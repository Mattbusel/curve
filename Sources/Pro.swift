import SwiftUI
import StoreKit

/// Curve Pro: one non-consumable. This term's grades and the need dial are free forever;
/// Pro is for the student keeping a whole transcript.
///
/// Anyone who installed a build before Pro existed keeps everything. AppTransaction's
/// originalAppVersion is the build number they first installed. Only trusted in production:
/// sandbox and Xcode report made-up values, and App Review must see the real paywall.
@MainActor
@Observable
final class Pro {
    static let productID = "com.mattbusel.curve.pro"
    /// The first build that has Pro in it. Anything earlier had every feature.
    static let firstFreemiumBuild = 2

    enum Reason: String, Identifiable { case terms, whatIf, drop, report, settings; var id: String { rawValue } }

    private(set) var unlocked: Bool
    private(set) var grandfathered = false
    private(set) var product: Product?
    var busy = false
    var message: String?
    var paywall: Reason? = nil

    private var updates: Task<Void, Never>?
    private let key = "curve.pro.unlocked"
    private let forced: Bool

    /// `forced` is for screenshots and the review recording, which must not touch StoreKit.
    init(forced: Bool? = nil) {
        self.forced = forced != nil
        if let forced { unlocked = forced; return }
        unlocked = UserDefaults.standard.bool(forKey: key)
        updates = Task { [weak self] in
            for await result in Transaction.updates { await self?.apply(result) }
        }
        Task { await refresh() }
    }

    var price: String { product?.displayPrice ?? "$2.99" }

    /// Runs `then` when Pro is unlocked, otherwise opens the paywall.
    func ask(_ why: Reason, then: () -> Void = {}) { if unlocked { then() } else { paywall = why } }

    func refresh() async {
        guard !forced else { return }
        if product == nil { product = try? await Product.products(for: [Pro.productID]).first }
        for await result in Transaction.currentEntitlements { await apply(result) }
        if case .verified(let app)? = try? await AppTransaction.shared,
           app.environment == .production, (Int(app.originalAppVersion) ?? Int.max) < Pro.firstFreemiumBuild {
            grandfathered = true
            grant()
        }
    }

    func buy() async {
        guard !forced, !busy else { return }
        busy = true; message = nil
        defer { busy = false }
        if product == nil { product = try? await Product.products(for: [Pro.productID]).first }
        guard let product else {
            message = "The App Store did not answer. Check your connection and try again."
            return
        }
        do {
            switch try await product.purchase() {
            case .success(let result):
                await apply(result)
                if !unlocked { message = "Apple could not confirm the purchase. Try Restore in a minute." }
            case .pending:
                message = "Waiting for approval. Pro unlocks by itself once it is approved."
            case .userCancelled:
                break
            @unknown default:
                message = "Something unexpected happened. You were not charged."
            }
        } catch {
            message = "The purchase did not go through: \(error.localizedDescription)"
        }
    }

    func restore() async {
        guard !forced, !busy else { return }
        busy = true; message = nil
        defer { busy = false }
        do { try await AppStore.sync() } catch {
            if let e = error as? StoreKitError, case .userCancelled = e { return }
            message = "Could not reach the App Store. Check your connection and try again."
            return
        }
        await refresh()
        message = unlocked ? "Curve Pro is unlocked. Welcome back." : "No Curve Pro purchase found on this Apple ID."
    }

    private func apply(_ result: VerificationResult<StoreKit.Transaction>) async {
        guard case .verified(let t) = result, t.productID == Pro.productID else { return }
        if t.revocationDate == nil { grant() } else if !grandfathered { revoke() }
        await t.finish()
    }

    private func grant() {
        guard !unlocked else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { unlocked = true }
        paywall = nil
        UserDefaults.standard.set(true, forKey: key)
    }

    private func revoke() {
        unlocked = false
        UserDefaults.standard.set(false, forKey: key)
    }
}

// MARK: - Paywall

/// A graded quiz: the four Pro features ticked off in marker, the price circled at the bottom.
struct PaywallView: View {
    @Environment(Pro.self) private var pro
    @Environment(\.dismiss) private var dismiss
    let reason: Pro.Reason
    @State private var shown = false

    var body: some View {
        ZStack {
            GraphPaper()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("CURVE PRO").font(.ui(12, .heavy)).tracking(3).foregroundStyle(Paper.bg)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(RoundedRectangle(cornerRadius: 4).fill(Paper.marker))
                            .rotationEffect(.degrees(-2))
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark").font(.system(size: 14, weight: .black)).foregroundStyle(Paper.chalk2)
                                .frame(width: 38, height: 38).background(Circle().fill(Paper.card)).overlay(Circle().strokeBorder(Paper.line2))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Close")
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(headline).font(.head(36)).foregroundStyle(Paper.chalk).fixedSize(horizontal: false, vertical: true)
                        Text("This term's grades and the need dial stay free forever. Pro is for the whole transcript.")
                            .font(.ui(14, .medium)).foregroundStyle(Paper.chalk2).fixedSize(horizontal: false, vertical: true)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        row(1, "Every term", "Keep Fall, Spring and the rest side by side, with a cumulative GPA across all of them.", .terms)
                        row(2, "What if", "Try a different letter in each course and watch the term and cumulative GPA move.", .whatIf)
                        row(3, "Drop lowest", "Match the syllabus that drops your worst quiz or homework.", .drop)
                        row(4, "Report and export", "A one-page PDF report and a CSV of every score, ready to share.", .report)
                    }
                    .tile(padding: 16)

                    HStack(alignment: .center, spacing: 14) {
                        ZStack {
                            Ellipse().stroke(Paper.marker, lineWidth: 3).frame(width: 120, height: 66).rotationEffect(.degrees(-6))
                                .scaleEffect(shown ? 1 : 0.6).opacity(shown ? 1 : 0)
                            Text(pro.price).font(.num(28)).foregroundStyle(Paper.chalk)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("once").font(.ui(15, .heavy)).foregroundStyle(Paper.marker)
                            Text("No subscription. Less than a textbook chapter.").font(.ui(12, .medium)).foregroundStyle(Paper.chalk2).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    if let m = pro.message {
                        Text(m).font(.ui(13, .semibold)).foregroundStyle(Paper.marker).frame(maxWidth: .infinity, alignment: .center).multilineTextAlignment(.center)
                    }
                    MarkerButton(title: pro.busy ? "One moment" : "Unlock Curve Pro for \(pro.price)", icon: "lock.open.fill") {
                        Task { await pro.buy() }
                    }
                    .disabled(pro.busy)
                    HStack(spacing: 10) {
                        GhostButton(title: "Restore purchase", icon: "arrow.clockwise") { Task { await pro.restore() } }
                        Spacer()
                        GhostButton(title: "Not now") { dismiss() }
                    }
                    Text("One payment, yours for good. Family Sharing works. Every grade you have entered stays yours, Pro or not.")
                        .font(.ui(11.5, .medium)).foregroundStyle(Paper.dim).fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 40)
            }
        }
        .onAppear { withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) { shown = true } }
        .onChange(of: pro.unlocked) { _, now in if now { dismiss() } }
    }

    var headline: String {
        switch reason {
        case .terms: return "Every term, one GPA."
        case .whatIf: return "What if you pull a B+?"
        case .drop: return "Drop the worst quiz."
        case .report: return "Hand in the report."
        case .settings: return "The whole transcript."
        }
    }

    func row(_ n: Int, _ title: String, _ body: String, _ r: Pro.Reason) -> some View {
        let hot = r == reason
        return HStack(alignment: .top, spacing: 12) {
            Text("\(n).").font(.num(15)).foregroundStyle(Paper.dim).frame(width: 22, alignment: .leading)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.ui(15, .heavy)).foregroundStyle(hot ? Paper.marker : Paper.chalk)
                Text(body).font(.ui(12.5, .medium)).foregroundStyle(Paper.chalk2).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            Image(systemName: "checkmark").font(.system(size: 18, weight: .black)).foregroundStyle(Paper.mint)
                .rotationEffect(.degrees(-8)).scaleEffect(shown ? 1 : 0.2).opacity(shown ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.55).delay(0.15 + Double(n) * 0.09), value: shown)
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) { if n < 4 { Rectangle().fill(Paper.line).frame(height: 1) } }
    }
}

/// The Pro line at the bottom of the GPA tab: status when unlocked, the way in (and Restore) when not.
struct ProCard: View {
    @Environment(Pro.self) private var pro
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Eyebrow("Curve Pro")
                Spacer()
                if pro.unlocked { Text("unlocked").font(.ui(11, .heavy)).foregroundStyle(Paper.mint) }
            }
            if pro.unlocked {
                Text(pro.grandfathered ? "Thank you for buying Curve early. Everything is yours." : "Every term, what if, drop lowest, the report and CSV. Thank you.")
                    .font(.ui(12.5, .medium)).foregroundStyle(Paper.chalk2)
            } else {
                Text("Every term with a cumulative GPA, what if, drop lowest, the PDF report and CSV. \(pro.price) once.")
                    .font(.ui(12.5, .medium)).foregroundStyle(Paper.chalk2).fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    GhostButton(title: "See Curve Pro", icon: "sparkles") { pro.ask(.settings) }
                    GhostButton(title: "Restore", icon: "arrow.clockwise") { Task { await pro.restore() } }
                }
                if let m = pro.message, pro.paywall == nil { Text(m).font(.ui(12, .semibold)).foregroundStyle(Paper.marker) }
            }
        }.tile()
    }
}

/// A small marker lock shown on Pro controls when locked.
struct ProLock: View {
    var body: some View {
        Image(systemName: "lock.fill").font(.system(size: 10, weight: .black)).foregroundStyle(Paper.marker)
    }
}

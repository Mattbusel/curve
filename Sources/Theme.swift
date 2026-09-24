import SwiftUI

/// Graph paper, chalk and a yellow marker. Forest green notebook, grades in big rounded numerals,
/// categories as highlighter strokes.
enum Paper {
    static let bg = Color(red: 0.070, green: 0.165, blue: 0.133)        // #122A22
    static let bg2 = Color(red: 0.090, green: 0.200, blue: 0.160)
    static let card = Color(red: 0.110, green: 0.235, blue: 0.190)
    static let card2 = Color(red: 0.145, green: 0.285, blue: 0.235)
    static let grid = Color.white.opacity(0.045)
    static let line = Color.white.opacity(0.09)
    static let line2 = Color.white.opacity(0.2)
    static let chalk = Color(red: 0.965, green: 0.950, blue: 0.900)
    static let chalk2 = Color(red: 0.965, green: 0.950, blue: 0.900).opacity(0.64)
    static let dim = Color(red: 0.965, green: 0.950, blue: 0.900).opacity(0.38)
    static let marker = Color(red: 0.960, green: 0.770, blue: 0.260)    // #F5C542
    static let marker2 = Color(red: 0.800, green: 0.600, blue: 0.120)
    static let mint = Color(red: 0.450, green: 0.860, blue: 0.620)
    static let sky = Color(red: 0.450, green: 0.720, blue: 0.950)
    static let lilac = Color(red: 0.720, green: 0.600, blue: 0.950)
    static let coral = Color(red: 0.980, green: 0.580, blue: 0.400)
    static let pink = Color(red: 0.980, green: 0.450, blue: 0.550)
    static let swatches: [Color] = [marker, mint, sky, lilac, coral, pink]
    static func swatch(_ i: Int) -> Color { swatches[max(0, i) % swatches.count] }
    static func grade(_ p: Double) -> Color { p >= 90 ? mint : p >= 80 ? marker : p >= 70 ? coral : pink }
}

extension Font {
    static func head(_ size: CGFloat) -> Font { .system(size: size, weight: .heavy, design: .serif) }
    static func big(_ size: CGFloat) -> Font { .system(size: size, weight: .heavy, design: .rounded) }
    static func ui(_ size: CGFloat, _ w: Font.Weight = .semibold) -> Font { .system(size: size, weight: w, design: .rounded) }
    static func num(_ size: CGFloat, _ w: Font.Weight = .heavy) -> Font { .system(size: size, weight: w, design: .rounded).monospacedDigit() }
}

/// Graph paper: faint squares on forest green, a warm glow top right.
struct GraphPaper: View {
    var body: some View {
        ZStack {
            Paper.bg
            Canvas { ctx, size in
                let step: CGFloat = 22
                var p = Path()
                var x: CGFloat = 0
                while x <= size.width { p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height)); x += step }
                var y: CGFloat = 0
                while y <= size.height { p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y)); y += step }
                ctx.stroke(p, with: .color(Paper.grid), lineWidth: 1)
            }
            RadialGradient(colors: [Paper.marker.opacity(0.14), .clear], center: .init(x: 0.95, y: -0.05), startRadius: 10, endRadius: 460)
        }.ignoresSafeArea()
    }
}

struct Eyebrow: View {
    let text: String
    init(_ t: String) { text = t }
    var body: some View { Text(text.uppercased()).font(.ui(11, .heavy)).tracking(2).foregroundStyle(Paper.dim) }
}

extension View {
    func tile(padding: CGFloat = 16, radius: CGFloat = 20) -> some View {
        self.padding(padding)
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(Paper.card))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(Paper.line))
    }
    func field() -> some View {
        self.padding(.horizontal, 12).frame(height: 44)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Paper.bg2))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Paper.line2))
    }
}

/// A highlighter stroke: a slightly skewed bar with soft ends, filled to a fraction.
struct Highlight: View {
    var fraction: Double
    var colour: Color = Paper.marker
    var height: CGFloat = 12
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4).fill(Paper.line).frame(height: height)
                RoundedRectangle(cornerRadius: 4).fill(colour.opacity(0.85))
                    .frame(width: max(0, min(1, fraction)) * g.size.width, height: height)
                    .transformEffect(CGAffineTransform(a: 1, b: 0, c: -0.18, d: 1, tx: 2, ty: 0))
                    .animation(.spring(duration: 0.5), value: fraction)
            }
        }.frame(height: height)
    }
}

/// Letter in a marker circle.
struct LetterBadge: View {
    let letter: String
    var size: CGFloat = 44
    var colour: Color = Paper.marker
    var body: some View {
        Text(letter).font(.big(size * 0.42)).foregroundStyle(Paper.bg)
            .frame(width: size, height: size)
            .background(Circle().fill(colour).shadow(color: colour.opacity(0.4), radius: 10, y: 4))
    }
}

struct MarkerButton: View {
    let title: String
    var icon: String? = nil
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon).font(.system(size: 15, weight: .black)) }
                Text(title).font(.ui(15, .heavy))
            }
            .foregroundStyle(Paper.bg).frame(maxWidth: .infinity).padding(.vertical, 15)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Paper.marker).shadow(color: Paper.marker.opacity(0.35), radius: 16, y: 6))
        }.buttonStyle(.plain)
    }
}

struct GhostButton: View {
    let title: String
    var icon: String? = nil
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon).font(.system(size: 13, weight: .bold)) }
                Text(title).font(.ui(13, .heavy))
            }
            .foregroundStyle(Paper.chalk2).padding(.horizontal, 14).padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(Paper.card2)).overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).strokeBorder(Paper.line2))
        }.buttonStyle(.plain)
    }
}

/// Notebook tabs along the bottom.
struct NotebookTabBar: View {
    @Binding var selection: Tab
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { t in
                Button { withAnimation(.snappy(duration: 0.25)) { selection = t } } label: {
                    VStack(spacing: 5) {
                        Image(systemName: t.icon).font(.system(size: 17, weight: selection == t ? .black : .medium))
                        Text(t.rawValue).font(.ui(10, .heavy))
                    }
                    .foregroundStyle(selection == t ? Paper.bg : Paper.dim)
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(Group { if selection == t { RoundedRectangle(cornerRadius: 13, style: .continuous).fill(Paper.marker) } })
                }.buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(RoundedRectangle(cornerRadius: 19, style: .continuous).fill(Paper.card).shadow(color: .black.opacity(0.6), radius: 20, y: 10))
        .overlay(RoundedRectangle(cornerRadius: 19, style: .continuous).strokeBorder(Paper.line2))
        .padding(.horizontal, 16)
    }
}

enum Fmt {
    static func pct(_ v: Double?) -> String { guard let v else { return "--" }; return String(format: "%.1f%%", v) }
    static func pct0(_ v: Double) -> String { String(format: "%.0f%%", v) }
    static func gpa(_ v: Double?) -> String { guard let v else { return "--" }; return String(format: "%.2f", v) }
    static func score(_ v: Double) -> String { v == v.rounded() ? String(format: "%.0f", v) : String(format: "%.1f", v) }
    static func credits(_ v: Double) -> String { score(v) }
}

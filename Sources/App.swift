import SwiftUI

@main
struct CurveApp: App {
    @State private var store: Store
    @State private var router = Router()
    @State private var pro: Pro
    init() {
        let a = ProcessInfo.processInfo.arguments
        let demo = a.contains("-shot") || a.contains("-demoAutoplay")
        _store = State(initialValue: Store(demo: demo))
        // Screenshots and the review recording show Pro; the paywall shot shows it locked.
        let shot = a.firstIndex(of: "-shot").flatMap { a.indices.contains($0 + 1) ? a[$0 + 1] : nil }
        _pro = State(initialValue: demo ? Pro(forced: shot != "paywall") : Pro())
    }
    var body: some Scene {
        WindowGroup {
            RootView().environment(store).environment(router).environment(pro).preferredColorScheme(.dark).tint(Paper.marker)
                .onAppear { router.applyShotArgs(store, pro); Autopilot.shared.run(store, router) }
        }
    }
}

enum Tab: String, CaseIterable {
    case term = "Term", gpa = "GPA", report = "Report"
    var icon: String {
        switch self {
        case .term: return "square.grid.2x2.fill"
        case .gpa: return "function"
        case .report: return "doc.text.fill"
        }
    }
}

@Observable
final class Router {
    var tab: Tab = .term
    var path: [UUID] = []
    var showNeed = false
    var needTarget: Double? = nil
    var showAdd = false
    var prefill: Assignment? = nil
    var editingAssignment: Assignment? = nil
    var editingCourse: Course? = nil
    var creatingCourse = false
    var editingTerm = false

    @MainActor
    func applyShotArgs(_ s: Store, _ pro: Pro) {
        let a = ProcessInfo.processInfo.arguments
        guard let i = a.firstIndex(of: "-shot"), i + 1 < a.count else { return }
        let cs = s.term.courses
        switch a[i + 1] {
        case "course": if let c = cs.first { path = [c.id] }
        case "need": if cs.count > 1 { path = [cs[1].id]; DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { self.showNeed = true } }
        case "add":
            if let c = cs.first {
                path = [c.id]
                prefill = Assignment(name: "HW 6 Series tests", category: c.categories.first?.id, score: 19, outOf: 20, date: Day.today)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { self.showAdd = true }
            }
        case "gpa": tab = .gpa
        case "report": tab = .report
        case "paywall": tab = .gpa; DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { pro.ask(.whatIf) }
        default: break
        }
    }
}

struct RootView: View {
    @Environment(Store.self) private var store
    @Environment(Router.self) private var router
    @Environment(Pro.self) private var pro
    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            ZStack(alignment: .bottom) {
                GraphPaper()
                Group {
                    switch router.tab {
                    case .term: TermView()
                    case .gpa: GPAView()
                    case .report: ReportView()
                    }
                }
                NotebookTabBar(selection: $router.tab).padding(.bottom, 2)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: UUID.self) { id in CourseView(id: id) }
        }
        .sheet(isPresented: $router.creatingCourse) { CourseEditor(course: Course(name: ""), isNew: true).presentationBackground(Paper.bg2) }
        .sheet(item: $router.editingCourse) { c in CourseEditor(course: c, isNew: false).presentationBackground(Paper.bg2) }
        .sheet(isPresented: $router.editingTerm) { TermEditor().presentationBackground(Paper.bg2).presentationDetents([.medium]) }
        // The course editor hosts its own paywall (drop lowest); this one covers everything else.
        .sheet(item: Binding(get: { router.creatingCourse || router.editingCourse != nil ? nil : pro.paywall }, set: { pro.paywall = $0 })) { r in
            PaywallView(reason: r).presentationBackground(Paper.bg)
        }
    }
}

struct Page<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) { content }.padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 110)
        }
    }
}

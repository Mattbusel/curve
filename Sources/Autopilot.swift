import SwiftUI

/// Drives the real screens for the App Review recording (-demoAutoplay).
@Observable
final class Autopilot {
    static let shared = Autopilot()
    static var on: Bool { ProcessInfo.processInfo.arguments.contains("-demoAutoplay") }
    private var running = false
    @MainActor private func wait(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }
    @MainActor
    func run(_ store: Store, _ router: Router) {
        guard Autopilot.on, !running else { return }
        running = true
        Task { @MainActor in
            await wait(3.5)
            let cs = store.term.courses
            guard cs.count > 1 else { return }
            router.path = [cs[0].id]; await wait(3.5)
            router.prefill = Assignment(name: "HW 6 Series tests", category: cs[0].categories.first?.id, score: 19, outOf: 20, date: Day.today)
            router.showAdd = true; await wait(3.5)
            router.showAdd = false; await wait(0.8)
            if let a = router.prefill { withAnimation { store.put(a, in: cs[0].id) } }
            await wait(2.5)
            router.showNeed = true; await wait(3)
            router.needTarget = 90; await wait(2.5)
            router.needTarget = 80; await wait(2.5)
            router.showNeed = false; await wait(1)
            router.path = []; await wait(1.5)
            router.tab = .gpa; await wait(4)
            router.tab = .report; await wait(4)
            router.tab = .term; await wait(1.5)
            try? Data("ok".utf8).write(to: URL.documentsDirectory.appending(path: "demo_done"))
        }
    }
}

import Foundation
import Observation

enum Mode: String, Codable, CaseIterable { case weighted, points }

struct ScaleStep: Codable, Hashable { var letter: String; var min: Double }

struct Category: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var weight: Double
    var drop: Int = 0
}

struct Assignment: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var category: UUID? = nil
    var score: Double? = nil
    var outOf: Double = 100
    var date: String                          // yyyy-MM-dd
    var skipped = false
    var pct: Double? { guard let s = score, outOf > 0 else { return nil }; return s / outOf * 100 }
    var graded: Bool { score != nil && !skipped }
}

struct Course: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var credits: Double = 3
    var instructor = ""
    var colour = 0
    var mode: Mode = .weighted
    var bump: Double = 0                      // 0.5 honors, 1.0 AP
    var categories: [Category] = []
    var assignments: [Assignment] = []
    var scale: [ScaleStep] = Scale.standard
    var weightTotal: Double { categories.reduce(0) { $0 + $1.weight } }
}

struct Term: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var courses: [Course] = []
}

enum Scale {
    static let standard: [ScaleStep] = [("A", 93.0), ("A-", 90.0), ("B+", 87.0), ("B", 83.0), ("B-", 80.0), ("C+", 77.0), ("C", 73.0), ("C-", 70.0), ("D+", 67.0), ("D", 63.0), ("D-", 60.0), ("F", 0.0)].map { ScaleStep(letter: $0.0, min: $0.1) }
    static let points: [String: Double] = ["A": 4, "A-": 3.7, "B+": 3.3, "B": 3, "B-": 2.7, "C+": 2.3, "C": 2, "C-": 1.7, "D+": 1.3, "D": 1, "D-": 0.7, "F": 0]
    static let order = ["A", "A-", "B+", "B", "B-", "C+", "C", "C-", "D+", "D", "D-", "F"]
    static func letter(_ p: Double, _ s: [ScaleStep]) -> String {
        for st in s.sorted(by: { $0.min > $1.min }) where p >= st.min - 1e-9 { return st.letter }
        return "F"
    }
    static func minFor(_ letter: String, _ s: [ScaleStep]) -> Double { s.first { $0.letter == letter }?.min ?? 0 }
}

enum Day {
    static let cal: Calendar = { var c = Calendar(identifier: .iso8601); c.timeZone = .current; return c }()
    static let f: DateFormatter = { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.calendar = cal; f.timeZone = .current; return f }()
    static func key(_ d: Date) -> String { f.string(from: d) }
    static func date(_ k: String) -> Date { f.date(from: k) ?? .now }
    static var today: String { key(.now) }
    static func add(_ k: String, _ n: Int) -> String { key(cal.date(byAdding: .day, value: n, to: date(k))!) }
    static func diff(_ a: String, _ b: String) -> Int { cal.dateComponents([.day], from: date(a), to: date(b)).day ?? 0 }
    static func short(_ k: String) -> String { date(k).formatted(.dateTime.month(.abbreviated).day()) }
    static func rel(_ k: String) -> String {
        let d = diff(today, k)
        if d == 0 { return "today" }
        if d == 1 { return "tomorrow" }
        if d == -1 { return "yesterday" }
        return d > 0 ? "in \(d) days" : "\(-d) days ago"
    }
}

// MARK: Grade engine

struct GradeResult {
    var pct: Double?                          // current grade, over what has been graded
    var earnedW: Double                       // sum of weight * average (percent-weight units)
    var gradedW: Double
    var totalW: Double
    var missing: [String]                     // categories with nothing graded yet
    var remainingW: Double { max(0, totalW - gradedW) }
}

enum Need: Equatable {
    case locked(Double)                       // nothing left, final grade is this
    case inTheBag                             // any score works
    case need(Double)
    case outOfReach(Double)
}

enum Trend: String { case rising, slipping, steady }

enum Grade {
    static func catAverage(_ c: Course, _ cat: Category) -> Double? {
        var items = c.assignments.filter { $0.category == cat.id && $0.graded }
        if cat.drop > 0 && items.count > cat.drop {
            items.sort { ($0.pct ?? 0) < ($1.pct ?? 0) }
            items.removeFirst(cat.drop)
        }
        guard !items.isEmpty else { return nil }
        let s = items.reduce(0.0) { $0 + ($1.score ?? 0) }
        let o = items.reduce(0.0) { $0 + $1.outOf }
        return o > 0 ? s / o * 100 : nil
    }

    static func result(_ c: Course) -> GradeResult {
        if c.mode == .points {
            let live = c.assignments.filter { !$0.skipped }
            let totalW = live.reduce(0.0) { $0 + $1.outOf }
            let graded = live.filter { $0.graded }
            let gradedW = graded.reduce(0.0) { $0 + $1.outOf }
            let earned = graded.reduce(0.0) { $0 + ($1.score ?? 0) }
            let pct: Double? = gradedW > 0 ? earned / gradedW * 100 : nil
            return GradeResult(pct: pct, earnedW: earned * 100, gradedW: gradedW, totalW: totalW, missing: [])
        }
        var earnedW = 0.0, gradedW = 0.0, missing: [String] = []
        for cat in c.categories {
            if let a = catAverage(c, cat) { earnedW += cat.weight * a; gradedW += cat.weight } else { missing.append(cat.name) }
        }
        let pct: Double? = gradedW > 0 ? earnedW / gradedW : nil
        return GradeResult(pct: pct, earnedW: earnedW, gradedW: gradedW, totalW: c.weightTotal, missing: missing)
    }

    static func letter(_ c: Course) -> String? {
        guard let p = result(c).pct else { return nil }
        return Scale.letter(p, c.scale)
    }

    /// What score is needed on everything still ungraded, to finish at `target` percent.
    static func need(_ c: Course, target: Double) -> Need {
        let r = result(c)
        if r.remainingW <= 0.0001 { return .locked(r.pct ?? 0) }
        let x = (target * r.totalW - r.earnedW) / r.remainingW
        if x <= 0 { return .inTheBag }
        if x > 100 { return .outOfReach(x) }
        return .need(x)
    }

    static func trend(_ c: Course) -> Trend {
        let g = c.assignments.filter { $0.graded }.sorted { $0.date < $1.date }.compactMap { $0.pct }
        guard g.count >= 4 else { return .steady }
        let last = g.suffix(3).reduce(0, +) / 3
        let before = g.dropLast(3)
        let prev = before.reduce(0, +) / Double(before.count)
        if last - prev > 2 { return .rising }
        if prev - last > 2 { return .slipping }
        return .steady
    }

    static func nextDue(_ c: Course) -> Assignment? {
        c.assignments.filter { $0.score == nil && !$0.skipped && $0.date >= Day.today }.min { $0.date < $1.date }
    }

    /// Running course grade after each graded assignment, in date order.
    static func history(_ c: Course) -> [(date: String, pct: Double)] {
        let graded = c.assignments.filter { $0.graded }.sorted { $0.date < $1.date }
        var out: [(date: String, pct: Double)] = []
        var copy = c
        copy.assignments = c.assignments.map { var a = $0; if a.graded { a.score = nil }; return a }
        for a in graded {
            if let i = copy.assignments.firstIndex(where: { $0.id == a.id }) { copy.assignments[i].score = a.score }
            if let p = result(copy).pct { out.append((date: a.date, pct: p)) }
        }
        return out
    }
}

// MARK: Store

@Observable
final class Store {
    var terms: [Term] = []
    var cur = 0
    var pointMap: [String: Double] = Scale.points
    var whatIf: [UUID: String] = [:]
    private var saveTask: Task<Void, Never>?
    private let url = URL.documentsDirectory.appending(path: "curve.json")
    struct Disk: Codable { var terms: [Term]; var cur: Int; var pointMap: [String: Double] }

    init(demo: Bool) {
        if demo { Demo.fill(self); return }
        if let d = try? Data(contentsOf: url), let disk = try? JSONDecoder().decode(Disk.self, from: d) {
            terms = disk.terms; cur = min(disk.cur, max(0, disk.terms.count - 1)); pointMap = disk.pointMap
        }
    }
    func save() {
        saveTask?.cancel(); let disk = Disk(terms: terms, cur: cur, pointMap: pointMap); let u = url
        saveTask = Task.detached(priority: .utility) {
            try? await Task.sleep(for: .milliseconds(200)); if Task.isCancelled { return }
            if let d = try? JSONEncoder().encode(disk) { try? d.write(to: u, options: .atomic) }
        }
    }

    var hasTerm: Bool { terms.indices.contains(cur) }
    var term: Term { hasTerm ? terms[cur] : Term(name: "No term yet") }
    func course(_ id: UUID) -> Course? { terms.flatMap { $0.courses }.first { $0.id == id } }
    func termOf(_ courseId: UUID) -> Int? { terms.firstIndex { $0.courses.contains { $0.id == courseId } } }

    func put(_ c: Course) {
        if let t = termOf(c.id), let i = terms[t].courses.firstIndex(where: { $0.id == c.id }) { terms[t].courses[i] = c }
        else if hasTerm { terms[cur].courses.append(c) }
        else { terms.append(Term(name: "This term", courses: [c])); cur = 0 }
        save()
    }
    func remove(course id: UUID) {
        if let t = termOf(id) { terms[t].courses.removeAll { $0.id == id } }
        save()
    }
    func put(_ a: Assignment, in courseId: UUID) {
        guard var c = course(courseId) else { return }
        if let i = c.assignments.firstIndex(where: { $0.id == a.id }) { c.assignments[i] = a } else { c.assignments.append(a) }
        put(c)
    }
    func remove(assignment id: UUID, in courseId: UUID) {
        guard var c = course(courseId) else { return }
        c.assignments.removeAll { $0.id == id }; put(c)
    }
    func addTerm(_ name: String) { terms.append(Term(name: name)); cur = terms.count - 1; save() }
    func renameTerm(_ name: String) { guard hasTerm else { return }; terms[cur].name = name; save() }
    func deleteTerm() { guard hasTerm else { return }; terms.remove(at: cur); cur = max(0, min(cur, terms.count - 1)); save() }

    // GPA
    func points(_ c: Course, letter: String, weighted: Bool) -> Double { (pointMap[letter] ?? 0) + (weighted ? c.bump : 0) }
    func letter(_ c: Course, whatIf: Bool = false) -> String? { whatIf ? (self.whatIf[c.id] ?? Grade.letter(c)) : Grade.letter(c) }
    func gpa(_ t: Term, weighted: Bool, whatIf: Bool = false) -> (gpa: Double?, credits: Double) {
        var pts = 0.0, cr = 0.0
        for c in t.courses { if let l = letter(c, whatIf: whatIf) { pts += points(c, letter: l, weighted: weighted) * c.credits; cr += c.credits } }
        return (cr > 0 ? pts / cr : nil, cr)
    }
    func cumulative(weighted: Bool, whatIf: Bool = false) -> (gpa: Double?, credits: Double) {
        var pts = 0.0, cr = 0.0
        for t in terms { for c in t.courses { if let l = letter(c, whatIf: whatIf) { pts += points(c, letter: l, weighted: weighted) * c.credits; cr += c.credits } } }
        return (cr > 0 ? pts / cr : nil, cr)
    }
    struct Upcoming: Identifiable { var id: UUID { a.id }; let course: Course; let a: Assignment }
    var upcoming: [Upcoming] {
        term.courses.flatMap { c in c.assignments.filter { $0.score == nil && !$0.skipped && $0.date >= Day.today }.map { Upcoming(course: c, a: $0) } }
            .sorted { $0.a.date < $1.a.date }
    }

    func csv() -> URL {
        var s = "term,course,category,assignment,date,score,out of,percent,skipped\n"
        func q(_ x: String) -> String { "\"" + x.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
        for t in terms { for c in t.courses { for a in c.assignments {
            let cat = c.categories.first { $0.id == a.category }?.name ?? ""
            s += [q(t.name), q(c.name), q(cat), q(a.name), a.date, a.score.map { Fmt.score($0) } ?? "", Fmt.score(a.outOf), a.pct.map { String(format: "%.1f", $0) } ?? "", a.skipped ? "yes" : "no"].joined(separator: ",") + "\n"
        } } }
        let u = URL.temporaryDirectory.appending(path: "Curve grades.csv")
        try? s.data(using: .utf8)?.write(to: u); return u
    }
}

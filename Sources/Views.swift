import SwiftUI
import Charts

// MARK: Term dashboard

struct TermView: View {
    @Environment(Store.self) private var store
    @Environment(Router.self) private var router
    var body: some View {
        let t = store.term
        let g = store.gpa(t, weighted: false), w = store.gpa(t, weighted: true), cum = store.cumulative(weighted: false)
        Page {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.hasTerm ? t.name : "Curve").font(.head(34)).foregroundStyle(Paper.chalk)
                    Text(store.hasTerm ? "\(t.courses.count) courses, \(Fmt.credits(g.credits)) credits graded so far." : "Grades, honestly weighted.").font(.ui(13, .medium)).foregroundStyle(Paper.chalk2)
                }
                Spacer()
                Menu {
                    ForEach(Array(store.terms.enumerated()), id: \.offset) { i, term in Button(term.name) { store.cur = i; store.save() } }
                    Divider()
                    Button("New term", systemImage: "plus") { router.editingTerm = true }
                    if store.hasTerm { Button("Rename term", systemImage: "pencil") { router.editingTerm = true } }
                } label: {
                    Image(systemName: "calendar").font(.system(size: 15, weight: .black)).foregroundStyle(Paper.chalk2).frame(width: 40, height: 40).background(Circle().fill(Paper.card)).overlay(Circle().strokeBorder(Paper.line2))
                }
            }.padding(.top, 14)

            HStack(spacing: 10) {
                stat(Fmt.gpa(g.gpa), "term GPA")
                stat(Fmt.gpa(w.gpa), "weighted")
                stat(Fmt.gpa(cum.gpa), "cumulative")
            }

            if !store.upcoming.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow("Coming up")
                    ForEach(Array(store.upcoming.prefix(4))) { u in
                        HStack(spacing: 10) {
                            Circle().fill(Paper.swatch(u.course.colour)).frame(width: 8, height: 8)
                            Text(u.a.name).font(.ui(13, .heavy)).foregroundStyle(Paper.chalk).lineLimit(1)
                            Text(u.course.name).font(.ui(12, .medium)).foregroundStyle(Paper.dim).lineLimit(1)
                            Spacer(minLength: 6)
                            Text(Day.rel(u.a.date)).font(.num(12, .bold)).foregroundStyle(Day.diff(Day.today, u.a.date) <= 2 ? Paper.marker : Paper.chalk2)
                        }
                    }
                }.tile()
            }

            ForEach(t.courses) { c in CourseCard(course: c).onTapGesture { router.path = [c.id] } }
            if t.courses.isEmpty {
                VStack(spacing: 10) {
                    Text(store.hasTerm ? "No courses yet." : "Start a term.").font(.ui(16, .heavy)).foregroundStyle(Paper.chalk)
                    Text(store.hasTerm ? "Add a course, type its categories and weights from the syllabus, and log scores as they come back." : "Fall 2026, Spring 2027, whatever the school calls it.").font(.ui(13, .medium)).foregroundStyle(Paper.chalk2).multilineTextAlignment(.center)
                }.frame(maxWidth: .infinity).tile(padding: 24)
            }
            MarkerButton(title: store.hasTerm ? "Add a course" : "New term", icon: "plus") { if store.hasTerm { router.creatingCourse = true } else { router.editingTerm = true } }
        }
    }
    func stat(_ v: String, _ l: String) -> some View {
        VStack(alignment: .leading, spacing: 2) { Text(v).font(.num(26)).foregroundStyle(Paper.marker); Text(l).font(.ui(11, .heavy)).foregroundStyle(Paper.dim) }.frame(maxWidth: .infinity, alignment: .leading).tile(padding: 14)
    }
}

struct CourseCard: View {
    let course: Course
    var body: some View {
        let r = Grade.result(course)
        let tr = Grade.trend(course)
        let next = Grade.nextDue(course)
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                if let p = r.pct {
                    Text(Fmt.pct(p)).font(.num(30)).foregroundStyle(Paper.chalk)
                } else {
                    Text("--").font(.num(30)).foregroundStyle(Paper.dim)
                }
                HStack(spacing: 6) {
                    Image(systemName: tr == .rising ? "arrow.up.right" : tr == .slipping ? "arrow.down.right" : "arrow.right").font(.system(size: 11, weight: .black))
                    Text(tr.rawValue).font(.ui(11, .heavy))
                }.foregroundStyle(tr == .rising ? Paper.mint : tr == .slipping ? Paper.pink : Paper.dim)
            }.frame(width: 104, alignment: .leading)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(course.name).font(.ui(16, .heavy)).foregroundStyle(Paper.chalk).lineLimit(1)
                    Spacer(minLength: 4)
                    if let p = r.pct { LetterBadge(letter: Scale.letter(p, course.scale), size: 30, colour: Paper.swatch(course.colour)) }
                }
                Highlight(fraction: (r.pct ?? 0) / 100, colour: Paper.swatch(course.colour), height: 9)
                Text(next.map { "Next: \($0.name), \(Day.rel($0.date))" } ?? "Nothing due").font(.ui(11, .medium)).foregroundStyle(Paper.dim).lineLimit(1)
            }
        }
        .tile(padding: 14)
        .contentShape(Rectangle())
    }
}

// MARK: Course

struct CourseView: View {
    @Environment(Store.self) private var store
    @Environment(Router.self) private var router
    let id: UUID
    var course: Course { store.course(id) ?? Course(name: "") }
    var body: some View {
        @Bindable var router = router
        let c = course
        let r = Grade.result(c)
        ZStack {
            GraphPaper()
            Page {
                HStack {
                    Button { router.path = [] } label: { Image(systemName: "chevron.left").font(.system(size: 14, weight: .black)).foregroundStyle(Paper.chalk2).frame(width: 36, height: 36).background(Circle().fill(Paper.card)) }.buttonStyle(.plain)
                    Spacer()
                    GhostButton(title: "Set up", icon: "slider.horizontal.3") { router.editingCourse = c }
                    ShareLink(item: store.csv()) { Image(systemName: "square.and.arrow.up").font(.system(size: 14, weight: .black)).foregroundStyle(Paper.chalk2).frame(width: 36, height: 36).background(Circle().fill(Paper.card)) }
                }.padding(.top, 8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(c.name).font(.head(30)).foregroundStyle(Paper.chalk)
                    Text([c.instructor, "\(Fmt.credits(c.credits)) credits", c.mode == .points ? "total points" : "weighted"].filter { !$0.isEmpty }.joined(separator: " · ")).font(.ui(13, .medium)).foregroundStyle(Paper.chalk2)
                }

                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(r.pct.map { Fmt.pct($0) } ?? "--").font(.num(54)).foregroundStyle(Paper.chalk)
                        Text(trendLine(c)).font(.ui(12, .medium)).foregroundStyle(Paper.chalk2)
                    }
                    Spacer()
                    if let p = r.pct { LetterBadge(letter: Scale.letter(p, c.scale), size: 74, colour: Paper.swatch(c.colour)) }
                }.tile()
                if !r.missing.isEmpty, r.pct != nil {
                    Text("\(r.missing.joined(separator: ", ")) \(r.missing.count == 1 ? "has" : "have") nothing graded yet, so this is out of the \(Fmt.pct0(r.gradedW / max(r.totalW, 1) * 100)) of the course graded so far.").font(.ui(12, .medium)).foregroundStyle(Paper.dim)
                }
                if c.mode == .weighted && abs(c.weightTotal - 100) > 0.01 && !c.categories.isEmpty {
                    Label("Weights add up to \(Fmt.score(c.weightTotal)), not 100. The grade still works, but check the syllabus.", systemImage: "exclamationmark.triangle.fill").font(.ui(12, .heavy)).foregroundStyle(Paper.marker)
                }

                HStack(spacing: 8) {
                    MarkerButton(title: "What do I need?", icon: "dial.high") { router.showNeed = true }
                    Button { router.prefill = nil; router.showAdd = true } label: {
                        HStack(spacing: 6) { Image(systemName: "plus").font(.system(size: 14, weight: .black)); Text("Score").font(.ui(15, .heavy)) }
                            .foregroundStyle(Paper.chalk).padding(.horizontal, 18).padding(.vertical, 15)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Paper.card2)).overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Paper.line2))
                    }.buttonStyle(.plain)
                }

                let hist = Grade.history(c)
                if hist.count >= 2 { GradeChart(points: hist, colour: Paper.swatch(c.colour)).tile(padding: 12) }

                if c.mode == .weighted {
                    VStack(alignment: .leading, spacing: 12) {
                        Eyebrow("Categories")
                        ForEach(c.categories) { cat in
                            let avg = Grade.catAverage(c, cat)
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text(cat.name).font(.ui(14, .heavy)).foregroundStyle(Paper.chalk)
                                    Text("\(Fmt.score(cat.weight))%" + (cat.drop > 0 ? " · drops \(cat.drop)" : "")).font(.ui(11, .heavy)).foregroundStyle(Paper.dim)
                                    Spacer()
                                    Text(avg.map { Fmt.pct($0) } ?? "not started").font(.num(13, .bold)).foregroundStyle(avg == nil ? Paper.dim : Paper.chalk)
                                }
                                Highlight(fraction: (avg ?? 0) / 100, colour: avg == nil ? Paper.line2 : Paper.grade(avg ?? 0), height: 10)
                            }
                        }
                        if c.categories.isEmpty { Text("No categories yet. Tap Set up and type them from the syllabus.").font(.ui(13, .medium)).foregroundStyle(Paper.chalk2) }
                    }.tile()
                }

                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow("Scores")
                    let groups = grouped(c)
                    ForEach(groups, id: \.title) { grp in
                        if c.mode == .weighted { Text(grp.title).font(.ui(11, .heavy)).foregroundStyle(Paper.dim).padding(.top, 4) }
                        ForEach(grp.items) { a in AssignmentRow(a: a).onTapGesture { router.editingAssignment = a } }
                    }
                    if c.assignments.isEmpty { Text("Nothing logged. Tap Score to add the first one.").font(.ui(13, .medium)).foregroundStyle(Paper.chalk2) }
                }.tile()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $router.showNeed) { NeedView(courseId: id).presentationBackground(Paper.bg2) }
        .sheet(isPresented: $router.showAdd) {
            AssignmentEditor(courseId: id, assignment: router.prefill ?? Assignment(name: "", category: c.categories.first?.id, date: Day.today), isNew: true).presentationBackground(Paper.bg2)
        }
        .sheet(item: $router.editingAssignment) { a in AssignmentEditor(courseId: id, assignment: a, isNew: false).presentationBackground(Paper.bg2) }
    }
    struct Group_: Hashable { var title: String; var items: [Assignment] }
    func grouped(_ c: Course) -> [Group_] {
        let sorted = c.assignments.sorted { $0.date > $1.date }
        if c.mode == .points { return [Group_(title: "All", items: sorted)] }
        var out: [Group_] = c.categories.map { cat in Group_(title: cat.name, items: sorted.filter { $0.category == cat.id }) }.filter { !$0.items.isEmpty }
        let orphan = sorted.filter { a in !c.categories.contains { $0.id == a.category } }
        if !orphan.isEmpty { out.append(Group_(title: "No category", items: orphan)) }
        return out
    }
    func trendLine(_ c: Course) -> String {
        let n = c.assignments.filter { $0.graded }.count
        switch Grade.trend(c) {
        case .rising: return "\(n) graded · last three are above your average"
        case .slipping: return "\(n) graded · last three are below your average"
        case .steady: return n == 0 ? "nothing graded yet" : "\(n) graded · holding steady"
        }
    }
}

struct AssignmentRow: View {
    let a: Assignment
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(a.name).font(.ui(14, .heavy)).foregroundStyle(a.skipped ? Paper.dim : Paper.chalk).strikethrough(a.skipped).lineLimit(1)
                Text(Day.short(a.date) + (a.score == nil && !a.skipped ? " · " + Day.rel(a.date) : "")).font(.ui(11, .medium)).foregroundStyle(Paper.dim)
            }
            Spacer(minLength: 6)
            if a.skipped {
                Text("skipped").font(.ui(11, .heavy)).foregroundStyle(Paper.dim)
            } else if let s = a.score {
                Text("\(Fmt.score(s)) / \(Fmt.score(a.outOf))").font(.num(13, .bold)).foregroundStyle(Paper.chalk2)
                Text(Fmt.pct(a.pct)).font(.num(14)).foregroundStyle(Paper.grade(a.pct ?? 0)).frame(width: 60, alignment: .trailing)
            } else {
                Text("out of \(Fmt.score(a.outOf))").font(.num(12, .bold)).foregroundStyle(Paper.dim)
            }
        }
        .padding(.vertical, 7)
        .contentShape(Rectangle())
    }
}

struct GradePoint: Identifiable { let id = UUID(); let date: Date; let pct: Double }

struct GradeChart: View {
    let points: [(date: String, pct: Double)]
    let colour: Color
    var body: some View {
        let pts = points.map { GradePoint(date: Day.date($0.date), pct: $0.pct) }
        let lo = max(0, (pts.map { $0.pct }.min() ?? 60) - 8)
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow("Running grade")
            Chart(pts) { p in
                AreaMark(x: .value("Date", p.date), yStart: .value("Low", lo), yEnd: .value("Grade", p.pct))
                    .foregroundStyle(LinearGradient(colors: [colour.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom))
                LineMark(x: .value("Date", p.date), y: .value("Grade", p.pct)).foregroundStyle(colour).lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round)).interpolationMethod(.monotone)
                PointMark(x: .value("Date", p.date), y: .value("Grade", p.pct)).foregroundStyle(colour).symbolSize(30)
            }
            .chartYScale(domain: lo...100)
            .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) { _ in AxisGridLine().foregroundStyle(Paper.line); AxisValueLabel().font(.ui(10, .bold)).foregroundStyle(Paper.dim) } }
            .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in AxisGridLine().foregroundStyle(Paper.line); AxisValueLabel().font(.ui(10, .bold)).foregroundStyle(Paper.dim) } }
            .frame(height: 150)
        }
    }
}

// MARK: What do I need

struct NeedView: View {
    @Environment(Store.self) private var store
    @Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss
    let courseId: UUID
    @State private var target: Double = 90
    var course: Course { store.course(courseId) ?? Course(name: "") }
    var body: some View {
        let c = course
        let r = Grade.result(c)
        let need = Grade.need(c, target: target)
        let remainingNames = c.mode == .points ? c.assignments.filter { $0.score == nil && !$0.skipped }.map { $0.name } : r.missing
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                Text("What do I need?").font(.head(28)).foregroundStyle(Paper.chalk).padding(.top, 22)
                Text("\(c.name). You are at \(Fmt.pct(r.pct)) with \(Fmt.pct0(r.remainingW / max(r.totalW, 1) * 100)) of the grade still to come" + (remainingNames.isEmpty ? "." : " (\(remainingNames.joined(separator: ", "))).")).font(.ui(13, .medium)).foregroundStyle(Paper.chalk2)

                Dial(value: dialValue(need), state: need)
                    .frame(height: 210)
                Text(headline(need)).font(.ui(15, .heavy)).foregroundStyle(Paper.chalk).multilineTextAlignment(.center).frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow("Turn the dial to a target")
                    HStack(spacing: 6) {
                        ForEach(c.scale.filter { $0.letter != "F" }, id: \.letter) { st in
                            Button { withAnimation(.snappy) { target = st.min } } label: {
                                Text(st.letter).font(.ui(12, .heavy)).foregroundStyle(abs(target - st.min) < 0.01 ? Paper.bg : Paper.chalk2)
                                    .frame(maxWidth: .infinity).frame(height: 34)
                                    .background(RoundedRectangle(cornerRadius: 9).fill(abs(target - st.min) < 0.01 ? Paper.marker : Paper.card))
                            }.buttonStyle(.plain)
                        }
                    }
                    HStack {
                        Slider(value: $target, in: 50...100, step: 0.5).tint(Paper.marker)
                        Text(Fmt.pct(target)).font(.num(15)).foregroundStyle(Paper.marker).frame(width: 64, alignment: .trailing)
                    }
                }.tile()

                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow("Every target")
                    ForEach(c.scale.filter { $0.letter != "F" }, id: \.letter) { st in
                        let n = Grade.need(c, target: st.min)
                        HStack {
                            Text(st.letter).font(.ui(14, .heavy)).foregroundStyle(Paper.chalk).frame(width: 34, alignment: .leading)
                            Text("\(Fmt.score(st.min))%+").font(.num(12, .bold)).foregroundStyle(Paper.dim)
                            Spacer()
                            Text(short(n)).font(.num(14)).foregroundStyle(colour(n))
                        }.padding(.vertical, 3)
                    }
                }.tile()
                MarkerButton(title: "Done") { dismiss() }
            }.padding(18)
        }
        .onAppear { if let t = router.needTarget { target = t } }
        .onChange(of: router.needTarget) { _, v in if let v { withAnimation(.snappy(duration: 0.6)) { target = v } } }
    }
    func dialValue(_ n: Need) -> Double {
        switch n { case .locked: return 0; case .inTheBag: return 0; case .need(let x): return x; case .outOfReach: return 100 }
    }
    func headline(_ n: Need) -> String {
        switch n {
        case .locked(let p): return "Everything is graded. You finish at \(Fmt.pct(p))."
        case .inTheBag: return "Already locked in. Any score on what is left keeps \(Fmt.pct(target))."
        case .need(let x): return "You need \(Fmt.pct(x)) on what is left to finish at \(Fmt.pct(target))."
        case .outOfReach(let x): return "Out of reach: it would take \(Fmt.pct(x)) on what is left. Aim one step lower."
        }
    }
    func short(_ n: Need) -> String {
        switch n { case .locked: return "graded"; case .inTheBag: return "locked in"; case .need(let x): return Fmt.pct(x); case .outOfReach: return "out of reach" }
    }
    func colour(_ n: Need) -> Color {
        switch n { case .locked: return Paper.dim; case .inTheBag: return Paper.mint; case .need(let x): return x > 90 ? Paper.coral : Paper.chalk; case .outOfReach: return Paper.pink }
    }
}

/// A gauge you turn: the needle points at the score you need on what is left.
struct Dial: View {
    let value: Double
    let state: Need
    var body: some View {
        Canvas { ctx, size in
            let cx = size.width / 2, cy = size.height * 0.82
            let radius = min(size.width * 0.42, size.height * 0.72)
            let startA = Angle.degrees(200), endA = Angle.degrees(-20)
            func angle(_ v: Double) -> Angle { Angle.degrees(startA.degrees + (endA.degrees - startA.degrees) * v / 100) }
            func arc(_ from: Double, _ to: Double) -> Path {
                var p = Path()
                p.addArc(center: CGPoint(x: cx, y: cy), radius: radius, startAngle: angle(from), endAngle: angle(to), clockwise: false)
                return p
            }
            ctx.stroke(arc(0, 100), with: .color(Paper.line2), style: StrokeStyle(lineWidth: 16, lineCap: .round))
            let fillColour: Color
            switch state { case .inTheBag: fillColour = Paper.mint; case .outOfReach: fillColour = Paper.pink; case .locked: fillColour = Paper.dim; case .need(let x): fillColour = x > 90 ? Paper.coral : Paper.marker }
            if value > 0 { ctx.stroke(arc(0, value), with: .color(fillColour), style: StrokeStyle(lineWidth: 16, lineCap: .round)) }
            for tick in stride(from: 0.0, through: 100.0, by: 10.0) {
                let a = angle(tick).radians
                let inner = radius - 22, outer = radius - 14
                var t = Path()
                t.move(to: CGPoint(x: cx + CGFloat(cos(a)) * inner, y: cy + CGFloat(sin(a)) * inner))
                t.addLine(to: CGPoint(x: cx + CGFloat(cos(a)) * outer, y: cy + CGFloat(sin(a)) * outer))
                ctx.stroke(t, with: .color(Paper.dim), lineWidth: 2)
            }
            let na = angle(value).radians
            let needleLen = radius - 34
            var n = Path()
            n.move(to: CGPoint(x: cx, y: cy))
            n.addLine(to: CGPoint(x: cx + CGFloat(cos(na)) * needleLen, y: cy + CGFloat(sin(na)) * needleLen))
            ctx.stroke(n, with: .color(Paper.chalk), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            ctx.fill(Path(ellipseIn: CGRect(x: cx - 9, y: cy - 9, width: 18, height: 18)), with: .color(Paper.chalk))
            let label: String
            switch state { case .inTheBag: label = "locked in"; case .outOfReach: label = "out of reach"; case .locked: label = "done"; case .need(let x): label = Fmt.pct(x) }
            ctx.draw(Text(label).font(.num(30)).foregroundStyle(fillColour), at: CGPoint(x: cx, y: cy - radius * 0.42))
            ctx.draw(Text("on what is left").font(.ui(11, .heavy)).foregroundStyle(Paper.dim), at: CGPoint(x: cx, y: cy - radius * 0.42 + 26))
        }
        .animation(.spring(duration: 0.6), value: value)
    }
}

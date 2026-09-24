import SwiftUI

struct TermEditor: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var rename = false
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(store.hasTerm ? "Terms." : "New term.").font(.head(26)).foregroundStyle(Paper.chalk).padding(.top, 22)
            TextField("Fall 2026", text: $name).font(.ui(18, .heavy)).foregroundStyle(Paper.chalk).field()
            HStack(spacing: 8) {
                if store.hasTerm {
                    GhostButton(title: "Rename current", icon: "pencil") { let n = name.trimmingCharacters(in: .whitespaces); guard !n.isEmpty else { return }; store.renameTerm(n); dismiss() }
                    GhostButton(title: "Delete current", icon: "trash") { store.deleteTerm(); dismiss() }
                }
                MarkerButton(title: "Add as new term", icon: "plus") { let n = name.trimmingCharacters(in: .whitespaces); guard !n.isEmpty else { return }; store.addTerm(n); dismiss() }
            }
            Spacer()
        }.padding(18)
    }
}

struct CourseEditor: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State var course: Course
    let isNew: Bool
    @State private var quick = ""
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                Text(isNew ? "New course." : "Set up.").font(.head(26)).foregroundStyle(Paper.chalk).padding(.top, 22)
                TextField("Organic Chemistry", text: $course.name).font(.ui(18, .heavy)).foregroundStyle(Paper.chalk).field()
                HStack(spacing: 10) {
                    TextField("Instructor", text: $course.instructor).font(.ui(14, .semibold)).foregroundStyle(Paper.chalk).field()
                    HStack(spacing: 6) {
                        Text("\(Fmt.credits(course.credits)) cr").font(.num(14)).foregroundStyle(Paper.chalk)
                        Stepper("", value: $course.credits, in: 0.5...6, step: 0.5).labelsHidden()
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow("Colour")
                    HStack(spacing: 8) {
                        ForEach(0..<Paper.swatches.count, id: \.self) { i in
                            Button { course.colour = i } label: { Circle().fill(Paper.swatch(i)).frame(width: 30, height: 30).overlay(Circle().strokeBorder(Paper.chalk, lineWidth: course.colour == i ? 3 : 0)) }.buttonStyle(.plain)
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow("How it is graded")
                    Picker("", selection: $course.mode) { Text("Weighted categories").tag(Mode.weighted); Text("Total points").tag(Mode.points) }.pickerStyle(.segmented)
                    Picker("", selection: $course.bump) { Text("Regular").tag(0.0); Text("Honors +0.5").tag(0.5); Text("AP / IB +1.0").tag(1.0) }.pickerStyle(.segmented)
                    Text("The bump only changes the weighted GPA.").font(.ui(11, .medium)).foregroundStyle(Paper.dim)
                }
                if course.mode == .weighted {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Eyebrow("Categories")
                            Spacer()
                            Text("\(Fmt.score(course.weightTotal)) of 100").font(.num(12, .bold)).foregroundStyle(abs(course.weightTotal - 100) < 0.01 ? Paper.mint : Paper.marker)
                        }
                        ForEach($course.categories) { $cat in
                            HStack(spacing: 8) {
                                TextField("Name", text: $cat.name).font(.ui(14, .heavy)).foregroundStyle(Paper.chalk)
                                TextField("%", value: $cat.weight, format: .number).keyboardType(.decimalPad).font(.num(14, .bold)).foregroundStyle(Paper.chalk).frame(width: 48).multilineTextAlignment(.trailing)
                                Text("%").font(.ui(12, .heavy)).foregroundStyle(Paper.dim)
                                Menu { ForEach(0..<4, id: \.self) { n in Button(n == 0 ? "Keep all" : "Drop lowest \(n)") { cat.drop = n } } } label: {
                                    Text(cat.drop == 0 ? "keep" : "drop \(cat.drop)").font(.ui(11, .heavy)).foregroundStyle(Paper.chalk2).padding(.horizontal, 8).padding(.vertical, 5).background(Capsule().fill(Paper.card2))
                                }
                                Button { course.categories.removeAll { $0.id == cat.id } } label: { Image(systemName: "xmark").font(.system(size: 11, weight: .black)).foregroundStyle(Paper.dim) }.buttonStyle(.plain)
                            }.padding(.vertical, 4)
                        }
                        GhostButton(title: "Add category", icon: "plus") { course.categories.append(Category(name: "", weight: 0)) }
                        Eyebrow("Quick setup from the syllabus")
                        TextField("Homework 20, Quizzes 15, Midterm 25, Final 40", text: $quick).font(.ui(13, .semibold)).foregroundStyle(Paper.chalk).field()
                        GhostButton(title: "Use this", icon: "wand.and.stars") { parseQuick() }
                    }.tile()
                }
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow("Letter scale, minimum percent")
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                        ForEach($course.scale, id: \.letter) { $st in
                            HStack(spacing: 4) {
                                Text(st.letter).font(.ui(12, .heavy)).foregroundStyle(Paper.chalk).frame(width: 22, alignment: .leading)
                                TextField("", value: $st.min, format: .number).keyboardType(.decimalPad).font(.num(12, .bold)).foregroundStyle(Paper.chalk2).multilineTextAlignment(.trailing)
                            }.padding(.horizontal, 8).frame(height: 32).background(RoundedRectangle(cornerRadius: 8).fill(Paper.bg2))
                        }
                    }
                }.tile()
                HStack(spacing: 8) {
                    if !isNew { GhostButton(title: "Delete course", icon: "trash") { store.remove(course: course.id); dismiss() } }
                    MarkerButton(title: "Save") {
                        let n = course.name.trimmingCharacters(in: .whitespaces); guard !n.isEmpty else { return }
                        var c = course; c.name = n; c.categories.removeAll { $0.name.trimmingCharacters(in: .whitespaces).isEmpty }
                        store.put(c); dismiss()
                    }
                }
            }.padding(18)
        }
    }
    func parseQuick() {
        var out: [Category] = []
        for part in quick.split(whereSeparator: { $0 == "," || $0 == "\n" || $0 == ";" }) {
            let s = part.trimmingCharacters(in: .whitespaces)
            guard let range = s.range(of: #"(\d+(\.\d+)?)\s*%?\s*$"#, options: .regularExpression) else { continue }
            let w = Double(s[range].replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)) ?? 0
            let name = s[..<range.lowerBound].trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: ":-"))
            if !name.isEmpty { out.append(Category(name: name, weight: w)) }
        }
        if !out.isEmpty { course.categories = out; quick = "" }
    }
}

struct AssignmentEditor: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    let courseId: UUID
    @State var assignment: Assignment
    let isNew: Bool
    @State private var scoreText: String
    @State private var outOfText: String
    init(courseId: UUID, assignment: Assignment, isNew: Bool) {
        self.courseId = courseId; self.isNew = isNew
        _assignment = State(initialValue: assignment)
        _scoreText = State(initialValue: assignment.score.map { Fmt.score($0) } ?? "")
        _outOfText = State(initialValue: Fmt.score(assignment.outOf))
    }
    var course: Course { store.course(courseId) ?? Course(name: "") }
    var body: some View {
        let c = course
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                Text(isNew ? "New score." : "Edit score.").font(.head(26)).foregroundStyle(Paper.chalk).padding(.top, 22)
                TextField("Midterm 2", text: $assignment.name).font(.ui(18, .heavy)).foregroundStyle(Paper.chalk).field()
                if c.mode == .weighted && !c.categories.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow("Category")
                        HStack(spacing: 6) {
                            ForEach(c.categories) { cat in
                                Button { assignment.category = cat.id } label: {
                                    Text(cat.name).font(.ui(12, .heavy)).foregroundStyle(assignment.category == cat.id ? Paper.bg : Paper.chalk2).lineLimit(1).minimumScaleFactor(0.7)
                                        .frame(maxWidth: .infinity).frame(height: 36)
                                        .background(RoundedRectangle(cornerRadius: 9).fill(assignment.category == cat.id ? Paper.marker : Paper.card))
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                }
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Eyebrow("Score")
                        TextField("leave blank if not back yet", text: $scoreText).keyboardType(.decimalPad).font(.num(22)).foregroundStyle(Paper.chalk).field()
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Eyebrow("Out of")
                        TextField("100", text: $outOfText).keyboardType(.decimalPad).font(.num(22)).foregroundStyle(Paper.chalk).field()
                    }.frame(width: 120)
                }
                if let s = Double(scoreText), let o = Double(outOfText), o > 0 {
                    HStack { Text(Fmt.pct(s / o * 100)).font(.num(28)).foregroundStyle(Paper.grade(s / o * 100)); Text("on this one").font(.ui(12, .heavy)).foregroundStyle(Paper.dim) }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow("Date")
                    DatePicker("", selection: Binding(get: { Day.date(assignment.date) }, set: { assignment.date = Day.key($0) }), displayedComponents: .date).labelsHidden().datePickerStyle(.compact).tint(Paper.marker)
                }
                Toggle(isOn: $assignment.skipped) { Text("Skip it (excused, does not count)").font(.ui(14, .semibold)).foregroundStyle(Paper.chalk) }.tint(Paper.marker)
                HStack(spacing: 8) {
                    if !isNew { GhostButton(title: "Delete", icon: "trash") { store.remove(assignment: assignment.id, in: courseId); dismiss() } }
                    MarkerButton(title: "Save") {
                        let n = assignment.name.trimmingCharacters(in: .whitespaces); guard !n.isEmpty else { return }
                        var a = assignment; a.name = n
                        a.score = Double(scoreText.trimmingCharacters(in: .whitespaces))
                        a.outOf = max(0.01, Double(outOfText.trimmingCharacters(in: .whitespaces)) ?? 100)
                        store.put(a, in: courseId); dismiss()
                    }
                }
            }.padding(18)
        }
    }
}

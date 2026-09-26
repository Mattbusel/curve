import SwiftUI

// MARK: GPA

struct GPAView: View {
    @Environment(Store.self) private var store
    @Environment(Pro.self) private var pro
    var body: some View {
        let cumU = store.cumulative(weighted: false), cumW = store.cumulative(weighted: true)
        let projU = store.cumulative(weighted: false, whatIf: true), projW = store.cumulative(weighted: true, whatIf: true)
        Page {
            VStack(alignment: .leading, spacing: 4) {
                Text("GPA.").font(.head(34)).foregroundStyle(Paper.chalk)
                Text("Across every term you have logged. Weighted adds the honors and AP bumps.").font(.ui(13, .medium)).foregroundStyle(Paper.chalk2)
            }.padding(.top, 14)
            HStack(spacing: 10) {
                big(Fmt.gpa(cumU.gpa), "cumulative", sub: "\(Fmt.credits(cumU.credits)) credits")
                big(Fmt.gpa(cumW.gpa), "weighted", sub: "with bumps")
            }
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow("By term")
                ForEach(store.terms) { t in
                    let g = store.gpa(t, weighted: false), w = store.gpa(t, weighted: true)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(t.name).font(.ui(14, .heavy)).foregroundStyle(Paper.chalk)
                            Text("\(t.courses.count) courses · \(Fmt.credits(g.credits)) credits").font(.ui(11, .medium)).foregroundStyle(Paper.dim)
                        }
                        Spacer()
                        col(Fmt.gpa(g.gpa), "GPA"); col(Fmt.gpa(w.gpa), "weighted")
                    }.padding(.vertical, 5)
                }
                if store.terms.isEmpty { Text("No terms yet.").font(.ui(13, .medium)).foregroundStyle(Paper.chalk2) }
            }.tile()

            if store.hasTerm && !store.term.courses.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) { Eyebrow("What if · \(store.term.name)"); if !pro.unlocked { ProLock() } }
                    Text("Tap a letter to try a different finish for each course.").font(.ui(12, .medium)).foregroundStyle(Paper.dim)
                    ForEach(store.term.courses) { c in
                        let now = Grade.letter(c)
                        let pick = store.whatIf[c.id]
                        HStack(spacing: 8) {
                            Circle().fill(Paper.swatch(c.colour)).frame(width: 8, height: 8)
                            Text(c.name).font(.ui(13, .heavy)).foregroundStyle(Paper.chalk).lineLimit(1)
                            Spacer()
                            Text(now ?? "--").font(.num(12, .bold)).foregroundStyle(Paper.dim)
                            Image(systemName: "arrow.right").font(.system(size: 10, weight: .black)).foregroundStyle(Paper.dim)
                            let chip = Text(pick ?? now ?? "--").font(.ui(13, .heavy)).foregroundStyle(pick == nil ? Paper.chalk2 : Paper.bg).frame(width: 44, height: 30)
                                .background(RoundedRectangle(cornerRadius: 8).fill(pick == nil ? Paper.card2 : Paper.marker))
                            if pro.unlocked {
                                Menu {
                                    Button("As it stands") { store.whatIf[c.id] = nil }
                                    ForEach(Scale.order, id: \.self) { l in Button(l) { store.whatIf[c.id] = l } }
                                } label: { chip }
                            } else {
                                Button { pro.ask(.whatIf) } label: { chip }.buttonStyle(.plain)
                            }
                        }
                    }
                    Divider().overlay(Paper.line2)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Projected").font(.ui(11, .heavy)).foregroundStyle(Paper.dim)
                            Text("term \(Fmt.gpa(store.gpa(store.term, weighted: false, whatIf: true).gpa)) · weighted \(Fmt.gpa(store.gpa(store.term, weighted: true, whatIf: true).gpa))").font(.num(13, .bold)).foregroundStyle(Paper.chalk)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Cumulative").font(.ui(11, .heavy)).foregroundStyle(Paper.dim)
                            Text("\(Fmt.gpa(projU.gpa)) · \(Fmt.gpa(projW.gpa))").font(.num(13, .bold)).foregroundStyle(Paper.marker)
                        }
                    }
                }.tile()
            }

            VStack(alignment: .leading, spacing: 10) {
                Eyebrow("Points per letter")
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                    ForEach(Scale.order, id: \.self) { l in
                        HStack(spacing: 4) {
                            Text(l).font(.ui(12, .heavy)).foregroundStyle(Paper.chalk).frame(width: 22, alignment: .leading)
                            TextField("", value: Binding(get: { store.pointMap[l] ?? 0 }, set: { store.pointMap[l] = $0; store.save() }), format: .number).keyboardType(.decimalPad).font(.num(12, .bold)).foregroundStyle(Paper.chalk2).multilineTextAlignment(.trailing)
                        }.padding(.horizontal, 8).frame(height: 32).background(RoundedRectangle(cornerRadius: 8).fill(Paper.bg2))
                    }
                }
            }.tile()

            ProCard()
        }
    }
    func big(_ v: String, _ l: String, sub: String) -> some View {
        VStack(alignment: .leading, spacing: 2) { Text(v).font(.num(38)).foregroundStyle(Paper.marker); Text(l).font(.ui(11, .heavy)).foregroundStyle(Paper.chalk2); Text(sub).font(.ui(11, .medium)).foregroundStyle(Paper.dim) }.frame(maxWidth: .infinity, alignment: .leading).tile(padding: 14)
    }
    func col(_ v: String, _ l: String) -> some View {
        VStack(spacing: 0) { Text(v).font(.num(14, .bold)).foregroundStyle(Paper.chalk); Text(l).font(.ui(9, .heavy)).foregroundStyle(Paper.dim) }.frame(width: 60)
    }
}

// MARK: Report

struct ReportView: View {
    @Environment(Store.self) private var store
    @Environment(Pro.self) private var pro
    @State private var pdf: URL? = nil
    var body: some View {
        Page {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Report.").font(.head(34)).foregroundStyle(Paper.chalk)
                    Text("A one-page term report to share or print.").font(.ui(13, .medium)).foregroundStyle(Paper.chalk2)
                }
                Spacer()
            }.padding(.top, 14)
            ReportSheet(store: store).tile(padding: 0, radius: 14)
            if pro.unlocked {
                HStack(spacing: 8) {
                    if let pdf { ShareLink(item: pdf) { shareLabel("Share PDF", "doc.richtext") } } else { shareLabel("Preparing PDF", "hourglass") }
                    ShareLink(item: store.csv()) { shareLabel("Export CSV", "tablecells") }
                }
            } else {
                Button { pro.ask(.report) } label: { shareLabel("Share PDF and CSV with Curve Pro", "lock.fill") }.buttonStyle(.plain)
            }
        }
        .task { pdf = PDF.make(store) }
        .onChange(of: store.terms) { _, _ in pdf = PDF.make(store) }
    }
    func shareLabel(_ t: String, _ i: String) -> some View {
        HStack(spacing: 8) { Image(systemName: i).font(.system(size: 14, weight: .black)); Text(t).font(.ui(14, .heavy)) }
            .foregroundStyle(Paper.bg).frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Paper.marker))
    }
}

/// The paper report itself: light, printable, chalk on cream.
struct ReportSheet: View {
    let store: Store
    var body: some View {
        let t = store.term
        let g = store.gpa(t, weighted: false), w = store.gpa(t, weighted: true), cum = store.cumulative(weighted: false)
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(t.name).font(.system(size: 24, weight: .heavy, design: .serif)).foregroundStyle(.black)
                    Text("Term report · \(Date.now.formatted(.dateTime.month(.wide).day().year()))").font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(.black.opacity(0.55))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text(Fmt.gpa(g.gpa)).font(.system(size: 26, weight: .heavy, design: .rounded).monospacedDigit()).foregroundStyle(.black)
                    Text("term GPA · \(Fmt.gpa(w.gpa)) weighted").font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(.black.opacity(0.55))
                }
            }
            Rectangle().fill(.black.opacity(0.15)).frame(height: 1)
            ForEach(t.courses) { c in
                let r = Grade.result(c)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(c.name).font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(.black)
                        Text("\(Fmt.credits(c.credits)) cr" + (c.instructor.isEmpty ? "" : " · " + c.instructor)).font(.system(size: 10, weight: .semibold, design: .rounded)).foregroundStyle(.black.opacity(0.5))
                        Spacer()
                        Text(r.pct.map { Fmt.pct($0) } ?? "--").font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit()).foregroundStyle(.black.opacity(0.7))
                        Text(r.pct.map { Scale.letter($0, c.scale) } ?? "--").font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(.white).frame(width: 34, height: 22).background(RoundedRectangle(cornerRadius: 6).fill(Color(red: 0.11, green: 0.27, blue: 0.21)))
                    }
                    if c.mode == .weighted {
                        Text(c.categories.map { cat in "\(cat.name) \(Fmt.score(cat.weight))%: \(Grade.catAverage(c, cat).map { Fmt.pct($0) } ?? "not yet")" }.joined(separator: "  ·  ")).font(.system(size: 9.5, weight: .medium, design: .rounded)).foregroundStyle(.black.opacity(0.6)).lineLimit(2)
                    } else {
                        Text("Total points: \(Fmt.score(r.earnedW / 100)) of \(Fmt.score(r.gradedW)) graded, \(Fmt.score(r.totalW)) in the course").font(.system(size: 9.5, weight: .medium, design: .rounded)).foregroundStyle(.black.opacity(0.6))
                    }
                }
            }
            Rectangle().fill(.black.opacity(0.15)).frame(height: 1)
            HStack {
                Text("Cumulative \(Fmt.gpa(cum.gpa)) over \(Fmt.credits(cum.credits)) credits across \(store.terms.count) term\(store.terms.count == 1 ? "" : "s").").font(.system(size: 10, weight: .semibold, design: .rounded)).foregroundStyle(.black.opacity(0.6))
                Spacer()
                Text("Made with Curve").font(.system(size: 9, weight: .heavy, design: .rounded)).foregroundStyle(.black.opacity(0.35))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.98, green: 0.97, blue: 0.93))
    }
}

enum PDF {
    @MainActor
    static func make(_ store: Store) -> URL? {
        let view = ReportSheet(store: store).frame(width: 560)
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = ProposedViewSize(width: 560, height: nil)
        let url = URL.temporaryDirectory.appending(path: "\(store.term.name) report.pdf")
        var done = false
        renderer.render { size, draw in
            var box = CGRect(origin: .zero, size: CGSize(width: 612, height: max(792, size.height + 52)))
            guard let ctx = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            ctx.beginPDFPage(nil)
            ctx.translateBy(x: 26, y: box.height - size.height - 26)
            draw(ctx)
            ctx.endPDFPage(); ctx.closePDF(); done = true
        }
        return done ? url : nil
    }
}

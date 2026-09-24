import Foundation

enum Demo {
    static func fill(_ s: Store) {
        let t = Day.today
        func d(_ n: Int) -> String { Day.add(t, n) }
        func cat(_ n: String, _ w: Double, drop: Int = 0) -> Category { Category(name: n, weight: w, drop: drop) }
        func a(_ n: String, _ c: Category?, _ score: Double?, _ outOf: Double, _ day: Int) -> Assignment { Assignment(name: n, category: c?.id, score: score, outOf: outOf, date: d(day)) }

        // A finished term.
        func done(_ name: String, _ credits: Double, _ colour: Int, _ pct: Double, bump: Double = 0) -> Course {
            let c = cat("Overall", 100)
            return Course(name: name, credits: credits, colour: colour, bump: bump, categories: [c], assignments: [a("Final grade", c, pct, 100, -130)])
        }
        let spring = Term(name: "Spring 2026", courses: [
            done("Calculus I", 4, 0, 91.2), done("General Chemistry", 4, 3, 84.5), done("Composition", 3, 2, 95.0), done("Psychology 101", 3, 1, 88.0),
        ])

        // Calculus II
        let cHW = cat("Homework", 20, drop: 1), cQ = cat("Quizzes", 15), cM = cat("Midterms", 40), cF = cat("Final exam", 25)
        let calc = Course(name: "Calculus II", credits: 4, instructor: "Dr. Okafor", colour: 0, categories: [cHW, cQ, cM, cF], assignments: [
            a("HW 1 Integration by parts", cHW, 18, 20, -33), a("HW 2 Trig substitution", cHW, 20, 20, -26), a("HW 3 Partial fractions", cHW, 17, 20, -19),
            a("HW 4 Improper integrals", cHW, 19, 20, -12), a("HW 5 Sequences", cHW, 15, 20, -5), a("HW 6 Series tests", cHW, nil, 20, 1),
            a("Quiz 1", cQ, 9, 10, -22), a("Quiz 2", cQ, 8, 10, -8), a("Quiz 3", cQ, nil, 10, 8),
            a("Midterm 1", cM, 84, 100, -6), a("Midterm 2", cM, nil, 100, 40), a("Final exam", cF, nil, 100, 80),
        ])
        // Organic Chemistry
        let oHW = cat("Homework", 15), oQ = cat("Quizzes", 10), oL = cat("Lab reports", 25), oM = cat("Midterm", 25), oF = cat("Final exam", 25)
        let orgo = Course(name: "Organic Chemistry", credits: 4, instructor: "Dr. Lindqvist", colour: 3, categories: [oHW, oQ, oL, oM, oF], assignments: [
            a("Problem set 1", oHW, 42, 50, -31), a("Problem set 2", oHW, 47, 50, -24), a("Problem set 3", oHW, 38, 50, -17), a("Problem set 4", oHW, 45, 50, -10),
            a("Quiz 1 Nomenclature", oQ, 7, 10, -27), a("Quiz 2 Stereochemistry", oQ, 8, 10, -13), a("Quiz 3 Reactions", oQ, 6, 10, -3),
            a("Lab 1 Recrystallization", oL, 88, 100, -28), a("Lab 2 Distillation", oL, 92, 100, -18), a("Lab 3 Extraction", oL, 79, 100, -9), a("Lab 4 Chromatography", oL, nil, 100, 7),
            a("Midterm", oM, 71, 100, -5), a("Final exam", oF, nil, 100, 79),
        ])
        // Intro to Economics
        let eP = cat("Problem sets", 30), eM = cat("Midterm", 30), eF = cat("Final exam", 40)
        let econ = Course(name: "Intro to Economics", credits: 3, instructor: "Dr. Marsh", colour: 1, categories: [eP, eM, eF], assignments: [
            a("Problem set 1", eP, 28, 30, -30), a("Problem set 2", eP, 30, 30, -23), a("Problem set 3", eP, 27, 30, -16), a("Problem set 4", eP, 29, 30, -9), a("Problem set 5", eP, nil, 30, 9),
            a("Midterm", eM, 89, 100, -4), a("Final exam", eF, nil, 100, 86),
        ])
        // Spanish 201
        let sH = cat("Homework", 25), sC = cat("Compositions", 25), sO = cat("Oral exams", 20), sF = cat("Final exam", 30)
        let span = Course(name: "Spanish 201", credits: 3, instructor: "Sra. Delgado", colour: 2, categories: [sH, sC, sO, sF], assignments: [
            a("Tarea 1", sH, 9, 10, -32), a("Tarea 2", sH, 10, 10, -25), a("Tarea 3", sH, 8, 10, -18), a("Tarea 4", sH, 10, 10, -11), a("Tarea 5", sH, 9, 10, -4),
            a("Composition 1", sC, 44, 50, -14), a("Composition 2", sC, nil, 50, 9),
            a("Oral exam 1", sO, 17, 20, -7), a("Final exam", sF, nil, 100, 83),
        ])
        // Art History, total points
        let art = Course(name: "Art History", credits: 3, instructor: "Dr. Petrova", colour: 4, mode: .points, assignments: [
            a("Response 1", nil, 18, 20, -34), a("Response 2", nil, 19, 20, -27), a("Response 3", nil, 17, 20, -20), a("Response 4", nil, 20, 20, -13), a("Response 5", nil, 19, 20, -6),
            a("Response 6", nil, nil, 20, 5), a("Museum paper", nil, 91, 100, -8), a("Quiz", nil, 44, 50, -15), a("Midterm exam", nil, 87, 100, -2), a("Final exam", nil, nil, 150, 85),
        ])
        let fall = Term(name: "Fall 2026", courses: [calc, orgo, econ, span, art])
        s.terms = [spring, fall]
        s.cur = 1
    }
}

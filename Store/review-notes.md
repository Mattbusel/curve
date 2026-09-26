# App Review notes

---

No account, login or network connection is required.

HOW TO USE: Tap the calendar button on the Term tab to add a term, then "Add a course". Type the course name and its categories with weights (or paste "Homework 20, Quizzes 15, Midterm 25, Final 40" into Quick setup), save. Open the course and tap "Score" to log an assignment. "What do I need?" solves for the score needed on what is still ungraded. The GPA tab shows term and cumulative GPA with a what-if projection; the Report tab shares a PDF or CSV (Pro).

IN-APP PURCHASE: the app is free. One non-consumable, "Curve Pro" (com.mattbusel.curve.pro, $2.99), unlocks more than one term with a cumulative GPA, the what-if projection, drop-lowest in categories, and the PDF report and CSV export. The current term, courses, scores, grades, the need dial and the term GPA are free with no limit. To see the paywall: open the GPA tab and tap any letter in the "What if" card; or open the Report tab and tap "Share PDF and CSV with Curve Pro"; or, once a term exists, tap the calendar button on the Term tab and choose "New term (Pro)". Restore purchase is on the paywall and on the Curve Pro card at the bottom of the GPA tab. No subscription.

PRIVACY: no data is collected. Everything is stored in a JSON file in the app's Documents folder on the device. No notifications. The only network use is StoreKit, to buy or restore Curve Pro.

2. PURPOSE AND TARGET AUDIENCE
Curve is a personal grade tracker and final exam calculator for high school and college students: weighted categories, running grades, the score needed on the final, GPA across terms. General audience; rated 4+.

3. SETUP AND ACCESS
No setup, login or credentials. A new install starts empty; add a term and a course.

4. EXTERNAL SERVICES, TOOLS AND PLATFORMS
Apple StoreKit 2 for the one in-app purchase. No other network requests, no analytics, advertising or third-party frameworks. Built with SwiftUI, Swift Charts, StoreKit and Foundation. PDF export uses ImageRenderer; sharing uses the system share sheet.

5. REGIONAL DIFFERENCES
None.

6. REGULATED INDUSTRY / PROTECTED MATERIAL
Not applicable. All art, text and code are my own work.

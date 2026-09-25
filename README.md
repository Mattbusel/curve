# Curve

A grade tracker for iPhone that answers the question every student asks in December: what do I need on the final?

![iOS 17+](https://img.shields.io/badge/iOS-17%2B-black) ![SwiftUI](https://img.shields.io/badge/SwiftUI-Swift%205-orange) ![Built on GitHub Actions](https://img.shields.io/badge/built%20on-GitHub%20Actions%20macOS-2088FF)

**Coming to the App Store.**

<p align="center">
  <img src="fastlane/screenshots/en-US/01_iPhone.png" width="250" alt="Curve screenshot">
  <img src="fastlane/screenshots/en-US/02_iPhone.png" width="250" alt="Curve screenshot">
  <img src="fastlane/screenshots/en-US/03_iPhone.png" width="250" alt="Curve screenshot">
</p>

Type your syllabus once and log each score as it comes back. Curve keeps the real weighted grade, shows where it is heading, and solves for the score you need on everything still ungraded.

## Features

- Every course on one page with grade, letter, a trend arrow and what is due next; term, weighted and cumulative GPA
- Weighted categories or total points, drop the lowest N, custom letter scales with plus and minus, honors and AP bumps
- Quick setup from text like "Homework 20, Quizzes 15, Midterm 25, Final 40"
- What do I need: pick a target letter or percent and Curve solves for the rest, and says so when a grade is locked in or out of reach
- Honest maths: empty categories are left out and the rest re-weighted, with a note; a running grade chart per course
- GPA what-if, editable points per letter, a one-page PDF term report and a CSV of every score

## Price

A paid app: one price, no in-app purchases, no subscription, no ads.

## Privacy

No network code at all: Curve makes no requests and collects no data. Everything is saved on the device in `curve.json`. The privacy manifest (`Resources/PrivacyInfo.xcprivacy`) declares no tracking and no collected data types.

## Built without a Mac

This app was written on a Windows PC. No Mac is involved at any point: every build, signature, screenshot and App Store submission runs on GitHub Actions macOS runners, driven by the App Store Connect API.

- **`project.yml`** is an [XcodeGen](https://github.com/yonaskolb/XcodeGen) spec. The `.xcodeproj` is generated on the runner and never committed, so the repo can be edited on any OS and there are no `.pbxproj` merge conflicts.
- **`.github/workflows/build.yml`** runs on every push: picks the newest Xcode 26 and iPhone simulator on the runner, builds, then launches the app once per screen with `-shot <screen>` (sample data, fixed 9:41 status bar) and captures the store screenshots with `simctl`, uploaded as a workflow artifact.
- **`.github/workflows/appstore.yml`** (manual) has three modes: `compile`, `dry_run` (build, sign, upload, do not submit) and `release` (also submits for review). The distribution certificate is imported from a secret into a throwaway keychain; [fastlane](https://fastlane.tools) (`fastlane/Fastfile`) fetches the App Store profile with the API key, sets the build number one above the latest on TestFlight, archives, and uploads the binary with `fastlane/metadata` and the committed `fastlane/screenshots`.
- **`.github/workflows/review-video.yml`** records the App Review screen recording: the app is launched with `-demoAutoplay` and drives its own real screens.
- **`Store/*.py`** talk to the App Store Connect API directly from Windows (Python, `requests` + `PyJWT`): `asc.py` registers the bundle id and pushes metadata, `listing.py` sets the age rating, review details, price and screenshots, and `signing.py` creates the distribution certificate locally so its private key is never stranded on a disposable runner.

Only one step is manual: Apple's API will not create the app record itself, so that is made once in the App Store Connect web UI.

## Build and run

With a Mac and Xcode 26 (the version CI uses; the app targets iOS 17+):

```bash
brew install xcodegen
xcodegen generate
open Curve.xcodeproj
```

Run the `Curve` scheme on any iPhone simulator. No signing is needed for the simulator; from the command line:

```bash
xcodebuild build -project Curve.xcodeproj -scheme Curve \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' CODE_SIGNING_ALLOWED=NO
```

To see it filled with sample data, launch with a screenshot argument, e.g. `xcrun simctl launch booted com.mattbusel.curve -shot term`.

Without a Mac: fork the repo and push. The Build workflow compiles it on a GitHub macOS runner and attaches the screenshots as an artifact.

Shipping your own build needs these repository secrets: `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_CONTENT` (base64 of the `.p8`), `DEVELOPMENT_TEAM`, `DIST_CERT_P12`, `DIST_CERT_PASSWORD`, plus your own bundle id in `project.yml` and `fastlane/Fastfile`.

## Code map

All app code is in `Sources/` (SwiftUI, Observation, no third-party dependencies).

| File | What it does |
| --- | --- |
| `App.swift` | entry point, tabs, `-shot` handling |
| `Model.swift` | the grade engine: weights, drops, letter scales, the needed-score solver, JSON persistence |
| `Views.swift` | term dashboard, course and what-do-I-need screens |
| `Editors.swift` | course and score editors |
| `Report.swift` | GPA, the PDF term report and CSV export |
| `Theme.swift` | graph paper and chalk look |
| `Demo.swift` / `Autopilot.swift` | screenshot data and the App Review recording |

`Store/` holds the App Store Connect scripts, `fastlane/` the lanes, listing text and screenshots, `Resources/` the asset catalog and privacy manifest.

---

**More apps built the same way:** [Chain](https://github.com/Mattbusel/chain), [Ironbook](https://github.com/Mattbusel/ironbook), [Quiver](https://github.com/Mattbusel/quiver), [Race Fuel](https://github.com/Mattbusel/race-fuel), [Minder](https://github.com/Mattbusel/minder), [Baseline Ledger](https://github.com/Mattbusel/baseline-ledger), [Fairway Ledger](https://github.com/Mattbusel/fairway-ledger), [Odometer](https://github.com/Mattbusel/odometer), [Rooms](https://github.com/Mattbusel/rooms), [Clockout](https://github.com/Mattbusel/clockout), [Pricebook](https://github.com/Mattbusel/pricebook), [Chores](https://github.com/Mattbusel/chores), [Pawprint](https://github.com/Mattbusel/pawprint), [Pocket Beings](https://github.com/Mattbusel/pocket-beings), [Glyphstorm](https://github.com/Mattbusel/glyphstorm), [Clear the Strait](https://github.com/Mattbusel/clear-the-strait).

# "notepod" → "rrm_alpha" Rename Report

Generated 2026-07-08. This documents a repository-wide, case-insensitive,
literal replacement of the string `notepod` with `rrm_alpha` (content and
file/directory names), performed across the whole working tree (excluding
`.git/`, `build/`, `.dart_tool/`, which are untracked/generated).

- 112 files had textual content changed.
- 19 files/directories were renamed (git-tracked where possible; two
  untracked `.iml` IDE files were renamed with a plain `mv`).
- Verified afterwards with `flutter pub get` (succeeded) and
  `flutter analyze` (no new compile errors; see "Lint-only regressions"
  below).

Full list of renamed paths and full-text diff are visible via `git status`
/ `git diff` in the repo; this report focuses on **why specific changes
may break things that live outside this repository**, since a plain
find-and-replace cannot know about external registrations.

## High-risk: external systems this repo does not control

### 1. Solid Pod data storage path (data-loss risk for existing users)
- `lib/constants/paths.dart:30` — `basePath`: `'notepod/data'` → `'rrm_alpha/data'`
- `lib/constants/app.dart:71` — `appDir`: `'notepod'` → `'rrm_alpha'`

The app reads/writes notes under a container named by `appDir`/`basePath`
inside each user's Solid Pod. Any notes previously saved by real users
under the `notepod/` container will **not** be found by the app anymore
— they are not deleted, just orphaned at the old path. If this app has
already been used to store real data, a migration (or a fallback read
from the old path) is needed before shipping this rename.

### 2. Hard-coded Solid Pod server hostname
- `lib/constants/app.dart:214` — `appUrl`: `'https://notepod.solidcommunity.au'` → `'https://rrm_alpha.solidcommunity.au'`

This was a literal replacement, but `rrm_alpha.solidcommunity.au` is
almost certainly **not a real, provisioned DNS host**. If `appUrl` is
used for login / Pod discovery / "invite others" links, this now points
at a server that likely doesn't exist. **This line should be reviewed
manually** — either point it at the correct real Pod host, or provision
`rrm_alpha.solidcommunity.au` before release.

### 3. Upstream project links now point at a non-existent repo
- `lib/constants/app.dart:35,37,65` and `installers/app-windows.iss:7` — `https://github.com/anusii/notepod...` → `https://github.com/anusii/rrm_alpha...`

These referenced the **upstream ANU SII project** (`github.com/anusii`),
which this codebase is a fork/derivative of — not this repository
(`redsq129/rrm_alpha_notepod`). The literal replacement now points at
`github.com/anusii/rrm_alpha`, which does not exist. Decide manually
whether these should point at this fork's actual URL
(`https://github.com/redsq129/rrm_alpha_notepod`) or be removed.

### 4. App identity (bundle ID / application ID / OAuth redirect scheme)
- `android/app/build.gradle.kts:8,19,27` — `namespace`, `applicationId`, and `appAuthRedirectScheme`: `com.togaware.notepod` → `com.togaware.rrm_alpha`
- `ios/Runner.xcodeproj/project.pbxproj`, `macos/Runner.xcodeproj/project.pbxproj`, `macos/Runner/Configs/AppInfo.xcconfig(.signed)`, `macos/Runner/*.entitlements` — `PRODUCT_BUNDLE_IDENTIFIER`: `com.togaware.notepod` → `com.togaware.rrm_alpha`

Changing the application/bundle ID makes this a **different app** as far
as Google Play, the Apple App Store/TestFlight, and any OS are
concerned:
- Existing installs on any store release under `com.togaware.notepod`
  cannot be updated in place to `com.togaware.rrm_alpha` — users would
  need to install a separate app.
- `appAuthRedirectScheme` is the custom URL scheme `flutter_appauth` uses
  for the OAuth/OIDC redirect back into the app after Solid Pod login.
  If this exact scheme is registered with any Identity Provider client
  configuration outside this repo, login will break until that
  registration is updated to match.
- Any existing signing keystores / provisioning profiles tied to the old
  identifier will need re-linking to the new one.

### 5. Apple provisioning profile name (CI signing will fail until fixed in App Store Connect)
- `.github/workflows/installers.yaml:549,555,557` (comments) — profile name `NotePod_Mac_Distribution_Mac_Appstore_Connect` → `rrm_alpha_Mac_Distribution_Mac_Appstore_Connect`, and `Profile linked apps: com.togaware.notepod` → `com.togaware.rrm_alpha`

These are only comments today, but if/when signing is enabled, the
**actual provisioning profile registered in Apple Developer / App Store
Connect** is still named `NotePod_...` and linked to the old bundle ID.
It must be recreated (or renamed) and re-linked to
`com.togaware.rrm_alpha` before CI signing will work.

### 6. Snap Store package name (global registration, not just a config value)
- `snap/snapcraft.yaml:1` — `name: notepod` → `name: rrm_alpha`
- `snap/gui/rrm_alpha.desktop` (renamed from `notepod.desktop`), `Exec=` line updated to match

Snap Store names are globally unique and must be registered with
Canonical (`snapcraft register rrm_alpha`) before `snapcraft upload` will
work — this file change alone does not transfer or claim the name, and
`rrm_alpha` may or may not be available. The original `notepod` snap (if
published) is unaffected and remains live under Canonical's registry.

### 7. Installer / update-channel naming (breaks upgrade path for existing installs)
- `installers/app-windows.iss:4,7,8,46` — `MyAppName`, `MyAppExeName` (`notepod.exe` → `rrm_alpha.exe`), `OutputBaseFilename` (`notepod-{version}` → `rrm_alpha-{version}`)
- `installers/deb.sh:38` — Debian package `Name=Notepod` → `Name=rrm_alpha`
- `installers/update.sh` — comment only reference, but confirm the script's real update-check logic (URLs/filenames it fetches) doesn't hard-code the old `notepod-*` artifact naming anywhere it matters

Any users with an existing Windows/Debian install of the old-named
package will not be recognized as "the same app" to upgrade in place —
this is effectively a new package identity. If there's a live
self-hosted auto-update mechanism watching for `notepod-*` release
artifacts, it needs to be repointed at `rrm_alpha-*`, or old clients will
stop receiving updates.

### 8. CI artifact naming
- `.github/workflows/installers.yaml:45` — `APP: notepod` → `APP: rrm_alpha`

This env var drives generated release artifact filenames. Any release
notes, download links, or external documentation referencing the old
`notepod-*` filenames will need updating to `rrm_alpha-*`.

## Lower-risk: internal renames (mechanical, self-consistent)

These were verified consistent via `flutter pub get` and `flutter
analyze` and require no external coordination:
- Dart package name `notepod` → `rrm_alpha` in `pubspec.yaml`, and every
  `import 'package:notepod/...'` → `import 'package:rrm_alpha/...'`
  across `lib/` and `test/`.
- `lib/notepod.dart` renamed to `lib/rrm_alpha.dart`.
- Android Kotlin package directory
  `android/app/src/main/kotlin/com/togaware/notepod/` renamed to
  `.../com/togaware/rrm_alpha/`, matching the updated `package` statement
  in `MainActivity.kt`.
- Asset image files under `assets/images/` (e.g. `notepod.png`,
  `notepod_menu.png`, `notepod.iconset/`, etc.) renamed to their
  `rrm_alpha` equivalents; references in `lib/constants/app.dart`,
  `lib/home.dart`, `installers/app.desktop`, `installers/README.md`, and
  the `exercises/*.md` walkthroughs were updated to match.
- `windows/runner/Runner.rc`, `linux/my_application.cc`, `web/index.html`,
  `web/manifest.json`, docs (`README.md`, `CHANGELOG.md`, `GUIDE.md`,
  `release/**/*.md`, `exercises/*.md`), and IDE project files
  (`rrm_alpha.iml`, `android/rrm_alpha_android.iml`, `.idea/modules.xml`).

## Lint-only regressions from the literal, case-insensitive replacement

Because the requested replacement was a literal string swap, a few
`camelCase`/`PascalCase` identifiers that had "Notepod"/"notepod" as an
inner word fragment now contain the literal snake_case token
`rrm_alpha` embedded in them. These still compile and run correctly
(confirmed via `flutter analyze`: 0 new errors), but read awkwardly and
trip Dart's naming-convention lints. Left as-is since choosing a
stylized replacement (e.g. `RrmAlpha` vs `rrmAlpha`) wasn't specified —
recommend a manual pass if desired:

| File | Identifier now | Was |
|---|---|---|
| `lib/constants/colours.dart:57` | `defaultrrm_alphaColors` | `defaultNotepodColors` |
| `lib/constants/turtle_structures.dart:42` | `rrm_alphaTerms` | `notepodTerms` |
| `lib/utils/public_sharing_transform.dart:48` | `registerrrm_alphaPublicSharingHooks` | `registerNotepodPublicSharingHooks` |
| `lib/rrm_alpha.dart:44` | `class rrm_alpha extends StatelessWidget` | `class NotePod extends StatelessWidget` |

Note: `rrm_alphaTerms` (turtle_structures.dart) is only a Dart variable
name / Turtle `@prefix` alias used when serializing notes to RDF — the
underlying namespace IRI it holds (`https://solidcommunity.au/predicates/terms#`)
was not affected, so previously-written note files remain readable.

## Not changed / out of scope

- `.git/` history — old commits still reference `notepod` in messages
  and historical file content; this was not rewritten.
- No external accounts, DNS records, OAuth client registrations, App
  Store Connect / Play Console listings, or Snap Store names were
  created or modified — only local repository files.

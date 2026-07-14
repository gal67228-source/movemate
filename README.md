# MoveMate

MoveMate is a Hebrew-first Flutter application for managing a home move: tasks,
rooms, boxes, items for sale, shopping and budget tracking.

## Current version

This repository contains the Sprint 1 starter:

- Hebrew and RTL support
- Material 3 light and dark themes
- Navigation with `go_router`
- State-management foundation with Riverpod
- Welcome screen
- Create-move wizard
- Dashboard prototype
- Tasks prototype
- GitHub Actions CI for Android

## Run locally

Install the current Flutter stable SDK, clone the repository, and run:

```bash
./scripts/bootstrap.sh
flutter run
```

On Windows PowerShell, use:

```powershell
flutter create . --platforms=android --org com.movemate --project-name movemate
flutter pub get
flutter run
```

## Continuous integration

`.github/workflows/flutter-ci.yml` runs automatically on every push and pull
request. The workflow:

1. Installs Java and Flutter stable.
2. Generates the Android platform project when it is missing.
3. Installs packages.
4. Verifies Dart formatting.
5. Runs `flutter analyze`.
6. Runs all Flutter tests.
7. Builds a release APK.
8. Uploads the APK as a GitHub Actions artifact for 14 days.

To download an APK, open the repository's **Actions** tab, select a successful
workflow run, and download the artifact named `movemate-android-apk-*`.

## First GitHub upload

Create an empty GitHub repository named `movemate`, then run from this folder:

```bash
git init
git add .
git commit -m "Initial MoveMate Flutter app with Android CI"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/movemate.git
git push -u origin main
```

The first push starts the CI workflow automatically.

## Useful local checks

Run these before pushing:

```bash
dart format lib test
flutter analyze
flutter test
flutter build apk --release
```

## Next sprint

- Persist moves and tasks locally
- Add task creation, editing and deletion
- Add rooms and boxes
- Calculate real dashboard progress

## GitHub Copilot

Project-wide development rules are stored in:

```text
.github/copilot-instructions.md
```

GitHub Copilot uses this file as repository instructions so generated changes follow MoveMate's Flutter architecture, Hebrew RTL requirements, Riverpod/Drift conventions, testing rules, and CI standards.

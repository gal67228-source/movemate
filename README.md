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

On Windows Command Prompt, use:

```bat
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

## One-command GitHub publishing

The project includes an automatic publishing tool. It:

1. Installs Flutter packages.
2. Formats the Dart source.
3. Runs static analysis and tests.
4. Builds a local debug APK unless disabled.
5. Stages all changes and creates a Git commit.
6. Pushes the current branch to `origin`.
7. Waits for the matching GitHub Actions run when GitHub CLI is installed.

### macOS / Linux

```bash
./scripts/publish.sh "Describe the change"
```

### Windows

Double-click `publish.bat`, or run from Command Prompt:

```bat
publish.bat "Describe the change"
```

The Windows launcher calls the cross-platform `scripts\publish.py` script directly. PowerShell is not used.

### Useful options

macOS / Linux:

```bash
./scripts/publish.sh "Update dashboard" --skip-local-build
./scripts/publish.sh "Small documentation update" --skip-checks
./scripts/publish.sh "Push without waiting" --no-wait
./scripts/publish.sh "Open CI page" --open
```

Windows Command Prompt:

```bat
publish.bat "Update dashboard" --skip-local-build
publish.bat "Small documentation update" --skip-checks
publish.bat "Push without waiting" --no-wait
publish.bat "Open CI page" --open
```

`--skip-checks` should be used only when necessary. GitHub Actions still performs
all required CI checks after the push.

### Optional GitHub CLI integration

Install GitHub CLI and authenticate once:

```bash
gh auth login
```

After that, the publishing tool waits for the CI result and returns a failure exit
code when the workflow fails. Without `gh`, pushing still starts CI automatically,
but the tool only prints the GitHub Actions address.

### First-time setup

The repository must already have an `origin` remote:

```bash
git remote add origin https://github.com/YOUR_USERNAME/movemate.git
git branch -M main
git push -u origin main
```

After the first setup, use only the publishing command for normal updates.

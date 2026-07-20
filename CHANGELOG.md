## 0.99.7+46

- Added a Smart Move readiness score based on tasks, packing, boxes, shopping, and sales.
- Added a move timeline showing the next open tasks.
- Added a room-grouped list of items that are still not packed.
- Added one-tap completion of missing recommended tasks based on the move date.
- Added readiness insights and countdown access from the dashboard.

## 0.99.6+45

- Pinned FlutterFire to the official compatible set: firebase_core 3.13.0, firebase_auth 5.5.2, and cloud_firestore 5.6.6.
- Avoided the Firebase Android SDK release compiled with Kotlin metadata 2.3.
- Disabled Gradle file-system watching and background daemons in CI.
- Forced Kotlin compilation in-process with limited workers for deterministic GitHub Actions builds.
- Added a CI check that verifies the exact Firebase dependency versions before analysis and build.

# Changelog

## 0.99.5

- Removed box and inventory photo capture and gallery selection.
- Removed Firebase Storage and image picker dependencies.
- Kept QR generation and scanning for boxes.
- Removed Storage rules and Storage deployment configuration.
- Preserved legacy image fields only for backward-compatible data loading.

- Run Flutter CI on pushes to `main` only.
- Run pull request CI only when targeting `main`.
- Prevent duplicate/stale runs with a workflow-aware concurrency group.
- Reduce Dependabot updates to monthly with one open PR per ecosystem.

## 0.99.3+42

- Added stable QR codes for moving boxes.
- Added QR scanning to open a box directly.
- Added camera/gallery photos for boxes and room inventory items.
- Added Firebase Storage uploads for signed-in users with local fallback.
- Added secure `storage.rules` for move owners and shared members.
- Added QR and media migration tests.

## 0.99.2+41

- Added Android system sharing for move invitation codes.
- Invitations can now be sent through WhatsApp, email, messaging apps, and any installed share target.
- Kept copy-to-clipboard as a separate quick action.

## 0.99.1+40

- Fixed async BuildContext lint in the sharing screen.

# Changelog

## 0.99.0+39

- Added Cloud Firestore synchronization while keeping Drift as the local source of truth.
- Added last-write-wins comparison using local and server timestamps.
- Added live remote update listening for shared moves.
- Added invitation codes that expire after seven days.
- Added shared move member management for owners.
- Added a sharing and sync status screen.
- Added Firestore security rules and setup documentation.

## 0.98.5+38

- Removed the demo preview action from the new move flow.
- Added safe back navigation and unsaved-change confirmation.

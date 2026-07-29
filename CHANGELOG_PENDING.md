# MoveMate 0.99.17

- Added Firebase initialization during app startup.
- Added local-first Firestore synchronization for all Drift app records.
- Added timestamp-based conflict resolution between local and cloud data.
- Added user-scoped Firestore rules for `users/{uid}/appStorage`.
- Added anonymous authentication fallback when no signed-in Firebase user exists.

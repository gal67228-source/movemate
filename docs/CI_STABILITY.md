# CI stability — v0.99.6

MoveMate pins a known-compatible FlutterFire set from FlutterFire BoM 3.9.0:

- `firebase_core 3.13.0`
- `firebase_auth 5.5.2`
- `cloud_firestore 5.6.6`

That set uses Firebase Android SDK 33.11.0 and avoids the Kotlin 2.3 metadata incompatibility seen with the newer native Auth artifact.

GitHub Actions also disables Gradle file-system watching and background daemons, uses the in-process Kotlin compiler, and limits workers to reduce duplicate watcher and daemon failures.

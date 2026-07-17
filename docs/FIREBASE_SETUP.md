# Firebase setup for MoveMate v0.98

MoveMate compiles and works in local mode even when Firebase is not configured.
Google sign-in becomes active after the Android Firebase configuration is added.

## Firebase Console

1. Create a Firebase project.
2. Add an Android app with package name `com.movemate.movemate`.
3. Add the SHA-1 and SHA-256 fingerprints for the signing key used by the app.
4. Enable **Authentication → Sign-in method → Google**.
5. Download `google-services.json`.

## GitHub Actions secret

The workflow can configure Firebase without committing `google-services.json`.

1. Encode the file as Base64 on your computer.
2. Create a GitHub Actions repository secret named:
   `GOOGLE_SERVICES_JSON_BASE64`
3. Paste the Base64 value into the secret.

During CI, the workflow restores the file and enables the Google Services Gradle plugin.
If the secret is missing, CI still builds the APK and MoveMate displays the local-mode option.

## Data behavior in v0.98

- Drift remains the source of truth.
- Google sign-in stores the Firebase UID on the active move as `ownerUid`.
- Existing moves without an owner are assigned to the first Google account that signs in.
- A move already assigned to a different UID is not silently reassigned.
- Cloud data synchronization is not included yet; it is planned for v0.99.

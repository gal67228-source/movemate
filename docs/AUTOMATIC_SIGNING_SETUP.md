# Automatic Android signing bootstrap

MoveMate includes a manually-triggered GitHub Actions workflow named **Bootstrap Android Signing**.

It generates once:

- `movemate-release.jks`
- a strong random keystore password
- a strong random key password
- SHA-1 and SHA-256 certificate fingerprints
- ready-to-copy GitHub Actions secret values

The artifact is retained for one day only.

## Required one-time steps

1. Open **Actions** in GitHub.
2. Select **Bootstrap Android Signing**.
3. Select **Run workflow**.
4. Download the `movemate-signing-bootstrap` artifact.
5. Open `signing-secrets.txt` and add these repository secrets:
   - `ANDROID_KEYSTORE_BASE64`
   - `ANDROID_KEYSTORE_PASSWORD`
   - `ANDROID_KEY_ALIAS`
   - `ANDROID_KEY_PASSWORD`
6. Add the generated `SHA1` and `SHA256` fingerprints to the Android app in Firebase.
7. Download a fresh `google-services.json`, encode it as Base64, and save it as `GOOGLE_SERVICES_JSON_BASE64`.
8. Store `movemate-release.jks` and `signing-secrets.txt` in a safe offline location.
9. Delete the workflow artifact after setup.

GitHub Actions cannot safely create its own repository secrets with the default workflow token. This is why copying the generated values into repository secrets is the only required manual security step.

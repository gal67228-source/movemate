# Changelog

## 0.98.5+38

- Removed the development-only demo dashboard action from the welcome screen.
- Opened new-move creation with normal stack navigation.
- Added an explicit back button to the new-move screen.
- Added Android back-button handling with confirmation when the form contains unsaved changes.
- Dismissed the keyboard when tapping outside fields or opening the date picker.

## 0.98.4+37

- Simplified the Google sign-in screen to the two primary actions.
- Removed setup and Firebase explanatory cards from the initial screen.
- Kept the new-move form focused and removed preview content.
- Made the move name optional with a default of `מעבר דירה`.
- Added a short success confirmation after creating a move.

## 0.98.3+36

- Fixed PKCS12 signing by using the keystore password for the private key.
- Added a keytool validation step before the Android release build.
- Updated the signing bootstrap to generate one consistent password.

## 0.98.2+35

- Added the Firebase Android configuration file to the repository package.
- CI now copies `firebase/google-services.json` into the generated Android project.
- Removed the requirement for the `GOOGLE_SERVICES_JSON_BASE64` GitHub secret.

# Changelog

## 0.98.0+33

- Added Firebase Authentication and Google sign-in foundation.
- Added a sign-in screen with a safe local-mode fallback.
- Added account details and sign-out to Settings.
- Added `ownerUid`, `plan`, `createdAt`, and `updatedAt` to move data.
- Added backward-compatible migration defaults for existing moves.
- Added optional GitHub Actions Firebase configuration through a repository secret.
- Added identity model tests and updated widget tests with a fake auth service.

## 0.97.6+32

- Completed Drift cleanup and migration tests.

## 0.98.1+34

- Added one-time automatic Android signing bootstrap workflow.
- Generates permanent JKS, random credentials, SHA-1 and SHA-256 automatically.
- Added CI support for permanent release signing from GitHub Secrets.
- Added signing setup documentation.

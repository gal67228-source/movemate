# Firestore setup for MoveMate

1. Open Firebase Console and select the MoveMate project.
2. Open **Firestore Database** and create a database in production mode.
3. Open the **Rules** tab.
4. Replace the rules with the contents of `firestore.rules` from this repository.
5. Publish the rules.

The app stores data under:

- `users/{uid}` — the signed-in user's profile.
- `moves/{moveId}` — move ownership metadata.
- `moves/{moveId}/state/{storageKey}` — synchronized MoveMate data.
- `moves/{moveId}/members/{uid}` — shared users.
- `invites/{code}` — seven-day invitation codes.

Drift remains the device source of truth. Firestore synchronizes serialized
feature state and uses last-write-wins timestamps when two devices edit the
same storage key.

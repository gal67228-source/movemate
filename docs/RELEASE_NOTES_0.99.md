# MoveMate 0.99 — Cloud Sync and Sharing

MoveMate now keeps Drift as the local source of truth and synchronizes the
serialized application state with Cloud Firestore for signed-in users.

Owners can generate an eight-character invitation code valid for seven days.
Another signed-in user can enter the code to download and collaborate on the
same move. Firestore security rules restrict move data to the owner and member
documents created from valid invitations.

Before using this release, create a Firestore database and publish the included
`firestore.rules` file.

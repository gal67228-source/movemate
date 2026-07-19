# QR codes and photos

MoveMate assigns a stable QR payload to every box using its internal ID. Scanning the code opens the matching box in the current move.

Photos can be selected from the camera or gallery. When a Google user is signed in and Firebase Storage is available, photos are uploaded under:

```text
moves/<moveId>/boxes/<boxId>/...
moves/<moveId>/items/<itemId>/...
```

When Storage is unavailable or the app is in local mode, the local file path is retained so the photo remains usable on the current device.

## Firebase setup

1. Enable Cloud Storage in the Firebase project.
2. Publish `storage.rules` from this repository.
3. Keep Firestore rules published as well because Storage authorization checks the move owner/member documents.

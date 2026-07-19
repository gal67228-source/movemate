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

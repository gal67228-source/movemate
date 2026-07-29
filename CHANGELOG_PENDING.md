# MoveMate 0.99.16

- Replaced `file_picker` with Flutter's maintained `file_selector` plugin.
- Updated JSON backup import to use `openFile` and `XTypeGroup`.
- Updated CI to verify that `file_selector` is resolved and `file_picker` is absent.
- Kept Android API 36, Firebase setup, signing, analysis, tests, and release APK build.

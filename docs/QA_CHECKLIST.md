# MoveMate 0.95 QA checklist

Run this checklist on a real Android phone before promoting version 1.0.

## Installation and startup

- Install the release APK over the previous version without clearing app data.
- Confirm the existing move, tasks, rooms, boxes, sales, shopping, and budget remain available.
- Close and reopen the app and confirm it returns to the dashboard.
- Check light mode and dark mode.

## Core flows

- Create, edit, complete, and delete a task.
- Open every room and edit a room inventory item.
- Link an inventory item to a box and confirm both screens stay synchronized.
- Create and edit a box, then change its moving status.
- Mark an inventory item for sale and confirm the sale listing is created.
- Mark a sale as sold and enter the actual sale price.
- Add a shopping item and an expense and verify dashboard totals.
- Search for an inventory item, box content, task, sale, and shopping item.
- Update the Moving Day checklist and box statuses.

## Usability

- Verify that buttons and checkboxes are easy to tap.
- Verify dialogs do not overflow when the keyboard is open.
- Verify long Hebrew names wrap without clipping.
- Verify empty lists show a useful action or explanation.
- Verify destructive actions ask for confirmation.

## Release gate

- `dart format lib test`
- `flutter analyze --fatal-infos`
- `flutter test --reporter=expanded`
- `flutter build apk --release`
- `flutter build appbundle --release`

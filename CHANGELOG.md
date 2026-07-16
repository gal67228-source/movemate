## 0.95.2+24

- Replaced the unavailable Cupertino page transition builder with a Material transition builder compatible with the Flutter version used by CI.
- Preserved the restored GitHub Actions workflow.

# 0.95.1+23

- Restored the GitHub Actions workflow and hidden GitHub configuration files in the release archive.
- No application data or feature behavior changed.

# MoveMate Changelog

## 0.95.0+22

- Unified Material 3 styling across the application.
- Improved accessibility with consistent 48dp interactive controls.
- Polished cards, dialogs, forms, chips, progress indicators, and navigation transitions.
- Added theme regression tests and a full manual QA checklist.
- CI now builds and uploads both APK and AAB artifacts.
- Kept all existing local data formats unchanged for safe upgrades.

## 0.9.0+21

- Added a dedicated Moving Day dashboard.
- Added explicit box status controls for loaded, arrived, and unpacked states.
- Added urgent task completion from the Moving Day screen.
- Added a persistent moving-day checklist with custom items.
- Added live warnings and summary metrics on the main dashboard.

## 0.7.2+15

- Expanded the default inventory catalog for every supported room.
- Added quantity to room inventory and sale items.
- Automatically creates or updates a sale listing when an inventory item is marked for sale.
- Added asking price directly to the room-item editor.
- Keeps linked sale entries synchronized with inventory quantity and name.

## 0.7.1+14

- Fixed nullable room handling in the Smart Rooms inventory screen.
- Restored strict analyzer compatibility.

## 0.6.0+12

- Added shopping list with quantities, statuses and whole-shekel prices.
- Added moving budget and expense management.
- Connected sales income, shopping and budget summaries to the dashboard.
- Added shopping and budget calculation tests.

## 0.5.2+11

- Store sale prices as whole shekels instead of agorot.
- Migrate existing agorot-based sale data to shekels.
- Remove the new-task floating button from the Dashboard.
- Keep task creation available only from the Tasks screen.

# Changelog

## 0.5.1+10

- Fixed the Dashboard import for the shared `formatShekels` currency formatter.
- Restored successful static analysis for the Sale Manager dashboard statistics.

## 0.5.0+9

- Added a complete Sale Manager with create, edit and delete flows.
- Added sale categories, statuses, asking prices and actual sold prices.
- Added search, status filters and a quick mark-as-sold action.
- Added expected and actual revenue summaries to Sales and Dashboard.
- Added schema-aware JSON loading and compatibility with legacy sale fields.
- Added sale statistics, migration and search tests.

## 0.4.0+8

- Added full create and edit flow for moving boxes.
- Added content, room and box-number search.
- Added box name, weight, notes and lifecycle status.
- Added edit, delete and quick status progression actions.
- Added packing dashboard box statistics.
- Preserved compatibility with boxes saved by version 0.3.
- Added moving-box model and search tests.

## 0.7.3+16
- Restored `.github/workflows/flutter-ci.yml` after it was accidentally omitted from the v0.7.2 ZIP.
- Restored `.github/dependabot.yml`, `.github/copilot-instructions.md`, and `.gitignore`.

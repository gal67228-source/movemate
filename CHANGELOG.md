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

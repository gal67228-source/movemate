# Changelog

## 0.8.0+19

- Added one global search across room inventory, boxes, sales, tasks and shopping.
- Added search filters by result type.
- Added direct navigation from each result to the relevant screen.
- Added room, status, box, price and quantity context to search results.

## 0.7.5+18

- Added a sold checkbox to every sale item.
- Marking an item as sold now asks for the actual sale price.
- Cancelling the dialog leaves the item unchanged.
- Unchecking a sold item restores it to published status.

# Changelog

## 0.7.4+17
- Fixed `use_build_context_synchronously` in the room inventory editor by checking `context.mounted` after awaiting the sales repository.


## 0.7.0+13
- Added smart room inventory with built-in equipment catalogs.
- Added quick item removal and custom room items.
- Added item editor with explicit status selection.
- Synchronized room inventory with moving box contents and box status.
- Removed the separate packing-items shortcut from the dashboard.

## 0.7.3+16
- Restored GitHub Actions and repository configuration files omitted from the previous archive.

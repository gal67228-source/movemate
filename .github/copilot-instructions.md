# MoveMate — GitHub Copilot Instructions

## Product context
MoveMate is a Hebrew-first Flutter application for managing a home move. The first release focuses on tasks, rooms, packing boxes and their contents, items for sale, shopping, budget, documents, and a central progress dashboard.

## Language and UX
- The application is Hebrew-first and must fully support RTL.
- All user-facing strings should be written in clear, natural Hebrew unless a product or technical term is intentionally kept in English.
- Do not hard-code layout direction. Use Flutter localization and direction-aware APIs such as `EdgeInsetsDirectional`, `AlignmentDirectional`, `BorderRadiusDirectional`, `start`, and `end`.
- Keep screens simple, accessible, and usable with one hand.
- Use Material Design 3 components and support both light and dark themes.
- Avoid dense screens. Prefer cards, clear hierarchy, large touch targets, and concise labels.
- Add semantic labels and tooltips where icons alone may be unclear.

## Flutter and Dart standards
- Use the stable Flutter channel and current non-deprecated APIs.
- Keep the project compatible with Android first, without blocking future iOS support.
- Follow `flutter_lints` and keep `flutter analyze` clean.
- Format all Dart files with `dart format`.
- Prefer immutable models and widgets whenever practical.
- Use `const` constructors wherever possible.
- Avoid `dynamic` unless interoperability requires it.
- Handle nullable values explicitly and safely.
- Never swallow exceptions silently. Convert technical failures into meaningful domain failures and user-friendly messages.

## Architecture
- Organize code by feature under `lib/features/`.
- Shared cross-feature code belongs under `lib/core/` or `lib/shared/`.
- Keep business logic out of widgets.
- Widgets should render state and forward user actions to controllers/providers.
- Use Riverpod for state management and dependency injection.
- Use repositories as the boundary between application logic and data sources.
- Do not access Drift, SQLite, files, or network services directly from UI widgets.
- Keep domain models independent from database table classes when doing so improves clarity and testability.
- Prefer small, focused classes and files over large multipurpose files.

Suggested feature structure:

```text
lib/features/<feature>/
  data/
    datasources/
    repositories/
  domain/
    models/
    repositories/
  presentation/
    controllers/
    screens/
    widgets/
```

Do not create empty layers merely to satisfy this structure. Add them when the feature needs them.

## State management with Riverpod
- Use Riverpod providers for repositories, services, controllers, and observable state.
- Prefer `Notifier`, `AsyncNotifier`, and their generated equivalents for non-trivial feature state.
- Represent loading, success, empty, and error states explicitly.
- Keep side effects in controllers/services, not inside widget `build` methods.
- Avoid global mutable state and singleton service locators outside Riverpod.

## Local persistence with Drift
- Drift/SQLite is the source of truth for version 1 offline data.
- Every move-owned record must include a stable identifier and the relevant `moveId` relationship.
- Define foreign keys and deletion behavior deliberately.
- Use migrations for every schema change after the database is introduced.
- Never destroy user data as a shortcut for a schema update.
- Repositories should expose domain-friendly methods and streams rather than raw SQL concerns.
- Add timestamps where useful for sorting, synchronization, or future cloud migration.

## Domain rules
- A user may eventually manage multiple moves, so avoid assuming one permanent global move.
- Tasks, rooms, boxes, sales, shopping items, expenses, and documents belong to a specific move.
- Box numbers must be unique within a move, but do not assume they are globally unique.
- A box contains zero or more box items and belongs to one room.
- Box status should be modeled as a typed enum, not arbitrary strings.
- Monetary values must not use floating-point arithmetic. Store amounts as integer minor units, such as agorot, and format them for display as ILS.
- Dates should be stored as real date/time values and formatted only at the presentation layer.
- Progress calculations must be deterministic, testable, and centralized rather than duplicated across screens.

## Navigation
- Use `go_router` for navigation.
- Keep route names and paths centralized.
- Pass identifiers through routes rather than complete mutable objects where practical.
- Deep links and back navigation should remain predictable.

## Testing
- Every new business rule requires a unit test.
- Every repository should have tests using an in-memory or test database when practical.
- Important screens and user flows should have widget tests.
- Add regression tests when fixing bugs.
- Tests must not depend on network access, real user files, or execution order.
- Keep the existing CI green: formatting, static analysis, tests, and Android build must pass.

## CI and dependencies
- Do not weaken or bypass CI checks to make a change pass.
- Do not commit generated build artifacts, secrets, keystores, APKs, or local environment files.
- Pin GitHub Actions to supported major versions and keep workflows minimal.
- Add a dependency only when it has a clear benefit, active maintenance, and compatible licensing.
- Prefer official Flutter/Dart packages or widely adopted, actively maintained packages.
- Run `flutter pub get`, `dart format`, `flutter analyze`, and `flutter test` after dependency or code changes.

## Security and privacy
- Never commit API keys, signing keys, tokens, passwords, private addresses, or personal documents.
- Treat saved addresses, documents, photos, contacts, and sale information as private user data.
- Request Android permissions only when a feature actually requires them and explain the purpose in the UI.
- Validate file paths, imported data, and user input.
- Prepare data access boundaries so cloud sync can be added later without exposing local data unintentionally.

## Code generation requests
When generating or modifying code:
1. Inspect the surrounding feature and follow its existing conventions.
2. Make the smallest coherent change that fully solves the task.
3. Update models, repositories, providers, UI, tests, and migrations together when the change crosses layers.
4. Preserve Hebrew RTL behavior and dark mode.
5. Avoid placeholders, fake production data, and unfinished TODOs unless the task explicitly requests scaffolding.
6. Explain any required code-generation command, migration, Android permission, or CI change in the pull request summary.

## Definition of done
A change is complete only when:
- The requested behavior works end to end.
- User-facing text is polished Hebrew and RTL-safe.
- Loading, empty, success, and failure states are handled.
- Relevant tests were added or updated.
- `dart format --output=none --set-exit-if-changed .` passes.
- `flutter analyze` passes without warnings or errors.
- `flutter test` passes.
- The Android CI build remains successful.

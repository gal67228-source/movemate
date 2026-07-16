# Drift cleanup (v0.97.6)

MoveMate now persists all moving data exclusively in Drift/SQLite.

SharedPreferences remains in use only for:

1. lightweight application settings such as theme mode;
2. the one-time import of legacy data created before v0.97.

The migration marker is written only after all legacy string values have been
copied successfully. Existing Drift values are never overwritten by legacy
values. Legacy preference values remain available as a recovery copy for now.

Tests use `AppDatabase.inMemory()` and therefore exercise the same Drift-backed
storage path as production without writing files to the test machine.

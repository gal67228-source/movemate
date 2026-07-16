# Drift migration — v0.97.0

MoveMate now persists application data in a Drift database backed by SQLite.

## Compatibility approach

The existing feature repositories continue to use the `LocalStorage` facade.
At startup, that facade loads the Drift key-value table into memory, preserving
its synchronous read API while all writes are committed to SQLite.

## One-time migration

On the first launch of v0.97.0:

1. Drift opens `movemate.sqlite` in the application documents directory.
2. Existing string and JSON values are copied from SharedPreferences.
3. The migration is marked complete only after every value is written.
4. Legacy SharedPreferences values remain untouched as a recovery copy.

A later release may remove the recovery copy after field testing confirms that
all existing installations migrated successfully.

## Next steps

The next database iteration can replace the compatibility key-value table with
normalized Drift tables and typed DAOs feature by feature, without another risky
all-at-once UI rewrite.

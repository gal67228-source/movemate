#!/usr/bin/env bash
set -euo pipefail

flutter create . \
  --platforms=android \
  --org com.movemate \
  --project-name movemate
flutter pub get

echo "MoveMate is ready. Run: flutter run"

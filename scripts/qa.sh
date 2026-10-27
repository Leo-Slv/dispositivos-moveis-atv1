#!/bin/sh
# Verificações de qualidade: formatação, análise estática e testes.
set -e
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test

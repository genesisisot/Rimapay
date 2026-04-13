# AGENTS.md - RimaPay

Flutter mobile wallet app with Riverpod, go_router, clean architecture.

## Run Commands

```bash
# Dev (default)
flutter run

# Staging
flutter run -t lib/mainStaging.dart --flavor staging --debug

# Production
flutter run -t lib/mainProd.dart --flavor production --debug

# Specific device
flutter run -d chrome
flutter devices
```

## Build Commands

```bash
# Debug APK
flutter build apk --debug

# Release APK with flavor (used in CI)
flutter build apk --release --flavor production -t lib/mainProd.dart --no-tree-shake-icons

# Release APK for staging
flutter build apk --release --flavor staging -t lib/mainStaging.dart

# Web release
flutter build web --release
```

## CI/CD

- **Workflow**: `.github/workflows/build.yml`
- **Flutter version**: 3.41.2
- **Java version**: 17
- **Build output**: `build/app/outputs/flutter-apk/app-production-release.apk`
- **Triggers**: push to main, manual dispatch

## Test & Lint

```bash
flutter test
flutter test test/widget_test.dart -n "specific test name"
flutter analyze
flutter analyze --fix
```

## Code Generation

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## Project Structure

```
lib/
├── core/           # theme, providers, services, router
├── features/       # auth/, home/, bills/, wallet/
├── shared/         # reusable widgets
├── Services/       # legacy (migrating to features/)
├── Models/         # data models
├── Utils/          # helpers
└── main*.dart      # entry points: main.dart, mainStaging.dart, mainProd.dart
```

## Entry Points

- `lib/main.dart` - dev (default)
- `lib/mainStaging.dart` - staging environment
- `lib/mainProd.dart` - production environment

Uses `AppInitializer` from `lib/Utils/MyFlavorsConfig.dart` for staging/prod setup.

## Key Dependencies

- State: `flutter_riverpod ^2.4.9`, `provider ^6.1.1`
- Router: `go_router ^16.2.1`
- HTTP: `dio ^5.3.3`, `retrofit ^4.0.3`
- Storage: `hive`, `hive_flutter`, `shared_preferences`
- Lint: `flutter_lints ^6.0.0`

## Naming Conventions

- Files: `snake_case.dart`
- Classes: `PascalCase`
- Private: `_leadingUnderscore`

## Import Order

1. Dart core
2. Flutter
3. Third-party
4. Project (relative paths)

## Theme

- Colors: `core/theme/app_colors.dart`
- Text: `core/theme/app_text_styles.dart`
- Spacing: `core/theme/app_spacing.dart`

## Navigation

Use GoRouter: `context.push('/home')` or `context.push('/user/${user.id}')`
# AGENTS.md - RimaPay

Flutter mobile wallet app (Riverpod, go_router, clean architecture).

## Run Commands

```bash
# Dev (default)
flutter run

# Staging / Production (requires flavor)
flutter run -t lib/mainStaging.dart --flavor staging --debug
flutter run -t lib/mainProd.dart --flavor production --debug

# List available devices
flutter devices
```

## Build Commands

```bash
# Debug APK
flutter build apk --debug

# Release APK (flavor required for staging/prod)
flutter build apk --release --flavor production -t lib/mainProd.dart --no-tree-shake-icons
flutter build apk --release --flavor staging -t lib/mainStaging.dart

# Web release
flutter build web --release
```

**Important**: `--no-tree-shake-icons` is required for release builds (preserves icon font).

## Test & Lint

```bash
flutter test
flutter test test/widget_test.dart -n "test_name"
flutter analyze
flutter analyze --fix
```

## Code Generation

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## CI/CD

- Workflow: `.github/workflows/build.yml`
- Flutter: 3.41.2, Java: 17
- Trigger: push to main, manual dispatch

## Project Structure

```
lib/
├── core/           # theme, providers, services, router
├── features/       # auth/, home/, bills/, wallet/, etc.
├── shared/         # reusable widgets
├── Services/       # legacy (migrating to features/)
├── Models/         # data models
└── main*.dart      # entry points
```

## Entry Points

- `main.dart` - dev (default)
- `mainStaging.dart` - staging
- `mainProd.dart` - production

Uses `AppInitializer` from `lib/Utils/MyFlavorsConfig.dart`.

## Key Dependencies

- State: `flutter_riverpod ^2.4.9`, `provider ^6.1.1`
- Router: `go_router ^16.2.1`
- HTTP: `dio ^5.3.3`, `retrofit ^4.0.3`
- Storage: `hive`, `hive_flutter`, `shared_preferences`

## Conventions

- Files: `snake_case.dart`, Classes: `PascalCase`
- Private: `_leadingUnderscore`
- Import order: Dart core → Flutter → third-party → project (relative)

## Theme Files

- Colors: `core/theme/app_colors.dart`
- Text: `core/theme/app_text_styles.dart`
- Spacing: `core/theme/app_spacing.dart`

## Navigation

GoRouter: `context.push('/home')` or `context.push('/user/${user.id}')`
# MindIsle Monorepo

This repository is organized as a Flutter monorepo with Melos.

## Structure

- `apps/patient`: Patient-side Flutter application.
- `apps/doctor`: Doctor-side Flutter application.
- `packages/app_core`: Shared infrastructure (`Result`, `AppError`, network stack, session abstractions, `ApiCallExecutor`).
- `packages/app_ui`: Shared Material 3 theme and reusable UI widgets.
- `packages/models`: Shared domain models and data mappers (auth/common/medication).

## Workspace setup

```bash
dart pub get
dart run melos bootstrap
```

## Analyze and test

```bash
dart run melos run analyze
dart run melos run test
```

## Run apps

Run patient app (debug):

```bash
dart run melos run run:patient
```

JetBrains IDE shared run configurations are provided in `.run/`:
- `Patient (Flutter Debug, Hot Reload)`
- `Doctor (Flutter Debug, Hot Reload)`
Use these for IDE hot reload/hot restart instead of terminal-based Melos run scripts.

Run doctor app (debug):

```bash
dart run melos run run:doctor
```

Run patient app (release mode):

```bash
dart run melos run run:patient:release
```

Run doctor app (release mode):

```bash
dart run melos run run:doctor:release
```

Build patient release APK:

```bash
dart run melos run build:patient:release
```

Build doctor release APK:

```bash
dart run melos run build:doctor:release
```


# NextRep 🏋️

A simple workout tracker built with **Flutter**: create a program with a few routines, follow them set by set in the gym and see your progress over time. Everything is stored on the device.

## How it works

1. **Schede**: create a program and a number of routines (A, B, C...). Open a routine to add exercises with sets, reps, optional weight and rest time. Exercises can be reordered (drag) and removed (swipe).
2. **Allenati**: the app proposes the next routine in rotation (the one after the last you completed). Tap the big button to start. For each set you tap the reps done, confirm the weight, and rest. After the last set of an exercise you get a recap vs the routine target.
3. **Dashboard / Analisi**: number of workouts, volume per session, sets per muscle group in the last 30 days and the full history.

Login and registration are local only (no server): they just remember that you went through the welcome screen.

## Tech stack

- **Flutter / Dart**, **Provider** for state
- **Hive** for programs and the exercise catalogue, **Isar** for workout sessions (code generation via `build_runner`)
- **fl_chart**, **wakelock_plus** (screen stays on during a workout)

## Project structure

```
lib/
  core/        theme, colors, strings, target parsing helpers
  models/      exercise, routine, program (Hive) and workout session (Isar)
  providers/   auth, programs, live workout session + history
  screens/     dashboard, programs, workout, analysis, auth
  services/    local database
```

## Run locally

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Tests: `flutter test`.

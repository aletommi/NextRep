# NextRep 🏋️

A cross-platform workout tracker built with **Flutter**: create training programs, follow them set by set in the gym and track your progress over time.

## Features

- **Training programs**: step-by-step wizard to create programs and routines, with an exercise picker and a routine editor.
- **Live workout mode**: focused, one-exercise-at-a-time view with a custom numeric keypad to log weight and reps quickly.
- **Rest timer**: built-in timer between sets; the screen stays awake during the workout.
- **Workout recap**: summary of the session when you finish.
- **Dashboard & analysis**: stats cards, progress charts and a per-muscle-group overview.
- **Offline first**: all data is stored locally on the device, no account or server needed.
- Dark theme designed for use in the gym.

## Tech stack

- **Flutter / Dart**: one codebase for Android, iOS, web and desktop
- **Provider**: state management
- **Hive** and **Isar**: local NoSQL databases (with code generation via `build_runner`)
- **fl_chart**: charts
- **wakelock_plus**, **google_fonts**

## Project structure

```
lib/
  core/        theme, colors and strings
  models/      data models (exercise, workout, set, routine, program, session)
  providers/   app state (auth, programs, workouts, live session)
  screens/     dashboard, programs, workout, analysis, auth
  services/    local database
```

## Run locally

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Status

Work in progress. Login and registration are local only, and some analysis widgets still use sample data.

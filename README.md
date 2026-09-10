# Bu Dian Mobile

Flutter mobile application untuk deteksi alergen makanan.

## Tech Stack

- Flutter (latest stable)
- Dart
- Provider (state management)
- Lucide Icons

## Features

- **Bottom Navigation** — 4 tabs: Home, Detect, History, Profile
- **Detection** — Upload from camera/gallery → detect allergens
- **History** — Infinite scroll pagination
- **Password Toggle** — Eye icon on all password fields
- **Bottom Sheets** — Image picker, filter/sort
- **Manual Form Validation** — No third-party validation packages

## Setup

```bash
# Install dependencies
flutter pub get

# Run on emulator/device
flutter run

# Build APK
flutter build apk

# Build iOS
flutter build ios
```

## Project Structure

```
lib/
├── core/              # Constants, theme, utils, widgets
├── data/              # Datasources, models, repositories
├── domain/            # Entities, repository interfaces, use cases
├── presentation/      # Providers, pages, widgets
├── services/          # API, storage, image picker
└── config/            # Routes, dependency injection
```

## Architecture

Clean Architecture with 3 layers:
- **Domain** — Entities and use cases (business logic)
- **Data** — Models, datasources, repository implementations
- **Presentation** — Providers, pages, widgets (UI)

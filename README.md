# Bu Dian Mobile

Aplikasi mobile untuk deteksi alergen makanan menggunakan kamera. Dibangun dengan Flutter dan Clean Architecture.

## Tech Stack

- Flutter 3 (Dart)
- Provider (state management)
- Lucide Icons
- HTTP client untuk API calls
- Image Picker (kamera/galeri)

## Fitur

- **Bottom Navigation**: 4 tab - Home, Detect, History, Profile
- **Deteksi Alergen**: Upload dari kamera/galeri → deteksi alergen
- **Riwayat**: Infinite scroll pagination untuk history deteksi
- **Password Toggle**: Icon eye pada semua field password
- **Bottom Sheets**: Image picker, filter/sort
- **Validasi Manual**: Tanpa package validasi pihak ketiga
- **Onboarding**: Panduan penggunaan pertama kali

## Platform

| Platform | Status |
|----------|--------|
| Android | ✅ Supported |
| iOS | ✅ Supported |

## Setup

### Prasyarat

- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio / Xcode

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Jalankan aplikasi

```bash
# Jalankan di emulator/device
flutter run

# Jalankan di device spesifik
flutter run -d <device-id>
```

### 3. Build

```bash
# Build APK (Android)
flutter build apk

# Build iOS
flutter build ios
```

## Struktur Project

```
lib/
├── config/          # Routes, dependency injection
├── core/            # Constants, theme, utils, widgets
├── data/            # Datasources, models, repositories
├── domain/          # Entities, repository interfaces, use cases
├── presentation/
│   ├── pages/       # Halaman UI
│   │   ├── auth/        # Login, Register
│   │   ├── detection/   # Upload & hasil deteksi
│   │   ├── history/     # Riwayat deteksi
│   │   ├── home/        # Beranda
│   │   ├── main/        # Bottom navigation
│   │   ├── onboarding/  # Panduan pertama
│   │   ├── profile/     # Profil user
│   │   └── splash/      # Splash screen
│   ├── providers/   # State management
│   └── widgets/     # Komponen UI reusable
└── services/        # API, storage, image picker
```

## Arsitektur

Clean Architecture dengan 3 lapisan:

- **Domain** — Entities dan use cases (business logic)
- **Data** — Models, datasources, implementasi repository
- **Presentation** — Providers, pages, widgets (UI)

# Forum Alumni Mobile

Aplikasi Flutter komunitas Alumni dengan feed, posting, komentar realtime, notifikasi lokal, dan fitur lanjutan. Kini telah dioptimalkan untuk Production (Tahap 5).

## Arsitektur Singkat
- State management: `hooks_riverpod`
- Routing: `go_router` + `StatefulShellRoute`
- Networking: `dio` (+ Auth Interceptor, Retry, Sentry)
- Realtime: `supabase_flutter` (opsional via --dart-define)
- Storage: `hive`, `flutter_secure_storage`
- Notifikasi Lokal: `flutter_local_notifications`
- UI: Material 3, komponen modular (widgets & views)

Struktur utama:
- `lib/features/` fitur modular (auth, posts, search, profile, settings, notifications)
- `lib/services/` API client, Supabase, Notifikasi, dsb.
- `lib/router/app_router.dart` definisi rute
- `lib/core/constants/app_config.dart` konfigurasi runtime (env)

## Setup & Environment
Prasyarat:
- Flutter 3.22+ (Dart 3.9+)
- Android SDK (targetSdk 34), Xcode (untuk iOS)

Instal dependensi:
```
flutter pub get
```

Jalankan (tanpa Supabase Realtime):
```
flutter run
```

Aktifkan Supabase Realtime (opsional):
```
flutter run \
  --dart-define=SUPABASE_URL=YOUR_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_KEY
```

Konfigurasi Sentry (opsional):
```
--dart-define=SENTRY_DSN=YOUR_SENTRY_DSN
```

Konfigurasi API Base URL & Flavor:
```
--dart-define=APP_ENV=dev|staging|prod \
--dart-define=API_BASE_URL=https://api.example.com
```

Certificate Pinning (opsional):
- Set `AppConfig.pinnedSha256` (list fingerprint `sha256/<base64>`) di `lib/core/constants/app_config.dart`.
- Letakkan sertifikat di `assets/certs/` bila diperlukan (untuk dokumentasi/internal).

## Build & Deployment

Android release (contoh):
```
flutter build apk --release \
  --dart-define=APP_ENV=prod \
  --dart-define=API_BASE_URL=https://api.example.com \
  --dart-define=SENTRY_DSN=YOUR_SENTRY_DSN
```

Optimasi build Android:
- ProGuard/R8 diaktifkan (`android/app/build.gradle.kts`)
- File aturan: `android/app/proguard-rules.pro`

Signing:
- Tambahkan signingConfig release pada `build.gradle.kts` (keystore Anda)

## Troubleshooting
- AAR Metadata / Desugaring: telah diaktifkan `coreLibraryDesugaring` dan dependensi `desugar_jdk_libs`.
- Gagal install di device: coba hapus versi sebelumnya
  ```
  adb uninstall com.example.forumalumnimobile
  flutter run
  ```
- Crash/Errors: periksa Sentry dashboard jika DSN disetel.
- Realtime tidak jalan: pastikan `SUPABASE_URL` dan `SUPABASE_ANON_KEY` benar dan skema tabel sesuai.

## Testing
- Tambahkan unit test untuk repository dan controller (contoh: `test/`)
- Jalankan: `flutter test`

## Catatan Production
- Input sanitization & XSS prevention diterapkan pada render Markdown dan konten yang dikirim (lihat `features/shared/utils/sanitize.dart`).
- Retry & exponential backoff untuk network (`services/api/retry_interceptor.dart`).
- Global error boundary + Sentry init di `main.dart`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

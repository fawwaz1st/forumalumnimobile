class AppConstants {
  const AppConstants._();

  // App Information
  static const String appName = 'Forum Alumni';
  static const String appVersion = '1.0.0';

  // API Endpoints
  static const String baseUrl = 'http://10.126.9.142:8000/api/v1';

  // Storage Keys
  static const String tokenKey = 'token';
  static const String userKey = 'user';
  static const String themeKey = 'theme_mode';

  // Validation Rules
  static const int minPasswordLength = 8;
  static const int maxContentLength = 500;
  static const int maxUsernameLength = 30;

  // Media Types
  static const String mediaTypeImage = 'image';
  static const String mediaTypeVideo = 'video';

  // Post Categories
  static const List<String> postCategories = [
    'Umum',
    'Karir',
    'Event',
    'Alumni',
    'Diskusi',
  ];

  // Alumni Status Options
  static const List<String> alumniStatusOptions = [
    'Bekerja',
    'Belum Bekerja',
    'Wirausaha',
    'Melanjutkan Studi',
  ];

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardBorderRadius = 16.0;

  // Image Sizes
  static const double avatarSizeSmall = 32.0;
  static const double avatarSizeMedium = 48.0;
  static const double avatarSizeLarge = 64.0;
  static const double postImageHeight = 220.0;

  // Error Messages
  static const String networkError = 'Koneksi internet bermasalah';
  static const String serverError = 'Terjadi kesalahan pada server';
  static const String unknownError = 'Terjadi kesalahan yang tidak diketahui';

  // Success Messages
  static const String loginSuccess = 'Login berhasil';
  static const String registerSuccess = 'Registrasi berhasil';
  static const String postCreated = 'Postingan berhasil dibuat';
  static const String profileUpdated = 'Profil berhasil diperbarui';
}

class MediaTypes {
  const MediaTypes._();
  
  static const String image = 'image';
  static const String video = 'video';
}

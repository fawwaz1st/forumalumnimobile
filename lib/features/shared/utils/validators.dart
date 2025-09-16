class Validators {
  static String? requiredField(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName wajib diisi';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email wajib diisi';
    final regex = RegExp(r'^[\w.-]+@[\w-]+(\.[\w-]+)+$');
    if (!regex.hasMatch(value.trim())) return 'Email tidak valid';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password wajib diisi';
    // Minimal 8 karakter, 1 huruf, 1 angka
    final regex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d!@#\$%\^&\*\-_]{8,}$');
    if (!regex.hasMatch(value)) {
      return 'Min. 8 karakter, kombinasi huruf & angka';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Konfirmasi password wajib diisi';
    if (value != password) return 'Konfirmasi password tidak cocok';
    return null;
  }
}

class Validators {
  static String? requiredField(String? value, {String label = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label wajib diisi';
    }
    return null;
  }

  static String? email(String? value) {
    final required = requiredField(value, label: 'Email');
    if (required != null) return required;
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!regex.hasMatch(value!.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  static String? password(String? value) {
    final required = requiredField(value, label: 'Password');
    if (required != null) return required;
    if (value!.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }
}


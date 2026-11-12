/// Modul aturan validasi input profil mahasiswa TitipJalur.
/// Bertanggung jawab murni pada logika validasi input (Single Responsibility)
/// untuk menghindari duplikasi kode validasi regex di berbagai screen.
class ProfileValidator {
  ProfileValidator._();

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  static final RegExp _phoneRegExp = RegExp(
    r'^(\+62|62|0)8[1-9][0-9]{7,11}$',
  );

  static final RegExp _nimRegExp = RegExp(
    r'^[0-9]{8,15}$',
  );

  static final RegExp _nameRegExp = RegExp(
    r"^[a-zA-Z\s\.\']{3,50}$",
  );

  /// Validasi nama lengkap mahasiswa
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama lengkap wajib diisi';
    }
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return 'Nama lengkap minimal 3 karakter';
    }
    if (trimmed.length > 50) {
      return 'Nama lengkap maksimal 50 karakter';
    }
    if (!_nameRegExp.hasMatch(trimmed)) {
      return 'Nama hanya boleh memuat huruf, spasi, titik, dan petik';
    }
    return null;
  }

  /// Validasi email kampus
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email kampus wajib diisi';
    }
    final trimmed = value.trim();
    if (!_emailRegExp.hasMatch(trimmed)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  /// Validasi Nomor Induk Mahasiswa (NIM)
  static String? validateNim(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'NIM wajib diisi';
    }
    final trimmed = value.trim();
    if (!_nimRegExp.hasMatch(trimmed)) {
      return 'NIM harus berupa angka 8-15 digit';
    }
    return null;
  }

  /// Validasi nomor telepon / WhatsApp
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nomor telepon wajib diisi';
    }
    final trimmed = value.trim().replaceAll(RegExp(r'[\s\-]'), '');
    if (!_phoneRegExp.hasMatch(trimmed)) {
      return 'Nomor telepon harus format Indonesia valid (contoh: 081234567890)';
    }
    return null;
  }

  /// Memeriksa seluruh kumpulan field profil secara kolektif
  static Map<String, String> validateAll({
    required String? name,
    required String? email,
    required String? nim,
    required String? phone,
  }) {
    final errors = <String, String>{};

    final nameErr = validateName(name);
    if (nameErr != null) errors['name'] = nameErr;

    final emailErr = validateEmail(email);
    if (emailErr != null) errors['email'] = emailErr;

    final nimErr = validateNim(nim);
    if (nimErr != null) errors['nim'] = nimErr;

    final phoneErr = validatePhone(phone);
    if (phoneErr != null) errors['phone'] = phoneErr;

    return errors;
  }
}

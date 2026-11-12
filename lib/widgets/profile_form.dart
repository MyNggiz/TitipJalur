import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/profile_repository.dart';
import '../services/profile_validator.dart';
import 'app_text_field.dart';
import 'primary_button.dart';

/// Status siklus hidup formulir profil (Status UI).
enum ProfileFormStatus {
  idle,
  validating,
  submitting,
  success,
  failure,
}

/// Widget formulir profil mahasiswa TitipJalur.
/// Bertanggung jawab murni pada:
/// 1. Rendering kontrol input (Nama, NIM, Email, No. HP, Peran).
/// 2. Pengelolaan status visual UI (Idle, Loading, Success, Error).
/// 
/// Memisahkan tanggung jawab secara tegas:
/// - Aturan validasi didelegasikan ke [ProfileValidator].
/// - Komunikasi jaringan/API didelegasikan ke [ProfileRepository].
class ProfileForm extends ConsumerStatefulWidget {
  final UserModel? initialUser;
  final ValueChanged<UserModel>? onProfileSaved;
  final bool simulateApiError;

  const ProfileForm({
    super.key,
    this.initialUser,
    this.onProfileSaved,
    this.simulateApiError = false,
  });

  @override
  ConsumerState<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<ProfileForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _nimController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  String _selectedRole = 'Mahasiswa';
  ProfileFormStatus _status = ProfileFormStatus.idle;
  String? _errorMessage;
  String? _successMessage;

  // Error messages per field dari ProfileValidator
  String? _nameError;
  String? _nimError;
  String? _emailError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    final user = widget.initialUser ?? UserModel.guest();
    _nameController = TextEditingController(text: user.name);
    _nimController = TextEditingController(text: user.nim ?? '22051204001');
    _emailController = TextEditingController(text: user.email);
    _phoneController =
        TextEditingController(text: user.phoneNumber ?? '081234567890');
    _selectedRole = user.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nimController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Menjalankan validasi input menggunakan [ProfileValidator] (Avoid duplikasi kode)
  bool _validateInputs() {
    setState(() {
      _status = ProfileFormStatus.validating;
      _nameError = ProfileValidator.validateName(_nameController.text);
      _emailError = ProfileValidator.validateEmail(_emailController.text);
      _nimError = ProfileValidator.validateNim(_nimController.text);
      _phoneError = ProfileValidator.validatePhone(_phoneController.text);
    });

    final hasError = _nameError != null ||
        _emailError != null ||
        _nimError != null ||
        _phoneError != null;

    if (hasError) {
      setState(() {
        _status = ProfileFormStatus.failure;
        _errorMessage = 'Mohon periksa kembali kolom input bertanda merah.';
        _successMessage = null;
      });
      return false;
    }

    setState(() {
      _errorMessage = null;
    });
    return true;
  }

  /// Mengirim data pembaruan ke [ProfileRepository] (Request API)
  Future<void> _handleSubmit() async {
    if (!_validateInputs()) return;

    setState(() {
      _status = ProfileFormStatus.submitting;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final repository = ref.read(profileRepositoryProvider);
      final updatedUser = await repository.updateProfile(
        name: _nameController.text,
        email: _emailController.text,
        nim: _nimController.text,
        phoneNumber: _phoneController.text,
        role: _selectedRole,
        simulateError: widget.simulateApiError,
      );

      if (!mounted) return;

      setState(() {
        _status = ProfileFormStatus.success;
        _successMessage = 'Profil mahasiswa berhasil diperbarui ke server!';
        _errorMessage = null;
      });

      widget.onProfileSaved?.call(updatedUser);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = ProfileFormStatus.failure;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _successMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = _status == ProfileFormStatus.submitting;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Banner Status UI: Error Feedback
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Color(0xFFDC2626), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF991B1B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Banner Status UI: Success Feedback
          if (_successMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: Color(0xFF059669), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _successMessage!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF065F46),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Input: Nama Mahasiswa
          AppTextField(
            label: 'Nama Lengkap Mahasiswa *',
            hint: 'Contoh: Muhammad Naufal Fahrel',
            controller: _nameController,
            prefixIcon: Icons.badge_outlined,
            enabled: !isSubmitting,
            errorText: _nameError,
            textInputAction: TextInputAction.next,
            onChanged: (val) {
              if (_nameError != null) {
                setState(() => _nameError = ProfileValidator.validateName(val));
              }
            },
          ),
          const SizedBox(height: 14),

          // Input: NIM
          AppTextField(
            label: 'Nomor Induk Mahasiswa (NIM) *',
            hint: 'Contoh: 22051204001',
            controller: _nimController,
            prefixIcon: Icons.numbers_rounded,
            keyboardType: TextInputType.number,
            enabled: !isSubmitting,
            errorText: _nimError,
            textInputAction: TextInputAction.next,
            onChanged: (val) {
              if (_nimError != null) {
                setState(() => _nimError = ProfileValidator.validateNim(val));
              }
            },
          ),
          const SizedBox(height: 14),

          // Input: Email Kampus
          AppTextField(
            label: 'Email Kampus *',
            hint: 'Contoh: mhs@kampus.ac.id',
            controller: _emailController,
            prefixIcon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            enabled: !isSubmitting,
            errorText: _emailError,
            textInputAction: TextInputAction.next,
            onChanged: (val) {
              if (_emailError != null) {
                setState(
                    () => _emailError = ProfileValidator.validateEmail(val));
              }
            },
          ),
          const SizedBox(height: 14),

          // Input: Nomor Telepon / WhatsApp
          AppTextField(
            label: 'Nomor Telepon / WhatsApp *',
            hint: 'Contoh: 081234567890',
            controller: _phoneController,
            prefixIcon: Icons.phone_android_rounded,
            keyboardType: TextInputType.phone,
            enabled: !isSubmitting,
            errorText: _phoneError,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleSubmit(),
            onChanged: (val) {
              if (_phoneError != null) {
                setState(
                    () => _phoneError = ProfileValidator.validatePhone(val));
              }
            },
          ),
          const SizedBox(height: 16),

          // Pilihan Peran Aktif
          const Text(
            'Peran Utama Pengguna:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Mode Pemohon'),
                  selected: _selectedRole == 'Mahasiswa',
                  selectedColor: const Color(0xFF059669),
                  backgroundColor: const Color(0xFFF1F5F9),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _selectedRole == 'Mahasiswa'
                        ? Colors.white
                        : const Color(0xFF475569),
                  ),
                  onSelected: isSubmitting
                      ? null
                      : (selected) {
                          if (selected) {
                            setState(() => _selectedRole = 'Mahasiswa');
                          }
                        },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Mode Komuter'),
                  selected: _selectedRole == 'Runner',
                  selectedColor: const Color(0xFF059669),
                  backgroundColor: const Color(0xFFF1F5F9),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _selectedRole == 'Runner'
                        ? Colors.white
                        : const Color(0xFF475569),
                  ),
                  onSelected: isSubmitting
                      ? null
                      : (selected) {
                          if (selected) {
                            setState(() => _selectedRole = 'Runner');
                          }
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Tombol Submit / Loading Status UI (Anti-Double Tap)
          PrimaryButton(
            label: 'Simpan Pembaruan Profil',
            icon: Icons.save_rounded,
            isLoading: isSubmitting,
            onPressed: isSubmitting ? null : _handleSubmit,
          ),
        ],
      ),
    );
  }
}

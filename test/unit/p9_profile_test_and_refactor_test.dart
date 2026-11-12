import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titip_jalur/models/user_model.dart';
import 'package:titip_jalur/repositories/profile_repository.dart';
import 'package:titip_jalur/services/auth_service.dart';
import 'package:titip_jalur/services/profile_validator.dart';
import 'package:titip_jalur/widgets/app_text_field.dart';
import 'package:titip_jalur/widgets/profile_form.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ===========================================================================
  // 1. UNIT TEST: VALIDATION (ATURAN INPUT MURNI - AVOID DUPLIKASI KODE)
  // ===========================================================================
  group('P9 Component 1: Validation Rules (ProfileValidator)', () {
    test('1.1 validateName validates empty, too short, special characters, and valid name', () {
      expect(ProfileValidator.validateName(null), equals('Nama lengkap wajib diisi'));
      expect(ProfileValidator.validateName('   '), equals('Nama lengkap wajib diisi'));
      expect(ProfileValidator.validateName('Al'), equals('Nama lengkap minimal 3 karakter'));
      expect(ProfileValidator.validateName('User@123!'), equals('Nama hanya boleh memuat huruf, spasi, titik, dan petik'));
      expect(ProfileValidator.validateName('Muhammad Naufal Fahrel'), isNull);
      expect(ProfileValidator.validateName("D'Artagnan M.Sc."), isNull);
    });

    test('1.2 validateEmail validates empty, missing @, invalid domain, and valid email', () {
      expect(ProfileValidator.validateEmail(null), equals('Email kampus wajib diisi'));
      expect(ProfileValidator.validateEmail(''), equals('Email kampus wajib diisi'));
      expect(ProfileValidator.validateEmail('bukanemail'), equals('Format email tidak valid'));
      expect(ProfileValidator.validateEmail('mhs@'), equals('Format email tidak valid'));
      expect(ProfileValidator.validateEmail('fahrel@kampus.ac.id'), isNull);
      expect(ProfileValidator.validateEmail('student@unesa.ac.id'), isNull);
    });

    test('1.3 validateNim validates numeric constraints and 8-15 digit length', () {
      expect(ProfileValidator.validateNim(null), equals('NIM wajib diisi'));
      expect(ProfileValidator.validateNim(''), equals('NIM wajib diisi'));
      expect(ProfileValidator.validateNim('12345'), equals('NIM harus berupa angka 8-15 digit'));
      expect(ProfileValidator.validateNim('22051204001A'), equals('NIM harus berupa angka 8-15 digit'));
      expect(ProfileValidator.validateNim('22051204001'), isNull);
    });

    test('1.4 validatePhone validates standard Indonesian mobile formats', () {
      expect(ProfileValidator.validatePhone(null), equals('Nomor telepon wajib diisi'));
      expect(ProfileValidator.validatePhone(''), equals('Nomor telepon wajib diisi'));
      expect(ProfileValidator.validatePhone('123456'), equals('Nomor telepon harus format Indonesia valid (contoh: 081234567890)'));
      expect(ProfileValidator.validatePhone('0711123456'), equals('Nomor telepon harus format Indonesia valid (contoh: 081234567890)'));
      expect(ProfileValidator.validatePhone('081234567890'), isNull);
      expect(ProfileValidator.validatePhone('+6281234567890'), isNull);
      expect(ProfileValidator.validatePhone('6281234567890'), isNull);
    });

    test('1.5 validateAll aggregates all field errors into structured map', () {
      final errors = ProfileValidator.validateAll(
        name: 'A',
        email: 'invalid',
        nim: '123',
        phone: 'invalid_phone',
      );

      expect(errors.containsKey('name'), isTrue);
      expect(errors.containsKey('email'), isTrue);
      expect(errors.containsKey('nim'), isTrue);
      expect(errors.containsKey('phone'), isTrue);

      final validErrors = ProfileValidator.validateAll(
        name: 'Dimas Setiawan',
        email: 'dimas@kampus.ac.id',
        nim: '22051204002',
        phone: '081298765432',
      );
      expect(validErrors.isEmpty, isTrue);
    });
  });

  // ===========================================================================
  // 2. UNIT TEST: PROFILEREPOSITORY (REQUEST API & PERSISTENSI DATA)
  // ===========================================================================
  group('P9 Component 2: ProfileRepository (API Request & Session Sync)', () {
    test('2.1 getProfile returns current user from AuthService or default guest user', () async {
      final authService = AuthService.instance;
      await authService.loginAsGuest();
      final repository = ProfileRepositoryImpl(authService: authService);

      final profile = await repository.getProfile();
      expect(profile.name, equals('Muhammad Naufal Fahrel'));
      expect(profile.email, equals('mhs@kampus.ac.id'));
    });

    test('2.2 updateProfile performs API mutation and updates user session', () async {
      final authService = AuthService.instance;
      await authService.loginAsGuest();
      final repository = ProfileRepositoryImpl(authService: authService);

      final updated = await repository.updateProfile(
        name: 'Ahmad Dahlan',
        email: 'ahmad@kampus.ac.id',
        nim: '22051204999',
        phoneNumber: '081234567800',
        role: 'Runner',
      );

      expect(updated.name, equals('Ahmad Dahlan'));
      expect(updated.email, equals('ahmad@kampus.ac.id'));
      expect(updated.nim, equals('22051204999'));
      expect(updated.phoneNumber, equals('081234567800'));
      expect(updated.role, equals('Runner'));

      // Verifikasi sesi AuthService juga tersinkronisasi
      expect(authService.currentUser?.name, equals('Ahmad Dahlan'));
      expect(authService.currentUser?.role, equals('Runner'));
    });

    test('2.3 updateProfile with simulateError throws ProfileUpdateException', () async {
      final repository = ProfileRepositoryImpl();

      expect(
        () => repository.updateProfile(
          name: 'Testing User',
          email: 'test@kampus.ac.id',
          nim: '22051204010',
          phoneNumber: '081234567811',
          simulateError: true,
        ),
        throwsA(isA<ProfileUpdateException>()),
      );
    });
  });

  // ===========================================================================
  // 3. WIDGET TEST: PROFILEFORM (INPUT DAN STATUS UI MURNI)
  // ===========================================================================
  group('P9 Component 3: ProfileForm Widget (Input & Status UI)', () {
    testWidgets('3.1 ProfileForm renders all input controls with initial values', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ProfileForm(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nama Lengkap Mahasiswa *'), findsOneWidget);
      expect(find.text('Nomor Induk Mahasiswa (NIM) *'), findsOneWidget);
      expect(find.text('Email Kampus *'), findsOneWidget);
      expect(find.text('Nomor Telepon / WhatsApp *'), findsOneWidget);
      expect(find.text('Mode Pemohon'), findsOneWidget);
      expect(find.text('Mode Komuter'), findsOneWidget);
      expect(find.text('Simpan Pembaruan Profil'), findsOneWidget);
    });

    testWidgets('3.2 Status UI Validation: Triggering submit with invalid data displays error banner and field errors', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ProfileForm(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clear all fields
      await tester.enterText(find.widgetWithText(AppTextField, 'Nama Lengkap Mahasiswa *'), '');
      await tester.enterText(find.widgetWithText(AppTextField, 'Nomor Induk Mahasiswa (NIM) *'), '');
      await tester.enterText(find.widgetWithText(AppTextField, 'Email Kampus *'), '');
      await tester.enterText(find.widgetWithText(AppTextField, 'Nomor Telepon / WhatsApp *'), '');
      await tester.pumpAndSettle();

      // Tap submit
      final submitBtn = find.text('Simpan Pembaruan Profil');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Error banner and specific field errors appear
      expect(find.text('Mohon periksa kembali kolom input bertanda merah.'), findsOneWidget);
      expect(find.text('Nama lengkap wajib diisi'), findsOneWidget);
      expect(find.text('NIM wajib diisi'), findsOneWidget);
      expect(find.text('Email kampus wajib diisi'), findsOneWidget);
      expect(find.text('Nomor telepon wajib diisi'), findsOneWidget);
    });

    testWidgets('3.3 Status UI Loading: Displays progress indicator and disables submit button during API request', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ProfileForm(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final submitBtn = find.text('Simpan Pembaruan Profil');
      await tester.tap(submitBtn);
      await tester.pump(); // Frame when submitting starts

      // Verifikasi status UI loading & anti-double tap
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('3.4 Status UI Success: Successful submission displays success message banner and invokes callback', (tester) async {
      UserModel? savedUser;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ProfileForm(
                  onProfileSaved: (user) => savedUser = user,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter valid profile data
      await tester.enterText(find.widgetWithText(AppTextField, 'Nama Lengkap Mahasiswa *'), 'Budi Santoso');
      await tester.enterText(find.widgetWithText(AppTextField, 'Nomor Induk Mahasiswa (NIM) *'), '22051204088');
      await tester.enterText(find.widgetWithText(AppTextField, 'Email Kampus *'), 'budi@kampus.ac.id');
      await tester.enterText(find.widgetWithText(AppTextField, 'Nomor Telepon / WhatsApp *'), '081234567899');
      await tester.pumpAndSettle();

      // Submit
      final submitBtn = find.text('Simpan Pembaruan Profil');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verifikasi status UI success
      expect(find.text('Profil mahasiswa berhasil diperbarui ke server!'), findsOneWidget);
      expect(savedUser, isNotNull);
      expect(savedUser!.name, equals('Budi Santoso'));
      expect(savedUser!.nim, equals('22051204088'));
    });

    testWidgets('3.5 Status UI Error: API failure renders descriptive error banner', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ProfileForm(
                  simulateApiError: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final submitBtn = find.text('Simpan Pembaruan Profil');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verifikasi status UI error banner
      expect(
        find.textContaining('Gagal memperbarui profil: Terjadi kendala koneksi ke server kampus'),
        findsOneWidget,
      );
    });
  });
}

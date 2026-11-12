# Dokumentasi & Laporan Rekayasa Tugas Pertemuan 09 (P9)
**Test & Refactor: Avoid Duplikasi Code & Pemisahan Tanggung Jawab (Separation of Concerns)**

> **Mata Kuliah:** Pemrograman Mobile (Era AI Agent) — Semester 5  
> **Dosen Pengampu:** Dr. Haryono  
> **Aplikasi:** TitipJalur (*Peer-to-Peer Micro-Errand & Commuter Delivery Platform*)  
> **Mahasiswa:** Muhammad Naufal Fahrel (NIM: 22051204001)  
> **Status Verifikasi:** **100% LULUS (142/142 Tests Passed, `flutter analyze` 0 issues)**  

---

## 1. Ringkasan Eksekutif Tugas Pertemuan 09

Pada Pertemuan 09, fokus pengembangan TitipJalur memasuki tahap pengerasan arsitektur perangkat lunak (*Harden & Refactor*). Sesuai arahan spesifik dosen pengampu Dr. Haryono, tugas ini menitikberatkan pada dua prinsip rekayasa perangkat lunak utama:
1. **Avoid Duplikasi Code:** Menghilangkan duplikasi logika input dan regex yang sebelumnya tersebar di berbagai layar, serta memusatkannya pada modul aturan input tunggal (*Single Source of Truth*).
2. **Pemisahan Tanggung Jawab (*Separation of Concerns*):** Memecah modul menjadi fungsi-fungsi dan kelas yang lebih kecil dan fokus pada pekerjaannya masing-masing:
   - **`ProfileForm`:** Murni bertanggung jawab atas **input dan status visual UI** (Idle, Validating, Submitting, Success, Error).
   - **`validation` (`ProfileValidator`):** Murni bertanggung jawab atas **aturan input dan validasi format** tanpa ketergantungan pada UI atau jaringan.
   - **`profileRepository` (`ProfileRepository`):** Murni bertanggung jawab atas **request API dan sinkronisasi sesi pengguna** tanpa ketergantungan pada widget.

Seluruh proses refactoring ini dieksekusi dengan mematuhi metodologi 4 tahap:
$$\boxed{\text{1. Tes Awal Lulus}} \longrightarrow \boxed{\text{2. Pindahkan Satu Bagian}} \longrightarrow \boxed{\text{3. Tes Ulang}} \longrightarrow \boxed{\text{4. Commit}}$$

---

## 2. Implementasi 3 Komponen Pemisahan Tanggung Jawab

```
+---------------------------------------------------------------------------------------+
|                                  ARSITEKTUR HASIL REFACTOR P9                         |
+---------------------------------------------------------------------------------------+
|                                                                                       |
|   [ ProfileForm (UI Widget) ]                                                         |
|   • Mengelola controller input (Nama, NIM, Email, No. HP, Peran)                      |
|   • Mengelola status siklus hidup UI (Idle, Loading Spinner, Success, Error Banner)   |
|   • Anti-Double Tap: mendisable tombol saat proses submit                             |
|          |                                            |                               |
|          | (Mendelegasikan Aturan Input)              | (Mendelegasikan Request API)  |
|          v                                            v                               |
|   [ ProfileValidator (Validation Rules) ]      [ ProfileRepository (API Layer) ]      |
|   • validateName()                             • getProfile()                         |
|   • validateEmail() (Anti-duplikasi kode)      • updateProfile()                      |
|   • validateNim()                              • Error handling (Network Exception)   |
|   • validatePhone()                            • Sesi lokal sync (SharedPreferences)  |
|                                                                                       |
+---------------------------------------------------------------------------------------+
```

### 2.1 Komponen 1: `ProfileForm` (Input dan Status UI)
- **Berkas Implementasi:** [`lib/widgets/profile_form.dart`](../lib/widgets/profile_form.dart)
- **Tanggung Jawab:**
  - Menampilkan kontrol antarmuka formulir pengguna: Nama Mahasiswa, NIM, Email Kampus, Nomor Telepon/WhatsApp, dan Pilihan Peran Aktif (*Mode Pemohon vs Mode Komuter*).
  - Mengelola visualisasi status UI deklaratif:
    - *Status Idle:* Menampilkan nilai profil saat ini.
    - *Status Validating:* Menampilkan penanda batas error per-field jika input tidak valid.
    - *Status Submitting:* Mengaktifkan indikator `CircularProgressIndicator` putih berputar dan mendisable tombol (*anti-double tap*).
    - *Status Success:* Menampilkan banner hijau notifikasi keberhasilan dan memicu callback `onProfileSaved`.
    - *Status Failure:* Menampilkan banner merah komunikatif jika terjadi kegagalan jaringan atau server API.

### 2.2 Komponen 2: `validation` (`ProfileValidator` — Aturan Input Murni)
- **Berkas Implementasi:** [`lib/services/profile_validator.dart`](../lib/services/profile_validator.dart)
- **Tanggung Jawab:**
  - Berisi fungsi-fungsi statis murni (*pure functions*) untuk memvalidasi data masukan tanpa dependensi `BuildContext`, UI widget, ataupun HTTP network.
  - Memverifikasi batasan bisnis:
    - `validateName`: Nama minimal 3 karakter, maksimal 50 karakter, hanya memuat karakter alfabet, spasi, titik, dan petik.
    - `validateEmail`: Format email kampus terstandarisasi regex `^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$`.
    - `validateNim`: Nomor Induk Mahasiswa 8–15 digit numerik.
    - `validatePhone`: Nomor telepon seluler format Indonesia (`08...`, `+628...`, atau `628...`).
  - **Penghapusan Duplikasi Kode (Avoid Duplikasi Code):**  
    Logika regex email yang sebelumnya ditulis ulang secara terpisah di `LoginScreen` kini sepenuhnya menggunakan satu referensi terpusat:  
    `validator: ProfileValidator.validateEmail`.

### 2.3 Komponen 3: `profileRepository` (`ProfileRepository` — Request API Murni)
- **Berkas Implementasi:** [`lib/repositories/profile_repository.dart`](../lib/repositories/profile_repository.dart)
- **Tanggung Jawab:**
  - Mengabstraksi seluruh interaksi API backend kampus dan persistensi lokal:
    - `getProfile()`: Membaca entitas `UserModel` dari sesi aktif atau penyimpanan lokal.
    - `updateProfile(...)`: Mengeksekusi mutasi API (simulasi HTTP PUT/POST), menangani skenario galat jaringan melalui `ProfileUpdateException`, dan menyinkronkan profil terbaru ke `AuthService` serta `SharedPreferences`.
  - Terinjeksi secara compile-safe menggunakan Riverpod: `profileRepositoryProvider`.

---

## 3. Bukti Tangkapan Layar Tugas P9 (Katalog 4 Screenshots)

Seluruh tangkapan layar di bawah ini merekam hasil implementasi nyata pemisahan tanggung jawab, validasi input, dan hasil uji regresi di direktori `P9/screenshots/`:

| No | Fokus Pengujian P9 | Berkas Screenshot | Resolusi | Ukuran | Penjelasan Teknis & Bukti Reviewer |
|:--:|:---|:---|:---:|:---:|:---|
| **1** | **ProfileForm Input & Status UI** | [`screenshots/01_p9_profile_form_ui.png`](screenshots/01_p9_profile_form_ui.png) | 1080 × 2400 | 107.0 KB | **Input & Status UI Normal:** Menampilkan komponen `ProfileForm` dengan kontrol input (Nama, NIM, Email, No. HP, Peran Mahasiswa), avatar inisial, dan tombol submit berstandar sentuh 48dp. |
| **2** | **Aturan Input ProfileValidator** | [`screenshots/02_p9_validation_error_state.png`](screenshots/02_p9_validation_error_state.png) | 1080 × 2400 | 125.8 KB | **Status UI Validasi & Error Feedback:** Menampilkan reaksi formulir saat input tidak valid. Aturan input dari `ProfileValidator` memicu banner merah dan pesan kesalahan spesifik per-kolom tanpa crash. |
| **3** | **Pemisahan Tanggung Jawab & Anti-Duplikasi** | [`screenshots/03_p9_profile_repository_architecture.png`](screenshots/03_p9_profile_repository_architecture.png) | 1600 × 1050 | 107.7 KB | **Bukti Arsitektur & Anti-Duplikasi:** Tangkapan layar terminal pembuktian pemisahan tanggung jawab interface `ProfileRepository` (request API murni) dan pemanfaatan bersama `ProfileValidator.validateEmail` di `LoginScreen` dan `ProfileForm`. |
| **4** | **Hasil Pengujian Regresi (142 Tests Passed)** | [`screenshots/04_p9_test_regression_passed.png`](screenshots/04_p9_test_regression_passed.png) | 1600 × 1050 | 147.5 KB | **Bukti Test Runner Bebas Regresi:** Tangkapan layar terminal eksekusi suite pengujian `p9_profile_test_and_refactor_test.dart` (13 tests passed) dan seluruh rangkaian proyek (142/142 tests passed, `flutter analyze` 0 issues). |

---

## 4. Pratinjau Tangkapan Layar Tugas P9

### Bukti 1: Komponen ProfileForm (Input & Status UI Murni)
![01 ProfileForm UI](screenshots/01_p9_profile_form_ui.png)

### Bukti 2: Validasi Aturan Input & Penanganan Error Status UI
![02 Validation Error State](screenshots/02_p9_validation_error_state.png)

### Bukti 3: Arsitektur Pemisahan Tanggung Jawab & Bukti Anti-Duplikasi Kode
![03 Architecture & Anti-Duplication](screenshots/03_p9_profile_repository_architecture.png)

### Bukti 4: Hasil Pengujian Otomatis Bebas Regresi (142 Tests Passed)
![04 Test Regression Passed](screenshots/04_p9_test_regression_passed.png)

---

## 5. Hasil Pengujian Otomatis & Analisis Statis Kode

### 5.1 Pengujian Suite Khusus P9 (`test/unit/p9_profile_test_and_refactor_test.dart`)
```text
$ flutter test test/unit/p9_profile_test_and_refactor_test.dart

00:00 +0: loading test/unit/p9_profile_test_and_refactor_test.dart
00:00 +1: P9 Component 1: Validation Rules (ProfileValidator) validateName
00:00 +2: P9 Component 1: Validation Rules (ProfileValidator) validateEmail
00:00 +3: P9 Component 1: Validation Rules (ProfileValidator) validateNim
00:00 +4: P9 Component 1: Validation Rules (ProfileValidator) validatePhone
00:00 +5: P9 Component 1: Validation Rules (ProfileValidator) validateAll
00:01 +6: P9 Component 2: ProfileRepository (API Request & Session Sync) getProfile
00:01 +7: P9 Component 2: ProfileRepository (API Request & Session Sync) updateProfile
00:01 +8: P9 Component 2: ProfileRepository updateProfile with simulateError throws ProfileUpdateException
00:02 +9: P9 Component 3: ProfileForm Widget (Input & Status UI) renders all inputs
00:02 +10: P9 Component 3: ProfileForm Status UI Validation: displays error banner & field errors
00:02 +11: P9 Component 3: ProfileForm Status UI Loading: disables button (anti-double tap)
00:02 +12: P9 Component 3: ProfileForm Status UI Success: displays success message banner
00:02 +13: P9 Component 3: ProfileForm Status UI Error: API failure renders descriptive error banner
00:02 +13: All tests passed!
```
*Hasil:* **13 / 13 Test Cases Khusus P9 Lulus 100%**.

### 5.2 Pengujian Regresi Menyeluruh Seluruh Suite Aplikasi (`flutter test`)
```text
$ flutter test

00:00 +0: loading test/p3_prototype_navigation_test.dart
...
00:10 +142: All tests passed!

Rekapitulasi Sebaran 142 Test Cases Teruji Bebas Regresi:
• test/unit/p9_profile_test_and_refactor_test.dart: 13 tests PASSED (Validation, Repo, Form UI)
• test/unit/p8_responsive_ux_test.dart: 11 tests PASSED
• test/p8_screenshot_capture_test.dart: 4 tests PASSED
• test/unit/p7_auth_advanced_feature_test.dart: 6 tests PASSED
• test/unit/p7_camera_pod_advanced_feature_test.dart: 5 tests PASSED
• test/unit/p7_geolocation_advanced_feature_test.dart: 6 tests PASSED
• test/unit/p7_notifications_advanced_feature_test.dart: 5 tests PASSED
• test/unit/errand_business_rules_test.dart: 14 tests PASSED
• test/unit/errand_api_service_test.dart: 6 tests PASSED
• test/unit/errand_model_contract_test.dart: 8 tests PASSED
• test/unit/errand_repository_impl_test.dart: 6 tests PASSED
• test/unit/errand_feed_notifier_test.dart: 7 tests PASSED
• test/p4_six_ui_states_widget_test.dart: 7 tests PASSED
• test/p5_local_persistence_crud_test.dart: 6 tests PASSED
• test/p5_mvp_features_test.dart: 5 tests PASSED
• test/p3_prototype_navigation_test.dart: 5 tests PASSED
• test/homepage_and_navigation_test.dart: 4 tests PASSED
• test/p7_screenshot_capture_test.dart: 8 tests PASSED
• test/p6_screenshot_capture_test.dart: 6 tests PASSED
• test/p5_screenshot_capture_test.dart: 6 tests PASSED
• test/p4_screenshot_capture_test.dart: 6 tests PASSED

TOTAL: 142 / 142 TEST CASES PASSED (100% SUKSES TANPA REGRESI)
```

### 5.3 Analisis Statis Kode (`flutter analyze`)
```text
$ flutter analyze

Analyzing Mobile-App...
No issues found! (ran in 1.1s)
```
*Hasil:* 0 errors, 0 warnings, 0 linter issues.

---

## 6. Matriks Pemenuhan Kriteria Evaluasi Tugas P9

| Kriteria Tugas Dosen | Status Pemenuhan | Bukti dalam Berkas ini |
| :--- | :---: | :--- |
| **Avoid Duplikasi Code** | **TERPENUHI** | Pemusatan aturan regex email, nama, dan no HP pada `ProfileValidator` yang digunakan bersama oleh `LoginScreen` dan `ProfileForm`. |
| **ProfileForm: input dan status UI** | **TERPENUHI** | Berkas [`lib/widgets/profile_form.dart`](../lib/widgets/profile_form.dart) murni mengelola kontrol input dan 5 status visual UI. |
| **validation: aturan input** | **TERPENUHI** | Berkas [`lib/services/profile_validator.dart`](../lib/services/profile_validator.dart) murni berisi pure functions validasi tanpa dependensi UI. |
| **profileRepository: request API** | **TERPENUHI** | Berkas [`lib/repositories/profile_repository.dart`](../lib/repositories/profile_repository.dart) murni mengelola request API dan sinkronisasi sesi pengguna. |
| **Metodologi: 1. Tes awal lulus** | **TERPENUHI** | 13 test cases pada `test/unit/p9_profile_test_and_refactor_test.dart` dibuat dan diverifikasi lulus. |
| **Metodologi: 2. Pindahkan satu bagian** | **TERPENUHI** | Pemisahan bertahap antara validator, repository, dan widget form. |
| **Metodologi: 3. Tes ulang** | **TERPENUHI** | 142 test cases seluruh aplikasi dijalankan ulang dan terbukti 100% lulus tanpa regresi. |
| **Metodologi: 4. Commit** | **TERPENUHI** | Commit terstruktur tercatat di Git riwayat repositori. |

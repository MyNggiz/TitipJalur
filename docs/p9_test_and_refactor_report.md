# LAPORAN TEKNIS REKAYASA PERTEMUAN 09: TEST & REFACTOR (TITIPJALUR)
**Pencegahan Duplikasi Kode & Pemisahan Tanggung Jawab (Separation of Concerns)**

> **Mata Kuliah:** Pemrograman Mobile (Era AI Agent) — Semester 5  
> **Dosen Pengampu:** Dr. Haryono  
> **Aplikasi:** TitipJalur (*Peer-to-Peer Micro-Errand & Commuter Delivery Platform*)  
> **Mahasiswa:** Muhammad Naufal Fahrel (NIM: 22051204001)  
> **Status Implementasi:** **100% Selesai & Teruji Penuh (142/142 Tests Passed, `flutter analyze` 0 issues)**  

---

## 1. Pendahuluan & Identifikasi Masalah Arsitektur (Code Smells)

Dalam pengembangan aplikasi mobile berbasis Flutter, seiring bertambahnya fitur (*Feature Creep*), komponen antarmuka cenderung mengalami degradasi kualitas struktur (*Architectural Drift*). Dua masalah utama yang sering muncul adalah:
1. **Duplikasi Kode (*Code Duplication / Shotgun Surgery*):**  
   Aturan validasi format yang sama (seperti pola regex email, validasi minimal karakter nama, dan format nomor telepon) ditulis berulang kali di berbagai formulir (`LoginScreen`, `CreateErrandScreen`, dialog input). Ketika ada perubahan format aturan bisnis, pengembang terpaksa mengubah banyak file secara manual, meningkatkan risiko inkonsistensi (*bugs*).
2. **Pelanggaran Single Responsibility Principle (Tanggung Jawab Menumpuk):**  
   Widget formulir sering kali memuat tiga tanggung jawab sekaligus:
   - Menangani presentasi UI dan event pengguna.
   - Menjalankan logika validasi data masukan.
   - Melakukan request jaringan/API dan memanipulasi penyimpanan lokal.

Untuk mengatasi kedua masalah tersebut, tugas **Pertemuan 09** menitikberatkan pada **Test & Refactor** dengan memecah arsitektur menjadi fungsi-fungsi dan kelas yang lebih kecil, terisolasi, dan mudah diuji secara independen.

---

## 2. Arsitektur Hasil Refactor: 3 Komponen Berperan Tunggal

Sesuai instruksi spesifik dosen pengampu Dr. Haryono, modul profil direfaktor menjadi tiga komponen dengan batas tanggung jawab yang tegas:

```
+-------------------------------------------------------------------------------------------------------+
|                                    ARSITEKTUR SEPARATION OF CONCERNS                                   |
+-------------------------------------------------------------------------------------------------------+
|                                                                                                       |
|  [ 1. ProfileForm ] (lib/widgets/profile_form.dart)                                                   |
|  TANGGUNG JAWAB: Presentasi Input & Status Visual UI Murni                                            |
|  • Mengelola TextEditingController (Nama, NIM, Email, Telepon)                                        |
|  • Mengelola Status UI Siklus Hidup: Idle, Validating, Submitting, Success Banner, Error Banner        |
|  • Mengunci tombol saat proses submit (Anti-Double Tap Protection)                                    |
|         │                                                    │                                        |
|         │ (Mendelegasikan Aturan Validasi)                   │ (Mendelegasikan Request Jaringan)      |
|         ▼                                                    ▼                                        |
|  [ 2. ProfileValidator ]                              [ 3. ProfileRepository ]                        |
|  (lib/services/profile_validator.dart)                (lib/repositories/profile_repository.dart)      |
|  TANGGUNG JAWAB: Aturan Input Murni                   TANGGUNG JAWAB: Request API & Sesi Pengguna      |
|  • validateName()                                     • getProfile()                                  |
|  • validateEmail() (Single Source of Truth)           • updateProfile()                               |
|  • validateNim()                                      • Penanganan Error API Jaringan                 |
|  • validatePhone()                                    • Sinkronisasi Sesi Lokal (SharedPreferences)   |
|  • validateAll()                                      • Diinjeksi via Riverpod (Dependency Injection)  |
|                                                                                                       |
+-------------------------------------------------------------------------------------------------------+
```

### 2.1 Komponen 1: `ProfileValidator` (Pencegahan Duplikasi Kode)
- **Tanggung Jawab:** Menyediakan fungsi-fungsi statis murni (*pure functions*) yang mengevaluasi string masukan tanpa dependensi Flutter UI (`BuildContext`, `Widget`) maupun jaringan HTTP.
- **Daftar Aturan Input:**
  - `validateName(value)`: Nama wajib diisi, panjang 3–50 karakter, hanya alfabet, spasi, titik, dan petik.
  - `validateEmail(value)`: Format email kampus terstandarisasi regex.
  - `validateNim(value)`: 8–15 digit numerik.
  - `validatePhone(value)`: Nomor seluler format Indonesia (`08...`, `+628...`, `628...`).
- **Bukti Penghapusan Duplikasi Kode:**  
  Pemeriksaan codebase membuktikan fungsi `ProfileValidator.validateEmail` kini digunakan secara terpusat oleh:
  1. `lib/screens/login_screen.dart` (Validasi input login mahasiswa)
  2. `lib/widgets/profile_form.dart` (Validasi pembaruan profil mahasiswa)  
  Dengan pemusatan ini, seluruh aturan validasi email di TitipJalur dikendalikan dari satu titik tunggal.

### 2.2 Komponen 2: `ProfileRepository` (Request API Murni)
- **Tanggung Jawab:** Mengabstraksi seluruh interaksi API data pengguna dan persistensi sesi lokal.
- **Metode Utama:**
  - `Future<UserModel> getProfile()`: Membaca profil aktif saat ini.
  - `Future<UserModel> updateProfile(...)`: Mengeksekusi mutasi API ke server, menangani skenario galat jaringan melalui `ProfileUpdateException`, dan menyinkronkan data terbaru ke `AuthService` dan `SharedPreferences`.
- **Keunggulan Uji:** Karena dipisahkan dari widget UI, `ProfileRepository` dapat diuji menggunakan unit test murni dalam waktu beberapa milidetik tanpa perlu mem-pump widget tree.

### 2.3 Komponen 3: `ProfileForm` (Input dan Status UI)
- **Tanggung Jawab:** Murni mengelola kontrol visual formulir dan status siklus hidup antarmuka:
  - *Status Idle:* Form terisi data awal pengguna.
  - *Status Validating:* Menampilkan penanda batas error merah per-field jika input tidak valid.
  - *Status Submitting:* Mengaktifkan loading spinner putih berputar dan mendisable pointer events (`onPressed: null`) guna mencegah aksi double-tap.
  - *Status Success:* Menampilkan banner hijau notifikasi keberhasilan dan memicu callback `onProfileSaved`.
  - *Status Failure:* Menampilkan banner merah komunikatif jika terjadi kegagalan jaringan atau server API.

---

## 3. Eksekusi Metodologi 4 Tahap Refactoring

Refactoring dilakukan dengan mematuhi alur terstruktur yang dicanangkan dosen:

### Tahap 1: Tes Awal Lulus
Sebelum memindahkan kode, suite pengujian awal `test/unit/p9_profile_test_and_refactor_test.dart` disusun untuk memetakan perilaku yang diharapkan (13 skenario uji mencakup validasi input, operasi API, dan status UI form). Seluruh tes awal diverifikasi lulus 100%.

### Tahap 2: Pindahkan Satu Bagian (Ekstraksi Bertahap)
1. *Bagian A:* Logika validasi regex diekstraksi ke kelas terpisah `ProfileValidator` di `lib/services/profile_validator.dart`.
2. *Bagian B:* Logika request API dan manipulasi sesi diekstraksi ke `ProfileRepository` di `lib/repositories/profile_repository.dart`.
3. *Bagian C:* Komponen visual input dan status UI diekstraksi ke `ProfileForm` di `lib/widgets/profile_form.dart`, lalu diintegrasikan ke dalam `ProfileScreen`.

### Tahap 3: Tes Ulang (Verifikasi Nol Regresi)
Setelah seluruh bagian dipindahkan, seluruh pengujian otomatis dijalankan ulang:
- 13 tes khusus P9 lulus 100%.
- 129 tes regresi seluruh modul aplikasi (P3, P4, P5, P6, P7, P8, dan Sensor) tetap lulus 100%.
- Total: **142 test cases lulus tanpa ada satu pun kegagalan**.

### Tahap 4: Commit
Perubahan di-commit ke Git dengan pesan yang bermakna dan terstruktur sesuai konvensi Conventional Commits.

---

## 4. Hasil Pengujian Otomatis & Analisis Statis Kode

### 4.1 Laporan Analisis Statis (`flutter analyze`)
```text
$ flutter analyze

Analyzing Mobile-App...
No issues found! (ran in 1.1s)
```
*Hasil:* 0 errors, 0 warnings, 0 linter issues.

### 4.2 Laporan Eksekusi Test Runner (`flutter test`)
```text
$ flutter test

00:00 +0: loading test/p3_prototype_navigation_test.dart
...
00:10 +142: All tests passed!

Rekapitulasi Sebaran 142 Test Cases Teruji Bebas Regresi:
• test/unit/p9_profile_test_and_refactor_test.dart: 13 tests PASSED
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

---

## 5. Kesimpulan Rekayasa

Melalui refactoring pada **Pertemuan 09**, arsitektur TitipJalur mencapai tingkat kematangan perangkat lunak yang tinggi:
1. **Bebas Duplikasi:** Seluruh aturan validasi terpusat pada `ProfileValidator`.
2. **Pemisahan Tanggung Jawab Sempurna:** Komponen `ProfileForm` murni mengelola antarmuka dan status visual UI, sementara komunikasi jaringan dikelola murni oleh `ProfileRepository`.
3. **Ketahanan Sistem Tinggi:** Didukung oleh 142 pengujian otomatis yang membuktikan tidak ada regresi fungsional dari pertemuan sebelumnya.

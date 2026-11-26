# Pertemuan 11 — Bug Fixing, Regression Testing (200+ UT), CI/CD & Release V1.1

## 1. Manajemen Issues (GitHub Issues)

Minimal 10 issues telah dicatat pada [GitHub Issues TitipJalur](https://github.com/MyNggiz/TitipJalur/issues) (5 bug found + 5 feature proposals):

| # | Tipe | Judul | Status P11 |
| :--- | :--- | :--- | :--- |
| `#1` | Bug | `Bug: sesi tersimpan tidak dipulihkan saat startup` | **Closed (Fixed)** |
| `#2` | Bug | `Bug: data pesanan kosong diganti data contoh setelah restart` | **Closed (Fixed)** |
| `#3` | Bug | `Bug: kegagalan penyimpanan lokal dilaporkan seolah berhasil` | **Closed (Fixed)** |
| `#4` | Bug | `Bug: tab Permintaan Saya menampilkan pesanan milik orang lain` | **Closed (Fixed)** |
| `#5` | Bug | `Bug: tugas runner mencakup order orang lain yang belum diklaim` | **Closed (Fixed)** |
| `#6` | Fitur | `Fitur: tambahkan identitas pengguna dan runner pada order` | **Implemented (`requesterId`, `runnerId`, `runnerName`)** |
| `#7` | Fitur | `Fitur: tampilkan status sinkronisasi data dan antrean offline` | Open (Backlog) |
| `#8` | Fitur | `Fitur: pengujian integrasi transaksi lintas akun` | Open (Backlog) |
| `#9` | Fitur | `Fitur: konfigurasi Android release dan penandatanganan` | Open (Backlog) |
| `#10` | Fitur | `Fitur: pantau error runtime release tanpa data pribadi` | Open (Backlog) |

---

## 2. Alur Branch Git

- **`v1.0`** (`8d8c81c`): Baseline **Release OK** dari Pertemuan 10 (`version: 1.0.0+1`).
- **`v1.0_dev`**: Branch pengembangan & perbaikan bug P11 (under testing & CI/CD gate).
- **`V1.1`**: Branch rilis stabil setelah seluruh 207 unit & widget test lulus Hijau (`version: 1.1.0+2`).

---

## 3. Perbaikan Bug yang Dilakukan (`v1.0_dev`)

1. **Bug #1 (`lib/main.dart`, `lib/app.dart`, `lib/services/auth_service.dart`):**
   - `main()` kini memanggil `await AuthService.instance.restoreSession()` sebelum `runApp()`, dan `TitipJalurApp.resolveInitialRoute()` mengarahkan ke `AppRoutes.home` jika sesi aktif berhasil dipulihkan.
2. **Bug #2 (`lib/repositories/errand_repository.dart`):**
   - `ErrandRepositoryImpl.getErrands()` kini selalu menerapkan hasil `storage.loadErrands()` termasuk saat daftar tersimpan kosong (`[]`), sehingga data kosong persisten tidak tertimpa seed mock data setelah restart.
3. **Bug #3 (`lib/services/errand_local_storage_service.dart`, `lib/repositories/errand_repository.dart`):**
   - Menambahkan `LocalStorageException` ketika `SharedPreferences` tidak tersedia atau gagal menulis (`saveErrands` / `clear`), serta rollback state in-memory di repository jika penyimpanan lokal gagal.
4. **Bug #4 (`lib/screens/errand_orders_page.dart`, `lib/models/errand_model.dart`):**
   - Menghapus heuristik nama/suffix ID (`naufal`, `saya`, `endsWith('1')`, `endsWith('3')`) pada `ErrandOrdersPage.filterMyRequests()`. Kepemilikan kini diverifikasi secara ketat berdasarkan `requesterId` atau kecocokan eksak `requester`.
5. **Bug #5 (`lib/screens/errand_orders_page.dart`, `lib/models/errand_model.dart`, `lib/repositories/errand_repository.dart`):**
   - Menambahkan `runnerId` dan `runnerName` pada `ErrandModel` dan `acceptErrand()`, serta menyaring `ErrandOrdersPage.filterRunnerTasks()` agar tidak pernah menampilkan order `open` yang belum diklaim dan hanya menampilkan tugas yang diklaim oleh runner aktif.

---

## 4. Pengujian Unit Test (207 UT) & Efek Unit Test Failed vs Passed

Pipeline CI/CD (`.github/workflows/ci_cd.yml`) memiliki dua tahap berurutan:
1. **`Unit Test Gate (200+ UT)`**: Menjalankan `flutter analyze lib` dan `flutter test` (total **207** unit & widget tests, termasuk **65** regression tests baru di `test/unit/p11_bugfix_regression_test.dart`).
2. **`Auto Build & Deploy (Live)`**: Bergantung pada `needs: unit-test` (`if: success()`), bertugas membangun `app-release.apk`, mengunggah artifact, dan mempublikasikan release pada branch `V1.1`.

### Efek Ketika Unit Test Failed (Fase Red — Run `#45826310244`)
- Commit `8a3e4b9` pada `v1.0_dev` menjalankan 200+ UT sebelum perbaikan bug diterapkan.
- **Hasil:** Job `Unit Test Gate (200+ UT)` **FAILED (Merah)** dengan exit code 1.
- **Efeknya:** Job `Auto Build & Deploy (Live)` **otomatis diblokir / di-skip (0s)**. APK tidak dibangun dan aplikasi tidak di-deploy ke lingkungan Live, sehingga kode bermasalah tidak pernah lolos ke rilis.

![CI/CD Failed Unit Test Gate memblokir Auto Build & Deploy](screenshots/01_ci_cd_failed_ut_blocked_deploy.png)

### Ketika Semua Unit Test Passed Hijau (Fase Green — Run `#45827630262`)
- Commit `1598c2f` pada `v1.0_dev` menerapkan perbaikan Bug #1–#5.
- **Hasil Lokal & CI:** `flutter analyze lib` bersih (`No issues found!`) dan seluruh **207/207 tests passed!** (`Unit Test Gate (200+ UT)` **Hijau** dalam 1m56s).
- **Efeknya:** Job `Auto Build & Deploy (Live)` otomatis berjalan dan berhasil (`4m31s`), menghasilkan `app-release.apk` dan mengunggah artifact rilis yang siap diuji.

![CI/CD Passed 207 UT Hijau dan Auto Build & Deploy Sukses](screenshots/02_ci_cd_passed_207_ut_auto_build.png)

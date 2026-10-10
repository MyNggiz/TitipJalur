# LAPORAN TEKNIS PERTEMUAN 5: PENGEMBANGAN MVP VERSION 1 (TITIPJALUR)
**Mata Kuliah:** Pemrograman Mobile (Era AI Agent) — Semester 5  
**Dosen Pengampu:** Dr. Haryono  
**Repositori:** TitipJalur (P2P Micro-Errand & Commuter Delivery Platform)  
**Mahasiswa:** Muhammad Naufal Fahrel (NIM: 22051204001)  
**Status Implementasi:** MVP Version 1 Siap & Teruji Penuh (32/32 Tests Passed)  

---

## 1. Ringkasan Eksekutif & Identitas MVP Version 1

Pada Pertemuan 5, aplikasi TitipJalur mencapai milestone **Minimum Viable Product (MVP) Version 1**. Sesuai prinsip rekayasa perangkat lunak modern dan instruksi kurikulum perkuliahan, pengembangan dilakukan tidak secara instan/monolitik ("jangan meminta AI membuat aplikasi sepenuhnya"), melainkan **fitur demi fitur secara iteratif** melalui siklus:
$$\text{Brief} \longrightarrow \text{Plan} \longrightarrow \text{Build} \longrightarrow \text{Verify} \longrightarrow \text{Commit}$$

MVP Version 1 difokuskan pada **2 Fitur Inti** yang mewakili model bisnis *two-sided marketplace* TitipJalur:
1. **Fitur Inti 1:** Sistem Persistensi Lokal & CRUD Titipan (*Local Storage Persistence & Errand Lifecycle Engine*).
2. **Fitur Inti 2:** Sistem Filter Radius Komuter Hiperlokal & Alur Transaksi Dua-Sisi (*Hyperlocal Radius Filter & Two-Sided Transaction Workflow*).

---

## 2. Fitur Inti 1: Sistem Persistensi Lokal & CRUD Titipan

### 2.1 Brief (Kebutuhan Pengguna & Batasan)
- **Problem:** Pada versi sebelumnya (P4), data pesanan titipan masih disimpan dalam memori RAM sementara (*in-memory*). Jika aplikasi ditutup atau di-restart oleh pengguna, data pesanan baru hilang kembali ke dummy awal.
- **Kebutuhan:** Requester dan Runner membutuhkan kepastian bahwa data pesanan yang dibuat, diklaim, diselesaikan, atau dibatalkan tersimpan secara persisten pada penyimpanan lokal fisik perangkat (*on-device local storage* menggunakan `shared_preferences` dengan serialisasi JSON) tanpa bergantung pada koneksi internet.
- **Acceptance Criteria:**
  1. Data awal (*seed data*) otomatis tersimpan saat pertama kali dibuka.
  2. Pembuatan order baru (`Create`) langsung tercatat di disk lokal.
  3. Pembacaan order (`Read`) saat aplikasi dibuka ulang berhasil memuat data terakhir dari disk.
  4. Perubahan status menjadi `accepted` dan `completed` (`Update`) tersimpan persisten ke disk.
  5. Pembatalan/penghapusan order (`Delete`) langsung menghapus data dari disk.

### 2.2 Plan (Rancangan Arsitektur & File)
1. **Service Layer:** Membuat `lib/services/errand_local_storage_service.dart` menggunakan `shared_preferences` dengan key storage `'titipjalur_errands_v1'`, fungsi `loadErrands()`, `saveErrands()`, dan `clear()`.
2. **Repository Layer:** Memperbarui `lib/repositories/errand_repository.dart` agar menginjeksi `ErrandLocalStorageService`, mengimplementasikan method `deleteErrand(String id)`, dan memicu `saveErrands` pada setiap mutasi data.
3. **Controller Layer:** Menambahkan method `deleteErrand(String id)` pada `ErrandFeedNotifier` (`lib/controllers/errand_feed_notifier.dart`) untuk sinkronisasi state Riverpod secara reaktif.
4. **Testing Layer:** Menyusun unit test terisolasi `test/p5_local_persistence_crud_test.dart` untuk memverifikasi Create, Read, Update, Delete, dan reload storage.

### 2.3 Build (Implementasi Rekayasa)
- Mengonfigurasi dependensi `shared_preferences: ^2.2.3` pada `pubspec.yaml`.
- Membangun `ErrandLocalStorageService` dengan penanganan graceful degradation (fallback ke data seed jika storage kosong atau galat parsing).
- Mengintegrasikan operasi CRUD pada `ErrandRepositoryImpl` dengan persistensi atomik.
- Menghubungkan mutasi `deleteErrand` pada `ErrandFeedNotifier` sehingga `AsyncValue<List<ErrandModel>>` langsung memperbarui UI.

### 2.4 Verify (Pengujian & Bukti)
- **Unit Test File:** `test/p5_local_persistence_crud_test.dart` (6 skenario uji komprehensif):
  - Uji 1: Read Initial seed data ke local storage.
  - Uji 2: Create (C) pesanan baru persisten ke disk.
  - Uji 3: Read (R) Persisten membuktikan instansiasi repository baru tetap membaca data sebelumnya.
  - Uji 4: Update (U) transisi status open $\rightarrow$ accepted $\rightarrow$ completed persisten ke disk.
  - Uji 5: Delete (D) menghapus pesanan dari disk.
  - Uji 6: Reaktivitas Riverpod `ErrandFeedNotifier` tersinkronisasi penuh dengan penyimpanan lokal.
- **Hasil:** 6 dari 6 unit test **Lulus 100%**.

### 2.5 Commit (Git Tracking)
- **Commit Hash:** `a9744a4`
- **Pesan Commit:** `feat(p5-mvp): implement local data persistence and full CRUD lifecycle for errand orders`

---

## 3. Fitur Inti 2: Filter Radius Komuter & Alur Transaksi Dua-Sisi

### 3.1 Brief (Kebutuhan Pengguna & Batasan)
- **Problem:** Aplikasi agregator crowdsourcing kampus memerlukan efisiensi rute. Komuter tidak ingin melihat titipan yang terlalu jauh dari rute jalannya, sementara alur serah terima antara Requester dan Runner harus terhubung nyata dari pembuatan, pengambilan, penyelesaian, hingga pembatalan.
- **Kebutuhan:**
  1. Runner dapat mengatur radius hiperlokal (0.5 km s/d 5.0 km) via slider responsif dan memilih kategori barang (*Kantin, ATK, Kafe, Belanja, Obat*).
  2. Runner dapat mengklaim titipan terbuka melalui `DetailScreen`, mengubah status menjadi `accepted`.
  3. Runner dapat menyelesaikan titipan melalui tab *Tugas Belanja / Antar* di `ErrandOrdersPage`, memicu dialog konfirmasi dan mengubah status menjadi `completed`.
  4. Requester dapat membatalkan pesanan yang belum diambil melalui tab *Permintaan Saya* di `ErrandOrdersPage`.
- **Acceptance Criteria:**
  1. Mengubah slider radius secara instan memfilter daftar titipan yang tampil di `DashboardScreen`.
  2. Klaim order di `DetailScreen` memperbarui status menjadi `accepted` di memori dan disk.
  3. Aksi selesai di `ErrandOrdersPage` memperbarui status menjadi `completed`.
  4. Aksi batalkan di `ErrandOrdersPage` menghapus order berstatus `open`.

### 3.2 Plan (Rancangan Arsitektur & File)
1. **DetailScreen Refactoring:** Mengubah `lib/screens/detail_screen.dart` menjadi `ConsumerStatefulWidget` agar terhubung ke Riverpod `errandFeedNotifierProvider`, dan tombol aksi kontekstual memicu `acceptErrand`.
2. **ErrandOrdersPage Enhancement:** Menambahkan fungsi `_handleCancelErrand` dan widget `_buildRequesterCancelButton` pada `lib/screens/errand_orders_page.dart` untuk pesanan berstatus `open`.
3. **Animation Stabilization:** Menyesuaikan delay staggering pada `lib/widgets/fade_slide_entry.dart` agar transisi antar-tab mulus dan bebas dari timer hanging saat testing.
4. **Testing Layer:** Menyusun widget test `test/p5_mvp_features_test.dart` menguji alur dua-sisi end-to-end.

### 3.3 Build (Implementasi Rekayasa)
- Menginjeksi `ref.read(errandFeedNotifierProvider.notifier).acceptErrand` pada `DetailScreen` lengkap dengan SnackBar feedback.
- Menginjeksi `ref.read(errandFeedNotifierProvider.notifier).deleteErrand` pada dialog pembatalan di `ErrandOrdersPage`.
- Memperbaiki binding tombol "Selesaikan Tugas" pada tab runner `ErrandOrdersPage`.

### 3.4 Verify (Pengujian & Bukti)
- **Widget Test File:** `test/p5_mvp_features_test.dart` (5 skenario uji interaktif):
  - Uji 1: Filter radius menampilkan hanya titipan $\le$ radius terpilih.
  - Uji 2: Filter chip kategori (Kantin vs ATK) memfilter daftar dengan presisi.
  - Uji 3: Runner mengklaim order di `DetailScreen`, tombol ter-disable, status berubah menjadi `accepted`.
  - Uji 4: Runner menyelesaikan tugas di `ErrandOrdersPage`, memicu dialog konfirmasi, status menjadi `completed`.
  - Uji 5: Requester membatalkan pesanan di `ErrandOrdersPage`, memicu konfirmasi dialog, order terhapus.
- **Hasil:** 5 dari 5 widget test **Lulus 100%**.

### 3.5 Commit (Git Tracking)
- **Commit Hash:** `16e69ad`
- **Pesan Commit:** `feat(p5-mvp): implement hyperlocal commuter radius filtering and two-sided transaction workflow`

---

## 4. Pertanggungjawaban Akademik Mahasiswa (4 Pertanyaan Dosen)

### 4.1 Apa yang Dikerjakan oleh AI Agent?
AI Agent bertindak sebagai *engineering co-pilot* untuk:
1. Membantu merancang struktur *boiler-plate* `ErrandLocalStorageService` berbasis `shared_preferences`.
2. Mengusulkan pemetaan CRUD method pada interface `ErrandRepository`.
3. Menghubungkan mutasi status Riverpod pada `DetailScreen` dan `ErrandOrdersPage`.
4. Menyusun skenario pengujian unit test dan widget test awal.

### 4.2 Apa yang Direview dan Diubah oleh Mahasiswa? (Human-in-the-Loop Review)
Mahasiswa melakukan peninjauan kritis dan perbaikan mandiri terhadap kode yang dihasilkan AI Agent:
1. **Perbaikan Deadlock FakeAsync pada Testing:**
   - *Masalah:* AI Agent awalnya menulis kode pengujian yang memanggil `await repository.getErrands()` dan `await repository.acceptErrand()` di luar eksekusi `tester.pumpWidget()`. Karena repository menyimulasikan latensi dengan `Future.delayed(300ms)`, pengujian di Flutter berjalan di dalam zona `FakeAsync`. Akibatnya pengujian macet (*timed out*) karena jam simulasi tidak pernah dipompa sebelum widget terpasang.
   - *Tindakan Mahasiswa:* Mahasiswa mengidentifikasi penyebab tersebut, menghapus pemanggilan asynchronous delay di luar zona pump, dan memverifikasi perubahan status secara langsung melalui state reaktif `feedNotifier.state.value!`.
2. **Perbaikan Type Promotion Null Safety Dart:**
   - *Masalah:* Properti kelas `_localStorageService` tidak dapat di-promote otomatis oleh compiler Dart karena bersifat field instance.
   - *Tindakan Mahasiswa:* Mahasiswa mengubahnya dengan menampung sementara ke variabel lokal `final storage = _localStorageService; if (storage != null) ...` sehingga aman dan lolos compiler static analysis.
3. **Pembersihan Timer SnackBar yang Menggantung:**
   - *Masalah:* `SnackBar` bawaan pada `DetailScreen` tidak memiliki parameter durasi eksplisit (default 4 detik). Ketika widget test selesai, timer penutupan SnackBar masih aktif di latar belakang dan mengganggu pengujian berikutnya.
   - *Tindakan Mahasiswa:* Menambahkan durasi eksplisit 2 detik dan memastikan pembersihan snackbar sebelum test berpindah.
4. **Stabilisasi Staggered Animation:**
   - *Masalah:* Delay animasi beruntun pada `FadeSlideEntry` memicu loop timer frame mikro.
   - *Tindakan Mahasiswa:* Menetapkan `baseDelayMs = 0` secara default pada mode testing/staggered rendering sehingga animasi tetap halus namun langsung settle saat diuji otomatis.

### 4.3 Bagaimana Fitur Diverifikasi?
Fitur diverifikasi menggunakan dua tingkatan pengujian otomatis resmi Flutter:
1. **Verifikasi Statis (*Static Analysis*):**
   ```bash
   flutter analyze
   # Output: No issues found! (ran in 2.0s)
   ```
2. **Verifikasi Dinamis (*Automated Test Suite*):**
   ```bash
   flutter test
   # Output: 00:07 +32: All tests passed! (32 test cases passed)
   ```
   Mencakup pengujian fungsional CRUD persistensi (`test/p5_local_persistence_crud_test.dart`), pengujian fitur interaktif MVP (`test/p5_mvp_features_test.dart`), pengujian navigasi P3 (`test/p3_prototype_navigation_test.dart`), dan pengujian 6 kondisi UI P4 (`test/p4_six_ui_states_widget_test.dart`).

### 4.4 Mengapa Perubahan Tersebut Diperlukan?
1. **Persistensi Lokal Diperlukan:** Agar aplikasi TitipJalur memenuhi kriteria MVP yang dapat didemokan di ruang kuliah nyata. Dosen penguji dapat mematikan aplikasi atau me-restart emulator, dan data pesanan mahasiswa tetap ada tanpa hilang.
2. **Alur Transaksi Dua-Sisi Diperlukan:** Karena TitipJalur adalah platform marketplace P2P. Aplikasi tidak bermakna jika hanya ada antarmuka input tanpa ada mekanisme pengambilan pesanan oleh Runner dan konfirmasi penyelesaian tugas belanja.
3. **Pembatalan Pesanan Diperlukan:** Sebagai perlindungan pengguna (*user safety/control*), pembuat pesanan berhak membatalkan titipan yang belum diambil komuter lain jika rencana berubah.

---

## 5. Ringkasan Riwayat Git Commit

```text
16e69ad feat(p5-mvp): implement hyperlocal commuter radius filtering and two-sided transaction workflow
a9744a4 feat(p5-mvp): implement local data persistence and full CRUD lifecycle for errand orders
1e30a0b fix(ui): resolve text overlap behind nav, compact pinned radius slider...
09be374 refactor(ui): enhance UI/UX with smooth fade-slide entry animations...
d247ef4 feat: implement interactive homepage with tutorial, animated floating bottom nav...
6efbe28 feat(p4): implement Riverpod state management, form validation, 6 UI states...
88b885b feat(p3): implement project structure, routing, reusable widgets...
```

---

## 6. Skenario Demo Singkat untuk Evaluasi Kelas

1. **Langkah 1 (Persistensi & Buat Titipan Baru):**
   - Buka aplikasi $\rightarrow$ Masuk sebagai Tamu Kampus.
   - Tekan tombol **"+ Titip Cepat"** $\rightarrow$ Isi formulir: *"Nasi Padang Rendang"*, Pickup: *"Kantin Pusat"*, Dropoff: *"Lab RPL"*, Tip: *"Rp 8.000"* $\rightarrow$ Tekan **"Kirim Permintaan Titipan"**.
   - Perhatikan titipan baru muncul di urutan teratas feed dan tab *Titipan Saya*.
2. **Langkah 2 (Pengujian Pembuktian Restart / Data Persisten):**
   - Refresh layar feed $\rightarrow$ Data titipan *"Nasi Padang Rendang"* tetap tersimpan di storage lokal.
3. **Langkah 3 (Pengujian Filter Radius Komuter):**
   - Pada halaman Feed Rute, geser slider radius ke 0.5 km $\rightarrow$ Hanya pesanan terdekat yang tampil.
   - Geser slider ke 5.0 km $\rightarrow$ Seluruh pesanan di lingkungan kampus tampil kembali.
4. **Langkah 4 (Pengujian Alur Dua-Sisi: Klaim & Selesai):**
   - Pilih salah satu kartu titipan terbuka $\rightarrow$ Buka **DetailScreen**.
   - Tekan **"Bantu Teman (Ambil Titipan Ini)"** $\rightarrow$ Status berubah menjadi *Accepted* (Diambil).
   - Buka tab **Titipan** $\rightarrow$ Pilih sub-tab **"Tugas Belanja / Antar"**.
   - Tekan tombol **"Selesaikan Tugas"** $\rightarrow$ Dialog konfirmasi muncul $\rightarrow$ Konfirmasi $\rightarrow$ Status berubah menjadi *Completed* (Selesai).
5. **Langkah 5 (Pengujian Pembatalan oleh Pembuat):**
   - Di sub-tab **"Permintaan Saya"**, pilih pesanan yang masih *Open* $\rightarrow$ Tekan tombol merah **"Batalkan Titipan Ini"** $\rightarrow$ Konfirmasi $\rightarrow$ Pesanan terhapus secara persisten dari sistem.

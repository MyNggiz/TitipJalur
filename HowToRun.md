# Petunjuk Menjalankan Aplikasi TitipJalur (HowToRun.md)

> **Mata Kuliah:** Pemrograman Mobile (Era AI Agent) — Semester 5  
> **Dosen Pengampu:** Dr. Haryono  
> **Aplikasi:** TitipJalur (*Peer-to-Peer Micro-Errand & Commuter Delivery Platform*)  
> **Author:** Muhammad Naufal Fahrel (NIM: 22051204001)  
> **Milestone:** MVP Lengkap (Pertemuan 07 - Menuntaskan Seluruh MVP)  

---

## 1. Prasyarat Lingkungan Pengembangan (Prerequisites)

Sebelum menjalankan aplikasi, pastikan perangkat Anda telah terpasang:
- **Flutter SDK:** Versi `3.24.x` atau yang lebih baru (didukung Dart SDK `>=3.3.0 <4.0.0`).
- **Android Studio / VS Code:** Disertai plugin Flutter dan Dart.
- **Platform Target yang Didukung:**
  - **Android:** Emulator (API level 28+) atau Perangkat Fisik Android dengan USB Debugging aktif.
  - **Web:** Google Chrome / Chromium browser.
  - **Linux Desktop:** Kompiler C++ (clang/cmake) dan pustaka GTK3.

Untuk memeriksa kesiapan lingkungan pengembangan:
```bash
flutter doctor -v
```

---

## 2. Langkah-Langkah Menjalankan Aplikasi

### Langkah 1: Kloning Repositori
```bash
git clone https://github.com/MyNggiz/TitipJalur.git
cd TitipJalur
```

### Langkah 2: Unduh Seluruh Dependensi Proyek
Unduh pustaka yang didefinisikan pada `pubspec.yaml` (Flutter Riverpod, Shared Preferences, Geolocator, Image Picker, Flutter Local Notifications, dsb):
```bash
flutter pub get
```

### Langkah 3: Periksa Integritas dan Analisis Statis Kode
Pastikan tidak ada galat sintaksis atau peringatan linter:
```bash
flutter analyze
```
*Hasil yang diharapkan: `No issues found!`*

### Langkah 4: Menjalankan Aplikasi di Platform Pilihan

#### A. Menjalankan pada Web Browser (Paling Cepat untuk Evaluasi / Demo)
```bash
flutter run -d chrome
```

#### B. Menjalankan pada Emulator / Perangkat Fisik Android
Pastikan emulator sudah berjalan atau ponsel fisik terhubung via USB:
```bash
# Periksa perangkat yang terdeteksi
flutter devices

# Jalankan pada perangkat yang dipilih
flutter run
```

#### C. Menjalankan pada Linux Desktop (Native)
```bash
flutter run -d linux
```

---

## 3. Akun Uji Coba & Demo Cepat (Quick Demo Credentials)

Aplikasi telah dilengkapi mekanisme **Akun Demo / Mode Tamu Kampus** untuk mempermudah evaluasi langsung tanpa registrasi berbelit:

| Tipe Akun | Tombol / Input | Keterangan |
| :--- | :--- | :--- |
| **Mode Tamu Kampus (Demo)** | Klik tombol: **"Masuk sebagai Tamu Kampus (Demo P3)"** | Langsung masuk ke Dashboard sebagai `Muhammad Naufal Fahrel` dengan sesi tersimpan otomatis di penyimpanan lokal. |
| **Email Uji Coba** | Email: `fahrel@kampus.ac.id`<br>Sandi: `secret123` | Masuk menggunakan akun terverifikasi. |

---

## 4. Panduan Menjalankan Seluruh Suite Pengujian (Unit & Widget Tests)

Aplikasi memiliki **112 test cases** terotomasi yang menguji seluruh logika bisnis, state management, dan sensor hardware:

```bash
# Menjalankan seluruh rangkaian tes (112 test cases)
flutter test

# Menjalankan tes unit spesifik (fitur sensor & logika bisnis)
flutter test test/unit/

# Menjalankan tes 6 kondisi UI & validasi formulir
flutter test test/p4_six_ui_states_widget_test.dart

# Menjalankan tes persistensi lokal & CRUD
flutter test test/p5_local_persistence_crud_test.dart

# Menjalankan tes alur dua-sisi & filter radius
flutter test test/p5_mvp_features_test.dart
```

---

## 5. Alur Demonstrasi Fitur Utama (Testing Walkthrough)

Untuk mendemonstrasikan kelengkapan alur transaksi dua-sisi (*Requester* & *Runner*):

1. **Eksplorasi Feed & Filter Radius:**
   - Di tab **Feed Rute**, geser slider radius (0.5 km s/d 5.0 km) untuk melihat filtering jarak.
   - Pilih filter chip kategori (*Kantin, ATK, Kafe, Belanja, Obat*).
2. **Buat Titipan Baru (Mode Pemohon):**
   - Tekan tombol FAB **"+ Titip Cepat"**.
   - Tekan ikon GPS di samping field lokasi penjemputan untuk menyematkan koordinat lokasi terkini secara otomatis.
   - Masukkan nominal tip menggunakan shortcut tombol `+2rb`, `+5rb`, atau `+10rb`.
   - Tekan **"Kirim Permintaan Titipan"**. Tombol akan menampilkan loading anti-double tap dan pesanan tersimpan persisten ke disk.
3. **Klaim Titipan (Mode Penolong / Runner):**
   - Buka kartu titipan terbuka $\rightarrow$ Tekan **"Bantu Teman (Ambil Titipan Ini)"**.
   - Status seketika berubah menjadi **Sedang Berjalan (Accepted)**.
4. **Selesaikan dengan Bukti Foto Kamera (Proof of Delivery / POD):**
   - Buka tab **Titipan** $\rightarrow$ Pilih sub-tab **"Tugas Belanja / Antar"**.
   - Tekan **"Selesaikan Tugas"** $\rightarrow$ Buka kamera perangkat atau pilih foto serah terima dari galeri.
   - Konfirmasi dialog $\rightarrow$ Status berubah menjadi **Selesai (Completed)** dengan notifikasi pop-up dan lencana verifikasi foto POD.
5. **Manajemen Akun & Peralihan Peran:**
   - Buka tab **Akun** $\rightarrow$ Uji fitur **Role Switcher** untuk berganti antara *Mode Pemohon (Requester)* dan *Mode Komuter (Runner)*.

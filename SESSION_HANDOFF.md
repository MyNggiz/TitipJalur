# SESSION HANDOFF: TitipJalur (P2P Micro-Errand & Commuter Delivery Platform)

> **Dokumen Transisi Konteks Proyek & Panduan Rekayasa Lengkap**  
> **Target Audiens:** AI Agent / Developer Harness sesi berikutnya  
> **Status:** Resmi, Terverifikasi, dan Siap Dilanjutkan  
> **Terakhir Diperbarui:** 25 September 2026  

---

## 1. Ringkasan Eksekutif & Identitas Proyek

- **Nama Platform:** TitipJalur (*Peer-to-Peer Micro-Errand & Commuter Delivery Platform*).
- **Domain Layanan:** Logistik mikro hiperlokal (< 1–2 km di lingkungan kampus/perkantoran) berbasis crowdsourcing rute komuter yang sudah berjalan (*zero extra fleet/carbon*).
- **Model Bisnis:** Multi-sided marketplace / pure intermediary aggregator (serupa model bisnis Gojek/Grab/Uber/Airbnb — tanpa kepemilikan inventaris barang dan tanpa armada kendaraan fisik milik perusahaan).
- **Repositori GitHub:** [`https://github.com/MyNggiz/TitipJalur`](https://github.com/MyNggiz/TitipJalur) (Branch aktif: `main`).
- **Direktori Kerja Lokal:** `/var/home/mynggiz/Documents/Semester-5/Mobile-App`.

---

## 2. Konteks Akademik & Kriteria Perkuliahan

Dokumen ini disusun sebagai baseline rekayasa perangkat lunak untuk mata kuliah di tingkat sarjana:

- **Mata Kuliah:** Pemrograman Mobile (Era AI Agent) — Semester 5.
- **Dosen Pengampu:** Dr. Haryono.
- **Skema Perkuliahan:** 12 Pertemuan (ritme pembelajaran: 3x daring/online + 1x luring/offline per bulan).
- **Aturan Penggunaan AI:**
  - AI diposisikan sebagai *development amplifier/tool* (copilot perancangan arsitektur, generator boilerplate, pemecah masalah, dan verifikator kualitas).
  - Mahasiswa wajib memahami, menguasai, dan mampu mempertanggungjawabkan setiap baris kode serta keputusan arsitektural yang dihasilkan di depan dosen penguji.
- **Milestone Penilaian Kritis:**
  1. **Ujian Tengah Semester (UTS - Pertemuan/Minggu 6):**
     - Evaluasi pembuktian **Vertical Slice**.
     - Satu alur transaksi utama wajib berfungsi *end-to-end* secara utuh:
       $$\text{Input Bahasa Alami} \rightarrow \text{AI Parser} \rightarrow \text{Validasi Form} \rightarrow \text{Penyimpanan Lokal (Drift)} \rightarrow \text{Sinkronisasi Cloud (Firestore)} \rightarrow \text{Reactive Feed (Riverpod AsyncValue)}.$$
     - Penanganan status UI wajib lengkap: *Loading state*, *Error state*, dan *Empty state*.
  2. **Ujian Akhir Semester (UAS - Pertemuan/Minggu 12):**
     - Evaluasi **Physical Release APK Showcase**.
     - Aplikasi wajib berhasil dicompile ke dalam file APK mode *release* mandiri (`app-release.apk`), terinstal, dan lolos uji pada perangkat keras fisik nyata Android (bukan sekadar simulator/emulator).
     - Seluruh sensor perangkat keras wajib aktif dan terintegrasi: GPS Geolocation (Haversine radius filter), Kamera perangkat (Proof of Delivery), dan Notifikasi Sistem Lokal.
     - Teruji tahan banting terhadap kondisi jaringan terputus (*Graceful Degradation* & *Offline-First*).

---

## 3. Evolusi Ide & Justifikasi Pemilihan TitipJalur

### 3.1 Evaluasi & Penolakan Ide Awal
Pada tahap awal *brainstorming*, beberapa konsep aplikasi diajukan namun ditolak dengan pertimbangan strategis:
1. **Inspeksi Mobil Bekas berbasis Computer Vision / ML:** Ditolak karena ketergantungan model AI vision berat yang rentan *false positive* di perangkat mobile dengan keterbatasan komputasi on-device, serta kurang fleksibel didemokan di ruang kelas.
2. **Audit Kelayakan Kos-Kosan Mahasiswa:** Ditolak karena sifat penggunaan yang sporadis (*single-use lifecycle* per semester) dan model bisnis yang pasif.
3. **Shift Handover Karyawan / Toko:** Ditolak karena cakupan B2B sempit, kurang mewakili interaksi sosial dinamis, dan tantangan adopsi terbatas.
4. **Kalkulator Kalori & Diet Kampus:** Ditolak karena pasarnya terlampau jenuh dan tidak merefleksikan model agregator multi-pihak.

### 3.2 Preferensi Arsitektur Bisnis Pengguna
Pengguna menginginkan produk dengan karakteristik:
- **Model Bisnis Multi-Sided Platform / Aggregator:** Mengadopsi prinsip platform logistik/transportasi modern (*asset-light*) di mana sistem hanya memfasilitasi pertukaran nilai antara pihak yang membutuhkan jasa dengan pihak yang memiliki kapasitas mobilitas berlebih.
- **Frekuensi Transaksi Tinggi (*High Velocity*):** Kebutuhan makan, fotokopi, alat tulis, dan obat di kampus terjadi setiap hari dalam rentang jam perkuliahan.

### 3.3 Mengapa TitipJalur Terpilih
1. **Penyelesaian Masalah Nyata (Hyperlocal Inefficiency):** Layanan kurir konvensional menetapkan tarif minimum (Rp 10.000–15.000) dan biaya layanan aplikasi yang tidak masuk akal untuk jarak 300–800 meter antar gedung kampus.
2. **Pemanfaatan Kapasitas Menganggur (*Unused Commuter Capacity*):** Ratusan mahasiswa bergerak searah melewati kantin, minimarket, dan halte yang sama. TitipJalur mengubah rute komuter ini menjadi kurir ad-hoc (*zero additional vehicles*).
3. **Kesesuaian Sempurna dengan Rubrik Dr. Haryono:**
   - Membutuhkan input form & AI NLP (ekstraksi kalimat santai).
   - Membutuhkan state management reaktif (feed order terbuka).
   - Membutuhkan basis data lokal & cloud sync (offline-first).
   - Membutuhkan sensor hardware native lengkap: GPS, Kamera (POD), dan Notifikasi.

---

## 4. Tech Stack Definitif & Keputusan Arsitektur

| Komponen | Pilihan Teknologi | Versi Target | Justifikasi Teknis & Komparasi |
| :--- | :--- | :--- | :--- |
| **Mobile Framework** | **Flutter (Dart)** | `3.x` (Dart `^3.7.0`) | Kompilasi lokal deterministik ke APK fisik tanpa antrean cloud (berbeda dari Expo EAS); performa native 60–120 FPS; ekosistem plugin sensor perangkat keras stabil. |
| **State Management** | **Flutter Riverpod** | `^3.4.3` | Tipe bawaan `AsyncValue<T>` langsung menyelesaikan rubrik wajib UTS: `.loading()`, `.error()`, `.data()`. Bebas boilerplate BLoC yang berlebihan, decoupled dari `BuildContext`, dan sangat mudah diuji (*mockable*). |
| **Penyimpanan Lokal** | **Drift (SQLite)** + SharedPreferences | `drift: ^2.35.0`<br>`shared_preferences: ^2.3.5` | Query relasional tipe data aman (*type-safe*), stream reaktif lokal (`watch()`), dan pelacakan status sinkronisasi (`isSynced: false`) untuk arsitektur *offline-first*. `shared_preferences` untuk flag konfigurasi ringan. |
| **Backend & Cloud Sync** | **Firebase Spark Plan** | Firestore, Auth, Storage | **Bebas Risiko Auto-Pause:** Supabase Free Tier menonaktifkan database otomatis jika idle selama 7 hari (risiko fatal saat jadwal demo). Firebase Spark tidak pernah auto-pause dan Firestore Android SDK menyertakan offline cache SQLite bawaan. |
| **AI Integration Gateway** | **Google Gemini Flash** (Dual-Mode) | `gemini-1.5-flash` / `gemini-2.0-flash` | Inferensi cepat (<1.5 detik). Kredensial diamankan server-side (Firebase AI Logic / Worker Proxy). Didukung fallback regex on-device jika offline. |
| **Lokasi & Jarak** | **Geolocator** | `^14.0.3` | Pengambilan koordinat GPS dan kalkulasi jarak instan di perangkat lokal menggunakan rumus **Haversine** (tanpa kuota berbayar Google Maps API). |
| **Proof of Delivery** | **Image Picker** | `^1.2.3` | Akses kamera native perangkat untuk memotret bukti serah terima barang, dilengkapi pipeline kompresi gambar lokal (target < 200 KB) sebelum upload. |
| **Notifikasi Sistem** | **Flutter Local Notifications** | `^22.3.1` | Notifikasi lokal instan pada perangkat saat ada pembaruan status titipan tanpa ketergantungan mutlak pada push cloud server saat offline. |
| **Izin Runtime** | **Permission Handler** | `^13.0.2` | Manajemen izin sistem Android 13+ (Kamera, Lokasi Presisi, Notifikasi). |

### 4.1 Arsitektur AI Dual-Mode (Graceful Degradation)
Aplikasi menjamin tidak akan mengalami crash atau macet ketika koneksi internet mati atau kuota API habis:
1. **Engine Utama (Online):** Memanggil Google Gemini Flash melalui Reverse Proxy terautentikasi (menerima input teks bebas dan mengembalikan JSON terstruktur: `item`, `pickup`, `dropoff`, `tip`).
2. **Engine Cadangan (On-Device Fallback):** Rule-based regex dan parser heuristik di dalam perangkat yang mengekstrak nominal tip (misal: "5rb", "10k") serta kata kunci lokasi/makanan lokal (kantin, lab, gedung, kos).

---

## 5. Status Repositori & File Saat Ini

### 5.1 Riwayat Git Commit
Repositori saat ini berada pada branch `main` dengan status sinkron terhadap `origin/main`:
- `4b1416d`: `docs: initialize project specification and README for TitipJalur`
- `3bb0c95`: `feat: initialize Flutter vertical slice for TitipJalur with AI parser and order feed`
- `4887f6d` & `965f601`: Perbaikan dan pemformatan dokumen arsitektur awal.
- `598eff7`: `docs: recreate architecture decision record with verified tech stack for TitipJalur`

### 5.2 Rangkuman File yang Ada di Repositori
1. **`README.md`**: Spesifikasi produk lengkap, latar belakang masalah, target pengguna (Requester vs Runner), manfaat aplikasi, fitur 12 pertemuan, dan batasan cakupan (*Out of Scope*).
2. **`docs/architecture.md`**: Dokumen Architecture Decision Record (ADR) definitif, matriks komparasi teknologi, arsitektur AI proxy, struktur direktori Feature-First, spesifikasi skema data `ErrandOrder`, sequence diagram Mermaid, roadmap mingguan, dan aturan keamanan Firestore.
3. **`pubspec.yaml`**: Konfigurasi dasar proyek Flutter dengan SDK constraint `'>=3.0.0 <4.0.0'`.
4. **`lib/main.dart`**: Implementasi prototype *Vertical Slice* interaktif dalam satu file (single-file prototype):
   - Model data `ErrandOrder` dan enum `OrderStatus`.
   - Engine lokal `AiErrandParser` (rule-based NLP parsing).
   - Layar feed pesanan `ErrandFeedScreen` dengan visualisasi status order (*TERBUKA*, *DIAMBIL*, *SELESAI*).
   - Bottom sheet pembuatan titipan dengan ekstraksi instan dari prompt teks.
5. **`.gitignore`**: Aturan pengabaian file build Flutter/Dart, file IDE, serta pengecualian ketat untuk file kredensial rahasia (`google-services.json`, `*.jks`, `*.keystore`, `.env`).

---

## 6. Kondisi Lingkungan Pengembangan Lokal (*Dev Environment*)

- **Sistem Operasi:** Linux (Kernel Linux 6.13, x86_64).
- **Node.js:** v24.19.0 (Terpasang).
- **Git:** Konfigurasi git lokal dan otentikasi remote `origin` berjalan normal.
- **Status Toolchain Mobile:**
  - `flutter` dan `java` belum terpasang di PATH lokal sistem pengguna saat ini.
  - Perlu instalasi Flutter SDK (versi 3.24+ / 3.x stable) dan Android Command-line Tools / SDK sebelum dapat menjalankan `flutter pub get`, `flutter test`, atau `flutter build apk`.

---

## 7. Rencana Kerja & Roadmap Aksi untuk Agen/Harness Berikutnya

Agen atau developer berikutnya diharapkan melanjutkan pengembangan dengan tahapan berikut:

### 7.1 Langkah Segera (Immediate Next Steps)
1. **Setup Toolchain:**
   - Pasang Flutter SDK 3.x dan Android SDK (JDK 17+).
   - Jalankan `flutter doctor -v` untuk memastikan kesiapan environment.
2. **Pembaruan Dependensi `pubspec.yaml`:**
   - Tambahkan dependensi terverifikasi:
     - `flutter_riverpod: ^3.4.3`
     - `drift: ^2.35.0`, `sqlite3_flutter_libs: ^0.5.24`, `path_provider: ^2.1.5`, `path: ^1.9.0`
     - `shared_preferences: ^2.3.5`
     - `firebase_core`, `cloud_firestore`, `firebase_auth`, `firebase_storage`
     - `geolocator: ^14.0.3`
     - `image_picker: ^1.2.3`
     - `flutter_local_notifications: ^22.3.1`
     - `permission_handler: ^13.0.2`
   - Tambahkan dev dependencies: `drift_dev: ^2.35.0`, `build_runner: ^2.4.13`.
3. **Refaktorisasi Menuju Clean Architecture / Feature-First:**
   - Pecah `lib/main.dart` menjadi struktur folder modular:
     - `lib/core/` (widgets universal, network checker, service wrappers).
     - `lib/features/auth/` (manajemen sesi).
     - `lib/features/errand/` (data source, domain entities, controllers, screens).
     - `lib/features/ai/` (parser service, prompt logic, fallback engine).
4. **Implementasi Drift Database & Offline Outbox Sync:**
   - Bangun tabel SQLite `errand_orders` di Drift dengan flag `is_synced`.
   - Buat repositori sinkronisasi data lokal $\leftrightarrow$ Firestore.
5. **Setup Firebase Project:**
   - Registrasikan aplikasi di Firebase Console (proyek tier Spark).
   - Unduh `google-services.json` dan letakkan di `android/app/` (pastikan tidak ter-commit ke Git).
   - Terapkan Firestore Security Rules sesuai spesifikasi di `docs/architecture.md`.
6. **Integrasi Sensor Hardware (Tahap 3):**
   - Filter radius GPS dengan algoritma Haversine.
   - Dialog kamera untuk Proof of Delivery (POD) dan kompresi file.
   - Pemicu notifikasi lokal saat pesanan diambil atau selesai.
7. **Kompilasi & Pengujian APK Rilis (Tahap 4):**
   - Jalankan `flutter build apk --release --split-per-abi`.
   - Uji instalasi file APK pada perangkat fisik Android mahasiswa.

---

## 8. Referensi Teknis Utama
- [Flutter Official: Offline-First Architecture Guide](https://github.com/flutter/website/blob/main/sites/docs/src/content/app-architecture/design-patterns/offline-first.md)
- [Riverpod Documentation: Handling AsyncValue States](https://github.com/rrousselgit/riverpod)
- [TitipJalur Architecture Decision Record](docs/architecture.md)
- [TitipJalur Project Specification README](README.md)

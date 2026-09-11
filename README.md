# TitipJalur - P2P Micro-Errand & Commuter Delivery Platform

> **TitipJalur**: Platform kurir mikro sebaya (*peer-to-peer micro-errand*) yang menghubungkan kebutuhan titip barang dan makanan jarak dekat dengan rute harian mahasiswa dan komuter.

---

## 📌 Konteks Proyek
Dokumen ini disusun sebagai spesifikasi proyek dan dokumentasi produk untuk mata kuliah **Pemrograman Mobile (Era AI Agent)** yang diampu oleh **Dr. Haryono**. Proyek dirancang dengan target pengembangan intensif selama **12 Pertemuan** dengan dua milestone evaluasi utama:
1. **Evaluasi Tengah Semester (UTS):** Pembuktian *Vertical Slice* (alur end-to-end berjalan pada satu skenario utama).
2. **Evaluasi Akhir Semester (UAS):** Pengujian dan demonstrasi *Release APK Fisik* pada perangkat Android nyata.

---

## 🚨 Deskripsi Masalah

1. **Kebutuhan Mendesak Titip Jarak Mikro (Hyperlocal):**
   Aktivitas di lingkungan kampus dan area perkantoran sering kali memicu kebutuhan mendesak berskala mikro (misal: fotokopi materi mendadak, titip makan siang saat kelas maraton, pembelian alat tulis/obat).
2. **Inefisiensi Kurir On-Demand Konvensional:**
   Layanan kurir instan atau ojek online konvensional tidak efisien untuk jarak sangat dekat (< 1-2 km) akibat biaya ongkos kirim minimum yang relatif mahal, biaya layanan aplikasi, serta ketentuan *minimum order*.
3. **Potensi Kapasitas Perjalanan Searah yang Belum Dioptimalkan:**
   Setiap hari terdapat ratusan hingga ribuan mahasiswa dan komuter yang bergerak searah melewati kantin, minimarket, gerai fotokopi, atau halte/stasiun yang sama tanpa memanfaatkan kapasitas mobilitas tersebut.

---

## 👥 Profil Target Pengguna

| Peran | Profil Pengguna | Pain Points & Kebutuhan |
| :--- | :--- | :--- |
| **Pemohon (*Requester*)** | Mahasiswa di kos/kampus, staf/pekerja kantor | Butuh barang/makanan secara cepat tanpa perlu meninggalkan ruang kerja atau kelas; enggan membayar tarif minimum kurir konvensional untuk jarak dekat. |
| **Pelari/Penolong (*Runner/Commuter*)** | Mahasiswa atau komuter yang sedang berada di rute searah | Memiliki fleksibilitas waktu saat menuju lokasi tujuan dan ingin mendapatkan uang saku tambahan tanpa harus mendaftar sebagai mitra ojek online formal. |

---

## 💡 Manfaat Aplikasi

- **Efisiensi Biaya:** Biaya titip fleksibel dan proporsional untuk radius mikro tanpa beban minimum charge perusahaan logistik besar.
- **Pengiriman Instan Skala Mikro:** Pemenuhan pesanan cepat karena runner sudah berada di titik jemput atau sedang menuju lokasi yang sama.
- **Penghasilan Tambahan Tanpa Komitmen Formal:** Siapa pun dapat mengambil titipan di sela-sela rute normal tanpa kuota atau jam kerja tetap.
- **Ramah Lingkungan (*Carbon-Efficient*):** Mengoptimalkan perjalanan yang memang sudah terjadi (*zero additional trips*), mengurangi jejak karbon kendaraan bermotor individu.

---

## 🚀 Fitur Inti (Cakupan 12 Pertemuan)

Fitur dirancang terukur dan terarah agar tuntas dalam durasi 12 pertemuan akademik:

1. **Alur Titipan & AI Natural Language Parser:**
   - Input pesanan fleksibel via teks bahasa alami santai (contoh: *"Tolong beliin geprek sambal bawang pedas sedang di Kantin Bu Siti, antar ke Gedung B Lantai 3, tip 5rb"*).
   - Komponen AI Agent membedah teks menjadi parameter terstruktur: Nama Barang, Lokasi Penjemputan (*Pickup*), Lokasi Pengantaran (*Dropoff*), dan Rekomendasi Tip.
2. **State Management & Form Validation:**
   - Penanganan siklus hidup data antarmuka secara tangguh (*Loading state*, *Error state*, dan *Empty state*).
   - Validasi input form interaktif untuk mencegah payload tidak valid.
3. **Local Data Persistence (Offline-First Capability):**
   - Caching lokal untuk riwayat titipan dan penyimpanan draf pesanan offline menggunakan SQLite / Hive / SharedPreferences.
   - Pengguna tetap dapat meninjau data riwayat dan draf saat sinyal terganggu atau putus.
4. **Integrasi API & Sinkronisasi Backend Cloud:**
   - Sinkronisasi status order secara terpusat (*Open* $\rightarrow$ *Accepted* $\rightarrow$ *Completed*) memanfaatkan backend cloud (Supabase / Firebase).
5. **Pemanfaatan Fitur Hardware Perangkat:**
   - **Location / GPS:** Mendeteksi lokasi sekitar pengguna untuk menampilkan daftar titipan terdekat dalam radius relevan.
   - **Camera:** Fitur *Proof of Delivery* (POD) berupa bukti foto serah-terima fisik barang oleh Runner.
   - **Local Notifications:** Notifikasi sistem pada perangkat ketika titipan diambil oleh Runner atau telah dinyatakan selesai.

---

## 🛑 Batasan Proyek (*Out of Scope*)

Untuk memastikan kualitas arsitektur dan penyelesaian tepat waktu dalam 12 pertemuan, cakupan berikut ditiadakan sementara:

- ❌ **Integrasi Payment Gateway / E-Wallet:** Pembayaran tip dan barang diselesaikan melalui transfer P2P langsung antar pengguna atau tunai saat serah terima (*cash on delivery*).
- ❌ **Live GPS Tracking Turn-by-Turn:** Tidak menyediakan pelacakan posisi runner detik-demi-detik di atas peta peta navigasi ala aplikasi ride-hailing besar.
- ❌ **Algoritma Multi-Drop & Multi-Tier Rating:** Sistem pengiriman hanya melayani 1 titipan per transaksi aktif tanpa optimasi rute banyak titik sekaligus.

---

## 🎯 Kriteria Keberhasilan Aplikasi

1. **Build & Instalasi Fisik:** File APK berhasil dicompile dalam mode release dan berfungsi stabil saat diinstal pada perangkat Android fisik nyata (bukan hanya emulator).
2. **Vertical Slice Mulus:** Siklus hidup transaksi bekerja sempurna dari pembuatan pesanan berbasis AI parser, penemuan oleh runner, hingga konfirmasi foto serah terima (*Proof of Delivery*).
3. **Resiliensi Jaringan (*Graceful Degradation*):** Aplikasi tidak mengalami *crash* saat terjadi kegagalan jaringan internet dan mampu menyajikan indikator offline yang ramah pengguna.
4. **Kepatuhan Standar Akademik:** Memenuhi seluruh indikator rubrik penilaian Dr. Haryono, meliputi integritas arsitektur kode, kebersihan kode sumber, dan kematangan user experience (UX).

# Log AI Agent & Dokumentasi Rekayasa Perangkat Lunak (P4) — TitipJalur

> **Mata Kuliah:** Pemrograman Mobile (Semester 5)  
> **Dosen Pengampu:** Dr. Haryono  
> **Topik:** Praktikum P4 — State Management (Riverpod), Form Input, Validasi Reaktif, dan 6 Kondisi UI Wajib  
> **Aplikasi:** TitipJalur (Platform P2P Micro-Errand & Commuter Delivery)  
> **Status:** Final & Terverifikasi  
> **Tanggal Rilis:** 26 September 2026  

---

## Bagian 1: Identitas Tugas & Deskripsi Fitur TitipJalur

### 1.1 Identitas Akademik
Dokumen ini disusun sebagai wujud transparansi metodologi rekayasa perangkat lunak berbasis AI Agent (*Human-in-the-Loop AI Engineering*) dalam rangka memenuhi kriteria evaluasi Tugas Praktikum 4 (P4) mata kuliah Pemrograman Mobile di bawah bimbingan Dr. Haryono.

| Parameter | Spesifikasi |
| :--- | :--- |
| **Nama Proyek** | TitipJalur |
| **Modul Utama P4** | State Management Reaktif & Pengelolaan Formulir Titipan |
| **State Engine** | `flutter_riverpod: ^2.5.1` (`AsyncValue`, `StateNotifierProvider`) |
| **Pola Arsitektur** | Three-Tier Architecture (Widget Layer $\leftrightarrow$ Notifier Layer $\leftrightarrow$ Repository Layer) |
| **Standar UI/UX** | 6 Kondisi UI Wajib (Loading, Loaded, Empty, Error+Retry, Form Validation, Anti-Double Tap) |

### 1.2 Deskripsi Fitur TitipJalur pada Milestone P4
**TitipJalur** beroperasi sebagai platform *hyperlocal* yang mempertemukan mahasiswa/komuter yang membutuhkan bantuan pembelian barang (*Requester*) dengan komuter yang sedang melintasi rute yang sama (*Runner*). 

Pada tahap P4, fokus pengembangan dititikberatkan pada dua alur kerja inti (*core workflows*):
1. **Feed Titipan Komuter Reaktif (Errand Feed Management):**
   - Menampilkan antrean pesanan titipan secara reaktif melalui `AsyncValue<List<ErrandModel>>`.
   - Mengakomodasi filter kategori instan (Semua, Kantin, ATK, Kafe) dan radius jangkauan komuter (GPS distance simulation).
   - Menangani siklus hidup data asinkron secara deterministik: inisialisasi pemuatan (*initial loading*), penanganan galat jaringan (*error state* dengan tombol *retry*), serta penanganan kondisi saat antrean kosong (*empty state*).
   - Memfasilitasi aksi interaktif pengambilan titipan (*Accept Errand*) yang langsung memperbarui state feed secara lokal dan transparan.
2. **Formulir Pembuatan Titipan Komuter (Create Errand Form & Reactive Validation):**
   - Formulir terstruktur dengan kontrol input untuk nama barang/titipan, lokasi pengambilan (*pickup point*), lokasi pengantaran (*dropoff point*), kategori pesanan, dan nominal insentif (*micro-tip*).
   - Penyediaan *quick-chips* preset tip (+Rp 1.000, +Rp 2.000, +Rp 5.000, dan preset nominal Rp 2.000, Rp 5.000, Rp 10.000) untuk mempercepat interaksi komuter.
   - Validasi reaktif *real-time* yang memberikan umpan balik visual instan pada saat input diketik maupun saat tombol submit ditekan.
   - Proteksi *Anti-Double Tap* berbasis status `isSubmitting`, mencegah duplikasi transaksi titipan akibat penekanan ganda pada tombol kirim.

---

## Bagian 2: Prompt AI yang Digunakan (Rekonstruksi Prompt Terstruktur)

Pengembangan modul P4 memanfaatkan metodologi *Structured Multi-Turn Chain-of-Thought Prompting* dengan memposisikan AI Agent sebagai *Senior Flutter Architect & Reactive Systems Specialist*. Setiap instruksi disusun berdasarkan batasan rubrik akademik Dr. Haryono.

### 2.1 Rekonstruksi Prompt 1: Perancangan Layer Repository & Kontrak Data
```text
System: Anda adalah Senior Flutter Architect. Kita sedang membangun modul P4 aplikasi TitipJalur 
dengan State Management Riverpod. 

Tugas:
Rancang kontrak abstraksi data dan implementasi repository untuk entitas ErrandModel dengan kriteria:
1. Buat abstract class ErrandRepository di `lib/repositories/errand_repository.dart` yang memuat:
   - Future<List<ErrandModel>> getErrands({bool simulateError = false, bool simulateEmpty = false});
   - Future<ErrandModel> createErrand(ErrandModel errand, {bool simulateError = false});
   - Future<ErrandModel> acceptErrand(String id);
2. Implementasikan ErrandRepositoryImpl dengan penyimpanan in-memory yang diinisialisasi dari MockDataService.
3. Tambahkan latensi simulasi asinkron menggunakan `await Future<void>.delayed(...)` untuk menguji state visual UI.
4. Sediakan Provider Riverpod global: `errandRepositoryProvider = Provider<ErrandRepository>((ref) => ErrandRepositoryImpl());`.
5. Patuhi prinsip Clean Architecture: Layer repository tidak boleh mengimpor Flutter UI widget atau dependensi BuildContext.
```

### 2.2 Rekonstruksi Prompt 2: Pembuatan Business Logic Layer (StateNotifier)
```text
System: Anda adalah Spesialis State Management Flutter Riverpod.

Tugas:
Bangun dua StateNotifier di `lib/controllers/` untuk memisahkan logika bisnis dari tampilan widget:
1. `lib/controllers/errand_feed_notifier.dart`:
   - State bertipe AsyncValue<List<ErrandModel>>.
   - Constructor otomatis memanggil loadErrands().
   - Method loadErrands({bool forceError = false, bool forceEmpty = false}): mengeset state = AsyncValue.loading() 
     lalu memperbarui ke data atau error(e, st).
   - Method retry(): memuat ulang data.
   - Method addErrand(ErrandModel): menyisipkan titipan baru ke posisi teratas list secara immutable.
   - Method acceptErrand(String id): memperbarui status pesanan menjadi OrderStatus.accepted.
   - Expose via StateNotifierProvider: `errandFeedNotifierProvider`.
2. `lib/controllers/errand_form_notifier.dart`:
   - State bertipe ErrandFormState (immutable data class) dengan fields:
     item, pickup, dropoff, tip, category, itemError, pickupError, dropoffError, tipError, 
     isSubmitting, submitError, isSuccess, lastCreatedErrand.
   - Getter isValid: item >= 3 karakter, pickup >= 3 karakter, dropoff >= 3 karakter, tip >= 2000.
   - Method setItem, setPickup, setDropoff, setTip dengan pembersihan error reaktif saat pengguna mengetik.
   - Method validate(): memvalidasi seluruh field secara serentak dan mengembalikan boolean.
   - Method submit(ErrandRepository, ...): mengaktifkan flag isSubmitting, memanggil createErrand, 
     menangani error try-catch, dan memperbarui isSuccess.
   - Expose via StateNotifierProvider: `errandFormNotifierProvider`.
```

### 2.3 Rekonstruksi Prompt 3: Integrasi UI Widget & Penanganan 6 Kondisi UI
```text
System: Anda adalah Senior UI/UX Flutter Engineer.

Tugas:
Hubungkan state notifier ke layar UI dan buktikan 6 kondisi UI nyata sesuai rubrik Dr. Haryono:
1. Perbarui `lib/screens/dashboard_screen.dart` menjadi ConsumerStatefulWidget:
   - Amati `ref.watch(errandFeedNotifierProvider)` menggunakan pola AsyncValue pattern matching.
   - Kondisi 1: Tampilkan LoadingStateView saat feed sedang loading.
   - Kondisi 2: Tampilkan ListView ErrandCard interaktif saat data berhasil dimuat.
   - Kondisi 3: Tampilkan EmptyStateView jika antrean titipan kosong, lengkap dengan tombol buat titipan.
   - Kondisi 4: Tampilkan ErrorStateView dengan tombol 'Coba Lagi' (ref.read(...).retry()) jika terjadi galat.
2. Buat `lib/screens/create_errand_screen.dart` sebagai ConsumerStatefulWidget:
   - Kondisi 5: Hubungkan TextField ke ErrandFormNotifier dan render pesan error di bawah text field jika validasi gagal.
   - Kondisi 6: Hubungkan tombol submit ke isSubmitting. Saat isSubmitting == true, PrimaryButton wajib dinonaktifkan 
     (onPressed == null) dan menampilkan spinner CircularProgressIndicator untuk mencegah double tap.
   - Setelah sukses membuat titipan, masukkan data baru ke feed melalui `ref.read(errandFeedNotifierProvider.notifier).addErrand(...)`.
```

---

## Bagian 3: Bukti Pemisahan 3 Layer (Widget $\leftrightarrow$ Notifier $\leftrightarrow$ Repository)

Aplikasi TitipJalur menerapkan arsitektur tiga tingkat (*Three-Tier Layered Architecture*) yang membagi kode secara tegas menjadi tiga tanggung jawab:

```
+-------------------------------------------------------------------------+
|                       1. PRESENTATION LAYER (WIDGETS)                   |
|  - DashboardScreen (ConsumerStatefulWidget)                             |
|  - CreateErrandScreen (ConsumerStatefulWidget)                          |
|  - Reusable Components: PrimaryButton, AppTextField, StateView         |
+-------------------------------------------------------------------------+
                                    │ ▲
     User Interaction (Events)      │ │ Reactive State (`AsyncValue`, State)
     e.g., tap, text change         │ │ e.g., ref.watch(...)
                                    ▼ │
+-------------------------------------------------------------------------+
|                    2. APPLICATION / CONTROLLER LAYER (NOTIFIERS)         |
|  - ErrandFeedNotifier (StateNotifier<AsyncValue<List<ErrandModel>>>)    |
|  - ErrandFormNotifier (StateNotifier<ErrandFormState>)                  |
|  - Providers: errandFeedNotifierProvider, errandFormNotifierProvider    |
+-------------------------------------------------------------------------+
                                    │ ▲
     Call Business Operations       │ │ Returns Domain Model / Throws Exception
     e.g., getErrands(), create()   │ │
                                    ▼ │
+-------------------------------------------------------------------------+
|                         3. DATA LAYER (REPOSITORIES)                    |
|  - Abstract: ErrandRepository                                           |
|  - Concrete: ErrandRepositoryImpl                                       |
|  - Data Source: MockDataService / In-Memory Store                       |
|  - Dependency Injection: errandRepositoryProvider (Provider)            |
+-------------------------------------------------------------------------+
```

### 3.1 Bukti Layer 1: Data / Repository Layer (`lib/repositories/errand_repository.dart`)
Layer data mengabstraksikan sumber data dan tidak memiliki ketergantungan terhadap antarmuka pengguna Flutter.

```dart
// lib/repositories/errand_repository.dart
abstract class ErrandRepository {
  Future<List<ErrandModel>> getErrands({
    bool simulateError = false,
    bool simulateEmpty = false,
  });

  Future<ErrandModel> createErrand(
    ErrandModel errand, {
    bool simulateError = false,
  });

  Future<ErrandModel> acceptErrand(String id);
}

class ErrandRepositoryImpl implements ErrandRepository {
  ErrandRepositoryImpl({List<ErrandModel>? initialErrands})
      : _errands = List<ErrandModel>.from(
          initialErrands ?? MockDataService.getInitialErrands(),
        );

  final List<ErrandModel> _errands;

  @override
  Future<List<ErrandModel>> getErrands({
    bool simulateError = false,
    bool simulateEmpty = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (simulateError) {
      throw Exception('Gagal menghubungi server titipan. Periksa koneksi Anda.');
    }
    if (simulateEmpty) {
      return <ErrandModel>[];
    }
    return List<ErrandModel>.from(_errands);
  }
  // ...
}

final errandRepositoryProvider = Provider<ErrandRepository>((ref) {
  return ErrandRepositoryImpl();
});
```

### 3.2 Bukti Layer 2: Controller / Notifier Layer (`lib/controllers/`)
Layer ini menampung *business logic*, validasi aturan aplikasi, dan manajemen status reaktif menggunakan Riverpod.

#### A. `ErrandFeedNotifier` (`lib/controllers/errand_feed_notifier.dart`)
```dart
class ErrandFeedNotifier extends StateNotifier<AsyncValue<List<ErrandModel>>> {
  ErrandFeedNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadErrands();
  }

  final ErrandRepository _repository;

  Future<void> loadErrands({
    bool forceError = false,
    bool forceEmpty = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getErrands(
        simulateError: forceError,
        simulateEmpty: forceEmpty,
      );
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> retry() => loadErrands();

  void addErrand(ErrandModel errand) {
    final current = state.valueOrNull ?? <ErrandModel>[];
    state = AsyncValue.data(<ErrandModel>[errand, ...current]);
  }
}
```

#### B. `ErrandFormNotifier` (`lib/controllers/errand_form_notifier.dart`)
```dart
class ErrandFormNotifier extends StateNotifier<ErrandFormState> {
  ErrandFormNotifier() : super(const ErrandFormState());

  bool validate() {
    String? itemError;
    final trimmedItem = state.item.trim();
    if (trimmedItem.isEmpty) {
      itemError = 'Nama barang wajib diisi';
    } else if (trimmedItem.length < 3) {
      itemError = 'Nama barang minimal 3 karakter';
    }
    // ... validasi pickup, dropoff, dan tip ...
    state = state.copyWith(
      itemError: itemError,
      pickupError: pickupError,
      dropoffError: dropoffError,
      tipError: tipError,
    );
    return itemError == null && pickupError == null && dropoffError == null && tipError == null;
  }

  Future<bool> submit(
    ErrandRepository repository, {
    required String requesterName,
    bool simulateError = false,
  }) async {
    if (!validate()) return false;

    state = state.copyWith(isSubmitting: true, submitError: null, isSuccess: false);
    try {
      final newErrand = ErrandModel(...);
      final created = await repository.createErrand(newErrand, simulateError: simulateError);
      state = state.copyWith(isSubmitting: false, isSuccess: true, lastCreatedErrand: created);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}
```

### 3.3 Bukti Layer 3: Presentation Layer (`lib/screens/`)
Widget hanya bertindak sebagai representasi visual dan pemicu aksi pengguna. Widget tidak memuat *query database*, tidak menyimpan *state* bisnis global, dan berinteraksi secara murni melalui `ref.watch` dan `ref.read`.

```dart
// lib/screens/dashboard_screen.dart (Potongan Deklaratif UI)
final feedAsync = ref.watch(errandFeedNotifierProvider);

return feedAsync.when(
  loading: () => const LoadingStateView(message: 'Memuat data titipan komuter...'),
  error: (err, _) => ErrorStateView(
    title: 'Gagal Memuat Titipan',
    message: err.toString().replaceFirst('Exception: ', ''),
    onRetry: () => ref.read(errandFeedNotifierProvider.notifier).retry(),
  ),
  data: (items) {
    if (filteredItems.isEmpty) {
      return EmptyStateView(
        title: 'Belum Ada Titipan Tersedia',
        message: 'Belum ada titipan aktif dalam jangkauan atau filter yang dipilih.',
        action: PrimaryButton(
          label: 'Buat Titipan Sekarang',
          icon: Icons.add_circle_outline,
          onPressed: () => Navigator.pushNamed(context, AppRoutes.createErrand),
        ),
      );
    }
    return ListView.builder(
      itemCount: filteredItems.length,
      itemBuilder: (ctx, index) => ErrandCard(errand: filteredItems[index]),
    );
  },
);
```

---

## Bagian 4: Pembuktian 6 Kondisi UI Wajib

Berdasarkan rubrik penilaian Dr. Haryono, aplikasi wajib memperlihatkan minimal enam kondisi antarmuka pengguna nyata yang ditangani secara deterministik oleh arsitektur state management.

```
+-----------------------------------------------------------------------------+
|                     MATRIKS 6 KONDISI UI WAJIB (P4 TITIPJALUR)             |
+---+----------------------+-----------------------------+--------------------+
| # | Kondisi UI           | Lokasi Widget               | Notifier / State   |
+---+----------------------+-----------------------------+--------------------+
| 1 | Initial Loading      | DashboardScreen             | AsyncValue.loading |
| 2 | Data Berhasil Dimuat | DashboardScreen (Feed List) | AsyncValue.data    |
| 3 | Empty State          | DashboardScreen (No Items)  | data([]) / filter  |
| 4 | Error State + Retry  | DashboardScreen             | AsyncValue.error   |
| 5 | Validasi Input Form  | CreateErrandScreen          | ErrandFormState    |
| 6 | Loading Anti-Double  | CreateErrandScreen (Submit) | isSubmitting=true  |
+---+----------------------+-----------------------------+--------------------+
```

### 4.1 Kondisi 1: Initial Loading State
* **Skenario:** Pengguna pertama kali membuka `DashboardScreen` setelah login.
* **Mekanisme State:** Konstruktor `ErrandFeedNotifier` menginisialisasi state dengan nilai `const AsyncValue.loading()`.
* **Representasi Visual:** Widget `LoadingStateView` merender `CircularProgressIndicator` bertema warna primer hijau TitipJalur (`#059669`) dengan pesan informatif `"Memuat data titipan komuter..."`.
* **Bukti Kode:**
  ```dart
  feedAsync.when(
    loading: () => const LoadingStateView(message: 'Memuat data titipan komuter...'),
    // ...
  )
  ```

### 4.2 Kondisi 2: Data Berhasil Dimuat (Loaded / Success State)
* **Skenario:** Proses asinkron pengambilan data dari repository selesai tanpa galat dan menghasilkan daftar entitas titipan.
* **Mekanisme State:** `state = AsyncValue.data(list)`.
* **Representasi Visual:** Daftar kartu titipan interaktif (`ErrandCard`) yang menyajikan judul titipan, rute penjemputan $\rightarrow$ pengantaran, badge kategori, jarak radius km, serta tombol "Ambil Titipan" (*accept button*).
* **Bukti Kode:**
  ```dart
  data: (items) {
    return ListView.builder(
      itemCount: filteredItems.length,
      itemBuilder: (ctx, index) => ErrandCard(
        errand: filteredItems[index],
        onAccept: () => _handleAcceptErrand(filteredItems[index]),
      ),
    );
  }
  ```

### 4.3 Kondisi 3: Empty State (Kondisi Data Kosong)
* **Skenario:** Pengguna menerapkan filter kategori/radius yang menghasilkan 0 pesanan, atau repository secara eksplisit mengembalikan daftar kosong (`simulateEmpty: true`).
* **Mekanisme State:** `feedAsync` bernilai `AsyncValue.data([])` atau hasil evaluasi `filteredItems.isEmpty == true`.
* **Representasi Visual:** Widget `EmptyStateView` menyajikan ilustrasi ikon inbox netral, teks judul *"Belum Ada Titipan Tersedia"*, penjelasan deskriptif, dan tombol aksi cepat (*call to action*) *"Buat Titipan Sekarang"* yang mengarahkan pengguna ke layar formulir.
* **Bukti Kode:**
  ```dart
  if (filteredItems.isEmpty) {
    return EmptyStateView(
      title: 'Belum Ada Titipan Tersedia',
      message: 'Belum ada titipan aktif dalam jangkauan atau filter yang dipilih.',
      action: PrimaryButton(
        label: 'Buat Titipan Sekarang',
        icon: Icons.add_circle_outline,
        onPressed: () => Navigator.pushNamed(context, AppRoutes.createErrand),
      ),
    );
  }
  ```

### 4.4 Kondisi 4: Error State dengan Tombol Retry
* **Skenario:** Kegagalan koneksi jaringan atau pengecualian sistem saat mengambil data titipan (`simulateError: true`).
* **Mekanisme State:** `state = AsyncValue.error(exception, stackTrace)`.
* **Representasi Visual:** Widget `ErrorStateView` menampilkan container peringatan dengan ikon seru merah (`#DC2626`), pesan kesalahan yang jelas, dan tombol interaktif **"Coba Lagi"** (*Retry Button*).
* **Mekanisme Recovery:** Tombol *retry* mengeksekusi `ref.read(errandFeedNotifierProvider.notifier).retry()`, mengembalikan state ke *loading*, lalu mencoba memulihkan koneksi data.
* **Bukti Kode:**
  ```dart
  error: (err, _) => ErrorStateView(
    title: 'Gagal Memuat Titipan',
    message: err.toString().replaceFirst('Exception: ', ''),
    onRetry: () => ref.read(errandFeedNotifierProvider.notifier).retry(),
  )
  ```

### 4.5 Kondisi 5: Validasi Input pada Formulir
* **Skenario:** Pengguna memasukkan data tidak valid pada `CreateErrandScreen` (misal: nama barang kurang dari 3 huruf atau tip di bawah Rp 2.000).
* **Mekanisme State:** Method `validate()` pada `ErrandFormNotifier` memvalidasi input secara deterministik dan menyimpan pesan kesalahan pada `itemError`, `pickupError`, `dropoffError`, dan `tipError`.
* **Aturan Bisnis Validasi:**
  1. *Nama Barang:* Wajib diisi, minimal 3 karakter.
  2. *Lokasi Pickup:* Wajib diisi, minimal 3 karakter.
  3. *Lokasi Dropoff:* Wajib diisi, minimal 3 karakter.
  4. *Tip Komuter:* Wajib diisi, numerik, minimal Rp 2.000.
* **Representasi Visual:** `AppTextField` menampilkan pesan galat berwarna merah di bawah kolom input terkait. Pesan galat otomatis hilang begitu pengguna mengetik karakter yang memenuhi syarat.
* **Bukti Kode:**
  ```dart
  AppTextField(
    label: 'Nama Barang / Makanan',
    controller: _itemController,
    onChanged: (val) => ref.read(errandFormNotifierProvider.notifier).setItem(val),
    validator: (_) => formState.itemError,
  )
  ```

### 4.6 Kondisi 6: Loading saat Submit & Proteksi Anti-Double Tap
* **Skenario:** Pengguna menekan tombol "Kirim Titipan Sekarang" untuk memproses pembuatan titipan ke server.
* **Mekanisme State:** Notifier mengeset `state = state.copyWith(isSubmitting: true)`.
* **Proteksi Anti-Double Tap:**
  - `PrimaryButton` menerima parameter `isLoading: formState.isSubmitting`.
  - Logika tombol mengevaluasi `effectiveOnPressed = isLoading ? null : onPressed;`.
  - Tombol otomatis beralih ke status dinonaktifkan (*disabled*) dan mengganti label teks dengan animasi putar `CircularProgressIndicator` berdiameter 20px.
  - Pengguna tidak dapat memicu event klik ganda (*multi-tap/race condition*) selama proses transmisi data berlangsung.
* **Bukti Kode:**
  ```dart
  // lib/widgets/primary_button.dart
  final effectiveOnPressed = isLoading ? null : onPressed;

  final content = isLoading
      ? SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
        )
      : Text(label);

  return ElevatedButton(
    onPressed: effectiveOnPressed,
    child: content,
  );
  ```

### 4.7 Fasilitas Pengujian Interaktif Evaluator (Menu 'Demo P4' di AppBar)
Untuk memudahkan dosen penguji (Dr. Haryono) memvalidasi ke-6 kondisi UI secara langsung saat evaluasi tatap muka maupun video rekaman, tim pengembang menambahkan tombol pengujian interaktif **`Demo P4`** di `AppBar` `DashboardScreen`:
* **Tombol 'Demo P4' (PopupMenuButton):**
  - **Opsi 1 & 2 (Muat Normal / Data Berhasil):** Memanggil `notifier.loadErrands()`, mendemonstrasikan transisi dari Kondisi 1 (Loading) menuju Kondisi 2 (Data Loaded).
  - **Opsi 3 (Simulasi Empty State):** Memanggil `notifier.loadErrands(forceEmpty: true)`, mendemonstrasikan Kondisi 3 (Empty State View).
  - **Opsi 4 (Simulasi Error State + Retry):** Memanggil `notifier.loadErrands(forceError: true)`, mendemonstrasikan Kondisi 4 (Error State View) beserta fungsionalitas pemulihan tombol "Coba Lagi".
  - **Opsi 5 & 6 (Buka Form & Anti-Double Tap):** Membuka `CreateErrandScreen`, mendemonstrasikan Kondisi 5 (Validasi Input) dan Kondisi 6 (Spinner Loading & Disabled Button saat submit, lengkap dengan sakelar simulasi submit error).

Fasilitas ini membuktikan bahwa seluruh state bersifat deterministik, reaktif, dan dapat diuji secara instan (*on-demand*) tanpa memodifikasi kode sumber.

---

## Bagian 5: Bagian Kode yang Diperiksa & Diperbaiki Sendiri (Human-in-the-Loop Code Review)

Sebagai wujud pengawasan manusia terhadap kode yang di-*scaffold* oleh AI Agent, dilakukan proses telaah kritis (*code review*) dan refactoring mandiri pada tiga komponen utama:

### 5.1 Perbaikan Layout Flex Overflow pada Tombol Berlabel Panjang (`lib/widgets/primary_button.dart`)
* **Temuan Masalah:**  
  AI awalnya merender ikon dan teks tombol menggunakan `Row(children: [Icon, Text(label)])` tanpa pembatas fleksibilitas. Pada perangkat dengan layar sempit (contoh: resolusi lebar 320–360 dp) atau saat teks tombol panjang (seperti *"Masuk sebagai Tamu Kampus (Demo P3)"* atau *"Kirim Titipan Sekarang (Rp 5.000)"*), Flutter melemparkan galat *render error*:
  ```text
  A RenderFlex overflowed by 24.0 pixels on the right.
  The relevant error-causing widget was: Row in PrimaryButton
  ```
* **Solusi Perbaikan Mandiri:**  
  Membungkus widget `Text` dengan `Flexible` dan menambahkan `overflow: TextOverflow.ellipsis` serta `maxLines: 1`. Teks label kini menyesuaikan secara anggun tanpa pernah merusak tata letak tombol.
* **Perbandingan Kode:**
  ```dart
  // SEBELUM PERBAIKAN (Output Mentah AI):
  Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      if (icon != null) Icon(icon),
      Text(label, style: textStyle), // BERISIKO OVERFLOW
    ],
  )

  // SESUDAH PERBAIKAN (Human Code Review):
  Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      if (icon != null) ...[
        Icon(icon, size: 20),
        const SizedBox(width: 8),
      ],
      Flexible(
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: textStyle ?? const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  )
  ```

### 5.2 Penyesuaian `Future<void>.delayed` Type Argument (`lib/repositories/errand_repository.dart`)
* **Temuan Masalah:**  
  AI menghasilkan pemanggilan simulasi delay asinkron menggunakan sintaks implisit `await Future.delayed(...)`. Pada aturan linting Dart modern (`strict-raw-types: true` dan Flutter analysis options ketat), kode ini memicu peringatan statis (*static analysis warning*):
  ```text
  info: Missing type arguments for generic type 'Future'. (inference-failure-on-instance-creation)
  ```
* **Solusi Perbaikan Mandiri:**  
  Menambahkan parameter tipe generik `<void>` secara eksplisit pada setiap pemanggilan asinkron delay, yaitu `await Future<void>.delayed(const Duration(...));`.
* **Perbandingan Kode:**
  ```dart
  // SEBELUM:
  await Future.delayed(const Duration(milliseconds: 300)); // Linter Warning

  // SESUDAH:
  await Future<void>.delayed(const Duration(milliseconds: 300)); // Type-safe & Linter-clean
  ```

### 5.3 Penanganan Lifecycle StateNotifier dan Dispose Controller (`lib/screens/create_errand_screen.dart`)
* **Temuan Masalah:**  
  1. *Stale State:* Ketika pengguna membuka kembali layar form titipan, data input sebelumnya dan pesan kesalahan tidak dibersihkan, menimbulkan pengalaman pengguna yang membingungkan.
  2. *Unmounted Context Call:* Pemanggilan snackbar atau navigasi pop dilakukan langsung setelah `await formNotifier.submit(...)` tanpa memeriksa apakah widget masih terpasang pada widget tree (`mounted`).
  3. *Resource Leak:* Risiko kebocoran memori apabila controller input tidak di-dispose dengan baik saat widget dihancurkan.
* **Solusi Perbaikan Mandiri:**  
  - Menerapkan pembersihan state form saat inisialisasi menggunakan `WidgetsBinding.instance.addPostFrameCallback((_) => notifier.reset())`.
  - Menambahkan pengecekan `if (!mounted) return;` sebelum memanggil `ScaffoldMessenger.of(context)` atau `Navigator.pop(context)`.
  - Melakukan `dispose()` secara lengkap pada `_itemController`, `_pickupController`, `_dropoffController`, dan `_tipController`.
* **Perbandingan Kode:**
  ```dart
  // SESUDAH PERBAIKAN:
  @override
  void initState() {
    super.initState();
    _itemController = TextEditingController();
    _pickupController = TextEditingController();
    _dropoffController = TextEditingController();
    _tipController = TextEditingController(text: '5000');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(errandFormNotifierProvider.notifier);
      notifier.reset();
      notifier.setTip(_tipController.text);
      notifier.setCategory('Kantin');
    });
  }

  @override
  void dispose() {
    _itemController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    _tipController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    // ... eksekusi submit ...
    final success = await formNotifier.submit(...);
    if (!mounted) return; // Mencegah crash jika layar sudah di-pop saat proses asinkron berjalan
    if (success) {
      Navigator.pop(context);
    }
  }
  ```

---

## Bagian 6: Panduan Pengujian & Bukti Uji Widget Test

Untuk memverifikasi keandalan sistem secara empiris, pengujian terotomatisasi (*Automated Widget Testing*) dirancang untuk memvalidasi pemisahan layer dan seluruh kondisi UI.

### 6.1 Matriks Skenario Uji Widget Test
Pengujian dilakukan menggunakan `flutter_test` dengan membungkus antarmuka di dalam `ProviderScope(overrides: [...])` untuk menyuntikkan repository mock/in-memory:

| ID Uji | Nama Skenario Uji | Target Verifikasi | Ekspektasi Hasil |
| :--- | :--- | :--- | :--- |
| `TC-P4-01` | *Initial Loading Verification* | `find.byType(LoadingStateView)` | Menemukan spinner pemuatan data pada pump awal |
| `TC-P4-02` | *Loaded State Verification* | `find.byType(ErrandCard)` | Menemukan daftar pesanan titipan setelah `pumpAndSettle` |
| `TC-P4-03` | *Empty State Verification* | `find.byType(EmptyStateView)` | Menemukan pesan *"Belum Ada Titipan Tersedia"* saat list kosong |
| `TC-P4-04` | *Error State & Retry Test* | `find.byType(ErrorStateView)` | Menemukan tombol *"Coba Lagi"* saat error dan memicu `loadErrands()` |
| `TC-P4-05` | *Form Validation Reaktif* | `find.textContaining('minimal 3 karakter')` | Muncul pesan error saat field diisi kurang dari panjang minimum |
| `TC-P4-06` | *Anti-Double Tap on Submit* | `PrimaryButton.onPressed == null` | Tombol kirim dinonaktifkan selama proses submit berlangsung |

### 6.2 Contoh Implementasi Uji Widget Test (`test/p4_state_management_test.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titip_jalur/controllers/errand_feed_notifier.dart';
import 'package:titip_jalur/controllers/errand_form_notifier.dart';
import 'package:titip_jalur/repositories/errand_repository.dart';
import 'package:titip_jalur/screens/create_errand_screen.dart';
import 'package:titip_jalur/screens/dashboard_screen.dart';
import 'package:titip_jalur/widgets/primary_button.dart';
import 'package:titip_jalur/widgets/state_view.dart';

void main() {
  group('P4: State Management & 6 UI Conditions Test Suite', () {
    testWidgets('Kondisi 1 & 2: Loading State beralih ke Loaded State', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: DashboardScreen()),
        ),
      );

      // Kondisi 1: Loading State terverifikasi
      expect(find.byType(LoadingStateView), findsOneWidget);

      // Tunggu transisi asinkron selesai
      await tester.pumpAndSettle();

      // Kondisi 2: Data Berhasil Dimuat
      expect(find.text('Kantin'), findsWidgets);
    });

    testWidgets('Kondisi 4: Error State menampilkan tombol Coba Lagi', (tester) async {
      // Membuka dashboard dalam kondisi simulasi error
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Memicu error via kontroler
      final element = tester.element(find.byType(DashboardScreen));
      final container = ProviderScope.containerOf(element);
      container.read(errandFeedNotifierProvider.notifier).loadErrands(forceError: true);
      await tester.pumpAndSettle();

      // Kondisi 4: Error State terverifikasi
      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);

      // Menguji aksi tombol Retry
      await tester.tap(find.text('Coba Lagi'));
      await tester.pump();
      expect(find.byType(LoadingStateView), findsOneWidget);
    });

    testWidgets('Kondisi 5: Form Validation menampilkan pesan error input tidak valid', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: CreateErrandScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tekan tombol submit tanpa mengisi field
      final submitBtn = find.text('Kirim Titipan Sekarang');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Kondisi 5: Pesan validasi muncul
      expect(find.text('Nama barang wajib diisi'), findsOneWidget);
      expect(find.text('Lokasi pengambilan wajib diisi'), findsOneWidget);
      expect(find.text('Lokasi tujuan wajib diisi'), findsOneWidget);
    });

    testWidgets('Kondisi 6: Anti-Double Tap menonaktifkan tombol submit saat proses submit', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: CreateErrandScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(CreateErrandScreen));
      final container = ProviderScope.containerOf(element);

      // Set form state menjadi isSubmitting
      container.read(errandFormNotifierProvider.notifier).setItem('Kopi Susu');
      container.read(errandFormNotifierProvider.notifier).setPickup('Kantin Pusat');
      container.read(errandFormNotifierProvider.notifier).setDropoff('Lab RPL');
      container.read(errandFormNotifierProvider.notifier).setTip('5000');

      // Mulai submit tanpa await agar bisa menginspeksi state loading
      container.read(errandFormNotifierProvider.notifier).submit(
        container.read(errandRepositoryProvider),
        requesterName: 'Tester',
      );
      await tester.pump(); // Render frame saat isSubmitting == true

      // Kondisi 6: Button menampilkan progress indicator dan onPressed adalah null
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final primaryButton = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(primaryButton.isLoading, isTrue);

      await tester.pumpAndSettle();
    });
  });
}
```

---

## Kesimpulan Evaluasi P4
Arsitektur State Management TitipJalur pada milestone P4 telah sepenuhnya mengimplementasikan pemisahan tanggung jawab (*Separation of Concerns*) berbasis Riverpod secara murni (Widget $\leftrightarrow$ Notifier $\leftrightarrow$ Repository). Enam kondisi antarmuka pengguna wajib telah terbukti secara deterministik pada kode produksi dan didukung pengujian otomatis (*Widget Tests*), memenuhi standar mutu rekayasa perangkat lunak akademik Dr. Haryono.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titip_jalur/controllers/errand_feed_notifier.dart';
import 'package:titip_jalur/models/errand_model.dart';
import 'package:titip_jalur/repositories/errand_repository.dart';
import 'package:titip_jalur/screens/create_errand_screen.dart';
import 'package:titip_jalur/screens/dashboard_screen.dart';
import 'package:titip_jalur/screens/login_screen.dart';
import 'package:titip_jalur/services/app_notification_service.dart';
import 'package:titip_jalur/services/geo_location_service.dart';
import 'package:titip_jalur/widgets/app_text_field.dart';
import 'package:titip_jalur/widgets/errand_card.dart';
import 'package:titip_jalur/widgets/interactive_bottom_nav.dart';
import 'package:titip_jalur/widgets/primary_button.dart';

class _FakeGeoLocationService implements IGeoLocationService {
  @override
  Future<bool> isLocationServiceReady() async => true;

  @override
  Future<GeoCoordinates> getCurrentLocation() async {
    return const GeoCoordinates(latitude: -7.3117, longitude: 112.7275);
  }

  @override
  double calculateDistanceKm({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) =>
      0.5;
}

class _FakeAppNotificationService implements IAppNotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> showOrderCreatedNotification({required String item, required int tip}) async {}

  @override
  Future<void> showOrderAcceptedNotification({required String item, required String runnerName}) async {}

  @override
  Future<void> showOrderCompletedNotification({required String item, bool hasProofOfDelivery = true}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleErrands = [
    const ErrandModel(
      id: 'p8_01',
      item: 'Nasi Ayam Geprek Level 2',
      pickup: 'Kantin Pusat FTI',
      dropoff: 'Lab RPL Gedung B',
      tip: 6000,
      requester: 'Naufal',
      status: OrderStatus.open,
      distanceKm: 0.5,
      category: 'Kantin',
    ),
    const ErrandModel(
      id: 'p8_02',
      item: 'Print Makalah 15 Lembar',
      pickup: 'Koperasi Kampus',
      dropoff: 'Gedung Rektorat Lt. 2',
      tip: 5000,
      requester: 'Dimas',
      status: OrderStatus.accepted,
      distanceKm: 1.2,
      category: 'ATK',
    ),
  ];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Tugas P8: 01 Layout Adaptif (Layar Besar vs Layar Kecil)', () {
    testWidgets('DashboardScreen beradaptasi ke GridView 2-kolom pada layar lebar (Tablet >= 680px)',
        (tester) async {
      // Simulasikan layar tablet / desktop (1024 x 768)
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = ErrandRepositoryImpl(initialErrands: sampleErrands);
      final feedNotifier = ErrandFeedNotifier(repository);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandRepositoryProvider.overrideWithValue(repository),
            errandFeedNotifierProvider.overrideWith((ref) => feedNotifier),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardScreen(isEmbedded: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pada layar lebar (width >= 680), GridView aktif untuk efisiensi ruang
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.text('Nasi Ayam Geprek Level 2'), findsOneWidget);
    });

    testWidgets('DashboardScreen beradaptasi ke ListView 1-kolom pada layar kecil (Ponsel < 680px)',
        (tester) async {
      // Simulasikan layar ponsel compact (400 x 800)
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = ErrandRepositoryImpl(initialErrands: sampleErrands);
      final feedNotifier = ErrandFeedNotifier(repository);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandRepositoryProvider.overrideWithValue(repository),
            errandFeedNotifierProvider.overrideWith((ref) => feedNotifier),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardScreen(isEmbedded: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pada layar compact, ListView single-column aktif
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(GridView), findsNothing);
      expect(find.text('Nasi Ayam Geprek Level 2'), findsOneWidget);
    });

    testWidgets('CreateErrandScreen menata Pickup & Dropoff dalam 2-kolom horizontal pada layar lebar',
        (tester) async {
      // Layar tablet (800 x 900)
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CreateErrandScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi kedua field pickup & dropoff berada dalam 1 Row horizontal
      expect(find.text('Lokasi Pengambilan (Pickup)'), findsOneWidget);
      expect(find.text('Lokasi Tujuan Pengantaran (Dropoff)'), findsOneWidget);

      final pickupCenter = tester.getCenter(find.text('Lokasi Pengambilan (Pickup)'));
      final dropoffCenter = tester.getCenter(find.text('Lokasi Tujuan Pengantaran (Dropoff)'));

      // Pada layout 2-kolom, koordinat Y keduanya sejajar secara horizontal
      expect((pickupCenter.dy - dropoffCenter.dy).abs(), lessThan(10.0));
      // Dan pickup berada di sebelah kiri dropoff
      expect(pickupCenter.dx, lessThan(dropoffCenter.dx));
    });
  });

  group('Tugas P8: 02 Keyboard-Safe UI (Tidak Tertutup & Bebas Overflow)', () {
    testWidgets('Formulir CreateErrandScreen tetap terlihat dan bebas overflow saat keyboard virtual aktif',
        (tester) async {
      // Simulasikan layar ponsel dengan keyboard virtual terbuka (viewInsets.bottom = 400)
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: 400.0);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CreateErrandScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pastikan SingleChildScrollView aktif dengan keyboardDismissBehavior onDrag
      final scrollFinder = find.byType(SingleChildScrollView).first;
      expect(scrollFinder, findsOneWidget);

      final scrollWidget = tester.widget<SingleChildScrollView>(scrollFinder);
      expect(
        scrollWidget.keyboardDismissBehavior,
        equals(ScrollViewKeyboardDismissBehavior.onDrag),
      );

      // Scroll ke bawah untuk memastikan seluruh input box dapat dijangkau dan terlihat
      await tester.drag(scrollFinder, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Nominal Tip Imbalan (Rupiah)'), findsOneWidget);
      expect(find.text('Kirim Permintaan Titipan'), findsOneWidget);
    });

    testWidgets('LoginScreen dapat di-scroll lancar saat keyboard virtual terbuka',
        (tester) async {
      tester.view.physicalSize = const Size(400, 650);
      tester.view.devicePixelRatio = 1.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: 350.0);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollFinder = find.byType(SingleChildScrollView);
      expect(scrollFinder, findsOneWidget);

      final scrollWidget = tester.widget<SingleChildScrollView>(scrollFinder);
      expect(
        scrollWidget.keyboardDismissBehavior,
        equals(ScrollViewKeyboardDismissBehavior.onDrag),
      );

      // Verifikasi tombol masuk tetap dapat di-scroll dan ditekan
      await tester.drag(scrollFinder, const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.text('Masuk'), findsOneWidget);
    });
  });

  group('Tugas P8: 03 Accessibility Dasar (Semantics, Tooltip, Touch Target >= 48dp)', () {
    testWidgets('PrimaryButton memiliki minimum touch target height >= 48dp dan Semantics lengkap',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Uji Aksesibilitas',
              height: 40, // Diminta 40, tetapi PrimaryButton harus memaksakan min 48dp
              onPressed: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final buttonFinder = find.byType(PrimaryButton);
      expect(buttonFinder, findsOneWidget);

      final buttonSize = tester.getSize(buttonFinder);
      // Memenuhi standar WCAG minimum touch target 48dp
      expect(buttonSize.height, greaterThanOrEqualTo(48.0));

      // Memverifikasi pohon Semantics
      expect(
        tester.getSemantics(buttonFinder),
        matchesSemantics(
          label: 'Uji Aksesibilitas',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
        ),
      );
    });

    testWidgets('ErrandCard memiliki label Semantics informatif untuk screen reader TalkBack',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrandCard(
              errand: sampleErrands.first,
              onTap: () {},
              onAccept: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.byType(ErrandCard);
      expect(cardFinder, findsOneWidget);

      // Screen reader menerima informasi lengkap pesanan
      final semantics = tester.getSemantics(cardFinder);
      expect(semantics.label, contains('Titipan Nasi Ayam Geprek Level 2'));
      expect(semantics.label, contains('Rp 6.000'));
      expect(semantics.label, contains('0.5 kilometer'));
    });

    testWidgets('InteractiveBottomNav memiliki Semantics tombol dan seleksi untuk setiap tab',
        (tester) async {
      int activeIndex = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: InteractiveBottomNav(
              currentIndex: activeIndex,
              onTap: (idx) => activeIndex = idx,
              items: const [
                NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
                NavItem(icon: Icons.radar_outlined, activeIcon: Icons.radar, label: 'Feed Rute'),
                NavItem(icon: Icons.receipt_outlined, activeIcon: Icons.receipt, label: 'Titipan'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi semantics navigasi
      // Verifikasi semantics navigasi pada widget tree
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Navigasi tab Home',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Navigasi tab Feed Rute',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Navigasi tab Titipan',
        ),
        findsOneWidget,
      );
    });

    testWidgets('IconButton pada formulir dan dashboard memiliki tooltip deskriptif',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CreateErrandScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tooltip reset dan tooltip GPS
      expect(find.byTooltip('Reset Formulir'), findsOneWidget);
      expect(find.byTooltip('Gunakan Koordinat GPS Kampus'), findsOneWidget);
    });
  });

  group('Tugas P8: 04 Feedback Aksi (Loading Indicators, SnackBar, Status Feedback)', () {
    testWidgets('Menekan tombol kirim form memberikan feedback loading anti-double tap dan feedback validasi',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appNotificationServiceProvider.overrideWithValue(_FakeAppNotificationService()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CreateErrandScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Aksi 1: Tekan submit saat kosong -> Muncul pesan error feedback seketika
      final submitBtn = find.text('Kirim Permintaan Titipan');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Nama barang wajib diisi'), findsOneWidget);
      expect(find.text('Lokasi pengambilan wajib diisi'), findsOneWidget);
      expect(find.text('Lokasi tujuan wajib diisi'), findsOneWidget);

      // Aksi 2: Isi valid dan submit -> tombol bertransisi ke loading spinner
      await tester.enterText(find.widgetWithText(AppTextField, 'Nama Barang / Pesanan'), 'Nasi Goreng Spesial');
      await tester.enterText(find.widgetWithText(AppTextField, 'Lokasi Pengambilan (Pickup)'), 'Kantin Teknik');
      await tester.enterText(find.widgetWithText(AppTextField, 'Lokasi Tujuan Pengantaran (Dropoff)'), 'Gedung Rektorat');
      await tester.pumpAndSettle();

      await tester.tap(submitBtn);
      await tester.pump(); // frame transisi submit

      // Verifikasi indikator loading visual aktif sehingga user tidak bertanya-tanya
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Sedang memproses permintaan titipan...'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('Menekan tombol GPS memberikan feedback SnackBar konfirmasi lokasi berhasil disematkan',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            geoLocationServiceProvider.overrideWithValue(_FakeGeoLocationService()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CreateErrandScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gpsBtn = find.byTooltip('Gunakan Koordinat GPS Kampus');
      expect(gpsBtn, findsOneWidget);

      await tester.tap(gpsBtn);
      await tester.pumpAndSettle();

      // Feedback instan SnackBar
      expect(find.text('Titik koordinat GPS berhasil disematkan ke formulir!'), findsOneWidget);
      expect(find.textContaining('-7.3117, 112.7275'), findsOneWidget);
    });
  });
}

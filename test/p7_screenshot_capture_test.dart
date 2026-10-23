import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titip_jalur/controllers/errand_feed_notifier.dart';
import 'package:titip_jalur/models/errand_model.dart';
import 'package:titip_jalur/repositories/errand_repository.dart';
import 'package:titip_jalur/screens/create_errand_screen.dart';
import 'package:titip_jalur/screens/dashboard_screen.dart';
import 'package:titip_jalur/screens/detail_screen.dart';
import 'package:titip_jalur/screens/errand_orders_page.dart';
import 'package:titip_jalur/screens/profile_screen.dart';
import 'package:titip_jalur/services/auth_service.dart';
import 'package:titip_jalur/services/pod_camera_service.dart';
import 'font_loader_helper.dart';
import 'test_theme_helper.dart';

class _FakePodCameraService implements IPodCameraService {
  @override
  Future<String?> captureProofOfDelivery({dynamic source}) async {
    return '/cache/pod_camera_proof_sample.jpg';
  }

  @override
  Future<bool> verifyImageExists(String path) async => true;
}

Future<void> _captureHighResPhoneScreenshot(
  WidgetTester tester,
  GlobalKey key,
  String fileName,
) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.625);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('P7/screenshots/$fileName');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(byteData!.buffer.asUint8List(), flush: true);
  });
}

Widget _buildScreenInRepaintBoundary(Widget screen, GlobalKey repaintKey) {
  return RepaintBoundary(
    key: repaintKey,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: getTitipJalurTheme(),
      home: screen,
    ),
  );
}

void main() {
  setUpAll(() async {
    await loadRealFonts();
  });

  const sampleCompletedWithPod = ErrandModel(
    id: 'p7_pod_01',
    item: 'Nasi Ayam Penyet Sambal Korek',
    pickup: 'Kantin Pusat UNESA Ketintang',
    dropoff: 'Lab Jaringan Komputer Gedung K10',
    tip: 6000,
    requester: 'Muhammad Naufal Fahrel',
    status: OrderStatus.completed,
    distanceKm: 0.8,
    category: 'Kantin',
    proofOfDeliveryPath: 'pod_camera_serah_terima_01.jpg',
    latitude: -7.3117,
    longitude: 112.7275,
  );

  final sampleErrands = [
    sampleCompletedWithPod,
    const ErrandModel(
      id: 'p7_order_02',
      item: 'Kertas HVS A4 1 Rim & Spidol Boardmarker',
      pickup: 'Koperasi Mahasiswa FMIPA',
      dropoff: 'Ruang Dosen Gedung C',
      tip: 4000,
      requester: 'Dimas Pratama',
      status: OrderStatus.accepted,
      distanceKm: 1.1,
      category: 'ATK',
    ),
    const ErrandModel(
      id: 'p7_order_03',
      item: 'Iced Caramel Macchiato Double Shot',
      pickup: 'Kafe Rimbun Kampus',
      dropoff: 'Perpustakaan Pusat Lt 2',
      tip: 7500,
      requester: 'Ahmad Fauzi',
      status: OrderStatus.open,
      distanceKm: 0.5,
      category: 'Kafe',
    ),
  ];

  group('P7 Advanced Features FHD+ Mobile Screenshots (1080x2400)', () {
    testWidgets('1. Fitur 1: Autentikasi & Multi-Sided Role Switcher (Requester vs Runner)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      await tester.runAsync(() async {
        await AuthService.instance.loginAsGuest(role: 'Runner');
      });

      final key = GlobalKey();

      await tester.pumpWidget(
        ProviderScope(
          child: _buildScreenInRepaintBoundary(
            const ProfileScreen(),
            key,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _captureHighResPhoneScreenshot(
        tester,
        key,
        '01_p7_auth_role_switcher.png',
      );
    });

    testWidgets('2. Fitur 2: Form Buat Titipan dengan Deteksi Lokasi GPS Kampus',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final key = GlobalKey();

      await tester.pumpWidget(
        ProviderScope(
          child: _buildScreenInRepaintBoundary(
            const CreateErrandScreen(),
            key,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger GPS detection button
      final gpsBtn = find.byIcon(Icons.my_location_rounded);
      if (gpsBtn.evaluate().isNotEmpty) {
        await tester.tap(gpsBtn);
        await tester.pumpAndSettle();
      }

      await _captureHighResPhoneScreenshot(
        tester,
        key,
        '02_p7_gps_location_create.png',
      );
    });

    testWidgets('3. Fitur 3: Kamera Proof of Delivery (POD) Dialog di Manajemen Tugas Runner',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final repository = ErrandRepositoryImpl(initialErrands: sampleErrands);
      final feedNotifier = ErrandFeedNotifier(repository);
      final key = GlobalKey();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandRepositoryProvider.overrideWithValue(repository),
            errandFeedNotifierProvider.overrideWith((ref) => feedNotifier),
            podCameraServiceProvider.overrideWithValue(_FakePodCameraService()),
          ],
          child: _buildScreenInRepaintBoundary(
            const Scaffold(body: ErrandOrdersPage()),
            key,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Runner tasks tab
      final runnerTab = find.text('Tugas Belanja / Antar');
      await tester.tap(runnerTab);
      await tester.pumpAndSettle();

      // Tap Selesaikan Tugas button to open dialog
      final completeBtn = find.text('Selesaikan Tugas');
      if (completeBtn.evaluate().isNotEmpty) {
        await tester.tap(completeBtn.first);
        await tester.pumpAndSettle();

        // Simulate picking camera photo in dialog
        final cameraBtn = find.text('Kamera');
        if (cameraBtn.evaluate().isNotEmpty) {
          await tester.tap(cameraBtn);
          await tester.pumpAndSettle();
        }
      }

      await _captureHighResPhoneScreenshot(
        tester,
        key,
        '03_p7_pod_camera_dialog.png',
      );
    });

    testWidgets('4. Fitur 3: Detail Order dengan Bukti Foto POD Terverifikasi Kamera',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final repository = ErrandRepositoryImpl(initialErrands: [sampleCompletedWithPod]);
      final key = GlobalKey();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandRepositoryProvider.overrideWithValue(repository),
          ],
          child: _buildScreenInRepaintBoundary(
            const DetailScreen(errand: sampleCompletedWithPod),
            key,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _captureHighResPhoneScreenshot(
        tester,
        key,
        '04_p7_pod_verified_detail.png',
      );
    });

    testWidgets('5. Dashboard Feed Komuter dengan Slider Radius & Chip Kategori',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final repository = ErrandRepositoryImpl(initialErrands: sampleErrands);
      final feedNotifier = ErrandFeedNotifier(repository);
      final key = GlobalKey();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandRepositoryProvider.overrideWithValue(repository),
            errandFeedNotifierProvider.overrideWith((ref) => feedNotifier),
          ],
          child: _buildScreenInRepaintBoundary(
            const DashboardScreen(isEmbedded: true),
            key,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _captureHighResPhoneScreenshot(
        tester,
        key,
        '05_p7_commuter_feed_active.png',
      );
    });

    testWidgets('6. Tab Permintaan Saya dengan Opsi Pembatalan Pesanan Aman',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final repository = ErrandRepositoryImpl(initialErrands: sampleErrands);
      final feedNotifier = ErrandFeedNotifier(repository);
      final key = GlobalKey();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandRepositoryProvider.overrideWithValue(repository),
            errandFeedNotifierProvider.overrideWith((ref) => feedNotifier),
          ],
          child: _buildScreenInRepaintBoundary(
            const Scaffold(body: ErrandOrdersPage()),
            key,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _captureHighResPhoneScreenshot(
        tester,
        key,
        '06_p7_requester_orders_tab.png',
      );
    });
  });
}

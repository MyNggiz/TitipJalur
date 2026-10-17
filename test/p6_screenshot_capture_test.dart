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
import 'font_loader_helper.dart';
import 'test_theme_helper.dart';

class _MockFeedNotifier extends StateNotifier<AsyncValue<List<ErrandModel>>>
    implements ErrandFeedNotifier {
  _MockFeedNotifier(super.state);

  @override
  void addErrand(ErrandModel errand) {}

  @override
  Future<void> acceptErrand(String id) async {}

  @override
  Future<void> completeErrand(String id) async {}

  @override
  Future<void> deleteErrand(String id) async {}

  @override
  Future<void> loadErrands(
      {bool forceError = false, bool forceEmpty = false}) async {}

  @override
  Future<void> retry() async {}
}

Future<void> _captureHighResPhoneScreenshot(
  WidgetTester tester,
  GlobalKey key,
  String fileName,
) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    // Render at physical pixel ratio 2.625 (1080 x 2400 physical resolution)
    final image = await boundary.toImage(pixelRatio: 2.625);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('P6/screenshots/$fileName');
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

  final sampleErrands = [
    const ErrandModel(
      id: 'p6_api_01',
      item: 'Nasi Ayam Geprek Sambal Matah Level 4',
      pickup: 'Kantin Pusat UNESA Lt. 1',
      dropoff: 'Lab Jaringan & Cloud Gedung K10',
      tip: 7000,
      requester: 'Naufal Fahrel',
      status: OrderStatus.open,
      distanceKm: 0.5,
      category: 'Kantin',
    ),
    const ErrandModel(
      id: 'p6_api_02',
      item: 'Kertas HVS 1 Rim & Map Plastik Biru',
      pickup: 'Koperasi Mahasiswa Utama',
      dropoff: 'Ruang Himpunan Mahasiswa TI',
      tip: 5000,
      requester: 'Dimas Pratama',
      status: OrderStatus.accepted,
      distanceKm: 0.9,
      category: 'ATK',
    ),
    const ErrandModel(
      id: 'p6_api_03',
      item: 'Iced Spanish Latte & Croissant Butter',
      pickup: 'Kafe Rimbun Kampus Ketintang',
      dropoff: 'Perpustakaan Pusat Lantai 3',
      tip: 8000,
      requester: 'Ahmad Fauzi',
      status: OrderStatus.completed,
      distanceKm: 1.4,
      category: 'Kafe',
    ),
  ];

  group('P6 MVP Refinement FHD+ Mobile Screenshots (1080x2400)', () {
    testWidgets('1. State 1: Loading State (Vertical Slice In Progress)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final key = GlobalKey();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandFeedNotifierProvider.overrideWith(
              (ref) => _MockFeedNotifier(const AsyncValue.loading()),
            ),
          ],
          child: _buildScreenInRepaintBoundary(
            const DashboardScreen(isEmbedded: true),
            key,
          ),
        ),
      );
      await tester.pump();

      await _captureHighResPhoneScreenshot(
        tester,
        key,
        '01_p6_state_loading.png',
      );
    });

    testWidgets('2. State 2: Success State (Active Errand Feed via REST API)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final repository = ErrandRepositoryImpl(initialErrands: sampleErrands);
      final feedNotifier = _MockFeedNotifier(AsyncValue.data(sampleErrands));
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
        '02_p6_state_success_feed.png',
      );
    });

    testWidgets('3. State 3: Empty State (No Active Orders via API)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final key = GlobalKey();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandFeedNotifierProvider.overrideWith(
              (ref) => _MockFeedNotifier(const AsyncValue.data([])),
            ),
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
        '03_p6_state_empty.png',
      );
    });

    testWidgets('4. State 4: Error State with Retry Button',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final key = GlobalKey();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandFeedNotifierProvider.overrideWith(
              (ref) => _MockFeedNotifier(
                AsyncValue.error(
                  Exception('Gagal menghubungi server titipan. Periksa koneksi internet Anda.'),
                  StackTrace.empty,
                ),
              ),
            ),
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
        '04_p6_state_error_retry.png',
      );
    });

    testWidgets('5. Fitur 3: Form Pembuatan Titipan Baru (Vertical Slice POST)',
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

      await _captureHighResPhoneScreenshot(
        tester,
        key,
        '05_p6_vertical_slice_create.png',
      );
    });

    testWidgets('6. Fitur 4: Detail Order & Aksi Klaim Komuter (Two-Sided Flow)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final repository = ErrandRepositoryImpl(initialErrands: sampleErrands);
      final key = GlobalKey();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandRepositoryProvider.overrideWithValue(repository),
          ],
          child: _buildScreenInRepaintBoundary(
            DetailScreen(errand: sampleErrands.first),
            key,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _captureHighResPhoneScreenshot(
        tester,
        key,
        '06_p6_detail_order_claim.png',
      );
    });
  });
}

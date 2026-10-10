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
import 'font_loader_helper.dart';
import 'test_theme_helper.dart';

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
    final file = File('P5/screenshots/$fileName');
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
      id: 'p5_shot_01',
      item: 'Ayam Geprek Bu Siti Level 3 + Es Teh',
      pickup: 'Kantin Pusat FTI Lt. 1',
      dropoff: 'Lab Komputer RPL Gedung B',
      tip: 6000,
      requester: 'Naufal',
      status: OrderStatus.open,
      distanceKm: 0.4,
      category: 'Kantin',
    ),
    const ErrandModel(
      id: 'p5_shot_02',
      item: 'Print Makalah 20 Lembar & Map Hijau',
      pickup: 'Fotokopi Gerbang Depan',
      dropoff: 'Gedung Dekanat Lt. 1 R.102',
      tip: 5000,
      requester: 'Dimas',
      status: OrderStatus.accepted,
      distanceKm: 1.2,
      category: 'ATK',
    ),
    const ErrandModel(
      id: 'p5_shot_03',
      item: 'Iced Caramel Macchiato & Croissant',
      pickup: 'Kafe Pojok Perpustakaan',
      dropoff: 'Ruang Seminar Bersama',
      tip: 8000,
      requester: 'Fahrel',
      status: OrderStatus.completed,
      distanceKm: 0.8,
      category: 'Kafe',
    ),
  ];

  group('P5 MVP v1 Real FHD+ Mobile Screenshots (1080x2400)', () {
    testWidgets('1. Fitur 1: Feed Titipan dengan Data Persisten Lokal',
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
        '01_fitur1_feed_data_persisten.png',
      );
    });

    testWidgets('2. Fitur 1: Formulir Buat Titipan Persisten',
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
        '02_fitur1_form_create_persisten.png',
      );
    });

    testWidgets('3. Fitur 2: Filter Radius Hiperlokal & Kategori Komuter',
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

      // Tap filter ATK
      final atkChip = find.widgetWithText(FilterChip, 'ATK');
      if (atkChip.evaluate().isNotEmpty) {
        await tester.tap(atkChip);
        await tester.pumpAndSettle();
      }

      await _captureHighResPhoneScreenshot(
        tester,
        key,
        '03_fitur2_radius_slider_filter.png',
      );
    });

    testWidgets('4. Fitur 2: Halaman Detail Titipan & Aksi Klaim Runner',
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
            DetailScreen(errand: sampleErrands.first),
            key,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 350));

      await _captureHighResPhoneScreenshot(
        tester,
        key,
        '04_fitur2_detail_runner_claim.png',
      );
    });
    testWidgets('5. Fitur 2: Tab Manajemen Pesanan Runner & Selesaikan Tugas',
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

      // Pindah ke tab runner
      final runnerTab = find.text('Tugas Belanja / Antar');
      if (runnerTab.evaluate().isNotEmpty) {
        await tester.tap(runnerTab);
        await tester.pumpAndSettle();
      }

      await _captureHighResPhoneScreenshot(
        tester,
        key,
        '05_fitur2_runner_tasks_complete.png',
      );
    });

    testWidgets('6. Fitur 2: Tab Permintaan Saya & Pembatalan Pesanan',
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
        '06_fitur2_requester_cancel_order.png',
      );
    });
  });
}

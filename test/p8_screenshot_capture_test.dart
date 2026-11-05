import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titip_jalur/controllers/errand_feed_notifier.dart';
import 'package:titip_jalur/controllers/errand_form_notifier.dart';
import 'package:titip_jalur/models/errand_model.dart';
import 'package:titip_jalur/repositories/errand_repository.dart';
import 'package:titip_jalur/screens/create_errand_screen.dart';
import 'package:titip_jalur/screens/dashboard_screen.dart';
import 'package:titip_jalur/screens/detail_screen.dart';
import 'font_loader_helper.dart';
import 'test_theme_helper.dart';

Future<void> _captureHighResScreenshot(
  WidgetTester tester,
  GlobalKey key,
  String fileName, {
  double pixelRatio = 2.0,
}) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('P8/screenshots/$fileName');
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
      id: 'p8_shot_01',
      item: 'Ayam Geprek Sambal Bawang + Es Teh Manis',
      pickup: 'Kantin Pusat FTI Lt. 1',
      dropoff: 'Lab Komputer RPL Gedung B R.204',
      tip: 6000,
      requester: 'Naufal',
      status: OrderStatus.open,
      distanceKm: 0.4,
      category: 'Kantin',
    ),
    const ErrandModel(
      id: 'p8_shot_02',
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
      id: 'p8_shot_03',
      item: 'Iced Caramel Macchiato & Croissant Keju',
      pickup: 'Kafe Pojok Perpustakaan',
      dropoff: 'Ruang Seminar Bersama Lt. 3',
      tip: 8000,
      requester: 'Fahrel',
      status: OrderStatus.open,
      distanceKm: 0.8,
      category: 'Kafe',
    ),
    const ErrandModel(
      id: 'p8_shot_04',
      item: 'Vitamin C 1000mg & Masker Medis 1 Box',
      pickup: 'Apotek Koperasi Kampus',
      dropoff: 'Asrama Mahasiswa Putri R.312',
      tip: 7000,
      requester: 'Anisa',
      status: OrderStatus.completed,
      distanceKm: 1.5,
      category: 'Obat',
    ),
  ];

  group('P8 Responsive UX Real FHD+ Screenshots (4 Bukti Utama Reviewer)', () {
    // -------------------------------------------------------------------------
    // BUKTI 1: 01 Layout Adaptif (Layar Lebar / Tablet 2-Kolom Grid & Form Adaptif)
    // -------------------------------------------------------------------------
    testWidgets('Screenshot 1: 01 Layout Adaptif Layar Lebar Tablet / Desktop Widescreen',
        (tester) async {
      // Resolusi tablet widescreen (1600 x 2200, ratio 2.0 = 800x1100 logical)
      tester.view.physicalSize = const Size(1600, 2200);
      tester.view.devicePixelRatio = 2.0;
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
            const Scaffold(body: DashboardScreen(isEmbedded: true)),
            key,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _captureHighResScreenshot(
        tester,
        key,
        '01_p8_layout_adaptif.png',
        pixelRatio: 1.5,
      );
    });

    // -------------------------------------------------------------------------
    // BUKTI 2: 02 Keyboard-Safe UI (Formulir Saat Keyboard Aktif Bebas Overflow)
    // -------------------------------------------------------------------------
    testWidgets('Screenshot 2: 02 Keyboard-Safe UI Input Box Terlihat Jelas & Bebas Overflow',
        (tester) async {
      // Layar ponsel FHD+ (1080 x 2400) dengan keyboard virtual aktif terangkat (insets bottom 750px)
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      tester.view.viewInsets = const FakeViewPadding(bottom: 750.0);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

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

      // Scroll sedikit agar input box dan quick tips terlihat pas di atas keyboard
      final scrollFinder = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollFinder, const Offset(0, -180));
      await tester.pumpAndSettle();

      await _captureHighResScreenshot(
        tester,
        key,
        '02_p8_keyboard_safe_ui.png',
        pixelRatio: 2.625,
      );
    });

    // -------------------------------------------------------------------------
    // BUKTI 3: 03 Accessibility Dasar (Semantics, Tooltips, Touch Target 48dp, Kontras)
    // -------------------------------------------------------------------------
    testWidgets('Screenshot 3: 03 Accessibility Dasar Touch Targets & Visual Semantics',
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

      await _captureHighResScreenshot(
        tester,
        key,
        '03_p8_accessibility_dasar.png',
        pixelRatio: 2.625,
      );
    });

    // -------------------------------------------------------------------------
    // BUKTI 4: 04 Feedback Aksi (Loading Indicator, Banner Status & Anti-Double Tap)
    // -------------------------------------------------------------------------
    testWidgets('Screenshot 4: 04 Feedback Aksi Loading Spinner Anti-Double Tap & Banner Responsif',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final key = GlobalKey();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandFormNotifierProvider.overrideWith(
              (ref) => _CustomSubmittingFormNotifier(
                const ErrandFormState(
                  item: 'Nasi Padang Rendang + Es Jeruk',
                  pickup: 'Kantin Pusat FTI Lt. 1',
                  dropoff: 'Lab Komputer RPL Gedung B R.204',
                  tip: '8000',
                  category: 'Kantin',
                  isSubmitting: true, // Sedang memproses submit
                ),
              ),
            ),
          ],
          child: _buildScreenInRepaintBoundary(
            const CreateErrandScreen(),
            key,
          ),
        ),
      );
      await tester.pump();

      await _captureHighResScreenshot(
        tester,
        key,
        '04_p8_feedback_aksi.png',
        pixelRatio: 2.625,
      );
    });
  });
}

class _CustomSubmittingFormNotifier extends StateNotifier<ErrandFormState>
    implements ErrandFormNotifier {
  _CustomSubmittingFormNotifier(super.state);

  @override
  void setCategory(String val) {}

  @override
  void setDropoff(String val) {}

  @override
  void setItem(String val) {}

  @override
  void setPickup(String val) {}

  @override
  void setTip(String val) {}

  @override
  void reset() {}

  @override
  bool validate() => true;

  @override
  Future<bool> submit(
    ErrandRepository repository, {
    required String requesterName,
    bool simulateError = false,
  }) async =>
      true;
}

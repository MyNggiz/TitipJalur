import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titip_jalur/controllers/errand_feed_notifier.dart';
import 'package:titip_jalur/models/errand_model.dart';
import 'package:titip_jalur/models/user_model.dart';
import 'package:titip_jalur/repositories/errand_repository.dart';
import 'package:titip_jalur/screens/errand_orders_page.dart';
import 'package:titip_jalur/services/auth_service.dart';
import 'font_loader_helper.dart';
import 'test_theme_helper.dart';

Future<void> _captureScreenshot(
  WidgetTester tester,
  GlobalKey key,
  String fileName,
) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('P11/screenshots/$fileName');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(byteData!.buffer.asUint8List(), flush: true);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadRealFonts();
  });

  group('P11 UI Bugfix Screenshot Capture', () {
    testWidgets('1. Tab Permintaan Saya hanya menampilkan pesanan milik user aktif (Bug #4 Fixed)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await AuthService.instance.setCurrentUser(
        const UserModel(
          id: 'usr_budi',
          name: 'Budi',
          email: 'budi@kampus.ac.id',
          role: 'Mahasiswa',
        ),
      );

      final errands = [
        const ErrandModel(
          id: 'err_budi_1',
          item: 'Kopi Susu Gula Aren (Milik Budi)',
          pickup: 'Kantin Vokasi',
          dropoff: 'Lab RPL Lt. 2',
          tip: 5000,
          requester: 'Budi',
          requesterId: 'usr_budi',
          status: OrderStatus.open,
        ),
        const ErrandModel(
          id: 'other_001',
          item: 'Pesanan Orang Lain ID Suffix 1',
          pickup: 'Kantin',
          dropoff: 'Perpus',
          tip: 4000,
          requester: 'Siti',
          requesterId: 'usr_siti',
          status: OrderStatus.open,
        ),
        const ErrandModel(
          id: 'other_003',
          item: 'Pesanan Naufal Orang Lain',
          pickup: 'Koperasi',
          dropoff: 'Rektorat',
          tip: 6000,
          requester: 'Naufal Pratama',
          requesterId: 'usr_naufal',
          status: OrderStatus.open,
        ),
      ];

      final repo = ErrandRepositoryImpl(initialErrands: errands);
      final notifier = ErrandFeedNotifier(repo);
      final key = GlobalKey();

      tester.view.physicalSize = const Size(540, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandRepositoryProvider.overrideWithValue(repo),
            errandFeedNotifierProvider.overrideWith((ref) => notifier),
          ],
          child: RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: getTitipJalurTheme(),
              home: const Scaffold(body: ErrandOrdersPage()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kopi Susu Gula Aren (Milik Budi)'), findsOneWidget);
      expect(find.text('Pesanan Orang Lain ID Suffix 1'), findsNothing);
      expect(find.text('Pesanan Naufal Orang Lain'), findsNothing);

      await _captureScreenshot(tester, key, '06_ui_permintaan_saya_fixed.png');
      AuthService.instance.resetForTest();
    });

    testWidgets('2. Tab Tugas Belanja / Antar hanya menampilkan tugas yang diklaim runner aktif (Bug #5 Fixed)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await AuthService.instance.setCurrentUser(
        const UserModel(
          id: 'usr_budi',
          name: 'Budi',
          email: 'budi@kampus.ac.id',
          role: 'Runner',
        ),
      );

      final errands = [
        const ErrandModel(
          id: 'task_budi_claimed',
          item: 'Fotokopi Modul Jarkom (Diklaim Budi)',
          pickup: 'Koperasi FMIPA',
          dropoff: 'Gedung C Lt. 3',
          tip: 7000,
          requester: 'Siti',
          requesterId: 'usr_siti',
          runnerId: 'usr_budi',
          runnerName: 'Budi',
          status: OrderStatus.accepted,
        ),
        const ErrandModel(
          id: 'open_unclaimed_1',
          item: 'Order Terbuka Belum Diklaim',
          pickup: 'Kantin',
          dropoff: 'Lab',
          tip: 4000,
          requester: 'Dewi',
          requesterId: 'usr_dewi',
          status: OrderStatus.open,
        ),
      ];

      final repo = ErrandRepositoryImpl(initialErrands: errands);
      final notifier = ErrandFeedNotifier(repo);
      final key = GlobalKey();

      tester.view.physicalSize = const Size(540, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            errandRepositoryProvider.overrideWithValue(repo),
            errandFeedNotifierProvider.overrideWith((ref) => notifier),
          ],
          child: RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: getTitipJalurTheme(),
              home: const Scaffold(body: ErrandOrdersPage()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tugas Belanja / Antar'));
      await tester.pumpAndSettle();

      expect(find.text('Fotokopi Modul Jarkom (Diklaim Budi)'), findsOneWidget);
      expect(find.text('Order Terbuka Belum Diklaim'), findsNothing);

      await _captureScreenshot(tester, key, '07_ui_tugas_runner_fixed.png');
      AuthService.instance.resetForTest();
    });
  });
}

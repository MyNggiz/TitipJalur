import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadRealFonts() async {
  final fontDir = Directory('/home/mynggiz/development/flutter/bin/cache/artifacts/material_fonts');
  if (!fontDir.existsSync()) return;

  // 1. Load Roboto fonts under family 'Roboto'
  final robotoLoader = FontLoader('Roboto');
  // Also load under '' (default/fallback) if possible, and under platform font names
  final defaultLoader = FontLoader('.SF UI Text');
  final androidLoader = FontLoader('sans-serif');

  for (final file in fontDir.listSync()) {
    if (file is File && file.path.contains('Roboto') && file.path.endsWith('.ttf')) {
      final bytes = file.readAsBytesSync();
      robotoLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
      defaultLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
      androidLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
  }
  await robotoLoader.load();
  await defaultLoader.load();
  await androidLoader.load();

  // 2. Load MaterialIcons font
  final iconFile = File('${fontDir.path}/MaterialIcons-Regular.otf');
  if (iconFile.existsSync()) {
    final iconLoader = FontLoader('MaterialIcons');
    final bytes = iconFile.readAsBytesSync();
    iconLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
    await iconLoader.load();
  }
}

/// Helper that wraps [child] in a [DefaultTextStyle] that enforces [Roboto] font family,
/// ensuring widgets with unstyled or inline [TextStyle] never fall back to the test [Ahem] font.
Widget withRealRoboto(Widget child) {
  return DefaultTextStyle.merge(
    style: const TextStyle(
      fontFamily: 'Roboto',
      fontFamilyFallback: ['Roboto', 'sans-serif'],
    ),
    child: child,
  );
}

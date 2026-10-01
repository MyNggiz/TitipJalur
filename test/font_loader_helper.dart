import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadRealFonts() async {
  final fontDir = Directory('/home/mynggiz/development/flutter/bin/cache/artifacts/material_fonts');
  if (!fontDir.existsSync()) return;

  final fontLoader = FontLoader('Roboto');
  for (final file in fontDir.listSync()) {
    if (file is File && file.path.endsWith('.ttf')) {
      final bytes = file.readAsBytesSync();
      fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
  }
  await fontLoader.load();
}

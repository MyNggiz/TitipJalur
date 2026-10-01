import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadRealFonts() async {
  final fontDir = Directory('/home/mynggiz/development/flutter/bin/cache/artifacts/material_fonts');
  if (!fontDir.existsSync()) return;

  // 1. Load Roboto fonts (Regular, Bold, Medium, etc.)
  final robotoLoader = FontLoader('Roboto');
  for (final file in fontDir.listSync()) {
    if (file is File && file.path.contains('Roboto') && file.path.endsWith('.ttf')) {
      final bytes = file.readAsBytesSync();
      robotoLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
  }
  await robotoLoader.load();

  // 2. Load MaterialIcons font
  final iconFile = File('${fontDir.path}/MaterialIcons-Regular.otf');
  if (iconFile.existsSync()) {
    final iconLoader = FontLoader('MaterialIcons');
    final bytes = iconFile.readAsBytesSync();
    iconLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
    await iconLoader.load();
  }
}

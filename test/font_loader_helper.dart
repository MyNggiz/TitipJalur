import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadRealFonts() async {
  Directory? fontDir;

  // 1. Check local repo test assets
  final localAssets = Directory('test/assets/fonts');
  if (localAssets.existsSync()) {
    fontDir = localAssets;
  }

  // 2. Check Windows / Puro caches
  if (fontDir == null) {
    final home = Platform.environment['USERPROFILE'] ??
        Platform.environment['HOME'] ??
        '';
    final puroShared = Directory('$home/.puro/shared/caches');
    if (puroShared.existsSync()) {
      for (final entity in puroShared.listSync()) {
        final candidate = Directory('${entity.path}/artifacts/material_fonts');
        if (candidate.existsSync()) {
          fontDir = candidate;
          break;
        }
      }
    }
  }

  // 3. Fallback to Linux dev path
  if (fontDir == null) {
    final linuxPath = Directory(
      '/home/mynggiz/development/flutter/bin/cache/artifacts/material_fonts',
    );
    if (linuxPath.existsSync()) {
      fontDir = linuxPath;
    }
  }

  if (fontDir == null || !fontDir.existsSync()) return;

  // Load Roboto fonts under family 'Roboto', '.SF UI Text', and 'sans-serif'
  final robotoLoader = FontLoader('Roboto');
  final defaultLoader = FontLoader('.SF UI Text');
  final androidLoader = FontLoader('sans-serif');

  for (final file in fontDir.listSync()) {
    if (file is File) {
      final nameLower = file.path.toLowerCase();
      if (nameLower.contains('roboto') && nameLower.endsWith('.ttf')) {
        final bytes = file.readAsBytesSync();
        robotoLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
        defaultLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
        androidLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
      }
    }
  }
  await robotoLoader.load();
  await defaultLoader.load();
  await androidLoader.load();

  // Load MaterialIcons font
  for (final file in fontDir.listSync()) {
    if (file is File) {
      final nameLower = file.path.toLowerCase();
      if (nameLower.contains('materialicons') &&
          (nameLower.endsWith('.otf') || nameLower.endsWith('.ttf'))) {
        final iconLoader = FontLoader('MaterialIcons');
        final bytes = file.readAsBytesSync();
        iconLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
        await iconLoader.load();
        break;
      }
    }
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

import 'dart:io';

import 'package:flutter/services.dart';

/// Whether `--dart-define=SCREENSHOTS=true` was passed; image tests skip otherwise.
const screenshotsEnabled = bool.fromEnvironment('SCREENSHOTS');

/// Loads the real app fonts and Material icons, which widget tests replace
/// with a placeholder font by default.
Future<void> loadAppFonts() async {
  Future<void> load(String family, Future<ByteData> data) async {
    await (FontLoader(family)..addFont(data)).load();
  }

  await load('Inter', rootBundle.load('assets/fonts/Inter-Variable.ttf'));
  await load('Vazirmatn', rootBundle.load('assets/fonts/Vazirmatn-Variable.ttf'));
  await load('Cinzel', rootBundle.load('assets/fonts/Cinzel-Variable.ttf'));
  final root = Platform.environment['FLUTTER_ROOT']!;
  final icons = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').readAsBytesSync();
  await load('MaterialIcons', Future.value(ByteData.sublistView(icons)));
}

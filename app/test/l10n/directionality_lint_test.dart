import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Layouts must use logical directions only (localization guide §3).
void main() {
  test('no physical left/right in UI code', () {
    final banned = <RegExp>[
      RegExp(r'EdgeInsets\.only\([^)]*\b(left|right):'),
      RegExp(r'EdgeInsets\.fromLTRB'),
      RegExp(r'TextAlign\.(left|right)\b'),
      RegExp(r'Alignment\.(centerLeft|centerRight|topLeft|topRight|bottomLeft|bottomRight)\b'),
      RegExp(r'Positioned\([^)]*\b(left|right):'),
      RegExp(r'BorderRadius\.only\([^)]*\b(topLeft|topRight|bottomLeft|bottomRight):'),
    ];
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.contains('/generated/') || f.path.endsWith('.g.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (banned.any((r) => r.hasMatch(lines[i]))) offenders.add('${f.path}:${i + 1}: ${lines[i].trim()}');
      }
    }
    expect(offenders, isEmpty);
  });
}

// Renders the README banner and showcase art from the real app screens,
// fonts and design tokens. Run after readme_screenshots_test.dart, which
// produces the phone screenshots these images frame:
//
//   flutter test --dart-define=SCREENSHOTS=true --update-goldens test/screenshots
//
// Skipped in normal test runs. Output: docs/assets/*.png at the repo root.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wyrd/design/components/background.dart';
import 'package:wyrd/design/theme.dart';
import 'package:wyrd/design/tokens.dart';

import 'support.dart';

const _shots = '../docs/screenshots';
const _out = '../../../docs/assets';
const _dpr = 1.5;

MemoryImage _shot(String name) => MemoryImage(File('$_shots/$name.png').readAsBytesSync());

Future<void> _render(WidgetTester tester, Size size, Palette palette, Widget art, String name) async {
  tester.view.devicePixelRatio = _dpr;
  tester.view.physicalSize = size * _dpr;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(debugShowCheckedModeBanner: false, theme: buildAppTheme(const Locale('en'), palette), home: art),
  );
  // Decode every framed screenshot before capturing.
  await tester.runAsync(() async {
    for (final e in tester.widgetList<Image>(find.byType(Image))) {
      await precacheImage(e.image, tester.element(find.byType(Scaffold)));
    }
  });
  await tester.pump();
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('$_out/$name.png'));
}

void main() {
  setUpAll(() async {
    if (screenshotsEnabled) await loadAppFonts();
  });

  for (final dark in [true, false]) {
    final t = dark ? 'dark' : 'light';
    testWidgets('banner ($t)', skip: !screenshotsEnabled, (tester) async {
      await _render(
        tester,
        const Size(1280, 640),
        dark ? Palette.dark : Palette.light,
        _Banner(front: _shot('phone-character-$t-en'), back: _shot(dark ? 'phone-reward-$t-en' : 'phone-quests-$t-en')),
        'banner-$t',
      );
    });
  }

  testWidgets('light and dark showcase', skip: !screenshotsEnabled, (tester) async {
    await _render(
      tester,
      const Size(1280, 720),
      Palette.dark,
      _Themes(dark: _shot('phone-character-dark-en'), light: _shot('phone-character-light-fa')),
      'themes',
    );
  });
}

/// Wordmark, promise and platforms on the start side; two phones on the end.
class _Banner extends StatelessWidget {
  const _Banner({required this.front, required this.back});

  final ImageProvider front;
  final ImageProvider back;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: AppBackground(
        child: Stack(
          children: [
            PositionedDirectional(
              start: 84,
              top: 0,
              bottom: 0,
              width: 600,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'A DARK-FANTASY RPG FOR REAL LIFE',
                    style: text.labelSmall?.copyWith(fontSize: 15, letterSpacing: 3.2, color: p.accent),
                  ),
                  const SizedBox(height: 10),
                  ShaderMask(
                    shaderCallback: (r) => AppGradients.emberDiagonal.createShader(r, textDirection: TextDirection.ltr),
                    child: Text(
                      'Wyrd',
                      style: text.displayLarge?.copyWith(
                        fontSize: 136,
                        height: 1.05,
                        letterSpacing: 8,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Your character is who you become.',
                    style: text.headlineSmall?.copyWith(fontSize: 30, height: 1.25),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Quests and habits become XP, six attributes and a living chronicle. '
                    'AI proposes, honest rules decide, and every reward explains itself.',
                    style: text.bodyLarge?.copyWith(fontSize: 19, height: 1.55),
                  ),
                  const SizedBox(height: 30),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _Chip('Android · iOS · Web', Icons.devices_rounded, p.accent),
                      _Chip('English · فارسی', Icons.translate_rounded, p.arcane),
                      _Chip('Light & dark', Icons.contrast_rounded, p.gold),
                      _Chip('Bring your own AI', Icons.auto_awesome_rounded, p.success),
                    ],
                  ),
                ],
              ),
            ),
            PositionedDirectional(
              end: 262,
              top: 86,
              child: Transform.rotate(angle: -0.11, child: _Phone(back, width: 236)),
            ),
            PositionedDirectional(
              end: 64,
              top: 36,
              child: Transform.rotate(angle: 0.05, child: _Phone(front, width: 268)),
            ),
          ],
        ),
      ),
    );
  }
}

/// The same character in both themes, split along a diagonal.
class _Themes extends StatelessWidget {
  const _Themes({required this.dark, required this.light});

  final ImageProvider dark;
  final ImageProvider light;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Theme(data: buildAppTheme(const Locale('en'), Palette.dark), child: _Half(dark, 'ASHEN CODEX · DARK')),
          ClipPath(
            clipper: _Diagonal(),
            child: Theme(
              data: buildAppTheme(const Locale('en'), Palette.light),
              child: _Half(light, 'VELLUM · LIGHT', end: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _Half extends StatelessWidget {
  const _Half(this.image, this.label, {this.end = false});

  final ImageProvider image;
  final String label;
  final bool end;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 15, letterSpacing: 3, color: p.accent);
    return AppBackground(
      child: Stack(
        children: [
          PositionedDirectional(
            start: end ? 760 : 232,
            top: 44,
            child: Transform.rotate(angle: end ? 0.04 : -0.04, child: _Phone(image, width: 270)),
          ),
          PositionedDirectional(
            start: end ? 1000 : 40,
            top: 668,
            width: 240,
            child: Text(label, style: style, textAlign: end ? TextAlign.end : TextAlign.start),
          ),
        ],
      ),
    );
  }
}

class _Diagonal extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width * 0.58, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(size.width * 0.42, size.height)
    ..close();

  @override
  bool shouldReclip(_Diagonal oldClipper) => false;
}

/// A phone frame: dark bezel, rounded screen and a small island.
class _Phone extends StatelessWidget {
  const _Phone(this.image, {required this.width});

  final ImageProvider image;
  final double width;

  @override
  Widget build(BuildContext context) {
    final height = width * 844 / 390;
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0D12),
        borderRadius: BorderRadius.circular(width * 0.16),
        border: Border.all(color: const Color(0xFF3B4152), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x73000000), blurRadius: 48, offset: Offset(0, 26), spreadRadius: -8)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(width * 0.13),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Image(image: image, width: width, height: height, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: width * 0.24,
                height: 18,
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(9)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A larger version of the app's Pill, sized for a banner.
class _Chip extends StatelessWidget {
  const _Chip(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: AppRadius.pillAll,
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 15, color: color)),
      ],
    ),
  );
}

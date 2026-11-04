import 'package:flutter/widgets.dart';

/// Direction of user-authored text from its first strong character
/// (Unicode "first strong" rule), independent of the UI language, so a
/// Persian quest title reads correctly in the English UI and vice versa.
TextDirection? userTextDirection(String text) {
  for (final r in text.runes) {
    if (_isRtl(r)) return TextDirection.rtl;
    if (_isLtr(r)) return TextDirection.ltr;
  }
  return null;
}

bool _isRtl(int r) =>
    (r >= 0x0590 && r <= 0x08FF) || // Hebrew, Arabic, Syriac, Thaana, NKo, Arabic ext.
    (r >= 0xFB1D && r <= 0xFDFF) || // Hebrew/Arabic presentation forms A
    (r >= 0xFE70 && r <= 0xFEFF); // Arabic presentation forms B

bool _isLtr(int r) =>
    (r >= 0x41 && r <= 0x5A) ||
    (r >= 0x61 && r <= 0x7A) ||
    (r >= 0x00C0 && r <= 0x024F) || // Latin-1 supplement & extended
    (r >= 0x0370 && r <= 0x03FF) || // Greek
    (r >= 0x0400 && r <= 0x04FF); // Cyrillic

/// Text for user-authored content with automatic direction.
class UserText extends StatelessWidget {
  const UserText(this.text, {super.key, this.style, this.maxLines, this.overflow});

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final dir = userTextDirection(text) ?? Directionality.of(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      child: Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textDirection: dir,
        textAlign: dir == Directionality.of(context) ? TextAlign.start : TextAlign.end,
      ),
    );
  }
}

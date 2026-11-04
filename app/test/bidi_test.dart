import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wyrd/core/format/bidi.dart';

void main() {
  test('first strong character decides direction', () {
    expect(userTextDirection('۳۰ دقیقه مطالعه'), TextDirection.rtl);
    expect(userTextDirection('30 min study'), TextDirection.ltr);
    expect(userTextDirection('Python تمرین'), TextDirection.ltr);
    expect(userTextDirection('مطالعه Python'), TextDirection.rtl);
    expect(userTextDirection('123 456'), isNull);
  });
}

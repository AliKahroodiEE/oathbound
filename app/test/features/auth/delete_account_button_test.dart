import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wyrd/app/providers.dart';
import 'package:wyrd/data/repositories/data_repository.dart';
import 'package:wyrd/features/auth/auth_gateway.dart';
import 'package:wyrd/features/auth/delete_account_button.dart';

import 'fake_auth_gateway.dart';

/// Remembers whether the device copy was wiped.
class _FakeData implements DataRepository {
  bool wiped = false;

  @override
  Future<void> wipe() async => wiped = true;

  @override
  Future<Map<String, Object?>> exportAll() async => const {};
}

void main() {
  Future<(FakeAuthGateway, _FakeData)> pump(WidgetTester tester) async {
    final gateway = FakeAuthGateway();
    final data = _FakeData();
    await pumpPage(
      tester,
      const Scaffold(body: Center(child: DeleteAccountButton())),
      overrides: [authGatewayProvider.overrideWithValue(gateway), dataRepositoryProvider.overrideWithValue(data)],
    );
    return (gateway, data);
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.text('Delete account'));
    await settle(tester);
    expect(find.textContaining('This permanently deletes your account'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete account'));
    await settle(tester);
  }

  testWidgets('cancelling keeps everything', (tester) async {
    final (gateway, data) = await pump(tester);
    await tester.tap(find.text('Delete account'));
    await settle(tester);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(gateway.calls, isEmpty);
    expect(data.wiped, isFalse);
  });

  testWidgets('deletes on the server, signs out, wipes the device and starts over', (tester) async {
    final (gateway, data) = await pump(tester);
    await confirm(tester);
    expect(gateway.calls, ['deleteAccount', 'signOut']);
    expect(data.wiped, isTrue);
    expect(find.text('onboarding page'), findsOneWidget);
    expect(find.text('Your account has been deleted.'), findsOneWidget);
  });

  testWidgets('a failed deletion keeps the account and the local data', (tester) async {
    final (gateway, data) = await pump(tester);
    gateway.failWith = StateError('database unavailable');
    await confirm(tester);
    expect(gateway.calls, ['deleteAccount']);
    expect(data.wiped, isFalse);
    expect(find.text('Something went wrong on our side. Your data is safe.'), findsOneWidget);
    final button = find.ancestor(of: find.text('Delete account'), matching: find.bySubtype<TextButton>());
    expect(tester.widget<TextButton>(button).onPressed, isNotNull, reason: 'ready to try again');
  });
}

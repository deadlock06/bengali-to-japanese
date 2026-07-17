// C3 proof: StatePack renders each state and the error retry fires.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensei_app/presentation/state_pack.dart';

void main() {
  Future<void> pump(WidgetTester t, Widget w) =>
      t.pumpWidget(MaterialApp(home: Scaffold(body: w)));

  testWidgets('loading shows spinner + optional line', (t) async {
    await pump(t, const StatePack.loading(bn: 'লোড হচ্ছে…'));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('লোড হচ্ছে…'), findsOneWidget);
  });

  testWidgets('empty is framed as a next step', (t) async {
    await pump(t, const StatePack.empty(title: 'কিছু নেই', body: 'একটা পাঠ করো'));
    expect(find.text('কিছু নেই'), findsOneWidget);
    expect(find.text('একটা পাঠ করো'), findsOneWidget);
  });

  testWidgets('error offers a working retry', (t) async {
    var retried = false;
    await pump(t, StatePack.error(onRetry: () => retried = true));
    expect(find.text('আবার চেষ্টা'), findsOneWidget);
    await t.tap(find.text('আবার চেষ্টা'));
    expect(retried, true);
  });

  testWidgets('offline reassures the core works offline', (t) async {
    await pump(t, const StatePack.offline());
    expect(find.textContaining('ইন্টারনেট ছাড়াই চলে'), findsOneWidget);
  });
}

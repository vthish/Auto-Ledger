import 'package:flutter_test/flutter_test.dart';

import 'package:auto_ledger_police/main.dart';

void main() {
  testWidgets('shows police login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AutoLedgerPoliceApp());

    expect(find.text('Auto-Ledger'), findsOneWidget);
    expect(find.text('Police Officer Portal'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
import 'package:flutter_test/flutter_test.dart';

import 'package:interface_stage/main.dart';

void main() {
  testWidgets('dashboard starts without forcing the QR scanner route',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('CS Ahomey Lokpo'), findsOneWidget);
    expect(find.text('Scan QR + Token'), findsNothing);
    expect(find.text('Scan QR Token'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:interface_stage/app/routes.dart';
import 'package:interface_stage/main.dart';

void main() {
  testWidgets('app starts on the QR scanner route before dashboard',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Scan QR + Token'), findsOneWidget);
    expect(find.text('CS Ahomey Lokpo'), findsNothing);
  });

  test('dashboard route remains available after token validation', () {
    expect(AppRoutes.routes.containsKey(AppRoutes.dashboard), isTrue);
    expect(AppRoutes.routes.containsKey(AppRoutes.qrTokenValidation), isTrue);
  });
}

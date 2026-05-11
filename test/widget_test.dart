import 'package:flutter_test/flutter_test.dart';

import 'package:interface_stage/app/routes.dart';
import 'package:interface_stage/main.dart';

void main() {

      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();


  });
}

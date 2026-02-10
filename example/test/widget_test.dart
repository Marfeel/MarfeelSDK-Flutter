import 'package:flutter_test/flutter_test.dart';

import 'package:marfeel_sdk_example/main.dart';

void main() {
  testWidgets('App renders bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const MarfeelExampleApp());
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Video'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}

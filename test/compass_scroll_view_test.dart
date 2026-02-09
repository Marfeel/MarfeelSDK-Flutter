import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marfeel_sdk/marfeel_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.marfeel.sdk/compass'),
      (call) async => null,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.marfeel.sdk/compass'),
      null,
    );
  });

  testWidgets('CompassScrollView renders children', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CompassScrollView(
            child: Text('Hello'),
          ),
        ),
      ),
    );
    expect(find.text('Hello'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('CompassScrollView passes scroll properties', (tester) async {
    final controller = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompassScrollView(
            controller: controller,
            padding: const EdgeInsets.all(16),
            child: const Text('Content'),
          ),
        ),
      ),
    );
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('CompassScrollView reports scroll percentage', (tester) async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.marfeel.sdk/compass'),
      (call) async {
        calls.add(call);
        return null;
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompassScrollView(
            child: Column(
              children: List.generate(
                  100, (i) => SizedBox(height: 100, child: Text('Item $i'))),
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    final scrollCalls = calls
        .where((c) => c.method == 'updateScrollPercentage')
        .toList();
    expect(scrollCalls, isNotEmpty);
    final lastPercentage =
        (scrollCalls.last.arguments as Map)['percentage'] as int;
    expect(lastPercentage, greaterThan(0));
    expect(lastPercentage, lessThanOrEqualTo(100));
  });
}

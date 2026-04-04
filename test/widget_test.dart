import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_isolates/main.dart';

void main() {
  testWidgets('loads the main thread fibonacci page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Main-isolate Fibonacci'), findsOneWidget);
    expect(find.byKey(const Key('fibonacci-input-field')), findsOneWidget);
    expect(
      find.byKey(const Key('calculate-main-thread-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('calculate-isolate-run-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('loading-skeleton')),
      findsOneWidget,
    );
  });
}

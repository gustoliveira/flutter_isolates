import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_isolates/main_thread_fibonacci_page.dart';

void main() {
  Widget createPage() {
    return const MaterialApp(home: MainThreadFibonacciPage());
  }

  testWidgets('shows the animated skeleton as soon as page loads', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createPage());

    expect(
      find.byKey(const ValueKey<String>('loading-skeleton')),
      findsOneWidget,
    );
  });

  testWidgets('shows input validation for non-integer values', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createPage());

    await tester.enterText(
      find.byKey(const Key('fibonacci-input-field')),
      'abc',
    );
    await tester.tap(find.byKey(const Key('calculate-main-thread-button')));
    await tester.pump();

    expect(find.text('Please enter a valid integer.'), findsOneWidget);
  });

  testWidgets('keeps skeleton visible while calculating and after result', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createPage());

    expect(
      find.byKey(const ValueKey<String>('loading-skeleton')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('fibonacci-input-field')),
      '10',
    );
    await tester.tap(find.byKey(const Key('calculate-main-thread-button')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('loading-skeleton')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('fibonacci-calculating-text')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('loading-skeleton')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('fibonacci-result-text')), findsOneWidget);
    expect(find.text('fib(10) = 55'), findsOneWidget);
    expect(find.byKey(const Key('fibonacci-elapsed-text')), findsOneWidget);
  });
}

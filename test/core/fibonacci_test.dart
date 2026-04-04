import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_isolates/fibonacci.dart';

void main() {
  group('fibonacciRecursive', () {
    test('returns base values for 0 and 1', () {
      expect(fibonacciRecursive(0), 0);
      expect(fibonacciRecursive(1), 1);
    });

    test('returns expected values for known inputs', () {
      expect(fibonacciRecursive(2), 1);
      expect(fibonacciRecursive(5), 5);
      expect(fibonacciRecursive(10), 55);
    });

    test('throws for negative input', () {
      expect(() => fibonacciRecursive(-1), throwsRangeError);
    });
  });

  group('parseFibonacciInput', () {
    test('parses a valid integer input', () {
      expect(parseFibonacciInput('8'), 8);
      expect(parseFibonacciInput(' 13 '), 13);
    });

    test('throws FormatException for non-integer input', () {
      expect(
        () => parseFibonacciInput('not-a-number'),
        throwsA(isA<FormatException>()),
      );
      expect(() => parseFibonacciInput('4.2'), throwsA(isA<FormatException>()));
    });

    test('throws RangeError when input is outside default range', () {
      expect(() => parseFibonacciInput('-1'), throwsRangeError);
      expect(() => parseFibonacciInput('101'), throwsRangeError);
    });

    test('accepts values based on custom min and max', () {
      expect(parseFibonacciInput('20', min: 10, max: 30), 20);
      expect(
        () => parseFibonacciInput('9', min: 10, max: 30),
        throwsRangeError,
      );
      expect(
        () => parseFibonacciInput('31', min: 10, max: 30),
        throwsRangeError,
      );
    });
  });
}

const int kMaxRecommendedFibonacciInput = 100;

int parseFibonacciInput(
  String input, {
  int min = 0,
  int max = kMaxRecommendedFibonacciInput,
}) {
  final value = int.tryParse(input.trim());
  if (value == null) {
    throw const FormatException('Please enter a valid integer.');
  }
  if (value < min || value > max) {
    throw RangeError.range(value, min, max, 'n');
  }
  return value;
}

int fibonacciRecursive(int n) {
  if (n < 0) {
    throw RangeError.value(n, 'n', 'Must be greater than or equal to 0.');
  }
  if (n <= 1) {
    return n;
  }
  return fibonacciRecursive(n - 1) + fibonacciRecursive(n - 2);
}

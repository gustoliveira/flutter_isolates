import 'dart:isolate';

import 'package:flutter_isolates/core/fibonacci.dart';

Future<int> fibonacciWithIsolateRun(int n) {
  return Isolate.run<int>(() => fibonacciRecursive(n));
}

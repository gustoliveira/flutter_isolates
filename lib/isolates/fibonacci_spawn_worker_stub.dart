void fibonacciWorkerEntryPoint(Object _) {
  throw UnsupportedError('Worker isolates are not available on this platform.');
}

class FibonacciSpawnWorker {
  Future<void> start() async {
    throw UnsupportedError(
      'Isolate.spawn workers are not supported on Flutter Web in this demo.',
    );
  }

  Future<int> calculate(int n) async {
    throw UnsupportedError(
      'Isolate.spawn workers are not supported on Flutter Web in this demo.',
    );
  }

  void dispose() {}
}

import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_isolates/fibonacci_spawn_worker.dart';

void main() {
  group('FibonacciSpawnWorker', () {
    late FibonacciSpawnWorker worker;

    setUp(() {
      worker = FibonacciSpawnWorker();
    });

    tearDown(() {
      worker.dispose();
    });

    test('calculates fibonacci using a spawned worker isolate', () async {
      final int result = await worker.calculate(10);
      expect(result, 55);
    });

    test(
      'handles multiple sequential calculations on the same worker',
      () async {
        expect(await worker.calculate(8), 21);
        expect(await worker.calculate(11), 89);
      },
    );

    test('throws a worker error for invalid input', () async {
      expect(() => worker.calculate(-1), throwsA(isA<StateError>()));
    });

    test(
      'worker entrypoint guards malformed messages and stays responsive',
      () async {
        final ReceivePort readyPort = ReceivePort();
        final Isolate isolate = await Isolate.spawn(
          fibonacciWorkerEntryPoint,
          readyPort.sendPort,
        );

        final SendPort workerPort = await readyPort.first as SendPort;
        readyPort.close();

        workerPort.send(123);
        workerPort.send(<Object>[10]);
        workerPort.send(<Object>[10, 'not-a-send-port']);

        final ReceivePort invalidPayloadPort = ReceivePort();
        workerPort.send(<Object>['invalid', invalidPayloadPort.sendPort]);

        final dynamic invalidPayloadResponse = await invalidPayloadPort.first
            .timeout(const Duration(seconds: 1));
        invalidPayloadPort.close();

        expect(invalidPayloadResponse, isA<List<dynamic>>());
        final List<dynamic> invalidList =
            invalidPayloadResponse as List<dynamic>;
        expect(invalidList.first, 'error');

        final ReceivePort validResponsePort = ReceivePort();
        workerPort.send(<Object>[10, validResponsePort.sendPort]);
        final dynamic validResponse = await validResponsePort.first.timeout(
          const Duration(seconds: 1),
        );
        validResponsePort.close();

        expect(validResponse, 55);

        workerPort.send('shutdown');
        isolate.kill(priority: Isolate.immediate);
      },
    );
  });
}

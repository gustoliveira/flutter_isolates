import 'dart:async';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_isolates/isolates/fibonacci_spawn_worker.dart';

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
        final ReceivePort responsePort = ReceivePort();
        final StreamIterator<dynamic> responses = StreamIterator<dynamic>(
          responsePort,
        );

        final Isolate isolate = await Isolate.spawn(
          fibonacciWorkerEntryPoint,
          <Object>[readyPort.sendPort, responsePort.sendPort],
        );

        final SendPort workerPort = await readyPort.first as SendPort;
        readyPort.close();

        workerPort.send(123);
        workerPort.send(<Object>[10]);
        workerPort.send(<Object>['not-an-id', 10]);
        workerPort.send(<Object>[1, 'invalid']);

        final bool hasErrorResponse = await responses.moveNext().timeout(
          const Duration(seconds: 1),
        );
        expect(hasErrorResponse, isTrue);

        final dynamic invalidPayloadResponse = responses.current;
        expect(invalidPayloadResponse, isA<List<dynamic>>());
        final List<dynamic> invalidList =
            invalidPayloadResponse as List<dynamic>;
        expect(invalidList.length, 3);
        expect(invalidList[0], 'error');
        expect(invalidList[1], 1);

        workerPort.send(<Object>[2, 10]);

        final bool hasValidResponse = await responses.moveNext().timeout(
          const Duration(seconds: 1),
        );
        expect(hasValidResponse, isTrue);

        final dynamic validResponse = responses.current;
        expect(validResponse, isA<List<dynamic>>());
        final List<dynamic> validList = validResponse as List<dynamic>;
        expect(validList.length, 2);
        expect(validList[0], 2);
        expect(validList[1], 55);

        workerPort.send('shutdown');
        await responses.cancel();
        responsePort.close();
        isolate.kill(priority: Isolate.immediate);
      },
    );
  });
}

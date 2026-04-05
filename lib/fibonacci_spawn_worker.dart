import 'dart:isolate';

import 'package:flutter_isolates/fibonacci.dart';

const String _shutdownMessage = 'shutdown';

void fibonacciWorkerEntryPoint(SendPort mainSendPort) {
  final ReceivePort commandPort = ReceivePort();
  mainSendPort.send(commandPort.sendPort);

  commandPort.listen((dynamic message) {
    if (message is String && message == _shutdownMessage) {
      commandPort.close();
      Isolate.exit();
    }

    if (message is String) {
      return;
    }

    if (message is! List<dynamic> || message.length != 2) {
      return;
    }

    final dynamic rawInput = message[0];
    final dynamic rawReplyPort = message[1];

    if (rawReplyPort is! SendPort) {
      return;
    }

    if (rawInput is! int) {
      rawReplyPort.send(<Object>['error', 'Invalid request payload.']);
      return;
    }

    try {
      final int result = fibonacciRecursive(rawInput);
      rawReplyPort.send(result);
    } catch (error) {
      rawReplyPort.send(<Object>['error', error.toString()]);
    }
  });
}

class FibonacciSpawnWorker {
  Isolate? _isolate;
  SendPort? _sendPort;
  Future<void>? _startFuture;

  Future<void> start() {
    if (_sendPort != null) {
      return Future<void>.value();
    }
    _startFuture ??= _startInternal();
    return _startFuture!;
  }

  Future<int> calculate(int n) async {
    await start();

    final SendPort? workerPort = _sendPort;
    if (workerPort == null) {
      throw StateError('Worker isolate is not available.');
    }

    final ReceivePort responsePort = ReceivePort();
    workerPort.send(<Object>[n, responsePort.sendPort]);

    final dynamic response = await responsePort.first;
    responsePort.close();

    if (response is int) {
      return response;
    }

    if (response is List<dynamic> && response.length == 2) {
      final dynamic type = response[0];
      final dynamic message = response[1];
      if (type == 'error') {
        throw StateError(message.toString());
      }
    }

    throw StateError('Unexpected worker response.');
  }

  void dispose() {
    _sendPort?.send(_shutdownMessage);
    _isolate?.kill(priority: Isolate.immediate);
    _sendPort = null;
    _isolate = null;
    _startFuture = null;
  }

  Future<void> _startInternal() async {
    final ReceivePort readyPort = ReceivePort();

    _isolate = await Isolate.spawn(
      fibonacciWorkerEntryPoint,
      readyPort.sendPort,
    );
    final dynamic firstMessage = await readyPort.first;
    readyPort.close();

    if (firstMessage is! SendPort) {
      throw StateError('Failed to initialize worker isolate.');
    }

    _sendPort = firstMessage;
  }
}

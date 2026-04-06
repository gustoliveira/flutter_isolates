import 'dart:async';
import 'dart:isolate';

import 'package:flutter_isolates/core/fibonacci.dart';

const String _shutdownMessage = 'shutdown';
const String _errorMessage = 'error';

void fibonacciWorkerEntryPoint(Object initialMessage) {
  if (initialMessage is! List<dynamic> || initialMessage.length != 2) {
    return;
  }

  final dynamic rawMainSendPort = initialMessage[0];
  final dynamic rawResponseSendPort = initialMessage[1];

  if (rawMainSendPort is! SendPort || rawResponseSendPort is! SendPort) {
    return;
  }

  final SendPort mainSendPort = rawMainSendPort;
  final SendPort responseSendPort = rawResponseSendPort;
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

    final dynamic rawRequestId = message[0];
    final dynamic rawInput = message[1];

    if (rawRequestId is! int) {
      return;
    }

    if (rawInput is! int) {
      responseSendPort.send(<Object>[
        _errorMessage,
        rawRequestId,
        'Invalid request payload.',
      ]);
      return;
    }

    try {
      final int result = fibonacciRecursive(rawInput);
      responseSendPort.send(<Object>[rawRequestId, result]);
    } catch (error) {
      responseSendPort.send(<Object>[
        _errorMessage,
        rawRequestId,
        error.toString(),
      ]);
    }
  });
}

class FibonacciSpawnWorker {
  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _responsePort;
  StreamSubscription<dynamic>? _responseSubscription;
  Future<void>? _startFuture;
  final Map<int, Completer<int>> _pendingRequests = <int, Completer<int>>{};
  int _nextRequestId = 0;
  bool _disposed = false;

  Future<void> start() {
    if (_disposed) {
      throw StateError('Worker isolate was disposed.');
    }

    if (_sendPort != null) {
      return Future<void>.value();
    }

    _startFuture ??= _startInternal();
    return _startFuture!;
  }

  Future<int> calculate(int n) async {
    if (_disposed) {
      throw StateError('Worker isolate was disposed.');
    }

    await start();

    final SendPort? workerPort = _sendPort;
    if (workerPort == null) {
      throw StateError('Worker isolate is not available.');
    }

    final int requestId = _nextRequestId++;
    final Completer<int> completer = Completer<int>();
    _pendingRequests[requestId] = completer;

    try {
      workerPort.send(<Object>[requestId, n]);
    } catch (error, stackTrace) {
      _pendingRequests.remove(requestId);
      completer.completeError(error, stackTrace);
    }

    return completer.future;
  }

  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;
    _sendPort?.send(_shutdownMessage);

    _completePendingWithError(StateError('Worker isolate was disposed.'));

    _responseSubscription?.cancel();
    _responsePort?.close();
    _isolate?.kill(priority: Isolate.immediate);

    _sendPort = null;
    _isolate = null;
    _responseSubscription = null;
    _responsePort = null;
    _startFuture = null;
  }

  Future<void> _startInternal() async {
    final ReceivePort readyPort = ReceivePort();
    final ReceivePort responsePort = ReceivePort();

    _responsePort = responsePort;
    _responseSubscription = responsePort.listen(_handleWorkerResponse);

    try {
      _isolate = await Isolate.spawn(fibonacciWorkerEntryPoint, <Object>[
        readyPort.sendPort,
        responsePort.sendPort,
      ]);
      final dynamic firstMessage = await readyPort.first;

      if (firstMessage is! SendPort) {
        throw StateError('Failed to initialize worker isolate.');
      }

      _sendPort = firstMessage;
    } catch (_) {
      _responseSubscription?.cancel();
      _responseSubscription = null;
      _responsePort?.close();
      _responsePort = null;
      _isolate?.kill(priority: Isolate.immediate);
      _isolate = null;
      _sendPort = null;
      _startFuture = null;
      rethrow;
    } finally {
      readyPort.close();
    }
  }

  void _handleWorkerResponse(dynamic response) {
    if (response is! List<dynamic> || response.length < 2) {
      return;
    }

    if (response.length == 2 && response[0] is int) {
      final int requestId = response[0] as int;
      final Completer<int>? completer = _pendingRequests.remove(requestId);
      if (completer == null || completer.isCompleted) {
        return;
      }

      final dynamic rawValue = response[1];
      if (rawValue is int) {
        completer.complete(rawValue);
      } else {
        completer.completeError(StateError('Unexpected worker response.'));
      }
      return;
    }

    if (response.length == 3 && response[0] == _errorMessage) {
      final dynamic rawRequestId = response[1];
      final dynamic rawMessage = response[2];

      if (rawRequestId is! int) {
        return;
      }

      final Completer<int>? completer = _pendingRequests.remove(rawRequestId);
      if (completer == null || completer.isCompleted) {
        return;
      }

      completer.completeError(StateError(rawMessage.toString()));
    }
  }

  void _completePendingWithError(Object error) {
    for (final Completer<int> completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    }
    _pendingRequests.clear();
  }
}

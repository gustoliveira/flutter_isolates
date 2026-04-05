import 'package:flutter/material.dart';
import 'package:flutter_isolates/fibonacci.dart';
import 'package:flutter_isolates/fibonacci_spawn_worker.dart';
import 'package:flutter_isolates/loading_skeleton.dart';

enum _CalculationMode { mainThread, isolateRun, spawnWorker }

class MainThreadFibonacciPage extends StatefulWidget {
  const MainThreadFibonacciPage({super.key});

  @override
  State<MainThreadFibonacciPage> createState() =>
      _MainThreadFibonacciPageState();
}

class _MainThreadFibonacciPageState extends State<MainThreadFibonacciPage> {
  final TextEditingController _inputController = TextEditingController(
    text: '45',
  );
  final FibonacciSpawnWorker _spawnWorker = FibonacciSpawnWorker();

  bool _isCalculating = false;
  String? _inputError;
  int? _lastInput;
  int? _lastResult;
  Duration? _elapsed;
  _CalculationMode? _lastCompletedMode;
  _CalculationMode? _activeMode;
  final Map<_CalculationMode, Duration> _elapsedByMode =
      <_CalculationMode, Duration>{};

  @override
  void dispose() {
    _spawnWorker.dispose();
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _calculateOnMainThread() async {
    await _runCalculation(_CalculationMode.mainThread);
  }

  Future<void> _calculateWithIsolateRun() async {
    await _runCalculation(_CalculationMode.isolateRun);
  }

  Future<void> _calculateWithSpawnWorker() async {
    await _runCalculation(_CalculationMode.spawnWorker);
  }

  Future<void> _runCalculation(_CalculationMode mode) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final String rawInput = _inputController.text;
    final int value;

    try {
      value = parseFibonacciInput(rawInput);
    } on FormatException catch (error) {
      setState(() {
        _inputError = error.message;
      });
      return;
    } on RangeError {
      setState(() {
        _inputError =
            'Please enter a number between 0 and $kMaxRecommendedFibonacciInput.';
      });
      return;
    }

    setState(() {
      _inputError = null;
      _isCalculating = true;
      _activeMode = mode;
      _lastInput = value;
      _lastResult = null;
      _elapsed = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 80));

    final Stopwatch stopwatch = Stopwatch()..start();
    final int result;
    if (mode == _CalculationMode.mainThread) {
      result = fibonacciRecursive(value);
    } else if (mode == _CalculationMode.isolateRun) {
      result = await fibonacciWithIsolateRun(value);
    } else {
      result = await _spawnWorker.calculate(value);
    }
    stopwatch.stop();

    if (!mounted) {
      return;
    }

    setState(() {
      _isCalculating = false;
      _activeMode = null;
      _lastCompletedMode = mode;
      _lastResult = result;
      _elapsed = stopwatch.elapsed;
      _elapsedByMode[mode] = stopwatch.elapsed;
    });
  }

  String _formatElapsed(Duration elapsed) {
    return '${elapsed.inMilliseconds} ms';
  }

  String _modeLabel(_CalculationMode mode) {
    switch (mode) {
      case _CalculationMode.mainThread:
        return 'Main Thread';
      case _CalculationMode.isolateRun:
        return 'Isolate.run';
      case _CalculationMode.spawnWorker:
        return 'Isolate.spawn + ports';
    }
  }

  String _activeModeDescription() {
    switch (_activeMode) {
      case _CalculationMode.mainThread:
        return 'Calculating on the main thread. The skeleton may freeze for large n.';
      case _CalculationMode.isolateRun:
        return 'Calculating with Isolate.run. The skeleton should stay smooth.';
      case _CalculationMode.spawnWorker:
        return 'Calculating with Isolate.spawn + ports. The skeleton should stay smooth.';
      case null:
        return 'The skeleton above runs continuously to highlight UI jank during heavy work.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Fibonacci POC - Strategy Comparison')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Main-isolate Fibonacci',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This version runs the recursive calculation on the main '
                    'thread, with Isolate.run, and with a persistent '
                    'Isolate.spawn worker using ports. Compare elapsed time and '
                    'skeleton smoothness across strategies.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    key: const Key('fibonacci-input-field'),
                    controller: _inputController,
                    enabled: !_isCalculating,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Integer n',
                      hintText: '0 to $kMaxRecommendedFibonacciInput',
                      errorText: _inputError,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('calculate-main-thread-button'),
                      onPressed: _isCalculating ? null : _calculateOnMainThread,
                      icon: const Icon(Icons.functions),
                      label: const Text('Calculate on Main Thread'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      key: const Key('calculate-isolate-run-button'),
                      onPressed: _isCalculating
                          ? null
                          : _calculateWithIsolateRun,
                      icon: const Icon(Icons.rocket_launch_outlined),
                      label: const Text('Calculate with Isolate.run'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      key: const Key('calculate-spawn-worker-button'),
                      onPressed: _isCalculating
                          ? null
                          : _calculateWithSpawnWorker,
                      icon: const Icon(Icons.hub_outlined),
                      label: const Text('Calculate with Isolate.spawn + ports'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const LoadingSkeleton(key: ValueKey('loading-skeleton')),
                  const SizedBox(height: 12),
                  Text(
                    _activeModeDescription(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ResultCard(
                    input: _lastInput,
                    result: _lastResult,
                    elapsedLabel: _elapsed == null
                        ? null
                        : _formatElapsed(_elapsed!),
                    modeLabel: _lastCompletedMode == null
                        ? null
                        : _modeLabel(_lastCompletedMode!),
                    isCalculating: _isCalculating,
                  ),
                  const SizedBox(height: 12),
                  _ComparisonCard(
                    mainThreadElapsed:
                        _elapsedByMode[_CalculationMode.mainThread],
                    isolateRunElapsed:
                        _elapsedByMode[_CalculationMode.isolateRun],
                    spawnWorkerElapsed:
                        _elapsedByMode[_CalculationMode.spawnWorker],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    this.input,
    this.result,
    this.elapsedLabel,
    this.modeLabel,
    this.isCalculating = false,
  });

  final int? input;
  final int? result;
  final String? elapsedLabel;
  final String? modeLabel;
  final bool isCalculating;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (isCalculating && input != null) {
      return Card(
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Calculating fib($input)...',
            key: const Key('fibonacci-calculating-text'),
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    if (input == null || result == null || elapsedLabel == null) {
      return Card(
        color: theme.colorScheme.surface,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Type a number and start a calculation to see the result.',
          ),
        ),
      );
    }

    return Card(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'fib($input) = $result',
              key: const Key('fibonacci-result-text'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (modeLabel != null)
              Text(
                'Strategy: $modeLabel',
                key: const Key('fibonacci-mode-text'),
                style: theme.textTheme.bodyMedium,
              ),
            if (modeLabel != null) const SizedBox(height: 8),
            Text(
              'Elapsed: $elapsedLabel',
              key: const Key('fibonacci-elapsed-text'),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({
    this.mainThreadElapsed,
    this.isolateRunElapsed,
    this.spawnWorkerElapsed,
  });

  final Duration? mainThreadElapsed;
  final Duration? isolateRunElapsed;
  final Duration? spawnWorkerElapsed;

  String _format(Duration? elapsed) {
    if (elapsed == null) {
      return '--';
    }
    return '${elapsed.inMilliseconds} ms';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Latest elapsed by strategy',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            _ComparisonRow(
              label: 'Main Thread',
              value: _format(mainThreadElapsed),
            ),
            const SizedBox(height: 6),
            _ComparisonRow(
              label: 'Isolate.run',
              value: _format(isolateRunElapsed),
            ),
            const SizedBox(height: 6),
            _ComparisonRow(
              label: 'Isolate.spawn + ports',
              value: _format(spawnWorkerElapsed),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

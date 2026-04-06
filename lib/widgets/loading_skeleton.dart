import 'dart:math' as math;

import 'package:flutter/material.dart';

class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({super.key, this.lineCount = 5});

  final int lineCount;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<double> widthFactors = <double>[1.0, 0.94, 0.86, 0.76, 0.61];

    return Card(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List<Widget>.generate(widget.lineCount, (int index) {
                final double phase = (_controller.value + index * 0.12) % 1;
                final double pulse = 0.5 - (phase - 0.5).abs();
                final double glow = math.max(0.0, pulse * 2);

                final Color color =
                    Color.lerp(
                      theme.colorScheme.surfaceContainerHighest,
                      theme.colorScheme.surfaceContainerLow,
                      glow,
                    ) ??
                    theme.colorScheme.surfaceContainerHighest;

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == widget.lineCount - 1 ? 0 : 12,
                  ),
                  child: FractionallySizedBox(
                    widthFactor: widthFactors[index % widthFactors.length],
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: index == 0 ? 20 : 14,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

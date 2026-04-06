import 'package:flutter/material.dart';

import '../config/theme.dart';

class DataThresholdBanner extends StatelessWidget {
  final int seizureDaysLogged;
  final int normalDaysLogged;
  final int minRequired;
  final bool forTTest;

  const DataThresholdBanner({
    super.key,
    required this.seizureDaysLogged,
    required this.normalDaysLogged,
    this.minRequired = 2,
    this.forTTest = false,
  });

  @override
  Widget build(BuildContext context) {
    final needed = forTTest ? 10 : minRequired;
    final seizureRemaining = (needed - seizureDaysLogged).clamp(0, needed);
    final normalRemaining = (needed - normalDaysLogged).clamp(0, needed);
    final ready = seizureDaysLogged >= needed && normalDaysLogged >= needed;

    if (ready) return const SizedBox.shrink();

    final message = forTTest
        ? 'Keep logging to unlock verified trigger insights. '
            '${seizureRemaining > 0 ? '$seizureRemaining more seizure day(s)' : ''}'
            '${seizureRemaining > 0 && normalRemaining > 0 ? ' and ' : ''}'
            '${normalRemaining > 0 ? '$normalRemaining more normal day(s)' : ''} needed.'
        : 'Not enough data yet. '
            '${seizureRemaining > 0 ? '$seizureRemaining more seizure day(s)' : ''}'
            '${seizureRemaining > 0 && normalRemaining > 0 ? ' and ' : ''}'
            '${normalRemaining > 0 ? '$normalRemaining more normal day(s)' : ''} needed.';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.lavenderLight.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.deepPurplePrimary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

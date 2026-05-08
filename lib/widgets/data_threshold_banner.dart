import 'package:flutter/material.dart';

import '../config/theme.dart';

class DataThresholdBanner extends StatelessWidget {
  final int seizureDaysLogged;
  final int normalDaysLogged;
  final int minRequired;
  final bool forTTest;

  // A banner that shows how many more seizure and normal days need to be logged before insights can be unlocked. 
  // If forTTest is true, the threshold is 10 days instead of the default minRequired (which is 2 by default).
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

    // Build the message based on whether this is for T-Test insights or general insights, and how many seizure and normal days are remaining to meet the threshold.
    var message = '';
    if (forTTest) {
      message = 'Keep logging to unlock verified trigger insights. ';
    } else {
      message = 'Not enough data yet. ';
    }

    var extra = '';
    if (seizureRemaining > 0) {
      extra = '$seizureRemaining more seizure day(s)';
    }

    if (seizureRemaining > 0 && normalRemaining > 0) {
      extra += ' and ';
    }

    if (normalRemaining > 0) {
      extra += '$normalRemaining more normal day(s)';
    }

    message += '$extra needed.';

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

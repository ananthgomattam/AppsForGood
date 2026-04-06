import 'package:flutter/material.dart';

import '../services/trigger_service.dart';

class TriggerCard extends StatelessWidget {
  final TriggerResult trigger;

  const TriggerCard({super.key, required this.trigger});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    trigger.factorName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Icon(
                  trigger.isTrigger ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                  color: trigger.isTrigger ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _StatChip(label: 'Seizure avg', value: trigger.seizureAvg.toStringAsFixed(2)),
                const SizedBox(width: 8),
                _StatChip(label: 'Normal avg', value: trigger.normalAvg.toStringAsFixed(2)),
                const SizedBox(width: 8),
                _StatChip(label: 'Difference', value: trigger.difference.toStringAsFixed(2)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              trigger.usedTTest
                  ? 'Method: Welch t-test'
                  : 'Method: Limited-data threshold',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (!trigger.usedTTest)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Keep logging for statistically verified trigger confidence.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF6EAF8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

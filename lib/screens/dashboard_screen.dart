import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const riskLevel = 'Moderate';
    const safetyScore = 0.64;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MetricCard(
            title: 'Today\'s Risk Level',
            value: riskLevel,
            subtitle: 'Prediction based on recent logs and triggers',
          ),
          const SizedBox(height: 12),
          _MetricCard(
            title: 'Safety Score',
            value: safetyScore.toStringAsFixed(2),
            subtitle: 'Closer to 1.00 means lower risk',
          ),
          const SizedBox(height: 12),
          const _MetricCard(
            title: 'Trigger Highlights',
            value: 'Low sleep + high stress',
            subtitle: 'Possible trigger combination detected',
          ),
          const SizedBox(height: 12),
          const _MetricCard(
            title: 'Medication Reminder',
            value: '8:00 PM - Levetiracetam',
            subtitle: 'Next scheduled dose',
          ),
          const SizedBox(height: 16),
          Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionButton(label: 'Log Seizure', route: '/log-seizure'),
              _ActionButton(label: 'Track Triggers', route: '/triggers'),
              _ActionButton(label: 'Medication', route: '/medication'),
              _ActionButton(label: 'Profile', route: '/profile'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(subtitle),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final String route;

  const _ActionButton({required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => Navigator.pushNamed(context, route),
      child: Text(label),
    );
  }
}

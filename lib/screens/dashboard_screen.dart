import 'dart:math';

import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../frontend/account_store.dart';
import '../services/trigger_service.dart';
import '../widgets/data_threshold_banner.dart';
import '../widgets/risk_gauge.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashboardInsights> _future;

  @override
  void initState() {
    super.initState();
    _future = _getInsights();
  }

  Future<void> _signOut(BuildContext context) async {
    await FrontendAccountStore.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Future<_DashboardInsights> _getInsights() async {
    final daily = await DatabaseHelper.instance.getAllDailyLogs();
    final seizure = await DatabaseHelper.instance.getAllSeizureLogs();
    final normal = max(0, daily.length - seizure.length);

    if (daily.length < 10 || seizure.length < 10) {
      return _DashboardInsights.insufficientData(
        dailyCount: daily.length,
        seizureCount: seizure.length,
        normalCount: normal,
      );
    }

    final analysis = await TriggerService().analyzeTriggers();
    final active = <TriggerResult>[];
    for (final item in analysis) {
      if (item.isTrigger) {
        active.add(item);
      }
    }
    active.sort((a, b) => b.weight.compareTo(a.weight));

    final risk = _riskFrom(active);
    return _DashboardInsights.withData(
      dailyCount: daily.length,
      seizureCount: seizure.length,
      normalCount: normal,
      riskScore: risk,
      topTrigger: active.isEmpty ? null : active.first,
      activeTriggerCount: active.length,
    );
  }

  double _riskFrom(List<TriggerResult> active) {
    if (active.isEmpty) {
      return 0.2;
    }

    var total = 0.0;
    for (final t in active) {
      total += t.weight;
    }

    final avg = total / active.length;
    return min(0.95, 0.25 + (avg * 0.35) + (active.length * 0.08));
  }

  String _riskLabel(double score) {
    if (score < 0.4) return 'Low';
    if (score < 0.7) return 'Moderate';
    return 'High';
  }

  Color _riskColor(double score) {
    if (score < 0.4) return const Color(0xFF2E7D32);
    if (score < 0.7) return const Color(0xFFF9A825);
    return const Color(0xFFC62828);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FutureBuilder<String?>(
            future: FrontendAccountStore.instance.getCurrentUsername(),
            builder: (context, snapshot) {
              final username = snapshot.data ?? 'Guest';
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF522583), Color(0xFF9D00FF)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Color(0xFF5E2AA5)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Welcome back, $username',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Icon(Icons.insights_rounded, color: Colors.white),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          FutureBuilder<_DashboardInsights>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              if (snapshot.hasError) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Unable to load insights right now. Please try again.'),
                  ),
                );
              }

              final insights = snapshot.data!;
              if (!insights.hasEnoughData) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Today\'s Safety Snapshot', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        DataThresholdBanner(
                          seizureDaysLogged: insights.seizureCount,
                          normalDaysLogged: insights.normalCount,
                          forTTest: true,
                        ),
                        const Text(
                          'We need more data before showing risk or trigger insights on this page.',
                        ),
                        Text(
                          'Current data: ${insights.dailyCount} daily logs, ${insights.seizureCount} seizure logs.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final safetyScore = 1 - insights.riskScore;
              final scoreColor = _riskColor(insights.riskScore);
              return Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Today\'s Safety Snapshot', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 10),
                          Center(child: RiskGauge(safetyScore: safetyScore)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _MetricPill(
                                  label: 'Risk',
                                  value: _riskLabel(insights.riskScore),
                                  valueColor: scoreColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _MetricPill(
                                  label: 'Safety',
                                  value: safetyScore.toStringAsFixed(2),
                                  valueColor: scoreColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              minHeight: 10,
                              value: safetyScore,
                              color: scoreColor,
                              backgroundColor: const Color(0xFFE9D8EE),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Prediction is calculated from trigger analysis and seizure history.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MetricCard(
                    icon: Icons.warning_amber_rounded,
                    title: 'Trigger Highlights',
                    value: insights.topTrigger == null
                        ? 'No strong triggers detected yet'
                        : insights.topTrigger!.factorName,
                    subtitle: insights.topTrigger == null
                        ? 'Keep logging to detect patterns over time.'
                        : '${insights.activeTriggerCount} active trigger(s) detected from backend data.',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<dynamic>>(
            future: Future.wait([
              DatabaseHelper.instance.getAllMedications(),
            ]),
            builder: (context, snapshot) {
              String reminderText = 'No medication schedule added yet';
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData &&
                  (snapshot.data![0] as List).isNotEmpty) {
                final meds = snapshot.data![0] as List;
                final first = meds.first;
                reminderText = '${first.name} - ${first.timesList}';
              }
              return _MetricCard(
                icon: Icons.medication_outlined,
                title: 'Medication Reminder',
                value: reminderText,
                subtitle: 'Synced with saved medication plans.',
              );
            },
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Support Resources', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  const _ResourceRow(
                    icon: Icons.school_outlined,
                    title: 'Educational Guidance',
                    subtitle: 'Learn about seizure patterns and prevention habits.',
                  ),
                  const SizedBox(height: 8),
                  const _ResourceRow(
                    icon: Icons.groups_2_outlined,
                    title: 'Community & Care Teams',
                    subtitle: 'Keep your support network and emergency contacts ready.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _ActionButton(label: 'Daily Entry', route: '/log-seizure'),
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

class _DashboardInsights {
  final bool hasEnoughData;
  final int dailyCount;
  final int seizureCount;
  final int normalCount;
  final double riskScore;
  final TriggerResult? topTrigger;
  final int activeTriggerCount;

  const _DashboardInsights({
    required this.hasEnoughData,
    required this.dailyCount,
    required this.seizureCount,
    required this.normalCount,
    required this.riskScore,
    required this.topTrigger,
    required this.activeTriggerCount,
  });

  factory _DashboardInsights.insufficientData({
    required int dailyCount,
    required int seizureCount,
    required int normalCount,
  }) {
    return _DashboardInsights(
      hasEnoughData: false,
      dailyCount: dailyCount,
      seizureCount: seizureCount,
      normalCount: normalCount,
      riskScore: 0,
      topTrigger: null,
      activeTriggerCount: 0,
    );
  }

  factory _DashboardInsights.withData({
    required int dailyCount,
    required int seizureCount,
    required int normalCount,
    required double riskScore,
    required TriggerResult? topTrigger,
    required int activeTriggerCount,
  }) {
    return _DashboardInsights(
      hasEnoughData: true,
      dailyCount: dailyCount,
      seizureCount: seizureCount,
      normalCount: normalCount,
      riskScore: riskScore,
      topTrigger: topTrigger,
      activeTriggerCount: activeTriggerCount,
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _MetricCard({
    required this.icon,
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
            Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF660066)),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
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

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _MetricPill({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF6EAF8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _ResourceRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ResourceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEEDAF5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF660066)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
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

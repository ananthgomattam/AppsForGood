import 'dart:math';

import 'package:flutter/material.dart';

import '../data/daily_log.dart';
import '../database/database_helper.dart';
import '../frontend/account_store.dart';
import '../services/prediction_service.dart';
import '../services/weather_service.dart';
import '../widgets/risk_gauge.dart';

enum _InsightsTier { locked, safetyOnly, basicTriggers, full }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver, RouteAware {
  late Future<_DashboardInsights> _future;
  late Future<WeatherSnapshot> _weatherFuture;

  @override
  void initState() {
    super.initState();
    _refreshInsights();
    _refreshWeather();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _refreshInsights() {
    setState(() {
      _future = _getInsights();
    });
  }

  Future<void> _openAndRefresh(String route) async {
    await Navigator.pushNamed(context, route);
    if (!mounted) return;
    _refreshInsights();
    _refreshWeather();
  }

  void _refreshWeather() {
    setState(() {
      _weatherFuture = WeatherService().getWeather();
    });
  }

  Future<void> _signOut(BuildContext context) async {
    await FrontendAccountStore.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh insights when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _refreshInsights();
      _refreshWeather();
    }
  }

  @override
  void didPopNext() {
    // Refresh insights when navigating back to this screen
    _refreshInsights();
    _refreshWeather();
    super.didPopNext();
  }

  Future<_DashboardInsights> _getInsights() async {
    try {
      final daily = await DatabaseHelper.instance.getAllDailyLogs();
      final seizure = await DatabaseHelper.instance.getAllSeizureLogs();
      final normal = max(0, daily.length - seizure.length);
      final totalEntries = daily.length;

      if (totalEntries <= 6) {
        return _DashboardInsights.insufficientData(
          dailyCount: daily.length,
          seizureCount: seizure.length,
          normalCount: normal,
          totalEntries: totalEntries,
        );
      }

      // Get today's date
      final today = DateTime.now();
      final todayDateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Find today's log and fall back to latest real log if today's entry does not exist.
      DailyLog? todayLog = daily.cast<DailyLog?>().firstWhere(
        (log) => log?.date == todayDateStr,
        orElse: () => null,
      );

      bool usedLatestLog = false;
      if (todayLog == null) {
        final sorted = [...daily]..sort((a, b) => b.date.compareTo(a.date));
        if (sorted.isEmpty) {
          return _DashboardInsights.insufficientData(
            dailyCount: daily.length,
            seizureCount: seizure.length,
            normalCount: normal,
            totalEntries: totalEntries,
          );
        }
        todayLog = sorted.first;
        usedLatestLog = true;
      }

      final basisDate = usedLatestLog ? todayLog.date : todayDateStr;

      // Get prediction for today
      try {
        final predictionService = PredictionService();
        final prediction = await predictionService.predict(todayLog);

        // Convert risk score (0-100) to 0-1 scale for consistency with existing display
        final riskScoreNormalized = prediction.riskScore / 100.0;
        
        // Determine tier based on entry count:
        // 0-6: locked (handled above)
        // 7-13: safetyOnly (show safety score with disclaimer)
        // 14-29: basicTriggers (safety score + basic triggers with disclaimer)
        // 30+: full (complete experience, no disclaimer)
        final tier = totalEntries >= 30
            ? _InsightsTier.full
            : totalEntries >= 14
            ? _InsightsTier.basicTriggers
            : _InsightsTier.safetyOnly;

        return _DashboardInsights.withData(
          dailyCount: daily.length,
          seizureCount: seizure.length,
          normalCount: normal,
          totalEntries: totalEntries,
          tier: tier,
          riskScore: riskScoreNormalized,
          prediction: prediction,
          predictionBasedOnDate: basisDate,
          predictionComputed: true,
        );
      } catch (e) {
        final tier = totalEntries >= 30
            ? _InsightsTier.full
            : totalEntries >= 14
            ? _InsightsTier.basicTriggers
            : _InsightsTier.safetyOnly;
        return _DashboardInsights.withData(
          dailyCount: daily.length,
          seizureCount: seizure.length,
          normalCount: normal,
          totalEntries: totalEntries,
          tier: tier,
          riskScore: 0,
          prediction: null,
          predictionBasedOnDate: basisDate,
          predictionComputed: false,
        );
      }
    } on StateError catch (e) {
      // Handle database initialization errors on web
      if (e.message.contains('databaseFactory')) {
        return _DashboardInsights.insufficientData(
          dailyCount: 0,
          seizureCount: 0,
          normalCount: 0,
          totalEntries: 0,
        );
      }
      rethrow;
    } catch (e) {
      // Generic error handler
      return _DashboardInsights.insufficientData(
        dailyCount: 0,
        seizureCount: 0,
        normalCount: 0,
        totalEntries: 0,
      );
    }
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
          FutureBuilder<WeatherSnapshot>(
            future: _weatherFuture,
            builder: (context, snapshot) {
              final weather = snapshot.data ?? WeatherSnapshot.unavailable();
              final temp = weather.temperature;
              final humidity = weather.humidity;
              final pressure = weather.pressure;

              final label = temp == null ? '-- C' : '${temp.round()} C';
              final tooltip = temp == null
                  ? 'Weather unavailable'
                  : 'Condition: ${weather.conditionLabel} | Temp: ${temp.toStringAsFixed(1)} C | Humidity: ${humidity?.toStringAsFixed(0) ?? '--'}% | Pressure: ${pressure?.toStringAsFixed(0) ?? '--'} hPa';

              IconData weatherIcon = Icons.cloud_off_outlined;
              final code = weather.weatherCode;
              if (code != null) {
                if (code == 0) {
                  weatherIcon = Icons.wb_sunny_outlined;
                } else if (code == 1 || code == 2 || code == 3) {
                  weatherIcon = Icons.cloud_outlined;
                } else if (code == 45 || code == 48) {
                  weatherIcon = Icons.foggy;
                } else if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
                  weatherIcon = Icons.grain_outlined;
                } else if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) {
                  weatherIcon = Icons.ac_unit_outlined;
                } else if (code >= 95) {
                  weatherIcon = Icons.thunderstorm_outlined;
                }
              }

              return Tooltip(
                message: tooltip,
                child: TextButton.icon(
                  onPressed: _refreshWeather,
                  icon: Icon(weatherIcon, size: 18),
                  label: Text(label),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              );
            },
          ),
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
                        const Text(
                          'Keep logging to unlock your insights.',
                        ),
                        Text(
                          'Current entries logged: ${insights.totalEntries}/7',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (!insights.predictionComputed) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Today\'s Safety Snapshot', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        const Text(
                          'Safety score is temporarily unavailable. We could not complete backend trigger analysis for your latest entry.',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Data source: ${insights.dailyCount} daily entries and ${insights.seizureCount} seizure entries (latest prediction date: ${insights.predictionBasedOnDate ?? '--'}).',
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
                            'Prediction is calculated from backend trigger analysis and seizure history.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Calculation date: ${insights.predictionBasedOnDate ?? '--'}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (insights.tier != _InsightsTier.full) ...[
                            const SizedBox(height: 6),
                            const Text(
                              'Based on limited data.',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (insights.tier != _InsightsTier.safetyOnly) ...[
                    const SizedBox(height: 12),
                    _MetricCard(
                      icon: Icons.warning_amber_rounded,
                      title: insights.tier == _InsightsTier.full
                          ? 'Prediction Insight'
                          : 'Basic Trigger List',
                      value: insights.prediction?.explanation ?? 'Unable to predict',
                      subtitle: insights.prediction?.activeTriggers.isEmpty ?? true
                          ? 'No active triggers detected yet.'
                          : 'Active triggers: ${insights.prediction!.activeTriggers.join(", ")}',
                    ),
                  ],
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
            children: [
              _ActionButton(
                label: 'Daily Entry',
                onPressed: () => _openAndRefresh('/log-seizure'),
              ),
              _ActionButton(
                label: 'Track Triggers',
                onPressed: () => _openAndRefresh('/triggers'),
              ),
              _ActionButton(
                label: 'Entries',
                onPressed: () => _openAndRefresh('/entries'),
              ),
              _ActionButton(
                label: 'Medication',
                onPressed: () => _openAndRefresh('/medication'),
              ),
              _ActionButton(
                label: 'Profile',
                onPressed: () => _openAndRefresh('/profile'),
              ),
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
  final int totalEntries;
  final _InsightsTier tier;
  final double riskScore;
  final PredictionResult? prediction;
  final String? predictionBasedOnDate;
  final bool predictionComputed;

  const _DashboardInsights({
    required this.hasEnoughData,
    required this.dailyCount,
    required this.seizureCount,
    required this.normalCount,
    required this.totalEntries,
    required this.tier,
    required this.riskScore,
    required this.prediction,
    required this.predictionBasedOnDate,
    required this.predictionComputed,
  });

  factory _DashboardInsights.insufficientData({
    required int dailyCount,
    required int seizureCount,
    required int normalCount,
    required int totalEntries,
  }) {
    return _DashboardInsights(
      hasEnoughData: false,
      dailyCount: dailyCount,
      seizureCount: seizureCount,
      normalCount: normalCount,
      totalEntries: totalEntries,
      tier: _InsightsTier.locked,
      riskScore: 0,
      prediction: null,
      predictionBasedOnDate: null,
      predictionComputed: false,
    );
  }

  factory _DashboardInsights.withData({
    required int dailyCount,
    required int seizureCount,
    required int normalCount,
    required int totalEntries,
    required _InsightsTier tier,
    required double riskScore,
    required PredictionResult? prediction,
    required String? predictionBasedOnDate,
    required bool predictionComputed,
  }) {
    return _DashboardInsights(
      hasEnoughData: true,
      dailyCount: dailyCount,
      seizureCount: seizureCount,
      normalCount: normalCount,
      totalEntries: totalEntries,
      tier: tier,
      riskScore: riskScore,
      prediction: prediction,
      predictionBasedOnDate: predictionBasedOnDate,
      predictionComputed: predictionComputed,
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
  final VoidCallback onPressed;

  const _ActionButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

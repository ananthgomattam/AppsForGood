import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../services/trigger_service.dart';
import '../widgets/data_threshold_banner.dart';
import '../widgets/trigger_card.dart';

class TriggersScreen extends StatefulWidget {
  const TriggersScreen({super.key});

  @override
  State<TriggersScreen> createState() => _TriggersScreenState();
}

class _TriggersScreenState extends State<TriggersScreen> {
  late Future<_TriggerPageData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _getData();
  }

  Future<_TriggerPageData> _getData() async {
    final daily = await DatabaseHelper.instance.getAllDailyLogs();
    final seizure = await DatabaseHelper.instance.getAllSeizureLogs();
    final normal = (daily.length - seizure.length).clamp(0, daily.length);

    if (daily.length < 10 || seizure.length < 10) {
      return _TriggerPageData.insufficient(
        dailyCount: daily.length,
        seizureCount: seizure.length,
        normalCount: normal,
      );
    }

    final results = await TriggerService().analyzeTriggers();
    results.sort((a, b) => b.weight.compareTo(a.weight));

    return _TriggerPageData.ready(
      dailyCount: daily.length,
      seizureCount: seizure.length,
      normalCount: normal,
      results: results,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trigger Insights')),
      body: FutureBuilder<_TriggerPageData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Unable to load trigger analysis right now.'),
              ),
            );
          }

          final data = snapshot.data!;
          if (!data.hasEnoughData) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DataThresholdBanner(
                    seizureDaysLogged: data.seizureCount,
                    normalDaysLogged: data.normalCount,
                    forTTest: true,
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Need More Data', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          const Text(
                            'Trigger insights are synced to backend analysis and stay hidden until enough data exists.',
                          ),
                          const SizedBox(height: 8),
                          Text('Daily logs: ${data.dailyCount}/10'),
                          Text('Seizure logs: ${data.seizureCount}/10'),
                          Text('Normal days: ${data.normalCount}/10'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final triggerCount = data.results.where((item) => item.isTrigger).length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DataThresholdBanner(
                seizureDaysLogged: data.seizureCount,
                normalDaysLogged: data.normalCount,
                forTTest: true,
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Trigger Analysis Summary', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Analyzed ${data.dailyCount} daily logs and ${data.seizureCount} seizure logs.'),
                      const SizedBox(height: 4),
                      Text('$triggerCount factor(s) currently flagged as likely triggers.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...data.results.map((result) => TriggerCard(trigger: result)),
            ],
          );
        },
      ),
    );
  }
}

class _TriggerPageData {
  final bool hasEnoughData;
  final int dailyCount;
  final int seizureCount;
  final int normalCount;
  final List<TriggerResult> results;

  const _TriggerPageData({
    required this.hasEnoughData,
    required this.dailyCount,
    required this.seizureCount,
    required this.normalCount,
    required this.results,
  });

  factory _TriggerPageData.insufficient({
    required int dailyCount,
    required int seizureCount,
    required int normalCount,
  }) {
    return _TriggerPageData(
      hasEnoughData: false,
      dailyCount: dailyCount,
      seizureCount: seizureCount,
      normalCount: normalCount,
      results: const [],
    );
  }

  factory _TriggerPageData.ready({
    required int dailyCount,
    required int seizureCount,
    required int normalCount,
    required List<TriggerResult> results,
  }) {
    return _TriggerPageData(
      hasEnoughData: true,
      dailyCount: dailyCount,
      seizureCount: seizureCount,
      normalCount: normalCount,
      results: results,
    );
  }
}

import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../services/trigger_service.dart';
import '../widgets/trigger_card.dart';
//Copilot: "Explain the key Flutter patterns for implementing a data-driven screen with FutureBuilder, async database fetch, conditional content, and list rendering based on analysis results"
// The TriggersScreen is a stateful widget that displays insights about potential seizure triggers based on the user's logged data. It retrieves daily logs and seizure logs from the database, analyzes them using the TriggerService, and presents the results in a user-friendly format. The screen handles different states such as loading, error, insufficient data, and ready with results, providing appropriate feedback to the user in each case.
enum _TriggerTier { locked, basic, full }
// The _TriggerPageData class is a data model that encapsulates the state of the trigger analysis page. It includes information about whether there is enough data for analysis, counts of daily logs, seizure logs, normal logs, total entries, the tier of analysis available, the list of trigger results, and any error messages. This class provides factory constructors for creating instances representing insufficient data, ready data with results, and error states, allowing for clear and organized handling of the different scenarios that may arise when loading and analyzing trigger data.
class TriggersScreen extends StatefulWidget {
  const TriggersScreen({super.key});

  @override
  State<TriggersScreen> createState() => _TriggersScreenState();
}
// The _TriggersScreenState class manages the state of the TriggersScreen. It initializes a Future to load the trigger analysis data when the screen is first created. The _getData method retrieves the necessary logs from the database, checks if there is enough data for analysis, and if so, performs the trigger analysis using the TriggerService. The results are sorted and returned in a structured format. The build method uses a FutureBuilder to handle the different states of loading, error, insufficient data, and ready with results, displaying appropriate UI elements for each case.
class _TriggersScreenState extends State<TriggersScreen> {
  late Future<_TriggerPageData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _getData();
  }

  void _reload() {
    setState(() {
      _dataFuture = _getData();
    });
  }

  Future<_TriggerPageData> _getData() async {
    try {
      final daily = await DatabaseHelper.instance.getAllDailyLogs();
      final seizure = await DatabaseHelper.instance.getAllSeizureLogs();
      final normal = (daily.length - seizure.length).clamp(0, daily.length);
      final totalEntries = daily.length;

      if (totalEntries <= 6) {
        return _TriggerPageData.insufficient(
          dailyCount: daily.length,
          seizureCount: seizure.length,
          normalCount: normal,
          totalEntries: totalEntries,
          tier: _TriggerTier.locked,
        );
      }

      if (totalEntries <= 13) {
        return _TriggerPageData.insufficient(
          dailyCount: daily.length,
          seizureCount: seizure.length,
          normalCount: normal,
          totalEntries: totalEntries,
          tier: _TriggerTier.locked,
        );
      }

      final results = <TriggerResult>[];
      results.addAll(await TriggerService().analyzeTriggers());
      results.sort((a, b) => b.weight.compareTo(a.weight));
      
      // Tier determined by entry count:
      // 14-29 entries: basic (with disclaimer)
      // 30+ entries: full (no disclaimer)
      final tier = totalEntries >= 30 ? _TriggerTier.full : _TriggerTier.basic;

      return _TriggerPageData.ready(
        dailyCount: daily.length,
        seizureCount: seizure.length,
        normalCount: normal,
        totalEntries: totalEntries,
        tier: tier,
        results: results,
      );
    } on StateError catch (e) {
      // Handle database initialization errors on web
      if (e.message.contains('databaseFactory')) {
        return _TriggerPageData.error('Database not available on this platform');
      }
      return _TriggerPageData.error(e.toString());
    } catch (error) {
      return _TriggerPageData.error(error.toString());
    }
  }
// The _reload method is a simple function that triggers a reload of the trigger analysis data by calling setState and reassigning the _dataFuture to a new call to _getData. This allows the user to refresh the analysis results after making changes to their logged data or in case of an error.
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Unable to load trigger analysis right now.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!;
          if (data.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Unable to load trigger analysis right now.'),
                    const SizedBox(height: 8),
                    Text(
                      data.errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!data.hasEnoughData) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trigger Analysis Locked',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Keep logging to unlock trigger analysis. Patterns emerge after 14 entries.',
                          ),
                          const SizedBox(height: 8),
                          Text('Entries logged: ${data.totalEntries}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final triggerCount = data.results
              .where((item) => item.isTrigger)
              .length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (data.tier != _TriggerTier.full) ...[
                const SizedBox(height: 4),
                const Text(
                  'Based on limited data.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trigger Analysis Summary',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Analyzed ${data.totalEntries} total entries.',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.tier == _TriggerTier.full
                            ? 'T-test verified triggers are enabled.'
                            : 'Showing basic trigger list using threshold method.',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$triggerCount factor(s) currently flagged as likely triggers.',
                      ),
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
// The _TriggerPageData class is a data model that encapsulates the state of the trigger analysis page. It includes information about whether there is enough data for analysis, counts of daily logs, seizure logs, normal logs, total entries, the tier of analysis available, the list of trigger results, and any error messages. This class provides factory constructors for creating instances representing insufficient data, ready data with results, and error states, allowing for clear and organized handling of the different scenarios that may arise when loading and analyzing trigger data.
class _TriggerPageData {
  final bool hasEnoughData;
  final int dailyCount;
  final int seizureCount;
  final int normalCount;
  final int totalEntries;
  final _TriggerTier tier;
  final List<TriggerResult> results;
  final String? errorMessage;

  const _TriggerPageData({
    required this.hasEnoughData,
    required this.dailyCount,
    required this.seizureCount,
    required this.normalCount,
    required this.totalEntries,
    required this.tier,
    required this.results,
    this.errorMessage,
  });

  factory _TriggerPageData.insufficient({
    required int dailyCount,
    required int seizureCount,
    required int normalCount,
    required int totalEntries,
    required _TriggerTier tier,
  }) {
    return _TriggerPageData(
      hasEnoughData: false,
      dailyCount: dailyCount,
      seizureCount: seizureCount,
      normalCount: normalCount,
      totalEntries: totalEntries,
      tier: tier,
      results: const [],
      errorMessage: null,
    );
  }

  factory _TriggerPageData.ready({
    required int dailyCount,
    required int seizureCount,
    required int normalCount,
    required int totalEntries,
    required _TriggerTier tier,
    required List<TriggerResult> results,
  }) {
    return _TriggerPageData(
      hasEnoughData: true,
      dailyCount: dailyCount,
      seizureCount: seizureCount,
      normalCount: normalCount,
      totalEntries: totalEntries,
      tier: tier,
      results: results,
      errorMessage: null,
    );
  }

  factory _TriggerPageData.error(String message) {
    return _TriggerPageData(
      hasEnoughData: false,
      dailyCount: 0,
      seizureCount: 0,
      normalCount: 0,
      totalEntries: 0,
      tier: _TriggerTier.locked,
      results: const [],
      errorMessage: message,
    );
  }
}

import 'dart:math';

import '../data/daily_log.dart';
import '../data/seizure_log.dart';
import '../database/database_helper.dart';

// Holds the result of analyzing one factor (e.g. sleep, stress)
// isTrigger = true means this factor is significantly different on seizure days
// weight = how strong the trigger is, used later in prediction_service.dart
class TriggerResult {
  final String factorName;
  final bool isTrigger;
  final double seizureAvg;
  final double normalAvg;
  final double difference;
  final double weight;
  final bool usedTTest;

  TriggerResult({
    required this.factorName,
    required this.isTrigger,
    required this.seizureAvg,
    required this.normalAvg,
    required this.difference,
    required this.weight,
    required this.usedTTest,
  });
}

class TriggerService {

  // Fetches all data, builds seizure/normal day lists, runs trigger analysis on every factor, returns list of results
  Future<List<TriggerResult>> analyzeTriggers() async {

    // Pull all logs from the database
    final dailyLogs = await DatabaseHelper.instance.getAllDailyLogs();
    final seizureLogs = await DatabaseHelper.instance.getAllSeizureLogs();

    // For seizure days: use the DailyLog embedded inside each SeizureLog (for priority)
    final seizureDays = seizureLogs.map((log) => log.dailyLog).toList();

    // Get all dates that had a seizure so we can exclude them from normal days
    final seizureDates = seizureLogs.map((log) => log.date).toSet();

    // Normal days are defined as daily logs where no seizure occurred on that date
    final normalDays = dailyLogs
        .where((log) => !seizureDates.contains(log.date))
        .toList();

    // Sort all daily logs by date once — needed for the rolling weather window
    final sortedLogs = [...dailyLogs]
      ..sort((a, b) => a.date.compareTo(b.date));

    // Run standard trigger analysis for all non-weather factors
    final results = [
      _analyzeFactor(
        name: 'Sleep Hours',
        seizureDays: seizureDays,
        normalDays: normalDays,
        getValue: (log) => log.sleepHours,
      ),
      _analyzeFactor(
        name: 'Sleep Quality',
        seizureDays: seizureDays,
        normalDays: normalDays,
        getValue: (log) => log.sleepQuality.toDouble(),
      ),
      _analyzeFactor(
        name: 'Sleep Interruptions',
        seizureDays: seizureDays,
        normalDays: normalDays,
        getValue: (log) => log.sleepInterruptions.toDouble(),
      ),
      _analyzeFactor(
        name: 'Stress Level',
        seizureDays: seizureDays,
        normalDays: normalDays,
        getValue: (log) => log.stressLevel.toDouble(),
      ),
      _analyzeFactor(
        name: 'Diet Quality',
        seizureDays: seizureDays,
        normalDays: normalDays,
        getValue: (log) => log.dietQuality.toDouble(),
      ),
      _analyzeFactor(
        name: 'Medication',
        seizureDays: seizureDays,
        normalDays: normalDays,
        getValue: (log) => log.medicationAdherence ? 1.0 : 0.0,
      ),
      _analyzeFactor(
        name: 'Drug Use',
        seizureDays: seizureDays,
        normalDays: normalDays,
        getValue: (log) => log.drugUse ? 1.0 : 0.0,
      ),
      _analyzeFactor(
        name: 'Hormonal Changes',
        seizureDays: seizureDays,
        normalDays: normalDays,
        getValue: (log) => log.hormonalChanges == true ? 1.0 : 0.0,
      ),

      // Weather factors use rolling window analysis instead of global average
      // to avoid seasonal bias — only compares each seizure day to the 7 days
      // before and after it
      _analyzeWeatherFactor(
        name: 'Temperature',
        seizureLogs: seizureLogs,
        sortedDailyLogs: sortedLogs,
        getValue: (log) => log.temperature,
      ),
      _analyzeWeatherFactor(
        name: 'Pressure',
        seizureLogs: seizureLogs,
        sortedDailyLogs: sortedLogs,
        getValue: (log) => log.pressure,
      ),
      _analyzeWeatherFactor(
        name: 'Humidity',
        seizureLogs: seizureLogs,
        sortedDailyLogs: sortedLogs,
        getValue: (log) => log.humidity,
      ),
    ];

    return results;
  }

  // Calculates the average of one factor across a list of logs
  double _average(List<DailyLog> logs, double Function(DailyLog) getValue) {
    if (logs.isEmpty) return 0.0;
    final sum = logs.fold(0.0, (total, log) => total + getValue(log));
    return sum / logs.length;
  }

  // Calculates variance of a list of values given their average
  double _variance(List<double> values, double avg) {
    if (values.length < 2) return 0.0;
    final sumSquares = values.fold(0.0, (sum, v) => sum + pow(v - avg, 2));
    return sumSquares / (values.length - 1);
  }

  // Determines if one factor is a trigger
  // Uses simple threshold if not enough data, Welch's t-test if sufficient data
  TriggerResult _analyzeFactor({
    required String name,
    required List<DailyLog> seizureDays,
    required List<DailyLog> normalDays,
    required double Function(DailyLog) getValue,
    double threshold = 0.2,
  }) {
    final seizureAvg = _average(seizureDays, getValue);
    final normalAvg = _average(normalDays, getValue);
    final difference = (seizureAvg - normalAvg).abs();

    // NOT ENOUGH DATA: use simple threshold comparison
    if (seizureDays.length < 30 || normalDays.length < 30) {
      return TriggerResult(
        factorName: name,
        isTrigger: difference >= threshold,
        seizureAvg: seizureAvg,
        normalAvg: normalAvg,
        difference: difference,
        weight: difference,
        usedTTest: false,
      );
    }

    // ENOUGH DATA: use Welch's t-test
    final seizureValues = seizureDays.map(getValue).toList();
    final normalValues = normalDays.map(getValue).toList();

    final seizureVariance = _variance(seizureValues, seizureAvg);
    final normalVariance = _variance(normalValues, normalAvg);

    // Pooled standard error: accounts for both variance and sample size
    final sp =
        (seizureVariance / seizureDays.length) +
        (normalVariance / normalDays.length);

    // All values identical: no difference possible
    if (sp == 0) {
      return TriggerResult(
        factorName: name,
        isTrigger: false,
        seizureAvg: seizureAvg,
        normalAvg: normalAvg,
        difference: 0,
        weight: 0,
        usedTTest: true,
      );
    }

    // t > 2.0 roughly corresponds to p < 0.05
    final tStat = difference / sqrt(sp);
    final isTrigger = tStat > 2.0;

    // Weight = effect size — larger = stronger trigger
    final seizureSD = sqrt(seizureVariance);
    final weight = isTrigger ? (difference / (seizureSD + 0.001)) : 0.0;

    return TriggerResult(
      factorName: name,
      isTrigger: isTrigger,
      seizureAvg: seizureAvg,
      normalAvg: normalAvg,
      difference: difference,
      weight: weight,
      usedTTest: true,
    );
  }

  // Weather-specific analysis using a 15 day rolling window (7 before, 7 after)
  // For each seizure, compares that day's weather to surrounding days only
  // This removes seasonal bias from the global average approach
  TriggerResult _analyzeWeatherFactor({
    required String name,
    required List<SeizureLog> seizureLogs,
    required List<DailyLog> sortedDailyLogs,
    required double? Function(DailyLog) getValue,
    double threshold = 0.5,
  }) {
    // For each seizure, calculate how much the weather deviated from its local window
    final deviations = <double>[];

    for (final seizure in seizureLogs) {
      // Find the index of the seizure date in the sorted daily logs
      final i = sortedDailyLogs.indexWhere((log) => log.date == seizure.date);
      if (i == -1) continue;

      // Get the seizure day's weather value — skip if null
      final seizureValue = getValue(sortedDailyLogs[i]);
      if (seizureValue == null) continue;

      // Build the 15 day window: 7 days before and 7 days after
      // Uses whatever days are available at the edges of the dataset
      final windowStart = (i - 7).clamp(0, sortedDailyLogs.length - 1);
      final windowEnd = (i + 7).clamp(0, sortedDailyLogs.length - 1);

      // Get all window values that are not null and not the seizure day itself
      final windowValues = sortedDailyLogs
          .sublist(windowStart, windowEnd + 1)
          .where((log) => log.date != seizure.date)
          .map(getValue)
          .whereType<double>()
          .toList();

      if (windowValues.isEmpty) continue;

      // Calculate local average for the window
      final windowAvg = windowValues.reduce((a, b) => a + b) / windowValues.length;

      // Deviation = how far the seizure day was from the local average
      deviations.add((seizureValue - windowAvg).abs());
    }

    // Not enough seizures with weather data
    if (deviations.isEmpty) {
      return TriggerResult(
        factorName: name,
        isTrigger: false,
        seizureAvg: 0,
        normalAvg: 0,
        difference: 0,
        weight: 0,
        usedTTest: false,
      );
    }

    // Average deviation across all seizures
    final avgDeviation = deviations.reduce((a, b) => a + b) / deviations.length;

    // If average deviation is large enough, weather is a trigger
    final isTrigger = avgDeviation >= threshold;

    // Weight = how strong the deviation is
    final weight = isTrigger ? avgDeviation : 0.0;

    return TriggerResult(
      factorName: name,
      isTrigger: isTrigger,
      seizureAvg: avgDeviation,   
      normalAvg: 0,               
      difference: avgDeviation,
      weight: weight,
      usedTTest: false,           
    );
  }
}
import 'dart:math';

import '../data/daily_log.dart';
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

  // Main function — fetches all data, builds seizure/normal day lists,
  // runs trigger analysis on every factor, returns list of results
  Future<List<TriggerResult>> analyzeTriggers() async {

    // Pull all logs from the database
    final dailyLogs = await DatabaseHelper.instance.getAllDailyLogs();
    final seizureLogs = await DatabaseHelper.instance.getAllSeizureLogs();

    // For seizure days — use the DailyLog embedded inside each SeizureLog
    // This takes priority over the standalone daily log for that date
    final seizureDays = seizureLogs.map((log) => log.dailyLog).toList();

    // Get all dates that had a seizure so we can exclude them from normal days
    final seizureDates = seizureLogs.map((log) => log.date).toSet();

    // Normal days — daily logs where no seizure occurred on that date
    final normalDays = dailyLogs
        .where((log) => !seizureDates.contains(log.date))
        .toList();

    // Run _analyzeFactor on every factor we track
    return [
      _analyzeFactor(name: 'Sleep Hours',        seizureDays: seizureDays, normalDays: normalDays, getValue: (log) => log.sleepHours),
      _analyzeFactor(name: 'Sleep Quality',       seizureDays: seizureDays, normalDays: normalDays, getValue: (log) => log.sleepQuality.toDouble()),
      _analyzeFactor(name: 'Sleep Interruptions', seizureDays: seizureDays, normalDays: normalDays, getValue: (log) => log.sleepInterruptions.toDouble()),
      _analyzeFactor(name: 'Stress Level',        seizureDays: seizureDays, normalDays: normalDays, getValue: (log) => log.stressLevel.toDouble()),
      _analyzeFactor(name: 'Diet Quality',        seizureDays: seizureDays, normalDays: normalDays, getValue: (log) => log.dietQuality.toDouble()),
      _analyzeFactor(name: 'Medication',          seizureDays: seizureDays, normalDays: normalDays, getValue: (log) => log.medicationAdherence ? 1.0 : 0.0),
      _analyzeFactor(name: 'Drug Use',            seizureDays: seizureDays, normalDays: normalDays, getValue: (log) => log.drugUse ? 1.0 : 0.0),
      _analyzeFactor(name: 'Hormonal Changes',    seizureDays: seizureDays, normalDays: normalDays, getValue: (log) => log.hormonalChanges == true ? 1.0 : 0.0),
    ];
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

    // NOT ENOUGH DATA — use simple threshold comparison
    if (seizureDays.length < 10 || normalDays.length < 10) {
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

    // ENOUGH DATA — use Welch's t-test
    final seizureValues = seizureDays.map(getValue).toList();
    final normalValues = normalDays.map(getValue).toList();

    final seizureVariance = _variance(seizureValues, seizureAvg);
    final normalVariance = _variance(normalValues, normalAvg);

    final sp = (seizureVariance / seizureDays.length) +
               (normalVariance / normalDays.length);

    // All values identical — no difference possible
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
    final weight = isTrigger
        ? (difference / (seizureSD + 0.001))
        : 0.0;

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
}
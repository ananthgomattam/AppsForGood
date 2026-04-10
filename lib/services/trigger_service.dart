import 'dart:math';

import '../data/daily_log.dart';
import '../data/seizure_log.dart';
import '../database/database_helper.dart';

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
  Future<List<TriggerResult>> analyzeTriggers() async {
    final dailyLogs = await DatabaseHelper.instance.getAllDailyLogs();
    final seizureLogs = await DatabaseHelper.instance.getAllSeizureLogs();

    // Not enough data to analyze triggers yet
    if (dailyLogs.length < 14) return [];

    final seizureDays = seizureLogs.map((log) => log.dailyLog).toList();
    final seizureDates = seizureLogs.map((log) => log.date).toSet();
    final normalDays = dailyLogs
        .where((log) => !seizureDates.contains(log.date))
        .toList();

    final sortedLogs = [...dailyLogs]..sort((a, b) => a.date.compareTo(b.date));

    return [
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
  }

  double _average(List<DailyLog> logs, double Function(DailyLog) getValue) {
    if (logs.isEmpty) return 0.0;
    final sum = logs.fold(0.0, (total, log) => total + getValue(log));
    return sum / logs.length;
  }

  double _variance(List<double> values, double avg) {
    if (values.length < 2) return 0.0;
    final sumSquares = values.fold(0.0, (sum, v) => sum + pow(v - avg, 2));
    return sumSquares / (values.length - 1);
  }

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
    // usedTTest = false tells UI to show disclaimer
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

    // ENOUGH DATA: use Welch's t-test
    final seizureValues = seizureDays.map(getValue).toList();
    final normalValues = normalDays.map(getValue).toList();

    final seizureVariance = _variance(seizureValues, seizureAvg);
    final normalVariance = _variance(normalValues, normalAvg);

    final sp =
        (seizureVariance / seizureDays.length) +
        (normalVariance / normalDays.length);

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

    final tStat = difference / sqrt(sp);
    final isTrigger = tStat > 2.0;
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

  TriggerResult _analyzeWeatherFactor({
    required String name,
    required List<SeizureLog> seizureLogs,
    required List<DailyLog> sortedDailyLogs,
    required double? Function(DailyLog) getValue,
    double threshold = 0.5,
  }) {
    final deviations = <double>[];

    for (final seizure in seizureLogs) {
      final i = sortedDailyLogs.indexWhere((log) => log.date == seizure.date);
      if (i == -1) continue;

      final seizureValue = getValue(sortedDailyLogs[i]);
      if (seizureValue == null) continue;

      final windowStart = (i - 7).clamp(0, sortedDailyLogs.length - 1);
      final windowEnd = (i + 7).clamp(0, sortedDailyLogs.length - 1);

      final windowValues = sortedDailyLogs
          .sublist(windowStart, windowEnd + 1)
          .where((log) => log.date != seizure.date)
          .map(getValue)
          .whereType<double>()
          .toList();

      if (windowValues.isEmpty) continue;

      final windowAvg =
          windowValues.reduce((a, b) => a + b) / windowValues.length;
      deviations.add((seizureValue - windowAvg).abs());
    }

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

    final avgDeviation = deviations.reduce((a, b) => a + b) / deviations.length;
    final isTrigger = avgDeviation >= threshold;
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

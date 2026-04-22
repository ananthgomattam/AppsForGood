import 'dart:io';
import 'dart:math';

import 'package:forseizure/data/test_dataset.dart';

class LabDailyLog {
  final String date;
  final bool medicationAdherence;
  final double sleepHours;
  final int sleepQuality;
  final int sleepInterruptions;
  final int stressLevel;
  final int dietQuality;
  final bool drugUse;
  final bool? hormonalChanges;
  final double? temperature;
  final double? pressure;
  final double? humidity;

  const LabDailyLog({
    required this.date,
    required this.medicationAdherence,
    required this.sleepHours,
    required this.sleepQuality,
    required this.sleepInterruptions,
    required this.stressLevel,
    required this.dietQuality,
    required this.drugUse,
    required this.hormonalChanges,
    required this.temperature,
    required this.pressure,
    required this.humidity,
  });

  LabDailyLog copyWith({
    String? date,
    bool? medicationAdherence,
    double? sleepHours,
    int? sleepQuality,
    int? sleepInterruptions,
    int? stressLevel,
    int? dietQuality,
    bool? drugUse,
    bool? hormonalChanges,
    double? temperature,
    double? pressure,
    double? humidity,
  }) {
    return LabDailyLog(
      date: date ?? this.date,
      medicationAdherence: medicationAdherence ?? this.medicationAdherence,
      sleepHours: sleepHours ?? this.sleepHours,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      sleepInterruptions: sleepInterruptions ?? this.sleepInterruptions,
      stressLevel: stressLevel ?? this.stressLevel,
      dietQuality: dietQuality ?? this.dietQuality,
      drugUse: drugUse ?? this.drugUse,
      hormonalChanges: hormonalChanges ?? this.hormonalChanges,
      temperature: temperature ?? this.temperature,
      pressure: pressure ?? this.pressure,
      humidity: humidity ?? this.humidity,
    );
  }
}

class LabSeizureLog {
  final String date;
  final LabDailyLog dailyLog;

  const LabSeizureLog({
    required this.date,
    required this.dailyLog,
  });
}

class TriggerResult {
  final String factorName;
  final bool isTrigger;
  final double seizureAvg;
  final double normalAvg;
  final double difference;
  final double weight;
  final bool usedTTest;

  const TriggerResult({
    required this.factorName,
    required this.isTrigger,
    required this.seizureAvg,
    required this.normalAvg,
    required this.difference,
    required this.weight,
    required this.usedTTest,
  });
}

class PredictionResult {
  final double riskScore;
  final String riskLevel;
  final List<String> activeTriggers;
  final String explanation;

  const PredictionResult({
    required this.riskScore,
    required this.riskLevel,
    required this.activeTriggers,
    required this.explanation,
  });
}

class LabDataset {
  final List<LabDailyLog> dailyLogs;
  final List<LabSeizureLog> seizureLogs;

  const LabDataset({required this.dailyLogs, required this.seizureLogs});
}

class ModelLab {
  static List<TriggerResult> analyzeTriggers({
    required List<LabDailyLog> dailyLogs,
    required List<LabSeizureLog> seizureLogs,
  }) {
    if (dailyLogs.length < 14) {
      return [];
    }

    final seizureDays = seizureLogs.map((log) => log.dailyLog).toList();
    final seizureDates = seizureLogs.map((log) => log.date).toSet();
    final normalDays =
        dailyLogs.where((log) => !seizureDates.contains(log.date)).toList();
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

  static PredictionResult predict({
    required LabDailyLog today,
    required List<LabDailyLog> allDailyLogs,
    required List<LabSeizureLog> allSeizureLogs,
    required DateTime referenceNow,
  }) {
    final triggers =
        analyzeTriggers(dailyLogs: allDailyLogs, seizureLogs: allSeizureLogs);

    if (allDailyLogs.length < 7) {
      return const PredictionResult(
        riskScore: 0,
        riskLevel: 'Insufficient Data',
        activeTriggers: [],
        explanation: 'Log at least 7 days to unlock your first prediction',
      );
    }

    final sortedLogs = [...allDailyLogs]..sort((a, b) => a.date.compareTo(b.date));

    double rawRisk = 0.0;
    double totalWeight = 0.0;
    final activeTriggers = <String>[];

    for (final trigger in triggers) {
      if (!trigger.isTrigger || trigger.weight == 0.0) continue;
      final todayValue = _getFactorValue(today, trigger.factorName);
      if (todayValue == null) continue;
      final normalizedRisk = _calculateTriggerContribution(
        todayValue: todayValue,
        trigger: trigger,
      );
      if (normalizedRisk > 0.1) activeTriggers.add(trigger.factorName);
      rawRisk += normalizedRisk * trigger.weight;
      totalWeight += trigger.weight;
    }

    final triggerRisk =
        totalWeight > 0 ? (rawRisk / totalWeight).clamp(0.0, 1.0) : 0.0;

    final recentLogs = sortedLogs
        .where((log) => log.date.compareTo(today.date) < 0)
        .toList()
        .reversed
        .take(7)
        .toList();

    double avgSleep = 7.0;
    double avgStress = 5.0;
    double rollingRisk = 0.0;

    if (recentLogs.isNotEmpty) {
      avgSleep =
          recentLogs.map((l) => l.sleepHours).reduce((a, b) => a + b) /
          recentLogs.length;
      avgStress =
          recentLogs
              .map((l) => l.stressLevel.toDouble())
              .reduce((a, b) => a + b) /
          recentLogs.length;
      final missedMedCount = recentLogs.where((l) => !l.medicationAdherence).length;

      if (avgSleep < 6.0) rollingRisk += 0.15;
      if (avgSleep < 5.0) rollingRisk += 0.10;
      if (avgStress > 7.0) rollingRisk += 0.15;
      if (avgStress > 8.5) rollingRisk += 0.10;
      if (missedMedCount >= 2) rollingRisk += 0.15;
      if (missedMedCount >= 4) rollingRisk += 0.15;
    }

    rollingRisk = rollingRisk.clamp(0.0, 1.0);

    final recentSeizures =
        allSeizureLogs.where((log) => log.date.compareTo(today.date) < 0).toList();

    double seizureHistoryRisk = 0.0;
    final thirtyDaysAgo = referenceNow.subtract(const Duration(days: 30));
    final recentSeizureCount = recentSeizures.where((log) {
      final date = DateTime.parse(log.date);
      return date.isAfter(thirtyDaysAgo);
    }).length;

    if (recentSeizureCount >= 1) seizureHistoryRisk += 0.10;
    if (recentSeizureCount >= 3) seizureHistoryRisk += 0.10;
    if (recentSeizureCount >= 5) seizureHistoryRisk += 0.10;

    if (recentSeizures.isNotEmpty) {
      final lastSeizureDate = DateTime.parse(recentSeizures.last.date);
      final hoursSinceLastSeizure = referenceNow.difference(lastSeizureDate).inHours;
      if (hoursSinceLastSeizure < 48) seizureHistoryRisk += 0.20;
    }

    seizureHistoryRisk = seizureHistoryRisk.clamp(0.0, 1.0);

    int medicationStreak = 0;
    for (final log in sortedLogs.reversed) {
      if (log.medicationAdherence) {
        medicationStreak++;
      } else {
        break;
      }
    }

    final medicationPenalty = medicationStreak < 3 ? 0.2 : 0.0;
    double combinedRisk =
        (triggerRisk * 0.35) +
        (rollingRisk * 0.30) +
        (seizureHistoryRisk * 0.25) +
        (medicationPenalty * 0.10);

    final interactionMultiplier = _calculateInteractionEffects(
      today: today,
      recentLogs: recentLogs,
      medicationStreak: medicationStreak,
      activeTriggers: activeTriggers,
    );

    combinedRisk = (combinedRisk * interactionMultiplier).clamp(0.0, 1.0);

    final riskScore = (combinedRisk * 100).roundToDouble();

    final riskLevel = riskScore < 30
        ? 'Low'
        : riskScore < 60
        ? 'Moderate'
        : 'High';

    final explanationParts = <String>[];
    if (avgSleep < 6.0) {
      explanationParts.add('poor sleep (${avgSleep.toStringAsFixed(1)} hrs)');
    }
    if (avgStress > 7.0) {
      explanationParts.add('high stress (${avgStress.toStringAsFixed(1)}/10)');
    }
    if (medicationStreak < 2) explanationParts.add('missed medication');
    if (recentSeizureCount >= 3) explanationParts.add('recent seizure activity');
    if (today.hormonalChanges == true) explanationParts.add('hormonal changes');

    String explanation;
    if (explanationParts.isEmpty) {
      explanation = 'All factors within normal range';
    } else if (explanationParts.length == 1) {
      explanation = 'Detected: ${explanationParts[0]}';
    } else if (explanationParts.length == 2) {
      explanation =
          'Detected: ${explanationParts[0]} and ${explanationParts[1]}';
    } else {
      final parts = explanationParts.sublist(0, explanationParts.length - 1);
      explanation = 'Detected: ${parts.join(', ')}, and ${explanationParts.last}';
    }

    if (interactionMultiplier > 1.0) {
      explanation += ' (dangerous combination)';
    }

    return PredictionResult(
      riskScore: riskScore,
      riskLevel: riskLevel,
      activeTriggers: activeTriggers,
      explanation: explanation,
    );
  }

  static List<LabDailyLog> fixedDailyLogs() {
    return fixedTestDataset
        .map(
          (entry) => LabDailyLog(
            date: entry.date,
            medicationAdherence: entry.medicationAdherence,
            sleepHours: entry.sleepHours,
            sleepQuality: entry.sleepQuality,
            sleepInterruptions: entry.sleepInterruptions,
            stressLevel: entry.stressLevel,
            dietQuality: entry.dietQuality,
            drugUse: entry.drugUse,
            hormonalChanges: entry.hormonalChanges,
            temperature: null,
            pressure: null,
            humidity: null,
          ),
        )
        .toList();
  }

  static List<LabSeizureLog> fixedSeizureLogs(List<LabDailyLog> dailyLogs) {
    final byDate = {for (final log in dailyLogs) log.date: log};
    final out = <LabSeizureLog>[];

    for (final entry in fixedTestDataset) {
      final daily = byDate[entry.date];
      if (daily == null) continue;
      for (var i = 0; i < entry.seizureCount; i++) {
        out.add(LabSeizureLog(date: entry.date, dailyLog: daily));
      }
    }

    return out;
  }

  static LabDataset fromCsv(String csvPath) {
    final file = File(csvPath);
    if (!file.existsSync()) {
      throw ArgumentError('CSV file not found: $csvPath');
    }

    final lines = file
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .toList();

    if (lines.length < 2) {
      throw ArgumentError('CSV must include header and at least one row');
    }

    final header = lines.first.split(',').map((e) => e.trim()).toList();
    final idx = <String, int>{
      for (var i = 0; i < header.length; i++) header[i]: i,
    };

    final required = [
      'date',
      'sleepHours',
      'sleepQuality',
      'sleepInterruptions',
      'stressLevel',
      'dietQuality',
      'medicationAdherence',
      'drugUse',
      'hormonalChanges',
      'seizureCount',
    ];

    for (final key in required) {
      if (!idx.containsKey(key)) {
        throw ArgumentError('Missing required CSV column: $key');
      }
    }

    final dailyLogs = <LabDailyLog>[];
    final seizureCounts = <String, int>{};

    for (var lineNo = 2; lineNo <= lines.length; lineNo++) {
      final row = lines[lineNo - 1].split(',').map((e) => e.trim()).toList();
      String get(String key) {
        final col = idx[key]!;
        if (col >= row.length) {
          throw ArgumentError('Row $lineNo has no value for $key');
        }
        return row[col];
      }

      final date = get('date');
      final sleepHours = double.parse(get('sleepHours'));
      final sleepQuality = int.parse(get('sleepQuality'));
      final sleepInterruptions = int.parse(get('sleepInterruptions'));
      final stressLevel = int.parse(get('stressLevel'));
      final dietQuality = int.parse(get('dietQuality'));
      final medicationAdherence = _parseBool(get('medicationAdherence'));
      final drugUse = _parseBool(get('drugUse'));
      final hormonalChanges = _parseBool(get('hormonalChanges'));
      final seizureCount = int.parse(get('seizureCount'));

      final temperature = idx.containsKey('temperature') ? _parseDoubleOrNull(get('temperature')) : null;
      final pressure = idx.containsKey('pressure') ? _parseDoubleOrNull(get('pressure')) : null;
      final humidity = idx.containsKey('humidity') ? _parseDoubleOrNull(get('humidity')) : null;

      dailyLogs.add(
        LabDailyLog(
          date: date,
          medicationAdherence: medicationAdherence,
          sleepHours: sleepHours,
          sleepQuality: sleepQuality,
          sleepInterruptions: sleepInterruptions,
          stressLevel: stressLevel,
          dietQuality: dietQuality,
          drugUse: drugUse,
          hormonalChanges: hormonalChanges,
          temperature: temperature,
          pressure: pressure,
          humidity: humidity,
        ),
      );
      seizureCounts[date] = seizureCount;
    }

    final byDate = {for (final log in dailyLogs) log.date: log};
    final seizureLogs = <LabSeizureLog>[];
    for (final entry in seizureCounts.entries) {
      final daily = byDate[entry.key];
      if (daily == null) continue;
      for (var i = 0; i < entry.value; i++) {
        seizureLogs.add(LabSeizureLog(date: entry.key, dailyLog: daily));
      }
    }

    return LabDataset(dailyLogs: dailyLogs, seizureLogs: seizureLogs);
  }

  static bool selfCheck() {
    final daily = fixedDailyLogs();
    final seizures = fixedSeizureLogs(daily);
    final sorted = [...daily]..sort((a, b) => a.date.compareTo(b.date));

    final lowRiskDay = sorted.firstWhere((d) => d.date == '2023-01-24');
    final highRiskDay = sorted.firstWhere((d) => d.date == '2023-01-22');

    final low = predict(
      today: lowRiskDay,
      allDailyLogs: sorted,
      allSeizureLogs: seizures,
      referenceNow: DateTime.parse('2023-01-25'),
    );
    final high = predict(
      today: highRiskDay,
      allDailyLogs: sorted,
      allSeizureLogs: seizures,
      referenceNow: DateTime.parse('2023-01-23'),
    );

    final triggers = analyzeTriggers(dailyLogs: sorted, seizureLogs: seizures)
        .where((t) => t.isTrigger)
        .map((t) => t.factorName)
        .toSet();

    final checks = <String, bool>{
      'Low-risk sample stays below high-risk sample': low.riskScore < high.riskScore,
      'Low-risk sample classified as Low or Moderate':
          low.riskLevel == 'Low' || low.riskLevel == 'Moderate',
      'High-risk sample classified as Moderate or High':
          high.riskLevel == 'Moderate' || high.riskLevel == 'High',
      'Stress factor detected as trigger': triggers.contains('Stress Level'),
      'Sleep interruption factor detected as trigger':
          triggers.contains('Sleep Interruptions'),
    };

    var ok = true;
    stdout.writeln('=== Model Lab Self-Check ===');
    checks.forEach((name, passed) {
      stdout.writeln('${passed ? 'PASS' : 'FAIL'}  $name');
      if (!passed) ok = false;
    });

    stdout.writeln('');
    stdout.writeln('Low-risk day (2023-01-24): ${low.riskScore.toStringAsFixed(1)} ${low.riskLevel}');
    stdout.writeln('High-risk day (2023-01-22): ${high.riskScore.toStringAsFixed(1)} ${high.riskLevel}');
    return ok;
  }

  static double _average(List<LabDailyLog> logs, double Function(LabDailyLog) getValue) {
    if (logs.isEmpty) return 0.0;
    final sum = logs.fold(0.0, (total, log) => total + getValue(log));
    return sum / logs.length;
  }

  static double _variance(List<double> values, double avg) {
    if (values.length < 2) return 0.0;
    final sumSquares = values.fold(0.0, (sum, v) => sum + pow(v - avg, 2));
    return sumSquares / (values.length - 1);
  }

  static TriggerResult _analyzeFactor({
    required String name,
    required List<LabDailyLog> seizureDays,
    required List<LabDailyLog> normalDays,
    required double Function(LabDailyLog) getValue,
    double threshold = 0.2,
  }) {
    final seizureAvg = _average(seizureDays, getValue);
    final normalAvg = _average(normalDays, getValue);
    final difference = (seizureAvg - normalAvg).abs();

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

    final seizureValues = seizureDays.map(getValue).toList();
    final normalValues = normalDays.map(getValue).toList();

    final seizureVariance = _variance(seizureValues, seizureAvg);
    final normalVariance = _variance(normalValues, normalAvg);

    final sp = (seizureVariance / seizureDays.length) + (normalVariance / normalDays.length);

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

  static TriggerResult _analyzeWeatherFactor({
    required String name,
    required List<LabSeizureLog> seizureLogs,
    required List<LabDailyLog> sortedDailyLogs,
    required double? Function(LabDailyLog) getValue,
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

      final windowAvg = windowValues.reduce((a, b) => a + b) / windowValues.length;
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

  static double _calculateInteractionEffects({
    required LabDailyLog today,
    required List<LabDailyLog> recentLogs,
    required int medicationStreak,
    required List<String> activeTriggers,
  }) {
    var multiplier = 1.0;

    final avgSleep = recentLogs.isNotEmpty
        ? recentLogs.map((l) => l.sleepHours).reduce((a, b) => a + b) / recentLogs.length
        : 7.0;
    final avgStress = recentLogs.isNotEmpty
        ? recentLogs
                  .map((l) => l.stressLevel.toDouble())
                  .reduce((a, b) => a + b) /
              recentLogs.length
        : 5.0;

    if (avgSleep < 6.0 && avgStress > 7.0) {
      multiplier = 1.4;
    } else if (medicationStreak < 2 && activeTriggers.isNotEmpty) {
      multiplier = 1.35;
    } else if (today.hormonalChanges == true && today.stressLevel > 7) {
      multiplier = 1.25;
    }

    return multiplier;
  }

  static double _calculateTriggerContribution({
    required double todayValue,
    required TriggerResult trigger,
  }) {
    final trend = trigger.seizureAvg - trigger.normalAvg;

    // Weather factors currently use a deviation-only trigger definition,
    // so keep absolute distance behavior for them.
    final isDeviationOnlyFactor =
        trigger.factorName == 'Temperature' ||
        trigger.factorName == 'Pressure' ||
        trigger.factorName == 'Humidity';

    if (isDeviationOnlyFactor) {
      final deviation = (todayValue - trigger.normalAvg).abs();
      return (deviation * trigger.weight).clamp(0.0, 1.0);
    }

    if (trend == 0.0) return 0.0;

    final directionalDelta = (todayValue - trigger.normalAvg) * trend.sign;
    if (directionalDelta <= 0.0) return 0.0;

    return (directionalDelta * trigger.weight).clamp(0.0, 1.0);
  }

  static double? _getFactorValue(LabDailyLog log, String factorName) {
    switch (factorName) {
      case 'Sleep Hours':
        return log.sleepHours;
      case 'Sleep Quality':
        return log.sleepQuality.toDouble();
      case 'Sleep Interruptions':
        return log.sleepInterruptions.toDouble();
      case 'Stress Level':
        return log.stressLevel.toDouble();
      case 'Diet Quality':
        return log.dietQuality.toDouble();
      case 'Medication':
        return log.medicationAdherence ? 1.0 : 0.0;
      case 'Drug Use':
        return log.drugUse ? 1.0 : 0.0;
      case 'Hormonal Changes':
        return log.hormonalChanges == true ? 1.0 : 0.0;
      case 'Temperature':
        return log.temperature;
      case 'Pressure':
        return log.pressure;
      case 'Humidity':
        return log.humidity;
      default:
        return null;
    }
  }
}

void main(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  if (args.contains('--self-check')) {
    final ok = ModelLab.selfCheck();
    exit(ok ? 0 : 1);
  }

  final argMap = _parseArgs(args);
  final csvPath = argMap['csv'];
  final datasetName = argMap['dataset'] ?? 'fixed';
  final date = argMap['date'];
  final referenceNowArg = argMap['reference-now'];
  final sensitivityArg = argMap['sensitivity'];

  late final List<LabDailyLog> dailyLogs;
  late final List<LabSeizureLog> seizureLogs;

  if (csvPath != null) {
    final data = ModelLab.fromCsv(csvPath);
    dailyLogs = data.dailyLogs;
    seizureLogs = data.seizureLogs;
  } else if (datasetName == 'fixed') {
    dailyLogs = ModelLab.fixedDailyLogs();
    seizureLogs = ModelLab.fixedSeizureLogs(dailyLogs);
  } else {
    stderr.writeln('Unknown dataset "$datasetName". Use --dataset fixed or --csv <path>.');
    exit(2);
  }

  if (dailyLogs.isEmpty) {
    stderr.writeln('No daily logs loaded.');
    exit(2);
  }

  final sortedLogs = [...dailyLogs]..sort((a, b) => a.date.compareTo(b.date));

  final today = date == null
      ? sortedLogs.last
      : sortedLogs.firstWhere(
          (log) => log.date == date,
          orElse: () {
            stderr.writeln('Date not found in dataset: $date');
            exit(2);
          },
        );

  final referenceNow = referenceNowArg != null
      ? DateTime.parse(referenceNowArg)
      : DateTime.parse(today.date).add(const Duration(days: 1));

  final triggers = ModelLab.analyzeTriggers(
    dailyLogs: sortedLogs,
    seizureLogs: seizureLogs,
  );
  final prediction = ModelLab.predict(
    today: today,
    allDailyLogs: sortedLogs,
    allSeizureLogs: seizureLogs,
    referenceNow: referenceNow,
  );

  stdout.writeln('=== Model Lab Report ===');
  stdout.writeln('Daily rows: ${sortedLogs.length}');
  stdout.writeln('Seizure rows: ${seizureLogs.length}');
  stdout.writeln('Prediction date: ${today.date}');
  stdout.writeln('Reference now: ${referenceNow.toIso8601String()}');
  stdout.writeln('Risk score: ${prediction.riskScore.toStringAsFixed(1)}');
  stdout.writeln('Risk level: ${prediction.riskLevel}');
  stdout.writeln('Explanation: ${prediction.explanation}');
  stdout.writeln(
    'Active triggers: ${prediction.activeTriggers.isEmpty ? '(none)' : prediction.activeTriggers.join(', ')}',
  );

  final active = triggers.where((t) => t.isTrigger).toList()
    ..sort((a, b) => b.weight.compareTo(a.weight));

  stdout.writeln('');
  stdout.writeln('Top trigger analysis:');
  if (active.isEmpty) {
    stdout.writeln('(none)');
  } else {
    for (final t in active.take(8)) {
      stdout.writeln(
        '- ${t.factorName}: weight=${t.weight.toStringAsFixed(3)} diff=${t.difference.toStringAsFixed(3)} method=${t.usedTTest ? 'welch_t' : 'threshold'}',
      );
    }
  }

  if (sensitivityArg != null) {
    stdout.writeln('');
    _runSensitivityReport(
      sensitivityArg: sensitivityArg,
      today: today,
      allDailyLogs: sortedLogs,
      allSeizureLogs: seizureLogs,
      referenceNow: referenceNow,
      baseline: prediction,
    );
  }
}

void _runSensitivityReport({
  required String sensitivityArg,
  required LabDailyLog today,
  required List<LabDailyLog> allDailyLogs,
  required List<LabSeizureLog> allSeizureLogs,
  required DateTime referenceNow,
  required PredictionResult baseline,
}) {
  final key = sensitivityArg.toLowerCase();

  LabDailyLog? worse;
  LabDailyLog? better;
  String? label;

  if (key == 'sleep' || key == 'sleephours') {
    label = 'Sleep trend sensitivity';
    worse = today.copyWith(
      sleepHours: max(0.0, today.sleepHours - 2.0),
      sleepQuality: _clampInt(today.sleepQuality - 2, 1, 10),
      sleepInterruptions: today.sleepInterruptions + 2,
    );
    better = today.copyWith(
      sleepHours: today.sleepHours + 2.0,
      sleepQuality: _clampInt(today.sleepQuality + 2, 1, 10),
      sleepInterruptions: _clampInt(today.sleepInterruptions - 2, 0, 20),
    );
  } else if (key == 'stress' || key == 'stresslevel') {
    label = 'Stress trend sensitivity';
    worse = today.copyWith(stressLevel: _clampInt(today.stressLevel + 3, 1, 10));
    better = today.copyWith(stressLevel: _clampInt(today.stressLevel - 3, 1, 10));
  } else if (key == 'meds' || key == 'medication' || key == 'medicationadherence') {
    label = 'Medication adherence sensitivity';
    worse = today.copyWith(medicationAdherence: false);
    better = today.copyWith(medicationAdherence: true);
  } else {
    stdout.writeln('Sensitivity mode not recognized: $sensitivityArg');
    stdout.writeln('Use: sleep | stress | medication');
    return;
  }

  final worsePrediction = ModelLab.predict(
    today: worse,
    allDailyLogs: allDailyLogs,
    allSeizureLogs: allSeizureLogs,
    referenceNow: referenceNow,
  );

  final betterPrediction = ModelLab.predict(
    today: better,
    allDailyLogs: allDailyLogs,
    allSeizureLogs: allSeizureLogs,
    referenceNow: referenceNow,
  );

  stdout.writeln('=== $label ===');
  stdout.writeln(
    'Baseline: ${baseline.riskScore.toStringAsFixed(1)} (${baseline.riskLevel})',
  );
  stdout.writeln(
    'Worse-case: ${worsePrediction.riskScore.toStringAsFixed(1)} (${worsePrediction.riskLevel})  delta=${(worsePrediction.riskScore - baseline.riskScore).toStringAsFixed(1)}',
  );
  stdout.writeln(
    'Better-case: ${betterPrediction.riskScore.toStringAsFixed(1)} (${betterPrediction.riskLevel})  delta=${(betterPrediction.riskScore - baseline.riskScore).toStringAsFixed(1)}',
  );
}

int _clampInt(int value, int minValue, int maxValue) {
  if (value < minValue) return minValue;
  if (value > maxValue) return maxValue;
  return value;
}

Map<String, String> _parseArgs(List<String> args) {
  final out = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final token = args[i];
    if (!token.startsWith('--')) continue;
    final key = token.substring(2);
    if (i + 1 < args.length && !args[i + 1].startsWith('--')) {
      out[key] = args[i + 1];
      i++;
    } else {
      out[key] = 'true';
    }
  }
  return out;
}

bool _parseBool(String raw) {
  final s = raw.trim().toLowerCase();
  if (s == 'true' || s == '1' || s == 'yes' || s == 'y') return true;
  if (s == 'false' || s == '0' || s == 'no' || s == 'n') return false;
  throw ArgumentError('Expected boolean value but got "$raw"');
}

double? _parseDoubleOrNull(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;
  return double.parse(s);
}

void _printUsage() {
  stdout.writeln('Model Lab: offline model validation runner');
  stdout.writeln('');
  stdout.writeln('Usage:');
  stdout.writeln('  dart run tool/model_lab.dart --self-check');
  stdout.writeln('  dart run tool/model_lab.dart --dataset fixed --date 2023-01-22');
  stdout.writeln('  dart run tool/model_lab.dart --csv tool/sample_model_input.csv --date 2023-01-22');
  stdout.writeln('');
  stdout.writeln('Optional:');
  stdout.writeln('  --reference-now YYYY-MM-DD');
  stdout.writeln('    Overrides current-time reference used by recency features.');
  stdout.writeln('  --sensitivity <sleep|stress|medication>');
  stdout.writeln('    Runs a local perturbation test to prove input changes affect output.');
}

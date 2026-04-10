import '../data/daily_log.dart';
import '../database/database_helper.dart';
import 'trigger_service.dart';

class PredictionResult {
  final double riskScore;
  final String riskLevel;
  final List<String> activeTriggers;
  final String explanation;

  PredictionResult({
    required this.riskScore,
    required this.riskLevel,
    required this.activeTriggers,
    required this.explanation,
  });
}

class PredictionService {
  final TriggerService _triggerService = TriggerService();

  Future<PredictionResult> predict(DailyLog today) async {
    final triggers = await _triggerService.analyzeTriggers();
    final allDailyLogs = await DatabaseHelper.instance.getAllDailyLogs();
    final allSeizureLogs = await DatabaseHelper.instance.getAllSeizureLogs();

    // Not enough data — return early
    if (allDailyLogs.length < 7) {
      return PredictionResult(
        riskScore: 0,
        riskLevel: 'Insufficient Data',
        activeTriggers: [],
        explanation: 'Log at least 7 days to unlock your first prediction',
      );
    }

    final sortedLogs = [...allDailyLogs]
      ..sort((a, b) => a.date.compareTo(b.date));

    double rawRisk = 0.0;
    double totalWeight = 0.0;
    final activeTriggers = <String>[];

    for (final trigger in triggers) {
      if (!trigger.isTrigger || trigger.weight == 0.0) continue;
      final todayValue = _getFactorValue(today, trigger.factorName);
      if (todayValue == null) continue;
      final deviation = (todayValue - trigger.normalAvg).abs();
      final normalizedRisk = (deviation * trigger.weight).clamp(0.0, 1.0);
      if (normalizedRisk > 0.1) activeTriggers.add(trigger.factorName);
      rawRisk += normalizedRisk * trigger.weight;
      totalWeight += trigger.weight;
    }

    final triggerRisk = totalWeight > 0
        ? (rawRisk / totalWeight).clamp(0.0, 1.0)
        : 0.0;

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
      final missedMedCount = recentLogs
          .where((l) => !l.medicationAdherence)
          .length;

      if (avgSleep < 6.0) rollingRisk += 0.15;
      if (avgSleep < 5.0) rollingRisk += 0.10;
      if (avgStress > 7.0) rollingRisk += 0.15;
      if (avgStress > 8.5) rollingRisk += 0.10;
      if (missedMedCount >= 2) rollingRisk += 0.15;
      if (missedMedCount >= 4) rollingRisk += 0.15;
    }

    rollingRisk = rollingRisk.clamp(0.0, 1.0);

    final recentSeizures = allSeizureLogs
        .where((log) => log.date.compareTo(today.date) < 0)
        .toList();

    double seizureHistoryRisk = 0.0;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentSeizureCount = recentSeizures.where((log) {
      final date = DateTime.parse(log.date);
      return date.isAfter(thirtyDaysAgo);
    }).length;

    if (recentSeizureCount >= 1) seizureHistoryRisk += 0.10;
    if (recentSeizureCount >= 3) seizureHistoryRisk += 0.10;
    if (recentSeizureCount >= 5) seizureHistoryRisk += 0.10;

    if (recentSeizures.isNotEmpty) {
      final lastSeizureDate = DateTime.parse(recentSeizures.last.date);
      final hoursSinceLastSeizure = DateTime.now()
          .difference(lastSeizureDate)
          .inHours;
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

    double interactionMultiplier = _calculateInteractionEffects(
      today: today,
      recentLogs: recentLogs,
      medicationStreak: medicationStreak,
      activeTriggers: activeTriggers,
    );

    combinedRisk = (combinedRisk * interactionMultiplier).clamp(0.0, 1.0);

    final riskScore = (combinedRisk * 100).roundToDouble();

    String riskLevel;
    if (riskScore < 30) {
      riskLevel = 'Low';
    } else if (riskScore < 60) {
      riskLevel = 'Moderate';
    } else {
      riskLevel = 'High';
    }

    final explanationParts = <String>[];
    if (avgSleep < 6.0)
      explanationParts.add('poor sleep (${avgSleep.toStringAsFixed(1)} hrs)');
    if (avgStress > 7.0)
      explanationParts.add('high stress (${avgStress.toStringAsFixed(1)}/10)');
    if (medicationStreak < 2) explanationParts.add('missed medication');
    if (recentSeizureCount >= 3)
      explanationParts.add('recent seizure activity');
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
      explanation =
          'Detected: ${parts.join(", ")}, and ${explanationParts.last}';
    }

    if (interactionMultiplier > 1.0) explanation += ' (dangerous combination)';

    return PredictionResult(
      riskScore: riskScore,
      riskLevel: riskLevel,
      activeTriggers: activeTriggers,
      explanation: explanation,
    );
  }

  double _calculateInteractionEffects({
    required DailyLog today,
    required List<DailyLog> recentLogs,
    required int medicationStreak,
    required List<String> activeTriggers,
  }) {
    double multiplier = 1.0;

    final avgSleep = recentLogs.isNotEmpty
        ? recentLogs.map((l) => l.sleepHours).reduce((a, b) => a + b) /
              recentLogs.length
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

  double? _getFactorValue(DailyLog log, String factorName) {
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

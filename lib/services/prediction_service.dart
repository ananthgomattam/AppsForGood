import 'dart:math';

import '../data/daily_log.dart';
import '../database/database_helper.dart';
import 'trigger_service.dart';

// Holds the full prediction output for today
class PredictionResult {
  final double safetyScore; // 0.0 (dangerous) to 1.0 (safe)
  final String riskLevel; // "Low", "Moderate", "High"
  final List<String> activeTriggers; // which triggers are active today
  final String explanation; // "High stress and poor sleep detected"

  PredictionResult({
    required this.safetyScore,
    required this.riskLevel,
    required this.activeTriggers,
    required this.explanation,
  });
}

class PredictionService {
  final TriggerService _triggerService = TriggerService();

  Future<PredictionResult> predict(DailyLog today) async {
    // Get fresh trigger weights every time
    final triggers = await _triggerService.analyzeTriggers();

    // Get all logs for rolling average and seizure history calculations
    final allDailyLogs = await DatabaseHelper.instance.getAllDailyLogs();
    final allSeizureLogs = await DatabaseHelper.instance.getAllSeizureLogs();

    // Sort by date for rolling calculations
    final sortedLogs = [...allDailyLogs]
      ..sort((a, b) => a.date.compareTo(b.date));

    // Track total risk and which triggers are active today
    double rawRisk = 0.0;
    double totalWeight = 0.0;
    final activeTriggers = <String>[];

    for (final trigger in triggers) {
      // Skip anything that isn't a confirmed trigger
      if (!trigger.isTrigger || trigger.weight == 0.0) continue;

      // Get today's value for this factor
      final todayValue = _getFactorValue(today, trigger.factorName);
      if (todayValue == null) continue;

      // How far is today from this user's normal average?
      final deviation = (todayValue - trigger.normalAvg).abs();

      // Normalize deviation
      final normalizedRisk = (deviation * trigger.weight).clamp(0.0, 1.0);

      if (normalizedRisk > 0.1) activeTriggers.add(trigger.factorName);

      rawRisk += normalizedRisk * trigger.weight;
      totalWeight += trigger.weight;
    }

    // Normalize total risk to 0-1 scale
    final triggerRisk = totalWeight > 0
        ? (rawRisk / totalWeight).clamp(0.0, 1.0)
        : 0.0;

    // Add rolling 7-day window risk based on recent patterns
    final recentLogs = sortedLogs
        .where((log) => log.date.compareTo(today.date) < 0)
        .toList()
        .reversed
        .take(7)
        .toList();

    double rollingRisk = 0.0;

    if (recentLogs.isNotEmpty) {
      final avgSleep =
          recentLogs.map((l) => l.sleepHours).reduce((a, b) => a + b) /
          recentLogs.length;
      final avgStress =
          recentLogs
              .map((l) => l.stressLevel.toDouble())
              .reduce((a, b) => a + b) /
          recentLogs.length;
      final missedMedCount = recentLogs
          .where((l) => !l.medicationAdherence)
          .length;

      // Low average sleep over 7 days → adds risk
      if (avgSleep < 6.0) rollingRisk += 0.15;
      if (avgSleep < 5.0) rollingRisk += 0.10; // extra penalty for severe deprivation

      // High average stress over 7 days → adds risk
      if (avgStress > 7.0) rollingRisk += 0.15;
      if (avgStress > 8.5) rollingRisk += 0.10;

      // Missed medication multiple days in a row → adds significant risk
      if (missedMedCount >= 2) rollingRisk += 0.15;
      if (missedMedCount >= 4) rollingRisk += 0.15;
    }

    rollingRisk = rollingRisk.clamp(0.0, 1.0);

    // Add seizure history risk based on recent seizures
    final recentSeizures = allSeizureLogs
        .where((log) => log.date.compareTo(today.date) < 0)
        .toList();

    double seizureHistoryRisk = 0.0;

    // Count seizures in last 30 days
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentSeizureCount = recentSeizures.where((log) {
      final date = DateTime.parse(log.date);
      return date.isAfter(thirtyDaysAgo);
    }).length;

    // More seizures recently = higher risk
    if (recentSeizureCount >= 1) seizureHistoryRisk += 0.10;
    if (recentSeizureCount >= 3) seizureHistoryRisk += 0.10;
    if (recentSeizureCount >= 5) seizureHistoryRisk += 0.10;

    // Extra risk if seizure was in the last 48 hours
    // Brain is most vulnerable right after a seizure
    if (recentSeizures.isNotEmpty) {
      final lastSeizureDate = DateTime.parse(recentSeizures.last.date);
      final hoursSinceLastSeizure = DateTime.now()
          .difference(lastSeizureDate)
          .inHours;
      if (hoursSinceLastSeizure < 48) seizureHistoryRisk += 0.20;
    }

    seizureHistoryRisk = seizureHistoryRisk.clamp(0.0, 1.0);

    // **STEP 1: Calculate medication streak (consecutive days of adherence)**
    // This identifies if user just stopped taking meds, amplifying other risks
    int medicationStreak = 0;
    for (final log in sortedLogs.reversed) {
      if (log.medicationAdherence) {
        medicationStreak++;
      } else {
        break;
      }
    }

    // **STEP 2: Combine all risk factors with weighted average**
    // Each factor contributes differently to overall risk
    // - Trigger deviation: 35% (what's abnormal TODAY)
    // - Rolling patterns: 30% (7-day trends catch gradual buildup)
    // - Seizure history: 25% (recent seizure activity primes the brain)
    // - Medication streak penalty: 10% (non-adherence is critical)

    final medicationPenalty = medicationStreak < 3 ? 0.2 : 0.0;
    double combinedRisk =
        (triggerRisk * 0.35) +
        (rollingRisk * 0.30) +
        (seizureHistoryRisk * 0.25) +
        (medicationPenalty * 0.10);

    // **STEP 3: Calculate interaction effects using ANOVA**
    // Tests if factor combinations (like low sleep + high stress) have synergistic effects
    double interactionMultiplier = await _calculateInteractionEffects(
      today: today,
      recentLogs: recentLogs,
      medicationStreak: medicationStreak,
      activeTriggers: activeTriggers,
      sortedLogs: sortedLogs,
    );

    // Apply multiplier to intensify risk if dangerous combinations detected
    combinedRisk = (combinedRisk * interactionMultiplier).clamp(0.0, 1.0);

    // **STEP 4: Convert risk score to safety score (inverse scale)**
    // safetyScore = 1.0 - combinedRisk
    // High risk = low safety, low risk = high safety
    final safetyScore = 1.0 - combinedRisk;

    // **STEP 5: Classify into risk level buckets**
    String riskLevel;
    if (safetyScore >= 0.7) {
      riskLevel = "Low";
    } else if (safetyScore >= 0.4) {
      riskLevel = "Moderate";
    } else {
      riskLevel = "High";
    }

    // **STEP 6: Generate human-readable explanation**
    final explanationParts = <String>[];

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

    if (avgSleep < 6.0) {
      explanationParts.add("poor sleep (${avgSleep.toStringAsFixed(1)} hrs)");
    }
    if (avgStress > 7.0) {
      explanationParts.add("high stress (${avgStress.toStringAsFixed(1)}/10)");
    }
    if (medicationStreak < 2) {
      explanationParts.add("missed medication");
    }
    if (recentSeizureCount >= 3) {
      explanationParts.add("recent seizure activity");
    }
    if (today.hormonalChanges == true) {
      explanationParts.add("hormonal changes");
    }

    // Format explanation based on number of detected issues
    String explanation;
    if (explanationParts.isEmpty) {
      explanation = "All factors within normal range";
    } else if (explanationParts.length == 1) {
      explanation = "Detected: ${explanationParts[0]}";
    } else if (explanationParts.length == 2) {
      explanation =
          "Detected: ${explanationParts[0]} and ${explanationParts[1]}";
    } else {
      final parts = explanationParts.sublist(0, explanationParts.length - 1);
      explanation =
          "Detected: ${parts.join(", ")}, and ${explanationParts.last}";
    }

    // Note if dangerous interaction detected
    if (interactionMultiplier > 1.0) {
      explanation += " (dangerous combination)";
    }

    // **STEP 7: Return complete prediction result**
    return PredictionResult(
      safetyScore: safetyScore,
      riskLevel: riskLevel,
      activeTriggers: activeTriggers,
      explanation: explanation,
    );
  }

  // Helper: Calculate interaction effects
  Future<double> _calculateInteractionEffects({
    required DailyLog today,
    required List<DailyLog> recentLogs,
    required int medicationStreak,
    required List<String> activeTriggers,
    required List<DailyLog> sortedLogs,
  }) async {
    return _getHeuristicInteractionMultiplier(
      today: today,
      recentLogs: recentLogs,
      medicationStreak: medicationStreak,
      activeTriggers: activeTriggers,
    );
  }

  // Helper: Heuristic fallback when insufficient data**
  double _getHeuristicInteractionMultiplier({
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

    // Low sleep + high stress: 1.4x
    if (avgSleep < 6.0 && avgStress > 7.0) {
      multiplier = 1.4;
    }
    // Missed medication + active triggers: 1.35x
    else if (medicationStreak < 2 && activeTriggers.isNotEmpty) {
      multiplier = 1.35;
    }
    // Hormonal changes + high stress: 1.25x
    else if (today.hormonalChanges == true && today.stressLevel > 7) {
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

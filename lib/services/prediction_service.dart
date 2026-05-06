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

    double totalTriggerRisk = 0.0;
    double totalTriggerWeight = 0.0;
    final activeTriggers = <String>[];

    for (final trigger in triggers) {
      if (!trigger.isTrigger || trigger.weight == 0.0) continue;
      
      final todayValue = _getFactorValue(today, trigger.factorName);
      if (todayValue == null) continue;
      
      final triggerContribution = _calculateTriggerContribution(
        todayValue: todayValue,
        trigger: trigger,
      );
      
      if (triggerContribution > 0.1) {
        activeTriggers.add(trigger.factorName);
      }
      
      totalTriggerRisk += triggerContribution * trigger.weight;
      totalTriggerWeight += trigger.weight;
    }

    final triggerRisk = totalTriggerWeight > 0
        ? (totalTriggerRisk / totalTriggerWeight).clamp(0.0, 1.0)
        : 0.0;

    final beforeToday = sortedLogs
        .where((log) => log.date.compareTo(today.date) < 0)
        .toList();
    final recentLogs = beforeToday.reversed.take(7).toList();

    double averageSleepHours = 7.0;
    double averageStressLevel = 5.0;
    double rollingRisk = 0.0;

    if (recentLogs.isNotEmpty) {
      double totalSleep = 0.0;
      double totalStress = 0.0;
      
      for (final log in recentLogs) {
        totalSleep += log.sleepHours;
        totalStress += log.stressLevel.toDouble();
      }
      
      averageSleepHours = totalSleep / recentLogs.length;
      averageStressLevel = totalStress / recentLogs.length;
      
      final missedMedicationCount = recentLogs
          .where((log) => !log.medicationAdherence)
          .length;

      if (averageSleepHours < 6.0) rollingRisk += 0.15;
      if (averageSleepHours < 5.0) rollingRisk += 0.10;
      if (averageStressLevel > 7.0) rollingRisk += 0.15;
      if (averageStressLevel > 8.5) rollingRisk += 0.10;
      if (missedMedicationCount >= 2) rollingRisk += 0.15;
      if (missedMedicationCount >= 4) rollingRisk += 0.15;
    }

    rollingRisk = rollingRisk.clamp(0.0, 1.0);

    final allSeizuresBeforeToday = allSeizureLogs
        .where((log) => log.date.compareTo(today.date) < 0)
        .toList();

    double seizureHistoryRisk = 0.0;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    int recentSeizureCount = 0;
    for (final seizure in allSeizuresBeforeToday) {
      final seizureDate = DateTime.parse(seizure.date);
      if (seizureDate.isAfter(thirtyDaysAgo)) {
        recentSeizureCount++;
      }
    }

    if (recentSeizureCount >= 1) seizureHistoryRisk += 0.10;
    if (recentSeizureCount >= 3) seizureHistoryRisk += 0.10;
    if (recentSeizureCount >= 5) seizureHistoryRisk += 0.10;

    if (allSeizuresBeforeToday.isNotEmpty) {
      final lastSeizure = allSeizuresBeforeToday.last;
      final lastSeizureDate = DateTime.parse(lastSeizure.date);
      final hoursSinceLastSeizure = DateTime.now()
          .difference(lastSeizureDate)
          .inHours;
      if (hoursSinceLastSeizure < 48) {
        seizureHistoryRisk += 0.20;
      }
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

    String riskLevel;
    if (riskScore < 30) {
      riskLevel = 'Low';
    } else if (riskScore < 60) {
      riskLevel = 'Moderate';
    } else {
      riskLevel = 'High';
    }

    final factors = <String>[];
    
    if (averageSleepHours < 6.0) {
      final sleepFormatted = averageSleepHours.toStringAsFixed(1);
      factors.add('poor sleep ($sleepFormatted hrs)');
    }
    
    if (averageStressLevel > 7.0) {
      final stressFormatted = averageStressLevel.toStringAsFixed(1);
      factors.add('high stress ($stressFormatted/10)');
    }
    
    if (medicationStreak < 2) {
      factors.add('missed medication');
    }
    
    if (recentSeizureCount >= 3) {
      factors.add('recent seizure activity');
    }
    
    if (today.hormonalChanges == true) {
      factors.add('hormonal changes');
    }

    String explanation;
    if (factors.isEmpty) {
      explanation = 'All factors within normal range';
    } else if (factors.length == 1) {
      explanation = 'Detected: ${factors[0]}';
    } else if (factors.length == 2) {
      explanation = 'Detected: ${factors[0]} and ${factors[1]}';
    } else {
      final allButLast = factors.sublist(0, factors.length - 1);
      final allButLastJoined = allButLast.join(', ');
      explanation = 'Detected: $allButLastJoined, and ${factors.last}';
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

  double _calculateInteractionEffects({
    required DailyLog today,
    required List<DailyLog> recentLogs,
    required int medicationStreak,
    required List<String> activeTriggers,
  }) {
    double multiplier = 1.0;

    double averageSleep = 7.0;
    double averageStress = 5.0;
    
    if (recentLogs.isNotEmpty) {
      double totalSleep = 0.0;
      double totalStress = 0.0;
      
      for (final log in recentLogs) {
        totalSleep += log.sleepHours;
        totalStress += log.stressLevel.toDouble();
      }
      
      averageSleep = totalSleep / recentLogs.length;
      averageStress = totalStress / recentLogs.length;
    }

    final poorSleepAndHighStress = averageSleep < 6.0 && averageStress > 7.0;
    if (poorSleepAndHighStress) {
      multiplier = 1.4;
      return multiplier;
    }

    final missedMedsAndTriggers = medicationStreak < 2 && activeTriggers.isNotEmpty;
    if (missedMedsAndTriggers) {
      multiplier = 1.35;
      return multiplier;
    }

    final hormonalAndStressed = today.hormonalChanges == true && today.stressLevel > 7;
    if (hormonalAndStressed) {
      multiplier = 1.25;
    }

    return multiplier;
  }

  double _calculateTriggerContribution({
    required double todayValue,
    required TriggerResult trigger,
  }) {
    final trend = trigger.seizureAvg - trigger.normalAvg;

    final isWeatherFactor =
        trigger.factorName == 'Temperature' ||
        trigger.factorName == 'Pressure' ||
        trigger.factorName == 'Humidity';

    if (isWeatherFactor) {
      final deviation = (todayValue - trigger.normalAvg).abs();
      return (deviation * trigger.weight).clamp(0.0, 1.0);
    }

    if (trend == 0.0) {
      return 0.0;
    }

    final directionalChange = (todayValue - trigger.normalAvg) * trend.sign;
    if (directionalChange <= 0.0) {
      return 0.0;
    }

    return (directionalChange * trigger.weight).clamp(0.0, 1.0);
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

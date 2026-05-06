import 'daily_log.dart';

class SeizureLog {
  final int? id;
  final String username;
  final String date;
  final String timeOfDay;
  final int durationSeconds;
  final String seizureType;
  final String? symptoms;
  final int mood; // 1–5
  final String? notes;
  final String createdAt;

  final DailyLog dailyLog;

  SeizureLog({
    this.id,
    required this.username,
    required this.date,
    required this.timeOfDay,
    required this.durationSeconds,
    required this.seizureType,
    this.symptoms,
    required this.mood,
    this.notes,
    required this.createdAt,
    required this.dailyLog,
  });

  // For writing TO the database
  Map<String, dynamic> toMap() {
    final daily = dailyLog.toMap();
    return {
      if (id != null) 'id': id,
      'username': username,
      'date': date,
      'timeOfDay': timeOfDay,
      'durationSeconds': durationSeconds,
      'seizureType': seizureType,
      'symptoms': symptoms,
      'mood': mood,
      'notes': notes,
      'createdAt': createdAt,
      'isSeizure': 1,
      'medicationAdherence': daily['medicationAdherence'],
      'sleepHours': daily['sleepHours'],
      'sleepQuality': daily['sleepQuality'],
      'sleepInterruptions': daily['sleepInterruptions'],
      'stressLevel': daily['stressLevel'],
      'dietQuality': daily['dietQuality'],
      'drugUse': daily['drugUse'],
      'hormonalChanges': daily['hormonalChanges'],
      'temperature': daily['temperature'],
      'pressure': daily['pressure'],
      'humidity': daily['humidity'],
    };
  }

  // For reading BACK from the database
  factory SeizureLog.fromMap(Map<String, dynamic> map) {
    // Build a minimal DailyLog from columns embedded in the seizure row.
    final daily = DailyLog.fromMap({
      'id': null,
      'username': (map['username'] ?? 'unknown') as String,
      'date': (map['date'] ?? '') as String,
      'medicationAdherence': map['medicationAdherence'] ?? 0,
      'sleepHours': map['sleepHours'] ?? 0.0,
      'sleepQuality': map['sleepQuality'] ?? 3,
      'sleepInterruptions': map['sleepInterruptions'] ?? 0,
      'stressLevel': map['stressLevel'] ?? 5,
      'dietQuality': map['dietQuality'] ?? 3,
      'drugUse': map['drugUse'] ?? 0,
      'hormonalChanges': map['hormonalChanges'],
      'createdAt': (map['createdAt'] ?? DateTime.now().toIso8601String()) as String,
      'temperature': map['temperature'],
      'pressure': map['pressure'],
      'humidity': map['humidity'],
      'notes': null,
      'isSeizure': 1,
    });

    return SeizureLog(
      id: map['id'] as int?,
      username: (map['username'] ?? 'unknown') as String,
      date: (map['date'] ?? '') as String,
      timeOfDay: (map['timeOfDay'] ?? '') as String,
      durationSeconds: (map['durationSeconds'] as int?) ?? 0,
      seizureType: (map['seizureType'] ?? '') as String,
      symptoms: map['symptoms'] as String?,
      mood: (map['mood'] as int?) ?? 3,
      notes: map['notes'] as String?,
      createdAt: (map['createdAt'] ?? DateTime.now().toIso8601String()) as String,
      dailyLog: daily,
    );
  }

  // For editing an existing log without rewriting every field
  SeizureLog copyWith({
    int? id,
    String? username,
    String? date,
    String? timeOfDay,
    int? durationSeconds,
    String? seizureType,
    String? symptoms,
    int? mood,
    String? notes,
    String? createdAt,
    DailyLog? dailyLog,
  }) {
    return SeizureLog(
      id: id ?? this.id,
      username: username ?? this.username,
      date: date ?? this.date,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      seizureType: seizureType ?? this.seizureType,
      symptoms: symptoms ?? this.symptoms,
      mood: mood ?? this.mood,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      dailyLog: dailyLog ?? this.dailyLog,
    );
  }
}

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
    final daily = DailyLog.fromMap({
      'id': null,
      'date': map['date'],
      'medicationAdherence': map['medicationAdherence'],
      'sleepHours': map['sleepHours'],
      'sleepQuality': map['sleepQuality'],
      'sleepInterruptions': map['sleepInterruptions'],
      'stressLevel': map['stressLevel'],
      'dietQuality': map['dietQuality'],
      'drugUse': map['drugUse'],
      'hormonalChanges': map['hormonalChanges'],
      'createdAt': map['createdAt'],
      'temperature': map['temperature'],
      'pressure': map['pressure'],
      'humidity': map['humidity'],
      'notes': null,
    });

    return SeizureLog(
      id: map['id'] as int?,
      username: map['username'] as String,
      date: map['date'] as String,
      timeOfDay: map['timeOfDay'] as String,
      durationSeconds: map['durationSeconds'] as int,
      seizureType: map['seizureType'] as String,
      symptoms: map['symptoms'] as String?,
      mood: map['mood'] as int,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] as String,
      dailyLog: daily,
    );
  }

  // For editing an existing log without rewriting every field
  SeizureLog copyWith({
    int? id,
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
      username: this.username,
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
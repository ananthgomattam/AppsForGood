class DailyLog {
  final int? id;
  final String username;
  final String date;
  final bool medicationAdherence;
  final double sleepHours;
  final int sleepQuality; // 1-5
  final int sleepInterruptions;
  final int stressLevel; // 1-10
  final int dietQuality; // 1-5 
  final bool drugUse;
  final bool? hormonalChanges;
  final String? notes;
  final String createdAt;

  // Auto-filled later
  final double? temperature;
  final double? pressure;
  final double? humidity;

  DailyLog({
    this.id,
    required this.username,
    required this.date, 
    required this.medicationAdherence,
    required this.sleepHours,
    required this.sleepQuality,
    required this.sleepInterruptions,
    required this.stressLevel,
    required this.dietQuality,
    required this.drugUse,
    this.hormonalChanges,
    this.notes,
    required this.createdAt,
    this.temperature,
    this.pressure,
    this.humidity,
  });

  // For writing TO the database
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'username': username,
      'date': date,
      'medicationAdherence': medicationAdherence ? 1 : 0,
      'sleepHours': sleepHours,
      'sleepQuality': sleepQuality,
      'sleepInterruptions': sleepInterruptions,
      'stressLevel': stressLevel,
      'dietQuality': dietQuality,
      'drugUse': drugUse ? 1 : 0,
      'hormonalChanges': hormonalChanges == null ? null : (hormonalChanges! ? 1 : 0),
      'createdAt': createdAt,
      'temperature': temperature,
      'pressure': pressure,
      'humidity': humidity,
      'notes': notes,
    };
  }

  // For reading BACK from the database
  factory DailyLog.fromMap(Map<String, dynamic> map) {
    return DailyLog(
      id: map['id'] as int?,
      username: map['username'] as String,
      date: map['date'] as String,
      medicationAdherence: map['medicationAdherence'] == 1,
      sleepHours: (map['sleepHours'] as num).toDouble(),
      sleepQuality: map['sleepQuality'] as int,
      sleepInterruptions: map['sleepInterruptions'] as int,
      stressLevel: map['stressLevel'] as int,
      dietQuality: map['dietQuality'] as int,
      drugUse: map['drugUse'] == 1,
      hormonalChanges: map['hormonalChanges'] == null ? null : map['hormonalChanges'] == 1,
      createdAt: map['createdAt'] as String,
      temperature: (map['temperature'] as num?)?.toDouble(),
      pressure: (map['pressure'] as num?)?.toDouble(),
      humidity: (map['humidity'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
    );
  }

  // For editing an existing log without rewriting every field
  DailyLog copyWith({
    int? id,
    String? date,
    bool? medicationAdherence,
    double? sleepHours,
    int? sleepQuality,
    int? sleepInterruptions,
    int? stressLevel,
    int? dietQuality,
    bool? drugUse,
    bool? hormonalChanges,
    String? createdAt,
    double? temperature,
    double? pressure,
    double? humidity,
    String? notes,
  }) {
    return DailyLog(
      id: id ?? this.id,
      username: this.username,
      date: date ?? this.date,
      medicationAdherence: medicationAdherence ?? this.medicationAdherence,
      sleepHours: sleepHours ?? this.sleepHours,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      sleepInterruptions: sleepInterruptions ?? this.sleepInterruptions,
      stressLevel: stressLevel ?? this.stressLevel,
      dietQuality: dietQuality ?? this.dietQuality,
      drugUse: drugUse ?? this.drugUse,
      hormonalChanges: hormonalChanges ?? this.hormonalChanges,
      createdAt: createdAt ?? this.createdAt,
      temperature: temperature ?? this.temperature,
      pressure: pressure ?? this.pressure,
      humidity: humidity ?? this.humidity,
      notes: notes ?? this.notes,
    );
  }

}
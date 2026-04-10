class Medication {
  final int? id;
  final String username;
  final String name;
  final String dosage;
  final int frequencyCount;
  final String frequencyUnit;
  final String timesList;
  final String startDate;
  final String? endDate;
  final String? notes;
  final String createdAt;

  Medication({
    this.id,
    required this.username,
    required this.name,
    required this.dosage,
    required this.frequencyCount,
    required this.frequencyUnit,
    required this.timesList,
    required this.startDate,
    this.endDate,
    this.notes,
    required this.createdAt,
  });

  // For writing TO the database
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'username': username,
      'name': name,
      'dosage': dosage,
      'frequencyCount': frequencyCount,
      'frequencyUnit': frequencyUnit,
      'timesList': timesList,
      'startDate': startDate,
      'endDate': endDate,
      'notes': notes,
      'createdAt': createdAt,
    };
  }

  // For reading BACK from the database
  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] as int?,
      username: map['username'] as String,
      name: map['name'] as String,
      dosage: map['dosage'] as String,
      frequencyCount: map['frequencyCount'] as int,
      frequencyUnit: map['frequencyUnit'] as String,
      timesList: map['timesList'] as String,
      startDate: map['startDate'] as String,
      endDate: map['endDate'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] as String,
    );
  }

  // For updating existing medication with new values
  Medication copyWith({
    int? id,
    String? name,
    String? dosage,
    int? frequencyCount,
    String? frequencyUnit,
    String? timesList,
    String? startDate,
    String? endDate,
    String? notes,
    String? createdAt,
  }) {
    return Medication(
      id: id ?? this.id,
      username: this.username,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequencyCount: frequencyCount ?? this.frequencyCount,
      frequencyUnit: frequencyUnit ?? this.frequencyUnit,
      timesList: timesList ?? this.timesList,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }


}
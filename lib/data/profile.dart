class Profile {
  final int? id;
  final String username;
  final String name;
  final String dateOfBirth;
  final String? gender;
  final String? diagnosisType;
  final String? diagnosisDate;
  final String? doctorName;
  final String? doctorPhone;
  final String? hospitalPreference;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelation;
  final int dailyLogRemainderHour; // 0-23
  final int dailyLogRemainderMinute; // 0-59
  final bool seizureNotifications;
  final String createdAt;

  Profile({
    this.id,
    required this.username,
    required this.name,
    required this.dateOfBirth,
    this.gender,
    this.diagnosisType,
    this.diagnosisDate,
    this.doctorName,

    this.doctorPhone,
    this.hospitalPreference,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelation,
    required this.dailyLogRemainderHour,
    required this.dailyLogRemainderMinute,
    required this.seizureNotifications,
    required this.createdAt,
  });

  // For writing TO the database
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'username': username,
      'name': name,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'diagnosisType': diagnosisType,
      'diagnosisDate': diagnosisDate,
      'doctorName': doctorName,
      'doctorPhone': doctorPhone,
      'hospitalPreference': hospitalPreference,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'emergencyContactRelation': emergencyContactRelation,
      'dailyLogRemainderHour': dailyLogRemainderHour,
      'dailyLogRemainderMinute': dailyLogRemainderMinute,
      'seizureNotifications': seizureNotifications ? 1 : 0,
      'createdAt': createdAt,
    };
  }

  // For reading BACK from the database
  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as int?,
      username: map['username'] as String,
      name: map['name'] as String,
      dateOfBirth: map['dateOfBirth'] as String,
      gender: map['gender'] as String?,
      diagnosisType: map['diagnosisType'] as String?,
      diagnosisDate: map['diagnosisDate'] as String?,
      doctorName: map['doctorName'] as String?,
      doctorPhone: map['doctorPhone'] as String?,
      hospitalPreference: map['hospitalPreference'] as String?,
      emergencyContactName: map['emergencyContactName'] as String?,
      emergencyContactPhone: map['emergencyContactPhone'] as String?,
      emergencyContactRelation: map['emergencyContactRelation'] as String?,
      dailyLogRemainderHour: map['dailyLogRemainderHour'] as int,
      dailyLogRemainderMinute: map['dailyLogRemainderMinute'] as int,
      seizureNotifications: map['seizureNotifications'] == 1,
      createdAt: map['createdAt'] as String,
    );
  }
  
  // For updating existing profile with new values
  Profile copyWith({
    int? id,
    String? name,
    String? dateOfBirth,
    String? gender,
    String? diagnosisType,
    String? diagnosisDate,
    String? doctorName,
    String? doctorPhone,
    String? hospitalPreference,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    int? dailyLogRemainderHour,
    int? dailyLogRemainderMinute,
    bool? seizureNotifications,
    String? createdAt,
  }) {
    return Profile(
      id: id ?? this.id,
      username: this.username,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      diagnosisType: diagnosisType ?? this.diagnosisType,
      diagnosisDate: diagnosisDate ?? this.diagnosisDate,
      doctorName: doctorName ?? this.doctorName,
      doctorPhone: doctorPhone ?? this.doctorPhone,
      hospitalPreference: hospitalPreference ?? this.hospitalPreference,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelation: emergencyContactRelation ?? this.emergencyContactRelation,
      dailyLogRemainderHour: dailyLogRemainderHour ?? this.dailyLogRemainderHour,
      dailyLogRemainderMinute: dailyLogRemainderMinute ?? this.dailyLogRemainderMinute,
      seizureNotifications: seizureNotifications ?? this.seizureNotifications,
      createdAt: createdAt ?? this.createdAt,
    );
  }

}
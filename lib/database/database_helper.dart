import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../data/daily_log.dart';
import '../data/seizure_log.dart';
import '../data/profile.dart';
import '../data/medication.dart';
import '../data/test_dataset.dart';
import '../frontend/account_store.dart';

class DatabaseHelper {
  // Create instance of database helper for use in app
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static String? _currentUsername;

  DatabaseHelper._init();

  // Set the current username when user logs in
  static Future<void> setCurrentUser(String username) async {
    _currentUsername = username;
  }

  // Clear the current user and reset database when logging out
  static Future<void> clearCurrentUser() async {
    _currentUsername = null;
    _database = null;
  }

  Future<String?> _getCurrentUsername() async {
    if (_currentUsername != null) return _currentUsername;
    _currentUsername = await FrontendAccountStore.instance.getCurrentUsername();
    return _currentUsername;
  }

  Future<Database> get database async {
    // If database already exists, return it. Otherwise, create it and return it.
    if (_database != null) {
      return _database!;
    }
    _database = await _initDB('forseizure.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Get the default database path for the device and append our file name to it
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add username column to all tables
      try {
        await db.execute('ALTER TABLE profile ADD COLUMN username TEXT NOT NULL DEFAULT "unknown"');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE medication ADD COLUMN username TEXT NOT NULL DEFAULT "unknown"');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE daily_log ADD COLUMN username TEXT NOT NULL DEFAULT "unknown"');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE seizure_log ADD COLUMN username TEXT NOT NULL DEFAULT "unknown"');
      } catch (_) {}
    }
  }

  Future<void> _ensureTables(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS profile (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      dateOfBirth TEXT NOT NULL,
      gender TEXT,
      diagnosisType TEXT,
      diagnosisDate TEXT,
      doctorName TEXT,
      doctorPhone TEXT,
      hospitalPreference TEXT,
      emergencyContactName TEXT,
      emergencyContactPhone TEXT,
      emergencyContactRelation TEXT,
      dailyLogRemainderHour INTEGER NOT NULL,
      dailyLogRemainderMinute INTEGER NOT NULL,
      seizureNotifications INTEGER NOT NULL,
      createdAt TEXT NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS medication (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      dosage TEXT NOT NULL,
      frequencyCount INTEGER NOT NULL,
      frequencyUnit TEXT NOT NULL,
      timesList TEXT NOT NULL,
      startDate TEXT NOT NULL,
      endDate TEXT,
      notes TEXT,
      createdAt TEXT NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS daily_log (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      medicationAdherence INTEGER NOT NULL,
      sleepHours REAL NOT NULL,
      sleepQuality INTEGER NOT NULL,
      sleepInterruptions INTEGER NOT NULL,
      stressLevel INTEGER NOT NULL,
      dietQuality INTEGER NOT NULL,
      drugUse INTEGER NOT NULL,
      hormonalChanges INTEGER,
      createdAt TEXT NOT NULL,
      temperature REAL,
      pressure REAL,
      humidity REAL,
      notes TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS seizure_log (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      timeOfDay TEXT NOT NULL,
      durationSeconds INTEGER NOT NULL,
      seizureType TEXT NOT NULL,
      symptoms TEXT,
      mood INTEGER NOT NULL,
      notes TEXT,
      createdAt TEXT NOT NULL,
      medicationAdherence INTEGER NOT NULL,
      sleepHours REAL NOT NULL,
      sleepQuality INTEGER NOT NULL,
      sleepInterruptions INTEGER NOT NULL,
      stressLevel INTEGER NOT NULL,
      dietQuality INTEGER NOT NULL,
      drugUse INTEGER NOT NULL,
      hormonalChanges INTEGER,
      temperature REAL,
      pressure REAL,
      humidity REAL
    )
    ''');
  }

  // Create the database tables for each of the data files
  Future _createDB(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
    CREATE TABLE profile (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL,
      name TEXT NOT NULL,
      dateOfBirth TEXT NOT NULL,
      gender TEXT,
      diagnosisType TEXT,
      diagnosisDate TEXT,
      doctorName TEXT,
      doctorPhone TEXT,
      hospitalPreference TEXT,
      emergencyContactName TEXT,
      emergencyContactPhone TEXT,
      emergencyContactRelation TEXT,
      dailyLogRemainderHour INTEGER NOT NULL,
      dailyLogRemainderMinute INTEGER NOT NULL,
      seizureNotifications INTEGER NOT NULL,
      createdAt TEXT NOT NULL
    )
    ''');

    batch.execute('''
    CREATE TABLE medication (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL,
      name TEXT NOT NULL,
      dosage TEXT NOT NULL,
      frequencyCount INTEGER NOT NULL,
      frequencyUnit TEXT NOT NULL,
      timesList TEXT NOT NULL,
      startDate TEXT NOT NULL,
      endDate TEXT,
      notes TEXT,
      createdAt TEXT NOT NULL
    )
    ''');

    batch.execute('''
    CREATE TABLE daily_log (
      username TEXT NOT NULL,
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      medicationAdherence INTEGER NOT NULL,
      sleepHours REAL NOT NULL,
      sleepQuality INTEGER NOT NULL,
      sleepInterruptions INTEGER NOT NULL,
      stressLevel INTEGER NOT NULL,
      dietQuality INTEGER NOT NULL,
      drugUse INTEGER NOT NULL,
      hormonalChanges INTEGER,
      createdAt TEXT NOT NULL,
      temperature REAL,
      pressure REAL,
      humidity REAL,
      notes TEXT
    )
    ''');

    batch.execute('''
    CRusername TEXT NOT NULL,
      EATE TABLE seizure_log (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      timeOfDay TEXT NOT NULL,
      durationSeconds INTEGER NOT NULL,
      seizureType TEXT NOT NULL,
      symptoms TEXT,
      mood INTEGER NOT NULL,
      notes TEXT,
      createdAt TEXT NOT NULL,
      medicationAdherence INTEGER NOT NULL,
      sleepHours REAL NOT NULL,
      sleepQuality INTEGER NOT NULL,
      sleepInterruptions INTEGER NOT NULL,
      stressLevel INTEGER NOT NULL,
      dietQuality INTEGER NOT NULL,
      drugUse INTEGER NOT NULL,
      hormonalChanges INTEGER,
      temperature REAL,
      pressure REAL,
      humidity REAL
    )
    ''');

    await batch.commit(noResult: true);
  }

  // CRUD operations for profile

  // Insert a new profile (only ever one row, but this is for the initial creation)
  Future<int> insertProfile(Profile profile) async {
    final db = await instance.database;
    final username = await _getCurrentUsername();
    final map = profile.toMap();
    map['username'] = username;
    return await db.insert('profile', map);
  }

  // Get the profile (only ever one row)
  Future<Profile?> getProfile() async {
    final db = await instance.database;
    final username = await _getCurrentUsername();
    final results = await db.query('profile', where: 'username = ?', whereArgs: [username]);
    if (results.isEmpty) {
      return null;
    }
    return Profile.fromMap(results.first);
  }

  // Update existing profile
  Future<int> updateProfile(Profile profile) async {
    final db = await instance.database;
    final map = profile.toMap();
    return await db.update(
      'profile',
      map,
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  // Delete profile (probably never used but good to have)
  Future<int> deleteProfile(int id) async {
    final db = await instance.database;
    return await db.delete('profile', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD operations for medication

  // Insert a new medication
  Future<int> insertMedication(Medication medication) async {
    final db = await instance.database;
    final username = await _getCurrentUsername();
    final map = medication.toMap();
    map['username'] = username;
    return await db.insert('medication', map);
  }

  // Get all medications (returns a list)
  Future<List<Medication>> getAllMedications() async {
    final db = await instance.database;
    final username = await _getCurrentUsername();
    final results = await db.query('medication', where: 'username = ?', whereArgs: [username]);
    return results.map((row) => Medication.fromMap(row)).toList();
  }

  // Update existing medication
  Future<int> updateMedication(Medication medication) async {
    final db = await instance.database;
    return await db.update(
      'medication',
      medication.toMap(),
      where: 'id = ?',
      whereArgs: [medication.id],
    );
  }

  // Delete a medication
  Future<int> deleteMedication(int id) async {
    final db = await instance.database;
    return await db.delete('medication', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD operations for daily log

  // Insert a new daily log
  Future<int> insertDailyLog(DailyLog log) async {
    final db = await instance.database;
    final username = await _getCurrentUsername();
    final map = log.toMap();
    map['username'] = username;
    return await db.insert('daily_log', map);
  }

  // Get all daily logs
  Future<List<DailyLog>> getAllDailyLogs() async {
    final db = await instance.database;
    final username = await _getCurrentUsername();
    final results = await db.query('daily_log', where: 'username = ?', whereArgs: [username]);
    final logs = <DailyLog>[];
    for (final row in results) {
      try {
        logs.add(DailyLog.fromMap(row));
      } catch (_) {
        // Skip malformed rows so analytics screens can still render.
      }
    }
    return logs;
  }

  // Get a specific day's log by date string
  Future<DailyLog?> getDailyLogByDate(String date) async {
    final db = await instance.database;
    final username = await _getCurrentUsername();
    final results = await db.query(
      'daily_log',
      where: 'username = ? AND date = ?',
      whereArgs: [username, date],
    );
    if (results.isEmpty) {
      return null;
    }
    return DailyLog.fromMap(results.first);
  }

  // Update existing daily log
  Future<int> updateDailyLog(DailyLog log) async {
    final db = await instance.database;
    return await db.update(
      'daily_log',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  // Delete a daily log
  Future<int> deleteDailyLog(int id) async {
    final db = await instance.database;
    return await db.delete('daily_log', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD operations for seizure log

  // Insert a new seizure log
  Future<int> insertSeizureLog(SeizureLog log) async {
    final db = await instance.database;
    final username = await _getCurrentUsername();
    final map = log.toMap();
    map['username'] = username;
    return await db.insert('seizure_log', map);
  }

  // Get all seizure logs
  Future<List<SeizureLog>> getAllSeizureLogs() async {
    final db = await instance.database;
    final username = await _getCurrentUsername();
    final results = await db.query('seizure_log', where: 'username = ?', whereArgs: [username]);
    final logs = <SeizureLog>[];
    for (final row in results) {
      try {
        logs.add(SeizureLog.fromMap(row));
      } catch (_) {
        // Skip malformed rows so analytics screens can still render.
      }
    }
    return logs;
  }

  // Get all seizure logs for a specific date
  Future<List<SeizureLog>> getSeizureLogsByDate(String date) async {
    final db = await instance.database;
    final username = await _getCurrentUsername();
    final results = await db.query(
      'seizure_log',
      where: 'username = ? AND date = ?',
      whereArgs: [username, date],
    );
    return results.map((row) => SeizureLog.fromMap(row)).toList();
  }

  // Update existing seizure log
  Future<int> updateSeizureLog(SeizureLog log) async {
    final db = await instance.database;
    return await db.update(
      'seizure_log',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  // Delete a seizure log
  Future<int> deleteSeizureLog(int id) async {
    final db = await instance.database;
    return await db.delete('seizure_log', where: 'id = ?', whereArgs: [id]);
  }

  // Force-loads a fixed dataset so UI and model behavior are consistent for demos/tests.
  Future<void> loadFixedTestData() async {
    final db = await instance.database;
    await _ensureTables(db);

    await db.transaction((txn) async {
      await txn.delete('seizure_log');
      await txn.delete('daily_log');

      var seizureOrdinal = 0;
      for (final entry in fixedTestDataset) {
        final createdAt = '${entry.date}T08:00:00.000';

        final dailyMap = {
          'date': entry.date,
          'medicationAdherence': entry.medicationAdherence ? 1 : 0,
          'sleepHours': entry.sleepHours,
          'sleepQuality': entry.sleepQuality,
          'sleepInterruptions': entry.sleepInterruptions,
          'stressLevel': entry.stressLevel,
          'dietQuality': entry.dietQuality,
          'drugUse': entry.drugUse ? 1 : 0,
          'hormonalChanges': entry.hormonalChanges ? 1 : 0,
          'createdAt': createdAt,
          'temperature': null,
          'pressure': null,
          'humidity': null,
          'notes': 'Fixed test dataset',
        };

        await txn.insert('daily_log', dailyMap);

        for (var i = 0; i < entry.seizureCount; i++) {
          seizureOrdinal += 1;
          final hour = (9 + i).toString().padLeft(2, '0');

          await txn.insert('seizure_log', {
            'date': entry.date,
            'timeOfDay': '$hour:00',
            'durationSeconds': 60 + (i * 30),
            'seizureType': 'Tonic-clonic',
            'symptoms': 'Test seizure #$seizureOrdinal',
            'mood': entry.sleepQuality,
            'notes': 'Fixed test dataset',
            'createdAt': '${entry.date}T$hour:00:00.000',
            'medicationAdherence': entry.medicationAdherence ? 1 : 0,
            'sleepHours': entry.sleepHours,
            'sleepQuality': entry.sleepQuality,
            'sleepInterruptions': entry.sleepInterruptions,
            'stressLevel': entry.stressLevel,
            'dietQuality': entry.dietQuality,
            'drugUse': entry.drugUse ? 1 : 0,
            'hormonalChanges': entry.hormonalChanges ? 1 : 0,
            'temperature': null,
            'pressure': null,
            'humidity': null,
          });
        }
      }
    });
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

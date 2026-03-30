import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../data/daily_log.dart';
import '../data/seizure_log.dart';
import '../data/profile.dart';
import '../data/medication.dart';

class DatabaseHelper {

  // Create instance of database helper for use in app
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

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
      version: 1,
      onCreate: _createDB,
    );
  }

  // Create the database tables for each of the data files
  Future _createDB(Database db, int version) async {
  await db.execute('''
    CREATE TABLE profile (
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
    );

    CREATE TABLE medication (
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
    );

    CREATE TABLE daily_log (
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
    );

    
    CREATE TABLE seizure_log (
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
    );

  ''');
  }

  // CRUD operations for profile
  
  // Insert a new profile (only ever one row, but this is for the initial creation)
  Future<int> insertProfile(Profile profile) async {
    final db = await instance.database;
    return await db.insert('profile', profile.toMap());
  }

  // Get the profile (only ever one row)
  Future<Profile?> getProfile() async {
    final db = await instance.database;
    final results = await db.query('profile');
    if (results.isEmpty) {
      return null;
    }
    return Profile.fromMap(results.first);
  }

  // Update existing profile
  Future<int> updateProfile(Profile profile) async {
    final db = await instance.database;
    return await db.update('profile', profile.toMap(), where: 'id = ?', whereArgs: [profile.id]);
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
    return await db.insert('medication', medication.toMap());
  }

  // Get all medications (returns a list)
  Future<List<Medication>> getAllMedications() async {
    final db = await instance.database;
    final results = await db.query('medication');
    return results.map((row) => Medication.fromMap(row)).toList();
  }

  // Update existing medication
  Future<int> updateMedication(Medication medication) async {
    final db = await instance.database;
    return await db.update('medication', medication.toMap(), where: 'id = ?', whereArgs: [medication.id]);
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
    return await db.insert('daily_log', log.toMap());
  }

  // Get all daily logs
  Future<List<DailyLog>> getAllDailyLogs() async {
    final db = await instance.database;
    final results = await db.query('daily_log');
    return results.map((row) => DailyLog.fromMap(row)).toList();
  }

  // Get a specific day's log by date string 
  Future<DailyLog?> getDailyLogByDate(String date) async {
    final db = await instance.database;
    final results = await db.query('daily_log', where: 'date = ?', whereArgs: [date]);
    if (results.isEmpty) {
      return null;
    }
    return DailyLog.fromMap(results.first);
  }

  // Update existing daily log
  Future<int> updateDailyLog(DailyLog log) async {
    final db = await instance.database;
    return await db.update('daily_log', log.toMap(), where: 'id = ?', whereArgs: [log.id]);
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
    return await db.insert('seizure_log', log.toMap());
  }

  // Get all seizure logs
  Future<List<SeizureLog>> getAllSeizureLogs() async {
    final db = await instance.database;
    final results = await db.query('seizure_log');
    return results.map((row) => SeizureLog.fromMap(row)).toList();
  }

  // Get all seizure logs for a specific date
  Future<List<SeizureLog>> getSeizureLogsByDate(String date) async {
    final db = await instance.database;
    final results = await db.query('seizure_log', where: 'date = ?', whereArgs: [date]);
    return results.map((row) => SeizureLog.fromMap(row)).toList();
  }

  // Update existing seizure log
  Future<int> updateSeizureLog(SeizureLog log) async {
    final db = await instance.database;
    return await db.update('seizure_log', log.toMap(), where: 'id = ?', whereArgs: [log.id]);
  }

  // Delete a seizure log
  Future<int> deleteSeizureLog(int id) async {
    final db = await instance.database;
    return await db.delete('seizure_log', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
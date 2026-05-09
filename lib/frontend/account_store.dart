import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/daily_log.dart';
import '../data/medication.dart';
import '../data/profile.dart';
import '../data/seizure_log.dart';
import '../database/database_helper.dart';

class FrontendAccount {
  final String username;
  final String passwordHash;
  final String createdAt;

  // Create a new account with the given username and password hash, and the current timestamp as the creation time
  const FrontendAccount({
    required this.username,
    required this.passwordHash,
    required this.createdAt,
  });

  // Get a FrontendAccount
  factory FrontendAccount.fromMap(Map<String, dynamic> map) {
    return FrontendAccount(
      username: (map['username'] ?? '') as String,
      passwordHash: (map['passwordHash'] ?? '') as String,
      createdAt: (map['createdAt'] ?? '') as String,
    );
  }

  // Convert the FrontendAccount to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'passwordHash': passwordHash,
      'createdAt': createdAt,
    };
  }
}

// Authorization attempt
class AccountAuthResult {
  final bool success;
  final String? message;

  const AccountAuthResult({required this.success, this.message});
}

// Account deletion attempt
class AccountDeletionResult {
  final bool success;
  final String? message;
  final bool deletedCurrentUser;

  const AccountDeletionResult({
    required this.success,
    this.message,
    this.deletedCurrentUser = false,
  });
}

// Manages user accounts, including sign up, sign in, sign out, and account deletion.
class FrontendAccountStore {
  FrontendAccountStore._();

  static final FrontendAccountStore instance = FrontendAccountStore._();

  static const String _accountsKey = 'frontend_accounts_v1';
  static const String _currentUserKey = 'frontend_current_user_v1';
  static const String _favoritePrefix = 'frontend_favorite_meds_';
  static const String _legacyMigratedPrefix = 'frontend_unknown_migrated_v1_';

  // Get all accounts stored on the device
  Future<List<FrontendAccount>> getAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getStringList(_accountsKey) ?? <String>[];

    final list = <FrontendAccount>[];
    for (final value in encoded) {
      final map = jsonDecode(value) as Map<String, dynamic>;
      list.add(FrontendAccount.fromMap(map));
    }

    return list;
  }

  // Get the currently signed in username, or null if no user is signed in
  Future<String?> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserKey);
  }

  // Sign up for a new account with the given username and password. Returns an AccountAuthResult indicating success or failure and an optional message.
  Future<AccountAuthResult> signUp({
    required String username,
    required String password,
  }) async {
    final normalized = username.trim().toLowerCase();
    if (normalized.isEmpty || password.isEmpty) {
      return const AccountAuthResult(
        success: false,
        message: 'Username and password are required.',
      );
    }

    final existing = await getAccounts();
    final alreadyExists = existing.any(
      (account) => account.username == normalized,
    );
    if (alreadyExists) {
      return const AccountAuthResult(
        success: false,
        message: 'That username already exists.',
      );
    }

    final account = FrontendAccount(
      username: normalized,
      passwordHash: _hashPassword(password),
      createdAt: DateTime.now().toIso8601String(),
    );

    final updated = [...existing, account];
    await _writeAccounts(updated);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, normalized);

    // Set current user in database
    await DatabaseHelper.setCurrentUser(normalized);
    await _migrateLegacyUnknownDataIfNeeded(normalized);

    return const AccountAuthResult(success: true);
  }

  // Sign in to an existing account with the given username and password. Returns an AccountAuthResult indicating success or failure and an optional message.
  Future<AccountAuthResult> signIn({
    required String username,
    required String password,
  }) async {
    final normalized = username.trim().toLowerCase();
    final list = await getAccounts();

    FrontendAccount? account;
    for (final item in list) {
      if (item.username == normalized) {
        account = item;
        break;
      }
    }

    // If no account was found with the given username, return an error
    if (account == null) {
      return const AccountAuthResult(
        success: false,
        message: 'Account not found.',
      );
    }

    // If the password hash of the found account does not match the hash of the provided password, return an error
    if (account.passwordHash != _hashPassword(password)) {
      return const AccountAuthResult(
        success: false,
        message: 'Incorrect password.',
      );
    }

    // If we reach this point, the username and password are correct. Set the current user in shared preferences and the database, and return success.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, normalized);

    // Set current user in database
    await DatabaseHelper.setCurrentUser(normalized);
    await _migrateLegacyUnknownDataIfNeeded(normalized);

    return const AccountAuthResult(success: true);
  }

  // Sign out the current user by removing the current user key from shared preferences and clearing the current user in the database
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);

    // Disconnect from database
    await DatabaseHelper.clearCurrentUser();
  }

  // Delete an existing account with the given username and password. Returns an AccountDeletionResult indicating success or failure, an optional message, and whether the deleted account was the currently signed in user.
  Future<AccountDeletionResult> deleteAccount({
    required String username,
    required String password,
  }) async {
    final normalized = username.trim().toLowerCase();
    if (normalized.isEmpty || password.isEmpty) {
      return const AccountDeletionResult(
        success: false,
        message: 'Username and password are required.',
      );
    }

    final existing = await getAccounts();
    FrontendAccount? account;
    for (final item in existing) {
      if (item.username == normalized) {
        account = item;
        break;
      }
    }

    // If no account was found with the given username, return an error
    if (account == null) {
      return const AccountDeletionResult(
        success: false,
        message: 'Account not found.',
      );
    }

    // If the password hash of the found account does not match the hash of the provided password, return an error
    if (account.passwordHash != _hashPassword(password)) {
      return const AccountDeletionResult(
        success: false,
        message: 'Incorrect password.',
      );
    }

    // If we reach this point, the username and password are correct. Remove the account from the list of accounts, delete all associated data from the database, and if this was the currently signed in user, also sign out.
    final prefs = await SharedPreferences.getInstance();
    await DatabaseHelper.instance.deleteUserData(normalized);

    // Remove the account from the list of accounts and save the updated list
    final updated = existing
        .where((item) => item.username != normalized)
        .toList();
    await _writeAccounts(updated);

    // Remove any favorite medications associated with this user
    await prefs.remove('$_favoritePrefix$normalized');

    // Remove any legacy migration flag for this user
    await prefs.remove('$_legacyMigratedPrefix$normalized');

    final currentUser = prefs.getString(_currentUserKey);
    final deletedCurrentUser = currentUser == normalized;
    if (deletedCurrentUser) {
      await prefs.remove(_currentUserKey);
      await DatabaseHelper.clearCurrentUser();
    }

    return AccountDeletionResult(
      success: true,
      deletedCurrentUser: deletedCurrentUser,
    );
  }

  // Set the current user to the given username. This is used when switching accounts without signing out, such as from a profile screen. It updates the current user in shared preferences and the database, and migrates any legacy "unknown" data if needed.
  Future<void> setCurrentUser(String username) async {
    final normalized = username.trim().toLowerCase();
    if (normalized.isEmpty) {
      return;
    }

    final existing = await getAccounts();
    final canSwitch = existing.any((account) => account.username == normalized);
    if (!canSwitch) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, normalized);

    // Update database for new user
    await DatabaseHelper.setCurrentUser(normalized);
    await _migrateLegacyUnknownDataIfNeeded(normalized);
  }

  // If the user is switching to a new account and there is legacy data under the "unknown" user, migrate that data to the new account. This only happens once per account, and only if the new account doesn't already have any data (to avoid overwriting any existing data).
  Future<void> _migrateLegacyUnknownDataIfNeeded(String username) async {
    if (username.isEmpty || username == 'unknown') {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final migrationKey = '$_legacyMigratedPrefix$username';
    if (prefs.getBool(migrationKey) == true) {
      return;
    }

    await DatabaseHelper.setCurrentUser(username);

    final existingProfile = await DatabaseHelper.instance.getProfile();
    final existingMeds = await DatabaseHelper.instance.getAllMedications();
    final existingDaily = await DatabaseHelper.instance.getAllDailyLogs();
    final existingSeizures = await DatabaseHelper.instance.getAllSeizureLogs();
    final alreadyHasData =
        existingProfile != null ||
        existingMeds.isNotEmpty ||
        existingDaily.isNotEmpty ||
        existingSeizures.isNotEmpty;

    if (alreadyHasData) {
      await prefs.setBool(migrationKey, true);
      return;
    }

    Profile? legacyProfile;
    List<Medication> legacyMeds = const [];
    List<DailyLog> legacyDaily = const [];
    List<SeizureLog> legacySeizures = const [];

    try {
      await DatabaseHelper.setCurrentUser('unknown');
      legacyProfile = await DatabaseHelper.instance.getProfile();
      legacyMeds = await DatabaseHelper.instance.getAllMedications();
      legacyDaily = await DatabaseHelper.instance.getAllDailyLogs();
      legacySeizures = await DatabaseHelper.instance.getAllSeizureLogs();
    } finally {
      await DatabaseHelper.setCurrentUser(username);
    }

    if (legacyProfile != null) {
      final migratedProfile = Profile(
        username: username,
        name: legacyProfile.name,
        dateOfBirth: legacyProfile.dateOfBirth,
        gender: legacyProfile.gender,
        diagnosisType: legacyProfile.diagnosisType,
        diagnosisDate: legacyProfile.diagnosisDate,
        doctorName: legacyProfile.doctorName,
        doctorPhone: legacyProfile.doctorPhone,
        hospitalPreference: legacyProfile.hospitalPreference,
        emergencyContactName: legacyProfile.emergencyContactName,
        emergencyContactPhone: legacyProfile.emergencyContactPhone,
        emergencyContactRelation: legacyProfile.emergencyContactRelation,
        dailyLogRemainderHour: legacyProfile.dailyLogRemainderHour,
        dailyLogRemainderMinute: legacyProfile.dailyLogRemainderMinute,
        seizureNotifications: legacyProfile.seizureNotifications,
        createdAt: legacyProfile.createdAt,
      );
      await DatabaseHelper.instance.insertProfile(migratedProfile);
    }

    for (final med in legacyMeds) {
      final migratedMed = Medication(
        username: username,
        name: med.name,
        dosage: med.dosage,
        frequencyCount: med.frequencyCount,
        frequencyUnit: med.frequencyUnit,
        timesList: med.timesList,
        startDate: med.startDate,
        endDate: med.endDate,
        notes: med.notes,
        createdAt: med.createdAt,
      );
      await DatabaseHelper.instance.insertMedication(migratedMed);
    }

    for (final log in legacyDaily) {
      final migratedLog = DailyLog(
        username: username,
        date: log.date,
        medicationAdherence: log.medicationAdherence,
        sleepHours: log.sleepHours,
        sleepQuality: log.sleepQuality,
        sleepInterruptions: log.sleepInterruptions,
        stressLevel: log.stressLevel,
        dietQuality: log.dietQuality,
        drugUse: log.drugUse,
        hormonalChanges: log.hormonalChanges,
        notes: log.notes,
        createdAt: log.createdAt,
        temperature: log.temperature,
        pressure: log.pressure,
        humidity: log.humidity,
      );
      await DatabaseHelper.instance.insertDailyLog(migratedLog);
    }

    for (final seizure in legacySeizures) {
      final migratedDaily = DailyLog(
        username: username,
        date: seizure.dailyLog.date,
        medicationAdherence: seizure.dailyLog.medicationAdherence,
        sleepHours: seizure.dailyLog.sleepHours,
        sleepQuality: seizure.dailyLog.sleepQuality,
        sleepInterruptions: seizure.dailyLog.sleepInterruptions,
        stressLevel: seizure.dailyLog.stressLevel,
        dietQuality: seizure.dailyLog.dietQuality,
        drugUse: seizure.dailyLog.drugUse,
        hormonalChanges: seizure.dailyLog.hormonalChanges,
        notes: seizure.dailyLog.notes,
        createdAt: seizure.dailyLog.createdAt,
        temperature: seizure.dailyLog.temperature,
        pressure: seizure.dailyLog.pressure,
        humidity: seizure.dailyLog.humidity,
      );

      final migratedSeizure = SeizureLog(
        username: username,
        date: seizure.date,
        timeOfDay: seizure.timeOfDay,
        durationSeconds: seizure.durationSeconds,
        seizureType: seizure.seizureType,
        symptoms: seizure.symptoms,
        mood: seizure.mood,
        notes: seizure.notes,
        createdAt: seizure.createdAt,
        dailyLog: migratedDaily,
      );
      await DatabaseHelper.instance.insertSeizureLog(migratedSeizure);
    }

    await prefs.setBool(migrationKey, true);
  }

  // Get the list of favorite medication names for the given username (or current user if username is null). This is stored in shared preferences under a key specific to the user.
  Future<List<String>> getFavoriteMedications({String? username}) async {
    final effectiveUser = username ?? await getCurrentUsername();
    if (effectiveUser == null || effectiveUser.isEmpty) {
      return <String>[];
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('$_favoritePrefix$effectiveUser') ?? <String>[];
  }

  // Toggle whether a given medication name is in the list of favorites for the given username
  Future<void> toggleFavoriteMedication(String medicationName) async {
    final currentUser = await getCurrentUsername();
    if (currentUser == null || currentUser.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final key = '$_favoritePrefix$currentUser';
    final favorites = prefs.getStringList(key) ?? <String>[];

    if (favorites.contains(medicationName)) {
      favorites.remove(medicationName);
    } else {
      favorites.add(medicationName);
    }

    await prefs.setStringList(key, favorites);
  }

  // Write the given list of accounts to shared preferences by encoding each account as a JSON string and saving the list of strings under the accounts key.
  Future<void> _writeAccounts(List<FrontendAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = <String>[];
    for (final account in accounts) {
      encoded.add(jsonEncode(account.toMap()));
    }

    await prefs.setStringList(_accountsKey, encoded);
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }
}

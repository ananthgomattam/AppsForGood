import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';

class FrontendAccount {
  final String username;
  final String passwordHash;
  final String createdAt;

  const FrontendAccount({
    required this.username,
    required this.passwordHash,
    required this.createdAt,
  });

  factory FrontendAccount.fromMap(Map<String, dynamic> map) {
    return FrontendAccount(
      username: (map['username'] ?? '') as String,
      passwordHash: (map['passwordHash'] ?? '') as String,
      createdAt: (map['createdAt'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'passwordHash': passwordHash,
      'createdAt': createdAt,
    };
  }
}

class AccountAuthResult {
  final bool success;
  final String? message;

  const AccountAuthResult({required this.success, this.message});
}

class FrontendAccountStore {
  FrontendAccountStore._();

  static final FrontendAccountStore instance = FrontendAccountStore._();

  static const String _accountsKey = 'frontend_accounts_v1';
  static const String _currentUserKey = 'frontend_current_user_v1';
  static const String _favoritePrefix = 'frontend_favorite_meds_';

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

  Future<String?> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserKey);
  }

  Future<AccountAuthResult> signUp({
    required String username,
    required String password,
  }) async {
    final normalized = username.trim().toLowerCase();
    if (normalized.isEmpty || password.isEmpty) {
      return const AccountAuthResult(success: false, message: 'Username and password are required.');
    }

    final existing = await getAccounts();
    final alreadyExists = existing.any((account) => account.username == normalized);
    if (alreadyExists) {
      return const AccountAuthResult(success: false, message: 'That username already exists.');
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

    return const AccountAuthResult(success: true);
  }

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

    if (account == null) {
      return const AccountAuthResult(success: false, message: 'Account not found.');
    }

    if (account.passwordHash != _hashPassword(password)) {
      return const AccountAuthResult(success: false, message: 'Incorrect password.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, normalized);

    // Set current user in database
    await DatabaseHelper.setCurrentUser(normalized);

    return const AccountAuthResult(success: true);
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);

    // Disconnect from database
    await DatabaseHelper.clearCurrentUser();
  }

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
  }

  Future<List<String>> getFavoriteMedications({String? username}) async {
    final effectiveUser = username ?? await getCurrentUsername();
    if (effectiveUser == null || effectiveUser.isEmpty) {
      return <String>[];
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('$_favoritePrefix$effectiveUser') ?? <String>[];
  }

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

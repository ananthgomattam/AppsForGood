import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:forseizure/database/database_helper.dart';
import 'package:forseizure/services/trigger_service.dart';

Future<void> main() async {
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  try {
    await DatabaseHelper.instance.loadFixedTestData();
    final daily = await DatabaseHelper.instance.getAllDailyLogs();
    final seizure = await DatabaseHelper.instance.getAllSeizureLogs();
    print('daily=${daily.length} seizure=${seizure.length}');

    final results = await TriggerService().analyzeTriggers();
    print('triggerResults=${results.length}');
    for (final r in results) {
      print('${r.factorName}: trigger=${r.isTrigger} weight=${r.weight}');
    }
  } catch (e, st) {
    print('ERROR: $e');
    print(st);
  }
}

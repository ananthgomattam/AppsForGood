import 'package:flutter/material.dart';

import '../data/daily_log.dart';
import '../data/seizure_log.dart';
import '../database/database_helper.dart';
// Screen to view, edit, and delete daily and seizure entries. Provides a tabbed interface to switch between daily logs and seizure logs, with options to refresh data and manage individual entries.
class EntriesScreen extends StatefulWidget {
  const EntriesScreen({super.key});

  @override
  State<EntriesScreen> createState() => _EntriesScreenState();
}
// State class for the EntriesScreen, responsible for loading data from the database, handling user interactions for editing and deleting entries, and building the UI to display the lists of daily and seizure logs.
class _EntriesScreenState extends State<EntriesScreen> {
  bool _loading = true;
  List<DailyLog> _dailyLogs = const [];
  List<SeizureLog> _seizureLogs = const [];
// Helper method to create a summary string of weather conditions based on available temperature, pressure, and humidity data from the daily log. This is used in the list item subtitles to provide quick weather context for each entry.
  String _weatherSummary({
    required double? temperature,
    required double? pressure,
    required double? humidity,
  }) {
    final parts = <String>[];
    if (temperature != null) {
      parts.add('${temperature.toStringAsFixed(1)} C');
    }
    if (pressure != null) {
      parts.add('${pressure.toStringAsFixed(0)} hPa');
    }
    if (humidity != null) {
      parts.add('${humidity.toStringAsFixed(0)}% RH');
    }

    if (parts.isEmpty) {
      return 'Weather unavailable';
    }
    return 'Weather ${parts.join(' | ')}';
  }
// When the screen initializes, it calls the _reload method to load the daily and seizure logs from the database. The _reload method sets the loading state, fetches the data, sorts it appropriately, and then updates the state to display the loaded entries.
  @override
  void initState() {
    super.initState();
    _reload();
  }
// Method to load daily and seizure logs from the database, sort them, and update the state. This is called on initialization and can be triggered by the user via a refresh button in the app bar.
  Future<void> _reload() async {
    setState(() => _loading = true);
    final daily = await DatabaseHelper.instance.getAllDailyLogs();
    final seizure = await DatabaseHelper.instance.getAllSeizureLogs();

    // Sort seizure logs by date then time
    seizure.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      if (byDate != 0) return byDate;
      return b.timeOfDay.compareTo(a.timeOfDay);
    });

    daily.sort((a, b) => b.date.compareTo(a.date));

    if (!mounted) return;
    setState(() {
      _dailyLogs = daily;
      _seizureLogs = seizure;
      _loading = false;
    });
  }
// Method to confirm deletion of a daily log entry. If the entry is associated with a seizure, it also deletes the related seizure log(s). It shows a confirmation dialog to the user before performing the deletion and provides feedback via a SnackBar after deletion.
  Future<void> _confirmDeleteDaily(DailyLog log) async {
    if (log.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete daily entry?'),
          content: Text('This will remove the daily entry for ${log.date}.${log.isSeizure ? " (This will also remove the associated seizure log)" : ""}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
          ],
        );
      },
    );

    if (confirm != true) return;
    
    // If this was a seizure day, also delete the associated seizure log(s)
    if (log.isSeizure) {
      final seizures = await DatabaseHelper.instance.getSeizureLogsByDate(log.date);
      for (final seizure in seizures) {
        if (seizure.id != null) {
          await DatabaseHelper.instance.deleteSeizureLog(seizure.id!);
        }
      }
    }
    
    await DatabaseHelper.instance.deleteDailyLog(log.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted daily entry for ${log.date}.')),
    );
    await _reload();
  }

  Future<void> _confirmDeleteSeizure(SeizureLog log) async {
    if (log.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete seizure entry?'),
          content: Text('This will remove the seizure entry on ${log.date} at ${log.timeOfDay}. (This will also remove the associated daily log)'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
          ],
        );
      },
    );

    if (confirm != true) return;
    
    // Delete the seizure log first
    await DatabaseHelper.instance.deleteSeizureLog(log.id!);
    
    // Also delete the associated daily log for that date
    await DatabaseHelper.instance.deleteDailyLogByDate(log.date);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted seizure entry on ${log.date}.')),
    );
    await _reload();
  }

  Future<void> _editDaily(DailyLog log) async {
    final dateCtrl = TextEditingController(text: log.date);
    final sleepHoursCtrl = TextEditingController(text: log.sleepHours.toString());
    final interruptionsCtrl = TextEditingController(text: log.sleepInterruptions.toString());
    final notesCtrl = TextEditingController(text: log.notes ?? '');

    bool medicationAdherence = log.medicationAdherence;
    bool drugUse = log.drugUse;
    int sleepQuality = log.sleepQuality;
    int stressLevel = log.stressLevel;
    int dietQuality = log.dietQuality;
    bool? hormonalChanges = log.hormonalChanges;

    final didSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Edit Daily Entry'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: dateCtrl,
                        decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: sleepHoursCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Sleep Hours'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: interruptionsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Sleep Interruptions'),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        initialValue: sleepQuality,
                        decoration: const InputDecoration(labelText: 'Sleep Quality'),
                        items: const [1, 2, 3, 4, 5]
                            .map((value) => DropdownMenuItem(value: value, child: Text('$value')))
                            .toList(),
                        onChanged: (value) => setModalState(() => sleepQuality = value ?? sleepQuality),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        initialValue: stressLevel,
                        decoration: const InputDecoration(labelText: 'Stress Level'),
                        items: List.generate(10, (i) => i + 1)
                            .map((value) => DropdownMenuItem(value: value, child: Text('$value')))
                            .toList(),
                        onChanged: (value) => setModalState(() => stressLevel = value ?? stressLevel),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        initialValue: dietQuality,
                        decoration: const InputDecoration(labelText: 'Diet Quality'),
                        items: const [1, 2, 3, 4, 5]
                            .map((value) => DropdownMenuItem(value: value, child: Text('$value')))
                            .toList(),
                        onChanged: (value) => setModalState(() => dietQuality = value ?? dietQuality),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<bool?>(
                        initialValue: hormonalChanges,
                        decoration: const InputDecoration(labelText: 'Hormonal Changes'),
                        items: const [
                          DropdownMenuItem<bool?>(value: null, child: Text('Unknown')),
                          DropdownMenuItem<bool?>(value: true, child: Text('Yes')),
                          DropdownMenuItem<bool?>(value: false, child: Text('No')),
                        ],
                        onChanged: (value) => setModalState(() => hormonalChanges = value),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Medication Adherence'),
                        value: medicationAdherence,
                        onChanged: (value) => setModalState(() => medicationAdherence = value),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Drug Use'),
                        value: drugUse,
                        onChanged: (value) => setModalState(() => drugUse = value),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: notesCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Notes'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
              ],
            );
          },
        );
      },
    );

    if (didSave != true) {
      dateCtrl.dispose();
      sleepHoursCtrl.dispose();
      interruptionsCtrl.dispose();
      notesCtrl.dispose();
      return;
    }

    final parsedSleep = double.tryParse(sleepHoursCtrl.text.trim());
    final parsedInterruptions = int.tryParse(interruptionsCtrl.text.trim());

    if (parsedSleep == null || parsedInterruptions == null || dateCtrl.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid values before saving.')),
      );
      dateCtrl.dispose();
      sleepHoursCtrl.dispose();
      interruptionsCtrl.dispose();
      notesCtrl.dispose();
      return;
    }

    final updated = log.copyWith(
      date: dateCtrl.text.trim(),
      sleepHours: parsedSleep,
      sleepInterruptions: parsedInterruptions,
      sleepQuality: sleepQuality,
      stressLevel: stressLevel,
      dietQuality: dietQuality,
      medicationAdherence: medicationAdherence,
      drugUse: drugUse,
      hormonalChanges: hormonalChanges,
      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
    );

    await DatabaseHelper.instance.updateDailyLog(updated);
    
    // If this was a seizure day, also update the associated seizure log(s) with the new daily factors
    if (updated.isSeizure) {
      final seizures = await DatabaseHelper.instance.getSeizureLogsByDate(updated.date);
      for (final seizure in seizures) {
        final updatedSeizure = seizure.copyWith(
          dailyLog: updated,
        );
        await DatabaseHelper.instance.updateSeizureLog(updatedSeizure);
      }
    }
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Updated daily entry for ${updated.date}.')),
    );
    await _reload();

    dateCtrl.dispose();
    sleepHoursCtrl.dispose();
    interruptionsCtrl.dispose();
    notesCtrl.dispose();
  }
// Similar to _editDaily but for seizure logs. Allows editing of seizure-specific fields like time, duration, type, mood, symptoms, and notes. Also ensures that if the date is changed, the associated daily log is updated accordingly.
  Future<void> _editSeizure(SeizureLog log) async {
    final dateCtrl = TextEditingController(text: log.date);
    final timeCtrl = TextEditingController(text: log.timeOfDay);
    final durationCtrl = TextEditingController(text: log.durationSeconds.toString());
    final typeCtrl = TextEditingController(text: log.seizureType);
    final symptomsCtrl = TextEditingController(text: log.symptoms ?? '');
    final notesCtrl = TextEditingController(text: log.notes ?? '');

    int mood = log.mood;

    final didSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Edit Seizure Entry'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: dateCtrl,
                        decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: timeCtrl,
                        decoration: const InputDecoration(labelText: 'Time (HH:MM)'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: durationCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Duration (seconds)'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: typeCtrl,
                        decoration: const InputDecoration(labelText: 'Seizure Type'),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        initialValue: mood,
                        decoration: const InputDecoration(labelText: 'Mood (1-5)'),
                        items: const [1, 2, 3, 4, 5]
                            .map((value) => DropdownMenuItem(value: value, child: Text('$value')))
                            .toList(),
                        onChanged: (value) => setModalState(() => mood = value ?? mood),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: symptomsCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Symptoms'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: notesCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Notes'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
              ],
            );
          },
        );
      },
    );

    if (didSave != true) {
      dateCtrl.dispose();
      timeCtrl.dispose();
      durationCtrl.dispose();
      typeCtrl.dispose();
      symptomsCtrl.dispose();
      notesCtrl.dispose();
      return;
    }

    final parsedDuration = int.tryParse(durationCtrl.text.trim());
    if (parsedDuration == null ||
        dateCtrl.text.trim().isEmpty ||
        timeCtrl.text.trim().isEmpty ||
        typeCtrl.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid values before saving.')),
      );
      dateCtrl.dispose();
      timeCtrl.dispose();
      durationCtrl.dispose();
      typeCtrl.dispose();
      symptomsCtrl.dispose();
      notesCtrl.dispose();
      return;
    }

    final updated = log.copyWith(
      date: dateCtrl.text.trim(),
      timeOfDay: timeCtrl.text.trim(),
      durationSeconds: parsedDuration,
      seizureType: typeCtrl.text.trim(),
      symptoms: symptomsCtrl.text.trim().isEmpty ? null : symptomsCtrl.text.trim(),
      mood: mood,
      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      dailyLog: log.dailyLog.copyWith(date: dateCtrl.text.trim()),
    );

    await DatabaseHelper.instance.updateSeizureLog(updated);
    
    // Also update the associated daily log if date changed
    final updatedDaily = updated.dailyLog.copyWith(date: updated.date);
    await DatabaseHelper.instance.updateDailyLog(updatedDaily);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Updated seizure entry on ${updated.date}.')),
    );
    await _reload();

    dateCtrl.dispose();
    timeCtrl.dispose();
    durationCtrl.dispose();
    typeCtrl.dispose();
    symptomsCtrl.dispose();
    notesCtrl.dispose();
  }
// The build method constructs the UI for the EntriesScreen. It uses a DefaultTabController to create a tabbed interface with two tabs: one for daily logs and one for seizure logs. The app bar includes a refresh button to reload data from the database. Depending on the loading state, it either shows a progress indicator or the tab views with lists of entries.
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Entries'),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: 'Daily Logs (${_dailyLogs.length})'),
              Tab(text: 'Seizure Logs (${_seizureLogs.length})'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildDailyTab(),
                  _buildSeizureTab(),
                ],
              ),
      ),
    );
  }
// Builds the UI for the Daily Logs tab. If there are no daily logs, it shows a message indicating that. Otherwise, it displays a list of daily log entries in cards, showing key information such as date, sleep hours, stress level, medication adherence, and weather summary. Each entry has a popup menu for editing or deleting the entry.
  Widget _buildDailyTab() {
    if (_dailyLogs.isEmpty) {
      return const Center(child: Text('No daily entries yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _dailyLogs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final log = _dailyLogs[index];
        return Card(
          child: ListTile(
            isThreeLine: true,
            leading: Icon(log.isSeizure ? Icons.bolt_rounded : Icons.calendar_today_outlined, color: log.isSeizure ? Colors.red : null),
            title: Text(log.date),
            subtitle: Text(
              '${log.isSeizure ? "Seizure day | " : ""}Sleep ${log.sleepHours.toStringAsFixed(1)}h | Stress ${log.stressLevel}/10 | Meds ${log.medicationAdherence ? "Yes" : "No"}\n${_weatherSummary(temperature: log.temperature, pressure: log.pressure, humidity: log.humidity)}',
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  await _editDaily(log);
                } else if (value == 'delete') {
                  await _confirmDeleteDaily(log);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
        );
      },
    );
  }
// Builds the UI for the Seizure Logs tab. If there are no seizure logs, it shows a message indicating that. Otherwise, it displays a list of seizure log entries in cards, showing key information such as date, time, seizure type, duration, mood, symptoms, and weather summary. Each entry has a popup menu for editing or deleting the entry.
  Widget _buildSeizureTab() {
    if (_seizureLogs.isEmpty) {
      return const Center(child: Text('No seizure entries yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _seizureLogs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final log = _seizureLogs[index];
        return Card(
          child: ListTile(
            isThreeLine: true,
            leading: const Icon(Icons.bolt_rounded),
            title: Text('${log.date} at ${log.timeOfDay}'),
            subtitle: Text(
              '${log.seizureType} | ${log.durationSeconds}s | Mood ${log.mood}/5\n${_weatherSummary(temperature: log.dailyLog.temperature, pressure: log.dailyLog.pressure, humidity: log.dailyLog.humidity)}',
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  await _editSeizure(log);
                } else if (value == 'delete') {
                  await _confirmDeleteSeizure(log);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
        );
      },
    );
  }
}

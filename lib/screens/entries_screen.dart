import 'package:flutter/material.dart';

import '../data/daily_log.dart';
import '../data/seizure_log.dart';
import '../database/database_helper.dart';

class EntriesScreen extends StatefulWidget {
  const EntriesScreen({super.key});

  @override
  State<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends State<EntriesScreen> {
  bool _loading = true;
  List<DailyLog> _dailyLogs = const [];
  List<SeizureLog> _seizureLogs = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final daily = await DatabaseHelper.instance.getAllDailyLogs();
    final seizure = await DatabaseHelper.instance.getAllSeizureLogs();

    daily.sort((a, b) => b.date.compareTo(a.date));
    seizure.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      if (byDate != 0) return byDate;
      return b.timeOfDay.compareTo(a.timeOfDay);
    });

    if (!mounted) return;
    setState(() {
      _dailyLogs = daily;
      _seizureLogs = seizure;
      _loading = false;
    });
  }

  Future<void> _confirmDeleteDaily(DailyLog log) async {
    if (log.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete daily entry?'),
          content: Text('This will remove the daily entry for ${log.date}.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
          ],
        );
      },
    );

    if (confirm != true) return;
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
          content: Text('This will remove the seizure entry on ${log.date} at ${log.timeOfDay}.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
          ],
        );
      },
    );

    if (confirm != true) return;
    await DatabaseHelper.instance.deleteSeizureLog(log.id!);
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Entries'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Daily Logs'),
              Tab(text: 'Seizure Logs'),
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
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(log.date),
            subtitle: Text(
              'Sleep ${log.sleepHours.toStringAsFixed(1)}h | Stress ${log.stressLevel}/10 | Meds ${log.medicationAdherence ? "Yes" : "No"}',
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
            leading: const Icon(Icons.bolt_rounded),
            title: Text('${log.date} at ${log.timeOfDay}'),
            subtitle: Text(
              '${log.seizureType} | ${log.durationSeconds}s | Mood ${log.mood}/5',
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

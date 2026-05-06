import 'package:flutter/material.dart';

import '../data/daily_log.dart';
import '../data/seizure_log.dart';
import '../database/database_helper.dart';
import '../frontend/account_store.dart';
import '../services/weather_service.dart';

class LogSeizureScreen extends StatefulWidget {
  const LogSeizureScreen({super.key});

  @override
  State<LogSeizureScreen> createState() => _LogSeizureScreenState();
}

class _LogSeizureScreenState extends State<LogSeizureScreen> {
  final _formKey = GlobalKey<FormState>();

  final _dateCtrl = TextEditingController();

  final _sleepHoursCtrl = TextEditingController();
  final _sleepBreaksCtrl = TextEditingController();
  final _dayNotesCtrl = TextEditingController();

  final _timeCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _symptomsCtrl = TextEditingController();
  final _seizureNotesCtrl = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isSeizureDay = false;
  bool _medicationAdherence = true;
  bool _drugUse = false;
  bool? _hormonalChanges;
  int _sleepQuality = 3;
  int _stressLevel = 5;
  int _dietQuality = 3;

  String _seizureType = 'Tonic-clonic';
  int _mood = 3;
  bool _saving = false;

  @override
  void dispose() {
    _dateCtrl.dispose();
    _sleepHoursCtrl.dispose();
    _sleepBreaksCtrl.dispose();
    _dayNotesCtrl.dispose();
    _timeCtrl.dispose();
    _durationCtrl.dispose();
    _symptomsCtrl.dispose();
    _seizureNotesCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  String _formatTime(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  DateTime _resolveWeatherDateTime() {
    final parsedDate = DateTime.tryParse(_dateCtrl.text.trim());
    final baseDate = parsedDate ?? _selectedDate ?? DateTime.now();

    // If no seizure-time exists, sample midday for daily snapshots.
    if (!_isSeizureDay || _timeCtrl.text.trim().isEmpty) {
      return DateTime(baseDate.year, baseDate.month, baseDate.day, 12);
    }

    final parts = _timeCtrl.text.trim().split(':');
    if (parts.length != 2) {
      return DateTime(baseDate.year, baseDate.month, baseDate.day, 12);
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return DateTime(baseDate.year, baseDate.month, baseDate.day, 12);
    }

    return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
      _dateCtrl.text = _formatDate(picked);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked == null) return;
    setState(() {
      _selectedTime = picked;
      _timeCtrl.text = _formatTime(picked);
    });
  }

  Future<void> _saveLog() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final weatherDateTime = _resolveWeatherDateTime();
      final weather = await WeatherService().getWeatherAt(weatherDateTime);
      final username = await FrontendAccountStore.instance.getCurrentUsername() ?? 'unknown';
      // Defensive parsing for numeric fields to avoid runtime exceptions
      final sleepHours = double.tryParse(_sleepHoursCtrl.text.trim());
      final sleepInterruptions = int.tryParse(_sleepBreaksCtrl.text.trim());
      final duration = _isSeizureDay ? int.tryParse(_durationCtrl.text.trim()) : null;
      if (sleepHours == null || sleepHours < 0 || sleepHours > 24) {
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid sleep hours (0-24).')));
        return;
      }
      if (sleepInterruptions == null || sleepInterruptions < 0) {
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid sleep interruptions (0+).')));
        return;
      }
      if (_isSeizureDay && (duration == null || duration <= 0)) {
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid seizure duration in seconds.')),
        );
        return;
      }

      final dailyLog = DailyLog(
        username: username,
        date: _dateCtrl.text,
        medicationAdherence: _medicationAdherence,
        sleepHours: sleepHours,
        sleepQuality: _sleepQuality,
        sleepInterruptions: sleepInterruptions,
        stressLevel: _stressLevel,
        dietQuality: _dietQuality,
        drugUse: _drugUse,
        hormonalChanges: _hormonalChanges,
        notes: _dayNotesCtrl.text.trim().isEmpty ? null : _dayNotesCtrl.text.trim(),
        temperature: weather.temperature,
        pressure: weather.pressure,
        humidity: weather.humidity,
        isSeizure: _isSeizureDay,
        createdAt: DateTime.now().toIso8601String(),
      );

      await DatabaseHelper.instance.insertDailyLog(dailyLog);

      if (_isSeizureDay) {
        final seizureLog = SeizureLog(
          username: username,
          date: _dateCtrl.text,
          timeOfDay: _timeCtrl.text,
          durationSeconds: duration!,
          seizureType: _seizureType,
          symptoms: _symptomsCtrl.text.trim().isEmpty ? null : _symptomsCtrl.text.trim(),
          mood: _mood,
          notes: _seizureNotesCtrl.text.trim().isEmpty ? null : _seizureNotesCtrl.text.trim(),
          createdAt: DateTime.now().toIso8601String(),
          dailyLog: dailyLog,
        );

        await DatabaseHelper.instance.insertSeizureLog(seizureLog);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final err = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save this entry. ${err.length > 200 ? err.substring(0, 200) + "..." : err}')),
      );
      return;
    }

    if (!mounted) return;

    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isSeizureDay
              ? 'Seizure day entry saved and synced.'
              : 'Non-seizure day entry saved and synced.',
        ),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Entry')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4B2377), Color(0xFF7E2BC7)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'One Daily Entry',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Track both normal and seizure days to detect patterns and deviations over time.',
                      style: TextStyle(color: Colors.white, height: 1.35),
                    ),
                    const SizedBox(height: 14),
                    SegmentedButton<bool>(
                      showSelectedIcon: false,
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.white;
                          }
                          return Colors.white.withValues(alpha: 0.12);
                        }),
                        foregroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return const Color(0xFF4B2377);
                          }
                          return Colors.white;
                        }),
                      ),
                      segments: const [
                        ButtonSegment<bool>(
                          value: false,
                          icon: Icon(Icons.sunny),
                          label: Text('Non-seizure day'),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          icon: Icon(Icons.bolt_rounded),
                          label: Text('Seizure day'),
                        ),
                      ],
                      selected: {_isSeizureDay},
                      onSelectionChanged: (selected) {
                        setState(() {
                          _isSeizureDay = selected.first;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daily Factors', style: titleStyle),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _dateCtrl,
                        readOnly: true,
                        onTap: _pickDate,
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          suffixIcon: Icon(Icons.calendar_month_outlined),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Date is required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _sleepHoursCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Sleep Hours'),
                              validator: (v) {
                                final parsed = double.tryParse(v ?? '');
                                if (parsed == null || parsed < 0 || parsed > 24) {
                                  return 'Use 0 to 24';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _sleepBreaksCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Sleep Interruptions'),
                              validator: (v) {
                                final parsed = int.tryParse(v ?? '');
                                if (parsed == null || parsed < 0) {
                                  return 'Use 0+';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: _sleepQuality,
                        decoration: const InputDecoration(labelText: 'Sleep Quality (1-5)'),
                        items: const [1, 2, 3, 4, 5]
                            .map((value) => DropdownMenuItem(value: value, child: Text('$value')))
                            .toList(),
                        onChanged: (value) => setState(() => _sleepQuality = value ?? 3),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: _stressLevel,
                        decoration: const InputDecoration(labelText: 'Stress Level (1-10)'),
                        items: const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
                            .map((value) => DropdownMenuItem(value: value, child: Text('$value')))
                            .toList(),
                        onChanged: (value) => setState(() => _stressLevel = value ?? 5),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: _dietQuality,
                        decoration: const InputDecoration(labelText: 'Diet Quality (1-5)'),
                        items: const [1, 2, 3, 4, 5]
                            .map((value) => DropdownMenuItem(value: value, child: Text('$value')))
                            .toList(),
                        onChanged: (value) => setState(() => _dietQuality = value ?? 3),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Medication Adherence'),
                        subtitle: Text(_medicationAdherence ? 'Taken as planned' : 'Missed or delayed'),
                        value: _medicationAdherence,
                        onChanged: (value) => setState(() => _medicationAdherence = value),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Drug / Alcohol Use'),
                        subtitle: Text(_drugUse ? 'Reported today' : 'None reported'),
                        value: _drugUse,
                        onChanged: (value) => setState(() => _drugUse = value),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<bool?>(
                        initialValue: _hormonalChanges,
                        decoration: const InputDecoration(labelText: 'Hormonal Changes'),
                        items: const [
                          DropdownMenuItem<bool?>(value: null, child: Text('Not applicable / prefer not to say')),
                          DropdownMenuItem<bool?>(value: true, child: Text('Yes')),
                          DropdownMenuItem<bool?>(value: false, child: Text('No')),
                        ],
                        onChanged: (value) => setState(() => _hormonalChanges = value),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _dayNotesCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Daily Notes',
                          hintText: 'Routine, meals, stressors, or any deviation from normal habits',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isSeizureDay) const SizedBox(height: 16),
              if (_isSeizureDay)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Seizure Details', style: titleStyle),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _timeCtrl,
                          readOnly: true,
                          onTap: _pickTime,
                          decoration: const InputDecoration(
                            labelText: 'Time',
                            suffixIcon: Icon(Icons.access_time_outlined),
                          ),
                          validator: (v) {
                            if (!_isSeizureDay) return null;
                            return (v == null || v.isEmpty) ? 'Time is required for seizure days' : null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _durationCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Duration (seconds)'),
                          validator: (v) {
                            if (!_isSeizureDay) return null;
                            final parsed = int.tryParse(v ?? '');
                            if (parsed == null || parsed <= 0) {
                              return 'Enter a positive number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _seizureType,
                          decoration: const InputDecoration(labelText: 'Seizure Type'),
                          items: const [
                            DropdownMenuItem(value: 'Tonic-clonic', child: Text('Tonic-clonic')),
                            DropdownMenuItem(value: 'Absence', child: Text('Absence')),
                            DropdownMenuItem(value: 'Focal', child: Text('Focal')),
                          ],
                          onChanged: (value) => setState(() => _seizureType = value ?? 'Tonic-clonic'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: _mood,
                          decoration: const InputDecoration(labelText: 'Mood During / After (1-5)'),
                          items: const [1, 2, 3, 4, 5]
                              .map((value) => DropdownMenuItem(value: value, child: Text('$value')))
                              .toList(),
                          onChanged: (value) => setState(() => _mood = value ?? 3),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _symptomsCtrl,
                          decoration: const InputDecoration(labelText: 'Symptoms / Aura'),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _seizureNotesCtrl,
                          decoration: const InputDecoration(labelText: 'Seizure Notes'),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.cloud_sync_outlined, color: Color(0xFF5A2B8A)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Weather is fetched automatically when you save to help correlate climate conditions with outcomes.',
                        style: TextStyle(height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveLog,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isSeizureDay ? 'Save Seizure Day Entry' : 'Save Non-Seizure Day Entry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

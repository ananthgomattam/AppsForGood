import 'package:flutter/material.dart';

import '../data/daily_log.dart';
import '../data/seizure_log.dart';
import '../database/database_helper.dart';
import '../frontend/account_store.dart';
import '../services/weather_service.dart';
//Claude: "Teach me the Flutter concepts required to implement a stateful form screen with text fields, dropdowns, switches, date/time pickers, validation, and database save logic for logging daily seizure data."
// The LogSeizureScreen is a stateful widget that provides a form for users to log daily entries, including both seizure and non-seizure days. It captures various factors such as sleep, stress, medication adherence, and weather conditions to help users identify patterns and correlations over time. The screen includes validation for input fields and saves the data to a local database, while also fetching weather data based on the date and time of the entry.
class LogSeizureScreen extends StatefulWidget {
  const LogSeizureScreen({super.key});
// The createState method creates an instance of the _LogSeizureScreenState class, which manages the state and behavior of the LogSeizureScreen. This includes handling user input, form validation, data saving, and UI updates based on the user's interactions with the form.
  @override
  State<LogSeizureScreen> createState() => _LogSeizureScreenState();
}
// The state class for LogSeizureScreen manages the form state, input controllers, and the logic for saving the log entry. It includes methods for picking dates and times, validating input, and saving the data to the database while also fetching weather information. The build method constructs the UI for the form, allowing users to input various details about their day and seizure events.
class _LogSeizureScreenState extends State<LogSeizureScreen> {
  final _formKey = GlobalKey<FormState>();
// TextEditingController instances for managing the state of text input fields in the form. Each controller corresponds to a specific input field, allowing the app to read and manipulate the text input by the user.
  final _dateCtrl = TextEditingController();
// These TextEditingController instances are used to manage the state of the text input fields in the form. They allow the app to read the current value of the input fields, update them programmatically (such as when a date or time is picked), and clear them when needed. Each controller corresponds to a specific input field in the form, such as date, sleep hours, sleep interruptions, daily notes, seizure time, seizure duration, symptoms, and seizure notes.
  final _sleepHoursCtrl = TextEditingController();
  final _sleepBreaksCtrl = TextEditingController();
  final _dayNotesCtrl = TextEditingController();
// These controllers are used to manage the input fields for the date, sleep hours, sleep interruptions, daily notes, seizure time, seizure duration, symptoms, and seizure notes. They allow the app to read and manipulate the text input by the user, as well as to clear or set default values when needed.
  final _timeCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _symptomsCtrl = TextEditingController();
  final _seizureNotesCtrl = TextEditingController();
// The _selectedDate and _selectedTime variables are used to store the user's selected date and time for the log entry. These are updated when the user picks a date or time using the respective picker dialogs. They are also used to populate the text controllers with formatted date and time strings for display in the form fields.
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
// The _isSeizureDay boolean tracks whether the current entry being logged is a seizure day or not. This variable is used to conditionally show or hide seizure-specific input fields in the form and to determine how the data should be saved to the database. By default, it is set to false, indicating a non-seizure day, but users can toggle it to true if they are logging a seizure event.
  bool _isSeizureDay = false;
  bool _medicationAdherence = true;
  bool _drugUse = false;
  bool? _hormonalChanges;
  int _sleepQuality = 3;
  int _stressLevel = 5;
  int _dietQuality = 3;
// Default seizure type is set to 'Tonic-clonic', but users can select from other types as well. This field is only relevant if the entry is marked as a seizure day.
  String _seizureType = 'Tonic-clonic';
  int _mood = 3;
  bool _saving = false;
// The dispose method is overridden to clean up the text controllers when the widget is removed from the widget tree. This is important to prevent memory leaks and ensure that resources are properly released.
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
// The _formatDate method takes a DateTime object and formats it into a string in the format "yyyy-MM-dd". It ensures that the year is four digits, and the month and day are two digits, padding with zeros if necessary.
  String _formatDate(DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }
// The _formatTime method takes a TimeOfDay object and formats it into a string in the format "HH:mm". It ensures that hours and minutes are always two digits by padding with zeros if necessary.
  String _formatTime(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
// The _resolveWeatherDateTime method determines the appropriate DateTime to use when fetching weather data. It prioritizes the explicitly entered date and time for seizure events, but falls back to the selected date or current date if not provided. For non-seizure days or if time is not specified, it defaults to sampling weather data at midday to provide a consistent reference point for daily conditions.
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
// Method to pick a date using a date picker dialog. It updates the _selectedDate variable and the corresponding text controller with the formatted date string when a date is selected.
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
// Method to pick time using a time picker dialog. It updates the _selectedTime variable and the corresponding text controller with the formatted time string when a time is selected.
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
// The _saveLog method is responsible for validating the form input, fetching weather data based on the date and time of the entry, and saving the daily log and seizure log (if applicable) to the local database. It includes error handling to provide feedback to the user if something goes wrong during the save process.
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
// The build method constructs the UI for the LogSeizureScreen. It includes a form with various input fields for daily factors and seizure details, organized into cards for better visual separation. The form uses validation to ensure required fields are filled out correctly. A save button at the bottom triggers the _saveLog method, which handles data validation, saving to the database, and fetching weather information.
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

import 'package:flutter/material.dart';

import '../data/seizure_log.dart';
import '../database/database_helper.dart';

class LogSeizureScreen extends StatefulWidget {
  const LogSeizureScreen({super.key});

  @override
  State<LogSeizureScreen> createState() => _LogSeizureScreenState();
}

class _LogSeizureScreenState extends State<LogSeizureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _durationController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _seizureType = 'Tonic-clonic';
  int _mood = 3;
  bool _saving = false;

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _durationController.dispose();
    _symptomsController.dispose();
    _notesController.dispose();
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
      _dateController.text = _formatDate(picked);
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
      _timeController.text = _formatTime(picked);
    });
  }

  Future<void> _saveLog() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final dailyLog = await DatabaseHelper.instance.getDailyLogByDate(_dateController.text);

    if (!mounted) return;

    if (dailyLog == null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No daily log found for this date. Add a daily log first so seizure data can sync correctly.',
          ),
        ),
      );
      return;
    }

    final seizureLog = SeizureLog(
      date: _dateController.text,
      timeOfDay: _timeController.text,
      durationSeconds: int.parse(_durationController.text),
      seizureType: _seizureType,
      symptoms: _symptomsController.text.trim().isEmpty ? null : _symptomsController.text.trim(),
      mood: _mood,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
      dailyLog: dailyLog,
    );

    await DatabaseHelper.instance.insertSeizureLog(seizureLog);

    if (!mounted) return;

    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seizure log saved to backend.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Seizure')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: _pickDate,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  suffixIcon: Icon(Icons.calendar_month_outlined),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Date is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _timeController,
                readOnly: true,
                onTap: _pickTime,
                decoration: const InputDecoration(
                  labelText: 'Time',
                  suffixIcon: Icon(Icons.access_time_outlined),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Time is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Duration (seconds)'),
                validator: (v) {
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
                decoration: const InputDecoration(labelText: 'Mood During/After (1-5)'),
                items: const [1, 2, 3, 4, 5]
                    .map((value) => DropdownMenuItem(value: value, child: Text('$value')))
                    .toList(),
                onChanged: (value) => setState(() => _mood = value ?? 3),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _symptomsController,
                decoration: const InputDecoration(labelText: 'Symptoms / Aura'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
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
                      : const Text('Save Log'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

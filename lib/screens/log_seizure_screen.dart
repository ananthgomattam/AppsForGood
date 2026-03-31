import 'package:flutter/material.dart';

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
  String _seizureType = 'Tonic-clonic';

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _durationController.dispose();
    _symptomsController.dispose();
    _notesController.dispose();
    super.dispose();
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
                decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Date is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(labelText: 'Time (HH:MM)'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Time is required' : null,
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
                onChanged: (value) => setState(() => _seizureType = value!),
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
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Seizure log saved (UI only).')),
                      );
                    }
                  },
                  child: const Text('Save Log'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

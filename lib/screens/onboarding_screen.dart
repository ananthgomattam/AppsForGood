import 'package:flutter/material.dart';

import '../data/profile.dart';
import '../database/database_helper.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthController = TextEditingController();
  final _sleepController = TextEditingController(text: '8');
  DateTime? _selectedBirth;
  bool _notify = true;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _birthController.dispose();
    _sleepController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  Future<void> _pickBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirth ?? DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      _selectedBirth = picked;
      _birthController.text = _formatDate(picked);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);

    final existing = await DatabaseHelper.instance.getProfile();
    final profile = Profile(
      id: existing?.id,
      name: _nameController.text.trim(),
      dateOfBirth: _birthController.text.trim(),
      doctorName: existing?.doctorName,
      emergencyContactName: existing?.emergencyContactName,
      diagnosisDate: existing?.diagnosisDate,
      diagnosisType: existing?.diagnosisType,
      gender: existing?.gender,
      doctorPhone: existing?.doctorPhone,
      emergencyContactPhone: existing?.emergencyContactPhone,
      emergencyContactRelation: existing?.emergencyContactRelation,
      hospitalPreference: existing?.hospitalPreference,
      dailyLogRemainderHour: 20,
      dailyLogRemainderMinute: 0,
      seizureNotifications: _notify,
      createdAt: existing?.createdAt ?? DateTime.now().toIso8601String(),
    );

    if (existing == null) {
      await DatabaseHelper.instance.insertProfile(profile);
    } else {
      await DatabaseHelper.instance.updateProfile(profile);
    }

    if (!mounted) return;

    setState(() => _saving = false);
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Set up your profile',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _birthController,
                readOnly: true,
                onTap: _pickBirth,
                decoration: const InputDecoration(
                  labelText: 'Date of birth',
                  suffixIcon: Icon(Icons.calendar_month_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Date of birth is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sleepController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Average sleep hours',
                ),
                validator: (v) {
                  final value = double.tryParse(v ?? '');
                  if (value == null) return 'Enter a valid number';
                  if (value < 0 || value > 24) return 'Use a value from 0 to 24';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable seizure-risk notifications'),
                value: _notify,
                onChanged: (value) => setState(() => _notify = value),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../data/profile.dart';
import '../database/database_helper.dart';
import '../frontend/account_store.dart';
//Copilot: "Explain the key Flutter patterns for implementing an onboarding screen with form validation, date pickers, and database persistence."
// The OnboardingScreen is a stateful widget that allows users to set up their profile information when they first use the app. It includes fields for the user's name, date of birth, average sleep hours, and a toggle for enabling seizure-risk notifications. The screen validates the input and saves the profile information to the local database. Once the user completes the onboarding process, they are navigated to the dashboard screen.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}
// The _OnboardingScreenState class manages the state of the OnboardingScreen. It uses TextEditingControllers to handle user input for the name, date of birth, and average sleep hours. The state also includes a boolean for whether to enable notifications and a loading state for when the profile is being saved. The class includes methods for picking a date of birth using a date picker, validating and saving the profile information to the database, and formatting dates for display.
class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthController = TextEditingController();
  final _sleepController = TextEditingController(text: '8');
  DateTime? _selectedBirth;
  bool _notify = true;
  bool _saving = false;
// The dispose method is overridden to clean up the TextEditingControllers when the widget is removed from the widget tree. This is important to prevent memory leaks and ensure that resources are properly released.
  @override
  void dispose() {
    _nameController.dispose();
    _birthController.dispose();
    _sleepController.dispose();
    super.dispose();
  }
// The _formatDate method takes a DateTime object and formats it into a string in the format "YYYY-MM-DD". This is used to display the selected date of birth in the text field and to store it in the database in a consistent format.
  String _formatDate(DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }
// The _pickBirth method is an asynchronous function that shows a date picker dialog when the user taps on the date of birth field. It allows the user to select a date, and if a date is selected, it updates the _selectedBirth variable and sets the text of the _birthController to the formatted date string. The date picker is configured to allow selection of dates from January 1, 1900, up to the current date.
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
// The _save method is responsible for validating the form input and saving the user's profile information to the local database. It first checks if the form is valid, and if not, it returns early. If the form is valid, it sets the _saving state to true to indicate that the save operation is in progress. It then retrieves the current username from the FrontendAccountStore and checks if there is an existing profile in the database. It creates a new Profile object with the input data and either inserts it as a new record or updates the existing record in the database. After saving, it sets _saving back to false and navigates to the dashboard screen.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);

    final username = await FrontendAccountStore.instance.getCurrentUsername() ?? 'unknown';
    final existing = await DatabaseHelper.instance.getProfile();
    final profile = Profile(
      id: existing?.id,
      username: existing?.username ?? username,
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
// The build method constructs the UI for the onboarding screen. It uses a Scaffold with an AppBar and a SingleChildScrollView containing a Form. The form includes TextFormFields for the user's name, date of birth, and average sleep hours, as well as a SwitchListTile for enabling notifications. Each field has validation logic to ensure that the input is valid before allowing the user to save their profile. The save button is disabled while the profile is being saved, and shows a loading indicator during that time.
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

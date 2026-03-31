import 'package:flutter/material.dart';

class TriggersScreen extends StatefulWidget {
  const TriggersScreen({super.key});

  @override
  State<TriggersScreen> createState() => _TriggersScreenState();
}

class _TriggersScreenState extends State<TriggersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sleepController = TextEditingController(text: '8');
  final _stressController = TextEditingController(text: '4');
  final _dietController = TextEditingController(text: '3');
  bool _lightsExposure = false;
  bool _illness = false;
  bool _substanceUse = false;

  @override
  void dispose() {
    _sleepController.dispose();
    _stressController.dispose();
    _dietController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track Triggers')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _sleepController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Sleep Hours'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stressController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stress Level (1-10)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dietController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Diet Quality (1-5)'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Exposed to flashing lights'),
                value: _lightsExposure,
                onChanged: (value) => setState(() => _lightsExposure = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Illness / infection present'),
                value: _illness,
                onChanged: (value) => setState(() => _illness = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Alcohol / drug use'),
                value: _substanceUse,
                onChanged: (value) => setState(() => _substanceUse = value),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Trigger log saved (UI only).')),
                    );
                  },
                  child: const Text('Save Trigger Log'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

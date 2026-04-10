import 'package:flutter/material.dart';

import '../data/profile.dart';
import '../database/database_helper.dart';
import '../frontend/account_store.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _doctorController = TextEditingController();
  final _emergencyController = TextEditingController();
  bool _riskAlerts = true;
  Profile? _profile;
  bool _saving = false;
  String _user = 'Guest';
  List<FrontendAccount> _accounts = const [];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await FrontendAccountStore.instance.getCurrentUsername();
    final accounts = await FrontendAccountStore.instance.getAccounts();
    final profile = await DatabaseHelper.instance.getProfile();
    if (!mounted) return;
    setState(() {
      _user = user ?? 'Guest';
      _accounts = accounts;
      _profile = profile;
      if (profile != null) {
        _nameController.text = profile.name;
        _doctorController.text = profile.doctorName ?? '';
        _emergencyController.text = profile.emergencyContactName ?? '';
        _riskAlerts = profile.seizureNotifications;
      }
    });
  }

  Future<void> _switchToUser(String username) async {
    await FrontendAccountStore.instance.setCurrentUser(username);
    if (!mounted) return;
    setState(() {
      _user = username;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Switched to $username')),
    );
  }

  Future<void> _signOut() async {
    await FrontendAccountStore.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required to save your profile.')),
      );
      return;
    }

    setState(() => _saving = true);

    final base = _profile;
    final updated = Profile(
      id: base?.id,
      username: base?.username ?? 'unknown',
      name: _nameController.text.trim(),
      dateOfBirth: base?.dateOfBirth ?? '2000-01-01',
      gender: base?.gender,
      diagnosisType: base?.diagnosisType,
      diagnosisDate: base?.diagnosisDate,
      doctorName: _doctorController.text.trim().isEmpty ? null : _doctorController.text.trim(),
      doctorPhone: base?.doctorPhone,
      hospitalPreference: base?.hospitalPreference,
      emergencyContactName: _emergencyController.text.trim().isEmpty
          ? null
          : _emergencyController.text.trim(),
      emergencyContactPhone: base?.emergencyContactPhone,
      emergencyContactRelation: base?.emergencyContactRelation,
      dailyLogRemainderHour: base?.dailyLogRemainderHour ?? 20,
      dailyLogRemainderMinute: base?.dailyLogRemainderMinute ?? 0,
      seizureNotifications: _riskAlerts,
      createdAt: base?.createdAt ?? DateTime.now().toIso8601String(),
    );

    if (base == null) {
      await DatabaseHelper.instance.insertProfile(updated);
    } else {
      await DatabaseHelper.instance.updateProfile(updated);
    }

    final refreshed = await DatabaseHelper.instance.getProfile();
    if (!mounted) return;

    setState(() {
      _saving = false;
      _profile = refreshed;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved to backend.')),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doctorController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.switch_account_rounded, color: Color(0xFF660066)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Signed in as $_user',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton(onPressed: _signOut, child: const Text('Sign out')),
                      ],
                    ),
                    if (_accounts.length > 1) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Switch account',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _accounts
                            .where((account) => account.username != _user)
                            .map(
                              (account) => ActionChip(
                                avatar: const Icon(Icons.person_outline, size: 16),
                                label: Text(account.username),
                                onPressed: () => _switchToUser(account.username),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _doctorController,
                      decoration: const InputDecoration(labelText: 'Doctor Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emergencyController,
                      decoration: const InputDecoration(labelText: 'Emergency Contact'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                title: const Text('Enable seizure risk notifications'),
                subtitle: const Text('Receive reminders during high-risk periods.'),
                value: _riskAlerts,
                onChanged: (value) => setState(() => _riskAlerts = value),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

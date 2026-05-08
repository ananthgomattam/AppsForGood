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
      } else {
        _nameController.clear();
        _doctorController.clear();
        _emergencyController.clear();
        _riskAlerts = true;
      }
    });
  }

  Future<String?> _promptForPassword({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        bool hidePassword = true;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    obscureText: hidePassword,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setDialogState(() => hidePassword = !hidePassword);
                        },
                        icon: Icon(hidePassword ? Icons.visibility_off : Icons.visibility),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, controller.text),
                  child: Text(confirmLabel),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _switchToUser(FrontendAccount account) async {
    final messenger = ScaffoldMessenger.of(context);
    final password = await _promptForPassword(
      title: 'Switch account',
      message: 'Enter the password for ${account.username} to switch to this account.',
      confirmLabel: 'Switch',
    );
    if (password == null) return;

    final result = await FrontendAccountStore.instance.signIn(
      username: account.username,
      password: password,
    );
    if (!mounted) return;

    if (!result.success) {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message ?? 'Unable to switch accounts.')),
      );
      return;
    }

    await _loadUser();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text('Switched to ${account.username}')),
    );
  }

  Future<void> _deleteAccount() async {
    if (_user == 'Guest') {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final password = await _promptForPassword(
      title: 'Delete account',
      message: 'Enter the password for $_user to permanently delete this account and its data.',
      confirmLabel: 'Delete',
    );
    if (password == null) return;

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm deletion'),
          content: Text('This will permanently delete $_user and all of their saved data.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;

    final result = await FrontendAccountStore.instance.deleteAccount(
      username: _user,
      password: password,
    );
    if (!mounted) return;

    if (!result.success) {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message ?? 'Unable to delete account.')),
      );
      return;
    }

    if (result.deletedCurrentUser) {
      navigator.pushNamedAndRemoveUntil('/login', (_) => false);
      return;
    }

    await _loadUser();
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text('Deleted $_user.')),
    );
  }

  Future<void> _signOut() async {
    await FrontendAccountStore.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);

    if (_nameController.text.trim().isEmpty) {
      messenger.showSnackBar(
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

    messenger.showSnackBar(
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
                                onPressed: () => _switchToUser(account),
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
              child: OutlinedButton.icon(
                onPressed: _user == 'Guest' ? null : _deleteAccount,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                label: const Text('Delete account'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
              ),
            ),
            const SizedBox(height: 10),
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
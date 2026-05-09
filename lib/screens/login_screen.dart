import 'package:flutter/material.dart';

import '../frontend/account_store.dart';
// The LoginScreen is the entry point for users to access their accounts. It provides a user-friendly interface for signing in or creating a new account, with form validation and error handling to ensure a smooth authentication process. The screen features a visually appealing design with a gradient background and a card-based layout for the forms, making it easy for users to navigate and interact with the authentication options.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
// The LoginScreen provides a user interface for signing in or creating an account. It includes form validation, error handling, and communicates with the FrontendAccountStore to perform authentication actions. The screen features a tabbed layout for switching between sign-in and account creation forms, and it displays feedback to the user based on the success or failure of their actions.
class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _signInFormKey = GlobalKey<FormState>();
  final _createFormKey = GlobalKey<FormState>();

  final _signInUsername = TextEditingController();
  final _signInPassword = TextEditingController();

  final _createUsername = TextEditingController();
  final _createPassword = TextEditingController();
  final _createConfirmPassword = TextEditingController();

  bool _busy = false;
  bool _hideSignInPassword = true;
  bool _hideCreatePassword = true;
  bool _hideCreateConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInUsername.dispose();
    _signInPassword.dispose();
    _createUsername.dispose();
    _createPassword.dispose();
    _createConfirmPassword.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_signInFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _busy = true);
    final result = await FrontendAccountStore.instance.signIn(
      username: _signInUsername.text,
      password: _signInPassword.text,
    );
    if (!mounted) return;

    setState(() => _busy = false);
    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Unable to sign in.')),
      );
      return;
    }

    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  Future<void> _createAccount() async {
    if (!_createFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _busy = true);
    final result = await FrontendAccountStore.instance.signUp(
      username: _createUsername.text,
      password: _createPassword.text,
    );
    if (!mounted) return;

    setState(() => _busy = false);
    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Unable to create account.')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF522583),
              Color(0xFF9D00FF),
              Color(0xFFA020F0),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.health_and_safety_rounded, size: 70, color: Colors.white),
                    const SizedBox(height: 14),
                    const Text(
                      'ForSeizure',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'A cleaner way to track triggers, risk, and medication.',
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: const [
                        _FeatureTag(label: 'Trigger Tracking'),
                        _FeatureTag(label: 'Risk Forecasts'),
                        _FeatureTag(label: 'Medication Plans'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            TabBar(
                              controller: _tabController,
                              labelColor: const Color(0xFF522583),
                              indicatorColor: const Color(0xFF9D00FF),
                              tabs: const [
                                Tab(text: 'Sign In'),
                                Tab(text: 'Create Account'),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 332,
                              child: TabBarView(
                                controller: _tabController,
                                clipBehavior: Clip.none,
                                children: [
                                  _buildSignInForm(context),
                                  _buildCreateAccountForm(context),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
// The _buildSignInForm method constructs the form for signing in, including fields for username and password, validation logic, and a submit button that triggers the sign-in process. It also includes functionality to toggle password visibility and displays a loading indicator when the sign-in process is in progress.
  Widget _buildSignInForm(BuildContext context) {
    return Form(
      key: _signInFormKey,
      child: Column(
        children: [
          const SizedBox(height: 6),
          TextFormField(
            controller: _signInUsername,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Username is required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _signInPassword,
            obscureText: _hideSignInPassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _hideSignInPassword = !_hideSignInPassword),
                icon: Icon(_hideSignInPassword ? Icons.visibility_off : Icons.visibility),
              ),
            ),
            validator: (value) => (value == null || value.isEmpty) ? 'Password is required' : null,
          ),
          const SizedBox(height: 8),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _signIn,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Sign In'),
            ),
          ),
        ],
      ),
    );
  }
// The _buildCreateAccountForm method constructs the form for creating a new account, including fields for username, password, and password confirmation, along with validation logic to ensure proper input. It also includes functionality to toggle password visibility and displays a loading indicator when the account creation process is in progress. Additionally, it provides a reminder to users about the importance of remembering their credentials due to the lack of a 'Forgot password' option.
  Widget _buildCreateAccountForm(BuildContext context) {
    return Form(
      key: _createFormKey,
      child: Column(
        children: [
          const SizedBox(height: 6),
          TextFormField(
            controller: _createUsername,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.person_add_alt_1_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Username is required';
              }
              if (value.trim().length < 3) {
                return 'Use at least 3 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _createPassword,
            obscureText: _hideCreatePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.password_outlined),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _hideCreatePassword = !_hideCreatePassword),
                icon: Icon(_hideCreatePassword ? Icons.visibility_off : Icons.visibility),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 6) {
                return 'Use at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _createConfirmPassword,
            obscureText: _hideCreateConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.verified_user_outlined),
              suffixIcon: IconButton(
                onPressed: () => setState(
                  () => _hideCreateConfirmPassword = !_hideCreateConfirmPassword,
                ),
                icon: Icon(_hideCreateConfirmPassword ? Icons.visibility_off : Icons.visibility),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _createPassword.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          const Text(
            "Please write down your username and password — there is no 'Forgot password' option.",
            style: TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _createAccount,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Create Account'),
            ),
          ),
        ],
      ),
    );
  }
}
// The _FeatureTag widget is a reusable component that displays a label within a styled container, used to highlight key features of the app on the login screen. It features a semi-transparent background, rounded borders, and a consistent text style to maintain visual cohesion with the overall design of the login screen.
class _FeatureTag extends StatelessWidget {
  final String label;

  const _FeatureTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x40FFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x80FFFFFF)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

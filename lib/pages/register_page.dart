import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _loading = false;
  String? _error;

  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final username = _username.text.trim();
    final email = _email.text.trim();
    final pass = _password.text;
    final conf = _confirm.text;

    // Validate if all fields are filled and password matches
    if (username.isEmpty) {
      setState(() => _error = 'Please enter a username.');
      return;
    }
    if (email.isEmpty) {
      setState(() => _error = 'Please enter an email address.');
      return;
    }
    if (pass.isEmpty) {
      setState(() => _error = 'Please enter a password.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (pass != conf) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Create user in Firebase Authentication
      final userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);

      final user = userCred.user!;
      await user.updateDisplayName(username);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
        ),
      );

      // Replace current screen with the login page after successful registration
      Navigator.pushReplacementNamed(context, '/login');  // Ensure '/login' route exists

    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    InputDecoration _decor({
      required String label,
      required IconData icon,
      Widget? suffix,
      String? hint,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.05, 0.45, 1],
            colors: [
              scheme.primary.withOpacity(0.12),
              scheme.secondary.withOpacity(0.10),
              scheme.surfaceVariant.withOpacity(0.10),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, child) => Transform.translate(
                    offset: Offset(0, (1 - t) * 16),
                    child: Opacity(opacity: t, child: child),
                  ),
                  child: Card(
                    elevation: 8,
                    shadowColor: scheme.primary.withOpacity(0.25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top icon for registration
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.person_add_alt_1_outlined,
                              size: 42,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Register',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Create your account',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 16),

                          // Error message display
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _error == null
                                ? const SizedBox.shrink()
                                : Container(
                                    key: const ValueKey('err'),
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: scheme.errorContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: scheme.onErrorContainer,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _error!,
                                            style: TextStyle(
                                              color: scheme.onErrorContainer,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),

                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Username field
                                TextFormField(
                                  controller: _username,
                                  textInputAction: TextInputAction.next,
                                  decoration: _decor(
                                    label: 'Username',
                                    icon: Icons.person_outline,
                                    hint: 'Your name',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Email field
                                TextFormField(
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: _decor(
                                    label: 'Email',
                                    icon: Icons.alternate_email,
                                    hint: 'you@example.com',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Password field
                                TextFormField(
                                  controller: _password,
                                  obscureText: _obscurePass,
                                  textInputAction: TextInputAction.next,
                                  decoration: _decor(
                                    label: 'Password',
                                    icon: Icons.lock_outline,
                                    suffix: IconButton(
                                      tooltip: _obscurePass ? 'Show' : 'Hide',
                                      onPressed: () => setState(
                                        () => _obscurePass = !_obscurePass,
                                      ),
                                      icon: Icon(
                                        _obscurePass
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Confirm password field
                                TextFormField(
                                  controller: _confirm,
                                  obscureText: _obscureConfirm,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) =>
                                      _loading ? null : _register(),
                                  decoration: _decor(
                                    label: 'Confirm Password',
                                    icon: Icons.lock_person_outlined,
                                    suffix: IconButton(
                                      tooltip: _obscureConfirm
                                          ? 'Show'
                                          : 'Hide',
                                      onPressed: () => setState(
                                        () =>
                                            _obscureConfirm = !_obscureConfirm,
                                      ),
                                      icon: Icon(
                                        _obscureConfirm
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: FilledButton(
                                    onPressed: _loading ? null : _register,
                                    child: _loading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                            ),
                                          )
                                        : const Text('Create account'),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account?",
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                              TextButton(
                                onPressed: _loading
                                    ? null
                                    : () => Navigator.pop(context),
                                child: const Text('Log in'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

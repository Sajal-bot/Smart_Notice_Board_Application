import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      // No manual navigation — AuthGate will show Home
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Login failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      // Gorgeous gradient background
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
                        // App mark
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.dashboard_outlined,
                            size: 42,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Smart Notice Board',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sign in to continue',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),

                        const SizedBox(height: 16),

                        // Error banner (animated)
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

                        // Form
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.username,
                                  AutofillHints.email,
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'you@example.com',
                                  prefixIcon: const Icon(Icons.alternate_email),
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Email is required';
                                  }
                                  final ok = RegExp(
                                    r'^[^@]+@[^@]+\.[^@]+',
                                  ).hasMatch(v.trim());
                                  if (!ok) return 'Enter a valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _password,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                onFieldSubmitted: (_) =>
                                    _loading ? null : _login(),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: _obscure ? 'Show' : 'Hide',
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                  ),
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Password is required';
                                  if (v.length < 6)
                                    return 'At least 6 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () async {
                                    final email = _email.text.trim();
                                    if (email.isEmpty) {
                                      setState(
                                        () => _error =
                                            'Enter email to reset password',
                                      );
                                      return;
                                    }
                                    try {
                                      await FirebaseAuth.instance
                                          .sendPasswordResetEmail(email: email);
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Password reset email sent',
                                          ),
                                        ),
                                      );
                                    } on FirebaseAuthException catch (e) {
                                      setState(() => _error = e.message);
                                    }
                                  },
                                  child: const Text('Forgot password?'),
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: FilledButton(
                                  onPressed: _loading ? null : _login,
                                  child: _loading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                          ),
                                        )
                                      : const Text('Sign in'),
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
                              "New here?",
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                            TextButton(
                              onPressed: _loading
                                  ? null
                                  : () => Navigator.pushNamed(
                                      context,
                                      '/register',
                                    ),
                              child: const Text('Create an account'),
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
    );
  }
}

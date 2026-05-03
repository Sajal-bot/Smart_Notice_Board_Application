import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginRegisterPage extends StatefulWidget {
  const LoginRegisterPage({super.key});

  @override
  State<LoginRegisterPage> createState() => _LoginRegisterPageState();
}

class _LoginRegisterPageState extends State<LoginRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  bool isLogin = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      try {
        if (isLogin) {
          UserCredential userCredential = await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: email, password: password);

          print("🟢 Logged in as: ${userCredential.user?.email}");

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('✅ Home Page')),
              ),
            ),
          );
        } else {
          UserCredential userCredential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(email: email, password: password);

          print("🟢 Registered user: ${userCredential.user?.email}");

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Registration successful!')),
          );

          Future.delayed(const Duration(seconds: 2), () {
            setState(() {
              isLogin = true;
              _emailController.clear();
              _passwordController.clear();
              _confirmPasswordController.clear();
            });
          });
        }
      } on FirebaseAuthException catch (e) {
        print("❌ Firebase error: ${e.message}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Firebase Error: ${e.message}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Login' : 'Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value!.isEmpty ? 'Please enter email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value!.length < 6 ? 'Minimum 6 characters' : null,
              ),
              if (!isLogin) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(labelText: 'Confirm Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: Text(isLogin ? 'Login' : 'Register'),
              ),
              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(
                  isLogin
                      ? 'Don\'t have an account? Register'
                      : 'Already have an account? Login',
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

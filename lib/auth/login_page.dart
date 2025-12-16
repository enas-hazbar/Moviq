import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'register_page.dart';
import 'auth_widgets.dart';
import 'package:moviq/screen/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  Future<void> _signInWithGoogle() async {
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) _navigateToHome();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to sign in with Google: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signInWithApple() async {
    try {
      final user = await _authService.signInWithApple();
      if (user != null) _navigateToHome();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to sign in with Apple: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signInWithEmail() async {
    try {
      final user = await _authService.signInWithEmail(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
      if (user != null) _navigateToHome();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Email sign in failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              const Text(
                "MOVIQ",
                style: TextStyle(
                  fontSize: 28,
                  letterSpacing: 6,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),

              // Poster Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  "assets/psycho.jpg",
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),

              // Title
              const Text(
                "Sign in to Moviq",
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: "Serif",
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 15),

              // Input Panel
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: panelColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _email,
                      style: const TextStyle(color: Colors.white),
                      decoration: authInput("Email"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: authInput("Password"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // Login Button
              authButton("Login", _signInWithEmail),
              const SizedBox(height: 10),

              // Or text
              const Text("or", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 10),

              // Social Buttons
              authButton("Sign in with Google", _signInWithGoogle),
              const SizedBox(height: 8),
              authButton("Sign in with Apple", _signInWithApple),
              const SizedBox(height: 12),

              // Register link
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  );
                },
                child: const Text(
                  "Don't have an account? Register",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'auth_widgets.dart';
import 'package:moviq/screen/genre_onboarding_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _authService = AuthService();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _termsAccepted = false;
  bool _termsExpanded = false;
  bool _loading = false;

  String? _passwordValidationError(String value) {
    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must include at least one capital letter.';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must include at least one small letter.';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Password must include at least one number.';
    }
    if (!RegExp("[!@#\u0024%\\^&*(),.?\":{}|<>_\\-\\\\/\\[\\]`~+=]")
        .hasMatch(value)) {
      return 'Password must include at least one special character.';
    }
    return null;
  }

  Future<void> _register() async {
    if (!_termsAccepted || _loading) return;

    setState(() => _loading = true);

    try {
      final password = _password.text.trim();
      final confirm = _confirm.text.trim();
      final error = _passwordValidationError(password);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
        return;
      }
      if (password != confirm) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Passwords don't match."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final user = await _authService.signUpWithEmail(
        email: _email.text.trim(),
        password: password,
        username: _username.text.trim(),
      );

      if (user != null && mounted) {
        //
        //
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const GenreOnboardingPage(),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Registration failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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

          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              "assets/psycho.jpg",
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),

          const Text(
            "Register to Moviq",
            style: TextStyle(
              fontSize: 24,
              fontFamily: "Serif",
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 15),

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
                const SizedBox(height: 10),
                TextField(
                  controller: _username,
                  style: const TextStyle(color: Colors.white),
                  decoration: authInput("Username"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _password,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: authInput("Password"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _confirm,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: authInput("Confirm Password"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Checkbox(
                value: _termsAccepted,
                onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                activeColor: Colors.white,
                checkColor: Colors.black,
              ),
              const Expanded(
                child: Text(
                  "I agree to the Terms & Conditions",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),

          GestureDetector(
            onTap: () => setState(() => _termsExpanded = !_termsExpanded),
            child: Row(
              children: [
                Icon(
                  _termsExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.white70,
                ),
                const SizedBox(width: 4),
                const Text(
                  "View Terms & Conditions",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          if (_termsExpanded)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const SingleChildScrollView(
                child: Text(
                  "By using this app, you agree to our community guidelines.",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ),

          const SizedBox(height: 12),

          authButton(
            _loading ? "Creating account..." : "Register",
            _register,
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: content,
        ),
      ),
    );
  }
}

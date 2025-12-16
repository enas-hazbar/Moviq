import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'auth_widgets.dart';

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

  Future<void> _register() async {
    if (!_termsAccepted) return;

    try {
      final user = await _authService.signUpWithEmail(
        email: _email.text.trim(),
        password: _password.text.trim(),
        username: _username.text.trim(),
      );
      if (user != null) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Registration failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // The main content
    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // LOGO
          const Text(
            "MOVIQ",
            style: TextStyle(
                fontSize: 28,
                letterSpacing: 6,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 10),

          // POSTER
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              "assets/images/psycho.jpg",
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),

          // TITLE
          const Text(
            "Register to Moviq",
            style: TextStyle(
                fontSize: 24, fontFamily: "Serif", color: Colors.white70),
          ),
          const SizedBox(height: 15),

          // INPUT PANEL
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

          // TERMS & CONDITIONS Checkbox
          Row(
            children: [
              Checkbox(
                value: _termsAccepted,
                onChanged: (v) => setState(() => _termsAccepted = v!),
                checkColor: Colors.black,
                activeColor: Colors.white,
              ),
              const Expanded(
                child: Text(
                  "I agree to the Terms & Conditions",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),

          // Expand/collapse toggle
          GestureDetector(
            onTap: () {
              setState(() {
                _termsExpanded = !_termsExpanded;
              });
            },
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

          // Terms text, scrollable only if expanded
          if (_termsExpanded)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(6),
              ),
              height: 120, // fixed height
              child: SingleChildScrollView(
                child: const Text(
                  "By using this app, you agree that any content you submit complies with our community guidelines and does not infringe on intellectual property rights. The app reserves the right to suspend or terminate accounts that violate these terms.",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ),

          const SizedBox(height: 10),

          // REGISTER BUTTON
          authButton("Register", _register),
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
      // Wrap the page in SingleChildScrollView only when terms are expanded
      body: SafeArea(
        child: _termsExpanded
            ? SingleChildScrollView(child: content)
            : content,
      ),
    );
  }
}

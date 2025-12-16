import 'dart:async';
import 'package:flutter/material.dart';
import 'home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4B2C2C),
      body: SafeArea(
        child: Column(
          children: [
            // 🔝 Top bar
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: const [
                  Text(
                    'M O V I Q',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      letterSpacing: 7.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 6),
                  Divider(
                    color: Colors.white,
                    thickness: 1.2,
                    indent: 40,
                    endIndent: 40,
                  ),
                ],
              ),
            ),

            const Spacer(),
            Column(
              children: [
                Image.asset(
                  'assets/Moviq_logo.png',
                  height: 180,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                const Text(
                  'MOVIQ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

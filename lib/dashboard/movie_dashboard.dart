import 'package:flutter/material.dart';
import '../screen/home_page.dart';

class MovieDashboard extends StatelessWidget {
  const MovieDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('MOVIQ'),
        centerTitle: true,
      ),
      body: const HomePage(), // ← THIS is the key
    );
  }
}

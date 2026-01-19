import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_page.dart';

class GenreOnboardingPage extends StatefulWidget {
  const GenreOnboardingPage({super.key});

  @override
  State<GenreOnboardingPage> createState() => _GenreOnboardingPageState();
}

class _GenreOnboardingPageState extends State<GenreOnboardingPage> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  final Map<int, String> genres = {
    28: 'Action',
    12: 'Adventure',
    18: 'Drama',
    35: 'Comedy',
    27: 'Horror',
    878: 'Sci-Fi',
    10749: 'Romance',
  };

  final Set<int> selected = {};

  Future<void> _save() async {
    final uid = _auth.currentUser!.uid;

    await _db
        .collection('users')
        .doc(uid)
        .collection('preferences')
        .doc('profile')
        .set({
      'genres': selected.toList(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
Widget build(BuildContext context) {
  final bottom = MediaQuery.of(context).padding.bottom; // system bar / gesture area

  return Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      title: const Text('Choose genres'),
      automaticallyImplyLeading: false,
    ),

    body: Padding(
      padding: const EdgeInsets.all(12),
      child: Align(
        alignment: Alignment.topCenter,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: genres.entries.map((e) {
            return ChoiceChip(
              label: Text(e.value),
              selected: selected.contains(e.key),
              onSelected: (v) {
                setState(() {
                  v ? selected.add(e.key) : selected.remove(e.key);
                });
              },
            );
          }).toList(),
        ),
      ),
    ),

    bottomNavigationBar: SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + bottom + 8), // extra space for Samsung gestures
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: selected.isEmpty ? null : _save,
            child: const Text('Continue'),
          ),
        ),
      ),
    ),
  );
}
}

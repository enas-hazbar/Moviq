import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InteractionService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  Future<void> logInteraction({
    required List<int> genreIds,
    required double weight,
    required String source,
    int? movieId,
  }) async {
    if (uid == null) return;

    await _db.collection('users').doc(uid!).collection('interactions').add({
      'genreIds': genreIds,
      'weight': weight,
      'source': source,
      'movieId': movieId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/movie.dart';
import 'tmdb_service.dart';

class RecommendationService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _tmdb = TmdbService();

  String? get uid => _auth.currentUser?.uid;

  Future<List<Movie>> getRecommendedForYou() async {
    if (uid == null) {
      return _tmdb.getTrendingMovies();
    }

    // Try interaction-based recommendation
    final interactionGenres = await _getInteractionGenreScores();

    if (interactionGenres.isNotEmpty) {
      return _discoverByGenreScores(interactionGenres);
    }

    // Fallback to onboarding preferences
    final onboardingGenres = await _getOnboardingGenres();

    if (onboardingGenres.isNotEmpty) {
      return _discoverByGenreScores(onboardingGenres);
    }

    // 3️⃣ Final fallback
    return _tmdb.getTrendingMovies();
  }

  /* ================== HELPERS ================== */

  Future<Map<int, double>> _getInteractionGenreScores() async {
    final snap = await _db
        .collection('users')
        .doc(uid!)
        .collection('interactions')
        .get();

    final Map<int, double> scores = {};

    for (final doc in snap.docs) {
      final data = doc.data();
      final List<dynamic>? genres = data['genreIds'];
      final num weight = data['weight'] ?? 1;

      if (genres == null) continue;

      for (final g in genres) {
        if (g is int) {
          scores[g] = (scores[g] ?? 0) + weight.toDouble();
        }
      }
    }

    return scores;
  }

  Future<Map<int, double>> _getOnboardingGenres() async {
    final doc = await _db
        .collection('users')
        .doc(uid!)
        .collection('preferences')
        .doc('profile')
        .get();

    if (!doc.exists) return {};

    final List<dynamic>? genres = doc.data()?['genres'];
    if (genres == null) return {};

    return {
      for (final g in genres)
        if (g is int) g: 5.0
    };
  }

  Future<List<Movie>> _discoverByGenreScores(
    Map<int, double> genreScores,
  ) async {
    final sorted = genreScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final Set<Movie> results = {};

    for (final entry in sorted.take(3)) {
      final movies = await _tmdb.discoverMovies(
        genreId: entry.key,
        minRating: 6.8,
      );
      results.addAll(movies);
    }

    return results.take(12).toList();
  }
}

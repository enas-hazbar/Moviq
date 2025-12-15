import 'package:flutter_dotenv/flutter_dotenv.dart';

class TmdbConfig {
  static final String apiKey = _readApiKey();
  static const String baseUrl = 'https://api.themoviedb.org/3';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  static String _readApiKey() {
    final key = dotenv.env['TMDB_API_KEY'];
    if (key == null || key.isEmpty) {
      throw StateError(
        'TMDB_API_KEY not found. Make sure .env is loaded before using TmdbConfig.',
      );
    }
    return key;
  }
}
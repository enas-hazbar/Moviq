import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import '../config/tmdb_config.dart';

class TmdbService {
  Future<List<Movie>> getPopularMovies() async {
    final response = await http.get(
      Uri.parse(
        '${TmdbConfig.baseUrl}/movie/popular?api_key=${TmdbConfig.apiKey}',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((e) => Movie.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load popular movies');
    }
  }
}

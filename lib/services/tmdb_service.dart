import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import '../config/tmdb_config.dart';

class TmdbService {
  Future<List<Movie>> getPopularMovies() async {
    final response = await http.get(_buildUri('/movie/popular'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((e) => Movie.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load popular movies');
    }
  }

  Future<List<Movie>> getTrendingThisWeek() async {
    final response = await http.get(_buildUri('/trending/movie/week'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((e) => Movie.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load trending movies');
    }
  }

  Future<List<Movie>> getUpcomingMovies() async {
    final response = await http.get(_buildUri('/movie/upcoming'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((e) => Movie.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load upcoming movies');
    }
  }

  Uri _buildUri(String path) {
    return Uri.parse('${TmdbConfig.baseUrl}$path?api_key=${TmdbConfig.apiKey}');
  }
}

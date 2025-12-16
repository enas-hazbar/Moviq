import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import '../config/tmdb_config.dart';

class TmdbService {
  Future<List<Movie>> getPopularMovies() async {
    final response = await http.get(_buildUri('/movie/popular'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load popular movies');
    }

    final data = json.decode(response.body);
    return (data['results'] as List)
        .map((e) => Movie.fromJson(e))
        .toList();
  }

  Future<Map<String, dynamic>> getMovieDetails(int movieId) async {
    final response = await http.get(
      Uri.parse(
        '${TmdbConfig.baseUrl}/movie/$movieId?api_key=${TmdbConfig.apiKey}',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load movie details');
    }

    return json.decode(response.body);
  }

  Future<List<dynamic>> getMovieVideos(int movieId) async {
    final response = await http.get(
      Uri.parse(
        '${TmdbConfig.baseUrl}/movie/$movieId/videos?api_key=${TmdbConfig.apiKey}',
      ),
    );

    final data = json.decode(response.body);
    return data['results'];
  }

  Future<Map<String, dynamic>> getCredits(int movieId) async {
    final response = await http.get(
      Uri.parse(
        '${TmdbConfig.baseUrl}/movie/$movieId/credits?api_key=${TmdbConfig.apiKey}',
      ),
    );

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> getWatchProviders(int movieId) async {
    final response = await http.get(
      Uri.parse(
        '${TmdbConfig.baseUrl}/movie/$movieId/watch/providers?api_key=${TmdbConfig.apiKey}',
      ),
    );

    return json.decode(response.body)['results'];
  }

  Future<List<Movie>> getSimilarMovies(int movieId) async {
    final response = await http.get(
      Uri.parse(
        '${TmdbConfig.baseUrl}/movie/$movieId/similar?api_key=${TmdbConfig.apiKey}',
      ),
    );

    final data = json.decode(response.body);
    return (data['results'] as List)
        .map((e) => Movie.fromJson(e))
        .toList();
  }
  Future<Map<String, dynamic>> getPersonDetails(int personId) async {
  final response = await http.get(
    Uri.parse(
      '${TmdbConfig.baseUrl}/person/$personId?api_key=${TmdbConfig.apiKey}',
    ),
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to load actor details');
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

Future<List<Map<String, dynamic>>> getPersonMovieCredits(int personId) async {
  final response = await http.get(
    Uri.parse(
      '${TmdbConfig.baseUrl}/person/$personId/movie_credits?api_key=${TmdbConfig.apiKey}',
    ),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data['cast']);
  } else {
    throw Exception('Failed to load actor movies');
  }
}
}

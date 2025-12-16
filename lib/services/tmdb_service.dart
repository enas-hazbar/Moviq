import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import '../config/tmdb_config.dart';

class TmdbService {
  Uri _buildUri(String path) {
    return Uri.parse(
      '${TmdbConfig.baseUrl}$path?api_key=${TmdbConfig.apiKey}',
    );
  }

  Future<List<Movie>> getPopularMovies() async {
    final response = await http.get(_buildUri('/movie/popular'));
    final data = json.decode(response.body);
    return (data['results'] as List)
        .map((e) => Movie.fromJson(e))
        .toList();
  }

  Future<List<Movie>> getTrendingMovies() async {
    final response = await http.get(_buildUri('/trending/movie/week'));
    final data = json.decode(response.body);
    return (data['results'] as List)
        .map((e) => Movie.fromJson(e))
        .toList();
  }

  Future<List<Movie>> getUpcomingMovies() async {
    final response = await http.get(_buildUri('/movie/upcoming'));
    final data = json.decode(response.body);
    return (data['results'] as List)
        .map((e) => Movie.fromJson(e))
        .toList();
  }

  Future<Map<String, dynamic>> getMovieDetails(int movieId) async {
    final response =
        await http.get(_buildUri('/movie/$movieId'));
    return json.decode(response.body);
  }

  Future<List<dynamic>> getMovieVideos(int movieId) async {
    final response =
        await http.get(_buildUri('/movie/$movieId/videos'));
    return json.decode(response.body)['results'];
  }

  Future<Map<String, dynamic>> getCredits(int movieId) async {
    final response =
        await http.get(_buildUri('/movie/$movieId/credits'));
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> getWatchProviders(int movieId) async {
    final response =
        await http.get(_buildUri('/movie/$movieId/watch/providers'));
    return json.decode(response.body)['results'];
  }

  Future<List<Movie>> getSimilarMovies(int movieId) async {
    final response =
        await http.get(_buildUri('/movie/$movieId/similar'));
    final data = json.decode(response.body);
    return (data['results'] as List)
        .map((e) => Movie.fromJson(e))
        .toList();
  }

  /// ACTORS
  Future<Map<String, dynamic>> getPersonDetails(int personId) async {
    final response =
        await http.get(_buildUri('/person/$personId'));
    return json.decode(response.body);
  }

  Future<List<Map<String, dynamic>>> getPersonMovieCredits(
      int personId) async {
    final response =
        await http.get(_buildUri('/person/$personId/movie_credits'));
    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data['cast']);
  }
}

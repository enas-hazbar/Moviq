import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import '../config/tmdb_config.dart';

class TmdbService {
  Uri _buildUri(String path, {Map<String, String>? params}) {
    final uri = Uri.parse('${TmdbConfig.baseUrl}$path');

    return uri.replace(queryParameters: {
      'api_key': TmdbConfig.apiKey,
      if (params != null) ...params,
    });
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

  /// MOVIE DETAILS
  Future<Map<String, dynamic>> getMovieDetails(int movieId) async {
    final response = await http.get(
      _buildUri(
        '/movie/$movieId',
        params: {
          'append_to_response': 'credits,recommendations,similar'
        },
      ),
    );

    return json.decode(response.body);
  }

  Future<List<dynamic>> getMovieVideos(int movieId) async {
    final response = await http.get(_buildUri('/movie/$movieId/videos'));
    return json.decode(response.body)['results'];
  }

  Future<Map<String, dynamic>> getCredits(int movieId) async {
    final response = await http.get(_buildUri('/movie/$movieId/credits'));
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> getWatchProviders(int movieId) async {
    final response =
        await http.get(_buildUri('/movie/$movieId/watch/providers'));

    return json.decode(response.body)['results'];
  }

  Future<List<Movie>> getSimilarMovies(int movieId) async {
    final response = await http.get(_buildUri('/movie/$movieId/similar'));
    final data = json.decode(response.body);

    return (data['results'] as List)
        .map((e) => Movie.fromJson(e))
        .toList();
  }

  Future<Map<int, String>> getGenres() async {
    final response = await http.get(_buildUri('/genre/movie/list'));
    final data = json.decode(response.body);

    return {
      for (var g in data['genres']) g['id']: g['name'],
    };
  }

  Future<List<Movie>> searchMovies(String query) async {
    final response = await http.get(
      _buildUri(
        '/search/movie',
        params: {
          'query': query,
          'language': 'en-US'
        },
      ),
    );

    final data = json.decode(response.body);

    return (data['results'] as List)
        .map((e) => Movie.fromJson(e))
        .toList();
  }

  /// DISCOVER (FILTERS)
Future<List<Movie>> discoverMovies({
  int? startYear,
  int? endYear,
  int? genreId,
  double? minRating,
}) async {
  final params = {
    'api_key': TmdbConfig.apiKey,
    if (startYear != null)
      'primary_release_date.gte': '$startYear-01-01',
    if (endYear != null)
      'primary_release_date.lte': '$endYear-12-31',
    if (genreId != null) 'with_genres': '$genreId',
    if (minRating != null) 'vote_average.gte': '$minRating',
    'sort_by': 'popularity.desc',
  };

    final response = await http.get(
      _buildUri('/discover/movie', params: params),
    );

    final data = json.decode(response.body);

    return (data['results'] as List)
        .map((e) => Movie.fromJson(e))
        .toList();
  }

  Future<Map<String, dynamic>> getPersonDetails(int personId) async {
    final response = await http.get(_buildUri('/person/$personId'));
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

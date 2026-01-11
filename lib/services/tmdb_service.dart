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

  /// POPULAR
  Future<List<Movie>> getPopularMovies() async {
    final response = await http.get(_buildUri('/movie/popular'));
    final data = json.decode(response.body);

    return (data['results'] as List)
        .map((e) => Movie.fromJson(e))
        .toList();
  }

  /// TRENDING
  Future<List<Movie>> getTrendingMovies() async {
    final response = await http.get(_buildUri('/trending/movie/week'));
    final data = json.decode(response.body);

    return (data['results'] as List)
        .map((e) => Movie.fromJson(e))
        .toList();
  }

  /// UPCOMING
  Future<List<Movie>> getUpcomingMovies() async {
    final response = await http.get(_buildUri('/movie/upcoming'));
    final data = json.decode(response.body);

    return (data['results'] as List)
        .map((e) => Movie.fromJson(e))
        .toList();
  }

  /// MOVIE DETAILS
  Future<Map<String, dynamic>> getMovieDetails(int movieId) async {
    final response = await http.get(_buildUri('/movie/$movieId'));
    return json.decode(response.body);
  }

  /// ▶VIDEOS
  Future<List<dynamic>> getMovieVideos(int movieId) async {
    final response = await http.get(_buildUri('/movie/$movieId/videos'));
    return json.decode(response.body)['results'];
  }

  /// CREDITS
  Future<Map<String, dynamic>> getCredits(int movieId) async {
    final response = await http.get(_buildUri('/movie/$movieId/credits'));
    return json.decode(response.body);
  }

  /// WATCH PROVIDERS
  Future<Map<String, dynamic>> getWatchProviders(int movieId) async {
    final response =
        await http.get(_buildUri('/movie/$movieId/watch/providers'));
    return json.decode(response.body)['results'];
  }

  /// SIMILAR
  Future<List<Movie>> getSimilarMovies(int movieId) async {
    final response = await http.get(_buildUri('/movie/$movieId/similar'));
    final data = json.decode(response.body);

    return (data['results'] as List)
        .map((e) => Movie.fromJson(e))
        .toList();
  }

  

  /// GENRES
  Future<Map<int, String>> getGenres() async {
    final response = await http.get(_buildUri('/genre/movie/list'));
    final data = json.decode(response.body);

    return {
      for (var g in data['genres']) g['id']: g['name'],
    };
  }

  /// SEARCH BY TITLE
  Future<List<Movie>> searchMovies(String query) async {
    final uri = Uri.parse(
      '${TmdbConfig.baseUrl}/search/movie'
      '?api_key=${TmdbConfig.apiKey}&query=$query',
    );

    final response = await http.get(uri);
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

  final uri = Uri.parse('${TmdbConfig.baseUrl}/discover/movie')
      .replace(queryParameters: params);

  final response = await http.get(uri);
  final data = json.decode(response.body);

  return (data['results'] as List)
      .map((e) => Movie.fromJson(e))
      .toList();
}

//actors

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

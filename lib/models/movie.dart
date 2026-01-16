class Movie {
  final int id;
  final String title;
  final String overview;
  final String posterPath;
  final String releaseDate;
  final double rating;
  final List<int> genreIds;

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.releaseDate,
    required this.rating,
    required this.genreIds,

  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'] ?? '',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'] ?? '',
      releaseDate: json['release_date'] ?? '',
      rating: (json['vote_average'] ?? 0).toDouble(),
      genreIds: List<int>.from(json['genre_ids'] ?? []),

    );
  }
}

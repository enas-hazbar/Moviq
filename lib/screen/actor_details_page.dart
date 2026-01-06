import 'package:flutter/material.dart';
import '../services/tmdb_service.dart';
import '../config/tmdb_config.dart';
import 'movie_details_page.dart';

class ActorDetailsPage extends StatefulWidget {
  final int personId;

  const ActorDetailsPage({super.key, required this.personId});

  @override
  State<ActorDetailsPage> createState() => _ActorDetailsPageState();
}

class _ActorDetailsPageState extends State<ActorDetailsPage> {
  final TmdbService _service = TmdbService();

  late Future<Map<String, dynamic>> _actor;
  late Future<List<Map<String, dynamic>>> _movies;

  bool _expandedBio = false;

  @override
  void initState() {
    super.initState();
    _actor = _service.getPersonDetails(widget.personId);
    _movies = _service.getPersonMovieCredits(widget.personId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Actor')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _actor,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final actor = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// PROFILE IMAGE
                Center(
                  child: CircleAvatar(
                    radius: 70,
                    backgroundImage: actor['profile_path'] != null
                        ? NetworkImage(
                            TmdbConfig.imageBaseUrl + actor['profile_path'],
                          )
                        : null,
                  ),
                ),

                const SizedBox(height: 16),

                /// NAME
                Text(
                  actor['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                /// BIRTHDAY + PLACE
                Text(
                  'Born: ${actor['birthday'] ?? 'Unknown'}'
                  '${actor['place_of_birth'] != null ? ' • ${actor['place_of_birth']}' : ''}',
                  style: const TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 16),

                /// BIOGRAPHY (COLLAPSIBLE)
                _buildBiography(actor['biography'] ?? ''),

                const SizedBox(height: 24),

                /// MOVIES & ROLES
                const Text(
                  'Movies & Roles',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _movies,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();

                    final movies = snapshot.data!;

                    return SizedBox(
                      height: 240,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: movies.length,
                        itemBuilder: (context, index) {
                          final movie = movies[index];

                          if (movie['poster_path'] == null) {
                            return const SizedBox();
                          }

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MovieDetailsPage(
                                    movieId: movie['id'],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 140,
                              margin: const EdgeInsets.only(right: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// POSTER + FAVORITE HEART
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            TmdbConfig.imageBaseUrl +
                                                (movie['poster_path'] ?? ''),
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              color: Colors.white12,
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                Icons.movie_outlined,
                                                color: Colors.white38,
                                                size: 50,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 6,
                                          right: 6,
                                          child: FavoriteHeart(
                                            movieId: movie['id'],
                                            posterPath: movie['poster_path'] ?? '',
                                            width: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  /// TITLE
                                  Text(
                                    movie['title'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),

                                  /// CHARACTER
                                  Text(
                                    'as ${movie['character'] ?? ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 📖 COLLAPSIBLE BIOGRAPHY
  Widget _buildBiography(String bio) {
    if (bio.isEmpty) {
      return const Text(
        'No biography available.',
        style: TextStyle(color: Colors.white70),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          firstChild: Stack(
            children: [
              Text(
                bio,
                maxLines: 4,
                overflow: TextOverflow.fade,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 40,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          secondChild: Text(
            bio,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          crossFadeState: _expandedBio
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),

        const SizedBox(height: 6),

        GestureDetector(
          onTap: () {
            setState(() {
              _expandedBio = !_expandedBio;
            });
          },
          child: Text(
            _expandedBio ? 'Read less' : 'Read more',
            style: const TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}


import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'home.dart';

void main() {
  runApp(const Viewsongs());
}

class Viewsongs extends StatefulWidget {
  const Viewsongs({super.key});

  @override
  _ViewsongsState createState() => _ViewsongsState();
}

class _ViewsongsState extends State<Viewsongs> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ALL Songs')),
      backgroundColor: const Color(0xFF121212),
      body: const MusicPlayerView(),
    );
  }
}

class Song {
  final int id;
  final String sname;
  final String duration;
  final String emotion;
  final String songUrl;
  final String? simage;

  Song({
    required this.id,
    required this.sname,
    required this.duration,
    required this.emotion,
    required this.songUrl,
    this.simage,
  });

  factory Song.fromJson(Map<String, dynamic> json, String baseUrl) {
    String processUrl(String? url) {
      if (url == null || url.isEmpty) return '';
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return url;
      }
      return url.startsWith('/') ? baseUrl + url.substring(1) : baseUrl + url;
    }

    return Song(
      id: json['id'] ?? 0,
      sname: json['sname'] ?? 'Unknown',
      duration: json['duration'] ?? '0:00',
      emotion: json['emotion'] ?? 'Unknown',
      songUrl: processUrl(json['song']),
      simage: processUrl(json['simage']),
    );
  }
}

class MusicPlayerView extends StatefulWidget {
  const MusicPlayerView({Key? key}) : super(key: key);

  @override
  _MusicPlayerViewState createState() => _MusicPlayerViewState();
}

class _MusicPlayerViewState extends State<MusicPlayerView> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Song> songs = [];
  int currentIndex = -1;
  bool isPlaying = false;
  bool isLoading = true;
  String error = '';
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool isExpanded = false;
  bool isLiked = false;




  // Track listeners to cancel them
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _completionSubscription;

  Map<String, bool> likedSongs = {};


  @override
  void initState() {
    super.initState();
    _initializePlayer();
    fetchSongs();
  }

  void _initializePlayer() {
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state == PlayerState.playing;
        });
      }
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });

    _completionSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      nextSong();
    });
  }

  Future<void> fetchSongs() async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String baseUrl = sh.getString('url') ?? '';

      if (baseUrl.isEmpty) {
        throw Exception('Base URL not found in SharedPreferences');
      }

      if (!baseUrl.endsWith('/')) {
        baseUrl += '/';
      }

      final response = await http.get(Uri.parse("${baseUrl}play_song")).timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw TimeoutException('Connection timed out'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['data'] != null) {
          final List<dynamic> songsData = responseData['data'];
          if (mounted) {
            setState(() {
              songs = songsData.map((songData) => Song.fromJson(songData, baseUrl)).toList();
              isLoading = false;
            });
          }
        } else {
          throw Exception('No songs data in response');
        }
      } else {
        throw Exception('Failed to load songs: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<void> playSong(int index) async {
    if (index < 0 || index >= songs.length) return;

    try {
      final song = songs[index];
      await _audioPlayer.stop();
      await _audioPlayer.setSourceUrl(song.songUrl);
      await _audioPlayer.resume();

      if (mounted) {
        setState(() {
          currentIndex = index;
          isPlaying = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Error playing song: ${e.toString()}';
          isPlaying = false;
        });
      }
    }
  }

  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
    if (mounted) {
      setState(() {
        isPlaying = !isPlaying;
      });
    }
  }

  void nextSong() {
    if (currentIndex < songs.length - 1) {
      playSong(currentIndex + 1);
    }
  }

  void previousSong() {
    if (currentIndex > 0) {
      playSong(currentIndex - 1);
    }
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _completionSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMainContent(),
          if (currentIndex != -1 && !isExpanded) _buildMiniPlayer(),
          if (currentIndex != -1 && isExpanded) _buildExpandedPlayer(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error.isNotEmpty) {
      return Center(
        child: Text(
          error,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          title: const Text('ALL SONGS'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white), // Use Icons.home for a home icon
            onPressed: () {
              // Navigator.pop(context); // Use this to go back
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Homepage()));
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: fetchSongs,
            ),
          ],
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final song = songs[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: song.simage != null
                      ? Image.network(
                    song.simage!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.music_note, size: 50),
                  )
                      : const Icon(Icons.music_note, size: 50),
                ),
                title: Text(
                  song.sname,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  song.emotion,
                  style: TextStyle(color: Colors.grey[400]),
                ),
                trailing: Text(
                  song.duration,
                  style: TextStyle(color: Colors.grey[400]),
                ),
                onTap: () => playSong(index),
              );
            },
            childCount: songs.length,
          ),
        ),
        if (currentIndex != -1)
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
      ],
    );
  }


  Widget _buildMiniPlayer() {
    if (currentIndex == -1) return const SizedBox.shrink();
    final song = songs[currentIndex];

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () {
          setState(() {
            isExpanded = true;
          });
        },
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0.9),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            children: [
              if (song.simage != null)
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      song.simage!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                const SizedBox(
                  width: 60,
                  height: 60,
                  child: Icon(Icons.music_note, color: Colors.white),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        song.sname,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        song.emotion,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: Colors.white,
                  size: 36,
                ),
                onPressed: togglePlayPause,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedPlayer() {
    if (currentIndex == -1) return const SizedBox.shrink();
    final song = songs[currentIndex];

    return Container(
      color: const Color(0xFF282828),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down),
                    onPressed: () {
                      setState(() {
                        isExpanded = false;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'Now Playing',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                ],
              ),
            ),

            // Album Art
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: song.simage != null
                    ? Image.network(
                  song.simage!,
                  fit: BoxFit.cover,
                )
                    : const Icon(
                  Icons.music_note,
                  size: 200,
                  color: Colors.white,
                ),
              ),
            ),

            // Song Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.sname,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    song.emotion,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Slider(
                    value: _position.inSeconds.toDouble(),
                    min: 0,
                    max: _duration.inSeconds.toDouble(),
                    onChanged: (value) async {
                      await _audioPlayer.seek(Duration(seconds: value.toInt()));
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatDuration(_position),
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        Text(
                          formatDuration(_duration),
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Controls
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      likedSongs[song.id.toString()] == true ? Icons.favorite : Icons.favorite_outline,
                      color: likedSongs[song.id.toString()] == true ? const Color(0xFF1DB954) : Colors.white, // Spotify green when liked, bright white when not
                      size: 28, // Slightly larger icon
                    ),
                    splashColor: const Color(0xFF1DB954).withOpacity(0.3), // Spotify green splash
                    highlightColor: const Color(0xFF1DB954).withOpacity(0.1), // Subtle highlight
                    onPressed: () async {
                      SharedPreferences sh = await SharedPreferences.getInstance();
                      String url = sh.getString('url').toString();
                      String lid = sh.getString('lid').toString();
                      String sid = song.id.toString();
                      final urls = Uri.parse('$url/liked_song');

                      // Add haptic feedback for a more premium feel
                      HapticFeedback.lightImpact();

                      try {
                        final response = await http.post(urls, body: {
                          'lid': lid,
                          'sid': sid,
                        });
                        if (response.statusCode == 200) {
                          String status = jsonDecode(response.body)['status'];
                          bool isNowLiked = status == 'ok'; // true if added, false if removed

                          setState(() {
                            likedSongs[song.id.toString()] = isNowLiked;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(
                                      isNowLiked ? Icons.check_circle_outline : Icons.remove_circle_outline,
                                      color: isNowLiked ? Color(0xFF1DB954) : Colors.white70
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    isNowLiked ? "Added to Liked Songs" : "Removed from Liked Songs",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.black87,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Network Error",
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.black87,
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Error: ${e.toString()}",
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.black87,
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),

                  IconButton(
                    icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36),
                    onPressed: previousSong,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: togglePlayPause,
                      style: ElevatedButton.styleFrom(
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(16),
                        backgroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.black,
                        size: 40,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
                    onPressed: nextSong,
                  ),
                  IconButton(
                    icon: const Icon(Icons.repeat, color: Colors.white),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Repeat not implemented yet",
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.black87,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'home.dart';

class EmotionalMusicApp extends StatelessWidget {
  const EmotionalMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emotion Music',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.purple,
        colorScheme: const ColorScheme.dark(
          primary: Colors.purple,
          secondary: Colors.pinkAccent,
          surface: Color(0xFF1E1E1E),
          background: Color(0xFF121212),
        ),
        scaffoldBackgroundColor: const Color(0xff1d6008),
        cardTheme: CardTheme(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 8,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFF1E1E1E),
          centerTitle: true,
        ),
        textTheme: const TextTheme(
          headline6: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600),
          bodyText1: TextStyle(
              color: Colors.white),
          bodyText2: TextStyle(
              color: Colors.white),
        ),
      ),
      home: const EmotionalMusicPage(title: 'Emotion Music'),
    );
  }
}

class EmotionalMusicPage extends StatefulWidget {
  const EmotionalMusicPage({super.key, required this.title});

  final String title;

  @override
  State<EmotionalMusicPage> createState() => _EmotionalMusicPageState();
}

class _EmotionalMusicPageState extends State<EmotionalMusicPage>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Playlist> playlists = [];
  List<Song> currentPlaylistSongs = [];

  // Animation controller for expanded player
  late AnimationController _playerExpandController;
  late Animation<double> _playerAnimation;
  bool _isPlayerExpanded = false;

  // Player state
  Song? currentSong;
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  double playbackProgress = 0.0;
  String emotion = "";
  List<String> songIds = <String>[];
  List<String> songNames = <String>[];
  List<String> ownerNames = <String>[];
  List<String> imgfile = <String>[];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _playerExpandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _playerAnimation = CurvedAnimation(
      parent: _playerExpandController,
      curve: Curves.easeInOut,
    );

    fetchSongs();

    // Add listeners to track audio player state
    _audioPlayer.onDurationChanged.listen((newDuration) {
      setState(() {
        duration = newDuration;
      });
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      setState(() {
        position = newPosition;
        if (duration.inMilliseconds > 0) {
          playbackProgress = position.inMilliseconds / duration.inMilliseconds;
        }
      });
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        isPlaying = state == PlayerState.playing;
      });
    });

    // Add listener for player completion
    _audioPlayer.onPlayerComplete.listen((event) {
      _playNextSong();
    });
  }

  void _toggleExpandedPlayer() {
    setState(() {
      _isPlayerExpanded = !_isPlayerExpanded;
      if (_isPlayerExpanded) {
        _playerExpandController.forward();
      } else {
        _playerExpandController.reverse();
      }
    });
  }

  void _playNextSong() {
    if (currentSong != null && songIds.isNotEmpty) {
      int currentIndex = songIds.indexWhere((id) => id == currentSong!.id.toString());
      if (currentIndex != -1 && currentIndex < songIds.length - 1) {
        int nextIndex = currentIndex + 1;
        Song nextSong = Song(
          id: int.parse(songIds[nextIndex]),
          name: songNames[nextIndex],
          duration: '0:00',
          emotion: emotion,
          image: ownerNames[nextIndex],
          songUrl: imgfile[nextIndex],
        );
        playSong(nextSong);
      }
    }
  }

  void _playPreviousSong() {
    if (currentSong != null && songIds.isNotEmpty) {
      int currentIndex = songIds.indexWhere((id) => id == currentSong!.id.toString());
      if (currentIndex > 0) {
        int prevIndex = currentIndex - 1;
        Song prevSong = Song(
          id: int.parse(songIds[prevIndex]),
          name: songNames[prevIndex],
          duration: '0:00',
          emotion: emotion,
          image: ownerNames[prevIndex],
          songUrl: imgfile[prevIndex],
        );
        playSong(prevSong);
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  Future<void> playSong(Song song) async {
    try {
      final pref = await SharedPreferences.getInstance();
      String? baseUrl = pref.getString("url");
      if (baseUrl == null) return;

      setState(() {
        currentSong = song;
        isPlaying = true;
      });

      await _audioPlayer.stop();
      await _audioPlayer.setSourceUrl(
          song.songUrl.startsWith('http')
              ? song.songUrl
              : baseUrl + (song.songUrl.startsWith('/') ? song.songUrl.substring(1) : song.songUrl)
      );
      await _audioPlayer.resume();
    } catch (e) {
      print('Error playing song: $e');
    }
  }

  Future<void> fetchSongs() async {
    setState(() {
      isLoading = true;
    });

    try {
      final pref = await SharedPreferences.getInstance();
      String ip = pref.getString("url") ?? "";
      emotion = pref.getString("emotion") ?? "Unknown";

      String url = ip + "viewplaylist_emo";
      print("Fetching data from: $url");

      var response = await http.post(
          Uri.parse(url),
          body: {"emotion": emotion}
      );

      var jsonData = json.decode(response.body);
      String status = jsonData['status'];
      var songs = jsonData["data"];

      List<String> ids = [];
      List<String> names = [];
      List<String> owners = [];
      List<String> imgfilee = [];

      for (int i = 0; i < songs.length; i++) {
        ids.add(songs[i]['id'].toString());
        names.add(songs[i]['song'].toString());
        owners.add(ip + songs[i]['simage'].toString());
        imgfilee.add(ip + songs[i]['song_f'].toString());
      }

      setState(() {
        songIds = ids;
        songNames = names;
        ownerNames = owners;
        imgfile = imgfilee;
        isLoading = false;
      });

      print("Songs loaded: ${songIds.length}");
    } catch (e) {
      print("Error fetching songs: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _playerExpandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Color(0xff1d6008),
        title: Text(
          emotion.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchSongs,
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Homepage(),)),
        ),
      ),
      body: Stack(
        children: [
          // Main content
          isLoading
              ? const Center(
            child: CircularProgressIndicator(
              color: Colors.green,
            ),
          )
              : songIds.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.music_off,
                  size: 80,
                  color: Colors.grey.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  "No songs found for '$emotion'",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          )
              : CustomScrollView(
            slivers: [
              // Playlist header
              SliverToBoxAdapter(
                child: Container(
                  color: const Color(0xFF121212),
                  child: Column(
                    children: [
                      // Cover image
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              'https://picsum.photos/seed/$emotion/500/300',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade800,
                                  child: const Icon(Icons.music_note, color: Colors.white, size: 80),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      // Playlist info
                      Padding(
                        padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              emotion.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${songIds.length} songs',
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                if (songIds.isNotEmpty) {
                                  Song song = Song(
                                    id: int.parse(songIds[0]),
                                    name: songNames[0],
                                    duration: '0:00',
                                    emotion: emotion,
                                    image: ownerNames[0],
                                    songUrl: imgfile[0],
                                  );
                                  playSong(song);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              ),
                              child: const Text(
                                "PLAY",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(color: Color(0xFF2A2A2A), height: 1),
                    ],
                  ),
                ),
              ),
              // SliverList(
              //   delegate: SliverChildBuilderDelegate(
              //         (context, index) {
              //       return ListTile(
              //         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              //         leading: ClipRRect(
              //           borderRadius: BorderRadius.circular(4),
              //           child: SizedBox(
              //             width: 48,
              //             height: 48,
              //             child: Image.network(
              //               ownerNames[index],
              //               fit: BoxFit.cover,
              //               errorBuilder: (context, error, stackTrace) {
              //                 return Container(
              //                   color: Colors.grey.shade800,
              //                   child: const Icon(Icons.music_note, color: Colors.white, size: 24),
              //                 );
              //               },
              //             ),
              //           ),
              //         ),
              //         title: Text(
              //           songNames[index],
              //           style: const TextStyle(
              //             color: Colors.white,
              //             fontWeight: FontWeight.w500,
              //           ),
              //         ),
              //         // subtitle: Text(
              //         //   duration[],
              //         //   style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              //         // ),
              //         trailing: const Icon(
              //           Icons.play_circle_filled,
              //           color: Colors.green,
              //         ),
              //         onTap: () {
              //           Song song = Song(
              //             id: int.parse(songIds[index]),
              //             name: songNames[index],
              //             duration: '0:00',
              //             emotion: emotion,
              //             image: ownerNames[index],
              //             songUrl: imgfile[index],
              //           );
              //           playSong(song);
              //         },
              //       );
              //     },
              //     childCount: songIds.length,
              //   ),
              // ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        onTap: () {
                          Song song = Song(
                            id: int.parse(songIds[index]),
                            name: songNames[index],
                            duration: '0:00',
                            emotion: emotion,
                            image: ownerNames[index],
                            songUrl: imgfile[index],
                          );
                          playSong(song);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              // Column 1: Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Image.network(
                                    ownerNames[index],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade800,
                                        child: const Icon(Icons.music_note, color: Colors.white, size: 24),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16), // Spacing between columns
                              // Column 2: Song Name
                              Expanded(
                                child: Text(
                                  songNames[index],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 16), // Spacing between columns
                              // Column 3: Play Button
                              const Icon(
                                Icons.play_circle_filled,
                                color: Colors.green,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: songIds.length,
                ),
              ),
            ],
          ),

          // Mini Player
          // Mini Player (Spotify Theme)
          if (currentSong != null && !_isPlayerExpanded)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: _toggleExpandedPlayer,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF282828),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Column(
                    children: [
                      // Progress bar at the top
                      LinearProgressIndicator(
                        value: playbackProgress,
                        backgroundColor: Colors.grey.shade800,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
                        minHeight: 2,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Album art
                          Hero(
                            tag: 'album-art',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                currentSong!.image ?? '',
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 48,
                                    height: 48,
                                    color: Colors.grey.shade800,
                                    child: const Icon(Icons.music_note, color: Colors.white, size: 24),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Song details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentSong!.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentSong!.emotion,
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Control buttons
                          Row(
                            children: [
                              // Like button

                              // Play/pause button
                              IconButton(
                                iconSize: 32,
                                icon: Icon(
                                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                  color: Colors.white,
                                ),
                                onPressed: () async {
                                  if (isPlaying) {
                                    await _audioPlayer.pause();
                                  } else {
                                    await _audioPlayer.resume();
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

// Extended Player (Spotify Theme)
          if (currentSong != null && _isPlayerExpanded)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: 0,
              left: 0,
              right: 0,
              top: 0,
              child: Container(
                color: const Color(0xFF121212),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Header with down arrow and options
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_down),
                              color: Colors.white,
                              onPressed: _toggleExpandedPlayer,
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  'NOW PLAYING',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_down),
                              color: Colors.white,
                              onPressed: _toggleExpandedPlayer,
                            ),
                          ],
                        ),
                      ),                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                          child: Hero(
                            tag: 'album-art',
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  currentSong!.image ?? '',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade800,
                                      child: const Icon(Icons.music_note, color: Colors.white, size: 80),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Player controls section
                      Expanded(
                        flex: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Song title and emotion
                              Column(
                                children: [
                                  Text(
                                    currentSong!.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    currentSong!.emotion,
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              // Progress bar with times
                              Column(
                                children: [
                                  Slider(
                                    value: playbackProgress,
                                    onChanged: (value) async {
                                      final newPosition = duration * value;
                                      await _audioPlayer.seek(newPosition);
                                    },
                                    activeColor: const Color(0xFF1DB954),
                                    inactiveColor: Colors.grey.shade800,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDuration(position),
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          _formatDuration(duration),
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Playback controls
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  // IconButton(
                                  //   icon: const Icon(Icons.shuffle),
                                  //   color: Colors.grey.shade400,
                                  //   iconSize: 24,
                                  //   onPressed: () {},
                                  // ),
                                  IconButton(
                                    icon: const Icon(Icons.skip_previous),
                                    iconSize: 40,
                                    color: Colors.white,
                                    onPressed: _playPreviousSong,
                                  ),
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF1DB954).withOpacity(0.5),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        isPlaying ? Icons.pause : Icons.play_arrow,
                                        size: 38,
                                        color: Colors.black,
                                      ),
                                      onPressed: () async {
                                        if (isPlaying) {
                                          await _audioPlayer.pause();
                                        } else {
                                          await _audioPlayer.resume();
                                        }
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.skip_next),
                                    iconSize: 40,
                                    color: Colors.white,
                                    onPressed: _playNextSong,
                                  ),
                                  // IconButton(
                                  //   icon: const Icon(Icons.repeat),
                                  //   color: Colors.grey.shade400,
                                  //   iconSize: 24,
                                  //   onPressed: () {},
                                  // ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Playlist {
  final String id;
  final String name;
  final String emotion;
  final List<Song> songs;

  const Playlist({
    required this.id,
    required this.name,
    required this.emotion,
    required this.songs,
  });
}

class Song {
  final int id;
  final String name;
  final String duration;
  final String emotion;
  final String? image;
  final String songUrl;

  Song({
    required this.id,
    required this.name,
    required this.duration,
    required this.emotion,
    this.image,
    required this.songUrl,
  });
}
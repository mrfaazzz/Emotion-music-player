import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ViewPlay1 extends StatefulWidget {
  final String pid;
  final String pname;

  const ViewPlay1({
    Key? key,
    required this.pid,
    required this.pname,
  }) : super(key: key);

  @override
  State<ViewPlay1> createState() => _ViewPlay1State();
}

class _ViewPlay1State extends State<ViewPlay1> with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Song> songs = [];

  // Player state
  Song? currentSong;
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  // UI state
  bool isLoading = true;
  bool isExpandedPlayerVisible = false;
  late AnimationController _animationController;
  late Animation<double> _playerAnimation;

  // Subscriptions
  late StreamSubscription _playerStateSubscription;
  late StreamSubscription _positionSubscription;
  late StreamSubscription _durationSubscription;
  late StreamSubscription _completionSubscription;
  final ValueNotifier<Duration> _positionNotifier = ValueNotifier(Duration.zero);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initPlayer();
    fetchPlaylistSongs();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _playerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _initPlayer() {
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => isPlaying = state == PlayerState.playing);
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        _positionNotifier.value = newPosition;
        setState(() => position = newPosition);
      }
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) setState(() => duration = newDuration);
    });

    _completionSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      playNextSong();
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _playerStateSubscription.cancel();
    _positionSubscription.cancel();
    _durationSubscription.cancel();
    _completionSubscription.cancel();
    _positionNotifier.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchPlaylistSongs() async {
    try {
      setState(() => isLoading = true);
      final pref = await SharedPreferences.getInstance();
      String? baseUrl = pref.getString("url");

      if (baseUrl == null) {
        setState(() => isLoading = false);
        return;
      }

      if (!baseUrl.endsWith('/')) baseUrl += '/';

      final response = await http.post(
        Uri.parse(baseUrl + "view_playlistapp_details"),
        body: {'pid': widget.pid},
      );

      final jsonData = json.decode(response.body);

      if (jsonData["status"] == "ok") {
        List<Song> fetchedSongs = (jsonData["data"] as List)
            .map((item) => Song.fromJson(item, baseUrl!))
            .toList();

        setState(() {
          songs = fetchedSongs;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching songs: $e');
      setState(() => isLoading = false);
    }
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

  void togglePlayPause() {
    if (currentSong == null) return;
    setState(() => isPlaying = !isPlaying);
    isPlaying ? _audioPlayer.resume() : _audioPlayer.pause();
  }

  void playNextSong() {
    if (currentSong == null || songs.isEmpty) return;

    final currentIndex = songs.indexWhere((s) => s.id == currentSong!.id);
    if (currentIndex != -1 && currentIndex < songs.length - 1) {
      playSong(songs[currentIndex + 1]);
    } else if (songs.isNotEmpty) {
      // Loop to first song
      playSong(songs[0]);
    }
  }

  void playPreviousSong() {
    if (currentSong == null || songs.isEmpty) return;

    final currentIndex = songs.indexWhere((s) => s.id == currentSong!.id);
    if (currentIndex > 0) {
      playSong(songs[currentIndex - 1]);
    } else if (songs.isNotEmpty) {
      // Loop to last song
      playSong(songs[songs.length - 1]);
    }
  }

  void toggleExpandedPlayer() {
    setState(() {
      isExpandedPlayerVisible = !isExpandedPlayerVisible;
      if (isExpandedPlayerVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: isExpandedPlayerVisible
          ? null
          : AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(widget.pname),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Main playlist content
          Column(
            children: [
              Expanded(
                child: isLoading
                    ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                  ),
                )
                    : _buildPlaylistDetail(),
              ),
              // Mini player
              if (currentSong != null && !isExpandedPlayerVisible)
                _buildMiniPlayer(),
            ],
          ),

          // Expanded player overlay
          if (currentSong != null)
            AnimatedBuilder(
              animation: _playerAnimation,
              builder: (context, child) {
                final value = _playerAnimation.value;
                if (value <= 0) return const SizedBox.shrink();

                return Positioned.fill(
                  child: GestureDetector(
                    onVerticalDragEnd: (details) {
                      if (details.primaryVelocity! > 300) {
                        toggleExpandedPlayer();
                      }
                    },
                    child: Transform.translate(
                      offset: Offset(0, MediaQuery.of(context).size.height * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: _buildExpandedPlayer(),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return GestureDetector(
      onTap: toggleExpandedPlayer,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF282828),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Song thumbnail
            Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: currentSong?.image != null
                  ? Image.network(
                currentSong!.image!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade800,
                    child: const Icon(Icons.music_note, color: Colors.white, size: 24),
                  );
                },
              )
                  : Container(
                color: Colors.grey.shade800,
                child: const Icon(Icons.music_note, color: Colors.white, size: 24),
              ),
            ),

            // Song info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      currentSong!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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
            ),

            // Controls
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: togglePlayPause,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.white, size: 28),
                  onPressed: playNextSong,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistDetail() {
    return CustomScrollView(
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
                    child: songs.isNotEmpty && songs[0].image != null
                        ? Image.network(
                      songs[0].image!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade800,
                          child: const Icon(Icons.music_note, color: Colors.white, size: 80),
                        );
                      },
                    )
                        : Container(
                      color: Colors.grey.shade800,
                      child: const Icon(Icons.music_note, color: Colors.white, size: 80),
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
                        widget.pname,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${songs.length} songs',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              if (songs.isNotEmpty) {
                                playSong(songs[0]);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
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
                    ],
                  ),
                ),

                const Divider(color: Color(0xFF2A2A2A), height: 1),
              ],
            ),
          ),
        ),

        // Song list
        SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final song = songs[index];
              final isCurrentSong = currentSong != null && currentSong!.id == song.id;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: song.image != null
                        ? Image.network(
                      song.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade800,
                          child: const Icon(Icons.music_note, color: Colors.white, size: 24),
                        );
                      },
                    )
                        : Container(
                      color: Colors.grey.shade800,
                      child: const Icon(Icons.music_note, color: Colors.white, size: 24),
                    ),
                  ),
                ),
                title: Text(
                  song.name,
                  style: TextStyle(
                    color: isCurrentSong ? Colors.green.shade400 : Colors.white,
                    fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  song.emotion,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
                trailing: Text(
                  song.duration,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
                onTap: () => playSong(song),
              );
            },
            childCount: songs.length,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedPlayer() {
    if (currentSong == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Blurred Background
          Positioned.fill(
            child: currentSong?.image != null
                ? Image.network(
              currentSong!.image!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
            )
                : Container(color: Colors.black),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30), // Blur effect
              child: Container(color: Colors.black.withOpacity(0.7)), // Dark overlay
            ),
          ),

          Column(
            children: [
              const SizedBox(height: 40),

              // AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
                      onPressed: toggleExpandedPlayer,
                    ),
                    const Text(
                      "Now Playing",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
                      onPressed: toggleExpandedPlayer,
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // Album Art - Centered with increased height
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 340,
                    height: 340,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: currentSong?.image != null
                        ? Image.network(
                      currentSong!.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade800,
                          child: const Icon(Icons.music_note, color: Colors.white, size: 100),
                        );
                      },
                    )
                        : Container(
                      color: Colors.grey.shade800,
                      child: const Icon(Icons.music_note, color: Colors.white, size: 100),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 1),

              // Song info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      currentSong!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentSong!.emotion,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        activeTrackColor: Colors.green.shade400,
                        inactiveTrackColor: Colors.grey.shade700,
                        thumbColor: Colors.white,
                        overlayColor: Colors.white.withOpacity(0.2),
                      ),
                      child: Slider(
                        value: position.inSeconds.toDouble().clamp(0, duration.inSeconds.toDouble() > 0
                            ? duration.inSeconds.toDouble() : 1),
                        min: 0,
                        max: duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1,
                        onChanged: (value) {
                          _audioPlayer.seek(Duration(seconds: value.toInt()));
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatDuration(position),
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                        Text(
                          formatDuration(duration),
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Playback Controls
              Padding(
                padding: const EdgeInsets.only(bottom: 50.0, top: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36),
                      onPressed: playPreviousSong,
                    ),
                    const SizedBox(width: 40),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.shade600.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 48,
                        ),
                        onPressed: togglePlayPause,
                      ),
                    ),
                    const SizedBox(width: 40),
                    IconButton(
                      icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
                      onPressed: playNextSong,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
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

  factory Song.fromJson(Map<String, dynamic> json, String baseUrl) {
    String processUrl(String? url) {
      if (url == null || url.isEmpty) return '';
      if (url.startsWith('http')) return url;
      return baseUrl + (url.startsWith('/') ? url.substring(1) : url);
    }

    return Song(
      id: int.parse(json['id'].toString()),
      name: json['sname'].toString(),
      duration: json['duration']?.toString() ?? '0:00',
      emotion: json['emotion'].toString(),
      image: processUrl(json['simage']),
      songUrl: processUrl(json['song'] ?? ''),
    );
  }
}


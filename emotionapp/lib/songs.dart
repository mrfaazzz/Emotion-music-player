import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: managesong(),
  ));
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

class managesong extends StatefulWidget {
  const managesong({super.key});

  @override
  State<managesong> createState() => _managesongState();
}

class _managesongState extends State<managesong> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Playlist> playlists = [];
  List<Song> currentPlaylistSongs = [];

  // Player state
  Song? currentSong;
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  double playbackProgress = 0.0;

  // UI state
  bool isLoading = true;
  bool isSearching = false;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Playlist? selectedPlaylist;
  bool isExpandedPlayerVisible = false;

  // Subscriptions
  late StreamSubscription _playerStateSubscription;
  late StreamSubscription _positionSubscription;
  late StreamSubscription _durationSubscription;
  late StreamSubscription _completionSubscription;

  @override
  void initState() {
    super.initState();
    _initPlayer();
    fetchPlaylists();
    _searchController.addListener(() {
      setState(() => searchQuery = _searchController.text);
    });
  }

  void _initPlayer() {
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => isPlaying = state == PlayerState.playing);
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) setState(() => position = newPosition);
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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchPlaylists() async {
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
        Uri.parse(baseUrl + "view_playlistapp"),
        body: {'lid': pref.getString("lid") ?? ""},
      );

      final jsonData = json.decode(response.body);
      if (jsonData["status"] == "ok") {
        List<Playlist> tempPlaylists = (jsonData["data"] as List).map((item) {
          List<Song> songs = item['songs'] != null
              ? (item['songs'] as List)
              .map((songItem) => Song.fromJson(songItem, baseUrl!))
              .toList()
              : [Song.fromJson(item, baseUrl!)];

          return Playlist(
            id: item['id'].toString(),
            name: item['pname'].toString(),
            emotion: item['emotion'].toString(),
            songs: songs,
          );
        }).toList();

        setState(() {
          playlists = tempPlaylists;
          isLoading = false;
          selectedPlaylist = null;
          currentPlaylistSongs = [];
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchPlaylistSongs(String playlistId) async {
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
        body: {'pid': playlistId},
      );

      final jsonData = json.decode(response.body);
      if (jsonData["status"] == "ok") {
        List<Song> fetchedSongs = (jsonData["data"] as List)
            .map((item) => Song.fromJson(item, baseUrl!))
            .toList();

        // Find the selected playlist
        final selected = playlists.firstWhere(
              (playlist) => playlist.id == playlistId,
          orElse: () => playlists.first,
        );

        setState(() {
          currentPlaylistSongs = fetchedSongs;
          selectedPlaylist = selected;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
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
    if (currentSong == null || currentPlaylistSongs.isEmpty) return;

    final currentIndex = currentPlaylistSongs.indexWhere((s) => s.id == currentSong!.id);
    if (currentIndex != -1 && currentIndex < currentPlaylistSongs.length - 1) {
      playSong(currentPlaylistSongs[currentIndex + 1]);
    } else if (currentPlaylistSongs.isNotEmpty) {
      // Loop to first song
      playSong(currentPlaylistSongs[0]);
    }
  }





  void playPreviousSong() {
    if (currentSong == null || currentPlaylistSongs.isEmpty) return;

    final currentIndex = currentPlaylistSongs.indexWhere((s) => s.id == currentSong!.id);
    if (currentIndex > 0) {
      playSong(currentPlaylistSongs[currentIndex - 1]);
    } else if (currentPlaylistSongs.isNotEmpty) {
      // Loop to last song
      playSong(currentPlaylistSongs[currentPlaylistSongs.length - 1]);
    }
  }

  void goBackToPlaylists() {
    setState(() {
      selectedPlaylist = null;
      currentPlaylistSongs = [];
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
    final filteredPlaylists = playlists
        .where((playlist) =>
        playlist.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    // Show expanded player if visible
    if (isExpandedPlayerVisible && currentSong != null) {
      return _buildExpandedPlayer();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: selectedPlaylist != null
            ? Text(selectedPlaylist!.name)
            : (isSearching
            ? TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search playlists...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white),
          autofocus: true,
        )
            : const Text('Playlist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        leading: selectedPlaylist != null
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: goBackToPlaylists,
        )
            : null,
        actions: [
          if (selectedPlaylist == null)
            IconButton(
              icon: Icon(isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  if (isSearching) {
                    _searchController.clear();
                    searchQuery = '';
                  }
                  isSearching = !isSearching;
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: selectedPlaylist != null
                  ? () => fetchPlaylistSongs(selectedPlaylist!.id)
                  : fetchPlaylists,
              child: isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                ),
              )
                  : selectedPlaylist == null
                  ? _buildPlaylistGrid(filteredPlaylists)
                  : _buildPlaylistDetail(),
            ),
          ),
          if (currentSong != null) _buildMiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildPlaylistGrid(List<Playlist> playlists) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return GestureDetector(
          onTap: () => fetchPlaylistSongs(playlist.id),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey.shade900,
                  const Color(0xFF121212),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Playlist cover image
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          playlist.songs.isNotEmpty && playlist.songs[0].image != null
                              ? Image.network(
                            playlist.songs[0].image!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade800,
                                child: const Icon(Icons.music_note, color: Colors.white, size: 50),
                              );
                            },
                          )
                              : Container(
                            color: Colors.grey.shade800,
                            child: const Icon(Icons.music_note, color: Colors.white, size: 50),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Play button
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, bottom: 8),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                // Playlist info
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${playlist.songs.length} songs • ${playlist.emotion}',
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
              ],
            ),
          ),
        );
      },
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
                    child: currentPlaylistSongs.isNotEmpty && currentPlaylistSongs[0].image != null
                        ? Image.network(
                      currentPlaylistSongs[0].image!,
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
                        selectedPlaylist!.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${currentPlaylistSongs.length} songs • ${selectedPlaylist!.emotion}',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              if (currentPlaylistSongs.isNotEmpty) {
                                playSong(currentPlaylistSongs[0]);
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
              final song = currentPlaylistSongs[index];
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
            childCount: currentPlaylistSongs.length,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniPlayer() {
    if (currentSong == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        setState(() {
          isExpandedPlayerVisible = true;
        });
      },
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress slider
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.grey.shade700,
                thumbColor: Colors.white,
                overlayColor: Colors.white.withOpacity(0.2),
              ),
              child: Slider(
                value: position.inSeconds.toDouble().clamp(0, duration.inSeconds.toDouble()),
                min: 0,
                max: duration.inSeconds.toDouble(),
                onChanged: (value) {
                  _audioPlayer.seek(Duration(seconds: value.toInt()));
                },
              ),
            ),
            // Player controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Song thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: currentSong?.image != null
                          ? Image.network(
                        currentSong!.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade700,
                            child: const Icon(Icons.music_note, color: Colors.white, size: 24),
                          );
                        },
                      )
                          : Container(
                        color: Colors.grey.shade700,
                        child: const Icon(Icons.music_note, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                  // Song info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentSong!.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
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
                        icon: const Icon(Icons.skip_previous, color: Colors.white),
                        onPressed: playPreviousSong,
                      ),
                      IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: Colors.white,
                          size: 36,
                        ),
                        onPressed: togglePlayPause,
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.white),
                        onPressed: playNextSong,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
              child: Container(color: Colors.black.withOpacity(0.3)), // Dark overlay
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
                      onPressed: () {
                        setState(() {
                          isExpandedPlayerVisible = false;
                        });
                      },
                    ),
                    const Text(
                      "Now Playing",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
                      onPressed: () {
                        setState(() {
                          isExpandedPlayerVisible = false;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Center the image in the available space
              const Spacer(flex: 1),

              // Album Art - Centered and with increased height
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 340,
                    height: 380, // Increased height from 340
                    decoration: BoxDecoration(boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ]),
                    child: currentSong?.image != null
                        ? Image.network(
                      currentSong!.image!,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      color: Colors.grey.shade800,
                      child: const Icon(Icons.music_note, color: Colors.white, size: 100),
                    ),
                  ),
                ),
              ),

              // Push controls to bottom while keeping image centered
              const Spacer(flex: 1),

              // Song info above slider
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
                padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 10.0),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.grey.shade700,
                        thumbColor: Colors.white,
                        overlayColor: Colors.white.withOpacity(0.2),
                      ),
                      child: Slider(
                        value: position.inSeconds.toDouble().clamp(0, duration.inSeconds.toDouble()),
                        min: 0,
                        max: duration.inSeconds.toDouble(),
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
                padding: const EdgeInsets.only(bottom: 50.0),
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
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.black,
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
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

  class Song {
    final int id;
    final String sname;
    final String duration;
    final String emotion;
    final String image;
    final String songUrl;
  
    Song({
      required this.id,
      required this.sname,
      required this.duration,
      required this.emotion,
      required this.image,
      required this.songUrl,
    });
  }
  
  class LikedSongsScreen extends StatefulWidget {
    const LikedSongsScreen({super.key});
  
    @override
    State<LikedSongsScreen> createState() => _LikedSongsScreenState();
  }
  
  class _LikedSongsScreenState extends State<LikedSongsScreen>
      with SingleTickerProviderStateMixin {
    final AudioPlayer _audioPlayer = AudioPlayer();
    List<Song> likedSongs = [];
  
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
  
      fetchLikedSongs();
  
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
  
    String _formatDuration(Duration duration) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final minutes = twoDigits(duration.inMinutes.remainder(60));
      final seconds = twoDigits(duration.inSeconds.remainder(60));
      return "$minutes:$seconds";
    }
  
    Future<void> fetchLikedSongs() async {
      setState(() {
        isLoading = true;
      });
  
      try {
        final pref = await SharedPreferences.getInstance();
        String ip = pref.getString("url") ?? "";
        String lid = pref.getString("lid") ?? "";
  
        if (ip.isEmpty || lid.isEmpty) {
          throw Exception("Missing server URL or login ID");
        }
  
        String url = "$ip/get_liked_songs";
        print("Fetching liked songs from: $url");
  
        var response = await http.post(
          Uri.parse(url),
          headers: {
            "Content-Type": "application/json",
          },
          body: json.encode({
            "lid": lid,
          }),
        );
  
        print("Response status: ${response.statusCode}");
        print("Response body: ${response.body}");
  
        if (response.statusCode == 200) {
          var jsonData = json.decode(response.body);
  
          if (jsonData.containsKey("liked_songs")) {
            List<dynamic> songs = jsonData["liked_songs"];
  
            List<Song> fetchedSongs = songs.map((song) => Song(
              id: song['id'],
              sname: song['sname'],
              duration: song['duration'],
              emotion: song['emotion'],
              image: song['simage'],
              songUrl: song['song'],
            )).toList();
  
            setState(() {
              likedSongs = fetchedSongs;
              isLoading = false;
            });
  
            print("Fetched ${likedSongs.length} liked songs");
          } else {
            print("Error: 'liked_songs' key not found in response.");
            setState(() {
              isLoading = false;
            });
          }
        } else {
          print("Error fetching liked songs: ${response.statusCode} - ${response.body}");
          setState(() {
            isLoading = false;
          });
        }
      } catch (e) {
        print("Exception while fetching liked songs: $e");
        setState(() {
          isLoading = false;
        });
  
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Could not fetch liked songs: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  
    Future<void> playSong(Song song) async {
      try {
        // First set the song as current before attempting to play
        setState(() {
          currentSong = song;
          isPlaying = true;
        });
  
        // Reset position and duration
        setState(() {
          position = Duration.zero;
          duration = Duration.zero;
          playbackProgress = 0.0;
        });
  
        // Stop any currently playing audio first
        await _audioPlayer.stop();
  
        // Ensure the URL is properly encoded
        String url = song.songUrl.trim();
        if (!url.startsWith('http')) {
          // If url doesn't start with http, use the base URL from your SharedPreferences
          final pref = await SharedPreferences.getInstance();
          String ip = pref.getString("url") ?? "";
          url = "$ip$url";
        }
  
        // Set the source and play
        await _audioPlayer.setSourceUrl(url);
        await _audioPlayer.resume();
  
        print('Playing song: ${song.sname} from URL: $url');
      } catch (e) {
        print('Error playing song: $e');
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Playback Error'),
            content: Text('Could not play "${song.sname}". Error: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  
    void _playNextSong() {
      if (currentSong != null && likedSongs.isNotEmpty) {
        int currentIndex = likedSongs.indexWhere((song) => song.id == currentSong!.id);
        if (currentIndex != -1 && currentIndex < likedSongs.length - 1) {
          playSong(likedSongs[currentIndex + 1]);
        }
      }
    }
  
    void _playPreviousSong() {
      if (currentSong != null && likedSongs.isNotEmpty) {
        int currentIndex = likedSongs.indexWhere((song) => song.id == currentSong!.id);
        if (currentIndex > 0) {
          playSong(likedSongs[currentIndex - 1]);
        }
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
          backgroundColor: const Color(0xff1d6008),
          title: const Text(
            "Liked Songs",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: fetchLikedSongs,
            ),
          ],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
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
                : likedSongs.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No liked songs found",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
                : CustomScrollView(
              slivers: [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final song = likedSongs[index];
                      final bool isCurrentSong = currentSong?.id == song.id;
  
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCurrentSong ? Colors.green.withOpacity(0.2) : Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: InkWell(
                          onTap: () {
                            playSong(song);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                // Album art
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: song.image != null && song.image!.isNotEmpty
                                        ? Image.network(
                                      song.image!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        print("Error loading image: $error");
                                        return Container(
                                          color: Colors.grey.shade800,
                                          child: const Icon(Icons.music_note, color: Colors.white, size: 24),
                                        );
                                      },
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          color: Colors.grey.shade800,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                        : Container(
                                      color: Colors.grey.shade800,
                                      child: const Icon(Icons.music_note, color: Colors.white, size: 24),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Song name
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        song.sname,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        song.emotion,
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Play button
                                Icon(
                                  isCurrentSong && isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                                  color: Colors.green,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: likedSongs.length,
                  ),
                ),
              ],
            ),

      if (currentSong != null && !_isPlayerExpanded)
      Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: GestureDetector(
          onTap: _toggleExpandedPlayer,
          child: Container(
          decoration: BoxDecoration(
          gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2A2A), Color(0xFF1a1a1a)],
          ),
          boxShadow: [
          BoxShadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 8,
          offset: const Offset(0, -2),
          ),
          ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
          children: [
          // Progress bar
          LinearProgressIndicator(
          value: playbackProgress,
          backgroundColor: Colors.grey.shade800,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          minHeight: 2,
          ),
          const SizedBox(height: 8),
          Row(
          children: [
          // Album art
          Hero(
          tag: 'album-art',
          child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: currentSong!.image != null && currentSong!.image!.isNotEmpty
          ? Image.network(
          currentSong!.image!,
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
          )
              : Container(
          width: 48,
          height: 48,
          color: Colors.grey.shade800,
          child: const Icon(Icons.music_note, color: Colors.white, size: 24),
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
          currentSong!.sname,
          style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
          currentSong!.emotion,
          style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          ),
          ],
          ),
          ),
          // Controls
          Row(
          children: [
          IconButton(
          icon: const Icon(Icons.skip_previous, color: Colors.white),
          onPressed: _playPreviousSong,
          ),
          IconButton(
          iconSize: 36,
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
          IconButton(
          icon: const Icon(Icons.skip_next, color: Colors.white),
          onPressed: _playNextSong,
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

// Expanded Player
      if (currentSong != null && _isPlayerExpanded)
      AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      bottom: 0,
      left: 0,
      right: 0,
      top: 0,
      child: Container(
      decoration: BoxDecoration(
      gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
      HSLColor.fromColor(const Color(0xFF2A2A2A)).withLightness(0.3).toColor(),
      const Color(0xFF121212),
      ],
      ),
      ),
      child: SafeArea(
      child: Column(
      children: [
      // Header with down arrow
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
      child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
      Text(
      "NOW PLAYING",
      style: TextStyle(
      color: Colors.green,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.5,
      ),
      ),
      ],
      ),
      ),
        IconButton(
          icon: const Icon(Icons.close),
          color: Colors.white,
          onPressed: _toggleExpandedPlayer,  // Changed to close the expanded player
        ),
      ],
      ),
      ),
      // Album art
      Expanded(
      flex: 5,
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
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
      child: currentSong!.image != null && currentSong!.image!.isNotEmpty
      ? Image.network(
      currentSong!.image!,
      fit: BoxFit.cover,
      width: double.infinity,
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
      ),
      ),
      ),
      // Player controls
      Expanded(
      flex: 4,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
      // Song title and artist
      Column(
      children: [
      Text(
      currentSong!.sname,
      style: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 22,
      ),
      textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      Text(
      currentSong!.emotion,
      style: TextStyle(
      color: Colors.white.withOpacity(0.7),
      fontSize: 16,
      ),
      textAlign: TextAlign.center,
      ),
      ],
      ),
      // Progress bar with time
      Column(
      children: [
      SliderTheme(
      data: SliderThemeData(
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
      activeTrackColor: const Color(0xFF1DB954),
      inactiveTrackColor: Colors.grey.shade800,
      thumbColor: Colors.white,
      overlayColor: const Color(0xFF1DB954).withOpacity(0.2),
      ),
      child: Slider(
      value: playbackProgress.clamp(0.0, 1.0),
      onChanged: (value) async {
      final newPosition = Duration(
      milliseconds: (value * duration.inMilliseconds).round(),
      );
      await _audioPlayer.seek(newPosition);
      },
      ),
      ),
      Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
      Text(
      _formatDuration(position),
      style: TextStyle(
      color: Colors.white.withOpacity(0.6),
      fontSize: 12,
      ),
      ),
      Text(
      _formatDuration(duration),
      style: TextStyle(
      color: Colors.white.withOpacity(0.6),
      fontSize: 12,
      ),
      ),
      ],
      ),
      ),
      ],
      ),
      // Controls
      Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [

      IconButton(
      iconSize: 34,
      icon: const Icon(
      Icons.skip_previous,
      color: Colors.white,
      ),
      onPressed: _playPreviousSong,
      ),
      Container(
      decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white,
      boxShadow: [
      BoxShadow(
      color: const Color(0xFF1DB954).withOpacity(0.5),
      blurRadius: 10,
      spreadRadius: 2,
      ),
      ],
      ),
      child: IconButton(
      iconSize: 50,
      icon: Icon(
      isPlaying ? Icons.pause : Icons.play_arrow,
      color: Colors.black,
      size: 30,
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
      iconSize: 34,
      icon: const Icon(
      Icons.skip_next,
      color: Colors.white,
      ),
      onPressed: _playNextSong,
      ),

      ],
      ),
      // Bottom row with additional controls
      Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
      ]
      ),
      );
    }
  }

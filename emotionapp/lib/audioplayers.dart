import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class PlaySongScreen extends StatefulWidget {
  final String id;
  final String name;
  final String image;
  final String emotion;
  final String songs;

  const PlaySongScreen({
    Key? key,
    required this.id,
    required this.name,
    required this.image,
    required this.emotion,
    required this.songs,
  }) : super(key: key);

  @override
  _PlaySongScreenState createState() => _PlaySongScreenState();
}

class _PlaySongScreenState extends State<PlaySongScreen> with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _animationController;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    // Setup player
    _audioPlayer.setSourceUrl(widget.id);

    // Listen for state changes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });

      if (_isPlaying) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    });

    // Listen for duration changes
    _audioPlayer.onDurationChanged.listen((newDuration) {
      setState(() {
        _duration = newDuration;
      });
    });

    // Listen for position changes
    _audioPlayer.onPositionChanged.listen((newPosition) {
      setState(() {
        _position = newPosition;
      });
    });
  }

  void _handleLikeUnlike(bool liked) {
    setState(() {
      _isLiked = liked;
    });

    // Show a confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(liked ? 'Added to favorites' : 'Removed from favorites'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'DISMISS',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return hours == '00' ? '$minutes:$seconds' : '$hours:$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [
              const Color(0xFF121212),
              const Color(0xFF1E1E1E),
            ]
                : [
              const Color(0xFFE0E0E0),
              const Color(0xFFF5F5F5),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Bar with back button and popup menu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'NOW PLAYING',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    // Popup menu
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                      onSelected: (value) {
                        if (value == 'like') {
                          _handleLikeUnlike(true);
                        } else if (value == 'unlike') {
                          _handleLikeUnlike(false);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'like',
                          enabled: !_isLiked,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.favorite,
                              color: _isLiked
                                  ? Colors.grey
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(
                              'Like',
                              style: TextStyle(
                                color: _isLiked
                                    ? Colors.grey
                                    : isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'unlike',
                          enabled: _isLiked,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.favorite_border,
                              color: !_isLiked
                                  ? Colors.grey
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(
                              'Unlike',
                              style: TextStyle(
                                color: !_isLiked
                                    ? Colors.grey
                                    : isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem<String>(
                          value: 'share',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.share,
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                            title: Text(
                              'Share',
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'playlist',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.playlist_add,
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                            title: Text(
                              'Add to playlist',
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // Album art with like indicator
                Center(
                  child: Stack(
                    children: [
                      // Rotating album art
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (_, child) {
                          return Transform.rotate(
                            angle: _animationController.value * 2 * 3.14159,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.network(
                              widget.songs,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      // Like indicator
                      if (_isLiked)
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            child: Icon(
                              Icons.favorite,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                // Song title and artist
                Text(
                  widget.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.emotion,
                  style: TextStyle(
                    fontSize: 18,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 40),
                // Custom progress bar
                Column(
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                        activeTrackColor: Theme.of(context).colorScheme.primary,
                        inactiveTrackColor: isDarkMode ? Colors.white24 : Colors.black12,
                        thumbColor: Theme.of(context).colorScheme.primary,
                        overlayColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      ),
                      child: Slider(
                        min: 0,
                        max: _duration.inSeconds.toDouble(),
                        value: _position.inSeconds.toDouble(),
                        onChanged: (value) {
                          final position = Duration(seconds: value.toInt());
                          _audioPlayer.seek(position);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Playback controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        size: 28,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.skip_previous,
                        color: isDarkMode ? Colors.white : Colors.black87,
                        size: 36,
                      ),
                      onPressed: () {},
                    ),
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 40,
                        ),
                        onPressed: () {
                          if (_isPlaying) {
                            _audioPlayer.pause();
                          } else {
                            _audioPlayer.resume();
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.skip_next,
                        color: isDarkMode ? Colors.white : Colors.black87,
                        size: 36,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.repeat,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        size: 28,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}















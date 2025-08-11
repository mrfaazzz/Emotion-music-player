import 'package:flutter/material.dart';

class PlaylistDetailView extends StatelessWidget {
  final List<Song> playlistSongs;
  final Function(int) onPlaySong;

  const PlaylistDetailView({
    required this.playlistSongs,
    required this.onPlaySong,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.purple.shade900, const Color(0xFF121212)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: playlistSongs.isNotEmpty &&
                            playlistSongs[0].simage != null
                            ? Image.network(
                          playlistSongs[0].simage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.purple.shade300,
                              child: const Icon(Icons.music_note,
                                  color: Colors.white, size: 100),
                            );
                          },
                        )
                            : Container(
                          color: Colors.purple.shade300,
                          child: const Icon(Icons.music_note,
                              color: Colors.white, size: 100),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        playlistSongs.isNotEmpty
                            ? playlistSongs[0].sname
                            : 'Playlist',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${playlistSongs.length} songs',
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade400, Colors.purple.shade700],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play All'),
                      onPressed: () => onPlaySong(0),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final song = playlistSongs[index];
                return Container(
                  margin:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: song.simage != null
                          ? Image.network(
                        song.simage!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              width: 50,
                              height: 50,
                              color: Colors.purple.shade200,
                              child: const Icon(Icons.music_note,
                                  color: Colors.white),
                            ),
                      )
                          : Container(
                        width: 50,
                        height: 50,
                        color: Colors.purple.shade200,
                        child: const Icon(Icons.music_note,
                            color: Colors.white),
                      ),
                    ),
                    title: Text(
                      song.sname,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      song.emotion,
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          song.duration,
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.grey),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    onTap: () => onPlaySong(index),
                  ),
                );
              },
              childCount: playlistSongs.length,
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }
}

class Playlist {
  final String id;
  final String pname;
  final String emotion;
  final List<Song> songs;

  const Playlist({
    required this.id,
    required this.pname,
    required this.emotion,
    required this.songs,
  });
}

class Song {
  final int id;
  final String sname;
  final String duration;
  final String emotion;
  final String? simage;
  final String songUrl;

  Song({
    required this.id,
    required this.sname,
    required this.duration,
    required this.emotion,
    this.simage,
    this.songUrl = '',
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
      id: int.parse(json['id'].toString()),
      sname: json['sname'].toString(),
      duration: json['duration']?.toString() ?? '0:00',
      emotion: json['emotion'].toString(),
      simage: processUrl(json['simage']),
      songUrl: processUrl(json['song'] ?? ''),
    );
  }
}
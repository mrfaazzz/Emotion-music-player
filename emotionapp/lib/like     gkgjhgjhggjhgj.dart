import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: playlist_select(),
  ));
}

class playlist_select extends StatefulWidget {
  const playlist_select({super.key});

  @override
  State<playlist_select> createState() => _playlist_selectState();
}

class _playlist_selectState extends State<playlist_select> {
  List<Playlist> playlists = [];
  List<Song> playlistSongs = []; // To store songs of the selected playlist
  bool isLoading = true;
  bool isLoadingSongs = false; // To show loading for song fetch
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    fetchPlaylists();
    _searchController.addListener(() {
      setState(() => searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
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

      if (!baseUrl.endsWith('/')) {
        baseUrl += '/';
      }

      String url = baseUrl + "view_playlistapp";
      var response = await http.post(Uri.parse(url), body: {
        'lid': pref.getString("lid") ?? "",
      });

      var jsondata = json.decode(response.body);
      if (jsondata["status"] == "ok") {
        List<Playlist> tempPlaylists = (jsondata["data"] as List).map((item) {
          List<Song> songs = item['songs'] != null
              ? (item['songs'] as List)
              .map((songItem) => Song.fromJson(songItem, baseUrl!))
              .toList()
              : [Song.fromJson(item, baseUrl!)];

          return Playlist(
            id: item['id'].toString(),
            pname: item['pname'].toString(),
            emotion: item['emotion'].toString(),
            songs: songs,
          );
        }).toList();

        setState(() {
          playlists = tempPlaylists;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchPlaylistDetails(String pid) async {
    try {
      setState(() => isLoadingSongs = true);
      final pref = await SharedPreferences.getInstance();
      String? baseUrl = pref.getString("url");
      if (baseUrl == null) {
        setState(() => isLoadingSongs = false);
        return;
      }

      if (!baseUrl.endsWith('/')) {
        baseUrl += '/';
      }

      String url = baseUrl + "view_playlistapp_details";
      var response = await http.post(Uri.parse(url), body: {
        'pid': pid,
      });

      var jsondata = json.decode(response.body);
      if (jsondata["status"] == "ok") {
        List<Song> fetchedSongs = (jsondata["data"] as List).map((item) {
          return Song(
            id: item['id'],
            sname: item['sname'],
            duration: item['duration'] ?? '0:00',
            emotion: item['emotion'],
            simage: item['simage'],
            songUrl: item['song'] ?? '',
          );
        }).toList();

        setState(() {
          playlistSongs = fetchedSongs;
          isLoadingSongs = false;
        });
      } else {
        setState(() => isLoadingSongs = false);
      }
    } catch (e) {
      setState(() => isLoadingSongs = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching playlist details: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredPlaylists = playlists
        .where((playlist) =>
        playlist.pname.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.purple.shade900,
        title: isSearching
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
            : const Text('My Playlists'),
        actions: [
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
      body: RefreshIndicator(
        onRefresh: fetchPlaylists,
        child: isLoading
            ? const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
          ),
        )
            : Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: filteredPlaylists.length,
                itemBuilder: (context, index) {
                  final playlist = filteredPlaylists[index];
                  return Card(
                    color: const Color(0xFF1E1E1E),
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        await fetchPlaylistDetails(playlist.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: playlist.songs.isNotEmpty &&
                                    playlist.songs[0].simage != null
                                    ? Image.network(
                                  playlist.songs[0].simage!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.purple.withOpacity(0.3),
                                      child: const Icon(
                                          Icons.music_note,
                                          color: Colors.white),
                                    );
                                  },
                                )
                                    : Container(
                                  color: Colors.purple.withOpacity(0.3),
                                  child: const Icon(
                                      Icons.music_note,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    playlist.pname,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${playlist.songs.length} songs • ${playlist.emotion}',
                                    style: TextStyle(color: Colors.grey.shade400),
                                  ),
                                ],
                              ),
                            ),
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.purple,
                              child: IconButton(
                                icon: const Icon(Icons.play_arrow,
                                    color: Colors.white, size: 18),
                                onPressed: () async {
                                  await fetchPlaylistDetails(playlist.id);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (isLoadingSongs)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                ),
              )
            else if (playlistSongs.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: playlistSongs.length,
                  itemBuilder: (context, index) {
                    final song = playlistSongs[index];
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
                              Container(
                                width: 50,
                                height: 50,
                                color: Colors.purple.shade200,
                                child:
                                const Icon(Icons.music_note, color: Colors.white),
                              ),
                        )
                            : Container(
                          width: 50,
                          height: 50,
                          color: Colors.purple.shade200,
                          child:
                          const Icon(Icons.music_note, color: Colors.white),
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
                      trailing: Text(
                        song.duration,
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                      onTap: () {
                        // Song selected but no action now
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Selected song: ${song.sname}')),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
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
      // Ensure there's no double slash when combining base URL and path
      if (baseUrl.endsWith('/') && url.startsWith('/')) {
        return baseUrl + url.substring(1);
      } else if (!baseUrl.endsWith('/') && !url.startsWith('/')) {
        return baseUrl + '/' + url;
      }
      return baseUrl + url;
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
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
    // Helper function to process URLs
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
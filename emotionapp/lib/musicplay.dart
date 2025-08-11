import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MusicApp());
}

class MusicApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NowPlayingScreen(),
    );
  }
}

class NowPlayingScreen extends StatefulWidget {
  @override
  _NowPlayingScreenState createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  String imageUrl = '';

  @override
  void initState() {
    super.initState();
    fetchSongData();
  }

  void fetchSongData() async {
    final response = await http.get(Uri.parse('https://your-backend-api-url.com/api/songs'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        imageUrl = data['data'][0]['simage']; // Fetch the first song image from the response
      });
    } else {
      print('Failed to load song data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Blurred background
          Positioned.fill(
            child: imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
            )
                : Container(color: Colors.black),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),

          // Main content
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text(
                      //   'Play Now: Playlist «Mysterious»',
                      //   style: TextStyle(
                      //     fontSize: 16,
                      //     color: Colors.white70,
                      //     fontFamily: 'Roboto',
                      //   ),
                      // ),
                      // SizedBox(height: 10),
                      // Text(
                      //   'Burning',
                      //   style: TextStyle(
                      //     fontSize: 28,
                      //     fontWeight: FontWeight.bold,
                      //     color: Colors.white,
                      //     fontFamily: 'Roboto',
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),

              // Overlapping small image
              Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: imageUrl.isNotEmpty
                          ? NetworkImage(imageUrl)
                          : AssetImage('assets/placeholder.jpg') as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                ),
              ),

              // Music controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    // Progress bar
                    Slider(
                      value: 0.36,
                      onChanged: (value) {},
                      activeColor: Colors.white,
                      inactiveColor: Colors.white54,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '0:36',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            '2:43',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),

                    // Play/Pause and Skip buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.skip_previous),
                          iconSize: 48,
                          color: Colors.white,
                          onPressed: () {},
                        ),
                        SizedBox(width: 16),
                        IconButton(
                          icon: Icon(Icons.play_circle_fill),
                          iconSize: 64,
                          color: Colors.white,
                          onPressed: () {},
                        ),
                        SizedBox(width: 16),
                        IconButton(
                          icon: Icon(Icons.skip_next),
                          iconSize: 48,
                          color: Colors.white,
                          onPressed: () {},
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Music List button
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'o_o',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
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
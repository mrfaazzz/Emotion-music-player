import 'dart:convert';
import 'package:emotionapp/songs.dart';
import 'package:emotionapp/view%20complaint.dart';
import 'package:emotionapp/view%20playlist.dart';
import 'package:emotionapp/viewplay1.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'Login.dart';
import 'camopen1.dart';
import 'feedback.dart';
import 'liked_playlist.dart';
import 'viewprofile.dart';
import 'view%20chat.dart';

void main() {
  // Add this to properly handle system navigation
  SystemChannels.platform.invokeMethod('SystemNavigator.setEgressType', {'type': 'none'});
  runApp(const Homepage());
}

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show exit dialog instead of allowing back navigation
        _showExitDialog(context);
        return false; // Prevents back navigation
      },
      child: const BrowseScreen(),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text(
          'Exit App',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Do you want to exit the application?',
          style: TextStyle(color: Color(0xFFB3B3B3)),
        ),
        actions: [
          TextButton(
            child: const Text(
              'No',
              style: TextStyle(color: Color(0xFF1DB954)),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text(
              'Yes',
              style: TextStyle(color: Color(0xFFFF0000)),
            ),
            onPressed: () {
              // This is the proper way to exit the app
              SystemNavigator.pop();
            },
          ),
        ],
      ),
    );
  }
}

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> with SingleTickerProviderStateMixin {
  // State variables
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  String name = 'name', email = 'email', image = 'image';

  // Constants and data
  static const Color primaryColor = Color(0xFF1DB954);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color secondaryBackgroundColor = Color(0xFF282828);
  static const Color textColor = Color(0xFFFFFFFF);
  static const Color secondaryTextColor = Color(0xFFB3B3B3);
  static const Color dividerColor = Color(0xFF404040);

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _initializeAnimation();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _animation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show exit dialog instead of allowing back navigation
        _showExitDialog(context);
        return false;
      },
      child: Scaffold(
        drawer: _buildDrawer(),
        appBar: _buildAppBar(),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "Find Your Mood" Title
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Find Your Mood',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2F7A0C),
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: const Color(0xFF1DB954).withOpacity(0.5),
                        offset: const Offset(2, 2),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),

              // Mood Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: [
                  _buildMoodCard('FEAR', 'assets/new year.jpg'),
                  _buildMoodCard('NEUTRAL', 'assets/best2020.jpeg'),
                  _buildMoodCard('Happy', 'assets/happy.jpeg'),
                  _buildMoodCard('RAGE', 'assets/gym.jpg'),
                  _buildMoodCard('Sad', 'assets/sad.jpg'),
                  _buildMoodCard('Chill', 'assets/chill.jpg'),
                ],
              ),
            ],
          ),
        ),
        floatingActionButton: _buildFAB(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        title: const Text(
          'Exit App',
          style: TextStyle(color: textColor),
        ),
        content: const Text(
          'Do you want to exit the application?',
          style: TextStyle(color: secondaryTextColor),
        ),
        actions: [
          TextButton(
            child: const Text(
              'No',
              style: TextStyle(color: primaryColor),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text(
              'Yes',
              style: TextStyle(color: Color(0xFFFF0000)),
            ),
            onPressed: () {
              // This is the proper way to exit the app
              SystemNavigator.pop();
            },
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'EMO PLAYER',
        style: TextStyle(
          color: Colors.green,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [secondaryBackgroundColor, backgroundColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline, color: textColor),
          onPressed: () {
            _showPopup(context);
          },
        ),
      ],
    );
  }

  void _showPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: backgroundColor,
          child: Container(
            padding: const EdgeInsets.all(24),
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Title Section
                Center(
                  child: Column(
                    children: [
                      Text(
                        '🎧 EMO PLAYER',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Music that understands you.',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey[700]),

                /// Feature Section
                const SizedBox(height: 12),
                _buildFeatureItem(
                  title: '📸 Snap Your Mood        ',
                  description: 'Take a selfie, and let EMO PLAYER analyze your facial expression in real time.',
                ),
                _buildFeatureItem(
                  title: '🎵 AI-Powered Playlists  ',
                  description: 'Our advanced AI selects songs based on emotions like happiness, sadness, relaxation, and excitement.',
                ),

                _buildFeatureItem(
                  title: '🔒 100% Privacy         ' ,
                  description: 'Images are processed locally and never stored, ensuring complete privacy and security.',
                ),

                const Spacer(),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CamOpenPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '🎬 Try It Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem({required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodCard(String title, String imagePath) {
    // Define the playlist object based on the mood title
    ViewPlay1 playlistDetails;

    switch (title.toLowerCase()) {
      case 'fear':
        playlistDetails = ViewPlay1(pid: '18', pname: 'Fearful Vibes');
        break;
      case 'neutral':
        playlistDetails = ViewPlay1(pid: '16', pname: 'Neutral Tones');
        break;
      case 'happy':
        playlistDetails = ViewPlay1(pid: '7', pname: 'Happy Beats');
        break;
      case 'rage':
        playlistDetails = ViewPlay1(pid: '11', pname: 'Rage Mode');
        break;
      case 'sad':
        playlistDetails = ViewPlay1(pid: '10', pname: 'Sad Melodies');
        break;
      case 'chill':
        playlistDetails = ViewPlay1(pid: '24', pname: 'Chillout');
        break;
      default:
        playlistDetails = ViewPlay1(pid: '', pname: 'Default Playlist');
    }

    return GestureDetector(
      onTap: () async {
        final sh = await SharedPreferences.getInstance();
        sh.setString("emo", title);
        sh.setString("view_playlist_pid", playlistDetails.pid);
        sh.setString("view_playlist_pname", playlistDetails.pname);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewPlay1(pid: playlistDetails.pid, pname: playlistDetails.pname),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          gradient: LinearGradient(
            colors: [const Color(0xFF282828), const Color(0xFF121212)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              Image.asset(imagePath, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Color(0xFF1DB954), blurRadius: 5)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return ScaleTransition(
      scale: _animation,
      child: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CamOpenPage()),
        ),
        backgroundColor: primaryColor,
        child: const Icon(Icons.camera_alt, color: textColor, size: 32),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomAppBar(
      color: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [secondaryBackgroundColor, backgroundColor],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 0, const Homepage()),
            _buildNavItem(Icons.chat, 1, const ChatWithUser(title: 'Chat')),
            const SizedBox(width: 40),
            _buildNavItem(Icons.feedback, 2, const feedback()),
            _buildNavItem(Icons.person, 3, const studProfile(title: 'Profile')),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, Widget destination) {
    final isSelected = _currentIndex == index;
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? primaryColor : secondaryTextColor,
        size: 28,
      ),
      onPressed: () {
        setState(() => _currentIndex = index);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
    );
  }

  // ===== DRAWER COMPONENTS =====

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: backgroundColor,
      elevation: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [secondaryBackgroundColor, backgroundColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildDrawerHeader(),
            _buildDrawerItem(Icons.person, 'View Profile', const studProfile(title: 'Profile')),
            _buildDrawerItem(Icons.music_note, 'View Songs', const Viewsongs()),
            _buildDrawerItem(Icons.playlist_add, 'Manage Playlist', managesong()),
            _buildDrawerItem(Icons.favorite, 'YOUR Playlist',  LikedSongsScreen()),
            _buildDrawerItem(Icons.feedback, 'Feedback & Ratings', const feedback()),
            _buildDrawerItem(Icons.camera_alt, 'FACE', CamOpenPage()),
            // _buildDrawerItem(Icons.camera_alt, 'FACE', ViewPlay1(pid: '24', pname: 'chillout',)),
            _buildDrawerItem(Icons.report, 'Complaints', ComplaintsFullPage(title: '')),
            _buildDrawerItem(Icons.chat, 'Chat with Users', const ChatWithUser(title: 'Chat')),
            const Divider(
              color: dividerColor,
              thickness: 1,
              indent: 16,
              endIndent: 16,
            ),
            _buildDrawerItem(Icons.logout, 'Logout', null, isLogout: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 40, left: 16, bottom: 16),
      decoration: const BoxDecoration(
        color: secondaryBackgroundColor,
        border: Border(bottom: BorderSide(color: dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: dividerColor,
            child: ClipOval(
              child: Image.network(
                image,
                fit: BoxFit.cover,
                width: 76,
                height: 76,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, Widget? destination, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: secondaryTextColor, size: 28),
      title: Text(
        title,
        style: const TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        if (isLogout) {
          _showLogoutDialog();
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination!),
          );
        }
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        title: const Text(
          'Confirm Logout',
          style: TextStyle(color: textColor),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: secondaryTextColor),
        ),
        actions: [
          TextButton(
            child: const Text(
              'Cancel',
              style: TextStyle(color: primaryColor),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text(
              'Logout',
              style: TextStyle(color: Color(0xFFFF0000)),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const login()),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===== DATA HANDLING =====

  void _fetchUserProfile() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url') ?? '';
    String lid = sh.getString('lid') ?? '';
    final urls = Uri.parse(url + 'and_profile');

    try {
      final response = await http.post(urls, body: {'lid': lid});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          setState(() {
            name = data['name'].toString();
            email = data['email'].toString();
            image = '$url${data['image']}';
          });
        } else {
          Fluttertoast.showToast(msg: 'Profile not found');
        }
      } else {
        Fluttertoast.showToast(msg: '');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }
}
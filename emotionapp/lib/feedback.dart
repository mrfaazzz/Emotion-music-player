import 'dart:convert';
import 'package:emotionapp/view%20chat.dart';
import 'package:emotionapp/viewprofile.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'home.dart';

class feedback extends StatefulWidget {
  const feedback({super.key});

  @override
  State<feedback> createState() => _feedbackState();
}

class _feedbackState extends State<feedback> {
  int _selectedStars = 0; // Stores the selected rating
  int _currentIndex = 2; // Sets the initial index to 'Feedback' tab
  final TextEditingController _commentController = TextEditingController();

  Future<void> _submitfeedback() async {
    final sh = await SharedPreferences.getInstance();
    String rating = _selectedStars.toString();
    String comment = _commentController.text;
    String? url = sh.getString("url");

    if (url == null) {
      Fluttertoast.showToast(msg: "URL not found in SharedPreferences");
      return;
    }

    try {
      var response = await http.post(
        Uri.parse(url + "user_sent_feedback"),
        body: {
          'lid': sh.getString("lid") ?? "",
          'content': comment,
          'rating': rating,
        },
      );

      var jsonData = json.decode(response.body);
      if (jsonData['status'] == "ok") {
        Fluttertoast.showToast(msg: "Feedback sent successfully!");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Homepage()),
        );
      } else {
        Fluttertoast.showToast(msg: "Failed to send feedback.");
      }
    } catch (e) {
      print(e);
      Fluttertoast.showToast(msg: "An error occurred.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Homepage()),
        );
        return false; // Prevent default back action
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A), // Darker background
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Share Your Feedback',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Colors.grey.shade900],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Your feedback helps us improve',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 20),

                // Star Rating Section with animation
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () => setState(() => _selectedStars = index + 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: Icon(
                          index < _selectedStars ? Icons.star : Icons.star_border,
                          color: Colors.greenAccent.shade400,
                          size: 45,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 30),

                // Comments Input with modern design
                TextField(
                  controller: _commentController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Leave your comments (optional)',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.grey.shade800.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 30),

                // Submit Button with gradient
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _submitfeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: const EdgeInsets.all(0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.greenAccent.shade400, Colors.teal.shade300],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: const Text(
                          'Send',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // "No, Thank You" Button with subtle hover effect
                TextButton(
                  onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const Homepage()),),
                  child: const Text(
                    'No, Thank You',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.greenAccent.shade200,
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF070101),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.feedback), label: 'Feedback'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          selectedItemColor: Colors.greenAccent.shade400,
          unselectedItemColor: Colors.white70,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            switch (index) {
              case 0:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Homepage()),
                );
                break;
              case 1:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatWithUser(title: 'Chat'),
                  ),
                );
                break;
              case 2:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const feedback()),
                );
                break;
              case 3:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const studProfile(title: 'Profile'),
                  ),
                );
                break;
            }
          },
          elevation: 10,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
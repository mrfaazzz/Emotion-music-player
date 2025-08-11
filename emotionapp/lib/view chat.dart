
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'chat.dart';
import 'home.dart';
import 'feedback.dart';
import 'viewprofile.dart';

class ViewChat extends StatefulWidget {
  const ViewChat({super.key});

  @override
  _ViewChatState createState() => _ViewChatState();
}

class _ViewChatState extends State<ViewChat> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat View')),
      backgroundColor: const Color(0xFF121212),
      body: const ChatWithUser(title: 'Chat View'),
    );
  }
}

class ChatWithUser extends StatefulWidget {
  const ChatWithUser({super.key, required this.title});
  final String title;

  @override
  State<ChatWithUser> createState() => _ChatWithUserState();
}

class _ChatWithUserState extends State<ChatWithUser> {
  List<String> cid_ = <String>[];
  List<String> LOGIN_ = <String>[];
  List<String> name_ = <String>[];
  List<String> image_ = <String>[];
  List<String> place_ = <String>[];
  int _currentIndex = 1;

  _ChatWithUserState() {
    load();
  }

  Future<void> load() async {
    List<String> cid = <String>[];
    List<String> LOGIN = <String>[];
    List<String> name = <String>[];
    List<String> image = <String>[];
    List<String> place = <String>[];

    try {
      final pref = await SharedPreferences.getInstance();
      String ip = pref.getString("url").toString();
      String lid = pref.getString("lid").toString();
      String url = ip + "view_user_chat";

      var data = await http.post(Uri.parse(url), body: {'lid': lid});
      var jsonData = json.decode(data.body);

      var arr = jsonData["data"];

      for (int i = 0; i < arr.length; i++) {
        cid.add(arr[i]['id'].toString());
        LOGIN.add(arr[i]['LOGIN'].toString());
        name.add(arr[i]['name'].toString());
        place.add(arr[i]['place'].toString());
        String baseUrl = pref.getString('url').toString();
        String imageUrl = baseUrl + arr[i]['image'].toString();
        image.add(imageUrl);
      }

      setState(() {
        cid_ = cid;
        LOGIN_ = LOGIN;
        name_ = name;
        image_ = image;
        place_ = place;
      });
    } catch (e) {
      print("Error: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFF121212),
        title: Text(
          "CHAT",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF121212),
              Color(0xFF050505),
            ],
          ),
        ),
        child: ListView.builder(
          physics: BouncingScrollPhysics(),
          itemCount: cid_.length,
          itemBuilder: (BuildContext context, int index) {
            return AnimatedContainer(
              duration: Duration(milliseconds: 300),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Color(0xFF282828),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {},
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 35,
                              backgroundColor: Color(0xFFFFFFFF),
                              child: CircleAvatar(
                                radius: 33,
                                backgroundImage: image_[index].isNotEmpty
                                    ? NetworkImage(image_[index])
                                    : AssetImage('assets/placeholder.jpg') as ImageProvider,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name_[index],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  place_[index],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () async {
                                    SharedPreferences sh = await SharedPreferences.getInstance();
                                    sh.setString('clid', LOGIN_[index].toString());
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => MyChatPage(title: '')),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    primary: Color(0xFF1DB954),
                                    onPrimary: Colors.white,
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.chat_bubble_outline, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Message',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 15,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Color(0xFF282828),
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.feedback_outlined),
              activeIcon: Icon(Icons.feedback),
              label: 'Feedback',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          selectedItemColor: Color(0xFF1DB954),
          unselectedItemColor: Colors.grey[400],
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            switch (index) {
              case 0:
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => const Homepage()));
                break;
              case 1:
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => const ViewChat()));
                break;
              case 2:
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => const feedback()));
                break;
              case 3:
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => const studProfile(title: 'Profile')));
                break;
            }
          },
        ),
      ),
    );
  }
}
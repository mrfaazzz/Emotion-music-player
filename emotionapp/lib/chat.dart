import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyChatApp());
}

class MyChatApp extends StatelessWidget {
  const MyChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Modern Chat',
      theme: ThemeData.dark().copyWith(
        primaryColor: Color(0xFF1DB954),
        scaffoldBackgroundColor: Color(0xFF121212),
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF1DB954),
          secondary: Color(0xFF1ED760),
        ),
      ),
      home: const MyChatPage(title: 'Chat'),
    );
  }
}

class MyChatPage extends StatefulWidget {
  const MyChatPage({super.key, required this.title});
  final String title;

  @override
  State<MyChatPage> createState() => _MyChatPageState();
}

class ChatMessage {
  String messageContent;
  String messageType;
  ChatMessage({required this.messageContent, required this.messageType});
}

class _MyChatPageState extends State<MyChatPage> {
  String username = "";
  List<ChatMessage> messages = [];
  final TextEditingController te_message = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  _MyChatPageState() {
    Timer.periodic(Duration(seconds: 2), (_) {
      view_message();
    });
  }

  @override
  void dispose() {
    te_message.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> view_message() async {
    try {
      final pref = await SharedPreferences.getInstance();
      String urls = pref.getString('url').toString();
      String lid = pref.getString("lid").toString();
      String clid = pref.getString("clid").toString();

      String url = urls + 'user_viewchat';
      var data = await http.post(Uri.parse(url), body: {
        'from_id': lid,
        'to_id': clid,
      });

      var jsondata = json.decode(data.body);
      String fetchedUsername = jsondata['user'] ?? "user";

      var arr = jsondata["data"];
      List<ChatMessage> newMessages = [];

      for (int i = 0; i < arr.length; i++) {
        if (lid == arr[i]['from'].toString()) {
          newMessages.add(ChatMessage(
              messageContent: arr[i]['msg'], messageType: "sender"));
        } else {
          newMessages.add(ChatMessage(
              messageContent: arr[i]['msg'], messageType: "receiver"));
        }
      }

      setState(() {
        username = fetchedUsername;
        messages = newMessages;
      });

      // Scroll to bottom when new messages arrive
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      print("Error: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFF282828),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF1DB954).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: Color(0xFF1DB954),
                radius: 20,
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : '',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    color: Color(0xFF1DB954),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // IconButton(
          //   icon: Icon(Icons.call, color: Colors.white),
          //   onPressed: () {},
          // ),
          // IconButton(
          //   icon: Icon(Icons.more_vert, color: Colors.white),
          //   onPressed: () {},
          // ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF282828),
              Color(0xFF121212),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  bool isMe = messages[index].messageType == "sender";
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment:
                      isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        if (!isMe)
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey[800],
                            child: Text(
                              username.isNotEmpty ? username[0].toUpperCase() : '',
                              style: TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ),
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          margin: EdgeInsets.only(
                            left: isMe ? 0 : 8,
                            right: isMe ? 8 : 0,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isMe ? Color(0xFF1DB954) : Color(0xFF404040),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 3,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            messages[index].messageContent,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.grey[200],
                              fontSize: 16,
                            ),
                          ),
                        ),
                        // if (isMe)
                        //   CircleAvatar(
                        //     radius: 16,
                        //     backgroundColor: Color(0xFF1DB954),
                        //     child: Text(
                        //       'Me',
                        //       style: TextStyle(fontSize: 12, color: Colors.white),
                        //     ),
                        //   ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xFF282828),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Color(0xFF404040),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: te_message,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF1DB954),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.send, color: Colors.white),
                        onPressed: () async {
                          String message = te_message.text.trim();
                          if (message.isEmpty) return;

                          try {
                            final pref = await SharedPreferences.getInstance();
                            String ip = pref.getString("url").toString();
                            String url = ip + "user_sendchat";

                            await http.post(Uri.parse(url), body: {
                              'message': message,
                              'from_id': pref.getString("lid").toString(),
                              'to_id': pref.getString("clid").toString()
                            });

                            te_message.clear();
                            setState(() {});
                          } catch (e) {
                            print("Error: ${e.toString()}");
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
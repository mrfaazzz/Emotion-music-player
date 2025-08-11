import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'home.dart';
import 'editprofile.dart';

class studProfile extends StatefulWidget {
  const studProfile({super.key, required this.title});

  final String title;

  @override
  State<studProfile> createState() => _studProfileState();
}

class _studProfileState extends State<studProfile> {
  @override
  void initState() {
    super.initState();
    senddata();
  }

  String name = 'name';
  String email = 'email';
  String post = 'post';
  String place = 'place';
  String phone = 'phone';
  String image = 'Image';
  String pin = 'pin';

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Homepage()),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SingleChildScrollView(
          child: Stack(
            children: [
              // Top Image
              SizedBox(
                height: 280,
                width: double.infinity,
                child: Image.network(
                  image,
                  fit: BoxFit.cover,
                ),
              ),

              // Profile Content
              Container(
                margin: const EdgeInsets.fromLTRB(16.0, 240.0, 16.0, 16.0),
                child: InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => Image.network(image),
                    );
                  },
                  child: Column(
                    children: [
                      // Profile Card
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            margin: const EdgeInsets.only(top: 16.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(left: 110.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            email,
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      CircleAvatar(
                                        backgroundColor: Colors.green,
                                        child: IconButton(
                                          onPressed: () async {
                                           Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen(title: '')));
                                          },
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                        // child: IconButton(
                                        //   onPressed: () async {
                                        //     final updatedData =
                                        //     await Navigator.push(
                                        //       context,
                                        //       MaterialPageRoute(
                                        //
                                        //       ),
                                        //     );
                                        //
                                        //     if (updatedData != null) {
                                        //       setState(() {
                                        //         name = updatedData['name'];
                                        //         email = updatedData['email'];
                                        //         place = updatedData['place'];
                                        //         post = updatedData['post'];
                                        //         pin = updatedData['pin'];
                                        //         phone = updatedData['phone'];
                                        //       });
                                        //     }
                                        //   },
                                        //   icon: const Icon(
                                        //     Icons.edit_outlined,
                                        //     color: Colors.white,
                                        //     size: 18,
                                        //   ),
                                        // ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Profile Picture
                          Container(
                            height: 90,
                            width: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.0),
                              image: DecorationImage(
                                image: NetworkImage(image),
                                fit: BoxFit.cover,
                              ),
                            ),
                            margin: const EdgeInsets.only(left: 20.0),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20.0),

                      // Profile Information
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Column(
                          children: [
                            const ListTile(
                              title: Text(
                                "Profile Information",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            const Divider(color: Colors.grey),
                            _buildInfoTile(
                              title: 'email',
                              subtitle: email,
                              icon: Icons.mail_outline,
                            ),
                            _buildInfoTile(
                              title: 'phone',
                              subtitle: phone,
                              icon: Icons.phone,
                            ),
                            _buildInfoTile(
                              title: 'place',
                              subtitle: place,
                              icon: Icons.place,
                            ),
                            _buildInfoTile(
                              title: 'post',
                              subtitle: post,
                              icon: Icons.local_post_office_outlined,
                            ),
                            _buildInfoTile(
                              title: 'pin',
                              subtitle: pin,
                              icon: Icons.pin_drop,
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),

              // Back Button
              Positioned(
                top: 60,
                left: 20,
                child: MaterialButton(
                  minWidth: 0.2,
                  elevation: 0.2,
                  color: Colors.black.withOpacity(0.7),
                  child: const Icon(
                    Icons.arrow_back_ios_outlined,
                    color: Colors.green,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Homepage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Profile Info Tile
  ListTile _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.green),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white),
      ),
      leading: Icon(
        icon,
        color: Colors.green,
      ),
    );
  }

  void senddata() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url').toString();
    String lid = sh.getString('lid').toString();
    final urls = Uri.parse(url + "and_profile");
    try {
      final response = await http.post(urls, body: {
        'lid': lid,
      });
      if (response.statusCode == 200) {
        String status = jsonDecode(response.body)['status'];
        if (status == 'ok') {
          setState(() {
            name = jsonDecode(response.body)['name'].toString();
            email = jsonDecode(response.body)['email'].toString();
            place = jsonDecode(response.body)['place'].toString();
            post = jsonDecode(response.body)['post'].toString();
            pin = jsonDecode(response.body)['pin'].toString();
            phone = jsonDecode(response.body)['phone'].toString();
            image = sh.getString('url').toString() +
                jsonDecode(response.body)['image'];
          });
        } else {
          Fluttertoast.showToast(msg: 'Not Found');
        }
      } else {
        Fluttertoast.showToast(msg: 'Network Error');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }
}

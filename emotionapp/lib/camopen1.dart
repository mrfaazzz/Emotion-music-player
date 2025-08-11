import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'home.dart';
import 'playlistplayf.dart'; // Ensure this file exists

class CamOpenPage extends StatefulWidget {
  @override
  _CamOpenPageState createState() => _CamOpenPageState();
}

class _CamOpenPageState extends State<CamOpenPage> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _captureImage();
  }

  Future<void> _captureImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
        await _uploadImage(_image!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No image selected.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error capturing image: $e")),
      );
    }
  }

  Future<void> _uploadImage(File image) async {
    try {
      setState(() {
        isLoading = true;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String ip = prefs.getString('url') ?? '';
      String lid = prefs.getString('lid') ?? '';
      String url = '$ip/uploadimage';

      Uint8List imageBytes = await image.readAsBytes();
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['lid'] = lid;
      request.files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: 'sample.png'));

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);

        if (jsonResponse['status'] == 'ok') {
          await prefs.setString("emotion", jsonResponse['emotion'].toString());
          String lid = jsonResponse['emotion'].toString();
          prefs.setString("emotion", lid);

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => EmotionalMusicApp()),
            );
          }
        } else {
          _showSnackBar("Face not verified. Try again.");
        }
      } else {
        _showSnackBar("Failed to upload. Please try again.");
      }
    } catch (e) {
      _showSnackBar("Error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Homepage()),
          );
          return false; // Prevent the default back navigation
        },
        child: Scaffold(
            backgroundColor: const Color(0xFF121212), // Spotify dark gray background
            appBar: AppBar(
              title: const Text(
                'Capture and Upload Image',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: const Color(0xFF1DB954), // Spotify green
            ),
            body: Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: isLoading
                    ? const CircularProgressIndicator(
                  color: Color(0xFF1DB954), // Spotify green color for loader
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_image != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_image!),
                      )
                    else ...[
                      const Text(
                        'Capture an image to upload',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'We\'ll analyze your expression to create a personalized playlist',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _captureImage, // Direct call to camera method
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DB954), // Spotify green
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'TRY AGAIN',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ),
      );
   }
}
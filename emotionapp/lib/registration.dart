
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'login.dart';

class registration extends StatefulWidget {
  const registration({super.key});

  @override
  State<registration> createState() => _registrationState();
}

class _registrationState extends State<registration> {
  // Controllers for Text Fields
  TextEditingController nameController = TextEditingController();
  TextEditingController placeController = TextEditingController();
  TextEditingController postController = TextEditingController();
  TextEditingController pinController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  bool _obscurePassword = true;

  // Regex Validators
  final RegExp nameRegExp = RegExp(r'^[A-Za-z ]{2,25}$');
  final RegExp emailRegExp = RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,25}$');
  final RegExp phoneRegExp = RegExp(r'^[6789]\d{9}$');
  final RegExp pinRegExp = RegExp(r'^\d{6}$');

  XFile? _image;

  // Validation method
  bool _validateInputs() {
    if (_image == null) {
      _showErrorSnackBar("Please select a profile image");
      return false;
    }

    if (!nameRegExp.hasMatch(nameController.text)) {
      _showErrorSnackBar("Name should be 2-25 characters long and contain only letters");
      return false;
    }

    if (!emailRegExp.hasMatch(emailController.text)) {
      _showErrorSnackBar("Please enter a valid email address");
      return false;
    }

    if (!phoneRegExp.hasMatch(phoneController.text)) {
      _showErrorSnackBar("Phone number should start with 6,7,8,9 and be 10 digits long");
      return false;
    }

    if (placeController.text.trim().isEmpty) {
      _showErrorSnackBar("Please enter a place");
      return false;
    }

    if (!pinRegExp.hasMatch(pinController.text)) {
      _showErrorSnackBar("Pin code should be exactly 6 digits");
      return false;
    }

    if (postController.text.trim().isEmpty) {
      _showErrorSnackBar("Please enter a post");
      return false;
    }

    if (usernameController.text.trim().isEmpty) {
      _showErrorSnackBar("Please enter a username");
      return false;
    }

    if (passwordController.text.length < 6) {
      _showErrorSnackBar("Password should be at least 6 characters long");
      return false;
    }

    return true;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Image Picker Methods
  _imgFromCamera() async {
    XFile? image = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );
    if (image != null) {
      setState(() {
        _image = image;
      });
    }
  }

  _imgFromGallery() async {
    XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (image != null) {
      setState(() {
        _image = image;
      });
    }
  }

  void _showPicker(context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.white),
                title: Text('Photo Library', style: TextStyle(color: Colors.white)),
                onTap: () {
                  _imgFromGallery();
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera, color: Colors.white),
                title: Text('Camera', style: TextStyle(color: Colors.white)),
                onTap: () {
                  _imgFromCamera();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Sign Up", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: () {
                  _showPicker(context);
                },
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey[800],
                  child: _image != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.file(
                      File(_image!.path),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Icon(
                    Icons.camera_alt,
                    color: Colors.grey[400],
                    size: 50,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildTitle("Personal Information"),
            const SizedBox(height: 20),
            _buildTextField(
              controller: nameController,
              label: " Name",
              icon: Icons.person,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: emailController,
              label: "Email",
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: phoneController,
              label: "Phone Number",
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: placeController,
              label: "Place",
              icon: Icons.place,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: pinController,
              label: "Pin code",
              icon: Icons.pin_drop_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: postController,
              label: "Post",
              icon: Icons.local_post_office_outlined,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: usernameController,
              label: "username",
              icon: Icons.person_2_outlined,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: passwordController,
              label: "Password",
              icon: Icons.lock,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey[400],
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  // Validate inputs first
                  if (!_validateInputs()) {
                    return;
                  }

                  // If validation passes, proceed with registration
                  String name = nameController.text;
                  String email = emailController.text;
                  String phone = phoneController.text;
                  String place = placeController.text;
                  String pin = pinController.text;
                  String post = postController.text;
                  String username = usernameController.text;
                  String password = passwordController.text;

                  try {
                    final sh = await SharedPreferences.getInstance();
                    String url = sh.getString("url").toString();
                    print(url);

                    var uri = Uri.parse(url + 'and_user_registration');
                    var request = http.MultipartRequest('POST', uri);

                    request.files.add(await http.MultipartFile.fromPath(
                        'image', _image!.path));
                    request.fields['name'] = name;
                    request.fields['email'] = email;
                    request.fields['place'] = place;
                    request.fields['post'] = post;
                    request.fields['pin'] = pin;
                    request.fields['phone'] = phone;
                    request.fields['username'] = username;
                    request.fields['password'] = password;

                    var response = await request.send();

                    if (response.statusCode == 200) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Successfully Registered'),
                          duration: Duration(seconds: 4),
                        ),
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => login()),
                      );
                    } else {
                      _showErrorSnackBar('Registration failed. Please try again.');
                    }
                  } catch (e) {
                    print(e);
                    _showErrorSnackBar('An error occurred. Please try again.');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1DB954),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: Text("Sign Up", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: Colors.grey[400]),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey[850],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
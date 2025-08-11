import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'home.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.title});
  final String title;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  // Text controllers for the editable fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Profile image
  String? _oldImageUrl;
  File? _selectedImage;

  // Spotify theme colors
  final Color _spotifyBlack = const Color(0xFF121212);
  final Color _spotifyDarkGrey = const Color(0xFF212121);
  final Color _spotifyGrey = const Color(0xFF535353);
  final Color _spotifyLightGrey = const Color(0xFFB3B3B3);
  final Color _spotifyGreen = const Color(0xFF1DB954);
  final Color _spotifyWhite = const Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  @override
  void dispose() {
    // Clean up controllers
    _nameController.dispose();
    _placeController.dispose();
    _postController.dispose();
    _pinController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Fetch existing profile data
  Future<void> _fetchProfileData() async {
    try {
      setState(() => _isLoading = true);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString('url') ?? '';
      final userId = prefs.getString('lid') ?? '';

      final response = await http.post(
        Uri.parse('$baseUrl/and_profile'),
        body: {'lid': userId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'ok') {
          _nameController.text = data['name'] ?? '';
          _placeController.text = data['place'] ?? '';
          _postController.text = data['post'] ?? '';
          _pinController.text = data['pin'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _emailController.text = data['email'] ?? '';

          if (data['image'] != null && data['image'].isNotEmpty) {
            _oldImageUrl = '$baseUrl${data['image']}';
          }
        } else {
          _showMessage('Could not load profile data');
        }
      } else {
        _showMessage('');
      }
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Save profile changes
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isSaving = true);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString('url') ?? '';
      final userId = prefs.getString('lid') ?? '';

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/and_editprofile'),
      );

      // Add text fields
      request.fields['lid'] = userId;
      request.fields['name'] = _nameController.text;
      request.fields['place'] = _placeController.text;
      request.fields['post'] = _postController.text;
      request.fields['pin'] = _pinController.text;
      request.fields['phone'] = _phoneController.text;
      request.fields['email'] = _emailController.text;

      // Add image if selected
      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', _selectedImage!.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'ok') {
          _showMessage('Profile updated successfully');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Homepage()),
          );
        } else {
          _showMessage('Failed to update profile');
        }
      } else {
        _showMessage('Network error occurred');
      }
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // Select image from gallery
  // Update the _selectImage method
  Future<void> _selectImage() async {
    // For Android 13+, we need to request specific permissions
    if (Platform.isAndroid) {
      // Check for Android SDK version for proper permission handling
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.photos,
        // Add media permissions for Android 13+
        Permission.mediaLibrary,
      ].request();

      if (statuses[Permission.storage]!.isGranted ||
          statuses[Permission.photos]!.isGranted ||
          statuses[Permission.mediaLibrary]!.isGranted) {
        _pickImage();
      } else {
        _showPermissionDialog();
      }
    } else {
      // For iOS
      final status = await Permission.photos.request();
      if (status.isGranted) {
        _pickImage();
      } else {
        _showPermissionDialog();
      }
    }
  }

// Separate method for picking image
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedImage != null) {
      setState(() => _selectedImage = File(pickedImage.path));
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _spotifyDarkGrey,
        title: Text('Permission Required',
            style: TextStyle(color: _spotifyWhite, fontWeight: FontWeight.bold)),
        content: Text(
          'This app needs access to your photos to select a profile picture. '
              'Please grant permission in your device settings.',
          style: TextStyle(color: _spotifyLightGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL',
                style: TextStyle(color: _spotifyLightGrey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('OPEN SETTINGS',
                style: TextStyle(color: _spotifyGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  void _showMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: _spotifyDarkGrey,
      textColor: _spotifyWhite,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _spotifyBlack,
        primaryColor: _spotifyGreen,
        colorScheme: ColorScheme.dark(
          primary: _spotifyGreen,
          secondary: _spotifyGreen,
          background: _spotifyBlack,
          surface: _spotifyDarkGrey,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: _spotifyWhite),
          bodyMedium: TextStyle(color: _spotifyLightGrey),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
            style: TextStyle(
              color: _spotifyWhite,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          centerTitle: true,
          backgroundColor: _spotifyBlack,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: _spotifyWhite,
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (!_isLoading)
              IconButton(
                icon: Icon(Icons.check, color: _spotifyGreen),
                onPressed: _isSaving ? null : _saveProfile,
              ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _spotifyDarkGrey.withOpacity(0.6),
                _spotifyBlack,
              ],
              stops: const [0.0, 0.4],
            ),
          ),
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: _spotifyGreen))
              : _buildProfileForm(),
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileImagePicker(),
          const SizedBox(height: 28),
          _buildCategory('Personal Information'),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _nameController,
            labelText: 'Full Name',
            hintText: 'Enter your full name',
            prefixIcon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _phoneController,
            labelText: 'Phone Number',
            hintText: 'Enter your 10-digit phone number',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              if (!RegExp(r'^[6789]\d{9}$').hasMatch(value)) {
                return 'Enter a valid phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _emailController,
            labelText: 'Email',
            hintText: 'Enter your email address',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                  .hasMatch(value)) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          _buildCategory('Address Information'),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _placeController,
            labelText: 'Place',
            hintText: 'Enter your city or town',
            prefixIcon: Icons.location_on_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your place';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _postController,
            labelText: 'Post',
            hintText: 'Enter your post office name',
            prefixIcon: Icons.markunread_mailbox_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter post code';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _pinController,
            labelText: 'PIN Code',
            hintText: 'Enter your 6-digit PIN code',
            prefixIcon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter PIN code';
              }
              if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                return 'Enter a valid 6-digit PIN code';
              }
              return null;
            },
          ),
          const SizedBox(height: 40),
          _isSaving
              ? Center(child: CircularProgressIndicator(color: _spotifyGreen))
              : _buildSaveButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCategory(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: _spotifyGreen,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildProfileImagePicker() {
    return Center(
      child: Stack(
        children: [
          Container(
            height: 130,
            width: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _spotifyDarkGrey,
              border: Border.all(
                color: _spotifyGreen,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: _spotifyGreen.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
              image: _selectedImage != null
                  ? DecorationImage(
                image: FileImage(_selectedImage!),
                fit: BoxFit.cover,
              )
                  : _oldImageUrl != null
                  ? DecorationImage(
                image: NetworkImage(_oldImageUrl!),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: (_selectedImage == null && _oldImageUrl == null)
                ? Icon(
              Icons.person,
              size: 80,
              color: _spotifyLightGrey,
            )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: InkWell(
              onTap: _selectImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _spotifyGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _spotifyBlack.withOpacity(0.5),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: _spotifyWhite),
      cursorColor: _spotifyGreen,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        hintStyle: TextStyle(color: _spotifyGrey.withOpacity(0.7)),
        labelStyle: TextStyle(color: _spotifyLightGrey),
        prefixIcon: Icon(prefixIcon, color: _spotifyLightGrey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: _spotifyGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        filled: true,
        fillColor: _spotifyDarkGrey,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        errorStyle: const TextStyle(color: Colors.redAccent),
        floatingLabelStyle: TextStyle(color: _spotifyGreen),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      validator: validator,
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _saveProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: _spotifyGreen,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 5,
        shadowColor: _spotifyGreen.withOpacity(0.5),
      ),
      child: const Text(
        'SAVE CHANGES',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
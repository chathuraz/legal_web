import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class LawyerProfile extends StatefulWidget {
  const LawyerProfile({Key? key}) : super(key: key);

  @override
  _LawyerProfileState createState() => _LawyerProfileState();
}

class _LawyerProfileState extends State<LawyerProfile> {
  // Add form key
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Add Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  bool _isUploadingImage = false; // Add this for image upload loading
  String? _profileImageUrl;
  File? _profileImage;
  int _currentIndex = 3;  // Profile tab selected

  // Controllers for text fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _languageController = TextEditingController();  // Singular form
  final TextEditingController _specializationController = TextEditingController();
  final TextEditingController _practiceCourtsController = TextEditingController();

  // Update _pickImage method to directly use the picked image
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85, // Compress image for better upload performance
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
        
        // Automatically upload the image to Firebase Storage
        await _uploadProfileImageToFirebase();
      }
    } catch (e) {
      print('Image picker error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // New method to upload image to Firebase Storage
  Future<void> _uploadProfileImageToFirebase() async {
    if (_profileImage == null) return;

    try {
      setState(() => _isUploadingImage = true);
      
      final String uid = _auth.currentUser!.uid;
      final String fileName = 'profile_images/$uid.jpg';
      
      // Create a reference to Firebase Storage
      final Reference storageRef = _storage.ref().child(fileName);
      
      // Upload the file
      final UploadTask uploadTask = storageRef.putFile(
        _profileImage!,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': uid,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );
      
      // Monitor upload progress (optional)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      });
      
      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      
      // Get the download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Update Firestore with the new image URL
      await _firestore.collection('lawyers').doc(uid).update({
        'profileImage': downloadUrl,
        'profileImagePath': downloadUrl, // Keep backward compatibility
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      setState(() {
        _profileImageUrl = downloadUrl;
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      print('Upload error: $e');
      setState(() => _isUploadingImage = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadLawyerProfile();
  }

  // Update the _loadLawyerProfile method to load profile image
  Future<void> _loadLawyerProfile() async {
    try {
      setState(() => _isLoading = true);
      
      final String uid = _auth.currentUser!.uid;
      final DocumentSnapshot doc = await _firestore
          .collection('lawyers')
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          // Update to use firstName and lastName directly from database
          _firstNameController.text = data['firstName'] ?? '';
          _lastNameController.text = data['lastName'] ?? '';
          _genderController.text = data['gender'] ?? '';
          _educationController.text = data['education'] ?? '';
          _experienceController.text = data['experience']?.toString() ?? '';
          _languageController.text = data['language'] ?? '';
          _specializationController.text = data['specialization'] ?? '';
          _practiceCourtsController.text = data['practiceCourts'] ?? '';
          _profileImageUrl = data['profileImage'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to delete profile image from Firebase Storage
  Future<void> _deleteProfileImage() async {
    try {
      setState(() => _isUploadingImage = true);
      
      final String uid = _auth.currentUser!.uid;
      
      // Delete from Firebase Storage
      if (_profileImageUrl != null && _profileImageUrl!.contains('firebase')) {
        final Reference storageRef = _storage.refFromURL(_profileImageUrl!);
        await storageRef.delete();
      }
      
      // Update Firestore to remove image URL
      await _firestore.collection('lawyers').doc(uid).update({
        'profileImage': FieldValue.delete(),
        'profileImagePath': FieldValue.delete(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      setState(() {
        _profileImageUrl = null;
        _profileImage = null;
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture removed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      print('Delete error: $e');
      setState(() => _isUploadingImage = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Update the profile image display widget
  Widget _buildProfileImageWidget() {
    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: const Color(0xFFD0A554),
          backgroundImage: _getProfileImage(),
          child: (_profileImage == null && _profileImageUrl == null)
              ? const Icon(Icons.person, size: 60, color: Colors.white)
              : null,
        ),
        
        // Loading indicator for image upload
        if (_isUploadingImage)
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD0A554),
                strokeWidth: 3,
              ),
            ),
          ),
        
        // Camera/Menu button
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD0A554),
              borderRadius: BorderRadius.circular(20),
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              onSelected: (String value) {
                switch (value) {
                  case 'camera':
                    _pickImage(ImageSource.camera);
                    break;
                  case 'gallery':
                    _pickImage(ImageSource.gallery);
                    break;
                  case 'delete':
                    _showDeleteImageDialog();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'camera',
                  child: ListTile(
                    leading: Icon(Icons.camera_alt),
                    title: Text('Take Photo'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'gallery',
                  child: ListTile(
                    leading: Icon(Icons.photo_library),
                    title: Text('Choose from Gallery'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (_profileImageUrl != null || _profileImage != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Remove Photo', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to get profile image
  ImageProvider? _getProfileImage() {
    if (_profileImage != null) {
      return FileImage(_profileImage!);
    } else if (_profileImageUrl != null) {
      if (_profileImageUrl!.startsWith('http')) {
        // Firebase Storage URL
        return NetworkImage(_profileImageUrl!);
      } else {
        // Local file path (backward compatibility)
        return FileImage(File(_profileImageUrl!));
      }
    }
    return null;
  }

  // Show delete confirmation dialog
  void _showDeleteImageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3D4559),
          title: const Text(
            'Remove Profile Picture',
            style: TextStyle(color: Color(0xFFD0A554)),
          ),
          content: const Text(
            'Are you sure you want to remove your profile picture?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProfileImage();
              },
              child: const Text(
                'Remove',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // Update the _saveProfile method (remove image upload logic since it's now automatic)
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final String uid = _auth.currentUser!.uid;

      // Generate search keywords for better searchability
      List<String> searchKeywords = [];
      
      // Add name keywords
      String fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
      searchKeywords.addAll(fullName.toLowerCase().split(' '));
      searchKeywords.add(_firstNameController.text.trim().toLowerCase());
      searchKeywords.add(_lastNameController.text.trim().toLowerCase());
      
      // Add current user's email prefix for existing lawyers
      String? email = _auth.currentUser?.email;
      if (email != null && email.contains('@')) {
        String emailPrefix = email.split('@')[0].toLowerCase();
        searchKeywords.add(emailPrefix);
        if (emailPrefix.contains('.')) {
          searchKeywords.addAll(emailPrefix.split('.'));
        }
      }
      
      // Add specialization keywords
      if (_specializationController.text.trim().isNotEmpty) {
        searchKeywords.add(_specializationController.text.trim().toLowerCase());
        searchKeywords.addAll(_specializationController.text.trim().toLowerCase().split(' '));
      }
      
      // Add education keywords
      if (_educationController.text.trim().isNotEmpty) {
        searchKeywords.addAll(_educationController.text.trim().toLowerCase().split(' '));
      }
      
      // Add practice courts keywords
      if (_practiceCourtsController.text.trim().isNotEmpty) {
        searchKeywords.addAll(_practiceCourtsController.text.trim().toLowerCase().split(',').map((e) => e.trim()));
      }
      
      // Add language keywords
      if (_languageController.text.trim().isNotEmpty) {
        searchKeywords.addAll(_languageController.text.trim().toLowerCase().split(',').map((e) => e.trim()));
      }
      
      // Remove duplicates and empty strings
      searchKeywords = searchKeywords.where((keyword) => keyword.isNotEmpty).toSet().toList();

      // Update Firestore document
      await _firestore.collection('lawyers').doc(uid).update({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'name': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        'gender': _genderController.text,
        'education': _educationController.text,
        'experience': int.tryParse(_experienceController.text) ?? 0,
        'language': _languageController.text,
        'specialization': _specializationController.text,
        'practiceCourts': _practiceCourtsController.text.trim(),
        'searchKeywords': searchKeywords,
        'profileComplete': true,
        'lastUpdated': FieldValue.serverTimestamp(),
        // Note: profileImage is handled separately in _uploadProfileImageToFirebase
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _genderController.dispose();
    _educationController.dispose();
    _experienceController.dispose();
    _languageController.dispose();
    _specializationController.dispose();
    _practiceCourtsController.dispose();
    _profileImage?.delete().ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Color(0xFFD0A554)),
        ),
        backgroundColor: const Color(0xFF353E55),
        iconTheme: const IconThemeData(color: Color(0xFFD0A554)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/lawyer/dashboard');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      backgroundColor: const Color(0xFF353E55),
      body: _isLoading 
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFFD0A554)),
          )
        : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Updated profile image widget
                _buildProfileImageWidget(),
                const SizedBox(height: 20),
                
                // Profile information text
                if (_profileImageUrl != null)
                  const Text(
                    'Profile picture uploaded to secure cloud storage',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 20),
                
                // Existing form fields
                _buildProfileField('First Name', _firstNameController),
                _buildProfileField('Last Name', _lastNameController),
                _buildProfileField('Gender', _genderController),
                _buildProfileField('Education', _educationController),
                _buildProfileField('Experience', _experienceController),
                _buildProfileField('Language', _languageController),
                _buildProfileField('Specialization', _specializationController),
                _buildProfileField('Practice Courts', _practiceCourtsController, 
                  hint: 'e.g., Supreme Court, High Court'),
              ],
            ),
          ),
        ),
      floatingActionButton: _isLoading ? null : FloatingActionButton.extended(
        onPressed: _saveProfile,
        backgroundColor: const Color(0xFFD0A554),
        icon: const Icon(Icons.save, color: Color(0xFF353E55)),
        label: const Text(
          'Save Profile',
          style: TextStyle(color: Color(0xFF353E55)),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF3D4559),
        selectedItemColor: const Color(0xFFD0A554),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/lawyer/dashboard');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/lawyer/bookings');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/lawyer/availability');
              break;
            case 3:
              // Already on profile page
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Availability',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField(String label, TextEditingController controller, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
          labelStyle: const TextStyle(color: Color(0xFFD0A554)),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFD0A554)),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFD0A554), width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          if (label == 'Practice Courts' && !value.contains(',') && value.length < 10) {
            return 'Please enter multiple courts separated by commas';
          }
          return null;
        },
      ),
    );
  }
}

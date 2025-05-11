import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class LawyerProfile extends StatefulWidget {
  const LawyerProfile({Key? key}) : super(key: key);

  @override
  _LawyerProfileState createState() => _LawyerProfileState();
}

class _LawyerProfileState extends State<LawyerProfile> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _languageController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  final TextEditingController _practiceCourtsController = TextEditingController();

  int _currentIndex = 3; // Profile is selected

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed
    _nameController.dispose();
    _genderController.dispose();
    _educationController.dispose();
    _experienceController.dispose();
    _languageController.dispose();
    _specializationController.dispose();
    _practiceCourtsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFF353E55),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Save profile logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile Saved')),
                );
              }
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFF353E55),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFFD0A554),
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : null,
                  child: _profileImage == null
                      ? const Icon(Icons.camera_alt,
                          size: 40, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              _buildProfileField('Name', _nameController),
              _buildProfileField('Gender', _genderController),
              _buildProfileField('Education', _educationController),
              _buildProfileField('Experience (years)', _experienceController),
              _buildProfileField('Languages', _languageController),
              _buildProfileField('Specialization', _specializationController),
              _buildProfileField('Practice Courts', _practiceCourtsController),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildProfileField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFFD0A554)),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFD0A554)),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
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
            Navigator.pushReplacementNamed(context, '/lawyer-dashboard');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/lawyer-bookings');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/lawyer-availability');
            break;
          case 3:
            // Already on profile page
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
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
    );
  }
}
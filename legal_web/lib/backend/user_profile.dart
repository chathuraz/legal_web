import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _contactController;
  late TextEditingController _professionController;
  late TextEditingController _districtController;
  late TextEditingController _nicController;
  late TextEditingController _genderController;
  late TextEditingController _languageController;

  bool _isEditing = false;
  bool _isLoading = true;
  String? _userId;

  StreamSubscription<DocumentSnapshot>? _userSubscription;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadUserData();
    _setupUserListener();
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _contactController = TextEditingController();
    _professionController = TextEditingController();
    _districtController = TextEditingController();
    _nicController = TextEditingController();
    _genderController = TextEditingController();
    _languageController = TextEditingController();
  }

  void _setupUserListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && mounted) {
          final userData = snapshot.data()!;
          setState(() {
            _firstNameController.text = userData['firstName'] ?? '';
            _lastNameController.text = userData['lastName'] ?? '';
            _nicController.text = userData['nic'] ?? '';
            _addressController.text = userData['address'] ?? '';
            _contactController.text = userData['contact'] ?? '';
            _professionController.text = userData['profession'] ?? '';
            _districtController.text = userData['district'] ?? '';
            _genderController.text = userData['gender'] ?? 'Male';
            _languageController.text = userData['language'] ?? 'Sinhala';
          });
        }
      });
    }
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) Navigator.pushReplacementNamed(context, '/client/signin');
        return;
      }

      _userId = user.uid;
      print('Loading data for user ID: $_userId'); // Debug print

      // Get user document from Firestore
      final docRef = FirebaseFirestore.instance.collection('users').doc(_userId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final userData = docSnapshot.data()!;
        print('Found user data: $userData'); // Debug print

        if (mounted) {
          setState(() {
            _firstNameController.text = userData['firstName'] ?? '';
            _lastNameController.text = userData['lastName'] ?? '';
            _emailController.text = user.email ?? '';
            _nicController.text = userData['nic'] ?? '';
            _addressController.text = userData['address'] ?? '';
            _contactController.text = userData['contact'] ?? '';
            _professionController.text = userData['profession'] ?? '';
            _districtController.text = userData['district'] ?? '';
            _genderController.text = userData['gender'] ?? 'Male';
            _languageController.text = userData['language'] ?? 'Sinhala';
          });
        }
      } else {
        print('No existing user document found. Creating new one.'); // Debug print
        
        // Create initial user data
        final initialUserData = {
          'firstName': '',
          'lastName': '',
          'email': user.email ?? '',
          'nic': '',
          'address': '',
          'contact': '',
          'profession': '',
          'district': '',
          'gender': 'Male',
          'language': 'Sinhala',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'profileComplete': false,
        };

        // Create new document
        await docRef.set(initialUserData);
        
        if (mounted) {
          setState(() {
            _emailController.text = user.email ?? '';
            _genderController.text = 'Male';
            _languageController.text = 'Sinhala';
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e'); // Debug print
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'nic': _nicController.text.trim(),
        'address': _addressController.text.trim(),
        'contact': _contactController.text.trim(),
        'profession': _professionController.text.trim(),
        'district': _districtController.text.trim(),
        'gender': _genderController.text,
        'language': _languageController.text,
        'updatedAt': FieldValue.serverTimestamp(),
        'profileComplete': true,
      };

      print('Saving user data: $userData'); // Debug print

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .update(userData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully'),
          backgroundColor: Color(0xFFD0A554),
        ),
      );

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      // Reload user data to confirm changes
      await _loadUserData();
    } catch (e) {
      print('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _professionController.dispose();
    _districtController.dispose();
    _nicController.dispose();
    _genderController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF353E55),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFD0A554)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF353E55),
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: const Color(0xFF353E55),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color(0xFFD0A554),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/client/home'); // Updated route
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            color: const Color(0xFFD0A554),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFFD0A554),
                child: Icon(Icons.person, size: 50, color: Color(0xFF353E55)),
              ),
              const SizedBox(height: 20),
              _buildProfileField('First Name', _firstNameController, Icons.person),
              _buildProfileField('Last Name', _lastNameController, Icons.person),
              _buildProfileField('Email', _emailController, Icons.email, enabled: false),
              _buildProfileField('NIC', _nicController, Icons.credit_card, enabled: !_isEditing),
              _buildProfileField('Address', _addressController, Icons.location_on),
              _buildProfileField('Contact', _contactController, Icons.phone),
              _buildProfileField('Profession', _professionController, Icons.work),
              _buildProfileField('District', _districtController, Icons.map),
              _buildProfileField('Gender', _genderController, Icons.transgender),
              _buildProfileField('Language', _languageController, Icons.language),
              const SizedBox(height: 30),
              if (_isEditing)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD0A554),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: _saveProfile,
                  child: const Text(
                    'SAVE CHANGES',
                    style: TextStyle(
                      color: Color(0xFF353E55),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF353E55),
        selectedItemColor: const Color(0xFFD0A554),
        unselectedItemColor: const Color(0xFFD9D9D9),
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/client/home'); // Updated route to match your app's route structure
          }
          // No need for index == 1 case as we're already on profile
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField(
    String label, 
    TextEditingController controller, 
    IconData icon, {
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        enabled: _isEditing && enabled,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFFD0A554)),
          prefixIcon: Icon(icon, color: const Color(0xFFD0A554)),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFD0A554)),
          ),
          disabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
        ),
        validator: (value) {
          if (_isEditing && enabled && (value == null || value.isEmpty)) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFD0A554),
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD0A554),
            ),
            onPressed: _loadUserData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
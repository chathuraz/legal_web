import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../constants/app_colors.dart';
import 'lawyer_dashboard_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String nic;

  const UserProfileScreen({
    Key? key,
    required this.firstName,
    required this.lastName,
    required this.nic,
  }) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _editMode = false;
  late final TextEditingController _fullNameController;
  late final TextEditingController _addressController;
  late final TextEditingController _contactController;
  late final TextEditingController _professionController;
  late final TextEditingController _districtController;
  late final TextEditingController _genderController;
  late final TextEditingController _languageController;
  
  // Profile image properties
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with passed data where applicable
    _fullNameController = TextEditingController(text: "${widget.firstName} ${widget.lastName}");
    _addressController = TextEditingController(text: "");
    _contactController = TextEditingController(text: "");
    _professionController = TextEditingController(text: "");
    _districtController = TextEditingController(text: "");
    _genderController = TextEditingController(text: "");
    _languageController = TextEditingController(text: "");
    
    // Check for existing profile image
    _loadProfileImage();
  }
  
  @override
  void dispose() {
    _fullNameController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _professionController.dispose();
    _districtController.dispose();
    _genderController.dispose();
    _languageController.dispose();
    super.dispose();
  }
  
  // Load existing profile image if available
  Future<void> _loadProfileImage() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String profileImagePath = path.join(appDir.path, 'profile_${widget.nic}.jpg');
      final File imageFile = File(profileImagePath);
      
      if (await imageFile.exists()) {
        setState(() {
          _profileImage = imageFile;
        });
      }
    } catch (e) {
      print('Error loading profile image: $e');
    }
  }

  // Method to pick an image from gallery
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compress image for efficiency
      );
      
      if (pickedFile != null) {
        // Create app directory if needed
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String profileImagePath = path.join(appDir.path, 'profile_${widget.nic}.jpg');
        
        // Copy the picked image to app directory with a unique name
        final File localImage = File(pickedFile.path);
        final File savedImage = await localImage.copy(profileImagePath);
        
        setState(() {
          _profileImage = savedImage;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick image')),
      );
    }
  }
  
  // Method to take a photo using camera
  Future<void> _takePhoto() async {
    try {
      final XFile? photoFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (photoFile != null) {
        // Save to app directory
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String profileImagePath = path.join(appDir.path, 'profile_${widget.nic}.jpg');
        
        final File localImage = File(photoFile.path);
        final File savedImage = await localImage.copy(profileImagePath);
        
        setState(() {
          _profileImage = savedImage;
        });
      }
    } catch (e) {
      print('Error taking photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to take photo')),
      );
    }
  }
  
  // Show image source selection dialog
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Profile Picture'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Take a Photo'),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _takePhoto();
                  },
                ),
                const Divider(),
                GestureDetector(
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Choose from Gallery'),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage();
                  },
                ),
                if (_profileImage != null) ...[
                  const Divider(),
                  GestureDetector(
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Remove Photo', style: TextStyle(color: Colors.red)),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _profileImage = null;
                      });
                      // Delete the file
                      _deleteProfileImage();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Delete profile image file
  Future<void> _deleteProfileImage() async {
    try {
      if (_profileImage != null && await _profileImage!.exists()) {
        await _profileImage!.delete();
        setState(() {
          _profileImage = null;
        });
      }
    } catch (e) {
      print('Error deleting profile image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundGrey,
        elevation: 0,
        // Removed title text as requested
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // User Avatar with tap to change photo
                      GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.purple, width: 2),
                              ),
                              child: _profileImage != null
                                  ? CircleAvatar(
                                      radius: 30,
                                      backgroundImage: FileImage(_profileImage!),
                                    )
                                  : const CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Colors.pink,
                                      child: Icon(Icons.person, size: 30, color: Colors.white),
                                    ),
                            ),
                            // Add small camera icon overlay
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.purple,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Edit Profile Button
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _editMode = !_editMode;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 2,
                        ),
                        child: Text(_editMode ? 'Save Changes' : 'Edit Profile'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // User details
                  _buildDetailRow('full name : ', _fullNameController, _editMode),
                  const Divider(),
                  _buildDetailRow('Adress : ', _addressController, _editMode),
                  const Divider(),
                  _buildDetailRow('Contact : ', _contactController, _editMode),
                  const Divider(),
                  _buildDetailRow('profession : ', _professionController, _editMode),
                  const Divider(),
                  _buildDetailRow('District : ', _districtController, _editMode),
                  const Divider(),
                  _buildDetailRow('NIC : ', TextEditingController(text: widget.nic), false), // NIC is not editable
                  const Divider(),
                  _buildDetailRow('Gender : ', _genderController, _editMode),
                  const Divider(),
                  _buildDetailRow('Language : ', _languageController, _editMode),
                ],
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.home),
                  onPressed: () {
                    // Navigate to home screen or refresh the current screen
                  },
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.document_scanner),
                  onPressed: () {
                    // Navigate to documents page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LawyerDashboardScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, TextEditingController controller, bool isEditable) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: isEditable
                ? TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                    ),
                  )
                : Text(
                    controller.text,
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/custom_text_field.dart';
import 'user_profile_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nicController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nicController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signUp() {
    if (_formKey.currentState!.validate()) {
      // In a real app, you would integrate with your authentication service here
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            nic: _nicController.text,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with logo and app name - full width as shown in image
              Container(
                width: double.infinity,
                color: AppColors.navyBlue,
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    // Balance scale icon instead of image as shown in the photo
                    Icon(Icons.balance, size: 50, color: AppColors.black12 ),
                    const SizedBox(height: 10),
                    const Text(
                      'LEGAL WEB',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'YOUR TRUSTED LEGAL PARTNER,\nANYTIME, ANYWHERE......',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Form content - with padding
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      
                      // First Row: First Name and Last Name side by side
                      Row(
                        children: [
                          // First Name field
                          Expanded(
                            child: CustomTextField(
                              hintText: 'First Name',
                              controller: _firstNameController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your first name';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10), 
                          // Last Name field
                          Expanded(
                            child: CustomTextField(
                              hintText: 'Last Name',
                              controller: _lastNameController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your last name';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      // NIC field - full width
                      CustomTextField(
                        hintText: 'NIC',
                        controller: _nicController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your NIC';
                          }
                          return null;
                        },
                      ),
                      
                      // Password field
                      CustomTextField(
                        hintText: 'Password',
                        controller: _passwordController,
                        obscureText: true,
                        showToggleVisibility: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          } else if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      
                      // Confirm Password field
                      CustomTextField(
                        hintText: 'Confirm Password',
                        controller: _confirmPasswordController,
                        obscureText: true,
                        showToggleVisibility: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          } else if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navyBlue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
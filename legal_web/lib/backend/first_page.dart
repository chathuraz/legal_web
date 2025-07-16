import 'package:flutter/material.dart';

class FirstPage extends StatelessWidget {
  const FirstPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF353E55),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo and Title Section
              Column(
                children: [
                  Image.asset(
                    'assets/images/legal_web_1.png',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 25),
                  Text(
                    'LEGAL WEB',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFD0A554),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Your Trusted Legal Partner',
                    style: TextStyle(
                      fontSize: 18,
                      color: const Color(0xFFD9D9D9),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Anytime, Anywhere',
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color(0xFFD9D9D9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              
              // Client Option Button - Updated to navigate to user_signin.dart
              _buildAuthButton(
                context: context,
                route: '/client/signin',  // Updated route
                icon: Icons.person_outline,
                label: 'For Clients',
                backgroundColor: const Color(0xFFD9D9D9),
                textColor: const Color(0xFF353E55),
                iconColor: const Color(0xFF353E55),
              ),
              const SizedBox(height: 20),
              
              // Lawyer Option Button - Updated to navigate to lawyer_signin.dart
              _buildAuthButton(
                context: context,
                route: '/lawyer/signin',  // Updated route
                icon: Icons.gavel,
                label: 'For Lawyers',
                backgroundColor: const Color(0xFFD0A554),
                textColor: Colors.white,
                iconColor: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthButton({
    required BuildContext context,
    required String route,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
  }) {
    return SizedBox(
      width: 220,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: backgroundColor == const Color(0xFFD0A554)
                  ? Colors.transparent
                  : const Color(0xFF353E55).withOpacity(0.2),
              width: 1,
            ),
          ),
          elevation: 3,
          shadowColor: Colors.black.withOpacity(0.2),
        ),
        onPressed: () {
          Navigator.pushNamed(context, route);  // Uses the named route
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                color: textColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
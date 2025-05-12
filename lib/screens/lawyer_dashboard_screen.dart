import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/dashboard_card.dart';

class LawyerDashboardScreen extends StatelessWidget {
  const LawyerDashboardScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      appBar: AppBar(
        backgroundColor: AppColors.navyBlue,
        elevation: 0,
        // Title removed as requested
      ),
      body: Column(
        children: [
          // Header with Logo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: AppColors.navyBlue,
            child: Column(
              children: [
                Image.asset(
                  'assets/images/logo.png', // Make sure to add this to your assets
                  height: 40,
                  // If logo is not available, use an icon
                  // Icon(Icons.balance, size: 40, color: AppColors.gold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'LEGAL WEB',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Dashboard Cards
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  DashboardCard(
                    title: 'Profile',
                    icon: Icons.person,
                    onTap: () {
                      // Navigate to profile
                    },
                  ),
                  DashboardCard(
                    title: 'Bookings',
                    icon: Icons.book,
                    onTap: () {
                      // Navigate to bookings
                    },
                  ),
                  DashboardCard(
                    title: 'Availability',
                    icon: Icons.access_time,
                    onTap: () {
                      // Navigate to availability management
                    },
                  ),
                  DashboardCard(
                    title: 'Clients',
                    icon: Icons.people,
                    onTap: () {
                      // Navigate to clients list
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Navigation
          Container(
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.home, true),
                _buildNavItem(Icons.book, false),
                _buildNavItem(Icons.access_time, false),
                _buildNavItem(Icons.people, false),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNavItem(IconData icon, bool isSelected) {
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? AppColors.navyBlue : Colors.grey,
      ),
      onPressed: () {
        // Handle navigation
      },
    );
  }
}
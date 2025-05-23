import 'package:flutter/material.dart';

class UserHome extends StatelessWidget {
  const UserHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF353E55),
      appBar: AppBar(
        title: Text(
          'Find Lawyer',
          style: TextStyle(
            color: const Color(0xFFD0A554),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF353E55),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search for lawyers...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: const Color(0xFF353E55)),
                  suffixIcon: Icon(Icons.tune, color: const Color(0xFF353E55)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
                style: TextStyle(color: const Color(0xFF353E55)),
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // AI Legal ChatBot Card
            _buildFeatureCard(
              icon: Icons.chat_bubble_outline,
              title: 'AI Legal ChatBot',
              subtitle: 'Get instant legal answers',
              color: const Color(0xFFD0A554),
              onTap: () {
                Navigator.pushNamed(context, '/ai-chatbot');
              },
            ),
            const SizedBox(height: 20),
            
            // My Bookings Card
            _buildFeatureCard(
              icon: Icons.calendar_today,
              title: 'My Bookings',
              subtitle: 'View and manage appointments',
              color: const Color(0xFF6C8EBF),
              onTap: () {
                Navigator.pushNamed(context, '/user-bookings');
              },
            ),
            const SizedBox(height: 20),
            
            // Scam Detection Card
            _buildFeatureCard(
              icon: Icons.security,
              title: 'Scam Detection',
              subtitle: 'Verify legal documents',
              color: const Color(0xFFD9D9D9),
              onTap: () {
                Navigator.pushNamed(context, '/scam-detection');
              },
            ),
            const SizedBox(height: 20),
            
            // Lawyers List Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recommended Lawyers',
                    style: TextStyle(
                      color: const Color(0xFFD0A554),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/all-lawyers');
                    },
                    child: Text(
                      'View All',
                      style: TextStyle(
                        color: const Color(0xFFD9D9D9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Sample Lawyer Cards
            Expanded(
              child: ListView(
                children: [
                  _buildLawyerCard(
                    name: 'John Doe',
                    specialization: 'Corporate Law',
                    rating: 4.8,
                    experience: '12 years',
                    onTap: () {
                      Navigator.pushNamed(context, '/lawyer-details', 
                        arguments: {
                          'name': 'John Doe',
                          'specialization': 'Corporate Law',
                          'rating': 4.8,
                          'experience': '12 years'
                        }
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildLawyerCard(
                    name: 'Jane Smith',
                    specialization: 'Family Law',
                    rating: 4.9,
                    experience: '8 years',
                    onTap: () {
                      Navigator.pushNamed(context, '/lawyer-details',
                        arguments: {
                          'name': 'Jane Smith',
                          'specialization': 'Family Law',
                          'rating': 4.9,
                          'experience': '8 years'
                        }
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF353E55),
        selectedItemColor: const Color(0xFFD0A554),
        unselectedItemColor: const Color(0xFFD9D9D9),
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/user-home');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/user-profile');
          }
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

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 40,
              color: const Color(0xFF353E55),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF353E55),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF353E55),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLawyerCard({
    required String name,
    required String specialization,
    required double rating,
    required String experience,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: const Color(0xFF3D4559),
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFFD0A554),
                child: Icon(Icons.person, color: Color(0xFF353E55)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      specialization,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$experience experience',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFD0A554), size: 18),
                      const SizedBox(width: 4),
                      Text(
                        rating.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'View Profile',
                    style: TextStyle(
                      color: const Color(0xFFD0A554),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
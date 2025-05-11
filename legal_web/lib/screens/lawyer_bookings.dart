import 'package:flutter/material.dart';

class LawyerBookings extends StatefulWidget {
  const LawyerBookings({Key? key}) : super(key: key);

  @override
  _LawyerBookingsState createState() => _LawyerBookingsState();
}

class _LawyerBookingsState extends State<LawyerBookings> {
  int _currentIndex = 1; // Bookings is selected
  String _selectedTab = 'Today'; // 'Today' or 'Upcoming'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF353E55),
      appBar: AppBar(
        title: const Text('Bookings'),
        backgroundColor: const Color(0xFF353E55),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFD0A554)),
      ),
      body: Column(
        children: [
          // Tab selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabButton('Today', 3),
                _buildTabButton('Upcoming', 5),
              ],
            ),
          ),
          const Divider(color: Color(0xFFD0A554), height: 1),
          // Booking cards
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildBookingCard(
                  date: '2024-03-20',
                  name: 'John Doe',
                  service: 'on call',
                  number: '+1 234 567 890',
                  reason: 'Divorce consultation',
                  timeSlot: '6:00 PM - 7:00 PM',
                ),
                const SizedBox(height: 16),
                _buildBookingCard(
                  date: '2024-03-22',
                  name: 'Jane Smith',
                  service: 'in person',
                  number: '+1 987 654 321',
                  reason: 'Property dispute',
                  timeSlot: '2:30 PM - 3:30 PM',
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildTabButton(String title, int count) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: _selectedTab == title ? const Color(0xFFD0A554) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: _selectedTab == title ? const Color(0xFF353E55) : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _selectedTab == title ? const Color(0xFF353E55) : const Color(0xFFD0A554),
                shape: BoxShape.circle,
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: _selectedTab == title ? const Color(0xFFD0A554) : const Color(0xFF353E55),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard({
    required String date,
    required String name,
    required String service,
    required String number,
    required String reason,
    required String timeSlot,
  }) {
    return Card(
      color: const Color(0xFF3D4559),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date: $date',
              style: const TextStyle(
                color: Color(0xFFD0A554),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Name:', name),
            _buildDetailRow('Service:', service),
            _buildDetailRow('Number:', number),
            _buildDetailRow('Reason:', reason),
            const SizedBox(height: 16),
            Text(
              'Time Slot: $timeSlot',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // Handle reject action
                  },
                  child: const Text(
                    'Reject',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD0A554),
                  ),
                  onPressed: () {
                    // Handle accept action
                  },
                  child: const Text(
                    'Accept',
                    style: TextStyle(
                      color: Color(0xFF353E55),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD0A554),
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/lawyer-dashboard');
            break;
          case 1:
            // Already on bookings page
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/lawyer-availability');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/lawyer-profile');
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF3D4559),
      selectedItemColor: const Color(0xFFD0A554),
      unselectedItemColor: Colors.grey[400],
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
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
    );
  }
}
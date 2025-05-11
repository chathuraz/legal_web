import 'package:flutter/material.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({Key? key}) : super(key: key);

  @override
  _ClientsPageState createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  int _currentIndex = 1; // Bookings is selected (which shows clients)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF353E55),
      appBar: AppBar(
        title: const Text('All Clients'),
        backgroundColor: const Color(0xFF353E55),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFD0A554)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildClientCard(
              'John Doe',
              '2024.03.12  on call  6.00pm',
              ['birth certificate'],
            ),
            _buildClientCard(
              'Jane Smith',
              '2024.03.15  in person  2.30pm',
              ['contract', 'property deed'],
            ),
            // Add more clients as needed
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildClientCard(String name, String history, List<String> files) {
    return Card(
      color: const Color(0xFF3D4559),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFFD0A554),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'History',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              history,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Files',
              style: TextStyle(
                color: Color(0xFFD0A554),
                fontSize: 16,
              ),
            ),
            Column(
              children: files.map((file) => _buildFileItem(file)).toList(),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Handle see more action
                },
                child: const Text(
                  'see more →',
                  style: TextStyle(
                    color: Color(0xFFD0A554),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem(String fileName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Checkbox(
            value: false,
            onChanged: (value) {},
            fillColor: MaterialStateProperty.resolveWith<Color>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.selected)) {
                  return const Color(0xFFD0A554);
                }
                return const Color(0xFF3D4559);
              },
            ),
            checkColor: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            fileName,
            style: const TextStyle(
              color: Colors.white,
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
            // Already on clients page
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
          icon: Icon(Icons.people), // Changed from calendar to people
          label: 'Clients',
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
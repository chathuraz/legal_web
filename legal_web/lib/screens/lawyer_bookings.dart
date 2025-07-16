import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LawyerBookings extends StatefulWidget {
  const LawyerBookings({Key? key}) : super(key: key);

  @override
  _LawyerBookingsState createState() => _LawyerBookingsState();
}

class _LawyerBookingsState extends State<LawyerBookings> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _currentIndex = 1;
  String _selectedTab = 'All';
  bool _isLoading = true;
  List<QueryDocumentSnapshot> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      setState(() => _isLoading = true);
      final String lawyerId = _auth.currentUser!.uid;
      
      print('Loading bookings for lawyer: $lawyerId'); // Debug log
      
      // Get all bookings for this lawyer first
      Query query = _firestore
          .collection('bookings')
          .where('lawyerId', isEqualTo: lawyerId);

      // Apply status filter based on selected tab
      if (_selectedTab == 'Pending') {
        query = query.where('status', isEqualTo: 'pending');
      } else if (_selectedTab == 'Accepted') {
        query = query.where('status', isEqualTo: 'accepted');
      } else if (_selectedTab == 'Completed') {
        query = query.where('status', isEqualTo: 'completed');
      }

      try {
        // Try to order by createdAt first
        final QuerySnapshot snapshot = await query
            .orderBy('createdAt', descending: true)
            .get();
        
        setState(() {
          _bookings = snapshot.docs;
          _isLoading = false;
        });
        
        print('Found ${_bookings.length} bookings'); // Debug log
      } catch (e) {
        print('Error with orderBy, trying without: $e');
        
        // If orderBy fails (maybe due to index), get without ordering
        final QuerySnapshot snapshot = await query.get();
        
        // Sort locally
        List<QueryDocumentSnapshot> docs = snapshot.docs;
        docs.sort((a, b) {
          var aData = a.data() as Map<String, dynamic>;
          var bData = b.data() as Map<String, dynamic>;
          var aTime = aData['createdAt'];
          var bTime = bData['createdAt'];
          
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          
          if (aTime is Timestamp && bTime is Timestamp) {
            return bTime.compareTo(aTime);
          }
          return 0;
        });
        
        setState(() {
          _bookings = docs;
          _isLoading = false;
        });
        
        print('Found ${_bookings.length} bookings (sorted locally)'); // Debug log
      }
    } catch (e) {
      print('Error loading bookings: $e');
      
      // Final fallback - get all bookings and filter
      try {
        final QuerySnapshot allBookings = await _firestore
            .collection('bookings')
            .get();
        
        List<QueryDocumentSnapshot> filteredBookings = [];
        for (var doc in allBookings.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          if (data['lawyerId'] == _auth.currentUser!.uid) {
            // Apply tab filter
            if (_selectedTab == 'All' || 
                data['status'] == _selectedTab.toLowerCase() ||
                (_selectedTab == 'Pending' && (data['status'] == null || data['status'] == 'pending'))) {
              filteredBookings.add(doc);
            }
          }
        }
        
        setState(() {
          _bookings = filteredBookings;
          _isLoading = false;
        });
        
        print('Fallback: Found ${_bookings.length} bookings'); // Debug log
      } catch (fallbackError) {
        print('Fallback also failed: $fallbackError');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking $status successfully'),
          backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
        ),
      );
      
      _loadBookings(); // Reload the bookings list
    } catch (e) {
      print('Error updating booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update booking status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  int _getBookingCountForTab(String tab) {
    return _bookings.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      if (tab == 'All') return true;
      return data['status'] == tab.toLowerCase();
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF353E55),
      appBar: AppBar(
        title: const Text(
          'Bookings',
          style: TextStyle(
            color: Color(0xFFD0A554),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF353E55),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFD0A554)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/lawyer/dashboard');
          },
        ),
      ),
      body: Column(
        children: [
          // Tab selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabButton('All', _bookings.length),
                  const SizedBox(width: 8),
                  _buildTabButton('Pending', _getBookingCountForTab('Pending')),
                  const SizedBox(width: 8),
                  _buildTabButton('Accepted', _getBookingCountForTab('Accepted')),
                  const SizedBox(width: 8),
                  _buildTabButton('Completed', _getBookingCountForTab('Completed')),
                ],
              ),
            ),
          ),
          const Divider(color: Color(0xFFD0A554), height: 1),
          
          // Booking cards
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFD0A554)),
                  )
                : _bookings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No bookings found',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedTab == 'All' 
                                  ? 'You don\'t have any bookings yet'
                                  : 'No $_selectedTab bookings found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _bookings.length,
                        itemBuilder: (context, index) {
                          final booking = _bookings[index].data() as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: _buildBookingCard(
                              bookingId: _bookings[index].id,
                              booking: booking,
                            ),
                          );
                        },
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
        _loadBookings(); // Reload bookings when tab changes
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: _selectedTab == title ? const Color(0xFFD0A554) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFD0A554),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: _selectedTab == title ? const Color(0xFF353E55) : const Color(0xFFD0A554),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _selectedTab == title ? const Color(0xFF353E55) : const Color(0xFFD0A554),
                borderRadius: BorderRadius.circular(10),
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
    required String bookingId,
    required Map<String, dynamic> booking,
  }) {
    // Handle different field names that might exist
    final String clientName = booking['userName'] ?? booking['clientName'] ?? 'Unknown Client';
    final String clientEmail = booking['userEmail'] ?? booking['clientEmail'] ?? 'N/A';
    final String clientPhone = booking['userPhone'] ?? booking['clientPhone'] ?? booking['phone'] ?? 'N/A';
    final String consultationType = booking['consultationType'] ?? booking['serviceType'] ?? booking['type'] ?? 'N/A';
    final String description = booking['description'] ?? booking['reason'] ?? 'No description provided';
    final String timeSlot = booking['timeSlot'] ?? booking['time'] ?? 'N/A';
    final String status = booking['status'] ?? 'pending';
    
    // Format date
    String formattedDate = 'N/A';
    if (booking['date'] != null) {
      try {
        if (booking['date'] is Timestamp) {
          final DateTime date = booking['date'].toDate();
          formattedDate = '${date.day}/${date.month}/${date.year}';
        } else if (booking['date'] is String) {
          formattedDate = booking['date'];
        }
      } catch (e) {
        print('Error formatting date: $e');
      }
    }

    return Card(
      color: const Color(0xFF3D4559),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with client name and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    clientName,
                    style: const TextStyle(
                      color: Color(0xFFD0A554),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Booking details
            _buildDetailRow(Icons.calendar_today, 'Date', formattedDate),
            _buildDetailRow(Icons.access_time, 'Time', timeSlot),
            _buildDetailRow(Icons.video_call, 'Type', consultationType),
            _buildDetailRow(Icons.email, 'Email', clientEmail),
            _buildDetailRow(Icons.phone, 'Phone', clientPhone),
            _buildDetailRow(Icons.note, 'Description', description),
            
            // Action buttons for pending bookings
            if (status == 'pending') ...[
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFD0A554)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _updateBookingStatus(bookingId, 'rejected'),
                      child: const Text(
                        'Reject',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD0A554),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _updateBookingStatus(bookingId, 'accepted'),
                      child: const Text(
                        'Accept',
                        style: TextStyle(
                          color: Color(0xFF353E55),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFD0A554), size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'confirmed':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.orange;
    }
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
            Navigator.pushReplacementNamed(context, '/lawyer/dashboard');
            break;
          case 1:
            // Already on bookings page
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/lawyer/availability');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/lawyer/profile');
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF3D4559),
      selectedItemColor: const Color(0xFFD0A554),
      unselectedItemColor: Colors.grey[400],
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
    );
  }
}

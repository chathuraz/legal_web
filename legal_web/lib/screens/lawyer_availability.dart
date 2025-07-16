import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LawyerAvailability extends StatefulWidget {
  const LawyerAvailability({Key? key}) : super(key: key);

  @override
  _LawyerAvailabilityState createState() => _LawyerAvailabilityState();
}

class _LawyerAvailabilityState extends State<LawyerAvailability> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<DocumentSnapshot> _availabilities = [];
  int _currentIndex = 2; // Availability is selected
  DateTime? _selectedDate;
  bool _isAvailable = true;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAvailabilities();
  }

  Future<void> _loadAvailabilities() async {
    try {
      setState(() => _isLoading = true);
      
      final String lawyerId = _auth.currentUser!.uid;
      print('Loading availabilities for lawyer: $lawyerId'); // Debug log
      
      // Try main query first
      try {
        final QuerySnapshot snapshot = await _firestore
            .collection('lawyer_availability')
            .where('lawyerId', isEqualTo: lawyerId)
            .orderBy('date', descending: false)
            .get();

        print('Found ${snapshot.docs.length} availabilities'); // Debug log
        
        setState(() {
          _availabilities = snapshot.docs;
          _isLoading = false;
        });
        
        // Debug: print each availability
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          print('Availability: ${doc.id} - ${data}');
        }
        
      } catch (e) {
        print('Error with orderBy query: $e');
        
        // Fallback without orderBy if index issues
        final QuerySnapshot fallbackSnapshot = await _firestore
            .collection('lawyer_availability')
            .where('lawyerId', isEqualTo: lawyerId)
            .get();
        
        print('Fallback found ${fallbackSnapshot.docs.length} availabilities'); // Debug log
        
        List<DocumentSnapshot> docs = fallbackSnapshot.docs;
        
        // Sort locally by date
        docs.sort((a, b) {
          try {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aDate = aData['date'] as Timestamp;
            final bDate = bData['date'] as Timestamp;
            return aDate.compareTo(bDate);
          } catch (e) {
            print('Error sorting: $e');
            return 0;
          }
        });
        
        setState(() {
          _availabilities = docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Complete error loading availabilities: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading availabilities: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF353E55),
      appBar: AppBar(
        title: const Text('Availability'),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Selection
            _buildSection(
              icon: Icons.calendar_today,
              title: 'Date',
              child: InkWell(
                onTap: _selectDate,
                child: Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : 'Select Date',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Availability Toggle
            _buildSection(
              icon: Icons.event_available,
              title: 'Available',
              child: Switch(
                value: _isAvailable,
                onChanged: (value) {
                  setState(() {
                    _isAvailable = value;
                  });
                },
                activeColor: const Color(0xFFD0A554),
              ),
            ),
            const SizedBox(height: 20),
            
            // Time Slot
            _buildSection(
              icon: Icons.access_time,
              title: 'Add Sections',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _selectStartTime,
                          child: Text(
                            _startTime != null
                                ? _startTime!.format(context)
                                : 'Start Time',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const Text(' to ', style: TextStyle(color: Colors.white)),
                      Expanded(
                        child: InkWell(
                          onTap: _selectEndTime,
                          child: Text(
                            _endTime != null
                                ? _endTime!.format(context)
                                : 'End Time',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // Save Button
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD0A554),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                onPressed: _saveAvailability,
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Color(0xFF353E55),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Existing Availabilities Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Availabilities',
                  style: TextStyle(
                    color: Color(0xFFD0A554),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    print('Refreshing availabilities...'); // Debug log
                    _loadAvailabilities();
                  },
                  icon: const Icon(
                    Icons.refresh,
                    color: Color(0xFFD0A554),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Availabilities List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFD0A554)),
                    )
                  : _availabilities.isEmpty
                      ? const Center(
                          child: Text(
                            'No availabilities set',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _availabilities.length,
                          itemBuilder: (context, index) {
                            final availability = _availabilities[index].data() as Map<String, dynamic>;
                            return _buildAvailabilityCard(availability, _availabilities[index].id);
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFFD0A554)),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFD0A554),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF3D4559),
            borderRadius: BorderRadius.circular(10),
          ),
          child: child,
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD0A554),
              onPrimary: Color(0xFF353E55),
              surface: Color(0xFF3D4559),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD0A554),
              onPrimary: Color(0xFF353E55),
              surface: Color(0xFF3D4559),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD0A554),
              onPrimary: Color(0xFF353E55),
              surface: Color(0xFF3D4559),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  Future<void> _saveAvailability() async {
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date and time slots'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      
      final String lawyerId = _auth.currentUser!.uid;
      
      // Convert TimeOfDay to string for storage
      final String startTimeStr = '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}';
      final String endTimeStr = '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}';

      // Generate time slots (30-minute intervals)
      List<String> timeSlots = _generateTimeSlots(_startTime!, _endTime!);

      // Check for existing availability on this date
      final QuerySnapshot existingSlots = await _firestore
          .collection('lawyer_availability')
          .where('lawyerId', isEqualTo: lawyerId)
          .where('date', isEqualTo: Timestamp.fromDate(_selectedDate!))
          .get();

      if (existingSlots.docs.isNotEmpty) {
        // Update existing availability
        await _firestore.collection('lawyer_availability')
            .doc(existingSlots.docs.first.id)
            .update({
          'isAvailable': _isAvailable,
          'startTime': startTimeStr,
          'endTime': endTimeStr,
          'timeSlots': timeSlots,
          'availableSlots': timeSlots,
          'updatedAt': FieldValue.serverTimestamp(),
          'status': 'active', // Add this for consistency
        });
      } else {
        // Create new availability
        await _firestore.collection('lawyer_availability').add({
          'lawyerId': lawyerId,
          'date': Timestamp.fromDate(_selectedDate!),
          'isAvailable': _isAvailable,
          'startTime': startTimeStr,
          'endTime': endTimeStr,
          'timeSlots': timeSlots,
          'availableSlots': timeSlots,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'status': 'active'
        });
      }

      // Reload availabilities
      await _loadAvailabilities();

      // Reset form
      setState(() {
        _selectedDate = null;
        _startTime = null;
        _endTime = null;
        _isAvailable = true;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Availability saved successfully'),
          backgroundColor: Color(0xFFD0A554),
        ),
      );
    } catch (e) {
      print('Error saving availability: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving availability: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<String> _generateTimeSlots(TimeOfDay startTime, TimeOfDay endTime) {
    List<String> slots = [];
    
    // Convert TimeOfDay to minutes for easier calculation
    int startMinutes = startTime.hour * 60 + startTime.minute;
    int endMinutes = endTime.hour * 60 + endTime.minute;
    
    // Generate 30-minute slots
    for (int minutes = startMinutes; minutes < endMinutes; minutes += 30) {
      int hours = minutes ~/ 60;
      int mins = minutes % 60;
      
      int nextMinutes = minutes + 30;
      int nextHours = nextMinutes ~/ 60;
      int nextMins = nextMinutes % 60;
      
      String startTimeStr = '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
      String endTimeStr = '${nextHours.toString().padLeft(2, '0')}:${nextMins.toString().padLeft(2, '0')}';
      
      slots.add('$startTimeStr - $endTimeStr');
    }
    
    return slots;
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        if (_currentIndex != index) {
          setState(() => _currentIndex = index);
          
          switch (index) {
            case 0: // Dashboard
              Navigator.pushReplacementNamed(context, '/lawyer/dashboard');
              break;
            case 1: // Bookings
              Navigator.pushReplacementNamed(context, '/lawyer/bookings');
              break;
            case 2: // Availability
              // Already on availability page
              break;
            case 3: // Profile
              Navigator.pushReplacementNamed(context, '/lawyer/profile');
              break;
          }
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

  Widget _buildAvailabilityCard(Map<String, dynamic> availability, String docId) {
    print('Building availability card for: $availability'); // Debug log
    
    final date = (availability['date'] as Timestamp).toDate();
    final dateStr = '${date.day}/${date.month}/${date.year}';
    final startTime = availability['startTime'] ?? 'N/A';
    final endTime = availability['endTime'] ?? 'N/A';
    final timeSlots = List<String>.from(availability['timeSlots'] ?? []);
    final availableSlots = List<String>.from(availability['availableSlots'] ?? []);
    final isAvailable = availability['isAvailable'] ?? false;

    print('Date: $dateStr, Available: $isAvailable, Slots: ${timeSlots.length}'); // Debug log
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF3D4559),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: Color(0xFFD0A554),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAvailable ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAvailable ? 'Available' : 'Unavailable',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Time: $startTime - $endTime',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Available Slots: ${availableSlots.length}/${timeSlots.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            if (timeSlots.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Time Slots:',
                style: TextStyle(
                  color: Color(0xFFD0A554),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: timeSlots.map((slot) {
                  final isSlotAvailable = availableSlots.contains(slot);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSlotAvailable ? const Color(0xFFD0A554) : Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                      child: Text(
                        slot,
                        style: TextStyle(
                          color: isSlotAvailable ? const Color(0xFF353E55) : Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created: ${_formatTimestamp(availability['createdAt'])}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
                TextButton(
                  onPressed: () => _deleteAvailability(docId),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Add this helper method to format timestamps:
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      print('Error formatting timestamp: $e');
    }
    
    return 'Unknown';
  }

  Future<void> _deleteAvailability(String docId) async {
    try {
      await _firestore.collection('lawyer_availability').doc(docId).delete();
      await _loadAvailabilities();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Availability deleted successfully'),
          backgroundColor: Color(0xFFD0A554),
        ),
      );
    } catch (e) {
      print('Error deleting availability: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error deleting availability'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
import 'lawyer_chat_list.dart';

class LawyerDashboardScreen extends StatefulWidget {
  const LawyerDashboardScreen({Key? key}) : super(key: key);

  @override
  _LawyerDashboardScreenState createState() => _LawyerDashboardScreenState();
}

class _LawyerDashboardScreenState extends State<LawyerDashboardScreen> {
  int _currentIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? lawyerData;
  bool isLoading = true;
  List<Map<String, dynamic>> _recentBookings = [];
  
  // Chat-related variables
  List<Map<String, dynamic>> _recentChats = [];
  bool _isLoadingChats = false;
  int _totalUnreadMessages = 0;

  @override
  void initState() {
    super.initState();
    _loadLawyerData();
    _fetchBookings();
    _fetchRecentChats(); // Add chat loading
  }

  Future<void> _loadLawyerData() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final DocumentSnapshot doc = await _firestore
            .collection('lawyers')
            .doc(currentUser.uid)
            .get();

        if (doc.exists) {
          setState(() {
            lawyerData = doc.data() as Map<String, dynamic>;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading lawyer data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Add chat fetching functionality
  Future<void> _fetchRecentChats() async {
    try {
      setState(() => _isLoadingChats = true);
      
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        print('Loading chats for lawyer: ${currentUser.uid}');
        
        // First, get all chats where this lawyer is a participant
        final chatsSnapshot = await _firestore
            .collection('chats')
            .where('participants', arrayContains: currentUser.uid)
            .get(); // Remove the orderBy temporarily to avoid index requirement

        print('Found ${chatsSnapshot.docs.length} chats');

        List<Map<String, dynamic>> chats = [];
        int totalUnread = 0;
        
        for (var doc in chatsSnapshot.docs) {
          Map<String, dynamic> chat = doc.data();
          chat['id'] = doc.id;
          
          // Get the other participant (client) info
          final participants = List<String>.from(chat['participants'] ?? []);
          final otherParticipantId = participants.firstWhere(
            (id) => id != currentUser.uid,
            orElse: () => '',
          );
          
          if (otherParticipantId.isNotEmpty) {
            // Get client name from users collection
            try {
              final userDoc = await _firestore.collection('users').doc(otherParticipantId).get();
              if (userDoc.exists) {
                final userData = userDoc.data() as Map<String, dynamic>;
                chat['clientName'] = userData['name'] ?? 'Unknown Client';
                chat['clientEmail'] = userData['email'] ?? '';
                chat['clientProfileImage'] = userData['profileImage'];
              } else {
                chat['clientName'] = 'Unknown Client';
              }
            } catch (e) {
              chat['clientName'] = 'Unknown Client';
            }
            
            chat['clientId'] = otherParticipantId;
            
            // Count unread messages for this lawyer
            final unreadCount = (chat['unreadCount'] as Map<String, dynamic>?)?[currentUser.uid] ?? 0;
            totalUnread += unreadCount as int;
            
            chats.add(chat);
          }
        }

        // Sort chats by lastMessageTime locally
        chats.sort((a, b) {
          final aTime = a['lastMessageTime'] as Timestamp?;
          final bTime = b['lastMessageTime'] as Timestamp?;
          
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          
          return bTime.compareTo(aTime); // Descending order
        });

        // Take only the latest 3 chats for dashboard
        if (chats.length > 3) {
          chats = chats.take(3).toList();
        }

        setState(() {
          _recentChats = chats;
          _totalUnreadMessages = totalUnread;
          _isLoadingChats = false;
        });
        
        print('Loaded ${chats.length} chats with $totalUnread total unread messages');
      }
    } catch (e) {
      print('Error fetching chats: $e');
      setState(() => _isLoadingChats = false);
    }
  }

  Future<void> _fetchBookings() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        print('Current lawyer ID: ${currentUser.uid}');
        
        final bookingsSnapshot = await _firestore
            .collection('bookings')
            .where('lawyerId', isEqualTo: currentUser.uid)
            .orderBy('createdAt', descending: true)
            .limit(5)
            .get();

        print('Found ${bookingsSnapshot.docs.length} bookings');

        List<Map<String, dynamic>> bookings = [];
        for (var doc in bookingsSnapshot.docs) {
          Map<String, dynamic> booking = doc.data();
          booking['id'] = doc.id;
          bookings.add(booking);
          print('Booking: ${booking['userName'] ?? booking['clientName']} - ${booking['status']}');
        }

        setState(() {
          _recentBookings = bookings;
        });
      }
    } catch (e) {
      print('Error fetching bookings: $e');
      
      // Fallback: Get all bookings and filter locally
      try {
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          final allBookingsSnapshot = await _firestore
              .collection('bookings')
              .get();

          List<Map<String, dynamic>> bookings = [];
          for (var doc in allBookingsSnapshot.docs) {
            Map<String, dynamic> booking = doc.data();
            
            // Check if this booking belongs to current lawyer
            if (booking['lawyerId'] == currentUser.uid) {
              booking['id'] = doc.id;
              bookings.add(booking);
            }
          }

          // Sort by creation date (newest first)
          bookings.sort((a, b) {
            var aTime = a['createdAt'];
            var bTime = b['createdAt'];
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            
            if (aTime is Timestamp && bTime is Timestamp) {
              return bTime.compareTo(aTime);
            }
            return 0;
          });

          // Take only the latest 5
          if (bookings.length > 5) {
            bookings = bookings.take(5).toList();
          }

          setState(() {
            _recentBookings = bookings;
          });
          
          print('Fallback: Found ${bookings.length} bookings for lawyer');
        }
      } catch (fallbackError) {
        print('Fallback also failed: $fallbackError');
      }
    }
  }

  // New method to build the stats section with real-time data
  Widget _buildRealtimeStatsSection() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    // Stream for bookings to count pending and completed cases
    final bookingsStream = _firestore
        .collection('bookings')
        .where('lawyerId', isEqualTo: currentUser.uid)
        .snapshots();

    // Stream for chats to count total clients
    final chatsStream = _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: bookingsStream,
      builder: (context, bookingsSnapshot) {
        int pendingCases = 0;
        int completedCases = 0;

        if (bookingsSnapshot.hasData) {
          for (var doc in bookingsSnapshot.data!.docs) {
            final status = doc['status'] as String?;
            if (status == 'pending') {
              pendingCases++;
            } else if (status == 'completed' || status == 'accepted') {
              completedCases++;
            }
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: chatsStream,
          builder: (context, chatsSnapshot) {
            int totalClients = 0;
            if (chatsSnapshot.hasData) {
              totalClients = chatsSnapshot.data!.docs.length;
            }

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF3D4559),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Total Clients', totalClients.toString()),
                  _buildStatItem('Pending Cases', pendingCases.toString()),
                  _buildStatItem('Completed Cases', completedCases.toString()),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF353E55),
      appBar: AppBar(
        title: Text(
          lawyerData?['name'] ?? 'Lawyer Dashboard',
          style: const TextStyle(
            color: Color(0xFFD0A554),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF353E55),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFD0A554)),
        actions: [
          // Add messages icon with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LawyerChatList()),
                  );
                },
              ),
              if (_totalUnreadMessages > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _totalUnreadMessages > 99 ? '99+' : _totalUnreadMessages.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await _auth.signOut();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/lawyer/signin');
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error signing out: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD0A554)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lawyer Stats Section
                  _buildRealtimeStatsSection(),
                  const SizedBox(height: 24),
                  
                  // Quick Actions Section
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      color: Color(0xFFD0A554),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Container(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildCompactDashboardItem(Icons.person, 'Profile', const Color(0xFFD0A554), () {
                          Navigator.pushNamed(context, '/lawyer/profile');
                        }),
                        _buildCompactDashboardItem(Icons.calendar_today, 'Bookings', const Color(0xFF6C8EBF), () {
                          Navigator.pushNamed(context, '/lawyer/bookings');
                        }),
                        _buildCompactDashboardItem(Icons.access_time, 'Availability', const Color(0xFF82B366), () {
                          Navigator.pushNamed(context, '/lawyer/availability');
                        }),
                        // Add Messages quick action with badge
                        _buildCompactDashboardItemWithBadge(
                          Icons.chat_bubble_outline, 
                          'Messages', 
                          const Color(0xFFE06B7D), 
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LawyerChatList()),
                            );
                          },
                          _totalUnreadMessages,
                        ),
                        _buildCompactDashboardItem(Icons.people, 'Clients', const Color(0xFFD6B656), () {
                          Navigator.pushNamed(context, '/lawyer/clients');
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recent Messages Section
                  _buildRecentChatsSection(),
                  const SizedBox(height: 24),

                  // Recent Bookings Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Bookings',
                        style: TextStyle(
                          color: Color(0xFFD0A554),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/lawyer/bookings');
                        },
                        child: const Text(
                          'View All',
                          style: TextStyle(color: Color(0xFFD0A554)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Recent Bookings List
                  _recentBookings.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3D4559),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Center(
                            child: Text(
                              'No recent bookings',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: _recentBookings.map((booking) {
                            return _buildBookingCard(booking);
                          }).toList(),
                        ),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // Recent Chats Section
  Widget _buildRecentChatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Recent Messages',
                  style: TextStyle(
                    color: Color(0xFFD0A554),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_totalUnreadMessages > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _totalUnreadMessages.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LawyerChatList()),
                );
              },
              child: const Text(
                'View All',
                style: TextStyle(color: Color(0xFFD0A554)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (_isLoadingChats)
          const Center(
            child: CircularProgressIndicator(color: Color(0xFFD0A554)),
          )
        else if (_recentChats.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF3D4559),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white54,
                    size: 48,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No messages yet',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Client messages will appear here',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: _recentChats.map((chat) => _buildChatPreviewCard(chat)).toList(),
          ),
      ],
    );
  }

  // Chat Preview Card
  Widget _buildChatPreviewCard(Map<String, dynamic> chat) {
    final clientName = chat['clientName'] ?? 'Unknown Client';
    final lastMessage = chat['lastMessage'] ?? '';
    final lastMessageTime = chat['lastMessageTime'] as Timestamp?;
    final unreadCount = (chat['unreadCount'] as Map<String, dynamic>?)?[_auth.currentUser!.uid] ?? 0;
    final clientProfileImage = chat['clientProfileImage'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFF3D4559),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Mark messages as read when opening chat
          _markMessagesAsRead(chat['id']);
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                lawyerId: chat['clientId'],
                lawyerName: clientName,
                lawyerProfileImage: clientProfileImage,
              ),
            ),
          ).then((_) {
            // Refresh chats when returning from chat screen
            _fetchRecentChats();
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Client Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF6C8EBF),
                    backgroundImage: clientProfileImage != null 
                        ? NetworkImage(clientProfileImage)
                        : null,
                    child: clientProfileImage == null
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 24,
                          )
                        : null,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              
              // Message Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            clientName,
                            style: TextStyle(
                              color: const Color(0xFFD0A554),
                              fontSize: 14,
                              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (lastMessageTime != null)
                          Text(
                            _formatChatTime(lastMessageTime.toDate()),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMessage.isEmpty ? 'No messages yet' : lastMessage,
                      style: TextStyle(
                        color: lastMessage.isEmpty ? Colors.white54 : Colors.white70,
                        fontSize: 12,
                        fontStyle: lastMessage.isEmpty ? FontStyle.italic : FontStyle.normal,
                        fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Arrow icon
              Icon(
                Icons.chevron_right,
                color: unreadCount > 0 ? const Color(0xFFD0A554) : Colors.white54,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Mark messages as read
  Future<void> _markMessagesAsRead(String chatId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.${_auth.currentUser!.uid}': 0,
      });
      
      // Refresh chat data
      _fetchRecentChats();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Format chat time helper
  String _formatChatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.day}/${dateTime.month}';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Existing methods remain the same...
  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD0A554),
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactDashboardItem(IconData icon, String title, Color color, VoidCallback onTap) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF3D4559),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 24, color: color),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // New method for dashboard item with badge
  Widget _buildCompactDashboardItemWithBadge(IconData icon, String title, Color color, VoidCallback onTap, int badgeCount) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF3D4559),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Icon(icon, size: 24, color: color),
                    if (badgeCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            badgeCount > 99 ? '99+' : badgeCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
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
                Expanded(
                  child: Text(
                    booking['userName'] ?? booking['clientName'] ?? 'Unknown Client',
                    style: const TextStyle(
                      color: Color(0xFFD0A554),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking['status'] ?? 'pending'),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(booking['status'] ?? 'pending'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.calendar_today, 'Date', _formatDate(booking['date'])),
            _buildDetailRow(Icons.access_time, 'Time', booking['timeSlot'] ?? booking['time'] ?? 'N/A'),
            _buildDetailRow(Icons.video_call, 'Type', booking['consultationType'] ?? booking['type'] ?? 'N/A'),
            if (booking['description'] != null && booking['description'].toString().isNotEmpty)
              _buildDetailRow(Icons.note, 'Issue', booking['description'] ?? booking['reason'] ?? 'N/A'),
            
            if (booking['status'] == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () => _updateBookingStatus(booking['id'], 'accepted'),
                      child: const Text(
                        'Accept',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () => _updateBookingStatus(booking['id'], 'rejected'),
                      child: const Text(
                        'Reject',
                        style: TextStyle(color: Colors.white, fontSize: 12),
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
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD0A554), size: 14),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
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

  String _getStatusText(String status) {
    return status.toUpperCase();
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    
    try {
      if (date is Timestamp) {
        final DateTime dateTime = date.toDate();
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      } else if (date is String) {
        return date;
      }
    } catch (e) {
      print('Error formatting date: $e');
    }
    
    return 'N/A';
  }

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    try {
      print('Updating booking $bookingId to status: $status');
      
      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Successfully updated booking status');

      await _fetchBookings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking $status successfully'),
            backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error updating booking status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error updating booking status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        if (_currentIndex != index) {
          setState(() => _currentIndex = index);

          switch (index) {
            case 0: // Dashboard
              // Already on dashboard, do nothing
              break;
            case 1: // Bookings
              Navigator.pushNamed(context, '/lawyer/bookings');
              break;
            case 2: // Availability
              Navigator.pushNamed(context, '/lawyer/availability');
              break;
            case 3: // Profile
              Navigator.pushNamed(context, '/lawyer/profile');
              break;
          }
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF3D4559),
      selectedItemColor: const Color(0xFFD0A554),
      unselectedItemColor: Colors.grey[400],
      showSelectedLabels: true,
      showUnselectedLabels: true,
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
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import 'client_details_screen.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({Key? key}) : super(key: key);

  @override
  _ClientsPageState createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF353E55),
      appBar: AppBar(
        title: const Text('Active Clients'),
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
      // MODIFIED: Show real-time active clients with chat integration
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('chats')
            .where('participants', arrayContains: _auth.currentUser!.uid)
            .snapshots(),
        builder: (context, chatsSnapshot) {
          if (chatsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFD0A554)));
          }
          if (chatsSnapshot.hasError) {
            return Center(child: Text('Error: ${chatsSnapshot.error}', style: const TextStyle(color: Colors.white)));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('bookings')
                .where('lawyerId', isEqualTo: _auth.currentUser!.uid)
                .snapshots(),
            builder: (context, bookingsSnapshot) {
              if (bookingsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFD0A554)));
              }
              if (bookingsSnapshot.hasError) {
                return Center(child: Text('Error: ${bookingsSnapshot.error}', style: const TextStyle(color: Colors.white)));
              }

              // Combine chat and booking data for active clients
              final activeClients = _combineClientData(chatsSnapshot.data, bookingsSnapshot.data);

              if (activeClients.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No active clients',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      Text(
                        'Clients with ongoing cases will appear here',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  itemCount: activeClients.length,
                  itemBuilder: (context, index) {
                    final client = activeClients[index];
                    return _buildActiveClientCard(client);
                  },
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // NEW: Combine chat and booking data to show active clients
  List<Map<String, dynamic>> _combineClientData(QuerySnapshot? chatsSnapshot, QuerySnapshot? bookingsSnapshot) {
    final Map<String, Map<String, dynamic>> clientsMap = {};
    final currentUserId = _auth.currentUser!.uid;

    // Process chats to get recent activity
    if (chatsSnapshot != null) {
      for (final chatDoc in chatsSnapshot.docs) {
        final chatData = chatDoc.data() as Map<String, dynamic>;
        final participants = List<String>.from(chatData['participants'] ?? []);
        
        // Find the client (non-lawyer participant)
        final clientId = participants.firstWhere(
          (id) => id != currentUserId,
          orElse: () => '',
        );
        
        if (clientId.isNotEmpty) {
          final participantNames = chatData['participantNames'] as Map<String, dynamic>? ?? {};
          final lastMessage = chatData['lastMessage'] as String? ?? '';
          final lastMessageTime = chatData['lastMessageTime'] as Timestamp?;
          final unreadCount = (chatData['unreadCount'] as Map<String, dynamic>?)?[currentUserId] ?? 0;

          clientsMap[clientId] = {
            'clientId': clientId,
            'clientName': participantNames[clientId] ?? 'Unknown Client',
            'chatId': chatDoc.id,
            'lastMessage': lastMessage,
            'lastMessageTime': lastMessageTime,
            'unreadCount': unreadCount,
            'hasActiveChat': true,
            'consultationType': 'Chat Active',
            'caseStatus': 'In Progress',
            'documents': <String>[],
          };
        }
      }
    }

    // Process bookings to get case information
    if (bookingsSnapshot != null) {
      for (final bookingDoc in bookingsSnapshot.docs) {
        final bookingData = bookingDoc.data() as Map<String, dynamic>;
        final status = bookingData['status'] as String?;
        final clientId = bookingData['clientId'] as String?;
        
        // Only include accepted/ongoing cases
        if ((status == 'accepted' || status == 'pending') && clientId != null) {
          final existing = clientsMap[clientId];
          
          if (existing != null) {
            // Update existing chat client with booking info
            existing['consultationType'] = bookingData['consultationType'] ?? 'General';
            existing['caseStatus'] = status == 'accepted' ? 'Active Case' : 'Pending';
            existing['bookingDate'] = bookingData['date'];
            existing['timeSlot'] = bookingData['timeSlot'];
            existing['documents'] = List<String>.from(bookingData['documents'] ?? []);
          } else {
            // Add client with booking but no recent chat
            clientsMap[clientId] = {
              'clientId': clientId,
              'clientName': bookingData['clientName'] ?? 'Unknown Client',
              'chatId': null,
              'lastMessage': 'No recent messages',
              'lastMessageTime': null,
              'unreadCount': 0,
              'hasActiveChat': false,
              'consultationType': bookingData['consultationType'] ?? 'General',
              'caseStatus': status == 'accepted' ? 'Active Case' : 'Pending',
              'bookingDate': bookingData['date'],
              'timeSlot': bookingData['timeSlot'],
              'documents': List<String>.from(bookingData['documents'] ?? []),
            };
          }
        }
      }
    }

    // Convert to list and sort by activity (chats first, then by last message time)
    final clientsList = clientsMap.values.toList();
    clientsList.sort((a, b) {
      // Prioritize clients with active chats and unread messages
      if (a['unreadCount'] > 0 && b['unreadCount'] == 0) return -1;
      if (b['unreadCount'] > 0 && a['unreadCount'] == 0) return 1;
      
      // Then by last message time
      final aTime = a['lastMessageTime'] as Timestamp?;
      final bTime = b['lastMessageTime'] as Timestamp?;
      
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      
      return bTime.compareTo(aTime);
    });

    return clientsList;
  }

  // MODIFIED: Build card for active clients with real-time info
  Widget _buildActiveClientCard(Map<String, dynamic> client) {
    final hasUnread = client['unreadCount'] > 0;
    final lastMessageTime = client['lastMessageTime'] as Timestamp?;
    final timeString = lastMessageTime != null ? _formatTime(lastMessageTime.toDate()) : 'No activity';
    
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
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        client['clientName'],
                        style: const TextStyle(
                          color: Color(0xFFD0A554),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${client['unreadCount']}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  timeString,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  client['hasActiveChat'] ? Icons.chat_bubble : Icons.event_note,
                  color: client['hasActiveChat'] ? Colors.green : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${client['consultationType']} • ${client['caseStatus']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (client['lastMessage'].isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                client['lastMessage'],
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (client['documents'].isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.attach_file, color: Color(0xFFD0A554), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${client['documents'].length} files',
                        style: const TextStyle(color: Color(0xFFD0A554), fontSize: 12),
                      ),
                    ],
                  ),
                Row(
                  children: [
                    if (client['hasActiveChat'])
                      ElevatedButton.icon(
                        onPressed: () {
                          // FIXED: Navigate to chat with correct parameters
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                lawyerId: client['clientId'], // This is the client's ID
                                lawyerName: client['clientName'], // This is the client's name
                                lawyerProfileImage: null, // You can add profile image logic later
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat, size: 16),
                        label: const Text('Chat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD0A554),
                          foregroundColor: const Color(0xFF353E55),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        ),
                      ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        // UPDATED: Navigate to client details screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClientDetailsScreen(
                              clientId: client['clientId'],
                              clientName: client['clientName'],
                              clientData: client,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'View Details →',
                        style: TextStyle(
                          color: Color(0xFFD0A554),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
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
          icon: Icon(Icons.people),
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

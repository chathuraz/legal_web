import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClientDetailsScreen extends StatefulWidget {
  final String clientId;
  final String clientName;
  final Map<String, dynamic> clientData;

  const ClientDetailsScreen({
    Key? key,
    required this.clientId,
    required this.clientName,
    required this.clientData,
  }) : super(key: key);

  @override
  _ClientDetailsScreenState createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _fullClientData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClientDetails();
  }

  Future<void> _loadClientDetails() async {
    try {
      // Fetch full client data from users collection
      final clientDoc = await _firestore.collection('users').doc(widget.clientId).get();
      
      if (clientDoc.exists) {
        setState(() {
          _fullClientData = clientDoc.data();
          _isLoading = false;
        });
      } else {
        setState(() {
          _fullClientData = {};
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading client details: $e');
      setState(() {
        _fullClientData = {};
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF353E55),
      appBar: AppBar(
        title: Text(widget.clientName),
        backgroundColor: const Color(0xFF353E55),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFD0A554)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD0A554)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildClientInfoCard(),
                  const SizedBox(height: 16),
                  _buildCaseInfoCard(),
                  const SizedBox(height: 16),
                  _buildCommunicationCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildClientInfoCard() {
    final clientData = _fullClientData ?? {};
    
    return Card(
      color: const Color(0xFF3D4559),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Color(0xFFD0A554)),
                const SizedBox(width: 8),
                const Text(
                  'Client Information',
                  style: TextStyle(
                    color: Color(0xFFD0A554),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(color: Color(0xFFD0A554)),
            const SizedBox(height: 12),
            _buildInfoRow('Full Name', clientData['name'] ?? widget.clientName),
            _buildInfoRow('Email', clientData['email'] ?? 'Not provided'),
            _buildInfoRow('Phone', clientData['phone'] ?? 'Not provided'),
            _buildInfoRow('Address', clientData['address'] ?? 'Not provided'),
            _buildInfoRow('Date of Birth', clientData['dateOfBirth'] ?? 'Not provided'),
            _buildInfoRow('Occupation', clientData['occupation'] ?? 'Not provided'),
            _buildInfoRow('Emergency Contact', clientData['emergencyContact'] ?? 'Not provided'),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseInfoCard() {
    final caseData = widget.clientData;
    
    return Card(
      color: const Color(0xFF3D4559),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.gavel, color: Color(0xFFD0A554)),
                const SizedBox(width: 8),
                const Text(
                  'Case Information',
                  style: TextStyle(
                    color: Color(0xFFD0A554),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(color: Color(0xFFD0A554)),
            const SizedBox(height: 12),
            _buildInfoRow('Consultation Type', caseData['consultationType'] ?? 'Not specified'),
            _buildInfoRow('Case Status', caseData['caseStatus'] ?? 'Not specified'),
            if (caseData['bookingDate'] != null)
              _buildInfoRow('Booking Date', _formatDate(caseData['bookingDate'])),
            if (caseData['timeSlot'] != null)
              _buildInfoRow('Time Slot', caseData['timeSlot']),
            _buildInfoRow('Last Activity', caseData['lastMessageTime'] != null 
                ? _formatTime((caseData['lastMessageTime'] as Timestamp).toDate()) 
                : 'No recent activity'),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunicationCard() {
    return Card(
      color: const Color(0xFF3D4559),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.chat, color: Color(0xFFD0A554)),
                const SizedBox(width: 8),
                const Text(
                  'Communication',
                  style: TextStyle(
                    color: Color(0xFFD0A554),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(color: Color(0xFFD0A554)),
            const SizedBox(height: 12),
            _buildInfoRow('Unread Messages', '${widget.clientData['unreadCount'] ?? 0}'),
            _buildInfoRow('Last Message', widget.clientData['lastMessage'] ?? 'No messages'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
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

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      final dateTime = date.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    return date.toString();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
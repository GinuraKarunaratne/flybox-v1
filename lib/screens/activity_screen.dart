// lib/screens/activity_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'journey_detail_screen.dart';
import 'booking_detail_screen.dart';

class ActivityScreen extends StatefulWidget {
  @override
  _ActivityScreenState createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _daysUntil(String dateString) {
    try {
      // Parse date format: "DD/MM/YYYY"
      final parts = dateString.split('/');
      if (parts.length != 3) return 0;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      final targetDate = DateTime(year, month, day);
      final now = DateTime.now();
      final difference = targetDate.difference(DateTime(now.year, now.month, now.day));

      return difference.inDays;
    } catch (e) {
      return 0;
    }
  }


  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(color: const Color(0xFF006CD5)),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Activity',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontFamily: 'Instrument Sans',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: user == null
                      ? Center(child: Text('Please login'))
                      : Column(
                          children: [
                            // Tabs
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildTab('My Journeys', 0),
                                  ),
                                  Expanded(
                                    child: _buildTab('My Bookings', 1),
                                  ),
                                ],
                              ),
                            ),

                            // Content
                            Expanded(
                              child: _buildTabContent(user.uid),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _selectedTab = 0;

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Color(0xFF006CD5) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Instrument Sans',
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Color(0xFF006CD5) : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(String userId) {
    if (_selectedTab == 0) {
      return _buildMyJourneys(userId);
    } else {
      return _buildMyBookings(userId);
    }
  }

  Widget _buildMyJourneys(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('journeys')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.flight_takeoff, size: 64, color: Colors.grey.withOpacity(0.3)),
                SizedBox(height: 16),
                Text(
                  'No journeys yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Instrument Sans',
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Create a journey to start earning',
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'Instrument Sans',
                    color: Colors.black38,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final daysLeft = _daysUntil(data['date'] ?? '');

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JourneyDetailScreen(
                      journeyId: doc.id,
                      journeyData: data,
                    ),
                  ),
                );
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${data['from']} → ${data['to']}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Instrument Sans',
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${data['date']} at ${data['time']}',
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: 'Instrument Sans',
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (daysLeft >= 0)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: daysLeft <= 1
                                ? Colors.orange.withOpacity(0.1)
                                : Color(0xFF006CD5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$daysLeft',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Instrument Sans',
                                  color: daysLeft <= 1 ? Colors.orange : Color(0xFF006CD5),
                                ),
                              ),
                              Text(
                                'days left',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'Instrument Sans',
                                  color: daysLeft <= 1 ? Colors.orange : Color(0xFF006CD5),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.inventory_2_outlined,
                        '${data['remainingWeight'] ?? data['availableWeight']}kg available',
                      ),
                      SizedBox(width: 8),
                      _buildInfoChip(
                        Icons.bookmark_outline,
                        '${data['totalBookings'] ?? 0} bookings',
                      ),
                    ],
                  ),
                ],
              ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMyBookings(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('bookings')
          .where('senderId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.withOpacity(0.3)),
                SizedBox(height: 16),
                Text(
                  'No bookings yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Instrument Sans',
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Browse journeys to send a package',
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'Instrument Sans',
                    color: Colors.black38,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final route = data['route'] as Map<String, dynamic>?;
            final packageDetails = data['packageDetails'] as Map<String, dynamic>?;
            final daysLeft = _daysUntil(route?['date'] ?? '');

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingDetailScreen(
                      bookingId: doc.id,
                      bookingData: data,
                    ),
                  ),
                );
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${route?['from']} → ${route?['to']}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Instrument Sans',
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Traveler: ${data['travelerName'] ?? 'Unknown'}',
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: 'Instrument Sans',
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusBgColor(data['status'] ?? 'pending'),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          (data['status'] ?? 'pending').toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Instrument Sans',
                            color: _getStatusTextColor(data['status'] ?? 'pending'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  if (daysLeft >= 0 && daysLeft <= 7)
                    Container(
                      padding: EdgeInsets.all(8),
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.orange),
                          SizedBox(width: 6),
                          Text(
                            '$daysLeft days until delivery',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Instrument Sans',
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.category_outlined,
                        packageDetails?['packageType'] ?? 'N/A',
                      ),
                      SizedBox(width: 8),
                      _buildInfoChip(
                        Icons.scale_outlined,
                        '${packageDetails?['weight'] ?? 0}kg',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            );
          },
        );
      },
    );
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.withOpacity(0.1);
      case 'active':
        return Colors.blue.withOpacity(0.1);
      case 'completed':
        return Colors.green.withOpacity(0.1);
      case 'cancelled':
        return Colors.red.withOpacity(0.1);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade700;
      case 'active':
        return Colors.blue.shade700;
      case 'completed':
        return Colors.green.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black54),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'Instrument Sans',
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

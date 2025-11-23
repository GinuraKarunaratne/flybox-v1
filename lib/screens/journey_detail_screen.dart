// lib/screens/journey_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JourneyDetailScreen extends StatefulWidget {
  final String journeyId;
  final Map<String, dynamic> journeyData;

  const JourneyDetailScreen({
    Key? key,
    required this.journeyId,
    required this.journeyData,
  }) : super(key: key);

  @override
  State<JourneyDetailScreen> createState() => _JourneyDetailScreenState();
}

class _JourneyDetailScreenState extends State<JourneyDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  int _daysUntil(String dateString) {
    try {
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

  Future<void> _handleBookingAction(String bookingId, String action) async {
    setState(() => _isLoading = true);

    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': action == 'accept' ? 'accepted' : 'rejected',
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Create notification for sender
      final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
      final bookingData = bookingDoc.data();

      await _firestore.collection('notifications').add({
        'userId': bookingData?['senderId'],
        'title': action == 'accept' ? 'Booking Accepted!' : 'Booking Rejected',
        'message': action == 'accept'
            ? 'Your booking has been accepted by the traveler'
            : 'Your booking has been rejected by the traveler',
        'type': 'booking_status',
        'bookingId': bookingId,
        'isRead': false,
        'priority': 'high',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking ${action}ed successfully'),
            backgroundColor: action == 'accept' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelJourney() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Cancel Journey?', style: TextStyle(fontFamily: 'Instrument Sans')),
        content: Text(
          'This will cancel your journey and notify all senders who booked with you.',
          style: TextStyle(fontFamily: 'Instrument Sans'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: TextStyle(fontFamily: 'Instrument Sans')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Yes, Cancel',
              style: TextStyle(fontFamily: 'Instrument Sans', color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await _firestore.collection('journeys').doc(widget.journeyId).update({
        'status': 'cancelled',
        'isAvailable': false,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Notify all bookings
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('journeyId', isEqualTo: widget.journeyId)
          .get();

      for (var doc in bookingsSnapshot.docs) {
        await _firestore.collection('notifications').add({
          'userId': doc.data()['senderId'],
          'title': 'Journey Cancelled',
          'message': 'The journey you booked has been cancelled by the traveler',
          'type': 'journey_cancelled',
          'isRead': false,
          'priority': 'high',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Journey cancelled'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysLeft = _daysUntil(widget.journeyData['date'] ?? '');

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
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Journey Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontFamily: 'Instrument Sans',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    if (daysLeft >= 0)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              '$daysLeft days',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Instrument Sans',
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
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
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Route Card
                              Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF006CD5), Color(0xFF0052A3)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'FROM',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontFamily: 'Instrument Sans',
                                                  color: Colors.white.withOpacity(0.8),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                widget.journeyData['from'] ?? '',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700,
                                                  fontFamily: 'Instrument Sans',
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.arrow_forward, color: Colors.white, size: 32),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'TO',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontFamily: 'Instrument Sans',
                                                  color: Colors.white.withOpacity(0.8),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                widget.journeyData['to'] ?? '',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700,
                                                  fontFamily: 'Instrument Sans',
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildInfoChip(
                                            Icons.calendar_today,
                                            widget.journeyData['date'] ?? '',
                                            isWhite: true,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: _buildInfoChip(
                                            Icons.access_time,
                                            widget.journeyData['time'] ?? '',
                                            isWhite: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 24),

                              // Journey Info
                              _buildSectionTitle('Journey Information'),
                              SizedBox(height: 12),
                              _buildInfoRow('Available Weight', '${widget.journeyData['remainingWeight'] ?? widget.journeyData['availableWeight']}kg'),
                              _buildInfoRow('Package Type', widget.journeyData['packageType'] ?? 'All'),
                              _buildInfoRow('Total Bookings', '${widget.journeyData['totalBookings'] ?? 0}'),
                              _buildInfoRow('Status', _getStatusText(widget.journeyData['status'] ?? 'active')),

                              SizedBox(height: 24),

                              // Bookings Section
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildSectionTitle('Booking Requests'),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF006CD5).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${widget.journeyData['totalBookings'] ?? 0}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Instrument Sans',
                                        color: Color(0xFF006CD5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),

                              // Bookings List
                              StreamBuilder<QuerySnapshot>(
                                stream: _firestore
                                    .collection('bookings')
                                    .where('journeyId', isEqualTo: widget.journeyId)
                                    .orderBy('createdAt', descending: true)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                    return Container(
                                      padding: EdgeInsets.all(32),
                                      child: Center(
                                        child: Column(
                                          children: [
                                            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.withOpacity(0.3)),
                                            SizedBox(height: 12),
                                            Text(
                                              'No bookings yet',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontFamily: 'Instrument Sans',
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  return Column(
                                    children: snapshot.data!.docs.map((doc) {
                                      final data = doc.data() as Map<String, dynamic>;
                                      return _buildBookingCard(doc.id, data);
                                    }).toList(),
                                  );
                                },
                              ),

                              SizedBox(height: 24),

                              // Cancel Journey Button
                              if (widget.journeyData['status'] != 'cancelled')
                                Container(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: _cancelJourney,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: BorderSide(color: Colors.red),
                                      padding: EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.cancel_outlined, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Cancel Journey',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Instrument Sans',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        fontFamily: 'Instrument Sans',
        color: Colors.black87,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Instrument Sans',
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Instrument Sans',
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, {bool isWhite = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isWhite ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isWhite ? Colors.white : Colors.black54),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Instrument Sans',
                color: isWhite ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(String bookingId, Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending';
    final packageDetails = data['packageDetails'] as Map<String, dynamic>?;

    return Container(
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(0xFF006CD5).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (data['senderName'] ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Instrument Sans',
                      color: Color(0xFF006CD5),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['senderName'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Instrument Sans',
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      data['senderEmail'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
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
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Instrument Sans',
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          Row(
            children: [
              _buildInfoChip(Icons.category_outlined, packageDetails?['packageType'] ?? 'N/A'),
              SizedBox(width: 8),
              _buildInfoChip(Icons.scale_outlined, '${packageDetails?['weight'] ?? 0}kg'),
            ],
          ),

          if (status == 'pending') ...[
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleBookingAction(bookingId, 'accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Text('Accept', style: TextStyle(fontFamily: 'Instrument Sans', fontWeight: FontWeight.w600)),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleBookingAction(bookingId, 'reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Text('Reject', style: TextStyle(fontFamily: 'Instrument Sans', fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    return status[0].toUpperCase() + status.substring(1);
  }
}

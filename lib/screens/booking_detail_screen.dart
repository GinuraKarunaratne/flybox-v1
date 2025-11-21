// lib/screens/booking_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const BookingDetailScreen({
    Key? key,
    required this.bookingId,
    required this.bookingData,
  }) : super(key: key);

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
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

  Future<void> _cancelBooking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Cancel Booking?', style: TextStyle(fontFamily: 'Instrument Sans')),
        content: Text(
          'This will cancel your booking and notify the traveler.',
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
      // Update booking status
      await _firestore.collection('bookings').doc(widget.bookingId).update({
        'status': 'cancelled',
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Restore journey weight
      final packageDetails = widget.bookingData['packageDetails'] as Map<String, dynamic>?;
      final weight = packageDetails?['weight'] ?? 0.0;
      final journeyId = widget.bookingData['journeyId'];

      await _firestore.collection('journeys').doc(journeyId).update({
        'remainingWeight': FieldValue.increment(weight),
        'totalBookings': FieldValue.increment(-1),
      });

      // Notify traveler
      await _firestore.collection('notifications').add({
        'userId': widget.bookingData['travelerId'],
        'title': 'Booking Cancelled',
        'message': '${widget.bookingData['senderName']} cancelled their booking',
        'type': 'booking_cancelled',
        'isRead': false,
        'priority': 'normal',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking cancelled'), backgroundColor: Colors.orange),
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
    final route = widget.bookingData['route'] as Map<String, dynamic>?;
    final packageDetails = widget.bookingData['packageDetails'] as Map<String, dynamic>?;
    final receiverInfo = widget.bookingData['receiverInfo'] as Map<String, dynamic>?;
    final status = widget.bookingData['status'] ?? 'pending';
    final daysLeft = _daysUntil(route?['date'] ?? '');

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
                        'Booking Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontFamily: 'Instrument Sans',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Instrument Sans',
                          color: Colors.white,
                        ),
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
                              // Timeline/Status Tracker
                              if (daysLeft >= 0 && daysLeft <= 7)
                                Container(
                                  padding: EdgeInsets.all(16),
                                  margin: EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time, color: Colors.white, size: 32),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Delivery in $daysLeft days',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                fontFamily: 'Instrument Sans',
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Your package will be delivered soon',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontFamily: 'Instrument Sans',
                                                color: Colors.white.withOpacity(0.9),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

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
                                                route?['from'] ?? '',
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
                                                route?['to'] ?? '',
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
                                            route?['date'] ?? '',
                                            isWhite: true,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: _buildInfoChip(
                                            Icons.access_time,
                                            route?['time'] ?? '',
                                            isWhite: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 24),

                              // Traveler Info
                              _buildSectionTitle('Traveler Information'),
                              SizedBox(height: 12),
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Color(0xFF006CD5).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          (widget.bookingData['travelerName'] ?? 'U')[0].toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'Instrument Sans',
                                            color: Color(0xFF006CD5),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.bookingData['travelerName'] ?? 'Unknown',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Instrument Sans',
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            widget.bookingData['travelerEmail'] ?? '',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontFamily: 'Instrument Sans',
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 24),

                              // Package Details
                              _buildSectionTitle('Package Details'),
                              SizedBox(height: 12),
                              _buildInfoRow('Type', packageDetails?['packageType'] ?? 'N/A'),
                              _buildInfoRow('Description', packageDetails?['description'] ?? 'N/A'),
                              _buildInfoRow('Weight', '${packageDetails?['weight'] ?? 0}kg'),
                              _buildInfoRow(
                                'Dimensions',
                                '${packageDetails?['dimensions']?['length']}L × ${packageDetails?['dimensions']?['width']}W × ${packageDetails?['dimensions']?['height']}H cm',
                              ),

                              SizedBox(height: 24),

                              // Receiver Info
                              _buildSectionTitle('Receiver Information'),
                              SizedBox(height: 12),
                              _buildInfoRow('Name', receiverInfo?['name'] ?? 'N/A'),
                              _buildInfoRow('Phone', receiverInfo?['phone'] ?? 'N/A'),
                              _buildInfoRow('Address', receiverInfo?['address'] ?? 'N/A'),
                              if (receiverInfo?['notes'] != null && receiverInfo!['notes'].toString().isNotEmpty)
                                _buildInfoRow('Notes', receiverInfo['notes']),

                              SizedBox(height: 24),

                              // Booking Info
                              _buildSectionTitle('Booking Information'),
                              SizedBox(height: 12),
                              _buildInfoRow('Booking ID', widget.bookingId.substring(0, 8).toUpperCase()),
                              _buildInfoRow('Status', _getStatusText(status)),

                              SizedBox(height: 24),

                              // Cancel Button
                              if (status != 'cancelled' && status != 'completed')
                                Container(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: _cancelBooking,
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
                                          'Cancel Booking',
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Instrument Sans',
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Instrument Sans',
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    return status[0].toUpperCase() + status.substring(1);
  }
}

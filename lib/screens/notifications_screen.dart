// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All notifications marked as read'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'journey_created':
        return Icons.flight_takeoff;
      case 'booking_created':
        return Icons.shopping_bag_outlined;
      case 'booking_received':
        return Icons.notification_add_outlined;
      case 'reminder':
        return Icons.notifications_active_outlined;
      case 'journey_reminder':
        return Icons.alarm;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'journey_created':
        return Colors.blue;
      case 'booking_created':
        return Colors.green;
      case 'booking_received':
        return Colors.orange;
      case 'reminder':
      case 'journey_reminder':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';

    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notifications',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontFamily: 'Instrument Sans',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextButton(
                      onPressed: _markAllAsRead,
                      child: Text(
                        'Mark all read',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: 'Instrument Sans',
                          fontWeight: FontWeight.w500,
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
                  child: user == null
                      ? Center(child: Text('Please login'))
                      : _buildNotificationsList(user.uid),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
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
                Icon(
                  Icons.notifications_none_outlined,
                  size: 64,
                  color: Colors.grey.withOpacity(0.3),
                ),
                SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Instrument Sans',
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'We\'ll notify you when something happens',
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
          padding: EdgeInsets.zero,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final isRead = data['isRead'] ?? false;
            final type = data['type'] ?? 'general';
            final priority = data['priority'] ?? 'normal';

            return InkWell(
              onTap: () => _markAsRead(doc.id),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isRead ? Colors.white : Color(0xFF006CD5).withOpacity(0.05),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getColorForType(type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getIconForType(type),
                        size: 20,
                        color: _getColorForType(type),
                      ),
                    ),

                    SizedBox(width: 12),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  data['title'] ?? 'Notification',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                                    fontFamily: 'Instrument Sans',
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              if (priority == 'high')
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    'HIGH',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Instrument Sans',
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            data['message'] ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'Instrument Sans',
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: Colors.black38,
                              ),
                              SizedBox(width: 4),
                              Text(
                                _getTimeAgo(data['createdAt'] as Timestamp?),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'Instrument Sans',
                                  color: Colors.black38,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Unread indicator
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        margin: EdgeInsets.only(left: 8, top: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFF006CD5),
                          shape: BoxShape.circle,
                        ),
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
}

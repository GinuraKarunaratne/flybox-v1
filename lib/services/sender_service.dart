// lib/services/sender_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SenderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Fetch all available journeys from Firestore
  Future<List<Map<String, dynamic>>> getAvailableJourneys() async {
    try {
      print('📦 [SENDER] Fetching available journeys...');

      final QuerySnapshot snapshot = await _firestore
          .collection('journeys')
          .where('status', isEqualTo: 'active')
          .where('isAvailable', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      print('📦 [SENDER] Found ${snapshot.docs.length} available journeys');

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ [SENDER] Error fetching journeys: $e');
      rethrow;
    }
  }

  /// Create a booking request
  Future<String> createBooking({
    required String journeyId,
    required Map<String, dynamic> packageDetails,
    required Map<String, dynamic> receiverInfo,
  }) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      print('📦 [SENDER] Creating booking for journey: $journeyId');

      // Get sender's user data
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      // Get journey details
      DocumentSnapshot journeyDoc = await _firestore
          .collection('journeys')
          .doc(journeyId)
          .get();

      if (!journeyDoc.exists) {
        throw Exception('Journey not found');
      }

      Map<String, dynamic> journeyData = journeyDoc.data() as Map<String, dynamic>;

      // Check if journey has enough weight
      double requestedWeight = packageDetails['weight'] ?? 0.0;
      double remainingWeight = journeyData['remainingWeight'] ?? 0.0;

      if (requestedWeight > remainingWeight) {
        throw Exception('Insufficient weight available. Only ${remainingWeight}kg remaining.');
      }

      // Create booking document
      Map<String, dynamic> bookingData = {
        'senderId': currentUser.uid,
        'senderEmail': userData?['email'] ?? currentUser.email,
        'senderName': userData?['fullName'] ?? 'Unknown',
        'senderPhone': userData?['phone'] ?? '',
        'journeyId': journeyId,
        'travelerId': journeyData['userId'],
        'travelerName': journeyData['userName'] ?? 'Unknown',
        'travelerEmail': journeyData['userEmail'] ?? '',
        'route': {
          'from': journeyData['from'],
          'to': journeyData['to'],
          'date': journeyData['date'],
          'time': journeyData['time'],
        },
        'packageDetails': packageDetails,
        'receiverInfo': receiverInfo,
        'status': 'pending',
        'bookingDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Add booking to Firestore
      DocumentReference bookingRef = await _firestore
          .collection('bookings')
          .add(bookingData);

      print('✅ [SENDER] Booking created with ID: ${bookingRef.id}');

      // Update journey's remaining weight
      await _firestore.collection('journeys').doc(journeyId).update({
        'remainingWeight': remainingWeight - requestedWeight,
        'totalBookings': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Create notifications for both sender and traveler
      await _createNotifications(
        bookingId: bookingRef.id,
        senderId: currentUser.uid,
        travelerId: journeyData['userId'],
        route: '${journeyData['from']} → ${journeyData['to']}',
      );

      return bookingRef.id;
    } catch (e) {
      print('❌ [SENDER] Error creating booking: $e');
      rethrow;
    }
  }

  /// Create notifications for booking
  Future<void> _createNotifications({
    required String bookingId,
    required String senderId,
    required String travelerId,
    required String route,
  }) async {
    try {
      // Notification for sender
      await _firestore.collection('notifications').add({
        'userId': senderId,
        'title': 'Booking Created',
        'message': 'Your booking for $route has been created successfully!',
        'type': 'booking_created',
        'bookingId': bookingId,
        'isRead': false,
        'priority': 'normal',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Notification for traveler
      await _firestore.collection('notifications').add({
        'userId': travelerId,
        'title': 'New Booking Request',
        'message': 'You have received a new booking request for $route',
        'type': 'booking_received',
        'bookingId': bookingId,
        'isRead': false,
        'priority': 'high',
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ [SENDER] Notifications created');
    } catch (e) {
      print('⚠️ [SENDER] Error creating notifications: $e');
      // Non-fatal, don't throw
    }
  }

  /// Get user's bookings
  Future<List<Map<String, dynamic>>> getUserBookings() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .where('senderId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ [SENDER] Error fetching bookings: $e');
      rethrow;
    }
  }
}

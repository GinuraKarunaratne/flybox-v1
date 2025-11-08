// lib/services/database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  final CollectionReference journeys = FirebaseFirestore.instance.collection('journeys');
  final CollectionReference users = FirebaseFirestore.instance.collection('users');
  final CollectionReference notifications = FirebaseFirestore.instance.collection('notifications');

  /// Save traveler journey into "journeys" collection.
  /// Returns the created document ID on success.
  Future<String> saveTravelerJourney({
    required String userId,
    required Map<String, dynamic> journeyDetails,
    required Map<String, dynamic> luggageDetails,
  }) async {
    try {
      print('📝 [DB] Starting to save journey to "journeys" collection (debug mode)...');
      print('🧾 [DB] Current userId: $userId');

      // Attempt to read user profile (safe fallback if missing)
      DocumentSnapshot userDoc;
      Map<String, dynamic>? userData;
      try {
        userDoc = await users.doc(userId).get();
        userData = userDoc.data() as Map<String, dynamic>?;
        print('👤 [DB] User data: ${userData ?? "<no user data>"}');
      } catch (e) {
        print('⚠️ [DB] Could not fetch user profile: $e');
        userData = null;
      }

      // Prepare journey data
      Map<String, dynamic> journeyData = {
        'userId': userId,
        'userEmail': userData?['email'] ?? '',
        'userName': userData?['fullName'] ?? '',
        'userPhone': userData?['phone'] ?? '',
        'from': journeyDetails['from'],
        'to': journeyDetails['to'],
        'date': journeyDetails['date'],
        'time': journeyDetails['time'],
        'ticketPrice': journeyDetails['ticketPrice'],
        'ticketImageUrl': journeyDetails['ticketImageUrl'],
        'ticketImageUploaded': journeyDetails['ticketImageUploaded'] ?? false,
        'packageType': luggageDetails['packageType'],
        'hateToCarry': luggageDetails['hateToCarry'],
        'availableWeight': luggageDetails['weight'],
        'dimensions': {
          'length': luggageDetails['length'],
          'width': luggageDetails['width'],
          'height': luggageDetails['height'],
        },
        'status': 'active',
        'isAvailable': true,
        'bookings': [],
        'totalBookings': 0,
        'remainingWeight': luggageDetails['weight'],
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'fromLowercase': (journeyDetails['from'] ?? '').toString().toLowerCase(),
        'toLowercase': (journeyDetails['to'] ?? '').toString().toLowerCase(),
        'routeKey': '${journeyDetails['from'] ?? ''}_${journeyDetails['to'] ?? ''}'.toLowerCase(),
        'journeyType': 'traveler_offering',
        'offerType': 'luggage_space',
      };

      // Defensive check
      if ((journeyData['from'] ?? '').toString().isEmpty ||
          (journeyData['to'] ?? '').toString().isEmpty) {
        throw Exception('Required journey fields missing (from/to).');
      }

      // Add to Firestore
      DocumentReference docRef;
      try {
        docRef = await journeys.add(journeyData);
        print('✅ [DB] Document added with ID: ${docRef.id}');
      } on FirebaseException catch (fe) {
        print('❌ [DB] FirebaseException on add: ${fe.code} - ${fe.message}');
        rethrow;
      } catch (e) {
        print('❌ [DB] Unknown error on add: $e');
        rethrow;
      }

      // Optional verification (helpful for debugging)
      try {
        final snapshot = await docRef.get();
        if (!snapshot.exists) {
          throw Exception('Write returned docRef but snapshot does not exist right after write.');
        }
        print('🔍 [DB] Verification ok: ${snapshot.id}');
      } catch (e) {
        // Not fatal; log for investigation
        print('⚠️ [DB] Verification error (non-fatal): $e');
      }

      // Create a notification (best-effort)
      try {
        await saveNotification(
          userId: userId,
          title: 'Journey Created Successfully',
          message: 'Your journey from ${journeyDetails['from']} to ${journeyDetails['to']} is now live!',
          type: 'journey_created',
          additionalData: {'journeyId': docRef.id, 'route': '${journeyDetails['from']} -> ${journeyDetails['to']}'},
        );
      } catch (e) {
        print('⚠️ [DB] Failed creating notification: $e');
      }

      return docRef.id;
    } catch (e) {
      print('❌ [DB] saveTravelerJourney caught error: $e');
      rethrow;
    }
  }

  /// Save notification document
  Future<void> saveNotification({
    required String userId,
    required String title,
    required String message,
    String? type,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await notifications.add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type ?? 'general',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'priority': 'normal',
        ...?additionalData,
      });
      print('✅ [DB] Notification saved successfully for user: $userId');
    } on FirebaseException catch (fe) {
      print('❌ [DB] FirebaseException while saving notification: ${fe.code} - ${fe.message}');
      rethrow;
    } catch (e) {
      print('❌ [DB] Unknown error while saving notification: $e');
      rethrow;
    }
  }
}

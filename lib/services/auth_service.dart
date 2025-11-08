import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Authentication Service
/// Handles email/password authentication, user registration, and data management
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Register user with email and password
  Future<UserCredential?> registerWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('Attempting to register with email: $email');
      
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      
      print('Registration successful for user: ${result.user?.uid}');
      return result;
    } on FirebaseAuthException catch (e) {
      print('Registration failed: ${e.code} - ${e.message}');
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      print('Registration exception: $e');
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  /// Sign in user with email and password
  Future<UserCredential?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('Attempting to sign in with email: $email');
      
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      
      print('Sign in successful for user: ${result.user?.uid}');
      return result;
    } on FirebaseAuthException catch (e) {
      print('Sign in failed: ${e.code} - ${e.message}');
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      print('Sign in exception: $e');
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
      print('Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      print('Password reset failed: ${e.code} - ${e.message}');
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      print('Password reset exception: $e');
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        print('Email verification sent to: ${user.email}');
      }
    } catch (e) {
      print('Email verification failed: $e');
      throw Exception('Failed to send verification email');
    }
  }

  /// Register user data to Firestore with comprehensive error handling
  Future<void> registerUserData({
    required String fullName,
    required String email,
    required String phone,
    required String userType,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      print('Saving user data for UID: ${user.uid}');

      // Prepare user data
      Map<String, dynamic> userData = {
        'uid': user.uid,
        'fullName': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone,
        'userType': userType,
        'isEmailVerified': user.emailVerified,
        'isPhoneVerified': false, // Will be true when phone is verified separately
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'isActive': true,
        'profileCompleted': true,
      };

      // Add additional data if provided
      if (additionalData != null) {
        userData.addAll(additionalData);
      }

      // Save to Firestore
      await _firestore.collection('users').doc(user.uid).set(userData);
      print('User data saved successfully to Firestore');

    } catch (e) {
      print('Error saving user data: $e');
      rethrow;
    }
  }

  /// Get current user data from Firestore
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user found');
        return null;
      }

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        print('User data retrieved for: ${userData['fullName']}');
        return userData;
      } else {
        print('No user document found for UID: ${user.uid}');
        return null;
      }
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Update user data in Firestore
  Future<void> updateUserData(Map<String, dynamic> updates) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      updates['lastUpdated'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('users').doc(user.uid).update(updates);
      print('User data updated successfully');

    } catch (e) {
      print('Error updating user data: $e');
      rethrow;
    }
  }

  /// Check if user exists in Firestore
  Future<bool> userExistsInDatabase() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking user existence: $e');
      return false;
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('User signed out successfully');
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  /// Check if user is currently logged in
  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  /// Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Delete user account and data
  Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Delete user data from Firestore
      await _firestore.collection('users').doc(user.uid).delete();
      
      // Delete Firebase Auth account
      await user.delete();
      
      print('User account deleted successfully');
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }

  /// Get user-friendly error messages
  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password';
      case 'email-already-in-use':
        return 'An account already exists with this email address';
      case 'invalid-email':
        return 'Invalid email address format';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'user-not-found':
        return 'No account found with this email address';
      case 'wrong-password':
        return 'Incorrect password. Please try again';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      case 'invalid-credential':
        return 'Invalid email or password';
      default:
        return 'Authentication failed. Please try again';
    }
  }
}
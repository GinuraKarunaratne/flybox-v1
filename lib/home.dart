import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'navigation_bar.dart' as nav;
import 'screens/activity_screen.dart';
import 'screens/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _userName = 'User';
  

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAuthentication();
    _loadUserName();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _checkAuthentication() {
    if (_auth.currentUser == null) {
      Future.microtask(() => Navigator.of(context).pushReplacementNamed('/welcome'));
    }
  }

  Future<void> _loadUserName() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          setState(() {
            _userName = data?['fullName'] ?? 'User';
          });
        }
      }
    } catch (e) {
      print('Error loading user name: $e');
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning!';
    } else if (hour < 17) {
      return 'Good afternoon!';
    } else {
      return 'Good evening!';
    }
  }

  void _onNavigationTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return ActivityScreen();
      case 2:
        return NotificationsScreen();
      default:
        return _buildHomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getCurrentPage(),
      bottomNavigationBar: nav.NavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavigationTapped,
      ),
    );
  }

  Widget _buildHomePage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFF006CD5)),
      child: SafeArea(
        child: Column(
          children: [
            // Top section with profile and greeting
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  // Profile picture aligned to right
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/profile');
                      },
                      child: Container(
                        width: 35,
                        height: 35,
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: OvalBorder(
                            side: BorderSide(width: 2, color: Colors.white),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _userName[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Instrument Sans',
                              color: Color(0xFF006CD5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Greeting text
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Hello $_userName,\n',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontFamily: 'Instrument Sans',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextSpan(
                            text: _getGreeting(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: 'Instrument Sans',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Main white container
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(24),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Get started section
                    Column(
                      children: [
                        // Yellow accent box
                        Container(
                          width: 128,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFDE58),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              width: 1,
                              color: const Color(0xFFFFDE58),
                            ),
                          ),
                          child: Icon(
                            Icons.flight_takeoff,
                            size: 32,
                            color: const Color(0xFF1E1E1E),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Get started title
                        Text(
                          'Get started',
                          style: TextStyle(
                            color: const Color(0xFF1E1E1E),
                            fontSize: 18,
                            fontFamily: 'Instrument Sans',
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.18,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Divider line
                        Container(
                          width: double.infinity,
                          height: 1,
                          color: const Color(0xFF1E1E1E).withOpacity(0.2),
                        ),

                        const SizedBox(height: 40),

                        // Send Package button
                        Container(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pushNamed(context, '/browseJourneys'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF242424),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: Text(
                              'Send Package',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Instrument Sans',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Become a Traveler button
                        Container(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pushNamed(context, '/userType'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF242424),
                              side: BorderSide(color: const Color(0xFF242424)),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: Text(
                              'Become a Traveler',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Instrument Sans',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Additional info text
                        Text(
                          'Start your journey with Flybox.\nSend packages or offer luggage space.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontFamily: 'Instrument Sans',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

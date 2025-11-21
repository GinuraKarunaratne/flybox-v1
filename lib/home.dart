import 'package:flutter/material.dart';
import 'navigation_bar.dart' as nav;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAuthentication();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _checkAuthentication() {
    // Add your authentication check logic here
    // For example:
    // if (!isAuthenticated) {
    //   Navigator.of(context).pushReplacementNamed('/login');
    // }
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

  void _onGetStartedPressed() {
    Navigator.pushNamed(context, '/userType');
  }

  void _onNavigationTapped(int index) {
    if (index == _currentIndex) return; // Avoid unnecessary state updates
    
    setState(() {
      _currentIndex = index;
    });

    // Add navigation logic based on index
    switch (index) {
      case 0: // Home
        break;
      case 1: // Search
        // Navigate to search screen
        break;
      case 2: // Profile
        // Navigate to profile screen
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
                      child: Container(
                        width: 35,
                        height: 35,
                        decoration: ShapeDecoration(
                          color: Colors.grey[300],
                          image: DecorationImage(
                            image: AssetImage("assets/default_avatar.png"),
                            fit: BoxFit.cover,
                          ),
                          shape: OvalBorder(
                            side: BorderSide(width: 2, color: Colors.white),
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
                              text: 'Hello Yasas,\n',
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
                              onPressed: () => Navigator.pushNamed(context, '/sendDestination'),
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

                          // Get started button (secondary)
                          Container(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              onPressed: _onGetStartedPressed,
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
      ),
      bottomNavigationBar: nav.NavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavigationTapped,
      ),
    );
  }
}
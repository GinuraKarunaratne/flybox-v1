import 'package:flutter/material.dart';
import 'package:flutter_application_1/auth/welcome.dart';
import 'package:flutter_application_1/auth/register.dart';
import 'package:flutter_application_1/auth/login.dart';
import 'package:flutter_application_1/usertype.dart';
import 'package:flutter_application_1/travelersetup.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'home.dart';
// Sender screens
import 'sender/browse_journeys_screen.dart';
import 'sender/package_details_screen.dart';
import 'sender/receiver_info_screen.dart';
import 'sender/confirmation_screen.dart';
// Main screens
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase initialized successfully");
  } catch (e) {
    print("❌ Firebase initialization failed: $e");
    // You might want to show an error dialog or handle this gracefully
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlyBox - Package Delivery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF006CD5),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Instrument Sans',
      ),

      // Check if user is already logged in
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Show loading while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // If user is logged in, go to home, otherwise go to welcome
          if (snapshot.hasData && snapshot.data != null) {
            return HomeScreen();
          } else {
            return WelcomeScreen();
          }
        },
      ),

      routes: {
        '/welcome': (context) => WelcomeScreen(),
        '/register': (context) => RegistrationCarousel(),
        '/home': (context) => HomeScreen(),
        '/login': (context) => LoginScreen(),
        '/userType': (context) => UserTypeScreen(),
        '/travelerSetup': (context) => TravelerSetupScreen(),
        // Sender flow routes
        '/browseJourneys': (context) => const BrowseJourneysScreen(),
        '/profile': (context) => ProfileScreen(),
      },

      onGenerateRoute: (settings) {
        // Handle routes with arguments
        switch (settings.name) {
          case '/senderPackageDetails':
            final journey = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => PackageDetailsScreen(journey: journey),
            );
          case '/senderReceiverInfo':
            final data = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => ReceiverInfoScreen(data: data),
            );
          case '/senderConfirmation':
            final data = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => ConfirmationScreen(data: data),
            );
          default:
            return MaterialPageRoute(
              builder: (context) => WelcomeScreen(),
            );
        }
      },
    );
  }
}
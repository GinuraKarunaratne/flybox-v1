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
      title: 'Flutter Application',
      debugShowCheckedModeBanner: false,
      
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
      },
      
      onGenerateRoute: (settings) {
        // Handle unknown routes
        return MaterialPageRoute(
          builder: (context) => WelcomeScreen(),
        );
      },
    );
  }
}
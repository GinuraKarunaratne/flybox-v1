import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

/// Login screen with email/password authentication and Firebase integration
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
} 

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  
  // Form controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validate form inputs
  bool _validateForm() {
    if (_emailController.text.trim().isEmpty) {
      _showMessage('Please enter your email address', isError: true);
      return false;
    }
    
    if (!_isValidEmail(_emailController.text.trim())) {
      _showMessage('Please enter a valid email address', isError: true);
      return false;
    }
    
    if (_passwordController.text.isEmpty) {
      _showMessage('Please enter your password', isError: true);
      return false;
    }
    
    return true;
  }

  /// Email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Show message using SnackBar
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontFamily: 'Instrument Sans',
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Handle login process
  void _handleLogin() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.signInWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Check if user data exists in Firestore
      bool userExists = await _authService.userExistsInDatabase();
      
      if (userExists) {
        _navigateToHome();
      } else {
        // If user doesn't exist in Firestore, redirect to complete profile
        _showMessage('Please complete your profile setup');
        Navigator.pushReplacementNamed(context, '/userType');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage(e.toString(), isError: true);
    }
  }

  /// Navigate to home screen
  void _navigateToHome() {
    _showMessage('Login successful! Welcome back to Flybox.');
    Future.delayed(Duration(milliseconds: 1200), () {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    });
  }

  /// Handle forgot password
  void _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      _showMessage('Please enter your email address first', isError: true);
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showMessage('Please enter a valid email address', isError: true);
      return;
    }

    try {
      await _authService.sendPasswordResetEmail(_emailController.text.trim());
      _showMessage('Password reset email sent! Check your inbox.');
    } catch (e) {
      _showMessage(e.toString(), isError: true);
    }
  }

  /// Build input field with proper styling
  Widget _buildInputField({
    required String placeholder,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
  }) {
    return Container(
      width: double.infinity,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(
          color: const Color(0xFF1E1E1E),
          fontSize: 14,
          fontFamily: 'Instrument Sans',
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(
            color: const Color(0xFF999999),
            fontSize: 14,
            fontFamily: 'Instrument Sans',
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          isDense: true,
          suffixIcon: suffixIcon,
        ),
      ),
    );
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
              SizedBox(height: 60),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome back title
                      Text(
                        'Welcome back!',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 32,
                          fontFamily: 'Instrument Sans',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Divider line
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: Colors.grey.withOpacity(0.3),
                      ),
                      
                      // Spacer to center the form
                      Expanded(child: Container()),
                      
                      // Login form
                      Column(
                        children: [
                          // Email field
                          _buildInputField(
                            placeholder: 'Enter your email address',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Password field
                          _buildInputField(
                            placeholder: 'Enter your password',
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          
                          SizedBox(height: 12),
                          
                          // Remember me checkbox
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _rememberMe = !_rememberMe;
                                  });
                                },
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: _rememberMe ? const Color(0xFF006CD5) : Colors.transparent,
                                    border: Border.all(color: const Color(0xFF006CD5)),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: _rememberMe
                                      ? Icon(Icons.check, size: 12, color: Colors.white)
                                      : null,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Remember me',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontFamily: 'Instrument Sans',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 24),
                          
                          // Login button
                          Container(
                            width: double.infinity,
                            height: 45,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF242424),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                disabledBackgroundColor: Colors.grey,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'Instrument Sans',
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                            ),
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Forgot password link
                          GestureDetector(
                            onTap: _handleForgotPassword,
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: const Color(0xFF006CD5),
                                fontSize: 12,
                                fontFamily: 'Instrument Sans',
                                fontWeight: FontWeight.w400,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Bottom spacer
                      Expanded(child: Container()),
                      
                      // Back to registration option
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontFamily: 'Instrument Sans',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                'Register here',
                                style: TextStyle(
                                  color: const Color(0xFF006CD5),
                                  fontSize: 12,
                                  fontFamily: 'Instrument Sans',
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
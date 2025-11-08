import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

/// Multi-step registration carousel with email/password authentication and Firebase integration
class RegistrationCarousel extends StatefulWidget {
  @override
  _RegistrationCarouselState createState() => _RegistrationCarouselState();
}

class _RegistrationCarouselState extends State<RegistrationCarousel> {
  final PageController _pageController = PageController();
  final AuthService _authService = AuthService();
  int _currentStep = 0;
  bool _isLoading = false;
  
  // Form controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nicController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  
  String _selectedProvince = '';
  String _selectedDistrict = '';
  bool _termsAccepted = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  
  // Static data
  final List<String> _provinces = [
    'Western Province', 'Central Province', 'Southern Province', 
    'Northern Province', 'Eastern Province', 'North Western Province',
    'North Central Province', 'Uva Province', 'Sabaragamuwa Province'
  ];
  
  final List<String> _districts = [
    'Colombo', 'Gampaha', 'Kalutara', 'Kandy', 'Matale', 'Nuwara Eliya',
    'Galle', 'Matara', 'Hambantota', 'Jaffna', 'Kilinochchi', 'Mannar'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _nicController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  /// Validate current step before proceeding
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Account details
        if (_fullNameController.text.trim().isEmpty) {
          _showMessage('Please enter your full name', isError: true);
          return false;
        }
        if (_emailController.text.trim().isEmpty || !_isValidEmail(_emailController.text)) {
          _showMessage('Please enter a valid email address', isError: true);
          return false;
        }
        if (_passwordController.text.isEmpty || _passwordController.text.length < 6) {
          _showMessage('Password must be at least 6 characters long', isError: true);
          return false;
        }
        if (_passwordController.text != _confirmPasswordController.text) {
          _showMessage('Passwords do not match', isError: true);
          return false;
        }
        break;
      case 1: // Phone number
        if (_phoneController.text.isEmpty || _phoneController.text.length != 9) {
          _showMessage('Please enter a valid 9-digit phone number', isError: true);
          return false;
        }
        break;
      case 2: // Identification
        if (_nicController.text.trim().isEmpty) {
          _showMessage('Please enter your NIC or Passport number', isError: true);
          return false;
        }
        break;
      case 3: // Location
        if (_selectedProvince.isEmpty || _selectedDistrict.isEmpty || _streetController.text.trim().isEmpty) {
          _showMessage('Please fill in all location fields', isError: true);
          return false;
        }
        break;
      case 4: // Terms
        if (!_termsAccepted) {
          _showMessage('Please accept the terms and conditions to continue', isError: true);
          return false;
        }
        break;
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

  /// Handle next step navigation
  Future<void> _nextStep() async {
    if (!_validateCurrentStep()) return;

    if (_currentStep == 0) {
      await _handleAccountCreation();
    } else if (_currentStep < 4) {
      _moveToNextStep();
    } else {
      await _submitRegistration();
    }
  }

  /// Handle account creation with email/password
  Future<void> _handleAccountCreation() async {
    setState(() => _isLoading = true);
    
    try {
      await _authService.registerWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      setState(() => _isLoading = false);
      _moveToNextStep();
      _showMessage('Account created successfully! Please continue with your profile.');
      
      // Send email verification
      try {
        await _authService.sendEmailVerification();
        _showMessage('Verification email sent to ${_emailController.text}');
      } catch (e) {
        // Don't stop registration if email verification fails
        print('Email verification failed: $e');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage(e.toString(), isError: true);
    }
  }

  /// Move to next step with animation
  void _moveToNextStep() {
    setState(() => _currentStep++);
    _pageController.animateToPage(
      _currentStep,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Submit registration data to Firebase
  Future<void> _submitRegistration() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await _authService.registerUserData(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: '+94${_phoneController.text}',
        userType: 'user',
        additionalData: {
          'nic': _nicController.text.trim(),
          'province': _selectedProvince,
          'district': _selectedDistrict,
          'street': _streetController.text.trim(),
          'termsAccepted': _termsAccepted,
          'registrationCompleted': true,
          'profileType': 'standard',
        }
      );

      if (mounted) {
        _showMessage('Registration successful!');
        await Future.delayed(Duration(milliseconds: 1500));
        Navigator.pushReplacementNamed(context, '/userType');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Registration failed: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Go back to previous step
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Build progress indicator
  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) { // Changed from 6 to 5 steps
          bool isActive = index <= _currentStep;
          return Row(
            children: [
              Container(
                width: 21,
                height: 21,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFFFDE58) : const Color(0xFFD9D9D9),
                  border: Border.all(width: 1, color: const Color(0xFF888888)),
                  borderRadius: BorderRadius.circular(10.5),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontFamily: 'Instrument Sans',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              if (index < 4)
                Container(
                  width: 15,
                  height: 1,
                  color: Colors.black.withOpacity(0.25),
                ),
            ],
          );
        }),
      ),
    );
  }

  /// Build input field with proper styling
  Widget _buildInputField({
    required String placeholder,
    TextEditingController? controller,
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

  /// Build dropdown field
  Widget _buildDropdownField({
    required String placeholder,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      width: double.infinity,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.isEmpty ? null : value,
          hint: Text(
            placeholder,
            style: TextStyle(
              color: const Color(0xFF999999),
              fontSize: 14,
              fontFamily: 'Instrument Sans',
              fontWeight: FontWeight.w400,
            ),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  color: const Color(0xFF1E1E1E),
                  fontSize: 14,
                  fontFamily: 'Instrument Sans',
                  fontWeight: FontWeight.w400,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          isExpanded: true,
        ),
      ),
    );
  }

  /// Build navigation buttons
  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _currentStep > 0
              ? TextButton(
                  onPressed: _isLoading ? null : _previousStep,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    'Back',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.70),
                      fontSize: 16,
                      fontFamily: 'Instrument Sans',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                )
              : SizedBox(width: 60),
          Container(
            width: 80,
            height: 36,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF242424),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: EdgeInsets.zero,
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _currentStep < 4 ? 'Next' : 'Finish',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Instrument Sans',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build file upload field
  Widget _buildFileUploadField(String label) {
    return Container(
      width: double.infinity,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF999999),
              fontSize: 14,
              fontFamily: 'Instrument Sans',
              fontWeight: FontWeight.w400,
            ),
          ),
          GestureDetector(
            onTap: () {
              // TODO: Implement file upload
              print('Upload $label');
            },
            child: Icon(
              Icons.upload_file, 
              size: 18, 
              color: const Color(0xFF666666),
            ),
          ),
        ],
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
                  child: PageView(
                    controller: _pageController,
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      // Step 1: Account Details
                      _buildAccountStep(),
                      // Step 2: Phone Number
                      _buildPhoneStep(),
                      // Step 3: Identification
                      _buildIdentificationStep(),
                      // Step 4: Location
                      _buildLocationStep(),
                      // Step 5: Terms & Conditions
                      _buildTermsStep(),
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

  Widget _buildAccountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create an account',
          style: TextStyle(
            color: const Color(0xFF242424),
            fontSize: 20,
            fontFamily: 'Instrument Sans',
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 16),
        _buildProgressIndicator(),
        SizedBox(height: 24),
        Expanded(
          child: Column(
            children: [
              _buildInputField(
                placeholder: 'Enter your full name',
                controller: _fullNameController,
              ),
              SizedBox(height: 12),
              _buildInputField(
                placeholder: 'Enter your email address',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 12),
              _buildInputField(
                placeholder: 'Enter a password',
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
              _buildInputField(
                placeholder: 'Confirm your password',
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add your phone number',
          style: TextStyle(
            color: const Color(0xFF242424),
            fontSize: 20,
            fontFamily: 'Instrument Sans',
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 16),
        _buildProgressIndicator(),
        SizedBox(height: 24),
        Text(
          'Enter your mobile number for account security',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Instrument Sans',
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 20),
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Text(
                '+94',
                style: TextStyle(
                  color: const Color(0xFF1E1E1E),
                  fontSize: 16,
                  fontFamily: 'Instrument Sans',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildInputField(
                placeholder: 'Enter phone number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
              ),
            ),
          ],
        ),
        Expanded(child: Container()),
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildIdentificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Identification',
          style: TextStyle(
            color: const Color(0xFF242424),
            fontSize: 20,
            fontFamily: 'Instrument Sans',
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 16),
        _buildProgressIndicator(),
        SizedBox(height: 24),
        Expanded(
          child: Column(
            children: [
              _buildInputField(
                placeholder: 'NIC / Passport number',
                controller: _nicController,
              ),
              SizedBox(height: 12),
              _buildFileUploadField('Upload NIC - front'),
              SizedBox(height: 12),
              _buildFileUploadField('Upload NIC - back'),
            ],
          ),
        ),
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your location',
          style: TextStyle(
            color: const Color(0xFF242424),
            fontSize: 20,
            fontFamily: 'Instrument Sans',
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 16),
        _buildProgressIndicator(),
        SizedBox(height: 24),
        Expanded(
          child: Column(
            children: [
              _buildDropdownField(
                placeholder: 'Select your province',
                value: _selectedProvince,
                items: _provinces,
                onChanged: (value) {
                  setState(() {
                    _selectedProvince = value ?? '';
                  });
                },
              ),
              SizedBox(height: 12),
              _buildDropdownField(
                placeholder: 'Select your district',
                value: _selectedDistrict,
                items: _districts,
                onChanged: (value) {
                  setState(() {
                    _selectedDistrict = value ?? '';
                  });
                },
              ),
              SizedBox(height: 12),
              _buildInputField(
                placeholder: 'Enter your street address',
                controller: _streetController,
              ),
            ],
          ),
        ),
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildTermsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Terms & Conditions',
          style: TextStyle(
            color: const Color(0xFF242424),
            fontSize: 20,
            fontFamily: 'Instrument Sans',
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 16),
        _buildProgressIndicator(),
        SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: Text(
              'By using this application, you agree to use the platform responsibly and in accordance with all applicable laws and airline regulations. Travelers must accurately declare available luggage space and ensure no prohibited or illegal items are transported. Senders are responsible for the contents of their packages and must comply with all customs and security requirements. Both parties must complete identity verification and use in-app QR codes for secure handovers. The platform is not liable for loss, damage, or disputes arising from transactions. Users must respect community guidelines and are subject to removal for violations. Continued use of the app indicates acceptance of these terms.',
              textAlign: TextAlign.justify,
              style: TextStyle(
                color: Colors.black,
                fontSize: 11.5,
                fontFamily: 'Instrument Sans',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _termsAccepted = !_termsAccepted;
                });
              },
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _termsAccepted ? const Color(0xFFFFDE58) : const Color(0xFFD9D9D9),
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: _termsAccepted
                    ? Icon(Icons.check, size: 12, color: Colors.black)
                    : null,
              ),
            ),
            SizedBox(width: 13),
            Expanded(
              child: Text(
                'I confirm that the information I provide is accurate and true. I agree to the above terms and conditions.',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontFamily: 'Instrument Sans',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildNavigationButtons(),
      ],
    );
  }
}
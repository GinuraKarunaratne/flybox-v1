import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TravelerSetupScreen extends StatefulWidget {
  const TravelerSetupScreen({Key? key}) : super(key: key);

  @override
  State<TravelerSetupScreen> createState() => _TravelerSetupScreenState();
}

class _TravelerSetupScreenState extends State<TravelerSetupScreen> {
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PageController _pageController = PageController();

  bool _isLoading = false;
  int _currentStep = 0;

  // Form controllers
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _ticketPriceController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  String _selectedPackageType = '';
  String _selectedHateToCarry = '';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _ticketImageUrl;
  bool _ticketImageUploaded = false;

  final List<String> _packageTypes = ['All', 'Documents', 'Electronics', 'Clothing', 'Food Items', 'Medicine'];
  final List<String> _hateToCarryOptions = ['Fresh items', 'Fragile items', 'Heavy items', 'Liquid items'];

  @override
  void dispose() {
    _pageController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _ticketPriceController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  /// ENHANCED Save journey to Firestore with better debugging
  Future<void> _saveToDatabase() async {
    try {
      print('🔥 [DEBUG] Starting database save process...');
      
      // Check Firebase Auth first
      final User? currentUser = FirebaseAuth.instance.currentUser;
      print('🔥 [DEBUG] Current user: ${currentUser?.uid}');
      print('🔥 [DEBUG] User email: ${currentUser?.email}');
      print('🔥 [DEBUG] Auth state: ${currentUser != null ? "LOGGED IN" : "NOT LOGGED IN"}');
      
      if (currentUser == null) {
        throw Exception('No user logged in - Auth failed');
      }

      // Test Firestore connection first
      print('🔥 [DEBUG] Testing Firestore connection...');
      try {
        await _firestore.collection('journeys').limit(1).get();
        print('🔥 [DEBUG] Firestore connection: SUCCESS');
      } catch (e) {
        print('🔥 [DEBUG] Firestore connection: FAILED - $e');
        throw Exception('Firestore connection failed: $e');
      }

      // Fetch user data to get the name
      String userName = 'Unknown';
      try {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
          userName = userData?['fullName'] ?? userData?['name'] ?? currentUser.email?.split('@')[0] ?? 'Unknown';
        }
      } catch (e) {
        print('🔥 [DEBUG] Could not fetch user name: $e');
        userName = currentUser.email?.split('@')[0] ?? 'Unknown';
      }

      // Prepare simple test data first
      Map<String, dynamic> journeyData = {
        'userId': currentUser.uid,
        'userEmail': currentUser.email ?? '',
        'userName': userName,
        'testField': 'test_value_${DateTime.now().millisecondsSinceEpoch}',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Add form data only if available
      if (_fromController.text.trim().isNotEmpty) {
        journeyData['from'] = _fromController.text.trim();
        print('🔥 [DEBUG] Added from: ${_fromController.text.trim()}');
      }
      if (_toController.text.trim().isNotEmpty) {
        journeyData['to'] = _toController.text.trim();
        print('🔥 [DEBUG] Added to: ${_toController.text.trim()}');
      }
      if (_dateController.text.trim().isNotEmpty) {
        journeyData['date'] = _dateController.text.trim();
        print('🔥 [DEBUG] Added date: ${_dateController.text.trim()}');
      }
      if (_timeController.text.trim().isNotEmpty) {
        journeyData['time'] = _timeController.text.trim();
        print('🔥 [DEBUG] Added time: ${_timeController.text.trim()}');
      }
      if (_ticketPriceController.text.trim().isNotEmpty) {
        try {
          journeyData['ticketPrice'] = double.parse(_ticketPriceController.text.trim());
          print('🔥 [DEBUG] Added ticket price: ${_ticketPriceController.text.trim()}');
        } catch (e) {
          journeyData['ticketPriceText'] = _ticketPriceController.text.trim();
          print('🔥 [DEBUG] Added ticket price as text: ${_ticketPriceController.text.trim()}');
        }
      }
      if (_ticketImageUploaded) {
        journeyData['ticketImageUploaded'] = true;
        journeyData['ticketImageUrl'] = _ticketImageUrl ?? 'uploaded';
        print('🔥 [DEBUG] Added ticket image data');
      }

      // Add luggage details if available
      if (_selectedPackageType.isNotEmpty) {
        journeyData['packageType'] = _selectedPackageType;
        print('🔥 [DEBUG] Added package type: $_selectedPackageType');
      }
      if (_selectedHateToCarry.isNotEmpty) {
        journeyData['hateToCarry'] = _selectedHateToCarry;
        print('🔥 [DEBUG] Added hate to carry: $_selectedHateToCarry');
      }
      if (_weightController.text.trim().isNotEmpty) {
        try {
          double weight = double.parse(_weightController.text.trim());
          journeyData['availableWeight'] = weight;
          journeyData['remainingWeight'] = weight; // Initially same as available weight
          print('🔥 [DEBUG] Added weight: ${_weightController.text.trim()}');
        } catch (e) {
          journeyData['weightText'] = _weightController.text.trim();
          print('🔥 [DEBUG] Added weight as text: ${_weightController.text.trim()}');
        }
      }
      // Add dimensions as a structured object
      Map<String, dynamic> dimensions = {};
      if (_lengthController.text.trim().isNotEmpty) {
        try {
          dimensions['length'] = double.parse(_lengthController.text.trim());
        } catch (e) {
          dimensions['length'] = 0.0;
        }
      }
      if (_widthController.text.trim().isNotEmpty) {
        try {
          dimensions['width'] = double.parse(_widthController.text.trim());
        } catch (e) {
          dimensions['width'] = 0.0;
        }
      }
      if (_heightController.text.trim().isNotEmpty) {
        try {
          dimensions['height'] = double.parse(_heightController.text.trim());
        } catch (e) {
          dimensions['height'] = 0.0;
        }
      }
      if (dimensions.isNotEmpty) {
        journeyData['dimensions'] = dimensions;
      }

      // Add status and availability fields
      journeyData['status'] = 'active';
      journeyData['isAvailable'] = true;
      journeyData['createdAt'] = FieldValue.serverTimestamp();

      print('🔥 [DEBUG] Final data to save: $journeyData');
      print('🔥 [DEBUG] Data size: ${journeyData.length} fields');

      // Attempt to save to Firestore
      print('🔥 [DEBUG] Attempting to save to Firestore journeys collection...');
      
      DocumentReference docRef = await _firestore
          .collection('journeys')
          .add(journeyData)
          .timeout(Duration(seconds: 10));
      
      print('🔥 [DEBUG] Document added with ID: ${docRef.id}');

      // Verify the document was created
      print('🔥 [DEBUG] Verifying document creation...');
      DocumentSnapshot savedDoc = await docRef.get().timeout(Duration(seconds: 5));
      
      if (savedDoc.exists) {
        Map<String, dynamic>? savedData = savedDoc.data() as Map<String, dynamic>?;
        print('🔥 [DEBUG] ✅ VERIFICATION SUCCESS!');
        print('🔥 [DEBUG] Document ID: ${savedDoc.id}');
        print('🔥 [DEBUG] Saved data keys: ${savedData?.keys.toList()}');
        print('🔥 [DEBUG] User ID in saved doc: ${savedData?['userId']}');
        print('🔥 [DEBUG] Test field in saved doc: ${savedData?['testField']}');
        
        // Show success message
        _showMessage('✅ Journey saved successfully! Doc ID: ${docRef.id}');
        
        // Wait then navigate
        await Future.delayed(Duration(milliseconds: 2000));
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        }
      } else {
        print('🔥 [DEBUG] ❌ VERIFICATION FAILED - Document does not exist');
        throw Exception('Document verification failed - document not found');
      }

    } catch (e, stackTrace) {
      print('🔥 [DEBUG] ❌ SAVE ERROR: $e');
      print('🔥 [DEBUG] Stack trace: $stackTrace');
      
      if (e.toString().contains('permission')) {
        _showMessage('❌ Permission denied. Check Firestore rules.', isError: true);
      } else if (e.toString().contains('network')) {
        _showMessage('❌ Network error. Check internet connection.', isError: true);
      } else if (e.toString().contains('timeout')) {
        _showMessage('❌ Request timeout. Try again.', isError: true);
      } else {
        _showMessage('❌ Save failed: ${e.toString()}', isError: true);
      }
      rethrow;
    }
  }


  /// Submit the form and save to database
  Future<void> _submitForm() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      print('🚀 [SUBMIT] Starting form submission...');
      await _saveToDatabase();
    } catch (e) {
      print('❌ [SUBMIT] Submit error: $e');
      if (mounted) {
        _showMessage('Submission failed: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Show message using SnackBar
  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    
    print('📱 [UI] Showing message: $message');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontFamily: 'Instrument Sans',
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        duration: Duration(seconds: isError ? 5 : 3),
      ),
    );
  }

  /// Handle next step
  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Final step - submit the form
      _submitForm();
    }
  }

  /// Handle previous step
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  /// Date picker
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  /// Time picker
  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        final hour = picked.hour.toString().padLeft(2, '0');
        final minute = picked.minute.toString().padLeft(2, '0');
        _timeController.text = "$hour:$minute";
      });
    }
  }

  /// Handle ticket image upload (simulated)
  void _handleTicketImageUpload() {
    setState(() {
      _ticketImageUploaded = true;
      _ticketImageUrl = 'ticket_image_${DateTime.now().millisecondsSinceEpoch}';
    });
    _showMessage('Ticket image uploaded successfully');
  }

  /// Build input field with proper styling
  Widget _buildInputField({
    required String placeholder,
    required TextEditingController controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
    VoidCallback? onTap,
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
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        readOnly: readOnly,
        onTap: onTap,
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

  /// Build file upload field
  Widget _buildFileUploadField(String label) {
    return Container(
      width: double.infinity,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _ticketImageUploaded ? const Color(0xFFE8F5E8) : const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _ticketImageUploaded ? Colors.green.withOpacity(0.5) : Colors.grey.withOpacity(0.3)
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _ticketImageUploaded ? 'Ticket image uploaded ✓' : label,
            style: TextStyle(
              color: _ticketImageUploaded ? Colors.green[700] : const Color(0xFF999999),
              fontSize: 14,
              fontFamily: 'Instrument Sans',
              fontWeight: FontWeight.w400,
            ),
          ),
          GestureDetector(
            onTap: _handleTicketImageUpload,
            child: Icon(
              _ticketImageUploaded ? Icons.check_circle : Icons.upload_file, 
              size: 18, 
              color: _ticketImageUploaded ? Colors.green[700] : const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  /// Build dimension field
  Widget _buildDimensionField({
    required String label,
    required String maxValue,
    required TextEditingController controller,
  }) {
    return Expanded(
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                LengthLimitingTextInputFormatter(4),
              ],
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(
                color: const Color(0xFF1E1E1E),
                fontSize: 12,
                fontFamily: 'Instrument Sans',
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: label,
                hintStyle: TextStyle(
                  color: const Color(0xFF999999),
                  fontSize: 10,
                  fontFamily: 'Instrument Sans',
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
            Text(
              maxValue,
              style: TextStyle(
                color: Colors.black.withOpacity(0.25),
                fontSize: 8,
                fontFamily: 'Instrument Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build navigation buttons
  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: _previousStep,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              _currentStep > 0 ? 'Back' : 'Cancel',
              style: TextStyle(
                color: Colors.black.withOpacity(0.70),
                fontSize: 16,
                fontFamily: 'Instrument Sans',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Row(
            children: [
              // Add test button for debugging            
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
                          _currentStep < 2 ? 'Next' : 'Confirm',
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
              // Title section
              Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _currentStep == 0 ? 'Journey Details' : 
                    _currentStep == 1 ? 'Luggage Availability' : 'Confirm Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontFamily: 'Instrument Sans',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 14),
              
              // Main content container
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
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
                      _buildJourneyStep(),
                      _buildLuggageStep(),
                      _buildConfirmStep(),
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

  /// Build journey details step
  Widget _buildJourneyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildInputField(
                  placeholder: 'From',
                  controller: _fromController,
                ),
                SizedBox(height: 16),
                _buildInputField(
                  placeholder: 'To',
                  controller: _toController,
                ),
                SizedBox(height: 16),
                _buildInputField(
                  placeholder: 'Date',
                  controller: _dateController,
                  readOnly: true,
                  onTap: _selectDate,
                ),
                SizedBox(height: 16),
                _buildInputField(
                  placeholder: 'Time',
                  controller: _timeController,
                  readOnly: true,
                  onTap: _selectTime,
                ),
                SizedBox(height: 16),
                _buildInputField(
                  placeholder: 'Ticket price (LKR)',
                  controller: _ticketPriceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                ),
                SizedBox(height: 16),
                _buildFileUploadField('Ticket image'),
              ],
            ),
          ),
        ),
        _buildNavigationButtons(),
      ],
    );
  }

  /// Build luggage availability step
  Widget _buildLuggageStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildDropdownField(
                  placeholder: 'Select package type',
                  value: _selectedPackageType,
                  items: _packageTypes,
                  onChanged: (value) {
                    setState(() {
                      _selectedPackageType = value ?? '';
                    });
                  },
                ),
                SizedBox(height: 16),
                _buildDropdownField(
                  placeholder: 'Hate to carry?',
                  value: _selectedHateToCarry,
                  items: _hateToCarryOptions,
                  onChanged: (value) {
                    setState(() {
                      _selectedHateToCarry = value ?? '';
                    });
                  },
                ),
                SizedBox(height: 16),
                Container(
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
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                            LengthLimitingTextInputFormatter(4),
                          ],
                          textAlignVertical: TextAlignVertical.center,
                          style: TextStyle(
                            color: const Color(0xFF1E1E1E),
                            fontSize: 14,
                            fontFamily: 'Instrument Sans',
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Available Weight(Kg)',
                            hintStyle: TextStyle(
                              color: const Color(0xFF999999),
                              fontSize: 14,
                              fontFamily: 'Instrument Sans',
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                        ),
                      ),
                      Text(
                        'Max 15kg',
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.25),
                          fontSize: 13,
                          fontFamily: 'Instrument Sans',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    _buildDimensionField(
                      label: 'Length(cm)',
                      maxValue: 'Max 20cm',
                      controller: _lengthController,
                    ),
                    SizedBox(width: 12),
                    _buildDimensionField(
                      label: 'Width(cm)',
                      maxValue: 'Max 35cm',
                      controller: _widthController,
                    ),
                    SizedBox(width: 12),
                    _buildDimensionField(
                      label: 'Height(cm)',
                      maxValue: 'Max 50cm',
                      controller: _heightController,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        _buildNavigationButtons(),
      ],
    );
  }

  /// Build confirmation step
  Widget _buildConfirmStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Journey details section
                Text(
                  'Journey details',
                  style: TextStyle(
                    color: const Color(0xFF1E1E1E),
                    fontSize: 13,
                    fontFamily: 'Instrument Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                _buildConfirmationText('From', _fromController.text.isNotEmpty ? _fromController.text : 'Not specified'),
                _buildConfirmationText('To', _toController.text.isNotEmpty ? _toController.text : 'Not specified'),
                _buildConfirmationText('Date', _dateController.text.isNotEmpty ? _dateController.text : 'Not specified'),
                _buildConfirmationText('Time', _timeController.text.isNotEmpty ? _timeController.text : 'Not specified'),
                _buildConfirmationText('Ticket price', 'LKR ${_ticketPriceController.text.isNotEmpty ? _ticketPriceController.text : "0"}.00'),
                _buildConfirmationText('Ticket image', _ticketImageUploaded ? 'Uploaded ✓' : 'Not uploaded'),
                
                SizedBox(height: 16),
                
                // Divider
                Container(
                  width: double.infinity,
                  height: 1,
                  color: Colors.black.withOpacity(0.25),
                ),
                
                SizedBox(height: 16),
                
                // Luggage availability section
                Text(
                  'Luggage Availability',
                  style: TextStyle(
                    color: const Color(0xFF1E1E1E),
                    fontSize: 13,
                    fontFamily: 'Instrument Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                _buildConfirmationText('Package type', _selectedPackageType.isNotEmpty ? _selectedPackageType : 'Not specified'),
                _buildConfirmationText('Hate to carry', _selectedHateToCarry.isNotEmpty ? _selectedHateToCarry : 'Not specified'),
                
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildConfirmationText('Weight', '${_weightController.text.isNotEmpty ? _weightController.text : "0"}Kg'),
                    _buildConfirmationText('Length', '${_lengthController.text.isNotEmpty ? _lengthController.text : "0"}cm'),
                    _buildConfirmationText('Width', '${_widthController.text.isNotEmpty ? _widthController.text : "0"}cm'),
                    _buildConfirmationText('Height', '${_heightController.text.isNotEmpty ? _heightController.text : "0"}cm'),
                  ],
                ),
              ],
            ),
          ),
        ),
        _buildNavigationButtons(),
      ],
    );
  }

  /// Build confirmation text widget
  Widget _buildConfirmationText(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label\n',
              style: TextStyle(
                color: Colors.black.withOpacity(0.25),
                fontSize: 12,
                fontFamily: 'Instrument Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontFamily: 'Instrument Sans',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
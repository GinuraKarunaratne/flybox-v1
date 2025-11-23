// lib/sender/package_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PackageDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> journey;

  const PackageDetailsScreen({Key? key, required this.journey}) : super(key: key);

  @override
  State<PackageDetailsScreen> createState() => _PackageDetailsScreenState();
}

class _PackageDetailsScreenState extends State<PackageDetailsScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Form controllers
  final TextEditingController _packageTypeController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedPackageType = '';
  final List<String> _packageTypes = [
    'Documents',
    'Electronics',
    'Clothing',
    'Food Items',
    'Medicine',
    'Books',
    'Gifts',
    'Other'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _packageTypeController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // Validate current step
    if (!_validateCurrentStep()) {
      _showMessage('Please fill all required fields', isError: true);
      return;
    }

    if (_currentStep < 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Go to receiver info screen
      _proceedToReceiverInfo();
    }
  }

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

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      return _selectedPackageType.isNotEmpty && _descriptionController.text.trim().isNotEmpty;
    } else if (_currentStep == 1) {
      return _weightController.text.trim().isNotEmpty &&
          _lengthController.text.trim().isNotEmpty &&
          _widthController.text.trim().isNotEmpty &&
          _heightController.text.trim().isNotEmpty;
    }
    return true;
  }

  void _proceedToReceiverInfo() {
    final packageDetails = {
      'packageType': _selectedPackageType,
      'description': _descriptionController.text.trim(),
      'weight': double.tryParse(_weightController.text.trim()) ?? 0.0,
      'dimensions': {
        'length': double.tryParse(_lengthController.text.trim()) ?? 0.0,
        'width': double.tryParse(_widthController.text.trim()) ?? 0.0,
        'height': double.tryParse(_heightController.text.trim()) ?? 0.0,
      },
    };

    Navigator.pushNamed(
      context,
      '/senderReceiverInfo',
      arguments: {
        'journey': widget.journey,
        'packageDetails': packageDetails,
      },
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

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
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildInputField({
    required String placeholder,
    required TextEditingController controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
  }) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 40),
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
        maxLines: maxLines,
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
          Container(
            width: 80,
            height: 36,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF242424),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Text(
                _currentStep < 1 ? 'Next' : 'Continue',
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
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _currentStep == 0 ? 'Package Details' : 'Package Size',
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

              // Main content
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
                      _buildPackageTypeStep(),
                      _buildPackageSizeStep(),
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

  Widget _buildPackageTypeStep() {
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
                _buildInputField(
                  placeholder: 'Package description',
                  controller: _descriptionController,
                  maxLines: 3,
                ),
                SizedBox(height: 24),

                // Journey info
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF006CD5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Journey',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Instrument Sans',
                          color: Color(0xFF006CD5),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${widget.journey['from']} → ${widget.journey['to']}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Instrument Sans',
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${widget.journey['date']} at ${widget.journey['time']}',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Instrument Sans',
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Available: ${widget.journey['remainingWeight'] ?? widget.journey['availableWeight']}kg',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Instrument Sans',
                          color: Color(0xFF006CD5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildPackageSizeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
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
                            hintText: 'Weight (Kg)',
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
                        'Max ${widget.journey['remainingWeight'] ?? widget.journey['availableWeight']}kg',
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
                      maxValue: 'Max 50cm',
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
                      maxValue: 'Max 20cm',
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
}

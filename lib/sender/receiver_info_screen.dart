// lib/sender/receiver_info_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReceiverInfoScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const ReceiverInfoScreen({Key? key, required this.data}) : super(key: key);

  @override
  State<ReceiverInfoScreen> createState() => _ReceiverInfoScreenState();
}

class _ReceiverInfoScreenState extends State<ReceiverInfoScreen> {
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _nameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _addressController.text.trim().isNotEmpty;
  }

  void _proceedToConfirmation() {
    if (!_isFormValid) {
      _showMessage('Please fill all required fields', isError: true);
      return;
    }

    final receiverInfo = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'notes': _notesController.text.trim(),
    };

    Navigator.pushNamed(
      context,
      '/senderConfirmation',
      arguments: {
        'journey': widget.data['journey'],
        'packageDetails': widget.data['packageDetails'],
        'receiverInfo': receiverInfo,
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
        onChanged: (value) => setState(() {}),
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
            onPressed: () => Navigator.pop(context),
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
          ),
          Container(
            width: 80,
            height: 36,
            child: ElevatedButton(
              onPressed: _isFormValid ? _proceedToConfirmation : null,
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
                'Review',
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
                    'Receiver Information',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildInputField(
                                placeholder: 'Receiver name',
                                controller: _nameController,
                              ),
                              SizedBox(height: 16),
                              _buildInputField(
                                placeholder: 'Phone number',
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                              ),
                              SizedBox(height: 16),
                              _buildInputField(
                                placeholder: 'Delivery address',
                                controller: _addressController,
                                maxLines: 3,
                              ),
                              SizedBox(height: 16),
                              _buildInputField(
                                placeholder: 'Additional notes (optional)',
                                controller: _notesController,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      _buildNavigationButtons(),
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

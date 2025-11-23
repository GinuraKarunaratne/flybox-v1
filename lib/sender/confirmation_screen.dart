// lib/sender/confirmation_screen.dart
import 'package:flutter/material.dart';
import '../services/sender_service.dart';

class ConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const ConfirmationScreen({Key? key, required this.data}) : super(key: key);

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  final SenderService _senderService = SenderService();
  bool _isLoading = false;

  Future<void> _confirmBooking() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      print('📦 [CONFIRMATION] Starting booking process...');

      final journey = widget.data['journey'];
      final packageDetails = widget.data['packageDetails'];
      final receiverInfo = widget.data['receiverInfo'];

      final bookingId = await _senderService.createBooking(
        journeyId: journey['id'],
        packageDetails: packageDetails,
        receiverInfo: receiverInfo,
      );

      print('✅ [CONFIRMATION] Booking successful: $bookingId');

      if (mounted) {
        _showSuccessDialog(bookingId);
      }
    } catch (e) {
      print('❌ [CONFIRMATION] Booking failed: $e');

      if (mounted) {
        _showMessage('Booking failed: ${e.toString()}', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog(String bookingId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text(
              'Booking Confirmed!',
              style: TextStyle(
                fontFamily: 'Instrument Sans',
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your booking has been created successfully.',
              style: TextStyle(
                fontFamily: 'Instrument Sans',
                fontSize: 14,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking ID',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'Instrument Sans',
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    bookingId,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Instrument Sans',
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF006CD5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).popUntil((route) => route.isFirst); // Go to home
            },
            child: Text(
              'Done',
              style: TextStyle(
                fontFamily: 'Instrument Sans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF006CD5),
              ),
            ),
          ),
        ],
      ),
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

  Widget _buildConfirmationText(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.black.withOpacity(0.6),
                fontSize: 13,
                fontFamily: 'Instrument Sans',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontFamily: 'Instrument Sans',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
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
            onPressed: _isLoading ? null : () => Navigator.pop(context),
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
            width: 100,
            height: 36,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _confirmBooking,
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
                      'Confirm',
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
    final journey = widget.data['journey'];
    final packageDetails = widget.data['packageDetails'];
    final receiverInfo = widget.data['receiverInfo'];

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
                    'Confirm Details',
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Journey details section
                              Text(
                                'Journey Details',
                                style: TextStyle(
                                  color: const Color(0xFF1E1E1E),
                                  fontSize: 13,
                                  fontFamily: 'Instrument Sans',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 12),
                              _buildConfirmationText('Route', '${journey['from']} → ${journey['to']}'),
                              _buildConfirmationText('Date', journey['date'] ?? 'N/A'),
                              _buildConfirmationText('Time', journey['time'] ?? 'N/A'),
                              _buildConfirmationText('Traveler', journey['userName'] ?? 'Unknown'),

                              SizedBox(height: 20),

                              // Divider
                              Container(
                                width: double.infinity,
                                height: 1,
                                color: Colors.black.withOpacity(0.1),
                              ),

                              SizedBox(height: 20),

                              // Package details section
                              Text(
                                'Package Details',
                                style: TextStyle(
                                  color: const Color(0xFF1E1E1E),
                                  fontSize: 13,
                                  fontFamily: 'Instrument Sans',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 12),
                              _buildConfirmationText('Type', packageDetails['packageType'] ?? 'N/A'),
                              _buildConfirmationText('Description', packageDetails['description'] ?? 'N/A'),
                              _buildConfirmationText('Weight', '${packageDetails['weight'] ?? 0}kg'),
                              _buildConfirmationText(
                                'Dimensions',
                                '${packageDetails['dimensions']['length']}L × ${packageDetails['dimensions']['width']}W × ${packageDetails['dimensions']['height']}H cm',
                              ),

                              SizedBox(height: 20),

                              // Divider
                              Container(
                                width: double.infinity,
                                height: 1,
                                color: Colors.black.withOpacity(0.1),
                              ),

                              SizedBox(height: 20),

                              // Receiver info section
                              Text(
                                'Receiver Information',
                                style: TextStyle(
                                  color: const Color(0xFF1E1E1E),
                                  fontSize: 13,
                                  fontFamily: 'Instrument Sans',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 12),
                              _buildConfirmationText('Name', receiverInfo['name'] ?? 'N/A'),
                              _buildConfirmationText('Phone', receiverInfo['phone'] ?? 'N/A'),
                              _buildConfirmationText('Address', receiverInfo['address'] ?? 'N/A'),
                              if (receiverInfo['notes'] != null && receiverInfo['notes'].toString().isNotEmpty)
                                _buildConfirmationText('Notes', receiverInfo['notes']),
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

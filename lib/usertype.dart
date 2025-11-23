import 'package:flutter/material.dart';

class UserTypeScreen extends StatefulWidget {
  @override
  _UserTypeScreenState createState() => _UserTypeScreenState();
}

class _UserTypeScreenState extends State<UserTypeScreen> {
  String _selectedUserType = '';

  void _selectUserType(String userType) {
    setState(() {
      _selectedUserType = userType;
    });
    // Direct navigation without popup
    Future.delayed(Duration(milliseconds: 200), () {
      if (userType == 'Traveler') {
        Navigator.pushReplacementNamed(context, '/travelerSetup');
      } else {
        Navigator.pushReplacementNamed(context, '/browseJourneys');
      }
    });
  }
  

  Widget _buildUserTypeButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFDE58) : const Color(0xFFD9D9D9),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            width: 1,
            color: isSelected ? const Color(0xFFC3A301) : const Color(0xFF888888),
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFFFFDE58).withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ] : null,
        ),
        child: Center(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'I\'m a ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: 'Instrument Sans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextSpan(
                  text: title,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontFamily: 'Instrument Sans',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
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
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Top spacer to center the content
                Expanded(flex: 1, child: Container()),
                
                // Main white container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        'Choose your role to get started',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.70),
                          fontSize: 16,
                          fontFamily: 'Instrument Sans',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      
                      SizedBox(height: 32),
                      
                      // Sender button
                      _buildUserTypeButton(
                        title: 'Sender',
                        isSelected: _selectedUserType == 'Sender',
                        onTap: () => _selectUserType('Sender'),
                      ),
                      
                      SizedBox(height: 12),
                      
                      // OR text
                      Text(
                        'or',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.80),
                          fontSize: 14,
                          fontFamily: 'Instrument Sans',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      
                      SizedBox(height: 12),
                      
                      // Traveler button
                      _buildUserTypeButton(
                        title: 'Traveler',
                        isSelected: _selectedUserType == 'Traveler',
                        onTap: () => _selectUserType('Traveler'),
                      ),
                      
                      SizedBox(height: 32),
                      
                      // Info text
                      Text(
                        'Senders can request package deliveries.\nTravelers can offer luggage space.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontFamily: 'Instrument Sans',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Bottom spacer
                Expanded(flex: 2, child: Container()),
                
                // Back button
                Container(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(color: Colors.white.withOpacity(0.5)),
                      ),
                    ),
                    child: Text(
                      'Back to Home',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Instrument Sans',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
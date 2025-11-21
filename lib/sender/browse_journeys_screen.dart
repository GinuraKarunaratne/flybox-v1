// lib/sender/browse_journeys_screen.dart
import 'package:flutter/material.dart';
import '../services/sender_service.dart';

class BrowseJourneysScreen extends StatefulWidget {
  const BrowseJourneysScreen({Key? key}) : super(key: key);

  @override
  State<BrowseJourneysScreen> createState() => _BrowseJourneysScreenState();
}

class _BrowseJourneysScreenState extends State<BrowseJourneysScreen> {
  final SenderService _senderService = SenderService();
  List<Map<String, dynamic>> _journeys = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadJourneys();
  }

  Future<void> _loadJourneys() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final journeys = await _senderService.getAvailableJourneys();
      setState(() {
        _journeys = journeys;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _selectJourney(Map<String, dynamic> journey) {
    Navigator.pushNamed(
      context,
      '/senderPackageDetails',
      arguments: journey,
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
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Available Journeys',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontFamily: 'Instrument Sans',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 56),
                      child: Text(
                        'Select a traveler to send your package',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontFamily: 'Instrument Sans',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
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
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006CD5)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.withOpacity(0.5)),
            SizedBox(height: 16),
            Text(
              'Error loading journeys',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadJourneys,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF006CD5),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_journeys.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.withOpacity(0.5)),
            SizedBox(height: 16),
            Text(
              'No journeys available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Check back later for available travelers',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadJourneys,
      child: ListView.builder(
        itemCount: _journeys.length,
        itemBuilder: (context, index) {
          return _buildJourneyCard(_journeys[index]);
        },
      ),
    );
  }

  Widget _buildJourneyCard(Map<String, dynamic> journey) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectJourney(journey),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            journey['from'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Instrument Sans',
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            journey['to'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Instrument Sans',
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      color: Color(0xFF006CD5),
                      size: 24,
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Divider
                Container(
                  height: 1,
                  color: Colors.grey.withOpacity(0.2),
                ),

                SizedBox(height: 12),

                // Details
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    SizedBox(width: 6),
                    Text(
                      journey['date'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'Instrument Sans',
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.access_time, size: 16, color: Colors.grey),
                    SizedBox(width: 6),
                    Text(
                      journey['time'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'Instrument Sans',
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: Colors.grey),
                    SizedBox(width: 6),
                    Text(
                      journey['userName'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'Instrument Sans',
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Available Weight
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFF006CD5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: Color(0xFF006CD5),
                      ),
                      SizedBox(width: 6),
                      Text(
                        '${journey['remainingWeight'] ?? journey['availableWeight'] ?? 0}kg available',
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

                // Package type if specified
                if (journey['packageType'] != null &&
                    journey['packageType'] != 'All') ...[
                  SizedBox(height: 8),
                  Text(
                    'Accepts: ${journey['packageType']}',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Instrument Sans',
                      color: Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

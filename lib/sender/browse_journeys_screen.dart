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
  List<Map<String, dynamic>> _filteredJourneys = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filters
  String _selectedFromFilter = '';
  String _selectedToFilter = '';
  String _selectedPackageTypeFilter = '';
  List<String> _availableFromLocations = [];
  List<String> _availableToLocations = [];
  final List<String> _packageTypes = ['All', 'Documents', 'Electronics', 'Clothing', 'Food Items', 'Medicine'];

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

      // Extract unique locations
      Set<String> fromSet = {};
      Set<String> toSet = {};
      for (var journey in journeys) {
        if (journey['from'] != null) fromSet.add(journey['from']);
        if (journey['to'] != null) toSet.add(journey['to']);
      }

      setState(() {
        _journeys = journeys;
        _filteredJourneys = journeys;
        _availableFromLocations = fromSet.toList()..sort();
        _availableToLocations = toSet.toList()..sort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredJourneys = _journeys.where((journey) {
        bool matchesFrom = _selectedFromFilter.isEmpty || journey['from'] == _selectedFromFilter;
        bool matchesTo = _selectedToFilter.isEmpty || journey['to'] == _selectedToFilter;
        bool matchesPackageType = _selectedPackageTypeFilter.isEmpty ||
                                  _selectedPackageTypeFilter == 'All' ||
                                  journey['packageType'] == _selectedPackageTypeFilter ||
                                  journey['packageType'] == 'All';
        return matchesFrom && matchesTo && matchesPackageType;
      }).toList();
    });
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Journeys',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Instrument Sans',
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        _selectedFromFilter = '';
                        _selectedToFilter = '';
                        _selectedPackageTypeFilter = '';
                      });
                      setState(() {
                        _selectedFromFilter = '';
                        _selectedToFilter = '';
                        _selectedPackageTypeFilter = '';
                      });
                      _applyFilters();
                    },
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        fontFamily: 'Instrument Sans',
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // From Filter
              Text(
                'From',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Instrument Sans',
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFromFilter.isEmpty ? null : _selectedFromFilter,
                    hint: Text('Any location', style: TextStyle(fontFamily: 'Instrument Sans')),
                    isExpanded: true,
                    items: _availableFromLocations.map((location) {
                      return DropdownMenuItem(
                        value: location,
                        child: Text(location, style: TextStyle(fontFamily: 'Instrument Sans')),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() => _selectedFromFilter = value ?? '');
                      setState(() => _selectedFromFilter = value ?? '');
                    },
                  ),
                ),
              ),

              SizedBox(height: 16),

              // To Filter
              Text(
                'To',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Instrument Sans',
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedToFilter.isEmpty ? null : _selectedToFilter,
                    hint: Text('Any location', style: TextStyle(fontFamily: 'Instrument Sans')),
                    isExpanded: true,
                    items: _availableToLocations.map((location) {
                      return DropdownMenuItem(
                        value: location,
                        child: Text(location, style: TextStyle(fontFamily: 'Instrument Sans')),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() => _selectedToFilter = value ?? '');
                      setState(() => _selectedToFilter = value ?? '');
                    },
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Package Type Filter
              Text(
                'Package Type',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Instrument Sans',
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPackageTypeFilter.isEmpty ? null : _selectedPackageTypeFilter,
                    hint: Text('Any type', style: TextStyle(fontFamily: 'Instrument Sans')),
                    isExpanded: true,
                    items: _packageTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type, style: TextStyle(fontFamily: 'Instrument Sans')),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() => _selectedPackageTypeFilter = value ?? '');
                      setState(() => _selectedPackageTypeFilter = value ?? '');
                    },
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Apply Button
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _applyFilters();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF006CD5),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Instrument Sans',
                    ),
                  ),
                ),
              ),

              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        IconButton(
                          icon: Icon(Icons.filter_list, color: Colors.white),
                          onPressed: _showFilters,
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
        itemCount: _filteredJourneys.length,
        itemBuilder: (context, index) {
          return _buildJourneyCard(_filteredJourneys[index]);
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

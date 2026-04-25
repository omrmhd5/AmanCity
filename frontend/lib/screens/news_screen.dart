import 'package:flutter/material.dart';
import '../models/osint_incident.dart';
import '../services/backend_api/osint_api_service.dart';
import '../utils/app_theme.dart';
import '../widgets/news/news_header.dart';
import '../widgets/news/news_feed_card.dart';
import '../widgets/news/news_scan_button.dart';
import '../widgets/news/news_scan_result_banner.dart';
import '../widgets/news/news_search_bar.dart';
import '../widgets/news/news_type_filter.dart';
import 'news_incident_detail_sheet.dart';

class NewsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const NewsScreen({Key? key, this.onBack}) : super(key: key);

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<OsintIncident> _incidents = [];
  bool _isLoading = false;
  bool _isScanning = false;
  String? _error;
  String? _scanError;
  Map<String, dynamic>? _lastScanResult;
  String _searchQuery = '';
  String? _selectedTypeFilter;
  bool _showAllTypes = false;

  @override
  void initState() {
    super.initState();
    _fetchIncidents();
  }

  /// Fetch incidents from backend
  Future<void> _fetchIncidents() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final incidents = await OsintApiService.fetchIncidents();
      setState(() {
        _incidents = incidents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  /// Get filtered incidents based on search query and type filter
  List<OsintIncident> _getFilteredIncidents() {
    return _incidents.where((incident) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          incident.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          incident.locationText.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      final matchesFilter =
          _selectedTypeFilter == null ||
          incident.type.toLowerCase() == _selectedTypeFilter!.toLowerCase();

      return matchesSearch && matchesFilter;
    }).toList();
  }

  /// Trigger Grok scan
  Future<void> _triggerScan() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _scanError = null;
      _lastScanResult = null;
    });

    try {
      final result = await OsintApiService.triggerScan();
      setState(() {
        _lastScanResult = result;
        _isScanning = false;
      });

      // Re-fetch incidents after scan
      await _fetchIncidents();

      // Auto-dismiss banner after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _lastScanResult = null;
          });
        }
      });
    } catch (e) {
      setState(() {
        _scanError = e.toString().replaceFirst('Exception: ', '');
        _isScanning = false;
      });
    }
  }

  /// Open detail sheet for incident
  void _showIncidentDetails(OsintIncident incident) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NewsIncidentDetailSheet(incident: incident),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.onBack == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && widget.onBack != null) {
          widget.onBack!();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.getBackgroundColor(),
        body: SafeArea(
          child: _isLoading && _incidents.isEmpty
              ? _buildLoadingState()
              : RefreshIndicator(
                  onRefresh: _fetchIncidents,
                  child: ListView(
                    children: [
                      // Header
                      NewsHeader(onBackPressed: widget.onBack),

                      // Scan Button
                      NewsScanButton(
                        onPressed: _triggerScan,
                        isLoading: _isScanning,
                        errorMessage: _scanError,
                      ),
                      const SizedBox(height: 8),

                      // Scan Result Banner
                      if (_lastScanResult != null)
                        NewsScanResultBanner(
                          scanned: _lastScanResult!['scanned'] ?? 0,
                          saved: _lastScanResult!['saved'] ?? 0,
                          onDismiss: () {
                            setState(() {
                              _lastScanResult = null;
                            });
                          },
                        ),

                      const SizedBox(height: 12),

                      // Search Bar
                      NewsSearchBar(
                        searchQuery: _searchQuery,
                        onSearchChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),

                      // Type Filter
                      NewsTypeFilter(
                        selectedFilter: _selectedTypeFilter,
                        onFilterChanged: (filter) {
                          setState(() => _selectedTypeFilter = filter);
                        },
                        showAllTypes: _showAllTypes,
                        onShowAllTypesChanged: (value) {
                          setState(() => _showAllTypes = value);
                        },
                      ),

                      // Incidents List or Empty State
                      if (_error != null)
                        _buildErrorState()
                      else if (_incidents.isEmpty)
                        _buildEmptyState()
                      else if (_getFilteredIncidents().isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'No incidents match your search or filter',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.getSecondaryTextColor(),
                              ),
                            ),
                          ),
                        )
                      else
                        ..._buildIncidentsList(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(AppTheme.getSecondaryTextColor()),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppTheme.getSecondaryTextColor(),
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load news',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.getPrimaryTextColor(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'An error occurred',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.getSecondaryTextColor(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchIncidents,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.newspaper_outlined,
            size: 48,
            color: AppTheme.getSecondaryTextColor(),
          ),
          const SizedBox(height: 16),
          Text(
            'No news yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.getPrimaryTextColor(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fetch the latest incidents from Twitter using the button above',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.getSecondaryTextColor(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildIncidentsList() {
    final filteredIncidents = _getFilteredIncidents();
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          '${filteredIncidents.length} of ${_incidents.length} incidents',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.getSecondaryTextColor(),
          ),
        ),
      ),
      ...filteredIncidents
          .map(
            (incident) => NewsFeedCard(
              incident: incident,
              onTap: () => _showIncidentDetails(incident),
            ),
          )
          .toList(),
      const SizedBox(height: 20),
    ];
  }
}

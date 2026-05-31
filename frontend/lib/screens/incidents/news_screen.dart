import 'package:flutter/material.dart';
import '../../data/app_colors.dart';
import '../../models/incidents/osint_incident.dart';
import '../../services/incidents/osint_api_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/news/news_header.dart';
import '../../widgets/news/news_feed_card.dart';
import '../../widgets/news/news_scan_button.dart';
import '../../widgets/news/news_scan_result_banner.dart';
import '../../widgets/news/news_search_bar.dart';
import '../../widgets/news/news_type_filter.dart';
import 'news_incident_detail_sheet.dart';

class NewsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final ValueNotifier<int>? activationSignal;

  const NewsScreen({Key? key, this.onBack, this.activationSignal})
    : super(key: key);

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

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
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    widget.activationSignal?.addListener(_onActivation);
    _fetchIncidents();
  }

  @override
  void dispose() {
    widget.activationSignal?.removeListener(_onActivation);
    _entryController.dispose();
    super.dispose();
  }

  void _onActivation() {
    _entryController.forward(from: 0);
  }

  Widget _animated(Widget child, {double start = 0.0, double end = 1.0}) {
    final anim = CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
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
              : Column(
                  children: [
                    // Header
                    _animated(
                      NewsHeader(onBackPressed: widget.onBack),
                      start: 0.0,
                      end: 0.5,
                    ),
                    // Teal gradient divider
                    _animated(
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.secondary.withOpacity(0.0),
                              AppColors.secondary.withOpacity(0.3),
                              AppColors.secondary.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                      start: 0.05,
                      end: 0.55,
                    ),
                    // Scrollable content
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _fetchIncidents,
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          children: [
                            // Scan Button
                            _animated(
                              NewsScanButton(
                                onPressed: _triggerScan,
                                isLoading: _isScanning,
                                errorMessage: _scanError,
                              ),
                              start: 0.1,
                              end: 0.65,
                            ),

                            // Scan Result Banner
                            if (_lastScanResult != null)
                              _animated(
                                NewsScanResultBanner(
                                  scanned: _lastScanResult!['scanned'] ?? 0,
                                  saved: _lastScanResult!['saved'] ?? 0,
                                  onDismiss: () {
                                    setState(() => _lastScanResult = null);
                                  },
                                ),
                                start: 0.1,
                                end: 0.65,
                              ),

                            // Search Bar
                            _animated(
                              NewsSearchBar(
                                searchQuery: _searchQuery,
                                onSearchChanged: (value) {
                                  setState(() => _searchQuery = value);
                                },
                              ),
                              start: 0.15,
                              end: 0.7,
                            ),

                            // Type Filter
                            _animated(
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
                              start: 0.2,
                              end: 0.75,
                            ),

                            // Section label
                            _animated(
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  12,
                                  20,
                                  4,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.newspaper_rounded,
                                      size: 15,
                                      color: AppColors.secondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'INCIDENTS',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.getSecondaryTextColor(),
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              start: 0.25,
                              end: 0.8,
                            ),

                            // Incidents List or States
                            if (_error != null)
                              _buildErrorState()
                            else if (_incidents.isEmpty)
                              _buildEmptyState()
                            else if (_getFilteredIncidents().isEmpty)
                              _buildNoResultsState()
                            else
                              ..._buildIncidentsList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(AppColors.secondary),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 36,
              color: AppColors.danger,
            ),
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
          GestureDetector(
            onTap: _fetchIncidents,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.secondary.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
            ),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.newspaper_outlined,
              size: 36,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No incidents yet',
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

  Widget _buildNoResultsState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
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
    );
  }

  List<Widget> _buildIncidentsList() {
    final filteredIncidents = _getFilteredIncidents();
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Text(
          '${filteredIncidents.length} of ${_incidents.length} incidents',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.getSecondaryTextColor(),
          ),
        ),
      ),
      ...filteredIncidents.asMap().entries.map((entry) {
        final i = entry.key;
        final incident = entry.value;
        return _animated(
          NewsFeedCard(
            incident: incident,
            onTap: () => _showIncidentDetails(incident),
          ),
          start: (0.3 + i * 0.04).clamp(0.0, 0.85),
          end: (0.65 + i * 0.04).clamp(0.0, 1.0),
        );
      }),
      const SizedBox(height: 20),
    ];
  }
}

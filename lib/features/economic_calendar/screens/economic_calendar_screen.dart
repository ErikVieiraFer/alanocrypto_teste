import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';

class EconomicCalendarScreen extends StatefulWidget {
  const EconomicCalendarScreen({Key? key}) : super(key: key);

  @override
  State<EconomicCalendarScreen> createState() => _EconomicCalendarScreenState();
}

class _EconomicCalendarScreenState extends State<EconomicCalendarScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _allEvents = [];
  List<Map<String, dynamic>> _filteredEvents = [];
  bool _isLoading = true;
  int _currentTabIndex = 1; // Start on "Today"

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
          _filterEvents();
        });
      }
    });
    _loadCalendarData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCalendarData() async {
    setState(() => _isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('market_cache')
          .doc('economic_calendar')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['data'] != null) {
          _allEvents = List<Map<String, dynamic>>.from(data['data']);
          _filterEvents();
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar calendário: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterEvents() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(const Duration(days: 7));

    _filteredEvents = _allEvents.where((event) {
      final eventDate = _parseEventDate(event['date']);
      if (eventDate == null) return false;

      final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);

      switch (_currentTabIndex) {
        case 0: // Yesterday
          return eventDay.isAtSameMomentAs(yesterday);
        case 1: // Today
          return eventDay.isAtSameMomentAs(today);
        case 2: // Tomorrow
          return eventDay.isAtSameMomentAs(tomorrow);
        case 3: // This Week
          return eventDay.isAfter(yesterday) && eventDay.isBefore(weekEnd);
        default:
          return false;
      }
    }).toList();

    // Sort by date
    _filteredEvents.sort((a, b) {
      final dateA = _parseEventDate(a['date']);
      final dateB = _parseEventDate(b['date']);
      if (dateA == null || dateB == null) return 0;
      return dateA.compareTo(dateB);
    });
  }

  DateTime? _parseEventDate(dynamic dateValue) {
    if (dateValue == null) return null;
    try {
      if (dateValue is String) {
        return DateTime.parse(dateValue.replaceAll(' ', 'T'));
      } else if (dateValue is Timestamp) {
        return dateValue.toDate();
      }
    } catch (e) {
      debugPrint('Erro ao parsear data: $e');
    }
    return null;
  }

  Color _getImpactColor(dynamic importance) {
    final value = int.tryParse(importance?.toString() ?? '0') ?? 0;
    switch (value) {
      case 3:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getImpactLabel(dynamic importance) {
    final value = int.tryParse(importance?.toString() ?? '0') ?? 0;
    switch (value) {
      case 3:
        return 'HIGH';
      case 2:
        return 'MEDIUM';
      case 1:
        return 'LOW';
      default:
        return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Calendário Econômico',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.filter_list, color: Colors.white),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.search, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Acompanhe os eventos econômicos importantes',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF1a1f26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                tabs: const [
                  Tab(text: 'Ontem'),
                  Tab(text: 'Hoje'),
                  Tab(text: 'Amanhã'),
                  Tab(text: 'Semana'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Events List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryGreen,
                      ),
                    )
                  : _filteredEvents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 64,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhum evento econômico',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'para este período',
                                style: TextStyle(
                                  color: AppTheme.textTertiary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadCalendarData,
                          color: AppTheme.primaryGreen,
                          backgroundColor: const Color(0xFF1a1f26),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _filteredEvents.length,
                            itemBuilder: (context, index) {
                              final event = _filteredEvents[index];
                              return _buildEventCard(event);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final importance = event['importance'];
    final impactColor = _getImpactColor(importance);
    final impactLabel = _getImpactLabel(importance);

    final eventDate = _parseEventDate(event['date']);
    final timeStr = eventDate != null
        ? DateFormat('HH:mm').format(eventDate)
        : '00:00';
    final dateStr = eventDate != null
        ? DateFormat('dd/MM').format(eventDate)
        : '';

    final currency = event['currency']?.toString() ?? 'USD';
    final country = event['country']?.toString() ?? '';
    final title = event['event']?.toString() ?? 'Evento';
    final actual = event['actual']?.toString() ?? '-';
    final forecast = event['forecast']?.toString() ?? '-';
    final previous = event['previous']?.toString() ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1f26),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: impactColor,
            width: 4,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: impactColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    impactLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: impactColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  currency,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (country.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    country,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (dateStr.isNotEmpty)
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Event title
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // Values row
            Row(
              children: [
                Expanded(
                  child: _buildValueItem('Anterior', previous, AppTheme.textSecondary),
                ),
                Expanded(
                  child: _buildValueItem('Previsão', forecast, AppTheme.textSecondary),
                ),
                Expanded(
                  child: _buildValueItem('Atual', actual, AppTheme.primaryGreen),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.textTertiary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

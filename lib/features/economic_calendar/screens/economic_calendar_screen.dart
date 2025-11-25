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
  int _currentTabIndex = 2; // Start on "Today" (middle tab)
  late List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    // Gerar 5 dias: -2, -1, hoje, +1, +2
    final today = DateTime.now();
    _dates = List.generate(5, (i) => today.add(Duration(days: i - 2)));

    _tabController = TabController(length: 5, vsync: this, initialIndex: 2);
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
    final selectedDate = _dates[_currentTabIndex];

    _filteredEvents = _allEvents.where((event) {
      final eventDate = _parseEventDate(event['date']);
      if (eventDate == null) return false;

      return eventDate.year == selectedDate.year &&
             eventDate.month == selectedDate.month &&
             eventDate.day == selectedDate.day;
    }).toList();

    // Ordenar por hora
    _filteredEvents.sort((a, b) {
      final dateA = _parseEventDate(a['date']) ?? DateTime.now();
      final dateB = _parseEventDate(b['date']) ?? DateTime.now();
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
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryGreen,
                indicatorWeight: 3.0,
                labelColor: AppTheme.primaryGreen,
                unselectedLabelColor: AppTheme.textSecondary,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
                tabs: _dates.map((date) => Tab(
                  text: DateFormat('dd/MM').format(date),
                )).toList(),
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
                            padding: EdgeInsets.zero,
                            itemCount: _filteredEvents.length,
                            itemBuilder: (context, index) {
                              final event = _filteredEvents[index];
                              return _buildEventItem(event);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // LAYOUT COMPACTO ESTILO TRADING APP
  // ═══════════════════════════════════════════════════════════

  Widget _buildEventItem(Map<String, dynamic> event) {
    final eventDate = _parseEventDate(event['date']);
    final timeStr = eventDate != null ? DateFormat('HH:mm').format(eventDate) : '--:--';

    final country = event['country']?.toString() ?? '';
    final currency = _getCurrencyFromCountry(country);
    final flag = _getFlagEmoji(country);
    final title = event['event']?.toString() ?? 'Evento';

    final actual = event['actual'];
    final forecast = event['forecast'];
    final previous = event['previous'];

    final importance = event['importance'] ?? 1;
    final isUS = event['isUS'] == true || country == 'US';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // COLUNA 1: Horário
          SizedBox(
            width: 50,
            child: Text(
              timeStr,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // COLUNA 2: Moeda + Bandeira
          SizedBox(
            width: 70,
            child: Row(
              children: [
                Text(
                  currency,
                  style: TextStyle(
                    color: isUS ? AppTheme.primaryGreen : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(flag, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),

          // COLUNA 3: Conteúdo principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Linha 1: Indicador de impacto + Nome do evento
                Row(
                  children: [
                    _buildImpactIndicator(importance),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Linha 2: Valores (Act | Cons | Prev)
                if (actual != null || forecast != null || previous != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _buildValuesRow(actual, forecast, previous),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Indicador de impacto com círculos coloridos
  Widget _buildImpactIndicator(dynamic importance) {
    final level = int.tryParse(importance.toString()) ?? 1;

    Color activeColor;
    switch (level) {
      case 3:
        activeColor = Colors.red;
        break;
      case 2:
        activeColor = Colors.orange;
        break;
      default:
        activeColor = Colors.grey;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isActive = index < level;
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? activeColor : Colors.grey.withValues(alpha: 0.3),
          ),
        );
      }),
    );
  }

  // Linha de valores: Act | Cons | Prev
  Widget _buildValuesRow(dynamic actual, dynamic forecast, dynamic previous) {
    final parts = <Widget>[];

    if (actual != null && actual.toString() != '-' && actual.toString().isNotEmpty) {
      final actualStr = _formatValue(actual);
      final isPositive = actualStr.startsWith('+') ||
          (double.tryParse(actualStr.replaceAll('%', '').replaceAll(',', '')) ?? 0) > 0;
      final isNegative = actualStr.startsWith('-');

      parts.add(
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Act: ',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              TextSpan(
                text: actualStr,
                style: TextStyle(
                  color: isNegative ? Colors.red : (isPositive ? AppTheme.primaryGreen : Colors.white),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (forecast != null && forecast.toString() != '-' && forecast.toString().isNotEmpty) {
      if (parts.isNotEmpty) {
        parts.add(Text(' | ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)));
      }
      parts.add(
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Cons: ',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              TextSpan(
                text: _formatValue(forecast),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (previous != null && previous.toString() != '-' && previous.toString().isNotEmpty) {
      if (parts.isNotEmpty) {
        parts.add(Text(' | ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)));
      }
      parts.add(
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Prev: ',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              TextSpan(
                text: _formatValue(previous),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (parts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(children: parts);
  }

  // Formatar valores numéricos
  String _formatValue(dynamic value) {
    if (value == null) return '-';
    final str = value.toString();
    if (str.isEmpty || str == '-') return '-';

    // Se já tem %, manter
    if (str.contains('%')) return str;

    // Tentar formatar número
    final num = double.tryParse(str.replaceAll(',', ''));
    if (num != null) {
      if (num.abs() >= 1000000000) {
        return '${(num / 1000000000).toStringAsFixed(1)}B';
      } else if (num.abs() >= 1000000) {
        return '${(num / 1000000).toStringAsFixed(1)}M';
      } else if (num.abs() >= 1000) {
        return '${(num / 1000).toStringAsFixed(1)}K';
      }
      return num.toStringAsFixed(num.truncateToDouble() == num ? 0 : 2);
    }

    return str;
  }

  // Obter moeda do país
  String _getCurrencyFromCountry(String country) {
    const currencies = {
      'US': 'USD',
      'EU': 'EUR',
      'GB': 'GBP',
      'JP': 'JPY',
      'CN': 'CNY',
      'CA': 'CAD',
      'AU': 'AUD',
      'NZ': 'NZD',
      'CH': 'CHF',
      'BR': 'BRL',
      'MX': 'MXN',
      'ZA': 'ZAR',
      'KR': 'KRW',
      'IN': 'INR',
      'RU': 'RUB',
    };
    return currencies[country] ?? country;
  }

  // Obter emoji de bandeira
  String _getFlagEmoji(String country) {
    const flags = {
      'US': '🇺🇸',
      'EU': '🇪🇺',
      'GB': '🇬🇧',
      'JP': '🇯🇵',
      'CN': '🇨🇳',
      'CA': '🇨🇦',
      'AU': '🇦🇺',
      'NZ': '🇳🇿',
      'CH': '🇨🇭',
      'BR': '🇧🇷',
      'MX': '🇲🇽',
      'ZA': '🇿🇦',
      'KR': '🇰🇷',
      'IN': '🇮🇳',
      'RU': '🇷🇺',
    };
    return flags[country] ?? '🏳️';
  }
}

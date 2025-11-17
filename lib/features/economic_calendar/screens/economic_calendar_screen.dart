import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/economic_calendar_service.dart';
import '../../../theme/app_theme.dart';

class EconomicCalendarScreen extends StatefulWidget {
  const EconomicCalendarScreen({Key? key}) : super(key: key);

  @override
  State<EconomicCalendarScreen> createState() => _EconomicCalendarScreenState();
}

class _EconomicCalendarScreenState extends State<EconomicCalendarScreen> {
  late final EconomicCalendarService _calendarService;
  List<EconomicEvent>? _events;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // SEM API KEY - usa Cloud Function
    _calendarService = EconomicCalendarService();

    _loadCalendar();
  }

  Future<void> _loadCalendar() async {
    setState(() => _isLoading = true);

    final events = await _calendarService.getEconomicCalendar(days: 7);

    if (mounted) {
      setState(() {
        _events = events;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundColor,
      padding: const EdgeInsets.all(16),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : _events == null || _events!.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum evento econômico disponível',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCalendar,
                  color: AppTheme.primaryGreen,
                  child: ListView.builder(
                    itemCount: _events!.length,
                    itemBuilder: (context, index) {
                      final event = _events![index];
                      return _buildEventCard(event);
                    },
                  ),
                ),
    );
  }

  Widget _buildEventCard(EconomicEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: event.getImpactColor(),
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: event.getImpactColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    event.impact.toUpperCase(),
                    style: TextStyle(
                      color: event.getImpactColor(),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  event.country,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd/MM HH:mm').format(event.date),
                  style: TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              event.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (event.previous != null || event.forecast != null || event.actual != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    if (event.previous != null)
                      _buildDataChip('Anterior', event.previous!),
                    if (event.forecast != null)
                      _buildDataChip('Previsão', event.forecast!),
                    if (event.actual != null)
                      _buildDataChip('Atual', event.actual!, highlight: true),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataChip(String label, String value, {bool highlight = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? AppTheme.primaryGreen.withOpacity(0.2)
            : AppTheme.cardMedium,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: highlight ? AppTheme.primaryGreen : AppTheme.textTertiary,
              fontSize: 10,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: highlight ? AppTheme.primaryGreen : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

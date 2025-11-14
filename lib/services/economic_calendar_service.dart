import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class EconomicCalendarService {
  static const String _baseUrl = 'https://financialmodelingprep.com/api/v3';
  final String apiKey;

  EconomicCalendarService({required this.apiKey});

  Future<List<EconomicEvent>> getEconomicCalendar({int days = 7}) async {
    try {
      final now = DateTime.now();
      final fromDate = now.subtract(const Duration(days: 1));
      final toDate = now.add(Duration(days: days));

      final from = _formatDate(fromDate);
      final to = _formatDate(toDate);

      print('📅 Buscando eventos de $from até $to');

      final url = '$_baseUrl/economic_calendar?from=$from&to=$to&apikey=$apiKey';
      print('🔗 URL: $url');

      final response = await http.get(Uri.parse(url));

      print('📡 Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        print('✅ ${data.length} eventos encontrados');

        if (data.isEmpty) {
          return [];
        }

        return data
            .map((item) {
              try {
                return EconomicEvent.fromJson(item);
              } catch (e) {
                print('❌ Erro ao parsear evento: $e');
                return null;
              }
            })
            .whereType<EconomicEvent>()
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
      }

      return [];
    } catch (e, stackTrace) {
      print('❌ Erro ao buscar calendário: $e');
      print('📍 Stack: $stackTrace');
      return [];
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class EconomicEvent {
  final String title;
  final String country;
  final DateTime date;
  final String impact;
  final String? previous;
  final String? estimate;
  final String? actual;

  EconomicEvent({
    required this.title,
    required this.country,
    required this.date,
    required this.impact,
    this.previous,
    this.estimate,
    this.actual,
  });

  factory EconomicEvent.fromJson(Map<String, dynamic> json) {
    // Determinar impacto baseado no evento
    String determineImpact(String event) {
      final highImpact = ['gdp', 'employment', 'interest rate', 'inflation', 'nonfarm'];
      final mediumImpact = ['retail', 'manufacturing', 'consumer', 'pmi'];

      final eventLower = event.toLowerCase();

      if (highImpact.any((keyword) => eventLower.contains(keyword))) {
        return 'High';
      } else if (mediumImpact.any((keyword) => eventLower.contains(keyword))) {
        return 'Medium';
      }
      return 'Low';
    }

    final event = json['event'] ?? '';

    return EconomicEvent(
      title: event,
      country: json['country'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      impact: json['impact'] ?? determineImpact(event),
      previous: json['previous']?.toString(),
      estimate: json['estimate']?.toString(),
      actual: json['actual']?.toString(),
    );
  }

  Color getImpactColor() {
    switch (impact.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class EconomicCalendarService {
  // URL da Cloud Function (será preenchida após deploy)
  static const String _cloudFunctionUrl =
    'https://us-central1-alanocryptofx-v2.cloudfunctions.net/getEconomicCalendar';

  Future<List<EconomicEvent>> getEconomicCalendar({int days = 7}) async {
    try {
      final response = await http.get(
        Uri.parse(_cloudFunctionUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == true && data['response'] != null) {
          final List<dynamic> responseData = data['response'];

          if (responseData.isEmpty) {
            return [];
          }

          final events = responseData
              .map((item) {
                try {
                  return EconomicEvent.fromJson(item);
                } catch (e) {
                  return null;
                }
              })
              .whereType<EconomicEvent>()
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));

          return events;
        } else {
          return [];
        }
      } else {
        print('❌ Erro HTTP ao buscar calendário: ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao buscar calendário: $e');
      return [];
    }
  }
}

class EconomicEvent {
  final String title;
  final String country;
  final DateTime date;
  final String impact; // Vamos converter importance -> impact
  final String? previous;
  final String? forecast;
  final String? actual;
  final String? indicator;
  final String? comment;

  EconomicEvent({
    required this.title,
    required this.country,
    required this.date,
    required this.impact,
    this.previous,
    this.forecast,
    this.actual,
    this.indicator,
    this.comment,
  });

  factory EconomicEvent.fromJson(Map<String, dynamic> json) {
    // Parse da data (formato: "2025-11-16 11:00:00")
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();

      try {
        if (dateValue is String) {
          // Remover possível timezone
          final cleaned = dateValue.split('.')[0].trim();
          return DateTime.parse(cleaned.replaceAll(' ', 'T'));
        } else if (dateValue is int) {
          return DateTime.fromMillisecondsSinceEpoch(dateValue * 1000);
        }
      } catch (e) {
        // Silencioso - retorna data atual em caso de erro
      }

      return DateTime.now();
    }

    // Converter importance (0-3) para impact (Low/Medium/High)
    String convertImportanceToImpact(dynamic importance) {
      if (importance == null) return 'Low';

      final importanceValue = int.tryParse(importance.toString()) ?? 0;

      switch (importanceValue) {
        case 3:
          return 'High';
        case 2:
          return 'Medium';
        case 1:
          return 'Low';
        default:
          return 'Low';
      }
    }

    final title = json['title'] ?? json['event'] ?? json['name'] ?? '';
    final country = json['country'] ?? '';
    final date = parseDate(json['date'] ?? json['time']);
    final impact = convertImportanceToImpact(json['importance']);

    return EconomicEvent(
      title: title,
      country: country,
      date: date,
      impact: impact,
      previous: json['previous']?.toString(),
      forecast: json['forecast']?.toString() ?? json['estimate']?.toString(),
      actual: json['actual']?.toString(),
      indicator: json['indicator']?.toString(),
      comment: json['comment']?.toString(),
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

  String getImpactLabel() {
    switch (impact.toLowerCase()) {
      case 'high':
        return 'ALTA';
      case 'medium':
        return 'MÉDIA';
      default:
        return 'BAIXA';
    }
  }
}

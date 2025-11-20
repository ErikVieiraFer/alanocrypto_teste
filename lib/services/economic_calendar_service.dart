import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EconomicCalendarService {
  Future<List<EconomicEvent>> getEconomicCalendar({int days = 7}) async {
    try {
      // Buscar do cache no Firestore
      final doc = await FirebaseFirestore.instance
          .collection('market_cache')
          .doc('economic_calendar')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['data'] != null) {
          final List<dynamic> responseData = data['data'];

          if (responseData.isEmpty) {
            return [];
          }

          final events = responseData
              .map((item) {
                try {
                  return EconomicEvent.fromJson(Map<String, dynamic>.from(item));
                } catch (e) {
                  return null;
                }
              })
              .whereType<EconomicEvent>()
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));

          return events;
        }
      }

      return [];
    } catch (e) {
      print('❌ Erro ao buscar calendário do cache: $e');
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

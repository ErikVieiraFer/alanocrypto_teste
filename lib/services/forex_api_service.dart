import 'dart:convert';
import 'package:http/http.dart' as http;

class ForexApiService {
  static const String _baseUrl = 'https://fcsapi.com/api-v3';
  final String apiKey;

  ForexApiService({required this.apiKey});

  Future<List<ForexPair>> getForexPairs() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/forex/latest?symbol=EUR/USD,GBP/USD,USD/JPY,AUD/USD,USD/CAD,NZD/USD,EUR/GBP&access_key=$apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == true) {
          final List<dynamic> responseData = data['response'];
          return responseData.map((item) => ForexPair.fromJson(item)).toList();
        }
      }

      return [];
    } catch (e) {
      print('Error fetching forex data: $e');
      return [];
    }
  }
}

class ForexPair {
  final String symbol;
  final double price;
  final double change;
  final double changePercent;

  ForexPair({
    required this.symbol,
    required this.price,
    required this.change,
    required this.changePercent,
  });

  factory ForexPair.fromJson(Map<String, dynamic> json) {
    print('🔍 Parsing Forex Pair:');
    print('📊 JSON recebido: $json');

    final symbol = json['s'] ?? json['symbol'] ?? '';
    final price = double.tryParse(json['c']?.toString() ?? json['price']?.toString() ?? '0') ?? 0.0;
    final change = double.tryParse(json['ch']?.toString() ?? json['change']?.toString() ?? '0') ?? 0.0;

    // CORRIGIR - remover % e + antes de parsear
    final changePercentString = json['cp']?.toString() ?? json['changePercent']?.toString() ?? '0';
    final changePercent = double.tryParse(changePercentString.replaceAll('%', '').replaceAll('+', '')) ?? 0.0;

    print('✅ Symbol: $symbol');
    print('💰 Price: $price');
    print('📈 Change: $change');
    print('📊 Change % (raw): $changePercentString');
    print('📊 Change % (parsed): $changePercent');

    return ForexPair(
      symbol: symbol,
      price: price,
      change: change,
      changePercent: changePercent,
    );
  }
}

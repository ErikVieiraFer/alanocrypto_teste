import 'dart:convert';
import 'package:http/http.dart' as http;

class ForexApiService {
  static const String _cloudFunctionUrl =
    'https://getforex-yoas3thzsq-uc.a.run.app';

  Future<List<ForexPair>> getForexPairs() async {
    try {
      print('💱 Buscando dados Forex via Cloud Function...');
      print('🔗 URL: $_cloudFunctionUrl');

      final response = await http.get(
        Uri.parse(_cloudFunctionUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      print('📡 Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == true && data['response'] != null) {
          final List<dynamic> pairs = data['response'];

          print('✅ ${pairs.length} pares Forex encontrados');

          return pairs.map((pair) => ForexPair.fromJson(pair)).toList();
        } else {
          print('⚠️ Resposta inválida da API');
          return [];
        }
      } else {
        print('❌ Erro HTTP: ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao buscar Forex: $e');
      print('📍 Stack: $stackTrace');
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

    final changePercentString = json['cp']?.toString() ?? '0';
    final changePercent = double.tryParse(
      changePercentString.replaceAll('%', '').replaceAll('+', '')
    ) ?? 0.0;

    print('✅ Symbol: $symbol');
    print('💰 Price: $price');
    print('📈 Change: $change');
    print('📊 Change %: $changePercent');

    return ForexPair(
      symbol: symbol,
      price: price,
      change: change,
      changePercent: changePercent,
    );
  }
}

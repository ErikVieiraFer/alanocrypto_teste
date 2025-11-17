import 'dart:convert';
import 'package:http/http.dart' as http;

class StocksApiService {
  static const String _cloudFunctionUrl =
    'https://gettopstocks-yoas3thzsq-uc.a.run.app';

  Future<List<Stock>> getTopStocks() async {
    try {
      print('📈 Buscando top ações via Cloud Function...');
      print('🔗 URL: $_cloudFunctionUrl');

      final response = await http.get(
        Uri.parse(_cloudFunctionUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      print('📡 Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['stocks'] != null) {
          final List<dynamic> stocks = data['stocks'];

          print('✅ ${stocks.length} ações encontradas');

          return stocks.map((stock) {
            final quote = stock['data'];
            return Stock(
              symbol: stock['symbol'],
              price: double.tryParse(quote['05. price']?.toString() ?? '0') ?? 0.0,
              change: double.tryParse(quote['09. change']?.toString() ?? '0') ?? 0.0,
              changePercent: _parseChangePercent(quote['10. change percent']),
              volume: int.tryParse(quote['06. volume']?.toString() ?? '0') ?? 0,
            );
          }).toList();
        } else {
          print('⚠️ Resposta sem campo "stocks"');
          return [];
        }
      } else {
        print('❌ Erro HTTP: ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao buscar ações: $e');
      print('📍 Stack: $stackTrace');
      return [];
    }
  }

  double _parseChangePercent(String? value) {
    if (value == null) return 0.0;
    final cleaned = value.replaceAll('%', '').replaceAll('+', '');
    return double.tryParse(cleaned) ?? 0.0;
  }
}

class Stock {
  final String symbol;
  final double price;
  final double change;
  final double changePercent;
  final int volume;

  Stock({
    required this.symbol,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.volume,
  });
}

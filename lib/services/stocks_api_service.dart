import 'dart:convert';
import 'package:http/http.dart' as http;

class StocksApiService {
  static const String _baseUrl = 'https://www.alphavantage.co/query';
  final String apiKey;

  StocksApiService({required this.apiKey});

  Future<List<Stock>> getTopStocks() async {
    // Lista de ações populares para buscar
    final symbols = ['AAPL', 'GOOGL', 'MSFT', 'AMZN', 'TSLA', 'META', 'NVDA', 'JPM'];
    List<Stock> stocks = [];

    try {
      // Buscar cotações em lote
      for (String symbol in symbols.take(5)) { // Limitar a 5 para não estourar API
        final response = await http.get(
          Uri.parse('$_baseUrl?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$apiKey'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data.containsKey('Global Quote')) {
            final quote = data['Global Quote'];

            if (quote.isNotEmpty) {
              stocks.add(Stock.fromJson(quote));
            }
          }
        }

        // Pequeno delay para não sobrecarregar API
        await Future.delayed(const Duration(milliseconds: 500));
      }

      return stocks;
    } catch (e) {
      print('Error fetching stocks data: $e');
      return [];
    }
  }
}

class Stock {
  final String symbol;
  final double price;
  final double change;
  final double changePercent;
  final String volume;

  Stock({
    required this.symbol,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.volume,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      symbol: json['01. symbol'] ?? '',
      price: double.tryParse(json['05. price'] ?? '0') ?? 0.0,
      change: double.tryParse(json['09. change'] ?? '0') ?? 0.0,
      changePercent: double.tryParse(
        (json['10. change percent'] ?? '0%').replaceAll('%', '')
      ) ?? 0.0,
      volume: json['06. volume'] ?? '0',
    );
  }
}

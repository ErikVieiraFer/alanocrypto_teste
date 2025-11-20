import 'dart:convert';
import 'package:http/http.dart' as http;

class AssetSearchService {
  static final AssetSearchService _instance = AssetSearchService._internal();
  factory AssetSearchService() => _instance;
  AssetSearchService._internal();

  // Cache para evitar muitas requisições
  List<SearchableAsset>? _cryptoCache;
  List<SearchableAsset>? _stocksCache;
  List<SearchableAsset>? _forexCache;
  DateTime? _lastCryptoFetch;
  DateTime? _lastStocksFetch;
  DateTime? _lastForexFetch;

  // Lista de ações populares (já que a API retorna poucas)
  static const List<Map<String, String>> _popularStocks = [
    {'symbol': 'AAPL', 'name': 'Apple Inc.'},
    {'symbol': 'MSFT', 'name': 'Microsoft Corporation'},
    {'symbol': 'GOOGL', 'name': 'Alphabet Inc.'},
    {'symbol': 'AMZN', 'name': 'Amazon.com Inc.'},
    {'symbol': 'NVDA', 'name': 'NVIDIA Corporation'},
    {'symbol': 'META', 'name': 'Meta Platforms Inc.'},
    {'symbol': 'TSLA', 'name': 'Tesla Inc.'},
    {'symbol': 'BRK.B', 'name': 'Berkshire Hathaway'},
    {'symbol': 'JPM', 'name': 'JPMorgan Chase & Co.'},
    {'symbol': 'V', 'name': 'Visa Inc.'},
    {'symbol': 'JNJ', 'name': 'Johnson & Johnson'},
    {'symbol': 'WMT', 'name': 'Walmart Inc.'},
    {'symbol': 'PG', 'name': 'Procter & Gamble'},
    {'symbol': 'MA', 'name': 'Mastercard Inc.'},
    {'symbol': 'UNH', 'name': 'UnitedHealth Group'},
    {'symbol': 'HD', 'name': 'Home Depot Inc.'},
    {'symbol': 'DIS', 'name': 'Walt Disney Co.'},
    {'symbol': 'BAC', 'name': 'Bank of America'},
    {'symbol': 'XOM', 'name': 'Exxon Mobil'},
    {'symbol': 'PFE', 'name': 'Pfizer Inc.'},
    {'symbol': 'NFLX', 'name': 'Netflix Inc.'},
    {'symbol': 'INTC', 'name': 'Intel Corporation'},
    {'symbol': 'AMD', 'name': 'Advanced Micro Devices'},
    {'symbol': 'CRM', 'name': 'Salesforce Inc.'},
    {'symbol': 'ORCL', 'name': 'Oracle Corporation'},
    {'symbol': 'PETR4', 'name': 'Petrobras PN'},
    {'symbol': 'VALE3', 'name': 'Vale ON'},
    {'symbol': 'ITUB4', 'name': 'Itaú Unibanco PN'},
    {'symbol': 'BBDC4', 'name': 'Bradesco PN'},
    {'symbol': 'ABEV3', 'name': 'Ambev ON'},
  ];

  // Lista de pares forex populares
  static const List<Map<String, String>> _popularForex = [
    {'symbol': 'EUR/USD', 'name': 'Euro / US Dollar'},
    {'symbol': 'GBP/USD', 'name': 'British Pound / US Dollar'},
    {'symbol': 'USD/JPY', 'name': 'US Dollar / Japanese Yen'},
    {'symbol': 'USD/CHF', 'name': 'US Dollar / Swiss Franc'},
    {'symbol': 'AUD/USD', 'name': 'Australian Dollar / US Dollar'},
    {'symbol': 'USD/CAD', 'name': 'US Dollar / Canadian Dollar'},
    {'symbol': 'NZD/USD', 'name': 'New Zealand Dollar / US Dollar'},
    {'symbol': 'EUR/GBP', 'name': 'Euro / British Pound'},
    {'symbol': 'EUR/JPY', 'name': 'Euro / Japanese Yen'},
    {'symbol': 'GBP/JPY', 'name': 'British Pound / Japanese Yen'},
    {'symbol': 'USD/BRL', 'name': 'US Dollar / Brazilian Real'},
    {'symbol': 'EUR/BRL', 'name': 'Euro / Brazilian Real'},
    {'symbol': 'USD/MXN', 'name': 'US Dollar / Mexican Peso'},
    {'symbol': 'XAU/USD', 'name': 'Gold / US Dollar'},
    {'symbol': 'XAG/USD', 'name': 'Silver / US Dollar'},
  ];

  Future<List<SearchableAsset>> searchAssets(String query, String assetType) async {
    if (query.isEmpty) {
      return _getPopularAssets(assetType);
    }

    switch (assetType) {
      case 'Criptomoedas':
        return _searchCryptos(query);
      case 'Ações':
        return _searchStocks(query);
      case 'Forex':
        return _searchForex(query);
      default:
        return [];
    }
  }

  List<SearchableAsset> _getPopularAssets(String assetType) {
    switch (assetType) {
      case 'Criptomoedas':
        return _cryptoCache?.take(10).toList() ?? [];
      case 'Ações':
        return _popularStocks.take(10).map((s) => SearchableAsset(
          symbol: s['symbol']!,
          name: s['name']!,
          type: 'Ações',
        )).toList();
      case 'Forex':
        return _popularForex.take(10).map((f) => SearchableAsset(
          symbol: f['symbol']!,
          name: f['name']!,
          type: 'Forex',
        )).toList();
      default:
        return [];
    }
  }

  Future<List<SearchableAsset>> _searchCryptos(String query) async {
    // Verificar cache
    final now = DateTime.now();
    if (_cryptoCache != null &&
        _lastCryptoFetch != null &&
        now.difference(_lastCryptoFetch!).inMinutes < 5) {
      return _filterAssets(_cryptoCache!, query);
    }

    try {
      final url = Uri.parse(
        'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=250&sparkline=false',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _cryptoCache = data.map((item) => SearchableAsset(
          symbol: (item['symbol'] as String).toUpperCase(),
          name: item['name'] as String,
          type: 'Criptomoedas',
          imageUrl: item['image'] as String?,
          currentPrice: (item['current_price'] ?? 0).toDouble(),
        )).toList();
        _lastCryptoFetch = now;
        return _filterAssets(_cryptoCache!, query);
      }
    } catch (e) {
      print('Erro ao buscar criptos: $e');
    }

    return [];
  }

  Future<List<SearchableAsset>> _searchStocks(String query) async {
    // Usar lista estática para ações
    if (_stocksCache == null) {
      _stocksCache = _popularStocks.map((s) => SearchableAsset(
        symbol: s['symbol']!,
        name: s['name']!,
        type: 'Ações',
      )).toList();
    }

    return _filterAssets(_stocksCache!, query);
  }

  Future<List<SearchableAsset>> _searchForex(String query) async {
    // Usar lista estática para forex
    if (_forexCache == null) {
      _forexCache = _popularForex.map((f) => SearchableAsset(
        symbol: f['symbol']!,
        name: f['name']!,
        type: 'Forex',
      )).toList();
    }

    return _filterAssets(_forexCache!, query);
  }

  List<SearchableAsset> _filterAssets(List<SearchableAsset> assets, String query) {
    final lowerQuery = query.toLowerCase();
    return assets.where((asset) =>
      asset.symbol.toLowerCase().contains(lowerQuery) ||
      asset.name.toLowerCase().contains(lowerQuery)
    ).take(15).toList();
  }
}

class SearchableAsset {
  final String symbol;
  final String name;
  final String type;
  final String? imageUrl;
  final double? currentPrice;

  SearchableAsset({
    required this.symbol,
    required this.name,
    required this.type,
    this.imageUrl,
    this.currentPrice,
  });
}

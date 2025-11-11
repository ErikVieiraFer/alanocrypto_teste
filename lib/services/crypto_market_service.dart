import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/crypto_data_model.dart';

class CryptoMarketService {
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';
  static final CryptoMarketService _instance = CryptoMarketService._internal();
  factory CryptoMarketService() => _instance;
  CryptoMarketService._internal();

  final List<String> _defaultCryptos = [
    'bitcoin',
    'ethereum',
    'ripple',
    'binancecoin',
    'solana',
    'tron',
    'dogecoin',
    'cardano',
    'hyperliquid',
    'chainlink',
  ];

  final StreamController<List<CryptoDataModel>> _cryptoController =
      StreamController<List<CryptoDataModel>>.broadcast();
  Timer? _updateTimer;

  Stream<List<CryptoDataModel>> get cryptoStream => _cryptoController.stream;

  Future<List<CryptoDataModel>> fetchCryptoData({
    List<String>? cryptoIds,
    bool includeSparkline = true,
  }) async {
    try {
      final ids = cryptoIds ?? _defaultCryptos;
      final idsString = ids.join(',');

      final url = Uri.parse(
        '$_baseUrl/coins/markets?vs_currency=usd&ids=$idsString&order=market_cap_desc&sparkline=$includeSparkline&price_change_percentage=24h',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final cryptoList = data.map((item) => CryptoDataModel.fromJson(item)).toList();
        _cryptoController.add(cryptoList);
        return cryptoList;
      } else {
        throw Exception('Failed to load crypto data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching crypto data: $e');
    }
  }

  Future<CryptoDataModel> fetchSingleCrypto(String cryptoId) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/coins/markets?vs_currency=usd&ids=$cryptoId&order=market_cap_desc&sparkline=true&price_change_percentage=24h',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return CryptoDataModel.fromJson(data[0]);
        } else {
          throw Exception('Crypto not found');
        }
      } else {
        throw Exception('Failed to load crypto data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching crypto data: $e');
    }
  }

  Future<List<CryptoDataModel>> searchCryptos(String query) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&sparkline=false',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final cryptoList = data
            .map((item) => CryptoDataModel.fromJson(item))
            .where((crypto) =>
                crypto.name.toLowerCase().contains(query.toLowerCase()) ||
                crypto.symbol.toLowerCase().contains(query.toLowerCase()))
            .toList();
        return cryptoList;
      } else {
        throw Exception('Failed to search cryptos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching cryptos: $e');
    }
  }

  void startAutoUpdate({Duration interval = const Duration(seconds: 30)}) {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(interval, (_) {
      fetchCryptoData();
    });
    fetchCryptoData();
  }

  void stopAutoUpdate() {
    _updateTimer?.cancel();
  }

  void dispose() {
    _updateTimer?.cancel();
    _cryptoController.close();
  }
}

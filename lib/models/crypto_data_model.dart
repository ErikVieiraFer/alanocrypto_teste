class CryptoDataModel {
  final String id;
  final String symbol;
  final String name;
  final double currentPrice;
  final double priceChange24h;
  final double priceChangePercentage24h;
  final double marketCap;
  final double totalVolume;
  final List<double> sparklineData;

  CryptoDataModel({
    required this.id,
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.priceChange24h,
    required this.priceChangePercentage24h,
    required this.marketCap,
    required this.totalVolume,
    this.sparklineData = const [],
  });

  factory CryptoDataModel.fromJson(Map<String, dynamic> json) {
    return CryptoDataModel(
      id: json['id'] ?? '',
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      currentPrice: (json['current_price'] ?? 0).toDouble(),
      priceChange24h: (json['price_change_24h'] ?? 0).toDouble(),
      priceChangePercentage24h: (json['price_change_percentage_24h'] ?? 0).toDouble(),
      marketCap: (json['market_cap'] ?? 0).toDouble(),
      totalVolume: (json['total_volume'] ?? 0).toDouble(),
      sparklineData: json['sparkline_in_7d'] != null
          ? List<double>.from(
              (json['sparkline_in_7d']['price'] as List).map((e) => e.toDouble()))
          : [],
    );
  }

  bool get isPriceUp => priceChangePercentage24h >= 0;

  String get formattedPrice {
    if (currentPrice >= 1000) {
      return '\$${(currentPrice / 1000).toStringAsFixed(1)}K';
    } else if (currentPrice >= 1) {
      return '\$${currentPrice.toStringAsFixed(2)}';
    } else {
      return '\$${currentPrice.toStringAsFixed(4)}';
    }
  }

  String get formattedPercentage {
    return '${priceChangePercentage24h >= 0 ? '+' : ''}${priceChangePercentage24h.toStringAsFixed(2)}%';
  }
}

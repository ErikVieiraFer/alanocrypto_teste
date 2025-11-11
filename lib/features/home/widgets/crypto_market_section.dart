import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/crypto_data_model.dart';
import '../../../services/crypto_market_service.dart';

class CryptoMarketSection extends StatefulWidget {
  const CryptoMarketSection({super.key});

  @override
  State<CryptoMarketSection> createState() => _CryptoMarketSectionState();
}

class _CryptoMarketSectionState extends State<CryptoMarketSection> {
  final CryptoMarketService _cryptoService = CryptoMarketService();
  List<CryptoDataModel> _cryptos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCryptos();
    _cryptoService.startAutoUpdate();
    _cryptoService.cryptoStream.listen((cryptos) {
      if (mounted) {
        setState(() {
          _cryptos = cryptos;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _loadCryptos() async {
    try {
      final cryptos = await _cryptoService.fetchCryptoData();
      if (mounted) {
        setState(() {
          _cryptos = cryptos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _cryptoService.stopAutoUpdate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.trending_up, color: Color.fromRGBO(76, 175, 80, 1), size: 24),
              SizedBox(width: 8),
              Text(
                'Mercado',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 190,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color.fromRGBO(76, 175, 80, 1),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _cryptos.length,
                  itemBuilder: (context, index) {
                    return _CryptoCard(crypto: _cryptos[index]);
                  },
                ),
        ),
      ],
    );
  }
}

class _CryptoCard extends StatelessWidget {
  final CryptoDataModel crypto;

  const _CryptoCard({required this.crypto});

  @override
  Widget build(BuildContext context) {
    final isPositive = crypto.isPriceUp;
    final changeColor = isPositive
        ? const Color.fromRGBO(76, 175, 80, 1)
        : const Color.fromRGBO(244, 67, 54, 1);

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(18, 18, 18, 1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromRGBO(50, 50, 50, 1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(50, 50, 50, 1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    crypto.symbol.toUpperCase().substring(0, 1),
                    style: const TextStyle(
                      color: Color.fromRGBO(76, 175, 80, 1),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive
                      ? const Color.fromRGBO(76, 175, 80, 0.2)
                      : const Color.fromRGBO(244, 67, 54, 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  crypto.formattedPercentage,
                  style: TextStyle(
                    color: changeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            crypto.symbol.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            crypto.name,
            style: const TextStyle(
              color: Color.fromRGBO(158, 158, 158, 1),
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            crypto.formattedPrice,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (crypto.sparklineData.isNotEmpty)
            SizedBox(
              height: 40,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: crypto.sparklineData
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: changeColor,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: isPositive
                            ? const Color.fromRGBO(76, 175, 80, 0.1)
                            : const Color.fromRGBO(244, 67, 54, 0.1),
                      ),
                    ),
                  ],
                  lineTouchData: const LineTouchData(enabled: false),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

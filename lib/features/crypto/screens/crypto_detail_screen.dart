import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/crypto_data_model.dart';
import '../../../services/crypto_market_service.dart';
import '../../../services/watchlist_service.dart';

class CryptoDetailScreen extends StatefulWidget {
  final String cryptoId;

  const CryptoDetailScreen({super.key, required this.cryptoId});

  @override
  State<CryptoDetailScreen> createState() => _CryptoDetailScreenState();
}

class _CryptoDetailScreenState extends State<CryptoDetailScreen> {
  final CryptoMarketService _cryptoService = CryptoMarketService();
  final WatchlistService _watchlistService = WatchlistService();

  CryptoDataModel? _crypto;
  bool _isLoading = true;
  bool _isInWatchlist = false;
  String _selectedTimeframe = '7D';

  @override
  void initState() {
    super.initState();
    _loadCryptoData();
    _checkWatchlist();
  }

  Future<void> _loadCryptoData() async {
    try {
      final crypto = await _cryptoService.fetchSingleCrypto(widget.cryptoId);
      if (mounted) {
        setState(() {
          _crypto = crypto;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkWatchlist() async {
    final isIn = await _watchlistService.isInWatchlist(widget.cryptoId);
    if (mounted) {
      setState(() => _isInWatchlist = isIn);
    }
  }

  Future<void> _toggleWatchlist() async {
    try {
      await _watchlistService.toggleWatchlist(widget.cryptoId);
      setState(() => _isInWatchlist = !_isInWatchlist);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isInWatchlist
                  ? 'Adicionado à watchlist'
                  : 'Removido da watchlist',
            ),
            backgroundColor: const Color.fromRGBO(76, 175, 80, 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao atualizar watchlist'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatMarketCap(double value) {
    if (value >= 1000000000000) {
      return '\$${(value / 1000000000000).toStringAsFixed(2)}T';
    } else if (value >= 1000000000) {
      return '\$${(value / 1000000000).toStringAsFixed(2)}B';
    } else if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(2)}M';
    } else {
      return '\$${value.toStringAsFixed(0)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _crypto == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: const Color.fromRGBO(18, 18, 18, 1),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color.fromRGBO(76, 175, 80, 1),
          ),
        ),
      );
    }

    final isPositive = _crypto!.isPriceUp;
    final changeColor = isPositive
        ? const Color.fromRGBO(76, 175, 80, 1)
        : const Color.fromRGBO(244, 67, 54, 1);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(18, 18, 18, 1),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
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
                  _crypto!.symbol.toUpperCase().substring(0, 1),
                  style: const TextStyle(
                    color: Color.fromRGBO(76, 175, 80, 1),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _crypto!.symbol.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isInWatchlist ? Icons.star : Icons.star_border,
              color: _isInWatchlist
                  ? const Color.fromRGBO(255, 193, 7, 1)
                  : Colors.white,
            ),
            onPressed: _toggleWatchlist,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    _crypto!.name,
                    style: const TextStyle(
                      color: Color.fromRGBO(158, 158, 158, 1),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _crypto!.formattedPrice,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? const Color.fromRGBO(76, 175, 80, 0.2)
                          : const Color.fromRGBO(244, 67, 54, 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _crypto!.formattedPercentage,
                      style: TextStyle(
                        color: changeColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (_crypto!.sparklineData.isNotEmpty)
              Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(18, 18, 18, 1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color.fromRGBO(50, 50, 50, 1),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ['1D', '1W', '1M', '1Y'].map((timeframe) {
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedTimeframe = timeframe);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedTimeframe == timeframe
                                  ? const Color.fromRGBO(76, 175, 80, 1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              timeframe,
                              style: TextStyle(
                                color: _selectedTimeframe == timeframe
                                    ? Colors.white
                                    : const Color.fromRGBO(158, 158, 158, 1),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) {
                              return const FlLine(
                                color: Color.fromRGBO(50, 50, 50, 1),
                                strokeWidth: 1,
                              );
                            },
                          ),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _crypto!.sparklineData
                                  .asMap()
                                  .entries
                                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                                  .toList(),
                              isCurved: true,
                              color: changeColor,
                              barWidth: 3,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: isPositive
                                    ? const Color.fromRGBO(76, 175, 80, 0.1)
                                    : const Color.fromRGBO(244, 67, 54, 0.1),
                              ),
                            ),
                          ],
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              tooltipBgColor: const Color.fromRGBO(50, 50, 50, 1),
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  return LineTooltipItem(
                                    '\$${spot.y.toStringAsFixed(2)}',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'Estatísticas',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(18, 18, 18, 1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color.fromRGBO(50, 50, 50, 1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  _StatRow(
                    label: 'Market Cap',
                    value: _formatMarketCap(_crypto!.marketCap),
                  ),
                  const Divider(
                    color: Color.fromRGBO(50, 50, 50, 1),
                    height: 24,
                  ),
                  _StatRow(
                    label: 'Volume 24h',
                    value: _formatMarketCap(_crypto!.totalVolume),
                  ),
                  const Divider(
                    color: Color.fromRGBO(50, 50, 50, 1),
                    height: 24,
                  ),
                  _StatRow(
                    label: 'Variação 24h',
                    value: _crypto!.formattedPercentage,
                    valueColor: changeColor,
                  ),
                  const Divider(
                    color: Color.fromRGBO(50, 50, 50, 1),
                    height: 24,
                  ),
                  _StatRow(
                    label: 'Símbolo',
                    value: _crypto!.symbol.toUpperCase(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color.fromRGBO(158, 158, 158, 1),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

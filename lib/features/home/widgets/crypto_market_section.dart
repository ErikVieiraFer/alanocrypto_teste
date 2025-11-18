import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/crypto_data_model.dart';
import '../../../services/crypto_market_service.dart';
import '../../../theme/app_theme.dart';
import '../../dashboard/screen/dashboard_screen.dart';

class CryptoMarketSection extends StatefulWidget {
  const CryptoMarketSection({super.key});

  @override
  State<CryptoMarketSection> createState() => _CryptoMarketSectionState();
}

class _CryptoMarketSectionState extends State<CryptoMarketSection> {
  final CryptoMarketService _cryptoService = CryptoMarketService();
  List<CryptoDataModel> _cryptos = [];
  bool _isLoading = true;
  StreamSubscription<List<CryptoDataModel>>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    _loadCryptos();
    _cryptoService.startAutoUpdate();
    _streamSubscription = _cryptoService.cryptoStream.listen((cryptos) {
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
    _streamSubscription?.cancel();
    _cryptoService.stopAutoUpdate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.mobileHorizontalPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Icon(Icons.trending_up, color: AppTheme.primaryGreen, size: 24),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Mercado Cripto',
                        style: AppTheme.heading2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navega para a tela de mercado através do DashboardScreen
                  final dashboardState = context.findAncestorStateOfType<DashboardScreenState>();
                  if (dashboardState != null) {
                    dashboardState.changeTab(5); // Index 5 = MarketScreen
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver todos',
                      style: TextStyle(color: AppTheme.primaryGreen, fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppTheme.primaryGreen,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.gapMedium),
        SizedBox(
          height: 200,
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryGreen,
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(
                    left: AppTheme.mobileHorizontalPadding,
                    right: AppTheme.mobileHorizontalPadding,
                  ),
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
        ? AppTheme.primaryGreen
        : AppTheme.errorRed;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: AppTheme.mobileCardSpacing),
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      decoration: AppTheme.cardDecoration(
        hasGlow: isPositive,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.cardMedium,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    crypto.symbol.toUpperCase().substring(0, 1),
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
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
                      ? AppTheme.greenTransparent20
                      : AppTheme.redTransparent20,
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
          const SizedBox(height: 6),
          Text(
            crypto.symbol.toUpperCase(),
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            crypto.name,
            style: AppTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            crypto.formattedPrice,
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          if (crypto.sparklineData.isNotEmpty)
            Flexible(
              child: SizedBox(
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
                            ? AppTheme.greenTransparent10
                            : AppTheme.redTransparent10,
                      ),
                    ),
                  ],
                  lineTouchData: const LineTouchData(enabled: false),
                ),
              ),
            ),
            ),
        ],
      ),
    );
  }
}

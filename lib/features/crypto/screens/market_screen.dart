import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/crypto_data_model.dart';
import '../../../services/crypto_market_service.dart';
import '../../../theme/app_theme.dart';
import 'crypto_detail_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final CryptoMarketService _cryptoService = CryptoMarketService();
  final TextEditingController _searchController = TextEditingController();

  List<CryptoDataModel> _allCryptos = [];
  List<CryptoDataModel> _filteredCryptos = [];
  bool _isLoading = true;
  String _selectedFilter = 'Top 100';
  String _selectedSort = 'Market Cap';

  @override
  void initState() {
    super.initState();
    _loadCryptos();
    _searchController.addListener(_filterCryptos);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCryptos() async {
    setState(() => _isLoading = true);
    try {
      final cryptos = await _cryptoService.searchCryptos('');
      if (mounted) {
        setState(() {
          _allCryptos = cryptos;
          _filteredCryptos = cryptos;
          _isLoading = false;
        });
        _applySorting();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterCryptos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCryptos = _allCryptos
          .where((crypto) =>
              crypto.name.toLowerCase().contains(query) ||
              crypto.symbol.toLowerCase().contains(query))
          .toList();
    });
    _applySorting();
  }

  void _applySorting() {
    setState(() {
      switch (_selectedSort) {
        case 'Price':
          _filteredCryptos.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
          break;
        case '24h%':
          _filteredCryptos.sort((a, b) =>
              b.priceChangePercentage24h.compareTo(a.priceChangePercentage24h));
          break;
        case 'Market Cap':
          _filteredCryptos.sort((a, b) => b.marketCap.compareTo(a.marketCap));
          break;
        case 'Volume':
          _filteredCryptos.sort((a, b) => b.totalVolume.compareTo(a.totalVolume));
          break;
      }
    });
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros',
              style: AppTheme.heading3,
            ),
            const SizedBox(height: AppTheme.gapLarge),
            Wrap(
              spacing: AppTheme.gapSmall,
              runSpacing: AppTheme.gapSmall,
              children: ['Top 100', 'DeFi', 'NFT', 'Metaverse'].map((filter) {
                return ChoiceChip(
                  label: Text(filter),
                  selected: _selectedFilter == filter,
                  onSelected: (selected) {
                    setState(() => _selectedFilter = filter);
                    Navigator.pop(context);
                  },
                  selectedColor: AppTheme.primaryGreen,
                  backgroundColor: AppTheme.borderDark,
                  labelStyle: TextStyle(
                    color: _selectedFilter == filter
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppTheme.gapXLarge),
            Text(
              'Ordenar por',
              style: AppTheme.heading3,
            ),
            const SizedBox(height: AppTheme.gapLarge),
            Wrap(
              spacing: AppTheme.gapSmall,
              runSpacing: AppTheme.gapSmall,
              children: ['Price', '24h%', 'Market Cap', 'Volume'].map((sort) {
                return ChoiceChip(
                  label: Text(sort),
                  selected: _selectedSort == sort,
                  onSelected: (selected) {
                    setState(() => _selectedSort = sort);
                    _applySorting();
                    Navigator.pop(context);
                  },
                  selectedColor: AppTheme.primaryGreen,
                  backgroundColor: AppTheme.borderDark,
                  labelStyle: TextStyle(
                    color: _selectedSort == sort
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: AppTheme.backgroundBlack,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppTheme.paddingMedium),
                child: TextField(
                  controller: _searchController,
                  style: AppTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Buscar criptomoeda...',
                    hintStyle: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppTheme.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppTheme.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: AppTheme.defaultRadius,
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingMedium),
                child: Row(
                  children: [
                    Text(
                      _selectedFilter,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppTheme.gapSmall),
                    Text(
                      '•',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppTheme.gapSmall),
                    Text(
                      'Ordenado por $_selectedSort',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.gapSmall),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryGreen,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadCryptos,
                        color: AppTheme.primaryGreen,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppTheme.paddingMedium),
                          itemCount: _filteredCryptos.length,
                          itemBuilder: (context, index) {
                            return _MarketCryptoCard(
                              crypto: _filteredCryptos[index],
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _showFilterModal,
            backgroundColor: AppTheme.primaryGreen,
            child: const Icon(Icons.filter_list, color: AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _MarketCryptoCard extends StatelessWidget {
  final CryptoDataModel crypto;

  const _MarketCryptoCard({required this.crypto});

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
    final isPositive = crypto.isPriceUp;
    final changeColor = isPositive
        ? AppTheme.primaryGreen
        : AppTheme.errorRed;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CryptoDetailScreen(cryptoId: crypto.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.gapMedium),
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: AppTheme.defaultRadius,
          border: Border.all(
            color: AppTheme.borderDark,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.cardMedium,
                borderRadius: AppTheme.smallRadius,
              ),
              child: Center(
                child: Text(
                  crypto.symbol.toUpperCase().substring(0, 1),
                  style: AppTheme.heading3.copyWith(
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.gapMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        crypto.symbol.toUpperCase(),
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppTheme.gapSmall),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isPositive
                              ? AppTheme.greenTransparent20
                              : AppTheme.redTransparent20,
                          borderRadius: AppTheme.tinyRadius,
                        ),
                        child: Text(
                          crypto.formattedPercentage,
                          style: AppTheme.bodySmall.copyWith(
                            color: changeColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    crypto.name,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Market Cap: ${_formatMarketCap(crypto.marketCap)}',
                    style: AppTheme.bodySmall.copyWith(
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  crypto.formattedPrice,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (crypto.sparklineData.isNotEmpty)
                  SizedBox(
                    width: 80,
                    height: 30,
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
                          ),
                        ],
                        lineTouchData: const LineTouchData(enabled: false),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

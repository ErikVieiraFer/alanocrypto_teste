import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/crypto_data_model.dart';
import '../../../services/crypto_market_service.dart';
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
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color.fromRGBO(18, 18, 18, 1),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtros',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Top 100', 'DeFi', 'NFT', 'Metaverse'].map((filter) {
                return ChoiceChip(
                  label: Text(filter),
                  selected: _selectedFilter == filter,
                  onSelected: (selected) {
                    setState(() => _selectedFilter = filter);
                    Navigator.pop(context);
                  },
                  selectedColor: const Color.fromRGBO(76, 175, 80, 1),
                  backgroundColor: const Color.fromRGBO(50, 50, 50, 1),
                  labelStyle: TextStyle(
                    color: _selectedFilter == filter
                        ? Colors.white
                        : const Color.fromRGBO(158, 158, 158, 1),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ordenar por',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Price', '24h%', 'Market Cap', 'Volume'].map((sort) {
                return ChoiceChip(
                  label: Text(sort),
                  selected: _selectedSort == sort,
                  onSelected: (selected) {
                    setState(() => _selectedSort = sort);
                    _applySorting();
                    Navigator.pop(context);
                  },
                  selectedColor: const Color.fromRGBO(76, 175, 80, 1),
                  backgroundColor: const Color.fromRGBO(50, 50, 50, 1),
                  labelStyle: TextStyle(
                    color: _selectedSort == sort
                        ? Colors.white
                        : const Color.fromRGBO(158, 158, 158, 1),
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(18, 18, 18, 1),
        title: const Text(
          'Mercado',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterModal,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar criptomoeda...',
                hintStyle: const TextStyle(
                  color: Color.fromRGBO(158, 158, 158, 1),
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color.fromRGBO(158, 158, 158, 1),
                ),
                filled: true,
                fillColor: const Color.fromRGBO(18, 18, 18, 1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  _selectedFilter,
                  style: const TextStyle(
                    color: Color.fromRGBO(158, 158, 158, 1),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '•',
                  style: TextStyle(
                    color: Color.fromRGBO(158, 158, 158, 1),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Ordenado por $_selectedSort',
                  style: const TextStyle(
                    color: Color.fromRGBO(158, 158, 158, 1),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color.fromRGBO(76, 175, 80, 1),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadCryptos,
                    color: const Color.fromRGBO(76, 175, 80, 1),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
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
        ? const Color.fromRGBO(76, 175, 80, 1)
        : const Color.fromRGBO(244, 67, 54, 1);

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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(18, 18, 18, 1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color.fromRGBO(50, 50, 50, 1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(50, 50, 50, 1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  crypto.symbol.toUpperCase().substring(0, 1),
                  style: const TextStyle(
                    color: Color.fromRGBO(76, 175, 80, 1),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        crypto.symbol.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
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
                  const SizedBox(height: 4),
                  Text(
                    crypto.name,
                    style: const TextStyle(
                      color: Color.fromRGBO(158, 158, 158, 1),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Market Cap: ${_formatMarketCap(crypto.marketCap)}',
                    style: const TextStyle(
                      color: Color.fromRGBO(158, 158, 158, 1),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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

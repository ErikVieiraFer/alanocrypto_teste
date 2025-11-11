import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/crypto_data_model.dart';
import '../../../services/crypto_market_service.dart';
import '../../../services/watchlist_service.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final CryptoMarketService _cryptoService = CryptoMarketService();
  final WatchlistService _watchlistService = WatchlistService();

  List<String> _watchlistIds = [];
  List<CryptoDataModel> _watchlistCryptos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
    _watchlistService.getWatchlistStream().listen((ids) {
      _watchlistIds = ids;
      _loadCryptoData();
    });
  }

  Future<void> _loadWatchlist() async {
    try {
      final ids = await _watchlistService.getWatchlist();
      setState(() {
        _watchlistIds = ids;
      });
      await _loadCryptoData();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCryptoData() async {
    if (_watchlistIds.isEmpty) {
      setState(() {
        _watchlistCryptos = [];
        _isLoading = false;
      });
      return;
    }

    try {
      final cryptos = await _cryptoService.fetchCryptoData(
        cryptoIds: _watchlistIds,
      );
      if (mounted) {
        setState(() {
          _watchlistCryptos = cryptos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddCryptoModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddCryptoModal(
        onCryptoAdded: () {
          _loadWatchlist();
        },
        existingIds: _watchlistIds,
      ),
    );
  }

  Future<void> _removeCrypto(String cryptoId) async {
    try {
      await _watchlistService.removeFromWatchlist(cryptoId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removido da watchlist'),
            backgroundColor: Color.fromRGBO(76, 175, 80, 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao remover da watchlist'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(18, 18, 18, 1),
        title: const Text(
          'Watchlist',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddCryptoModal,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromRGBO(76, 175, 80, 1),
              ),
            )
          : _watchlistCryptos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.star_border,
                        size: 64,
                        color: Color.fromRGBO(158, 158, 158, 1),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sua watchlist está vazia',
                        style: TextStyle(
                          color: Color.fromRGBO(158, 158, 158, 1),
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showAddCryptoModal,
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar Criptomoeda'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(76, 175, 80, 1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadWatchlist,
                  color: const Color.fromRGBO(76, 175, 80, 1),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _watchlistCryptos.length,
                    itemBuilder: (context, index) {
                      return _WatchlistCryptoCard(
                        crypto: _watchlistCryptos[index],
                        onRemove: () => _removeCrypto(_watchlistCryptos[index].id),
                      );
                    },
                  ),
                ),
    );
  }
}

class _WatchlistCryptoCard extends StatelessWidget {
  final CryptoDataModel crypto;
  final VoidCallback onRemove;

  const _WatchlistCryptoCard({
    required this.crypto,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = crypto.isPriceUp;
    final changeColor = isPositive
        ? const Color.fromRGBO(76, 175, 80, 1)
        : const Color.fromRGBO(244, 67, 54, 1);

    return Container(
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
                          fontSize: 12,
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
                    fontSize: 14,
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
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(
              Icons.close,
              color: Color.fromRGBO(244, 67, 54, 1),
            ),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class AddCryptoModal extends StatefulWidget {
  final VoidCallback onCryptoAdded;
  final List<String> existingIds;

  const AddCryptoModal({
    super.key,
    required this.onCryptoAdded,
    required this.existingIds,
  });

  @override
  State<AddCryptoModal> createState() => _AddCryptoModalState();
}

class _AddCryptoModalState extends State<AddCryptoModal> {
  final CryptoMarketService _cryptoService = CryptoMarketService();
  final WatchlistService _watchlistService = WatchlistService();
  final TextEditingController _searchController = TextEditingController();

  List<CryptoDataModel> _allCryptos = [];
  List<CryptoDataModel> _filteredCryptos = [];
  bool _isLoading = true;

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
    try {
      final cryptos = await _cryptoService.searchCryptos('');
      if (mounted) {
        setState(() {
          _allCryptos = cryptos
              .where((c) => !widget.existingIds.contains(c.id))
              .toList();
          _filteredCryptos = _allCryptos;
          _isLoading = false;
        });
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
  }

  Future<void> _addCrypto(String cryptoId) async {
    try {
      await _watchlistService.addToWatchlist(cryptoId);
      widget.onCryptoAdded();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Adicionado à watchlist'),
            backgroundColor: Color.fromRGBO(76, 175, 80, 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao adicionar à watchlist'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(18, 18, 18, 1),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color.fromRGBO(50, 50, 50, 1),
                ),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Adicionar Criptomoeda',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou símbolo...',
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
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color.fromRGBO(76, 175, 80, 1),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredCryptos.length,
                    itemBuilder: (context, index) {
                      final crypto = _filteredCryptos[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(50, 50, 50, 1),
                            borderRadius: BorderRadius.circular(20),
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
                        title: Text(
                          crypto.symbol.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          crypto.name,
                          style: const TextStyle(
                            color: Color.fromRGBO(158, 158, 158, 1),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Color.fromRGBO(76, 175, 80, 1),
                          ),
                          onPressed: () => _addCrypto(crypto.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

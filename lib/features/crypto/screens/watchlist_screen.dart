import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/crypto_data_model.dart';
import '../../../services/crypto_market_service.dart';
import '../../../services/watchlist_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/empty_state.dart';

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
  StreamSubscription<List<String>>? _watchlistSubscription;

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
    _watchlistSubscription = _watchlistService.getWatchlistStream().listen((ids) {
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
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao remover da watchlist'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _watchlistSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundColor,
      child: Stack(
        children: [
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryGreen,
                  ),
                )
              : _watchlistCryptos.isEmpty
                  ? EmptyState(
                      icon: Icons.star_border_rounded,
                      title: 'Sua watchlist está vazia',
                      message: 'Adicione criptomoedas aos favoritos',
                      buttonText: 'Adicionar Criptomoeda',
                      onButtonPressed: _showAddCryptoModal,
                    )
                  : RefreshIndicator(
                      onRefresh: _loadWatchlist,
                      color: AppTheme.primaryGreen,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppTheme.paddingMedium),
                        itemCount: _watchlistCryptos.length,
                        itemBuilder: (context, index) {
                          return _WatchlistCryptoCard(
                            crypto: _watchlistCryptos[index],
                            onRemove: () => _removeCrypto(_watchlistCryptos[index].id),
                          );
                        },
                      ),
                    ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'watchlist_fab',
              onPressed: _showAddCryptoModal,
              backgroundColor: AppTheme.primaryGreen,
              child: const Icon(Icons.add, color: AppTheme.textPrimary),
            ),
          ),
        ],
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
        ? AppTheme.primaryGreen
        : AppTheme.errorRed;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.gapMedium),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: AppTheme.defaultRadius,
          splashColor: AppTheme.primaryGreen.withOpacity(0.1),
          child: Ink(
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
                const SizedBox(width: AppTheme.gapMedium),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppTheme.errorRed,
                  ),
                  onPressed: onRemove,
                ),
              ],
            ),
          ),
        ),
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
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao adicionar à watchlist'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: AppTheme.extraLargeRadius.copyWith(
          bottomLeft: Radius.zero,
          bottomRight: Radius.zero,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.paddingMedium),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.borderDark,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Adicionar Criptomoeda',
                  style: AppTheme.bodyLarge.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.paddingMedium),
            child: TextField(
              controller: _searchController,
              style: AppTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou símbolo...',
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
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryGreen,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingMedium),
                    itemCount: _filteredCryptos.length,
                    itemBuilder: (context, index) {
                      final crypto = _filteredCryptos[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: AppTheme.gapSmall),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.borderDark,
                            borderRadius: AppTheme.extraLargeRadius,
                          ),
                          child: Center(
                            child: Text(
                              crypto.symbol.toUpperCase().substring(0, 1),
                              style: AppTheme.bodyLarge.copyWith(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          crypto.symbol.toUpperCase(),
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          crypto.name,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: AppTheme.primaryGreen,
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

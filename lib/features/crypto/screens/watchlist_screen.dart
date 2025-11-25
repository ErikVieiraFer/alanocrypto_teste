import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_theme.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  List<Map<String, dynamic>> _watchlistItems = [];
  bool _isLoading = true;

  // Dados de mercado
  List<Map<String, dynamic>> _allCryptos = [];
  List<Map<String, dynamic>> _allStocks = [];
  List<Map<String, dynamic>> _allForex = [];

  @override
  void initState() {
    super.initState();
    _loadAllMarketData();
    _loadWatchlist();
  }

  Future<void> _loadAllMarketData() async {
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('market_cache').doc('crypto').get(),
        FirebaseFirestore.instance.collection('market_cache').doc('stocks').get(),
        FirebaseFirestore.instance.collection('market_cache').doc('forex').get(),
      ]);

      setState(() {
        if (results[0].exists && results[0].data()?['data'] != null) {
          _allCryptos = List<Map<String, dynamic>>.from(results[0].data()!['data']);
        }

        if (results[1].exists && results[1].data()?['data'] != null) {
          _allStocks = List<Map<String, dynamic>>.from(results[1].data()!['data']);
        }

        if (results[2].exists && results[2].data()?['data'] != null) {
          _allForex = List<Map<String, dynamic>>.from(results[2].data()!['data']);
        }
      });

      print('📊 Loaded: ${_allCryptos.length} cryptos, ${_allStocks.length} stocks, ${_allForex.length} forex');
    } catch (e) {
      print('❌ Erro ao carregar dados de mercado: $e');
    }
  }

  Future<void> _loadWatchlist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('watchlist')
          .orderBy('addedAt', descending: true)
          .get();

      setState(() {
        _watchlistItems = snapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erro ao carregar watchlist: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFromWatchlist(String assetId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('watchlist')
          .doc(assetId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removido da watchlist'),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      _loadWatchlist();
    } catch (e) {
      print('❌ Erro ao remover: $e');
    }
  }

  void _showAddAssetModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddAssetModal(
        allCryptos: _allCryptos,
        allStocks: _allStocks,
        allForex: _allForex,
        onAssetAdded: _loadWatchlist,
      ),
    );
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
              : _watchlistItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.star_border,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Sua watchlist está vazia',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Adicione crypto, ações ou forex',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _showAddAssetModal,
                            icon: const Icon(Icons.add),
                            label: const Text('Adicionar Ativo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await _loadAllMarketData();
                        await _loadWatchlist();
                      },
                      color: AppTheme.primaryGreen,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _watchlistItems.length,
                        itemBuilder: (context, index) {
                          return _buildWatchlistItem(_watchlistItems[index]);
                        },
                      ),
                    ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'watchlist_fab',
              onPressed: _showAddAssetModal,
              backgroundColor: AppTheme.primaryGreen,
              child: const Icon(Icons.add, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchlistItem(Map<String, dynamic> item) {
    // Detecção inteligente do tipo (para retrocompatibilidade com itens antigos)
    String type = item['type']?.toString() ?? '';

    // Se não tem o campo 'type', detectar pelo ID nos arrays de mercado
    if (type.isEmpty) {
      final itemId = item['id']?.toString() ?? '';
      if (_allForex.any((e) => e['id'] == itemId)) {
        type = 'forex';
      } else if (_allStocks.any((e) => e['id'] == itemId)) {
        type = 'stock';
      } else {
        type = 'crypto';
      }
    }

    final isForex = type == 'forex';
    final isStock = type == 'stock';

    print('🔍 Item: ${item['symbol']}, Type: $type, isStock: $isStock, isForex: $isForex');

    // Buscar dados atualizados do mercado
    Map<String, dynamic>? marketData;
    if (isForex) {
      marketData = _allForex.firstWhere(
        (e) => e['id'] == item['id'],
        orElse: () => item,
      );
    } else if (isStock) {
      marketData = _allStocks.firstWhere(
        (e) => e['id'] == item['id'],
        orElse: () => item,
      );
    } else {
      marketData = _allCryptos.firstWhere(
        (e) => e['id'] == item['id'],
        orElse: () => item,
      );
    }

    final price = marketData['current_price'] ?? 0;
    final priceChange = (marketData['price_change_percentage_24h'] ?? 0).toDouble();
    final isPositive = priceChange >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1f26),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                _buildAssetIcon(marketData, isForex: isForex, isStock: isStock),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        marketData['symbol']?.toString().toUpperCase() ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        marketData['name']?.toString() ?? '',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatPrice(price, isForex),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPositive
                            ? AppTheme.primaryGreen.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${isPositive ? '+' : ''}${priceChange.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: isPositive ? AppTheme.primaryGreen : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.star, color: Colors.amber),
                  onPressed: () => _removeFromWatchlist(item['id']),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssetIcon(Map<String, dynamic> asset, {bool isForex = false, bool isStock = false}) {
    print('📸 _buildAssetIcon: symbol=${asset['symbol']}, isForex=$isForex, isStock=$isStock');

    if (isForex) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF2a3040),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Center(
          child: Text(
            asset['flag']?.toString() ?? '💱',
            style: const TextStyle(fontSize: 24),
          ),
        ),
      );
    }

    if (isStock) {
      final symbol = asset['symbol']?.toString() ?? '?';
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF2a3040),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Center(
          child: Text(
            symbol.length > 2 ? symbol.substring(0, 2) : symbol,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    final imageUrl = asset['image']?.toString() ?? '';
    if (imageUrl.isNotEmpty && !imageUrl.contains('placeholder')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.network(
          imageUrl,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackIcon(asset['symbol'] ?? '?'),
        ),
      );
    }

    return _buildFallbackIcon(asset['symbol'] ?? '?');
  }

  Widget _buildFallbackIcon(String symbol) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF2a3040),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Center(
        child: Text(
          symbol.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatPrice(dynamic price, bool isForex) {
    if (price == null) return '-';

    double value;
    if (price is String) {
      value = double.tryParse(price) ?? 0;
    } else if (price is int) {
      value = price.toDouble();
    } else if (price is double) {
      value = price;
    } else {
      return '-';
    }

    if (isForex) {
      if (value >= 100) {
        return value.toStringAsFixed(2);
      } else {
        return value.toStringAsFixed(4);
      }
    }

    if (value >= 1) {
      return '\$${value.toStringAsFixed(2)}';
    } else {
      return '\$${value.toStringAsFixed(4)}';
    }
  }
}

class _AddAssetModal extends StatefulWidget {
  final List<Map<String, dynamic>> allCryptos;
  final List<Map<String, dynamic>> allStocks;
  final List<Map<String, dynamic>> allForex;
  final VoidCallback onAssetAdded;

  const _AddAssetModal({
    required this.allCryptos,
    required this.allStocks,
    required this.allForex,
    required this.onAssetAdded,
  });

  @override
  State<_AddAssetModal> createState() => _AddAssetModalState();
}

class _AddAssetModalState extends State<_AddAssetModal> {
  int _selectedTab = 0;
  String _searchQuery = '';
  Set<String> _watchlistIds = {};

  @override
  void initState() {
    super.initState();
    _loadWatchlistIds();
  }

  Future<void> _loadWatchlistIds() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('watchlist')
          .get();

      setState(() {
        _watchlistIds = snapshot.docs.map((doc) => doc.id).toSet();
      });
    } catch (e) {
      print('❌ Erro ao carregar watchlist IDs: $e');
    }
  }

  List<Map<String, dynamic>> _getCurrentList() {
    List<Map<String, dynamic>> list;
    switch (_selectedTab) {
      case 0:
        list = widget.allCryptos;
        break;
      case 1:
        list = widget.allStocks;
        break;
      case 2:
        list = widget.allForex;
        break;
      default:
        list = widget.allCryptos;
    }

    if (_searchQuery.isEmpty) return list;

    return list.where((item) {
      final symbol = item['symbol']?.toString().toLowerCase() ?? '';
      final name = item['name']?.toString().toLowerCase() ?? '';
      return symbol.contains(_searchQuery.toLowerCase()) ||
          name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  String _getAssetType() {
    switch (_selectedTab) {
      case 0:
        return 'crypto';
      case 1:
        return 'stock';
      case 2:
        return 'forex';
      default:
        return 'crypto';
    }
  }

  Future<void> _addToWatchlist(Map<String, dynamic> asset) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final assetId = asset['id']?.toString() ?? asset['symbol']?.toString() ?? '';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('watchlist')
          .doc(assetId)
          .set({
        'id': assetId,
        'symbol': asset['symbol'],
        'name': asset['name'],
        'image': asset['image'],
        'flag': asset['flag'],
        'type': _getAssetType(),
        'addedAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${asset['symbol']} adicionado à watchlist!'),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );

      widget.onAssetAdded();
    } catch (e) {
      print('❌ Erro ao adicionar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentList = _getCurrentList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1a1f26),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Adicionar Ativo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF0f1419),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTab('Crypto', 0),
                _buildTab('Ações', 1),
                _buildTab('Forex', 2),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou símbolo...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF0f1419),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: currentList.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum ativo encontrado',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: currentList.length,
                    itemBuilder: (context, index) {
                      final asset = currentList[index];
                      final assetId = asset['id']?.toString() ?? asset['symbol']?.toString() ?? '';
                      final isInWatchlist = _watchlistIds.contains(assetId);

                      return _buildAssetTile(asset, isInWatchlist);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = index == _selectedTab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssetTile(Map<String, dynamic> asset, bool isInWatchlist) {
    final isForex = _selectedTab == 2;
    final isStock = _selectedTab == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: isInWatchlist ? null : () => _addToWatchlist(asset),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: const Color(0xFF0f1419),
        leading: _buildAssetIcon(asset, isForex: isForex, isStock: isStock),
        title: Text(
          asset['symbol']?.toString().toUpperCase() ?? '',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          asset['name']?.toString() ?? '',
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          isInWatchlist ? Icons.check_circle : Icons.add_circle_outline,
          color: isInWatchlist ? Colors.grey : AppTheme.primaryGreen,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildAssetIcon(Map<String, dynamic> asset, {bool isForex = false, bool isStock = false}) {
    if (isForex) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF2a3040),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Center(
          child: Text(
            asset['flag']?.toString() ?? '💱',
            style: const TextStyle(fontSize: 24),
          ),
        ),
      );
    }

    if (isStock) {
      final symbol = asset['symbol']?.toString() ?? '?';
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF2a3040),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Center(
          child: Text(
            symbol.length > 2 ? symbol.substring(0, 2) : symbol,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    final imageUrl = asset['image']?.toString() ?? '';
    if (imageUrl.isNotEmpty && !imageUrl.contains('placeholder')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.network(
          imageUrl,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackIcon(asset['symbol'] ?? '?'),
        ),
      );
    }

    return _buildFallbackIcon(asset['symbol'] ?? '?');
  }

  Widget _buildFallbackIcon(String symbol) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF2a3040),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Center(
        child: Text(
          symbol.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

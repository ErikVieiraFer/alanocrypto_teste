import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MarketsScreen extends StatefulWidget {
  const MarketsScreen({Key? key}) : super(key: key);

  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen> with SingleTickerProviderStateMixin {
  bool _showWatchlistOnly = false;
  List<Map<String, dynamic>> _cryptos = [];
  List<Map<String, dynamic>> _stocks = [];
  List<Map<String, dynamic>> _forex = [];
  Map<String, dynamic>? _globalData;
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _watchlist = {};
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
    _loadWatchlist();
    _fetchAllMarketData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWatchlist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['watchlist'] != null) {
          setState(() {
            _watchlist = Set<String>.from(data['watchlist']);
          });
        }
      }
    } catch (e) {
      print('Erro ao carregar watchlist: $e');
    }
  }

  Future<void> _toggleWatchlist(String coinId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      if (_watchlist.contains(coinId)) {
        _watchlist.remove(coinId);
      } else {
        _watchlist.add(coinId);
      }
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'watchlist': _watchlist.toList(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Erro ao atualizar watchlist: $e');
    }
  }

  Future<void> _fetchAllMarketData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Buscar dados do cache no Firestore
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('market_cache').doc('crypto').get(),
        FirebaseFirestore.instance.collection('market_cache').doc('stocks').get(),
        FirebaseFirestore.instance.collection('market_cache').doc('forex').get(),
      ]);

      final cryptoDoc = results[0];
      final stocksDoc = results[1];
      final forexDoc = results[2];

      // CRYPTO
      print('📊 [CRYPTO] Documento existe: ${cryptoDoc.exists}');
      if (cryptoDoc.exists && cryptoDoc.data() != null) {
        final data = cryptoDoc.data()!;
        print('📊 [CRYPTO] Campos: ${data.keys.toList()}');
        if (data['data'] != null) {
          _cryptos = List<Map<String, dynamic>>.from(data['data']);
          print('📊 [CRYPTO] Quantidade: ${_cryptos.length}');
        }
      }

      // STOCKS
      print('📊 [STOCKS] Documento existe: ${stocksDoc.exists}');
      if (stocksDoc.exists && stocksDoc.data() != null) {
        final data = stocksDoc.data()!;
        print('📊 [STOCKS] Campos: ${data.keys.toList()}');
        if (data['data'] != null) {
          _stocks = List<Map<String, dynamic>>.from(data['data']);
          print('📊 [STOCKS] Quantidade: ${_stocks.length}');
        }
      }

      // FOREX - COM LOGS DETALHADOS
      print('📊 [FOREX] Iniciando carregamento...');
      print('📊 [FOREX] Documento existe: ${forexDoc.exists}');

      if (forexDoc.exists && forexDoc.data() != null) {
        final data = forexDoc.data()!;
        print('📊 [FOREX] Campos no documento: ${data.keys.toList()}');
        print('📊 [FOREX] Source: ${data['source']}');
        print('📊 [FOREX] UpdatedAt: ${data['updatedAt']}');

        if (data['data'] != null) {
          final forexList = data['data'] as List<dynamic>;
          print('📊 [FOREX] Quantidade de pares: ${forexList.length}');

          if (forexList.isNotEmpty) {
            print('📊 [FOREX] Primeiro par: ${forexList.first}');
          }

          _forex = List<Map<String, dynamic>>.from(forexList);
        } else {
          print('❌ [FOREX] Campo data está null');
          _forex = [];
        }
      } else {
        print('❌ [FOREX] Documento não existe ou está vazio');
        _forex = [];
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [ERROR] Erro ao buscar dados do cache: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _currentData {
    List<Map<String, dynamic>> data;

    switch (_currentTabIndex) {
      case 0:
        data = _cryptos;
        break;
      case 1:
        data = _stocks;
        break;
      case 2:
        data = _forex;
        break;
      default:
        data = [];
    }

    if (_showWatchlistOnly) {
      data = data.where((item) => _watchlist.contains(item['id'])).toList();
    }

    if (_searchQuery.isNotEmpty) {
      data = data.where((item) {
        final name = (item['name'] ?? '').toString().toLowerCase();
        final symbol = (item['symbol'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || symbol.contains(query);
      }).toList();
    }

    return data;
  }

  String _formatNumber(dynamic number) {
    if (number == null) return '\$0.00';

    double value;
    if (number is String) {
      value = double.tryParse(number) ?? 0;
    } else if (number is int) {
      value = number.toDouble();
    } else if (number is double) {
      value = number;
    } else {
      return '\$0.00';
    }

    if (value >= 1000000000000) {
      return '\$' + (value / 1000000000000).toStringAsFixed(2) + 'T';
    } else if (value >= 1000000000) {
      return '\$' + (value / 1000000000).toStringAsFixed(2) + 'B';
    } else if (value >= 1000000) {
      return '\$' + (value / 1000000).toStringAsFixed(2) + 'M';
    } else if (value >= 1000) {
      return '\$' + (value / 1000).toStringAsFixed(2) + 'K';
    } else if (value >= 1) {
      return '\$' + value.toStringAsFixed(2);
    } else {
      return '\$' + value.toStringAsFixed(8);
    }
  }

  String _formatForexPrice(dynamic price) {
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

    if (value >= 100) {
      return value.toStringAsFixed(2);
    } else if (value >= 1) {
      return value.toStringAsFixed(4);
    } else {
      return value.toStringAsFixed(4);
    }
  }

  Widget _buildAssetIcon(Map<String, dynamic> asset, bool isForex) {
    if (isForex && asset['flag'] != null) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF1E2329),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            asset['flag'] ?? '💱',
            style: const TextStyle(fontSize: 20),
          ),
        ),
      );
    }

    final imageUrl = asset['image']?.toString() ?? '';

    if (imageUrl.isNotEmpty && !imageUrl.contains('placeholder')) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF2a2f36),
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Image.network(
            imageUrl,
            width: 32,
            height: 32,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackIcon(asset['symbol'] ?? '?');
            },
          ),
        ),
      );
    }

    return _buildFallbackIcon(asset['symbol'] ?? '?');
  }

  Widget _buildFallbackIcon(String symbol) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2329),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          symbol.substring(0, symbol.length > 2 ? 2 : symbol.length),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1116),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchAllMarketData,
          color: const Color(0xFF00FF88),
          backgroundColor: const Color(0xFF1a1f26),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Mercados',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _showWatchlistOnly = !_showWatchlistOnly;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _showWatchlistOnly
                                    ? const Color(0xFF00FF88).withValues(alpha: 0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _showWatchlistOnly
                                      ? const Color(0xFF00FF88)
                                      : Colors.grey,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _showWatchlistOnly
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: _showWatchlistOnly
                                        ? const Color(0xFF00FF88)
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Watchlist',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _showWatchlistOnly
                                          ? const Color(0xFF00FF88)
                                          : Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a1f26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: const Color(0xFF00FF88),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          labelColor: Colors.black,
                          unselectedLabelColor: Colors.grey,
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(text: 'Crypto'),
                            Tab(text: 'Ações'),
                            Tab(text: 'Forex'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Buscar ativo...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF1a1f26),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (!_isLoading && _globalData != null && _currentTabIndex == 0) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                'Market Cap',
                                _formatNumber(_globalData!['total_market_cap']['usd']),
                                (_globalData!['market_cap_change_percentage_24h_usd'] ?? 0).toStringAsFixed(2),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildInfoCard(
                                'Volume 24h',
                                _formatNumber(_globalData!['total_volume']['usd']),
                                null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                'BTC Dominance',
                                '${(_globalData!['market_cap_percentage']['btc'] ?? 0).toStringAsFixed(1)}%',
                                null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildFearGreedCard(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),

              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00FF88),
                    ),
                  ),
                )
              else if (_currentData.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showWatchlistOnly ? Icons.star_border : Icons.search_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _showWatchlistOnly
                                ? 'Sua watchlist está vazia'
                                : 'Nenhum ativo encontrado',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _showWatchlistOnly
                                ? 'Adicione ativos aos favoritos'
                                : 'Tente outra busca',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          if (_showWatchlistOnly) ...[
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _showWatchlistOnly = false;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00FF88),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Adicionar Ativo'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1a1f26),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: const [
                              SizedBox(width: 60),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Nome',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Preço',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  '24h',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Market Cap',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF1a1f26),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _currentData.length,
                            separatorBuilder: (context, index) => const Divider(
                              color: Color(0xFF2a2f36),
                              height: 1,
                            ),
                            itemBuilder: (context, index) {
                              final item = _currentData[index];
                              final isInWatchlist = _watchlist.contains(item['id']);
                              final priceChange = (item['price_change_percentage_24h'] ?? 0).toDouble();
                              final isPositive = priceChange >= 0;
                              final isForex = _currentTabIndex == 2;

                              return InkWell(
                                onTap: () {},
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 60,
                                        child: Row(
                                          children: [
                                            Text(
                                              '${item['market_cap_rank'] ?? index + 1}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            InkWell(
                                              onTap: () => _toggleWatchlist(item['id']),
                                              child: Icon(
                                                isInWatchlist
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: isInWatchlist
                                                    ? const Color(0xFF00FF88)
                                                    : Colors.grey,
                                                size: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          children: [
                                            _buildAssetIcon(item, isForex),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    (item['symbol'] ?? '').toString().toUpperCase(),
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  Text(
                                                    item['name'] ?? '',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          isForex
                                              ? _formatForexPrice(item['current_price'])
                                              : _formatNumber(item['current_price']),
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Icon(
                                              isPositive
                                                  ? Icons.arrow_drop_up
                                                  : Icons.arrow_drop_down,
                                              color: isPositive
                                                  ? const Color(0xFF00FF88)
                                                  : Colors.red,
                                              size: 20,
                                            ),
                                            Text(
                                              '${priceChange.abs().toStringAsFixed(2)}%',
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isPositive
                                                    ? const Color(0xFF00FF88)
                                                    : Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          item['market_cap'] != null && item['market_cap'] > 0
                                              ? _formatNumber(item['market_cap'])
                                              : '-',
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, String? percentage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1f26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (percentage != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  double.parse(percentage) >= 0
                      ? Icons.arrow_drop_up
                      : Icons.arrow_drop_down,
                  size: 20,
                  color: double.parse(percentage) >= 0
                      ? const Color(0xFF00FF88)
                      : Colors.red,
                ),
                Text(
                  '${percentage}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: double.parse(percentage) >= 0
                        ? const Color(0xFF00FF88)
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFearGreedCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1f26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Fear & Greed',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.mood,
                color: Colors.orange,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                '43',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Neutral',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_theme.dart';

class MarketListCard extends StatefulWidget {
  const MarketListCard({super.key});

  @override
  State<MarketListCard> createState() => _MarketListCardState();
}

class _MarketListCardState extends State<MarketListCard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 490,
      decoration: AppTheme.gradientCardDecoration,
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryGreen,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primaryGreen,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: '🪙 Crypto'),
                Tab(text: '💱 Forex'),
                Tab(text: '📈 Ações'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCryptoList(),
                _buildForexList(),
                _buildStocksList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCryptoList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('market_cache')
          .doc('crypto')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
            child: Text('Dados não disponíveis', style: TextStyle(color: AppTheme.textSecondary)),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final List<dynamic> cryptos = data?['data'] ?? [];

        if (cryptos.isEmpty) {
          return const Center(
            child: Text('Nenhuma crypto encontrada', style: TextStyle(color: AppTheme.textSecondary)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: cryptos.length > 15 ? 15 : cryptos.length,
          itemBuilder: (context, index) {
            final crypto = cryptos[index] as Map<String, dynamic>;
            return _buildMarketItem(
              symbol: crypto['symbol']?.toString().toUpperCase() ?? '',
              name: crypto['name'] ?? '',
              price: (crypto['current_price'] ?? 0).toDouble(),
              changePercent: (crypto['price_change_percentage_24h'] ?? 0).toDouble(),
              imageUrl: crypto['image'],
            );
          },
        );
      },
    );
  }

  Widget _buildForexList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('market_cache')
          .doc('forex')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
            child: Text('Dados não disponíveis', style: TextStyle(color: AppTheme.textSecondary)),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final List<dynamic> pairs = data?['data'] ?? [];

        if (pairs.isEmpty) {
          return const Center(
            child: Text('Nenhum par forex encontrado', style: TextStyle(color: AppTheme.textSecondary)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: pairs.length > 20 ? 20 : pairs.length,
          itemBuilder: (context, index) {
            final pair = pairs[index] as Map<String, dynamic>;
            return _buildMarketItem(
              symbol: pair['symbol'] ?? '',
              name: pair['name'] ?? pair['symbol'] ?? '',
              price: (pair['current_price'] ?? pair['rate'] ?? 0).toDouble(),
              changePercent: (pair['price_change_percentage_24h'] ?? 0).toDouble(),
              flag: pair['flag'],
            );
          },
        );
      },
    );
  }

  Widget _buildStocksList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('market_cache')
          .doc('stocks')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
            child: Text('Dados não disponíveis', style: TextStyle(color: AppTheme.textSecondary)),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final List<dynamic> stocks = data?['data'] ?? [];

        if (stocks.isEmpty) {
          return const Center(
            child: Text('Nenhuma ação encontrada', style: TextStyle(color: AppTheme.textSecondary)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: stocks.length > 20 ? 20 : stocks.length,
          itemBuilder: (context, index) {
            final stock = stocks[index] as Map<String, dynamic>;
            return _buildMarketItem(
              symbol: stock['symbol'] ?? '',
              name: stock['name'] ?? '',
              price: (stock['current_price'] ?? 0).toDouble(),
              changePercent: (stock['price_change_percentage_24h'] ?? 0).toDouble(),
              imageUrl: stock['image'],
            );
          },
        );
      },
    );
  }

  Widget _buildMarketItem({
    required String symbol,
    required String name,
    required double price,
    required double changePercent,
    String? imageUrl,
    String? flag,
  }) {
    final isPositive = changePercent >= 0;
    final changeColor = isPositive ? AppTheme.successGreen : AppTheme.errorRed;
    final changeIcon = isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down;

    String formattedPrice;
    if (price >= 1000) {
      formattedPrice = '\$${price.toStringAsFixed(2)}';
    } else if (price >= 1) {
      formattedPrice = '\$${price.toStringAsFixed(4)}';
    } else {
      formattedPrice = '\$${price.toStringAsFixed(6)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.cardDark.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (flag != null)
            Text(flag, style: const TextStyle(fontSize: 20))
          else if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) => Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.greenTransparent20,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      symbol.isNotEmpty ? symbol[0] : '?',
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppTheme.greenTransparent20,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  symbol.isNotEmpty ? symbol[0] : '?',
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  symbol,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
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
                formattedPrice,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(changeIcon, color: changeColor, size: 16),
                  Text(
                    '${changePercent.abs().toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: changeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../widgets/add_transaction_dialog.dart';
import '../widgets/edit_transaction_dialog.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedPeriod = 1;
  final List<String> _periods = ['1D', '7D', '1M', '3M', '1Y', 'YTD', 'ALL'];
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getAssetTypeFromIndex(int index) {
    switch (index) {
      case 0:
        return 'Criptomoedas';
      case 1:
        return 'Ações';
      case 2:
        return 'Forex';
      default:
        return 'Criptomoedas';
    }
  }

  Future<void> _exportToCsv() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final assetType = _getAssetTypeFromIndex(_tabController.index);
      final snapshot = await FirebaseFirestore.instance
          .collection('portfolio_transactions')
          .where('userId', isEqualTo: user.uid)
          .where('assetType', isEqualTo: assetType)
          .orderBy('date', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nenhuma transação para exportar'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Criar CSV
      final buffer = StringBuffer();
      buffer.writeln('Data,Tipo,Símbolo,Nome,Quantidade,Preço,Taxas,Total,Observações');

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(date);
        final type = data['transactionType'] ?? '';
        final symbol = data['symbol'] ?? '';
        final name = (data['name'] ?? '').toString().replaceAll(',', ';');
        final quantity = data['quantity']?.toString() ?? '0';
        final price = data['price']?.toString() ?? '0';
        final fees = data['fees']?.toString() ?? '0';
        final total = data['total']?.toString() ?? '0';
        final obs = (data['observations'] ?? '').toString().replaceAll(',', ';').replaceAll('\n', ' ');

        buffer.writeln('$dateStr,$type,$symbol,$name,$quantity,$price,$fees,$total,$obs');
      }

      // Salvar arquivo
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/portfolio_${assetType.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(buffer.toString());

      // Compartilhar
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Portfólio $assetType',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${snapshot.docs.length} transações exportadas'),
            backgroundColor: const Color(0xFF00FF88),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final assetType = _getAssetTypeFromIndex(_tabController.index);

    return Scaffold(
      backgroundColor: const Color(0xFF0E1116),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Portfólio',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Acompanhe seus investimentos em tempo real',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: _exportToCsv,
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: const Text('Exportar CSV'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF2a2f36)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const AddTransactionDialog(),
                          );
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Adicionar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF88),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1a1f26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: _GlowingBorderIndicator(
                  borderRadius: BorderRadius.circular(10),
                  borderColor: const Color(0xFF00FF88),
                  borderWidth: 2,
                  glowColor: const Color(0xFF00FF88),
                  glowSpread: 8,
                  glowBlur: 12,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                tabs: const [
                  Tab(text: 'Crypto'),
                  Tab(text: 'Ações'),
                  Tab(text: 'Forex'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: user == null
                  ? const Center(
                      child: Text(
                        'Faça login para ver seu portfólio',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('portfolio_transactions')
                          .where('userId', isEqualTo: user.uid)
                          .where('assetType', isEqualTo: assetType)
                          .orderBy('date', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.cloud_off, color: Colors.orange, size: 48),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Não foi possível carregar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Verifique sua conexão com a internet e tente novamente.',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => setState(() {}),
                                    icon: const Icon(Icons.refresh, size: 18),
                                    label: const Text('Tentar novamente'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00FF88),
                                      foregroundColor: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF00FF88),
                            ),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];

                        // Calcular totais
                        double totalValue = 0;
                        double totalBought = 0;
                        double totalSold = 0;
                        final Map<String, Map<String, dynamic>> holdings = {};

                        for (final doc in docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final symbol = data['symbol'] as String;
                          final quantity = (data['quantity'] ?? 0).toDouble();
                          final price = (data['price'] ?? 0).toDouble();
                          final type = data['transactionType'] as String;

                          if (!holdings.containsKey(symbol)) {
                            holdings[symbol] = {
                              'name': data['name'] ?? symbol,
                              'quantity': 0.0,
                              'totalCost': 0.0,
                              'transactions': <Map<String, dynamic>>[],
                            };
                          }

                          if (type == 'Compra') {
                            holdings[symbol]!['quantity'] += quantity;
                            holdings[symbol]!['totalCost'] += quantity * price;
                            totalBought += quantity * price;
                          } else {
                            holdings[symbol]!['quantity'] -= quantity;
                            totalSold += quantity * price;
                          }

                          (holdings[symbol]!['transactions'] as List).add({
                            'id': doc.id,
                            ...data,
                          });
                        }

                        // Calcular valor total (usando preço médio)
                        holdings.forEach((symbol, data) {
                          if (data['quantity'] > 0 && data['totalCost'] > 0) {
                            totalValue += data['totalCost'] as double;
                          }
                        });

                        final pnl = totalSold - totalBought + totalValue;

                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoCard(
                                      'Valor do Portfólio',
                                      'US\$ ${totalValue.toStringAsFixed(2)}',
                                      null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildInfoCard(
                                      'PnL Total',
                                      'US\$ ${pnl.toStringAsFixed(2)}',
                                      pnl >= 0 ? '+${((pnl / (totalBought > 0 ? totalBought : 1)) * 100).toStringAsFixed(2)}%' : '${((pnl / (totalBought > 0 ? totalBought : 1)) * 100).toStringAsFixed(2)}%',
                                      isPositive: pnl >= 0,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoCard(
                                      'Total Comprado',
                                      'US\$ ${totalBought.toStringAsFixed(2)}',
                                      null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildInfoCard(
                                      'Total Vendido',
                                      'US\$ ${totalSold.toStringAsFixed(2)}',
                                      null,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              Row(
                                children: [
                                  _buildTabButton('Ativos', 0),
                                  const SizedBox(width: 12),
                                  _buildTabButton('Histórico', 1),
                                ],
                              ),

                              const SizedBox(height: 24),

                              if (_selectedTab == 0)
                                _buildHoldingsList(holdings)
                              else
                                _buildTransactionsList(docs),

                              const SizedBox(height: 100),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoldingsList(Map<String, Map<String, dynamic>> holdings) {
    final activeHoldings = holdings.entries
        .where((e) => (e.value['quantity'] as double) > 0)
        .toList();

    if (activeHoldings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1f26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.account_balance_wallet_outlined, color: Colors.grey, size: 48),
              SizedBox(height: 12),
              Text(
                'Nenhum ativo em carteira',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 4),
              Text(
                'Adicione sua primeira transação',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: activeHoldings.map((entry) {
        final symbol = entry.key;
        final data = entry.value;
        final quantity = data['quantity'] as double;
        final totalCost = data['totalCost'] as double;
        final avgPrice = quantity > 0 ? totalCost / quantity : 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1a1f26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(
                    Icons.monetization_on,
                    color: Color(0xFF00FF88),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      symbol,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      data['name'] as String,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${quantity.toStringAsFixed(quantity < 1 ? 8 : 2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'PM: \$${avgPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransactionsList(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1f26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.history, color: Colors.grey, size: 48),
              SizedBox(height: 12),
              Text(
                'Nenhuma transação registrada',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: docs.take(20).map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final date = (data['date'] as Timestamp).toDate();
        final symbol = data['symbol'] as String;
        final type = data['transactionType'] as String;
        final quantity = (data['quantity'] ?? 0).toDouble();
        final price = (data['price'] ?? 0).toDouble();
        final total = quantity * price;
        final isBuy = type == 'Compra';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1a1f26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isBuy
                      ? const Color(0xFF00FF88).withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isBuy ? const Color(0xFF00FF88) : Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$type $symbol',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(date),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isBuy ? const Color(0xFF00FF88) : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${quantity.toStringAsFixed(quantity < 1 ? 8 : 2)} @ \$${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF00FF88), size: 20),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => EditTransactionDialog(
                          transactionId: doc.id,
                          transactionData: data,
                        ),
                      );
                    },
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF1a1f26),
                          title: const Text(
                            'Excluir transação?',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: Text(
                            'Deseja excluir a transação de $type $symbol?\n\nEsta ação não pode ser desfeita.',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Excluir',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await doc.reference.delete();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transação excluída'),
                              backgroundColor: Color(0xFF00FF88),
                            ),
                          );
                        }
                      }
                    },
                    tooltip: 'Excluir',
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoCard(String title, String value, String? percentage, {bool isPositive = true}) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (percentage != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: isPositive ? const Color(0xFF00FF88) : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  percentage,
                  style: TextStyle(
                    fontSize: 12,
                    color: isPositive ? const Color(0xFF00FF88) : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final bool isSelected = _selectedTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00FF88) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }
}

class _GlowingBorderIndicator extends Decoration {
  final BorderRadius borderRadius;
  final Color borderColor;
  final double borderWidth;
  final Color glowColor;
  final double glowSpread;
  final double glowBlur;

  const _GlowingBorderIndicator({
    required this.borderRadius,
    required this.borderColor,
    required this.borderWidth,
    required this.glowColor,
    required this.glowSpread,
    required this.glowBlur,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _GlowingBorderPainter(
      borderRadius: borderRadius,
      borderColor: borderColor,
      borderWidth: borderWidth,
      glowColor: glowColor,
      glowSpread: glowSpread,
      glowBlur: glowBlur,
    );
  }
}

class _GlowingBorderPainter extends BoxPainter {
  final BorderRadius borderRadius;
  final Color borderColor;
  final double borderWidth;
  final Color glowColor;
  final double glowSpread;
  final double glowBlur;

  _GlowingBorderPainter({
    required this.borderRadius,
    required this.borderColor,
    required this.borderWidth,
    required this.glowColor,
    required this.glowSpread,
    required this.glowBlur,
  });

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final rect = offset & configuration.size!;
    final rrect = borderRadius.toRRect(rect);

    // Paint glow effect
    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowBlur)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth + glowSpread;

    canvas.drawRRect(rrect, glowPaint);

    // Paint border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRRect(rrect, borderPaint);
  }
}

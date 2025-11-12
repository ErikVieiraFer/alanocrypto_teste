import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction_model.dart';
import '../../../models/crypto_data_model.dart';
import '../../../services/transaction_service.dart';
import '../../../services/crypto_market_service.dart';
import '../../../theme/app_theme.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> with SingleTickerProviderStateMixin {
  final TransactionService _transactionService = TransactionService();
  final CryptoMarketService _cryptoService = CryptoMarketService();

  late TabController _tabController;
  double _balance = 10000.0;
  Map<String, double> _currentPrices = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBalance();
    _loadPrices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    final balance = await _transactionService.getCurrentBalance();
    if (mounted) {
      setState(() => _balance = balance);
    }
  }

  Future<void> _loadPrices() async {
    try {
      final cryptos = await _cryptoService.fetchCryptoData();
      final prices = <String, double>{};
      for (var crypto in cryptos) {
        prices[crypto.id] = crypto.currentPrice;
      }
      if (mounted) {
        setState(() => _currentPrices = prices);
      }
    } catch (e) {
      // Handle error
    }
  }

  void _showCreateTransactionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateTransactionModal(
        onTransactionCreated: () {
          _loadBalance();
        },
      ),
    );
  }

  Future<void> _resetPortfolio() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: Text('Resetar Portfólio', style: AppTheme.heading3),
        content: Text(
          'Tem certeza que deseja resetar seu portfólio? Todas as transações serão apagadas e o saldo voltará para \$10,000.',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resetar', style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _transactionService.resetPortfolio();
        _loadBalance();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Portfólio resetado com sucesso'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao resetar portfólio'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: AppTheme.backgroundBlack,
          child: Column(
            children: [
              Container(
                color: AppTheme.cardDark,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppTheme.paddingMedium, AppTheme.paddingMedium, AppTheme.paddingMedium, AppTheme.gapSmall),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Saldo Disponível',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppTheme.gapSmall),
                              Text(
                                '\$${_balance.toStringAsFixed(2)}',
                                style: AppTheme.heading1,
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: AppTheme.primaryGreen),
                            onPressed: _resetPortfolio,
                          ),
                        ],
                      ),
                    ),
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppTheme.primaryGreen,
                      indicatorWeight: 3,
                      labelColor: AppTheme.textPrimary,
                      unselectedLabelColor: AppTheme.textSecondary,
                      labelStyle: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                      tabs: const [
                        Tab(text: 'Ativas'),
                        Tab(text: 'Histórico'),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _ActiveTransactionsTab(
                      currentPrices: _currentPrices,
                      onTransactionClosed: _loadBalance,
                    ),
                    const _HistoryTransactionsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'transactions_fab',
            onPressed: _showCreateTransactionModal,
            backgroundColor: AppTheme.primaryGreen,
            child: const Icon(Icons.add, color: AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _ActiveTransactionsTab extends StatelessWidget {
  final Map<String, double> currentPrices;
  final VoidCallback onTransactionClosed;

  const _ActiveTransactionsTab({
    required this.currentPrices,
    required this.onTransactionClosed,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TransactionModel>>(
      stream: TransactionService().getActiveTransactionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryGreen,
            ),
          );
        }

        final transactions = snapshot.data ?? [];

        if (transactions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.trending_up,
                  size: 64,
                  color: AppTheme.textSecondary,
                ),
                SizedBox(height: 16),
                Text(
                  'Nenhuma transação ativa',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            return _TransactionCard(
              transaction: transactions[index],
              currentPrice: currentPrices[transactions[index].forexPair] ?? 0,
              onClosed: onTransactionClosed,
            );
          },
        );
      },
    );
  }
}

class _HistoryTransactionsTab extends StatelessWidget {
  const _HistoryTransactionsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TransactionModel>>(
      stream: TransactionService().getClosedTransactionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryGreen,
            ),
          );
        }

        final transactions = snapshot.data ?? [];

        if (transactions.isEmpty) {
          return const Center(
            child: Text(
              'Nenhuma transação no histórico',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 18,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            return _HistoryCard(transaction: transactions[index]);
          },
        );
      },
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final double currentPrice;
  final VoidCallback onClosed;

  const _TransactionCard({
    required this.transaction,
    required this.currentPrice,
    required this.onClosed,
  });

  Future<void> _closeTransaction(BuildContext context) async {
    try {
      await TransactionService().closeTransaction(transaction.id, currentPrice);
      onClosed();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transação fechada'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pnl = transaction.calculatePnL(currentPrice);
    final pnlPercentage = transaction.calculatePnLPercentage(currentPrice);
    final isProfitable = pnl >= 0;
    final pnlColor = isProfitable
        ? AppTheme.primaryGreen
        : AppTheme.errorRed;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: transaction.type == TransactionType.buy
                      ? AppTheme.greenTransparent20
                      : AppTheme.redTransparent20,
                  borderRadius: AppTheme.tinyRadius,
                ),
                child: Text(
                  transaction.type == TransactionType.buy ? 'COMPRA' : 'VENDA',
                  style: TextStyle(
                    color: transaction.type == TransactionType.buy
                        ? AppTheme.primaryGreen
                        : AppTheme.errorRed,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt),
                style: AppTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.gapMedium),
          Text(
            transaction.cryptoSymbol.toUpperCase(),
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            transaction.forexPairName,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quantidade',
                      style: AppTheme.bodySmall,
                    ),
                    Text(
                      transaction.quantity.toStringAsFixed(4),
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preço Entrada',
                      style: AppTheme.bodySmall,
                    ),
                    Text(
                      '\$${transaction.entryPrice.toStringAsFixed(2)}',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preço Atual',
                      style: AppTheme.bodySmall,
                    ),
                    Text(
                      '\$${currentPrice.toStringAsFixed(2)}',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.gapMedium),
          Container(
            padding: const EdgeInsets.all(AppTheme.gapMedium),
            decoration: BoxDecoration(
              color: isProfitable
                  ? AppTheme.greenTransparent10
                  : AppTheme.redTransparent10,
              borderRadius: AppTheme.smallRadius,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'P&L',
                      style: AppTheme.bodySmall,
                    ),
                    Text(
                      '${pnl >= 0 ? '+' : ''}\$${pnl.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: pnlColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${pnlPercentage >= 0 ? '+' : ''}${pnlPercentage.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: pnlColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.gapMedium),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _closeTransaction(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                foregroundColor: AppTheme.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: AppTheme.gapMedium),
              ),
              child: const Text('Fechar Posição'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final TransactionModel transaction;

  const _HistoryCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final pnl = transaction.calculatePnL(transaction.exitPrice!);
    final isProfitable = pnl >= 0;
    final pnlColor = isProfitable
        ? AppTheme.primaryGreen
        : AppTheme.errorRed;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                transaction.cryptoSymbol.toUpperCase(),
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: AppTheme.gapSmall),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: transaction.type == TransactionType.buy
                      ? AppTheme.greenTransparent20
                      : AppTheme.redTransparent20,
                  borderRadius: AppTheme.tinyRadius,
                ),
                child: Text(
                  transaction.type == TransactionType.buy ? 'COMPRA' : 'VENDA',
                  style: TextStyle(
                    color: transaction.type == TransactionType.buy
                        ? AppTheme.primaryGreen
                        : AppTheme.errorRed,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${pnl >= 0 ? '+' : ''}\$${pnl.toStringAsFixed(2)}',
                style: TextStyle(
                  color: pnlColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.gapSmall),
          Text(
            'Aberto: ${DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt)}',
            style: AppTheme.bodySmall,
          ),
          Text(
            'Fechado: ${DateFormat('dd/MM/yyyy HH:mm').format(transaction.closedAt!)}',
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class CreateTransactionModal extends StatefulWidget {
  final VoidCallback onTransactionCreated;

  const CreateTransactionModal({super.key, required this.onTransactionCreated});

  @override
  State<CreateTransactionModal> createState() => _CreateTransactionModalState();
}

class _CreateTransactionModalState extends State<CreateTransactionModal> {
  final CryptoMarketService _cryptoService = CryptoMarketService();
  final TransactionService _transactionService = TransactionService();
  final TextEditingController _quantityController = TextEditingController();

  List<CryptoDataModel> _cryptos = [];
  CryptoDataModel? _selectedCrypto;
  TransactionType _selectedType = TransactionType.buy;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCryptos();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
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

  Future<void> _createTransaction() async {
    if (_selectedCrypto == null || _quantityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }

    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quantidade inválida'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    try {
      await _transactionService.createTransaction(
        forexPair: _selectedCrypto!.id,
        cryptoSymbol: _selectedCrypto!.symbol,
        forexPairName: _selectedCrypto!.name,
        type: _selectedType,
        quantity: quantity,
        entryPrice: _selectedCrypto!.currentPrice,
      );

      widget.onTransactionCreated();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transação criada com sucesso'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  'Nova Transação',
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
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryGreen,
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tipo',
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppTheme.gapSmall),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Compra'),
                                selected: _selectedType == TransactionType.buy,
                                onSelected: (selected) {
                                  setState(() => _selectedType = TransactionType.buy);
                                },
                                selectedColor: AppTheme.primaryGreen,
                                backgroundColor: AppTheme.borderDark,
                                labelStyle: TextStyle(
                                  color: _selectedType == TransactionType.buy
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.gapMedium),
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Venda'),
                                selected: _selectedType == TransactionType.sell,
                                onSelected: (selected) {
                                  setState(() => _selectedType = TransactionType.sell);
                                },
                                selectedColor: AppTheme.errorRed,
                                backgroundColor: AppTheme.borderDark,
                                labelStyle: TextStyle(
                                  color: _selectedType == TransactionType.sell
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.gapXLarge),
                        Text(
                          'Criptomoeda',
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppTheme.gapSmall),
                        DropdownButtonFormField<CryptoDataModel>(
                          value: _selectedCrypto,
                          decoration: InputDecoration(
                            hintText: 'Selecione uma criptomoeda',
                            hintStyle: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            filled: true,
                            fillColor: AppTheme.cardDark,
                            border: OutlineInputBorder(
                              borderRadius: AppTheme.defaultRadius,
                              borderSide: BorderSide.none,
                            ),
                          ),
                          dropdownColor: AppTheme.cardDark,
                          style: AppTheme.bodyMedium,
                          items: _cryptos.map((crypto) {
                            return DropdownMenuItem(
                              value: crypto,
                              child: Text(
                                '${crypto.symbol.toUpperCase()} - \$${crypto.currentPrice.toStringAsFixed(2)}',
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedCrypto = value);
                          },
                        ),
                        const SizedBox(height: AppTheme.gapXLarge),
                        Text(
                          'Quantidade',
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppTheme.gapSmall),
                        TextField(
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: AppTheme.bodyMedium,
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: AppTheme.bodyMedium.copyWith(
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
                        if (_selectedCrypto != null && _quantityController.text.isNotEmpty) ...[
                          const SizedBox(height: AppTheme.gapXLarge),
                          Container(
                            padding: const EdgeInsets.all(AppTheme.paddingMedium),
                            decoration: BoxDecoration(
                              color: AppTheme.cardDark,
                              borderRadius: AppTheme.defaultRadius,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Preço Atual:',
                                      style: AppTheme.bodyMedium.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '\$${_selectedCrypto!.currentPrice.toStringAsFixed(2)}',
                                      style: AppTheme.bodyMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.gapSmall),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total:',
                                      style: AppTheme.bodyLarge.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '\$${((double.tryParse(_quantityController.text) ?? 0) * _selectedCrypto!.currentPrice).toStringAsFixed(2)}',
                                      style: AppTheme.bodyLarge.copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: AppTheme.gapXLarge),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _createTransaction,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: AppTheme.textPrimary,
                              padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingMedium),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppTheme.defaultRadius,
                              ),
                            ),
                            child: const Text(
                              'Criar Transação',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction_model.dart';
import '../../../models/crypto_data_model.dart';
import '../../../services/transaction_service.dart';
import '../../../services/crypto_market_service.dart';

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
        backgroundColor: const Color.fromRGBO(18, 18, 18, 1),
        title: const Text('Resetar Portfólio', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Tem certeza que deseja resetar seu portfólio? Todas as transações serão apagadas e o saldo voltará para \$10,000.',
          style: TextStyle(color: Color.fromRGBO(158, 158, 158, 1)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resetar', style: TextStyle(color: Colors.red)),
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
              backgroundColor: Color.fromRGBO(76, 175, 80, 1),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao resetar portfólio'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
          'Transações',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetPortfolio,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Saldo Disponível',
                      style: TextStyle(
                        color: Color.fromRGBO(158, 158, 158, 1),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${_balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: const Color.fromRGBO(76, 175, 80, 1),
                labelColor: Colors.white,
                unselectedLabelColor: const Color.fromRGBO(158, 158, 158, 1),
                tabs: const [
                  Tab(text: 'Ativas'),
                  Tab(text: 'Histórico'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ActiveTransactionsTab(
            currentPrices: _currentPrices,
            onTransactionClosed: _loadBalance,
          ),
          const _HistoryTransactionsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTransactionModal,
        backgroundColor: const Color.fromRGBO(76, 175, 80, 1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
              color: Color.fromRGBO(76, 175, 80, 1),
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
                  color: Color.fromRGBO(158, 158, 158, 1),
                ),
                SizedBox(height: 16),
                Text(
                  'Nenhuma transação ativa',
                  style: TextStyle(
                    color: Color.fromRGBO(158, 158, 158, 1),
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
              currentPrice: currentPrices[transactions[index].cryptoId] ?? 0,
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
              color: Color.fromRGBO(76, 175, 80, 1),
            ),
          );
        }

        final transactions = snapshot.data ?? [];

        if (transactions.isEmpty) {
          return const Center(
            child: Text(
              'Nenhuma transação no histórico',
              style: TextStyle(
                color: Color.fromRGBO(158, 158, 158, 1),
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
            backgroundColor: Color.fromRGBO(76, 175, 80, 1),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: transaction.type == TransactionType.buy
                      ? const Color.fromRGBO(76, 175, 80, 0.2)
                      : const Color.fromRGBO(244, 67, 54, 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  transaction.type == TransactionType.buy ? 'COMPRA' : 'VENDA',
                  style: TextStyle(
                    color: transaction.type == TransactionType.buy
                        ? const Color.fromRGBO(76, 175, 80, 1)
                        : const Color.fromRGBO(244, 67, 54, 1),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt),
                style: const TextStyle(
                  color: Color.fromRGBO(158, 158, 158, 1),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            transaction.cryptoSymbol.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            transaction.cryptoName,
            style: const TextStyle(
              color: Color.fromRGBO(158, 158, 158, 1),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quantidade',
                      style: TextStyle(
                        color: Color.fromRGBO(158, 158, 158, 1),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      transaction.quantity.toStringAsFixed(4),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
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
                    const Text(
                      'Preço Entrada',
                      style: TextStyle(
                        color: Color.fromRGBO(158, 158, 158, 1),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '\$${transaction.entryPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
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
                    const Text(
                      'Preço Atual',
                      style: TextStyle(
                        color: Color.fromRGBO(158, 158, 158, 1),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '\$${currentPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isProfitable
                  ? const Color.fromRGBO(76, 175, 80, 0.1)
                  : const Color.fromRGBO(244, 67, 54, 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'P&L',
                      style: TextStyle(
                        color: Color.fromRGBO(158, 158, 158, 1),
                        fontSize: 12,
                      ),
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _closeTransaction(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(244, 67, 54, 1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                transaction.cryptoSymbol.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: transaction.type == TransactionType.buy
                      ? const Color.fromRGBO(76, 175, 80, 0.2)
                      : const Color.fromRGBO(244, 67, 54, 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  transaction.type == TransactionType.buy ? 'COMPRA' : 'VENDA',
                  style: TextStyle(
                    color: transaction.type == TransactionType.buy
                        ? const Color.fromRGBO(76, 175, 80, 1)
                        : const Color.fromRGBO(244, 67, 54, 1),
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
          const SizedBox(height: 8),
          Text(
            'Aberto: ${DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt)}',
            style: const TextStyle(
              color: Color.fromRGBO(158, 158, 158, 1),
              fontSize: 12,
            ),
          ),
          Text(
            'Fechado: ${DateFormat('dd/MM/yyyy HH:mm').format(transaction.closedAt!)}',
            style: const TextStyle(
              color: Color.fromRGBO(158, 158, 158, 1),
              fontSize: 12,
            ),
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
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quantidade inválida'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _transactionService.createTransaction(
        cryptoId: _selectedCrypto!.id,
        cryptoSymbol: _selectedCrypto!.symbol,
        cryptoName: _selectedCrypto!.name,
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
            backgroundColor: Color.fromRGBO(76, 175, 80, 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
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
                  'Nova Transação',
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
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color.fromRGBO(76, 175, 80, 1),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tipo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Compra'),
                                selected: _selectedType == TransactionType.buy,
                                onSelected: (selected) {
                                  setState(() => _selectedType = TransactionType.buy);
                                },
                                selectedColor: const Color.fromRGBO(76, 175, 80, 1),
                                backgroundColor: const Color.fromRGBO(50, 50, 50, 1),
                                labelStyle: TextStyle(
                                  color: _selectedType == TransactionType.buy
                                      ? Colors.white
                                      : const Color.fromRGBO(158, 158, 158, 1),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Venda'),
                                selected: _selectedType == TransactionType.sell,
                                onSelected: (selected) {
                                  setState(() => _selectedType = TransactionType.sell);
                                },
                                selectedColor: const Color.fromRGBO(244, 67, 54, 1),
                                backgroundColor: const Color.fromRGBO(50, 50, 50, 1),
                                labelStyle: TextStyle(
                                  color: _selectedType == TransactionType.sell
                                      ? Colors.white
                                      : const Color.fromRGBO(158, 158, 158, 1),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Criptomoeda',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<CryptoDataModel>(
                          value: _selectedCrypto,
                          decoration: InputDecoration(
                            hintText: 'Selecione uma criptomoeda',
                            hintStyle: const TextStyle(
                              color: Color.fromRGBO(158, 158, 158, 1),
                            ),
                            filled: true,
                            fillColor: const Color.fromRGBO(18, 18, 18, 1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          dropdownColor: const Color.fromRGBO(18, 18, 18, 1),
                          style: const TextStyle(color: Colors.white),
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
                        const SizedBox(height: 24),
                        const Text(
                          'Quantidade',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: const TextStyle(
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
                        if (_selectedCrypto != null && _quantityController.text.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(18, 18, 18, 1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Preço Atual:',
                                      style: TextStyle(
                                        color: Color.fromRGBO(158, 158, 158, 1),
                                      ),
                                    ),
                                    Text(
                                      '\$${_selectedCrypto!.currentPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total:',
                                      style: TextStyle(
                                        color: Color.fromRGBO(158, 158, 158, 1),
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '\$${((double.tryParse(_quantityController.text) ?? 0) * _selectedCrypto!.currentPrice).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.white,
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
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _createTransaction,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromRGBO(76, 175, 80, 1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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

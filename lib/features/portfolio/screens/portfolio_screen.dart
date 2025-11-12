import 'package:flutter/material.dart';
import '../../../models/transaction_model.dart';
import '../../../services/transaction_service.dart';
import '../../../theme/app_theme.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> with SingleTickerProviderStateMixin {
  final TransactionService _transactionService = TransactionService();

  late TabController _tabController;
  double _balance = 10000.0;
  Map<String, double> _currentPrices = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBalance();
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

  Future<void> _editBalance() async {
    final controller = TextEditingController(text: _balance.toStringAsFixed(2));

    final newBalance = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: Text('Editar Saldo', style: AppTheme.heading3),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Novo Saldo',
            prefixText: '\$ ',
            filled: true,
            fillColor: AppTheme.cardMedium,
            border: OutlineInputBorder(
              borderRadius: AppTheme.defaultRadius,
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Salvar', style: TextStyle(color: AppTheme.primaryGreen)),
          ),
        ],
      ),
    );

    if (newBalance != null && newBalance.isNotEmpty) {
      try {
        final value = double.parse(newBalance);
        if (value >= 0) {
          await _transactionService.setBalance(value);
          _loadBalance();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Saldo atualizado para \$${value.toStringAsFixed(2)}'),
                backgroundColor: AppTheme.primaryGreen,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Valor inválido'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
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
          if (mounted) {
            setState(() {});
          }
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
          'Tem certeza que deseja resetar seu portfólio? Todas as operações serão apagadas e o saldo voltará para \$10,000.',
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

  Future<void> _closeTransaction(TransactionModel transaction) async {
    try {
      await _transactionService.closeTransaction(
        transaction.id,
        transaction.entryPrice,
      );
      _loadBalance();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Operação fechada com sucesso'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao fechar operação'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Widget _buildActiveTab() {
    return StreamBuilder<List<TransactionModel>>(
      stream: _transactionService.getActiveTransactionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen),
          );
        }

        if (snapshot.hasError) {
          print('=== ERRO NO STREAMBUILDER (ATIVAS) ===');
          print('Erro: ${snapshot.error}');
          print('Stack: ${snapshot.stackTrace}');
          if (snapshot.error.toString().contains('index') ||
              snapshot.error.toString().contains('INDEX')) {
            print('');
            print('⚠️  LINK DO INDEX FIRESTORE:');
            print(snapshot.error.toString());
            print('');
          }
          print('======================================');

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
                const SizedBox(height: AppTheme.gapLarge),
                Text('Erro ao carregar operações', style: AppTheme.heading3),
                const SizedBox(height: AppTheme.gapSmall),
                Text(
                  snapshot.error.toString(),
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final transactions = snapshot.data ?? [];

        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.trending_up, size: 64, color: AppTheme.textSecondary),
                const SizedBox(height: AppTheme.gapLarge),
                Text('Nenhuma operação ativa', style: AppTheme.heading3),
                const SizedBox(height: AppTheme.gapSmall),
                Text(
                  'Crie sua primeira operação',
                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: AppTheme.primaryGreen,
          child: ListView.builder(
            padding: const EdgeInsets.all(AppTheme.paddingMedium),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              return _buildTransactionCard(transactions[index], true);
            },
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<List<TransactionModel>>(
      stream: _transactionService.getClosedTransactionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen),
          );
        }

        if (snapshot.hasError) {
          print('=== ERRO NO STREAMBUILDER (HISTÓRICO) ===');
          print('Erro: ${snapshot.error}');
          print('Stack: ${snapshot.stackTrace}');
          if (snapshot.error.toString().contains('index') ||
              snapshot.error.toString().contains('INDEX')) {
            print('');
            print('⚠️  LINK DO INDEX FIRESTORE:');
            print(snapshot.error.toString());
            print('');
          }
          print('=========================================');

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
                const SizedBox(height: AppTheme.gapLarge),
                Text('Erro ao carregar histórico', style: AppTheme.heading3),
                const SizedBox(height: AppTheme.gapSmall),
                Text(
                  snapshot.error.toString(),
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final transactions = snapshot.data ?? [];

        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history, size: 64, color: AppTheme.textSecondary),
                const SizedBox(height: AppTheme.gapLarge),
                Text('Nenhuma operação no histórico', style: AppTheme.heading3),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: AppTheme.primaryGreen,
          child: ListView.builder(
            padding: const EdgeInsets.all(AppTheme.paddingMedium),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              return _buildTransactionCard(transactions[index], false);
            },
          ),
        );
      },
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction, bool isActive) {
    final double priceToUse;
    if (isActive) {
      priceToUse = _currentPrices[transaction.forexPair] ?? transaction.entryPrice;
    } else {
      priceToUse = transaction.exitPrice ?? transaction.entryPrice;
    }

    final pnl = transaction.calculatePnL(priceToUse);
    final isProfit = pnl >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.gapMedium),
      decoration: AppTheme.modernCard(
        glowColor: isProfit ? AppTheme.primaryGreen : AppTheme.errorRed,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isProfit ? AppTheme.primaryGreen : AppTheme.errorRed,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                transaction.forexPair,
                style: AppTheme.heading2.copyWith(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingSmall,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: transaction.type == TransactionType.buy
                      ? AppTheme.primaryGreen
                      : AppTheme.errorRed,
                  borderRadius: AppTheme.smallRadius,
                ),
                child: Text(
                  transaction.type == TransactionType.buy ? 'BUY' : 'SELL',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.gapSmall),
          Text(
            '${transaction.quantity} lotes @ \$${transaction.entryPrice.toStringAsFixed(2)}',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
          if (!isActive && transaction.exitPrice != null) ...[
            const SizedBox(height: AppTheme.gapSmall),
            Text(
              'Fechado @ \$${transaction.exitPrice!.toStringAsFixed(2)}',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            ),
          ],
          const SizedBox(height: AppTheme.gapMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'P&L',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                  ),
                  Row(
                    children: [
                      Icon(
                        isProfit ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 18,
                        color: isProfit ? AppTheme.primaryGreen : AppTheme.errorRed,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${pnl >= 0 ? '+' : ''}\$${pnl.toStringAsFixed(2)}',
                        style: AppTheme.heading3.copyWith(
                          color: isProfit ? AppTheme.primaryGreen : AppTheme.errorRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (isActive)
                ElevatedButton(
                  onPressed: () => _closeTransaction(transaction),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.paddingLarge,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Fechar'),
                ),
            ],
          ),
        ],
        ),
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
              Container(
                color: AppTheme.cardDark,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.paddingMedium,
                        AppTheme.paddingMedium,
                        AppTheme.paddingMedium,
                        AppTheme.gapSmall,
                      ),
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
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: AppTheme.primaryGreen),
                                onPressed: _editBalance,
                                tooltip: 'Editar Saldo',
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
                                onPressed: _resetPortfolio,
                                tooltip: 'Resetar Portfólio',
                              ),
                            ],
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
                    _buildActiveTab(),
                    _buildHistoryTab(),
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
            heroTag: 'portfolio_fab',
            onPressed: _showCreateTransactionModal,
            backgroundColor: AppTheme.primaryGreen,
            child: const Icon(Icons.add, color: AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }
}

class CreateTransactionModal extends StatefulWidget {
  final VoidCallback onTransactionCreated;

  const CreateTransactionModal({
    super.key,
    required this.onTransactionCreated,
  });

  @override
  State<CreateTransactionModal> createState() => _CreateTransactionModalState();
}

class _CreateTransactionModalState extends State<CreateTransactionModal> {
  final _formKey = GlobalKey<FormState>();
  final TransactionService _transactionService = TransactionService();

  String? _selectedPair;
  String _customPair = '';
  TransactionType _type = TransactionType.buy;
  final _quantityController = TextEditingController();
  final _entryController = TextEditingController();
  final _target1Controller = TextEditingController();
  final _target2Controller = TextEditingController();
  final _target3Controller = TextEditingController();
  final _stopLossController = TextEditingController();

  bool _isLoading = false;
  bool _useCustomPair = false;

  final List<Map<String, String>> _commonPairs = [
    {'symbol': 'EUR/USD', 'name': 'Euro / Dólar Americano'},
    {'symbol': 'GBP/USD', 'name': 'Libra Esterlina / Dólar Americano'},
    {'symbol': 'USD/JPY', 'name': 'Dólar Americano / Iene Japonês'},
    {'symbol': 'AUD/USD', 'name': 'Dólar Australiano / Dólar Americano'},
    {'symbol': 'USD/CAD', 'name': 'Dólar Americano / Dólar Canadense'},
    {'symbol': 'NZD/USD', 'name': 'Dólar Neozelandês / Dólar Americano'},
    {'symbol': 'EUR/GBP', 'name': 'Euro / Libra Esterlina'},
    {'symbol': 'USD/CHF', 'name': 'Dólar Americano / Franco Suíço'},
  ];

  @override
  void dispose() {
    _quantityController.dispose();
    _entryController.dispose();
    _target1Controller.dispose();
    _target2Controller.dispose();
    _target3Controller.dispose();
    _stopLossController.dispose();
    super.dispose();
  }

  Future<void> _createTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final pair = _useCustomPair ? _customPair : _selectedPair;
    if (pair == null || pair.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione ou digite um par Forex'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final quantity = double.parse(_quantityController.text);
      final entry = double.parse(_entryController.text);

      await _transactionService.createTransaction(
        forexPair: pair,
        cryptoSymbol: pair,
        forexPairName: _commonPairs.firstWhere(
          (p) => p['symbol'] == pair,
          orElse: () => {'symbol': pair, 'name': pair},
        )['name']!,
        type: _type,
        quantity: quantity,
        entryPrice: entry,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onTransactionCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Operação $pair criada com sucesso!'),
            backgroundColor: AppTheme.primaryGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Saldo') || e.toString().contains('insuficiente')
                  ? 'Saldo insuficiente'
                  : 'Erro ao criar operação',
            ),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Nova Operação', style: AppTheme.heading2),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.gapLarge),
              Row(
                children: [
                  Text('Par personalizado', style: AppTheme.bodyMedium),
                  const Spacer(),
                  Switch(
                    value: _useCustomPair,
                    onChanged: (value) => setState(() => _useCustomPair = value),
                    activeColor: AppTheme.primaryGreen,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.gapMedium),
              if (!_useCustomPair)
                DropdownButtonFormField<String>(
                  value: _selectedPair,
                  decoration: InputDecoration(
                    labelText: 'Par Forex',
                    filled: true,
                    fillColor: AppTheme.cardMedium,
                    border: OutlineInputBorder(
                      borderRadius: AppTheme.defaultRadius,
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: AppTheme.cardMedium,
                  items: _commonPairs.map((pair) {
                    return DropdownMenuItem(
                      value: pair['symbol'],
                      child: Text('${pair['symbol']} - ${pair['name']}'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedPair = value),
                  validator: (value) =>
                      !_useCustomPair && value == null ? 'Selecione um par' : null,
                  style: const TextStyle(color: AppTheme.textPrimary),
                )
              else
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Par Forex (ex: EUR/USD)',
                    filled: true,
                    fillColor: AppTheme.cardMedium,
                    border: OutlineInputBorder(
                      borderRadius: AppTheme.defaultRadius,
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  onChanged: (value) => _customPair = value,
                  validator: (value) =>
                      _useCustomPair && (value == null || value.isEmpty)
                          ? 'Digite o par'
                          : null,
                ),
              const SizedBox(height: AppTheme.gapMedium),
              DropdownButtonFormField<TransactionType>(
                value: _type,
                decoration: InputDecoration(
                  labelText: 'Tipo',
                  filled: true,
                  fillColor: AppTheme.cardMedium,
                  border: OutlineInputBorder(
                    borderRadius: AppTheme.defaultRadius,
                    borderSide: BorderSide.none,
                  ),
                ),
                dropdownColor: AppTheme.cardMedium,
                items: const [
                  DropdownMenuItem(value: TransactionType.buy, child: Text('BUY (Compra)')),
                  DropdownMenuItem(value: TransactionType.sell, child: Text('SELL (Venda)')),
                ],
                onChanged: (value) => setState(() => _type = value!),
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: AppTheme.gapMedium),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantidade (Lotes)',
                  filled: true,
                  fillColor: AppTheme.cardMedium,
                  border: OutlineInputBorder(
                    borderRadius: AppTheme.defaultRadius,
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppTheme.textPrimary),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Digite a quantidade';
                  if (double.tryParse(value) == null) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.gapMedium),
              TextFormField(
                controller: _entryController,
                decoration: InputDecoration(
                  labelText: 'Preço de Entrada',
                  filled: true,
                  fillColor: AppTheme.cardMedium,
                  border: OutlineInputBorder(
                    borderRadius: AppTheme.defaultRadius,
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppTheme.textPrimary),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Digite o preço de entrada';
                  if (double.tryParse(value) == null) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.gapMedium),
              Text(
                'Targets (Opcional)',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.gapSmall),
              TextFormField(
                controller: _target1Controller,
                decoration: InputDecoration(
                  labelText: 'Target 1',
                  filled: true,
                  fillColor: AppTheme.cardMedium,
                  border: OutlineInputBorder(
                    borderRadius: AppTheme.defaultRadius,
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: AppTheme.gapSmall),
              TextFormField(
                controller: _target2Controller,
                decoration: InputDecoration(
                  labelText: 'Target 2',
                  filled: true,
                  fillColor: AppTheme.cardMedium,
                  border: OutlineInputBorder(
                    borderRadius: AppTheme.defaultRadius,
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: AppTheme.gapSmall),
              TextFormField(
                controller: _target3Controller,
                decoration: InputDecoration(
                  labelText: 'Target 3',
                  filled: true,
                  fillColor: AppTheme.cardMedium,
                  border: OutlineInputBorder(
                    borderRadius: AppTheme.defaultRadius,
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: AppTheme.gapMedium),
              TextFormField(
                controller: _stopLossController,
                decoration: InputDecoration(
                  labelText: 'Stop Loss (Opcional)',
                  filled: true,
                  fillColor: AppTheme.cardMedium,
                  border: OutlineInputBorder(
                    borderRadius: AppTheme.defaultRadius,
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: AppTheme.gapXLarge),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: const BorderSide(color: AppTheme.borderDark),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppTheme.defaultRadius,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.gapMedium),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: AppTheme.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppTheme.defaultRadius,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(AppTheme.textPrimary),
                              ),
                            )
                          : const Text('Criar Operação'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

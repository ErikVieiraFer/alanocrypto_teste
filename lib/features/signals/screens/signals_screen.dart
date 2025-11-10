import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/signal_model.dart';
import '../../../services/signal_service.dart';

class SignalsScreen extends StatefulWidget {
  const SignalsScreen({super.key});

  @override
  State<SignalsScreen> createState() => _SignalsScreenState();
}

class _SignalsScreenState extends State<SignalsScreen> with SingleTickerProviderStateMixin {
  final SignalService _signalService = SignalService();
  SignalType? _selectedFilter;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }





























  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _copySignal(Signal signal) async {
    try {
      // Formatar targets
      final targetsText = signal.targets
          .asMap()
          .entries
          .map((e) => '🎯 Alvo ${e.key + 1}: \$${e.value.toStringAsFixed(2)}')
          .join('\n');

      // Determinar emoji por tipo
      final typeEmoji = signal.type == SignalType.long ? '📈' : '📉';
      final typeName = signal.type == SignalType.long ? 'LONG (Compra)' : 'SHORT (Venda)';

      // Formatar confiança
      String confidenceLevel;
      String confidenceEmoji;
      if (signal.confidence >= 80) {
        confidenceLevel = 'Alta';
        confidenceEmoji = '🔥';
      } else if (signal.confidence >= 60) {
        confidenceLevel = 'Média';
        confidenceEmoji = '⚡';
      } else {
        confidenceLevel = 'Baixa';
        confidenceEmoji = '⚠️';
      }

      // Montar mensagem formatada
      final text = '''
━━━━━━━━━━━━━━━━━━━━
$typeEmoji SINAL DE TRADING
━━━━━━━━━━━━━━━━━━━━

💰 Moeda: ${signal.coin}
📊 Tipo: $typeName

💵 Entrada: \$${signal.entry.toStringAsFixed(2)}

$targetsText

🛑 Stop Loss: \$${signal.stopLoss.toStringAsFixed(2)}

$confidenceEmoji Confiança: $confidenceLevel (${signal.confidence}%)

━━━━━━━━━━━━━━━━━━━━
⚠️ AVISO: Este não é um conselho financeiro.
Opere por sua conta e risco.

📲 AlanoCryptoFX
━━━━━━━━━━━━━━━━━━━━
      '''.trim();

      await Clipboard.setData(ClipboardData(text: text));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sinal copiado! Cole em qualquer lugar.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao copiar sinal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao copiar sinal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.show_chart, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'Sinais',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _FilterChip(
                            label: 'Todos',
                            isSelected: _selectedFilter == null,
                            onTap: () {
                              setState(() {
                                _selectedFilter = null;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _FilterChip(
                            label: 'LONG',
                            isSelected: _selectedFilter == SignalType.long,
                            color: const Color(0xFF4CAF50),
                            onTap: () {
                              setState(() {
                                _selectedFilter = SignalType.long;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _FilterChip(
                            label: 'SHORT',
                            isSelected: _selectedFilter == SignalType.short,
                            color: const Color(0xFFF44336),
                            onTap: () {
                              setState(() {
                                _selectedFilter = SignalType.short;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Ativos'),
                      Tab(text: 'Histórico'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SignalsTab(
                  stream: _signalService.getActiveSignals(filter: _selectedFilter),
                  emptyMessage: 'Nenhum sinal ativo',
                  onCopy: _copySignal,
                  formatTimestamp: _formatTimestamp,
                ),
                _SignalsTab(
                  stream: _signalService.getCompletedSignals(filter: _selectedFilter),
                  emptyMessage: 'Nenhum sinal finalizado',
                  onCopy: _copySignal,
                  formatTimestamp: _formatTimestamp,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipColor = color ?? Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withAlpha(26)
              : (isDark ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? chipColor : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _SignalsTab extends StatelessWidget {
  final Stream<List<Signal>> stream;
  final String emptyMessage;
  final Function(Signal) onCopy;
  final String Function(DateTime) formatTimestamp;

  const _SignalsTab({
    required this.stream,
    required this.emptyMessage,
    required this.onCopy,
    required this.formatTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Signal>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          final errorMessage = snapshot.error.toString();
          
          if (errorMessage.contains('index') || 
              errorMessage.contains('FAILED_PRECONDITION')) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.build_circle_outlined,
                      size: 64,
                      color: Colors.orange[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Índice do banco de dados em construção',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aguarde alguns minutos e tente novamente',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignalsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Erro ao carregar sinais',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }

        final signals = snapshot.data ?? [];

        if (signals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.show_chart_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {},
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: signals.length,
            itemBuilder: (context, index) {
              return SignalCard(
                signal: signals[index],
                onCopy: onCopy,
                formatTimestamp: formatTimestamp,
              );
            },
          ),
        );
      },
    );
  }
}

class SignalCard extends StatelessWidget {
  final Signal signal;
  final Function(Signal) onCopy;
  final String Function(DateTime) formatTimestamp;

  const SignalCard({
    super.key,
    required this.signal,
    required this.onCopy,
    required this.formatTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: signal.typeColor.withAlpha(77),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: signal.typeColor.withAlpha(26),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: signal.typeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    signal.typeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    signal.coin,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: signal.statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    signal.statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _InfoRow(
                        icon: Icons.login,
                        label: 'Entrada',
                        value: '\$${signal.entry.toStringAsFixed(2)}',
                      ),
                    ),
                    Expanded(
                      child: _InfoRow(
                        icon: Icons.block,
                        label: 'Stop Loss',
                        value: '\$${signal.stopLoss.toStringAsFixed(2)}',
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.flag, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Alvos:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: signal.targets.asMap().entries.map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withAlpha(51)),
                      ),
                      child: Text(
                        'T${entry.key + 1}: \$${entry.value.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.speed, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Confiança: ${signal.confidence}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatTimestamp(signal.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (signal.profit != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (signal.profit! >= 0 ? Colors.green : Colors.red)
                          .withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          signal.profit! >= 0 ? Icons.trending_up : Icons.trending_down,
                          color: signal.profit! >= 0 ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lucro: ${signal.profit!.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: signal.profit! >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onCopy(signal),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.copy,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Copiar Sinal',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[600]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
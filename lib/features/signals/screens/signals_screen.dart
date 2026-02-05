import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../models/signal_model.dart';
import '../../../services/signal_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shimmer_loading.dart';

class SignalsScreen extends StatefulWidget {
  const SignalsScreen({super.key});

  @override
  State<SignalsScreen> createState() => _SignalsScreenState();
}

class _SignalsScreenState extends State<SignalsScreen> {
  final SignalService _signalService = SignalService();
  SignalType? _selectedFilter;
  late Timer _refreshTimer;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) {
        setState(() {
          _refreshKey++;
        });
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  Future<void> _copySignal(Signal signal) async {
    try {
      final isLong = signal.type == SignalType.long;
      final typeEmoji = isLong ? '🟢' : '🔴';
      final typeName = isLong ? 'COMPRA' : 'VENDA';

      final strategyLine = signal.strategy != 'Não especificado'
          ? '📈 Estratégia: ${signal.strategy}'
          : '📈 Estratégia: Análise técnica';

      final rsiLine = signal.rsiValue != 'N/A'
          ? '🥇 Entrada Nível 1   ( RSI Atual: ${signal.rsiValue} )'
          : '🥇 Entrada Nível 1';

      final timeframeLine = signal.timeframe != 'N/A'
          ? '⏰ Timeframe: ${signal.timeframe}'
          : '⏰ Timeframe: Intraday';

      final alertMessage = isLong
          ? '⚡️ Sinal detectado! O RSI indica sobrevenda, oportunidade de entrada inicial.'
          : '⚡️ Sinal detectado! O RSI indica sobrecompra, oportunidade de entrada inicial.';

      final text = '''
🚨 Alerta de Oportunidade! 🚨

🔥 Análises do Alano Crypto
🎯 Acabamos de receber uma notificação

📍 Ativo: ${signal.formattedCoin}
$timeframeLine

$strategyLine
$rsiLine
💡 Tipo de operação: $typeEmoji $typeName
💵 Preço de entrada: ${signal.entry}

$alertMessage

🔥 Azulou, ganhou! Aproveite essa oportunidade no mercado.
💬 Qualquer dúvida, fale no grupo ou no suporte!
🟠 SUPORTE ALANO CRYPTO 🦎
https://bit.ly/suportealanocripto
      '''
              .trim();

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
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                ],
              ),
            ),
          ),
          Expanded(
            key: ValueKey(_refreshKey),
            child: _SignalsTab(
              stream: _signalService.getActiveSignals(
                filter: _selectedFilter,
              ),
              emptyMessage: 'Nenhum sinal ativo nos últimos 30 minutos',
              onCopy: _copySignal,
              formatTimestamp: _formatTimestamp,
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
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (context, index) => const SignalShimmer(),
          );
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
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Erro ao carregar sinais',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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

class SignalCard extends StatefulWidget {
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
  State<SignalCard> createState() => _SignalCardState();
}

class _SignalCardState extends State<SignalCard> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Widget _buildTimeRemaining() {
    final expiresAt = widget.signal.createdAt.add(const Duration(minutes: 30));
    final remaining = expiresAt.difference(DateTime.now());

    if (remaining.isNegative) return const SizedBox.shrink();

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    final isUrgent = minutes < 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isUrgent
            ? Colors.red.withValues(alpha: 0.2)
            : const Color(0xFF00FF88).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUrgent
              ? Colors.red.withValues(alpha: 0.5)
              : const Color(0xFF00FF88).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 14,
            color: isUrgent ? Colors.red : const Color(0xFF00FF88),
          ),
          const SizedBox(width: 4),
          Text(
            '${minutes}m ${seconds.toString().padLeft(2, '0')}s',
            style: TextStyle(
              color: isUrgent ? Colors.red : const Color(0xFF00FF88),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLong = widget.signal.type == SignalType.long;
    final signal = widget.signal;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.signalCard(isLong: isLong),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Borda colorida à esquerda
              Container(
                width: 4,
                color: isLong ? AppTheme.successGreen : AppTheme.errorRed,
              ),
              // Conteúdo principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: signal.typeColor.withAlpha(26),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
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
                              signal.formattedCoin,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
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
                    // Body
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (signal.strategy != 'Não especificado') ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(26),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.blue.withAlpha(51),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.lightbulb_outline,
                                    size: 18,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Estratégia',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          signal.strategy,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          _InfoRow(
                            icon: Icons.login,
                            label: 'Entrada',
                            value: '\$${signal.entry}',
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (signal.rsiValue != 'N/A')
                                Expanded(
                                  child: _InfoRow(
                                    icon: Icons.show_chart,
                                    label: 'RSI Atual',
                                    value: signal.rsiValue,
                                    color: Colors.orange,
                                  ),
                                ),
                              if (signal.timeframe != 'N/A')
                                Expanded(
                                  child: _InfoRow(
                                    icon: Icons.access_time,
                                    label: 'Timeframe',
                                    value: signal.timeframe,
                                    color: Colors.purple,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                signal.confidenceEmoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Confiança: ${signal.confidenceLabel}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const Spacer(),
                              _buildTimeRemaining(),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.formatTimestamp(signal.createdAt),
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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
                                    signal.profit! >= 0
                                        ? Icons.trending_up
                                        : Icons.trending_down,
                                    color: signal.profit! >= 0
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Lucro: ${signal.profit!.toStringAsFixed(2)}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: signal.profit! >= 0
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Footer
                    InkWell(
                      onTap: () => widget.onCopy(signal),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.copy,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Copiar Sinal',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
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
              ),
            ],
          ),
        ),
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
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ],
    );
  }
}

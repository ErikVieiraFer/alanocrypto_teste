import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../models/signal_model.dart';
import '../../../services/signal_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shimmer_loading.dart';
import '../widgets/cupula_widgets.dart';

const Color _kNeonGreen = Color(0xFF00FF88);

class CupulaSignalsPreview extends StatefulWidget {
  const CupulaSignalsPreview({super.key});

  @override
  State<CupulaSignalsPreview> createState() => _CupulaSignalsPreviewState();
}

class _CupulaSignalsPreviewState extends State<CupulaSignalsPreview>
    with SingleTickerProviderStateMixin {
  final SignalService _signalService = SignalService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Sinal copiado! Cole em qualquer lugar.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: _kNeonGreen.withValues(alpha: 0.9),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao copiar sinal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _SignalsTab(
                stream: _signalService.getActiveSignals(),
                emptyMessage: 'Nenhum sinal premium disponível',
                onCopy: _copySignal,
                formatTimestamp: _formatTimestamp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.cardDark,
            AppTheme.backgroundColor,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _kNeonGreen.withValues(alpha: 0.3),
                          _kNeonGreen.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _kNeonGreen.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.show_chart_rounded,
                      color: _kNeonGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sinais Premium',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Operações exclusivas da Cúpula',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatsChip(),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsChip() {
    return StreamBuilder<List<Signal>>(
      stream: _signalService.getActiveSignals(),
      builder: (context, snapshot) {
        final total = snapshot.data?.length ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _kNeonGreen.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _kNeonGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: _kNeonGreen,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                '$total ativos',
                style: const TextStyle(
                  color: _kNeonGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
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
            return _buildErrorState(
              context,
              icon: Icons.build_circle_outlined,
              iconColor: Colors.orange,
              title: 'Índice do banco de dados em construção',
              subtitle: 'Aguarde alguns minutos e tente novamente',
              showRetry: true,
            );
          }

          return _buildErrorState(
            context,
            icon: Icons.error_outline,
            iconColor: Colors.red,
            title: 'Erro ao carregar sinais',
            subtitle: errorMessage,
            showRetry: false,
          );
        }

        final signals = snapshot.data ?? [];

        if (signals.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          color: _kNeonGreen,
          onRefresh: () async {},
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: signals.length,
            itemBuilder: (context, index) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 50)),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: SignalCard(
                  signal: signals[index],
                  onCopy: onCopy,
                  formatTimestamp: formatTimestamp,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _kNeonGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.show_chart_rounded,
              size: 48,
              color: _kNeonGreen.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            emptyMessage,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Novos sinais serão postados em breve',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool showRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: iconColor),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (showRetry) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CupulaSignalsPreview(),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar Novamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kNeonGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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
    final isLong = signal.type == SignalType.long;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isLong ? AppTheme.successGreen : AppTheme.errorRed).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: (isLong ? AppTheme.successGreen : AppTheme.errorRed).withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      isLong ? AppTheme.successGreen : AppTheme.errorRed,
                      (isLong ? AppTheme.successGreen : AppTheme.errorRed).withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardHeader(isLong),
                    _buildCardBody(),
                    _buildCardFooter(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(bool isLong) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            signal.typeColor.withValues(alpha: 0.15),
            signal.typeColor.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  signal.typeColor,
                  signal.typeColor.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: signal.typeColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLong ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  signal.typeLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              signal.formattedCoin,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const PremiumBadge(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: signal.statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: signal.statusColor.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              signal.statusLabel,
              style: TextStyle(
                color: signal.statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBody() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (signal.strategy != 'Não especificado') ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estratégia',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          signal.strategy,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          _InfoRow(
            icon: Icons.login_rounded,
            label: 'Entrada',
            value: '\$${signal.entry}',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (signal.rsiValue != 'N/A')
                Expanded(
                  child: _InfoRow(
                    icon: Icons.show_chart_rounded,
                    label: 'RSI Atual',
                    value: signal.rsiValue,
                    color: Colors.orange,
                  ),
                ),
              if (signal.timeframe != 'N/A')
                Expanded(
                  child: _InfoRow(
                    icon: Icons.access_time_rounded,
                    label: 'Timeframe',
                    value: signal.timeframe,
                    color: Colors.purple,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
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
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: AppTheme.textSecondary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  formatTimestamp(signal.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          if (signal.profit != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (signal.profit! >= 0 ? Colors.green : Colors.red)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (signal.profit! >= 0 ? Colors.green : Colors.red)
                      .withValues(alpha: 0.3),
                ),
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
    );
  }

  Widget _buildCardFooter(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onCopy(signal),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _kNeonGreen.withValues(alpha: 0.15),
                _kNeonGreen.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.copy_rounded,
                    color: _kNeonGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Copiar Sinal',
                    style: TextStyle(
                      color: _kNeonGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
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
    final effectiveColor = color ?? _kNeonGreen;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: effectiveColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: effectiveColor),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary.withValues(alpha: 0.8),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: effectiveColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

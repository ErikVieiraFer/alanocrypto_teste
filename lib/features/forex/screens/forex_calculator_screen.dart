import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../services/forex_calculator_service.dart';
import '../../../theme/app_theme.dart';

class ForexCalculatorScreen extends StatefulWidget {
  const ForexCalculatorScreen({super.key});

  @override
  State<ForexCalculatorScreen> createState() => _ForexCalculatorScreenState();
}

class _ForexCalculatorScreenState extends State<ForexCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _balanceController = TextEditingController();
  final _riskController = TextEditingController();
  final _stopController = TextEditingController();

  String? _selectedPair;
  String _selectedLeverage = '1:100';
  bool _showResult = false;
  Map<String, dynamic>? _result;

  final List<String> _pairs = [
    'EUR/USD',
    'GBP/USD',
    'USD/JPY',
    'AUD/USD',
    'USD/CAD',
    'NZD/USD',
    'EUR/GBP',
    'EUR/JPY',
    'GBP/JPY',
  ];

  final List<String> _leverages = [
    '1:1',
    '1:10',
    '1:20',
    '1:30',
    '1:50',
    '1:100',
    '1:200',
    '1:500',
  ];

  @override
  void dispose() {
    _priceController.dispose();
    _balanceController.dispose();
    _riskController.dispose();
    _stopController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (_showResult) {
      setState(() {
        _showResult = false;
        _result = null;
      });
    }
  }

  void _calculate() {
    if (_formKey.currentState!.validate()) {
      final leverageValue = int.parse(_selectedLeverage.split(':')[1]);
      final result = ForexCalculatorService.calculate(
        pair: _selectedPair!,
        currentPrice: double.parse(_priceController.text),
        accountBalance: double.parse(_balanceController.text),
        riskPercentage: double.parse(_riskController.text),
        stopPips: double.parse(_stopController.text),
        leverage: leverageValue,
      );

      setState(() {
        _result = result;
        _showResult = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.paddingLarge),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.calculate_rounded,
              size: 80,
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(height: AppTheme.gapLarge),
            Text(
              'Calculadora Forex',
              textAlign: TextAlign.center,
              style: AppTheme.heading2,
            ),
            const SizedBox(height: AppTheme.paddingXLarge),
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingLarge),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: AppTheme.largeRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📊 Parâmetros de Trading',
                    style: AppTheme.heading3,
                  ),
                  const SizedBox(height: AppTheme.gapSmall),
                  Text(
                    'Configure os parâmetros para calcular o tamanho da posição',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.gapXLarge),
                  DropdownButtonFormField<String>(
                    value: _selectedPair,
                    decoration: AppTheme.inputDecoration('Par (símbolo)'),
                    dropdownColor: AppTheme.cardMedium,
                    style: AppTheme.bodyMedium,
                    hint: Text(
                      'Selecione o par de moedas',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    items: _pairs.map((pair) {
                      return DropdownMenuItem(
                        value: pair,
                        child: Text(pair),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPair = value;
                      });
                      _onFieldChanged();
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Selecione um par de moedas';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.gapLarge),
                  TextFormField(
                    controller: _priceController,
                    decoration: AppTheme.inputDecoration('Preço atual'),
                    style: AppTheme.bodyMedium,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (_) => _onFieldChanged(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite o preço atual';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price <= 0) {
                        return 'Preço deve ser maior que 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.gapLarge),
                  TextFormField(
                    controller: _balanceController,
                    decoration: AppTheme.inputDecoration('Saldo da conta (USD)'),
                    style: AppTheme.bodyMedium,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (_) => _onFieldChanged(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite o saldo da conta';
                      }
                      final balance = double.tryParse(value);
                      if (balance == null || balance <= 0) {
                        return 'Saldo deve ser maior que 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.gapLarge),
                  TextFormField(
                    controller: _riskController,
                    decoration: AppTheme.inputDecoration('Risco por operação (%)'),
                    style: AppTheme.bodyMedium,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (_) => _onFieldChanged(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite o percentual de risco';
                      }
                      final risk = double.tryParse(value);
                      if (risk == null || risk <= 0 || risk > 100) {
                        return 'Risco deve estar entre 0 e 100';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.gapLarge),
                  TextFormField(
                    controller: _stopController,
                    decoration: AppTheme.inputDecoration('Stop (pips)'),
                    style: AppTheme.bodyMedium,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (_) => _onFieldChanged(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite o stop em pips';
                      }
                      final stop = double.tryParse(value);
                      if (stop == null || stop <= 0) {
                        return 'Stop deve ser maior que 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.gapLarge),
                  DropdownButtonFormField<String>(
                    value: _selectedLeverage,
                    decoration: AppTheme.inputDecoration('Alavancagem'),
                    dropdownColor: AppTheme.cardMedium,
                    style: AppTheme.bodyMedium,
                    items: _leverages.map((leverage) {
                      return DropdownMenuItem(
                        value: leverage,
                        child: Text(leverage),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLeverage = value!;
                      });
                      _onFieldChanged();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.gapXLarge),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate),
                label: Text(
                  'Calcular',
                  style: AppTheme.buttonText,
                ),
                style: AppTheme.primaryButton,
              ),
            ),
            if (_showResult && _result != null) ...[
              const SizedBox(height: AppTheme.gapXLarge),
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingLarge),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: AppTheme.largeRadius,
                  border: Border.all(
                    color: AppTheme.primaryGreen,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💰 Resultado do Cálculo',
                      style: AppTheme.heading3,
                    ),
                    const SizedBox(height: AppTheme.gapXLarge),
                    _buildResultRow(
                      'Tamanho da posição',
                      '${_result!['positionSizeLots'].toStringAsFixed(2)} lotes',
                      AppTheme.primaryGreen,
                    ),
                    const SizedBox(height: AppTheme.gapLarge),
                    _buildResultRow(
                      'Tamanho da posição (unidades)',
                      NumberFormat('#,###').format(_result!['positionSizeUnits'].toInt()),
                      AppTheme.warningOrange,
                    ),
                    const SizedBox(height: AppTheme.gapLarge),
                    _buildResultRow(
                      'Valor do pip',
                      '\$ ${_result!['pipValue'].toStringAsFixed(2)}',
                      AppTheme.textPrimary,
                    ),
                    const SizedBox(height: AppTheme.gapLarge),
                    _buildResultRow(
                      'Risco em dólar',
                      '\$ ${_result!['riskDollar'].toStringAsFixed(2)}',
                      AppTheme.textPrimary,
                    ),
                    const SizedBox(height: AppTheme.gapLarge),
                    _buildResultRow(
                      'Margem necessária ($_selectedLeverage)',
                      '\$ ${_result!['marginRequired'].toStringAsFixed(2)}',
                      AppTheme.textPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.heading3.copyWith(
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

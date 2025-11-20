import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditTransactionDialog extends StatefulWidget {
  final String transactionId;
  final Map<String, dynamic> transactionData;

  const EditTransactionDialog({
    super.key,
    required this.transactionId,
    required this.transactionData,
  });

  @override
  State<EditTransactionDialog> createState() => _EditTransactionDialogState();
}

class _EditTransactionDialogState extends State<EditTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _transactionType;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _feesController;
  late TextEditingController _observationsController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _transactionType = widget.transactionData['transactionType'] ?? 'Compra';
    _quantityController = TextEditingController(
      text: widget.transactionData['quantity']?.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: widget.transactionData['price']?.toString() ?? '',
    );
    _feesController = TextEditingController(
      text: widget.transactionData['fees']?.toString() ?? '',
    );
    _observationsController = TextEditingController(
      text: widget.transactionData['observations'] ?? '',
    );
    _selectedDate = (widget.transactionData['date'] as Timestamp).toDate();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _feesController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final quantity = double.parse(_quantityController.text);
      final price = double.parse(_priceController.text);
      final fees = _feesController.text.isNotEmpty ? double.parse(_feesController.text) : 0.0;
      final total = (quantity * price) + fees;

      await FirebaseFirestore.instance
          .collection('portfolio_transactions')
          .doc(widget.transactionId)
          .update({
        'transactionType': _transactionType,
        'quantity': quantity,
        'price': price,
        'fees': fees,
        'total': total,
        'observations': _observationsController.text.trim(),
        'date': Timestamp.fromDate(_selectedDate),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transação atualizada com sucesso!'),
            backgroundColor: Color(0xFF00FF88),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final symbol = widget.transactionData['symbol'] ?? '';
    final name = widget.transactionData['name'] ?? '';

    return Dialog(
      backgroundColor: const Color(0xFF1a1f26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Editar Transação',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$symbol - $name',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF00FF88),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Text(
                  'Tipo de Transação',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _transactionType,
                  dropdownColor: const Color(0xFF2a2f36),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF2a2f36),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  items: ['Compra', 'Venda'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _transactionType = newValue;
                      });
                    }
                  },
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quantidade',
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _quantityController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF2a2f36),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Obrigatório';
                              if (double.tryParse(value) == null) return 'Inválido';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Preço (USD)',
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF2a2f36),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Obrigatório';
                              if (double.tryParse(value) == null) return 'Inválido';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Taxas (opcional)',
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _feesController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF2a2f36),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data',
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.dark().copyWith(
                                      colorScheme: const ColorScheme.dark(
                                        primary: Color(0xFF00FF88),
                                        surface: Color(0xFF1a1f26),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (date != null) {
                                setState(() {
                                  _selectedDate = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    _selectedDate.hour,
                                    _selectedDate.minute,
                                  );
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2a2f36),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Text(
                  'Observações (opcional)',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _observationsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF2a2f36),
                    hintText: 'Adicione observações...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _saveChanges,
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('Salvar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF88),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
        ),
      ),
    );
  }
}

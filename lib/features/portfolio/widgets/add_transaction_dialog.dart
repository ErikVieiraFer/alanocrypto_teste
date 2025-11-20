import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/asset_search_service.dart';

class AddTransactionDialog extends StatefulWidget {
  const AddTransactionDialog({super.key});

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _assetSearchService = AssetSearchService();

  String _assetType = 'Criptomoedas';
  String _transactionType = 'Compra';
  final _symbolController = TextEditingController();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _feesController = TextEditingController();
  final _observationsController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  List<SearchableAsset> _searchResults = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  SearchableAsset? _selectedAsset;

  @override
  void initState() {
    super.initState();
    _loadInitialAssets();
  }

  Future<void> _loadInitialAssets() async {
    final assets = await _assetSearchService.searchAssets('', _assetType);
    if (mounted) {
      setState(() {
        _searchResults = assets;
      });
    }
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _feesController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  Future<void> _searchAssets(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _assetSearchService.searchAssets(query, _assetType);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _selectAsset(SearchableAsset asset) {
    setState(() {
      _selectedAsset = asset;
      _symbolController.text = asset.symbol;
      _nameController.text = asset.name;
      _showSuggestions = false;
    });
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final quantity = double.parse(_quantityController.text);
      final price = double.parse(_priceController.text);
      final fees = _feesController.text.isNotEmpty ? double.parse(_feesController.text) : 0.0;
      final total = (quantity * price) + fees;

      await FirebaseFirestore.instance.collection('portfolio_transactions').add({
        'userId': user.uid,
        'assetType': _assetType,
        'symbol': _symbolController.text.trim().toUpperCase(),
        'name': _nameController.text.trim(),
        'transactionType': _transactionType,
        'quantity': quantity,
        'price': price,
        'fees': fees,
        'total': total,
        'observations': _observationsController.text.trim(),
        'date': Timestamp.fromDate(_selectedDate),
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transação adicionada com sucesso!'),
            backgroundColor: Color(0xFF00FF88),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar transação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1a1f26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
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
                    const Text(
                      'Adicionar Transação',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Text(
                  'Tipo de Ativo',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _assetType,
                  dropdownColor: const Color(0xFF2a2f36),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF2a2f36),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF00FF88), width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF00FF88), width: 2),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  items: ['Criptomoedas', 'Ações', 'Forex'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _assetType = newValue;
                        _symbolController.clear();
                        _nameController.clear();
                        _selectedAsset = null;
                      });
                      _loadInitialAssets();
                    }
                  },
                ),

                const SizedBox(height: 16),
                const Text(
                  'Buscar Ativo',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
                const SizedBox(height: 8),

                // Campo de busca com autocomplete
                Column(
                  children: [
                    TextFormField(
                      controller: _symbolController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF2a2f36),
                        hintText: 'Digite o nome ou símbolo (ex: Bitcoin, BTC)',
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF00FF88),
                                  ),
                                ),
                              )
                            : _selectedAsset != null
                                ? IconButton(
                                    icon: const Icon(Icons.check_circle, color: Color(0xFF00FF88)),
                                    onPressed: null,
                                  )
                                : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) {
                        _searchAssets(value);
                        setState(() {
                          _showSuggestions = true;
                          _selectedAsset = null;
                        });
                      },
                      onTap: () {
                        setState(() {
                          _showSuggestions = true;
                        });
                      },
                      validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                    ),

                    // Lista de sugestões
                    if (_showSuggestions && _searchResults.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2a2f36),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF3a3f46)),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final asset = _searchResults[index];
                            return InkWell(
                              onTap: () => _selectAsset(asset),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  border: index < _searchResults.length - 1
                                      ? const Border(bottom: BorderSide(color: Color(0xFF3a3f46)))
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    if (asset.imageUrl != null)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: Image.network(
                                            asset.imageUrl!,
                                            width: 24,
                                            height: 24,
                                            errorBuilder: (_, __, ___) => const Icon(
                                              Icons.monetization_on,
                                              size: 24,
                                              color: Color(0xFF00FF88),
                                            ),
                                          ),
                                        ),
                                      ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            asset.symbol,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            asset.name,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (asset.currentPrice != null)
                                      Text(
                                        '\$${asset.currentPrice!.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Color(0xFF00FF88),
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),

                if (_selectedAsset != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF88).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF00FF88).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF00FF88), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_selectedAsset!.symbol} - ${_selectedAsset!.name}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                          onPressed: () {
                            setState(() {
                              _selectedAsset = null;
                              _symbolController.clear();
                              _nameController.clear();
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
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
                              hintText: '0.00',
                              hintStyle: const TextStyle(color: Colors.grey),
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
                              hintText: '0.00',
                              hintStyle: const TextStyle(color: Colors.grey),
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
                              hintText: '0.00',
                              hintStyle: const TextStyle(color: Colors.grey),
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
                              if (date != null && mounted) {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(_selectedDate),
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
                                if (time != null) {
                                  setState(() {
                                    _selectedDate = DateTime(
                                      date.year,
                                      date.month,
                                      date.day,
                                      time.hour,
                                      time.minute,
                                    );
                                  });
                                }
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
                                    '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
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
                    hintText: 'Adicione observações sobre esta transação...',
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
                      onPressed: _saveTransaction,
                      icon: const Icon(Icons.add, size: 18),
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

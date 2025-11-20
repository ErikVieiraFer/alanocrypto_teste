import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';

class ManagementScreen extends StatefulWidget {
  const ManagementScreen({Key? key}) : super(key: key);

  @override
  State<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  DateTime _filterStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _filterEndDate = DateTime.now();

  final _gainsController = TextEditingController();
  final _lossesController = TextEditingController();
  final _observationsController = TextEditingController();

  String _selectedSession = '';
  bool _morningChecked = false;
  bool _afternoonChecked = false;
  bool _nightChecked = false;

  double _calculatePnL() {
    final gains = double.tryParse(_gainsController.text) ?? 0;
    final losses = double.tryParse(_lossesController.text) ?? 0;
    return gains - losses;
  }

  @override
  void dispose() {
    _gainsController.dispose();
    _lossesController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  Future<void> _saveDailyRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final sessions = <String>[];
    if (_morningChecked) sessions.add('Manhã');
    if (_afternoonChecked) sessions.add('Tarde');
    if (_nightChecked) sessions.add('Noite');

    try {
      await FirebaseFirestore.instance.collection('daily_records').add({
        'userId': user.uid,
        'date': Timestamp.fromDate(_selectedDate),
        'gains': double.parse(_gainsController.text),
        'losses': double.parse(_lossesController.text),
        'pnl': _calculatePnL(),
        'sessions': sessions,
        'observations': _observationsController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      _gainsController.clear();
      _lossesController.clear();
      _observationsController.clear();
      setState(() {
        _morningChecked = false;
        _afternoonChecked = false;
        _nightChecked = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro salvo com sucesso!'),
            backgroundColor: Color(0xFF00FF88),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar registro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteRecord(String docId, DateTime date) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1f26),
        title: const Text(
          'Excluir registro?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Deseja excluir o registro do dia ${DateFormat('dd/MM/yyyy').format(date)}?\n\nEsta ação não pode ser desfeita.',
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
      try {
        await FirebaseFirestore.instance
            .collection('daily_records')
            .doc(docId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registro excluído com sucesso!'),
              backgroundColor: Color(0xFF00FF88),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showEditDialog(String docId, Map<String, dynamic> data) {
    final gainsController = TextEditingController(text: data['gains']?.toString() ?? '');
    final lossesController = TextEditingController(text: data['losses']?.toString() ?? '');
    final obsController = TextEditingController(text: data['observations'] ?? '');

    final sessions = List<String>.from(data['sessions'] ?? []);
    bool morningChecked = sessions.contains('Manhã');
    bool afternoonChecked = sessions.contains('Tarde');
    bool nightChecked = sessions.contains('Noite');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1a1f26),
          title: const Text(
            'Editar Registro',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ganhos (USD)', style: TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: gainsController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF2a2f36),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Perdas (USD)', style: TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: lossesController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF2a2f36),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Sessões', style: TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: morningChecked,
                      onChanged: (v) => setDialogState(() => morningChecked = v!),
                      fillColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return const Color(0xFF00FF88);
                        }
                        return const Color(0xFF2a2f36);
                      }),
                    ),
                    const Text('Manhã', style: TextStyle(color: Colors.white)),
                    Checkbox(
                      value: afternoonChecked,
                      onChanged: (v) => setDialogState(() => afternoonChecked = v!),
                      fillColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return const Color(0xFF00FF88);
                        }
                        return const Color(0xFF2a2f36);
                      }),
                    ),
                    const Text('Tarde', style: TextStyle(color: Colors.white)),
                    Checkbox(
                      value: nightChecked,
                      onChanged: (v) => setDialogState(() => nightChecked = v!),
                      fillColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return const Color(0xFF00FF88);
                        }
                        return const Color(0xFF2a2f36);
                      }),
                    ),
                    const Text('Noite', style: TextStyle(color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Observações', style: TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: obsController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF2a2f36),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final newSessions = <String>[];
                  if (morningChecked) newSessions.add('Manhã');
                  if (afternoonChecked) newSessions.add('Tarde');
                  if (nightChecked) newSessions.add('Noite');

                  final gains = double.tryParse(gainsController.text) ?? 0;
                  final losses = double.tryParse(lossesController.text) ?? 0;

                  await FirebaseFirestore.instance
                      .collection('daily_records')
                      .doc(docId)
                      .update({
                    'gains': gains,
                    'losses': losses,
                    'pnl': gains - losses,
                    'sessions': newSessions,
                    'observations': obsController.text.trim(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Registro atualizado com sucesso!'),
                        backgroundColor: Color(0xFF00FF88),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao atualizar: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF88),
                foregroundColor: Colors.black,
              ),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1116),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gerenciamento',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Registre seus resultados diários e acompanhe suas metas',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1a1f26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.filter_list, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Filtros de Período',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () async {
                            final records = await FirebaseFirestore.instance
                                .collection('daily_records')
                                .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                                .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_filterStartDate))
                                .where('date', isLessThanOrEqualTo: Timestamp.fromDate(_filterEndDate))
                                .get();

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Exportando ${records.docs.length} registros...'),
                                  backgroundColor: const Color(0xFF00FF88),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('CSV'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final dateRange = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                initialDateRange: DateTimeRange(
                                  start: _filterStartDate,
                                  end: _filterEndDate,
                                ),
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

                              if (dateRange != null) {
                                setState(() {
                                  _filterStartDate = dateRange.start;
                                  _filterEndDate = dateRange.end;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2a2f36),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Colors.grey, size: 18),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${DateFormat('dd/MM/yyyy').format(_filterStartDate)} - ${DateFormat('dd/MM/yyyy').format(_filterEndDate)}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _filterStartDate = DateTime.now().subtract(const Duration(days: 30));
                              _filterEndDate = DateTime.now();
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: const Text(
                            'Limpar Filtros',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  _buildStatCard('', 'US\$ 0,00', '', flex: 1),
                  const SizedBox(width: 16),
                  _buildStatCard('', 'US\$ 0,00', '', flex: 1),
                  const SizedBox(width: 16),
                  _buildStatCard('', 'US\$ 0,00', '', flex: 1),
                  const SizedBox(width: 16),
                  _buildStatCard('', 'US\$ 0,00', '', flex: 1),
                ],
              ),

              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1a1f26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Registrar Dia',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                      firstDate: DateTime(2020),
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
                                        _selectedDate = date;
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

                          const SizedBox(width: 24),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PnL do Dia',
                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2a2f36),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'US\$ ${_calculatePnL().toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _calculatePnL() >= 0
                                          ? const Color(0xFF00FF88)
                                          : Colors.red,
                                    ),
                                  ),
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
                                  'Ganhos (USD)',
                                  style: TextStyle(fontSize: 14, color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _gainsController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFF2a2f36),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    hintText: '0',
                                    hintStyle: const TextStyle(color: Colors.grey),
                                  ),
                                  style: const TextStyle(color: Colors.white),
                                  onChanged: (_) => setState(() {}),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Campo obrigatório';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Valor inválido';
                                    }
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
                                  'Perdas (USD)',
                                  style: TextStyle(fontSize: 14, color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _lossesController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFF2a2f36),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    hintText: '0',
                                    hintStyle: const TextStyle(color: Colors.grey),
                                  ),
                                  style: const TextStyle(color: Colors.white),
                                  onChanged: (_) => setState(() {}),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Campo obrigatório';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Valor inválido';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Sessões de Trading',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildSessionCheckbox('Manhã', _morningChecked, (value) {
                            setState(() {
                              _morningChecked = value!;
                            });
                          }),
                          const SizedBox(width: 24),
                          _buildSessionCheckbox('Tarde', _afternoonChecked, (value) {
                            setState(() {
                              _afternoonChecked = value!;
                            });
                          }),
                          const SizedBox(width: 24),
                          _buildSessionCheckbox('Noite', _nightChecked, (value) {
                            setState(() {
                              _nightChecked = value!;
                            });
                          }),
                        ],
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Observações',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _observationsController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF2a2f36),
                          hintText: 'Como foi o dia de trading? Estratégias, emoções, lições aprendidas...',
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _saveDailyRecord,
                            icon: const Icon(Icons.save, size: 18),
                            label: const Text('Salvar Dia'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00FF88),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton.icon(
                            onPressed: () {
                              _gainsController.clear();
                              _lossesController.clear();
                              _observationsController.clear();
                              setState(() {
                                _morningChecked = false;
                                _afternoonChecked = false;
                                _nightChecked = false;
                                _selectedDate = DateTime.now();
                              });
                            },
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Cancelar'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Histórico Diário',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('daily_records')
                    .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print('Erro no histórico: ${snapshot.error}');
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1a1f26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 12),
                          const Text(
                            'Erro ao carregar histórico',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString().contains('index')
                                ? 'É necessário criar um índice no Firestore. Verifique o console.'
                                : 'Verifique sua conexão com a internet.',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
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

                  // Filtrar por data localmente
                  final filteredDocs = snapshot.data?.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final date = (data['date'] as Timestamp).toDate();
                    return date.isAfter(_filterStartDate.subtract(const Duration(days: 1))) &&
                           date.isBefore(_filterEndDate.add(const Duration(days: 1)));
                  }).toList() ?? [];

                  if (!snapshot.hasData || filteredDocs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1a1f26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Nenhum registro encontrado',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: filteredDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final date = (data['date'] as Timestamp).toDate();
                      final pnl = data['pnl'] as double;
                      final gains = data['gains'] as double;
                      final losses = data['losses'] as double;
                      final sessions = List<String>.from(data['sessions'] ?? []);
                      final observations = data['observations'] as String;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a1f26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('dd/MM/yyyy').format(date),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'US\$ ${pnl.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: pnl >= 0
                                            ? const Color(0xFF00FF88)
                                            : Colors.red,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF00FF88), size: 20),
                                      onPressed: () => _showEditDialog(doc.id, data),
                                      tooltip: 'Editar',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      onPressed: () => _deleteRecord(doc.id, date),
                                      tooltip: 'Excluir',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildHistoryItem('Ganhos', 'US\$ ${gains.toStringAsFixed(2)}', const Color(0xFF00FF88)),
                                const SizedBox(width: 24),
                                _buildHistoryItem('Perdas', 'US\$ ${losses.toStringAsFixed(2)}', Colors.red),
                              ],
                            ),
                            if (sessions.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                children: sessions.map((session) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2a2f36),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      session,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                            if (observations.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                observations,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String change, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1f26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (change.isNotEmpty)
              Text(
                change,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF00FF88),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCheckbox(String label, bool value, Function(bool?) onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            fillColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return const Color(0xFF00FF88);
              }
              return const Color(0xFF2a2f36);
            }),
            checkColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

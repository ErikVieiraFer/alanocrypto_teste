import 'package:flutter/material.dart';
import 'verify_users_collection.dart';
import 'update_chat_messages.dart';

/// 🚀 QUICK START - Executar todos os scripts de uma vez
///
/// COMO USAR:
/// 1. Adicionar FloatingActionButton temporário em qualquer tela
/// 2. Executar app
/// 3. Clicar no botão
/// 4. Deletar após usar

class QuickStartWidget extends StatefulWidget {
  const QuickStartWidget({super.key});

  @override
  State<QuickStartWidget> createState() => _QuickStartWidgetState();
}

class _QuickStartWidgetState extends State<QuickStartWidget> {
  String _status = 'Pronto para começar';
  bool _isRunning = false;
  final List<String> _logs = [];

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
      _status = message;
    });
  }

  Future<void> _runAll() async {
    setState(() {
      _isRunning = true;
      _logs.clear();
    });

    try {
      _addLog('🔍 Verificando usuários...');
      await verifyUsersCollection();

      _addLog('🔧 Corrigindo usuários...');
      await fixUsersCollection();

      _addLog('👤 Garantindo usuário atual...');
      await ensureCurrentUserExists();

      _addLog('💬 Atualizando mensagens...');
      await updateChatMessages();

      _addLog('✅ CONCLUÍDO!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tudo pronto! Verifique o console para detalhes.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _addLog('❌ Erro: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Start - Setup Chat'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🚀 Setup Completo do Chat',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Este botão vai:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text('• Verificar collection users'),
                    const Text('• Adicionar campos faltantes'),
                    const Text('• Garantir seu usuário existe'),
                    const Text('• Atualizar mensagens antigas'),
                    const SizedBox(height: 12),
                    const Text(
                      '⚠️ IMPORTANTE: Executar apenas UMA VEZ!',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isRunning ? null : _runAll,
              icon: _isRunning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isRunning ? 'Executando...' : 'EXECUTAR SETUP'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Status: $_status',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Log:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _logs.isEmpty
                    ? const Center(
                        child: Text(
                          'Clique no botão para começar',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(_logs[index]),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Verifique o console (terminal) para logs detalhados.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// EXEMPLO DE USO - FloatingActionButton
// ═══════════════════════════════════════════════════════════════════

/// Adicionar em qualquer tela (ex: dashboard_screen.dart):
///
/// ```dart
/// import '../scripts/QUICK_START.dart';
///
/// floatingActionButton: FloatingActionButton.extended(
///   onPressed: () {
///     Navigator.push(
///       context,
///       MaterialPageRoute(builder: (context) => QuickStartWidget()),
///     );
///   },
///   label: Text('Setup Chat'),
///   icon: Icon(Icons.settings),
/// ),
/// ```
///
/// Depois de executar UMA VEZ, remover o botão e deletar scripts.

// ═══════════════════════════════════════════════════════════════════
// OPÇÃO ALTERNATIVA - Botão direto (sem tela)
// ═══════════════════════════════════════════════════════════════════

Future<void> quickStartSetup(BuildContext context) async {
  // Mostrar loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Configurando chat...'),
              SizedBox(height: 8),
              Text(
                'Veja o console para detalhes',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  try {
    print('\n═══════════════════════════════════════════════════════');
    print('🚀 QUICK START - SETUP COMPLETO');
    print('═══════════════════════════════════════════════════════\n');

    await verifyUsersCollection();
    await fixUsersCollection();
    await ensureCurrentUserExists();
    await updateChatMessages();

    print('\n═══════════════════════════════════════════════════════');
    print('✅ SETUP CONCLUÍDO COM SUCESSO!');
    print('═══════════════════════════════════════════════════════\n');

    // Fechar loading
    if (context.mounted) Navigator.pop(context);

    // Mostrar sucesso
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Chat configurado! Verifique o console.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  } catch (e) {
    print('\n❌ ERRO NO SETUP: $e\n');

    // Fechar loading
    if (context.mounted) Navigator.pop(context);

    // Mostrar erro
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Usar assim:
///
/// ```dart
/// import '../scripts/QUICK_START.dart';
///
/// FloatingActionButton(
///   onPressed: () => quickStartSetup(context),
///   child: Icon(Icons.settings),
/// )
/// ```

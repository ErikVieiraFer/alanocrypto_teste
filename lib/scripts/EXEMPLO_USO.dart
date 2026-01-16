import 'package:flutter/material.dart';
import 'update_chat_messages.dart';

/// EXEMPLO DE USO DO SCRIPT
///
/// Copiar este código para onde você quiser executar o script.
/// Depois de executar UMA VEZ, deletar tudo.

// EXEMPLO 1: Botão flutuante
class ExemploComBotao extends StatelessWidget {
  const ExemploComBotao({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Atualizar Chat')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Clicar no botão abaixo para atualizar mensagens'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Mostrar loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  // Executar script
                  await updateChatMessages();

                  // Fechar loading
                  if (context.mounted) Navigator.pop(context);

                  // Mostrar sucesso
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Mensagens atualizadas com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
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
              },
              child: const Text('ATUALIZAR MENSAGENS'),
            ),
            const SizedBox(height: 20),
            const Text(
              'ATENÇÃO: Executar apenas UMA VEZ!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// EXEMPLO 2: Executar automaticamente (uma vez)
class ExemploAutomatico extends StatefulWidget {
  const ExemploAutomatico({super.key});

  @override
  State<ExemploAutomatico> createState() => _ExemploAutomaticoState();
}

class _ExemploAutomaticoState extends State<ExemploAutomatico> {
  bool _isUpdating = false;
  bool _isComplete = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _runUpdate();
  }

  Future<void> _runUpdate() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await updateChatMessages();
      setState(() {
        _isComplete = true;
        _isUpdating = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Atualização Automática')),
      body: Center(
        child: _isUpdating
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Atualizando mensagens...'),
                ],
              )
            : _isComplete
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 64),
                      SizedBox(height: 20),
                      Text('Atualização concluída!'),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 64),
                      const SizedBox(height: 20),
                      Text('Erro: $_error'),
                    ],
                  ),
      ),
    );
  }
}

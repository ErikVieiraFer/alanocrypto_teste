import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AIService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  final String _systemPrompt = '''
Você é um assistente especializado em trading e criptomoedas, com foco em análise técnica e fundamentalista.

Diretrizes:
- Seja objetivo e direto nas respostas
- Use linguagem profissional mas acessível
- Explique conceitos complexos de forma simples
- Sempre inclua disclaimer: suas respostas são educacionais e não constituem conselho financeiro
- Foque em análise técnica, padrões gráficos, indicadores e gestão de risco

Sempre termine respostas sobre operações com: "⚠️ Lembre-se: isso não é conselho financeiro. Sempre faça sua própria análise."
''';

  Future<String> sendMessage(
    String message,
    List<Map<String, String>> conversationHistory,
  ) async {
    await Future.delayed(Duration(seconds: 1));

    return '🤖 Chat com IA - Em Desenvolvimento\n\n'
        'Esta funcionalidade estará disponível em breve!\n\n'
        'Por enquanto, você pode:\n'
        '• Ver os posts da comunidade\n'
        '• Acessar os sinais de trading\n'
        '• Assistir os vídeos exclusivos do Alano\n\n'
        '⚠️ Aguarde atualizações!';
  }

  List<String> getSuggestedQuestions() {
    return [
      'Como identificar tendências de alta?',
      'O que é RSI e como usar?',
      'Explique suporte e resistência',
      'Como fazer gestão de risco?',
      'O que são stop loss e take profit?',
      'Diferença entre LONG e SHORT',
    ];
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}

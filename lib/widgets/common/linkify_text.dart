import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget que renderiza texto com links clicáveis
/// Detecta automaticamente URLs e as torna clicáveis
class LinkifyText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const LinkifyText({
    super.key,
    required this.text,
    this.style,
    this.linkStyle,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  static final RegExp _urlRegex = RegExp(
    r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
    caseSensitive: false,
  );

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Erro ao abrir URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = style ?? const TextStyle(
      color: Colors.white,
      fontSize: 14,
      height: 1.5,
    );

    final defaultLinkStyle = linkStyle ?? defaultStyle.copyWith(
      color: const Color(0xFF4A9EFF), // Azul para links
      decoration: TextDecoration.underline,
      decorationColor: const Color(0xFF4A9EFF),
    );

    final matches = _urlRegex.allMatches(text).toList();

    if (matches.isEmpty) {
      return Text(
        text,
        style: defaultStyle,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
    }

    final List<TextSpan> spans = [];
    int currentPosition = 0;

    for (final match in matches) {
      // Adiciona texto antes do link
      if (match.start > currentPosition) {
        spans.add(TextSpan(
          text: text.substring(currentPosition, match.start),
          style: defaultStyle,
        ));
      }

      // Adiciona o link
      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: defaultLinkStyle,
        recognizer: TapGestureRecognizer()..onTap = () => _launchUrl(url),
      ));

      currentPosition = match.end;
    }

    // Adiciona texto após o último link
    if (currentPosition < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentPosition),
        style: defaultStyle,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      textAlign: textAlign ?? TextAlign.start,
    );
  }
}

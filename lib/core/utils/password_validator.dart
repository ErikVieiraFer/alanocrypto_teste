/// Validador de senha forte para o aplicativo AlanoCryptoFX
///
/// Requisitos:
/// - Mínimo 8 caracteres
/// - 1 letra maiúscula (A-Z)
/// - 1 letra minúscula (a-z)
/// - 1 número (0-9)
/// - 1 símbolo (!@#$%^&*()_+-=[]{}|;:,.<>?)
class PasswordValidator {
  static const int minLength = 8;

  /// Verifica se a senha atende todos os requisitos
  static bool isValid(String password) {
    if (password.length < minLength) return false;

    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSymbol = password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]'));

    return hasUppercase && hasLowercase && hasDigit && hasSymbol;
  }

  /// Valida a senha e retorna mensagem de erro detalhada
  /// Retorna null se a senha for válida
  static String? validate(String? password) {
    if (password == null || password.isEmpty) {
      return 'Digite uma senha';
    }

    if (password.length < minLength) {
      return 'A senha deve ter no mínimo $minLength caracteres';
    }

    final errors = <String>[];

    if (!password.contains(RegExp(r'[A-Z]'))) {
      errors.add('letra maiúscula');
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      errors.add('letra minúscula');
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      errors.add('número');
    }
    if (!password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]'))) {
      errors.add('símbolo (!@#\$%...)');
    }

    if (errors.isNotEmpty) {
      return 'Falta: ${errors.join(', ')}';
    }

    return null;
  }

  /// Texto com os requisitos da senha para exibir ao usuário
  static String get requirements =>
      'Mínimo 8 caracteres: maiúscula, minúscula, número e símbolo';
}

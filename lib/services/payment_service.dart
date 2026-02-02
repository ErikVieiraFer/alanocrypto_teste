import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:universal_html/html.dart' as html;

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _createSubscriptionUrl =
      'https://us-central1-alanocryptofx-v2.cloudfunctions.net/createSubscription';

  Future<Map<String, dynamic>> createCheckout() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ PaymentService: Usuário não autenticado');
      throw Exception('Você precisa estar logado para assinar.');
    }

    debugPrint('💳 PaymentService: Criando checkout para ${user.uid}');

    try {
      final response = await http.post(
        Uri.parse(_createSubscriptionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': user.uid,
          'userEmail': user.email,
          'userName': user.displayName ?? 'Usuário',
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        debugPrint('✅ PaymentService: Checkout criado');
        return data;
      }

      debugPrint('❌ PaymentService: Erro ${response.statusCode}');
      debugPrint('📄 Body: ${response.body}');

      final errorCode = data['error'] as String?;
      final errorMessage = data['message'] as String?;

      if (errorCode == 'CONFIG_ERROR') {
        throw Exception('Serviço temporariamente indisponível. Tente novamente mais tarde.');
      } else if (errorCode == 'PAYMENT_ERROR') {
        throw Exception('Erro ao processar pagamento. Tente novamente.');
      } else if (errorCode == 'VALIDATION_ERROR') {
        throw Exception(errorMessage ?? 'Dados inválidos. Faça login novamente.');
      } else {
        throw Exception('Erro inesperado. Entre em contato com o suporte.');
      }
    } catch (e) {
      debugPrint('❌ PaymentService: Erro ao criar checkout: $e');
      if (e is Exception) rethrow;
      throw Exception('Erro de conexão. Verifique sua internet.');
    }
  }

  Future<void> openCheckout() async {
    final result = await createCheckout();

    final checkoutUrl = result['checkoutUrl'] as String?;

    if (checkoutUrl == null) {
      throw Exception('URL de pagamento não disponível.');
    }

    try {
      if (kIsWeb) {
        final userAgent = html.window.navigator.userAgent.toLowerCase();
        final isSafari = userAgent.contains('safari') &&
                         !userAgent.contains('chrome') &&
                         !userAgent.contains('crios');
        final isIOS = userAgent.contains('iphone') ||
                      userAgent.contains('ipad') ||
                      userAgent.contains('ipod');

        debugPrint('🌐 PaymentService: userAgent=$userAgent, isSafari=$isSafari, isIOS=$isIOS');

        if (isSafari || isIOS) {
          html.window.location.href = checkoutUrl;
        } else {
          html.window.open(checkoutUrl, '_blank');
        }
      } else {
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Não foi possível abrir o navegador.');
        }
      }
    } catch (e) {
      debugPrint('❌ PaymentService: Erro ao abrir URL: $e');
      if (e is Exception) rethrow;
      throw Exception('Erro ao abrir checkout.');
    }
  }

  Future<bool> checkPremiumStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ checkPremiumStatus: usuário não logado');
        return false;
      }

      debugPrint('🔍 checkPremiumStatus: verificando UID ${user.uid}');

      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();

      debugPrint('🔍 checkPremiumStatus: documento existe = ${doc.exists}');

      if (data == null) {
        debugPrint('❌ checkPremiumStatus: dados nulos');
        return false;
      }

      final isPremiumRaw = data['isPremium'];
      final premiumUntilRaw = data['premiumUntil'];

      debugPrint('🔍 checkPremiumStatus: isPremium = $isPremiumRaw (tipo: ${isPremiumRaw.runtimeType})');
      debugPrint('🔍 checkPremiumStatus: premiumUntil = $premiumUntilRaw (tipo: ${premiumUntilRaw?.runtimeType})');

      final isPremium = isPremiumRaw == true || isPremiumRaw == 'true';

      if (!isPremium) {
        debugPrint('❌ checkPremiumStatus: isPremium não é true');
        return false;
      }

      if (premiumUntilRaw == null) {
        debugPrint('✅ checkPremiumStatus: isPremium true, sem data de expiração - acesso liberado');
        return true;
      }

      DateTime expirationDate;
      if (premiumUntilRaw is Timestamp) {
        expirationDate = premiumUntilRaw.toDate();
      } else if (premiumUntilRaw is String) {
        expirationDate = DateTime.parse(premiumUntilRaw);
      } else {
        debugPrint('⚠️ checkPremiumStatus: tipo de premiumUntil desconhecido, assumindo válido');
        return true;
      }

      final now = DateTime.now();
      final isValid = expirationDate.isAfter(now);

      debugPrint('🔍 checkPremiumStatus: expiração = $expirationDate');
      debugPrint('🔍 checkPremiumStatus: agora = $now');
      debugPrint('🔍 checkPremiumStatus: ainda válido = $isValid');

      return isValid;
    } catch (e, stackTrace) {
      debugPrint('❌ checkPremiumStatus: erro $e');
      debugPrint('❌ checkPremiumStatus: stackTrace $stackTrace');
      return false;
    }
  }

  Stream<bool> premiumStatusStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
          final data = doc.data();
          if (data == null) return false;

          final isPremium = data['isPremium'] == true;
          final premiumUntil = data['premiumUntil'] as Timestamp?;

          if (!isPremium) return false;
          if (premiumUntil == null) return isPremium;

          return premiumUntil.toDate().isAfter(DateTime.now());
        });
  }

  Future<bool> isAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ isAdmin: usuário não logado');
        return false;
      }

      debugPrint('🔍 isAdmin: verificando UID ${user.uid}');

      final doc = await _firestore.collection('users').doc(user.uid).get();

      final data = doc.data();
      debugPrint('🔍 isAdmin: dados do usuário: $data');

      final isAdminValue = data?['isAdmin'];
      debugPrint('🔍 isAdmin: valor do campo isAdmin: $isAdminValue (tipo: ${isAdminValue.runtimeType})');

      final result = isAdminValue == true;
      debugPrint('🔍 isAdmin: resultado final: $result');

      return result;
    } catch (e) {
      debugPrint('❌ isAdmin: erro $e');
      return false;
    }
  }

  Future<bool> hasAccess() async {
    debugPrint('🏛️ ========================================');
    debugPrint('🏛️ hasAccess: INICIANDO VERIFICAÇÃO DE ACESSO');
    debugPrint('🏛️ ========================================');

    final isAdminResult = await isAdmin();
    debugPrint('🏛️ hasAccess: isAdmin = $isAdminResult');

    if (isAdminResult) {
      debugPrint('🏛️ ✅ hasAccess: ACESSO LIBERADO (admin)');
      return true;
    }

    final isPremiumResult = await checkPremiumStatus();
    debugPrint('🏛️ hasAccess: isPremium = $isPremiumResult');

    if (isPremiumResult) {
      debugPrint('🏛️ ✅ hasAccess: ACESSO LIBERADO (premium)');
      return true;
    }

    debugPrint('🏛️ ❌ hasAccess: ACESSO NEGADO');
    return false;
  }

  Stream<bool> accessStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
          final data = doc.data();
          if (data == null) return false;

          if (data['isAdmin'] == true) return true;

          final isPremium = data['isPremium'] == true;
          final premiumUntil = data['premiumUntil'] as Timestamp?;

          if (!isPremium) return false;
          if (premiumUntil == null) return isPremium;

          return premiumUntil.toDate().isAfter(DateTime.now());
        });
  }

  Future<Map<String, dynamic>?> getSubscriptionInfo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();

      if (data == null) return null;

      return {
        'isPremium': data['isPremium'] == true,
        'premiumUntil': (data['premiumUntil'] as Timestamp?)?.toDate(),
        'lastPaymentStatus': data['lastPaymentStatus'],
        'subscriptionActive': data['subscriptionActive'] == true,
      };
    } catch (e) {
      return null;
    }
  }
}

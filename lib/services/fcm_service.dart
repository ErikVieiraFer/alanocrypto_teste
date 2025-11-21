import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _vapidKey =
      'BATytYh7j6wG1t8FJ9cus4TxgCClYp_CV9hKdp9zHANa3DvqZWFbwWTZqnQ98GevzIVK2_qQiDIWVGfr8G4IHO0';

  Future<void> initialize() async {
    try {
      // Solicitar permissão
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ Permissão de notificação concedida');
        await _getAndSaveToken();
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('⚠️ Permissão provisória concedida');
        await _getAndSaveToken();
      } else {
        debugPrint('❌ Permissão de notificação negada');
      }

      // Configurar handlers de notificação
      _configureNotificationHandlers();
    } catch (e) {
      debugPrint('❌ Erro ao inicializar notificações FCM: $e');
    }
  }

  Future<void> _getAndSaveToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint(
          '⚠️ Usuário não autenticado, não é possível obter token FCM',
        );
        return;
      }

      String? token;

      if (kIsWeb) {
        // Web precisa da VAPID key
        if (_vapidKey == 'COLE_SUA_VAPID_KEY_AQUI') {
          debugPrint(
            '⚠️ VAPID key não configurada! Configure em fcm_service.dart',
          );
          return;
        }
        token = await _messaging.getToken(vapidKey: _vapidKey);
      } else {
        // Mobile
        token = await _messaging.getToken();
      }

      if (token != null) {
        debugPrint('📱 FCM Token obtido: ${token.substring(0, 20)}...');
        await _saveTokenToFirestore(token);
      } else {
        debugPrint('❌ Não foi possível obter o FCM token');
      }

      // Atualizar token se mudar
      _messaging.onTokenRefresh.listen(_saveTokenToFirestore);
    } catch (e) {
      debugPrint('❌ Erro ao obter token FCM: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'notificationsEnabled': true,
      });

      debugPrint('✅ Token FCM salvo no Firestore');
    } catch (e) {
      debugPrint('❌ Erro ao salvar token FCM no Firestore: $e');
    }
  }

  void _configureNotificationHandlers() {
    // Notificação recebida quando app está em foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📬 Notificação FCM recebida (foreground)');

      if (kIsWeb) {
        debugPrint('⚠️ Web: Service Worker já mostrou notificação, ignorando');
        return;
      }

      debugPrint('Título: ${message.notification?.title}');
      debugPrint('Corpo: ${message.notification?.body}');
      debugPrint('Data: ${message.data}');

      // Aqui você pode mostrar um snackbar ou dialog
      // Ex: _showNotificationDialog(message);
    });

    // Quando usuário clica na notificação (app estava em background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 Notificação FCM clicada');
      _handleNotificationClick(message);
    });

    // Verificar se app foi aberto por uma notificação
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('🚀 App aberto via notificação FCM');
        _handleNotificationClick(message);
      }
    });
  }

  void _handleNotificationClick(RemoteMessage message) {
    debugPrint('📲 Tratando clique em notificação: ${message.data}');

    final type = message.data['type'];
    final postId = message.data['postId'];
    final messageId = message.data['messageId'];

    switch (type) {
      case 'alano_post':
        debugPrint('📝 Abrir post do Alano: $postId');
        navigateToScreen(2); // Index 2 = AlanoPostsScreen
        // TODO: Navegar para tela de posts do Alano com ID específico
        break;

      case 'mention':
        debugPrint('💬 Abrir chat na mensagem: $messageId');
        navigateToScreen(1); // Index 1 = GroupChatScreen
        // TODO: Navegar para chat e focar na mensagem
        break;

      case 'signal':
        debugPrint('📊 Abrir tela de sinais');
        navigateToScreen(3); // Index 3 = SignalsScreen
        break;

      default:
        debugPrint('❓ Tipo desconhecido: $type');
        navigateToScreen(0); // Ir para home por padrão
    }
  }

  void navigateToScreen(int screenIndex) {
    // Usar um GlobalKey ou NavigatorState para navegar
    // Como FcmService é um singleton, precisamos de uma referência ao contexto
    // A melhor forma é através de um callback ou usando GetX/Provider

    // Por enquanto, vamos usar um approach simplificado com um callback
    if (_navigationCallback != null) {
      _navigationCallback!(screenIndex);
    } else {
      debugPrint('⚠️ Navigation callback não configurado');
    }
  }

  // Callback para navegação
  Function(int)? _navigationCallback;

  void setNavigationCallback(Function(int) callback) {
    _navigationCallback = callback;
  }

  Future<void> disableNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'notificationsEnabled': false,
      });

      debugPrint('🔕 Notificações FCM desabilitadas');
    } catch (e) {
      debugPrint('❌ Erro ao desabilitar notificações FCM: $e');
    }
  }

  Future<bool> areNotificationsEnabled() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint('❌ Erro ao verificar permissão de notificação: $e');
      return false;
    }
  }

  Future<String?> getToken() async {
    try {
      if (kIsWeb) {
        if (_vapidKey == 'COLE_SUA_VAPID_KEY_AQUI') {
          debugPrint('⚠️ VAPID key não configurada!');
          return null;
        }
        return await _messaging.getToken(vapidKey: _vapidKey);
      } else {
        return await _messaging.getToken();
      }
    } catch (e) {
      debugPrint('❌ Erro ao obter token FCM: $e');
      return null;
    }
  }
}

// Handler para notificações em background (top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📬 Notificação FCM recebida em background');
  debugPrint('Título: ${message.notification?.title}');
  debugPrint('Corpo: ${message.notification?.body}');
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'theme/app_theme.dart';
import 'features/auth/screens/landing_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
// import 'features/auth/screens/email_verification_screen.dart'; // DESABILITADO - Fluxo direto sem verificação
import 'features/auth/screens/pending_approval_screen.dart';
import 'features/dashboard/screen/dashboard_screen.dart';
import 'features/placeholder/under_development_screen.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/fcm_service.dart';
import 'package:alanoapp/firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Import condicional para Web
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html if (dart.library.io) '';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('📬 Notificação FCM recebida em background');
  debugPrint('Título: ${message.notification?.title}');
  debugPrint('Corpo: ${message.notification?.body}');
}

// Global key para navegação
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void _setupWebMessageListener() {
  if (kIsWeb) {
    debugPrint('🌐 Configurando listener de mensagens do Service Worker');

    html.window.addEventListener('message', (event) {
      final messageEvent = event as html.MessageEvent;
      final data = messageEvent.data;

      if (data is Map && data['type'] == 'NOTIFICATION_CLICK') {
        debugPrint('📱 Mensagem do SW recebida: ${data['notifType']}');
        _handleWebNotificationClick(data);
      }
    });
  }
}

void _handleWebNotificationClick(Map<dynamic, dynamic> data) {
  final notifType = data['notifType'];
  final notifData = data['data'] ?? {};

  debugPrint('🎯 Tipo de notificação: $notifType');
  debugPrint('📦 Dados: $notifData');

  // Delay para garantir que app esteja carregado
  Future.delayed(const Duration(milliseconds: 500), () {
    final context = navigatorKey.currentContext;
    if (context != null) {
      // Usar callback do FCM Service
      final postId = notifData['postId']?.toString();
      final messageId = notifData['messageId']?.toString();

      switch (notifType) {
        case 'alano_post':
          debugPrint('📝 Navegar para post do Alano: $postId');
          FcmService().navigateToScreen(2); // Index 2 = AlanoPostsScreen
          break;

        case 'mention':
          debugPrint('💬 Navegar para chat na mensagem: $messageId');
          FcmService().navigateToScreen(1); // Index 1 = GroupChatScreen
          break;

        default:
          debugPrint('❓ Tipo desconhecido: $notifType');
          FcmService().navigateToScreen(0); // Ir para home
      }
    } else {
      debugPrint('⚠️ Context não disponível para navegação');
    }
  });
}

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    final error = details.exception.toString();
    if (error.contains('JavaScriptObject') ||
        error.contains('_testException') ||
        error.contains('ArgumentError')) {
      debugPrint(
        'Suprimindo erro conhecido do FlutterFire: ${details.exception}',
      );
      return;
    }
    FlutterError.presentError(details);
  };

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        // Firebase App Check - opcional para debug
        if (!kIsWeb) {
          try {
            await FirebaseAppCheck.instance.activate(
              androidProvider: AndroidProvider.debug,
              appleProvider: AppleProvider.debug,
            );
            debugPrint('✅ Firebase App Check ativado');
          } catch (e) {
            debugPrint('⚠️ Firebase App Check não ativado (modo debug): $e');
            // Continuar sem App Check em desenvolvimento
          }
        }

        if (!kIsWeb) {
          FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler,
          );
        }
      } catch (e) {
        if (!e.toString().contains('duplicate-app')) {
          rethrow;
        }
      }

      timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());

      // Configurar listener de mensagens web
      if (kIsWeb) {
        _setupWebMessageListener();
      }

      runApp(const MyApp());
    },
    (error, stack) {
      if (error.toString().contains('JavaScriptObject') ||
          error.toString().contains('_testException') ||
          error.toString().contains('ArgumentError')) {
        debugPrint(
          'Suprimindo erro assíncrono conhecido do FlutterFire: $error',
        );
        return;
      }
      debugPrint('Erro não tratado: $error');
      debugPrint('Stack trace: $stack');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF0f0f0f),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'AlanoCryptoFX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      themeMode: ThemeMode.dark,
      navigatorKey: navigatorKey,
      home: const AuthWrapper(),
      routes: {
        '/landing': (context) => const LandingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        // '/email-verification': (context) {
        //   final args = ModalRoute.of(context)!.settings.arguments as Map;
        //   return EmailVerificationScreen(
        //     email: args['email'],
        //     displayName: args['displayName'],
        //   );
        // }, // DESABILITADO - Fluxo direto sem verificação
        '/pending-approval': (context) => const PendingApprovalScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/under-development': (context) {
          final pageName =
              ModalRoute.of(context)?.settings.arguments as String? ?? 'Página';
          return UnderDevelopmentScreen(pageName: pageName);
        },
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _fcmInitialized = false;

  Future<void> _initializeFcm() async {
    if (!_fcmInitialized) {
      try {
        await FcmService().initialize();
        _fcmInitialized = true;
        debugPrint('✅ FCM Service inicializado no AuthWrapper');
      } catch (e) {
        debugPrint('❌ Erro ao inicializar FCM Service: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final userService = UserService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            body: const Center(
              child: CircularProgressIndicator(color: AppTheme.accentGreen),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<bool>(
            future: userService.isUserApproved(snapshot.data!.uid),
            builder: (context, approvalSnapshot) {
              if (approvalSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  backgroundColor: AppTheme.backgroundColor,
                  body: const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.accentGreen,
                    ),
                  ),
                );
              }

              if (approvalSnapshot.hasData && approvalSnapshot.data == true) {
                // Inicializar FCM após login e aprovação
                _initializeFcm();
                return const DashboardScreen();
              }

              return const PendingApprovalScreen();
            },
          );
        }

        return const LandingScreen();
      },
    );
  }
}

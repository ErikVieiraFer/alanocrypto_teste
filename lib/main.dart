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
import 'middleware/auth_middleware.dart';
import 'package:alanoapp/firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Handler para notificações em background (deve estar no top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('📬 Notificação FCM recebida em background');
  debugPrint('Título: ${message.notification?.title}');
  debugPrint('Corpo: ${message.notification?.body}');
}

void main() {
  // Global error handler to suppress known FlutterFire web interop error
  FlutterError.onError = (FlutterErrorDetails details) {
    final error = details.exception.toString();
    if (error.contains('JavaScriptObject') ||
        error.contains('_testException') ||
        error.contains('ArgumentError')) {
      // Suppress known FlutterFire web interop error
      debugPrint(
        'Suprimindo erro conhecido do FlutterFire: ${details.exception}',
      );
      return;
    }
    FlutterError.presentError(details);
  };

  // Catch errors in async code - EVERYTHING must be inside runZonedGuarded
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize Firebase
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        // Only activate App Check on non-web platforms to avoid conflicts
        if (!kIsWeb) {
          await FirebaseAppCheck.instance.activate(
            androidProvider: AndroidProvider.debug,
            appleProvider: AppleProvider.debug,
          );
        }

        // Registrar handler para notificações em background (mobile)
        if (!kIsWeb) {
          FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler,
          );
        }
      } catch (e) {
        if (e.toString().contains('duplicate-app')) {
          // Firebase already initialized
        } else {
          rethrow;
        }
      }

      timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());

      runApp(const MyApp());
    },
    (error, stack) {
      // Catch uncaught async errors
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
    // Configurar cor da StatusBar do sistema
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor:
            Colors.transparent, // Transparente para usar a cor do AppBar
        statusBarIconBrightness: Brightness.light, // Ícones brancos
        statusBarBrightness: Brightness.dark, // Para iOS
        systemNavigationBarColor: Color(0xFF0f0f0f), // Mesma cor da AppBar
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'AlanoCryptoFX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      themeMode: ThemeMode.dark,
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

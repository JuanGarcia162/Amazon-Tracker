import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'config/supabase_config.dart';
import 'config/app_theme.dart';
import 'providers/product_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'services/notification_service.dart';

// GlobalKey para acceder al Navigator desde cualquier lugar
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Helper para obtener el contexto del Navigator
BuildContext? getNavigatorContext() {
  return navigatorKey.currentContext;
}

// Handler para notificaciones en background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📬 Notificación en background: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp();
  
  // Configurar handler de notificaciones en background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Inicializar Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  // Inicializar servicio de notificaciones
  await NotificationService().initialize();
  
  // Establecer navigatorKey para notificaciones in-app
  NotificationService().setNavigatorKey(navigatorKey);
  
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Agregar observer para detectar cambios en el estado de la app
    WidgetsBinding.instance.addObserver(this);
    // Limpiar badge al iniciar
    NotificationService().clearBadge();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Cuando la app vuelve al foreground, limpiar el badge
    if (state == AppLifecycleState.resumed) {
      NotificationService().clearBadge();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, authProvider, themeProvider, _) {
          // Actualizar el brillo del sistema después del build
          final brightness = MediaQuery.platformBrightnessOf(context);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            themeProvider.updateSystemBrightness(brightness);
          });

          return CupertinoApp(
            title: 'Amazon Tracker',
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
            home: authProvider.isAuthenticated
                ? const HomeScreen()
                : const LoginScreen(),
            theme: AppTheme.buildTheme(themeProvider.isDarkMode),
          );
        },
      ),
    );
  }
}

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

/// Servicio para manejar notificaciones push con Firebase Cloud Messaging
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  GlobalKey<NavigatorState>? _navigatorKey;

  /// Establecer navigatorKey
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Inicializar el servicio de notificaciones
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Solicitar permisos
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Permisos de notificaciones concedidos');
      } else {
        print('⚠️ Permisos de notificaciones denegados');
        return;
      }

      // Configurar notificaciones locales
      await _initializeLocalNotifications();

      // Obtener FCM token
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('📱 FCM Token: $token');
        await _saveFCMToken(token);
      }

      // Escuchar cambios en el token
      _firebaseMessaging.onTokenRefresh.listen(_saveFCMToken);

      // Manejar notificaciones cuando la app está en foreground
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Manejar notificaciones cuando la app se abre desde una notificación
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Verificar si la app se abrió desde una notificación
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _initialized = true;
      print('✅ Servicio de notificaciones inicializado');
    } catch (e) {
      print('❌ Error inicializando notificaciones: $e');
    }
  }

  /// Inicializar notificaciones locales
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Configurar canal de notificaciones para Android
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'price_alerts',
        'Alertas de Precio',
        description: 'Notificaciones cuando un producto alcanza tu precio objetivo',
        importance: Importance.high,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }
  }

  /// Guardar FCM token en Supabase
  Future<void> _saveFCMToken(String token) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        print('⚠️ Usuario no autenticado, no se puede guardar FCM token');
        return;
      }

      // Guardar o actualizar el token en la tabla de usuarios
      await supabase.from('user_fcm_tokens').upsert({
        'user_id': userId,
        'fcm_token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('✅ FCM token guardado en Supabase');
    } catch (e) {
      print('❌ Error guardando FCM token: $e');
    }
  }

  /// Manejar notificaciones cuando la app está en foreground
  void _handleForegroundMessage(RemoteMessage message) {
    print('📬 Notificación recibida en foreground: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    // Mostrar notificación in-app
    _showInAppNotification(
      title: notification.title ?? 'Amazon Tracker',
      body: notification.body ?? '',
    );
  }

  /// Mostrar notificación in-app
  void _showInAppNotification({
    required String title,
    required String body,
  }) {
    // Usar navigatorKey para obtener el contexto
    final context = _getNavigatorContext();
    if (context == null) {
      print('⚠️ No hay contexto disponible para notificación in-app');
      // Fallback: Mostrar notificación local
      _showLocalNotification(
        title: title,
        body: body,
        payload: '',
      );
      return;
    }
    
    try {
      // Mostrar banner sutil en la parte superior
      _showBannerNotification(context, title, body);
    } catch (e) {
      print('❌ Error mostrando notificación in-app: $e');
    }
  }

  /// Mostrar banner de notificación sutil
  void _showBannerNotification(BuildContext context, String title, String body) {
    // Esperar 2 segundos para asegurar que todo esté completamente listo
    Future.delayed(const Duration(seconds: 2), () {
      try {
        // Usar el overlay del navigatorKey directamente
        final overlay = _navigatorKey?.currentState?.overlay;
        
        if (overlay == null) {
          print('❌ No se pudo obtener el overlay del Navigator');
          _showLocalNotification(
            title: title,
            body: body,
            payload: '',
          );
          return;
        }

        late OverlayEntry overlayEntry;

        overlayEntry = OverlayEntry(
          builder: (context) => _NotificationBanner(
            title: title,
            body: body,
            onDismiss: () {
              try {
                overlayEntry.remove();
              } catch (e) {
                print('⚠️ Error removiendo overlay: $e');
              }
            },
            onTap: () {
              try {
                overlayEntry.remove();
                // Navegar a favoritos si es necesario
              } catch (e) {
                print('⚠️ Error removiendo overlay: $e');
              }
            },
          ),
        );

        overlay.insert(overlayEntry);

        // Auto-dismiss después de 5 segundos
        Future.delayed(const Duration(seconds: 5), () {
          try {
            if (overlayEntry.mounted) {
              overlayEntry.remove();
            }
          } catch (e) {
            print('⚠️ Error en auto-dismiss: $e');
          }
        });
      } catch (e) {
        print('❌ Error mostrando banner: $e');
        // Fallback a notificación local
        _showLocalNotification(
          title: title,
          body: body,
          payload: '',
        );
      }
    });
  }

  /// Obtener contexto del Navigator usando navigatorKey
  BuildContext? _getNavigatorContext() {
    return _navigatorKey?.currentContext;
  }

  /// Mostrar notificación local
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'price_alerts',
      'Alertas de Precio',
      channelDescription: 'Notificaciones cuando un producto alcanza tu precio objetivo',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Manejar tap en notificación
  void _handleNotificationTap(RemoteMessage message) {
    print('👆 Usuario tocó la notificación: ${message.data}');
    
    // Aquí puedes navegar a la pantalla del producto
    // Por ejemplo, extraer el product_id del payload y navegar
    final productId = message.data['product_id'] as String?;
    if (productId != null) {
      // TODO: Navegar a ProductDetailScreen con el productId
      print('📦 Navegar al producto: $productId');
    }
  }

  /// Manejar tap en notificación local
  void _onNotificationTap(NotificationResponse response) {
    print('👆 Usuario tocó la notificación local: ${response.payload}');
    // Similar a _handleNotificationTap
  }

  /// Cancelar todas las notificaciones
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Limpiar el badge count (número rojo en el ícono de la app)
  Future<void> clearBadge() async {
    try {
      // Cancelar todas las notificaciones pendientes
      await _localNotifications.cancelAll();
      
      if (Platform.isIOS) {
        // En iOS, también necesitamos limpiar las notificaciones entregadas
        final iosPlugin = _localNotifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        
        // Esto limpia el badge automáticamente en iOS
        await iosPlugin?.cancelAll();
        
        print('✅ Badge y notificaciones limpiados');
      }
    } catch (e) {
      print('❌ Error limpiando badge: $e');
    }
  }

  /// Eliminar FCM token al cerrar sesión
  Future<void> deleteFCMToken() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) return;

      await supabase
          .from('user_fcm_tokens')
          .delete()
          .eq('user_id', userId);

      await _firebaseMessaging.deleteToken();
      print('✅ FCM token eliminado');
    } catch (e) {
      print('❌ Error eliminando FCM token: $e');
    }
  }
}

/// Handler para notificaciones en background (debe ser top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📬 Notificación recibida en background: ${message.notification?.title}');
}

/// Widget de banner de notificación in-app
class _NotificationBanner extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _NotificationBanner({
    required this.title,
    required this.body,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  State<_NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<_NotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: widget.onTap,
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! < -300) {
                _dismiss();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF007AFF),
                    const Color(0xFF007AFF).withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007AFF).withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.bell_fill,
                      color: CupertinoColors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.body,
                          style: TextStyle(
                            color: CupertinoColors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Close button
                  GestureDetector(
                    onTap: _dismiss,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.xmark,
                        color: CupertinoColors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

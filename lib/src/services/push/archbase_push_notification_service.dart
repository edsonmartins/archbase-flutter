import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/archbase_storage_keys.dart';
import '../../core/state/archbase_service.dart';
import '../storage/archbase_storage_service.dart';

/// Mensagem normalizada vinda de uma notificação remota.
class ArchbasePushMessage {
  ArchbasePushMessage({
    required this.id,
    this.title,
    this.body,
    this.data = const {},
  });

  final String id;
  final String? title;
  final String? body;
  final Map<String, dynamic> data;

  factory ArchbasePushMessage.fromRemoteMessage(RemoteMessage m) {
    return ArchbasePushMessage(
      id: m.messageId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: m.notification?.title,
      body: m.notification?.body,
      data: Map<String, dynamic>.from(m.data),
    );
  }
}

/// Definição de canal Android (ignorada em iOS).
class ArchbaseNotificationChannel {
  const ArchbaseNotificationChannel({
    required this.id,
    required this.name,
    required this.description,
    this.importance = Importance.high,
  });

  final String id;
  final String name;
  final String description;
  final Importance importance;
}

/// Wrapper Firebase Messaging + flutter_local_notifications.
///
/// Cuida de:
/// - permissão (iOS / Android 13+)
/// - canais
/// - foreground/background handlers
/// - exibição local quando a notificação chega em foreground
/// - persistência do token e listener de refresh
class ArchbasePushNotificationService extends ArchbaseService {
  ArchbasePushNotificationService({
    required this.storage,
    this.channels = const [
      ArchbaseNotificationChannel(
        id: 'archbase_default',
        name: 'Notificações',
        description: 'Notificações gerais do app',
      ),
    ],
    this.androidIcon = '@mipmap/ic_launcher',
  });

  final ArchbaseStorageService storage;
  final List<ArchbaseNotificationChannel> channels;
  final String androidIcon;

  final FirebaseMessaging _fm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  final ValueNotifier<String?> token = ValueNotifier<String?>(null);

  final _onMessageController =
      StreamController<ArchbasePushMessage>.broadcast();
  final _onMessageOpenedController =
      StreamController<ArchbasePushMessage>.broadcast();

  /// Disparado quando o app está em primeiro plano e recebe push.
  Stream<ArchbasePushMessage> get onMessage => _onMessageController.stream;

  /// Disparado quando o usuário toca em uma notificação para abrir o app.
  Stream<ArchbasePushMessage> get onMessageOpenedApp =>
      _onMessageOpenedController.stream;

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  StreamSubscription<String>? _tokenSub;

  @override
  Future<void> onInit() async {
    await _local.initialize(
      InitializationSettings(
        android: AndroidInitializationSettings(androidIcon),
        iOS: const DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == null) return;
        try {
          final decoded = jsonDecode(response.payload!) as Map<String, dynamic>;
          _onMessageOpenedController.add(
            ArchbasePushMessage(
              id: decoded['id']?.toString() ??
                  DateTime.now().microsecondsSinceEpoch.toString(),
              title: decoded['title']?.toString(),
              body: decoded['body']?.toString(),
              data: (decoded['data'] as Map?)?.cast<String, dynamic>() ?? {},
            ),
          );
        } catch (_) {}
      },
    );

    if (Platform.isAndroid) {
      final android = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      for (final ch in channels) {
        await android?.createNotificationChannel(
          AndroidNotificationChannel(
            ch.id,
            ch.name,
            description: ch.description,
            importance: ch.importance,
          ),
        );
      }
    }

    await _fm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Solicita permissão. Em Android 13+, isso engatilha o prompt do sistema.
  Future<bool> requestPermission() async {
    final settings = await _fm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Inicia listeners + obtém token. Chame após login.
  Future<void> start() async {
    final fcmToken = await _fm.getToken();
    if (fcmToken != null) {
      token.value = fcmToken;
      await storage.write(ArchbaseStorageKeys.fcmToken, fcmToken);
    }

    _tokenSub?.cancel();
    _tokenSub = _fm.onTokenRefresh.listen((newToken) async {
      token.value = newToken;
      await storage.write(ArchbaseStorageKeys.fcmToken, newToken);
    });

    _foregroundSub?.cancel();
    _foregroundSub = FirebaseMessaging.onMessage.listen((message) async {
      final msg = ArchbasePushMessage.fromRemoteMessage(message);
      _onMessageController.add(msg);
      // Mostra como notificação local para o user enxergar mesmo em foreground.
      if (msg.title != null || msg.body != null) {
        await showLocal(
          channelId: channels.first.id,
          title: msg.title ?? '',
          body: msg.body ?? '',
          payload: jsonEncode({
            'id': msg.id,
            'title': msg.title,
            'body': msg.body,
            'data': msg.data,
          }),
        );
      }
    });

    _openedSub?.cancel();
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _onMessageOpenedController
          .add(ArchbasePushMessage.fromRemoteMessage(message));
    });

    final initial = await _fm.getInitialMessage();
    if (initial != null) {
      _onMessageOpenedController
          .add(ArchbasePushMessage.fromRemoteMessage(initial));
    }
  }

  Future<void> stop() async {
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
    await _tokenSub?.cancel();
    _foregroundSub = null;
    _openedSub = null;
    _tokenSub = null;
  }

  /// Exibe uma notificação local (sem passar pela rede).
  Future<void> showLocal({
    required String channelId,
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    final channel = channels.firstWhere(
      (c) => c.id == channelId,
      orElse: () => channels.first,
    );
    await _local.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: channel.importance,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  Future<void> deleteToken() async {
    try {
      await _fm.deleteToken();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[archbase][push] deleteToken falhou: $e');
      }
    }
    token.value = null;
    await storage.remove(ArchbaseStorageKeys.fcmToken);
  }

  @override
  Future<void> onDispose() async {
    await stop();
    await _onMessageController.close();
    await _onMessageOpenedController.close();
    token.dispose();
  }
}

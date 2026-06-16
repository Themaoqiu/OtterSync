import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:ottersync/services/app_event_bus.dart';

///
///
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('后台收到推送: ${message.messageId} / ${message.notification?.title}');
}

///
///
class MessagingService {
  MessagingService._();

  static final MessagingService instance = MessagingService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _initialized = false;
  String? _token;

  String? get token => _token;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
    } catch (error) {
      debugPrint('请求推送权限失败: $error');
    }

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpened(initialMessage);
    }
  }

  Future<void> registerToken(String uid) async {
    try {
      _token = await _messaging.getToken();
      if (_token != null) {
        await _saveToken(uid, _token!);
      }
      _messaging.onTokenRefresh.listen((newToken) {
        _token = newToken;
        _saveToken(uid, newToken);
      });
    } catch (error) {
      debugPrint('获取/保存 FCM token 失败: $error');
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    await _firestore.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    debugPrint('前台收到推送: ${notification?.title}');
    AppEventBus.instance.emitType(
      AppEventType.notificationReceived,
      payload: {
        'title': notification?.title,
        'body': notification?.body,
        'route': message.data['route'],
      },
    );
  }

  void _handleMessageOpened(RemoteMessage message) {
    final route = message.data['route'];
    debugPrint('用户点击推送进入: $route');
    if (route is String && route.isNotEmpty) {
      AppEventBus.instance.emitType(
        AppEventType.notificationReceived,
        payload: {'route': route, 'opened': true},
      );
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:ottersync/services/app_event_bus.dart';

/// 后台消息处理器。
///
/// 当推送到达而应用处于后台或已被系统杀死时，Android 系统的
/// `FirebaseMessagingService`（一个真正的系统级后台 Service）会唤起一个
/// 独立的后台 Isolate 来运行这个顶层函数。因此它必须是顶层函数，并标注
/// [pragma]('vm:entry-point') 以防被 release 编译裁剪。
///
/// 这里只做轻量记录；真实业务（如本地通知落库）应保持精简，因为后台
/// 执行时间受系统限制。
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('后台收到推送: ${message.messageId} / ${message.notification?.title}');
}

/// 推送消息服务（对应 Android 的 FirebaseMessagingService 客户端封装）。
///
/// 负责：
/// 1. 申请通知权限；
/// 2. 获取并维护 FCM token，写入当前用户的 Firestore 文档，供服务端定向推送；
/// 3. 监听前台消息 [FirebaseMessaging.onMessage]，转成应用内广播（事件总线）；
/// 4. 监听用户点击推送进入应用 [FirebaseMessaging.onMessageOpenedApp]。
///
/// 采用单例，在应用启动时初始化、随进程常驻，是一个独立于任何页面、
/// 长期在后台监听消息流的服务组件。
class MessagingService {
  MessagingService._();

  static final MessagingService instance = MessagingService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _initialized = false;
  String? _token;

  String? get token => _token;

  /// 初始化前台监听与权限申请。后台处理器需在 `main` 中单独注册。
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (error) {
      debugPrint('请求推送权限失败: $error');
    }

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

    // 应用被推送冷启动时的首条消息。
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpened(initialMessage);
    }
  }

  /// 登录成功后调用：取 token 并写入用户文档。token 变化时自动更新。
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
    await _firestore.collection('users').doc(uid).set(
      {
        'fcmTokens': FieldValue.arrayUnion([token]),
      },
      SetOptions(merge: true),
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    debugPrint('前台收到推送: ${notification?.title}');
    // 把收到的推送转换成应用内广播，让通知红点 / 列表等订阅方刷新。
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

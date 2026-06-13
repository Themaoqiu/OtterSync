import 'dart:async';

enum AppEventType {
  workItemCreated,
  workItemUpdated,
  workspaceCreated,
  workspaceMembershipChanged,
  notificationReceived,
}

class AppEvent {
  const AppEvent(this.type, {this.payload = const {}});

  final AppEventType type;
  final Map<String, Object?> payload;

  @override
  String toString() => 'AppEvent($type, $payload)';
}

class AppEventBus {
  AppEventBus._();

  static final AppEventBus instance = AppEventBus._();

  final StreamController<AppEvent> _controller =
      StreamController<AppEvent>.broadcast();

  Stream<AppEvent> get stream => _controller.stream;

  void emit(AppEvent event) {
    if (_controller.isClosed) {
      return;
    }
    _controller.add(event);
  }

  void emitType(AppEventType type, {Map<String, Object?> payload = const {}}) {
    emit(AppEvent(type, payload: payload));
  }

  /// 订阅指定若干事件类型，类似注册一个只接收特定 action 的接收器。
  ///
  /// 传入空集合表示订阅全部事件。返回的 [StreamSubscription] 需由调用方
  /// 在不再需要时 `cancel()`。
  StreamSubscription<AppEvent> on(
    Set<AppEventType> types,
    void Function(AppEvent event) onEvent,
  ) {
    return _controller.stream.listen((event) {
      if (types.isEmpty || types.contains(event.type)) {
        onEvent(event);
      }
    });
  }
}

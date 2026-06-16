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

  ///
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

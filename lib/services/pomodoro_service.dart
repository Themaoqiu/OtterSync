import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

///
///

///
@pragma('vm:entry-point')
void startPomodoroCallback() {
  FlutterForegroundTask.setTaskHandler(_PomodoroTaskHandler());
}

class _PomodoroTaskHandler extends TaskHandler {
  DateTime? _endAt;
  String _taskName = '专注';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onReceiveData(Object data) {
    if (data is Map) {
      final seconds = (data['durationSeconds'] as num?)?.toInt() ?? 0;
      _taskName = (data['taskName'] as String?)?.trim().isNotEmpty == true
          ? data['taskName'] as String
          : '专注';
      _endAt = DateTime.now().add(Duration(seconds: seconds));
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    final endAt = _endAt;
    if (endAt == null) {
      return;
    }

    final remaining = endAt.difference(DateTime.now()).inSeconds;
    if (remaining > 0) {
      FlutterForegroundTask.updateService(
        notificationTitle: '专注中 · $_taskName',
        notificationText: '⏱ ${_formatClock(remaining)}',
      );
      FlutterForegroundTask.sendDataToMain({
        'remaining': remaining,
        'taskName': _taskName,
      });
    } else {
      _endAt = null;
      FlutterForegroundTask.updateService(
        notificationTitle: '专注完成 🎉',
        notificationText: '$_taskName 已完成一个番茄钟',
      );
      FlutterForegroundTask.sendDataToMain({'finished': true});
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _endAt = null;
  }
}

class PomodoroController extends ChangeNotifier {
  PomodoroController._();

  static final PomodoroController instance = PomodoroController._();

  bool _isRunning = false;
  int _remainingSeconds = 0;
  String _taskName = '';

  bool get isRunning => _isRunning;
  int get remainingSeconds => _remainingSeconds;
  String get taskName => _taskName;

  String get remainingClock => _formatClock(_remainingSeconds);

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'pomodoro_focus',
        channelName: '专注计时',
        channelDescription: '番茄钟专注计时器的常驻通知',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        allowWakeLock: true,
        autoRunOnBoot: false,
      ),
    );

    FlutterForegroundTask.addTaskDataCallback(_onReceiveFromTask);
  }

  Future<bool> start({
    required String taskName,
    required Duration duration,
  }) async {
    if (_isRunning) {
      return false;
    }

    final permission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (permission != NotificationPermission.granted) {
      final requested =
          await FlutterForegroundTask.requestNotificationPermission();
      if (requested != NotificationPermission.granted) {
        return false;
      }
    }

    final seconds = duration.inSeconds;
    final result = await FlutterForegroundTask.startService(
      serviceId: 1001,
      serviceTypes: const [ForegroundServiceTypes.dataSync],
      notificationTitle: '专注中 · $taskName',
      notificationText: '⏱ ${_formatClock(seconds)}',
      callback: startPomodoroCallback,
    );

    if (result is! ServiceRequestSuccess) {
      debugPrint('启动专注服务失败: $result');
      return false;
    }

    FlutterForegroundTask.sendDataToTask({
      'taskName': taskName,
      'durationSeconds': seconds,
    });

    _isRunning = true;
    _taskName = taskName;
    _remainingSeconds = seconds;
    notifyListeners();
    return true;
  }

  Future<void> stop() async {
    if (!_isRunning) {
      return;
    }
    await FlutterForegroundTask.stopService();
    _reset();
  }

  void _onReceiveFromTask(Object data) {
    if (data is! Map) {
      return;
    }
    if (data['finished'] == true) {
      FlutterForegroundTask.stopService();
      _reset();
      return;
    }
    final remaining = (data['remaining'] as num?)?.toInt();
    if (remaining != null) {
      _remainingSeconds = remaining;
      final name = data['taskName'] as String?;
      if (name != null && name.isNotEmpty) {
        _taskName = name;
      }
      _isRunning = true;
      notifyListeners();
    }
  }

  void _reset() {
    _isRunning = false;
    _remainingSeconds = 0;
    _taskName = '';
    notifyListeners();
  }
}

String _formatClock(int totalSeconds) {
  final clamped = totalSeconds < 0 ? 0 : totalSeconds;
  final minutes = (clamped ~/ 60).toString().padLeft(2, '0');
  final seconds = (clamped % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

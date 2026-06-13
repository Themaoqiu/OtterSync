import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// 番茄钟专注计时器 —— 一个真正的 Android 前台服务（Foreground Service）。
///
/// 这就是「像播放音乐那样」的服务：用户在工作项详情页点「专注计时」后，
/// 即使把 App 退到后台或锁屏，计时仍由系统级前台服务持续运行，并在通知栏
/// 常驻显示倒计时与任务名；计时结束后通知变为「专注完成」。
///
/// 本文件包含两部分：
/// 1. [_PomodoroTaskHandler] + [startPomodoroCallback]：运行在独立后台 isolate 中，
///    由前台服务驱动，每秒触发一次倒计时逻辑。
/// 2. [PomodoroController]：运行在主 isolate（UI 侧）的单例 ChangeNotifier，
///    负责启动/停止服务、申请权限，并把后台传来的剩余时间同步给界面。

/// 后台服务的入口回调。
///
/// 必须是顶层函数并标注 [pragma]('vm:entry-point')，否则 release 编译会裁剪掉它，
/// 系统在后台 isolate 中也就找不到这个入口。
@pragma('vm:entry-point')
void startPomodoroCallback() {
  FlutterForegroundTask.setTaskHandler(_PomodoroTaskHandler());
}

/// 前台服务在后台 isolate 中执行的任务处理器。
class _PomodoroTaskHandler extends TaskHandler {
  DateTime? _endAt;
  String _taskName = '专注';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // 服务刚启动，真正的时长由主 isolate 通过 sendDataToTask 下发。
  }

  /// 主 isolate 通过 [FlutterForegroundTask.sendDataToTask] 下发参数。
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

  /// 由 ForegroundTaskOptions 的 eventAction 决定调用频率（这里每秒一次）。
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

/// UI 侧单例：暴露专注计时状态，并代理前台服务的启动/停止。
class PomodoroController extends ChangeNotifier {
  PomodoroController._();

  static final PomodoroController instance = PomodoroController._();

  bool _isRunning = false;
  int _remainingSeconds = 0;
  String _taskName = '';

  bool get isRunning => _isRunning;
  int get remainingSeconds => _remainingSeconds;
  String get taskName => _taskName;

  /// 剩余时间的 mm:ss 文本，供按钮直接显示。
  String get remainingClock => _formatClock(_remainingSeconds);

  bool _initialized = false;

  /// 在 App 启动时调用：配置通知渠道与任务节拍，并注册数据回调。
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

  /// 开始专注：申请通知权限 → 启动前台服务 → 下发任务名与时长。
  Future<bool> start({
    required String taskName,
    required Duration duration,
  }) async {
    if (_isRunning) {
      return false;
    }

    final permission = await FlutterForegroundTask.checkNotificationPermission();
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

    // 服务起来后把任务参数发给后台 isolate。
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

  /// 停止专注：关闭前台服务并复位状态。
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
      // 计时自然结束：服务因 stopWithTask 仍在运行，这里主动收尾。
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

/// 把秒数格式化为 mm:ss。
String _formatClock(int totalSeconds) {
  final clamped = totalSeconds < 0 ? 0 : totalSeconds;
  final minutes = (clamped ~/ 60).toString().padLeft(2, '0');
  final seconds = (clamped % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

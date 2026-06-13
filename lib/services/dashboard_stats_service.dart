import 'package:flutter/foundation.dart';
import 'package:ottersync/viewmodels/jira_models.dart';

/// 仪表盘四项统计的结果。
class DashboardStatsResult {
  const DashboardStatsResult({
    required this.assigned,
    required this.inProgress,
    required this.dueSoon,
    required this.completedThisWeek,
  });

  final int assigned;
  final int inProgress;
  final int dueSoon;
  final int completedThisWeek;
}

/// 后台统计服务。
///
/// 把仪表盘的工作量聚合放到独立的后台 Isolate 线程执行，避免在工作项
/// 数量较大时阻塞 UI 线程。这里通过 Flutter 的 [compute] 启动一次性
/// Isolate：它在线程内运行纯函数 [_aggregate]，算完把结果回传主线程。
///
/// 由于 Isolate 之间只能传递可序列化的简单数据，[computeStats] 先把
/// [IssueSummary] 列表降维成由 int 组成的「行记录」再发送，从根本上
///规避了跨 Isolate 传递复杂对象的问题。
class DashboardStatsService {
  const DashboardStatsService();

  Future<DashboardStatsResult> computeStats({
    required int assignedCount,
    required List<IssueSummary> allItems,
  }) async {
    final now = DateTime.now();
    // 序列化为后台线程可接收的纯数据：
    // [statusIndex, dueDateMillis(-1 表示空), completedAtMillis(-1 表示空)]
    final rows = allItems
        .map((item) => <int>[
              item.statusKey.index,
              item.dueDate?.millisecondsSinceEpoch ?? -1,
              item.completedAt?.millisecondsSinceEpoch ?? -1,
            ])
        .toList(growable: false);

    final payload = _StatsPayload(
      assignedCount: assignedCount,
      nowMillis: now.millisecondsSinceEpoch,
      rows: rows,
    );

    // compute 会 spawn 一个后台 Isolate 运行 _aggregate。
    final counts = await compute(_aggregate, payload);
    return DashboardStatsResult(
      assigned: assignedCount,
      inProgress: counts[0],
      dueSoon: counts[1],
      completedThisWeek: counts[2],
    );
  }
}

class _StatsPayload {
  const _StatsPayload({
    required this.assignedCount,
    required this.nowMillis,
    required this.rows,
  });

  final int assignedCount;
  final int nowMillis;
  final List<List<int>> rows;
}

/// 在后台 Isolate 中运行的纯函数：遍历行记录算出三项计数。
List<int> _aggregate(_StatsPayload payload) {
  final now = DateTime.fromMillisecondsSinceEpoch(payload.nowMillis);
  final today = DateTime(now.year, now.month, now.day);
  final doneIndex = WorkItemStatus.done.index;
  final inProgressIndex = WorkItemStatus.inProgress.index;

  var inProgress = 0;
  var dueSoon = 0;
  var completedThisWeek = 0;

  for (final row in payload.rows) {
    final statusIndex = row[0];
    final dueMillis = row[1];
    final completedMillis = row[2];

    if (statusIndex == inProgressIndex) {
      inProgress++;
    }

    if (dueMillis >= 0 && statusIndex != doneIndex) {
      final due = DateTime.fromMillisecondsSinceEpoch(dueMillis);
      final dueDay = DateTime(due.year, due.month, due.day);
      final diff = dueDay.difference(today).inDays;
      if (diff >= 0 && diff <= 3) {
        dueSoon++;
      }
    }

    if (statusIndex == doneIndex && completedMillis >= 0) {
      final completed = DateTime.fromMillisecondsSinceEpoch(completedMillis);
      if (now.difference(completed).inDays <= 7) {
        completedThisWeek++;
      }
    }
  }

  return [inProgress, dueSoon, completedThisWeek];
}

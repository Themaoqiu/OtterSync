import 'package:flutter/foundation.dart';
import 'package:ottersync/viewmodels/jira_models.dart';

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

///
///
class DashboardStatsService {
  const DashboardStatsService();

  Future<DashboardStatsResult> computeStats({
    required int assignedCount,
    required List<IssueSummary> allItems,
  }) async {
    final now = DateTime.now();
    final rows = allItems
        .map(
          (item) => <int>[
            item.statusKey.index,
            item.dueDate?.millisecondsSinceEpoch ?? -1,
            item.completedAt?.millisecondsSinceEpoch ?? -1,
          ],
        )
        .toList(growable: false);

    final payload = _StatsPayload(
      assignedCount: assignedCount,
      nowMillis: now.millisecondsSinceEpoch,
      rows: rows,
    );

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

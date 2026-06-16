part of 'work_item_service.dart';

extension RecentViewService on WorkItemService {
  Future<List<QuickAccessItem>> loadHomeQuickAccess() async {
    return _guard(() async {
      await _ensureSeedData();
      final spaces = await listSpaces();
      final items = await _loadWorkItemMaps(limit: 4);
      final result = <QuickAccessItem>[];

      for (final space in spaces.take(2)) {
        result.add(
          QuickAccessItem(
            title: '${space.key}面板',
            subtitle: space.name,
            icon: space.avatar.icon,
            color: space.avatar.gradient.first.withValues(alpha: 0.18),
            iconTint: space.avatar.gradient.first,
            route: '/space-details/${space.id}',
          ),
        );
      }

      final remaining = 3 - result.length;
      for (final data in items.take(remaining > 0 ? remaining : 0)) {
        final workspace = Map<String, dynamic>.from(
          data['workspace'] as Map? ?? const <String, dynamic>{},
        );
        result.add(
          QuickAccessItem(
            title: data['summary'] as String? ?? '',
            subtitle:
                '${data['key'] as String? ?? ''} • ${workspace['title'] as String? ?? ''}',
            icon: Icons.task_alt_rounded,
            color: const Color(0xFFD8E7FF),
            iconTint: const Color(0xFF0C66E4),
            route: '/all-work',
          ),
        );
      }

      return result;
    });
  }

  Future<void> recordRecentView({
    required int workItemId,
    required String workItemKey,
    required String workItemTitle,
  }) async {
    return _guard(() async {
      await _ensureSeedData();
      await _ensureCanEditWorkItem(workItemId);
      final uid = _requireCurrentUid();
      final docId = '${uid}_$workItemId';
      await _recentViewsCollection.doc(docId).set({
        'userId': uid,
        'targetId': workItemId,
        'targetKey': workItemKey,
        'targetTitle': workItemTitle,
        'viewedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<List<IssueSummary>> loadRecentProjects({int limit = 4}) async {
    return _guard(() async {
      await _ensureSeedData();
      final items = await _loadWorkItemMaps(limit: limit);
      return items.map(_issueSummaryFromWorkItem).toList(growable: false);
    });
  }

  Future<List<IssueSummary>> loadAssignedIssues({int limit = 4}) async {
    return _guard(() async {
      await _ensureSeedData();
      final items = await _loadWorkItemMaps(limit: limit);
      return items.map(_issueSummaryFromWorkItem).toList(growable: false);
    });
  }

  Future<List<IssueSummary>> loadViewedItems({int limit = 4}) async {
    return _guard(() async {
      await _ensureSeedData();
      final uid = _currentUid;
      if (uid == null || uid.isEmpty) {
        return const <IssueSummary>[];
      }

      final viewSnapshot = await _recentViewsCollection
          .where('userId', isEqualTo: uid)
          .get();
      if (viewSnapshot.docs.isEmpty) {
        return const <IssueSummary>[];
      }

      final viewedAtById = <int, DateTime?>{};
      for (final doc in viewSnapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        final targetId = (data['targetId'] as num?)?.toInt();
        if (targetId != null) {
          viewedAtById[targetId] = _asDateTime(data['viewedAt']);
        }
      }

      final items = await _loadWorkItemMaps();
      final result = <IssueSummary>[];
      for (final data in items) {
        final id = (data['id'] as num?)?.toInt();
        if (id == null || !viewedAtById.containsKey(id)) {
          continue;
        }
        result.add(
          _issueSummaryFromWorkItem(
            data,
          ).copyWith(lastViewedAt: viewedAtById[id]),
        );
      }

      result.sort((a, b) {
        final ta = a.lastViewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.lastViewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });

      if (result.length <= limit) {
        return result;
      }
      return result.take(limit).toList(growable: false);
    });
  }

  Future<List<IssueSummary>> loadRecentDynamicItems({int limit = 4}) async {
    return _guard(() async {
      await _ensureSeedData();
      final items = await _loadWorkItemMaps(
        limit: limit,
        sortBy: (data) => _asDateTime(data['createdAt']),
      );
      return items.map(_issueSummaryFromWorkItem).toList(growable: false);
    });
  }

  Future<List<DashboardActivityItem>> loadDashboardActivities({
    int limit = 6,
  }) async {
    return _guard(() async {
      await _ensureSeedData();
      final items = await _loadWorkItemMaps(limit: limit);
      return items
          .map((data) {
            final key = data['key'] as String? ?? '';
            final summary = data['summary'] as String? ?? '';
            return DashboardActivityItem(
              text: '创建了 $key - $summary',
              issue: key,
              time: _relativeTimeLabel(_asDateTime(data['createdAt'])),
            );
          })
          .toList(growable: false);
    });
  }
}

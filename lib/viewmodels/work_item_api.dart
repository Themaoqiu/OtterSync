import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ottersync/viewmodels/jira_models.dart';
import 'package:ottersync/viewmodels/work_item_models.dart';

class WorkItemApiException implements Exception {
  const WorkItemApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class WorkItemApi {
  WorkItemApi({FirebaseFirestore? firestore, String? currentUid})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _currentUid = currentUid ?? _defaultUid;

  final FirebaseFirestore _firestore;
  final String? _currentUid;

  static String? _defaultUid;

  /// Sets the default UID for all WorkItemApi instances.
  /// Called once after authentication is confirmed.
  static void init({required String uid}) {
    _defaultUid = uid;
  }

  /// Clears the default UID on sign-out.
  static void clear() {
    _defaultUid = null;
  }

  static const _metaCollection = '_meta';
  static const _workspacesCollection = 'workspaces';
  static const _workTypesCollection = 'workTypes';
  static const _usersCollection = 'users';
  static const _teamsCollection = 'teams';
  static const _labelsCollection = 'labels';
  static const _workItemsCollection = 'workItems';
  static const _feedbackCollectionName = 'feedback';
  CollectionReference get _feedbackCollection =>
      _firestore.collection(_feedbackCollectionName);
  CollectionReference get _recentViewsCollection =>
      _firestore.collection('recentViews');

  Future<List<JiraSpace>> listSpaces() async {
    return _guard(() async {
      await _ensureSeedData();
      final snapshot = await _firestore.collection(_workspacesCollection).orderBy('id').get();
      final workItemSnapshot = await _firestore.collection(_workItemsCollection).get();
      final counts = <int, int>{};

      for (final doc in workItemSnapshot.docs) {
        final data = doc.data();
        final workspaceId = (data['workspaceId'] as num?)?.toInt();
        if (workspaceId != null) {
          counts.update(workspaceId, (value) => value + 1, ifAbsent: () => 1);
        }
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final id = (data['id'] as num).toInt();
        return JiraSpace(
          id: id,
          name: data['title'] as String? ?? '',
          key: data['subtitle'] as String? ?? '',
          template: data['template'] as String? ?? '看板',
          issueCount: counts[id] ?? 0,
          avatar: buildSpaceAvatar('${data['subtitle'] ?? ''}${data['title'] ?? ''}'),
        );
      }).toList(growable: false);
    });
  }

  Future<JiraSpace> createWorkspace(WorkspaceCreateRequest payload) async {
    return _guard(() async {
      await _ensureSeedData();
      final name = payload.name.trim();
      final key = payload.key.trim().toUpperCase();
      final template = payload.template.trim();

      if (name.isEmpty) {
        throw const WorkItemApiException('请输入空间名称。');
      }
      if (key.isEmpty) {
        throw const WorkItemApiException('请输入空间 Key。');
      }

      final existing = await _firestore
          .collection(_workspacesCollection)
          .where('subtitle', isEqualTo: key)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        throw const WorkItemApiException('该空间 Key 已存在，请使用其他 Key。');
      }

      final id = await _nextId('workspaces');
      final record = JiraSpace(
        id: id,
        name: name,
        key: key,
        template: template.isEmpty ? '看板' : template,
        avatar: buildSpaceAvatar('$key$name'),
      );

      await _firestore.collection(_workspacesCollection).doc('$id').set({
        'id': record.id,
        'title': record.name,
        'subtitle': record.key,
        'template': record.template,
        'avatarSeed': '$key$name',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return record;
    });
  }

  Future<JiraSpace?> getWorkspaceById(int id) async {
    return _guard(() async {
      await _ensureSeedData();
      final snapshot = await _firestore.collection(_workspacesCollection).doc('$id').get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      final count = await _countWorkspaceItems(id);
      return JiraSpace(
        id: (data['id'] as num).toInt(),
        name: data['title'] as String? ?? '',
        key: data['subtitle'] as String? ?? '',
        template: data['template'] as String? ?? '看板',
        issueCount: count,
        avatar: buildSpaceAvatar(
          (data['avatarSeed'] as String?) ??
              '${data['subtitle'] as String? ?? ''}${data['title'] as String? ?? ''}',
        ),
      );
    });
  }

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
            subtitle: '${data['key'] as String? ?? ''} • ${workspace['title'] as String? ?? ''}',
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

  Future<WorkItemResponse?> getWorkItemById(int id) async {
    return _guard(() async {
      await _ensureSeedData();
      final doc =
          await _firestore.collection(_workItemsCollection).doc('$id').get();
      if (!doc.exists) return null;
      return WorkItemResponse.fromMap(doc.data() as Map<String, dynamic>);
    });
  }

  /// 提交反馈（点赞/踩）
  Future<void> submitFeedback({
    required String targetType,
    required String targetId,
    required String type,
    String? comment,
  }) async {
    return _guard(() async {
      await _ensureSeedData();
      final uid = _currentUid;
      if (uid == null) {
        throw const WorkItemApiException('请先登录。');
      }

      // 查询是否已有同类型反馈，有则先取消
      final existing = await _feedbackCollection
          .where('userId', isEqualTo: uid)
          .where('targetType', isEqualTo: targetType)
          .where('targetId', isEqualTo: targetId)
          .get();

      for (final doc in existing.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['type'] == type) {
          // 已有同类型反馈，取消（toggle）
          await _feedbackCollection.doc(doc.id).delete();
          return;
        }
        // 互斥：先取消相反类型
        await _feedbackCollection.doc(doc.id).delete();
      }

      final id = await _nextId('feedback');
      await _feedbackCollection.doc('$id').set({
        'id': id,
        'userId': uid,
        'targetType': targetType,
        'targetId': targetId,
        'type': type,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// 查询当前用户对某目标的反馈状态
  Future<String?> getFeedbackStatus({
    required String targetType,
    required String targetId,
  }) async {
    return _guard(() async {
      await _ensureSeedData();
      final uid = _currentUid;
      if (uid == null) return null;

      final snapshot = await _feedbackCollection
          .where('userId', isEqualTo: uid)
          .where('targetType', isEqualTo: targetType)
          .where('targetId', isEqualTo: targetId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return (snapshot.docs.first.data() as Map<String, dynamic>)['type'] as String?;
    });
  }

  /// 更新工作项状态
  Future<void> updateWorkItemStatus(int id, WorkItemStatus status) async {
    return _guard(() async {
      await _ensureSeedData();
      await _firestore.collection(_workItemsCollection).doc('$id').update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// 记录最近查看
  Future<void> recordRecentView({
    required int workItemId,
    required String workItemKey,
    required String workItemTitle,
  }) async {
    return _guard(() async {
      await _ensureSeedData();
      final docId = '${_currentUid}_$workItemId';
      await _recentViewsCollection.doc(docId).set({
        'userId': _currentUid,
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
      final items = await _loadWorkItemMaps(
        limit: limit,
        sortBy: (data) => _asDateTime(data['lastViewedAt']),
      );
      return items.map(_issueSummaryFromWorkItem).toList(growable: false);
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
      return items.map((data) {
        final key = data['key'] as String? ?? '';
        final summary = data['summary'] as String? ?? '';
        return DashboardActivityItem(
          text: '创建了 $key - $summary',
          issue: key,
          time: _relativeTimeLabel(_asDateTime(data['createdAt'])),
        );
      }).toList(growable: false);
    });
  }

  Future<List<NotificationItem>> loadNotifications({int limit = 6}) async {
    return _guard(() async {
      await _ensureSeedData();
      final items = await _loadWorkItemMaps(limit: limit);
      return items.map((data) {
        final key = data['key'] as String? ?? '';
        final summary = data['summary'] as String? ?? '';
        return NotificationItem(
          title: '工作项有新动态',
          description: '$key · $summary',
          route: '/all-work',
          workItemId: (data['id'] as num?)?.toInt(),
        );
      }).toList(growable: false);
    });
  }

  Future<List<SpaceSummaryMetric>> loadSpaceSummaryMetrics(int workspaceId) async {
    return _guard(() async {
      await _ensureSeedData();
      final items = await _loadWorkItemMaps(workspaceId: workspaceId);
      final doneCount = items.where((data) => _statusFromData(data) == WorkItemStatus.done).length;
      final inProgressCount = items
          .where((data) => _statusFromData(data) == WorkItemStatus.inProgress)
          .length;
      final createdLast7 = items
          .where((data) => _isWithinLastDays(_asDateTime(data['createdAt']), 7))
          .length;
      final dueNext7 = items
          .where((data) => _isWithinNextDays(_asDateTime(data['dueDate']), 7))
          .length;

      return [
        SpaceSummaryMetric(
          headline: '过去 7 天内',
          value: '$doneCount',
          icon: Icons.check_rounded,
          color: const Color(0xFF111214),
          emphasis: '项已完成',
        ),
        SpaceSummaryMetric(
          headline: '在过去 7 天内',
          value: '$inProgressCount',
          icon: Icons.edit_outlined,
          color: const Color(0xFF123A86),
          emphasis: '项已更新',
        ),
        SpaceSummaryMetric(
          headline: '在过去 7 天内',
          value: '$createdLast7',
          icon: Icons.add_rounded,
          color: const Color(0xFF8E4BC3),
          emphasis: '项已创建',
        ),
        SpaceSummaryMetric(
          headline: '未来 7 天内',
          value: '$dueNext7',
          icon: Icons.calendar_today_outlined,
          color: const Color(0xFF111214),
          emphasis: '项已到期',
        ),
      ];
    });
  }

  Future<List<BacklogGroup>> loadBacklogGroups(int workspaceId) async {
    return _guard(() async {
      await _ensureSeedData();
      final workspace = await getWorkspaceById(workspaceId);
      final items = await _loadWorkItemMaps(workspaceId: workspaceId);
      final backlogItems = items
          .where((data) => _bucketFromData(data) == WorkItemBucket.backlog)
          .map(_issueSummaryFromWorkItem)
          .toList(growable: false);
      final sprintItems = items
          .where((data) => _bucketFromData(data) == WorkItemBucket.sprint)
          .map(_issueSummaryFromWorkItem)
          .toList(growable: false);
      final title = workspace == null
          ? '待办事项列表'
          : '${workspace.key} 待办事项列表';

      return [
        BacklogGroup(
          title: '$title · 普通待办',
          issueCount: backlogItems.length,
          todoCount: backlogItems.where((item) => item.statusKey == WorkItemStatus.todo).length,
          inProgressCount: backlogItems
              .where((item) => item.statusKey == WorkItemStatus.inProgress)
              .length,
          doneCount: backlogItems.where((item) => item.statusKey == WorkItemStatus.done).length,
          items: backlogItems,
        ),
        BacklogGroup(
          title: '$title · 冲刺工作',
          issueCount: sprintItems.length,
          todoCount: sprintItems.where((item) => item.statusKey == WorkItemStatus.todo).length,
          inProgressCount: sprintItems
              .where((item) => item.statusKey == WorkItemStatus.inProgress)
              .length,
          doneCount: sprintItems.where((item) => item.statusKey == WorkItemStatus.done).length,
          items: sprintItems,
        ),
      ].where((group) => group.issueCount > 0).toList(growable: false);
    });
  }

  Future<int> loadBoardItemCount(int workspaceId) async {
    return _guard(() async {
      await _ensureSeedData();
      final items = await _loadWorkItemMaps(workspaceId: workspaceId);
      return items.where((data) => _bucketFromData(data) == WorkItemBucket.sprint).length;
    });
  }

  Future<List<IssueSummary>> loadBoardItems(int workspaceId) async {
    return _guard(() async {
      await _ensureSeedData();
      final items = await _loadWorkItemMaps(workspaceId: workspaceId);
      return items
          .where((data) => _bucketFromData(data) == WorkItemBucket.sprint)
          .map(_issueSummaryFromWorkItem)
          .toList(growable: false);
    });
  }

  Future<List<IssueSummary>> loadCalendarItems(int workspaceId) async {
    return _guard(() async {
      await _ensureSeedData();
      final items = await _loadWorkItemMaps(workspaceId: workspaceId);
      return items.map(_issueSummaryFromWorkItem).toList(growable: false);
    });
  }

  Future<List<LookupOption>> listWorkItems({String query = ''}) async {
    return _guard(() async {
      await _ensureSeedData();
      final snapshot = await _firestore
          .collection(_workItemsCollection)
          .orderBy('id', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Map<String, dynamic>.from(doc.data()))
          .map(
            (data) => LookupOption(
              id: (data['id'] as num).toInt(),
              title: data['summary'] as String? ?? '',
              subtitle: data['key'] as String?,
              status: data['status'] as String?,
            ),
          )
          .where((item) => _matchesQuery(item.title, query) || _matchesQuery(item.subtitle ?? '', query))
          .toList(growable: false);
    });
  }

  Future<CreateWorkItemLookups> loadCreateLookups() async {
    return _guard(() async {
      await _ensureSeedData();
      final results = await Future.wait([
        _loadLookupCollection(_workspacesCollection),
        _loadLookupCollection(_workTypesCollection),
        _loadLookupCollection(_usersCollection),
        _loadLookupCollection(_teamsCollection),
        _loadLookupCollection(_labelsCollection),
      ]);

      final workspaces = results[0];
      final workTypes = results[1];
      final users = results[2];
      final teams = results[3];
      final labels = results[4];

      return CreateWorkItemLookups(
        workspaces: workspaces,
        workTypes: workTypes,
        users: users,
        teams: teams,
        labels: labels,
      );
    });
  }

  Future<List<LookupOption>> listParentItems({
    String query = '',
    int? workspaceId,
  }) async {
    return _guard(() async {
      await _ensureSeedData();
      final snapshot = await _firestore
          .collection(_workItemsCollection)
          .orderBy('id', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Map<String, dynamic>.from(doc.data()))
          .where(
            (data) => workspaceId == null || data['workspaceId'] == workspaceId,
          )
          .map(
            (data) => LookupOption(
              id: (data['id'] as num).toInt(),
              title: data['summary'] as String? ?? '',
              subtitle: data['key'] as String?,
            ),
          )
          .where((item) => _matchesQuery(item.title, query) || _matchesQuery(item.subtitle ?? '', query))
          .toList(growable: false);
    });
  }

  /// 搜索工作项（客户端过滤）
  Future<List<IssueSummary>> searchWorkItems(String query) async {
    return _guard(() async {
      await _ensureSeedData();
      if (query.trim().isEmpty) return [];
      final maps = await _loadWorkItemMaps();
      final lowerQuery = query.toLowerCase();
      final filtered = maps.where((m) {
        final summary = (m['summary'] as String? ?? '').toLowerCase();
        final key = (m['key'] as String? ?? '').toLowerCase();
        final description = (m['description'] as String? ?? '').toLowerCase();
        return summary.contains(lowerQuery) ||
            key.contains(lowerQuery) ||
            description.contains(lowerQuery);
      }).toList();
      return filtered.map(_issueSummaryFromWorkItem).toList(growable: false);
    });
  }

  /// 搜索空间
  Future<List<JiraSpace>> searchSpaces(String query) async {
    return _guard(() async {
      await _ensureSeedData();
      if (query.trim().isEmpty) return [];
      final snapshot = await _firestore.collection(_workspacesCollection).get();
      final workItemSnapshot = await _firestore.collection(_workItemsCollection).get();
      final counts = <int, int>{};
      for (final doc in workItemSnapshot.docs) {
        final data = doc.data();
        final workspaceId = (data['workspaceId'] as num?)?.toInt();
        if (workspaceId != null) {
          counts.update(workspaceId, (value) => value + 1, ifAbsent: () => 1);
        }
      }

      final lowerQuery = query.toLowerCase();
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            final id = (data['id'] as num).toInt();
            return JiraSpace(
              id: id,
              name: data['title'] as String? ?? '',
              key: data['subtitle'] as String? ?? '',
              template: data['template'] as String? ?? '看板',
              issueCount: counts[id] ?? 0,
              avatar: buildSpaceAvatar('${data['subtitle'] ?? ''}${data['title'] ?? ''}'),
            );
          })
          .where((space) =>
              space.name.toLowerCase().contains(lowerQuery) ||
              space.key.toLowerCase().contains(lowerQuery))
          .toList(growable: false);
    });
  }

  /// 更新工作区名称
  Future<void> updateWorkspace(int id, {String? name, String? key}) async {
    return _guard(() async {
      await _ensureSeedData();
      final data = <String, dynamic>{};
      if (name != null) data['title'] = name;
      if (key != null) data['subtitle'] = key;
      await _firestore.collection(_workspacesCollection).doc('$id').update(data);
    });
  }

  /// 删除工作区（级联删除关联工作项）
  Future<void> deleteWorkspace(int id) async {
    return _guard(() async {
      await _ensureSeedData();
      final workItems = await _firestore
          .collection(_workItemsCollection)
          .where('workspaceId', isEqualTo: id)
          .get();
      final batch = _firestore.batch();
      for (final doc in workItems.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_firestore.collection(_workspacesCollection).doc('$id'));
      await batch.commit();
    });
  }

  /// 创建待办事项（简化版）
  Future<WorkItemResponse> createBacklogItem({
    required int workspaceId,
    required String summary,
    String? description,
  }) async {
    return createWorkItem(WorkItemCreateRequest(
      workspaceId: workspaceId,
      workTypeId: 1,
      summary: summary,
      reporterId: 1,
      bucket: WorkItemBucket.backlog,
      status: WorkItemStatus.todo,
      description: description,
    ));
  }

  Future<WorkItemResponse> createWorkItem(WorkItemCreateRequest payload) async {
    return _guard(() async {
      await _ensureSeedData();
      final summary = payload.summary.trim();
      if (summary.isEmpty) {
        throw const WorkItemApiException('创建失败，摘要不能为空。');
      }

      final workspace = await _loadLookupById(_workspacesCollection, payload.workspaceId, 'workspace');
      final workType = await _loadLookupById(_workTypesCollection, payload.workTypeId, 'work type');
      final reporter = await _loadLookupById(_usersCollection, payload.reporterId, 'reporter');
      final assignee = await _loadOptionalLookupById(_usersCollection, payload.assigneeId, 'assignee');
      final parent = await _loadOptionalParentItem(payload.parentId);
      final team = await _loadOptionalLookupById(_teamsCollection, payload.teamId, 'team');

      final selectedLabels = await _loadLabels(payload.labelIds);
      final createdLabels = await _createMissingLabels(payload.newLabelNames);
      final labels = [...selectedLabels, ...createdLabels];

      final workItemId = await _nextId('workItems');
      final workspaceKey = workspace.subtitle?.trim().toUpperCase() ?? '';
      if (workspaceKey.isEmpty) {
        throw const WorkItemApiException('空间 Key 不能为空。');
      }
      final workItemKey = '$workspaceKey-$workItemId';
      final now = DateTime.now();
      final response = WorkItemResponse(
        id: workItemId,
        summary: summary,
        key: workItemKey,
        description: _normalizeOptionalText(payload.description),
        workspace: workspace,
        workType: workType,
        reporter: reporter,
        bucket: payload.bucket,
        status: payload.status,
        assignee: assignee,
        parent: parent,
        team: team,
        dueDate: payload.dueDate,
        startDate: payload.startDate,
        createdAt: now,
        lastViewedAt: now,
        labels: labels,
        attachments: payload.attachments,
      );

      final document = {
        ...response.toMap(),
        'workspaceId': workspace.id,
        'workTypeId': workType.id,
        'reporterId': reporter.id,
        'assigneeId': assignee?.id,
        'parentId': parent?.id,
        'teamId': team?.id,
        'labelIds': labels.map((item) => item.id).toList(),
        'createdBy': _currentUid,
        'createdAt': FieldValue.serverTimestamp(),
        'lastViewedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection(_workItemsCollection).doc('$workItemId').set(document);
      return response;
    });
  }

  Future<T> _guard<T>(
    Future<T> Function() action,
  ) async {
    try {
      return await action();
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('WorkItemApi FirebaseException: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw WorkItemApiException(
        error.message ?? '请求失败，请检查 Firebase 配置和网络连接。',
      );
    } catch (error, stackTrace) {
      debugPrint('WorkItemApi unknown error: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw WorkItemApiException('$error');
    }
  }

  Future<void> _ensureSeedData() async {
    final bootstrapRef = _firestore.collection(_metaCollection).doc('bootstrap');
    final snapshot = await bootstrapRef.get();
    if (snapshot.exists) {
      return;
    }

    await _firestore.runTransaction((transaction) async {
      final current = await transaction.get(bootstrapRef);
      if (current.exists) {
        return;
      }

      final countersRef = _firestore.collection(_metaCollection).doc('counters');
      transaction.set(countersRef, {
        'workspaces': 0,
        'workTypes': 3,
        'users': 2,
        'teams': 1,
        'labels': 0,
        'workItems': 0,
        'feedback': 0,
      });
      transaction.set(bootstrapRef, {
        'seededAt': FieldValue.serverTimestamp(),
      });

      _seedLookup(transaction, _workTypesCollection, const LookupOption(id: 1, title: '任务', subtitle: 'Task'));
      _seedLookup(transaction, _workTypesCollection, const LookupOption(id: 2, title: '缺陷', subtitle: 'Bug'));
      _seedLookup(transaction, _workTypesCollection, const LookupOption(id: 3, title: '故事', subtitle: 'Story'));
      if (_currentUid != null) {
        _seedLookup(transaction, _usersCollection, LookupOption(id: 1, title: _currentUid, subtitle: _currentUid));
      } else {
        _seedLookup(transaction, _usersCollection, const LookupOption(id: 1, title: 'User 1', subtitle: 'user1@example.com'));
        _seedLookup(transaction, _usersCollection, const LookupOption(id: 2, title: 'User 2', subtitle: 'user2@example.com'));
      }
      _seedLookup(transaction, _teamsCollection, const LookupOption(id: 1, title: 'Default Team', subtitle: 'team-1'));
    });
  }

  Future<List<LookupOption>> _loadLookupCollection(String collection) async {
    final snapshot = await _firestore.collection(collection).orderBy('id').get();
    return snapshot.docs
        .map((doc) => LookupOption.fromMap(Map<String, dynamic>.from(doc.data())))
        .toList(growable: false);
  }

  Future<LookupOption> _loadLookupById(
    String collection,
    int id,
    String label,
  ) async {
    final snapshot = await _firestore.collection(collection).doc('$id').get();
    if (!snapshot.exists || snapshot.data() == null) {
      throw WorkItemApiException('找不到对应的 $label。');
    }
    return LookupOption.fromMap(Map<String, dynamic>.from(snapshot.data()!));
  }

  Future<LookupOption?> _loadOptionalLookupById(
    String collection,
    int? id,
    String label,
  ) async {
    if (id == null) {
      return null;
    }
    return _loadLookupById(collection, id, label);
  }

  Future<LookupOption?> _loadOptionalParentItem(int? id) async {
    if (id == null) {
      return null;
    }
    final snapshot = await _firestore.collection(_workItemsCollection).doc('$id').get();
    if (!snapshot.exists || snapshot.data() == null) {
      throw const WorkItemApiException('找不到对应的父项。');
    }
    final data = snapshot.data()!;
    return LookupOption(
      id: (data['id'] as num).toInt(),
      title: data['summary'] as String? ?? '',
      subtitle: data['key'] as String?,
    );
  }

  Future<List<LookupOption>> _loadLabels(List<int> ids) async {
    final labels = <LookupOption>[];
    for (final id in ids) {
      labels.add(await _loadLookupById(_labelsCollection, id, 'label'));
    }
    return labels;
  }

  Future<List<LookupOption>> _createMissingLabels(List<String> names) async {
    final normalized = <String>[];
    final seen = <String>{};

    for (final raw in names) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      final key = trimmed.toLowerCase();
      if (seen.add(key)) {
        normalized.add(trimmed);
      }
    }

    if (normalized.isEmpty) {
      return const [];
    }

    final existing = await _loadLookupCollection(_labelsCollection);
    final byKey = {
      for (final item in existing) item.title.toLowerCase(): item,
    };

    final created = <LookupOption>[];
    for (final name in normalized) {
      final existingLabel = byKey[name.toLowerCase()];
      if (existingLabel != null) {
        created.add(existingLabel);
        continue;
      }

      final id = await _nextId('labels');
      final label = LookupOption(id: id, title: name, subtitle: name.toLowerCase());
      await _firestore.collection(_labelsCollection).doc('$id').set(label.toMap());
      byKey[name.toLowerCase()] = label;
      created.add(label);
    }

    return created;
  }

  Future<int> _nextId(String counterKey) async {
    final countersRef = _firestore.collection(_metaCollection).doc('counters');
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(countersRef);
      final currentValue = (snapshot.data()?[counterKey] as num?)?.toInt() ?? 0;
      final nextValue = currentValue + 1;
      transaction.set(countersRef, {counterKey: nextValue}, SetOptions(merge: true));
      return nextValue;
    });
  }

  void _seedLookup(
    Transaction transaction,
    String collection,
    LookupOption option,
  ) {
    transaction.set(_firestore.collection(collection).doc('${option.id}'), option.toMap());
  }

  bool _matchesQuery(String value, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return true;
    }
    return value.toLowerCase().contains(normalizedQuery);
  }

  String? _normalizeOptionalText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  Future<int> _countWorkspaceItems(int workspaceId) async {
    final items = await _loadWorkItemMaps(workspaceId: workspaceId);
    return items.length;
  }

  Future<List<Map<String, dynamic>>> _loadWorkItemMaps({
    int? workspaceId,
    int? limit,
    DateTime? Function(Map<String, dynamic> data)? sortBy,
  }) async {
    final snapshot = await _firestore.collection(_workItemsCollection).get();
    final items = snapshot.docs
        .map((doc) => Map<String, dynamic>.from(doc.data()))
        .where((data) => workspaceId == null || data['workspaceId'] == workspaceId)
        .toList(growable: false);
    final sorted = [...items]
      ..sort((left, right) {
        final leftDate = sortBy?.call(left) ?? _asDateTime(left['createdAt']);
        final rightDate = sortBy?.call(right) ?? _asDateTime(right['createdAt']);
        final dateCompare = (rightDate ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(leftDate ?? DateTime.fromMillisecondsSinceEpoch(0));
        if (dateCompare != 0) {
          return dateCompare;
        }
        return ((right['id'] as num?)?.toInt() ?? 0).compareTo((left['id'] as num?)?.toInt() ?? 0);
      });
    if (limit == null || sorted.length <= limit) {
      return sorted;
    }
    return sorted.take(limit).toList(growable: false);
  }

  IssueSummary _issueSummaryFromWorkItem(Map<String, dynamic> data) {
    final workspace = Map<String, dynamic>.from(
      data['workspace'] as Map? ?? const <String, dynamic>{},
    );
    final status = _statusFromData(data);
    final bucket = _bucketFromData(data);
    return IssueSummary(
      id: (data['id'] as num?)?.toInt(),
      title: data['summary'] as String? ?? '',
      key: data['key'] as String? ?? '',
      subtitle: workspace['title'] as String?,
      status: workItemStatusLabel(status),
      assigneeInitials: 'MT',
      icon: bucket == WorkItemBucket.sprint
          ? Icons.view_kanban_rounded
          : Icons.check_box_outlined,
      iconBackgroundColor: bucket == WorkItemBucket.sprint
          ? const Color(0xFFE9D5FF)
          : const Color(0xFFD8E7FF),
      iconColor: bucket == WorkItemBucket.sprint
          ? const Color(0xFF8E4BC3)
          : const Color(0xFF0C66E4),
      statusKey: status,
      bucket: bucket,
      workspaceId: (data['workspaceId'] as num?)?.toInt(),
      startDate: _asDateTime(data['startDate']),
      dueDate: _asDateTime(data['dueDate']),
    );
  }

  WorkItemStatus _statusFromData(Map<String, dynamic> data) {
    final raw = data['status'] as String?;
    return WorkItemStatus.values.firstWhere(
      (item) => item.name == raw,
      orElse: () => WorkItemStatus.todo,
    );
  }

  WorkItemBucket _bucketFromData(Map<String, dynamic> data) {
    final raw = data['bucket'] as String?;
    return WorkItemBucket.values.firstWhere(
      (item) => item.name == raw,
      orElse: () => WorkItemBucket.backlog,
    );
  }

  bool _isWithinLastDays(DateTime? value, int days) {
    if (value == null) {
      return false;
    }
    final now = DateTime.now();
    return value.isAfter(now.subtract(Duration(days: days)));
  }

  bool _isWithinNextDays(DateTime? value, int days) {
    if (value == null) {
      return false;
    }
    final now = DateTime.now();
    return value.isAfter(now) && value.isBefore(now.add(Duration(days: days)));
  }

  String _relativeTimeLabel(DateTime? value) {
    if (value == null) {
      return '刚刚';
    }
    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) {
      return '刚刚';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes} 分钟前';
    }
    if (diff.inDays < 1) {
      return '${diff.inHours} 小时前';
    }
    return '${diff.inDays} 天前';
  }

  DateTime? _asDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

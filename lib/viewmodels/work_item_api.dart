import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ottersync/viewmodels/jira_models.dart';
import 'package:ottersync/viewmodels/workspace_access.dart';
import 'package:ottersync/viewmodels/work_item_models.dart';

class WorkItemApiException implements Exception {
  const WorkItemApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class WorkItemApi {
  WorkItemApi({
    FirebaseFirestore? firestore,
    String? currentUid,
    String? currentEmail,
  })
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _currentUid = currentUid ?? _defaultUid,
      _currentEmail = currentEmail ?? _defaultEmail;

  final FirebaseFirestore _firestore;
  final String? _currentUid;
  final String? _currentEmail;

  static String? _defaultUid;
  static String? _defaultEmail;

  /// Sets the default UID for all WorkItemApi instances.
  /// Called once after authentication is confirmed.
  static void init({required String uid, String? email}) {
    _defaultUid = uid;
    _defaultEmail = _normalizeEmail(email);
  }

  /// Clears the default UID on sign-out.
  static void clear() {
    _defaultUid = null;
    _defaultEmail = null;
  }

  static const _metaCollection = '_meta';
  static const _workspacesCollection = 'workspaces';
  static const _workTypesCollection = 'workTypes';
  static const _usersCollection = 'users';
  static const _teamsCollection = 'teams';
  static const _labelsCollection = 'labels';
  static const _workItemsCollection = 'workItems';
  static const _sprintsCollection = 'sprints';
  static const _workspaceInvitesCollection = 'workspaceInvites';
  static const _feedbackCollectionName = 'feedback';
  CollectionReference get _feedbackCollection =>
      _firestore.collection(_feedbackCollectionName);
  CollectionReference get _recentViewsCollection =>
      _firestore.collection('recentViews');
  CollectionReference get _notificationsCollection =>
      _firestore.collection('notifications');

  Future<List<JiraSpace>> listSpaces() async {
    return _guard(() async {
      await _ensureSeedData();
      final workspaceMaps = await _loadVisibleWorkspaceMaps();
      final visibleWorkspaceIds = workspaceMaps
          .map((data) => (data['id'] as num?)?.toInt())
          .whereType<int>()
          .toSet();
      final counts = <int, int>{};

      for (final data in await _loadWorkItemMaps()) {
        final workspaceId = (data['workspaceId'] as num?)?.toInt();
        if (workspaceId != null && visibleWorkspaceIds.contains(workspaceId)) {
          counts.update(workspaceId, (value) => value + 1, ifAbsent: () => 1);
        }
      }

      return workspaceMaps.map((data) {
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
        'ownerUid': _requireCurrentUid(),
        'memberUids': [_requireCurrentUid()],
        'invitedEmails': payload.invitedEmails
            .map(_normalizeEmail)
            .whereType<String>()
            .toList(growable: false),
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
      if (!_canAccessWorkspace(data)) {
        throw const WorkItemApiException('你没有访问该空间的权限。');
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

  Future<void> inviteWorkspaceMember({
    required int workspaceId,
    required String email,
  }) async {
    return _guard(() async {
      await _ensureSeedData();
      final normalizedEmail = _normalizeEmail(email);
      if (normalizedEmail == null) {
        throw const WorkItemApiException('请输入有效的邀请邮箱。');
      }

      final workspaceRef = _firestore.collection(_workspacesCollection).doc('$workspaceId');
      final workspaceSnapshot = await workspaceRef.get();
      final workspace = workspaceSnapshot.data();
      if (!workspaceSnapshot.exists || workspace == null) {
        throw const WorkItemApiException('空间不存在。');
      }
      if (workspace['ownerUid'] != _requireCurrentUid()) {
        throw const WorkItemApiException('只有空间创建者可以邀请成员。');
      }

      final existingInvite = await _firestore
          .collection(_workspaceInvitesCollection)
          .where('workspaceId', isEqualTo: workspaceId)
          .where('invitedEmail', isEqualTo: normalizedEmail)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (existingInvite.docs.isNotEmpty) {
        throw const WorkItemApiException('该成员已有待处理邀请。');
      }

      final inviteRef = _firestore.collection(_workspaceInvitesCollection).doc();
      await workspaceRef.update({
        'invitedEmails': FieldValue.arrayUnion([normalizedEmail]),
      });
      await inviteRef.set({
        'id': inviteRef.id,
        'workspaceId': workspaceId,
        'workspaceName': workspace['title'] as String? ?? '',
        'workspaceKey': workspace['subtitle'] as String? ?? '',
        'inviterUid': _requireCurrentUid(),
        'invitedEmail': normalizedEmail,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<List<WorkspaceInvite>> listPendingWorkspaceInvites() async {
    return _guard(() async {
      await _ensureSeedData();
      final email = _currentEmail;
      if (email == null || email.isEmpty) {
        return const [];
      }

      final snapshot = await _firestore
          .collection(_workspaceInvitesCollection)
          .where('invitedEmail', isEqualTo: email)
          .where('status', isEqualTo: 'pending')
          .get();
      final invites = snapshot.docs
          .map((doc) => WorkspaceInvite.fromMap(Map<String, dynamic>.from(doc.data())))
          .toList(growable: false);
      invites.sort((left, right) {
        final leftDate = left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final rightDate = right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return rightDate.compareTo(leftDate);
      });
      return invites;
    });
  }

  Future<void> acceptWorkspaceInvite(String inviteId) async {
    return _guard(() async {
      await _ensureSeedData();
      final inviteRef = _firestore.collection(_workspaceInvitesCollection).doc(inviteId);
      final inviteSnapshot = await inviteRef.get();
      final inviteData = inviteSnapshot.data();
      if (!inviteSnapshot.exists || inviteData == null) {
        throw const WorkItemApiException('邀请不存在。');
      }
      final invite = WorkspaceInvite.fromMap(Map<String, dynamic>.from(inviteData));
      if (invite.invitedEmail != _currentEmail || invite.status != 'pending') {
        throw const WorkItemApiException('邀请不存在或已处理。');
      }

      final uid = _requireCurrentUid();
      final workspaceRef = _firestore.collection(_workspacesCollection).doc('${invite.workspaceId}');
      final batch = _firestore.batch();
      batch.update(workspaceRef, {
        'memberUids': FieldValue.arrayUnion([uid]),
        'invitedEmails': FieldValue.arrayRemove([invite.invitedEmail]),
      });
      batch.update(inviteRef, {
        'status': 'accepted',
        'acceptedByUid': uid,
        'respondedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();

      await _createNotification(
        recipientUid: uid,
        title: '你已加入新空间',
        description: '${invite.workspaceKey} · ${invite.workspaceName}',
        route: '/space-details/${invite.workspaceId}',
        workspaceId: invite.workspaceId,
      );
    });
  }

  Future<void> declineWorkspaceInvite(String inviteId) async {
    return _guard(() async {
      await _ensureSeedData();
      final inviteRef = _firestore.collection(_workspaceInvitesCollection).doc(inviteId);
      final inviteSnapshot = await inviteRef.get();
      final inviteData = inviteSnapshot.data();
      if (!inviteSnapshot.exists || inviteData == null) {
        throw const WorkItemApiException('邀请不存在。');
      }
      final invite = WorkspaceInvite.fromMap(Map<String, dynamic>.from(inviteData));
      if (invite.invitedEmail != _currentEmail || invite.status != 'pending') {
        throw const WorkItemApiException('邀请不存在或已处理。');
      }

      final workspaceRef = _firestore.collection(_workspacesCollection).doc('${invite.workspaceId}');
      final batch = _firestore.batch();
      batch.update(inviteRef, {
        'status': 'declined',
        'declinedByUid': _requireCurrentUid(),
        'respondedAt': FieldValue.serverTimestamp(),
      });
      batch.update(workspaceRef, {
        'invitedEmails': FieldValue.arrayRemove([invite.invitedEmail]),
      });
      await batch.commit();
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
      final data = Map<String, dynamic>.from(doc.data() as Map);
      await _ensureCanAccessWorkspaceId(
        (data['workspaceId'] as num?)?.toInt(),
      );
      return WorkItemResponse.fromMap(data);
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

  /// 更新工作项任意字段（仅传入需要更新的）
  Future<void> updateWorkItemFields(
    int id, {
    String? summary,
    String? description,
    DateTime? startDate,
    DateTime? dueDate,
    bool clearStartDate = false,
    bool clearDueDate = false,
    int? assigneeId,
    bool clearAssignee = false,
    int? teamId,
    bool clearTeam = false,
    int? sprintId,
    bool clearSprint = false,
    String? priority,
    bool clearPriority = false,
    int? parentId,
    bool clearParent = false,
  }) async {
    return _guard(() async {
      await _ensureSeedData();
      await _ensureCanEditWorkItem(id);
      final patch = <String, dynamic>{};
      if (summary != null) patch['summary'] = summary;
      if (description != null) patch['description'] = description;
      if (startDate != null) patch['startDate'] = startDate;
      if (clearStartDate) patch['startDate'] = null;
      if (dueDate != null) patch['dueDate'] = dueDate;
      if (clearDueDate) patch['dueDate'] = null;
      if (assigneeId != null) {
        final lookup =
            await _loadLookupById(_usersCollection, assigneeId, 'assignee');
        patch['assigneeId'] = assigneeId;
        patch['assignee'] = lookup.toMap();
      } else if (clearAssignee) {
        patch['assigneeId'] = null;
        patch['assignee'] = null;
      }
      if (teamId != null) {
        final lookup = await _loadLookupById(_teamsCollection, teamId, 'team');
        patch['teamId'] = teamId;
        patch['team'] = lookup.toMap();
      } else if (clearTeam) {
        patch['teamId'] = null;
        patch['team'] = null;
      }
      if (sprintId != null) {
        final sprint = await getSprintById(sprintId);
        if (sprint == null) {
          throw const WorkItemApiException('找不到对应的冲刺。');
        }
        patch['sprintId'] = sprintId;
        patch['sprint'] = sprint.toLookup().toMap();
        patch['bucket'] = WorkItemBucket.sprint.name;
      } else if (clearSprint) {
        patch['sprintId'] = null;
        patch['sprint'] = null;
        patch['bucket'] = WorkItemBucket.backlog.name;
      }
      if (priority != null) patch['priority'] = priority;
      if (clearPriority) patch['priority'] = null;
      if (parentId != null) {
        final parent = await _loadOptionalParentItem(parentId);
        patch['parentId'] = parentId;
        patch['parent'] = parent?.toMap();
      } else if (clearParent) {
        patch['parentId'] = null;
        patch['parent'] = null;
      }
      patch['updatedAt'] = FieldValue.serverTimestamp();
      if (patch.length == 1) return; // only updatedAt
      await _firestore.collection(_workItemsCollection).doc('$id').update(patch);
      await _notifyWorkItemParticipants(
        id,
        title: '工作项已更新',
        descriptionPrefix: '字段发生变化',
      );
    });
  }

  /// 更新工作项截止日期（dueDate=null 表示清除）
  Future<void> updateWorkItemDueDate(int id, DateTime? dueDate) async {
    return _guard(() async {
      await _ensureSeedData();
      await _ensureCanEditWorkItem(id);
      await _firestore.collection(_workItemsCollection).doc('$id').update({
        'dueDate': dueDate,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _notifyWorkItemParticipants(
        id,
        title: '工作项日期已变更',
        descriptionPrefix: '截止日期发生变化',
      );
    });
  }

  /// 更新工作项状态
  Future<void> updateWorkItemStatus(int id, WorkItemStatus status) async {
    return _guard(() async {
      await _ensureSeedData();
      await _ensureCanEditWorkItem(id);
      await _firestore.collection(_workItemsCollection).doc('$id').update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _notifyWorkItemParticipants(
        id,
        title: '工作项状态已变更',
        descriptionPrefix: '状态更新为 ${workItemStatusLabel(status)}',
      );
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
      await _ensureCanEditWorkItem(workItemId);
      final docId = '${_currentUid}_$workItemId';
      await _recentViewsCollection.doc(docId).set({
        'userId': _currentUid,
        'targetId': workItemId,
        'targetKey': workItemKey,
        'targetTitle': workItemTitle,
        'viewedAt': FieldValue.serverTimestamp(),
      });
      await _firestore
          .collection(_workItemsCollection)
          .doc('$workItemId')
          .update({'lastViewedAt': FieldValue.serverTimestamp()});
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
      final uid = _requireCurrentUid();
      final snapshot = await _notificationsCollection
          .where('recipientUid', isEqualTo: uid)
          .get();
      final notifications = snapshot.docs
          .map((doc) => Map<String, dynamic>.from(doc.data() as Map))
          .where((data) => shouldNotifyUser(data, uid: uid))
          .toList(growable: false);
      notifications.sort((left, right) {
        final leftDate = _asDateTime(left['createdAt']);
        final rightDate = _asDateTime(right['createdAt']);
        return (rightDate ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(leftDate ?? DateTime.fromMillisecondsSinceEpoch(0));
      });
      return notifications
          .take(limit)
          .map((data) => NotificationItem(
                title: data['title'] as String? ?? '通知',
                description: data['description'] as String? ?? '',
                route: data['route'] as String?,
                workItemId: (data['workItemId'] as num?)?.toInt(),
              ))
          .toList(growable: false);
    });
  }

  /// 实时订阅当前用户的通知。
  ///
  /// 通过 Firestore [snapshots] 监听 notifications 集合，
  /// 服务端写入新事件后会自动推送到客户端，无需轮询或手动刷新。
  Stream<List<NotificationItem>> watchNotifications({int limit = 30}) {
    final uid = _currentUid;
    if (uid == null || uid.isEmpty) {
      return Stream.value(const []);
    }
    return _notificationsCollection
        .where('recipientUid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => Map<String, dynamic>.from(doc.data() as Map))
          .where((data) => shouldNotifyUser(data, uid: uid))
          .toList(growable: false);
      notifications.sort((left, right) {
        final leftDate = _asDateTime(left['createdAt']);
        final rightDate = _asDateTime(right['createdAt']);
        return (rightDate ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(leftDate ?? DateTime.fromMillisecondsSinceEpoch(0));
      });
      return notifications
          .take(limit)
          .map((data) => NotificationItem(
                title: data['title'] as String? ?? '通知',
                description: data['description'] as String? ?? '',
                route: data['route'] as String?,
                workItemId: (data['workItemId'] as num?)?.toInt(),
              ))
          .toList(growable: false);
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

  Future<List<Sprint>> listSprints({int? workspaceId}) async {
    return _guard(() async {
      await _ensureSeedData();
      final visibleWorkspaceIds = workspaceId == null
          ? await _visibleWorkspaceIds()
          : {workspaceId};
      if (workspaceId != null) {
        await _ensureCanAccessWorkspaceId(workspaceId);
      }

      final sprints = <Sprint>[];
      for (final id in visibleWorkspaceIds) {
        final snapshot = await _firestore
            .collection(_sprintsCollection)
            .where('workspaceId', isEqualTo: id)
            .get();
        sprints.addAll(snapshot.docs
            .map((doc) => Sprint.fromMap(Map<String, dynamic>.from(doc.data()))));
      }
      sprints.sort((left, right) => left.id.compareTo(right.id));
      return sprints;
    });
  }

  Future<Sprint?> getSprintById(int id) async {
    return _guard(() async {
      await _ensureSeedData();
      final snapshot =
          await _firestore.collection(_sprintsCollection).doc('$id').get();
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      final sprint = Sprint.fromMap(Map<String, dynamic>.from(snapshot.data()!));
      await _ensureCanAccessWorkspaceId(sprint.workspaceId);
      return sprint;
    });
  }

  Future<Sprint> createSprint(SprintCreateRequest payload) async {
    return _guard(() async {
      await _ensureSeedData();
      final name = payload.name.trim();
      if (name.isEmpty) {
        throw const WorkItemApiException('请输入冲刺名称。');
      }
      await _ensureCanAccessWorkspaceId(payload.workspaceId);
      final id = await _nextId('sprints');
      final sprint = Sprint(
        id: id,
        workspaceId: payload.workspaceId,
        name: name,
        goal: payload.goal?.trim().isEmpty ?? true ? null : payload.goal!.trim(),
        status: SprintStatus.planned,
        startDate: payload.startDate,
        endDate: payload.endDate,
      );
      await _firestore
          .collection(_sprintsCollection)
          .doc('$id')
          .set(sprint.toMap());
      return sprint;
    });
  }

  Future<Sprint> updateSprintStatus(int id, SprintStatus status) async {
    return _guard(() async {
      await _ensureSeedData();
      final docRef = _firestore.collection(_sprintsCollection).doc('$id');
      final snapshot = await docRef.get();
      if (!snapshot.exists || snapshot.data() == null) {
        throw const WorkItemApiException('冲刺不存在。');
      }
      final sprint = Sprint.fromMap(Map<String, dynamic>.from(snapshot.data()!));
      await _ensureCanAccessWorkspaceId(sprint.workspaceId);
      final patch = <String, dynamic>{'status': status.name};
      if (status == SprintStatus.completed) {
        patch['completedAt'] = FieldValue.serverTimestamp();
      }
      await docRef.update(patch);
      final updated = await docRef.get();
      return Sprint.fromMap(Map<String, dynamic>.from(updated.data()!));
    });
  }

  Future<void> deleteSprint(int id) async {
    return _guard(() async {
      await _ensureSeedData();
      final sprint = await getSprintById(id);
      if (sprint == null) {
        throw const WorkItemApiException('冲刺不存在。');
      }
      final affected = await _firestore
          .collection(_workItemsCollection)
          .where('workspaceId', isEqualTo: sprint.workspaceId)
          .get();
      final batch = _firestore.batch();
      for (final doc in affected.docs) {
        final data = doc.data();
        if ((data['sprintId'] as num?)?.toInt() != id) {
          continue;
        }
        batch.update(doc.reference, {
          'sprintId': null,
          'sprint': null,
          'bucket': WorkItemBucket.backlog.name,
        });
      }
      batch.delete(_firestore.collection(_sprintsCollection).doc('$id'));
      await batch.commit();
    });
  }

  Future<List<BacklogGroup>> loadBacklogGroups(int workspaceId) async {
    return _guard(() async {
      await _ensureSeedData();
      final items = await _loadWorkItemMaps(workspaceId: workspaceId);
      final sprints = await listSprints(workspaceId: workspaceId);
      final groups = <BacklogGroup>[];

      for (final sprint in sprints) {
        if (sprint.status == SprintStatus.completed) {
          continue;
        }
        final sprintItems = items
            .where((data) => (data['sprintId'] as num?)?.toInt() == sprint.id)
            .map(_issueSummaryFromWorkItem)
            .toList(growable: false);
        final statusLabel = sprint.status == SprintStatus.active ? '进行中' : '计划中';
        groups.add(_buildBacklogGroup(
          '${sprint.name} · $statusLabel',
          sprintItems,
          sprintId: sprint.id,
        ));
      }

      final backlogItems = items
          .where((data) => (data['sprintId'] as num?) == null)
          .map(_issueSummaryFromWorkItem)
          .toList(growable: false);
      groups.add(_buildBacklogGroup('待办事项列表', backlogItems));

      return groups;
    });
  }

  BacklogGroup _buildBacklogGroup(
    String title,
    List<IssueSummary> items, {
    int? sprintId,
  }) {
    return BacklogGroup(
      title: title,
      issueCount: items.length,
      todoCount:
          items.where((item) => item.statusKey == WorkItemStatus.todo).length,
      inProgressCount: items
          .where((item) => item.statusKey == WorkItemStatus.inProgress)
          .length,
      doneCount:
          items.where((item) => item.statusKey == WorkItemStatus.done).length,
      items: items,
      sprintId: sprintId,
    );
  }

  Future<int> loadBoardItemCount(int workspaceId) async {
    final items = await loadBoardItems(workspaceId);
    return items.length;
  }

  Future<List<IssueSummary>> loadBoardItems(int workspaceId) async {
    return _guard(() async {
      await _ensureSeedData();
      final sprints = await listSprints(workspaceId: workspaceId);
      final openSprintIds = sprints
          .where((sprint) => sprint.status != SprintStatus.completed)
          .map((sprint) => sprint.id)
          .toSet();
      final items = await _loadWorkItemMaps(workspaceId: workspaceId);
      return items.where((data) {
        final sprintId = (data['sprintId'] as num?)?.toInt();
        if (sprintId != null) {
          return openSprintIds.contains(sprintId);
        }
        return _bucketFromData(data) == WorkItemBucket.sprint;
      }).map(_issueSummaryFromWorkItem).toList(growable: false);
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
      final items = await _loadWorkItemMaps();
      return items
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
        _loadVisibleWorkspaceLookups(),
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
      final maps = await _loadWorkItemMaps(workspaceId: workspaceId);
      return maps
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
      final visibleWorkspaceMaps = await _loadVisibleWorkspaceMaps();
      final visibleWorkspaceIds = visibleWorkspaceMaps
          .map((data) => (data['id'] as num?)?.toInt())
          .whereType<int>()
          .toSet();
      final counts = <int, int>{};
      for (final data in await _loadWorkItemMaps()) {
        final workspaceId = (data['workspaceId'] as num?)?.toInt();
        if (workspaceId != null && visibleWorkspaceIds.contains(workspaceId)) {
          counts.update(workspaceId, (value) => value + 1, ifAbsent: () => 1);
        }
      }

      final lowerQuery = query.toLowerCase();
      return visibleWorkspaceMaps
          .map((data) {
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
      await _ensureOwnsWorkspace(id);
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
      await _ensureOwnsWorkspace(id);
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
    int? sprintId,
  }) async {
    return _guard(() async {
      await _ensureSeedData();
      final reporter = await _ensureCurrentUserLookup();
      return createWorkItem(WorkItemCreateRequest(
        workspaceId: workspaceId,
        workTypeId: 1,
        summary: summary,
        reporterId: reporter?.id ?? 1,
        bucket: sprintId != null ? WorkItemBucket.sprint : WorkItemBucket.backlog,
        status: WorkItemStatus.todo,
        sprintId: sprintId,
        description: description,
      ));
    });
  }

  Future<WorkItemResponse> createWorkItem(WorkItemCreateRequest payload) async {
    return _guard(() async {
      await _ensureSeedData();
      final summary = payload.summary.trim();
      if (summary.isEmpty) {
        throw const WorkItemApiException('创建失败，摘要不能为空。');
      }

      final workspace = await _loadLookupById(_workspacesCollection, payload.workspaceId, 'workspace');
      final visibleWorkspaceIds = await _visibleWorkspaceIds();
      if (!visibleWorkspaceIds.contains(payload.workspaceId)) {
        throw const WorkItemApiException('你没有在该空间创建工作项的权限。');
      }
      final workType = await _loadLookupById(_workTypesCollection, payload.workTypeId, 'work type');
      final reporter = await _loadLookupById(_usersCollection, payload.reporterId, 'reporter');
      final assignee = await _loadOptionalLookupById(_usersCollection, payload.assigneeId, 'assignee');
      final parent = await _loadOptionalParentItem(payload.parentId);
      final team = await _loadOptionalLookupById(_teamsCollection, payload.teamId, 'team');

      final selectedLabels = await _loadLabels(payload.labelIds);
      final createdLabels = await _createMissingLabels(payload.newLabelNames);
      final labels = [...selectedLabels, ...createdLabels];

      Sprint? sprint;
      if (payload.sprintId != null) {
        sprint = await getSprintById(payload.sprintId!);
        if (sprint == null) {
          throw const WorkItemApiException('找不到对应的冲刺。');
        }
        if (sprint.workspaceId != payload.workspaceId) {
          throw const WorkItemApiException('该冲刺不属于当前空间。');
        }
      }
      final effectiveBucket =
          sprint != null ? WorkItemBucket.sprint : payload.bucket;

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
        bucket: effectiveBucket,
        status: payload.status,
        assignee: assignee,
        parent: parent,
        team: team,
        sprint: sprint?.toLookup(),
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
        'sprintId': sprint?.id,
        'labelIds': labels.map((item) => item.id).toList(),
        'createdBy': _currentUid,
        'createdAt': FieldValue.serverTimestamp(),
        'lastViewedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection(_workItemsCollection).doc('$workItemId').set(document);
      await _notifyWorkItemCreated(response, document);
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
    if (!snapshot.exists) {
      await _firestore.runTransaction((transaction) async {
        final current = await transaction.get(bootstrapRef);
        if (current.exists) {
          return;
        }

        final hasCurrentUser = _currentUid != null;
        final countersRef = _firestore.collection(_metaCollection).doc('counters');
        transaction.set(countersRef, {
          'workspaces': 0,
          'workTypes': 3,
          'users': hasCurrentUser ? 1 : 2,
          'teams': 1,
          'labels': 0,
          'workItems': 0,
          'sprints': 0,
          'feedback': 0,
          'notifications': 0,
        });
        transaction.set(bootstrapRef, {
          'seededAt': FieldValue.serverTimestamp(),
        });

        _seedLookup(transaction, _workTypesCollection, const LookupOption(id: 1, title: '任务', subtitle: 'Task'));
        _seedLookup(transaction, _workTypesCollection, const LookupOption(id: 2, title: '缺陷', subtitle: 'Bug'));
        _seedLookup(transaction, _workTypesCollection, const LookupOption(id: 3, title: '故事', subtitle: 'Story'));
        if (hasCurrentUser) {
          final currentUid = _currentUid;
          _seedUserLookup(
            transaction,
            id: 1,
            uid: currentUid,
            email: _currentEmail,
          );
        } else {
          _seedLookup(transaction, _usersCollection, const LookupOption(id: 1, title: 'User 1', subtitle: 'user1@example.com'));
          _seedLookup(transaction, _usersCollection, const LookupOption(id: 2, title: 'User 2', subtitle: 'user2@example.com'));
        }
        _seedLookup(transaction, _teamsCollection, const LookupOption(id: 1, title: 'Default Team', subtitle: 'team-1'));
      });
    }

    await _ensureCurrentUserLookup();
  }

  Future<List<LookupOption>> _loadLookupCollection(String collection) async {
    if (collection == _usersCollection) {
      await _ensureCurrentUserLookup();
      return _loadUserLookups();
    }
    final snapshot = await _firestore.collection(collection).orderBy('id').get();
    return snapshot.docs
        .map((doc) => LookupOption.fromMap(Map<String, dynamic>.from(doc.data())))
        .toList(growable: false);
  }

  Future<List<LookupOption>> _loadUserLookups() async {
    final snapshot = await _firestore.collection(_usersCollection).get();
    final byId = <int, LookupOption>{};
    for (final doc in snapshot.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      final id = (data['id'] as num?)?.toInt();
      if (id == null) {
        continue;
      }
      byId[id] = _userLookupFromData(data);
    }
    final users = byId.values.toList(growable: false);
    users.sort((left, right) => left.id.compareTo(right.id));
    return users;
  }

  Future<List<LookupOption>> _loadVisibleWorkspaceLookups() async {
    final workspaceMaps = await _loadVisibleWorkspaceMaps();
    return workspaceMaps
        .map((data) => LookupOption(
              id: (data['id'] as num).toInt(),
              title: data['title'] as String? ?? '',
              subtitle: data['subtitle'] as String?,
            ))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _loadVisibleWorkspaceMaps() async {
    final uid = _requireCurrentUid();
    final byId = <int, Map<String, dynamic>>{};

    Future<void> addSnapshot(QuerySnapshot snapshot) async {
      for (final doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        if (!_canAccessWorkspace(data)) {
          continue;
        }
        final id = (data['id'] as num?)?.toInt();
        if (id != null) {
          byId[id] = data;
        }
      }
    }

    await addSnapshot(await _firestore
        .collection(_workspacesCollection)
        .where('ownerUid', isEqualTo: uid)
        .get());
    await addSnapshot(await _firestore
        .collection(_workspacesCollection)
        .where('memberUids', arrayContains: uid)
        .get());

    final workspaces = byId.values.toList(growable: false);
    workspaces.sort((left, right) {
      final leftId = (left['id'] as num?)?.toInt() ?? 0;
      final rightId = (right['id'] as num?)?.toInt() ?? 0;
      return leftId.compareTo(rightId);
    });
    return workspaces;
  }

  Future<void> _ensureCanAccessWorkspaceId(int? workspaceId) async {
    if (workspaceId == null) {
      throw const WorkItemApiException('工作空间不存在。');
    }

    final snapshot = await _firestore.collection(_workspacesCollection).doc('$workspaceId').get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null || !_canAccessWorkspace(data)) {
      throw const WorkItemApiException('你没有访问该空间的权限。');
    }
  }

  Future<void> _ensureOwnsWorkspace(int workspaceId) async {
    final snapshot = await _firestore.collection(_workspacesCollection).doc('$workspaceId').get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      throw const WorkItemApiException('空间不存在。');
    }
    if (data['ownerUid'] != _requireCurrentUid()) {
      throw const WorkItemApiException('只有空间创建者可以执行该操作。');
    }
  }

  Future<Map<String, dynamic>> _loadAccessibleWorkItemData(int id) async {
    final snapshot = await _firestore.collection(_workItemsCollection).doc('$id').get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      throw const WorkItemApiException('工作项不存在。');
    }
    final item = Map<String, dynamic>.from(data);
    await _ensureCanAccessWorkspaceId((item['workspaceId'] as num?)?.toInt());
    return item;
  }

  Future<void> _ensureCanEditWorkItem(int id) async {
    await _loadAccessibleWorkItemData(id);
  }

  Future<void> _notifyWorkItemCreated(
    WorkItemResponse response,
    Map<String, dynamic> document,
  ) async {
    await _notifyParticipantsFromData(
      document,
      title: '有新的工作项',
      description: '${response.key} · ${response.summary}',
      workItemId: response.id,
      route: '/work-item/${response.id}',
      workspaceId: (document['workspaceId'] as num?)?.toInt(),
    );
  }

  Future<void> _notifyWorkItemParticipants(
    int id, {
    required String title,
    required String descriptionPrefix,
  }) async {
    final snapshot = await _firestore.collection(_workItemsCollection).doc('$id').get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return;
    }
    final key = data['key'] as String? ?? '';
    final summary = data['summary'] as String? ?? '';
    await _notifyParticipantsFromData(
      data,
      title: title,
      description: '$descriptionPrefix：$key · $summary',
      workItemId: id,
      route: '/work-item/$id',
    );
  }

  Future<void> _notifyParticipantsFromData(
    Map<String, dynamic> data, {
    required String title,
    required String description,
    int? workItemId,
    String? route,
    int? workspaceId,
  }) async {
    final recipients = <String>{};
    final createdBy = data['createdBy'] as String?;
    if (createdBy != null && createdBy.isNotEmpty) {
      recipients.add(createdBy);
    }

    await _addLookupUserUid(recipients, (data['reporterId'] as num?)?.toInt());
    await _addLookupUserUid(recipients, (data['assigneeId'] as num?)?.toInt());
    recipients.remove(_currentUid);

    workspaceId ??= (data['workspaceId'] as num?)?.toInt();
    for (final uid in recipients) {
      if (!await _userCanAccessWorkspace(uid, workspaceId)) {
        continue;
      }
      await _createNotification(
        recipientUid: uid,
        title: title,
        description: description,
        workItemId: workItemId,
        route: route,
        workspaceId: workspaceId,
      );
    }
  }

  Future<bool> _userCanAccessWorkspace(String uid, int? workspaceId) async {
    if (workspaceId == null) {
      return false;
    }
    final snapshot = await _firestore.collection(_workspacesCollection).doc('$workspaceId').get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return false;
    }
    final email = await _emailForUid(uid);
    return canAccessWorkspaceData(data, uid: uid, email: email);
  }

  Future<String?> _emailForUid(String uid) async {
    final authDoc = await _firestore.collection(_usersCollection).doc(uid).get();
    final directEmail = _normalizeEmail(authDoc.data()?['email'] as String?);
    if (directEmail != null) {
      return directEmail;
    }

    final snapshot = await _firestore
        .collection(_usersCollection)
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    return _normalizeEmail(snapshot.docs.first.data()['email'] as String?);
  }

  Future<void> _addLookupUserUid(Set<String> recipients, int? userId) async {
    if (userId == null) {
      return;
    }
    final uid = await _uidForLookupUserId(userId);
    if (uid != null && uid.isNotEmpty) {
      recipients.add(uid);
    }
  }

  Future<String?> _uidForLookupUserId(int userId) async {
    final byId = await _firestore.collection(_usersCollection).doc('$userId').get();
    final directUid = byId.data()?['uid'] as String?;
    if (directUid != null && directUid.isNotEmpty) {
      return directUid;
    }

    final snapshot = await _firestore
        .collection(_usersCollection)
        .where('id', isEqualTo: userId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    return snapshot.docs.first.data()['uid'] as String?;
  }

  Future<void> _createNotification({
    required String recipientUid,
    required String title,
    required String description,
    int? workItemId,
    String? route,
    int? workspaceId,
  }) async {
    final id = await _nextId('notifications');
    await _notificationsCollection.doc('$id').set({
      'id': id,
      'recipientUid': recipientUid,
      'senderUid': _currentUid,
      'title': title,
      'description': description,
      'workItemId': workItemId,
      'workspaceId': workspaceId,
      'route': route,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<LookupOption> _loadLookupById(
    String collection,
    int id,
    String label,
  ) async {
    if (collection == _usersCollection) {
      final user = await _loadUserLookupById(id);
      if (user == null) {
        throw WorkItemApiException('找不到对应的 $label。');
      }
      return user;
    }
    final snapshot = await _firestore.collection(collection).doc('$id').get();
    if (!snapshot.exists || snapshot.data() == null) {
      throw WorkItemApiException('找不到对应的 $label。');
    }
    return LookupOption.fromMap(Map<String, dynamic>.from(snapshot.data()!));
  }

  Future<LookupOption?> _loadUserLookupById(int id) async {
    await _ensureCurrentUserLookup();
    final direct = await _firestore.collection(_usersCollection).doc('$id').get();
    final directData = direct.data();
    if (direct.exists && directData != null && directData['id'] is num) {
      return _userLookupFromData(Map<String, dynamic>.from(directData));
    }

    final snapshot = await _firestore
        .collection(_usersCollection)
        .where('id', isEqualTo: id)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    return _userLookupFromData(Map<String, dynamic>.from(snapshot.docs.first.data()));
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

  void _seedUserLookup(
    Transaction transaction, {
    required int id,
    required String uid,
    String? email,
  }) {
    final normalizedEmail = _normalizeEmail(email) ?? uid;
    transaction.set(_firestore.collection(_usersCollection).doc('$id'), {
      'id': id,
      'uid': uid,
      'title': normalizedEmail,
      'subtitle': normalizedEmail,
      'email': normalizedEmail,
    });
  }

  Future<LookupOption?> _ensureCurrentUserLookup() async {
    final uid = _currentUid;
    if (uid == null || uid.isEmpty) {
      return null;
    }

    final existing = await _firestore
        .collection(_usersCollection)
        .where('uid', isEqualTo: uid)
        .get();
    final existingUser = existing.docs
        .map((doc) => Map<String, dynamic>.from(doc.data()))
        .where((data) => data['id'] is num)
        .cast<Map<String, dynamic>?>()
        .firstWhere((data) => data != null, orElse: () => null);
    if (existingUser != null) {
      final data = existingUser;
      await _syncAuthUserRecord(data);
      return _userLookupFromData(data);
    }

    final id = await _nextId('users');
    final normalizedEmail = _normalizeEmail(_currentEmail) ?? uid;
    await _firestore.collection(_usersCollection).doc('$id').set({
      'id': id,
      'uid': uid,
      'title': normalizedEmail,
      'subtitle': normalizedEmail,
      'email': normalizedEmail,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _syncAuthUserRecord({
      'id': id,
      'uid': uid,
      'email': normalizedEmail,
      'title': normalizedEmail,
      'subtitle': normalizedEmail,
    });
    return LookupOption(id: id, title: normalizedEmail, subtitle: normalizedEmail);
  }

  Future<void> _syncAuthUserRecord(Map<String, dynamic> data) async {
    final uid = data['uid'] as String?;
    if (uid == null || uid.isEmpty) {
      return;
    }

    final normalizedEmail = _normalizeEmail(data['email'] as String?) ??
        _normalizeEmail(_currentEmail);
    await _firestore.collection(_usersCollection).doc(uid).set({
      'uid': uid,
      if (data['id'] is num) 'id': (data['id'] as num).toInt(),
      'email': ?normalizedEmail,
      if (data['title'] is String) 'username': data['title'],
    }, SetOptions(merge: true));
  }

  LookupOption _userLookupFromData(Map<String, dynamic> data) {
    final id = (data['id'] as num).toInt();
    final email = _normalizeEmail(data['email'] as String?) ??
        _normalizeEmail(data['subtitle'] as String?);
    final title = (data['title'] as String?) ??
        (data['username'] as String?) ??
        email ??
        (data['uid'] as String?) ??
        '';
    return LookupOption(
      id: id,
      title: title,
      subtitle: email ?? data['subtitle'] as String?,
    );
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
    final visibleWorkspaceIds = workspaceId == null
        ? await _visibleWorkspaceIds()
        : {workspaceId};
    if (workspaceId != null) {
      await _ensureCanAccessWorkspaceId(workspaceId);
    }
    final items = <Map<String, dynamic>>[];
    for (final id in visibleWorkspaceIds) {
      final snapshot = await _firestore
          .collection(_workItemsCollection)
          .where('workspaceId', isEqualTo: id)
          .get();
      items.addAll(snapshot.docs
          .map((doc) => Map<String, dynamic>.from(doc.data())));
    }
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
      sprintId: (data['sprintId'] as num?)?.toInt(),
      priority: data['priority'] as String?,
      workTypeId: (data['workTypeId'] as num?)?.toInt(),
      workTypeTitle: () {
        final wt = data['workType'];
        if (wt is Map) {
          return wt['title'] as String?;
        }
        return null;
      }(),
      lastViewedAt: _asDateTime(data['lastViewedAt']),
      createdAt: _asDateTime(data['createdAt']),
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

  bool _canAccessWorkspace(Map<String, dynamic> data) {
    return canAccessWorkspaceData(data, uid: _currentUid, email: _currentEmail);
  }

  String _requireCurrentUid() {
    final uid = _currentUid;
    if (uid == null || uid.isEmpty) {
      throw const WorkItemApiException('请先登录。');
    }
    return uid;
  }

  Future<Set<int>> _visibleWorkspaceIds() async {
    final workspaces = await _loadVisibleWorkspaceMaps();
    return workspaces
        .map((data) => (data['id'] as num?)?.toInt())
        .whereType<int>()
        .toSet();
  }
}

String? _normalizeEmail(String? value) {
  final normalized = value?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty || !normalized.contains('@')) {
    return null;
  }
  return normalized;
}

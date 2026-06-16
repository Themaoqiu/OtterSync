import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ottersync/services/app_event_bus.dart';
import 'package:ottersync/services/workspace_access.dart';
import 'package:ottersync/viewmodels/jira_models.dart';
import 'package:ottersync/viewmodels/work_item_models.dart';

part 'workspace_service.dart';
part 'work_item_operations_service.dart';
part 'sprint_service.dart';
part 'lookup_service.dart';
part 'notification_service.dart';
part 'feedback_service.dart';
part 'recent_view_service.dart';

class WorkItemServiceException implements Exception {
  const WorkItemServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class WorkItemService {
  WorkItemService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    String? currentUid,
    String? currentEmail,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _overrideUid = currentUid,
       _overrideEmail = _normalizeEmail(currentEmail);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Optional fixed identity for tests. In production both are null and the
  // current user is resolved live from FirebaseAuth on every access, so a
  // long-lived instance never serves a previous account's data.
  final String? _overrideUid;
  final String? _overrideEmail;

  String? get _currentUid => _overrideUid ?? _auth.currentUser?.uid;
  String? get _currentEmail =>
      _overrideEmail ?? _normalizeEmail(_auth.currentUser?.email);

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

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('WorkItemService FirebaseException: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw WorkItemServiceException(
        error.message ?? '请求失败，请检查 Firebase 配置和网络连接。',
      );
    } catch (error, stackTrace) {
      debugPrint('WorkItemService unknown error: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw WorkItemServiceException('$error');
    }
  }

  Future<void> _ensureSeedData() async {
    final bootstrapRef = _firestore
        .collection(_metaCollection)
        .doc('bootstrap');
    final snapshot = await bootstrapRef.get();
    if (!snapshot.exists) {
      await _firestore.runTransaction((transaction) async {
        final current = await transaction.get(bootstrapRef);
        if (current.exists) {
          return;
        }

        final hasCurrentUser = _currentUid != null;
        final countersRef = _firestore
            .collection(_metaCollection)
            .doc('counters');
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

        _seedLookup(
          transaction,
          _workTypesCollection,
          const LookupOption(id: 1, title: '任务', subtitle: 'Task'),
        );
        _seedLookup(
          transaction,
          _workTypesCollection,
          const LookupOption(id: 2, title: '缺陷', subtitle: 'Bug'),
        );
        _seedLookup(
          transaction,
          _workTypesCollection,
          const LookupOption(id: 3, title: '故事', subtitle: 'Story'),
        );
        final currentUid = _currentUid;
        if (currentUid != null) {
          _seedUserLookup(
            transaction,
            id: 1,
            uid: currentUid,
            email: _currentEmail,
          );
        } else {
          _seedLookup(
            transaction,
            _usersCollection,
            const LookupOption(
              id: 1,
              title: 'User 1',
              subtitle: 'user1@example.com',
            ),
          );
          _seedLookup(
            transaction,
            _usersCollection,
            const LookupOption(
              id: 2,
              title: 'User 2',
              subtitle: 'user2@example.com',
            ),
          );
        }
        _seedLookup(
          transaction,
          _teamsCollection,
          const LookupOption(id: 1, title: 'Default Team', subtitle: 'team-1'),
        );
      });
    }

    await _ensureCurrentUserLookup();
  }

  Future<List<LookupOption>> _loadLookupCollection(String collection) async {
    if (collection == _usersCollection) {
      await _ensureCurrentUserLookup();
      return _loadUserLookups();
    }
    final snapshot = await _firestore
        .collection(collection)
        .orderBy('id')
        .get();
    return snapshot.docs
        .map(
          (doc) => LookupOption.fromMap(Map<String, dynamic>.from(doc.data())),
        )
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
        .map(
          (data) => LookupOption(
            id: (data['id'] as num).toInt(),
            title: data['title'] as String? ?? '',
            subtitle: data['subtitle'] as String?,
          ),
        )
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

    await addSnapshot(
      await _firestore
          .collection(_workspacesCollection)
          .where('ownerUid', isEqualTo: uid)
          .get(),
    );
    await addSnapshot(
      await _firestore
          .collection(_workspacesCollection)
          .where('memberUids', arrayContains: uid)
          .get(),
    );

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
      throw const WorkItemServiceException('工作空间不存在。');
    }

    final snapshot = await _firestore
        .collection(_workspacesCollection)
        .doc('$workspaceId')
        .get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null || !_canAccessWorkspace(data)) {
      throw const WorkItemServiceException('你没有访问该空间的权限。');
    }
  }

  Future<void> _ensureOwnsWorkspace(int workspaceId) async {
    final snapshot = await _firestore
        .collection(_workspacesCollection)
        .doc('$workspaceId')
        .get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      throw const WorkItemServiceException('空间不存在。');
    }
    if (data['ownerUid'] != _requireCurrentUid()) {
      throw const WorkItemServiceException('只有空间创建者可以执行该操作。');
    }
  }

  Future<Map<String, dynamic>> _loadAccessibleWorkItemData(int id) async {
    final snapshot = await _firestore
        .collection(_workItemsCollection)
        .doc('$id')
        .get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      throw const WorkItemServiceException('工作项不存在。');
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
    final snapshot = await _firestore
        .collection(_workItemsCollection)
        .doc('$id')
        .get();
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
    final snapshot = await _firestore
        .collection(_workspacesCollection)
        .doc('$workspaceId')
        .get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return false;
    }
    final email = await _emailForUid(uid);
    return canAccessWorkspaceData(data, uid: uid, email: email);
  }

  Future<String?> _emailForUid(String uid) async {
    final authDoc = await _firestore
        .collection(_usersCollection)
        .doc(uid)
        .get();
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
    final byId = await _firestore
        .collection(_usersCollection)
        .doc('$userId')
        .get();
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
        throw WorkItemServiceException('找不到对应的 $label。');
      }
      return user;
    }
    final snapshot = await _firestore.collection(collection).doc('$id').get();
    if (!snapshot.exists || snapshot.data() == null) {
      throw WorkItemServiceException('找不到对应的 $label。');
    }
    return LookupOption.fromMap(Map<String, dynamic>.from(snapshot.data()!));
  }

  Future<LookupOption?> _loadUserLookupById(int id) async {
    await _ensureCurrentUserLookup();
    final direct = await _firestore
        .collection(_usersCollection)
        .doc('$id')
        .get();
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
    return _userLookupFromData(
      Map<String, dynamic>.from(snapshot.docs.first.data()),
    );
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
    final snapshot = await _firestore
        .collection(_workItemsCollection)
        .doc('$id')
        .get();
    if (!snapshot.exists || snapshot.data() == null) {
      throw const WorkItemServiceException('找不到对应的父项。');
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
    final byKey = {for (final item in existing) item.title.toLowerCase(): item};

    final created = <LookupOption>[];
    for (final name in normalized) {
      final existingLabel = byKey[name.toLowerCase()];
      if (existingLabel != null) {
        created.add(existingLabel);
        continue;
      }

      final id = await _nextId('labels');
      final label = LookupOption(
        id: id,
        title: name,
        subtitle: name.toLowerCase(),
      );
      await _firestore
          .collection(_labelsCollection)
          .doc('$id')
          .set(label.toMap());
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
      transaction.set(countersRef, {
        counterKey: nextValue,
      }, SetOptions(merge: true));
      return nextValue;
    });
  }

  void _seedLookup(
    Transaction transaction,
    String collection,
    LookupOption option,
  ) {
    transaction.set(
      _firestore.collection(collection).doc('${option.id}'),
      option.toMap(),
    );
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
    return LookupOption(
      id: id,
      title: normalizedEmail,
      subtitle: normalizedEmail,
    );
  }

  Future<void> _syncAuthUserRecord(Map<String, dynamic> data) async {
    final uid = data['uid'] as String?;
    if (uid == null || uid.isEmpty) {
      return;
    }

    final normalizedEmail =
        _normalizeEmail(data['email'] as String?) ??
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
    final email =
        _normalizeEmail(data['email'] as String?) ??
        _normalizeEmail(data['subtitle'] as String?);
    final title =
        (data['title'] as String?) ??
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
      items.addAll(
        snapshot.docs.map((doc) => Map<String, dynamic>.from(doc.data())),
      );
    }
    final sorted = [...items]
      ..sort((left, right) {
        final leftDate = sortBy?.call(left) ?? _asDateTime(left['createdAt']);
        final rightDate =
            sortBy?.call(right) ?? _asDateTime(right['createdAt']);
        final dateCompare =
            (rightDate ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
              leftDate ?? DateTime.fromMillisecondsSinceEpoch(0),
            );
        if (dateCompare != 0) {
          return dateCompare;
        }
        return ((right['id'] as num?)?.toInt() ?? 0).compareTo(
          (left['id'] as num?)?.toInt() ?? 0,
        );
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
      createdAt: _asDateTime(data['createdAt']),
      completedAt: _asDateTime(data['completedAt']),
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
      throw const WorkItemServiceException('请先登录。');
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

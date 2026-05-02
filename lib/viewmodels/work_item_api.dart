import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:ottersync/viewmodels/work_item_models.dart';

class WorkItemApiException implements Exception {
  const WorkItemApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class WorkItemApi {
  WorkItemApi({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static bool _useLocalStore = false;
  static bool _localStoreSeeded = false;
  static final Map<String, Map<String, Map<String, dynamic>>> _localCollections =
      <String, Map<String, Map<String, dynamic>>>{};
  static final Map<String, int> _localCounters = <String, int>{};

  static const _metaCollection = '_meta';
  static const _workspacesCollection = 'workspaces';
  static const _workTypesCollection = 'workTypes';
  static const _usersCollection = 'users';
  static const _teamsCollection = 'teams';
  static const _labelsCollection = 'labels';
  static const _workItemsCollection = 'workItems';
  static const _bootstrapDocument = 'bootstrap';
  static const _countersDocument = 'counters';
  static const _allowLocalFallback = kDebugMode;

  Future<List<LookupOption>> listWorkItems({String query = ''}) async {
    return _guard(() async {
      await _ensureSeedData();
      if (_useLocalStore) {
        return _listWorkItemsLocal(query: query);
      }
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
      if (_useLocalStore) {
        return _listParentItemsLocal(query: query, workspaceId: workspaceId);
      }
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

  Future<WorkItemResponse> createWorkItem(WorkItemCreateRequest payload) async {
    return _guard(() async {
      await _ensureSeedData();
      if (_useLocalStore) {
        throw const WorkItemApiException(
          '当前未连接到云端数据库，无法创建云端工作项目。请检查 Firebase 配置、网络连接和 Firestore 权限。',
        );
      }
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
      final keyPrefix = workspace.subtitle?.trim().isNotEmpty == true
          ? workspace.subtitle!.trim().toUpperCase()
          : 'OT';
      final response = WorkItemResponse(
        id: workItemId,
        summary: summary,
        description: _normalizeOptionalText(payload.description),
        workspace: workspace,
        workType: workType,
        reporter: reporter,
        assignee: assignee,
        parent: parent,
        team: team,
        dueDate: payload.dueDate,
        startDate: payload.startDate,
        labels: labels,
        attachments: payload.attachments,
      );

      final document = {
        ...response.toMap(),
        'key': '$keyPrefix-$workItemId',
        'workspaceId': workspace.id,
        'workTypeId': workType.id,
        'reporterId': reporter.id,
        'assigneeId': assignee?.id,
        'parentId': parent?.id,
        'teamId': team?.id,
        'labelIds': labels.map((item) => item.id).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection(_workItemsCollection).doc('$workItemId').set(document);
      return response;
    }, allowLocalFallback: false);
  }

  Future<T> _guard<T>(
    Future<T> Function() action, {
    bool allowLocalFallback = true,
  }) async {
    try {
      return await action();
    } on FirebaseException catch (error, stackTrace) {
      if (allowLocalFallback && _shouldUseLocalFallback(error) && !_useLocalStore) {
        debugPrint(
          'WorkItemApi switching to local debug data because Firestore is unavailable.',
        );
        _enableLocalStore();
        return action();
      }
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
    if (_useLocalStore) {
      _enableLocalStore();
      return;
    }

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
        'workspaces': 1,
        'workTypes': 3,
        'users': 2,
        'teams': 1,
        'labels': 3,
        'workItems': 1,
      });
      transaction.set(bootstrapRef, {
        'seededAt': FieldValue.serverTimestamp(),
      });

      _seedLookup(transaction, _workspacesCollection, const LookupOption(id: 1, title: 'ottersync', subtitle: 'OT'));
      _seedLookup(transaction, _workTypesCollection, const LookupOption(id: 1, title: '任务', subtitle: 'Task'));
      _seedLookup(transaction, _workTypesCollection, const LookupOption(id: 2, title: '缺陷', subtitle: 'Bug'));
      _seedLookup(transaction, _workTypesCollection, const LookupOption(id: 3, title: '故事', subtitle: 'Story'));
      _seedLookup(transaction, _usersCollection, const LookupOption(id: 1, title: 'Maoqiu The', subtitle: 'maoqiu@example.com'));
      _seedLookup(transaction, _usersCollection, const LookupOption(id: 2, title: 'Otter Bot', subtitle: 'otterbot@example.com'));
      _seedLookup(transaction, _teamsCollection, const LookupOption(id: 1, title: 'ottersync', subtitle: 'ottersync team'));
      _seedLookup(transaction, _labelsCollection, const LookupOption(id: 1, title: '移动端', subtitle: 'mobile'));
      _seedLookup(transaction, _labelsCollection, const LookupOption(id: 2, title: '高优先级', subtitle: 'high'));
      _seedLookup(transaction, _labelsCollection, const LookupOption(id: 3, title: '设计', subtitle: 'design'));

      transaction.set(_firestore.collection(_workItemsCollection).doc('1'), {
        'id': 1,
        'key': 'OT-1',
        'summary': '完善 Firebase 数据接入',
        'description': '将创建工作项和工作项列表迁移到 Firestore。',
        'workspaceId': 1,
        'workspace': const LookupOption(id: 1, title: 'ottersync', subtitle: 'OT').toMap(),
        'workTypeId': 1,
        'workType': const LookupOption(id: 1, title: '任务', subtitle: 'Task').toMap(),
        'reporterId': 1,
        'reporter': const LookupOption(id: 1, title: 'Maoqiu The', subtitle: 'maoqiu@example.com').toMap(),
        'assigneeId': 1,
        'assignee': const LookupOption(id: 1, title: 'Maoqiu The', subtitle: 'maoqiu@example.com').toMap(),
        'parentId': null,
        'parent': null,
        'teamId': 1,
        'team': const LookupOption(id: 1, title: 'ottersync', subtitle: 'ottersync team').toMap(),
        'dueDate': null,
        'startDate': null,
        'labelIds': [1, 3],
        'labels': [
          const LookupOption(id: 1, title: '移动端', subtitle: 'mobile').toMap(),
          const LookupOption(id: 3, title: '设计', subtitle: 'design').toMap(),
        ],
        'attachments': const [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<List<LookupOption>> _loadLookupCollection(String collection) async {
    if (_useLocalStore) {
      final items = _localCollection(collection).values
          .map((item) => LookupOption.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false);
      items.sort((left, right) => left.id.compareTo(right.id));
      return items;
    }
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
    if (_useLocalStore) {
      final data = _localCollection(collection)['$id'];
      if (data == null) {
        throw WorkItemApiException('找不到对应的 $label。');
      }
      return LookupOption.fromMap(Map<String, dynamic>.from(data));
    }
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
    if (_useLocalStore) {
      final data = _localCollection(_workItemsCollection)['$id'];
      if (data == null) {
        throw const WorkItemApiException('找不到对应的父项。');
      }
      return LookupOption(
        id: (data['id'] as num).toInt(),
        title: data['summary'] as String? ?? '',
        subtitle: data['key'] as String?,
      );
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
      if (_useLocalStore) {
        _setLocalDocument(_labelsCollection, '$id', label.toMap());
      } else {
        await _firestore.collection(_labelsCollection).doc('$id').set(label.toMap());
      }
      byKey[name.toLowerCase()] = label;
      created.add(label);
    }

    return created;
  }

  Future<int> _nextId(String counterKey) async {
    if (_useLocalStore) {
      final currentValue = _localCounters[counterKey] ?? 0;
      final nextValue = currentValue + 1;
      _localCounters[counterKey] = nextValue;
      _setLocalDocument(_metaCollection, _countersDocument, {
        ..._localDocument(_metaCollection, _countersDocument),
        counterKey: nextValue,
      });
      return nextValue;
    }
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

  bool _shouldUseLocalFallback(FirebaseException error) {
    return _allowLocalFallback && error.code == 'unavailable';
  }

  List<LookupOption> _listWorkItemsLocal({String query = ''}) {
    final items = _localCollection(_workItemsCollection).values
        .map((doc) => Map<String, dynamic>.from(doc))
        .map(
          (data) => LookupOption(
            id: (data['id'] as num).toInt(),
            title: data['summary'] as String? ?? '',
            subtitle: data['key'] as String?,
          ),
        )
        .where((item) => _matchesQuery(item.title, query) || _matchesQuery(item.subtitle ?? '', query))
        .toList(growable: false);
    items.sort((left, right) => right.id.compareTo(left.id));
    return items;
  }

  List<LookupOption> _listParentItemsLocal({
    required String query,
    int? workspaceId,
  }) {
    final items = _localCollection(_workItemsCollection).values
        .map((doc) => Map<String, dynamic>.from(doc))
        .where((data) => workspaceId == null || data['workspaceId'] == workspaceId)
        .map(
          (data) => LookupOption(
            id: (data['id'] as num).toInt(),
            title: data['summary'] as String? ?? '',
            subtitle: data['key'] as String?,
          ),
        )
        .where((item) => _matchesQuery(item.title, query) || _matchesQuery(item.subtitle ?? '', query))
        .toList(growable: false);
    items.sort((left, right) => right.id.compareTo(left.id));
    return items;
  }

  void _enableLocalStore() {
    _useLocalStore = true;
    if (_localStoreSeeded) {
      return;
    }

    _localCollections.clear();
    _localCounters
      ..clear()
      ..addAll({
        'workspaces': 1,
        'workTypes': 3,
        'users': 2,
        'teams': 1,
        'labels': 3,
        'workItems': 1,
      });

    _setLocalDocument(_metaCollection, _bootstrapDocument, {
      'seededAt': DateTime.now().toIso8601String(),
    });
    _setLocalDocument(_metaCollection, _countersDocument, Map<String, dynamic>.from(_localCounters));

    _setLocalDocument(
      _workspacesCollection,
      '1',
      const LookupOption(id: 1, title: 'ottersync', subtitle: 'OT').toMap(),
    );
    _setLocalDocument(
      _workTypesCollection,
      '1',
      const LookupOption(id: 1, title: '任务', subtitle: 'Task').toMap(),
    );
    _setLocalDocument(
      _workTypesCollection,
      '2',
      const LookupOption(id: 2, title: '缺陷', subtitle: 'Bug').toMap(),
    );
    _setLocalDocument(
      _workTypesCollection,
      '3',
      const LookupOption(id: 3, title: '故事', subtitle: 'Story').toMap(),
    );
    _setLocalDocument(
      _usersCollection,
      '1',
      const LookupOption(id: 1, title: 'Maoqiu The', subtitle: 'maoqiu@example.com').toMap(),
    );
    _setLocalDocument(
      _usersCollection,
      '2',
      const LookupOption(id: 2, title: 'Otter Bot', subtitle: 'otterbot@example.com').toMap(),
    );
    _setLocalDocument(
      _teamsCollection,
      '1',
      const LookupOption(id: 1, title: 'ottersync', subtitle: 'ottersync team').toMap(),
    );
    _setLocalDocument(
      _labelsCollection,
      '1',
      const LookupOption(id: 1, title: '移动端', subtitle: 'mobile').toMap(),
    );
    _setLocalDocument(
      _labelsCollection,
      '2',
      const LookupOption(id: 2, title: '高优先级', subtitle: 'high').toMap(),
    );
    _setLocalDocument(
      _labelsCollection,
      '3',
      const LookupOption(id: 3, title: '设计', subtitle: 'design').toMap(),
    );
    _setLocalDocument(_workItemsCollection, '1', {
      'id': 1,
      'key': 'OT-1',
      'summary': '完善 Firebase 数据接入',
      'description': '将创建工作项和工作项列表迁移到 Firestore。',
      'workspaceId': 1,
      'workspace': const LookupOption(id: 1, title: 'ottersync', subtitle: 'OT').toMap(),
      'workTypeId': 1,
      'workType': const LookupOption(id: 1, title: '任务', subtitle: 'Task').toMap(),
      'reporterId': 1,
      'reporter': const LookupOption(id: 1, title: 'Maoqiu The', subtitle: 'maoqiu@example.com').toMap(),
      'assigneeId': 1,
      'assignee': const LookupOption(id: 1, title: 'Maoqiu The', subtitle: 'maoqiu@example.com').toMap(),
      'parentId': null,
      'parent': null,
      'teamId': 1,
      'team': const LookupOption(id: 1, title: 'ottersync', subtitle: 'ottersync team').toMap(),
      'dueDate': null,
      'startDate': null,
      'labelIds': [1, 3],
      'labels': [
        const LookupOption(id: 1, title: '移动端', subtitle: 'mobile').toMap(),
        const LookupOption(id: 3, title: '设计', subtitle: 'design').toMap(),
      ],
      'attachments': const [],
      'createdAt': DateTime.now().toIso8601String(),
    });

    _localStoreSeeded = true;
  }

  Map<String, Map<String, dynamic>> _localCollection(String collection) {
    return _localCollections.putIfAbsent(collection, () => <String, Map<String, dynamic>>{});
  }

  Map<String, dynamic> _localDocument(String collection, String documentId) {
    return Map<String, dynamic>.from(_localCollection(collection)[documentId] ?? const <String, dynamic>{});
  }

  void _setLocalDocument(
    String collection,
    String documentId,
    Map<String, dynamic> value,
  ) {
    _localCollection(collection)[documentId] = Map<String, dynamic>.from(value);
  }
}

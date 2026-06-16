part of 'work_item_service.dart';

extension WorkItemOperationsService on WorkItemService {
  Future<WorkItemResponse?> getWorkItemById(int id) async {
    return _guard(() async {
      await _ensureSeedData();
      final doc = await _firestore
          .collection(WorkItemService._workItemsCollection)
          .doc('$id')
          .get();
      if (!doc.exists) return null;
      final data = Map<String, dynamic>.from(doc.data() as Map);
      await _ensureCanAccessWorkspaceId((data['workspaceId'] as num?)?.toInt());
      return WorkItemResponse.fromMap(data);
    });
  }

  Future<void> deleteWorkItem(int id) async {
    return _guard(() async {
      await _ensureSeedData();
      await _ensureCanEditWorkItem(id);
      final affected = await _firestore
          .collection(WorkItemService._workItemsCollection)
          .where('parentId', isEqualTo: id)
          .get();
      final batch = _firestore.batch();
      for (final doc in affected.docs) {
        batch.update(doc.reference, {'parentId': null, 'parent': null});
      }
      batch.delete(
        _firestore.collection(WorkItemService._workItemsCollection).doc('$id'),
      );
      await batch.commit();
      AppEventBus.instance.emitType(
        AppEventType.workItemUpdated,
        payload: {'workItemId': id, 'deleted': true},
      );
    });
  }

  Future<WorkItemResponse?> addAttachment(
    int id,
    AttachmentCreateRequest attachment,
  ) async {
    return _guard(() async {
      await _ensureSeedData();
      await _ensureCanEditWorkItem(id);
      final docRef = _firestore
          .collection(WorkItemService._workItemsCollection)
          .doc('$id');
      final doc = await docRef.get();
      if (!doc.exists) {
        throw const WorkItemServiceException('工作项不存在。');
      }
      final data = Map<String, dynamic>.from(doc.data() as Map);
      final attachments = <Map<String, dynamic>>[
        ...((data['attachments'] as List?)?.map(
              (e) => Map<String, dynamic>.from(e as Map),
            ) ??
            const []),
        attachment.toMap(),
      ];
      await docRef.update({
        'attachments': attachments,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppEventBus.instance.emitType(
        AppEventType.workItemUpdated,
        payload: {'workItemId': id},
      );
      return getWorkItemById(id);
    });
  }

  Future<WorkItemResponse?> removeAttachment(int id, int index) async {
    return _guard(() async {
      await _ensureSeedData();
      await _ensureCanEditWorkItem(id);
      final docRef = _firestore
          .collection(WorkItemService._workItemsCollection)
          .doc('$id');
      final doc = await docRef.get();
      if (!doc.exists) {
        throw const WorkItemServiceException('工作项不存在。');
      }
      final data = Map<String, dynamic>.from(doc.data() as Map);
      final attachments =
          ((data['attachments'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList()) ??
          <Map<String, dynamic>>[];
      if (index < 0 || index >= attachments.length) {
        throw const WorkItemServiceException('附件不存在。');
      }
      attachments.removeAt(index);
      await docRef.update({
        'attachments': attachments,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppEventBus.instance.emitType(
        AppEventType.workItemUpdated,
        payload: {'workItemId': id},
      );
      return getWorkItemById(id);
    });
  }

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
        final lookup = await _loadLookupById(
          WorkItemService._usersCollection,
          assigneeId,
          'assignee',
        );
        patch['assigneeId'] = assigneeId;
        patch['assignee'] = lookup.toMap();
      } else if (clearAssignee) {
        patch['assigneeId'] = null;
        patch['assignee'] = null;
      }
      if (teamId != null) {
        final lookup = await _loadLookupById(
          WorkItemService._teamsCollection,
          teamId,
          'team',
        );
        patch['teamId'] = teamId;
        patch['team'] = lookup.toMap();
      } else if (clearTeam) {
        patch['teamId'] = null;
        patch['team'] = null;
      }
      if (sprintId != null) {
        final sprint = await getSprintById(sprintId);
        if (sprint == null) {
          throw const WorkItemServiceException('找不到对应的冲刺。');
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
      await _firestore
          .collection(WorkItemService._workItemsCollection)
          .doc('$id')
          .update(patch);
      await _notifyWorkItemParticipants(
        id,
        title: '工作项已更新',
        descriptionPrefix: '字段发生变化',
      );
      AppEventBus.instance.emitType(
        AppEventType.workItemUpdated,
        payload: {'workItemId': id},
      );
    });
  }

  Future<void> updateWorkItemDueDate(int id, DateTime? dueDate) async {
    return _guard(() async {
      await _ensureSeedData();
      await _ensureCanEditWorkItem(id);
      await _firestore
          .collection(WorkItemService._workItemsCollection)
          .doc('$id')
          .update({
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

  Future<void> updateWorkItemStatus(int id, WorkItemStatus status) async {
    return _guard(() async {
      await _ensureSeedData();
      await _ensureCanEditWorkItem(id);
      await _firestore
          .collection(WorkItemService._workItemsCollection)
          .doc('$id')
          .update({
            'status': status.name,
            'updatedAt': FieldValue.serverTimestamp(),
            'completedAt': status == WorkItemStatus.done
                ? FieldValue.serverTimestamp()
                : null,
          });
      await _notifyWorkItemParticipants(
        id,
        title: '工作项状态已变更',
        descriptionPrefix: '状态更新为 ${workItemStatusLabel(status)}',
      );
      AppEventBus.instance.emitType(
        AppEventType.workItemUpdated,
        payload: {'workItemId': id, 'status': status.name},
      );
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
        final statusLabel = sprint.status == SprintStatus.active
            ? '进行中'
            : '计划中';
        groups.add(
          _buildBacklogGroup(
            '${sprint.name} · $statusLabel',
            sprintItems,
            sprintId: sprint.id,
          ),
        );
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
      todoCount: items
          .where((item) => item.statusKey == WorkItemStatus.todo)
          .length,
      inProgressCount: items
          .where((item) => item.statusKey == WorkItemStatus.inProgress)
          .length,
      doneCount: items
          .where((item) => item.statusKey == WorkItemStatus.done)
          .length,
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
      return items
          .where((data) {
            final sprintId = (data['sprintId'] as num?)?.toInt();
            if (sprintId != null) {
              return openSprintIds.contains(sprintId);
            }
            return _bucketFromData(data) == WorkItemBucket.sprint;
          })
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

  Future<List<IssueSummary>> listWorkItemSummaries({String query = ''}) async {
    return _guard(() async {
      await _ensureSeedData();
      final items = await _loadWorkItemMaps();
      return items
          .map(_issueSummaryFromWorkItem)
          .where(
            (item) =>
                _matchesQuery(item.title, query) ||
                _matchesQuery(item.key, query),
          )
          .toList(growable: false);
    });
  }

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

  Future<WorkItemResponse> createBacklogItem({
    required int workspaceId,
    required String summary,
    String? description,
    int? sprintId,
  }) async {
    return _guard(() async {
      await _ensureSeedData();
      final reporter = await _ensureCurrentUserLookup();
      return createWorkItem(
        WorkItemCreateRequest(
          workspaceId: workspaceId,
          workTypeId: 1,
          summary: summary,
          reporterId: reporter?.id ?? 1,
          bucket: sprintId != null
              ? WorkItemBucket.sprint
              : WorkItemBucket.backlog,
          status: WorkItemStatus.todo,
          sprintId: sprintId,
          description: description,
        ),
      );
    });
  }

  Future<WorkItemResponse> createWorkItem(WorkItemCreateRequest payload) async {
    return _guard(() async {
      await _ensureSeedData();
      final summary = payload.summary.trim();
      if (summary.isEmpty) {
        throw const WorkItemServiceException('创建失败，摘要不能为空。');
      }

      final workspace = await _loadLookupById(
        WorkItemService._workspacesCollection,
        payload.workspaceId,
        'workspace',
      );
      final visibleWorkspaceIds = await _visibleWorkspaceIds();
      if (!visibleWorkspaceIds.contains(payload.workspaceId)) {
        throw const WorkItemServiceException('你没有在该空间创建工作项的权限。');
      }
      final workType = await _loadLookupById(
        WorkItemService._workTypesCollection,
        payload.workTypeId,
        'work type',
      );
      final reporter = await _loadLookupById(
        WorkItemService._usersCollection,
        payload.reporterId,
        'reporter',
      );
      final assignee = await _loadOptionalLookupById(
        WorkItemService._usersCollection,
        payload.assigneeId,
        'assignee',
      );
      final parent = await _loadOptionalParentItem(payload.parentId);
      final team = await _loadOptionalLookupById(
        WorkItemService._teamsCollection,
        payload.teamId,
        'team',
      );

      final selectedLabels = await _loadLabels(payload.labelIds);
      final createdLabels = await _createMissingLabels(payload.newLabelNames);
      final labels = [...selectedLabels, ...createdLabels];

      Sprint? sprint;
      if (payload.sprintId != null) {
        sprint = await getSprintById(payload.sprintId!);
        if (sprint == null) {
          throw const WorkItemServiceException('找不到对应的冲刺。');
        }
        if (sprint.workspaceId != payload.workspaceId) {
          throw const WorkItemServiceException('该冲刺不属于当前空间。');
        }
      }
      final effectiveBucket = sprint != null
          ? WorkItemBucket.sprint
          : payload.bucket;

      final workItemId = await _nextId('workItems');
      final workspaceKey = workspace.subtitle?.trim().toUpperCase() ?? '';
      if (workspaceKey.isEmpty) {
        throw const WorkItemServiceException('空间 Key 不能为空。');
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
        updatedAt: now,
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
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(WorkItemService._workItemsCollection)
          .doc('$workItemId')
          .set(document);
      await _notifyWorkItemCreated(response, document);
      AppEventBus.instance.emitType(
        AppEventType.workItemCreated,
        payload: {
          'workItemId': response.id,
          'workspaceId': workspace.id,
          'key': response.key,
          'summary': response.summary,
        },
      );
      return response;
    });
  }
}

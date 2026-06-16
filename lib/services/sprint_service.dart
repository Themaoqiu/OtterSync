part of 'work_item_service.dart';

extension SprintService on WorkItemService {
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
            .collection(WorkItemService._sprintsCollection)
            .where('workspaceId', isEqualTo: id)
            .get();
        sprints.addAll(
          snapshot.docs.map(
            (doc) => Sprint.fromMap(Map<String, dynamic>.from(doc.data())),
          ),
        );
      }
      sprints.sort((left, right) => left.id.compareTo(right.id));
      return sprints;
    });
  }

  Future<Sprint?> getSprintById(int id) async {
    return _guard(() async {
      await _ensureSeedData();
      final snapshot = await _firestore
          .collection(WorkItemService._sprintsCollection)
          .doc('$id')
          .get();
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      final sprint = Sprint.fromMap(
        Map<String, dynamic>.from(snapshot.data()!),
      );
      await _ensureCanAccessWorkspaceId(sprint.workspaceId);
      return sprint;
    });
  }

  Future<Sprint> createSprint(SprintCreateRequest payload) async {
    return _guard(() async {
      await _ensureSeedData();
      final name = payload.name.trim();
      if (name.isEmpty) {
        throw const WorkItemServiceException('请输入冲刺名称。');
      }
      await _ensureCanAccessWorkspaceId(payload.workspaceId);
      final id = await _nextId('sprints');
      final sprint = Sprint(
        id: id,
        workspaceId: payload.workspaceId,
        name: name,
        goal: payload.goal?.trim().isEmpty ?? true
            ? null
            : payload.goal!.trim(),
        status: SprintStatus.planned,
        startDate: payload.startDate,
        endDate: payload.endDate,
      );
      await _firestore
          .collection(WorkItemService._sprintsCollection)
          .doc('$id')
          .set(sprint.toMap());
      return sprint;
    });
  }

  Future<Sprint> updateSprintStatus(int id, SprintStatus status) async {
    return _guard(() async {
      await _ensureSeedData();
      final docRef = _firestore
          .collection(WorkItemService._sprintsCollection)
          .doc('$id');
      final snapshot = await docRef.get();
      if (!snapshot.exists || snapshot.data() == null) {
        throw const WorkItemServiceException('冲刺不存在。');
      }
      final sprint = Sprint.fromMap(
        Map<String, dynamic>.from(snapshot.data()!),
      );
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
        throw const WorkItemServiceException('冲刺不存在。');
      }
      final affected = await _firestore
          .collection(WorkItemService._workItemsCollection)
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
      batch.delete(
        _firestore.collection(WorkItemService._sprintsCollection).doc('$id'),
      );
      await batch.commit();
    });
  }
}

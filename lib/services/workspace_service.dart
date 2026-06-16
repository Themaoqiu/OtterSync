part of 'work_item_service.dart';

extension WorkspaceService on WorkItemService {
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

      return workspaceMaps
          .map((data) {
            final id = (data['id'] as num).toInt();
            return JiraSpace(
              id: id,
              name: data['title'] as String? ?? '',
              key: data['subtitle'] as String? ?? '',
              template: data['template'] as String? ?? '看板',
              issueCount: counts[id] ?? 0,
              avatar: buildSpaceAvatar(
                '${data['subtitle'] ?? ''}${data['title'] ?? ''}',
              ),
            );
          })
          .toList(growable: false);
    });
  }

  Future<JiraSpace> createWorkspace(WorkspaceCreateRequest payload) async {
    return _guard(() async {
      await _ensureSeedData();
      final name = payload.name.trim();
      final key = payload.key.trim().toUpperCase();
      final template = payload.template.trim();

      if (name.isEmpty) {
        throw const WorkItemServiceException('请输入空间名称。');
      }
      if (key.isEmpty) {
        throw const WorkItemServiceException('请输入空间 Key。');
      }

      final existing = await _firestore
          .collection(WorkItemService._workspacesCollection)
          .where('subtitle', isEqualTo: key)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        throw const WorkItemServiceException('该空间 Key 已存在，请使用其他 Key。');
      }

      final id = await _nextId('workspaces');
      final record = JiraSpace(
        id: id,
        name: name,
        key: key,
        template: template.isEmpty ? '看板' : template,
        avatar: buildSpaceAvatar('$key$name'),
      );

      await _firestore
          .collection(WorkItemService._workspacesCollection)
          .doc('$id')
          .set({
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

      AppEventBus.instance.emitType(
        AppEventType.workspaceCreated,
        payload: {'workspaceId': record.id, 'name': record.name},
      );
      return record;
    });
  }

  Future<JiraSpace?> getWorkspaceById(int id) async {
    return _guard(() async {
      await _ensureSeedData();
      final snapshot = await _firestore
          .collection(WorkItemService._workspacesCollection)
          .doc('$id')
          .get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      if (!_canAccessWorkspace(data)) {
        throw const WorkItemServiceException('你没有访问该空间的权限。');
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
        throw const WorkItemServiceException('请输入有效的邀请邮箱。');
      }

      final workspaceRef = _firestore
          .collection(WorkItemService._workspacesCollection)
          .doc('$workspaceId');
      final workspaceSnapshot = await workspaceRef.get();
      final workspace = workspaceSnapshot.data();
      if (!workspaceSnapshot.exists || workspace == null) {
        throw const WorkItemServiceException('空间不存在。');
      }
      if (workspace['ownerUid'] != _requireCurrentUid()) {
        throw const WorkItemServiceException('只有空间创建者可以邀请成员。');
      }

      final existingInvite = await _firestore
          .collection(WorkItemService._workspaceInvitesCollection)
          .where('workspaceId', isEqualTo: workspaceId)
          .where('invitedEmail', isEqualTo: normalizedEmail)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (existingInvite.docs.isNotEmpty) {
        throw const WorkItemServiceException('该成员已有待处理邀请。');
      }

      final inviteRef = _firestore
          .collection(WorkItemService._workspaceInvitesCollection)
          .doc();
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
          .collection(WorkItemService._workspaceInvitesCollection)
          .where('invitedEmail', isEqualTo: email)
          .where('status', isEqualTo: 'pending')
          .get();
      final invites = snapshot.docs
          .map(
            (doc) =>
                WorkspaceInvite.fromMap(Map<String, dynamic>.from(doc.data())),
          )
          .toList(growable: false);
      invites.sort((left, right) {
        final leftDate =
            left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final rightDate =
            right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return rightDate.compareTo(leftDate);
      });
      return invites;
    });
  }

  Future<void> acceptWorkspaceInvite(String inviteId) async {
    return _guard(() async {
      await _ensureSeedData();
      final inviteRef = _firestore
          .collection(WorkItemService._workspaceInvitesCollection)
          .doc(inviteId);
      final inviteSnapshot = await inviteRef.get();
      final inviteData = inviteSnapshot.data();
      if (!inviteSnapshot.exists || inviteData == null) {
        throw const WorkItemServiceException('邀请不存在。');
      }
      final invite = WorkspaceInvite.fromMap(
        Map<String, dynamic>.from(inviteData),
      );
      if (invite.invitedEmail != _currentEmail || invite.status != 'pending') {
        throw const WorkItemServiceException('邀请不存在或已处理。');
      }

      final uid = _requireCurrentUid();
      final workspaceRef = _firestore
          .collection(WorkItemService._workspacesCollection)
          .doc('${invite.workspaceId}');
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
      AppEventBus.instance.emitType(
        AppEventType.workspaceMembershipChanged,
        payload: {'workspaceId': invite.workspaceId, 'action': 'accepted'},
      );
    });
  }

  Future<void> declineWorkspaceInvite(String inviteId) async {
    return _guard(() async {
      await _ensureSeedData();
      final inviteRef = _firestore
          .collection(WorkItemService._workspaceInvitesCollection)
          .doc(inviteId);
      final inviteSnapshot = await inviteRef.get();
      final inviteData = inviteSnapshot.data();
      if (!inviteSnapshot.exists || inviteData == null) {
        throw const WorkItemServiceException('邀请不存在。');
      }
      final invite = WorkspaceInvite.fromMap(
        Map<String, dynamic>.from(inviteData),
      );
      if (invite.invitedEmail != _currentEmail || invite.status != 'pending') {
        throw const WorkItemServiceException('邀请不存在或已处理。');
      }

      final workspaceRef = _firestore
          .collection(WorkItemService._workspacesCollection)
          .doc('${invite.workspaceId}');
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
      AppEventBus.instance.emitType(
        AppEventType.workspaceMembershipChanged,
        payload: {'workspaceId': invite.workspaceId, 'action': 'declined'},
      );
    });
  }

  Future<List<SpaceSummaryMetric>> loadSpaceSummaryMetrics(
    int workspaceId,
  ) async {
    return _guard(() async {
      await _ensureSeedData();
      final items = await _loadWorkItemMaps(workspaceId: workspaceId);
      final doneCount = items
          .where((data) => _statusFromData(data) == WorkItemStatus.done)
          .length;
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
              avatar: buildSpaceAvatar(
                '${data['subtitle'] ?? ''}${data['title'] ?? ''}',
              ),
            );
          })
          .where(
            (space) =>
                space.name.toLowerCase().contains(lowerQuery) ||
                space.key.toLowerCase().contains(lowerQuery),
          )
          .toList(growable: false);
    });
  }

  Future<void> updateWorkspace(int id, {String? name, String? key}) async {
    return _guard(() async {
      await _ensureSeedData();
      await _ensureOwnsWorkspace(id);
      final data = <String, dynamic>{};
      if (name != null) data['title'] = name;
      if (key != null) data['subtitle'] = key;
      await _firestore
          .collection(WorkItemService._workspacesCollection)
          .doc('$id')
          .update(data);
    });
  }

  Future<void> deleteWorkspace(int id) async {
    return _guard(() async {
      await _ensureSeedData();
      await _ensureOwnsWorkspace(id);
      final workItems = await _firestore
          .collection(WorkItemService._workItemsCollection)
          .where('workspaceId', isEqualTo: id)
          .get();
      final batch = _firestore.batch();
      for (final doc in workItems.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(
        _firestore.collection(WorkItemService._workspacesCollection).doc('$id'),
      );
      await batch.commit();
    });
  }
}

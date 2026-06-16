part of 'work_item_service.dart';

extension LookupService on WorkItemService {
  Future<CreateWorkItemLookups> loadCreateLookups() async {
    return _guard(() async {
      await _ensureSeedData();
      final results = await Future.wait([
        _loadVisibleWorkspaceLookups(),
        _loadLookupCollection(WorkItemService._workTypesCollection),
        _loadLookupCollection(WorkItemService._usersCollection),
        _loadLookupCollection(WorkItemService._teamsCollection),
        _loadLookupCollection(WorkItemService._labelsCollection),
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

  Future<List<LookupOption>> loadWorkspaceMembers(int workspaceId) async {
    return _guard(() async {
      await _ensureSeedData();
      await _ensureCurrentUserLookup();
      final snapshot = await _firestore
          .collection(WorkItemService._workspacesCollection)
          .doc('$workspaceId')
          .get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null || !_canAccessWorkspace(data)) {
        throw const WorkItemServiceException('你没有访问该空间的权限。');
      }
      final memberUids = <String>{};
      final ownerUid = data['ownerUid'] as String?;
      if (ownerUid != null && ownerUid.isNotEmpty) {
        memberUids.add(ownerUid);
      }
      for (final uid in (data['memberUids'] as List<dynamic>? ?? const [])) {
        if (uid is String && uid.isNotEmpty) {
          memberUids.add(uid);
        }
      }

      final users = await _firestore
          .collection(WorkItemService._usersCollection)
          .get();
      final byId = <int, LookupOption>{};
      for (final doc in users.docs) {
        final userData = Map<String, dynamic>.from(doc.data());
        final uid = userData['uid'] as String?;
        final id = (userData['id'] as num?)?.toInt();
        if (id == null || uid == null || !memberUids.contains(uid)) {
          continue;
        }
        byId[id] = _userLookupFromData(userData);
      }
      final members = byId.values.toList(growable: false);
      members.sort((left, right) => left.id.compareTo(right.id));
      return members;
    });
  }

  Future<List<LookupOption>> listRegisteredUsers() async {
    return _guard(() async {
      await _ensureSeedData();
      await _ensureCurrentUserLookup();
      return _loadUserLookups();
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
          .where(
            (item) =>
                _matchesQuery(item.title, query) ||
                _matchesQuery(item.subtitle ?? '', query),
          )
          .toList(growable: false);
    });
  }
}

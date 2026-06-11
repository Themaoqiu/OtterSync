bool canAccessWorkspaceData(
  Map<String, dynamic> data, {
  required String? uid,
  String? email,
}) {
  if (uid == null || uid.isEmpty) {
    return false;
  }

  final ownerUid = data['ownerUid'];
  if (ownerUid == uid) {
    return true;
  }

  final memberUids = data['memberUids'];
  if (memberUids is Iterable && memberUids.contains(uid)) {
    return true;
  }

  return false;
}

bool shouldNotifyUser(
  Map<String, dynamic> data, {
  required String? uid,
}) {
  if (uid == null || uid.isEmpty) {
    return false;
  }
  return data['recipientUid'] == uid;
}

part of 'work_item_service.dart';

extension NotificationService on WorkItemService {
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
        return (rightDate ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
          leftDate ?? DateTime.fromMillisecondsSinceEpoch(0),
        );
      });
      return notifications
          .take(limit)
          .map(
            (data) => NotificationItem(
              title: data['title'] as String? ?? '通知',
              description: data['description'] as String? ?? '',
              route: data['route'] as String?,
              workItemId: (data['workItemId'] as num?)?.toInt(),
            ),
          )
          .toList(growable: false);
    });
  }

  ///
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
              .map(
                (data) => NotificationItem(
                  title: data['title'] as String? ?? '通知',
                  description: data['description'] as String? ?? '',
                  route: data['route'] as String?,
                  workItemId: (data['workItemId'] as num?)?.toInt(),
                ),
              )
              .toList(growable: false);
        });
  }
}

part of 'work_item_service.dart';

extension FeedbackService on WorkItemService {
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
        throw const WorkItemServiceException('请先登录。');
      }

      final existing = await _feedbackCollection
          .where('userId', isEqualTo: uid)
          .where('targetType', isEqualTo: targetType)
          .where('targetId', isEqualTo: targetId)
          .get();

      for (final doc in existing.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['type'] == type) {
          await _feedbackCollection.doc(doc.id).delete();
          return;
        }
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
      return (snapshot.docs.first.data() as Map<String, dynamic>)['type']
          as String?;
    });
  }
}

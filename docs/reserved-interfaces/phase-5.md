# 阶段五：工作项更新与筛选

**目标**：实现工作项状态更新、筛选器应用、最近查看记录
**涉及接口**：4 处
**预计工时**：2 天
**新增**：1 个集合、3 个 API 方法

---

## 5.1 Firestore 集合设计

**集合名**：`recentViews`

**文档结构**：
```
recentViews/{userId}_{targetId}
├── userId: string
├── targetId: int (工作项 ID)
├── targetKey: string (如 "PROJ-5")
├── targetTitle: string
├── viewedAt: Timestamp
```

**说明**：`{userId}_{targetId}` 作为文档 ID，同一用户对同一工作项只保留一条记录，`set` 覆盖更新。

## 5.2 安全规则更新

- **文件**：`firestore.rules`
- **新增规则**：
  ```
  match /recentViews/{id} {
    allow read: if isSignedIn();
    allow create, update: if isSignedIn();
    allow delete: if isSignedIn();
  }
  ```

## 5.3 WorkItemApi 扩展

- **文件**：`lib/viewmodels/work_item_api.dart`
- **新增集合常量**：
  ```dart
  CollectionReference get _recentViewsCollection =>
      _firestore.collection('recentViews');
  ```
- **新增方法**：
  ```dart
  /// 更新工作项状态
  Future<void> updateWorkItemStatus(int id, WorkItemStatus status) async {
    return _guard(() async {
      await _ensureSeedData();
      await _workItemsCollection.doc(id.toString()).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// 更新工作项经办人
  Future<void> updateWorkItemAssignee(int id, int? assigneeId) async {
    return _guard(() async {
      await _ensureSeedData();
      final data = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (assigneeId != null) {
        final assignee = await _loadLookupById(_usersCollection, assigneeId);
        data['assignee'] = assignee.toMap();
        data['assigneeId'] = assigneeId;
      } else {
        data['assignee'] = FieldValue.delete();
        data['assigneeId'] = FieldValue.delete();
      }
      await _workItemsCollection.doc(id.toString()).update(data);
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
      final docId = '${_currentUid}_$workItemId';
      await _recentViewsCollection.doc(docId).set({
        'userId': _currentUid,
        'targetId': workItemId,
        'targetKey': workItemKey,
        'targetTitle': workItemTitle,
        'viewedAt': FieldValue.serverTimestamp(),
      });
    });
  }
  ```

## 5.4 工作项详情页集成

- **文件**：`lib/pages/WorkItemDetail/index.dart`（阶段二新建）
- 进入详情页时调用 `recordRecentView`
- 支持状态切换（待办 → 进行中 → 已完成）
- 状态切换后调用 `updateWorkItemStatus`

## 5.5 空间详情筛选（SpaceDetails）

- **文件**：`lib/pages/SpaceDetails/index.dart` 第 71 行
- 弹出筛选 BottomSheet，支持按状态（待办/进行中/已完成）筛选
- 筛选结果刷新当前 tab 数据

## 5.6 按状态筛选工作项（SpaceDetails Summary）

- **文件**：`lib/pages/SpaceDetails/index.dart` 第 124 行
- 点击状态标签后弹出该状态下的工作项列表 BottomSheet

## 5.7 AllWork 筛选器应用

- **文件**：`lib/pages/AllWork/index.dart`
- 增加 `_selectedFilter` 状态
- 选择筛选器后客户端过滤 `_workItems` 列表

---

## 检查清单

- [ ] 进入详情页自动记录最近查看
- [ ] 工作项状态可在详情页切换
- [ ] 状态更新同步到 Firestore
- [ ] 空间筛选 BottomSheet 正常工作
- [ ] Summary 状态标签点击有响应
- [ ] AllWork 筛选器正确过滤列表
- [ ] `flutter analyze` 无警告

## Git 提交

```
feat(workflow): 实现工作项更新、筛选和最近查看记录

- 新增 Firestore recentViews 集合及安全规则
- WorkItemApi 新增 updateWorkItemStatus、updateWorkItemAssignee、recordRecentView
- 工作项详情页支持状态切换和查看记录
- SpaceDetails 支持按状态筛选
- AllWork 筛选器应用实际过滤逻辑
```

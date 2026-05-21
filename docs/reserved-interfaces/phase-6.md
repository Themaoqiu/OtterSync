# 阶段六：空间操作与待办创建

**目标**：实现空间更多操作、待办创建、通知详情
**涉及接口**：4 处
**预计工时**：1.5 天

---

## 6.1 更多空间操作（SpaceDetails）

- **文件**：`lib/pages/SpaceDetails/index.dart` 第 75 行
- 弹出 `PopupMenuButton` 或 BottomSheet
- 菜单项：编辑空间名称、归档空间、删除空间（需确认对话框）

## 6.2 WorkItemApi 扩展

- **文件**：`lib/viewmodels/work_item_api.dart`
- **新增方法**：
  ```dart
  /// 更新工作区名称
  Future<void> updateWorkspace(int id, {String? name, String? key}) async {
    return _guard(() async {
      await _ensureSeedData();
      final data = <String, dynamic>{};
      if (name != null) data['title'] = name;
      if (key != null) data['subtitle'] = key;
      await _workspacesCollection.doc(id.toString()).update(data);
    });
  }

  /// 删除工作区（级联删除关联工作项）
  Future<void> deleteWorkspace(int id) async {
    return _guard(() async {
      await _ensureSeedData();
      final workItems = await _workItemsCollection
          .where('workspaceId', isEqualTo: id)
          .get();
      final batch = _firestore.batch();
      for (final doc in workItems.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_workspacesCollection.doc(id.toString()));
      await batch.commit();
    });
  }

  /// 创建待办事项（简化版）
  Future<WorkItemResponse> createBacklogItem({
    required int workspaceId,
    required String summary,
    String? description,
  }) async {
    return createWorkItem(WorkItemCreateRequest(
      workspaceId: workspaceId,
      workTypeId: 1,
      summary: summary,
      reporterId: 1,
      bucket: WorkItemBucket.backlog,
      status: WorkItemStatus.todo,
      description: description,
    ));
  }
  ```

## 6.3 创建待办事项（SpaceDetails Backlog）

- **文件**：`lib/pages/SpaceDetails/index.dart` 第 141 行
- 弹出简易创建对话框（仅需输入 summary）
- 调用 `createBacklogItem`，成功后刷新 backlog 列表

## 6.4 通知详情（Notifications）

- **文件**：`lib/pages/Notifications/index.dart` 第 99 行
- 有关联 `workItemId` 时跳转 `/work-item/:id`
- 系统通知显示详情 BottomSheet

## 6.5 模型更新

- **文件**：`lib/viewmodels/jira_models.dart`
- `NotificationItem` 增加 `int? workItemId` 字段（阶段二已引入）

---

## 检查清单

- [ ] 空间更多操作弹出菜单
- [ ] 编辑空间名称功能正常
- [ ] 删除空间确认对话框 + 级联删除工作项
- [ ] 待办事项创建成功并出现在 backlog
- [ ] 通知点击可跳转关联工作项
- [ ] `flutter analyze` 无警告

## Git 提交

```
feat(space): 实现空间操作、待办创建和通知详情

- SpaceDetails 更多操作菜单（编辑/删除空间，级联删除工作项）
- WorkItemApi 新增 updateWorkspace、deleteWorkspace、createBacklogItem
- Backlog 创建待办事项对话框
- Notifications 通知详情跳转
```

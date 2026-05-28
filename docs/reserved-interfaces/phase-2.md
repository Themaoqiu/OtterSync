# 阶段二：导航与详情页

**目标**：新建工作项详情页，打通各页面的导航跳转
**涉及接口**：6 处
**预计工时**：1.5 天
**新增**：1 个页面、1 个路由、1 个 API 方法

---

## 2.1 WorkItemApi 扩展

- **文件**：`lib/viewmodels/work_item_api.dart`
- **新增方法**：
  ```dart
  Future<WorkItemResponse?> getWorkItemById(int id) async {
    return _guard(() async {
      await _ensureSeedData();
      final doc = await _workItemsCollection.doc(id.toString()).get();
      if (!doc.exists) return null;
      return WorkItemResponse.fromMap(doc.data() as Map<String, dynamic>);
    });
  }
  ```

## 2.2 工作项详情页

- **新文件**：`lib/pages/WorkItemDetail/index.dart`
- **遵循技能**：`skills/ottersync-flutter-style/SKILL.md`
- **页面结构**：
  ```
  WorkItemDetailView (StatefulWidget)
  ├── AppBar: 返回按钮 + 工作项 key + 更多操作
  ├── Body: ListView
  │   ├── 标题（summary）
  │   ├── 状态标签 + 类型标签
  │   ├── 描述（description）
  │   ├── 详情字段列表
  │   │   ├── 经办人（assignee）
  │   │   ├── 报告人（reporter）
  │   │   ├── 团队（team）
  │   │   ├── 标签（labels）
  │   │   ├── 父项（parent）
  │   │   ├── 开始日期 / 截止日期
  │   │   └── 创建时间
  │   └── 附件列表（attachments）
  ```
- **数据加载**：`WorkItemApi().getWorkItemById(workItemId)`
- **UI 组件**：复用 `AppSurface`、`IssueSummary` 相关样式

## 2.3 路由注册

- **文件**：`lib/routes/index.dart`
- **新增路由**：
  ```dart
  GoRoute(
    path: '/work-item/:workItemId',
    builder: (context, state) {
      final id = int.tryParse(state.pathParameters['workItemId'] ?? '');
      return WorkItemDetailView(workItemId: id);
    },
  ),
  ```

## 2.4 各页面导航接入

| 页面 | 文件位置 | 当前代码 | 修改 |
|------|----------|----------|------|
| Home | `lib/pages/Home/index.dart` 第 211、225、249 行 | `showDemoFeedback(...)` | `context.push('/work-item/${item.id}')` |
| AllWork | `lib/pages/AllWork/index.dart` 第 159 行 | `showDemoFeedback(...)` | `context.push('/work-item/${item.id}')` |
| Dashboard | `lib/pages/Dashboard/index.dart` 第 108 行 | `showDemoFeedback(...)` | `context.push('/work-item/${item.id}')` |
| Dashboard | `lib/pages/Dashboard/index.dart` 第 115 行 | `showDemoFeedback(...)` | 从 `item.issue`（"PROJ-5"）解析数字 ID 跳转 |
| Notifications | `lib/pages/Notifications/index.dart` 第 99 行 | `showDemoFeedback(...)` | `context.push('/work-item/${item.workItemId}')` |

**前置改动**：
- `IssueSummary` 模型增加 `int? id` 字段
- `NotificationItem` 模型增加 `int? workItemId` 字段

## 2.5 快速访问项交互（Home）

- **文件**：`lib/pages/Home/index.dart` 第 169 行
- **实现方案**：
  - 有 `route` 的项目已正确跳转
  - 无 `route` 的项目跳转到对应空间详情
  - `QuickAccessItem` 模型增加 `spaceId` 字段

---

## 检查清单

- [ ] 工作项详情页正确显示所有字段
- [ ] 从 Home、AllWork、Dashboard、Notifications 均可跳转到详情页
- [ ] 详情页加载失败时显示错误状态
- [ ] 快速访问项无 route 时有合理的降级行为
- [ ] `flutter analyze` 无警告
- [ ] 各入口跳转测试通过

## Git 提交

```
feat(detail): 新建工作项详情页，打通各页面导航跳转

- 新增 WorkItemDetailView 页面，展示工作项完整信息
- 新增 WorkItemApi.getWorkItemById 方法
- 注册 /work-item/:workItemId 路由
- 接入 Home、AllWork、Dashboard、Notifications 的详情跳转
- IssueSummary 增加 id 字段，NotificationItem 增加 workItemId 字段
```

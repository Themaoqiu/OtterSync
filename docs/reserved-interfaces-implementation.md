# OtterSync 预留接口实现开发文档

> 版本：v1.0 | 日期：2026-05-21
> 范围：除「AI 创建工作项（图像上传）」外的全部 18 处预留接口
> 技能约束：所有开发必须遵循 `skills/ottersync-flutter-style/SKILL.md` 及 `skills/firebase-develop/` 下的相关技能

---

## 目录

1. [现状分析](#1-现状分析)
2. [开发前置条件](#2-开发前置条件)
3. [分阶段开发计划](#3-分阶段开发计划)
   - [阶段一：纯客户端功能](#阶段一纯客户端功能)
   - [阶段二：导航与详情页](#阶段二导航与详情页)
   - [阶段三：反馈与剪贴板](#阶段三反馈与剪贴板)
   - [阶段四：搜索功能](#阶段四搜索功能)
   - [阶段五：工作项更新与筛选](#阶段五工作项更新与筛选)
   - [阶段六：空间操作与待办创建](#阶段六空间操作与待办创建)
4. [待确认问题](#4-待确认问题)
5. [接口清单汇总](#5-接口清单汇总)

---

## 1. 现状分析

### 1.1 数据层现状

- **单一数据入口**：`WorkItemApi`（824 行），所有 Firestore 访问通过此类
- **集合结构**：`_meta`、`workspaces`、`workTypes`、`users`、`teams`、`labels`、`workItems`
- **已具备能力**：创建工作项、创建工作区、列表查询、首页/仪表板数据加载
- **缺失能力**：
  - 无工作项更新/删除方法
  - 无服务端过滤（全部客户端内存过滤）
  - 无分页支持
  - 无 `feedback` 集合
  - 无用户偏好/最近查看记录集合

### 1.2 路由现状

- GoRouter + `StatefulShellRoute.indexedStack`（5 个 tab）
- 已有路由：`/home`、`/spaces`、`/all-work`、`/dashboards`、`/notifications`、`/account`、`/space-details/:spaceId`、`/create-work-item`
- **缺失路由**：工作项详情页、搜索页

### 1.3 遵循的技能包

| 技能包 | 用途 |
|--------|------|
| `skills/ottersync-flutter-style/SKILL.md` | 代码风格、目录结构、组件命名 |
| `skills/ottersync-flutter-style/references/clean_style.md` | 风格基线 |
| `skills/firebase-develop/firebase-basics/SKILL.md` | Firebase CLI 基础 |
| `skills/firebase-develop/firebase-firestore-standard/SKILL.md` | Firestore 数据操作 |
| `skills/firebase-develop/firebase-auth-basics/SKILL.md` | 安全规则与认证 |

---

## 2. 开发前置条件

### 2.1 Firestore 新增集合

以下集合需要在开发过程中按需创建：

| 集合 | 文档结构 | 用途 | 引入阶段 |
|------|----------|------|----------|
| `feedback` | `{id, userId, targetType, targetId, type(like/dislike), createdAt}` | 概述卡片反馈 | 阶段三 |
| `recentViews` | `{id, userId, targetType, targetId, viewedAt}` | 最近查看记录 | 阶段五 |
| `userPreferences` | `{uid, quickAccessOrder, defaultDashboardId}` | 用户偏好设置 | 阶段六 |

### 2.2 新增路由

| 路由 | 页面 | 引入阶段 |
|------|------|----------|
| `/work-item/:workItemId` | 工作项详情页 | 阶段二 |
| `/search` | 搜索页 | 阶段四 |

### 2.3 WorkItemApi 需扩展的方法

按阶段逐步添加：

| 方法 | 签名 | 引入阶段 |
|------|------|----------|
| `getWorkItemById` | `Future<WorkItemResponse?> getWorkItemById(int id)` | 阶段二 |
| `updateWorkItemStatus` | `Future<void> updateWorkItemStatus(int id, WorkItemStatus status)` | 阶段五 |
| `updateWorkItemAssignee` | `Future<void> updateWorkItemAssignee(int id, int? assigneeId)` | 阶段五 |
| `submitFeedback` | `Future<void> submitFeedback({...})` | 阶段三 |
| `getFeedbackStatus` | `Future<String?> getFeedbackStatus({...})` | 阶段三 |
| `cancelFeedback` | `Future<void> cancelFeedback({...})` | 阶段三 |
| `searchWorkItems` | `Future<List<IssueSummary>> searchWorkItems(String query)` | 阶段四 |
| `searchSpaces` | `Future<List<JiraSpace>> searchSpaces(String query)` | 阶段四 |
| `createBacklogItem` | `Future<void> createBacklogItem(...)` | 阶段六 |
| `updateWorkspace` | `Future<void> updateWorkspace(int id, {...})` | 阶段六 |
| `deleteWorkspace` | `Future<void> deleteWorkspace(int id)` | 阶段六 |
| `recordRecentView` | `Future<void> recordRecentView(...)` | 阶段五 |

---

## 3. 分阶段开发计划

---

### 阶段一：纯客户端功能

**目标**：实现 4 处无需后端的纯客户端交互
**涉及接口**：4 处
**预计工时**：0.5 天
**无需新增集合/路由/API 方法**

#### 1.1 摘要内容复制（Home）

- **文件**：`lib/pages/Home/index.dart` 第 102 行
- **当前代码**：`onCopy: () => showDemoFeedback(context, '摘要内容复制接口已预留。')`
- **实现方案**：
  ```dart
  onCopy: () async {
    await Clipboard.setData(ClipboardData(text: description));
    if (context.mounted) {
      showDemoFeedback(context, '已复制到剪贴板');
    }
  },
  ```
- **依赖**：`import 'package:flutter/services.dart';`

#### 1.2 仪表板切换（Dashboard）

- **文件**：`lib/pages/Dashboard/index.dart` 第 62 行
- **当前代码**：`onTap: () => showDemoFeedback(context, '仪表板切换接口已预留。')`
- **实现方案**：
  - 当前只有一个默认仪表板，切换功能暂时弹出 BottomSheet 显示"暂无其他仪表板"
  - 后续有多个仪表板数据时再扩展
  ```dart
  onTap: () {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('默认仪表板'),
              leading: Icon(Icons.dashboard_rounded, color: palette.primary),
              trailing: Icon(Icons.check_rounded, color: palette.primary),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('暂无其他仪表板', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  },
  ```

#### 1.3 设置项视图（Account）

- **文件**：`lib/pages/Account/index.dart` 第 112 行
- **当前代码**：`onTap: (item) => showDemoFeedback(context, '${item.title} 视图未实现。')`
- **实现方案**：
  - "通知设置"和"设置"暂时显示 SnackBar 提示"功能开发中"
  - 不新增页面，保持 showDemoFeedback 但更新提示文案为"功能开发中，敬请期待"
- **修改**：更新提示文案

#### 1.4 设置项操作（Account）

- **文件**：`lib/pages/Account/index.dart` 第 126 行
- **当前代码**：`onTap: (item) => showDemoFeedback(context, '${item.title} 操作已代理。')`
- **实现方案**：
  - "提供反馈"→ 打开邮件或显示反馈表单（暂用 SnackBar）
  - "评价我们"→ 暂用 SnackBar 提示
  - "更多 Atlassian 应用"→ 暂用 SnackBar 提示
- **修改**：更新提示文案，区分不同操作

#### 阶段一检查清单

- [ ] 剪贴板复制功能正常工作
- [ ] 仪表板切换弹出 BottomSheet
- [ ] Account 设置项文案更新
- [ ] `flutter analyze` 无新增警告
- [ ] 所有页面手动测试通过

#### 阶段一 Git 提交

```
feat(client): 实现纯客户端预留接口（剪贴板、仪表板切换、设置项）

- Home 概述卡片复制功能接入系统剪贴板
- Dashboard 仪表板切换弹出选择面板
- Account 设置项操作文案更新
```

---

### 阶段二：导航与详情页

**目标**：新建工作项详情页，打通各页面的导航跳转
**涉及接口**：6 处
**预计工时**：1.5 天
**新增**：1 个页面、1 个路由、1 个 API 方法

#### 2.1 WorkItemApi 扩展

- **文件**：`lib/viewmodels/work_item_api.dart`
- **新增方法**：
  ```dart
  /// 根据 ID 获取工作项详情
  Future<WorkItemResponse?> getWorkItemById(int id) async {
    return _guard(() async {
      await _ensureSeedData();
      final doc = await _workItemsCollection.doc(id.toString()).get();
      if (!doc.exists) return null;
      return WorkItemResponse.fromMap(doc.data() as Map<String, dynamic>);
    });
  }
  ```

#### 2.2 工作项详情页

- **新文件**：`lib/pages/WorkItemDetail/index.dart`
- **遵循技能**：`skills/ottersync-flutter-style/SKILL.md` — 页面放在 `lib/pages/<Feature>/index.dart`
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
- **数据加载**：通过 `WorkItemApi().getWorkItemById(workItemId)` 获取
- **UI 组件**：复用 `AppSurface`、`IssueSummary` 相关样式

#### 2.3 路由注册

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

#### 2.4 各页面导航接入

| 页面 | 文件位置 | 当前代码 | 修改 |
|------|----------|----------|------|
| Home | `lib/pages/Home/index.dart` 第 211、225、249 行 | `showDemoFeedback(context, '将打开 ${item.key} 的详情页。')` | `context.push('/work-item/${item.id}')` |
| AllWork | `lib/pages/AllWork/index.dart` 第 159 行 | `showDemoFeedback(context, '将打开 ${item.title}。')` | `context.push('/work-item/${item.id}')` |
| Dashboard | `lib/pages/Dashboard/index.dart` 第 108 行 | `showDemoFeedback(context, '将打开 ${item.key}。')` | `context.push('/work-item/${item.id}')` |
| Dashboard | `lib/pages/Dashboard/index.dart` 第 115 行 | `showDemoFeedback(context, '将打开 ${item.issue} 的活动详情。')` | 从 `item.issue`（如 "PROJ-5"）解析出数字 ID，调用 `getWorkItemById` 后跳转 `/work-item/:id` |
| Notifications | `lib/pages/Notifications/index.dart` 第 99 行 | `showDemoFeedback(context, '${item.title} 已保留详情入口。')` | `context.push('/work-item/${item.id}')` |

**前置改动**：`IssueSummary` 模型增加 `int? id` 字段，所有构造 `IssueSummary` 的地方补充 id 传参。`NotificationItem` 模型增加 `int? workItemId` 字段。

#### 2.5 快速访问项交互（Home）

- **文件**：`lib/pages/Home/index.dart` 第 169 行
- **当前代码**：`showDemoFeedback(context, '${item.title} 交互入口已预留。')`
- **实现方案**：
  - 有 `route` 的项目已正确跳转
  - 无 `route` 的项目（如来自 API 的快速访问项）跳转到对应空间详情
  - 需要在 `QuickAccessItem` 模型中增加 `spaceId` 字段用于导航

#### 阶段二检查清单

- [ ] 工作项详情页正确显示所有字段
- [ ] 从 Home、AllWork、Dashboard、Notifications 均可跳转到详情页
- [ ] 详情页加载失败时显示错误状态
- [ ] 快速访问项无 route 时有合理的降级行为
- [ ] `flutter analyze` 无警告
- [ ] 各入口跳转测试通过

#### 阶段二 Git 提交

```
feat(detail): 新建工作项详情页，打通各页面导航跳转

- 新增 WorkItemDetailView 页面，展示工作项完整信息
- 新增 WorkItemApi.getWorkItemById 方法
- 注册 /work-item/:workItemId 路由
- 接入 Home、AllWork、Dashboard、Notifications 的详情跳转
- QuickAccessItem 模型增加 spaceId 字段
```

---

### 阶段三：反馈与剪贴板

**目标**：实现反馈提交功能（点赞/踩），需要新增 Firestore 集合
**涉及接口**：3 处
**预计工时**：1 天
**新增**：1 个集合、1 个 API 方法
**遵循技能**：`skills/firebase-develop/firebase-firestore-standard/SKILL.md`

#### 3.1 Firestore 集合设计

**集合名**：`feedback`

**文档结构**：
```
feedback/{id}
├── id: int (自增 ID)
├── userId: string (当前用户 UID)
├── targetType: string ("overview" | "workItem" | "dashboard")
├── targetId: string (关联目标 ID，overview 时为 "daily")
├── type: string ("like" | "dislike")
├── comment: string? (可选备注)
├── createdAt: Timestamp
```

**索引**：
- 复合索引：`userId` + `targetType` + `targetId`（用于查询用户是否已反馈）

#### 3.2 安全规则更新

- **文件**：`firestore.rules`
- **新增规则**：
  ```
  match /feedback/{id} {
    allow read: if isSignedIn();
    allow create: if isSignedIn()
      && request.resource.data.userId == request.auth.uid
      && request.resource.data.type in ['like', 'dislike'];
    allow delete: if isSignedIn() && resource.data.userId == request.auth.uid; // 仅创建者可取消
    allow update: if false;
  }
  ```
- **遵循技能**：`skills/firebase-develop/firebase-auth-basics/SKILL.md` — 安全规则参考

#### 3.3 WorkItemApi 扩展

- **文件**：`lib/viewmodels/work_item_api.dart`
- **新增方法**：
  ```dart
  /// 提交反馈（点赞/踩）
  Future<void> submitFeedback({
    required String targetType,
    required String targetId,
    required String type, // 'like' | 'dislike'
    String? comment,
  }) async {
    return _guard(() async {
      await _ensureSeedData();
      final id = await _nextId('feedback');
      await _feedbackCollection.doc(id.toString()).set({
        'id': id,
        'userId': _currentUid,
        'targetType': targetType,
        'targetId': targetId,
        'type': type,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
  ```
- **新增集合常量**：
  ```dart
  static const _feedbackCollectionName = 'feedback';
  CollectionReference get _feedbackCollection =>
      _firestore.collection(_feedbackCollectionName);
  ```

#### 3.4 Seed 数据更新

- **文件**：`lib/viewmodels/work_item_api.dart` 的 `_ensureSeedData` 方法
- **修改**：在 `_meta/counters` 中增加 `feedback: 0` 计数器

#### 3.5 UI 接入

| 页面 | 文件位置 | 接口 | 修改 |
|------|----------|------|------|
| Home | `lib/pages/Home/index.dart` 第 103 行 | 点赞 | 调用 `submitFeedback(targetType: 'overview', targetId: 'daily', type: 'like')` |
| Home | `lib/pages/Home/index.dart` 第 104 行 | 踩 | 调用 `submitFeedback(targetType: 'overview', targetId: 'daily', type: 'dislike')` |
| Dashboard | `lib/pages/Dashboard/index.dart` 第 120 行 | 反馈提交 | 调用 `submitFeedback(targetType: 'dashboard', targetId: 'default', type: 'like')` |

**UI 交互细节**：
- 点赞/踩后按钮变为选中状态（颜色变化）
- 已点赞时再次点击取消点赞（删除 feedback 记录）
- 已踩时再次点击取消踩（删除 feedback 记录）
- 点赞时自动取消已有的踩，反之亦然
- 需要在 `HomeOverviewCard` 中增加 `isLiked`/`isDisliked` 状态
- 实现方式：进入页面时查询当前用户对该目标的已有 feedback 记录，设置初始状态

**WorkItemApi 新增查询方法**：
```dart
/// 查询当前用户对某目标的反馈状态
Future<String?> getFeedbackStatus({
  required String targetType,
  required String targetId,
}) async {
  return _guard(() async {
    await _ensureSeedData();
    final snapshot = await _feedbackCollection
        .where('userId', isEqualTo: _currentUid)
        .where('targetType', isEqualTo: targetType)
        .where('targetId', isEqualTo: targetId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.get('type') as String;
  });
}

/// 取消反馈
Future<void> cancelFeedback({
  required String targetType,
  required String targetId,
}) async {
  return _guard(() async {
    await _ensureSeedData();
    final snapshot = await _feedbackCollection
        .where('userId', isEqualTo: _currentUid)
        .where('targetType', isEqualTo: targetType)
        .where('targetId', isEqualTo: targetId)
        .limit(1)
        .get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  });
}
```

#### 3.6 HomeOverviewCard 改造

- **文件**：`lib/components/Home/HomeOverviewCard.dart`
- **修改**：
  - 增加 `isLiked`、`isDisliked` 参数
  - 点赞按钮选中时显示填充图标（`Icons.thumb_up_alt`）
  - 踩按钮选中时显示填充图标（`Icons.thumb_down_alt`）
  - 选中状态颜色使用 `palette.primary`

#### 阶段三检查清单

- [ ] `feedback` 集合正确创建
- [ ] 安全规则部署成功
- [ ] 点赞/踩数据写入 Firestore
- [ ] 重复点赞/踩正确处理（取消机制）
- [ ] 按钮状态视觉反馈正确
- [ ] `flutter analyze` 无警告

#### 阶段三 Git 提交

```
feat(feedback): 实现反馈提交功能（点赞/踩）

- 新增 Firestore feedback 集合及安全规则
- WorkItemApi 新增 submitFeedback 方法
- HomeOverviewCard 支持点赞/踩状态切换
- Dashboard 反馈卡片接入提交功能
```

---

### 阶段四：搜索功能

**目标**：实现工作项和空间的搜索功能
**涉及接口**：2 处
**预计工时**：1.5 天
**新增**：1 个页面、1 个路由、2 个 API 方法

#### 4.1 WorkItemApi 扩展

- **文件**：`lib/viewmodels/work_item_api.dart`
- **新增方法**：
  ```dart
  /// 搜索工作项（客户端过滤）
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
      return filtered.map(IssueSummary.fromMap).toList();
    });
  }

  /// 搜索空间
  Future<List<JiraSpace>> searchSpaces(String query) async {
    return _guard(() async {
      await _ensureSeedData();
      if (query.trim().isEmpty) return [];
      final snapshot = await _workspacesCollection.get();
      final lowerQuery = query.toLowerCase();
      return snapshot.docs
          .map((doc) => JiraSpace.fromMap(doc.data() as Map<String, dynamic>))
          .where((space) =>
              space.name.toLowerCase().contains(lowerQuery) ||
              space.key.toLowerCase().contains(lowerQuery))
          .toList();
    });
  }
  ```

**说明**：当前阶段保持客户端过滤方案，与现有 `listWorkItems` 一致。后续可升级为 Firestore 复合索引查询。

#### 4.2 搜索页

- **新文件**：`lib/pages/Search/index.dart`
- **页面结构**：
  ```
  SearchView (StatefulWidget)
  ├── AppBar: 搜索输入框（自动聚焦）+ 取消按钮
  ├── Body: 根据搜索词动态显示结果
  │   ├── 搜索中: CircularProgressIndicator
  │   ├── 有结果: ListView of IssueSummary / JiraSpace
  │   └── 无结果: EmptyStateView
  ```
- **搜索范围**：可通过参数控制搜索 `workItems` 或 `spaces`
- **防抖**：输入 300ms 后自动触发搜索

#### 4.3 路由注册

- **文件**：`lib/routes/index.dart`详情页
- **新增路由**：
  ```dart
  GoRoute(
    path: '/search',
    builder: (context, state) {
      final scope = state.uri.queryParameters['scope'] ?? 'workItems';
      return SearchView(scope: scope);
    },
  ),
  ```

#### 4.4 UI 接入

| 页面 | 文件位置 | 接口 | 修改 |
|------|----------|------|------|
| AllWork | `lib/pages/AllWork/index.dart` 第 68 行 | 搜索工作项 | `context.push('/search?scope=workItems')` |
| Spaces | `lib/pages/Spaces/index.dart` 第 61 行 | 搜索空间 | `context.push('/search?scope=spaces')` |

#### 阶段四检查清单

- [ ] 搜索页正确显示，输入框自动聚焦
- [ ] 工作项搜索结果正确（按 summary、key、description 匹配）
- [ ] 空间搜索结果正确（按 name、key 匹配）
- [ ] 空搜索词不触发搜索
- [ ] 搜索无结果时显示空状态
- [ ] 搜索结果点击可跳转详情
- [ ] `flutter analyze` 无警告

#### 阶段四 Git 提交

```
feat(search): 实现工作项和空间搜索功能

- 新增 SearchView 页面，支持工作项和空间搜索
- WorkItemApi 新增 searchWorkItems 和 searchSpaces 方法
- 注册 /search 路由，支持 scope 参数
- AllWork 和 Spaces 搜索按钮接入搜索页
```

---

### 阶段五：工作项更新与筛选

**目标**：实现工作项状态更新、筛选器应用、最近查看记录
**涉及接口**：4 处
**预计工时**：2 天
**新增**：1 个集合、3 个 API 方法

#### 5.1 Firestore 集合设计

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

**说明**：使用 `{userId}_{targetId}` 作为文档 ID，实现同一用户对同一工作项只保留一条记录，通过 `set` 覆盖更新。

#### 5.2 安全规则更新

- **文件**：`firestore.rules`
- **新增规则**：
  ```
  match /recentViews/{id} {
    allow read: if isSignedIn();
    allow create, update: if isSignedIn();
    allow delete: if isSignedIn();
  }
  ```

#### 5.3 WorkItemApi 扩展

- **文件**：`lib/viewmodels/work_item_api.dart`
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

#### 5.4 工作项详情页集成

- **文件**：`lib/pages/WorkItemDetail/index.dart`（阶段二新建）
- **修改**：
  - 进入详情页时调用 `recordRecentView`
  - 详情页展示当前状态，支持状态切换（待办 → 进行中 → 已完成）
  - 状态切换后调用 `updateWorkItemStatus`

#### 5.5 空间详情筛选（SpaceDetails）

- **文件**：`lib/pages/SpaceDetails/index.dart` 第 71 行
- **当前代码**：`onPressed: () => showDemoFeedback(context, '空间筛选接口已预留。')`
- **实现方案**：
  - 弹出筛选 BottomSheet，支持按状态（待办/进行中/已完成）筛选
  - 筛选结果刷新当前 tab 的数据
  - 复用现有的 `FilterItem` 模型

#### 5.6 按状态筛选工作项（SpaceDetails Summary）

- **文件**：`lib/pages/SpaceDetails/index.dart` 第 124 行
- **当前代码**：`onStatusTap: (status) => showDemoFeedback(context, '将按$status筛选工作项。')`
- **实现方案**：
  - 点击状态标签后切换到面板 tab 并高亮对应状态列
  - 或弹出该状态下的工作项列表 BottomSheet

#### 5.7 AllWork 筛选器应用

- **文件**：`lib/pages/AllWork/index.dart`
- **当前代码**：选择了筛选器但没有实际过滤
- **实现方案**：
  - 在 `_AllWorkViewState` 中增加 `_selectedFilter` 状态
  - 选择筛选器后，根据筛选器类型过滤 `_workItems` 列表
  - 筛选逻辑在客户端实现（与现有架构一致）

#### 阶段五检查清单

- [ ] 进入详情页自动记录最近查看
- [ ] 工作项状态可在详情页切换
- [ ] 状态更新同步到 Firestore
- [ ] 空间筛选 BottomSheet 正常工作
- [ ] Summary 状态标签点击有响应
- [ ] AllWork 筛选器正确过滤列表
- [ ] `flutter analyze` 无警告

#### 阶段五 Git 提交

```
feat(workflow): 实现工作项更新、筛选和最近查看记录

- 新增 Firestore recentViews 集合及安全规则
- WorkItemApi 新增 updateWorkItemStatus、updateWorkItemAssignee、recordRecentView
- 工作项详情页支持状态切换和查看记录
- SpaceDetails 支持按状态筛选
- AllWork 筛选器应用实际过滤逻辑
```

---

### 阶段六：空间操作与待办创建

**目标**：实现空间更多操作、待办创建、通知详情
**涉及接口**：4 处
**预计工时**：1.5 天

#### 6.1 更多空间操作（SpaceDetails）

- **文件**：`lib/pages/SpaceDetails/index.dart` 第 75 行
- **当前代码**：`onPressed: () => showDemoFeedback(context, '更多空间操作接口已预留。')`
- **实现方案**：
  - 弹出 `PopupMenuButton` 或 BottomSheet
  - 菜单项：
    - 编辑空间名称
    - 归档空间
    - 删除空间（需确认对话框）
  - 编辑和删除调用 `WorkItemApi` 对应方法

#### 6.2 WorkItemApi 扩展

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
      // 先删除该空间下的所有工作项
      final workItems = await _workItemsCollection
          .where('workspaceId', isEqualTo: id)
          .get();
      final batch = _firestore.batch();
      for (final doc in workItems.docs) {
        batch.delete(doc.reference);
      }
      // 再删除空间本身
      batch.delete(_workspacesCollection.doc(id.toString()));
      await batch.commit();
    });
  }

  /// 创建待办事项（简化版，仅需 summary 和 workspaceId）
  Future<WorkItemResponse> createBacklogItem({
    required int workspaceId,
    required String summary,
    String? description,
  }) async {
    return createWorkItem(WorkItemCreateRequest(
      workspaceId: workspaceId,
      workTypeId: 1, // 默认 Task
      summary: summary,
      reporterId: 1, // 默认当前用户
      bucket: WorkItemBucket.backlog,
      status: WorkItemStatus.todo,
      description: description,
    ));
  }
  ```

#### 6.3 创建待办事项（SpaceDetails Backlog）

- **文件**：`lib/pages/SpaceDetails/index.dart` 第 141 行
- **当前代码**：`onCreate: () => showDemoFeedback(context, '创建待办事项接口已预留。')`
- **实现方案**：
  - 弹出简易创建对话框（仅需输入 summary）
  - 调用 `createBacklogItem` 方法
  - 创建成功后刷新 backlog 列表

#### 6.4 通知详情（Notifications）

- **文件**：`lib/pages/Notifications/index.dart` 第 99 行
- **当前代码**：`showDemoFeedback(context, '${item.title} 已保留详情入口。')`
- **实现方案**：
  - 如果 `NotificationItem` 有关联的工作项 ID，跳转到 `/work-item/:id`
  - 如果是系统通知，显示详情 BottomSheet
  - 需要在 `NotificationItem` 模型中增加 `workItemId` 字段

#### 6.5 模型更新

- **文件**：`lib/viewmodels/jira_models.dart`
- **修改**：`NotificationItem` 增加 `int? workItemId` 字段

#### 阶段六检查清单

- [ ] 空间更多操作弹出菜单
- [ ] 编辑空间名称功能正常
- [ ] 删除空间需确认对话框
- [ ] 待办事项创建成功并出现在 backlog
- [ ] 通知点击可跳转关联工作项
- [ ] `flutter analyze` 无警告

#### 阶段六 Git 提交

```
feat(space): 实现空间操作、待办创建和通知详情

- SpaceDetails 更多操作菜单（编辑/删除空间）
- WorkItemApi 新增 updateWorkspace、deleteWorkspace、createBacklogItem
- Backlog 创建待办事项对话框
- Notifications 通知详情跳转
```

---

## 4. 待确认问题

在开发过程中需要与你确认以下问题：

### 4.1 数据模型问题

| # | 问题 | 决策 | 说明 |
|---|------|------|------|
| Q1 | `IssueSummary` 增加 `id` 字段 | **采纳，增加 `id`** | 直接 `context.push('/work-item/${item.id}')`，简单可靠。模型已有 `workspaceId`，补 `id` 保持一致 |
| Q2 | `DashboardActivityItem` 的 `issue` 字段格式 | **确认为 "PROJ-5" 格式** | 通过 key 解析出 workspaceKey + 数字 ID，查询 Firestore 获取完整工作项后跳转 |
| Q3 | `NotificationItem` 关联 `workItemId` | **采纳，增加 `workItemId`** | 当前只有 title 和 description，增加字段后可跳转到具体工作项 |

### 4.2 业务逻辑问题

| # | 问题 | 决策 | 说明 |
|---|------|------|------|
| Q4 | 点赞/踩防重复 | **再次点击取消** | 查询已有反馈，有则删除，无则创建。点赞时自动取消已有的踩，反之亦然 |
| Q5 | 搜索历史 | 暂不实现 | 后续可扩展 |
| Q6 | 空间删除级联 | **级联删除** | 删除空间时同步删除该空间下所有工作项 |
| Q7 | 筛选器持久化 | 暂不实现 | 当前刷新重置，后续可存入 `userPreferences` |

### 4.3 UI/UX 问题

| # | 问题 | 决策 | 说明 |
|---|------|------|------|
| Q8 | 详情页编辑功能 | **暂不做，后续迭代** | 当前阶段目标是打通导航和展示。编辑涉及字段级表单、状态机、并发冲突，复杂度远高于展示，放后续迭代 |
| Q9 | 搜索高亮 | 暂不实现 | 后续可扩展 |

---

## 5. 接口清单汇总

| 阶段 | 接口 | 页面 | 类型 | 状态 |
|------|------|------|------|------|
| 一 | 摘要内容复制 | Home | 客户端 | 待开发 |
| 一 | 仪表板切换 | Dashboard | 客户端 | 待开发 |
| 一 | 设置项视图 | Account | 客户端 | 待开发 |
| 一 | 设置项操作 | Account | 客户端 | 待开发 |
| 二 | 工作项详情页 | Home/AllWork/Dashboard/Notifications | 导航 | 待开发 |
| 二 | 通知详情入口 | Notifications | 导航 | 待开发 |
| 二 | 快速访问项交互 | Home | 导航 | 待开发 |
| 三 | 反馈提交（点赞） | Home | 写入 | 待开发 |
| 三 | 反馈提交（踩） | Home | 写入 | 待开发 |
| 三 | 反馈提交（Dashboard） | Dashboard | 写入 | 待开发 |
| 四 | 搜索工作项 | AllWork | 查询 | 待开发 |
| 四 | 搜索空间 | Spaces | 查询 | 待开发 |
| 五 | 空间筛选 | SpaceDetails | 筛选 | 待开发 |
| 五 | 按状态筛选工作项 | SpaceDetails | 筛选 | 待开发 |
| 五 | AllWork 筛选器应用 | AllWork | 筛选 | 待开发 |
| 六 | 更多空间操作 | SpaceDetails | CRUD | 待开发 |
| 六 | 创建待办事项 | SpaceDetails | CRUD | 待开发 |
| 六 | 通知详情 | Notifications | 导航 | 待开发 |

---

## 开发流程规范

每个阶段的开发流程：

1. **开发**：按阶段任务清单逐项实现
2. **自检**：运行 `flutter analyze`，确认无新增警告
3. **测试**：手动测试所有改动的功能点
4. **审查**：对照阶段检查清单逐项确认
5. **提交**：按约定的 commit message 格式 git commit
6. **推进**：进入下一阶段

**代码审查重点**：
- 是否遵循 `skills/ottersync-flutter-style/SKILL.md` 的目录和命名规范
- 是否使用 `package:` 导入
- 是否复用现有设计令牌（`AppPalette`、`AppSpace` 等）
- Firestore 操作是否包含错误处理（`_guard` 包裹）
- 安全规则是否正确配置

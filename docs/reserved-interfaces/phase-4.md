# 阶段四：搜索功能

**目标**：实现工作项和空间的搜索功能
**涉及接口**：2 处
**预计工时**：1.5 天
**新增**：1 个页面、1 个路由、2 个 API 方法

---

## 4.1 WorkItemApi 扩展

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

**说明**：保持客户端过滤，与现有架构一致。

## 4.2 搜索页

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
- **搜索范围**：参数 `scope` 控制搜索 `workItems` 或 `spaces`
- **防抖**：输入 300ms 后自动触发

## 4.3 路由注册

- **文件**：`lib/routes/index.dart`
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

## 4.4 UI 接入

| 页面 | 文件位置 | 修改 |
|------|----------|------|
| AllWork | `lib/pages/AllWork/index.dart` 第 68 行 | `context.push('/search?scope=workItems')` |
| Spaces | `lib/pages/Spaces/index.dart` 第 61 行 | `context.push('/search?scope=spaces')` |

---

## 检查清单

- [ ] 搜索页正确显示，输入框自动聚焦
- [ ] 工作项搜索结果正确（summary、key、description）
- [ ] 空间搜索结果正确（name、key）
- [ ] 空搜索词不触发搜索
- [ ] 搜索无结果时显示空状态
- [ ] 搜索结果点击可跳转详情
- [ ] `flutter analyze` 无警告

## Git 提交

```
feat(search): 实现工作项和空间搜索功能

- 新增 SearchView 页面，支持工作项和空间搜索
- WorkItemApi 新增 searchWorkItems 和 searchSpaces 方法
- 注册 /search 路由，支持 scope 参数
- AllWork 和 Spaces 搜索按钮接入搜索页
```

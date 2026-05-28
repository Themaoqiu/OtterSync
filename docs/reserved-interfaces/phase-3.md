# 阶段三：反馈提交

**目标**：实现反馈提交功能（点赞/踩）
**涉及接口**：3 处
**预计工时**：1 天
**新增**：1 个集合、3 个 API 方法
**遵循技能**：`skills/firebase-develop/firebase-firestore-standard/SKILL.md`

---

## 3.1 Firestore 集合设计

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

**索引**：复合索引 `userId` + `targetType` + `targetId`

## 3.2 安全规则更新

- **文件**：`firestore.rules`
- **新增规则**：
  ```
  match /feedback/{id} {
    allow read: if isSignedIn();
    allow create: if isSignedIn()
      && request.resource.data.userId == request.auth.uid
      && request.resource.data.type in ['like', 'dislike'];
    allow delete: if isSignedIn() && resource.data.userId == request.auth.uid;
    allow update: if false;
  }
  ```

## 3.3 WorkItemApi 扩展

- **文件**：`lib/viewmodels/work_item_api.dart`
- **新增集合常量**：
  ```dart
  static const _feedbackCollectionName = 'feedback';
  CollectionReference get _feedbackCollection =>
      _firestore.collection(_feedbackCollectionName);
  ```
- **新增方法**：
  ```dart
  /// 提交反馈（点赞/踩）
  Future<void> submitFeedback({
    required String targetType,
    required String targetId,
    required String type,
    String? comment,
  }) async { ... }

  /// 查询当前用户对某目标的反馈状态
  Future<String?> getFeedbackStatus({
    required String targetType,
    required String targetId,
  }) async { ... }

  /// 取消反馈
  Future<void> cancelFeedback({
    required String targetType,
    required String targetId,
  }) async { ... }
  ```

## 3.4 Seed 数据更新

- `_ensureSeedData` 中 `_meta/counters` 增加 `feedback: 0`

## 3.5 UI 接入

| 页面 | 文件位置 | 接口 | 修改 |
|------|----------|------|------|
| Home | `lib/pages/Home/index.dart` 第 103 行 | 点赞 | 调用 `submitFeedback(type: 'like')` |
| Home | `lib/pages/Home/index.dart` 第 104 行 | 踩 | 调用 `submitFeedback(type: 'dislike')` |
| Dashboard | `lib/pages/Dashboard/index.dart` 第 120 行 | 反馈 | 调用 `submitFeedback(type: 'like')` |

**交互逻辑**：
- 进入页面时查询 `getFeedbackStatus` 设置初始状态
- 点赞时：如有踩→先取消踩→再点赞；如已赞→取消赞
- 踩时：如有赞→先取消赞→再踩；如已踩→取消踩

## 3.6 HomeOverviewCard 改造

- **文件**：`lib/components/Home/HomeOverviewCard.dart`
- 增加 `isLiked`、`isDisliked` 参数
- 选中时显示填充图标 + `palette.primary` 颜色

---

## 检查清单

- [ ] `feedback` 集合正确创建
- [ ] 安全规则部署成功
- [ ] 点赞/踩数据写入 Firestore
- [ ] 重复点赞/踩正确处理（取消机制）
- [ ] 点赞/踩互斥正确
- [ ] 按钮状态视觉反馈正确
- [ ] `flutter analyze` 无警告

## Git 提交

```
feat(feedback): 实现反馈提交功能（点赞/踩）

- 新增 Firestore feedback 集合及安全规则
- WorkItemApi 新增 submitFeedback、getFeedbackStatus、cancelFeedback
- HomeOverviewCard 支持点赞/踩状态切换（互斥+取消）
- Dashboard 反馈卡片接入提交功能
```

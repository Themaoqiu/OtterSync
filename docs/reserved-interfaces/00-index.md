# 预留接口实现 — 总览

> 版本：v1.0 | 日期：2026-05-21
> 范围：除「AI 创建工作项（图像上传）」外的全部 18 处预留接口
> 技能约束：遵循 `skills/ottersync-flutter-style/SKILL.md` 及 `skills/firebase-develop/` 下相关技能

---

## 分阶段计划

| 阶段 | 内容 | 接口数 | 预计工时 | 文档 |
|------|------|--------|----------|------|
| [阶段一](phase-1.md) | 纯客户端功能 | 4 处 | 0.5 天 | 剪贴板、仪表板切换、设置项 |
| [阶段二](phase-2.md) | 导航与详情页 | 6 处 | 1.5 天 | 工作项详情页 + 各页面跳转 |
| [阶段三](phase-3.md) | 反馈提交 | 3 处 | 1 天 | 点赞/踩 + Firestore 集合 |
| [阶段四](phase-4.md) | 搜索功能 | 2 处 | 1.5 天 | 搜索页 + 工作项/空间搜索 |
| [阶段五](phase-5.md) | 工作项更新与筛选 | 4 处 | 2 天 | 状态更新、筛选器、最近查看 |
| [阶段六](phase-6.md) | 空间操作与待办创建 | 4 处 | 1.5 天 | 空间编辑/删除、待办创建、通知详情 |

---

## 开发前置条件

### Firestore 新增集合

| 集合 | 文档结构 | 用途 | 引入阶段 |
|------|----------|------|----------|
| `feedback` | `{id, userId, targetType, targetId, type, createdAt}` | 概述卡片反馈 | 阶段三 |
| `recentViews` | `{userId, targetId, targetKey, targetTitle, viewedAt}` | 最近查看记录 | 阶段五 |

### 新增路由

| 路由 | 页面 | 引入阶段 |
|------|------|----------|
| `/work-item/:workItemId` | 工作项详情页 | 阶段二 |
| `/search` | 搜索页 | 阶段四 |

### WorkItemApi 扩展方法

| 方法 | 引入阶段 |
|------|----------|
| `getWorkItemById(int id)` | 阶段二 |
| `submitFeedback(...)` / `getFeedbackStatus(...)` / `cancelFeedback(...)` | 阶段三 |
| `searchWorkItems(String query)` / `searchSpaces(String query)` | 阶段四 |
| `updateWorkItemStatus(...)` / `updateWorkItemAssignee(...)` / `recordRecentView(...)` | 阶段五 |
| `updateWorkspace(...)` / `deleteWorkspace(...)` / `createBacklogItem(...)` | 阶段六 |

---

## 已确认决策

| # | 问题 | 决策 |
|---|------|------|
| Q1 | `IssueSummary` 增加 `id` 字段 | 采纳，直接用于详情页跳转 |
| Q2 | `DashboardActivityItem.issue` 格式 | 确认为 "PROJ-5" 格式，解析数字 ID 跳转 |
| Q3 | `NotificationItem` 关联 `workItemId` | 采纳，增加字段用于跳转 |
| Q4 | 点赞/踩防重复 | 再次点击取消，互斥 |
| Q6 | 空间删除级联 | 级联删除关联工作项 |
| Q8 | 详情页编辑功能 | 暂不做，后续迭代 |

---

## 开发流程

每个阶段：开发 → `flutter analyze` → 手动测试 → 对照检查清单 → git commit → 下一阶段

**代码审查重点**：
- 遵循 `skills/ottersync-flutter-style/SKILL.md` 目录和命名规范
- 使用 `package:` 导入
- 复用设计令牌（`AppPalette`、`AppSpace` 等）
- Firestore 操作用 `_guard` 包裹
- 安全规则正确配置

# 阶段一：纯客户端功能

**目标**：实现 4 处无需后端的纯客户端交互
**涉及接口**：4 处
**预计工时**：0.5 天
**无需新增集合/路由/API 方法**

---

## 1.1 摘要内容复制（Home）

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

## 1.2 仪表板切换（Dashboard）

- **文件**：`lib/pages/Dashboard/index.dart` 第 62 行
- **当前代码**：`onTap: () => showDemoFeedback(context, '仪表板切换接口已预留。')`
- **实现方案**：
  - 当前只有一个默认仪表板，弹出 BottomSheet 显示"暂无其他仪表板"
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

## 1.3 设置项视图（Account）

- **文件**：`lib/pages/Account/index.dart` 第 112 行
- **当前代码**：`onTap: (item) => showDemoFeedback(context, '${item.title} 视图未实现。')`
- **修改**：更新提示文案为"功能开发中，敬请期待"

## 1.4 设置项操作（Account）

- **文件**：`lib/pages/Account/index.dart` 第 126 行
- **当前代码**：`onTap: (item) => showDemoFeedback(context, '${item.title} 操作已代理。')`
- **修改**：区分不同操作更新提示文案

---

## 检查清单

- [ ] 剪贴板复制功能正常工作
- [ ] 仪表板切换弹出 BottomSheet
- [ ] Account 设置项文案更新
- [ ] `flutter analyze` 无新增警告
- [ ] 所有页面手动测试通过

## Git 提交

```
feat(client): 实现纯客户端预留接口（剪贴板、仪表板切换、设置项）

- Home 概述卡片复制功能接入系统剪贴板
- Dashboard 仪表板切换弹出选择面板
- Account 设置项操作文案更新
```

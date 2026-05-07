# 🦦 OtterSync

OtterSync 是一个现代化的团队协作与项目管理平台，主要功能复刻自 Jira Mobile。当前客户端使用 Flutter，工作项数据接入改为 Firebase / Cloud Firestore。

## 1. 快速开始

### 1.1 Skills

仓库内置前后端开发约束，位于 `skills/`：

- `skills/ottersync-flutter-style/SKILL.md`：Flutter 代码风格、目录组织和 UI 约定
- `skills/ottersync-python-backend/SKILL.md`：仓库内历史 Python 后端代码的开发约定

### 1.2 前端开发

前端代码位于 `lib/`，使用 Flutter 框架开发，注意每次开发时都先拉取新代码。

每次启动都先更新依赖：

```bash
flutter pub get
```

运行应用：

```bash
flutter run
```

检查与测试：

```bash
flutter analyze
flutter test
```

### 1.3 Firebase 配置

项目以 Firebase / Cloud Firestore 作为工作项存储层。仓库已包含各平台的配置文件，clone 后即可直接运行：

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `macos/Runner/GoogleService-Info.plist`

客户端使用 `firebase_core` + `cloud_firestore`，首次启动会在 Firestore 中自动写入一批默认工作区、用户、标签和示例工作项，便于直接演示。

如需接入自己的 Firebase 项目，可用 FlutterFire CLI 重新生成配置覆盖：

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

## 2. 代码结构

### 2.1 前端结构

```text
lib/
├── main.dart
├── components/
│   ├── Account/
│   ├── AllWork/
│   ├── Common/
│   ├── Dashboard/
│   ├── Home/
│   ├── SpaceDetails/
│   └── Spaces/
├── pages/
│   ├── Account/
│   ├── AllWork/
│   ├── Dashboard/
│   ├── Home/
│   ├── Main/
│   ├── Notifications/
│   ├── SpaceDetails/
│   └── Spaces/
├── routes/
│   └── index.dart
├── state/
│   └── theme_controller.dart
├── theme/
│   └── design_tokens.dart
└── viewmodels/
    ├── jira_demo_data.dart
    └── jira_models.dart
```


## 3. 开发约束

### 3.1 前端

- 页面放在 `lib/pages/<Feature>/index.dart`
- 可复用 UI 放在 `lib/components/<Feature>/`
- 入口和路由集中在 `lib/routes/index.dart`
- 优先使用 `package:` 导入


<p align="center">
  <img src="assets/images/otter_logo.png" alt="OtterSync logo" width="180">
</p>

<h1 align="center">OtterSync</h1>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white">
  <img alt="Firebase" src="https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20FCM-FFCA28?logo=firebase&logoColor=black">
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white">

</p>

OtterSync 是一个使用 Flutter 与 Firebase 构建的团队协作和项目管理应用，作为上海电力大学信管专业智能终端开发课程设计。它以 Jira Mobile 的核心体验为参考，提供工作区、工作项、冲刺、通知、搜索、AI 助手和番茄钟等移动端协作功能。符合课程所有要求。

## 功能概览

- 邮箱、Google、Apple 登录
- 工作区创建、成员邀请与邀请审核
- 工作项创建、筛选、详情、反馈与最近访问
- 冲刺、日历、报表和空间设置
- Firestore 实时数据同步
- Firebase Cloud Messaging 推送通知
- AI 聊天入口与本地番茄钟前台服务

## 技术栈

- Flutter / Dart
- Firebase Auth
- Cloud Firestore
- Firebase Cloud Messaging
- Cloud Functions for Firebase
- GoRouter

## 目录结构

```text
lib/
├── components/       # 可复用 UI 组件
├── pages/            # 页面入口
├── routes/           # 路由配置
├── services/         # Firebase、业务数据和系统服务
├── state/            # 应用级状态控制
├── theme/            # 主题与设计 token
└── viewmodels/       # 页面展示模型

functions/            # Firebase Cloud Functions
firestore.rules       # Firestore 安全规则
firestore.indexes.json
firebase.json         # Firebase 部署配置
```

## 本地运行

### 环境要求

- Flutter SDK，匹配 `pubspec.yaml` 中的 Dart SDK 约束
- Node.js 24，用于 Cloud Functions
- Firebase CLI
- 一个已启用 Auth、Firestore、Cloud Messaging 和 Cloud Functions 的 Firebase 项目

### 安装依赖

```bash
flutter pub get
npm --prefix functions install
```

### 配置 Firebase

仓库中已经包含当前演示项目的 FlutterFire 配置文件：

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `macos/Runner/GoogleService-Info.plist`

如果要部署到自己的 Firebase 项目，建议重新生成配置：

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

FlutterFire 会更新 `lib/firebase_options.dart`，并按选择的平台生成对应的 Firebase 客户端配置文件。

### 可选环境变量

项目会尝试读取根目录 `.env`。当前应用可以在没有 `.env` 的情况下启动；如果你接入自己的 AI 或外部服务，可以在 `.env` 中放置对应密钥，并在相关 service 中读取。

### 启动客户端

```bash
flutter run
```

首次进入应用后，客户端会在 Firestore 中初始化必要的默认数据，方便本地演示和开发。

## 部署

### 1. 登录并选择 Firebase 项目

```bash
firebase login
firebase use <your-project-id>
```

也可以直接在部署命令中加 `--project <your-project-id>`，避免误部署到其他项目。

### 2. 部署 Firestore 规则和索引

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

`firestore.rules` 是应用真正的权限边界，限制用户只能访问自己所属工作区、自己的通知、自己的最近访问记录，以及符合邀请状态的工作区邀请。

### 3. 部署 Cloud Functions

```bash
npm --prefix functions install
npm --prefix functions run build
firebase deploy --only functions
```

当前 Cloud Function 会监听 `notifications/{notificationId}` 新文档，并把通知通过 FCM 推送到收件人设备。部署前请确认 Firebase 项目已经启用 Cloud Functions 和 Cloud Messaging。

### 4. 构建客户端

按目标平台构建发布包：

```bash
flutter build apk --release
flutter build appbundle --release
flutter build ios --release
flutter build web --release
```

Android 当前 release 配置仍使用 debug signing，正式上架前需要在 `android/app/build.gradle.kts` 中替换为自己的签名配置，并把 `applicationId` 改成正式包名。

## 验证

提交或部署前建议运行：

```bash
flutter analyze
flutter test
npm --prefix functions run build
```

如果修改了 Firestore 权限，建议同时使用 Firebase Emulator 验证规则行为，再部署到线上项目。

## 开发约定

- 页面放在 `lib/pages/<Feature>/index.dart`
- 可复用组件放在 `lib/components/<Feature>/`
- 业务访问逻辑集中在 `lib/services/`
- 路由集中在 `lib/routes/index.dart`
- 优先使用 `package:` 导入
- Firestore 权限变化需要同步更新客户端逻辑和 `firestore.rules`


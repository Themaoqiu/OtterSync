# 🦦 OtterSync

OtterSync 是一个现代化的团队协作与项目管理平台，主要功能复刻自Jira Mobile，使用 Flutter + Python 的全栈技术栈。

## 1. 快速开始

### 1.1 Skills

仓库内置前后端开发约束，位于 `skills/`：

- `skills/ottersync-flutter-style/SKILL.md`：Flutter 代码风格、目录组织和 UI 约定
- `skills/ottersync-python-backend/SKILL.md`：Python 后端架构、依赖管理和 clean code 约定

### 1.2 前端开发

前端代码位于 `lib/`，使用 Flutter 框架开发。

安装依赖：

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

### 1.3 后端开发

后端目录位于 `src/`，使用 `uv` 管理 Python 环境和依赖。

安装 `uv`：

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

或：

```bash
# macos
brew install uv
```

同步环境：

```bash
cd src
uv sync
```

激活环境：

```bash
source .venv/bin/activate
```

新增依赖：

```bash
uv add fastapi sqlmodel uvicorn pydantic-settings
```

删除依赖：

```bash
uv remove <package_name>
```

不要使用：

```bash
uv pip install
```

运行后端：

```bash
cd src
uv run python main.py
```

导出 OpenAPI 契约：

```bash
cd src
uv run uv run uvicorn main:app --reload --port 8001
curl http://127.0.0.1:8000/openapi.json -o src/openapi.json

uv run --project src openapi-generator-cli generate \
  -i src/openapi.json \ # 输入文件
  -g dart \ # 生成器
  -o client \ # 输出目录
  -p pubName=ottersync_openapi,pubAuthor=OtterSync,pubDescription="Generated OpenAPI client for the OtterSync backend.",pubVersion=0.1.0 
```


推荐技术栈：

- `fastapi`
- `sqlmodel`
- `uvicorn`
- `pytest`
- `ruff`
- `mypy`

后端接口以 FastAPI + Pydantic 定义为唯一契约源，推荐前端直接基于 `openapi.json` 生成 Dart client / model，而不是手工同步字段。

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

### 2.2 后端结构

```text
src/
├── adaptors                         # repository的具体实现
│   ├── __init__.py
│   └── sqlite                       # repository的sqlite数据库存储的具体实现
│       ├── __init__.py
│       ├── model.py
│       └── sqlite_adaptor.py
├── application                      # 对于service的应用层，这个部分是对service(业务逻辑的封装)，提供给外部一个可用的接口、复杂的cli等
│   ├── perception_loop.py
│   └── stroge.py
├── entity                           # 核心业务实体模型(model)，它是最核心的东西，repository/service的输入输出都是它(或者简单类型例如str/boolean)
│   ├── __init__.py
├── generated                        # 从外部schema生成的model，一部分直接可以被抽成entity(这么做是偷懒减少工作量，没有再写一遍直接import)
│   ├── __init__.py
│   ├── model.py
│   ├── perception_model.py
│   └── types.py
├── __init__.py
├── repository.py                    # 存储、外部数据源的抽象层
├── service                          # 核心业务逻辑，不依赖任何外部框架，例如orm、flask、fastapi等，只写业务，它依赖repository(抽象的，而不是adaptor)/entity
│   ├── __init__.py
│   └── storage.py
└── utils                            # 业务不强相关的工具函数
    ├── config.py
    ├── __init__.py
    └── s3_client.py
```

## 3. 开发约束

### 3.1 前端

- 页面放在 `lib/pages/<Feature>/index.dart`
- 可复用 UI 放在 `lib/components/<Feature>/`
- 入口和路由集中在 `lib/routes/index.dart`
- 优先使用 `package:` 导入

### 3.2 后端

- 先定义 `entity` 和 `repository` 抽象，再写 `service`
- `service` 不依赖具体框架，只依赖抽象和实体
- `adaptors` 放 sqlite、s3、第三方 API 等具体实现
- FastAPI 只做路由和依赖注入，不写业务逻辑
- SQLModel 只放在边界层，不进入核心业务逻辑
- 新增依赖必须使用 `uv add`，不要使用 `uv pip install`
- 有行为变化就补测试，避免宽泛异常捕获和深层嵌套

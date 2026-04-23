---
name: ottersync-python-backend
description: Use when creating or modifying the OtterSync Python backend under src/ and the work should follow the repo's layered backend architecture, uv-based dependency workflow, modern Python backend packages, and strict clean-code guardrails.
---

# OtterSync Python Backend

Use this skill when working in `/Users/themaoqiu/CodeRepo/Android/ottersync/src`.

The backend is expected to use:

- `uv` for Python version, virtualenv, lockfile, and dependency management
- `fastapi` for HTTP entrypoints
- `sqlmodel` for database models and persistence integration
- `pydantic-settings` for configuration
- `pytest` for tests
- `ruff` and `mypy` for static checks

## First read

Inspect these files first:

- `src/pyproject.toml`
- any module directly related to the requested feature

If the task is architectural or involves adding new backend modules, align with the structure below before writing code.

## Dependency workflow

Always manage dependencies with `uv`.

Use:

```bash
uv sync
source .venv/bin/activate
uv add <package>
uv add --dev <package>
uv remove <package>
uv run pytest
```

Do not use:

- `pip install`
- `uv pip install`

Reason: dependency changes must stay reflected in `pyproject.toml` and the lockfile, instead of drifting in the local virtualenv.

## Backend architecture

Organize backend code like this:

```text
src/
├── adaptors                         # repository 的具体实现
│   ├── __init__.py
│   └── sqlite                       # repository 的 sqlite 数据库存储的具体实现
│       ├── __init__.py
│       ├── model.py
│       └── sqlite_adaptor.py
├── application                      # 对于 service 的应用层，提供给外部可用接口、复杂 CLI 等
│   ├── perception_loop.py
│   └── stroge.py
├── entity                           # 核心业务实体模型
│   └── __init__.py
├── generated                        # 从外部 schema 生成的 model，可按需抽成 entity
│   ├── __init__.py
│   ├── model.py
│   ├── perception_model.py
│   └── types.py
├── __init__.py
├── repository.py                    # 存储、外部数据源的抽象层
├── service                          # 核心业务逻辑，不依赖 FastAPI / ORM / Flask 等框架
│   ├── __init__.py
│   └── storage.py
└── utils                            # 业务不强相关的工具函数
    ├── config.py
    ├── __init__.py
    └── s3_client.py
```

## Layer rules

- `entity` contains the domain model and core business objects.
- `repository.py` defines persistence or external-source abstractions.
- `service` implements business logic and depends only on `entity` plus repository abstractions.
- `adaptors` implements concrete persistence or third-party integrations such as sqlite or s3.
- `application` orchestrates services into usable entrypoints such as CLI flows, loops, or API-facing handlers.
- `generated` holds generated models from external schemas. Reuse carefully and stop them from leaking everywhere.
- `utils` is for cross-cutting helpers only. Do not move domain logic there.

## FastAPI and SQLModel boundary rules

- Keep FastAPI route handlers thin; they should validate input, call application/service code, and map output.
- Do not place business rules directly inside route functions.
- Keep SQLModel-specific mapping or session details in adaptor implementations, not in domain services.
- Prefer repository interfaces between service code and SQLModel-backed storage.
- If a model is both a transport shape and a persistence shape, be explicit about that compromise instead of letting boundaries blur accidentally.

## FastAPI and OpenAPI contract workflow

- Treat FastAPI route declarations plus Pydantic models as the single source of truth for HTTP contracts.
- Use FastAPI's generated OpenAPI schema to drive API docs, typed clients, or frontend code generation when it reduces duplicated request and response definitions.
- Do not describe this as "no need to define interface parameters". The backend still must explicitly define paths, methods, request models, query/path parameters, response models, and error semantics.
- Prefer keeping transport models explicit and stable so generated OpenAPI remains useful for downstream consumers.
- When the frontend or another client needs typed integration, prefer generating client code or type definitions from `openapi.json` instead of manually duplicating the same shapes.
- If generated client code is introduced, keep generation reproducible and document the command and source schema location in the repo.

## OtterSync OpenAPI generation rule

For this repo, keep the OpenAPI export and Dart client generation workflow fixed and reproducible.

- Start the FastAPI server from `src/` on port `8001`.
- Export the schema from the running FastAPI app into `src/openapi.json`.
- Generate the Dart client with `openapi-generator-cli` into `client/`.
- Do not add ad-hoc schema post-processing scripts just to make Flutter generation pass. If generation breaks, fix the Python-side FastAPI/Pydantic schema definitions first so `openapi.json` itself is correct.
- Do not hand-maintain duplicate Dart request/response models when the generated client already owns that contract.

Use these commands:

```bash
cd src
uv run uvicorn main:app --reload --port 8001
```

In another terminal from the repo root:

```bash
curl http://127.0.0.1:8001/openapi.json -o src/openapi.json

uv run --project src openapi-generator-cli generate \
  -i src/openapi.json \
  -g dart \
  -o client \
  -p pubName=ottersync_openapi,pubAuthor=OtterSync,pubDescription="Generated OpenAPI client for the OtterSync backend.",pubVersion=0.1.0
```

Notes:

- The API process and the `curl` export must use the same port. In this repo that default is `8001`.
- Keep the generated Dart package under `client/` unless the repo is intentionally reorganized.
- If a generated Dart file is invalid, inspect the corresponding OpenAPI schema in `src/openapi.json` and the FastAPI/Pydantic model definitions that produced it before changing generator settings.

## Clean code guardrails

Apply these rules on every backend change:

- Keep functions short and focused.
- Use explicit names and narrow module responsibilities.
- Prefer guard clauses and early returns over deep nesting.
- Target cyclomatic complexity <= 10 per function.
- Avoid duplicate logic; extract reusable helpers when the reuse is real.
- Keep public interfaces small and predictable.

## Error handling

- Catch only expected exceptions that belong to normal business flow.
- Do not add bare `except` or broad `except Exception` unless re-raising immediately with useful context.
- Do not silently swallow errors.
- Let unexpected failures surface so they can be fixed.

## Testing standard

Tests are required for backend behavior changes.

Cover at least:

- happy path
- edge or boundary cases
- expected failure modes

Prefer deterministic unit tests. Avoid unnecessary network, time, randomness, and external service coupling.

## Completion gate

Do not consider backend work complete until all are true:

- architecture boundaries still make sense
- new dependencies were added with `uv add` or `uv add --dev`
- tests were added or updated for changed behavior
- static checks pass
- unexpected errors are not being hidden

## Project-local notes

- The architecture note currently uses `application/stroge.py`; if this file is newly created, prefer standardizing on `storage.py` unless the repo has already committed to the current spelling.
- When adding modern backend capabilities, default to `fastapi`, `sqlmodel`, `pydantic-settings`, `pytest`, `ruff`, and `mypy` before considering heavier alternatives.

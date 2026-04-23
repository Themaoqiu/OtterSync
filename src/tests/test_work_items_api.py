from __future__ import annotations

from pathlib import Path

from fastapi.testclient import TestClient

from main import create_app


def build_client(tmp_path: Path) -> TestClient:
    database_url = f"sqlite:///{tmp_path / 'test.db'}"
    return TestClient(create_app(database_url=database_url))


def create_workspace(client: TestClient, name: str = "ottersync", key: str = "OTTER") -> int:
    response = client.post("/api/workspaces", json={"name": name, "key": key})
    assert response.status_code == 201
    return response.json()["id"]


def create_user(client: TestClient, name: str, email: str) -> int:
    response = client.post("/api/users", json={"name": name, "email": email})
    assert response.status_code == 201
    return response.json()["id"]


def create_team(client: TestClient, name: str = "移动端", key: str = "mobile") -> int:
    response = client.post("/api/teams", json={"name": name, "key": key})
    assert response.status_code == 201
    return response.json()["id"]


def test_create_work_item_with_new_label_and_attachment(tmp_path: Path) -> None:
    client = build_client(tmp_path)

    workspace_id = create_workspace(client)
    reporter_id = create_user(client, "Themaoqiu", "themaoqiu@ottersync.dev")
    assignee_id = create_user(client, "Alice Chen", "alice@ottersync.dev")
    team_id = create_team(client)
    work_type_id = client.get("/api/lookups/work-types", params={"q": "任务"}).json()[0]["id"]

    parent_response = client.post(
        "/api/work-items",
        json={
            "workspace_id": workspace_id,
            "work_type_id": work_type_id,
            "summary": "现有父任务",
            "reporter_id": reporter_id,
        },
    )
    assert parent_response.status_code == 201
    parent_id = parent_response.json()["id"]

    response = client.post(
        "/api/work-items",
        json={
            "workspace_id": workspace_id,
            "work_type_id": work_type_id,
            "summary": "实现首页创建任务弹窗",
            "description": "支持工作空间、工作类型、附件和更多字段。",
            "reporter_id": reporter_id,
            "assignee_id": assignee_id,
            "team_id": team_id,
            "parent_id": parent_id,
            "due_date": "2026-05-01",
            "start_date": "2026-04-23",
            "new_label_names": ["移动端联调", "设计"],
            "attachments": [
                {
                    "name": "create-sheet.png",
                    "kind": "photo",
                    "uri": "file:///attachments/create-sheet.png",
                    "mime_type": "image/png",
                }
            ],
        },
    )

    assert response.status_code == 201
    payload = response.json()
    assert payload["summary"] == "实现首页创建任务弹窗"
    assert payload["reporter"]["title"] == "Themaoqiu"
    assert payload["assignee"]["title"] == "Alice Chen"
    assert payload["team"]["title"] == "移动端"
    assert payload["parent"]["title"] == "现有父任务"
    assert sorted(label["title"] for label in payload["labels"]) == ["移动端联调", "设计"]
    assert payload["attachments"][0]["kind"] == "photo"

    labels_after = client.get("/api/lookups/labels", params={"q": "移动端联调"})
    assert labels_after.status_code == 200
    assert labels_after.json()[0]["title"] == "移动端联调"


def test_create_work_item_requires_reporter(tmp_path: Path) -> None:
    client = build_client(tmp_path)
    workspace_id = create_workspace(client)
    work_type_id = client.get("/api/lookups/work-types", params={"q": "任务"}).json()[0]["id"]

    response = client.post(
        "/api/work-items",
        json={
            "workspace_id": workspace_id,
            "work_type_id": work_type_id,
            "summary": "缺少 reporter 的任务",
        },
    )

    assert response.status_code == 422


def test_parent_lookup_can_filter_by_workspace_and_search(tmp_path: Path) -> None:
    client = build_client(tmp_path)
    target_workspace_id = create_workspace(client, name="ottersync", key="OTTER")
    other_workspace_id = create_workspace(client, name="backend", key="BACK")
    reporter_id = create_user(client, "Themaoqiu", "themaoqiu@ottersync.dev")
    work_type_id = client.get("/api/lookups/work-types", params={"q": "任务"}).json()[0]["id"]

    target_parent = client.post(
        "/api/work-items",
        json={
            "workspace_id": target_workspace_id,
            "work_type_id": work_type_id,
            "summary": "同步异常修复",
            "reporter_id": reporter_id,
        },
    )
    assert target_parent.status_code == 201

    other_parent = client.post(
        "/api/work-items",
        json={
            "workspace_id": other_workspace_id,
            "work_type_id": work_type_id,
            "summary": "同步接口重构",
            "reporter_id": reporter_id,
        },
    )
    assert other_parent.status_code == 201

    response = client.get(
        "/api/lookups/parent-items",
        params={"workspace_id": target_workspace_id, "q": "同步"},
    )

    assert response.status_code == 200
    payload = response.json()
    assert len(payload) == 1
    assert payload[0]["title"] == "同步异常修复"


def test_openapi_validation_error_schema_uses_string_locations(tmp_path: Path) -> None:
    client = build_client(tmp_path)

    response = client.get("/openapi.json")

    assert response.status_code == 200
    schemas = response.json()["components"]["schemas"]
    detail_schema = schemas["ValidationErrorDetail"]
    loc_items = detail_schema["properties"]["loc"]["items"]
    input_schema = detail_schema["properties"]["input"]
    ctx_schema = detail_schema["properties"]["ctx"]

    assert loc_items["type"] == "string"
    assert input_schema["anyOf"][0]["type"] == "string"
    assert ctx_schema["anyOf"][0]["additionalProperties"]["type"] == "string"
    assert "ValidationError" not in schemas
    assert "HTTPValidationError" not in schemas

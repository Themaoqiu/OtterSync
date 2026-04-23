from __future__ import annotations

from fastapi import FastAPI

from adaptors.sqlite.sqlite_adaptor import SQLiteWorkItemRepository
from application.work_items import build_work_item_router
from service.storage import WorkItemService
from utils.config import get_settings


def create_app(database_url: str | None = None) -> FastAPI:
    settings = get_settings()
    repository = SQLiteWorkItemRepository(database_url=database_url or settings.database_url)
    service = WorkItemService(repository)
    service.initialize()

    app = FastAPI(
        title=settings.app_name,
        version="0.1.0",
        summary="OtterSync work item backend",
        description=(
            "OpenAPI contract source for the OtterSync client. "
            "Frontend integrations should generate typed clients and models from this schema "
            "instead of manually duplicating request and response shapes."
        ),
    )
    app.include_router(build_work_item_router(service))

    @app.get("/health")
    def healthcheck() -> dict[str, str]:
        return {"status": "ok"}

    return app


app = create_app()

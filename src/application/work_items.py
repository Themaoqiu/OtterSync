from __future__ import annotations

from datetime import date

from fastapi import APIRouter, HTTPException, Query, status
from pydantic import BaseModel, Field, field_validator

from entity.work_item import AttachmentDraft, AttachmentKind, LookupOption, WorkItemDraft, WorkItemRecord
from service.storage import WorkItemService, WorkItemValidationError


class ValidationErrorDetail(BaseModel):
    loc: list[str]
    msg: str
    type: str
    input: str | None = None
    ctx: dict[str, str] | None = None


class ValidationErrorResponse(BaseModel):
    detail: list[ValidationErrorDetail] = Field(default_factory=list)


class AttachmentCreateRequest(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    kind: AttachmentKind
    uri: str = Field(min_length=1, max_length=2048)
    mime_type: str | None = Field(default=None, max_length=255)

    def to_domain(self) -> AttachmentDraft:
        return AttachmentDraft(
            name=self.name.strip(),
            kind=self.kind,
            uri=self.uri.strip(),
            mime_type=self.mime_type.strip() if self.mime_type else None,
        )


class WorkspaceCreateRequest(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    key: str = Field(min_length=1, max_length=50)


class UserCreateRequest(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    email: str = Field(min_length=1, max_length=200)


class TeamCreateRequest(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    key: str = Field(min_length=1, max_length=50)


class WorkItemCreateRequest(BaseModel):
    workspace_id: int
    work_type_id: int
    summary: str = Field(min_length=1, max_length=200)
    description: str | None = Field(default=None, max_length=4000)
    reporter_id: int
    assignee_id: int | None = None
    parent_id: int | None = None
    team_id: int | None = None
    due_date: date | None = None
    start_date: date | None = None
    label_ids: list[int] = Field(default_factory=list)
    new_label_names: list[str] = Field(default_factory=list)
    attachments: list[AttachmentCreateRequest] = Field(default_factory=list)

    @field_validator("summary")
    @classmethod
    def validate_summary(cls, value: str) -> str:
        normalized_value = value.strip()
        if not normalized_value:
            raise ValueError("summary must not be blank")
        return normalized_value

    @field_validator("description")
    @classmethod
    def validate_description(cls, value: str | None) -> str | None:
        if value is None:
            return None
        normalized_value = value.strip()
        return normalized_value or None

    @field_validator("new_label_names")
    @classmethod
    def validate_new_label_names(cls, value: list[str]) -> list[str]:
        return [item for item in value]

    def to_domain(self) -> WorkItemDraft:
        return WorkItemDraft(
            workspace_id=self.workspace_id,
            work_type_id=self.work_type_id,
            summary=self.summary,
            description=self.description,
            reporter_id=self.reporter_id,
            assignee_id=self.assignee_id,
            parent_id=self.parent_id,
            team_id=self.team_id,
            due_date=self.due_date,
            start_date=self.start_date,
            label_ids=self.label_ids,
            new_label_names=self.new_label_names,
            attachments=[attachment.to_domain() for attachment in self.attachments],
        )


class LookupResponse(BaseModel):
    id: int
    title: str
    subtitle: str | None = None

    @classmethod
    def from_domain(cls, option: LookupOption) -> "LookupResponse":
        return cls(id=option.id, title=option.title, subtitle=option.subtitle)


class AttachmentResponse(BaseModel):
    name: str
    kind: AttachmentKind
    uri: str
    mime_type: str | None = None

    @classmethod
    def from_domain(cls, attachment: AttachmentDraft) -> "AttachmentResponse":
        return cls(
            name=attachment.name,
            kind=attachment.kind,
            uri=attachment.uri,
            mime_type=attachment.mime_type,
        )


class WorkItemResponse(BaseModel):
    id: int
    summary: str
    description: str | None = None
    workspace: LookupResponse
    work_type: LookupResponse
    reporter: LookupResponse
    assignee: LookupResponse | None = None
    parent: LookupResponse | None = None
    team: LookupResponse | None = None
    due_date: date | None = None
    start_date: date | None = None
    labels: list[LookupResponse]
    attachments: list[AttachmentResponse]

    @classmethod
    def from_domain(cls, record: WorkItemRecord) -> "WorkItemResponse":
        return cls(
            id=record.id,
            summary=record.summary,
            description=record.description,
            workspace=LookupResponse.from_domain(record.workspace),
            work_type=LookupResponse.from_domain(record.work_type),
            reporter=LookupResponse.from_domain(record.reporter),
            assignee=LookupResponse.from_domain(record.assignee) if record.assignee else None,
            parent=LookupResponse.from_domain(record.parent) if record.parent else None,
            team=LookupResponse.from_domain(record.team) if record.team else None,
            due_date=record.due_date,
            start_date=record.start_date,
            labels=[LookupResponse.from_domain(label) for label in record.labels],
            attachments=[AttachmentResponse.from_domain(item) for item in record.attachments],
        )


def build_work_item_router(service: WorkItemService) -> APIRouter:
    router = APIRouter(
        prefix="/api",
        tags=["work-items"],
        responses={
            status.HTTP_422_UNPROCESSABLE_CONTENT: {
                "model": ValidationErrorResponse,
                "description": "Validation Error",
            }
        },
    )

    @router.post("/workspaces", response_model=LookupResponse, status_code=status.HTTP_201_CREATED)
    def create_workspace(payload: WorkspaceCreateRequest) -> LookupResponse:
        try:
            return LookupResponse.from_domain(service.create_workspace(payload.name, payload.key))
        except WorkItemValidationError as exc:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc

    @router.post("/users", response_model=LookupResponse, status_code=status.HTTP_201_CREATED)
    def create_user(payload: UserCreateRequest) -> LookupResponse:
        try:
            return LookupResponse.from_domain(service.create_user(payload.name, payload.email))
        except WorkItemValidationError as exc:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc

    @router.post("/teams", response_model=LookupResponse, status_code=status.HTTP_201_CREATED)
    def create_team(payload: TeamCreateRequest) -> LookupResponse:
        try:
            return LookupResponse.from_domain(service.create_team(payload.name, payload.key))
        except WorkItemValidationError as exc:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc

    @router.get("/lookups/workspaces", response_model=list[LookupResponse])
    def list_workspaces(q: str = Query(default="")) -> list[LookupResponse]:
        return [LookupResponse.from_domain(item) for item in service.search_workspaces(q)]

    @router.get("/lookups/work-types", response_model=list[LookupResponse])
    def list_work_types(q: str = Query(default="")) -> list[LookupResponse]:
        return [LookupResponse.from_domain(item) for item in service.search_work_types(q)]

    @router.get("/lookups/users", response_model=list[LookupResponse])
    def list_users(q: str = Query(default="")) -> list[LookupResponse]:
        return [LookupResponse.from_domain(item) for item in service.search_users(q)]

    @router.get("/lookups/teams", response_model=list[LookupResponse])
    def list_teams(q: str = Query(default="")) -> list[LookupResponse]:
        return [LookupResponse.from_domain(item) for item in service.search_teams(q)]

    @router.get("/lookups/labels", response_model=list[LookupResponse])
    def list_labels(q: str = Query(default="")) -> list[LookupResponse]:
        return [LookupResponse.from_domain(item) for item in service.search_labels(q)]

    @router.get("/lookups/parent-items", response_model=list[LookupResponse])
    def list_parent_items(
        q: str = Query(default=""),
        workspace_id: int | None = Query(default=None),
    ) -> list[LookupResponse]:
        return [
            LookupResponse.from_domain(item)
            for item in service.search_parent_items(query=q, workspace_id=workspace_id)
        ]

    @router.get("/work-items", response_model=list[LookupResponse])
    def list_work_items(q: str = Query(default="")) -> list[LookupResponse]:
        return [LookupResponse.from_domain(item) for item in service.list_work_items(q)]

    @router.post("/work-items", response_model=WorkItemResponse, status_code=status.HTTP_201_CREATED)
    def create_work_item(payload: WorkItemCreateRequest) -> WorkItemResponse:
        try:
            record = service.create_work_item(payload.to_domain())
        except WorkItemValidationError as exc:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc

        return WorkItemResponse.from_domain(record)

    return router

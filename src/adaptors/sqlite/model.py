from __future__ import annotations

from datetime import date, datetime, timezone

from sqlmodel import Field, SQLModel


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


class WorkspaceTable(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    name: str = Field(index=True, max_length=120)
    key: str = Field(index=True, unique=True, max_length=50)


class WorkTypeTable(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    name: str = Field(index=True, unique=True, max_length=120)
    code: str = Field(index=True, unique=True, max_length=50)


class UserTable(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    name: str = Field(index=True, max_length=120)
    email: str = Field(index=True, unique=True, max_length=200)


class TeamTable(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    name: str = Field(index=True, unique=True, max_length=120)
    key: str = Field(index=True, unique=True, max_length=50)


class LabelTable(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    name: str = Field(index=True, unique=True, max_length=120)


class WorkItemTable(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    summary: str = Field(index=True, max_length=200)
    description: str | None = Field(default=None, max_length=4000)
    workspace_id: int = Field(foreign_key="workspacetable.id", index=True)
    work_type_id: int = Field(foreign_key="worktypetable.id", index=True)
    reporter_id: int = Field(foreign_key="usertable.id", index=True)
    assignee_id: int | None = Field(default=None, foreign_key="usertable.id", index=True)
    parent_id: int | None = Field(default=None, foreign_key="workitemtable.id", index=True)
    team_id: int | None = Field(default=None, foreign_key="teamtable.id", index=True)
    due_date: date | None = Field(default=None)
    start_date: date | None = Field(default=None)
    created_at: datetime = Field(default_factory=utc_now, index=True)
    updated_at: datetime = Field(default_factory=utc_now)


class WorkItemLabelLink(SQLModel, table=True):
    work_item_id: int = Field(foreign_key="workitemtable.id", primary_key=True)
    label_id: int = Field(foreign_key="labeltable.id", primary_key=True)


class AttachmentTable(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    work_item_id: int = Field(foreign_key="workitemtable.id", index=True)
    name: str = Field(max_length=255)
    kind: str = Field(max_length=20)
    uri: str = Field(max_length=2048)
    mime_type: str | None = Field(default=None, max_length=255)
    created_at: datetime = Field(default_factory=utc_now, index=True)

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date
from enum import StrEnum


class AttachmentKind(StrEnum):
    PHOTO = "photo"
    VIDEO = "video"
    DOCUMENT = "document"


@dataclass(frozen=True)
class LookupOption:
    id: int
    title: str
    subtitle: str | None = None


@dataclass(frozen=True)
class AttachmentDraft:
    name: str
    kind: AttachmentKind
    uri: str
    mime_type: str | None = None


@dataclass(frozen=True)
class WorkItemDraft:
    workspace_id: int
    work_type_id: int
    summary: str
    description: str | None
    reporter_id: int
    assignee_id: int | None = None
    parent_id: int | None = None
    team_id: int | None = None
    due_date: date | None = None
    start_date: date | None = None
    label_ids: list[int] = field(default_factory=list)
    new_label_names: list[str] = field(default_factory=list)
    attachments: list[AttachmentDraft] = field(default_factory=list)


@dataclass(frozen=True)
class WorkItemRecord:
    id: int
    summary: str
    description: str | None
    workspace: LookupOption
    work_type: LookupOption
    reporter: LookupOption
    assignee: LookupOption | None
    parent: LookupOption | None
    team: LookupOption | None
    due_date: date | None
    start_date: date | None
    labels: list[LookupOption]
    attachments: list[AttachmentDraft]

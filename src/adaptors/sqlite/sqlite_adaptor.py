from __future__ import annotations

from collections.abc import Sequence
from typing import Any, cast

from sqlalchemy import or_
from sqlmodel import Session, SQLModel, create_engine, func, select

from adaptors.sqlite.model import (
    AttachmentTable,
    LabelTable,
    TeamTable,
    UserTable,
    WorkItemLabelLink,
    WorkItemTable,
    WorkspaceTable,
    WorkTypeTable,
)
from entity.work_item import AttachmentDraft, AttachmentKind, LookupOption, WorkItemDraft, WorkItemRecord
from repository import WorkItemRepository

SYSTEM_WORK_TYPES: tuple[tuple[str, str], ...] = (
    ("任务", "task"),
    ("缺陷", "bug"),
    ("故事", "story"),
    ("长篇故事", "epic"),
)


class SQLiteWorkItemRepository(WorkItemRepository):
    def __init__(self, database_url: str) -> None:
        connect_args = {"check_same_thread": False} if database_url.startswith("sqlite") else {}
        self._engine = create_engine(database_url, connect_args=connect_args)

    def initialize(self) -> None:
        SQLModel.metadata.create_all(self._engine)
        with Session(self._engine) as session:
            self._seed_system_work_types(session)
            session.commit()

    def create_work_item(self, draft: WorkItemDraft) -> WorkItemRecord:
        with Session(self._engine) as session:
            work_item = WorkItemTable(
                summary=draft.summary,
                description=draft.description,
                workspace_id=draft.workspace_id,
                work_type_id=draft.work_type_id,
                reporter_id=draft.reporter_id,
                assignee_id=draft.assignee_id,
                parent_id=draft.parent_id,
                team_id=draft.team_id,
                due_date=draft.due_date,
                start_date=draft.start_date,
            )
            session.add(work_item)
            session.flush()

            work_item_id = self._require_id(work_item.id)
            label_ids = self._resolve_label_ids(session, draft.label_ids, draft.new_label_names)
            for label_id in label_ids:
                session.add(WorkItemLabelLink(work_item_id=work_item_id, label_id=label_id))

            for attachment in draft.attachments:
                session.add(
                    AttachmentTable(
                        work_item_id=work_item_id,
                        name=attachment.name,
                        kind=attachment.kind.value,
                        uri=attachment.uri,
                        mime_type=attachment.mime_type,
                    )
                )

            session.commit()
            session.refresh(work_item)
            return self._build_work_item_record(session, work_item)

    def create_workspace(self, name: str, key: str) -> LookupOption:
        with Session(self._engine) as session:
            workspace = WorkspaceTable(name=name, key=key)
            session.add(workspace)
            session.commit()
            session.refresh(workspace)
            return LookupOption(id=self._require_id(workspace.id), title=workspace.name, subtitle=workspace.key)

    def create_user(self, name: str, email: str) -> LookupOption:
        with Session(self._engine) as session:
            user = UserTable(name=name, email=email)
            session.add(user)
            session.commit()
            session.refresh(user)
            return LookupOption(id=self._require_id(user.id), title=user.name, subtitle=user.email)

    def create_team(self, name: str, key: str) -> LookupOption:
        with Session(self._engine) as session:
            team = TeamTable(name=name, key=key)
            session.add(team)
            session.commit()
            session.refresh(team)
            return LookupOption(id=self._require_id(team.id), title=team.name, subtitle=team.key)

    def get_workspace(self, workspace_id: int) -> LookupOption | None:
        with Session(self._engine) as session:
            workspace = session.get(WorkspaceTable, workspace_id)
            if workspace is None:
                return None
            return LookupOption(id=self._require_id(workspace.id), title=workspace.name, subtitle=workspace.key)

    def get_work_type(self, work_type_id: int) -> LookupOption | None:
        with Session(self._engine) as session:
            work_type = session.get(WorkTypeTable, work_type_id)
            if work_type is None:
                return None
            return LookupOption(id=self._require_id(work_type.id), title=work_type.name, subtitle=work_type.code)

    def get_user(self, user_id: int) -> LookupOption | None:
        with Session(self._engine) as session:
            user = session.get(UserTable, user_id)
            if user is None:
                return None
            return LookupOption(id=self._require_id(user.id), title=user.name, subtitle=user.email)

    def get_team(self, team_id: int) -> LookupOption | None:
        with Session(self._engine) as session:
            team = session.get(TeamTable, team_id)
            if team is None:
                return None
            return LookupOption(id=self._require_id(team.id), title=team.name, subtitle=team.key)

    def get_parent_item(self, parent_id: int) -> LookupOption | None:
        with Session(self._engine) as session:
            work_item = session.get(WorkItemTable, parent_id)
            if work_item is None:
                return None
            work_item_id = self._require_id(work_item.id)
            return LookupOption(id=work_item_id, title=work_item.summary, subtitle=f"#{work_item_id}")

    def search_workspaces(self, query: str) -> list[LookupOption]:
        with Session(self._engine) as session:
            statement = select(WorkspaceTable).order_by(cast(Any, WorkspaceTable.name))
            statement = self._apply_text_filter(statement, WorkspaceTable.name, WorkspaceTable.key, query=query)
            items = session.exec(statement).all()
            return [LookupOption(id=self._require_id(item.id), title=item.name, subtitle=item.key) for item in items]

    def search_work_types(self, query: str) -> list[LookupOption]:
        with Session(self._engine) as session:
            statement = select(WorkTypeTable).order_by(cast(Any, WorkTypeTable.id))
            statement = self._apply_text_filter(statement, WorkTypeTable.name, WorkTypeTable.code, query=query)
            items = session.exec(statement).all()
            return [LookupOption(id=self._require_id(item.id), title=item.name, subtitle=item.code) for item in items]

    def search_users(self, query: str) -> list[LookupOption]:
        with Session(self._engine) as session:
            statement = select(UserTable).order_by(cast(Any, UserTable.name))
            statement = self._apply_text_filter(statement, UserTable.name, UserTable.email, query=query)
            items = session.exec(statement).all()
            return [LookupOption(id=self._require_id(item.id), title=item.name, subtitle=item.email) for item in items]

    def search_teams(self, query: str) -> list[LookupOption]:
        with Session(self._engine) as session:
            statement = select(TeamTable).order_by(cast(Any, TeamTable.name))
            statement = self._apply_text_filter(statement, TeamTable.name, TeamTable.key, query=query)
            items = session.exec(statement).all()
            return [LookupOption(id=self._require_id(item.id), title=item.name, subtitle=item.key) for item in items]

    def search_labels(self, query: str) -> list[LookupOption]:
        with Session(self._engine) as session:
            statement = select(LabelTable).order_by(cast(Any, LabelTable.name))
            statement = self._apply_text_filter(statement, LabelTable.name, query=query)
            items = session.exec(statement).all()
            return [LookupOption(id=self._require_id(item.id), title=item.name) for item in items]

    def search_parent_items(self, query: str, workspace_id: int | None) -> list[LookupOption]:
        with Session(self._engine) as session:
            statement = select(WorkItemTable).order_by(cast(Any, WorkItemTable.created_at).desc())
            statement = self._apply_text_filter(statement, WorkItemTable.summary, WorkItemTable.description, query=query)
            if workspace_id is not None:
                statement = statement.where(WorkItemTable.workspace_id == workspace_id)
            items = session.exec(statement.limit(20)).all()
            return [self._to_work_item_lookup(item) for item in items]

    def label_exists(self, label_id: int) -> bool:
        with Session(self._engine) as session:
            return session.get(LabelTable, label_id) is not None

    def get_or_create_label(self, name: str) -> LookupOption:
        with Session(self._engine) as session:
            label = self._get_label_by_name(session, name)
            if label is None:
                label = LabelTable(name=name)
                session.add(label)
                session.commit()
                session.refresh(label)
            return LookupOption(id=self._require_id(label.id), title=label.name)

    def list_work_items(self, query: str) -> list[LookupOption]:
        with Session(self._engine) as session:
            statement = select(WorkItemTable).order_by(cast(Any, WorkItemTable.created_at).desc())
            statement = self._apply_text_filter(statement, WorkItemTable.summary, WorkItemTable.description, query=query)
            items = session.exec(statement.limit(50)).all()
            return [self._to_work_item_lookup(item) for item in items]

    @staticmethod
    def _apply_text_filter(statement: Any, *columns: Any, query: str) -> Any:
        normalized_query = query.strip()
        if not normalized_query:
            return statement

        pattern = f"%{normalized_query}%"
        conditions = [column.ilike(pattern) for column in columns]
        return statement.where(or_(*conditions))

    @staticmethod
    def _require_id(value: int | None) -> int:
        if value is None:
            raise ValueError("Expected persisted record id.")
        return value

    def _seed_system_work_types(self, session: Session) -> None:
        existing_codes = {
            item.code
            for item in session.exec(select(WorkTypeTable)).all()
        }
        for name, code in SYSTEM_WORK_TYPES:
            if code in existing_codes:
                continue
            session.add(WorkTypeTable(name=name, code=code))

    @staticmethod
    def _get_label_by_name(session: Session, name: str) -> LabelTable | None:
        statement = select(LabelTable).where(func.lower(LabelTable.name) == name.casefold())
        return session.exec(statement).first()

    def _resolve_label_ids(self, session: Session, label_ids: Sequence[int], new_label_names: Sequence[str]) -> list[int]:
        ordered_ids: list[int] = []
        seen_ids: set[int] = set()

        for label_id in label_ids:
            if label_id in seen_ids:
                continue
            seen_ids.add(label_id)
            ordered_ids.append(label_id)

        for name in new_label_names:
            label = self._get_label_by_name(session, name)
            if label is None:
                label = LabelTable(name=name)
                session.add(label)
                session.flush()

            label_id = self._require_id(label.id)
            if label_id in seen_ids:
                continue
            seen_ids.add(label_id)
            ordered_ids.append(label_id)

        return ordered_ids

    def _build_work_item_record(self, session: Session, work_item: WorkItemTable) -> WorkItemRecord:
        workspace = session.get(WorkspaceTable, work_item.workspace_id)
        work_type = session.get(WorkTypeTable, work_item.work_type_id)
        reporter = session.get(UserTable, work_item.reporter_id)
        assignee = session.get(UserTable, work_item.assignee_id) if work_item.assignee_id else None
        parent = session.get(WorkItemTable, work_item.parent_id) if work_item.parent_id else None
        team = session.get(TeamTable, work_item.team_id) if work_item.team_id else None

        if workspace is None or work_type is None or reporter is None:
            raise ValueError("Expected related records to exist for the stored work item.")

        work_item_id = self._require_id(work_item.id)
        label_statement = (
            select(LabelTable)
            .join(WorkItemLabelLink, cast(Any, WorkItemLabelLink.label_id == LabelTable.id))
            .where(WorkItemLabelLink.work_item_id == work_item_id)
            .order_by(cast(Any, LabelTable.name))
        )
        labels = session.exec(label_statement).all()

        attachment_statement = (
            select(AttachmentTable)
            .where(AttachmentTable.work_item_id == work_item_id)
            .order_by(cast(Any, AttachmentTable.created_at))
        )
        attachments = session.exec(attachment_statement).all()

        return WorkItemRecord(
            id=work_item_id,
            summary=work_item.summary,
            description=work_item.description,
            workspace=LookupOption(id=self._require_id(workspace.id), title=workspace.name, subtitle=workspace.key),
            work_type=LookupOption(id=self._require_id(work_type.id), title=work_type.name, subtitle=work_type.code),
            reporter=LookupOption(id=self._require_id(reporter.id), title=reporter.name, subtitle=reporter.email),
            assignee=(
                LookupOption(id=self._require_id(assignee.id), title=assignee.name, subtitle=assignee.email)
                if assignee
                else None
            ),
            parent=self._to_work_item_lookup(parent) if parent else None,
            team=LookupOption(id=self._require_id(team.id), title=team.name, subtitle=team.key) if team else None,
            due_date=work_item.due_date,
            start_date=work_item.start_date,
            labels=[LookupOption(id=self._require_id(label.id), title=label.name) for label in labels],
            attachments=[
                AttachmentDraft(
                    name=attachment.name,
                    kind=AttachmentKind(attachment.kind),
                    uri=attachment.uri,
                    mime_type=attachment.mime_type,
                )
                for attachment in attachments
            ],
        )

    def _to_work_item_lookup(self, work_item: WorkItemTable) -> LookupOption:
        work_item_id = self._require_id(work_item.id)
        return LookupOption(id=work_item_id, title=work_item.summary, subtitle=f"#{work_item_id}")

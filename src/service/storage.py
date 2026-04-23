from __future__ import annotations

from dataclasses import replace

from entity.work_item import LookupOption, WorkItemDraft, WorkItemRecord
from repository import WorkItemRepository


class WorkItemValidationError(ValueError):
    """Raised when a work item request violates domain rules."""


class WorkItemService:
    def __init__(self, repository: WorkItemRepository) -> None:
        self._repository = repository

    def initialize(self) -> None:
        self._repository.initialize()

    def create_work_item(self, draft: WorkItemDraft) -> WorkItemRecord:
        self._require_lookup(self._repository.get_workspace(draft.workspace_id), "workspace_id")
        self._require_lookup(self._repository.get_work_type(draft.work_type_id), "work_type_id")
        self._require_lookup(self._repository.get_user(draft.reporter_id), "reporter_id")

        if draft.assignee_id is not None:
            self._require_lookup(self._repository.get_user(draft.assignee_id), "assignee_id")

        if draft.team_id is not None:
            self._require_lookup(self._repository.get_team(draft.team_id), "team_id")

        if draft.parent_id is not None:
            self._require_lookup(self._repository.get_parent_item(draft.parent_id), "parent_id")

        for label_id in draft.label_ids:
            if not self._repository.label_exists(label_id):
                raise WorkItemValidationError(f"Unknown label_id: {label_id}")

        normalized_new_labels = self._normalize_label_names(draft.new_label_names)
        normalized_draft = replace(draft, new_label_names=normalized_new_labels)
        return self._repository.create_work_item(normalized_draft)

    def create_workspace(self, name: str, key: str) -> LookupOption:
        normalized_name = name.strip()
        normalized_key = key.strip().upper()
        if not normalized_name:
            raise WorkItemValidationError("Workspace name must not be empty.")
        if not normalized_key:
            raise WorkItemValidationError("Workspace key must not be empty.")
        return self._repository.create_workspace(normalized_name, normalized_key)

    def create_user(self, name: str, email: str) -> LookupOption:
        normalized_name = name.strip()
        normalized_email = email.strip().lower()
        if not normalized_name:
            raise WorkItemValidationError("User name must not be empty.")
        if not normalized_email:
            raise WorkItemValidationError("User email must not be empty.")
        return self._repository.create_user(normalized_name, normalized_email)

    def create_team(self, name: str, key: str) -> LookupOption:
        normalized_name = name.strip()
        normalized_key = key.strip().lower()
        if not normalized_name:
            raise WorkItemValidationError("Team name must not be empty.")
        if not normalized_key:
            raise WorkItemValidationError("Team key must not be empty.")
        return self._repository.create_team(normalized_name, normalized_key)

    def search_workspaces(self, query: str) -> list[LookupOption]:
        return self._repository.search_workspaces(query)

    def search_work_types(self, query: str) -> list[LookupOption]:
        return self._repository.search_work_types(query)

    def search_users(self, query: str) -> list[LookupOption]:
        return self._repository.search_users(query)

    def search_teams(self, query: str) -> list[LookupOption]:
        return self._repository.search_teams(query)

    def search_labels(self, query: str) -> list[LookupOption]:
        return self._repository.search_labels(query)

    def search_parent_items(self, query: str, workspace_id: int | None) -> list[LookupOption]:
        return self._repository.search_parent_items(query, workspace_id)

    def list_work_items(self, query: str) -> list[LookupOption]:
        return self._repository.list_work_items(query)

    @staticmethod
    def _normalize_label_names(label_names: list[str]) -> list[str]:
        deduplicated: list[str] = []
        seen: set[str] = set()

        for label_name in label_names:
            normalized_name = label_name.strip()
            if not normalized_name:
                raise WorkItemValidationError("Label names must not be empty.")
            lowered = normalized_name.casefold()
            if lowered in seen:
                continue
            seen.add(lowered)
            deduplicated.append(normalized_name)

        return deduplicated

    @staticmethod
    def _require_lookup(option: LookupOption | None, field_name: str) -> None:
        if option is None:
            raise WorkItemValidationError(f"Unknown {field_name}.")

from __future__ import annotations

from abc import ABC, abstractmethod

from entity.work_item import LookupOption, WorkItemDraft, WorkItemRecord


class WorkItemRepository(ABC):
    @abstractmethod
    def initialize(self) -> None:
        """Create schema and seed reference data."""

    @abstractmethod
    def create_work_item(self, draft: WorkItemDraft) -> WorkItemRecord:
        """Persist a work item and return the stored record."""

    @abstractmethod
    def create_workspace(self, name: str, key: str) -> LookupOption:
        """Create a workspace."""

    @abstractmethod
    def create_user(self, name: str, email: str) -> LookupOption:
        """Create a user."""

    @abstractmethod
    def create_team(self, name: str, key: str) -> LookupOption:
        """Create a team."""

    @abstractmethod
    def get_workspace(self, workspace_id: int) -> LookupOption | None:
        """Return a workspace by id."""

    @abstractmethod
    def get_work_type(self, work_type_id: int) -> LookupOption | None:
        """Return a work type by id."""

    @abstractmethod
    def get_user(self, user_id: int) -> LookupOption | None:
        """Return a user by id."""

    @abstractmethod
    def get_team(self, team_id: int) -> LookupOption | None:
        """Return a team by id."""

    @abstractmethod
    def get_parent_item(self, parent_id: int) -> LookupOption | None:
        """Return a parent item by id."""

    @abstractmethod
    def search_workspaces(self, query: str) -> list[LookupOption]:
        """Search workspaces."""

    @abstractmethod
    def search_work_types(self, query: str) -> list[LookupOption]:
        """Search work item types."""

    @abstractmethod
    def search_users(self, query: str) -> list[LookupOption]:
        """Search users."""

    @abstractmethod
    def search_teams(self, query: str) -> list[LookupOption]:
        """Search teams."""

    @abstractmethod
    def search_labels(self, query: str) -> list[LookupOption]:
        """Search labels."""

    @abstractmethod
    def search_parent_items(self, query: str, workspace_id: int | None) -> list[LookupOption]:
        """Search previous work items as parent candidates."""

    @abstractmethod
    def label_exists(self, label_id: int) -> bool:
        """Return True if the label exists."""

    @abstractmethod
    def get_or_create_label(self, name: str) -> LookupOption:
        """Get an existing label by name or create a new one."""

    @abstractmethod
    def list_work_items(self, query: str) -> list[LookupOption]:
        """List stored work items."""

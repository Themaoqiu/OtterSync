from __future__ import annotations

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="OTTERSYNC_", extra="ignore")

    app_name: str = "OtterSync Backend"
    database_url: str = "sqlite:///./ottersync.db"


@lru_cache
def get_settings() -> Settings:
    return Settings()

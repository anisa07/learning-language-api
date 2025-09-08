from pydantic_settings import BaseSettings
from pydantic import field_validator
from typing import List
import os

class Settings(BaseSettings):
    APP_NAME: str
    DATABASE_URL: str

    ALLOWED_ORIGINS: List[str] = []

    AI_PROVIDER: str

    # OpenAI-compatible
    OPENAI_API_BASE: str | None = None
    OPENAI_API_KEY: str | None = None
    OPENAI_MODEL: str

    # Hugging Face Inference API
    HF_API_KEY: str | None = None
    HF_MODEL: str

    # PostgreSQL Configuration (for Docker)
    POSTGRES_USER: str | None = None
    POSTGRES_PASSWORD: str | None = None
    POSTGRES_DB: str | None = None

    @field_validator("ALLOWED_ORIGINS", mode="before")
    @classmethod
    def parse_origins(cls, v):
        if isinstance(v, str):
            # allow JSON-like list or comma list
            v = v.strip()
            if v.startswith("["):
                import json
                return json.loads(v)
            return [s.strip() for s in v.split(",") if s.strip()]
        return v

    class Config:
        # Load multiple files in order of priority
        env_file = [
            f".env.{os.getenv('ENVIRONMENT', 'dev')}",  # Specific environment
            ".env.local",                                # Local overrides
            ".env"                                       # Base fallback
        ]

settings = Settings()

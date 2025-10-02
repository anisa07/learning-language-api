from contextlib import asynccontextmanager
import os


if os.getenv("DEBUGPY", "0") == "1":
    import debugpy
    debugpy.listen(("0.0.0.0", 5678))
    print("🔌 debugpy listening on 5678")
    # debugpy.wait_for_client()  # uncomment if you want to pause until attached

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .config import settings
from .db import Base, engine
from .api.v1 import router

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    # For simple projects, create tables on startup.
    # For mature projects, switch to Alembic migrations.
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    # Shutdown - cleanup code can go here if needed

app = FastAPI(title=settings.APP_NAME, lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router, prefix="/api/v1")


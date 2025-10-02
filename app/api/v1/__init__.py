from fastapi import APIRouter
from .words import router as words_router

router = APIRouter()
router.include_router(words_router)

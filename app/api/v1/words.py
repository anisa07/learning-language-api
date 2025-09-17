from fastapi import APIRouter, Depends, HTTPException, Query, Path
from sqlalchemy import select, func
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload, selectinload
from app.models import AppUser, Category, Level, Word
from ...controllers.word import get_app_user_words as get_user_words
from ...db import get_session
from ...services.ai import AIService

router = APIRouter(prefix="/words", tags=["words"])

router = APIRouter()
ai = AIService()
    
@router.get("/words/app-user/{user_id}")
async def get_app_user_words(user_id: int = Path(..., gt=0), limit: int = Query(15, ge=1, le=100), session: AsyncSession = Depends(get_session)):
    """
    - check user exist 
    - get user level
    - check user has {{ limit }} words
    - return {{ limit }} randow words of hiw level
    """
    try: 
        return await get_user_words(user_id, limit, session)
        
    except SQLAlchemyError:
        await session.rollback()
        raise HTTPException(500, "Database error")
    
# Test routes return users
@router.get("/test/users")
async def get_app_user_list(session: AsyncSession = Depends(get_session)):
    """Get user list"""
    try:
        result = await session.execute(
            select(AppUser).options(joinedload(AppUser.level)).order_by(AppUser.id)
        )
        users = result.scalars().all()
        return [
            {
                "id": u.id,
                # "username": u.username,
                # "email": u.email,
                "level": u.level.level if u.level else None,
            }
            for u in users
        ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
 
@router.get("/test/stats")
async def get_vocabulary_stats(session: AsyncSession = Depends(get_session)):
    """Get vocabulary statistics for testing."""
    try:
        # Count words by level
        level_stats = await session.execute(
            select(Level.level, func.count(Word.id).label('word_count'))
            .join(Word, Level.id == Word.level_id)
            .group_by(Level.level)
            .order_by(Level.level)
        )
        
        # Count words by part of speech
        pos_stats = await session.execute(
            select(Word.part_of_speech, func.count(Word.id).label('word_count'))
            .group_by(Word.part_of_speech)
            .order_by(func.count(Word.id).desc())
        )
        
        # Total counts
        total_words = await session.execute(select(func.count(Word.id)))
        total_levels = await session.execute(select(func.count(Level.id)))
        total_categories = await session.execute(select(func.count(Category.id)))
        
        return {
            "total_words": total_words.scalar(),
            "total_levels": total_levels.scalar(),
            "total_categories": total_categories.scalar(),
            "words_by_level": {level: count for level, count in level_stats},
            "words_by_part_of_speech": {pos: count for pos, count in pos_stats}
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

from fastapi import APIRouter, Depends, HTTPException, Query, Path
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete, func, and_
from sqlalchemy.orm import joinedload, selectinload
from sqlalchemy.dialects.postgresql import insert as pg_insert

from ..services.word import get_random_words, save_user_words
from ..controllers.word import get_user_ranked_words
from ..db import get_session
from ..models import AppUserWord, PromptExample, Word, Level, Category, AppUser
from ..schemas import PromptExampleCreate, PromptExampleRead, ChatRequest, ChatResponse
from ..services.ai import AIService

router = APIRouter()
ai = AIService()

@router.get("/health")
async def health():
    return {"status": "ok"}

@router.post("/ai/chat", response_model=ChatResponse)
async def ai_chat(req: ChatRequest):
    try:
        text, provider, model = await ai.chat(req.prompt, req.system, req.provider, req.model)
        return ChatResponse(output=text, provider=provider, model=model)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/examples", response_model=PromptExampleRead)
async def create_example(payload: PromptExampleCreate, session: AsyncSession = Depends(get_session)):
    row = PromptExample(title=payload.title, prompt=payload.prompt)
    session.add(row)
    await session.commit()
    await session.refresh(row)
    return row

@router.get("/examples", response_model=list[PromptExampleRead])
async def list_examples(session: AsyncSession = Depends(get_session)):
    res = await session.execute(select(PromptExample).order_by(PromptExample.created_at.desc()))
    return [*res.scalars().all()]

@router.get("/examples/{id}", response_model=PromptExampleRead)
async def get_example(id: int, session: AsyncSession = Depends(get_session)):
    row = await session.get(PromptExample, id)
    if not row:
        raise HTTPException(404, "Not found")
    return row

@router.delete("/examples/{id}")
async def delete_example(id: int, session: AsyncSession = Depends(get_session)):
    await session.execute(delete(PromptExample).where(PromptExample.id == id))
    await session.commit()
    return {"ok": True}

# Test routes for vocabulary data
@router.get("/test/words")
async def get_all_words(limit: int = 50, session: AsyncSession = Depends(get_session)):
    """Get all words from the database for testing."""
    try:
        # Get total count
        count_result = await session.execute(select(func.count(Word.id)))
        total_count = count_result.scalar()
        
        # Get words with their levels
        result = await session.execute(
            select(Word, Level.level.label('level_name'))
            .join(Level, Word.level_id == Level.id)
            .order_by(Word.word)
            .limit(limit)
        )
        
        words = []
        for word, level_name in result:
            words.append({
                "id": word.id,
                "dutch": word.word,
                "english": word.meaning,
                "part_of_speech": word.part_of_speech,
                "level": level_name
            })
        
        return {
            "total_count": total_count,
            "showing": len(words),
            "limit": limit,
            "words": words
        }
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

@router.get("/test/sample/{level_name}")
async def get_sample_words_by_level(level_name: str, limit: int = 10, session: AsyncSession = Depends(get_session)):
    """Get sample words for a specific level."""
    try:
        result = await session.execute(
            select(Word)
            .join(Level, Word.level_id == Level.id)
            .where(Level.level == level_name)
            .order_by(Word.word)
            .limit(limit)
        )
        
        words = []
        for word in result.scalars():
            words.append({
                "dutch": word.word,
                "english": word.meaning,
                "part_of_speech": word.part_of_speech
            })
        
        return {
            "level": level_name,
            "count": len(words),
            "words": words
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

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
    
@router.get("/words/app-user/{user_id}")
async def get_app_user_words(user_id: int = Path(..., gt=0), limit: int = Query(0, ge=0, le=100), session: AsyncSession = Depends(get_session)):
    # check user exist 
    # get user level
    # check user has 10 words with rank <= limit
    # return 10 randow words of hiw level
    try: 
         # 1) load the user (and level)
        app_user = await session.get(AppUser, user_id, options=[selectinload(AppUser.app_user_words).joinedload(AppUserWord.word)])
        if not app_user:
            raise HTTPException(404, "User not found")
        
        words = []
        rows = []
        if len(app_user.app_user_words) == 0:
            print("user doesn't have words")
            # 2) fetch random words for that level when user has no words
            words = await get_random_words([Word.level_id == app_user.level_id], limit, session)
            rows = [
                {"app_user_id": user_id, "word_id": item['word'].id, "rank": 0}
                for item in words
            ]
            await save_user_words(rows, session)

            return [
                {"id": item['word'].id, "word": item['word'].word, "part_of_speech": item['word'].part_of_speech, "meaning": item['word'].meanin, "rank": item['rank']}
                for item in words
            ]
            
        if len(app_user.app_user_words):
            print("user has words")
            # 3) return words for the user
            result = await get_user_ranked_words(limit, app_user, session)
            return result
        
    except SQLAlchemyError:
        await session.rollback()
        raise HTTPException(500, "Database error")

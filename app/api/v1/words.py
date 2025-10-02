from fastapi import APIRouter, Query, Path
from app.schemas import AppUserWords, BatchSetRanks, CategoryRead
from typing import List
from ...controllers.word import get_app_user_words as get_user_words, get_app_words, remove_app_user_words, sentences_with_app_user_words, update_app_words, update_user_words_ranks
from ...controllers.category import get_categories
from ...services.ai import AIService

router = APIRouter(prefix="/words", tags=["words"])
ai = AIService()
    
@router.get("/app-user/{user_id}")
async def get_app_user_words(user_id: int = Path(..., gt=0), limit: int = Query(0, ge=0, le=100)):
    """vhk
    - check user exist 
    - get user level
    - check user has {{ limit }} words
    - return {{ limit }} random words of hiw level
    """
    return await get_user_words(user_id, limit)

@router.patch("/app-user/{user_id}")
async def update_app_user_words_rank(user_id: int = Path(..., gt=0), body: BatchSetRanks = []):
    """
    - update list of user's word's ranks
    - check user exist
    - body is list of dict {items: [{ "word_id": int, "rank": int }]}
    - return back updated list
    """
    return await update_user_words_ranks(user_id, body)

@router.get("/list")
async def get_app_word_list(limit: int = 0):
    """
    - return words form the system
    """
    return await get_app_words(limit)

@router.post("/list/{user_id}")
async def add_user_word_list(user_id: int = Path(..., gt=0), body: AppUserWords = { "words": [] }, limit: int = Query(0, ge=0, le=100)):
    """
    - push user new word list
    """
    return await update_app_words(user_id, body, limit)

@router.delete("/list/{user_id}")
async def remove_user_word_from_list(user_id: int = Path(..., gt=0), body: AppUserWords = { "words": [] }, limit: int = Query(0, ge=0, le=100)):
    """
    - remove list of words from of users words
    """
    return await remove_app_user_words(user_id, body, limit)

@router.get("/sentences-with-user-words/{user_id}")
async def get_app_user_sentences(user_id: int = Path(..., gt=0), limit: int = Query(10, ge=1, le=100)):
    """
    - return list of sentences with user words
    """
    return await sentences_with_app_user_words(user_id, limit)

@router.get("/categories", response_model=List[CategoryRead])
async def get_all_categories():
    """
    - return all categories from the database
    """
    return await get_categories()

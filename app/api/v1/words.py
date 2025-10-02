from fastapi import APIRouter, Query, Path
from app.schemas import AppUserMeanings, BatchSetRanks, CategoryRead, SelectedMeaningsUpdate
from typing import List
from ...controllers.word import get_app_user_meanings as get_user_meanings, get_app_meanings, remove_app_user_meanings, sentences_with_app_user_meanings, update_app_meanings, update_user_meanings_ranks, get_user_selected_meanings, update_selected_meanings_status
from ...controllers.category import get_categories
from ...services.ai import AIService

router = APIRouter(prefix="/words", tags=["words"])
ai = AIService()
    
@router.get("/app-user/{user_id}")
async def get_app_user_meanings(user_id: int = Path(..., gt=0), limit: int = Query(0, ge=0, le=100)):
    """vhk
    - check user exist 
    - get user level
    - check user has {{ limit }} meanings
    - return {{ limit }} random meanings of his level
    """
    return await get_user_meanings(user_id, limit)

@router.patch("/user/{user_id}/rank")
async def update_app_user_meanings_rank(user_id: int = Path(..., gt=0), body: BatchSetRanks = []):
    """
    - update list of user's meaning's ranks
    - check user exist
    - body is list of dict {items: [{ "meaning_id": int, "rank": int }]}
    - return back updated list
    """
    return await update_user_meanings_ranks(user_id, body)

@router.get("/list")
async def get_app_meaning_list(limit: int = 0):
    """
    - return meanings from the system
    """
    return await get_app_meanings(limit)

@router.post("/list/{user_id}")
async def add_user_meaning_list(user_id: int = Path(..., gt=0), body: AppUserMeanings = { "meanings": [] }, limit: int = Query(0, ge=0, le=100)):
    """
    - push user new meaning list
    """
    return await update_app_meanings(user_id, body, limit)

@router.delete("/list/{user_id}")
async def remove_user_meaning_from_list(user_id: int = Path(..., gt=0), body: AppUserMeanings = { "meanings": [] }, limit: int = Query(0, ge=0, le=100)):
    """
    - remove list of meanings from user's meanings
    """
    return await remove_app_user_meanings(user_id, body, limit)

@router.get("/sentences-with-user-meanings/{user_id}")
async def get_app_user_sentences(user_id: int = Path(..., gt=0), limit: int = Query(10, ge=1, le=100)):
    """
    - return list of sentences with user meanings
    """
    return await sentences_with_app_user_meanings(user_id, limit)

@router.get("/categories", response_model=List[CategoryRead])
async def get_all_categories():
    """
    - return all categories from the database
    """
    return await get_categories()

@router.get("/list-selected/{user_id}")
async def get_selected_meanings(user_id: int = Path(..., gt=0), limit: int = Query(10, ge=1, le=100)):
    """
    - return only meanings from app_user_meanings that have isSelected = true
    """
    return await get_user_selected_meanings(user_id, limit)

@router.patch("/user/{user_id}/selected")
async def update_selected_meanings(user_id: int = Path(..., gt=0), body: SelectedMeaningsUpdate = None):
    """
    - set isSelected true/false for meaning ids
    """
    if body is None:
        body = SelectedMeaningsUpdate(meaning_ids=[], is_selected=False)
    return await update_selected_meanings_status(user_id, body.meaning_ids, body.is_selected)

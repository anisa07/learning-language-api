from fastapi import Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import SQLAlchemyError
from typing import List

from app.services.ai import AIService
from ..schemas import AppUserMeanings, BatchSetRanks

from ..services.meaning import get_random_meanings, get_meaning_list, get_meanings_rank, remove_app_user_meaning_list, save_user_meanings, select_user_meanings_from_list, serialize_meaning, get_app_user, update_app_user_meaning_list, update_meanings_ranks, get_selected_meanings, update_selected_meanings
from ..models import AppUser, Meaning, Word
from ..db import get_session
from ..services.word_pool import MeaningPool

async def get_app_user_meanings(user_id: int, limit: int):
    try:
        # 1) load the user (and level)
        session = await get_session()
        app_user = await get_app_user(user_id, session)
        
        if not app_user:
            raise HTTPException(404, "User not found")
            
        rows = []
        if len(app_user.app_user_meanings) == 0:
            print("get_app_user_meanings: user doesn't have meanings")
            # 2) fetch random meanings for that level when user has no meanings
            result = await get_random_meanings([Word.level_id == app_user.level_id], limit or 15, session)
            meanings_only = [row[0] for row in result]
            rows = [
                {"app_user_id": user_id, "meaning_id": item.id, "rank": 0, "is_selected": False}
                for item in meanings_only
            ]
            await save_user_meanings(rows, session)
            return [serialize_meaning(item[0], item[1], item[2] or 0) for item in result]
                
        if len(app_user.app_user_meanings):
            print("user has meanings")
            # 3) return meanings for the user
            result = await get_user_ranked_meanings(limit, app_user, session)
            return result
    except SQLAlchemyError:
        await session.rollback()
        raise HTTPException(500, "Database error")
    
async def get_user_ranked_meanings(limit: int, app_user: AppUser, session: AsyncSession = Depends(get_session)):
    meaning_pool = MeaningPool()
    if limit > 0:
        selected = await meaning_pool.get_user_meanings(app_user.id, limit, session)
        return [serialize_meaning(item['meaning'], item['word'], item['rank'] or 0) for item in selected[:limit]]
    selected = await select_user_meanings_from_list(app_user.id, 0, session)
    return [serialize_meaning(item[0], item[1], item[2] or 0) for item in selected]
    

async def update_user_meanings_ranks(user_id: int, body: BatchSetRanks = []):
    try:
        session = await get_session()
        app_user = await get_app_user(user_id, session)
        
        if not app_user:
            raise HTTPException(404, "User not found")
        
        if not body.items:
            return []
        
        meaning_ids = await update_meanings_ranks(user_id, body.items, session)
        items = await get_meanings_rank(user_id, meaning_ids, session)
        
        return items
    except SQLAlchemyError:
        await session.rollback()

async def get_app_meanings(limit: int):
    try:
        session = await get_session()
        list = await get_meaning_list(limit, session)
        
        return [serialize_meaning(item[0], item[1], 0) for item in list]
    
    except SQLAlchemyError:
        await session.rollback()
    pass

async def update_app_meanings(user_id: int, body: AppUserMeanings, limit: int):
    try:
        session = await get_session()
        app_user = await get_app_user(user_id, session)
        
        if not app_user:
            raise HTTPException(404, "User not found")
        
        if not len(body.meanings):
            return []
        
        # Add meanings to user's list
        await update_app_user_meaning_list(user_id, body.meanings, session)
        meanings = await select_user_meanings_from_list(user_id, limit, session)
        
        return [serialize_meaning(item[0], item[1], item[2] or 0) for item in meanings]
    
    except SQLAlchemyError as e:
        await session.rollback()
        await session.close()
        raise HTTPException(500, f"Database error: {str(e)}")

async def remove_app_user_meanings(user_id: int, body: AppUserMeanings, limit: int):
    try:
        session = await get_session()
        app_user = await get_app_user(user_id, session)
        
        if not app_user:
            raise HTTPException(404, "User not found")
        
        if not len(body.meanings):
            return []
        
        # Remove meanings from user's list
        await remove_app_user_meaning_list(user_id, body.meanings, session)
        
        meanings = await select_user_meanings_from_list(user_id, limit, session)
        
        return [serialize_meaning(item[0], item[1], item[2] or 0) for item in meanings]
    
    except SQLAlchemyError as e:
        await session.rollback()
        await session.close()
        raise HTTPException(500, f"Database error: {str(e)}")

async def sentences_with_app_user_meanings(user_id: int, limit: int):
    try:
        session = await get_session()
        app_user = await get_app_user(user_id, session)
        
        if not app_user:
            raise HTTPException(404, "User not found")
        
        user_meanings = await select_user_meanings_from_list(user_id, limit, session)
        
        if not user_meanings:
            return []
        
        ai_service = AIService()
        
        # Create a list of words for the AI prompt
        words_list = [f"- {item[1]}" for item in user_meanings]  # item[1] is the word
        words_text = "\n".join(words_list)
        
        system_prompt = """You are a Dutch language teacher helping students learn Dutch vocabulary. 
Create simple, clear example sentences that demonstrate how to use Dutch words in context. 
Each sentence should be appropriate for language learners and show the word's meaning clearly. 
Word can be in any form e.g. noun in plural form, verb in past tense, adjective in de form 
"""
        
        user_prompt = f"""Please create one simple Dutch sentence example for each of these words, mark word with _:

{words_text}

Return your response in this exact JSON format:
[
  {{"word": "word1", "example_sentence": "Dutch sentence with _word1_"}},
  {{"word": "word2", "example_sentence": "Dutch sentence with _word2_"}}
]

Make sure:
- Each sentence is simple and clear
- Use proper Dutch grammar
- Show the word in a natural context
- Keep sentences short (5-10 words)"""

        response, provider, model = await ai_service.chat(
            prompt=user_prompt,
            system=system_prompt,
            provider="openai"
        )
        
        print(response)
        # Parse AI response and match with meaning IDs
        import json
        try:
            ai_sentences = json.loads(response)
            result = []
            
            # Create a mapping from word to meaning_id
            word_to_meaning_id = {item[1]: item[0].id for item in user_meanings}  # word -> meaning_id
            
            for sentence_data in ai_sentences:
                word = sentence_data.get("word")
                example = sentence_data.get("example_sentence")
                
                if word in word_to_meaning_id:
                    result.append({
                        "meaning_id": word_to_meaning_id[word],
                        "word": word,
                        "example_sentence": example
                    })
            
            return result
            
        except json.JSONDecodeError as e:
            # Fallback: return basic structure if AI doesn't return valid JSON
            print(f"JSON parsing error: {e}")
            return [{"meaning_id": item[0].id, "example_sentence": f"AI response parsing failed for: {item[1]}"} for item in user_meanings]
    
    except SQLAlchemyError as e:
        await session.rollback()
        await session.close()
        raise HTTPException(500, f"Database error: {str(e)}")

async def get_user_selected_meanings(user_id: int, limit: int):
    """Get only meanings that are selected (is_selected = true) for the user"""
    try:
        session = await get_session()
        app_user = await get_app_user(user_id, session)
        
        if not app_user:
            raise HTTPException(404, "User not found")
        
        meanings = await get_selected_meanings(user_id, limit, session)
        
        return [serialize_meaning(item[0], item[1], item[2] or 0) for item in meanings]
    
    except SQLAlchemyError as e:
        await session.rollback()
        await session.close()
        raise HTTPException(500, f"Database error: {str(e)}")

async def update_selected_meanings_status(user_id: int, meaning_ids: List[int], is_selected: bool):
    """Update is_selected field for specific meanings for a user"""
    try:
        session = await get_session()
        app_user = await get_app_user(user_id, session)
        
        if not app_user:
            raise HTTPException(404, "User not found")
        
        if not meaning_ids:
            return {"updated_count": 0}
        
        updated_count = await update_selected_meanings(user_id, meaning_ids, is_selected, session)
        
        return {"updated_count": updated_count}
    
    except SQLAlchemyError as e:
        await session.rollback()
        await session.close()
        raise HTTPException(500, f"Database error: {str(e)}")

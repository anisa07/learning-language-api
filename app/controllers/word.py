from fastapi import Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import SQLAlchemyError

from app.services.ai import AIService
from ..schemas import AppUserWords, BatchSetRanks

from ..services.word import get_random_words, get_word_list, get_words_rank, remove_app_user_word_list, save_user_words, select_user_words_from_list, serialize, get_app_user, update_app_user_word_list, update_words_ranks
from ..models import AppUser, Word
from ..db import get_session
from ..services.word_pool import WordPool

async def get_app_user_words(user_id: int, limit: int):
    try:
        # 1) load the user (and level)
        session = await get_session()
        app_user = await get_app_user(user_id, session)
        
        if not app_user:
            raise HTTPException(404, "User not found")
            
        rows = []
        if len(app_user.app_user_words) == 0:
            print("get_app_user_words: user doesn't have words")
            # 2) fetch random words for that level when user has no words
            result = await get_random_words([Word.level_id == app_user.level_id], limit or 15, session)
            words_only = [row[0] for row in result]
            rows = [
                {"app_user_id": user_id, "word_id": item.id, "rank": 0}
                for item in words_only
            ]
            await save_user_words(rows, session)
            return [serialize(item[0], item[1] or 0, item[2]) for item in result]
                
        if len(app_user.app_user_words):
            print("user has words")
            # 3) return words for the user
            result = await get_user_ranked_words(limit, app_user, session)
            return result
    except SQLAlchemyError:
        await session.rollback()
        raise HTTPException(500, "Database error")
    
async def get_user_ranked_words(limit: int, app_user: AppUser, session: AsyncSession = Depends(get_session)):
    # user_words = await session.execute(
    #     select(AppUserWord.word_id, AppUserWord.rank).where(AppUserWord.app_user_id == app_user.id)
    # )
    # print("User assigned words:", user_words.all())

    
    # buckets = bucket_rank()
    
    # for b in buckets.values():
    #     # count how many words user have of that specific condition
    #     b["have"] = await count_bucket(b["cond"], app_user.id, session)

    # total_have = sum(b["have"] for b in buckets.values())
    
    # if total_have == 0:
    #     return []  # user has no words assigned yet
    
    # # initial targets from shares (floor), except r0 which is remainder later
    # for b in buckets.values():
    #     if b["share"] is not None:
    #         b["want"] = min(b["have"], floor(limit * b["share"]))
    #     used = sum(b["want"] for b in buckets.values())
    #     buckets["r0"]["want"] = min(buckets["r0"]["have"], max(0, limit - used))
        
    # # redistribute leftover (if any) to r0 -> r5 -> r10 -> r15, respecting availability
    # leftover = limit - sum(b["want"] for b in buckets.values())
    # for b in buckets.values():
    #     if leftover <= 0:
    #         break
    #     room = max(0, b["have"] - b["want"])
    #     take = min(room, leftover)
    #     b["want"] += take
    #     leftover -= take
        
    # # ---- fetch random words per bucket ----
    # selected_ids = set()
    # selected = []
    
    # for key in ["r15", "r10", "r5", "r0"]:  # fetch in this order (doesn't really matter)
    #     take = await pick_from_bucket(buckets[key]["cond"], buckets[key]["want"], app_user.id, selected_ids, session)
    #     for (w, rank, category) in take:
    #         print(w)
    #         selected_ids.add(w.id)
    #         selected.append({
    #             "word": w,
    #             "rank": rank or 0,
    #             "category": category
    #         })
            
    # TODO test before delete
    # if we still have fewer than limit (e.g., not enough assigned words),
    # fill up randomly from the user's remaining assigned words
    # rest = max(0, limit - len(selected))
    # if rest > 0:
    #     new_words = select_new_words(app_user, rest,  selected_ids, session)
        
    #     rows = [
    #         {"app_user_id": app_user.id, "word_id": item["word"].id, "rank": 0}
    #         for item in new_words
    #     ]
        
    #     await save_user_words(rows, session)
        
    #     selected.extend(new_words)
    #     selected_ids.update(w.id for w in new_words)
    
    word_pool = WordPool()
    if limit > 0:
        selected = await word_pool.get_user_words(app_user.id, limit, session)
        return [serialize(item['word'], item['rank'] or 0, item['category']) for item in selected[:limit]]
    selected = await select_user_words_from_list(app_user.id, 0, session)
    return [serialize(item[0], item[1] or 0, item[2]) for item in selected]
    

async def update_user_words_ranks(user_id: int, body: BatchSetRanks = []):
    try:
        session = await get_session()
        app_user = await get_app_user(user_id, session)
        
        if not app_user:
            raise HTTPException(404, "User not found")
        
        if not body.items:
            return []
        
        word_ids = await update_words_ranks(user_id, body.items, session)
        items = await get_words_rank(user_id, word_ids, session)
        
        return items
    except SQLAlchemyError:
        await session.rollback()

async def get_app_words(limit: int):
    try:
        session = await get_session()
        list = await get_word_list(limit, session)
        
        return [serialize(item[0], 0, item[1]) for item in list]
    
    except SQLAlchemyError:
        await session.rollback()
    pass

async def update_app_words(user_id: int, body: AppUserWords, limit: int):
    try:
        session = await get_session()
        app_user = await get_app_user(user_id, session)
        
        if not app_user:
            raise HTTPException(404, "User not found")
        
        if not len(body.words):
            return []
        
        # Add words to user's list
        await update_app_user_word_list(user_id, body.words, session)
        words = await select_user_words_from_list(user_id, limit, session)
        
        return [serialize(item[0], item[1] or 0, item[2]) for item in words]
    
    except SQLAlchemyError as e:
        await session.rollback()
        await session.close()
        raise HTTPException(500, f"Database error: {str(e)}")

async def remove_app_user_words(user_id: int, body: AppUserWords, limit: int):
    try:
        session = await get_session()
        app_user = await get_app_user(user_id, session)
        
        if not app_user:
            raise HTTPException(404, "User not found")
        
        if not len(body.words):
            return []
        
        # Remove words from user's list
        await remove_app_user_word_list(user_id, body.words, session)
        
        words = await select_user_words_from_list(user_id, limit, session)
        
        return [serialize(item[0], item[1] or 0, item[2]) for item in words]
    
    except SQLAlchemyError as e:
        await session.rollback()
        await session.close()
        raise HTTPException(500, f"Database error: {str(e)}")

async def sentences_with_app_user_words(user_id: int, limit: int):
    try:
        session = await get_session()
        app_user = await get_app_user(user_id, session)
        
        if not app_user:
            raise HTTPException(404, "User not found")
        
        user_words = await select_user_words_from_list(user_id, limit, session)
        
        if not user_words:
            return []
        
        ai_service = AIService()
        
        # Create a list of words for the AI prompt
        words_list = [f"- {item[0].word}" for item in user_words]
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
        # Parse AI response and match with word IDs
        import json
        try:
            ai_sentences = json.loads(response)
            result = []
            
            # Create a mapping from word to word_id
            word_to_id = {item[0].word: item[0].id for item in user_words}
            
            for sentence_data in ai_sentences:
                word = sentence_data.get("word")
                example = sentence_data.get("example_sentence")
                
                if word in word_to_id:
                    result.append({
                        "word_id": word_to_id[word],
                        "word": word,
                        "example_sentence": example
                    })
            
            return result
            
        except json.JSONDecodeError as e:
            # Fallback: return basic structure if AI doesn't return valid JSON
            print(f"JSON parsing error: {e}")
            return [{"word_id": item[0].id, "example_sentence": f"AI response parsing failed for: {item[0].word}"} for item in user_words]
    
    except SQLAlchemyError as e:
        await session.rollback()
        await session.close()
        raise HTTPException(500, f"Database error: {str(e)}")

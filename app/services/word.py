from enum import Enum
from fastapi import Depends
from math import floor
import logging
from sqlalchemy import ColumnElement, case, exists, select, delete, func, and_, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload, selectinload
from sqlalchemy.dialects.postgresql import insert as pg_insert
from typing import List

from app.schemas import WordRank
from ..db import get_session
from ..models import AppUser, AppUserWord, CategoryMeaning, PromptExample, Word, Level, Category, Meaning

async def update_words_ranks(user_id: int, items: List[WordRank], session: AsyncSession = Depends(get_session)):
    # de-dup by word_id (keep last) do we really need it?
    dedup = {}
    for it in items:
        dedup[it.word_id] = it.rank
        
    word_ids = list(dedup.keys())
    rank_map = dedup  # {word_id: rank}
    
    # CASE over word_id to set different ranks in one UPDATE
    rank_case = case(rank_map, value=AppUserWord.word_id)
    
    stmt = (
        update(AppUserWord)
        .where(
            AppUserWord.app_user_id == user_id,
            AppUserWord.word_id.in_(word_ids),
        )
        .values(rank=rank_case)
    )
    
    await session.execute(stmt)
    await session.commit()
    
    return word_ids

async def get_words_rank(user_id: int, word_ids: List, session: AsyncSession = Depends(get_session)):
    # Read back the updated rows (portable across DBs)
    sel = (
        select(AppUserWord.word_id, AppUserWord.rank)
        .where(
            AppUserWord.app_user_id == user_id,
            AppUserWord.word_id.in_(word_ids),
        )
    )
    res = await session.execute(sel)
    items = [{"user_id": user_id, "word_id": wid, "rank": r} for (wid, r) in res.all()]
    return items

async def get_app_user(user_id: int, session: AsyncSession):
    return await session.get(AppUser, user_id, options=[selectinload(AppUser.app_user_words).joinedload(AppUserWord.word)])

async def get_word_list(limit: int, session: AsyncSession = Depends(get_session)):
    stmt = (
        select(Word, Category.category)
        .join(Meaning, Meaning.word_id == Word.id, isouter=True)
        .join(CategoryMeaning, CategoryMeaning.meaning_id == Meaning.id, isouter=True)
        .join(Category, CategoryMeaning.category_id == Category.id, isouter=True)
        .distinct()
        .options(
            selectinload(Word.meanings).selectinload(Meaning.verb_form),
            selectinload(Word.meanings).selectinload(Meaning.noun_form),
            selectinload(Word.meanings).selectinload(Meaning.adjective_form),
            selectinload(Word.meanings).selectinload(Meaning.numeral_form),
            selectinload(Word.meanings).selectinload(Meaning.category_meanings).selectinload(CategoryMeaning.category),
        )
    )
    if limit and limit > 0:
        stmt = stmt.limit(limit)
        
    result = await session.execute(stmt)
    return result.all()

async def update_app_user_word_list(user_id: int, words: List[int], session: AsyncSession = Depends(get_session)):
    # Prepare all words for insertion
    new_words = [
        {
            "app_user_id": user_id,
            "word_id": word_id,
            "rank": 0
        }
        for word_id in words
    ]
    
    # Insert all words, duplicates will be ignored by on_conflict_do_nothing
    if new_words:
        insert_stmt = pg_insert(AppUserWord).values(new_words)
        insert_stmt = insert_stmt.on_conflict_do_nothing(
            index_elements=[AppUserWord.app_user_id, AppUserWord.word_id]
        )
        result = await session.execute(insert_stmt)
        await session.commit()
        
        # Return number of rows actually inserted (new words only)
        return result.rowcount
    
    return 0

async def remove_app_user_word_list(user_id: int, words: List[int], session: AsyncSession = Depends(get_session)):
    """Remove word IDs from user's word list (doesn't delete the actual words)"""
    if not words:
        return 0
    
    # Delete from AppUserWord table only
    stmt = (
        delete(AppUserWord)
        .where(
            AppUserWord.app_user_id == user_id,
            AppUserWord.word_id.in_(words)
        )
    )
    
    result = await session.execute(stmt)
    await session.commit()
    
    # Return number of rows deleted
    return result.rowcount

async def get_random_words(conditions: list[ColumnElement[bool]], limit: int, session: AsyncSession = Depends(get_session)):
    stmt = (
        select(Word, AppUserWord.rank, Category.category)
        .join(AppUserWord, AppUserWord.word_id == Word.id, isouter=True)
        .join(Meaning, Meaning.word_id == Word.id, isouter=True)
        .join(CategoryMeaning, CategoryMeaning.meaning_id == Meaning.id, isouter=True)
        .join(Category, CategoryMeaning.category_id == Category.id, isouter=True)
        .distinct()
        .where(*conditions)
        .options(
            selectinload(Word.meanings).selectinload(Meaning.verb_form),
            selectinload(Word.meanings).selectinload(Meaning.noun_form),
            selectinload(Word.meanings).selectinload(Meaning.adjective_form),
            selectinload(Word.meanings).selectinload(Meaning.numeral_form),
            selectinload(Word.meanings).selectinload(Meaning.category_meanings).selectinload(CategoryMeaning.category),
        )
        .order_by(func.random())           # PostgreSQL random order
    )
    
    if limit and limit > 0:
        stmt = stmt.limit(limit)
    
    result = await session.execute(stmt)
    words = result.all()
    
    # Log the number of words returned
    print(f"get_random_words: Retrieved {len(words)} words (limit: {limit})")
    
    return words

async def save_user_words(rows: list[dict[str, int]], session: AsyncSession = Depends(get_session)):
    insert_stmt = pg_insert(AppUserWord).values(rows)
    insert_stmt = insert_stmt.on_conflict_do_nothing(
        index_elements=[AppUserWord.app_user_id, AppUserWord.word_id]
    )
    await session.execute(insert_stmt)
    await session.commit()
        
async def pick_from_bucket(cond, n: int, user_id: int, selected_ids: set, session: AsyncSession = Depends(get_session)):
    """Pick users words"""
    if n <= 0:
        return []

    stmt = (
        select(Word, AppUserWord.rank, Category.category)
        .join(AppUserWord, AppUserWord.word_id == Word.id, isouter=True)
        .join(Meaning, Meaning.word_id == Word.id, isouter=True)
        .join(CategoryMeaning, CategoryMeaning.meaning_id == Meaning.id, isouter=True)
        .join(Category, CategoryMeaning.category_id == Category.id, isouter=True)
        .distinct()
        .where(AppUserWord.app_user_id == user_id, cond, ~Word.id.in_(selected_ids))
        .options(
            selectinload(Word.meanings).selectinload(Meaning.verb_form), 
            selectinload(Word.meanings).selectinload(Meaning.noun_form),
            selectinload(Word.meanings).selectinload(Meaning.adjective_form),
            selectinload(Word.meanings).selectinload(Meaning.numeral_form),
        )
        .order_by(func.random())  # PostgreSQL
    )
    
    if n and n > 0:
        stmt = stmt.limit(n)
        
    res = await session.execute(stmt)
    return res.all() #res.scalars().all()
  
async def select_new_words(app_user: AppUser, limit: int, selected_ids: set, session: AsyncSession = Depends(get_session)):
    """Select new word from database for the user"""
    # exclude words already assigned to this user
    assigned_exists = (
        select(AppUserWord.id)
        .where(
            AppUserWord.app_user_id == app_user.id,
            AppUserWord.word_id == Word.id,
        )
    )
        
    # build conditions
    conditions = [
        Word.level_id == app_user.level_id,
        ~exists(assigned_exists),                 # not yet assigned
    ]
        
    if selected_ids:   # avoid "IN ()" when empty
        conditions.append(~Word.id.in_(selected_ids))  # not already selected in this call
    
    return await get_random_words(conditions, limit, session)

async def select_user_words_from_list(user_id: int, limit: int, session: AsyncSession = Depends(get_session)):
    # Get the user's words directly from database after insertion
    stmt = (
        select(Word, AppUserWord.rank, Category.category)
        .join(AppUserWord, AppUserWord.word_id == Word.id)
        .join(Meaning, Meaning.word_id == Word.id, isouter=True)
        .join(CategoryMeaning, CategoryMeaning.meaning_id == Meaning.id, isouter=True)
        .join(Category, CategoryMeaning.category_id == Category.id, isouter=True)
        .distinct()
        .where(AppUserWord.app_user_id == user_id)
        .options(
            selectinload(Word.meanings).selectinload(Meaning.verb_form),
            selectinload(Word.meanings).selectinload(Meaning.noun_form),
            selectinload(Word.meanings).selectinload(Meaning.adjective_form),
            selectinload(Word.meanings).selectinload(Meaning.numeral_form),
            selectinload(Word.meanings).selectinload(Meaning.category_meanings).selectinload(CategoryMeaning.category),
        )
    )
        
    if limit and limit > 0:
        stmt = stmt.limit(limit)
            
    result = await session.execute(stmt)
    return result.all()
                                          
# class POS(str, Enum):
#     verb = "verb"
#     noun = "noun"
#     adjective = "adjective"
#     numeral = "numeral"

# RELATION_BY_POS = {
#     POS.verb: Word.verb_form,
#     POS.noun: Word.noun_form,
#     POS.adjective: Word.adjective_form,
#     POS.numeral: Word.numeral_form,
# }

def serialize(w: Word, rank: int, category: str = None):
    # Get categories for each meaning
    meaning_categories = {}
    for meaning in w.meanings:
        meaning_categories[meaning.id] = []
        for category_meaning in meaning.category_meanings:
            meaning_categories[meaning.id].append(category_meaning.category.category)
    
    out = {
        "id": w.id,
        "word": w.word,
        "meanings": [
            {
                "id": m.id, 
                "pos": m.pos, 
                "meaning": m.meaning, 
                "usage": m.usage, 
                "example_dutch": m.example_dutch, 
                "example_english": m.example_english,
                "categories": meaning_categories.get(m.id, [])
            } for m in w.meanings
        ],
        "rank": rank,  # 0 if user doesn't have it yet
    }
    
    # Handle grammatical forms for all meanings (support words with multiple POS)
    for meaning in w.meanings:
        if meaning.pos == "verb" and meaning.verb_form:
            v = meaning.verb_form
            out["verb_form"] = {
                "infinitive": v.infinitive,
                "present": {
                    "ik": v.ik,
                    "jij": v.jij,
                    "u": v.u,
                    "hij": v.hij,
                    "wij": v.wij,
                },
                "past": {"sg": v.past_sg, "pl": v.past_pl},
                "perfect": {"aux": v.perfect, "participle": v.past_participle},
                "separable_prefix": v.separable_prefix,
                "is_separable": v.separable_prefix is not None,
                "is_irregular": v.is_irregular,
                "is_strong_verb": v.is_strong_verb,
                "is_modal": v.is_modal,
            }
        elif meaning.pos == "noun" and meaning.noun_form:
            n = meaning.noun_form
            out["noun_form"] = {
                "noun": w.word,
                "indefinite_article": n.indefinite_article,
                "diminutive": n.diminutive,
                "plural": n.plural,
            }
        elif meaning.pos == "adjective" and meaning.adjective_form:
            a = meaning.adjective_form
            out["adjective_form"] = {
                "base": w.word,  # Get base form from words table
                "inflected": a.inflected,
                "comparative": a.comparative,
                "superlative": a.superlative,
            }
        elif meaning.pos == "numeral" and meaning.numeral_form:
            num = meaning.numeral_form
            out["numeral_form"] = {
                "numeral": w.word,  # Use word from words table instead of redundant numeral column
                "numeric_value": num.numeric_value,
                "ordinal_form": num.ordinal_form,
            }
    return out
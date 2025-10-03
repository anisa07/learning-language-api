from enum import Enum
from fastapi import Depends
from math import floor
import logging
from sqlalchemy import ColumnElement, case, exists, select, delete, func, and_, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload, selectinload
from sqlalchemy.dialects.postgresql import insert as pg_insert
from typing import List

from app.schemas import MeaningRank
from ..db import get_session
from ..models import AppUser, AppUserMeaning, CategoryMeaning, PromptExample, Word, Level, Category, Meaning

async def update_meanings_ranks(user_id: int, items: List[MeaningRank], session: AsyncSession = Depends(get_session)):
    # de-dup by meaning_id (keep last)
    dedup = {}
    for it in items:
        dedup[it.meaning_id] = it.rank
        
    meaning_ids = list(dedup.keys())
    rank_map = dedup  # {meaning_id: rank}
    
    # CASE over meaning_id to set different ranks in one UPDATE
    rank_case = case(rank_map, value=AppUserMeaning.meaning_id)
    
    stmt = (
        update(AppUserMeaning)
        .where(
            AppUserMeaning.app_user_id == user_id,
            AppUserMeaning.meaning_id.in_(meaning_ids),
        )
        .values(rank=rank_case)
    )
    
    await session.execute(stmt)
    await session.commit()
    
    return meaning_ids

async def get_meanings_rank(user_id: int, meaning_ids: List, session: AsyncSession = Depends(get_session)):
    # Read back the updated rows (portable across DBs)
    sel = (
        select(AppUserMeaning.meaning_id, AppUserMeaning.rank)
        .where(
            AppUserMeaning.app_user_id == user_id,
            AppUserMeaning.meaning_id.in_(meaning_ids),
        )
    )
    res = await session.execute(sel)
    items = [{"user_id": user_id, "meaning_id": mid, "rank": r} for (mid, r) in res.all()]
    return items

async def get_app_user(user_id: int, session: AsyncSession):
    return await session.get(AppUser, user_id, options=[selectinload(AppUser.app_user_meanings).joinedload(AppUserMeaning.meaning)])

async def get_meaning_list(limit: int, session: AsyncSession = Depends(get_session)):
    stmt = (
        select(Meaning, Word.word)
        .join(Word, Meaning.word_id == Word.id)
        .options(
            selectinload(Meaning.verb_form),
            selectinload(Meaning.noun_form),
            selectinload(Meaning.adjective_form),
            selectinload(Meaning.numeral_form),
            selectinload(Meaning.category_meanings).selectinload(CategoryMeaning.category),
        )
        .order_by(Word.word, Meaning.pos)
    )
    if limit and limit > 0:
        stmt = stmt.limit(limit)
        
    result = await session.execute(stmt)
    return result.all()

async def update_app_user_meaning_list(user_id: int, meanings: List[int], session: AsyncSession = Depends(get_session)):
    # Prepare all meanings for insertion
    new_meanings = [
        {
            "app_user_id": user_id,
            "meaning_id": meaning_id,
            "rank": 0,
            "is_selected": False
        }
        for meaning_id in meanings
    ]
    
    # Insert all meanings, duplicates will be ignored by on_conflict_do_nothing
    if new_meanings:
        insert_stmt = pg_insert(AppUserMeaning).values(new_meanings)
        insert_stmt = insert_stmt.on_conflict_do_nothing(
            index_elements=[AppUserMeaning.app_user_id, AppUserMeaning.meaning_id]
        )
        result = await session.execute(insert_stmt)
        await session.commit()
        
        # Return number of rows actually inserted (new meanings only)
        return result.rowcount
    
    return 0

async def remove_app_user_meaning_list(user_id: int, meanings: List[int], session: AsyncSession = Depends(get_session)):
    """Remove meaning IDs from user's meaning list (doesn't delete the actual meanings)"""
    if not meanings:
        return 0
    
    # Delete from AppUserMeaning table only
    stmt = (
        delete(AppUserMeaning)
        .where(
            AppUserMeaning.app_user_id == user_id,
            AppUserMeaning.meaning_id.in_(meanings)
        )
    )
    
    result = await session.execute(stmt)
    await session.commit()
    
    # Return number of rows deleted
    return result.rowcount

async def get_random_meanings(conditions: list[ColumnElement[bool]], limit: int, session: AsyncSession = Depends(get_session)):
    stmt = (
        select(Meaning, Word.word, AppUserMeaning.rank)
        .join(Word, Meaning.word_id == Word.id)
        .join(AppUserMeaning, AppUserMeaning.meaning_id == Meaning.id, isouter=True)
        .where(*conditions)
        .options(
            selectinload(Meaning.verb_form),
            selectinload(Meaning.noun_form),
            selectinload(Meaning.adjective_form),
            selectinload(Meaning.numeral_form),
            selectinload(Meaning.category_meanings).selectinload(CategoryMeaning.category),
        )
        .order_by(func.random())           # PostgreSQL random order
    )
    
    if limit and limit > 0:
        stmt = stmt.limit(limit)
    
    result = await session.execute(stmt)
    meanings = result.all()
    
    # Log the number of meanings returned
    print(f"get_random_meanings: Retrieved {len(meanings)} meanings (limit: {limit})")
    
    return meanings

async def save_user_meanings(rows: list[dict[str, int]], session: AsyncSession = Depends(get_session)):
    insert_stmt = pg_insert(AppUserMeaning).values(rows)
    insert_stmt = insert_stmt.on_conflict_do_nothing(
        index_elements=[AppUserMeaning.app_user_id, AppUserMeaning.meaning_id]
    )
    await session.execute(insert_stmt)
    await session.commit()
        
async def pick_from_bucket(cond, n: int, user_id: int, selected_ids: set, session: AsyncSession = Depends(get_session)):
    """Pick users meanings"""
    if n <= 0:
        return []

    stmt = (
        select(Meaning, Word.word, AppUserMeaning.rank, Category)
        .join(Word, Meaning.word_id == Word.id)
        .join(AppUserMeaning, AppUserMeaning.meaning_id == Meaning.id, isouter=True)
        .join(CategoryMeaning, CategoryMeaning.meaning_id == Meaning.id, isouter=True)
        .join(Category, Category.id == CategoryMeaning.category_id, isouter=True)
        .where(AppUserMeaning.app_user_id == user_id, cond, ~Meaning.id.in_(selected_ids))
        .options(
            selectinload(Meaning.verb_form), 
            selectinload(Meaning.noun_form),
            selectinload(Meaning.adjective_form),
            selectinload(Meaning.numeral_form),
            selectinload(Meaning.category_meanings).selectinload(CategoryMeaning.category),
        )
        .order_by(func.random())  # PostgreSQL
    )
    
    if n and n > 0:
        stmt = stmt.limit(n)
        
    res = await session.execute(stmt)
    return res.all()
  
async def select_new_meanings(app_user: AppUser, limit: int, selected_ids: set, session: AsyncSession = Depends(get_session)):
    """Select new meanings from database for the user"""
    # exclude meanings already assigned to this user
    assigned_exists = (
        select(AppUserMeaning.id)
        .where(
            AppUserMeaning.app_user_id == app_user.id,
            AppUserMeaning.meaning_id == Meaning.id,
        )
    )
        
    # build conditions
    conditions = [
        Word.level_id == app_user.level_id,
        ~exists(assigned_exists),                 # not yet assigned
    ]
        
    if selected_ids:   # avoid "IN ()" when empty
        conditions.append(~Meaning.id.in_(selected_ids))  # not already selected in this call
    
    return await get_random_meanings(conditions, limit, session)

async def select_user_meanings_from_list(user_id: int, limit: int, session: AsyncSession = Depends(get_session)):
    # Get the user's meanings directly from database after insertion
    stmt = (
        select(Meaning, Word.word, AppUserMeaning.rank)
        .join(Word, Meaning.word_id == Word.id)
        .join(AppUserMeaning, AppUserMeaning.meaning_id == Meaning.id)
        .where(AppUserMeaning.app_user_id == user_id)
        .options(
            selectinload(Meaning.verb_form),
            selectinload(Meaning.noun_form),
            selectinload(Meaning.adjective_form),
            selectinload(Meaning.numeral_form),
            selectinload(Meaning.category_meanings).selectinload(CategoryMeaning.category),
        )
        .order_by(Word.word, Meaning.pos)
    )
        
    if limit and limit > 0:
        stmt = stmt.limit(limit)
            
    result = await session.execute(stmt)
    return result.all()

async def get_selected_meanings(user_id: int, limit: int, session: AsyncSession = Depends(get_session)):
    """Get only meanings that are selected (is_selected = true) for the user"""
    stmt = (
        select(Meaning, Word.word, AppUserMeaning.rank)
        .join(Word, Meaning.word_id == Word.id)
        .join(AppUserMeaning, AppUserMeaning.meaning_id == Meaning.id)
        .where(
            AppUserMeaning.app_user_id == user_id,
            AppUserMeaning.is_selected == True
        )
        .options(
            selectinload(Meaning.verb_form),
            selectinload(Meaning.noun_form),
            selectinload(Meaning.adjective_form),
            selectinload(Meaning.numeral_form),
            selectinload(Meaning.category_meanings).selectinload(CategoryMeaning.category),
        )
        .order_by(Word.word, Meaning.pos)
    )
        
    if limit and limit > 0:
        stmt = stmt.limit(limit)
            
    result = await session.execute(stmt)
    return result.all()

async def update_selected_meanings(user_id: int, meaning_ids: List[int], is_selected: bool, session: AsyncSession = Depends(get_session)):
    """Update is_selected field for specific meanings for a user"""
    if not meaning_ids:
        return 0
    
    stmt = (
        update(AppUserMeaning)
        .where(
            AppUserMeaning.app_user_id == user_id,
            AppUserMeaning.meaning_id.in_(meaning_ids)
        )
        .values(is_selected=is_selected)
    )
    
    result = await session.execute(stmt)
    await session.commit()
    
    return result.rowcount

def serialize_meaning(m: Meaning, word: str, rank: int):
    # Get categories for this meaning
    meaning_categories = []
    for category_meaning in m.category_meanings:
        meaning_categories.append(category_meaning.category.category)
    
    out = {
        "id": m.id,
        "word": word,
        "pos": m.pos,
        "meaning": m.meaning,
        "usage": m.usage,
        "example_dutch": m.example_dutch,
        "example_english": m.example_english,
        "categories": meaning_categories,
        "rank": rank,
    }
    
    # Handle grammatical forms based on POS
    if m.pos == "verb" and m.verb_form:
        v = m.verb_form
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
    elif m.pos == "noun" and m.noun_form:
        n = m.noun_form
        out["noun_form"] = {
            "noun": word,
            "indefinite_article": n.indefinite_article,
            "diminutive": n.diminutive,
            "plural": n.plural,
        }
    elif m.pos == "adjective" and m.adjective_form:
        a = m.adjective_form
        out["adjective_form"] = {
            "base": word,
            "inflected": a.inflected,
            "comparative": a.comparative,
            "superlative": a.superlative,
        }
    elif m.pos == "numeral" and m.numeral_form:
        num = m.numeral_form
        out["numeral_form"] = {
            "numeral": word,
            "numeric_value": num.numeric_value,
            "ordinal_form": num.ordinal_form,
        }
    
    return out

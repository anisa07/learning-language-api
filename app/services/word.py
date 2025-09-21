from enum import Enum
from fastapi import Depends
from math import floor
from sqlalchemy import ColumnElement, case, exists, select, delete, func, and_, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload, selectinload
from sqlalchemy.dialects.postgresql import insert as pg_insert
from typing import List

from app.schemas import WordRank
from ..db import get_session
from ..models import AppUser, AppUserWord, CategoryWord, PromptExample, Word, Level, Category

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

async def get_user_words(user_id: int, session: AsyncSession):
    return await session.get(AppUser, user_id, options=[selectinload(AppUser.app_user_words).joinedload(AppUserWord.word)])

async def get_random_words(conditions: list[ColumnElement[bool]], limit: int, session: AsyncSession = Depends(get_session)):
    stmt = (
        select(Word, AppUserWord.rank, Category.category)
        .join(AppUserWord, AppUserWord.word_id == Word.id, isouter=True)
        .join(CategoryWord, CategoryWord.word_id == Word.id, isouter=True)
        .join(Category, CategoryWord.category_id == Category.id, isouter=True)
        .where(*conditions)
        .options(
            selectinload(Word.meanings),
            selectinload(Word.verb_form),
            selectinload(Word.noun_form),
            selectinload(Word.adjective_form),
            selectinload(Word.numeral_form),
        )
        .order_by(func.random())           # PostgreSQL random order
        .limit(limit)
    )
    result = await session.execute(stmt)
    return result.all()

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
    print(cond)            
    stmt = (
        select(Word, AppUserWord.rank, Category.category)
        .join(AppUserWord, AppUserWord.word_id == Word.id, isouter=True)
        .join(CategoryWord, CategoryWord.word_id == Word.id, isouter=True)
        .join(Category, CategoryWord.category_id == Category.id, isouter=True)
        .where(AppUserWord.app_user_id == user_id, cond, ~Word.id.in_(selected_ids))
        .options(
            selectinload(Word.meanings), 
            selectinload(Word.verb_form),
            selectinload(Word.noun_form),
            selectinload(Word.adjective_form),
            selectinload(Word.numeral_form),
        )
        .order_by(func.random())  # PostgreSQL
        .limit(n)
    )
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

def serialize(w: Word, rank: int, category: str):
    out = {
        "id": w.id,
        "word": w.word,
        "part_of_speech": w.part_of_speech,
        # "meaning": w.meaning,
        "meanings": [m for m in w.meanings],
        "rank": rank,  # 0 if user doesn't have it yet
        "category": category
    }
    pos = w.part_of_speech
    print(pos)
    print(w)
    if pos == "verb" and w.verb_form:
        v = w.verb_form
        out["verb_form"] = {
            "infinitive": v.infinitive,
            "present": {
                "ik": v.present_simple_1st_singular,
                "jij": v.present_simple_2nd_singular,
                "u": v.present_simple_2nd_respectful,
                "hij": v.present_simple_3rd_singular,
                "wij": v.present_simple_plural,
            },
            "past": {"sg": v.past_simple_singular, "pl": v.past_simple_plural},
            "perfect": {"aux": v.perfect_auxiliary, "participle": v.past_participle},
            "separable_prefix": v.separable_prefix,
            "is_separable": v.is_separable,
            "is_irregular": v.is_irregular,
            "is_strong_verb": v.is_strong_verb,
            "is_modal": v.is_modal,
        }
    elif pos == "noun" and w.noun_form:
        n = w.noun_form
        out["noun_form"] = {
            "noun": n.noun,
            "indefinite_article": n.indefinite_article,
            "diminutive": n.diminutive,
            "plural": n.plural,
        }
    elif pos == "adjective" and w.adjective_form:
        a = w.adjective_form
        out["adjective_form"] = {
            "adjective": a.adjective,
            "de_form": a.de_form,
            "comparison": a.comparison,
            "superlative": a.superlative,
        }
    elif pos == "numeral" and w.numeral_form:
        num = w.numeral_form
        out["numeral_form"] = {
            "numeral": num.numeral,
            "numeric_value": num.numeric_value,
            "ordinal_form": num.ordinal_form,
        }
    return out
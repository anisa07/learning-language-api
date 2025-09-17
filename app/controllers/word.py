from fastapi import Depends, HTTPException
from enum import Enum
from sqlalchemy.ext.asyncio import AsyncSession
from math import floor

from ..services.word import bucket_rank, count_bucket, get_random_words, pick_from_bucket, save_user_words, select_new_words, serialize, get_user_words
from ..models import AppUser, Word
from ..db import get_session

async def get_app_user_words(user_id: int, limit: int, session: AsyncSession = Depends(get_session)):
    # 1) load the user (and level)
    app_user = await get_user_words(user_id, session)
    
    if not app_user:
        raise HTTPException(404, "User not found")
        
    rows = []
    print(app_user.app_user_words)
    if len(app_user.app_user_words) == 0:
        print("user doesn't have words")
        # 2) fetch random words for that level when user has no words
        result = await get_random_words([Word.level_id == app_user.level_id], limit, session)
        words_only = [row[0] for row in result]
        rows = [
            {"app_user_id": user_id, "word_id": item.id, "rank": 0}
            for item in words_only
        ]
        # await save_user_words(rows, session)
        return [serialize(item[0], item[1]) for item in result]
            
    if len(app_user.app_user_words):
        print("user has words")
        # 3) return words for the user
        result = await get_user_ranked_words(limit, app_user, session)
        return result

async def get_user_ranked_words(limit: int, app_user: AppUser, session: AsyncSession = Depends(get_session)):
    buckets = bucket_rank()
    
    for b in buckets.values():
        b["have"] = await count_bucket(b["cond"], app_user.id, session)

    total_have = sum(b["have"] for b in buckets.values())
    
    if total_have == 0:
        return []  # user has no words assigned yet
    
    # initial targets from shares (floor), except r0 which is remainder later
    for key, b in buckets.items():
        if b["share"] is not None:
            b["want"] = min(b["have"], floor(limit * b["share"]))
        used = sum(b["want"] for b in buckets.values())
        buckets["r0"]["want"] = min(buckets["r0"]["have"], max(0, limit - used))
        
    # redistribute leftover (if any) to r0 -> r5 -> r10 -> r15, respecting availability
    leftover = limit - sum(b["want"] for b in buckets.values())
    for key in ["r0", "r5", "r10", "r15"]:
        if leftover <= 0:
            break
        b = buckets[key]
        room = max(0, b["have"] - b["want"])
        take = min(room, leftover)
        b["want"] += take
        leftover -= take
        
    # ---- fetch random words per bucket ----
    selected_ids = set()
    selected = []
    
    for key in ["r15", "r10", "r5", "r0"]:  # fetch in this order (doesn't really matter)
        take = await pick_from_bucket(buckets[key]["cond"], buckets[key]["want"], app_user.id, selected_ids, session)
        for (w, rank) in take:
            print(w)
            selected_ids.add(w.id)
            selected.append({
                "word": w,
                "rank": rank or 0
            })
            
    # if we still have fewer than limit (e.g., not enough assigned words),
    # fill up randomly from the user's remaining assigned words
    rest = max(0, limit - len(selected))
    if rest > 0:
        new_words = select_new_words(app_user, rest,  selected_ids, session)
        
        rows = [
            {"app_user_id": app_user.id, "word_id": item["word"].id, "rank": 0}
            for item in new_words
        ]
        
        await save_user_words(rows, session)
        
        selected.extend(new_words)
        selected_ids.update(w.id for w in new_words)
        
    return [serialize(item['word'], item['rank']) for item in selected[:limit]]

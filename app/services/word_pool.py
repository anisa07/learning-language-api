from sqlalchemy import and_

from app.services.word import pick_from_bucket
from ..models import AppUser, AppUserWord, Word
from sqlalchemy import ColumnElement, case, exists, select, delete, func, and_, update
from sqlalchemy.ext.asyncio import AsyncSession
from math import floor

class WordPool:
    def bucket_rank(self):
        """
        Define non-overlapping rank buckets + target shares
            5% from rank = 15
            30% from rank 10–14
            30% from rank 5–9
            the remainder from rank 0–4
        """
        return {
            "r15":  dict(cond=(AppUserWord.rank == 15), share=0.05, want=0, have=0),
            "r10":  dict(cond=and_(AppUserWord.rank >= 10, AppUserWord.rank <= 14), share=0.30, want=0, have=0),
            "r5":   dict(cond=and_(AppUserWord.rank >= 5,  AppUserWord.rank <= 9),  share=0.30, want=0, have=0),
            "r0":   dict(cond=and_(AppUserWord.rank >= 0,  AppUserWord.rank <= 4),  share=None, want=0, have=0),  # gets the remainder
        }
    
    async def _get_user_word_pool_selection_plan(self, user_id: int, limit: int, session: AsyncSession):
        buckets = self.bucket_rank()
        
        for b in buckets.values():
            # count how many words user have of that specific condition
            b["have"] = await self._count_bucket(b["cond"], user_id, session)

        total_have = sum(b["have"] for b in buckets.values())
        
        if total_have == 0:
            return []  # user has no words assigned yet
        
        # initial targets from shares (floor), except r0 which is remainder later
        for b in buckets.values():
            if b["share"] is not None:
                b["want"] = min(b["have"], floor(limit * b["share"]))
            used = sum(b["want"] for b in buckets.values())
            buckets["r0"]["want"] = min(buckets["r0"]["have"], max(0, limit - used))
            
        # redistribute leftover (if any) to r0 -> r5 -> r10 -> r15, respecting availability
        leftover = limit - sum(b["want"] for b in buckets.values())
        for b in buckets.values():
            if leftover <= 0:
                break
            room = max(0, b["have"] - b["want"])
            take = min(room, leftover)
            b["want"] += take
            leftover -= take
        return buckets
    
    async def get_user_words(self, user_id: int, limit: int, session: AsyncSession):
        buckets = await self._get_user_word_pool_selection_plan(user_id, limit, session)
        
        selected_ids = set()
        selected = []
        
        for b in buckets.values():  # fetch in this order (doesn't really matter)
            take = await pick_from_bucket(b["cond"], b["want"], user_id, selected_ids, session)
            for (w, rank, category) in take:
                selected_ids.add(w.id)
                selected.append({
                    "word": w,
                    "rank": rank or 0,
                    "category": category
                })
        return selected
    
    async def _count_bucket(self, cond, user_id: int, session: AsyncSession):
        """Count how many user words exist in each bucket satisfying condition"""
        q = select(func.count()).select_from(AppUserWord).where(
            AppUserWord.app_user_id == user_id, cond
        )
        return (await session.execute(q)).scalar_one()

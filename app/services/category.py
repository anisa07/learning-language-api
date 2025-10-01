from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import Depends

from ..db import get_session
from ..models import Category


async def get_all_categories(session: AsyncSession = Depends(get_session)):
    """Fetch all categories from the database"""
    stmt = select(Category).order_by(Category.category)
    result = await session.execute(stmt)
    return result.scalars().all()


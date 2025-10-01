from fastapi import HTTPException
from sqlalchemy.exc import SQLAlchemyError
from typing import List

from ..db import get_session
from ..services.category import get_all_categories
from ..schemas import CategoryRead


async def get_categories() -> List[CategoryRead]:
    """Controller to get all categories"""
    try:
        session = await get_session()
        categories = await get_all_categories(session)
        
        # Convert SQLAlchemy models to Pydantic schemas
        return [
            CategoryRead(id=cat.id, category=cat.category)
            for cat in categories
        ]
    
    except SQLAlchemyError as e:
        await session.rollback()
        await session.close()
        raise HTTPException(500, f"Database error: {str(e)}")


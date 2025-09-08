from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete
from ..db import get_session
from ..models import PromptExample
from ..schemas import PromptExampleCreate, PromptExampleRead, ChatRequest, ChatResponse
from ..services.ai import AIService

router = APIRouter()
ai = AIService()

@router.get("/health")
async def health():
    return {"status": "ok"}

@router.post("/ai/chat", response_model=ChatResponse)
async def ai_chat(req: ChatRequest):
    try:
        text, provider, model = await ai.chat(req.prompt, req.system, req.provider, req.model)
        return ChatResponse(output=text, provider=provider, model=model)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/examples", response_model=PromptExampleRead)
async def create_example(payload: PromptExampleCreate, session: AsyncSession = Depends(get_session)):
    row = PromptExample(title=payload.title, prompt=payload.prompt)
    session.add(row)
    await session.commit()
    await session.refresh(row)
    return row

@router.get("/examples", response_model=list[PromptExampleRead])
async def list_examples(session: AsyncSession = Depends(get_session)):
    res = await session.execute(select(PromptExample).order_by(PromptExample.created_at.desc()))
    return [*res.scalars().all()]

@router.get("/examples/{id}", response_model=PromptExampleRead)
async def get_example(id: int, session: AsyncSession = Depends(get_session)):
    row = await session.get(PromptExample, id)
    if not row:
        raise HTTPException(404, "Not found")
    return row

@router.delete("/examples/{id}")
async def delete_example(id: int, session: AsyncSession = Depends(get_session)):
    await session.execute(delete(PromptExample).where(PromptExample.id == id))
    await session.commit()
    return {"ok": True}

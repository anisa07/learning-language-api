from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List

class PromptExampleBase(BaseModel):
    title: str
    prompt: str

class PromptExampleCreate(PromptExampleBase):
    pass

class PromptExampleRead(PromptExampleBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True

# Word schemas
class WordBase(BaseModel):
    word: str
    part_of_speech: str
    meaning: str

class WordCreate(WordBase):
    pass

class WordRead(WordBase):
    id: int

    class Config:
        from_attributes = True

# VerbForm schemas
class VerbFormBase(BaseModel):
    infinitive: str
    modal: bool = False
    ik: Optional[str] = None
    jij: Optional[str] = None
    u: Optional[str] = None
    hij: Optional[str] = None
    wij: Optional[str] = None
    past_sg: Optional[str] = None
    past_pl: Optional[str] = None
    past_participle: Optional[str] = None
    perfect: Optional[str] = None
    separable_prefix: Optional[str] = None
    is_irregular: bool = False
    is_strong_verb: bool = False

class VerbFormCreate(VerbFormBase):
    word_id: int

class VerbFormRead(VerbFormBase):
    id: int
    word_id: int
    created_at: datetime

    class Config:
        from_attributes = True

# NounForm schemas
class NounFormBase(BaseModel):
    indefinite_article: Optional[str] = None
    definite_article: Optional[str] = None
    diminutive: str
    plural: str

class NounFormCreate(NounFormBase):
    word_id: int

class NounFormRead(NounFormBase):
    id: int
    word_id: int

    class Config:
        from_attributes = True

# AdjectiveForm schemas
class AdjectiveFormBase(BaseModel):
    inflected: str
    comparative: str
    superlative: str

class AdjectiveFormCreate(AdjectiveFormBase):
    word_id: int

class AdjectiveFormRead(AdjectiveFormBase):
    id: int
    word_id: int

    class Config:
        from_attributes = True

# Category schemas
class CategoryBase(BaseModel):
    category: str

class CategoryCreate(CategoryBase):
    pass

class CategoryRead(CategoryBase):
    id: int

    class Config:
        from_attributes = True

# Level schemas
class LevelBase(BaseModel):
    level: str

class LevelCreate(LevelBase):
    pass

class LevelRead(LevelBase):
    id: int

    class Config:
        from_attributes = True

# AppUser schemas
class AppUserBase(BaseModel):
    pass

class AppUserCreate(AppUserBase):
    level_id: int

class AppUserRead(AppUserBase):
    id: int
    level_id: int

    class Config:
        from_attributes = True

# AppUserWord schemas
class AppUserWordBase(BaseModel):
    rank: int = 0

class AppUserWordCreate(AppUserWordBase):
    app_user_id: int
    word_id: int

class AppUserWordRead(AppUserWordBase):
    id: int
    app_user_id: int
    word_id: int

    class Config:
        from_attributes = True

# CategoryWord schemas  
class CategoryWordBase(BaseModel):
    pass

class CategoryWordCreate(CategoryWordBase):
    category_id: int
    word_id: int

class CategoryWordRead(CategoryWordBase):
    id: int
    category_id: int
    word_id: int

    class Config:
        from_attributes = True

class ChatRequest(BaseModel):
    prompt: str
    system: str | None = None
    provider: str | None = None  # override default
    model: str | None = None     # override default

class ChatResponse(BaseModel):
    output: str
    provider: str
    model: str
    
class WordRank(BaseModel):
    word_id: int
    rank: int

class BatchSetRanks(BaseModel):
    items: List[WordRank]

class AppUserWords(BaseModel):
    words: List[int]
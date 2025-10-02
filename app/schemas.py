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

class WordCreate(WordBase):
    level_id: int

class WordRead(WordBase):
    id: int
    level_id: int

    class Config:
        from_attributes = True

# Meaning schemas
class MeaningBase(BaseModel):
    pos: str
    meaning: str
    usage: Optional[str] = None
    example_dutch: Optional[str] = None
    example_english: Optional[str] = None

class MeaningCreate(MeaningBase):
    word_id: int

class MeaningRead(MeaningBase):
    id: int
    word_id: int

    class Config:
        from_attributes = True

# VerbForm schemas
class VerbFormBase(BaseModel):
    infinitive: str
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
    is_modal: bool = False

class VerbFormCreate(VerbFormBase):
    meaning_id: int

class VerbFormRead(VerbFormBase):
    id: int
    meaning_id: int
    created_at: datetime

    class Config:
        from_attributes = True

# NounForm schemas
class NounFormBase(BaseModel):
    indefinite_article: Optional[str] = None
    diminutive: Optional[str] = None
    plural: Optional[str] = None

class NounFormCreate(NounFormBase):
    meaning_id: int

class NounFormRead(NounFormBase):
    id: int
    meaning_id: int

    class Config:
        from_attributes = True

# AdjectiveForm schemas
class AdjectiveFormBase(BaseModel):
    inflected: Optional[str] = None
    comparative: Optional[str] = None
    superlative: Optional[str] = None

class AdjectiveFormCreate(AdjectiveFormBase):
    meaning_id: int

class AdjectiveFormRead(AdjectiveFormBase):
    id: int
    meaning_id: int

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
    username: Optional[str] = None
    email: Optional[str] = None

class AppUserCreate(AppUserBase):
    level_id: int

class AppUserRead(AppUserBase):
    id: int
    level_id: int
    created_at: datetime

    class Config:
        from_attributes = True

# AppUserWord schemas
class AppUserWordBase(BaseModel):
    rank: int = 0
    learned_at: Optional[datetime] = None

class AppUserWordCreate(AppUserWordBase):
    app_user_id: int
    word_id: int

class AppUserWordRead(AppUserWordBase):
    id: int
    app_user_id: int
    word_id: int

    class Config:
        from_attributes = True

# CategoryMeaning schemas  
class CategoryMeaningBase(BaseModel):
    pass

class CategoryMeaningCreate(CategoryMeaningBase):
    category_id: int
    meaning_id: int

class CategoryMeaningRead(CategoryMeaningBase):
    id: int
    category_id: int
    meaning_id: int

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

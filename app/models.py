from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import String, Text, DateTime, func, ForeignKey, Integer
from typing import List
from .db import Base

class PromptExample(Base):
    __tablename__ = "prompt_examples"
    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    title: Mapped[str] = mapped_column(String(200))
    prompt: Mapped[str] = mapped_column(Text())
    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now())

class Word(Base):
    __tablename__ = "words"
    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    word: Mapped[str] = mapped_column(String(100))
    part_of_speech: Mapped[str] = mapped_column(String(25)) # e.g adjective, noun, verb
    meaning: Mapped[str] = mapped_column(String(100))
    
    # Foreign key to Level (many words can have the same level)
    level_id: Mapped[int] = mapped_column(ForeignKey("levels.id"))
    
    # Relationship to Level
    level: Mapped["Level"] = relationship("Level", back_populates="words")
    
    # 1-to-1 relationship with VerbForm (optional - only for verbs)
    verb_form: Mapped["VerbForm"] = relationship("VerbForm", back_populates="word", uselist=False)
    # 1-to-1 relationship with NounForm (optional - only for nouns)
    noun_form: Mapped["NounForm"] = relationship("NounForm", back_populates="word", uselist=False)
     # 1-to-1 relationship with AdjectiveForm (optional - only for adjectives)
    adjective_form: Mapped["AdjectiveForm"] = relationship("AdjectiveForm", back_populates="word", uselist=False)
    
    # Many-to-many relationship with Category
    category_words: Mapped[List["CategoryWord"]] = relationship("CategoryWord", back_populates="word")
    
    # Many-to-many relationship with AppUser
    app_user_words: Mapped[List["AppUserWord"]] = relationship("AppUserWord", back_populates="word")

class VerbForm(Base):
    __tablename__ = "verb_forms"
    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    
    # 1-to-1 relationship with Word
    word_id: Mapped[int] = mapped_column(ForeignKey("words.id"), unique=True)
    word: Mapped["Word"] = relationship("Word", back_populates="verb_form")
    
    infinitive: Mapped[str] = mapped_column(String(100))
    modal: Mapped[bool] = mapped_column(default=False)
    
    # Present Simple (Onvoltooid Tegenwoordige Tijd)
    present_simple_1st_singular: Mapped[str] = mapped_column(String(100), nullable=True)  # ik
    present_simple_2nd_singular: Mapped[str] = mapped_column(String(100), nullable=True)  # jij/je
    present_simple_2nd_respectful: Mapped[str] = mapped_column(String(100), nullable=True)  # u
    present_simple_3rd_singular: Mapped[str] = mapped_column(String(100), nullable=True)  # hij/zij/het
    present_simple_plural: Mapped[str] = mapped_column(String(100), nullable=True)  # wij/jullie/zij
    
    # Past Simple (Onvoltooid Verleden Tijd) - simplified
    past_simple_singular: Mapped[str] = mapped_column(String(100), nullable=True)  # ik/jij/hij
    past_simple_plural: Mapped[str] = mapped_column(String(100), nullable=True)  # wij/jullie/zij
    
    # Present Perfect (Voltooid Tegenwoordige Tijd)
    past_participle: Mapped[str] = mapped_column(String(100), nullable=True)  # gebruikt in perfectum
    perfect_auxiliary: Mapped[str] = mapped_column(String(10), nullable=True)  # "hebben", "zijn", or "both"
    
    # Separable verb parts (for separable verbs like "opstaan")
    separable_prefix: Mapped[str] = mapped_column(String(50), nullable=True)
    is_separable: Mapped[bool] = mapped_column(default=False)
    
    # Irregular verb indicators
    is_irregular: Mapped[bool] = mapped_column(default=False)
    is_strong_verb: Mapped[bool] = mapped_column(default=False)  # strong vs weak verbs
    
    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    
class NounForm(Base):
    __tablename__ = "noun_forms"
    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    indefinite_article: Mapped[str] = mapped_column(String(5), nullable=True)
    definite_article: Mapped[str] = mapped_column(String(5), nullable=True)
    diminutive: Mapped[str] = mapped_column(String(100))
    plural: Mapped[str] = mapped_column(String(100))
    # 1-to-1 relationship with Word
    word_id: Mapped[int] = mapped_column(ForeignKey("words.id"), unique=True)
    word: Mapped["Word"] = relationship("Word", back_populates="noun_form")

class AdjectiveForm(Base):
    __tablename__ = "adjective_forms"
    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    comparison: Mapped[str] = mapped_column(String(100))
    superlative: Mapped[str] = mapped_column(String(100))
     # 1-to-1 relationship with Word
    word_id: Mapped[int] = mapped_column(ForeignKey("words.id"), unique=True)
    word: Mapped["Word"] = relationship("Word", back_populates="adjective_form")
    
class Category(Base):
    __tablename__ = "categories"
    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    category: Mapped[str] = mapped_column(String(100))
    
    # Many-to-many relationship with Word
    category_words: Mapped[List["CategoryWord"]] = relationship("CategoryWord", back_populates="category")

class CategoryWord(Base):
    __tablename__ = "category_words"
    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    
    # Many-to-many association table
    category_id: Mapped[int] = mapped_column(ForeignKey("categories.id"))
    word_id: Mapped[int] = mapped_column(ForeignKey("words.id"))
    
    # Optional: relationships to access the linked objects
    category: Mapped["Category"] = relationship("Category", back_populates="category_words")
    word: Mapped["Word"] = relationship("Word", back_populates="category_words")

class AppUser(Base):
    __tablename__ = "app_users"
    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    
    # Foreign key to Level (many users can have the same level)
    level_id: Mapped[int] = mapped_column(ForeignKey("levels.id"))
    
    # Relationship to Level
    level: Mapped["Level"] = relationship("Level", back_populates="users")
    
    # Many-to-many relationship with Word through AppUserWord
    app_user_words: Mapped[List["AppUserWord"]] = relationship("AppUserWord", back_populates="app_user")

class AppUserWord(Base):
    __tablename__ = "app_user_words"
    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    rank: Mapped[int] = mapped_column(Integer, default=0) 
    
    # Many-to-many association table
    app_user_id: Mapped[int] = mapped_column(ForeignKey("app_users.id"))
    word_id: Mapped[int] = mapped_column(ForeignKey("words.id"))
    
    # Relationships to access the linked objects
    app_user: Mapped["AppUser"] = relationship("AppUser", back_populates="app_user_words")
    word: Mapped["Word"] = relationship("Word", back_populates="app_user_words")

class Level(Base):
    __tablename__ = "levels"
    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    level: Mapped[str] = mapped_column(String(15)) # A2, B1
    
    # One-to-many relationship with AppUser
    users: Mapped[List["AppUser"]] = relationship("AppUser", back_populates="level")
    
    # One-to-many relationship with Word
    words: Mapped[List["Word"]] = relationship("Word", back_populates="level")



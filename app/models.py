from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import CheckConstraint, String, Text, DateTime, UniqueConstraint, func, ForeignKey, Integer
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
    __table_args__ = (UniqueConstraint("word", "part_of_speech", name="uq_words_token_pos"), CheckConstraint("part_of_speech IN ('verb','noun','adjective','numeral')", name="ck_pos"),)
    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    word: Mapped[str] = mapped_column(String(150), nullable=False) # if ite's verb - infinitive, noun - singular form with definite article, adjective - het form w/o e at the end
    part_of_speech: Mapped[str] = mapped_column(String(25), nullable=False) # e.g adjective, noun, verb
    
    # Foreign key to Level (many words can have the same level)
    level_id: Mapped[int] = mapped_column(ForeignKey("levels.id"))
    # Relationship to Level
    level: Mapped["Level"] = relationship("Level", back_populates="words")
    # 1-to-1 relationship with Verb (optional - only for verbs)
    verb_form: Mapped["Verb"] = relationship("Verb", back_populates="word", uselist=False)
    # 1-to-1 relationship with Noun (optional - only for nouns)
    noun_form: Mapped["Noun"] = relationship("Noun", back_populates="word", uselist=False)
    # 1-to-1 relationship with Numeral (optional - only for numerals)
    numeral_form: Mapped["Numeral"] = relationship("Numeral", back_populates="word", uselist=False)
    # 1-to-1 relationship with AdjectiveForm (optional - only for adjectives)
    adjective_form: Mapped["Adjective"] = relationship("Adjective", back_populates="word", uselist=False)
    # Many-to-many relationship with Category
    category_words: Mapped[List["CategoryWord"]] = relationship("CategoryWord", back_populates="word")
    # Many-to-many relationship with AppUser
    app_user_words: Mapped[List["AppUserWord"]] = relationship("AppUserWord", back_populates="word")
    # One-to-many relationship with Meaning
    meanings:  Mapped[List["Meaning"]] = relationship("Meaning", back_populates="word", cascade="all, delete-orphan")

class Meaning(Base):
    __tablename__ = "meanings"
    __table_args__ = (UniqueConstraint("word_id", "meaning", name="uq_meaning_per_word"),)
    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    meaning = mapped_column(String(200), nullable=False)
    usage = mapped_column(Text, nullable=True) # context
    example = mapped_column(Text, nullable=True)
    example_translation = mapped_column(Text, nullable=True)
    # One-to-many relationship with Word
    word_id: Mapped[int] = mapped_column(ForeignKey("words.id"), nullable=False, index=True)
    word: Mapped["Word"] = relationship("Word", back_populates="meanings")

class Verb(Base):
    __tablename__ = "verbs"
    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    infinitive: Mapped[str] = mapped_column(String(100))
    
    # Present Simple (Onvoltooid Tegenwoordige Tijd)
    ik: Mapped[str] = mapped_column(String(100), nullable=True)  # ik (1st person singular)
    jij: Mapped[str] = mapped_column(String(100), nullable=True)  # jij/je (2nd person singular informal)
    u: Mapped[str] = mapped_column(String(100), nullable=True)  # u (2nd person singular/plural formal)
    hij: Mapped[str] = mapped_column(String(100), nullable=True)  # hij/zij/het (3rd person singular)
    wij: Mapped[str] = mapped_column(String(100), nullable=True)  # wij/jullie/zij (plural)
    
    # Past Simple (Onvoltooid Verleden Tijd)
    past_sg: Mapped[str] = mapped_column(String(100), nullable=True)  # ik/jij/hij (singular)
    past_pl: Mapped[str] = mapped_column(String(100), nullable=True)  # wij/jullie/zij (plural)
    
    # Present Perfect (Voltooid Tegenwoordige Tijd)
    past_participle: Mapped[str] = mapped_column(String(100), nullable=True)  # gebruikt in perfectum
    perfect: Mapped[str] = mapped_column(String(10), nullable=True)  # "hebben", "zijn", or "both"
    
    # Separable verb parts (for separable verbs like "opstaan")
    separable_prefix: Mapped[str] = mapped_column(String(50), nullable=True)
    
    # Irregular verb indicators
    is_irregular: Mapped[bool] = mapped_column(default=False)
    is_strong_verb: Mapped[bool] = mapped_column(default=False)  # strong vs weak verbs
    is_modal: Mapped[bool] = mapped_column(default=False)

    # 1-to-1 relationship with Word
    word_id: Mapped[int] = mapped_column(ForeignKey("words.id"), unique=True)
    word: Mapped["Word"] = relationship("Word", back_populates="verb_form")

    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    
class Noun(Base):
    __tablename__ = "nouns"
    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    indefinite_article: Mapped[str] = mapped_column(String(5), nullable=True) # de/het
    diminutive: Mapped[str] = mapped_column(String(100), nullable=True)
    plural: Mapped[str] = mapped_column(String(100), nullable=True)
    # 1-to-1 relationship with Word
    word_id: Mapped[int] = mapped_column(ForeignKey("words.id"), unique=True)
    word: Mapped["Word"] = relationship("Word", back_populates="noun_form")

    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now())

class Numeral(Base):
    __tablename__ = "numerals"
    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    numeric_value: Mapped[int] = mapped_column(Integer, nullable=True) # the actual number (e.g. 3, 20)
    ordinal_form: Mapped[str] = mapped_column(String(100), nullable=True) # ordinal form (e.g. "derde", "twintigste")
    
    # 1-to-1 relationship with Word
    word_id: Mapped[int] = mapped_column(ForeignKey("words.id"), unique=True)
    word: Mapped["Word"] = relationship("Word", back_populates="numeral_form")

    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now())

class Adjective(Base):
    __tablename__ = "adjectives"
    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    inflected: Mapped[str] = mapped_column(String(150), nullable=True) # if applicable
    comparative: Mapped[str] = mapped_column(String(100), nullable=True)
    superlative: Mapped[str] = mapped_column(String(100), nullable=True)
    # 1-to-1 relationship with Word
    word_id: Mapped[int] = mapped_column(ForeignKey("words.id"), unique=True)
    word: Mapped["Word"] = relationship("Word", back_populates="adjective_form")

    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    
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
    username: Mapped[str] = mapped_column(String(50), unique=True, nullable=True)
    email: Mapped[str] = mapped_column(String(100), unique=True, nullable=True)
    
    # Foreign key to Level (many users can have the same level)
    level_id: Mapped[int] = mapped_column(ForeignKey("levels.id"))
    # Relationship to Level
    level: Mapped["Level"] = relationship("Level", back_populates="users")
    # Many-to-many relationship with Word through AppUserWord
    app_user_words: Mapped[List["AppUserWord"]] = relationship("AppUserWord", back_populates="app_user")

    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now())

class AppUserWord(Base):
    __tablename__ = "app_user_words"
    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    rank: Mapped[int] = mapped_column(Integer, default=0)
    learned_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), nullable=True)
    
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
    count: Mapped[int] = mapped_column(Integer, default=0) 
    # One-to-many relationship with AppUser
    users: Mapped[List["AppUser"]] = relationship("AppUser", back_populates="level")
    
    # One-to-many relationship with Word
    words: Mapped[List["Word"]] = relationship("Word", back_populates="level")


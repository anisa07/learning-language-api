-- 00_schema.sql
-- Create tables for Dutch Language Learning API
-- This file is automatically executed when the PostgreSQL container initializes

-- Create prompt_examples table
CREATE TABLE IF NOT EXISTS prompt_examples (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    prompt TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create levels table first (referenced by other tables)
CREATE TABLE IF NOT EXISTS levels (
    id SERIAL PRIMARY KEY,
    level VARCHAR(15) NOT NULL UNIQUE,
    count INTEGER DEFAULT 0
);

-- Create categories table
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    category VARCHAR(100) NOT NULL UNIQUE
);

-- Create words table
CREATE TABLE IF NOT EXISTS words (
    id SERIAL PRIMARY KEY,
    word VARCHAR(150) NOT NULL UNIQUE,
    level_id INTEGER REFERENCES levels(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create meanings table 1-to-many connection with word
CREATE TABLE IF NOT EXISTS meanings (
  id SERIAL PRIMARY KEY,
  word_id INTEGER NOT NULL REFERENCES words(id) ON DELETE CASCADE,
  pos VARCHAR(25) NOT NULL,
  meaning VARCHAR(200) NOT NULL,
  usage TEXT,
  example_dutch TEXT,
  example_english TEXT,
  CONSTRAINT uq_meaning_per_word_pos UNIQUE (word_id, meaning, pos)
);

-- Create verbs table (1-to-1 with meanings where pos = 'verb')
CREATE TABLE IF NOT EXISTS verbs (
    id SERIAL PRIMARY KEY,
    meaning_id INTEGER UNIQUE REFERENCES meanings(id) ON DELETE CASCADE,
    infinitive VARCHAR(100),
    
    -- Present Simple (Onvoltooid Tegenwoordige Tijd)
    ik VARCHAR(100), -- ik (1st person singular)
    jij VARCHAR(100), -- jij/je (2nd person singular informal)
    u VARCHAR(100), -- u (2nd person singular/plural formal)
    hij VARCHAR(100), -- hij/zij/het (3rd person singular)
    wij VARCHAR(100), -- wij/jullie/zij (plural)
    
    -- Past Simple (Onvoltooid Verleden Tijd)
    past_sg VARCHAR(100), -- ik/jij/hij (singular)
    past_pl VARCHAR(100), -- wij/jullie/zij (plural)
    
    -- Present Perfect (Voltooid Tegenwoordige Tijd)
    past_participle VARCHAR(100), -- gebruikt in perfectum
    perfect VARCHAR(10), -- "hebben", "zijn", or "both"
    
    -- Separable verb parts
    separable_prefix VARCHAR(50),
    
    -- Irregular verb indicators
    is_irregular BOOLEAN DEFAULT FALSE,
    is_strong_verb BOOLEAN DEFAULT FALSE,
    is_modal BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create nouns table (1-to-1 with meanings where pos = 'noun')
CREATE TABLE IF NOT EXISTS nouns (
    id SERIAL PRIMARY KEY,
    meaning_id INTEGER UNIQUE REFERENCES meanings(id) ON DELETE CASCADE,
    indefinite_article VARCHAR(5), -- de/het article
    diminutive VARCHAR(100), -- -je, -tje endings
    plural VARCHAR(100), -- plural form
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create numerals table (1-to-1 with meanings where pos = 'numeral')
CREATE TABLE IF NOT EXISTS numerals (
    id SERIAL PRIMARY KEY,
    meaning_id INTEGER UNIQUE REFERENCES meanings(id) ON DELETE CASCADE,
    numeric_value INTEGER, -- the actual number (e.g. 3, 20)
    ordinal_form VARCHAR(100), -- ordinal form (e.g. "derde", "twintigste")
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create adjectives table (1-to-1 with meanings where pos = 'adjective')
CREATE TABLE IF NOT EXISTS adjectives (
    id SERIAL PRIMARY KEY,
    meaning_id INTEGER UNIQUE REFERENCES meanings(id) ON DELETE CASCADE,
    inflected VARCHAR(150), -- if applicable
    comparative VARCHAR(100), -- comparative form (-er)
    superlative VARCHAR(100), -- superlative form (-st)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create app_users table
CREATE TABLE IF NOT EXISTS app_users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE,
    email VARCHAR(100) UNIQUE,
    level_id INTEGER REFERENCES levels(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create many-to-many relationship tables
CREATE TABLE IF NOT EXISTS category_meanings (
    id SERIAL PRIMARY KEY,
    category_id INTEGER REFERENCES categories(id) ON DELETE CASCADE,
    meaning_id INTEGER REFERENCES meanings(id) ON DELETE CASCADE,
    UNIQUE(category_id, meaning_id)
);

CREATE TABLE IF NOT EXISTS app_user_meanings (
    id SERIAL PRIMARY KEY,
    app_user_id INTEGER REFERENCES app_users(id) ON DELETE CASCADE,
    meaning_id INTEGER REFERENCES meanings(id) ON DELETE CASCADE,
    rank INTEGER DEFAULT 0,
    is_selected BOOLEAN DEFAULT FALSE,
    UNIQUE(app_user_id, meaning_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_words_level_id ON words(level_id);
CREATE INDEX IF NOT EXISTS idx_words_word ON words(word);
CREATE INDEX IF NOT EXISTS idx_meanings_word_id ON meanings(word_id);
CREATE INDEX IF NOT EXISTS idx_meanings_pos ON meanings(pos);
CREATE INDEX IF NOT EXISTS idx_verbs_meaning_id ON verbs(meaning_id);
CREATE INDEX IF NOT EXISTS idx_nouns_meaning_id ON nouns(meaning_id);
CREATE INDEX IF NOT EXISTS idx_numerals_meaning_id ON numerals(meaning_id);
CREATE INDEX IF NOT EXISTS idx_numerals_numeric_value ON numerals(numeric_value);
CREATE INDEX IF NOT EXISTS idx_adjectives_meaning_id ON adjectives(meaning_id);
CREATE INDEX IF NOT EXISTS idx_category_meanings_category_id ON category_meanings(category_id);
CREATE INDEX IF NOT EXISTS idx_category_meanings_meaning_id ON category_meanings(meaning_id);
CREATE INDEX IF NOT EXISTS idx_app_user_meanings_user_id ON app_user_meanings(app_user_id);
CREATE INDEX IF NOT EXISTS idx_app_user_meanings_meaning_id ON app_user_meanings(meaning_id);
CREATE INDEX IF NOT EXISTS idx_app_user_meanings_is_selected ON app_user_meanings(is_selected);
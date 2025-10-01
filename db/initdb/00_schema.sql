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
    word VARCHAR(150),
    part_of_speech VARCHAR(25) NOT NULL,
    level_id INTEGER REFERENCES levels(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(word, part_of_speech) -- Allow same word with different meanings
);

-- Create meanings table 1-to-many connection with word
CREATE TABLE IF NOT EXISTS meanings (
  id SERIAL PRIMARY KEY,
  word_id INTEGER NOT NULL REFERENCES words(id) ON DELETE CASCADE,
  meaning VARCHAR(200) NOT NULL,
  usage TEXT,
  example TEXT,
  example_translation TEXT,
  CONSTRAINT uq_meaning_per_word UNIQUE (word_id, meaning)
);

-- Create verbs table (1-to-1 with words where part_of_speech = 'verb')
CREATE TABLE IF NOT EXISTS verbs (
    id SERIAL PRIMARY KEY,
    word_id INTEGER UNIQUE REFERENCES words(id) ON DELETE CASCADE,
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

-- Create nouns table (1-to-1 with words where part_of_speech = 'noun')
CREATE TABLE IF NOT EXISTS nouns (
    id SERIAL PRIMARY KEY,
    word_id INTEGER UNIQUE REFERENCES words(id) ON DELETE CASCADE,
    indefinite_article VARCHAR(5), -- de/het article
    diminutive VARCHAR(100), -- -je, -tje endings
    plural VARCHAR(100), -- plural form
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create numerals table (1-to-1 with words where part_of_speech = 'numeral')
CREATE TABLE IF NOT EXISTS numerals (
    id SERIAL PRIMARY KEY,
    word_id INTEGER UNIQUE REFERENCES words(id) ON DELETE CASCADE,
    numeric_value INTEGER, -- the actual number (e.g. 3, 20)
    ordinal_form VARCHAR(100), -- ordinal form (e.g. "derde", "twintigste")
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create adjectives table (1-to-1 with words where part_of_speech = 'adjective')
CREATE TABLE IF NOT EXISTS adjectives (
    id SERIAL PRIMARY KEY,
    word_id INTEGER UNIQUE REFERENCES words(id) ON DELETE CASCADE,
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
CREATE TABLE IF NOT EXISTS category_words (
    id SERIAL PRIMARY KEY,
    category_id INTEGER REFERENCES categories(id) ON DELETE CASCADE,
    word_id INTEGER REFERENCES words(id) ON DELETE CASCADE,
    UNIQUE(category_id, word_id)
);

CREATE TABLE IF NOT EXISTS app_user_words (
    id SERIAL PRIMARY KEY,
    app_user_id INTEGER REFERENCES app_users(id) ON DELETE CASCADE,
    word_id INTEGER REFERENCES words(id) ON DELETE CASCADE,
    rank INTEGER DEFAULT 0,
    learned_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(app_user_id, word_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_words_part_of_speech ON words(part_of_speech);
CREATE INDEX IF NOT EXISTS idx_words_level_id ON words(level_id);
CREATE INDEX IF NOT EXISTS idx_words_word ON words(word);
CREATE INDEX IF NOT EXISTS idx_verbs_word_id ON verbs(word_id);
CREATE INDEX IF NOT EXISTS idx_nouns_word_id ON nouns(word_id);
CREATE INDEX IF NOT EXISTS idx_numerals_word_id ON numerals(word_id);
CREATE INDEX IF NOT EXISTS idx_numerals_numeric_value ON numerals(numeric_value);
CREATE INDEX IF NOT EXISTS idx_adjectives_word_id ON adjectives(word_id);
CREATE INDEX IF NOT EXISTS idx_category_words_category_id ON category_words(category_id);
CREATE INDEX IF NOT EXISTS idx_category_words_word_id ON category_words(word_id);
CREATE INDEX IF NOT EXISTS idx_app_user_words_user_id ON app_user_words(app_user_id);
CREATE INDEX IF NOT EXISTS idx_app_user_words_word_id ON app_user_words(word_id);
CREATE INDEX IF NOT EXISTS idx_meanings_word_id ON meanings(word_id);
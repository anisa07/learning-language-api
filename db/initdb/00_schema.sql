-- 00_schema.sql
-- Create tables for Dutch Language Learning API
-- This file is automatically executed when the PostgreSQL container initializes

-- Create levels table first (referenced by other tables)
CREATE TABLE IF NOT EXISTS levels (
    id SERIAL PRIMARY KEY,
    level VARCHAR(15) NOT NULL UNIQUE
);

-- Create categories table
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    category VARCHAR(100) NOT NULL UNIQUE
);

-- Create words table
CREATE TABLE IF NOT EXISTS words (
    id SERIAL PRIMARY KEY,
    word VARCHAR(100) NOT NULL,
    part_of_speech VARCHAR(25) NOT NULL,
    meaning VARCHAR(500) NOT NULL,
    level_id INTEGER REFERENCES levels(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(word, meaning) -- Allow same word with different meanings
);

-- Create verb_forms table (1-to-1 with words where part_of_speech = 'verb')
CREATE TABLE IF NOT EXISTS verb_forms (
    id SERIAL PRIMARY KEY,
    word_id INTEGER UNIQUE REFERENCES words(id) ON DELETE CASCADE,
    infinitive VARCHAR(100),
    modal BOOLEAN DEFAULT FALSE,
    
    -- Present Simple (Onvoltooid Tegenwoordige Tijd)
    present_simple_1st_singular VARCHAR(100), -- ik
    present_simple_2nd_singular VARCHAR(100), -- jij/je
    present_simple_2nd_respectful VARCHAR(100), -- u
    present_simple_3rd_singular VARCHAR(100), -- hij/zij/het
    present_simple_plural VARCHAR(100), -- wij/jullie/zij
    
    -- Past Simple (Onvoltooid Verleden Tijd)
    past_simple_singular VARCHAR(100), -- ik/jij/hij
    past_simple_plural VARCHAR(100), -- wij/jullie/zij
    
    -- Present Perfect (Voltooid Tegenwoordige Tijd)
    past_participle VARCHAR(100), -- gebruikt in perfectum
    perfect_auxiliary VARCHAR(10), -- "hebben", "zijn", or "both"
    
    -- Separable verb parts
    separable_prefix VARCHAR(50),
    is_separable BOOLEAN DEFAULT FALSE,
    
    -- Irregular verb indicators
    is_irregular BOOLEAN DEFAULT FALSE,
    is_strong_verb BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create noun_forms table (1-to-1 with words where part_of_speech = 'noun')
CREATE TABLE IF NOT EXISTS noun_forms (
    id SERIAL PRIMARY KEY,
    word_id INTEGER UNIQUE REFERENCES words(id) ON DELETE CASCADE,
    indefinite_article VARCHAR(5), -- een, een
    definite_article VARCHAR(5), -- de, het
    diminutive VARCHAR(100), -- -je, -tje endings
    plural VARCHAR(100), -- plural form
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create adjective_forms table (1-to-1 with words where part_of_speech = 'adjective')
CREATE TABLE IF NOT EXISTS adjective_forms (
    id SERIAL PRIMARY KEY,
    word_id INTEGER UNIQUE REFERENCES words(id) ON DELETE CASCADE,
    comparison VARCHAR(100), -- comparative form (-er)
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
CREATE INDEX IF NOT EXISTS idx_category_words_category_id ON category_words(category_id);
CREATE INDEX IF NOT EXISTS idx_category_words_word_id ON category_words(word_id);
CREATE INDEX IF NOT EXISTS idx_app_user_words_user_id ON app_user_words(app_user_id);
CREATE INDEX IF NOT EXISTS idx_app_user_words_word_id ON app_user_words(word_id);
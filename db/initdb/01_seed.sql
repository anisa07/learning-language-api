-- 01_seed.sql
-- Complete seed data for Dutch Language Learning API
-- Auto-generated from dutch_words.json and dutch-learning-backup.json
-- This file is automatically executed after schema creation

-- Insert CEFR levels with target counts
INSERT INTO levels (level, count) VALUES 
('A1', 500), ('A2', 1000), ('B1', 1500), ('B2', 2000), ('C1', 3000), ('C2', 5000)
ON CONFLICT (level) DO UPDATE SET count = EXCLUDED.count;

-- Insert consolidated categories (reduced from 276 to 123)
INSERT INTO categories (category) VALUES
('abandonment'),('ability'),('accommodation'),('accompaniment'),('activity'),
('age'),('application'),('approximation'),('astronomy'),('authority'),
('beginning'),('body'),('brevity'),('building'),('category'),
('change'),('classification'),('cleanliness'),('clothing'),('color'),
('commerce'),('communication'),('concession'),('conflict'),('consensus'),
('consumption'),('creation'),('culture'),('design'),('development'),
('direction'),('discovery'),('disposal'),('education'),('element'),
('emotion'),('exclusion'),('existence'),('expertise'),('feature'),
('food'),('foundation'),('function'),('future'),('global'),
('goods'),('grammar'),('health'),('housework'),('impact'),
('industry'),('information'),('intention'),('language'),('leisure'),
('life'),('location'),('luck'),('manner'),('manufacturing'),
('material'),('media'),('medical'),('mental'),('mixture'),
('money'),('movement'),('nature'),('numbers'),('object'),
('occurrence'),('ordinary'),('organization'),('origin'),('outcome'),
('people'),('person'),('personality'),('perspective'),('plan'),
('plural'),('possession'),('power'),('preference'),('presence'),
('quality'),('quantity'),('reality'),('reason'),('reflexive'),
('relation'),('relationships'),('representation'),('reputation'),('response'),
('rest'),('risk'),('royalty'),('rule'),('scenery'),
('season'),('sense'),('service'),('shape'),('singular'),
('skill'),('social'),('speed'),('stage'),('substance'),
('suggestion'),('sum'),('support'),('temperature'),('thing'),
('thought'),('time'),('topic'),('transportation'),('truth'),
('type'),('weight'),('work')
ON CONFLICT (category) DO NOTHING;

-- Insert all vocabulary words from CSV
-- Create a temporary table to load CSV data
CREATE TEMP TABLE temp_vocab_words (
    number INTEGER,
    dutch TEXT,
    english TEXT,
    part_of_speech TEXT,
    category TEXT,
    example_dutch TEXT,
    example_english TEXT
);

-- Load CSV data into temporary table
COPY temp_vocab_words(number, dutch, english, part_of_speech, category, example_dutch, example_english)
FROM '/docker-entrypoint-initdb.d/easy-vocabulary.csv'
DELIMITER ','
CSV HEADER
QUOTE '"';

-- Insert words from CSV (all at A2 level since it's "easy vocabulary")
DO $$
DECLARE
    a2_level_id INTEGER;
BEGIN
    -- Get A2 level ID
    SELECT id INTO a2_level_id FROM levels WHERE level = 'A2';

    -- Insert words from temp table (all at A2 level)
    INSERT INTO words (word, part_of_speech, level_id)
    SELECT DISTINCT dutch, part_of_speech, a2_level_id
    FROM temp_vocab_words
    ON CONFLICT (word, part_of_speech) DO NOTHING;

    -- Also insert category associations
    INSERT INTO category_words (category_id, word_id)
    SELECT DISTINCT c.id, w.id
    FROM temp_vocab_words tv
    JOIN words w ON w.word = tv.dutch AND w.part_of_speech = tv.part_of_speech
    JOIN categories c ON c.category = tv.category
    ON CONFLICT (category_id, word_id) DO NOTHING;

    -- Auto-categorize words by part of speech (for backward compatibility)
    INSERT INTO category_words (category_id, word_id)
    SELECT c.id, w.id 
    FROM categories c, words w 
    WHERE c.category = 'verbs' AND w.part_of_speech = 'verb'
    ON CONFLICT (category_id, word_id) DO NOTHING;

    INSERT INTO category_words (category_id, word_id)
    SELECT c.id, w.id 
    FROM categories c, words w 
    WHERE c.category = 'adjectives' AND w.part_of_speech = 'adjective'
    ON CONFLICT (category_id, word_id) DO NOTHING;

    INSERT INTO category_words (category_id, word_id)
    SELECT c.id, w.id 
    FROM categories c, words w 
    WHERE c.category = 'numbers' AND w.part_of_speech = 'numeral'
    ON CONFLICT (category_id, word_id) DO NOTHING;

    INSERT INTO category_words (category_id, word_id)
    SELECT c.id, w.id 
    FROM categories c, words w 
    WHERE c.category = 'prepositions' AND w.part_of_speech = 'preposition'
    ON CONFLICT (category_id, word_id) DO NOTHING;

    INSERT INTO category_words (category_id, word_id)
    SELECT c.id, w.id 
    FROM categories c, words w 
    WHERE c.category = 'articles' AND w.part_of_speech = 'article'
    ON CONFLICT (category_id, word_id) DO NOTHING;

    INSERT INTO category_words (category_id, word_id)
    SELECT c.id, w.id 
    FROM categories c, words w 
    WHERE c.category = 'pronouns' AND w.part_of_speech = 'pronoun'
    ON CONFLICT (category_id, word_id) DO NOTHING;

END $$;

-- Clean up temporary table
DROP TABLE temp_vocab_words;

-- Display summary
DO $$
DECLARE
    word_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO word_count FROM words;
    RAISE NOTICE 'Total words in database: %', word_count;
END $$;

-- Create noun forms for Dutch nouns with articles
INSERT INTO nouns
(word_id, noun, indefinite_article, diminutive, plural, possessive_form_singular, possessive_form_plural)
VALUES
((SELECT id FROM words WHERE word='de druif' AND part_of_speech='noun' LIMIT 1), 'de druif', 'een', 'het druifje', 'druiven', NULL, NULL),
((SELECT id FROM words WHERE word='de stad' AND part_of_speech='noun' LIMIT 1), 'de stad', 'een', 'het stadje', 'steden', NULL, NULL),
((SELECT id FROM words WHERE word='het huis' AND part_of_speech='noun' LIMIT 1), 'het huis', 'een', 'het huisje', 'huizen', NULL, NULL),
((SELECT id FROM words WHERE word='de vriend' AND part_of_speech='noun' LIMIT 1), 'de vriend', 'een', 'het vriendje', 'vrienden', NULL, NULL),
((SELECT id FROM words WHERE word='de vriendin' AND part_of_speech='noun' LIMIT 1), 'de vriendin', 'een', 'het vriendinnetje', 'vriendinnen', NULL, NULL),
((SELECT id FROM words WHERE word='de appel' AND part_of_speech='noun' LIMIT 1), 'de appel', 'een', 'het appeltje', 'appels', NULL, NULL),
((SELECT id FROM words WHERE word='de banaan' AND part_of_speech='noun' LIMIT 1), 'de banaan', 'een', 'het banaantje', 'bananen', NULL, NULL),
((SELECT id FROM words WHERE word='de kers' AND part_of_speech='noun' LIMIT 1), 'de kers', 'een', 'het kersje', 'kersen', NULL, NULL),
((SELECT id FROM words WHERE word='de peer' AND part_of_speech='noun' LIMIT 1), 'de peer', 'een', 'het peertje', 'peren', NULL, NULL),
((SELECT id FROM words WHERE word='de naam' AND part_of_speech='noun' LIMIT 1), 'de naam', 'een', 'het naampje', 'namen', NULL, NULL),
((SELECT id FROM words WHERE word='het woord' AND part_of_speech='noun' LIMIT 1), 'het woord', 'een', 'het woordje', 'woorden', NULL, NULL),
((SELECT id FROM words WHERE word='de week' AND part_of_speech='noun' LIMIT 1), 'de week', 'een', 'het weekje', 'weken', NULL, NULL),
((SELECT id FROM words WHERE word='het land' AND part_of_speech='noun' LIMIT 1), 'het land', 'een', 'het landje', 'landen', NULL, NULL),
((SELECT id FROM words WHERE word='de taal' AND part_of_speech='noun' LIMIT 1), 'de taal', 'een', 'het taaltje', 'talen', NULL, NULL),
((SELECT id FROM words WHERE word='de foto' AND part_of_speech='noun' LIMIT 1), 'de foto', 'een', 'het fotootje', 'foto''s', NULL, NULL),
((SELECT id FROM words WHERE word='het gesprek' AND part_of_speech='noun' LIMIT 1), 'het gesprek', 'een', 'het gesprekje', 'gesprekken', NULL, NULL),
((SELECT id FROM words WHERE word='de vraag' AND part_of_speech='noun' LIMIT 1), 'de vraag', 'een', 'het vraagje', 'vragen', NULL, NULL),
((SELECT id FROM words WHERE word='de tekst' AND part_of_speech='noun' LIMIT 1), 'de tekst', 'een', 'het tekstje', 'teksten', NULL, NULL),
((SELECT id FROM words WHERE word='het model' AND part_of_speech='noun' LIMIT 1), 'het model', 'een', 'het modelletje', 'modellen', NULL, NULL),
((SELECT id FROM words WHERE word='de e-mail' AND part_of_speech='noun' LIMIT 1), 'de e-mail', 'een', 'het e-mailtje', 'e-mails', NULL, NULL),
((SELECT id FROM words WHERE word='de mail' AND part_of_speech='noun' LIMIT 1), 'de mail', 'een', 'het mailtje', 'mails', NULL, NULL),
((SELECT id FROM words WHERE word='het hoofd' AND part_of_speech='noun' LIMIT 1), 'het hoofd', 'een', 'het hoofdje', 'hoofden', NULL, NULL),
((SELECT id FROM words WHERE word='de arm' AND part_of_speech='noun' LIMIT 1), 'de arm', 'een', 'het armpje', 'armen', NULL, NULL),
((SELECT id FROM words WHERE word='de bank' AND part_of_speech='noun' LIMIT 1), 'de bank', 'een', 'het bankje', 'banken', NULL, NULL),
((SELECT id FROM words WHERE word='het lied' AND part_of_speech='noun' LIMIT 1), 'het lied', 'een', 'het liedje', 'liederen', NULL, NULL),
((SELECT id FROM words WHERE word='de rol' AND part_of_speech='noun' LIMIT 1), 'de rol', 'een', 'het rolletje', 'rollen', NULL, NULL),
((SELECT id FROM words WHERE word='de roos' AND part_of_speech='noun' LIMIT 1), 'de roos', 'een', 'het roosje', 'rozen', NULL, NULL),
((SELECT id FROM words WHERE word='de studie' AND part_of_speech='noun' LIMIT 1), 'de studie', 'een', 'het studietje', 'studies', NULL, NULL),
((SELECT id FROM words WHERE word='het thema' AND part_of_speech='noun' LIMIT 1), 'het thema', 'een', 'het themaatje', 'thema''s', NULL, NULL),
((SELECT id FROM words WHERE word='de vorm' AND part_of_speech='noun' LIMIT 1), 'de vorm', 'een', 'het vormpje', 'vormen', NULL, NULL),
((SELECT id FROM words WHERE word='de wereld' AND part_of_speech='noun' LIMIT 1), 'de wereld', 'een', 'het wereldje', 'werelden', NULL, NULL),
((SELECT id FROM words WHERE word='het niveau' AND part_of_speech='noun' LIMIT 1), 'het niveau', 'een', 'het niveautje', 'niveaus', NULL, NULL),
((SELECT id FROM words WHERE word='de oefening' AND part_of_speech='noun' LIMIT 1), 'de oefening', 'een', 'het oefeningetje', 'oefeningen', NULL, NULL),
((SELECT id FROM words WHERE word='het contact' AND part_of_speech='noun' LIMIT 1), 'het contact', 'een', 'het contactje', 'contacten', NULL, NULL),
((SELECT id FROM words WHERE word='de opdracht' AND part_of_speech='noun' LIMIT 1), 'de opdracht', 'een', 'het opdrachtje', 'opdrachten', NULL, NULL),
((SELECT id FROM words WHERE word='de oplossing' AND part_of_speech='noun' LIMIT 1), 'de oplossing', 'een', 'het oplossingetje', 'oplossingen', NULL, NULL),
((SELECT id FROM words WHERE word='de persoon' AND part_of_speech='noun' LIMIT 1), 'de persoon', 'een', 'het persoontje', 'personen', NULL, NULL),
((SELECT id FROM words WHERE word='het recht' AND part_of_speech='noun' LIMIT 1), 'het recht', 'een', 'het rechtje', 'rechten', NULL, NULL),
((SELECT id FROM words WHERE word='de reeks' AND part_of_speech='noun' LIMIT 1), 'de reeks', 'een', 'het reeksje', 'reeksen', NULL, NULL),
((SELECT id FROM words WHERE word='het schema' AND part_of_speech='noun' LIMIT 1), 'het schema', 'een', 'het schemaatje', 'schema''s', NULL, NULL),
((SELECT id FROM words WHERE word='de situatie' AND part_of_speech='noun' LIMIT 1), 'de situatie', 'een', 'het situatietje', 'situaties', NULL, NULL),
((SELECT id FROM words WHERE word='de spraak' AND part_of_speech='noun' LIMIT 1), 'de spraak', 'een', 'het spraakje', 'spraken', NULL, NULL),
((SELECT id FROM words WHERE word='de acht' AND part_of_speech='noun' LIMIT 1), 'de acht', 'een', 'het achtje', 'achten', NULL, NULL),
((SELECT id FROM words WHERE word='de vaardigheid' AND part_of_speech='noun' LIMIT 1), 'de vaardigheid', 'een', 'het vaardigheidje', 'vaardigheden', NULL, NULL),
((SELECT id FROM words WHERE word='het vierfasemodel' AND part_of_speech='noun' LIMIT 1), 'het vierfasemodel', 'een', 'het vierfasemodelletje', 'vierfasemodellen', NULL, NULL),
((SELECT id FROM words WHERE word='de volwassene' AND part_of_speech='noun' LIMIT 1), 'de volwassene', 'een', 'het volwassenetje', 'volwassenen', NULL, NULL),
((SELECT id FROM words WHERE word='de vormgeving' AND part_of_speech='noun' LIMIT 1), 'de vormgeving', NULL, NULL, NULL, NULL, NULL),
((SELECT id FROM words WHERE word='de woordenlijst' AND part_of_speech='noun' LIMIT 1), 'de woordenlijst', 'een', 'het woordenlijstje', 'woordenlijsten', NULL, NULL),
((SELECT id FROM words WHERE word='de woordenschat' AND part_of_speech='noun' LIMIT 1), 'de woordenschat', NULL, NULL, 'woordenschatten', NULL, NULL),
((SELECT id FROM words WHERE word='de woordzoeker' AND part_of_speech='noun' LIMIT 1), 'de woordzoeker', 'een', 'het woordzoekertje', 'woordzoekers', NULL, NULL),
((SELECT id FROM words WHERE word='de test' AND part_of_speech='noun' LIMIT 1), 'de test', 'een', 'het testje', 'testen', NULL, NULL),
((SELECT id FROM words WHERE word='het antwoord' AND part_of_speech='noun' LIMIT 1), 'het antwoord', 'een', 'het antwoordje', 'antwoorden', NULL, NULL),
((SELECT id FROM words WHERE word='het aspect' AND part_of_speech='noun' LIMIT 1), 'het aspect', 'een', 'het aspectje', 'aspecten', NULL, NULL),
((SELECT id FROM words WHERE word='de audiocd' AND part_of_speech='noun' LIMIT 1), 'de audiocd', 'een', 'het audiocd''tje', 'audiocd''s', NULL, NULL),
((SELECT id FROM words WHERE word='het adres' AND part_of_speech='noun' LIMIT 1), 'het adres', 'een', 'het adresje', 'adressen', NULL, NULL),
((SELECT id FROM words WHERE word='de bagage' AND part_of_speech='noun' LIMIT 1), 'de bagage', NULL, NULL, NULL, NULL, NULL),  -- uncountable
((SELECT id FROM words WHERE word='het boek' AND part_of_speech='noun' LIMIT 1), 'het boek', 'een', 'het boekje', 'boeken', NULL, NULL),
((SELECT id FROM words WHERE word='de bijlage' AND part_of_speech='noun' LIMIT 1), 'de bijlage', 'een', 'het bijlagetje', 'bijlagen', NULL, NULL),
((SELECT id FROM words WHERE word='de cd' AND part_of_speech='noun' LIMIT 1), 'de cd', 'een', 'het cd''tje', 'cd''s', NULL, NULL),
((SELECT id FROM words WHERE word='het centrum' AND part_of_speech='noun' LIMIT 1), 'het centrum', 'een', 'het centrumpje', 'centra', NULL, NULL),
((SELECT id FROM words WHERE word='de Chinees' AND part_of_speech='noun' LIMIT 1), 'de Chinees', 'een', NULL, 'Chinezen', NULL, NULL),
((SELECT id FROM words WHERE word='de controle' AND part_of_speech='noun' LIMIT 1), 'de controle', 'een', 'het controletje', 'controles', NULL, NULL),
((SELECT id FROM words WHERE word='de cursist' AND part_of_speech='noun' LIMIT 1), 'de cursist', 'een', 'het cursistje', 'cursisten', NULL, NULL),
((SELECT id FROM words WHERE word='de cursus' AND part_of_speech='noun' LIMIT 1), 'de cursus', 'een', 'het cursusje', 'cursussen', NULL, NULL),
((SELECT id FROM words WHERE word='de dag' AND part_of_speech='noun' LIMIT 1), 'de dag', 'een', 'het dagje', 'dagen', NULL, NULL),
((SELECT id FROM words WHERE word='het deel' AND part_of_speech='noun' LIMIT 1), 'het deel', 'een', 'het deeltje', 'delen', NULL, NULL),
((SELECT id FROM words WHERE word='de Deen' AND part_of_speech='noun' LIMIT 1), 'de Deen', 'een', NULL, 'Denen', NULL, NULL),
((SELECT id FROM words WHERE word='de dialoog' AND part_of_speech='noun' LIMIT 1), 'de dialoog', 'een', 'het dialoogje', 'dialogen', NULL, NULL),
((SELECT id FROM words WHERE word='de docent' AND part_of_speech='noun' LIMIT 1), 'de docent', 'een', 'het docentje', 'docenten', NULL, NULL),
((SELECT id FROM words WHERE word='de druk' AND part_of_speech='noun' LIMIT 1), 'de druk', 'een', 'het drukje', 'drukken', NULL, NULL),
((SELECT id FROM words WHERE word='het effect' AND part_of_speech='noun' LIMIT 1), 'het effect', 'een', 'het effectje', 'effecten', NULL, NULL),
((SELECT id FROM words WHERE word='het element' AND part_of_speech='noun' LIMIT 1), 'het element', 'een', 'het elementje', 'elementen', NULL, NULL),
((SELECT id FROM words WHERE word='de ervaring' AND part_of_speech='noun' LIMIT 1), 'de ervaring', 'een', 'het ervaringetje', 'ervaringen', NULL, NULL),
((SELECT id FROM words WHERE word='het examen' AND part_of_speech='noun' LIMIT 1), 'het examen', 'een', 'het examentje', 'examens', NULL, NULL),
((SELECT id FROM words WHERE word='de fase' AND part_of_speech='noun' LIMIT 1), 'de fase', 'een', 'het fasetje', 'fases', NULL, NULL),
((SELECT id FROM words WHERE word='de Fransman' AND part_of_speech='noun' LIMIT 1), 'de Fransman', 'een', NULL, 'Fransen', NULL, NULL),
((SELECT id FROM words WHERE word='de gedachte' AND part_of_speech='noun' LIMIT 1), 'de gedachte', 'een', NULL, 'gedachten', NULL, NULL),
((SELECT id FROM words WHERE word='het gen' AND part_of_speech='noun' LIMIT 1), 'het gen', 'een', 'het genetje', 'genen', NULL, NULL),
((SELECT id FROM words WHERE word='het geval' AND part_of_speech='noun' LIMIT 1), 'het geval', 'een', 'het gevalletje', 'gevallen', NULL, NULL),
((SELECT id FROM words WHERE word='het huiswerk' AND part_of_speech='noun' LIMIT 1), 'het huiswerk', NULL, NULL, NULL, NULL, NULL), -- usually uncountable
((SELECT id FROM words WHERE word='de kamer' AND part_of_speech='noun' LIMIT 1), 'de kamer', 'een', 'het kamertje', 'kamers', NULL, NULL),
((SELECT id FROM words WHERE word='het kamp' AND part_of_speech='noun' LIMIT 1), 'het kamp', 'een', 'het kampje', 'kampen', NULL, NULL),
((SELECT id FROM words WHERE word='de kennis' AND part_of_speech='noun' LIMIT 1), 'de kennis', 'een', NULL, 'kennissen', NULL, NULL),
((SELECT id FROM words WHERE word='de koningin' AND part_of_speech='noun' LIMIT 1), 'de koningin', 'een', 'het koninginnetje', 'koninginnen', NULL, NULL),
((SELECT id FROM words WHERE word='de kroon' AND part_of_speech='noun' LIMIT 1), 'de kroon', 'een', 'het kroontje', 'kronen', NULL, NULL),
((SELECT id FROM words WHERE word='het kruis' AND part_of_speech='noun' LIMIT 1), 'het kruis', 'een', 'het kruisje', 'kruisen', NULL, NULL),
((SELECT id FROM words WHERE word='de lay-out' AND part_of_speech='noun' LIMIT 1), 'de lay-out', 'een', 'het lay-outje', 'lay-outs', NULL, NULL),
((SELECT id FROM words WHERE word='de leeftijd' AND part_of_speech='noun' LIMIT 1), 'de leeftijd', 'een', NULL, 'leeftijden', NULL, NULL),
((SELECT id FROM words WHERE word='de leergang' AND part_of_speech='noun' LIMIT 1), 'de leergang', 'een', 'het leergangetje', 'leergangen', NULL, NULL),
((SELECT id FROM words WHERE word='de leeuw' AND part_of_speech='noun' LIMIT 1), 'de leeuw', 'een', 'het leeuwtje', 'leeuwen', NULL, NULL),
((SELECT id FROM words WHERE word='de lesstof' AND part_of_speech='noun' LIMIT 1), 'de lesstof', NULL, NULL, NULL, NULL, NULL), -- typically uncountable
((SELECT id FROM words WHERE word='de letter' AND part_of_speech='noun' LIMIT 1), 'de letter', 'een', 'het lettertje', 'letters', NULL, NULL),
((SELECT id FROM words WHERE word='de lever' AND part_of_speech='noun' LIMIT 1), 'de lever', 'een', 'het levertje', 'levers', NULL, NULL),
((SELECT id FROM words WHERE word='het meer' AND part_of_speech='noun' LIMIT 1), 'het meer', 'een', 'het meertje', 'meren', NULL, NULL),
((SELECT id FROM words WHERE word='de meneer' AND part_of_speech='noun' LIMIT 1), 'de meneer', 'een', 'het menéértje', 'meneren', NULL, NULL),
((SELECT id FROM words WHERE word='de mening' AND part_of_speech='noun' LIMIT 1), 'de mening', 'een', 'het meningetje', 'meningen', NULL, NULL),
((SELECT id FROM words WHERE word='de mens' AND part_of_speech='noun' LIMIT 1), 'de mens', 'een', NULL, 'mensen', NULL, NULL),
((SELECT id FROM words WHERE word='het middel' AND part_of_speech='noun' LIMIT 1), 'het middel', 'een', 'het middeltje', 'middelen', NULL, NULL),
((SELECT id FROM words WHERE word='de noemer' AND part_of_speech='noun' LIMIT 1), 'de noemer', 'een', 'het noemertje', 'noemers', NULL, NULL),
((SELECT id FROM words WHERE word='de omslag' AND part_of_speech='noun' LIMIT 1), 'de omslag', 'een', 'het omslagje', 'omslagen', NULL, NULL),
((SELECT id FROM words WHERE word='de pizzeria' AND part_of_speech='noun' LIMIT 1), 'de pizzeria', 'een', 'het pizzeriaatje', 'pizzeria''s', NULL, NULL),
((SELECT id FROM words WHERE word='de plaats' AND part_of_speech='noun' LIMIT 1), 'de plaats', 'een', 'het plaatsje', 'plaatsen', NULL, NULL),
((SELECT id FROM words WHERE word='de prins' AND part_of_speech='noun' LIMIT 1), 'de prins', 'een', 'het prinsje', 'prinsen', NULL, NULL),
((SELECT id FROM words WHERE word='het pronomen' AND part_of_speech='noun' LIMIT 1), 'het pronomen', 'een', NULL, 'pronomina', NULL, NULL),
((SELECT id FROM words WHERE word='de puzzel' AND part_of_speech='noun' LIMIT 1), 'de puzzel', 'een', 'het puzzeltje', 'puzzels', NULL, NULL),
((SELECT id FROM words WHERE word='de redactie' AND part_of_speech='noun' LIMIT 1), 'de redactie', 'een', 'het redactietje', 'redacties', NULL, NULL),
((SELECT id FROM words WHERE word='de setting' AND part_of_speech='noun' LIMIT 1), 'de setting', 'een', 'het settingtje', 'settings', NULL, NULL),
((SELECT id FROM words WHERE word='de staat' AND part_of_speech='noun' LIMIT 1), 'de staat', 'een', 'het staatje', 'staten', NULL, NULL),
((SELECT id FROM words WHERE word='de straat' AND part_of_speech='noun' LIMIT 1), 'de straat', 'een', 'het straatje', 'straten', NULL, NULL),
((SELECT id FROM words WHERE word='de streep' AND part_of_speech='noun' LIMIT 1), 'de streep', 'een', 'het streepje', 'strepen', NULL, NULL),
((SELECT id FROM words WHERE word='het stuk' AND part_of_speech='noun' LIMIT 1), 'het stuk', 'een', 'het stukje', 'stukken', NULL, NULL),
((SELECT id FROM words WHERE word='het subthema' AND part_of_speech='noun' LIMIT 1), 'het subthema', 'een', 'het subthemaatje', 'subthema''s', NULL, NULL),
((SELECT id FROM words WHERE word='het symbool' AND part_of_speech='noun' LIMIT 1), 'het symbool', 'een', 'het symbooltje', 'symbolen', NULL, NULL),
((SELECT id FROM words WHERE word='het net' AND part_of_speech='noun' LIMIT 1), 'het net', 'een', 'het netje', 'netten', NULL, NULL),
((SELECT id FROM words WHERE word='het netwerk' AND part_of_speech='noun' LIMIT 1), 'het netwerk', 'een', 'het netwerkje', 'netwerken', NULL, NULL),
((SELECT id FROM words WHERE word='het vak' AND part_of_speech='noun' LIMIT 1), 'het vak', 'een', 'het vakje', 'vakken', NULL, NULL),
((SELECT id FROM words WHERE word='de vakantie' AND part_of_speech='noun' LIMIT 1), 'de vakantie', 'een', 'het vakantietje', 'vakanties', NULL, NULL),
((SELECT id FROM words WHERE word='het verbum' AND part_of_speech='noun' LIMIT 1), 'het verbum', 'een', NULL, 'verba', NULL, NULL),
((SELECT id FROM words WHERE word='de voornaam' AND part_of_speech='noun' LIMIT 1), 'de voornaam', 'een', 'het voornaampje', 'voornamen', NULL, NULL),
((SELECT id FROM words WHERE word='het voorwoord' AND part_of_speech='noun' LIMIT 1), 'het voorwoord', 'een', 'het voorwoordje', 'voorwoorden', NULL, NULL),
((SELECT id FROM words WHERE word='het werkboek' AND part_of_speech='noun' LIMIT 1), 'het werkboek', 'een', 'het werkboekje', 'werkboeken', NULL, NULL),
((SELECT id FROM words WHERE word='de zin' AND part_of_speech='noun' LIMIT 1), 'de zin', 'een', 'het zinnetje', 'zinnen', NULL, NULL),
((SELECT id FROM words WHERE word='Afghanistan' AND part_of_speech='noun' LIMIT 1), 'Afghanistan', NULL, NULL, NULL, NULL, NULL),
((SELECT id FROM words WHERE word='Almere' AND part_of_speech='noun' LIMIT 1), 'Almere', NULL, NULL, NULL, NULL, NULL),
((SELECT id FROM words WHERE word='Amerika' AND part_of_speech='noun' LIMIT 1), 'Amerika', NULL, NULL, NULL, NULL, NULL),
((SELECT id FROM words WHERE word='België' AND part_of_speech='noun' LIMIT 1), 'België', NULL, NULL, NULL, NULL, NULL),
((SELECT id FROM words WHERE word='China' AND part_of_speech='noun' LIMIT 1), 'China', NULL, NULL, NULL, NULL, NULL),
((SELECT id FROM words WHERE word='Denemarken' AND part_of_speech='noun' LIMIT 1), 'Denemarken', NULL, NULL, NULL, NULL, NULL),
((SELECT id FROM words WHERE word='Kopenhagen' AND part_of_speech='noun' LIMIT 1), 'Kopenhagen', NULL, NULL, NULL, NULL, NULL),
((SELECT id FROM words WHERE word='Marokko' AND part_of_speech='noun' LIMIT 1), 'Marokko', NULL, NULL, NULL, NULL, NULL),
((SELECT id FROM words WHERE word='Nijmegen' AND part_of_speech='noun' LIMIT 1), 'Nijmegen', NULL, NULL, NULL, NULL, NULL),
((SELECT id FROM words WHERE word='Polen' AND part_of_speech='noun' LIMIT 1), 'Polen', NULL, NULL, NULL, NULL, NULL),
((SELECT id FROM words WHERE word='Rome' AND part_of_speech='noun' LIMIT 1), 'Rome', NULL, NULL, NULL, NULL, NULL),
((SELECT id FROM words WHERE word='Rusland' AND part_of_speech='noun' LIMIT 1), 'Rusland', NULL, NULL, NULL, NULL, NULL),
((SELECT id FROM words WHERE word='Spanje' AND part_of_speech='noun' LIMIT 1), 'Spanje', NULL, NULL, NULL, NULL, NULL),
((SELECT id FROM words WHERE word='Utrecht' AND part_of_speech='noun' LIMIT 1), 'Utrecht', NULL, NULL, NULL, NULL, NULL),
((SELECT id FROM words WHERE word='Turkije' AND part_of_speech='noun' LIMIT 1), 'Turkije', NULL, NULL, NULL, NULL, NULL),
((SELECT id FROM words WHERE word='de Verenigde Staten' AND part_of_speech='noun' LIMIT 1), 'de Verenigde Staten', NULL, NULL, NULL, NULL, NULL),
((SELECT id FROM words WHERE word='Zweed' AND part_of_speech='noun' LIMIT 1), 'Zweed', NULL, NULL, NULL, NULL, NULL),
((SELECT id FROM words WHERE word='de aandacht' AND part_of_speech='noun' LIMIT 1), 'de aandacht', NULL, NULL, NULL, NULL, NULL),
((SELECT id FROM words WHERE word='de hulp' AND part_of_speech='noun' LIMIT 1), 'de hulp', 'een', 'het hulpje', 'hulpen', NULL, NULL),
((SELECT id FROM words WHERE word='het bestaan' AND part_of_speech='noun' LIMIT 1), 'het bestaan', NULL, NULL, NULL, NULL, NULL)
ON CONFLICT (word_id) DO NOTHING;

-- Create numeral forms for Dutch numerals (explicit rows mirroring nouns style)
INSERT INTO numerals (word_id, numeral, numeric_value, ordinal_form) VALUES
((SELECT id FROM words WHERE word = 'een' AND part_of_speech = 'numeral' LIMIT 1), 'een', 1, 'eerste'),
((SELECT id FROM words WHERE word = 'twee' AND part_of_speech = 'numeral' LIMIT 1), 'twee', 2, 'tweede'),
((SELECT id FROM words WHERE word = 'drie' AND part_of_speech = 'numeral' LIMIT 1), 'drie', 3, 'derde'),
((SELECT id FROM words WHERE word = 'vier' AND part_of_speech = 'numeral' LIMIT 1), 'vier', 4, 'vierde'),
((SELECT id FROM words WHERE word = 'vijf' AND part_of_speech = 'numeral' LIMIT 1), 'vijf', 5, 'vijfde'),
((SELECT id FROM words WHERE word = 'zes' AND part_of_speech = 'numeral' LIMIT 1), 'zes', 6, 'zesde'),
((SELECT id FROM words WHERE word = 'zeven' AND part_of_speech = 'numeral' LIMIT 1), 'zeven', 7, 'zevende'),
((SELECT id FROM words WHERE word = 'acht' AND part_of_speech = 'numeral' LIMIT 1), 'acht', 8, 'achtste'),
((SELECT id FROM words WHERE word = 'negen' AND part_of_speech = 'numeral' LIMIT 1), 'negen', 9, 'negende'),
((SELECT id FROM words WHERE word = 'tien' AND part_of_speech = 'numeral' LIMIT 1), 'tien', 10, 'tiende'),
((SELECT id FROM words WHERE word = 'elf' AND part_of_speech = 'numeral' LIMIT 1), 'elf', 11, 'elfde'),
((SELECT id FROM words WHERE word = 'twaalf' AND part_of_speech = 'numeral' LIMIT 1), 'twaalf', 12, 'twaalfde'),
((SELECT id FROM words WHERE word = 'dertien' AND part_of_speech = 'numeral' LIMIT 1), 'dertien', 13, 'dertiende'),
((SELECT id FROM words WHERE word = 'veertien' AND part_of_speech = 'numeral' LIMIT 1), 'veertien', 14, 'veertiende'),
((SELECT id FROM words WHERE word = 'vijftien' AND part_of_speech = 'numeral' LIMIT 1), 'vijftien', 15, 'vijftiende'),
((SELECT id FROM words WHERE word = 'zestien' AND part_of_speech = 'numeral' LIMIT 1), 'zestien', 16, 'zestiende'),
((SELECT id FROM words WHERE word = 'zeventien' AND part_of_speech = 'numeral' LIMIT 1), 'zeventien', 17, 'zeventiende'),
((SELECT id FROM words WHERE word = 'achttien' AND part_of_speech = 'numeral' LIMIT 1), 'achttien', 18, 'achttiende'),
((SELECT id FROM words WHERE word = 'negentien' AND part_of_speech = 'numeral' LIMIT 1), 'negentien', 19, 'negentiende'),
((SELECT id FROM words WHERE word = 'twintig' AND part_of_speech = 'numeral' LIMIT 1), 'twintig', 20, 'twintigste'),
((SELECT id FROM words WHERE word = 'dertig' AND part_of_speech = 'numeral' LIMIT 1), 'dertig', 30, 'dertigste'),
((SELECT id FROM words WHERE word = 'veertig' AND part_of_speech = 'numeral' LIMIT 1), 'veertig', 40, 'veertigste'),
((SELECT id FROM words WHERE word = 'vijftig' AND part_of_speech = 'numeral' LIMIT 1), 'vijftig', 50, 'vijftigste'),
((SELECT id FROM words WHERE word = 'honderd' AND part_of_speech = 'numeral' LIMIT 1), 'honderd', 100, 'honderdste'),
((SELECT id FROM words WHERE word = 'duizend' AND part_of_speech = 'numeral' LIMIT 1), 'duizend', 1000, 'duizendste'),
((SELECT id FROM words WHERE word = 'achthonderdzesentwintig' AND part_of_speech = 'numeral' LIMIT 1), 'achthonderdzesentwintig', 84, 'achthonderdzesentwintigste'),
((SELECT id FROM words WHERE word = 'vierentachtig' AND part_of_speech = 'numeral' LIMIT 1), 'vierentachtig', 84, 'vierentachtigste'),
((SELECT id FROM words WHERE word = 'vierentwintig' AND part_of_speech = 'numeral' LIMIT 1), 'vierentwintig', 24, 'vierentwintigste'),
((SELECT id FROM words WHERE word = 'zeshonderd' AND part_of_speech = 'numeral' LIMIT 1), 'zeshonderd', 600, 'zeshonderdste'),
((SELECT id FROM words WHERE word = 'zevenhonderdnegenennegentig' AND part_of_speech = 'numeral' LIMIT 1), 'zevenhonderdnegenennegentig', 799, 'zevenhonderdnegenennegentigste')
ON CONFLICT (word_id) DO NOTHING;
-- Create adjective forms for Dutch adjectives (explicit rows)
INSERT INTO adjectives (word_id, adjective, de_form, comparison, superlative) VALUES
((SELECT id FROM words WHERE word = 'groot' AND part_of_speech = 'adjective' LIMIT 1), 'groot', 'grote', 'groter', 'grootste'),
((SELECT id FROM words WHERE word = 'klein' AND part_of_speech = 'adjective' LIMIT 1), 'klein', 'kleine', 'kleiner', 'kleinste'),
((SELECT id FROM words WHERE word = 'oud' AND part_of_speech = 'adjective' LIMIT 1), 'oud', 'oude', 'ouder', 'oudste'),
((SELECT id FROM words WHERE word = 'nieuw' AND part_of_speech = 'adjective' LIMIT 1), 'nieuw', 'nieuwe', 'nieuwer', 'nieuwste'),
((SELECT id FROM words WHERE word = 'mooi' AND part_of_speech = 'adjective' LIMIT 1), 'mooi', 'mooie', 'mooier', 'mooiste'),
((SELECT id FROM words WHERE word = 'lelijk' AND part_of_speech = 'adjective' LIMIT 1), 'lelijk', 'lelijke', 'lelijker', 'lelijkste'),
((SELECT id FROM words WHERE word = 'goed' AND part_of_speech = 'adjective' LIMIT 1), 'goed', 'goede', 'beter', 'best'),
((SELECT id FROM words WHERE word = 'slecht' AND part_of_speech = 'adjective' LIMIT 1), 'slecht', 'slechte', 'slechter', 'slechtst'),
((SELECT id FROM words WHERE word = 'snel' AND part_of_speech = 'adjective' LIMIT 1), 'snel', 'snelle', 'sneller', 'snelst'),
((SELECT id FROM words WHERE word = 'langzaam' AND part_of_speech = 'adjective' LIMIT 1), 'langzaam', 'langzame', 'langzamer', 'langzaamste'),
((SELECT id FROM words WHERE word = 'warm' AND part_of_speech = 'adjective' LIMIT 1), 'warm', 'warme', 'warmer', 'warmste'),
((SELECT id FROM words WHERE word = 'koud' AND part_of_speech = 'adjective' LIMIT 1), 'koud', 'koude', 'kouder', 'koudste'),
((SELECT id FROM words WHERE word = 'moeilijk' AND part_of_speech = 'adjective' LIMIT 1), 'moeilijk', 'moeilijke', 'moeilijker', 'moeilijkste'),
((SELECT id FROM words WHERE word = 'makkelijk' AND part_of_speech = 'adjective' LIMIT 1), 'makkelijk', 'makkelijke', 'makkelijker', 'makkelijkste'),
((SELECT id FROM words WHERE word = 'lang' AND part_of_speech = 'adjective' LIMIT 1), 'lang', 'lange', 'langer', 'langste'),
((SELECT id FROM words WHERE word = 'kort' AND part_of_speech = 'adjective' LIMIT 1), 'kort', 'korte', 'korter', 'kortste'),
((SELECT id FROM words WHERE word = 'interessant' AND part_of_speech = 'adjective' LIMIT 1), 'interessant', 'interessante', 'interessanter', 'interessantste'),
((SELECT id FROM words WHERE word = 'belangrijk' AND part_of_speech = 'adjective' LIMIT 1), 'belangrijk', 'belangrijke', 'belangrijker', 'belangrijkste'),
((SELECT id FROM words WHERE word='al' AND part_of_speech='adjective' LIMIT 1), 'al','alle',NULL,NULL),
((SELECT id FROM words WHERE word='allemaal' AND part_of_speech='adjective' LIMIT 1), 'allemaal','allemaal',NULL,NULL),
((SELECT id FROM words WHERE word='allebei' AND part_of_speech='adjective' LIMIT 1), 'allebei','allebei',NULL,NULL),
((SELECT id FROM words WHERE word='ander' AND part_of_speech='adjective' LIMIT 1), 'ander','andere',NULL,NULL),
((SELECT id FROM words WHERE word='elk' AND part_of_speech='adjective' LIMIT 1), 'elk','elke',NULL,NULL),
((SELECT id FROM words WHERE word='ieder' AND part_of_speech='adjective' LIMIT 1), 'ieder','iedere',NULL,NULL),
((SELECT id FROM words WHERE word='sommige' AND part_of_speech='adjective' LIMIT 1), 'sommige','sommige',NULL,NULL),
((SELECT id FROM words WHERE word='geen' AND part_of_speech='adjective' LIMIT 1), 'geen','geen',NULL,NULL),
((SELECT id FROM words WHERE word='je' AND part_of_speech='adjective' LIMIT 1), 'je','je',NULL,NULL),
((SELECT id FROM words WHERE word='jouw' AND part_of_speech='adjective' LIMIT 1), 'jouw','jouw',NULL,NULL),
((SELECT id FROM words WHERE word='mijn' AND part_of_speech='adjective' LIMIT 1), 'mijn','mijn',NULL,NULL),
((SELECT id FROM words WHERE word='uw' AND part_of_speech='adjective' LIMIT 1), 'uw','uw',NULL,NULL),
((SELECT id FROM words WHERE word='arm' AND part_of_speech='adjective' LIMIT 1), 'arm','arme','armer','armste'),
((SELECT id FROM words WHERE word='bruin' AND part_of_speech='adjective' LIMIT 1), 'bruin','bruine','bruiner','bruinste'),
((SELECT id FROM words WHERE word='druk' AND part_of_speech='adjective' LIMIT 1), 'druk','drukke','drukker','drukste'),
((SELECT id FROM words WHERE word='gelukkig' AND part_of_speech='adjective' LIMIT 1), 'gelukkig','gelukkige','gelukkiger','gelukkigste'),
((SELECT id FROM words WHERE word='leuk' AND part_of_speech='adjective' LIMIT 1), 'leuk','leuke','leuker','leukste'),
((SELECT id FROM words WHERE word='los' AND part_of_speech='adjective' LIMIT 1), 'los','losse','losser','losste'),
((SELECT id FROM words WHERE word='net' AND part_of_speech='adjective' LIMIT 1), 'net','nette','netter','netste'),
((SELECT id FROM words WHERE word='vast' AND part_of_speech='adjective' LIMIT 1), 'vast','vaste','vaster','vastste'),
((SELECT id FROM words WHERE word='diep' AND part_of_speech='adjective' LIMIT 1), 'diep','diepe','dieper','diepste'),
((SELECT id FROM words WHERE word='typisch' AND part_of_speech='adjective' LIMIT 1), 'typisch','typische','typischer','typischste'),
((SELECT id FROM words WHERE word='verticaal' AND part_of_speech='adjective' LIMIT 1), 'verticaal','verticale','verticaler','verticalste'),
((SELECT id FROM words WHERE word='geel' AND part_of_speech='adjective' LIMIT 1), 'geel','gele','geler','geelste'),
((SELECT id FROM words WHERE word='goed' AND part_of_speech='adjective' LIMIT 1), 'goed','goede','beter','beste'),
((SELECT id FROM words WHERE word='lang' AND part_of_speech='adjective' LIMIT 1), 'lang','lange','langer','langste'),
((SELECT id FROM words WHERE word='geboren' AND part_of_speech='adjective' LIMIT 1), 'geboren','geboren',NULL,NULL),
((SELECT id FROM words WHERE word='gesloten' AND part_of_speech='adjective' LIMIT 1), 'gesloten','gesloten',NULL,NULL),
((SELECT id FROM words WHERE word='mogelijk' AND part_of_speech='adjective' LIMIT 1), 'mogelijk','mogelijke',NULL,NULL),
((SELECT id FROM words WHERE word='openbaar' AND part_of_speech='adjective' LIMIT 1), 'openbaar','openbare',NULL,NULL),
((SELECT id FROM words WHERE word='voorbehouden' AND part_of_speech='adjective' LIMIT 1), 'voorbehouden','voorbehouden',NULL,NULL),
((SELECT id FROM words WHERE word='juist' AND part_of_speech='adjective' LIMIT 1), 'juist','juiste',NULL,NULL),
((SELECT id FROM words WHERE word='waar' AND part_of_speech='adjective' LIMIT 1), 'waar','ware',NULL,NULL),
((SELECT id FROM words WHERE word='open' AND part_of_speech='adjective' LIMIT 1), 'open','open','opener','openste'),
((SELECT id FROM words WHERE word='deens' AND part_of_speech='adjective' LIMIT 1), 'deens','deense',NULL,NULL),
((SELECT id FROM words WHERE word='duits' AND part_of_speech='adjective' LIMIT 1), 'duits','duitse',NULL,NULL),
((SELECT id FROM words WHERE word='engels' AND part_of_speech='adjective' LIMIT 1), 'engels','engelse',NULL,NULL),
((SELECT id FROM words WHERE word='europees' AND part_of_speech='adjective' LIMIT 1), 'europees','europese',NULL,NULL),
((SELECT id FROM words WHERE word='frans' AND part_of_speech='adjective' LIMIT 1), 'frans','franse',NULL,NULL),
((SELECT id FROM words WHERE word='italiaans' AND part_of_speech='adjective' LIMIT 1), 'italiaans','italiaanse',NULL,NULL),
((SELECT id FROM words WHERE word='nederlands' AND part_of_speech='adjective' LIMIT 1), 'nederlands','nederlandse',NULL,NULL),
((SELECT id FROM words WHERE word='russisch' AND part_of_speech='adjective' LIMIT 1), 'russisch','russische',NULL,NULL),
((SELECT id FROM words WHERE word='akoestisch' AND part_of_speech='adjective' LIMIT 1), 'akoestisch','akoestische','akoestischer','akoestischste'),
((SELECT id FROM words WHERE word='anderstalig' AND part_of_speech='adjective' LIMIT 1), 'anderstalig','anderstalige','anderstaliger','anderstaligste'),
((SELECT id FROM words WHERE word='benodigd' AND part_of_speech='adjective' LIMIT 1), 'benodigd','benodigde',NULL,NULL),
((SELECT id FROM words WHERE word='bijbehorend' AND part_of_speech='adjective' LIMIT 1), 'bijbehorend','bijbehorende','bijbehorender','bijbehorendste'),
((SELECT id FROM words WHERE word='communicatief' AND part_of_speech='adjective' LIMIT 1), 'communicatief','communicatieve','communicatiever','communicatiefste'),
((SELECT id FROM words WHERE word='driedelig' AND part_of_speech='adjective' LIMIT 1), 'driedelig','driedelige','driedeliger','driedeligste'),
((SELECT id FROM words WHERE word='filmisch' AND part_of_speech='adjective' LIMIT 1), 'filmisch','filmische','filmischer','filmischste'),
((SELECT id FROM words WHERE word='functioneel' AND part_of_speech='adjective' LIMIT 1), 'functioneel','functionele','functioneler','functioneelste'),
((SELECT id FROM words WHERE word='grafisch' AND part_of_speech='adjective' LIMIT 1), 'grafisch','grafische','grafischer','grafischste'),
((SELECT id FROM words WHERE word='grammaticaal' AND part_of_speech='adjective' LIMIT 1), 'grammaticaal','grammaticale','grammaticaler','grammaticaalste'),
((SELECT id FROM words WHERE word='hoogopgeleid' AND part_of_speech='adjective' LIMIT 1), 'hoogopgeleid','hoogopgeleide','hoogopgeleider','hoogopgeleidste'),
((SELECT id FROM words WHERE word='ingescand' AND part_of_speech='adjective' LIMIT 1), 'ingescand','ingescand',NULL,NULL),
((SELECT id FROM words WHERE word='interrogatief' AND part_of_speech='adjective' LIMIT 1), 'interrogatief','interrogatieve','interrogatiever','interrogatiefste'),
((SELECT id FROM words WHERE word='lexicaal' AND part_of_speech='adjective' LIMIT 1), 'lexicaal','lexicale','lexicaler','lexicaalste'),
((SELECT id FROM words WHERE word='modern' AND part_of_speech='adjective' LIMIT 1), 'modern','moderne','moderner','modernste'),
((SELECT id FROM words WHERE word='nederlandstalig' AND part_of_speech='adjective' LIMIT 1), 'nederlandstalig','nederlandstalige','nederlandstaliger','nederlandstaligste'),
((SELECT id FROM words WHERE word='productief' AND part_of_speech='adjective' LIMIT 1), 'productief','productieve','productiever','productiefste'),
((SELECT id FROM words WHERE word='realistisch' AND part_of_speech='adjective' LIMIT 1), 'realistisch','realistische','realistischer','realistischste'),
((SELECT id FROM words WHERE word='receptief' AND part_of_speech='adjective' LIMIT 1), 'receptief','receptieve','receptiever','receptiefste'),
((SELECT id FROM words WHERE word='schriftelijk' AND part_of_speech='adjective' LIMIT 1), 'schriftelijk','schriftelijke','schriftelijker','schriftelijkste'),
((SELECT id FROM words WHERE word='relatief' AND part_of_speech='adjective' LIMIT 1), 'relatief','relatieve','relatiever','relatiefste'),
((SELECT id FROM words WHERE word='volgend' AND part_of_speech='adjective' LIMIT 1), 'volgend','volgende',NULL,NULL),
((SELECT id FROM words WHERE word='voorafgaand' AND part_of_speech='adjective' LIMIT 1), 'voorafgaand','voorafgaande',NULL,NULL),
((SELECT id FROM words WHERE word='verenigd' AND part_of_speech='adjective' LIMIT 1), 'verenigd','verenigde',NULL,NULL),
((SELECT id FROM words WHERE word='even' AND part_of_speech='adjective' LIMIT 1), 'even','even',NULL,NULL),
((SELECT id FROM words WHERE word='best' AND part_of_speech='adjective' LIMIT 1), 'best','beste',NULL,NULL)
ON CONFLICT (word_id) DO NOTHING;

-- Create verb forms for common Dutch verbs (explicit rows)
INSERT INTO verbs (
    infinitive,
    present_simple_1st_singular,
    present_simple_2nd_singular,
    present_simple_2nd_respectful,
    present_simple_3rd_singular,
    present_simple_plural,
    past_simple_singular,
    past_simple_plural,
    past_participle,
    perfect_auxiliary,
    separable_prefix,
    is_separable,
    is_irregular,
    is_strong_verb,
    is_modal,
    word_id
)
VALUES
('gelden', 'geld','geldt','geldt','geldt','gelden','gold','golden','gegolden','hebben', NULL,false,true,false,false,(SELECT id FROM words WHERE word='gelden' AND part_of_speech='verb' LIMIT 1)),
('houden', 'houd','houdt','houdt','houdt','houden','hield','hielden','gehouden','hebben', NULL,false,true,false,false,(SELECT id FROM words WHERE word='houden' AND part_of_speech='verb' LIMIT 1)),
('zijn',    'ben','bent','bent','is','zijn','was','waren','geweest','zijn',   NULL,false,true, true, false,(SELECT id FROM words WHERE word='zijn'    AND part_of_speech='verb' LIMIT 1)),
('hebben',  'heb','hebt','hebt','heeft','hebben','had','hadden','gehad','hebben',NULL,false,true, false,false,(SELECT id FROM words WHERE word='hebben'  AND part_of_speech='verb' LIMIT 1)),
('gaan',    'ga', 'gaat','gaat','gaat','gaan','ging','gingen','gegaan','zijn', NULL,false,true, true, false,(SELECT id FROM words WHERE word='gaan'    AND part_of_speech='verb' LIMIT 1)),
('komen',   'kom','komt','komt','komt','komen','kwam','kwamen','gekomen','zijn',NULL,false,true, true, false,(SELECT id FROM words WHERE word='komen'   AND part_of_speech='verb' LIMIT 1)),
('doen',    'doe','doet','doet','doet','doen','deed','deden','gedaan','hebben', NULL,false,true, true, false,(SELECT id FROM words WHERE word='doen'    AND part_of_speech='verb' LIMIT 1)),
('zien',    'zie','ziet','ziet','ziet','zien','zag','zagen','gezien','hebben',  NULL,false,true, true, false,(SELECT id FROM words WHERE word='zien'    AND part_of_speech='verb' LIMIT 1)),
('kunnen',  'kan','kunt','kunt','kan','kunnen','kon','konden','gekund','hebben', NULL,false,true, false,true, (SELECT id FROM words WHERE word='kunnen'  AND part_of_speech='verb' LIMIT 1)),
('willen',  'wil','wilt','wilt','wil','willen','wilde','wilden','gewild','hebben',NULL,false,true, false,true, (SELECT id FROM words WHERE word='willen'  AND part_of_speech='verb' LIMIT 1)),
('moeten',  'moet','moet','moet','moet','moeten','moest','moesten','gemoeten','hebben',NULL,false,true, false,true, (SELECT id FROM words WHERE word='moeten'  AND part_of_speech='verb' LIMIT 1)),
('mogen',   'mag','mag','mag','mag','mogen','mocht','mochten','gemogen','hebben',NULL,false,true, false,true, (SELECT id FROM words WHERE word='mogen'   AND part_of_speech='verb' LIMIT 1)),
('zeggen',  'zeg','zegt','zegt','zegt','zeggen','zei','zeiden','gezegd','hebben',NULL,false,true, false,false,(SELECT id FROM words WHERE word='zeggen'  AND part_of_speech='verb' LIMIT 1)),
('maken',   'maak','maakt','maakt','maakt','maken','maakte','maakten','gemaakt','hebben',NULL,false,false,false,false,(SELECT id FROM words WHERE word='maken'   AND part_of_speech='verb' LIMIT 1)),
('nemen',   'neem','neemt','neemt','neemt','nemen','nam','namen','genomen','hebben',NULL,false,true, true, false,(SELECT id FROM words WHERE word='nemen'   AND part_of_speech='verb' LIMIT 1)),
('geven',   'geef','geeft','geeft','geeft','geven','gaf','gaven','gegeven','hebben',NULL,false,true, true, false,(SELECT id FROM words WHERE word='geven'   AND part_of_speech='verb' LIMIT 1)),
('werken',  'werk','werkt','werkt','werkt','werken','werkte','werkten','gewerkt','hebben',NULL,false,false,false,false,(SELECT id FROM words WHERE word='werken'  AND part_of_speech='verb' LIMIT 1)),
('lezen',   'lees','leest','leest','leest','lezen','las','lazen','gelezen','hebben',NULL,false,true, true, false,(SELECT id FROM words WHERE word='lezen'   AND part_of_speech='verb' LIMIT 1)),
('schrijven','schrijf','schrijft','schrijft','schrijft','schrijven','schreef','schreven','geschreven','hebben',NULL,false,true, true, false,(SELECT id FROM words WHERE word='schrijven'AND part_of_speech='verb' LIMIT 1)),
('eten',    'eet','eet','eet','eet','eten','at','aten','gegeten','hebben', NULL,false,true, true, false,(SELECT id FROM words WHERE word='eten'    AND part_of_speech='verb' LIMIT 1)),
('drinken', 'drink','drinkt','drinkt','drinkt','drinken','dronk','dronken','gedronken','hebben',NULL,false,true, true, false,(SELECT id FROM words WHERE word='drinken' AND part_of_speech='verb' LIMIT 1)),
('slapen',  'slaap','slaapt','slaapt','slaapt','slapen','sliep','sliepen','geslapen','hebben',NULL,false,true, true, false,(SELECT id FROM words WHERE word='slapen'  AND part_of_speech='verb' LIMIT 1)),
('aanbieden','bied','biedt','biedt','biedt','bieden','bood','boden','aangeboden','hebben','aan', true, true,  true,  false,(SELECT id FROM words WHERE word='aanbieden'  AND part_of_speech='verb' LIMIT 1)),
('aangeven','geef','geeft','geeft','geeft','geven','gaf','gaven','aangegeven','hebben','aan', true, true,  true,  false,(SELECT id FROM words WHERE word='aangeven'   AND part_of_speech='verb' LIMIT 1)),
('afspreken','spreek','spreekt','spreekt','spreekt','spreken','sprak','spraken','afgesproken','hebben','af', true, true,  true,  false,(SELECT id FROM words WHERE word='afspreken'  AND part_of_speech='verb' LIMIT 1)),
('inleveren','lever','levert','levert','levert','leveren','leverde','leverden','ingeleverd','hebben','in', true, false, false, false,(SELECT id FROM words WHERE word='inleveren'  AND part_of_speech='verb' LIMIT 1)),
('inschrijven','schrijf','schrijft','schrijft','schrijft','schrijven','schreef','schreven','ingeschreven','hebben','in', true, true,  true,  false,(SELECT id FROM words WHERE word='inschrijven' AND part_of_speech='verb' LIMIT 1)),
('nazeggen','zeg','zegt','zegt','zegt','zeggen','zei','zeiden','nagezegd','hebben','na', true, true,  false, false,(SELECT id FROM words WHERE word='nazeggen'   AND part_of_speech='verb' LIMIT 1)),
('opbouwen','bouw','bouwt','bouwt','bouwt','bouwen','bouwde','bouwden','opgebouwd','hebben','op', true, false, false, false,(SELECT id FROM words WHERE word='opbouwen'   AND part_of_speech='verb' LIMIT 1)),
('uitdiepen','diep','diept','diept','diept','diepen','diepte','diepten','uitgediept','hebben','uit', true, false, false, false,(SELECT id FROM words WHERE word='uitdiepen'  AND part_of_speech='verb' LIMIT 1)),
('uiten','uit','uit','uit','uit','uiten','uitte','uitten','geuit','hebben',NULL, false, false, false, false,(SELECT id FROM words WHERE word='uiten'      AND part_of_speech='verb' LIMIT 1)),
('uitvoeren','voer','voert','voert','voert','voeren','voerde','voerden','uitgevoerd','hebben','uit', true, false, false, false,(SELECT id FROM words WHERE word='uitvoeren'  AND part_of_speech='verb' LIMIT 1)),
('voorkomen','kom','komt','komt','komt','komen','kwam','kwamen','voorgekomen','zijn','voor', true, true,  true,  false,(SELECT id FROM words WHERE word='voorkomen'  AND part_of_speech='verb' LIMIT 1)),
('voorstellen','stel','stelt','stelt','stelt','stellen','stelde','stelden','voorgesteld','hebben','voor', true, false, false, false,(SELECT id FROM words WHERE word='voorstellen'AND part_of_speech='verb' LIMIT 1)),
('antwoorden','antwoord','antwoordt','antwoordt','antwoordt','antwoorden','antwoordde','antwoordden','geantwoord','hebben',NULL,false,false,false,false,(SELECT id FROM words WHERE word='antwoorden' AND part_of_speech='verb' LIMIT 1)),
('begeleiden','begeleid','begeleidt','begeleidt','begeleidt','begeleiden','begeleidde','begeleidden','begeleid','hebben',NULL,false,false,false,false,(SELECT id FROM words WHERE word='begeleiden' AND part_of_speech='verb' LIMIT 1)),
('behandelen','behandel','behandelt','behandelt','behandelt','behandelen','behandelde','behandelden','behandeld','hebben',NULL,false,false,false,false,(SELECT id FROM words WHERE word='behandelen' AND part_of_speech='verb' LIMIT 1)),
('bevatten','bevat','bevat','bevat','bevat','bevatten','bevatte','bevatten','bevat','hebben',NULL,false,false,false,false,(SELECT id FROM words WHERE word='bevatten'   AND part_of_speech='verb' LIMIT 1)),
('bellen','bel','belt','belt','belt','bellen','belde','belden','gebeld','hebben',NULL,false,false,false,false,(SELECT id FROM words WHERE word='bellen'     AND part_of_speech='verb' LIMIT 1)),
('duren','duur','duurt','duurt','duurt','duren','duurde','duurden','geduurd','hebben',NULL,false,false,false,false,(SELECT id FROM words WHERE word='duren'     AND part_of_speech='verb' LIMIT 1)),
('gebruiken','gebruik','gebruikt','gebruikt','gebruikt','gebruiken','gebruikte','gebruikten','gebruikt','hebben',NULL,false,false,false,false,(SELECT id FROM words WHERE word='gebruiken'  AND part_of_speech='verb' LIMIT 1)),
('illustreren','illustreer','illustreert','illustreert','illustreert','illustreren','illustreerde','illustreerden','geïllustreerd','hebben',NULL,false,false,false,false,(SELECT id FROM words WHERE word='illustreren'AND part_of_speech='verb' LIMIT 1)),
('kopen','koop','koopt','koopt','koopt','kopen','kocht','kochten','gekocht','hebben',NULL,false,true, true, false,(SELECT id FROM words WHERE word='kopen'     AND part_of_speech='verb' LIMIT 1)),
('kampen','kamp','kampt','kampt','kampt','kampen','kampte','kampten','gekampt','hebben',NULL,false,false,false,false,(SELECT id FROM words WHERE word='kampen'    AND part_of_speech='verb' LIMIT 1)),
('kijken','kijk','kijkt','kijkt','kijkt','kijken','keek','keken','gekeken','hebben',NULL,false,true, true, false,(SELECT id FROM words WHERE word='kijken'    AND part_of_speech='verb' LIMIT 1)),
('kiezen','kies','kiest','kiest','kiest','kiezen','koos','kozen','gekozen','hebben',NULL,false,true, true, false,(SELECT id FROM words WHERE word='kiezen'    AND part_of_speech='verb' LIMIT 1)),
('krijgen','krijg','krijgt','krijgt','krijgt','krijgen','kreeg','kregen','gekregen','hebben',NULL,false,true, true, false,(SELECT id FROM words WHERE word='krijgen'   AND part_of_speech='verb' LIMIT 1)),
('kruisen','kruis','kruist','kruist','kruist','kruisen','kruiste','kruisten','gekruist','hebben',NULL,false,false,false,false,(SELECT id FROM words WHERE word='kruisen'   AND part_of_speech='verb' LIMIT 1)),
('landen','land','landt','landt','landt','landen','landde','landden','geland','zijn',NULL,false,false,false,false,(SELECT id FROM words WHERE word='landen'    AND part_of_speech='verb' LIMIT 1)),
('leiden','leid','leidt','leidt','leidt','leiden','leidde','leidden','geleid','hebben',NULL,false,false,false,false,(SELECT id FROM words WHERE word='leiden'    AND part_of_speech='verb' LIMIT 1)),
('leren','leer','leert','leert','leert','leren','leerde','leerden','geleerd','hebben',NULL,false,false,false,false,(SELECT id FROM words WHERE word='leren'     AND part_of_speech='verb' LIMIT 1)),
('leveren','lever','levert','levert','levert','leveren','leverde','leverden','geleverd','hebben',NULL,false,false,false,false,(SELECT id FROM words WHERE word='leveren'   AND part_of_speech='verb' LIMIT 1)),
('lopen','loop','loopt','loopt','loopt','lopen','liep','liepen','gelopen','hebben',NULL,false,true, true, false,(SELECT id FROM words WHERE word='lopen'     AND part_of_speech='verb' LIMIT 1)),
('mennen','men','ment','ment','ment','mennen','mende','menden','gemend','hebben',NULL,false,false,false,false,(SELECT id FROM words WHERE word='mennen'     AND part_of_speech='verb' LIMIT 1)),
('oefenen','oefen','oefent','oefent','oefent','oefenen','oefende','oefenden','geoefend','hebben',NULL,false,false,false,false,(SELECT id FROM words WHERE word='oefenen'   AND part_of_speech='verb' LIMIT 1)),
('ontvangen','ontvang','ontvangt','ontvangt','ontvangt','ontvangen','ontving','ontvingen','ontvangen','hebben',NULL,false,true, true, false,(SELECT id FROM words WHERE word='ontvangen'  AND part_of_speech='verb' LIMIT 1)),
('ontwerpen','ontwerp','ontwerpt','ontwerpt','ontwerpt','ontwerpen','ontwierp','ontwierpen','ontworpen','hebben',NULL,false,true, true, false,(SELECT id FROM words WHERE word='ontwerpen'  AND part_of_speech='verb' LIMIT 1)),
('plaatsen','plaats','plaatst','plaatst','plaatst','plaatsen','plaatste','plaatsten','geplaatst','hebben',NULL,false,false,false,false,(SELECT id FROM words WHERE word='plaatsen'  AND part_of_speech='verb' LIMIT 1)),
('spreken','spreek','spreekt','spreekt','spreekt','spreken','sprak','spraken','gesproken','hebben',NULL,false,true, true, false,(SELECT id FROM words WHERE word='spreken'   AND part_of_speech='verb' LIMIT 1)),
('sluiten','sluit','sluit','sluit','sluit','sluiten','sloot','sloten','gesloten','hebben',NULL,false,true, true, false,(SELECT id FROM words WHERE word='sluiten'   AND part_of_speech='verb' LIMIT 1)),
('spelen','speel','speelt','speelt','speelt','spelen','speelde','speelden','gespeeld','hebben',NULL,false,false,false,false,(SELECT id FROM words WHERE word='spelen'    AND part_of_speech='verb' LIMIT 1)),
('staan','sta','staat','staat','staat','staan','stond','stonden','gestaan','hebben',NULL,false,true, true, false,(SELECT id FROM words WHERE word='staan'     AND part_of_speech='verb' LIMIT 1)),
('stellen','stel','stelt','stelt','stelt','stellen','stelde','stelden','gesteld','hebben',NULL,false,false,false,false,(SELECT id FROM words WHERE word='stellen'   AND part_of_speech='verb' LIMIT 1)),
('sturen','stuur','stuurt','stuurt','stuurt','sturen','stuurde','stuurden','gestuurd','hebben',NULL,false,false,false,false,(SELECT id FROM words WHERE word='sturen'    AND part_of_speech='verb' LIMIT 1)),
('studeren','studeer','studeert','studeert','studeert','studeren','studeerde','studeerden','gestudeerd','hebben',NULL,false,false,false,false,(SELECT id FROM words WHERE word='studeren'  AND part_of_speech='verb' LIMIT 1)),
('toetsen','toets','toetst','toetst','toetst','toetsen','toetste','toetsten','getoetst','hebben',NULL,false,false,false,false,(SELECT id FROM words WHERE word='toetsen'   AND part_of_speech='verb' LIMIT 1)),
('vinden','vind','vindt','vindt','vindt','vinden','vond','vonden','gevonden','hebben',NULL,false,true, true, false,(SELECT id FROM words WHERE word='vinden'    AND part_of_speech='verb' LIMIT 1)),
('voelen','voel','voelt','voelt','voelt','voelen','voelde','voelden','gevoeld','hebben',NULL,false,false,false,false,(SELECT id FROM words WHERE word='voelen'    AND part_of_speech='verb' LIMIT 1)),
('bestaan','bestaan','bestaat','bestaat','bestaat','bestaan','bestond','bestonden','bestaan','hebben',NULL,false,true, true, false,(SELECT id FROM words WHERE word='bestaan'   AND part_of_speech='verb' LIMIT 1)),
('blijven','blijf','blijft','blijft','blijft','blijven','bleef','bleven','gebleven','zijn',NULL,false,true, true, false,(SELECT id FROM words WHERE word='blijven'   AND part_of_speech='verb' LIMIT 1)),
('delen','deel','deelt','deelt','deelt','delen','deelde','deelden','gedeeld','hebben',NULL,false,false,false,false,(SELECT id FROM words WHERE word='delen' AND part_of_speech='verb' LIMIT 1))
ON CONFLICT (word_id) DO NOTHING;

-- Insert sample users for testing
INSERT INTO app_users (username, email, level_id) VALUES 
('demo_user', 'demo@example.com', (SELECT id FROM levels WHERE level = 'A2')),
('test_user', 'test@example.com', (SELECT id FROM levels WHERE level = 'A1'))
ON CONFLICT (username) DO NOTHING;

-- Note: Level target counts can be added later if needed
-- Currently using actual word counts from the database

-- 01_seed.sql
-- Complete seed data for Dutch Language Learning API
-- Auto-generated from dutch_words.json and dutch-learning-backup.json
-- This file is automatically executed after schema creation

-- Insert CEFR levels with target counts
INSERT INTO levels (level, count) VALUES 
('A1', 500), ('A2', 1000), ('B1', 1500), ('B2', 2000), ('C1', 3000), ('C2', 5000)
ON CONFLICT (level) DO UPDATE SET count = EXCLUDED.count;

-- Insert categories (automatically extracted from easy-vocabulary.csv)
-- To regenerate categories.csv, run: python db/initdb/extract_categories.py
CREATE TEMP TABLE t_categories (
    category TEXT,
    count INTEGER
);

COPY t_categories (category, count)
FROM '/docker-entrypoint-initdb.d/categories.csv'
DELIMITER ','
CSV HEADER;

INSERT INTO categories (category)
SELECT DISTINCT category FROM t_categories
ON CONFLICT (category) DO NOTHING;

-- Insert all vocabulary words from CSV
-- Create a temporary table to load CSV data
CREATE TEMP TABLE t_vocab_words (
    number INTEGER,
    dutch TEXT,
    english TEXT,
    part_of_speech TEXT,
    category TEXT,
    example_dutch TEXT,
    example_english TEXT
);

-- Load CSV data into temporary table
COPY t_vocab_words(number, dutch, english, part_of_speech, category, example_dutch, example_english)
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
    FROM t_vocab_words
    ON CONFLICT (word, part_of_speech) DO NOTHING;

    -- Also insert category associations
    INSERT INTO category_words (category_id, word_id)
    SELECT DISTINCT c.id, w.id
    FROM t_vocab_words tv
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
DROP TABLE t_vocab_words;

CREATE TEMP TABLE t_nouns AS
SELECT id, word
FROM words
WHERE part_of_speech = 'noun';

-- Insert noun forms for Dutch nouns from easy-vocabulary.csv
-- Note: Grammatical forms (articles, diminutives, plurals) need to be filled in manually
INSERT INTO nouns
(word_id, indefinite_article, diminutive, plural)
VALUES
((SELECT id FROM t_nouns WHERE word='aardappel' LIMIT 1), 'de', 'aardappeltje', 'aardappels'),
((SELECT id FROM t_nouns WHERE word='actie' LIMIT 1), 'de', 'actietje', 'acties'),
((SELECT id FROM t_nouns WHERE word='activiteit' LIMIT 1), 'de', 'activiteitje', 'activiteiten'),
((SELECT id FROM t_nouns WHERE word='adres' LIMIT 1), 'het', 'adresje', 'adressen'),
((SELECT id FROM t_nouns WHERE word='advies' LIMIT 1), 'het', 'adviestje', 'adviezen'),
((SELECT id FROM t_nouns WHERE word='afbeelding' LIMIT 1), 'de', 'afbeeldingetje', 'afbeeldingen'),
((SELECT id FROM t_nouns WHERE word='afkomst' LIMIT 1), 'de', 'afkomstje', 'afkomsten'),
((SELECT id FROM t_nouns WHERE word='afwasmachine' LIMIT 1), 'de', 'afwasmachinetje', 'afwasmachines'),
((SELECT id FROM t_nouns WHERE word='agent' LIMIT 1), 'de', 'agentje', 'agenten'),
((SELECT id FROM t_nouns WHERE word='antwoord' LIMIT 1), 'het', 'antwoordje', 'antwoorden'),
((SELECT id FROM t_nouns WHERE word='argument' LIMIT 1), 'het', 'argumentje', 'argumenten'),
((SELECT id FROM t_nouns WHERE word='arm' LIMIT 1), 'de', 'armpje', 'armen'),
((SELECT id FROM t_nouns WHERE word='artikel' LIMIT 1), 'het', 'artikeltje', 'artikelen'),
((SELECT id FROM t_nouns WHERE word='aspect' LIMIT 1), 'het', 'aspectje', 'aspecten'),
((SELECT id FROM t_nouns WHERE word='auteur' LIMIT 1), 'de', 'auteurtje', 'auteurs'),
((SELECT id FROM t_nouns WHERE word='avondeten' LIMIT 1), 'het', 'avondetentje', 'avondeten'),
((SELECT id FROM t_nouns WHERE word='baan' LIMIT 1), 'de', 'baantje', 'banen'),
((SELECT id FROM t_nouns WHERE word='baas' LIMIT 1), 'de', 'baasje', 'bazen'),
((SELECT id FROM t_nouns WHERE word='baby' LIMIT 1), 'de', 'babytje', 'baby''s'),
((SELECT id FROM t_nouns WHERE word='bank' LIMIT 1), 'de', 'bankje', 'banken'),
((SELECT id FROM t_nouns WHERE word='basis' LIMIT 1), 'de', 'basisje', 'bases'),
((SELECT id FROM t_nouns WHERE word='bed' LIMIT 1), 'het', 'bedje', 'bedden'),
((SELECT id FROM t_nouns WHERE word='bedrijf' LIMIT 1), 'het', 'bedrijfje', 'bedrijven'),
((SELECT id FROM t_nouns WHERE word='begin' LIMIT 1), 'het', 'beginnetje', 'begins'),
((SELECT id FROM t_nouns WHERE word='beroep' LIMIT 1), 'het', 'beroepje', 'beroepen'),
((SELECT id FROM t_nouns WHERE word='bier' LIMIT 1), 'het', 'biertje', 'bieren'),
((SELECT id FROM t_nouns WHERE word='bijbaantje' LIMIT 1), 'het', 'bijbaantje', 'bijbaantjes'),
((SELECT id FROM t_nouns WHERE word='bloed' LIMIT 1), 'het', 'bloedje', 'bloed'),
((SELECT id FROM t_nouns WHERE word='bodem' LIMIT 1), 'de', 'bodempje', 'bodems'),
((SELECT id FROM t_nouns WHERE word='boek' LIMIT 1), 'het', 'boekje', 'boeken'),
((SELECT id FROM t_nouns WHERE word='boodschap' LIMIT 1), 'de', 'boodschapje', 'boodschappen'),
((SELECT id FROM t_nouns WHERE word='boot' LIMIT 1), 'de', 'bootje', 'boten'),
((SELECT id FROM t_nouns WHERE word='broer' LIMIT 1), 'de', 'broertje', 'broers'),
((SELECT id FROM t_nouns WHERE word='brood' LIMIT 1), 'het', 'broodje', 'broden'),
((SELECT id FROM t_nouns WHERE word='bus' LIMIT 1), 'de', 'busje', 'bussen'),
((SELECT id FROM t_nouns WHERE word='cafÃ©' LIMIT 1), 'het', 'cafeetje', 'cafÃ©s'),
((SELECT id FROM t_nouns WHERE word='categorie' LIMIT 1), 'de', 'categorietje', 'categorieÃ«n'),
((SELECT id FROM t_nouns WHERE word='centrum' LIMIT 1), 'het', 'centrumpje', 'centrums'),
((SELECT id FROM t_nouns WHERE word='collega' LIMIT 1), 'de', 'collegatje', 'collega''s'),
((SELECT id FROM t_nouns WHERE word='combinatie' LIMIT 1), 'de', 'combinatietje', 'combinaties'),
((SELECT id FROM t_nouns WHERE word='communicatie' LIMIT 1), 'de', 'communicatietje', 'communicaties'),
((SELECT id FROM t_nouns WHERE word='computer' LIMIT 1), 'de', 'computertje', 'computers'),
((SELECT id FROM t_nouns WHERE word='conclusie' LIMIT 1), 'de', 'conclusietje', 'conclusies'),
((SELECT id FROM t_nouns WHERE word='consequentie' LIMIT 1), 'de', 'consequentietje', 'consequenties'),
((SELECT id FROM t_nouns WHERE word='contact' LIMIT 1), 'het', 'contactje', 'contacten'),
((SELECT id FROM t_nouns WHERE word='crisis' LIMIT 1), 'de', 'crisisje', 'crises'),
((SELECT id FROM t_nouns WHERE word='cultuur' LIMIT 1), 'de', 'cultuurtje', 'culturen'),
((SELECT id FROM t_nouns WHERE word='dag' LIMIT 1), 'de', 'dagje', 'dagen'),
((SELECT id FROM t_nouns WHERE word='detail' LIMIT 1), 'het', 'detailtje', 'details'),
((SELECT id FROM t_nouns WHERE word='deur' LIMIT 1), 'de', 'deurtje', 'deuren'),
((SELECT id FROM t_nouns WHERE word='ding' LIMIT 1), 'het', 'dingetje', 'dingen'),
((SELECT id FROM t_nouns WHERE word='directeur' LIMIT 1), 'de', 'directeurtje', 'directeuren'),
((SELECT id FROM t_nouns WHERE word='discussie' LIMIT 1), 'de', 'discussietje', 'discussies'),
((SELECT id FROM t_nouns WHERE word='dochter' LIMIT 1), 'de', 'dochtertje', 'dochters'),
((SELECT id FROM t_nouns WHERE word='dokter' LIMIT 1), 'de', 'doktertje', 'dokters'),
((SELECT id FROM t_nouns WHERE word='dood' LIMIT 1), 'de', 'doodje', 'doden'),
((SELECT id FROM t_nouns WHERE word='dorst' LIMIT 1), 'de', 'dorstje', 'dorst'),
((SELECT id FROM t_nouns WHERE word='drinken' LIMIT 1), 'het', 'drinkje', 'drankjes'),
((SELECT id FROM t_nouns WHERE word='droom' LIMIT 1), 'de', 'droompje', 'dromen'),
((SELECT id FROM t_nouns WHERE word='economie' LIMIT 1), 'de', 'economietje', 'economieÃ«n'),
((SELECT id FROM t_nouns WHERE word='effect' LIMIT 1), 'het', 'effectje', 'effecten'),
((SELECT id FROM t_nouns WHERE word='ei' LIMIT 1), 'het', 'eitje', 'eieren'),
((SELECT id FROM t_nouns WHERE word='eiland' LIMIT 1), 'het', 'eilandje', 'eilanden'),
((SELECT id FROM t_nouns WHERE word='eind' LIMIT 1), 'het', 'eindje', 'einden'),
((SELECT id FROM t_nouns WHERE word='emotie' LIMIT 1), 'de', 'emotietje', 'emoties'),
((SELECT id FROM t_nouns WHERE word='energie' LIMIT 1), 'de', 'energietje', 'energieÃ«n'),
((SELECT id FROM t_nouns WHERE word='eten' LIMIT 1), 'het', 'etentje', 'etens'),
((SELECT id FROM t_nouns WHERE word='examen' LIMIT 1), 'het', 'examentje', 'examens'),
((SELECT id FROM t_nouns WHERE word='experiment' LIMIT 1), 'het', 'experimentje', 'experimenten'),
((SELECT id FROM t_nouns WHERE word='fabriek' LIMIT 1), 'de', 'fabriekje', 'fabrieken'),
((SELECT id FROM t_nouns WHERE word='factor' LIMIT 1), 'de', 'factortje', 'factoren'),
((SELECT id FROM t_nouns WHERE word='familie' LIMIT 1), 'de', 'familietje', 'families'),
((SELECT id FROM t_nouns WHERE word='fase' LIMIT 1), 'de', 'fasetje', 'fases'),
((SELECT id FROM t_nouns WHERE word='feit' LIMIT 1), 'het', 'feitje', 'feiten'),
((SELECT id FROM t_nouns WHERE word='figuur' LIMIT 1), 'de', 'figuurtje', 'figuren'),
((SELECT id FROM t_nouns WHERE word='film' LIMIT 1), 'de', 'filmpje', 'films'),
((SELECT id FROM t_nouns WHERE word='foto' LIMIT 1), 'de', 'fotootje', 'foto''s'),
((SELECT id FROM t_nouns WHERE word='fruit' LIMIT 1), 'het', 'fruitje', 'fruit'),
((SELECT id FROM t_nouns WHERE word='functie' LIMIT 1), 'de', 'functietje', 'functies'),
((SELECT id FROM t_nouns WHERE word='gast' LIMIT 1), 'de', 'gastje', 'gasten'),
((SELECT id FROM t_nouns WHERE word='geluk' LIMIT 1), 'het', 'gelukje', 'geluk'),
((SELECT id FROM t_nouns WHERE word='generatie' LIMIT 1), 'de', 'generatietje', 'generaties'),
((SELECT id FROM t_nouns WHERE word='gerecht' LIMIT 1), 'het', 'gerechtje', 'gerechten'),
((SELECT id FROM t_nouns WHERE word='getal' LIMIT 1), 'het', 'getalletje', 'getallen'),
((SELECT id FROM t_nouns WHERE word='gevoel' LIMIT 1), 'het', 'gevoeltje', 'gevoelens'),
((SELECT id FROM t_nouns WHERE word='glas' LIMIT 1), 'het', 'glaasje', 'glazen'),
((SELECT id FROM t_nouns WHERE word='goed' LIMIT 1), 'het', 'goedje', 'goederen'),
((SELECT id FROM t_nouns WHERE word='gras' LIMIT 1), 'het', 'grasje', 'grassen'),
((SELECT id FROM t_nouns WHERE word='groep' LIMIT 1), 'de', 'groepje', 'groepen'),
((SELECT id FROM t_nouns WHERE word='haar' LIMIT 1), 'het', 'haartje', 'haren'),
((SELECT id FROM t_nouns WHERE word='hand' LIMIT 1), 'de', 'handje', 'handen'),
((SELECT id FROM t_nouns WHERE word='hart' LIMIT 1), 'het', 'hartje', 'harten'),
((SELECT id FROM t_nouns WHERE word='helft' LIMIT 1), 'de', 'helftje', 'helften'),
((SELECT id FROM t_nouns WHERE word='herfst' LIMIT 1), 'de', 'herfstje', 'herfsten'),
((SELECT id FROM t_nouns WHERE word='hoed' LIMIT 1), 'de', 'hoedje', 'hoeden'),
((SELECT id FROM t_nouns WHERE word='holland' LIMIT 1), 'het', 'hollandje', 'holland'),
((SELECT id FROM t_nouns WHERE word='honger' LIMIT 1), 'de', 'hongertje', 'honger'),
((SELECT id FROM t_nouns WHERE word='hoop' LIMIT 1), 'de', 'hoopje', 'hopen'),
((SELECT id FROM t_nouns WHERE word='hotel' LIMIT 1), 'het', 'hoteltje', 'hotels'),
((SELECT id FROM t_nouns WHERE word='huis' LIMIT 1), 'het', 'huisje', 'huizen'),
((SELECT id FROM t_nouns WHERE word='hulp' LIMIT 1), 'de', 'hulpje', 'hulp'),
((SELECT id FROM t_nouns WHERE word='hut' LIMIT 1), 'de', 'hutje', 'hutten'),
((SELECT id FROM t_nouns WHERE word='idee' LIMIT 1), 'het', 'ideetje', 'ideeÃ«n'),
((SELECT id FROM t_nouns WHERE word='individu' LIMIT 1), 'het', 'individutje', 'individuen'),
((SELECT id FROM t_nouns WHERE word='informatie' LIMIT 1), 'de', 'informatietje', 'informatie'),
((SELECT id FROM t_nouns WHERE word='initiatief' LIMIT 1), 'het', 'initiatiefje', 'initiatieven'),
((SELECT id FROM t_nouns WHERE word='instrument' LIMIT 1), 'het', 'instrumentje', 'instrumenten'),
((SELECT id FROM t_nouns WHERE word='invloed' LIMIT 1), 'de', 'invloedje', 'invloeden'),
((SELECT id FROM t_nouns WHERE word='jaar' LIMIT 1), 'het', 'jaartje', 'jaren'),
((SELECT id FROM t_nouns WHERE word='jongeman' LIMIT 1), 'de', 'jongemannetje', 'jongemannen'),
((SELECT id FROM t_nouns WHERE word='juni' LIMIT 1), 'de', 'junitje', 'juni'),
((SELECT id FROM t_nouns WHERE word='kaas' LIMIT 1), 'de', 'kaasje', 'kazen'),
((SELECT id FROM t_nouns WHERE word='kamp' LIMIT 1), 'het', 'kampje', 'kampen'),
((SELECT id FROM t_nouns WHERE word='karakter' LIMIT 1), 'het', 'karaktertje', 'karakters'),
((SELECT id FROM t_nouns WHERE word='kat' LIMIT 1), 'de', 'katje', 'katten'),
((SELECT id FROM t_nouns WHERE word='keer' LIMIT 1), 'de', 'keertje', 'keren'),
((SELECT id FROM t_nouns WHERE word='kennis' LIMIT 1), 'de', 'kennisje', 'kennis'),
((SELECT id FROM t_nouns WHERE word='kilometer' LIMIT 1), 'de', 'kilometertje', 'kilometers'),
((SELECT id FROM t_nouns WHERE word='kind' LIMIT 1), 'het', 'kindje', 'kinderen'),
((SELECT id FROM t_nouns WHERE word='klant' LIMIT 1), 'de', 'klantje', 'klanten'),
((SELECT id FROM t_nouns WHERE word='klas' LIMIT 1), 'de', 'klasje', 'klassen'),
((SELECT id FROM t_nouns WHERE word='kleur' LIMIT 1), 'de', 'kleurtje', 'kleuren'),
((SELECT id FROM t_nouns WHERE word='knie' LIMIT 1), 'de', 'knietje', 'knieÃ«n'),
((SELECT id FROM t_nouns WHERE word='koffie' LIMIT 1), 'de', 'koffietje', 'koffie'),
((SELECT id FROM t_nouns WHERE word='koning' LIMIT 1), 'de', 'koninkje', 'koningen'),
((SELECT id FROM t_nouns WHERE word='kosten' LIMIT 1), 'de', 'kostentje', 'kosten'),
((SELECT id FROM t_nouns WHERE word='kruis' LIMIT 1), 'het', 'kruisje', 'kruisen'),
((SELECT id FROM t_nouns WHERE word='kust' LIMIT 1), 'de', 'kustje', 'kusten'),
((SELECT id FROM t_nouns WHERE word='kwaliteit' LIMIT 1), 'de', 'kwaliteitje', 'kwaliteiten'),
((SELECT id FROM t_nouns WHERE word='landschap' LIMIT 1), 'het', 'landschapje', 'landschappen'),
((SELECT id FROM t_nouns WHERE word='leider' LIMIT 1), 'de', 'leidertje', 'leiders'),
((SELECT id FROM t_nouns WHERE word='leiding' LIMIT 1), 'de', 'leidingetje', 'leidingen'),
((SELECT id FROM t_nouns WHERE word='lente' LIMIT 1), 'de', 'lentetje', 'lentes'),
((SELECT id FROM t_nouns WHERE word='leren' LIMIT 1), 'het', 'leertje', 'leren'),
((SELECT id FROM t_nouns WHERE word='leven' LIMIT 1), 'het', 'leventje', 'levens'),
((SELECT id FROM t_nouns WHERE word='licht' LIMIT 1), 'het', 'lichtje', 'lichten'),
((SELECT id FROM t_nouns WHERE word='liefde' LIMIT 1), 'de', 'liefdetje', 'liefdes'),
((SELECT id FROM t_nouns WHERE word='lijst' LIMIT 1), 'de', 'lijstje', 'lijsten'),
((SELECT id FROM t_nouns WHERE word='lip' LIMIT 1), 'de', 'lipje', 'lippen'),
((SELECT id FROM t_nouns WHERE word='literatuur' LIMIT 1), 'de', 'literatuurtje', 'literatuur'),
((SELECT id FROM t_nouns WHERE word='luitenant' LIMIT 1), 'de', 'luitenantje', 'luitenants'),
((SELECT id FROM t_nouns WHERE word='maaltijd' LIMIT 1), 'de', 'maaltijdje', 'maaltijden'),
((SELECT id FROM t_nouns WHERE word='maan' LIMIT 1), 'de', 'maantje', 'manen'),
((SELECT id FROM t_nouns WHERE word='maand' LIMIT 1), 'de', 'maandje', 'maanden'),
((SELECT id FROM t_nouns WHERE word='machine' LIMIT 1), 'de', 'machinetje', 'machines'),
((SELECT id FROM t_nouns WHERE word='mama' LIMIT 1), 'de', 'mamaatje', 'mama''s'),
((SELECT id FROM t_nouns WHERE word='man' LIMIT 1), 'de', 'mannetje', 'mannen'),
((SELECT id FROM t_nouns WHERE word='markt' LIMIT 1), 'de', 'marktje', 'markten'),
((SELECT id FROM t_nouns WHERE word='materiaal' LIMIT 1), 'het', 'materiaaltje', 'materialen'),
((SELECT id FROM t_nouns WHERE word='meer' LIMIT 1), 'het', 'meertje', 'meren'),
((SELECT id FROM t_nouns WHERE word='meester' LIMIT 1), 'de', 'meestertje', 'meesters'),
((SELECT id FROM t_nouns WHERE word='meter' LIMIT 1), 'de', 'metertje', 'meters'),
((SELECT id FROM t_nouns WHERE word='methode' LIMIT 1), 'de', 'methodetje', 'methodes'),
((SELECT id FROM t_nouns WHERE word='minister' LIMIT 1), 'de', 'ministertje', 'ministers'),
((SELECT id FROM t_nouns WHERE word='minuut' LIMIT 1), 'de', 'minuutje', 'minuten'),
((SELECT id FROM t_nouns WHERE word='moeder' LIMIT 1), 'de', 'moedertje', 'moeders'),
((SELECT id FROM t_nouns WHERE word='moment' LIMIT 1), 'het', 'momentje', 'momenten'),
((SELECT id FROM t_nouns WHERE word='mond' LIMIT 1), 'de', 'mondje', 'monden'),
((SELECT id FROM t_nouns WHERE word='motief' LIMIT 1), 'het', 'motiefje', 'motieven'),
((SELECT id FROM t_nouns WHERE word='museum' LIMIT 1), 'het', 'museumpje', 'museums'),
((SELECT id FROM t_nouns WHERE word='muziek' LIMIT 1), 'de', 'muziekje', 'muziek'),
((SELECT id FROM t_nouns WHERE word='naam' LIMIT 1), 'de', 'naampje', 'namen'),
((SELECT id FROM t_nouns WHERE word='nacht' LIMIT 1), 'de', 'nachtje', 'nachten'),
((SELECT id FROM t_nouns WHERE word='natuur' LIMIT 1), 'de', 'natuurtje', 'natuur'),
((SELECT id FROM t_nouns WHERE word='neef' LIMIT 1), 'de', 'neefje', 'neven'),
((SELECT id FROM t_nouns WHERE word='nek' LIMIT 1), 'de', 'nekje', 'nekken'),
((SELECT id FROM t_nouns WHERE word='neus' LIMIT 1), 'de', 'neusje', 'neuzen'),
((SELECT id FROM t_nouns WHERE word='nicht' LIMIT 1), 'de', 'nichtje', 'nichten'),
((SELECT id FROM t_nouns WHERE word='noorden' LIMIT 1), 'het', 'noordentje', 'noorden'),
((SELECT id FROM t_nouns WHERE word='nummer' LIMIT 1), 'het', 'nummertje', 'nummers'),
((SELECT id FROM t_nouns WHERE word='object' LIMIT 1), 'het', 'objectje', 'objecten'),
((SELECT id FROM t_nouns WHERE word='officier' LIMIT 1), 'de', 'officiertje', 'officieren'),
((SELECT id FROM t_nouns WHERE word='oktober' LIMIT 1), 'de', 'oktobertje', 'oktobers'),
((SELECT id FROM t_nouns WHERE word='olie' LIMIT 1), 'de', 'olietje', 'oliÃ«n'),
((SELECT id FROM t_nouns WHERE word='oma' LIMIT 1), 'de', 'omaatje', 'oma''s'),
((SELECT id FROM t_nouns WHERE word='oom' LIMIT 1), 'de', 'oompje', 'ooms'),
((SELECT id FROM t_nouns WHERE word='oor' LIMIT 1), 'het', 'oortje', 'oren'),
((SELECT id FROM t_nouns WHERE word='opa' LIMIT 1), 'de', 'opaatje', 'opa''s'),
((SELECT id FROM t_nouns WHERE word='operatie' LIMIT 1), 'de', 'operatietje', 'operaties'),
((SELECT id FROM t_nouns WHERE word='orgaan' LIMIT 1), 'het', 'orgaantje', 'organen'),
((SELECT id FROM t_nouns WHERE word='organisatie' LIMIT 1), 'de', 'organisatietje', 'organisaties'),
((SELECT id FROM t_nouns WHERE word='ouder' LIMIT 1), 'de', 'oudertje', 'ouders'),
((SELECT id FROM t_nouns WHERE word='pad' LIMIT 1), 'het', 'paadje', 'paden'),
((SELECT id FROM t_nouns WHERE word='papier' LIMIT 1), 'het', 'papiertje', 'papieren'),
((SELECT id FROM t_nouns WHERE word='partner' LIMIT 1), 'de', 'partnertje', 'partners'),
((SELECT id FROM t_nouns WHERE word='pas' LIMIT 1), 'de', 'pasje', 'passen'),
((SELECT id FROM t_nouns WHERE word='patiÃ«nt' LIMIT 1), 'de', 'patiÃ«ntje', 'patiÃ«nten'),
((SELECT id FROM t_nouns WHERE word='patroon' LIMIT 1), 'het', 'patroontje', 'patronen'),
((SELECT id FROM t_nouns WHERE word='periode' LIMIT 1), 'de', 'periodetje', 'periodes'),
((SELECT id FROM t_nouns WHERE word='pers' LIMIT 1), 'de', 'persje', 'pers'),
((SELECT id FROM t_nouns WHERE word='persoon' LIMIT 1), 'de', 'persoontje', 'personen'),
((SELECT id FROM t_nouns WHERE word='persoonlijkheid' LIMIT 1), 'de', 'persoonlijkheidje', 'persoonlijkheden'),
((SELECT id FROM t_nouns WHERE word='pijn' LIMIT 1), 'de', 'pijntje', 'pijnen'),
((SELECT id FROM t_nouns WHERE word='plaat' LIMIT 1), 'de', 'plaatje', 'platen'),
((SELECT id FROM t_nouns WHERE word='plaats' LIMIT 1), 'de', 'plaatsje', 'plaatsen'),
((SELECT id FROM t_nouns WHERE word='plan' LIMIT 1), 'het', 'plannetje', 'plannen'),
((SELECT id FROM t_nouns WHERE word='plant' LIMIT 1), 'de', 'plantje', 'planten'),
((SELECT id FROM t_nouns WHERE word='plezier' LIMIT 1), 'het', 'pleziertje', 'plezier'),
((SELECT id FROM t_nouns WHERE word='politie' LIMIT 1), 'de', 'politietje', 'politie'),
((SELECT id FROM t_nouns WHERE word='positie' LIMIT 1), 'de', 'positietje', 'posities'),
((SELECT id FROM t_nouns WHERE word='pot' LIMIT 1), 'de', 'potje', 'potten'),
((SELECT id FROM t_nouns WHERE word='praktijk' LIMIT 1), 'de', 'praktijkje', 'praktijken'),
((SELECT id FROM t_nouns WHERE word='president' LIMIT 1), 'de', 'presidentje', 'presidenten'),
((SELECT id FROM t_nouns WHERE word='prijs' LIMIT 1), 'de', 'prijsje', 'prijzen'),
((SELECT id FROM t_nouns WHERE word='probleem' LIMIT 1), 'het', 'probleempje', 'problemen'),
((SELECT id FROM t_nouns WHERE word='procent' LIMIT 1), 'het', 'procentje', 'procenten'),
((SELECT id FROM t_nouns WHERE word='proces' LIMIT 1), 'het', 'procesje', 'processen'),
((SELECT id FROM t_nouns WHERE word='product' LIMIT 1), 'het', 'productje', 'producten'),
((SELECT id FROM t_nouns WHERE word='productie' LIMIT 1), 'de', 'productietje', 'producties'),
((SELECT id FROM t_nouns WHERE word='programma' LIMIT 1), 'het', 'programmaatje', 'programma''s'),
((SELECT id FROM t_nouns WHERE word='project' LIMIT 1), 'het', 'projectje', 'projecten'),
((SELECT id FROM t_nouns WHERE word='provincie' LIMIT 1), 'de', 'provincietje', 'provincies'),
((SELECT id FROM t_nouns WHERE word='psychologie' LIMIT 1), 'de', 'psychologietje', 'psychologie'),
((SELECT id FROM t_nouns WHERE word='psycholoog' LIMIT 1), 'de', 'psycholoogje', 'psychologen'),
((SELECT id FROM t_nouns WHERE word='radio' LIMIT 1), 'de', 'radiootje', 'radio''s'),
((SELECT id FROM t_nouns WHERE word='reactie' LIMIT 1), 'de', 'reactietje', 'reacties'),
((SELECT id FROM t_nouns WHERE word='reden' LIMIT 1), 'de', 'redentje', 'redenen'),
((SELECT id FROM t_nouns WHERE word='regel' LIMIT 1), 'de', 'regeltje', 'regels'),
((SELECT id FROM t_nouns WHERE word='relatie' LIMIT 1), 'de', 'relatietje', 'relaties'),
((SELECT id FROM t_nouns WHERE word='restaurant' LIMIT 1), 'het', 'restaurantje', 'restaurants'),
((SELECT id FROM t_nouns WHERE word='resultaat' LIMIT 1), 'het', 'resultaatje', 'resultaten'),
((SELECT id FROM t_nouns WHERE word='rijk' LIMIT 1), 'het', 'rijkje', 'rijken'),
((SELECT id FROM t_nouns WHERE word='risico' LIMIT 1), 'het', 'risicootje', 'risico''s'),
((SELECT id FROM t_nouns WHERE word='rivier' LIMIT 1), 'de', 'riviertje', 'rivieren'),
((SELECT id FROM t_nouns WHERE word='roepnaam' LIMIT 1), 'de', 'roepnaamtje', 'roepnamen'),
((SELECT id FROM t_nouns WHERE word='rol' LIMIT 1), 'de', 'rolletje', 'rollen'),
((SELECT id FROM t_nouns WHERE word='rommel' LIMIT 1), 'de', 'rommeltje', 'rommel'),
((SELECT id FROM t_nouns WHERE word='rust' LIMIT 1), 'de', 'rustje', 'rust'),
((SELECT id FROM t_nouns WHERE word='schaduw' LIMIT 1), 'de', 'schaduwt je', 'schaduwen'),
((SELECT id FROM t_nouns WHERE word='schoen' LIMIT 1), 'de', 'schoentje', 'schoenen'),
((SELECT id FROM t_nouns WHERE word='school' LIMIT 1), 'de', 'schooltje', 'scholen'),
((SELECT id FROM t_nouns WHERE word='schouder' LIMIT 1), 'de', 'schoudertje', 'schouders'),
((SELECT id FROM t_nouns WHERE word='seconde' LIMIT 1), 'de', 'secondetje', 'seconden'),
((SELECT id FROM t_nouns WHERE word='sector' LIMIT 1), 'de', 'sectortje', 'sectoren'),
((SELECT id FROM t_nouns WHERE word='sigaret' LIMIT 1), 'de', 'sigaretje', 'sigaretten'),
((SELECT id FROM t_nouns WHERE word='slaap' LIMIT 1), 'de', 'slaapje', 'slaap'),
((SELECT id FROM t_nouns WHERE word='sneeuw' LIMIT 1), 'de', 'sneeuwt je', 'sneeuw'),
((SELECT id FROM t_nouns WHERE word='soort' LIMIT 1), 'de', 'soortje', 'soorten'),
((SELECT id FROM t_nouns WHERE word='staan' LIMIT 1), 'de', 'staantje', 'stands'),
((SELECT id FROM t_nouns WHERE word='staat' LIMIT 1), 'de', 'staatje', 'staten'),
((SELECT id FROM t_nouns WHERE word='stap' LIMIT 1), 'de', 'stapje', 'stappen'),
((SELECT id FROM t_nouns WHERE word='station' LIMIT 1), 'het', 'stationnetje', 'stations'),
((SELECT id FROM t_nouns WHERE word='steen' LIMIT 1), 'de', 'steentje', 'stenen'),
((SELECT id FROM t_nouns WHERE word='ster' LIMIT 1), 'de', 'sterretje', 'sterren'),
((SELECT id FROM t_nouns WHERE word='stijl' LIMIT 1), 'de', 'stijltje', 'stijlen'),
((SELECT id FROM t_nouns WHERE word='straat' LIMIT 1), 'de', 'straatje', 'straten'),
((SELECT id FROM t_nouns WHERE word='structuur' LIMIT 1), 'de', 'structuurtje', 'structuren'),
((SELECT id FROM t_nouns WHERE word='student' LIMIT 1), 'de', 'studentje', 'studenten'),
((SELECT id FROM t_nouns WHERE word='studie' LIMIT 1), 'de', 'studietje', 'studies'),
((SELECT id FROM t_nouns WHERE word='succes' LIMIT 1), 'het', 'succesje', 'successen'),
((SELECT id FROM t_nouns WHERE word='suiker' LIMIT 1), 'de', 'suikertje', 'suiker'),
((SELECT id FROM t_nouns WHERE word='symbool' LIMIT 1), 'het', 'symbooltje', 'symbolen'),
((SELECT id FROM t_nouns WHERE word='systeem' LIMIT 1), 'het', 'systeempje', 'systemen'),
((SELECT id FROM t_nouns WHERE word='tafel' LIMIT 1), 'de', 'tafeltje', 'tafels'),
((SELECT id FROM t_nouns WHERE word='tante' LIMIT 1), 'de', 'tantetje', 'tantes'),
((SELECT id FROM t_nouns WHERE word='techniek' LIMIT 1), 'de', 'techniekje', 'technieken'),
((SELECT id FROM t_nouns WHERE word='tekst' LIMIT 1), 'de', 'tekstje', 'teksten'),
((SELECT id FROM t_nouns WHERE word='telefoon' LIMIT 1), 'de', 'telefoontje', 'telefoons'),
((SELECT id FROM t_nouns WHERE word='televisie' LIMIT 1), 'de', 'televisietje', 'televisies'),
((SELECT id FROM t_nouns WHERE word='tentamen' LIMIT 1), 'het', 'tentamenje', 'tentamens'),
((SELECT id FROM t_nouns WHERE word='term' LIMIT 1), 'de', 'termpje', 'termen'),
((SELECT id FROM t_nouns WHERE word='terras' LIMIT 1), 'het', 'terrasje', 'terrassen'),
((SELECT id FROM t_nouns WHERE word='terrein' LIMIT 1), 'het', 'terreintje', 'terreinen'),
((SELECT id FROM t_nouns WHERE word='thee' LIMIT 1), 'de', 'theetje', 'thee'),
((SELECT id FROM t_nouns WHERE word='theorie' LIMIT 1), 'de', 'theorietje', 'theorieÃ«n'),
((SELECT id FROM t_nouns WHERE word='titel' LIMIT 1), 'de', 'titeltje', 'titels'),
((SELECT id FROM t_nouns WHERE word='toetje' LIMIT 1), 'het', 'toetje', 'toetjes'),
((SELECT id FROM t_nouns WHERE word='toets' LIMIT 1), 'de', 'toetsje', 'toetsen'),
((SELECT id FROM t_nouns WHERE word='tong' LIMIT 1), 'de', 'tongetje', 'tongen'),
((SELECT id FROM t_nouns WHERE word='top' LIMIT 1), 'de', 'topje', 'toppen'),
((SELECT id FROM t_nouns WHERE word='traditie' LIMIT 1), 'de', 'traditietje', 'tradities'),
((SELECT id FROM t_nouns WHERE word='trein' LIMIT 1), 'de', 'treintje', 'treinen'),
((SELECT id FROM t_nouns WHERE word='tuin' LIMIT 1), 'de', 'tuintje', 'tuinen'),
((SELECT id FROM t_nouns WHERE word='universiteit' LIMIT 1), 'de', 'universiteittje', 'universiteiten'),
((SELECT id FROM t_nouns WHERE word='uur' LIMIT 1), 'het', 'uurtje', 'uren'),
((SELECT id FROM t_nouns WHERE word='vader' LIMIT 1), 'de', 'vadertje', 'vaders'),
((SELECT id FROM t_nouns WHERE word='veld' LIMIT 1), 'het', 'veldje', 'velden'),
((SELECT id FROM t_nouns WHERE word='verjaardag' LIMIT 1), 'de', 'verjaardagje', 'verjaardagen'),
((SELECT id FROM t_nouns WHERE word='vinger' LIMIT 1), 'de', 'vingertje', 'vingers'),
((SELECT id FROM t_nouns WHERE word='vis' LIMIT 1), 'de', 'visje', 'vissen'),
((SELECT id FROM t_nouns WHERE word='visie' LIMIT 1), 'de', 'visietje', 'visies'),
((SELECT id FROM t_nouns WHERE word='vloer' LIMIT 1), 'de', 'vloertje', 'vloeren'),
((SELECT id FROM t_nouns WHERE word='voet' LIMIT 1), 'de', 'voetje', 'voeten'),
((SELECT id FROM t_nouns WHERE word='vorming' LIMIT 1), 'de', 'vormingetje', 'vormingen'),
((SELECT id FROM t_nouns WHERE word='vriend' LIMIT 1), 'de', 'vriendje', 'vrienden'),
((SELECT id FROM t_nouns WHERE word='vriendin' LIMIT 1), 'de', 'vriendinnetje', 'vriendinnen'),
((SELECT id FROM t_nouns WHERE word='vuilnis' LIMIT 1), 'het', 'vuilnisje', 'vuilnis'),
((SELECT id FROM t_nouns WHERE word='vuur' LIMIT 1), 'het', 'vuurtje', 'vuren'),
((SELECT id FROM t_nouns WHERE word='wapen' LIMIT 1), 'het', 'wapentje', 'wapens'),
((SELECT id FROM t_nouns WHERE word='warmte' LIMIT 1), 'de', 'warmtetje', 'warmte'),
((SELECT id FROM t_nouns WHERE word='wasmachine' LIMIT 1), 'de', 'wasmachinetje', 'wasmachines'),
((SELECT id FROM t_nouns WHERE word='water' LIMIT 1), 'het', 'watertje', 'waters'),
((SELECT id FROM t_nouns WHERE word='week' LIMIT 1), 'de', 'weekje', 'weken'),
((SELECT id FROM t_nouns WHERE word='weer' LIMIT 1), 'het', 'weertje', 'weer'),
((SELECT id FROM t_nouns WHERE word='wens' LIMIT 1), 'de', 'wensje', 'wensen'),
((SELECT id FROM t_nouns WHERE word='wereld' LIMIT 1), 'de', 'wereldje', 'werelden'),
((SELECT id FROM t_nouns WHERE word='werk' LIMIT 1), 'het', 'werkje', 'werken'),
((SELECT id FROM t_nouns WHERE word='westen' LIMIT 1), 'het', 'westentje', 'westen'),
((SELECT id FROM t_nouns WHERE word='wetenschap' LIMIT 1), 'de', 'wetenschapje', 'wetenschappen'),
((SELECT id FROM t_nouns WHERE word='wijn' LIMIT 1), 'de', 'wijntje', 'wijnen'),
((SELECT id FROM t_nouns WHERE word='wind' LIMIT 1), 'de', 'windje', 'winden'),
((SELECT id FROM t_nouns WHERE word='winter' LIMIT 1), 'de', 'wintertje', 'winters'),
((SELECT id FROM t_nouns WHERE word='woord' LIMIT 1), 'het', 'woordje', 'woorden'),
((SELECT id FROM t_nouns WHERE word='zaken' LIMIT 1), 'de', 'zaakje', 'zaken'),
((SELECT id FROM t_nouns WHERE word='zand' LIMIT 1), 'het', 'zandje', 'zand'),
((SELECT id FROM t_nouns WHERE word='zee' LIMIT 1), 'de', 'zeetje', 'zeeÃ«n'),
((SELECT id FROM t_nouns WHERE word='zomer' LIMIT 1), 'de', 'zomertje', 'zomers'),
((SELECT id FROM t_nouns WHERE word='zondag' LIMIT 1), 'de', 'zondagje', 'zondagen'),
((SELECT id FROM t_nouns WHERE word='zoon' LIMIT 1), 'de', 'zoontje', 'zonen'),
((SELECT id FROM t_nouns WHERE word='zout' LIMIT 1), 'het', 'zoutje', 'zouten'),
((SELECT id FROM t_nouns WHERE word='zus' LIMIT 1), 'de', 'zusje', 'zussen'),
((SELECT id FROM t_nouns WHERE word='zuster' LIMIT 1), 'de', 'zustertje', 'zusters')
ON CONFLICT (word_id) DO NOTHING;

-- Clean up temporary table
DROP TABLE t_nouns;

CREATE TEMP TABLE t_numerals AS
SELECT id, word
FROM words
WHERE part_of_speech = 'numeral';

-- Create numeral forms for Dutch numerals (explicit rows mirroring nouns style)
INSERT INTO numerals (word_id, numeric_value, ordinal_form) VALUES
((SELECT id FROM t_numerals WHERE word='nul' LIMIT 1), 0, 'nul'),
((SELECT id FROM t_numerals WHERE word='een' LIMIT 1), 1, 'eerste'),
((SELECT id FROM t_numerals WHERE word='twee' LIMIT 1), 2, 'tweede'),
((SELECT id FROM t_numerals WHERE word='drie' LIMIT 1), 3, 'derde'),
((SELECT id FROM t_numerals WHERE word='vier' LIMIT 1), 4, 'vierde'),
((SELECT id FROM t_numerals WHERE word='vijf' LIMIT 1), 5, 'vijfde'),
((SELECT id FROM t_numerals WHERE word='zes' LIMIT 1), 6, 'zesde'),
((SELECT id FROM t_numerals WHERE word='zeven' LIMIT 1), 7, 'zevende'),
((SELECT id FROM t_numerals WHERE word='acht' LIMIT 1), 8, 'achtste'),
((SELECT id FROM t_numerals WHERE word='negen' LIMIT 1), 9, 'negende'),
((SELECT id FROM t_numerals WHERE word='tien' LIMIT 1), 10, 'tiende'),
((SELECT id FROM t_numerals WHERE word='elf' LIMIT 1), 11, 'elfde'),
((SELECT id FROM t_numerals WHERE word='twaalf' LIMIT 1), 12, 'twaalfde'),
((SELECT id FROM t_numerals WHERE word='dertien' LIMIT 1), 13, 'dertiende'),
((SELECT id FROM t_numerals WHERE word='veertien' LIMIT 1), 14, 'veertiende'),
((SELECT id FROM t_numerals WHERE word='vijftien' LIMIT 1), 15, 'vijftiende'),
((SELECT id FROM t_numerals WHERE word='zestien' LIMIT 1), 16, 'zestiende'),
((SELECT id FROM t_numerals WHERE word='zeventien' LIMIT 1), 17, 'zeventiende'),
((SELECT id FROM t_numerals WHERE word='achttien' LIMIT 1), 18, 'achttiende'),
((SELECT id FROM t_numerals WHERE word='negentien' LIMIT 1), 19, 'negentiende'),
((SELECT id FROM t_numerals WHERE word='twintig' LIMIT 1), 20, 'twintigste'),
((SELECT id FROM t_numerals WHERE word='dertig' LIMIT 1), 30, 'dertigste'),
((SELECT id FROM t_numerals WHERE word='veertig' LIMIT 1), 40, 'veertigste'),
((SELECT id FROM t_numerals WHERE word='vijftig' LIMIT 1), 50, 'vijftigste'),
((SELECT id FROM t_numerals WHERE word='honderd' LIMIT 1), 100, 'honderdste'),
((SELECT id FROM t_numerals WHERE word='duizend' LIMIT 1), 1000, 'duizendste')
ON CONFLICT (word_id) DO NOTHING;

DROP TABLE t_numerals;

CREATE TEMP TABLE t_adjs AS
SELECT id, word
FROM words
WHERE part_of_speech = 'adjective';

-- Create adjective forms for Dutch adjectives (explicit rows)
INSERT INTO adjectives (word_id, inflected, comparative, superlative) VALUES
((SELECT id FROM t_adjs WHERE word='aanstaande' LIMIT 1), 'aanstaande', NULL, NULL),
((SELECT id FROM t_adjs WHERE word='aanwezig' LIMIT 1), 'aanwezige', 'aanweziger', 'aanwezigste'),
((SELECT id FROM t_adjs WHERE word='actief' LIMIT 1), 'actieve', 'actiever', 'actiefste'),
((SELECT id FROM t_adjs WHERE word='al' LIMIT 1), 'alle', NULL, NULL),
((SELECT id FROM t_adjs WHERE word='algemeen' LIMIT 1), 'algemene', 'algemener', 'algemeenste'),
((SELECT id FROM t_adjs WHERE word='alle' LIMIT 1), 'alle', NULL, NULL),
((SELECT id FROM t_adjs WHERE word='alleen' LIMIT 1), 'alleen', NULL, NULL),
((SELECT id FROM t_adjs WHERE word=' ANDer' LIMIT 1), ' ANDere', NULL, NULL),
((SELECT id FROM t_adjs WHERE word='arm' LIMIT 1), 'arme', 'armer', 'armste'),
((SELECT id FROM t_adjs WHERE word='beide' LIMIT 1), 'beide', NULL, NULL),
((SELECT id FROM t_adjs WHERE word='beroemd' LIMIT 1), 'beroemde', 'beroemder', 'beroemdste'),
((SELECT id FROM t_adjs WHERE word='beter' LIMIT 1), 'betere', NULL, NULL),
((SELECT id FROM t_adjs WHERE word='bezig' LIMIT 1), 'bezige', 'beziger', 'bezigste'),
((SELECT id FROM t_adjs WHERE word='bitter' LIMIT 1), 'bittere', 'bitterder', 'bitterste'),
((SELECT id FROM t_adjs WHERE word='blauw' LIMIT 1), 'blauwe', 'blauwer', 'blauwste'),
((SELECT id FROM t_adjs WHERE word='boos' LIMIT 1), 'boze', 'bozer', 'booste'),
((SELECT id FROM t_adjs WHERE word='bruin' LIMIT 1), 'bruine', 'bruiner', 'bruinste'),
((SELECT id FROM t_adjs WHERE word='cultureel' LIMIT 1), 'culturele', 'cultureler', 'cultureelste'),
((SELECT id FROM t_adjs WHERE word='diep' LIMIT 1), 'diepe', 'dieper', 'diepste'),
((SELECT id FROM t_adjs WHERE word='direct' LIMIT 1), 'directe', 'directer', 'directste'),
((SELECT id FROM t_adjs WHERE word='dom' LIMIT 1), 'domme', 'dommer', 'domste'),
((SELECT id FROM t_adjs WHERE word='dood' LIMIT 1), 'dode', NULL, NULL),
((SELECT id FROM t_adjs WHERE word='druk' LIMIT 1), 'drukke', 'drukker', 'drukste'),
((SELECT id FROM t_adjs WHERE word='dubbel' LIMIT 1), 'dubbele', NULL, NULL),
((SELECT id FROM t_adjs WHERE word='duidelijk' LIMIT 1), 'duidelijke', 'duidelijker', 'duidelijkste'),
((SELECT id FROM t_adjs WHERE word='dun' LIMIT 1), 'dunne', 'dunner', 'dunste'),
((SELECT id FROM t_adjs WHERE word='duur' LIMIT 1), 'dure', 'duurder', 'duurste'),
((SELECT id FROM t_adjs WHERE word='eenzaam' LIMIT 1), 'eenzame', 'eenzamer', 'eenzaamste'),
((SELECT id FROM t_adjs WHERE word='eindeloos' LIMIT 1), 'eindeloze', NULL, NULL),
((SELECT id FROM t_adjs WHERE word='elk' LIMIT 1), 'elke', NULL, NULL),
((SELECT id FROM t_adjs WHERE word='emotioneel' LIMIT 1), 'emotionele', 'emotioneler', 'emotioneelste'),
((SELECT id FROM t_adjs WHERE word='engels' LIMIT 1), 'engelse', NULL, NULL),
((SELECT id FROM t_adjs WHERE word='enorm' LIMIT 1), 'enorme', 'enormer', 'enormste'),
((SELECT id FROM t_adjs WHERE word='financieel' LIMIT 1), 'financiÃ«le', 'financieler', 'financieelste'),
((SELECT id FROM t_adjs WHERE word='fundamenteel' LIMIT 1), 'fundamentele', 'fundamenteler', 'fundamenteelste'),
((SELECT id FROM t_adjs WHERE word='geboren' LIMIT 1), 'geboren', NULL, NULL),
((SELECT id FROM t_adjs WHERE word='gemeen' LIMIT 1), 'gemene', 'gemener', 'gemeenste'),
((SELECT id FROM t_adjs WHERE word='gewoon' LIMIT 1), 'gewone', 'gewoner', 'gewoonste'),
((SELECT id FROM t_adjs WHERE word='gezond' LIMIT 1), 'gezonde', 'gezonder', 'gezondste'),
((SELECT id FROM t_adjs WHERE word='goed' LIMIT 1), 'goede', 'beter', 'beste'),
((SELECT id FROM t_adjs WHERE word='goedkoop' LIMIT 1), 'goedkope', 'goedkoper', 'goedkoopste'),
((SELECT id FROM t_adjs WHERE word='gouden' LIMIT 1), 'gouden', NULL, NULL),
((SELECT id FROM t_adjs WHERE word='groen' LIMIT 1), 'groene', 'groener', 'groenste'),
((SELECT id FROM t_adjs WHERE word='half' LIMIT 1), 'halve', NULL, NULL),
((SELECT id FROM t_adjs WHERE word='hard' LIMIT 1), 'harde', 'harder', 'hardste'),
((SELECT id FROM t_adjs WHERE word='heet' LIMIT 1), 'hete', 'heter', 'heetste'),
((SELECT id FROM t_adjs WHERE word='historisch' LIMIT 1), 'historische', 'historischer', 'historischste'),
((SELECT id FROM t_adjs WHERE word='ideaal' LIMIT 1), 'ideale', 'idealer', 'ideaalste'),
((SELECT id FROM t_adjs WHERE word='ieder' LIMIT 1), 'iedere', NULL, NULL),
((SELECT id FROM t_adjs WHERE word='iedere' LIMIT 1), 'iedere', NULL, NULL),
((SELECT id FROM t_adjs WHERE word='individueel' LIMIT 1), 'individuele', 'individueler', 'individueelste'),
((SELECT id FROM t_adjs WHERE word='interessant' LIMIT 1), 'interessante', 'interessanter', 'interessantste'),
((SELECT id FROM t_adjs WHERE word='internationaal' LIMIT 1), 'internationale', 'internationaler', 'internationaalste'),
((SELECT id FROM t_adjs WHERE word='jong' LIMIT 1), 'jonge', 'jonger', 'jongste'),
((SELECT id FROM t_adjs WHERE word='kalm' LIMIT 1), 'kalme', 'kalmer', 'kalmste'),
((SELECT id FROM t_adjs WHERE word='klassiek' LIMIT 1), 'klassieke', 'klassieker', 'klassiekste'),
((SELECT id FROM t_adjs WHERE word='koel' LIMIT 1), 'koele', 'koeler', 'koelste'),
((SELECT id FROM t_adjs WHERE word='koud' LIMIT 1), 'koude', 'kouder', 'koudste'),
((SELECT id FROM t_adjs WHERE word='laat' LIMIT 1), 'late', 'later', 'laatste'),
((SELECT id FROM t_adjs WHERE word='laatste' LIMIT 1), 'laatste', NULL, NULL),
((SELECT id FROM t_adjs WHERE word='lang' LIMIT 1), 'lange', 'langer', 'langste'),
((SELECT id FROM t_adjs WHERE word='licht' LIMIT 1), 'lichte', 'lichter', 'lichtste'),
((SELECT id FROM t_adjs WHERE word='logisch' LIMIT 1), 'logische', 'logischer', 'logischste'),
((SELECT id FROM t_adjs WHERE word='los' LIMIT 1), 'losse', 'losser', 'losste'),
((SELECT id FROM t_adjs WHERE word='medisch' LIMIT 1), 'medische', NULL, NULL),
((SELECT id FROM t_adjs WHERE word='modern' LIMIT 1), 'moderne', 'moderner', 'modernste'),
((SELECT id FROM t_adjs WHERE word='moe' LIMIT 1), 'moe', 'moeÃ«r', 'moeste'),
((SELECT id FROM t_adjs WHERE word='moeilijk' LIMIT 1), 'moeilijke', 'moeilijker', 'moeilijkste'),
((SELECT id FROM t_adjs WHERE word='mooi' LIMIT 1), 'mooie', 'mooier', 'mooiste'),
((SELECT id FROM t_adjs WHERE word='nationaal' LIMIT 1), 'nationale', 'nationaler', 'nationaalste'),
((SELECT id FROM t_adjs WHERE word='negatief' LIMIT 1), 'negatieve', 'negatiever', 'negatiefste'),
((SELECT id FROM t_adjs WHERE word='nieuw' LIMIT 1), 'nieuwe', 'nieuwer', 'nieuwste'),
((SELECT id FROM t_adjs WHERE word='normaal' LIMIT 1), 'normale', 'normaler', 'normaalste'),
((SELECT id FROM t_adjs WHERE word='officieel' LIMIT 1), 'officiÃ«le', 'officiÃ«ler', 'officiÃ«elst'),
((SELECT id FROM t_adjs WHERE word='open' LIMIT 1), 'open', 'opener', 'openste'),
((SELECT id FROM t_adjs WHERE word='oud' LIMIT 1), 'oude', 'ouder', 'oudste'),
((SELECT id FROM t_adjs WHERE word='pijnlijk' LIMIT 1), 'pijnlijke', 'pijnlijker', 'pijnlijkste'),
((SELECT id FROM t_adjs WHERE word='positief' LIMIT 1), 'positieve', 'positiever', 'positiefste'),
((SELECT id FROM t_adjs WHERE word='prachtig' LIMIT 1), 'prachtige', 'prachtiger', 'prachtigste'),
((SELECT id FROM t_adjs WHERE word='praktisch' LIMIT 1), 'praktische', 'praktischer', 'praktischste'),
((SELECT id FROM t_adjs WHERE word='psychologisch' LIMIT 1), 'psychologische', 'psychologischer', 'psychologischste'),
((SELECT id FROM t_adjs WHERE word='raar' LIMIT 1), 'rare', 'raarder', 'raarste'),
((SELECT id FROM t_adjs WHERE word='rijk' LIMIT 1), 'rijke', 'rijker', 'rijkste'),
((SELECT id FROM t_adjs WHERE word='rommelig' LIMIT 1), 'rommelige', 'rommeliger', 'rommeligste'),
((SELECT id FROM t_adjs WHERE word='rond' LIMIT 1), 'ronde', 'ronder', 'rondste'),
((SELECT id FROM t_adjs WHERE word='rood' LIMIT 1), 'rode', 'roder', 'roodste'),
((SELECT id FROM t_adjs WHERE word='serieus' LIMIT 1), 'serieuze', 'serieuzer', 'serieuust'),
((SELECT id FROM t_adjs WHERE word='smerig' LIMIT 1), 'smerige', 'smeriger', 'smerigste'),
((SELECT id FROM t_adjs WHERE word='sociaal' LIMIT 1), 'sociale', 'socialer', 'sociaalste'),
((SELECT id FROM t_adjs WHERE word='sommige' LIMIT 1), 'sommige', NULL, NULL),
((SELECT id FROM t_adjs WHERE word='speciaal' LIMIT 1), 'speciale', 'specialer', 'speciaalste'),
((SELECT id FROM t_adjs WHERE word='specifiek' LIMIT 1), 'specifieke', 'specifieker', 'specifiekste'),
((SELECT id FROM t_adjs WHERE word='stijf' LIMIT 1), 'stijve', 'stijver', 'stijfste'),
((SELECT id FROM t_adjs WHERE word='stil' LIMIT 1), 'stille', 'stiller', 'stilste'),
((SELECT id FROM t_adjs WHERE word='technisch' LIMIT 1), 'technische', 'technischer', 'technischste'),
((SELECT id FROM t_adjs WHERE word='theoretisch' LIMIT 1), 'theoretische', 'theoretischer', 'theoretischste'),
((SELECT id FROM t_adjs WHERE word='totaal' LIMIT 1), 'totale', NULL, NULL),
((SELECT id FROM t_adjs WHERE word='traditioneel' LIMIT 1), 'traditionele', 'traditioneler', 'traditioneelste'),
((SELECT id FROM t_adjs WHERE word='typisch' LIMIT 1), 'typische', 'typischer', 'typischste'),
((SELECT id FROM t_adjs WHERE word='uitstekend' LIMIT 1), 'uitstekende', 'uitstekender', 'uitstekendste'),
((SELECT id FROM t_adjs WHERE word='ver' LIMIT 1), 'verre', 'verder', 'verste'),
((SELECT id FROM t_adjs WHERE word='vervelend' LIMIT 1), 'vervelende', 'vervelender', 'vervelendste'),
((SELECT id FROM t_adjs WHERE word='vies' LIMIT 1), 'vieze', 'viezer', 'viezerste'),
((SELECT id FROM t_adjs WHERE word='vol' LIMIT 1), 'volle', 'voller', 'volste'),
((SELECT id FROM t_adjs WHERE word='volgende' LIMIT 1), 'volgende', NULL, NULL),
((SELECT id FROM t_adjs WHERE word='vreemd' LIMIT 1), 'vreemde', 'vreemder', 'vreemdste'),
((SELECT id FROM t_adjs WHERE word='vriendelijk' LIMIT 1), 'vriendelijke', 'vriendelijker', 'vriendelijkste'),
((SELECT id FROM t_adjs WHERE word='vrij' LIMIT 1), 'vrije', 'vrijer', 'vrijste'),
((SELECT id FROM t_adjs WHERE word='vroeg' LIMIT 1), 'vroege', 'vroeger', 'vroegste'),
((SELECT id FROM t_adjs WHERE word='vrolijk' LIMIT 1), 'vrolijke', 'vrolijker', 'vrolijkste'),
((SELECT id FROM t_adjs WHERE word='wakker' LIMIT 1), 'wakkere', 'wakkerder', 'wakkerste'),
((SELECT id FROM t_adjs WHERE word='warm' LIMIT 1), 'warme', 'warmer', 'warmste'),
((SELECT id FROM t_adjs WHERE word='westers' LIMIT 1), 'westerse', NULL, NULL),
((SELECT id FROM t_adjs WHERE word='wijd' LIMIT 1), 'wijde', 'wijder', 'wijdste'),
((SELECT id FROM t_adjs WHERE word='wild' LIMIT 1), 'wilde', 'wilder', 'wildste'),
((SELECT id FROM t_adjs WHERE word='wit' LIMIT 1), 'witte', 'witter', 'witste'),
((SELECT id FROM t_adjs WHERE word='zacht' LIMIT 1), 'zachte', 'zachter', 'zachtste'),
((SELECT id FROM t_adjs WHERE word='ziek' LIMIT 1), 'zieke', 'zieker', 'ziekste'),
((SELECT id FROM t_adjs WHERE word='zoet' LIMIT 1), 'zoete', 'zoeter', 'zoetste')
ON CONFLICT (word_id) DO NOTHING;

-- Clean up temporary table
DROP TABLE t_adjs;

CREATE TEMP TABLE t_verbs AS
SELECT id, word
FROM words
WHERE part_of_speech = 'verb';

-- Create verb forms for common Dutch verbs (explicit rows)
INSERT INTO verbs (
    word_id,
    infinitive,
    ik,
    jij,
    u,
    hij,
    wij,
    past_sg,
    past_pl,
    past_participle,
    perfect,
    separable_prefix,
    is_irregular,
    is_strong_verb,
    is_modal
)
VALUES
-- PART_1_START
-- accepteren (to accept) - regular
((SELECT id FROM t_verbs WHERE word='accepteren' LIMIT 1), 'accepteren', 'accepteer', 'accepteert', 'accepteert', 'accepteert', 'accepteren', 'accepteerde', 'accepteerden', 'geaccepteerd', 'hebben', NULL, false, false, false),
-- beginnen (to begin) - strong verb
((SELECT id FROM t_verbs WHERE word='beginnen' LIMIT 1), 'beginnen', 'begin', 'begint', 'begint', 'begint', 'beginnen', 'begon', 'begonnen', 'begonnen', 'zijn', NULL, true, true, false),
-- bespreken (to discuss) - strong verb
((SELECT id FROM t_verbs WHERE word='bespreken' LIMIT 1), 'bespreken', 'bespreek', 'bespreekt', 'bespreekt', 'bespreekt', 'bespreken', 'besprak', 'bespraken', 'besproken', 'hebben', NULL, true, true, false),
-- bestellen (to order) - regular
((SELECT id FROM t_verbs WHERE word='bestellen' LIMIT 1), 'bestellen', 'bestel', 'bestelt', 'bestelt', 'bestelt', 'bestellen', 'bestelde', 'bestelden', 'besteld', 'hebben', NULL, false, false, false),
-- bezoeken (to visit) - regular
((SELECT id FROM t_verbs WHERE word='bezoeken' LIMIT 1), 'bezoeken', 'bezoek', 'bezoekt', 'bezoekt', 'bezoekt', 'bezoeken', 'bezocht', 'bezochten', 'bezocht', 'hebben', NULL, false, false, false),
-- beÃ¯nvloeden (to influence) - regular
((SELECT id FROM t_verbs WHERE word='beÃ¯nvloeden' LIMIT 1), 'beÃ¯nvloeden', 'beÃ¯nvloed', 'beÃ¯nvloedt', 'beÃ¯nvloedt', 'beÃ¯nvloedt', 'beÃ¯nvloeden', 'beÃ¯nvloedde', 'beÃ¯nvloedden', 'beÃ¯nvloed', 'hebben', NULL, false, false, false),
-- bijten (to bite) - strong verb
((SELECT id FROM t_verbs WHERE word='bijten' LIMIT 1), 'bijten', 'bijt', 'bijt', 'bijt', 'bijt', 'bijten', 'beet', 'beten', 'gebeten', 'hebben', NULL, true, true, false),
-- borrelen (to have drinks) - regular
((SELECT id FROM t_verbs WHERE word='borrelen' LIMIT 1), 'borrelen', 'borrel', 'borrelt', 'borrelt', 'borrelt', 'borrelen', 'borrelde', 'borrelden', 'geborreld', 'hebben', NULL, false, false, false),
-- bouwen (to build) - regular
((SELECT id FROM t_verbs WHERE word='bouwen' LIMIT 1), 'bouwen', 'bouw', 'bouwt', 'bouwt', 'bouwt', 'bouwen', 'bouwde', 'bouwden', 'gebouwd', 'hebben', NULL, false, false, false),
-- brengen (to bring) - irregular
((SELECT id FROM t_verbs WHERE word='brengen' LIMIT 1), 'brengen', 'breng', 'brengt', 'brengt', 'brengt', 'brengen', 'bracht', 'brachten', 'gebracht', 'hebben', NULL, true, false, false),
-- danken (to thank) - regular
((SELECT id FROM t_verbs WHERE word='danken' LIMIT 1), 'danken', 'dank', 'dankt', 'dankt', 'dankt', 'danken', 'dankte', 'dankten', 'gedankt', 'hebben', NULL, false, false, false),
-- dansen (to dance) - regular
((SELECT id FROM t_verbs WHERE word='dansen' LIMIT 1), 'dansen', 'dans', 'danst', 'danst', 'danst', 'dansen', 'danste', 'dansten', 'gedanst', 'hebben', NULL, false, false, false),
-- denken (to think) - irregular
((SELECT id FROM t_verbs WHERE word='denken' LIMIT 1), 'denken', 'denk', 'denkt', 'denkt', 'denkt', 'denken', 'dacht', 'dachten', 'gedacht', 'hebben', NULL, true, false, false),
-- doen (to do) - irregular
((SELECT id FROM t_verbs WHERE word='doen' LIMIT 1), 'doen', 'doe', 'doet', 'doet', 'doet', 'doen', 'deed', 'deden', 'gedaan', 'hebben', NULL, true, false, false),
-- draaien (to turn) - regular
((SELECT id FROM t_verbs WHERE word='draaien' LIMIT 1), 'draaien', 'draai', 'draait', 'draait', 'draait', 'draaien', 'draaide', 'draaiden', 'gedraaid', 'hebben', NULL, false, false, false),
-- drinken (to drink) - strong verb
((SELECT id FROM t_verbs WHERE word='drinken' LIMIT 1), 'drinken', 'drink', 'drinkt', 'drinkt', 'drinkt', 'drinken', 'dronk', 'dronken', 'gedronken', 'hebben', NULL, true, true, false),
-- dromen (to dream) - regular
((SELECT id FROM t_verbs WHERE word='dromen' LIMIT 1), 'dromen', 'droom', 'droomt', 'droomt', 'droomt', 'dromen', 'droomde', 'droomden', 'gedroomd', 'hebben', NULL, false, false, false),
-- eindigen (to end) - regular
((SELECT id FROM t_verbs WHERE word='eindigen' LIMIT 1), 'eindigen', 'eindig', 'eindigt', 'eindigt', 'eindigt', 'eindigen', 'eindigde', 'eindigden', 'geÃ«indigd', 'hebben', NULL, false, false, false),
-- eten (to eat) - strong verb
((SELECT id FROM t_verbs WHERE word='eten' LIMIT 1), 'eten', 'eet', 'eet', 'eet', 'eet', 'eten', 'at', 'aten', 'gegeten', 'hebben', NULL, true, true, false),
-- formuleren (to formulate) - regular
((SELECT id FROM t_verbs WHERE word='formuleren' LIMIT 1), 'formuleren', 'formuleer', 'formuleert', 'formuleert', 'formuleert', 'formuleren', 'formuleerde', 'formuleerden', 'geformuleerd', 'hebben', NULL, false, false, false),
-- gaan (to go) - irregular
((SELECT id FROM t_verbs WHERE word='gaan' LIMIT 1), 'gaan', 'ga', 'gaat', 'gaat', 'gaat', 'gaan', 'ging', 'gingen', 'gegaan', 'zijn', NULL, true, false, false),
-- geven (to give) - strong verb
((SELECT id FROM t_verbs WHERE word='geven' LIMIT 1), 'geven', 'geef', 'geeft', 'geeft', 'geeft', 'geven', 'gaf', 'gaven', 'gegeven', 'hebben', NULL, true, true, false),
-- groeien (to grow) - regular
((SELECT id FROM t_verbs WHERE word='groeien' LIMIT 1), 'groeien', 'groei', 'groeit', 'groeit', 'groeit', 'groeien', 'groeide', 'groeiden', 'gegroeid', 'zijn', NULL, false, false, false),
-- hebben (to have) - irregular
((SELECT id FROM t_verbs WHERE word='hebben' LIMIT 1), 'hebben', 'heb', 'hebt', 'hebt', 'heeft', 'hebben', 'had', 'hadden', 'gehad', 'hebben', NULL, true, false, false),
-- helpen (to help) - strong verb
((SELECT id FROM t_verbs WHERE word='helpen' LIMIT 1), 'helpen', 'help', 'helpt', 'helpt', 'helpt', 'helpen', 'hielp', 'hielpen', 'geholpen', 'hebben', NULL, true, true, false),
-- hopen (to hope) - regular
((SELECT id FROM t_verbs WHERE word='hopen' LIMIT 1), 'hopen', 'hoop', 'hoopt', 'hoopt', 'hoopt', 'hopen', 'hoopte', 'hoopten', 'gehoopt', 'hebben', NULL, false, false, false),
-- horen (to hear) - regular
((SELECT id FROM t_verbs WHERE word='horen' LIMIT 1), 'horen', 'hoor', 'hoort', 'hoort', 'hoort', 'horen', 'hoorde', 'hoorden', 'gehoord', 'hebben', NULL, false, false, false),
-- houden (to hold) - irregular
((SELECT id FROM t_verbs WHERE word='houden' LIMIT 1), 'houden', 'hou', 'houdt', 'houdt', 'houdt', 'houden', 'hield', 'hielden', 'gehouden', 'hebben', NULL, true, false, false),
-- interesseren (to interest) - regular
((SELECT id FROM t_verbs WHERE word='interesseren' LIMIT 1), 'interesseren', 'interesseer', 'interesseert', 'interesseert', 'interesseert', 'interesseren', 'interesseerde', 'interesseerden', 'geÃ¯nteresseerd', 'hebben', NULL, false, false, false),
-- kijken (to look) - regular
((SELECT id FROM t_verbs WHERE word='kijken' LIMIT 1), 'kijken', 'kijk', 'kijkt', 'kijkt', 'kijkt', 'kijken', 'keek', 'keken', 'gekeken', 'hebben', NULL, false, false, false),
-- klagen (to complain) - regular
((SELECT id FROM t_verbs WHERE word='klagen' LIMIT 1), 'klagen', 'klaag', 'klaagt', 'klaagt', 'klaagt', 'klagen', 'klaagde', 'klaagden', 'geklaagd', 'hebben', NULL, false, false, false),
-- klimmen (to climb) - strong verb
((SELECT id FROM t_verbs WHERE word='klimmen' LIMIT 1), 'klimmen', 'klim', 'klimt', 'klimt', 'klimt', 'klimmen', 'klom', 'klommen', 'geklommen', 'zijn', NULL, true, true, false),
-- komen (to come) - strong verb
((SELECT id FROM t_verbs WHERE word='komen' LIMIT 1), 'komen', 'kom', 'komt', 'komt', 'komt', 'komen', 'kwam', 'kwamen', 'gekomen', 'zijn', NULL, true, true, false),
-- kosten (to cost) - regular
((SELECT id FROM t_verbs WHERE word='kosten' LIMIT 1), 'kosten', 'kost', 'kost', 'kost', 'kost', 'kosten', 'kostte', 'kostten', 'gekost', 'hebben', NULL, false, false, false),
-- kunnen (can) - modal verb
((SELECT id FROM t_verbs WHERE word='kunnen' LIMIT 1), 'kunnen', 'kan', 'kunt', 'kunt', 'kan', 'kunnen', 'kon', 'konden', 'gekund', 'hebben', NULL, true, false, true),
-- lachen (to laugh) - regular
((SELECT id FROM t_verbs WHERE word='lachen' LIMIT 1), 'lachen', 'lach', 'lacht', 'lacht', 'lacht', 'lachen', 'lachte', 'lachten', 'gelachen', 'hebben', NULL, false, false, false),
-- laten (to let) - strong verb
((SELECT id FROM t_verbs WHERE word='laten' LIMIT 1), 'laten', 'laat', 'laat', 'laat', 'laat', 'laten', 'liet', 'lieten', 'gelaten', 'hebben', NULL, true, true, false),
-- leiden (to lead) - irregular
((SELECT id FROM t_verbs WHERE word='leiden' LIMIT 1), 'leiden', 'leid', 'leidt', 'leidt', 'leidt', 'leiden', 'leidde', 'leidden', 'geleid', 'hebben', NULL, false, false, false),
-- leren (to learn) - regular
((SELECT id FROM t_verbs WHERE word='leren' LIMIT 1), 'leren', 'leer', 'leert', 'leert', 'leert', 'leren', 'leerde', 'leerden', 'geleerd', 'hebben', NULL, false, false, false),
-- leven (to live) - regular
((SELECT id FROM t_verbs WHERE word='leven' LIMIT 1), 'leven', 'leef', 'leeft', 'leeft', 'leeft', 'leven', 'leefde', 'leefden', 'geleefd', 'hebben', NULL, false, false, false),
-- leveren (to deliver) - regular
((SELECT id FROM t_verbs WHERE word='leveren' LIMIT 1), 'leveren', 'lever', 'levert', 'levert', 'levert', 'leveren', 'leverde', 'leverden', 'geleverd', 'hebben', NULL, false, false, false),
-- liggen (to lie) - strong verb
((SELECT id FROM t_verbs WHERE word='liggen' LIMIT 1), 'liggen', 'lig', 'ligt', 'ligt', 'ligt', 'liggen', 'lag', 'lagen', 'gelegen', 'hebben', NULL, true, true, false),
-- logeren (to stay over) - regular
((SELECT id FROM t_verbs WHERE word='logeren' LIMIT 1), 'logeren', 'logeer', 'logeert', 'logeert', 'logeert', 'logeren', 'logeerde', 'logeerden', 'gelogeerd', 'hebben', NULL, false, false, false),
-- lopen (to walk) - strong verb
((SELECT id FROM t_verbs WHERE word='lopen' LIMIT 1), 'lopen', 'loop', 'loopt', 'loopt', 'loopt', 'lopen', 'liep', 'liepen', 'gelopen', 'hebben', NULL, true, true, false),
-- luisteren (to listen) - regular
((SELECT id FROM t_verbs WHERE word='luisteren' LIMIT 1), 'luisteren', 'luister', 'luistert', 'luistert', 'luistert', 'luisteren', 'luisterde', 'luisterden', 'geluisterd', 'hebben', NULL, false, false, false),
-- maken (to make) - regular
((SELECT id FROM t_verbs WHERE word='maken' LIMIT 1), 'maken', 'maak', 'maakt', 'maakt', 'maakt', 'maken', 'maakte', 'maakten', 'gemaakt', 'hebben', NULL, false, false, false),
-- menen (to mean) - regular
((SELECT id FROM t_verbs WHERE word='menen' LIMIT 1), 'menen', 'meen', 'meent', 'meent', 'meent', 'menen', 'meende', 'meenden', 'gemeend', 'hebben', NULL, false, false, false),
-- missen (to miss) - regular
((SELECT id FROM t_verbs WHERE word='missen' LIMIT 1), 'missen', 'mis', 'mist', 'mist', 'mist', 'missen', 'miste', 'misten', 'gemist', 'hebben', NULL, false, false, false),
-- moeten (must) - modal verb
((SELECT id FROM t_verbs WHERE word='moeten' LIMIT 1), 'moeten', 'moet', 'moet', 'moet', 'moet', 'moeten', 'moest', 'moesten', 'gemoeten', 'hebben', NULL, true, false, true),
-- oefenen (to practice) - regular
((SELECT id FROM t_verbs WHERE word='oefenen' LIMIT 1), 'oefenen', 'oefen', 'oefent', 'oefent', 'oefent', 'oefenen', 'oefende', 'oefenden', 'geoefend', 'hebben', NULL, false, false, false),
-- ontbreken (to lack) - strong verb
((SELECT id FROM t_verbs WHERE word='ontbreken' LIMIT 1), 'ontbreken', 'ontbreek', 'ontbreekt', 'ontbreekt', 'ontbreekt', 'ontbreken', 'ontbrak', 'ontbraken', 'ontbroken', 'hebben', NULL, true, true, false),
-- ontmoeten (to meet) - regular
((SELECT id FROM t_verbs WHERE word='ontmoeten' LIMIT 1), 'ontmoeten', 'ontmoet', 'ontmoet', 'ontmoet', 'ontmoet', 'ontmoeten', 'ontmoette', 'ontmoetten', 'ontmoet', 'hebben', NULL, false, false, false),
-- ontspannen (to relax) - irregular
((SELECT id FROM t_verbs WHERE word='ontspannen' LIMIT 1), 'ontspannen', 'ontspan', 'ontspant', 'ontspant', 'ontspant', 'ontspannen', 'ontspande', 'ontspanden', 'ontspannen', 'hebben', NULL, false, false, false),
-- ontvangen (to receive) - strong verb
((SELECT id FROM t_verbs WHERE word='ontvangen' LIMIT 1), 'ontvangen', 'ontvang', 'ontvangt', 'ontvangt', 'ontvangt', 'ontvangen', 'ontving', 'ontvingen', 'ontvangen', 'hebben', NULL, true, true, false),
-- openen (to open) - regular
((SELECT id FROM t_verbs WHERE word='openen' LIMIT 1), 'openen', 'open', 'opent', 'opent', 'opent', 'openen', 'opende', 'openden', 'geopend', 'hebben', NULL, false, false, false),
-- ophalen (to pick up) - separable
((SELECT id FROM t_verbs WHERE word='ophalen' LIMIT 1), 'ophalen', 'haal op', 'haalt op', 'haalt op', 'haalt op', 'halen op', 'haalde op', 'haalden op', 'opgehaald', 'hebben', 'op', false, false, false),
-- opruimen (to clean up) - separable
((SELECT id FROM t_verbs WHERE word='opruimen' LIMIT 1), 'opruimen', 'ruim op', 'ruimt op', 'ruimt op', 'ruimt op', 'ruimen op', 'ruimde op', 'ruimden op', 'opgeruimd', 'hebben', 'op', false, false, false),
-- opschieten (to hurry) - separable, strong verb
((SELECT id FROM t_verbs WHERE word='opschieten' LIMIT 1), 'opschieten', 'schiet op', 'schiet op', 'schiet op', 'schiet op', 'schieten op', 'schoot op', 'schoten op', 'opgeschoten', 'zijn', 'op', true, true, false),
-- organiseren (to organize) - regular
((SELECT id FROM t_verbs WHERE word='organiseren' LIMIT 1), 'organiseren', 'organiseer', 'organiseert', 'organiseert', 'organiseert', 'organiseren', 'organiseerde', 'organiseerden', 'georganiseerd', 'hebben', NULL, false, false, false),
-- passeren (to pass) - regular
((SELECT id FROM t_verbs WHERE word='passeren' LIMIT 1), 'passeren', 'passeer', 'passeert', 'passeert', 'passeert', 'passeren', 'passeerde', 'passeerden', 'gepasseerd', 'hebben', NULL, false, false, false),
-- plaatsen (to place) - regular
((SELECT id FROM t_verbs WHERE word='plaatsen' LIMIT 1), 'plaatsen', 'plaats', 'plaatst', 'plaatst', 'plaatst', 'plaatsen', 'plaatste', 'plaatsten', 'geplaatst', 'hebben', NULL, false, false, false),
-- planten (to plant) - regular
((SELECT id FROM t_verbs WHERE word='planten' LIMIT 1), 'planten', 'plant', 'plant', 'plant', 'plant', 'planten', 'plantte', 'plantten', 'geplant', 'hebben', NULL, false, false, false),
-- praten (to talk) - regular
((SELECT id FROM t_verbs WHERE word='praten' LIMIT 1), 'praten', 'praat', 'praat', 'praat', 'praat', 'praten', 'praatte', 'praatten', 'gepraat', 'hebben', NULL, false, false, false),
-- produceren (to produce) - regular
((SELECT id FROM t_verbs WHERE word='produceren' LIMIT 1), 'produceren', 'produceer', 'produceert', 'produceert', 'produceert', 'produceren', 'produceerde', 'produceerden', 'geproduceerd', 'hebben', NULL, false, false, false),
-- publiceren (to publish) - regular
((SELECT id FROM t_verbs WHERE word='publiceren' LIMIT 1), 'publiceren', 'publiceer', 'publiceert', 'publiceert', 'publiceert', 'publiceren', 'publiceerde', 'publiceerden', 'gepubliceerd', 'hebben', NULL, false, false, false),
-- realiseren (to realize) - regular
((SELECT id FROM t_verbs WHERE word='realiseren' LIMIT 1), 'realiseren', 'realiseer', 'realiseert', 'realiseert', 'realiseert', 'realiseren', 'realiseerde', 'realiseerden', 'gerealiseerd', 'hebben', NULL, false, false, false),
-- rennen (to run) - irregular
((SELECT id FROM t_verbs WHERE word='rennen' LIMIT 1), 'rennen', 'ren', 'rent', 'rent', 'rent', 'rennen', 'rende', 'renden', 'gerend', 'hebben', NULL, false, false, false),
-- rusten (to rest) - regular
((SELECT id FROM t_verbs WHERE word='rusten' LIMIT 1), 'rusten', 'rust', 'rust', 'rust', 'rust', 'rusten', 'rustte', 'rustten', 'gerust', 'hebben', NULL, false, false, false),
-- schoonmaken (to clean) - separable
((SELECT id FROM t_verbs WHERE word='schoonmaken' LIMIT 1), 'schoonmaken', 'maak schoon', 'maakt schoon', 'maakt schoon', 'maakt schoon', 'maken schoon', 'maakte schoon', 'maakten schoon', 'schoongemaakt', 'hebben', 'schoon', false, false, false),
-- slapen (to sleep) - strong verb
((SELECT id FROM t_verbs WHERE word='slapen' LIMIT 1), 'slapen', 'slaap', 'slaapt', 'slaapt', 'slaapt', 'slapen', 'sliep', 'sliepen', 'geslapen', 'hebben', NULL, true, true, false),
-- spreken (to speak) - strong verb
((SELECT id FROM t_verbs WHERE word='spreken' LIMIT 1), 'spreken', 'spreek', 'spreekt', 'spreekt', 'spreekt', 'spreken', 'sprak', 'spraken', 'gesproken', 'hebben', NULL, true, true, false),
-- staan (to stand) - irregular
((SELECT id FROM t_verbs WHERE word='staan' LIMIT 1), 'staan', 'sta', 'staat', 'staat', 'staat', 'staan', 'stond', 'stonden', 'gestaan', 'hebben', NULL, true, false, false),
-- stappen (to step) - regular
((SELECT id FROM t_verbs WHERE word='stappen' LIMIT 1), 'stappen', 'stap', 'stapt', 'stapt', 'stapt', 'stappen', 'stapte', 'stapten', 'gestapt', 'hebben', NULL, false, false, false),
-- stofzuigen (to vacuum) - separable, strong verb
((SELECT id FROM t_verbs WHERE word='stofzuigen' LIMIT 1), 'stofzuigen', 'zuig stof', 'zuigt stof', 'zuigt stof', 'zuigt stof', 'zuigen stof', 'zoog stof', 'zogen stof', 'gestofzuigd', 'hebben', 'stof', true, true, false),
-- stoppen (to stop) - regular
((SELECT id FROM t_verbs WHERE word='stoppen' LIMIT 1), 'stoppen', 'stop', 'stopt', 'stopt', 'stopt', 'stoppen', 'stopte', 'stopten', 'gestopt', 'hebben', NULL, false, false, false),
-- strijken (to iron) - strong verb
((SELECT id FROM t_verbs WHERE word='strijken' LIMIT 1), 'strijken', 'strijk', 'strijkt', 'strijkt', 'strijkt', 'strijken', 'streek', 'streken', 'gestreken', 'hebben', NULL, true, true, false),
-- studeren (to study) - regular
((SELECT id FROM t_verbs WHERE word='studeren' LIMIT 1), 'studeren', 'studeer', 'studeert', 'studeert', 'studeert', 'studeren', 'studeerde', 'studeerden', 'gestudeerd', 'hebben', NULL, false, false, false),
-- sturen (to send) - regular
((SELECT id FROM t_verbs WHERE word='sturen' LIMIT 1), 'sturen', 'stuur', 'stuurt', 'stuurt', 'stuurt', 'sturen', 'stuurde', 'stuurden', 'gestuurd', 'hebben', NULL, false, false, false),
-- vallen (to fall) - strong verb
((SELECT id FROM t_verbs WHERE word='vallen' LIMIT 1), 'vallen', 'val', 'valt', 'valt', 'valt', 'vallen', 'viel', 'vielen', 'gevallen', 'zijn', NULL, true, true, false),
-- vechten (to fight) - strong verb
((SELECT id FROM t_verbs WHERE word='vechten' LIMIT 1), 'vechten', 'vecht', 'vecht', 'vecht', 'vecht', 'vechten', 'vocht', 'vochten', 'gevochten', 'hebben', NULL, true, true, false),
-- verbieden (to forbid) - strong verb
((SELECT id FROM t_verbs WHERE word='verbieden' LIMIT 1), 'verbieden', 'verbied', 'verbiedt', 'verbiedt', 'verbiedt', 'verbieden', 'verbood', 'verboden', 'verboden', 'hebben', NULL, true, true, false),
-- verspreiden (to spread) - irregular
((SELECT id FROM t_verbs WHERE word='verspreiden' LIMIT 1), 'verspreiden', 'verspreid', 'verspreidt', 'verspreidt', 'verspreidt', 'verspreiden', 'verspreidde', 'verspreidden', 'verspreid', 'hebben', NULL, false, false, false),
-- vertellen (to tell) - regular
((SELECT id FROM t_verbs WHERE word='vertellen' LIMIT 1), 'vertellen', 'vertel', 'vertelt', 'vertelt', 'vertelt', 'vertellen', 'vertelde', 'vertelden', 'verteld', 'hebben', NULL, false, false, false),
-- vervullen (to fulfill) - regular
((SELECT id FROM t_verbs WHERE word='vervullen' LIMIT 1), 'vervullen', 'vervul', 'vervult', 'vervult', 'vervult', 'vervullen', 'vervulde', 'vervulden', 'vervuld', 'hebben', NULL, false, false, false),
-- vinden (to find) - strong verb
((SELECT id FROM t_verbs WHERE word='vinden' LIMIT 1), 'vinden', 'vind', 'vindt', 'vindt', 'vindt', 'vinden', 'vond', 'vonden', 'gevonden', 'hebben', NULL, true, true, false),
-- vissen (to fish) - regular
((SELECT id FROM t_verbs WHERE word='vissen' LIMIT 1), 'vissen', 'vis', 'vist', 'vist', 'vist', 'vissen', 'viste', 'visten', 'gevist', 'hebben', NULL, false, false, false),
-- vliegen (to fly) - strong verb
((SELECT id FROM t_verbs WHERE word='vliegen' LIMIT 1), 'vliegen', 'vlieg', 'vliegt', 'vliegt', 'vliegt', 'vliegen', 'vloog', 'vlogen', 'gevlogen', 'zijn', NULL, true, true, false),
-- vluchten (to flee) - regular
((SELECT id FROM t_verbs WHERE word='vluchten' LIMIT 1), 'vluchten', 'vlucht', 'vlucht', 'vlucht', 'vlucht', 'vluchten', 'vluchtte', 'vluchtten', 'gevlucht', 'zijn', NULL, false, false, false),
-- voelen (to feel) - regular
((SELECT id FROM t_verbs WHERE word='voelen' LIMIT 1), 'voelen', 'voel', 'voelt', 'voelt', 'voelt', 'voelen', 'voelde', 'voelden', 'gevoeld', 'hebben', NULL, false, false, false),
-- vullen (to fill) - regular
((SELECT id FROM t_verbs WHERE word='vullen' LIMIT 1), 'vullen', 'vul', 'vult', 'vult', 'vult', 'vullen', 'vulde', 'vulden', 'gevuld', 'hebben', NULL, false, false, false),
-- wachten (to wait) - regular
((SELECT id FROM t_verbs WHERE word='wachten' LIMIT 1), 'wachten', 'wacht', 'wacht', 'wacht', 'wacht', 'wachten', 'wachtte', 'wachtten', 'gewacht', 'hebben', NULL, false, false, false),
-- wandelen (to walk) - regular
((SELECT id FROM t_verbs WHERE word='wandelen' LIMIT 1), 'wandelen', 'wandel', 'wandelt', 'wandelt', 'wandelt', 'wandelen', 'wandelde', 'wandelden', 'gewandeld', 'hebben', NULL, false, false, false),
-- wassen (to wash) - regular
((SELECT id FROM t_verbs WHERE word='wassen' LIMIT 1), 'wassen', 'was', 'wast', 'wast', 'wast', 'wassen', 'waste', 'wasten', 'gewassen', 'hebben', NULL, false, false, false),
-- wensen (to wish) - regular
((SELECT id FROM t_verbs WHERE word='wensen' LIMIT 1), 'wensen', 'wens', 'wenst', 'wenst', 'wenst', 'wensen', 'wenste', 'wensten', 'gewenst', 'hebben', NULL, false, false, false),
-- werken (to work) - regular
((SELECT id FROM t_verbs WHERE word='werken' LIMIT 1), 'werken', 'werk', 'werkt', 'werkt', 'werkt', 'werken', 'werkte', 'werkten', 'gewerkt', 'hebben', NULL, false, false, false),
-- weten (to know) - irregular
((SELECT id FROM t_verbs WHERE word='weten' LIMIT 1), 'weten', 'weet', 'weet', 'weet', 'weet', 'weten', 'wist', 'wisten', 'geweten', 'hebben', NULL, true, false, false),
-- winnen (to win) - strong verb
((SELECT id FROM t_verbs WHERE word='winnen' LIMIT 1), 'winnen', 'win', 'wint', 'wint', 'wint', 'winnen', 'won', 'wonnen', 'gewonnen', 'hebben', NULL, true, true, false),
-- worden (to become) - irregular
((SELECT id FROM t_verbs WHERE word='worden' LIMIT 1), 'worden', 'word', 'wordt', 'wordt', 'wordt', 'worden', 'werd', 'werden', 'geworden', 'zijn', NULL, true, false, false),
-- zeggen (to say) - irregular
((SELECT id FROM t_verbs WHERE word='zeggen' LIMIT 1), 'zeggen', 'zeg', 'zegt', 'zegt', 'zegt', 'zeggen', 'zei', 'zeiden', 'gezegd', 'hebben', NULL, true, false, false),
-- zenden (to send) - irregular
((SELECT id FROM t_verbs WHERE word='zenden' LIMIT 1), 'zenden', 'zend', 'zendt', 'zendt', 'zendt', 'zenden', 'zond', 'zonden', 'gezonden', 'hebben', NULL, true, false, false),
-- zien (to see) - strong verb
((SELECT id FROM t_verbs WHERE word='zien' LIMIT 1), 'zien', 'zie', 'ziet', 'ziet', 'ziet', 'zien', 'zag', 'zagen', 'gezien', 'hebben', NULL, true, true, false),
-- zingen (to sing) - strong verb
((SELECT id FROM t_verbs WHERE word='zingen' LIMIT 1), 'zingen', 'zing', 'zingt', 'zingt', 'zingt', 'zingen', 'zong', 'zongen', 'gezongen', 'hebben', NULL, true, true, false),
-- zitten (to sit) - strong verb
((SELECT id FROM t_verbs WHERE word='zitten' LIMIT 1), 'zitten', 'zit', 'zit', 'zit', 'zit', 'zitten', 'zat', 'zaten', 'gezeten', 'hebben', NULL, true, true, false),
-- zullen (shall) - modal verb
((SELECT id FROM t_verbs WHERE word='zullen' LIMIT 1), 'zullen', 'zal', 'zult', 'zult', 'zal', 'zullen', 'zou', 'zouden', 'gezuld', 'hebben', NULL, true, false, true)
ON CONFLICT (word_id) DO NOTHING;

-- Clean up temporary table
DROP TABLE t_verbs;

-- Insert sample users for testing
INSERT INTO app_users (username, email, level_id) VALUES 
('demo_user', 'demo@example.com', (SELECT id FROM levels WHERE level = 'A2')),
('test_user', 'test@example.com', (SELECT id FROM levels WHERE level = 'A1'))
ON CONFLICT (username) DO NOTHING;

-- Note: Level target counts can be added later if needed
-- Currently using actual word counts from the database

-- Log seeding results
DO $$
BEGIN
    RAISE NOTICE '=== SEEDING RESULTS ===';
    RAISE NOTICE 'Levels: % entries', (SELECT COUNT(*) FROM levels);
    RAISE NOTICE 'Categories: % entries', (SELECT COUNT(*) FROM categories);
    RAISE NOTICE 'Words: % entries', (SELECT COUNT(*) FROM words);
    RAISE NOTICE 'Category-Word associations: % entries', (SELECT COUNT(*) FROM category_words);
    RAISE NOTICE 'Nouns: % entries', (SELECT COUNT(*) FROM nouns);
    RAISE NOTICE 'Numerals: % entries', (SELECT COUNT(*) FROM numerals);
    RAISE NOTICE 'Adjectives: % entries', (SELECT COUNT(*) FROM adjectives);
    RAISE NOTICE 'Verbs: % entries', (SELECT COUNT(*) FROM verbs);
    RAISE NOTICE 'App Users: % entries', (SELECT COUNT(*) FROM app_users);
    RAISE NOTICE '========================';
END $$;


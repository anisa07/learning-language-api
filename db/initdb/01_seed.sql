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

CREATE TEMP TABLE temp_nouns AS
SELECT id, word
FROM words
WHERE part_of_speech = 'noun';

-- Insert noun forms for Dutch nouns from easy-vocabulary.csv
-- Note: Grammatical forms (articles, diminutives, plurals) need to be filled in manually
INSERT INTO nouns
(word_id, indefinite_article, diminutive, plural)
VALUES
((SELECT id FROM temp_nouns WHERE word='aardappel' LIMIT 1), 'de', 'aardappeltje', 'aardappels'),
((SELECT id FROM temp_nouns WHERE word='actie' LIMIT 1), 'de', 'actietje', 'acties'),
((SELECT id FROM temp_nouns WHERE word='activiteit' LIMIT 1), 'de', 'activiteitje', 'activiteiten'),
((SELECT id FROM temp_nouns WHERE word='adres' LIMIT 1), 'het', 'adresje', 'adressen'),
((SELECT id FROM temp_nouns WHERE word='advies' LIMIT 1), 'het', 'adviestje', 'adviezen'),
((SELECT id FROM temp_nouns WHERE word='afbeelding' LIMIT 1), 'de', 'afbeeldingetje', 'afbeeldingen'),
((SELECT id FROM temp_nouns WHERE word='afkomst' LIMIT 1), 'de', 'afkomstje', 'afkomsten'),
((SELECT id FROM temp_nouns WHERE word='afwasmachine' LIMIT 1), 'de', 'afwasmachinetje', 'afwasmachines'),
((SELECT id FROM temp_nouns WHERE word='agent' LIMIT 1), 'de', 'agentje', 'agenten'),
((SELECT id FROM temp_nouns WHERE word='antwoord' LIMIT 1), 'het', 'antwoordje', 'antwoorden'),
((SELECT id FROM temp_nouns WHERE word='argument' LIMIT 1), 'het', 'argumentje', 'argumenten'),
((SELECT id FROM temp_nouns WHERE word='arm' LIMIT 1), 'de', 'armpje', 'armen'),
((SELECT id FROM temp_nouns WHERE word='artikel' LIMIT 1), 'het', 'artikeltje', 'artikelen'),
((SELECT id FROM temp_nouns WHERE word='aspect' LIMIT 1), 'het', 'aspectje', 'aspecten'),
((SELECT id FROM temp_nouns WHERE word='auteur' LIMIT 1), 'de', 'auteurtje', 'auteurs'),
((SELECT id FROM temp_nouns WHERE word='avondeten' LIMIT 1), 'het', 'avondetentje', 'avondeten'),
((SELECT id FROM temp_nouns WHERE word='baan' LIMIT 1), 'de', 'baantje', 'banen'),
((SELECT id FROM temp_nouns WHERE word='baas' LIMIT 1), 'de', 'baasje', 'bazen'),
((SELECT id FROM temp_nouns WHERE word='baby' LIMIT 1), 'de', 'babytje', 'baby''s'),
((SELECT id FROM temp_nouns WHERE word='bank' LIMIT 1), 'de', 'bankje', 'banken'),
((SELECT id FROM temp_nouns WHERE word='basis' LIMIT 1), 'de', 'basisje', 'bases'),
((SELECT id FROM temp_nouns WHERE word='bed' LIMIT 1), 'het', 'bedje', 'bedden'),
((SELECT id FROM temp_nouns WHERE word='bedrijf' LIMIT 1), 'het', 'bedrijfje', 'bedrijven'),
((SELECT id FROM temp_nouns WHERE word='begin' LIMIT 1), 'het', 'beginnetje', 'begins'),
((SELECT id FROM temp_nouns WHERE word='beroep' LIMIT 1), 'het', 'beroepje', 'beroepen'),
((SELECT id FROM temp_nouns WHERE word='bier' LIMIT 1), 'het', 'biertje', 'bieren'),
((SELECT id FROM temp_nouns WHERE word='bijbaantje' LIMIT 1), 'het', 'bijbaantje', 'bijbaantjes'),
((SELECT id FROM temp_nouns WHERE word='bloed' LIMIT 1), 'het', 'bloedje', 'bloed'),
((SELECT id FROM temp_nouns WHERE word='bodem' LIMIT 1), 'de', 'bodempje', 'bodems'),
((SELECT id FROM temp_nouns WHERE word='boek' LIMIT 1), 'het', 'boekje', 'boeken'),
((SELECT id FROM temp_nouns WHERE word='boodschap' LIMIT 1), 'de', 'boodschapje', 'boodschappen'),
((SELECT id FROM temp_nouns WHERE word='boot' LIMIT 1), 'de', 'bootje', 'boten'),
((SELECT id FROM temp_nouns WHERE word='broer' LIMIT 1), 'de', 'broertje', 'broers'),
((SELECT id FROM temp_nouns WHERE word='brood' LIMIT 1), 'het', 'broodje', 'broden'),
((SELECT id FROM temp_nouns WHERE word='bus' LIMIT 1), 'de', 'busje', 'bussen'),
((SELECT id FROM temp_nouns WHERE word='café' LIMIT 1), 'het', 'cafeetje', 'cafés'),
((SELECT id FROM temp_nouns WHERE word='categorie' LIMIT 1), 'de', 'categorietje', 'categorieën'),
((SELECT id FROM temp_nouns WHERE word='centrum' LIMIT 1), 'het', 'centrumpje', 'centrums'),
((SELECT id FROM temp_nouns WHERE word='collega' LIMIT 1), 'de', 'collegatje', 'collega''s'),
((SELECT id FROM temp_nouns WHERE word='combinatie' LIMIT 1), 'de', 'combinatietje', 'combinaties'),
((SELECT id FROM temp_nouns WHERE word='communicatie' LIMIT 1), 'de', 'communicatietje', 'communicaties'),
((SELECT id FROM temp_nouns WHERE word='computer' LIMIT 1), 'de', 'computertje', 'computers'),
((SELECT id FROM temp_nouns WHERE word='conclusie' LIMIT 1), 'de', 'conclusietje', 'conclusies'),
((SELECT id FROM temp_nouns WHERE word='consequentie' LIMIT 1), 'de', 'consequentietje', 'consequenties'),
((SELECT id FROM temp_nouns WHERE word='contact' LIMIT 1), 'het', 'contactje', 'contacten'),
((SELECT id FROM temp_nouns WHERE word='crisis' LIMIT 1), 'de', 'crisisje', 'crises'),
((SELECT id FROM temp_nouns WHERE word='cultuur' LIMIT 1), 'de', 'cultuurtje', 'culturen'),
((SELECT id FROM temp_nouns WHERE word='dag' LIMIT 1), 'de', 'dagje', 'dagen'),
((SELECT id FROM temp_nouns WHERE word='detail' LIMIT 1), 'het', 'detailtje', 'details'),
((SELECT id FROM temp_nouns WHERE word='deur' LIMIT 1), 'de', 'deurtje', 'deuren'),
((SELECT id FROM temp_nouns WHERE word='ding' LIMIT 1), 'het', 'dingetje', 'dingen'),
((SELECT id FROM temp_nouns WHERE word='directeur' LIMIT 1), 'de', 'directeurtje', 'directeuren'),
((SELECT id FROM temp_nouns WHERE word='discussie' LIMIT 1), 'de', 'discussietje', 'discussies'),
((SELECT id FROM temp_nouns WHERE word='dochter' LIMIT 1), 'de', 'dochtertje', 'dochters'),
((SELECT id FROM temp_nouns WHERE word='dokter' LIMIT 1), 'de', 'doktertje', 'dokters'),
((SELECT id FROM temp_nouns WHERE word='dood' LIMIT 1), 'de', 'doodje', 'doden'),
((SELECT id FROM temp_nouns WHERE word='dorst' LIMIT 1), 'de', 'dorstje', 'dorst'),
((SELECT id FROM temp_nouns WHERE word='drinken' LIMIT 1), 'het', 'drinkje', 'drankjes'),
((SELECT id FROM temp_nouns WHERE word='droom' LIMIT 1), 'de', 'droompje', 'dromen'),
((SELECT id FROM temp_nouns WHERE word='economie' LIMIT 1), 'de', 'economietje', 'economieën'),
((SELECT id FROM temp_nouns WHERE word='effect' LIMIT 1), 'het', 'effectje', 'effecten'),
((SELECT id FROM temp_nouns WHERE word='ei' LIMIT 1), 'het', 'eitje', 'eieren'),
((SELECT id FROM temp_nouns WHERE word='eiland' LIMIT 1), 'het', 'eilandje', 'eilanden'),
((SELECT id FROM temp_nouns WHERE word='eind' LIMIT 1), 'het', 'eindje', 'einden'),
((SELECT id FROM temp_nouns WHERE word='emotie' LIMIT 1), 'de', 'emotietje', 'emoties'),
((SELECT id FROM temp_nouns WHERE word='energie' LIMIT 1), 'de', 'energietje', 'energieën'),
((SELECT id FROM temp_nouns WHERE word='eten' LIMIT 1), 'het', 'etentje', 'etens'),
((SELECT id FROM temp_nouns WHERE word='examen' LIMIT 1), 'het', 'examentje', 'examens'),
((SELECT id FROM temp_nouns WHERE word='experiment' LIMIT 1), 'het', 'experimentje', 'experimenten'),
((SELECT id FROM temp_nouns WHERE word='fabriek' LIMIT 1), 'de', 'fabriekje', 'fabrieken'),
((SELECT id FROM temp_nouns WHERE word='factor' LIMIT 1), 'de', 'factortje', 'factoren'),
((SELECT id FROM temp_nouns WHERE word='familie' LIMIT 1), 'de', 'familietje', 'families'),
((SELECT id FROM temp_nouns WHERE word='fase' LIMIT 1), 'de', 'fasetje', 'fases'),
((SELECT id FROM temp_nouns WHERE word='feit' LIMIT 1), 'het', 'feitje', 'feiten'),
((SELECT id FROM temp_nouns WHERE word='figuur' LIMIT 1), 'de', 'figuurtje', 'figuren'),
((SELECT id FROM temp_nouns WHERE word='film' LIMIT 1), 'de', 'filmpje', 'films'),
((SELECT id FROM temp_nouns WHERE word='foto' LIMIT 1), 'de', 'fotootje', 'foto''s'),
((SELECT id FROM temp_nouns WHERE word='fruit' LIMIT 1), 'het', 'fruitje', 'fruit'),
((SELECT id FROM temp_nouns WHERE word='functie' LIMIT 1), 'de', 'functietje', 'functies'),
((SELECT id FROM temp_nouns WHERE word='gast' LIMIT 1), 'de', 'gastje', 'gasten'),
((SELECT id FROM temp_nouns WHERE word='geluk' LIMIT 1), 'het', 'gelukje', 'geluk'),
((SELECT id FROM temp_nouns WHERE word='generatie' LIMIT 1), 'de', 'generatietje', 'generaties'),
((SELECT id FROM temp_nouns WHERE word='gerecht' LIMIT 1), 'het', 'gerechtje', 'gerechten'),
((SELECT id FROM temp_nouns WHERE word='getal' LIMIT 1), 'het', 'getalletje', 'getallen'),
((SELECT id FROM temp_nouns WHERE word='gevoel' LIMIT 1), 'het', 'gevoeltje', 'gevoelens'),
((SELECT id FROM temp_nouns WHERE word='glas' LIMIT 1), 'het', 'glaasje', 'glazen'),
((SELECT id FROM temp_nouns WHERE word='goed' LIMIT 1), 'het', 'goedje', 'goederen'),
((SELECT id FROM temp_nouns WHERE word='gras' LIMIT 1), 'het', 'grasje', 'grassen'),
((SELECT id FROM temp_nouns WHERE word='groep' LIMIT 1), 'de', 'groepje', 'groepen'),
((SELECT id FROM temp_nouns WHERE word='haar' LIMIT 1), 'het', 'haartje', 'haren'),
((SELECT id FROM temp_nouns WHERE word='hand' LIMIT 1), 'de', 'handje', 'handen'),
((SELECT id FROM temp_nouns WHERE word='hart' LIMIT 1), 'het', 'hartje', 'harten'),
((SELECT id FROM temp_nouns WHERE word='helft' LIMIT 1), 'de', 'helftje', 'helften'),
((SELECT id FROM temp_nouns WHERE word='herfst' LIMIT 1), 'de', 'herfstje', 'herfsten'),
((SELECT id FROM temp_nouns WHERE word='hoed' LIMIT 1), 'de', 'hoedje', 'hoeden'),
((SELECT id FROM temp_nouns WHERE word='holland' LIMIT 1), 'het', 'hollandje', 'holland'),
((SELECT id FROM temp_nouns WHERE word='honger' LIMIT 1), 'de', 'hongertje', 'honger'),
((SELECT id FROM temp_nouns WHERE word='hoop' LIMIT 1), 'de', 'hoopje', 'hopen'),
((SELECT id FROM temp_nouns WHERE word='hotel' LIMIT 1), 'het', 'hoteltje', 'hotels'),
((SELECT id FROM temp_nouns WHERE word='huis' LIMIT 1), 'het', 'huisje', 'huizen'),
((SELECT id FROM temp_nouns WHERE word='hulp' LIMIT 1), 'de', 'hulpje', 'hulp'),
((SELECT id FROM temp_nouns WHERE word='hut' LIMIT 1), 'de', 'hutje', 'hutten'),
((SELECT id FROM temp_nouns WHERE word='idee' LIMIT 1), 'het', 'ideetje', 'ideeën'),
((SELECT id FROM temp_nouns WHERE word='individu' LIMIT 1), 'het', 'individutje', 'individuen'),
((SELECT id FROM temp_nouns WHERE word='informatie' LIMIT 1), 'de', 'informatietje', 'informatie'),
((SELECT id FROM temp_nouns WHERE word='initiatief' LIMIT 1), 'het', 'initiatiefje', 'initiatieven'),
((SELECT id FROM temp_nouns WHERE word='instrument' LIMIT 1), 'het', 'instrumentje', 'instrumenten'),
((SELECT id FROM temp_nouns WHERE word='invloed' LIMIT 1), 'de', 'invloedje', 'invloeden'),
((SELECT id FROM temp_nouns WHERE word='jaar' LIMIT 1), 'het', 'jaartje', 'jaren'),
((SELECT id FROM temp_nouns WHERE word='jongeman' LIMIT 1), 'de', 'jongemannetje', 'jongemannen'),
((SELECT id FROM temp_nouns WHERE word='juni' LIMIT 1), 'de', 'junitje', 'juni'),
((SELECT id FROM temp_nouns WHERE word='kaas' LIMIT 1), 'de', 'kaasje', 'kazen'),
((SELECT id FROM temp_nouns WHERE word='kamp' LIMIT 1), 'het', 'kampje', 'kampen'),
((SELECT id FROM temp_nouns WHERE word='karakter' LIMIT 1), 'het', 'karaktertje', 'karakters'),
((SELECT id FROM temp_nouns WHERE word='kat' LIMIT 1), 'de', 'katje', 'katten'),
((SELECT id FROM temp_nouns WHERE word='keer' LIMIT 1), 'de', 'keertje', 'keren'),
((SELECT id FROM temp_nouns WHERE word='kennis' LIMIT 1), 'de', 'kennisje', 'kennis'),
((SELECT id FROM temp_nouns WHERE word='kilometer' LIMIT 1), 'de', 'kilometertje', 'kilometers'),
((SELECT id FROM temp_nouns WHERE word='kind' LIMIT 1), 'het', 'kindje', 'kinderen'),
((SELECT id FROM temp_nouns WHERE word='klant' LIMIT 1), 'de', 'klantje', 'klanten'),
((SELECT id FROM temp_nouns WHERE word='klas' LIMIT 1), 'de', 'klasje', 'klassen'),
((SELECT id FROM temp_nouns WHERE word='kleur' LIMIT 1), 'de', 'kleurtje', 'kleuren'),
((SELECT id FROM temp_nouns WHERE word='knie' LIMIT 1), 'de', 'knietje', 'knieën'),
((SELECT id FROM temp_nouns WHERE word='koffie' LIMIT 1), 'de', 'koffietje', 'koffie'),
((SELECT id FROM temp_nouns WHERE word='koning' LIMIT 1), 'de', 'koninkje', 'koningen'),
((SELECT id FROM temp_nouns WHERE word='kosten' LIMIT 1), 'de', 'kostentje', 'kosten'),
((SELECT id FROM temp_nouns WHERE word='kruis' LIMIT 1), 'het', 'kruisje', 'kruisen'),
((SELECT id FROM temp_nouns WHERE word='kust' LIMIT 1), 'de', 'kustje', 'kusten'),
((SELECT id FROM temp_nouns WHERE word='kwaliteit' LIMIT 1), 'de', 'kwaliteitje', 'kwaliteiten'),
((SELECT id FROM temp_nouns WHERE word='landschap' LIMIT 1), 'het', 'landschapje', 'landschappen'),
((SELECT id FROM temp_nouns WHERE word='leider' LIMIT 1), 'de', 'leidertje', 'leiders'),
((SELECT id FROM temp_nouns WHERE word='leiding' LIMIT 1), 'de', 'leidingetje', 'leidingen'),
((SELECT id FROM temp_nouns WHERE word='lente' LIMIT 1), 'de', 'lentetje', 'lentes'),
((SELECT id FROM temp_nouns WHERE word='leren' LIMIT 1), 'het', 'leertje', 'leren'),
((SELECT id FROM temp_nouns WHERE word='leven' LIMIT 1), 'het', 'leventje', 'levens'),
((SELECT id FROM temp_nouns WHERE word='licht' LIMIT 1), 'het', 'lichtje', 'lichten'),
((SELECT id FROM temp_nouns WHERE word='liefde' LIMIT 1), 'de', 'liefdetje', 'liefdes'),
((SELECT id FROM temp_nouns WHERE word='lijst' LIMIT 1), 'de', 'lijstje', 'lijsten'),
((SELECT id FROM temp_nouns WHERE word='lip' LIMIT 1), 'de', 'lipje', 'lippen'),
((SELECT id FROM temp_nouns WHERE word='literatuur' LIMIT 1), 'de', 'literatuurtje', 'literatuur'),
((SELECT id FROM temp_nouns WHERE word='luitenant' LIMIT 1), 'de', 'luitenantje', 'luitenants'),
((SELECT id FROM temp_nouns WHERE word='maaltijd' LIMIT 1), 'de', 'maaltijdje', 'maaltijden'),
((SELECT id FROM temp_nouns WHERE word='maan' LIMIT 1), 'de', 'maantje', 'manen'),
((SELECT id FROM temp_nouns WHERE word='maand' LIMIT 1), 'de', 'maandje', 'maanden'),
((SELECT id FROM temp_nouns WHERE word='machine' LIMIT 1), 'de', 'machinetje', 'machines'),
((SELECT id FROM temp_nouns WHERE word='mama' LIMIT 1), 'de', 'mamaatje', 'mama''s'),
((SELECT id FROM temp_nouns WHERE word='man' LIMIT 1), 'de', 'mannetje', 'mannen'),
((SELECT id FROM temp_nouns WHERE word='markt' LIMIT 1), 'de', 'marktje', 'markten'),
((SELECT id FROM temp_nouns WHERE word='materiaal' LIMIT 1), 'het', 'materiaaltje', 'materialen'),
((SELECT id FROM temp_nouns WHERE word='meer' LIMIT 1), 'het', 'meertje', 'meren'),
((SELECT id FROM temp_nouns WHERE word='meester' LIMIT 1), 'de', 'meestertje', 'meesters'),
((SELECT id FROM temp_nouns WHERE word='meter' LIMIT 1), 'de', 'metertje', 'meters'),
((SELECT id FROM temp_nouns WHERE word='methode' LIMIT 1), 'de', 'methodetje', 'methodes'),
((SELECT id FROM temp_nouns WHERE word='minister' LIMIT 1), 'de', 'ministertje', 'ministers'),
((SELECT id FROM temp_nouns WHERE word='minuut' LIMIT 1), 'de', 'minuutje', 'minuten'),
((SELECT id FROM temp_nouns WHERE word='moeder' LIMIT 1), 'de', 'moedertje', 'moeders'),
((SELECT id FROM temp_nouns WHERE word='moment' LIMIT 1), 'het', 'momentje', 'momenten'),
((SELECT id FROM temp_nouns WHERE word='mond' LIMIT 1), 'de', 'mondje', 'monden'),
((SELECT id FROM temp_nouns WHERE word='motief' LIMIT 1), 'het', 'motiefje', 'motieven'),
((SELECT id FROM temp_nouns WHERE word='museum' LIMIT 1), 'het', 'museumpje', 'museums'),
((SELECT id FROM temp_nouns WHERE word='muziek' LIMIT 1), 'de', 'muziekje', 'muziek'),
((SELECT id FROM temp_nouns WHERE word='naam' LIMIT 1), 'de', 'naampje', 'namen'),
((SELECT id FROM temp_nouns WHERE word='nacht' LIMIT 1), 'de', 'nachtje', 'nachten'),
((SELECT id FROM temp_nouns WHERE word='natuur' LIMIT 1), 'de', 'natuurtje', 'natuur'),
((SELECT id FROM temp_nouns WHERE word='neef' LIMIT 1), 'de', 'neefje', 'neven'),
((SELECT id FROM temp_nouns WHERE word='nek' LIMIT 1), 'de', 'nekje', 'nekken'),
((SELECT id FROM temp_nouns WHERE word='neus' LIMIT 1), 'de', 'neusje', 'neuzen'),
((SELECT id FROM temp_nouns WHERE word='nicht' LIMIT 1), 'de', 'nichtje', 'nichten'),
((SELECT id FROM temp_nouns WHERE word='noorden' LIMIT 1), 'het', 'noordentje', 'noorden'),
((SELECT id FROM temp_nouns WHERE word='nummer' LIMIT 1), 'het', 'nummertje', 'nummers'),
((SELECT id FROM temp_nouns WHERE word='object' LIMIT 1), 'het', 'objectje', 'objecten'),
((SELECT id FROM temp_nouns WHERE word='officier' LIMIT 1), 'de', 'officiertje', 'officieren'),
((SELECT id FROM temp_nouns WHERE word='oktober' LIMIT 1), 'de', 'oktobertje', 'oktobers'),
((SELECT id FROM temp_nouns WHERE word='olie' LIMIT 1), 'de', 'olietje', 'oliën'),
((SELECT id FROM temp_nouns WHERE word='oma' LIMIT 1), 'de', 'omaatje', 'oma''s'),
((SELECT id FROM temp_nouns WHERE word='oom' LIMIT 1), 'de', 'oompje', 'ooms'),
((SELECT id FROM temp_nouns WHERE word='oor' LIMIT 1), 'het', 'oortje', 'oren'),
((SELECT id FROM temp_nouns WHERE word='opa' LIMIT 1), 'de', 'opaatje', 'opa''s'),
((SELECT id FROM temp_nouns WHERE word='operatie' LIMIT 1), 'de', 'operatietje', 'operaties'),
((SELECT id FROM temp_nouns WHERE word='orgaan' LIMIT 1), 'het', 'orgaantje', 'organen'),
((SELECT id FROM temp_nouns WHERE word='organisatie' LIMIT 1), 'de', 'organisatietje', 'organisaties'),
((SELECT id FROM temp_nouns WHERE word='ouder' LIMIT 1), 'de', 'oudertje', 'ouders'),
((SELECT id FROM temp_nouns WHERE word='pad' LIMIT 1), 'het', 'paadje', 'paden'),
((SELECT id FROM temp_nouns WHERE word='papier' LIMIT 1), 'het', 'papiertje', 'papieren'),
((SELECT id FROM temp_nouns WHERE word='partner' LIMIT 1), 'de', 'partnertje', 'partners'),
((SELECT id FROM temp_nouns WHERE word='pas' LIMIT 1), 'de', 'pasje', 'passen'),
((SELECT id FROM temp_nouns WHERE word='patiënt' LIMIT 1), 'de', 'patiëntje', 'patiënten'),
((SELECT id FROM temp_nouns WHERE word='patroon' LIMIT 1), 'het', 'patroontje', 'patronen'),
((SELECT id FROM temp_nouns WHERE word='periode' LIMIT 1), 'de', 'periodetje', 'periodes'),
((SELECT id FROM temp_nouns WHERE word='pers' LIMIT 1), 'de', 'persje', 'pers'),
((SELECT id FROM temp_nouns WHERE word='persoon' LIMIT 1), 'de', 'persoontje', 'personen'),
((SELECT id FROM temp_nouns WHERE word='persoonlijkheid' LIMIT 1), 'de', 'persoonlijkheidje', 'persoonlijkheden'),
((SELECT id FROM temp_nouns WHERE word='pijn' LIMIT 1), 'de', 'pijntje', 'pijnen'),
((SELECT id FROM temp_nouns WHERE word='plaat' LIMIT 1), 'de', 'plaatje', 'platen'),
((SELECT id FROM temp_nouns WHERE word='plaats' LIMIT 1), 'de', 'plaatsje', 'plaatsen'),
((SELECT id FROM temp_nouns WHERE word='plan' LIMIT 1), 'het', 'plannetje', 'plannen'),
((SELECT id FROM temp_nouns WHERE word='plant' LIMIT 1), 'de', 'plantje', 'planten'),
((SELECT id FROM temp_nouns WHERE word='plezier' LIMIT 1), 'het', 'pleziertje', 'plezier'),
((SELECT id FROM temp_nouns WHERE word='politie' LIMIT 1), 'de', 'politietje', 'politie'),
((SELECT id FROM temp_nouns WHERE word='positie' LIMIT 1), 'de', 'positietje', 'posities'),
((SELECT id FROM temp_nouns WHERE word='pot' LIMIT 1), 'de', 'potje', 'potten'),
((SELECT id FROM temp_nouns WHERE word='praktijk' LIMIT 1), 'de', 'praktijkje', 'praktijken'),
((SELECT id FROM temp_nouns WHERE word='president' LIMIT 1), 'de', 'presidentje', 'presidenten'),
((SELECT id FROM temp_nouns WHERE word='prijs' LIMIT 1), 'de', 'prijsje', 'prijzen'),
((SELECT id FROM temp_nouns WHERE word='probleem' LIMIT 1), 'het', 'probleempje', 'problemen'),
((SELECT id FROM temp_nouns WHERE word='procent' LIMIT 1), 'het', 'procentje', 'procenten'),
((SELECT id FROM temp_nouns WHERE word='proces' LIMIT 1), 'het', 'procesje', 'processen'),
((SELECT id FROM temp_nouns WHERE word='product' LIMIT 1), 'het', 'productje', 'producten'),
((SELECT id FROM temp_nouns WHERE word='productie' LIMIT 1), 'de', 'productietje', 'producties'),
((SELECT id FROM temp_nouns WHERE word='programma' LIMIT 1), 'het', 'programmaatje', 'programma''s'),
((SELECT id FROM temp_nouns WHERE word='project' LIMIT 1), 'het', 'projectje', 'projecten'),
((SELECT id FROM temp_nouns WHERE word='provincie' LIMIT 1), 'de', 'provincietje', 'provincies'),
((SELECT id FROM temp_nouns WHERE word='psychologie' LIMIT 1), 'de', 'psychologietje', 'psychologie'),
((SELECT id FROM temp_nouns WHERE word='psycholoog' LIMIT 1), 'de', 'psycholoogje', 'psychologen'),
((SELECT id FROM temp_nouns WHERE word='radio' LIMIT 1), 'de', 'radiootje', 'radio''s'),
((SELECT id FROM temp_nouns WHERE word='reactie' LIMIT 1), 'de', 'reactietje', 'reacties'),
((SELECT id FROM temp_nouns WHERE word='reden' LIMIT 1), 'de', 'redentje', 'redenen'),
((SELECT id FROM temp_nouns WHERE word='regel' LIMIT 1), 'de', 'regeltje', 'regels'),
((SELECT id FROM temp_nouns WHERE word='relatie' LIMIT 1), 'de', 'relatietje', 'relaties'),
((SELECT id FROM temp_nouns WHERE word='restaurant' LIMIT 1), 'het', 'restaurantje', 'restaurants'),
((SELECT id FROM temp_nouns WHERE word='resultaat' LIMIT 1), 'het', 'resultaatje', 'resultaten'),
((SELECT id FROM temp_nouns WHERE word='rijk' LIMIT 1), 'het', 'rijkje', 'rijken'),
((SELECT id FROM temp_nouns WHERE word='risico' LIMIT 1), 'het', 'risicootje', 'risico''s'),
((SELECT id FROM temp_nouns WHERE word='rivier' LIMIT 1), 'de', 'riviertje', 'rivieren'),
((SELECT id FROM temp_nouns WHERE word='roepnaam' LIMIT 1), 'de', 'roepnaamtje', 'roepnamen'),
((SELECT id FROM temp_nouns WHERE word='rol' LIMIT 1), 'de', 'rolletje', 'rollen'),
((SELECT id FROM temp_nouns WHERE word='rommel' LIMIT 1), 'de', 'rommeltje', 'rommel'),
((SELECT id FROM temp_nouns WHERE word='rust' LIMIT 1), 'de', 'rustje', 'rust'),
((SELECT id FROM temp_nouns WHERE word='schaduw' LIMIT 1), 'de', 'schaduwt je', 'schaduwen'),
((SELECT id FROM temp_nouns WHERE word='schoen' LIMIT 1), 'de', 'schoentje', 'schoenen'),
((SELECT id FROM temp_nouns WHERE word='school' LIMIT 1), 'de', 'schooltje', 'scholen'),
((SELECT id FROM temp_nouns WHERE word='schouder' LIMIT 1), 'de', 'schoudertje', 'schouders'),
((SELECT id FROM temp_nouns WHERE word='seconde' LIMIT 1), 'de', 'secondetje', 'seconden'),
((SELECT id FROM temp_nouns WHERE word='sector' LIMIT 1), 'de', 'sectortje', 'sectoren'),
((SELECT id FROM temp_nouns WHERE word='sigaret' LIMIT 1), 'de', 'sigaretje', 'sigaretten'),
((SELECT id FROM temp_nouns WHERE word='slaap' LIMIT 1), 'de', 'slaapje', 'slaap'),
((SELECT id FROM temp_nouns WHERE word='sneeuw' LIMIT 1), 'de', 'sneeuwt je', 'sneeuw'),
((SELECT id FROM temp_nouns WHERE word='soort' LIMIT 1), 'de', 'soortje', 'soorten'),
((SELECT id FROM temp_nouns WHERE word='staan' LIMIT 1), 'de', 'staantje', 'stands'),
((SELECT id FROM temp_nouns WHERE word='staat' LIMIT 1), 'de', 'staatje', 'staten'),
((SELECT id FROM temp_nouns WHERE word='stap' LIMIT 1), 'de', 'stapje', 'stappen'),
((SELECT id FROM temp_nouns WHERE word='station' LIMIT 1), 'het', 'stationnetje', 'stations'),
((SELECT id FROM temp_nouns WHERE word='steen' LIMIT 1), 'de', 'steentje', 'stenen'),
((SELECT id FROM temp_nouns WHERE word='ster' LIMIT 1), 'de', 'sterretje', 'sterren'),
((SELECT id FROM temp_nouns WHERE word='stijl' LIMIT 1), 'de', 'stijltje', 'stijlen'),
((SELECT id FROM temp_nouns WHERE word='straat' LIMIT 1), 'de', 'straatje', 'straten'),
((SELECT id FROM temp_nouns WHERE word='structuur' LIMIT 1), 'de', 'structuurtje', 'structuren'),
((SELECT id FROM temp_nouns WHERE word='student' LIMIT 1), 'de', 'studentje', 'studenten'),
((SELECT id FROM temp_nouns WHERE word='studie' LIMIT 1), 'de', 'studietje', 'studies'),
((SELECT id FROM temp_nouns WHERE word='succes' LIMIT 1), 'het', 'succesje', 'successen'),
((SELECT id FROM temp_nouns WHERE word='suiker' LIMIT 1), 'de', 'suikertje', 'suiker'),
((SELECT id FROM temp_nouns WHERE word='symbool' LIMIT 1), 'het', 'symbooltje', 'symbolen'),
((SELECT id FROM temp_nouns WHERE word='systeem' LIMIT 1), 'het', 'systeempje', 'systemen'),
((SELECT id FROM temp_nouns WHERE word='tafel' LIMIT 1), 'de', 'tafeltje', 'tafels'),
((SELECT id FROM temp_nouns WHERE word='tante' LIMIT 1), 'de', 'tantetje', 'tantes'),
((SELECT id FROM temp_nouns WHERE word='techniek' LIMIT 1), 'de', 'techniekje', 'technieken'),
((SELECT id FROM temp_nouns WHERE word='tekst' LIMIT 1), 'de', 'tekstje', 'teksten'),
((SELECT id FROM temp_nouns WHERE word='telefoon' LIMIT 1), 'de', 'telefoontje', 'telefoons'),
((SELECT id FROM temp_nouns WHERE word='televisie' LIMIT 1), 'de', 'televisietje', 'televisies'),
((SELECT id FROM temp_nouns WHERE word='tentamen' LIMIT 1), 'het', 'tentamenje', 'tentamens'),
((SELECT id FROM temp_nouns WHERE word='term' LIMIT 1), 'de', 'termpje', 'termen'),
((SELECT id FROM temp_nouns WHERE word='terras' LIMIT 1), 'het', 'terrasje', 'terrassen'),
((SELECT id FROM temp_nouns WHERE word='terrein' LIMIT 1), 'het', 'terreintje', 'terreinen'),
((SELECT id FROM temp_nouns WHERE word='thee' LIMIT 1), 'de', 'theetje', 'thee'),
((SELECT id FROM temp_nouns WHERE word='theorie' LIMIT 1), 'de', 'theorietje', 'theorieën'),
((SELECT id FROM temp_nouns WHERE word='titel' LIMIT 1), 'de', 'titeltje', 'titels'),
((SELECT id FROM temp_nouns WHERE word='toetje' LIMIT 1), 'het', 'toetje', 'toetjes'),
((SELECT id FROM temp_nouns WHERE word='toets' LIMIT 1), 'de', 'toetsje', 'toetsen'),
((SELECT id FROM temp_nouns WHERE word='tong' LIMIT 1), 'de', 'tongetje', 'tongen'),
((SELECT id FROM temp_nouns WHERE word='top' LIMIT 1), 'de', 'topje', 'toppen'),
((SELECT id FROM temp_nouns WHERE word='traditie' LIMIT 1), 'de', 'traditietje', 'tradities'),
((SELECT id FROM temp_nouns WHERE word='trein' LIMIT 1), 'de', 'treintje', 'treinen'),
((SELECT id FROM temp_nouns WHERE word='tuin' LIMIT 1), 'de', 'tuintje', 'tuinen'),
((SELECT id FROM temp_nouns WHERE word='universiteit' LIMIT 1), 'de', 'universiteittje', 'universiteiten'),
((SELECT id FROM temp_nouns WHERE word='uur' LIMIT 1), 'het', 'uurtje', 'uren'),
((SELECT id FROM temp_nouns WHERE word='vader' LIMIT 1), 'de', 'vadertje', 'vaders'),
((SELECT id FROM temp_nouns WHERE word='veld' LIMIT 1), 'het', 'veldje', 'velden'),
((SELECT id FROM temp_nouns WHERE word='verjaardag' LIMIT 1), 'de', 'verjaardagje', 'verjaardagen'),
((SELECT id FROM temp_nouns WHERE word='vinger' LIMIT 1), 'de', 'vingertje', 'vingers'),
((SELECT id FROM temp_nouns WHERE word='vis' LIMIT 1), 'de', 'visje', 'vissen'),
((SELECT id FROM temp_nouns WHERE word='visie' LIMIT 1), 'de', 'visietje', 'visies'),
((SELECT id FROM temp_nouns WHERE word='vloer' LIMIT 1), 'de', 'vloertje', 'vloeren'),
((SELECT id FROM temp_nouns WHERE word='voet' LIMIT 1), 'de', 'voetje', 'voeten'),
((SELECT id FROM temp_nouns WHERE word='vorming' LIMIT 1), 'de', 'vormingetje', 'vormingen'),
((SELECT id FROM temp_nouns WHERE word='vriend' LIMIT 1), 'de', 'vriendje', 'vrienden'),
((SELECT id FROM temp_nouns WHERE word='vriendin' LIMIT 1), 'de', 'vriendinnetje', 'vriendinnen'),
((SELECT id FROM temp_nouns WHERE word='vuilnis' LIMIT 1), 'het', 'vuilnisje', 'vuilnis'),
((SELECT id FROM temp_nouns WHERE word='vuur' LIMIT 1), 'het', 'vuurtje', 'vuren'),
((SELECT id FROM temp_nouns WHERE word='wapen' LIMIT 1), 'het', 'wapentje', 'wapens'),
((SELECT id FROM temp_nouns WHERE word='warmte' LIMIT 1), 'de', 'warmtetje', 'warmte'),
((SELECT id FROM temp_nouns WHERE word='wasmachine' LIMIT 1), 'de', 'wasmachinetje', 'wasmachines'),
((SELECT id FROM temp_nouns WHERE word='water' LIMIT 1), 'het', 'watertje', 'waters'),
((SELECT id FROM temp_nouns WHERE word='week' LIMIT 1), 'de', 'weekje', 'weken'),
((SELECT id FROM temp_nouns WHERE word='weer' LIMIT 1), 'het', 'weertje', 'weer'),
((SELECT id FROM temp_nouns WHERE word='wens' LIMIT 1), 'de', 'wensje', 'wensen'),
((SELECT id FROM temp_nouns WHERE word='wereld' LIMIT 1), 'de', 'wereldje', 'werelden'),
((SELECT id FROM temp_nouns WHERE word='werk' LIMIT 1), 'het', 'werkje', 'werken'),
((SELECT id FROM temp_nouns WHERE word='westen' LIMIT 1), 'het', 'westentje', 'westen'),
((SELECT id FROM temp_nouns WHERE word='wetenschap' LIMIT 1), 'de', 'wetenschapje', 'wetenschappen'),
((SELECT id FROM temp_nouns WHERE word='wijn' LIMIT 1), 'de', 'wijntje', 'wijnen'),
((SELECT id FROM temp_nouns WHERE word='wind' LIMIT 1), 'de', 'windje', 'winden'),
((SELECT id FROM temp_nouns WHERE word='winter' LIMIT 1), 'de', 'wintertje', 'winters'),
((SELECT id FROM temp_nouns WHERE word='woord' LIMIT 1), 'het', 'woordje', 'woorden'),
((SELECT id FROM temp_nouns WHERE word='zaken' LIMIT 1), 'de', 'zaakje', 'zaken'),
((SELECT id FROM temp_nouns WHERE word='zand' LIMIT 1), 'het', 'zandje', 'zand'),
((SELECT id FROM temp_nouns WHERE word='zee' LIMIT 1), 'de', 'zeetje', 'zeeën'),
((SELECT id FROM temp_nouns WHERE word='zomer' LIMIT 1), 'de', 'zomertje', 'zomers'),
((SELECT id FROM temp_nouns WHERE word='zondag' LIMIT 1), 'de', 'zondagje', 'zondagen'),
((SELECT id FROM temp_nouns WHERE word='zoon' LIMIT 1), 'de', 'zoontje', 'zonen'),
((SELECT id FROM temp_nouns WHERE word='zout' LIMIT 1), 'het', 'zoutje', 'zouten'),
((SELECT id FROM temp_nouns WHERE word='zus' LIMIT 1), 'de', 'zusje', 'zussen'),
((SELECT id FROM temp_nouns WHERE word='zuster' LIMIT 1), 'de', 'zustertje', 'zusters')
ON CONFLICT (word_id) DO NOTHING;

-- Clean up temporary table
DROP TABLE temp_nouns;

CREATE TEMP TABLE temp_numerals AS
SELECT id, word
FROM words
WHERE part_of_speech = 'numeral';

-- Create numeral forms for Dutch numerals (explicit rows mirroring nouns style)
INSERT INTO numerals (word_id, numeric_value, ordinal_form) VALUES
((SELECT id FROM temp_numerals WHERE word='nul' LIMIT 1), 0, 'nul'),
((SELECT id FROM temp_numerals WHERE word='een' LIMIT 1), 1, 'eerste'),
((SELECT id FROM temp_numerals WHERE word='twee' LIMIT 1), 2, 'tweede'),
((SELECT id FROM temp_numerals WHERE word='drie' LIMIT 1), 3, 'derde'),
((SELECT id FROM temp_numerals WHERE word='vier' LIMIT 1), 4, 'vierde'),
((SELECT id FROM temp_numerals WHERE word='vijf' LIMIT 1), 5, 'vijfde'),
((SELECT id FROM temp_numerals WHERE word='zes' LIMIT 1), 6, 'zesde'),
((SELECT id FROM temp_numerals WHERE word='zeven' LIMIT 1), 7, 'zevende'),
((SELECT id FROM temp_numerals WHERE word='acht' LIMIT 1), 8, 'achtste'),
((SELECT id FROM temp_numerals WHERE word='negen' LIMIT 1), 9, 'negende'),
((SELECT id FROM temp_numerals WHERE word='tien' LIMIT 1), 10, 'tiende'),
((SELECT id FROM temp_numerals WHERE word='elf' LIMIT 1), 11, 'elfde'),
((SELECT id FROM temp_numerals WHERE word='twaalf' LIMIT 1), 12, 'twaalfde'),
((SELECT id FROM temp_numerals WHERE word='dertien' LIMIT 1), 13, 'dertiende'),
((SELECT id FROM temp_numerals WHERE word='veertien' LIMIT 1), 14, 'veertiende'),
((SELECT id FROM temp_numerals WHERE word='vijftien' LIMIT 1), 15, 'vijftiende'),
((SELECT id FROM temp_numerals WHERE word='zestien' LIMIT 1), 16, 'zestiende'),
((SELECT id FROM temp_numerals WHERE word='zeventien' LIMIT 1), 17, 'zeventiende'),
((SELECT id FROM temp_numerals WHERE word='achttien' LIMIT 1), 18, 'achttiende'),
((SELECT id FROM temp_numerals WHERE word='negentien' LIMIT 1), 19, 'negentiende'),
((SELECT id FROM temp_numerals WHERE word='twintig' LIMIT 1), 20, 'twintigste'),
((SELECT id FROM temp_numerals WHERE word='dertig' LIMIT 1), 30, 'dertigste'),
((SELECT id FROM temp_numerals WHERE word='veertig' LIMIT 1), 40, 'veertigste'),
((SELECT id FROM temp_numerals WHERE word='vijftig' LIMIT 1), 50, 'vijftigste'),
((SELECT id FROM temp_numerals WHERE word='honderd' LIMIT 1), 100, 'honderdste'),
((SELECT id FROM temp_numerals WHERE word='duizend' LIMIT 1), 1000, 'duizendste')
ON CONFLICT (word_id) DO NOTHING;

DROP TABLE temp_numerals;

-- Create adjective forms for Dutch adjectives (explicit rows)
INSERT INTO adjectives (word_id, adjective, de_form, comparison, superlative) VALUES
((SELECT id FROM words WHERE word='groot' AND part_of_speech = 'adjective' LIMIT 1), 'groot', 'grote', 'groter', 'grootste'),
((SELECT id FROM words WHERE word='klein' AND part_of_speech = 'adjective' LIMIT 1), 'klein', 'kleine', 'kleiner', 'kleinste'),
((SELECT id FROM words WHERE word='oud' AND part_of_speech = 'adjective' LIMIT 1), 'oud', 'oude', 'ouder', 'oudste'),
((SELECT id FROM words WHERE word='nieuw' AND part_of_speech = 'adjective' LIMIT 1), 'nieuw', 'nieuwe', 'nieuwer', 'nieuwste'),
((SELECT id FROM words WHERE word='mooi' AND part_of_speech = 'adjective' LIMIT 1), 'mooi', 'mooie', 'mooier', 'mooiste'),
((SELECT id FROM words WHERE word='lelijk' AND part_of_speech = 'adjective' LIMIT 1), 'lelijk', 'lelijke', 'lelijker', 'lelijkste'),
((SELECT id FROM words WHERE word='goed' AND part_of_speech = 'adjective' LIMIT 1), 'goed', 'goede', 'beter', 'best'),
((SELECT id FROM words WHERE word='slecht' AND part_of_speech = 'adjective' LIMIT 1), 'slecht', 'slechte', 'slechter', 'slechtst'),
((SELECT id FROM words WHERE word='snel' AND part_of_speech = 'adjective' LIMIT 1), 'snel', 'snelle', 'sneller', 'snelst'),
((SELECT id FROM words WHERE word='langzaam' AND part_of_speech = 'adjective' LIMIT 1), 'langzaam', 'langzame', 'langzamer', 'langzaamste'),
((SELECT id FROM words WHERE word='warm' AND part_of_speech = 'adjective' LIMIT 1), 'warm', 'warme', 'warmer', 'warmste'),
((SELECT id FROM words WHERE word='koud' AND part_of_speech = 'adjective' LIMIT 1), 'koud', 'koude', 'kouder', 'koudste'),
((SELECT id FROM words WHERE word='moeilijk' AND part_of_speech = 'adjective' LIMIT 1), 'moeilijk', 'moeilijke', 'moeilijker', 'moeilijkste'),
((SELECT id FROM words WHERE word='makkelijk' AND part_of_speech = 'adjective' LIMIT 1), 'makkelijk', 'makkelijke', 'makkelijker', 'makkelijkste'),
((SELECT id FROM words WHERE word='lang' AND part_of_speech = 'adjective' LIMIT 1), 'lang', 'lange', 'langer', 'langste'),
((SELECT id FROM words WHERE word='kort' AND part_of_speech = 'adjective' LIMIT 1), 'kort', 'korte', 'korter', 'kortste'),
((SELECT id FROM words WHERE word='interessant' AND part_of_speech = 'adjective' LIMIT 1), 'interessant', 'interessante', 'interessanter', 'interessantste'),
((SELECT id FROM words WHERE word='belangrijk' AND part_of_speech = 'adjective' LIMIT 1), 'belangrijk', 'belangrijke', 'belangrijker', 'belangrijkste'),
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

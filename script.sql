---- inicio do script, por favor, terminar ele depois.
---- Falta terminar o script.
DROP VIEW  IF EXISTS race_colors, status_conjulgal, lista_escolaridade_em_anos CASCADE;
DROP TABLE IF EXISTS regions, states, cities, genders, code_cities, races, schooling_in_years, regioes_temp, deaths, 
estados_temp, cidades_temp, codigo_cidades_temp, obitos_temp;
DROP INDEX IF EXISTS idx_codmunres, idx_id_cities, idx_id_gender;
 
CREATE TEMPORARY TABLE IF NOT EXISTS regioes_temp(
    Id integer,
    Nome TEXT
);

CREATE TEMPORARY TABLE IF NOT EXISTS estados_temp(
    Id INTEGER,
    CodigoUF INTEGER,
    Nome TEXT,
    Uf   TEXT,
    Regiao INTEGER
);

CREATE TEMPORARY TABLE IF NOT EXISTS cidades_temp (
    Id Integer,
    Codigo VARCHAR(10),
    Nome VARCHAR(100),
    Uf VARCHAR(2)
);


CREATE TEMPORARY TABLE IF NOT EXISTS obitos_temp (
    ORIGEM TEXT,
    TIPOBITO TEXT,
    DTOBITO TEXT,
    HORAOBITO TEXT,
    NATURAL1 TEXT,
    CODMUNNATU INTEGER,
    DTNASC TEXT,
    IDADE TEXT,
    SEXO TEXT,
    RACACOR TEXT,
    ESTCIV TEXT,
    ESC TEXT,
    ESC2010 TEXT,
    OCUP TEXT,
    CODMUNRES INTEGER,
    LOCOCOR TEXT,
    CODMUNOCOR INTEGER,
    ASSISTMED TEXT,
    NECROPSIA TEXT,
    ACIDTRAB TEXT
);


CREATE TEMPORARY TABLE IF NOT EXISTS codigo_cidades_temp(
    codigo BIGINT
);

CREATE TABLE IF NOT EXISTS regions(
    id          SERIAL PRIMARY KEY,
    code_region INTEGER,
    name VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS states(
    id      SERIAL PRIMARY KEY,
    code_uf INTEGER,
    name    VARCHAR(255),
    Uf      VARCHAR(2),
    region_id INTEGER,
    FOREIGN KEY(region_id) REFERENCES regions(id)
);

CREATE TABLE IF NOT EXISTS cities(
    id       SERIAL PRIMARY KEY,
    code     VARCHAR(255),
    name     VARCHAR(255),
    state_id INTEGER,
    FOREIGN KEY(state_id) REFERENCES states(id)
);

CREATE TABLE IF NOT EXISTS code_cities(
    id      SERIAL PRIMARY KEY,
    code    BIGINT NOT NULL,
    city_id INTEGER,
    FOREIGN KEY (city_id) REFERENCES cities(id)
);

CREATE TABLE IF NOT EXISTS genders(
    id          SERIAL PRIMARY KEY,
    code        INTEGER,
    slug        VARCHAR(5),
    description VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS races(
    Id      SERIAL PRIMARY KEY,
    color   VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS marital_status(
    id SERIAL PRIMARY KEY,
    description VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS schooling_in_years(
    id          SERIAL PRIMARY KEY,
    description VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS deaths(
    id SERIAL PRIMARY KEY,
    type_death INTEGER,
    date_death TEXT,
	gender_id  INTEGER,
    race_id    INTEGER,
    schooling_in_year_id INTEGER,
    marital_status_id    INTEGER,
    code_city_of_birth_id     INTEGER,
    code_city_of_residence_id INTEGER,
    code_city_of_death_id     INTEGER,
    FOREIGN KEY (schooling_in_year_id)      REFERENCES schooling_in_years(id),
    FOREIGN KEY (marital_status_id)         REFERENCES marital_status(id),
    FOREIGN KEY (gender_id)                 REFERENCES genders(id),
    FOREIGN KEY (race_id)                   REFERENCES races(id), 
    FOREIGN KEY (code_city_of_birth_id)     REFERENCES code_cities (id),
    FOREIGN KEY (code_city_of_residence_id) REFERENCES code_cities (id),
    FOREIGN KEY (code_city_of_death_id)     REFERENCES code_cities (id)
);

COPY obitos_temp FROM 'C:\mortalidade_2018.csv' DELIMITER ',' CSV HEADER;

COPY obitos_temp FROM 'C:\mortalidade_2019.csv' DELIMITER ',' CSV HEADER;

COPY obitos_temp FROM 'C:\mortalidade_2020.csv' DELIMITER ',' CSV HEADER;


COPY regioes_temp   FROM 'C:\regioes.csv'   DELIMITER ',' CSV HEADER;
COPY estados_temp   FROM 'C:\estados.csv'   DELIMITER ',' CSV HEADER;
COPY cidades_temp   FROM 'C:\cidades.csv'   DELIMITER ',' CSV HEADER;

INSERT INTO codigo_cidades_temp(codigo)
SELECT 
 distinct(codmunres)::BIGINT
FROM obitos_temp order by codmunres;


---CREATE VIEW FOR LIST RACES

CREATE OR REPLACE VIEW race_colors AS 
SELECT distinct(racacor),
CASE 
	WHEN obitos_temp.racacor = '1' THEN 'Branco'
	WHEN obitos_temp.racacor = '2' THEN 'Preta'
	WHEN obitos_temp.racacor = '3' THEN 'Amarela'
	WHEN obitos_temp.racacor = '4' THEN 'Parda'
	WHEN obitos_temp.racacor = '5' THEN 'Indígena'
END color
FROM obitos_temp where racacor != '' order by racacor;

--- CREATE VIEW FOR LIST STATUS MARITAL
CREATE OR REPLACE VIEW status_conjulgal AS
SELECT
	DISTINCT(estciv),
CASE 
	WHEN obitos_temp.estciv = '1' THEN 'Solteiro'
	WHEN obitos_temp.estciv = '2' THEN 'Casado'
	WHEN obitos_temp.estciv = '3' THEN 'Viúvo'
	WHEN obitos_temp.estciv = '4' THEN 'Separado judicialmente/divorciado'
	WHEN obitos_temp.estciv = '5' THEN 'União estável'
	WHEN obitos_temp.estciv = '9' THEN 'Ignorado'
END description
FROM obitos_temp WHERE estciv != '' ORDER BY estciv;


--- CREATE VIEW FOR LIST SCHOOLING IN YEARS
CREATE OR REPLACE VIEW lista_escolaridade_em_anos AS
SELECT DISTINCT(esc),
CASE
	WHEN esc = '1' THEN 'Nenhuma'
	WHEN esc = '2' THEN 'de 1 a 3 anos'
	WHEN esc = '3' THEN 'de 4 a 7 anos'
	WHEN esc = '4' THEN 'de 8 a 11 anos'
	WHEN esc = '5' THEN '12 anos e mais'
	WHEN esc = '9' THEN 'Ignorado'
END description
FROM obitos_temp WHERE esc != '' ORDER BY esc;


--- CREATE INDEX

CREATE INDEX idx_codmunres ON obitos_temp (codmunres);
CREATE INDEX idx_id_cities ON cities (id);
CREATE INDEX idx_id_gender ON genders (id);
--- END CREATE INDEX


---- CREATE FUNCTIONS
CREATE OR REPLACE FUNCTION build_genders()
RETURNS void
LANGUAGE plpgsql
as
$$
declare
begin
    INSERT INTO genders(slug, code, description) VALUES ('M', 1, 'Masculino');
    INSERT INTO genders(slug, code, description) VALUES ('F', 2, 'Feminino');
    INSERT INTO genders(slug, code, description) VALUES ('I', 3, 'Indeterminado');
end;
$$;

CREATE OR REPLACE FUNCTION build_regions()
RETURNS void
LANGUAGE  plpgsql
as
$$
declare
begin
    INSERT INTO regions(name, code_region)
    SELECT
    regioes_temp.nome,
    regioes_temp.id
    FROM regioes_temp;
    
    RAISE NOTICE 'Inseriu dados na tabela de regions';
end;
$$;


CREATE OR REPLACE FUNCTION build_states()
RETURNS void
LANGUAGE plpgsql
as
$$
declare
begin
    INSERT INTO states(code_uf, name, uf, region_id)
    SELECT 
        CodigoUF,
        nome,
        Uf,
        (
        SELECT id as region_id FROM regions where id = estados_temp.regiao
        )
    FROM estados_temp;

    RAISE NOTICE 'Inseriu dados na tabela de states';
end;
$$;

CREATE OR REPLACE FUNCTION build_cities()
RETURNS void
LANGUAGE plpgsql
as
$$
declare
begin
    INSERT INTO cities(code, name, state_id)
    SELECT 
    distinct(codigo) as code,
    nome,
    (
        SELECT id as state_id FROM states where uf = cidades_temp.uf
    )
    FROM cidades_temp order by codigo;

    RAISE NOTICE 'Inseriu dados na tabela de cities';
end;
$$;

CREATE OR REPLACE FUNCTION build_code_cities()
RETURNS void
LANGUAGE plpgsql
as
$$
declare
begin
 	INSERT INTO code_cities(code, city_id)
	SELECT 
		codigo,
		(SELECT id as city_id FROM cities WHERE code LIKE '%' || CAST(codigo_cidades_temp.codigo AS TEXT) ||'%' LIMIT 1)
	FROM codigo_cidades_temp;

    RAISE NOTICE 'Inseriu dados na tabela de code_cities';
end;
$$;


CREATE OR REPLACE FUNCTION build_races()
RETURNS void
LANGUAGE plpgsql
as
$$
declare
begin
    INSERT INTO races(color)
    SELECT race_colors.color FROM race_colors;

    RAISE NOTICE 'Inseriu dados na tabela de races';
end;
$$;

CREATE OR REPLACE FUNCTION build_marital_status()
RETURNS void
LANGUAGE plpgsql
as
$$
declare
begin
    INSERT INTO marital_status(description)
    SELECT status_conjulgal.description FROM status_conjulgal;

    RAISE NOTICE 'Inseriu dados na tabela de marital_status';
end;
$$;

CREATE OR REPLACE FUNCTION build_schooling_in_years()
RETURNS void
LANGUAGE plpgsql
as
$$
declare
begin
    INSERT INTO schooling_in_years(description)
    SELECT lista_escolaridade_em_anos.description FROM lista_escolaridade_em_anos;

    RAISE NOTICE 'Inseriu dados na tabela de schooling_in_years';
end;
$$;


CREATE OR REPLACE FUNCTION build_table_deaths()
RETURNS void
LANGUAGE plpgsql
as
$$
declare
begin
 	INSERT INTO deaths(type_death, date_death, gender_id, race_id, schooling_in_year_id, 
	marital_status_id, code_city_of_birth_id, code_city_of_residence_id, code_city_of_death_id)
	SELECT 
		tipobito::integer as type_death,
		dtobito  as date_death,
		(SELECT id as gender_id FROM genders WHERE code = obitos_temp.sexo::integer),
        (SELECT id as race_id 	FROM RACES 	 WHERE id = obitos_temp.racacor::integer),
        (SELECT id as schooling_in_year_id      FROM schooling_in_years WHERE id = obitos_temp.esc::integer),
        (SELECT id as marital_status_id         FROM marital_status WHERE id = obitos_temp.estciv::integer),
		(SELECT id as code_city_of_birth_id     FROM code_cities WHERE code = obitos_temp.codmunnatu LIMIT 1),
		(SELECT id as code_city_of_residence_id FROM code_cities WHERE code = obitos_temp.codmunres	 LIMIT 1),
		(SELECT id as code_city_of_death_id     FROM code_cities WHERE code = obitos_temp.codmunocor LIMIT 1)
	FROM obitos_temp LIMIT 1000;

	RAISE NOTICE 'Inseriu dados na tabela de deaths';
end;
$$;

--- END CREATE

SELECT build_regions();
SELECT build_states();
SELECT build_cities();
SELECT build_genders();
SELECT build_code_cities();
SELECT build_races();
SELECT build_marital_status();
SELECT build_schooling_in_years();
SELECT build_table_deaths();

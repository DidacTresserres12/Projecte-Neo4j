//Generació de dades projecte Neo4j grup 10.


// --- 1. NETEJA ---
MATCH (n) DETACH DELETE n;

// --- 2. CONSTRAINTS I ÍNDEXS ---
CREATE CONSTRAINT UniqueIndividu IF NOT EXISTS 
FOR (i:Individu) REQUIRE i.id IS NODE KEY;

// Definim la CONSTRAINT usant 'location' com a propietat del graf
CREATE CONSTRAINT UniqueHabitatge IF NOT EXISTS 
FOR (h:Habitatge) REQUIRE (h.id_llar, h.any_padro, h.location) IS NODE KEY;

CREATE INDEX index_nom_cognom IF NOT EXISTS 
FOR (i:Individu) ON (i.name, i.surname);

// --- 3. CÀRREGA NODES: INDIVIDU ---
LOAD CSV WITH HEADERS FROM 
'https://docs.google.com/spreadsheets/d/e/2PACX-1vTfU6oJBZhmhzzkV_0-avABPzHTdXy8851ySDbn2gq32WwaNmYxfiBtCGJGOZsMgCWjzlEGX4Zh1wqe/pub?output=csv' 
AS row
WITH row WHERE row.Id IS NOT NULL
MERGE (i:Individu {id: toInteger(row.Id)})
SET i.name = row.name,
    i.surname = row.surname,
    i.second_surname = row.second_surname,
    i.year = toInteger(row.Year);

// --- 4. CÀRREGA NODES: HABITATGE (Mapeig de Municipi a location) ---
LOAD CSV WITH HEADERS FROM 
'https://docs.google.com/spreadsheets/d/e/2PACX-1vT0ZhR6BSO_M72JEmxXKs6GLuOwxm_Oy-0UruLJeX8_R04KAcICuvrwn2OENQhtuvddU5RSJSclHRJf/pub?output=csv' 
AS row
WITH row WHERE row.Id_Llar IS NOT NULL AND row.Municipi IS NOT NULL
// Creem el node usant 'location' encara que el CSV digui 'Municipi'
MERGE (h:Habitatge {
    id_llar: toInteger(row.Id_Llar),
    any_padro: toInteger(row.Any_Padro),
    location: row.Municipi 
})
SET h.carrer = row.Carrer,
    h.numero = CASE 
        WHEN row.Numero IS NOT NULL AND row.Numero <> '' AND row.Numero <> 'null' 
        THEN toInteger(row.Numero) 
        ELSE NULL 
    END;

// --- 5. CÀRREGA RELACIÓ VIU ---
LOAD CSV WITH HEADERS FROM 
'https://docs.google.com/spreadsheets/d/e/2PACX-1vRM4DPeqFmv7w6kLH5msNk6_Hdh1wuExRirgysZKO_Q70L21MKBkDISIyjvdm8shVixl5Tcw_5zCfdg/pub?output=csv' 
AS row
WITH row WHERE row.IND IS NOT NULL AND row.HOUSE_ID IS NOT NULL
MATCH (i:Individu {id: toInteger(row.IND)})
// Aquí el CSV de VIU ja sol portar la columna 'Location'
MATCH (h:Habitatge {
    id_llar: toInteger(row.HOUSE_ID),
    any_padro: toInteger(row.Year),
    location: row.Location
})
MERGE (i)-[:VIU]->(h);

// --- 6. CÀRREGA RELACIÓ FAMÍLIA ---
LOAD CSV WITH HEADERS FROM 
'https://docs.google.com/spreadsheets/d/e/2PACX-1vRVOoMAMoxHiGboTjCIHo2yT30CCWgVHgocGnVJxiCTgyurtmqCfAFahHajobVzwXFLwhqajz1fqA8d/pub?output=csv' 
AS row
WITH row WHERE row.ID_1 IS NOT NULL AND row.ID_2 IS NOT NULL
MATCH (i1:Individu {id: toInteger(row.ID_1)})
MATCH (i2:Individu {id: toInteger(row.ID_2)})
MERGE (i1)-[r:FAMILIA]->(i2)
SET r.relacio = row.Relacio,
    r.relacio_harmonitzada = row.Relacio_Harmonitzada;

// --- 7. CÀRREGA RELACIÓ SAME_AS ---
LOAD CSV WITH HEADERS FROM 
'https://docs.google.com/spreadsheets/d/e/2PACX-1vTgC8TBmdXhjUOPKJxyiZSpetPYjaRC34gmxHj6H2AWvXTGbg7MLKVdJnwuh5bIeer7WLUi0OigI6wc/pub?output=csv' 
AS row
WITH row WHERE row.Id_A IS NOT NULL AND row.Id_B IS NOT NULL
MATCH (iA:Individu {id: toInteger(row.Id_A)})
MATCH (iB:Individu {id: toInteger(row.Id_B)})
MERGE (iA)-[:SAME_AS]->(iB);
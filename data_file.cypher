//Generació de dades projecte Neo4j grup 10

// 1. NETEJA
MATCH (n) DETACH DELETE n;


// 2. CONSTRAINTS I ÍNDEXS
CREATE CONSTRAINT UniqueIndividu IF NOT EXISTS FOR (i:Individu) REQUIRE i.individuId IS NODE KEY;
CREATE CONSTRAINT UniqueHabitatge IF NOT EXISTS FOR (h:Habitatge) REQUIRE (h.llarId, h.anyPadro, h.location) IS NODE KEY;

// Índex per a les cerques ràpides per any en individus
CREATE INDEX index_any_individu IF NOT EXISTS FOR (i:Individu) ON (i.anyPadro);
CREATE INDEX NomCognom IF NOT EXISTS FOR (i:Individu) ON (i.name, i.surname);

// 3. CÀRREGA NODE: INDIVIDU
LOAD CSV WITH HEADERS FROM 'https://docs.google.com/spreadsheets/d/e/2PACX-1vTfU6oJBZhmhzzkV_0-avABPzHTdXy8851ySDbn2gq32WwaNmYxfiBtCGJGOZsMgCWjzlEGX4Zh1wqe/pub?output=csv' AS row
WITH row 
WHERE row.Id IS NOT NULL
MERGE (i:Individu {individuId: toInteger(row.Id)})
SET i.name = row.name, i.surname = row.surname, i.secondSurname = row.second_surname, i.year = toInteger(row.Year)
RETURN count(i);


// 4. CÀRREGA NODE: HABITATGE
LOAD CSV WITH HEADERS FROM 'https://docs.google.com/spreadsheets/d/e/2PACX-1vT0ZhR6BSO_M72JEmxXKs6GLuOwxm_Oy-0UruLJeX8_R04KAcICuvrwn2OENQhtuvddU5RSJSclHRJf/pub?output=csv' AS row
WITH row 
WHERE row.Id_Llar IS NOT NULL AND row.Any_Padro IS NOT NULL AND row.Municipi IS NOT NULL 
MERGE (h:Habitatge {llarId: toInteger(row.Id_Llar), anyPadro: toInteger(row.Any_Padro), location: row.Municipi})
SET h.carrer = row.Carrer, h.numero = CASE 
        WHEN row.Numero IS NOT NULL AND row.Numero <> '' AND row.Numero <> 'null' 
        THEN toInteger(row.Numero) 
        ELSE NULL 
    END
RETURN count(h);


// 5. CÀRREGA RELACIÓ: VIU 
LOAD CSV WITH HEADERS FROM 'https://docs.google.com/spreadsheets/d/e/2PACX-1vRM4DPeqFmv7w6kLH5msNk6_Hdh1wuExRirgysZKO_Q70L21MKBkDISIyjvdm8shVixl5Tcw_5zCfdg/pub?output=csv' AS row
WITH row 
WHERE row.IND IS NOT NULL AND row.HOUSE_ID IS NOT NULL AND row.Year IS NOT NULL AND row.Location IS NOT NULL
MATCH (i:Individu {individuId: toInteger(row.IND)})
MATCH (h:Habitatge {llarId: toInteger(row.HOUSE_ID), anyPadro: toInteger(row.Year), location: row.Location})
MERGE (i)-[r:VIU]->(h)
RETURN count(r) AS relacionsCreades;


// 6. CÀRREGA RELACIÓ: FAMILIA 
LOAD CSV WITH HEADERS FROM 'https://docs.google.com/spreadsheets/d/e/2PACX-1vRVOoMAMoxHiGboTjCIHo2yT30CCWgVHgocGnVJxiCTgyurtmqCfAFahHajobVzwXFLwhqajz1fqA8d/pub?output=csv' AS row
WITH row 
WHERE row.ID_1 IS NOT NULL AND row.ID_2 IS NOT NULL
MATCH (i1:Individu {individuId: toInteger(row.ID_1)})
MATCH (i2:Individu {individuId: toInteger(row.ID_2)})
MERGE (i1)-[r:FAMILIA]->(i2)
SET r.relacio = row.Relacio, r.relacioHarmonitzada = row.Relacio_Harmonitzada
RETURN count(r) AS relacionsCreades;


// 7. CÀRREGA RELACIÓ: SAME_AS
LOAD CSV WITH HEADERS FROM 'https://docs.google.com/spreadsheets/d/e/2PACX-1vTgC8TBmdXhjUOPKJxyiZSpetPYjaRC34gmxHj6H2AWvXTGbg7MLKVdJnwuh5bIeer7WLUi0OigI6wc/pub?output=csv' AS row
WITH row 
WHERE row.Id_A IS NOT NULL AND row.Id_B IS NOT NULL
MATCH (iA:Individu {individuId: toInteger(row.Id_A)})
MATCH (iB:Individu {individuId: toInteger(row.Id_B)})
MERGE (iA)-[r:SAME_AS]->(iB)
RETURN count(r) AS relacionsCreades;
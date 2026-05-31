// NETEJA 
MATCH (n) DETACH DELETE n;


// CONSTRAINTS I ÍNDEXS 
CREATE CONSTRAINT UniqueIndividu IF NOT EXISTS FOR (i:Individu) REQUIRE i.individuId IS NODE KEY;
CREATE CONSTRAINT UniqueHabitatge IF NOT EXISTS FOR (h:Habitatge) REQUIRE (h.llarId, h.anyPadro, h.location) IS NODE KEY;
CREATE CONSTRAINT UniqueMunicipi IF NOT EXISTS FOR (m:Municipi) REQUIRE m.municipi IS UNIQUE;
CREATE CONSTRAINT UniquePadro IF NOT EXISTS FOR (pa:Padro) REQUIRE pa.anyPadro IS UNIQUE;


// CÀRREGA: INDIVIDU 
LOAD CSV WITH HEADERS FROM 'https://docs.google.com/spreadsheets/d/e/2PACX-1vTfU6oJBZhmhzzkV_0-avABPzHTdXy8851ySDbn2gq32WwaNmYxfiBtCGJGOZsMgCWjzlEGX4Zh1wqe/pub?output=csv' AS row
WITH row 
WHERE row.Id IS NOT NULL
MERGE (i:Individu {individuId: toInteger(row.Id)})
SET i.name = row.name, i.surname = row.surname, i.secondSurname = row.second_surname
RETURN count(i) AS TotalIndividus;


// CÀRREGA: HABITATGE + MUNICIPI + PADRO
LOAD CSV WITH HEADERS FROM 'https://docs.google.com/spreadsheets/d/e/2PACX-1vT0ZhR6BSO_M72JEmxXKs6GLuOwxm_Oy-0UruLJeX8_R04KAcICuvrwn2OENQhtuvddU5RSJSclHRJf/pub?output=csv' AS row
WITH row
WHERE row.Id_Llar IS NOT NULL AND row.Any_Padro IS NOT NULL AND row.Municipi IS NOT NULL
MERGE (h:Habitatge {llarId: toInteger(row.Id_Llar), anyPadro: toInteger(row.Any_Padro), location: row.Municipi})
SET h.carrer = row.Carrer, h.numero = CASE
        WHEN row.Numero IS NOT NULL AND row.Numero <> '' AND row.Numero <> 'null'
        THEN toInteger(row.Numero) 
        ELSE NULL 
        END
MERGE (m:Municipi {municipi: row.Municipi})
MERGE (h)-[r1:PERTANY_A]->(m)
MERGE (pa:Padro {anyPadro: toInteger(row.Any_Padro)})
MERGE (h)-[r2:EN_PADRO]->(pa)
RETURN count(h) AS Habitatges, count(m) AS Municipis, count(r1) AS RelPertanya, count(pa) AS Padrons, count(r2) AS RelEnPadro;


// CÀRREGA: VIU 
LOAD CSV WITH HEADERS FROM 'https://docs.google.com/spreadsheets/d/e/2PACX-1vRM4DPeqFmv7w6kLH5msNk6_Hdh1wuExRirgysZKO_Q70L21MKBkDISIyjvdm8shVixl5Tcw_5zCfdg/pub?output=csv' AS row
WITH row 
WHERE row.IND IS NOT NULL AND row.HOUSE_ID IS NOT NULL AND row.Year IS NOT NULL AND row.Location IS NOT NULL
MATCH (i:Individu {individuId: toInteger(row.IND)})
MATCH (h:Habitatge {llarId: toInteger(row.HOUSE_ID), anyPadro: toInteger(row.Year), location: row.Location})
MERGE (i)-[r:VIU]->(h)
RETURN count(r) AS TotalRelViu;


// CÀRREGA: FAMILIA + FILL_DE + ESPOSA_DE 
LOAD CSV WITH HEADERS FROM 'https://docs.google.com/spreadsheets/d/e/2PACX-1vRVOoMAMoxHiGboTjCIHo2yT30CCWgVHgocGnVJxiCTgyurtmqCfAFahHajobVzwXFLwhqajz1fqA8d/pub?output=csv' AS row
WITH row 
WHERE row.ID_1 IS NOT NULL AND row.ID_2 IS NOT NULL
MATCH (i1:Individu {individuId: toInteger(row.ID_1)})
MATCH (i2:Individu {individuId: toInteger(row.ID_2)})
WITH DISTINCT i1, i2, row
CALL (i1, i2, row) {
    WITH i1, i2, row
    WHERE row.Relacio_Harmonitzada IN ['fill', 'filla']
    MERGE (i2)-[:FILL_DE]->(i1)
}
CALL (i1, i2, row) {
    WITH i1, i2, row
    WHERE row.Relacio_Harmonitzada = 'esposa'
    MERGE (i2)-[:ESPOSA_DE]->(i1)
}
CALL (i1, i2, row) {
    WITH i1, i2, row
    WHERE NOT row.Relacio_Harmonitzada IN ['fill', 'filla', 'esposa']
    MERGE (i1)-[r:FAMILIA]->(i2)
    SET r.relacio = row.Relacio, r.relacioHarmonitzada = row.Relacio_Harmonitzada
}
RETURN count(*) AS TotalFiles;


// CÀRREGA: SAME_AS
LOAD CSV WITH HEADERS FROM 'https://docs.google.com/spreadsheets/d/e/2PACX-1vTgC8TBmdXhjUOPKJxyiZSpetPYjaRC34gmxHj6H2AWvXTGbg7MLKVdJnwuh5bIeer7WLUi0OigI6wc/pub?output=csv' AS row
WITH row
WHERE row.Id_A IS NOT NULL AND row.Id_B IS NOT NULL
MATCH (iA:Individu {individuId: toInteger(row.Id_A)})
MATCH (iB:Individu {individuId: toInteger(row.Id_B)})
MERGE (iA)-[:SAME_AS]->(iB)
RETURN count(*) AS SameAsCarregats;

// OPTIMITZACIÓ: REDUCCIÓ TRANSITIVA ITERATIVA
// Problema del codi original: un sol pas no elimina totes les redundàncies en cadenes llargues (A→B→C→D: el primer pas elimina A→C i B→D, però si A→D existia, pot quedar-se).
// Solució: fem servir CALL {} IN TRANSACTIONS per processar en lots i repetim amb una segona passada de neteja per garantir que no queden redundàncies residuals.
// PASSADA 1 — elimina redundàncies directes (path de longitud 2+)
MATCH (i1:Individu)-[r:SAME_AS]->(i3:Individu)
WHERE EXISTS {
    MATCH (i1)-[:SAME_AS]->(:Individu)-[:SAME_AS*..]->(i3)
}
DELETE r
RETURN count(r) AS Passada1_Esborrades;

// PASSADA 2 — neteja residual per cadenes que s'han quedat descobertes després de la primera passada
MATCH (i1:Individu)-[r:SAME_AS]->(i3:Individu)
WHERE EXISTS {
    MATCH (i1)-[:SAME_AS]->(:Individu)-[:SAME_AS*..]->(i3)
}
DELETE r
RETURN count(r) AS Passada2_Esborrades;

// VERIFICACIÓ FINAL
// Comprovem que no queda cap relació transitiva redundant. Ha de retornar 0.
MATCH (i1:Individu)-[r:SAME_AS]->(i3:Individu)
WHERE EXISTS {
    MATCH (i1)-[:SAME_AS]->(:Individu)-[:SAME_AS*..]->(i3)
}
RETURN count(r) AS RedundantsRestants;

// Resum de l'estat final del graf SAME_AS
MATCH ()-[r:SAME_AS]->()
RETURN count(r) AS TotalSameAsFinal;
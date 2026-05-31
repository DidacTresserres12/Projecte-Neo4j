// Consulta 1 - Per a cada combinació de municipi i any de padró, mostra el total de fills, el nombre d’habitatges i la mitjana de fills per habitatge.

// MODEL ORIGINAL

MATCH (h:Habitatge)<-[:VIU]-(i1:Individu)-[rel:FAMILIA]->(i2:Individu)
WHERE rel.relacioHarmonitzada IN ['fill', 'filla']
WITH h.location AS Municipi, h.anyPadro AS Any, count(DISTINCT i2) AS TotalFills
CALL (Municipi, Any) {
    MATCH (h2:Habitatge)
    WHERE h2.location = Municipi AND h2.anyPadro = Any
    RETURN count(DISTINCT h2) AS TotalHabitatges
}
RETURN Municipi, Any, TotalFills, TotalHabitatges, toFloat(TotalFills) / TotalHabitatges AS MitjaFills
ORDER BY Municipi, Any;



// MODEL NOU

MATCH (m:Municipi)<-[:PERTANY_A]-(h:Habitatge)-[:EN_PADRO]->(pa:Padro)
MATCH (h)<-[:VIU]-(i1:Individu)<-[:FILL_DE]-(i2:Individu)
WITH m, pa, count(DISTINCT i2) AS TotalFills
CALL (m, pa) {
    MATCH (h2:Habitatge)-[:PERTANY_A]->(m)
    MATCH (h2)-[:EN_PADRO]->(pa)
    RETURN count(DISTINCT h2) AS TotalHabitatges
}
RETURN m.municipi AS Municipi, pa.anyPadro AS Any, TotalFills, TotalHabitatges, toFloat(TotalFills) / TotalHabitatges AS MitjaFills
ORDER BY Municipi, Any;






// Consulta 2 - Mostra les esposes que van canviar de residència dins del municipi SFLL en dos padrons consecutius. Per cada cas, mostra el nom i cognom de l’esposa, l’any del padró anterior, el carrer on vivia, l’any del padró posterior i el carrer nou.

// MODEL ORIGINAL

MATCH (i1:Individu)-[rel:FAMILIA]->(esposa:Individu)
WHERE rel.relacioHarmonitzada = 'esposa'
MATCH (esposa)-[:SAME_AS*]-(altra:Individu)
WITH DISTINCT esposa, altra
MATCH (esposa)-[:VIU]->(h1:Habitatge)
MATCH (altra)-[:VIU]->(h2:Habitatge)
WHERE h1.anyPadro < h2.anyPadro AND h1.location = 'SFLL' AND h2.location = 'SFLL' AND (h1.carrer <> h2.carrer OR h1.numero <> h2.numero)
     AND NOT EXISTS {
           MATCH (esposa)-[:SAME_AS*]-(intermedia:Individu)-[:VIU]->(hMig:Habitatge)
           WHERE hMig.location = 'SFLL' AND h1.anyPadro < hMig.anyPadro AND hMig.anyPadro < h2.anyPadro
     }
RETURN DISTINCT esposa.name AS Nom, esposa.surname AS Cognom, h1.anyPadro AS AnyAnterior, h1.carrer AS CarrerAnterior, h1.numero AS NumeroAnterior, 
                h2.anyPadro AS AnyPosterior, h2.carrer AS CarrerPosterior, h2.numero AS NumeroPosterior
ORDER BY h2.anyPadro, Cognom;



// MODEL NOU

MATCH (esposa:Individu)-[:ESPOSA_DE]->(marit:Individu)
MATCH (esposa)-[:SAME_AS*]-(altra:Individu)
WITH DISTINCT esposa, altra
MATCH (esposa)-[:VIU]->(h1:Habitatge)-[:PERTANY_A]->(:Municipi {municipi: 'SFLL'})
MATCH (altra)-[:VIU]->(h2:Habitatge)-[:PERTANY_A]->(:Municipi {municipi: 'SFLL'})
WHERE h1.anyPadro < h2.anyPadro AND (h1.carrer <> h2.carrer OR h1.numero <> h2.numero)
     AND NOT EXISTS {
          MATCH (esposa)-[:SAME_AS*]-(intermedia:Individu)-[:VIU]->(hMig:Habitatge)-[:PERTANY_A]->(:Municipi {municipi: 'SFLL'})
          WHERE hMig.anyPadro > h1.anyPadro AND hMig.anyPadro < h2.anyPadro AND intermedia <> esposa AND intermedia <> altra
     }
RETURN DISTINCT esposa.name AS Nom, esposa.surname AS Cognom, h1.anyPadro AS AnyAnterior, h1.carrer AS CarrerAnterior, h1.numero AS NumeroAnterior, 
                h2.anyPadro AS AnyPosterior, h2.carrer AS CarrerNou, h2.numero AS NumeroNou
ORDER BY h2.anyPadro, Cognom;

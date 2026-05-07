// EXERCICI 2 - Consultes

A) Per a cada padró (any) de Castellví de Rosanes, retorna l’any de padró, el número d'habitants, i la llista de cognoms. Elimina duplicats i “nan”. 

MATCH (i:Individu)-[:VIU]->(h:Habitatge)
WHERE h.location = "CR" 
AND i.surname IS NOT NULL AND i.surname <> "nan" AND i.surname <> "" 
AND i.secondSurname IS NOT NULL AND i.secondSurname <> "nan" AND i.secondSurname <> ""
RETURN h.anyPadro AS AnyPadro, count(DISTINCT i) AS NumeroHabitants, collect(DISTINCT (i.surname + " " + i.secondSurname)) AS LlistaCognoms
ORDER BY AnyPadro

// D'aquesta manera eliminem les parelles de cognoms duplicades i els habitants que tenen un nan a algun dels cognoms (NO SÉ SI ÉS EXACTAMENT EL QUE DEMANEN)

// Aquí podem veure com existeixen inidividus amb un nan a alguns dels cognoms:

MATCH (i:Individu)-[:VIU]->(h:Habitatge)
WHERE h.location = "CR" 
AND (i.surname IS NULL OR i.surname = "nan" OR i.surname = "" OR i.secondSurname IS NULL OR i.secondSurname = "nan" OR i.secondSurname = "") 
RETURN i.name



B) Retorna el nom de les persones que vivien al mateix habitatge que "rafel marti" (no té segon cognom) segons el padró de 1838 de Sant Feliu de Llobregat (SFLL). Retorna la informació en mode graf i mode llista. 

MATCH (i:Individu)-[:VIU]->(h:Habitatge)
WHERE i.name = "rafel" AND i.surname = "marti" AND h.anyPadro = 1838 AND h.location = "SFLL"
MATCH (i2:Individu)-[:VIU]->(h)
WHERE i2 <> i
RETURN i2



C) Retorna totes les aparicions de "miguel estape bofill". Fes servir la relació SAME_AS per poder retornar totes les instancies, independentment de si hi ha variacions lèxiques (ex. diferents formes d'escriure el seu nom/cognoms). Mostra la informació en forma de taula: el nom, la llista de cognoms i la llista de segon cognom (elimina duplicats). 

MATCH (i1:Individu)-[:SAME_AS*0..]-(i2:Individu)
WHERE i1.name = "miguel" AND i1.surname = "estape" AND i1.secondSurname = "bofill"
RETURN i2.name AS Nom, collect(DISTINCT i2.surname) AS Cognom, collect(DISTINCT i2.secondSurname) AS SegonCognom



D) Mitja de fills a Sant Feliu de Llobregat l’any 1881 per família. Mostreu el total de fills, el nombre d’habitatges i la mitja de fills per habitatge. Fes servir CALL per obtenir el nombre de llars. 

CALL () {
    MATCH (h:Habitatge)
    WHERE h.location = "SFLL" AND h.anyPadro = 1881
    RETURN count(h) AS TotalHabitatges
}

MATCH (i1:Individu)-[:VIU]->(h:Habitatge)
WHERE h.location = "SFLL" AND h.anyPadro = 1881
MATCH (i1)-[rel:FAMILIA]->(i2:Individu)
WHERE rel.relacioHarmonitzada IN ["fill", "filla"]
WITH count(i2) AS TotalFills, TotalHabitatges 
RETURN TotalFills, TotalHabitatges, toFloat(TotalFills) / TotalHabitatges AS MitjaFillsPerHabitatge



E) Mostreu les famílies de Castellví de Rosanes amb més de 3 fills. Mostreu el nom i cognoms del cap de família i el nombre de fills. Ordeneu-les pel nombre de fills fins a un límit de 20, de més a menys.  

MATCH (i:Individu)-[:VIU]->(h:Habitatge)
WHERE h.location = "CR"
MATCH (i)-[rel:FAMILIA]->(i2:Individu)
WHERE rel.relacioHarmonitzada in ["fill", "filla"]
WITH i, count(i2) AS TotalFills
WHERE TotalFills > 3
RETURN i.name AS NomCap, i.surname AS CognomCap, i.secondSurname AS SegonCognomCap, TotalFills
ORDER BY TotalFills DESC
LIMIT 20



F) Per cada padró/any de Sant Feliu de Llobregat, mostra el carrer amb menys habitants i el nombre d’habitants en aquell carrer. Fes servir la funció min() i CALL per obtenir el nombre mínim d’habitants. Ordena els resultats per any de forma ascendent. 

MATCH (i:Individu)-[:VIU]->(h:Habitatge)
WHERE h.location = "SFLL"
WITH h.anyPadro AS AnyPadro, h.carrer AS Carrer, count(i) AS HabitantsPerCarrer

CALL (AnyPadro) {
    MATCH (i2:Individu)-[:VIU]->(h2:Habitatge)
    WHERE h2.location = "SFLL" AND h2.anyPadro = AnyPadro
    WITH h2.carrer AS Carrer2, count(i2) AS Habitants2
    RETURN min(Habitants2) AS MinHabitants
}

WITH AnyPadro, Carrer, HabitantsPerCarrer, MinHabitants
WHERE HabitantsPerCarrer = MinHabitants
RETURN AnyPadro, Carrer, HabitantsPerCarrer AS TotalHabitants
ORDER BY AnyPadro


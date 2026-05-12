// EXERCICI 2 - Consultes Grup 10

//A) Per a cada padró (any) de Castellví de Rosanes, retorna l’any de padró, el número d'habitants, i la llista de cognoms. Elimina duplicats i “nan”.

// Aquí podem veure com existeixen inidividus amb un nan a alguns dels cognoms:

MATCH (i:Individu)-[:VIU]->(h:Habitatge)
WHERE h.location = "CR"
AND (i.surname IS NULL OR i.surname = "nan" OR i.surname = "" OR i.secondSurname IS NULL OR i.secondSurname = "nan" OR i.secondSurname = "")
RETURN i.name

//OPCIO A
// En aquest cas no eliminem individus amb "nan", sinó que reconstruïm el cognom per no perdre habitants.
// També eliminem duplicats amb DISTINCT.

MATCH (i:Individu)-[:VIU]->(h:Habitatge)
WHERE h.location = "CR"
WITH h.anyPadro AS Any,ç
     i,
     CASE
        WHEN i.secondSurname IS NULL OR i.secondSurname = "nan" OR i.secondSurname = "" 
        THEN i.surname
        ELSE i.surname + " " + i.secondSurname
     END AS CognomNet
WHERE CognomNet IS NOT NULL AND CognomNet <> "nan" AND CognomNet <> ""
RETURN Any AS AnyPadro, count(DISTINCT i) AS NumeroHabitants, collect(DISTINCT CognomNet) AS LlistaCognoms
ORDER BY AnyPadro

//OPCIO B
//En aquest cas si eliminem els individus amb "nan"
// D'aquesta manera eliminem les parelles de cognoms duplicades i els habitants que tenen un nan a algun dels cognoms 

MATCH (i:Individu)-[:VIU]->(h:Habitatge)
WHERE h.location = "CR"
AND i.surname IS NOT NULL AND i.surname <> "nan" AND i.surname <> ""
AND i.secondSurname IS NOT NULL AND i.secondSurname <> "nan" AND i.secondSurname <> ""
RETURN h.anyPadro AS AnyPadro, count(DISTINCT i) AS NumeroHabitants, collect(DISTINCT (i.surname + " " + i.secondSurname)) AS LlistaCognoms
ORDER BY AnyPadro


//B) Retorna el nom de les persones que vivien al mateix habitatge que "rafel marti" (no té segon cognom) segons el padró de 1838 de //Sant Feliu de Llobregat (SFLL). Retorna la informació en mode graf i mode llista.

//Mode llista

MATCH (rafel:Individu {name: "rafel", surname: "marti"})-[:VIU]->(h:Habitatge {anyPadro: 1838, location: "SFLL"})
MATCH (altre:Individu)-[:VIU]->(h)
WHERE altre <> rafel
RETURN altre.name AS Nom;

//Mode graf

MATCH (rafel:Individu {name: "rafel", surname: "marti"})-[:VIU]->(h:Habitatge {anyPadro: 1838, location: "SFLL"})<-[:VIU]-(altre:Individu)
RETURN rafel, h, altre;


//C) Retorna totes les aparicions de "miguel estape bofill". Fes servir la relació SAME_AS per poder retornar totes les instancies, //independentment de si hi ha variacions lèxiques (ex. diferents formes d'escriure el seu nom/cognoms). Mostra la informació en forma //de taula: el nom, la llista de cognoms i la llista de segon cognom (elimina duplicats).

MATCH (i1:Individu)-[:SAME_AS*0..]-(i2:Individu)
WHERE i1.name = "miguel" AND i1.surname = "estape" AND i1.secondSurname = "bofill"
RETURN i2.name AS Nom,
       collect(DISTINCT i2.surname) AS Cognoms,
       collect(DISTINCT i2.secondSurname) AS SegonsCognoms;


// D) Mitja de fills a Sant Feliu de Llobregat l'any 1881 per família.
// Fes servir CALL per obtenir el nombre de llars.

CALL () {
    MATCH (h:Habitatge)
    WHERE h.location = "SFLL" AND h.anyPadro = 1881
    RETURN count(DISTINCT h) AS TotalHabitatges
}

MATCH (h:Habitatge {location: "SFLL", anyPadro: 1881})<-[:VIU]-(i1:Individu)
MATCH (i1)-[rel:FAMILIA]->(i2:Individu)
WHERE rel.relacioHarmonitzada IN ["fill", "filla"]

WITH count(DISTINCT i2) AS TotalFills, TotalHabitatges
RETURN TotalFills,
       TotalHabitatges,
       toFloat(TotalFills) / TotalHabitatges AS MitjaFillsPerHabitatge;


//E) Mostreu les famílies de Castellví de Rosanes amb més de 3 fills. Mostreu el nom i cognoms del cap de família i el nombre de //fills. Ordeneu-les pel nombre de fills fins a un límit de 20, de més a menys.

MATCH (cap:Individu)-[:VIU]->(h:Habitatge)
WHERE h.location = "CR"
MATCH (cap)-[rel:FAMILIA]->(fill:Individu)
WHERE rel.relacioHarmonitzada in ["fill", "filla"]

WITH cap, count(DISTINCT fill) AS TotalFills
WHERE TotalFills > 3

RETURN cap.name AS NomCap, cap.surname AS CognomCap, cap.secondSurname AS SegonCognomCap, TotalFills
ORDER BY TotalFills DESC
LIMIT 20;


//F) Per cada padró/any de Sant Feliu de Llobregat, mostra el carrer amb menys habitants i el nombre d’habitants en aquell carrer. //Fes servir la funció min() i CALL per obtenir el nombre mínim d’habitants. Ordena els resultats per any de forma ascendent.

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

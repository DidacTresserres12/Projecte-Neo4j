// EXERCICI 4 - Analítica de Grafs

// 1. Estudi de les components connexes (cc) i de l’estructura de les components en funció de la seva mida. Feu servir el mode
// stream. Un cop calculades les components connexes (nodes individu, habitatge i relació VIU), feu dues consultes per explorar
// les dades. Per exemple (podeu fer altres consultes): 

// Primer carreguem el graf en memòria

CALL gds.graph.project(
  'grafCC',
  ['Individu', 'Habitatge'],
  'VIU'
)

// 1.1. Mostra, en forma de taula, les 10 components connexes més grans (ids i mida). 

CALL gds.wcc.stream('grafCC')
YIELD componentId, nodeId
WITH componentId, size(collect(nodeId)) as mida
ORDER BY mida DESC
LIMIT 10
RETURN componentId AS ComponentID, mida as Mida


// 1.2. Per cada municipi i any, mostra el nombre de parelles del tipus: (Individu)—(Habitatge). 

CALL gds.wcc.stream('grafCC')
YIELD nodeId, componentId
MATCH (n) WHERE id(n) = nodeId
WITH componentId, collect(n) AS nodes
UNWIND nodes AS n1
UNWIND nodes AS n2
WITH componentId, n1, n2
WHERE n1:Individu AND n2:Habitatge
MATCH (n1)-[:VIU]->(n2)
RETURN n2.location AS Municipi, n2.anyPadro AS Any, count(*) AS NombreParelles
ORDER BY Municipi, Any




// 2. Semblança entre els nodes. Ens interessa saber quins nodes són semblants com a pas previ a identificar els individus que 
// són el mateix (i unirem amb una aresta de tipus SAME_AS). Abans de fer aquest anàlisi:

// 2.1. Determineu els habitatges que són els mateixos al llarg dels anys. Afegiu una aresta amb nom “MATEIX_HAB“ entre aquests 
// habitatges. Per evitar arestes duplicades feu que la aresta apunti al habitatge amb any de padró més petit. 

MATCH (h1:Habitatge)
MATCH (h2:Habitatge)
WHERE h1.llarId = h2.llarId AND h1.location = h2.location AND h1.anyPadro < h2.anyPadro
MERGE (h1)-[:MATEIX_HAB]->(h2)
RETURN count(*) AS ArestesMATEIX_HAB


// 2.2. Creeu un graf en memòria que inclogui els nodes Individu i Habitatge i les relacions VIU, FAMILIA, MATEIX_HAB que acabeu de crear. 

CALL gds.graph.project(
  'grafSimilitud',
  ['Individu', 'Habitatge'],
  ['VIU', 'FAMILIA', 'MATEIX_HAB']
)


// 2.3. Calculeu la similitud entre els nodes del graf que acabeu de crear, escriviu el resultat de nou a la base de dades i interpreteu els resultats obtinguts. 

CALL gds.nodeSimilarity.write('grafSimilitud', {
  writeRelationshipType: 'SIMILAR',
  writeProperty: 'score'
})
YIELD nodesCompared, relationshipsWritten
RETURN nodesCompared, relationshipsWritten


// Verifiquem que s'ha escrit bé el resultat a la base de dades

CALL gds.nodeSimilarity.write('grafSimilitud', {
  writeRelationshipType: 'SIMILAR',
  writeProperty: 'score'
})
YIELD nodesCompared, relationshipsWritten
RETURN nodesCompared, relationshipsWritten
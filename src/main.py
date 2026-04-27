"""
main.py - Exemples de connexió a MongoDB i Neo4j
Bases de Dades no Relacionals (BDnR) - UAB

Configuració: copia .env.example a .env i omple les credencials.
"""

import os
from dotenv import load_dotenv

load_dotenv()


# ---------------------------------------------------------------------------
# MongoDB
# ---------------------------------------------------------------------------

def connect_mongodb():
    """Connecta a MongoDB i retorna el client i la base de dades."""
    from pymongo import MongoClient
    from pymongo.errors import ConnectionFailure

    uri = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
    db_name = os.getenv("MONGODB_DB", "bdnr")

    client = MongoClient(uri)
    try:
        # Comprova que la connexió és correcta
        client.admin.command("ping")
        print(f"[MongoDB] Connexió establerta correctament a '{db_name}'.")
    except ConnectionFailure as e:
        client.close()
        print(f"[MongoDB] Error de connexió: {e}")
        raise

    return client, client[db_name]


def example_mongodb(db):
    """Exemples bàsics d'operacions CRUD a MongoDB."""
    col = db["exemple"]

    # Inserir un document
    result = col.insert_one({"nom": "UAB", "tipus": "universitat"})
    print(f"[MongoDB] Document inserit amb _id: {result.inserted_id}")

    # Cercar documents
    doc = col.find_one({"nom": "UAB"})
    print(f"[MongoDB] Document trobat: {doc}")

    # Esborrar el document de prova
    col.delete_one({"_id": result.inserted_id})
    print("[MongoDB] Document de prova esborrat.")


# ---------------------------------------------------------------------------
# Neo4j
# ---------------------------------------------------------------------------

def connect_neo4j():
    """Connecta a Neo4j i retorna el driver."""
    from neo4j import GraphDatabase
    from neo4j.exceptions import ServiceUnavailable

    uri = os.getenv("NEO4J_URI", "bolt://localhost:7687")
    user = os.getenv("NEO4J_USER", "neo4j")
    password = os.getenv("NEO4J_PASSWORD", "password")

    driver = GraphDatabase.driver(uri, auth=(user, password))
    try:
        driver.verify_connectivity()
        print("[Neo4j] Connexió establerta correctament.")
    except ServiceUnavailable as e:
        print(f"[Neo4j] Error de connexió: {e}")
        raise

    return driver


def example_neo4j(driver):
    """Exemples bàsics d'operacions amb Neo4j."""
    with driver.session() as session:
        # Crear un node
        session.run(
            "CREATE (n:Universitat {nom: $nom}) RETURN n",
            nom="UAB",
        )
        print("[Neo4j] Node 'Universitat' creat.")

        # Cercar nodes
        result = session.run(
            "MATCH (n:Universitat {nom: $nom}) RETURN n.nom AS nom",
            nom="UAB",
        )
        for record in result:
            print(f"[Neo4j] Node trobat: {record['nom']}")

        # Esborrar el node de prova
        session.run("MATCH (n:Universitat {nom: $nom}) DELETE n", nom="UAB")
        print("[Neo4j] Node de prova esborrat.")


# ---------------------------------------------------------------------------
# Punt d'entrada
# ---------------------------------------------------------------------------

def main():
    use_mongodb = os.getenv("USE_MONGODB", "true").lower() == "true"
    use_neo4j = os.getenv("USE_NEO4J", "false").lower() == "true"

    if use_mongodb:
        client, db = connect_mongodb()
        try:
            example_mongodb(db)
        finally:
            client.close()

    if use_neo4j:
        driver = connect_neo4j()
        try:
            example_neo4j(driver)
        finally:
            driver.close()


if __name__ == "__main__":
    main()

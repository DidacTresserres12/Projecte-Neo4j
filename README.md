# Bases de Dades no Relacionals (BDnR)
## Grau de Matemàtica Computacional i Analítica de Dades, UAB

Aquest repositori conté el punt de partida pels projectes  en Python per connectar-se i treballar amb bases de dades no relacionals, concretament **MongoDB** i **Neo4j**.

## Contingut

- `src/main.py`: Script principal amb exemples de connexió a MongoDB i Neo4j.
- `.env.example`: Plantilla amb les variables d'entorn necessàries.

## Requisits

- Python 3.8+
- Paquets necessaris: `pymongo`, `neo4j`, `python-dotenv`

Instal·lació de dependències:

```bash
pip install pymongo neo4j python-dotenv
```

## Configuració

1. Copia el fitxer `.env.example` a `.env`:

```bash
cp .env.example .env
```

2. Edita `.env` amb les teves credencials de MongoDB i/o Neo4j.

## Execució

```bash
python src/main.py
```

## Llicència

Vegeu el fitxer [LICENSE](LICENSE).

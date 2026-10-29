"""Verify live YAGO graph without fabricating expected source counts."""
import json
import os
from datetime import datetime, timezone
from pathlib import Path
from neo4j import GraphDatabase

QUERIES = {
    "movies": "MATCH (n:Movie) RETURN count(n) AS count",
    "people": "MATCH (n:Person) RETURN count(n) AS count",
    "genres": "MATCH (n:Genre) RETURN count(n) AS count",
    "acted_in": "MATCH (:Movie)-[r:ACTED_IN]->(:Person) RETURN count(r) AS count",
    "directed": "MATCH (:Movie)-[r:DIRECTED_BY]->(:Person) RETURN count(r) AS count",
    "has_genre": "MATCH (:Movie)-[r:HAS_GENRE]->(:Genre) RETURN count(r) AS count",
    "crud_remaining": "MATCH (m:Movie {id:'urn:demo:movie:crud'}) RETURN count(m) AS count",
}
def main():
    uri = os.getenv("TUGRAPH_URI", "bolt://127.0.0.1:17687")
    user = os.getenv("TUGRAPH_USER", "admin")
    password = os.environ["TUGRAPH_PASSWORD"]
    graph = os.getenv("TUGRAPH_GRAPH", "yago_movies")
    with GraphDatabase.driver(uri, auth=(user, password)) as driver:
        with driver.session(database=graph) as session:
            counts = {k: session.run(q).single()["count"] for k, q in QUERIES.items()}
    assert counts["movies"] > 0, "No YAGO movies imported"
    assert counts["crud_remaining"] == 0, "CRUD demo node remains"
    result = {"captured_at": datetime.now(timezone.utc).isoformat(), "graph": graph, "counts": counts}
    p = Path("evidence/yago-results.json")
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps(result, indent=2))
if __name__ == "__main__":
    main()

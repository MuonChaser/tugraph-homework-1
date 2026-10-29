"""Compare live graph counts with CSV rows; run after import and CRUD deletion."""
import csv
import json
import os
from pathlib import Path
from neo4j import GraphDatabase

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data" / "movie_csv"

def num_rows(name):
    with (DATA / name).open(encoding="utf-8", newline="") as f:
        return sum(1 for _ in csv.reader(f)) - 1

def main():
    expected = {"movies": num_rows("movies.csv"), "people": num_rows("people.csv"),
                "produced": num_rows("produced.csv"), "crud_remaining": 0}
    queries = {
        "movies": "MATCH (n:Movie) RETURN count(n) AS n",
        "people": "MATCH (n:Person) RETURN count(n) AS n",
        "produced": "MATCH (:Person)-[r:PRODUCED]->(:Movie) RETURN count(r) AS n",
        "crud_remaining": "MATCH (n:Movie {id:-999999}) RETURN count(n) AS n",
    }
    with GraphDatabase.driver(os.environ.get("TUGRAPH_URI", "bolt://127.0.0.1:17687"),
                              auth=(os.getenv("TUGRAPH_USER", "admin"),
                                    os.environ["TUGRAPH_PASSWORD"])) as driver:
        with driver.session(database=os.getenv("TUGRAPH_GRAPH", "movie_csv_demo")) as s:
            actual = {key: s.run(query).single()["n"] for key,query in queries.items()}
    result = {"expected": expected, "actual": actual, "passed": actual == expected}
    destination = ROOT / "evidence" / "movie-csv-results.json"
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(result, indent=2), encoding="utf-8")
    if not result["passed"]:
        raise AssertionError(f"Unexpected counts: {result}")
    print(json.dumps(result, indent=2))

if __name__ == "__main__":
    main()

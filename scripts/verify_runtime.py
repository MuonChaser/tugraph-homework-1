"""Read the running TuGraph graph and save reproducible verification evidence."""
import json
import os
from datetime import datetime, timezone, timedelta
from pathlib import Path
from neo4j import GraphDatabase

ROOT = Path(__file__).resolve().parents[1]
QUERIES = {
    "nodes": "MATCH (n) RETURN label(n) AS label, count(n) AS total ORDER BY label",
    "relationships": "MATCH ()-[r]->() RETURN label(r) AS label, count(r) AS total ORDER BY label",
    "aggregate": (
        "MATCH (d:Disease)-[:HAS_SYMPTOM]->(s:Symptom) "
        "RETURN d.name AS disease, count(DISTINCT s) AS symptom_count "
        "ORDER BY symptom_count DESC, disease"
    ),
    "deleted_demo_count": (
        "MATCH (x:Symptom {name:'临时症状-CRUD'}) RETURN count(x) AS remaining"
    ),
    "symptoms_query": (
        "MATCH (d:Disease)-[:HAS_SYMPTOM]->(s:Symptom) "
        "WHERE d.name = $disease RETURN d.name AS disease, collect(s.name) AS symptoms"
    ),
}

def main():
    uri = os.environ.get("TUGRAPH_URI", "bolt://127.0.0.1:17687")
    username = os.environ.get("TUGRAPH_USER", "admin")
    password = os.environ.get("TUGRAPH_PASSWORD", "73@TuGraph")
    result = {"captured_at": datetime.now(timezone(timedelta(hours=8))).isoformat(), "graph": "medical_demo", "queries": QUERIES}
    with GraphDatabase.driver(uri, auth=(username, password)) as driver:
        with driver.session(database="medical_demo") as session:
            for name, query in QUERIES.items():
                result[name] = session.run(query, {"disease": "普通感冒"}).data()
    assert {r["label"]: r["total"] for r in result["nodes"]} == {"Department": 3, "Disease": 4, "Drug": 3, "Symptom": 7}
    assert {r["label"]: r["total"] for r in result["relationships"]} == {"BELONGS_TO": 4, "HAS_SYMPTOM": 12, "TREATS": 4}
    assert {r["disease"]: r["symptom_count"] for r in result["aggregate"]} == {"普通感冒": 4, "流行性感冒": 3, "过敏性鼻炎": 3, "急性咽炎": 2}
    assert result["deleted_demo_count"] == [{"remaining": 0}]
    result["verification"] = "passed"
    destination = ROOT / "evidence" / "results.json"
    destination.parent.mkdir(exist_ok=True)
    destination.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(result, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()

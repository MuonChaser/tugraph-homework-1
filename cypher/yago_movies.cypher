// Select the yago_movies graph in TuGraph Browser. Run statements separately.
// Label counts
MATCH (n:Movie) RETURN count(n) AS movies;
MATCH (n:Person) RETURN count(n) AS people;
MATCH (n:Genre) RETURN count(n) AS genres;
// Most frequent movie genres
MATCH (m:Movie)-[:HAS_GENRE]->(g:Genre)
RETURN g.name AS genre, count(DISTINCT m) AS movies
ORDER BY movies DESC LIMIT 20;
// Most prolific directors in the imported subgraph
MATCH (m:Movie)-[:DIRECTED_BY]->(p:Person)
RETURN p.name AS director, count(DISTINCT m) AS movies
ORDER BY movies DESC LIMIT 20;
// Cast size distribution by film
MATCH (m:Movie)-[:ACTED_IN]->(p:Person)
RETURN m.name AS movie, count(DISTINCT p) AS cast_size
ORDER BY cast_size DESC LIMIT 20;
// Actor co-appearances (pair is counted once per movie)
MATCH (m:Movie)-[:ACTED_IN]->(a:Person), (m)-[:ACTED_IN]->(b:Person)
WHERE a.id < b.id
RETURN a.name AS actor_a, b.name AS actor_b, count(DISTINCT m) AS common_movies
ORDER BY common_movies DESC LIMIT 20;
// Isolated test record, not imported YAGO data. Run CRUD in order.
CREATE (m:Movie {id:'urn:demo:movie:crud', name:'CRUD demo'}) RETURN m.id, m.name;
MATCH (m:Movie {id:'urn:demo:movie:crud'}) RETURN m.id, m.name;
MATCH (m:Movie {id:'urn:demo:movie:crud'}) SET m.name='CRUD updated' RETURN m.name;
MATCH (m:Movie {id:'urn:demo:movie:crud'}) DELETE m;
MATCH (m:Movie {id:'urn:demo:movie:crud'}) RETURN count(m) AS remaining;

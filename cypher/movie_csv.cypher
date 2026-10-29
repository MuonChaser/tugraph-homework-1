// Select graph movie_csv_demo and execute one statement at a time.
// Dataset: 54 Movie nodes, 665 Person nodes, 60 PRODUCED edges before CRUD.
MATCH (m:Movie) RETURN count(m) AS movies;
MATCH (p:Person) RETURN count(p) AS people;
MATCH (:Person)-[r:PRODUCED]->(:Movie) RETURN count(r) AS produced_edges;

// Producer-to-film mapping
MATCH (p:Person)-[:PRODUCED]->(m:Movie)
RETURN p.name AS producer, m.title AS movie
ORDER BY producer, movie LIMIT 30;

// Films produced per person
MATCH (p:Person)-[:PRODUCED]->(m:Movie)
RETURN p.name AS producer, count(DISTINCT m) AS movie_count
ORDER BY movie_count DESC, producer LIMIT 20;

// Producing people per movie
MATCH (p:Person)-[:PRODUCED]->(m:Movie)
RETURN m.title AS movie, count(DISTINCT p) AS producer_count
ORDER BY producer_count DESC, movie LIMIT 20;

// Distribution of film running time (only movies with positive duration)
MATCH (m:Movie)
WHERE m.duration > 0
RETURN m.rated AS rating, count(m) AS movie_count, avg(m.duration) AS avg_duration
ORDER BY movie_count DESC;

// CRUD on disposable test node (not source data).
CREATE (m:Movie {id:-999999, title:'CRUD demo', tagline:'test', duration:0})
RETURN m.id AS id, m.title AS title;
MATCH (m:Movie {id:-999999}) RETURN m.id AS id, m.title AS title;
MATCH (m:Movie {id:-999999}) SET m.title='CRUD updated' RETURN m.title AS title;
MATCH (m:Movie {id:-999999}) DELETE m;
MATCH (m:Movie {id:-999999}) RETURN count(m) AS remaining;

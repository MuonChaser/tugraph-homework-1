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


// --- 电影属性筛选：按时长排序 ---
MATCH (m:Movie)
WHERE m.duration >= 120
RETURN m.id AS movie_id, m.title AS title, m.duration AS minutes, m.rated AS rating
ORDER BY minutes DESC, title LIMIT 20;

// --- 电影标题关键词检索（大小写不敏感） ---
MATCH (m:Movie)
WHERE toLower(m.title) CONTAINS 'matrix'
RETURN m.id AS movie_id, m.title AS title, m.duration AS minutes;

// --- 按姓名检索制作人员及关联电影 ---
MATCH (p:Person)-[:PRODUCED]->(m:Movie)
WHERE toLower(p.name) CONTAINS 'smith'
RETURN p.id AS person_id, p.name AS producer, m.title AS movie
ORDER BY producer, movie LIMIT 30;

// --- 按出生年代统计人物数量：仅使用有效年份 ---
MATCH (p:Person)
WHERE p.born >= 1900 AND p.born < 2100
RETURN (p.born / 10) * 10 AS decade, count(p) AS people
ORDER BY decade;

// --- 电影时长整体统计 ---
MATCH (m:Movie)
WHERE m.duration > 0
RETURN count(m) AS films_with_duration,
       min(m.duration) AS shortest_minutes,
       max(m.duration) AS longest_minutes,
       avg(m.duration) AS average_minutes;

// --- 两跳关系：共同参与某部电影制作的人物对 ---
// 使用 ID 比较去除 a/b、b/a 形式的重复对。
MATCH (a:Person)-[:PRODUCED]->(m:Movie)<-[:PRODUCED]-(b:Person)
WHERE a.id < b.id
RETURN m.title AS movie, a.name AS producer_a, b.name AS producer_b
ORDER BY movie, producer_a, producer_b LIMIT 50;

// --- 制作人员合作次数：共同参与多部电影制作 ---
MATCH (a:Person)-[:PRODUCED]->(m:Movie)<-[:PRODUCED]-(b:Person)
WHERE a.id < b.id
RETURN a.name AS producer_a, b.name AS producer_b,
       count(DISTINCT m) AS shared_movies
ORDER BY shared_movies DESC, producer_a, producer_b LIMIT 20;

// --- 同一制作人员关联的不同电影对 ---
MATCH (m1:Movie)<-[:PRODUCED]-(p:Person)-[:PRODUCED]->(m2:Movie)
WHERE m1.id < m2.id
RETURN p.name AS producer, m1.title AS movie_a, m2.title AS movie_b
ORDER BY producer, movie_a, movie_b LIMIT 30;

// --- 未关联任何制作人员的电影 ---
MATCH (m:Movie)
WHERE NOT (m)<-[:PRODUCED]-(:Person)
RETURN m.id AS movie_id, m.title AS title ORDER BY title;

// --- 没有制作关系的人物数量 ---
MATCH (p:Person)
WHERE NOT (p)-[:PRODUCED]->(:Movie)
RETURN count(p) AS people_without_production;

// --- 数据检查：同名电影、人物分别统计（不同 ID 允许同名） ---
MATCH (m:Movie)
RETURN m.title AS title, count(m) AS occurrences
ORDER BY occurrences DESC, title LIMIT 20;

MATCH (p:Person)
RETURN p.name AS name, count(p) AS occurrences
ORDER BY occurrences DESC, name LIMIT 20;

// --- 制作关系图可视化 ---
MATCH (p:Person)-[r:PRODUCED]->(m:Movie)
RETURN p, r, m LIMIT 40;

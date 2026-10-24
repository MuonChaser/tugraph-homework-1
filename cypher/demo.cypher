// 建议先在 Browser 中选中 medical_demo 图，再逐条执行。

// 节点和关系数量核对
MATCH (n) RETURN label(n) AS label, count(n) AS total ORDER BY label;
MATCH ()-[r]->() RETURN label(r) AS label, count(r) AS total ORDER BY label;
MATCH (n:Disease) RETURN count(n) AS disease_count;
MATCH (n:Symptom) RETURN count(n) AS symptom_count;
MATCH (n:Department) RETURN count(n) AS department_count;
MATCH (n:Drug) RETURN count(n) AS drug_count;
MATCH ()-[r]->() RETURN count(r) AS relationship_count;

// 根据疾病查询症状和科室
MATCH (d:Disease)-[:HAS_SYMPTOM]->(s:Symptom)
WHERE d.name = '普通感冒'
RETURN d.name AS disease, collect(s.name) AS symptoms;

MATCH (d:Disease)-[:BELONGS_TO]->(dept:Department)
WHERE d.name = '普通感冒'
RETURN d.name AS disease, dept.name AS department;

// 聚合：统计每种疾病的症状数
MATCH (d:Disease)-[:HAS_SYMPTOM]->(s:Symptom)
RETURN d.name AS disease, count(DISTINCT s) AS symptom_count
ORDER BY symptom_count DESC;

// CRUD：创建、读、改、删一条临时记录
CREATE (x:Symptom {name:'临时症状-CRUD', severity:'测试'}) RETURN x.name AS name, x.severity AS severity;
MATCH (x:Symptom {name:'临时症状-CRUD'}) RETURN x.name AS name, x.severity AS severity;
MATCH (x:Symptom {name:'临时症状-CRUD'}) SET x.severity = '已修改' RETURN x.name AS name, x.severity AS severity;
MATCH (x:Symptom {name:'临时症状-CRUD'}) DELETE x;
MATCH (x:Symptom {name:'临时症状-CRUD'}) RETURN count(x) AS remaining;

# 作业一：基于 TuGraph 的电影知识图谱构建与查询分析

## 一、实验目的

本实验以电影及其制作人员之间的关联为研究对象，使用 TuGraph 图数据库构建属性图，完成电影数据的整理、图模型设计、CSV 批量导入、Cypher 增删改查与关系分析。重点考察图数据库在实体关联、多跳关系检索以及分组聚合等任务中的应用。

## 二、实验数据

实验使用三份 CSV 文件，分别记录电影信息、人物信息及人物与电影之间的制作关系。

| 数据文件 | 内容 | 记录数 |
| --- | --- | ---: |
| [movie.csv](data/source/movie.csv) | 电影标题、简介、时长、分级等 | 54 |
| [person.csv](data/source/person.csv) | 人物姓名、出生年份、图片等 | 665 |
| [produce.csv](data/source/produce.csv) | 人物与电影的制作关系 | 60 |

由此建立包含 **719 个实体节点、60 条制作关系** 的属性图数据。原始数据中，`produce.csv` 的两列分别为人物 ID 和电影 ID，关系的两个端点均可在相应节点表中找到。

### 2.1 属性图模型

电影实体记为 `Movie`，人物实体记为 `Person`，制作关系记为 `PRODUCED`。图的基本结构为：

```text
(Person)-[:PRODUCED]->(Movie)
```

| 类型 | 主键 | 属性 |
| --- | --- | --- |
| Movie | id（INT32） | title、tagline、summary、poster_image、duration、rated |
| Person | id（INT32） | name、born、poster_image |
| PRODUCED | 人物 ID → 电影 ID | 表示人物参与该电影的制作 |

使用整数 ID 而非姓名或标题作为实体主键，可以区分同名人物和同名电影；以有向边表示制作关系，可以通过图模式匹配直接检索人物对应的电影，也可以反向查找一部电影关联的制作人员。

## 三、实验环境与数据导入

实验使用 **TuGraph 4.5.1**，采用 Docker Desktop 提供 Linux 容器环境，通过 TuGraph 的 `lgraph_import` 工具进行离线数据导入。

节点源文件带有标签及字段类型行，关系文件使用人物、电影 ID 表示连接。为统一导入格式，编写 [prepare_movie_csv.py](scripts/prepare_movie_csv.py) 对三份 CSV 进行编码处理、字段整理、主键唯一性检查与关系端点检查，生成标准表头的节点和边文件。

```text
data/source/movie.csv  ──> data/movie_csv/movies.csv
data/source/person.csv ──> data/movie_csv/people.csv
data/source/produce.csv ─> data/movie_csv/produced.csv
```

图的标签、属性类型、主键、边约束和文件字段映射定义在 [import.json](data/movie_csv/import.json) 中，数据库图名为 `movie_csv_demo`。

在 Windows PowerShell 中，项目的部署入口为：

```powershell
git clone https://github.com/MuonChaser/tugraph-homework-1.git
cd tugraph-homework-1
.\setup.ps1
```

脚本依次执行数据预处理、TuGraph 4.5.1 环境构建、CSV 数据导入和服务启动。Browser 地址为 `http://127.0.0.1:17070`，Bolt 地址为 `bolt://127.0.0.1:17687`。

### TuGraph Browser 界面

![TuGraph Browser 登录页面](https://raw.githubusercontent.com/Ruinan-Li/SSH/89ccf6fa4e501216d13192572261d2b5ed29b785/screenshots/01-login.png)

*图 1　TuGraph Browser 登录页面。*

![TuGraph 图项目管理页面](https://raw.githubusercontent.com/Ruinan-Li/SSH/89ccf6fa4e501216d13192572261d2b5ed29b785/screenshots/02-console.png)

*图 2　TuGraph 图项目管理页面。*


## 四、Cypher 查询与数据操作

完整查询语句见 [cypher/movie_csv.cypher](cypher/movie_csv.cypher)。本实验从基本查询、聚合分析、多跳关系和增删改查四个层次组织数据库操作。

![TuGraph Cypher 语句查询界面](https://raw.githubusercontent.com/Ruinan-Li/SSH/89ccf6fa4e501216d13192572261d2b5ed29b785/screenshots/04-import.png)

*图 3　Cypher 查询编辑器及列表结果展示界面示例。界面中的语句及记录仅用于展示查询交互方式。*


### 4.1 节点和关系数量统计

分别统计电影、人物和制作关系数量，检查各标签的数据规模。

```cypher
MATCH (m:Movie) RETURN count(m) AS movies;
MATCH (p:Person) RETURN count(p) AS people;
MATCH (:Person)-[r:PRODUCED]->(:Movie)
RETURN count(r) AS produced_edges;
```

### 4.2 按条件检索电影

利用属性过滤查询时长不少于 120 分钟的电影，并按照时长降序排列。

```cypher
MATCH (m:Movie)
WHERE m.duration >= 120
RETURN m.title AS title, m.duration AS minutes, m.rated AS rating
ORDER BY minutes DESC, title LIMIT 20;
```

同时使用 `toLower` 与 `CONTAINS` 实现标题、人物姓名的关键词查询，展示图数据库对属性条件和关系条件的组合支持。

### 4.3 统计制作人员的参与电影数

对每名制作人员关联的电影进行去重计数，识别在当前数据集内参与作品较多的人物。

```cypher
MATCH (p:Person)-[:PRODUCED]->(m:Movie)
RETURN p.name AS producer, count(DISTINCT m) AS movie_count
ORDER BY movie_count DESC, producer LIMIT 20;
```

同理，以电影为分组单位统计关联制作人员数量，可用于比较不同电影的制作关系规模。

### 4.4 多跳关系：共同参与电影制作

通过 `Person → Movie ← Person` 的两跳图模式，找到共同参与同一部电影制作的两个人。条件 `a.id < b.id` 避免重复返回同一对人物。

```cypher
MATCH (a:Person)-[:PRODUCED]->(m:Movie)<-[:PRODUCED]-(b:Person)
WHERE a.id < b.id
RETURN m.title AS movie, a.name AS producer_a, b.name AS producer_b
ORDER BY movie, producer_a, producer_b LIMIT 50;
```

进一步以人物对为分组单位，通过 `count(DISTINCT m)` 统计合作影片数量。相反方向的 `Movie ← Person → Movie` 模式则可以寻找共享制作人员的两部电影。

### 4.5 属性聚合与图完整性查询

根据影片分级 `rated` 对电影数量及平均时长进行汇总，并结合 `min`、`max`、`avg` 等聚合函数分析电影时长分布。对 `born` 字段进行年代分组，描述人物出生年份分布。

利用否定关系模式，可以找出缺少制作关系的电影：

```cypher
MATCH (m:Movie)
WHERE NOT (m)<-[:PRODUCED]-(:Person)
RETURN m.id AS movie_id, m.title AS title
ORDER BY title;
```

这一查询也可以对应扩展为“没有制作关系的人物”，从而分析知识图谱中的孤立节点。

### 4.6 节点的增删改查

使用独立的临时电影节点展示 `CREATE`、`MATCH`、`SET` 和 `DELETE` 操作。操作完成后再以主键查询，检查节点是否已被删除。

```cypher
CREATE (m:Movie {id:-999999, title:'CRUD demo', tagline:'test', duration:0})
RETURN m.id, m.title;

MATCH (m:Movie {id:-999999})
SET m.title='CRUD updated'
RETURN m.id, m.title;

MATCH (m:Movie {id:-999999}) DELETE m;

MATCH (m:Movie {id:-999999})
RETURN count(m) AS remaining;
```

## 五、数据分析与讨论

根据原始 CSV 的实体 ID 和制作关系进行关联统计，可得到以下数据特征：

| 统计指标 | 数量 |
| --- | ---: |
| 电影实体 | 54 |
| 人物实体 | 665 |
| 制作关系 | 60 |
| 具有制作关系的人物 | 45 |
| 具有制作人员关联的电影 | 36 |
| 未关联制作关系的人物 | 620 |
| 未关联制作人员的电影 | 18 |

制作关系并未覆盖全部电影和人物节点，因此当前图中存在较多孤立节点。这体现了实体信息与关系信息在覆盖范围上的区别，也说明查询中需要区分“所有实体”和“具有某种关系的实体”。

在制作人员作品数量统计中，Bob Weinstein 和 Harvey Weinstein 均关联 **4 部电影**；Joel Silver、Christopher Nolan 和 Peter Jackson 各关联 **3 部电影**。例如，电影 *Cloud Atlas* 关联 Lily Wachowski、Lana Wachowski 和 Tom Tykwer 三位制作人员。上述统计以本次 CSV 记录为范围，并非人物完整职业生涯的作品统计。

相较于只查询单一数据表，图模式可以更直接地表示人物与电影之间的连接关系。特别是在共同制作人员、共享制作人员的电影组合等多跳问题中，`MATCH` 能够用路径结构表达关联条件。

## 六、实验总结

本实验基于电影及人物 CSV 数据，设计了 `Movie`、`Person` 与 `PRODUCED` 构成的属性图模型，形成了数据预处理、批量导入、关系查询、聚合统计与节点维护的完整流程。

图数据库将实体属性和实体之间的关联统一表示为节点与边，使电影制作关系的检索更加直观；通过多跳模式匹配，可以进一步研究制作人员之间的合作和电影之间的间接联系。实验也表明，在关系数据覆盖不完整时，需要结合孤立节点统计理解查询结果的范围。

## 附录：项目文件

| 文件 | 内容 |
| --- | --- |
| [data/source/](data/source/) | 三份原始电影 CSV |
| [data/movie_csv/import.json](data/movie_csv/import.json) | 属性图模型和导入映射 |
| [scripts/prepare_movie_csv.py](scripts/prepare_movie_csv.py) | 数据预处理 |
| [cypher/movie_csv.cypher](cypher/movie_csv.cypher) | 查询、聚合、多跳关系及 CRUD |
| [scripts/verify_movie_csv.py](scripts/verify_movie_csv.py) | 数据数量核对 |
| [setup.ps1](setup.ps1) | TuGraph 环境构建与导入 |
| [latex/main.tex](latex/main.tex) | 实验报告 LaTeX 源码 |

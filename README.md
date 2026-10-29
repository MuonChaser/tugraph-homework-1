# 作业1：TuGraph 电影知识图谱实验

使用 TuGraph 4.5.1 构建电影知识图谱，完成 CSV 导入、图模型设计、关系查询、CRUD 和聚合统计。

## 数据与图模型

数据包括 `movie.csv`（54 部电影）、`person.csv`（665 人）和 `produce.csv`（60 条制作关系），总计 719 个节点、60 条边。上述数量来自 CSV 数据记录。数据源中没有电影类型和演员关系，故本项目不假定存在相关事实。

| 节点 | 主键 | 属性 |
|---|---|---|
| Movie | id: INT32 | title、tagline、summary、poster_image、duration、rated |
| Person | id: INT32 | name、born、poster_image |
| PRODUCED（Person → Movie） | 人物/电影 ID | 无 |

## 安装与启动

在 Windows PowerShell、Docker Desktop (Linux x86_64) 环境执行：

```powershell
git clone https://github.com/MuonChaser/tugraph-homework-1.git
cd tugraph-homework-1
./setup.ps1
```

`setup.ps1` 自动构建 TuGraph 4.5.1 镜像、导入电影数据并启动本机服务。Browser: http://127.0.0.1:17070，Bolt: bolt://127.0.0.1:17687。数据库名称为 `movie_csv_demo`。默认管理密码仅用于本地初次测试，切勿暴露公网。

数据文件位于 `data/source/`。运行 `python scripts/prepare_movie_csv.py --input data/source --output data/movie_csv` 生成标准 CSV。导入映射见 [data/movie_csv/import.json](data/movie_csv/import.json)。

如需全新导入，先停止旧容器，另行备份或清空 `runtime/db` 后执行 setup.ps1；脚本不会覆盖已有数据库。

## Cypher 分析

在 TuGraph Browser 选中 `movie_csv_demo`，逐条执行 [cypher/movie_csv.cypher](cypher/movie_csv.cypher)。查询分为以下主题：

| 类别 | 内容 |
|---|---|
| 基础检索 | 电影、人物、制作关系数量；人物与电影关系表；标题和姓名关键词检索；时长筛选 |
| 聚合统计 | 制作人作品数量排名、每部电影制作人数、分级与时长分析、最长/最短/平均片长、出生年代分布 |
| 多跳查询 | 合作制作人组合、共同制作次数、同一制作人参与的电影组合 |
| 图完整性 | 没有关联制作人的电影、没有制作关系的人物、同名实体计数 |
| 图可视化 | 返回 Person–PRODUCED–Movie 子图 |
| 数据操作 | 临时电影节点的创建、读取、修改、删除及删除后复查 |

### 示例：制作人员参与影片数量

```cypher
MATCH (p:Person)-[:PRODUCED]->(m:Movie)
RETURN p.name AS producer, count(DISTINCT m) AS movie_count
ORDER BY movie_count DESC, producer LIMIT 20;
```

### 示例：共同制作电影的两个人

```cypher
MATCH (a:Person)-[:PRODUCED]->(m:Movie)<-[:PRODUCED]-(b:Person)
WHERE a.id < b.id
RETURN m.title AS movie, a.name AS producer_a, b.name AS producer_b
ORDER BY movie, producer_a, producer_b LIMIT 50;
```

### 示例：找出没有制作关系的电影

```cypher
MATCH (m:Movie)
WHERE NOT (m)<-[:PRODUCED]-(:Person)
RETURN m.id AS movie_id, m.title AS title ORDER BY title;
```

所有查询仅使用 CSV 中的电影、人物属性和 PRODUCED 关系，不引入未提供的演员、导演或类型边。

## 结果验证

```powershell
python -m pip install -r requirements.txt
$env:TUGRAPH_PASSWORD = '73@TuGraph'
python scripts/verify_movie_csv.py
```

验证脚本根据导入 CSV 自动计算期望记录数，读取运行数据库，并将结果写到 `evidence/movie-csv-results.json`。

## 实验报告

[LaTeX 报告源码](latex/main.tex) 用于编写实验过程与分析。报告与 Cypher 脚本使用一致的电影图模型和查询主题。

## 项目结构

```text
Dockerfile                 TuGraph 镜像
setup.ps1                  环境构建、CSV 预处理与导入启动
data/source/               原始电影、人物、制作关系 CSV
data/movie_csv/import.json TuGraph 图模型与导入配置
scripts/prepare_movie_csv.py  CSV 标准化
scripts/verify_movie_csv.py   导入验证
cypher/movie_csv.cypher    关系查询、聚合与 CRUD
latex/main.tex             实验报告源码
```

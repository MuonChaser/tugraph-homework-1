# 作业1：TuGraph 电影知识图谱实验

使用 TuGraph 4.5.1 构建电影知识图谱，完成 CSV 导入、图模型设计、关系查询、CRUD 和聚合统计。

## 数据与图模型

数据包括 `movie.csv`（54 部电影）、`person.csv`（665 人）和 `produce.csv`（60 条制作关系），总计 719 个节点、60 条边。以上是源文件的记录数，数据库实测结果需运行验证脚本获得。数据源中没有电影类型和演员关系，故本项目不假定存在相关事实。

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

在 TuGraph Browser 选中 `movie_csv_demo`，逐条执行 [cypher/movie_csv.cypher](cypher/movie_csv.cypher)。包含：
1. 电影、人物与制作关系数量统计；
2. 制作人及其电影的关系查询；
3. 制作人员作品数量排名；
4. 单部电影制作人员数量排名；
5. 不同分级影片的时长聚合；
6. 临时电影节点的新增、读取、修改、删除。

## 结果验证

```powershell
python -m pip install -r requirements.txt
$env:TUGRAPH_PASSWORD = '73@TuGraph'
python scripts/verify_movie_csv.py
```

验证脚本根据导入 CSV 自动计算期望记录数，读取运行数据库，并将结果写到 `evidence/movie-csv-results.json`。未执行该验证之前，README 中的数据量只是 CSV 统计值，不表示已验证的数据库状态。

## 实验报告

[LaTeX 报告源码](latex/main.tex) 用于编写实验过程与分析。报告中的实际运行截图、日志和结果需要在本地完成导入后补充，项目不会用示意图片代替运行证据。

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

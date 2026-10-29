# CSV 电影图谱分析（使用上传的数据）

这条路径直接使用用户提供的 `movie.csv`、`person.csv`、`produce.csv`，**不需要 RDF 或 YAGO 转换**。目前无法确认这些 CSV 的 YAGO 来源，因此不能将其声称为 YAGO 官方数据。

已检查原始 CSV：54 部电影、665 名人物、60 条制作关系。两个节点文件使用首行 `LABEL=movie/person` 加第二行带类型的字段名；`produce.csv` 无表头，列顺序为人物 ID、电影 ID。所有 60 条边均有对应人物和电影。

## 1. 准备 CSV

将三个上传的原始文件原样放入仓库的 `data/source/` 下：

    data/source/movie.csv
    data/source/person.csv
    data/source/produce.csv

运行：

    python scripts/prepare_movie_csv.py --input data/source --output data/movie_csv

输出为三个带普通字段表头的 `data/movie_csv/movies.csv`、`people.csv` 和 `produced.csv`，直接配合 `data/movie_csv/import.json` 导入。人物属性包括 name、born、poster_image；电影属性包括 title、tagline、summary、poster_image、duration、rated。两个实体均以整型 id 作主键。

## 2. TuGraph 导入

运行仓库原来的 Docker 镜像构建（`setup.ps1` 仍然是医疗实验环境），使用**新的、空的**数据库目录，避免覆盖原实验：

```powershell
New-Item -ItemType Directory -Force runtime/movie-db | Out-Null
docker run --rm --mount "type=bind,source=$PWD,target=/workspace" `
  --entrypoint /usr/local/bin/lgraph_import tugraph-assignment-clean:4.5.1 `
  --config_file /workspace/data/movie_csv/import.json `
  --dir /workspace/runtime/movie-db --graph movie_csv_demo
```

原服务仍指向 `runtime/db`，因此导入后需要另行配置服务以使用 `runtime/movie-db` 才能在 Browser 查询。不要同时让两个 TuGraph 进程操作同一目录。

## 3. 查询与核对

`cypher/movie_csv.cypher` 提供人物制作影片映射、制作人员参与电影数排行、每部电影制作人数、时长按电影分级聚合，以及在独立临时电影节点上的增删改查。CRUD 执行完毕后，确认临时节点已经删除。

数据库成功运行后，设置 `TUGRAPH_PASSWORD`（以及必要时的 `TUGRAPH_URI` 与 `TUGRAPH_GRAPH`），执行：

    python scripts/verify_movie_csv.py

脚本根据 CSV 文件计算预期数量，并与数据库数量比较，实际结果写入 `evidence/movie-csv-results.json`。

**状态：** CSV 结构及关联经过本地静态检查，但 GitHub 仓库目前只提交了处理脚本、导入配置和分析脚本；原始 CSV 尚未提交到仓库。TuGraph 运行、截图、LaTeX 报告和 PDF 尚未替换或验证，旧医疗实验材料仍然存在。

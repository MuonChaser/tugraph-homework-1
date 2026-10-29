# YAGO 电影图谱实验（迁移分支）

本分支新增基于真实 YAGO RDF 数据的电影分析，不把旧医疗样例数据、截图、日志或报告冒充为 YAGO 实验结果。原 README 和报告仍属于医疗实验，需要实测后重新完成。

## 数据准备

从 [YAGO 官方网站](https://yago-knowledge.org/) 下载课程要求版本的 RDF 数据。准备一个包含 schema:Movie 类型声明、schema:actor、schema:director、schema:genre 和可选 rdfs:label/schema:name 的 Turtle 或 N-Triples 子集。源数据可能分散在多个文件，应先合并相关三元组（相同 RDF 格式）或提取子集。当前 rdflib 解析器会把输入载入内存，适用于电影子集，不适用于直接读取超大 dump。

    python -m pip install -r requirements.txt
    python scripts/prepare_yago_movies.py path/to/yago-movie-subset.ttl --output data/yago

生成 movies.csv、people.csv、genres.csv、acted_in.csv、directed.csv、has_genre.csv，主键是源数据 URI，避免同名冲突；导入 schema 在 data/yago/import.json。

## 导入

保留原始 Dockerfile 构建 TuGraph 4.5.1 的方式，先构建 tugraph-assignment-clean:4.5.1。使用空目录 runtime/yago-db，不要覆盖医疗实验数据库 runtime/db：

    docker run --rm --mount "type=bind,source=${PWD},target=/workspace" --entrypoint /usr/local/bin/lgraph_import tugraph-assignment-clean:4.5.1 --config_file /workspace/data/yago/import.json --dir /workspace/runtime/yago-db --graph yago_movies

上述命令假定在 PowerShell 的仓库根目录执行。原 setup.ps1 启动的服务仍指向 runtime/db；若要查询 yago_movies，必须另外启动一个服务指向 runtime/yago-db，且不得同时写入相同数据库目录。

## 分析

在 Browser 选择 yago_movies，逐条运行 cypher/yago_movies.cypher。包含节点数量核对、类型热度、导演作品数量、演员数量排行、演员合作网络及独立临时节点 CRUD。

运行验证：设置 TUGRAPH_PASSWORD 环境变量、TUGRAPH_GRAPH=yago_movies，并运行 python scripts/verify_yago.py。实测结果才会保存在 evidence/yago-results.json。

**尚未进行实际 YAGO 导入、数据库运行验证、截图、LaTeX 报告替换或 PDF 重新编译。** 当前 main README、latex/main.tex、report/作业1.pdf、screenshots/ 和旧 evidence 依旧是医疗实验材料，不属于 YAGO 实验结果。

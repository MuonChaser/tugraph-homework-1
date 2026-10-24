# CSV 字段说明

使用 UTF-8 CSV。先导入节点，再导入关系；唯一键使用 `name`。

- `diseases.csv`: Disease(name, category)
- `symptoms.csv`: Symptom(name, severity)
- `departments.csv`: Department(name)
- `drugs.csv`: Drug(name, kind)
- `disease_symptom.csv`: Disease -> HAS_SYMPTOM -> Symptom，首列为疾病名，次列为症状名
- `disease_department.csv`: Disease -> BELONGS_TO -> Department
- `disease_drug.csv`: Disease -> TREATS -> Drug

此为教学用模拟数据，不构成医疗建议。

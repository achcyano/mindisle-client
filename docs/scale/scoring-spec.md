# 量表计分规则说明

本文档描述当前服务端实现的计分逻辑，与 `ScaleScoringMethod` 对应。

## 1. PHQ-9

- 计分题：`q1 ~ q9`，每题 `0~3`
- 总分：`q1..q9` 求和，范围 `0~27`
- 分级：
  - `0~4`：`minimal`（无抑郁）
  - `5~9`：`mild`（轻度抑郁）
  - `10~14`：`moderate`（中度抑郁）
  - `15~19`：`moderately_severe`（中重度抑郁）
  - `>=20`：`severe`（重度抑郁）
- 风险标记：
  - `q9 >= 1` -> `SUICIDE_RISK`
- 功能损害题：
  - `q10` 不纳入总分，仅作为 `overallMetrics.functionImpact`（若可解析）。

## 2. GAD-7

- 计分题：`q1 ~ q7`，每题 `0~3`
- 总分：`0~21`
- 分级：
  - `0~4`：`minimal`（无焦虑）
  - `5~9`：`mild`（轻度焦虑）
  - `10~14`：`moderate`（中度焦虑）
  - `>=15`：`severe`（重度焦虑）

## 3. PSQI

组件分（`C1~C7`）每项 `0~3`，总分 `0~21`。

- `C1`：`q9`
- `C2`：`q2 + q5a` 后映射
  - `0 -> 0`
  - `1~2 -> 1`
  - `3~4 -> 2`
  - `5~6 -> 3`
- `C3`：由 `q4`（实际睡眠时长）映射
  - `>7h -> 0`
  - `6~7h -> 1`
  - `5~6h -> 2`
  - `<5h -> 3`
- `C4`：睡眠效率 `q4 / (q3-q1在床时长) * 100%`
  - `>=85 -> 0`
  - `75~84 -> 1`
  - `65~74 -> 2`
  - `<65 -> 3`
- `C5`：`q5b..q5j` 求和后映射
  - `0 -> 0`
  - `1~9 -> 1`
  - `10~18 -> 2`
  - `19~27 -> 3`
- `C6`：`q6`
- `C7`：`q7 + q8` 后映射（同 `C2`）

结论：

- `<=7`：`good`（睡眠质量良好）
- `>7`：`sleep_issue`（存在睡眠问题）

输出：

- `overallMetrics.sleepEfficiency`
- `dimensionScores` 与 `dimensionResults` 包含 `C1..C7`

## 4. SCL-90

题目采用 `1~5` 评分，按以下维度分组：

- `somatization`：1-12（12题）
- `obsessive_compulsive`：13-22（10题）
- `interpersonal_sensitivity`：23-31（9题）
- `depression`：32-44（13题）
- `anxiety`：45-54（10题）
- `hostility`：55-60（6题）
- `phobic_anxiety`：61-67（7题）
- `paranoid_ideation`：68-73（6题）
- `psychoticism`：74-83（10题）
- `additional`：84-90（7题）

计算：

- `totalScore`：90题总和
- `totalAverage`：`totalScore / 题目数`
- `positiveItemCount`：评分 `>=2` 的题目数
- `positiveMean`：阳性题均分
- 维度分：各维度均分

筛查阳性判定（满足任一）：

- `totalScore >= 160`
- `positiveItemCount >= 43`
- 任一维度均分 `>= 3`

输出：

- 阳性时 `bandLevelCode=positive`，并添加 `resultFlags: ["SCL90_POSITIVE"]`

## 5. EPQ（EPQ-88）

维度与题号：

- `E`：1-21（其中 15-21 为反向计分）
- `N`：22-45
- `P`：46-65
- `L`：66-88

题型：`YES_NO`，默认 `是=1, 否=0`；反向题按 `reverseScored` 反转。

输出：

- `rawScore`：维度原始分
- `standardScore`：T分（性别常模可用时）

T分公式：

`T = 50 + 10 * (X - mean) / sd`

常模来自 `rule_json.norms`（男女分开配置）。

当用户性别未知：

- 不计算 T 分
- 返回标记：`EPQ_NORM_PENDING_GENDER`

## 6. 结果兼容策略

- 旧字段 `dimensionScores` 继续返回
- 新字段：
  - `overallMetrics`
  - `dimensionResults`
  - `resultFlags`
- 数据库存储：
  - `dimension_scores_json`（兼容）
  - `result_detail_json`（新增，结构化明细）

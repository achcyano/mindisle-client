# MindIsle 量表系统接口文档

本文档说明 `/api/v1/scales/**` 的接口、SSE 事件和计分结果结构。  
所有接口默认 UTF-8。

## 1. 通用约定

- Base URL: `/api/v1`
- 鉴权：均需 `Authorization: Bearer <accessToken>`
- 通用响应：

```json
{
  "code": 0,
  "message": "OK",
  "data": {}
}
```

## 2. 会话状态

- `IN_PROGRESS`：进行中，可保存、可提交、可删除
- `SUBMITTED`：已提交，不可修改、不可删除
- `ABANDONED`：预留状态

服务端按 `user_id + scale_id` 复用最新 `IN_PROGRESS` 会话，实现断点续填。

## 3. 量表接口

### 3.1 获取量表列表

- `GET /api/v1/scales?limit=20&cursor=<optional>&status=<optional>`
- `limit`: `1~50`，默认 `20`
- `cursor`: 分页游标
- `status`: `DRAFT | PUBLISHED | ARCHIVED`
- `status` 传非法值会返回 `40020`

说明：

- 当前列表仅返回“存在已发布版本（`ScaleVersion.status=PUBLISHED`）”的量表
- 列表项新增 `lastCompletedAt`：当前用户最近一次完成（`SUBMITTED`）该量表的时间
- `lastCompletedAt` 使用固定时区 `UTC+8`，格式 `ISO8601 +08:00`（示例：`2026-02-24T21:30:00+08:00`）
- 若该用户从未完成该量表，`lastCompletedAt` 为 `null`

### 3.2 获取量表详情（题目+选项+维度）

- `GET /api/v1/scales/{scaleRef}`
- `scaleRef` 支持量表 `id` 或 `code`

返回重点字段：

- `config`: 版本配置 JSON
- `dimensions`: 维度定义数组（新增）
  - `key`
  - `name`
  - `description`
  - `scoreRange`
  - `interpretationHint`
- `questions`: 题目数组（含 `type/dimension/scorable/reverseScored/options`）

### 3.3 创建或恢复会话

- `POST /api/v1/scales/{scaleId}/sessions`
- 已存在 `IN_PROGRESS` 时返回旧会话，否则创建新会话。

### 3.4 获取会话详情

- `GET /api/v1/scales/sessions/{sessionId}`
- 返回：
  - `session`
  - `answers`
  - `unansweredRequiredQuestionIds`

### 3.5 保存单题答案（自动保存）

- `PUT /api/v1/scales/sessions/{sessionId}/answers/{questionId}`

请求体：

```json
{
  "answer": {
    "optionId": 123
  }
}
```

建议格式：

- 单选/是非：`{"optionId":123}` 或 `{"optionKey":"opt_1"}`
- 多选：`{"optionIds":[1,2]}` 或 `{"optionKeys":["a","b"]}`
- 文本：`"文本"` 或 `{"text":"文本"}`
- 时间：`{"value":"23:30"}`（规范化后存 `HH:mm`）
- 时长：`{"value":"6h"}`（规范化后存 `minutes/hours`）

开放题（`TEXT`）长度限制：

- 使用全局 `.env` 固定值，不按题目单独配置
- `SCALE_OPEN_TEXT_ANSWER_MIN_CHARS`
- `SCALE_OPEN_TEXT_ANSWER_MAX_CHARS`
- 超出范围返回 `40021`

### 3.6 提交量表并计分

- `POST /api/v1/scales/sessions/{sessionId}/submit`
- 行为：
  - 校验必答题
  - 执行量表方法计分
  - 写入结果
  - 会话置为 `SUBMITTED`

### 3.7 获取结果

- `GET /api/v1/scales/sessions/{sessionId}/result`

返回字段：

- `totalScore`
- `dimensionScores`（兼容字段，`Map<String, Double>`）
- `overallMetrics`（新增，总体指标）
- `dimensionResults`（新增，维度详细结果）
- `resultFlags`（新增，风险/状态标记）
- `bandLevelCode/bandLevelName`
- `resultText`

注意：

- 若会话尚未产出结果（例如还未提交），当前实现返回 HTTP `409` + 业务码 `40020`（`Result not ready`）

`dimensionResults` 结构：

```json
{
  "dimensionKey": "C1",
  "dimensionName": "主观睡眠质量",
  "rawScore": 2.0,
  "averageScore": null,
  "standardScore": null,
  "levelCode": null,
  "levelName": null,
  "interpretation": null,
  "extraMetrics": {}
}
```

### 3.8 历史记录

- `GET /api/v1/scales/history?limit=20&cursor=<optional>`
- 仅返回当前用户 `SUBMITTED` 会话。

### 3.9 删除草稿会话

- `DELETE /api/v1/scales/sessions/{sessionId}`
- 仅允许删除非 `SUBMITTED` 会话。

## 4. 题目问 AI（SSE，带5轮上下文）

### 4.1 接口

- `POST /api/v1/scales/assist/stream`
- Headers:
  - `Authorization`
  - `Content-Type: application/json`
  - `Accept: text/event-stream`

请求体（已变更）：

```json
{
  "sessionId": 101,
  "questionId": 2001,
  "userDraftAnswer": "我最近总是半夜醒"
}
```

说明：

- 服务端会基于 `sessionId + questionId` 自动加载题目、选项、提示、注意事项，再调用模型。
- 不信任客户端传题干和选项，避免版本不一致和篡改。
- 服务端会在内存中按 `userId + sessionId + questionId` 维护最近 5 轮问答上下文，并自动带入下一次提问。
- 该上下文不落库；服务重启后会丢失。
- `userDraftAnswer` 可为空；若传入，最大 4000 字符，且不能包含控制字符。

### 4.2 SSE 事件

```text
id: <generationId>:<seq>
event: <eventName>
data: <json>

```

事件类型：

- `meta`
- `delta`
- `done`
- `error`

说明：

- `error` 为业务错误事件，不代表 HTTP 层断开
- 上游限流时，`error.data.code` 会映射为 `42920`

## 5. 当前支持量表与计分方法

- `PHQ9`
- `GAD7`
- `PSQI`
- `SCL90`
- `EPQ`（EPQ-88）

详见：`docs/scale/scoring-spec.md`

## 6. 错误码（量表相关）

| code | HTTP | 含义 |
|---|---|---|
| 40020 | 400 | 量表参数非法 |
| 40021 | 400 | 答案格式不合法/题型不匹配 |
| 40320 | 403 | 会话不属于当前用户 |
| 40420 | 404 | 量表不存在 |
| 40421 | 404 | 量表版本不存在 |
| 40422 | 404 | 量表会话不存在 |
| 40920 | 409 | 会话已提交，不能修改 |
| 40921 | 409 | 版本不一致（预留，当前未启用） |
| 42220 | 422 | 必答题未完成，无法提交 |
| 42920 | 429 | 量表问 AI 触发限流 |
| 50030 | 500 | 计分内部异常 |

补充：

- `GET /scales/sessions/{sessionId}/result` 在“结果未生成”场景下会返回 HTTP `409` + `40020`

## 7. 服务端机制摘要

1. 启动时自动建表，并按版本写入量表种子（PHQ9/GAD7/PSQI/SCL90/EPQ）。  
2. 客户端按量表详情渲染题目，逐题保存。  
3. 服务端保存题目时更新进度，支持断点续填。  
4. 提交后执行对应计分方法，写入总分、维度分、维度详情和风险标记。  
5. 题目问 AI 使用独立 SSE 通道，并按同用户同会话同题目维护最近 5 轮内存上下文（不落库，重启丢失）。  

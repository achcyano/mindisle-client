# MindIsle AI SSE 接口说明（DeepSeek v3.2 / 阿里云）

本文档说明 AI 对话接口（`/api/v1/ai/**`）的请求方式、SSE 事件、断线重连，以及“可点击选项（options）”机制。

## 1. 总览

- 鉴权：所有接口都需要 `Authorization: Bearer <accessToken>`
- 协议：普通接口返回 `ApiResponse`，流式接口返回 `text/event-stream`
- 历史：按用户保存全部会话和消息
- 选项：每次助手回复都会返回 3 个可点击选项
- 点击语义：客户端点击后，将 `option.payload` 直接作为下一轮 `userMessage` 发给服务端

## 2. 主要接口

### 2.1 创建会话
- `POST /api/v1/ai/conversations`
- body:
```json
{ "title": "可选标题" }
```

### 2.2 会话列表
- `GET /api/v1/ai/conversations?limit=20&cursor=<optional>`

### 2.3 历史消息
- `GET /api/v1/ai/conversations/{conversationId}/messages?limit=50&before=<optional>`
- assistant 消息会带 `options` 字段（见第 4 节）

### 2.4 发起流式对话
- `POST /api/v1/ai/conversations/{conversationId}/stream`
- headers:
  - `Authorization`
  - `Content-Type: application/json`
  - `Accept: text/event-stream`
  - `Last-Event-ID`（可选）
- body:
```json
{
  "userMessage": "最近睡眠不好怎么办？",
  "clientMessageId": "uuid",
  "temperature": 0.7,
  "maxTokens": 2048
}
```

### 2.5 按 generation 重连
- `GET /api/v1/ai/generations/{generationId}/stream`
- headers:
  - `Authorization`
  - `Accept: text/event-stream`
  - `Last-Event-ID`（可选，格式 `<generationId>:<seq>`）

## 3. SSE 事件

服务端统一输出：

```text
id: <generationId>:<seq>
event: <eventName>
data: <json>

```

### 3.1 事件类型与顺序

标准顺序：
1. `meta`
2. `delta`（流式增量，按上游 chunk 实时下发，可能是词片段）
3. `usage`（可选）
4. `options`（必有）
5. `done`

异常时会发送：
- `error`

### 3.2 `options` 事件

```json
{
  "items": [
    { "id": "opt_1", "label": "请继续解释", "payload": "请继续解释，并给我更具体一点的建议。" },
    { "id": "opt_2", "label": "帮我做总结", "payload": "请把刚才的回答总结成三点重点。" },
    { "id": "opt_3", "label": "下一步怎么做", "payload": "结合我现在的情况，我下一步具体该怎么做？" }
  ],
  "source": "primary"
}
```

`source` 取值：
- `primary`：主模型回复中成功解析出选项
- `fallback`：主解析失败，单独调用一次 LLM 生成选项
- `default`：主解析 + fallback 都失败，服务端固定兜底选项

## 4. 历史消息结构

`GET /messages` 返回的 assistant 消息示例：

```json
{
  "messageId": 1001,
  "role": "ASSISTANT",
  "content": "这是助手回答正文",
  "options": [
    { "id": "opt_1", "label": "请继续解释", "payload": "请继续解释，并给我更具体一点的建议。" },
    { "id": "opt_2", "label": "帮我做总结", "payload": "请把刚才的回答总结成三点重点。" },
    { "id": "opt_3", "label": "下一步怎么做", "payload": "结合我现在的情况，我下一步具体该怎么做？" }
  ],
  "generationId": "xxx",
  "createdAt": "2026-02-21T12:00:00Z"
}
```

## 5. 断线重连

1. 客户端记录最近一个 SSE `id`
2. 断线后调用重连接口并携带 `Last-Event-ID`
3. 服务端会回放缺失事件（包括 `options`）
4. 如果超出回放窗口，返回 `40911 AI_REPLAY_WINDOW_EXPIRED`

## 6. options 约束

- 固定 3 个
- `label` 最长 24 字符
- `payload` 最长 80 字符
- 不能包含控制字符
- 同一批 options 内 `payload` 不能重复

## 7. 错误码（新增/相关）

| code | HTTP | 含义 |
|---|---|---|
| 40010 | 400 | AI 请求参数非法 |
| 40011 | 400 | 选项结构非法 |
| 40310 | 403 | 会话/生成任务不属于当前用户 |
| 40410 | 404 | 会话不存在 |
| 40411 | 404 | generation 不存在 |
| 40910 | 409 | 幂等冲突（同 clientMessageId 不同内容） |
| 40911 | 409 | 重连回放窗口过期/缺口 |
| 42910 | 429 | 上游限流 |
| 50020 | 500 | 服务端流处理异常 |
| 50021 | 500 | 主回复选项解析失败（内部兜底流程会继续） |
| 50201 | 502 | 上游调用失败 |
| 50202 | 502 | fallback 选项生成失败（内部会再用默认选项） |

## 8. 客户端接入建议

1. 每次发消息都生成唯一 `clientMessageId`
2. 始终监听 `options` 事件并渲染按钮
3. 点击按钮时直接发送 `payload` 作为下一轮 `userMessage`
4. 会话重进时从历史消息 `options` 字段恢复按钮

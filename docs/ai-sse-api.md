# MindIsle AI SSE 接口说明（DeepSeek v3.2 / 阿里云）

本文档说明 AI 对话接口（`/api/v1/ai/**`）的请求方式、SSE 事件、断线重连，以及可点击选项（`options`）机制。

## 1. 总览

- 鉴权：所有接口都需要 `Authorization: Bearer <accessToken>`
- 普通接口返回 `ApiResponse`，流式接口返回 `text/event-stream`
- 历史会话与消息按用户持久化保存
- 每轮助手回复会返回 3 个可点击选项
- 选项结构已调整：`option` 仅返回 `id`、`label`，不再返回 `payload`
- 同一会话中仅保留“最新一条助手消息”的 options；更早消息的 options 会被清空
- 对话标题默认策略：若创建会话时未传 `title`，在首条用户消息发送时自动用“第一句话前部分文字”生成标题（最多 20 字）
- 点击语义：客户端点击后，将 `option.label` 作为下一轮 `userMessage` 发给服务端

## 2. 主要接口

### 2.1 创建会话

- `POST /api/v1/ai/conversations`
- body:

```json
{ "title": "可选标题" }
```

约束：

- `title` 可为空；若传入则最长 100 字符，且不能包含控制字符

### 2.2 会话列表

- `GET /api/v1/ai/conversations?limit=20&cursor=<optional>`

约束：

- `limit` 建议 `1~50`（服务端会裁剪到该范围）
- `cursor` 为会话 ID（Long）

### 2.3 修改会话标题

- `PUT /api/v1/ai/conversations/{conversationId}/title`
- body:

```json
{ "title": "新的标题" }
```
- response `data`:

```json
{
  "conversationId": 123,
  "title": "新的标题",
  "updatedAt": "2026-02-22T08:00:00Z"
}
```

约束：

- `title` 必填，去空格后不能为空
- `title` 最长 100 字符，且不能包含控制字符

### 2.4 删除会话

- `DELETE /api/v1/ai/conversations/{conversationId}`
- 说明：删除后会级联删除该会话的消息、生成任务及流事件历史
- response：`ApiResponse<Unit>`（`data` 为 `null`）
### 2.5 历史消息

- `GET /api/v1/ai/conversations/{conversationId}/messages?limit=50&before=<optional>`
- assistant 消息会带 `options` 字段（见第 4 节）

约束：

- `limit` 建议 `1~100`（服务端会裁剪到该范围）
- `before` 为消息 ID（Long）
### 2.6 发起流式对话

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

请求体约束：

- `userMessage` 必填，非空白，且不能包含控制字符
- `clientMessageId` 必填，非空白，且不能包含控制字符
- `temperature` 可选，范围 `0.0~2.0`
- `maxTokens` 可选，范围 `1~8192`

### 2.7 按 generation 重连

- `GET /api/v1/ai/generations/{generationId}/stream`
- headers:
  - `Authorization`
  - `Accept: text/event-stream`
  - `Last-Event-ID`（可选，支持 `<generationId>:<seq>` 或仅 `<seq>`）

## 3. SSE 事件

统一输出格式：

```text
id: <generationId>:<seq>
event: <eventName>
data: <json>

```

### 3.1 事件类型与顺序

标准顺序：

1. `meta`
2. `delta`（流式增量文本；服务端会过滤 `<OPTIONS_JSON>...</OPTIONS_JSON>` 块）
3. `usage`（可选）
4. `options`（必有）
5. `done`

异常时会发送：

- `error`

连接保活：

- 服务端会发送 SSE 注释行 `: ping` 作为心跳，客户端应忽略该行

### 3.2 `options` 事件

```json
{
  "items": [
    { "id": "opt_1", "label": "💡 请继续解释" },
    { "id": "opt_2", "label": "🧭 帮我做总结" },
    { "id": "opt_3", "label": "✅ 下一步怎么做" }
  ],
  "source": "primary"
}
```

`source` 取值：

- `primary`：主模型回复中成功解析出选项
- `fallback`：主解析失败，单独调用一次 LLM 生成选项
- `default`：主解析与 fallback 都失败，服务端使用固定兜底选项

## 4. 历史消息结构

`GET /messages` 返回的 assistant 消息示例：

```json
{
  "messageId": 1001,
  "role": "ASSISTANT",
  "content": "这是助手回答正文",
  "options": [
    { "id": "opt_1", "label": "💡 请继续解释" },
    { "id": "opt_2", "label": "🧭 帮我做总结" },
    { "id": "opt_3", "label": "✅ 下一步怎么做" }
  ],
  "generationId": "xxx",
  "createdAt": "2026-02-21T12:00:00Z"
}
```

说明：历史列表里只有会话最新一条助手消息会带 `options`，其他消息的 `options` 为 `null`。

## 5. 断线重连

1. 客户端记录最近一个 SSE `id`
2. 断线后调用重连接口并携带 `Last-Event-ID`
3. 服务端回放缺失事件（包括 `options`）
4. 超出回放窗口时返回 `40911 AI_REPLAY_WINDOW_EXPIRED`

## 6. options 约束

- 固定 3 项
- 每项仅包含 `id`、`label`
- `label` 最长 24 字符
- 服务端通过系统提示词强引导 `label` 以 emoji 开头，但当前不做硬性校验；客户端应按普通文本容错处理
- 不允许控制字符
- 同一批 options 内 `label` 不能重复

## 7. 错误码（AI 相关）

客户端可稳定依赖的错误码：

| code | HTTP | 含义 |
|---|---|---|
| 40010 | 400 | AI 请求参数非法 |
| 40310 | 403 | 会话/任务不属于当前用户 |
| 40410 | 404 | 会话不存在 |
| 40411 | 404 | generation 不存在 |
| 40910 | 409 | 幂等冲突（同 clientMessageId 不同内容） |
| 40911 | 409 | 重连回放窗口过期/缺口 |
| 42910 | 429 | 上游限流 |
| 50020 | 500 | 服务端流处理异常 |
| 50201 | 502 | 上游调用失败 |

内部保留码（当前通常不会直接下发给客户端）：

| code | 含义 |
|---|---|
| 40011 | 选项结构非法（保留） |
| 50021 | 主回复选项解析失败（内部兜底流程会继续） |
| 50202 | fallback 选项生成失败（内部会再用默认选项） |

## 8. 客户端接入建议

1. 每次发送消息都生成唯一 `clientMessageId`
2. 始终监听 `options` 事件并渲染按钮
3. 点击按钮时直接发送 `label` 作为下一轮 `userMessage`
4. 会话重进时从历史消息 `options` 字段恢复按钮

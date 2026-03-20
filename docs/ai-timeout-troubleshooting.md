# AI 流式超时排查（50201）

## 现象

客户端 SSE 收到：

- `event: error`
- `data.code = 50201`
- `data.message` 包含 `Request timeout has expired`

这表示服务端访问阿里云 DeepSeek 上游流式接口超时，不是客户端 SSE 解析错误。

## 当前超时策略

服务端 `DeepSeekAliyunClient` 已调整为：

- 关闭“整请求总时长超时”（避免长回复被总时长截断）
- 使用“流式空闲超时（socket timeout）”
- 空闲超时由环境变量 `LLM_REQUEST_TIMEOUT_SECONDS` 控制
  - `> 0`：启用空闲超时（秒）
  - `<= 0`：关闭空闲超时

## 建议配置

本地联调建议先用：

```env
LLM_REQUEST_TIMEOUT_SECONDS=300
```

如果仍然偶发超时，可进一步增大，或临时设为 `0` 排查网络/上游抖动。

## 客户端建议

- 遇到 `50201` 时保留已收到的 `delta` 文本
- 提供“继续生成”按钮，使用新一轮请求续写
- 如需要自动重试，建议只重试一次，避免重复扣费或重复内容

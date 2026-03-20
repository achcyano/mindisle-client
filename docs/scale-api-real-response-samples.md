# Scale API 真实返回样例（本地运行抓取）

抓取时间：`2026-02-23 22:08:39 +08:00`  
服务地址：`http://127.0.0.1:9999`  
说明：以下样例均来自正在运行的本地服务真实请求，不是手写构造。

## 1. `GET /api/v1/scales/{scaleRef}` 真实样例

请求：

```bash
curl --request GET \
  --url "http://127.0.0.1:9999/api/v1/scales/PHQ9" \
  --header "Authorization: Bearer <ACCESS_TOKEN>" \
  --header "Accept: application/json"
```

HTTP 状态：`200`

完整响应已保存到：

- `docs/real-sample-scale-detail.json`

## 2. `GET /api/v1/scales/sessions/{sessionId}` 真实样例

说明：该接口需要真实会话 ID。抓样例时先调用了创建会话接口，得到 `sessionId=1`：

```bash
curl --request POST \
  --url "http://127.0.0.1:9999/api/v1/scales/1/sessions" \
  --header "Authorization: Bearer <ACCESS_TOKEN>" \
  --header "Accept: application/json"
```

该创建接口响应也已保存（便于你核对 `sessionId` 来源）：

- `docs/real-sample-create-session.json`

目标接口请求：

```bash
curl --request GET \
  --url "http://127.0.0.1:9999/api/v1/scales/sessions/1" \
  --header "Authorization: Bearer <ACCESS_TOKEN>" \
  --header "Accept: application/json"
```

HTTP 状态：`200`

完整响应已保存到：

- `docs/real-sample-session-detail.json`

## 3. `GET /api/v1/scales/sessions/{sessionId}/result` 真实样例

说明：该接口只有在会话已提交且完成计分后才能拿到结果。  
本次样例使用会话 `sessionId=1`，先保存必答题后执行了提交。

请求：

```bash
curl --request GET \
  --url "http://127.0.0.1:9999/api/v1/scales/sessions/1/result" \
  --header "Authorization: Bearer <ACCESS_TOKEN>" \
  --header "Accept: application/json"
```

HTTP 状态：`200`

完整响应已保存到：

- `docs/real-sample-session-result.json`

## 4. `GET /api/v1/scales/history` 真实样例

请求：

```bash
curl --request GET \
  --url "http://127.0.0.1:9999/api/v1/scales/history?limit=20" \
  --header "Authorization: Bearer <ACCESS_TOKEN>" \
  --header "Accept: application/json"
```

HTTP 状态：`200`

完整响应已保存到：

- `docs/real-sample-scale-history.json`

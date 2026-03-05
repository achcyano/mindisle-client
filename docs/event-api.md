# MindIsle 事件系统接口文档

本文档说明用户事件聚合接口与医生绑定状态接口，供客户端做提醒与跳转。

## 1. 通用约定

- Base URL: `/api/v1`
- 鉴权：`Authorization: Bearer <accessToken>`
- 通用响应：

```json
{
  "code": 0,
  "message": "OK",
  "data": {}
}
```

- 事件时间字段 `dueAt` 使用固定时区 `UTC+8`，格式 `ISO8601 +08:00`。

## 2. 事件接口

### `GET /api/v1/users/me/events`

- 鉴权：需要 JWT
- 请求头：
  - `Authorization` 必填
- 请求体：无
- 成功：`200 OK`

成功响应：`ApiResponse<UserEventListResponse>`

`UserEventListResponse`

- `generatedAt: String`（+08:00）
- `items: List<UserEventItem>`

`UserEventItem`

- `eventName: String`（稳定事件名）
- `eventType: String`（客户端跳转类型）
- `dueAt: String`（+08:00）
- `persistent: Boolean`（当前固定 `true`）
- `payload: Object`（按事件类型不同）

### 2.1 事件类型定义

1. `eventName = SCALE_REDO_DUE`
   - `eventType = OPEN_SCALE`
   - `payload`：
     - `scaleId: Long`
     - `scaleCode: String`
     - `scaleName: String`
     - `intervalDays: Int`
   - 含义：量表到达重做周期。

2. `eventName = SCALE_SESSION_IN_PROGRESS`
   - `eventType = CONTINUE_SCALE_SESSION`
   - `payload`：
     - `sessionId: Long`
     - `scaleId: Long`
     - `scaleCode: String`
     - `scaleName: String`
     - `progress: Int`
   - 含义：存在未提交量表会话，需继续填写。

3. `eventName = DOCTOR_BIND_REQUIRED`
   - `eventType = BIND_DOCTOR`
   - `payload = {}`
   - 含义：当前未绑定医生。

4. `eventName = MEDICATION_PLAN_EMPTY`
   - `eventType = IMPORT_MEDICATION_PLAN`
   - `payload`：
     - `activeMedicationCount: Int`（当前为 `0`）
   - 含义：当前无用药计划。

5. `eventName = PROFILE_UPDATE_MONTHLY`
   - `eventType = UPDATE_BASIC_PROFILE`
   - `payload`：
     - `anchor: String`（当前固定 `REGISTERED_AT`）
   - 含义：基于注册时间锚点的月度资料更新提醒。

### 2.2 到期时间规则

- 量表重做：
  - 从该量表最新发布版本的 `config.redoIntervalDays` 读取周期（天）。
  - 未配置或非法时默认 `30` 天。
  - 锚点：该量表最近一次 `SUBMITTED` 的时间；若从未提交，使用用户注册时间。
  - `dueAt` 为下一次周期到期点。

- 继续填写：
  - 每个量表只返回一条最新 `IN_PROGRESS` 会话事件。
  - `dueAt = 会话 updatedAt`。

- 未绑定医生：
  - 医生绑定状态为 `false` 时返回。
  - `dueAt = 用户注册时间`。

- 用药计划为空：
  - 当前有效用药计划条数为 `0` 时返回。
  - `dueAt = 用户注册时间`。

- 月度资料更新：
  - 按用户注册时间锚点，每 1 个月计算下一次到期时间。

### 2.3 示例

```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "generatedAt": "2026-03-05T16:30:00+08:00",
    "items": [
      {
        "eventName": "DOCTOR_BIND_REQUIRED",
        "eventType": "BIND_DOCTOR",
        "dueAt": "2026-02-01T10:00:00+08:00",
        "persistent": true,
        "payload": {}
      },
      {
        "eventName": "SCALE_SESSION_IN_PROGRESS",
        "eventType": "CONTINUE_SCALE_SESSION",
        "dueAt": "2026-03-05T15:40:00+08:00",
        "persistent": true,
        "payload": {
          "sessionId": 101,
          "scaleId": 2,
          "scaleCode": "GAD7",
          "scaleName": "广泛性焦虑障碍量表（GAD-7）",
          "progress": 57
        }
      }
    ]
  }
}
```

接口级可能错误码：

- `40100` access token 无效/缺失，或用户不存在

## 3. 医生绑定状态接口

### `GET /api/v1/users/me/doctor-binding`

- 鉴权：需要 JWT
- 请求头：
  - `Authorization` 必填
- 请求体：无
- 成功：`200 OK`

成功响应：`ApiResponse<DoctorBindingStatusResponse>`

`DoctorBindingStatusResponse`

- `isBound: Boolean`
- `boundAt: String?`（UTC `Z`）
- `unboundAt: String?`（UTC `Z`）
- `updatedAt: String`（UTC `Z`）

### `PUT /api/v1/users/me/doctor-binding`

- 鉴权：需要 JWT
- 请求头：
  - `Authorization` 必填
  - `Content-Type: application/json`
- 请求体：

```json
{
  "isBound": true
}
```

- 成功：`200 OK`
- 成功响应：`ApiResponse<DoctorBindingStatusResponse>`

接口级可能错误码：

- `40000` 请求体非法（如字段类型不匹配）
- `40100` access token 无效/缺失，或用户不存在

# MindIsle 事件系统 API

## 1. 接口

- `GET /api/v1/users/me/events`
- 鉴权：`Authorization: Bearer <accessToken>`
- 返回：`ApiResponse<UserEventListResponse>`

```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "generatedAt": "2026-03-06T10:00:00+08:00",
    "items": [
      {
        "eventName": "DOCTOR_BIND_REQUIRED",
        "eventType": "BIND_DOCTOR",
        "dueAt": "2026-03-06T10:00:00+08:00",
        "persistent": true,
        "payload": {}
      }
    ]
  }
}
```

## 2. 事件类型

1. `SCALE_REDO_DUE`
   - `eventType = OPEN_SCALE`
   - `payload`: `scaleId/scaleCode/scaleName/intervalDays`
2. `SCALE_SESSION_IN_PROGRESS`
   - `eventType = CONTINUE_SCALE_SESSION`
   - `payload`: `sessionId/scaleId/scaleCode/scaleName/progress`
3. `DOCTOR_BIND_REQUIRED`
   - `eventType = BIND_DOCTOR`
   - `payload`: `{}`
4. `MEDICATION_PLAN_EMPTY`
   - `eventType = IMPORT_MEDICATION_PLAN`
   - `payload`: `activeMedicationCount`
5. `PROFILE_UPDATE_MONTHLY`
   - `eventType = UPDATE_BASIC_PROFILE`
   - `payload`: `anchor`

## 3. 到期时间与判定规则

- `dueAt` 与 `generatedAt` 固定输出为 `UTC+8` 偏移格式（`+08:00`）。
- `SCALE_REDO_DUE`：按量表配置 `redoIntervalDays` 计算（无配置默认 30 天）。
- `SCALE_SESSION_IN_PROGRESS`：每个量表只返回 1 条最新未提交会话。
- `DOCTOR_BIND_REQUIRED`：已接入真实绑定判定。
  - 当用户不存在活跃绑定（`doctor_patient_bindings.status=ACTIVE` 且 `unboundAt IS NULL`）时返回。
  - 不再使用“固定未绑定 TODO”占位逻辑。
- `MEDICATION_PLAN_EMPTY`：无有效用药计划时返回。
- `PROFILE_UPDATE_MONTHLY`：以注册时间为锚点，每月提醒。

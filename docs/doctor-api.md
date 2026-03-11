# MindIsle 医生端 API（v1）

本文档覆盖医生认证、医患绑定、患者管理、量表趋势与报告、用药监测相关接口。  
Base URL：`/api/v1`

## 1. 通用约定

- 成功统一响应：

```json
{
  "code": 0,
  "message": "OK",
  "data": {}
}
```

- 患者鉴权：`Authorization: Bearer <userAccessToken>`
- 医生鉴权：`Authorization: Bearer <doctorAccessToken>`
- 医生登录/注册/刷新/登出必须携带：`X-Device-Id: <device-id>`

## 2. 医生认证

前缀：`/doctor/auth`

1. `POST /doctor/auth/sms-codes`
   - 入参：`{ "phone": "...", "purpose": "REGISTER|RESET_PASSWORD" }`
2. `POST /doctor/auth/register`
   - Header：`X-Device-Id`
   - 入参：`phone/smsCode/password/fullName?/title?/hospital?`
3. `POST /doctor/auth/login/check`
   - Header：`X-Device-Id`
   - 入参：`phone`
   - 返回：`REGISTER_REQUIRED | DIRECT_LOGIN_ALLOWED | PASSWORD_REQUIRED`
4. `POST /doctor/auth/login/direct`
   - Header：`X-Device-Id`
   - 入参：`phone/ticket`
5. `POST /doctor/auth/login/password`
   - Header：`X-Device-Id`
   - 入参：`phone/password`
6. `POST /doctor/auth/token/refresh`
   - Header：`X-Device-Id`
   - 入参：`refreshToken`
7. `POST /doctor/auth/password/reset`
   - 入参：`phone/smsCode/newPassword`
8. `POST /doctor/auth/password/change`（医生 JWT）
   - 入参：`oldPassword/newPassword`
9. `POST /doctor/auth/logout`（医生 JWT）
   - Header：`X-Device-Id`
   - 入参可选：`refreshToken`

认证成功返回 `DoctorAuthResponse`：

```json
{
  "doctorId": 1,
  "token": {
    "accessToken": "...",
    "refreshToken": "...",
    "accessTokenExpiresInSeconds": 1800,
    "refreshTokenExpiresInSeconds": 15552000
  }
}
```

## 3. 医患绑定（严格新协议）

### 3.1 患者侧接口（需要患者 JWT）

1. `GET /users/me/doctor-binding`
   - 返回当前绑定状态。
2. `POST /users/me/doctor-binding/bind`
   - 入参：`{ "bindingCode": "01234" }`
   - `bindingCode` 必须严格匹配 `^\d{5}$`（仅 5 位数字，允许前导 0）。
3. `POST /users/me/doctor-binding/unbind`
   - 解绑当前活跃绑定，历史保留。
4. `GET /users/me/doctor-binding/history?limit=20&cursor=<id>`
   - 返回患者自己的绑定历史。
5. `POST /users/me/side-effects`
   - 入参：`symptom/severity(1-10)/note?/recordedAt?(ISO-8601 instant)`
6. `GET /users/me/side-effects?limit=20&cursor=<id>`
   - 返回患者自己的副作用记录列表。

### 3.2 医生侧接口（需要医生 JWT）

1. `POST /doctors/me/binding-codes`
   - 返回 5 位绑定码（10 分钟有效）：

```json
{
  "code": "01234",
  "expiresAt": "2026-03-11T08:10:00Z"
}
```

2. `GET /doctors/me/binding-history?limit=20&cursor=<id>&patientUserId=<id?>`
   - 返回该医生名下绑定历史（含解绑记录）。

说明：
- 服务端不再返回 `qrPayload`。
- 客户端可自行生成二维码，二维码载荷只需要承载这 5 位码。

### 3.3 绑定业务规则

1. 单活跃绑定：同一患者同一时刻只允许 1 条 `ACTIVE` 绑定。
2. 冲突绑定：患者已绑定医生 A 时，使用医生 B 绑定码会返回 `409 DOCTOR_BINDING_CONFLICT`。
3. 解绑保留历史：解绑将当前记录改为 `UNBOUND`，写入 `unboundAt`。
4. 绑定码一次性：绑定码被消费后立即失效，过期/已消费/错误码都返回 `400 DOCTOR_BINDING_CODE_INVALID`。
5. 不支持自动换绑：必须先解绑，再绑定新医生。

## 4. 医生侧核心接口

前缀：`/doctors/me`

### 4.1 个人与阈值

1. `GET /doctors/me/profile`
2. `GET /doctors/me/thresholds`
3. `PUT /doctors/me/thresholds`
   - 入参：`scl90Threshold?/phq9Threshold?/gad7Threshold?/psqiThreshold?`

### 4.2 患者管理

1. `GET /doctors/me/patients`
   - 查询参数：`limit(1..50)`、`cursor`、`keyword`、`abnormalOnly`
2. `PUT /doctors/me/patients/{patientUserId}/grouping`
   - 入参：`severityGroup?/treatmentPhase?`
3. `GET /doctors/me/patients/{patientUserId}/grouping-history?limit=20&cursor=<id>`

### 4.3 量表趋势与报告

1. `GET /doctors/me/patients/{patientUserId}/scale-trends?days=180`
2. `POST /doctors/me/patients/{patientUserId}/assessment-report`
   - 入参可选：`{ "days": 90 }`
   - LLM 失败时返回模板报告，`polished=false`。

### 4.4 用药与监测

1. `POST /doctors/me/patients/{patientUserId}/medications`
2. `GET /doctors/me/patients/{patientUserId}/medications?limit=50&cursor=<id>&onlyActive=false`
3. `PUT /doctors/me/patients/{patientUserId}/medications/{medicationId}`
4. `DELETE /doctors/me/patients/{patientUserId}/medications/{medicationId}`
5. `GET /doctors/me/patients/{patientUserId}/side-effects/summary?days=30`
6. `GET /doctors/me/patients/{patientUserId}/weight-trend?days=180`

## 5. 错误码（医生域）

- `40040 DOCTOR_INVALID_ARGUMENT`
- `40041 DOCTOR_BINDING_CODE_INVALID`
- `40042 DOCTOR_INVALID_OLD_PASSWORD`
- `40340 DOCTOR_FORBIDDEN`
- `40440 DOCTOR_NOT_FOUND`
- `40441 DOCTOR_PATIENT_NOT_BOUND`
- `40940 DOCTOR_BINDING_CONFLICT`

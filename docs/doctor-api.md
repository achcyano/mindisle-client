# MindIsle 医生端 API（v1）

本文档覆盖医生认证、医患绑定、患者管理、量表趋势/报告、处方调整、用药监测与副作用/体重接口。

## 1. 通用约定

- Base URL: `/api/v1`
- 统一返回：

```json
{
  "code": 0,
  "message": "OK",
  "data": {}
}
```

- 医生端鉴权：`Authorization: Bearer <doctorAccessToken>`
- 患者端鉴权：`Authorization: Bearer <userAccessToken>`
- 设备标识：`X-Device-Id: <device-id>`（医生登录/注册/刷新/登出必传）

## 2. 医生认证

前缀：`/doctor/auth`

1. `POST /doctor/auth/sms-codes`
   - 入参：`{ "phone": "...", "purpose": "REGISTER|RESET_PASSWORD" }`
2. `POST /doctor/auth/register`
   - 头：`X-Device-Id`
   - 入参：`phone/smsCode/password/fullName/title?/hospital?`
3. `POST /doctor/auth/login/password`
   - 头：`X-Device-Id`
   - 入参：`phone/password`
4. `POST /doctor/auth/token/refresh`
   - 头：`X-Device-Id`
   - 入参：`refreshToken`
5. `POST /doctor/auth/password/reset`
   - 入参：`phone/smsCode/newPassword`
6. `POST /doctor/auth/password/change`（医生 JWT）
   - 入参：`oldPassword/newPassword`
7. `POST /doctor/auth/logout`（医生 JWT）
   - 头：`X-Device-Id`
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

## 3. 患者侧绑定与副作用

需要患者 JWT（`auth-jwt`）。

1. `GET /users/me/doctor-binding`
   - 返回当前是否绑定及当前绑定信息。
2. `POST /users/me/doctor-binding/bind`
   - 入参：`{ "bindingCode": "123456" }`
   - 规则：同一患者同一时刻只允许 1 位活跃医生。
3. `POST /users/me/doctor-binding/unbind`
   - 解绑当前活跃医生，历史保留。
4. `GET /users/me/doctor-binding/history?limit=20&cursor=<id>`
   - 返回患者自己的绑定历史。
5. `POST /users/me/side-effects`
   - 入参：`symptom/severity(1-10)/note?/recordedAt?(ISO-8601 instant)`
6. `GET /users/me/side-effects?limit=20&cursor=<id>`
   - 返回患者自己的副作用记录列表。

## 4. 医生侧核心接口

需要医生 JWT（`doctor-auth-jwt`），前缀：`/doctors/me`

### 4.1 个人与阈值

1. `GET /doctors/me/profile`
2. `GET /doctors/me/thresholds`
3. `PUT /doctors/me/thresholds`
   - 入参：`scl90Threshold?/phq9Threshold?/gad7Threshold?/psqiThreshold?`

### 4.2 绑定码与绑定历史

1. `POST /doctors/me/binding-codes`
   - 返回 `code`（6位）、`expiresAt`（10分钟）、`qrPayload`。
2. `GET /doctors/me/binding-history?limit=20&cursor=<id>&patientUserId=<id?>`
   - 返回该医生名下绑定历史（含解绑历史）。

### 4.3 患者管理

1. `GET /doctors/me/patients`
   - 查询参数：
   - `limit`（1..50）
   - `cursor`
   - `keyword`（按手机号/姓名）
   - `abnormalOnly`（true/false）
   - 仅返回“当前活跃绑定到该医生”的患者。
   - `metrics.adherence` 当前固定返回 `null`。
2. `PUT /doctors/me/patients/{patientUserId}/grouping`
   - 入参：`severityGroup?/treatmentPhase?`
   - 服务端保存当前值，并写入变更历史。
3. `GET /doctors/me/patients/{patientUserId}/grouping-history?limit=20&cursor=<id>`

### 4.4 量表趋势与自动报告

1. `GET /doctors/me/patients/{patientUserId}/scale-trends?days=180`
2. `POST /doctors/me/patients/{patientUserId}/assessment-report`
   - 入参：`{ "days": 90 }`（可选）
   - 行为：模板报告 + LLM 润色。
   - LLM 失败时降级返回模板，且 `polished=false`，接口仍成功返回。

### 4.5 处方调整（代管患者用药）

1. `POST /doctors/me/patients/{patientUserId}/medications`
2. `GET /doctors/me/patients/{patientUserId}/medications?limit=50&cursor=<id>&onlyActive=false`
3. `PUT /doctors/me/patients/{patientUserId}/medications/{medicationId}`
4. `DELETE /doctors/me/patients/{patientUserId}/medications/{medicationId}`

限制：医生仅可操作“当前活跃绑定”患者的数据。

### 4.6 副作用汇总与体重曲线

1. `GET /doctors/me/patients/{patientUserId}/side-effects/summary?days=30`
2. `GET /doctors/me/patients/{patientUserId}/weight-trend?days=180`

体重日志来源：
- 患者更新 `/users/me/profile` 且体重变化
- 患者更新 `/users/me/basic-profile` 且体重变化

## 5. 关键业务规则

1. 绑定关系：单活跃绑定 + 历史保留（解绑后状态改为 `UNBOUND`）。
2. 绑定码：6 位数字，10 分钟过期，一次消费。
3. 异常筛选：按医生阈值 + 患者最新量表总分（SCL90/PHQ9/GAD7/PSQI）。
4. 依从性：字段保留，当前返回 `null`，不参与异常判断。
5. TESS：本期未纳入筛选。

## 6. 新增错误码

- `40040 DOCTOR_INVALID_ARGUMENT`
- `40041 DOCTOR_BINDING_CODE_INVALID`
- `40042 DOCTOR_INVALID_OLD_PASSWORD`
- `40340 DOCTOR_FORBIDDEN`
- `40440 DOCTOR_NOT_FOUND`
- `40441 DOCTOR_PATIENT_NOT_BOUND`
- `40940 DOCTOR_BINDING_CONFLICT`

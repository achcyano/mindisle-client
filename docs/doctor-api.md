# MindIsle 医生端 API（v1）

本文档覆盖医生认证、医生资料、医患绑定、患者管理、量表趋势与报告、用药监测相关接口。

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
- 医生注册、登录、刷新、登出必须携带：`X-Device-Id: <device-id>`

## 2. 医生认证

前缀：`/doctor/auth`

1. `POST /doctor/auth/sms-codes`
   - 入参：`{ "phone": "...", "purpose": "REGISTER|RESET_PASSWORD" }`
2. `POST /doctor/auth/register`
   - Header：`X-Device-Id`
   - 入参：`phone/smsCode/password/fullName?/hospital?`
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
8. `POST /doctor/auth/password/change`
   - 需要医生 JWT
   - 入参：`oldPassword/newPassword`
9. `POST /doctor/auth/logout`
   - 需要医生 JWT
   - Header：`X-Device-Id`
   - 入参可选：`refreshToken`

认证成功返回：

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

注册说明：
- `fullName` 可不传；未传时服务端会自动生成占位名。
- `hospital` 可不传。
- 若传入 `fullName` 或 `hospital`，会先 `trim()`，空白字符串会返回 `400`。

## 3. 医生资料

前缀：`/doctors/me`

1. `GET /doctors/me/profile`
   - 返回当前医生资料：

```json
{
  "doctorId": 1,
  "fullName": "张医生",
  "hospital": "某某医院"
}
```

2. `PUT /doctors/me/profile`
   - 入参：

```json
{
  "fullName": "张医生",
  "hospital": "某某医院"
}
```

更新语义：
- `null` 表示不修改该字段
- 非空字符串会先 `trim()`
- `trim()` 后为空字符串返回 `400`
- 更新成功后返回最新完整资料

## 4. 医患绑定（严格 5 位绑定码）

### 4.1 患者侧接口

需要患者 JWT。

1. `GET /users/me/doctor-binding`
2. `POST /users/me/doctor-binding/bind`
   - 入参：`{ "bindingCode": "01234" }`
   - `bindingCode` 必须严格匹配 `^\d{5}$`
3. `POST /users/me/doctor-binding/unbind`
4. `GET /users/me/doctor-binding/history?limit=20&cursor=<id>`
5. `POST /users/me/side-effects`
6. `GET /users/me/side-effects?limit=20&cursor=<id>`

### 4.2 医生侧接口

需要医生 JWT。

1. `POST /doctors/me/binding-codes`
   - 返回：

```json
{
  "code": "01234",
  "expiresAt": "2026-03-11T08:10:00Z"
}
```

2. `GET /doctors/me/binding-history?limit=20&cursor=<id>&patientUserId=<id?>`

说明：
- 服务端不返回 `qrPayload`
- 客户端可自行把 5 位绑定码编码到二维码内容中

### 4.3 绑定规则

1. 同一患者同一时刻只允许 1 条 `ACTIVE` 绑定
2. 已绑定医生 A 的患者，不能直接绑定医生 B；会返回 `409 DOCTOR_BINDING_CONFLICT`
3. 解绑后保留历史，当前记录状态改为 `UNBOUND`
4. 绑定码 10 分钟有效，一次性消费
5. 过期、已消费、错误码统一返回 `400 DOCTOR_BINDING_CODE_INVALID`

## 5. 医生业务接口

前缀：`/doctors/me`

1. `GET /doctors/me/thresholds`
2. `PUT /doctors/me/thresholds`
3. `GET /doctors/me/patients`
4. `PUT /doctors/me/patients/{patientUserId}/grouping`
5. `GET /doctors/me/patients/{patientUserId}/grouping-history`
6. `GET /doctors/me/patients/{patientUserId}/scale-trends`
7. `POST /doctors/me/patients/{patientUserId}/assessment-report`
8. `POST /doctors/me/patients/{patientUserId}/medications`
9. `GET /doctors/me/patients/{patientUserId}/medications`
10. `PUT /doctors/me/patients/{patientUserId}/medications/{medicationId}`
11. `DELETE /doctors/me/patients/{patientUserId}/medications/{medicationId}`
12. `GET /doctors/me/patients/{patientUserId}/side-effects/summary`
13. `GET /doctors/me/patients/{patientUserId}/weight-trend`

## 6. 错误码（医生域）

- `40040 DOCTOR_INVALID_ARGUMENT`
- `40041 DOCTOR_BINDING_CODE_INVALID`
- `40042 DOCTOR_INVALID_OLD_PASSWORD`
- `40340 DOCTOR_FORBIDDEN`
- `40440 DOCTOR_NOT_FOUND`
- `40441 DOCTOR_PATIENT_NOT_BOUND`
- `40940 DOCTOR_BINDING_CONFLICT`

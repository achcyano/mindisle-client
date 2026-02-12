# MindIsle 服务端接口与行为说明（客户端对接版）

本文档基于当前 `mindisle-server` 源码整理，覆盖所有已注册路由、请求/响应格式、鉴权与设备头要求、错误码及触发原因，并说明服务端运行机制。

## 1. 服务概览

- 运行框架: Ktor + Netty
- 默认监听: `0.0.0.0:8808`（可由 `KTOR_HTTP_PORT` 覆盖）
- 统一业务 API 前缀: `/api/v1`
- 数据库: MySQL（Exposed + HikariCP）
- 启动时行为: 自动建表（`SchemaUtils.create`，无迁移版本管理）

已注册路由：

- `GET /`
- `POST /test`
- `POST /api/v1/auth/sms-codes`
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login/check`
- `POST /api/v1/auth/login/direct`
- `POST /api/v1/auth/login/password`
- `POST /api/v1/auth/token/refresh`
- `POST /api/v1/auth/password/reset`
- `POST /api/v1/auth/logout`
- `GET /api/v1/users/me`
- `PUT /api/v1/users/me/profile`

## 2. 通用约定

### 2.1 编码与 JSON

- 请求/响应编码: UTF-8
- JSON 解析: `isLenient=true`、`ignoreUnknownKeys=true`
- 含义：
- 未定义字段会被忽略，不会报错。
- 缺少必填字段、字段类型不匹配、枚举值非法等会返回 `40000 Invalid request body`。

### 2.2 通用响应包装（业务 API）

`/api/v1/**` 路由统一返回：

```json
{
  "code": 0,
  "message": "OK",
  "data": {}
}
```

字段定义：

- `code`: 业务码，`0` 为成功。
- `message`: 文本消息。
- `data`: 业务数据，可为 `null`。

说明：`GET /` 和 `POST /test` 返回纯文本，不使用该包装。

### 2.3 鉴权与请求头

- Access Token 头：`Authorization: Bearer <accessToken>`
- 设备头：`X-Device-Id: <device-id>`
- 代理 IP 头（可选）：`X-Forwarded-For: <ip[,proxy1,...]>`

`X-Device-Id` 的服务端要求：

- 必须非空字符串（仅在指定接口强制）。
- 未做长度校验，但数据库字段上限为 128；超长可能触发数据库异常（50000）。

### 2.4 手机号规则

仅支持中国大陆手机号：`^1[3-9]\d{9}$`。

服务端会先做标准化：

- 去掉空格与 `-`
- `+86xxxxxxxxxxx` 会去掉 `+86`
- `86xxxxxxxxxxx`（长度 13）会去掉 `86`

最终入库与响应中的手机号都为 11 位本地号码（不含国家码）。

## 3. 枚举与数据模型

### 3.1 枚举

`SmsPurpose`：

- `REGISTER`
- `RESET_PASSWORD`

`LoginDecision`：

- `REGISTER_REQUIRED`
- `DIRECT_LOGIN_ALLOWED`
- `PASSWORD_REQUIRED`

`Gender`：

- `UNKNOWN`
- `MALE`
- `FEMALE`
- `OTHER`

### 3.2 主要请求体

`SendSmsCodeRequest`

- `phone: String`（必填）
- `purpose: SmsPurpose`（必填）

`RegisterRequest`

- `phone: String`（必填）
- `smsCode: String`（必填）
- `password: String`（必填，至少 6 位）
- `profile: UpsertProfileRequest?`（可选）

`LoginCheckRequest`

- `phone: String`（必填）

`DirectLoginRequest`

- `phone: String`（必填）
- `ticket: String`（必填，一次性票据）

`PasswordLoginRequest`

- `phone: String`（必填）
- `password: String`（必填）

`TokenRefreshRequest`

- `refreshToken: String`（必填）

`ResetPasswordRequest`

- `phone: String`（必填）
- `smsCode: String`（必填）
- `newPassword: String`（必填，至少 6 位）

`LogoutRequest`

- `refreshToken: String?`（可选，用于校验“当前设备会话是否为该 token”）

`UpsertProfileRequest`

- `fullName: String?`（可选，最多 200 字符）
- `gender: Gender?`（可选）
- `birthDate: String?`（可选，必须 `yyyy-MM-dd`）
- `weightKg: Double?`（可选，数据库精度 `DECIMAL(5,2)`）
- `familyHistory: List<String>?`（可选，每项最多 200 字符）
- `medicalHistory: List<String>?`（可选，每项最多 200 字符）
- `medicationHistory: List<String>?`（可选，每项最多 200 字符）

更新语义（`PUT /users/me/profile`）：

- 字段为 `null` 表示不修改该字段。
- 列表字段传入后会“整表替换”：先删旧数据，再写入新列表。
- 列表项会 `trim()` 后写入，空字符串项会被丢弃。

### 3.3 主要响应体

`TokenPairResponse`

- `accessToken: String`
- `refreshToken: String`
- `accessTokenExpiresInSeconds: Long`
- `refreshTokenExpiresInSeconds: Long`

`AuthResponse`

- `userId: Long`
- `token: TokenPairResponse`

`LoginCheckResponse`

- `decision: LoginDecision`
- `ticket: String?`（仅 `DIRECT_LOGIN_ALLOWED` 时有值）

`UserProfileResponse`

- `userId: Long`
- `phone: String`
- `fullName: String?`
- `gender: Gender`
- `birthDate: String?`
- `weightKg: Double?`
- `familyHistory: List<String>`
- `medicalHistory: List<String>`
- `medicationHistory: List<String>`

## 4. 接口详情

## 4.1 健康检查

### `GET /`

- 鉴权：无
- 请求头：无特殊要求
- 请求体：无
- 成功响应：`200 text/plain`

示例：

```text
MindIsle server is running.
```

### `POST /test`

- 鉴权：无
- 请求头：无特殊要求
- 请求体：无
- 成功响应：`200 text/plain`

示例：

```text
This is a test endpoint.
```

## 4.2 认证与账户

### `POST /api/v1/auth/sms-codes`

- 鉴权：无
- 请求头：
- `Content-Type: application/json`
- `X-Forwarded-For` 可选（只取第一个 IP，存入数据库）
- 请求体：`SendSmsCodeRequest`
- 成功：`202 Accepted`

成功响应：

```json
{
  "code": 0,
  "message": "Accepted",
  "data": null
}
```

接口级可能错误码：

- `40000` 请求体非法
- `40001` 手机号非法
- `40402` `purpose=RESET_PASSWORD` 且手机号未注册
- `40901` `purpose=REGISTER` 且手机号已注册
- `42901` 短信发送过频（冷却期内）
- `42902` 当日短信次数超限
- `50010` 短信服务商调用失败（阿里云）

### `POST /api/v1/auth/register`

- 鉴权：无
- 请求头：
- `Content-Type: application/json`
- `X-Device-Id` 必填
- 请求体：`RegisterRequest`
- 成功：`201 Created`

成功响应：`ApiResponse<AuthResponse>`。

接口级可能错误码：

- `40000` 请求体非法、缺失 `X-Device-Id`、`profile` 字段格式非法
- `40001` 手机号非法
- `40002` 密码长度不足 6
- `40003` 验证码错误/过期/已消费
- `40901` 手机号已注册
- `42903` 验证码校验失败次数超限
- `50010` 短信服务商校验失败（阿里云）

### `POST /api/v1/auth/login/check`

- 鉴权：无
- 请求头：
- `Content-Type: application/json`
- `X-Device-Id` 必填
- 请求体：`LoginCheckRequest`
- 成功：`200 OK`

成功响应：`ApiResponse<LoginCheckResponse>`。

行为说明：

- 手机号未注册：`decision=REGISTER_REQUIRED`
- 手机号已注册且该 `userId + deviceId` 存在 `ACTIVE` 会话：`DIRECT_LOGIN_ALLOWED` 并发放一次性 `ticket`
- 其他情况：`PASSWORD_REQUIRED`

`ticket` 特性：

- 默认有效期 120 秒（可配置）
- 与 `phone + deviceId + userId` 绑定
- 仅可消费一次

接口级可能错误码：

- `40000` 请求体非法、缺失 `X-Device-Id`
- `40001` 手机号非法

### `POST /api/v1/auth/login/direct`

- 鉴权：无
- 请求头：
- `Content-Type: application/json`
- `X-Device-Id` 必填
- 请求体：`DirectLoginRequest`
- 成功：`200 OK`

成功响应：`ApiResponse<AuthResponse>`。

接口级可能错误码：

- `40000` 请求体非法、缺失 `X-Device-Id`
- `40001` 手机号非法
- `40004` ticket 无效/过期/已消费/与设备不匹配
- `40401` 手机号未注册

### `POST /api/v1/auth/login/password`

- 鉴权：无
- 请求头：
- `Content-Type: application/json`
- `X-Device-Id` 必填
- 请求体：`PasswordLoginRequest`
- 成功：`200 OK`

成功响应：`ApiResponse<AuthResponse>`。

接口级可能错误码：

- `40000` 请求体非法、缺失 `X-Device-Id`
- `40001` 手机号非法
- `40101` 密码错误
- `40401` 手机号未注册

### `POST /api/v1/auth/token/refresh`

- 鉴权：无
- 请求头：
- `Content-Type: application/json`
- `X-Device-Id` 必填
- 请求体：`TokenRefreshRequest`
- 成功：`200 OK`

成功响应：`ApiResponse<AuthResponse>`。

刷新规则：

- 必须命中同设备（`deviceId`）下的 `ACTIVE` 会话。
- 会话必须未过期。
- 刷新成功后会轮换（替换）`refreshToken`，旧 token 立即失效。

接口级可能错误码：

- `40000` 请求体非法、缺失 `X-Device-Id`
- `40100` refresh token 无效/过期/设备不匹配

### `POST /api/v1/auth/password/reset`

- 鉴权：无
- 请求头：
- `Content-Type: application/json`
- 请求体：`ResetPasswordRequest`
- 成功：`200 OK`

成功响应：

```json
{
  "code": 0,
  "message": "Password reset success",
  "data": null
}
```

行为说明：

- 重置成功后，会将该用户所有会话标记为 `REVOKED`（所有设备下线）。

接口级可能错误码：

- `40000` 请求体非法
- `40001` 手机号非法
- `40002` 新密码长度不足 6
- `40003` 验证码错误/过期/已消费
- `40402` 手机号未注册
- `42903` 验证码校验失败次数超限
- `50010` 短信服务商校验失败（阿里云）

### `POST /api/v1/auth/logout`

- 鉴权：需要 JWT（`Authorization: Bearer <accessToken>`）
- 请求头：
- `Authorization` 必填
- `X-Device-Id` 必填
- `Content-Type: application/json`（可选，有 body 时建议带）
- 请求体：可选 `LogoutRequest`
- 成功：`200 OK`

成功响应：

```json
{
  "code": 0,
  "message": "Logged out",
  "data": null
}
```

行为说明：

- 仅撤销当前 `userId + deviceId` 的 `ACTIVE` 会话。
- 如果该设备没有 `ACTIVE` 会话，也返回成功。
- 若传了 `refreshToken`，会校验是否匹配当前设备会话，不匹配返回 40100。
- body 解析失败时会被忽略并按“无 body”处理。

接口级可能错误码：

- `40000` 缺失 `X-Device-Id`
- `40100` access token 无效/缺失，或 refreshToken 与设备会话不匹配

## 4.3 用户资料

### `GET /api/v1/users/me`

- 鉴权：需要 JWT
- 请求头：
- `Authorization` 必填
- 请求体：无
- 成功：`200 OK`

成功响应：`ApiResponse<UserProfileResponse>`。

行为说明：

- 若用户 profile 行不存在，会自动创建默认 profile（`gender=UNKNOWN`）。

接口级可能错误码：

- `40100` access token 无效/缺失，或用户不存在

### `PUT /api/v1/users/me/profile`

- 鉴权：需要 JWT
- 请求头：
- `Authorization` 必填
- `Content-Type: application/json`
- 请求体：`UpsertProfileRequest`
- 成功：`200 OK`

成功响应：`ApiResponse<UserProfileResponse>`（返回更新后的完整资料）。

接口级可能错误码：

- `40000` 请求体非法、`birthDate` 格式错误、文本超长
- `40100` access token 无效/缺失，或用户不存在

## 5. 错误码总表（含原因）

| 业务码 | HTTP 状态 | 含义 | 触发原因（可能） |
|---|---|---|---|
| 0 | 200/201/202 | 成功 | 请求处理成功 |
| 40000 | 400 | INVALID_REQUEST | 请求体反序列化失败；枚举值非法；缺少必填字段；缺失 `X-Device-Id`；`birthDate` 非 `yyyy-MM-dd`；资料文本超过 200 字符 |
| 40001 | 400 | INVALID_PHONE | 手机号不符合中国大陆手机号规则 |
| 40002 | 400 | PASSWORD_TOO_SHORT | `password` 或 `newPassword` 长度 < 6 |
| 40003 | 400 | INVALID_SMS_CODE | 验证码错误、过期、已消费 |
| 40004 | 400 | LOGIN_TICKET_INVALID | 直登票据无效、过期、已消费，或设备/手机号不匹配 |
| 40100 | 401 | UNAUTHORIZED | access token 无效/过期/缺失；refresh token 无效/过期/设备不匹配；logout 时 refresh token 与设备会话不匹配；用户不存在 |
| 40101 | 401 | INVALID_CREDENTIALS | 密码登录时密码错误 |
| 40401 | 404 | REGISTER_REQUIRED | 密码登录/直登时手机号未注册 |
| 40402 | 404 | PHONE_NOT_REGISTERED | 重置密码发码或重置密码时手机号未注册 |
| 40901 | 409 | PHONE_ALREADY_REGISTERED | 注册发码或注册时手机号已注册 |
| 42901 | 429 | SMS_TOO_FREQUENT | 短信发送触发冷却间隔限制 |
| 42902 | 429 | SMS_DAILY_LIMIT | 当日短信发送次数达到上限 |
| 42903 | 429 | SMS_VERIFY_TOO_MANY_ATTEMPTS | 验证码校验失败次数达到窗口上限 |
| 50010 | 500 | SMS_PROVIDER_ERROR | 短信供应商配置缺失、SDK 异常、网关调用失败、返回非 OK |
| 50000 | 500 | Internal server error | 未捕获异常（数据库约束错误等） |

统一错误响应示例：

```json
{
  "code": 40000,
  "message": "Invalid request body",
  "data": null
}
```

## 6. 服务端工作机制

### 6.1 启动流程

1. 安装 JSON 序列化插件（宽松解析 + 忽略未知字段）。
2. 初始化数据库连接池并自动建表。
3. 初始化 JWT 服务。
4. 根据 `SMS_PROVIDER` 初始化短信网关：
- `local/none/disabled` => 不接第三方网关
- `aliyun` => 阿里云网关
5. 注册全局异常处理（`StatusPages`）。
6. 注册 JWT 鉴权（`auth-jwt`）。
7. 注册路由。

### 6.2 令牌与会话模型

- Access Token: JWT，包含 `uid`（用户 ID）和 `did`（设备 ID）声明。
- Refresh Token: 随机串，只存储其 SHA-256 哈希。
- 会话唯一键：`(user_id, device_id)`。
- 同一设备重复登录会覆盖该设备旧 refresh token。
- 刷新 token 会轮换 refresh token，并延长会话过期时间。

默认 TTL（可配）：

- `ACCESS_TOKEN_TTL_SECONDS = 1800`（30 分钟）
- `REFRESH_TOKEN_TTL_SECONDS = 15552000`（180 天）
- `LOGIN_TICKET_TTL_SECONDS = 120`（2 分钟）

### 6.3 短信与验证码机制

发送限制（按手机号）：

- 冷却间隔：默认 60 秒
- 日上限：默认 10 次

校验限制（按手机号 + purpose）：

- 窗口：默认 600 秒
- 窗口内最大失败次数：默认 5 次
- 达到上限后返回 `42903`

模式差异：

- `local`：服务端本地生成验证码并存哈希校验。
- `aliyun`：发送与校验都依赖阿里云接口，服务端仍记录请求与尝试轨迹。

### 6.4 资料存储机制

- 用户基础信息在 `user_profiles`（一行）
- 家族史/病史/用药史在独立子表（一对多）
- 更新资料时，若提交列表字段，则对应子表全量替换

## 7. 客户端接入建议流程

1. 登录页先调 `POST /api/v1/auth/login/check`。
2. 根据 `decision` 分流：
- `REGISTER_REQUIRED`：走注册流程。
- `DIRECT_LOGIN_ALLOWED`：调用 `POST /api/v1/auth/login/direct`。
- `PASSWORD_REQUIRED`：调用 `POST /api/v1/auth/login/password`。
3. access token 过期后调用 `POST /api/v1/auth/token/refresh` 并替换本地 token 对。
4. 忘记密码走短信重置：发码（`RESET_PASSWORD`）+ `POST /api/v1/auth/password/reset`。
5. 注销时调用 `POST /api/v1/auth/logout`，并清理本地 token。

## 8. 关键配置项（影响客户端行为）

- `KTOR_HTTP_PORT`
- `ACCESS_TOKEN_TTL_SECONDS`
- `REFRESH_TOKEN_TTL_SECONDS`
- `LOGIN_TICKET_TTL_SECONDS`
- `SMS_CODE_TTL_SECONDS`
- `SMS_COOLDOWN_SECONDS`
- `SMS_DAILY_LIMIT`
- `SMS_VERIFY_WINDOW_SECONDS`
- `SMS_VERIFY_MAX_ATTEMPTS`
- `SMS_PROVIDER`（`local` 或 `aliyun`）

建议客户端将以上 TTL 与限制设计为“服务端可变参数”，不要硬编码固定值。

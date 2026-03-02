# 用药模块 API 文档

本文档描述 `/api/v1/users/me/medications` 的接口、字段约束、错误码与时区规则。

## 1. 总览

- 认证方式：`Authorization: Bearer <accessToken>`
- 响应包装：`ApiResponse<T>`
- 基础路径：`/api/v1/users/me/medications`
- 时区约定：
  - `recordedDate` 由服务端自动生成，按 `UTC+8` 计算当天日期。
  - `createdAt` / `updatedAt` 为 UTC 时间（ISO8601，结尾 `Z`）。

## 2. 数据结构

### 2.1 枚举

- `MedicationDoseUnit`: `MG | G | TABLET`
- `MedicationStrengthUnit`: `MG | G`

### 2.2 创建/更新请求体

```json
{
  "drugName": "阿司匹林",
  "doseTimes": ["08:00", "12:30", "19:00"],
  "endDate": "2026-03-31",
  "doseAmount": 1.0,
  "doseUnit": "TABLET",
  "tabletStrengthAmount": 500.0,
  "tabletStrengthUnit": "MG"
}
```

字段说明：

- `drugName: String`，必填，去首尾空格后不能为空，最大 200 字符。
- `doseTimes: List<String>`，必填，长度 `1~16`，每项必须是严格 `HH:mm`（如 `08:00`）。
- `endDate: String`，必填，格式 `yyyy-MM-dd`。
- `doseAmount: Double`，必填，范围 `(0, 100000]`，按 3 位小数保存。
- `doseUnit: MedicationDoseUnit`，必填。
- `tabletStrengthAmount: Double?`，条件必填（见下）。
- `tabletStrengthUnit: MedicationStrengthUnit?`，条件必填（见下）。

剂量联动规则：

- 当 `doseUnit = TABLET`：
  - `tabletStrengthAmount` 和 `tabletStrengthUnit` 都必须传。
- 当 `doseUnit = MG/G`：
  - `tabletStrengthAmount` 和 `tabletStrengthUnit` 必须都不传（`null`）。

## 3. 接口定义

## 3.1 新增药品

`POST /api/v1/users/me/medications`

请求头：

- `Authorization: Bearer <accessToken>`
- `Content-Type: application/json`

成功响应：`201`

```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "medicationId": 12,
    "drugName": "阿司匹林",
    "doseTimes": ["08:00", "12:30", "19:00"],
    "recordedDate": "2026-03-02",
    "endDate": "2026-03-31",
    "doseAmount": 1.0,
    "doseUnit": "TABLET",
    "tabletStrengthAmount": 500.0,
    "tabletStrengthUnit": "MG",
    "isActive": true,
    "createdAt": "2026-03-02T07:00:00Z",
    "updatedAt": "2026-03-02T07:00:00Z"
  }
}
```

## 3.2 获取药品列表

`GET /api/v1/users/me/medications?limit=50&cursor=<optional>&onlyActive=false`

请求头：

- `Authorization: Bearer <accessToken>`

查询参数：

- `limit`：默认 `50`，范围 `1~200`。
- `cursor`：可选，按 `medicationId` 倒序分页。
- `onlyActive`：可选，默认 `false`，支持 `true/false/1/0`。

active 判定：

- `recordedDate <= today(UTC+8) <= endDate`

成功响应：`200`

```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "items": [],
    "activeCount": 0,
    "nextCursor": null
  }
}
```

## 3.3 更新药品

`PUT /api/v1/users/me/medications/{medicationId}`

请求头：

- `Authorization: Bearer <accessToken>`
- `Content-Type: application/json`

路径参数：

- `medicationId`：正整数。

请求体：与新增接口一致（全量更新）。

更新限制：

- `recordedDate` 不可由客户端修改。
- `endDate` 必须大于等于该记录的 `recordedDate`。

成功响应：`200`，`data` 结构同新增接口。

## 3.4 删除药品

`DELETE /api/v1/users/me/medications/{medicationId}`

请求头：

- `Authorization: Bearer <accessToken>`

路径参数：

- `medicationId`：正整数。

成功响应：`200`

```json
{
  "code": 0,
  "message": "OK",
  "data": null
}
```

## 4. 错误码

- `40030 MEDICATION_INVALID_ARGUMENT`
  - 路径参数非法
  - `onlyActive` 不是布尔值
  - `drugName` 为空/过长/含控制字符
  - `doseTimes` 为空、超过 16 项、或存在非 `HH:mm` 项
  - `endDate` 非 `yyyy-MM-dd` 或早于允许日期
  - `doseAmount/tabletStrengthAmount` 非法（非有限数、<=0、>100000）
  - `doseUnit` 与 `tabletStrength*` 联动不合法
- `40100 UNAUTHORIZED`
  - token 无效或用户不存在
- `40430 MEDICATION_NOT_FOUND`
  - 当前用户下不存在对应 `medicationId`


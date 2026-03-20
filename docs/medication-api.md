# 用药模块 API 文档

本文档描述 `/api/v1/users/me/medications` 的接口、字段规则、软删除行为与错误码。

## 1. 总览

- 认证：`Authorization: Bearer <accessToken>`
- 响应：`ApiResponse<T>`
- 路径前缀：`/api/v1/users/me/medications`
- 时间约定：
  - `recordedDate` 由服务端自动生成，按 `UTC+8` 的当天日期保存。
  - `createdAt` / `updatedAt` 使用 UTC 时间（ISO8601，`Z` 结尾）。

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

字段规则：

- `drugName`：必填，去空格后不能为空，最多 200 字符。
- `doseTimes`：必填，`1~16` 项，每项必须严格 `HH:mm`。
- `endDate`：必填，格式 `yyyy-MM-dd`。
- `doseAmount`：必填，范围 `(0, 100000]`，按 3 位小数保存。
- `doseUnit`：必填。
- `tabletStrengthAmount/tabletStrengthUnit` 联动：
  - `doseUnit=TABLET` 时，这两个字段都必填。
  - `doseUnit=MG/G` 时，这两个字段都必须为 `null`。

## 3. 接口

## 3.1 新增药品

`POST /api/v1/users/me/medications`

请求头：

- `Authorization: Bearer <accessToken>`
- `Content-Type: application/json`

成功：`201`

## 3.2 获取药品列表

`GET /api/v1/users/me/medications?limit=50&cursor=<optional>&onlyActive=false`

请求头：

- `Authorization: Bearer <accessToken>`

查询参数：

- `limit`：默认 `50`，范围 `1~200`。
- `cursor`：可选，正整数，按 `medicationId` 倒序分页。
- `onlyActive`：可选，默认 `false`，支持 `true/false/1/0`。

active 判定：

- `recordedDate <= today(UTC+8) <= endDate`

成功：`200`

返回体示例：

```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "items": [
      {
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
    ],
    "activeCount": 1,
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

请求体：与创建接口一致（全量更新）。

更新限制：

- `recordedDate` 由服务端维护，不允许客户端修改。
- `endDate` 必须大于等于该记录的 `recordedDate`。
- 已删除记录不可更新（返回 `40430`）。

成功：`200`

## 3.4 删除药品（软删除）

`DELETE /api/v1/users/me/medications/{medicationId}`

请求头：

- `Authorization: Bearer <accessToken>`

路径参数：

- `medicationId`：正整数。

成功：`200`

软删除规则：

- 删除时仅写入删除标记（`deleted_at`），不物理删除数据库数据。
- 已删除数据不会在列表接口返回。
- 已删除数据不可更新。
- 再次删除同一条已删除记录，接口保持成功（幂等）。

## 4. 错误码

- `40030 MEDICATION_INVALID_ARGUMENT`
  - 参数格式或业务约束不满足
- `40100 UNAUTHORIZED`
  - token 无效或用户不存在
- `40430 MEDICATION_NOT_FOUND`
  - 记录不存在，或不属于当前用户，或记录已删除

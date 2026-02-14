# MindIsle Flutter Material 3 文本与颜色使用说明

本文档用于统一项目中的 Material 3 `Typography` 和 `ColorScheme` 使用方式，保证页面风格一致、可维护。

## 1. Typography（文本层级）

Flutter Material 3 提供以下 15 个文本样式（`Theme.of(context).textTheme`）：

1. `displayLarge`
2. `displayMedium`
3. `displaySmall`
4. `headlineLarge`
5. `headlineMedium`
6. `headlineSmall`
7. `titleLarge`
8. `titleMedium`
9. `titleSmall`
10. `bodyLarge`
11. `bodyMedium`
12. `bodySmall`
13. `labelLarge`
14. `labelMedium`
15. `labelSmall`

### 推荐用途

1. `display*`：超大展示文案。
2. `headline*`：页面主标题。
3. `title*`：区块标题或中等强调文本。
4. `body*`：正文与说明文案。
5. `label*`：按钮和短标签文字。

## 2. ColorScheme（颜色语义）

使用 `Theme.of(context).colorScheme` 获取语义色，而不是写死颜色值。

### 常用颜色与含义

1. `primary`：品牌主色、主操作元素。
2. `onPrimary`：放在 `primary` 背景上的文字/图标。
3. `surface`：页面/容器背景色。
4. `onSurface`：主要正文颜色。
5. `onSurfaceVariant`：次要说明文字颜色。
6. `surfaceContainerHighest`：层级容器背景色（如键盘按键底色）。
7. `outline`：边框、分割线。
8. `error`：错误提示颜色。

## 3. 当前项目的 TextTheme 自定义（主题层）

定义位置：`lib/view/theme/app_text_theme.dart`

1. `displaySmall`: `32 / w800 / letterSpacing 0.7`
2. `headlineSmall`: `19 / w600`
3. `bodySmall`: `13 / w300`
4. `titleSmall`: `17 / w300`
5. `labelLarge`: `16 / w600`
6. `titleLarge`: `23 / w300`
7. `titleMedium`: `16 / w300 / letterSpacing 0.6`

主题入口：`lib/view/theme/app_theme.dart`，在 `lib/main.dart` 注入。

## 4. 当前各组件实际使用的字体

### 欢迎页

1. `lib/view/pages/start/welcome_page.dart`
   App 名称：`displaySmall`

### 登录步骤页（phone / otp / password）

1. `lib/view/pages/login/steps/phone_step_view.dart`
   标题：`headlineSmall`  
   描述：`bodySmall`（仅 `copyWith` 颜色）  
   输入框文字：`titleSmall`  
   错误提示：`bodySmall`（仅 `copyWith` 颜色）

2. `lib/view/pages/login/steps/otp_step_view.dart`
   标题：`headlineSmall`  
   描述：`bodySmall`（仅 `copyWith` 颜色）  
   错误提示：`bodySmall`（仅 `copyWith` 颜色）  
   验证码格子数字：`titleLarge`（与数字键盘数字一致）

3. `lib/view/pages/login/steps/password_step_view.dart`
   标题：`headlineSmall`  
   描述：`bodySmall`（仅 `copyWith` 颜色）  
   输入框文字：`titleSmall`  
   错误提示：`bodySmall`（仅 `copyWith` 颜色）

### 复用组件

1. `lib/view/widget/guided_entry_button.dart`
   按钮文字：`labelLarge`

2. `lib/view/widget/number_keypad.dart`
   数字：`titleLarge`  
   字母：`titleMedium`

### SnackBar（保持默认）

1. `lib/main.dart`
2. `lib/features/auth/presentation/login/login_flow_controller.dart`

以上两处 `SnackBar` 文本未手动传 `TextStyle`，并且未设置 `snackBarTheme.contentTextStyle`，因此使用 Material 3 默认样式。

## 5. 实践规范

1. 优先使用主题：`textTheme` + `colorScheme`。
2. 避免写死 `Colors.black/grey` 等固定色值。
3. 同类文案统一用同一 typography，颜色差异再用 `copyWith` 微调。
4. 若全局要改字号/字重，优先改 `lib/view/theme/app_text_theme.dart`。

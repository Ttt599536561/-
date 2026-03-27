# 心动课表

心动课表是一个面向情侣场景的 Android 课表应用，目标是把“我的课表、TA 的课表、共同空闲时间、共享待办、纪念日互动”整合到同一个产品里，降低日常沟通成本，提升线下约会和协同安排的效率。

当前项目已经具备完整的本地可运行界面和主要业务页面，技术栈为 `Kotlin + Jetpack Compose + Hilt + Room + DataStore + Retrofit/Moshi`。它已经可以正常编译运行，但目前仍处于“高保真原型 / 本地演示版”阶段，还没有完全打通真实账号体系、跨设备同步和正式情侣协同闭环。

## 当前状态

- 项目类型：Android 原生应用
- 最低版本：`minSdk 26`
- 编译目标：`targetSdk 35`
- UI 技术：Jetpack Compose
- 本地数据：Room + DataStore
- 远端预留：Retrofit + Supabase API 定义已存在，但业务未完全接入
- 构建状态：2026-03-25 已验证 `:app:compileDebugKotlin` 与 `:app:lintDebug` 可通过

## 已有功能

- 登录页 / 注册页
- 课表首页
  - 我的课表
  - 共同课表
  - TA 的课表
- 手动添加 / 编辑 / 删除课程
- 教务系统导入课表
- 情侣绑定页
- 互动页
  - 纪念日
  - 共享清单
  - 快捷提醒
- 日视图 / 空档页
- 设置页
  - 学期设置
  - 当前周校正
  - 上课时间配置
  - 主题切换

## 当前限制

- 当前账号体系仍以本地演示逻辑为主，真实用户登录未打通
- 课程、情侣关系、共享待办目前主要保存在本地数据库中
- `SupabaseApi` 已定义，但还没有形成真实的远端同步闭环
- 情侣绑定目前是本地模拟，不是跨设备真实绑定
- 导入课表当前采用覆盖式写入，符合当前产品定位；后续重点应放在导入预览、失败诊断和稳定性，而不是备份合并或额外确认步骤
- 项目当前没有自动化测试目录
- 目前存在若干安全与工程化问题，详见 [ARCHITECTURE.md](./ARCHITECTURE.md) 和 [TODO_ROADMAP.md](./TODO_ROADMAP.md)

## 目录结构

```text
app/src/main/java/com/heartbeat/schedule
├─ data
│  ├─ local
│  │  ├─ datastore
│  │  ├─ db
│  │  └─ session
│  ├─ remote
│  │  ├─ api
│  │  └─ model
│  └─ repository
├─ di
├─ domain
│  ├─ mapper
│  ├─ model
│  ├─ usecase
│  └─ util
├─ ui
│  ├─ component
│  ├─ navigation
│  ├─ screen
│  └─ theme
├─ HeartbeatApp.kt
├─ MainActivity.kt
└─ SplashActivity.kt
```

## 运行方式

### 1. 环境要求

- Android Studio 最新稳定版或兼容 AGP 8.7.3 的版本
- JDK 17 或更高版本
- 已安装 Android SDK

### 2. 本地运行

```bash
./gradlew :app:assembleDebug
```

Windows:

```powershell
.\gradlew.bat :app:assembleDebug
```

### 3. 常用检查命令

```powershell
.\gradlew.bat :app:compileDebugKotlin
.\gradlew.bat :app:lintDebug
```

## 配置说明

当前工程在 [app/build.gradle.kts](./app/build.gradle.kts) 中预留了以下构建参数：

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

但它们目前仍是占位值，项目当前并不依赖真实远端配置也能运行本地流程。

## 开发产物存放约定

为了避免后续继续把临时截图、日志、数据库文件堆到项目根目录，项目约定如下：

- 临时实机截图放到 `.artifacts/screenshots/`
- 临时运行日志放到 `.artifacts/logs/`
- 临时数据库导出放到 `.artifacts/db/`
- 需要长期保留、并会在文档中引用的正式图片放到 `docs/images/`
- 项目根目录不放临时截图、日志、数据库或其他调试产物

说明：

- `.artifacts/` 下的子目录默认通过各自的 `.gitignore` 忽略，不参与版本管理
- `docs/images/` 用于真正需要长期保留的文档图片
- 根级 `.gitignore` 已补充对常见根目录截图、日志、数据库和构建产物的忽略规则

## 交互与 UI 设计约束

后续所有功能设计、交互设计和界面布局，必须符合基本的人机交互学原则，尤其要遵守以下约束：

- 所有系统提示都应尽量出现在用户当前视觉关注区域附近，优先放在页面上半区或相关内容区域附近
- 系统提示不得遮挡输入框、主按钮、返回按钮等关键操作控件
- 表单校验类提示应优先靠近相关输入区域，而不是放到屏幕底部
- 轻量反馈应采用非打断式提示，减少用户决策负担
- 重要提醒、危险操作、不可逆操作必须使用弹窗或明确确认流程
- 页面布局应优先遵循中国大陆主流移动应用的阅读顺序、操作路径和视觉层级习惯
- 能通过减少步骤、减少判断、减少跳转来完成的流程，不应增加额外选择成本

## 风险提示

当前仓库里仍存在一些不适合直接发布正式版的内容：

- 签名信息直接写在 Gradle 配置中
- 存在 `usesCleartextTraffic="true"` 和宽松的 network security 配置
- WebView 导入页对 SSL 错误采取放行策略
- 根目录保留了截图、日志、数据库等开发期文件

这些问题不会影响本地继续开发，但会影响正式发布和安全合规。

## 推荐阅读顺序

如果你是第一次接手这个项目，建议按下面顺序阅读：

1. [README.md](./README.md)
2. [ARCHITECTURE.md](./ARCHITECTURE.md)
3. [DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md)
4. [SUPABASE_DATABASE_SETUP.sql](./SUPABASE_DATABASE_SETUP.sql)
5. [TODO_ROADMAP.md](./TODO_ROADMAP.md)
6. [PROJECT_HISTORY.md](./PROJECT_HISTORY.md)

## 后续开发建议

建议优先把项目从“本地演示原型”推进到“单用户稳定版”，再做“真实情侣协同版”：

1. 先统一周次、节次、导入、课表展示的业务规则。
2. 再补齐账号体系、情侣绑定、远端同步。
3. 最后完善提醒、分享、小组件、统计等增强能力。

详细路线图见 [TODO_ROADMAP.md](./TODO_ROADMAP.md)。

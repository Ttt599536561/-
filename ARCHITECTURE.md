# 项目架构说明

## 1. 项目定位

心动课表当前采用的是典型的单模块 Android 应用结构：`app` 模块内同时承载 UI、业务逻辑、本地数据和远端接口定义。架构方向已经接近分层，但还没有完全收敛为严格的 Clean Architecture。

从实际代码状态看，当前更适合定义为：

- UI 层：Compose + ViewModel 驱动
- 数据层：Room / DataStore 为主，Retrofit 为预留
- 领域层：已有部分 model / usecase / util，但职责尚未完全稳定

## 2. 当前分层

### 2.1 UI 层

目录：

- `ui/navigation`
- `ui/screen`
- `ui/component`
- `ui/theme`

职责：

- 页面展示
- Compose 交互逻辑
- 页面级状态订阅
- 路由跳转

特点：

- 目前大部分页面采用 `Screen + ViewModel` 结构
- 多个页面文件较大，单文件承载了过多 UI 细节和交互逻辑
- 存在一定程度的组件复用，但还不够系统化

主要页面：

- `ScheduleScreen`
- `GapFinderScreen`
- `InteractiveScreen`
- `SettingsScreen`
- `CourseEditScreen`
- `ScheduleImportScreen`
- `CoupleBindScreen`
- `LoginScreen`
- `RegisterScreen`

### 2.2 状态管理层

目录：

- `ui/screen/**/**ViewModel.kt`

职责：

- 聚合 repository 数据
- 输出页面 `UiState`
- 处理页面动作
- 驱动导航前置状态

当前特点：

- 基本采用 `MutableStateFlow + StateFlow`
- ViewModel 职责较重，部分同时承担了业务规则、数据拼装和 UI 特化逻辑
- 某些状态计算没有完全抽离到 domain 层

### 2.3 数据层

目录：

- `data/local`
- `data/remote`
- `data/repository`

职责：

- 本地持久化
- 会话信息持久化
- 远端接口声明
- 为 ViewModel 提供统一数据访问入口

当前特点：

- 实际运行主要依赖 Room + DataStore
- 远端接口已定义，但 repository 还未形成“本地 + 远端同步”双源模型
- repository 当前更多是“本地数据包装层”

### 2.4 领域层

目录：

- `domain/model`
- `domain/usecase`
- `domain/util`
- `domain/mapper`

职责：

- 业务模型
- 核心算法
- 周次和时间规则
- entity / dto / domain 间映射

当前特点：

- 已有一定业务抽象
- 但规则仍有一部分散落在 ViewModel 和 Screen 中
- `GapFinderUseCase` 已存在，但尚未真正驱动空档页面主逻辑

## 3. 核心数据流

### 3.1 登录流程

当前流程：

1. 用户输入手机号或昵称
2. `AuthViewModel` 调用 `UserPreferences.saveLogin(...)`
3. 本地写入登录态和默认用户 ID
4. 若本地没有用户档案，则写入 `UserProfileEntity`
5. `MainActivity` 根据登录态决定起始页面

当前问题：

- 真实账号体系未打通
- 默认用户仍使用固定 `demo_user`
- 登录态是“本地伪登录”，不具备跨设备一致性

### 3.2 课表流程

当前流程：

1. `ScheduleViewModel` 监听当前用户课程和用户档案
2. 结合周次规则生成当前展示周
3. 页面用 `ScheduleGrid` 绘制周课表
4. 新增或编辑课程时，由 `CourseEditViewModel` 写入 `CourseRepository`

当前问题：

- 周次和节次规则没有统一配置源
- 编辑页、导入页、课表页、空档页对“总周数 / 总节数”的认知不完全一致

### 3.3 课表导入流程

当前流程：

1. `ScheduleImportScreen` 打开教务系统 WebView
2. 注入 `extract_zhengfang.js`
3. 解析课程 JSON
4. 用户预览后保存
5. `ScheduleImportViewModel` 删除当前用户旧课程并写入新课程

当前问题：

- 当前导入逻辑强依赖具体页面结构
- 适配范围偏窄，实际更像定制化解析
- 保存策略是“全量覆盖”
- 后续优化重点应是低阻力导入、失败诊断和稳定性，而不是备份合并或额外确认步骤

### 3.4 情侣绑定流程

当前流程：

1. 生成 6 位邀请码
2. 输入对方邀请码后本地创建绑定关系
3. 自动生成 `partner_xxx` 的虚拟对方账号
4. 后续通过本地数据库模拟查看 TA 的课表

当前问题：

- 不是真实绑定
- 不是服务端校验的邀请码
- 不支持跨设备
- 不支持绑定确认、失效、重复绑定治理

### 3.5 互动流程

当前流程：

- 纪念日保存在本地绑定关系中
- 共享待办保存在本地 `shared_todos`
- 快捷提醒只更新页面 snackbar

当前问题：

- 不会真正发送给对方
- 不是同步数据
- “TA 当前状态”计算没有严格按学周和自定义节次时间判断

## 4. 主要模块说明

### 4.1 本地持久化

#### Room

表结构：

- `courses`
- `user_profile`
- `couple_binding`
- `shared_todos`

特点：

- 已有基础 migration
- 本地模型已经足以支撑单机版业务
- 但数据隔离、同步状态、冲突处理仍不完整

#### DataStore

保存内容：

- 登录态
- 用户 ID
- token
- 主题
- 节次时间

问题：

- 登录态默认值策略偏激进，页面初始渲染存在误判风险
- token 字段已预留，但当前真实认证未接入

### 4.2 远端接口

目录：

- `data/remote/api/SupabaseApi.kt`
- `data/remote/model/*`

当前状态：

- 已定义课程、用户、情侣、邀请码、共享待办接口
- DI 也已注入 Retrofit / OkHttp / Moshi
- 但业务 repository 并未真正使用这些接口完成同步闭环

结论：

这是“远端集成预留层”，不是“已完成远端业务层”。

## 5. 当前架构问题

### 5.1 原型态逻辑和产品态逻辑混用

项目最核心的问题不是“代码不能跑”，而是“演示逻辑和正式业务逻辑尚未拆开”。典型表现包括：

- `demo_user` 贯穿多个模块
- 本地生成虚拟 partner 用户
- WebView 导入采用偏开发态的宽松安全策略

### 5.2 业务规则分散

当前至少有以下规则未完全统一：

- 总周数
- 当前周计算
- 节次数量
- 节次时间
- 导入周次归一化
- 对方课程可见性

这些规则分别存在于：

- `domain/util`
- `ViewModel`
- `Screen`
- Canvas 绘制逻辑

这会让后续改一个规则时容易漏改。

### 5.3 Screen 文件过大

当前多个页面超过 600 行，`SettingsScreen.kt` 更是超过 1000 行。问题包括：

- 阅读成本高
- 复用困难
- 交互状态难追踪
- 容易出现重复实现

### 5.4 领域抽象尚未闭环

虽然已有 `GapFinderUseCase` 等领域对象，但真正的页面输出没有完全依赖 usecase 驱动，导致：

- domain 层和 UI 层职责边界不清
- 同一规则在不同层重复实现

## 6. 推荐演进方向

## 6.1 短期目标：先做稳定的单用户版本

建议优先收敛：

- 周次 / 节次统一
- 导入流程稳定
- 本地课表逻辑一致
- 互动页状态判断准确
- 页面结构拆分

### 6.2 中期目标：再打通真实情侣协同

建议补齐：

- 真实用户体系
- 服务端邀请码绑定
- 云端同步
- 共享待办与纪念日跨设备一致
- 共同空闲时间真正由双方课表计算

### 6.3 长期目标：形成完整产品能力

包括：

- 通知提醒
- 分享导出
- 小组件
- 统计能力
- 备份恢复

## 7. 推荐目标架构

后续可以逐步演进为：

```text
UI (Compose Screens / Components)
  ↓
Presentation (ViewModel / UiState / UiAction)
  ↓
Domain (UseCase / Rule / Aggregation)
  ↓
Data (Repository)
  ↓
Local(Room/DataStore) + Remote(API)
```

其中建议重点落地两件事：

1. 把所有“学期 / 周次 / 节次 / 导入归一化”统一收敛到 domain 层。
2. 把 repository 从“本地包装层”升级成“本地 + 远端同步协调层”。

## 8. 文档对应关系

- 项目概览和运行方式：见 [README.md](./README.md)
- 当前问题、需求清单和路线图：见 [TODO_ROADMAP.md](./TODO_ROADMAP.md)

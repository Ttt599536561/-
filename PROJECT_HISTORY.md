# Project History

## 文档用途
这份文档用于记录项目的重要修改历史，帮助后续开发者快速了解：

- 项目当前处于什么阶段
- 最近改过哪些地方
- 为什么要改
- 改动属于哪个功能模块
- 改动是修复问题、交互优化，还是新增能力
- 改动后做过什么验证

适用场景：

- 新成员接手项目
- 开发新功能前排查历史改动
- 回溯某个页面为什么现在会这样表现
- 在没有 Git 提交说明或提交记录不完整时补充背景

## 记录说明

- 修改人：`GPT-5.4`
- 时间来源：`本次开发会话记录 + 文件最后修改时间`
- 说明：当前项目目录不是标准 Git 仓库，因此这里记录的是人工维护的历史说明，不等同于正式提交记录
- 约定：后续每次涉及 UI、交互逻辑、业务规则、签名配置、打包流程、数据结构等变更时，都应追加一条记录

## 项目当前概况

- 项目名称：`HeartbeatSchedule / 心动课表`
- 技术栈：`Kotlin + Compose + Hilt + Room + DataStore + Retrofit/Moshi`
- 当前状态：可正常编译并生成签名 `release APK`
- APK 签名：当前项目已接入 `app/heartbeat.jks`
- 说明文档状态：此前根目录缺少可用于交接的变更历史文档，本文件为补充建立

## 当前已知约束

- 后端正式环境参数仍是占位值：
  - `SUPABASE_URL = https://your-project.memfiredb.com`
  - `SUPABASE_ANON_KEY = your-anon-key`
- 账号体系仍偏本地演示型，未完成正式云端闭环
- 项目当前未发现正式的测试目录或自动化测试用例
- 很多业务判断依赖本地数据和 Room 数据库，开发新功能时应优先确认是否会影响本地课表展示、周次计算和设置页

## 近期修改记录

### 1. 2026-03-25 09:02:03

- 修改人：`GPT-5.4`
- 功能模块：`构建与签名 / 打包发布`
- 修改类型：`工程配置 / 发布配置`
- 修改原因：
  - 需要让项目能够稳定生成统一签名的 `debug` 和 `release` 包
  - 避免后续打包时出现临时手签、签名来源不一致、安装覆盖失败等问题
- 修改内容：
  - 在 `app/build.gradle.kts` 中补充 `signingConfigs.release`
  - 将 `debug` 与 `release` 统一接入 `app/heartbeat.jks`
  - 使 Gradle 直接生成已签名的 `app-release.apk`
- 影响文件：
  - `app/build.gradle.kts`
  - `app/heartbeat.jks`
- 验证结果：
  - 已成功执行 `:app:assembleDebug`
  - 已成功执行 `:app:assembleRelease`
  - 已使用 `apksigner verify --print-certs` 校验签名

### 2. 2026-03-25 09:13:16

- 修改人：`GPT-5.4`
- 功能模块：`课程编辑 / 手动添加课程页`
- 修改类型：`UI 优化 / 交互修正`
- 修改原因：
  - 用户反馈“返回按钮”和“添加课程/编辑课程”标题距离状态栏过远
  - 页面顶部实际上叠加了多层上边距，导致视觉位置偏低
- 修改内容：
  - 收紧顶部标题行自身的上下间距
  - 去掉顶部重复叠加的 inset，只保留一层安全区
  - 保证标题区更靠近状态栏，但仍不会贴边
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/course/CourseEditScreen.kt`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`
  - 已重新打包并覆盖桌面安装包

### 3. 2026-03-25 09:25:00

- 修改人：`GPT-5.4`
- 功能模块：`课表首页 / 顶部日期栏`
- 修改类型：`Bug 修复`
- 修改原因：
  - 用户切换到非本周时，顶部日期栏仍然显示“今天”的蓝色选中背景
  - 这会造成当前查看周与真实本周混淆
- 修改内容：
  - 课表页顶部日期高亮逻辑改为：
    - 只有当前查看周等于真实本周时，才高亮今天
    - 查看其他周时，不再保留“今天”的蓝底状态
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleScreen.kt`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`
  - 已重新打包并覆盖桌面安装包

### 4. 2026-03-25 10:27:35

- 修改人：`GPT-5.4`
- 功能模块：`学期规则 / 周次与日期映射`
- 修改类型：`业务规则修正`
- 修改原因：
  - 用户要求：无论把哪一天设置为“上课第一天”，系统都应把第一周对齐到该日期所在周的周一
  - 之前对“第一周”起点的理解存在偏差，容易导致课表日期展示与用户预期不一致
- 修改内容：
  - 将第一周起点统一定义为：
    - `用户所选开学日期所在周的周一`
  - 同步影响：
    - 当前周计算
    - 课表页顶部日期映射
    - 基于学期起点的整周展示逻辑
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/domain/util/WeekUtil.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleScreen.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/component/ScheduleGrid.kt`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`

### 5. 2026-03-25 12:38:29

- 修改人：`GPT-5.4`
- 功能模块：`设置 / 学期设置`
- 修改类型：`规则限制调整`
- 修改原因：
  - 用户要求将学期总周数上限从原有逻辑调整为 `24 周`
  - 避免设置页保存出超出产品预期的周数
- 修改内容：
  - 将学期总周数保存限制从 `1..30` 修改为 `1..24`
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/settings/SettingsViewModel.kt`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`
  - 已重新打包并覆盖桌面安装包

### 6. 2026-03-25 13:30:47

- 修改人：`GPT-5.4`
- 功能模块：`设置 / 学期设置弹窗`
- 修改类型：`UI 重构 / 交互优化`
- 修改原因：
  - 原弹窗视觉层级较弱，背景色与整体风格不统一
  - “总周数”标题位置不统一
  - “预览：当前周为第 X 周 / 共 Y 周”表达成本高，第一眼不易理解
  - 用户学习成本偏高，不符合主流设置面板交互习惯
- 修改内容：
  - 新增一版更清晰的学期设置弹窗实现，并替换旧入口
  - 统一字段结构为：
    - 顶部说明
    - 开学日期卡片
    - 总周数输入
    - 保存后效果摘要
  - 优化背景色、卡片边框、信息分组和阅读层级
  - 将“总周数”标题移到输入框上方，与“开学日期”保持一致
  - 将晦涩的预览文案改为 3 条结果摘要：
    - 第一周开始
    - 按今天计算
    - 学期长度
  - 为总周数输入补充数字键盘、占位提示和“周”后缀
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/settings/SettingsScreen.kt`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`

### 7. 2026-03-25 13:33:52

- 修改人：`GPT-5.4`
- 功能模块：`课表首页 / 空状态展示`
- 修改类型：`UI 统一 / 体验优化`
- 修改原因：
  - “我的 / 共同 / TA的” 三个空状态卡片尺寸、位置和视觉样式不统一
  - 空状态组件占位偏大，容易压住课表中心区域
  - 三种提示缺少统一的视觉体系
- 修改内容：
  - 将三种空状态统一为一套更紧凑的居中卡片样式
  - 保持图标存在，但统一为更年轻、干净的线性图标风格：
    - `School`
    - `Link`
    - `Person`
  - 缩小空状态占位尺寸，使其尽量停留在课表中间
  - 统一标题字号、说明文案样式和按钮区域布局
  - 绑定按钮保留，但整体样式融入统一空状态卡片
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleScreen.kt`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`
  - 已重新打包并覆盖桌面安装包

### 8. 2026-03-25 13:45:00

- 修改人：`GPT-5.4`
- 功能模块：`课表导入 / 周次对齐 / 课表展示`
- 修改类型：`Bug 修复 / 数据显示修正`
- 修改原因：
  - 用户反馈：即使设置了学期日期，第一节课仍然会在后一周才显示
  - 根因不是日期头本身，而是部分导入课表的最早周次并不是第 1 周，而是第 2 周或更后
  - 仅修改“学期日期映射”不足以修复这种数据偏移
- 修改内容：
  - 新增课程显示周次归一化逻辑：
    - 如果课程列表的最早周次大于 1，则显示时整体前移，使最早周次对齐到第 1 周
  - 在导入课表保存时，同步把最早导入周次归一化到第 1 周
  - 对已有已导入数据，展示层也会自动修正，无需重新导入即可生效
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/domain/util/WeekUtil.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/gapfinder/GapFinderViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/importschedule/ScheduleImportViewModel.kt`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`

### 9. 2026-03-25 14:05:00

- 修改人：`GPT-5.4`
- 功能模块：`当前周管理 / 设置页 / 导入完成流程`
- 修改类型：`功能增强 / 交互补充`
- 修改原因：
  - 项目此前只有“学期设置”和“自动计算当前周”，缺少手动校正当前周的能力
  - 导入课表后也缺少“当前周是否识别正确”的确认环节
  - 自动计算出错时，用户无法直接纠偏
- 修改内容：
  - 新增“当前周校正”能力
  - 为用户资料新增 `current_week_offset` 字段，用于记录当前周相对自动计算结果的偏移量
  - 自动周次继续随时间推进，手动校正后不会固定死在某一周
  - 设置页增加“当前周校正”入口，并支持恢复自动识别
  - 导入完成后强制弹出“确认当前周”对话框，允许用户：
    - 直接确认当前周正确
    - 立刻手动修改当前周
  - 课表页、寻空页会统一读取修正后的当前周与学期锚点
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/domain/util/WeekUtil.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/local/db/entity/UserProfileEntity.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/local/db/dao/UserProfileDao.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/local/db/HeartbeatDatabase.kt`
  - `app/src/main/java/com/heartbeat/schedule/di/DatabaseModule.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/repository/UserProfileRepository.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/settings/SettingsViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/settings/SettingsScreen.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/gapfinder/GapFinderViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/importschedule/ScheduleImportViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/importschedule/ScheduleImportScreen.kt`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`

### 10. 2026-03-25 15:50:00

- 修改人：`GPT-5.4`
- 功能模块：`设置页 / 当前周校正`
- 修改类型：`Bug 修复 / 稳定性热修`
- 修改原因：
  - 用户反馈：点击“我的”页后会崩溃，尤其是在打开“手动修改当前周”后点击空白区域更容易触发闪退
  - 为优先恢复可用性，需要先移除设置页里潜在不稳定的弹窗复用方案
- 修改内容：
  - 不再在设置页复用课表页的 `WeekPickerDialog`
  - 改为设置页内部独立的“当前周校正”对话框
  - 采用更简单的数字输入方式，减少弹窗层级和点击空白区域带来的不确定行为
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/settings/SettingsScreen.kt`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`

### 11. 2026-03-25 16:40:00

- 修改人：`GPT-5.4`
- 功能模块：`设置页信息架构 / 学期与周次`
- 修改类型：`交互优化 / 信息分组调整`
- 修改原因：
  - 用户反馈“当前周校正”不应出现在“外观”分组下
  - 参考主流课表产品后，学期开始日期、当前周、学期周数应属于同一类“课表数据”或“学期与周次”配置
- 修改内容：
  - 将“当前周校正”从“外观”区域移动到“设置”区域
  - 放在“学期设置”之后，形成连续的“学期与周次”配置链路
  - 恢复“外观”分组仅承载主题切换，减少用户认知干扰
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/settings/SettingsScreen.kt`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`

### 12. 2026-03-26 01:23:42

- 修改人：`GPT-5.4`
- 功能模块：`文档治理 / 开发环境整理 / 登录体系`
- 修改类型：`文档补充 / 工程清理 / 功能改造`
- 修改原因：
  - 项目此前缺少正式的交接文档，后续接手者难以快速理解项目现状、架构和开发路线
  - 根目录残留了大量调试截图、日志、数据库和构建产物，容易污染项目目录并影响维护体验
  - 账号体系仍依赖本地演示态 `demo_user`，无法支撑真实用户登录与后续情侣协同能力
  - 登录流程原本区分“注册”和“登录”，用户学习成本偏高，不符合“输入邮箱验证码即可自动注册或登录”的产品目标
- 修改内容：
  - 新增正式项目文档：
    - `README.md`
    - `ARCHITECTURE.md`
    - `TODO_ROADMAP.md`
  - 在 `README.md` 中补充了“开发产物存放约定”，明确：
    - 临时截图放 `.artifacts/screenshots/`
    - 临时日志放 `.artifacts/logs/`
    - 临时数据库导出放 `.artifacts/db/`
    - 正式文档图片放 `docs/images/`
  - 新增 `.gitignore`、`.artifacts/`、`docs/images/` 目录结构，并建立临时产物忽略规则
  - 清理根目录调试残留：
    - 删除课程编辑/课表验证截图
    - 删除 `logcat` 导出文件
    - 删除本地数据库导出文件
    - 删除根目录与 `app/` 下的构建产物目录
  - 调整路线图文档中的导入策略描述，统一为：
    - 课表导入继续保持直接覆盖导入
    - 不做备份合并
    - 不增加额外覆盖确认步骤
    - 后续重点放在失败提示与导入稳定性
  - 接入 Supabase 邮箱 OTP 登录：
    - 新增 `SupabaseAuthApi`、认证 DTO 与 `AuthRepository`
    - 在 `NetworkModule` 中补充 `auth/v1` 接口注入
    - 将 `app/build.gradle.kts` 中的 Supabase 占位配置替换为真实 `SUPABASE_URL` 和 `publishable key`
  - 去除本地伪登录链路：
    - 删除 `saveLogin()` 方案
    - 去掉 `demo_user`
    - `UserSessionProvider` 改为严格依赖真实登录用户
    - `ScheduleImportViewModel` 改为使用当前真实用户 ID
  - 重构邮箱验证码登录体验：
    - 登录页改为单入口“邮箱验证码登录”
    - 新用户与老用户统一走同一条验证码流程
    - 验证成功后自动完成注册或登录
    - 首次登录自动创建本地 `UserProfile`
  - 重新构建并导出桌面安装包：
    - `心动课表-v1.0.0-debug.apk`
- 影响文件：
  - `README.md`
  - `ARCHITECTURE.md`
  - `TODO_ROADMAP.md`
  - `.gitignore`
  - `.artifacts/README.md`
  - `.artifacts/screenshots/.gitignore`
  - `.artifacts/logs/.gitignore`
  - `.artifacts/db/.gitignore`
  - `docs/images/.gitkeep`
  - `app/build.gradle.kts`
  - `app/src/main/java/com/heartbeat/schedule/di/NetworkModule.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/local/datastore/UserPreferences.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/local/session/UserSessionProvider.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/repository/UserProfileRepository.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/repository/AuthRepository.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/remote/api/SupabaseAuthApi.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/remote/model/AuthDto.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/auth/AuthViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/auth/LoginScreen.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/auth/RegisterScreen.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/importschedule/ScheduleImportViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/MainActivity.kt`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`
  - 已成功执行 `:app:assembleDebug`
  - 已重新生成桌面安装包 `心动课表-v1.0.0-debug.apk`

### 13. 2026-03-26 01:32:26

- 修改人：`GPT-5.4`
- 功能模块：`邮箱 OTP 登录体验 / 系统提示体验`
- 修改类型：`交互优化 / 反馈机制优化`
- 修改原因：
  - 用户反馈：邮箱验证码短时间内无法重新发送时，如果邮箱填错，当前流程会把用户卡住，导致登录阻力过高
  - 用户反馈：当前登录提示样式不够现代，需要统一检查轻提示与强提醒的使用场景
  - 情侣绑定成功后同时出现成功页面和 Snackbar，提示重复
- 修改内容：
  - 优化邮箱验证码体验：
    - 在验证码发送后增加“修改邮箱”入口
    - 用户即使遇到发送频控，也可以直接返回修改邮箱重新获取验证码
    - 保留“重新发送验证码”入口，但不再把它作为唯一恢复手段
  - 优化认证错误文案：
    - 针对 Supabase 频控报错增加友好化提示
    - 当服务端提示需等待较长时间时，明确告诉用户可以直接修改邮箱继续
    - 对 `signups not allowed for otp` 等错误增加更可理解的中文说明
  - 新增统一轻提示组件：
    - 新增 `HeartbeatSnackbarHost`
    - 将默认 Snackbar 替换为更统一的圆角白底轻提示样式
  - 统一关键页面的轻提示外观：
    - 登录页
    - 课程编辑页
    - 情侣绑定页
    - 互动页
  - 去掉情侣绑定成功后的重复 Snackbar，仅保留成功状态页作为主反馈
  - 对当前项目的提示方式做了一轮梳理，形成了“轻提示 / 强提醒”分类基线：
    - 轻提示：发送验证码、课程校验失败、快捷提醒已发送、邀请码格式错误等
    - 强提醒：清空课程、解绑情侣、导入完成后的当前周确认、导入失败页、日期/时间选择等
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/data/repository/AuthRepository.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/auth/LoginScreen.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/component/HeartbeatSnackbar.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/course/CourseEditScreen.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/couple/CoupleBindScreen.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/interactive/InteractiveScreen.kt`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`

### 14. 2026-03-26 01:39:00

- 修改人：`GPT-5.4`
- 功能模块：`邮箱登录页布局 / 轻提示体验`
- 修改类型：`UI 重构 / 交互简化`
- 修改原因：
  - 用户反馈：当前邮箱登录页整体位置偏低，品牌区距离屏幕顶部过远，不符合主流移动应用布局
  - 用户反馈：登录页文案不够简洁，部分辅助说明冗余，增加了用户理解成本
  - 用户反馈：页面中存在“大背景框内叠输入框”的层级感，视觉上不够清爽
  - 需要进一步统一“轻提示 / 强提醒”的使用边界，避免不必要的打断式反馈
- 修改内容：
  - 重构邮箱登录页布局：
    - 将页面整体上移，品牌区更贴近状态栏
    - 移除大卡片式外层容器，改为更接近主流大陆 App 的“顶部品牌区 + 单列输入区 + 直接主按钮”结构
    - 保留简洁背景，突出输入和主操作按钮
  - 调整登录页文案：
    - 将“输入邮箱和验证码，自动完成注册或登录”改为“新用户自动注册”
    - 将“验证码已送到……”缩短为“验证码已发送”
    - 删除“如果邮箱填错了……”的长说明
    - 将按钮文案“验证并进入”改为“登录注册”
  - 简化登录页交互：
    - 去掉“修改邮箱”按钮
    - 保持邮箱输入框在验证码阶段仍可直接编辑
    - 验证时以当前输入框里的邮箱为准，减少额外步骤
  - 保留“重新发送验证码”作为最小辅助操作，但不再给它额外的大按钮层级
  - 延续上一轮轻提示方案，继续使用统一 `HeartbeatSnackbarHost`
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/auth/LoginScreen.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/auth/AuthViewModel.kt`
  - `PROJECT_HISTORY.md`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`

### 15. 2026-03-26 02:05:00

- 修改人：`GPT-5.4`
- 功能模块：`系统提示位置 / 登录页人机交互 / UI 设计约束`
- 修改类型：`交互修复 / 设计规范补充 / 测试验证`
- 修改原因：
  - 用户反馈：登录页“请输入正确的邮箱地址”等提示出现在屏幕底部，不符合用户当前视线焦点，也不符合人机交互学
  - 用户要求：全项目检查类似提示方式，系统提示应优先出现在屏幕上半区或相关内容附近，且不能遮挡输入框和按钮
  - 用户要求：将“符合人机交互学”明确写入根目录文档，作为后续功能设计和 UI 布局的长期约束
- 修改内容：
  - 新增页内消息条组件：
    - `HeartbeatMessageBanner`
    - 用于在页面上半区、内容区域内承载轻量提示
  - 登录页改为页内错误提示：
    - “请输入正确的邮箱地址”等错误不再走底部提示
    - 改为显示在品牌区下方、输入区域上方
    - 保证提示不遮挡输入框和主按钮
  - 将以下页面的底部轻提示迁移为页内上方消息条：
    - 邮箱登录页
    - 课程编辑页
    - 情侣绑定页
    - 互动页
  - 登录页继续按用户要求简化：
    - 保持“新用户自动注册”
    - 保持“验证码已发送”
    - 保持“登录注册”按钮文案
    - 去掉“修改邮箱”按钮
    - 允许用户直接编辑邮箱输入框
  - 在 `README.md` 中新增“交互与 UI 设计约束”章节，明确写入：
    - 所有功能设计、交互设计、UI 布局必须符合人机交互学原则
    - 系统提示优先出现在用户当前视觉关注区域附近
    - 系统提示不得遮挡输入框、按钮等关键控件
    - 表单校验提示优先靠近相关输入区域
    - 轻提示与强提醒应按风险级别分层使用
  - 在严格测试阶段发现：
    - Windows + 中文路径 + KSP/Hilt 在并发构建时容易出现生成目录异常
    - 改为使用英文目录别名 `C:\\hbapp` 串行执行编译与 lint，验证通过
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/ui/component/HeartbeatMessageBanner.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/auth/LoginScreen.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/auth/AuthViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/course/CourseEditScreen.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/couple/CoupleBindScreen.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/interactive/InteractiveScreen.kt`
  - `README.md`
  - `PROJECT_HISTORY.md`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:lintDebug`（基于 `C:\\hbapp` 串行执行）

### 16. 2026-03-26 11:30:00

- 修改人：`GPT-5.4`
- 功能模块：`路线图文档 / 清单治理`
- 修改类型：`文档更新 / 计划重排`
- 修改原因：
  - 原有 `TODO_ROADMAP.md` 中部分问题项已经过时，例如 `demo_user`、本地伪登录等描述不再符合项目现状
  - 最近几轮新增了登录体验、提示系统、人机交互约束、构建规范等任务，需要纳入正式清单
  - 需要重新梳理当前最优先任务，避免后续继续按旧路线推进
- 修改内容：
  - 重写 `TODO_ROADMAP.md`
  - 清理已完成或已过时的问题项
  - 新增当前阶段真实存在的缺口：
    - 真实情侣绑定
    - 共享数据远端同步
    - 提示系统全量统一
    - `RegisterScreen` 角色处理
    - Windows + 中文路径 + KSP/Hilt 构建规范
  - 更新功能清单、优化清单、需求清单和里程碑
  - 重新排序“最近最值得先做的 10 件事”，使其更符合当前项目阶段
- 影响文件：
  - `TODO_ROADMAP.md`
  - `PROJECT_HISTORY.md`
- 验证结果：
  - 已人工复核路线图内容与当前项目状态的一致性

### 17. 2026-03-26 11:45:00

- 修改人：`GPT-5.4`
- 功能模块：`课表基础规则 / 节次与周次统一`
- 修改类型：`业务规则统一 / 数据模型收敛`
- 修改原因：
  - 项目中长期并存“11 节 / 12 节”和“20 周 / 24 周”两套规则，容易导致导入、展示、编辑和算法之间出现隐性不一致
  - 需要建立单一规则来源，减少后续开发和排错成本
- 修改内容：
  - 在 `SectionTimeConfig.kt` 中统一定义：
    - `DEFAULT_TOTAL_WEEKS = 20`
    - `MAX_TOTAL_WEEKS = 24`
    - `DEFAULT_SECTION_COUNT = 12`
  - 将默认节次时间表从 11 节统一扩展为 12 节
  - 对旧的 11 节本地配置做兼容：
    - 旧配置不会直接失效
    - 会自动补齐第 12 节默认时间
  - 收敛节次数规则：
    - `ScheduleGrid` 改为按 `sectionTimes.size` 渲染，不再写死 11 节
    - `GapFinderScreen` 改为按统一节次数渲染时间轴
    - `GapFinderUseCase` 改为依赖统一节次数和统一时间映射
    - `ScheduleImportViewModel` 导入课程时按统一节次数约束
    - `CourseEditViewModel` 新建/编辑课程时按统一节次数约束
  - 收敛周次数规则：
    - `CourseEditViewModel` 新增 `totalWeeks`
    - 课程编辑页的可选周次由用户当前学期周数动态生成，不再写死 20 周
    - `SettingsViewModel` 改为使用统一 `MAX_TOTAL_WEEKS`
    - `ScheduleViewModel`、`GapFinderViewModel`、`ImportUiState` 等默认周数改为统一来源
    - `UserProfileEntity`、`UserProfileRepository`、`AuthViewModel` 的默认总周数改为统一常量
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/domain/model/SectionTimeConfig.kt`
  - `app/src/main/java/com/heartbeat/schedule/domain/usecase/GapFinderUseCase.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/component/ScheduleGrid.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/gapfinder/GapFinderScreen.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/gapfinder/GapFinderViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/course/CourseEditViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/course/CourseEditScreen.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/settings/SettingsViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/importschedule/ScheduleImportViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/local/db/entity/UserProfileEntity.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/repository/UserProfileRepository.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/auth/AuthViewModel.kt`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`（基于 `C:\\hbapp` 串行执行）

### 18. 2026-03-26 12:10:00

- 修改人：`GPT-5.4`
- 功能模块：`互动页 / TA 当前状态判断`
- 修改类型：`业务规则统一 / 状态判断修正`
- 修改原因：
  - 互动页原本通过粗略小时段映射来推断“TA 当前状态”，没有真正使用用户的节次时间配置
  - 原逻辑也没有严格结合当前学周判断，容易出现“时间对了但本周没课也显示上课中”的误判
  - 在上一轮完成 11/12 节与 20/24 周规则统一后，需要把互动页也纳入同一套规则体系
- 修改内容：
  - 重写 `InteractiveViewModel` 中的 `observePartnerStatus()`
  - 当前状态判断改为同时依赖：
    - 当前星期
    - 当前学周
    - 用户自定义节次时间配置
  - 不再使用简单的“按小时硬编码映射节次”方案
  - 新增 `currentWeek` 与 `sectionTimes` 到 `InteractiveUiState`
  - 从 `UserPreferences` 中实时读取节次配置
  - 从当前用户档案中读取真实当前学周
  - 将 partner 课程在判断前统一做 `normalizeCoursesForDisplay()`
  - 仅当课程满足“同一天 + 当前学周 + 当前节次命中区间”时，才显示 `上课中`
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/interactive/InteractiveViewModel.kt`
  - `PROJECT_HISTORY.md`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:lintDebug`（基于 `C:\\hbapp` 串行执行）

### 19. 2026-03-26 12:35:00

- 修改人：`GPT-5.4`
- 功能模块：`情侣绑定闭环 / 远端邀请码与绑定同步`
- 修改类型：`功能增强 / 真实数据闭环`
- 修改原因：
  - 项目当前已经完成真实邮箱 OTP 登录，但情侣绑定仍停留在本地模拟阶段
  - 需要先把“邀请码生成 -> 输入邀请码绑定 -> 远端情侣关系建立 -> 本地缓存同步”这条主链路打通
  - 否则项目仍然无法从“单机版课表”进入真实双人协同阶段
- 修改内容：
  - 为 `SupabaseApi` 补充真实绑定所需接口：
    - 按 `user_a_id` / `user_b_id` 查询情侣关系
    - 删除情侣关系
    - 按 `creator_id` 查询可用邀请码
  - 为 `UserSessionProvider` 补充：
    - `requireAccessToken()`
    - `requireAuthHeader()`
  - 重写 `CoupleRepository`，实现第一版真实绑定闭环：
    - 邀请码优先从远端获取或复用
    - 不存在时在远端创建邀请码
    - 输入邀请码后在远端创建 `couples` 关系
    - 将邀请码标记为已使用
    - 将远端绑定结果同步到本地 `CoupleBindingDao`
    - 同步本地 `UserProfile.coupleId`
    - 同步 `DataStore` 中的 `couple_id`
    - 支持从远端刷新当前绑定状态
    - 支持解绑时删除远端情侣关系并清理本地缓存
  - 重写 `CoupleBindViewModel`：
    - 初始进入页面时先从远端刷新绑定状态
    - 邀请码展示改为真实远端邀请码
    - 绑定动作改为调用真实远端绑定逻辑
  - 将依赖绑定状态的页面接入远端刷新：
    - `ScheduleViewModel`
    - `GapFinderViewModel`
    - `SettingsViewModel`
    - `InteractiveViewModel`
  - 补充解绑后清理 `DataStore` 中 `couple_id` 的一致性处理
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/data/local/session/UserSessionProvider.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/local/datastore/UserPreferences.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/remote/api/SupabaseApi.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/repository/CoupleRepository.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/couple/CoupleBindViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/gapfinder/GapFinderViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/settings/SettingsViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/interactive/InteractiveViewModel.kt`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:lintDebug`（基于 `C:\\hbapp` 串行执行）

### 20. 2026-03-26 15:20:00

- 修改人：`GPT-5.4`
- 功能模块：`数据库文档 / 架构交接`
- 修改类型：`文档增强 / 交接补充`
- 修改原因：
  - 用户要求将整套数据库表结构用根目录文档完整讲清楚，方便后续人员快速了解项目框架
  - 原有数据库文档偏“设计草案”，还不够适合作为正式交接材料
- 修改内容：
  - 重写 `DATABASE_SCHEMA.md`
  - 明确说明：
    - 每一张表的职责
    - 表与表之间的关系
    - 每个字段的用途与含义
    - 为什么这样设计
    - 哪些表属于 MVP 必建，哪些属于后续扩展
  - 同步将 `DATABASE_SCHEMA.md` 加入 `README.md` 的推荐阅读顺序
- 影响文件：
  - `DATABASE_SCHEMA.md`
  - `README.md`
  - `PROJECT_HISTORY.md`
- 验证结果：
  - 已人工复核文档内容与当前项目架构设计的一致性

### 21. 2026-03-26 15:35:00

- 修改人：`GPT-5.4`
- 功能模块：`数据库落地脚本 / Supabase 初始化`
- 修改类型：`文档补充 / 基础设施脚本`
- 修改原因：
  - 用户已确认数据库结构设计，需要继续提供可直接在 Supabase SQL Editor 中执行的建表脚本
  - 后续如果没有统一建表脚本，其他接手者很难快速把远端数据库初始化到与项目一致的状态
- 修改内容：
  - 新增根目录脚本 `SUPABASE_DATABASE_SETUP.sql`
  - 脚本内容覆盖：
    - 核心业务表
    - 扩展表
    - 索引
    - `updated_at` 触发器
    - `auth.users -> profiles` 自动建档触发器
    - 基础 RLS 策略
  - 在 `README.md` 的推荐阅读顺序中加入 `SUPABASE_DATABASE_SETUP.sql`
- 影响文件：
  - `SUPABASE_DATABASE_SETUP.sql`
  - `README.md`
  - `PROJECT_HISTORY.md`
- 验证结果：
  - 已人工复核脚本与 `DATABASE_SCHEMA.md` 的设计一致性

### 22. 2026-03-26 15:45:00

- 修改人：`GPT-5.4`
- 功能模块：`Supabase 建表脚本`
- 修改类型：`脚本修复`
- 修改原因：
  - 用户在 Supabase SQL Editor 执行初始化脚本时报错：
    - `relation "public.couples" does not exist`
  - 根因是关系辅助函数 `is_couple_member()` 和 `is_partner_of_user()` 在 `public.couples` 表创建之前就被定义，导致 PostgreSQL 校验失败
- 修改内容：
  - 调整 `SUPABASE_DATABASE_SETUP.sql` 的执行顺序
  - 将依赖 `public.couples` 的辅助函数移动到核心表创建之后
  - 使脚本可以从头重新执行
- 影响文件：
  - `SUPABASE_DATABASE_SETUP.sql`
  - `PROJECT_HISTORY.md`
- 验证结果：
  - 已完成脚本级逻辑复核

### 23. 2026-03-26 16:05:00

- 修改人：`GPT-5.4`
- 功能模块：`情侣绑定代码 / 正式 schema 对齐`
- 修改类型：`兼容性修复 / 数据层对齐`
- 修改原因：
  - 用户已成功执行正式数据库 schema 脚本
  - 但当前 App 的情侣绑定代码仍依赖旧字段：
    - `invite_codes.used`
    - `couples.invite_code`
  - 如果直接打包测试，会因为代码和数据库字段不一致导致绑定失败
- 修改内容：
  - 将远端 DTO 对齐到正式 schema：
    - `InviteCodeDto` 新增 `id / used_by_id / couple_id / status / used_at`
    - `CoupleDto` 改为使用 `invite_code_id`
  - 将 `SupabaseApi` 对齐到正式表名与字段语义：
    - 业务用户远端接口改为 `profiles`
    - 补充 `getInviteCodeById()`
    - `getInviteCodesByCreator()` 改为按 `status = active` 查询
  - 扩展本地 `CoupleBindingEntity`：
    - 新增 `invite_code_id`
  - `Room` 数据库版本升级到 `4`
  - 新增 `MIGRATION_3_4`
  - 重写 `CoupleRepository`，使其绑定逻辑完全基于正式 schema：
    - 邀请码状态使用 `status`
    - 建立情侣关系时写入 `invite_code_id`
    - 更新邀请码时写入 `used_by_id / couple_id / used_at / status`
    - 本地缓存同步时通过 `invite_code_id` 反查邀请码文本
  - 同步修正 `updateAnniversary()` 对远端 couple 字段的写入方式
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/data/remote/model/InviteCodeDto.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/remote/model/CoupleDto.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/remote/api/SupabaseApi.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/local/db/entity/CoupleBindingEntity.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/local/db/HeartbeatDatabase.kt`
  - `app/src/main/java/com/heartbeat/schedule/di/DatabaseModule.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/repository/CoupleRepository.kt`
  - `PROJECT_HISTORY.md`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:lintDebug`（基于 `C:\\hbapp` 串行执行）

### 24. 2026-03-26 21:05:00

- 修改人：`GPT-5.4`
- 功能模块：`登录态管理 / Supabase 会话续期 / 情侣绑定调试`
- 修改类型：`Bug 修复 / 稳定性增强`
- 修改原因：
  - 用户在进入“情侣绑定”页面时遇到 `401`，而数据库表和 `profiles` 补档已经确认正常
  - 排查后发现当前项目虽然保存了 `refresh_token`，但远端业务请求没有做会话自动续期
  - 用户此前较早登录，晚上再进入绑定页时，`access_token` 已过期，导致首次访问 Supabase 业务表直接返回 `401`
- 修改内容：
  - 在 `SupabaseAuthApi` 中补充刷新会话接口：`POST auth/v1/token?grant_type=refresh_token`
  - 在 `AuthDto.kt` 中新增 `AuthRefreshTokenRequestDto`
  - 将 `AuthRepository` 调整为 `@Singleton`，并新增 `refreshSession()`，用于用 `refresh_token` 换取新的会话
  - 在 `UserPreferences` 中补充 `refreshToken` 流读取
  - 重写 `UserSessionProvider`：
    - 新增 JWT `exp` 解析
    - 新增“令牌即将过期”判断
    - 新增 `Mutex` 串行刷新，避免情侣绑定页初始化时两个并发请求同时刷新会话
    - 在刷新失败时清理本地登录态，统一提示重新登录
  - 重新打包 `debug APK`，并通过 `adb install -r` 安装到当前已连接设备
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/data/remote/model/AuthDto.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/remote/api/SupabaseAuthApi.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/repository/AuthRepository.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/local/datastore/UserPreferences.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/local/session/UserSessionProvider.kt`
  - `PROJECT_HISTORY.md`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:lintDebug`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:assembleDebug`（基于 `C:\\hbapp` 串行执行）
  - 已成功将新版 APK 安装到当前通过 `adb devices` 可见的设备 `126ea443`

### 25. 2026-03-26 21:25:00

- 修改人：`GPT-5.4`
- 功能模块：`情侣绑定页 / 已绑定状态进入体验`
- 修改类型：`交互优化 / 状态初始化修复`
- 修改原因：
  - 用户反馈：绑定成功后再次进入“情侣绑定”页，会先看到约 2 秒的未绑定页面，再切换到“你已经绑定过 TA”
  - 这种先展示错误状态、再异步纠正的体验很割裂，明显不符合绑定成功后的页面预期
- 修改内容：
  - 重写 `CoupleBindViewModel` 的初始化流程
  - 页面进入时优先读取本地 `CoupleBinding` 缓存
  - 如果本地已存在绑定记录，则首轮状态直接进入 `isAlreadyBound = true`
  - 在已命中本地绑定缓存时，不再先加载邀请码再等待远端返回
  - 远端 `refreshCurrentBinding()` 改为后台同步，负责校正，而不是阻塞首帧 UI
  - 新增 `isInitializing` 状态，避免初始化阶段重复触发绑定动作
  - 保留重新进入后的远端校正能力，以防用户在其他设备解绑后本机状态长期滞后
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/couple/CoupleBindViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/couple/CoupleBindScreen.kt`
  - `PROJECT_HISTORY.md`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:lintDebug`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:assembleDebug`（基于 `C:\\hbapp` 串行执行）

### 26. 2026-03-26 22:10:00

- 修改人：`GPT-5.4`
- 功能模块：`课表页 / 共同 Tab 重构 / 共同空闲与专属约会`
- 修改类型：`功能重构 / 视觉升级 / 交互增强`
- 修改原因：
  - 用户确认将“共同”Tab 从旧的“共同课表”重定义为“共同空闲主视图”
  - 目标是让共同页具备更强的情侣氛围感、视觉惊艳感和点击转化能力，而不是继续停留在死板的合并课表展示
  - 需要把“共同空闲 -> 点击 -> 设定专属约会 -> 网格切换为达成态”这条主链路真正做出来
- 修改内容：
  - 新增共同页核心状态模型：
    - `CommonScheduleBlock`
    - `CommonScheduleBlockState`
  - 新增 `BuildCommonScheduleBlocksUseCase`
    - 基于“我的课表 / TA 的课表 / 本地专属约会事件”生成共同页网格块
    - 支持状态：
      - 共同空闲
      - 我有课
      - TA有课
      - 都有课
      - 专属约会
  - 新增本地专属约会数据层：
    - `CoupleEventEntity`
    - `CoupleEventDao`
    - `CoupleEventRepository`
    - `CoupleEvent`
  - `Room` 数据库升级到 `version = 5`
  - 新增 `MIGRATION_4_5`，创建 `couple_events` 本地表
  - 新增共同页专用渲染组件：
    - `CommonScheduleGrid`
    - 使用独立玻璃拟态卡片渲染，不再复用旧 `ScheduleGrid`
  - `ScheduleViewModel` 重构：
    - 接入共同页 block 构建 usecase
    - 增加本地专属约会事件观察
    - 生成 `commonBlocksByWeek`
    - 新增创建专属约会方法
    - 新增共同页埋点入口
  - `ScheduleScreen` 重构：
    - `共同` Tab 改为渲染 `CommonScheduleGrid`
    - 引入氛围渐变背景
    - 点击共同空闲块可弹出底部约会编辑浮层
    - 输入标题后可将网格切换为“专属约会”状态
    - 增加共同 Tab 停留时长埋点
    - 调整空状态文案，使其符合“共同空闲主视图”的语义
  - 新增轻量埋点骨架：
    - `AnalyticsTracker`
    - 当前先以本地 `Log.d` 输出为主，后续可接正式埋点 SDK
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/domain/model/CommonScheduleBlock.kt`
  - `app/src/main/java/com/heartbeat/schedule/domain/model/CoupleEvent.kt`
  - `app/src/main/java/com/heartbeat/schedule/domain/usecase/BuildCommonScheduleBlocksUseCase.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/local/db/entity/CoupleEventEntity.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/local/db/dao/CoupleEventDao.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/repository/CoupleEventRepository.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/analytics/AnalyticsTracker.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/local/db/HeartbeatDatabase.kt`
  - `app/src/main/java/com/heartbeat/schedule/di/DatabaseModule.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/component/CommonScheduleGrid.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleScreen.kt`
  - `PROJECT_HISTORY.md`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:lintDebug`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:assembleDebug`（基于 `C:\\hbapp` 串行执行）

### 27. 2026-03-26 22:35:00

- 修改人：`GPT-5.4`
- 功能模块：`共同页性能优化 / 周切换跟手体验`
- 修改类型：`性能优化 / 交互修正`
- 修改原因：
  - 用户反馈共同页切换周数时不够跟手
  - 共同页第一版视觉实现里仍包含较重的渲染开销：
    - 整体页面模糊
    - 卡片阴影
    - 弹窗与输入框的额外光影
    - `displayedWeek` 变化时为全部周数预构建共同块
  - 在情侣产品中视觉很重要，但这次优先级需要切回“最好的性能 + 仍然好看”
- 修改内容：
  - 将课表页周切换改回 `HorizontalPager` 原生手势滑动
  - 移除自定义“松手后再触发翻页”的手势逻辑，使周切换重新具备跟手拖拽体验
  - 删除共同页打开约会弹窗时对整页内容施加的 `blur`
  - 简化共同页视觉层：
    - 去除共同块 `shadow`
    - 去除毛玻璃风格的半透明重叠底板
    - 将单方忙碌块改为更轻量的纯色浅卡片
    - 将双方忙碌块改为低存在感纯色块
    - 保留适度的高光粉色主块，以兼顾美观性
  - 简化约会弹窗：
    - 去掉弹窗容器大阴影
    - 去掉输入框聚焦阴影
    - 改为更轻的白底 + 边框方案
  - 优化共同块构建逻辑：
    - 不再为全部周数一次性生成共同块
    - 改为只缓存“上一周 / 当前周 / 下一周”三页，降低周切换时的数据构建压力
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleScreen.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/component/CommonScheduleGrid.kt`
  - `PROJECT_HISTORY.md`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:lintDebug`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:assembleDebug`（基于 `C:\\hbapp` 串行执行）

### 28. 2026-03-26 22:55:00

- 修改人：`GPT-5.4`
- 功能模块：`共同页渲染架构 / Canvas 性能重构`
- 修改类型：`渲染重构 / 性能优化`
- 修改原因：
  - 用户继续反馈共同页切周“还是不跟手”
  - 分析后确认共同页即使已经去掉部分重视觉效果，仍然属于“Pager 内大量 Compose 节点渲染”的方案
  - 对于当前这种周视图高频滑动场景，更稳的方案是与原课表页保持一致，改为单 Canvas 渲染
- 修改内容：
  - 将 `CommonScheduleGrid` 从多节点 Compose 卡片方案重写为单 `Canvas` 渲染
  - 在一个 Canvas 中完成：
    - 顶部星期与日期绘制
    - 左侧节次与时间绘制
    - 网格线绘制
    - 共同空闲 / 单方有课 / 双方忙碌 / 专属约会四类块绘制
    - 块内标题、副标题与图标文本绘制
  - 使用 `detectTapGestures` 做轻量点击映射：
    - 共同空闲块点击
    - 专属约会块点击
  - 保留原有共同页业务语义与状态模型，不改变功能，只更换渲染实现
  - 共同页由此与原 `ScheduleGrid` 保持同类性能取向，降低周切换时的拖拽阻力
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/ui/component/CommonScheduleGrid.kt`
  - `PROJECT_HISTORY.md`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:lintDebug`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:assembleDebug`（基于 `C:\\hbapp` 串行执行）

### 29. 2026-03-26 23:20:00

- 修改人：`GPT-5.4`
- 功能模块：`路线图复盘 / 共同页性能体检 / 优先级重排`
- 修改类型：`文档重构 / 项目审计`
- 修改原因：
  - 用户要求重新检查项目当前状态，明确共同页还有哪些值得继续优化，哪些已经没必要再动
  - 现有 `TODO_ROADMAP.md` 中仍包含大量过时结论，例如：
    - 情侣绑定仍是本地模拟
    - 共同页仍被视作旧的共同课表
    - 多个优先级条目已与当前真实实现不一致
  - 需要把“已完成 / 未完成 / 下一步优先级”重新梳理为一版真实可执行的路线图
- 修改内容：
  - 重写 `TODO_ROADMAP.md`
  - 新增并明确：
    - 当前阶段判断
    - 已完成的关键事项
    - 当前问题清单（P0 / P1 / P2）
    - 共同页性能体检结论
    - 当前真正值得继续优化的点
    - 当前不值得继续抠的点
    - 最新需求清单
    - 最新 Phase 路线图
    - 最新 Top 10 优先事项
    - 当前推荐优先级
  - 路线图重点改为：
    - 先做远端课表同步
    - 再做远端专属约会同步
    - 再做共享待办 / 纪念日 / 互动闭环
    - 最后收敛安全与测试
- 影响文件：
  - `TODO_ROADMAP.md`
  - `PROJECT_HISTORY.md`
- 验证结果：
  - 已人工复核新路线图与当前代码、数据库和共同页重构状态的一致性

### 30. 2026-03-26 23:40:00

- 修改人：`GPT-5.4`
- 功能模块：`远端课表同步第一版 / 路线图对齐`
- 修改类型：`功能增强 / 文档更新`
- 修改原因：
  - 用户确认开始做“远端课表同步第一版”
  - 项目此前虽然已有 `courses` 表和 Supabase API 定义，但课表实际仍主要停留在本地 Room，未形成真实账号级数据闭环
  - 同时现有路线图仍把“远端课表同步未做”写成旧状态，需要同步更新为“第一版已接入”
- 修改内容：
  - 对齐远端 `courses` 字段映射：
    - `CourseDto.userId` 改为绑定 `owner_id`
  - 扩展 `SupabaseApi`：
    - 新增 `upsertCourse`
    - 新增 `deleteCoursesByOwner`
  - 扩展 `CourseDao`：
    - 新增 `getCoursesByUserSync`
  - 重写 `CourseRepository`，接入远端课表同步第一版：
    - 登录后可拉取我的远端课表
    - 远端为空、本地有历史课表时，会自动把本地课表首轮上推到远端
    - 保存课程时同步远端
    - 删除课程时同步远端
    - 导入课表时执行远端整体替换
    - 绑定后可拉取 TA 的远端课表
    - 绑定后会为当前用户远端课程补齐 `couple_id`
  - 调整 `CourseEditViewModel`：
    - 保存 / 删除课程时加入同步失败错误提示
  - 调整 `ScheduleImportViewModel`：
    - 导入完成后不再只写本地，改为通过 `CourseRepository.replaceMyCourses()` 同步远端
  - 调整 `ScheduleViewModel` 与 `ScheduleScreen`：
    - `ScheduleScreen` 在 `onResume` 时主动刷新远端课表
    - `ScheduleViewModel` 增加 `refreshRemoteCourses()`
  - 重写 `TODO_ROADMAP.md`
    - 将远端课表同步状态改为“第一版已接入，但仍需稳定化和双端一致性补齐”
    - 同步重排后续优先级
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/data/remote/model/CourseDto.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/remote/api/SupabaseApi.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/local/db/dao/CourseDao.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/repository/CourseRepository.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/course/CourseEditViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/importschedule/ScheduleImportViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleScreen.kt`
  - `TODO_ROADMAP.md`
  - `PROJECT_HISTORY.md`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:lintDebug`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:assembleDebug`（基于 `C:\\hbapp` 串行执行）
  - 已覆盖桌面安装包 `心动课表-v1.0.0-debug.apk`
  - 本轮结束时 `adb` 未检测到设备，因此未执行自动安装到手机

### 31. 2026-03-27 00:10:00

- 修改人：`GPT-5.4`
- 功能模块：`课表页体验 / 远端同步刷新抖动修复`
- 修改类型：`体验修复 / 数据同步优化`
- 修改原因：
  - 用户反馈课表页会偶尔出现“一瞬间的刷新”，影响体验
  - 排查后确认原因主要有两类：
    - 远端同步时，先 `deleteAllByUser()` 再 `upsertAll()`，会让 Room Flow 短暂发出空列表
    - 课表页在 `onResume` 时会频繁主动触发远端刷新，即使数据没有变化也会打到本地层
- 修改内容：
  - 在 `CourseDao` 中新增事务方法 `replaceCoursesByUser()`
    - 将“删旧课 + 写新课”放入一个事务中
    - 避免课表流中间短暂变空导致 UI 闪一下
  - 在 `CourseRepository` 中优化同步逻辑：
    - 本地课表与远端课表一致时，直接跳过本地重写
    - 只在数据真实变化时才替换本地课程
    - `replaceMyCourses()` 改为使用事务替换
    - `syncCoursesForUserFromRemote()` 也改为事务替换
  - 在 `ScheduleViewModel` 中为 `refreshRemoteCourses()` 增加节流
    - 避免短时间内多次 `onResume` 重复刷新
    - 降低远端同步对前台体验的打扰
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/data/local/db/dao/CourseDao.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/repository/CourseRepository.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleViewModel.kt`
  - `PROJECT_HISTORY.md`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:lintDebug`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:assembleDebug`（基于 `C:\\hbapp` 串行执行）
  - 已重新安装到当前连接手机

### 32. 2026-03-27 00:40:00

- 修改人：`GPT-5.4`
- 功能模块：`课表同步策略重构 / 启动级静默对账`
- 修改类型：`同步策略升级 / 体验优化`
- 修改原因：
  - 用户明确提出：课表同步不应在本次运行中持续打扰用户
  - 现有实现仍然带有页面驱动的同步痕迹，容易在课表页造成轻微刷新感
  - 目标是调整为：
    - 只在应用打开后静默对账一次
    - 本次运行不持续实时检测
    - 本地与远端相同则不改动
    - 本地与远端不同则按课程 `updated_at` 逐条决定谁覆盖谁
- 修改内容：
  - 新增 `AppLaunchSyncCoordinator`
    - 负责应用启动后的一次性静默同步
    - 按 `userId + coupleId` 做会话级去重
    - 同步当前用户课表与 TA 课表
  - `MainActivity` 中增加启动级同步入口：
    - 登录后根据 `userId / coupleId` 触发一次静默对账
    - 退出登录时重置同步状态
  - `ScheduleScreen` 移除 `onResume` 课表强刷
  - `ScheduleViewModel` 移除页面驱动远端刷新逻辑
  - `CourseRepository` 重构远端同步策略：
    - 启动时按课程 `id + updated_at` 做逐条合并
    - 本地和远端一致时跳过本地重写
    - 本地仅存在且 `isSynced = true` 时，默认认为是远端已删除，不再复活
    - 本地仅存在且 `isSynced = false` 时，作为本地新改动上推远端
    - 继续保留导入时整体替换远端的逻辑
  - 补充 `CourseEntity -> CourseDto` 映射，用于启动级静默回推
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/data/repository/AppLaunchSyncCoordinator.kt`
  - `app/src/main/java/com/heartbeat/schedule/MainActivity.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/repository/CourseRepository.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleScreen.kt`
  - `PROJECT_HISTORY.md`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:lintDebug`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:assembleDebug`（基于 `C:\\hbapp` 串行执行）
  - 本轮结束时 `adb` 未检测到设备，因此未执行自动安装到手机

### 33. 2026-03-27 01:10:00

- 修改人：`GPT-5.4`
- 功能模块：`重装后课表恢复 / 共同页空状态修复`
- 修改类型：`Bug 修复 / 数据展示修正`
- 修改原因：
  - 用户反馈：卸载重装并重新登录后，“我的”课表未显示从数据库拉下来的课程
  - 同时“共同”页在提示“先导入你的课程”时，后方仍显示旧的共同空闲块，造成数据观感混乱
  - 进一步核查后确认：
    - 当前登录账号 `599536561@qq.com` 的远端 `courses` 实际为 0 条，因此“我的课表为空”并不是同步失败
    - 共同页确实存在渲染 bug：即使当前用户无课表，也会继续使用 TA 的课程参与共同块计算与绘制
- 修改内容：
  - 修正 `ScheduleViewModel.rebuildCommonBlocks()`：
    - 只有在“已绑定 + 我有课表 + TA 有课表”时，才生成共同页网格块
    - 否则直接清空 `commonBlocksByWeek`
  - 修正 `ScheduleScreen`：
    - 当 `uiState.canRenderCommonSchedule == false` 时，不再渲染 `CommonScheduleGrid`
    - 只显示空状态卡片，避免出现“空状态弹窗 + 旧块背景”叠加的错误体验
  - 保留空状态文案逻辑：
    - 未绑定：先绑定 TA
    - 我无课表：先导入你的课表
    - TA 无课表：等 TA 导入课表
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleScreen.kt`
  - `PROJECT_HISTORY.md`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:lintDebug`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:assembleDebug`（基于 `C:\\hbapp` 串行执行）
  - 已重新安装到当前连接手机

### 34. 2026-03-27 01:35:00

- 修改人：`GPT-5.4`
- 功能模块：`远端 couple_events 第一版 / 共同页双端一致性起步`
- 修改类型：`功能增强 / 远端同步接入 / 文档对齐`
- 修改原因：
  - 当前“共同空闲 -> 专属约会”只在本地成立，无法在两台手机上保持一致
  - 需要把专属约会正式纳入 Supabase 数据层，形成双端共享的基础
- 修改内容：
  - 新增远端模型：
    - `CoupleEventDto`
  - 扩展 `SupabaseApi`：
    - `getCoupleEvents`
    - `upsertCoupleEvent`
    - `deleteCoupleEvent`
  - 升级 `CoupleEventDao`：
    - 新增同步查询
    - 新增批量写入
    - 新增按情侣整体替换
  - 重写 `CoupleEventRepository`：
    - 创建约会时写远端并回写本地
    - 支持按情侣从远端拉取并替换本地缓存
    - 支持远端删除接口
  - 升级 `AppLaunchSyncCoordinator`：
    - 启动静默同步时一并同步 `couple_events`
  - 更新 `SUPABASE_DATABASE_SETUP.sql`
    - 新增 `public.couple_events`
    - 新增索引
    - 新增 `updated_at` trigger
    - 新增 RLS 策略
  - 更新 `DATABASE_SCHEMA.md`
    - 将 `couple_events` 纳入正式核心表结构说明
  - 更新 `TODO_ROADMAP.md`
    - 将 `couple_events` 状态改为“第一版代码链已接入，等待 SQL 落地与双端验证”
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/data/remote/model/CoupleEventDto.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/remote/api/SupabaseApi.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/local/db/dao/CoupleEventDao.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/repository/CoupleEventRepository.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/repository/AppLaunchSyncCoordinator.kt`
  - `SUPABASE_DATABASE_SETUP.sql`
  - `DATABASE_SCHEMA.md`
  - `TODO_ROADMAP.md`
  - `PROJECT_HISTORY.md`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:lintDebug`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:assembleDebug`（基于 `C:\\hbapp` 串行执行）
  - 已重新安装到当前连接手机

### 35. 2026-03-27 02:05:00

- 修改人：`GPT-5.4`
- 功能模块：`profiles 远端同步 / 共同页跨账号周次一致性`
- 修改类型：`功能增强 / 跨设备一致性修复`
- 修改原因：
  - 用户在另一邮箱账号登录后，能看到双方课表，但看不到刚创建的远端约会
  - 排查后确认：
    - 远端 `couple_events` 已正常写入
    - 该约会属于第 3 周
    - 但另一账号的 `profiles` 中 `semester_start_date / current_week_offset / couple_id` 等关键资料未同步，导致重装或切账号后当前显示周与约会所在周不一致
  - 因此需要补上 `profiles` 远端同步，保证跨账号 / 重装后学期设置和情侣关系不会乱
- 修改内容：
  - 修正 `UserDto`，与正式 `profiles` schema 对齐：
    - `email`
    - `couple_id`
    - `current_week_offset`
    - `total_weeks`
    - `semester_start_date`
  - 重写 `UserProfileRepository`
    - 本地 `saveProfile()` 后尝试推远端
    - `updateCoupleId()` 后推远端
    - `setManualCurrentWeek()` / `resetCurrentWeekToAutomatic()` 后推远端
    - 新增 `syncCurrentProfileOnLaunch()`
      - 启动时先拉远端 `profiles`
      - 合并到本地 `user_profile`
      - 如远端缺字段，则把本地值补回远端
  - 调整 `AppLaunchSyncCoordinator`
    - 启动静默同步顺序变为：
      1. 刷新绑定
      2. 同步 profile
      3. 同步课表
      4. 同步 couple_events
  - 这样切账号 / 重装后，当前周和情侣关系会先恢复，再参与共同页计算
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/data/remote/model/UserDto.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/repository/UserProfileRepository.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/repository/AppLaunchSyncCoordinator.kt`
  - `PROJECT_HISTORY.md`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:lintDebug`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:assembleDebug`（基于 `C:\\hbapp` 串行执行）
  - 已重新安装到当前连接手机

### 36. 2026-03-27 02:25:00

- 修改人：`GPT-5.4`
- 功能模块：`专属约会查看 / 编辑 / 删除`
- 修改类型：`功能增强 / 交互完善`
- 修改原因：
  - 当前共同页里的专属约会虽然已经支持创建和双端同步，但还缺少后续维护能力
  - 若不能查看、编辑、删除，`couple_events` 仍只是“单向创建”能力，不足以长期使用
- 修改内容：
  - 为共同页底部面板增加双模式：
    - 创建模式
    - 编辑模式
  - 点击 `COUPLE_EVENT` 状态块时：
    - 自动读取对应事件
    - 打开编辑面板
    - 预填当前标题
  - `ScheduleViewModel` 新增：
    - `updateCoupleEvent()`
    - `deleteCoupleEvent()`
  - 复用 `CoupleEventRepository.saveEvent()` 的 upsert 能力实现远端编辑
  - 复用 `CoupleEventRepository.deleteEvent()` 实现远端删除
  - 面板按钮逻辑改为：
    - 新建时：取消 / 设定专属约会
    - 编辑时：删除 / 保存修改
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleScreen.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleViewModel.kt`
  - `PROJECT_HISTORY.md`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:lintDebug`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:assembleDebug`（基于 `C:\\hbapp` 串行执行）
  - 已重新安装到当前连接手机

### 37. 2026-03-27 02:50:00

- 修改人：`GPT-5.4`
- 功能模块：`专属约会编辑保存崩溃修复`
- 修改类型：`Bug 修复 / 错误处理增强`
- 修改原因：
  - 用户反馈：编辑约会标题后点击“保存修改”，应用直接闪退
  - 通过 `adb logcat` 确认闪退原因为：
    - `retrofit2.HttpException: HTTP 403`
  - 根因是编辑约会时仍复用“创建/upsert”接口
    - 当另一方账号编辑由对方创建的事件时，命中了 `insert policy`
    - 因 `created_by != auth.uid()` 被 RLS 拒绝
  - 同时 ViewModel 未对异常进行兜底，导致主线程崩溃
- 修改内容：
  - 在 `SupabaseApi` 中新增 `PATCH couple_events` 接口：
    - `updateCoupleEvent()`
  - 在 `CoupleEventRepository` 中新增：
    - `updateEvent()`
    - 编辑时只更新 `title / updated_at`
    - 不再走创建用的 upsert 接口
  - 在 `ScheduleViewModel` 中：
    - `updateCoupleEvent()` 改为调用 repository 的 `updateEvent()`
    - `createCoupleEvent()` / `updateCoupleEvent()` / `deleteCoupleEvent()` 全部增加 `runCatching`
    - 失败时写入 `errorMessage`，不再崩溃
    - 新增 `clearError()`
  - 在 `ScheduleScreen` 中：
    - 接入 `HeartbeatMessageBanner`
    - 共同页保存/删除失败时显示上方错误提示
    - 2.5 秒后自动清除
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/data/remote/api/SupabaseApi.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/repository/CoupleEventRepository.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleScreen.kt`
  - `PROJECT_HISTORY.md`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:lintDebug`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:assembleDebug`（基于 `C:\\hbapp` 串行执行）
  - 已重新安装到当前连接手机

### 38. 2026-03-27 03:05:00

- 修改人：`GPT-5.4`
- 功能模块：`专属约会标题锁定 / 对方回复 / 轻量聊天式详情弹窗`
- 修改类型：`业务逻辑重构 / 交互重构 / schema 扩展`
- 修改原因：
  - 用户最新需求明确要求：
    - 约会标题创建后双方都不能再修改
    - 创建者本人不能回复
    - 只能由对方在标题下进行回复
    - 约会详情应采用半屏、年轻活泼、轻量聊天式弹窗
  - 当前实现仍保留“编辑标题 / 删除约会”的旧逻辑，不再符合产品方向
- 修改内容：
  - 扩展 `CoupleEvent` 数据模型：
    - `replyContent`
    - `repliedBy`
    - `repliedAt`
  - 扩展本地 `CoupleEventEntity`
  - 扩展远端 `CoupleEventDto`
  - `Room` 数据库升级到 `version = 7`
  - 新增 `MIGRATION_6_7`
    - 为本地 `couple_events` 增加回复相关字段
  - `CoupleEventRepository` 新增：
    - `replyToEvent()`
    - 回复时走远端 `PATCH couple_events`
  - `ScheduleViewModel` 新增：
    - `currentUserId` 写入 `ScheduleUiState`
    - `replyToCoupleEvent()`
    - 规则限制：
      - 发起人不能回复自己的约会
      - 一条约会默认只允许一条回复
  - `ScheduleScreen` 重构共同页底部面板：
    - 不再沿用旧的“编辑标题表单”
    - 改为双模式：
      - 创建模式：输入标题创建约会
      - 详情模式：半屏详情弹窗
    - 详情模式展示：
      - 发起标题气泡
      - 已回复时的回复气泡
      - 发起人等待提示
      - 对方回复输入框与发送按钮
  - `SUPABASE_DATABASE_SETUP.sql` 更新：
    - 远端 `public.couple_events` 补充回复字段
  - `DATABASE_SCHEMA.md` 更新：
    - 补充回复字段说明
  - `TODO_ROADMAP.md` 更新：
    - 将“编辑标题”方向修正为“标题锁定 + 回复”
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/domain/model/CoupleEvent.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/local/db/entity/CoupleEventEntity.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/remote/model/CoupleEventDto.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/local/db/HeartbeatDatabase.kt`
  - `app/src/main/java/com/heartbeat/schedule/di/DatabaseModule.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/repository/CoupleEventRepository.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleScreen.kt`
  - `SUPABASE_DATABASE_SETUP.sql`
  - `DATABASE_SCHEMA.md`
  - `TODO_ROADMAP.md`
  - `PROJECT_HISTORY.md`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:lintDebug`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:assembleDebug`（基于 `C:\\hbapp` 串行执行）
  - 本轮结束时 `adb` 未检测到设备，因此未执行自动安装到手机

### 39. 2026-03-27 03:35:00

- 修改人：`GPT-5.4`
- 功能模块：`标题锁定 + 对方回复 / 聊天式约会详情`
- 修改类型：`业务重构 / UI 交互重构`
- 修改原因：
  - 用户明确要求改变专属约会逻辑：
    - 标题创建后双方都不能再修改
    - 创建者自己不能回复
    - 只允许对方回复
    - 约会详情采用占据半屏的、类似主流聊天软件的轻量聊天式弹窗
  - 旧的“编辑标题 / 删除”模式已不再符合产品设计方向
- 修改内容：
  - 扩展约会数据模型：
    - `replyContent`
    - `repliedBy`
    - `repliedAt`
  - 扩展本地实体与远端 DTO：
    - `CoupleEventEntity`
    - `CoupleEventDto`
  - `Room` 数据库升级到 `version = 7`
  - 新增 `MIGRATION_6_7`
    - 为本地 `couple_events` 增加回复字段
  - `CoupleEventRepository` 新增：
    - `replyToEvent()`
    - 回复走远端 `PATCH couple_events`
  - `ScheduleViewModel` 新增：
    - `currentUserId`
    - `replyToCoupleEvent()`
    - 规则限制：
      - 发起人不能回复自己的约会
      - 默认只允许一条回复
  - `ScheduleScreen` 详情弹窗重构：
    - 不再是“编辑标题”表单
    - 改为双模式：
      - 创建模式：输入标题发起约会
      - 详情模式：轻量聊天式半屏面板
    - 详情模式展示：
      - 发起标题消息
      - 回复消息
      - 每条消息带时间
      - 左右对齐按当前用户视角区分
      - 创建者看到“等待 TA 回复”
      - 对方看到回复输入框
  - 更新数据库脚本和文档：
    - `SUPABASE_DATABASE_SETUP.sql`
    - `DATABASE_SCHEMA.md`
    - `TODO_ROADMAP.md`
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/domain/model/CoupleEvent.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/local/db/entity/CoupleEventEntity.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/remote/model/CoupleEventDto.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/local/db/HeartbeatDatabase.kt`
  - `app/src/main/java/com/heartbeat/schedule/di/DatabaseModule.kt`
  - `app/src/main/java/com/heartbeat/schedule/data/repository/CoupleEventRepository.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleScreen.kt`
  - `SUPABASE_DATABASE_SETUP.sql`
  - `DATABASE_SCHEMA.md`
  - `TODO_ROADMAP.md`
  - `PROJECT_HISTORY.md`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:lintDebug`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:assembleDebug`（基于 `C:\\hbapp` 串行执行）
  - 已覆盖桌面安装包 `心动课表-v1.0.0-debug.apk`

### 40. 2026-03-27 03:55:00

- 修改人：`GPT-5.4`
- 功能模块：`约会详情消息流视角修正`
- 修改类型：`交互修正 / 视觉逻辑修正`
- 修改原因：
  - 用户反馈当前约会详情存在两个明显问题：
    - 两个账号看到的上下顺序不够直观
    - 左右气泡有时与“自己永远右、对方永远左”的直觉不一致
  - 根因不是单点条件判断写错，而是详情面板仍然以“标题块 + 回复块”固定结构思维在渲染，而不是以统一的消息流模型渲染
- 修改内容：
  - 在 `ScheduleScreen` 中新增 `EventChatMessage`
  - 将约会详情统一转换为消息流：
    - 消息 1：标题消息
    - 消息 2：回复消息（若存在）
  - 统一排序规则：
    - 按 `timestamp` 升序
    - 若时间相同，标题消息永远排在前
  - 统一左右规则：
    - `senderId == currentUserId` 的消息永远在右侧
    - 其它消息永远在左侧
  - `ChatBubble` 组件升级：
    - 显示发送者标签（我 / TA）
    - 显示消息时间
    - 保持轻量聊天式布局
  - 时间格式优化：
    - 当天消息只显示 `HH:mm`
    - 非当天显示 `MM-dd HH:mm`
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleScreen.kt`
  - `PROJECT_HISTORY.md`
- 验证结果：
  - 已成功执行 `:app:compileDebugKotlin`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:lintDebug`（基于 `C:\\hbapp` 串行执行）
  - 已成功执行 `:app:assembleDebug`（基于 `C:\\hbapp` 串行执行）
  - 已覆盖桌面安装包 `心动课表-v1.0.0-debug.apk`

### 41. 2026-03-27 22:24:23

- 修改人：`GPT-5.4`
- 功能模块：`TODO_ROADMAP 真实状态校准 / 文档记录机制补充`
- 修改类型：`文档修正 / 进度对齐`
- 修改原因：
  - 当前根目录 `TODO_ROADMAP.md` 仍残留多条过时结论，例如：
    - 仍写着 `public.couple_events` 未落地
    - 仍写着专属约会查看 / 编辑 / 删除未完成
    - 仍把纪念日和共享待办都笼统归类为“未远端闭环”
  - 若继续按旧路线图推进，会误导后续开发判断真实优先级
  - 同时需要把这次文档对齐本身记录下来，避免后续中断时无人知道最近一次状态校准结论
- 修改内容：
  - 重写 `TODO_ROADMAP.md` 中以下部分，使其贴近当前真实状态：
    - 当前阶段判断
    - 已完成关键事项中的 `couple_events` 状态
    - 当前问题清单 `P0 / P1 / P2`
    - 共同页性能建议
    - 功能补充清单中的专属约会 / 互动能力项
    - 重要需求、路线图、Top 10 任务与推荐优先级
  - 明确写出当前真实结论：
    - 专属约会已经不是“未做”，而是已完成“标题锁定 + 对方单次回复 + 聊天式详情”
    - `public.couple_events` 已不应再作为“未创建”问题继续表述
    - 共享待办仍是本地闭环，快捷提醒仍是假发送
    - 中文路径构建目前可通过，但仍依赖 `android.overridePathCheck=true`
  - 将这次修订追加记录到 `PROJECT_HISTORY.md`
- 影响文件：
  - `TODO_ROADMAP.md`
  - `PROJECT_HISTORY.md`
- 验证结果：
  - 基于当前代码、文档与实时核查结果完成对齐
  - 本次修改为文档修正，未新增业务代码
  - 本次修正已补入 `PROJECT_HISTORY.md`，供后续开发接力

### 42. 2026-03-27 22:44:11

- 修改人：`GPT-5.4`
- 功能模块：`专属约会详情回复链路修复`
- 修改类型：`Bug 修复 / 交互修正`
- 修改原因：
  - 用户反馈当前“约会详情”里已经无法稳定回复
  - 排查后确认当前共同页详情面板存在两个隐患：
    - 面板状态里保存的是旧的 `CoupleEvent` 快照，详情不会自动跟随最新事件数据刷新
    - 点击“回复”后会立刻关闭详情面板，即使远端失败，用户也会感知成“没反应 / 没法回复”
- 修改内容：
  - 将 `CommonEventSheetState.Detail` 从保存整条 `event` 改为只保存 `eventId`
  - 详情面板渲染时改为始终从最新 `uiState.coupleEvents` 中查当前事件，避免使用过期快照
  - 回复按钮点击后不再立即关闭详情面板
    - 回复成功时，面板可直接看到最新回复结果
    - 回复失败时，保留输入内容并继续显示错误提示
  - 当详情对应事件已不存在或已变化到无法直接渲染时，显示“约会详情已更新”的兜底提示，避免空白或旧数据
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleScreen.kt`
  - `PROJECT_HISTORY.md`
- 验证结果：
  - 已完成代码修复
  - 已成功执行 `:app:compileDebugKotlin`

### 43. 2026-03-27 22:44:11

- 修改人：`GPT-5.4`
- 功能模块：`专属约会回复入口可见性修复`
- 修改类型：`Bug 修复 / 状态同步增强`
- 修改原因：
  - 用户安装验证后反馈：约会详情里没有回复入口按钮
  - 排查判断当前 UI 的回复入口依赖 `uiState.currentUserId`
  - 原实现中该字段主要通过课表/资料联动流间接更新，存在时序窗口，可能导致详情页把“可回复”误判为“不可回复”
- 修改内容：
  - 在 `ScheduleViewModel` 中新增对 `userPreferences.userId` 的直接监听
    - 登录态里的 `userId` 会更早写入 `ScheduleUiState.currentUserId`
    - 不再只依赖资料流侧向带出当前用户身份
  - 在 `ScheduleScreen` 详情面板中新增不可回复原因文案
    - 当前账号信息未同步
    - 已经收到回复
    - 当前用户就是发起人
  - 避免详情页在没有回复按钮时只显示“知道了”，降低误判成本
- 影响文件：
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleViewModel.kt`
  - `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleScreen.kt`
  - `PROJECT_HISTORY.md`
- 验证结果：
  - 已完成代码修复
  - 已成功执行 `:app:compileDebugKotlin`

### 44. 2026-03-27 23:16:25

- 修改人：`GPT-5.4`
- 功能模块：`专属约会回复规则真机核查记录`
- 修改类型：`文档补充 / 规则确认`
- 修改原因：
  - 用户安装到真机后反馈“约会详情没有回复入口按钮”
  - 需要区分这是代码缺陷，还是命中了当前产品规则，避免后续开发人员重复误判
- 修改内容：
  - 通过真机 `adb logcat` 与远端返回数据核查确认：
    - 当前登录用户就是该条约会的 `created_by`
    - 该条约会已经存在 `reply_content`
  - 因此当前详情页不显示回复入口，属于命中既有业务规则，不是新的 UI 渲染故障
  - 规则结论补充为：
    - 发起人不能回复自己的约会
    - 同一条约会默认只允许一条回复
    - 命中上述条件时，详情页不显示回复入口
  - 将这条规则同步补充到 `TODO_ROADMAP.md`
- 影响文件：
  - `TODO_ROADMAP.md`
  - `PROJECT_HISTORY.md`
- 验证结果：
  - 已通过真机 `adb` 日志与远端 `couple_events` 返回结果完成核查
  - 结论为“当前现象符合既有规则，不是新 bug”

## 最近修改涉及的主要文件

- `app/build.gradle.kts`
- `app/src/main/java/com/heartbeat/schedule/ui/component/HeartbeatSnackbar.kt`
- `app/src/main/java/com/heartbeat/schedule/di/NetworkModule.kt`
- `app/src/main/java/com/heartbeat/schedule/data/local/datastore/UserPreferences.kt`
- `app/src/main/java/com/heartbeat/schedule/data/local/session/UserSessionProvider.kt`
- `app/src/main/java/com/heartbeat/schedule/data/repository/AuthRepository.kt`
- `app/src/main/java/com/heartbeat/schedule/data/repository/UserProfileRepository.kt`
- `app/src/main/java/com/heartbeat/schedule/data/remote/api/SupabaseAuthApi.kt`
- `app/src/main/java/com/heartbeat/schedule/data/remote/model/AuthDto.kt`
- `app/src/main/java/com/heartbeat/schedule/domain/util/WeekUtil.kt`
- `app/src/main/java/com/heartbeat/schedule/ui/screen/auth/AuthViewModel.kt`
- `app/src/main/java/com/heartbeat/schedule/ui/screen/auth/LoginScreen.kt`
- `app/src/main/java/com/heartbeat/schedule/ui/screen/auth/RegisterScreen.kt`
- `app/src/main/java/com/heartbeat/schedule/ui/screen/course/CourseEditScreen.kt`
- `app/src/main/java/com/heartbeat/schedule/ui/screen/importschedule/ScheduleImportViewModel.kt`
- `app/src/main/java/com/heartbeat/schedule/ui/screen/schedule/ScheduleScreen.kt`
- `app/src/main/java/com/heartbeat/schedule/ui/component/ScheduleGrid.kt`
- `app/src/main/java/com/heartbeat/schedule/ui/screen/settings/SettingsViewModel.kt`
- `app/src/main/java/com/heartbeat/schedule/ui/screen/settings/SettingsScreen.kt`
- `README.md`
- `ARCHITECTURE.md`
- `TODO_ROADMAP.md`
- `PROJECT_HISTORY.md`
- `.gitignore`

## 推荐的后续维护方式

建议每次修改都按下面格式追加一条记录：

```md
### YYYY-MM-DD HH:mm:ss

- 修改人：
- 功能模块：
- 修改类型：
- 修改原因：
- 修改内容：
- 影响文件：
- 验证结果：
```

建议优先记录这些类型的变更：

- 业务规则变化
- 课表日期/周次相关计算变化
- UI 重构或明显视觉调整
- 打包、签名、发布流程变化
- 影响导入、绑定、登录、设置等主流程的修复

## 备注

- 当前桌面安装包文件名为：`心动课表-v1.0.0-debug.apk`
- 当前项目已经补齐：
  - `README.md`
  - `ARCHITECTURE.md`
  - `TODO_ROADMAP.md`
- 后续如果接入正式后端、补充测试、引入 Git 提交规范，建议再新增：
  - `CHANGELOG.md`
  - `KNOWN_ISSUES.md`

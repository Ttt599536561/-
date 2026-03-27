# Database Schema

## 1. 文档目的

本文档用于说明项目数据库的整体结构设计，帮助后续开发者快速理解：

- 为什么需要这些表
- 每张表负责什么业务
- 表和表之间如何关联
- 每个字段的含义是什么
- 哪些表是 MVP 必建，哪些属于后续扩展

这份文档面向的是“产品 + 工程”的共同视角，不只是建表清单。

## 2. 设计原则

整套表结构设计遵循以下原则：

- 认证身份与业务资料分离
- 一张表只承载一种核心职责
- 优先满足当前产品主线，避免过度设计
- 同时为后续功能预留扩展空间
- 尽量符合 Supabase 官方推荐的数据组织方式
- 尽量让查询路径简单、RLS 易写、后续维护成本低

## 3. 设计结论

我建议本项目长期采用如下结构：

### 核心表

1. `auth.users`
2. `public.profiles`
3. `public.invite_codes`
4. `public.couples`
5. `public.courses`
6. `public.couple_events`
7. `public.shared_todos`

### 后续扩展表
8. `public.user_devices`
9. `public.reminder_messages`
10. `public.course_overrides`

## 4. 为什么这样设计

### 4.1 认证与业务分离

Supabase 已经提供 `auth.users` 作为认证身份源。  
因此我们不应该再把“业务用户主表”设计成与认证混在一起的 `public.users`，而应该使用：

- `auth.users`：负责登录身份
- `public.profiles`：负责业务资料

这样做的好处：

- Auth 不和业务耦合
- RLS 更清晰
- 后续资料字段扩展更自由
- 更符合 Supabase 官方推荐做法

### 4.2 情侣关系与邀请码分离

邀请码不是“情侣关系本身”，只是建立关系的凭证。  
因此需要分成两张表：

- `invite_codes`：管理邀请码的生成、状态、使用
- `couples`：管理真正的绑定关系

这样后续才能支持：

- 失效邀请码
- 重置邀请码
- 邀请码过期
- 已用邀请码追踪

### 4.3 课程与课程变更分离

当前 MVP 可以只用 `courses` 表。  
但如果后续做调课、补课、停课、节假日替换课表，就需要：

- `course_overrides`

因此这里先在文档里明确它的设计位置，等后续功能需要时再落表。

## 5. 整体关系图

```text
auth.users
  └─ 1:1 public.profiles

public.profiles
  ├─ 1:N public.invite_codes
  ├─ 1:N public.courses
  ├─ 1:N public.shared_todos (created_by)
  ├─ 1:N public.user_devices
  ├─ 1:N public.reminder_messages (sender / receiver)
  ├─ couples.user_a_id
  └─ couples.user_b_id

public.invite_codes
  └─ 可选关联 public.couples

public.couples
  ├─ 1:N public.couple_events
  ├─ 1:N public.shared_todos
  ├─ 1:N public.reminder_messages
  └─ 可选关联 public.courses (共享视角冗余字段)

public.courses
  └─ 1:N public.course_overrides
```

## 6. 表结构详细说明

## 6.1 `auth.users`

### 作用

Supabase Auth 自带表，负责：

- 登录认证
- 获取真实用户 ID
- 用户邮箱身份管理

### 是否自己建表

不需要。  
这是 Supabase 自带的认证表。

### 在本项目中的职责

- 提供全局唯一 `uid`
- 作为 `profiles.id` 的来源
- 是所有业务表最终身份关联的根节点

### 备注

我们不会直接在业务代码里把全部用户资料都存到 `auth.users` 里，而是通过 `profiles` 承载业务字段。

---

## 6.2 `public.profiles`

### 作用

业务用户主表。  
每个登录用户有且仅有一条资料记录。

### 主要职责

- 昵称
- 头像
- 学期设置
- 当前周校正
- 节次时间
- 主题
- 当前情侣关系标识

### 与其它表的关系

- `profiles.id -> auth.users.id`
- `profiles.id -> invite_codes.creator_id`
- `profiles.id -> courses.owner_id`
- `profiles.id -> shared_todos.created_by`
- `profiles.id -> couples.user_a_id / user_b_id`

### 字段说明

| 字段名 | 类型 | 是否必填 | 说明 |
|---|---|---:|---|
| `id` | `uuid` | 是 | 主键，同时引用 `auth.users(id)` |
| `email` | `text` | 否 | 当前用户邮箱，方便业务查询和展示 |
| `nickname` | `text` | 是 | 用户昵称 |
| `avatar_url` | `text` | 否 | 头像地址 |
| `couple_id` | `uuid` | 否 | 当前用户已绑定的情侣关系 ID，冗余字段，便于快速读取 |
| `semester_start_date` | `timestamptz` | 否 | 学期开始时间 |
| `total_weeks` | `smallint` | 是 | 当前学期总周数 |
| `current_week_offset` | `smallint` | 是 | 当前周手动校正偏移量 |
| `theme_mode` | `text` | 是 | 主题模式，如 `blue` / `pink` |
| `section_times` | `jsonb` | 是 | 节次时间配置，建议直接存数组 JSON |
| `created_at` | `timestamptz` | 是 | 创建时间 |
| `updated_at` | `timestamptz` | 是 | 更新时间 |

### 为什么 `section_times` 用 `jsonb`

因为当前节次配置天然是一组结构化数组数据，使用 `jsonb` 的好处是：

- 结构清晰
- 读取简单
- 更新方便
- 不需要额外拆出一张“小而复杂”的子表

### 推荐索引

- 主键自带索引
- `couple_id`

---

## 6.3 `public.invite_codes`

### 作用

情侣绑定邀请码表。

### 主要职责

- 生成邀请码
- 查询邀请码归属人
- 标记邀请码是否已使用
- 为后续支持“失效 / 轮换 / 过期”做基础

### 与其它表的关系

- `invite_codes.creator_id -> profiles.id`
- `invite_codes.used_by_id -> profiles.id`
- `invite_codes.couple_id -> couples.id`（可选）

### 字段说明

| 字段名 | 类型 | 是否必填 | 说明 |
|---|---|---:|---|
| `id` | `uuid` | 是 | 主键 |
| `code` | `text` | 是 | 邀请码本体，建议唯一 |
| `creator_id` | `uuid` | 是 | 邀请码创建者 |
| `used_by_id` | `uuid` | 否 | 邀请码被哪个用户使用 |
| `couple_id` | `uuid` | 否 | 使用后形成的情侣关系 ID |
| `status` | `text` | 是 | 状态，如 `active` / `used` / `revoked` / `expired` |
| `expires_at` | `timestamptz` | 否 | 过期时间 |
| `used_at` | `timestamptz` | 否 | 使用时间 |
| `created_at` | `timestamptz` | 是 | 创建时间 |

### 为什么不把邀请码直接放在 `profiles`

因为邀请码不是一个稳定不变的“用户属性”，而是一个独立可流转对象。  
如果未来要支持：

- 失效旧邀请码
- 重新生成新邀请码
- 邀请码过期
- 追踪历史邀请码

那单独拆表是更合理的。

### 推荐索引

- `code unique`
- `creator_id`
- `status`
- 可选：`creator_id + status` 组合索引

---

## 6.4 `public.couples`

### 作用

情侣关系主表。

### 主要职责

- 表示绑定成功的情侣关系
- 记录双方用户
- 记录纪念日
- 作为共享待办、提醒消息等双人数据的关系锚点

### 与其它表的关系

- `couples.user_a_id -> profiles.id`
- `couples.user_b_id -> profiles.id`
- `couples.invite_code_id -> invite_codes.id`
- `shared_todos.couple_id -> couples.id`
- `reminder_messages.couple_id -> couples.id`

### 字段说明

| 字段名 | 类型 | 是否必填 | 说明 |
|---|---|---:|---|
| `id` | `uuid` | 是 | 主键，情侣关系 ID |
| `user_a_id` | `uuid` | 是 | 关系中的第一个用户 |
| `user_b_id` | `uuid` | 是 | 关系中的第二个用户 |
| `invite_code_id` | `uuid` | 否 | 这次关系由哪条邀请码创建 |
| `anniversary_date` | `timestamptz` | 否 | 纪念日 |
| `status` | `text` | 是 | 状态，如 `active` / `unbound` |
| `bound_at` | `timestamptz` | 是 | 绑定时间 |
| `created_at` | `timestamptz` | 是 | 创建时间 |
| `updated_at` | `timestamptz` | 是 | 更新时间 |

### 设计重点

- 要防止同一对用户重复建关系
- 要防止 `(A,B)` 和 `(B,A)` 两条重复关系
- 要防止一个用户同时存在多个 `active` 关系

这部分约束可以通过：

- 唯一索引
- 检查约束
- 业务层校验

共同控制

### 推荐索引

- `user_a_id`
- `user_b_id`
- `status`
- `(least(user_a_id, user_b_id), greatest(user_a_id, user_b_id))` 表达式唯一索引

---

## 6.5 `public.courses`

### 作用

课表课程主表。

### 主要职责

- 存每个用户的课程数据
- 支撑我的课表
- 支撑 TA 的课表
- 支撑共同课表
- 支撑共同空闲时间计算

### 与其它表的关系

- `courses.owner_id -> profiles.id`
- `courses.couple_id -> couples.id`（可选冗余）

### 字段说明

| 字段名 | 类型 | 是否必填 | 说明 |
|---|---|---:|---|
| `id` | `uuid` | 是 | 主键 |
| `owner_id` | `uuid` | 是 | 课程归属用户 |
| `couple_id` | `uuid` | 否 | 所属情侣关系，可选冗余字段 |
| `name` | `text` | 是 | 课程名 |
| `location` | `text` | 否 | 上课地点 |
| `teacher` | `text` | 否 | 老师 |
| `day_of_week` | `smallint` | 是 | 周几上课，1-7 |
| `start_section` | `smallint` | 是 | 起始节次 |
| `duration` | `smallint` | 是 | 持续几节 |
| `weeks` | `int[]` | 是 | 上课周次数组 |
| `color` | `text` | 是 | 课程颜色 |
| `is_private` | `boolean` | 是 | 是否私密课 |
| `source` | `text` | 是 | 来源，如 `manual` / `imported` |
| `created_at` | `timestamptz` | 是 | 创建时间 |
| `updated_at` | `timestamptz` | 是 | 更新时间 |

### 为什么 `weeks` 用 `int[]`

因为这是 PostgreSQL 非常适合处理的结构：

- 比把周次存成字符串更规范
- 查询、更新、索引都更自然
- 后续如果要做更复杂筛选，也更好扩展

### 推荐索引

- `owner_id`
- `couple_id`
- `(owner_id, day_of_week, start_section)`

---

## 6.6 `public.shared_todos`

### 作用

情侣共享待办表。

### 主要职责

- 互动页共享清单
- 双方协同待办事项

### 与其它表的关系

- `shared_todos.couple_id -> couples.id`
- `shared_todos.created_by -> profiles.id`

### 字段说明

| 字段名 | 类型 | 是否必填 | 说明 |
|---|---|---:|---|
| `id` | `uuid` | 是 | 主键 |
| `couple_id` | `uuid` | 是 | 所属情侣关系 |
| `content` | `text` | 是 | 待办内容 |
| `created_by` | `uuid` | 是 | 创建者 |
| `is_completed` | `boolean` | 是 | 是否已完成 |
| `completed_at` | `timestamptz` | 否 | 完成时间 |
| `created_at` | `timestamptz` | 是 | 创建时间 |
| `updated_at` | `timestamptz` | 是 | 更新时间 |

### 推荐索引

- `couple_id`
- `(couple_id, created_at desc)`

---

## 6.6 `public.couple_events`

### 作用

情侣“专属约会 / 共同安排”主表。

### 主要职责

- 保存共同页点击共同空闲后生成的约会安排
- 支持两台手机之间同步显示
- 为后续查看 / 编辑 / 删除约会提供基础数据结构

### 与其它表的关系

- `couple_events.couple_id -> couples.id`
- `couple_events.created_by -> profiles.id`

### 字段说明

| 字段名 | 类型 | 是否必填 | 说明 |
|---|---|---:|---|
| `id` | `uuid` | 是 | 主键 |
| `couple_id` | `uuid` | 是 | 所属情侣关系 |
| `title` | `text` | 是 | 约会标题 |
| `week` | `int` | 是 | 第几周 |
| `day_of_week` | `smallint` | 是 | 星期几 |
| `start_section` | `smallint` | 是 | 起始节次 |
| `end_section` | `smallint` | 是 | 结束节次 |
| `created_by` | `uuid` | 是 | 创建者 |
| `reply_content` | `text` | 否 | 对方对这条约会主题的回复内容 |
| `replied_by` | `uuid` | 否 | 回复者 |
| `replied_at` | `timestamptz` | 否 | 回复时间 |
| `created_at` | `timestamptz` | 是 | 创建时间 |
| `updated_at` | `timestamptz` | 是 | 更新时间 |

### 推荐索引

- `couple_id`
- `week`
- `day_of_week`

---

## 6.7 `public.shared_todos`

### 作用

设备与推送表。

### 主要职责

- 记录用户的设备
- 记录 Push Token
- 支撑课前提醒和快捷提醒推送

### 字段说明

| 字段名 | 类型 | 是否必填 | 说明 |
|---|---|---:|---|
| `id` | `uuid` | 是 | 主键 |
| `user_id` | `uuid` | 是 | 所属用户 |
| `platform` | `text` | 是 | 平台，如 android / ios |
| `push_token` | `text` | 是 | 推送 token |
| `is_active` | `boolean` | 是 | 是否激活 |
| `created_at` | `timestamptz` | 是 | 创建时间 |
| `updated_at` | `timestamptz` | 是 | 更新时间 |

---

## 6.8 `public.user_devices`

### 作用

情侣提醒消息表。

### 主要职责

- 快捷提醒历史
- 后续消息中心
- 已读未读状态

### 与其它表的关系

- `couple_id -> couples.id`
- `sender_id -> profiles.id`
- `receiver_id -> profiles.id`

### 字段说明

| 字段名 | 类型 | 是否必填 | 说明 |
|---|---|---:|---|
| `id` | `uuid` | 是 | 主键 |
| `couple_id` | `uuid` | 是 | 所属情侣关系 |
| `sender_id` | `uuid` | 是 | 发送者 |
| `receiver_id` | `uuid` | 是 | 接收者 |
| `message_type` | `text` | 是 | 消息类型 |
| `content` | `text` | 是 | 消息正文 |
| `read_at` | `timestamptz` | 否 | 阅读时间 |
| `created_at` | `timestamptz` | 是 | 创建时间 |

---

## 6.9 `public.reminder_messages`

---

## 6.10 `public.course_overrides`

### 作用

课程变更表。

### 主要职责

- 调课
- 补课
- 停课

### 与其它表的关系

- `course_id -> courses.id`

### 字段说明

| 字段名 | 类型 | 是否必填 | 说明 |
|---|---|---:|---|
| `id` | `uuid` | 是 | 主键 |
| `course_id` | `uuid` | 是 | 对应原课程 |
| `week` | `int` | 是 | 哪一周生效 |
| `override_type` | `text` | 是 | 变更类型 |
| `new_day_of_week` | `smallint` | 否 | 新的上课日 |
| `new_start_section` | `smallint` | 否 | 新的起始节次 |
| `new_duration` | `smallint` | 否 | 新的持续节数 |
| `new_location` | `text` | 否 | 新地点 |
| `created_at` | `timestamptz` | 是 | 创建时间 |

## 7. MVP 阶段先建哪些表

如果现在只做最小可用闭环，建议先建这 5 张：

1. `public.profiles`
2. `public.invite_codes`
3. `public.couples`
4. `public.courses`
5. `public.couple_events`
6. `public.shared_todos`

这样已经足够支撑：

- 登录后的业务资料
- 邀请码绑定
- 情侣关系
- 课表
- 共享待办

## 8. 当前代码与数据库设计的差异

当前 App 远端接口历史上曾使用：

- `users`

但从当前确认的数据库设计来看，更推荐统一使用：

- `profiles`

所以从现在起的正式方向应该是：

- 数据库层：`profiles`
- 代码层：逐步把旧的 `users` 命名迁移到 `profiles`

## 9. 最终确认结论

如果要确认一套“既能支撑当前产品，又适合后续长期扩展”的数据库结构，我确认推荐采用：

- `auth.users`
- `public.profiles`
- `public.invite_codes`
- `public.couples`
- `public.courses`
- `public.shared_todos`

未来扩展：

- `public.user_devices`
- `public.reminder_messages`
- `public.course_overrides`

# 宠联中枢 (PetHub) — 分布式智能养宠平台

基于 **HarmonyOS 6.0.1(21)** 原生开发，利用鸿蒙分布式软总线技术实现跨品牌智能宠物硬件统一管控。

## 基本信息

| 项目 | 内容 |
|---|---|
| **应用名称** | 宠联中枢 (PetHub) |
| **Bundle ID** | `com.pethub.intelligent_pet` |
| **版本** | 1.0.0 (versionCode: 1000000) |
| **厂商** | PetHub |
| **Target SDK** | HarmonyOS 6.0.1(21) |
| **API 模式** | Stage Mode |
| **支持设备** | Phone, Tablet |
| **开发工具** | DevEco Studio |
| **主分支** | `master` |

## 项目简介

宠联中枢是一个面向宠物主人的智能养宠综合管理平台，旨在通过鸿蒙分布式软总线技术，将智能项圈、智能喂食器、饮水机、猫砂盆、摄像头、温湿度计等 16 款 IoT 设备整合到一个统一的中枢应用中，实现跨品牌、跨设备的协同控制和数据互通。

核心场景包括：
- **宠物定位与安全**：通过智能项圈实现 GPS 实时定位、历史轨迹回放、电子围栏告警
- **运动健康监测**：记录宠物每日步数、里程、卡路里消耗，生成周运动趋势
- **智能喂食管理**：多时段定时投喂、运动量自适应喂食调整、远程手动加餐
- **健康档案管理**：体重、体温、心率记录，疫苗接种与就诊记录追踪
- **多宠物管理**：支持添加多只宠物，数据按宠物隔离

## 技术栈

| 层级 | 技术 |
|---|---|
| **语言** | ArkTS (Ark TypeScript) |
| **UI 框架** | ArkUI（声明式 UI，`@Component` / `@State` / `@Entry`） |
| **构建系统** | Hvigor 6.0.1 |
| **包管理** | OHPM (OpenHarmony Package Manager) |
| **数据库** | RelationalStore (SQLite 封装，`@kit.ArkData`) |
| **分布式** | DeviceManager 软总线设备发现 (`@kit.DistributedServiceKit`) |
| **定位** | GeoLocationManager (`@kit.LocationKit`) |
| **传感器** | Accelerometer 加速度计传感器 |
| **日志** | HiLog (`@kit.PerformanceAnalysisKit`) |
| **测试框架** | @ohos/hypium 1.0.24 |
| **Mock 框架** | @ohos/hamock 1.0.0 |

## 项目结构

```
pet_project/
├── AppScope/                          # 应用级配置与资源
│   └── app.json5                      # 应用信息（bundleName、版本号、厂商）
├── entry/                             # 主模块
│   ├── build-profile.json5            # 模块构建配置
│   ├── src/main/
│   │   ├── ets/                       # ArkTS 源代码
│   │   │   ├── common/                # 公共常量与工具
│   │   │   │   └── constants/
│   │   │   │       └── AppConstants.ets   # 主题色、字号、间距常量
│   │   │   ├── components/            # 可复用 UI 组件
│   │   │   │   ├── CommonComponents.ets   # GlassCard、StatusBadge、ProgressRing 等
│   │   │   │   └── MapComponent.ets       # 地图组件（模拟占位）
│   │   │   ├── entryability/          # 应用生命周期入口
│   │   │   │   └── EntryAbility.ets       # 主 UIAbility：初始化 DB、启动首页
│   │   │   ├── entrybackupability/    # 备份扩展
│   │   │   │   └── EntryBackupAbility.ets
│   │   │   ├── hardware/              # 硬件抽象层（参考架构，当前注释）
│   │   │   │   ├── HardwareAbstraction.ets  # Hi3863 硬件模拟控制
│   │   │   │   └── Hi3863Controller.ets    # GPIO/PWM/ADC 引脚配置
│   │   │   ├── models/                # 数据模型与类型定义
│   │   │   │   ├── DataModels.ets         # 核心接口与枚举（30+ 类型）
│   │   │   │   ├── HardwareServiceModels.ets
│   │   │   │   ├── LocationModels.ets
│   │   │   │   ├── MapModels.ets
│   │   │   │   ├── SensorModels.ets
│   │   │   │   └── ServiceModels.ets
│   │   │   ├── pages/                 # 页面（13 个）
│   │   │   │   ├── Index.ets              # 主入口(Tab 导航) + 登录守卫
│   │   │   │   ├── LoginPage.ets          # 登录页
│   │   │   │   ├── RegisterPage.ets       # 注册页
│   │   │   │   ├── ForgotPasswordPage.ets # 忘记密码页
│   │   │   │   ├── HomePage.ets           # 首页（仪表盘）
│   │   │   │   ├── DevicesPage.ets        # 设备管理页
│   │   │   │   ├── HealthPage.ets         # 健康数据页
│   │   │   │   ├── ProfilePage.ets        # 个人中心页
│   │   │   │   ├── PetManagePage.ets      # 宠物档案管理页
│   │   │   │   ├── FeedingSchedulePage.ets # 喂食计划配置页
│   │   │   │   └── MapPage.ets            # 全屏地图/轨迹页
│   │   │   └── services/              # 业务逻辑与服务层
│   │   │       ├── RdbHelper.ets          # 数据库管理器（核心，9 张表）
│   │   │       ├── UserService.ets        # 用户认证服务
│   │   │       ├── PetService.ets         # 宠物 CRUD 服务
│   │   │       ├── FeedService.ets        # 喂食记录服务
│   │   │       ├── MotionService.ets      # 运动数据服务
│   │   │       ├── SensorService.ets      # 传感器服务（加速度计）
│   │   │       ├── LocationService.ets    # GPS 定位服务
│   │   │       ├── MapService.ets         # 地图操作服务
│   │   │       ├── DeviceDiscoveryService.ets  # 设备发现服务（软总线）
│   │   │       ├── CollarHardwareService.ets   # 项圈硬件控制服务
│   │   │       └── FeederHardwareService.ets   # 喂食器硬件控制服务
│   │   ├── resources/                 # 应用资源
│   │   │   ├── base/
│   │   │   │   ├── element/           # color.json、float.json、string.json
│   │   │   │   ├── media/             # 图标、头像、SVG 素材
│   │   │   │   └── profile/
│   │   │   │       ├── main_pages.json      # 页面路由配置
│   │   │   │       └── backup_config.json   # 备份配置
│   │   │   └── dark/element/color.json      # 深色模式配色
│   │   └── module.json5               # 模块清单（权限、Ability 声明）
│   ├── src/ohosTest/                  # 集成测试
│   ├── src/test/                      # 单元测试
│   └── src/mock/                      # Mock 配置
├── oh_modules/                        # OHPM 依赖（hypium、hamock）
├── hvigor/                            # Hvigor 构建系统配置
├── build-profile.json5                # 项目级构建配置
├── oh-package.json5                   # 根包清单
├── oh-package-lock.json5              # 依赖锁定
├── code-linter.json5                  # Lint 规则
├── hvigorfile.ts                      # 根 Hvigor 构建脚本
└── local.properties                   # 本地 SDK 路径
```

## 功能模块概览

### 首页（HomePage）

- **宠物信息卡片**：展示当前选中的宠物基本信息（名称、品种、年龄、在线状态）
- **智能项圈模块**：
  - 实时地图定位预览（含地理位置描述）
  - 四项操作按钮：一键寻宠、语音对讲、历史轨迹、电子围栏
  - 今日运动数据环形进度条（步数 / 里程 / 卡路里）
- **智能喂食器模块**：
  - 余粮 / 水量双环形进度指示
  - 今日喂食计划列表（早餐 / 午餐 / 晚餐，含状态标签）
  - 立即加餐 + 自定义投喂按钮
  - 今日投喂记录（定时 / 运动奖励 / 手动加餐）
- **其他设备快捷入口**：饮水机、猫砂盆、摄像头、温湿度计
- **分布式联动状态栏**：显示跨设备协同连接状态

### 设备管理（DevicesPage）

- 设备列表（智能项圈、喂食器、饮水机等）
- 设备详细信息（型号、状态、电量 / 余粮）
- 功能特性标签展示
- 更多设备网格（最多 13 台设备）
- 添加新设备入口

### 健康管理（HealthPage）

- 宠物健康档案（体重、体温、心率）
- 本周运动趋势柱状图
- 疫苗接种记录（狂犬疫苗、六联疫苗、驱虫）
- 就诊记录（常规体检、皮肤检查等）
- 查看完整历史入口

### 个人中心（ProfilePage）

- 用户信息卡片（VIP 会员标识）
- 统计数据：宠物数量、设备数量、使用天数、联动场景数
- 功能入口：我的宠物、设备管理、联动场景
- 设置选项：消息通知、隐私设置、帮助中心、关于我们
- 退出登录

### 用户系统

- 用户名 + 密码注册 / 登录
- 忘记密码重置
- 登录态通过 AppStorage 管理
- Index 页路由守卫：未登录自动跳转登录页

### 宠物管理（PetManagePage）

- 多宠物 CRUD（添加、编辑、删除）
- 宠物信息：名称、品种、年龄、性别、体重、头像
- 数据按 `user_id` 隔离

### 喂食计划（FeedingSchedulePage）

- 多时段喂食计划配置
- 每项支持：时间、标签、投喂量、是否启用自适应
- 自适应规则：根据运动步数阈值自动调整投喂量
- 星期重复设置

### 地图轨迹（MapPage）

- 全屏地图视图
- 宠物当日运动轨迹回放
- 位置点详情展示

## 数据库设计

数据库文件：`pet_hub.db`（安全等级 S1）

共 **9 张表**：

| 表名 | 用途 | 关键字段 | 分布式 |
|---|---|---|---|
| `user_info` | 用户账户 | id, username, password, nickname, is_vip | — |
| `pet_info` | 宠物档案 | id, user_id, name, breed, age, weight, vaccine_status | ✓ |
| `motion_record` | 运动记录 | id, pet_id, steps, distance, calories, record_date | ✓ |
| `feed_log` | 喂食日志 | id, pet_id, feed_time, feed_type, amount | ✓ |
| `location_track` | GPS 轨迹 | id, pet_id, latitude, longitude, accuracy, timestamp | ✓ |
| `hardware_telemetry` | 设备遥测 | id, device_id, device_type, metric_type, value | ✓ |
| `feeding_schedule` | 喂食计划 | id, pet_id, time, label, amount, is_adaptive | ✓ |
| `geo_fence` | 电子围栏 | id, pet_id, name, latitude, longitude, radius | ✓ |
| `adaptive_feeding_rule` | 自适应喂食规则 | id, pet_id, steps_threshold, amount_adjustment, is_reward | — |

标记为「✓」的 7 张表设置为分布式表，通过 `RelationalStore.setDistributedTables()` 实现跨设备数据同步。

数据库管理器 `RdbHelper` 采用单例模式，提供：
- 自动建表
- 分布式表配置
- 通用 CRUD（`insert` / `query` / `update` / `deleteData`）
- 事务批量操作
- 跨设备同步（`syncDistributed`）
- 轨迹查询（`getPetTrajectory`）
- 遥测查询（`getLatestTelemetry`）
- 喂食计划查询（`getActiveFeedingSchedules`）
- 延迟初始化 + 自动重试机制

## 服务层架构

```
pages/ ──调用──▶ services/ ──读写──▶ RdbHelper ──操作──▶ RelationalStore (SQLite)
                        │
                        ├──▶ DeviceDiscoveryService ──▶ DeviceManager (软总线)
                        ├──▶ LocationService ──▶ GeoLocationManager (GPS)
                        ├──▶ SensorService ──▶ Accelerometer (传感器)
                        ├──▶ CollarHardwareService ──▶ 智能项圈 (GPIO/PWM)
                        └──▶ FeederHardwareService ──▶ 智能喂食器 (GPIO/ADC)
```

| 服务 | 职责 |
|---|---|
| `RdbHelper` | 数据库生命周期管理、表创建、分布式同步、通用 CRUD |
| `UserService` | 注册、登录、登出、密码重置、Session 管理 |
| `PetService` | 宠物增删改查、多宠物切换、数据按用户隔离 |
| `FeedService` | 喂食记录增删改查、今日投喂量汇总 |
| `MotionService` | 运动日报读写、目标达成判断、自适应投喂建议 |
| `SensorService` | 加速度计传感器读取、步数检测（支持模拟回退） |
| `LocationService` | GPS 实时定位、轨迹点记录 |
| `MapService` | 地图相关数据操作 |
| `DeviceDiscoveryService` | 鸿蒙软总线设备发现、按设备类型/名称过滤 |
| `CollarHardwareService` | 项圈硬件指令（寻宠蜂鸣/LED、状态查询） |
| `FeederHardwareService` | 喂食器硬件指令（舵机投喂、重量传感器、校准） |

## 数据模型

核心类型定义在 [DataModels.ets](entry/src/main/ets/models/DataModels.ets) 中，包含 30+ 接口和枚举：

**枚举类型**：`DeviceType`（8 种设备类型）、`FeedingStatus`、`FeedingRecordType`、`VaccineStatus`、`HardwareCommandType`

**核心接口**：
- `PetInfo`、`DeviceInfo`、`LocationInfo`、`ActivityData`、`HealthData`
- `FeedingPlan`、`FeedingRecord`、`FeederStatus`
- `VaccineRecord`、`MedicalRecord`、`WeeklyActivity`
- `UserInfo`、`MenuItem`
- `LocationPoint`、`Trajectory`、`HardwareCommand`、`HardwareStatus`
- `CollarHardwareStatus`、`FeederHardwareStatus`
- `SensorData`、`AccelerometerData`
- `FeedingScheduleItem`、`AdaptiveFeedingRule`、`GeoFence`
- `HardwareTelemetry`

其他模型文件根据功能领域拆分：`HardwareServiceModels`、`LocationModels`、`SensorModels`、`MapModels`、`ServiceModels`。

## 权限申请

应用共申请 **9 项系统权限**（在 [module.json5](entry/src/main/module.json5) 中声明）：

| 权限 | 用途 | 使用场景 |
|---|---|---|
| `ohos.permission.LOCATION` | 精确定位 | 实时追踪宠物位置 |
| `ohos.permission.APPROXIMATELY_LOCATION` | 模糊定位 | 大致位置估算 |
| `ohos.permission.MICROPHONE` | 麦克风 | 语音对讲 |
| `ohos.permission.INTERNET` | 网络访问 | 云端服务与远程控制 |
| `ohos.permission.DISTRIBUTED_DATASYNC` | 分布式数据同步 | 跨设备数据协同 |
| `ohos.permission.ACCESS_SERVICE_DM` | 设备管理 | 软总线组网与设备发现 |
| `ohos.permission.USE_BLUETOOTH` | 蓝牙 | 连接项圈/喂食器等蓝牙设备 |
| `ohos.permission.GET_WIFI_INFO` | Wi-Fi 信息 | 网络通信 |
| `ohos.permission.ACCELEROMETER` | 加速度计 | 运动传感器数据 |
| `ohos.permission.ACTIVITY_MOTION` | 运动状态 | 步数统计与活动监测 |

## UI 组件

[CommonComponents.ets](entry/src/main/ets/components/CommonComponents.ets) 提供以下可复用组件：

| 组件 | 说明 |
|---|---|
| `GlassCard` | 玻璃态卡片容器，支持磨砂透明背景 |
| `StatusBadge` | 状态标签（在线/离线/已完成/待处理） |
| `SectionHeader` | 分区标题栏，带操作入口 |
| `ProgressRing` | 环形进度条，支持渐变色和动画 |
| `QuickActionButton` | 快捷操作按钮，带图标和标签 |

[MapComponent.ets](entry/src/main/ets/components/MapComponent.ets) 提供模拟地图组件（Map Kit 需要 AGC 配置，当前使用模拟占位）。

## 设计风格

- **设备尺寸**：适配 Phone + Tablet
- **配色方案**：主色 `#FF9F43`（活力橙），辅色 `#00B4D8`（科技蓝）
- **组件风格**：玻璃态卡片设计（Glassmorphism）、圆角卡片、柔和阴影
- **图标**：使用本地 SVG 资源，含 home、device、health、settings、GPS、shield、ring 等
- **支持深色模式**：在 `resources/dark/element/color.json` 中定义

## 主题常量

定义在 [AppConstants.ets](entry/src/main/ets/common/constants/AppConstants.ets)：

- `COLOR_PRIMARY`: `#FF9F43`
- `COLOR_SECONDARY`: `#00B4D8`
- `COLOR_SUCCESS`: `#2ECC71`
- `COLOR_WARNING`: `#F39C12`
- `COLOR_DANGER`: `#E74C3C`
- 统一的字号、边距、圆角半径、阴影参数

## 页面路由

在 [main_pages.json](entry/src/main/resources/base/profile/main_pages.json) 中注册 5 个页面路由：

```
pages/Index
pages/LoginPage
pages/RegisterPage
pages/ForgotPasswordPage
pages/PetManagePage
```

注：其他页面（HomePage、DevicesPage、HealthPage、ProfilePage、FeedingSchedulePage、MapPage）作为 Index 页 Tab 子页面或通过路由 API 导航，不需要在 `main_pages.json` 中注册。

## 硬件集成（参考架构）

项目预留了基于 Hi3863 开发板的硬件控制层代码（位于 `entry/src/main/ets/hardware/`，当前为注释状态），作为与真实智能硬件对接的参考架构：

- `HardwareAbstraction.ets`：硬件抽象层，提供模拟硬件控制器和 Hi3863 硬件控制器
- `Hi3863Controller.ets`：Hi3863 引脚配置（GPIO、PWM、ADC）

支持的硬件操作：
- **一键寻宠**：GPIO 控制蜂鸣器 + LED 闪烁
- **语音对讲**：麦克风 + 扬声器通道
- **运动检测**：加速度计传感器读取
- **自动投喂**：PWM 舵机 + 重量传感器（ADC）
- **状态查询**：电量、信号强度、在线状态

## 构建与运行

### 环境要求

- **DevEco Studio**：最新版本
- **HarmonyOS SDK**：API 21（6.0.1）
- **Node.js**：18.x 以上
- **OHPM**：最新版本

### 构建步骤

```bash
# 1. 安装依赖
ohpm install

# 2. 使用 Hvigor 构建（Debug）
hvigorw assembleHap --mode module -p product=default -p buildMode=debug

# 3. 或使用 hvigorw wrapper（如果配置了 wrapper）
./hvigorw assembleHap

# 4. 产物路径
# entry/build/default/outputs/default/entry-default-signed.hap
```

或在 DevEco Studio 中直接点击 **Build > Build Hap(s) / APP(s)**。

### 运行

1. 连接 HarmonyOS 设备或启动模拟器
2. 在 DevEco Studio 中点击 **Run** 按钮
3. 或通过命令行部署：

```bash
hdc install entry/build/default/outputs/default/entry-default-signed.hap
```

### 测试

```bash
# 运行单元测试
hvigorw test

# 运行集成测试（ohosTest）
hvigorw assembleHap --mode module -p product=default -p buildMode=debug --target ohosTest
```

## 代码规范

项目配置了 [code-linter.json5](code-linter.json5)，包含：

- **安全规则**：禁止弱加密算法、限制不安全的哈希函数使用
- **TypeScript 规则**：基于 `@typescript-eslint` 的编码规范检查

## 已知限制与待完成项

1. **硬件层未激活**：`hardware/` 目录代码为参考架构，当前为注释状态，需配合 Hi3863 真实硬件启用
2. **地图为模拟实现**：Map Kit 需要华为 AGC (AppGallery Connect) 配置，当前使用模拟占位组件
3. **传感器存在模拟回退**：`SensorService` 包含 `useSimulation` 标志，在无真实传感器时使用模拟数据
4. **代码混淆未启用**：Release 构建的混淆配置已就绪但 `enable: false`
5. **远程服务未接入**：互联网权限已申请，但远端 API/云服务尚未对接

## 相关资源

- [HarmonyOS 开发文档](https://developer.harmonyos.com/cn/docs/documentation)
- [ArkUI 开发指南](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/arkui-overview-0000001532000093-V3)
- [RelationalStore 开发指南](https://developer.harmonyos.com/cn/docs/documentation/doc-references-V3/js-apis-data-relationalStore-0000001544584053-V3)
- [DeviceManager 开发指南](https://developer.harmonyos.com/cn/docs/documentation/doc-references-V3/js-apis-distributedDeviceManager-0000001544463941-V3)
- [Hi3863 开发板](https://device.harmonyos.com/cn/docs/start/introduce/oem_start_guide-0000001050273456)

---

创建日期: 2026-04-20  
最后更新: 2026-05-16  
版本: 1.0.0

# Show Codex IQ Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 构建一个使用 Swift 6.2 和 SwiftUI/AppKit 的原生 macOS 菜单栏应用，定时获取 CodexRadar 数据，展示双行排名、详细榜单、趋势图与可配置的刷新策略。

**Architecture:** 应用采用单向数据流：`RadarClient` 负责网络请求，`RadarRepository` 负责缓存和刷新，`RankingEngine` 产生各类排名，`AppModel` 向 SwiftUI 视图暴露状态。通过 `MenuBarExtra(.window)` 提供菜单栏入口和弹出详情，使用 `Settings` scene 承载独立设置窗口；最后一次成功数据持久化到 Application Support，断网时继续可用。

**Tech Stack:** Swift 6.2.3、SwiftUI、AppKit、Swift Charts、Observation、URLSession、OSLog、ServiceManagement、XCTest/Swift Testing，macOS 14+，不引入第三方运行时依赖。

---

## 1. 已确认的数据与产品决策

### 数据来源

- 首版开发端点：`https://codexradar.com/current.json`
- 已确认 schema：`schema_version = 2.0`
- 所需字段位于 `model_iq.comparisons`，每个模型含 `label`、`model`、`reasoning_effort`、`latest.score`、`latest.cost_usd`、`latest.wall_seconds` 和 `recent_days`。
- 当前公开 JSON 已足够生成智商、费用、耗时和综合排名，也足够绘制近期趋势。
- CodexRadar 明确要求二次开发授权和数据归属说明。开发可使用公开摘要验证，对外发布前必须获得授权，并在详情页固定展示“数据来自 Codex 雷达 codexradar.com”及可点击链接。

### 交互方案比较

1. **推荐：SwiftUI `MenuBarExtra(.window)` + 紧凑单页详情**
   - 可原生表达 SF Symbols、Charts、Settings scene，结构清晰，维护成本低。
   - 菜单栏 label 使用两行 `VStack` 显示排名前两名；如果特定 macOS 版本对双行高度截断，仅对 status item label 降级为 AppKit `NSStatusItem` 自定义 view。
2. **纯 AppKit `NSStatusItem` + `NSPopover`**
   - 对菜单栏尺寸控制最强，但状态同步、设置窗口和预览代码更多。
3. **WKWebView 包装网页**
   - 开发快，但无法提供稳定的双行菜单栏、本地缓存和原生设置，不采用。

### 默认 UI

- 菜单栏默认两行：`1  GPT-5.6 Sol xhigh  105`、`2  GPT-5.6 Luna max  105`，使用 9–10 pt 紧凑字号、等宽数字。
- 设置中可将菜单栏指标切换为：智商最高、综合最佳、费用最低、耗时最低。
- 点击后打开约 430 x 680 pt 弹窗：
  1. 顶部：数据日期、更新/离线状态、立即刷新。
  2. 榜单：智商 `brain.head.profile`、费用 `dollarsign.circle`、耗时 `clock`、综合 `trophy`，每组显示前三。
  3. 趋势：使用 Swift Charts 显示当前指标前三的近期曲线，可在智商/费用/耗时之间切换。
  4. 底部：数据归属、设置、退出应用。
- 弹窗默认不使用巨大卡片和装饰性渐变，保持 macOS 菜单栏工具的高信息密度。

### 综合排名规则

- 对同一批有效模型分别生成百分位排名分：智商越高越好，费用和耗时越低越好。
- 综合分 = `智商排名分 x 50% + 费用排名分 x 25% + 耗时排名分 x 25%`。
- 同分先比智商，再比费用，再比耗时，最后按稳定 model id 排序。
- 缺少任一核心指标的模型不进入综合榜，但仍可进入拥有完整数据的单项榜。

## 2. 实施任务

### Task 1: 建立可构建的 macOS 应用骨架

**Files:**
- Create: `Package.swift`
- Create: `Sources/ShowCodexIQ/App/ShowCodexIQApp.swift`
- Create: `Sources/ShowCodexIQ/Resources/Info.plist`
- Create: `Tests/ShowCodexIQTests/SmokeTests.swift`
- Create: `.gitignore`

**Steps:**
1. 先写一个失败的 smoke test，导入 `ShowCodexIQ` 模块并验证 app metadata 存在。
2. 创建 Swift 6.2 package，配置 `.macOS(.v14)`、executable target 和 test target。
3. 创建最小 `@main App`，包含 `MenuBarExtra` 与 `Settings` scene。
4. 在 Info.plist 设置 `LSUIElement = true`，确保 Dock 不显示常驻图标。
5. 运行 `swift test`，预期全部通过；运行 `swift build`，预期无 warning/error。
6. 提交：`chore: scaffold native macOS menu bar app`。

### Task 2: 定义容错的 CodexRadar 数据模型

**Files:**
- Create: `Sources/ShowCodexIQ/Domain/RadarResponse.swift`
- Create: `Sources/ShowCodexIQ/Domain/ModelBenchmark.swift`
- Create: `Sources/ShowCodexIQ/Domain/Metric.swift`
- Create: `Tests/ShowCodexIQTests/Fixtures/current-v2.json`
- Create: `Tests/ShowCodexIQTests/RadarDecodingTests.swift`

**Steps:**
1. 从已确认的公开 JSON 保存一份最小化、去除无关隐私内容的 fixture。
2. 先写解码测试：比较字典转为稳定数组，正确解码 score/cost/wall time/recent days，忽略未知字段。
3. 再写字段缺失、`null`、未知 schema 的测试；未知 schema 可解码已知字段并记录 warning，不直接崩溃。
4. 使用 `CodingKeys` 隔离 snake_case，将网络 DTO 转为值语义的 `ModelBenchmark`。
5. 运行 `swift test --filter RadarDecodingTests`，预期通过。
6. 提交：`feat: model CodexRadar benchmark payload`。

### Task 3: 实现排名与综合分引擎

**Files:**
- Create: `Sources/ShowCodexIQ/Domain/RankingEngine.swift`
- Create: `Sources/ShowCodexIQ/Domain/RankedModel.swift`
- Create: `Tests/ShowCodexIQTests/RankingEngineTests.swift`

**Steps:**
1. 先写智商降序、费用升序、耗时升序、综合加权的失败测试。
2. 补充并列、单模型、指标全相等、缺少指标和稳定排序测试。
3. 实现纯函数 `rank(_:by:)` 和 `overallRanking(_:)`，不与 UI/网络状态耦合。
4. 运行 `swift test --filter RankingEngineTests`，预期通过。
5. 提交：`feat: add deterministic model rankings`。

### Task 4: 实现网络、缓存和离线降级

**Files:**
- Create: `Sources/ShowCodexIQ/Data/RadarClient.swift`
- Create: `Sources/ShowCodexIQ/Data/URLSessionRadarClient.swift`
- Create: `Sources/ShowCodexIQ/Data/SnapshotStore.swift`
- Create: `Sources/ShowCodexIQ/Data/RadarRepository.swift`
- Create: `Tests/ShowCodexIQTests/RadarClientTests.swift`
- Create: `Tests/ShowCodexIQTests/RadarRepositoryTests.swift`

**Steps:**
1. 通过协议抽象 client/store，先用 `URLProtocol` stub 写 200、304、HTTP 错误、超时和非法 JSON 测试。
2. 实现 15 秒超时、`Accept: application/json`、ETag/Last-Modified 条件请求和明确 User-Agent。
3. 先写 repository 测试：启动立即读取最后一次成功快照；刷新成功原子覆盖；刷新失败保留旧数据并标记 stale/offline。
4. 将缓存写入 `~/Library/Application Support/ShowCodexIQ/latest.json`，不保存任何账号或个人数据。
5. 对重复刷新做 single-flight，避免用户点击和定时器同时发起多个请求。
6. 运行 `swift test --filter 'Radar(Client|Repository)Tests'`，预期通过。
7. 提交：`feat: fetch and cache radar snapshots`。

### Task 5: 实现应用状态与自动刷新

**Files:**
- Create: `Sources/ShowCodexIQ/App/AppModel.swift`
- Create: `Sources/ShowCodexIQ/App/RefreshScheduler.swift`
- Create: `Sources/ShowCodexIQ/Settings/AppSettings.swift`
- Create: `Tests/ShowCodexIQTests/RefreshSchedulerTests.swift`
- Modify: `Sources/ShowCodexIQ/App/ShowCodexIQApp.swift`

**Steps:**
1. 使用 `@Observable @MainActor` 统一管理 loading/content/stale/error 和四类排名。
2. 先写可注入 clock 的调度测试：关闭自动刷新、修改间隔重置调度、从 sleep 唤醒后超过间隔立即刷新。
3. 默认自动刷新开启，间隔 30 分钟；候选间隔为 15/30/60/120/240 分钟，避免对数据源过度请求。
4. 每次打开弹窗时，若快照超过当前间隔则后台刷新，不阻塞展示缓存。
5. 运行 `swift test --filter RefreshSchedulerTests`，预期通过。
6. 提交：`feat: schedule automatic radar refreshes`。

### Task 6: 实现双行菜单栏标签

**Files:**
- Create: `Sources/ShowCodexIQ/MenuBar/MenuBarLabel.swift`
- Create: `Sources/ShowCodexIQ/Formatting/MetricFormatter.swift`
- Create: `Tests/ShowCodexIQTests/MetricFormatterTests.swift`
- Modify: `Sources/ShowCodexIQ/App/ShowCodexIQApp.swift`

**Steps:**
1. 先测试分数、美元、分钟/小时、未知值和过长模型名的格式化。
2. 用两行紧凑 `HStack` 组成 label，每行包含排名、缩短名称和数值；小数使用等宽数字。
3. 加载中显示 `Codex IQ ···`；无缓存且失败显示 `Codex IQ !`；有缓存但刷新失败保留排名并在弹窗告知离线。
4. 手动 QA 四种指标和浅色/深色菜单栏，检查不截断、不跳动。
5. 如 SwiftUI label 在目标系统上只显示一行，在此任务内切换为 `NSStatusItem` + `NSHostingView`，弹窗内容仍保持 SwiftUI。
6. 提交：`feat: show two ranked models in menu bar`。

### Task 7: 实现详情弹窗与四类榜单

**Files:**
- Create: `Sources/ShowCodexIQ/Popover/DashboardView.swift`
- Create: `Sources/ShowCodexIQ/Popover/StatusHeaderView.swift`
- Create: `Sources/ShowCodexIQ/Popover/RankingSection.swift`
- Create: `Sources/ShowCodexIQ/Popover/RankRow.swift`
- Create: `Sources/ShowCodexIQ/Popover/EmptyStateView.swift`
- Modify: `Sources/ShowCodexIQ/App/ShowCodexIQApp.swift`

**Steps:**
1. 将页面拆为独立小视图，排名行仅消费 `RankedModel` 值，无网络逻辑。
2. 为四个榜单分配 SF Symbols 和系统颜色；前三名使用轻量 medal/tint 强调，不使用自定义图片作为系统功能图标。
3. 顶部刷新按钮在请求期间显示 `ProgressView`并禁用重复点击；失败以紧凑 inline banner 呈现，不弹系统模态警告。
4. 页面底部添加必需的数据归属和跳转 CodexRadar 的 `Link`。
5. 为无数据、加载中、离线缓存和正常数据准备 Preview fixture，然后手动 QA VoiceOver label、键盘焦点、浅/深色。
6. 提交：`feat: add detailed ranking dashboard`。

### Task 8: 实现趋势曲线

**Files:**
- Create: `Sources/ShowCodexIQ/Popover/TrendChartView.swift`
- Create: `Sources/ShowCodexIQ/Domain/TrendPoint.swift`
- Create: `Tests/ShowCodexIQTests/TrendPointTests.swift`
- Modify: `Sources/ShowCodexIQ/Popover/DashboardView.swift`

**Steps:**
1. 先测试 `recent_days` 的日期排序、重复日期去重、缺失点和单位转换。
2. 使用 `Picker(.segmented)` 切换智商/费用/耗时，曲线默认选取当前指标前三模型。
3. 使用 Swift Charts `LineMark` + `PointMark`，固定模型颜色、简化 X 轴标签，hover 显示模型、日期与完整数值。
4. 少于两个点时显示可理解的空状态，不画误导性的平线。
5. 运行 `swift test --filter TrendPointTests`，然后手动验证 hover、长模型名和高对比度模式。
6. 提交：`feat: chart recent benchmark trends`。

### Task 9: 实现设置窗口与开机启动

**Files:**
- Create: `Sources/ShowCodexIQ/Settings/SettingsView.swift`
- Create: `Sources/ShowCodexIQ/Settings/GeneralSettingsView.swift`
- Create: `Sources/ShowCodexIQ/Settings/AboutView.swift`
- Create: `Sources/ShowCodexIQ/Settings/LaunchAtLoginController.swift`
- Create: `Tests/ShowCodexIQTests/AppSettingsTests.swift`
- Modify: `Sources/ShowCodexIQ/App/ShowCodexIQApp.swift`

**Steps:**
1. 用 `UserDefaults`/`@AppStorage` 持久化菜单栏默认指标、自动刷新开关、间隔和开机启动偏好。
2. 设置界面分为“通用”和“关于”；关于页从 bundle 读取版本/构建号，提供 GitHub 和数据源链接。
3. 使用 `SMAppService.mainApp` 管理开机启动，捕获失败并在设置页 inline 告知。
4. 自动刷新关闭时禁用间隔 Picker；修改菜单栏指标后 label 立即响应。
5. 测试默认值、无效旧值迁移和设置更改通知。
6. 运行 `swift test --filter AppSettingsTests`，然后手动验证重启保留设置和开机启动状态。
7. 提交：`feat: add preferences and launch at login`。

### Task 10: 打包、文档与完整验证

**Files:**
- Create: `scripts/package-app.sh`
- Create: `README.md`
- Create: `LICENSE`
- Create: `CONTRIBUTING.md`
- Create: `docs/data-source.md`
- Modify: `Sources/ShowCodexIQ/Resources/Info.plist`

**Steps:**
1. 写打包脚本：执行 release build，组装 `Show Codex IQ.app/Contents/{MacOS,Resources}`，复制 Info.plist，本地 ad-hoc codesign 仅供 QA。
2. 在 README 说明功能、macOS 要求、构建/运行、数据来源、排名公式、隐私和已知限制。
3. 在 `docs/data-source.md` 记录 schema 字段依赖、请求频率、归属要求和授权状态；未获授权前不发布二进制包。
4. 执行 `swift test --parallel`，预期全部通过。
5. 执行 `swift build -c release`，预期无 warning/error。
6. 执行 `bash scripts/package-app.sh`，预期生成 `dist/Show Codex IQ.app`；执行 `codesign --verify --deep --strict 'dist/Show Codex IQ.app'`，预期成功。
7. 手动验收：首次启动、双行 label、四榜单、趋势 hover、立即刷新、断网缓存、设置持久化、深色模式、VoiceOver、退出。
8. 添加远程 `https://github.com/zzzZZZ-JW/Show-Codex-IQ.git`，不覆盖远程已有历史；先 fetch/对比，再决定是否 rebase/merge。
9. 提交：`docs: add build and data source documentation`。

## 3. 验收标准

- 应用在 macOS 14+ 上作为纯菜单栏应用运行，不显示 Dock 图标。
- 菜单栏同时显示当前选定指标的第一、第二名，两行清晰可读。
- 弹窗显示智商、费用、耗时、综合前三、近期趋势、更新时间、刷新状态与立即刷新。
- 设置可修改菜单栏指标、自动刷新、刷新间隔和开机启动，并显示版本号。
- 断网或服务端错误不会清空已有数据，用户可看到数据陈旧程度和失败原因。
- 不存储个人数据，不使用分析 SDK，不依赖页面 HTML 抓取。
- 所有自动化测试和 release build 通过，数据归属可见，对外发布前授权已确认。

## 4. 开始实现前需确认的三个默认值

1. 最低系统版本使用 macOS 14，以直接使用 Observation 和 Swift Charts。
2. 综合排名权重使用“智商 50% / 费用 25% / 耗时 25%”。
3. 首版界面使用简体中文，字符串结构预留未来本地化，但本期不增加英文界面。

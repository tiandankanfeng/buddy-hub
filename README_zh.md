# buddy-hub

**[English](./README.md)** | **[中文](./README_zh.md)**

> Velpro 的 Claude Code Plugin Marketplace

专注于**开发者工作流自动化**、**代码质量守护**与**多 Agent 协作**的 Claude Code 插件集合。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

---

## 快速开始

### 安装 Marketplace

```bash
claude plugin marketplace add KaverinX/buddy-hub
```

### 更新 Marketplace

```bash
claude plugin marketplace update KaverinX/buddy-hub
```

### 卸载 Marketplace

```bash
claude plugin marketplace remove KaverinX/buddy-hub
```

---

## 插件管理

安装 Marketplace 后，可以管理其中的单个插件：

```bash
# 安装插件
claude plugin install flowsmith@buddy-hub

# 更新插件
claude plugin update flowsmith@buddy-hub

# 卸载插件
claude plugin uninstall flowsmith@buddy-hub

# 查看已安装插件
claude plugin list
```

---

## 当前可用插件

### 🔨 [flowsmith](./plugins/flowsmith) — 状态机驱动的开发 SOP 工作流

**角色：核心编排器** | `v1.0.0` | 6 条命令、4 个 Agent、3 个 Skill

强制执行严格的五阶段开发流程：**PLANNING → ARCHITECTURE → IMPLEMENTATION → OPTIMIZATION → REVIEW → DONE**。通过状态机禁止"跳过思考直接编码"，每个阶段都有明确的输入输出契约。

**核心特性：**
- 状态机强制阶段流转——不允许跳过
- 4 个独立上下文的 Subagent：Optimizer + Architecture / Security / Logic 审查员
- 3 个阶段专属 Skill 引导规划、架构设计和编码纪律
- PostToolUse Hook 自动校验状态合法性
- 跨任务知识沉淀到 `.sop/lessons.md`

```bash
claude plugin install flowsmith@buddy-hub
```

详见 [flowsmith README](./plugins/flowsmith/README.md)。

---

### 🔍 [code-archaeologist](./plugins/code-archaeologist) — 老代码考古与重构辅助

**角色：遗留代码分析师** | `v1.0.0` | 6 条命令、3 个 Agent、1 个 Skill

在重构、拆分或删除遗留代码前，派遣三个独立考古员进行三维度深度尽调——预防 90% 的重构事故。

**核心特性：**
- 三维度并行分析：历史(History) + 依赖(Dependency) + 意图(Intent)
- 自动识别 IDE 无法检测的隐式依赖（反射、配置驱动调用、序列化协议）
- 生成"不可跨越的红线"清单预防重构回归
- 考古结论自动注入 flowsmith 的规划约束
- 决策矩阵生成可执行的重构策略建议

```bash
claude plugin install code-archaeologist@buddy-hub
```

---

### 👥 [co-review](./plugins/co-review) — 团队协作审查工具

**角色：团队健康检查员** | `v1.0.0` | 4 条命令、3 个 Agent、1 个 Skill

针对多人协作场景的水平审查。不审查单个代码质量（那是 flowsmith 的工作），而是分析团队协作健康度、接口冲突风险与完成度信号。

**核心特性：**
- 三层架构：贡献画像 + 完成度评估 + 协作风险检测
- 独立上下文的 Subagent 避免分析污染
- 纯终端 TUI 可视化看板 (`bash scripts/tui/dashboard.sh`)
- 隐私优先：个人反馈严格隔离——不做横向对比、不判断态度、不泄露他人信息
- 5 级合并策略：`merge-now` → `staged` → `coordinate` → `block` → `escalate`

```bash
claude plugin install co-review@buddy-hub
```

---

### 🎨 [formatter](./plugins/formatter) — 代码风格守卫

**角色：代码风格守护者** | `v1.1.0` | 1 条命令、2 个 Hook、1 个 Skill

编辑即格式化 + 会话结束时风格门禁。将团队编码规约注入 Claude 的编辑动作中，消灭风格争论。

**核心特性：**
- 内置支付宝/阿里巴巴 Java 编码规约 Profile（约 270 条 Eclipse JDT 规则）
- PostToolUse Hook：每次编辑文件自动格式化
- Stop Hook：会话结束前全局风格检查
- 支持 Maven 与 Gradle 项目一键配置
- 可扩展 Profile 架构——添加新 XML 即可支持新语言

```bash
claude plugin install formatter@buddy-hub
```

---

## 插件生态架构

这些插件构成一个互联互通的生态系统，而非孤立工具：

```
                    ┌─────────────────────────────┐
                    │    🔨 flowsmith（核心）       │
                    │  状态机编排器                 │
                    │  规划 → 架构 → 编码 → 完成    │
                    └──────┬──────────┬────────────┘
                           │          │
              Hook：检测    │          │ Hook：审查后
              重构意图      │          │ 检测多作者
                           ▼          ▼
              ┌────────────────┐  ┌────────────────┐   ┌────────────────┐
              │ 🔍 code-       │  │ 👥 co-review   │   │ 🎨 formatter   │
              │ archaeologist  │  │                │   │                │
              │                │  │ 读取 .sop/*    │   │  正交层         │
              │ 注入结论到 ────┼──▶ 读取 .arch/*   │   │  无状态交互     │
              │ plan.md        │  │ 获取红线       │   │                │
              └────────────────┘  └────────────────┘   └────────────────┘
                           │          │
                           ▼          ▼
                    ┌─────────────────────────────┐
                    │   📚 共享知识层              │
                    │  .sop/lessons.md — 全员读写   │
                    │  .archaeology/report.md      │
                    └─────────────────────────────┘
```

### 插件关联关系

| 来源 | 目标 | 机制 | 说明 |
|------|------|------|------|
| flowsmith | code-archaeologist | Hook 触发 | 检测到重构/拆分/迁移关键词 → 建议 `/arch-init` |
| flowsmith | co-review | Hook 触发 | `/sop-review` 完成 + 检测到多作者 → 建议 `/scope-review` |
| code-archaeologist | flowsmith | `/arch-handoff` | 将考古结论注入 `plan.md` 的约束与前置条件 |
| code-archaeologist | co-review | 共享产物 | 红线清单输入协作风险检测 |
| co-review | flowsmith | 上下文读取 | 读取 `.sop/` 产物进行更精准的分析 |
| co-review | code-archaeologist | 上下文读取 | 读取 `.archaeology/report.md` 检测边界违规 |
| formatter | *（无）* | 正交独立 | 独立运行——与其他插件无状态交互 |
| **所有插件** | `lessons.md` | 共享读写 | 跨任务知识积累与注入 |

---

## 项目结构

```
buddy-hub/
├── .claude-plugin/
│   └── marketplace.json          # Marketplace 元信息
├── .github/workflows/
│   └── static.yml                # GitHub Pages 部署
├── index.html                    # 交互式 Marketplace 网站
├── README.md                     # 英文文档
├── README_zh.md                  # 中文文档
├── LICENSE                       # MIT 许可证
└── plugins/
    ├── flowsmith/                # SOP 工作流引擎
    │   ├── commands/             # 6 条斜杠命令
    │   ├── agents/               # 4 个独立上下文 Subagent
    │   ├── skills/               # 3 个阶段 Skill + 参考文档
    │   └── hooks/                # 状态校验 Hook
    ├── code-archaeologist/       # 老代码考古
    │   ├── commands/             # 6 条斜杠命令
    │   ├── agents/               # 3 个维度考古员
    │   ├── skills/               # 重构策略 Skill + 决策矩阵
    │   └── hooks/                # 重构意图检测 Hook
    ├── co-review/                # 团队协作审查
    │   ├── commands/             # 4 条斜杠命令
    │   ├── agents/               # 3 个独立分析器
    │   ├── skills/               # 合并策略 Skill + 评分标准
    │   ├── hooks/                # 多作者检测 Hook
    │   └── scripts/tui/          # 终端看板
    └── formatter/                # 代码风格守卫
        ├── commands/             # 1 条配置命令
        ├── skills/               # Java-Alipay 编码指导
        ├── hooks/                # 格式化 + 检查 Hook
        └── config/profiles/      # Eclipse JDT 格式化 Profile
```

---

## 后续规划

| 状态 | 插件 | 说明 | 关联插件 |
|------|------|------|----------|
| 🟢 开发中 | **release-captain** | 标准化发布流程编排：多语言 Changelog 同步、语义化版本管理、发布门禁。衔接 flowsmith 的 DONE 阶段到"发布上线"。 | flowsmith, co-review |
| 🟡 规划中 | **knowledge-base v2** | 跨项目经验沉淀中心。将所有插件的 `lessons.md` 聚合为全局语义索引，利用向量数据库实现跨项目经验注入。 | flowsmith, code-archaeologist, co-review |
| 🔵 探索中 | **Project Insight UI** | 从 co-review 的终端 TUI 进化为基于 Web 的交互式仪表盘。实时呈现代码演进曲线、团队健康热力图、重构风险雷达。 | co-review, code-archaeologist, flowsmith |

---

## 宏伟愿景

我们相信 AI 辅助编程不应该是"更快地写出更多 Bug"，而应该是**"用工程纪律打造真正可靠的软件"**。

1. **流程即护栏** — 状态机强制"先思考再编码"。每个阶段都有明确契约，不允许跳过。
2. **知识会沉淀** — `lessons.md` 不是日志，是活的知识库。每次任务完成、审查发现、考古结论都会回流——让下一次任务站在历史肩膀上。
3. **多 Agent 隔离** — 每个分析维度在独立上下文中运行。安全审查不会被优化建议干扰，团队分析不会被个人偏见污染。
4. **隐私优先** — 团队协作分析严格隔离个人数据。不做横向对比、不判断态度、不泄露他人信息——让工具服务于成长，而非制造焦虑。
5. **考古而非猛冲** — 重构前先理解：当初为什么这样写？谁在依赖它？哪些是必要复杂性？这套思考框架能预防 90% 的重构事故。
6. **开发全周期** — 从"想法"到"上线"的完整链路：规划 → 设计 → 编码 → 格式化 → 考古 → 审查 → 团队协作 → 发布。每个环节都有专属插件护航。

---

## 作者

**Velpro**
Email: [xvelpro8@gmail.com](mailto:xvelpro8@gmail.com)
GitHub: [@KaverinX](https://github.com/KaverinX)

---

## License

MIT © Velpro

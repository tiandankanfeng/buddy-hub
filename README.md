# buddy-hub

> Velpro 的 Claude Code Plugin Marketplace

专注于开发者工作流、代码质量、多 agent 协作的 Claude Code 插件集合。

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

强制执行五阶段开发流程：**规划 → 架构 → 编码 → 优化 → 三层并行审查**，支持知识沉淀与跨任务经验积累。

**核心特性**：
- 状态机驱动，禁止跳阶段
- 4 个 Subagent（独立上下文）：optimizer + 3 个专职 reviewer
- 3 个 Skill 引导规划/架构/编码阶段
- Hook 自动校验状态合法性
- 跨任务经验沉淀到 `.sop/lessons.md`

**安装**：
```bash
claude plugin install flowsmith@buddy-hub
```

详见 [flowsmith README](./plugins/flowsmith/README.md)。

### 🎨 [formatter](./plugins/formatter) — 编辑即格式化的代码风格守卫

Claude 每次编辑文件后自动运行格式化，任务结束时做全局风格检查。内置 **Alipay Convention**（阿里巴巴 Java 开发规约）配置，支持扩展更多语言和风格。

**核心特性**：
- PostToolUse Hook：编辑后自动 `spotless:apply` 单文件格式化
- Stop Hook：任务结束前全局 `spotless:check` 风格检查
- `/formatter:setup` 一键接入项目构建配置
- 内置 Authoring Skill，引导 Claude 遵循编码规范中格式化器无法自动修复的部分
- 支持 Maven / Gradle，支持自定义 Profile 扩展

**安装**：
```bash
claude plugin install formatter@buddy-hub
```

详见 [formatter README](./plugins/formatter/README.md)。

---

## Marketplace 结构

```
buddy-hub/
├── .claude-plugin/
│   └── marketplace.json                  # Marketplace 元信息
└── plugins/
    ├── flowsmith/                        # SOP 工作流插件
    └── formatter/                        # 代码格式化插件
```

---

## 后续规划

更多 plugin 即将加入：
- `code-archaeologist` — 老代码考古与重构辅助（规划中）
- `release-captain` — 自动化发版流程编排（规划中）

欢迎在 issues 中提建议或贡献新 plugin。

---

## 作者

**Velpro**
Email: [xvelpro8@gmail.com](mailto:xvelpro8@gmail.com)

---

## License

MIT © Velpro

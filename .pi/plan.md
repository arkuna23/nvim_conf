# Neovim 配置兼容性修复计划

## 摘要
以本机 **Neovim 0.12.5 和当前锁定插件版本**为基线，修复本轮审查发现的 LSP、Treesitter、格式化、调试与剪贴板问题，保留全部现有语言支持及主要快捷键。

已确定：格式化按项目选择；本机使用系统剪贴板，SSH 使用 OSC52 复制及终端快捷键粘贴；实施范围包含必要的用户级工具安装；Treesitter 增量选区采用小型原生实现。

## 1. 统一 LSP 注册、项目根目录与启用策略

涉及 `lua/plugins/lsp.lua`、`lua/plugins/conf.lua`、`lua/lib/lsp.lua`、`lua/lib/user_config.lua`。

- 统一使用 `vim.lsp.config(name, opts)` 注册，关闭 Mason-lspconfig 的自动启用，由配置显式调用 `vim.lsp.enable`。
- 根目录优先沿用各服务的上游默认实现，删除加载配置时立即求值的覆盖。需要保留的特殊规则使用 `root_markers` 或 `root_dir(bufnr, on_dir)`，从目标文件定位项目。
- PHP 恢复 Intelephense 的默认根目录逻辑；Kotlin 同样按目标文件识别 Gradle 根目录。散文件行为沿用各服务默认值。
- `editor_lang`、Mason 工具列表及语言插件使用一致的语言归类；兼容现有 `js`／`js/ts` 等别名，保留 `nil` 表示全部语言。
- Rust 由 rustaceanvim 管理，Haskell 由 haskell-tools 管理，避免通用注册入口重复启动这些服务。

**数据流：** 用户语言选择 → 服务与工具清单 → Mason 安装 → 原生配置注册 → 按缓冲区判断项目与禁用规则 → 启动服务。

## 2. 接通项目级设置

涉及 `lua/plugins/editor.lua`、`lua/lib/lsp.lua`，必要时增加一个职责单一的项目配置辅助模块。

- 保留 Neoconf 作为项目设置读取和交互入口，关闭旧式 LSP 设置注入及其自动重载链路，由原生 LSP 包装器负责应用设置。
- 保留 `.neoconf.json` 的 `lspconfig.<服务名>` 格式及点分键展开；设置优先级为基础配置 → 导入的全局／项目编辑器设置 → 全局 Neoconf 服务设置 → 项目 Neoconf 服务设置。
- 同时兼容 `lspconfig.<服务名> = false` 和已有 `<服务名>.disable = true`；在目标缓冲区的启动判定中处理，使不同项目可分别启用同一服务。
- 服务启动前合并设置，保留并串联原有生命周期回调。项目设置变更以重新启动 Neovim 后生效作为明确默认行为。
- 简化 JSON Schema 注册，在原生配置的 `settings` 中一次完成 SchemaStore 与自定义 schema 合并。

## 3. 修复具体语言配置与工具依赖

涉及 `lua/plugins/conf.lua`、`lua/plugins/lang.lua` 和现有安装入口。

- **C#：** 使用 Mason 的 OmniSharp 可执行入口和上游默认启动参数；将仍需要的选项迁移到 `settings`，消除 DLL 路径及大小写依赖。
- **Go：** 将配置修正为 `settings.gopls` 对象，保留现有提示、检查及 CodeLens 偏好。
- **Vue：** 保留 `ts_ls`，补齐 `vue_ls`，安装 Vue Language Server，并使用其实际安装目录加载 `@vue/typescript-plugin`；采用当前 lspconfig 提供的请求转发协作。
- **Rust：** 为当前生效工具链安装 rust-analyzer；将保存检查整理为 `checkOnSave = true` 与 `check.command = "clippy"`，构建脚本选项使用当前字段。工具链维护从插件构建步骤中分离，形成显式安装操作。
- **Python：** 补齐 Black，保留 `isort → black` 的处理顺序。
- 安装声明和实际语言筛选保持一致。工具安装失败时给出具体包名和原因，验收在依赖准备完成后继续。

## 4. 完整迁移新版 Treesitter

涉及 `lua/plugins/editor.lua`、`lua/plugins/conf.lua`；增量选区集中在一个小型 Lua 模块中。

- 使用当前 `main` 实现并提前加载，按配置列表显式安装解析器；`TSUpdate` 继续负责更新。
- 在文件类型事件中启用高亮、缩进和窗口局部折叠；保留 LaTeX 的现有高亮例外。
- 为启动时已打开的缓冲区及解析器安装完成后的缓冲区应用相同初始化逻辑。
- 保留增量选区键位：普通模式 Enter 选择当前语法节点；选区模式 Enter 扩大到更大的父节点；Backspace 回到上一次选区；Tab 扩到最近的语法作用域。
- 作用域来自当前语言的 `locals` 查询；缺少作用域查询时，Tab 使用更大的命名父节点。选区历史按缓冲区保存，并在文本变化或退出选区后重置；正确换算 Treesitter 的字节列及右开区间。
- 解析器尚在安装或文件类型缺少解析器时沿用普通编辑行为，安装完成后再启用增强功能。

## 5. 统一手动和保存格式化

涉及 `lua/lib/lsp.lua`、`lua/plugins/editor.lua`、`lua/plugins/conf.lua`。

- 保留服务器原始格式化能力，由 Conform 使用 `lsp_format = "fallback"` 统一决策。
- 手动格式化继续使用 `<leader>f`；保存格式化保留 Markdown、Vue、Kotlin 的现有排除项。两种入口共用工具选择策略，保存采用同步、有界超时。
- JS、TS、JSX、TSX、CSS、JSON、JSONC、GraphQL：从文件目录向上找到 Biome 配置且 Biome 可用时选 Biome，否则选 Prettier。
- HTML、Vue、Svelte、Astro、SCSS、Less、YAML、Handlebars、Markdown／MDX 使用 Prettier，避开 Biome 实验性语言能力的默认依赖。
- 每次前端格式化只选择一个外部格式化器。工具执行报错时直接报告，保持选定工具的语义；项目缺少外部工具时由 LSP 回退处理。
- 项目 Prettier 配置优先，通过 Prettier 配置解析接口识别其支持的配置文件；项目配置完整性由 Prettier 自身校验。项目未提供配置时使用现有 `conf/.prettierrc.json`。

## 6. 修复调试和快捷键

涉及 `lua/plugins/dap.lua`、`lua/lib/lsp.lua`。

- Mason-DAP 显式声明 `codelldb` 和 Kotlin adapter，并沿用语言筛选。
- 逐项注册 `dap.adapters` 和 `dap.configurations`，保留 Mason 及其他语言插件注册的调试能力。
- 为 nvim-dap-virtual-text 配置 `setup`。
- `<leader>da` 增加参数输入：通过 Vim 的 `input()` 与 `shellsplit()` 获取参数，深拷贝运行配置后设置 `args`，保持原运行配置；取消输入则结束此次启动，空输入表示空参数。
- `<leader>cA` 使用 `vim.lsp.buf.code_action`，限定 `context.only = { "source" }`。

## 7. 区分本机与 SSH 剪贴板

涉及 `lua/config/general.lua`。

- 判定顺序：Neovide 原有集成 → SSH 环境 → 本机桌面。
- 本机 Wayland／X11 使用 Neovim 系统剪贴板 provider，保持 `unnamedplus`。
- SSH 根据 `SSH_CONNECTION`／`SSH_TTY` 选择 OSC52 复制；保留普通 `y/p` 使用内部寄存器，通过显式 `+` 寄存器复制到本机。远程读取 provider 使用独立的本地缓存，避免递归读取未命名寄存器。
- 从本机向 SSH 会话粘贴使用终端快捷键；OSC52 读取查询保持关闭。tmux 等场景的实际传输取决于终端转发支持，作为交互验收项。

## 验证与验收

采用少量正向场景覆盖独立行为，优先复用现有验证入口；仅为项目根目录／设置合并、格式化选择和原生选区等新增逻辑补充针对性检查。

1. **多项目 LSP：** 同一会话打开两个真实项目，确认各自客户端根目录、项目设置和语言筛选结果；PHP、C#、Go、Vue、Rust 分别确认成功附加，Vue 验证脚本跳转与模板补全。
2. **Treesitter：** Lua／TypeScript／Rust 验证解析器、高亮、缩进与折叠；验证 Enter 扩选、Tab 作用域及 Backspace 回退，并覆盖多字节文本的选区范围。
3. **格式化：** 分别在 Biome 项目、Prettier 项目及默认配置项目核对所选工具；Python 验证导入排序和正文格式化，TOML 验证 LSP 格式化；核对保存排除项。
4. **DAP：** C／C++ 最小程序完成断点、单步、变量显示和带参数启动；Kotlin adapter 完成安装及注册检查，现有 Go 等 adapter 继续保留。
5. **剪贴板：** 本机验证应用间双向复制粘贴；SSH 验证显式复制到本机、终端快捷键粘贴及内部寄存器操作。
6. **整体：** 正常文件启动、启动页后打开文件、恢复会话均完成插件初始化；最终差异仅包含本计划范围内的配置及必要锁文件变化。

## 假设与默认边界

- 默认保留全部语言、现有分类开关、主题、AI 插件、会话功能和主要快捷键。
- 插件兼容基线采用当前锁文件；仅在实现依赖确有需要时调整对应单个插件或新增必要锁条目。
- 用户级安装覆盖 Mason 工具、解析器及当前 Rust 工具链组件；系统级运行时与桌面剪贴板依赖整理为明确清单。
- 新版 Treesitter 增量选区复用 Neovim API，保持单模块实现。
- 项目级 LSP 设置通过重新启动 Neovim 应用；远程粘贴采用已选定的终端方式。
- 实际项目、终端或系统依赖阻塞验收时，记录已获得的证据、具体阻塞点和所需环境，再继续对应验证。
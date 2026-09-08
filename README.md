# ai-coder-rightclick

为 Windows 资源管理器右键菜单添加 `opencode`、`claude`、`cline` 三项，让你在任意文件夹里一键启动常用的 AI 编码命令行工具。

## 功能特性

- **无需管理员权限** —— 所有注册表项都写在 `HKCU\Software\Classes` 下。
- **一套脚本管理三个工具** —— `opencode`、`claude`、`cline`（AI 编码三件套）。
- **菜单排在最上方** —— 数字前缀 `01_` / `02_` / `03_` 让三项压过所有第三方菜单项（cmd、git、WSL、Trae CN…）。
- **显示名干净** —— 注册表键名是 `01_opencode`，但菜单上只显示 `opencode`（由 `MUIVerb` 控制）。
- **官方图标** —— 每项使用对应工具的官方 `.ico`。
- **自包含** —— 安装/卸载脚本、启动器、图标同目录打包，双击 `.bat` 即用。
- **支持单独或批量** —— 可只增删某一个，也可一次增删三个。

## 支持的工具

| 工具 | 启动命令 |
|---|---|
| `opencode` | `opencode` |
| `claude` | `claude` |
| `cline` | `cline` |

> 工具本体**不**随包提供，请自行安装并确保已在 `PATH` 中。

## 环境要求

- Windows 10 / 11
- PowerShell 5.1+（Windows 自带）
- 目标 AI 命令行工具已安装且在 `PATH` 中

## 快速开始

### 安装（添加菜单项）

双击 **`添加-全部.bat`** 一次添加三个，或双击 **`添加-<工具>.bat`** 单独添加。

也可在终端运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Tool all
# 或只装一个：
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Tool opencode
```

启动器默认部署到 `D:\tools\ctx-menu`，可用 `-InstallDir` 改路径：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Tool all -InstallDir "C:\my\tools"
```

### 卸载（移除菜单项）

双击 **`卸载-全部.bat`** 一次移除三个，或双击 **`卸载-<工具>.bat`** 单独移除。

```powershell
powershell -ExecutionPolicy Bypass -File .\ctx-uninstall.ps1 -Tool all
```

卸载只删除注册表项，**不会**删除 `D:\tools\ctx-menu` 下的启动器与图标文件。

## 工作原理

每个工具会写入两个场景的注册表项：

| 场景 | 注册表路径 | 触发方式 |
|---|---|---|
| 文件夹空白处 | `HKCU\Software\Classes\Directory\Background\shell\<Verb>` | 在文件夹空白处右键 |
| 选中文件夹 | `HKCU\Software\Classes\Directory\shell\<Verb>` | 右键点击某个文件夹 |

命令会打开一个 PowerShell 窗口，先切换到目标目录（`%V` / `%1`），再执行对应工具。

### 为什么用数字前缀（`01_opencode` …）

资源管理器按注册表子键的**字母序**渲染右键菜单。数字排在字母之前，因此 `01_` / `02_` / `03_` 让三项排在所有第三方项（cmd、git_gui、WSL、Trae CN…）之前。系统内置项（新建 / 剪切 / 复制 / 属性）不在 `shell` 键里，恒在最上方。

### 为什么用 `MUIVerb` 而非改键名

菜单显示文字由 `MUIVerb` 控制，与键名**解耦**。所以键名可以是 `01_opencode`，菜单上仍显示 `opencode`。

### 为什么不写 `Position`

`Position` 只接受 `Top` / `Bottom`，且会**覆盖**字母序——写了反而会把数字前缀的排序全部盖掉；它也无法做出"系统项之后、第三方之前"的中间位置。因此排序完全交给数字前缀。

## 注意事项

- **Windows 11 二级菜单**：静态注册表项只出现在「显示更多选项」（旧版右键菜单）里。要进一级菜单需 COM shell 扩展或 Nilesoft Shell / ExplorerPatcher 之类的工具。经典菜单 hack（`{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}`）自 Windows 11 24H2 起已弃用。
- **编辑 `.ps1` 文件**：若修改脚本，请保存为 **UTF-8 with BOM**——否则 PowerShell 5.1 会按 GBK 解析中文导致乱码。
- **重启资源管理器**：安装/卸载会自动重启 Explorer（会关闭已打开的文件夹窗口）。加 `-NoRestartExplorer` 可跳过。

## 文件说明

| 文件 | 用途 |
|---|---|
| `install.ps1` | 核心安装脚本（自包含）。`-Tool opencode | claude | cline | all` |
| `ctx-uninstall.ps1` | 核心卸载脚本。`-Tool opencode | claude | cline | all`（`ctx-` = context menu） |
| `opencode.ps1` / `claude.ps1` / `cline.ps1` | 部署到安装目录的启动器 |
| `icons/` | 各工具的官方 `.ico` 图标 |
| `添加-*.bat` | 双击添加（单个或三个） |
| `卸载-*.bat` | 双击移除（单个或三个） |

## 许可证

MIT —— 见 [LICENSE](LICENSE)。

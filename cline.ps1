<#
.SYNOPSIS
    cline - 资源管理器右键菜单启动器

.DESCRIPTION
    由 Explorer 上下文菜单调用：先切换工作目录到目标文件夹，再执行 `cline`。

    参数使用 ValueFromRemainingArguments 接收，原因：
    Explorer 展开 %V / %1 时不会自动加引号，若在注册表里手写引号，
    根目录（如 C:\）展开后会变成 `C:\"`，CommandLineToArgvW 会解析出错。
    这里改为让 PowerShell 把多个 token 原样收集后 join 回完整路径。

.NOTES
    文件必须保存为 UTF-8 with BOM，否则 PowerShell 5.1 会按 GBK 解析中文。
#>
[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Target
)

$ErrorActionPreference = 'Continue'
$Tag = 'cline'

function Write-Tag {
    param(
        [string]$Message,
        [string]$Color = 'Gray'
    )
    Write-Host "[$Tag] $Message" -ForegroundColor $Color
}

# ---------- 1. 解析目标目录 ----------
$Path = (($Target | Where-Object { $_ }) -join ' ').Trim().Trim('"')
if ([string]::IsNullOrWhiteSpace($Path)) {
    $Path = (Get-Location).ProviderPath
}

# ---------- 2. 校验目录 ----------
if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
    Write-Tag "目标不是有效文件夹: $Path" 'Red'
    Write-Tag '若为根目录（如 C:\）或路径含连续空格，请改用 install.ps1 安装的版本。' 'DarkGray'
    exit 1
}

# ---------- 3. 校验依赖 ----------
if (-not (Get-Command cline -ErrorAction SilentlyContinue)) {
    Write-Tag '未找到 cline 命令。' 'Red'
    Write-Tag '请先安装 Cline CLI，并确保其所在目录已加入 PATH。' 'DarkGray'
    exit 1
}

# ---------- 4. 切换工作目录 ----------
Set-Location -LiteralPath $Path
try { $Host.UI.RawUI.WindowTitle = "$Tag - $Path" } catch { }

Write-Host ''
Write-Host ('=' * 62) -ForegroundColor DarkGray
Write-Tag ("工作目录 : " + (Get-Location).ProviderPath) 'Cyan'
Write-Tag '执行命令 : cline' 'Cyan'
Write-Host ('=' * 62) -ForegroundColor DarkGray
Write-Host ''

# ---------- 5. 执行 ----------
& cline
$exitCode = $LASTEXITCODE

Write-Host ''
Write-Host ('=' * 62) -ForegroundColor DarkGray
if ($null -ne $exitCode -and $exitCode -ne 0) {
    Write-Tag "cline 退出码: $exitCode（非 0，请查看上方输出）" 'Yellow'
}
else {
    Write-Tag '会话已结束，窗口保留在此目录。' 'Green'
}

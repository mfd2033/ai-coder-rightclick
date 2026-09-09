<#
.SYNOPSIS
    ctx-menu 右键菜单 - 卸载工具
.DESCRIPTION
    删除由 ctx-menu 安装的右键菜单项（注册表项）。
    自动重启 Windows 资源管理器。
    不会删除已部署的启动器与图标文件。
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\ctx-uninstall.ps1 -Tool opencode
    powershell -ExecutionPolicy Bypass -File .\ctx-uninstall.ps1 -Tool claude
    powershell -ExecutionPolicy Bypass -File .\ctx-uninstall.ps1 -Tool cline
.NOTES
    双击同名 .bat 入口即可；脚本需 UTF-8 with BOM。
#>
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('opencode', 'claude', 'cline')]
    [string]$Tool,

    # 脚本化调用时用：跳过重启资源管理器（菜单需下次重启 explorer 后才刷新）
    [switch]$NoRestartExplorer
)

$ErrorActionPreference = 'Stop'

# 工具 -> 内部 Verb 映射（与 install.ps1 一致；数字前缀控制菜单排序）
$Map = @{
    'opencode' = '01_opencode'
    'claude'   = '02_claude'
    'cline'    = '03_cline'
}
# 2026-09-08 之前的无前缀旧键名，改名后需一并清理，否则菜单会有重复项
$LegacyMap = @{
    'opencode' = 'OpenCode'
    'claude'   = 'Claude'
    'cline'    = 'Cline'
}

# 目标：当前工具 + 旧版键名（无前缀）；opencode 额外清 v1 的 OpenCodeHD
$Targets = @()
$Targets += $Map[$Tool], $LegacyMap[$Tool]
if ($Tool -eq 'opencode') { $Targets += 'OpenCodeHD' }

$Roots = @(
    'HKCU:\Software\Classes\Directory\Background\shell',
    'HKCU:\Software\Classes\Directory\shell',
    'HKCU:\Software\Classes\DesktopBackground\Shell'
)

Write-Host ''
Write-Host "==== 卸载 ctx-menu 菜单项：$Tool ====" -ForegroundColor Cyan
$Removed = 0
foreach ($verb in $Targets) {
    foreach ($root in $Roots) {
        $key = Join-Path $root $verb
        if (Test-Path -LiteralPath $key) {
            Remove-Item -LiteralPath $key -Recurse -Force
            Write-Host "[ok] 已删除: $key" -ForegroundColor Green
            $Removed++
        }
    }
}
if ($Removed -eq 0) {
    Write-Host "[--] 没有匹配的菜单项需要删除（已卸载过？）" -ForegroundColor DarkGray
}

# 校验
Write-Host ''
Write-Host '---- 校验 ----' -ForegroundColor DarkGray
$Left = @()
foreach ($verb in $Targets) {
    foreach ($root in $Roots) {
        $key = Join-Path $root $verb
        if (Test-Path -LiteralPath $key) { $Left += $key }
    }
}
if ($Left.Count -eq 0) {
    Write-Host "[ok] 目标键已全部清除" -ForegroundColor Green
}
else {
    Write-Host "[!!] 仍有残留: $($Left -join ', ')" -ForegroundColor Red
}

# 重启资源管理器
if ($NoRestartExplorer) {
    Write-Host ''
    Write-Host '[--] 跳过重启资源管理器。请手动执行: taskkill /f /im explorer.exe & start explorer.exe' -ForegroundColor Yellow
}
else {
    Write-Host ''
    Write-Host '[..] 正在重启 Windows 资源管理器 ...' -ForegroundColor Yellow
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) {
        Start-Process explorer.exe
    }
}
Write-Host '[ok] 完成。' -ForegroundColor Green
Write-Host ''

<#
.SYNOPSIS
    ctx-menu 右键菜单 - 一键安装（不需要管理员权限）

.DESCRIPTION
    部署以下三个工具的右键菜单项到 HKCU\Software\Classes：
        - opencode  ->  D:\tools\ctx-menu\opencode.ps1
        - claude    ->  D:\tools\ctx-menu\claude.ps1
        - cline     ->  D:\tools\ctx-menu\cline.ps1
    每个工具注册两个场景：
        Directory\Background\shell\<Verb>  -> 文件夹空白处右键，参数 %V
        Directory\shell\<Verb>              -> 选中文件夹右键，参数 %1
    清理已废弃的 OpenCodeHD 旧键（如有）。

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\install.ps1
    powershell -ExecutionPolicy Bypass -File .\install.ps1 -InstallDir D:\tools\ctx-menu
    powershell -ExecutionPolicy Bypass -File .\install.ps1 -NoRestartExplorer

.NOTES
    文件必须保存为 UTF-8 with BOM，否则 PowerShell 5.1 会按 GBK 解析中文。
#>
param(
    # 只装某一个工具；默认 all = 三个全装
    [ValidateSet('opencode', 'claude', 'cline', 'all')]
    [string]$Tool = 'all',

    [string]$InstallDir = 'D:\tools\ctx-menu',
    [switch]$NoRestartExplorer
)

$ErrorActionPreference = 'Stop'

# 配置
# Verb 键名带数字前缀：Explorer 按注册表子键字母序渲染菜单，
# 数字(0x30) < 字母，因此 01_/02_/03_ 会排在所有第三方项（cmd/git_gui/WSL/Trae CN…）之前。
# 系统内置项（新建/剪切/复制/查看/刷新）不在 shell 键里，恒在最上方，不受影响。
# 显示名由 MUIVerb 指定，与键名解耦，所以菜单上看到的仍是 opencode / claude / cline。
$Tools = @(
    @{ Verb = '01_opencode'; Display = 'opencode'; Launcher = 'opencode.ps1'; Icon = 'opencode.ico' },
    @{ Verb = '02_claude';   Display = 'claude';   Launcher = 'claude.ps1';   Icon = 'claude.ico'   },
    @{ Verb = '03_cline';    Display = 'cline';    Launcher = 'cline.ps1';    Icon = 'cline.ico'    }
)
# 只装指定工具时过滤列表（Display 就是 opencode / claude / cline）
if ($Tool -ne 'all') {
    $Tools = @($Tools | Where-Object { $_.Display -eq $Tool })
}

$PsExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'

# 场景：(注册表根, 占位符, 中文描述)
$Scenes = @(
    @{ Root = 'HKCU:\Software\Classes\Directory\Background\shell'; Arg = '%V'; Desc = '文件夹空白处右键' },
    @{ Root = 'HKCU:\Software\Classes\Directory\shell';            Arg = '%1'; Desc = '选中文件夹右键'   }
)

# 兼容旧版本键名（改名前的残留需要清掉，否则菜单会出现重复项）
#   - OpenCode/Claude/Cline : v2 之前（2026-09-08 前）的无前缀键名
#   - OpenCodeHD            : v1 (opencode-hd) 时代
$LegacyKeys = @(
    'HKCU:\Software\Classes\Directory\Background\shell\OpenCode',
    'HKCU:\Software\Classes\Directory\shell\OpenCode',
    'HKCU:\Software\Classes\Directory\Background\shell\Claude',
    'HKCU:\Software\Classes\Directory\shell\Claude',
    'HKCU:\Software\Classes\Directory\Background\shell\Cline',
    'HKCU:\Software\Classes\Directory\shell\Cline',
    'HKCU:\Software\Classes\Directory\Background\shell\OpenCodeHD',
    'HKCU:\Software\Classes\Directory\shell\OpenCodeHD',
    'HKCU:\Software\Classes\DesktopBackground\Shell\OpenCodeHD'
)

Write-Host ''
Write-Host '==== ctx-menu 右键菜单安装 ====' -ForegroundColor Cyan

# ---------- 0. 定位源文件 ----------
$SourceDir = $PSScriptRoot
$Missing = @()
foreach ($t in $Tools) {
    $p = Join-Path $SourceDir $t.Launcher
    if (-not (Test-Path -LiteralPath $p)) { $Missing += $p }
}
if ($Missing.Count -gt 0) {
    throw "缺少源文件: $($Missing -join ', ')`n请将本 install.ps1 与三个 .ps1 启动器、icons\ 目录放在同一目录。"
}
$SourceIconDir = Join-Path $SourceDir 'icons'
if (-not (Test-Path -LiteralPath $SourceIconDir)) {
    throw "缺少图标目录: $SourceIconDir"
}

# ---------- 1. 部署启动器 ----------
New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
foreach ($t in $Tools) {
    $dst = Join-Path $InstallDir $t.Launcher
    Copy-Item -LiteralPath (Join-Path $SourceDir $t.Launcher) -Destination $dst -Force
    Write-Host "[ok] 启动器: $dst" -ForegroundColor Green
}

# ---------- 2. 部署图标 ----------
$IconDir = Join-Path $InstallDir 'icons'
New-Item -ItemType Directory -Path $IconDir -Force | Out-Null
foreach ($t in $Tools) {
    $src = Join-Path $SourceIconDir $t.Icon
    $dst = Join-Path $IconDir $t.Icon
    if (Test-Path -LiteralPath $src) {
        Copy-Item -LiteralPath $src -Destination $dst -Force
        Write-Host "[ok] 图标  : $dst" -ForegroundColor Green
    }
    else {
        Write-Host "[!!] 图标源缺失: $src（菜单项会回退为无图标）" -ForegroundColor Yellow
    }
}

# ---------- 3. 清理旧键 ----------
foreach ($k in $LegacyKeys) {
    if (Test-Path -LiteralPath $k) {
        Remove-Item -LiteralPath $k -Recurse -Force
        Write-Host "[cleanup] 已删除旧键: $k" -ForegroundColor DarkYellow
    }
}

# ---------- 4. 写新键 ----------
foreach ($t in $Tools) {
    $Launcher = Join-Path $InstallDir $t.Launcher
    $Icon     = Join-Path $IconDir $t.Icon
    if (-not (Test-Path $Icon)) { $Icon = $PsExe }   # 回退

    foreach ($s in $Scenes) {
        $Key = Join-Path $s.Root $t.Verb

        New-Item -Path $Key -Force | Out-Null
        Set-ItemProperty -Path $Key -Name '(Default)' -Value $t.Display
        Set-ItemProperty -Path $Key -Name 'MUIVerb'   -Value $t.Display
        Set-ItemProperty -Path $Key -Name 'Icon'      -Value $Icon
        # 刻意不写 Position：
        #   1) Position 优先级高于字母序，会把数字前缀的排序全部盖掉
        #   2) 取值只有 Top/Bottom，做不出"系统项之后、第三方之前"这类中间位置
        #   3) 多个 verb 同时设 Top 会冲突（文档：后者优先）
        # 排序完全交给 Verb 的数字前缀。
        Remove-ItemProperty -Path $Key -Name 'Position' -ErrorAction SilentlyContinue

        $CmdKey = Join-Path $Key 'command'
        $cmd = "`"$PsExe`" -NoExit -NoProfile -ExecutionPolicy Bypass -File `"$Launcher`" $($s.Arg)"
        New-Item -Path $CmdKey -Force | Out-Null
        Set-ItemProperty -Path $CmdKey -Name '(Default)' -Value $cmd

        Write-Host "[ok] $($t.Display) $($s.Desc): $Key" -ForegroundColor Green
    }
}

# ---------- 5. 回读校验 ----------
Write-Host ''
Write-Host '---- 写入结果校验 ----' -ForegroundColor DarkGray
$AllOk = $true
foreach ($t in $Tools) {
    foreach ($s in $Scenes) {
        $Key = Join-Path $s.Root $t.Verb
        $label   = (Get-ItemProperty -Path $Key -Name '(Default)' -ErrorAction SilentlyContinue).'(Default)'
        $muiverb = (Get-ItemProperty -Path $Key -Name 'MUIVerb'   -ErrorAction SilentlyContinue).MUIVerb
        $cmd     = (Get-ItemProperty -Path (Join-Path $Key 'command') -Name '(Default)' -ErrorAction SilentlyContinue).'(Default)'
        $pos     = (Get-ItemProperty -Path $Key -Name 'Position'  -ErrorAction SilentlyContinue).Position
        if ($label -eq $t.Display -and $muiverb -eq $t.Display -and $cmd -match [regex]::Escape($t.Launcher) -and -not $pos) {
            Write-Host "[ok] $($t.Display) $($s.Desc)" -ForegroundColor Green
        }
        else {
            Write-Host "[!!] 校验失败: $Key" -ForegroundColor Red
            $AllOk = $false
        }
    }
}

# ---------- 5.5 排序预览 ----------
# Explorer 按注册表子键字母序渲染，这里把最终顺序打出来，便于肉眼确认是否够靠前。
Write-Host ''
Write-Host '---- 菜单项最终顺序预览（字母序 = 实际渲染顺序）----' -ForegroundColor DarkGray
$MyVerbs = @($Tools.Verb)
foreach ($s in $Scenes) {
    $hklmView = $s.Root -replace '^HKCU:\\Software\\Classes', 'HKEY_CLASSES_ROOT'
    $names = Get-ChildItem "Registry::$hklmView" -ErrorAction SilentlyContinue |
             Sort-Object -Property PSChildName | ForEach-Object { $_.PSChildName }
    Write-Host "  [$($s.Desc)]  $hklmView" -ForegroundColor Cyan
    for ($i = 0; $i -lt $names.Count; $i++) {
        $mine = $MyVerbs -contains $names[$i]
        $no   = '{0,2}.' -f ($i + 1)
        if ($mine) { Write-Host "      $no $($names[$i])   <== 本工具" -ForegroundColor Green }
        else       { Write-Host "      $no $($names[$i])" -ForegroundColor DarkGray }
    }
}

# ---------- 6. 重启资源管理器 ----------
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

Write-Host ''
if ($AllOk) {
    Write-Host '[ok] 安装完成。' -ForegroundColor Green
}
else {
    Write-Host '[!!] 部分键校验失败，请查看上方输出。' -ForegroundColor Red
}
Write-Host ''
Write-Host '验证方法：' -ForegroundColor Cyan
Write-Host '  1. 在任意文件夹空白处右键 -> Windows 11 需点「显示更多选项」-> 应看到 opencode / claude / cline 三项'
Write-Host '  2. 或选中一个文件夹右键 -> 同上'
Write-Host '  3. 点击后弹出 PowerShell，标题栏为 <tool> - <目录>，随后执行对应命令'
Write-Host ''
Write-Host '卸载：双击 D:\右键菜单卸载\卸载-<工具>.bat（或运行 卸载-全部.bat 一次性清掉全部）' -ForegroundColor Cyan
Write-Host ''

@echo off
chcp 65001 > nul
title 卸载 opencode 右键菜单
echo.
echo 即将删除 opencode 右键菜单项（含空白处 + 选中文件夹两种场景）
echo 不会删除 D:\tools\ctx-menu\opencode.ps1 等文件
echo.
pause
powershell -ExecutionPolicy Bypass -File "%~dp0ctx-uninstall.ps1" -Tool opencode
echo.
echo 完成。按任意键关闭窗口。
pause > nul

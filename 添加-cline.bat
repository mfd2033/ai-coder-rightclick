@echo off
chcp 65001 > nul
title 添加 cline 右键菜单
echo.
echo 即将添加 cline 右键菜单项（文件夹空白处 / 选中文件夹右键）
echo 菜单项会排在右键菜单最上方（键名 03_cline），显示名仍是 cline
echo.
pause
powershell -ExecutionPolicy Bypass -File "%~dp0install.ps1" -Tool cline
echo.
echo 完成。按任意键关闭窗口。
pause > nul

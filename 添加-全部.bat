@echo off
chcp 65001 > nul
title 添加全部 ctx-menu 右键菜单
echo.
echo 即将添加全部三个菜单项：opencode + claude + cline
echo 菜单项会排在右键菜单最上方（键名 01_opencode / 02_claude / 03_cline）
echo 同时会清理无数字前缀的旧键名（OpenCode / Claude / Cline / OpenCodeHD）
echo.
pause
powershell -ExecutionPolicy Bypass -File "%~dp0install.ps1" -Tool all
echo.
echo 完成。按任意键关闭窗口。
pause > nul

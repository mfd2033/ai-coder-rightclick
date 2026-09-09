@echo off
chcp 65001 > nul
title 一次性卸载全部 ctx-menu 菜单项
echo.
echo 即将删除全部 ctx-menu 菜单项（opencode + claude + cline，含旧 OpenCodeHD）
echo 不会删除已部署的启动器与图标文件
echo.
pause
powershell -ExecutionPolicy Bypass -File "%~dp0ctx-uninstall.ps1" -Tool all
echo.
echo 完成。按任意键关闭窗口。
pause > nul

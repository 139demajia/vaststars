@echo off
@chcp 65001 >nul

set current_dir=%~dp0
set mode=%1
if not defined mode (
	set mode=release
)

pushd %CURRENT_DIR%
	title build %mode% - %current_dir%
	luamake.exe -mode %mode%
	luamake.exe tools -mode %mode%
popd

pause
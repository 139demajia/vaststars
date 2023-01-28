@echo off
chcp 65001
set current_dir=%~dp0
set cachedir=.\3rd\ant\tools\prefab_editor\.build
set param=.\3rd\ant\tools\fileserver\main.lua ../../startup
set mode=%1
if not defined mode (
	set mode=release
)

if exist "%cachedir%" (
	rem rd /s /q %cachedir%
)

set exe=bin\msvc\%mode%\vaststars.exe
if not exist "%exe%" (
	echo can not found "%exe%"
	goto end
)

pushd %current_dir%
	title %mode% - %current_dir%%exe%
	%current_dir%%exe% %param%
popd

:end
pause
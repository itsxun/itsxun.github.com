@echo off
cls

set year=%date:~3,4%
set month=%date:~8,2%
set day=%date:~11,2%
set today=%year%-%month%-%day%
set time=%time:~0,8%
::编辑器
set editor=C:\Program Files\Sublime Text 3\sublime_text.exe
SET pwd=%cd%

echo 请输入博客分类：
set /p type=

set dir=%pwd%\_posts\%type%\

::if语句中为毛需要这么处理，可以参考：https://stackoverflow.com/questions/28308258/cannot-take-user-input-in-batch-file-while-in-if-statement
SETLOCAL ENABLEDELAYEDEXPANSION
IF NOT EXIST "%dir%" (
	md "%dir%"
)


cd /d "%dir%"

:rename

echo 请输入博客标题：
set /p title=

set title=%title: =-%

set file=%today%-%title%.md

IF EXIST "%file%" (
	echo 文件名已经被占用，请重新输入：
	goto rename
)

type NUL > %file%

@echo --- >> %file%
@echo layout: post >> %file%
@echo title: %title% >> %file%
@echo author: itsxun >> %file%
@echo date: %today% %time% +08:00  >> %file%
@echo catalog: true >> %file%
@echo tags: >> %file%
@echo     - %type% >> %file%
@echo --- >> %file%
@echo .>> %file%
echo 初始化完毕，正在打开中...
start "%editor%" "%file%"
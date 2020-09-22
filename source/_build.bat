echo off
call ..\TOOLS\PATHTOOL.EXE _tempbat.bat
call _tempbat.bat
del _tempbat.bat
maker.exe

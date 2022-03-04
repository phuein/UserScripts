@echo off

title LockAtNight
nircmd.exe win hide ititle "LockAtNight"

SET hour=%time:~0,2%
SET shouldrun=False

IF %hour% GEQ 0 IF %hour% LEQ 08 SET shouldrun=True

IF "%shouldrun%"=="True" (
    C:\nircmd-x64\nircmd.exe monitor off
)

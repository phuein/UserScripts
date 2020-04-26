@echo OFF
REM ffmpeg -i "%~1" -map 0:m:language:eng "%~n1.eng.srt"
REM ffmpeg -i "%~1" "%~n1.eng.srt"

:LOOP
if "%~1"=="" goto :END
  ffmpeg -i "%~1" "%~n1.eng.srt"
  shift
  goto :LOOP
:END

if %errorlevel% neq 0 pause

@echo OFF
ffmpeg -i "%~1" -map 0:m:language:eng "%~n1.eng.srt"

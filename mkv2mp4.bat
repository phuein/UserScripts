@echo OFF
CD /D %~dp1
ffmpeg -i %~nx1 -vf subtitles=%~nx1:si=0 -c:v libx264 -c:a copy -map 0:v -map 0:a:0 %~n1.mp4
pause
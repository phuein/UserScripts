@echo OFF
CD /D %~dp1

ffmpeg -i %~nx1 -filter_complex "fps=10,scale=-1:-1:flags=lanczos[x];[x]split[x1][x2]; [x1]palettegen[p];[x2][p]paletteuse" %~n1.gif

REM pause
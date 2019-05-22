REM Deletes files older than 7 days, in my security video recording folder.

CD /D "%userprofile%\Videos\Captures\video\C615"
start cmd /c for %%G in (.mp4, .jpg) do forfiles -s -m *%%G -d -7 -c "cmd /c del @path"

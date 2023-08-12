#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#MaxThreadsPerHotkey 2

MsgBox, 0, Functions, F1 - Click`nF2 - Hold Click`nF3 - Random E Key`nF4 - Random Clicking, 3

F1::Click
;F2::RButton
F2::Click down

F3::
ToggleE := !ToggleE
Loop
{
  If not ToggleE
    break

  Random,rand, 838, 2292
  Sleep rand
  Send e
}
return

F4::
Toggle := !Toggle
Loop
{
  If not Toggle
    break

  Random,rand, 348, 1492
  Sleep rand
  Click
}
return

F5::ExitApp

;New World
;ahk_class CryENGINE
;ahk_exe Javelin_x64.exe
;ahk_pid 4220
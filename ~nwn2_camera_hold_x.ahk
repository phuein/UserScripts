#Requires AutoHotkey v2.0

SendMode('Event')

#HotIf WinActive("ahk_exe nwn2.exe")
X::
{
	static toggle := 0
	Click 'X ' ((toggle := !toggle) ? 'down' : 'up')

}
#HotIf

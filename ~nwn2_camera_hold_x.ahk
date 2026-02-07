#Requires AutoHotkey v2.0

SendMode('Event')

toggle := 0

ToggleX()
{
	global toggle

    Click 'X ' ((toggle := !toggle) ? 'down' : 'up')
}

#HotIf WinActive("ahk_exe nwn2.exe")
; Override clicking X with a hold toggle of X
X::
{
	ToggleX()
}

; Release the toggle on Left Mouse Button click
~LButton::
{	
	if (toggle) {
		ToggleX()
	}
}
#HotIf

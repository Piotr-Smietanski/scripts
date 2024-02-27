#IfWinActive ahk_class POEWindowClass ;Disable HotKeys while game window isn't focused

Numpad0::
{
	send, {Ctrl down}
	send, qwert
	send, {Ctrl up}
}
return

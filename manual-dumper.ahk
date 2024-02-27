#IfWinActive ahk_class POEWindowClass ;Disable HotKeys while game window isn't focused

;----------------------------------------------------------------------------------------
dump_inv_manual_mouse_controll()
{
	while (GetKeyState("MButton" , "p"))
	{
		Click
		Sleep 20
	}
}

;----------------------------------------------------------------------------------------
MButton::
{
	if (GetKeyState("NumLock" , "t"))
	{
		Send, {Ctrl down}
		dump_inv_manual_mouse_controll()
		Send, {Ctrl up}
	}
	else
		dump_inv_manual_mouse_controll()
}
return

;----------------------------------------------------------------------------------------
^MButton::
{
	dump_inv_manual_mouse_controll()
}
return

;----------------------------------------------------------------------------------------
+MButton::
{
	dump_inv_manual_mouse_controll()
}
return

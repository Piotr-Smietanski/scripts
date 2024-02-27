#IfWinActive ahk_class POEWindowClass ;Disable HotKeys while game window isn't focused

global DUMP_KEY := "F4"
global CANCEL_KEY := "Esc"

Hotkey, %DUMP_KEY%, DumpButton
return

DumpButton:
	global DUMP_MODE := "manual"
	dump_inv_wrap()
return

;----------------------------------------------------------------------------------------
move_mouse_and_click(X, Y, Speed=1, Delay=33)
{
	MouseMove, X, Y, Speed
	Random, rndd, 0, 20
	Delay:=Delay+rndd
	Sleep, %Delay%
	Click
}

;----------------------------------------------------------------------------------------
dump_column(X, Y, Y_Offset, Quantity, mode)
{
	Counter = 0
	while(Counter <= Quantity)
	{
		; two break points:
		; one in manual mode requires holding down a button in order to continue dumping
		; second in automatic mode is holding Esc key
		if (mode == "manual")
		{
			if (!GetKeyState(DUMP_KEY , "p"))
			{
				return false
			}
		} else {
			if (GetKeyState(CANCEL_KEY , "p"))
			{
				return false
			}
		}
		; Y_Offset is a width of a single tile
		; (Y_Offset/2) is a distance to tile edge
		; variation can be negative because X and Y are coordinates of tile center
		variation:=(Y_Offset/2)*(1/3)
		Random, varia1, -variation, variation
		Random, varia2, -variation, variation
		move_mouse_and_click(X+varia1, Y+varia2)
		Y += Y_Offset
		++Counter
	}
	return true
}

;----------------------------------------------------------------------------------------
dump_sequence(First_Slot_X, First_Slot_Y, Last_Slot_X, Last_Slot_Y, TilesX, TilesY )
{
	steps_horizontal := TilesX - 1
	steps_vertical := TilesY - 1
	
	Single_Tile_X_Offset := (Last_Slot_X - First_Slot_X ) / steps_horizontal
	Single_Tile_Y_Offset := (Last_Slot_Y - First_Slot_Y ) / steps_vertical
	
	Current_Y := First_Slot_Y ; use different variable for tracking what row we are currently at
	Current_X := First_Slot_X ; use different variable for tracking what column we are currently at

	Counter = 0
	while (Counter <= steps_horizontal)
	{
		if ( ! dump_column(Current_X, Current_Y, Single_Tile_Y_Offset, steps_vertical, DUMP_MODE) )
		{
			break
		}
		Current_X += Single_Tile_X_Offset
		++Counter
	}
}

;----------------------------------------------------------------------------------------
dump_inv(First_Slot_X, First_Slot_Y, Last_Slot_X, Last_Slot_Y, tilH, tilV)
{
	Send, {Ctrl Down}
	dump_sequence(First_Slot_X, First_Slot_Y, Last_Slot_X, Last_Slot_Y, tilH, tilV)
	Send, {Ctrl Up}
}

;----------------------------------------------------------------------------------------
dump_inv_wrap()
{
    if WinActive("Path of Exile")
    {
		WinGetPos, Xpos, Ypos, WWidth, WHeight  ; Uses the window found above.
		
		tilH:=12 ; tiles horizontal
		tilV:=5 ; tiles vertical
		
		; calculate tiles centres coordinates based on screen resolution
		; fX - first slot X coordinate
		; lY - last  slot Y coordinate
		
		fXmult:=0.576
		lXmult:=0.03981
		fYmult:=0.4314
		lYmult:=0.236
		
		fX:= WWidth  - WHeight * fXmult
		lX:= WWidth  - WHeight * lXmult
		fY:= WHeight - WHeight * fYmult 
		lY:= WHeight - WHeight * lYmult 
		
		
		BlockInput, MouseMove
		MouseGetPos, CMPX, CMPY
		dump_inv(fX, fY, lX, lY, tilH, tilV)
		MouseMove, %CMPX%, %CMPY%, 0
		BlockInput, MouseMoveOff
	}
}

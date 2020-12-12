;========= Tweaked by kczx3 to include classes by just me ======================
;
; Header =======================================================================
; Name .........: Microsoft Office 2016 Inspired UI
; Description ..: A custom UI design based on Microsoft Office 2016
; AHK Version ..: 1.1.23.01 (Unicode 32-bit) - January 24, 2016
; OS Version ...: Windows 2000+
; Language .....: English (en-US)
; Author .......: (TheDewd) Weston Campbell <westoncampbell@gmail.com>
; Filename .....: Office16.ahk
; Link .........: https://autohotkey.com/boards/viewtopic.php?f=6&t=3851&p=70009#p70009
; ==============================================================================

; =========================Modfied for AHKNMS===================================
; AHK Version ..: 1.1.30.01 (Unicode 64-bit)
; OS Version ...: Windows 10 
; Author .......: Helsmy jj4156@outlook.com
; Link .........: https://github.com/helsmy/AHKNumberMusicSheet
; ==============================================================================

; Globals ======================================================================
#SingleInstance, Force ; Allow only one running instance of the script
#Persistent ; Keep the script permanently running until terminated
#NoEnv ; Avoid checking empty variables for environment variables
;#Warn ; Enable warnings to assist with detecting common errors
;#NoTrayIcon ; Disable the tray icon of the script
#Include lib\Class_ImageButton-master\Sources\Class_ImageButton.ahk
#Include lib\Class_CtlColors-master\Sources\Class_CtlColors.ahk
SendMode, Input ; Method for sending keystrokes and mouse clicks
SetWorkingDir, %A_ScriptDir% ; Set the working directory of the script
SetBatchLines, -1 ; Run the script at maximum speed
SetControlDelay, -1 ; The delay to occur after modifying a control

Global Application := {} ; Create Application Object
Application.Name := "Number Music Sheet"
Application.Version := "0.1"
Application.Menu := ["File", "Edit", "View", "Tools", "Help"]
Application.SubMenu := {"File": ["Open", "Save", "SaveAs", "Revert"]
				  , "Edit": ["Edit"]
				  , "View": ["Play", "Stop"]
				  , "Tools": ["KeyUp", "KeyDown"]
				  , "Help": ["Help", "Abort"]}

Global Window := {} ; Create Window Object
Window.Width := 600
Window.Height := 400
Window.Title := Application.Name
; ==============================================================================

; Script =======================================================================
Gui, +LastFound Resize -Caption -Border +OwnDialogs +HwndhGui1
Gui, Color, FFFFFF
Gui, Margin, 10, 10

; Window Border
;~ Gui, Add, Picture, % " x" 0 " y" 0 " w" 1 " h" Window.Height " +HWNDhWindowBorderLeft", % "resources\border-outer-normal.png"
;~ Gui, Add, Picture, % " x" Window.Width-1 " y" 0 " w" 1 " h" Window.Height " +HWNDhWindowBorderRight", % "border-outer-normal.png"
;~ Gui, Add, Picture, % " x" 1 " y" Window.Height-1 " w" Window.Width-2 " h" 1 " +HWNDhWindowBorderBottom", % "border-outer-normal.png"
Gui, Add, Picture, vBorderTop, resources\border-top-normal.png
Gui, Add, Picture, vBorderBottom, resources\border-outer-normal.png
Gui, Add, Picture, vBorderLeft, resources\border-outer-normal.png
Gui, Add, Picture, vBorderRight, resources\border-outer-normal.png
; Window Header
Gui, Add, Picture, % " x" 1 " y" 0 " w" Window.Width-139 " h" 31 " +HWNDhWindowHeader1 gclickDrag", % "resources\window-header.png"
Gui, Add, Picture, % "x" 1 " y" 31 " w" Window.Width-2 " h" 29 " +HWNDhWindowHeader2", % "resources\window-header.png"

; Window Title
Gui, Font, s9 cFFFFFF, Segoe UI ; Set font options
Gui, Add, Text, % " x" 140 " y" 12 " w" Window.Width/6 " +BackgroundTrans +0x101 +HWNDhTitle", % Window.Title
Gui, Font ; Reset font options

; Window Menu Button
Gui, Font, s9 cFFFFFF, Segoe UI ; Set font options
loop, % Application.Menu.MaxIndex()
{
	tempMenu := Application.Menu[A_Index]
	If (A_Index = 1)
	{
		Gui, Add, Text, x2 yp+24 w60 h24 Center gOnMenuClick +HWNDhButtonMenu%tempMenu%Text +0x201, %tempMenu%
		CtlColors.Attach(hButtonMenu%tempMenu%Text, "2a8ad4", "FFFFFF")
	}
	Else
	{
		Gui, Add, Text, xp+60 yp wp hp Center gOnMenuClick +HWNDhButtonMenu%tempMenu%Text +0x201, %tempMenu%
		CtlColors.Attach(hButtonMenu%tempMenu%Text, "0173c7", "FFFFFF")
	}
}
;opt1 := [0, 0x0173c7, , 0xFFFFFF]
;opt2 := [0, 0x2a8ad4, , 0xFFFFFF]
Gui, Font ; Reset font options

;Ribbons Menu
Gui, Add, Picture, % "x1 y60 w" Window.Width-2 " h30 +HWNDhRibbonBackground", % "resources\ribbonMenu.png"
Gui, Add, Tab2, % "x" Window.Height " y" Window.Width " w0 h0 HWNDhTabs", File|Edit|View|Tools|Help
loop, % Application.Menu.MaxIndex()
{
	tempMenu := Application.Menu[A_Index]
	Gui, Tab, %A_Index%
	SubButton := Application.SubMenu[tempMenu]
	loop % SubButton.MaxIndex()
	{
		ButtonText := SubButton[A_Index]
		If (A_Index = 1)
			Gui, Add, Button, x4 y60 w70 h25 Section gmenuHandler vv%tempMenu%%ButtonText% +hwndh%tempMenu%%ButtonText%, %ButtonText%
		Else
			Gui, Add, Button, ys w70 h25 Section gmenuHandler vv%tempMenu%%ButtonText% +hwndh%tempMenu%%ButtonText%, %ButtonText%
		Opt1 := [0, 0xefefef]
		Opt2 := [0, 0xc0c0c0]
		Opt3 := [0, 0x808080]
		ImageButton.Create(h%tempMenu%%ButtonText%, Opt1, Opt2, Opt3)
	}
}
Gui, Tab

; Window Minimize Button
Gui, Add, Button, % "x" Window.Width-139 " y0 w46 h31 +HWNDhButtonMinimize gMinimize"
Opt1 := [0, "resources\button-minimize-normal.png"]
Opt2 := [0, "resources\button-minimize-hover.png"]
Opt3 := [0, "resources\button-minimize-pressed.png"]
ImageButton.Create(hButtonMinimize, Opt1, Opt2, Opt3)

; Window Maximize Button
Gui, Add, Button, % "x" Window.Width-93 " y0 w46 h31 +HWNDhButtonMaximize gMaximize"
Opt1 := [0, "resources\button-maximize-normal.png"]
Opt2 := [0, "resources\button-maximize-hover.png"]
Opt3 := [0, "resources\button-maximize-pressed.png"]
ImageButton.Create(hButtonMaximize, Opt1, Opt2, Opt3)

; Window Restore Button
Gui, Add, Button, % "x" Window.Width-93 " y0 w46 h31 +HWNDhButtonRestore gRestore Hidden1"
Opt1 := [0, "resources\button-restore-normal.png"]
Opt2 := [0, "resources\button-restore-hover.png"]
Opt3 := [0, "resources\button-restore-pressed.png"]
ImageButton.Create(hButtonRestore, Opt1, Opt2, Opt3)

; Window Close Button
Gui, Add, Button, % "x" Window.Width-47 " y0 w46 h31 +HWNDhButtonClose gGuiClose"
Opt1 := [0, "resources\button-close-normal.png"]
Opt2 := [0, "resources\button-close-hover.png"]
Opt3 := [0, "resources\button-close-pressed.png"]
ImageButton.Create(hButtonClose, Opt1, Opt2, Opt3)

; Window StatusBar
Gui, Font, s8 c515050, Segoe UI ; Set font options
Gui, Add, Picture, % " x" 1 " y" Window.Height-23 " w" Window.Width-2 " h" 22 " +HWNDhStatusBar", % "resources\window-statusbar.png"
Gui, Add, Text, % " x" 8 " y" Window.Height-19 " w" Window.Width-16 " vsBar +HWNDhStatusBarText +BackgroundTrans", % "Sample Text"
Gui, Font ; Reset font options

; Editor
Gui, Font, s20, Segoe UI
Gui,Add, Edit, % "ReadOnly -Wrap" " x" 15 " y" 100 " w" Window.Width-30 " h" Window.Height-100-23-15 " vvNMSEdit +HWNDhNMSEdit" 

Gui, Show, % " w" Window.Width " h" Window.Height, % Window.Title
GuiControl, Focus, sBar

return ; End automatic execution
; ==============================================================================

; Labels =======================================================================
OnMenuClick:
	GuiControlGet, MouseCtrl, Hwnd, %A_GuiControl%
	;MouseGetPos,,,, MouseCtrl, 2
	loop, % Application.Menu.MaxIndex()
	{
		tempMenu := Application.Menu[A_Index]
		If (MouseCtrl != hButtonMenu%tempMenu%Text)
			ctlColors.Change(hButtonMenu%tempMenu%Text, "0173c7", "FFFFFF")
		Else
		{
			ctlColors.Change(MouseCtrl, "2a8ad4", "FFFFFF")
			GuiControl, ChooseString, % hTabs, %tempMenu%
		}
	}
Return

Minimize:
	WinMinimize
Return

Maximize:
Restore:
	WinGet, MinMaxStatus, MinMax
	If (MinMaxStatus = 1)
	{
		WinRestore
		GuiControl, Show, % hButtonMaximize
		GuiControl, Hide, % hButtonRestore
	}
	Else
	{
		WinMaximize
		GuiControl, Hide, % hButtonMaximize
		GuiControl, Show, % hButtonRestore
	}
Return

GuiSize:
	If (ErrorLevel = 1) {
		return ; The window has been minimized.  No action needed.
	}

	GuiControl, MoveDraw, % hWindowHeader1, % " w" A_GuiWidth-139
	GuiControl, MoveDraw, % hWindowHeader2, % " w" A_GuiWidth-2
	GuiControl, MoveDraw, % hWindowBorderLeft, % " h" A_GuiHeight
	GuiControl, MoveDraw, % hWindowBorderRight, % " x"  A_GuiWidth-1 " h" A_GuiHeight
	GuiControl, MoveDraw, % hWindowBorderBottom, % " y" A_GuiHeight-1 " w" A_GuiWidth-2
	GuiControl, MoveDraw, % hTitle, % " w" A_GuiWidth-280
	GuiControl, MoveDraw, % hRibbonBackground, % "w" A_GuiWidth-2
	GuiControl, MoveDraw, % hStatusBar, % " w" A_GuiWidth-2 " y" A_GuiHeight-23
	GuiControl, MoveDraw, % hStatusBarText, % " w" A_GuiWidth-16 " y" A_GuiHeight-19
	GuiControl, MoveDraw, % hButtonMinimize, % " x" A_GuiWidth-139
	GuiControl, MoveDraw, % hButtonMaximize, % " x" A_GuiWidth-93
	GuiControl, MoveDraw, % hButtonRestore, % " x" A_GuiWidth-93
	GuiControl, MoveDraw, % hButtonClose, % " x" A_GuiWidth-47
	GuiControl, MoveDraw, % hNMSEdit, % " w" A_GuiWidth-30  " h" A_GuiHeight-100-23-15
return

MenuHandler:
	GuiControl, Focus, sBar
	GuiControlGet, currTab, , % hTabs
	ButtonPress := StrReplace(A_GuiControl,"v" . currTab)
	%ButtonPress%()
return

GuiEscape:
GuiClose:
ExitSub:
	ExitApp ; Terminate the script unconditionally
return

clickDrag:
	PostMessage, 0xA1, 2
Return

test()
{
	MsgBox, test
}
; ==============================================================================
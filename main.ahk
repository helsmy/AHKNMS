#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance, Force
; #NoTrayIcon ; Hide icon in tray , decomment it while program is runnable 
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SetBatchLines -1 ; For efficiency

#Include parser.ahk

p := new Parser()
nms := new NumSheet()

Gui, New, hwndhGui
Gui, Font,, MS Sans Serif
Gui, Font,, Consolas
Gui, Font,, Hymmnos  ; Easter Egg 一个小彩蛋
Gui,Add,Text,x43 y15 w70 h16,original
Gui,Add,Text,x554 y15 w70 h16,converted
Gui,Add,Edit,ReadOnly x40 y38 w300 h500,
Gui,Add,Edit,ReadOnly vShiftTxt x550 y38 w300 h500,
Gui,Add,Button,x415 y150 w70 h23,Key Up
Gui,Add,Text,x436 y180 w24 h12,-->
Gui,Add,Button,x415 y200 w70 h23,Key Down
Gui, Show, AutoSize Center, AHKNMS
return

ButtonKeyUp:
nms.KeyShift(1)
shift_txt := nms.Write()
GuiControl,, ShiftTxt, %shift_txt%
return

ButtonKeyDown:
nms.KeyShift(-1)
shift_txt := nms.Write()
GuiControl,, ShiftTxt, %shift_txt%
return

$^v::
IfWinActive ahk_class AutoHotkeyGUI
{
    ControlSetText,Edit1, %Clipboard%
    ControlSetText,Edit2,
    Gui, Submit, NoHide
    nms := p.NSParse(Clipboard)
}
else
    Send ^v
return

GuiClose:
ExitApp

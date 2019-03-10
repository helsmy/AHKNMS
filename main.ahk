#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance, Force

#Include parser.ahk

Gui, New, hwndhGui AlwaysOnTop Resize
Gui, Font,, MS Sans Serif
Gui, Add, Text,, Hello AHKNMS!
Gui, Show, AutoSize Center, AHKNMS

while(1)
{
	
}

GuiClose:
ExitApp

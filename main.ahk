#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance, Force
; #NoTrayIcon ; Hide icon in tray , decomment it while program is runnable 
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SetBatchLines -1 ; For efficiency

; =================================AHKNMS=======================================
; AHK Version ..: 1.1.30.01 (Unicode 64-bit)
; OS Version ...: Windows 10 
; Author .......: Helsmy jj4156@outlook.com
; Link .........: https://github.com/helsmy/AHKNumberMusicSheet
; License ......: GPLv3.0
; ==============================================================================

#Include lib\parser.ahk
#Include lib\midi.ahk

; 初始化
try
{
	global par := new Parser()
	global nms := new NumSheet()
	global NMS_path =
	global player := 
	#Include lib\gui.ahk
}
catch, err
{
	;MsgBox,,错误, % err.message "`n`n" err.extra
	; 启动GUI自动执行
	MsgBox, 1
}


; ==========================按键事件调用函数====================================
Open()
{
	old_path := NMS_path
	FileSelectFile, NMS_path, 3,,Open number sheet file, *.txt;*.nms
    ; 如果NMS_path为空说明按下了cancel，直接返回结束
	if NMS_path is Space
		return
	FileRead, NMS_file, % NMS_path
	Try
	{
		nms := par.NSParse(NMS_file)
		ControlSetText, Edit1, % NMS_file
	}
	Catch, err
	{
		NMS_path := old_path
		MsgBox,0, 解析失败,% "读取的文件也许不是数字谱`n`n" err.message "`n`n" err.extra
		return
	}
	return NMS_path
}

Save()
{
	MsgBox, Save
}

SaveAs()
{
	MsgBox, SaveAs
}

Revert()
{
	if (NMS_path == "")
		return
	FileRead, NMS_file, % NMS_path
	Try
	{
		nms := par.NSParse(NMS_file)
		ControlSetText, Edit1, % NMS_file
	}
	Catch, err
	{
        MsgBox,0, 解析失败,% "读取的文件也许不是数字谱`n`n" err.message "`n`n" err.extra
        return
    }
}

Play()
{
	if (nms.len == 0)
		return
	if !player
    {
        try
            player := new MIDIPlayer()
        catch err
        {
           MsgBox,,MIDI播放器初始化错误, % "`n`n" err.message "`n`n" err.extra
           return
        }
    }
    try
		player.Play(nms)	
	catch err
    {
        MsgBox,,播放错误, % "`n`n" err.message "`n`n" err.extra
        return
    }
}

Stop()
{
	if (nms.len == 0)
		return
	try
		Player.Stop()
	catch err
	{
        MsgBox,,停止错误,% "`n`n" err.message "`n`n" err.extra
        return
    }
}

Help()
{
	MsgBox,0,帮助,
(
具体语法请阅读
https://github.com/helsmy/AHKNumberMusicSheet
的 README 文件或者其他说明文件
)
	return
}

Abort()
{
	MsgBox,0,关于,
(
AHK Number Music Sheet v0.2-alpha
		
简单的数字谱扩展集解析器
		
欢迎访问
https://github.com/helsmy/AHKNumberMusicSheet
批判一番
)
	return
}
; ==========================按键事件调用函数完====================================
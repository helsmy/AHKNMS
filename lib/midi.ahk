#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; =================================AHKNMS=======================================
; AHK Version ..: 1.1.30.01 (Unicode 64-bit)
; OS Version ...: Windows 10 
; Author .......: Helsmy jj4156@outlook.com (modified for ahknms) Anthony Zhang azhang9@gmail.com (original author)
; Link .........: https://github.com/helsmy/AHKNumberMusicSheet
; License ......: AGPLv3.0
; ==============================================================================

class MIDIPlayer
{
	__New()
	{
		this.Device := new MIDIOutputDevice
		this.Device.SetVolume(100)
		this.Playing := False
		this.play_pos := 1
		this.command_pos := 1
		this.command_flag := 0
		this.NumSheet := ""
		this.beat := 0
		this.pCallback := RegisterCallback(this.PlayCallback,"F","",&this)
		this.buffer := []
		this.buffer_callback := RegisterCallback(this.BufferCallBack,"F","",&this)
	}
	; ==========================命令事件调用函数====================================
	BPM(r_beat)
	{
		old_command := this.current_command
		this.current_command := "CHANGEBPM"
		this.NumSheet.BPM := Round(60000/r_beat)
		this.beat := this.NumSheet.BPM << 2
		this.current_command := old_command
	}
	DO(r_main_note)
	{
		old_command := this.current_command
		this.current_command := "CHANGEDO"
		main_note_list := {"C": 1, "D": 3, "E": 5, "F": 6, "G": 8, "A": 10, "B": 12}
		up_list := {"#": 1, "b": -1}
		if (StrLen(r_main_note) == 1)
			this.NumSheet.main_note := main_note_list[r_main_note]
		else
		{
			this.NumSheet.main_note := main_note_list[SubStr(r_main_note, 0, 1)]
			this.NumSheet.main_note += up_list[SubStr(r_main_note, 1, 1)]
		}
		this.current_command := old_command
	}
	BEAT(r_b)
	{
		old_command := this.current_command
		this.current_command := "CHANGEBEAT"
		this.current_command := old_command
	}
	JUMP(r_labels)
	{
		; JUMP 命令在 GOTOS 命令执行了
		; 并且 GOTOS 的剩余循环次数为 0 时才执行
		if this.command_flag == 0
		{
			old_command := this.current_command
			this.current_command := "JUMP"
			if old_command == "GOTOS"
				this.play_pos := r_labels[1]
			this.current_command := old_command
		}
		return
	}
	GOTOS(r_labels)
	{
		; 循环命令
		; 相当于
		; DO … WHILE 循环
		; 但是不允许嵌套
		
		; 先检查 this.current_command
		; 如果不是 GOTOS 命令，说明命令是第一次执行
		; 将循环的次数送入 this.command_flag
		; 是 GOTOS 命令时
		; 就每循环一次将循环次数 - 1
		; 循环次数为 0 时跳出循环，
		; 将 this.current_command 置为空
		if (this.current_command == "GOTOS")
		{
			if (this.command_flag == 0)
			{
				this.current_command := ""
			}
			else
			{
				this.play_pos := r_labels[3]
				this.command_flag--
			}
		}
		else
		{
			this.current_command := "GOTOS"
			this.command_flag := r_labels[1]
			this.play_pos := r_labels[3]
			this.command_flag--
		}
		return
	}
	LABELS(r_labels)
	{
		return
	}
	; ==========================命令事件调用函数====================================
	GetNote(offset := 0)
	{
		if (this.NumSheet.command_list[this.command_pos][1][2] == this.play_pos)
		{
			while A_Index <= this.NumSheet.command_list[this.command_pos][1].Count()
			{
				i := A_Index
				for k,v in this.NumSheet.command_list[this.command_pos][i][1]
				{
					this[k](v)
				}
			}
			if (this.current_command != "GOTOS")
				this.command_pos++
		}
		
		;~ temp1 := this.NumSheet.sheet[this.play_pos + offset][1] - 1
		;~ temp2 := this.NumSheet.sheet[this.play_pos + offset][2] * 12
		;~ temp3 := this.play_pos + offset
		a_note := [this.NumSheet.sheet[this.play_pos + offset][1] - 1 + this.NumSheet.sheet[this.play_pos + offset][2] * 12 + this.NumSheet.main_note - 1
			   ,Round(this.beat / this.NumSheet.sheet[this.play_pos+offset][3])]
		
		;MsgBox, % a_note[1] "`n" a_note[2] "ms"
		return a_note
	}
	Play(NumSheet)
	{
		If this.Playing
			Return, this
		
		this.NumSheet := NumSheet
		this.len := NumSheet.len
		this.beat := NumSheet.BPM << 2
		a_note := this.GetNote()
		
		; 初始化，加载缓存 buffer
		; buffer : [[MIDI_pitch, MIDI_duration]+]
		this.play_pos++
		this.BufferCallBack()
		
		this.playing := True
		
		; 初始化, 向 MIDI 设备发送第一个音，并启动定时器
		; 之后的播放由定时器的回调函数完成
		this.playing_note := a_note[1]
		
		this.Device.NoteOn(this.playing_note, 50)

		this.hTimer := DllCall("SetTimer","UPtr",0,"UPtr",0
						  ,"UInt",a_note[2]
						  ,"UPtr",this.pCallback,"UPtr")
		;~ this.buffer.Pop()
		; 定时缓存
		this.hTimer_buffer := DllCall("SetTimer","UPtr",0,"UPtr",0
							    ,"UInt",Round(NumSheet.BPM << 2)										; 每隔一个16分音长度检查一次缓存 buffer
							    ,"UPtr",this.buffer_callback,"UPtr")
		return this
	}
	PlayCallback(x,y,z)
	{
		MIDIPlayer := Object(A_EventInfo)
		If !DllCall("KillTimer","UPtr",0,"UPtr",MIDIPlayer.hTimer)
			throw Exception("Could not destroy update timer.")
		
		duration := MIDIPlayer.buffer[1][2]
		; 缓存不足，先补满缓存
		if (!duration and MIDIPlayer.play_pos != MIDIPlayer.len)
		{
			MIDIPlayer.BufferCallBack()
			duration := MIDIPlayer.buffer[1][2]
		}
		; 指针指到最后停止播放
		
		if (MIDIPlayer.play_pos > MIDIPlayer.len and this.current_command != "GOTOS")
		{
			MIDIPlayer.Device.NoteOff(MIDIPlayer.playing_note, 50)
			MIDIPlayer.playing_note := ""
			MIDIPlayer.buffer := []
			
			MIDIPlayer.playing := False
			if !DllCall("KillTimer","UPtr",0,"UPtr",MIDIPlayer.hTimer_buffer)
				throw Exception("Could not destroy buffer update timer.")
			MIDIPlayer.play_pos := 1
			return
		}
		
		
		MIDIPlayer.Device.NoteOff(MIDIPlayer.playing_note, 50)
		if MIDIPlayer.buffer[1][1] == 0
			goto settime1
		MIDIPlayer.Device.NoteOn(MIDIPlayer.buffer[1][1], 50)
		settime1:
		MIDIPlayer.hTimer := DllCall("SetTimer","UPtr",0,"UPtr",0
							,"UInt",duration
							,"UPtr",MIDIPlayer.pCallback,"UPtr")
		MIDIPlayer.play_pos += 1
		MIDIPlayer.playing_note := MIDIPlayer.buffer[1][1]
		MIDIPlayer.buffer.RemoveAt(1)
		
	}
	BufferCallBack()
	{
		MIDIPlayer := Object(A_EventInfo)
		if !MIDIPlayer
			MIDIPlayer := this
		
		; 如果缓存到谱子最后就直接返回
		if MIDIPlayer.play_pos+buffer_len-1 >= MIDIPlayer.len
			return		
		;~ this.command := MIDIPlayer.NumSheet.command_list[command_pos]
		
		while ((buffer_len := MIDIPlayer.buffer.Count()) < 10)
		{
			if MIDIPlayer.play_pos+buffer_len > MIDIPlayer.len
				Break
			
			a_note := MIDIPlayer.GetNote(buffer_len)
			MIDIPlayer.buffer.Push(a_note)
		}
	}
	Stop()
	{
		If !this.Playing
			Return, this
		if !DllCall("KillTimer","UPtr",0,"UPtr",this.hTimer)
			throw Exception("Could not destroy update timer.")
		if !DllCall("KillTimer","UPtr",0,"UPtr",this.hTimer_buffer)
			throw Exception("Could not destroy buffer update timer.")
		this.Device.NoteOff(this.playing_note,100)
		this.Playing := False
		this.play_pos := 1
		this.buffer := []
		Return, this
	}
	__Delete()
	{
		this.Stop()
		DllCall("GlobalFree","UPtr",this.pCallback)
		DllCall("GlobalFree","UPtr",this.BufferCallBack)
	}
}

class MIDIOutputDevice
{
	static DeviceCount := 0
	__New(DeviceID = 0)
	{
		If MIDIOutputDevice.DeviceCount = 0
		{
			this.hModule := DllCall("LoadLibrary","Str","winmm")
			If !this.hModule
				throw Exception("Could not load WinMM library.")
		}
		MIDIOutputDevice.DeviceCount ++
		hMIDIOutputDevice := 0
		Status := DllCall("winmm\midiOutOpen"
                            ,"UInt*",hMIDIOutputDevice
                            ,"UInt",DeviceID
                            ,"UPtr",0,"UPtr",0,"UInt",0)
		If Status != 0
			throw Exception("Could not open MIDI output device: " . DeviceID . ".")
		this.hMIDIOutputDevice := hMIDIOutputDevice
		this.Channel := 0
		this.Sound := 0
		this.Pitch := 0
	}
	__Get(Key)
	{
		Return, this["_" . Key]
	}
	__Set(Key,Value)
	{
		If (Key = "Channel")
		{
			If Value Not Between 0 And 15
				throw Exception("Invalid channel: " . Value . ".",-1)
		}
		Else If (Key = "Sound")
		{
			If Value Not Between 0 And 127
				throw Exception("Invalid sound: " . Value . ".",-1)
			If DllCall("winmm\midiOutShortMsg","UInt",this.hMIDIOutputDevice,"UInt",0xC0 | this.Channel | (Value << 8))
				throw Exception("Could not send ""Program Change"" message.")
		}
		Else If (Key = "Pitch")
		{
			If (Value < -100)
				Value := -100
			If (Value > 100)
				Value := 100
			TempValue := Round(((Value + 100) / 200) * 0x4000)
			If DllCall("winmm\midiOutShortMsg","UInt",this.hMIDIOutputDevice,"UInt",0xE0 | this.Channel | ((TempValue & 0x7F) << 8) | (TempValue << 9))
				throw Exception("Could not send ""Pitch Bend"" message.")
		}
		ObjInsert(this,"_" . Key,Value)
		Return, Value
	}
	__Delete()
	{
		this.Reset()
		If DllCall("winmm\midiOutClose","UInt",this.hMIDIOutputDevice)
			throw Exception("Could not close MIDI output device.")
		MIDIOutputDevice.DeviceCount --
		If MIDIOutputDevice.DeviceCount = 0
			DllCall("FreeLibrary","UPtr",this.hModule)
	}
	GetVolume(Channel = "")
	{
		Volume := 0
		If DllCall("winmm\midiOutGetVolume","UInt",this.hMIDIOutputDevice,"UInt*",Volume)
			throw Exception("Could not retrieve device volume.")
		If (Channel = "" || Channel = "Left")
			Return, ((Volume & 0xFFFF) / 0xFFFF) * 100
		Else If (Channel = "Right")
			Return, ((Volume >> 16) / 0xFFFF) * 100
		Else
			throw Exception("Invalid channel:" . Channel . ".",-1)
	}
	SetVolume(Volume,Channel = "")
	{
		If Volume Not Between 0 And 100
			throw Exception("Invalid volume: " . Volume . ".",-1)
		If (Channel = "")
			Volume := Round((Volume / 100) * 0xFFFF), Volume |= Volume << 16
		Else If (Channel = "Left")
			Volume := Round((Volume / 100) * 0xFFFF)
		Else If (Channel = "Right")
			Volume := Round((Volume / 100) * 0xFFFF) << 16
		Else
			throw Exception("Invalid channel: " . Channel . ".",-1)
		DllCall("winmm\midiOutSetVolume","UInt",this.hMIDIOutputDevice,"UInt",Volume)
	}
	NoteOn(Note,Velocity)
	{
		If Note Is Not Integer
			throw Exception("Invalid note: " . Note . ".",-1)
		If Velocity Not Between 0 And 100
			throw Exception("Invalid velocity: " . Velocity . ".",-1)
		Velocity := Round((Velocity / 100) * 127)
		If DllCall("winmm\midiOutShortMsg","UInt",this.hMIDIOutputDevice,"UInt",0x90 | this.Channel | (Note << 8) | (Velocity << 16))
			throw Exception("Could not send ""Note On"" message.")
	}
	NoteOff(Note,Velocity)
	{
		If Note Is Not Integer
			throw Exception("Invalid note: " . Note . ".",-1)
		If Velocity Not Between 0 And 100
			throw Exception("Invalid velocity: " . Velocity . ".",-1)
		Velocity := Round((Velocity / 100) * 127)
		If DllCall("winmm\midiOutShortMsg","UInt",this.hMIDIOutputDevice,"UInt",0x80 | this.Channel | (Note << 8) | (Velocity << 16))
			throw Exception("Could not send ""Note Off"" message.")
	}
	UpdateNotePressure(Note,Pressure)
	{
		If Note Is Not Integer
			throw Exception("Invalid note: " . Note . ".",-1)
		If Pressure Not Between 0 And 100
			throw Exception("Invalid pressure: " . Pressure . ".",-1)
		Pressure := Round((Pressure / 100) * 127)
		If DllCall("winmm\midiOutShortMsg","UInt",this.hMIDIOutputDevice,"UInt",0xA0 | this.Channel | (Note << 8) | (Pressure << 16))
			throw Exception("Could not send ""Polyphonic Aftertouch"" message.")
	}
	Reset()
	{
		If DllCall("winmm\midiOutReset","UInt",this.hMIDIOutputDevice)
			throw Exception("Could not reset MIDI output device.")
	}
}

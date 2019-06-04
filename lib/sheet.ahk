; SHEET_AHK

; =================================AHKNMS=======================================
; AHK Version ..: 1.1.30.01 (Unicode 64-bit)
; OS Version ...: Windows 10 
; Author .......: Helsmy jj4156@outlook.com (modified for ahknms) Nigh jiyucheng007@gmail.com (original author)
; Link .........: https://github.com/helsmy/AHKNumberMusicSheet
; License ......: GPLv3.0
; ==============================================================================

class NumSheet
{
	note_dic := {1:1,2:"#1",3:2,4:"#2",5:3,6:4,7:"#4",8:5,9:"#5",10:6,11:"#6",12:7}
	
	__New()
	{
		; sheet        : [[pitch,range,duration], *]
		; command_list : [[command(dict), ordinal], *]
		; music_attr   : [main_note, beat_speed]
		;                main_note   : C = 1 D = 3 ...
		;                beat_speed  : time(ms) = 60s / duration * 1000
		this.sheet := []
		this.command_list := []
		this.len := this.sheet.Count()
		this.BPM := 500
		this.main_note := 1
	}
	
	NSPush(note)
	{
		len := note.Count()
		while(A_Index <= len)
		{
			this.sheet.Push(note[A_Index])
		}
		this.len := this.sheet.MaxIndex()
	}
	
	AddCommand(command_list)
	{
		; push command_list : command, ordinal
		if this.command_list[this.command_list.Count()][1][2] == this.len+1
			this.command_list[this.command_list.Count()].Push([command_list[1],this.len+1])
		else
			this.command_list.Push([[command_list[1],this.len+1]])
	}
	
	GetNote(ordinal := 1)
	{
		return this.sheet[ordinal]
	}
	
	KeyShift(key := 0)
	{
		; 移key
		while(A_Index <= this.len)
		{
			this.sheet[A_Index][1] += key
			if this.sheet[A_Index][1] > 12
			{
				this.sheet[A_Index][1] -= 12
				this.sheet[A_Index][2] += 1
			}
			else if this.sheet[A_Index][1] < 1
			{
				this.sheet[A_Index][1] += 12
				this.sheet[A_Index][2] -= 1
			}
		}
	}
	
	Write()
	{
		; 回写成数字谱
		str_sheet := ""
		while(A_Index <= this.len)
		{
			if this.sheet[A_Index][2] = 3
				str_sheet .= Format("({1:s})", this.note_dic[this.sheet[A_Index][1]])
			else if this.sheet[A_Index][2] = 5
				str_sheet .= Format("[{1:s}]", this.note_dic[this.sheet[A_Index][1]])
			else if this.sheet[A_Index][2] = 4
				str_sheet .= this.note_dic[this.sheet[A_Index][1]]
			else if this.sheet[A_Index][2] = 6
				str_sheet .= Format("{{1:s}}", this.note_dic[this.sheet[A_Index][1]])
			else if this.sheet[A_Index][2] = 2
				str_sheet .= Format("<{1:s}>", this.note_dic[this.sheet[A_Index][1]])
			; 这if用来回写成一样的格式，主要是插入空白字符
			; parser没有写对应于空白字符的解析只是跳过了
			; 所以先注释掉
			; else if this.sheet[A_Index][1] is not digit
			; 	str_sheet .= this.sheet[A_Index][1]
		}
		return str_sheet
	}
}

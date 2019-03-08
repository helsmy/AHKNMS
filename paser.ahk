#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; 声明初始的一些值，这里有点问题
static NOTE, HALFUP, HALFDOWN, RHIGE, LHIGH, RLOW, LLOW, EOF = "INTEGER", "#", "b", "[", "]"， "("， ")", "EOF"

static notelist := ["C", "#C", "D", "#D", "E", "F", "#F", "G", "#G", "A", "#A", "B"]

; 乐谱列表[[12平均律,音区，时值(暂且设置为0)]，...]


class Token(Object)
{
	__new(this, types, values)
	{
		; 这里定义token的类型和值
		this.types := types
		this.values := values
	}
	
	types[]
	{
		get 
		{ 
			return this.types
		}
	}
	
	values[]
	{
		get
		{
			return this.values
		}
	}
}

class Lexer(Object)
{
	__new(this, txt)
	{
		; 这里接受输入的字符串
		this.txt := txt
		; 这里是字符串位置指针
		this.ptr := 0
		; 这里得到现在的字符
		this.current_char := this.txt[this.ptr]
	}
	
	; 这里要定义返回的异常
	; Error(this){ TODO }
	ErrCharIsNotNote(this)
	{
		; 这里可能有点问题
		Throw Exception("InvalidCharacter", -1, Format("Wrong Character in {1:d}", this.ptr))
	}
	
	Advance(this)
	{
		; 用来让指针向前1次
		this.ptr := this.ptr  + 1
		if this.ptr > StrLen(this.txt)
			this.current_char := "" ;ahk没有空值真是有趣，不知道space类型会不会重复判断
		else
			this.current_char := this.txt[this.ptr]
	}
	
	SkipWhitesspace(this)
	{
		; 跳过空白
		while(this.current_char != "" and this.current_char is Space)
			this.Advance()
	}
	
	Int(this)
	{
		;返回一个整数，代表音高，并拒绝超过7的数字，超过7就抛出异常
		result := ""
		
		if this.current_char is integer
			result := Integer(result)
		if result > 7
			this.ErrCharIsNotNote()
		else
			return reslust
	}
	
	GetNextToken(this)
	{
		while(this.current_char != "")
		{
			if this.current_char is Space
			{
				this.SkipWhitesspace()
				Continue
			}
			
			this.Advance()
			
			if this.current_char is Integer
				return Token(NOTE, this.Int())
			
			; 直接返回音区，默认中央C为C4,用 13 这种表示得到开始的符号
			if this.current_char == "("
				return Token(RLOW, 13)
			
			if this.current_char == ")"
				return Token(LLOW, 3)
			
			if this.current_char == "["
				return Token(RHIGH, 15)
			
			if this.current_char == "]"
				return Token(LHIGH, 5)
			
			; 直接返回数字这样方便后续直接计算音高
			if this.current_char == "#"
				return Token(HALFUP, 1)
			
			if this.current_char == "b"
				return Token(HALFDOWN, -1)
		}
		
		return Token(EOF, "")
	}
}

class Paser(Object)
{
	__new(this, lexer)
	{
		this.lexer := lexer
		; 将当前的token设置到输入的第一个
		this.current_token := this.lexer.GetNextToken()
		this.paern_finish = 0
	}
	
	ErrInvalidSyntax(this)
	{
		Throw Exception("InvalidSyntax",-1,this.ptr)
	}
	
	Eat(this, TokenTypes)
	{
		; 对比得到的类型，相符就消费掉，不符就抛出异常
		if this.current_token == TokenTypes
			this.current_token = this.lexer.GetNextToken()
		else
			this.ErrInvalidSyntax()
	}
	
	Pitch(this)
	{
		; 音高  ： NUMBER  
		token := this.current_token
		if token.types == NOTE
		{
			this.Eat(NOTE)
			return Token.values
		}
	}
	
	Notes(this)
	{
		; 音区 ： 括号  只在右括号的时候返回感觉有点隐患，抛出个语法错误异常好了
		
		if token.types == RHIGE
		{
			this.Eat(RHIGE)
			this.paern_finish = 1
		}
		else if token.types == LHIGH
		{
			this.Eat(LHIGH)
			this.paern_finish = 0
			return [Pitch(), token.values]
		}
		else if token.types == RLOW
		{
			this.Eat(RLOW)
			this.paern_finish = 0
		}
		else if token.types == LLOW
		{
			this.Eat(LLOW)
			this.paern_finish = 1
			return [Pitch(), token.values]
		}
		
		if this.paern_finish == 0
			this.ErrInvalidSyntax()
		
	}
	
	Sheet(this)
	{
		
		result := []
		
		while(this.current_token.types != EOF)
		{
			token := this.current_token
			result.Insert([this.Notes(), 0])
		}
		
		return result
	}
}

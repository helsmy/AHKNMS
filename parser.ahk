global LHIGH := "[", RHIGH := "]", NOTE := "INT", EOF := "EOF", LLOW := "(", RLOW := ")"
; MsgBox, % Format("global LHIGH : {1:s} RHIGH : {2:s}", LHIGH, RHIGH)
class Token
{
    __New(atypes, avalues)
    {
        ; 这里定义token的类型和值
        this.types := atypes
        this.values := avalues
    }
}

class Lexer
{
    __New(str)
    {
        this.str := str
        this.ptr := 1
        this.current_char := SubStr(this.str, 1, 1)
    }
    
    SkipWhitesspace()
    {
        ; 跳过空白
        msgbox, SkipWhitesspace called
        this.Advance()
        msgbox, SkipWhitesspace Advance called
    }
    
    Advance()
    {
        ; 用来让指针向前1次
        this.ptr := this.ptr  + 1
        if this.ptr > StrLen(this.str)
            this.current_char := "" ; ahk没有空值真是有趣，不知道space类型会不会重复判断
        else
            this.current_char := SubStr(this.str, this.ptr, 1)
    }
    
    GetNextToken()
    {
        magic1:
        cc := this.current_char
        t := New Token("", "")
        
        while(cc != "")
        {
            if cc is Space
            {
                this.Advance()
                goto magic1        ; 我用goto我有罪，是我太菜了
            }
            
            if cc is digit
            {
                this.Advance()
                t.types := NOTE
                
            }
            ; 直接返回音区，默认中央C为C4,用 13 这种表示得到开始的符号
            
            if(cc = LHIGH)
            {
                this.Advance()
                t.types := LHIGH
            }
            
            if(cc == RHIGH)
            {
                t.types := RHIGH
            }
            
            if(cc == LLOW)
            {
                this.Advance()
                t.types := LLOW
            }
            
            if(cc == RLOW)
            {
                this.Advance()
                t.types := RLOW
            }
            
            t.values := cc
            return t
        }
        t.types := EOF
        t.values := ""
        return t
    }
}

class Parser
{
    __New(str)
    {
        this.lexer := new Lexer(str)
        this.current_char := this.lexer.GetNextToken()
    }
    
    ErrInvalidSyntax()
    {
        Throw Exception("InvalidSyntax", -1, Format("Wrong Character in {1:d} {2:s}", this.lexer.ptr, SubStr(this.txt, this.lexer.ptr, 3)))
    }
    
    Eat(TokenTypes)
    {
        ; 对比得到的类型，相符就消费掉，不符就抛出异常
        if this.current_char.types == TokenTypes
            this.current_char := this.lexer.GetNextToken()
        else
            this.ErrInvalidSyntax()
    }
    
    Pitch(ranges := 4)
    {
        ; 音高  ： NUMBER  
        token := this.current_char
        if(token.types == NOTE)
        {
            this.Eat(NOTE)
            r := [token.values, ranges, 0]
            return r
        }
    }
    
    Notes()
    {
        ; 音区 ： 括号  
        token := this.current_char
        result := []
        if token.types == LHIGH
        {
            this.Eat(LHIGH)
            result := this.Pitch(5)
            this.Eat(RHIGH)
        }
        else if token.types == LLOW
        {
            this.Eat(LLOW)
            result := this.Pitch(3)
            this.Eat(RLOW)
        }
        else if token.types == NOTE
        {
            result := this.Pitch(4)
        }
        return result
    }
    
    Sheet()
    {
        result := []
        while(this.current_char.types != EOF)
        {
            n := this.Notes()
            result.Push(n)
        }
        return result
    }
}

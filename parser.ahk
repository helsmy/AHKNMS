; PARSER_AHK

#Include sheet.ahk

global LHIGH := "[", RHIGH := "]", NOTE := "INT", EOF := "EOF", LLOW := "(", RLOW := ")", HALFUP := 1, HALFDOWN := -1

; stand form : notelist := [[pitch, range, duration], ...]
; duration 还没有实现格式与解析先置0
; duration is temporarily set to 0

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
        this.char_list := {LHIGH: "[", RHIGH: "]", LLOW: "(", RLOW: ")", 1: "#", -1: "b", NOTE: "INT", EOF: "EOF"}
        this.ptr := 1
        this.current_char := SubStr(this.str, 1, 1)
    }
    
    ErrInvalidchar()
    {
        Throw Exception("InvalidCharacter", -1, this.ptr)
    }
    
    SkipWhitesspace()
    {
        ; 跳过空白
        this.Advance()
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
        refresh:
        cc := this.current_char
        t := New Token("", "")
        
        while(cc != "")
        {
            if cc is Space
            {
                this.Advance()
                goto refresh        ; 我用goto我有罪，是我太菜了
            }
            
            else if cc is digit
            {
                this.Advance()
                t.types := NOTE
                
            }
            ; 直接返回音区，默认中央C为C4
            
            else
            {
                for k,v in this.char_list
                {
                    if(v == this.current_char)
                    {
                        this.Advance()
                        t.types := k
                        goto setvalue    ; 我用goto我有罪，是我太菜了
                    }
                }
                this.ErrInvalidchar()
            }
            setvalue:
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
        this.note_dic := {1:1, 2:3, 3:5, 4:6, 5:8, 6:10, 7:12}
    }
    
    ErrInvalidSyntax()
    {
        Throw Exception("InvalidSyntax", -1, Format("Wrong Character in {1:d} SubString : {2:s} {3:s}", this.lexer.ptr-1, SubStr(this.lexer.str, this.lexer.ptr-1, 3), this.current_char.types))
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
        ; 音高  ： NUMBER | (#|b)NUMBER 
        token := this.current_char
        half_pitch := 0
        r := []
        while(token.types == "1"||token.types == "-1"||token.types == NOTE)
        {
            if(token.types == "1"||token.types == "-1")
            {
                this.Eat(token.types)
                half_pitch := token.types  ; 这里让临时升降记号的types值等于对应的升降半音（1 / -1）
                token := this.current_char ; 更新token的值，让它指向下一个字符，这个字符应该为数字
            }            
            this.Eat(NOTE)
            r.Push([this.note_dic[token.values] + half_pitch, ranges, 0])
            token := this.current_char ; 更新token的值，让它指向下一个字符，这个字符应该为数字
        }
        return r
    }
    
    Notes()
    {
        ; 音区 ： [PITCH, PITCH, ...] | (PITCH, PITCH, ...)
        result := []
        if this.current_char.types == "LHIGH"
        {
            this.Eat("LHIGH")
            result := this.Pitch(5)
            this.Eat("RHIGH")
        }
        else if this.current_char.types == "LLOW"
        {
            this.Eat("LLOW")
            result := this.Pitch(3)
            this.Eat("RLOW")
        }
        else ; if this.current_char.types == NOTE||HALFUP||HALFDOWN
        {
            result := this.Pitch(4)
        }
        return result
    }
    
    Sheet()
    {
        result := new NumSheet()
        while(this.current_char.types != EOF)
        {
            n := this.Notes()
            result.NSPush(n)
        }
        return result
    }
}

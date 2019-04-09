#Include sheet.ahk

global LHIGH := "LHIGH", RHIGH := "RHIGH", NOTE := "INT", EOF := "EOF", LLOW := "LLOW", RLOW := "RLOW"
    , HALFUP := 1, HALFDOWN := -1, LDHIGH := "LDHIGH", RDHIGH := "RDHIGH"
    , LDLOW := "LDLOW", RDLOW := "RDLOW", ASSIGN := "ASSIGN", BEGIN := "BEGIN", END := "END"

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

global RESERVED_KEYWORDS := {BEGIN: new Token("BEGIN", "BEGIN"), END: new Token("END", "END")}

class Lexer
{
    __New(str)
    {
        this.str := str
        this.char_list := {"[": "LHIGH", "]": "RHIGH", "(": "LLOW", ")": "RLOW", "#": "1", "b": "-1", "{": "LDHIGH", "}" : "RDHIGH", "<" : "LDLOW", ">" : "RDLOW", "=": "ASSIGN", "/": "SLASH"}
        this.ptr := 1
        this.current_char := SubStr(this.str, 1, 1)
    }
    
    ErrInvalidchar()
    {
        Throw Exception("InvalidCharacter", -1, Format("Wrong Character in {1:d} SubString : {2:s} {3:s}", this.ptr-1, SubStr(this.str, this.ptr-1, 3), this.current_char.types))
    }
    
    SkipWhitesspace()
    {
        ; 跳过空白
        this.Advance()
    }
    
    Advance()
    {
        ; 用来让指针向前1次
        this.ptr += 1
        if this.ptr > StrLen(this.str)
            this.current_char := "" ; ahk没有空值真是有趣，不知道space类型会不会重复判断
        else
            this.current_char := SubStr(this.str, this.ptr, 1)
    }
    
    Num()
    {
        ; 将数字字符转换成数字
        r := ""
        cc := this.current_char
        while(1)    
        {
            if cc is digit
            {
                r .= this.current_char
                this.Advance()
                cc := this.current_char
            }
            else
                break
        }
        return new Token("INT", r)
    }
    
    _id()
    {
        ; 处理保留关键字和标识符
        result := ""
        while 1
        {
            cc := this.current_char
            if cc is space                            ; 所以为什么一定要建一个新变量才能判断
                break                
            else
            {
                if cc is alpha                        ; 这里又可以不用，迷
                {
                    result .= this.current_char
                    this.Advance()
                }
                else
                    break
            }
        }
        t := RESERVED_KEYWORDS[result]
        if t.types == ""
            return new Token("ID", result)
        else
            return t
    }
    
    GetNextToken()
    {
        while((cc := this.current_char) != "")
        {
            if cc is Space
            {
                this.Advance()
            }
            
            else if cc is alpha
                return this._id()
            
            else if cc is digit
            {
                this.Advance()
                return new Token(NOTE, cc)
            }
            
            else
            {
                t := this.char_list[cc]
                if t is Space
                    this.ErrInvalidchar()
                else
                {
                    this.Advance()
                    return new token(t, cc)
                }
            }
        }
        return new Token(EOF, "")
    }
    
    StatementGNT()
    {
        ; 声明语句块专用的get_next_token
        cc := this.current_char
        while InStr(" `t`r`n", cc)
        {
            this.Advance()
            cc := this.current_char
        }
        if cc is digit
            return this.Num()
        else
            return this.GetNextToken()
    }
}

class Parser
{
    __New()
    {
        this.note_dic := {1:1, 2:3, 3:5, 4:6, 5:8, 6:10, 7:12}
    }
    
    ErrInvalidSyntax(Expect := "")
    {
        Throw Exception("InvalidSyntax", -1, Format("{4:s} Wrong Character in {1:d} SubString : {2:s} {3:s}", this.lexer.ptr-1, SubStr(this.lexer.str, this.lexer.ptr-1, 3), this.current_char.types, Expect))
    }
    
    Eat(TokenTypes)
    {
        ; 对比得到的类型，相符就消费掉，不符就抛出异常
        if this.current_char.types == TokenTypes
            this.current_char := this.lexer.GetNextToken()
        else
            this.ErrInvalidSyntax(TokenTypes)
    }
    
    StatementEat(TokenTypes)
    {
        ; 声明用的 Eat
        if this.current_char.types == TokenTypes
            this.current_char := this.lexer.StatementGNT()
        else
            this.ErrInvalidSyntax(TokenTypes)
        
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
        if this.current_char.types == LHIGH
        {
            this.Eat(LHIGH)
            result := this.Pitch(5)
            this.Eat(RHIGH)
        }
        else if this.current_char.types == LLOW
        {
            this.Eat(LLOW)
            result := this.Pitch(3)
            this.Eat(RLOW)
        }
        else if this.current_char.types == LDHIGH
        {
            this.Eat(LDHIGH)
            result := this.Pitch(6)
            this.Eat(RDHIGH)
        }
        else if this.current_char.types == LDLOW
        {
            this.Eat(LDLOW)
            result := this.Pitch(2)
            this.Eat(RDLOW)
        }
        else ; if this.current_char.types == NOTE||HALFUP||HALFDOWN
        {
            result := this.Pitch(4)
        }
        return result
    }
    
    Expr()
    {
        ; expr : INT
        r := this.current_char.values
        this.StatementEat("INT")
        return r
    }
    
    Variable()
    {
        ; variable : ID
        r := this.current_char.values
        this.StatementEat("ID")
        return r
    }
    
    AssignmentStatement()
    {
        ; assignment_statement : variable ASSIGN expr
        ; 复用 Token 表示变量关系
        L_OP := this.Variable()
        this.StatementEat(ASSIGN)
        R_OP := this.Expr()
        return new Token(L_OP, R_OP)
    }
    
    ShStatement()
    {
        ; Sheet another statement : 1 ASSIGN ID : 1=C
        ;                         | INT SLASH INT : 4/4
        num1 := this.Expr()
        if this.current_char.types == ASSIGN && num1 == 1
        {
            this.StatementEat(ASSIGN)
            main_note := this.Variable()
            return new Token("DO", main_note)
        }
        this.StatementEat("SLASH")
        num2 := this.Expr()
        return new Token("BEAT", Format("{1:s}/{2:s}", num1, num2))
    }
    
    Statement()
    {
        ; statement : assignment_statement : BPM = 120
        ;           | empty
        ;           | 4/4
        if this.current_char.types == "ID"
            r := this.AssignmentStatement()
        else if this.current_char.types == "INT"
            r := this.ShStatement()
        else
            r := this.Empty()
        return r
    }
    
    StatementList()
    {
        ; statement_list : statement
        r := []
        while this.current_char.types != "END"
            r.push(this.Statement())
        
        if this.current_char.types == "ID"
            this.ErrInvalidSyntax()
        
        return r
    }
    
    MusicAttr()
    {
        ; 解析 compound_statement 式的调式声明 : BEGIN statement_list END
        ; 返回乐谱的调性等属性
        ; MusicAttr_list : ["MA", [调式, 速度, 拍号], 0]
        this.StatementEat(BEGIN)
        r := this.StatementList()
        this.Eat(END)
        MusicAttr_list := ["MA", ["C", 120, "4/4"], 0]
        while A_INDEX <= r.Count()
        {
            ; MsgBox, % r[A_Index].values
            if r[A_Index].types == "BPM"
                MusicAttr_list[2][2] := r[A_Index].values
            if r[A_Index].types == "BEAT"
                MusicAttr_list[2][3] := r[A_Index].values
            if r[A_Index].types == "DO"
                MusicAttr_list[2][1] := r[A_Index].values
        }
        return [MusicAttr_list]
    }
    
    Sheet()
    {
        result := new NumSheet()
        while(this.current_char.types != EOF)
        {
            if this.current_char.types == BEGIN
                n := this.MusicAttr()
            else
                n := this.Notes()
            result.NSPush(n)
        }
        return result
    }
    
    NSParse(str)
    {
        this.lexer := new Lexer(str)
        this.current_char := this.lexer.GetNextToken()
        r := this.Sheet()
        return r
    }
}

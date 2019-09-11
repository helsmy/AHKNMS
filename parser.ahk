; PARSER_AHK
; stand form : notelist := [[pitch, range, duration], ...]
; stand form : command_list := [[[command(dict), ordinal], ...]]

#Include sheet.ahk


global LHIGH := "LHIGH", RHIGH := "RHIGH", NOTE := "INT", EOF := "EOF", LLOW := "LLOW", RLOW := "RLOW", HALFUP := 1, HALFDOWN := -1, LDHIGH := "LDHIGH", RDHIGH := "RDHIGH"
global LDLOW := "LDLOW", RDLOW := "RDLOW"

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

global RESERVED_KEYWORDS := {BEGIN: new Token("BEGIN", "BEGIN")
                        , END: new Token("END", "END")
                        , "goto": new Token("GOTO", "goto")
                        , jump: new Token("JUMP", "jump")}

class Lexer
{
    __New(str)
    {
        this.str := str
        this.char_list := {"[": "LHIGH", "]": "RHIGH", "(": "LLOW", ")": "RLOW", "#": "1", "b": "-1"
                        , "{": "LDHIGH", "}" : "RDHIGH", "<" : "LDLOW", ">" : "RDLOW", "=": "ASSIGN"
                        , "'": "EIGHTH", """": "SIXTEENTH", "-": "SUSTAIN", "|": "TONE", "\": "BSLASH"
                        , "/": "SLASH", "@": "TAGSTART", ":": "TAGEND",";": "COMMENT"}
        this.ptr := 1
        this.current_char := SubStr(this.str, 1, 1)
    }
    
    ErrInvalidchar()
    {
        Throw Exception("InvalidCharacter"
                        , -1
                        , Format("Wrong Character in {1:d} SubString : {2:s} {3:s}"
                            , this.ptr-1
                            , SubStr(this.str, this.ptr-1, 3)
                            , this.current_char.types))
    }
    
    SkipWhitesspace()
    {
        ; 跳过空白
        this.Advance()
    }
    
    SkipCommnent()
    {
        while this.current_char != "`n"
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
        while((cc := this.current_char) != "")
        {
            if cc is digit
            {
                r .= this.current_char
                this.Advance()
            }
            else
                break
        }
        return new Token("INT", r)
    }
    
    Sustain()
    {
        ; 处理全音符和2分音符 ：- | ---
        if SubStr(this.str, this.ptr+1, 2) == "--"
        {
            this.Advance()
            this.Advance()
            this.Advance()
            return new Token("FULL", "---")
        }
        else
        {
            this.Advance()
            return new Token("HALF", "-")
        }
    }
    
    _id()
    {
        ; 处理保留关键字和标识符
        result := ""
        while(cc := this.current_char)
        {
            if cc is space                            ; 所以为什么一定要建一个新变量才能判断
                break                
            else if cc is alpha    
            {
                result .= this.current_char
                this.Advance()
            }
            else if cc is NUMBER
            {
                result .= this.current_char
                this.Advance()
            }
            else
                break
        }
        t := RESERVED_KEYWORDS[result]
        if t.types = ""
            return new Token("ID", result)
        else
            return t
    }
    
    GetNextToken()
    {

        refresh:
        cc := this.current_char
        
        while(cc != "")
        {
            if cc is Space
            {
                this.Advance()
            }
            
            else if Instr(";", cc)
                this.SkipCommnent()
            
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
}

class Parser
{
    __New()
    {
        this.note_dic := {1:1, 2:3, 3:5, 4:6, 5:8, 6:10, 7:12}
        this.duration_dic := {"EIGHTH": 8, "SIXTEENTH": 16, "FULL": 1, "HALF": 2}
    }
    
    ErrInvalidSyntax(Expect := "")
    {
        Throw Exception("InvalidSyntax"
                        , -1
                        , Format("Expcet: {4:s} token: {3:s} Wrong Character in {1:d} SubString : {2:s} "
                            , this.lexer.ptr-1
                            , SubStr(this.lexer.str, this.lexer.ptr-1, 3)
                            , this.current_char.types
                            , Expect))
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
    
    Pitch(ranges := 4, duration := 4)
    {
        ; 音高  ： NUMBER* | (#|b)NUMBER* 
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
            r.Push([this.note_dic[token.values] + half_pitch, ranges, duration])
            token := this.current_char ; 更新token的值，让它指向下一个字符，这个字符应该为数字
        }
        return r
    }
    
    Ranges(duration := 4)
    {
        ; 音区 ： [PITCH, PITCH, ...] | (PITCH, PITCH, ...)  
        result := []
        if this.current_char.types == LHIGH
        {
            this.Eat(LHIGH)
            result := this.Pitch(5, duration)
            this.Eat(RHIGH)
        }
        else if this.current_char.types == LLOW
        {
            this.Eat(LLOW)
            result := this.Pitch(3, duration)
            this.Eat(RLOW)
        }
        else if this.current_char.types == LDHIGH
        {
            this.Eat(LDHIGH)
            result := this.Pitch(6, duration)
            this.Eat(RDHIGH)
        }
        else if this.current_char.types == LDLOW
        {
            this.Eat(LDLOW)
            result := this.Pitch(2, duration)
            this.Eat(RDLOW)
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
            result := this.Pitch(4, duration)
        }
        return result
    }
    
    Notes(t_num := 2)
    {
        ; 处理时值 : duration note* duration
        ;          | note duration
        ; 值是具体时间的倒数，如四分音符的值为 4
        result := []
        t := this.current_char.types
        
        if this.duration_dic.HasKey(t)
        {
            this.Eat(t)
            result := this.Ranges(SubStr(this.duration_dic[t]/2*t_num, 1, 1))
            this.Eat(t)
        }
        else if t == "TONE"
        {
            ; 处理连音，把时值除 2 乘 3
            ; TONE INT TONE NOTE* TONE 
            ; 其实可以完全不需要递归的写法的
            ; 但是我不想再写个函数了
            this.Eat("TONE")
            ; 这个量代表是几连音，为 2 时就是正常节奏
            t_num := this.current_char.values
            this.Eat("INT")
            this.Eat("TONE")
            result := this.Notes(t_num)
            this.Eat("TONE")
        }
        else if this.current_char.types == SLASH
        {
            ; 处理延音符号
            ; 右结合运算 : SLASH NOTE1 NOTE2
            ; note1 和 note2 如果是同一个音高合并为一个音
            ; 递归调用 因为之后每个都是一个完整的音符
            ; 这里应该是这个解析器唯一的递归下降部分吧 XD
            this.Eat(SLASH)
            result := this.Notes()                ; 这个result一遇到非数字字符就停下了啊，所以你还是要写个if看一下长度，永远怀念越界错误
            if result.Count() < 2
            {
                t := this.Notes()
                while A_Index <= t.Count()
                    result.push(t[A_Index])
            }
            if result[1][1] == result[2][1]
            {
                result[1][3] .= result[2][3]
                result.RemoveAt(2)
            }
        }
        else
        {
            ; 全音和2分音符号只影响前面的一个音符
            ; 所以只要最后修改最后一个音的时值即可
            ; 一般应该没有全音符3连音这种写法的吧
            ; 所有时值的符号都位于最外
            ; 余下的情况都要查看下一个 token 是不是延音符
            result := this.Ranges()
            if InStr("FULL" . "HALF", this.current_char.types)
            {
                result[result.Count()][3] := this.duration_dic[this.current_char.types]
                this.Eat(this.current_char.types)
            }
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
    
    Empty()
    {
        return "empty"
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
        ; Sheet other statement : 1 ASSIGN ID : 1=C
        ;                       | INT SLASH INT : 4/4
        num1 := this.Expr()
        main_note := ""
        if this.current_char.types == ASSIGN && num1 == 1
        {
            this.StatementEat(ASSIGN)
            if InStr("1" . "-1", this.current_char.types)
            {
                main_note .= this.current_char.values
                this.StatementEat(this.current_char.types)
            }
            main_note .= this.Variable()
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
        ;           | Sheet other statement
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
        ; MusicAttr_list : {调式, 速度, 拍号}
        this.StatementEat(BEGIN)
        r := this.StatementList()
        this.Eat(END)
        MusicAttr_list := {DO: "", BPM: "", BEAT: ""}
        while A_INDEX <= r.Count()
        {
            if r[A_Index].types == "BPM"
                MusicAttr_list["BPM"] := r[A_Index].values
            if r[A_Index].types == "BEAT"
                MusicAttr_list["BEAT"] := r[A_Index].values
            if r[A_Index].types == "DO"
                MusicAttr_list["DO"] := r[A_Index].values
        }
        return [MusicAttr_list]
    }
    
    Tag()
    { 
        ; 处理速度声明和拍号声明 TAG
        ; 下一个  TOKEN 为 SLASH 时认为是一个拍号声明 TAG
        ; 否则认为是一个速度声明 TAG
        if this.current_char.types =="INT"
        {
            tag_n1 := this.current_char.values
            this.StatementEat("INT")
            if this.current_char.types =="SLASH"
            {
                this.StatementEat("SLASH")
                tag_n2 := this.current_char.values
                this.StatementEat("INT")
                return new Token("BEAT", Format("{1:s}/{2:s}", tag_n1, tag_n2))
            }
            return new Token("BPM", tag_n1)
        }
        ; 处理 ID 型 TOKEN 
        ; 如果长度为 1 且在 A-G 中认为是调式声明 TAG
        ; 否则认为这个 TAG 是一个 LABEL
        else if this.current_char.types =="ID"
        {
            v := this.current_char.values
            this.StatementEat("ID")
            if StrLen(v) == 1
                return new Token("DO", v)
            else 
                return new Token("LABEL", v)
        }
        ; 处理临时升降号
        ; 和后一个长度为 1 的 ID 合并成一个调式声明 TAG
        else if InStr("1" . "-1", this.current_char.types)
        {
            v := this.current_char.values
            this.StatementEat(this.current_char.types)
            v .= this.current_char.values
            this.StatementEat("ID")
            return new Token("DO", v)
        }
        ; 处理 GOTO 类型的TOKEN
        ; 返回一个 GOTO 命令 TAG
        ; GOTO 命令形式 : GOTO LABEL INT
        ; INT 为 1 时可以省略不写
        else if this.current_char.types == "GOTO"
        {
            this.StatementEat("GOTO")
            label_name := this.current_char.values
            this.StatementEat("ID")
            if this.current_char.types == "INT"
            {
                repeat_num := this.current_char.values
                this.StatementEat("INT")
            }
            else
                repeat_num := 1
            return new Token("GOTO", repeat_num . "|" . label_name)
        }
        ; 处理 JUMP 类型的 Token
        ; 返回 JUMP 命令 TAG
        ; JUMP 命令形式 : JUMP LABEL
        else if this.current_char.types == "JUMP"
        {
            this.StatementEat("JUMP")
            label_name :=this.current_char.values
            this.StatementEat("ID")
            return new Token("JUMP", label_name)
        }
    }
    
    TagList()
    {
        ; statement_list : statement
        r := []
        while this.current_char.types != "TAGEND"
            r.push(this.Tag())
        
        if this.current_char.types == "ID"
            this.ErrInvalidSyntax()
        
        return r
    }
    
    ShortTag()
    {
        ; 解析 short_tag : @ tag* :
        ; 先实现返回乐谱的调性等属性的功能 : @ SHORT_TAG* :
        ; tag_command_list : [{tag_types: tag_values, *}]
        this.StatementEat("TAGSTART")
        r := this.TagList()
        this.Eat("TAGEND")
        tag_command_list := {}
        while A_INDEX <= r.Count()
        {
            tag_command_list[r[A_INDEX].types] := r[A_INDEX].values
        }
        return [tag_command_list]
    }
    
    Sheet()
    {
        result := new NumSheet()
        while(this.current_char.types != EOF)
        {
            if this.current_char.types == BEGIN
                result.AddCommand(this.MusicAttr())
            else if this.current_char.types == "TAGSTART"
                result.AddCommand(this.ShortTag())
            else
                result.NSPush(this.Notes())
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

; SHEET_AHK
; class for Music Sheet

; TODO 
; write function for range 2 and 6
; 实现对于音区为 2 和 6 的write函数
; 因为 parser 里面没有写解析这两个音区的函数
; 软件生成的谱软件自己解析不了就十分尴尬了
; 但 KeyShift 里面会涉及

class NumSheet
{
    ; 乐谱类
    __New(s := "")
    {
        this.sheet := s
        this.KeyShift()
    }
    
    GetNote(ordinal := 1)
    {
        return this.sheet[ordinal]
    }
    
    KeyShift(key := 0)
    {
        ; 移key
        len := this.sheet.Count()
        while(A_Index <= len)
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
        len := this.sheet.Count()
        while(A_Index <= len)
        {
            if this.sheet[A_Index][2] = 3
                str_sheet .= Format("({1:s})", this.sheet[A_Index][1])
            else if this.sheet[A_Index][2] = 5
                str_sheet .= Format("[{1:s}]", this.sheet[A_Index][1])
            else if this.sheet[A_Index][2] = 4
                str_sheet .= this.sheet[A_Index][1]
            ; 这if用来回写成一样的格式，主要是插入空白字符
            ; parser没有写对应于空白字符的解析只是跳过了
            ; 所以先注释掉
            ; else if this.sheet[A_Index][1] is not digit
            ;     str_sheet .= this.sheet[A_Index][1]
        }
        return str_sheet
    }
}

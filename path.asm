.ORIG x3000

; --- Main Program ---
; Initialize Stack Pointer (R6)
LD R6, STACK_START
; Initialize Frame Pointer (R5) to 0 to avoid simulator error
AND R5, R5, #0

; Load x and y
LDI R0, ADDR_X      ; Load x from x3100
LDI R1, ADDR_Y      ; Load y from x3101

; Call p(x, y)
; Push Space for Return Value
ADD R6, R6, #-1

; Push y (2nd argument)
ADD R6, R6, #-1
STR R1, R6, #0

; Push x (1st argument)
ADD R6, R6, #-1
STR R0, R6, #0

; Call p
JSR P_FUNC

; Pop Return Value and Arguments
LDR R0, R6, #2      ; Load return value (at R6+2)
ADD R6, R6, #3      ; Pop Arg1, Arg2, RV

; Store Result
STI R0, ADDR_RES    ; Store result to x3200

HALT

; --- Data for Main ---
STACK_START .FILL x4000
ADDR_X      .FILL x3100
ADDR_Y      .FILL x3101
ADDR_RES    .FILL x3200

; --- Function s(i, j) ---
; Returns i + j
; Stack Frame:
; R5+0: Saved R5
; R5+1: Saved R7
; R5+2: Arg1 (i)
; R5+3: Arg2 (j)
; R5+4: RV
S_FUNC
    ; Prologue
    ADD R6, R6, #-1
    STR R7, R6, #0      ; Push R7
    ADD R6, R6, #-1
    STR R5, R6, #0      ; Push R5
    ADD R5, R6, #0      ; Set Frame Pointer

    ; Body
    LDR R0, R5, #2      ; Load i (Arg 1)
    LDR R1, R5, #3      ; Load j (Arg 2)
    ADD R0, R0, R1      ; R0 = i + j

    ; Store Return Value
    STR R0, R5, #4      ; Store at RV slot (R5 + 4)

    ; Epilogue
    LDR R5, R6, #0      ; Pop R5
    ADD R6, R6, #1
    LDR R7, R6, #0      ; Pop R7
    ADD R6, R6, #1
    RET

; --- Function r(i, j) ---
; Returns 1 if i==0 or j==0, else r(i-1, j) + r(i, j-1)
R_FUNC
    ; Prologue
    ADD R6, R6, #-1
    STR R7, R6, #0
    ADD R6, R6, #-1
    STR R5, R6, #0
    ADD R5, R6, #0

    ; Check Base Cases
    LDR R0, R5, #2      ; Load i
    BRz BASE_CASE       ; if i == 0, return 1
    LDR R1, R5, #3      ; Load j
    BRz BASE_CASE       ; if j == 0, return 1

    ; Recursive Step
    ; Call r(i-1, j)
    ADD R6, R6, #-1     ; Push Space for RV
    LDR R1, R5, #3      ; Load j
    ADD R6, R6, #-1
    STR R1, R6, #0      ; Push j
    LDR R0, R5, #2      ; Load i
    ADD R0, R0, #-1     ; i - 1
    ADD R6, R6, #-1
    STR R0, R6, #0      ; Push i-1
    JSR R_FUNC
    LDR R2, R6, #2      ; Load result of r(i-1, j) into R2
    ADD R6, R6, #3      ; Pop RV, Arg1, Arg2
    
    ; Save R2 (result of first call) on stack
    ADD R6, R6, #-1
    STR R2, R6, #0

    ; Call r(i, j-1)
    ADD R6, R6, #-1     ; Push Space for RV
    LDR R1, R5, #3      ; Load j
    ADD R1, R1, #-1     ; j - 1
    ADD R6, R6, #-1
    STR R1, R6, #0      ; Push j-1
    LDR R0, R5, #2      ; Load i
    ADD R6, R6, #-1
    STR R0, R6, #0      ; Push i
    JSR R_FUNC
    LDR R3, R6, #2      ; Load result of r(i, j-1) into R3
    ADD R6, R6, #3      ; Pop RV, Arg1, Arg2

    ; Restore R2
    LDR R2, R6, #0
    ADD R6, R6, #1

    ; Add results
    ADD R0, R2, R3      ; R0 = r(i-1, j) + r(i, j-1)
    STR R0, R5, #4      ; Store Return Value
    BR TEARDOWN_R

BASE_CASE
    AND R0, R0, #0
    ADD R0, R0, #1      ; R0 = 1
    STR R0, R5, #4      ; Store Return Value

TEARDOWN_R
    ; Epilogue
    LDR R5, R6, #0
    ADD R6, R6, #1
    LDR R7, R6, #0
    ADD R6, R6, #1
    RET

; --- Function p(i, j) ---
; Returns 5*r(i, j) - s(i, j)
P_FUNC
    ; Prologue
    ADD R6, R6, #-1
    STR R7, R6, #0
    ADD R6, R6, #-1
    STR R5, R6, #0
    ADD R5, R6, #0

    ; Call r(i, j)
    ADD R6, R6, #-1     ; Push Space for RV
    LDR R1, R5, #3      ; Load j
    ADD R6, R6, #-1
    STR R1, R6, #0      ; Push j
    LDR R0, R5, #2      ; Load i
    ADD R6, R6, #-1
    STR R0, R6, #0      ; Push i
    JSR R_FUNC
    LDR R0, R6, #2      ; Load result r(i, j)
    ADD R6, R6, #3      ; Pop RV, args

    ; Calculate 5 * r(i, j)
    ADD R1, R0, R0      ; 2*r
    ADD R1, R1, R1      ; 4*r
    ADD R0, R1, R0      ; 5*r

    ; Save 5*r on stack
    ADD R6, R6, #-1
    STR R0, R6, #0

    ; Call s(i, j)
    ADD R6, R6, #-1     ; Push Space for RV
    LDR R1, R5, #3      ; Load j
    ADD R6, R6, #-1
    STR R1, R6, #0      ; Push j
    LDR R0, R5, #2      ; Load i
    ADD R6, R6, #-1
    STR R0, R6, #0      ; Push i
    JSR S_FUNC
    LDR R1, R6, #2      ; Load result s(i, j)
    ADD R6, R6, #3      ; Pop RV, args

    ; Restore 5*r
    LDR R0, R6, #0
    ADD R6, R6, #1

    ; Calculate 5*r - s
    NOT R1, R1
    ADD R1, R1, #1      ; -s
    ADD R0, R0, R1      ; 5*r - s

    ; Store Return Value
    STR R0, R5, #4

    ; Epilogue
    LDR R5, R6, #0
    ADD R6, R6, #1
    LDR R7, R6, #0
    ADD R6, R6, #1
    RET

.END



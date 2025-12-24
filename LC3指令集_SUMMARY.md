# LC-3 指令集（总结）

此文档为 LC-3 汇编/机器指令的详尽参考，便于后续查阅。内容包括：寄存器与条件码、指令格式与 opcode、每条指令的含义、操作数字段、示例汇编和机器码、常用伪指令与 TRAP 向量等。

> 备注：本说明基于标准 LC-3 教学架构（16 位字长，8 个通用寄存器 R0-R7，程序计数器 PC，条件码 N/Z/P）。

## 快速参考

- 字长：16 位
- 寄存器：R0..R7
- 地址空间：16-bit，64K 地址空间
- 条件码：N（负），Z（零），P（正）

## 寄存器与条件码

- R0-R7：通用寄存器
- PC：程序计数器，取指后自动 +1（除非发生跳转/JSR 等）
- IR：指令寄存器
- MAR/MDR：内存地址/数据寄存器（实现细节）
- 条件码：根据最近一次写入寄存器（通常为 ALU 结果）设置为 N/Z/P

设置条件码的规则：
- 结果为 0 -> Z = 1
- 结果最高位为 1（视为负数） -> N = 1
- 否则 -> P = 1

## 指令集总览（按 opcode）

LC-3 一共有 16 个基本 opcode（4 位），下面逐条列出：

1) BR (0000) — 条件分支

- 二进制格式：0000 n z p PCoffset9
- 说明：根据 N/Z/P 标志，对 PC 进行带符号的 9 位偏移跳转（偏移按字计）。
- 字段：n,z,p（三个位表示要检查的条件位），PCoffset9（带符号，范围 -256..+255）
- 示例：
  - BRnzp LABEL ; 无条件跳转
  - 二进制示例：0000 111 111111111 表示 BRnzp -1（用于无限循环）

2) ADD (0001) — 加法

- 两种模式：寄存器或立即数
- 格式（寄存器）：0001 DR SR1 000 SR2
- 格式（立即数）：0001 DR SR1 1 imm5（imm5 带符号）
- 说明：DR = SR1 + SR2 或 DR = SR1 + imm5
- 示例：
  - ADD R1,R2,R3 ; R1 = R2 + R3
  - ADD R1,R2,#-3 ; R1 = R2 - 3

3) LD (0010) — 直接加载（PC-relative）

- 格式：0010 DR PCoffset9
- 说明：DR = MEM[PC + sext(PCoffset9)]（PC 已增 1 后计算偏移）
- 示例：LD R0,VALUE

4) ST (0011) — 直接存储（PC-relative）

- 格式：0011 SR PCoffset9
- 说明：MEM[PC + sext(PCoffset9)] = SR

5) JSR / JSRR (0100) — 跳转并链接

- 两种形式：JSR（PC-relative）和 JSRR（寄存器）
- JSR 格式：0100 1 PCoffset11  -> R7 = PC; PC = PC + sext(PCoffset11)
- JSRR 格式：0100 0 000 BaseR 000000 -> R7 = PC; PC = BaseR
- 说明：保存返回地址到 R7

6) AND (0101) — 位与

- 格式与 ADD 类似（寄存器/立即数）
- 寄存器：0101 DR SR1 000 SR2
- 立即数：0101 DR SR1 1 imm5
- 说明：DR = SR1 & SR2 或 DR = SR1 & imm5

7) LDR (0110) — 基址寄存器加载（Base+offset）

- 格式：0110 DR BaseR offset6
- 说明：DR = MEM[BaseR + sext(offset6)]（offset6 带符号）

8) STR (0111) — 基址寄存器存储

- 格式：0111 SR BaseR offset6
- 说明：MEM[BaseR + sext(offset6)] = SR

9) RTI (1000) — 恢复中断（通常用于操作系统/异常处理）

- 格式：1000 0000 000000（通常不用于用户程序）
- 说明：从系统栈/状态恢复寄存器和条件码，返回到中断前的状态

10) NOT (1001) — 位取反

- 格式：1001 DR SR1 111111
- 说明：DR = bitwise NOT of SR1 ; 设置条件码
- 示例：NOT R0,R1

11) LDI (1010) — 间接加载（通过内存指针）

- 格式：1010 DR PCoffset9
- 说明：有效地址 EA = MEM[PC + sext(PCoffset9)]; DR = MEM[EA]

12) STI (1011) — 间接存储

- 格式：1011 SR PCoffset9
- 说明：EA = MEM[PC + sext(PCoffset9)]; MEM[EA] = SR

13) JMP / RET (1100) — 跳转寄存器

- 格式：1100 000 BaseR 000000
- 说明：PC = BaseR
- RET 是 JMP R7 的别名（1100 000 111 000000）

14) RES / 未使用 (1101)

- 说明：保留（未定义/保留给未来使用）

15) LEA (1110) — 装载有效地址（Load Effective Address）

- 格式：1110 DR PCoffset9
- 说明：DR = PC + sext(PCoffset9)（把目标地址装到寄存器，不访问内存）

16) TRAP (1111) — 软中断 / 系统调用

- 格式：1111 0000 trapvect8
- 说明：将 PC 的下一个地址存入 R7，然后 PC = x00FF & trapvect8（跳转到 TRAP 向量表）
- 常用 trapvect：
  - x20 GETC  : 读取一个字符到 R0（阻塞），不回显
  - x21 OUT   : 将 R0 低 8 位输出到控制台
  - x22 PUTS  : 将以 R0 指向的内存中的字符串输出，遇 0x00 结束
  - x23 IN    : 提示并读取一个字符，回显到屏幕并存入 R0
  - x24 PUTSP : 输出打包字符串（每字包含两个 ASCII 字节）
  - x25 HALT  : 停止程序（通常打印 "HALT" 并停机）


## 指令细节与示例

下面给出每条指令的更详细示例（汇编 -> 机器码）和对条件码的影响说明。

- BR (条件分支)

  - 示例：BRzp POS_LABEL
  - 汇编：0000 101 PCoffset9
  - 说明：如果 Z=1 或 P=1，则跳转到 PC + sign_extend(PCoffset9)

- ADD

  - 示例（寄存器）：ADD R2,R3,R4  -> 0001 010 011 000 100
  - 示例（立即数）：ADD R1,R1,#5 -> 0001 001 001 1 00101
  - 条件码：写入 DR 后更新 N/Z/P

- LD / ST

  - LD R0,VAL ; 如果 VAL 在 PC+5，则 PCoffset9=5
  - 二进制：0010 000 000000101

- JSR / JSRR

  - JSR LABEL -> 保存 R7=PC ; PC=PC+sext(PCoffset11)
  - JSRR R3 -> 保存 R7=PC ; PC=R3

- AND

  - AND R0,R1,R2 -> 0101 000 001 000 010
  - AND R0,R0,#-1 -> 0101 000 000 1 11111  (用于掩码)

- LDR / STR

  - LDR R1,R2,#-2 -> 0110 001 010 111110 (offset6 = -2)

- NOT

  - NOT R1,R2 -> 1001 001 010 111111

- LDI / STI

  - LDI R0, PTR -> 1010 000 PCoffset9 ; 假设 PTR 存放一个地址 A，且 MEM[A] 是目标值

- JMP / RET

  - JMP R1 -> 1100 000 001 000000
  - RET -> JMP R7 -> 1100 000 111 000000

- LEA

  - LEA R3, LABEL -> R3 = PC + sext(PCoffset9)

- TRAP

  - TRAP x23 -> 1111 0000 00100011
  - 执行后 PC 跳转到 TRAP 向量表中对应地址（通常在低页面）并执行系统例程


## 伪指令（Assembler Pseudo-Ops）

- .ORIG x3000  ; 程序起始地址
- .END         ; 程序结束
- .BLKW n      ; 分配 n 个字（word）空间
- .FILL x1234  ; 在当前位置放置一个字（16 位）常量
- .STRINGZ "Hello" ; 放置以 0 结尾的字符串

示例：
.ORIG x3000
LEA R0,MSG
PUTS
HALT
MSG .STRINGZ "Hello, LC-3!"
.END


## 地址/偏移细节与符号扩展

- PCoffset9：9 位带符号，范围 -256..+255。计算跳转地址时通常以 PC（在取指阶段已增 1）为基准。
- offset6：6 位带符号，范围 -32..+31，用于 LDR/STR
- imm5：5 位带符号，范围 -16..+15，用于 ADD/AND 立即数


## TRAP 常用向量（汇总）

- x20 GETC
- x21 OUT
- x22 PUTS
- x23 IN
- x24 PUTSP
- x25 HALT


## 常见示例程序片段

- 将字符回显并停止：

    .ORIG x3000
    TRAP x23   ; 输入字符到 R0
    TRAP x21   ; 输出 R0
    TRAP x25   ; HALT
    .END

- 计算两个数之和并保存：

    .ORIG x3000
    LD R1,NUM1
    LD R2,NUM2
    ADD R3,R1,R2
    ST R3,SAVE
    HALT
NUM1 .FILL x0005
NUM2 .FILL x0007
SAVE .BLKW 1
    .END


## 调试与附加说明

- 条件码必须在对寄存器写入后手动或自动更新（指令会自动更新受写影响的条件码）。
- 在使用 PC-relative 指令（BR/LD/ST/LEA/LDI/STI/JSR 等）时，注意 PC 的增量行为：在取指阶段 PC 已加 1，再应用偏移。
- 注意立即数的符号扩展（imm5/offset6/PCoffset9/PCoffset11）以确保负数正确表示。


## 参考资料与延伸阅读

- 《Introduction to Computing Systems: From bits & gates to C & beyond》（Bryant & O'Hallaron）中 LC-3 的章节
- 各大学的 LC-3 教程和实验资料（常见于课程资料与实验说明书）


---

文件已生成于工作区根目录：`LC3/LC3指令集_SUMMARY.md`。如需我把内容写入特定文件名（例如覆盖现有 `LC3指令集 ` 文件）或生成更精简/更详细的版本（例如加入每条指令的位级图示、更多示例或汇编器兼容性说明），告诉我你偏好的格式和深度，我会继续完善。

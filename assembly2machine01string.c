/*
该程序的作用：实现一个LC3的汇编器
实现将输入的LC3汇编代码转化为机器码（01串）
实现目标：
        从标准输入读入 LC-3 代码，并以文本形式（字符 '1' 和 '0'）将机器代码输出到标准输出。
        输入的 LC-3 代码不会存在错误，并且已经经过规范化（参见后续描述）。
        源代码仅包含一个程序段（即一对 .ORIG 和 .END）。
        输出的机器代码须在第一行标注装载地址，随后每条指令一行。
        源代码可能包含任意 LC-3 汇编指令。
        可以使用任何支持标准输入和输出的语言（也包括 LC-3！）来编写程序。


输入规范：
        行与行之间以 LF \n 分隔，可能有空行。
        源代码可能有注释，注释以分号 ; 开始，至所在行的末尾结束。
        每个非空行仅包含一条指令（包含伪指令，下同），每条指令也仅会写在一行中（标签除外）。
        指令可能会有不定数目空格的缩进。
        如果指令有标签，标签可能放在指令前（与操作码有一空格），或者在指令上方一行。
        指令可能有多个标签。
        操作码与操作数之间有一空格。
        每两个操作数之间以逗号加空格 ,  分隔。
        操作码、寄存器名与标签均可能包含大写或小写字母。
        .STRINGZ 后的字符串以双引号 " 包裹。
        .STRINGZ 的字符串若包含转义符，则只有 \n 一种。
        .BLKW 后的操作数没有立即数前缀。
        带有汇编名称的中断（如 HALT）会使用其中断名，而不是 TRAP 与立即数的组合。
        源代码仅包含可打印 ASCII 字符。
*/
/*
所有的指令：
    .ORIG
    .END
    .FILL
    .BLKW
    .STRINGZ
    ADD
    AND
    NOT
    BR
    BRn
    BRz
    BRp
    BRnz
    BRnp
    BRzp
    BRnzp
    JMP
    JSR
    JSRR
    LD
    LDR
    LDI
    LEA
    ST
    STR
    STI
    RTI
    RET
    TRAP
    HALT
    寄存器：
    R0
    R1
    R2      
    R3
    R4
    R5
    R6
    R7
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define MAX_LINE_LENGTH 256// 每行最大长度
#define MAX_LABEL_LENGTH 20// 标签最大长度
#define MAX_INSTRUCTIONS 10000// 最大指令数
#define MEMORY_SIZE 65536// LC-3 内存大小2^16
#define MAX_LABELS 1000// 最大标签数

typedef struct {
    char label[MAX_LABEL_LENGTH];
    int addr;
} Label;// 标签结构体: 存储标签名和对应地址

typedef struct {
    char line[MAX_LINE_LENGTH];
    int addr;
} Instruction;// 指令结构体: 存储指令行和对应地址

Label labelTable[MAX_LABELS];// 标签表
int labelCount = 0;// 标签计数  
Instruction instructions[MAX_INSTRUCTIONS];// 指令数组
int instructionCount = 0;// 指令计数
int originAddress = 0;// 程序起始地址

// 函数声明
void trim(char *str);// 去除字符串首尾空格
int isLabel(const char *str);// 判断是否为标签
void addLabel(const char *label, int addr);// 添加标签到标签表
int getLabelAddress(const char *label);// 获取标签地址
void parseLine(char *line, int currentAddr);// 解析每行指令
void assembleInstruction(const char *line, int currentAddr, char *output);// 汇编单条指令
void toBinaryString(int value, char *output);// 整数转二进制字符串      
void handlePseudoInstruction(const char *line, int *currentAddr);// 处理伪指令
void handleComment(char *line);// 处理注释

int main() {
    char line[MAX_LINE_LENGTH];// 存储每行输入
    int currentAddr = 0;// 当前地址
    int inProgram = 0; // 是否在程序段内

    // 第一遍: 解析标签和伪指令
    while (fgets(line, sizeof(line), stdin)) {
        handleComment(line);// 去除注释
        trim(line);// 去除首尾空格
        if (strlen(line) == 0) continue;// 空行跳过

        if (strncasecmp(line, ".ORIG", 5) == 0) {
            sscanf(line + 5, "%x", &originAddress);
            currentAddr = originAddress;
            inProgram = 1;
            continue;
        }
        if (strncasecmp(line, ".END", 4) == 0) {
            inProgram = 0;
            continue;
        }
        if (!inProgram) continue;

        parseLine(line, currentAddr);// 解析当前行
    }

    // 第二遍: 汇编指令
    currentAddr = originAddress;
    printf("%04X\n", originAddress);
    for (int i = 0; i < instructionCount; i++) {
        char machineCode[17];
        assembleInstruction(instructions[i].line, instructions[i].addr, machineCode);
        printf("%s\n", machineCode);
    }

    return 0;
}
// 去除字符串首尾空格
void trim(char *str) {
    char *end;
    while (isspace((unsigned char)*str)) str++;//只要不是空格
    if (*str == 0) return;
    end = str + strlen(str) - 1;
    while (end > str && isspace((unsigned char)*end)) end--;
    *(end + 1) = 0;// 结束符
}
// 判断是否为标签
int isLabel(const char *str) {
    int len = strlen(str);
    if (len == 0 || len >= MAX_LABEL_LENGTH) return 0;
    for (int i = 0; i < len; i++) {
        if (!isalnum((unsigned char)str[i]) && str[i] != '_') return 0;
    }
    return 1;
}
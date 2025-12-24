.ORIG x3000
      AND R2,R2,#0;0->R2
INPUT GETC;0/1/Y->R
     
      AND R1,R1,#0
      LD R1,UY
      ADD R1,R0,R1
      BRz OUTPUT
      
      AND R1,R1,#0
      LD R1,UZERO
      ADD R0,R0,R1;R0=0/1
      ADD R2,R2,R2
      ADD R2,R2,R0;R2=R2*2+R0
      AND R1,R1,#0
      ADD R1,R2,#-7
      BRn INPUT
      ADD R2,R2,#-7
      BRnzp INPUT
      
OUTPUT LD R0,ZERO
       ADD R0,R2,R0;->ASCII 
       OUT
       HALT

UY .FILL #-121
UZERO .FILL #-48
ZERO .FILL #48
 .END
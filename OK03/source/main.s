.section .init
.global _start
_start:
b   main


.section    .text
main:
mov         sp,#0x800


/* Set GPIO Function */
pinNum      .req r0
pinFunc     .req r1
mov         pinNum,#47
mov         pinFunc,#1
bl          SetGpioFunction
.unreq      pinNum
.unreq      pinFunc


/* Enable GPIO Pin */
enable$:
pinNum      .req r0
pinVal      .req r1
mov         pinNum,#47
mov         pinVal,#1
bl          SetGpio
.unreq      pinNum
.unreq      pinVal


/* Wait */
mov     r2,#0x3F0000
wait1$:
sub     r2,#1
cmp     r2,#0
bne     wait1$


/* Disable GPIO Pin */
pinNum      .req r0
pinVal      .req r1
mov         pinNum,#47
mov         pinVal,#0
bl          SetGpio
.unreq      pinNum
.unreq      pinVal


/* Wait */
mov     r2,#0x3F0000
wait2$:
sub     r2,#1
cmp     r2,#0
bne     wait2$

b   enable$


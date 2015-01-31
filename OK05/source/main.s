.section .init
.global _start
_start:
b   main

.section    .text
main:
mov         sp,#0x8000

/*
* Set pin as output
*/
pinNum      .req r0
pinFunc     .req r1
mov         pinNum,#47
mov         pinFunc,#1
bl          SetGpioFunction
.unreq      pinNum
.unreq      pinFunc


loop$:
/*
* Enable pin
*/
pinNum      .req r0
pinVal      .req r1
mov         pinNum,#47
mov         pinVal,#1
bl          SetGpio
.unreq      pinNum
.unreq      pinVal


WaitTime    .req r0
ldr         WaitTime,=100000
bl          Wait
.unreq      WaitTime


/*
* Disable pin
*/
pinNum      .req r0
pinVal      .req r1
mov         pinNum,#47
mov         pinVal,#0
bl          SetGpio
.unreq      pinNum
.unreq      pinVal


WaitTime    .req r0
ldr         WaitTime,=100000
bl          Wait
.unreq      WaitTime


b   loop$


/*
* The data section of the file will hold any data that isn't a direct
* instruction for the processor.
*
* The align instruction will set the address of the next line as a multiple of
* the number following the instruction. In this instance it will ensure the
* address for the pattern label will be a multiple of 2. This is needed as the
* ldr instruction will only work on addresses that are a multiple of 2.
*/
.section .data
.align 2
pattern:
.int 0b11111111101010100010001000101010


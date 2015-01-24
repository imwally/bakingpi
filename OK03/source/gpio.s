/* 
* Function GetGpioAddress
*
* .globl will make this function accessible to all files 
*
* Copy the value in lr (link register) to pc 
*
* pc is a special register which always contains the address
* of the next instruction to be run.
*
* lr is the address to branch back to when a function is 
* finished but it has to contain the same address after
* the function has finished.
*
* Before this function runs, the next line to run after
* it is copied into the lr register. Moving this register
* into the pc register will execute that line after
* this function finishes.
*/
.globl GetGpioAddress
GetGpioAddress:
    ldr     r0,=0x20200000
    mov     pc,lr


/*
* Function SetGpioFunction
*
* Start compare of r0 to 53 
* Compare r1 to 7 only if line above returned less than
* Move lr into PC only if line above returned higher than 
* Push what is in lr onto the stack because GetGpioAddress needs to use lr 
* Move the value in r0 into r2 
* Branch to GetGpioAddress 
*/
.globl SetGpioFunction
SetGpioFunction:
    cmp     r0,#53
    cmpls   r1,#7
    movhi   pc,lr 
    push    {lr}
    mov     r2,r0
    bl      GetGpioAddress

/* 
* Start a loop 
*
* Compare the value in r2 to 9 
* Subtract 10 from the value in r2 only if the compare above was higher than 
* Add 4 to the value in in r0 (GPIO Address) only if the compare above was higher than 
* Keep looping until the compare is lower than 9 
*/
functionLoop$:
    cmp     r2,#9
    subhi   r2,#10
    addhi   r0,#4
    bhi     functionLoop$

    add     r2, r2,lsl #1
    lsl     r1,r2
    str     r1,[r0]
    pop     {pc}


.globl SetGpio
SetGpio:
pinNum      .req r0
pinVal      .req r1


cmp     pinNum,#53
movhi   pc,lr
push    {lr}
mov     r2, pinNum
.unreq  pinNum
pinNum  .req r2
bl      GetGpioAddress
gpioAddr    .req r0


pinBank     .req r3
lsr         pinBank,pinNum,#5
lsl         pinBank,#2
add         gpioAddr,pinBank
.unreq      pinBank


and         pinNum,#31
setBit      .req r3
mov         setBit,#1
lsl         setBit,pinNum
.unreq      pinNum


teq        pinVal,#0
.unreq      pinVal
streq       setBit,[gpioAddr,#40]
strne       setBit,[gpioAddr,#28]
.unreq      setBit
.unreq      gpioAddr
pop         {pc}


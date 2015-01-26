/* 
* A very simple function that loads the GPIO address into register r0. The
* .globl command will make this function available to external files.
*
* After the GPIO address has been loaded into r0 register the function can
* return by moving the lr register into the pc register. pc is a special
* register which always contains the address of the next instruction to be run.
* lr is the address to branch back to when a function is finished but it has to
* contain the same address after the function has finished.
*
* Before this function runs, the next line to run after it is copied into the
* lr register. Moving this register into the pc register will execute that
* line when this function finishes.
*/
.globl GetGpioAddress
GetGpioAddress:
    ldr     r0,=0x20200000
    mov     pc,lr


/*
* The SetGpioFunction function will set the function of the GPIO pin. That is to
* say the pin will be set as either an input or output.
*
* There are 54 GPIO pins (0-53) with 8 functions (0-7) for each pin. Register r0
* will hold the pin number and register r1 will hold the function for that pin.
* The function will only continue to run if the value in r0 is lower than or the
* same as 53 and the value in r1 is lower than or the same as 7. Otherwise the
* function will end by moving the lr register into the pc register.
*
* The function continues on by pushing lr onto the stack and moving r0 into r2
* because GetGpioAddress makes use of both these registers. 
*/
.globl SetGpioFunction
SetGpioFunction:
    cmp     r0,#53
    cmpls   r1,#7
    movhi   pc,lr 
    push    {lr}
    mov     r2,r0
    bl      GetGpioAddress

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


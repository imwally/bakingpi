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
* as GetGpioAddress makes use of both these registers. 
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
    * Where the magic happens. As mentioned in OK01, there are 6 banks of 4
    * bytes where 3 bit chunks correspond to the function of a specific GPIO
    * pin. The math used to find which bank location and 3 bit chunk is simple
    * yet confusing at the same time. There are only 10 pins to each bank.
    * Taking the same bit location and moving it up one bank will result in
    * adding 10. For instance if the bit was in the 3 bit chunk of the first
    * bank (0x20200000) at say pin 4, then moving up an address location
    * (0x200004) will in turn result in pin 14. 
    *
    * Knowing this but reversing it will give the desired result needed to
    * calculate both the bank and 3 bit location.
    *
    * The first step is to compare the pin number (r2) to 9 and if it is lower
    * than or the same, this first chunk of the loop is finished, otherwise a
    * bit of subtraction and addition takes place. If the pin number is say, 14
    * then 10 is subtracted from it while 4 is added to the GPIO location. This
    * results in the GPIO location of 0x200004 (pins 10-19) and a 4 which is
    * used to then calculate the 4th 3 bit chunk that corresponds to pin 14 in
    * that 32 bit bank.
    *
    * This simple loop has the nice property of both reducing the pin number
    * down to a single digit (which relates to the 3 bit pin function) while
    * simultaneously adding a 4 to the GPIO location that corresponds to the 32
    * bit bank where the pin is located.
    */
    functionLoop$:
        cmp     r2,#9
        subhi   r2,#10
        addhi   r0,#4
        bhi     functionLoop$

        /*
        * After the GPIO location and 3 bit section is found in the above loop
        * the next step is to place a 1 in that 3 bit section and write it to
        * the GPIO location. Multiplying the pin number by 3 will yield the
        * location of where the bit should fall in the 32 bit bank. 
        *
        * The easiest way to multiply by 3 is first by shifting the binary
        * representation of the number by 1 to the left and adding the number to
        * this result.
        *
        * An example of this for the 47th GPIO pin looks like this:
        *
        * r2 = 7 = 00000111
        * r2 = 7<<1 = 00001110 = 14
        * r2 = 14 + 7 = 21
        * r1 = 1<<21 = 00000000 00100000 00000000 00000000
        * write r1 to the location found in r0
        */
        add     r2, r2,lsl #1
        lsl     r1,r2
        str     r1,[r0]
        pop     {pc}

/*
* SetGpio will enable or disable a GPIO pin.
*/
.globl SetGpio
SetGpio:
    /*
    * Set aliases for the registers that will hold the arguments for this
    * function. Register r0 will hold the pin number while register r1 will hold
    * the value of either 0 or 1 declaring on or off for that particular pin.
    */
    pinNum      .req r0
    pinVal      .req r1

    /*
    * If the pin number is higher than 53 end the function.
    */
    cmp     pinNum,#53
    movhi   pc,lr

    /*
    * Otherwise push lr onto the stack and continue on.
    */
    push    {lr}

    /*
    * Move the pin number (r0) into r2 as GetGpioAddress will utilize register
    * r0.
    */
    mov     r2, pinNum
    .unreq  pinNum
    pinNum  .req r2
    bl      GetGpioAddress

    /* 
    * r0 will hold the base GPIO address and r3 will hold the pin bank.
    */
    gpioAddr    .req r0
    pinBank     .req r3

    /* 
    * GPSET0 and GPSET1 enable and disable GPIO pins. GPSET0 resides at
    * 0x2020001C and controls the first 32 pins. GPSET1 is located at 0x20200020
    * and controls pins 32-53.
    * 
    * To determine which bank the pin falls in the pin number can be divided by
    * 32. Shifting the binary representation of the pin to the right by 5 is the
    * same as diving the value by 32.
    *
    * The pin bank is then multiplied by 4 which is the same as shifting the
    * binary representation of the number left by 2.
    *
    * pinBank will result in either 0x200000 or 0x200004
    */
    lsr         pinBank,pinNum,#5
    lsl         pinBank,#2
    add         gpioAddr,pinBank
    .unreq      pinBank

    /*
    * Doing a bitwise AND operation on the pin number and 31 will give the
    * result of dividing the pin number by 32 and leaving the remainder. This
    * remainder will decide whether the bit needed to enable or disable the GPIO
    * pin will fall in the first or second GPSETn bank.
    *
    * An example of this:
    *
    * pinNum = 47
    * pinNum AND 31 = 15
    *
    * A 1 can now be set in the 15th bit by shifting setBit 15 spaces to the
    * left. setBit will now contain the value needed to enable or disable the
    * GPIO pin.
    */
    and         pinNum,#31
    setBit      .req r3
    mov         setBit,#1
    lsl         setBit,pinNum
    .unreq      pinNum


    /*
    * The remaining lines will test if pinVal is equal to zero, if it is (streq)
    * then the setBit will be stored at the GPIO address + 40 otherwise (strne)
    * will store the setBit at the GPIO address + 28.
    */
    teq        pinVal,#0
    .unreq      pinVal
    streq       setBit,[gpioAddr,#40]
    strne       setBit,[gpioAddr,#28]
    .unreq      setBit
    .unreq      gpioAddr
    pop         {pc}


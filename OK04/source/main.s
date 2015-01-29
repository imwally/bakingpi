/*
* This program introduces the use of functions. It achieves the same result as
* OK02 but abstracts some of the functionality out into a different file called
* gpio.s. That file will contain the code for the functions being called in this
* main.s file.
*
* The init section has been altered to keep it as small as possible. It simply
* branches to the main code found in the text section below.
*/
.section .init
.global _start
_start:
b   main

/*
* A new text section has been created that stores the main code. The first line
* of the code sets the stack pointer location to 0x8000. This is done as to give
* the stack ample room to grow because it grows down meaning that the top of the
* stack will have the lowest address.
*
* Memory Locations
*
* +---------------+
* | .text section |
* +---------------+
* | .init section |
* +---------------+
* |    bottom     |  0x8000
* |               |
* |    stack      |
* |               |
* |     top       |  0x????
* +---------------+
* |    ATAGS      |  0x100
* +---------------+
* |  loader stub  |  0x0
* +---------------+
*
*/ 
.section    .text
main:
mov         sp,#0x8000

/*
* Functions usually take arguments but not always. This particular function
* takes two arguments, a pin number and the function for that pin. Arguments are
* stored in registers before a function is called and the way in which they are
* used is described in a standard called the Application Binary Interface or the
* ABI.
*
* From the bakingpi tutorial:
*
* "The standard says that r0,r1,r2 and r3 will be used as inputs to a function
* in order. If a function needs no inputs, then it doesn't matter what value it
* takes. If it needs only one it always goes in r0, if it needs two, the first
* goes in r0, and the second goes on r1, and so on. The output will always be in
* r0. If a function has no output, it doesn't matter what value r0 takes."
*
* The first two lines set the aliases for these arguments. An alias is created
* by first writing the alias name followed by .req and then the register that's
* being aliased.
*
* Register r0 will hold the pin number so it's alias becomes pinNum. The
* function for that pin will be stored in r1 so it's alias will become pinFunc.
* 
* After the aliases have been set they can be used to store their expected
* values. Pin 47 controls the ACT LED on the Raspberry Pi so pinNum (r0) will
* hold the number 47. Setting that pin as an output is done but moving a 1 into
* the pinFunc (r1) register. Now that the arguments have been set the actual
* function that does the work can be called by using the bl mnemonic. bl will
* update the lr register to hold the line after the function call. This is
* needed as to remember what line is to be executed next after the function
* finishes. It is then the job of the function to to execute this next line.
*
* When the function has returned it's a good idea to remove the aliases to the
* argument registers. This is done by using the .unreq command followed by the
* alias name.
*/
pinNum      .req r0
pinFunc     .req r1
mov         pinNum,#47
mov         pinFunc,#1
bl          SetGpioFunction
.unreq      pinNum
.unreq      pinFunc


/* 
* This part of the code is where the loop for enabling the ACT LED will begin so
* a label is created to remember where to branch back to.
*/
loop$:

/*
* The following lines will enable the 47th GPIO pin. First the argument
* registers are aliased as pinNum (r0) and pinVal (r1). Those registers will
* hold the values 47 and 1 respectively. After the function is called with bl
* the aliases can be removed from the argument registers. 
*/ 
pinNum      .req r0
pinVal      .req r1
mov         pinNum,#47
mov         pinVal,#1
bl          SetGpio
.unreq      pinNum
.unreq      pinVal


/* 
* Use the more accurate wait function from systemTimer.s
*
* A delay time in microseconds is loaded into register r0 as an argument to the
* function.
*/
WaitTime    .req r0
ldr         WaitTime,=100000
bl          Wait
.unreq      WaitTime


/* 
* Disabling the 47th GPIO pin (ACT LED) looks very similar to the enable code
* except that the pinVal register is set to 0, thus disabling the pin.
*/
pinNum      .req r0
pinVal      .req r1
mov         pinNum,#47
mov         pinVal,#0
bl          SetGpio
.unreq      pinNum
.unreq      pinVal


/* 
* Wait again.
*/
WaitTime    .req r0
ldr         WaitTime,=100000
bl          Wait
.unreq      WaitTime


/*
* Branch back to the beginning of this enable / disable cycle.
*
b   loop$


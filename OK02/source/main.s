/*
* OK02 builds off of OK01. Instead of just enabling the ACT LED pin it will
* cause it to blink by adding a delay between the on and off sequences.
*
* Since most of the code is similar to OK1, I will only write explanations for
* the new bits of code.
*/
.section .init
.global _start
_start:

/*
* GPIO controller location
*/
ldr     r0,=0x20200000

/*
* Set GPIO pin 47 as an output.
*
* r1 = 00000000 00000000 00000000 00000001
* r1 = 00000000 00100000 00000000 00000000
* Write r1 to 0x20200010 (GPFSEL4)
*/
mov     r1,#1
lsl     r1,#21
str     r1,[r0,#16]

/*
* Declare the start of the looping for the on / off sequence. A label (loop$) is
* used to tell the branch command where to start execution again.
*/
loop$:

/*
* Enable GPIO pin 47.
*
* r1 = 00000000 00000000 00000000 00000001
* r1 = 00000000 00000000 10000000 00000000
* Write r1 to 0x20200020 (GPSET1)
*/
mov     r1,#1
lsl     r1,#15
str     r1,[r0,#32]

/*
* Delay execution.
*
* Processors execute commands very fast. In order to get a sufficient delay
* between executions the processor has to keep itself busy by doing something.
* That something sometimes looks like nothing because there is no output
* produced. The simplest form of this nothing is to have the processor subtract
* 1 from a very large number until it reaches 0. After it has successfully
* counted down it will continue on with the next execution.
*
* There is however a problem with this method of delay. Different processors
* execute commands at different speeds. One could count down much faster than
* another slower processor. Thankfully this code will work on most Raspberry
* Pi's because they all have the same processors, at least as of early 2015. 
*
* One of the later lessons will go over a more universal and concrete way of
* handling time by using the system's built-in counter. Until then, this method
* works just as well. 
*
* First, a large number (4128768) is moved into register r2.
* Next, a label is declared to state where the wait loop should start over.
* 1 is subtracted from the large number.
* After that a comparison is made between the difference and 0.  
* The result of that comparison is checked. If it's not equal to 0 then start
* the whole process over again by subtracting 1 from the result.
*/
mov     r2,#0x3F0000
wait1$:
    sub     r2,#1
    cmp     r2,#0
    bne     wait1$

/*
* Disable GPIO pin 47.
*
* Write r1 to 0x2020002C (GPCLR1)
*/
str     r1,[r0,#44]

/*
* Delay execution.
*
* The following code is exactly the same as the first delay except that the
* label has a different name. This is because a second delay is needed after the
* LED has been disabled. If a branch was made back to the first delay here,
* then the code will only loop back before the LED was disabled, it will never
* loop back to the beginning where it should be re-enabled. 
*/
mov     r2,#0x3F0000
wait2$:
    sub     r2,#1
    cmp     r2,#0
    bne     wait2$

/*
* Branch back to the enabling of pin 47
*
* All of the code above starting at loop$ on down is referenced by that label,
* loop$, so branching back to it will start the endless cycle of a blinking LED.
*/
b       loop$


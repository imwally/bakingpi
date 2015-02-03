.section .init
.global _start
_start:
    b main

.section .text
main:
    mov sp,#0x8000

    /*
    * Set GPIO pin 47 as output.
    */
    mov r0,#47
    mov r1,#1
    bl  SetGpioFunction

    /*
    * Load the SOS binary pattern into r4 and the sequence position bit into r5.
    */
    ldr r4,=pattern
    ldr r4,[r4]
    mov r5,#0

    loop$:
        mov r1,#1
        lsl r1,r5
        and r1,r4

        /*
        * Enable or disable pin 47 depending on the value in r1.
        */
        mov r0,#47
        bl  SetGpio

        ldr r0,=100000
        bl  Wait

        /*
        * Compare the sequence bit position to 32, if it's lower increment 1
        * otherwise set it back to 0 and repeat.
        */
        cmp r5,#32
        movhi r5,#0
        addle r5,#1

        b loop$
        


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
.int 0b00000000010101011101110111010101


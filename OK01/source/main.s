/*
* Tell the assembly that our code starts here.
*
* "If we don't do this, the code in the alphabetically first file name will run
* first!"
*/
.section .init

/*
* From the footnotes of the tutorial:
*
* Since the GNU toolchain is mainly used for creating programs, it expects there
* to be an entry point labeled _start. As we're making an operating system, the
* _start is always whatever comes first, which we set up with the .section .init
* command. However, if we don't say where the entry point is, the toolchain gets
* upset. Thus, the first line says that we are going to define a symbol called
* _start for all to see (globally), and the second line says to make the symbol
* _start the address of the next line.
*/
.global _start
_start:

/*
* It's best to have a baseline to start from when working with peripherals. The
* ACT LED is connected to the GPIO controller. Starting with the base address of
* the GPIO controller would be a good idea then. The address is 0x20200000.
* Using the load register command will load this address into register r0.
*/
ldr     r0,=0x20200000

/*
* There are 54 GPIO pins. Each pin is controlled by 3 bits that correspond to
* different functions. These pins are spread out over 24 bytes ranging from the
* base GPIO location 0x20200000 to 0x20200014.
*
* Location    Pins    Bytes
* --------    -----   -----
* 0x20200014  50-54   00000000 00000000 00000000 00000000
* 0x20200010  40-49   00000000 00000000 00000000 00000000
* 0x2020000C  30-39   00000000 00000000 00000000 00000000
* 0x20200008  20-29   00000000 00000000 00000000 00000000
* 0x20200004  10-19   00000000 00000000 00000000 00000000
* 0x20200000   0-9    00000000 00000000 00000000 00000000
*
* Pin 47 is used to control the ACT LED on the Raspberry Pi A+ model. Pins 40-49
* fall in the 0x20200010 block. Splitting this 32 bit block up into 3 bit pieces
* gives a better visual to understand how each pin is controlled.
*
*     49  48   47  46   45  44  43   42  41  40
* 00|000|000 |001|000|00 0|000|000|0 00|000|000
*
* Getting a 1 into that 3 bit chunk is easiest by first starting with a base
* 32 bit binary representation of 1 (00000000 00000000 00000000 00000001).
* 
* Shifting the 1 over to the left by 21 places will land in the 7th 3 bit chunk
* that maps to pin 47. Notice that 3 * 7 = 21.
*
* Register r1 now contains 00000000 00100000 00000000 00000000.
*
* This value can be stored in the 40-49 pin block. The location to this block is
* at 0x20200010. 16 is added to the base GPIO location to get this value. 
* 
* In hex: 0x20200000 + 16 = 0x20200010
*
* The last line here will store the value in r1 at the location computed by
* [r0,#16].
*
* Setting the 3 bit value for pin 47 to 001 sets it to be used as an output.
*/
mov     r1,#1
lsl     r1,#21
str     r1,[r0,#16]

/*
* After a pin has been selected it can be manipulated with a few commands.
* Enabling the pin can be done with the GPSETn command.
*
* n denotes which pin to enable. The first 31 bits fall in the GPSET0 address at
* 0x2020001C. Bits 32-53 fall in the GPSET1 address at 0x20200020.
*
*              Pin 53    Pin 47     Pin 32
*              |         |          |
*              |         +-------+  +------------+
*              |                 |               |
*              v                 v               v
* lsl r1,#15 = 00000000 00000000 10000000 00000000 
* 
* Storing this value at 0x20200020 will enable pin 47.
*/
mov     r1,#1
lsl     r1,#15
str     r1,[r0,#32]

/*
* A line that ends with with a $ declares a label. It is saying that the next
* line after this one can be referred to any where in the block as this label.
*
* The b mnemonic stands for branch. It will branch to the part of the code
* mentioned in it's argument and execute that line.
*
* These two lines essentially point to each other creating an infinite loop. The
* processor doesn't know when to stop so this will give it something to do until
* the power is pulled from the system.
*/
loop$:
b loop$ 


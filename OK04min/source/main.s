.section .init
.global _start
_start:
b   main

.section .text
main:
mov sp,#0x8000

bl SetActLEDPinAsOutput
loop$:
    bl EnableActLED
    bl Wait25
    bl DisableActLED
    bl Wait25
    bl loop$


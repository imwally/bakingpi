/*
* Get system timer's location
*
* Loads the base address, 0x20003000, into r0.
*/
.globl GetSystemTimerBase
GetSystemTimerBase:
    ldr     r0,=0x20003000
    mov     pc,lr


/*
* Get the current time
*
* The counter address location is 0x20003004
*
* This address holds an 8 byte value. It must be loaded across 2 registers
* with ldrd.
*/
.globl GetTimeStamp
GetTimeStamp:
    push    {lr}
    bl      GetSystemTimerBase
    ldrd    r0,r1,[r0,#4]
    pop     {pc}


/*
* Wait will wait for the amount of microseconds found in r0.
*
* First r0 is moved into r2 because GetTimeStamp will load the current
* timestamp into r0.
*
* After the time is loaded into r0 it is then moved into r3 as the start time.
*
* r0 = low register counter value
* r1 = high register counter value
* r2 = time to wait
* r3 = start time
*
* r0 and r1 are freed as GetTimeStamp is used in  a loop to check to see how
* much time has passed since the start of the function.
*
*/
.globl Wait
Wait:
    delay   .req r2
    mov     delay,r0
    push    {lr}
    bl      GetTimeStamp
    start   .req r3
    mov     start,r0

    /* 
    * Waiting logic
    *
    * Start by getting the current time stamp.
    *
    * Subtract start time from current time and store difference in r1
    * (elapsed).
    *
    * Compare the amount of time to wait (delay) with the time elapsed.
    *
    * Branch back to the beginning of the loop if the comparison was lower than
    * or the same.
    */
    loop$:
        bl  GetTimeStamp
        elapsed .req r1
        sub elapsed,r0,start
        cmp elapsed,delay
        .unreq elapsed
        bls loop$

    .unreq  delay
    .unreq  start
    pop     {pc}


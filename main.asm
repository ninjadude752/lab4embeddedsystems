;
; lab4embeddedsystems.asm
;
; Created: 3/23/2023 3:15:04 PM
; Author : smblackwll
;


; Replace with your application code

;assembly code to initialize the LCD display into 4 bit mode.
/*
Wait 100ms for power on
Write D7-4 = 3 hex, with RS=0
wait 5ms 
Write D7-4 = 3 hex, with RS = 0
Wait 200 us
Write D7-4 = 3 hex, with RS = 0, for a 3rd time 
Wait 200 us 
Write D7-4 =2 to enable four bit mode
Wait 5ms

Now the screen is in 4 bit mode

Now:
Write Command:	"Set Interface"
Write Command: "Enable Display/Cursor"
Write Command: "Clear and Home"
Write Command: "Set cursor move direction"
Turn on display
Now the display is ready to accept data


*/

init:




start:
    inc r16
    rjmp start



; poll2 to read in from the RPG from lab 3
poll2:
	rcall readRPG2
	mov R19, R22
	andi R19, 0x3
	cp R16, R19 
	brne shiftAB
	ldi R30, 12
	sbis PINB, 0
	rcall wait_loop
	rjmp poll2



;readRPG2 from lab 3 to read in the shifts
readRPG2:
	in R16, PINC
	andi r16,0x03
	ret


;shiftAB from lab 3
shiftAB:
	lsl R22
	lsl R22
	Or R22, R16
	rjmp compare

;The waiting loop from lab 3
wait_loop:
	rcall delayLoop
	sbic PINB,0
	rjmp check_loop
	dec R30
	cpi R30, 0x00
	brne wait_loop
	clr R27
	rjmp reset
	ret



;The timer from lab 3 - with a 50.091 ms delay/
;It is going to have to be reconfigured for this lab
// run this once to get 50.091 ms delay
delayLoop:
	ldi R23, 0x01		// tmp1
	ldi R24, 0x03		// prescaler, 64 
	ldi R20, 107		// counter
	out TCCR0B, R24
	rcall delay
	dec R29
	brne delayLoop
	ret


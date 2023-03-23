;
; lab4embeddedsystems.asm
;
; Created: 3/23/2023 3:15:04 PM
; Author : smblackwll
;


; Replace with your application code


/*
Pins to configure (on arduino)
11
10
9
8
4
3
2

Pins for RPG
Pins for button



*/

/*
We need:
Interrupt
Interrupt Vector table
To initalize stack pointer

*/


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

.def tmp1 = R23
.def tmp2 = R24		
.def counter = R20

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
	//rjmp compare

;The waiting loop from lab 3
wait_loop:
	rcall delayLoop
	sbic PINB,0
	//This was where the loop to check the code was run
	//rjmp check_loop
	dec R30
	cpi R30, 0x00
	brne wait_loop
	clr R27
	//This is where we cleared the code 
	//rjmp reset
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

; The timer from lab 3
; Wait for TIMER0 to roll over.
delay:
	; Stop timer 0.
	in tmp1, TCCR0B		; Save configuration
	ldi tmp2, 0x00		; Stop timer 0
	out TCCR0B, tmp2
	; Clear overflow flag.
	in tmp2, TIFR0		; tmp <-- TIFR0
	sbr tmp2, 1 << TOV0	; clear TOV0, write logic 1
	out TIFR0, tmp2
	; Start timer with new initial count
	out TCNT0, counter	; Load counter
	out TCCR0B, tmp1	; Restart timer
wait:
	in tmp2, TIFR0		; tmp <-- TIFR0
	sbrs tmp2, TOV0		; Check overflow flag
	rjmp wait
	ret	


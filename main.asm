;
; lab4embeddedsystems.asm
;
; Created: 3/23/2023 3:15:04 PM
; Author : smblackwll
;

// set A0-A3 on uC as output from LCD D4-D7
sbi DDRC, 0		// D4
sbi DDRC, 1		// D5
sbi DDRC, 2		// D6
sbi DDRC, 3		// D7

sbi DDRD, 2		// RPG A signal	(pin2)
sbi DDRD, 3		// RPG B signal (pin3)

cbi DDRB, 0		// set pin8 on uC as input from PBS
cbi DDRB, 3		// set pin11 on uC as input from LCD pin 6 E (enable signal)
cbi DDRB, 5		// set pin13 on uC as input from LCD pin 4 RS (0 = instruction input, 1 = data input)

/*
We need:
Interrupt
Interrupt Vector table
To initalize stack pointer
*/


;assembly code to initialize the LCD display into 4 bit mode.
/*
Wait 100ms for power on
Write D7-4 = 3 hex, with RS=0 = This means that pin 4 should be low
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
ldi R29, 84					; controls the delay time in delayloop
.def tmp1 = R23
.def tmp2 = R24		
.def counter = R20


start:
	rcall changeMode
	rjmp start
	ldi R21, 8				; length of the string
	ldi R17, LOW(2*sf80)	; load Z register low
	ldi R18, High(2*sf80)	; load Z register high
	rcall displayCString

    //inc r16
    rjmp start

sf80: .DB "F=80 kHZ"		; create a static string in program memory
changeMode:
	// wait 100 ms
	rcall delayLoop
	rcall delayLoop
	rcall LCDStrobe
	// write D7-4 = 3 hex?
	cbi PORTC, 3
	cbi PORTC, 2
	sbi PORTC, 1
	sbi PORTC, 0
	// wait 5 ms
	rcall delayLoop
	rcall LCDStrobe
	cbi PORTC, 3
	cbi PORTC, 2
	sbi PORTC, 1
	// wait 200 us
	rcall delayLoop
	rcall LCDStrobe
	cbi PORTC, 3
	cbi PORTC, 2
	sbi PORTC, 1
	sbi PORTC, 0
	// wait 200 us
	rcall delayLoop
	rcall LCDStrobe
	// write D7-4 = 2 hex
	cbi PORTC, 3
	cbi PORTC, 2
	sbi PORTC, 1
	cbi PORTC, 0
	// wait 5 ms
	rcall delayLoop
	rcall LCDStrobe
	
	sbi PORTC, 3
	sbi PORTC, 2
	sbi PORTC, 1
	sbi PORTC, 0
	rcall delayLoop
	rcall LCDStrobe	

	ret

displayCString:
L20:
	lpm
	swap R0					; upper nibble in place
	out PORTC, R0			; send upper nibble out
	rcall LCDStrobe			; latch nibble
	rcall delayLoop		; wait
	swap R0					; lower nibble in place
	out PORTC, R0			; send lower nibble out
	rcall LCDStrobe			; latch nibble
	rcall delayLoop		; wait
	adiw zh:zl, 1			; increment z pointer
	dec R21					; repeat until
	brne L20				; all charcters are out
	ret


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
	in R16, PIND
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

// delay of 100 us
delay_100u:
	
	ret

// latch nibble
LCDStrobe:
	sbi PORTB, 3
	rcall delayLoop
	cbi PORTB, 3
	ret

// Clear display
clear:
	cbi PINC, 0
	cbi PINC, 1
	cbi PINC, 2
	cbi PINC, 3
	cbi PIND, 7
	sbi PIND, 7
	ret

// Timer 0 Overflow interrupt ISR
/*
tim0_ovf:
	push R25
	in R25, SREG
	push R25
	sbi PINC, 5		; Toggle PORTC, 5  <== LED
	ldi R25, 201	; Reload counter
	out TCNT0, R25
	pop R25
	out SREG, R25
	pop R25
	reti
*/

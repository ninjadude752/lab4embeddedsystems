;
; lab4embeddedsystems.asm
;
; Created: 3/23/2023 3:15:04 PM
; Author : smblackwll
;
.cseg
	.org 0x0000
		rjmp start

sf80: .DB "F=80 kHZ",0		; create a static string in program memory
buttonOn: .DB "Fan: On ", 0 //length 8
buttonOff: .DB "Fan: Off", 0 //length 8
	;rcall displayCString



start:
	

			// set A0-A3 on uC as output from LCD D4-D7
	sbi DDRC, 0		// D4
	sbi DDRC, 1		// D5
	sbi DDRC, 2		// D6
	sbi DDRC, 3		// D7

	//set pushbutton as input
	sbi DDRC, 4
	sbi DDRD, 3

	;sbi DDRD, 2		// RPG A signal	(pin2)
	;sbi DDRD, 3		// RPG B signal (pin3)

	;cbi DDRB, 0		// set pin8 on uC as input from PBS
	sbi DDRB, 3		// set pin11 on uC as input from LCD pin 6 E (enable signal)
	sbi DDRB, 5		// set pin13 on uC as input from LCD pin 4 RS (0 = instruction input, 1 = data input)

	/*
	We need:
	Interrupt
	Interrupt Vector table
	To initalize stack pointer
	*/

	

	ldi R29, 50					; controls the delay time in delayloop
	ldi R28, 50
	.def tmp1 = R13
	.def tmp2 = R24		
	.def counter = R20
	clr R25						; register to store nibble
	ldi R17, 0x01 ;set fan bit to on

	rcall changeMode
	sbi PORTB, 5
	rcall displayCString
	//need a function to move the cursor over 9 spaces to get to the next line
	rcall nextLine
	sbi PORTB, 5
	rcall displayFanOn
	;rcall clearDisplay
    //inc r16
	;rcall PWMLoop
	rjmp end

displayLoop:
	sbi PORTB, 5
	rcall displayCString
	//need a function to move the cursor over 9 spaces to get to the next line
	rcall nextLine
	sbi PORTB, 5
	rcall displayFanOn

changeMode:
	cbi PORTB, 3
	cbi PORTB, 5
	// wait 100 ms
	rcall delayLoop
	rcall delayLoop
	rcall delayLoop
	// write D7-4 = 3 hex?
	ldi R25, 0x03
	out PORTC, R25
	rcall enable
	// wait 5 ms
	rcall delayLoop
	ldi R25, 0x03
	out PORTC, R25
	rcall enable
	// wait 200 us
	rcall delayLoop
	ldi R25, 0x03
	out PORTC, R25
	rcall enable
	// wait 200 us
	rcall delayLoop
	// write D7-4 = 2 hex
	ldi R25, 0x02
	out PORTC, R25
	rcall enable
	// wait 5 ms
	rcall delayLoop
	
	// 2 lines
	ldi R25, 0x02
	out PORTC, R25
	rcall enable
	rcall delayLoop 
	ldi R25, 0x08
	out PORTC, R25
	rcall enable
	rcall delayLoop

	// enable display/cursor 08 hex
	ldi R25, 0x00
	out PORTC, R25
	rcall enable
	rcall delayLoop
	ldi R25, 0x08
	out PORTC, R25
	rcall enable
	rcall delayLoop

	// clear and home display 01 hex
	ldi R25, 0x00
	out PORTC, R25
	rcall enable
	rcall delayLoop
	ldi R25, 0x01
	out PORTC, R25
	rcall enable
	rcall delayLoop

	// move cursor right 06 hex
	ldi R25, 0x00
	out PORTC, R25
	rcall enable
	rcall delayLoop
	ldi R25, 0x06
	out PORTC, R25
	rcall enable
	rcall delayLoop
	
	// turn on display 0C hex
	ldi R25, 0x00
	out PORTC, R25
	rcall enable
	rcall delayLoop
	ldi R25, 0x0C
	out PORTC, R25
	rcall enable
	rcall delayLoop
	ret
	

displayCString:
	ldi R21, 8				; length of the string
	ldi R30, LOW(2*sf80)	; load Z register low
	ldi R31, HIGH(2*sf80)	; load Z register high
	rjmp L20
displayFanOn:
	ldi R17, 0x01
	ldi R21, 8
	ldi R30, LOW(2*buttonOn)
	ldi R31, HIGH(2*buttonOn)
	rjmp L20
displayFanOff:
	clr R17
	ldi R21, 8
	ldi R30, LOW(2*buttonOff)
	ldi R31, HIGH(2*buttonOff)
	rjmp L20
L20:
	lpm
	swap R0					; upper nibble in place
	out PORTC, R0			; send upper nibble out
	rcall enable			; latch nibble
	rcall delayLoop			; wait
	swap R0					; lower nibble in place
	out PORTC, R0			; send lower nibble out
	rcall enable			; latch nibble
	rcall delayLoop			; wait
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
	sbis PINB, 0
	rcall wait_loop
	rjmp poll2

togglePower:
	cpi R17, 0x00
	breq displayFanOn
	cpi R17, 0x01
	breq displayFanOff
	ret


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
	cpi R26, 0x00
	brne wait_loop
	clr R27
	//This is where we cleared the code 
	//rjmp reset
	ret


clearDisplay:
	// clear and home display 01 hex
	cbi PORTB, 5
	ldi R25, 0x00
	out PORTC, R25
	rcall enable
	rcall delayLoop
	ldi R25, 0x01
	out PORTC, R25
	rcall enable
	rcall delayLoop
	ret

// delay of 100 us
delay_100u:
	
	ret

// enable and disable the enable signal
enable:
	sbi PORTB, 3
	rcall delayLoop
	cbi PORTB, 3
	rcall delayLoop
	ret

nextLine:
	cbi PORTB, 5
	rcall delayLoop
	ldi R25, 0x0C
	out PORTC, R25
	rcall enable
	rcall delayLoop
	ldi R25, 0x00
	out PORTC, R25
	rcall enable
	rcall delayLoop
	ret

;The timer from lab 3 - with a 50.091 ms delay/
;It is going to have to be reconfigured for this lab
// run this once to get 50.091 ms delay
delayLoop:
	ldi R23, 0x01		// tmp1
	ldi R24, 0x03		// prescaler, 64 
	ldi R20, 230		// counter
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


PWMLoop:
	ldi R18, 0x23		// value to set fast pwm mode
	ldi R26, 0x03		// prescaler, 64 
	ldi R27, 255		// counter
	ldi R28, 49
	sts OCR2B, R28
	sts TCCR2B, R26
	rcall delayPWM
	dec R28
	brne PWMLoop
	ret

; The timer from lab 3
; Wait for TIMER0 to roll over.
delayPWM:
	lds R18, TCCR2A		; set to fast pwm mode, non-inverting
	; Stop timer 0.
	lds R26, TCCR2B		; Save configuration
	ldi R26, 0x00		; Stop timer 0
	sts TCCR2B, R26
	; Clear overflow flag.
	in R26, TIFR2		; tmp <-- TIFR0
	sbr R26, 1 << TOV2	; clear TOV0, write logic 1
	out TIFR2, R26
	; Start timer with new initial count
	sts TCNT2, R27	; Load counter
	sts TCCR2B, R18	; Restart timer
PWMWait:
	in R26, TIFR2		; tmp <-- TIFR0
	sbrs R26, TOV2		; Check overflow flag
	rjmp PWMWait
	ret	



// end of the file
end:
	rcall nextLine
	sbi PORTB,5
	SBIS PINC,5
	rcall togglePower
	rjmp end

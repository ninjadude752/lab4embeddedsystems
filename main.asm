;
; lab4embeddedsystems.asm
;
; Created: 3/23/2023 3:15:04 PM
; Author : smblackwll
;

.cseg
.org 0x0000
	rjmp start

.org 0x0002
	jmp buttonInt

.org 0x0006
	jmp rpgInt


sf80: .DB "DC="	; create a static string in program memory
defaultHz: .DB 250
buttonOn: .DB "Fan: On " //length 8
buttonOff: .DB "Fan: Off" //length 8

/*
.DEF DREM16UL = R23
.DEF DREM16UH = R24
.DEF DRES16UL = R26
.DEF DRES16UH = R27
.DEF DD16UL = R26
.DEF DD16UH = R27
.DEF DV16UL = R19
.DEF DV16UH = R20
*/

start:
	cli						; disable interrupts
	// set up stack pointer
	ldi R16, low(RAMEND)
	out SPL, R16
	ldi R16, high(RAMEND)
	out SPH, R16
	clr R16
	// pushbutton
	ldi R16, 0x01			; enable INT0
	out EIMSK, R16
	ldi R16, 0x02			; INT0 on falling edge
	sts EICRA, R16
	// RPG
	ldi R17, 0x03
	sts PCMSK0, R17
	ldi R17, 0x01
	sts PCICR, R17



	// set A0-A3 on uC as output from LCD D4-D7
	sbi DDRC, 0		// D4
	sbi DDRC, 1		// D5
	sbi DDRC, 2		// D6
	sbi DDRC, 3		// D7

	//set pushbutton as input
	cbi DDRD, 2

	// set fan as output
	sbi DDRD, 5
	
	// set RPG as input
	cbi DDRB, 1		; RPG A signal	(pin8)
	cbi DDRB, 0		; RPG B signal (pin8)


	sbi DDRB, 4		; set pin12 on uC as output from LCD pin 6 E (enable signal)
	sbi DDRB, 5		; set pin13 on uC as output from LCD pin 4 RS (0 = instruction input, 1 = data input)
	
	rcall setCounter			; set the counter for the fan, and also starts the fan

	.def tmp1 = R23
	.def tmp2 = R24		
	.def counter = R20
	
	ldi R29, 50					; controls the delay time in delayloop
	clr R25						; register to store nibble
	ldi R17, 0x01				; set fan bit to on

	rcall changeMode
	sbi PORTB, 5				; change to character mode not instruction
	rcall displayCString
	;rcall rpgChange
	;sbi PORTB, 5
	rcall DisplayCycleString
	rcall setupDstring
	rcall nextLine				; function to move the cursor over 9 spaces to get to the next line
	sbi PORTB, 5
	rcall displayFanOff
    //inc r16

	sei							; enable interrupts 	

main:
	rjmp main

buttonInt:
	cli
	push R18
	in R18, SREG
	push R18
	rcall togglePower
	
	pop R18
	out SREG, R18
	pop R18
	reti

rpgInt:
	cli
	push R18
	in R18, SREG
	push R18
	rcall poll2				
	rcall poll2
	rcall poll2
	rcall poll2
	pop R18
	out SREG, R18
	pop R18
	reti

displayLoop:
	sbi PORTB, 5
	rcall displayCString
	//need a function to move the cursor over 9 spaces to get to the next line
	rcall nextLine
	sbi PORTB, 5
	rcall displayFanOn

changeMode:
	cbi PORTB, 4
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



DisplayCycleString:
.dseg
	dtxt: .BYTE 5 ; Allocation
.cseg
	mov dd16uL,R26 ; LSB of number to display DEFINE
	mov dd16uH,r27 ; MSB of number to display DEFINE
	ldi dv16uL,low(10) //DEFINE
	ldi dv16uH,high(10) //DEFINE
	; Store terminating for the string.
	ldi R28,0x00 ; Terminating NULL
	sts dtxt+4,R28 ; Store in RAM
	; Divide the number by 10 and format remainder.
	rcall div16u ; Result: r17:r16, rem: r15:r14  DEFINE
	ldi R28,0x30
	add r14,R28 ; Convert to ASCII
	sts dtxt+3,r14 ; Store in RAM
	; Generate decimal point.
	ldi R28,0x2e ; ASCII code for .
	sts dtxt+2,R28 ; Store in RAM
	ret

setupDstring:
	ldi R21, 5
	ldi R30, LOW(2*dtxt)
	ldi R31, HIGH(2*dtxt)
	;rcall displayDstring
	rcall L20


displayDstring:
	ld r0,Z
	tst r0 ; Reached end of message ?
	breq done_dsd ; Yes => quit
	swap r0 ; Upper nibble in place
	out PORTC,r0 ; Send upper nibble out
	rcall enable ; Latch nibble
	swap r0 ; Lower nibble in place
	out PORTC,r0 ; Send lower nibble out
	rcall enable ; Latch nibble
	rjmp displayDString
done_dsd:
	ret
	

displayCString:
	ldi R21, 3				; length of the string
	ldi R30, LOW(2*sf80)	; load Z register low
	ldi R31, HIGH(2*sf80)	; load Z register high
	rjmp L20
displayFanOn:
	//rcall nextLine
	//sbi PORTB,5
	ldi R17, 0x01
	ldi R21, 8
	ldi R30, LOW(2*buttonOn)
	ldi R31, HIGH(2*buttonOn)
	;rcall turnOnFan
	ldi R29, 191
	out OCR0B, R29
	rjmp L20
displayFanOff:
	//rcall nextLine
	//sbi PORTB,5
	clr R17
	ldi R21, 8
	ldi R30, LOW(2*buttonOff)
	ldi R31, HIGH(2*buttonOff)
	;rcall turnOffFan
	ldi R29, 255
	out OCR0B, R29
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

// enable and disable the enable signal
enable:
	sbi PORTB, 4
	rcall delayLoop
	cbi PORTB, 4
	rcall delayLoop
	ret

togglePower:
	rcall nextLine
	sbi PORTB,5
	cpi R17, 0x00
	breq displayFanOn
	cpi R17, 0x01
	breq displayFanOff
	ret

nextLine:
	cbi PORTB, 5
	//rcall delayLoop
	ldi R25, 0x0C
	out PORTC, R25
	rcall enable
	//rcall delayLoop
	ldi R25, 0x00
	out PORTC, R25
	rcall enable
	//rcall delayLoop
	ret
rpgChange:
	cbi PORTB, 5
	//rcall delayLoop
	ldi R25, 0x00
	out PORTC, R25
	rcall enable
	//rcall delayLoop
	ldi R25, 0x03
	out PORTC, R25
	rcall enable
	//rcall delayLoop
	ret


;The timer from lab 3 - with a 50.091 ms delay/
;It is going to have to be reconfigured for this lab
// run this once to get 50.091 ms delay
delayLoop:
	cli
	ldi R23, 0x01		// tmp1
	ldi R24, 0x03		// prescaler, 64 
	ldi R20, 230		// counter
	sts TCCR2B, R24
	rcall delay
	dec R29
	brne delayLoop
	sei
	ret

; The timer from lab 3
; Wait for TIMER2 to roll over.
delay:
	; Stop timer 0.
	lds tmp1, TCCR2B	; Save configuration
	ldi tmp2, 0x00		; Stop timer 2
	sts TCCR2B, tmp2
	; Clear overflow flag.
	in tmp2, TIFR2		; tmp <-- TIFR0
	sbr tmp2, 1 << TOV2	; clear TOV2, write logic 1
	out TIFR2, tmp2
	; Start timer with new initial count
	sts TCNT2, counter	; Load counter
	sts TCCR2B, tmp1	; Restart timer
wait:
	in tmp2, TIFR2		; tmp <-- TIFR2
	sbrs tmp2, TOV2		; Check overflow flag
	rjmp wait
	ret	

setCounter:
	ldi R28, 50
	rcall PWMLoop
	clr R18
	ret

// timer 0
PWMLoop:
	ldi R18, 0b00110011		// value to set fast pwm mode
	ldi R26, 0x01				// prescaler, 32
	ldi R27, 200			// counter

	out TCCR0A, R18			; set to fast pwm mode, inverting, clear OC0A at BOTTOM
	out TCCR0B, R26			; set prescaler
	out OCR0A, R27
	ldi R27, 255
	out OCR0B, R27
	dec R28
	brne PWMLoop
	ret

turnOffFan:
	ldi R29, 255
	out OCR0B, R29
	ret



changeSpeedCounter:
	cpi R29, 255
	breq decrement
	inc R29
	out OCR0B, R29
	rjmp poll2

changeSpeedClock:
	cpi R29, 0
	breq increment
	dec R29
	out OCR0B, R29
	rjmp poll2

decrement:
	dec R29
	subi R19, low(-4)
	subi R20, high(-4)
	ret

increment:
	inc R29
	subi R19, low(4)
	subi R20, high(4)
	ret

; poll2 to read in from the RPG from lab 3
poll2:
	rcall readRPG2
	mov R19, R22
	andi R19, 0x03
	cp R16, R19 
	brne shiftAB
	;rjmp poll2


;readRPG2 from lab 3 to read in the shifts
readRPG2:
	in R16, PINB
	andi r16, 0x03
	ret

;shiftAB from lab 3
shiftAB:
	lsl R22
	lsl R22
	Or R22, R16
	rjmp compare

compare:
	cpi R22, 0b11010010
	breq changeSpeedCounter
	cpi R22, 0b11100001
	breq changeSpeedClock
	rjmp poll2

;***************************************************************************
;*
;* "div16u" - 16/16 Bit Unsigned Division
;*
;* This subroutine divides the two 16-bit numbers 
;* "dd8uH:dd8uL" (dividend) and "dv16uH:dv16uL" (divisor). 
;* The result is placed in "dres16uH:dres16uL" and the remainder in
;* "drem16uH:drem16uL".
;*  
;* Number of words	:19
;* Number of cycles	:235/251 (Min/Max)
;* Low registers used	:2 (drem16uL,drem16uH)
;* High registers used  :5 (dres16uL/dd16uL,dres16uH/dd16uH,dv16uL,dv16uH,
;*			    dcnt16u)
;*
;***************************************************************************

;***** Subroutine Register Variables


.DEF DREM16UL = R23
.DEF DREM16UH = R24
.DEF DRES16UL = R26
.DEF DRES16UH = R27
.DEF DD16UL = R26
.DEF DD16UH = R27
.DEF DV16UL = R19
.DEF DV16UH = R20
.def dcnt16u = r21
;***** Code

div16u:	clr	drem16uL	;clear remainder Low byte
	sub	drem16uH,drem16uH;clear remainder High byte and carry
	ldi	dcnt16u,17	;init loop counter
d16u_1:	rol	dd16uL		;shift left dividend
	rol	dd16uH
	dec	dcnt16u		;decrement counter
	brne	d16u_2		;if done
	ret			;    return
d16u_2:	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_3		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_1		;else
d16u_3:	sec			;    set carry to be shifted into result
	rjmp	d16u_1

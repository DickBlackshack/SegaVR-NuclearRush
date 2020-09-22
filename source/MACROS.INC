**************************************************************************
**                                 MACROS                                *
**************************************************************************

testheld	macro
	tst.b	KeyTab1+\1*2	;see if a joystick button is current pressed
	endm

testhit	macro
	bclr.b	#0,KeyTab1+\1*2+1 ;see if a joystick button has been pressed (since last time)
	endm

clearhit	macro
	sf	KeyTab1+\1*2+1	;flag joystick button has not been pressed
	endm


DI	macro
	or.w	#$0700,sr	;disable 68000 interrupts
	endm

EI	macro
	and.w	#$F8FF,sr	;enable all 68000 interrupts
	endm

Z80di	macro
	move.w	#$100,Z80BusReq	;Z80 bus request
	move.w	#$100,Z80Reset	;Z80 reset line high (NORMAL RUN STATE)
	btst.b	#0,Z80BusReq	;Z80 bus grant acknowledge?
	bne.s	*-8		;wait until bus granted
	endm

Z80ei	macro
	move.w	#0,Z80BusReq	;Z80 bus release
	endm
 
Z80eiGO	macro
	move.w	#0,Z80Reset	;Z80 reset line low
	Z80ei			;release bus
	move.w	#$100,Z80Reset	;Z80 reset line high (i.e. it has pulsed low)
	endm

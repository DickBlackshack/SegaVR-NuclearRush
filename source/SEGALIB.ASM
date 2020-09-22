*************************************************************************
*                 GENERAL PURPOSE ROUTINES (HARDWARE)                   *
*************************************************************************

	include	EQUATES.INC
	include	MACROS.INC
	include	VARIABLE.INC

	XREF	_gemsdmastart	; tell the z80 we want to do dma
	XREF	_gemsdmaend	; tell the z80 we're done with dma
	XREF	_gemsholdz80	; hold Z80, before accessing joystick
	XREF	_gemsreleasez80	; resume the Z80, after accessing joystick

	OPT	LLBL

Z80NoROM	equ	Z80Base+4	;flag for disabling Z80 ROM accesses


*************************************************************************
* C Callable _SYS_Copy3DObj:	Copy world 3D object
*	SYS_Copy3DObj(OBJECT3D *dest, OBJECT3D *src);
*************************************************************************

	XDEF	_SYS_Copy3DObj

_SYS_Copy3DObj
	move.l	4(a7),a1	; Get destination address
	move.l	8(a7),a0	; Get source address
	move.l	(a0)+,(a1)+	; CURRENTLY, 3D objects are 48 bytes long.
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	rts

*************************************************************************
* C Callable _SYS_CopyV3DObj:		Copy Visable 3D object
*	SYS_Copy3DObj(OBJECT3D *dest, OBJECT3D *src);
*************************************************************************

	XDEF	_SYS_CopyV3DObj

_SYS_CopyV3DObj
	move.l	4(a7),a1	; Get destination address
	move.l	8(a7),a0	; Get source address
	move.l	(a0)+,(a1)+	; CURRENTLY...
	move.l	(a0)+,(a1)+	; Visable 3D objects are 30 bytes long.
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.w	(a0)+,(a1)+
	rts

*************************************************************************
* C Callable _SYS_DCAddVAddr:	Add an Address change to the DC List
*	SYS_DCAddVAddr(UWORD Value);
*************************************************************************

	XREF	_SYS_DCLISTAVL		; List ready to send
	XREF	_SYS_DCLISTLEN		; List length
	XREF	_SYS_DCLIST		; Data or Ctrl flags
	XREF	_SYS_DCDATA		; WORDs to send

	XDEF	_SYS_DCAddVAddr
_SYS_DCAddVAddr:
	move.w	4(a7),d0		; Get destination address
	move.l	d0,d1			; Convert address to VDP address
	or.w	#CD0,d0
	swap	d0
	move.w	d1,d0
	rol.w	#2,d0
	and.l	#($FFFF-CD1)<<16+%11,d0
	lea	_SYS_DCLIST,a0		; Add address to the list
	move	_SYS_DCLISTLEN,d1
	sf.b	0(a0,d1)
	sf.b	1(a0,d1)
	lea	_SYS_DCDATA,a0
	lsl	#1,d1
	move	d0,2(a0,d1)
	swap	d0
	move	d0,0(a0,d1)
	lsr	#1,d1
	add	#2,d1
	move	d1,_SYS_DCLISTLEN
	rts

*************************************************************************
*	SPECIAL CASE FRACTIONAL MULTIPLY FOR:
*		MULTIPLIER HAS NO FRACTIONAL PART
*		MULTIPLICAND IS ONLY FRACTIONAL PART
*************************************************************************

	XDEF	_fsmul

_fsmul	link	a6,#0
	movem.l	d1-d5,-(sp)
	clr	d4		; Signflag = FALSE
	move.l	8(a6),d0	; Get multiplier
	beq.s	.out		; if d0 = 0 product will = 0
	bpl.s	.pos1
	not	d4
	neg.l	d0
.pos1	move.l	12(a6),d2	; Get multiplicand
	bne	.chkp
	moveq	#0,d0
	bra	.out
.chkp	bpl.s	.pos2
	not	d4
	neg.l	d2
.pos2	swap	d0		;getting the top of the multiplier
	mulu	d2,d0		;BH * AL
	tst	d4
	beq.s	.out
	neg.l	d0
.out	movem.l	(sp)+,d1-d5
	unlk	a6
	rts
	
*************************************************************************
*                 FRACTIONAL ARCTANGENT ROUTINE (RESULT IN DEGREES)     *
*************************************************************************

	IFNE 0

	XREF	_tantab
	XDEF	_fatan2

_fatan2	link	a6,#0
	movem.l	d1-d4/a0,-(sp)
	moveq.l	#0,d2		; Signflag = FALSE
	moveq.l	#0,d4		; Second Signflag = FALSE
	move.l	8(a6),d0	; Get X
	bne.s	.0		; if 0 atan = 90 or 270
.pre0	move.l	#90,d0
	move.l	12(a6),d1	; Get Y
	bpl.s	.exit
	neg	d0
	bra.s	.exit		
.0	bpl.s	.1
	not	d4		; Save sign of X for later
	neg.l	d0
.1	move.w	#0,d0		; Change Y fraction into an integer
	swap	d0
	tst.l	d0
	beq	.exit
	move.l	12(a6),d1	; Get Y
	bpl.s	.2
	neg.l	d1
	not	d2		; Save sign of Y for later
.2	move.w	#0,d1		; Change X fraction into an integer
	swap	d1
	divu	d0,d1		; Y/X
	bvs.s	.pre0		; overflow means steep slope 90 or 270
	bmi.s	.pre0		; negative means steep slope
	move.l	d1,d3		; Save off integer portion
	swap	d3
	bmi.s	.pre0		; negative means steep slope
	move.w	#0,d1		; Calculate fractional part
	divu	d0,d1
	move.w	d1,d3
	lea	_tantab,a0
	moveq	#0,d0
.3	cmp.l	0(a0,d0),d3	; Is value <= item in tangent table?
	bls.s	.4
	addq	#4,d0
	cmp	#91*4,d0	; Loop until we have visited all items
	blo.s	.3
	subq	#4,d0
.4	lsr.l	#2,d0
	tst	d2		; Negate result if Y was negative
	beq.s	.5
	neg.l	d0
.5	tst	d4		; subtract from 180 if negative
	beq.s	.exit
	subi.l	#180,d0
	neg.l	d0
.exit	movem.l	(sp)+,d1-d4/a0
	unlk	a6
	rts

*************************************************************************
*                 FRACTIONAL ARCTANGENT ROUTINE (RESULT IN DEGREES)     *
*************************************************************************

	ELSEC

	XREF	_atantab
	XDEF	_fatan2

_fatan2	link	a6,#0
	movem.l	d1-d4/a0,-(sp)
	moveq.l	#0,d2		; Signflag = FALSE
	moveq.l	#0,d3		; 45 degree flip = FALSE
	moveq.l	#0,d4		; Second Signflag = FALSE
	move.l	8(a6),d0	; Get X
.0	bpl.s	.1
	not	d4		; Save sign of X for later
	neg.l	d0
.1	move.l	12(a6),d1	; Get Y
	bpl.s	.2
	neg.l	d1
	not	d2		; Save sign of Y for later
.2	cmp.l	d0,d1		; we want a fraction
	bmi.s	.25
	exg.l	d0,d1
	not	d3
.25	move.w	#0,d0		; Change Y fraction into an integer
	swap	d0
	bne	.27		; if 0 we don't divide
.pre0	move.l	#90,d0
	bra.s	.4
.27	divu	d0,d1		; Y/X
	bvs.s	.pre0		; overflow means steep slope 90 or 270
	andi.w	#$ff00,d1
	lsr.w	#6,d1
	lea	_atantab,a0
	move.l	(a0,d1.w),d0	; Is value <= item in tangent table?
.4	tst	d3
	beq.s	.45
	subi.l	#90,d0
	beq.s	.5		; no need to neg if 0
	neg.l	d0
.45	tst	d2		; Negate result if Y was negative
	beq.s	.5
	neg.l	d0
.5	tst	d4		; subtract from 180 if negative
	beq.s	.exit
	subi.l	#180,d0
	beq.s	.exit
	neg.l	d0
.exit	tst	d0
	bpl.s	.post
	addi.l	#360,d0
.post	movem.l	(sp)+,d1-d4/a0
	unlk	a6
	rts

	ENDC

*************************************************************************
*                 32x32 BIT FRACTIONAL MULTIPLY (32 BIT RESULT)         *
*************************************************************************

ZEROCHK	equ	1
KNUTH	equ	0

	XDEF	_fmul

	IFEQ	ZEROCHK
_fmul	link	a6,#0
	movem.l	d1-d5,-(sp)
	clr	d4		; Signflag = FALSE
	move.l	8(a6),d0	; Get multiplier
	bpl.s	.ms1
	not	d4
	neg.l	d0
.ms1	move.l	12(a6),d2	; Get multiplicand
	bpl.s	.ms2
	not	d4
	neg.l	d2
.ms2	move.l	d0,d1		; copy A to d1
	swap	d1		;4-82 AH
	move.l	d0,d3		;4-4 copy A to d3
	move.l	d0,d5		;4-8 copy A to d5
	mulu	d2,d5		;70-78 BL * AL
	mulu	d2,d1		;70-152 BL * AH
	swap	d2		;4-156 BH
	swap	d0		;4-160 AH
	mulu	d2,d0		;70-230 BH * AH
	mulu	d2,d3		;70-300 BH * AL
	add.l	d3,d1		;6-316 x = ((BH * AL) + (BL * AH)) << 16
	swap	d0		;4-320 (BH * AH) << 32 + x + (BL * AL)
	move	#0,d0		;8-328
	move	#0,d5		;8-336
	swap	d5		;4-340
	add.l	d1,d0		;6-346
	add.l	d5,d0
	tst	d4
	beq.s	.mout
	neg.l	d0
.mout	movem.l	(sp)+,d1-d5
	unlk	a6
	rts


	ELSEC

_fmul	link	a6,#0
	movem.l	d1-d5,-(sp)
	clr	d4		; Signflag = FALSE
	move.l	8(a6),d0	; Get multiplier
	beq.s	.out		; if d0 = 0 product will = 0
	bpl.s	.s1
	not	d4
	neg.l	d0
.s1	move.l	12(a6),d2	; Get multiplicand
	bne	.s1.5
	moveq	#0,d0
	bra	.out
.s1.5	bpl.s	.s2
	not	d4
	neg.l	d2
.s2	tst.w	d0
	beq	.top0		; only the top is non-zero 
	move.l	d0,d1		; copy A to d1
	swap	d1		;4-82 AH
	tst.w	d1
	beq	.bot0		;only the bottom is non-zero
	move.l	d0,d3		;4-4 copy A to d3
	move.l	d0,d5		;4-8 copy A to d5
	tst.w	d2
	beq	.top2
	mulu	d2,d5		;70-78 BL * AL
	mulu	d2,d1		;70-152 BL * AH
	swap	d2		;4-156 BH
	tst.w	d2
	beq	.bot2
	swap	d0		;4-160 AH
	mulu	d2,d0		;70-230 BH * AH
	mulu	d2,d3		;70-300 BH * AL
	add.l	d3,d1		;6-316 x = ((BH * AL) + (BL * AH)) << 16
	swap	d0		;4-320 (BH * AH) << 32 + x + (BL * AL)
	move	#0,d0		;8-328
	move	#0,d5		;8-336
	swap	d5		;4-340
	add.l	d1,d0		;6-346
	add.l	d5,d0
	tst	d4
	beq.s	.out
	neg.l	d0
.out	movem.l	(sp)+,d1-d5
	unlk	a6
	rts
.top0	swap	d0		;getting the top
	move.l	d0,d1		;copying for second mutliply
	mulu	d2,d1		;BL * AH whole long important
	swap	d2
	mulu	d2,d0		;BH * AH
	swap	d0
	move	#0,d0
	add.l	d1,d0
	tst	d4
	beq.s	.outt0
	neg.l	d0
.outt0	movem.l	(sp)+,d1-d5
	unlk	a6
	rts
.bot0	swap	d1		;getting the bottom back
	mulu	d2,d1		;BL * AL only top important
	swap	d2
	mulu	d2,d0		;BH * AL whole long important
	move	#0,d1
	swap	d1
	add.l	d1,d0
	tst	d4
	beq.s	.outb0
	neg.l	d0
.outb0	movem.l	(sp)+,d1-d5
	unlk	a6
	rts
.top2	swap	d2		;now has the top
	mulu	d2,d0		;BH * AL whole long important
	mulu	d2,d1		;BH * AH only low word important
	swap	d1
	move	#0,d1
	add.l	d1,d0
	tst	d4
	beq.s	.outt2
	neg.l	d0
.outt2	movem.l	(sp)+,d1-d5
	unlk	a6
	rts
.bot2	move.l	d1,d0		;BL * AH whole long important
	move.w	#0,d5		;BL * AL only top important
	swap	d5
	add.l	d5,d0
	tst	d4
	beq.s	.outb2
	neg.l	d0
.outb2	movem.l	(sp)+,d1-d5
	unlk	a6
	rts
	
	ENDC


	IFNE	 KNUTH

*				; change if to KNUTH

_fmul	link	a6,#0
	movem.l	d1-d5,-(sp)
	clr.l	d4		;+2 (6 intead of 8) Signflag = FALSE
	move.l	8(a6),d0	; Get multiplier 
	bpl.s	ms1
	not.w	d4		;
	neg.l	d0
ms1	move.l	12(a6),d2	; Get multiplicand
ms1.5	bpl.s	ms2
	not.w	d4		;
	neg.l	d2
ms2	move.l	d0,d1		; multiplier top in d1

*	from here to ms5 the code is altered radically

	swap	d1		;4-4
	swap	d4		;4-8	this word is signflag #2
	move.l	d2,d3		;4-12 multiplicand top in d3
	swap 	d3		;4-16
	sub.w	d0,d1		;4-20 bottom - top
	bcc.s	ms3		;8-28 (6 less if not taken)
	neg.w	d1		;4-32
	not.w	d4		;4-36
ms3	move.w	d2,d5		;4-40 multiplicand top
	sub.w	d3,d5		;4-44 top - bottom
	bcc.s	ms4		;8-52
	neg.w	d5		;4-56 (6 less if not taken)
	not.w	d4		;4-60
ms4	mulu	d1,d5		;70-130 the cross product result
	move.l	d0,d1		;4-134 multiplier top in d1
	swap	d1		;4-138
	mulu	d0,d2		;70-208 the bottoms
	mulu	d1,d3		;70-278 the tops
	move.l	d3,d0		;4-282
	add.l	d2,d0		;6-288 the bottom 32 bits
	swap	d3		;4-292
	clr.w	d3		;4-296 top also gets added to upper 16
	add.l	d3,d0		;6-302
	clr.w	d2		;4-306
	swap	d2		;4-310	
	add.l	d2,d0		;6-316
	tst.w	d4		;4-320
	beq	ms5		;8-328 (4 less if not taken)
	neg.l	d5		;6-334
ms5	add.l	d5,d0		; cross product (could be negative)
	swap	d4		;4
	tst.w	d4
	beq.s	mout
	neg.l	d0
mout	movem.l	(sp)+,d1-d5
	unlk	a6
	rts

	ENDC

*************************************************************************
*                 32x32 BIT FRACTIONAL DIVIDE (32 BIT RESULT)           *
*************************************************************************

	XDEF	_fdiv
_fdiv	link	a6,#0
	movem.l	d1-d5,-(sp)
	clr	d4		; Signflag = FALSE
	move.l	8(a6),d0	; Get dividend
	bpl.s	.s1
	not	d4
	neg.l	d0
.s1	move.l	12(a6),d1	; Get divisor
	beq.s	.out		; We don't do division by zero
	bpl.s	.s2
	not	d4
	neg.l	d1
.s2	move.l	d0,d5		; Set up extra 16 bits
	swap	d5
	move	#0,d5
	move	d5,d0
	swap	d0
	clr.l	d2
	move	#64-1,d3	; Loop 64 times
	move	#0,CCR		; Clear X flag
.loop	roxl.l	#1,d5
	roxl.l	#1,d0
	roxl.l	#1,d2
	cmp.l	d1,d2
	blt.s	.dec		; if dividend < divisor loop
	sub.l	d1,d2		; else dividend -= divisor
	move	#$10,CCR	; Set X flag
.dec	dbra	d3,.loop
	roxl.l	#1,d5		; shift in last bit
	move.l	d5,d0
	tst	d4
	beq.s	.out
	neg.l	d0
.out	movem.l	(sp)+,d1-d5
	unlk	a6
	rts


	XDEF	_SYS_SetPalette
_SYS_SetPalette
	link	a6,#0
	movem.l	a1,-(sp)
	move.l	8(a6),a0
	bsr	SetPalette
	movem.l	(sp)+,a1
	unlk	a6
	rts

* C Callable SYS_SendPalette:
*	Send the PalBuffer to CRAM (No Fade In)
*	SYS_SetPalette();

	XDEF	_SYS_SendPalette
_SYS_SendPalette
	movem.l	d1/a1,-(sp)
	bsr	JumpIn
	movem.l	(sp)+,d1/a1
	rts

* C Callable SYS_ClrPalette:
*	Black out all colors
*	SYS_ClrPalette();

	XDEF	_SYS_ClrPalette
_SYS_ClrPalette
	movem.l	d1/a1,-(sp)
	bsr	BlackOut
	movem.l	(sp)+,d1/a1
	rts

* C Callable _SYS_FadeIn:
*	SYS_FadeIn(UWORD frames);

	XDEF	_SYS_FadeIn
_SYS_FadeIn
	link	a6,#0
	movem.l	d1-d7/a0-a5,-(sp)
	move.l	8(a6),d0
	bsr	FadeIn
	movem.l	(sp)+,d1-d7/a0-a5
	unlk	a6
	rts

* C Callable _SYS_FadeOut:
*	SYS_FadeOut(UWORD frames);

	XDEF	_SYS_FadeOut
_SYS_FadeOut
	link	a6,#0
	movem.l	d1-d7/a0-a5,-(sp)
	move.l	8(a6),d0
	bsr	FadeOut
	movem.l	(sp)+,d1-d7/a0-a5
	unlk	a6
	rts

* C Callable SYS_SetVAddr:
*	SYS_SetVAddr(UWORD video_addr);

	XDEF	_SYS_SetVAddr
_SYS_SetVAddr
	link	a6,#0
	move.l	8(a6),d0
	bsr	SetVRAMWrite
	unlk	a6
	rts

* C Callable SYS_SetVAddr:
*	SYS_SetVSAddr(UWORD video_addr);

	XDEF	_SYS_SetVSAddr
_SYS_SetVSAddr
	link	a6,#0
	move.l	8(a6),d0
	bsr	SetVSRAMWrite
	unlk	a6
	rts

* C Callable DMA:
*	SYS_DMA(UWORD video_addr,UWORD length,UWORD *src_addr)

	XDEF	_SYS_DMA
_SYS_DMA
	link	a6,#0
	movem.l	d1/a0,-(sp)
	move.l	8(a6),d0
	move.l	12(a6),d1
	move.l	16(a6),a0
	bsr	CopyToVRAM
	moveq	#0,d0
	movem.l	(sp)+,d1/a0
	unlk	a6
	rts

**************************************************************************
**         SCAN JOYSTICK INTERFACE AND GENERATE HIT AND HELD INFO        *
**************************************************************************

	XDEF	ScanJoy1
ScanJoy1
	jsr	_gemsholdz80
	lea	Data1,a0	;point to hardware
	move.b	#$00,(a0)	;TH=0
	nop
	nop			;wait
	move.b	(a0),d0		;get bits 6..7 (in 4..5)
	lsl.w	#2,d0		;move to 6..7
	move.b	#$40,(a0)	;TH=1
	and.w	#$C0,d0		;mask 6..7
	move.b	(a0),d1		;get 0..5
	jsr	_gemsreleasez80
	and.w	#$3f,d1		;mask 0..5
	or.w	d1,d0		;combine (top byte of word=0)
	lea	KeyTab1,a0	;point to button status table
	moveq	#8-1,d1		;8 buttons
.j_key	lsr.b	#1,d0		;check bit
	bcs.s	.j_up		;skip if up
	tst.b	(a0)		;test held status
	bne.s	.j_next		;skip if already down
	st	KeyHit		;flag hit occured (global)
	move.w	#$101,(a0)	;flag hit and held
	bra.s	.j_next		;next bit
.j_up	clr.b	(a0)		;not held (leave hit status)
.j_next	addq.w	#2,a0		;next ststus entry
	dbra	d1,.j_key	;do all bits
	rts

***
**	Second joystick scanner
***

	XDEF	ScanJoy2
ScanJoy2
	jsr	_gemsholdz80
	lea	Data2,a0	;point to hardware
	move.b	#$00,(a0)	;TH=0
	nop
	nop			;wait
	move.b	(a0),d0		;get bits 6..7 (in 4..5)
	lsl.w	#2,d0		;move to 6..7
	move.b	#$40,(a0)	;TH=1
	and.w	#$C0,d0		;mask 6..7
	move.b	(a0),d1		;get 0..5
	jsr	_gemsreleasez80
	and.w	#$3f,d1		;mask 0..5
	or.w	d1,d0		;combine (top byte of word=0)
	lea	KeyTab2,a0	;point to button status table
	moveq	#8-1,d1		;8 buttons
.j_key2	lsr.b	#1,d0		;check bit
	bcs.s	.j_up2		;skip if up
	tst.b	(a0)		;test held status
	bne.s	.j_next		;skip if already down
	st	KeyHit		;flag hit occured (global)
	move.w	#$101,(a0)	;flag hit and held
	bra.s	.j_next		;next bit
.j_up2	clr.b	(a0)		;not held (leave hit status)
.j_next	addq.w	#2,a0		;next ststus entry
	dbra	d1,.j_key2	;do all bits
	rts

**************************************************************************
**                         CLEAR JOYSTICK HIT INFO                       *
**************************************************************************

	XDEF	ClearKeys
ClearKeys
	sf	KeyHit		;flag no key hit
	lea	KeyTab1+1,a0	;point at hit entries
	moveq	#8-1,d0		;8 of them
ck_lp	sf	(a0)+		;clear hit flag
	addq.w	#1,a0		;index next hit ststus
	dbra	d0,ck_lp	;do all
	rts

**************************************************************************
**                 SYNCHRONIZE TO VERTICAL VIDEO INTERRUPT               *
**************************************************************************
*interrupts must be ON!

	XDEF	WaitFrame,_SYS_WaitFrame
_SYS_WaitFrame
WaitFrame
	sf	FlyBackFlag	;clear flag
.lp	tst.b	FlyBackFlag	;has interrupt set it yet
	beq.s	.lp		;wait until it has
	rts

**************************************************************************
**                         CLEAR JOYSTICK HIT INFO                       *
**************************************************************************
*entry:-
*d0 = number of frames to wait (remember: 60/s on NTSC, 50/s on PAL)

	XDEF	WaitFrames
WaitFrames
	subq.w	#1,d0
wfs_lp
	bsr	WaitFrame
	dbra	d0,wfs_lp
	rts

**************************************************************************
**                            SET WRITE TO VRAM                          *
**************************************************************************

*entry:-
*d0 = VRAM address

	XDEF	SetVRAMWrite
SetVRAMWrite
	move.l	d0,-(sp)
	or.w	#CD0,d0
	swap	d0
	move.w	2(sp),d0
	rol.w	#2,d0
	and.l	#($FFFF-CD1)<<16+%11,d0
	move.l	d0,VDPControl
	move.l	(sp)+,d0
	rts

**************************************************************************
**                            SET READ FROM VRAM                         *
**************************************************************************
*entry:-
*d0 = VRAM address

	XDEF	SetVRAMRead
SetVRAMRead
	move.l	d0,-(sp)
	swap	d0
	move.w	2(sp),d0
	rol.w	#2,d0
	and.l	#($FFFF-CD1-CD0)<<16+%11,d0
	move.l	d0,VDPControl
	move.l	(sp)+,d0
	rts

**************************************************************************
**                            SET WRITE TO CRAM                          *
**************************************************************************
*entry:-
*d0 = CRAM address

	XDEF	SetCRAMWrite
SetCRAMWrite
	and.w	#$7F,d0
	or.w	#CD1+CD0,d0
	move.w	d0,VDPControl
	move.w	#0,VDPControl
	and.w	#$7F,d0
	rts

**************************************************************************
**                            SET READ FROM CRAM                         *
**************************************************************************
*entry:-
*d0 = CRAM address

	XDEF	SetCRAMRead
SetCRAMRead
	and.w	#$7F,d0
	move.w	d0,VDPControl
	move.w	#CD3,VDPControl
	rts

**************************************************************************
**                            SET WRITE TO VSRAM                         *
**************************************************************************
*entry:-
*d0 = VSRAM address

	XDEF	SetVSRAMWrite
SetVSRAMWrite
	and.w	#$3f,d0
	or.w	#CD0,d0
	move.w	d0,VDPControl
	move.w	#CD2,VDPControl
	and.w	#$3f,d0
	rts

**************************************************************************
**                            SET READ FROM VSRAM                        *
**************************************************************************
*entry:-
*d0 = VSRAM address

	XDEF	SetVSRAMRead
SetVSRAMRead
	and.w	#$3f,d0
	move.w	d0,VDPControl
	move.w	#CD2,VDPControl
	rts

**************************************************************************
**                SET ALL ENTRIES IN PALETTE TO COLOUR 0                 *
**************************************************************************

	XDEF	BlackOut
BlackOut
	moveq	#0,d0		;CRAM address 0
	bsr	SetCRAMWrite	;set write to CRAM
	moveq	#64*2/4-1,d1	;long words less 1
bo_lp
	move.l	d0,VDPData	;clear 2 entries
	dbra	d1,bo_lp	;until all clear
	rts

**************************************************************************
**                        CREATE PALETTE SLAVE BUFFER                    *
**************************************************************************

*entry:-
*a0 = pointer to data structure
*	dc.w	startcolour
*	dc.w	number
*
*	dc.w	colour
*	...
*
*	dc.w	-1 (or repeat structure)

	XDEF	SetPalette
SetPalette
	bra.s	sp_get		;jump to start
sp_set
	lea	PalBuffer,a1	;point at slave buffer
	add.w	d0,d0		;2*colour
	add.w	d0,a1		;index correct slave
	move.w	(a0)+,d0	;get count of values
	subq.w	#1,d0		;for dbra
sp_lp
	move.w	(a0)+,(a1)+	;copy value to slave buffer
	dbra	d0,sp_lp	;do values
sp_get
	move.w	(a0)+,d0	;get flag/address
	bpl.s	sp_set		;adress if not -ve
	rts			;stop

**************************************************************************
**                     COPY PALETTE SLAVES TO PALETTE                    *
**************************************************************************

	XDEF	JumpIn
JumpIn
	moveq	#0,d0		;first colour
	bsr	SetCRAMWrite	;set write to colour RAM
	lea	PalBuffer,a0	;point at slaves
	moveq	#64-1,d0	;number of colours (4*16 colour palettes)
ji_lp
	move.w	(a0)+,VDPData	;move data to CRAM
	dbra	d0,ji_lp	;move all
	rts

**************************************************************************
**                          FADE PALETTE IN                              *
**************************************************************************
*interrupts must be ON!
*entry:-
*d0 = frames to take

	XDEF	FadeIn
FadeIn
	lea	PalBuffer,a0	;point to slaves
FadeAnyIn
	move.w	d0,d7		;maximum frame
	moveq	#1,d6		;first frame
	moveq	#1,d5		;direction
      	bra.s	f_join		;do it

**************************************************************************
**                          FADE PALETTE OUT                             *
**************************************************************************
*interrupts must be ON!
*entry:-
*d0 = frames to take

	XDEF	FadeOut
FadeOut
	lea	PalBuffer,a0	;point to slaves
	move.w	d0,d7		;maximum frame
	move.w	d0,d6
	subq.w	#1,d6		;first frame
	moveq	#-1,d5		;direction
	moveq	#0,d0		;set address of palettes (in CRAM)
	bsr	SetCRAMRead	;set read of palette
	moveq	#64-1,d0	;words
f_get
	move.w	VDPData,(a0)+	;read palette
	dbra	d0,f_get	;read all
	lea	-128(a0),a0	;point to buffer
f_join
	move.w	d7,d4
	subq.w	#1,d4		;frames to do (adjusted for dbra)
f_fade
	lea	PalTemp,a1	; Working Buffer (KLM)
	moveq	#64-1,d1	;every colour
f_set
	move.b	(a0)+,d0	;1st byte of data
	bsr	f_nib		;do nybble
	move.b	d0,-(sp)
	move.w	(sp)+,d0	;byte swap
	move.b	(a0)+,d0	;2nd byte of data
	ror.b	#4,d0		;top nibble
	bsr	f_nib		;do nybble
	ror.b	#4,d0		;bottom nibble
	bsr	f_nib		;do nybble
	move.w	d0,(a1)+	; Save to working buffer (KLM)
	dbra	d1,f_set	;do all colours

	bsr	WaitFrame	;synchronize to video
	moveq	#0,d0		;address to write (in CRAM)
	bsr	SetCRAMWrite	;set write palette
	lea	PalTemp,a1	; Working Buffer (KLM)
	moveq	#64-1,d1	; Send working buffer (KLM)
f_send	move.w	(a1)+,VDPData	;set colour
	dbra	d1,f_send	;do all colours

	lea	-128(a0),a0	;point to buffer again
	add.w	d5,d6		;next frame
	dbra	d4,f_fade	;fade
	rts
f_nib
	move.w	d0,d3
	and.w	#$f,d0		;get nibble
	eor.w	d0,d3		;clear nibble
	mulu	d6,d0
	divu	d7,d0		;scale for current frame
	and.w	#$e,d0		;discard bottom bit
	or.w	d3,d0		;include other nibbles
	rts

**************************************************************************
**                       WAIT FOR DMA TO FINISH                          *
**************************************************************************
*only required when moving from ROM or work RAM

	XDEF	_SYS_WaitForDMA
	XDEF	WaitForDMA
_SYS_WaitForDMA
WaitForDMA
	move.w	VDPStatus,d0	;get status
	and.w	#DMA,d0		;DMA finished?
	bne.s	WaitForDMA	;loop if not
	rts

**************************************************************************
**                 CLEAR VERTICAL SCROLL RAM                             *
**************************************************************************

	XDEF	ClearVSRAM
ClearVSRAM
	moveq	#0,d0		;start address
	bsr	SetVSRAMWrite	;set VSRAM write
	moveq	#80/4-1,d1	;long words
	lea	VDPData,a0	;point to VDP data port
cv_lp
	move.l	d0,(a0)		;clear scrolls
	dbra	d1,cv_lp	;clear all
	rts
	
**************************************************************************
**                 CLEAR HORIZONTAL SCROLL RAM                           *
**************************************************************************

	XDEF	ClearHSRAM
ClearHSRAM
	move.w	#HScroll,d0	;address of scroll table (in VRAM)
	bsr	SetVRAMWrite	;set write to VRAM
	moveq	#0,d0		;clear d0
	move.w	#1024/4-1,d1	;long words
	lea	VDPData,a0	;point to VDP data port
ch_lp	move.l	d0,(a0)		;clear scrolls
	dbra	d1,ch_lp	;clear all
	rts

**************************************************************************
**      COPY DATA FROM WORK RAM OR ROM TO VRAM USING DMA                 *
**************************************************************************

*entry:-
*d0 = VRAM address
*d1 = length of data (bytes)
*a0 = pointer to data
         
	XDEF	CopyToVRAM
CopyToVRAM
	move.l	d2,-(sp)
	jsr	_gemsdmastart
	move	#$8F02,VCTRL
	move	#$8174,VCTRL
	lsr.w	#1,d1		; convert length to words
	move.w	d1,-(sp)
	move	#$9300,d2
	move.b	d1,d2
	move	d2,VCTRL
	add	#$0100,d2
	move.b	(sp)+,d2
	move	d2,VCTRL
	move.l	a0,d1		;get address
	lsr.l	#1,d1		;convert to word address
	add	#$0100,d2	; Set DMA Address
	move.b	d1,d2
	move	d2,VCTRL
	move.w	d1,-(sp)
	move.b	(sp)+,d2
	add	#$0100,d2
	move	d2,VCTRL
	swap	d1
	and.b	#$7F,d1
	add	#$0100,d2
	move.b	d1,d2
	move.w	d2,VCTRL
* Set VRAM Address
	move	d0,d2
	lea	VCTRL,a0
	and.w	#$FFFF-CD1,d0	;clear CD1
	or.w	#CD0,d0		;set CD0
	move.w	d0,(a0)		;set first word of address
	move	d2,d0
	move.l	DMATrigger(pc),DMATemp	;move trigger code to work RAM
	rol.w	#2,d0		;move bits 14/15 to bits 0/1
	and.w	#%11,d0		;mask them (clear CD2 and other bits)
	or.w	#$80,d0		;set bit 7
	jsr	DMATemp		;call the trigger (set second word of address)
	move	#$8164,VCTRL
	jsr	_gemsdmaend
	move.l	(sp)+,d2
	rts
DMATrigger
	move.w	d0,(a0)		;\ this code is moved to and executed in work RAM
	rts			;/

**************************************************************************
**      COPY DATA FROM WORK RAM OR ROM TO VRAM WITHOUT DMA               *
**************************************************************************
*entry:-
*d0 = VRAM address
*d1 = length of data (bytes) assumed even
*a0 = pointer to data

	XDEF	CopyToVRAM2
CopyToVRAM2
	bsr	SetVRAMWrite	;set VRAM address for write
	lsr.w	#1,d1		;words
	subq.w	#1,d1		;adjust for dbra
ctv_load
	move.w	(a0)+,VDPData	;load word
	dbra	d1,ctv_load	;until done
	rts

**************************************************************************
**                           LOAD A CHARACTER SET INTO VRAM              *
**************************************************************************
*entry:-
*d0 = first cell number
*d1 = number of characters
*d2 = foreground colour
*d3 = background colour
*a0 = pointer to sets of 8 bytes of 2 colour character data

	XDEF	LoadChars
LoadChars
	lsl.w	#5,d0		;make VRAM address
	bsr	SetVRAMWrite	;set write to VRAM
	lsl.w	#3,d1		;bytes to expand
	subq.w	#1,d1		;adjust for dbra
	lea	VDPData,a1	;point at data port
	and.w	#$f,d2
	and.w	#$f,d3		;force colours into range
	mulu	#%1000100010001,d2
	mulu	#%1000100010001,d3 ;duplicate nybble into all 4 nybbles
lc_bytes
	move.b	(a0),d0		;get byte
	and.w	#$f0,d0		;mask top nybble
	lsr.w	#3,d0		;make index
	bsr	lc_donybble	;expand nybble
	move.b	(a0)+,d0	;reget byte (and move data ptr)
	and.w	#$0f,d0		;mask bottom nybble
	add.w	d0,d0		;make mask
	bsr	lc_donybble	;expand nybble
	dbra	d1,lc_bytes	;expand all
	rts
lc_donybble
	move.w	lc_nybble4(pc,d0.w),d4 ;expand a nybble
	move.w	d4,d0		;duplicate
	not.w	d0		;make background mask
	and.w	d2,d4		;put in colour
	and.w	d3,d0		;put in other colour
	or.w	d4,d0		;combine
	move.w	d0,(a1)		;write expanded word to VRAM
	rts
lc_nybble4
	dc.w	$0000,$000F,$00F0,$00FF
	dc.w	$0F00,$0F0F,$0FF0,$0FFF
	dc.w	$F000,$F00F,$F0F0,$F0FF
	dc.w	$FF00,$FF0F,$FFF0,$FFFF
	

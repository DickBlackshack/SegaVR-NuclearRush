*************************************************************************
*               DECOMPRESSION ROUTINE LZSS		                *
*		12 bit index, 4 bit length				*
*************************************************************************

	OPT	LLBL

	BSECTION	.bss

		ds.w	0	; Align to word
temp_seek	ds.l	1	
temp_total	ds.l	1	
temp_xpnd_buff	ds.l	1	
lz_start	ds.l	1	;location of the compressed data
lz_current	ds.l	1	;the current byte of the compressed data
buff_start	ds.l	1	;location in RAM of the ring buffer
lz_pointer	ds.l	1	;moved by lz_seek, moved and used by lz_read
lz_seek_value	ds.l	1	;moved by lz_seek, moved and used by lz_read
buff_pointer	ds.w	1
bit_pointer	ds.w	1	;and current
xpnd_total	ds.l	1	;total bytes in the expanded file
ring_lo		ds.l	1	;ring_hi - 4095 or 0, whichever is lowest
ring_hi		ds.l	1	;buff_pointer + (4096 * #of times thru buffer)
bit_mask	ds.b	1
		ds.w	0	; Align to word

	TSECTION	.text

* C Callable LZ_Open:
*	LZ_Open(BYTE *comp_data,BYTE *ring_buffer)

	XDEF	_LZ_Open
_LZ_Open
	link	a6,#0
	movem.l	a0-a1,-(sp)
	move.l	8(a6),a0
	move.l	12(a6),a1
	bsr	lz_open
	moveq	#0,d0
	movem.l	(sp)+,a0-a1
	unlk	a6
	rts

*entry:-
*a0 = pointer to compressed data
*a1 = pointer to ring buffer to be decompressed into

	XDEF	lz_open
lz_open
	movem.l	d0/a1,-(sp)
	move.l	a0,lz_start
	move.l	a1,buff_start
	move.l	#0,lz_pointer	
	move.l	#0,lz_seek_value
	move.l	(a0)+,xpnd_total	; size of decompressed data
	move.l	a0,lz_current
	move.b	#$80,bit_mask		; mask for the compress stuff
	move.w	#1,bit_pointer		; used for shifts
  	move.w	#0,buff_pointer
  	move.l	#0,ring_lo
  	move.l	#0,ring_hi

	move.w	#4096+18-1,d0
init_xpnd_loop
	move.b	#0,(a1,d0.w)
	dbra	d0,init_xpnd_loop


	movem.l	(sp)+,d0/a1
	rts

* C Callable LZ_Read:
*	LZ_Read(BYTE *buffer,ULONG num_bytes)

	XDEF	_LZ_Read
_LZ_Read
	link	a6,#0
	movem.l	a0,-(sp)
	move.l	8(a6),a0
	move.l	12(a6),d0
	bsr	lz_read
	moveq	#0,d0
	movem.l	(sp)+,a0
	unlk	a6
	rts

*entry:-
*a0 = pointer to where to expand to
*d0 = number of bytes to expand
*uses a0, a1, a2, d1, d2, d3, d4, d5, d6, d7

	XDEF	lz_read
lz_read
	movem.l	d1-d7/a0-a2,-(sp)
	move.b	bit_mask,d3
	move.w	bit_pointer,d4
	move.w	buff_pointer,d1
	move.l	buff_start,a1	
	move.l	a0,a2
	move.l	lz_current,a0
	move.l	lz_pointer,d2

;now we want to fill a2 from lz_current to ring_hi
	move.l	ring_hi,d5
	move.l	lz_seek_value,d6	
	cmp.l	d6,d5
	beq	no_prepack
	and.w	#4095,d6

lzr_lp0	move.b	(a1,d6.w),(a2)+
	addq.w	#1,d6
	subq.l	#1,d0
	beq	lzrexit		; could be finished
	cmp.w	d6,d1
	bne	lzr_lp0

no_prepack
lzr0	move.b	(a0),d6
	and.b	d3,d6
	bne	lzr_next8
	cmp.b	#1,d3		
	beq	ez_next16
	move.b	(a0)+,d5	; get the bits from this byte and bump
	lsl.w	#8,d5
	move.b	(a0)+,d5	; get the bits from this byte and bump
	move.w	#0,d6
	move.b	(a0),d6		; get the bits from this byte
	lsl.w	d4,d5		; shift left
	subi.w	#8,d4		; putting 8 - d4 into d4	
	neg.w	d4
	lsr.b	d4,d6		; shift right
	or.w	d5,d6
	move.w	d6,d5
	lsr.w	#4,d5		; pointer into ring buffer
	subi.w	#1,d5
	andi.w	#4095,d5
	andi.l	#$0f,d6		; counter of bytes
	addi.w	#1,d6		; this is the value of BREAK_EVEN in lzss.c
	add.l	d6,ring_hi
	add.l	#1,ring_hi
	move.l	ring_hi,d7
	subi.l	#4095,d7
	cmp.l	ring_lo,d7
	bmi	lzr_lp01
	move.l	d7,ring_lo
lzr_lp01
	move.b	(a1,d5.w),(a1,d1.w)	;to the ring buffer
;	cmp.l	#0,d0
;	beq	nowrite01
	move.b	(a1,d5.w),(a2)+		;to the real buffer
;nowrite01
	addi.w	#1,d5
	andi.w	#4095,d5
	addi.l	#1,d2			;lz_pointer up one
	addi.w 	#1,d1
	andi.w	#4095,d1
	subq.l	#1,d0
	cmp.l	#-1,d0
	bne	lzr_mc01		; could be finished
	move.l	#0,d0
	move.l	a1,a2
	add.w	d5,a2
lzr_mc01
	dbra	d6,lzr_lp01


	subi.w	#8,d4		; putting d4 back to right
	neg.w	d4		; reversing the action above
	andi.w	#7,d4
	addq.w	#1,d4		; the shift changes
	lsr.b	#1,d3		; the mask moves
	cmp.l	#0,d0
	beq	lzrexit
	bra	lzr0		; will fall out if equal
ez_next16
	addq	#1,a0		; we used the last bit from a byte
	move.b	(a0)+,d5	; get the bits from this byte and bump
	move.w	#0,d6
	move.b	(a0)+,d6	; get the bits from this byte and bump
	lsl.w	#8,d5
	or.w	d6,d5
	lsr.w	#4,d5		; pointer into ring buffer
	subi.w	#1,d5
	andi.w	#4095,d5
	andi.l	#$0f,d6		; counter of bytes
	addi.w	#1,d6		; this is the value of BREAK_EVEN in lzss.c
	add.l	d6,ring_hi
	add.l	#1,ring_hi
	move.l	ring_hi,d7
	subi.l	#4095,d7
	cmp.l	ring_lo,d7
	bmi	lzr_lp02
	move.l	d7,ring_lo
lzr_lp02
	move.b	(a1,d5.w),(a1,d1.w)	;to the ring buffer
;	cmp.l	#0,d0
;	beq	nowrite02
	move.b	(a1,d5.w),(a2)+		;to the real buffer
;nowrite02
	addi.w	#1,d5
	andi.w	#4095,d5
	addi.l	#1,d2			;lz_pointer up one
	addi.w 	#1,d1
	andi.w	#4095,d1
	subq.l	#1,d0
	cmp.l	#-1,d0
	bne	lzr_mc02		; could be finished
	move.l	#0,d0
	move.l	a1,a2
	add.w	d5,a2
lzr_mc02
	dbra	d6,lzr_lp02

	move.w	#1,d4		; the shift value
	move.b	#$80,d3		; the bit mask
	cmp.l	#0,d0
	beq	lzrexit
	bra	lzr0
lzr_next8
	cmp.b	#1,d3		
	beq	ez_next8
	move.b	(a0)+,d5	; get the bits from this byte and bump
	move.b	(a0),d6		; get the bits from this byte
	lsl.b	d4,d5		; shift left
	subi.w	#8,d4	
	neg.w	d4
	lsr.b	d4,d6		; shift right
	or.b	d5,d6		; or them together
	move.b	d6,(a1,d1.w)
	move.b	d6,(a2)+
	subi.w	#8,d4	
	neg.w	d4		; reversing the action above
	andi.w	#7,d4
	addq.w	#1,d4		; the shift changes
	lsr.b	#1,d3		; the mask moves
	addq.w	#1,d1
	andi.w	#4095,d1		
	addq.w	#1,d2		
	addq.l	#1,ring_hi
	move.l	ring_hi,d7
	subi.l	#4095,d7
	cmp.l	ring_lo,d7
	bmi	lzr_lp03
	move.l	d7,ring_lo
lzr_lp03
	subq.l	#1,d0
	beq	lzrexit
	bne	lzr0
ez_next8
	addq	#1,a0		; we used the last bit from a byte
	move.b	(a0)+,(a1,d1.w)	; we get a byte add bump the pointer again
	move.b	(a1,d1.w),(a2)+	; we get a byte add bump the pointer again
	move.w	#1,d4		; the shift value
	move.b	#$80,d3		; the bit mask
	addq.w	#1,d1		
	andi.w	#4095,d1		
	addq.w	#1,d2		
	addq.l	#1,ring_hi
	move.l	ring_hi,d7
	subi.l	#4095,d7
	cmp.l	ring_lo,d7
	bmi	lzr_lp04
	move.l	d7,ring_lo
lzr_lp04
	subq.l	#1,d0
	bne	lzr0		; will fall out if equal
lzrexit	move.w	d1,buff_pointer
	move.b	d3,bit_mask
	move.w	d4,bit_pointer
	move.l	a0,lz_current
	move.l	d2,lz_pointer
	move.l	d2,lz_seek_value
	movem.l	(sp)+,d1-d7/a0-a2
	rts

* C Callable LZ_Seek:
*	LZ_Seek(ULONG pos)

	XDEF	_LZ_Seek
_LZ_Seek
	link	a6,#0
	move.l	8(a6),d0
	bsr	lz_read
	moveq	#0,d0
	unlk	a6
	rts

*entry:-
*d0 = what to put in lz_seek_value at the end
*uses d1, d2, d3, d4, d5, d6, d7

	XDEF	lz_seek
lz_seek
	movem.l	d1-d7/a0-a1,-(sp)
lz_seek2:
	move.b	bit_mask,d3
	move.w	bit_pointer,d4
	move.w	buff_pointer,d1
	move.l	buff_start,a1	
	move.l	lz_current,a0
	move.l	lz_pointer,d2

	move.l	ring_hi,d5
	move.l	ring_lo,d6
	cmp.l 	d6,d0		;is the seek backwards from the current ring?
	bpl	no_lzopen
	move.l	lz_start,a0
	move.l	buff_start,a1
	jsr	lz_open
	bra	lz_seek2	;start again
no_lzopen
	cmp.l	d0,d2
	bpl	lzsexit		; will fall out if past

	
lzs0	move.b	(a0),d6
	and.b	d3,d6
	bne	lzs_next8
	cmp.b	#1,d3		
	beq	ezs_next16
	move.b	(a0)+,d5	; get the bits from this byte and bump
	lsl.w	#8,d5
	move.b	(a0)+,d5	; get the bits from this byte and bump
	move.w	#0,d6
	move.b	(a0),d6		; get the bits from this byte
	lsl.w	d4,d5		; shift left
	subi.w	#8,d4		; putting 8 - d4 into d4	
	neg.w	d4
	lsr.b	d4,d6		; shift right
	or.w	d5,d6
	move.w	d6,d5
	lsr.w	#4,d5		; pointer into ring buffer
	subi.w	#1,d5
	andi.w	#4095,d5
	andi.l	#$0f,d6		; counter of bytes
	addi.w	#1,d6		; this is the value of BREAK_EVEN in lzss.c
	add.l	d6,ring_hi
	addq.l	#1,ring_hi
	move.l	ring_hi,d7
	subi.l	#4095,d7
	cmp.l	ring_lo,d7
	bmi	lzs_lp01
	move.l	d7,ring_lo
lzs_lp01
	move.b	(a1,d5.w),(a1,d1.w)	;to the ring buffer
	addi.w	#1,d5
	andi.w	#4095,d5
	addi.l	#1,d2			;lz_pointer up one
	addi.w 	#1,d1
	andi.w	#4095,d1
	dbra	d6,lzs_lp01


	subi.w	#8,d4		; putting d4 back to right
	neg.w	d4		; reversing the action above
	andi.w	#7,d4
	addq.w	#1,d4		; the shift changes
	lsr.b	#1,d3		; the mask moves
	cmp.l	d0,d2
	bmi	lzs0		; will fall out if equal
	bpl	lzsexit
ezs_next16
	addq	#1,a0		; we used the last bit from a byte
	move.b	(a0)+,d5	; get the bits from this byte and bump
	move.w	#0,d6
	move.b	(a0)+,d6	; get the bits from this byte and bump
	lsl.w	#8,d5
	or.w	d6,d5
	lsr.w	#4,d5		; pointer into ring buffer
	subi.w	#1,d5
	andi.w	#4095,d5
	andi.l	#$0f,d6		; counter of bytes
	addi.w	#1,d6		; this is the value of BREAK_EVEN in lzss.c
	add.l	d6,ring_hi
	addq.l	#1,ring_hi
	move.l	ring_hi,d7
	addq	#1,d7
	subi.l	#4095,d7
	cmp.l	ring_lo,d7
	bmi	lzs_lp02
	move.l	d7,ring_lo
lzs_lp02
	move.b	(a1,d5.w),(a1,d1.w)	;to the ring buffer
	addi.w	#1,d5
	andi.w	#4095,d5
	addi.l	#1,d2			;lz_pointer up one
	addi.w 	#1,d1
	andi.w	#4095,d1
	dbra	d6,lzs_lp02

	move.w	#1,d4		; the shift value
	move.b	#$80,d3		; the bit mask
	cmp.l	d0,d2
	bmi	lzs0		; will fall out if equal
	bpl	lzsexit
lzs_next8
	cmp.b	#1,d3		
	beq	ezs_next8
	move.b	(a0)+,d5	; get the bits from this byte and bump
	move.b	(a0),d6		; get the bits from this byte
	lsl.b	d4,d5		; shift left
	subi.w	#8,d4	
	neg.w	d4
	lsr.b	d4,d6		; shift right
	or.b	d5,d6		; or them together
	move.b	d6,(a1,d1.w)
	subi.w	#8,d4	
	neg.w	d4		; reversing the action above
	andi.w	#7,d4
	addq.w	#1,d4		; the shift changes
	lsr.b	#1,d3		; the mask moves
	addq.w	#1,d1
	andi.w	#4095,d1		
	addq.w	#1,d2		
	addq.l	#1,ring_hi
	move.l	ring_hi,d7
	subi.l	#4095,d7
	cmp.l	ring_lo,d7
	bmi	lzs_lp03
	move.l	d7,ring_lo
lzs_lp03
	cmp.l	d0,d2
	bmi	lzs0		; will fall out if equal
	bpl	lzsexit
ezs_next8
	addq	#1,a0		; we used the last bit from a byte
	move.b	(a0)+,(a1,d1.w)	; we get a byte add bump the pointer again
	move.w	#1,d4		; the shift value
	move.b	#$80,d3		; the bit mask
	addq.w	#1,d1		
	andi.w	#4095,d1		
	addq.w	#1,d2		
	addq.l	#1,ring_hi
	move.l	ring_hi,d7
	subi.l	#4095,d7
	cmp.l	ring_lo,d7
	bmi	lzs_lp04
	move.l	d7,ring_lo
lzs_lp04
	cmp.l	d0,d2
	bmi	lzs0		; will fall out if equal
lzsexit	move.w	d1,buff_pointer
	move.b	d3,bit_mask
	move.w	d4,bit_pointer
	move.l	a0,lz_current
	move.l	d2,lz_pointer
	move.l	d0,lz_seek_value
	movem.l	(sp)+,d1-d7/a0-a1
	rts


* GEMS Driver - 2.5 5/21/92 (pz.s projector version 7)
* Copyright (c) 1991,1992 SEGA
* All Rights Reserved

* Z80Code		proc	export
* 
* ************************************* RESET VECTOR *******************************************
* 
* Z80CODEBASE
* 		di
	dc.b	$F3
* 		im      1
	dc.b	$ED,$56
* 		ld	SP,STACKINIT
	dc.b	$31,$20,$1B
* 		jp      main
	dc.b	$C3,$C3,$08
* 
* *********************************** 60 Hz Interrupt ******************************************
* 
* * but first, let's squeeze in a few variables...
* 
* psgcom		db	00H,00H,00H,00H		*  0 command 1 = key on, 2 = key off, 4 = stop snd
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* psglev		db	0ffH,0ffH,0ffH,0ffH	*  4 output level attenuation (4 bit)
	dc.b	$FF
	dc.b	$FF
	dc.b	$FF
	dc.b	$FF
* psgatk		db	00H,00H,00H,00H		*  8 attack rate
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* psgdec		db	00H,00H,00H,00H		* 12 decay rate
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* psgslv		db	00H,00H,00H,00H		* 16 sustain level attenuation
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* psgrrt		db	00H,00H,00H,00H		* 20 release rate
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* psgenv		db	00H,00H,00H,00H		* 24 envelope mode 0 = off, 1 = attack, 2 = decay, 3 = sustain, 4
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* psgdtl		db	00H,00H,00H,00H		* 28 tone bottom 4 bits, noise bits
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* psgdth		db      00H,00H,00H,00H		* 32 tone upper 6 bits
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* psgalv		db      00H,00H,00H,00H		* 36 attack level attenuation
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* whdflg		db      00H,00H,00H,00H		* 40 flags to indicate hardware should be updated
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* 
* 		db	0
	dc.b	$00
* 
* CMDWPTR		db	0			* cmd fifo wptr @ $36
	dc.b	$00
* CMDRPTR		db	0			* read pointer @ $37
	dc.b	$00
* 
* *** psg command processor/envelope emulator
* 
* COM		equ	0
* LEV		equ	4
* ATK		equ	8
* DKY		equ	12
* SLV		equ	16
* RRT		equ	20
* MODE		equ	24
* DTL		equ	28
* DTH		equ	32
* ALV		equ	36
* FLG		equ	40
* 
* VBLINT
* 		ld	(TICKFLG),SP		* msb of SP in TICKFLG+1 will be >0
	dc.b	$ED,$73,$3E,$00
* 		reti                    	* leave disabled - will be enabled by CHECKTICK
	dc.b	$ED,$4D
* 
* TICKFLG		dw	0			* (TICKFLG+1) set by ^^
	dc.b	$00
	dc.b	$00
* TICKCNT		db	0			* tick accumulated by CHECKTICK
	dc.b	$00
* 
* CHECKTICK					* (if TICKFLG+1 is set, then ints are disabled!)
* 		di
	dc.b	$F3
* 		push	AF
	dc.b	$F5
* 		push	HL
	dc.b	$E5
* 		ld	HL,TICKFLG+1
	dc.b	$21,$3F,$00
* 		ld	A,(HL)			* check TICKFLG+1
	dc.b	$7E
* 		zor	A
	dc.b	$B7
* 		jr	Z,ctnotick		* return if not set yet
	dc.b	$28,$17
* 
* 						* at this point, can't reenable ints until we're
* 						* sure VBL (64 uS) has gone away, so do some
* 						* DACMEs and a delay (in case DACME is off)
* 
* 		ld	(HL),0			* clear flag (ints are disabled!)
	dc.b	$36,$00
* 		inc	HL			* point to counter
	dc.b	$23
* 		inc	(HL)			* and inc it
	dc.b	$34
* 
* 		call	DACME
	dc.b	$CD,$B7,$02
* 
* 		push	DE
	dc.b	$D5
* 		ld	HL,(SBPTACC)		* add sub beats per tick to its accumulator
	dc.b	$2A,$C0,$08
* 		ld	DE,(SBPT)
	dc.b	$ED,$5B,$BE,$08
* 		zadd	HL,DE
	dc.b	$19
* 		ld	(SBPTACC),HL		* this is all 8 frac bits, so (SBPTACC+1)
	dc.b	$22,$C0,$08
* 		pop	DE				*   is the # of subbeats gone by
	dc.b	$D1
* 
* 		call	DACME
	dc.b	$CD,$B7,$02
* ctnotick
* 		pop	HL
	dc.b	$E1
* 		pop	AF
	dc.b	$F1
* 		ei
	dc.b	$FB
* 		ret
	dc.b	$C9
* 
* DOPSGENV
* 		ld      IY,psgcom		* load psg pseudo registers
	dc.b	$FD,$21,$09,$00
* 		ld      HL,7F11H		* load hardware register address
	dc.b	$21,$11,$7F
* 		ld      D,80H			* load command mask
	dc.b	$16,$80
* 		ld      E,4			* load loop counter
	dc.b	$1E,$04
* 
* vloop		call	DACME
	dc.b	$CD,$B7,$02
* 		ld	C,(IY+COM)		* load command bits
	dc.b	$FD,$4E,$00
* 		ld      (IY+COM),0		* clear command bits
	dc.b	$FD,$36,$00,$00
* 
* stop		bit     2,C             	* test bit 2
	dc.b	$CB,$51
* 		jr      Z,ckof          	* nope...
	dc.b	$28,$19
* 		ld      (IY+LEV),0FFH   	* reset output level
	dc.b	$FD,$36,$04,$FF
* 		ld      (IY+FLG),1      	* flag hardware update
	dc.b	$FD,$36,$28,$01
* 		ld      (IY+MODE),0     	* shut off envelope processing
	dc.b	$FD,$36,$18,$00
* 		ld	A,1
	dc.b	$3E,$01
* 		cp	E			* was this TG4 (noise)
	dc.b	$BB
* 		jr	NZ,ckof
	dc.b	$20,$08
* 		ld	IX,PSGVTBLTG3		* yes - clear locked bit in TG3
	dc.b	$DD,$21,$CA,$17
* 		res	5,(IX)
	dc.b	$DD,$CB,$00,$AE
* 
* ckof		bit     1,C             	* test bit 1
	dc.b	$CB,$49
* 		jr      Z,ckon          	* nope...
	dc.b	$28,$0F
* 		ld      A,(IY+MODE)     	* load envelope mode
	dc.b	$FD,$7E,$18
* 		cp      0               	* check for key on
	dc.b	$FE,$00
* 		jr      Z,ckon          	* nope...
	dc.b	$28,$08
* 		ld      (IY+FLG),1      	* flag hardware update
	dc.b	$FD,$36,$28,$01
* 		ld      (IY+MODE),4     	* switch to envelope release phase
	dc.b	$FD,$36,$18,$04
* 
* ckon		bit     0,C             	* test bit 0
	dc.b	$CB,$41
* 		jr      Z,envproc       	* nope...
	dc.b	$28,$1A
* 		ld      (IY+LEV),0FFH   	* reset level
	dc.b	$FD,$36,$04,$FF
* 		ld      A,(IY+DTL)      	* load tone lsb
	dc.b	$FD,$7E,$1C
* 		zor     D               	* mix with command stuff
	dc.b	$B2
* 		ld      (HL),A          	* write tone lsb or noise data
	dc.b	$77
* 		ld	A,1               	* check for last channel ***BAS***
	dc.b	$3E,$01
* 		cp      E               	* is it?
	dc.b	$BB
* 		jr      Z,nskip         	* skip msb set (noise channel)
	dc.b	$28,$04
* 		ld      A,(IY+DTH)      	* load tone msb
	dc.b	$FD,$7E,$20
* 		ld      (HL),A          	* write tone msb
	dc.b	$77
* nskip		ld      (IY+FLG),1      	* flag hardware update
	dc.b	$FD,$36,$28,$01
* 		ld      (IY+MODE),1     	* initiate envelope processing (attack phase)
	dc.b	$FD,$36,$18,$01
* 
* envproc		call	DACME
	dc.b	$CD,$B7,$02
* 		ld      A,(IY+MODE)     	* load envelope phase
	dc.b	$FD,$7E,$18
* 		cp      0               	* test for on/off
	dc.b	$FE,$00
* 		jp      Z,vedlp         	* off.
	dc.b	$CA,$5C,$01
* 		cp      1               	* attack mode?
	dc.b	$FE,$01
* 		jr      NZ,chk2         	* nope...
	dc.b	$20,$26
* 
* mode1		ld      (IY+FLG),1      	* flag hardware update
	dc.b	$FD,$36,$28,$01
* 		ld      A,(IY+LEV)      	* load level
	dc.b	$FD,$7E,$04
* 		ld      B,(IY+ALV)      	* load attack level
	dc.b	$FD,$46,$24
* 		zsub    (IY+ATK)        	* subtract attack rate
	dc.b	$FD,$96,$08
* 		jr      C,atkend        	* attack finished
	dc.b	$38,$0D
* 		jr      Z,atkend        	* attack finished
	dc.b	$28,$0B
* 		cp      B               	* test level
	dc.b	$B8
* 		jr      C,atkend        	* attack finished
	dc.b	$38,$08
* 		jr      Z,atkend        	* attack finished
	dc.b	$28,$06
* 		ld      (IY+LEV),A      	* save new level
	dc.b	$FD,$77,$04
* 		jp      vedlp           	* done
	dc.b	$C3,$5C,$01
* atkend		ld      (IY+LEV),B      	* save attack level as new level
	dc.b	$FD,$70,$04
* 		ld      (IY+MODE),2     	* switch to decay mode
	dc.b	$FD,$36,$18,$02
* 		jp      vedlp           	* done
	dc.b	$C3,$5C,$01
* 
* chk2		cp      2               	* decay mode?
	dc.b	$FE,$02
* 		jp      NZ,chk4         	* nope...
	dc.b	$C2,$32,$01
* 
* mode2		ld      (IY+FLG),1      	* flag hardware update
	dc.b	$FD,$36,$28,$01
* 		ld      A,(IY+LEV)      	* load level
	dc.b	$FD,$7E,$04
* 		ld      B,(IY+SLV)      	* load sustain level
	dc.b	$FD,$46,$10
* 		cp      B               	* compare levels
	dc.b	$B8
* 		jr      C,dkadd         	* add to decay
	dc.b	$38,$0C
* 		jr      Z,dkyend        	* decay finished
	dc.b	$28,$17
* 		zsub     (IY+DKY)        	* subtract decay rate
	dc.b	$FD,$96,$0C
* 		jr	C,dkyend		* if the sub caused a wrap then we're done
	dc.b	$38,$12
* 		cp      B               	* compare levels
	dc.b	$B8
* 		jr      C,dkyend        	* decay finished
	dc.b	$38,$0F
* 		jr      dksav          		* save decay
	dc.b	$18,$08
* dkadd		zadd     A,(IY+DKY)     	* add decay rate
	dc.b	$FD,$86,$0C
* 		jr	C,dkyend		* caused a wrap - we're done
	dc.b	$38,$08
* 		cp      B               	* compare levels
	dc.b	$B8
* 		jr      NC,dkyend       	* decay finished
	dc.b	$30,$05
* dksav		ld      (IY+LEV),A      	* save level
	dc.b	$FD,$77,$04
* 		jr      vedlp           	* done
	dc.b	$18,$33
* dkyend		ld      (IY+LEV),B      	* save sustain level
	dc.b	$FD,$70,$04
* 		ld      (IY+MODE),3     	* set sustain mode
	dc.b	$FD,$36,$18,$03
* 		jr      vedlp           	* done
	dc.b	$18,$2A
* 
* chk4		cp      4               	* check for sustain phase
	dc.b	$FE,$04
* 		jr      NZ,vedlp        	* nope
	dc.b	$20,$26
* mode4		ld      (IY+FLG),1      	* flag hardware update
	dc.b	$FD,$36,$28,$01
* 		ld      A,(IY+LEV)      	* load level
	dc.b	$FD,$7E,$04
* 		zadd    A,(IY+RRT)      	* add release rate
	dc.b	$FD,$86,$14
* 		jr      C,killenv       	* release finished
	dc.b	$38,$05
* 		ld      (IY+LEV),A      	* save new level
	dc.b	$FD,$77,$04
* 		jr      vedlp           	* done
	dc.b	$18,$15
* killenv		ld      (IY+LEV),0FFH   	* reset level
	dc.b	$FD,$36,$04,$FF
* 		ld      (IY+MODE),0     	* reset envelope mode
	dc.b	$FD,$36,$18,$00
* 		ld	A,1
	dc.b	$3E,$01
* 		cp	E			* was this TG4 we just killed?
	dc.b	$BB
* 		jr	NZ,vedlp
	dc.b	$20,$08
* 		ld	IX,PSGVTBLTG3		* yes - clear locked bit in TG3
	dc.b	$DD,$21,$CA,$17
* 		res	5,(IX)
	dc.b	$DD,$CB,$00,$AE
* 
* vedlp		inc     IY              	* point to next channel registers
	dc.b	$FD,$23
* 		ld      A,20H           	* for tone command byte fixup
	dc.b	$3E,$20
* 		zadd     A,D             	* add tone command byte
	dc.b	$82
* 		ld      D,A             	* move back into D
	dc.b	$57
* 		dec     E              		* decrement counter
	dc.b	$1D
* 		jp      NZ,vloop        	* until done ***BAS***
	dc.b	$C2,$71,$00
* 
* 		call	DACME
	dc.b	$CD,$B7,$02
* 
* 		ld      IY,psgcom       	* reset psg envelope pointer
	dc.b	$FD,$21,$09,$00
* 
* uch1		bit     0,(IY+FLG)      	* test update flag
	dc.b	$FD,$CB,$28,$46
* 		jr      Z,uch2          	* next channel
	dc.b	$28,$12
* 		ld      (IY+FLG),0      	* clear update flag
	dc.b	$FD,$36,$28,$00
* 		ld      A,(IY+LEV)      	* load level
	dc.b	$FD,$7E,$04
* 		srl     A
	dc.b	$CB,$3F
* 		srl     A
	dc.b	$CB,$3F
* 		srl     A
	dc.b	$CB,$3F
* 		srl     A
	dc.b	$CB,$3F
* 		zor      90H            	* set command bits
	dc.b	$F6,$90
* 		ld      (HL),A          	* write new level
	dc.b	$77
* 
* uch2		bit     0,(IY+FLG+1)    	* test update flag
	dc.b	$FD,$CB,$29,$46
* 		jr      Z,uch3          	* next channel
	dc.b	$28,$12
* 		ld      (IY+FLG+1),0    	* clear update flag
	dc.b	$FD,$36,$29,$00
* 		ld      A,(IY+LEV+1)    	* load level
	dc.b	$FD,$7E,$05
* 		srl     A
	dc.b	$CB,$3F
* 		srl     A
	dc.b	$CB,$3F
* 		srl     A
	dc.b	$CB,$3F
* 		srl     A
	dc.b	$CB,$3F
* 		zor      0B0H            	* set command bits
	dc.b	$F6,$B0
* 		ld      (HL),A          	* write new level
	dc.b	$77
* 
* uch3		bit     0,(IY+FLG+2)    	* test update flag
	dc.b	$FD,$CB,$2A,$46
* 		jr      Z,uch4          	* next channel
	dc.b	$28,$12
* 		ld      (IY+FLG+2),0    	* clear update flag
	dc.b	$FD,$36,$2A,$00
* 		ld      A,(IY+LEV+2)    	* load level
	dc.b	$FD,$7E,$06
* 		srl     A
	dc.b	$CB,$3F
* 		srl     A
	dc.b	$CB,$3F
* 		srl     A
	dc.b	$CB,$3F
* 		srl     A
	dc.b	$CB,$3F
* 		zor	0D0H			* set command bits
	dc.b	$F6,$D0
* 		ld      (HL),A          	* write new level
	dc.b	$77
* 
* uch4		bit     0,(IY+FLG+3)    	* test update flag
	dc.b	$FD,$CB,$2B,$46
* 		jr      Z,vquit         	* next channel
	dc.b	$28,$12
* 		ld      (IY+FLG+3),0    	* clear update flag
	dc.b	$FD,$36,$2B,$00
* 		ld      A,(IY+LEV+3)    	* load level
	dc.b	$FD,$7E,$07
* 		srl     A
	dc.b	$CB,$3F
* 		srl     A
	dc.b	$CB,$3F
* 		srl     A
	dc.b	$CB,$3F
* 		srl     A
	dc.b	$CB,$3F
* 		zor      0F0H			* set command bits
	dc.b	$F6,$F0
* 		ld      (HL),A          	* write new level
	dc.b	$77
* 
* vquit		call	DACME
	dc.b	$CD,$B7,$02
* 		ret
	dc.b	$C9
* 
* 
* ****************************** Command FIFO (from 68000) *************************************
* 
* *
* *  GETCBYTE - returns the next command byte in the fifo from the 68k. will wait
* *    for one if the queue is empty when called.
* *
* *	parameters:	NONE
* *	returns:	A	byte from queue
* *
* 
* GETCBYTE	push	BC
	dc.b	$C5
* 		push	HL
	dc.b	$E5
* 
* getcbytel	call	DACME
	dc.b	$CD,$B7,$02
* 		call	FILLDACFIFO
	dc.b	$CD,$02,$03
* 
* 		ld	A,(CMDWPTR)
	dc.b	$3A,$36,$00
* 		ld	B,A
	dc.b	$47
* 		ld	A,(cmdrptr)		* compare read and write pointers
	dc.b	$3A,$37,$00
* 		cp	B
	dc.b	$B8
* 		jr	Z,getcbytel		* loop if equal
	dc.b	$28,$F0
* 
* 		ld	B,0
	dc.b	$06,$00
* 		ld	C,a			* BC gets 16 bit read ptr
	dc.b	$4F
* 		ld	HL,cmdfifo		* IX points at fifo
	dc.b	$21,$40,$1B
* 
* 		call	DACME
	dc.b	$CD,$B7,$02
* 
* 		zadd	HL,BC			* add 'em
	dc.b	$09
* 		inc	A			* increment read ptr
	dc.b	$3C
* 		zand	3FH			*  (mod 64)
	dc.b	$E6,$3F
* 		ld	(cmdrptr),A
	dc.b	$32,$37,$00
* 		ld	A,(HL)			* read actual entry
	dc.b	$7E
* 		pop	HL
	dc.b	$E1
* 		pop	BC
	dc.b	$C1
* 		ret
	dc.b	$C9
* 
* **************************************  XFER68K  *****************************************
* 
* *
* *  XFER68K - transfers 1 to 255 bytes from 68000 space to Z80. handles 32k block crossings.
* *
* *	parameters:		A	68k source address [23:16]
* *				HL	68k source address [15:0]
* *				DE	Z80 dest address
* *				C	byte count (0 is illegal!)
* *
* *	trashes:		B
* *
* 
* x68ksrclsb	db	0			* for storing lsw of src addr
	dc.b	$00
* x68ksrcmid	db	0
	dc.b	$00
* 
* XFER68K
* 
* 	call	DACME
	dc.b	$CD,$B7,$02
* 
* 		push	IX			* save IX - use it to point to DMA block flags
	dc.b	$DD,$E5
* 		ld	IX,MBOXES
	dc.b	$DD,$21,$20,$1B
* 
* 		ld	(x68ksrclsb),HL		* save src addr[15:0]
	dc.b	$22,$F7,$01
* 		res	7,H			* HL <- src addr[14:0]
	dc.b	$CB,$BC
* 		ld	B,0
	dc.b	$06,$00
* 		dec	C			* BC <- count-1
	dc.b	$0D
* 		zadd	HL,BC			* HL addr within 32k byte bank of last byte to xfer
	dc.b	$09
* 		bit	7,H			* is it in the next bank?
	dc.b	$CB,$7C
* 		jr	NZ,x68kcrosses
	dc.b	$20,$0B
* 
* 		ld	HL,(x68ksrclsb)		* single bank - easy: get back src addr[15:0]
	dc.b	$2A,$F7,$01
* 		inc	C			* C <- byte count
	dc.b	$0C
* 		ld	B,A			* B <- src addr msb
	dc.b	$47
* 
* 		call	xfer68ksafe
	dc.b	$CD,$3D,$02
* 
* 		pop	IX
	dc.b	$DD,$E1
* 		ret
	dc.b	$C9
* 
* x68kcrosses					* C = count-1, L=over-1
* 		ld	B,A			* B <- src addr msb
	dc.b	$47
* 		push	BC			* push src addr msb (B)
	dc.b	$C5
* 		push	HL			* push over-1 (L)
	dc.b	$E5
* 		ld	A,C
	dc.b	$79
* 		zsub	L
	dc.b	$95
* 		ld	C,A			* C <- C - L = count - over (byte count for 1st part)
	dc.b	$4F
* 		ld	HL,(x68ksrclsb)		* HL <- src addr[15:0]
	dc.b	$2A,$F7,$01
* 
* 		call	xfer68ksafe		* xfer away
	dc.b	$CD,$3D,$02
* 
* 		pop	HL			* L <- over-1
	dc.b	$E1
* 		pop	BC			* B <- src addr msb
	dc.b	$C1
* 		ld	C,L
	dc.b	$4D
* 		inc	C			* C <- over count
	dc.b	$0C
* 		ld	A,(x68ksrcmid)
	dc.b	$3A,$F8,$01
* 		zand	80H
	dc.b	$E6,$80
* 		zadd	A,80H
	dc.b	$C6,$80
* 		ld	H,A
	dc.b	$67
* 		ld	L,0			* HL <- lsw of start of next bank
	dc.b	$2E,$00
* 		jr	NC,x68knocarry
	dc.b	$30,$01
* 		inc	B			* inc msb if lsw carried
	dc.b	$04
* x68knocarry
* 		call	xfer68ksafe		* xfer away
	dc.b	$CD,$3D,$02
* 
* 		pop	IX
	dc.b	$DD,$E1
* 		ret
	dc.b	$C9
* 
* * xfer68kinner - inner loop of XFER68K
* *
* *	parameters:		B	68k source address [23:16]
* *				HL	68k source address [15:0]
* *				DE	Z80 dest address
* *				C	byte count (0 is illegal, as is any count which would
* *					  result in a 32k block crossing in 68k space
* *	trashes:		A
* 
* xfer68ksafe
* xfer68kinner
* 
* 	call	DACME
	dc.b	$CD,$B7,$02
* 
* 		push	DE
	dc.b	$D5
* 		ld	DE,6000H		* point to bank select register
	dc.b	$11,$00,$60
* 		ld	A,H
	dc.b	$7C
* 		rlc	A			* send addr[15]
	dc.b	$CB,$07
* 		ld	(DE),A
	dc.b	$12
* 		ld	A,B
	dc.b	$78
* 		ld	(DE),A			* send addr[16] to addr[23]
	dc.b	$12
* 		rra
	dc.b	$1F
* 		ld	(DE),A
	dc.b	$12
* 		rra
	dc.b	$1F
* 		ld	(DE),A
	dc.b	$12
* 		rra
	dc.b	$1F
* 		ld	(DE),A
	dc.b	$12
* 		rra
	dc.b	$1F
* 		ld	(DE),A
	dc.b	$12
* 		rra
	dc.b	$1F
* 		ld	(DE),A
	dc.b	$12
* 		rra
	dc.b	$1F
* 		ld	(DE),A
	dc.b	$12
* 		rra
	dc.b	$1F
* 		ld	(DE),A			* 32k byte bank is now selected
	dc.b	$12
* 
* 		pop	DE			* DE <- dest addr
	dc.b	$D1
* 		zset	7,H			* HL <- source addr, in 32k byte bank window
	dc.b	$CB,$FC
* 		ld	A,C			* A <- byte count
	dc.b	$79
* 		ld	B,0			* clear msb of BC
	dc.b	$06,$00
* 
* 	call	DACME
	dc.b	$CD,$B7,$02
* 
* 		zset	0,(IX+1)		* MBOX[1] tells 68k that Z80 might be xfering
	dc.b	$DD,$CB,$01,$C6
* 
* 		zsub	7			* count > maxcnt ?
	dc.b	$D6,$07
* *		zsub	13			* count > maxcnt ?
* 		jr	C,x68klast
	dc.b	$38,$11
* x68kloop
* 		ld	C,6			* yes - xfer maxcnt bytes
	dc.b	$0E,$06
* *		ld	C,12			* yes - xfer maxcnt bytes
* 		bit	0,(IX)			* MBOX[0] is block flag from 68k
	dc.b	$DD,$CB,$00,$46
* 		jr	NZ,x68klpwt
	dc.b	$20,$1C
* x68klpcont
* 		ldir
	dc.b	$ED,$B0
* 
* 	call	DACME
	dc.b	$CD,$B7,$02
* 
* 		zsub	6			* more than maxcnt left?
	dc.b	$D6,$06
* *		zsub	12			* more than maxcnt left?
* 		jr	NC,x68kloop		* yes - loop back
	dc.b	$30,$EF
* x68klast
* 		zadd	A,7			* last maxcnt or less - xfer them
	dc.b	$C6,$07
* *		zadd	A,13			* last maxcnt or less - xfer them
* 		ld	C,A
	dc.b	$4F
* 		bit	0,(IX)			* MBOX[0] is block flag from 68k
	dc.b	$DD,$CB,$00,$46
* 		jr	NZ,x68klstwt
	dc.b	$20,$1D
* x68klstcont
* 		ldir
	dc.b	$ED,$B0
* 
* 	call	DACME
	dc.b	$CD,$B7,$02
* 
* 		res	0,(IX+1)
	dc.b	$DD,$CB,$01,$86
* 
* 		ret
	dc.b	$C9
* 
* x68klpwt
* 		res	0,(IX+1)		* clear unsafe flag until unblocked
	dc.b	$DD,$CB,$01,$86
* x68klpwtlp
* 		call	DACME			* wait for block flag to clear, sending samples
	dc.b	$CD,$B7,$02
* 		bit	0,(IX)
	dc.b	$DD,$CB,$00,$46
* 		jr	NZ,x68klpwtlp
	dc.b	$20,$F7
* 		zset	0,(IX+1)
	dc.b	$DD,$CB,$01,$C6
* 		jr	x68klpcont
	dc.b	$18,$D1
* 
* x68klstwt
* 		res	0,(IX+1)
	dc.b	$DD,$CB,$01,$86
* x68klstwtlp
* 		call	DACME			* wait for block flag to clear, sending samples
	dc.b	$CD,$B7,$02
* 		bit	0,(IX)
	dc.b	$DD,$CB,$00,$46
* 		jr	NZ,x68klstwtlp
	dc.b	$20,$F7
* 		zset	0,(IX+1)
	dc.b	$DD,$CB,$01,$C6
* 		jr	x68klstcont
	dc.b	$18,$D0
* 
* **************************************  DIGITAL STUFF  *************************************
* 
* *
* *  DACME - do that DAC thing. assumes the the alternate registers are set up as follows
* *
* *			B	15H (reset cmd to timer) + CH3 mode bits
* *			C	control pattern for processing (compression, oversampling)
* *			DE	pointing into DACFIFO (1F00-1FFF)
* *			HL	4000H
* *
* 
* DACMEJRINST	dw	0			* for saving the DACME inst for slow sample rates
	dc.b	$00
	dc.b	$00
* DACME4BINST	dw	0			* for saving the DACMEPROC inst for processing
	dc.b	$00
	dc.b	$00
* 
* DACME		jr	DACMEALT		* change to EXX/EX AF to enable, RET to disable
	dc.b	$18,$26
* 
* *		ret				* change to EXX (0D9H) to enable this routine
* *		ex	AF,AF			* switch register set
* 
* 		ld	(HL),27H		* point FM chip at timer control register
	dc.b	$36,$27
* dacmespin
* 		bit	0,(HL)			* spin till Timer A overflows
	dc.b	$CB,$46
* 		jp	Z,dacmespin
	dc.b	$CA,$BB,$02
* 
* 		inc	L			* point HL to FM data register
	dc.b	$2C
* 		ld	(HL),B			* reset timer (sets CH3 mode bits)
	dc.b	$70
* 		dec	L
	dc.b	$2D
* 		ld	A,(DE)			* get next byte from fifo
	dc.b	$1A
* 
* DACMEPROC
* 		jr	DACMEDSP		* change to 2 nops for normal (non processed samples)
	dc.b	$18,$26
* *		znop
* *		znop
* 
* 		znop
	dc.b	$00
* 		inc	E
	dc.b	$1C
* 
* DACMEOUT	ld	(HL),02AH		* point FM chip at DAC data register
	dc.b	$36,$2A
* 		inc	HL
	dc.b	$23
* 		ld	(HL),A			* output sample
	dc.b	$77
* 		dec	L
	dc.b	$2D
* 		ex	AF,AF
	dc.b	$08
* 		exx
	dc.b	$D9
* DACMERET	ret				* change to ZNOP for DACME's every other call
	dc.b	$C9
* 						* for (slow sample rates)
* 
* 		ex	AF,AF			* changes DACME to jump to DACMEALT next time
	dc.b	$08
* 		ld	A,(DACMEJRINST)
	dc.b	$3A,$B3,$02
* 		ld	(DACME),A
	dc.b	$32,$B7,$02
* 		ld	A,(DACMEJRINST+1)
	dc.b	$3A,$B4,$02
* 		ld	(DACME+1),A
	dc.b	$32,$B8,$02
* 		ex	AF,AF
	dc.b	$08
* 		ret
	dc.b	$C9
* 
* DACMEALT
* 		ex	AF,AF			* changes DACME back to working next time
	dc.b	$08
* 		ld	A,0D9H			* D9 = exx
	dc.b	$3E,$D9
* 		ld	(DACME),A
	dc.b	$32,$B7,$02
* 		ld	A,008H			* 08 = ex af,af
	dc.b	$3E,$08
* 		ld	(DACME+1),A
	dc.b	$32,$B8,$02
* 		ex	AF,AF
	dc.b	$08
* 		ret
	dc.b	$C9
* 
* DACMEDSP
* 		rrc	C			* which sample (high nibble or low)
	dc.b	$CB,$09
* 		jr	C,DACME4BHI		* high
	dc.b	$38,$08
* 
* 		rla				* here for low nibble - 1st half
	dc.b	$17
* 		rla
	dc.b	$17
* 		rla
	dc.b	$17
* 		rla
	dc.b	$17
* DACME4BMSK
* 		zand	0F0H
	dc.b	$E6,$F0
* 		jr	DACMEOUT
	dc.b	$18,$D0
* DACME4BHI					* here for hi nib - 2nd half - inc ptr
* 		inc	E
	dc.b	$1C
* 		jr	DACME4BMSK
	dc.b	$18,$F9
* 
* 
* *
* *  FILLDACFIFO - gets the next 128 bytes of sample from the 68000 into the DACFIFO
* *
* 
* DACFIFOWPTR	db	0
	dc.b	$00
* 
* SAMPLEPTR	db	0,0,0
	dc.b	$00
	dc.b	$00
	dc.b	$00
* SAMPLECTR	dw	0
	dc.b	$00
	dc.b	$00
* FDFSTATE	db	0
	dc.b	$00
* 
* FILLDACFIFO
* 		ret				* replace with 0 (nop) to enable DAC fills
	dc.b	$C9
* 		push	AF
	dc.b	$F5
* 		ld	A,(DACFIFOWPTR)		* is DAC reading from bank to be filled ?
	dc.b	$3A,$FB,$02
* 		exx
	dc.b	$D9
* 		zxor	E
	dc.b	$AB
* 		exx
	dc.b	$D9
* 		zand	80H
	dc.b	$E6,$80
* 		jr	NZ,FDFneeded
	dc.b	$20,$06
* 
* 		pop	AF
	dc.b	$F1
* 		ret				* yes - return
	dc.b	$C9
* 
* FORCEFILLDF
* 
* 		call	CHECKTICK
	dc.b	$CD,$41,$00
* 
* 		push	AF
	dc.b	$F5
* 
* FDFneeded
* 		call	DACME
	dc.b	$CD,$B7,$02
* 
* 		push	BC
	dc.b	$C5
* 		push	DE
	dc.b	$D5
* 		push	HL
	dc.b	$E5
* 
* 		ld	A,(FDFSTATE)		* sample refill FSM state
	dc.b	$3A,$01,$03
* 		cp	7
	dc.b	$FE,$07
* 		jp	NC,FDF7
	dc.b	$D2,$CC,$03
* 
* FDF4N5N6					* states 4, 5, and 6
* 		ld	HL,(SAMPLECTR)
	dc.b	$2A,$FF,$02
* 		ld	BC,128
	dc.b	$01,$80,$00
* 		scf
	dc.b	$37
* 		ccf
	dc.b	$3F
* 		sbc	HL,BC			* HL <- samplectr - 128
	dc.b	$ED,$42
* 
* 		jr	C,FDF4DONE
	dc.b	$38,$2E
* 		jr	Z,FDF4DONE
	dc.b	$28,$2C
* FDF4NORM
* 		ld	(SAMPLECTR),HL
	dc.b	$22,$FF,$02
* 
* 		ld	D,1FH			* xfer next 128 samples from (SAMPLEPTR)
	dc.b	$16,$1F
* 		ld	A,(DACFIFOWPTR)
	dc.b	$3A,$FB,$02
* 		ld	E,A			* DE <- dest addr
	dc.b	$5F
* 		zadd	A,128			* increment dest addr for next time
	dc.b	$C6,$80
* 		ld	(DACFIFOWPTR),A
	dc.b	$32,$FB,$02
* 		ld	HL,(SAMPLEPTR)		* HL <- src addr lsw
	dc.b	$2A,$FC,$02
* 		ld	A,(SAMPLEPTR+2)		* A <- src addr msb
	dc.b	$3A,$FE,$02
* 		call	XFER68K			* reload FIFO
	dc.b	$CD,$F9,$01
* 
* 		ld	HL,(SAMPLEPTR)
	dc.b	$2A,$FC,$02
* 		ld	A,(SAMPLEPTR+2)
	dc.b	$3A,$FE,$02
* 		ld	BC,128
	dc.b	$01,$80,$00
* 		zadd	HL,BC
	dc.b	$09
* 		adc	A,0
	dc.b	$CE,$00
* 		ld	(SAMPLEPTR),HL
	dc.b	$22,$FC,$02
* 		ld	(SAMPLEPTR+2),A		* SAMPLEPTR <- SAMPLEPTR + 128
	dc.b	$32,$FE,$02
* 		jp	FDFreturn
	dc.b	$C3,$EA,$03
* FDF4DONE					* for now, loop back
* 		ld	A,L
	dc.b	$7D
* 		zadd	A,128
	dc.b	$C6,$80
* 		ld	C,A			* xfer the samples that are left
	dc.b	$4F
* 		ld	B,0
	dc.b	$06,$00
* 		push	BC			* save # xfered here
	dc.b	$C5
* 		ld	D,1FH
	dc.b	$16,$1F
* 		ld	A,(DACFIFOWPTR)
	dc.b	$3A,$FB,$02
* 		ld	E,A			* DE <- dest addr
	dc.b	$5F
* 		zadd	A,128			* increment dest addr for next time
	dc.b	$C6,$80
* 		ld	(DACFIFOWPTR),A
	dc.b	$32,$FB,$02
* 		ld	HL,(SAMPLEPTR)		* HL <- src addr lsw
	dc.b	$2A,$FC,$02
* 		ld	A,(SAMPLEPTR+2)		* A <- src addr msb
	dc.b	$3A,$FE,$02
* 		call	XFER68K			* reload FIFO - leaves DE at next to write
	dc.b	$CD,$F9,$01
* 		pop	BC			* C <- # just xfered
	dc.b	$C1
* 
* 		* needs to xfer the next few if needed, for now, just loop back
* 
* 		ld	A,(FDFSTATE)
	dc.b	$3A,$01,$03
* 		cp	5
	dc.b	$FE,$05
* 		jp	NZ,FDF7
	dc.b	$C2,$CC,$03
* 
* 		ld	HL,(SAMPLEPTR)
	dc.b	$2A,$FC,$02
* 		ld	A,(SAMPLEPTR+2)
	dc.b	$3A,$FE,$02
* 		push	BC
	dc.b	$C5
* 		zadd	HL,BC
	dc.b	$09
* 		adc	A,0			* add to sample pointer
	dc.b	$CE,$00
* 		ld	BC,(SAMPLOOP)
	dc.b	$ED,$4B,$29,$14
* 		scf
	dc.b	$37
* 		ccf
	dc.b	$3F
* 		sbc	HL,BC
	dc.b	$ED,$42
* 		sbc	A,0			* then subtract loop length
	dc.b	$DE,$00
* 		ld	(SAMPLEPTR),HL		* store new (beginning of loop ptr)
	dc.b	$22,$FC,$02
* 		ld	(SAMPLEPTR+2),A
	dc.b	$32,$FE,$02
* 		ld	(SAMPLECTR),BC
	dc.b	$ED,$43,$FF,$02
* 
* 		pop	BC
	dc.b	$C1
* 		ld	A,128
	dc.b	$3E,$80
* 		zsub	C
	dc.b	$91
* 		ld	C,A			* BC <- numer to complete this 128byte bank
	dc.b	$4F
* 		jp	Z,FDFreturn		* none to xfer
	dc.b	$CA,$EA,$03
* 
* 		ld	HL,(SAMPLECTR)
	dc.b	$2A,$FF,$02
* 		scf
	dc.b	$37
* 		ccf
	dc.b	$3F
* 		sbc	HL,BC			* subtract these few samples from ctr
	dc.b	$ED,$42
* 		ld	(SAMPLECTR),HL
	dc.b	$22,$FF,$02
* 						* DE still hangin out where it left off
* 		ld	HL,(SAMPLEPTR)		* HL <- src addr lsw
	dc.b	$2A,$FC,$02
* 		ld	A,(SAMPLEPTR+2)		* A <- src addr msb
	dc.b	$3A,$FE,$02
* 		push	BC
	dc.b	$C5
* 		call	XFER68K			* reload FIFO
	dc.b	$CD,$F9,$01
* 		pop	BC
	dc.b	$C1
* 
* 		ld	HL,(SAMPLEPTR)
	dc.b	$2A,$FC,$02
* 		ld	A,(SAMPLEPTR+2)
	dc.b	$3A,$FE,$02
* 		zadd	HL,BC
	dc.b	$09
* 		adc	A,0
	dc.b	$CE,$00
* 		ld	(SAMPLEPTR),HL
	dc.b	$22,$FC,$02
* 		ld	(SAMPLEPTR+2),A		* SAMPLEPTR <- SAMPLEPTR + 128
	dc.b	$32,$FE,$02
* 
* 		jr	FDFreturn
	dc.b	$18,$1E
* 
* FDF7						* state 7 - just off for now
* 
* 		ld	A,0C9H			* opcode "ret"
	dc.b	$3E,$C9
* 		ld	(DACME),A		* disable DACME routine
	dc.b	$32,$B7,$02
* 		ld	(FILLDACFIFO),A		* disable FILLDACFIFO
	dc.b	$32,$02,$03
* 		ld	HL,4000H		* disable DAC mode
	dc.b	$21,$00,$40
* 		ld	(HL),02BH
	dc.b	$36,$2B
* 		inc	HL
	dc.b	$23
* 		ld	(HL),0
	dc.b	$36,$00
* 		ld	HL,FMVTBLCH6
	dc.b	$21,$AD,$17
* 		ld	(HL),0C6H		* mark voice free, unlocked, and releasing
	dc.b	$36,$C6
* 		inc	HL
	dc.b	$23
* 		inc	HL
	dc.b	$23
* 		inc	HL
	dc.b	$23
* 		inc	HL
	dc.b	$23
* 		ld	(HL),0			* clear any pending release timer value
	dc.b	$36,$00
* 		inc	HL
	dc.b	$23
* 		ld	(HL),0
	dc.b	$36,$00
* 
* FDFreturn
* 		pop	HL
	dc.b	$E1
* 		pop	DE
	dc.b	$D1
* 		pop	BC
	dc.b	$C1
* 		pop	AF
	dc.b	$F1
* 
* 		ret
	dc.b	$C9
* 
* 
* 
* ************************************* SEQUENCER CODE ***************************************
* 
* * CCB Entries:	2,1,0	tag addr of 1st byte in 32-byte channel buffer
* *		5,4,3	addr of next byte to fetch
* *				so: 0 <= addr-tag <= 31 means hit in buffer
* *		6	flags
* *		8,7	timer (contains 0-ticks to delay)
* *		10,9	delay
* *		12,11	duration
* 
* CCBTAGL		equ	0	* lsb of addr of 1st byte in 32-byte sequence buffer
* CCBTAGM		equ	1	* mid of "
* CCBTAGH		equ	2	* msb of "
* CCBADDRL	equ	3	* lsb of addr of next byte to read from sequence
* CCBADDRM	equ	4	* mid of "
* CCBADDRH	equ	5	* msb of "
* CCBFLAGS	equ	6	* 80 = sustain
* 				* 40 = env retrigger
* 				* 20 = lock (for 68k based sfx)
* 				* 10 = running (not paused)
* 				* 08 = use sfx (150 bpm) timebase
* 				* 02 = muted (running, but not executing note ons)
* 				* 01 = in use
* CCBTIMERL	equ	7	* lsb of 2's comp, subbeat (1/24th) timer till next event
* CCBTIMERH	equ	8	* msb of "
* CCBDELL		equ	9	* lsb of registered subbeat delay value
* CCBDELH		equ	10	* msb of "
* CCBDURL		equ	11	* lsb of registered subbeat duration value
* CCBDURH		equ	12	* msb of "
* CCBPNUM		equ	13	* program number (patch)
* CCBSNUM		equ	14	* sequence number (in sequence bank)
* CCBVCHAN	equ	15	* MIDI channel number within sequence CCBSNUM
* CCBLOOP0	equ	16	* loop stack (counter, lsb of start addr, mid of start addr)
* CCBLOOP1	equ	19
* CCBLOOP2	equ	22
* CCBLOOP3	equ	25
* CCBPRIO		equ	28	* priority (0 lowest, 127 highest)
* CCBENV		equ	29	* envelope number
* CCBATN		equ	30	* channel attenuation (0=loud, 127=quiet)
* CCBy		equ	31
* 
* *
* *  GETSBYTE - get the channel's sequence byte pointed to by the CCB
* *
* *	parameters:		IX		points to the current channel's CCB
* *				(CHBUFPTR)	points to the current channel's buffer
* *	returns:		A		data
* *
* 
* *BUFSIZE		equ	16
* 
* GETSBYTE
* 
* 	call	DACME
	dc.b	$CD,$B7,$02
* 
* 		push	BC
	dc.b	$C5
* 		push	HL
	dc.b	$E5
* 
* 		ld	A,(IX+CCBADDRL)
	dc.b	$DD,$7E,$03
* 		zsub	(IX+CCBTAGL)
	dc.b	$DD,$96,$00
* 		ld	C,A			* C <- lsb of addr-tag
	dc.b	$4F
* 		ld	A,(IX+CCBADDRM)
	dc.b	$DD,$7E,$04
* 		sbc	A,(IX+CCBTAGM)		* A <- midbyte of addr-tag
	dc.b	$DD,$9E,$01
* 		jr	NZ,gsbmiss		* if non-zero, its a miss!
	dc.b	$20,$2A
* 		ld	A,(IX+CCBADDRH)
	dc.b	$DD,$7E,$05
* 		sbc	A,(IX+CCBTAGH)		* A <- high byte of addr-tag
	dc.b	$DD,$9E,$02
* 		jr	NZ,gsbmiss		* if non-zero, its a miss!
	dc.b	$20,$22
* 		ld	A,C
	dc.b	$79
* 		cp	16			* if mid and msb ok, is lsb < 16 ?
	dc.b	$FE,$10
* 		jr	NC,gsbmiss		* no - its a miss
	dc.b	$30,$1D
* gsbhit
* 	call	DACME
	dc.b	$CD,$B7,$02
* 
* 		ld	B,0			* hit!
	dc.b	$06,$00
* 		ld	HL,(CHBUFPTR)
	dc.b	$2A,$54,$04
* 		zadd	HL,BC			* HL <- ptr to byte in buffer
	dc.b	$09
* 		ld	A,(HL)			* A <- byte from buffer
	dc.b	$7E
* 
* 		inc	(IX+CCBADDRL)		* increment addr[23:0]
	dc.b	$DD,$34,$03
* 		jr	NZ,gsbincdone
	dc.b	$20,$08
* 		inc	(IX+CCBADDRM)
	dc.b	$DD,$34,$04
* 		jr	NZ,gsbincdone
	dc.b	$20,$03
* 		inc	(IX+CCBADDRH)
	dc.b	$DD,$34,$05
* gsbincdone
* 		pop	HL
	dc.b	$E1
* 		pop	BC
	dc.b	$C1
* 
* 	call	DACME
	dc.b	$CD,$B7,$02
* 
* 		ret
	dc.b	$C9
* gsbmiss
* 
* 	call	DACME
	dc.b	$CD,$B7,$02
* *	call	FILLDACFIFO
* 	call	CHECKTICK
	dc.b	$CD,$41,$00
* *	call	DACME
* 
* 		push	DE			* here to refill buffer w/ next 32 bytes in seq
	dc.b	$D5
* 		ld	DE,(CHBUFPTR)		* DE <- pointer to buffer
	dc.b	$ED,$5B,$54,$04
* 		ld	L,(IX+CCBADDRL)
	dc.b	$DD,$6E,$03
* 		ld	(IX+CCBTAGL),L
	dc.b	$DD,$75,$00
* 		ld	H,(IX+CCBADDRM)		* HL <- src addr lsw
	dc.b	$DD,$66,$04
* 		ld	(IX+CCBTAGM),H
	dc.b	$DD,$74,$01
* 		ld	A,(IX+CCBADDRH)		* A <- src addr msg
	dc.b	$DD,$7E,$05
* 		ld	(IX+CCBTAGH),A		* tag <- addr
	dc.b	$DD,$77,$02
* 		ld	C,16		* C <- byte count
	dc.b	$0E,$10
* 		call	XFER68K			* refill away
	dc.b	$CD,$F9,$01
* 		pop	DE
	dc.b	$D1
* 		ld	C,0
	dc.b	$0E,$00
* 		jr	gsbhit			* and hit on first byte (since we just refilled here)
	dc.b	$18,$BC
* 
* 
* *
* *  UPDSEQ - go through the CCB's, updating any enabled channels
* *
* 
* CHBUFPTR	dw	0			* pointer to current channel's sequence buffer
	dc.b	$00
	dc.b	$00
* CHPATPTR	dw	0			* pointer to current channel's patch buffer
	dc.b	$00
	dc.b	$00
* 
* UPDSEQ		ld	IX,CCB
	dc.b	$DD,$21,$80,$1B
* 		ld	HL,CH0BUF		* initialize seq buf ptr
	dc.b	$21,$80,$1D
* 		ld	(CHBUFPTR),HL
	dc.b	$22,$54,$04
* 		ld	HL,PATCHDATA
	dc.b	$21,$86,$18
* 		ld	(CHPATPTR),HL
	dc.b	$22,$56,$04
* 		ld	A,(TBASEFLAGS)
	dc.b	$3A,$C2,$08
* 		ld	C,A
	dc.b	$4F
* 		ld	A,16			* loop counter
	dc.b	$3E,$10
* 		ld	B,0			* make it channel 0
	dc.b	$06,$00
* 		jr	updseqloop1
	dc.b	$18,$1A
* updseqloop
* 	call	DACME
	dc.b	$CD,$B7,$02
* 		ld	DE,32			* go to next CCB
	dc.b	$11,$20,$00
* 		zadd	IX,DE
	dc.b	$DD,$19
* 		ld	HL,(CHBUFPTR)
	dc.b	$2A,$54,$04
* 		ld	E,16
	dc.b	$1E,$10
* 		zadd	HL,DE
	dc.b	$19
* 		ld	(CHBUFPTR),HL
	dc.b	$22,$54,$04
* 		ld	HL,(CHPATPTR)
	dc.b	$2A,$56,$04
* 		ld	E,39
	dc.b	$1E,$27
* 		zadd	HL,DE
	dc.b	$19
* 		ld	(CHPATPTR),HL
	dc.b	$22,$56,$04
* updseqloop1
* 		bit	4,(IX+CCBFLAGS)		* is channel running (vs. paused or free)
	dc.b	$DD,$CB,$06,$66
* 		jr	Z,updseqloop2
	dc.b	$28,$1D
* 		bit	3,(IX+CCBFLAGS)		* is it sfx tempo based?
	dc.b	$DD,$CB,$06,$5E
* 		jr	NZ,updseqsfx
	dc.b	$20,$06
* 		bit	1,C			* music tempo based - beat gone by?
	dc.b	$CB,$49
* 		jr	NZ,updseqdoit		* yes - sequence it
	dc.b	$20,$06
* 		jr	updseqloop2		* no - skip it
	dc.b	$18,$11
* updseqsfx
* 		bit	0,C			* sfx tempo based - tick gone by?
	dc.b	$CB,$41
* 		jr	Z,updseqloop2		* no - skip it
	dc.b	$28,$0D
* 
* updseqdoit
* 	call	DACME
	dc.b	$CD,$B7,$02
* 		push	AF
	dc.b	$F5
* 		push	BC
	dc.b	$C5
* 
* 	call	FILLDACFIFO
	dc.b	$CD,$02,$03
* 
* 		call	SEQUENCER
	dc.b	$CD,$B4,$04
* 		pop	BC
	dc.b	$C1
* 		pop	AF
	dc.b	$F1
* updseqloop2
* 		inc	B
	dc.b	$04
* 		dec	A
	dc.b	$3D
* 		jr	NZ,updseqloop
	dc.b	$20,$BF
* 		ret
	dc.b	$C9
* 
* *
* *  SEQUENCER - if the channel has timed out, then execute the next set of sequencer cmds
* *
* *	parameters:		IX	points to channel control block (CCB)
* *				B	channel
* *				C	timerbase flags ([0] = sfx, [1] = music)
* *
* 
* SEQUENCER
* 		inc	(IX+CCBTIMERL)			* increment channel timer
	dc.b	$DD,$34,$07
* 		ret	NZ
	dc.b	$C0
* 		inc	(IX+CCBTIMERH)
	dc.b	$DD,$34,$08
* 		ret	NZ
	dc.b	$C0
* seqcmdloop0
* 		call	GETSBYTE		* timed out! - do the next sequence commands
	dc.b	$CD,$EF,$03
* seqcmdloop
* 		bit	7,A			* dispatch on cmd type
	dc.b	$CB,$7F
* 		jp	Z,seqnote
	dc.b	$CA,$47,$05
* 		bit	6,A
	dc.b	$CB,$77
* 		jr	Z,seqdur
	dc.b	$28,$3F
* seqdel						* process delay commands
* 		zand	3FH			* get data bits into DE
	dc.b	$E6,$3F
* 		ld	E,A
	dc.b	$5F
* 		ld	D,0
	dc.b	$16,$00
* seqdelloop
* 		call	GETSBYTE		* is next command also a delay cmd?
	dc.b	$CD,$EF,$03
* 		bit	7,A
	dc.b	$CB,$7F
* 		jr	Z,seqdeldone
	dc.b	$28,$22
* 		bit	6,A
	dc.b	$CB,$77
* 		jr	Z,seqdeldone
	dc.b	$28,$1E
* 
* 		sla	E			* yes, shift in its data as the new lsbs
	dc.b	$CB,$23
* 		rl	D
	dc.b	$CB,$12
* 		sla	E
	dc.b	$CB,$23
* 		rl	D
	dc.b	$CB,$12
* 		sla	E
	dc.b	$CB,$23
* 		rl	D
	dc.b	$CB,$12
* 		sla	E
	dc.b	$CB,$23
* 		rl	D
	dc.b	$CB,$12
* 		sla	E
	dc.b	$CB,$23
* 		rl	D
	dc.b	$CB,$12
* 		sla	E
	dc.b	$CB,$23
* 		rl	D
	dc.b	$CB,$12
* 		zand	3FH
	dc.b	$E6,$3F
* 		zor	E
	dc.b	$B3
* 		ld	E,A
	dc.b	$5F
* 		jr	seqdelloop
	dc.b	$18,$D7
* seqdeldone
* 		ld	H,A
	dc.b	$67
* 		ld	A,E
	dc.b	$7B
* 		cpl
	dc.b	$2F
* 		ld	E,A
	dc.b	$5F
* 		ld	A,D
	dc.b	$7A
* 		cpl
	dc.b	$2F
* 		ld	D,A
	dc.b	$57
* 		inc	DE			* negate delay value before storing
	dc.b	$13
* 		ld	(IX+CCBDELL),E
	dc.b	$DD,$73,$09
* 		ld	(IX+CCBDELH),D
	dc.b	$DD,$72,$0A
* 		ld	A,H
	dc.b	$7C
* 		jr	seqcmdloop
	dc.b	$18,$B8
* seqdur						* process duration commands
* 		zand	3FH			* get data bits into DE
	dc.b	$E6,$3F
* 		ld	E,A
	dc.b	$5F
* 		ld	D,0
	dc.b	$16,$00
* seqdurloop
* 		call	GETSBYTE		* is next command also a duration cmd?
	dc.b	$CD,$EF,$03
* 		bit	7,A
	dc.b	$CB,$7F
* 		jr	Z,seqdurdone
	dc.b	$28,$22
* 		bit	6,A
	dc.b	$CB,$77
* 		jr	NZ,seqdurdone
	dc.b	$20,$1E
* 
* 		sla	E			* yes, shift in its data as the new lsbs
	dc.b	$CB,$23
* 		rl	D
	dc.b	$CB,$12
* 		sla	E
	dc.b	$CB,$23
* 		rl	D
	dc.b	$CB,$12
* 		sla	E
	dc.b	$CB,$23
* 		rl	D
	dc.b	$CB,$12
* 		sla	E
	dc.b	$CB,$23
* 		rl	D
	dc.b	$CB,$12
* 		sla	E
	dc.b	$CB,$23
* 		rl	D
	dc.b	$CB,$12
* 		sla	E
	dc.b	$CB,$23
* 		rl	D
	dc.b	$CB,$12
* 		zand	3FH
	dc.b	$E6,$3F
* 		zor	E
	dc.b	$B3
* 		ld	E,A
	dc.b	$5F
* 		jr	seqdurloop
	dc.b	$18,$D7
* seqdurdone
* 		ld	H,A
	dc.b	$67
* 		ld	A,E
	dc.b	$7B
* 		cpl
	dc.b	$2F
* 		ld	E,A
	dc.b	$5F
* 		ld	A,D
	dc.b	$7A
* 		cpl
	dc.b	$2F
* 		ld	D,A
	dc.b	$57
* 		inc	DE			* negate duration value before storing
	dc.b	$13
* 		ld	(IX+CCBDURL),E
	dc.b	$DD,$73,$0B
* 		ld	(IX+CCBDURH),D
	dc.b	$DD,$72,$0C
* 		ld	A,H
	dc.b	$7C
* 		jp	seqcmdloop
	dc.b	$C3,$BF,$04
* 
* seqnote						* process a note or command
* 		cp	96			* commands are 96-127
	dc.b	$FE,$60
* 		jr	NC,seqcmd
	dc.b	$30,$25
* 		bit	1,(IX+CCBFLAGS)		* is this channel muted?
	dc.b	$DD,$CB,$06,$4E
* 		jr	NZ,seqdelay		* yup - don't note on
	dc.b	$20,$0A
* 		push	BC
	dc.b	$C5
* 		push	IX
	dc.b	$DD,$E5
* 		ld	C,A			* C <- note* B is already channel
	dc.b	$4F
* 		call	NOTEON
	dc.b	$CD,$06,$12
* 		pop	IX
	dc.b	$DD,$E1
* 		pop	BC
	dc.b	$C1
* seqdelay
* 
* 	call	DACME
	dc.b	$CD,$B7,$02
* 
* 		ld	E,(IX+CCBDELL)
	dc.b	$DD,$5E,$09
* 		ld	D,(IX+CCBDELH)		* DE <- delay
	dc.b	$DD,$56,$0A
* 		ld	A,D
	dc.b	$7A
* 		zor	E
	dc.b	$B3
* 		jp	Z,seqcmdloop0		* zero delay - do another command
	dc.b	$CA,$BC,$04
* 		ld	(IX+CCBTIMERL),E	* non-zero delay - set channel timer
	dc.b	$DD,$73,$07
* 		ld	(IX+CCBTIMERH),D
	dc.b	$DD,$72,$08
* 		ret
	dc.b	$C9
* seqcmd
* 		zsub	96
	dc.b	$D6,$60
* 		jp	Z,seqeos		* 96 = eos
	dc.b	$CA,$06,$06
* 		dec	A
	dc.b	$3D
* 		jp	Z,seqpchange		* 97 = pchange
	dc.b	$CA,$13,$06
* 		dec	A
	dc.b	$3D
* 		jp	Z,seqenv		* 98 = env
	dc.b	$CA,$C0,$05
* 		dec	A
	dc.b	$3D
* 		jp	Z,seqdelay		* 99 = nop (triggers another delay)
	dc.b	$CA,$5B,$05
* 		dec	A
	dc.b	$3D
* 		jp	Z,seqsloop		* 100 = loop start
	dc.b	$CA,$21,$06
* 		dec	A
	dc.b	$3D
* 		jp	Z,seqeloop		* 101 = loopend
	dc.b	$CA,$4C,$06
* 		dec	A
	dc.b	$3D
* 		jp	Z,seqretrig		* 102 = retrigger mode
	dc.b	$CA,$DD,$05
* 		dec	A
	dc.b	$3D
* 		jp	Z,seqsus		* 103 = sustain
	dc.b	$CA,$F2,$05
* 		dec	A
	dc.b	$3D
* 		jp	Z,seqtempo		* 104 = tempo
	dc.b	$CA,$8B,$06
* 		dec	A
	dc.b	$3D
* 		jp	Z,seqmute		* 105 = mute
	dc.b	$CA,$96,$06
* 		dec	A
	dc.b	$3D
* 		jp	Z,seqprio		* 106 = priority
	dc.b	$CA,$D3,$06
* 		dec	A
	dc.b	$3D
* 		jp	Z,seqssong		* 107 = start song
	dc.b	$CA,$DC,$06
* 		dec	A
	dc.b	$3D
* 		jp	Z,seqpbend		* 108 = pitch bend
	dc.b	$CA,$EB,$06
* 		dec	A
	dc.b	$3D
* 		jp	Z,seqsfx		* 109 = use sfx timebase
	dc.b	$CA,$0C,$07
* 		dec	A
	dc.b	$3D
* 		jp	Z,seqsamprate		* 110 = set sample plbk rate
	dc.b	$CA,$13,$07
* 		dec	A
	dc.b	$3D
* 		jp	Z,seqgoto		* 111 = goto
	dc.b	$CA,$25,$07
* 		dec	A
	dc.b	$3D
* 		jp	Z,seqstore		* 112 = store
	dc.b	$CA,$4B,$07
* 		dec	A
	dc.b	$3D
* 		jp	Z,seqif			* 113 = if
	dc.b	$CA,$52,$07
* 		dec	A
	dc.b	$3D
* 		jp	Z,seqseekrit		* 114 = seekrit codes
	dc.b	$CA,$A6,$07
* 
* 
* *** THIS COULD USE SOME FANCY ERROR DETECTION RIGHT ABOUT NOW
* 
* 		jp	seqcmdloop0
	dc.b	$C3,$BC,$04
* 
* seqenv
* 		call	GETSBYTE
	dc.b	$CD,$EF,$03
* 		ld	(IX+CCBENV),A
	dc.b	$DD,$77,$1D
* 		bit	6,(IX+CCBFLAGS)		* immediate mode envelopes?
	dc.b	$DD,$CB,$06,$76
* 		jp	NZ,seqdelay
	dc.b	$C2,$5B,$05
* 		push	BC
	dc.b	$C5
* 		push	IX
	dc.b	$DD,$E5
* 		ld	E,B			* E <- channel
	dc.b	$58
* 		ld	C,(IX+CCBENV)
	dc.b	$DD,$4E,$1D
* 		call	TRIGENV
	dc.b	$CD,$2D,$0E
* 		pop	IX
	dc.b	$DD,$E1
* 		pop	BC
	dc.b	$C1
* 		jp	seqdelay
	dc.b	$C3,$5B,$05
* seqretrig
* 		call	GETSBYTE
	dc.b	$CD,$EF,$03
* 		zor	A			* retrigger on?
	dc.b	$B7
* 		jp	NZ,seqrton
	dc.b	$C2,$EB,$05
* 		res	6,(IX+CCBFLAGS)
	dc.b	$DD,$CB,$06,$B6
* 		jp	seqdelay
	dc.b	$C3,$5B,$05
* seqrton
* 		zset	6,(IX+CCBFLAGS)
	dc.b	$DD,$CB,$06,$F6
* 		jp	seqdelay
	dc.b	$C3,$5B,$05
* seqsus
* 		call	GETSBYTE
	dc.b	$CD,$EF,$03
* 		zor	A
	dc.b	$B7
* 		jr	NZ,seqsuson
	dc.b	$20,$07
* 		res	7,(IX+CCBFLAGS)
	dc.b	$DD,$CB,$06,$BE
* 		jp	seqdelay
	dc.b	$C3,$5B,$05
* seqsuson
* 		zset	7,(IX+CCBFLAGS)
	dc.b	$DD,$CB,$06,$FE
* 		jp	seqdelay
	dc.b	$C3,$5B,$05
* seqeos
* 		ld	(IX+CCBFLAGS),0		* end of sequence - disable CCB (free it)
	dc.b	$DD,$36,$06,$00
* 		ld	(IX+CCBDURL),0
	dc.b	$DD,$36,$0B,$00
* 		ld	(IX+CCBDURH),0
	dc.b	$DD,$36,$0C,$00
* 		ret
	dc.b	$C9
* seqpchange
* 		call	GETSBYTE
	dc.b	$CD,$EF,$03
* 		ld	(IX+CCBPNUM),A
	dc.b	$DD,$77,$0D
* 		push	BC
	dc.b	$C5
* 		call	FETCHPATCH
	dc.b	$CD,$37,$17
* 		pop	BC
	dc.b	$C1
* 		jp	seqdelay
	dc.b	$C3,$5B,$05
* seqsloop
* 		push	IX
	dc.b	$DD,$E5
* 		pop	IY
	dc.b	$FD,$E1
* 		ld	DE,16			* CCBLOOP0
	dc.b	$11,$10,$00
* 		zadd	IY,DE			* IY <- first loop stack entry for this CCB
	dc.b	$FD,$19
* 		ld	DE,3
	dc.b	$11,$03,$00
* seqsllp
* 		ld	A,(IY+0)		* is this stack entry free?
	dc.b	$FD,$7E,$00
* 		zor	A
	dc.b	$B7
* 		jr	Z,seqslfound
	dc.b	$28,$04
* 		zadd	IY,DE			* no - try the next one
	dc.b	$FD,$19
* 		jr	seqsllp
	dc.b	$18,$F6
* seqslfound
* 		call	GETSBYTE		* yes - store loop count and addr[15:0]
	dc.b	$CD,$EF,$03
* 		ld	(IY+0),A
	dc.b	$FD,$77,$00
* 		ld	A,(IX+CCBADDRL)
	dc.b	$DD,$7E,$03
* 		ld	(IY+1),A
	dc.b	$FD,$77,$01
* 		ld	A,(IX+CCBADDRM)
	dc.b	$DD,$7E,$04
* 		ld	(IY+2),A
	dc.b	$FD,$77,$02
* 		jp	seqcmdloop0
	dc.b	$C3,$BC,$04
* seqeloop
* 		push	IX
	dc.b	$DD,$E5
* 		pop	IY
	dc.b	$FD,$E1
* 		ld	DE,25			* CCBLOOP3
	dc.b	$11,$19,$00
* 		zadd	IY,DE			* IY <- last loop stack entry for this CCB
	dc.b	$FD,$19
* 		ld	DE,0FFFDH		* -3
	dc.b	$11,$FD,$FF
* seqellp
* 		ld	A,(IY+0)		* is this stack entry free?
	dc.b	$FD,$7E,$00
* 		zor	A
	dc.b	$B7
* 		jr	NZ,seqelfound
	dc.b	$20,$04
* 		zadd	IY,DE			* yes - try the previous one
	dc.b	$FD,$19
* 		jr	seqellp
	dc.b	$18,$F6
* seqelfound
* 		cp	127			* endless loop - go back
	dc.b	$FE,$7F
* 		jr	Z,seqelgobk
	dc.b	$28,$07
* 		dec	A
	dc.b	$3D
* 		ld	(IY+0),A
	dc.b	$FD,$77,$00
* 		jp	Z,seqcmdloop0		* end of finite loop - don't go back
	dc.b	$CA,$BC,$04
* seqelgobk
* 		ld	L,(IY+1)		* loop addr lsb
	dc.b	$FD,$6E,$01
* 		ld	E,(IX+CCBADDRL)		* current addr lsb
	dc.b	$DD,$5E,$03
* 		ld	(IX+CCBADDRL),L
	dc.b	$DD,$75,$03
* 		ld	H,(IY+2)		* HL <- loop back addr lsw
	dc.b	$FD,$66,$02
* 		ld	D,(IX+CCBADDRM)		* DE <- current addr lsw
	dc.b	$DD,$56,$04
* 		ld	(IX+CCBADDRM),H		* current addr lsw <- loop back addr lsw
	dc.b	$DD,$74,$04
* 		scf
	dc.b	$37
* 		ccf
	dc.b	$3F
* 		sbc	HL,DE
	dc.b	$ED,$52
* 		jr	C,seqelnoc		* if loop back lsw > current addr
	dc.b	$38,$03
* 		dec	(IX+CCBADDRH)		*   then dec current addr msb
	dc.b	$DD,$35,$05
* seqelnoc
* 		jp	seqcmdloop0
	dc.b	$C3,$BC,$04
* 
* seqtempo
* 		call	GETSBYTE		* tempo value is offset by -40
	dc.b	$CD,$EF,$03
* 		zadd	A,40
	dc.b	$C6,$28
* 		call	SETTEMPO
	dc.b	$CD,$1B,$0E
* 		jp	seqdelay
	dc.b	$C3,$5B,$05
* 
* seqmute
* 		call	GETSBYTE		* [4] is 1 for mute, [3:0] is midi channel
	dc.b	$CD,$EF,$03
* 		ld	H,A
	dc.b	$67
* 		ld	L,16
	dc.b	$2E,$10
* 		ld	IY,CCB
	dc.b	$FD,$21,$80,$1B
* 		ld	DE,32
	dc.b	$11,$20,$00
* seqmutelp
* 		bit	0,(IY+CCBFLAGS)		* channel in use?
	dc.b	$FD,$CB,$06,$46
* 		jr	Z,seqmutenext
	dc.b	$28,$10
* 		ld	A,(IY+CCBSNUM)		* running this sequence?
	dc.b	$FD,$7E,$0E
* 		cp	(IX+CCBSNUM)
	dc.b	$DD,$BE,$0E
* 		jr	NZ,seqmutenext
	dc.b	$20,$08
* 		ld	A,H			* and the desired channel?
	dc.b	$7C
* 		zand	0FH
	dc.b	$E6,$0F
* 		cp	(IY+CCBVCHAN)
	dc.b	$FD,$BE,$0F
* 		jr	Z,seqmuteit
	dc.b	$28,$08
* seqmutenext					* try the next chan
* 		dec	L
	dc.b	$2D
* 		jp	Z,seqdelay		* all dun
	dc.b	$CA,$5B,$05
* 		zadd	IY,DE
	dc.b	$FD,$19
* 		jr	seqmutelp
	dc.b	$18,$E2
* seqmuteit
* 		bit	4,H			* mute or unmute?
	dc.b	$CB,$64
* 		jr	NZ,sequnmute
	dc.b	$20,$07
* 		zset	1,(IY+CCBFLAGS)
	dc.b	$FD,$CB,$06,$CE
* 		jp	seqdelay
	dc.b	$C3,$5B,$05
* sequnmute
* 		res	1,(IY+CCBFLAGS)
	dc.b	$FD,$CB,$06,$8E
* 		jp	seqdelay
	dc.b	$C3,$5B,$05
* 
* seqprio
* 		call	GETSBYTE
	dc.b	$CD,$EF,$03
* 		ld	(IX+CCBPRIO),A
	dc.b	$DD,$77,$1C
* 		jp	seqdelay
	dc.b	$C3,$5B,$05
* 
* seqssong	call	GETSBYTE
	dc.b	$CD,$EF,$03
* 		push	IX
	dc.b	$DD,$E5
* 		push	BC
	dc.b	$C5
* 		call	STARTSEQ
	dc.b	$CD,$DF,$0B
* 		pop	BC
	dc.b	$C1
* 		pop	IX
	dc.b	$DD,$E1
* 		jp	seqdelay
	dc.b	$C3,$5B,$05
* 
* seqpbend
* 		ld	IY,PBTBL
	dc.b	$FD,$21,$76,$0F
* 		ld	E,B
	dc.b	$58
* 		ld	D,0
	dc.b	$16,$00
* 		zadd	IY,DE			* IY <- pointer to this ch's pitch bend data
	dc.b	$FD,$19
* 
* 		call	GETSBYTE		* 16 bit signed pitch bend (8 frac bits, semitones)
	dc.b	$CD,$EF,$03
* 		ld	(IY+PBPBL),A
	dc.b	$FD,$77,$00
* 		call	GETSBYTE
	dc.b	$CD,$EF,$03
* 		ld	(IY+PBPBH),A
	dc.b	$FD,$77,$10
* 		zset	0,(IY+PBRETRIG)
	dc.b	$FD,$CB,$40,$C6
* 		ld	A,1
	dc.b	$3E,$01
* 		ld	(NEEDBEND),A
	dc.b	$32,$75,$0F
* 		jp	seqdelay
	dc.b	$C3,$5B,$05
* seqsfx
* 		zset	3,(IX+CCBFLAGS)		* set sfx timebase flag in CCB
	dc.b	$DD,$CB,$06,$DE
* 		jp	seqdelay
	dc.b	$C3,$5B,$05
* seqsamprate
* 		call	GETSBYTE
	dc.b	$CD,$EF,$03
* 		ld	D,A
	dc.b	$57
* 		ld	HL,(CHPATPTR)
	dc.b	$2A,$56,$04
* 		ld	A,(HL)			* is this a digital patch?
	dc.b	$7E
* 		cp	1
	dc.b	$FE,$01
* 		jp	NZ,seqdelay		* no - no effect
	dc.b	$C2,$5B,$05
* 		inc	HL			* yes - update sample rate value
	dc.b	$23
* 		ld	(HL),D
	dc.b	$72
* 		jp	seqdelay
	dc.b	$C3,$5B,$05
* seqgoto
* 		call	GETSBYTE		* get 16 signed offset
	dc.b	$CD,$EF,$03
* 		ld	L,A
	dc.b	$6F
* 		call	GETSBYTE
	dc.b	$CD,$EF,$03
* 		ld	H,A
	dc.b	$67
* 		rla
	dc.b	$17
* 		ld	A,0
	dc.b	$3E,$00
* 		sbc	A,0
	dc.b	$DE,$00
* 		ld	D,A
	dc.b	$57
* seqbranch					* jump to addr + 24 bit offset in DHL
* 		ld	A,(IX+CCBADDRL)
	dc.b	$DD,$7E,$03
* 		zadd	A,L
	dc.b	$85
* 		ld	(IX+CCBADDRL),A
	dc.b	$DD,$77,$03
* 		ld	A,(IX+CCBADDRM)
	dc.b	$DD,$7E,$04
* 		adc	A,H
	dc.b	$8C
* 		ld	(IX+CCBADDRM),A
	dc.b	$DD,$77,$04
* 		ld	A,(IX+CCBADDRH)
	dc.b	$DD,$7E,$05
* 		adc	A,D
	dc.b	$8A
* 		ld	(IX+CCBADDRH),A
	dc.b	$DD,$77,$05
* 		jp	seqcmdloop0
	dc.b	$C3,$BC,$04
* seqstore
* 		call	seqmboxstart		* HL <- ptr to mbox, A <- next byte in op
	dc.b	$CD,$98,$07
* 		ld	(HL),A			* store value in mbox
	dc.b	$77
* 		jp	seqdelay
	dc.b	$C3,$5B,$05
* seqif
* 		call	seqmboxstart		* HL <- ptr to mbox, A <- next byte in op
	dc.b	$CD,$98,$07
* 		ld	D,A			* save relation in D
	dc.b	$57
* 		call	GETSBYTE		* A <- value
	dc.b	$CD,$EF,$03
* 		dec	D
	dc.b	$15
* 		jr	NZ,seqif0
	dc.b	$20,$05
* seqifne
* 		cp	(HL)			* V-M: if M<>V then NZ
	dc.b	$BE
* 		jr	NZ,seqifdoit
	dc.b	$20,$33
* 		jr	seqifpunt
	dc.b	$18,$27
* seqif0
* 		dec	D
	dc.b	$15
* 		jr	NZ,seqif1
	dc.b	$20,$05
* seqifgt
* 		cp	(HL)			* V-M: if M>V then C
	dc.b	$BE
* 		jr	C,seqifdoit
	dc.b	$38,$2B
* 		jr	seqifpunt
	dc.b	$18,$1F
* seqif1
* 		dec	D
	dc.b	$15
* 		jr	NZ,seqif2
	dc.b	$20,$07
* seqifgte
* 		cp	(HL)			* V-M: if M>=V then C|Z
	dc.b	$BE
* 		jr	C,seqifdoit
	dc.b	$38,$23
* 		jr	Z,seqifdoit
	dc.b	$28,$21
* 		jr	seqifpunt
	dc.b	$18,$15
* seqif2
* 		dec	D
	dc.b	$15
* 		jr	NZ,seqif3
	dc.b	$20,$07
* seqiflt
* 		cp	(HL)			* V-M: if M<V then NZ & NC
	dc.b	$BE
* 		jr	C,seqifpunt
	dc.b	$38,$0F
* 		jr	Z,seqifpunt
	dc.b	$28,$0D
* 		jr	seqifdoit
	dc.b	$18,$15
* seqif3
* 		dec	D
	dc.b	$15
* 		jr	NZ,seqifeq
	dc.b	$20,$05
* seqiflte
* 		cp	(HL)			* V-M: if M<=V then NC
	dc.b	$BE
* 		jr	NC,seqifdoit
	dc.b	$30,$0F
* 		jr	seqifpunt
	dc.b	$18,$03
* seqifeq
* 		cp	(HL)
	dc.b	$BE
* 		jr	Z,seqifdoit
	dc.b	$28,$0A
* seqifpunt
* 		call	GETSBYTE
	dc.b	$CD,$EF,$03
* 		ld	L,A
	dc.b	$6F
* 		ld	H,0
	dc.b	$26,$00
* 		ld	D,0
	dc.b	$16,$00
* 		jr	seqbranch
	dc.b	$18,$A1
* seqifdoit
* 		call	GETSBYTE
	dc.b	$CD,$EF,$03
* 		jp	seqcmdloop0
	dc.b	$C3,$BC,$04
* 
* seqmboxstart
* 		call	GETSBYTE		* get  mailbox num
	dc.b	$CD,$EF,$03
* 		ld	E,A
	dc.b	$5F
* 		ld	D,0
	dc.b	$16,$00
* 		ld	HL,MBOXES+2
	dc.b	$21,$22,$1B
* 		zadd	HL,DE			* HL <- pointer to mailbox
	dc.b	$19
* 		call	GETSBYTE		* get next byte
	dc.b	$CD,$EF,$03
* 		ret
	dc.b	$C9
* 
* seqseekrit					* extra functions (like a generic ctrllr)
* 		call	GETSBYTE		* get code
	dc.b	$CD,$EF,$03
* 		ld	D,A
	dc.b	$57
* 		call	GETSBYTE		* get value
	dc.b	$CD,$EF,$03
* 		ld	E,A
	dc.b	$5F
* 		ld	A,D			* dispatch on code
	dc.b	$7A
* 		cp	0
	dc.b	$FE,$00
* 		jp	Z,seqstopseq
	dc.b	$CA,$DB,$07
* 		cp	1
	dc.b	$FE,$01
* 		jp	Z,seqpauseseq
	dc.b	$CA,$E8,$07
* 		cp	2
	dc.b	$FE,$02
* 		jp	Z,seqresume
	dc.b	$CA,$FA,$07
* 		cp	3
	dc.b	$FE,$03
* 		jp	Z,seqpauselmusic
	dc.b	$CA,$F5,$07
* 		cp	4
	dc.b	$FE,$04
* 		jr	Z,seqatten
	dc.b	$28,$07
* 		cp	5
	dc.b	$FE,$05
* 		jr	Z,seqchatten
	dc.b	$28,$0A
* 		jp	seqdelay
	dc.b	$C3,$5B,$05
* 
* seqatten
* 		ld	A,E
	dc.b	$7B
* 		ld	(MASTERATN),A
	dc.b	$32,$CF,$15
* 		jp	seqdelay
	dc.b	$C3,$5B,$05
* 
* seqchatten
* 		ld	(IX+CCBATN),E
	dc.b	$DD,$73,$1E
* 		jp	seqdelay
	dc.b	$C3,$5B,$05
* 
* seqstopseq
* 		push	IX
	dc.b	$DD,$E5
* 		push	BC
	dc.b	$C5
* 		ld	A,E
	dc.b	$7B
* 		call	STOPSEQ
	dc.b	$CD,$9E,$0C
* 		pop	BC
	dc.b	$C1
* 		pop	IX
	dc.b	$DD,$E1
* 		jp	seqdelay
	dc.b	$C3,$5B,$05
* 
* seqpauseseq
* 		ld	A,E
	dc.b	$7B
* seqpausecom
* 		push	IX
	dc.b	$DD,$E5
* 		push	BC
	dc.b	$C5
* 		call	PAUSESEQ
	dc.b	$CD,$D1,$0C
* 		pop	BC
	dc.b	$C1
* 		pop	IX
	dc.b	$DD,$E1
* 		jp	seqdelay
	dc.b	$C3,$5B,$05
* 
* seqpauselmusic
* 		ld	A,(MBOXES+2)
	dc.b	$3A,$22,$1B
* 		jr	seqpausecom
	dc.b	$18,$EF
* 
* seqresume
* 		push	IX
	dc.b	$DD,$E5
* 		push	BC
	dc.b	$C5
* 		call	RESUMEALL
	dc.b	$CD,$89,$0B
* 		pop	BC
	dc.b	$C1
* 		pop	IX
	dc.b	$DD,$E1
* 		jp	seqdelay
	dc.b	$C3,$5B,$05
* 
* *
* *  VTIMER - updates the voice timers - first note on and then release values
* *
* 
* VTIMER
* 		ld	DE,7
	dc.b	$11,$07,$00
* 		ld	A,(TBASEFLAGS)
	dc.b	$3A,$C2,$08
* 		ld	B,A			* B <- tbase flags
	dc.b	$47
* 		ld	H,0			* indicates FM voices
	dc.b	$26,$00
* 		ld	IX,FMVTBL
	dc.b	$DD,$21,$91,$17
* 		call	vtimerloop
	dc.b	$CD,$28,$08
* 		inc	H			* indicates PSG voices
	dc.b	$24
* 		ld	IX,PSGVTBL
	dc.b	$DD,$21,$BC,$17
* 		call	vtimerloop
	dc.b	$CD,$28,$08
* 		ld	IX,PSGVTBLNG
	dc.b	$DD,$21,$D2,$17
* 		call	vtimerloop
	dc.b	$CD,$28,$08
* 		ret
	dc.b	$C9
* vtimerloop0
* 		zadd	IX,DE
	dc.b	$DD,$19
* vtimerloop
* 		ld	A,(IX+0)
	dc.b	$DD,$7E,$00
* 		cp	0FFH			* if eot
	dc.b	$FE,$FF
* 		ret	Z			*   return
	dc.b	$C8
* 	call	DACME
	dc.b	$CD,$B7,$02
* 		bit	3,A			* sfx tempo driven?
	dc.b	$CB,$5F
* 		jr	NZ,vtimersfx
	dc.b	$20,$06
* 		bit	1,B			* no - music beat flag set?
	dc.b	$CB,$48
* 		jr	Z,vtimerloop0
	dc.b	$28,$ED
* 		jr	vtimerdoit
	dc.b	$18,$04
* vtimersfx
* 		bit	0,B
	dc.b	$CB,$40
* 		jr	Z,vtimerloop0
	dc.b	$28,$E7
* vtimerdoit
* 		bit	6,A			* if in release
	dc.b	$CB,$77
* 		jr	Z,vtimerloop2
	dc.b	$28,$0C
* 		dec	(IX+6)			*   decrement release timer
	dc.b	$DD,$35,$06
* 		jr	NZ,vtimerloop0		*   not at zero, loop
	dc.b	$20,$DE
* 		res	6,A			*   turn off release flag
	dc.b	$CB,$B7
* 		ld	(IX+0),A
	dc.b	$DD,$77,$00
* 		jr	vtimerloop0
	dc.b	$18,$D7
* vtimerloop2
* 		bit	4,A			* self timed note?
	dc.b	$CB,$67
* 		jr	Z,vtimerloop0
	dc.b	$28,$D3
* 		zand	7			* yes - save voice # in C
	dc.b	$E6,$07
* 		ld	C,A
	dc.b	$4F
* 		inc	(IX+4)			* inc lsb of timer
	dc.b	$DD,$34,$04
* 		jr	NZ,vtimerloop0
	dc.b	$20,$CB
* 		inc	(IX+5)			* if zero (carry), inc msb
	dc.b	$DD,$34,$05
* 		jr	NZ,vtimerloop0
	dc.b	$20,$C6
* 
* 		res	4,(IX+0)		* timed out - clear self timer bit
	dc.b	$DD,$CB,$00,$A6
* 		res	3,(IX+0)		*   and clear sfx bit
	dc.b	$DD,$CB,$00,$9E
* 		ld	A,(IX+0)		* A <- note flags
	dc.b	$DD,$7E,$00
* 		zand	2FH			* mask lock and voice number
	dc.b	$E6,$2F
* 		cp	26H			* is it voice 6 (must be FM) and locked?
	dc.b	$FE,$26
* 		jr	Z,vtnoteoffdig		*   yes - its a digital noteoff
	dc.b	$28,$2F
* 		zset	6,(IX+0)		*   no - set release bit
	dc.b	$DD,$CB,$00,$F6
* 		zset	7,(IX+0)		*        set free bit
	dc.b	$DD,$CB,$00,$FE
* vtnoteoff					* note off...
* 		bit	0,H			* voice type?
	dc.b	$CB,$44
* 		jr	Z,vtnoteofffm
	dc.b	$28,$0F
* 
* 		ld	E,C			* psg - DE <- psg voice num
	dc.b	$59
* 		ld      IY,psgcom		* load psg register table
	dc.b	$FD,$21,$09,$00
* 		zadd	IY,DE			* point to correct register
	dc.b	$FD,$19
* 		ld	E,7			* restore DE to 7
	dc.b	$1E,$07
* 		zset	1,(IY+0)		* set key off command
	dc.b	$FD,$CB,$00,$CE
* 		jr	vtimerloop0
	dc.b	$18,$9A
* vtnoteofffm
* 		ld      IY,4000H        	* load fm register address
	dc.b	$FD,$21,$00,$40
* 		FMWrite 28H,C           	* key off
	dc.b	$79
	dc.b	$FD,$CB,$00,$7E
	dc.b	$20,$FA
	dc.b	$FD,$36,$00,$28
	dc.b	$FD,$77,$01
* 		jr	vtimerloop0
	dc.b	$18,$86
* vtnoteoffdig
* 		call	NOTEOFFDIG
	dc.b	$CD,$12,$17
* 		jr	vtimerloop0		* for now, note off don't effect digital
	dc.b	$18,$81
* 
* **************************************  MAIN LOOP  *****************************************
* 
* *
* * GETCCBPTR - gets one byte from command queue for channel number, multiplies by 32,
* *	and returns pointer to that channel's CCB in IX, as well as the channel #
* *	in A
* * GETCCBPTR2 - alternate entry point to providing channel # in A (skips GETCBYTE)
* *
* *	trashes DE
* *
* 
* GETCCBPTR
* 		call	GETCBYTE
	dc.b	$CD,$D1,$01
* GETCCBPTR2
* 		ld	D,0
	dc.b	$16,$00
* 		ld	E,A
	dc.b	$5F
* 		sla	E
	dc.b	$CB,$23
* 		sla	E
	dc.b	$CB,$23
* 		sla	E
	dc.b	$CB,$23
* 		sla	E
	dc.b	$CB,$23
* 		sla	E
	dc.b	$CB,$23
* 		rl	D			* DE <- 32 * channel
	dc.b	$CB,$12
* 		ld	IX,CCB
	dc.b	$DD,$21,$80,$1B
* 		zadd	IX,DE			* IX <- pointer to this channel's CCB
	dc.b	$DD,$19
* 		ret
	dc.b	$C9
* 
* *
* *  main - initialize command fifo, dispatch on commands
* *
* 
* SBPT		dw	204			* sub beats per tick (8frac), default is 120bpm
	dc.b	$CC
	dc.b	$00
* SBPTACC		dw	0			* accumulates ^^ each tick to track sub beats
	dc.b	$00
	dc.b	$00
* TBASEFLAGS	db	0
	dc.b	$00
* 
* main						* ints are disabled upon entry here
* 		exx				* initialize alternate regs for DACME calls
	dc.b	$D9
* 		ld	B,15H			* timer reset command (also hold CH3 mode bits)
	dc.b	$06,$15
* 		ld	D,1FH			* read pointer from DACFIFO - msb always = 1FH
	dc.b	$16,$1F
* 		ld	HL,4000H		* points to base of FM chip
	dc.b	$21,$00,$40
* 		exx
	dc.b	$D9
* 		ei
	dc.b	$FB
* 
* 		ld	HL,7F11H		* silence the psg voices
	dc.b	$21,$11,$7F
* 		ld	(HL),09FH
	dc.b	$36,$9F
* 		ld	(HL),0BFH
	dc.b	$36,$BF
* 		ld	(HL),0DFH
	dc.b	$36,$DF
* 		ld	(HL),0FFH
	dc.b	$36,$FF
* 
* 		ld	HL,PATCHDATA		* set all patch buffers to undefined
	dc.b	$21,$86,$18
* 		ld	DE,39
	dc.b	$11,$27,$00
* 		ld	B,16
	dc.b	$06,$10
* pinitloop
* 		ld	(HL),0FFH
	dc.b	$36,$FF
* 		zadd	HL,DE
	dc.b	$19
* 		dec	B
	dc.b	$05
* 		jr	NZ,pinitloop
	dc.b	$20,$FA
* 
* 		ld	HL,(DACME)		* save the jr in DACME to slow sample rate mode
	dc.b	$2A,$B7,$02
* 		ld	(DACMEJRINST),HL
	dc.b	$22,$B3,$02
* 		ld	HL,(DACMEPROC)		* save the jr for enabling processing
	dc.b	$2A,$C4,$02
* 		ld	(DACME4BINST),HL
	dc.b	$22,$B5,$02
* 
* 		ld	A,0C9H			* opcode "RET"
	dc.b	$3E,$C9
* 		ld	(DACME),A		* and disable for now
	dc.b	$32,$B7,$02
* 
* 		export	loop
* loop
* 		call	CHECKTICK
	dc.b	$CD,$41,$00
* 
* 		call	DACME
	dc.b	$CD,$B7,$02
* 
* 		call	FILLDACFIFO
	dc.b	$CD,$02,$03
* 
* 		call	DACME
	dc.b	$CD,$B7,$02
* 
* 		call	CHECKTICK
	dc.b	$CD,$41,$00
* 
* 		ld	B,0			* b[0] if 60Hz tick, b[1] if 1/24 beat tick
	dc.b	$06,$00
* 
* 		ld	A,(TICKCNT)		* check tick counter
	dc.b	$3A,$40,$00
* 		zsub	1
	dc.b	$D6,$01
* 		jr	C,noticks
	dc.b	$38,$0B
* 
* 		ld	(TICKCNT),A		* a tick's gone by...
	dc.b	$32,$40,$00
* 		call	DOPSGENV		*   do PSG envs and set tick flag
	dc.b	$CD,$66,$00
* 		call	CHECKTICK
	dc.b	$CD,$41,$00
* 		ld	B,1			*   set tick flag
	dc.b	$06,$01
* noticks
* 		call	DACME
	dc.b	$CD,$B7,$02
* 
* 		ld	A,(SBPTACC+1)		* check beat counter (scaled by tempo)
	dc.b	$3A,$C1,$08
* 		zsub	1
	dc.b	$D6,$01
* 		jr	C,nobeats
	dc.b	$38,$05
* 
* 		ld	(SBPTACC+1),A		* a beat (1/24 beat) 's gone by...
	dc.b	$32,$C1,$08
* 		zset	1,B			*   set beat flag
	dc.b	$CB,$C8
* nobeats
* 		ld	A,B
	dc.b	$78
* 		zor	A
	dc.b	$B7
* 		jr	Z,neithertick
	dc.b	$28,$15
* 		ld	(TBASEFLAGS),A
	dc.b	$32,$C2,$08
* 
* 		call	DOENVELOPE		* call the envelope processor
	dc.b	$CD,$C8,$0E
* 		call	CHECKTICK
	dc.b	$CD,$41,$00
* 		call	VTIMER			* update voice timers
	dc.b	$CD,$06,$08
* 		call	CHECKTICK
	dc.b	$CD,$41,$00
* 		call	UPDSEQ			* update sequencers
	dc.b	$CD,$58,$04
* 		call	CHECKTICK
	dc.b	$CD,$41,$00
* neithertick
* 		call	APPLYBEND		* check if bends need applying
	dc.b	$CD,$C6,$0F
* 
* 		ld	A,(CMDWPTR)		* check for command bytes...
	dc.b	$3A,$36,$00
* 		ld	B,A
	dc.b	$47
* 		ld	A,(cmdrptr)		* compare read and write pointers
	dc.b	$3A,$37,$00
* 		cp	B
	dc.b	$B8
* 		jp	Z,loop			* loop if no command bytes waiting
	dc.b	$CA,$F7,$08
* 
* 		call	GETCBYTE		* main loop
	dc.b	$CD,$D1,$01
* 		cp	0FFH			* start of command?
	dc.b	$FE,$FF
* 		jp	NZ,loop			* no, wait for one
	dc.b	$C2,$F7,$08
* 
* 		call	GETCBYTE		* get command
	dc.b	$CD,$D1,$01
* 		cp	0			* note on?
	dc.b	$FE,$00
* 		jp	Z,cmdnoteon
	dc.b	$CA,$D6,$09
* 		cp	1
	dc.b	$FE,$01
* 		jp	Z,cmdnoteoff
	dc.b	$CA,$EA,$09
* 		cp	2
	dc.b	$FE,$02
* 		jp	Z,cmdpchange
	dc.b	$CA,$F8,$09
* 		cp	3
	dc.b	$FE,$03
* 		jp	Z,cmdpupdate
	dc.b	$CA,$FE,$09
* 		cp	4
	dc.b	$FE,$04
* 		jp	Z,cmdpbend
	dc.b	$CA,$07,$0A
* 		cp	5
	dc.b	$FE,$05
* 		jp	Z,cmdtempo
	dc.b	$CA,$4B,$0A
* 		cp	6
	dc.b	$FE,$06
* 		jp	Z,cmdenv
	dc.b	$CA,$54,$0A
* 		cp	7
	dc.b	$FE,$07
* 		jp	Z,cmdretrig
	dc.b	$CA,$6D,$0A
* 		cp	11
	dc.b	$FE,$0B
* 		jp	Z,cmdgetptrs
	dc.b	$CA,$96,$0A
* 		cp	12
	dc.b	$FE,$0C
* 		jp	Z,cmdpause
	dc.b	$CA,$B1,$0A
* 		cp	13
	dc.b	$FE,$0D
* 		jp	Z,cmdresume
	dc.b	$CA,$C9,$0A
* 		cp	14
	dc.b	$FE,$0E
* 		jp	Z,cmdsussw
	dc.b	$CA,$CF,$0A
* 		cp	16
	dc.b	$FE,$10
* 		jp	Z,cmdstartseq
	dc.b	$CA,$84,$0A
* 		cp	18
	dc.b	$FE,$12
* 		jp	Z,cmdstopseq
	dc.b	$CA,$8D,$0A
* 		cp	20
	dc.b	$FE,$14
* 		jp	Z,cmdsetprio
	dc.b	$CA,$E6,$0A
* 		cp	22
	dc.b	$FE,$16
* 		jp	Z,cmdstopall
	dc.b	$CA,$F2,$0A
* 		cp	23
	dc.b	$FE,$17
* 		jp	Z,cmdmute
	dc.b	$CA,$12,$0B
* 		cp	26
	dc.b	$FE,$1A
* 		jp	Z,cmdsamprate
	dc.b	$CA,$4F,$0B
* 		cp	27
	dc.b	$FE,$1B
* 		jp	Z,cmdstore
	dc.b	$CA,$64,$0B
* 		cp	28
	dc.b	$FE,$1C
* 		jp	Z,cmdlockch
	dc.b	$CA,$75,$0B
* 		cp	29
	dc.b	$FE,$1D
* 		jp	Z,cmdunlockch
	dc.b	$CA,$7F,$0B
* 		cp	30
	dc.b	$FE,$1E
* 		jp	Z,cmdpbendvch
	dc.b	$CA,$10,$0A
* 		cp	31
	dc.b	$FE,$1F
* 		jp	Z,cmdvolume
	dc.b	$CA,$A8,$0B
* 		cp	32
	dc.b	$FE,$20
* 		jp	Z,cmdmasteratn
	dc.b	$CA,$B4,$0B
* 		jp	loop
	dc.b	$C3,$F7,$08
* 
* cmdnoteon
* 		call	GETCCBPTR		* GETCBYTE for channel, IX <- CCB ptr, A <- channel
	dc.b	$CD,$A5,$08
* 		ld	B,A			* B <- channel
	dc.b	$47
* 		call	GETPATPTR		* HL <- PATCHDATA + 39 * A
	dc.b	$CD,$51,$11
* 		ld	(CHPATPTR),HL		* set pointer to this channel's patch buffer
	dc.b	$22,$56,$04
* 
* 		call	GETCBYTE
	dc.b	$CD,$D1,$01
* 		ld	C,A			* C <- note
	dc.b	$4F
* 		call	NOTEON
	dc.b	$CD,$06,$12
* 		jp	loop
	dc.b	$C3,$F7,$08
* 
* cmdnoteoff
* 		call	GETCBYTE		* yes
	dc.b	$CD,$D1,$01
* 		ld	B,A			* B <- channel
	dc.b	$47
* 		call	GETCBYTE
	dc.b	$CD,$D1,$01
* 		ld	C,A			* C <- note
	dc.b	$4F
* 		call	NOTEOFF
	dc.b	$CD,$9E,$16
* 		jp	loop
	dc.b	$C3,$F7,$08
* 
* cmdpchange
* 		call	PCHANGE
	dc.b	$CD,$28,$17
* 		jp	loop
	dc.b	$C3,$F7,$08
* 
* cmdpupdate
* 		call	GETCBYTE
	dc.b	$CD,$D1,$01
* 		call	PATCHLOAD
	dc.b	$CD,$66,$17
* 		jp	loop
	dc.b	$C3,$F7,$08
* 
* cmdpbend
* 		call	GETCBYTE		* get midi channel
	dc.b	$CD,$D1,$01
* 		call	DOPITCHBEND		* PITCHBEND gets its own bend data from the cmd queue
	dc.b	$CD,$56,$0F
* 		jp	loop
	dc.b	$C3,$F7,$08
* 
* cmdpbendvch
* 		call	GETCBYTE
	dc.b	$CD,$D1,$01
* 		ld	C,A			* C <- seq #
	dc.b	$4F
* 		call	GETCBYTE
	dc.b	$CD,$D1,$01
* 		ld	H,A			* H <- midi ch #
	dc.b	$67
* 		ld	L,0			* L <- gems ch # (CCB num)
	dc.b	$2E,$00
* 
* 		ld	IX,CCB			* start with CCB 0
	dc.b	$DD,$21,$80,$1B
* 		ld	DE,32
	dc.b	$11,$20,$00
* 		ld	B,16			* only 16 CCB's to try
	dc.b	$06,$10
* pbvchloop
* 		bit	0,(IX+CCBFLAGS)		* is this channel in use?
	dc.b	$DD,$CB,$06,$46
* 		jr	Z,pbvchskip		* no - skip it
	dc.b	$28,$13
* 		ld	A,(IX+CCBSNUM)		* yes - is it for this seq number?
	dc.b	$DD,$7E,$0E
* 		cp	C
	dc.b	$B9
* 		jr	NZ,pbvchskip
	dc.b	$20,$0D
* 		ld	A,(IX+CCBVCHAN)		* yes - for this channel ?
	dc.b	$DD,$7E,$0F
* 		cp	H
	dc.b	$BC
* 		jr	NZ,pbvchskip
	dc.b	$20,$07
* 		ld	A,L			* yes - bend this channel
	dc.b	$7D
* 		call	DOPITCHBEND
	dc.b	$CD,$56,$0F
* 		jp	loop
	dc.b	$C3,$F7,$08
* pbvchskip
* 		zadd	IX,DE
	dc.b	$DD,$19
* 		inc	L
	dc.b	$2C
* 		dec	B
	dc.b	$05
* 		jr	NZ,pbvchloop
	dc.b	$20,$E1
* 		call	GETCBYTE
	dc.b	$CD,$D1,$01
* 		call	GETCBYTE
	dc.b	$CD,$D1,$01
* 		jp	loop
	dc.b	$C3,$F7,$08
* 
* cmdtempo
* 		call	GETCBYTE
	dc.b	$CD,$D1,$01
* 		call	SETTEMPO
	dc.b	$CD,$1B,$0E
* 		jp	loop
	dc.b	$C3,$F7,$08
* 
* cmdenv
* 		call	GETCCBPTR		* GETCBYTE for channel, IX <- CCB ptr, A <- channel
	dc.b	$CD,$A5,$08
* 		ld	B,A			* B <- channel
	dc.b	$47
* 		call	GETCBYTE		* A <- envelope number
	dc.b	$CD,$D1,$01
* 		ld	(IX+CCBENV),A		* store new env number
	dc.b	$DD,$77,$1D
* 		bit	6,(IX+CCBFLAGS)		* retrigger mode?
	dc.b	$DD,$CB,$06,$76
* 		jp	NZ,loop
	dc.b	$C2,$F7,$08
* 
* 		ld	C,A			* C <- env num
	dc.b	$4F
* 		ld	E,B			* E <- channel
	dc.b	$58
* 		call	TRIGENV			* no - trigger immediately
	dc.b	$CD,$2D,$0E
* 		jp	loop
	dc.b	$C3,$F7,$08
* 
* cmdretrig
* 		call	GETCCBPTR		* GETCBYTE for channel, IX <- CCB ptr, A <- channel
	dc.b	$CD,$A5,$08
* 		call	GETCBYTE		* A <- 80h for retrigg, 0 for immediate
	dc.b	$CD,$D1,$01
* 		zor	A			* set retrigger?
	dc.b	$B7
* 		jr	Z,retrigclr
	dc.b	$28,$07
* 		zset	6,(IX+CCBFLAGS)
	dc.b	$DD,$CB,$06,$F6
* 		jp	loop
	dc.b	$C3,$F7,$08
* retrigclr
* 		res	6,(IX+CCBFLAGS)
	dc.b	$DD,$CB,$06,$B6
* 		jp	loop
	dc.b	$C3,$F7,$08
* 
* cmdstartseq					* start a sequence
* 		call	GETCBYTE
	dc.b	$CD,$D1,$01
* 		call	STARTSEQ
	dc.b	$CD,$DF,$0B
* 		jp	loop
	dc.b	$C3,$F7,$08
* 
* cmdstopseq
* 		call	GETCBYTE		* get sequencer number to stop
	dc.b	$CD,$D1,$01
* 		call	STOPSEQ
	dc.b	$CD,$9E,$0C
* 		jp	loop
	dc.b	$C3,$F7,$08
* 
* cmdgetptrs
* 		ld	HL,PTBL68K
	dc.b	$21,$A5,$0A
* 		ld	B,12			* read 12 bytes into the pointer variables
	dc.b	$06,$0C
* getptrslp
* 		call	GETCBYTE
	dc.b	$CD,$D1,$01
* 		ld	(HL),A
	dc.b	$77
* 		inc	HL
	dc.b	$23
* 		djnz	getptrslp
	dc.b	$10,$F9
* 		jp	loop
	dc.b	$C3,$F7,$08
* 
* PTBL68K		db	0,0,0			* 24-bit 68k space pointer to patch table
	dc.b	$00
	dc.b	$00
	dc.b	$00
* ETBL68K		db	0,0,0			* 24-bit 68k space pointer to envelope table
	dc.b	$00
	dc.b	$00
	dc.b	$00
* STBL68K		db	0,0,0			* 24-bit 68k space pointer to sequence table
	dc.b	$00
	dc.b	$00
	dc.b	$00
* DTBL68K		db	0,0,0			* 24-bit 68k space pointer to digital sample table
	dc.b	$00
	dc.b	$00
	dc.b	$00
* 
* cmdpause					* pause all CCB's current running
* 		ld	IX,CCB
	dc.b	$DD,$21,$80,$1B
* 		ld	B,16
	dc.b	$06,$10
* 		ld	DE,32
	dc.b	$11,$20,$00
* cmdpsloop					* go through CCB's
* 		res	4,(IX+CCBFLAGS)		* shut off running flags
	dc.b	$DD,$CB,$06,$A6
* 		zadd	IX,DE
	dc.b	$DD,$19
* 		dec	B
	dc.b	$05
* 		jr	NZ,cmdpsloop
	dc.b	$20,$F7
* 		call	CLIPALL
	dc.b	$CD,$F9,$0C
* 		jp	loop
	dc.b	$C3,$F7,$08
* 
* cmdresume
* 		call	RESUMEALL
	dc.b	$CD,$89,$0B
* 		jp	loop
	dc.b	$C3,$F7,$08
* 
* cmdsussw					* set sustain flag for this channel
* 		call	GETCCBPTR		* GETCBYTE for channel, IX <- CCB ptr, A <- channel
	dc.b	$CD,$A5,$08
* 		call	GETCBYTE
	dc.b	$CD,$D1,$01
* 		zor	A			* switch on?
	dc.b	$B7
* 		jr	Z,cmdsusoff
	dc.b	$28,$07
* 		zset	7,(IX+CCBFLAGS)		* yes
	dc.b	$DD,$CB,$06,$FE
* 		jp	loop
	dc.b	$C3,$F7,$08
* cmdsusoff
* 		res	7,(IX+CCBFLAGS)		* no
	dc.b	$DD,$CB,$06,$BE
* 		jp	loop
	dc.b	$C3,$F7,$08
* 
* cmdsetprio
* 		call	GETCCBPTR		* GETCBYTE for channel, IX <- CCB ptr, A <- channel
	dc.b	$CD,$A5,$08
* 		call	GETCBYTE		* set priority for this channel
	dc.b	$CD,$D1,$01
* 		ld	(IX+CCBPRIO),A
	dc.b	$DD,$77,$1C
* 		jp	loop
	dc.b	$C3,$F7,$08
* 
* cmdstopall
* 		ld	IX,CCB			* start with CCB 0
	dc.b	$DD,$21,$80,$1B
* 		ld	DE,32
	dc.b	$11,$20,$00
* 		ld	B,16			* only 16 CCB's to try
	dc.b	$06,$10
* stopallloop
* 		ld	(IX+CCBFLAGS),0		* yes - make it free, no retrig, no sustain
	dc.b	$DD,$36,$06,$00
* 		ld	(IX+CCBDURL),0		* clear duration to enable live play
	dc.b	$DD,$36,$0B,$00
* 		ld	(IX+CCBDURH),0
	dc.b	$DD,$36,$0C,$00
* 		zadd	IX,DE
	dc.b	$DD,$19
* 		dec	B
	dc.b	$05
* 		jr	NZ,stopallloop
	dc.b	$20,$EF
* 		call	CLIPALL			* chop off all notes
	dc.b	$CD,$F9,$0C
* 		jp	loop
	dc.b	$C3,$F7,$08
* 
* cmdmute
* 		call	GETCBYTE
	dc.b	$CD,$D1,$01
* 		ld	C,A			* C <- seq #
	dc.b	$4F
* 		call	GETCBYTE
	dc.b	$CD,$D1,$01
* 		ld	H,A			* H <- ch #
	dc.b	$67
* 		call	GETCBYTE
	dc.b	$CD,$D1,$01
* 		ld	L,A			* L <- 1 to mute, 0 to unmute
	dc.b	$6F
* 
* 		ld	IX,CCB			* start with CCB 0
	dc.b	$DD,$21,$80,$1B
* 		ld	DE,32
	dc.b	$11,$20,$00
* 		ld	B,16			* only 16 CCB's to try
	dc.b	$06,$10
* muteseqloop
* 		bit	0,(IX+CCBFLAGS)		* is this channel in use?
	dc.b	$DD,$CB,$06,$46
* 		jr	Z,muteseqskip		* no - skip it
	dc.b	$28,$1A
* 		ld	A,(IX+CCBSNUM)		* yes - is it for this seq number?
	dc.b	$DD,$7E,$0E
* 		cp	C
	dc.b	$B9
* 		jr	NZ,muteseqskip
	dc.b	$20,$14
* 		ld	A,(IX+CCBVCHAN)		* yes - for this channel ?
	dc.b	$DD,$7E,$0F
* 		cp	H
	dc.b	$BC
* 		jr	NZ,muteseqskip
	dc.b	$20,$0E
* 		bit	0,L			* mute or unmute?
	dc.b	$CB,$45
* 		jr	NZ,muteit
	dc.b	$20,$06
* 		res	1,(IX+CCBFLAGS)		* unmute
	dc.b	$DD,$CB,$06,$8E
* 		jr	muteseqskip
	dc.b	$18,$04
* muteit
* 		zset	1,(IX+CCBFLAGS)		* mute
	dc.b	$DD,$CB,$06,$CE
* muteseqskip
* 		dec	B
	dc.b	$05
* 		jp	Z,loop
	dc.b	$CA,$F7,$08
* 		zadd	IX,DE
	dc.b	$DD,$19
* 		jr	muteseqloop
	dc.b	$18,$D8
* cmdsamprate
* 		call	GETCBYTE		* A <- channel
	dc.b	$CD,$D1,$01
* 		call	GETPATPTR		* HL <- PATCHDATA + 39 * A
	dc.b	$CD,$51,$11
* 
* 		call	GETCBYTE
	dc.b	$CD,$D1,$01
* 		ld	B,A			* B <- new rate value
	dc.b	$47
* 
* 		ld	A,(HL)			* is this a digital patch?
	dc.b	$7E
* 		cp	1
	dc.b	$FE,$01
* 		jp	NZ,loop			* no - no effect
	dc.b	$C2,$F7,$08
* 		inc	HL			* yes - update sample rate value
	dc.b	$23
* 		ld	(HL),B
	dc.b	$70
* 		jp	loop
	dc.b	$C3,$F7,$08
* cmdstore
* 		call	GETCBYTE
	dc.b	$CD,$D1,$01
* 		ld	D,0
	dc.b	$16,$00
* 		ld	E,A
	dc.b	$5F
* 		ld	HL,MBOXES+2
	dc.b	$21,$22,$1B
* 		zadd	HL,DE
	dc.b	$19
* 		call	GETCBYTE
	dc.b	$CD,$D1,$01
* 		ld	(HL),A
	dc.b	$77
* 		jp	loop
	dc.b	$C3,$F7,$08
* cmdlockch
* 		call	GETCCBPTR		* GETCBYTE for channel, IX <- CCB ptr, A <- channel
	dc.b	$CD,$A5,$08
* 		zset	5,(IX+CCBFLAGS)
	dc.b	$DD,$CB,$06,$EE
* 		jp	loop
	dc.b	$C3,$F7,$08
* cmdunlockch
* 		call	GETCCBPTR		* GETCBYTE for channel, IX <- CCB ptr, A <- channel
	dc.b	$CD,$A5,$08
* 		res	5,(IX+CCBFLAGS)
	dc.b	$DD,$CB,$06,$AE
* 		jp	loop
	dc.b	$C3,$F7,$08
* 
* RESUMEALL					* resume all enabled CCB's
* 		ld	IX,CCB
	dc.b	$DD,$21,$80,$1B
* 		ld	B,16
	dc.b	$06,$10
* 		ld	DE,32
	dc.b	$11,$20,$00
* cmdresloop					* go through CCB's
* 		bit	5,(IX+CCBFLAGS)		* locked? then dont resume
	dc.b	$DD,$CB,$06,$6E
* 		jr	NZ,cmdresnext
	dc.b	$20,$0A
* 		bit	0,(IX+CCBFLAGS)
	dc.b	$DD,$CB,$06,$46
* 		jr	Z,cmdresnext
	dc.b	$28,$04
* 		zset	4,(IX+CCBFLAGS)		* set any enabled CCB's running again
	dc.b	$DD,$CB,$06,$E6
* cmdresnext
* 		dec	B
	dc.b	$05
* 		ret	Z
	dc.b	$C8
* 		zadd	IX,DE
	dc.b	$DD,$19
* 		jr	cmdresloop
	dc.b	$18,$EA
* 
* cmdvolume
* 		call	GETCCBPTR		* GETCBYTE for channel, IX <- CCB ptr, A <- channel
	dc.b	$CD,$A5,$08
* 		call	GETCBYTE		* get attenuation value
	dc.b	$CD,$D1,$01
* 		ld	(IX+CCBATN),A
	dc.b	$DD,$77,$1E
* 		jp	loop
	dc.b	$C3,$F7,$08
* 
* cmdmasteratn
* 		call	GETCBYTE
	dc.b	$CD,$D1,$01
* 		ld	(MASTERATN),A
	dc.b	$32,$CF,$15
* 		jp	loop
	dc.b	$C3,$F7,$08
* 
* *
* *  STARTSEQ - starts a multi channel sequence. a free CCB is allocated for each channel
* *    in the sequence.
* *
* *	parameters		A	sequence number
* *
* *	trashes		everything!
* *
* 
* *stseqx		ds.b	33			* 33 byte scratch area for starting a sequence
* 
* stseqx		db	0,0,0,0,0,0,0,0		* 33 byte scratch area for starting a sequence
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* 		db	0,0,0,0,0,0,0,0
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* 		db	0,0,0,0,0,0,0,0
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* 		db	0,0,0,0,0,0,0,0
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* 		db	0
	dc.b	$00
* 
* stseqsnum	db	0
	dc.b	$00
* 
* STARTSEQ
* 		ld	D,0
	dc.b	$16,$00
* 		ld	(stseqsnum),A
	dc.b	$32,$DE,$0B
* 		ld	E,A
	dc.b	$5F
* 		sla	E			* DE <- snum * 2
	dc.b	$CB,$23
* 		ld	HL,(STBL68K)
	dc.b	$2A,$AB,$0A
* 		ld	A,(STBL68K+2)		* AHL <- pointer to seq table in 68k space
	dc.b	$3A,$AD,$0A
* 		zadd	HL,DE
	dc.b	$19
* 		adc	A,0			* AHL <- pointer to this seq's offset
	dc.b	$CE,$00
* 		ld	C,2			* read 2 byte offset, into...
	dc.b	$0E,$02
* 		ld	DE,stseqx		* scratch
	dc.b	$11,$BD,$0B
* 		call	XFER68K
	dc.b	$CD,$F9,$01
* 
* 		ld	DE,(stseqx)		* DE <- the offset
	dc.b	$ED,$5B,$BD,$0B
* 		ld	HL,(STBL68K)
	dc.b	$2A,$AB,$0A
* 		ld	A,(STBL68K+2)
	dc.b	$3A,$AD,$0A
* 		zadd	HL,DE
	dc.b	$19
* 		adc	A,0			* AHL <- pointer to seq hdr data
	dc.b	$CE,$00
* 		ld	C,33			* xfer the max 33 byte seq hdr into
	dc.b	$0E,$21
* 		ld	DE,stseqx		* scratch
	dc.b	$11,$BD,$0B
* 		call	XFER68K
	dc.b	$CD,$F9,$01
* 
* *** this should probably be something different!
* 
* 		ld	A,(stseqx)
	dc.b	$3A,$BD,$0B
* 		zor	A
	dc.b	$B7
* 		ret	Z			* return if empty sequence
	dc.b	$C8
* 
* 		ld	IX,CCB			* start with CCB 0
	dc.b	$DD,$21,$80,$1B
* 		ld	IY,PBTBL
	dc.b	$FD,$21,$76,$0F
* 		ld	DE,32
	dc.b	$11,$20,$00
* 		ld	C,0			* C <- channel count
	dc.b	$0E,$00
* 		ld	HL,stseqx+1		* track pointers start at stseqx+1
	dc.b	$21,$BE,$0B
* 		ld	B,16			* only 16 CCB's to try
	dc.b	$06,$10
* chkstseqloop
* 		ld	A,(IX+CCBFLAGS)
	dc.b	$DD,$7E,$06
* 		zand	21H			* check in use and locked flags
	dc.b	$E6,$21
* 		jr	NZ,stseqskipccb		* if either set, skip ch
	dc.b	$20,$6B
* 		ld	(IX+CCBFLAGS),11H	* yes - set enable and running bits
	dc.b	$DD,$36,$06,$11
* 
* 		ld	A,(STBL68K)		* addr of this track is 24 bit base pointer
	dc.b	$3A,$AB,$0A
* 		zadd	A,(HL)			* plus 16 bit offset in descriptor
	dc.b	$86
* 		inc	HL
	dc.b	$23
* 		ld	(IX+CCBADDRL),A
	dc.b	$DD,$77,$03
* 
* 		ld	A,(STBL68K+1)
	dc.b	$3A,$AC,$0A
* 		adc	A,(HL)
	dc.b	$8E
* 		inc	HL
	dc.b	$23
* 		ld	(IX+CCBADDRM),A
	dc.b	$DD,$77,$04
* 
* 		ld	A,(STBL68K+2)
	dc.b	$3A,$AD,$0A
* 		adc	A,0
	dc.b	$CE,$00
* 		ld	(IX+CCBADDRH),A
	dc.b	$DD,$77,$05
* 
* 		ld	(IX+CCBTAGL),0FFH	* invalidate tags
	dc.b	$DD,$36,$00,$FF
* 		ld	(IX+CCBTAGM),0FFH
	dc.b	$DD,$36,$01,$FF
* 		ld	(IX+CCBTAGH),0FFH
	dc.b	$DD,$36,$02,$FF
* 		ld	(IX+CCBTIMERL),0FFH
	dc.b	$DD,$36,$07,$FF
* 		ld	(IX+CCBTIMERH),0FFH	* set timer to -1 to trigger sequencer next tick
	dc.b	$DD,$36,$08,$FF
* 		ld	A,(stseqsnum)
	dc.b	$3A,$DE,$0B
* 		ld	(IX+CCBSNUM),A		* save sequence number
	dc.b	$DD,$77,$0E
* 		ld	(IX+CCBVCHAN),C		* save virtual channel number
	dc.b	$DD,$71,$0F
* 		ld	(IX+CCBLOOP0),0		* clear loop stack
	dc.b	$DD,$36,$10,$00
* 		ld	(IX+CCBLOOP1),0
	dc.b	$DD,$36,$13,$00
* 		ld	(IX+CCBLOOP2),0
	dc.b	$DD,$36,$16,$00
* 		ld	(IX+CCBLOOP3),0
	dc.b	$DD,$36,$19,$00
* 		ld	(IX+CCBENV),0		* clear envelope
	dc.b	$DD,$36,$1D,$00
* 		ld	(IX+CCBPRIO),0
	dc.b	$DD,$36,$1C,$00
* 		ld	(IX+CCBATN),0		* clear channel attenuation
	dc.b	$DD,$36,$1E,$00
* 		ld	(IY+PBEBL),0		* clear pitchbend, envelope bend
	dc.b	$FD,$36,$20,$00
* 		ld	(IY+PBEBH),0
	dc.b	$FD,$36,$30,$00
* 		ld	(IY+PBPBL),0
	dc.b	$FD,$36,$00,$00
* 		ld	(IY+PBPBH),0
	dc.b	$FD,$36,$10,$00
* 		inc	C
	dc.b	$0C
* 		ld	A,(stseqx)
	dc.b	$3A,$BD,$0B
* 		cp	C
	dc.b	$B9
* 		ret	Z			* return if all tracks started
	dc.b	$C8
* stseqskipccb
* 		dec	B
	dc.b	$05
* 		ret	Z			* return if out of CCB's
	dc.b	$C8
* 		zadd	IX,DE
	dc.b	$DD,$19
* 		inc	IY
	dc.b	$FD,$23
* 		jr	chkstseqloop
	dc.b	$18,$86
* 
* *
* *  STOPSEQ - stops a multi channel sequence (actually, all occurances of it)
* *
* *	parameters		A	sequence number
* *
* *	trashes		everything!
* *
* 
* STOPSEQ
* 		ld	IX,CCB			* start with CCB 0
	dc.b	$DD,$21,$80,$1B
* 		ld	DE,32
	dc.b	$11,$20,$00
* 		ld	B,16			* only 16 CCB's to try
	dc.b	$06,$10
* stopseqloop
* 		bit	0,(IX+CCBFLAGS)		* is this channel in use?
	dc.b	$DD,$CB,$06,$46
* 		jr	Z,stopseqskip		* no - skip it
	dc.b	$28,$1B
* 		bit	5,(IX+CCBFLAGS)		* is this channel in locked?
	dc.b	$DD,$CB,$06,$6E
* 		jr	NZ,stopseqskip		* yes - skip it
	dc.b	$20,$15
* 		cp	255			* stop song 255 means stop all
	dc.b	$FE,$FF
* 		jr	Z,stopseqstopit
	dc.b	$28,$05
* 		cp	(IX+CCBSNUM)		* yes - is it for this seq number?
	dc.b	$DD,$BE,$0E
* 		jr	NZ,stopseqskip
	dc.b	$20,$0C
* stopseqstopit
* 		ld	(IX+CCBFLAGS),0		* yes - make it free, no retrig, no sustain
	dc.b	$DD,$36,$06,$00
* 		ld	(IX+CCBDURL),0		* clear duration to enable live play
	dc.b	$DD,$36,$0B,$00
* 		ld	(IX+CCBDURH),0
	dc.b	$DD,$36,$0C,$00
* stopseqskip
* 		zadd	IX,DE
	dc.b	$DD,$19
* 		dec	B
	dc.b	$05
* 		jr	NZ,stopseqloop
	dc.b	$20,$DA
* 		call	CLIPALL
	dc.b	$CD,$F9,$0C
* 		ret
	dc.b	$C9
* 
* *
* *  PAUSESEQ - pause a multi channel sequence (actually, all occurances of it)
* *
* *	parameters		A	sequence number
* *
* *	trashes		everything!
* *
* 
* PAUSESEQ
* 		ld	IX,CCB			* start with CCB 0
	dc.b	$DD,$21,$80,$1B
* 		ld	DE,32
	dc.b	$11,$20,$00
* 		ld	B,16			* only 16 CCB's to try
	dc.b	$06,$10
* pauseseqloop
* 		bit	0,(IX+CCBFLAGS)		* is this channel in use?
	dc.b	$DD,$CB,$06,$46
* 		jr	Z,pauseseqskip		* no - skip it
	dc.b	$28,$0F
* 		bit	5,(IX+CCBFLAGS)		* is this channel in locked?
	dc.b	$DD,$CB,$06,$6E
* 		jr	NZ,pauseseqskip		* yes - skip it
	dc.b	$20,$09
* 		cp	(IX+CCBSNUM)		* yes - is it for this seq number?
	dc.b	$DD,$BE,$0E
* 		jr	NZ,pauseseqskip
	dc.b	$20,$04
* 		res	4,(IX+CCBFLAGS)		* shut off running flags
	dc.b	$DD,$CB,$06,$A6
* pauseseqskip
* 		zadd	IX,DE
	dc.b	$DD,$19
* 		dec	B
	dc.b	$05
* 		jr	NZ,pauseseqloop
	dc.b	$20,$E6
* 		call	CLIPALL
	dc.b	$CD,$F9,$0C
* 		ret
	dc.b	$C9
* 
* *
* *  CLIPALL - called by STOPALL and PAUSEALL - cancels all envelopes, voices
* *
* *	scans voice tables, clipping off notes from inactive (not running channels)
* *
* 
* CLIPVNUM	db	0
	dc.b	$00
* 
* CLIPALL
* 		ld	IX,FMVTBL		* do fm voices
	dc.b	$DD,$21,$91,$17
* 		ld	E,0
	dc.b	$1E,$00
* 		call	CLIPLOOP
	dc.b	$CD,$42,$0D
* 		ld	IX,PSGVTBL
	dc.b	$DD,$21,$BC,$17
* 		ld	E,1
	dc.b	$1E,$01
* 		call	CLIPLOOP
	dc.b	$CD,$42,$0D
* 		ld	IX,PSGVTBLNG
	dc.b	$DD,$21,$D2,$17
* 		ld	E,1
	dc.b	$1E,$01
* 		call	CLIPLOOP
	dc.b	$CD,$42,$0D
* 
* 		ld	IY,ECB-1		* now clip envelopes
	dc.b	$FD,$21,$AA,$0E
* clipenvloop
* 		inc	IY
	dc.b	$FD,$23
* 		ld	A,(IY+ECBCHAN)
	dc.b	$FD,$7E,$00
* 		bit	7,A			* end of list?
	dc.b	$CB,$7F
* 		ret	NZ
	dc.b	$C0
* 		bit	6,A			* in use?
	dc.b	$CB,$77
* 		jr	NZ,clipenvloop
	dc.b	$20,$F4
* 		ld	B,0
	dc.b	$06,$00
* 		sla	A
	dc.b	$CB,$27
* 		sla	A
	dc.b	$CB,$27
* 		sla	A
	dc.b	$CB,$27
* 		sla	A
	dc.b	$CB,$27
* 		sla	A
	dc.b	$CB,$27
* 		ld	C,A
	dc.b	$4F
* 		rl	B
	dc.b	$CB,$10
* 		ld	HL,CCB+CCBFLAGS
	dc.b	$21,$86,$1B
* 		zadd	HL,BC
	dc.b	$09
* 		bit	4,(HL)			* running?
	dc.b	$CB,$66
* 		jp	NZ,clipenvloop		* yes - don't clip this env
	dc.b	$C2,$18,$0D
* 		zset	6,(IY+ECBCHAN)
	dc.b	$FD,$CB,$00,$F6
* 		jr	clipenvloop
	dc.b	$18,$D6
* 
* 
* * IX <- voice table, E <- 0 for fm, 1 for psg
* 
* CLIPLOOP
* 		ld	A,(IX+VTBLFLAGS)	* get vtbl entry
	dc.b	$DD,$7E,$00
* 		cp	0FFH
	dc.b	$FE,$FF
* 		ret	Z
	dc.b	$C8
* 
* 		ld	D,A			* save it
	dc.b	$57
* 
* 		ld	B,0
	dc.b	$06,$00
* 		ld	C,(IX+VTBLCH)		* see if this ccb is running
	dc.b	$DD,$4E,$03
* 		sla	C
	dc.b	$CB,$21
* 		sla	C
	dc.b	$CB,$21
* 		sla	C
	dc.b	$CB,$21
* 		sla	C
	dc.b	$CB,$21
* 		sla	C
	dc.b	$CB,$21
* 		rl	B
	dc.b	$CB,$10
* 		ld	HL,CCB+CCBFLAGS
	dc.b	$21,$86,$1B
* 		zadd	HL,BC
	dc.b	$09
* 		bit	4,(HL)			* running?
	dc.b	$CB,$66
* 		jp	NZ,clipnxt		* yes - don't clip
	dc.b	$C2,$04,$0E
* 
* 		ld	A,D
	dc.b	$7A
* 		zand	7			* get voice num
	dc.b	$E6,$07
* 		zor	80H			* add free flag
	dc.b	$F6,$80
* 		ld	(IX+VTBLFLAGS),A	* update table
	dc.b	$DD,$77,$00
* 		ld	(IX+VTBLDL),0		* clear release and duration timers
	dc.b	$DD,$36,$04,$00
* 		ld	(IX+VTBLDH),0
	dc.b	$DD,$36,$05,$00
* 		ld	(IX+VTBLRT),0
	dc.b	$DD,$36,$06,$00
* 
* 		zand	7			* get voice num back
	dc.b	$E6,$07
* 		ld	(CLIPVNUM),A
	dc.b	$32,$F8,$0C
* 		bit	0,E			* fm or psg?
	dc.b	$CB,$43
* 		jp	NZ,clippsg
	dc.b	$C2,$0C,$0E
* 
* 		bit	5,D			* fm - digital mode?
	dc.b	$CB,$6A
* 		jr	Z,clipfm
	dc.b	$28,$13
* clipdig
* 		ld	A,0C9H			* opcode "ret"
	dc.b	$3E,$C9
* 		ld	(DACME),A		* disable DACME routine
	dc.b	$32,$B7,$02
* 		ld	(FILLDACFIFO),A		* disable FILLDACFIFO
	dc.b	$32,$02,$03
* 		ld	HL,4000H		* disable DAC mode
	dc.b	$21,$00,$40
* 		ld	(HL),02BH
	dc.b	$36,$2B
* 		inc	HL
	dc.b	$23
* 		ld	(HL),0
	dc.b	$36,$00
* 		jp	clipnxt
	dc.b	$C3,$04,$0E
* clipfm
* 		ld	D,0			* point to bank 0
	dc.b	$16,$00
* 		cp	3			* is voice in bank 1 ?
	dc.b	$FE,$03
* 		jr	C,clpafm0
	dc.b	$38,$04
* 		zsub	4			* yes, subtract 4 (map 4-6 >> 0-2)
	dc.b	$D6,$04
* 		ld	D,2			* point to bank 1
	dc.b	$16,$02
* clpafm0
* 		push	DE
	dc.b	$D5
* 		ld	E,A			* E <- channel within bank
	dc.b	$5F
* 		ld	H,40H
	dc.b	$26,$40
* 		FMWr	040H,7FH		* clamp all EGs
	dc.b	$2E,$00
	dc.b	$3E,$40
	dc.b	$83
	dc.b	$47
	dc.b	$0E,$7F
	dc.b	$3E,$80
	dc.b	$A6
	dc.b	$FA,$AF,$0D
	dc.b	$6A
	dc.b	$70
	dc.b	$2C
	dc.b	$71
* 		FMWr	044H,7FH
	dc.b	$2E,$00
	dc.b	$3E,$44
	dc.b	$83
	dc.b	$47
	dc.b	$0E,$7F
	dc.b	$3E,$80
	dc.b	$A6
	dc.b	$FA,$C1,$0D
	dc.b	$6A
	dc.b	$70
	dc.b	$2C
	dc.b	$71
* 		FMWr	048H,7FH
	dc.b	$2E,$00
	dc.b	$3E,$48
	dc.b	$83
	dc.b	$47
	dc.b	$0E,$7F
	dc.b	$3E,$80
	dc.b	$A6
	dc.b	$FA,$D3,$0D
	dc.b	$6A
	dc.b	$70
	dc.b	$2C
	dc.b	$71
* 		FMWr	04CH,7FH
	dc.b	$2E,$00
	dc.b	$3E,$4C
	dc.b	$83
	dc.b	$47
	dc.b	$0E,$7F
	dc.b	$3E,$80
	dc.b	$A6
	dc.b	$FA,$E5,$0D
	dc.b	$6A
	dc.b	$70
	dc.b	$2C
	dc.b	$71
* 		pop	DE
	dc.b	$D1
* 
* 		ld	A,(CLIPVNUM)
	dc.b	$3A,$F8,$0C
* 		ld	IY,4000H
	dc.b	$FD,$21,$00,$40
* 		FMWrite 28H,A           	* key off
	dc.b	$7F
	dc.b	$FD,$CB,$00,$7E
	dc.b	$20,$FA
	dc.b	$FD,$36,$00,$28
	dc.b	$FD,$77,$01
* clipnxt
* 		ld	BC,7
	dc.b	$01,$07,$00
* 		zadd	IX,BC
	dc.b	$DD,$09
* 		jp	CLIPLOOP
	dc.b	$C3,$42,$0D
* clippsg
* 		ld      IY,psgcom		* load psg register table
	dc.b	$FD,$21,$09,$00
* 		ld      C,A			* BC <- 0A
	dc.b	$4F
* 		ld      B,0
	dc.b	$06,$00
* 		zadd	IY,BC			* point to correct register
	dc.b	$FD,$09
* 		ld      (IY+COM),4		* set stop command
	dc.b	$FD,$36,$00,$04
* 		jr	clipnxt
	dc.b	$18,$E9
* 
* 
* *
* *  SETTEMPO - sets the (1/24 beat) / (1/60 sec) ratio in SBPT (Sub Beat Per Tick)
* *	SBPT is 16 bits, 8 of em fractional
* *
* *	parameters:		A	beats per minute
* *
* *	trashes:		DE,HL
* *
* 
* SETTEMPO
* 		ld	DE,218
	dc.b	$11,$DA,$00
* 		call	MULTIPLY
	dc.b	$CD,$59,$11
* 
* 		zxor	A
	dc.b	$AF
* 		sla	L
	dc.b	$CB,$25
* 		rl	H
	dc.b	$CB,$14
* 		rla				* AH <- sbpt, 8 fracs
	dc.b	$17
* 		ld	L,H
	dc.b	$6C
* 		ld	H,A			* HL <- AH
	dc.b	$67
* 		ld	(SBPT),HL
	dc.b	$22,$BE,$08
* 		ret
	dc.b	$C9
* 
* *
* *  TRIGENV - initialize an envelope
* *
* *	parameters:		C	envelope number
* *				E	midi channel
* *				IX	pointer to CCB
* *
* *	trashes:		everything
* *
* 
* TRIGENV
* 		ld	B,(IX+CCBFLAGS)		* save channel's flags (for sfx tempo flag) in B
	dc.b	$DD,$46,$06
* 		ld	D,0
	dc.b	$16,$00
* 		ld	IY,PBTBL
	dc.b	$FD,$21,$76,$0F
* 		zadd	IY,DE
	dc.b	$FD,$19
* 		ld	IX,ECB			* point at the envelope control blocks
	dc.b	$DD,$21,$AB,$0E
* retrigloop
* 		ld	A,(IX+ECBCHAN)		* first see if an ECB already exists for this channel
	dc.b	$DD,$7E,$00
* 		bit	7,A			* end of list?
	dc.b	$CB,$7F
* 		jr	NZ,tryfree
	dc.b	$20,$07
* 		cp	E
	dc.b	$BB
* 		jr	Z,trigger
	dc.b	$28,$16
* 		inc	IX
	dc.b	$DD,$23
* 		jr	retrigloop
	dc.b	$18,$F2
* tryfree
* 		ld	IX,ECB
	dc.b	$DD,$21,$AB,$0E
* trigloop					* then try to find a free ECB
* 		ld	A,(IX+ECBCHAN)		* A <- channel number and flags
	dc.b	$DD,$7E,$00
* 		bit	7,A			* end of list?
	dc.b	$CB,$7F
* 		ret	NZ			* yup - return
	dc.b	$C0
* 		bit	6,A			* active ?
	dc.b	$CB,$77
* 		jr	NZ,trigger		* nope - go allocate
	dc.b	$20,$04
* 		inc	IX
	dc.b	$DD,$23
* 		jr	trigloop
	dc.b	$18,$F2
* trigger						* tigger envelope
* 		bit	3,B			* sfx flag set in CCB?
	dc.b	$CB,$58
* 		jr	Z,trigger1
	dc.b	$28,$02
* 		zset	5,E			* yes - set sfx flag in ECB
	dc.b	$CB,$EB
* trigger1
* 		ld	(IX+ECBCHAN),E		* set channel
	dc.b	$DD,$73,$00
* 		ld	(IX+ECBCTR),0		* clear counter to trigger segment update
	dc.b	$DD,$36,$0D,$00
* 
* 		ld	B,0
	dc.b	$06,$00
* 		sla	C			* BC <- 2 * envelope #
	dc.b	$CB,$21
* 		ld	HL,(ETBL68K)
	dc.b	$2A,$A8,$0A
* 		ld	A,(ETBL68K+2)		* AHL <- pointer to env table in 68k space
	dc.b	$3A,$AA,$0A
* 		zadd	HL,BC
	dc.b	$09
* 		adc	A,0			* AHL <- pointer to this env's offset
	dc.b	$CE,$00
* 		ld	C,2			* read 2 byte offset, into...
	dc.b	$0E,$02
* 		ld	DE,fpoffset		* local fpoffset (shared w/ fetchpatch)
	dc.b	$11,$26,$17
* 		call	XFER68K
	dc.b	$CD,$F9,$01
* 
* 		ld	DE,(fpoffset)		* DE <- the offset
	dc.b	$ED,$5B,$26,$17
* 		ld	HL,(ETBL68K)
	dc.b	$2A,$A8,$0A
* 		ld	A,(ETBL68K+2)
	dc.b	$3A,$AA,$0A
* 		zadd	HL,DE
	dc.b	$19
* 		adc	A,0			* AHL <- pointer to env data
	dc.b	$CE,$00
* 		ld	C,32			* xfer the 32 byte env into
	dc.b	$0E,$20
* 		ld	D,01EH
	dc.b	$16,$1E
* 		ld	E,(IX+ECBBUFP)		* this ECB's envelope buffer
	dc.b	$DD,$5E,$19
* 		call	XFER68K
	dc.b	$CD,$F9,$01
* 
* 		ld	D,01EH
	dc.b	$16,$1E
* 		ld	E,(IX+ECBBUFP)		* DE <- ptr to this ECB's envelope buffer
	dc.b	$DD,$5E,$19
* 
* 		ld	A,(DE)			* initialize envelope bend value
	dc.b	$1A
* 		ld	(IY+PBEBL),A
	dc.b	$FD,$77,$20
* 		inc	DE
	dc.b	$13
* 		ld	A,(DE)
	dc.b	$1A
* 		ld	(IY+PBEBH),A
	dc.b	$FD,$77,$30
* 		inc	DE
	dc.b	$13
* 
* 		ld	(IX+ECBPTRL),E		* point ECB at envelope after initial value
	dc.b	$DD,$73,$05
* 		ld	(IX+ECBPTRH),D
	dc.b	$DD,$72,$09
* 
* 		ret
	dc.b	$C9
* 
* *
* *  DOENVELOPE - update the pitch envelope processor
* *
* *		trashes:	everything
* *
* 
* 		export	ECB
* 
* ECB		db	040H,040H,040H,040H	* 4 envelopes worth of control blocks (ECB's)
	dc.b	$40
	dc.b	$40
	dc.b	$40
	dc.b	$40
* 		db	0FFH
	dc.b	$FF
* 		db	0,0,0,0
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* 		db	0,0,0,0
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* 		db	0,0,0,0
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* 		db	0,0,0,0
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* 		db	0,0,0,0
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* 		db	80H,0A0H,0C0H,0E0H
	dc.b	$80
	dc.b	$A0
	dc.b	$C0
	dc.b	$E0
* 
* ECBCHAN		equ	0			* offset to 4 envelopes' channel numbers and flags
* 						* [7]=eot, [6]=free, [5]=sfx tempo
* ECBPTRL		equ	5			*	"		 segment ptr LSBs
* ECBPTRH		equ	9			*	"		 segment ptr MSBs
* ECBCTR		equ	13			* 	"		 segment ctrs
* ECBDELL		equ	17			*	"		 segment delta LSBs
* ECBDELH		equ	21			*	"		 segment delta MSBs
* ECBBUFP		equ	25			* LSB of pointer to 32 byte envelope buffer
* 
* DOENVELOPE
* 		ld	IX,ECB			* point at the envelope control blocks
	dc.b	$DD,$21,$AB,$0E
* envloop
* 	call	DACME
	dc.b	$CD,$B7,$02
* 		ld	C,(IX+ECBCHAN)		* C <- channel number and flags
	dc.b	$DD,$4E,$00
* 		bit	7,C			* end of list?
	dc.b	$CB,$79
* 		ret	NZ			* yup - return
	dc.b	$C0
* 		bit	6,C			* active ?
	dc.b	$CB,$71
* 		jr	Z,envactive
	dc.b	$28,$04
* envnext						* nope - loop
* 		inc	IX
	dc.b	$DD,$23
* 		jr	envloop
	dc.b	$18,$EF
* envactive					* check if this envelope's timebase has ticked
* 		ld	A,(TBASEFLAGS)
	dc.b	$3A,$C2,$08
* 		bit	5,C			* sfx timebase?
	dc.b	$CB,$69
* 		jr	NZ,envsfx
	dc.b	$20,$06
* 		bit	1,A			* no - check music tick flag
	dc.b	$CB,$4F
* 		jr	NZ,envticked
	dc.b	$20,$06
* 		jr	envnext
	dc.b	$18,$EF
* envsfx
* 		bit	0,A			* yes - check sfx tick flag
	dc.b	$CB,$47
* 		jr	Z,envnext
	dc.b	$28,$EB
* envticked
* 		ld	A,(IX+ECBCTR)
	dc.b	$DD,$7E,$0D
* 		zsub	1			* ctr at 0?
	dc.b	$D6,$01
* 		jr	NC,envseg		* no - process segment
	dc.b	$30,$1F
* envnextseg
* 		ld	L,(IX+ECBPTRL)		* yes -
	dc.b	$DD,$6E,$05
* 		ld	H,(IX+ECBPTRH)		* HL <- ptr to segment data
	dc.b	$DD,$66,$09
* 		ld	A,(HL)			* A <- counter value for next segment
	dc.b	$7E
* 		zsub	1
	dc.b	$D6,$01
* 		jr	C, envdone
	dc.b	$38,$3E
* 		inc	HL
	dc.b	$23
* 		ld	B,(HL)
	dc.b	$46
* 		ld	(IX+ECBDELL),B
	dc.b	$DD,$70,$11
* 		inc	HL
	dc.b	$23
* 		ld	B,(HL)
	dc.b	$46
* 		ld	(IX+ECBDELH),B		* ECB's delta <- this segment's delta
	dc.b	$DD,$70,$15
* 		inc	HL
	dc.b	$23
* 	call	DACME
	dc.b	$CD,$B7,$02
* 		ld	(IX+ECBPTRL),L		* ECB's segment ptr <- ptr to next segment
	dc.b	$DD,$75,$05
* 		ld	(IX+ECBPTRH),H
	dc.b	$DD,$74,$09
* envseg						* process segment
* 		ld	IY,PBTBL
	dc.b	$FD,$21,$76,$0F
* 		ld	B,0
	dc.b	$06,$00
* 		res	5,C
	dc.b	$CB,$A9
* 		zadd	IY,BC			* IY <- ptr to this channel's pitchbend entries
	dc.b	$FD,$09
* 		ld	(IX+ECBCTR),A		* save ECB's counter
	dc.b	$DD,$77,$0D
* 		ld	A,(IY+PBEBL)
	dc.b	$FD,$7E,$20
* 		zadd	A,(IX+ECBDELL)
	dc.b	$DD,$86,$11
* 		ld	(IY+PBEBL),A
	dc.b	$FD,$77,$20
* 		ld	A,(IY+PBEBH)
	dc.b	$FD,$7E,$30
* 		adc	A,(IX+ECBDELH)
	dc.b	$DD,$8E,$15
* 		ld	(IY+PBEBH),A		* this ch's envelope bend += this envelope's delta
	dc.b	$FD,$77,$30
* envneedupd
* 		zset	0,(IY+PBRETRIG)
	dc.b	$FD,$CB,$40,$C6
* 		ld	A,1
	dc.b	$3E,$01
* 		ld	(NEEDBEND),A
	dc.b	$32,$75,$0F
* 		jr	envnext
	dc.b	$18,$9B
* 
* envdone
* 		ld	IY,PBTBL
	dc.b	$FD,$21,$76,$0F
* 		ld	B,0
	dc.b	$06,$00
* 		res	5,C
	dc.b	$CB,$A9
* 		zadd	IY,BC			* IY <- ptr to this channel's pitchbend entries
	dc.b	$FD,$09
* 		ld	(IY+PBEBL),0		* zero the envelope bend on this channel
	dc.b	$FD,$36,$20,$00
* 		ld	(IY+PBEBH),0
	dc.b	$FD,$36,$30,$00
* 		ld	(IX+ECBCHAN),040H	* shut off this envelope
	dc.b	$DD,$36,$00,$40
* 		jr	envneedupd
	dc.b	$18,$DD
* 
* *
* *  DOPITCHBEND- updates the (pitchbend) value for the gems channel (= MIDI channel during perf
* *
* *	inputs:		A				CCB number (0-15)
* *			(next 2 bytes in cmd queue)	pbend value
* *
* 
* DOPITCHBEND
* 		ld	C,A
	dc.b	$4F
* 		ld	B,0
	dc.b	$06,$00
* 		ld	IX,PBTBL
	dc.b	$DD,$21,$76,$0F
* 		zadd	IX,BC			* IX <- ptr to this ch's bends
	dc.b	$DD,$09
* 		call	GETCBYTE		* get pitch bend in half steps (8 fracs) into
	dc.b	$CD,$D1,$01
* 		ld	(IX+PBPBL),A		* pitch bend for channel 0
	dc.b	$DD,$77,$00
* 		call	GETCBYTE
	dc.b	$CD,$D1,$01
* 		ld	(IX+PBPBH),A
	dc.b	$DD,$77,$10
* 		zset	0,(IX+PBRETRIG)
	dc.b	$DD,$CB,$40,$C6
* 		ld	A,1
	dc.b	$3E,$01
* 		ld	(NEEDBEND),A
	dc.b	$32,$75,$0F
* 		ret
	dc.b	$C9
* 
* *
* *  APPLYBEND - if NEEDBEND is set, apply the pitch and envelope bends to all channels,
* *	and reset NEEDBEND
* *
* *	trashes:	everything
* *
* 
* NEEDBEND	db	0			* set to 1 to trigger a need to bend
	dc.b	$00
* 
* PBTBL		db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0	* pitch bend LSB
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* 		db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0	* pitch bend MSB
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* 		db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0	* env bend LSB
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* 		db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0	* env bend MSB
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* 		db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0	* [0]=apply bend - set by pbend/mod,
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* 							* cleared by applybend
* 
* PBPBL		equ	0			* offset in PBTBL to 16 channels' pitchbend LSB
* PBPBH		equ	16			* offset in PBTBL to 16 channels' pitchbend MSB
* PBEBL		equ	32			* offset in PBTBL to 16 channels' envelopebend LSB
* PBEBH		equ	48			* offset in PBTBL to 16 channels' envelopebend MSB
* PBRETRIG	equ	64			* offset in PBTBL to 16 channels' retrigger flag
* 
* APPLYBEND
* 		ld	A,(NEEDBEND)		* return if no bend needed
	dc.b	$3A,$75,$0F
* 		zor	A
	dc.b	$B7
* 		ret	Z
	dc.b	$C8
* 		zxor	A
	dc.b	$AF
* 		ld	(NEEDBEND),A		* clear the flag and go for it
	dc.b	$32,$75,$0F
* 
* 		call	CHECKTICK
	dc.b	$CD,$41,$00
* 
* 		ld	IY,FMVTBL		* go through FM voice table
	dc.b	$FD,$21,$91,$17
* pbfmloop
* 		call	DACME
	dc.b	$CD,$B7,$02
* 		ld	A,(IY+0)
	dc.b	$FD,$7E,$00
* 		cp	0FFH			* eot?
	dc.b	$FE,$FF
* 		jr	Z,pbpsg			* yup - all done
	dc.b	$28,$63
* 		zand	7
	dc.b	$E6,$07
* 		ld	B,A			* B <- voice number
	dc.b	$47
* 		ld	C,(IY+2)		* C <- note number
	dc.b	$FD,$4E,$02
* 		ld	E,(IY+3)			* E <- channel number
	dc.b	$FD,$5E,$03
* 		ld	A,0			* indicate FM type voice
	dc.b	$3E,$00
* 
* *FOR TESTING ONLY
* *		jr	pbfmskip
* 
* 		ld	IX,PBTBL
	dc.b	$DD,$21,$76,$0F
* 		ld	D,0
	dc.b	$16,$00
* 		zadd	IX,DE			* IX <- ptr to pitch/envelope bend for this ch
	dc.b	$DD,$19
* 		bit	0,(IX+PBRETRIG)		* check for change in bend on this channel
	dc.b	$DD,$CB,$40,$46
* 		jr	Z,pbfmskip
	dc.b	$28,$43
* 
* 		call	GETFREQ			* get the new freq num for this voice
	dc.b	$CD,$A8,$10
* 		ld	(noteonffreq),DE	* save freq number
	dc.b	$ED,$53,$2D,$14
* 
* 		ld	D,0			* indicates bank 0 to FMWr
	dc.b	$16,$00
* 		ld	A,B
	dc.b	$78
* 		cp	3			* is voice in bank 1 ?
	dc.b	$FE,$03
* 		jr	C,pbfmbank0
	dc.b	$38,$04
* 		zsub	4			* yes, subtract 4 (map 4-6 >> 0-2)
	dc.b	$D6,$04
* 		ld	D,2			* indicates bank 1 to FMWr
	dc.b	$16,$02
* pbfmbank0
* 		ld	E,A			* E <- channel within bank
	dc.b	$5F
* 		ld	H,40H
	dc.b	$26,$40
* 		push	IY
	dc.b	$FD,$E5
* 		ld	IY,noteonffreq		* IY <- ptr to freq number from GETFREQ
	dc.b	$FD,$21,$2D,$14
* 		FMWr	0A4H,(IY+1)		* set frequency msb
	dc.b	$2E,$00
	dc.b	$3E,$A4
	dc.b	$83
	dc.b	$47
	dc.b	$FD,$4E,$01
	dc.b	$3E,$80
	dc.b	$A6
	dc.b	$FA,$1E,$10
	dc.b	$6A
	dc.b	$70
	dc.b	$2C
	dc.b	$71
* 		FMWr	0A0H,(IY+0)		* set frequency lsb
	dc.b	$2E,$00
	dc.b	$3E,$A0
	dc.b	$83
	dc.b	$47
	dc.b	$FD,$4E,$00
	dc.b	$3E,$80
	dc.b	$A6
	dc.b	$FA,$31,$10
	dc.b	$6A
	dc.b	$70
	dc.b	$2C
	dc.b	$71
* 		pop	IY
	dc.b	$FD,$E1
* 
* pbfmskip
* 		ld	DE,7
	dc.b	$11,$07,$00
* 		zadd	IY,DE
	dc.b	$FD,$19
* 		jr	pbfmloop
	dc.b	$18,$93
* 
* * New Register Usage ^^^
* *   H <- 40H (MSB of FM chip register address)
* *   D <- 0 for bank 0 (channels 0,1,2) or 2 for bank 1 (channels 3,4,5)
* *   E <- channel within bank (0-2)
* * FMWrch uses these plus A,B,C,L
* *
* 
* pbpsg
* 		ld	IY,PSGVTBL		* go through PSG voice table
	dc.b	$FD,$21,$BC,$17
* pbpsgloop
* 		call	DACME
	dc.b	$CD,$B7,$02
* 		ld	A,(IY+0)
	dc.b	$FD,$7E,$00
* 		cp	0FFH			* eot?
	dc.b	$FE,$FF
* 		jr	Z,pbdone		* yup - all done
	dc.b	$28,$49
* 		zand	7
	dc.b	$E6,$07
* 		ld	B,A			* B <- voice number
	dc.b	$47
* 		ld	C,(IY+2)			* C <- note number
	dc.b	$FD,$4E,$02
* 		ld	E,(IY+3)			* DE <- channel number
	dc.b	$FD,$5E,$03
* 		ld	A,1			* flag psg type voice
	dc.b	$3E,$01
* 
* *FOR TESTING ONLY
* *		jr	pbpsgskip
* 
* 		ld	IX,PBTBL
	dc.b	$DD,$21,$76,$0F
* 		ld	D,0
	dc.b	$16,$00
* 		zadd	IX,DE			* IX <- ptr to pitch/envelope bend for this ch
	dc.b	$DD,$19
* 		bit	0,(IX+PBRETRIG)		* check for change in bend on this channel
	dc.b	$DD,$CB,$40,$46
* 		jr	Z,pbpsgskip
	dc.b	$28,$29
* 
* 		call	GETFREQ			* get the new freq num for this voice
	dc.b	$CD,$A8,$10
* 
* 		call	DACME
	dc.b	$CD,$B7,$02
* 
* 		rrc	B
	dc.b	$CB,$08
* 		rrc	B
	dc.b	$CB,$08
* 		rrc	B
	dc.b	$CB,$08
* 		ld	A,E
	dc.b	$7B
* 		zand	0FH
	dc.b	$E6,$0F
* 		zor	80H
	dc.b	$F6,$80
* 		zor	B
	dc.b	$B0
* 
* 		ld	(07F11H),A
	dc.b	$32,$11,$7F
* 		srl	D
	dc.b	$CB,$3A
* 		rr	E
	dc.b	$CB,$1B
* 		srl	D
	dc.b	$CB,$3A
* 		rr	E
	dc.b	$CB,$1B
* 		srl	D
	dc.b	$CB,$3A
* 		rr	E
	dc.b	$CB,$1B
* 		srl	D
	dc.b	$CB,$3A
* 		rr	E
	dc.b	$CB,$1B
* 		ld	A,E
	dc.b	$7B
* 		ld      (07F11H),A		* write tone msb
	dc.b	$32,$11,$7F
* pbpsgskip
* 		ld	DE,7
	dc.b	$11,$07,$00
* 		zadd	IY,DE
	dc.b	$FD,$19
* 		jr	pbpsgloop
	dc.b	$18,$AD
* 
* pbdone
* 		ld	HL,PBTBL+PBRETRIG
	dc.b	$21,$B6,$0F
* 		ld	A,16
	dc.b	$3E,$10
* pbdoneloop
* 		ld	(HL),0
	dc.b	$36,$00
* 		inc	HL
	dc.b	$23
* 		dec	A
	dc.b	$3D
* 		jr	NZ,pbdoneloop
	dc.b	$20,$FA
* 
* 		ret
	dc.b	$C9
* 
* *  GETFREQ - gets a frequency (for FM) or wavelength (for PSG) value from a note
* *	number and a channel # (for adding pitch and envelope bends)
* *
* *	parameters:	A	0 for FM, 1 for PSG
* *			C	note (0=C0, 95=B7)
* *			E	channel
* *			IX	pointer to this channel's PBTBL entry
* 
* *	returns:	DE	freq or wavelength value
* *
* *	trashs:		A,IX
* 
* gfpbend		dw	0			* local pitch bend
	dc.b	$00
	dc.b	$00
* 
* GETFREQ
* 		push	BC
	dc.b	$C5
* 		push	HL
	dc.b	$E5
* 
* 		call	DACME
	dc.b	$CD,$B7,$02
* 
* 		ld	B,A			* B <- voice type
	dc.b	$47
* 
* 		ld	A,(IX+PBPBL)
	dc.b	$DD,$7E,$00
* 		zadd	A,(IX+PBEBL)
	dc.b	$DD,$86,$20
* 		ld	E,A
	dc.b	$5F
* 		ld	A,(IX+PBPBH)
	dc.b	$DD,$7E,$10
* 		adc	A,(IX+PBEBH)
	dc.b	$DD,$8E,$30
* 		ld	D,A			* DE <- pitchbend(IX) + envelopebend(IX)
	dc.b	$57
* 		ld	(gfpbend),DE		* save pitch bend
	dc.b	$ED,$53,$A6,$10
* 
* 		call	DACME
	dc.b	$CD,$B7,$02
* 
* 		ld	A,C
	dc.b	$79
* 		zadd	A,D			* A <- semitone + semitone portion of bend
	dc.b	$82
* 		cp	96			* is it outside 0..95?
	dc.b	$FE,$60
* 		jr	C,gflookup		* no - go to lookup
	dc.b	$38,$12
* 		bit	7,D			* yes - was bend up or down?
	dc.b	$CB,$7A
* 		jr	Z,gftoohi
	dc.b	$28,$07
* 		ld	A,0			* down - peg at 0 (C0)
	dc.b	$3E,$00
* 		ld	(gfpbend),A
	dc.b	$32,$A6,$10
* 		jr	gflookup
	dc.b	$18,$07
* gftoohi
* 		ld	A,0FFH
	dc.b	$3E,$FF
* 		ld	(gfpbend),A
	dc.b	$32,$A6,$10
* 		ld	A,95			* up - peg at 95 (B7) and max frac pbend
	dc.b	$3E,$5F
* gflookup
* 		call	DACME
	dc.b	$CD,$B7,$02
* 		bit	0,B			* voice type ? (dictates lookup method)
	dc.b	$CB,$40
* 		jr	NZ,gflupsg
	dc.b	$20,$20
* gfllufm						* fm style lookup
* 		ld	C,0			* C <- A / 12* A <- A % 12
	dc.b	$0E,$00
* 		cp	48
	dc.b	$FE,$30
* 		jr	C,nobit2
	dc.b	$38,$04
* 		zsub	48
	dc.b	$D6,$30
* 		zset	2,C
	dc.b	$CB,$D1
* nobit2		cp	24
	dc.b	$FE,$18
* 		jr	C,nobit1
	dc.b	$38,$04
* 		zsub	24
	dc.b	$D6,$18
* 		zset	1,C
	dc.b	$CB,$C9
* nobit1		cp	12
	dc.b	$FE,$0C
* 		jr	C,nobit0
	dc.b	$38,$04
* 		zsub	12
	dc.b	$D6,$0C
* 		zset	0,C
	dc.b	$CB,$C1
* nobit0
* 		ld	IX,fmftbl
	dc.b	$DD,$21,$68,$11
* 		jr	gfinterp
	dc.b	$18,$0D
* gflupsg						* psg style lookup
* 		zsub	33			* lowest note for PSG is A2
	dc.b	$D6,$21
* 		jr	NC,gflupsg1
	dc.b	$30,$05
* 		ld	A,0
	dc.b	$3E,$00
* 		ld	(gfpbend),A
	dc.b	$32,$A6,$10
* gflupsg1
* 		ld	IX,psgftbl
	dc.b	$DD,$21,$82,$11
* gfinterp					* interpolate up from value at (IX) by (gfpbend)
* 		rlca
	dc.b	$07
* 		ld	E,A			* DE <- 2 * A
	dc.b	$5F
* 		ld	D,0
	dc.b	$16,$00
* 		zadd	IX,DE			* (IX) <- ptr in appropriate table (clears carry)
	dc.b	$DD,$19
* 
* 		call	DACME
	dc.b	$CD,$B7,$02
* 
* 		ld	A,(IX+2)
	dc.b	$DD,$7E,$02
* 		zsub	(IX+0)
	dc.b	$DD,$96,$00
* 		ld	E,A
	dc.b	$5F
* 		ld	A,(IX+3)
	dc.b	$DD,$7E,$03
* 		sbc	A,(IX+1)
	dc.b	$DD,$9E,$01
* 		ld	D,A			* DE <- next table entry - this table entry
	dc.b	$57
* 
* 		ld	A,(gfpbend)		* A <- frac part of pitch bend
	dc.b	$3A,$A6,$10
* 		call	MULTIPLY		* HL <- (DE (table delta) * A (frac bend) ) * 256
	dc.b	$CD,$59,$11
* 
* 		call	DACME
	dc.b	$CD,$B7,$02
* 
* 		ld	L,0			* L <- 8 bits sign extention of H
	dc.b	$2E,$00
* 		bit	7,H
	dc.b	$CB,$7C
* 		jr	Z,gfnoextnd
	dc.b	$28,$02
* 		ld	L,0FFH
	dc.b	$2E,$FF
* gfnoextnd
* 		ld	A,(IX+0)
	dc.b	$DD,$7E,$00
* 		zadd	A,H
	dc.b	$84
* 		ld	E,A
	dc.b	$5F
* 		ld	A,(IX+1)
	dc.b	$DD,$7E,$01
* 		adc	A,L
	dc.b	$8D
* 		ld	D,A			* DE <- this entry + (delta * frac)
	dc.b	$57
* 
* 		bit	0,B			* voice type ?
	dc.b	$CB,$40
* 		jr	NZ,gfdone		* all done for PSG
	dc.b	$20,$06
* 
* 		ld	A,C			* for FM, put octave in F number 13:11
	dc.b	$79
* 		rlca
	dc.b	$07
* 		rlca
	dc.b	$07
* 		rlca
	dc.b	$07
* 		zor	D
	dc.b	$B2
* 		ld	D,A
	dc.b	$57
* gfdone
* 		pop	HL
	dc.b	$E1
* 		pop	BC
	dc.b	$C1
* 		call	DACME
	dc.b	$CD,$B7,$02
* 		ret
	dc.b	$C9
* 
* 
* *
* *  MULTIPLY - unsigned 8 x 16 multiply: HL <- A * DE
* *	MULADD entry point: for preloading HL with an offset
* *	GETPATPTR entry point: HL <- PATCHDATA + 39 * A
* 
* 
* GETPATPTR
* 		ld	HL,PATCHDATA
	dc.b	$21,$86,$18
* 		ld	DE,39
	dc.b	$11,$27,$00
* 		jr	MULADD
	dc.b	$18,$03
* MULTIPLY
* 		ld	HL,0
	dc.b	$21,$00,$00
* MULADD
* 		srl	A
	dc.b	$CB,$3F
* 		jr	NC,mulbitclr
	dc.b	$30,$01
* 		zadd	HL,DE
	dc.b	$19
* mulbitclr
* 		ret	Z
	dc.b	$C8
* 		sla	E			* if more bits still set in A, DE*=2 and loop
	dc.b	$CB,$23
* 		rl	D
	dc.b	$CB,$12
* 		jr	MULADD
	dc.b	$18,$F4
* 
* 
* *
* *  NOTEON - note on (key on)
* *
* *	parameters:	B		midi channel
* *			C		note number: 0..95 = C0..B7
* *			IX		pointer to this channel's CCB
* *			(CHPATPTR)	pointer to this channel's patch
* *
* *	trashes:	all registers
* *
* 
* * fmftbl contains a 16 bit freq number for each half step in a single octave (C-C)
* 
* fmftbl		dw	644,682,723,766,811,859,910,965,1022,1083,1147,1215,1288
	dc.b	$84
	dc.b	$02
	dc.b	$AA
	dc.b	$02
	dc.b	$D3
	dc.b	$02
	dc.b	$FE
	dc.b	$02
	dc.b	$2B
	dc.b	$03
	dc.b	$5B
	dc.b	$03
	dc.b	$8E
	dc.b	$03
	dc.b	$C5
	dc.b	$03
	dc.b	$FE
	dc.b	$03
	dc.b	$3B
	dc.b	$04
	dc.b	$7B
	dc.b	$04
	dc.b	$BF
	dc.b	$04
	dc.b	$08
	dc.b	$05
* 
* * psgftbl contains the 16 bit wavelength numbers for the notes A2 thru B7 (33-95)
* 
* psgftbl		dw	       03F9H, 03C0H, 038AH	* A2 > B2
	dc.b	$F9
	dc.b	$03
	dc.b	$C0
	dc.b	$03
	dc.b	$8A
	dc.b	$03
* 
* 		dw	0357H, 0327H, 02FAH, 02CFH	* C3 > B3
	dc.b	$57
	dc.b	$03
	dc.b	$27
	dc.b	$03
	dc.b	$FA
	dc.b	$02
	dc.b	$CF
	dc.b	$02
* 		dw	02A7H, 0281H, 025DH, 023BH
	dc.b	$A7
	dc.b	$02
	dc.b	$81
	dc.b	$02
	dc.b	$5D
	dc.b	$02
	dc.b	$3B
	dc.b	$02
* 		dw	021BH, 01FCH, 01E0H, 01C5H
	dc.b	$1B
	dc.b	$02
	dc.b	$FC
	dc.b	$01
	dc.b	$E0
	dc.b	$01
	dc.b	$C5
	dc.b	$01
* 
* 		dw	01ACH, 0194H, 017DH, 0168H	* C4 > B4
	dc.b	$AC
	dc.b	$01
	dc.b	$94
	dc.b	$01
	dc.b	$7D
	dc.b	$01
	dc.b	$68
	dc.b	$01
* 		dw	0153H, 0140H, 012EH, 011DH
	dc.b	$53
	dc.b	$01
	dc.b	$40
	dc.b	$01
	dc.b	$2E
	dc.b	$01
	dc.b	$1D
	dc.b	$01
* 		dw	010DH, 00FEH, 00F0H, 00E2H
	dc.b	$0D
	dc.b	$01
	dc.b	$FE
	dc.b	$00
	dc.b	$F0
	dc.b	$00
	dc.b	$E2
	dc.b	$00
* 
* 		dw	00D6H, 00CAH, 00BEH, 00B4H	* C5 > B5
	dc.b	$D6
	dc.b	$00
	dc.b	$CA
	dc.b	$00
	dc.b	$BE
	dc.b	$00
	dc.b	$B4
	dc.b	$00
* 		dw	00AAH, 00A0H, 0097H, 008FH
	dc.b	$AA
	dc.b	$00
	dc.b	$A0
	dc.b	$00
	dc.b	$97
	dc.b	$00
	dc.b	$8F
	dc.b	$00
* 		dw	0087H, 007FH, 0078H, 0071H
	dc.b	$87
	dc.b	$00
	dc.b	$7F
	dc.b	$00
	dc.b	$78
	dc.b	$00
	dc.b	$71
	dc.b	$00
* 
* 		dw	006BH, 0065H, 005FH, 005AH	* C6 > B6
	dc.b	$6B
	dc.b	$00
	dc.b	$65
	dc.b	$00
	dc.b	$5F
	dc.b	$00
	dc.b	$5A
	dc.b	$00
* 		dw	0055H, 0050H, 004CH, 0047H
	dc.b	$55
	dc.b	$00
	dc.b	$50
	dc.b	$00
	dc.b	$4C
	dc.b	$00
	dc.b	$47
	dc.b	$00
* 		dw	0043H, 0040H, 003CH, 0039H
	dc.b	$43
	dc.b	$00
	dc.b	$40
	dc.b	$00
	dc.b	$3C
	dc.b	$00
	dc.b	$39
	dc.b	$00
* 
* 		dw	0035H, 0032H, 002FH, 002DH	* C7 > B7 (not very accurate!)
	dc.b	$35
	dc.b	$00
	dc.b	$32
	dc.b	$00
	dc.b	$2F
	dc.b	$00
	dc.b	$2D
	dc.b	$00
* 		dw	002AH, 0028H, 0026H, 0023H
	dc.b	$2A
	dc.b	$00
	dc.b	$28
	dc.b	$00
	dc.b	$26
	dc.b	$00
	dc.b	$23
	dc.b	$00
* 		dw	0021H, 0020H, 001EH, 001CH
	dc.b	$21
	dc.b	$00
	dc.b	$20
	dc.b	$00
	dc.b	$1E
	dc.b	$00
	dc.b	$1C
	dc.b	$00
* 
* 		dw	001CH				* extra value for interpolation of B7
	dc.b	$1C
	dc.b	$00
* 
* noteonnote	db	0			* note on note (keep these together - stored as BC)
	dc.b	$00
* noteonch	db	0			* note on channel
	dc.b	$00
* noteonvoice	db	0			* allocated voice
	dc.b	$00
* noteonatten	db	0			* attenuation for this voice
	dc.b	$00
* 
* NOTEON
* 		call	DACME
	dc.b	$CD,$B7,$02
* 
* ** LAST MINUTE FIX FOR TAZ LEVELS - down 7
* 		ld	A,(MASTERATN)
	dc.b	$3A,$CF,$15
* **		zadd	A,10
* 		zadd	A,(IX+CCBATN)		* sum channel and master attenuations, limit to 127
	dc.b	$DD,$86,$1E
* 		jp	P,legalatten
	dc.b	$F2,$14,$12
* 		ld	A,127
	dc.b	$3E,$7F
* legalatten
* 		ld	(noteonatten),A
	dc.b	$32,$05,$12
* 
* 		ld	(noteonnote),BC		* save note and channel
	dc.b	$ED,$43,$02,$12
* 
* 		call	FILLDACFIFO
	dc.b	$CD,$02,$03
* 		call	CHECKTICK
	dc.b	$CD,$41,$00
* 
* 		ld	HL,(CHPATPTR)
	dc.b	$2A,$56,$04
* 		ld	A,(HL)			* A <- patch type (byte 0 of patch)
	dc.b	$7E
* 		cp	0
	dc.b	$FE,$00
* 		jp	Z,noteonfm		* 0 for fm patches
	dc.b	$CA,$2F,$14
* 		cp	1
	dc.b	$FE,$01
* 		jp	Z,noteondig		* 1 for digital patches
	dc.b	$CA,$F7,$12
* 		cp	2
	dc.b	$FE,$02
* 		jp	Z,noteontone
	dc.b	$CA,$43,$12
* 		cp	3
	dc.b	$FE,$03
* 		jp	Z,noteonnoise
	dc.b	$CA,$3A,$12
* 		ret
	dc.b	$C9
* 
* * here to allocate a voice for a PSG patch
* 
* noteonnoise
* 		ld	IY,PSGVTBLNG		* try to get TG4 (noise ch)
	dc.b	$FD,$21,$D2,$17
* 		call	ALLOCSPEC
	dc.b	$CD,$41,$18
* 		jr	noteoneither
	dc.b	$18,$07
* noteontone
* 		ld	IY,PSGVTBL
	dc.b	$FD,$21,$BC,$17
* 		call	ALLOC
	dc.b	$CD,$DE,$17
* noteoneither
* 		cp	0FFH
	dc.b	$FE,$FF
* 		ret	Z			* return if unable to allocate a voice
	dc.b	$C8
* 
* 		call	VTANDET			* call code shared by FM and PSG to update
	dc.b	$CD,$59,$16
* 						*   VoiceTable AND Envelope Trigger
* 		ld	A,1			* indicates PSG
	dc.b	$3E,$01
* 		ld	E,B			* E <- channel
	dc.b	$58
* 		ld	IX,PBTBL
	dc.b	$DD,$21,$76,$0F
* 		ld	D,0
	dc.b	$16,$00
* 		zadd	IX,DE			* IX <- ptr to pitch/envelope bend for this ch
	dc.b	$DD,$19
* 		call	GETFREQ
	dc.b	$CD,$A8,$10
* 
* 		ld	IX,(CHPATPTR)		* IX <- patch pointer
	dc.b	$DD,$2A,$56,$04
* 		inc	IX
	dc.b	$DD,$23
* 
* 		ld	A,(noteonvoice)		* A <- PSG voice number
	dc.b	$3A,$04,$12
* 		ld      C,A
	dc.b	$4F
* 		ld      B,0
	dc.b	$06,$00
* 		ld      IY,psgcom
	dc.b	$FD,$21,$09,$00
* 		zadd	IY,BC			* IY <- psg control registers for this voice
	dc.b	$FD,$09
* 
* 		ld	A,E
	dc.b	$7B
* 		zand	0FH
	dc.b	$E6,$0F
* 		ld      (IY+DTL),A		* write tone lsb
	dc.b	$FD,$77,$1C
* 		srl	D
	dc.b	$CB,$3A
* 		rr	E
	dc.b	$CB,$1B
* 		srl	D
	dc.b	$CB,$3A
* 		rr	E
	dc.b	$CB,$1B
* 		srl	D
	dc.b	$CB,$3A
* 		rr	E
	dc.b	$CB,$1B
* 		srl	D
	dc.b	$CB,$3A
* 		rr	E
	dc.b	$CB,$1B
* 		ld      (IY+DTH),E		* write tone msb
	dc.b	$FD,$73,$20
* 
* 		ld	A,(noteonvoice)
	dc.b	$3A,$04,$12
* 		cp	3
	dc.b	$FE,$03
* 		jr	NZ,pskon		* for TG1-TG3, go on to rest of control regs
	dc.b	$20,$34
* 
* 		ld	HL,PSGVTBLTG3		* assume TG3 is not locked by this noise patch
	dc.b	$21,$CA,$17
* 		res	5,(HL)
	dc.b	$CB,$AE
* 
* 		ld	A,(IX-1)		* its TG4 - is it clocked by TG3?
	dc.b	$DD,$7E,$00
* 		zand	3
	dc.b	$E6,$03
* 		cp	3
	dc.b	$FE,$03
* 		jr	NZ,psgnoise
	dc.b	$20,$20
* 
* 		ld	HL,7F11H		* yes - move the frequency directly to TG3
	dc.b	$21,$11,$7F
* 		ld	A,(IY+DTL)
	dc.b	$FD,$7E,$1C
* 		zor	0C0H
	dc.b	$F6,$C0
* 		ld	(HL),A
	dc.b	$77
* 		ld	A,(IY+DTH)
	dc.b	$FD,$7E,$20
* 		ld	(HL),A
	dc.b	$77
* 
* 		ld	HL,PSGVTBLTG3		* in the voice table...
	dc.b	$21,$CA,$17
* 		ld	(HL),0A2H		* show TG3 free and locked
	dc.b	$36,$A2
* 		inc	HL
	dc.b	$23
* 		inc	HL
	dc.b	$23
* 		ld	BC,(noteonnote)
	dc.b	$ED,$4B,$02,$12
* 		ld	(HL),C			* and store note and channel (for pitch mod)
	dc.b	$71
* 		inc	HL
	dc.b	$23
* 		ld	(HL),B
	dc.b	$70
* 
* 		ld	HL,psgcom+2		* and send a stop command to TG3 env processor
	dc.b	$21,$0B,$00
* 		ld	(HL),4
	dc.b	$36,$04
* psgnoise
* 		ld      A,(IX+0)		* load noise data
	dc.b	$DD,$7E,$00
* 		ld      (IY+DTL),A		* write noise data
	dc.b	$FD,$77,$1C
* 
* pskon      	ld      A,(IX+1)		* load attack rate
	dc.b	$DD,$7E,$01
* 		ld      (IY+ATK),A		* write attack rate
	dc.b	$FD,$77,$08
* 		ld      A,(IX+2)		* load sustain level
	dc.b	$DD,$7E,$02
* 		sla     A			* fix significance (<<4)
	dc.b	$CB,$27
* 		sla     A
	dc.b	$CB,$27
* 		sla     A
	dc.b	$CB,$27
* 		sla     A
	dc.b	$CB,$27
* 		ld      (IY+SLV),A		* write sustain level
	dc.b	$FD,$77,$10
* 		ld      A,(IX+3)		* load attack level
	dc.b	$DD,$7E,$03
* 		sla     A			* fix significance (<<4)
	dc.b	$CB,$27
* 		sla     A
	dc.b	$CB,$27
* 		sla     A
	dc.b	$CB,$27
* 		sla     A
	dc.b	$CB,$27
* 		ld      (IY+ALV),A		* write attack level
	dc.b	$FD,$77,$24
* 		ld      A,(IX+4)		* load decay rate
	dc.b	$DD,$7E,$04
* 		ld      (IY+DKY),A		* write decay rate
	dc.b	$FD,$77,$0C
* 		ld      A,(IX+5)		* load release rate
	dc.b	$DD,$7E,$05
* 		ld      (IY+RRT),A		* write release rate
	dc.b	$FD,$77,$14
* 		zset     0,(IY+COM)		* key on command
	dc.b	$FD,$CB,$00,$C6
* 
* 		ret
	dc.b	$C9
* 
* * here for a digital patch note on
* 
* noteondig
* 		ld	IY,FMVTBLCH6		* try to get FM voice 6 (DAC)
	dc.b	$FD,$21,$AD,$17
* 		call	ALLOCSPEC
	dc.b	$CD,$41,$18
* 		cp	0FFH
	dc.b	$FE,$FF
* 		ret	Z			* return if unable to allocate
	dc.b	$C8
* 
* 		bit	7,A			* was it in use?
	dc.b	$CB,$7F
* 		jr	NZ,noteondig2
	dc.b	$20,$1F
* 		ld	A,0C9H			* yes - disable DACME in case it was on to speed noteondig
	dc.b	$3E,$C9
* 		ld	(DACME),A
	dc.b	$32,$B7,$02
* 		ld	A,(HL)			* get flags back
	dc.b	$7E
* 		bit	5,A			* yes - was it FM?
	dc.b	$CB,$6F
* 		jr	NZ,noteondig2
	dc.b	$20,$15
* 		zand	7			* yes - do a keyoff
	dc.b	$E6,$07
* 		ld	IY,4000H
	dc.b	$FD,$21,$00,$40
* 		FMWrite	28H,A
	dc.b	$7F
	dc.b	$FD,$CB,$00,$7E
	dc.b	$20,$FA
	dc.b	$FD,$36,$00,$28
	dc.b	$FD,$77,$01
* 		ld	A,(HL)			* get flags back
	dc.b	$7E
* noteondig2
* 		call	VTANDET			* call code shared by FM and PSG to update
	dc.b	$CD,$59,$16
* 						*   VoiceTable AND Envelope Trigger
* 		ld	HL,FMVTBLCH6
	dc.b	$21,$AD,$17
* 		zset	5,(HL)			* lock the voice from FM allocation
	dc.b	$CB,$EE
* 
* * at this point, C is note number - C4 >> B7 equals samples  0 through 47 (for back compatibil
* *				    C0 >> B3 equals samples 48 through 96
* * trigger sample by reading sample bank table for header
* 
* 		ld	A,C			* map note num to sample num
	dc.b	$79
* 		zsub	48
	dc.b	$D6,$30
* 		jr	NC,noteondig21
	dc.b	$30,$02
* 		zadd	A,96
	dc.b	$C6,$60
* noteondig21
* 		ld	C,A
	dc.b	$4F
* 		ld	B,0			* BC <- sample number
	dc.b	$06,$00
* 		ld	HL,(DTBL68K)		* AHL <- pointer to sample table
	dc.b	$2A,$AE,$0A
* 		ld	A,(DTBL68K+2)
	dc.b	$3A,$B0,$0A
* 		sla	C
	dc.b	$CB,$21
* 		rl	B
	dc.b	$CB,$10
* 		sla	C
	dc.b	$CB,$21
* 		rl	B			* BC <- 4*sampno
	dc.b	$CB,$10
* 		zadd	HL,BC
	dc.b	$09
* 		adc	A,0
	dc.b	$CE,$00
* 		sla	C
	dc.b	$CB,$21
* 		rl	B			* BC <- 8*sampno
	dc.b	$CB,$10
* 		zadd	HL,BC			* AHL <- pointer to this sample in table (sampno*12)
	dc.b	$09
* 		adc	A,0
	dc.b	$CE,$00
* 
* 		ld	C,12			* read 12 byte header, into...
	dc.b	$0E,$0C
* 		ld	DE,SAMPFLAGS		* sample header cache
	dc.b	$11,$21,$14
* 		call	XFER68K
	dc.b	$CD,$F9,$01
* 
* 		ld	BC,(SAMPFIRST)		* check for non-zero sample length
	dc.b	$ED,$4B,$27,$14
* 		ld	A,B
	dc.b	$78
* 		zor	C
	dc.b	$B1
* 		jr	NZ,sampleok
	dc.b	$20,$06
* 		ld	HL,FMVTBLCH6
	dc.b	$21,$AD,$17
* 		ld	(HL),0C6H		* empty sample - mark voice 6 free and releasing
	dc.b	$36,$C6
* 		ret
	dc.b	$C9
* sampleok
* 
* * now check for sample playback rate override (2nd byte of patch != 4) - override rate in SAMP
* 
* 		ld	HL,(CHPATPTR)
	dc.b	$2A,$56,$04
* 		inc	HL
	dc.b	$23
* 		ld	A,(HL)
	dc.b	$7E
* 		cp	4
	dc.b	$FE,$04
* 		jr	Z,sampleok1
	dc.b	$28,$0A
* 		ld	B,A
	dc.b	$47
* 		ld	A,(SAMPFLAGS)
	dc.b	$3A,$21,$14
* 		zand	0F0H			* replace counter value in flags (controls freq)
	dc.b	$E6,$F0
* 		zor	B
	dc.b	$B0
* 		ld	(SAMPFLAGS),A
	dc.b	$32,$21,$14
* sampleok1
* 		exx
	dc.b	$D9
* 
* 		ld	E,0			* reset FIFO read ptr to start of buffer
	dc.b	$1E,$00
* 
* 		ld	(HL),024H		* set timer A msb
	dc.b	$36,$24
* 		inc	HL
	dc.b	$23
* 		ld	A,(SAMPFLAGS)
	dc.b	$3A,$21,$14
* 		zand	0FH
	dc.b	$E6,$0F
* 		zneg
	dc.b	$ED,$44
* 		sra	A
	dc.b	$CB,$2F
* 		sra	A
	dc.b	$CB,$2F
* 		ld	(HL),A
	dc.b	$77
* 		dec	HL
	dc.b	$2B
* 
* 		ld	(HL),025H		* timer A lsb
	dc.b	$36,$25
* 		inc	HL
	dc.b	$23
* 		ld	A,(SAMPFLAGS)
	dc.b	$3A,$21,$14
* 		zand	0FH
	dc.b	$E6,$0F
* 		zneg
	dc.b	$ED,$44
* 		zand	3
	dc.b	$E6,$03
* 		ld	(HL),A
	dc.b	$77
* 		dec	HL
	dc.b	$2B
* 
* 		ld	(HL),02BH		* enable the dac
	dc.b	$36,$2B
* 		inc	HL
	dc.b	$23
* 		ld	(HL),080H
	dc.b	$36,$80
* 		dec	HL
	dc.b	$2B
* 
* 		ld	(HL),27H		* enable timer
	dc.b	$36,$27
* 		inc	HL
	dc.b	$23
* 		ld	(HL),B
	dc.b	$70
* 		dec	HL
	dc.b	$2B
* 
* 		exx
	dc.b	$D9
* 
* 		ld	IY,4002H
	dc.b	$FD,$21,$02,$40
* 		FMWrite 0B6H,0C0H		* enable ch6 output to both R and L
	dc.b	$3E,$C0
	dc.b	$FD,$CB,$00,$7E
	dc.b	$20,$FA
	dc.b	$FD,$36,$00,$B6
	dc.b	$FD,$77,$01
* 
* 		ld	BC,(DTBL68K)
	dc.b	$ED,$4B,$AE,$0A
* 		ld	A,(DTBL68K+2)
	dc.b	$3A,$B0,$0A
* 		ld	D,A			* DBC <- pointer to sample table
	dc.b	$57
* 		ld	HL,(SAMPPTR)
	dc.b	$2A,$22,$14
* 		ld	A,(SAMPPTR+2)		* AHL <- 24-bit sample start offset
	dc.b	$3A,$24,$14
* 		zadd	HL,BC
	dc.b	$09
* 		adc	A,D			* add em up to get ptr to sample start
	dc.b	$8A
* 		ld	BC,(SAMPSKIP)
	dc.b	$ED,$4B,$25,$14
* 		zadd	HL,BC			* add skip value to pointer for initial load
	dc.b	$09
* 		adc	A,0
	dc.b	$CE,$00
* 		ld	(SAMPLEPTR),HL		* store read pointer for FILLDACFIFO
	dc.b	$22,$FC,$02
* 		ld	(SAMPLEPTR+2),A
	dc.b	$32,$FE,$02
* 
* 		ld	HL,(SAMPFIRST)
	dc.b	$2A,$27,$14
* 		ld	(SAMPLECTR),HL		* initialize counter
	dc.b	$22,$FF,$02
* 
* 		ld	A,0
	dc.b	$3E,$00
* 		ld	(FILLDACFIFO),A		* enable full FILLDACFIFO routine
	dc.b	$32,$02,$03
* 		ld	(DACFIFOWPTR),A		* start fill at 1F00
	dc.b	$32,$FB,$02
* 
* 		ld	A,(SAMPFLAGS)
	dc.b	$3A,$21,$14
* 		bit	4,A			* looped?
	dc.b	$CB,$67
* 		ld	A,4			* FDF=4 to run nonloop sample
	dc.b	$3E,$04
* 		jr	Z,notlooped
	dc.b	$28,$01
* 		inc	A			* FDF=5 to run loop sample
	dc.b	$3C
* notlooped
* 		ld	(FDFSTATE),A
	dc.b	$32,$01,$03
* 
* 		call	FORCEFILLDF		* force the fill
	dc.b	$CD,$10,$03
* 
* 		ld	A,0D9H			* opcode "EXX"
	dc.b	$3E,$D9
* 		ld	(DACME),A		* enable DACME routine
	dc.b	$32,$B7,$02
* 		ld	A,008H			* opcode "EX AF,AF"
	dc.b	$3E,$08
* 		ld	(DACME+1),A
	dc.b	$32,$B8,$02
* 
* 		ld	A,(SAMPFLAGS)		* check for slow dacme mode: samp rate = 5.2kHz
	dc.b	$3A,$21,$14
* 		zand	0FH
	dc.b	$E6,$0F
* 		cp	10			* samples rate <= 5.2?
	dc.b	$FE,$0A
* 		ld	A,0			* (if slow, put a NOP at DACMERET to enable toggling)
	dc.b	$3E,$00
* 		jr	NC,useslowdacme
	dc.b	$30,$02
* 		ld	A,0C9H			* opcode "RET", to disable toggling
	dc.b	$3E,$C9
* useslowdacme
* 		ld	(DACMERET),A
	dc.b	$32,$CF,$02
* 
* 		ld	A,(SAMPFLAGS)		* compression on?
	dc.b	$3A,$21,$14
* 		bit	7,A
	dc.b	$CB,$7F
* 		ld	HL,0			* (2 nops for 8 bit mode)
	dc.b	$21,$00,$00
* 		jr	Z,setprocinst
	dc.b	$28,$07
* 
* 		ld	HL,(DACME4BINST)	* jump to DACMEDSP for DACMEPROC
	dc.b	$2A,$B5,$02
* 		exx
	dc.b	$D9
* 		ld	C,0AAH			* pattern to control nibble selection in DACMEDSP
	dc.b	$0E,$AA
* 		exx
	dc.b	$D9
* setprocinst
* 		ld	(DACMEPROC),HL		* set approriate inst(s) at DACMEPROC
	dc.b	$22,$C4,$02
* 		ret
	dc.b	$C9
* 
* 
* SAMPFLAGS	db	0
	dc.b	$00
* SAMPPTR		db	0,0,0
	dc.b	$00
	dc.b	$00
	dc.b	$00
* SAMPSKIP	db	0,0
	dc.b	$00
	dc.b	$00
* SAMPFIRST	db	0,0
	dc.b	$00
	dc.b	$00
* SAMPLOOP	db	0,0
	dc.b	$00
	dc.b	$00
* SAMPEND		db	0,0
	dc.b	$00
	dc.b	$00
* 
* * here to allocate a voice for an FM patch
* 
* noteonffreq	dw	0
	dc.b	$00
	dc.b	$00
* 
* noteonfm
* 		inc	HL
	dc.b	$23
* 		inc	HL
	dc.b	$23
* 		ld	D,(HL)			* (D <- CH3 mode byte)
	dc.b	$56
* 		bit	6,D
	dc.b	$CB,$72
* 		jr	Z,noteonfm1
	dc.b	$28,$09
* 
* 		ld	IY,FMVTBLCH3		* only CH3 will do for a CH3 mode patch
	dc.b	$FD,$21,$B4,$17
* 		call	ALLOCSPEC
	dc.b	$CD,$41,$18
* 		jr	noteonfm15
	dc.b	$18,$07
* noteonfm1
* 		ld	IY,FMVTBL
	dc.b	$FD,$21,$91,$17
* 		call	ALLOC
	dc.b	$CD,$DE,$17
* noteonfm15
* 
* 	call	DACME
	dc.b	$CD,$B7,$02
* 
* 		cp	0FFH
	dc.b	$FE,$FF
* 		ret	Z			* return if unable to allocate a voice
	dc.b	$C8
* 
* 		bit	7,A			* was it in use?
	dc.b	$CB,$7F
* 		jr	NZ,noteonfm2
	dc.b	$20,$15
* 		zand	7			* yes - do a keyoff
	dc.b	$E6,$07
* 		ld	IY,4000H
	dc.b	$FD,$21,$00,$40
* 		FMWrite	28H,A
	dc.b	$7F
	dc.b	$FD,$CB,$00,$7E
	dc.b	$20,$FA
	dc.b	$FD,$36,$00,$28
	dc.b	$FD,$77,$01
* 		ld	A,(HL)			* get flags back
	dc.b	$7E
* noteonfm2
* 		push	DE
	dc.b	$D5
* 		call	VTANDET
	dc.b	$CD,$59,$16
* 		pop	DE
	dc.b	$D1
* 
* 		bit	6,D			* skip freq computation for CH3 mode
	dc.b	$CB,$72
* 		jr	NZ,noteonfm3
	dc.b	$20,$15
* 
* 		ld	A,0			* FM type voice
	dc.b	$3E,$00
* 		ld	E,B			* E <- channel
	dc.b	$58
* 
* 		ld	IX,PBTBL
	dc.b	$DD,$21,$76,$0F
* 		ld	D,0
	dc.b	$16,$00
* 		zadd	IX,DE			* IX <- ptr to pitch/envelope bend for this ch
	dc.b	$DD,$19
* 		call	GETFREQ
	dc.b	$CD,$A8,$10
* 		ld	(noteonffreq),DE	* save freq number
	dc.b	$ED,$53,$2D,$14
* 
* 		call	DACME
	dc.b	$CD,$B7,$02
* 
* noteonfm3
* 		ld	IX,(CHPATPTR)		* IX <- patch pointer + 1 (past type byte)
	dc.b	$DD,$2A,$56,$04
* 		inc	IX
	dc.b	$DD,$23
* 		ld	A,(noteonvoice)
	dc.b	$3A,$04,$12
* 		ld	C,A			* C  <- key on code
	dc.b	$4F
* 
* 		ld	IY,4000H		* IY <- FM chip
	dc.b	$FD,$21,$00,$40
* 
* 		cp	2			* channel 3 ?
	dc.b	$FE,$02
* 		jr	NZ,noteonfm4
	dc.b	$20,$1E
* 		ld	A,(IX+1)		* yes - add CH3 mode bits to DACME's reset cmd
	dc.b	$DD,$7E,$01
* 		zor	15H
	dc.b	$F6,$15
* 		exx
	dc.b	$D9
* 		ld	B,A			*  which is kept in B'
	dc.b	$47
* 		exx
	dc.b	$D9
* 
* 		ld	A,(IX+1)		* CH3 mode bits again, plus bits to
	dc.b	$DD,$7E,$01
* 		zor	5			* KEEP TIMER A ENABLED AND RUNNING, but not reset
	dc.b	$F6,$05
* 		ld	H,A
	dc.b	$67
* 		ld	L,27H			* send now
	dc.b	$2E,$27
* 		FMWrgl
	dc.b	$FD,$CB,$00,$7E
	dc.b	$20,$FA
	dc.b	$7D
	dc.b	$32,$00,$40
	dc.b	$7C
	dc.b	$32,$01,$40
* 
* noteonfm4
* 		ld	D,0			* indicates bank 0 to FMWr
	dc.b	$16,$00
* 		ld	A,C
	dc.b	$79
* 		cp	3			* is voice in bank 1 ?
	dc.b	$FE,$03
* 		jr	C,fmbank0
	dc.b	$38,$04
* 		zsub	4			* yes, subtract 4 (map 4-6 >> 0-2)
	dc.b	$D6,$04
* 		ld	D,2			* indicates bank 1 to FMWr
	dc.b	$16,$02
* fmbank0
* 		ld	E,A			* E <- channel within bank
	dc.b	$5F
* 		ld      H,(IX+0)		* load lfo data
	dc.b	$DD,$66,$00
* 		bit	3,H			* only load if LFO on in this patch
	dc.b	$CB,$5C
* 		jr	Z,fmlfodis
	dc.b	$28,$10
* 		ld      L,22H			* load register number
	dc.b	$2E,$22
* 		FMWrgl				* write lfo register
	dc.b	$FD,$CB,$00,$7E
	dc.b	$20,$FA
	dc.b	$7D
	dc.b	$32,$00,$40
	dc.b	$7C
	dc.b	$32,$01,$40
* fmlfodis
* 		push	BC		* save C (note on number)
	dc.b	$C5
* 
* 		ld	HL,CARRIERTBL
	dc.b	$21,$C6,$15
* 		ld	B,0
	dc.b	$06,$00
* 		ld	A,(IX+2)		* lookup up carrier mask by alg number
	dc.b	$DD,$7E,$02
* 		zand	7
	dc.b	$E6,$07
* 		ld	C,A
	dc.b	$4F
* 		zadd	HL,BC
	dc.b	$09
* 		ld	A,(HL)
	dc.b	$7E
* 		ld	(CARRIERS),A		* bit 0 for op 1 carrier, bit 1 for op 2 carrier...
	dc.b	$32,$CE,$15
* 
* 		ld	H,40H
	dc.b	$26,$40
* 		ld	BC,FMADDRTBL
	dc.b	$01,$1C,$16
* 		call	WRITEFM
	dc.b	$CD,$D0,$15
* 
* 		export FOO2
* FOO2
* 
* 
* 		bit     6,(IX+1)		* check channel 3 mode
	dc.b	$DD,$CB,$01,$76
* 		jr      NZ,fmc3on		* go set channel 3 frequency
	dc.b	$20,$2D
* 		ld	IY,noteonffreq		* IY <- ptr to freq number from GETFREQ
	dc.b	$FD,$21,$2D,$14
* 		FMWr	0A4H,(IY+1)		* set frequency msb
	dc.b	$2E,$00
	dc.b	$3E,$A4
	dc.b	$83
	dc.b	$47
	dc.b	$FD,$4E,$01
	dc.b	$3E,$80
	dc.b	$A6
	dc.b	$FA,$03,$15
	dc.b	$6A
	dc.b	$70
	dc.b	$2C
	dc.b	$71
* 		FMWr	0A0H,(IY+0)		* set frequency lsb
	dc.b	$2E,$00
	dc.b	$3E,$A0
	dc.b	$83
	dc.b	$47
	dc.b	$FD,$4E,$00
	dc.b	$3E,$80
	dc.b	$A6
	dc.b	$FA,$16,$15
	dc.b	$6A
	dc.b	$70
	dc.b	$2C
	dc.b	$71
* 		jp      fmkon			* go key on
	dc.b	$C3,$A6,$15
* 
* fmc3on
* 		ld	IY,4000H
	dc.b	$FD,$21,$00,$40
* 		FMWrite 0A6H,(IX+28)		* ch3 op1 msb
	dc.b	$DD,$7E,$1C
	dc.b	$FD,$CB,$00,$7E
	dc.b	$20,$FA
	dc.b	$FD,$36,$00,$A6
	dc.b	$FD,$77,$01
* 		FMWrite 0A2H,(IX+29)		* ch3 op1 lsb
	dc.b	$DD,$7E,$1D
	dc.b	$FD,$CB,$00,$7E
	dc.b	$20,$FA
	dc.b	$FD,$36,$00,$A2
	dc.b	$FD,$77,$01
* 		FMWrite 0ACH,(IX+30)		* ch3 op2 msb
	dc.b	$DD,$7E,$1E
	dc.b	$FD,$CB,$00,$7E
	dc.b	$20,$FA
	dc.b	$FD,$36,$00,$AC
	dc.b	$FD,$77,$01
* 		FMWrite 0A8H,(IX+31)		* ch3 op2 lsb
	dc.b	$DD,$7E,$1F
	dc.b	$FD,$CB,$00,$7E
	dc.b	$20,$FA
	dc.b	$FD,$36,$00,$A8
	dc.b	$FD,$77,$01
* 		FMWrite 0ADH,(IX+32)		* ch3 op3 msb
	dc.b	$DD,$7E,$20
	dc.b	$FD,$CB,$00,$7E
	dc.b	$20,$FA
	dc.b	$FD,$36,$00,$AD
	dc.b	$FD,$77,$01
* 		FMWrite 0A9H,(IX+33)		* ch3 op3 lsb
	dc.b	$DD,$7E,$21
	dc.b	$FD,$CB,$00,$7E
	dc.b	$20,$FA
	dc.b	$FD,$36,$00,$A9
	dc.b	$FD,$77,$01
* 		FMWrite 0AEH,(IX+34)		* ch3 op4 msb
	dc.b	$DD,$7E,$22
	dc.b	$FD,$CB,$00,$7E
	dc.b	$20,$FA
	dc.b	$FD,$36,$00,$AE
	dc.b	$FD,$77,$01
* 		FMWrite 0AAH,(IX+35)		* ch3 op4 lsb
	dc.b	$DD,$7E,$23
	dc.b	$FD,$CB,$00,$7E
	dc.b	$20,$FA
	dc.b	$FD,$36,$00,$AA
	dc.b	$FD,$77,$01
* 
* fmkon:		ld      A,(IX+36)		* load operator on mask
	dc.b	$DD,$7E,$24
* 		sla     A			* fix significance
	dc.b	$CB,$27
* 		sla     A
	dc.b	$CB,$27
* 		sla     A
	dc.b	$CB,$27
* 		sla     A
	dc.b	$CB,$27
* 		pop	BC		* UGLY!!!!!
	dc.b	$C1
* 		zor	C			* mix with channel code
	dc.b	$B1
* 		ld      IY,4000H		* global fm register
	dc.b	$FD,$21,$00,$40
* 		FMWrite 28H,A			* key on
	dc.b	$7F
	dc.b	$FD,$CB,$00,$7E
	dc.b	$20,$FA
	dc.b	$FD,$36,$00,$28
	dc.b	$FD,$77,$01
* 
* 		ret
	dc.b	$C9
* 
* CARRIERTBL	db	08H		* alg 0, op 4 is carrier
	dc.b	$08
* 		db	08H		* alg 1, op 4 is carrier
	dc.b	$08
* 		db	08H		* alg 2, op 4 is carrier
	dc.b	$08
* 		db	08H		* alg 3, op 4 is carrier
	dc.b	$08
* 		db	0AH		* alg 4, op 2 and 4 are carriers
	dc.b	$0A
* 		db	0EH		* alg 5, op 2 and 3 and 4 are carriers
	dc.b	$0E
* 		db	0EH		* alg 6, op 2 and 3 and 4 are carriers
	dc.b	$0E
* 		db	0FH		* alg 7, all ops carriers
	dc.b	$0F
* 
* CARRIERS	db	0
	dc.b	$00
* 
* 		export	MASTERATN
* MASTERATN	db	0		* master attenuation is 7 frac bits (0 = full volume)
	dc.b	$00
* 
* *
* * WRITEFM - write a string of values to the FM chip. BC points to a null-terminated
* *   list of reg/data pairs, where data is an offset off of IX. if data is 0, the
* *   indirection is skipped and a 0 written (for the "proprietary register")
* *   H <- 40H (MSB of FM chip register address)
* *   D <- 0 for bank 0 (channels 0,1,2) or 2 for bank 1 (channels 3,4,5)
* *   E <- channel within bank (0-2)
* *
* 		export	WRITEFM
* WRITEFM
* 		ld	A,(BC)			* get reg num
	dc.b	$0A
* 		zor	A
	dc.b	$B7
* 		ret	Z			* (0 = EOT)
	dc.b	$C8
* 		inc	BC
	dc.b	$03
* 
* 		ld	L,0			* point to 4000
	dc.b	$2E,$00
* 		bit	7,(HL)			* spin on busy bit
	dc.b	$CB,$7E
* 		jr	NZ,*-2
	dc.b	$20,$FC
* 
* 		ld	L,D			* point at bank's addr port
	dc.b	$6A
* 		zadd	A,E			* add voice num to point at correct register
	dc.b	$83
* 		ld	(HL),A
	dc.b	$77
* 		inc	L			* point at data port
	dc.b	$2C
* 		ld	A,(BC)			* get data offset
	dc.b	$0A
* 		zor	A			* if data offset 0, just write 0
	dc.b	$B7
* 		jp	Z,writefm0
	dc.b	$CA,$17,$16
* 		jp	P,nottl			* msb indicates total level values
	dc.b	$F2,$11,$16
* 
* 		zand	7FH			* mask off tl flag
	dc.b	$E6,$7F
* 		push	HL
	dc.b	$E5
* 		ld	HL,CARRIERS		* is this a carrier?
	dc.b	$21,$CE,$15
* 		rr	(HL)
	dc.b	$CB,$1E
* 		jp	NC,nottl0		* no - normal output
	dc.b	$D2,$10,$16
* 		push	DE
	dc.b	$D5
* 		ld	(SELFMOD2+2),A		* modify LD instruction with this offset
	dc.b	$32,$F9,$15
* 		ld	A,127
	dc.b	$3E,$7F
* SELFMOD2	zsub	(IX+0)			* becomes ld A,(IX+dataoffset)
	dc.b	$DD,$96,$00
* 		push	AF			* save level (0=soft, 127=loud)
	dc.b	$F5
* 		sla	A
	dc.b	$CB,$27
* 		ld	E,A
	dc.b	$5F
* 		ld	D,0			* DE is level (0=soft, 254=loud)
	dc.b	$16,$00
* 		ld	A,(noteonatten)
	dc.b	$3A,$05,$12
* 		call	MULTIPLY
	dc.b	$CD,$59,$11
* 		pop	AF			* get back level
	dc.b	$F1
* 		zsub	H			* reduce by attenuation amount
	dc.b	$94
* 		ld	H,A
	dc.b	$67
* 		ld	A,127
	dc.b	$3E,$7F
* 		zsub	H
	dc.b	$94
* 		pop	DE
	dc.b	$D1
* 		pop	HL
	dc.b	$E1
* 		jr	writefm0
	dc.b	$18,$07
* nottl0
* 		pop	HL
	dc.b	$E1
* nottl
* 		ld	(SELFMOD+2),A		* modify LD instruction with this offset
	dc.b	$32,$16,$16
* SELFMOD		ld	A,(IX+0)		* becomes ld A,(IX+dataoffset)
	dc.b	$DD,$7E,$00
* 
* writefm0	ld	(HL),A
	dc.b	$77
* 		inc	BC
	dc.b	$03
* 		jp	WRITEFM
	dc.b	$C3,$D0,$15
* 
* FMADDRTBL
* 		db	0B0H,2		* set feedback, algorithm
	dc.b	$B0
	dc.b	$02
* 		db	0B4H,3		* set output, ams, fms
	dc.b	$B4
	dc.b	$03
* 		db	30H,4		* operator 1 - set detune, mult
	dc.b	$30
	dc.b	$04
* 		db	40H,133		*5+128	* set total level
	dc.b	$40
	dc.b	$85
* 		db	50H,6		* set rate scaling, attack rate
	dc.b	$50
	dc.b	$06
* 		db	60H,7		* set am enable, decay rate
	dc.b	$60
	dc.b	$07
* 		db	70H,8		* set sustain decay rate
	dc.b	$70
	dc.b	$08
* 		db	80H,9		* set sustain level, release rate
	dc.b	$80
	dc.b	$09
* 		db	90H,0		* set proprietary register
	dc.b	$90
	dc.b	$00
* 		db	38H,16		* operator 2 - set detune, mult
	dc.b	$38
	dc.b	$10
* 		db	48H,145		*17+128	* set total level
	dc.b	$48
	dc.b	$91
* 		db	58H,18		* set rate scaling, attack rate
	dc.b	$58
	dc.b	$12
* 		db	68H,19		* set am enable, decay rate
	dc.b	$68
	dc.b	$13
* 		db	78H,20		* set sustain decay rate
	dc.b	$78
	dc.b	$14
* 		db	88H,21		* set sustain level, release rate
	dc.b	$88
	dc.b	$15
* 		db	98H,0		* set proprietary register
	dc.b	$98
	dc.b	$00
* 		db	34H,10		* operator 3 - set detune, mult
	dc.b	$34
	dc.b	$0A
* 		db	44H,139		*11+128	* set total level
	dc.b	$44
	dc.b	$8B
* 		db	54H,12		* set rate scaling, attack rate
	dc.b	$54
	dc.b	$0C
* 		db	64H,13		* set am enable, decay rate
	dc.b	$64
	dc.b	$0D
* 		db	74H,14		* set sustain decay rate
	dc.b	$74
	dc.b	$0E
* 		db	84H,15		* set sustain level, release rate
	dc.b	$84
	dc.b	$0F
* 		db	94H,0		* set proprietary register
	dc.b	$94
	dc.b	$00
* 		db	3CH,22		* operator 4 - set detune, mult
	dc.b	$3C
	dc.b	$16
* 		db	4CH,151		*23+128	* set total level
	dc.b	$4C
	dc.b	$97
* 		db	5CH,24		* set rate scaling, attack rate
	dc.b	$5C
	dc.b	$18
* 		db	6CH,25		* set am enable, decay rate
	dc.b	$6C
	dc.b	$19
* 		db	7CH,26		* set sustain decay rate
	dc.b	$7C
	dc.b	$1A
* 		db	8CH,27		* set sustain level, release rate
	dc.b	$8C
	dc.b	$1B
* 		db	9CH,0			* set proprietary register
	dc.b	$9C
	dc.b	$00
* 		db	0
	dc.b	$00
* 
* 		export	EOWRITEFM
* EOWRITEFM
* 
* *
* *  VTANDET - code shared between FM and PSG note on routines for stuffing the
* *    voice table entry and checking for envelope retrigger
* *
* 
* VTANDET
* 		zand	7			* clear flags
	dc.b	$E6,$07
* 		ld	(noteonvoice),A		* save allocated voice
	dc.b	$32,$04,$12
* 		ld	(HL),A
	dc.b	$77
* 
* 		ld	E,(IX+CCBDURL)
	dc.b	$DD,$5E,$0B
* 		ld	D,(IX+CCBDURH)
	dc.b	$DD,$56,$0C
* 		ld	A,D
	dc.b	$7A
* 		zor	E
	dc.b	$B3
* 		jr	Z,noselftime		* if non-zero duration, set self-time flag
	dc.b	$28,$02
* 		zset	4,(HL)
	dc.b	$CB,$E6
* noselftime
* 		bit	3,(IX+CCBFLAGS)		* sfx tempo based?
	dc.b	$DD,$CB,$06,$5E
* 		jr	Z,nosfxtempo
	dc.b	$28,$02
* 		zset	3,(HL)			*  yes - set voice tbl sfx flag
	dc.b	$CB,$DE
* nosfxtempo
* 		inc	HL
	dc.b	$23
* 		ld	A,(IX+CCBPRIO)
	dc.b	$DD,$7E,$1C
* 		ld	(HL),A
	dc.b	$77
* 		ld	BC,(noteonnote)		* C <- note, B <- channel
	dc.b	$ED,$4B,$02,$12
* 		inc	HL			* store note and channel in table
	dc.b	$23
* 		ld	(HL),C
	dc.b	$71
* 		inc	HL
	dc.b	$23
* 		ld	(HL),B
	dc.b	$70
* 		inc	HL
	dc.b	$23
* 		ld	(HL),E
	dc.b	$73
* 		inc	HL
	dc.b	$23
* 		ld	(HL),D
	dc.b	$72
* 		inc	HL
	dc.b	$23
* 		ld	(HL),254		* init release timer
	dc.b	$36,$FE
* 
* 	call	DACME
	dc.b	$CD,$B7,$02
* 
* 		bit	6,(IX+CCBFLAGS)		* envelope retrigger on?
	dc.b	$DD,$CB,$06,$76
* 		ret	Z
	dc.b	$C8
* 		push	BC			* yes - trigger the envelope
	dc.b	$C5
* 		ld	C,(IX+CCBENV)
	dc.b	$DD,$4E,$1D
* 		ld	E,B
	dc.b	$58
* 		call	TRIGENV
	dc.b	$CD,$2D,$0E
* 		call	DACME
	dc.b	$CD,$B7,$02
* 		pop	BC
	dc.b	$C1
* 		ret
	dc.b	$C9
* 
* *
* *  NOTEOFF - note off (key off)
* *
* *	parameters:	B	midi channel
* *			C	note number: bits 6:4 = octave, bits 3:0 = note (0-11)
* *
* *	trashes:	all registers
* *
* 
* noteoffnote	db	0
	dc.b	$00
* noteoffch	db	0
	dc.b	$00
* 
* NOTEOFF
* 		ld	(noteoffnote),BC
	dc.b	$ED,$43,$9C,$16
* 
* 		ld	IX,FMVTBL
	dc.b	$DD,$21,$91,$17
* 		call	DACME
	dc.b	$CD,$B7,$02
* 		call	DEALLOC
	dc.b	$CD,$58,$18
* 
* 		cp	0FFH			* was note found?
	dc.b	$FE,$FF
* 		jr	Z,trypsg
	dc.b	$28,$1F
* 		zand	27H			* yes - locked channel six?
	dc.b	$E6,$27
* 		cp	26H
	dc.b	$FE,$26
* 		jr	Z,digoff		*   yes - do digital note off
	dc.b	$28,$15
* 		zand	7			*   no - get note number
	dc.b	$E6,$07
* 		ld      IY,4000H        	* load fm register address
	dc.b	$FD,$21,$00,$40
* 		FMWrite 28H,A           	* key off
	dc.b	$7F
	dc.b	$FD,$CB,$00,$7E
	dc.b	$20,$FA
	dc.b	$FD,$36,$00,$28
	dc.b	$FD,$77,$01
* 		ret
	dc.b	$C9
* digoff
* 		call	NOTEOFFDIG
	dc.b	$CD,$12,$17
* 		ret
	dc.b	$C9
* 
* trypsg		ld	BC,(noteoffnote)
	dc.b	$ED,$4B,$9C,$16
* 		ld	IX,PSGVTBL
	dc.b	$DD,$21,$BC,$17
* 		call	DACME
	dc.b	$CD,$B7,$02
* 		call	DEALLOC
	dc.b	$CD,$58,$18
* 
* 		cp	0FFH
	dc.b	$FE,$FF
* 		jr	Z,trynoise
	dc.b	$28,$10
* 
* 		zand	3
	dc.b	$E6,$03
* 		ld      IX,psgcom		* load psg register table
	dc.b	$DD,$21,$09,$00
* 		ld      C,A			* BC <- 0A
	dc.b	$4F
* 		ld      B,0
	dc.b	$06,$00
* 		zadd	IX,BC			* point to correct register
	dc.b	$DD,$09
* 		zset	1,(IX+0)		* set key off command
	dc.b	$DD,$CB,$00,$CE
* 		ret
	dc.b	$C9
* trynoise
* 		ld	BC,(noteoffnote)
	dc.b	$ED,$4B,$9C,$16
* 		ld	IX,PSGVTBLNG
	dc.b	$DD,$21,$D2,$17
* 		call	DACME
	dc.b	$CD,$B7,$02
* 		call	DEALLOC
	dc.b	$CD,$58,$18
* 
* 		cp	0FFH
	dc.b	$FE,$FF
* 		ret	Z
	dc.b	$C8
* 
* 		zand	3
	dc.b	$E6,$03
* 		ld      IX,psgcom		* load psg register table
	dc.b	$DD,$21,$09,$00
* 		ld      C,A			* BC <- 0A
	dc.b	$4F
* 		ld      B,0
	dc.b	$06,$00
* 		zadd	IX,BC			* point to correct register
	dc.b	$DD,$09
* 		zset	1,(IX+0)		* set key off command
	dc.b	$DD,$CB,$00,$CE
* 		ret
	dc.b	$C9
* 
* NOTEOFFDIG
* 		ld	A,(SAMPFLAGS)
	dc.b	$3A,$21,$14
* 		bit	5,A			* is clip@noteoff set?
	dc.b	$CB,$6F
* 		jr	NZ,noteoffdig1		* yes - shut down digitial
	dc.b	$20,$07
* 		bit	4,A			* is it looped?
	dc.b	$CB,$67
* 		ret	Z
	dc.b	$C8
* 		ld	A,6			* yes - indicate end of loop
	dc.b	$3E,$06
* 		jr	noteoffdig2
	dc.b	$18,$02
* noteoffdig1
* 		ld	A,7
	dc.b	$3E,$07
* noteoffdig2
* 		ld	(FDFSTATE),A
	dc.b	$32,$01,$03
* 		ret
	dc.b	$C9
* 
* *
* *  PCHANGE - program change
* *
* *	trashes:	all registers
* *
* 
* fpoffset	dw	0
	dc.b	$00
	dc.b	$00
* 
* PCHANGE
* 		call	GETCCBPTR		* GETCBYTE for channel, IX <- CCB ptr, A <- channel
	dc.b	$CD,$A5,$08
* 		call	GETPATPTR		* HL <- PATCHDATA + 39 * A
	dc.b	$CD,$51,$11
* 		ld	(CHPATPTR),HL		* set pointer to this channel's patch buffer
	dc.b	$22,$56,$04
* 
* 		call	GETCBYTE
	dc.b	$CD,$D1,$01
* 		ld	(IX+CCBPNUM),A		* set program number in CCB
	dc.b	$DD,$77,$0D
* FETCHPATCH
* 		ld	D,0
	dc.b	$16,$00
* 		ld	E,(IX+CCBPNUM)
	dc.b	$DD,$5E,$0D
* 		sla	E			* DE <- pnum * 2
	dc.b	$CB,$23
* 		ld	HL,(PTBL68K)
	dc.b	$2A,$A5,$0A
* 		ld	A,(PTBL68K+2)		* AHL <- pointer to patch table in 68k space
	dc.b	$3A,$A7,$0A
* 		zadd	HL,DE
	dc.b	$19
* 		adc	A,0			* AHL <- pointer to this patch's offset
	dc.b	$CE,$00
* 		ld	C,2			* read 2 byte offset, into...
	dc.b	$0E,$02
* 		ld	DE,fpoffset		* local fpoffset
	dc.b	$11,$26,$17
* 		call	XFER68K
	dc.b	$CD,$F9,$01
* 
* 		ld	DE,(fpoffset)		* DE <- the offset
	dc.b	$ED,$5B,$26,$17
* 		ld	HL,(PTBL68K)
	dc.b	$2A,$A5,$0A
* 		ld	A,(PTBL68K+2)
	dc.b	$3A,$A7,$0A
* 		zadd	HL,DE
	dc.b	$19
* 		adc	A,0			* AHL <- pointer to patch data
	dc.b	$CE,$00
* 		ld	C,39			* xfer the 39 byte patch into
	dc.b	$0E,$27
* 		ld	DE,(CHPATPTR)		* this channel's patch buffer
	dc.b	$ED,$5B,$56,$04
* 		call	XFER68K
	dc.b	$CD,$F9,$01
* 
* 		ret
	dc.b	$C9
* 
* PATCHLOAD
* 		ld	B,A			* B <- patchnum
	dc.b	$47
* 		ld	C,16			* C <- loop counter
	dc.b	$0E,$10
* 		ld	IX,CCB
	dc.b	$DD,$21,$80,$1B
* 		ld	HL,PATCHDATA
	dc.b	$21,$86,$18
* 		ld	(CHPATPTR),HL
	dc.b	$22,$56,$04
* plloop
* 		ld	A,B
	dc.b	$78
* 		cp	(IX+CCBPNUM)
	dc.b	$DD,$BE,$0D
* 		jr	NZ,plloop1
	dc.b	$20,$05
* 		push	BC
	dc.b	$C5
* 		call	FETCHPATCH
	dc.b	$CD,$37,$17
* 		pop	BC
	dc.b	$C1
* plloop1
* 		ld	DE,32
	dc.b	$11,$20,$00
* 		zadd	IX,DE
	dc.b	$DD,$19
* 		ld	DE,39
	dc.b	$11,$27,$00
* 		ld	HL,(CHPATPTR)
	dc.b	$2A,$56,$04
* 		zadd	HL,DE
	dc.b	$19
* 		ld	(CHPATPTR),HL
	dc.b	$22,$56,$04
* 		dec	C
	dc.b	$0D
* 		jr	NZ,plloop
	dc.b	$20,$E3
* 
* 		ret
	dc.b	$C9
* 
* 
* ***************************  Dynamic Voice Allocation ***************************
* 
* 		export	FMVTBL
* 		export	PSGVTBL
* 
* *  FMVTBL - contains (6) 7-byte entires, one per voice:
* *    byte 0: FRLxxVVV	flag byte, where F=free, R=release phase, L=locked, VVV=voice num
* *                       VVV is numbered (0,1,2,4,5,6) for writing directly to key on/off reg
* *    byte 1: priority	only valid for in-use (F=0) voices
* *    byte 2: notenum	    "
* *    byte 3: channel	    "
* *    byte 4: lsb of duration timer (for sequenced notes)
* *    byte 5: msb of duration timer
* *    byte 6: release timer
* 
* 
* FMVTBL		db	080H,0,050H,0,0,0,0		* fm voice 0
	dc.b	$80
	dc.b	$00
	dc.b	$50
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* 		db	081H,0,050H,0,0,0,0		* fm voice 1
	dc.b	$81
	dc.b	$00
	dc.b	$50
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* 		db	084H,0,050H,0,0,0,0		* fm voice 3
	dc.b	$84
	dc.b	$00
	dc.b	$50
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* 		db	085H,0,050H,0,0,0,0		* fm voice 4
	dc.b	$85
	dc.b	$00
	dc.b	$50
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* FMVTBLCH6	db	086H,0,050H,0,0,0,0		* fm voice 5 (supports digital)
	dc.b	$86
	dc.b	$00
	dc.b	$50
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* FMVTBLCH3	db	082H,0,050H,0,0,0,0		* fm voice 2 (supports CH3 poly mode)
	dc.b	$82
	dc.b	$00
	dc.b	$50
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* 		db	0FFH
	dc.b	$FF
* 
* PSGVTBL		db	080H,0,050H,0,0,0,0		* normal type voice, number 0
	dc.b	$80
	dc.b	$00
	dc.b	$50
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* 		db	081H,0,050H,0,0,0,0		* normal type voice, number 1
	dc.b	$81
	dc.b	$00
	dc.b	$50
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* PSGVTBLTG3	db	082H,0,050H,0,0,0,0		* normal type voice, number 2
	dc.b	$82
	dc.b	$00
	dc.b	$50
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* 		db	0FFH
	dc.b	$FF
* 
* PSGVTBLNG	db	083H,0,050H,0,0,0,0		* noise type voice, number 3
	dc.b	$83
	dc.b	$00
	dc.b	$50
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00
* 		db	0FFH
	dc.b	$FF
* 
* 
* *  ALLOC     - dynamic voice allocation routine
* *  ALLOCSPEC - special entry point for only allocating or not the single voice at (IY)
* *
* *	parameters:	B	channel
* *			IX	pointer to this channel's CCB
* *			IY	first entry in appropriate voice table
* *
* *	uses:		?????
* *
* *	returns:	A	flags of voice allocated, or FF if none allocated
* *			HL	pointer to entry allocated
* 
* avlowestp	dw	0			* pointer to lowest priority
	dc.b	$00
	dc.b	$00
* avfreestp	dw	0			* pointer to longest free
	dc.b	$00
	dc.b	$00
* 
* VTBLFLAGS	equ	0
* VTBLPRIO	equ	1
* VTBLCH		equ	3
* VTBLDL		equ	4
* VTBLDH		equ	5
* VTBLRT		equ	6
* 
* ALLOC
* 
* *	call	DACME
* *	push	IY
* *	pop	HL
* *	ld	A,(HL)
* *	ret
* 
* 		ld	C,0FFH			* C <- lowest prio so far (max actually 7FH)
	dc.b	$0E,$FF
* 		ld	L,0FFH			* L <- freest so far (max actually 0FE)
	dc.b	$2E,$FF
* 		ld	DE,7			* for incrementing HL to next entry
	dc.b	$11,$07,$00
* 		ld	H,(IX+CCBFLAGS)		* bit 7 is sustain
	dc.b	$DD,$66,$06
* 		jr	avstart
	dc.b	$18,$02
* avloop
* 		zadd	IY,DE			* point to next entry
	dc.b	$FD,$19
* avstart
* 
* 	call	DACME
	dc.b	$CD,$B7,$02
* 
* 		ld	A,(IY+VTBLFLAGS)
	dc.b	$FD,$7E,$00
* 		cp	0FFH			* end of table?
	dc.b	$FE,$FF
* 		jr	Z,aveot			*   yes - look into taking an in use voice
	dc.b	$28,$31
* 		bit	5,A			* channel locked?
	dc.b	$CB,$6F
* 		jr	NZ,avloop		* yup - skip it
	dc.b	$20,$F0
* 		bit	7,A			* check free/used
	dc.b	$CB,$7F
* 		jr	NZ,avfree		*
	dc.b	$20,$0D
* 
* 		ld	A,(IY+VTBLPRIO)		* in use - check priority against lowest so far
	dc.b	$FD,$7E,$01
* 		cp	C			* lower than lowest so far?
	dc.b	$B9
* 		jr	NC,avloop
	dc.b	$30,$E6
* 		ld	C,A			* yes - so make this lowest
	dc.b	$4F
* 		ld	(avlowestp),IY
	dc.b	$FD,$22,$DA,$17
* 		jr	avloop
	dc.b	$18,$DF
* avfree
* 		ld	A,(IY+VTBLCH)		* its free - same channel is requester?
	dc.b	$FD,$7E,$03
* 		cp	B
	dc.b	$B8
* 		jr	NZ,avdiffch
	dc.b	$20,$09
* 		bit	7,H			* yes - sustain on?
	dc.b	$CB,$7C
* 		jr	NZ,avdiffch
	dc.b	$20,$05
* 
* 		push	IY
	dc.b	$FD,$E5
* 		pop	HL
	dc.b	$E1
* 		ld	A,(HL)			* yes return A and HL
	dc.b	$7E
* 		ret
	dc.b	$C9
* avdiffch
* 		ld	A,(IY+VTBLRT)		* freer than freest so far?
	dc.b	$FD,$7E,$06
* 		cp	L
	dc.b	$BD
* 		jr	NC,avloop
	dc.b	$30,$CA
* 		ld	L,A			* yes - so make this the freest
	dc.b	$6F
* 		ld	(avfreestp),IY
	dc.b	$FD,$22,$DC,$17
* 		jr	avloop
	dc.b	$18,$C3
* aveot
* 		ld	A,L
	dc.b	$7D
* 		cp	0FFH			* any found free?
	dc.b	$FE,$FF
* 		jr	Z,avtakeused
	dc.b	$28,$05
* 		ld	HL,(avfreestp)		* yes take freest
	dc.b	$2A,$DC,$17
* 		ld	A,(HL)
	dc.b	$7E
* 		ret
	dc.b	$C9
* avtakeused
* 		ld	A,C			* no free ones - check lowest so far priority
	dc.b	$79
* avspecprio
* 		cp	(IX+CCBPRIO)		* compare to priority of this channel
	dc.b	$DD,$BE,$1C
* 		jr	Z,avtakeit
	dc.b	$28,$05
* 		jr	C,avtakeit		* this channel >= lowest priority
	dc.b	$38,$03
* 		ld	A,0FFH			* failed to allocate
	dc.b	$3E,$FF
* 		ret
	dc.b	$C9
* avtakeit
* 		ld	HL,(avlowestp)
	dc.b	$2A,$DA,$17
* 		ld	A,(HL)
	dc.b	$7E
* 		ret
	dc.b	$C9
* 
* ALLOCSPEC
* 
* 	call	DACME
	dc.b	$CD,$B7,$02
* 
* *	push	IY
* *	pop	HL
* *	ld	A,(HL)
* *	ret
* 
* 		ld	A,(IY+VTBLFLAGS)	* here to only try to allocate the voice at (IY)
	dc.b	$FD,$7E,$00
* 		bit	7,A			* free?
	dc.b	$CB,$7F
* 		jr	Z,avspecused
	dc.b	$28,$04
* 		push	IY
	dc.b	$FD,$E5
* 		pop	HL
	dc.b	$E1
* 		ret				* yes - take it
	dc.b	$C9
* avspecused
* 		ld	A,(IY+VTBLPRIO)		* no - have to check priority first
	dc.b	$FD,$7E,$01
* 		ld	(avlowestp),IY
	dc.b	$FD,$22,$DA,$17
* 		jr	avspecprio
	dc.b	$18,$DA
* 
* 
* *  DEALLOC - deallocate a voice by searching for a match on notenum and channel.
* *    for now - for digital do nuthing
* *    if release timer (byte 6) is zero, then set free bit immediately, otherwise
* *    set release bit (a 60 Hz routine will count this down and set free when its zero)
* *
* *	parameters:	B	channel
* *			C	note
* *			IX	top of voice table
* *
* *	uses:		D,E,H
* *
* *	returns:	A	flags byte of deallocated voice, or
* *				  0FFH if note not found
* 
* DEALLOC
* 		ld	DE,7
	dc.b	$11,$07,$00
* 		jr	dvstart
	dc.b	$18,$02
* dvloop
* 		zadd	IX,DE
	dc.b	$DD,$19
* dvstart
* 		ld	A,(IX+0)		* get flags
	dc.b	$DD,$7E,$00
* 		ld	H,A			* save em
	dc.b	$67
* 		cp	0FFH
	dc.b	$FE,$FF
* 		ret	Z			* eot - return FF in A for not found
	dc.b	$C8
* 		bit	7,A
	dc.b	$CB,$7F
* 		jr	NZ,dvloop		* if if free skip this voice
	dc.b	$20,$F3
* 		ld	A,(IX+2)
	dc.b	$DD,$7E,$02
* 		cp	C
	dc.b	$B9
* 		jr	NZ,dvloop		* did note match?
	dc.b	$20,$ED
* 		ld	A,(IX+3)
	dc.b	$DD,$7E,$03
* 		cp	B			* yes - check channel
	dc.b	$B8
* 		jr	NZ,dvloop
	dc.b	$20,$E7
* 
* 		ld	A,H
	dc.b	$7C
* 		zand	27H			* check for digital - locked and voice num=6
	dc.b	$E6,$27
* 		cp	26H
	dc.b	$FE,$26
* 		jr	Z,deallocdig
	dc.b	$28,$07
* 
* 		zand	027H			* keep lock and vnum
	dc.b	$E6,$27
* 		zor	0C0H			* set free and release
	dc.b	$F6,$C0
* 
* 		ld	(IX+0),A		* save flags
	dc.b	$DD,$77,$00
* 
* deallocdig
* 		ld	A,H
	dc.b	$7C
* 		ret
	dc.b	$C9
* 
* 
* 		export	Z80End
* Z80End
* 
* **************************************  DATA AREA  ***************************************
* 
* 		export	PATCHDATA
* PATCHDATA
* 
* 
* EOPATCHDATA	equ	PATCHDATA + (39*16)
* 
* *STACKINIT-(patchdata=39*16) = $18B0
* 
* STACKINIT	equ	$1B20			* inialize stack pointer right below here
* MBOXES		equ	$1B20			* 32 bytes for mail boxes
* CMDFIFO		equ	$1B40			* command fifo - 64 bytes
* CCB		equ	$1B80			* CCB - 512 bytes
* CH0BUF		equ	$1D80			* channel cache - 256 bytes
* ENV0BUF		equ	$1E80			* envelope buffers - 128 bytes
* DACFIFO		equ	$1F00			* DAC data FIFO - 256 bytes

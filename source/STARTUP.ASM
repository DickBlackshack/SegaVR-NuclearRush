*
*	Startup Code.
*

	INCLUDE	equates.inc
	INCLUDE	segalib.inc
	INCLUDE	variable.inc
	INCLUDE	sega.i

WCES94	equ	1		; Winter '94 CES kludges...

	OPT	LLBL


	XDEF  __exit

	XREF	load_tbl,_main
	XREF	VDPSlaves,CellMapCols,CellMapRows

	XDEF	_SYS_HARDWARE		; Genesis Hardware Version Number

	BSECTION	.bss
_SYS_HARDWARE	ds.w	1

	TSECTION	.text

*************************************************************************
*
*	All exception vectors:
*
*************************************************************************

		DS.L	0		; Alignment
INITSTK:	DC.L	$00000000	; Stack address
INITPC:		DC.L	START		; Program start address
		DC.L	Buserr
		DC.L	Addrerr
		DC.L	Ilglinst
		DC.L	Zdivide
		DC.L	Chkreg
		DC.L	Overflow
		DC.L	Privviol
		DC.L	Uninitv
		DS.B	16*4
AUTO_2:		DC.L	ExtInt
		DS.B	4
AUTO_4:		DC.L	Hint
		DS.B	4
AUTO_6:		DC.L	Vblank
		DS.B	$88-4

*************************************************************************
*
*	The SEGA header:
*
*************************************************************************

*		 0        1         2         3         4         5
*		 12345678901234567890123456789012345678901234567890
	DC.B	'SEGA GENESIS    '
	DC.B	'(C)SEGA 1993.AUG'
	DC.B	'NUCLEAR RUSH                                    '
	DC.B	'NUCLEAR RUSH                                    '
	DC.B	'GM MK-1831-00 '
	DC.W	0
	DC.B	'J               '
	DC.L	$00000000
	DC.L	$00200000
	DC.L	$FFFF0000
	DC.L	$FFFFFFFF
	DC.B	'            '
	DC.B	'            '
	DC.B	'                                        '
	DC.B	'U               '

*
*
*		MEGA DRIVE hard initial program
*
*				1990 6/6
*			R/D 5 
*
*	++++++++++++++++++++++++++++++++++++++++++++++++++
*	+	status of MEGA_DRIVE on program_finished +
*	++++++++++++++++++++++++++++++++++++++++++++++++++
*
*	****************** 68000 *******************
*	--------- CAUTION -----------
*	When program end
*	* 68000  set RESET to Z80 ($A11100=0,$A11200=$000)
*	* Z80 wait [ JP  (HL)  ] command ( HL=0000 )
*
*   *************************************************************
*   *								*
*   *	ICD_END is GAME_PROGRAM start_address			*
*   *  	ICD_END = START+$100					*
*   *	this program size is just 256 byte.			*
*   *								*
*   *************************************************************

;program start
START:
		tst.l	$a10008		; power on check cntl_A,cntl_B
		bne.s	h_s		; reset hot_start
		tst.w	$a1000c		; power on check cntl_C
h_s:		bne.s	hot_start	; reset hot_start

cold_start:				; power on (cold_start)
		lea.l	reg_set(pc),a5	;register set table
		movem.w (a5)+,d5-d7	; d5/d6/d7
		movem.l (a5)+,a0-a4	; a0-a5

security:				; ** a1=$a11100 **
		move.b	-$10ff(a1),d0	;-$1101(a1)=$a10000
		andi.b	#$000f,d0	;Ver.No check
		beq.s	japan
		move.l	#'SEGA',$2f00(a1)
* security part move "SEGA"
japan:					; $2F00(A1)=$A14000
reg_ini:
		move	(a4),d0		;VDP STATUS DUMMY READ (D5=$8000)
		moveq	#0,d0		; D0 set   0
		move.l	d0,a6		; A6 $00000000
		move.l	a6,usp		; User Stack Pointer
		moveq	#23,d1		; D1 count VDP_command
r_ini1:
		move.b	(a5)+,d5	;REG 0-23 SET (DMA FILL SET)
		move.w	d5,(a4)		;
		add	d7,d5		; d7=$100
		dbra	d1,r_ini1

dma_fill:				;already set REG#18,19,23
		move.l	(a5)+,(a4)	;dma fill(VDP_VRAM CLEAR)
		move	d0,(a3)		;fill data set $0,$C00000

z80_clr:				;Z80 self_initial
		move	d7,(a1)		; Z80_BUSREQ ON
		move	d7,(a2)		; Z80_RESET  OFF
z801:		btst	d0,(a1)		; Z80_BGACK  CHECK ?
		bne.s	z801
		moveq	#37,d2		; D2 is Z80_program's size
z802:		move.b	(a5)+,(a0)+	; move.B (z80_prg)+,($a00000)+
		dbra	d2,z802
		move	d0,(a2)		; Z80_RESET  ON
		move	d0,(a1)		; Z80_BUSREQ OFF
		move	d7,(a2)		; Z80_RESET  OFF(Z80 start)

clr_wk:					;A6=$0 D0=$0 D6=$3FFF
c_wk1:		move.l	d0,-(a6)	;wrok ram clear
		dbra 	d6,c_wk1	;

clr_col		move.l	(a5)+,(a4)	;VDP REG#1=04,#15=02
		move.l	(a5)+,(a4)	;a3=$c00000 a4=$c00004 d0=$0
		moveq	#$1f,d3		; d3 is color_ram's size/2(WORD)
c_col1:		move.l	d0,(a3)		;vdp_color clear
		dbra	d3,c_col1

clr_vsc:	move.l	(a5)+,(a4)	;a3=$c00000 a4=$c00004 d0=$0
		moveq	#19,d4		; d4 count Vscroll_ram
c_vsc1:		move.l	d0,(a3)		;vdp_vscroll clear
		dbra	d4,c_vsc1

clr_psg:	moveq	#3,d5		; d5 is byte_size of PSG init_DATA
c_psg1:		move.b	(a5)+,$11(a3)	;PSG_SOUND clear
		dbra	d5,c_psg1

		move	d0,(a2)		;Z80 RESET
		movem.l	(a6),d0-d7/a0-a6	;register all initial
		move	#$2700,sr	;68000 register initial 
hot_start:
		bra.s	chk_vdp		;
init_end:

reg_set:
	dc.w	$008000,$003fff,$000100			;d5/d6/d7
	dc.l	$a00000,$a11100,$a11200,$c00000		;a0-a3
	dc.l	$c00004					;a4

vreg_dt:
	dc.b	$04,$14,$30,$3c,$07,$6c,$00,$00		;VDP REG #0-7
	dc.b	$00,$00,$ff,$00,$81,$37,$00,$01		;VDP_REG #8-15
	dc.b	$01,$00,$00,$ff,$ff,$00,$00,$80		;VDP_REG #16-23
dma_fill_data:
	dc.l	$40000080		;dma fill(VDP_VRAM clear)

z80_prg:
	DC.B	$AF			;XOR	A
	DC.B	$01,$D9,$1F		;LD	BC,1FD9H
	DC.B	$11,$27,$00		;LD	DE,0027H
	DC.B	$21,$26,$00		;LD	HL,0026H
	DC.B	$F9			;LD	SP,HL
	DC.B	$77			;LD	(HL),A
	DC.B	$ED,$B0			;LDIR
	DC.B	$DD,$E1			;POP	IX
	DC.B	$FD,$E1			;POP	IY
	DC.B	$ED,$47			;LD	I,A
	DC.B	$ED,$4F			;LD	R,A
	DC.B	$D1			;POP	DE
	DC.B	$E1			;POP	HL
	DC.B	$F1			;POP	AF
	DC.B	$08			;EX	AF,AF'
	DC.B	$D9			;EXX
	DC.B	$C1			;POP	BC
	DC.B	$D1			;POP	DE
	DC.B	$E1			;POP	HL
	DC.B	$F1			;POP	AF
	DC.B	$F9			;LD	SP,HL
	DC.B	$F3			;DI
	DC.B	$ED,$56			;IM1
	DC.B	$36,$E9			;LD	(HL),$E9='JP (HL)'
	DC.B	$E9			;JP	(HL)
new_reg_data:
	dc.l	$81048f02		;VDP REG#1=04,#15=02
clr_col_data:
	dc.l	$c0000000		;color_ram address data
clr_vsc_data:
	dc.l	$40000010		;v_scroll ram address data

psg_dat:
	DC.B	$9F,$BF,$DF,$FF		;PSG initial data

chk_vdp:
	tst	$c00004
ICD_END:

*	Sega Lock Out code...
	nop
	bsr	WaitForDMA	; Idiots didn't put this in the lock out code!

	DC.B	$42,$80,$10,$39,$00,$A1,$00,$01,$EC,$08,$02,$00,$00,$03,$41,$FA
	DC.B	$01,$26,$10,$30,$00,$00,$4A,$00,$67,$00,$00,$E4,$41,$F9,$00,$00
	DC.B	$01,$F0,$32,$3C,$00,$0F,$B0,$10,$67,$00,$03,$66,$52,$88,$51,$C9
	DC.B	$FF,$F6,$49,$F9,$00,$C0,$00,$00,$4B,$F9,$00,$C0,$00,$04,$3A,$BC
	DC.B	$81,$64,$3A,$BC,$82,$30,$3A,$BC,$8C,$81,$3A,$BC,$8F,$02,$3A,$BC
	DC.B	$90,$01,$2A,$BC,$C0,$02,$00,$00,$38,$BC,$0E,$EE,$2A,$BC,$40,$00
	DC.B	$00,$00,$41,$FA,$01,$54,$30,$3C,$00,$3A,$24,$3C,$10,$00,$00,$00
	DC.B	$3C,$3C,$00,$07,$12,$18,$28,$3C,$00,$00,$00,$00,$3A,$3C,$00,$07
	DC.B	$E9,$9A,$E2,$19,$64,$02,$88,$82,$51,$CD,$FF,$F6,$28,$84,$51,$CE
	DC.B	$FF,$E4,$51,$C8,$FF,$DC,$12,$3C,$00,$08,$41,$FA,$00,$B2,$10,$18
	DC.B	$61,$00,$00,$5E,$43,$F9,$00,$00,$01,$F0,$0C,$11,$00,$20,$67,$42
	DC.B	$45,$FA,$00,$88,$38,$1A,$4A,$04,$67,$34,$B8,$11,$66,$2C,$0C,$29
	DC.B	$00,$20,$00,$01,$66,$14,$B3,$FC,$00,$00,$01,$F0,$67,$0C,$41,$FA
	DC.B	$00,$9B,$10,$18,$52,$41,$61,$00,$00,$28,$41,$FA,$00,$5A,$D1,$DA
	DC.B	$10,$18,$52,$41,$61,$00,$00,$1A,$60,$04,$58,$8A,$60,$C6,$52,$89
	DC.B	$60,$B8,$41,$FA,$00,$7A,$10,$18,$52,$41,$61,$00,$00,$04,$60,$FE
	DC.B	$14,$01,$02,$82,$00,$00,$00,$FF,$48,$42,$EF,$8A,$16,$00,$02,$83
	DC.B	$00,$00,$00,$FF,$48,$43,$E3,$83,$D4,$83,$06,$82,$40,$00,$00,$03
	DC.B	$2A,$82,$4A,$10,$67,$0E,$14,$18,$04,$02,$00,$20,$02,$42,$00,$FF
	DC.B	$38,$82,$60,$EE,$4E,$75,$4A,$00,$55,$45,$00,$4A,$00,$00,$00,$42
	DC.B	$00,$55,$00,$00,$00,$53,$00,$45,$00,$00,$00,$61,$00,$00,$06,$44
	DC.B	$45,$56,$45,$4C,$4F,$50,$45,$44,$20,$46,$4F,$52,$20,$55,$53,$45
	DC.B	$20,$4F,$4E,$4C,$59,$20,$57,$49,$54,$48,$00,$12,$26,$00,$0F,$53
	DC.B	$59,$53,$54,$45,$4D,$53,$2E,$00,$0C,$4E,$54,$53,$43,$20,$4D,$45
	DC.B	$47,$41,$20,$44,$52,$49,$56,$45,$00,$0D,$4E,$54,$53,$43,$20,$47
	DC.B	$45,$4E,$45,$53,$49,$53,$00,$04,$50,$41,$4C,$20,$41,$4E,$44,$20
	DC.B	$46,$52,$45,$4E,$43,$48,$20,$53,$45,$43,$41,$4D,$20,$4D,$45,$47
	DC.B	$41,$20,$44,$52,$49,$56,$45,$00,$00,$00,$00,$00,$00,$00,$00,$00
	DC.B	$18,$18,$18,$18,$00,$18,$18,$00,$36,$36,$48,$00,$00,$00,$00,$00
	DC.B	$12,$12,$7F,$12,$7F,$24,$24,$00,$08,$3F,$48,$3E,$09,$7E,$08,$00
	DC.B	$71,$52,$74,$08,$17,$25,$47,$00,$18,$24,$18,$29,$45,$46,$39,$00
	DC.B	$30,$30,$40,$00,$00,$00,$00,$00,$0C,$10,$20,$20,$20,$10,$0C,$00
	DC.B	$30,$08,$04,$04,$04,$08,$30,$00,$00,$08,$2A,$1C,$2A,$08,$00,$00
	DC.B	$08,$08,$08,$7F,$08,$08,$08,$00,$00,$00,$00,$00,$00,$30,$30,$40
	DC.B	$00,$00,$00,$7F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$30,$30,$00
	DC.B	$01,$02,$04,$08,$10,$20,$40,$00,$1E,$33,$33,$33,$33,$33,$1E,$00
	DC.B	$18,$38,$18,$18,$18,$18,$3C,$00,$3E,$63,$63,$0E,$38,$60,$7F,$00
	DC.B	$3E,$63,$03,$1E,$03,$63,$3E,$00,$06,$0E,$1E,$36,$66,$7F,$06,$00
	DC.B	$7E,$60,$7E,$63,$03,$63,$3E,$00,$3E,$63,$60,$7E,$63,$63,$3E,$00
	DC.B	$3F,$63,$06,$06,$0C,$0C,$18,$00,$3E,$63,$63,$3E,$63,$63,$3E,$00
	DC.B	$3E,$63,$63,$3F,$03,$63,$3E,$00,$00,$18,$18,$00,$00,$18,$18,$00
	DC.B	$00,$18,$18,$00,$00,$18,$18,$20,$03,$0C,$30,$40,$30,$0C,$03,$00
	DC.B	$00,$00,$7F,$00,$7F,$00,$00,$00,$60,$18,$06,$01,$06,$18,$60,$00
	DC.B	$3E,$63,$03,$1E,$18,$00,$18,$00,$3C,$42,$39,$49,$49,$49,$36,$00
	DC.B	$1C,$1C,$36,$36,$7F,$63,$63,$00,$7E,$63,$63,$7E,$63,$63,$7E,$00
	DC.B	$3E,$73,$60,$60,$60,$73,$3E,$00,$7E,$63,$63,$63,$63,$63,$7E,$00
	DC.B	$3F,$30,$30,$3E,$30,$30,$3F,$00,$3F,$30,$30,$3E,$30,$30,$30,$00
	DC.B	$3E,$73,$60,$67,$63,$73,$3E,$00,$66,$66,$66,$7E,$66,$66,$66,$00
	DC.B	$18,$18,$18,$18,$18,$18,$18,$00,$0C,$0C,$0C,$0C,$CC,$CC,$78,$00
	DC.B	$63,$66,$6C,$78,$6C,$66,$63,$00,$60,$60,$60,$60,$60,$60,$7F,$00
	DC.B	$63,$77,$7F,$6B,$6B,$63,$63,$00,$63,$73,$7B,$7F,$6F,$67,$63,$00
	DC.B	$3E,$63,$63,$63,$63,$63,$3E,$00,$7E,$63,$63,$7E,$60,$60,$60,$00
	DC.B	$3E,$63,$63,$63,$6F,$63,$3F,$00,$7E,$63,$63,$7E,$68,$66,$67,$00
	DC.B	$3E,$63,$70,$3E,$07,$63,$3E,$00,$7E,$18,$18,$18,$18,$18,$18,$00
	DC.B	$66,$66,$66,$66,$66,$66,$3C,$00,$63,$63,$63,$36,$36,$1C,$1C,$00
	DC.B	$6B,$6B,$6B,$6B,$6B,$7F,$36,$00,$63,$63,$36,$1C,$36,$63,$63,$00
	DC.B	$66,$66,$66,$3C,$18,$18,$18,$00,$7F,$07,$0E,$1C,$38,$70,$7F,$00

MainEntry:
	nop
   	move.l	#$FFFF0000,a0
	move.w	#65536/4-1,d1
	moveq	#0,d0
sl_clr:	move.l	d0,(a0)+
	dbra	d1,sl_clr	;clear all of the work RAM (NB. will clear a stack!)
	jsr	load_tbl
	bsr	ResetHardware	;set up scrolls interrupts etc

	move.w	#$100,Z80Reset	;Z80 reset line high (NORMAL RUN STATE)

	jmp	_main
__exit:	bra	__exit

**************************************************************************
**                SLAVE VDP REGISTERS AND SET UP HARDWARE                *
**************************************************************************
* This sets up 24 WORDS of work RAM as a 'copy' of the VDP registers.
* ICD_BLK4 sets up the hardware in a similar way, without slaving the
* VDP registers, but THIS code does slave the registers in work RAM
* as the VDP has write only registers (status excepted). It also
* enables the display and Vertical interrupts as well as setting up the
* VRAM addresses in the VDP.
*
* Note that with the VRAM containing all 0, this means that all the cell maps
* contain references to cell 0, which in turn consists of 32 bytes containing
* 0, which is a blank character, so the screen will be background coloured.
* In addition, the HScroll table contains the value 0, so the screen is not
* scrolled and the first sprite position is 0 and has link data 0, so no
* sprites are on screen. (Their pattern generator addresses are all space
* character anyway).
*
* Any characters placed on Pattern A or B will be visible.

ResetHardware:
	move.w	#$8104,VCTRL	; Kill display
	bsr	BlackOut	;blank the palette
	move.b	#$00,SCtrl1	; set parallel mode and clear ints (p75)
	move.b	#$00,SCtrl2	; set parallel mode and clear ints (p75)
	move.b	#$00,SCtrl3	; set parallel mode and clear ints (p75)
	move.b	#$40,Ctrl1
	move.b	#$40,Ctrl2
	move.b	#$7F,Ctrl3

	clr	_SYS_HARDWARE	; Get the hardware version number
	move.b	$A10001,_SYS_HARDWARE+1

	lea	InitialVDP,a0	;point to VDP initialization data
	move	#$8000,d0	;register increment
	moveq	#19-1,d1	;count
.loop	move.b	(a0)+,d0
	move	d0,VCTRL
	add.w	#$0100,d0	;increment register
	dbra	d1,.loop	;slave all regs

	move.w	#64,CellMapCols	;set up cell map width
	move.w	#64,CellMapRows	;set up cell map height

	VramWrtAddr  0,VCTRL
	move.w	#65536/4-1,d1
	moveq	#0,d0
.cloop	move.l	d0,VDATA
	dbra	d1,.cloop

	lea	VDPSlaves,a0
	move	#$8000,d0	;register increment
	move	#24-1,d1	;count
.xloop	move	d0,(a0)+
	add.w	#$0100,d0	;increment register
	dbra	d1,.xloop	;slave all regs

*	bsr	ClearVRAM	;clear vram (scrolls, hscroll, sprites, cells)
	bsr	ClearVSRAM
	rts

InitialVDP:
	DC.B	%00000100	; 0 no H interrupt, enable read HV counter
	DC.B	%01110100	; 1 ENABLE display, ENABLE V interrupt, NO DMA, 28CELL HIGH(NTSC)
	DC.B	ScrollA>>10	; 2 Pattern Table A
	DC.B	Window>>10	; 3 Pattern Window
	DC.B	ScrollB>>13	; 4 Pattern Table B
	DC.B	SpriteAttr>>9	; 5 Sprite Attributes
	DC.B	0		; 6 MUST BE 0
	DC.B	%00000000	; 7 Background colour 0 in palette 0
	DC.B	0		; 8 MUST BE 0
	DC.B	0		; 9 MUST BE 0
	DC.B	%11111111	;10 H interrupt divider
	DC.B	%00000100	;11 NO Ext interrupt, 2CELL V scroll, FULL H scroll
	DC.B	%10000001	;12 40CELL WIDE, NO shadow/hilight, NO interlace
	DC.B	HScroll>>10	;13 H Scroll Table    @62K
	DC.B	0		;14 MUST BE 0
	DC.B	%00000010	;15 Autoinc = 2 (i.e. increment by WORD)
	DC.B	%00010001	;16 Scroll size 64 HIGH by 64 WIDE occupies 64*64*2=8K bytes. NB CellMapCols
	DC.B	%00000000	;17 Window H position = 0  \  => NO window
	DC.B	%00000000	;18 Window V position = 0  /

	DS.W	0		; Align

* ERROR EXCEPTION FUNCTIONS - JUST LET US KNOW WHAT WENT WRONG


ErrorVect:
        bra     ErrorVect               ; We point all unhandled exceptions here

	XDEF	_EHInts
_EHInts:
	move.w	#$8014,VCTRL
        move.w  #$2000,SR
        rts

	XDEF	Vblank
*;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
* FUNCTION:     Vblank
* DESCRIPTION:  .
* RETURNS:      .
* PARAMETERS:   .
* SIDE EFFECTS: USES
* REVISIONS:    10/91   -jf-
*;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	XREF	_SYS_VCNT
*	XREF	_SYS_SENDSPRS
	XREF	_RIGHT_SPRLIST
	XREF	_LEFT_SPRLIST

	XREF	_SYS_HARRAY1
	XREF	_SYS_HARRAY2
	XREF	_SYS_HATOGGLE
	XREF	_SYS_HAPTR
	XREF	_SYS_SCROLLX
	XREF	_SYS_SCRLXB		; Scroll for Screen B
	XREF	_SYS_FLICKER
	XREF	_SYS_DOHEADSET
	XREF	_SYS_MINFDIST
	XREF	_SYS_AVGFDIST

	XREF	_CHR_1video_addr
	XREF	_CHR_1length
	XREF	_CHR_1src_addr
	XREF	_CHR_2video_addr
	XREF	_CHR_2length
	XREF	_CHR_2src_addr
	XREF	_CHR_3video_addr
	XREF	_CHR_3length
	XREF	_CHR_3src_addr

	XREF	_SPR_Video_Addr
	XREF	_SPR_Llength
	XREF	_SPR_Lsrc_addr
	XREF	_SPR_Rlength
	XREF	_SPR_Rsrc_addr
	XREF	_SPR_NLlength
	XREF	_SPR_NLsrc_addr
	XREF	_SPR_NRlength
	XREF	_SPR_NRsrc_addr

	XREF	_SYS_HORZCHRS
	XREF	_SYS_HORIZON
	XREF	_SYS_HORZLEN

	XREF	_Player_Fuel

	XREF	_SYS_DCLISTAVL		; List ready to send
	XREF	_SYS_DCLISTLEN		; List length
	XREF	_SYS_DCLIST		; Data or Ctrl flags
	XREF	_SYS_DCDATA		; WORDs to send
	XREF	_SYS_VSCROLL

	IFNE	WCES94
	XREF	_SYS_VR_MODE		; For WCES '94
	ENDC

	XREF	heap_org
	XREF	_HMD_DATA

	XDEF	_SYS_DOCYCLE
	XDEF	_SYS_SAFEDMA
	XDEF	_SYS_NODMA
	XDEF	_SYS_NEWXA
	XDEF	_SYS_NEWXB
	XDEF	_SYS_VLINE
	XDEF	_SYS_READHEAD
	XDEF	_SYS_HMD_DATA
	XDEF	_SYS_HMD_ERROR

	BSECTION	.bss
_SYS_HFLAG	ds.w	1
_DISP_LEFT	ds.w	1
_SYS_DOCYCLE	ds.w	1	; Color Cycle Yello in 4th Palette
_SYS_NODMA	ds.w	1	; Don't do any DMA...
_SYS_SAFEDMA	ds.w	1	; Flag to say "safe to DMA"
_SYS_NEWXA	ds.w	1	; New X scroll from plane A
_SYS_NEWXB	ds.w	1	; New X scroll from plane B
_SYS_VLINE	ds.w	1	; VCounter AFTER VBlank
_SYS_READHEAD	ds.w	1	; Read the headset?
_SYS_HMD_DATA	ds.l	1	; Headset Data
_SYS_HMD_ERROR	ds.l	1	; Headset Error

	XDEF	_RLEScaleCode
	XDEF	_RLESAddr
	XDEF	_RLEDAddr
	XDEF	_RLEJAddr
	XDEF	_RLEMoves

* RLE Scaling Code variables:
_RLEScaleCode	ds.w	1	; movea.l	#$12345678,a0
_RLESAddr	ds.l	1	; Address to be loaded into A0
		ds.w	1	; movea.l	#$12345678,a1
_RLEDAddr	ds.l	1	; Address to be loaded into A1
		ds.w	1	; jmp      #$xxxxxxxx
_RLEJAddr	ds.l	1	; Address to jump to
_RLEMoves	ds.w	256*4	; Rest of code to generate a scanline

	TSECTION	.text


YellowCycle:			; Color Register #51
	DC.W	$00EE,$00CC,$00AA,$0088,$0066,$0044,$0022,$0000
	DC.W	$0000,$0022,$0044,$0066,$0088,$00AA,$00CC,$00EE

Vblank:
*	btst.b	#0,_SYS_VCNT+3
*	beq.s	.leftx
** Display Right Data
*	move.b	#0,_DISP_LEFT
*	move.b	#2,PPDATA
*	bra.s	.sendx
** Display Left Data
*.leftx	move.b	#$FF,_DISP_LEFT
*	move.b	#1,PPDATA
*.sendx:
	movem.l	d0-d7/a0-a6,-(a7) ;save all registers
	add.l	#1,_SYS_VCNT
	st	FlyBackFlag	;flag VBLANK interrupt happened

	IFNE	WCES94

* Handle flickering
	move.w	_SPR_Video_Addr,d0
	btst.b	#0,_SYS_FLICKER
	beq.s	.showLeft
* xxxx|xxxx|xxxx|L R X8 Y8|X7 X6 X5 X4|X3 X2 X1 X0|Y7 Y6 Y5 Y4|Y3 Y2 Y1 Y0
	move.l	_SYS_HMD_DATA,d2
	andi.l	#$000C0000,d2
	cmp.w	#1,_SYS_VR_MODE		; Head Trak Normal Flicker?
	bne.s	.ces2
	eori.l	#$000C0000,d2
	bra.s	.cesT
.ces2	cmp.w	#2,_SYS_VR_MODE		; Head Trak Invert Flicker?
	bne.s	.ces3
.cesT	clr	_DISP_LEFT
	cmpi.l	#$00080000,d2
	seq	_DISP_LEFT
.ces3	tst	_DISP_LEFT
	beq.s	.showLeft
	move.w	_SPR_Rlength,d1
	beq.s	.doScroll
	move.l	_SPR_Rsrc_addr,a0
	bsr	CopyToVRAM
	sf	_DISP_LEFT
	bra.s	.doScroll
.showLeft
	st	_DISP_LEFT
	move.w	_SPR_Llength,d1
	beq.s	.doScroll
	move.l	_SPR_Lsrc_addr,a0
	bsr	CopyToVRAM

	ELSEC

* Handle flickering
	move.w	_SPR_Video_Addr,d0
	btst.b	#0,_SYS_FLICKER
	beq.s	.showLeft
	tst	_DISP_LEFT
	beq.s	.showLeft
	move.w	_SPR_Rlength,d1
	beq.s	.doScroll
	move.l	_SPR_Rsrc_addr,a0
	bsr	CopyToVRAM
	sf	_DISP_LEFT
	bra.s	.doScroll
.showLeft
	st	_DISP_LEFT
	move.w	_SPR_Llength,d1
	beq.s	.doScroll
	move.l	_SPR_Lsrc_addr,a0
	bsr	CopyToVRAM

	ENDC

* Update X scroll value safely
.doScroll
	move.w	#$8F02,VCTRL		; Set autoinc to 2
	VramWrtAddr  HScroll,VCTRL
	move	_SYS_SCROLLX,d0
	move	_SYS_SCRLXB,d1
	tst.b	_SYS_FLICKER
	beq.s	.fhx
	tst	_DISP_LEFT
	bne.s	.fhl
	sub.w	_SYS_MINFDIST,d0
*	move.w	_SYS_AVGFDIST,d1
*	neg	d1
	bra.s	.fhx
.fhl	add.w	_SYS_MINFDIST,d0
*	move.w	_SYS_AVGFDIST,d1
.fhx	move.w	d0,VDATA		; Flicker Scroll Screen A
	move.w	d1,VDATA		; Flicker Scroll Screen B
*  DMA First set of characters...
.CHR1DMA
	tst	_SYS_NODMA		; Should we try any DMA?
	bne	.exitDMA
	move.w	_CHR_1length,d1
	beq.s	.CHR2DMA
	move.w	_CHR_1video_addr,d0
	move.l	_CHR_1src_addr,a0
	bsr	CopyToVRAM
	move.w	#0,_CHR_1length
	move	VDPHVCount,_SYS_VLINE	; For debugging
	bra	.exitDMA
.CHR2DMA
	move.w	_CHR_2length,d1
	beq.s	.CHR3DMA
	move.w	_CHR_2video_addr,d0
	move.l	_CHR_2src_addr,a0
	bsr	CopyToVRAM
	move.w	#0,_CHR_2length
	bra	.exitDMA
.CHR3DMA
	move.w	_CHR_3length,d1		; sprite attribute table is last
	beq.s	.HORZDMA
	move.w	_CHR_3video_addr,d0
	move.l	_CHR_3src_addr,a0
	bsr	CopyToVRAM
	move.w	#0,_CHR_3length
	bra	.exitDMA
.HORZDMA
	move.w	_SYS_HORZLEN,d1		; Send Horizon characters?
	beq.s	.doneDMA
	move.w	_SYS_HORZCHRS,d0
	lea	_SYS_HORIZON,a0
	bsr	CopyToVRAM
	move.w	#0,_SYS_HORZLEN
.doneDMA
* Copy new pointers after DMA is finished
	tst	_SYS_SAFEDMA			; Only update once per frame
	bne.s	.exitDMA
	move	_SPR_NRlength,_SPR_Rlength
	move.l	_SPR_NRsrc_addr,_SPR_Rsrc_addr
	move	_SPR_NLlength,_SPR_Llength
	move.l	_SPR_NLsrc_addr,_SPR_Lsrc_addr
	move	_SYS_NEWXA,_SYS_SCROLLX		; Update scroll values
	move	_SYS_NEWXB,_SYS_SCRLXB

	move.l	#$40000010,VCTRL		; Update Y Scroll values
	lea	_SYS_VSCROLL,a0
	move	#19,d0
.adjvs	move	(a0)+,VDATA
	move	#0,VDATA
	dbra	d0,.adjvs

	st	_SYS_SAFEDMA
.exitDMA
* Do games VDP Data/Ctrl list updating...
	tst	_SYS_DCLISTAVL
	beq.s	.nolist
	move	_SYS_DCLISTLEN,d0
	beq.s	.nolist
	lea	_SYS_DCLIST,a0
	lea	_SYS_DCDATA,a1
	sub	#1,d0
.listlp	tst.b	(a0)+
	bne.s	.listd
	move.w	(a1)+,VCTRL
	bra.s	.listt
.listd	move.w	(a1)+,VDATA
.listt	dbra	d0,.listlp
	move	#0,_SYS_DCLISTLEN
.nolist	bsr	ScanJoy1	;scan joystick
	tst	_SYS_READHEAD
	bne.s	.updFuel
	bsr	ScanJoy2	;scan other joystick
* Update players fuel
.updFuel
	move.l	_SYS_VCNT,d0
	and	#$03FF,d0
	bne.s	.cyc
	sub	#1,_Player_Fuel
* Update Yellow Color Cycle if we need to
.cyc	tst	_SYS_DOCYCLE
	beq.s	.rexit
	moveq	#(3*16+3)*2,d0	;CRAM palette 3, color 3
	bsr	SetCRAMWrite	;set write to CRAM
	move.l	_SYS_VCNT,d0
	and	#$1E,d0
	lea	YellowCycle,a0
	move	0(a0,d0),VDATA
.rexit	
* Do headset read, if needed
	tst	_SYS_READHEAD
	beq.s	.bye
	btst.b	#0,_SYS_VCNT+3		; Only read the headset and 30Hz
	beq.s	.bye
	jsr	_HMD_DATA
	move.l	d0,_SYS_HMD_DATA
.bye	movem.l	(a7)+,d0-d7/a0-a6 ;get old registers
        rte

	XDEF	Hint
*;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
* FUNCTION:     Hint
* DESCRIPTION:  .
* RETURNS:      .
* PARAMETERS:   .
* SIDE EFFECTS: USES
* REVISIONS:    10/91   -jf-
*;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

*	DS.W	Color value
*	DS.W	Next horizontal line interrupt

Hint:
	tst	_SYS_HFLAG	; Change Interrupt counter?
	bne.s	HInorm
	move.w	#$8A01,VCTRL	; Interrupt changed to every other line
	move.w	#1,_SYS_HFLAG
	bra.s	HIexit		; Return back to program
HInorm	movem.l	d0/a0,-(a7)
	move.l	_SYS_HAPTR,a0
	move.w	#$8F04,VCTRL	; Set Auto increment to 4
	move.l	#$40000010,VCTRL
	move.w	(a0)+,VDATA
	move.l	a0,_SYS_HAPTR
	movem.l	(a7)+,d0/a0
HIexit	rte

	XDEF	ExtInt
*;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
* FUNCTION:     ExtInt
* DESCRIPTION:  .
* RETURNS:      .
* PARAMETERS:   .
* SIDE EFFECTS: USES
* REVISIONS:    10/91   -jf-
*;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ExtInt:
        rte

* Interrupt numbers.  These numbers are also defined in the standard
* header file <signal.h>.  Any modifications to these numbers *MUST*
* be accompanied by identical modifications to those #defines.

SIGBUS	 EQU 2		; Bus error.
SIGCHK	 EQU 3		; chk instruction exception.
SIGILL	 EQU 5		; Illegal instruction.
SIGOFLOW EQU 7		; Overflow (trapv instruction).
SIGPRIV	 EQU 8		; Privilege violation.
SIGSEGV	 EQU 9		; Address error.
SIGUIV	 EQU 11		; Uninitialized exception vector.
SIGZDIV	 EQU 12		; Divide by zero.

	XREF	__xraise

Buserr:
    movem.l d0-d7/a0-a7,-(sp)	; SIGBUS
    move.l  #SIGBUS,d0		; Set signal #.
    bra.s   L1

Addrerr:
    movem.l d0-d7/a0-a7,-(sp)	; SIGSEGV
    move.l  #SIGSEGV,d0		; Set signal #.
    bra.s   L1

Ilglinst:
    movem.l d0-d7/a0-a7,-(sp)	; SIGILL
    move.l  #SIGILL,d0		; Set signal #.
    bra.s   L1

Zdivide:
    movem.l d0-d7/a0-a7,-(sp)	; SIGZDIV
    move.l  #SIGZDIV,d0		; Set signal #.
    bra.s   L1

Chkreg:
    movem.l d0-d7/a0-a7,-(sp)	; SIGCHK
    move.l  #SIGCHK,d0		; Set signal #.
    bra.s   L1

Overflow:
    movem.l d0-d7/a0-a7,-(sp)	; SIGOFLOW
    move.l  #SIGOFLOW,d0	; Set signal #.
    bra.s   L1

Privviol:
    movem.l d0-d7/a0-a7,-(sp)	; SIGPRIV
    move.l  #SIGPRIV,d0		; Set signal #.
    bra.s   L1

Uninitv:
    movem.l d0-d7/a0-a7,-(sp)	; SIGUIV
    move.l  #SIGUIV,d0		; Set signal #.
L1:
	move.l	d0,-(sp)
	jsr	__xraise	; Call signal interface function
	addq.w	#4,sp
    movem.l (sp)+,d0-d7/a0-a7
    rte

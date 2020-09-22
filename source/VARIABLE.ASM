*************************************************************************
*                              VARIABLES                                *
*************************************************************************

	BSECTION	.bss

	XDEF	VDPSlaves
	XDEF	VDP_ModeSet1
	XDEF	VDP_ModeSet2
	XDEF	VDP_PatternA
	XDEF	VDP_Window
	XDEF	VDP_PatternB
	XDEF	VDP_SpriteAttr
	XDEF	VDP_Reg6
	XDEF	VDP_BackCol
	XDEF	VDP_Reg8
	XDEF	VDP_Reg9
	XDEF	VDP_HIntReg
	XDEF	VDP_ModeSet3
	XDEF	VDP_ModeSet4
	XDEF	VDP_HScroll
	XDEF	VDP_Reg14
	XDEF	VDP_AutoInc
	XDEF	VDP_ScrollSize
	XDEF	VDP_WindowHPos
	XDEF	VDP_WindowVPos
	XDEF	DMASlaves
	XDEF	VDP_DMALenLo
	XDEF	VDP_DMALenHi
	XDEF	VDP_DMASrcLo
	XDEF	VDP_DMASrcMid
	XDEF	VDP_DMASrcHi

	XDEF	FlyBackFlag
	XDEF	_SYS_JoyHit
	XDEF	KeyHit
	XDEF	_SYS_JoyTable
	XDEF	_SYS_Joy2Table
	XDEF	KeyTab1
	XDEF	KeyTab2
	XDEF	CellMapCols
	XDEF	CellMapRows
	XDEF	DMATemp
	XDEF	_PalBuffer
	XDEF	PalBuffer
	XDEF	PalTemp

	ds.w	0	; Align
	XDEF	_VdpShadow
_VdpShadow:
VDPSlaves:	ds.b	1
VDP_ModeSet1	ds.b	1
		ds.b	1
VDP_ModeSet2	ds.b	1
		ds.b	1
VDP_PatternA	ds.b	1
		ds.b	1
VDP_Window	ds.b	1
		ds.b	1
VDP_PatternB	ds.b	1
		ds.b	1
VDP_SpriteAttr	ds.b	1
		ds.b	1
VDP_Reg6	ds.b	1
		ds.b	1
VDP_BackCol	ds.b	1
		ds.b	1
VDP_Reg8	ds.b	1
		ds.b	1
VDP_Reg9	ds.b	1
		ds.b	1
VDP_HIntReg	ds.b	1
		ds.b	1
VDP_ModeSet3	ds.b	1
		ds.b	1
VDP_ModeSet4	ds.b	1
		ds.b	1
VDP_HScroll	ds.b	1
		ds.b	1
VDP_Reg14	ds.b	1
		ds.b	1
VDP_AutoInc	ds.b	1
		ds.b	1
VDP_ScrollSize	ds.b	1
		ds.b	1
VDP_WindowHPos	ds.b	1
		ds.b	1
VDP_WindowVPos	ds.b	1
DMASlaves:	ds.b	1

*		ds.w	0
*DMASlaves:
VDP_DMALenLo	ds.b	1
		ds.b	1
VDP_DMALenHi	ds.b	1
		ds.b	1
VDP_DMASrcLo	ds.b	1
		ds.b	1
VDP_DMASrcMid	ds.b	1
		ds.b	1
VDP_DMASrcHi	ds.b	1

FlyBackFlag	ds.w	1
_SYS_JoyHit:
KeyHit		ds.w	1
_SYS_JoyTable:
KeyTab1		ds.b	16
_SYS_Joy2Table:
KeyTab2		ds.b	16
CellMapCols	ds.w	1
CellMapRows	ds.w	1
DMATemp		ds.l	1

_PalBuffer:
PalBuffer	ds.b	128
PalTemp		ds.b	128


*******************************************************************************
* VRrev3.S	-	GENESIS VR Hat Tracker related routines
*
* ver:		3.6(12/28/93) (based on 3rd rev of the protocol)
*			modified for old ONOSENDAI
*	author:	Unni Pillai (SOA)
*
* MODS:
*	Copyright (c)	SEGA OF AMERICA INC.
*	All Rights Reserved
*	UP 4/93     start 4/29
*	up 05/05/93
*	up 07/28/93 new routines HMD_INIT_RDY & HMD_DATA
*	up 08/10/93-08/19/93
*	up 10/13/93
*	up 12/14/93 included equate.s
*	up 12/21/93 made I/O lines = hi upon crash exits
*	up 12/28/93 added delay=5seconds before IDLE after RESET(in HMD_RESET)
*********************************************************************************

        section .bss

        XDEF    _HeadID,_HeadX,_HeadY
	XDEF	_ferror,_fidle,_freset,_ftimeout

_HeadID:	ds.w	1	; Headset ID code
_HeadX:		ds.w	1	; Headset X data
_HeadY:		ds.w	1	; Headset Y data

HT_ID:		ds.b	1
_ferror:	ds.b	1
_fidle:		ds.b	1
_freset:	ds.b	1
_ftimeout:	ds.b	1
HT_LRXY:	ds.b	1
HT_XHIGH:	ds.b	1
HT_XLOW:	ds.b	1
HT_YHIGH:	ds.b	1
HT_YLOW:	ds.b	1

		ds.w	0	; Align to word boundary

        section .text

CvtValues:
	moveq.l	#0,d0
	moveq.l	#0,d1
	move.b	HT_LRXY,d0		; Get X
	andi	#2,d0
	lsl	#7,d0
	move.b	HT_XHIGH,d1
	andi	#$F,d1
	lsl	#4,d1
	or	d1,d0
	move.b	HT_XLOW,d1
	andi	#$F,d1
	or.b	d1,d0
	move	d0,_HeadX
	moveq.l	#0,d0
	moveq.l	#0,d1
	move.b	HT_LRXY,d0		; Get Y
	andi	#1,d0
	lsl	#8,d0
	move.b	HT_YHIGH,d1
	andi	#$F,d1
	lsl	#4,d1
	or	d1,d0
	move.b	HT_YLOW,d1
	andi	#$F,d1
	or.b	d1,d0
	btst	#8,d0
	beq.s	plus
	or	#$FE00,d0
plus	move	d0,_HeadY
	rts

***
*	_ReadHead:	Read X and Y position data from Headset
***

	XDEF    _ReadHead
_ReadHead:
	movem.l	d1-d7/a0-a5,-(sp)
	clr.b	_ferror
	clr.b	_fidle
	clr.b	_ftimeout
	bsr	_HT_DTGET
	tst.b	_ferror
	bne.s	rexit
	tst.b	_fidle
	bne.s	rexit
	tst.b	_ftimeout
	bne.s	rexit
	bsr	CvtValues
rexit	movem.l	(sp)+,d1-d7/a0-a5
	rts

***
*	_InitHead:	Initialize the Headset
***

        XDEF    _InitHead
_InitHead:
	movem.l	d1-d7/a0-a5,-(sp)
	clr.b	_ferror
	clr.b	_fidle
	clr.b	_ftimeout
	clr.b	HT_ID
	bsr	_HT_INIT
	bsr	_HT_INIT_RDY
	tst	d0
	bne.s	iexit
	tst.b	_ferror
	bne.s	iexit
	tst.b	_fidle
	bne.s	iexit
	tst.b	_ftimeout
	bne.s	iexit
	bsr	CvtValues
	moveq.l	#0,d0
iexit	movem.l	(sp)+,d1-d7/a0-a5
	rts


HDATA	equ	$A10005
HCTRL	equ	$A1000B
th_bit	equ	6
tr_bit	equ	5
tl_bit	equ	4
timeout	equ	$cff

wait		move.w	#$ffff,d5   	; delay counter
delay_disp	dbra	d5,delay_disp
		rts

*******************************************************************************
*	HMD_INIT_RDY	Head Tracker Initialization routine
*
*		INITIALIZES THE HEAD TRACKER
*		THIS ROUTINE MUST BE THE FIRST ACCESS TO HEAD TRACKER
*		essentially this routine issues RESET to the Head Tracker
*		and reads the corresponding Head Tracker identification ID
*		byte.  Also refer to VR.DOC/VR.TXT
*
*	In:	Nothing.
*	Out:	_SYS_HMD_ERROR.L	Status:
*			0		- Normal
*			1		- Timeout occurred
*			$80000001	- Hardware error
*			$80000002	- Timeout while RESET
*
*
*	REGISTERS:	d0 used for output,
*			d7 destroy
*			d6 destroy
*			a0 used to address I/O port
*	Ver:		0.5
*	Author:		Unni Pillai (Peripherals Department SOA)
*	Mods:
*		up	12/28/93 added delay 5seconds (in routine HMD_RESET)
****************************************************************************************

_HMD_INIT_RDY:
	movem.l	d1-d2/d6/d7/a0,-(sp)
	move.w	#$100,Z80BusReq	;Z80 bus request
	move.w	#$100,Z80Reset	;Z80 reset line high(NORMAL RUN STATE)
	btst.b	#0,Z80BusReq	;Z80 bus grant acknowledge?
	bne.s	*-8		;wait until bus granted
	move.l	#$00a10005,a0	;port address of HMD
	move.b	#$60,6(a0)	;set bits 6 and 5 output TH TR = out
	moveq	#0,d2
	moveq	#0,d7
	move.w	#$0fff,d7
	bsr	HMD_IDLE
	tst.l	d2
	bne	HMD_DATA_exit
	bsr	HMD_RESET
	tst.l	d2
	bne	HMD_DATA_exit
	move.b	#$20,(a0)	;1st Id nibble request TR =1
	moveq	#0,d7
	move.w	#$0fff,d7
HMD_init_lp0:
	btst.b	#4,(a0)		;check TL=0
	beq	HMD_INIT_10
	dbra	d7,HMD_init_lp0
	bra	HMD_FAIL
HMD_INIT_10:
	move.b	(a0),d1
	and.b	#$0f,d1
	cmp.b	#$08,d1
	bne	HMD_FAIL
	move.b	#$00,(a0)	;2nd Id reserve nibble req TR=0
HMD_init_lp1:
	btst.b	#4,(a0)		;check TL =1
	bne	HMD_DATA_20
	dbra	d7,HMD_init_lp1
	bra	HMD_timeout

******************************************************************************
*	HMD_DATA	Head Tracker Data Routine
*
*		THIS DRIVER READS THE HEAD TRACKER DATA
*		ACCESS THIS ROUTINE FROM WITHIN THE V_INT
*		Head Tracker supports a 60HZ frame rate.
*		Head Tracker must be plugged into I/O port 2.
*
*	In:	Nothing.
*	Out:	_SYS_HMD_ERROR.L	Status:
*			0		- Normal
*			1		- Timeout occurred
*			$80000001	- Hardware error
*			$80000002	- Time out while RESET
*
* 		D0.L			Data:
* xxxx|xxxx|xxxx|L R X8 Y8|X7 X6 X5 X4|X3 X2 X1 X0|Y7 Y6 Y5 Y4|Y3 Y2 Y1 Y0
*	X0-X8 represent absolute YAW values from 0 to 360 degrees in HEX
*	Y0-Y7	represents absolute PITCH values from 0to +/- 30 degrees
*	Y8 is sign bit  look up		Y8 = 0
*	look down	Y8 = 1
*
*	REGISTERS:	d0 used for output,
*			d2 used for output
*			d7 destroyed
*			d6 destroyed
*			a0 used to address I/O port
*	Ver:		0.5
*	Author:		Unni Pillai (Peripherals Department SOA)
*	Mods:
*			Unni Pillai 08/11/93
*			Unni Pillai 12/21/93
****************************************************************************************

_HMD_DATA:
	movem.l	d1-d2/d6/d7/a0,-(sp)
	move.w	#$100,Z80BusReq	;Z80 bus request
	move.w	#$100,Z80Reset	;Z80 reset line high(NORMAL RUN STATE)
	btst.b	#0,Z80BusReq	;Z80 bus grant acknowledge?
	bne.s	*-8		;wait until bus granted
	move.l	#$00a10005,a0	; port address of HMD
	move.b	#$60,6(a0)	; set bits 6 and 5 output TH TR = out
	moveq	#0,d0		; debounce delay for port switching
	moveq	#0,d2
HMD_DATA_20:
	move.b	#$20,(a0)	;1st data req	TR=1
	moveq	#0,d7
	move.w	#$0fff,d7	;max timeout = 40958 cycles
HMD_data_lp2:
	btst.b	#4,(a0)		;check TL=0
	beq	HMD_DATA_30
	dbra	d7,HMD_data_lp2
	bra	HMD_timeout
HMD_DATA_30:
	move.b	(a0),d0		;d0=xxxx|L R X8 Y8
	move.b	#$00,(a0)	;2nd data req TR=0
	lsl.l	#8,d0		;d0=xxxx|L R X8 Y8|X7 X6 X5 X4|X3 X2 X1 X0
HMD_data_lp3:
	btst.b	#4,(a0)		;check TL=1
	bne	HMD_DATA_40
	dbra	d7,HMD_data_lp3
	bra	HMD_timeout
HMD_DATA_40:
	move.b	(a0),d0		;d0=L R X8 Y8|xxxx|X7 X6 X5 X4
	move.b	#$20,(a0)	;3rd req XLow
	lsl.b	#4,d0		;d0=L R X8 Y8|X7 X6 X5 X4|xxxx
	lsl.l	#4,d0		;d0=L R X8 Y8|X7 X6 X5 X4|xxxx|xxxx
HMD_data_lp4:
	btst.b	#4,(a0)
	beq	HMD_DATA_50
	dbra	d7,HMD_data_lp4
	bra	HMD_timeout
HMD_DATA_50:
	move.b	(a0),d0		;d0=L R X8 Y8|X7 X6 X5 X4|xxxx|X3 X2 X1 X0
	move.b	#$00,(a0)	;4th req YHigh
	lsl.b	#4,d0		;d0=L R X8 Y8|X7 X6 X5 X4|X3 X2 X1 X0|xxxx
	lsl.l	#4,d0		;d0=L R X8 Y8|X7 X6 X5 X4|X3 X2 X1 X0|xxxx|xxxx
HMD_data_lp5:
	btst.b	#4,(a0)
	bne	HMD_DATA_60
	dbra	d7,HMD_data_lp5
	bra	HMD_timeout
HMD_DATA_60:
	move.b	(a0),d0		;d0=L R X8 Y8|X7 X6 X5 X4|X3 X2 X1 X0|xxxx|Y7 Y6 Y5 Y4
	move.b	#$20,(a0)	;5th req YLOW
	lsl.b	#4,d0		;d0=L R X8 Y8|X7 X6 X5 X4|X3 X2 X1 X0|Y7 Y6 Y5 Y4|xxxx
	lsl.l	#4,d0		;d0=L R X8 Y8|X7 X6 X5 X4|X3 X2 X1 X0|Y7 Y6 Y5 Y4|xxxx|xxxx
HMD_data_lp6:
	btst.b	#4,(a0)
	beq	HMD_DATA_70
	dbra	d7,HMD_data_lp6
	bra	HMD_timeout
HMD_DATA_70:
	move.b	(a0),d0	;d0=L R X8 Y8|X7 X6 X5 X4|X3 X2 X1 X0|Y7 Y6 Y5 Y4|xxxx|Y3 Y2 Y1 Y0
	lsl.b	#4,d0
	lsr.l	#4,d0
	moveq	#0,d2	;d0=L R X8 Y8|X7 X6 X5 X4|X3 X2 X1 X0|Y7 Y6 Y5 Y4|Y3 Y2 Y1 Y0
	bsr	HMD_IDLE
HMD_DATA_exit:
	move.l	d2,_SYS_HMD_ERROR
	move.w	#0,Z80BusReq
	movem.l	(sp)+,d1-d2/d6/d7/a0
	rts


********************************************************************
*	HMD_IDLE	sets the Head Tracker and Genesis into IDLE state
*	in:	a0	(address of I/O port 2 $00a10005)
*		d7	timeout counter
*	out: -
*********************************************************************

HMD_IDLE:
	move.b	#$60,(a0)
	moveq	#0,d6
	nop
idle_lp:
	btst.b	#4,(a0)
	bne	idle_ack
	dbra	d7,idle_lp
	bra	HMD_ID_FAIL
idle_ack:
	move.b	(a0),d6
	and.b	#$7f,d6
	cmp.b	#$70,d6
	bne	HMD_ID_FAIL
	rts

*************************************************************************
*	HMD_RESET issues reset to the Head Tracker
*	in:	a0	(address of I/O port 2 $00a10005)
*		d7  timer counter
*	out: -
* mods:
* up 12/28/93 added 5sec delay work with ONOSENDAI
*********************************************************************

HMD_RESET:
	move.b	#$40,(a0)	;reset req TH=1 TR=0
	moveq	#0,d6
	move.w	#$fffe,d6
reset_lp:
	btst.b	#4,(a0)
	beq	reset_exit
	dbra	d6,reset_lp
	bra	HMD_rst_FAIL
reset_exit:
	bsr	HMD_IDLE
	moveq	#0,d5
	move.w	#65,d5
sec5_dly:
	moveq	#0,d6
	move.w	#$fffe,d6
ms8_dly:
	dbra	d6,ms8_dly
	dbra	d5,sec5_dly
	rts

HMD_ID_FAIL:
	move.l	#$80000001,d2
	move.b	#$60,(a0)	;set TH, TR = 1 and exit
	rts

HMD_FAIL:
	move.l	#$80000001,_SYS_HMD_ERROR
	move.b	#$60,(a0)
	move.w	#0,Z80BusReq
	movem.l	(sp)+,d1-d2/d6/d7/a0
	rts

HMD_rst_FAIL:
	move.l	#$80000002,d2
	move.b	#$60,(a0)
	rts

****************************************************************************
*	HMD_timeout
*	returns d2.l = 1 to indicate timeout occurred
****************************************************************************

HMD_timeout:
	move.l	#1,_SYS_HMD_ERROR
	move.b	#$60,(a0)
	move.w	#0,Z80BusReq
	movem.l	(sp)+,d1-d2/d6/d7/a0
	rts



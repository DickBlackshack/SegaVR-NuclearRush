*****************************************************************************
*		Copyright (C) 1993 SEGA OF AMERICA INC.
*			All Rights Reserved
*
* VRrev3.S	-	GENESIS VR Hat Tracker related routines
*
* 	Ver:	3.6(12/28/93) (based on 3rd rev of the protocol)
*	    	modified for old ONOSENDAI
*	Author:	Unni Pillai (SOA)
*
* MODS:
*	UP  04/29/93	Started
*	UP  05/05/93
*	UP  07/28/93	New routines HMD_INIT_RDY & HMD_DATA
*	UP  08/10/93-08/19/93
*	KLM 08/30/93	Cleaned up code and made it suitable for Nuclear Rush
*	UP  10/13/93
*	UP  12/14/93	Included equate.s
*	UP  12/21/93	Made I/O lines = hi upon crash exits
*	UP  12/28/93	Added delay = 5seconds before IDLE after RESET
*			(in HMD_RESET)
*	KLM 01/01/94	Cleaned up code and made it suitable for Nuclear Rush
*****************************************************************************

		xdef	_HMD_INIT_RDY
		xdef	_HMD_DATA
		xref	_SYS_HMD_ERROR
		
;EXTRA_INIT_FAILURE_DIAG equ 1 ;rww - extra info for init failure in SYS_HMD_ERROR

	.ifdef EXTRA_INIT_FAILURE_DIAG
		xdef _EatSomeCycles
	.endif

Z80BusReq	equ	$A11100		; bit 8 (high=BusReq)
Z80Reset	equ	$A11200		; bit 8 (low=Reset)

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
	.ifdef EXTRA_INIT_FAILURE_DIAG
	bne	HMD_FAILED_INIT_exit
	.else
	bne	HMD_DATA_exit
	.endif
	bsr	HMD_RESET
	tst.l	d2
	.ifdef EXTRA_INIT_FAILURE_DIAG
	bne	HMD_FAILED_RESET_exit
	.else
	bne	HMD_DATA_exit
	.endif
	move.b	#$20,(a0)	;1st Id nibble request TR =1
	moveq	#0,d7
	move.w	#$0fff,d7
	.ifdef EXTRA_INIT_FAILURE_DIAG
	moveq	#0,d2
	.endif
HMD_init_lp0:
	.ifdef EXTRA_INIT_FAILURE_DIAG
	move.b	(a0),d1
	or.b	d1,d2
	btst	#4,d1
	.else
	btst.b	#4,(a0)		;check TL=0
	.endif
	beq	HMD_INIT_10
	dbra	d7,HMD_init_lp0
	.ifdef EXTRA_INIT_FAILURE_DIAG
	bra	HMD_FAILED_INIT0_exit
	.else
	bra	HMD_FAIL
	.endif
HMD_INIT_10:
	move.b	(a0),d1
	and.b	#$0f,d1
	cmp.b	#$08,d1
	.ifdef EXTRA_INIT_FAILURE_DIAG
	bne	HMD_FAILED_INIT1_exit
	.else
	bne	HMD_FAIL
	.endif
	move.b	#$00,(a0)	;2nd Id reserve nibble req TR=0
	.ifdef EXTRA_INIT_FAILURE_DIAG
	moveq	#0,d2
	.endif
HMD_init_lp1:
	.ifdef EXTRA_INIT_FAILURE_DIAG
	move.b	(a0),d1
	or.b	d1,d2
	btst	#4,d1
	.else
	btst.b	#4,(a0)		;check TL =1
	.endif
	bne	HMD_DATA_20
	dbra	d7,HMD_init_lp1
	.ifdef EXTRA_INIT_FAILURE_DIAG
	bra	HMD_FAILED_INIT2_exit
	.else
	bra	HMD_timeout
	.endif
	
	.ifdef EXTRA_INIT_FAILURE_DIAG
HMD_FAILED_INIT_exit:
	move.l	#$80000100,_SYS_HMD_ERROR
	or.l	d2,_SYS_HMD_ERROR
	bra HMD_DATA_exit_noerrorset
HMD_FAILED_RESET_exit:
	or.l	#$80000200,d2
	move.l	d2,_SYS_HMD_ERROR
	bra HMD_DATA_exit_noerrorset
HMD_FAILED_INIT0_exit:
	or.l	#$80000300,d2
	move.l	d2,_SYS_HMD_ERROR
	bra HMD_FAIL_NOERRORSET
HMD_FAILED_INIT1_exit:
	and.l	#$ff,d1
	or.l	#$80000400,d1
	move.l	d1,_SYS_HMD_ERROR
	bra HMD_FAIL_NOERRORSET
HMD_FAILED_INIT2_exit:
	and.l	#$ff,d1
	or.l	#$80000500,d1
	move.l	d1,_SYS_HMD_ERROR
	bra HMD_FAIL_NOERRORSET
	.endif
	

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
	.ifdef EXTRA_INIT_FAILURE_DIAG
	bra	HMD_timeout0
	.else
	bra	HMD_timeout
	.endif
HMD_DATA_30:
	move.b	(a0),d0		;d0=xxxx|L R X8 Y8
	move.b	#$00,(a0)	;2nd data req TR=0
	lsl.l	#8,d0		;d0=xxxx|L R X8 Y8|X7 X6 X5 X4|X3 X2 X1 X0
HMD_data_lp3:
	btst.b	#4,(a0)		;check TL=1
	bne	HMD_DATA_40
	dbra	d7,HMD_data_lp3
	.ifdef EXTRA_INIT_FAILURE_DIAG
	bra	HMD_timeout1
	.else
	bra	HMD_timeout
	.endif
HMD_DATA_40:
	move.b	(a0),d0		;d0=L R X8 Y8|xxxx|X7 X6 X5 X4
	move.b	#$20,(a0)	;3rd req XLow
	lsl.b	#4,d0		;d0=L R X8 Y8|X7 X6 X5 X4|xxxx
	lsl.l	#4,d0		;d0=L R X8 Y8|X7 X6 X5 X4|xxxx|xxxx
HMD_data_lp4:
	btst.b	#4,(a0)
	beq	HMD_DATA_50
	dbra	d7,HMD_data_lp4
	.ifdef EXTRA_INIT_FAILURE_DIAG
	bra	HMD_timeout2
	.else
	bra	HMD_timeout
	.endif
HMD_DATA_50:
	move.b	(a0),d0		;d0=L R X8 Y8|X7 X6 X5 X4|xxxx|X3 X2 X1 X0
	move.b	#$00,(a0)	;4th req YHigh
	lsl.b	#4,d0		;d0=L R X8 Y8|X7 X6 X5 X4|X3 X2 X1 X0|xxxx
	lsl.l	#4,d0		;d0=L R X8 Y8|X7 X6 X5 X4|X3 X2 X1 X0|xxxx|xxxx
HMD_data_lp5:
	btst.b	#4,(a0)
	bne	HMD_DATA_60
	dbra	d7,HMD_data_lp5
	.ifdef EXTRA_INIT_FAILURE_DIAG
	bra	HMD_timeout3
	.else
	bra	HMD_timeout
	.endif
HMD_DATA_60:
	move.b	(a0),d0		;d0=L R X8 Y8|X7 X6 X5 X4|X3 X2 X1 X0|xxxx|Y7 Y6 Y5 Y4
	move.b	#$20,(a0)	;5th req YLOW
	lsl.b	#4,d0		;d0=L R X8 Y8|X7 X6 X5 X4|X3 X2 X1 X0|Y7 Y6 Y5 Y4|xxxx
	lsl.l	#4,d0		;d0=L R X8 Y8|X7 X6 X5 X4|X3 X2 X1 X0|Y7 Y6 Y5 Y4|xxxx|xxxx
HMD_data_lp6:
	btst.b	#4,(a0)
	beq	HMD_DATA_70
	dbra	d7,HMD_data_lp6
	.ifdef EXTRA_INIT_FAILURE_DIAG
	bra	HMD_timeout4
	.else
	bra	HMD_timeout
	.endif
HMD_DATA_70:
	move.b	(a0),d0	;d0=L R X8 Y8|X7 X6 X5 X4|X3 X2 X1 X0|Y7 Y6 Y5 Y4|xxxx|Y3 Y2 Y1 Y0
	lsl.b	#4,d0
	lsr.l	#4,d0
	moveq	#0,d2	;d0=L R X8 Y8|X7 X6 X5 X4|X3 X2 X1 X0|Y7 Y6 Y5 Y4|Y3 Y2 Y1 Y0
	bsr	HMD_IDLE
HMD_DATA_exit:
	move.l	d2,_SYS_HMD_ERROR
HMD_DATA_exit_noerrorset:
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
	.ifdef EXTRA_INIT_FAILURE_DIAG
	moveq	#0,d2
	.endif
reset_lp:
	.ifdef EXTRA_INIT_FAILURE_DIAG
	move.b	(a0),d5
	or.b	d5,d2
	btst	#4,d5
	.else
	btst.b	#4,(a0)
	.endif
	beq	reset_exit
	dbra	d6,reset_lp
	bra	HMD_rst_FAIL
reset_exit:
	.ifdef EXTRA_INIT_FAILURE_DIAG
	moveq	#0,d2
	.endif
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
HMD_FAIL_NOERRORSET:
	move.b	#$60,(a0)
	move.w	#0,Z80BusReq
	movem.l	(sp)+,d1-d2/d6/d7/a0
	rts

HMD_rst_FAIL:
	.ifdef EXTRA_INIT_FAILURE_DIAG
	lsl.l	#8,d2
	lsl.l	#8,d2
	or.l	#$80000002,d2
	.else
	move.l	#$80000002,d2
	.endif
	move.b	#$60,(a0)
	rts

	.ifdef EXTRA_INIT_FAILURE_DIAG
_EatSomeCycles:
	nop
	nop
	nop
	nop
	rts
	
HMD_timeout0:
	move.l	#$80000502,_SYS_HMD_ERROR
	bra HMD_timeout_errorset
HMD_timeout1:
	move.l	#$80000503,_SYS_HMD_ERROR
	bra HMD_timeout_errorset
HMD_timeout2:
	move.l	#$80000504,_SYS_HMD_ERROR
	bra HMD_timeout_errorset
HMD_timeout3:
	move.l	#$80000505,_SYS_HMD_ERROR
	bra HMD_timeout_errorset
HMD_timeout4:
	move.l	#$80000506,_SYS_HMD_ERROR
	bra HMD_timeout_errorset
	.endif

****************************************************************************
*	HMD_timeout
*	returns d2.l = 1 to indicate timeout occurred
****************************************************************************

HMD_timeout:
	move.l	#1,_SYS_HMD_ERROR
HMD_timeout_errorset:
	move.b	#$60,(a0)
	move.w	#0,Z80BusReq
	movem.l	(sp)+,d1-d2/d6/d7/a0
	rts



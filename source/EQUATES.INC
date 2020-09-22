**************************************************************************
**                   GENERAL HARDWARE EQUATES                            *
**************************************************************************

true		equ	1
false		equ	0

EXTSIZE		equ	$A0
EXTCLEARED	equ	$00
EXTNOTCLEARED	equ	$40
EXTWORDS	equ	$00
EXTOTHER	equ	$08
EXTEVENBYTES	equ	$10
EXTODDBYTES	equ	$18
EXTTYPE		equ	$00
EXTSRAM		equ	$20
EXTEEPROM	equ	$40

Pri		equ	%1000000000000000
CP0		equ	%0010000000000000
CP1		equ	%0100000000000000
VF		equ	%0001000000000000
HF		equ	%0000100000000000

Pal0		equ	%0000000000000000
Pal1		equ	%0010000000000000
Pal2		equ	%0100000000000000
Pal3		equ	%0110000000000000

ROMBase		equ	$00000000
SystemBase	equ	$00A00000
VDPBase		equ	$00C00000
RAMBase		equ	$00FF0000	;first byte of work RAM
RAMEnd		equ	$01000000	;first byte AFTER work RAM

Z80Base		equ	$A00000
IOBase		equ	$A10000
ControlBase	equ	$A11000

SoundRam	equ	$A00000
YM2612		equ	$A04000
Z80Bank		equ	$A06000

VDPData		equ	$C00000
VDPControl	equ	$C00004
VDPStatus	equ	$C00004
VDPHVCount	equ	$C00008

VDATA		EQU	VDPData
VCTRL		EQU	VDPControl

VersionNo	equ	$A10001
Z80BusReq	equ	$A11100	; bit 8 (high=BusReq)
Z80Reset	equ	$A11200	; bit 8 (low=Reset)

IE0		equ	%0000000000100000
IE1		equ	%0000000000010000
IE2		equ	%0000000000001000
M1		equ	%0000000000010000
M2		equ	%0000000000001000
M3		equ	%0000000000000010
DISP		equ	%0000000001000000
VSCR		equ	%0000000000000100
HSCR		equ	%0000000000000010
LSCR		equ	%0000000000000001
RS0		equ	%0000000010000000
RS1		equ	%0000000000000001
STE		equ	%0000000000001000
LSM1		equ	%0000000000000100
LSM0		equ	%0000000000000010
VSZ1		equ	%0000000000100000
VSZ0		equ	%0000000000010000
HSZ1		equ	%0000000000000010
HSZ0		equ	%0000000000000001
DMD1		equ	%0000000010000000
DMD0		equ	%0000000001000000
CD0		equ	%0100000000000000
CD1		equ	%1000000000000000
CD2		equ	%0000000000010000
CD3		equ	%0000000000100000
CD4		equ	%0000000001000000
CD5		equ	%0000000010000000
DMA		equ	%0000000000000010
		
Data1		equ	$A10003
Data2		equ	$A10005
Data3		equ	$A10007
Ctrl1		equ	$A10009
Ctrl2		equ	$A1000B
Ctrl3		equ	$A1000D
SCtrl1		equ	$A10013
SCtrl2		equ	$A10019
SCtrl3		equ	$A1001F

KCodeUp		equ	0
KCodeDown	equ	1
KCodeLeft	equ	2
KCodeRight	equ	3
KCodeB		equ	4
KCodeC		equ	5
KCodeA		equ	6
KCodeStart	equ	7

* The following equates give two 4K scrolls (64X32CELLS) at 48K and 56K.
* The window (which is 4K long) is set to 52K. Since each scroll only
* requires 4K, there are two 4K gaps above the scrolls.
* Sprite Attributes and HScroll have been placed in 2K of the upper gap.

SpriteAttr	equ	$B400	;1K boundary in 40CELL (1/2K in 32CELL)
HScroll		equ	$B800	;1K boundary
ScrollA		equ	$C000	;8K boundary
Window		equ	$D000	;4K boundary in 40CELL (2K in 32CELL)
ScrollB		equ	$E000	;8K boundary

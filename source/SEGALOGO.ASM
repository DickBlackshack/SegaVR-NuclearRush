* Startup Code. - I changed the logocode 8/92 - Now runs in a 64x32 map
* Helps out if you want to do some text.
* The logo code has an ascii font attached to it.

        include SEGA.I
                                        
VDATA           EQU     $C00000
VCTRL           EQU     $C00004

        xref    LogoChars
        xref    LogoPalette
        xref    LogoCycle
        xref    _ScreenCol
        xref    _ScreenRow
	xref	_VdpShadow

        section .text

        xdef    _SegaLogo
                                        
_SegaLogo:
		movem.l	d0-d7/a0-a6,-(sp)
                move.l  #10,d6          
                jsr     delay
                SetVdpRegister  1,$44   ; Turn on the display
                SetVdpRegister  16,$11    ; Map Size 64x64
                lea.l   LogoChars,A0    ; A0 = *LogoChars
                VramWrtAddr  $20,VCTRL  ; Set address at 32 - Char #1
*                move.l  #16*144,d0      ; d0 char counter
                move.l  #16*147,d0      ; d0 char counter
ldchar:         move.w  (a0)+,VDATA     ; write logo chars
                dbra    d0,ldchar       
                lea.l   LogoPalette,a0  ; a0 = *LogoPallette
                CramWrtAddr  $0,VCTRL   ; Set CRAM ADDRESS
                moveq.l #15,d0          ; set color counter
ldpal:          move.w  (a0)+,VDATA ; write logo pallette
                dbra    d0,ldpal
*
* Here's where we're going to write out the logo map - map A points
* to C000.
*
                VramWrtAddr $C51C,D2    ; Set up D2 to be a address
                moveq.l #1,d1           ; overall char counter
                moveq.l #3,d3
newrow:         move.l  d2,VCTRL        ; Set address
                add.l   #$00800000,D2   ; Calc new address for 64 wide map
                moveq.l #11,D0          ; Row counter
wrtrow1:        move.w  d1,VDATA        ; write 1st row
                addq.w  #1,d1           ; next char
                dbra    d0,wrtrow1
                dbra    d3,newrow

*;;;;;;;;;;;; CYCLE THE LOGO HERE! ;;;;;;;;;;;;;;;;;;;;;;;;;
                lea     LogoCycle,a0    ; a0 = *LogoCycle
                addi    #32,a0          
                move    #16,d1          ; ctr for num of cycles
                move    #$3f,d6         ; delay
                jsr     delay           
stcycl:         move    a0,a1           ; ptr to start of cycle
                move.l  #$c00e0000,$C00004.L ; cram_wrt_addr(e)
                moveq   #8,d0           ; ctr for num of colors
cyc:            move.w  (a1)+,VDATA ; cram_wrt_data
                dbra    d0,cyc          
                move.l  #$08,d6         ; delay
                jsr     delay           
                subq    #2,a0           ; next cycle
                dbra    d1,stcycl       
		movem.l	(sp)+,d0-d7/a0-a6
                rts                     ; Back again!

                                        
delay:
                move.l  #$fff,d7        ; Call with delay value in D6
dt:             nop                     
                dbra    d7,dt           
                dbra    d6,delay
                rts

        xdef    _putchx
*;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
*; FUNCTION:     putchx  - console I/O function!
*; DESCRIPTION:  Console I/O to the Genesis screen - Assumes that the Genesis
*;               is in a 40 col mode.
*;               MAP A will receive the text, the ASCII font shoud have been
*;               loaded. MAP A should be located at $C000
*;
*; RETURNS:      .
*; PARAMETERS:   .
*; SIDE EFFECTS:
*; REVISIONS:    2/92    -jf-
*;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_putchx:
        move.w  _ScreenRow,D0
        lsl.w   #6,D0           ; D0=(ScreenRow*64+ScreenCol)*2
        add.w   _ScreenCol,D0   ;
        lsl.w   #1,D0
        add.w   #$E000,D0       ; adjust for address...
        CalcVramWrtAddrCode D0,D2
        move.l  D2,VCTRL        ; Set vram write address
*       move.l  4(a7),D0        ; Get ASCII char
	move.l	4(a7),D0	; Get ASCII char
        cmp.b   #10,D0          ; Is linefeed?
        bne     PC_1
        addq.w  #1,_ScreenRow
        bra     PC_3
PC_1:   cmp.b   #13,D0          ; is a CR?
        bne     PC_2
        move.w  #0,_ScreenCol
        bra     PC_3
PC_2:   add.w   #17,d0          ; Adjust for our character set
	or.w	#$E000,d0
        move.w  d0,VDATA        ; and set the map
        addq.w  #1,_ScreenCol
PC_3:   cmp.w   #39,_ScreenCol  ; At last col?
        bls     PC_4
        addq.w  #1,_ScreenRow
        move.w  #0,_ScreenCol   ; If so, go to the next row
PC_4:   cmp.w   #26,_ScreenRow  ; At last row?
        bls     PC_5            ; No, go around
*
* Scroll the screen up here
*
        AutoIncrement   1
        ShadowRegister  1,D0    ; Load whatever the prev register value was..
        or.b    #$10,D0         ; Enable DMA
        SetVdpRegisterCode 1,D0
        SetVdpRegister  19,$00
        SetVdpRegister  20,$0D  ; Setup DMA length
        SetVdpRegister  21,$80
        SetVdpRegister  22,$C0  ; DMA source address - $c080
        SetVdpRegister  23,$C0  ; DMA VRAM copy mode...
        MOVE.L  #$000000C3,VCTRL         ;Set DMA destination
** We should be DMA'ing now
PC_4A:  MOVE.W  VCTRL,D0
        BTST    #1,D0
        BNE     PC_4A           ; Wait for DMA
        SUBQ.W  #1,_ScreenRow

PC_5:
        rts


        xdef    _SetSR
****************************************************************************
* DESCRIPTION:  Sets the status register to the word passed. This is
*               a helper function for C code
* RETURNS:      .
* PARAMETERS:   new SR value
* SIDE EFFECTS:
* REVISIONS:    2/92    -jf-
****************************************************************************
_SetSR:
        move.l  4(a7),D0        ; Get param
        move.w  d0,SR           ; Set status register
        rts

*
* Modulator Offset Table
*

	dc.b	$0E,$00		; Offset to modulator #0: 14
	dc.b	$14,$00		; Offset to modulator #1: 20
	dc.b	$1D,$00		; Offset to modulator #2: 29
	dc.b	$29,$00		; Offset to modulator #3: 41
	dc.b	$2F,$00		; Offset to modulator #4: 47
	dc.b	$3B,$00		; Offset to modulator #5: 59
	dc.b	$4D,$00		; Offset to modulator #6: 77
*
* Modulator Data
*

* Modulator 0 "Null": Pitch
	dc.b	$00,$00			; initial value = 0
	dc.b	$01,$00,$00		; len = 1, slope = 0
	dc.b	0
* Modulator 1 "Beam in 1": Pitch
	dc.b	$00,$00			; initial value = 0
	dc.b	$5DC,$24,$00		; len = 1500, slope = 36
	dc.b	$5DC,$18,$00		; len = 1500, slope = 24
	dc.b	0
* Modulator 2 "Beam in 2": Pitch
	dc.b	$00,$00			; initial value = 0
	dc.b	$5DC,$24,$00		; len = 1500, slope = 36
	dc.b	$63,$2B,$00		; len = 99, slope = 43
	dc.b	$5DC,$F4,$01		; len = 1500, slope = 500
	dc.b	0
* Modulator 3 "Down 24": Pitch
	dc.b	$00,$00			; initial value = 0
	dc.b	$18,$50,$FB		; len = 24, slope = -1200
	dc.b	0
* Modulator 4 "Too Bad C": Pitch
	dc.b	$DA,$2F			; initial value = 12250
	dc.b	$64,$E2,$FF		; len = 100, slope = -30
	dc.b	$F0,$EB,$FF		; len = 240, slope = -21
	dc.b	$F0,$EB,$FF		; len = 240, slope = -21
	dc.b	0
* Modulator 5 "Big Explosion": Pitch
	dc.b	$14,$05			; initial value = 1300
	dc.b	$02,$B0,$04		; len = 2, slope = 1200
	dc.b	$08,$24,$FA		; len = 8, slope = -1500
	dc.b	$14,$D4,$FE		; len = 20, slope = -300
	dc.b	$5A,$38,$FF		; len = 90, slope = -200
	dc.b	$01,$00,$00		; len = 1, slope = 0
	dc.b	0
* Modulator 6 "Hooray": Pitch
	dc.b	$DA,$2F			; initial value = 12250
	dc.b	$64,$14,$00		; len = 100, slope = 20
	dc.b	$F0,$15,$00		; len = 240, slope = 21
	dc.b	$F0,$15,$00		; len = 240, slope = 21
	dc.b	$F0,$15,$00		; len = 240, slope = 21
	dc.b	$F0,$19,$00		; len = 240, slope = 25
	dc.b	0

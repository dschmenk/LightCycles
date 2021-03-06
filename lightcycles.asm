;*
;* Light Cycles 3D
;*
KEYBD	=	$C000	; Keyboard addresses
KEYSTRB	=	$C010
SPEAKER	=	$C030
GCSTROBE =	$C070
GC0	=	$C064
GC1	=	$C065
GCPB1	=	$C061
GCPB2	=	$C062
STPTRL	=	$06
STPTRH	=	$07
STPTR	=	STPTRL
ANGLE	=	$08
SCANIDX	=	$08
SCANLN	=	$09
VIEWPORT =	$0A
XVIEWF	=	$20
XVIEWI	=	$21
YVIEWF	=	$22
YVIEWI	=	$23
CH	=	$24
CV	=	$25
TBAS1L	=	$28
TBAS1H	=	$29
TBAS1	=	TBAS1L
TBAS2L	=	$2A
TBAS2H	=	$2B
TBAS2	=	TBAS2L
INVFLAG	=	$32
S_FRACL	=	$1A
S_FRACH	=	$1B
S_INT	=	$1C
T_FRACL	=	$1D
T_FRACH	=	$1E
T_INT	=	$1F
DS_FRACL=	$4E
DS_FRACH=	$3A
DS_INT	=	$3B
DT_FRACL=	$4F
DT_FRACH=	$3C
DT_INT	=	$3D
S_MIDFL	=	$50
S_MIDFH	=	$51
S_MIDI	=	$52
T_MIDFL	=	$53
T_MIDFH	=	$54
T_MIDI	=	$55
SRCMASK	=	$60
DSTMASK	=	$61
DVSR	=	$F8	; and $F9
DVDND	=	$FA	; and $FB
QUADRNT	=	$FC
SIGN	=	$FD
TMP	=	$FE	; and $FF
GBASL	=	$26	; GR ZP addresses
GBASH	=	$27
GBASE	=	GBASL
GPAGE	=	$2F
GCLR	=	$30
BLACK	=	$00	; GR colors
MAGENTA	=	$11
DRKBLU	=	$22
PURPLE	=	$33
DRKGRN	=	$44
GREY	=	$55
MEDBLU	=	$66
LGTBLU	=	$77
BROWN	=	$88
ORANGE	=	$99
GRAY	=	$AA
PINK	=	$BB
LGTGRN	=	$CC
YELLOW	=	$DD
AQUA	=	$EE
WHITE	=	$FF
HORIZON	=	16
VIEWBOT	=	19	; Bottom viewport
VIEWTOP	=	09
GCMAX	=	127	; Max value for game controller
;GCXPOS	=	$F0
;GCYPOS	=	$F1
;GCBTTNS	=	$F2
GCBTTN1	=	$80	; Game controller
GCBTTN2	=	$40
GCLIMITDLY =	15
MAP	=	$A000	; Arena map
P1CLR	=	DRKGRN;LGTGRN
P1TLCLR	=	LGTGRN;DRKGRN
P2CLR	=	BROWN;PURPLE
P2TLCLR	=	PURPLE;BROWN
FULLBOOST = 	$F0
*	=	$1000
	!SOURCE	"intro.asm"
	!SOURCE	"drawview.asm"
	!SOURCE	"utils.asm"
;*
;* Main game loop
;*	
GAMELOOP
	LDA	#$00	; Clear player status
	STA	PSTATUS
;*
;* Calculate angle and distance^2 between players
;*
	LDA	P2XF
	SEC
	SBC	P1XF
	TAY
	LDA	P2XI
	SBC	P1XI
	TAX
	TYA
	LDY	#$00	; Assume no X coord flip
	CPX	#$80
	BCC	+
	JSR	NEG
	LDY	#$3F
+	STY	QUADRNT
	STA	DVSR
	STX	DVSR+1
	TXA
	JSR	MUL8X8	; Calc triangle edge (a*a)
	PHA
	TXA
	PHA
	LDA	P2YF
	SEC
	SBC	P1YF
	TAY
	LDA	P2YI
	SBC	P1YI
	TAX
	TYA
	LDY	#$00	; Assume no Y coord flip
	CPX	#$80
	BCC	+
	JSR	NEG
	LDY	#$7F
+	STA	DVDND
	STX	DVDND+1
	TYA
	EOR	QUADRNT
	STA	QUADRNT
	TXA
	JSR	MUL8X8	; Calc triangle edge (b*b)
	STA	TMP
	STX	TMP+1
	PLA
	TAX
	PLA
	CLC
	ADC	TMP
	STA	TMP
	TXA
	LDX	#$00
	ADC	TMP+1
	STA	PPDIST
	BNE	+	; Convert distance^2 (c*c) to size for rendering
	LDX	#$08	; Less than 16 tiles away (16*16=256)
	LDA	TMP
-	DEX
	LSR
	BNE	-
+	STX	PPSIZE
	LDX	#$00	; Assume no octant flip
	LDA	DVDND	; Calc tan() in first octant for precision
	CMP	DVSR
	LDA	DVDND+1
	SBC	DVSR+1
	BCC	+
	LDA	DVDND	; Flip octant
	LDX	DVSR	; Swap divisor <-> dividend
	STA	DVSR
	STX	DVDND
	LDA	DVDND+1
	LDX	DVSR+1
	STA	DVSR+1
	STX	DVDND+1
	LDX	#$80
+	STX	SIGN	; Use SIGN to save octant flip flag
	LDX	DVSR+1	; Divide 8.8 by 8.0 to get 8.8 result
	LDA	DVSR	; Convert divisor to 8.0
	ASL		; Round up
	BCC	+
	INX
+	STX	DVSR
	LDA	#$00
	STA	DVSR+1
	JSR	DIV
	CPX	#$00
	BEQ	+
	LDA	#$10	; On the diagonal
	BNE	++
+	LDX	#$FE
SRCHTAN	INX	; Scan tan() table LSBs for matching angle
	INX
	CMP	TAN_TBL,X
	BEQ	+
	BCS	SRCHTAN	; Less than, reload MSB and keep searching
+	TXA
	LSR		; Convert index to angle
	LDX	SIGN
	BPL	++
	STA	TMP	; Reflect octant
	LDA	#$20
	SEC
	SBC	TMP
++	EOR	QUADRNT	; Reflect into correct quadrant
	STA	PPANGLE
;*
;* Update rythm based on player-to-player distance
;*
	LDA	DRYTHM
	CLC
	ADC	#$01
	CMP	PPDIST
	BCC	+
	LDA	#$00
	LSR	VTONE
	BNE	+
	LDX	#$02
	STX	VTONE
+	STA	DRYTHM
;*
;* Render views
;*	
	LDA	P1ANGLE
	STA	ANGLE
	LDA	P1XF
	STA	XVIEWF
	LDA	P1XI
	STA	XVIEWI
	LDA	P1YF
	STA	YVIEWF
	LDA	P1YI
	STA	YVIEWI
	LDA	#$02
	SEC
	SBC	P1TURBO
	STA	MTONE
	LDA	#VIEWTOP
	JSR	DRAWVIEW
	LDA	P2CYCLE
	STA	GCLR
	LDA	P1ANGLE
	SEC
	SBC	PPANGLE
	AND	#$7F
	TAX
	LDA	#VIEWTOP
	JSR	DRAWENEMY
	LDA	P2ANGLE
	STA	ANGLE
	LDA	P2XF
	STA	XVIEWF
	LDA	P2XI
	STA	XVIEWI
	LDA	P2YF
	STA	YVIEWF
	LDA	P2YI
	STA	YVIEWI
	LDA	#$02
	SEC
	SBC	P2TURBO
	STA	MTONE
	LDA	#VIEWBOT
	JSR	DRAWVIEW
	LDA	P1CYCLE
	STA	GCLR
	LDA	P2ANGLE
	SEC
	SBC	PPANGLE
	CLC
	ADC	#$40	; Flip angle to opposite direction
	AND	#$7F
	TAX
	LDA	#VIEWBOT
	JSR	DRAWENEMY
	JSR	GSWAP
;*
;* AI player update
;*
AI1	LDA	P1MAN
	BNE	AI2
;	BEQ	+
;	JMP	AI2
;+
	LDX	P1XI
	LDY	P1YI
	JSR	MAPWTS	; Calc best direction based on map
	LDY	P2ANGLE
	LDX	#$00
	LDA	COS_TBL,Y
	ASL
	BCC	+
	DEX
	CLC
+	ADC	P2XF
	TXA
	ADC	P2XI
	SEC
	SBC	P1XI
	PHA
	LDX	#$00
	LDA	SIN_TBL,Y
	ASL
	BCC	+
	DEX
	CLC
+	ADC	P2YF
	TXA
	ADC	P2YI
	SEC
	SBC	P1YI
	TAY
	PLA
	TAX
;	LDA	P2XF
;	CMP	P1XF
;	LDA	P2XI
;	SBC	P1XI
;	TAX
;	LDA	P2YF
;	CMP	P1YF
;	LDA	P2YI
;	SBC	P1YI
;	TAY
	JSR	ENMYWT	; Calc best dir based on enemy relative pos
	LDA	P1ANGLE	; Default to current angle
	LSR
	LSR
	LSR
	LSR
	LSR
	TAY
	EOR	#$02	; Don't allow 180 degree turns
	TAX
	LDA	#$00
	STA	AIMOVE,X
	LDA	AIMOVE,Y
	LDX	#$03
-	CMP	AIMOVE,X ; Select highest weighted direction
	BCS	+
	TXA
	TAY
	LDA	AIMOVE,X
+	DEX
	BPL	-
	TYA		; Convert to angle
	ASL
	ASL
	ASL
	ASL
	ASL
;	CMP	P1ANGLE
;	BEQ	+
	STA	P1ANGLE
;	LDA	#$80
;	STA	P1XF
;	STA	P1YF
+	LDY	#$00
	LDX	PPSIZE	; Turbo when enemy is close
;	DEX
	BEQ	+
	INY
+	STY	P1TURBO
;	LDX	#5
;	LDY	#23
;	JSR	GOTOXY
;	LDA	AIMOVE+0
;	JSR	PUTA
;	LDA	#' '
;	JSR	PUTC
;	LDA	AIMOVE+1
;	JSR	PUTA
;	LDA	#' '
;	JSR	PUTC
;	LDA	AIMOVE+2
;	JSR	PUTA
;	LDA	#' '
;	JSR	PUTC
;	LDA	AIMOVE+3
;	JSR	PUTA
;	LDA	#'='
;	JSR	PUTC
;	LDA	P1ANGLE
;	JSR	PUTA
AI2	LDA	P2MAN
	BNE	READKBD
;	BEQ	+
;	JMP	READKBD
;+
	LDX	P2XI
	LDY	P2YI
	JSR	MAPWTS	; Calc best direction based on map
	LDY	P1ANGLE
	LDX	#$00
	LDA	COS_TBL,Y
	ASL
	BCC	+
	DEX
	CLC
+	ADC	P1XF
	TXA
	ADC	P1XI
	SEC
	SBC	P2XI
	PHA
	LDX	#$00
	LDA	SIN_TBL,Y
	ASL
	BCC	+
	DEX
	CLC
+	ADC	P1YF
	TXA
	ADC	P1YI
	SEC
	SBC	P2YI
	TAY
	PLA
	TAX
;	LDA	P1XF
;	CMP	P2XF
;	LDA	P1XI
;	SBC	P2XI
;	TAX
;	LDA	P1YF
;	CMP	P2YF
;	LDA	P1YI
;	SBC	P2YI
;	TAY
	JSR	ENMYWT	; Calc best dir based on enemy relative pos
	LDA	P2ANGLE	; Default to current angle
	LSR
	LSR
	LSR
	LSR
	LSR
	TAY
	EOR	#$02	; Don't allow 180 degree turns
	TAX
	LDA	#$00
	STA	AIMOVE,X
	LDA	AIMOVE,Y
	LDX	#$03
-	CMP	AIMOVE,X ; Select highest weighted direction
	BCS	+
	TXA
	TAY
	LDA	AIMOVE,X
+	DEX
	BPL	-
	TYA		; Convert to angle
	ASL
	ASL
	ASL
	ASL
	ASL
;	CMP	P2ANGLE
;	BEQ	+
	STA	P2ANGLE
;	LDA	#$80
;	STA	P2XF
;	STA	P2YF
+	LDY	#$00
	LDX	PPSIZE	; Turbo when enemy is close
;	DEX
	BEQ	+
	INY
+	STY	P2TURBO
;	LDX	#25
;	LDY	#23
;	JSR	GOTOXY
;	LDA	AIMOVE+0
;	JSR	PUTA
;	LDA	#' '
;	JSR	PUTC
;	LDA	AIMOVE+1
;	JSR	PUTA
;	LDA	#' '
;	JSR	PUTC
;	LDA	AIMOVE+2
;	JSR	PUTA
;	LDA	#' '
;	JSR	PUTC
;	LDA	AIMOVE+3
;	JSR	PUTA
;	LDA	#'='
;	JSR	PUTC
;	LDA	P2ANGLE
;	JSR	PUTA
;*
;* Get player input and update position
;*
READKBD	LDA	KEYBD
	BMI	+
	JMP	READPDL
+	BIT	KEYSTRB
	CMP	#$9B	; ESC key?
	BNE	+
-	LDA	KEYBD	; Pause
	BPL	-
	BIT	KEYSTRB
	CMP	#$D1	; Quit
	BNE	+
	LDA	#$03
	STA	PSTATUS
	RTS
+	LDX	USEPDLS
	BEQ	+
	JMP	READPDL
+	LDX	P1MAN
	BEQ	++
	CMP	#$C1	; A key
	BNE	+
	LDA	P1ANGLE
	SEC
	SBC	#$20
	AND	#$7F
	STA	P1ANGLE
;	LDA	#$80
;	STA	P1XF
;	STA	P1YF
	BNE	READPDL
+	CMP	#$C4	; D key
	BNE	+
	LDA	P1ANGLE
	CLC
	ADC	#$20
	AND	#$7F
	STA	P1ANGLE
;	LDA	#$80
;	STA	P1XF
;	STA	P1YF
	BNE	READPDL
+	CMP	#$D3	; S key
	BNE	++
	LDA	P1TURBO
	EOR	#$01
	STA	P1TURBO
	BPL	READPDL
++	LDX	P2MAN
	BEQ	READPDL
	CMP	#$CA	; J key
	BNE	+
	LDA	P2ANGLE
	SEC
	SBC	#$20
	AND	#$7F
	STA	P2ANGLE
;	LDA	#$80
;	STA	P2XF
;	STA	P2YF
	BNE	READPDL
+	CMP	#$CC	; L key
	BNE	+
	LDA	P2ANGLE
	CLC
	ADC	#$20
	AND	#$7F
	STA	P2ANGLE
;	LDA	#$80
;	STA	P2XF
;	STA	P2YF
	BNE	READPDL
+	CMP	#$CB	; K key
	BNE	READPDL
	LDA	P2TURBO
	EOR	#$01
	STA	P2TURBO
READPDL	JSR	GCREAD
	PHA
	LDA	USEPDLS
	BNE	+
	PLA
	JMP	CHKBOOST
+	LDA	P1MAN	; Check for player 1 AI
	BEQ	+
	LDA	#$00
	STA	P1TURBO
	PLA
	PHA
	BPL	++	
	INC	P1TURBO
	BNE	++
+	LDY	#GCMAX/2
++	LDA	P2MAN	; Check for player 2 AI
	BEQ	+
	LDA	#$00
	STA	P2TURBO
	PLA
	ASL
	BPL	++
	INC	P2TURBO
	BNE	++
+	LDX	#GCMAX/2
	PLA
++	JSR	UPDTPDL
	TYA
	SEC
	SBC	#GCMAX/16
	CLC
	ADC	P1ANGLE
	AND	#$7F
	STA	P1ANGLE
	TXA
	SEC
	SBC	#GCMAX/16
	CLC
	ADC	P2ANGLE
	AND	#$7F
	STA	P2ANGLE
CHKBOOST LDA	P1TURBO
	BEQ	++
	LDA	P1BOOST
	BEQ	+
	SEC
	SBC	#$08
	STA	P1BOOST
	LDX	#3
	LDY	#21
	JSR	UPDTBST
	LDA	#$01
+	STA	P1TURBO
++	LDA	P2TURBO
	BEQ	P1MOVE
	LDA	P2BOOST
	BEQ	+
	SEC
	SBC	#$08
	STA	P2BOOST
	LDX	#22
	LDY	#21
	JSR	UPDTBST	
	LDA	#$01
+	STA	P2TURBO
;*
;* Update player 1
;*
P1MOVE	LDY	P1ANGLE
	LDA	P1TURBO
	LSR
	LDX	#$00
	LDA	COS_TBL,Y
	BPL	+	; Sign extend into X
	DEX
+	BCS	+	; Turbo active?
	CMP	#$80
	ROR
+	CLC
	ADC	P1XF
	STA	P1XF
	TXA
	ADC	P1XI
	STA	P1XI
	LDA	P1TURBO
	LSR
	LDX	#$00
	LDA	SIN_TBL,Y
	BPL	+	; Sign extend into X
	DEX
+	BCS	+	; Turbo active?
	CMP	#$80
	ROR
+	CLC
	ADC	P1YF
	STA	P1YF
	TXA
	ADC	P1YI
	STA	P1YI
;*
;* Update player 2
;*
P2MOVE	LDY	P2ANGLE
	LDA	P2TURBO
	LSR
	LDX	#$00
	LDA	COS_TBL,Y
	BPL	+	; Sign extend into X
	DEX
+	BCS	+	; Turbo active?
	CMP	#$80
	ROR
+	CLC
	ADC	P2XF
	STA	P2XF
	TXA
	ADC	P2XI
	STA	P2XI
	LDA	P2TURBO
	LSR
	LDX	#$00
	LDA	SIN_TBL,Y
	BPL	+	; Sign extend into X
	DEX
+	BCS	+	; Turbo active?
	CMP	#$80
	ROR
+	CLC
	ADC	P2YF
	STA	P2YF
	TXA
	ADC	P2YI
	STA	P2YI
;*
;* Check for collision
;*
	;LDA	P2YI
	CMP	P1YI
	BNE	UPDTAIL1
	LDA	P2XI
	CMP	P1XI
	BNE	UPDTAIL1
	LDA	#$03
	STA	PSTATUS
;*
;* Update map with tails
;*
UPDTAIL1 LDX	P1XI	; Player 1 tail
	LDY	P1YI
	CPX	P1XPREV
	BNE	+
	CPY	P1YPREV
	BEQ	UPDTAIL2
+	STX	P1XPREV
	STY	P1YPREV
	INC	P1HEAD
	LDA	P1HEAD
	AND	LENTAIL
	TAX
	PHA
	LDY	P1XTAIL,X
	LDA	P1YTAIL,X
	TAX
	LDA	MAP_TBLL,X
	STA	TMP
	LDA	MAP_TBLH,X
	STA	TMP+1
	TXA	 	; Which color to clear to
	LSR
	TYA
	ADC	#$00
;	LDA	P1XTAIL,X ; Which color to clear to
;	EOR	P1YTAIL,X
	LSR
	LDA	#GREY
	BCS	+
	LDA	#DRKBLU
+	STA	(TMP),Y	; Clear map
	PLA
	TAX
	LDA	P1XI
	CMP	#$40
	BCS	DEREZ1
	STA	P1XTAIL,X
	TAY
	LDA	P1YI
	CMP	#$40
	BCS	DEREZ1
	STA	P1YTAIL,X
	TAX
	LDA	MAP_TBLL,X
	STA	TMP
	LDA	MAP_TBLH,X
	STA	TMP+1
	LDA	(TMP),Y
	CMP	#DRKBLU
	BEQ	+
	CMP	#GREY
	BEQ	+
DEREZ1	LDA	#$01	; Uh, oh. Player 1 derez!
	ORA	PSTATUS
	STA	PSTATUS
	BNE	UPDTAIL2
+	LDA	#P1TLCLR
	STA	(TMP),Y
UPDTAIL2 LDX	P2XI	; Player 2 tail
	LDY	P2YI
	CPX	P2XPREV
	BNE	+
	CPY	P2YPREV
	BEQ	CHKSTAT
+	STX	P2XPREV
	STY	P2YPREV
	INC	P2HEAD
	LDA	P2HEAD
	AND	LENTAIL
	TAX
	PHA
	LDY	P2XTAIL,X	
	LDA	P2YTAIL,X
	TAX
	LDA	MAP_TBLL,X
	STA	TMP
	LDA	MAP_TBLH,X
	STA	TMP+1
	TXA 		; Which color to clear to
	LSR
	TYA
	ADC	#$00
;	LDA	P2XTAIL,X ; Which color to clear to
;	EOR	P2YTAIL,X
	LSR
	LDA	#GREY
	BCS	+
	LDA	#DRKBLU
+	STA	(TMP),Y	; Clear map
	PLA
	TAX
	LDA	P2XI
	CMP	#$40
	BCS	DEREZ2
	STA	P2XTAIL,X
	TAY
	LDA	P2YI
	CMP	#$40
	BCS	DEREZ2
	STA	P2YTAIL,X
	TAX
	LDA	MAP_TBLL,X
	STA	TMP
	LDA	MAP_TBLH,X
	STA	TMP+1
	LDA	(TMP),Y
	CMP	#DRKBLU
	BEQ	+
	CMP	#GREY
	BEQ	+
DEREZ2	LDA	#$02	; Uh, oh. Player 2 derez!
	ORA	PSTATUS
	STA	PSTATUS
	BNE	GAMEOVER
+	LDA	#P2TLCLR
	STA	(TMP),Y
CHKSTAT	LDA	PSTATUS
	BNE	GAMEOVER
	INC	FRAMENUM
	LDA	FRAMENUM
	LSR
	AND	#$03
	TAX
	LDA	P1CYCLE+1,X
	STA	P1CYCLE
	LDA	P2CYCLE+1,X
	STA	P2CYCLE
;	LDX	#19
;	LDY	#23
;	JSR	GOTOXY
;	LDA	FRAMENUM
;	JSR	PUTA
	JMP	GAMELOOP
GAMEOVER RTS
;*
;* Calc best direction based on map
;*
MAPWTS	LDA	#$00
	STA	AIMOVE+0
	STA	AIMOVE+1
	STA	AIMOVE+2
	STA	AIMOVE+3
	TYA
	PHA
	TXA
	PHA
	TYA
	TAX
	LDA	MAP_TBLL,X
	STA	TMP
	LDA	MAP_TBLH,X
	STA	TMP+1	; Check map for obstacles
	PLA
	PHA
	TAY
	INY		; Check +X
	CPY	#$40
	BCS	++	; Off map
	LDA	(TMP),Y
	CMP	#DRKBLU
	BEQ	+
	CMP	#GREY
	BNE	++	; Some kind of obstacle
+	LDA	#$04
	STA	AIMOVE+0
	INY		; Check ++X
	CPY	#$40
	BCS	++	; Off map
	LDA	(TMP),Y
	CMP	#DRKBLU
	BEQ	+
	CMP	#GREY
	BNE	++	; Some kind of obstacle
+	LDA	#$05
	STA	AIMOVE+0
++	PLA
	PHA
	TAY
	DEY		; Check -X
	BMI	++	; Off map
	LDA	(TMP),Y
	CMP	#DRKBLU
	BEQ	+
	CMP	#GREY
	BNE	++	; Some kind of obstacle
+	LDA	#$04
	STA	AIMOVE+2
	DEY		; Check --X
	BMI	++	; Off map
	LDA	(TMP),Y
	CMP	#DRKBLU
	BEQ	+
	CMP	#GREY
	BNE	++	; Some kind of obstacle
+	LDA	#$05
	STA	AIMOVE+2
++	PLA
	TAY
	PLA
	PHA
	TAX
	INX		; Check +Y
	CPX	#$40
	BCS	++
	LDA	MAP_TBLL,X
	STA	TMP
	LDA	MAP_TBLH,X
	STA	TMP+1
	LDA	(TMP),Y
	CMP	#DRKBLU
	BEQ	+
	CMP	#GREY
	BNE	++	; Some kind of obstacle
+	LDA	#$04
	STA	AIMOVE+1
	INX		; Check ++Y
	CPX	#$40
	BCS	++
	LDA	MAP_TBLL,X
	STA	TMP
	LDA	MAP_TBLH,X
	STA	TMP+1
	LDA	(TMP),Y
	CMP	#DRKBLU
	BEQ	+
	CMP	#GREY
	BNE	++	; Some kind of obstacle
+	LDA	#$05
	STA	AIMOVE+1
++	PLA
	TAX
	DEX		; Check -Y
	BMI	++
	LDA	MAP_TBLL,X
	STA	TMP
	LDA	MAP_TBLH,X
	STA	TMP+1
	LDA	(TMP),Y
	CMP	#DRKBLU
	BEQ	+
	CMP	#GREY
	BNE	++	; Some kind of obstacle
+	LDA	#$04
	STA	AIMOVE+3
	DEX		; Check --Y
	BMI	++
	LDA	MAP_TBLL,X
	STA	TMP
	LDA	MAP_TBLH,X
	STA	TMP+1
	LDA	(TMP),Y
	CMP	#DRKBLU
	BEQ	+
	CMP	#GREY
	BNE	++	; Some kind of obstacle
+	LDA	#$05
	STA	AIMOVE+3
++	RTS
;*
;* Calc best direction based on relative enemy poition
;*
ENMYWT	TXA
	BEQ	++
	BMI	+
	INC	AIMOVE+0 ; Enemy to the right
	INC	AIMOVE+0
	BNE	++
+	INC	AIMOVE+2 ; Enemy to the left
	INC	AIMOVE+2
++	TYA
	BEQ	++
	BMI	+
	INC	AIMOVE+1 ; Enemy above
	INC	AIMOVE+1
	RTS
+	INC	AIMOVE+3 ; Enemy below
	INC	AIMOVE+3
++	RTS
;*
;* Player variables
;*
PSTATUS	!BYTE	$00	; Player alive status
PPANGLE	!BYTE	$00	; Player-to-player angle
PPDIST	!BYTE	$00	; Player-to=player distance^2
PPSIZE	!BYTE	$00	; Player-to-player size
LENTAIL	!BYTE	$0F	; Tail length
P1MAN	!BYTE	$01	; Human/AI
P1ANGLE	!BYTE	$00	; Direction
P1XF	!BYTE	$00	; Position
P1XI	!BYTE	$00
P1YF	!BYTE	$00
P1YI	!BYTE	$00
P1TURBO	!BYTE	$00
P1BOOST	!BYTE	$F0
P1XPREV	!BYTE	$FF
P1YPREV	!BYTE	$FF
P1HEAD	!BYTE	$00	; Tail list - set length for easy/med/hard
P1XTAIL	!FILL	256
P1YTAIL	!FILL	256
P1CYCLE	!BYTE	P1CLR,GRAY,P1CLR,WHITE,P1CLR
P2MAN	!BYTE	$01	; Human/AI
P2ANGLE	!BYTE	$00	; Direction
P2XF	!BYTE	$00	; Position
P2XI	!BYTE	$00
P2YF	!BYTE	$00
P2YI	!BYTE	$00
P2TURBO	!BYTE	$00
P2BOOST	!BYTE	$F0
P2XPREV	!BYTE	$FF
P2YPREV	!BYTE	$FF
P2HEAD	!BYTE	$00	; Tail list - set length for easy/med/hard
P2XTAIL	!FILL	256
P2YTAIL	!FILL	256
P2CYCLE	!BYTE	P2CLR,GRAY,P2CLR,WHITE,P2CLR
;*
;* AI best move weights
;*
AIMOVE	!BYTE	$00,$00,$00,$00
;*
;* Working variables
;*
USEPDLS	!BYTE	$00
CURPAGE	!BYTE	$01
PGBASE	!BYTE	$08,$04
FRAMENUM !BYTE	$00
DRYTHM	!BYTE	$00
VTONE	!BYTE	$01
VDLY	!BYTE	$01
MTONE	!BYTE	$01
MDLY	!BYTE	$01
;*
;* Background walls - set each wall quadrant to a different color
;*
WALLS	!BYTE	PINK,PINK,PINK,PINK,PINK,PINK,PINK,PINK,PINK,PINK,PINK,PINK,PINK,PINK,PINK,PINK
	!BYTE	YELLOW,YELLOW,YELLOW,YELLOW,YELLOW,YELLOW,YELLOW,YELLOW,YELLOW,YELLOW,YELLOW,YELLOW,YELLOW,YELLOW,YELLOW,YELLOW
	!BYTE	YELLOW,YELLOW,YELLOW,YELLOW,YELLOW,YELLOW,YELLOW,YELLOW,YELLOW,YELLOW,YELLOW,YELLOW,YELLOW,YELLOW,YELLOW,YELLOW
	!BYTE	AQUA,AQUA,AQUA,AQUA,AQUA,AQUA,AQUA,AQUA,AQUA,AQUA,AQUA,AQUA,AQUA,AQUA,AQUA,AQUA
	!BYTE	AQUA,AQUA,AQUA,AQUA,AQUA,AQUA,AQUA,AQUA,AQUA,AQUA,AQUA,AQUA,AQUA,AQUA,AQUA,AQUA
	!BYTE	ORANGE,ORANGE,ORANGE,ORANGE,ORANGE,ORANGE,ORANGE,ORANGE,ORANGE,ORANGE,ORANGE,ORANGE,ORANGE,ORANGE,ORANGE,ORANGE
	!BYTE	ORANGE,ORANGE,ORANGE,ORANGE,ORANGE,ORANGE,ORANGE,ORANGE,ORANGE,ORANGE,ORANGE,ORANGE,ORANGE,ORANGE,ORANGE,ORANGE
	!BYTE	PINK,PINK,PINK,PINK,PINK,PINK,PINK,PINK,PINK,PINK,PINK,PINK,PINK,PINK,PINK,PINK
;*
;* Map row addresses
;*
MAP_TBLL !BYTE	$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0
	!BYTE	$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0
	!BYTE	$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0
	!BYTE	$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0
MAP_TBLH !BYTE	$00+>MAP,$00+>MAP,$00+>MAP,$00+>MAP,$01+>MAP,$01+>MAP,$01+>MAP,$01+>MAP,$02+>MAP,$02+>MAP,$02+>MAP,$02+>MAP,$03+>MAP,$03+>MAP,$03+>MAP,$03+>MAP
	!BYTE	$04+>MAP,$04+>MAP,$04+>MAP,$04+>MAP,$05+>MAP,$05+>MAP,$05+>MAP,$05+>MAP,$06+>MAP,$06+>MAP,$06+>MAP,$06+>MAP,$07+>MAP,$07+>MAP,$07+>MAP,$07+>MAP
	!BYTE	$08+>MAP,$08+>MAP,$08+>MAP,$08+>MAP,$09+>MAP,$09+>MAP,$09+>MAP,$09+>MAP,$0A+>MAP,$0A+>MAP,$0A+>MAP,$0A+>MAP,$0B+>MAP,$0B+>MAP,$0B+>MAP,$0B+>MAP
	!BYTE	$0C+>MAP,$0C+>MAP,$0C+>MAP,$0C+>MAP,$0D+>MAP,$0D+>MAP,$0D+>MAP,$0D+>MAP,$0E+>MAP,$0E+>MAP,$0E+>MAP,$0E+>MAP,$0F+>MAP,$0F+>MAP,$0F+>MAP,$0F+>MAP
;*
;* Text/GR screen row addresses
;*
TXT_TBLL		; TXT/GR row pointers
	!BYTE	<$000,<$080,<$100,<$180,<$200,<$280,<$300,<$380
	!BYTE	<$028,<$0A8,<$128,<$1A8,<$228,<$2A8,<$328,<$3A8
	!BYTE	<$050,<$0D0,<$150,<$1D0,<$250,<$2D0,<$350,<$3D0
TXT_TBLH		; TXT/GR row pointers
	!BYTE	>$000,>$080,>$100,>$180,>$200,>$280,>$300,>$380
	!BYTE	>$028,>$0A8,>$128,>$1A8,>$228,>$2A8,>$328,>$3A8
	!BYTE	>$050,>$0D0,>$150,>$1D0,>$250,>$2D0,>$350,>$3D0
	!SOURCE	"grnd_st.asm"
	!SOURCE	"sincos.asm"
	!SOURCE	"tan.asm"
	!WORD	$FFFF	; Make sure tan() table search stops here


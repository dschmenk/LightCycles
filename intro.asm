	LDA	#$91	; CTRL-Q = TURN OFF 80 COLUMN
	JSR	$FDED	; COUT
	STA	$C000	; Turn off 80STORE
	STA	$C00E	; Primary charset
	CLI		; Turn off interrupts
	LDA	#<ARENAS
	STA	ARENAP
	LDA	#>ARENAS
	STA	ARENAP+1
;*
;* Check for connected paddles
;*
	JSR	GCREAD
	LDA	#$01
	CPX	#GCMAX
	BNE	+
	CPY	#GCMAX
	BNE	+
	LDA	#$00
+	STA	USEPDLS
;*
;* Initialize game state and get player options
;*
INITGAME
	LDA	$C054	; Display page 1
	JSR	$FB39	; TXT mode
	JSR	NORMAL
	JSR	$FC58	; HOME
	LDA	#$10
	STA	GCPREVX
	STA	GCPREVY
;*
;* Init player panel
;*
	JSR	INVERSE
	LDX	#0
	LDY	#20
	JSR	PUTSXY
	!TEXT	"/:::: PLAYER 1 ::::\\/:::: PLAYER 2 ::::\\", 0
	LDX	#0
	LDY	#21
	JSR	PUTSXY
	!TEXT	"! [===============]!![===============] !", 0
	LDX	#0
	LDY	#22
	JSR	PUTSXY
	!TEXT	"!  <<<<<<<*>>>>>>> !! <<<<<<<*>>>>>>>  !", 0
	LDX	#0
	LDY	#23
	JSR	PUTSXY
	!TEXT	"\\::::::::::::::::::/\\::::::::::::::::::/", 0
;*
;* Display initial setting screen
;*
SHOWOPT	JSR	NORMAL
	LDX	#12
	LDY	#0
	JSR	PUTSXY
	!TEXT	"BY: RESMAN", 0
	LDX	#10
	LDY	#1
	JSR	PUTSXY
	!TEXT	"COPYRIGHT 1977", 0
	LDX	#4
	LDY	#19
	JSR	PUTSXY
	!TEXT	"(WHY 1977 WON'T BE LIKE 1977)", 0
	LDX	#10
	LDY	#4
	JSR	GOTOXY
	JSR	INVERSE
	LDA	#'P'
	JSR	PUTC
	JSR	NORMAL
	JSR	PUTS
	!TEXT	"ADDLES: ", 0
	LDA	USEPDLS
	BEQ	+
	JSR	PUTS
	!TEXT	"ENABLE ", 0
	JMP	++
+	JSR	PUTS
	!TEXT	"DISABLE", 0
++	LDX	#10
	LDY	#7
	JSR	GOTOXY
	JSR	INVERSE
	LDA	#'A'
	JSR	PUTC
	JSR	NORMAL
	JSR	PUTS
	!TEXT	"RENA: ", 0
	LDA	ARENAP
	STA	TMP
	LDA	ARENAP+1
	STA	TMP+1
	LDY	#$00
-	TYA
	PHA
	LDA	(TMP),Y
	JSR	PUTC
	PLA
	TAY
	INY
	CPY	#$10
	BNE	-
	LDX	#10
	LDY	#10
	JSR	PUTSXY
	!TEXT	"PLAYER ", 0
	JSR	INVERSE
	LDA	#'1'
	JSR	PUTC
	JSR	NORMAL
	LDA	P1MAN
	BEQ	+
	JSR	PUTS
	!TEXT	": HUMAN   ", 0
	JMP	++
+	JSR	PUTS
	!TEXT	": COMPUTER", 0
++	LDX	#10
	LDY	#11
	JSR	PUTSXY
	!TEXT	"PLAYER ", 0
	JSR	INVERSE
	LDA	#'2'
	JSR	PUTC
	JSR	NORMAL
	LDA	P2MAN
	BEQ	+
	JSR	PUTS
	!TEXT	": HUMAN   ", 0
	JMP	++
+	JSR	PUTS
	!TEXT	": COMPUTER", 0
++	LDX	#10
	LDY	#14
	JSR	PUTSXY
	!TEXT	"START GAME:", 0
	LDX	#15
	LDY	#15
	JSR	GOTOXY
	JSR	INVERSE
	LDA	#'S'
	JSR	PUTC
	JSR	NORMAL
	JSR	PUTS
	!TEXT	"HORT  TRAIL", 0
	LDX	#15
	LDY	#16
	JSR	GOTOXY
	JSR	INVERSE
	LDA	#'M'
	JSR	PUTC
	JSR	NORMAL
	JSR	PUTS
	!TEXT	"EDIUM TRAIL", 0
	LDX	#15
	LDY	#17
	JSR	GOTOXY
	JSR	INVERSE
	LDA	#'L'
	JSR	PUTC
	JSR	NORMAL
	JSR	PUTS
	!TEXT	"ONG   TRAIL", 0
;*
;* Scan for option input
;*
OPTION	LDA	KEYBD
	BMI	+
	JMP	OPTPDLS
+	BIT	KEYSTRB
	CMP	#$D0	; P key
	BNE	+
	LDA	USEPDLS
	EOR	#$01
	STA	USEPDLS
	JMP	SHOWOPT
+	CMP	#$C1	; A key
	BNE	++
	; Move to next arena
	LDA	ARENAP
	STA	TMP
	LDA	ARENAP+1
	STA	TMP+1
	LDY	#$1A	; Scan for end of compressed map
-	LDA	(TMP),Y
	BEQ	+
	INY
	BNE	-
+	INY
	TYA
	CLC
	ADC	TMP
	STA	TMP
	LDA	#$00
	ADC	TMP+1
	STA	TMP+1
	LDY	#$00
	LDA	(TMP),Y
	BNE	-
	INY
	LDA	(TMP),Y	; Check for end of arena == 0
	BNE	+
	LDA	#<ARENAS ; Wrap around to beginning
	STA	ARENAP
	LDA	#>ARENAS
	STA	ARENAP+1
	JMP	SHOWOPT
+	TYA
	CLC
	ADC	TMP
	STA	ARENAP
	LDA	#$00
	ADC	TMP+1
	STA	ARENAP+1
	JMP	SHOWOPT
++	CMP	#$B1	; 1 KEY
	BNE	+
	LDA	P1MAN
	EOR	#$01
	STA	P1MAN
	JMP	SHOWOPT
+	CMP	#$B2	; 2 KEY
	BNE	+
	LDA	P2MAN
	EOR	#$01
	STA	P2MAN
	JMP	SHOWOPT
+	CMP	#$D3	; S key
	BNE	+
	LDA	#$0F
	STA	LENTAIL
	BNE	STARTGAME
+	CMP	#$CD	; M key
	BNE	+
	LDA	#$7F
	STA	LENTAIL
	BNE	STARTGAME
+	CMP	#$CC	; L key
	BNE	+
	LDA	#$FF
	STA	LENTAIL
	BNE	STARTGAME
+	CMP	#$9B	; ESC key
	BNE	OPTPDLS
	JMP	EXIT
OPTPDLS	LDA	USEPDLS
	BEQ	+
	JSR	GCREAD
	JSR	UPDTPDL
+	JMP	OPTION
STARTGAME
;*
;* Init arena map
;*
	LDA	#>MAP
	STA	STPTRH
	LDY	#<MAP	; Better be $00
	STY	STPTRL
INITMAP	LDA	#DRKBLU	; Fill even row
	STA	(STPTR),Y
	INY
	LDA	#GREY
	STA	(STPTR),Y
	INY
	CPY	#$40
	BCC	INITMAP
-	LDA	#GREY	; Fill odd row
	STA	(STPTR),Y
	INY
	LDA	#DRKBLU
	STA	(STPTR),Y
	INY
	BPL	-
-	LDA	#DRKBLU	; Fill even row
	STA	(STPTR),Y
	INY
	LDA	#GREY
	STA	(STPTR),Y
	INY
	CPY	#$C0
	BCC	-
-	LDA	#GREY	; Fill odd row
	STA	(STPTR),Y
	INY
	LDA	#DRKBLU
	STA	(STPTR),Y
	INY
	BNE	-
	INC	STPTRH
	LDA	STPTRH
	CMP	#>(MAP+$1000)
	BNE	INITMAP
;*
;* Get arena initial start positions
;*
	LDA	ARENAP
	STA	TMP
	LDA	ARENAP+1
	STA	TMP+1
	LDY	#$10	; Copy start angle/pos out of arena map
	LDA	(TMP),Y
	STA	P1ANGLE
	INY
	LDA	(TMP),Y
	STA	P1XF
	INY
	LDA	(TMP),Y
	STA	P1XI
	STA	P1XPREV
	INY
	LDA	(TMP),Y
	STA	P1YF
	INY
	LDA	(TMP),Y
	STA	P1YI
	STA	P1YPREV
	INY
	LDA	(TMP),Y
	STA	P2ANGLE
	INY
	LDA	(TMP),Y
	STA	P2XF
	INY
	LDA	(TMP),Y
	STA	P2XI
	STA	P2XPREV
	INY
	LDA	(TMP),Y
	STA	P2YF
	INY
	LDA	(TMP),Y
	STA	P2YI
	STA	P2YPREV
;*
;* Init rest of player variables
;*
	LDX	#$00	; Clear out tails
-	LDA	#$40
	STA	P1YTAIL,X
	STA	P2YTAIL,X
	LDA	#$00
	STA	P1XTAIL,X
	LDA	#$7F
	STA	P2XTAIL,X
	DEX
	BNE	-
	STX	P1TURBO	; Reset turbo values
	STX	P2TURBO
	LDA	#FULLBOOST
	STA	P1BOOST
	STA	P2BOOST
;*
;* Start decompressing into map
;*
	LDA	#>MAP
	STA	STPTRH
	LDA	#<MAP
	STA	STPTRL
DECOMP	INY
	LDA	(TMP),Y
	BEQ	GETCNT
	BRK		; This better not happen
GETCNT	INY
	LDA	(TMP),Y
	BNE	+
	JMP	INITGR	; Done decompressing, init graphics mode
+	STA	SCANLN
	INY
	TYA
	CLC
	ADC	TMP
	STA	TMP
	LDA	#$00
	ADC	TMP+1
	STA	TMP+1
REPSCAN	LDY	#$00
--	LDA	(TMP),Y
	BNE	+
	DEC	SCANLN
	BNE	REPSCAN
	BEQ	GETCNT
+	BMI	+
	TAX
	TYA
	PHA
	TXA
	TAY
	LDA	#$00
-	DEY
	STA	(STPTR),Y
	BNE	-
	PLA
	TAY
	TXA
+	AND	#$7F
	CLC
	ADC	STPTRL
	STA	STPTRL
	LDA	#$00
	ADC	STPTRH
	STA	STPTRH
	INY
	BNE	--
;*
;* Clear screens
;*
INITGR	LDA	$C053	; Mix mode
	LDA	$C056	; GR mode
	LDA	$C050
	LDA	#$08	; Render to page2
	STA	GPAGE
	LDA	#BLACK
	STA	GCLR
	LDY	#0
	LDX	#0
	LDA	#39
	STA	SCANLN
	LDA	#39
	JSR	GRECT
	LDA	#$04	; Render to page 1
	STA	GPAGE
	LDA	#BLACK
	STA	GCLR
	LDY	#0
	LDX	#0
	LDA	#39
	STA	SCANLN
	LDA	#39
	JSR	GRECT
	LDA	#$01	; Set current page to 1
	STA	CURPAGE
	JSR	GAMELOOP
;*
;* Return to caller
;*
	PHA
	AND	#$01	; Player 1 DeRez?
	BEQ	+
	LDA	#MAGENTA
	STA	GCLR
	LDY	#0
	LDX	#0
	LDA	#19
	STA	SCANLN
	LDA	#39
	JSR	GRECT
+	PLA
	AND	#$02	; Player 2 DeRez?
	BEQ	+
	LDA	#MAGENTA
	STA	GCLR
	LDY	#20
	LDX	#0
	LDA	#39
	STA	SCANLN
	LDA	#39
	JSR	GRECT
+	LDX	#$20
-	LDA	$C055	; Display page 2
	BIT	SPEAKER
	LDA	#$7F
	JSR	$FCA8	; WAIT
	LDA	$C054	; Display page 1
	BIT	SPEAKER
	LDA	#$7F
	JSR	$FCA8	; WAIT
	DEX
	BNE	-
	JSR	$FB39	; TXT mode
	JSR	$FC58	; HOME
	BIT	KEYSTRB
	LDX	#10
	LDY	#12
	JSR	GOTOXY
	LDA	PSTATUS
	CMP	#$03
	BEQ	+
	JSR	PUTS
	!TEXT	"PLAYER ", 0
	LDA	PSTATUS
	EOR	#$03
	JSR	PUTA
	JSR	PUTS
	!TEXT	" WINS!", 0
	JMP	++
+	JSR	PUTS
	!TEXT	"   DRAW !!!", 0
++	LDX	#$10
-	LDA	#$FF
	JSR	$FCA8	; WAIT
	DEX
	BNE	-
	JMP	INITGAME
EXIT	JSR	NORMAL
	LDA	$BF00
	CMP	#$4C
	BNE	+	; No ProDOS
	SEI		; Turn interrupts on
	JSR	$BF00	; ProDOS QUIT
	!BYTE	$65
	!WORD	PARMTBL
PARMTBL	!BYTE	4
	!BYTE	0
	!WORD	0
	!BYTE	0
	!WORD	0
+	JMP	($FFFC)	; Reset vector
ARENAS	!TEXT	"BASIC           "
	!BYTE	$00	; P1 ANGLE
	!WORD	$0080	; P1 X 0.5
	!WORD	$2080	; P1 Y 32.5
	!BYTE	$40	; P2 ANGLE
	!WORD	$3F80	; P2 X 63.5
	!WORD	$2080	; P2 Y	32.5
			; Start of compressed map
	!BYTE	0,64	; Scanline repeat count (1..64)
	!BYTE	128+64	; Set 64 tiles
	!BYTE	0,0	; End of compressed map

	!TEXT	"DRAG RACE       "
	!BYTE	$00	; P1 ANGLE
	!WORD	$0080	; P1 X 0.5
	!WORD	$1E80	; P1 Y 30.5
	!BYTE	$00	; P2 ANGLE
	!WORD	$0080	; P2 X 0.5
	!WORD	$2280	; P2 Y 34.5
			; Start of compressed map
	!BYTE	0,20	; Scanline repeat count
	!BYTE	128+64
	!BYTE	0,9	; Scanline repeat count
	!BYTE	45,128+19
	!BYTE	0,3	; Scanline repeat count
	!BYTE	128+64
	!BYTE	0,1	; Scanline repeat count
	!BYTE	1,128+3,5,128+3,5,128+3,5,128+3,5,128+3,5,128+3,20
	!BYTE	0,3	; Scanline repeat count
	!BYTE	128+64
	!BYTE	0,9	; Scanline repeat count
	!BYTE	45,128+19
	!BYTE	0,19	; Scanline repeat count
	!BYTE	128+64
	!BYTE	0,0	; End of compressed map

	!TEXT	"BLACK HOLE      "
	!BYTE	$00	; P1 ANGLE
	!WORD	$0080	; P1 X 0.5
	!WORD	$2080	; P1 Y 32.5
	!BYTE	$40	; P2 ANGLE
	!WORD	$3F80	; P2 X 63.5
	!WORD	$2080	; P2 Y	32.5
			; Start of compressed map
	!BYTE	0,4	; Scanline repeat count
	!BYTE	128+64
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+28,7,128+1,1,128+27
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+24,16,128+24
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+21,22,128+21
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+19,26,128+19
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+17,30,128+17
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+16,32,128+16
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+14,36,128+14
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+13,38,128+13
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+12,40,128+12
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+11,42,128+11
	!BYTE	0,2	; Scanline repeat count
	!BYTE	128+10,44,128+10
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+9,46,128+9
	!BYTE	0,2	; Scanline repeat count
	!BYTE	128+8,48,128+8
	!BYTE	0,2	; Scanline repeat count
	!BYTE	128+7,50,128+7
	!BYTE	0,3	; Scanline repeat count
	!BYTE	128+6,52,128+6
	!BYTE	0,4	; Scanline repeat count
	!BYTE	128+5,54,128+5
	!BYTE	0,8	; Scanline repeat count
	!BYTE	128+4,56,128+4
	!BYTE	0,4	; Scanline repeat count
	!BYTE	128+5,54,128+5
	!BYTE	0,3	; Scanline repeat count
	!BYTE	128+6,52,128+6
	!BYTE	0,2	; Scanline repeat count
	!BYTE	128+7,50,128+7
	!BYTE	0,2	; Scanline repeat count
	!BYTE	128+8,48,128+8
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+9,46,128+9
	!BYTE	0,2	; Scanline repeat count
	!BYTE	128+10,44,128+10
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+11,42,128+11
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+12,40,128+12
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+13,38,128+13
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+14,36,128+14
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+16,32,128+16
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+17,30,128+17
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+19,26,128+19
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+21,22,128+21
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+24,16,128+24
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+28,7,128+1,1,128+27
	!BYTE	0,4	; Scanline repeat count
	!BYTE	128+64
	!BYTE	0,0	; End of compressed map

	!TEXT	"IRON CROSS      "
	!BYTE	$00	; P1 ANGLE
	!WORD	$0080	; P1 X 0.5
	!WORD	$2080	; P1 Y 32.5
	!BYTE	$40	; P2 ANGLE
	!WORD	$3F80	; P2 X 63.5
	!WORD	$2080	; P2 Y	32.5
			; Start of compressed map
	!BYTE	0,4	; Scanline repeat count
	!BYTE	17,128+31,16
	!BYTE	0,1	; Scanline repeat count
	!BYTE	21,128+23,20
	!BYTE	0,1	; Scanline repeat count
	!BYTE	22,128+21,21
	!BYTE	0,1	; Scanline repeat count
	!BYTE	23,128+19,22
	!BYTE	0,1	; Scanline repeat count
	!BYTE	24,128+17,23
	!BYTE	0,9	; Scanline repeat count
	!BYTE	25,128+15,24
	!BYTE	0,4	; Scanline repeat count
	!BYTE	128+4,21,128+15,21,128+3
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+5,20,128+15,20,128+4
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+6,19,128+15,19,128+5
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+7,19,128+13,19,128+6
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+8,19,128+11,19,128+7
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+23,4,128+11,4,128+22
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+24,3,128+11,3,128+23
	!BYTE	0,11	; Scanline repeat count
	!BYTE	128+64
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+24,3,128+11,3,128+23
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+23,4,128+11,4,128+22
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+8,19,128+11,19,128+7
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+7,19,128+13,19,128+6
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+6,19,128+15,19,128+5
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+5,20,128+15,20,128+4
	!BYTE	0,4	; Scanline repeat count
	!BYTE	128+4,21,128+15,21,128+3
	!BYTE	0,9	; Scanline repeat count
	!BYTE	25,128+15,24
	!BYTE	0,1	; Scanline repeat count
	!BYTE	24,128+17,23
	!BYTE	0,1	; Scanline repeat count
	!BYTE	23,128+19,22
	!BYTE	0,1	; Scanline repeat count
	!BYTE	22,128+21,21
	!BYTE	0,1	; Scanline repeat count
	!BYTE	21,128+23,20
	!BYTE	0,3	; Scanline repeat count
	!BYTE	16,128+32,16
	!BYTE	0,0	; End of compressed map

	!TEXT	"GRID            "
	!BYTE	$00	; P1 ANGLE
	!WORD	$0080	; P1 X 0.5
	!WORD	$2080	; P1 Y 32.5
	!BYTE	$40	; P2 ANGLE
	!WORD	$3F80	; P2 X 63.5
	!WORD	$2080	; P2 Y	32.5
			; Start of compressed map
	!BYTE	0,8	; Scanline repeat count (1..64)
	!BYTE	128+64	; Set 64 tiles
	!BYTE	128+64	; Set 64 tiles
	!BYTE	128+2,4,128+4,4,128+4,4,128+4,4,128+4,4,128+4,4,128+4,4,128+4,4,128+2
	!BYTE	128+2,4,128+4,4,128+4,4,128+4,4,128+4,4,128+4,4,128+4,4,128+4,4,128+2
	!BYTE	128+2,4,128+4,4,128+4,4,128+4,4,128+4,4,128+4,4,128+4,4,128+4,4,128+2
	!BYTE	128+2,4,128+4,4,128+4,4,128+4,4,128+4,4,128+4,4,128+4,4,128+4,4,128+2
	!BYTE	128+64	; Set 64 tiles	
	!BYTE	128+64	; Set 64 tiles	
	!BYTE	0,0	; End of compressed map

	!TEXT	"RINGS           "
	!BYTE	$00	; P1 ANGLE
	!WORD	$0080	; P1 X 0.5
	!WORD	$2080	; P1 Y 32.5
	!BYTE	$40	; P2 ANGLE
	!WORD	$3F80	; P2 X 63.5
	!WORD	$2080	; P2 Y	32.5
			; Start of compressed map
	!BYTE	0,1	; Scanline repeat count
	!BYTE	25,128+14,25
	!BYTE	0,1	; Scanline repeat count
	!BYTE	22,128+20,22
	!BYTE	0,1	; Scanline repeat count
	!BYTE	19,128+26,19
	!BYTE	0,1	; Scanline repeat count
	!BYTE	17,128+30,17
	!BYTE	0,1	; Scanline repeat count
	!BYTE	15,128+34,15
	!BYTE	0,1	; Scanline repeat count
	!BYTE	14,128+36,14
	!BYTE	0,1	; Scanline repeat count
	!BYTE	12,128+40,12
	!BYTE	0,1	; Scanline repeat count
	!BYTE	11,128+42,11
	!BYTE	0,1	; Scanline repeat count
	!BYTE	10,128+18,2,128+4,1,128+19,10
	!BYTE	0,1	; Scanline repeat count
	!BYTE	9,128+15,6,128+4,6,128+15,9
	!BYTE	0,1	; Scanline repeat count
	!BYTE	8,128+14,8,128+4,8,128+14,8
	!BYTE	0,1	; Scanline repeat count
	!BYTE	7,128+13,10,128+4,10,128+13,7
	!BYTE	0,1	; Scanline repeat count
	!BYTE	6,128+12,12,128+4,12,128+12,6
	!BYTE	0,1	; Scanline repeat count
	!BYTE	6,128+11,13,128+4,13,128+11,6
	!BYTE	0,1	; Scanline repeat count
	!BYTE	5,128+11,14,128+4,14,128+11,5
	!BYTE	0,1	; Scanline repeat count
	!BYTE	4,128+11,15,128+4,15,128+11,4
	!BYTE	0,1	; Scanline repeat count
	!BYTE	4,128+10,15,128+6,15,128+10,4
	!BYTE	0,1	; Scanline repeat count
	!BYTE	3,128+10,13,128+12,13,128+10,3
	!BYTE	0,1	; Scanline repeat count
	!BYTE	3,128+9,12,128+16,12,128+9,3
	!BYTE	0,1	; Scanline repeat count
	!BYTE	2,128+10,10,128+20,10,128+10,2
	!BYTE	0,1	; Scanline repeat count
	!BYTE	2,128+9,10,128+22,10,128+9,2
	!BYTE	0,1	; Scanline repeat count
	!BYTE	2,128+9,9,128+24,9,128+9,2
	!BYTE	0,2	; Scanline repeat count
	!BYTE	1,128+9,9,128+26,9,128+9,1
	!BYTE	0,1	; Scanline repeat count
	!BYTE	1,128+8,9,128+12,4,128+12,9,128+8,1
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+9,9,128+10,8,128+10,9,128+9
	!BYTE	0,2	; Scanline repeat count
	!BYTE	128+9,8,128+9,12,128+9,8,128+9
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+8,9,128+8,14,128+8,9,128+8
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+8,8,128+9,14,128+9,8,128+8
	!BYTE	0,4	; Scanline repeat count
	!BYTE	128+8,8,128+8,16,128+8,8,128+8
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+8,8,128+9,14,128+9,8,128+8
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+8,9,128+8,14,128+8,9,128+8
	!BYTE	0,2	; Scanline repeat count
	!BYTE	128+9,8,128+9,12,128+9,8,128+9
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+9,9,128+10,8,128+10,9,128+8,1
	!BYTE	0,1	; Scanline repeat count
	!BYTE	1,128+8,9,128+12,4,128+12,9,128+8,1
	!BYTE	0,2	; Scanline repeat count
	!BYTE	1,128+9,9,128+26,9,128+9,1
	!BYTE	0,1	; Scanline repeat count
	!BYTE	2,128+9,9,128+24,9,128+9,2
	!BYTE	0,1	; Scanline repeat count
	!BYTE	2,128+9,10,128+22,10,128+9,2
	!BYTE	0,1	; Scanline repeat count
	!BYTE	2,128+10,10,128+20,10,128+10,2
	!BYTE	0,1	; Scanline repeat count
	!BYTE	3,128+9,12,128+16,12,128+9,3
	!BYTE	0,1	; Scanline repeat count
	!BYTE	3,128+10,13,128+12,13,128+10,3
	!BYTE	0,1	; Scanline repeat count
	!BYTE	4,128+10,15,128+6,15,128+10,4
	!BYTE	0,1	; Scanline repeat count
	!BYTE	4,128+11,15,128+4,15,128+11,4
	!BYTE	0,1	; Scanline repeat count
	!BYTE	5,128+11,14,128+4,14,128+11,5
	!BYTE	0,1	; Scanline repeat count
	!BYTE	6,128+11,13,128+4,13,128+11,6
	!BYTE	0,1	; Scanline repeat count
	!BYTE	6,128+12,12,128+4,12,128+12,6
	!BYTE	0,1	; Scanline repeat count
	!BYTE	7,128+13,10,128+4,10,128+13,7
	!BYTE	0,1	; Scanline repeat count
	!BYTE	8,128+14,8,128+4,8,128+14,8
	!BYTE	0,1	; Scanline repeat count
	!BYTE	9,128+15,6,128+4,6,128+15,9
	!BYTE	0,1	; Scanline repeat count
	!BYTE	10,128+17,1,128+1,1,128+4,2,128+18,10
	!BYTE	0,1	; Scanline repeat count
	!BYTE	11,128+42,11
	!BYTE	0,1	; Scanline repeat count
	!BYTE	12,128+40,12
	!BYTE	0,1	; Scanline repeat count
	!BYTE	14,128+36,14
	!BYTE	0,1	; Scanline repeat count
	!BYTE	15,128+34,15
	!BYTE	0,1	; Scanline repeat count
	!BYTE	17,128+30,17
	!BYTE	0,1	; Scanline repeat count
	!BYTE	19,128+26,19
	!BYTE	0,1	; Scanline repeat count
	!BYTE	22,128+20,22
	!BYTE	0,1	; Scanline repeat count
	!BYTE	26,128+13,25
	!BYTE	0,0	; End of compressed map

	!TEXT	"MAZE            "
	!BYTE	$00	; P1 ANGLE
	!WORD	$0080	; P1 X 0.5
	!WORD	$2080	; P1 Y 32.5
	!BYTE	$40	; P2 ANGLE
	!WORD	$3F80	; P2 X 63.5
	!WORD	$2080	; P2 Y	32.5
			; Start of compressed map
	!BYTE	0,4	; Scanline repeat count
	!BYTE	128+64
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+4,57,128+3
	!BYTE	0,3	; Scanline repeat count
	!BYTE	128+4,1,128+19,1,128+23,1,128+3,1,128+7,1,128+3
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+4,1,128+3,13,128+3,1,128+3,13,128+3,5,128+3,1,128+3,1,128+3,1,128+3
	!BYTE	0,3	; Scanline repeat count
	!BYTE	128+4,1,128+3,1,128+15,1,128+19,1,128+3,1,128+3,1,128+3,1,128+3,1,128+3
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+4,1,128+3,1,128+3,9,128+3,1,128+3,9,128+3,1,128+3,1,128+3,1,128+3,1,128+3,1,128+3,1,128+3
	!BYTE	0,3	; Scanline repeat count
	!BYTE	128+4,1,128+3,1,128+15,1,128+11,1,128+3,1,128+3,1,128+3,1,128+7,1,128+3,1,128+3
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+4,1,128+3,13,128+3,1,128+3,9,128+3,1,128+3,1,128+3,9,128+3,1,128+3
	!BYTE	0,3	; Scanline repeat count
	!BYTE	128+4,1,128+15,1,128+3,1,128+27,1,128+7,1,128+3
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+4,13,128+3,1,128+3,13,128+3,1,128+3,5,128+3,1,128+3,5,128+3
	!BYTE	0,3	; Scanline repeat count
	!BYTE	128+20,1,128+19,1,128+15,1,128+7
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+4,13,128+3,17,128+3,1,128+3,9,128+3,1,128+3,1,128+3
	!BYTE	0,3	; Scanline repeat count
	!BYTE	128+4,1,128+35,1,128+11,1,128+3,1,128+3,1,128+3
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+4,1,128+3,33,128+3,5,128+3,1,128+3,1,128+3,1,128+3
	!BYTE	0,3	; Scanline repeat count
	!BYTE	128+40,1,128+7,1,128+3,1,128+11
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+4,13,128+3,17,128+3,9,128+3,1,128+3,5,128+3
	!BYTE	0,3	; Scanline repeat count
	!BYTE	128+20,1,128+7,1,128+11,1,128+7,1,128+3,1,128+3,1,128+7
	!BYTE	0,1	; Scanline repeat count
	!BYTE	8,128+4,5,128+3,1,128+3,1,128+3,9,128+3,1,128+7,1,128+3,1,128+3,1,128+3,1,128+3
	!BYTE	0,3	; Scanline repeat count
	!BYTE	128+4,1,128+15,1,128+3,1,128+11,1,128+19,1,128+3,1,128+3
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+4,1,128+3,13,128+3,1,128+3,5,128+3,1,128+3,5,128+3,1,128+3,5,128+3,1,128+3
	!BYTE	0,3	; Scanline repeat count
	!BYTE	128+4,1,128+15,1,128+3,1,128+7,1,128+3,1,128+7,1,128+3,1,128+11,1,128+3
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+4,1,128+3,1,128+3,5,128+3,1,128+3,9,128+3,1,128+3,1,128+3,1,128+3,1,128+3,9,128+3
	!BYTE	0,3	; Scanline repeat count
	!BYTE	128+4,1,128+3,1,128+7,1,128+3,1,128+15,1,128+3,1,128+7,1,128+11,1,128+3
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+4,1,128+3,17,128+3,1,128+3,5,128+3,5,128+3,1,128+3,1,128+3,1,128+3,1,128+3
	!BYTE	0,3	; Scanline repeat count
	!BYTE	128+4,1,128+3,1,128+19,1,128+19,1,128+3,1,128+3,1,128+3,1,128+3
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+4,1,128+3,1,128+3,9,128+3,1,128+3,1,128+3,5,128+3,5,128+3,1,128+3,1,128+3,5,128+3
	!BYTE	0,3	; Scanline repeat count
	!BYTE	128+24,1,128+3,1,128+7,1,128+3,1,128+7,1,128+3,1,128+11
	!BYTE	0,1	; Scanline repeat count
	!BYTE	21,128+3,1,128+3,1,128+3,1,128+3,1,128+3,1,128+3,1,128+3,1,128+3,9,128+3
	!BYTE	0,3	; Scanline repeat count
	!BYTE	128+8,1,128+7,1,128+7,1,128+7,1,128+11,1,128+3,1,128+11,1,128+3
	!BYTE	0,1	; Scanline repeat count
	!BYTE	128+4,1,128+3,1,128+3,1,128+3,1,128+3,1,128+3,1,128+3,1,128+3,13,128+3,9,128+3,1,128+3
	!BYTE	0,3	; Scanline repeat count
	!BYTE	128+4,1,128+7,1,128+7,1,128+3,1,128+3,1,128+27,1,128+7
	!BYTE	0,0	; End of compressed map

	!BYTE	$00	; End of arenas

ARENAP	!WORD	ARENAS

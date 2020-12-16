Module_Undertale:
	PHP

	COP
	COP
	COP

	SEP #$24 ; 8 bit and disable IRQ
	LDA.b #$20

	COP
	COP
	COP

.wait
	BIT.w RDNMI
	BPL .wait
	DEC
	BNE .wait
	LDA #$00 ; no auto joypad, no interrupts
	STA.w NMITIMEN

;	SEP #$30
;	LDA.b #$00
;	STA.l COLOR_BLIND

	REP #$38 ; 16 bit and disable decimal
	PHA
	PHX
	PHY
	PHB
	PHD

	PHK
	PLB

	PEA.w !DIRECT_PAGE_LOCATION
	PLD

	LDX #$00FF

--	STZ.b $00, X
	DEX
	BNE --

	SEP #$20

	LDX.w #$8008
	STX.w DMA0MODE

	LDX.w #!DIRECT_PAGE_LOCATION
	STX.w WMADDL
	STZ.w WMADDH

	LDA.b #ZeroLand2+1>>16
	LDX.w #ZeroLand2+1>>0
	STX.w DMA0ADDRL
	STA.w DMA0ADDRB

	LDX.w #$1000
	STX.w DMA0SIZE

	LDA.b #$01
	STA.w DMAENABLE

	REP #$20

	; seed RNG
	LDA.l $7E0FA1 ; seed with lttp's rng if possible
	AND #$00FF
	BEQ ++
	SEP #$20
	XBA
	LDA.l $7E0FA1
	EOR.l $7E001A ; frame counter
	REP #$20
	BRA +

++	LDA.w #$1824
+	STA.w WRAM.RNGseedX


	LDA.l $7EF360 ; rupee count
	BEQ ++
	ROL
	ROL
	ROL
	ROL
	BRA +

++	LDA.w #$122E
+	STA.w WRAM.RNGseedY

	SEP #$30
	; set up HP
	LDA.l $7EF36C

	LDA.b #$A0 ; hardcoded 20hp
	LSR ; 1 heart = 4 hp
	STA.b DP.HP
	STA.b DP.HP.MAX

	JSL Module_BattleInit

	STZ.b DP.Scratch+3

	LDX.b #$00
--	LDA.l HardCodedBottles, X
	BEQ .skipbottle
	TAY
	PHX
	LDX.b DP.Scratch+3

	LDA.w .bottles, Y
	STA.b DP.Items, X

	INX
	STX.b DP.Scratch+3
	PLX

.skipbottle
	INX
	CPX.b #4
	BCC --

.loop
	SEP #$30
	LDA.b DP.Undertale
	BNE .exit

.continue
	JSR NMIWaiter

	SEP #$30

	LDA.b DP.Module
	ASL
	TAX

	PHK ; oh god i'm using this shitty trick
	JSR (.pointers, X) ; because I want the code to be easily portable
	BRA .loop

.exit

	JSR WaitForVBlank

	; TODO game mode test

	REP #$30

	PLD
	PLB
	PLY
	PLX
	PLA
	PLP

	RTL

.pointers
	dw Module_BattleInit
	dw Module_Battle
	dw Module_Return

.bottles
	db 0 ; no bottle
	db 0 ; insanity potion
	db 0 ; empty bottle
	db 1 ; red
	db 2 ; green
	db 3 ; blue
	db 4 ; fairy
	db 5 ; bee
	db 5 ; good bee

HardCodedBottles:
	db 3, 4, 5, 6

Module_BattleInit:
	JSR WaitForVBlank

	SEP #$30
	STZ.b DP.Submodule
	INC.b DP.Module

	LDA #$80
	STA.w INIDISP

	LDA.b #7
	STA.b DP.BoxW

	REP #$10
	LDX.w #$0000

	LDA #$0F
	STA.b DP.INIDISP

	STZ.b DP.BGMODE
	STZ.b DP.MOSAIC

	LDA.b #!BG_1_MAP>>9
	STA.b DP.BG1SC

	LDA.b #!BG_2_MAP>>9
	STA.b DP.BG2SC

	LDA.b #!BG_3_MAP>>9
	STA.b DP.BG3SC
	LDA.b #!BG_4_MAP>>9
	STA.b DP.BG4SC

	LDA.b #!BG12NBA_BATTLE
	STA.b DP.BG12NBA

	LDA.b #!BG34NBA_BATTLE
	STA.b DP.BG34NBA

	LDA.b #$02
	STA.b DP.OBSEL

	STX.b DP.BG1HOFS
	STX.b DP.BG1VOFS
	STX.b DP.BG2HOFS
	STX.b DP.BG2VOFS
	STX.b DP.BG3HOFS
	STX.b DP.BG3VOFS
	STX.b DP.BG4HOFS
	STX.b DP.BG4VOFS

	STZ.b DP.W12SEL
	STZ.b DP.W34SEL
	STZ.b DP.WINDOW1L
	STZ.b DP.WINDOW1R
	STZ.b DP.WINDOW2L
	STZ.b DP.WINDOW2R
	STZ.b DP.WBGLOG

#ZeroLand2:
	LDA.b #$00
	STA.b DP.MAINDES
	STA.b DP.SUBDES

	STZ.b DP.CGWSEL
	STZ.b DP.CGADSUB
	STZ.b DP.COLDATA.R
	STZ.b DP.COLDATA.G
	STZ.b DP.COLDATA.B

	; graphics DMAs
	REP #$20
	SEP #$10
	LDY #$01

	LDX #$80
	STX.w VMAIN

	LDA.w #$1809
	STA.w DMA0MODE

	LDA.w #VRAMaddr(!BG_1_MAP)
	STA.w VMADDR

	LDX.b #ZeroLand2+1>>16
	LDA.w #ZeroLand2+1>>0
	STA.w DMA0ADDRL
	STX.w DMA0ADDRB

	LDA.w #$0800*4
	STA.w DMA0SIZE

	STY.w DMAENABLE

	; battle HUD
	LDA.w #$1801
	STA.w DMA0MODE

	LDX.b #BattleHUD>>16
	LDA.w #BattleHUD>>0
	STA.w DMA0ADDRL
	STX.w DMA0ADDRB

	LDA.w #$0800*3
	STA.w DMA0SIZE

	LDA.w #VRAMaddr(!BG_1_CHRS)
	STA.w VMADDR

	STY.w DMAENABLE

	LDX.b #SpritesGFX>>16
	LDA.w #SpritesGFX>>0
	STA.w DMA0ADDRL
	STX.w DMA0ADDRB

	LDA.w #$0800*3
	STA.w DMA0SIZE

	LDA.w #VRAMaddr(!OAM_CHARS)
	STA.w VMADDR

	STY.w DMAENABLE

	LDX.b #GanonGFX>>16
	LDA.w #GanonGFX>>0
	STA.w DMA0ADDRL
	STX.w DMA0ADDRB

	LDA.w #$0800*2
	STA.w DMA0SIZE

	LDA.w #VRAMaddr(!OAM_CHARS2)
	STA.w VMADDR

	STY.w DMAENABLE

	LDX.b #AttackGFX>>16
	LDA.w #AttackGFX>>0
	STA.w DMA0ADDRL
	STX.w DMA0ADDRB

	LDA.w #$0800*4
	STA.w DMA0SIZE

	LDA.w #VRAMaddr(!BG_3_CHRS)
	STA.w VMADDR

	STY.w DMAENABLE

	; palettes
	LDX.b #$00
	STX.w CGADD

	LDA.w #$2202
	STA.w DMA0MODE

	; use this 4 times
	LDA.w #BattlePalettes_bg1
	LDX.b #BattlePalettes_bg1>>16

	STX.w DMA0ADDRB
	STA.w DMA0ADDRL

	LDX.b #4*8*2
	STX.w DMA0SIZE
	STY.w DMAENABLE

	LDA.w #BattlePalettes_bg2
	STA.w DMA0ADDRL
	STX.w DMA0SIZE
	STY.w DMAENABLE

	LDA.w #BattlePalettes_bg3
	STA.w DMA0ADDRL
	STX.w DMA0SIZE
	STY.w DMAENABLE

	LDA.w #BattlePalettes_bg4
	STA.w DMA0ADDRL
	STX.w DMA0SIZE
	STY.w DMAENABLE

	LDA.w #BattlePalettes_sprites
	STA.w DMA0ADDRL
	LDX.b #$40
	STX.w DMA0SIZE
	STY.w DMAENABLE

	; Colorblind fixes
;	LDA.l COLOR_BLIND
;	TAX
;	BEQ .colorful
;
;	; red/green -> black/white for BG1 HP bar
;	LDX.b #14
;	STX.w CGADD
;	LDA.w #hexto555($F8F8F8)
;	SEP #$20
;	STZ.w CGDATA
;	STZ.w CGDATA
;
;	STA.w CGDATA
;	XBA
;	STA.w CGDATA
;	REP #$20
;
;	; red to white for damage number
;	LDX.b #131
;	STX.w CGADD
;	LDA.w #hexto555($F8F8F8)
;	SEP #$20
;	STA.w CGDATA
;	XBA
;	STA.w CGDATA
;	REP #$20
;
;	; outline for soul
;	LDX.b #133
;	STX.w CGADD
;	LDA.w #hexto555($F8F8F8)
;	SEP #$20
;	STA.w CGDATA
;	XBA
;	STA.w CGDATA
;	REP #$20

.colorful
	; do BG1 tilemap manually
	LDA.w #VRAMaddr(!BG_1_MAP+$40)
	STA.w VMADDR
	LDY.b #$02 ; using Y for a loop

	; draw 6 boxes here in a loop
.draw6boxes
	LDX.b #$05 ; draw 5 first

	; top of box, 1 blank, 1 corner, 4 lines
	STZ.w VMDATA ; 1 blank
.first5boxes
	LDA.w #$1C7A ; 1 corner
	STA.w VMDATA

	LDA.w #$1C7B ; top of line
	STA.w VMDATA
	STA.w VMDATA
	STA.w VMDATA
	STA.w VMDATA
	DEX
	BNE .first5boxes

	LDA.w #$1C7A ; 1 corner
	STA.w VMDATA

	LDA.w #$1C7B ; top of line
	STA.w VMDATA
	STA.w VMDATA
	STA.w VMDATA

	LDA.w #$5C7A ; flipped corner
	STA.w VMDATA

	STZ.w VMDATA ; blank tile

	LDX.b #$04 ; we need to loop 4 times
.drawboxsides
	PHX
	LDX.b #$05
	LDA.w #$1C79 ; vertical line
	STZ.w VMDATA ; blank tile

.do5boxsides
	STA.w VMDATA
	STZ.w VMDATA
	STZ.w VMDATA
	STZ.w VMDATA
	STZ.w VMDATA
	DEX
	BNE .do5boxsides
	STA.w VMDATA
	STZ.w VMDATA
	STZ.w VMDATA
	STZ.w VMDATA
	LDA.w #$5C79
	STA.w VMDATA
	STZ.w VMDATA
	PLX
	DEX
	BNE .drawboxsides

	DEY
	BNE .draw6boxes

	STZ.w VMDATA ; blank tile
	LDA.w #$1C7B ; top of line
	LDY.b #30

--	STA.w VMDATA
	DEY
	BNE --
	STZ.w VMDATA

	; do BG2 tilemap manually
	LDA.w #VRAMaddr(!BG_2_MAP)
	STA.w VMADDR

	LDY.b #$00 ; row
	LDX.b #$00 ; position

.nextrow
	TYA
	ASL
	ASL
	ASL
	ASL
	ASL
	TAX ; X*16 for from bottom to top

	LDA.w #16
	STA.b DP.Scratch

.nextchar
	LDA.w AttackTileMap, X
	STA.w VMDATA

	INX
	INX
	DEC.b DP.Scratch
	BNE .nextchar

	LDA.w #16
	STA.b DP.Scratch

	; now do the hflip
.nextcharflip
	DEX
	DEX
	LDA.w AttackTileMap, X
	EOR.w #$4000
	STA.w VMDATA
	DEC.b DP.Scratch
	BNE .nextcharflip

	INY
	CPY #$08
	BCC .nextrow

	; add "HP" and name to status bar
	LDA.w #VRAMaddr(!BG_2_MAP+$6C4)
	STA.w VMADDR

	LDA.w #$1113 ; S
	STA.w VMDATA
	LDA.w #$1108 ; H
	STA.w VMDATA
	LDA.w #$1101 ; A
	STA.w VMDATA
	LDA.w #$1111 ; Q
	STA.w VMDATA

	STZ.w VMDATA

	LDA.w #$110C ; L
	STA.w VMDATA
	LDA.w #$1116 ; V
	STA.w VMDATA
	LDA.w #$1129 ; 9
	STA.w VMDATA

	STZ.w VMDATA

	LDA.w #$111E
	STA.w VMDATA
	INC
	STA.w VMDATA

Set_UpHDMA:
	SEP #$30
	; cache HDMAs
	LDX.b #$1F

--	LDA.w $4360, X
	STA.w WRAM.HDMACache, X
	DEX
	BPL --


	REP #$20

	; set up HDMA for screen enabling
	LDX.b #$41 ; indirect table, 2 registers write once
	STX.w HDMA7MODE

	LDX.b #MAINDES
	STX.w DMA7PORT

	LDA.w #MAINDES_HDMA>>0
	LDX.b #MAINDES_HDMA>>16

	STA.w HDMA7ADDRL
	STX.w HDMA7ADDRB

	LDX.b #$7E
	STX.w HDMA7INDIRECTB

	; default display groups
	STZ.b DP.MAINDES_A
	STZ.b DP.MAINDES_B
	STZ.b DP.MAINDES_C
	STZ.b DP.MAINDES_D
	STZ.b DP.MAINDES_E

	; set up HDMA for bg scroll for the hp bar to look nice
	LDX.b #$42 ; indirect table, 1 register write twice
	STX.w HDMA6MODE

	LDX.b #BG2VOFS
	STX.w DMA6PORT

	LDA.w #BG2ScrollHDMA>>0
	LDX.b #BG2ScrollHDMA>>16

	STA.w HDMA6ADDRL
	STX.w HDMA6ADDRB
	STX.w HDMA6INDIRECTB

	LDX.b #$80

	RTL

MAINDES_HDMA:
	db 95
	dw DP.BGENABLE_A ; mostly the sprite

	db 8
	dw DP.BGENABLE_B ; segment after the sprite, just incase desired

	db 64
	dw DP.BGENABLE_C ; battlebox

	db 16
	dw DP.BGENABLE_D ; segment after the box

	db 1
	dw DP.BGENABLE_E ; menu

	db 0

BG2ScrollHDMA:
	db 103
	dw .first ; doesn't matter

	db 65 ; the box
	dw DP.BG2VOFS

	db 16 ; hp bar
	dw .scroll

.first
	dw 0

.scroll
	dw $002B

;==============================================================================
; Attack tilemap
;==============================================================================
AttackTileMap:
	!BO = $0150 ; offset into VRAM
	; row 1
	dw $0000+!BO, $0000+!BO ; 2 empty tiles
	dw $0001+!BO, $0001+!BO, $0001+!BO, $0001+!BO, $0001+!BO
	dw $0001+!BO, $0001+!BO, $0001+!BO, $0001+!BO ; 9 black squares
	dw $0002+!BO, $0003+!BO, $0003+!BO, $0004+!BO, $0005+!BO ; top of bar

	; row 2
	dw $0000+!BO, $0000+!BO ; 2 empty tiles
	dw $0001+!BO, $0001+!BO, $0001+!BO, $0001+!BO ; 4 black squares
	dw $0006+!BO, $0007+!BO, $0008+!BO, $0009+!BO, $040A+!BO ; the actual stuff
	dw $040B+!BO, $000C+!BO, $000D+!BO, $000E+!BO, $000F+!BO

	; row 3
	dw $0000+!BO, $0000+!BO ; 2 empty tiles
	dw $0001+!BO ; 1 black square
	dw $0010+!BO, $0011+!BO, $0812+!BO, $0813+!BO, $0814+!BO, $0815+!BO ; the stuff
	dw $0816+!BO, $0417+!BO, $0418+!BO, $0419+!BO, $041A+!BO, $001B+!BO, $001C+!BO


	; row 4
	dw $0000+!BO, $0000+!BO ; 2 empty tiles
	dw $001D+!BO, $001E+!BO, $001F+!BO, $0820+!BO ; first part
	dw $0001+!BO, $0821+!BO, $0001+!BO, $0822+!BO
	dw $0417+!BO, $0423+!BO, $0424+!BO, $0425+!BO
	dw $001B+!BO, $0026+!BO

	; row 5 - we start vflipping
	dw $0000+!BO, $0000+!BO ; 2 empty tiles
	dw $801D+!BO, $801E+!BO, $801F+!BO, $8820+!BO
	dw $8001+!BO, $8001+!BO, $8001+!BO, $8001+!BO ; black squares vflipped just cause
	dw $8417+!BO, $8423+!BO, $0427+!BO, $0428+!BO
	dw $801B+!BO, $0029+!BO

	; row 6
	dw $0000+!BO, $0000+!BO ; empty tiles
	dw $8001+!BO, $8010+!BO, $8011+!BO, $8812+!BO
	dw $082A+!BO, $082B+!BO, $082C+!BO, $082D+!BO
	dw $8417+!BO, $0418+!BO, $0419+!BO, $041A+!BO
	dw $001B+!BO, $8029+!BO

	; row 7 - almost the same as flipped row 2
	dw $0000+!BO, $0000+!BO ; 2 empty tiles
	dw $8001+!BO, $8001+!BO, $8001+!BO, $8001+!BO 
	dw $8006+!BO, $8007+!BO, $8008+!BO, $8009+!BO, $840A+!BO 
	dw $840B+!BO, $800C+!BO, $800D+!BO, $800E+!BO, $002E+!BO

	; row 8 - the same as row 1 flipped
	dw $0000+!BO, $0000+!BO ; 2 empty tiles
	dw $8001+!BO, $8001+!BO, $8001+!BO, $8001+!BO
	dw $8001+!BO, $8001+!BO, $8001+!BO, $8001+!BO, $8001+!BO 
	dw $8002+!BO, $8003+!BO, $8003+!BO, $8004+!BO, $8005+!BO

BattlePalettes:
.bg1
.bg3
.bg4
	%col4($000000, $000000, $F8F8F8, $C0C0C0)
	%col4($000000, $000000, $000000, $F8F800)
	%col4($000000, $000000, $F88028, $F88028)
	%col4($000000, $000000, $F80000, $00F800)

	%col4($000000, $000000, $F8F8F8, $F80000)
	%col4($000000, $000000, $F80000, $F8F800)
	%col4($000000, $000000, $989898, $585858)
	%col4($000000, $000000, $508060, $F800F8)

.bg2
	%col4($000000, $000000, $B8E820, $20A848)
	%col4($000000, $000000, $B8E820, $F8F800)
	%col4($000000, $000000, $B8E820, $F82828)
	%col4($000000, $000000, $B8E820, $0040F8)

	%col4($000000, $000000, $F8F8F8, $F80000)
	%col4($000000, $000000, $F80000, $F8F800)
	%col4($000000, $000000, $989898, $585858)
	%col4($000000, $000000, $F80000, $00F800)

.sprites
	; pal 1, heart color (0000000), normal bar
	%col8($000000, $F8F8F8, $000000, $FF0000, 0000000, 0000000, $000000, $F8F8F8)
	%col8($A8A8A8, $585858, $A8A8A8, $585858, $A8A8A8, $585858, $A8A8A8, $585858)

	; pal 2, has reversed bar colors
	%col8($000000, $F8F8F8, $000000, $FF0000, $0000FF, $42F8F8, $F8F8F8, $000000)
	%col8($00F800, $404040, $000000, $FF0000, $00FF00, $42F8F8, $F8F8F8, $000000)

;==============================================================================
; Yes
;==============================================================================
NMIWaiter:
	JSL FakeNMI
	INC.b DP.Frame
	JSR ClearOAM
	JSL ReadJoyPad
	RTS

;==============================================================================
; Waits for VBlank manually
;==============================================================================
WaitForVBlank:
	PHP
	SEP #$20

.wait
	BIT.w RDNMI
	BPL .wait

	; waste some cycles for safety?
	PHD
	PHD
	PLD
	PLD

	PLP
	RTS


FakeNMI:
	PHP
	REP #$30
	PHA
	PHX
	PHY
	PHB

	PHK
	PLB
	SEP #$30

	JSR WaitForVBlank
	LDA #$80
	STA.w INIDISP

	JSR NMIUpdates

	REP #$30
	PLB
	PLY
	PLX
	PLA
	PLP
	RTL

;==============================================================================
; xorshift courtesy of total
;==============================================================================
UTRandomInt:
	REP #$20
	LDA.w WRAM.RNGseedX
	ASL
	ASL
	ASL
	ASL
	ASL
	EOR.w WRAM.RNGseedX
	STA.w WRAM.RNGseedA

	LDA.w WRAM.RNGseedY
	STA.w WRAM.RNGseedX

	LDA.w WRAM.RNGseedA
	LSR
	LSR
	LSR
	EOR.w WRAM.RNGseedA
	STA.w WRAM.RNGseedA

	LDA.w WRAM.RNGseedY
	LSR
	EOR.w WRAM.RNGseedY
	EOR.w WRAM.RNGseedA
	STA.w WRAM.RNGseedY

	SEP #$20
	RTL

;==============================================================================
; 
;==============================================================================
Module_Return:
	SEP #$30
	INC.b DP.Undertale
	RTL


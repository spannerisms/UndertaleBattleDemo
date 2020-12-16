Vector_Reset:
	SEI

	LDA #$80
	STA $2100
	STZ $4200
	STZ $420B
	STZ $420C

	CLC
	XCE
	ASL $420D ; fast ROM

	REP #$28
#ZeroLand:
	; Clean up registers
	LDX #$00

	; BG color
	STX $2121
	STX $2122
	STX $2122

	; Windows
	STX $2123
	STX $2124
	STX $2125

	; Window masking
	STX $212E
	STX $212F

	; Color math
	STX $2131

	; Screen mode
	STX $2133

	; SPC
	STX $2140
	STX $2141
	STX $2142
	STX $2143

	LDX #$80
	STX $2115
	STZ $2116
	STZ $2181 ; reset write address for VRAM and WRAM
	STZ $2182

	LDA.w #ZeroLand+1 ; Zero land to our 3 DMAs
	STA $4302
	STA $4312
	STA $4322
	STX $4304
	STX $4314
	STX $4324

	LDA #$FFFF ; fill the whole thing
	STA $4305
	STA $4315
	STA $4325

	LDA #$1809
	STA $4300 ; write type for VRAM
	LDA #$8008
	STA $4310
	STA $4320 ; write type for WRAM

	LDX #$03
	STX $420B ; can't write bank 7F yet

	LDX #$00
	STX $2180 ; clean that last wram byte
	STZ $2118 ; and last VRAM word

	STZ $2181 ; reset WRAM address
	LDX #$01
	STA $2183 ; WRAM bank to 7F

	LDX #$04
	STX $420B

	LDA #$0000
	TCD ; direct page at $0000
	LDA #$01FF
	TCS ; stack at $01FF
	LDX #$80
	PHX
	PLB ; bank80

	;JSR Initialize_SPC

	SEP #$30
	LDA #$80
	PHA
	PLB ; make sure we start in fast rom

	JSL Module_Undertale
	STP

ReadJoyPad:
	PHP
	SEP #$20
	PEI.b (DP.Controller)

	LDA.b #$01
	STA.w JOYPAD
	STZ.w JOYPAD

	STZ.b DP.Controller+0
	STZ.b DP.Controller+1
	LDY.b #$10

--	LDA.w JOYPAD
	LSR
	ROL.b DP.Controller+0
	ROL.b DP.Controller+1
	DEY
	BNE --

	REP #$20
	LDA.b DP.Controller
	STA.b DP.Controller.prev

	PLA
	TSB.b DP.Controller.prev

	EOR #$FFFF
	AND.b DP.Controller
	STA.b DP.Controller.new

	JSL UTRandomInt

	PLP
	RTL

ReadJoyPadAuto:
	PHP
	SEP #$20

	PEI.b (DP.Controller)

	; wait for auto joypad read
	LDA #$01
--	LDA.l $004212
	BNE --

	REP #$20

	LDA.l $004218
	STA.b DP.Controller
	STA.b DP.Controller.prev

	PLA
	TSB.b DP.Controller.prev

	EOR #$FFFF
	AND.b DP.Controller
	STA.b DP.Controller.new

	JSL UTRandomInt

	PLP
	RTL

;===========================================
; OAM cleaner by MathOnNapkins
;===========================================
macro OAMVClear(pos)
	db $F0, <pos>+$05, $F0, <pos>+$09, $F0, <pos>+$0D, $F0, <pos>+$11
endmacro

OAM_Cleaner:
	%OAMVClear($00)
	%OAMVClear($10)
	%OAMVClear($20)
	%OAMVClear($30)
	%OAMVClear($40)
	%OAMVClear($50)
	%OAMVClear($60)
	%OAMVClear($70)
	%OAMVClear($80)
	%OAMVClear($90)
	%OAMVClear($A0)
	%OAMVClear($B0)
	%OAMVClear($C0)
	%OAMVClear($D0)
	%OAMVClear($E0)
	%OAMVClear($F0)

ClearOAM:
	PHP
	REP #$10
	SEP #$20

	; first half
	LDX #$8001
	STX $4300
	LDX.w #OAM.OAM.hi+$001
	STX $2181
	STZ $2183

	LDX.w #OAM_Cleaner
	STX $4302
	LDA.b #OAM_Cleaner>>16
	STA $4304
	LDX #$0080
	STX $4305
	LDA #$01
	STA $420B

	; second half
	LDX.w #OAM_Cleaner
	STX $4302
	LDX.w #OAM.OAM.hi+$101
	STX $2181
	LDX #$0080
	STX $4305

	STA $420B
	STZ.b DP.OAM.i
	STZ.b DP.OAM.drawn
	PLP
Bank00RTS:
	RTS

Vector_NMI:
	SEI
	REP #$30
	PHA
	PHX
	PHY
	PHD
	PHB

	SEP #$30
	LDA #$80
	PHA
	PLB
	STA.w INIDISP
	BIT $4210

	LDA.b DP.Spinning
	BNE .noupdate
	INC.b DP.Spinning

	JSR NMIUpdates

.noupdate
	SEP #$30
	LDA.b DP.INTERRUPTS
	STA.w NMITIMEN

	REP #$30
	PLB
	PLD
	PLY
	PLX
	PLA

	RTI

NMIUpdates:
	STZ.w HDMAENABLE

	LDA.b DP.OBSEL
	STA.w OBSEL

	LDA.b DP.BGMODE
	STA.w BGMODE

	LDA.b DP.MOSAIC
	STA.w MOSAIC

	LDA.b DP.BG1SC
	STA.w BG1SC
	LDA.b DP.BG2SC
	STA.w BG2SC
	LDA.b DP.BG3SC
	STA.w BG3SC
	LDA.b DP.BG4SC
	STA.w BG4SC

	LDA.b DP.BG12NBA
	STA.w BG12NBA
	LDA.b DP.BG34NBA
	STA.w BG34NBA

	LDA.b DP.BG1HOFS+0
	STA.w BG1HOFS
	LDA.b DP.BG1HOFS+1
	STA.w BG1HOFS
	LDA.b DP.BG1VOFS+0
	STA.w BG1VOFS
	LDA.b DP.BG1VOFS+1
	STA.w BG1VOFS

	LDA.b DP.BG2HOFS+0
	STA.w BG2HOFS
	LDA.b DP.BG2HOFS+1
	STA.w BG2HOFS
	LDA.b DP.BG2VOFS+0
	STA.w BG2VOFS
	LDA.b DP.BG2VOFS+1
	STA.w BG2VOFS

	LDA.b DP.BG3HOFS+0
	STA.w BG3HOFS
	LDA.b DP.BG3HOFS+1
	STA.w BG3HOFS
	LDA.b DP.BG3VOFS+0
	STA.w BG3VOFS
	LDA.b DP.BG3VOFS+1
	STA.w BG3VOFS

	LDA.b DP.BG4HOFS+0
	STA.w BG4HOFS
	LDA.b DP.BG4HOFS+1
	STA.w BG4HOFS
	LDA.b DP.BG4VOFS+0
	STA.w BG4VOFS
	LDA.b DP.BG4VOFS+1
	STA.w BG4VOFS


	LDA.b DP.W12SEL
	STA.w W12SEL
	LDA.b DP.W34SEL
	STA.w W34SEL

	LDA.b DP.WOBJSEL
	STA.w WOBJSEL

	LDA.b DP.WINDOW1L
	STA.w WINDOW1L
	LDA.b DP.WINDOW1R
	STA.w WINDOW1R
	LDA.b DP.WINDOW2L
	STA.w WINDOW2L
	LDA.b DP.WINDOW2R
	STA.w WINDOW2R

	LDA.b DP.WBGLOG
	STA.w WBGLOG
	LDA.b DP.WOBJLOG
	STA.w WOBJLOG

	LDA.b DP.MAINDES
	STA.w MAINDES
	LDA.b DP.SUBDES
	STA.w SUBDES

	LDA.b DP.TMW
	STA.w TMW
	LDA.b DP.TSW
	STA.w TSW

	LDA.b DP.CGWSEL
	STA.w CGWSEL
	LDA.b DP.CGADSUB
	STA.w CGADSUB

	LDA.b DP.COLDATA.R
	ORA.b #$20
	STA.w COLDATA

	LDA.b DP.COLDATA.G
	ORA.b #$40
	STA.w COLDATA

	LDA.b DP.COLDATA.B
	ORA.b #$80
	STA.w COLDATA

	REP #$20

	LDX #$80
	STX.w VMAIN
	LDY #$01

	LDX.b DP.NMI_MenuUpdate
	BEQ .no_menu_update

	LDX.b #$00
	STX.b DP.NMI_MenuUpdate

	LDX.b #$7E
	LDA.w #WRAM.MenuBuffer
	STA.w DMA0ADDRL
	STX.w DMA0ADDRB

	LDA.w #$1801
	STA.w DMA0MODE

	LDA.w #3*32*2
	STA.w DMA0SIZE

	LDA.w #VRAMaddr(!BG_1_MAP+!BG_1_MENU_OFFSET)
	STA.w VMADDR

	STY.w DMAENABLE

.no_menu_update
	LDX.b DP.NMI_BoxUpdate
	BEQ .no_box_update

	LDX.b #$00
	STX.b DP.NMI_BoxUpdate

	LDX.b #$7E
	LDA.w #WRAM.BoxBuffer
	STA.w DMA0ADDRL
	STX.w DMA0ADDRB

	LDA.w #$1801
	STA.w DMA0MODE

	LDA.w #8*32*2
	STA.w DMA0SIZE

	LDA.w #VRAMaddr(!BG_1_MAP+!BG_1_BOX_OFFSET)
	STA.w VMADDR

	STY.w DMAENABLE

.no_box_update
	LDX.b DP.NMI_TextUpdate
	BEQ .no_text_update

	LDX.b #$00
	STX.b DP.NMI_TextUpdate

	LDX.b #$7E
	LDA.w #WRAM.TextBuffer
	STA.w DMA0ADDRL
	STX.w DMA0ADDRB

	LDA.w #$1801
	STA.w DMA0MODE

	LDA.w #8*32*2
	STA.w DMA0SIZE

	LDA.w #VRAMaddr(!BG_2_MAP+!BG_1_BOX_OFFSET)
	STA.w VMADDR

	STY.w DMAENABLE

.no_text_update
	LDX.b DP.NMI_AttackBGUpdate
	BEQ .noatkbg
	LDX.b #$00
	STX.b DP.NMI_AttackBGUpdate

	LDX.b #$7F
	STZ.w DMA0ADDRL
	STX.w DMA0ADDRB
	LDA.w #$1801
	STA.w DMA0MODE

	LDA.w #$1000
	STA.w DMA0SIZE

	LDA.w #VRAMaddr(!BG_3_MAP)
	STA.w VMADDR

	STY.w DMAENABLE

.noatkbg
	LDX.b #$7E
	LDA.w #WRAM.HPBUFFER
	STA.w DMA0ADDRL
	STX.w DMA0ADDRB

	LDA.w #$1801
	STA.w DMA0MODE

	LDA.w #12+2+10
	STA.w DMA0SIZE

	LDA.w #VRAMaddr(!BG_2_MAP+$6DA)
	STA.w VMADDR

	STY.w DMAENABLE

	; OAM
	STZ.w OAMADDR ; priority rotation is off

	LDA #$0400
	STA.w DMA0MODE
	LDA.w #OAM.OAM_buffer
	STA.w DMA0ADDR
	LDX #$00
	STX.w DMA0ADDRB
	LDA #$0220
	STA.w DMA0SIZE
	LDY #$01
	STY.w DMAENABLE

	; soul color
	LDX.b #$84
	STX.w CGADD
	LDX.b DP.Soul.Color+0
	STX.w CGDATA
	LDX.b DP.Soul.Color+1
	STX.w CGDATA

;	LDA.l COLOR_BLIND
;	TAX
;	BNE .cb

	LDX.b DP.Soul.Color+0
	STX.w CGDATA
	LDX.b DP.Soul.Color+1
	STX.w CGDATA

.cb

.noupdate
	SEP #$30
	LDA.b DP.INIDISP
	STA.w INIDISP

	LDA.b DP.HDMA
	STA.w HDMAENABLE

	RTS

AddOAM:
	PHX
	PHY
	PHP

	SEP #$30

	LDA.b DP.OAM.i
	LSR.b DP.OAM.p
	BCC ++
	ADC #$3F

++	STA.b DP.Scratch
	REP #$30
	AND #$00FF
	ASL #2
	TAY ; x4 it since it's a byte indexing 32 bits

	LDA.b DP.OAM.d ; get first 2 bytes
	STA.w OAM.OAM.hi, Y ; add to buffer

	LDA.b DP.OAM.d+2 ; next 2 bytes
	STA.w OAM.OAM.hi+2, Y

	SEP #$30
	LDA.b DP.Scratch

	LSR #2
	TAY ; get byte index into the low table

	LDA.b DP.Scratch ; get index back
	AND #$03 ; only bottom 2 bits matter

	TAX ; number of times to shift the bits left 2 times
	LDA.l .clearmasks, X ; to clear the byte we're about to put in

	AND.w OAM.OAM.lo, Y ; clear bits we need
	STA.w OAM.OAM.lo, Y

	LDA.w DP.OAM.d.s
	AND #$03 ; get lowest bits

--	DEX
	BMI .doneshift ; decrement first so that Y=0 never shifts
	ASL #2 ; shift into position
	BRA --

.doneshift
	ORA.w OAM.OAM.lo, Y ; ORA the bits
	STA.w OAM.OAM.lo, Y ; add them in

	INC.b DP.OAM.i

	PLP
	PLY
	PLX
	RTL

.clearmasks
	db %11111100, %11110011, %11001111, %00111111

Vector_COP:
Vector_BRK:
Vector_Unused:
Vector_Abort:
Vector_IRQ:
	RTI

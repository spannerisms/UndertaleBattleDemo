table "battlecharmap.txt"
!DEFAULT_BOX_SIZE = $70
!BOX_RESIZE_SPEED = 3

Module_Battle:
	LDA.b DP.Submodule
	ASL
	TAX

	JSR (.pointers, X)

	JSR AnimateSoulMaybe
	JSR AnimateSprites
	RTL

.pointers
	dw Battle_PreBattle
	dw Battle_PlayerMenu
	dw Battle_PlayerFight
	dw Battle_PlayerAct
	dw Battle_PlayerItem
	dw Battle_PlayerMercy
	dw Battle_EnemyAttack
	dw Battle_Die
	dw Battle_Victory

Battle_PreBattle:
.VRAMINIT
	STZ.b DP.Soul.Mode

	LDA.b #$00
	JSL ChangeSoulColor

	LDA #$01
	STA.b DP.Enemy
	JSR HandleNewEnemies

	LDA.b #$30
	STA.b DP.W12SEL ; enable windowing for BG 3 and 4 on window 1
	LDA.b #$33
	STA.b DP.W34SEL
	LDA.b #$10 ; set default window boundaries
	STA.b DP.WINDOW1L
	LDA.b #$EF
	STA.b DP.WINDOW1R
	; window for main and sub windows
	LDA.b #$0C
	STA.b DP.TMW
	STA.b DP.TSW
	JSR WaitForNMI

	!SOUL_DISTANCE = 35
.soulflash
	LDA.b #191-(!SOUL_DISTANCE*2)
	STA.b DP.Soul.Y
	LDA.b #20+(!SOUL_DISTANCE*3)
	STA.b DP.Soul.X

	LDX.b #40
	LDA.b #$10
	STA.b DP.MAINDES
..flashing
	PHX
	JSR WaitForNMI_ButAnimateSoul
	PLX
	TXA
	AND #$04
	ASL
	ASL
	ASL
	ASL
	ASL
	STA.b DP.Soul.Mode
	DEX
	BNE ..flashing

	LDX.b #!SOUL_DISTANCE

..moving
	PHX
	JSR WaitForNMI_ButAnimateSoul
	PLX
	DEC.b DP.Soul.X
	DEC.b DP.Soul.X
	DEC.b DP.Soul.X
	INC.b DP.Soul.Y
	INC.b DP.Soul.Y
	DEX
	BNE ..moving

	STZ.b DP.HDMA
	LDA #$10
	STA.b DP.MAINDES
	STA.b DP.SUBDES

.init
	; set up base HP stuff
	LDA.b #$11
	STA.w WRAM.HPBUFFER+15
	STA.w WRAM.HPBUFFER+17
	STA.w WRAM.HPBUFFER+19
	STA.w WRAM.HPBUFFER+21
	STA.w WRAM.HPBUFFER+23

	SEP #$30
	STZ.b DP.Menu.Pos.Action
	LDA.b DP.HP.MAX
	JSR GetDamageNumbers
	LDA.w WRAM.DecDigitsCount
	CMP.b #$02 ; see if it's 2 digits
	LDA.w WRAM.DecDigits+0
	ORA #$20
	STA.w WRAM.HPBUFFER+22

	LDA.w WRAM.DecDigits+1
	BCS ++
	LDA.b #$00
++	ORA #$20
	STA.w WRAM.HPBUFFER+20

	LDA.b #$1D
	STA.w WRAM.HPBUFFER+18

	JSR BattleText_EmptyText

	SEP #$10
	REP #$20

	LDX #$C0
	STX.b DP.HDMA

	STZ.b DP.Scratch+2
	LDY #$00

..nextenemy
	LDX.b DP.Scratch+2
	CPX.b #3
	BCS ..done

	LDA.w DP.Enemy, X
	AND #$00FF
	BEQ ..skipenemy

	INY
	REP #$10
	AND.w #$00FF
	ASL
	ASL
	TAX

	LDA.l Intro_text_pointers+0, X
	PHA
	LDA.l Intro_text_pointers+2, X

	SEP #$10
	TAX ; the bank of messages
	PLA
	PHX
	PHA
	LDX.b #$00 ; just a normal message
	PHX

..skipenemy
	INC.b DP.Scratch+2
	BRA ..nextenemy

..done
	PHY ; save number of messages
	JSL BattleText_AddMessages ; add all messages
	SEP #$20
	LDA #$11
	STA.b DP.MAINDES_A
	STA.b DP.MAINDES_B
	STA.b DP.MAINDES_C
	STA.b DP.MAINDES_E
	STA.b DP.SUBDES_A
	STA.b DP.SUBDES_B
	STA.b DP.SUBDES_C
	STA.b DP.SUBDES_E

	LDA.b #$13
	STA.b DP.MAINDES_D
	STA.b DP.SUBDES_D

	LDA.b #$1F ; ganon song
	STA.w APUIO0

	INC.b DP.Submodule
	RTS

Battle_PlayerMenu:
	LDA.b #!DEFAULT_BOX_SIZE
	JSR Battle_PrepBoxBuilder

	JSR ShowBG1Menu
	JSR Battle_BuildMenu
	JSR Battle_MenuDrawBox

	LDA.b DP.Menu.Pos.Action
	JSR Battle_MenuSwapSelectColor ; set selected color for fight
	STZ.b DP.Soul.Mode
	JSR Battle_MenuSoulCoords
	JSL BattleText_WriteText

Battle_PlayerMenuControl:
.looper
	LDA.b DP.Controller.new.A
	LSR : BCS .pressed_right
	LSR : BCS .pressed_left
	BRA .check_other_buttons

.pressed_right
	LDA.b DP.Menu.Pos.Action
	PHA
	INC
	CMP.b #$04
	BCC .update_selection
	LDA #$00
	BRA .update_selection

.pressed_left
	LDA.b DP.Menu.Pos.Action
	PHA
	DEC
	BPL .update_selection
	LDA #$03

.update_selection
	STA.b DP.Menu.Pos.Action
	JSR Battle_MenuSwapSelectColor ; make this yellow
	PLA ; get old selection
	JSR Battle_MenuSwapSelectColor ; make it orange

.loop
	JSR Battle_MenuSoulCoords
	JSR WaitForNMI_ButAnimateSprites
	BRA .looper

.check_other_buttons
	BIT.b DP.Controller.new.B
	BMI .pressed_A
	BVS .pressed_X

	LDA.b #$30
	BIT.b DP.Controller.new.A
	;BMI .pressed_B
	;BVS .pressed_X
	;BNE .pressed_startselect
.pressed_X
.pressed_Y
.pressed_startselect
	BEQ .loop
	BRA .loop

.pressed_A
	LDA.b DP.Menu.Pos.Action
	CLC
	ADC #$02
	STA.b DP.Submodule
	RTS

.pressed_B
	LDA.b DP.Menu.Pos.Action
	BEQ .loop ; don't need to update if already position 0
	PHA
	LDA #$00
	BRA .update_selection

;==============================================================================
; Menu characters are just gonna be in order in VRAM
; 3 rows of 32 tiles
;==============================================================================
#Battle_BuildMenu:
	REP #$30
	LDA.w #$085F ; first char, pal 2
	LDX.w #3*32*2 ; rows * tiles * size

--	STA.w WRAM.MenuBuffer-2, X
	DEC
	DEX
	DEX
	BNE --

	SEP #$20
	INC.b DP.NMI_MenuUpdate
	RTS

Battle_MenuDrawBox:
	SEP #$30
.drawbox
	JSR Battle_BoxBuilding
	LDA.b DP.BoxT
	AND #$7F
	CMP.b DP.BoxW
	BEQ .done
	JSR WaitForNMI_ButAnimateSprites
	BRA .drawbox

.done
	RTS

Battle_MenuSoulCoords:
	LDA.b #191
	STA.b DP.Soul.Y
	LDA.b DP.Menu.Pos.Action ; get menu position
	ASL ; x2
	ASL ; x4
	STA.b DP.Soul.X ; save p*4
	SEC
	SBC.b DP.Menu.Pos.Action ; -p to get p*3
	CLC
	ADC.b DP.Soul.X
	ASL
	ASL
	ASL
	CLC
	ADC.b #20
	STA.b DP.Soul.X
	RTS

;==============================================================================
; Expects A to have target
;==============================================================================
Battle_PrepBoxBuilder:
	SEP #$20
	STA.b DP.BoxT ; set target
	CMP.b DP.BoxW ; compare to current

	LDA #$00
	ROR ; if T is bigger, we want bit 7 unset
	EOR #$80
	TSB.b DP.BoxT
	RTS

;==============================================================================
; Input A is the index to change
;==============================================================================
Battle_MenuSwapSelectColor:
	PHP
	SEP #$30
	INC.b DP.NMI_MenuUpdate
	AND #$03
	STA.b DP.Scratch ; save A
	ASL ; *8
	ASL
	ASL
	SEC
	SBC.b DP.Scratch ; -1 for *7

	CLC
	ADC #$02 ; carry should always be gone
	ASL

	TAX
	REP #$20
	LDA #$0003
	STA.b DP.Scratch

.nextpos
	LDY #$07
.nextchar
	LDA.w WRAM.MenuBuffer, X
	EOR.w #$0C00 ; swaps between pal 1 and 2
	STA.w WRAM.MenuBuffer, X
	INX
	INX
	DEY
	BNE .nextchar

	TXA
	CLC
	ADC.w #50
	TAX

.samerow
	DEC.b DP.Scratch
	BNE .nextpos

	PLP
	RTS

;==============================================================================
; The battle box is always 8 tiles tall
; The WRAM buffer will hold 8 rows of 32 tiles
; rows 0 and 7 will be drawn completely manually
; rows 1 through 6, which are just vertical bars, will be handled quickly
;
; The box is always even, so only 16 iterations will be done
; The W var defines how far the box should extend from the center in pixels
;   this refers to the corner pixel, not the valid boundaries within
; The T var defines the target for W
; bit 7 of T toggles grow or shrink
;
; A tells NMI to update the box
;==============================================================================
Battle_BoxBuilding:
BuildBox:
	PHP
	SEP #$30
	INC.b DP.NMI_BoxUpdate
	LDA.b DP.BoxT
	AND #$7F

	CMP.b DP.BoxW
	BEQ .correctsize

	BIT.b DP.BoxT
	BMI .shrink

.grow
	BCS .next

	; too big/small, so reset
.toofar
	STA.b DP.BoxW
	BRA .draw

.next
	LDA.b #!BOX_RESIZE_SPEED
	BRA .resize

.shrink
	BCS .toofar
	LDA.b #!BOX_RESIZE_SPEED*-1

.resize
	CLC
	ADC.b DP.BoxW
	STA.b DP.BoxW

	LDA.b DP.BoxT
	AND #$7F

	CMP.b DP.BoxW
	BEQ .correctsize

	BIT.b DP.BoxT
	BMI .shrink2

.grow2
	BCC .toofar
	BRA .correctsize

.shrink2
	BCS .toofar

.correctsize
.draw
	; set BG34 windowing
	LDA.b DP.BoxW
	CLC
	ADC.b #$7F
	STA.b DP.WINDOW1R
	EOR.b #$FF ; no inc, because that happens to work properly
	STA.b DP.WINDOW1L

	; clear the buffer
.clean
	REP #$20
	LDA #$0000 ; black character fill
	LDX.b #32*2 ; tiles*rows*size

--	STA.w WRAM.BoxBuffer-2+(64*0), X
	STA.w WRAM.BoxBuffer-2+(64*1), X
	STA.w WRAM.BoxBuffer-2+(64*2), X
	STA.w WRAM.BoxBuffer-2+(64*3), X
	STA.w WRAM.BoxBuffer-2+(64*4), X
	STA.w WRAM.BoxBuffer-2+(64*5), X
	STA.w WRAM.BoxBuffer-2+(64*6), X
	STA.w WRAM.BoxBuffer-2+(64*7), X
	DEX
	DEX
	BNE --

	; now find out how far we should extend outwards
	LDA.b DP.BoxW
	AND.w #$0078 ; number of full tiles to add
	LSR ; divided by 8 for tile size
	LSR ; but *2 because 16 bit

	TAX
	TXY

--	LDA #$2070 ; high priority vertical bar
	STA.w WRAM.BoxBuffer-2+(64*0)+(16*2), X
	LDA #$A070 ; vertical flipped bar
	STA.w WRAM.BoxBuffer-2+(64*7)+(16*2), X
	DEX
	DEX
	BNE --

	; now do it backwards
	TYA
	EOR.w #$FFFF
	INC A
	TAX

--	LDA #$2070 ; high priority vertical bar
	STA.w WRAM.BoxBuffer+(64*-4)+(16*2), X
	LDA #$A070 ; vertical flipped bar
	STA.w WRAM.BoxBuffer+(64*3)+(16*2), X
	INX
	INX
	BNE --

	LDA.b DP.BoxW
	AND.w #$0007 ; get number of partial pixels
	BEQ .zeros
	CMP.w #$0001 ; 1 is dumb and needs extra stuff
	BNE .continue

	LDA.w #$2069 ; 1 pixel on left, on current full bar tile
	JSR AddCornerAndVertBars
	LDA.w #$0001

.continue
	INY
	INY
.zeros
	SEC ; this is going to be 1 indexed in character data
	ADC.w #$2060
	JSR AddCornerAndVertBars
	PLP
	RTS

AddCornerAndVertBars:
	PHA

	TYA
	EOR.w #$FFFF
	INC A
	TAX

	; do corners first
	LDA 1, S
	STA.w WRAM.BoxBuffer+(64*-4)+(16*2), X ; top left
	EOR.w #$8000 ; vertical flip
	STA.w WRAM.BoxBuffer+(64*3)+(16*2), X ; bottom left

	EOR.w #$4000 ; horizontal flip
	STA.w WRAM.BoxBuffer-2+(64*7)+(16*2), Y ; bottom right
	EOR.w #$8000 ; vertical flip
	STA.w WRAM.BoxBuffer-2+(64*0)+(16*2), Y ; top right


	CLC
	ADC.w #$0010 ; get to row below, we start hflipped though
	STA.w WRAM.BoxBuffer-2+(64*1)+(16*2), Y
	STA.w WRAM.BoxBuffer-2+(64*2)+(16*2), Y
	STA.w WRAM.BoxBuffer-2+(64*3)+(16*2), Y
	STA.w WRAM.BoxBuffer-2+(64*4)+(16*2), Y
	STA.w WRAM.BoxBuffer-2+(64*5)+(16*2), Y
	STA.w WRAM.BoxBuffer-2+(64*6)+(16*2), Y

	EOR.w #$4000 ; hflip back
	STA.w WRAM.BoxBuffer+(64*-3)+(16*2), X
	STA.w WRAM.BoxBuffer+(64*-2)+(16*2), X
	STA.w WRAM.BoxBuffer+(64*-1)+(16*2), X
	STA.w WRAM.BoxBuffer+(64*0)+(16*2), X
	STA.w WRAM.BoxBuffer+(64*1)+(16*2), X
	STA.w WRAM.BoxBuffer+(64*2)+(16*2), X

	PLA
	RTS

;==============================================================================
; Waits for NMI
; also animates sprites
; returns with carry clear if joypad A or Start
;==============================================================================
WaitForNMI_ButAnimateSprites:
	PHX
	PHY
	PHP
	JSR AnimateSoulMaybe
	JSR AnimateSprites
	BRA ++

WaitForNMI:
	PHX
	PHY
	PHP
--
++	JSR NMIWaiter
	PLP
	PLY
	PLX
	RTS

WaitForNMI_ButAnimateSoul:
	PHX
	PHY
	PHP
	JSR AnimateSoulMaybe
	BRA --

;==============================================================================
; OAM routines
;==============================================================================
AnimateSoulMaybe:
	SEP #$30
	LDA.b DP.OAM.drawn
	BNE .skip
	INC.b DP.OAM.drawn
	JSR Sprite_DrawSoul
.skip
	JSR DrawPlayerHP
	RTS

AnimateSprites:
	SEP #$30
	LDY.b #$FF

.nextenemy
	INY
	CPY.b #3
	BCS .doneenemies

	TYX
	LDA.b DP.Enemy, X
	BEQ .nextenemy

	PHY
	PHB
	PHP

	REP #$30
	AND #$00FF
	ASL
	ASL
	TAX

	LDA.l Draw_routine_pointers+0, X
	STA.b DP.GameJML2+0
	LDA.l Draw_routine_pointers+2, X
	SEP #$30
	STA.b DP.GameJML2+2

	PHK
	PEA .ret-1

	PHA
	PLB

	JML.w [DP.GameJML2]

.ret
	PLP
	PLB
	PLY
	BRA .nextenemy

.doneenemies
	RTS

ChangeSoulColor:
	PHX
	PHP
	SEP #$30
	ASL
	TAX

	REP #$20
	LDA.l .base, X
	STA.b DP.Soul.Color.normal

	LDA.l .hurt, X
	STA.b DP.Soul.Color.hurt

	PLP
	PLX
	RTL

.base
	dw hexto555($F80000) ; red
	dw hexto555($0038F8) ; blue
	dw hexto555($00C000) ; green
	dw hexto555($D838D8) ; purple
	dw hexto555($F8F800) ; yellow
	dw hexto555($F8A800) ; orange
	dw hexto555($40F8F8) ; cyan

.hurt
	dw hexto555($800000) ; red
	dw hexto555($002080) ; blue
	dw hexto555($008000) ; green
	dw hexto555($902090) ; green
	dw hexto555($F0D000) ; yellow
	dw hexto555($E87000) ; orange
	dw hexto555($00A8C8) ; cyan

Sprite_DrawSoul:
	SEP #$20
	LDA.b DP.iFrames
	BEQ .normal
	DEC.b DP.iFrames
	LSR ; flash every 2 frames
	LSR
	LSR

	REP #$20
	BCS .dark

.normal
	REP #$20
	LDA.b DP.Soul.Color.normal
	BRA .setsoulcolor
.dark
	LDA.b DP.Soul.Color.hurt
.setsoulcolor
	STA.b DP.Soul.Color
	SEP #$30
	LDA.b DP.Soul.X
	STA.b DP.OAM.d.x
	LDA.b DP.Soul.Y
	STA.b DP.OAM.d.y

	LDA.b DP.Soul.Mode
	BMI .hide
	ASL
	TAX
	JMP (.modedraws, X)

.dying

.direction
	LDX.b DP.Soul.Box.Direction
	LDA.l .directiontiles, X
	STA.b DP.OAM.d.t
	LDA.l .directionprops, X
	BRA .continue

.nodirection
	LDA.b #$00
	STA.b DP.OAM.d.t
	LDA.b #$30

.continue
	STA.b DP.OAM.d.p
	STZ.b DP.OAM.d.s
	JSL AddOAM

.hide
	RTS

.directiontiles
	db $00, $00, $01, $01

.directionprops
	db $30, $B0, $70, $30

.modedraws
	dw .nodirection
	dw .bar
	dw .direction
	dw .dying

.bar
	STZ.b DP.OAM.d.s
	LDA.b #103
	STA.b DP.OAM.d.y
	LDA.b #$08
	STA.b DP.OAM.d.t
	LDA.b #$20
	ORA.b DP.Soul.Barflash
	STA.b DP.OAM.d.p
	JSL AddOAM

	LDA.b #159
	STA.b DP.OAM.d.y
	LDA.b #$A0
	ORA.b DP.Soul.Barflash
	STA.b DP.OAM.d.p
	JSL AddOAM

	INC.b DP.OAM.d.t

	LDA.b #111
	STA.b DP.OAM.d.y
	JSL AddOAM

	LDA.b #119
	STA.b DP.OAM.d.y
	JSL AddOAM

	LDA.b #127
	STA.b DP.OAM.d.y
	JSL AddOAM

	LDA.b #135
	STA.b DP.OAM.d.y
	JSL AddOAM

	LDA.b #143
	STA.b DP.OAM.d.y
	JSL AddOAM

	LDA.b #151
	STA.b DP.OAM.d.y
	JSL AddOAM

	RTS

DrawPlayerHP:
	PHX
	PHP
	SEP #$30
	LDA.b DP.HP ; get HP
	STA.w CPUMULTA
	LDA.b #48 ; multiply
	STA.w CPUMULTB
	LDY.b DP.HP.MAX ; 3 cycles
	REP #$20 ; 3 cycles
	NOP
	LDA.w CPUPRODUCT

	STA.w CPUDIVIDEND ; divide this number by
	STY.w CPUDIVISOR ; the max HP
	LDX #$00 ; 2 cycles
	SEP #$20 ; 3 cycles
	LDA #$01 ; 2 cycles
	TYA ; 2 cycles
	LSR ; 2 cycles
	NOP ; 2 cycles
	NOP ; 2 cycles
	LDY.w CPUQUOTIENT
	CMP.w CPUREMAINDER
	BCS .noround
	INY
.noround
	CPY.b #48
	BCC .nottoofar
	LDY.b #48
.nottoofar
	REP #$20
	TYA
	LSR ; get bar/8
	LSR
	LSR
	STA.b DP.Scratch+0

	TYA
	AND.w #$0007 ; get bar%8
	CLC
	BNE ++
	SEC
++	STA.b DP.Scratch+2

	LDA.w #6
	SBC.b DP.Scratch+0
	STA.b DP.Scratch+4

	LDA.w #$34F8
	LDY.b DP.Scratch+0
	BEQ ++
--	STA.w WRAM.HPBUFFER, X
	INX
	INX
	DEY
	BNE --

++	LDA.b DP.Scratch+2
	BEQ ++
	ORA.w #$34F0
	STA.w WRAM.HPBUFFER, X
	INX
	INX

++	LDA.w #$34F0
	LDY.b DP.Scratch+4
	BEQ ++
--	STA.w WRAM.HPBUFFER, X
	INX
	INX
	DEY
	BNE --

	; now draw the actual HP
++	SEP #$30
	LDA.b DP.HP
	JSR GetDamageNumbers

	LDA.w WRAM.DecDigitsCount
	CMP.b #$02 ; see if it's 2 digits
	LDA.w WRAM.DecDigits+0
	ORA #$20
	STA.w WRAM.HPBUFFER+16

	LDA.w WRAM.DecDigits+1
	BCS ++
	LDA.b #$00
++	ORA #$20
	STA.w WRAM.HPBUFFER+14


++	PLP
	PLX
	RTS

;==============================================================================
; 
;==============================================================================
HandleNewEnemies:
	PHP
	SEP #$30
	LDX #$00
.next
	LDA.b DP.Enemy, X
	BEQ .skip

	PHX
	TAX

	LDA.l EnemyHP, X
	PLX
	STA.b DP.Enemy.HP, X
	STA.b DP.Enemy.HP.MAX, X
	STZ.b DP.Enemy.ActLevel, X

.skip
	INX
	CPX #$03
	BCC .next

	PLP
	RTS

EnemyHP:
	fillbyte 0 : fill !ENEMY_MAX
macro enemy_hp(h)
pushpc
	org EnemyHP+!ENEMY_ID
		db <h>
pullpc
endmacro

;==============================================================================
; Fight stuff
; TODO
;==============================================================================
Battle_PlayerFight:
.initfight
	LDA #$80
	STA.b DP.Soul.Mode
	JSR DrawEnemyHP_all
	JSR GetEnemyList

.selectanenemy
	JSR GetEnemySelection
	BMI .selectedenemy

	JSR BattleText_DeleteShortText
	JSR BattleText_DeleteKText
	JSR BattleText_UnhideUndeletedMessages
	LDA.b #$01
	STA.b DP.Submodule
	RTS

.selectedenemy
	SEP #$30
	LDX.b DP.Menu.Pos.Text
	STX.b DP.SelectedEnemy
	JSR BuildBox
	SEP #$30
	LDA.b DP.Menu.Pos.Action
	JSR Battle_MenuSwapSelectColor
	LDX.b DP.SelectedEnemy

	JSR DisplayAttack
	LDA #$01
	STA.b DP.Soul.Mode
	LDA.b #232
	STA.b DP.Soul.X

--	JSR WaitForNMI_ButAnimateSprites
	JSL UTRandomInt
	BIT.b DP.Controller.new.B
	BMI .hit

	LDA.b DP.Soul.X
	CLC
	SBC.b #3
	STA.b DP.Soul.X
	CMP.b #20 ; TODO ?
	BCS --
 
.hit
	; TODO this is just hardcoded for ganon's stats
	; s = 1.0, 1.5, 1.8
	; near center:
	; (17 + 2) * s + rand(0,3)

	; not near center:
	; (17-10)*s*(1-abs(x/128)) from -128 to 128

	; except sword 1 = no damage
	LDA.l $7EF359

	LDA.b #$03 ; hardcoded tempered
	TAX
	BMI ++

	CMP.b #2 ; is master sword?
	BCS .calculatedamage
++	LDA.b #0
	BRA .applydamage

.calculatedamage
	LDA.b DP.Soul.X
	CLC
	ADC.b #4 ; make it so $80 is the middle
	; absolute value
	BPL ++

	EOR #$FF
	INC

++	TAY

	; get sword multiplier
	LDA.l .multiplier-2, X
	STA.w CPUMULTA
	STY.w CPUMULTB
	REP #$20 ; 3 cycles
	LDY.b #128 ; 2 cycles
	NOP ; 2 cycles
	LDA.w CPUPRODUCT
	STA.w CPUDIVIDEND
	STY.w CPUDIVISOR
	JSL UTRandomInt
	AND #$03
	CLC
	ADC.w CPUQUOTIENT

	LDX.b DP.Scratch+2
	CPX.b #3
	BCS .notreallygood
	ADC.b #5
	BRA .applydamage

.notreallygood
	CPX.b #16
	BCS .garbage
	ADC.b #3
	BRA .applydamage

.garbage
	ADC.b #2

.applydamage
	STA.b DP.DamageD
	STA.w WRAM.DamageDigitsDebug
	STZ.b DP.DamageZ
	STZ.b DP.DamageT
	JSR GetDamageNumbers

	LDX.b #11
.copydec
	LDA.w WRAM.DecDigitsCount-1, X
	STA.w WRAM.DamageDigitsCount-1, X
	DEX
	BNE .copydec

	LDX.b #40 ; 40 frames for sword animation? TODO
	LDA.b #$02
	STA.b DP.DamageC

.animateattack
	PHX
	JSR AddAttackAnimation
	JSR WaitForNMI_ButAnimateSprites
	PLX
	LDA.b DP.Frame
	AND.b #$04
	LSR
	STA.b DP.Soul.Barflash
	DEX
	BNE .animateattack

.animatedamage
	JSR AddDamageSprites
	JSR AnimateEnemyHPBar
	JSR WaitForNMI_ButAnimateSprites
	BCS .donewithbar
	LDA.b DP.Frame
	AND.b #$04
	LSR
	STA.b DP.Soul.Barflash
	BCC .animatedamage

.donewithbar
	LDX #40
.alittlemoreanimation
	PHX
	JSR AddDamageSprites
	JSR AnimateEnemyHPBar
	JSR WaitForNMI_ButAnimateSprites
	PLX
	LDA.b DP.Frame
	AND.b #$04
	LSR
	STA.b DP.Soul.Barflash
	DEX
	BNE .alittlemoreanimation

	LDX.b DP.SelectedEnemy
	LDA.b DP.Enemy.HP, X
	BEQ .enemydied

.gotofight
	SEP #$30
	LDA.b #$80
	STA.b DP.Soul.Mode
	LDA.b #$06
	STA.b DP.Submodule
	JSR HideBG2Box
	RTS

.enemydied
	; TODO animate death ?
	STZ.b DP.Enemy, X

	LDX.b #3 ; look for alive enemies

.nextlife
	LDA.b DP.Enemy.HP-1, X
	BNE .found
	DEX
	BNE .nextlife

.alldead
	STZ.b DP.Befriended
	LDA.b #$08
	STA.b DP.Submodule
	RTS
	
.found
	JMP .gotofight


.multiplier
	db 17*1.0, 17*1.5, 17*1.8

; TODO only for small numbers atm
GetDamageNumbers:
	PHP
	SEP #$30
	STA.w CPUDIVIDEND+0
	STZ.w CPUDIVIDEND+1
	LDY.b #10
	STY.w CPUDIVISOR

	STZ.w WRAM.DecDigitsCount ; 4 cycles
	INC.w WRAM.DecDigitsCount ; 6 cycles
	LDX.w WRAM.DecDigitsCount ; 4 cycles
	NOP ; 2 cycles

	LDA.w CPUREMAINDER
	STA.w WRAM.DecDigits-1, X

.nextdigit
	LDA.w CPUQUOTIENT
	BEQ .done

	STA.w CPUDIVIDEND+0
	STY.w CPUDIVISOR

	INC.w WRAM.DecDigitsCount ; 6 cycles
	LDX.w WRAM.DecDigitsCount ; 4 cycles
	REP #$00 ; 3 cycles
	NOP ; 2 cycles

	LDA.w CPUREMAINDER
	STA.w WRAM.DecDigits-1, X
	BRA .nextdigit

.done
	PLP
	RTS

AddAttackAnimation:
	PHP
	SEP #$31
	STX.b DP.Scratch+2
	STZ.b DP.Scratch+3

	LDX.b DP.SelectedEnemy
	LDA.w EnemySpritePositions, X
	SBC.b #40
	STA.b DP.Scratch+4

	LDA.b #56
	STA.b DP.OAM.d.y

	; get number of frames into animation
	SEC
	LDA.b #40
	SBC.b DP.Scratch+2
	LSR
	ROL.b DP.Scratch+3
	ASL ; move 8 pixels every other frame
	ASL
	LSR.b DP.Scratch+3 ; but move back every other frame
	BCC .nooffset
	;SBC #2
	CLC
	DEC.b DP.OAM.d.y

.nooffset
	ADC.b DP.Scratch+4
	STA.b DP.Scratch+6

	STA.b DP.OAM.d.x

	LDA.b #$02
	STA.b DP.OAM.d.s
	LDA.b #$30
	STA.b DP.OAM.d.p

	LDA.b #$40
	STA.b DP.OAM.d.t
	JSL AddOAM

	INC.b DP.OAM.d.t
	INC.b DP.OAM.d.t
	LDA.b DP.OAM.d.x
	CLC
	ADC.b #$10
	STA.b DP.OAM.d.x
	JSL AddOAM

	INC.b DP.OAM.d.t
	INC.b DP.OAM.d.t
	LDA.b DP.OAM.d.y
	CLC
	ADC.b #$10
	STA.b DP.OAM.d.y
	LDA.b DP.Scratch+6
	STA.b DP.OAM.d.x
	JSL AddOAM

	INC.b DP.OAM.d.t
	INC.b DP.OAM.d.t
	LDA.b DP.OAM.d.x
	CLC
	ADC.b #$10
	STA.b DP.OAM.d.x
	JSL AddOAM

	PLP
	RTS

AddDamageSprites:
	PHP
	SEP #$30
	LDA.b DP.DamageT
	CMP.b #10
	BCS .dontrisenow

.risenow
	INC.b DP.DamageZ
	BRA .heightsettimer

.dontrisenow
	CMP.b #22
	BCS .dontdescendnow
	DEC.b DP.DamageZ
	BRA .heightsettimer

.dontdescendnow
	CMP.b #24
	BCC .risenow
	BRA .doneheight

.heightsettimer
	INC.b DP.DamageT
.doneheight
	SEC
	LDA.b #14
	SBC.b DP.DamageZ
	STA.b DP.OAM.d.y

	LDY #$00
	LDA.b #$02
	STA.b DP.OAM.d.s

	LDA.w WRAM.DamageDigitsCount
	LDX.b DP.SelectedEnemy
	LDA.l EnemySpritePositions, X
	SBC.b #16
	STA.b DP.Scratch+2

	LDA.w WRAM.DamageDigitsCount
	ASL ; x8 for offset from center in pixels
	ASL
	ASL
	ADC.b DP.Scratch+2
	BRA .nextnoxoff

.nextdigit
	LDA.b DP.OAM.d.x
	SBC.b #14 ; since carry is clear

.nextnoxoff
	STA.b DP.OAM.d.x
	LDX.w WRAM.DamageDigits, Y

	LDA.w .props, X
	STA.b DP.OAM.d.p

	LDA.w .chr, X
	STA.b DP.OAM.d.t

	JSL AddOAM
	INY
	CPY.w WRAM.DamageDigitsCount
	BCC .nextdigit
	PLP
	RTS

.chr
	db $20 ; 0
	db $22 ; 1
	db $24 ; 2
	db $26 ; 3
	db $28 ; 4
	db $24 ; 5
	db $2A ; 6
	db $2C ; 7
	db $2E ; 8
	db $2A ; 9

.props
	db $30 ; 0
	db $30 ; 1
	db $30 ; 2
	db $30 ; 3
	db $30 ; 4
	db $70 ; 5
	db $30 ; 6
	db $30 ; 7
	db $30 ; 8
	db $F0 ; 9

AnimateEnemyHPBar:
	PHP
	SEP #$30
	LDX.b DP.SelectedEnemy

	LDA.b #$32
	STA.b DP.OAM.d.p
	STZ.b DP.OAM.d.s

	LDA.b DP.Enemy.HP, X ; get HP
	STA.w CPUMULTA
	LDA.b #80
	STA.w CPUMULTB
	LDY.b DP.Enemy.HP.MAX, X ; 4 cycles
	REP #$20 ; 3 cycles
	LDA.w CPUPRODUCT

	STA.w CPUDIVIDEND ; divide this number by
	STY.w CPUDIVISOR ; the max HP
	LDA.w EnemySpritePositions, X ; 5 cycles
	SEP #$31 ; 3 cycles
	SBC.b #48
	STA.b DP.OAM.d.x ; 3 cycles
	LDA.b #30 ; 2 cycles
	STA.b DP.OAM.d.y ; enough cycles for the math
	TYA
	LSR
	LDY.w CPUQUOTIENT
	CMP.w CPUREMAINDER
	BCS .noround
	INY
.noround
	CPY.b #80
	BCC .nottoofar
	LDY.b #80
.nottoofar
	TYA
	LSR ; get bar/8
	LSR
	LSR
	STA.b DP.Scratch+0

	TYA
	AND.b #$07 ; get bar%8
	CLC
	BNE ++
	SEC
++	STA.b DP.Scratch+2

	LDA.b #10
	SBC.b DP.Scratch+0
	STA.b DP.Scratch+4

	; do green bar
	LDY.b DP.Scratch+0
	BEQ ++
	LDA.b #$18
	STA.b DP.OAM.d.t

--	CLC
	LDA.b DP.OAM.d.x
	ADC.b #8
	STA.b DP.OAM.d.x
	JSL AddOAM
	DEY
	BNE --

++	LDA.b DP.Scratch+2
	BEQ ++
	ORA.b #$10
	STA.b DP.OAM.d.t

	CLC
	LDA.b DP.OAM.d.x
	ADC.b #8
	STA.b DP.OAM.d.x
	JSL AddOAM

++	LDY.b DP.Scratch+4
	BEQ ++
	LDA.b #$10
	STA.b DP.OAM.d.t

--	CLC
	LDA.b DP.OAM.d.x
	ADC.b #8
	STA.b DP.OAM.d.x
	JSL AddOAM
	DEY
	BNE --

	; now do health reduction
++	DEC.b DP.DamageC
	BNE .exit

	LDA.b #$02
	STA.b DP.DamageC
	LDA.b DP.DamageD
	BEQ .done
	DEC.b DP.Enemy.HP, X
	BEQ .done
	DEC.b DP.DamageD

.exit
	PLP
	CLC
	RTS

.done
	STZ.b DP.DamageD
	PLP
	SEC
	RTS

EnemySpritePositions:
	db $80, $80, $80

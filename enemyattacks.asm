EmptyBG34:
	PHP
	REP #$20

	STZ.b DP.BG3HOFS
	STZ.b DP.BG3VOFS
	STZ.b DP.BG4HOFS
	STZ.b DP.BG4VOFS

	STZ.w WMADDR

	LDA.w #$8008
	STA.w DMA0MODE

	LDA.w #$1000
	STA.w DMA0SIZE

	LDA.w #.zero
	STA.w DMA0ADDR

	SEP #$20
	LDA.b #.zero>>16
	STA.w DMA0ADDRB

	LDA.b #$01
	STA.w WMADDH
	STA.w DMAENABLE
	STA.b DP.NMI_AttackBGUpdate

	PLP
	RTL

.zero
	db 0

EnableBG3Attack:
	PHP
	SEP #$20
	LDA.b #$04

--	TSB.b DP.MAINDES_C
	TSB.b DP.SUBDES_C
	PLP
	RTL

EnableBG34Attack:
	PHP
	SEP #$20
	LDA.b #$0C
	BRA --

EnableBG4Attack:
	PHP
	SEP #$20
	LDA.b #$08
	BRA --

DisableBGAttack:
	PHP
	SEP #$20
	LDA.b #$0C

--	TRB.b DP.MAINDES_C
	TRB.b DP.SUBDES_C
	PLP
	RTL


Attack_RequestBoxSize:
	PHX
	PHP
	SEP #$30
	CMP.b #$00
	BEQ .done
	LDX.b DP.BoxT
	BEQ .do

	CMP.b DP.BoxT
	BCC .done

.do
	STA.b DP.BoxT
	BRA .done


.done
	PLP
	PLX
	RTL

Battle_EnemyAttack:
	JSR .main
	JSL DisableBGAttack
	RTS

.main
	SEP #$30
	JSR HideBG2Box
	STZ.w WRAM.Attacks.Pointers+(0*4)
	STZ.w WRAM.Attacks.Pointers+(1*4)
	STZ.w WRAM.Attacks.Pointers+(2*4)
	JSL EmptyBG34
	JSR EmptyAttackSprites

	LDX.b #40

.next
	STZ.w WRAM.Attacks.ID-1, X
	DEX
	BNE .next

	LDX.b #$FF
	STZ.b DP.BoxT

.nextenemy
	INX
	CPX.b #3
	BCS .doneenemies

	LDA.b DP.Enemy, X
	BEQ .nextenemy

	PHX
	PHB
	PHP

	REP #$30
	AND #$00FF
	ASL
	ASL
	TAX

	LDA.l Attack_routine_pointers+0, X
	STA.b DP.GameJML+0
	LDA.l Attack_routine_pointers+2, X
	SEP #$30
	STA.b DP.GameJML+2

	PHK
	PEA .ret-1

	PHA
	PLB

	JML.w [DP.GameJML]

.ret
	PLP
	PLB
	PLX
	BRA .nextenemy

.doneenemies
	SEP #$30
	; now do the battle box
	LDA.b DP.BoxT
	BNE .drawboxnow

	LDA.b #$30 ; default battle box size
	STA.b DP.BoxT

.drawboxnow
	JSR Battle_PrepBoxBuilder
	LDA.b #$00
	STA.b DP.Soul.Mode
	LDA.b #124
	STA.b DP.Soul.X
	LDA.b #130
	STA.b DP.Soul.Y

.drawbox
	JSR Battle_BoxBuilding
	LDA.b DP.BoxT
	AND #$7F
	CMP.b DP.BoxW
	BEQ .done
	JSR WaitForNMI_ButAnimateSprites
	BRA .drawbox

.done
	SEP #$31

	; set up boundaries for movement in the box
	LDA.b #$82
	SBC.b DP.BoxW
	STA.b DP.BoxXmin

	CLC
	LDA.b #$76
	ADC.b DP.BoxW
	STA.b DP.BoxXmax

.nextattackframe
	SEP #$30
	STZ.b DP.DoneAttacks

	JSR MoveSoulBox

	LDY.b #$00
	LDX.b #$00

.checkattack
	REP #$20
	LDA.w WRAM.Attacks.Pointers+0, Y
	BEQ ..skip

	LDA.w WRAM.Attacks.Dur+0, X
	BNE ..attempt
	STA.w WRAM.Attacks.Pointers+0, Y ; kill the attack
	BRA ..skip

..attempt
	DEC
	STA.w WRAM.Attacks.Dur+0, X

	SEP #$20
	INC.b DP.DoneAttacks
	PHY
	PHX
	PHP
	PHB

	PHK
	PEA ..ret-1

	LDA.w WRAM.Attacks.Pointers+3, Y
	STA.b DP.GameJML+2
	PHA

	LDA.w WRAM.Attacks.Pointers+2, Y
	STA.b DP.GameJML+1
	LDA.w WRAM.Attacks.Pointers+1, Y
	STA.b DP.GameJML+0

	PLB
	JML.w [DP.GameJML]

..ret
	PLB
	PLP
	PLX
	PLY

..skip
	INY
	INY
	INX
	INY
	INY
	INX

	CPY #$09
	BCC .checkattack

	SEP #$20
	JSR DoAllAttackSprites

	JSR WaitForNMI_ButAnimateSprites

	LDA.b DP.HP
	BNE .notdead
	JMP YOUDIED

.notdead
	LDA.b DP.DoneAttacks
	BNE .nextattackframe

EnemyRequestNewRandomMessage:
	SEP #$30
	LDA.b #$80
	STA.b DP.Soul.Mode
	JSR BattleText_EmptyText

	LDX.b #$FF

.nextenemy
	INX
	CPX.b #3
	BCS .doneenemies

	TXY
	LDA.b DP.Enemy, X
	BEQ .nextenemy

	PHX
	PHB
	PHP

	REP #$30
	AND #$00FF
	ASL
	ASL
	TAX

	LDA.l Random_text_pointers+0, X
	STA.b DP.GameJML+0
	LDA.l Random_text_pointers+2, X
	SEP #$30
	STA.b DP.GameJML+2

	PHK
	PEA .ret-1

	PHA
	PLB

	JML.w [DP.GameJML]

.ret
	PLP
	PLB
	PLX
	BRA .nextenemy

.doneenemies
	LDA.b #$01
	STA.b DP.Submodule
	RTS

YOUDIED:
	LDA.b #$07
	STA.b DP.Submodule
	RTS

MoveSoulBox:
	LDA.b DP.Controller.A

	AND.b #$0F
	ASL
	TAX

	JMP (.dpadpress, X)

	; UDLR
.dpadpress
	dw .none 		; 0000
	dw .right 		; 0001
	dw .left 		; 0010
	dw .right		; 0011
	dw .down		; 0100
	dw .downright	; 0101
	dw .downleft	; 0110
	dw .downright	; 0111
	dw .up			; 1000
	dw .upright		; 1001
	dw .upleft		; 1010
	dw .upright		; 1011
	dw .up			; 1100
	dw .upright		; 1101
	dw .upleft		; 1110
	dw .upright		; 1111

.downright
	INC.b DP.Soul.Y
.right
	INC.b DP.Soul.X
	BRA .correct

.downleft
	INC.b DP.Soul.Y
.left
	DEC.b DP.Soul.X
	BRA .correct

.down
	INC.b DP.Soul.Y
	BRA .correct

.upright
	INC.b DP.Soul.X
.up
	DEC.b DP.Soul.Y
	BRA .correct

.upleft
	DEC.b DP.Soul.X
	DEC.b DP.Soul.Y
	BRA .correct

.correct
	LDA.b DP.Soul.X
	CMP.b DP.BoxXmax
	BCC .checkminX

	LDA.b DP.BoxXmax
	STA.b DP.Soul.X
	BRA .checkY

.checkminX
	CMP.b DP.BoxXmin
	BCS .checkY

	LDA.b DP.BoxXmin
	STA.b DP.Soul.X

.checkY
	LDA.b DP.Soul.Y
	CMP.b #$9D
	BCC .checkminY

	LDA.b #$9D
	STA.b DP.Soul.Y
	BRA .done

.checkminY
	CMP.b #$68
	BCS .done

	LDA.b #$68
	STA.b DP.Soul.Y
	BRA .done

.none
	JSL UTRandomInt

.done
	RTS

EmptyAttackSprites:
	LDX.b #!ATTACK_SLOTS-1

--	STZ.w WRAM.Attacks.ID, X
	DEX
	BPL --
	RTS

RequestAttackSprite:
	SEP #$30
	LDY.b #!ATTACK_SLOTS-1
--	LDA.w WRAM.Attacks.ID, Y
	BEQ .found
	DEY
	BPL --
.found
	TYA
	RTL

DoAllAttackSprites:
	LDY.b #!ATTACK_SLOTS-1

.nextslot
	LDA.w WRAM.Attacks.ID, Y
	BEQ .skip

	ASL
	TAX

	PHP
	JSR (.attackthings, X)
	PLP

.skip
	DEY
	BPL .nextslot
.nothing
	RTS

.attackthings
	dw .nothing
	dw .basicrectangle
	dw .bg3rectangle
	dw .bg4rectangle

	dw .fireball
	dw 0
	dw .reversebg3rectangle
	dw .reversebg4rectangle

	dw .batflap
	dw .batfly
	dw .thrustingspeartarget ; 10
	dw .thrustingspearwait

	dw .thrustingspearthrust


.bg3rectangle
.bg4rectangle

.reversebg3rectangle
	LDA.w WRAM.Attacks.X, Y
	SEC
	SBC.b DP.BG3HOFS
	STA.b DP.Scratch+2

	LDA.w WRAM.Attacks.Y, Y
	SEC
	SBC.b DP.BG3VOFS
	STA.b DP.Scratch+3

	LDA.w WRAM.Attacks.W, Y
	STA.b DP.Scratch+4
	LDA.w WRAM.Attacks.H, Y
	STA.b DP.Scratch+5
	JSR CheckIfSoulContact
	BCS ..nohit
	LDA.b #8
	JSR DamageSoul
..nohit
	RTS

.reversebg4rectangle

.basicrectangle

.fireball
	LDA.w WRAM.Attacks.X, Y
	STA.b DP.OAM.d.x
	STA.b DP.Scratch+2

	LDA.w WRAM.Attacks.Y, Y
	CMP.b #$9D ; move down
	BCS ++
	INC
++	STA.w WRAM.Attacks.Y, Y
	STA.b DP.OAM.d.y
	SEC
	SBC.b #$05
	STA.b DP.Scratch+3

	LDA.b #8
	STA.b DP.Scratch+4
	LDA.b #13
	STA.b DP.Scratch+5

	JSR CheckIfSoulContact
	BCC ..nohit

	LDA.b #8
	JSR DamageSoul

..nohit
	LDA.b #$B8
	STZ.b DP.OAM.p
	STA.b DP.OAM.d.t
	LDA.w WRAM.Attacks.T, Y
	DEC
	STA.w WRAM.Attacks.T, Y
	AND.b #$04
	ASL
	ASL
	ASL
	ASL
	ORA.b #$20
	STA.b DP.OAM.d.p
	LDA.b #$00
	STA.b DP.OAM.d.s

	JSL AddOAM
	LDA.b #$A8
	STA.b DP.OAM.d.t
	LDA.b DP.OAM.d.y
	SEC
	SBC.b #$08
	INC.b DP.OAM.p
	STA.b DP.OAM.d.y
	JSL AddOAM

.easyexitA
	RTS

.batflap
	TYX
	LDA.w WRAM.Attacks.D, Y ; set up tile now with a slow flap
	AND.b #$10
	LSR
	LSR
	LSR
	ORA.b #$80
	STA.b DP.OAM.d.t

	JSR .batdraw
	DEC.w WRAM.Attacks.T, X
	BNE .easyexitA

.battargetsoul
	INC.w WRAM.Attacks.ID, X ; next phase is a different entity just cause
	; TODO calculate trajectory
	LDA.w WRAM.Attacks.Y, Y
	CMP.b DP.Soul.Y
	LDA.b #$01
	BCC ++
	LDA.b #$FF
++	STA.w WRAM.Attacks.B, Y

	LDA.w WRAM.Attacks.X, Y
	CMP.b DP.Soul.X
	LDA.b #$01
	BCC ++
	LDA.b #$FF
++	STA.w WRAM.Attacks.A, Y

	LDA.b #60
	STA.w WRAM.Attacks.T, Y
	RTS

.batfly
	TYX
	LDA.w WRAM.Attacks.D, Y ; set up tile now with a fast flap
	AND.b #$08
	LSR
	LSR
	ORA.b #$80
	STA.b DP.OAM.d.t

	LDA.w WRAM.Attacks.X, Y
	CLC
	ADC.w WRAM.Attacks.A, Y
	STA.w WRAM.Attacks.X, Y

	LDA.w WRAM.Attacks.Y, Y
	CLC
	ADC.w WRAM.Attacks.B, Y
	STA.w WRAM.Attacks.Y, Y

	JSR .batdraw

	JSR CheckIfSoulContact
	BCC ..nohit

	LDA.b #8
	JSR DamageSoul

..nohit
	DEC.w WRAM.Attacks.T, X
	BNE ++
	STZ.w WRAM.Attacks.ID, X
++	RTS

.batdraw
	DEC.w WRAM.Attacks.D, X

	; bat draw/hitbox setup
	LDA.b #16
	STA.b DP.Scratch+4
	LDA.b #10
	STA.b DP.Scratch+5

	LDA.w WRAM.Attacks.X, Y
	SEC
	SBC.b #8
	STA.b DP.Scratch+2
	SEC
	SBC.b #8
	STA.b DP.OAM.d.x

	LDA.w WRAM.Attacks.Y, Y
	STA.b DP.OAM.d.y
	CLC
	ADC.b #3
	STA.b DP.Scratch+3

	LDA.b #$30
	STA.b DP.OAM.d.p

	LDA.b #$02
	STA.b DP.OAM.d.s

	JSL AddOAM

	CLC
	LDA.b DP.OAM.d.x
	ADC.b #16
	STA.b DP.OAM.d.x

	LDA.b DP.OAM.d.p
	ORA.b #$40
	STA.b DP.OAM.d.p

	JSL AddOAM

	RTS

.thrustingspeartarget
	LDA.b DP.Soul.Y
	STA.w WRAM.Attacks.Y, Y

.thrustingspearwait
	TYX
	DEC.w WRAM.Attacks.T, X
	BNE .thrustingspearmain
	INC.w WRAM.Attacks.ID, X
	LDX.w WRAM.Attacks.ID, Y
	LDA.w ..timers-11, X
	STA.w WRAM.Attacks.T, Y

	BRA .thrustingspearmain

..timers
	db 30, 50

.thrustingspearthrust
	TYX
	DEC.w WRAM.Attacks.T, X
	BNE ..move
	STZ.w WRAM.Attacks.ID, X

..move
	LDX.w WRAM.Attacks.A, Y
	LDA.w ..speeds, X
	CLC
	ADC.w WRAM.Attacks.X, Y
	STA.w WRAM.Attacks.X, Y
	BRA .thrustingspearmain

..speeds
	dw -3, 3

.thrustingspearmain
	LDX.w WRAM.Attacks.A, Y

	LDA.w WRAM.Attacks.X, Y
	STA.b DP.OAM.d.x
	STA.b DP.Scratch+2

	LDA.w WRAM.Attacks.Y, Y
	STA.b DP.OAM.d.y
	DEC
	STA.b DP.Scratch+3

	JSR (..direction, X)
	; hitbox and draw

	; first do the head
	REP #$20
	LDA.w #$0D10
	STA.b DP.Scratch+4
	JSR CheckIfSoulContact
	BCS ..hit

..checkshaft
	LDA.b DP.Scratch+3
	ADC.b #5
	STA.b DP.Scratch+3

	SEC
	LDX.w WRAM.Attacks.A, Y
	LDA.b DP.Scratch+2
	ADC.w ..hitoffset, X
	STA.b DP.Scratch+2

	REP #$20
	LDA.w #$0310
	STA.b DP.Scratch+4
	JSR CheckIfSoulContact
	BCC ..nohit

..hit
	LDA.b #$07
	JSR DamageSoul

..nohit
	RTS

..hitoffset
	dw 16, -16


..direction
	dw ...left
	dw ...right

...left
	LDA.b #$A2
	STA.b DP.OAM.d.t

	LDA.b #$30
	STA.b DP.OAM.d.p

	LDA.b #$02
	STA.b DP.OAM.d.s

	JSL AddOAM

	CLC
	LDA.b DP.OAM.d.x
	ADC.b #16
	STA.b DP.OAM.d.x

	INC.b DP.OAM.d.y
	INC.b DP.OAM.d.y
	INC.b DP.OAM.d.y

	LDA.b #$B6
	STA.b DP.OAM.d.t

	LDA.b #$70
	STA.b DP.OAM.d.p

	STZ.b DP.OAM.d.s

	JSL AddOAM

	CLC
	LDA.b DP.OAM.d.x
	ADC.b #8
	STA.b DP.OAM.d.x

	LDA.b #$B6
	STA.b DP.OAM.d.t

	LDA.b #$30
	STA.b DP.OAM.d.p

	STZ.b DP.OAM.d.s

	JSL AddOAM

	RTS

...right
	LDA.b #$A2
	STA.b DP.OAM.d.t

	LDA.b #$70
	STA.b DP.OAM.d.p

	LDA.b #$02
	STA.b DP.OAM.d.s

	JSL AddOAM

	SEC
	LDA.b DP.OAM.d.x
	SBC.b #8
	STA.b DP.OAM.d.x

	INC.b DP.OAM.d.y
	INC.b DP.OAM.d.y
	INC.b DP.OAM.d.y

	LDA.b #$B6
	STA.b DP.OAM.d.t

	LDA.b #$30
	STA.b DP.OAM.d.p

	STZ.b DP.OAM.d.s

	JSL AddOAM

	SEC
	LDA.b DP.OAM.d.x
	SBC.b #8
	STA.b DP.OAM.d.x

	LDA.b #$B6
	STA.b DP.OAM.d.t

	LDA.b #$70
	STA.b DP.OAM.d.p

	STZ.b DP.OAM.d.s

	JSL AddOAM

	RTS


;==============================================================================
; expects:
;   Scratch+2 to have effective location of entity
;   Scratch+4 to have HHWW of hitbox
;   Y to have slot of entity
;==============================================================================
CheckIfSoulContact:
	SEP #$20
	; get full perimeter of the hitbox
	CLC
	LDA.b DP.Scratch+2
	ADC.b DP.Scratch+4
	STA.b DP.Scratch+4

	CLC
	LDA.b DP.Scratch+3
	ADC.b DP.Scratch+5
	STA.b DP.Scratch+5

	LDA.b DP.Soul.X ; is the left side of the soul within bounds?
	CMP.b DP.Scratch+4
	BEQ .fine
	BCS .nohit

.fine
	CLC
	ADC.b #$08 ; is the right side of soul within bounds?
	CMP.b DP.Scratch+2
	BCS .checkY

.nohit
	CLC
	RTS

.checkY
	LDA.b DP.Soul.Y ; is the top side of the soul within bounds?
	CMP.b DP.Scratch+3
	BCC .nohit

	; carry is set already
	ADC.b #$07 ; is the bottom side of the soul within bounds?
	CMP.b DP.Scratch+5
	BEQ .hit
	BCS .nohit

.hit
	SEC
	RTS




DamageSoul:
	STA.b DP.Scratch
	LDA.b DP.iFrames
	BNE .nodamage

	SEC
	LDA.b DP.HP
	SBC.b DP.Scratch
	BCS .fine
	LDA.b #$00

.fine
	STA.b DP.HP

	LDA.b #$28
	STA.b DP.iFrames

.nodamage
	RTS






















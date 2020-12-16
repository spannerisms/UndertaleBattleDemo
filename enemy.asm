%next_enemy()

%enemy_attack_routine()
Ganon_RequestAttack:
	SEP #$30
	JSL UTRandomInt

	AND.b #$07
	; TODO debug to always test same attack
	; Spears that target then thrust
	; some blue and sideways?
	;LDA.b #$03
	AND.b #$03

	TAX ; index of attack

	LDA.b DP.SelectedEnemy
	ASL
	TAY ; slot of attack

	LDA.w .boxsizes, X
	JSL Attack_RequestBoxSize

	TXA ; get *2 for 16 bit values
	ASL
	TAX

	LDA.w .durations+0, X
	STA.w WRAM.Attacks.Dur+0, Y
	LDA.w .durations+1, X
	STA.w WRAM.Attacks.Dur+1, Y

	LDA.b #$00
	STA.w WRAM.Attacks.Phase+0, Y

	JSL UTRandomInt
	AND.b #$0F
	STA.w WRAM.Attacks.Phase+1, Y

	TYA ; *4 of slot now for pointers
	ASL
	TAY

	PHK ; bank
	PLA
	STA.w WRAM.Attacks.Pointers+3, Y

	LDA.w .doattacks+1, X ; high
	STA.w WRAM.Attacks.Pointers+2, Y

	LDA.w .doattacks+0, X ; low
	STA.w WRAM.Attacks.Pointers+1, Y

	LDA.b #$01
	STA.w WRAM.Attacks.Pointers+0, Y

	JSR.w (.attackspre, X)
	RTL

; ideas
;    border of spears that moves
;    falling fire
;    8 targetting bats
;    trident spinning

.boxsizes
	db $20
	db $30
	db $30
	db $36
	db $00
	db $00
	db $00
	db $00

.durations
	dw 300
	dw 300
	dw 300
	dw 300
	dw 300
	dw 300
	dw 300
	dw 300

.attackspre
	dw GanonAttackSetup_00
	dw GanonAttackSetup_01
	dw GanonAttackSetup_02
	dw GanonAttackSetup_03
	dw GanonAttackSetup_04
	dw GanonAttackSetup_05
	dw GanonAttackSetup_06
	dw GanonAttackSetup_07

.doattacks
	dw GanonAttack_00
	dw GanonAttack_01
	dw GanonAttack_02
	dw GanonAttack_03
	dw GanonAttack_04
	dw GanonAttack_05
	dw GanonAttack_06
	dw GanonAttack_07

GanonAttackSetup_00:
GanonAttackSetup_02:
GanonAttackSetup_03:
GanonAttackSetup_04:
GanonAttackSetup_05:
GanonAttackSetup_06:
GanonAttackSetup_07:
	RTS







GanonAttack_00: ; Fire balls falling
	LDA.w WRAM.Attacks.Phase+0, X
	STA.b DP.Scratch
	ASL
	TAY

	REP #$20
	LDA.w WRAM.Attacks.Dur+0, X
	CMP.w .balltriggers, Y
	BNE .exit

.spawnball
	SEP #$20
	INC.w WRAM.Attacks.Phase+0, X

	LDA.b DP.Scratch
	CLC
	ADC.w WRAM.Attacks.Phase+1, X
	TAX

	JSL RequestAttackSprite
	BMI .exit

	LDA.b #$04
	STA.w WRAM.Attacks.ID, Y

	LDA.w .ballpositions, X
	STA.w WRAM.Attacks.X, Y

	LDA.b #$60
	STA.w WRAM.Attacks.Y, Y

	LDA.b #$00
	STA.w WRAM.Attacks.D, Y

	JSL UTRandomInt
	STA.w WRAM.Attacks.T, Y

.exit
	RTL

.balltriggers
	dw 280
	dw 260
	dw 240
	dw 230
	dw 220
	dw 210
	dw 200
	dw 190
	dw 180
	dw 170
	dw 160
	dw 150
	dw 140
	dw 130
	dw 120

.ballpositions
	db $70
	db $98
	db $88
	db $80
	db $68
	db $62
	db $78
	db $68
	db $82
	db $90
	db $6E
	db $82
	db $72
	db $8E
	db $90
	db $64
	db $85
	db $78
	db $68
	db $8E
	db $73
	db $92
	db $88
	db $65
	db $79
	db $96
	db $68
	db $88
	db $80
	db $72
	db $62
	db $78
	db $68
	db $92
	db $62
	db $8E
	db $90
	db $64
	db $85
	db $78
	db $68
	db $5E
	db $73
	db $92

GanonAttackSetup_01: ; square spear wall
	REP #$20
	STZ.w WMADDR

	LDA.w #$8000
	STA.w DMA0MODE

	LDA.w #$0800
	STA.w DMA0SIZE

	LDA.w #.tilemap
	STA.w DMA0ADDR

	SEP #$20
	LDA.b #.tilemap>>16
	STA.w DMA0ADDRB

	LDA.b #$01
	STA.w WMADDH
	STA.w DMAENABLE
	STA.b DP.NMI_AttackBGUpdate

	SEP #$30
	LDA.b #$28
	JSL Attack_RequestBoxSize
	JSL EnableBG3Attack
	LDA.b #$01
	STA.b DP.NMI_AttackBGUpdate

	JSR RandomBoxMove
	JSL RequestAttackSprite
	BMI ++

	LDA.b #$06
	STA.w WRAM.Attacks.ID, Y
	LDA.b #14*8
	STA.w WRAM.Attacks.X, Y

	LDA.b #15*8
	STA.w WRAM.Attacks.Y, Y

	LDA.b #4*8-1
	STA.w WRAM.Attacks.W, Y

	LDA.b #4*8-1
	STA.w WRAM.Attacks.H, Y

++	RTS

.tilemap
	fillword $A011 : fill $0380
	fillword $A001 : fill $0040

	fillword $2012 : fill 12*2
	dw $2003
	fillword $0000 : fill 6*2
	dw $6003
	fillword $6012 : fill 12*2

	fillword $2012 : fill 12*2
	dw $2003
	fillword $0000 : fill 6*2
	dw $6003
	fillword $6012 : fill 12*2

	fillword $2012 : fill 12*2
	dw $2003
	fillword $0000 : fill 6*2
	dw $6003
	fillword $6012 : fill 12*2

	fillword $2012 : fill 12*2
	dw $2003
	fillword $0000 : fill 6*2
	dw $6003
	fillword $6012 : fill 12*2

	fillword $2001 : fill $0040
	fillword $2011 : fill 12*64

GanonAttack_01:
	LDA.w WRAM.Attacks.Bonus, X
	BNE .no

	TXY
	JSR RandomBoxMove
	TYX

.no
	DEC.w WRAM.Attacks.Bonus, X
	LDA.b DP.Frame
	AND.b #$03
	BNE .wait
	LDA.w WRAM.Attacks.Phase+0, X
	CLC
	ADC.b DP.BG3HOFS
	STA.b DP.BG3HOFS

	CMP.b #$30
	BCC .doneX
	CMP.b #$D0
	BCS .doneX

.invertX
	LDA.w WRAM.Attacks.Phase+0, X
	EOR.b #$FF
	INC
	STA.w WRAM.Attacks.Phase+0, X

.doneX
	LDA.w WRAM.Attacks.Phase+1, X
	CLC
	ADC.b DP.BG3VOFS
	STA.b DP.BG3VOFS

	CMP.b #$20
	BCC .doneY
	CMP.b #$E0
	BCS .doneY

.invertY
	LDA.w WRAM.Attacks.Phase+1, X
	EOR.b #$FF
	INC
	STA.w WRAM.Attacks.Phase+1, X

.doneY
.wait
	RTL

RandomBoxMove:
	JSL UTRandomInt
	AND.b #$1F
	ADC.b #$10
	STA.w WRAM.Attacks.Bonus+0, Y
	JSL UTRandomInt
	AND #$07
	TAX
	LDA.l .xs, X
	STA.w WRAM.Attacks.Phase+0, Y
	LDA.l .ys, X
	STA.w WRAM.Attacks.Phase+1, Y
	RTS

.xs
	db 0, -1, 1, 0, -1, -1, 1, 1

.ys
	db 1, 0, 0, -1, 1, -1, 1, -1

GanonAttack_02: ; spawns bats
	LDA.w WRAM.Attacks.Phase+0, X
	ASL
	TAY

	REP #$20
	LDA.w WRAM.Attacks.Dur+0, X
	CMP.w .battriggers, Y
	BNE .exit

.spawnbat
	SEP #$20
	INC.w WRAM.Attacks.Phase+0, X

	JSL RequestAttackSprite
	BMI .exit

	LDA.b #8
	STA.w WRAM.Attacks.ID, Y

	JSL UTRandomInt
	CMP.b #85
	BCC .leftside

	CMP.b #170
	BCS .rightside

.middle
	JSL UTRandomInt
	AND.b #$7F
	ADC.b #$30
	STA.w WRAM.Attacks.X, Y

	LDA.b #$58
	BRA .continue

.leftside
	LDA.b #$40
	BRA .randomY

.rightside
	LDA.b #$B8

.randomY
	STA.w WRAM.Attacks.X, Y
	JSL UTRandomInt
	AND.b #$3F
	ADC.b #$50

.continue
	STA.w WRAM.Attacks.Y, Y

	LDA.b #100
	STA.w WRAM.Attacks.T, Y

	JSL UTRandomInt
	STA.w WRAM.Attacks.D, Y

.exit
	RTL


.battriggers
	dw 280
	dw 260
	dw 240
	dw 230
	dw 220
	dw 210
	dw 200
	dw 190
	dw 180
	dw 170
	dw 160
	dw 150
	dw 140
	dw 130
	dw 120

GanonAttack_03: ; thrusting spears
	LDA.w WRAM.Attacks.Phase+0, X
	ASL
	TAY

	REP #$20
	LDA.w WRAM.Attacks.Dur+0, X
	CMP.w .triggers, Y
	BNE .exit

.spawn
	SEP #$20
	INC.w WRAM.Attacks.Phase+0, X

	JSL RequestAttackSprite
	BMI .exit

	LDA.b #10
	STA.w WRAM.Attacks.ID, Y

	JSL UTRandomInt
	AND.b #$02
	STA.w WRAM.Attacks.A, Y
	BNE .leftside

.rightside
	LDA.b #$B8
	BRA .continue

.leftside
	LDA.b #$38

.continue
	STA.w WRAM.Attacks.X, Y

	LDA.b #20
	STA.w WRAM.Attacks.T, Y

.exit
	RTL


.triggers
	dw 280
	dw 250
	dw 240
	dw 200
	dw 180
	dw 170
	dw 140
	dw 110
	dw 90




GanonAttack_04:
GanonAttack_05:
GanonAttack_06:
GanonAttack_07: 








%enemy_draw_routine()
GanonDraw:
	SEP #$31
	TYX
	LDA.l EnemySpritePositions, X
	STA.b DP.Scratch+2
	LDA.b #$06
	STA.b DP.Scratch+4

	LDY.b #0

.nexttile
	TYA
	ASL
	ASL
	TAX
	LDA.b DP.Frame
	AND.b #$40
	ADC.l .tile+0, X
	STA.b DP.OAM.d.t

	LDA.l .tile+1, X
	CLC
	ADC.b DP.Scratch+2
	STA.b DP.OAM.d.x

	LDA.l .tile+2, X
	CLC
	ADC.b #12 ; base y position
	STA.b DP.OAM.d.y

	LDA.b #$02
	STA.b DP.OAM.d.s

	LDA.l .tile+3, X
	STA.b DP.OAM.d.p

	LDA.b #$01
	STA.b DP.OAM.p

	JSL AddOAM

	INY
	CPY.b #32
	BCC .nexttile
	RTL

.tile
	db $00, $D0, $00, $21
	db $02, $E0, $00, $21
	db $04, $F0, $00, $21
	db $04, $00, $00, $61
	db $02, $10, $00, $61
	db $00, $20, $00, $61

	db $06, $D0, $10, $21
	db $08, $E0, $10, $21
	db $0A, $F0, $10, $21
	db $0A, $00, $10, $61
	db $08, $10, $10, $61
	db $06, $20, $10, $61

	db $0C, $D0, $20, $21
	db $0E, $E0, $20, $21
	db $20, $F0, $20, $21
	db $20, $00, $20, $61
	db $0E, $10, $20, $61
	db $0C, $20, $20, $61

	db $22, $D0, $30, $21
	db $24, $E0, $30, $21
	db $26, $F0, $30, $21
	db $26, $00, $30, $61
	db $24, $10, $30, $61
	db $22, $20, $30, $61

	db $28, $E0, $2C, $21
	db $2A, $F0, $2C, $21
	db $2A, $00, $2C, $61
	db $28, $10, $2C, $61

	db $2C, $DE, $3C, $21
	db $2E, $EE, $3C, $21
	db $2E, $02, $3C, $61
	db $2C, $12, $3C, $61

!text_count = 0
macro random_text(n)
	?temp:
	pushpc
	org .random+2*!text_count
	dw ?temp
	pullpc
	!text_count #= !text_count+1
endmacro

%enemy_hp(255)

Ganon_Text:
%enemy_text_routine()
	PHK
	LDA.w DP.Enemy.MessageAI, Y
	REP #$20
	AND #$00FF
	ASL
	TAX
	LDA.l .messagecheck, X
	PHA
	SEP #$20

	TYX ; X has slot now
	LDA.b DP.Enemy.HP, X
	RTS ; go to phase routine

.messagecheck
	dw ..phase1-1
	dw ..phase2-1
	dw ..phase3-1
	dw .stillPhase-1


..phase1
	CMP #$D1
	BCS .stillPhase
	PEA.w .phase2
	BRA .nextphase

..phase2
	CMP #$A1
	BCS .stillPhase
	PEA.w .phase3
	BRA .nextphase

..phase3
	CMP #$64
	BCS .stillPhase
	PEA.w .phase4

.nextphase
	INC.b DP.Enemy.MessageAI, X
	BRA .presetmessage

.stillPhase
	JSL UTRandomInt
	AND.b #$3E
	TAX
	REP #$20
	LDA.l .random, X
	PHA

.presetmessage
	PEA $0001
	JSL BattleText_AddMessages
	RTL

.random
	skip 64

%enemy_name_text_pointer()
db "Ganon", 0

%enemy_intro_text_pointer()
db "Ganon presents you with%"
db "three (3) boxes of text."
db 0

.phase2
db "Ganon is practicing for%"
db "the flag squad tryouts."
db 0

.phase3
db "Ganon begins throwing a%"
db "temper tantrum."
db 0

.phase4
db "Ganon aggressively flips%"
db "the light switch off."
db 0

;------------------------------------------------------------------------------
%random_text("garish")
;  "012345678901234567890123"
db "Ganon is feeling just a%"
db "little bit garish."
db 0

%random_text("cheese")
db "Ganon shares with you%"
db "some cheese trivia."
db 0

%random_text("arrows")
db "Ganon tells you where%"
db "the bronze arrows are."
db 0

%random_text("slugs")
db "Ganon shares a detailed%"
db "description of slugs."
db 0

%random_text("hug")
db "Ganon gives you a great%"
db "big hug."
db 0

%random_text("fashion")
db "Ganon offers you some%"
db "advice on fashion."
db 0

%random_text("total")
db "Ganon adds another game%"
db "to SMZ3 randomizer."
db 0

%random_text("aerinon")
db "Ganon shuffles a door%"
db "then shuffles it back."
db 0

%random_text("chris")
db "Ganon calls you numpty."
db 0

%random_text("synack")
db "Ganon adds a new weight%"
db "set to Sahasrahbot."
db 0

%random_text("fish")
db "Ganon pets Marvin.%"
db 0

%random_text("richey")
db "Ganon tries to arrange a%"
db "song based on his theme."
db 0

%random_text("alucard")
db "Ganon can't do this\!%"
db "&What a stoops\!"
db 0

%random_text("veetorp")
db "Ganon plays some music%"
db "by ElectroCult Circus."
db 0

%random_text("zarby")
db "Ganon makes a hack using%"
db "ZScream."
db 0

%random_text("kan")
db "Ganon reads some blogs%"
db "on glitch explications."
db 0

%random_text("")
db "Ganon just does."
db 0

%random_text("")
db "Ganon makes an unfunny%"
db "randomizer joke that you%"
db "have heard 1000000 times%"
db "before."
db 0

%random_text("")
db "Ganon pulls some wax out%"
db "of his ears."
db 0

%random_text("")
db "Ganon smiles at you, as%"
db "if he's expecting you to%"
db "ask him out to dinner."
db 0

%random_text("")
db "Ganon says it's now your%"
db "turn to do something."
db 0

%random_text("")
db "Ganon tests how the text%"
db "engine handles overflow."
db "[][][][][][][][][][][][][][][][][][][][][]"
db 0

%random_text("")
db "Ganon is running out of%"
db "ideas for messages, but%"
db "he needs to have 32."
db 0

%random_text("")
db "Ganon finds you to be in%"
db "violation of 17 USC%"
db "section 110 subsection 6.%"
db 0

%random_text("")
db "Ganon wants to share his%"
db "Sans X Sans fanfiction.%"
db "(18+)"
db 0

%random_text("")
db "Ganon takes you to his%"
db "leader's liter."
db 0

%random_text("")
db "Ganon withdraws his bid%"
db "for the Zelda Nendoroid%"
db "he saw on eBay."
db 0

%random_text("")
db "Ganon reschedules his%"
db "3 o' clock appointment."
db 0

%random_text("")
db "Ganon waits for NMI."
db 0

%random_text("")
db "Ganon solves the Collatz%"
db "Conjecture for n<17."
db 0

%random_text("")
db "Ganon cuts stream.%"
db "&Thanks for watching!"
db 0

%random_text("")
db "Ganon dabs.%"
db "&Ganon is now disgusted%"
db "with himself."
db 0

%enemy_act_text_pointer()
db "Fun fact", 0
db "Cower", 0
db "Silvers", 0
dw 0

%enemy_check_text_pointer()
db "GANON 20 ATK 10 DEF%"
db "&Evil king of thieves.%"
db "&His fly is down."
db 0

GanonAct:
%enemy_check_routine()
	SEP #$30
	LDA.b DP.Befriended
	BEQ .nofriends
	LDA.b #$00
	BRA .setlevel

.nofriends
	LDA.b DP.Enemy.ActLevel

.setlevel
	ASL ; x8 for pointer base
	ASL
	ASL
	STA.b DP.Scratch+4

	LDA.b #GanonAct>>16
	STA.b DP.Scratch+2 ; get bank

	LDA.b DP.Menu.Pos.Text ; get selection
	DEC ; -1 since 0 is check
	ASL ; x2 for pointer
	ADC.b DP.Scratch+4
	CMP.b #124 ; s15_silvers
	BEQ .silvermessages

	TAX
	REP #$20
	LDA.l .pointers, X

.addmessage
	STA.b DP.Scratch+0
	RTL

.silvermessages
	LDA.l $7EF38E
	AND.b #$40 ; check for silvers
	REP #$20
	BEQ .nosilvers
.silvers
	LDA.w #GanonAct_s15_silversYES
	BRA .addmessage
.nosilvers
	LDA.w #GanonAct_s15_silversNO
	BRA .addmessage

.pointers
	dw GanonAct_s00_trivia, GanonAct_s00_cower, GanonAct_s00_silvers, GanonAct_s00_reserved
	dw GanonAct_s01_trivia, GanonAct_s01_cower, RejectSilvers, GanonAct_s01_reserved
	dw GanonAct_s02_trivia, GanonAct_s02_cower, RejectSilvers, GanonAct_s02_reserved
	dw GanonAct_s03_trivia, GanonAct_s03_cower, RejectSilvers, GanonAct_s03_reserved
	dw GanonAct_s04_trivia, GanonAct_s04_cower, RejectSilvers, GanonAct_s04_reserved
	dw GanonAct_s05_trivia, GanonAct_s05_cower, RejectSilvers, GanonAct_s05_reserved
	dw GanonAct_s06_trivia, GanonAct_s06_cower, RejectSilvers, GanonAct_s06_reserved
	dw GanonAct_s07_trivia, GanonAct_s07_cower, RejectSilvers, GanonAct_s07_reserved
	dw GanonAct_s08_trivia, GanonAct_s08_cower, RejectSilvers, GanonAct_s08_reserved
	dw GanonAct_s09_trivia, GanonAct_s09_cower, RejectSilvers, GanonAct_s09_reserved
	dw GanonAct_s10_trivia, GanonAct_s10_cower, RejectSilvers, GanonAct_s10_reserved
	dw GanonAct_s11_trivia, GanonAct_s11_cower, RejectSilvers, GanonAct_s11_reserved
	dw GanonAct_s12_trivia, GanonAct_s12_cower, RejectSilvers, GanonAct_s12_reserved
	dw GanonAct_s13_trivia, GanonAct_s13_cower, GanonAct_s13_silvers, GanonAct_s13_reserved
	dw GanonAct_s14_trivia, GanonAct_s14_cower, GanonAct_s14_silvers, GanonAct_s14_reserved
	dw GanonAct_s15_trivia, GanonAct_s15_cower, GanonAct_s15_silvers, GanonAct_s15_reserved

.s00
	..trivia
		db "You share some trivia%"
		db "about your favorite%"
		db "brand of clown shoes."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon is quite visibly%"
		db "impressed by that fact."
		db !TEXT_INCREMENT_ACT_PUZZLE
		db 0

	..cower
		db "You begin crying."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon finds you weak%"
		db "and pathetic."
		db 0

	..silvers
		db "You ask Ganon if silvers%"
		db "are required to win."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon says they are, but%"
		db "only for the pacifist%"
		db "secret ending."
		db 0

	..reserved
		db ""

.s01
	..trivia
		db "You recite every xkcd%"
		db "mouse-over text entirely%"
		db "from memory."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon particularly liked%"
		db "1437."
		db !TEXT_INCREMENT_ACT_PUZZLE
		db 0

	..cower
		db "You shiver your timbers."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon looks the other%"
		db "way, awkwardly."
		db 0

	..reserved
		db ""

#RejectSilvers:
	..silvers
		db "You try to speak, but%"
		db "Ganon interrupts you.%"
		db "&He is offended by your%"
		db "thoughts."
		db !TEXT_RESET_ACT_PUZZLE
		db 0

.s02
	..trivia
		db "You belch the Cyrillic%"
		db "Alphabet."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon is in tears from%"
		db "laughter."
		db !TEXT_INCREMENT_ACT_PUZZLE
		db 0

	..cower
		db "You scream at the top of%"
		db "your lungs."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon wishes you hadn't."
		db !TEXT_DECREMENT_ACT_PUZZLE
		db 0

	..reserved
		db ""

.s03
	..trivia
		db "You tell Ganon Dwayne%"
		db "'The Rock' Johnson is%"
		db "186cm tall."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon corrects you.%"
		db "&The Rock is 196cm tall."
		db !TEXT_INCREMENT_ACT_PUZZLE
		db 0

	..cower
		db "You scream at the bottom%"
		db "of your lungs."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon thinks you're just%"
		db "being stupid."
		db !TEXT_DECREMENT_ACT_PUZZLE
		db !TEXT_DECREMENT_ACT_PUZZLE
		db 0

	..reserved
		db ""

.s04
	..trivia
		db "You tell Ganon Dwayne%"
		db "'The Rock' Johnson was%"
		db "born in the city Hayward%"
		db "comma California."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon is too focused on%"
		db "your previous error."
		db 0

	..cower
		db "You apologize profusely%"
		db "for your error regarding%"
		db "'The Rock'."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon smugly accepts%"
		db "your humble remorse."
		db !TEXT_INCREMENT_ACT_PUZZLE
		db 0

	..reserved
		db ""

.s05
	..trivia
		db "You note that the 1000th%"
		db "digit of pi is 9."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon proudly notes the%"
		db "2000th digit is also 9.%"
		db "&Ganon relishes in his%"
		db "superior fact."
		db !TEXT_INCREMENT_ACT_PUZZLE
		db 0

	..cower
		db "You beg on your knees%"
		db "for Ganon to forgive the%"
		db "Dwayne Johnson mistake."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon tells you to stop%"
		db "your whining."
		db !TEXT_DECREMENT_ACT_PUZZLE
		db !TEXT_DECREMENT_ACT_PUZZLE
		db 0

	..reserved
		db ""

.s06
	..trivia
		db "You share some trivia%"
		db "about the great artist%"
		db "Weird Al Yankovic."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon already knew that."
		db !TEXT_DECREMENT_ACT_PUZZLE
		db 0

	..cower
		db "You admit Ganon has more%"
		db "knowledge about pi than%"
		db "you could ever dream of%"
		db "having."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon blushes audibly."
		db !TEXT_INCREMENT_ACT_PUZZLE
		db 0

	..reserved
		db ""

.s07
	..trivia
		db "You share your knowledge%"
		db "on the historicity of%"
		db "King Arthur."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon says your fact is%"
		db "good, but not great."
		db !TEXT_INCREMENT_ACT_PUZZLE
		db 0

	..cower
		db "You do the hokey pokey."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon is confused."
		db 0

	..reserved
		db ""

.s08
	..trivia
		db "You grab your collection%"
		db "of Captain Underpants%"
		db "books, but Ganon flexes%"
		db "his Dav Pilky knowledge%"
		db "before you can speak."
		db !TEXT_INCREMENT_ACT_PUZZLE
		db 0

	..cower
		db "You pee yourself to show%"
		db "you really are scared."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon says to save that%"
		db "urine for the next step%"
		db "in the script."
		db 0

	..reserved
		db ""

.s09
	..trivia
		db "You explain that Miley%"
		db "Stewart is the same girl%"
		db "as Hannah Montana."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		;  "012345678901234567890123"
		db "&Ganon is fully enraged%"
		db "by these spoilers!"
		db !TEXT_RESET_ACT_PUZZLE
		db 0

	..cower
		db "You pee yourself to show%"
		db "you really are scared."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon gains confidence."
		db !TEXT_INCREMENT_ACT_PUZZLE
		db 0

	..reserved
		db ""

.s10
	..trivia
		db "You explain the stark%"
		db "difference between oak%"
		db "and red oak."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon just yawns as he%"
		db "picks his nose."
		db !TEXT_DECREMENT_ACT_PUZZLE
		db !TEXT_DECREMENT_ACT_PUZZLE
		db 0

	..cower
		db "You clean up your mess%"
		db "while praising Ganon's%"
		db "extensive trivia smarts."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon chuckles and says%"
		db "to not embarrass him."
		db !TEXT_INCREMENT_ACT_PUZZLE
		db 0

	..reserved
		db ""

.s11
	..trivia
		db "You spell your name but%"
		db "backwards."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon thought he was the%"
		db "only one who could ever%"
		db "do that."
		db !TEXT_INCREMENT_ACT_PUZZLE
		db 0

	..cower
		db ";TODO: FILL IN LATER"
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon is enraged by the%"
		db "lack of effort put into%"
		db "festive randomizers.%"
		db "& @admins don't let this%"
		db "happen again or I quit."
		db !TEXT_RESET_ACT_PUZZLE
		db 0

	..reserved
		db ""

.s12
	..trivia
		db "You try to share a fact%"
		db "about Jupiter, but you%"
		db "end up sharing a boring%"
		db "fact about Neptune."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon clicks Wikipedia's%"
		db "Random article button and%"
		db "reads the page aloud."
		db !TEXT_DECREMENT_ACT_PUZZLE
		db !TEXT_DECREMENT_ACT_PUZZLE
		db !TEXT_DECREMENT_ACT_PUZZLE
		db 0

	..cower
		db "You pull your shirt over%"
		db "your face."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon is beginning to%"
		db "feel more comfortable."
		db !TEXT_INCREMENT_ACT_PUZZLE
		db 0

	..reserved
		db ""

.s13
	..trivia
		db "You check your phone.%"
		db !TEXT_WAIT_FOR_KEY
		db "&You don't have a phone.%"
		db !TEXT_WAIT_FOR_KEY
		db "&It was actually a phome."
		db 0

	..cower
		db "You pour water over your%"
		db "face and insist it is a%"
		db "nervous sweat."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon doesn't seem very%"
		db "convinced."
		db 0

	..silvers
		db "You try to mention the%"
		db "silver arrows."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon mentions he needs%"
		db "some to finally complete%"
		db "his stick collection."
		db !TEXT_INCREMENT_ACT_PUZZLE
		db 0

	..reserved
		db ""

.s14
	..trivia
		db "You tell Ganon that an%"
		db "atom of silver has 47%"
		db "protons."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon says 'No duh.'%"
		db "&'Why do you think I want%"
		db "those arrows?'"
		db !TEXT_DECREMENT_ACT_PUZZLE
		db 0

	..cower
		;  "012345678901234567890123"
		db "You sympathize with the%"
		db "troubles Ganon has with%"
		db "his collection."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon shyly suggests you%"
		db "might be able to help."
		db !TEXT_INCREMENT_ACT_PUZZLE
		db 0

	..silvers
		db "You almost ask where the%"
		db "silver arrows are, but%"
		db "manage to stop yourself."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&If Ganon knew, he would%"
		db "be able to complete his%"
		db "collection himself."
		db 0

	..reserved
		db ""

.s15
	..trivia
		db "You explain that this%"
		db "fight uses BG Mode 0 to%"
		db "make use of 4 layers."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon is annoyed by your%"
		db "breaking of the fourth%"
		db "wall."
		db !TEXT_DECREMENT_ACT_PUZZLE
		db 0

	..cower
		db "You shake your body at a%"
		db "frequency of 160hz."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon says to drop the%"
		db "act and give him what he%"
		db "wants."
		db !TEXT_DECREMENT_ACT_PUZZLE
		db !TEXT_DECREMENT_ACT_PUZZLE
		db 0

	..silvers
	..silversYES
		db "You give Ganon your only%"
		db "set of silver arrows."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon cries tears of joy%"
		db "as he blows you a kiss."
		db !TEXT_ACT_COMPLETE
		db 0

	..silversNO
	
		db "You reach into your left%"
		db "pocket.%"
		db !TEXT_WAIT_FOR_KEY
		db "&Nothing but lint."
		db !TEXT_WAIT_FOR_KEY
		db !TEXT_CLEAR
		db "&Ganon will not forgive%"
		db "you for this."
		db !TEXT_RESET_ACT_PUZZLE_FOR_REAL
		db 0

	..reserved
		db ""


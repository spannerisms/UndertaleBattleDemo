macro enemy_name_text_pointer()
?tempA:
.name
	pushpc
	org Name_text_pointers+(4*!ENEMY_ID)
		dd ?tempA
	pullpc
endmacro

macro enemy_act_text_pointer()
?tempB:
.actmenu
	pushpc
	org Act_text_pointers+(4*!ENEMY_ID)
		dd ?tempB
	pullpc
endmacro

macro enemy_check_text_pointer()
?tempC:
.checkoptions
	pushpc
	org Check_text_pointers+(4*!ENEMY_ID)
		dd ?tempC
	pullpc
endmacro

macro enemy_intro_text_pointer()
?tempD:
.introtext
	pushpc
	org Intro_text_pointers+(4*!ENEMY_ID)
		dd ?tempD
	pullpc
endmacro

macro enemy_text_routine()
?tempDE:
	pushpc
	org Random_text_pointers+(4*!ENEMY_ID)
		dd ?tempDE
	pullpc
endmacro


HideBG2Box:
	PHP
	SEP #$20
	LDA #$02
	TRB.b DP.MAINDES_C
	TRB.b DP.SUBDES_C
	PLP
	RTS

ShowBG1Health:
	PHP
	SEP #$20
	LDA #$01
	TSB.b DP.MAINDES_D
	TSB.b DP.SUBDES_D
	PLP
	RTS

ShowBG1Menu:
	PHP
	SEP #$20
	LDA #$01
	TSB.b DP.MAINDES_E
	TSB.b DP.SUBDES_E
	PLP
	RTS

HideBG1Menu:
	PHP
	SEP #$20
	LDA #$01
	TRB.b DP.MAINDES_D
	TRB.b DP.SUBDES_D
	PLP
	RTS

DisplayText:
	PHP
	REP #$30
	STZ.b DP.BG2VOFS
	BRA ShowBG2Box_in

DisplayAttack:
	PHP
	REP #$30
	LDA.w #$FF98
	STA.b DP.BG2VOFS
	BRA ShowBG2Box_in

ShowBG2Box:
	PHP
.in
	SEP #$20
	LDA #$02
	TSB.b DP.MAINDES_C
	TSB.b DP.SUBDES_C
	PLP
	RTS

BattleText_DeleteAll:
	JSR BattleText_EmptyBuffer

BattleText_EmptyText:
	PHX
	PHP

	SEP #$30
	LDX.b #4*(!MESSAGE_QUEUE_SIZE-1)
	LDA.b #$FF

.next
	STA.b DP.Message.Status, X
	DEX
	DEX
	DEX
	DEX
	BPL .next

	PLP
	PLX
	RTS



BattleText_DeleteKText:
	PHX
	PHY
	PHP

	SEP #$30
	LDA.b #$10
	BRA .start

#BattleText_DeleteShortText:
	PHX
	PHY
	PHP

	SEP #$30
	LDA.b #$20

.start
	LDX.b #4*(!MESSAGE_QUEUE_SIZE-1)
	LDY.b #$FF
.next
	BIT.b DP.Message.Status, X
	BEQ .notshort
	STY.b DP.Message.Status, X

.notshort
	DEX
	DEX
	DEX
	DEX
	BPL .next

	PLP
	PLY
	PLX
	RTS

BattleText_DeleteShortNonKMessages:
	PHX
	PHY
	PHP

	SEP #$30
	LDX.b #4*(!MESSAGE_QUEUE_SIZE-1)
	LDY.b #$FF
.next
	LDA.b DP.Message.Status, X
	BIT.b #$20
	BEQ .notshort
	BIT.b #$10
	BNE .keep

	STY.b DP.Message.Status, X

.keep
.notshort
	DEX
	DEX
	DEX
	DEX
	BPL .next

	PLP
	PLY
	PLX
	RTS

BattleText_EmptyBuffer:
	PHP
	REP #$30
	PHA
	PHX
	LDA.w #$0080
	LDX.w #(8*32*2)-2

.next
	STA.l WRAM.TextBuffer, X
	DEX
	DEX
	BPL .next

	PLX
	PLA
	PLP
#SafeRTS:
	RTS

;==============================================================================
; Scratch+2 = bit to check to continue
;   sk.. ....
;   s - only check small messages
;   k - only check k messages
; Scratch+3 = bitmask
; Scratch+4 = bit to add in
; Scratch+5 = bit to toggle (0 for none)
;==============================================================================
BattleText_HideUndeletedKMessages:
	PEA $40BF ; only check k messages, remove bit 6
	PEA $4000 ; add in bit 6, no toggles
	BRA BattleText_HandleUndeletedMessageFlags

BattleText_UnhideUndeletedKMessages:
	PEA $40BF ; only check k messages, remove bit 6
	PEA $0000 ; dont add in or toggle
	BRA BattleText_HandleUndeletedMessageFlags

BattleText_ToggleHideUndeletedMessages:
	PEA $00BF ; no checks, remove bit 6
	PEA $0040 ; nothing to add, toggle bit 6
	BRA BattleText_HandleUndeletedMessageFlags

BattleText_UnhideUndeletedMessages:
	PEA $00BF ; no checks, remove bit 6
	PEA $0000 ; don't add in or toggle anything
	BRA BattleText_HandleUndeletedMessageFlags

BattleText_HideUndeletedMessages:
	PEA $00BF ; no checks, remove bit 6
	PEA $4000 ; add in bit 6, no toggles
	BRA BattleText_HandleUndeletedMessageFlags

BattleText_HandleUndeletedMessageFlags:
	PHP
	SEP #$30
	PLX

	; pulled in this order so the PEAs are readable
	PLA
	STA.b DP.Scratch+5
	PLA
	STA.b DP.Scratch+4
	PLA
	STA.b DP.Scratch+3
	PLA
	STA.b DP.Scratch+2

	PHX
	LDX.b #$00 ; message looked at

.nextmessage
	LDA.b DP.Message.Status, X
	BMI .skipmessage ; negative means message is deleted

	BIT.b DP.Scratch+2
	BPL .ignoresize

	BIT.b #$20 ; not a small message, so skip
	BEQ .skipmessage

.ignoresize
	BVC .ignorekness ; BIT #i doesn't affect V flag, so it's fine
	BIT.b #$10
	BEQ .skipmessage

.ignorekness
	AND.b DP.Scratch+3 ; remove
	ORA.b DP.Scratch+4 ; add
	EOR.b DP.Scratch+5 ; toggle
	STA.b DP.Message.Status, X


.skipmessage
	INX
	INX
	INX
	INX
	CPX.b #4*!MESSAGE_QUEUE_SIZE
	BCC .nextmessage

	PLP
	RTS

;==============================================================================
; 0,0 is relative to the first black tile inside the box
; assumes a full sized box
;
; FF AAAAAA
; FF Messages flags:
; ndsk ?ppp
;  n - consider message deleted
;  d - whether or not to display the message
;  s - whether the message takes up half a row or a full row
;  k - special hideable message flag
;  p - position ID of text
;
; AAAAAA address of message
;==============================================================================
BattleText_WriteText:
	STZ.b DP.FastText
	BRA .continue

.menu
	STZ.b DP.FastText
	INC.b DP.FastText
	BRA .continue

.continue
	PHP
	PHB
	PHK
	PLB

	JSR BattleText_EmptyBuffer
	JSR BattleText_GarbageCollection

	SEP #$30
	LDA.b #$01
	STA.b DP.NMI_TextUpdate
	JSR WaitForNMI_ButAnimateSprites
	JSR DisplayText

	STZ.b DP.Message.X

	LDA #$FF
	STA.b DP.Message.NextPos

.nextmessage
	LDA.b DP.Message.X
	CMP.b #!MESSAGE_QUEUE_SIZE
	BCC ..fine
	JMP .done

..fine
	ASL
	ASL
	TAY
	TAX
	STA.b DP.SaferScratch+0 ; location of message in buffer

	; check position and size of message
	LDA.b DP.Message.Status, X
	BIT #$C0
	BEQ ..writemessageyesmaybe
	JMP .skipmessage

..writemessageyesmaybe
	BIT #$30 ; see if small message or k message for indentation
	PHP ; remember this
	BIT #$20 ; see if small message for newlines
	PHP
	LDA.b DP.Message.NextPos
	PLP
	BNE ..shortlines

..notshortlines
	LDA.b DP.Message.NextPos
	LSR A ; big message, so remove low bit
	SEC ; set carry so we're always on second column
	ROL A ; this makes the INC always be next row

..shortlines
	INC A

	STA.b DP.Message.NextPos

	; remember position in message properties
	AND.b #$07
	CMP.b #6 ; 6 messages max
	BCS .toomanymessages
	ORA.b DP.Message.Status, X
	STA.b DP.Message.Status, X

	LDA.b DP.Message.NextPos
	ASL
	TAX

	REP #$20

	LDA.l .text_positions, X

	PLP ; get back whether it was an indented message in Z
	REP #$21

	BEQ ..noindent

..indented2
	ADC #$0002

..noindent
..writeaddress
	STA.b DP.SaferScratch+2 ; save for reference when doing new rows
	DEC ; -2 for location of asterisk
	DEC
	LDX.b #$01
	STX.b DP.NMI_TextUpdate
	LDX.b #WRAM.TextBuffer>>16
	STA.b DP.GameJML+0
	STX.b DP.GameJML+2

	LDA.w #('*'+$80)|($1000)
	STA.b [DP.GameJML]
	INC.b DP.GameJML
	INC.b DP.GameJML

	TYX
	LDA.b DP.Message.Pointer+0, X
	STA.b DP.Message.Read+0
	LDX.b DP.Message.Pointer+2, Y
	STX.b DP.Message.Read+2

#NextText:
..nextcharacter
	REP #$20
	LDA.b [DP.Message.Read]
	INC.b DP.Message.Read

	AND.w #$00FF
	BEQ .donemessage
	CMP #$0080
	BCS ..command

	ADC.w #$0080
	ORA.w #$3000
#NextTextPreWriteChar:
	STA.b [DP.GameJML]
	INC.b DP.GameJML
	INC.b DP.GameJML
	SEP #$20
	LDA.b #$01
	STA.b DP.NMI_TextUpdate

	LDA.b DP.FastText
	BNE ..nowait

	JSR WaitForNMI_ButAnimateSprites
	BIT.b DP.Controller.new.B ; X for fast text
	BVC ..nowait

	INC.b DP.FastText
..nowait
	BRA ..nextcharacter

..command
	SBC #$0080
	ASL
	TAX
	JMP (TextCommands, X)
	BRA ..nextcharacter

.donemessage
.skipmessage
	SEP #$30
	INC.b DP.Message.X
	JMP .nextmessage

.toomanymessages
	PLP

.done
	PLB
	PLP
	; wait an extra frame
	JSR WaitForNMI_ButAnimateSprites
	RTL

; basically, row, column, indent
function text_rc(row, col) = WRAM.TextBuffer+(64*row)+(2*col)

.text_positions
	dw text_rc(1,4), text_rc(1, 17)
	dw text_rc(3,4), text_rc(3, 17)
	dw text_rc(5,4), text_rc(5, 17)

TextCommands:
	fillword NextText
	fill 20*2

!COMMAND = 0
macro add_text_command(n)
	!TEXT_<n> #= !COMMAND+$80
.<n>
	pushpc
	org TextCommands+(2*!COMMAND)
	dw .<n>
	pullpc
	!COMMAND #= !COMMAND+1
endmacro

%add_text_command("NEWLINE")
	CLC
	LDA.b DP.SaferScratch+2
	ADC.w #64
	STA.b DP.GameJML
	STA.b DP.SaferScratch+2
	JMP NextText

%add_text_command("STAR")
	SEC
	LDA.b DP.GameJML
	SBC.w #2
	STA.b DP.GameJML

	LDA.w #('*'+$80)|($1000)
	JMP NextTextPreWriteChar

%add_text_command("WAIT_FOR_KEY")
	SEP #$30
	JSR WaitForNMI_ButAnimateSprites

--	JSR WaitForNMI_ButAnimateSprites
	BIT.b DP.Controller.new.B
	BPL --

	JMP NextText

%add_text_command("CLEAR")
	JSR BattleText_EmptyBuffer

	LDA.w #text_rc(1,4)
	STA.b DP.GameJML
	STA.b DP.SaferScratch+2

	JSR WaitForNMI_ButAnimateSprites

	;LDA.w #('*'+$80)|($1000)
	JMP NextText;PreWriteChar

	; TODO just hardcode it to use ganon's counter atm
%add_text_command("INCREMENT_ACT_PUZZLE")
	INC.b DP.Enemy.ActLevel
	JMP NextText

%add_text_command("DECREMENT_ACT_PUZZLE")
	;DEC.b DP.Enemy.ActLevel
	JMP NextText

%add_text_command("RESET_ACT_PUZZLE")
	;STZ.b DP.Enemy.ActLevel
	JMP NextText

%add_text_command("RESET_ACT_PUZZLE_FOR_REAL")
	STZ.b DP.Enemy.ActLevel
	JMP NextText

%add_text_command("DELETE_SELF_NOW")
	PHP
	SEP #$30
	LDX.b DP.SaferScratch
	LDA.b #$FF
	STA.b DP.Message.Status, X
	PLP
	JMP NextText

%add_text_command("ACT_COMPLETE")
	PHP
	SEP #$30
	INC.b DP.Befriended
	PLP
	JMP NextText

;==============================================================================
; Removes unused messages and puts things in order
;==============================================================================
BattleText_GarbageCollection:
	PHP
	SEP #$30

	LDY.b #$00 ; number of messages we have
	LDX.b #$00 ; message looked at

.nextmessage
	BIT.b DP.Message.Status, X
	BMI .skipmessage ; negative means message is deleted

	INY ; 1 more messsage to add
	REP #$20

	; save to stack
	LDA.b DP.Message.Status+2, X
	PHA

	LDA.b DP.Message.Status+0, X
	AND.w #$FFFF ; clear position property
	PHA

	; delete message
	LDA.w #$FFFF
	STA.b DP.Message.Status+0, X
	STA.b DP.Message.Status+2, X

	SEP #$20

.skipmessage
	INX
	INX
	INX
	INX
	CPX.b #4*!MESSAGE_QUEUE_SIZE
	BCC .nextmessage

	; get number of messages to add
	; putting things in backwards
	TYA
	BEQ .nomessages
	DEC A
	ASL
	ASL
	TAX

	REP #$20
.addnext
	PLA ; get status and low byte
	STA.b DP.Message.Status+0, X
	PLA ; get rest of address
	STA.b DP.Message.Status+2, X

	DEX
	DEX
	DEX
	DEX
	DEY
	BNE .addnext

.nomessages
	PLP
	RTS

;==============================================================================
; Expects sets of 4 bytes in stack
; Address
; Message flags
; order: flmh
; the first 4 bytes pulled off are the number of messages to add
;==============================================================================
BattleText_AddMessages:
	PHP
	STX.b DP.Scratch+4 ; save X
	STY.b DP.Scratch+8 ; save Y

	JSR BattleText_GarbageCollection

	; save our return address to somewhere safe
	SEP #$10
	REP #$20
	PLX
	STX.b DP.Scratch+2 ; save processor

	PLA ; get address
	PLX ; get bank
	STA.b DP.Scratch+6
	STX.b DP.Scratch+3

	PLX ; now get the number of messages to add
	TXA
	ASL ; 4 bytes each
	ASL
	STA.b DP.Scratch+10 ; number of messages * 4, aka size of stack params
	TSC
	ADC.b DP.Scratch+10 ; carry will be clear from ASL
	STA.b DP.Scratch+12 ; save stack's new location

	PHB ; save data bank
	LDY #$00
	PHY
	PLB ; bank 00 since we're using stack

	REP #$11
	ADC.w #-3 ; so we can look at stack top
	TAY ; location of first item in stack, but the flag of the message

	STX.b DP.Scratch+10 ; X still holds number of messages

	; count upwards for new messages
	LDX.w #-4

.nextslot
	INX
	INX
	INX
	INX

	LDA.b DP.Message.Status-1, X ; -1 so status in high byte
	BMI .foundspace

.findnext
	CPX.w #!MESSAGE_QUEUE_SIZE*4
	BCC .nextslot

	; recover return address, remove stack params, and exit
.finishup
	REP #$20
	PLB ; recover data bank
	LDA.b DP.Scratch+12
	TCS ; get stack with everything removed
	PEI.b (DP.Scratch+2) ; push return address bank and processor to stack
	PLP ; get old processor back
	LDX.b DP.Scratch+4 ; recover X
	LDY.b DP.Scratch+8 ; recover Y
	PEI.b (DP.Scratch+6) ; push return address to stack
	RTL

.foundspace
	LDA.w $0002, Y ; second item in stack param
	; checked first because we may need to skip the message
	BNE .validmessage
	DEX
	DEX
	DEX
	DEX
	BRA .nextmessage

.validmessage
	STA.b DP.Message.Status+2, X

	LDA.w $0000, Y ; second item of stack param
	STA.b DP.Message.Status+0, X

.nextmessage
	DEC.b DP.Scratch+10
	BEQ .finishup

	DEY
	DEY
	DEY
	DEY
	BRA .findnext

;==============================================================================
; 
;==============================================================================
; TODO not robust enough to find then ignore dead enemies
BattleText_FindMenuMessages:
	PHP
	; first, find all the unhidden messages and their positions
	SEP #$30
	LDY #$00
	LDX #$00
.nextmessage
	BIT.b DP.Message.Status, X
	BMI .skip
	BVS .skip

	LDA.b DP.Message.Status, X
	AND.b #$03
	STA.w DP.Message.Locs, Y
	INY

.skip
	INX
	INX
	INX
	INX
	CPX.b #4*!MESSAGE_QUEUE_SIZE
	BCC .nextmessage

	; add terminator
	LDA.b #$FF
	STA.w DP.Message.Locs, Y
	STY.b DP.Message.Locs.max
	STZ.b DP.Menu.Pos.Text
	PLP
	RTS

BattleText_HandlePlayerCursor:
.enemyselect
	PHP
	SEP #$30
	LDA #$02
	BRA .continue

.shortselect
	PHP
	SEP #$30
	LDA #$00

.continue
	STA.b DP.Message.Scrolling

	LDA #$00
	STA.b DP.Soul.Mode

.loop
	LDX.b DP.Menu.Pos.Text
	LDA.b DP.Message.Locs, X ; get message location

	LDY.b #24 ; if even position
	LSR A ; check bottom bit of position for parity
	BCC ++ ; even position
	LDY.b #128 ; if odd position

++	STY.b DP.Soul.X
	ASL ; multiply by 16
	ASL
	ASL
	ASL
	ADC.b #111
	STA.b DP.Soul.Y

	JSR WaitForNMI_ButAnimateSprites

	STZ.b DP.Menu.Choice
	LDY.b DP.Menu.Pos.Text
	LDX.b DP.Message.Scrolling
	LDA.b DP.Controller.new.A

	JMP.w (..movementtype, X)

..movementtype
	dw .short
	dw .enemy

.short
	LSR
	BCS .pressedrightS
	LSR
	BCS .pressedleftS
	LSR
	BCS .presseddownS
	LSR
	BCS .pressedupS
	BRA .handleAB

.presseddownS
	INY
.presseddownE
.pressedrightS
.pressedrightE
	INY
	CPY.b DP.Message.Locs.max
	BCC .savenewposition
	JMP .loop

.pressedupS
	DEY
.pressedleftS
.pressedupE
.pressedleftE
	DEY
	BPL .savenewposition
	JMP .loop

.enemy
	LSR
	BCS .pressedrightE
	LSR
	BCS .pressedleftE
	LSR
	BCS .presseddownE
	LSR
	BCS .pressedupE
	BRA .handleAB


.savenewposition
	STY.b DP.Menu.Pos.Text
	JMP .loop

.handleAB
	BIT.b DP.Controller.new.A
	BPL .noBpress

	LDA.b #$40
.didBpress
	STA.b DP.Menu.Choice
	JSR WaitForNMI_ButAnimateSprites
	PLP
	RTS

.noBpress
	BIT.b DP.Controller.new.B
	BMI .didApress
	JMP .loop

.didApress
	LDA #$80
	BRA .didBpress

;==============================================================================
; 
;==============================================================================
Battle_Die:
	LDA.b #$10
	STA.b DP.MAINDES_A
	STA.b DP.MAINDES_B
	STA.b DP.MAINDES_C
	STA.b DP.MAINDES_D
	STA.b DP.MAINDES_E

	LDA.b #$00
	STA.b DP.Soul.Mode
	STA.b DP.iFrames
	JSL ChangeSoulColor

	LDX.b #40
--	JSR WaitForNMI_ButAnimateSoul
	DEX
	BNE --


	LDA.b #$80
	STA.b DP.Soul.Mode

	LDX.b #80

--	JSR AnimateDeadSoul
	JSR WaitForNMI
	DEX
	BNE --

	LDA.b #$02
	STA.b DP.Module
	LDA.b #$01
	STA.b DP.Submodule
	RTS

AnimateDeadSoul:
	LDA.b DP.Soul.X
	DEC
	STA.b DP.OAM.d.x

	LDA.b DP.Soul.Y
	STA.b DP.OAM.d.y

	LDA.b #$02
	STA.b DP.OAM.d.t

	LDA.b #$30
	STA.b DP.OAM.d.p
	STZ.b DP.OAM.d.s

	JSL AddOAM

	CLC
	LDA.b DP.OAM.d.x
	ADC.b #$6
	STA.b DP.OAM.d.x

	INC.b DP.OAM.d.t
	JSL AddOAM

	RTS

Battle_Victory:
	LDA.b #$80
	STA.b DP.Soul.Mode
	JSR BattleText_EmptyText

	PHK
	PEA.w .text
	PEA.w $0001

	JSL BattleText_AddMessages ; add message
	JSL BattleText_WriteText

	SEP #$30
.loop
	JSR WaitForNMI_ButAnimateSprites
	BIT.b DP.Controller.new.B
	BPL .loop

	LDA.b #$02
	STA.b DP.Module
	STZ.b DP.Submodule
	RTS

.text
	db "YOU WON!%"
	db "&You earned 100 XP and%"
	db "&0 gold."
	db 0

;==============================================================================
; 
;==============================================================================
GetEnemyList:
	JSR BattleText_HideUndeletedMessages ; hide the flavor texts

	SEP #$30
	LDY #$00
	LDX #$FF
	STX.b DP.Scratch+2

	; find live enemies
.nextslot
	INC.b DP.Scratch+2
	LDX.b DP.Scratch+2
	CPX.b #3
	BCS .addmessages

	LDA.b DP.Enemy, X
	BEQ .nextslot

	INY
	REP #$30
	AND #$00FF
	ASL
	ASL
	TAX

	LDA.l Name_text_pointers+1, X
	PHA ; push bank and high byte
	LDA.l Name_text_pointers+0, X

	SEP #$30
	PHA ; push low byte of pointer
	LDA #$10
	PHA ; message type K
	BRA .nextslot

.addmessages
	PHY
	JSL BattleText_AddMessages ; add all messages
	SEP #$30
	STZ.b DP.Menu.Pos.Text
	JSL BattleText_WriteText_menu
.exit
	RTS

#GetEnemySelection:
.nogood
	SEP #$30
	JSR BattleText_FindMenuMessages
	JSR BattleText_HandlePlayerCursor_enemyselect
	BIT.b DP.Menu.Choice
	BMI .exit
	BVS .exit
	BRA .nogood

DrawEnemyHP_all:
	PHP
	SEP #$30
	LDX.b #$00
.next
	LDA.b DP.Enemy, X
	BEQ .skip
	JSR DrawEnemyHP
.skip
	INX
	CPX.b #3
	BCC .next
	PLP
	RTS

DrawEnemyHP:
	PHX
	PHP
	SEP #$30
	LDA.b DP.Enemy.HP, X ; get HP
	STA.w CPUMULTA
	LDA.b #40 ; multiply by 40
	STA.w CPUMULTB
	LDY.b DP.Enemy.HP.MAX, X ; 4 cycles
	REP #$20 ; 3 cycles
	LDA.w CPUPRODUCT ; get HP*40

	STA.w CPUDIVIDEND ; divide this number by
	STY.w CPUDIVISOR ; the max HP
	REP #$10 ; 3 cycles
	TXA ; 2 cycles
	ASL ; 2 cycles
	TAX ; 2 cycles
	LDA.w .positions, X ; 5 cycles
	TAX ; 2 cycles, and we have plenty for the math now
	SEP #$20
	LDA #$01
	STA.b DP.NMI_BoxUpdate
	TYA
	LSR
	LDY.w CPUQUOTIENT
	CMP.w CPUREMAINDER
	BCS .noround
	INY
.noround
	CPY.w #40
	BCC .nottoofar
	LDY.w #40
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

	LDA.w #5
	SBC.b DP.Scratch+0
	STA.b DP.Scratch+4

	LDA.w #$2CF8
	LDY.b DP.Scratch+0
	BEQ ++
--	STA.w WRAM.BoxBuffer, X
	INX
	INX
	DEY
	BNE --

++	LDA.b DP.Scratch+2
	BEQ ++
	ORA.w #$2CF0
	STA.w WRAM.BoxBuffer, X
	INX
	INX

++	LDA.w #$2CF0
	LDY.b DP.Scratch+4
	BEQ ++
--	STA.w WRAM.BoxBuffer, X
	INX
	INX
	DEY
	BNE --

++	PLP
	PLX
	RTS


.positions
	dw (1*64)+40
	dw (3*64)+40
	dw (5*64)+40

;==============================================================================
; 
;==============================================================================
Name_text_pointers:
	filldword 0 : fill 4*!ENEMY_MAX

Act_text_pointers:
	filldword 0 : fill 4*!ENEMY_MAX

Check_text_pointers:
	filldword 0 : fill 4*!ENEMY_MAX

Intro_text_pointers:
	filldword 0 : fill 4*!ENEMY_MAX

Random_text_pointers:
	filldword 0 : fill 4*!ENEMY_MAX

Item_text_pointers:
	dw .noitems
	dw .red
	dw .green
	dw .blue
	dw .fairy
	dw .bee

.noitems
	db "No items!", 0

.red
	db "R Potion", 0

.green
	db "G Potion", 0

.blue
	db "B Potion", 0

.fairy
	db "Fairy", 0

.bee
	db "Bee", 0

;==============================================================================
; Item Menu
Battle_PlayerItem:
.init
	LDA #$80
	STA.b DP.Soul.Mode

	JSR BattleText_HideUndeletedMessages ; hide the flavor texts

	SEP #$30
	; clean up unused bottles and junk
	LDY.b #$00
	LDX.b #$00

..nextbottle
	LDA.b DP.Items, X
	BEQ ..nobottlehere
	STZ.b DP.Items, X

	PHA
	INY

..nobottlehere
	INX
	CPX.b #4
	BCC ..nextbottle

	TYA
	BEQ ..donereorg

	LDX.b #$00
..nextaddbottle
	PLA
	STA.b DP.Items, X
	INX
	DEY
	BNE ..nextaddbottle


..donereorg
	LDY #$00
	LDX #$FF
	STX.b DP.Scratch+2

	; find items
..nextslot
	INC.b DP.Scratch+2
	LDX.b DP.Scratch+2
	CPX #4
	BCS ..addmessages

	LDA.b DP.Items, X
	BEQ ..nextslot

	INY
	ASL
	TAX

	PHK

	LDA.l Item_text_pointers+1, X
	PHA
	LDA.l Item_text_pointers+0, X
	PHA

	LDA #$20
	PHA

	BRA ..nextslot

..addmessages
	TYA ; are we at 0 items?
	BNE ..nonzero
	INY

	PHK
	PEA.w Item_text_pointers_noitems 
	LDA #$20
	PHA

..nonzero
	PHY
	JSL BattleText_AddMessages

	SEP #$30
	STZ.b DP.Menu.Pos.Text
	JSL BattleText_WriteText_menu
	JSR BattleText_AddPage
	JSR BattleText_FindMenuMessages

.selectingitem
	JSR BattleText_HandlePlayerCursor_shortselect
	BIT.b DP.Menu.Choice
	BVS .return
	BMI .useitem
	BRA .selectingitem

.noitems
	PLA
	PLA

.return
	JSR BattleText_DeleteShortText
	JSR BattleText_UnhideUndeletedMessages
	LDA.b #$01
	STA.b DP.Submodule
	RTS

.useitem
	SEP #$30
	JSR BattleText_DeleteShortText

	SEP #$30
	LDA #$80
	STA.b DP.Soul.Mode

	LDX.b DP.Menu.Pos.Text
	LDA.b DP.Items, X
	STZ.b DP.Items, X
	ASL
	TAX

	JSR (.actions, X)

.itemused
	; returns with 16 bit A holding a message
	PHK
	PHA
	SEP #$20
	LDA.b DP.Menu.Pos.Action
	JSR Battle_MenuSwapSelectColor

	PEA.w $0001 ; 1 normal message
	JSL BattleText_AddMessages

	SEP #$30
	JSL BattleText_WriteText

	SEP #$30
..loop
	JSR WaitForNMI_ButAnimateSprites
	BIT.b DP.Controller.new.B
	BPL ..loop

	LDA.b #$06
	STA.b DP.Submodule
	RTS

.actions
	dw .noitems
	dw .red
	dw .green
	dw .blue
	dw .fairy
	dw .bee

.heal
	CLC
	ADC.b DP.HP
	CMP.b DP.HP.MAX
	BCC ..hpfine

	LDA.b DP.HP.MAX

..hpfine
	STA.b DP.HP
	RTS


.red
	LDA.b DP.HP.MAX
	LSR
	JSR .heal

	REP #$20
	LDA.w #..message
	RTS

..message
	;  "012345678901234567890123"
	db "You drink the R Potion.%"
	db "&You recover half HP."
	db 0

.green
	LDA.b DP.HP.MAX
	LSR
	LSR
	JSR .heal

	REP #$20
	LDA.w #..message
	RTS

..message
	;  "012345678901234567890123"
	db "You drink the G Potion.%"
	db "&You recover 1/4 HP."
	db 0

.blue
	LDA.b DP.HP.MAX
	LSR
	LSR
	STA.b DP.Scratch+2
	SEC
	LDA.b DP.HP.MAX
	SBC.b DP.Scratch+2
	JSR .heal

	REP #$20
	LDA.w #..message
	RTS

..message
	;  "012345678901234567890123"
	db "You drink the B Potion.%"
	db "&You recover 3/4 HP."
	db 0

.fairy
	LDA.b DP.HP.MAX
	JSR .heal

	REP #$20
	LDA.w #..message
	RTS

..message
	db "You eat the fairy.%"
	db "&What is your problem?"
	db !TEXT_WAIT_FOR_KEY
	db !TEXT_CLEAR
	db "&I mean like...%"
	db "&SERIOUSLY?"
	db !TEXT_WAIT_FOR_KEY
	db !TEXT_CLEAR
	db "&You could have just%"
	db "asked her to heal you."
	db !TEXT_WAIT_FOR_KEY
	db !TEXT_CLEAR
	db "&But no!%"
	db !TEXT_WAIT_FOR_KEY
	db "&YOU FREAKING ATE AN%"
	db "INTELLIGENT BEING!%"
	db !TEXT_WAIT_FOR_KEY
	db "&You are DISGUSTING."
	db !TEXT_WAIT_FOR_KEY
	db !TEXT_CLEAR
	db "&Anyways...%"
	db !TEXT_WAIT_FOR_KEY
	db "&Your HP was maxed out."
	db 0

.bee
	REP #$20
	LDA.w #..message
	RTS

..message
	;  "012345678901234567890123"
	db "You release the bee.%"
	db "&BZZZZZZZZZZZZZZZZZZZ"
	db 0

BattleText_AddPage:
	PHX
	PHP
	REP #$20
	SEP #$10
	LDX.b #10

--	LDA.l .text, X
	ORA.w #$1080
	STA.l text_rc(6,18), X
	DEX
	DEX
	BPL --

	LDX.b #$01
	STX.b DP.NMI_TextUpdate
	PLP
	PLX
	RTS

.text
	dw "PAGE 1"
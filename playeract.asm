;==============================================================================
; Act menu
;==============================================================================
Battle_PlayerAct:
.initact
	LDA #$80
	STA.b DP.Soul.Mode
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
	LDA.b DP.Menu.Pos.Text
	STA.b DP.SelectedEnemy
	STZ.b DP.Menu.Pos.Text
	JSR BattleText_HideUndeletedKMessages
	REP #$20

	PHK
	PEA CheckText ; add check text first
	LDY #$20 ; small messages
	PHY
	STY.b DP.Scratch+2 ; so it can be pushed easily

	LDX.b DP.Menu.Pos.Text
	LDA.b DP.Enemy, X
	REP #$30
	AND.w #$00FF
	ASL
	ASL
	TAX

	LDA.l Act_text_pointers+0, X
	STA.b DP.Scratch+3
	LDA.l Act_text_pointers+2, X
	STA.b DP.Scratch+5

	SEP #$10
	LDX #$01 ; X holds number of messages

	; need a separate check for first character
	; because we use $XX00 to find messages
.firstcharcheck
	LDA.b [DP.Scratch+3]
	BNE .addmessagehere ; if we have a non zero character, we have a message

.endofmessages
	SEP #$30
	PHX ; save number of messages
	JSL BattleText_AddMessages ; add all messages
	JSL BattleText_WriteText_menu
	JSR BattleText_FindMenuMessages
..nogood
	JSR BattleText_HandlePlayerCursor_shortselect
	BIT.b DP.Menu.Choice
	BMI .madeactchoice
	BVS .enemyselect
	BRA ..nogood

.nextchar
	LDA.b [DP.Scratch+3]
	BEQ .endofmessages ; double 0s means no more messages
	CMP.w #$0100 ; 0 with a character following it means new message

	INC.b DP.Scratch+3 ; however, we need to increment to the next address now
	BCS .nextchar
	INC.b DP.Scratch+3

	LDA.b [DP.Scratch+3]
	BEQ .endofmessages

.addmessagehere
	INX
	PEI.b (DP.Scratch+4) ; push bank and middle byte
	PEI.b (DP.Scratch+2) ; push low byte of location and properties
	BRA .nextchar

.enemyselect
	JSR BattleText_UnhideUndeletedKMessages
	JSR BattleText_DeleteShortNonKMessages
	SEP #$30
	STZ.b DP.Menu.Pos.Text
	JSL BattleText_WriteText_menu
	JMP .selectanenemy

.madeactchoice
	SEP #$30
	LDA.b DP.Menu.Pos.Action
	JSR Battle_MenuSwapSelectColor
	LDX.b DP.SelectedEnemy

	REP #$30
	LDA.b DP.Enemy, X
	AND #$00FF
	ASL
	ASL
	TAX

	LDA.b DP.Menu.Pos.Text
	AND #$00FF
	BEQ .docheck

	LDA.l Check_routine_pointers+0, X
	STA.b DP.Scratch+0
	LDA.l Check_routine_pointers+2, X
	STA.b DP.Scratch+2

	PHB

	SEP #$30
	PHK
	PLB
	PHP
	JSL .runcheck
	PLP
	PLB

	LDA.b DP.Scratch+2
	PHA
	PEI.b (DP.Scratch+0)
	BRA .domessage

.runcheck
	JML.w [DP.Scratch+0]

.docheck
	LDA.l Check_text_pointers+1, X
	PHA
	LDA.l Check_text_pointers+0, X

	SEP #$30
	PHA

.domessage
	LDA #$00 ; message type
	PHA
	INC A ; 1 message
	PHA

	LDA.b #$80
	STA.b DP.Soul.Mode
	JSR BattleText_EmptyText
	JSL BattleText_AddMessages ; add message
	JSL BattleText_WriteText

	SEP #$30
..loop
	JSR WaitForNMI_ButAnimateSprites
	BIT.b DP.Controller.new.B
	BPL ..loop

	LDA.b #$06
	STA.b DP.Submodule
	RTS

CheckText:
	db "Check"
	db 0
	db 0

macro enemy_check_routine()
?tempAAA:
	pushpc
	org Check_routine_pointers+(4*!ENEMY_ID)
		dd ?tempAAA
	pullpc
endmacro

macro enemy_attack_routine()
?tempBBB:
	pushpc
	org Attack_routine_pointers+(4*!ENEMY_ID)
		dd ?tempBBB
	pullpc
endmacro
macro enemy_draw_routine()
?tempCCC:
	pushpc
	org Draw_routine_pointers+(4*!ENEMY_ID)
		dd ?tempCCC
	pullpc
endmacro

Check_routine_pointers:
	filldword 0 : fill 4*!ENEMY_MAX

Attack_routine_pointers:
	filldword 0 : fill 4*!ENEMY_MAX

Draw_routine_pointers:
	filldword 0 : fill 4*!ENEMY_MAX

;==============================================================================
; Mercy menu
;==============================================================================
Battle_PlayerMercy:
.init
	LDA #$80
	STA.b DP.Soul.Mode

	JSR BattleText_HideUndeletedMessages ; hide the flavor texts

	SEP #$30
	PHK
	PEA.w .spare
	PEA.w $3001
	JSL BattleText_AddMessages

	SEP #$30
	STZ.b DP.Menu.Pos.Text
	JSL BattleText_WriteText_menu
	JSR BattleText_FindMenuMessages

.selecting
	JSR BattleText_HandlePlayerCursor_shortselect
	BIT.b DP.Menu.Choice
	BVS .return
	BMI .sparing
	BRA .selecting

.return
	JSR BattleText_DeleteShortText
	JSR BattleText_UnhideUndeletedMessages
	LDA.b #$01
	STA.b DP.Submodule
	RTS

.sparing
	LDA #$80
	STA.b DP.Soul.Mode

	LDA.b DP.Menu.Pos.Action
	JSR Battle_MenuSwapSelectColor

	LDX.b DP.Befriended
	LDA.l .submod, X
	STA.b DP.Submodule

	RTS

.submod
	db 6, 8

.spare
	db "Spare", 0
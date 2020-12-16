arch 65816
lorom
math pri on

; asar.exe --pause-mode=on-warning --fix-checksum=on main.asm UTBattleDemo.sfc

org $808000
incsrc "defines.asm"
incsrc "rammap.asm"
incsrc "registers.asm"
incsrc "header.asm"

reset bytes
org $808000
incsrc "bank00.asm"
incsrc "commandeer.asm"
incsrc "battle.asm"
incsrc "battletext.asm"
incsrc "battlefight.asm"
incsrc "playeract.asm"
incsrc "enemy.asm"
incsrc "enemyattacks.asm"

;incsrc "header.asm"

print "Code: ", bytes

org $818000
BattleHUD:
incbin "battle.2bpp"

BattleFont:
incbin "font.2bpp"
incbin "font2.2bpp"

SpritesGFX:
incbin "sprites.4bpp"
incbin "sprites2.4bpp"
incbin "ganonattacks.4bpp"

GanonGFX:
incbin "ganonsprite1.4bpp"
incbin "ganonsprite2.4bpp"

AttackGFX:
incbin "ganonattacksBG.2bpp"

print "All:  ", bytes

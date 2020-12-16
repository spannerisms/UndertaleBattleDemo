pushtable
cleartable
; Internal ROM header
org $00FFB0 ; ROM registration
db "SP"
db "UTDM"
db $00, $00, $00, $00, $00, $00
db $00 ; flash size
db $00 ; expansion RAM size
db $00 ; special version
db $00 ; special chip

org $00FFC0 ; ROM specifications
db "Undertale Battle Demo"

db $31 ; rom map
db $02 ; rom type, rom, ram, sram
db $06 ; rom size
db $00 ; sram size
db $01 ; ntsc
db $33 ; use $FFB0 for header
db $01 ; version
dw #$FFFF ; checksum
dw #$0000 ; inverse checksum

; native mode
dw $FFFF, $FFFF ; unused
dw Vector_COP
dw Vector_BRK
dw Vector_Abort
dw Vector_NMI
dw Vector_Reset
dw Vector_IRQ ; IRQ

; emulation mode
dw $FFFF, $FFFF ; unused
dw Vector_COP
dw Vector_Unused
dw Vector_Abort
dw Vector_NMI
dw Vector_Reset
dw Vector_IRQ ; IRQ/BRK
pulltable

!END_OF_LIST = $FFFF

!BG_1_BOX_OFFSET = 13*$40
!BG_1_MENU_OFFSET = 23*$40

; >>9 for tilemap
!BG_1_MAP = $2000
!BG_2_MAP = $2800
!BG_3_MAP = $3000
!BG_4_MAP = $3800

!BG_1_CHRS = $0000
!BG_2_CHRS = $0000
!BG12NBA_BATTLE = $00

!BG_3_CHRS = $4000
!BG_4_CHRS = $4000
!BG34NBA_BATTLE = $22

!BG_3_BOX_TL = $3340
!BG_4_BOX_TL = $3B40

!OAM_CHARS = $8000
!OAM_CHARS2 = $A000

!ATTACK_SLOTS = 30

COLOR_BLIND = $7EFF00 ; TODO
SILVERS = $7EFFE0
;==============================================================================
; Macros and functions
;==============================================================================
function VRAMaddr(a) = a>>1

function hexto555(h) = ((((h&$FF)/8)<<10)|(((h>>8&$FF)/8)<<5)|(((h>>16&$FF)/8)<<0))

function rgbto555(r,g,b) =  ((((b&$FF)/8)<<10)|(((g&$FF)/8)<<5)|(((r&$FF)/8)<<0))

function bg12chars(bg1,bg2) = (bg1>>13)|(bg2>>9)

macro col4(h1,h2,h3,h4)
	dw hexto555(<h1>)
	dw hexto555(<h2>)
	dw hexto555(<h3>)
	dw hexto555(<h4>)
endmacro

macro col8(h1,h2,h3,h4,h5,h6,h7,h8)
	dw hexto555(<h1>)
	dw hexto555(<h2>)
	dw hexto555(<h3>)
	dw hexto555(<h4>)
	dw hexto555(<h5>)
	dw hexto555(<h6>)
	dw hexto555(<h7>)
	dw hexto555(<h8>)
endmacro

!ENEMY_ID = 0
!ENEMY_MAX = 3
macro next_enemy()
	!ENEMY_ID #= !ENEMY_ID+1
endmacro

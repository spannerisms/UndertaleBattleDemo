!DIRECT_PAGE_LOCATION = $1100
!MESSAGE_QUEUE_SIZE = 10

struct DP $800000+!DIRECT_PAGE_LOCATION
	skip 4 ; just for safety

	.Undertale: skip 2

	.Scratch: skip 16
	.SaferScratch: skip 5
	.NMIScratch: skip 4

	.GameJML: skip 3
	.GameJML2: skip 3

	.Frame: skip 2
	.Spinning: skip 1

	.Befriended: skip 1
	.Module: skip 1
	.Submodule: skip 1

	.HP: skip 1
	.HP.MAX: skip 1
	.iFrames: skip 1

	.Enemy: skip 3
	.Enemy.ActLevel: skip 3
	.Enemy.MessageAI: skip 3
	.Enemy.HP: skip 3
	.Enemy.HP.MAX: skip 3

	.BoxW: skip 1
	.BoxT: skip 1
	.BoxXmin: skip 1
	.BoxXmax: skip 1

	.DamageD: skip 1
	.DamageZ: skip 1
	.DamageT: skip 1
	.DamageC: skip 1
	.DoneAttacks: skip 1

	.Soul.X: skip 1
	.Soul.Y: skip 1
	.Soul.Mode: skip 1
	; 0 = menu
	; 1 = text menu
	; 2 = battle
	.Soul.Box.Y: skip 1
	.Soul.Box.X: skip 1
	.Soul.Barflash:
	.Soul.Box.Direction: skip 1
	; 0 = down - so that it's default
	; 1 = up
	; 2 = right
	; 3 = left
	.Soul.Color: skip 2
	.Soul.Color.normal: skip 2
	.Soul.Color.hurt: skip 2

	.Menu.Pos.Action: skip 1
	.Menu.Pos.Text: skip 1
	.SelectedEnemy: skip 1
	.Menu.Choice: skip 1 ; pressed: bit7 = A, bit6 = B

	.NMI_MenuUpdate: skip 1
	.NMI_BoxUpdate: skip 1
	.NMI_TextUpdate: skip 1
	.NMI_AttackBGUpdate: skip 1

	.Items: skip 4

	.Message.Read: skip 3
	.Message.Read2: skip 2
	.Message.NextPos: skip 1
	.FastText: skip 1 ; keep these together
	.Message.X: skip 1

	.Message.Scrolling: skip 1
	.Message.Locs: skip !MESSAGE_QUEUE_SIZE+1
	.Message.Locs.max: skip 1

	.Message.Status: skip 1
	.Message.Pointer: skip 3
	skip 4*!MESSAGE_QUEUE_SIZE


	; controller A: BYsSUDLR
	; controller B: AXlr
	.Controller:
	.Controller.B: skip 1
	.Controller.A: skip 1

	.Controller.prev:
	.Controller.prev.B: skip 1
	.Controller.prev.A: skip 1

	.Controller.new:
	.Controller.new.B: skip 1
	.Controller.new.A: skip 1

	.OAM.drawn: skip 1
	.OAM.i:
	.OAM.h: skip 1
	.OAM.l: skip 1
	.OAM.p: skip 1 ; if bit 0 is off, high priority

	.OAM.d:
	.OAM.d.x: skip 1
	.OAM.d.y: skip 1
	.OAM.d.t: skip 1
	.OAM.d.p: skip 1
	.OAM.d.s: skip 1

	.INTERRUPTS: skip 1
	.INIDISP: skip 1
	.OBSEL: skip 1
	.BGMODE: skip 1
	.MOSAIC: skip 1
	.BG1SC: skip 1
	.BG2SC: skip 1
	.BG3SC: skip 1
	.BG4SC: skip 1
	.BG12NBA: skip 1
	.BG34NBA: skip 1
	.BG1HOFS: skip 2
	.BG1VOFS: skip 2
	.BG2HOFS: skip 2
	.BG2VOFS: skip 2
	.BG3HOFS: skip 2
	.BG3VOFS: skip 2
	.BG4HOFS: skip 2
	.BG4VOFS: skip 2
	.W12SEL: skip 1
	.W34SEL: skip 1
	.WOBJSEL: skip 1
	.WINDOW1L: skip 1
	.WINDOW1R: skip 1
	.WINDOW2L: skip 1
	.WINDOW2R: skip 1
	.WBGLOG: skip 1
	.WOBJLOG: skip 1
	.MAINDES: skip 1
	.SUBDES: skip 1
	.TMW: skip 1
	.TSW: skip 1
	.CGWSEL: skip 1
	.CGADSUB: skip 1
	.COLDATA.R: skip 1
	.COLDATA.G: skip 1
	.COLDATA.B: skip 1
	.APUIO: skip 1
	.APUIO0: skip 1
	.APUIO1: skip 1
	.APUIO2: skip 1
	.APUIO3: skip 1
	.HDMA: skip 1

	.BGENABLE_A:
	.MAINDES_A: skip 1
	.SUBDES_A: skip 1

	.BGENABLE_B:
	.MAINDES_B: skip 1
	.SUBDES_B: skip 1

	.BGENABLE_C:
	.MAINDES_C: skip 1
	.SUBDES_C: skip 1

	.BGENABLE_D:
	.MAINDES_D: skip 1
	.SUBDES_D: skip 1

	.BGENABLE_E:
	.MAINDES_E: skip 1
	.SUBDES_E: skip 1

endstruct

struct OAM $7E0800
	.OAM_buffer:
	.OAM.hi: skip $200
	.OAM.lo: skip $20
endstruct

struct WRAM $7E0000+!DIRECT_PAGE_LOCATION+$100
	.BoxBuffer: skip 8*32*2
	.MenuBuffer: skip 3*32*2
	.TextBuffer: skip 8*32*2

	.HPBUFFER: skip 12+2+10

	skip 3
	.RNGseedA: skip 2
	.RNGseedX: skip 2
	.RNGseedY: skip 2

	.DamageDigitsDebug: skip 1
	.DamageDigitsCount: skip 1
	.DamageDigits: skip 10

	.DecDigitsCount: skip 1
	.DecDigits: skip 10

	.Attacks.Dur: skip 6
	.Attacks.Phase: skip 6
	.Attacks.Bonus: skip 6
	.Attacks.Pointers: skip 12

	.Attacks.ID: skip !ATTACK_SLOTS
	.Attacks.X: skip !ATTACK_SLOTS
	.Attacks.Y: skip !ATTACK_SLOTS
	.Attacks.W:
	.Attacks.T: skip !ATTACK_SLOTS
	.Attacks.H:
	.Attacks.D: skip !ATTACK_SLOTS
	.Attacks.A: skip !ATTACK_SLOTS
	.Attacks.B: skip !ATTACK_SLOTS

	skip 20
	.HDMACache: skip $20

	print "WRAM END: ", pc
endstruct

struct WRAM2 $7F0000
	.BG3buffer: skip $800
	.BG4buffer: skip $800
endstruct

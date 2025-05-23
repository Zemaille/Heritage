DEF PRINTPARTY_HP EQU "◀" ; $71

PrintPage1:
	hlcoord 0, 0
	decoord 0, 0, wPrinterTilemapBuffer
	ld bc, 17 * SCREEN_WIDTH
	rst CopyBytes
	hlcoord 17, 1, wPrinterTilemapBuffer
	ld a, $62
	ld [hli], a
	inc a ; $63
	ld [hl], a
	hlcoord 17, 2, wPrinterTilemapBuffer
	ld a, $64
	ld [hli], a
	inc a ; $65
	ld [hl], a
	hlcoord 1, 9, wPrinterTilemapBuffer
	ld a, " "
	ld [hli], a
	ld [hl], a
	hlcoord 1, 10, wPrinterTilemapBuffer
	ld a, $61
	ld [hli], a
	ld [hl], a
	hlcoord 2, 11, wPrinterTilemapBuffer
	lb bc, 5, 18
	call ClearBox
	ld a, [wTempSpecies]
	call CheckCaughtMon
	push af
	ld a, [wTempSpecies]
	ld b, a
	ld c, 1 ; get page 1
	farcall GetDexEntryPagePointer
	pop af
	ld a, b
	hlcoord 1, 11, wPrinterTilemapBuffer
	call nz, PlaceFarString
	hlcoord 19, 0, wPrinterTilemapBuffer
	ld [hl], $35
	ld de, SCREEN_WIDTH
	add hl, de
	ld b, $f
.column_loop
	ld [hl], $37
	add hl, de
	dec b
	jr nz, .column_loop
	ld [hl], $3a
	ret

PrintPage2:
	hlcoord 0, 0, wPrinterTilemapBuffer
	ld bc, 8 * SCREEN_WIDTH
	ld a, " "
	rst ByteFill
	hlcoord 0, 0, wPrinterTilemapBuffer
	ld a, $36
	ld b, 6
	call .FillColumn
	hlcoord 19, 0, wPrinterTilemapBuffer
	ld a, $37
	ld b, 6
	call .FillColumn
	hlcoord 0, 6, wPrinterTilemapBuffer
	ld a, $38
	ld [hli], a
	ld a, $39
	ld bc, SCREEN_HEIGHT
	rst ByteFill
	ld [hl], $3a
	hlcoord 0, 7, wPrinterTilemapBuffer
	ld bc, SCREEN_WIDTH
	ld a, $32
	rst ByteFill
	ld a, [wTempSpecies]
	call CheckCaughtMon
	push af
	ld a, [wTempSpecies]
	ld b, a
	ld c, 2 ; get page 2
	farcall GetDexEntryPagePointer
	pop af
	hlcoord 1, 1, wPrinterTilemapBuffer
	ld a, b
	jmp nz, PlaceFarString
	ret

.FillColumn:
	push de
	ld de, SCREEN_WIDTH
.column_loop
	ld [hl], a
	add hl, de
	dec b
	jr nz, .column_loop
	pop de
	ret

GBPrinterStrings: ; used only for BANK(GBPrinterStrings)
GBPrinterString_Null: db "@"
GBPrinterString_CheckingLink: next " CHECKING LINK...@"
GBPrinterString_Transmitting: next "  TRANSMITTING...@"
GBPrinterString_Printing: next "    PRINTING...@"
GBPrinterString_PrinterError1:
	db   " Printer Error 1"
	next ""
	next "Check the Game Boy"
	next "Printer Manual."
	db   "@"
GBPrinterString_PrinterError2:
	db   " Printer Error 2"
	next ""
	next "Check the Game Boy"
	next "Printer Manual."
	db   "@"
GBPrinterString_PrinterError3:
	db   " Printer Error 3"
	next ""
	next "Check the Game Boy"
	next "Printer Manual."
	db   "@"
GBPrinterString_PrinterError4:
	db   " Printer Error 4"
	next ""
	next "Check the Game Boy"
	next "Printer Manual."
	db   "@"

PrintPartyMonPage1:
	call ClearBGPalettes
	call ClearTilemap
	call ClearSprites
	xor a
	ldh [hBGMapMode], a
	call LoadFontsBattleExtra

	ld de, GBPrinterHPIcon
	ld hl, vTiles2 tile PRINTPARTY_HP
	lb bc, BANK(GBPrinterHPIcon), 1
	call Request1bpp

	ld de, GBPrinterLvIcon
	ld hl, vTiles2 tile "<LV>"
	lb bc, BANK(GBPrinterLvIcon), 1
	call Request1bpp

	ld de, StatsScreenPageTilesGFX + 14 tiles ; shiny icon
	ld hl, vTiles2 tile "⁂"
	lb bc, BANK(StatsScreenPageTilesGFX), 1
	call Get2bpp

	xor a
	ld [wMonType], a
	farcall CopyMonToTempMon
	hlcoord 0, 7
	lb bc, 9, 18
	call Textbox
	hlcoord 8, 2
	ld a, [wTempMonLevel]
	call PrintLevel_Force3Digits
	hlcoord 12, 2
	ld a, PRINTPARTY_HP
	ld [hli], a
	ld de, wTempMonMaxHP
	lb bc, 2, 3
	call PrintNum
	ld a, [wCurPartySpecies]
	ld [wNamedObjectIndex], a
	ld [wCurSpecies], a
	ld hl, wPartyMonNicknames
	call GetCurPartyMonName
	hlcoord 8, 4
	rst PlaceString
	hlcoord 9, 6
	ld [hl], "/"
	call GetPokemonName
	hlcoord 10, 6
	rst PlaceString
	hlcoord 8, 0
	ld a, "№"
	ld [hli], a
	ld a, "."
	ld [hli], a
	ld de, wNamedObjectIndex
	lb bc, PRINTNUM_LEADINGZEROS | 1, 3
	call PrintNum
	hlcoord 1, 9
	ld de, PrintParty_OTString
	rst PlaceString
	ld hl, wPartyMonOTs
	call GetCurPartyMonName
	hlcoord 4, 9
	rst PlaceString
	hlcoord 1, 11
	ld de, PrintParty_IDNoString
	rst PlaceString
	hlcoord 4, 11
	ld de, wTempMonID
	lb bc, PRINTNUM_LEADINGZEROS | 2, 5
	call PrintNum
	hlcoord 1, 14
	ld de, PrintParty_MoveString
	rst PlaceString
	hlcoord 7, 14
	ld a, [wTempMonMoves + 0]
	call PlaceMoveNameString
	call PlaceGenderAndShininess
	ld hl, wTempMonDVs
	predef GetUnownLetter
	ld hl, wBoxAlignment
	xor a
	ld [hl], a
	ld a, [wCurPartySpecies]
	push hl
	call GetPokemonIndexFromID
	ld a, l
	sub LOW(UNOWN)
	if HIGH(UNOWN) == 0
		or h
		pop hl
	else
		ld a, h
		pop hl
		jr nz, .not_unown
		if HIGH(UNOWN) == 1
			dec a
		else
			cp HIGH(UNOWN)
		endc
	endc
	jr z, .got_alignment
.not_unown
	inc [hl]
.got_alignment
	hlcoord 0, 0
	call _PrepMonFrontpic
	call WaitBGMap
	ld b, SCGB_STATS_SCREEN_HP_PALS
	call GetSGBLayout
	jmp SetDefaultBGPAndOBP

PrintPartyMonPage2:
	call ClearBGPalettes
	call ClearTilemap
	call ClearSprites
	xor a
	ldh [hBGMapMode], a
	call LoadFontsBattleExtra
	xor a
	ld [wMonType], a
	farcall CopyMonToTempMon
	hlcoord 0, 0
	lb bc, 15, 18
	call Textbox
	ld bc, SCREEN_WIDTH
	decoord 0, 0
	hlcoord 0, 1
	rst CopyBytes
	hlcoord 7, 0
	ld a, [wTempMonMoves + 1]
	call PlaceMoveNameString
	hlcoord 7, 2
	ld a, [wTempMonMoves + 2]
	call PlaceMoveNameString
	hlcoord 7, 4
	ld a, [wTempMonMoves + 3]
	call PlaceMoveNameString
	hlcoord 7, 7
	ld de, PrintParty_StatsString
	rst PlaceString
	hlcoord 16, 7
	ld de, wTempMonAttack
	call .PrintTempMonStats
	hlcoord 16, 9
	ld de, wTempMonDefense
	call .PrintTempMonStats
	hlcoord 16, 11
	ld de, wTempMonSpclAtk
	call .PrintTempMonStats
	hlcoord 16, 13
	ld de, wTempMonSpclDef
	call .PrintTempMonStats
	hlcoord 16, 15
	ld de, wTempMonSpeed
	call .PrintTempMonStats
	call WaitBGMap
	ld b, SCGB_STATS_SCREEN_HP_PALS
	call GetSGBLayout
	jmp SetDefaultBGPAndOBP

.PrintTempMonStats:
	lb bc, 2, 3
	jmp PrintNum

GetCurPartyMonName:
	ld bc, NAME_LENGTH
	ld a, [wCurPartyMon]
	rst AddNTimes
	ld e, l
	ld d, h
	ret

PlaceMoveNameString:
	and a
	jr z, .no_move

	ld [wNamedObjectIndex], a
	call GetMoveName
	jr .got_string

.no_move
	ld de, PrintParty_NoMoveString

.got_string
	jmp PlaceString

PlaceGenderAndShininess:
	farcall GetGender
	ld a, " "
	jr c, .got_gender
	ld a, "♂"
	jr nz, .got_gender
	ld a, "♀"

.got_gender
	hlcoord 17, 2
	ld [hl], a
	ld bc, wTempMonDVs
	farcall CheckShininess
	ret nc
	hlcoord 18, 2
	ld [hl], "⁂"
	ret

PrintParty_OTString:
	db "OT/@"

PrintParty_MoveString:
	db "MOVE@"

PrintParty_IDNoString:
	db "<ID>№.@"

PrintParty_StatsString:
	db   "ATTACK"
	next "DEFENSE"
	next "SPCL.ATK"
	next "SPCL.DEF"
	next "SPEED"
	db   "@"

PrintParty_NoMoveString:
	db "------------@"

GBPrinterHPIcon:
INCBIN "gfx/printer/hp.1bpp"

GBPrinterLvIcon:
INCBIN "gfx/printer/lv.1bpp"

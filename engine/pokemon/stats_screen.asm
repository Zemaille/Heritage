	const_def
	const PINK_PAGE   ; 0
	const GREEN_PAGE  ; 1
	const BLUE_PAGE   ; 2
	const ORANGE_PAGE ; 3
DEF NUM_STAT_PAGES EQU const_value

DEF STAT_PAGE_MASK EQU %00000011
	const_def 4
	const STATS_SCREEN_PLACE_FRONTPIC ; 4
	const STATS_SCREEN_ANIMATE_MON    ; 5
	const STATS_SCREEN_ANIMATE_EGG    ; 6

StatsScreenInit:
	ld hl, StatsScreenMain
	ldh a, [hMapAnims]
	push af
	xor a
	ldh [hMapAnims], a ; disable overworld tile animations
	ld a, [wBoxAlignment] ; whether sprite is to be mirrorred
	push af
	ld a, [wJumptableIndex]
	ld b, a
	ld a, [wStatsScreenFlags]
	ld c, a

	push bc
	push hl
	call ClearBGPalettes
	call ClearTilemap
	call UpdateSprites
	farcall StatsScreen_LoadFont
	pop hl
	call _hl_
	call ClearBGPalettes
	call ClearTilemap
	pop bc

	; restore old values
	ld a, b
	ld [wJumptableIndex], a
	ld a, c
	ld [wStatsScreenFlags], a
	pop af
	ld [wBoxAlignment], a
	pop af
	ldh [hMapAnims], a
	ret

StatsScreenMain:
	xor a
	ld [wJumptableIndex], a
	ld [wStatsScreenFlags], a ;Pink Page
	
.loop
	ld a, [wJumptableIndex]
	and ~(1 << 7)
	ld hl, StatsScreenPointerTable
	call JumpTable
	call StatsScreen_WaitAnim
	ld a, [wJumptableIndex]
	bit JUMPTABLE_EXIT_F, a
	jr z, .loop
	ret

StatsScreenPointerTable:
	dw MonStatsInit       ; regular pokémon
	dw EggStatsInit       ; egg
	dw StatsScreenWaitCry
	dw EggStatsJoypad
	dw StatsScreen_LoadPage
	dw StatsScreenWaitCry
	dw MonStatsJoypad
	dw StatsScreen_Exit

StatsScreen_WaitAnim:
	ld hl, wStatsScreenFlags
	bit STATS_SCREEN_ANIMATE_EGG, [hl]
	jr nz, .try_anim
	bit STATS_SCREEN_ANIMATE_MON, [hl]
	jr nz, .finish
	jmp DelayFrame

.try_anim
	farcall SetUpPokeAnim
	jr nc, .finish
	ld hl, wStatsScreenFlags
	res STATS_SCREEN_ANIMATE_EGG, [hl]
.finish
	ld hl, wStatsScreenFlags
	res STATS_SCREEN_ANIMATE_MON, [hl]
	farjp HDMATransferTilemapToWRAMBank3

StatsScreen_SetJumptableIndex:
	ld a, [wJumptableIndex]
	and JUMPTABLE_EXIT
	or h
	ld [wJumptableIndex], a
	ret

StatsScreen_Exit:
	ld hl, wJumptableIndex
	set JUMPTABLE_EXIT_F, [hl]
	ret

MonStatsInit:
	ld hl, wStatsScreenFlags
	res STATS_SCREEN_ANIMATE_EGG, [hl]
	call ClearBGPalettes
	call ClearTilemap
	farcall HDMATransferTilemapToWRAMBank3
	call StatsScreen_CopyToTempMon
	ld a, [wCurPartySpecies]
	cp EGG
	jr z, .egg
	call StatsScreen_InitUpperHalf
	ld hl, wStatsScreenFlags
	set STATS_SCREEN_PLACE_FRONTPIC, [hl]
	ld h, 4
	jr StatsScreen_SetJumptableIndex

.egg
	ld h, 1
	jr StatsScreen_SetJumptableIndex

EggStatsInit:
	call EggStatsScreen
	ld hl, wJumptableIndex
	inc [hl]
	ret

EggStatsJoypad:
	call StatsScreen_GetJoypad
	bit A_BUTTON_F, a
	jr nz, .quit
if DEF(_DEBUG)
	cp START
	jr z, .hatch
endc
	and D_DOWN | D_UP | A_BUTTON | B_BUTTON
if DEF(_DEBUG)
	jmp StatsScreen_JoypadAction
else
	jr StatsScreen_JoypadAction ; no-optimize Stub jump
endc

.quit
	ld h, 7
	jr StatsScreen_SetJumptableIndex

if DEF(_DEBUG)
.hatch
	ld a, [wMonType]
	or a
	jr nz, .skip
	push bc
	push de
	push hl
	ld a, [wCurPartyMon]
	ld bc, PARTYMON_STRUCT_LENGTH
	ld hl, wPartyMon1Happiness
	rst AddNTimes
	ld a, 1 ; no-optimize *hl = N
	ld [hl], a
	ld [wTempMonHappiness], a
	ld a, 127
	ld [wStepCount], a
	ld de, .HatchSoonString
	hlcoord 8, 17
	rst PlaceString
	ld hl, wStatsScreenFlags
	set STATS_SCREEN_ANIMATE_MON, [hl]
	pop hl
	pop de
	pop bc
.skip
	xor a
if DEF(_DEBUG)
	jr StatsScreen_JoypadAction
else
	jmp StatsScreen_JoypadAction
endc

.HatchSoonString:
	db "▶HATCH SOON!@"
endc

StatsScreen_LoadPage:
	call StatsScreen_LoadGFX
	ld hl, wStatsScreenFlags
	res STATS_SCREEN_PLACE_FRONTPIC, [hl]
	ld hl, wJumptableIndex
	inc [hl]
	ret

MonStatsJoypad:
	call StatsScreen_GetJoypad
	jr nc, .next
	ld h, 0
if DEF(_DEBUG)
	jmp StatsScreen_SetJumptableIndex
else
	jr StatsScreen_SetJumptableIndex ; no-optimize Stub jump
endc

.next
	and D_DOWN | D_UP | D_LEFT | D_RIGHT | A_BUTTON | B_BUTTON
	jr StatsScreen_JoypadAction

StatsScreenWaitCry:
	call IsSFXPlaying
	ret nc
	ld hl, wJumptableIndex
	inc [hl]
	ret

StatsScreen_CopyToTempMon:
	ld a, [wMonType]
	cp BUFFERMON
	jr nz, .not_tempmon
	ld a, [wBufferMonSpecies]
	ld [wCurSpecies], a
	call GetBaseData
	ld hl, wBufferMon
	ld de, wTempMon
	ld bc, PARTYMON_STRUCT_LENGTH
	rst CopyBytes
	jr .done

.not_tempmon
	farcall CopyMonToTempMon
	ld a, [wCurPartySpecies]
	cp EGG
	jr z, .done
	ld a, [wMonType]
	cp BOXMON
	jr c, .done
	farcall CalcTempmonStats
.done
	and a
	ret

StatsScreen_GetJoypad:
	call GetJoypad
	ldh a, [hJoyPressed]
	and a
	ret

StatsScreen_JoypadAction:
	push af
	ld a, [wStatsScreenFlags]
	maskbits NUM_STAT_PAGES
	ld c, a
	pop af
	bit B_BUTTON_F, a
	jmp nz, .b_button
	bit D_LEFT_F, a
	jr nz, .d_left
	bit D_RIGHT_F, a
	jr nz, .d_right
	bit A_BUTTON_F, a
	jr nz, .a_button
	bit D_UP_F, a
	jr nz, .d_up
	bit D_DOWN_F, a
	ret z
	ld a, [wMonType]
	cp BUFFERMON
	jr z, .next_storage
	cp BOXMON
	ret nc
	and a
	ld a, [wPartyCount]
	jr z, .next_mon
	ld a, [wOTPartyCount]
.next_mon
	ld b, a
	ld a, [wCurPartyMon]
	inc a
	cp b
	ret z
	ld [wCurPartyMon], a
	ld b, a
	ld a, [wMonType]
	and a
	jr nz, .load_mon
	ld a, b
	inc a
	ld [wPartyMenuCursor], a
	jr .load_mon

.d_up
	ld a, [wMonType]
	cp BUFFERMON
	jr z, .prev_storage
	ld a, [wCurPartyMon]
	and a
	ret z
	dec a
	ld [wCurPartyMon], a
	ld b, a
	ld a, [wMonType]
	and a
	jr nz, .load_mon
	ld a, b
	inc a
	ld [wPartyMenuCursor], a
	jr .load_mon

.a_button
	ld a, c
	cp ORANGE_PAGE ; last page
	jr z, .b_button
.d_right
	inc c
	ld a, ORANGE_PAGE ; last page
	cp c
	jr nc, .set_page
	ld c, PINK_PAGE ; first page
	jr .set_page

.d_left
	ld a, c
	dec c
	and a ; cp PINK_PAGE ; first page
	jr nz, .set_page
	ld c, ORANGE_PAGE ; last page
	jr .set_page

.prev_storage
	farcall PrevStorageBoxMon
	jr nz, .load_storage_mon
	ret

.set_page
	ld a, [wStatsScreenFlags]
	and ~STAT_PAGE_MASK
	or c
	ld [wStatsScreenFlags], a
	ld h, 4
	jmp StatsScreen_SetJumptableIndex

.next_storage
	farcall NextStorageBoxMon
	ret z
.load_storage_mon
	ld a, [wBufferMonAltSpecies]
	ld [wCurPartySpecies], a
	ld [wCurSpecies], a
.load_mon
	ld h, 0
	jmp StatsScreen_SetJumptableIndex

.b_button
	ld h, 7
	jmp StatsScreen_SetJumptableIndex

StatsScreen_InitUpperHalf:
	call .PlaceHPBar
	xor a
	ldh [hBGMapMode], a
	ld a, [wBaseSpecies]
	ld [wCurSpecies], a
	call GetPokemonIndexFromID
	ld a, h
	ld h, l
	ld l, a
	push hl
	ld hl, sp + 0
	ld d, h
	ld e, l
	hlcoord 8, 0
	ld a, "№"
	ld [hli], a
	ld a, "."
	ld [hli], a
	lb bc, PRINTNUM_LEADINGZEROS | 2, 3
	call PrintNum
	add sp, 2
	hlcoord 14, 0
	call PrintLevel
	ld hl, .NicknamePointers
	call GetNicknamePointer
	call CopyNickname
	hlcoord 8, 2
	rst PlaceString
	hlcoord 18, 0
	call .PlaceGenderChar
	hlcoord 9, 4
	ld a, "/"
	ld [hli], a
	ld a, [wBaseSpecies]
	ld [wNamedObjectIndex], a
	call GetPokemonName
	rst PlaceString
	call StatsScreen_PlaceHorizontalDivider
	call StatsScreen_PlacePageSwitchArrows
	jr StatsScreen_PlaceShinyIcon

.PlaceHPBar:
	ld hl, wTempMonHP
	ld a, [hli]
	ld b, a
	ld c, [hl]
	ld hl, wTempMonMaxHP
	ld a, [hli]
	ld d, a
	ld e, [hl]
	farcall ComputeHPBarPixels
	ld hl, wCurHPPal
	call SetHPPal
	ld b, SCGB_STATS_SCREEN_HP_PALS
	call GetSGBLayout
	jmp DelayFrame

.PlaceGenderChar:
	push hl
	farcall GetGender
	pop hl
	ret c
	ld a, "♂"
	jr nz, .got_gender
	ld a, "♀"
.got_gender
	ld [hl], a
	ret

.NicknamePointers:
	dw wPartyMonNicknames
	dw wOTPartyMonNicknames
	dw wBufferMonNickname ; unused
	dw wBufferMonNickname ; unused
	dw wBufferMonNickname ; unused
	dw wBufferMonNickname

StatsScreen_PlaceVerticalDivider: ; unreferenced
; The Japanese stats screen has a vertical divider.
	hlcoord 7, 0
	ld bc, SCREEN_WIDTH
	ld d, SCREEN_HEIGHT
.loop
	ld [hl], $31 ; vertical divider
	add hl, bc
	dec d
	jr nz, .loop
	ret

StatsScreen_PlaceHorizontalDivider:
	hlcoord 0, 7
	ld b, SCREEN_WIDTH
	ld a, $62 ; horizontal divider (empty HP/exp bar)
.loop
	ld [hli], a
	dec b
	jr nz, .loop
	ret

StatsScreen_PlacePageSwitchArrows:
	hlcoord 10, 6
	ld [hl], "◀"
	hlcoord 19, 6
	ld [hl], "▶"
	ret

StatsScreen_PlaceShinyIcon:
	ld bc, wTempMonDVs
	farcall CheckShininess
	ret nc
	hlcoord 19, 0
	ld [hl], "⁂"
	ret

StatsScreen_LoadGFX:
	ld a, [wBaseSpecies]
	ld [wTempSpecies], a
	ld [wCurSpecies], a
	xor a
	ldh [hBGMapMode], a
	call .ClearBox
	call .PageTilemap
	call .LoadPals
	ld hl, wStatsScreenFlags
	bit STATS_SCREEN_PLACE_FRONTPIC, [hl]
	jmp z, SetDefaultBGPAndOBP
	jmp StatsScreen_PlaceFrontpic

.ClearBox:
	ld a, [wStatsScreenFlags]
	maskbits NUM_STAT_PAGES
	ld c, a
	call StatsScreen_LoadPageIndicators
	hlcoord 0, 8
	lb bc, 10, 20
	jmp ClearBox

.LoadPals:
	ld a, [wStatsScreenFlags]
	maskbits NUM_STAT_PAGES
	ld c, a
	farcall LoadStatsScreenPals
	call DelayFrame
	ld hl, wStatsScreenFlags
	set STATS_SCREEN_ANIMATE_MON, [hl]
	ret

.PageTilemap:
	ld a, [wStatsScreenFlags]
	maskbits NUM_STAT_PAGES
	ld hl, .Jumptable
	jmp JumpTable

.Jumptable:
; entries correspond to *_PAGE constants
	table_width 2
	dw LoadPinkPage
	dw LoadGreenPage
	dw LoadBluePage
	dw LoadOrangePage
	assert_table_length NUM_STAT_PAGES

LoadPinkPage:
	hlcoord 0, 9
	ld b, $0
	predef DrawPlayerHP
	hlcoord 8, 9
	ld [hl], $41 ; right HP/exp bar end cap
	ld de, .Status_Type
	hlcoord 0, 12
	rst PlaceString
	ld a, [wTempMonPokerusStatus]
	ld b, a
	and $f
	jr nz, .HasPokerus
	ld a, b
	and $f0
	jr z, .NotImmuneToPkrs
	hlcoord 8, 8
	ld [hl], "." ; Pokérus immunity dot
.NotImmuneToPkrs:
	ld a, [wMonType]
	cp BOXMON
	jr z, .StatusOK
	hlcoord 6, 13
	push hl
	ld de, wTempMonStatus
	predef PlaceStatusString
	pop hl
	jr nz, .done_status
	jr .StatusOK
.HasPokerus:
	ld de, .PkrsStr
	hlcoord 1, 13
	rst PlaceString
	jr .done_status
.StatusOK:
	ld de, .OK_str
	rst PlaceString
.done_status
	hlcoord 1, 15
	predef PrintMonTypes
	hlcoord 9, 8
	ld de, SCREEN_WIDTH
	ld b, 10
	ld a, $31 ; vertical divider
.vertical_divider
	ld [hl], a
	add hl, de
	dec b
	jr nz, .vertical_divider
	ld de, .ExpPointStr
	hlcoord 10, 9
	rst PlaceString
	hlcoord 17, 14
	call .PrintNextLevel
	hlcoord 13, 10
	lb bc, 3, 7
	ld de, wTempMonExp
	call PrintNum
	call .CalcExpToNextLevel
	hlcoord 13, 13
	lb bc, 3, 7
	ld de, wExpToNextLevel
	call PrintNum
	ld de, .LevelUpStr
	hlcoord 10, 12
	rst PlaceString
	ld de, .ToStr
	hlcoord 14, 14
	rst PlaceString
	hlcoord 11, 16
	ld a, [wTempMonLevel]
	ld b, a
	ld de, wTempMonExp + 2
	predef FillInExpBar
	hlcoord 10, 16
	ld [hl], $40 ; left exp bar end cap
	hlcoord 19, 16
	ld [hl], $41 ; right exp bar end cap
	ret

.PrintNextLevel:
	ld a, [wTempMonLevel]
	push af
	cp MAX_LEVEL
	jr z, .AtMaxLevel
	inc a
	ld [wTempMonLevel], a
.AtMaxLevel:
	call PrintLevel
	pop af
	ld [wTempMonLevel], a
	ret

.CalcExpToNextLevel:
	ld a, [wTempMonLevel]
	cp MAX_LEVEL
	jr z, .AlreadyAtMaxLevel
	inc a
	ld d, a
	farcall CalcExpAtLevel
	ld hl, wTempMonExp + 2
	ldh a, [hQuotient + 3]
	sub [hl]
	dec hl
	ld [wExpToNextLevel + 2], a
	ldh a, [hQuotient + 2]
	sbc [hl]
	dec hl
	ld [wExpToNextLevel + 1], a
	ldh a, [hQuotient + 1]
	sbc [hl]
	ld [wExpToNextLevel], a
	ret

.AlreadyAtMaxLevel:
	ld hl, wExpToNextLevel
	xor a
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ret

.Status_Type:
	db   "STATUS/"
	next "TYPE/@"

.OK_str:
	db "OK @"

.ExpPointStr:
	db "EXP POINTS@"

.LevelUpStr:
	db "LEVEL UP@"

.ToStr:
	db "TO@"

.PkrsStr:
	db "#RUS@"

LoadGreenPage:
	ld de, .Item
	hlcoord 0, 8
	rst PlaceString
	call .GetItemName
	hlcoord 8, 8
	rst PlaceString
	ld de, .Move
	hlcoord 0, 10
	rst PlaceString
	ld hl, wTempMonMoves
	ld de, wListMoves_MoveIndicesBuffer
	ld bc, NUM_MOVES
	rst CopyBytes
	hlcoord 8, 10
	ld a, SCREEN_WIDTH * 2
	ld [wListMovesLineSpacing], a
	predef ListMoves
	hlcoord 12, 11
	ld a, SCREEN_WIDTH * 2
	ld [wListMovesLineSpacing], a
	predef_jump ListMovePP

.GetItemName:
	ld de, .ThreeDashes
	ld a, [wTempMonItem]
	and a
	ret z
	ld [wNamedObjectIndex], a
	jmp GetItemName

.Item:
	db "ITEM@"

.ThreeDashes:
	db "---@"

.Move:
	db "MOVE@"

LoadBluePage:
	call .PlaceOTInfo
	hlcoord 10, 8
	ld de, SCREEN_WIDTH
	ld b, 10
	ld a, $31 ; vertical divider
.vertical_divider
	ld [hl], a
	add hl, de
	dec b
	jr nz, .vertical_divider
	hlcoord 11, 8
	ld bc, 6
	predef_jump PrintTempMonStats

.PlaceOTInfo:
	ld de, IDNoString
	hlcoord 0, 9
	rst PlaceString
	ld de, OTString
	hlcoord 0, 12
	rst PlaceString
	hlcoord 2, 10
	lb bc, PRINTNUM_LEADINGZEROS | 2, 5
	ld de, wTempMonID
	call PrintNum
	ld hl, .OTNamePointers
	call GetNicknamePointer
	call CopyNickname
	farcall CorrectNickErrors
	hlcoord 2, 13
	rst PlaceString
	ld a, [wTempMonCaughtGender]
	and a
	ret z
	cp $7f
	ret z
	and CAUGHT_GENDER_MASK
	ld a, "♂"
	jr z, .got_gender
	ld a, "♀"
.got_gender
	hlcoord 9, 13
	ld [hl], a
	ret

.OTNamePointers:
	dw wPartyMonOTs
	dw wOTPartyMonOTs
	dw wBufferMonOT ; unused
	dw wBufferMonOT ; unused
	dw wBufferMonOT ; unused
	dw wBufferMonOT

LoadOrangePage:
	call StatsScreen_placeCaughtLevel
	call StatsScreen_placeCaughtTime
	call StatsScreen_placeCaughtLocation
	call StatsScreen_PrintDVs
	call StatsScreen_HiddenPower

StatsScreen_HiddenPower:
	ld de, HiddenPowerTypeString
	hlcoord 1, 15
	call PlaceString
	ld de, GetHiddenPowerTypeString

HiddenPowerTypeString:
	db "HIDDEN POWER:@"

GetHiddenPowerTypeString:
	ld hl, wTempMonDVs
	ld a, [hl]
	and %0011
	ld b, a
	; + (Atk & 3) << 2
	ld a, [hli]
	and %0011 << 4
	swap a
	add a
	add a
	or b
	; add the least significant bit of the Speed DV to increment 50% of the time (to reach Fairy type)
	ld b, a
	ld a, [hl]
	swap a
	and %0001
	add b
	; Skip Normal
	inc a
	; Skip Bird
	cp BIRD
	jr c, .done
	inc a
	; Skip unused types
	cp UNUSED_TYPES
	jr c, .done
	add UNUSED_TYPES_END - UNUSED_TYPES
.done
	ld [wNamedObjectIndex], a
	farcall GetTypeName
	ld de, wStringBuffer1
	hlcoord 1, 16
	call PlaceString
	ret

StatsScreen_PrintDVs:
	hlcoord 1, 12
	ld de, .DVstring1
	call PlaceString
	hlcoord 1, 13
	ld de, .DVstring2
	call PlaceString
	; hlcoord 1, 14
	; ld de, .DVstring3
	; call PlaceString

	; we're using wPokedexStatus because why not, nobody using it atm lol
	; ATK DV
	ld a, [wTempMonDVs] ; only get the first byte of the word
	and %11110000 ; most significant nybble of first byte in word-sized wTempMonDVs
	swap a ; so we can print it properly
	ld [wPokedexStatus], a
	ld c, 0
	; calc HP stat contribution
	and 1 ; a still has the ATK DV
	jr z, .atk_not_odd
	ld a, 0
	add 8
	ld b, 0
	ld c, a
	;
.atk_not_odd
	push bc
	ld de, wPokedexStatus
	lb bc, PRINTNUM_LEADINGZEROS | 1, 2 ; bytes, digits
	hlcoord 10, 12
	call PrintNum

	; DEF DV
	ld a, [wTempMonDVs] ; only get the first byte of the word
	and %00001111 ; least significant nybble, don't need to swap the bits of the byte
	ld [wPokedexStatus], a ;DEF
	; calc HP stat contribution
	pop bc
	and 1 ; a still has the DEF DV
	jr z, .def_not_odd
	ld a, c
	add 4
	ld b, 0
	ld c, a
	;
.def_not_odd
	push bc
	ld de, wPokedexStatus
	lb bc, PRINTNUM_LEADINGZEROS | 1, 2 ; bytes, digits
	hlcoord 17, 12
	call PrintNum

	; SPE DV
	ld a, [wTempMonDVs + 1] ; second byte of word
	and %11110000 ; most significant nybble of 2nd byte in word-sized wTempMonDVs
	swap a ; so we can print it properly
	ld [wPokedexStatus], a ;SPEED
	; calc HP stat contribution
	pop bc
	and 1 ; a still has the SPEED DV
	jr z, .speed_not_odd
	ld a, c
	add 2
	ld b, 0
	ld c, a
	;
.speed_not_odd
	push bc
	ld de, wPokedexStatus
	lb bc, PRINTNUM_LEADINGZEROS | 1, 2 ; bytes, digits
	hlcoord 17, 13 ; 1, 5, 9, 13
	call PrintNum

	; SPC DV
	ld a, [wTempMonDVs + 1] ; second byte of word
	and %00001111 ; least significant nybble, don't need to swap the bits of the byte
	ld [wPokedexStatus], a ;SPC
	; calc HP stat contribution
	pop bc
	and 1 ; a still has the DEF DV
	jr z, .spc_not_odd
	ld a, c
	add 1
	ld b, 0
	ld c, a
	;
.spc_not_odd
	push bc
	ld de, wPokedexStatus
	lb bc, PRINTNUM_LEADINGZEROS | 1, 2 ; bytes, digits
	hlcoord 10, 13
	call PrintNum
	; hlcoord 18, 15 ; 1, 4, 7, 10, 13 
	; call PrintNum

	; HP
	; HP DV is determined by the last bit of each of these four DVs
	; odd Attack DV adds 8, Defense adds 4, Speed adds 2, and Special adds 1
	;For example, a Lugia with the DVs 5 Atk, 15 Def, 13 Spe, and 13 Spc will have:
	; 5 Attack = Odd, HP += 8
	; 15 Defense = Odd, HP += 4
	; 13 Speed = Odd, HP += 2
	; 13 Special = Odd, HP += 1
	;resulting in an HP stat of 15
	; THANKS SMOGON
	; going to "and 1" each final value and push a counter to stack to preserve it
	pop bc
	ld a, c
	ld [wPokedexStatus], a
	ld de, wPokedexStatus
	lb bc, PRINTNUM_LEADINGZEROS | 1, 2 ; bytes, digits
	hlcoord 3, 13 ; 1, 4, 7, 10, 13 
	call PrintNum
	ret

.DVstring1:
	db "DVS: ATK    DEF   @"
.DVstring2:	
	; db "ATK    DEF@"
	db "HP   SPC    SPE   @"
; .DVstring3:

StatsScreen_placeCaughtLevel:
	; caught level
	ld a, [wTempMonCaughtLevel]
	and CAUGHT_LEVEL_MASK	
	and a
	jr z, .unknown_level
	cp CAUGHT_EGG_LEVEL ; egg marker value
	jr nz, .print
	ld a, EGG_LEVEL ; egg hatch level

.print
	ld [wTextDecimalByte], a
	hlcoord 12, 9
	ld de, wTextDecimalByte
	lb bc, PRINTNUM_LEFTALIGN | 1, 3
	call PrintNum
	hlcoord 11, 9
	ld [hl], "<LV>"
	ret

.unknown_level
	ld de, .MetUnknownLevelString
	hlcoord 11, 9
	call PlaceString
	ret   
.MetUnknownLevelString:
	db "@"

StatsScreen_placeCaughtTime:
	ld a, [wTempMonCaughtTime]
	and CAUGHT_TIME_MASK
	jr z, .unknown_time
	rlca
	rlca
	dec a
	ld hl, .times
	call GetNthString
	ld d, h
	ld e, l
	call CopyName1
	ld de, wStringBuffer2
	hlcoord 6, 9
	call PlaceString
	ret
.unknown_time
	ld a, 0
	ld hl, .unknown_time_text
	call GetNthString
	ld d, h
	ld e, l
	call CopyName1
	ld de, wStringBuffer2
	hlcoord 6, 9
	call PlaceString
	ret
.times
	db "MORN@"
	db "DAY@"
	db "NITE@"
.unknown_time_text
	db "TRADE@"

StatsScreen_placeCaughtLocation:
	ld de, .MetAtMapString
	hlcoord 1, 9
	call PlaceString
	ld a, [wTempMonCaughtLocation]
	and CAUGHT_LOCATION_MASK
	jr z, .unknown_location
	cp LANDMARK_EVENT
	jr z, .unknown_location
	cp LANDMARK_GIFT
	jr z, .unknown_location
	ld e, a
	farcall GetLandmarkName
	ld de, wStringBuffer1
	hlcoord 2, 10
	call PlaceString
	ret	
.unknown_location:
	ld de, .MetUnknownMapString
	hlcoord 2, 10
	call PlaceString
	ret
.MetAtMapString:
	db "MET: @"
.MetUnknownMapString:
	db "UNKNOWN LOCATION@"

IDNoString:
	db "<ID>№.@"

OTString:
	db "OT/@"

StatsScreen_PlaceFrontpic:
	ld hl, wTempMonDVs
	predef GetUnownLetter
	call StatsScreen_GetAnimationParam
	jr c, .egg
	and a
	jr z, .no_cry
	jr .cry

.egg
	call .AnimateEgg
	jmp SetDefaultBGPAndOBP

.no_cry
	call .AnimateMon
	jmp SetDefaultBGPAndOBP

.cry
	call SetDefaultBGPAndOBP
	call .AnimateMon
	ld a, [wCurPartySpecies]
	jmp PlayMonCry2

.AnimateMon:
	ld hl, wStatsScreenFlags
	set STATS_SCREEN_ANIMATE_MON, [hl]
	ld a, [wCurPartySpecies]
	call GetPokemonIndexFromID
	ld a, l
	cp LOW(UNOWN)
	ld a, h
	hlcoord 0, 0
	jmp nz, PrepMonFrontpic
	if HIGH(UNOWN) == 0
		and a
	elif HIGH(UNOWN) == 1
		dec a
	else
		cp HIGH(UNOWN)
	endc
	jmp nz, PrepMonFrontpic
	xor a
	ld [wBoxAlignment], a
	jmp _PrepMonFrontpic

.AnimateEgg:
	ld a, [wCurPartySpecies]
	push hl
	call GetPokemonIndexFromID
	ld a, l
	cp LOW(UNOWN)
	ld a, h
	pop hl
	jr nz, .not_unown_egg
	if HIGH(UNOWN) == 0
		and a
	elif HIGH(UNOWN) == 1
		dec a
	else
		cp HIGH(UNOWN)
	endc
	jr z, .unownegg
.not_unown_egg
	ld a, TRUE
	ld [wBoxAlignment], a
	jr .get_animation
.unownegg
	xor a
	ld [wBoxAlignment], a
	; fallthrough

.get_animation
	ld a, [wCurPartySpecies]
	call IsAPokemon
	ret c
	call StatsScreen_LoadTextboxSpaceGFX
	ld de, vTiles2 tile $00
	predef GetAnimatedFrontpic
	hlcoord 0, 0
	lb de, $0, ANIM_MON_MENU
	predef LoadMonAnimation
	ld hl, wStatsScreenFlags
	set STATS_SCREEN_ANIMATE_EGG, [hl]
	ret

StatsScreen_GetAnimationParam:
	ld a, [wMonType]
	ld hl, .Jumptable
	jmp JumpTable

.Jumptable:
	dw .PartyMon
	dw .OTPartyMon
	dw .BoxMon ; unused
	dw .Tempmon ; unused
	dw .Wildmon
	dw .Buffermon

.PartyMon:
	ld a, [wCurPartyMon]
	ld hl, wPartyMon1
	ld bc, PARTYMON_STRUCT_LENGTH
	rst AddNTimes
	ld b, h
	ld c, l
	jr .CheckEggFaintedFrzSlp

.OTPartyMon:
	xor a
	ret

.BoxMon:
.Buffermon
.Tempmon:
	ld bc, wTempMonSpecies
; fallthrough
.CheckEggFaintedFrzSlp:
	ld a, [wCurPartySpecies]
	cp EGG
	jr z, .egg
	call CheckFaintedFrzSlp
	jr c, .FaintedFrzSlp
.egg
	xor a
	scf
	ret

.Wildmon:
	ld a, $1
	and a
	ret

.FaintedFrzSlp:
	xor a
	ret

StatsScreen_LoadTextboxSpaceGFX:
	push hl
	push de
	push bc
	push af
	call DelayFrame
	ldh a, [rVBK]
	push af
	ld a, $1
	ldh [rVBK], a
	ld de, TextboxSpaceGFX
	lb bc, BANK(TextboxSpaceGFX), 1
	ld hl, vTiles2 tile " "
	call Get2bpp
	pop af
	ldh [rVBK], a
	jmp PopAFBCDEHL

EggStatsScreen:
	xor a
	ldh [hBGMapMode], a
	ld hl, wCurHPPal
	call SetHPPal
	ld b, SCGB_STATS_SCREEN_HP_PALS
	call GetSGBLayout
	call StatsScreen_PlaceHorizontalDivider
	ld de, EggString
	hlcoord 8, 1
	rst PlaceString
	ld de, IDNoString
	hlcoord 8, 3
	rst PlaceString
	ld de, OTString
	hlcoord 8, 5
	rst PlaceString
	ld de, FiveQMarkString
	hlcoord 11, 3
	rst PlaceString
	ld de, FiveQMarkString
	hlcoord 11, 5
	rst PlaceString
if DEF(_DEBUG)
	ld de, .PushStartString
	hlcoord 8, 17
	rst PlaceString
	jr .placed_push_start

.PushStartString:
	db "▶PUSH START.@"

.placed_push_start
endc
	ld a, [wTempMonHappiness] ; egg status
	ld de, EggSoonString
	cp $6
	jr c, .picked
	ld de, EggCloseString
	cp $b
	jr c, .picked
	ld de, EggMoreTimeString
	cp $29
	jr c, .picked
	ld de, EggALotMoreTimeString
.picked
	hlcoord 1, 9
	rst PlaceString
	ld hl, wStatsScreenFlags
	set STATS_SCREEN_ANIMATE_MON, [hl]
	call SetDefaultBGPAndOBP
	call DelayFrame
	hlcoord 0, 0
	call PrepMonFrontpic
	farcall HDMATransferTilemapToWRAMBank3
	call StatsScreen_AnimateEgg

	ld a, [wTempMonHappiness]
	cp 6
	ret nc
	ld de, SFX_2_BOOPS
	jmp PlaySFX

EggString:
	db "EGG@"

FiveQMarkString:
	db "?????@"

EggSoonString:
	db   "It's making sounds"
	next "inside. It's going"
	next "to hatch soon!@"

EggCloseString:
	db   "It moves around"
	next "inside sometimes."
	next "It must be close"
	next "to hatching.@"

EggMoreTimeString:
	db   "Wonder what's"
	next "inside? It needs"
	next "more time, though.@"

EggALotMoreTimeString:
	db   "This EGG needs a"
	next "lot more time to"
	next "hatch.@"

StatsScreen_AnimateEgg:
	call StatsScreen_GetAnimationParam
	ret nc
	ld a, [wTempMonHappiness]
	ld e, $7
	cp 6
	jr c, .animate
	ld e, $8
	cp 11
	ret nc
.animate
	push de
	ld a, $1
	ld [wBoxAlignment], a
	call StatsScreen_LoadTextboxSpaceGFX
	ld de, vTiles2 tile $00
	predef GetAnimatedFrontpic
	pop de
	hlcoord 0, 0
	ld d, $0
	predef LoadMonAnimation
	ld hl, wStatsScreenFlags
	set STATS_SCREEN_ANIMATE_EGG, [hl]
	ret

StatsScreen_LoadPageIndicators:
	hlcoord 11, 5                ; Pink page coordinate
	ld a, $36 ; first of 4 small square tiles
	call .load_square
	hlcoord 13, 5                ; Green page coordinate
	ld a, $36 ; first of 4 small square tiles
	call .load_square
	hlcoord 15, 5                ; Blue page coordinate
	ld a, $36 ; first of 4 small square tiles
	call .load_square
	hlcoord 17, 5                ; Orange page coordinate
	ld a, $36 ; first of 4 small square tiles
	call .load_square
	ld a, c
	cp GREEN_PAGE
	jr c, .pink_page             ; If < GREEN_PAGE, highlight pink
	jr z, .green_page            ; If = GREEN_PAGE, highlight green
	cp BLUE_PAGE
	jr z, .blue_page             ; If = BLUE_PAGE, highlight blue
	hlcoord 17, 5                ; Otherwise highlight orange
	jr .load_highlight
.pink_page
	hlcoord 11, 5
	jr .load_highlight
.green_page
	hlcoord 13, 5
	jr .load_highlight
.blue_page
	hlcoord 15, 5
.load_highlight
	ld a, $3a                    ; first of 4 large square tiles
.load_square
	push bc
	ld [hli], a
	inc a
	ld [hld], a
	ld bc, SCREEN_WIDTH
	add hl, bc
	inc a
	ld [hli], a
	inc a
	ld [hl], a
	pop bc
	ret
CopyNickname:
	ld de, wStringBuffer1
	ld bc, MON_NAME_LENGTH
	push de
	rst CopyBytes
	pop de
	ret

GetNicknamePointer:
	ld a, [wMonType]
	add a
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [wMonType]
	cp BUFFERMON
	ret z
	ld a, [wCurPartyMon]
	jmp SkipNames

CheckFaintedFrzSlp:
	ld hl, MON_HP
	add hl, bc
	ld a, [hli]
	or [hl]
	jr z, .fainted_frz_slp
	ld hl, MON_STATUS
	add hl, bc
	ld a, [hl]
	and 1 << FRZ | SLP_MASK
	jr nz, .fainted_frz_slp
	and a
	ret

.fainted_frz_slp
	scf
	ret

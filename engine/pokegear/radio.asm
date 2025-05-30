PlayRadioShow:
; If we're already in the radio program proper, we don't need to be here.
	ld a, [wCurRadioLine]
	cp POKE_FLUTE_RADIO
	jr nc, .ok
; If Team Rocket is not occupying the radio tower, we don't need to be here.
	ld a, [wStatusFlags2]
	bit STATUSFLAGS2_ROCKETS_IN_RADIO_TOWER_F, a
	jr z, .ok
; If we're in Kanto, we don't need to be here.
	call IsInJohto
	and a
	jr nz, .ok
; Team Rocket broadcasts on all stations.
	ld a, ROCKET_RADIO
	ld [wCurRadioLine], a
.ok
; Jump to the currently loaded station.  The index to which we need to jump is in wCurRadioLine.
	jumptable RadioJumptable, wCurRadioLine

RadioJumptable:
; entries correspond to constants/radio_constants.asm
	table_width 2
	dw OaksPKMNTalk1     ; $00
	dw PokedexShow1      ; $01
	dw BenMonMusic1      ; $02
	dw LuckyNumberShow1  ; $03
	dw BuenasPassword1   ; $04
	dw PeoplePlaces1     ; $05
	dw FernMonMusic1     ; $06
	dw RocketRadio1      ; $07
	dw PokeFluteRadio    ; $08
	dw UnownRadio        ; $09
	dw EvolutionRadio    ; $0a
	assert_table_length NUM_RADIO_CHANNELS
; OaksPKMNTalk
	dw OaksPKMNTalk2     ; $0b
	dw OaksPKMNTalk3     ; $0c
	dw OaksPKMNTalk4     ; $0d
	dw OaksPKMNTalk5     ; $0e
	dw OaksPKMNTalk6     ; $0f
	dw OaksPKMNTalk7     ; $10
	dw OaksPKMNTalk8     ; $11
	dw OaksPKMNTalk9     ; $12
	dw PokedexShow2      ; $13
	dw PokedexShow3      ; $14
	dw PokedexShow4      ; $15
	dw PokedexShow5      ; $16
; Ben Music
	dw BenMonMusic2      ; $17
	dw BenMonMusic3      ; $18
	dw BenFernMusic4     ; $19
	dw BenFernMusic5     ; $1a
	dw BenFernMusic6     ; $1b
	dw DoNothing         ; $1c BenFernMusic7
	dw FernMonMusic2     ; $1d
; Lucky Number Show
	dw LuckyNumberShow2  ; $1e
	dw LuckyNumberShow3  ; $1f
	dw LuckyNumberShow4  ; $20
	dw LuckyNumberShow5  ; $21
	dw LuckyNumberShow6  ; $22
	dw LuckyNumberShow7  ; $23
	dw LuckyNumberShow8  ; $24
	dw LuckyNumberShow9  ; $25
	dw LuckyNumberShow10 ; $26
	dw LuckyNumberShow11 ; $27
	dw LuckyNumberShow12 ; $28
	dw LuckyNumberShow13 ; $29
	dw LuckyNumberShow14 ; $2a
	dw LuckyNumberShow15 ; $2b
; People & Places
	dw PeoplePlaces2     ; $2c
	dw PeoplePlaces3     ; $2d
	dw PeoplePlaces4     ; $2e
	dw PeoplePlaces5     ; $2f
	dw PeoplePlaces6     ; $30
	dw PeoplePlaces7     ; $31
; Rocket Radio
	dw RocketRadio2      ; $32
	dw RocketRadio3      ; $33
	dw RocketRadio4      ; $34
	dw RocketRadio5      ; $35
	dw RocketRadio6      ; $36
	dw RocketRadio7      ; $37
	dw RocketRadio8      ; $38
	dw RocketRadio9      ; $39
	dw RocketRadio10     ; $3a
; More Pokemon Channel stuff
	dw OaksPKMNTalk10    ; $3b
	dw OaksPKMNTalk11    ; $3c
	dw OaksPKMNTalk12    ; $3d
	dw OaksPKMNTalk13    ; $3e
	dw OaksPKMNTalk14    ; $3f
; Buenas Password
	dw BuenasPassword2   ; $40
	dw BuenasPassword3   ; $41
	dw BuenasPassword4   ; $42
	dw BuenasPassword5   ; $43
	dw BuenasPassword6   ; $44
	dw BuenasPassword7   ; $45
	dw BuenasPassword8   ; $46
	dw BuenasPassword9   ; $47
	dw BuenasPassword10  ; $48
	dw BuenasPassword11  ; $49
	dw BuenasPassword12  ; $4a
	dw BuenasPassword13  ; $4b
	dw BuenasPassword14  ; $4c
	dw BuenasPassword15  ; $4d
	dw BuenasPassword16  ; $4e
	dw BuenasPassword17  ; $4f
	dw BuenasPassword18  ; $50
	dw BuenasPassword19  ; $51
	dw BuenasPassword20  ; $52
	dw BuenasPassword21  ; $53
	dw RadioScroll       ; $54
; More Pokemon Channel stuff
	dw PokedexShow6      ; $55
	dw PokedexShow7      ; $56
	dw PokedexShow8      ; $57
	assert_table_length NUM_RADIO_SEGMENTS

PrintRadioLine:
	ld [wNextRadioLine], a
	ld hl, wRadioText
	ld a, [wNumRadioLinesPrinted]
	cp 2
	jr nc, .print
	inc hl
	ld [hl], TX_START
	inc a
	ld [wNumRadioLinesPrinted], a
	cp 2
	jr nz, .print
	bccoord 1, 16
	call PrintTextboxTextAt
	jr .skip
.print
	call PrintTextboxText
.skip
	ld a, RADIO_SCROLL
	ld [wCurRadioLine], a
	ld a, 100
	ld [wRadioTextDelay], a
	ret

RadioScroll:
	ld hl, wRadioTextDelay
	ld a, [hl]
	and a
	jr z, .proceed
	dec [hl]
	ret
.proceed
	ld a, [wNextRadioLine]
	ld [wCurRadioLine], a
	ld a, [wNumRadioLinesPrinted]
	cp 1
	call nz, CopyBottomLineToTopLine
	jmp ClearBottomLine

OaksPKMNTalk1:
	ld a, 5
	ld [wOaksPKMNTalkSegmentCounter], a
	call StartRadioStation
	ld hl, OPT_IntroText1
	ld a, OAKS_POKEMON_TALK_2
	jmp NextRadioLine

OaksPKMNTalk2:
	ld hl, OPT_IntroText2
	ld a, OAKS_POKEMON_TALK_3
	jmp NextRadioLine

OaksPKMNTalk3:
	ld hl, OPT_IntroText3
	ld a, OAKS_POKEMON_TALK_4
	jmp NextRadioLine

OaksPKMNTalk4:
; Choose a random route, and a random Pokemon from that route.
.sample
	call Random
	and %11111
	cp (OaksPKMNTalkRoutes.End - OaksPKMNTalkRoutes) / 2
	jr nc, .sample
	ld hl, OaksPKMNTalkRoutes
	ld c, a
	ld b, 0
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld d, a
	ld e, [hl]
	; de now contains the chosen map's group and number indices.
	push de
	farcall LookUpGrassJohtoWildmons

	; Generate a number, either 0, 1, or 2, to choose a time of day.
	; Can't pick 3 since evening does not have wild data.
.loop2
	call Random
	maskbits NUM_DAYTIMES
	cp EVE_F
	jr z, .loop2
	; Point hl to the list of Pokémon for that time of day, skipping the map ID and the percentages
	ld bc, 5
	add hl, bc
	ld c, 3 * NUM_GRASSMON
	rst AddNTimes

.loop3
	; Choose one of the middle three Pokemon.
	call Random
	maskbits NUM_GRASSMON
	cp 2
	jr c, .loop3
	cp 5
	jr nc, .loop3
	ld e, a
	ld d, 0
	add hl, de
	add hl, de
	add hl, de
	inc hl ; skip level
	ld a, BANK(JohtoGrassWildMons)
	call GetFarWord
	call GetPokemonIDFromIndex
	ld [wNamedObjectIndex], a
	ld [wCurPartySpecies], a
	call GetPokemonName
	ld hl, wStringBuffer1
	ld de, wMonOrItemNameBuffer
	ld bc, MON_NAME_LENGTH
	rst CopyBytes

	; Now that we've chosen our wild Pokemon,
	; let's recover the map index info and get its name.
	pop bc
	call GetWorldMapLocation
	ld e, a
	farcall GetLandmarkName
	ld hl, OPT_OakText1
	call CopyRadioTextToRAM
	ld a, OAKS_POKEMON_TALK_5
	jmp PrintRadioLine

.overflow
	pop bc
	ld a, OAKS_POKEMON_TALK
	jmp PrintRadioLine

INCLUDE "data/radio/oaks_pkmn_talk_routes.asm"

OaksPKMNTalk5:
	ld hl, OPT_OakText2
	ld a, OAKS_POKEMON_TALK_6
	jmp NextRadioLine

OaksPKMNTalk6:
	ld hl, OPT_OakText3
	ld a, OAKS_POKEMON_TALK_7
	jmp NextRadioLine

OPT_IntroText1:
	text_far _OPT_IntroText1
	text_end

OPT_IntroText2:
	text_far _OPT_IntroText2
	text_end

OPT_IntroText3:
	text_far _OPT_IntroText3
	text_end

OPT_OakText1:
	text_far _OPT_OakText1
	text_end

OPT_OakText2:
	text_far _OPT_OakText2
	text_end

OPT_OakText3:
	text_far _OPT_OakText3
	text_end

OaksPKMNTalk7:
	ld a, [wCurPartySpecies]
	ld [wNamedObjectIndex], a
	call GetPokemonName
	ld hl, OPT_MaryText1
	ld a, OAKS_POKEMON_TALK_8
	jmp NextRadioLine

OPT_MaryText1:
	text_far _OPT_MaryText1
	text_end

OaksPKMNTalk8:
	; 0-15 are all valid indexes into .Adverbs,
	; so no need for a retry loop
	call Random
	maskbits NUM_OAKS_POKEMON_TALK_ADVERBS
	assert_power_of_2 NUM_OAKS_POKEMON_TALK_ADVERBS
	ld e, a
	ld d, 0
	ld hl, .Adverbs
	add hl, de
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, OAKS_POKEMON_TALK_9
	jmp NextRadioLine

.Adverbs:
	table_width 2
	dw .OPT_SweetAdorablyText
	dw .OPT_WigglySlicklyText
	dw .OPT_AptlyNamedText
	dw .OPT_UndeniablyKindOfText
	dw .OPT_UnbearablyText
	dw .OPT_WowImpressivelyText
	dw .OPT_AlmostPoisonouslyText
	dw .OPT_SensuallyText
	dw .OPT_MischievouslyText
	dw .OPT_TopicallyText
	dw .OPT_AddictivelyText
	dw .OPT_LooksInWaterText
	dw .OPT_EvolutionMustBeText
	dw .OPT_ProvocativelyText
	dw .OPT_FlippedOutText
	dw .OPT_HeartMeltinglyText
	assert_table_length NUM_OAKS_POKEMON_TALK_ADVERBS

.OPT_SweetAdorablyText:
	text_far _OPT_SweetAdorablyText
	text_end

.OPT_WigglySlicklyText:
	text_far _OPT_WigglySlicklyText
	text_end

.OPT_AptlyNamedText:
	text_far _OPT_AptlyNamedText
	text_end

.OPT_UndeniablyKindOfText:
	text_far _OPT_UndeniablyKindOfText
	text_end

.OPT_UnbearablyText:
	text_far _OPT_UnbearablyText
	text_end

.OPT_WowImpressivelyText:
	text_far _OPT_WowImpressivelyText
	text_end

.OPT_AlmostPoisonouslyText:
	text_far _OPT_AlmostPoisonouslyText
	text_end

.OPT_SensuallyText:
	text_far _OPT_SensuallyText
	text_end

.OPT_MischievouslyText:
	text_far _OPT_MischievouslyText
	text_end

.OPT_TopicallyText:
	text_far _OPT_TopicallyText
	text_end

.OPT_AddictivelyText:
	text_far _OPT_AddictivelyText
	text_end

.OPT_LooksInWaterText:
	text_far _OPT_LooksInWaterText
	text_end

.OPT_EvolutionMustBeText:
	text_far _OPT_EvolutionMustBeText
	text_end

.OPT_ProvocativelyText:
	text_far _OPT_ProvocativelyText
	text_end

.OPT_FlippedOutText:
	text_far _OPT_FlippedOutText
	text_end

.OPT_HeartMeltinglyText:
	text_far _OPT_HeartMeltinglyText
	text_end

OaksPKMNTalk9:
	; 0-15 are all valid indexes into .Adjectives,
	; so no need for a retry loop
	call Random
	maskbits NUM_OAKS_POKEMON_TALK_ADJECTIVES
	assert_power_of_2 NUM_OAKS_POKEMON_TALK_ADJECTIVES
	ld e, a
	ld d, 0
	ld hl, .Adjectives
	add hl, de
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [wOaksPKMNTalkSegmentCounter] ; no-optimize Inefficient WRAM increment/decrement
	dec a
	ld [wOaksPKMNTalkSegmentCounter], a
	ld a, OAKS_POKEMON_TALK_4
	jr nz, .ok
	ld a, 5
	ld [wOaksPKMNTalkSegmentCounter], a
	ld a, OAKS_POKEMON_TALK_10
.ok
	jmp NextRadioLine

.Adjectives:
	table_width 2
	dw .OPT_CuteText
	dw .OPT_WeirdText
	dw .OPT_PleasantText
	dw .OPT_BoldSortOfText
	dw .OPT_FrighteningText
	dw .OPT_SuaveDebonairText
	dw .OPT_PowerfulText
	dw .OPT_ExcitingText
	dw .OPT_GroovyText
	dw .OPT_InspiringText
	dw .OPT_FriendlyText
	dw .OPT_HotHotHotText
	dw .OPT_StimulatingText
	dw .OPT_GuardedText
	dw .OPT_LovelyText
	dw .OPT_SpeedyText
	assert_table_length NUM_OAKS_POKEMON_TALK_ADJECTIVES

.OPT_CuteText:
	text_far _OPT_CuteText
	text_end

.OPT_WeirdText:
	text_far _OPT_WeirdText
	text_end

.OPT_PleasantText:
	text_far _OPT_PleasantText
	text_end

.OPT_BoldSortOfText:
	text_far _OPT_BoldSortOfText
	text_end

.OPT_FrighteningText:
	text_far _OPT_FrighteningText
	text_end

.OPT_SuaveDebonairText:
	text_far _OPT_SuaveDebonairText
	text_end

.OPT_PowerfulText:
	text_far _OPT_PowerfulText
	text_end

.OPT_ExcitingText:
	text_far _OPT_ExcitingText
	text_end

.OPT_GroovyText:
	text_far _OPT_GroovyText
	text_end

.OPT_InspiringText:
	text_far _OPT_InspiringText
	text_end

.OPT_FriendlyText:
	text_far _OPT_FriendlyText
	text_end

.OPT_HotHotHotText:
	text_far _OPT_HotHotHotText
	text_end

.OPT_StimulatingText:
	text_far _OPT_StimulatingText
	text_end

.OPT_GuardedText:
	text_far _OPT_GuardedText
	text_end

.OPT_LovelyText:
	text_far _OPT_LovelyText
	text_end

.OPT_SpeedyText:
	text_far _OPT_SpeedyText
	text_end

OaksPKMNTalk10:
	farcall RadioMusicRestartPokemonChannel
	ld hl, OPT_RestartText
	call PrintText
	call WaitBGMap
	ld hl, OPT_PokemonChannelText
	call PrintText
	ld a, OAKS_POKEMON_TALK_11
	ld [wCurRadioLine], a
	ld a, 100
	ld [wRadioTextDelay], a
	ret

OPT_PokemonChannelText:
	text_far _OPT_PokemonChannelText
	text_end

OPT_RestartText:
	text_end

OaksPKMNTalk11:
	ld hl, wRadioTextDelay
	dec [hl]
	ret nz
	hlcoord 9, 14
	ld de, .pokemon_string
	ld a, OAKS_POKEMON_TALK_12
	jr PlaceRadioString

.pokemon_string
	db "#MON@"

OaksPKMNTalk12:
	ld hl, wRadioTextDelay
	dec [hl]
	ret nz
	hlcoord 1, 16
	ld de, .pokemon_channel_string
	ld a, OAKS_POKEMON_TALK_13
	jr PlaceRadioString

.pokemon_channel_string
	db "#MON Channel@"

OaksPKMNTalk13:
	ld hl, wRadioTextDelay
	dec [hl]
	ret nz
	hlcoord 12, 16
	ld de, .terminator
	ld a, OAKS_POKEMON_TALK_14
	jr PlaceRadioString

.terminator
	db "@"

OaksPKMNTalk14:
	ld hl, wRadioTextDelay
	dec [hl]
	ret nz
	ld de, MUSIC_POKEMON_TALK
	farcall RadioMusicRestartDE
	ld hl, .terminator
	call PrintText
	ld a, OAKS_POKEMON_TALK_4
	ld [wNextRadioLine], a
	xor a
	ld [wNumRadioLinesPrinted], a
	ld a, RADIO_SCROLL
	ld [wCurRadioLine], a
	ld a, 10
	ld [wRadioTextDelay], a
	ret

.terminator
	db "@"

PlaceRadioString:
	ld [wCurRadioLine], a
	ld a, 100
	ld [wRadioTextDelay], a
	jmp PlaceString

CopyBottomLineToTopLine:
	hlcoord 0, 15
	decoord 0, 13
	ld bc, SCREEN_WIDTH * 2
	jmp CopyBytes

ClearBottomLine:
	hlcoord 1, 15
	ld bc, SCREEN_WIDTH - 2
	ld a, " "
	rst ByteFill
	hlcoord 1, 16
	ld bc, SCREEN_WIDTH - 2
	ld a, " "
	jmp ByteFill

PokedexShow1:
	call StartRadioStation
.loop
	call Random
	ld e, a
	call Random
	and $f
	ld d, a
	cp HIGH(NUM_POKEMON)
	jr c, .ok
	jr nz, .loop
	ld a, e
	cp LOW(NUM_POKEMON)
	jr nc, .loop
.ok
	inc de
	push de
	call CheckCaughtMonIndex
	pop hl
	jr z, .loop
	call GetPokemonIDFromIndex
	ld [wCurPartySpecies], a
	ld [wNamedObjectIndex], a
	call GetPokemonName
	ld hl, PokedexShowText
	ld a, POKEDEX_SHOW_2
	jmp NextRadioLine

PokedexShow2:
	ld a, [wCurPartySpecies]
	call GetPokemonIndexFromID
	dec hl
	ld b, h
	ld c, l
	add hl, hl
	add hl, bc
	ld bc, PokedexDataPointerTable
	add hl, bc
	ld a, BANK(PokedexDataPointerTable)
	call GetFarByte
	ld b, a
	inc hl
	ld a, BANK(PokedexDataPointerTable)
	call GetFarWord
	ld a, b
	push af
	push hl
	call CopyDexEntryPart1
	dec hl
	ld [hl], "<DONE>"
	ld hl, wPokedexShowPointerAddr
	call CopyRadioTextToRAM
	pop hl
	pop af
	call CopyDexEntryPart2
rept 4
	inc hl
endr
	ld a, l
	ld [wPokedexShowPointerAddr], a
	ld a, h
	ld [wPokedexShowPointerAddr + 1], a
	ld a, POKEDEX_SHOW_3
	jmp PrintRadioLine

PokedexShow3:
	call CopyDexEntry
	ld a, POKEDEX_SHOW_4
	jmp PrintRadioLine

PokedexShow4:
	call CopyDexEntry
	ld a, POKEDEX_SHOW_5
	jmp PrintRadioLine

PokedexShow5:
	call CopyDexEntry
	ld a, POKEDEX_SHOW_6
	jmp PrintRadioLine

PokedexShow6:
	call CopyDexEntry
	ld a, POKEDEX_SHOW_7
	jmp PrintRadioLine

PokedexShow7:
	call CopyDexEntry
	ld a, POKEDEX_SHOW_8
	jmp PrintRadioLine

PokedexShow8:
	call CopyDexEntry
	ld a, POKEDEX_SHOW
	jmp PrintRadioLine

CopyDexEntry:
	ld hl, wPokedexShowPointerAddr
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [wPokedexShowPointerBank]
	push af
	push hl
	call CopyDexEntryPart1
	dec hl
	ld [hl], "<DONE>"
	ld hl, wPokedexShowPointerAddr
	call CopyRadioTextToRAM
	pop hl
	pop af
	jr CopyDexEntryPart2

CopyDexEntryPart1:
	ld de, wPokedexShowPointerBank
	ld bc, SCREEN_WIDTH - 1
	call FarCopyBytes
	ld hl, wPokedexShowPointerAddr
	ld a, TX_START
	ld [hli], a
	ld a, "<LINE>"
	ld [hli], a
.loop
	ld a, [hli]
	cp "@"
	ret z
	cp "<NEXT>"
	ret z
	cp "<DEXEND>"
	ret z
	jr .loop

CopyDexEntryPart2:
	ld d, a
.loop
	ld a, d
	call GetFarByte
	inc hl
	cp "@"
	jr z, .okay
	cp "<NEXT>"
	jr z, .okay
	cp "<DEXEND>"
	jr nz, .loop
.okay
	ld a, l
	ld [wPokedexShowPointerAddr], a
	ld a, h
	ld [wPokedexShowPointerAddr + 1], a
	ld a, d
	ld [wPokedexShowPointerBank], a
	ret

PokedexShowText:
	text_far _PokedexShowText
	text_end

BenMonMusic1:
	call StartPokemonMusicChannel
	ld hl, BenIntroText1
	ld a, POKEMON_MUSIC_2
	jmp NextRadioLine

BenMonMusic2:
	ld hl, BenIntroText2
	ld a, POKEMON_MUSIC_3
	jmp NextRadioLine

BenMonMusic3:
	ld hl, BenIntroText3
	ld a, POKEMON_MUSIC_4
	jmp NextRadioLine

FernMonMusic1:
	call StartPokemonMusicChannel
	ld hl, FernIntroText1
	ld a, LETS_ALL_SING_2
	jmp NextRadioLine

FernMonMusic2:
	ld hl, FernIntroText2
	ld a, POKEMON_MUSIC_4
	jmp NextRadioLine

BenFernMusic4:
	ld hl, BenFernText1
	ld a, POKEMON_MUSIC_5
	jmp NextRadioLine

BenFernMusic5:
	call GetWeekday
	and 1
	ld hl, BenFernText2A
	jr z, .SunTueThurSun
	ld hl, BenFernText2B
.SunTueThurSun:
	ld a, POKEMON_MUSIC_6
	jmp NextRadioLine

BenFernMusic6:
	call GetWeekday
	and 1
	ld hl, BenFernText3A
	jr z, .SunTueThurSun
	ld hl, BenFernText3B
.SunTueThurSun:
	ld a, POKEMON_MUSIC_7
	jmp NextRadioLine

StartPokemonMusicChannel:
	call RadioTerminator
	call PrintText
	ld de, MUSIC_POKEMON_MARCH
	call GetWeekday
	and 1
	jr z, .SunTueThurSun
	ld de, MUSIC_POKEMON_LULLABY
.SunTueThurSun:
	farjp RadioMusicRestartDE

BenIntroText1:
	text_far _BenIntroText1
	text_end

BenIntroText2:
	text_far _BenIntroText2
	text_end

BenIntroText3:
	text_far _BenIntroText3
	text_end

FernIntroText1:
	text_far _FernIntroText1
	text_end

FernIntroText2:
	text_far _FernIntroText2
	text_end

BenFernText1:
	text_far _BenFernText1
	text_end

BenFernText2A:
	text_far _BenFernText2A
	text_end

BenFernText2B:
	text_far _BenFernText2B
	text_end

BenFernText3A:
	text_far _BenFernText3A
	text_end

BenFernText3B:
	text_far _BenFernText3B
	text_end

LuckyNumberShow1:
	call StartRadioStation
	farcall CheckLuckyNumberShowFlag
	jr nz, .dontreset
	farcall ResetLuckyNumberShowFlag
.dontreset
	ld hl, LC_Text1
	ld a, LUCKY_NUMBER_SHOW_2
	jmp NextRadioLine

LuckyNumberShow2:
	ld hl, LC_Text2
	ld a, LUCKY_NUMBER_SHOW_3
	jmp NextRadioLine

LuckyNumberShow3:
	ld hl, LC_Text3
	ld a, LUCKY_NUMBER_SHOW_4
	jmp NextRadioLine

LuckyNumberShow4:
	ld hl, LC_Text4
	ld a, LUCKY_NUMBER_SHOW_5
	jmp NextRadioLine

LuckyNumberShow5:
	ld hl, LC_Text5
	ld a, LUCKY_NUMBER_SHOW_6
	jmp NextRadioLine

LuckyNumberShow6:
	ld hl, LC_Text6
	ld a, LUCKY_NUMBER_SHOW_7
	jmp NextRadioLine

LuckyNumberShow7:
	ld hl, LC_Text7
	ld a, LUCKY_NUMBER_SHOW_8
	jmp NextRadioLine

LuckyNumberShow8:
	ld hl, wStringBuffer1
	ld de, wLuckyIDNumber
	lb bc, PRINTNUM_LEADINGZEROS | 2, 5
	call PrintNum
	ld a, "@"
	ld [wStringBuffer1 + 5], a
	ld hl, LC_Text8
	ld a, LUCKY_NUMBER_SHOW_9
	jmp NextRadioLine

LuckyNumberShow9:
	ld hl, LC_Text9
	ld a, LUCKY_NUMBER_SHOW_10
	jmp NextRadioLine

LuckyNumberShow10:
	ld hl, LC_Text7
	ld a, LUCKY_NUMBER_SHOW_11
	jmp NextRadioLine

LuckyNumberShow11:
	ld hl, LC_Text8
	ld a, LUCKY_NUMBER_SHOW_12
	jmp NextRadioLine

LuckyNumberShow12:
	ld hl, LC_Text10
	ld a, LUCKY_NUMBER_SHOW_13
	jmp NextRadioLine

LuckyNumberShow13:
	ld hl, LC_Text11
	call Random
	and a
	ld a, LUCKY_CHANNEL
	jr nz, .okay
	ld a, LUCKY_NUMBER_SHOW_14
.okay
	jmp NextRadioLine

LuckyNumberShow14:
	ld hl, LC_DragText1
	ld a, LUCKY_NUMBER_SHOW_15
	jmp NextRadioLine

LuckyNumberShow15:
	ld hl, LC_DragText2
	ld a, LUCKY_CHANNEL
	jmp NextRadioLine

LC_Text1:
	text_far _LC_Text1
	text_end

LC_Text2:
	text_far _LC_Text2
	text_end

LC_Text3:
	text_far _LC_Text3
	text_end

LC_Text4:
	text_far _LC_Text4
	text_end

LC_Text5:
	text_far _LC_Text5
	text_end

LC_Text6:
	text_far _LC_Text6
	text_end

LC_Text7:
	text_far _LC_Text7
	text_end

LC_Text8:
	text_far _LC_Text8
	text_end

LC_Text9:
	text_far _LC_Text9
	text_end

LC_Text10:
	text_far _LC_Text10
	text_end

LC_Text11:
	text_far _LC_Text11
	text_end

LC_DragText1:
	text_far _LC_DragText1
	text_end

LC_DragText2:
	text_far _LC_DragText2
	text_end

PeoplePlaces1:
	call StartRadioStation
	ld hl, PnP_Text1
	ld a, PLACES_AND_PEOPLE_2
	jmp NextRadioLine

PeoplePlaces2:
	ld hl, PnP_Text2
	ld a, PLACES_AND_PEOPLE_3
	jmp NextRadioLine

PeoplePlaces3:
	ld hl, PnP_Text3
	call Random
	cp 49 percent - 1
	; a = carry ? PLACES_AND_PEOPLE_4 : PLACES_AND_PEOPLE_6
	sbc a
	and PLACES_AND_PEOPLE_4 - PLACES_AND_PEOPLE_6
	add PLACES_AND_PEOPLE_6
	jmp NextRadioLine

PnP_Text1:
	text_far _PnP_Text1
	text_end

PnP_Text2:
	text_far _PnP_Text2
	text_end

PnP_Text3:
	text_far _PnP_Text3
	text_end

PeoplePlaces4: ; People
	call Random
	maskbits NUM_TRAINER_CLASSES
	inc a
	cp NUM_TRAINER_CLASSES ; exclude MYSTICALMAN
	jr nc, PeoplePlaces4
	push af
	ld hl, PnP_HiddenPeople
	ld a, [wStatusFlags]
	bit STATUSFLAGS_HALL_OF_FAME_F, a
	jr z, .ok
	ld hl, PnP_HiddenPeople_BeatE4
	ld a, [wKantoBadges]
	cp %11111111 ; all badges
	jr nz, .ok
	ld hl, PnP_HiddenPeople_BeatKanto
.ok
	pop af
	ld c, a
	ld de, 1
	push bc
	call IsInArray
	pop bc
	jr c, PeoplePlaces4
	push bc
	farcall GetTrainerClassName
	ld de, wStringBuffer1
	call CopyName1
	pop bc
	ld b, 1
	farcall GetTrainerName
	ld hl, PnP_Text4
	ld a, PLACES_AND_PEOPLE_5
	jmp NextRadioLine

INCLUDE "data/radio/pnp_hidden_people.asm"

PnP_Text4:
	text_far _PnP_Text4
	text_end

PeoplePlaces5:
	; 0-15 are all valid indexes into .Adjectives,
	; so no need for a retry loop
	call Random
	maskbits NUM_PNP_PEOPLE_ADJECTIVES
	assert_power_of_2 NUM_PNP_PEOPLE_ADJECTIVES
	ld e, a
	ld d, 0
	ld hl, .Adjectives
	add hl, de
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call Random
	cp 4 percent
	ld a, PLACES_AND_PEOPLE
	jr c, .ok
	call Random
	cp 49 percent - 1
	; a = carry ? PLACES_AND_PEOPLE_4 : PLACES_AND_PEOPLE_6
	sbc a
	and PLACES_AND_PEOPLE_4 - PLACES_AND_PEOPLE_6
	add PLACES_AND_PEOPLE_6
.ok
	jmp NextRadioLine

.Adjectives:
	table_width 2
	dw PnP_CuteText
	dw PnP_LazyText
	dw PnP_HappyText
	dw PnP_NoisyText
	dw PnP_PrecociousText
	dw PnP_BoldText
	dw PnP_PickyText
	dw PnP_SortOfOKText
	dw PnP_SoSoText
	dw PnP_GreatText
	dw PnP_MyTypeText
	dw PnP_CoolText
	dw PnP_InspiringText
	dw PnP_WeirdText
	dw PnP_RightForMeText
	dw PnP_OddText
	assert_table_length NUM_PNP_PEOPLE_ADJECTIVES

PnP_CuteText:
	text_far _PnP_CuteText
	text_end

PnP_LazyText:
	text_far _PnP_LazyText
	text_end

PnP_HappyText:
	text_far _PnP_HappyText
	text_end

PnP_NoisyText:
	text_far _PnP_NoisyText
	text_end

PnP_PrecociousText:
	text_far _PnP_PrecociousText
	text_end

PnP_BoldText:
	text_far _PnP_BoldText
	text_end

PnP_PickyText:
	text_far _PnP_PickyText
	text_end

PnP_SortOfOKText:
	text_far _PnP_SortOfOKText
	text_end

PnP_SoSoText:
	text_far _PnP_SoSoText
	text_end

PnP_GreatText:
	text_far _PnP_GreatText
	text_end

PnP_MyTypeText:
	text_far _PnP_MyTypeText
	text_end

PnP_CoolText:
	text_far _PnP_CoolText
	text_end

PnP_InspiringText:
	text_far _PnP_InspiringText
	text_end

PnP_WeirdText:
	text_far _PnP_WeirdText
	text_end

PnP_RightForMeText:
	text_far _PnP_RightForMeText
	text_end

PnP_OddText:
	text_far _PnP_OddText
	text_end

PeoplePlaces6: ; Places
	call Random
	cp (PnP_Places.End - PnP_Places) / 2
	jr nc, PeoplePlaces6
	ld hl, PnP_Places
	ld c, a
	ld b, 0
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld b, a
	ld c, [hl]
	call GetWorldMapLocation
	ld e, a
	farcall GetLandmarkName
	ld hl, PnP_Text5
	ld a, PLACES_AND_PEOPLE_7
	jmp NextRadioLine

INCLUDE "data/radio/pnp_places.asm"

PnP_Text5:
	text_far _PnP_Text5
	text_end

PeoplePlaces7:
	; 0-15 are all valid indexes into .Adjectives,
	; so no need for a retry loop
	call Random
	maskbits NUM_PNP_PLACES_ADJECTIVES
	assert_power_of_2 NUM_PNP_PLACES_ADJECTIVES
	ld e, a
	ld d, 0
	ld hl, .Adjectives
	add hl, de
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call CopyRadioTextToRAM
	call Random
	cp 4 percent
	ld a, PLACES_AND_PEOPLE
	jr c, .ok
	call Random
	cp 49 percent - 1
	; a = carry ? PLACES_AND_PEOPLE_4 : PLACES_AND_PEOPLE_6
	sbc a
	and PLACES_AND_PEOPLE_4 - PLACES_AND_PEOPLE_6
	add PLACES_AND_PEOPLE_6
.ok
	jmp PrintRadioLine

.Adjectives:
	table_width 2
	dw PnP_CuteText
	dw PnP_LazyText
	dw PnP_HappyText
	dw PnP_NoisyText
	dw PnP_PrecociousText
	dw PnP_BoldText
	dw PnP_PickyText
	dw PnP_SortOfOKText
	dw PnP_SoSoText
	dw PnP_GreatText
	dw PnP_MyTypeText
	dw PnP_CoolText
	dw PnP_InspiringText
	dw PnP_WeirdText
	dw PnP_RightForMeText
	dw PnP_OddText
	assert_table_length NUM_PNP_PLACES_ADJECTIVES

RocketRadio1:
	call StartRadioStation
	ld hl, RocketRadioText1
	ld a, ROCKET_RADIO_2
	jmp NextRadioLine

RocketRadio2:
	ld hl, RocketRadioText2
	ld a, ROCKET_RADIO_3
	jmp NextRadioLine

RocketRadio3:
	ld hl, RocketRadioText3
	ld a, ROCKET_RADIO_4
	jmp NextRadioLine

RocketRadio4:
	ld hl, RocketRadioText4
	ld a, ROCKET_RADIO_5
	jmp NextRadioLine

RocketRadio5:
	ld hl, RocketRadioText5
	ld a, ROCKET_RADIO_6
	jmp NextRadioLine

RocketRadio6:
	ld hl, RocketRadioText6
	ld a, ROCKET_RADIO_7
	jmp NextRadioLine

RocketRadio7:
	ld hl, RocketRadioText7
	ld a, ROCKET_RADIO_8
	jmp NextRadioLine

RocketRadio8:
	ld hl, RocketRadioText8
	ld a, ROCKET_RADIO_9
	jmp NextRadioLine

RocketRadio9:
	ld hl, RocketRadioText9
	ld a, ROCKET_RADIO_10
	jmp NextRadioLine

RocketRadio10:
	ld hl, RocketRadioText10
	ld a, ROCKET_RADIO
	jmp NextRadioLine

RocketRadioText1:
	text_far _RocketRadioText1
	text_end

RocketRadioText2:
	text_far _RocketRadioText2
	text_end

RocketRadioText3:
	text_far _RocketRadioText3
	text_end

RocketRadioText4:
	text_far _RocketRadioText4
	text_end

RocketRadioText5:
	text_far _RocketRadioText5
	text_end

RocketRadioText6:
	text_far _RocketRadioText6
	text_end

RocketRadioText7:
	text_far _RocketRadioText7
	text_end

RocketRadioText8:
	text_far _RocketRadioText8
	text_end

RocketRadioText9:
	text_far _RocketRadioText9
	text_end

RocketRadioText10:
	text_far _RocketRadioText10
	text_end

PokeFluteRadio:
	call StartRadioStation
	ld a, 1
	ld [wNumRadioLinesPrinted], a
	ret

UnownRadio:
	call StartRadioStation
	ld a, 1
	ld [wNumRadioLinesPrinted], a
	ret

EvolutionRadio:
	call StartRadioStation
	ld a, 1
	ld [wNumRadioLinesPrinted], a
	ret

BuenasPassword1:
; Determine if we need to be here
	call BuenasPasswordCheckTime
	jr nc, .PlayPassword
	ld a, [wNumRadioLinesPrinted]
	and a
	jmp z, BuenasPassword20
	jmp BuenasPassword8

.PlayPassword:
	call StartRadioStation
	ldh a, [hBGMapMode]
	push af
	xor a
	ldh [hBGMapMode], a
	ld de, BuenasPasswordChannelName
	hlcoord 2, 9
	rst PlaceString
	pop af
	ldh [hBGMapMode], a
	ld hl, BuenaRadioText1
	ld a, BUENAS_PASSWORD_2
	jmp NextRadioLine

BuenasPassword2:
	ld hl, BuenaRadioText2
	ld a, BUENAS_PASSWORD_3
	jmp NextRadioLine

BuenasPassword3:
	call BuenasPasswordCheckTime
	ld hl, BuenaRadioText3
	jmp c, BuenasPasswordAfterMidnight
	ld a, BUENAS_PASSWORD_4
	jmp NextRadioLine

BuenasPassword4:
	call BuenasPasswordCheckTime
	jmp c, BuenasPassword8
	ld a, [wBuenasPassword]
; If we already generated the password today, we don't need to generate a new one.
	ld hl, wDailyFlags2
	bit DAILYFLAGS2_BUENAS_PASSWORD_F, [hl]
	jr nz, .AlreadyGotIt
; There are only 11 groups to choose from.
.greater_than_11
	call Random
	maskbits NUM_PASSWORD_CATEGORIES
	cp NUM_PASSWORD_CATEGORIES
	jr nc, .greater_than_11
; Store it in the high nybble of e.
	swap a
	ld e, a
; For each group, choose one of the three passwords.
.greater_than_three
	call Random
	maskbits NUM_PASSWORDS_PER_CATEGORY
	cp NUM_PASSWORDS_PER_CATEGORY
	jr nc, .greater_than_three
; The high nybble of wBuenasPassword will now contain the password group index, and the low nybble contains the actual password.
	add e
	ld [wBuenasPassword], a
; Set the flag so that we don't generate a new password this week.
	ld hl, wDailyFlags2
	set DAILYFLAGS2_BUENAS_PASSWORD_F, [hl]
.AlreadyGotIt:
	ld c, a
	call GetBuenasPassword
	ld hl, BuenaRadioText4
	ld a, BUENAS_PASSWORD_5
	jmp NextRadioLine

GetBuenasPassword:
; The password indices are held in c.  High nybble contains the group index, low nybble contains the word index.
; Load the password group pointer in hl.
	ld a, c
	swap a
	and $f
	ld hl, BuenasPasswordTable
	ld d, 0
	ld e, a
	add hl, de
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
; Get the password type and store it in b.
	ld a, [hli]
	ld b, a
	push hl
	inc hl
; Get the password index.
	ld a, c
	and $f
	ld c, a
	push hl
	ld hl, .StringFunctionJumptable
	ld e, b
	add hl, de
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	pop de ; de now contains the pointer to the value of this week's password, in Blue Card Points.
	call _hl_
	pop hl
	ld c, [hl]
	ret

.StringFunctionJumptable:
; entries correspond to BUENA_* constants
	table_width 2
	dw .Mon       ; BUENA_MON
	dw .Item      ; BUENA_ITEM
	dw .Move      ; BUENA_MOVE
	dw .RawString ; BUENA_STRING
	assert_table_length NUM_BUENA_FUNCTIONS

.Mon:
	ld h, 0
	ld l, c
	add hl, hl
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call GetPokemonIDFromIndex
	ld [wNamedObjectIndex], a
	jmp GetPokemonName

.Item:
	ld h, 0
	ld l, c
	add hl, hl
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call GetItemIDFromIndex
	ld [wNamedObjectIndex], a
	jmp GetItemName

.Move:
	ld h, 0
	ld l, c
	add hl, hl
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call GetMoveIDFromIndex
	ld [wNamedObjectIndex], a
	jmp GetMoveName

.RawString:
; Get the string from the table...
	ld a, c
	and a
	jr z, .skip
.read_loop
	ld a, [de]
	inc de
	cp "@"
	jr nz, .read_loop
	dec c
	jr nz, .read_loop
; ... and copy it into wStringBuffer1.
.skip
	ld hl, wStringBuffer1
.copy_loop
	ld a, [de]
	inc de
	ld [hli], a
	cp "@"
	jr nz, .copy_loop
	ld de, wStringBuffer1
	ret

INCLUDE "data/radio/buenas_passwords.asm"

BuenasPassword5:
	ld hl, BuenaRadioText5
	ld a, BUENAS_PASSWORD_6
	jmp NextRadioLine

BuenasPassword6:
	ld hl, BuenaRadioText6
	ld a, BUENAS_PASSWORD_7
	jmp NextRadioLine

BuenasPassword7:
	call BuenasPasswordCheckTime
	ld hl, BuenaRadioText7
	jr c, BuenasPasswordAfterMidnight
	ld a, BUENAS_PASSWORD
	jmp NextRadioLine

BuenasPasswordAfterMidnight:
	push hl
	ld hl, wDailyFlags2
	res DAILYFLAGS2_BUENAS_PASSWORD_F, [hl]
	pop hl
	ld a, BUENAS_PASSWORD_8
	jmp NextRadioLine

BuenasPassword8:
	ld hl, wDailyFlags2
	res DAILYFLAGS2_BUENAS_PASSWORD_F, [hl]
	ld hl, BuenaRadioMidnightText10
	ld a, BUENAS_PASSWORD_9
	jmp NextRadioLine

BuenasPassword9:
	ld hl, BuenaRadioMidnightText1
	ld a, BUENAS_PASSWORD_10
	jmp NextRadioLine

BuenasPassword10:
	ld hl, BuenaRadioMidnightText2
	ld a, BUENAS_PASSWORD_11
	jmp NextRadioLine

BuenasPassword11:
	ld hl, BuenaRadioMidnightText3
	ld a, BUENAS_PASSWORD_12
	jmp NextRadioLine

BuenasPassword12:
	ld hl, BuenaRadioMidnightText4
	ld a, BUENAS_PASSWORD_13
	jmp NextRadioLine

BuenasPassword13:
	ld hl, BuenaRadioMidnightText5
	ld a, BUENAS_PASSWORD_14
	jmp NextRadioLine

BuenasPassword14:
	ld hl, BuenaRadioMidnightText6
	ld a, BUENAS_PASSWORD_15
	jmp NextRadioLine

BuenasPassword15:
	ld hl, BuenaRadioMidnightText7
	ld a, BUENAS_PASSWORD_16
	jmp NextRadioLine

BuenasPassword16:
	ld hl, BuenaRadioMidnightText8
	ld a, BUENAS_PASSWORD_17
	jmp NextRadioLine

BuenasPassword17:
	ld hl, BuenaRadioMidnightText9
	ld a, BUENAS_PASSWORD_18
	jmp NextRadioLine

BuenasPassword18:
	ld hl, BuenaRadioMidnightText10
	ld a, BUENAS_PASSWORD_19
	jmp NextRadioLine

BuenasPassword19:
	ld hl, BuenaRadioMidnightText10
	ld a, BUENAS_PASSWORD_20
	jmp NextRadioLine

BuenasPassword20:
	ldh a, [hBGMapMode]
	push af
	farcall NoRadioMusic
	farcall NoRadioName
	pop af
	ldh [hBGMapMode], a
	ld hl, wDailyFlags2
	res DAILYFLAGS2_BUENAS_PASSWORD_F, [hl]
	ld a, BUENAS_PASSWORD
	ld [wCurRadioLine], a
	xor a
	ld [wNumRadioLinesPrinted], a
	ld hl, BuenaOffTheAirText
	ld a, BUENAS_PASSWORD_21
	jmp NextRadioLine

BuenasPassword21:
	ld a, BUENAS_PASSWORD
	ld [wCurRadioLine], a
	xor a
	ld [wNumRadioLinesPrinted], a
	call BuenasPasswordCheckTime
	jmp nc, BuenasPassword1
	ld hl, BuenaOffTheAirText
	ld a, BUENAS_PASSWORD_21
	jmp NextRadioLine

BuenasPasswordCheckTime:
	call UpdateTime
	ldh a, [hHours]
	cp EVE_HOUR
	ret

BuenasPasswordChannelName:
	db "BUENA'S PASSWORD@"

BuenaRadioText1:
	text_far _BuenaRadioText1
	text_end

BuenaRadioText2:
	text_far _BuenaRadioText2
	text_end

BuenaRadioText3:
	text_far _BuenaRadioText3
	text_end

BuenaRadioText4:
	text_far _BuenaRadioText4
	text_end

BuenaRadioText5:
	text_far _BuenaRadioText5
	text_end

BuenaRadioText6:
	text_far _BuenaRadioText6
	text_end

BuenaRadioText7:
	text_far _BuenaRadioText7
	text_end

BuenaRadioMidnightText1:
	text_far _BuenaRadioMidnightText1
	text_end

BuenaRadioMidnightText2:
	text_far _BuenaRadioMidnightText2
	text_end

BuenaRadioMidnightText3:
	text_far _BuenaRadioMidnightText3
	text_end

BuenaRadioMidnightText4:
	text_far _BuenaRadioMidnightText4
	text_end

BuenaRadioMidnightText5:
	text_far _BuenaRadioMidnightText5
	text_end

BuenaRadioMidnightText6:
	text_far _BuenaRadioMidnightText6
	text_end

BuenaRadioMidnightText7:
	text_far _BuenaRadioMidnightText7
	text_end

BuenaRadioMidnightText8:
	text_far _BuenaRadioMidnightText8
	text_end

BuenaRadioMidnightText9:
	text_far _BuenaRadioMidnightText9
	text_end

BuenaRadioMidnightText10:
	text_far _BuenaRadioMidnightText10
	text_end

BuenaOffTheAirText:
	text_far _BuenaOffTheAirText
	text_end

CopyRadioTextToRAM:
	ld a, [hl]
	cp TX_FAR
	jmp z, FarCopyRadioText
	ld de, wRadioText
	ld bc, 2 * SCREEN_WIDTH
	jmp CopyBytes

StartRadioStation:
	ld a, [wNumRadioLinesPrinted]
	and a
	ret nz
	call RadioTerminator
	call PrintText
	ld hl, RadioChannelSongs
	ld a, [wCurRadioLine]
	ld c, a
	ld b, 0
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld d, [hl]
	ld e, a
	farjp RadioMusicRestartDE

INCLUDE "data/radio/channel_music.asm"

NextRadioLine:
	push af
	call CopyRadioTextToRAM
	pop af
	jmp PrintRadioLine

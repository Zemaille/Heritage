_UpdatePlayerSprite::
	call GetPlayerSprite
	ld a, [wUsedSprites]
	ldh [hUsedSpriteIndex], a
	ld a, [wUsedSprites + 1]
	ldh [hUsedSpriteTile], a
	ld hl, wSpriteFlags
	res 5, [hl]
	jmp GetUsedSprite

LoadStandingSpritesGFX: ; mobile
	ld hl, wSpriteFlags
	ld a, [hl]
	push af
	res SPRITES_SKIP_STANDING_GFX_F, [hl]
	set SPRITES_SKIP_WALKING_GFX_F, [hl]
	call LoadUsedSpritesGFX
	pop af
	ld [wSpriteFlags], a
	ret

LoadWalkingSpritesGFX: ; mobile
	ld hl, wSpriteFlags
	ld a, [hl]
	push af
	set SPRITES_SKIP_STANDING_GFX_F, [hl]
	res SPRITES_SKIP_WALKING_GFX_F, [hl]
	call LoadUsedSpritesGFX
	pop af
	ld [wSpriteFlags], a
	ret

GetPlayerSprite:
; Get Chris or Kris's sprite.
	ld hl, ChrisStateSprites
	ld a, [wPlayerSpriteSetupFlags]
	bit PLAYERSPRITESETUP_FEMALE_TO_MALE_F, a
	jr nz, .go
	ld a, [wPlayerGender]
	bit PLAYERGENDER_FEMALE_F, a
	jr z, .go
	ld hl, KrisStateSprites

.go
	ld a, [wPlayerState]
	ld c, a
.loop
	ld a, [hli]
	cp c
	jr z, .good
	inc hl
	cp -1
	jr nz, .loop

; Any player state not in the array defaults to Chris's sprite.
	xor a ; ld a, PLAYER_NORMAL
	ld [wPlayerState], a
	ld a, SPRITE_CHRIS
	jr .finish

.good
	ld a, [hl]

.finish
	ld [wUsedSprites + 0], a
	ld [wPlayerSprite], a
	ld [wPlayerObjectSprite], a
	ret

INCLUDE "data/sprites/player_sprites.asm"

RefreshSprites::
	push hl
	push de
	push bc
	call GetPlayerSprite
	xor a
	ldh [hUsedSpriteIndex], a
	call ReloadSpriteIndex
	call LoadMiscTiles
	jmp PopBCDEHL

ReloadSpriteIndex::
; Reloads sprites using hUsedSpriteIndex.
; Used to reload variable sprites
	ld hl, wObjectStructs
	ld de, OBJECT_LENGTH
	push bc
	ldh a, [hUsedSpriteIndex]
	ld b, a
	xor a
.loop
	ldh [hObjectStructIndex], a
	ld a, [hl]
	and a
	jr z, .done
	bit 7, b
	jr z, .continue
	cp b
	jr nz, .done
.continue
	push hl
	call GetSpriteVTile
	pop hl
	push hl
	inc hl
	inc hl
	ld [hl], a
	pop hl
.done
	add hl, de
	ldh a, [hObjectStructIndex]
	inc a
	cp NUM_OBJECT_STRUCTS
	jr nz, .loop
	pop bc
	ret

LoadUsedSpritesGFX:
	ld a, MAPCALLBACK_SPRITES
	call RunMapCallback
	call GetUsedSprites
; fallthrough
LoadMiscTiles:
	ld a, [wSpriteFlags]
	bit SPRITES_SKIP_WALKING_GFX_F, a
	ret nz

	ld c, EMOTE_SHADOW
	call LoadEmote
	call GetMapEnvironment
	call CheckOutdoorMap
	ld c, EMOTE_GRASS_RUSTLE
	jr z, .outdoor
	ld c, EMOTE_BOULDER_DUST
.outdoor
	jmp LoadEmote

SafeGetSprite:
	push hl
	call GetSprite
	pop hl
	ret

GetSprite::
	call GetMonSprite
	ret c

	ld hl, OverworldSprites + SPRITEDATA_ADDR
	dec a
	ld c, a
	ld b, 0
	ld a, NUM_SPRITEDATA_FIELDS
	rst AddNTimes
	; load the address into de
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	; load the length into c
	ld a, [hli]
	swap a
	ld c, a
	; load the sprite bank into both b and h
	ld b, [hl]
	ld a, [hli]
	; load the sprite type into l
	ld l, [hl]
	ld h, a
	ret

GetMonSprite:
; Return carry if a monster sprite was loaded.

	cp SPRITE_POKEMON
	jr c, .Normal
	cp SPRITE_DAY_CARE_MON_1
	jr z, .BreedMon1
	cp SPRITE_DAY_CARE_MON_2
	jr z, .BreedMon2
	cp SPRITE_VARS
	jr nc, .Variable
	jr .Icon

.Normal:
	and a
	ret

.Icon:
	sub SPRITE_POKEMON
	ld e, a
	ld d, 0
	ld hl, SpriteMons
	add hl, de
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call GetPokemonIDFromIndex
	jr .Mon

.BreedMon1
	ld a, [wBreedMon1Species]
	jr .Mon

.BreedMon2
	ld a, [wBreedMon2Species]

.Mon:
	ld e, a
	and a
	jr z, .NoBreedmon

	farcall LoadOverworldMonIcon

	lb hl, 0, WALKING_SPRITE
	scf
	ret

.Variable:
	sub SPRITE_VARS
	ld e, a
	ld d, 0
	ld hl, wVariableSprites
	add hl, de
	ld a, [hl]
	and a
	jr nz, GetMonSprite

.NoBreedmon:
	ld a, WALKING_SPRITE
	lb hl, 0, WALKING_SPRITE
	and a
	ret

_DoesSpriteHaveFacings::
; Checks to see whether we can apply a facing to a sprite.
; Returns carry unless the sprite is a Pokemon or a Still Sprite.
	cp SPRITE_POKEMON
	jr nc, .only_down

	push hl
	push bc
	ld hl, OverworldSprites + SPRITEDATA_TYPE
	dec a
	ld c, a
	ld b, 0
	ld a, NUM_SPRITEDATA_FIELDS
	rst AddNTimes
	ld a, [hl]
	pop bc
	pop hl
	cp STILL_SPRITE
	jr nz, .only_down
	scf
	ret

.only_down
	and a
	ret

_GetSpritePalette::
	ld a, c
	call GetMonSprite
	jr c, .is_pokemon

	ld hl, OverworldSprites + SPRITEDATA_PALETTE
	dec a
	ld c, a
	ld b, 0
	ld a, NUM_SPRITEDATA_FIELDS
	rst AddNTimes
	ld c, [hl]
	ret

.is_pokemon
	xor a
	ld c, a
	ret

AddSpriteGFX:
; Add any new sprite ids to a list of graphics to be loaded.
; Return carry if the list is full.

	push hl
	push bc
	ld b, a
	ld hl, wUsedSprites + 2
	ld c, SPRITE_GFX_LIST_CAPACITY - 1
.loop
	ld a, [hl]
	cp b
	jr z, .exists
	and a
	jr z, .new
	inc hl
	inc hl
	dec c
	jr nz, .loop

	pop bc
	pop hl
	scf
	ret

.exists
	pop bc
	pop hl
	and a
	ret

.new
	ld [hl], b
	pop bc
	pop hl
	and a
	ret

GetSpriteLength:
; Return the length of sprite type a in tiles.

	cp WALKING_SPRITE
	jr z, .AnyDirection
	cp STANDING_SPRITE
	jr z, .AnyDirection
	cp STILL_SPRITE
	jr z, .OneDirection

	ld a, 12
	ret

.AnyDirection:
	ld a, 12
	ret

.OneDirection:
	ld a, 4
	ret

GetUsedSprites:
	ld hl, wUsedSprites
	ld c, SPRITE_GFX_LIST_CAPACITY

.loop
	ld a, [wSpriteFlags]
	res SPRITES_VRAM_BANK_0_F, a
	ld [wSpriteFlags], a

	ld a, [hli]
	and a
	ret z
	ldh [hUsedSpriteIndex], a

	ld a, [hli]
	ldh [hUsedSpriteTile], a

	bit 7, a ; tiles $80+ are in VRAM bank 0
	jr z, .dont_set

	ld a, [wSpriteFlags]
	set SPRITES_VRAM_BANK_0_F, a
	ld [wSpriteFlags], a

.dont_set
	push bc
	push hl
	call GetUsedSprite
	pop hl
	pop bc
	dec c
	jr nz, .loop
	ret

GetUsedSprite::
	ldh a, [hUsedSpriteIndex]
	call SafeGetSprite
	ldh a, [hUsedSpriteTile]
	call .GetTileAddr
	push hl
	push de
	push bc
	ld a, [wSpriteFlags]
	bit SPRITES_SKIP_STANDING_GFX_F, a
	call z, .CopyToVram
	pop bc
	ld l, c
	ld h, $0
rept 4
	add hl, hl
endr
	pop de
	add hl, de
	ld d, h
	ld e, l
	pop hl

	ld a, [wSpriteFlags]
	bit SPRITES_SKIP_WALKING_GFX_F, a
	ret nz

	ldh a, [hUsedSpriteIndex]
	call _DoesSpriteHaveFacings
	ret c

	ld a, [wSpriteFlags]
	bit 5, a
	ld a, h
	jr nz, .vram1
	add 4
.vram1
	add 4
	ld h, a
; fallthrough
.CopyToVram:
	ldh a, [rVBK]
	push af
	ld a, [wSpriteFlags]
	and 1 << 5
	swap a
	rra
	ldh [rVBK], a
	call Get2bpp
	pop af
	ldh [rVBK], a
	ret

.GetTileAddr:
; Return the address of tile (a) in (hl).
	and $7f
	swap a
	ld l, a
	and $f
	ld h, a
	xor l
	add LOW(vTiles0)
	ld l, a
	ld a, h
	adc HIGH(vTiles0)
	ld h, a
	ret

LoadEmote::
; Get the address of the pointer to emote c.
	ld a, c
	ld bc, EMOTE_LENGTH
	ld hl, Emotes
	rst AddNTimes
; Load the emote address into de
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
; load the length of the emote (in tiles) into c
	ld a, [hli]
	ld c, a
	swap c
; load the emote pointer bank into b
	ld a, [hli]
	ld b, a
; load the VRAM destination into hl
	ld a, [hli]
	ld h, [hl]
	ld l, a
; if the emote has a length of 0, do not proceed (error handling)
	ld a, c
	and a
	ret z
	jmp Get2bpp

INCLUDE "data/sprites/emotes.asm"

INCLUDE "data/sprites/sprite_mons.asm"

INCLUDE "data/sprites/sprites.asm"

QueueBattleAnimation:
	ld hl, wActiveAnimObjects
	ld e, NUM_BATTLE_ANIM_STRUCTS
.loop
	ld a, [hl]
	and a
	jr z, .done
	ld bc, BATTLEANIMSTRUCT_LENGTH
	add hl, bc
	dec e
	jr nz, .loop
	scf
	ret

.done
	ld c, l
	ld b, h
	ld hl, wLastAnimObjectIndex
	inc [hl]
; InitBattleAnimation:
	ld hl, wBattleObjectTempID
	ld a, [hli]
	ld e, a
	ld d, [hl]
	ld hl, BattleAnimObjects
rept BATTLEANIMOBJ_LENGTH
	add hl, de
endr
	ld e, l
	ld d, h
	ld hl, BATTLEANIMSTRUCT_INDEX
	add hl, bc
	ld a, [wLastAnimObjectIndex]
	ld [hli], a ; BATTLEANIMSTRUCT_INDEX
	ld a, [de]
	inc de
	ld [hli], a ; BATTLEANIMSTRUCT_OAMFLAGS
	ld a, [de]
	inc de
	ld [hli], a ; BATTLEANIMSTRUCT_FIX_Y
	ld a, [de]
	inc de
	ld [hli], a ; BATTLEANIMSTRUCT_FRAMESET_ID
	ld a, [de]
	inc de
	ld [hli], a ; BATTLEANIMSTRUCT_FRAMESET_ID + 1
	ld a, [de]
	inc de
	ld [hli], a ; BATTLEANIMSTRUCT_FUNCTION
	ld a, [de]
	inc de
	ld [hli], a ; BATTLEANIMSTRUCT_PALETTE
	ld a, [de]
	call GetBattleAnimTileOffset
	ld [hli], a ; BATTLEANIMSTRUCT_TILEID
	ld a, [wBattleObjectTempXCoord]
	ld [hli], a ; BATTLEANIMSTRUCT_XCOORD
	ld a, [wBattleObjectTempYCoord]
	ld [hli], a ; BATTLEANIMSTRUCT_YCOORD
	xor a
	ld [hli], a ; BATTLEANIMSTRUCT_XOFFSET
	ld [hli], a ; BATTLEANIMSTRUCT_YOFFSET
	ld a, [wBattleObjectTempParam]
	ld [hli], a ; BATTLEANIMSTRUCT_PARAM
	xor a
	ld [hli], a ; BATTLEANIMSTRUCT_DURATION
	dec a
	ld [hli], a ; BATTLEANIMSTRUCT_FRAME
	xor a
	ld [hli], a ; BATTLEANIMSTRUCT_JUMPTABLE_INDEX
	ld [hli], a ; BATTLEANIMSTRUCT_VAR1
	ld [hl], a  ; BATTLEANIMSTRUCT_VAR2
	ret

BattleAnimOAMUpdate:
	call InitBattleAnimBuffer
	farcall GetBattleAnimFrame
	ld a, h
	cp HIGH(battleoamwait_command)
	jmp z, .done
	cp HIGH(battleoamdelete_command)
	jmp z, .delete
	ld d, h
	ld e, l
	ld hl, wBattleAnimTempOAMFlags
	ld a, [wBattleAnimTempFrameOAMFlags]
	xor [hl]
	and PRIORITY | Y_FLIP | X_FLIP
	ld [hl], a

	push bc
	call GetBattleAnimOAMPointer
	ld a, [wBattleAnimTempTileID]
	add [hl] ; tile offset
	ld [wBattleAnimTempTileID], a
	inc hl
	ld a, [hli] ; oam data length
	ld c, a
	ld a, [hli] ; oam data pointer
	ld h, [hl]
	ld l, a
	ld a, [wBattleAnimOAMPointerLo]
	ld e, a
	ld d, HIGH(wShadowOAM)

.loop
	; Y Coord
	ld a, [wBattleAnimTempYCoord]
	ld b, a
	ld a, [wBattleAnimTempYOffset]
	add b
	ld b, a
	push hl
	ld a, [hl]
	ld hl, wBattleAnimTempOAMFlags
	bit OAM_Y_FLIP, [hl]
	jr z, .no_yflip
	add $8
	cpl
	inc a
.no_yflip
	pop hl
	add b
	ld [de], a

	; X Coord
	inc hl
	inc de
	ld a, [wBattleAnimTempXCoord]
	ld b, a
	ld a, [wBattleAnimTempXOffset]
	add b
	ld b, a
	push hl
	ld a, [hl]
	ld hl, wBattleAnimTempOAMFlags
	bit OAM_X_FLIP, [hl]
	jr z, .no_xflip
	add $8
	cpl
	inc a
.no_xflip
	pop hl
	add b
	ld [de], a

	; Tile ID
	inc hl
	inc de
	ld a, [wBattleAnimTempTileID]
	add BATTLEANIM_BASE_TILE
	add [hl]
	ld [de], a

	; Attributes
	inc hl
	inc de
	ld a, [wBattleAnimTempOAMFlags]
	ld b, a
	ld a, [hl]
	xor b
	and PRIORITY | Y_FLIP | X_FLIP
	ld b, a
	ld a, [hl]
	and OBP_NUM
	or b
	ld b, a
	ld a, [wBattleAnimTempPalette]
	and PALETTE_MASK | VRAM_BANK_1
	or b
	ld [de], a

	inc hl
	inc de
	ld a, e
	ld [wBattleAnimOAMPointerLo], a
	cp LOW(wShadowOAMEnd)
	jr nc, .exit_set_carry
	dec c
	jr nz, .loop
	pop bc
	jr .done

.delete
	call DeinitBattleAnimation

.done
	and a
	ret

.exit_set_carry
	pop bc
	scf
	ret

InitBattleAnimBuffer:
	ld hl, BATTLEANIMSTRUCT_OAMFLAGS
	add hl, bc
	ld a, [hl]

	and PRIORITY
	ld [wBattleAnimTempOAMFlags], a
	xor a
	ld [wBattleAnimTempFrameOAMFlags], a
	ld hl, BATTLEANIMSTRUCT_PALETTE
	add hl, bc
	ld a, [hl]
	ld [wBattleAnimTempPalette], a
	ld hl, BATTLEANIMSTRUCT_FIX_Y
	add hl, bc
	ld a, [hl]
	ld [wBattleAnimTempFixY], a
	ld hl, BATTLEANIMSTRUCT_TILEID
	add hl, bc
	ld a, [hli]
	ld [wBattleAnimTempTileID], a
	ld a, [hli]
	ld [wBattleAnimTempXCoord], a
	ld a, [hli]
	ld [wBattleAnimTempYCoord], a
	ld a, [hli]
	ld [wBattleAnimTempXOffset], a
	ld a, [hli]
	ld [wBattleAnimTempYOffset], a

	ldh a, [hBattleTurn]
	and a
	ret z

	ld hl, BATTLEANIMSTRUCT_OAMFLAGS
	add hl, bc
	ld a, [hl]
	ld [wBattleAnimTempOAMFlags], a
	bit BATTLEANIMSTRUCT_OAMFLAGS_FIX_COORDS_F, [hl]
	ret z

	ld hl, BATTLEANIMSTRUCT_XCOORD
	add hl, bc
	ld a, [hli]
	cpl
	add (-10 * TILE_WIDTH) + 4 + 1
	ld [wBattleAnimTempXCoord], a
	ld a, [hli]
	ld d, a
	ld a, [wBattleAnimTempFixY]
	cp $ff
	jr nz, .vertical_flip
	ld a, 5 * TILE_WIDTH
	jr .done

.vertical_flip
	sub d
	push af
	push hl
	push bc
	ld hl, wFXAnimID
	ld a, [hli]
	ld b, [hl]
	ld c, a
	ld de, 2
	ld hl, .extra_offset_moves
	call IsInWordArray
	pop bc
	pop hl
	pop de
	sbc a
	and -(1 * TILE_WIDTH)
.done
	add d
	ld [wBattleAnimTempYCoord], a
	ld a, [hli]
	cpl
	inc a
	ld [wBattleAnimTempXOffset], a
	ret

.extra_offset_moves
	dw KINESIS
	dw SOFTBOILED
	dw MILK_DRINK
	dw -1

GetBattleAnimTileOffset:
	push hl
	push bc
	ld hl, wBattleAnimTileDict
	ld b, a
	ld c, NUM_BATTLEANIMTILEDICT_ENTRIES
.loop
	ld a, [hli]
	cp b
	jr z, .load
	inc hl
	dec c
	jr nz, .loop
	xor a
	jr .done

.load
	ld a, [hl]
.done
	pop bc
	pop hl
	ret

_ExecuteBGEffects:
	farjp ExecuteBGEffects

_QueueBGEffect:
	farjp QueueBGEffect

INCLUDE "data/battle_anims/objects.asm"

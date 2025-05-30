HasNoItems:
	ld a, [wNumItems]
	and a
	ret nz
	ld a, [wNumKeyItems]
	and a
	ret nz
	ld a, [wNumBalls]
	and a
	ret nz
	ld a, [wNumBerries]
	and a
	ret nz
	ld hl, wTMsHMs
	ld b, NUM_TMS + NUM_HMS
.loop
	ld a, [hli]
	and a
	jr nz, .done
	dec b
	jr nz, .loop
	scf
	ret
.done
	and a
	ret

TossItemFromPC:
	push de
	call PartyMonItemName
	farcall _CheckTossableItem
	ld a, [wItemAttributeValue]
	and a
	jr nz, .key_item
	ld hl, .ItemsTossOutHowManyText
	call MenuTextbox
	farcall SelectQuantityToToss
	push af
	call CloseWindow
	call ExitMenu
	pop af
	jr c, .quit
	ld hl, .ItemsThrowAwayText
	call MenuTextbox
	call YesNoBox
	push af
	call ExitMenu
	pop af
	jr c, .quit
	pop hl
	ld a, [wCurItemQuantity]
	call TossItem
	call PartyMonItemName
	ld hl, .ItemsDiscardedText
	call MenuTextbox
	call ExitMenu
	and a
	ret

.key_item
	call .CantToss
.quit
	pop hl
	scf
	ret

.ItemsTossOutHowManyText:
	text_far _ItemsTossOutHowManyText
	text_end

.ItemsThrowAwayText:
	text_far _ItemsThrowAwayText
	text_end

.ItemsDiscardedText:
	text_far _ItemsDiscardedText
	text_end

.CantToss:
	ld hl, .ItemsTooImportantText
	jmp MenuTextboxBackup

.ItemsTooImportantText:
	text_far _ItemsTooImportantText
	text_end

CantUseItem:
	ld hl, ItemsOakWarningText
	jmp MenuTextboxWaitButton

ItemsOakWarningText:
	text_far _ItemsOakWarningText
	text_end

PartyMonItemName:
	ld a, [wCurItem]
	ld [wNamedObjectIndex], a
	call GetItemName
	jmp CopyName1

CancelPokemonAction:
	farcall InitPartyMenuWithCancel
	farcall UnfreezeMonIcons
	ld a, 1
	ret

PokemonActionSubmenu:
	hlcoord 1, 15
	lb bc, 2, 18
	call ClearBox
	farcall MonSubmenu
	call GetCurNickname
	ld a, [wMenuSelection]
	ld hl, .Actions
	ld de, 3
	call IsInArray
	jr nc, .nothing

	inc hl
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp hl

.nothing
	xor a
	ret

.Actions:
	dbw MONMENUITEM_CUT,        MonMenu_Cut
	dbw MONMENUITEM_FLY,        MonMenu_Fly
	dbw MONMENUITEM_SURF,       MonMenu_Surf
	dbw MONMENUITEM_STRENGTH,   MonMenu_Strength
	dbw MONMENUITEM_FLASH,      MonMenu_Flash
	dbw MONMENUITEM_WHIRLPOOL,  MonMenu_Whirlpool
	dbw MONMENUITEM_DIG,        MonMenu_Dig
	dbw MONMENUITEM_TELEPORT,   MonMenu_Teleport
	dbw MONMENUITEM_SOFTBOILED, MonMenu_Softboiled_MilkDrink
	dbw MONMENUITEM_MILKDRINK,  MonMenu_Softboiled_MilkDrink
	dbw MONMENUITEM_HEADBUTT,   MonMenu_Headbutt
	dbw MONMENUITEM_WATERFALL,  MonMenu_Waterfall
	dbw MONMENUITEM_ROCKSMASH,  MonMenu_RockSmash
	dbw MONMENUITEM_SWEETSCENT, MonMenu_SweetScent
	dbw MONMENUITEM_STATS,      OpenPartyStats
	dbw MONMENUITEM_SWITCH,     SwitchPartyMons
	dbw MONMENUITEM_ITEM,       GiveTakePartyMonItem
	dbw MONMENUITEM_CANCEL,     CancelPokemonAction
	dbw MONMENUITEM_MOVE,       ManagePokemonMoves
	dbw MONMENUITEM_MAIL,       MonMailAction

SwitchPartyMons:
; Don't try if there's nothing to switch!
	ld a, [wPartyCount]
	cp 2
	jr c, .DontSwitch

	ld a, [wCurPartyMon]
	inc a
	ld [wSwitchMon], a

	farcall HoldSwitchmonIcon
	farcall InitPartyMenuNoCancel

	ld a, PARTYMENUACTION_MOVE
	ld [wPartyMenuActionText], a
	farcall WritePartyMenuTilemap
	farcall PlacePartyMenuText

	hlcoord 0, 1
	ld bc, SCREEN_WIDTH * 2
	ld a, [wSwitchMon]
	dec a
	rst AddNTimes
	ld [hl], "▷"
	call WaitBGMap
	call SetDefaultBGPAndOBP
	call DelayFrame

	farcall PartyMenuSelect
	bit B_BUTTON_F, b
	jr c, .DontSwitch

	farcall _SwitchPartyMons

	xor a
	ld [wPartyMenuActionText], a

	farcall LoadPartyMenuGFX
	farcall InitPartyMenuWithCancel
	farcall InitPartyMenuGFX

	ld a, 1
	ret

.DontSwitch:
	xor a
	ld [wPartyMenuActionText], a
	jmp CancelPokemonAction

GiveTakePartyMonItem:
; Eggs can't hold items!
	ld a, [wCurPartySpecies]
	cp EGG
	jr z, .cancel

	ld hl, GiveTakeItemMenuData
	call LoadMenuHeader
	call VerticalMenu
	call ExitMenu
	jr c, .cancel

	call GetCurNickname
	ld hl, wStringBuffer1
	ld de, wMonOrItemNameBuffer
	ld bc, MON_NAME_LENGTH
	rst CopyBytes
	ld a, [wMenuCursorY]
	cp 1
	jr nz, .take

	call LoadStandardMenuHeader
	call ClearPalettes
	call .GiveItem
	call ClearPalettes
	call LoadFontsBattleExtra
	call ExitMenu
	xor a
	ret

.take
	call TakePartyItem
	ld a, 3
	ret

.cancel
	ld a, 3
	ret

.GiveItem:
	ld hl, wItemFlags
	set IN_BAG_F, [hl]
	call GetItemToGive
	ret z
	call TryGiveItemToPartymon
	ld hl, wItemFlags
	res IN_BAG_F, [hl]
	ret

GetItemToGive:
; Returns nz if we got an item to give.
	call DepositSellInitPackBuffers
	; fallthrough
_GetItemToGive:
.loop
	call DepositSellPack

	ld a, [wPackUsedItem]
	and a
	ret z

	ld a, [wCurPocket]
	cp KEY_ITEM_POCKET
	jr z, .next

	call CheckTossableItem
	ld a, [wItemAttributeValue]
	and a
	jr nz, .next

	or 1
	ret

.next
	ld hl, ItemCantHeldText
	call MenuTextboxBackup
	jr .loop

PCGiveItem:
	ld hl, wItemFlags
	set IN_BAG_F, [hl]
	call DepositSellInitPackBuffers
.loop
	call _GetItemToGive
	jr z, .done

	; Ensure that we aren't trying to give Mail to a Pokémon in storage.
	ld a, [wCurItem]
	ld d, a
	farcall ItemIsMail
	jr nc, .item_ok

	ld a, [wBufferMonBox]
	and a
	jr z, .item_ok

	ld hl, CantPlaceMailInStorageText
	call MenuTextboxBackup
	jr .loop

.item_ok
	call PartyMonItemName
	call GiveItemToPokemon

	ld hl, wBufferMonNickname
	ld de, wMonOrItemNameBuffer
	ld bc, MON_NAME_LENGTH
	rst CopyBytes

	ld hl, PokemonHoldItemText
	call MenuTextboxBackup

	; Now, actually give the item.
	ld a, [wBufferMonSpecies]
	ld [wCurPartySpecies], a
	ld de, wCurItem
	ld a, [de]
	ld [wBufferMonItem], a
	farcall UpdateStorageBoxMonFromTemp

	; We know that if we're dealing with Mail, then we're giving to a partymon.
	; Thus, there's no harm in using party-specific code.
	ld a, [wBufferMonSlot]
	dec a
	ld [wCurPartyMon], a
	ld a, [wCurItem]
	ld d, a
	farcall ItemIsMail
	jr nc, .done
	call ComposeMailMessage

.done
	ld hl, wItemFlags
	res IN_BAG_F, [hl]
	ret

TryGiveItemToPartymon:
	call SpeechTextbox
	call PartyMonItemName
	call GetPartyItemLocation
	ld a, [hl]
	and a
	jr z, .give_item_to_mon

	push hl
	ld d, a
	farcall ItemIsMail
	pop hl
	jr c, .please_remove_mail
	ld a, [hl]
	jr .already_holding_item

.give_item_to_mon
	call GiveItemToPokemon
	ld hl, PokemonHoldItemText
	call MenuTextboxBackup
	jr GivePartyItem

.please_remove_mail
	ld hl, PokemonRemoveMailText
	jmp MenuTextboxBackup

.already_holding_item
	ld [wNamedObjectIndex], a
	call GetItemName
	ld hl, PokemonAskSwapItemText
	call StartMenuYesNo
	ret c

	call GiveItemToPokemon
	ld a, [wNamedObjectIndex]
	push af
	ld a, [wCurItem]
	ld [wNamedObjectIndex], a
	pop af
	ld [wCurItem], a
	call ReceiveItemFromPokemon
	jr nc, .bag_full

	ld hl, PokemonSwapItemText
	call MenuTextboxBackup
	ld a, [wNamedObjectIndex]
	ld [wCurItem], a
	jr GivePartyItem

.bag_full
	ld a, [wNamedObjectIndex]
	ld [wCurItem], a
	call ReceiveItemFromPokemon
	ld hl, ItemStorageFullText
	jmp MenuTextboxBackup

GivePartyItem:
	call GetPartyItemLocation
	ld a, [wCurItem]
	ld [hl], a
	ld d, a
	farcall ItemIsMail
	ret nc
	jmp ComposeMailMessage

TakePartyItem:
	call SpeechTextbox
	call GetPartyItemLocation
	ld a, [hl]
	and a
	jr z, .not_holding_item

	ld [wCurItem], a
	call ReceiveItemFromPokemon
	jr nc, .item_storage_full

	farcall ItemIsMail
	call GetPartyItemLocation
	ld a, [hl]
	ld [wNamedObjectIndex], a
	ld [hl], NO_ITEM
	call GetItemName
	ld hl, PokemonTookItemText
	jmp MenuTextboxBackup

.not_holding_item
	ld hl, PokemonNotHoldingText
	jmp MenuTextboxBackup

.item_storage_full
	ld hl, ItemStorageFullText
	jmp MenuTextboxBackup

GiveTakeItemMenuData:
	db MENU_SPRITE_ANIMS | MENU_BACKUP_TILES ; flags
	menu_coords 12, 12, SCREEN_WIDTH - 1, SCREEN_HEIGHT - 1
	dw .Items
	db 1 ; default option

.Items:
	db STATICMENU_CURSOR ; flags
	db 2 ; # items
	db "GIVE@"
	db "TAKE@"

PokemonSwapItemText:
	text_far _PokemonSwapItemText
	text_end

PokemonHoldItemText:
	text_far _PokemonHoldItemText
	text_end

PokemonRemoveMailText:
	text_far _PokemonRemoveMailText
	text_end

PokemonNotHoldingText:
	text_far _PokemonNotHoldingText
	text_end

ItemStorageFullText:
	text_far _ItemStorageFullText
	text_end

PokemonTookItemText:
	text_far _PokemonTookItemText
	text_end

PokemonAskSwapItemText:
	text_far _PokemonAskSwapItemText
	text_end

ItemCantHeldText:
	text_far _ItemCantHeldText
	text_end

CantPlaceMailInStorageText:
	text_far _CantPlaceMailInStorageText
	text_end

GetPartyItemLocation:
	push af
	ld a, MON_ITEM
	call GetPartyParamLocation
	pop af
	ret

ReceiveItemFromPokemon:
	ld a, 1
	ld [wItemQuantityChange], a
	ld hl, wNumItems
	jmp ReceiveItem

GiveItemToPokemon:
	ld a, 1
	ld [wItemQuantityChange], a
	ld hl, wNumItems
	jmp TossItem

StartMenuYesNo:
	call MenuTextbox
	call YesNoBox
	jmp ExitMenu

ComposeMailMessage:
	ld de, wTempMailMessage
	call _ComposeMailMessage
	ld hl, wPlayerName
	ld de, wTempMailAuthor
	ld bc, NAME_LENGTH - 1
	rst CopyBytes
	ld hl, wPlayerID
	ld bc, 2
	rst CopyBytes
	ld a, [wCurPartySpecies]
	ld [de], a
	inc de
	ld a, [wCurItem]
	ld [de], a
	ld a, [wCurPartyMon]
	ld hl, sPartyMail
	ld bc, MAIL_STRUCT_LENGTH
	rst AddNTimes
	ld d, h
	ld e, l
	ld hl, wTempMail
	ld bc, MAIL_STRUCT_LENGTH
	ld a, BANK(sPartyMail)
	call OpenSRAM
	rst CopyBytes
	jmp CloseSRAM

MonMailAction:
; If in the time capsule or trade center,
; selecting the mail only allows you to
; read the mail.
	ld a, [wLinkMode]
	cp LINK_TIMECAPSULE
	jr z, .read
	cp LINK_TRADECENTER
	jr z, .read

; Show the READ/TAKE/QUIT menu.
	ld hl, .MenuHeader
	call LoadMenuHeader
	call VerticalMenu
	call ExitMenu

; Interpret the menu.
	ld a, $3
	ret c
	ld a, [wMenuCursorY]
	cp $1
	jr z, .read
	cp $2
	jr z, TakeMail
	ld a, $3
	ret

.read
	farcall ReadPartyMonMail
	xor a
	ret

.MenuHeader:
	db MENU_BACKUP_TILES ; flags
	menu_coords 12, 10, SCREEN_WIDTH - 1, SCREEN_HEIGHT - 1
	dw .MenuData
	db 1 ; default option

.MenuData:
	db STATICMENU_CURSOR ; flags
	db 3 ; items
	db "READ@"
	db "TAKE@"
	db "QUIT@"

TakeMail:
	ld hl, .MailAskSendToPCText
	call StartMenuYesNo
	jr c, .RemoveMailToBag
	ld a, [wCurPartyMon]
	ld b, a
	farcall SendMailToPC
	jr c, .MailboxFull
	ld hl, .MailSentToPCText
	call MenuTextboxBackup
	jr .TookMail

.MailboxFull:
	ld hl, .MailboxFullText
	call MenuTextboxBackup
	jr .KeptMail

.RemoveMailToBag:
	ld hl, .MailLoseMessageText
	call StartMenuYesNo
	jr c, .KeptMail
	call GetPartyItemLocation
	ld a, [hl]
	ld [wCurItem], a
	call ReceiveItemFromPokemon
	jr nc, .BagIsFull
	call GetPartyItemLocation
	ld [hl], $0
	call GetCurNickname
	ld hl, .MailDetachedText
	call MenuTextboxBackup
	; fallthrough
.TookMail:
	scf
	jr .done

.BagIsFull:
	ld hl, .MailNoSpaceText
	call MenuTextboxBackup
	; fallthrough
.KeptMail:
	and a
.done
	ld a, $3
	ret

.MailLoseMessageText:
	text_far _MailLoseMessageText
	text_end

.MailDetachedText:
	text_far _MailDetachedText
	text_end

.MailNoSpaceText:
	text_far _MailNoSpaceText
	text_end

.MailAskSendToPCText:
	text_far _MailAskSendToPCText
	text_end

.MailboxFullText:
	text_far _MailboxFullText
	text_end

.MailSentToPCText:
	text_far _MailSentToPCText
	text_end

OpenPartyStats:
; PartyMon
	xor a
	ld [wMonType], a
	; fallthrough
_OpenPartyStats:
	call LoadStandardMenuHeader
	call ClearSprites
	call LowVolume
	predef StatsScreenInit
	; This ensures that MaxVolume works as it should if we're in the middle of
	; playing a cry.
	ld a, MAX_VOLUME
	ld [wLastVolume], a
	call MaxVolume
	xor a
	ld [wLastVolume], a
	call ExitMenu
	xor a
	ret

MonMenu_Cut:
	farcall CutFunction
	ld a, [wFieldMoveSucceeded]
	cp $1
	jr nz, .Fail
	ld b, $4
	ld a, $2
	ret

.Fail:
	ld a, $3
	ret

MonMenu_Fly:
	farcall FlyFunction
	ld a, [wFieldMoveSucceeded]
	cp $2
	jr z, .Fail
	and a
	jr z, .Error
	farcall StubbedTrainerRankings_Fly
	ld b, $4
	ld a, $2
	ret

.Fail:
	ld a, $3
	ret

.Error:
	xor a
	ret

MonMenu_Flash:
	farcall FlashFunction
	ld a, [wFieldMoveSucceeded]
	cp $1
	jr nz, .Fail
	ld b, $4
	ld a, $2
	ret

.Fail:
	ld a, $3
	ret

MonMenu_Strength:
	farcall StrengthFunction
	ld a, [wFieldMoveSucceeded]
	cp $1
	jr nz, .Fail
	ld b, $4
	ld a, $2
	ret

.Fail:
	ld a, $3
	ret

MonMenu_Whirlpool:
	farcall WhirlpoolFunction
	ld a, [wFieldMoveSucceeded]
	cp $1
	jr nz, .Fail
	ld b, $4
	ld a, $2
	ret

.Fail:
	ld a, $3
	ret

MonMenu_Waterfall:
	farcall WaterfallFunction
	ld a, [wFieldMoveSucceeded]
	cp $1
	jr nz, .Fail
	ld b, $4
	ld a, $2
	ret

.Fail:
	ld a, $3
	ret

MonMenu_Teleport:
	farcall TeleportFunction
	ld a, [wFieldMoveSucceeded]
	and a
	jr z, .Fail
	ld b, $4
	ld a, $2
	ret

.Fail:
	ld a, $3
	ret

MonMenu_Surf:
	farcall SurfFunction
	ld a, [wFieldMoveSucceeded]
	and a
	jr z, .Fail
	ld b, $4
	ld a, $2
	ret

.Fail:
	ld a, $3
	ret

MonMenu_Dig:
	farcall DigFunction
	ld a, [wFieldMoveSucceeded]
	cp $1
	jr nz, .Fail
	ld b, $4
	ld a, $2
	ret

.Fail:
	ld a, $3
	ret

MonMenu_Softboiled_MilkDrink:
	call .CheckMonHasEnoughHP
	jr nc, .NotEnoughHP
	farcall Softboiled_MilkDrinkFunction
	jr .finish

.NotEnoughHP:
	ld hl, .PokemonNotEnoughHPText
	call PrintText

.finish
	xor a
	ld [wPartyMenuActionText], a
	ld a, $3
	ret

.PokemonNotEnoughHPText:
	text_far _PokemonNotEnoughHPText
	text_end

.CheckMonHasEnoughHP:
; Need to have at least (MaxHP / 5) HP left.
	ld a, MON_MAXHP
	call GetPartyParamLocation
	ld a, [hli]
	ldh [hDividend + 0], a
	ld a, [hl]
	ldh [hDividend + 1], a
	ld a, 5
	ldh [hDivisor], a
	ld b, 2
	call Divide
	ld a, MON_HP + 1
	call GetPartyParamLocation
	ldh a, [hQuotient + 3]
	sub [hl]
	dec hl
	ldh a, [hQuotient + 2]
	sbc [hl]
	ret

MonMenu_Headbutt:
	farcall HeadbuttFunction
	ld a, [wFieldMoveSucceeded]
	cp $1
	jr nz, .Fail
	ld b, $4
	ld a, $2
	ret

.Fail:
	ld a, $3
	ret

MonMenu_RockSmash:
	farcall RockSmashFunction
	ld a, [wFieldMoveSucceeded]
	cp $1
	jr nz, .Fail
	ld b, $4
	ld a, $2
	ret

.Fail:
	ld a, $3
	ret

MonMenu_SweetScent:
	farcall SweetScentFromMenu
	ld b, $4
	ld a, $2
	ret

ChooseMoveToDelete:
	ld hl, wOptions
	ld a, [hl]
	push af
	set NO_TEXT_SCROLL, [hl]
	call LoadFontsBattleExtra
	call .ChooseMoveToDelete
	pop bc
	ld a, b
	ld [wOptions], a
	push af
	call ClearBGPalettes
	pop af
	ret

.ChooseMoveToDelete
	call SetUpMoveScreenBG
	ld de, DeleteMoveScreen2DMenuData
	call Load2DMenuData
	call SetUpMoveList
	ld hl, w2DMenuFlags1
	set _2DMENU_ENABLE_SPRITE_ANIMS_F, [hl]
	jr .enter_loop

.loop
	call ScrollingMenuJoypad
	bit B_BUTTON_F, a
	jr nz, .b_button
	bit A_BUTTON_F, a
	jr nz, .a_button

.enter_loop
	call PrepareToPlaceMoveData
	call PlaceMoveData
	jr .loop

.a_button
	and a
	jr .finish

.b_button
	scf

.finish
	push af
	xor a
	ld [wSwitchMon], a
	ld hl, w2DMenuFlags1
	res _2DMENU_ENABLE_SPRITE_ANIMS_F, [hl]
	call ClearSprites
	call ClearTilemap
	pop af
	ret

DeleteMoveScreen2DMenuData:
	db 3, 1 ; cursor start y, x
	db 3, 1 ; rows, columns
	db _2DMENU_ENABLE_SPRITE_ANIMS ; flags 1
	db 0 ; flags 2
	dn 2, 0 ; cursor offset
	db D_UP | D_DOWN | A_BUTTON | B_BUTTON ; accepted buttons

ManagePokemonMoves:
	ld a, [wCurPartySpecies]
	cp EGG
	jr z, .egg
	ld hl, wOptions
	ld a, [hl]
	push af
	set NO_TEXT_SCROLL, [hl]
	call MoveScreenLoop
	pop af
	ld [wOptions], a
	call ClearBGPalettes

.egg
	xor a
	ret

MoveScreenLoop:
	ld a, [wCurPartyMon]
	inc a
	ld [wPartyMenuCursor], a
	call SetUpMoveScreenBG
	call PlaceMoveScreenArrows
	ld de, MoveScreen2DMenuData
	call Load2DMenuData
.loop
	call SetUpMoveList
	ld hl, w2DMenuFlags1
	set _2DMENU_ENABLE_SPRITE_ANIMS_F, [hl]
	jr .skip_joy

.joy_loop
	call ScrollingMenuJoypad
	bit B_BUTTON_F, a
	jr nz, .b_button
	bit A_BUTTON_F, a
	jmp nz, .a_button
	bit D_RIGHT_F, a
	jr nz, .d_right
	bit D_LEFT_F, a
	jr nz, .d_left

.skip_joy
	call PrepareToPlaceMoveData
	ld a, [wSwappingMove]
	and a
	jr nz, .moving_move
	call PlaceMoveData
	jr .joy_loop

.moving_move
	ld a, " "
	hlcoord 1, 11
	ld bc, 8
	rst ByteFill
	hlcoord 1, 12
	lb bc, 5, SCREEN_WIDTH - 2
	call ClearBox
	hlcoord 1, 12
	ld de, String_MoveWhere
	rst PlaceString
	jr .joy_loop
.b_button
	call PlayClickSFX
	call WaitSFX
	ld a, [wSwappingMove]
	and a
	jmp z, .exit

	ld a, [wSwappingMove]
	ld [wMenuCursorY], a
	xor a
	ld [wSwappingMove], a
	hlcoord 1, 2
	lb bc, 8, SCREEN_WIDTH - 2
	call ClearBox
	jr .loop

.d_right
	ld a, [wSwappingMove]
	and a
	jr nz, .joy_loop

	ld a, [wCurPartyMon]
	ld b, a
	push bc
	call .cycle_right
	pop bc
	ld a, [wCurPartyMon]
	cp b
	jr z, .joy_loop
	jmp MoveScreenLoop

.d_left
	ld a, [wSwappingMove]
	and a
	jr nz, .joy_loop
	ld a, [wCurPartyMon]
	ld b, a
	push bc
	call .cycle_left
	pop bc
	ld a, [wCurPartyMon]
	cp b
	jmp z, .joy_loop
	jmp MoveScreenLoop

.cycle_right
	ld a, [wCurPartyMon] ; no-optimize Inefficient WRAM increment/decrement (value is needed in a)
	inc a
	ld [wCurPartyMon], a
	ld c, a
	ld b, 0
	ld hl, wPartySpecies
	add hl, bc
	ld a, [hl]
	cp -1
	jr z, .cycle_left
	cp EGG
	ret nz
	jr .cycle_right

.cycle_left
	ld a, [wCurPartyMon]
	and a
	ret z
.cycle_left_loop
	ld a, [wCurPartyMon] ; no-optimize Inefficient WRAM increment/decrement (value is needed in a)
	dec a
	ld [wCurPartyMon], a
	ld c, a
	ld b, 0
	ld hl, wPartySpecies
	add hl, bc
	ld a, [hl]
	cp EGG
	ret nz
	ld a, [wCurPartyMon]
	and a
	jr z, .cycle_right
	jr .cycle_left_loop

.a_button
	call PlayClickSFX
	call WaitSFX
	ld a, [wSwappingMove]
	and a
	jr nz, .place_move
	ld a, [wMenuCursorY]
	ld [wSwappingMove], a
	call PlaceHollowCursor
	jmp .moving_move

.place_move
	ld hl, wPartyMon1Moves
	ld bc, PARTYMON_STRUCT_LENGTH
	ld a, [wCurPartyMon]
	rst AddNTimes
	push hl
	call .copy_move
	pop hl
	ld bc, wPartyMon1PP - wPartyMon1Moves
	add hl, bc
	call .copy_move
	ld a, [wBattleMode]
	jr z, .swap_moves
	ld hl, wBattleMonMoves
	ld bc, wBattleMonStructEnd - wBattleMon
	ld a, [wCurPartyMon]
	rst AddNTimes
	push hl
	call .copy_move
	pop hl
	ld bc, wBattleMonPP - wBattleMonMoves
	add hl, bc
	call .copy_move

.swap_moves
	ld de, SFX_SWITCH_POKEMON
	call PlaySFX
	call WaitSFX
	ld de, SFX_SWITCH_POKEMON
	call PlaySFX
	call WaitSFX
	hlcoord 1, 2
	lb bc, 8, 18
	call ClearBox
	hlcoord 10, 10
	lb bc, 1, 9
	call ClearBox
	jmp .loop

.copy_move
	push hl
	ld a, [wMenuCursorY]
	dec a
	ld c, a
	ld b, 0
	add hl, bc
	ld d, h
	ld e, l
	pop hl
	ld a, [wSwappingMove]
	dec a
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [de]
	ld b, [hl]
	ld [hl], a
	ld a, b
	ld [de], a
	ret

.exit
	xor a
	ld [wSwappingMove], a
	ld hl, w2DMenuFlags1
	res _2DMENU_ENABLE_SPRITE_ANIMS_F, [hl]
	call ClearSprites
	jmp ClearTilemap

MoveScreen2DMenuData:
	db 3, 1 ; cursor start y, x
	db 3, 1 ; rows, columns
	db _2DMENU_ENABLE_SPRITE_ANIMS ; flags 1
	db 0 ; flags 2
	dn 2, 0 ; cursor offsets
	db D_UP | D_DOWN | D_LEFT | D_RIGHT | A_BUTTON | B_BUTTON ; accepted buttons

String_MoveWhere:
	db "Where?@"

SetUpMoveScreenBG:
	call ClearBGPalettes
	call ClearTilemap
	call ClearSprites
	xor a
	ldh [hBGMapMode], a
	farcall LoadStatsScreenPageTilesGFX
	farcall ClearSpriteAnims2
	ld a, [wCurPartyMon]
	ld e, a
	ld d, 0
	ld hl, wPartySpecies
	add hl, de
	ld a, [hl]
	ld [wTempIconSpecies], a
	ld e, MONICON_MOVES
	farcall LoadMenuMonIcon
	hlcoord 0, 1
	lb bc, 9, 18
	call Textbox
	hlcoord 0, 11
	lb bc, 5, 18
	call Textbox
	hlcoord 2, 0
	lb bc, 2, 3
	call ClearBox
	xor a
	ld [wMonType], a
	ld hl, wPartyMonNicknames
	ld a, [wCurPartyMon]
	call GetNickname
	hlcoord 5, 1
	rst PlaceString
	push bc
	farcall CopyMonToTempMon
	pop hl
	call PrintLevel
	ld hl, wPlayerHPPal
	call SetHPPal
	ld b, SCGB_MOVE_LIST
	call GetSGBLayout
	hlcoord 16, 0
	lb bc, 1, 3
	jmp ClearBox

SetUpMoveList:
	xor a
	ldh [hBGMapMode], a
	ld [wSwappingMove], a
	ld [wMonType], a
	predef CopyMonToTempMon
	ld hl, wTempMonMoves
	ld de, wListMoves_MoveIndicesBuffer
	ld bc, NUM_MOVES
	rst CopyBytes
	ld a, SCREEN_WIDTH * 2
	ld [wListMovesLineSpacing], a
	hlcoord 2, 3
	predef ListMoves
	hlcoord 10, 4
	predef ListMovePP
	call WaitBGMap
	call SetDefaultBGPAndOBP
	ld a, [wNumMoves]
	inc a
	ld [w2DMenuNumRows], a
	hlcoord 0, 11
	lb bc, 5, 18
	jmp Textbox

PrepareToPlaceMoveData:
	ld hl, wPartyMon1Moves
	ld bc, PARTYMON_STRUCT_LENGTH
	ld a, [wCurPartyMon]
	rst AddNTimes
	ld a, [wMenuCursorY]
	dec a
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [hl]
	ld [wCurSpecies], a
	hlcoord 1, 12
	lb bc, 5, 18
	jmp ClearBox

PlaceMoveData:
	xor a
	ldh [hBGMapMode], a
	
; print UI elements
	hlcoord 0, 10
	ld de, String_MoveType_Top
	rst PlaceString
	hlcoord 0, 11
	ld de, String_MoveType_Bottom
	rst PlaceString
	hlcoord 1, 11
	ld de, String_MoveAtk
	rst PlaceString
	hlcoord 1, 12
	ld de, String_MoveAcc
	rst PlaceString
	hlcoord 1, 13
	ld de, String_MoveEff
	rst PlaceString
	hlcoord 6, 12

; Print move effect chance
	ld a, [wCurSpecies]
	ld l, a
	ld a, MOVE_CHANCE
	call GetMoveAttribute
	cp 1
	jr c, .if_null_chance
	call ConvertPercentages
	ld [wTextDecimalByte], a
	ld de, wTextDecimalByte
	lb bc, 1, 3
	hlcoord 5, 13
	call PrintNum
	jr .skip_null_chance

.if_null_chance
	ld de, String_MoveNoPower
	ld bc, 3
	hlcoord 5, 13
	call PlaceString

.skip_null_chance

; Print move accuracy
    ld a, [wCurSpecies]
    ld l, a
    ld a, MOVE_ACC
    call GetMoveAttribute
    call ConvertPercentages
    ld [wTextDecimalByte], a
    ld de, wTextDecimalByte
    lb bc, 1, 3
    hlcoord 5, 12
    call PrintNum

; print move type
	ld a, [wCurSpecies]
	ld b, a
	farcall GetMoveCategoryName
	hlcoord 10, 13 ; Phys / Spec / Status
	ld [hl], "/"
	inc hl
	ld de, wStringBuffer1
	call PlaceString	
	ld a, [wCurSpecies]
	ld b, a
	hlcoord 10, 12  ; Type
	predef PrintMoveType

; print move power
	ld a, [wCurSpecies]
	ld l, a
	ld a, MOVE_POWER
	call GetMoveAttribute
	hlcoord 5, 11
	cp 2
	jr c, .no_power
	ld [wTextDecimalByte], a
	ld de, wTextDecimalByte
	lb bc, 1, 3
	call PrintNum
	jr .description

.no_power
	ld de, String_MoveNoPower
	rst PlaceString

; print move description 
.description
	hlcoord 1, 14
	predef PrintMoveDescription
	ld a, $1
	ldh [hBGMapMode], a
	ret

; This converts values out of 256 into a value
; out of 100. It achieves this by multiplying
; the value by 100 and dividing it by 256.
ConvertPercentages:

	; Overwrite the "hl" register.
	ld l, a
	ld h, 0
	push af

	; Multiplies the value of the "hl" register by 3.
	add hl, hl
	add a, l
	ld l, a
	adc h
	sub l
	ld h, a

	; Multiplies the value of the "hl" register
	; by 8. The value of the "hl" register
	; is now 24 times its original value.
	add hl, hl
	add hl, hl
	add hl, hl

	; Add the original value of the "hl" value to itself,
	; making it 25 times its original value.
	pop af
	add a, l
	ld l, a
	adc h
	sbc l
	ld h, a

	; Multiply the value of the "hl" register by
	; 4, making it 100 times its original value.
	add hl, hl
	add hl, hl

	; Set the "l" register to 0.5, otherwise the rounded
	; value may be lower than expected. Round the
	; high byte to nearest and drop the low byte.
	ld l, 0.5
	sla l
	sbc a
	and 1
	add a, h
	ret

; UI elements
String_MoveType_Top:
	db "┌────────┐@"
String_MoveType_Bottom:
	db "│        └@"
String_MoveAtk:
	db "ATK/@"
String_MoveAcc:
	db "ACC/@"
String_MoveEff:
	db "EFF/@"
String_MoveNoPower:
	db "---@"

PlaceMoveScreenArrows:
	call PlaceMoveScreenLeftArrow
	jr PlaceMoveScreenRightArrow

PlaceMoveScreenLeftArrow:
	ld a, [wCurPartyMon]
	and a
	ret z
	ld c, a
	ld e, a
	ld d, 0
	ld hl, wPartyCount
	add hl, de
.loop
	ld a, [hl]
	and a
	jr z, .prev
	cp MON_TABLE_ENTRIES + 1
	jr c, .legal

.prev
	dec hl
	dec c
	jr nz, .loop
	ret

.legal
	hlcoord 16, 0
	ld [hl], "◀"
	ret

PlaceMoveScreenRightArrow:
	ld a, [wCurPartyMon]
	inc a
	ld c, a
	ld a, [wPartyCount]
	cp c
	ret z
	ld e, c
	ld d, 0
	ld hl, wPartySpecies
	add hl, de
.loop
	ld a, [hl]
	cp -1
	ret z
	and a
	jr z, .next
	cp MON_TABLE_ENTRIES + 1
	jr c, .legal

.next
	inc hl
	jr .loop

.legal
	hlcoord 18, 0
	ld [hl], "▶"
	ret

Adjust_percent:
	; hMultiplicand 
	; hMultiplier. Result in hProduct.
	ldh [hMultiplicand], a
	ld a, 100
	ldh [hMultiplier], a
	call Multiply
	; Divide hDividend length b (max 4 bytes) by hDivisor. Result in hQuotient.
	; All values are big endian.
	ld b, 2
	; ldh a, [hProduct]
	; ldh [hDividend], a
	ld a, 255
	ldh [hDivisor], a
	call Divide
	ldh a, [hQuotient + 3]
	cp 100
	ret z
	inc a
	ret

	object_const_def
	const JOHTOPOKECENTER2F_TRADE_RECEPTIONIST
	const JOHTOPOKECENTER2F_BATTLE_RECEPTIONIST
	const JOHTOPOKECENTER2F_TIME_CAPSULE_RECEPTIONIST

JohtoPokecenter2F_MapScripts:
	def_scene_scripts

	def_callbacks

JohtoLinkReceptionistScript_Trade:
	jumptextfaceplayer NotImplementedText

JohtoLinkReceptionistScript_Battle:
	jumptextfaceplayer NotImplementedText

JohtoLinkReceptionistScript_TimeCapsule:
	jumptextfaceplayer NotImplementedText

NotImplementedText:
	text "Hi! This is not"
	line "implemented!"
	done

JohtoPokecenter2F_MapEvents:
	db 0, 0 ; filler

	def_warp_events
	warp_event  0,  7, JOHTO_POKECENTER_2F, -1

	def_coord_events

	def_bg_events


	def_object_events
	object_event  5,  2, SPRITE_LINK_RECEPTIONIST, SPRITEMOVEDATA_STANDING_DOWN, 0, 0, -1, -1, PAL_NPC_GREEN, OBJECTTYPE_SCRIPT, 0, JohtoLinkReceptionistScript_Trade, -1
	object_event  9,  2, SPRITE_LINK_RECEPTIONIST, SPRITEMOVEDATA_STANDING_DOWN, 0, 0, -1, -1, PAL_NPC_GREEN, OBJECTTYPE_SCRIPT, 0, JohtoLinkReceptionistScript_Battle, -1
	object_event 13,  3, SPRITE_LINK_RECEPTIONIST, SPRITEMOVEDATA_STANDING_DOWN, 0, 0, -1, -1, PAL_NPC_GREEN, OBJECTTYPE_SCRIPT, 0, JohtoLinkReceptionistScript_TimeCapsule, -1

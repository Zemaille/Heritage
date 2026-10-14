	object_const_def
	const SALTMARSHGATE_OFFICER1
	const SALTMARSHGATE_OFFICER2


SaltMarshGate_MapScripts:
	def_scene_scripts

	def_callbacks


SaltMarshGateOfficerScript:
	faceplayer
	opentext 
	writetext SaltMarshFloodedText
	waitbutton
	closetext
	end

SaltMarshFloodedText:
	text "The Olivine Salt"
	line "Marsh is currently"
	cont "flooded."
	done

SaltMarshGateContestOfficerScript:
	faceplayer
	opentext 
	writetext SaltMarshTournamentText
	waitbutton
	closetext
	end

SaltMarshTournamentText:
	text "A bunch of people"
	line "are all battling"

	para "deep in the Salt"
	line "Marsh."
	done

SaltMarshGate_MapEvents:
	db 0, 0 ; filler

	def_warp_events
	warp_event  4,  7, ROUTE_40, 1
	warp_event  5,  7, ROUTE_40, 1
	warp_event  4,  0, SALTMARSHSE, 1
	warp_event  5,  0, SALTMARSHSE, 2

	def_coord_events

	def_bg_events

	def_object_events
	object_event  0,  4, SPRITE_OFFICER, SPRITEMOVEDATA_STANDING_RIGHT, 0, 0, -1, -1, PAL_NPC_GREEN, OBJECTTYPE_SCRIPT, 0, SaltMarshGateOfficerScript, -1
	object_event  9,  3, SPRITE_OFFICER, SPRITEMOVEDATA_STANDING_LEFT, 0, 0, -1, -1, PAL_NPC_GREEN, OBJECTTYPE_SCRIPT, 0, SaltMarshGateContestOfficerScript, -1

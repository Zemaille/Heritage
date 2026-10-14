	object_const_def

CianwoodCave2F_MapScripts:
	def_scene_scripts

	def_callbacks

CianwoodCave2F_MapEvents:
	db 0, 0 ; filler

	def_warp_events
	warp_event 11, 33, CIANWOOD_CAVE_1F, 2
	warp_event  5,  7, CIANWOOD_CAVE_3F, 1 ; A cave
	warp_event 15,  7, CIANWOOD_CAVE_3F, 2 ; B Cave
	warp_event 15, 29, CIANWOOD_CAVE_3F, 3 ; Return

	def_coord_events

	def_bg_events


	def_object_events


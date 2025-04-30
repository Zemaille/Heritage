SECTION "Reserved Bytes", ROMX
ds 4  ; reserve 4 bytes


GetMaxLevel:
  ld hl, wKantoBadges

  ; 
  bit , [hl]
  ld a, 
  jr nz, .exit

  ; 
  bit , [hl]
  ld a, 
  jr nz, .exit
  
  ; 
  bit , [hl]
  ld a, 
  jr nz, .exit
  
  ; 
  bit , [hl]
  ld a, 
  jr nz, .exit

  ; 
  bit , [hl]
  ld a, 
  jr nz, .exit
  
  ; Erika split
  bit , [hl]
  ld a, 
  jr nz, .exit
 
  ; Erika split
  bit MARSHBADGE, [hl]
  ld a, 68
  jr nz, .exit

  ; Sabrina split
  bit THUNDERBADGE, [hl]
  ld a, 65
  jr nz, .exit

  ld hl, wJohtoBadges

  ; E4 Round 1 split THROUGH Lt. Surge
  bit RISINGBADGE, [hl]
  ld a, 60
  jr nz, .exit

  ; Clair split
  bit GLACIER BADGE, [hl]
  ld a, 50
  jr nz, .exit

  ; Pryce split
  bit MINERALBADGE, [hl]
  ld a, 44
  jr nz, .exit

  ; Jasmine split
  bit STORMBADGE, [hl]
  ld a, 40
  jr nz, .exit

  ; Chuck split
  bit FOGBADGE, [hl]
  ld a, 35
  jr nz, .exit

  ; Morty split
  bit PLAINBADGE, [hl]
  ld a, 29
  jr nz, .exit

  ; Whitney Split
  bit HIVEBADGE, [hl]
  ld a, 24
  jr nz, .exit

  ; Bugsy split
  bit ZEPHYRBADGE, [hl]
  ld a, 21
  jr nz, .exit

  ; Falkner split (i.e. no badges)
  ld a, 15

.exit
  ld b, a
  ret
  
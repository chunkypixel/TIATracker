; =====================================================================
; Variables
; Note: For batari Basic you will need to remove the Permanent and 
;       Temporary variables from file 'track_variables.asm' and instead 
;       insert the batari Basic variables from file 
;       'tiatracker_batari_variables.bas' into your source.
;       You will receive a compilation error if you don't
; =====================================================================
        include "tiatracker/track/track_variables.asm"

; =====================================================================
; Initialise
; =====================================================================
.tiatrackerinit
        include "tiatracker/track/track_init.asm"
        rts

; =====================================================================
; Player
; =====================================================================
.tiatrackerplay
        include "tiatracker/tiatracker_player.asm"
        rts

; =====================================================================
; Data
; =====================================================================   
        include "tiatracker/track/track_trackdata.asm"
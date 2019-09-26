; TIATracker music player
; Copyright 2016 Andre "Kylearan" Wichmann
; Website: https://bitbucket.org/kylearan/tiatracker
; Email: andre.wichmann@gmx.de
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;   http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.

; Song author: 
; Song name: 

; @com.wudsn.ide.asm.hardware=ATARI2600

; =====================================================================
; Initialize music.
; Set tt_cur_pat_index_c0/1 to the indexes of the first patterns from
; tt_SequenceTable for each channel.
; Set tt_timer and tt_cur_note_index_c0/1 to 0.
; All other variables can start with any value.
; =====================================================================
        lda #0
        sta tt_cur_pat_index_c0
        lda #37
        sta tt_cur_pat_index_c1
        ; the rest should be 0 already from startup code. If not,
        ; set the following variables to 0 manually:
        ; - tt_timer
        ; - tt_cur_pat_index_c0
        ; - tt_cur_pat_index_c1
        ; - tt_cur_note_index_c0
        ; - tt_cur_note_index_c1


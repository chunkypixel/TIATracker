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

; Song author: Bomb the bass / covered by Glafouk
; Song name: Miniblast

; @com.wudsn.ide.asm.hardware=ATARI2600

; =====================================================================
; Flags
; =====================================================================

; 1: Global song speed, 0: Each pattern has individual speed
TT_GLOBAL_SPEED         = 1
; duration (number of TV frames) of a note
TT_SPEED                = 4
; duration of odd frames (needs TT_USE_FUNKTEMPO)
TT_ODD_SPEED            = 4

; 1: Overlay percussion, +40 bytes
TT_USE_OVERLAY          = 0
; 1: Melodic instrument slide, +9 bytes
TT_USE_SLIDE            = 0
; 1: Goto pattern, +8 bytes
TT_USE_GOTO             = 1
; 1: Odd/even rows have different SPEED values, +7 bytes
TT_USE_FUNKTEMPO        = 0
; If the very first notes played on each channel are not PAUSE, HOLD or
; SLIDE, i.e. if they start with an instrument or percussion, then set
; this flag to 0 to save 2 bytes.
; 0: +2 bytes
TT_STARTS_WITH_NOTES    = 1


; =====================================================================
; For batari Basic these variables need to be removed!!!
; =====================================================================

; =====================================================================
; Permanent variables. These are states needed by the player.
; =====================================================================
;tt_timer                ds 1    ; current music timer value
;tt_cur_pat_index_c0     ds 1    ; current pattern index into tt_SequenceTable
;tt_cur_pat_index_c1     ds 1
;tt_cur_note_index_c0    ds 1    ; note index into current pattern
;tt_cur_note_index_c1    ds 1
;tt_envelope_index_c0    ds 1    ; index into ADSR envelope
;tt_envelope_index_c1    ds 1
;tt_cur_ins_c0           ds 1    ; current instrument
;tt_cur_ins_c1           ds 1


; =====================================================================
; Temporary variables. These will be overwritten during a call to the
; player routine, but can be used between calls for other things.
; =====================================================================
;tt_ptr                  ds 2

; =====================================================================
; TIATracker batari Basic and 7800basic Variables
; These variables need to be included at the top of your game
; If these clash with existing variables change their var reference
; =====================================================================

 dim tt_timer = a                   ; current music timer value
 dim tt_cur_pat_index_c0 = b        ; current pattern index into tt_SequenceTable
 dim tt_cur_pat_index_c1 = c
 dim tt_cur_note_index_c0 = d       ; note index into current pattern
 dim tt_cur_note_index_c1 = e
 dim tt_envelope_index_c0 = f       ; index into ADSR envelope
 dim tt_envelope_index_c1 = g
 dim tt_cur_ins_c0 = h              ; current instrument
 dim tt_cur_ins_c1 = i
 dim tt_ptr = j.k
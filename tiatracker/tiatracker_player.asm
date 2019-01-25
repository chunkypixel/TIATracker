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

; =====================================================================
; TIATracker Player
; =====================================================================
tt_PlayerStart:

; PLANNED PLAYER VARIANTS:
; - RAM, speed, player ROM: c0/c1 patterns have same length
; - RAM: Pack 2 values (out of cur_pat_index, cur_note_index, envelope_index)
;       into one and use lsr/asl to unpack them, allowing only ranges of
;       16/16 or 32/8 for them, depending on number of patterns, max
;       pattern size and max ADSR size
; - ROM: Check if tt_SequenceTable can hold ptrs directly without indexing
;       tt_PatternPtrLo/Hi. Can be smaller if not many patterns get repeated
;       (saves table and decode routine)
; - Speed: Inline tt_CalcInsIndex
; - Speed: Store ptr to current note in RAM instead of reconstructing it?
;       Might also save the need for cur_note_index


; ---------------------------------------------------------------------
; Helper macro: Retrieves current note. May advance pattern if needed.
; Becomes a subroutine if TT_USE_OVERLAY is used.
; ---------------------------------------------------------------------
    MAC TT_FETCH_CURRENT_NOTE
        ; construct ptr to pattern
.constructPatPtr:
        ldy tt_cur_pat_index_c0,x       ; get current pattern (index into tt_SequenceTable)
        lda tt_SequenceTable,y
    IF TT_USE_GOTO = 1
        bpl .noPatternGoto
        and #%01111111                  ; mask out goto bit to get pattern number
        sta tt_cur_pat_index_c0,x       ; store goto'ed pattern index
        bpl .constructPatPtr            ; unconditional
.noPatternGoto:
    ENDIF
        tay
        lda tt_PatternPtrLo,y
        sta tt_ptr
        lda tt_PatternPtrHi,y
        sta tt_ptr+1
        ; get new note
    IF TT_USE_OVERLAY = 0
        ldy tt_cur_note_index_c0,x
    ELSE
        ; If the V flag is set and if the new note is an instrument,
        ; it means it got pre-fetched by an overlay percussion, it has
        ; to remain in sustain.
        clv
        ; check if note had been pre-fetched by overlay perc already
        lda tt_cur_note_index_c0,x
        bpl .notPrefetched
        ; If so, remove flag
        and #%01111111
        sta tt_cur_note_index_c0,x
        ; Set V flag for later
        bit tt_Bit6Set
.notPrefetched:
        tay
    ENDIF
        lda (tt_ptr),y
        ; pre-process new note
        ; 7..5: instrument (1..7), 4..0 (0..31): frequency
        ; 0/0: End of pattern
        bne .noEndOfPattern
        ; End of pattern: Advance to next pattern
        sta tt_cur_note_index_c0,x      ; a is 0
        inc tt_cur_pat_index_c0,x
        bne .constructPatPtr            ; unconditional
.noEndOfPattern:
    ENDM


; ---------------------------------------------------------------------
; Music player entry. Call once per frame.
; ---------------------------------------------------------------------
; NOTE: this is casuing compile issues in bB but appears 
;       to cause no issues removing it
;tt_Player SUBROUTINE    
        ; ==================== Sequencer ====================
        ; Decrease speed timer
        dec tt_timer
        bpl .noNewNote
        
        ; Timer ran out: Do sequencer
        ; Advance to next note
        ldx #1                          ; 2 channels
.advanceLoop:
    IF TT_USE_OVERLAY = 1
        jsr tt_FetchNote
    ELSE
        TT_FETCH_CURRENT_NOTE
    ENDIF
        ; Parse new note from pattern
        cmp #TT_INS_PAUSE
    IF TT_USE_SLIDE = 0
        bcc .finishedNewNote	
        bne .newNote
    ELSE
        beq .pause
        bcs .newNote

        ; --- slide/hold ---
        ; Adjust frequency and hold note in sustain.
        ; composer/tracker has to make sure that no unwanted
        ; under/overflow happens.
        ; Note: f = f + (8-(16-x)) = x + f - 8
        adc tt_cur_ins_c0,x             ; carry is clear after cmp
        sec
        sbc #8
        sta tt_cur_ins_c0,x
        bcs .finishedNewNote            ; unconditional, since legally no underflow can happen (ins>0 or HOLD for ins=0)
    ENDIF
  
        ; --- pause ---
.pause:
        ; Get release index for current instrument. Since a pause can
        ; only follow an instrument, we don't need to handle percussion
        ; or commands.
        lda tt_cur_ins_c0,x
        jsr tt_CalcInsIndex
        lda tt_InsReleaseIndexes-1,y    ; -1 b/c instruments start at #1
        ; Put it into release. Skip junk byte so index no longer indicates
        ; sustain phase.
        clc
        adc #1
        bcc .storeADIndex               ; unconditional

; ---------------------------------------------------------------------
; Helper subroutine to minimize ROM footprint. Will be inlined if
; TT_USE_OVERLAY is not used.
; Interleaved here so player can be inlined.
; ---------------------------------------------------------------------
    IF TT_USE_OVERLAY = 1
tt_FetchNote:
        TT_FETCH_CURRENT_NOTE
        rts
    ENDIF


        ; --- start instrument or percussion ---
.newNote:
        sta tt_cur_ins_c0,x             ; set new instrument
        ; Instrument or percussion?
        cmp #TT_FREQ_MASK+1
        bcs .startInstrument

        ; --- start percussion ---
        ; Get index of envelope
        tay
        ; -TT_FIRST_PERC because percussion start with TT_FIRST_PERC
        lda tt_PercIndexes-TT_FIRST_PERC,y
        bne .storeADIndex               ; unconditional, since index values are >0

        ; --- start instrument ---
.startInstrument:
    IF TT_USE_OVERLAY = 1
        ; If V flag is set, this note had been pre-fetched. That means
        ; it should remain in sustain.
        bvs .finishedNewNote
    ENDIF
        ; Put note into attack/decay
        jsr tt_CalcInsIndex
        lda tt_InsADIndexes-1,y         ; -1 because instruments start at #1
.storeADIndex:
        sta tt_envelope_index_c0,x      

        ; --- Finished parsing new note ---
.finishedNewNote:
        ; increase note index into pattern
        inc tt_cur_note_index_c0,x
        ; loop over channels
.sequencerNextChannel:
        dex
        bpl .advanceLoop

        ; Reset timer value
    IF TT_GLOBAL_SPEED = 0
        ; Get timer value for current pattern in channel 0
        ldx tt_cur_pat_index_c0         ; get current pattern (index into tt_SequenceTable)
        ldy tt_SequenceTable,x          ; Current pattern index now in y
      IF TT_USE_FUNKTEMPO = 0
        lda tt_PatternSpeeds,y
        sta tt_timer
      ELSE
        ; Test for odd/even frame
        lda tt_cur_note_index_c0
        lsr
        lda tt_PatternSpeeds,y          ; does not affect carry flag
        bcc .evenFrame
        and #$0f                        ; does not affect carry flag
        bcs .storeFunkTempo        
.evenFrame:
        lsr
        lsr
        lsr
        lsr
.storeFunkTempo:
        sta tt_timer
      ENDIF   ; TT_USE_FUNKTEMPO = 0

    ELSE
        ; Global tempo
        ldx #TT_SPEED-1
      IF TT_USE_FUNKTEMPO = 1
        lda tt_cur_note_index_c0
        lsr
        bcc .noOddFrame
        ldx #TT_ODD_SPEED-1
.noOddFrame:
      ENDIF   ; TT_USE_FUNKTEMPO = 1
        stx tt_timer
    ENDIF   ; TT_GLOBAL_SPEED = 0

        ; No new note to process
.noNewNote:

        ; ==================== Update registers ====================
        ldx #1                          ; 2 channels
.updateLoop:
        ; Percussion or melodic instrument?
        lda tt_cur_ins_c0,x
    IF TT_STARTS_WITH_NOTES = 0
        ; This branch can be removed if track starts with a note in each channel
        beq .afterAudioUpdate
    ENDIF
        cmp #TT_FREQ_MASK+1
        bcs .instrument                 ; Melodic instrument

        ; --- Percussion: Get envelope index ---
        ldy tt_envelope_index_c0,x
        ; Set AUDC and AUDV value from envelope
        lda tt_PercCtrlVolTable-1,y     ; -1 because values are stored +1
        beq .endOfPercussion            ; 0 means end of percussion data
        inc tt_envelope_index_c0,x      ; if end not reached: advance index
.endOfPercussion:
        sta AUDV0,x
        lsr
        lsr
        lsr
        lsr
        sta AUDC0,x     
        ; Set AUDF
        lda tt_PercFreqTable-1,y        ; -1 because values are stored +1
        ; Bit 7 (overlay) might be set, but is unused in AUDF
        sta AUDF0,x
    IF TT_USE_OVERLAY = 1
        bpl .afterAudioUpdate
        ; Overlay percussion: Fetch next note out of order
        jsr tt_FetchNote
        ; Only do something if it's a melodic instrument
        cmp #TT_FREQ_MASK+1
        bcc .afterAudioUpdate
        ; Instrument: Put into sustain
        sta tt_cur_ins_c0,x             ; set new instrument
        jsr tt_CalcInsIndex
        lda tt_InsSustainIndexes-1,y    ; -1 because instruments start at #1
        sta tt_envelope_index_c0,x      
        ; Set prefetch flag. asl-sec-ror is smaller than lda-ora #128-sta
        asl tt_cur_note_index_c0,x
        sec
        ror tt_cur_note_index_c0,x
        bmi .afterAudioUpdate           ; unconditional
    ELSE  
        jmp .afterAudioUpdate
    ENDIF

    
; ---------------------------------------------------------------------
; Helper subroutine to minimize ROM footprint.
; Interleaved here so player routine can be inlined.
; ---------------------------------------------------------------------
tt_CalcInsIndex:
        ; move upper 3 bits to lower 3
        lsr
        lsr
        lsr
        lsr
        lsr
        tay
tt_Bit6Set:     ; This opcode has bit #6 set, for use with bit instruction
        rts


.instrument:
        ; --- Melodic instrument ---
        ; Compute index into ADSR indexes and master Ctrl tables
        jsr tt_CalcInsIndex
        ; Set AUDC with master value for this instrument, while we are at it
        lda tt_InsCtrlTable-1,y ; -1 because instruments start with #1
        sta AUDC0,x
        ; advance ADSR counter and compare to end of Sustain
        lda tt_envelope_index_c0,x
        cmp tt_InsReleaseIndexes-1,y    ; -1 because instruments start with #1
        bne .noEndOfSustain
        ; End of sustain: Go back to start of sustain
        lda tt_InsSustainIndexes-1,y    ; -1 because instruments start with #1
.noEndOfSustain:
        tay
        ; Set volume from envelope
        lda tt_InsFreqVolTable,y
        beq .endOfEnvelope              ; 0 means end of release has been reached:
        iny                             ; advance index otherwise
.endOfEnvelope:
        sty tt_envelope_index_c0,x
        sta AUDV0,x
        ; Now adjust frequency with ADSR value from envelope
        lsr
        lsr
        lsr
        lsr     
        clc
        adc tt_cur_ins_c0,x
        sec
        sbc #8
        sta AUDF0,x

.afterAudioUpdate:
        ; loop over channels
        dex
        bpl .updateLoop

        echo "Music player size: ", *-tt_PlayerStart

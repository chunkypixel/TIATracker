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
; TIATracker melodic and percussion instruments, patterns and sequencer
; data.
; =====================================================================
tt_TrackDataStart:

; =====================================================================
; Melodic instrument definitions (up to 7). tt_envelope_index_c0/1 hold
; the index values into these tables for the current instruments played
; in channel 0 and 1.
; 
; Each instrument is defined by:
; - tt_InsCtrlTable: the AUDC value
; - tt_InsADIndexes: the index of the start of the ADSR envelope as
;       defined in tt_InsFreqVolTable
; - tt_InsSustainIndexes: the index of the start of the Sustain phase
;       of the envelope
; - tt_InsReleaseIndexes: the index of the start of the Release phase
; - tt_InsFreqVolTable: The AUDF frequency and AUDV volume values of
;       the envelope
; =====================================================================

; Instrument master CTRL values
tt_InsCtrlTable:
        dc.b $03, $04, $0c, $03, $06, $0c


; Instrument Attack/Decay start indexes into ADSR tables.
tt_InsADIndexes:
        dc.b $00, $0e, $0e, $18, $1f, $2b


; Instrument Sustain start indexes into ADSR tables
tt_InsSustainIndexes:
        dc.b $0a, $14, $14, $1b, $27, $31


; Instrument Release start indexes into ADSR tables
; Caution: Values are stored with an implicit -1 modifier! To get the
; real index, add 1.
tt_InsReleaseIndexes:
        dc.b $0b, $15, $15, $1c, $28, $32


; AUDVx and AUDFx ADSR envelope values.
; Each byte encodes the frequency and volume:
; - Bits 7..4: Freqency modifier for the current note ([-8..7]),
;       8 means no change. Bit 7 is the sign bit.
; - Bits 3..0: Volume
; Between sustain and release is one byte that is not used and
; can be any value.
; The end of the release phase is encoded by a 0.
tt_InsFreqVolTable:
; 0: bass
        dc.b $8d, $8c, $89, $88, $87, $85, $84, $83
        dc.b $82, $81, $80, $00, $80, $00
; 1+2: boop
        dc.b $8e, $8b, $86, $84, $82, $81, $80, $00
        dc.b $80, $00
; 3: bass echo
        dc.b $89, $85, $83, $81, $00, $81, $00
; 4: hard dick
        dc.b $3f, $8e, $5d, $9c, $bb, $f8, $f5, $f2
        dc.b $f0, $00, $f0, $00
; 5: dunce
        dc.b $8e, $9a, $85, $8a, $86, $84, $82, $00
        dc.b $80, $00



; =====================================================================
; Percussion instrument definitions (up to 15)
;
; Each percussion instrument is defined by:
; - tt_PercIndexes: The index of the first percussion frame as defined
;       in tt_PercFreqTable and tt_PercCtrlVolTable
; - tt_PercFreqTable: The AUDF frequency value
; - tt_PercCtrlVolTable: The AUDV volume and AUDC values
; =====================================================================

; Indexes into percussion definitions signifying the first frame for
; each percussion in tt_PercFreqTable.
; Caution: Values are stored with an implicit +1 modifier! To get the
; real index, subtract 1.
tt_PercIndexes:
        dc.b $01, $05


; The AUDF frequency values for the percussion instruments.
; If the second to last value is negative (>=128), it means it's an
; "overlay" percussion, i.e. the player fetches the next instrument note
; immediately and starts it in the sustain phase next frame. (Needs
; TT_USE_OVERLAY)
tt_PercFreqTable:
; 0: hat
        dc.b $00, $00, $00, $00
; 1: snare
        dc.b $01, $1f, $00, $00, $00, $0d, $04, $08
        dc.b $0b, $0e, $0e, $0e, $00


; The AUDCx and AUDVx volume values for the percussion instruments.
; - Bits 7..4: AUDC value
; - Bits 3..0: AUDV value
; 0 means end of percussion data.
tt_PercCtrlVolTable:
; 0: hat
        dc.b $85, $81, $80, $00
; 1: snare
        dc.b $2c, $c5, $87, $86, $85, $84, $83, $82
        dc.b $81, $81, $80, $80, $00


        
; =====================================================================
; Track definition
; The track is defined by:
; - tt_PatternX (X=0, 1, ...): Pattern definitions
; - tt_PatternPtrLo/Hi: Pointers to the tt_PatternX tables, serving
;       as index values
; - tt_SequenceTable: The order in which the patterns should be played,
;       i.e. indexes into tt_PatternPtrLo/Hi. Contains the sequences
;       for all channels and sub-tracks. The variables
;       tt_cur_pat_index_c0/1 hold an index into tt_SequenceTable for
;       each channel.
;
; So tt_SequenceTable holds indexes into tt_PatternPtrLo/Hi, which
; in turn point to pattern definitions (tt_PatternX) in which the notes
; to play are specified.
; =====================================================================

; ---------------------------------------------------------------------
; Pattern definitions, one table per pattern. tt_cur_note_index_c0/1
; hold the index values into these tables for the current pattern
; played in channel 0 and 1.
;
; A pattern is a sequence of notes (one byte per note) ending with a 0.
; A note can be either:
; - Pause: Put melodic instrument into release. Must only follow a
;       melodic instrument.
; - Hold: Continue to play last note (or silence). Default "empty" note.
; - Slide (needs TT_USE_SLIDE): Adjust frequency of last melodic note
;       by -7..+7 and keep playing it
; - Play new note with melodic instrument
; - Play new note with percussion instrument
; - End of pattern
;
; A note is defined by:
; - Bits 7..5: 1-7 means play melodic instrument 1-7 with a new note
;       and frequency in bits 4..0. If bits 7..5 are 0, bits 4..0 are
;       defined as:
;       - 0: End of pattern
;       - [1..15]: Slide -7..+7 (needs TT_USE_SLIDE)
;       - 8: Hold
;       - 16: Pause
;       - [17..31]: Play percussion instrument 1..15
;
; The tracker must ensure that a pause only follows a melodic
; instrument or a hold/slide.
; ---------------------------------------------------------------------
TT_FREQ_MASK    = %00011111
TT_INS_HOLD     = 8
TT_INS_PAUSE    = 16
TT_FIRST_PERC   = 17

; Intro left
tt_pattern0:
        dc.b $3b, $08, $08, $3b, $08, $08, $3b, $08
        dc.b $08, $3b, $08, $3b, $2d, $08, $2c, $08
        dc.b $00

; Intro left2
tt_pattern1:
        dc.b $3b, $08, $08, $3b, $08, $08, $3b, $08
        dc.b $08, $3b, $08, $3b, $2d, $08, $2e, $08
        dc.b $00

; Intro left3
tt_pattern2:
        dc.b $3b, $26, $08, $3b, $2d, $08, $3b, $2d
        dc.b $08, $3b, $2d, $3b, $2d, $08, $2e, $08
        dc.b $00

; boop
tt_pattern3:
        dc.b $3b, $08, $70, $3b, $08, $70, $3b, $08
        dc.b $70, $3b, $08, $3b, $6f, $08, $2c, $70
        dc.b $00

; boop2
tt_pattern4:
        dc.b $3b, $08, $70, $3b, $08, $70, $3b, $08
        dc.b $6f, $3b, $08, $3b, $2d, $71, $2e, $70
        dc.b $00

; boop3
tt_pattern5:
        dc.b $3b, $26, $70, $3b, $2d, $6f, $3b, $2d
        dc.b $75, $3b, $2d, $3b, $2d, $08, $2e, $5b
        dc.b $00

; outro
tt_pattern6:
        dc.b $2d, $2f, $32, $2f, $32, $34, $32, $34
        dc.b $36, $34, $36, $38, $3b, $2d, $26, $3b
        dc.b $00

; outro2
tt_pattern7:
        dc.b $3b, $36, $34, $36, $31, $2f, $31, $2f
        dc.b $2d, $2f, $2d, $2b, $26, $27, $28, $27
        dc.b $00

; Intro right
tt_pattern8:
        dc.b $08, $9b, $08, $08, $9b, $08, $08, $9b
        dc.b $08, $08, $08, $08, $9b, $08, $08, $08
        dc.b $00

; dick
tt_pattern9:
        dc.b $ae, $08, $08, $08, $ae, $08, $08, $08
        dc.b $ae, $08, $08, $08, $ae, $08, $08, $08
        dc.b $00

; dick click
tt_pattern10:
        dc.b $ae, $11, $11, $11, $ae, $11, $11, $11
        dc.b $ae, $11, $11, $11, $ae, $11, $11, $11
        dc.b $00

; snare roll
tt_pattern11:
        dc.b $12, $12, $12, $12, $12, $12, $12, $12
        dc.b $12, $12, $12, $12, $12, $12, $12, $12
        dc.b $00

; dick snare
tt_pattern12:
        dc.b $ae, $11, $11, $11, $12, $11, $11, $11
        dc.b $ae, $11, $11, $11, $12, $11, $11, $11
        dc.b $00

; tick
tt_pattern13:
        dc.b $ae, $11, $d0, $11, $12, $11, $d0, $11
        dc.b $ae, $11, $d0, $11, $12, $11, $d0, $11
        dc.b $00

; tick2
tt_pattern14:
        dc.b $ae, $11, $d2, $11, $12, $11, $d2, $11
        dc.b $ae, $11, $d2, $11, $12, $11, $d2, $11
        dc.b $00

; tick3
tt_pattern15:
        dc.b $ae, $11, $d5, $11, $12, $11, $d5, $11
        dc.b $ae, $11, $d5, $11, $12, $11, $d5, $11
        dc.b $00

; tick4
tt_pattern16:
        dc.b $ae, $11, $d8, $11, $12, $11, $d8, $11
        dc.b $ae, $11, $d8, $11, $12, $11, $cf, $11
        dc.b $00




; Individual pattern speeds (needs TT_GLOBAL_SPEED = 0).
; Each byte encodes the speed of one pattern in the order
; of the tt_PatternPtr tables below.
; If TT_USE_FUNKTEMPO is 1, then the low nibble encodes
; the even speed and the high nibble the odd speed.
    IF TT_GLOBAL_SPEED = 0
tt_PatternSpeeds:
%%PATTERNSPEEDS%%
    ENDIF


; ---------------------------------------------------------------------
; Pattern pointers look-up table.
; ---------------------------------------------------------------------
tt_PatternPtrLo:
        dc.b <tt_pattern0, <tt_pattern1, <tt_pattern2, <tt_pattern3
        dc.b <tt_pattern4, <tt_pattern5, <tt_pattern6, <tt_pattern7
        dc.b <tt_pattern8, <tt_pattern9, <tt_pattern10, <tt_pattern11
        dc.b <tt_pattern12, <tt_pattern13, <tt_pattern14, <tt_pattern15
        dc.b <tt_pattern16
tt_PatternPtrHi:
        dc.b >tt_pattern0, >tt_pattern1, >tt_pattern2, >tt_pattern3
        dc.b >tt_pattern4, >tt_pattern5, >tt_pattern6, >tt_pattern7
        dc.b >tt_pattern8, >tt_pattern9, >tt_pattern10, >tt_pattern11
        dc.b >tt_pattern12, >tt_pattern13, >tt_pattern14, >tt_pattern15
        dc.b >tt_pattern16        


; ---------------------------------------------------------------------
; Pattern sequence table. Each byte is an index into the
; tt_PatternPtrLo/Hi tables where the pointers to the pattern
; definitions can be found. When a pattern has been played completely,
; the next byte from this table is used to get the address of the next
; pattern to play. tt_cur_pat_index_c0/1 hold the current index values
; into this table for channels 0 and 1.
; If TT_USE_GOTO is used, a value >=128 denotes a goto to the pattern
; number encoded in bits 6..0 (i.e. value AND %01111111).
; ---------------------------------------------------------------------
tt_SequenceTable:
        ; ---------- Channel 0 ----------
        dc.b $00, $01, $00, $02, $00, $01, $00, $02
        dc.b $00, $01, $00, $02, $03, $04, $03, $05
        dc.b $03, $04, $03, $05, $03, $04, $03, $05
        dc.b $03, $04, $03, $05, $06, $07, $06, $07
        dc.b $06, $07, $06, $07, $80

        
        ; ---------- Channel 1 ----------
        dc.b $08, $08, $08, $08, $09, $09, $09, $09
        dc.b $0a, $0a, $0a, $0b, $0c, $0c, $0c, $0c
        dc.b $09, $09, $0a, $0c, $0d, $0e, $0f, $10
        dc.b $0d, $0e, $0f, $0b, $09, $09, $09, $0a
        dc.b $0a, $0c, $0c, $0b, $a5


        echo "Track size: ", *-tt_TrackDataStart

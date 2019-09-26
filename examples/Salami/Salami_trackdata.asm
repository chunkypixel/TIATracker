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

; Song author: Glafouk
; Song name: Salami

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
        dc.b $06, $04, $0c


; Instrument Attack/Decay start indexes into ADSR tables.
tt_InsADIndexes:
        dc.b $00, $08, $08


; Instrument Sustain start indexes into ADSR tables
tt_InsSustainIndexes:
        dc.b $04, $0c, $0c


; Instrument Release start indexes into ADSR tables
; Caution: Values are stored with an implicit -1 modifier! To get the
; real index, add 1.
tt_InsReleaseIndexes:
        dc.b $05, $0d, $0d


; AUDVx and AUDFx ADSR envelope values.
; Each byte encodes the frequency and volume:
; - Bits 7..4: Freqency modifier for the current note ([-8..7]),
;       8 means no change. Bit 7 is the sign bit.
; - Bits 3..0: Volume
; Between sustain and release is one byte that is not used and
; can be any value.
; The end of the release phase is encoded by a 0.
tt_InsFreqVolTable:
; 0: bassline
        dc.b $8f, $8f, $8f, $8f, $86, $00, $80, $00
; 1+2: Chords
        dc.b $8c, $7a, $8b, $8c, $80, $00, $80, $00



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
        dc.b $01, $05, $14


; The AUDF frequency values for the percussion instruments.
; If the second to last value is negative (>=128), it means it's an
; "overlay" percussion, i.e. the player fetches the next instrument note
; immediately and starts it in the sustain phase next frame. (Needs
; TT_USE_OVERLAY)
tt_PercFreqTable:
; 0: Hat
        dc.b $02, $02, $02, $00
; 1: Kick
        dc.b $04, $01, $03, $03, $04, $05, $06, $07
        dc.b $08, $09, $0a, $0b, $0c, $0d, $00
; 2: Snare
        dc.b $07, $0d, $0e, $10, $14, $14, $15, $18
        dc.b $18, $19, $1a, $1b, $1e, $1f, $00


; The AUDCx and AUDVx volume values for the percussion instruments.
; - Bits 7..4: AUDC value
; - Bits 3..0: AUDV value
; 0 means end of percussion data.
tt_PercCtrlVolTable:
; 0: Hat
        dc.b $88, $86, $84, $00
; 1: Kick
        dc.b $ef, $ee, $ee, $eb, $e9, $e8, $e8, $e6
        dc.b $e6, $e6, $e4, $e4, $e2, $e2, $00
; 2: Snare
        dc.b $8e, $8d, $8d, $8c, $8b, $8a, $88, $88
        dc.b $87, $86, $84, $82, $81, $80, $00


        
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

; jointure
tt_pattern0:
        dc.b $38, $08, $08, $08, $08, $08, $08, $08
        dc.b $09, $08, $08, $08, $09, $08, $08, $08
        dc.b $09, $08, $08, $08, $09, $08, $08, $08
        dc.b $09, $08, $08, $08, $08, $08, $08, $08
        dc.b $6c, $53, $48, $49, $08, $08, $08, $08
        dc.b $4e, $08, $4e, $08, $4c, $08, $08, $08
        dc.b $4e, $4e, $08, $08, $08, $08, $08, $08
        dc.b $4a, $4a, $08, $08, $49, $49, $08, $08
        dc.b $08, $08, $08, $08, $08, $08, $00

; bass0
tt_pattern1:
        dc.b $30, $08, $30, $08, $08, $08, $08, $08
        dc.b $30, $08, $08, $08, $08, $08, $30, $08
        dc.b $08, $08, $08, $08, $30, $08, $08, $08
        dc.b $08, $08, $32, $08, $32, $08, $32, $08
        dc.b $2d, $08, $2d, $08, $08, $08, $08, $08
        dc.b $2d, $08, $08, $08, $08, $08, $2d, $08
        dc.b $08, $08, $08, $08, $2d, $08, $08, $08
        dc.b $08, $08, $2d, $08, $2d, $08, $2c, $08
        dc.b $00

; bass1
tt_pattern2:
        dc.b $34, $08, $34, $08, $08, $08, $08, $08
        dc.b $34, $08, $08, $08, $08, $08, $34, $08
        dc.b $08, $08, $08, $08, $34, $08, $08, $08
        dc.b $08, $08, $34, $08, $34, $08, $34, $08
        dc.b $2f, $08, $2f, $08, $08, $08, $08, $08
        dc.b $2f, $08, $08, $08, $08, $08, $2f, $08
        dc.b $08, $08, $08, $08, $32, $08, $2f, $08
        dc.b $08, $08, $2d, $08, $32, $08, $08, $08
        dc.b $00

; bass+mel0
tt_pattern3:
        dc.b $30, $08, $30, $08, $71, $08, $08, $08
        dc.b $30, $08, $08, $08, $78, $08, $30, $08
        dc.b $08, $08, $08, $08, $30, $08, $75, $08
        dc.b $71, $08, $32, $08, $32, $08, $32, $08
        dc.b $2d, $08, $2d, $08, $71, $08, $08, $08
        dc.b $2d, $08, $6b, $08, $6e, $08, $2d, $08
        dc.b $71, $08, $6f, $08, $2d, $08, $2f, $08
        dc.b $08, $08, $2d, $08, $2d, $08, $2c, $08
        dc.b $00

; bass+mel1
tt_pattern4:
        dc.b $34, $08, $34, $08, $71, $08, $08, $08
        dc.b $34, $08, $08, $08, $78, $08, $34, $08
        dc.b $08, $08, $08, $08, $34, $08, $75, $08
        dc.b $71, $08, $34, $08, $34, $08, $34, $08
        dc.b $2f, $08, $2f, $08, $71, $08, $08, $08
        dc.b $2f, $08, $6b, $08, $6e, $08, $2f, $08
        dc.b $71, $08, $6f, $08, $32, $08, $2f, $08
        dc.b $08, $08, $2d, $08, $32, $08, $08, $08
        dc.b $00

; bass+mel2
tt_pattern5:
        dc.b $30, $08, $30, $08, $5f, $08, $08, $08
        dc.b $30, $08, $6b, $08, $5f, $08, $30, $08
        dc.b $51, $08, $5a, $08, $30, $08, $08, $08
        dc.b $08, $08, $5a, $08, $57, $08, $32, $08
        dc.b $55, $08, $2d, $08, $55, $08, $2d, $08
        dc.b $55, $08, $08, $08, $57, $08, $2d, $08
        dc.b $08, $08, $08, $08, $2d, $08, $08, $08
        dc.b $08, $08, $2d, $08, $2d, $08, $2c, $08
        dc.b $00

; bass+mel3
tt_pattern6:
        dc.b $34, $08, $34, $08, $51, $08, $08, $08
        dc.b $34, $08, $55, $08, $51, $08, $34, $08
        dc.b $08, $08, $08, $08, $34, $08, $08, $08
        dc.b $51, $08, $34, $08, $34, $08, $34, $08
        dc.b $2f, $08, $2f, $08, $08, $08, $5a, $08
        dc.b $57, $08, $08, $08, $55, $08, $2f, $08
        dc.b $08, $08, $08, $08, $32, $08, $2f, $08
        dc.b $6b, $08, $2d, $08, $32, $08, $08, $08
        dc.b $00

; bass+mel4
tt_pattern7:
        dc.b $30, $08, $30, $08, $51, $08, $55, $08
        dc.b $30, $08, $5a, $08, $4f, $08, $30, $08
        dc.b $55, $08, $08, $08, $30, $08, $51, $08
        dc.b $4f, $08, $32, $08, $32, $08, $4f, $08
        dc.b $2d, $08, $2d, $08, $51, $08, $4f, $08
        dc.b $2d, $08, $5a, $08, $57, $08, $2d, $08
        dc.b $5f, $08, $6b, $08, $2d, $08, $57, $08
        dc.b $08, $08, $2d, $08, $2d, $08, $2c, $08
        dc.b $00

; bass+mel5
tt_pattern8:
        dc.b $34, $08, $34, $08, $51, $08, $55, $08
        dc.b $34, $08, $57, $08, $5a, $08, $34, $08
        dc.b $57, $08, $08, $08, $34, $08, $5a, $08
        dc.b $57, $08, $34, $08, $34, $08, $55, $08
        dc.b $2f, $08, $2f, $08, $55, $08, $55, $08
        dc.b $2f, $08, $57, $08, $5a, $08, $2f, $08
        dc.b $5f, $08, $6b, $08, $32, $08, $2f, $08
        dc.b $5f, $08, $2d, $08, $32, $08, $08, $08
        dc.b $00

; mel0
tt_pattern9:
        dc.b $74, $08, $74, $08, $71, $08, $08, $08
        dc.b $08, $08, $75, $08, $78, $08, $78, $08
        dc.b $08, $08, $08, $08, $08, $08, $75, $08
        dc.b $71, $08, $75, $08, $08, $08, $08, $08
        dc.b $08, $08, $71, $08, $71, $08, $6a, $08
        dc.b $08, $08, $6b, $08, $6e, $08, $08, $08
        dc.b $71, $08, $6f, $08, $08, $08, $6d, $08
        dc.b $08, $08, $08, $08, $08, $08, $08, $08
        dc.b $00

; mel1
tt_pattern10:
        dc.b $74, $08, $74, $08, $71, $08, $08, $08
        dc.b $08, $08, $75, $08, $78, $08, $78, $08
        dc.b $08, $08, $08, $08, $08, $08, $75, $08
        dc.b $71, $08, $75, $08, $08, $08, $08, $08
        dc.b $08, $08, $71, $08, $71, $08, $6a, $08
        dc.b $08, $08, $6b, $08, $6e, $08, $11, $08
        dc.b $71, $08, $6f, $08, $08, $08, $71, $08
        dc.b $11, $08, $12, $08, $12, $08, $12, $08
        dc.b $00

; jointure2
tt_pattern11:
        dc.b $11, $11, $11, $11, $08, $11, $08, $11
        dc.b $08, $08, $11, $08, $08, $08, $11, $08
        dc.b $08, $08, $08, $11, $08, $08, $08, $08
        dc.b $11, $08, $08, $08, $08, $08, $08, $11
        dc.b $08, $08, $08, $08, $08, $08, $11, $08
        dc.b $08, $08, $08, $08, $08, $08, $08, $08
        dc.b $11, $08, $08, $08, $08, $08, $08, $08
        dc.b $08, $08, $08, $08, $08, $08, $08, $08
        dc.b $11, $08, $08, $08, $08, $08, $00

; blank
tt_pattern12:
        dc.b $08, $08, $08, $08, $08, $08, $08, $08
        dc.b $08, $08, $08, $08, $08, $08, $08, $08
        dc.b $08, $08, $08, $08, $08, $08, $08, $08
        dc.b $08, $08, $08, $08, $08, $08, $08, $08
        dc.b $08, $08, $08, $08, $08, $08, $08, $08
        dc.b $08, $08, $08, $08, $08, $08, $08, $08
        dc.b $08, $08, $08, $08, $08, $08, $08, $08
        dc.b $08, $08, $08, $08, $08, $08, $08, $08
        dc.b $00

; k0
tt_pattern13:
        dc.b $12, $08, $08, $08, $08, $08, $08, $08
        dc.b $12, $08, $08, $08, $08, $08, $08, $08
        dc.b $12, $08, $08, $08, $08, $08, $08, $08
        dc.b $12, $08, $08, $08, $08, $08, $08, $08
        dc.b $12, $08, $08, $08, $08, $08, $08, $08
        dc.b $12, $08, $08, $08, $08, $08, $08, $08
        dc.b $12, $08, $08, $08, $08, $08, $08, $08
        dc.b $12, $08, $08, $08, $12, $08, $08, $08
        dc.b $00

; k1
tt_pattern14:
        dc.b $12, $08, $08, $08, $08, $08, $08, $08
        dc.b $12, $08, $08, $08, $08, $08, $08, $08
        dc.b $12, $08, $08, $08, $08, $08, $08, $08
        dc.b $12, $08, $08, $08, $08, $08, $08, $08
        dc.b $12, $08, $11, $08, $11, $08, $11, $08
        dc.b $12, $08, $11, $11, $11, $11, $11, $08
        dc.b $12, $08, $11, $11, $11, $08, $11, $08
        dc.b $12, $08, $11, $11, $11, $08, $11, $08
        dc.b $00

; k+h0
tt_pattern15:
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $12, $08, $08, $08, $11, $08, $11, $08
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $12, $08, $08, $08, $12, $08, $12, $08
        dc.b $00

; k+h1
tt_pattern16:
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $12, $08, $08, $08, $11, $08, $11, $08
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $12, $08, $11, $08, $11, $08, $11, $08
        dc.b $12, $08, $11, $11, $11, $11, $11, $08
        dc.b $00

; k+h+c0
tt_pattern17:
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $13, $08, $08, $08, $11, $08, $08, $08
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $13, $08, $08, $08, $11, $08, $11, $08
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $13, $08, $08, $08, $11, $08, $08, $08
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $13, $08, $08, $08, $11, $08, $13, $08
        dc.b $00

; k+h+c1
tt_pattern18:
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $13, $08, $08, $08, $11, $08, $08, $08
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $13, $08, $08, $08, $11, $08, $11, $08
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $13, $08, $08, $08, $11, $08, $08, $08
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $13, $08, $11, $11, $11, $11, $13, $08
        dc.b $00

; k+h+c+mel0
tt_pattern19:
        dc.b $12, $08, $74, $08, $11, $08, $08, $08
        dc.b $13, $08, $75, $08, $11, $08, $78, $08
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $13, $08, $75, $08, $11, $08, $11, $08
        dc.b $12, $08, $71, $08, $11, $08, $6a, $08
        dc.b $13, $08, $08, $08, $11, $08, $08, $08
        dc.b $12, $08, $08, $08, $11, $08, $6d, $08
        dc.b $13, $08, $08, $08, $11, $08, $13, $08
        dc.b $00

; k+h+c+mel1
tt_pattern20:
        dc.b $12, $08, $74, $08, $11, $08, $08, $08
        dc.b $13, $08, $75, $08, $11, $08, $78, $08
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $13, $08, $75, $08, $11, $08, $11, $08
        dc.b $12, $08, $71, $08, $11, $08, $6a, $08
        dc.b $13, $08, $08, $08, $11, $08, $08, $08
        dc.b $12, $08, $08, $08, $11, $08, $71, $08
        dc.b $13, $08, $08, $08, $11, $08, $13, $08
        dc.b $00

; k+h+c+mel2
tt_pattern21:
        dc.b $12, $08, $5f, $08, $11, $08, $08, $08
        dc.b $13, $08, $08, $08, $11, $08, $4f, $08
        dc.b $12, $08, $08, $08, $11, $08, $57, $08
        dc.b $13, $08, $08, $08, $11, $08, $5a, $08
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $13, $08, $08, $08, $11, $08, $5a, $08
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $13, $08, $55, $08, $51, $08, $13, $08
        dc.b $00

; k+h+c+mel3
tt_pattern22:
        dc.b $12, $08, $4f, $08, $11, $08, $08, $08
        dc.b $13, $08, $08, $08, $11, $08, $4f, $08
        dc.b $12, $08, $08, $08, $11, $08, $55, $08
        dc.b $13, $08, $55, $08, $11, $08, $57, $08
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $13, $08, $08, $08, $11, $08, $5a, $08
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $13, $08, $5f, $08, $11, $08, $13, $08
        dc.b $00

; k+h+c+mel4
tt_pattern23:
        dc.b $12, $08, $4f, $08, $11, $08, $08, $08
        dc.b $13, $08, $08, $08, $11, $08, $08, $08
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $13, $08, $51, $08, $11, $08, $11, $08
        dc.b $12, $08, $55, $08, $11, $08, $08, $08
        dc.b $13, $08, $08, $08, $11, $08, $08, $08
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $13, $08, $5a, $08, $11, $08, $13, $08
        dc.b $00

; k+h+c+mel5
tt_pattern24:
        dc.b $12, $08, $55, $08, $11, $08, $08, $08
        dc.b $13, $08, $08, $08, $11, $08, $08, $08
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $13, $08, $5a, $08, $11, $08, $11, $08
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $13, $08, $08, $08, $11, $08, $57, $08
        dc.b $12, $08, $08, $08, $11, $08, $08, $08
        dc.b $13, $08, $5a, $08, $11, $08, $13, $08
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
        dc.b <tt_pattern16, <tt_pattern17, <tt_pattern18, <tt_pattern19
        dc.b <tt_pattern20, <tt_pattern21, <tt_pattern22, <tt_pattern23
        dc.b <tt_pattern24
tt_PatternPtrHi:
        dc.b >tt_pattern0, >tt_pattern1, >tt_pattern2, >tt_pattern3
        dc.b >tt_pattern4, >tt_pattern5, >tt_pattern6, >tt_pattern7
        dc.b >tt_pattern8, >tt_pattern9, >tt_pattern10, >tt_pattern11
        dc.b >tt_pattern12, >tt_pattern13, >tt_pattern14, >tt_pattern15
        dc.b >tt_pattern16, >tt_pattern17, >tt_pattern18, >tt_pattern19
        dc.b >tt_pattern20, >tt_pattern21, >tt_pattern22, >tt_pattern23
        dc.b >tt_pattern24        


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
        dc.b $00, $01, $02, $01, $02, $01, $02, $01
        dc.b $02, $03, $04, $03, $04, $05, $06, $05
        dc.b $06, $03, $04, $03, $04, $07, $08, $07
        dc.b $08, $03, $04, $09, $0a, $01, $02, $83

        
        ; ---------- Channel 1 ----------
        dc.b $0b, $0c, $0c, $0d, $0e, $0f, $10, $11
        dc.b $12, $13, $14, $13, $14, $15, $16, $15
        dc.b $16, $13, $14, $13, $14, $17, $18, $17
        dc.b $18, $13, $14, $11, $12, $0d, $0d, $a3


        echo "Track size: ", *-tt_TrackDataStart

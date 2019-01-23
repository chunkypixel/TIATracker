 rem =============================================================================
 rem TIATracker Player
 rem This is an example of how to include TIATracker into your batari Basic game
 rem v1.0 23/01/2019 by Matthew Smith
 rem
 rem Instructions:
 rem - Create your music and select File > Export track data to dasm...' from
 rem   the menu. On the 'Save As' dialog locate your 'tiatracker/track' folder, 
 rem   enter a filename of 'track' and click the 'Save' button to export your 
 rem   music.
 rem 
 rem - Copy the variables from file tiatracker_batari_variables.bas
 rem   into your source. If these clash with existing variables change
 rem   their reference to suit.
 rem
 rem - In file 'track/track_variables.asm' remove the Permanent and Temporary 
 rem   variables from the file (otherwise you will receive a compilation error)
 rem ============================================================================

 rem *****************************************************
 bank 1
 rem *****************************************************
 temp1 = temp1

 set tv ntsc
 set kernel DPC+
 set smartbranching on
 set optimization inlinerand
 set kernel_options collision(playfield,player1)

 rem DEFINE VARS HERE

 rem =====================================================================
 rem TIATracker Variables
 rem These variables need to be included at the top of your game
 rem If these clash with existing variables change their reference
 rem Copied from tiatracker_batari_variables.bas
 rem =====================================================================
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

 rem score (show pattern for left and right)
 dim _sc1 = score
 dim _sc2 = score+1
 dim _sc3 = score+2

 goto START_RESTART bank2

 rem *****************************************************
 bank 2
 rem *****************************************************
 temp1 = temp1

START_RESTART
 rem mute volume of sound channels
 AUDV0 = 0 : AUDV1 = 0

 rem clear all normal variables
 a = 0 : b = 0 : c = 0 : d = 0 : e = 0 : f = 0 : g = 0 : h = 0 : i = 0
 j = 0 : k = 0 : l = 0 : m = 0 : n = 0 : o = 0 : p = 0 : q = 0 : r = 0
 s = 0 : t = 0 : u = 0 : v = 0 : w = 0 : x = 0 : y = 0 
 rem don't reset z = 0
 var0 = 0 : var1 = 0 : var2 = 0 : var3 = 0 : var4 = 0
 var5 = 0 : var6 = 0 : var7 = 0 : var8 = 0

 rem playfield configuration
 scorecolors:
 $0e
 $0e
 $0e
 $0e
 $0e
 $0e
 $0e
 $0e 
end

 rem display title
 goto TITLE_SETUP bank6

MAIN_LOOP
 goto MAIN_LOOP

 rem *****************************************************
 bank 3
 rem *****************************************************
 temp1 = temp1

 rem *****************************************************
 bank 4
 rem *****************************************************
 temp1 = temp1

 rem *****************************************************
 bank 5
 rem *****************************************************
 temp1 = temp1

 rem *****************************************************
 bank 6
 rem *****************************************************
 temp1 = temp1

TITLE_SETUP

 rem initialise tiatracker
 gosub tiatrackerinitmusic

TITLE_LOOP

 rem playfield resolution
 DF6FRACINC = 64 ; Background colors.
 DF4FRACINC = 64 ; Playfield colors.
 DF0FRACINC = 32 ; Column 0.
 DF1FRACINC = 32 ; Column 1.
 DF2FRACINC = 32 ; Column 2.
 DF3FRACINC = 32 ; Column 3.

 rem INSERT GAMEPLAY LOGIC

 rem  ****************************************************************
 rem  *
 rem  *  Puts temp4 in the three score digits on the right side.
 rem  *
 rem  ````````````````````````````````````````````````````````````````
 rem  `  Replace temp4 with whatever you need to check.
 rem  `
 temp4 = tt_cur_pat_index_c0
 _sc1 = 0 : _sc2 = _sc2 & 15
 if temp4 >= 100 then _sc1 = _sc1 + 16 : temp4 = temp4 - 100
 if temp4 >= 100 then _sc1 = _sc1 + 16 : temp4 = temp4 - 100
 if temp4 >= 50 then _sc1 = _sc1 + 5 : temp4 = temp4 - 50
 if temp4 >= 30 then _sc1 = _sc1 + 3 : temp4 = temp4 - 30
 if temp4 >= 20 then _sc1 = _sc1 + 2 : temp4 = temp4 - 20
 if temp4 >= 10 then _sc1 = _sc1 + 1 : temp4 = temp4 - 10
 _sc2 = (temp4 * 4 * 4) | _sc2

 rem  ****************************************************************
 rem  *
 rem  *  Puts temp4 in the three score digits on the right side.
 rem  *
 rem  ````````````````````````````````````````````````````````````````
 rem  `  Replace temp4 with whatever you need to check.
 rem  `
 temp4 = tt_cur_pat_index_c1
 _sc2 = _sc2 & 240 : _sc3 = 0
 if temp4 >= 100 then _sc2 = _sc2 + 1 : temp4 = temp4 - 100
 if temp4 >= 100 then _sc2 = _sc2 + 1 : temp4 = temp4 - 100
 if temp4 >= 50 then _sc3 = _sc3 + 80 : temp4 = temp4 - 50
 if temp4 >= 30 then _sc3 = _sc3 + 48 : temp4 = temp4 - 30
 if temp4 >= 20 then _sc3 = _sc3 + 32 : temp4 = temp4 - 20
 if temp4 >= 10 then _sc3 = _sc3 + 16 : temp4 = temp4 - 10
 _sc3 = _sc3 | temp4

 rem update display
 drawscreen

 rem play music (do after drawscreen)
 gosub tiatrackerplaytrack
 
 goto TITLE_LOOP

 rem include the tiatracker source
 asm
    include "tiatracker/tiatracker.asm"
end
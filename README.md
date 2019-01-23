# batari Basic TIATracker

Welcome to the TIATracker module for batari Basic allowing you to play TIATracker music in your Atari 2600 VCS game.

## What is TIATracker

TIATracker is a tool created by [Kylearan](http://atariage.com/forums/user/35905-kylearan/) for making Atari VCS music on the PC and a new sound routine for the VCS. It features ADSR envelopes, up to 7 melodic and 15 percussion instruments, customizable pitch guides for optimizing the number of in-tune notes, a size-optimized and configurable replayer routine and much more.

More information is available on the [AtariAge Forum](http://atariage.com/forums/topic/250014-tiatracker-a-new-sound-routine-and-sequencer-application)

## Example

See **TIATrackerPlayer.bas** for a full example of incorporating your TIATracker music into your batari Basic game.

## Known issues

None that I know of.  The example runs at a steady 262 frames (NTSC) in Stella but nothing else is pushing the VCS.

## Instructions

The following outlines how to add the **TIATracker** module to batari Basic and incorporate your music. If you are having issues refer to the example for assistance.

### batari Basic

1. Copy the **tiatracker** folder into the root of your batari Basic game folder

2. Copy the content of file **tiatracker/tiatracker_batari_variables.bas** into your variable definitions of your batari Basic game.

3. Add the following to your source (either at the bottom of your file or bank depending on your requirements):

```sh
 rem include the tiatracker source
 asm
    include "tiatracker/tiatracker.asm"
end
```

4. In the initalisation of your screen add the following to initialise the tracker:

```sh
 rem initialise tiatracker
 gosub tiatrackerinit
```

5. In your screen loop, after the **drawscreen** call add the following:

```sh
 rem play track
 gosub tiatrackerplay
```

### TIATracker

1. Create your music or get someone to do the hard work!

2. Select **File > Export track data to dasm...**  from the menu. On the **Save As** dialog locate your **tiatracker/track** folder in your batari Basic game folder, enter a filename of 'track' and click the **Save** button to export your music.

3. In file **tiatracker/track/track_variables.asm** remove the **Permanent** and **Temporary** variables from the file (otherwise you will receive a compilation error). *Note: This will need to be done each time you export your data.*

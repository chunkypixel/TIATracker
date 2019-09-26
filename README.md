# TIATracker

Welcome to the TIATracker module for batari Basic and 7800basic allowing you to play TIATracker music in your Atari console games.

## What is TIATracker

TIATracker is a tool created by [Kylearan](http://atariage.com/forums/user/35905-kylearan/) for making Atari VCS music on the PC and a new sound routine for the VCS. It features ADSR envelopes, up to 7 melodic and 15 percussion instruments, customizable pitch guides for optimizing the number of in-tune notes, a size-optimized and configurable replayer routine and much more.

More information is available on the [AtariAge Forum](http://atariage.com/forums/topic/250014-tiatracker-a-new-sound-routine-and-sequencer-application)

## Examples

For a full example of incorporating your TIATracker music into your source check the following depending on your platform:

* batari Basic - **TIATrackerPlayer.bas**
* 7800basic - **TIATrackerPlayer.78b** 

## Known issues

Currently only one track per game can be added.

## Instructions

The following outlines how to add the **TIATracker** module to source and incorporate your music. If you are having issues refer to the example for assistance.

1. Copy the **tiatracker** folder into the root of your source folder

2. Copy the content of file **tiatracker/tiatracker_variables.bas** into your variable definitions of your source.

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


# Change Log

The following enhancements and changes have been made to the TIATracker module:

### 1.2 - 20190926

* Update tracker source to work with 7800basic
* Added example source for 7800basic

### 1.1 - 20190125

* Fixed in issue where the **tiatracker source include** could not be inserted anywhere except at the end of the code (or bank 6 for DPC+) due to **Unresolved Symbol List** compilation errors in batari Basic (via dasm).

### 1.0 - 20190123

* Initial release

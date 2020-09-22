# Nuclear Rush (Unpublished)
Nuclear Rush was one of several Sega Genesis titles known to be in development for the Sega VR. This is the game's source code in buildable form, with a bunch of bug fixes to make the game fully playable on real hardware.

I chose not to fork for a couple of reasons, but this is all based on source code originally provided by one of the game's original developers, Kenneth Hurley, at: https://github.com/OldSkoolCode/Sega-Nuclear-Rush

Additionally, some of the tools used by the Nuclear Rush build process have been taken and/or adapted from Kenneth's Monster Hunter repository: https://github.com/OldSkoolCode/Sega-Monster-Hunter

I committed an unmodified copy of the relevant source bits before piling my modifications into this repository, so you'll have history on my changes.

## Sega VR Emulation
You'll find my emulation implementation of the Sega VR HMD here: https://github.com/DickBlackshack/SegaVR-DGenSDL

## Building
A MS-DOS 6.x environment and a copy of the Sierra 68000 C Compiler (see SIERRA/ReadMe.txt) are required to build this repository. With the compiler in place, make sure "source" is the working directory and run _build.bat under your MS-DOS environment. If all goes well, you'll end up with a file under source named _NUCRUSH.BIN. This is the playable Sega Genesis ROM.

/*
	File:		Gems.h - Version 2.0 for MicroTec 9/29/91

	Contains:	C includes for 68000 support routines for the GEMS driver.

	Written by:	Burt Sloane & Jonathan L. Miller

	Copyright:	 1990 by Sega of America, Inc., all rights reserved.

	Change History:
		11/19/91 BAS Update for 2.0

	To Do:
*/

/* start up the Gems system, including loading the Z80, starting it, and */
/*  passing pointers into the 68000 ROM for patches, envelopes, sequences and samples */
void gemsinit(/*long patchbankptr, long envbankptr, long seqbankptr, long sampbankptr*/);

/* start a sequence */
void gemsstartsong(/*short seqno*/);

/* stop a sequence */
void gemsstopsong(/*short seqno*/);

/* stop all sequences */
void gemsstopall();

/* pause all active sequences */
void gemspauseall();

/* resume all paused sequences */
void gemsresumeall();

/* set the global tempo value in beats per minute */
void gemssettempo(/*short newtempo*/);

/* lock a channel for use with sound effects */
void gemslockchannel(/*short channel*/);

/* set the note on priority for a channel */
void gemssetprio(/*short channel, short priority*/);

/* unlock a channel when done with making sound effects on it */
void gemsunlockchannel(/*short channel*/);

/* turn on notenum() on channel */
void gemsnoteon(/*short channel, short notenum*/);

/* turn off notenum on channel */
void gemsnoteoff(/*short channel, short notenum*/);

/* change the patch to newprog on channel */
void gemsprogchange(/*short channel, short newprog*/);

/* bend the note on channel by bendamt(signed 8-bit frac # semi-tones) */
void gemspitchbend(/*short channel, short bendamt*/);

/* change the pitch modulator to envnum on channel */
/*  trigger the envelope if not in note-on retrigger mode */
void gemssetenv(/*short channel, short envnum*/);

/* turn on/off the note-on retrigger mode on channel */
/*  val = 80h is on, val = 0 is off(explicit envelope trigger) */
void gemsretrigenv(/*short channel, short val*/);

/* turn on/off the sustain mode on channel */
/*  val = 80h is on, val = 0 is off */
void gemssustain(/*short channel, short val*/);

/* set the digital playback rate on channel */
/*  rate = 4 means dont override rate in sample bank */
/*  rate = 5 means play samples back at 10.4 kHz; see docs for more */
void gemssamprate(/*short channel, short rate*/);

/* mute a channel of a song */
/*  val = 1 is mute, val = 0 is enabled */
void gemsmute(/*short song, short channel, short val*/);

/* store a value in a mailbox */
/*  legal mailbox #s are 0..29, values are 0..127 */
void gemsstorembox(/*short mbox, short val*/);

/* read a value from a mailbox */
/*  legal mailbox #s are 0..29, values are 0..127 */
short gemsreadmbox(/*short mbox*/);

/* the following are low-level support routines */
/* tell the z80 we want to do dma */
void gemsdmastart(/*void*/);

/* tell the z80 we're done with dma */
void gemsdmaend(/*void*/);

/* hold the Z80 */
/*  use this before accessing the control paddle ports */
void gemsholdz80(/*void*/);

/* resume the Z80 */
/*  use this after accessing the control paddle ports */
void gemsreleasez80(/*void*/);

/* load the Z80 - called by initgems */
/*  dont use this */
void gemsloadz80(/*void*/);

/* start the Z80 - called by initgems */
/*  dont use this */
void gemsstartz80(/*void*/);

/* put a command byte on the Z80 command queue */
void gemsputcbyte(/*int b*/);

/* put a ptr on the Z80 command queue */
void gemsputptr(/*long p*/);


extern char patchbank;
extern char envbank;
extern char seqbank;
extern char sampbank;



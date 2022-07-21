; Sonic the Hedgehog 2 disassembled Z80 sound driver

; Disassembled by Xenowhirl for AS
; Additional disassembly work by RAS Oct 2008
; RAS' work merged into SVN by Flamewing
; ---------------------------------------------------------------------------
; NOTES:
;
; Set your editor's tab width to 8 characters wide for viewing this file.
;
; This code is compressed in the ROM, but you can edit it here as uncompressed
; and it will automatically be assembled and compressed into the correct place
; during the build process.
;
; This Z80 code can use labels and equates defined in the 68k code,
; and the 68k code can use the labels and equates defined in here.
; This is fortunate, as they contain references to each other's addresses.
;
; If you want to add significant amounts of extra code to this driver,
; I suggest putting your code as far down as possible, after the function zloc_12FC.
; That will make you less likely to run into space shortages from dislocated data alignment.
;
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; setup defines and macros and stuff

	; Okay, I spent a freakin' weekend trying to figure out this Z80 engine
	; (cause I just love it so much ;) ), and this is pretty much everything I've
	; got; it's probably about 95% figured out.
	;	- I didn't do 68K queueing completely... it's in there, I'm just a little fuzzy right now

	; I briefly touched the Saxman decoder though I'm not using it; I figured someone
	; else can play with that.  I think playing music out of ROM is just dandy,
	; even if it does require a little post-processing to work.  And actually, with
	; some tweaks, I think I can get this beast on relative addresses... heheheh

	; LOTS of decoding work and relabelling of unknowns!  This is a much more complete disasm ;)

	; zComRange:	@ 1B80h
	; 	+00h	-- Priority of current SFX (cleared when 1-up song is playing)
	; 	+01h	-- tempo clock
	; 	+02h	-- current tempo
	; 	+03h	-- Pause/unpause flag: 7Fh for pause; 80h for unpause (set from 68K)
	; 	+04h	-- total volume levels to continue decreasing volume before fade out considered complete (starts at 28h, works downward)
	; 	+05h	-- delay ticker before next volume decrease
	; 	+06h	-- communication value
	; 	+07h	-- "DAC is updating" flag (set to FFh until completion of DAC track change)
	; 	+08h	-- When NOT set to 80h, 68K request new sound index to play
	; 	+09h	-- SFX to Play queue slot
	; 	+0Ah	-- Play stereo sound queue slot
	; 	+0Bh	-- Unknown SFX Queue slot
	; 	+0Ch	-- Address to table of voices
	;
	; 	+0Eh	-- Set to 80h while fading in (disabling SFX) then 00h
	; 	+0Fh	-- Same idea as +05h, except for fade IN
	; 	+10h	-- Same idea as +04h, except for fade IN
	; 	+11h	-- 80h set indicating 1-up song is playing (stops other sounds)
	; 	+12h	-- main tempo value
	; 	+13h	-- original tempo for speed shoe restore
	; 	+14h	-- Speed shoes flag
	; 	+15h	-- If 80h, FM Channel 6 is NOT in use (DAC enabled)
	; 	+16h	-- value of which music bank to use (0 for MusicPoint1, $80 for MusicPoint2)
	; 	+17h	-- Pal mode flag
	;
	; ** zTracksStart starts @ +18h
	;
	; 	1B98 base
	; 	Track 1 = DAC
	; 	Then 6 FM
	; 	Then 3 PSG
	;
	;
	; 	1B98 = DAC
	; 	1BC2 = FM 1
	; 	1BEC = FM 2
	; 	1C16 = FM 3
	; 	1C40 = FM 4
	; 	1C6A = FM 5
	; 	1C94 = FM 6
	; 	1CBE = PSG 1
	; 	1CE8 = PSG 2
	; 	1D12 = PSG 3 (tone or noise)
	;
	; 	1D3C = SFX FM 3
	; 	1D66 = SFX FM 4
	; 	1D90 = SFX FM 5
	; 	1DBA = SFX PSG 1
	; 	1DE4 = SFX PSG 2
	; 	1E0E = SFX PSG 3 (tone or noise)
	;
	;
zTrack STRUCT DOTS
	; 	"playback control"; bits:
	; 	1 (02h): seems to be "track is at rest"
	; 	2 (04h): SFX is overriding this track
	; 	3 (08h): modulation on
	; 	4 (10h): do not attack next note
	; 	7 (80h): track is playing
	PlaybackControl:	ds.b 1
	; 	"voice control"; bits:
	; 	2 (04h): If set, bound for part II, otherwise 0 (see zWriteFMIorII)
	; 		-- bit 2 has to do with sending key on/off, which uses this differentiation bit directly
	; 	7 (80h): PSG Track
	VoiceControl:		ds.b 1
	TempoDivider:		ds.b 1	; timing divisor; 1 = Normal, 2 = Half, 3 = Third...
	DataPointerLow:		ds.b 1	; Track's position low byte
	DataPointerHigh:	ds.b 1	; Track's position high byte
	Transpose:		ds.b 1	; Transpose (from coord flag E9)
	Volume:			ds.b 1	; channel volume (only ap plied at voice changes)
	AMSFMSPan:		ds.b 1	; Panning / AMS / FMS settings
	VoiceIndex:		ds.b 1	; Current voice in use OR current PSG tone
	VolFlutter:		ds.b 1	; PSG flutter (dynamically effects PSG volume for decay effects)
	StackPointer:		ds.b 1	; "Gosub" stack position offset (starts at 2Ah, i.e. end of track, and each jump decrements by 2)
	DurationTimeout:	ds.b 1	; current duration timeout; counting down to zero
	SavedDuration:		ds.b 1	; last set duration (if a note follows a note, this is reapplied to 0Bh)
	;
	; 	; 0Dh / 0Eh change a little depending on track -- essentially they hold data relevant to the next note to play
	SavedDAC:			; DAC: Next drum to play
	FreqLow:		ds.b 1	; FM/PSG: frequency low byte
	FreqHigh:		ds.b 1	; FM/PSG: frequency high byte
	NoteFillTimeout:	ds.b 1	; Currently set note fill; counts down to zero and then cuts off note
	NoteFillMaster:		ds.b 1	; Reset value for current note fill
	ModulationPtrLow:	ds.b 1	; low byte of address of current modulation setting
	ModulationPtrHigh:	ds.b 1	; high byte of address of current modulation setting
	ModulationWait:		ds.b 1	; Wait for ww period of time before modulation starts
	ModulationSpeed:	ds.b 1	; Modulation Speed
	ModulationDelta:	ds.b 1	; Modulation change per Mod. Step
	ModulationSteps:	ds.b 1	; Number of steps in modulation (divided by 2)
	ModulationValLow:	ds.b 1	; Current modulation value low byte
	ModulationValHigh:	ds.b 1	; Current modulation value high byte
	Detune:			ds.b 1	; Set by detune coord flag E1; used to add directly to FM/PSG frequency
	VolTLMask:		ds.b 1	; zVolTLMaskTbl value set during voice setting (value based on algorithm indexing zGain table)
	PSGNoise:		ds.b 1	; PSG noise setting
	VoicePtrLow:		ds.b 1	; low byte of custom voice table (for SFX)
	VoicePtrHigh:		ds.b 1	; high byte of custom voice table (for SFX)
	LoopCounters:		ds.b $A	; Loop counter index 0
	;   ... open ...
	GoSubStack:			; start of next track, every two bytes below this is a coord flag "gosub" (F8h) return stack
	;
	;	The bytes between +20h and +29h are "open"; starting at +20h and going up are possible loop counters
	;	(for coord flag F7) while +2Ah going down (never AT 2Ah though) are stacked return addresses going
	;	down after calling coord flag F8h.  Of course, this does mean collisions are possible with either
	;	or other track memory if you're not careful with these!  No range checking is performed!
	;
	; 	All tracks are 2Ah bytes long
zTrack ENDSTRUCT

zVar STRUCT DOTS
	SFXPriorityVal:		ds.b 1
	TempoTimeout:		ds.b 1
	CurrentTempo:		ds.b 1	; Stores current tempo value here
	StopMusic:		ds.b 1	; Set to 7Fh to pause music, set to 80h to unpause. Otherwise 00h
	FadeOutCounter:		ds.b 1
	FadeOutDelay:		ds.b 1
	Communication:		ds.b 1	; Unused byte used to synchronise gameplay events with music
	DACUpdating:		ds.b 1 ; Set to FFh while DAC is updating, then back to 00h

	SoundQueueStart:
	QueueToPlay:		ds.b 1	; if NOT set to 80h, means new index was requested by 68K
	SFXToPlay:		ds.b 1	; When Genesis wants to play "normal" sound, it writes it here
	SFXStereoToPlay:	ds.b 1	; When Genesis wants to play alternating stereo sound, it writes it here
	SFXUnknown:		ds.b 1 ; Unknown type of sound queue, but it's in Genesis code like it was once used
	SoundQueueEnd:

	FadeInFlag:		ds.b 1
	FadeInDelay:		ds.b 1
	FadeInCounter:		ds.b 1
	1upPlaying:		ds.b 1
	TempoMod:		ds.b 1
	TempoTurbo:		ds.b 1	; Stores the tempo if speed shoes are acquired (or 7Bh is played anywho)
	SpeedUpFlag:		ds.b 1
	MusicBankNumber:	ds.b 1
	IsPalFlag:		ds.b 1	; I think this flags if system is PAL
zVar ENDSTRUCT

; equates: standard (for Genesis games) addresses in the memory map
zYM2612_A0 =	$4000
zYM2612_D0 =	$4001
zYM2612_A1 =	$4002
zYM2612_D1 =	$4003
zBankRegister =	$6000
zPSG =		$7F11
zROMWindow =	$8000
; more equates: addresses specific to this program (besides labelled addresses)
zStack =	$2000-((zVar.len*2)+(zTrack.len*20))
zMusicData = zStack - $A40 - $20

	phase zStack
zAbsVar:		zVar

zTracksStart:		; This is the beginning of all BGM track memory
zSongDACFMStart:
zSongDAC:		zTrack
zSongFMPSGStart:
zSongFMStart:
zSongFM1:		zTrack
zSongFM2:		zTrack
zSongFM3:		zTrack
zSongFM4:		zTrack
zSongFM5:		zTrack
zSongFM6:		zTrack
zSongFMEnd:
zSongDACFMEnd:
zSongPSGStart:
zSongPSG1:		zTrack
zSongPSG2:		zTrack
zSongPSG3:		zTrack
zSongPSGEnd:
zSongFMPSGEnd:
zTracksEnd:

zTracksSaveStart:	; When extra life plays, it backs up a large amount of memory (all track data plus 36 bytes)
zSaveSongDAC:		zTrack
zSaveSongFM1:		zTrack
zSaveSongFM2:		zTrack
zSaveSongFM3:		zTrack
zSaveSongFM4:		zTrack
zSaveSongFM5:		zTrack
zSaveSongFM6:		zTrack
zSaveSongPSG1:		zTrack
zSaveSongPSG2:		zTrack
zSaveSongPSG3:		zTrack
zTracksSaveEnd:

zSaveVar:		zVar
; see the very end for another set of variables
	dephase

	phase zTracksSaveStart
zTracksSFXStart:
zSFX_FMStart:
zSFX_FM3:		zTrack
zSFX_FM4:		zTrack
zSFX_FM5:		zTrack
zSFX_FMEnd:
zSFX_PSGStart:
zSFX_PSG1:		zTrack
zSFX_PSG2:		zTrack
zSFX_PSG3:		zTrack
zSFX_PSGEnd:
zTracksSFXEnd:
	dephase

MUSIC_TRACK_COUNT = (zTracksEnd-zTracksStart)/zTrack.len
MUSIC_DAC_FM_TRACK_COUNT = (zSongDACFMEnd-zSongDACFMStart)/zTrack.len
MUSIC_FM_PSG_TRACK_COUNT = (zSongFMPSGEnd-zSongFMPSGStart)/zTrack.len
MUSIC_FM_TRACK_COUNT = (zSongFMEnd-zSongFMStart)/zTrack.len
MUSIC_PSG_TRACK_COUNT = (zSongPSGEnd-zSongPSGStart)/zTrack.len

SFX_TRACK_COUNT = (zTracksSFXEnd-zTracksSFXStart)/zTrack.len
SFX_FM_TRACK_COUNT = (zSFX_FMEnd-zSFX_FMStart)/zTrack.len
SFX_PSG_TRACK_COUNT = (zSFX_PSGEnd-zSFX_PSGStart)/zTrack.len

    ; in what I believe is an unfortunate design choice in AS,
    ; both the phased and unphased PCs must be within the target processor's range,
    ; which means phase is useless here despite being designed to fix this problem...
    ; oh well, I set it up to fix this later when processing the .p file
    !org 0 ; Z80 code starting at address 0 has special meaning to s2p2bin.exe

    CPU Z80UNDOC
    listing purecode

zmake68kBank function addr,(((addr&3F8000h)/zROMWindow))

; macro to make a certain error message clearer should you happen to get it...
rsttarget macro {INTLABEL}
	if ($&7)||($>38h)
		fatal "Function __LABEL__ is at 0\{$}h, but must be at a multiple of 8 bytes <= 38h to be used with the rst instruction."
	endif
	if "__LABEL__"<>""
__LABEL__ label $
	endif
    endm

; function to decide whether an offset's full range won't fit in one byte
offsetover1byte function from,maxsize, ((from&0FFh)>(100h-maxsize))

; macro to make sure that ($ & 0FF00h) == (($+maxsize) & 0FF00h)
ensure1byteoffset macro maxsize
	if offsetover1byte($,maxsize)
startpad := $
		align 100h
	    if MOMPASS=1
endpad := $
		if endpad-startpad>=1h
			; warn because otherwise you'd have no clue why you're running out of space so fast
			warning "had to insert \{endpad-startpad}h   bytes of padding before improperly located data at 0\{startpad}h in Z80 code"
		endif
	    endif
	endif
    endm

; function to turn a 68k address into a word the Z80 can use to access it,
; assuming the correct bank has been switched to first
zmake68kPtr function addr,zROMWindow+(addr&7FFFh)


; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; Z80 'ROM' start:
;zEntryPoint:
	di	; disable interrupts
	ld	sp,zStack
	jp	zInitialiseDriver
; ---------------------------------------------------------------------------
; zbyte_7:
zPalModeByte:
	db	0

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||
	align	8
;zsub_10
zWriteFMIorII:    rsttarget
	bit	2,(ix+zTrack.VoiceControl)
	jp	nz, zWriteFMII
	nop
; End of function zWriteFMIorII

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||
	align	8
;zsub_18
zWriteFMI:    rsttarget
	; Write reg/data pair to part I; 'a' is register, 'c' is data
	ld	(iy+0),a
	ld	(iy+1),c
	ret
; End of function zWriteFMI

zPALUpdTick:	db 0 ; zbyte_12FE ; This counts from 0 to 5 to periodically "double update" for PAL systems (basically every 6 frames you need to update twice to keep up)

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||
	align	8
;zsub_28
zWriteFMII:    rsttarget
	; Write reg/data pair to part II; 'a' is register, 'c' is data
	ld	(iy+2),a
	ld	(iy+3),c
	ret
; End of function zWriteFMII

zSpindashPlayingCounter:	db 0 ; zbyte_1304

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||
	align	8
zBankSwitchToMusic:    rsttarget
	ld	a,(zAbsVar.MusicBankNumber)
	jr	zBankSwitch
; End of function zBankSwitchToMusic

zDACEnabled:	db 0
zHighPriorityDACPlaying:	db 0
zDACSFXPlaying:	db 0

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||
	align	8
zBankSwitchToSFX:    rsttarget
	ld	a,zmake68kBank(SoundIndex)
	jr	zBankSwitch
; End of function zBankSwitchToSFX

zCurDAC:	db 0 ; zbyte_12FF ; seems to indicate DAC sample playing status
zCurPCMBnk:	     ; shared wtih zDoSFXFlag
zDoSFXFlag:	db 0 ; zbyte_1301 ; Flag to indicate we're updating SFX (and thus use custom voice table); set to FFh while doing SFX, 0 when not.
zSpindashExtraFrequencyIndex:	db 0 ; zbyte_1305

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||
	align	8
; zsub_C63:
zBankSwitch:    rsttarget
	ld	hl, zBankRegister
	ld	(hl), a
	jp	zBankSwitchPart2
; End of function zBankSwitch

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||
	org	38h
zVInt:    rsttarget
	; This is called every VBLANK (38h is the interrupt entry point,
	; and VBLANK is the only one Z80 is hooked up to.)

	push	af					; Save 'af'
	push	bc
	push	de
	push	hl
	rst	zBankSwitchToMusic		; Bank switch to the music (depending on which BGM is playing in my version)
	xor	a						; Clear 'a'
	ld	(zDoSFXFlag),a			; Not updating SFX (updating music)
	ld	ix,zAbsVar			; ix points to zComRange
	ld	a,(zAbsVar.StopMusic)			; Get pause/unpause flag
	or	a						; test 'a'
	jr	z,zUpdateEverything		; If zero, go to zUpdateEverything
	call	zPauseMusic
	jp	zUpdateDAC				; Now update the DAC
; ---------------------------------------------------------------------------

;zloc_51
zUpdateEverything:
	ld	a,(zAbsVar.FadeOutCounter)			; are we fading out?
	or	a
	call	nz,zUpdateFadeout	; If so, update that
	ld	a,(zAbsVar.FadeInFlag)		; are we fading in?
	or	a
	call	nz,zUpdateFadeIn	; If so, update that
	ld	a,(zAbsVar.SFXToPlay)			; zComRange+09h -- play normal sound
	or	(ix+zVar.SFXStereoToPlay)				; zComRange+0Ah -- play stereo sound (alternating speakers)
	or	(ix+zVar.SFXUnknown)				; zComRange+0Bh -- "unknown" slot
	call	nz,zCycleQueue		; If any of those are non-zero, cycle queue

	; Apparently if this is 80h, it does not play anything new,
	; otherwise it cues up the next play (flag from 68K for new item)
	ld	a,(zAbsVar.QueueToPlay)
	or	a
	call	nz,zPlaySoundByIndex	; If not 80h, we need to play something new!

	; Spindash update
	ld	a,(zSpindashPlayingCounter)
	or	a
	jr	z,+ ; if the spindash counter is already 0, branch
	dec	a ; decrease the spindash sound playing counter
	ld	(zSpindashPlayingCounter),a
+
	; If the system is PAL, then this performs some timing adjustments
	; (i.e. you need to update 1.2x as much to keep up the same rate)
	ld	hl,zPalModeByte		; Get address of zPalModeByte
	ld	a,(zAbsVar.IsPalFlag)		; Get IsPalFlag -> 'a'
	and	(hl)				; 'And' them together
	jr	z,+					; If it comes out zero, do nothing
	ld	hl,zPALUpdTick
	dec	(hl)
	jr	nz,+
	ld	(hl),5				; every 6 frames (0-5) you need to "double update" to sort of keep up
	call	zUpdateMusic
+
	call	zUpdateMusic

	; Don't update SFX while 1up is playing (RAM gets overwritten in this driver, too)
	ld	a,(zAbsVar.1upPlaying)
	or	a
	jr	nz,zUpdateDAC

	; Now all of the SFX tracks are updated in a similar manner to "zUpdateMusic"...
	rst	zBankSwitchToSFX	; Bank switch to sound effects

	ld	a,80h
	ld	(zDoSFXFlag),a			; Set zDoSFXFlag = 80h (updating sound effects)

	; FM/PSG SFX channels
	ld	b,SFX_TRACK_COUNT					; Only 3 FM channels for SFX (FM3, FM4, FM5) + all PSG channels

-	push	bc
	ld	de,zTrack.len				; Spacing between tracks
	add	ix,de					; Next track
	bit	7,(ix+zTrack.PlaybackControl)				; Is it playing?
	call	nz,zUpdateTrack		; If it is, go update it
	pop	bc
	djnz	-

	; Now we update the DAC... this only does anything if there's a new DAC
	; sound to be played.  This is called after updating the DAC track.
	; Otherwise it just mucks with the timing loop, forcing an update.
zUpdateDAC:
	ld	(iy+0),2Ah		; Set DAC port register

zDACBankSwitch:
	ld	a,zmake68kBank(SndDAC1_Start)	; Bankswitch to the DAC data (self-modifying code!)
	rst	zBankSwitch

	; Shadow regs for the DPCM loop
	ld	c,0Fh				; DPCM nibble mask
	ld	de,zYM2612_D0
	ld	h,(zDACDecodeTbl & 0FF00h) >> 8	; DPCM lookup table address high byte
	exx

	ld	hl,zCurDAC			; Get address of 'current DAC sound' value
	bit	7,(hl)				; Get currently playing DAC sound
	jr	nz,+						; If one is queued (80h+), go to it!
	pop	hl
	pop	de
	pop	bc
	pop	af
	ld	b,1						; b=1 (initial feed to the DAC "djnz" loops, i.e. UPDATE RIGHT AWAY)
	ei		; enable interrupts
	ret
+
	; If you get here, it's time to start a new DAC sound...
	ld	a,80h
	ex	af,af'	;'
	res	7,(hl)					; Subtract 80h (first DAC index is 80h)

	; Clear the stack of (now-useless) backed-up variables
	pop	hl
	pop	de
	pop	bc
	pop	af

	pop	hl	; Pop return address from the stack; we don't want to return

zloc_104:
	ld	hl,0000h	; "self-modified code" -- sets start address of DAC sample for zWriteDPCMtoDAC

zloc_107:
	ld	de,0000h	; "self-modified code" -- sets length of DAC sample for zWriteDPCMtoDAC

zloc_10B:
	ld	bc,100h ; "self-modified code" -- From zloc_22A; sets b=1 (the 100h part of it) UPDATE RIGHT AWAY and c="data rate delay" for this DAC sample, the future 'b' setting
	ei		; enable interrupts

zDACPlaybackAddrInstruction:
	jp	zWriteDPCMtoDAC
; End of function zVInt

	align 100h
;zbyte_1B3
zDACDecodeTbl:
	db	   0,	 1,   2,   4,   8,  10h,  20h,  40h
	db	 80h,	-1,  -2,  -4,  -8, -10h, -20h, -40h

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

; Updates all tracks; queues notes and durations!

;zsub_110
zUpdateMusic:
	call	TempoWait		; This is a tempo waiting function

	; DAC updates
	ld	a,0FFh
	ld	(zAbsVar.DACUpdating),a		; Store FFh to DACUpdating
	ld	ix,zTracksStart		; Point "ix" to zTracksStart
	bit	7,(ix+zTrack.PlaybackControl)			; Is bit 7 (80h) set on playback control byte? (means "is playing")
	call	nz,zDACUpdateTrack		; If so, zDACUpdateTrack
	xor	a					; Clear A
	ld	(zAbsVar.DACUpdating),a		; Store 0 to DACUpdating
	ld	b,MUSIC_FM_PSG_TRACK_COUNT			; Loop 6 times (FM) + 3 times (PSG)...

-	push	bc
	ld	de,zTrack.len		; Space between tracks
	add	ix,de			; Go to next track
	bit	7,(ix+zTrack.PlaybackControl)		; Is bit 7 (80h) set on playback control byte? (means "is playing")
	call	nz,zUpdateTrack	; If so...
	pop	bc
	djnz	-

	ld	a,(zAbsVar.SpeedUpFlag)		; Get tempo speed-up value
	or	a		; Is music sped up?
	ret	z								; Return if not
	ld	c,a
zCanNotBeSpedUp = $+1
	ld	a,0
	or	a
	ret nz
	ld	hl, zAbsVar.TempoTurbo
	ld	a, (hl)			; Get extra tempo timeout
	or	a								; Has it expired?
	jr	nz, +							; Branch if not
	ld	(hl), c			; Reset extra tempo timeout to it
	jr	zUpdateMusic					; Update music again
; ---------------------------------------------------------------------------
+
	dec	a								; Decrement timeout...
	ld	(hl), a			; ... then store new value
	ret
; End of function zUpdateMusic


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


;zsub_14C
TempoWait:
	; Tempo works as divisions of the 60Hz clock (there is a fix supplied for
	; PAL that "kind of" keeps it on track.)  Every time the internal music clock
	; overflows, it will update.  So a tempo of 80h will update every other
	; frame, or 30 times a second.

	ld	ix,zAbsVar		; ix points to zComRange
	ld	a,(ix+zVar.CurrentTempo)			; tempo value
	add	a,(ix+zVar.TempoTimeout)			; Adds previous value to
	ld	(ix+zVar.TempoTimeout),a			; Store this as new
	ret	c					; If addition overflowed (answer greater than FFh), return

	; So if adding tempo value did NOT overflow, then we add 1 to all durations
	ld	hl,zTracksStart+zTrack.DurationTimeout	; Start at first track's delay counter (counting up to delay)
	ld	de,zTrack.len			; Offset between tracks
	ld	b,MUSIC_TRACK_COUNT				; Loop for all tracks

-	inc	(hl)				; Increasing delay tick counter to target
	add	hl,de				; Next track...
	djnz	-

	ret
; End of function TempoWait

; ---------------------------------------------------------------------------
; zloc_167:
zInitialiseDriver:
	im	1	; set interrupt mode 1
	ld	iy,zYM2612_A0
	call	zClearTrackPlaybackMem
	ei		; enable interrupts
	jr	$
	; This controls the update rate for the DAC...
	; My speculation for the rate at which the DAC updates:
	;	Z80 clock = 3.57954MHz = 3579540Hz (not sure?)
	;	zWaitLoop (immediately below) is waiting for someone to set
	;		'de' (length of DAC sample) to non-zero

	; The DAC code is sync'ed with VBLANK somehow, but I haven't quite got that
	; one figure out yet ... tests on emulator seem to confirm it though.
	; Next, there are "djnz" loops which do busy-waits.  (Two of them, which is
	; where the '2' comes from in my guess equation.)  The DACMasterPlaylist
	; appears to use '1' as the lowest input value to these functions.  (Which,
	; given the djnz, would be the fastest possible value.)
	; The rate seems to be calculated by 3579540Hz / (60Hz + (speed * 4)) / 2

	; 'hl' is the pointer to the sample, 'de' is the length of the sample,
	; and 'iy' points to the translation table; let's go...

	; The "djnz $" loops control the playback rate of the DAC
	; (the higher the 'b' value, the slower it will play)


	; As for the actual encoding of the data, it is described by jman2050:

	; "As for how the data is compressed, lemme explain that real quick:
	; First, it is a lossy compression. So if you recompress a PCM sample this way,
	; you will lose precision in data. Anyway, what happens is that each compressed data
	; is separated into nybbles (1 4-bit section of a byte). This first nybble of data is
	; read, and used as an index to a table containing the following data:
	; 0,1,2,4,8,$10,$20,$40,$80,$FF,$FE,$FC,$F8,$F0,$E0,$C0."   [zDACDecodeTbl / zbyte_1B3]
	; "So if the nybble were equal to F, it'd extract $C0 from the tale. If it were 8,
	; it would extract $80 from the table. ... Anyway, there is also another byte of data
	; that we'll call 'd'. At the start of decompression, d is $80. What happens is that d
	; is then added to the data extracted from the table using the nybble. So if the nybble
	; were 4, the 8 would be extracted from the table, then added to d, which is $80,
	; resulting in $88. This result is then put back into d, then fed into the YM2612 for
	; processing. Then the next nybble is read, the data is extracted from the table, then
	; is added to d (remember, d is now changed because of the previous operation), then is
	; put back into d, then is fed into the YM2612. This process is repeated until the number
	; of bytes as defined in the table above are read and decompressed."

	; In our case, the so-called 'd' value is shadow register 'a'

; zWriteToDAC:
zWriteDPCMtoDAC:
	djnz	$				; Busy wait for specific amount of time in 'b'

	di		; disable interrupts (while updating DAC)
	ld	a,(hl)				; Get next DAC byte
	rlca
	rlca
	rlca
	rlca
	exx
	and	c					; UPPER 4-bit offset into zDACDecodeTbl
	ld	l,a
	ex	af,af'				; shadow register 'a' is the 'd' value for 'jman2050' encoding
	add	a,(hl)			; Get byte from zDACDecodeTbl (self-modified to proper index)
	ld	(de),a		; Write this byte to the DAC
	exx
	ex	af,af'				; back to regular registers
	ld	b,c					; reload 'b' with wait value
	ei						; enable interrupts (done updating DAC, busy waiting for next update)

	djnz	$				; Busy wait for specific amount of time in 'b'

	di		; disable interrupts (while updating DAC)
	ld	b,c					; reload 'b' with wait value
	ld	a,(hl)				; Get next DAC byte
	inc	hl					; Next byte in DAC stream...
	dec	de					; One less byte
	exx
	and	c					; LOWER 4-bit offset into zDACDecodeTbl
	ld	l,a
	ex	af,af'				; shadow register 'a' is the 'd' value for 'jman2050' encoding
	add	a,(hl)			; Get byte from zDACDecodeTbl (self-modified to proper index)
	ld	(de),a		; Write this byte to the DAC
	exx
	ex	af,af'				; back to regular registers
	ei						; enable interrupts (done updating DAC, busy waiting for next update)

; zloc_174: zWaitLoop:
zDPCMWaitLoop:
	ld	a,d
	or	e
zDPCMWaitLoopJumpInstruction:
	jp	nz,zWriteDPCMtoDAC

	xor	a
	ld	(zHighPriorityDACPlaying),a
	ld	(zDACSFXPlaying),a
	jr	zDPCMWaitLoop		; As long as 'de' (length of sample) = 0, wait...

zWritePCMtoDAC:
	djnz	$				; Busy wait for specific amount of time in 'b'

	di		; disable interrupts (while updating DAC)
	ld	a,(hl)				; Get next DAC byte
	inc	hl					; Next byte in DAC stream...
	dec	de					; One less byte
	ld	(zYM2612_D0),a		; Write this byte to the DAC
	ld	b,c					; reload 'b' with wait value
	ei						; enable interrupts (done updating DAC, busy waiting for next update)

zPCMWaitLoop:
	ld	a,d
	or	e
zPCMWaitLoopJumpInstruction:
	jp	nz,zWritePCMtoDAC

	xor	a
	ld	(zHighPriorityDACPlaying),a
	ld	(zDACSFXPlaying),a
	jr	zPCMWaitLoop			; Back to the wait loop; if there's more DAC to write, we come back down again!

; ---------------------------------------------------------------------------
	; The following two tables are used for when an SFX terminates
	; its track to properly restore the music track it temporarily took
	; over.  Note that an important rule here is that no SFX may use
	; DAC, FM Channel 1, FM Channel 2, or FM Channel 6, period.
	; Thus there's also only SFX tracks starting at FM Channel 3.

	; The zeroes appear after FM 3 because it calculates the offsets into
	; these tables by their channel assignment, where between Channel 3
	; and Channel 4 there is a gap numerically.

	ensure1byteoffset 10h
;zbyte_1C3
zMusicTrackOffs:
	; These are offsets to different music tracks starting with FM3
	dw	zSongFM3,      0000h,  zSongFM4,  zSongFM5	; FM3, 0, FM4, FM5
	dw	zSongPSG1, zSongPSG2, zSongPSG3, zSongPSG3	; PSG1, PSG2, PSG3, PSG3 (noise alternate)

	ensure1byteoffset 10h
;zbyte_1D3
zSFXTrackOffs:
	; These are offsets to different sound effect tracks starting with FM3
	dw	zSFX_FM3,      0000h,  zSFX_FM4,  zSFX_FM5	; FM3, 0, FM4, FM5
	dw	zSFX_PSG1, zSFX_PSG2, zSFX_PSG3, zSFX_PSG3	; PSG1, PSG2, PSG3, PSG3 (noise alternate)
; ---------------------------------------------------------------------------

zDACUpdateTrack:
	dec	(ix+zTrack.DurationTimeout)		; Subtract 1 from (zTracksStart+0Bh) [Track 1's delay start]
	ret	nz				; Return if not zero yet
	ld	l,(ix+zTrack.DataPointerLow)		; Low byte of DAC track current address (zTracksStart+3)
	ld	h,(ix+zTrack.DataPointerHigh)		; High byte of DAC track current address (zTracksStart+4)

-	ld	a,(hl)			; Get next byte from DAC Track
	inc	hl				; Move to next position...
	cp	0E0h			; Check if is coordination flag
	jr	c,+				; Not coord flag?  Skip to '+'
	call	zCoordFlag	; Handle coordination flag
	jp	-				; Loop back around...
+
	or	a				; Test 'a' for 80h not set, which is a note duration
	jp	p,zloc_20E		; If note duration, jump to zloc_20E (note that "hl" is already incremented)
	ld	(ix+zTrack.SavedDAC),a		; This is a note; store it here
	ld	a,(hl)			; Get next byte...
	or	a				; Test 'a' for 80h not set, which is a note duration
	jp	p,zloc_20D		; Is this a duration this time??  If so, jump to zloc_20D (only difference is to increment "hl")
	; Note followed a note... apparently recycles the previous duration
	ld	a,(ix+zTrack.SavedDuration)		; Current DAC note ticker goal value -> 'a'
	ld	(ix+zTrack.DurationTimeout),a		; Use it again
	jr	zDACAfterDur	; Jump to after duration subroutine...
; ---------------------------------------------------------------------------

zloc_20D:
	inc	hl				; Goes to next byte (after duration byte)

zloc_20E:
	call	zSetDuration

;zloc_211
zDACAfterDur:
	ld	(ix+zTrack.DataPointerLow),l		; Stores "hl" to the DAC track pointer memory
	ld	(ix+zTrack.DataPointerHigh),h
	bit	2,(ix+zTrack.PlaybackControl)		; Is SFX overriding this track?
	ret	nz				; If so, we're done
	ld	a,(ix+zTrack.SavedDAC)		; Check next note to play
	cp	80h				; Is it a rest?
	ret	z				; If so, quit
	ld	b,a
	ld	c,(ix+zTrack.AMSFMSPan)
	ld	d,0
zPlayDAC:
	ld	a,(zHighPriorityDACPlaying)
	or	a
	ret	nz

	ld	a,b
	ld	(zCurDAC),a					; Store current DAC sound to play

	ld	a,d
	ld	(zDACSFXPlaying),a

	ld	a,0B6h		; Set FM6 panning
	rst	zWriteFMII

	; Enable DAC if it isn't enabled already
	ld	a,(zDACEnabled)
	or	a
	jr	nz,+
	ld	a,80h
	ld	(zDACEnabled),a
	ld	c,a
	ld	a,2Bh
	rst	zWriteFMI
+
	rst	zBankSwitchToSFX		; zDACMasterPlaylist is in this bank

	ld	a,(zCurDAC)
	sub	81h				; Otherwise, transform note into an index... (we're selecting which drum to play!)
;	add	a,a				; A = DAC number * 2
	ld	c,a
	ld	b,0
	ld	hl,zmake68kPtr(zDACMasterPlaylist)
	add	hl,bc
	add	hl,bc
	add	hl,bc
	add	hl,bc
	add	hl,bc
	add	hl,bc
	add	hl,bc	; Each entry of zDACMasterPlaylist is 7 bytes long

	ld	a, (hl)
	ld	(zDACBankSwitch+1),a	; write DAC bank
	inc	hl

	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	inc	hl
	ld	(zloc_104+1),bc			; write DAC sample start offset

	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	inc	hl
	ld	(zloc_107+1),bc			; write DAC sample size

	ld	a,(hl)						; Data rate delay -> 'b'
	ld	(zloc_10B+1),a	; store into the instruction after zloc_10B (self-modifying code)
	inc	hl

	ld	a,(hl)
	ld	bc,zWriteDPCMtoDAC
	rra
	jr	nc,+
	ld	bc,zWritePCMtoDAC
+
	ld	(zDACPlaybackAddrInstruction+1),bc

	rra
	sbc	a,a
	ld	(zHighPriorityDACPlaying),a

	rst	zBankSwitchToMusic	; Switch back to music

	ret

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

zUpdateTrack:
	bit	7,(ix+zTrack.VoiceControl)		; Is this a PSG track?
	jp	nz, zPSGUpdateTrack			; If so, jump to zPSGUpdateTrack
	;jp	zFMUpdateTrack				; Else, jump to zFMUpdateTrack
	; fall through instead

;zsub_237
zFMUpdateTrack:
	dec	(ix+zTrack.DurationTimeout)					; Decrement duration
	jr	nz,+						; If not time-out yet, go do updates only
	res	4,(ix+zTrack.PlaybackControl)					; When duration over, clear "do not attack" bit 4 (0x10) of track's play control
	call	zFMDoNext				; Handle coordination flags, get next note and duration
	call	zFMPrepareNote			; Prepares to play next note
	call	zFMNoteOn				; Actually key it (if allowed)
	call	zDoModulation			; Update modulation (if modulation doesn't change, we do not return here)
	jp		zFMUpdateFreq			; Applies frequency update from modulation
+
	call	zNoteFillUpdate			; Applies "note fill" (time until cut-off); NOTE: Will not return here if "note fill" expires
	call	zDoModulation			; Update modulation (if modulation doesn't change, we do not return here)
	jp		zFMUpdateFreq			; Applies frequency update from modulation
; End of function zFMUpdateTrack


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


;zsub_258
zFMDoNext:
	ld	l,(ix+zTrack.DataPointerLow)		; Load track position low byte
	ld	h,(ix+zTrack.DataPointerHigh)		; Load track position high byte
	res	1,(ix+zTrack.PlaybackControl)		; Clear bit 1 (02h) "track is rest" from track

-	ld	a,(hl)
	inc	hl				; Increment track to next byte
	cp	0E0h			; Is it a control byte / "coordination flag"?
	jr	c,+				; If not, jump over
	call	zCoordFlag	; Handle coordination flag
	jr	-				; Go around, get next byte
+
	push	af
	call	zFMNoteOff	; Send key off
	pop	af
	or	a				; Test 'a' for 80h not set, which is a note duration
	jp	p,+				; If duration, jump to '+'
	call	zFMSetFreq	; Otherwise, this is a note; call zFMSetFreq
	ld	a,(hl)			; Get next byte
	or	a				; Test 'a' for 80h set, which is a note
	jp	m,zFinishTrackUpdate		; If this is a note, jump to zFinishTrackUpdate
	inc	hl				; Otherwise, go to next byte; a duration
+
	call	zSetDuration
	jp	zFinishTrackUpdate		; Either way, jumping to zFinishTrackUpdate...
; End of function zFMDoNext

; ---------------------------------------------------------------------------
; zloc_285:
;zGetFrequency
zFMSetFreq:
	; 'a' holds a note to get frequency for
	sub	80h
	jr	z,zFMDoRest		; If this is a rest, jump to zFMDoRest
	add	a,(ix+zTrack.Transpose)		; Add current channel transpose (coord flag E9)
  if 0
	add	a,a				; Offset into Frequency table...
	add	a,zFrequencies&0FFh
	ld	(zloc_292+2),a	; store into the instruction after zloc_292 (self-modifying code)
	ld	d,a
	adc	a,(zFrequencies&0FF00h)>>8
	sub	d
	ld	(zloc_292+3),a	; this is how you could store the high byte of the pointer too (unnecessary if it's in the right range)
zloc_292:
	ld	de,(zFrequencies)	; Stores frequency into "de"
	ld	(ix+zTrack.FreqLow),e		; Frequency low byte   -> trackPtr + 0Dh
	ld	(ix+zTrack.FreqHigh),d		; Frequency high byte  -> trackPtr + 0Eh
  else
	ld	d,12			; 12 notes per octave
	ld	c,0			; clear c (will hold octave bits)

-	sub	d			; Subtract 1 octave from the note
	jr	c,+			; If this is less than zero, we are done
	inc	c			; One octave up
	jr	-
+
	add	a,d			; Add 1 octave back (so note index is positive)
	sla	c
	sla	c
	sla	c			; multiply octave value by 8, to get final octave bits
	ld	de,zFrequencies
SetFMPSGFreq:
	add	a,a
	add	a,e	; DE += 0A
	ld	e,a
	adc	a,d
	sub	a,e
	ld	d,a
	ld	a,(de)
	ld	(ix+zTrack.FreqLow),a		; Frequency low byte   -> trackPtr + 0Dh
	inc	de
	ld	a,(de)
	or	c			; a = high bits of frequency (including octave bits, which were in c)
	ld	(ix+zTrack.FreqHigh),a		; Frequency high byte  -> trackPtr + 0Eh
  endif
	ret
; ---------------------------------------------------------------------------

;zloc_29D
zFMDoRest:
	set	1,(ix+zTrack.PlaybackControl)		; Set bit 1 (track is at rest)
	xor	a				; Clear 'a'
	ld	(ix+zTrack.FreqLow),a		; Zero out FM Frequency
	ld	(ix+zTrack.FreqHigh),a		; Zero out FM Frequency
	ret

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


;zsub_2A9
zSetDuration:
	call	zComputeNoteDuration
	ld	(ix+zTrack.SavedDuration),a		; Store new duration into ticker goal of this track (this is reused if a note follows a note without a new duration)
	ld	(ix+zTrack.DurationTimeout),a		; Sets it on ticker (counts to zero)
	ret
; End of function zSetDuration

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


zComputeNoteDuration:
	ld	c,a				; 'a' = current duration
	xor	a
	ld	b,(ix+zTrack.TempoDivider)		; Divisor; causes multiplication of duration for every number higher than 1
-	add	a,c				; Will multiply duration based on 'b'
	djnz	-
	ret
; End of function zComputeNoteDuration

; ---------------------------------------------------------------------------

;zloc_2BA
zFinishTrackUpdate:
	; Common finish-up routine used by FM or PSG
	ld	(ix+zTrack.DataPointerLow),l		; Stores "hl" to the track pointer memory
	ld	(ix+zTrack.DataPointerHigh),h
	ld	a,(ix+zTrack.SavedDuration)		; Last set duration
	ld	(ix+zTrack.DurationTimeout),a		; ... put into ticker
	bit	4,(ix+zTrack.PlaybackControl)		; Is bit 4 (10h) "do not attack next note" set on playback?
	ret	nz				; If so, quit
	ld	a,(ix+zTrack.NoteFillMaster)		; Master "note fill" value -> a
	ld	(ix+zTrack.NoteFillTimeout),a		; Reset 0Fh "note fill" value to master
	ld	(ix+zTrack.VolFlutter),0		; Reset PSG flutter byte
	bit	3,(ix+zTrack.PlaybackControl)		; is modulation turned on?
	ret	z				; if not, quit
	ld	l,(ix+zTrack.ModulationPtrLow)		; Otherwise, get address of modulation setting
	ld	h,(ix+zTrack.ModulationPtrHigh)
	jp	zSetModulation	; ... and go do it!

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


;zsub_2E3
zNoteFillUpdate:
	ld	a,(ix+zTrack.NoteFillTimeout)		; Get current note fill value
	or	a
	ret	z				; If zero, return!
	dec	(ix+zTrack.NoteFillTimeout)		; Decrement note fill
	ret	nz				; If not zero, return
	set	1,(ix+zTrack.PlaybackControl)		; Set bit 1 (track is at rest)
	pop	de				; return address -> 'de' (will not return to z*UpdateTrack function!!)
	bit	7,(ix+zTrack.VoiceControl)		; Is this a PSG track?
	jp	nz,zPSGNoteOff	; If so, jump to zPSGNoteOff
	jp	zFMNoteOff		; Else, jump to zFMNoteOff
; End of function zNoteFillUpdate


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


;zsub_2FB
zDoModulation:
	pop	de				; keep return address -> de (MAY not return to caller)

	bit	1,(ix+zTrack.PlaybackControl)		; Is "track in rest"?
	ret	nz				; If so, quit
	bit	3,(ix+zTrack.PlaybackControl)		; Is modulation on?
	ret	z				; If not, quit
	ld	a,(ix+zTrack.ModulationWait)		; 'ww' period of time before modulation starts
	or	a
	jr	z,+				; if zero, go to it!
	dec	(ix+zTrack.ModulationWait)		; Otherwise, decrement timer
	ret					; return if decremented (does NOT return to z*UpdateTrack!!)
+
	dec	(ix+zTrack.ModulationSpeed)		; Decrement modulation speed counter
	ret	nz				; Return if not yet zero
	ld	l,(ix+zTrack.ModulationPtrLow)
	ld	h,(ix+zTrack.ModulationPtrHigh)		; 'hl' points to modulation setting
	inc	hl				; skip passed 'ww' period of time
	ld	a,(hl)			; Get modulation speed
	ld	(ix+zTrack.ModulationSpeed),a		; Restore speed counter
	ld	a,(ix+zTrack.ModulationSteps)		; Get number of steps in modulation
	or	a
	jr	nz,+			; If not zero, skip to '+'

	; If steps have reached zero...
	inc	hl				; passed mod speed
	inc	hl				; passed mod change per mod step
	ld	a,(hl)			; get number of steps in modulation
	ld	(ix+zTrack.ModulationSteps),a		; restore modulation steps
	ld	a,(ix+zTrack.ModulationDelta)		; get modulation change per mod step
	neg					; flip it negative
	ld	(ix+zTrack.ModulationDelta),a		; store negated value
	ret
+
	dec	(ix+zTrack.ModulationSteps)		; Decrement the step
	ld	l,(ix+zTrack.ModulationValLow)
	ld	h,(ix+zTrack.ModulationValHigh)		; Get 16-bit modulation value

	; This is a 16-bit sign extension for 'bc'
    if 0
	ld	b,0
	ld	c,(ix+zTrack.ModulationDelta)		; Get current modulation change per step -> 'c'
	bit	7,c
	jp	z,+
	ld	b,0FFh			; Sign extend if negative
    else
	ld	c,(ix+zTrack.ModulationDelta)		; Get current modulation change per step -> 'c'
	ld	a, c
	add	a, a			; sign bit into carry
	sbc	a, a
	ld	b, a			; b = sign extention
    endif
+
	add	hl,bc			; Add to current modulation value
	ld	(ix+zTrack.ModulationValLow),l
	ld	(ix+zTrack.ModulationValHigh),h		; Store new 16-bit modulation value
	ld	c,(ix+zTrack.FreqLow)		; frequency low byte -> c
	ld	b,(ix+zTrack.FreqHigh)		; frequency high byte -> b
	add	hl,bc			; Add modulation value
	ex	de,hl
	jp	(hl)			; WILL return to z*UpdateTrack
; End of function zDoModulation

; ---------------------------------------------------------------------------

;zloc_3E5
zFMPrepareNote:
	bit	1,(ix+zTrack.PlaybackControl)		; Is track in rest?
	ret	nz				; If so, quit
	ld	e,(ix+zTrack.FreqLow)		; Get frequency low
	ld	d,(ix+zTrack.FreqHigh)		; Get frequency high
	ld	a,d
	or	e
	jp	z,zloc_4C5		; If de == 0, go to zloc_4C5

;zloc_3F5
zFMUpdateFreq:
	bit	2,(ix+zTrack.PlaybackControl)		; Is SFX overriding this track?
	ret	nz				; If so, quit!
    if 0
	ld	h,0				; h = 0
	ld	l,(ix+zTrack.Detune)		; Get detune value
	; This is a 16-bit sign extension of (ix+19h)
	bit	7,l				; Did prior value have 80h set?
	jr	z,+				; If not, skip next step
	ld	h,0FFh			; h = FFh
    else
	ld	l,(ix+zTrack.Detune)		; Get detune value
	ld	a, l
	add	a, a			; sign bit into carry
	sbc	a, a
	ld	h, a			; h = sign extention
    endif
+
	add	hl,de			; Alter frequency just a tad
	ld	c,h				; Upper part of frequency as data to FM ('c')
	ld	a,(ix+zTrack.VoiceControl)		; "voice control" byte -> 'a'
	and	3				; Strip to only channel assignment
	add	a,0A4h			; Change to proper register
	rst	zWriteFMIorII	; Write it!
	ld	c,l				; lower part of frequency
	sub	4				; A0h+ register
	rst	zWriteFMIorII	; Write it!
	ret

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


;zsub_414
zPSGUpdateTrack:
	dec	(ix+zTrack.DurationTimeout)					; decrement current duration timeout..
	jr	nz,+						; If not time-out yet, go do updates only
	res	4,(ix+zTrack.PlaybackControl)				; Reset "do not attack next note" bit
	call	zPSGDoNext				; Handle coordination flags, get next note and duration
	call	zPSGDoNoteOn			; Actually key it (if allowed)
	call	zPSGDoVolFX				; This applies PSG volume as well as its special volume-based effects that I call "flutter"
	call	zDoModulation			; Update modulation (if modulation doesn't change, we do not return here)
	jp	zPSGUpdateFreq
+
	call	zNoteFillUpdate			; Applies "note fill" (time until cut-off); NOTE: Will not return here if "note fill" expires
	call	zPSGUpdateVolFX			; Update volume effects
	call	zDoModulation			; Update modulation (if modulation doesn't change, we do not return here)
	jp	zPSGUpdateFreq
; End of function zPSGUpdateTrack


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


;zsub_438
zPSGDoNext:
	ld	l,(ix+zTrack.DataPointerLow)		; Load track position low byte
	ld	h,(ix+zTrack.DataPointerHigh)		; Load track position high byte
	res	1,(ix+zTrack.PlaybackControl)		; Clear bit 1 (02h) "track is rest" from track

-	ld	a,(hl)
	inc	hl				; Increment track to next byte
	cp	0E0h			; Is it a control byte / "coordination flag"?
	jr	c,+				; If not, jump over
	call	zCoordFlag	; Handle coordination flag
	jr	-				; Go around, get next byte
+
	or	a				; Test 'a' for 80h not set, which is a note duration
	jp	p,+				; If note duration, jump to '+'
	call	zPSGSetFreq	; Get frequency for this note
	ld	a,(hl)			; Get next byte
	or	a				; Test 'a' for 80h set, which is a note
	jp	m,zFinishTrackUpdate		; If this is a note, jump to zFinishTrackUpdate
	inc	hl				; Otherwise, go to next byte; a duration
+
	call	zSetDuration
	jp	zFinishTrackUpdate		; Either way, jumping to zFinishTrackUpdate...
; End of function zPSGDoNext

; ---------------------------------------------------------------------------

;zloc_460
zPSGSetFreq:
	sub	81h				; a = a-$81 (zero-based index from lowest note)
	jr	c,+				; If carry (only time that happens if 80h because of earlier logic) this is a rest!
	add	a,(ix+zTrack.Transpose)		; Add current channel transpose (coord flag E9)
	add	a,12
  if 0
	add	a,a
	add	a,zPSGFrequencies&0FFh	; Point to proper place in table
	ld	(zloc_46D+2),a	; store into the instruction after zloc_46D (self-modifying code)
	ld	d,a
	adc	a,(zPSGFrequencies&0FF00h)>>8
	sub	d
	ld	(zloc_46D+3),a	; this is how you could store the high byte of the pointer too (unnecessary if it's in the right range)
zloc_46D:
	ld	de,(zPSGFrequencies)	; Gets appropriate frequency setting -> 'de'
	ld	(ix+zTrack.FreqLow),e		; Frequency low byte   -> trackPtr + 0Dh
	ld	(ix+zTrack.FreqHigh),d		; Frequency high byte  -> trackPtr + 0Eh
	ret
  else
	ld	de, zPSGFrequencies
	ld	c,0	; SetFMPSGFreq uses c to hold octave bits for FM
	jp	SetFMPSGFreq
  endif
+
	; If you get here, we're doing a PSG rest
	set	1,(ix+zTrack.PlaybackControl)		; Set "track in rest" bit
	ld	a,0FFh
	ld	(ix+zTrack.FreqLow),a		; Frequency low byte = FFh
	ld	(ix+zTrack.FreqHigh),a		; Frequency hight byte = FFh
	jp	zPSGNoteOff		; Send PSG Note Off

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


;zsub_487
zPSGDoNoteOn:
	bit	7,(ix+zTrack.FreqHigh)		; If track is at rest (frequency was set to FFh)...
	jr	nz,zloc_4C5		; jump to zloc_4C5
	ld	e,(ix+zTrack.FreqLow)		; Frequency low byte -> e
	ld	d,(ix+zTrack.FreqHigh)		; Frequency high byte -> d

;zloc_493
zPSGUpdateFreq:
	ld	a,(ix+zTrack.PlaybackControl)		; Get playback control byte
	and	6
	ret	nz				; If either bit 1 ("track in rest") and 2 ("SFX overriding this track"), quit!
	; This is a 16-bit sign extension of (ix+19h) -> 'hl'
    if 0
	ld	h,0
	ld	l,(ix+zTrack.Detune)		; hl = detune value (coord flag E9)
	bit	7,l				; Did prior value have 80h set?
	jr	z,+				; If not, skip next step
	ld	h,0FFh			; sign extend negative value
    else
	ld	l,(ix+zTrack.Detune)		; Get detune value
	ld	a, l
	add	a, a			; sign bit into carry
	sbc	a, a
	ld	h, a			; h = sign extention
    endif
+
	add	hl,de			; Alter frequency just a tad
	; This picks out the reg to write to the PSG
	ld	a,(ix+zTrack.VoiceControl)		; Get "voice control" byte...
	cp	0E0h			; Is it E0h?
	jr	nz,+			; If not, skip next step
	ld	a,0C0h			; a = C0h instead of E0h
+
	ld	b,a				; 'a' -> 'b'
	ld	a,l				; Frequency low byte -> 'a'
	and	0Fh				; Keep only lower four bits (first PSG reg write only applies d0-d3 of freq)
	or	b				; Apply register bits
	ld	(zPSG),a		; Write it to PSG!
	ld	a,l				; Get frequency low byte -> 'a'
	srl	h				; (h >> 1); lowest bit into carry
	rra					; (a >> 1); carry from 'h' applied at end
	srl	h				; ... and so on ...
	rra
	rra
	rra					; in C, basically (hl >> 4) (except possible garbage from the rotation in upper bits)
	and	3Fh				; keep only lower 6 bits (PSG d4-d9)
	ld	(zPSG),a		; Write other frequency byte to PSG!
	ret
; ---------------------------------------------------------------------------

zloc_4C5:
	set	1,(ix+zTrack.PlaybackControl)		; Set "track at rest" bit
	ret
; End of function zPSGDoNoteOn


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


;zsub_4CA
zPSGUpdateVolFX:
	ld	a,(ix+zTrack.VoiceIndex)		; Get current PSG tone
	or	a				; Test if it's zero
	ret	z				; If it is, return!
	; Otherwise, fall into zPSGDoVolFX...


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


;zsub_4CF
zPSGDoVolFX:
	ld	b,(ix+zTrack.Volume)		; Channel volume -> 'b'
	ld	a,(ix+zTrack.VoiceIndex)		; Current PSG tone -> 'a'
	or	a				; Test it
	jr	z,zPSGUpdateVol		; If tone is zero, jump to zPSGUpdateVol
	ld	hl,zPSG_FlutterTbl	; hl points to zPSG_FlutterTbl table
	dec	a				; a--
	add	a,a				; a *= 2
	ld	e,a
	ld	d,0				; de = a
	add	hl,de			; Offset into pointer table...
	ld	a,(hl)			; Get low byte -> 'a'
	inc	hl				; Next byte
	ld	h,(hl)			; Get high byte into 'h'
	add	a,(ix+zTrack.VolFlutter)		; Apply PSG flutter (provides dynamic volume for special effects)
	ld	l,a
	adc	a,h
	sub	l
	ld	h,a				; Basically, hl = (hl+(ix+zTrack.VolFlutter))
	ld	a,(hl)			; Get byte from this location
	inc	(ix+zTrack.VolFlutter)			; Increment PSG flutter value
	or	a				; test byte from before
	jp	p,+				; Is it a positive value?
	cp	80h				; Check if it's 80h (terminator to the "flutter" list)
	jr	z,zVolEnvHold		; If it is, then jump to zVolEnvHold (which just keeps at this flutter value, i.e. no more changes in volume)
+
	add	a,b				; Apply this "flutter" to channel volume -> 'a'
	ld	b,a				; a -> 'b'

;zloc_4F9
zPSGUpdateVol:
	ld	a,(ix+zTrack.PlaybackControl)		; get playback control byte
	and	6
	ret	nz				; If either bit 1 ("track in rest") and 2 ("SFX overriding this track"), quit!
	bit	4,(ix+zTrack.PlaybackControl)		; is "do not attack next note" set?
	jr	nz,zloc_515		; If so, jump to zloc_515

zloc_505:
	ld	a,b				; 'b' -> 'a'
	cp	10h				; Did the level get pushed below silence level? (i.e. a > 0Fh)
	jr	c,+
	ld	a,0Fh			; If so, fix it!
+
	or	(ix+zTrack.VoiceControl)			; Apply channel info (which PSG to set!)
	or	10h				; This bit marks it as an attenuation level assignment (along with channel info just above)
	ld	(zPSG),a		; Write to PSG!!
	ret
; ---------------------------------------------------------------------------

zloc_515:				; If you get here, then "do not attack next note" was set...
	ld	a,(ix+zTrack.NoteFillMaster)		; Get master "note fill" value
	or	a				; test it
	jr	z,zloc_505		; If it's zero, then just process normally
	ld	a,(ix+zTrack.NoteFillTimeout)		; Otherwise, get current "note fill" value
	or	a				; Test it
	jr	nz,zloc_505		; If it's not zero, then just process normally
	ret
; ---------------------------------------------------------------------------
; zloc_522:
zVolEnvHold:
	; This just decrements the flutter to keep it in place; no more volume changes in this list
	; Clownacy: This new code loops over the terminator flag AND the final volume
	; value, to fix PSG during fade in/out.
	dec	(ix+zTrack.VolFlutter)
	dec	(ix+zTrack.VolFlutter)				; Put index back (before final volume value)
	jr	zPSGDoVolFX				; Loop back and update volume
;	; DANGER! This effectively halts all future volume updates, breaking fades.
;	dec	(ix+zTrack.VolFlutter)	; Put index back (before flag 80h)
;	ret							; Return and don't update volume on this frame (!!!)
; End of function zPSGDoVolFX


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


;zsub_526
zPSGNoteOff:
	bit	2,(ix+zTrack.PlaybackControl)		; Is "SFX override" bit set?
	ret	nz				; If so, quit!
	ld	a,(ix+zTrack.VoiceControl)		; Get "voice control" byte (loads upper bits which specify attenuation setting)

	;                 |a| |1Fh|
	; VOL1    0x90	= 100 1xxxx	vol 4b xxxx = attenuation value
	; VOL2    0xb0	= 101 1xxxx	vol 4b
	; VOL3    0xd0	= 110 1xxxx	vol 4b

	or	1Fh				; Attenuation Off
	ld	(zPSG),a
	; Clownacy: Without zInitMusicPlayback forcefully muting all channels, there's the
	; risk of music accidentally playing noise because it can't detect if
	; the PSG4/noise channel needs muting, on track initialisation.
	; This bug can be heard be playing the End of Level music in CNZ, whose
	; music uses the noise channel. S&K's driver contains a fix just like this.
	cp	0DFh		; Are we stopping PSG3?
	ret	nz
	ld	a,0FFh		; If so, stop noise channel while we're at it
	ld	(zPSG),a	; Stop noise channel
	ret
; End of function zPSGNoteOff


;zloc_5F4
zPSGSilenceAll:
	ld	hl,zPSG		; PSG reg
	ld	(hl),9Fh	; Stop channel 0
	ld	(hl),0BFh	; Stop channel 1
	ld	(hl),0DFh	; Stop channel 2
	ld	(hl),0FFh	; Stop noise channel
	ret

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||
;zsub_600
zPauseMusic:
	jp	m,+		; If we are to unpause music, branch
zPaused = $+1
	ld	a,0		; Get paused flag
	or	a				; Are we paused already?
	ret	nz				; If so, return
	ld	a,0FFh			; a = 0FFh
	ld	(zPaused),a		; Set paused flag
	ld	a,0DAh				; jp c, (carry is cleared by the preceeding 'or' instuction, so the branch never executes)
	ld	(zDPCMWaitLoopJumpInstruction),a	; Pause DAC loop
	ld	(zPCMWaitLoopJumpInstruction),a		; Pause DAC loop
	call	zFMSilenceAll
	jp	zPSGSilenceAll
+
	;push	ix			; Save ix
	xor	a				; a = 0
	ld	(ix+zVar.StopMusic),a		; Clear pause/unpause flag
	ld	(zPaused),a		; Clear paused flag
	ld	a,0C2h				; jp nz,
	ld	(zDPCMWaitLoopJumpInstruction),a	; Resume DAC loop
	ld	(zPCMWaitLoopJumpInstruction),a		; Resume DAC loop
zRestoreSound:
	ld	ix,zSongDACFMStart	; ix = pointer to track RAM
	ld	b,MUSIC_DAC_FM_TRACK_COUNT				; 1 DAC + 6 FM
	call	zResumeTrack

	ld	a,(zAbsVar.1upPlaying)
	or	a
	ret	nz

	rst	zBankSwitchToSFX		; Now for SFX

	ld	a,0FFh			; a = 0FFH
	ld	(zDoSFXFlag),a	; Set flag to say we are updating SFX
	ld	ix,zSFX_FMStart	; ix = pointer to SFX track RAM
	ld	b,SFX_FM_TRACK_COUNT				; 3 FM
	call	zResumeTrack
	xor	a				; a = 0
	ld	(zDoSFXFlag),a	; Clear SFX updating flag
	;rst	zBankSwitchToMusic	; Back to music (Pointless: music isn't updated until the next frame)
	;pop	ix				; Restore ix (nothing uses this, beyond this point...)
	ret
; End of function zPauseMusic


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||
;zsub_64D
zResumeTrack:
	bit	7,(ix+zTrack.PlaybackControl)		; Is track playing?
	jr	z,+				; Branch if not
	bit	2,(ix+zTrack.PlaybackControl)		; Is SFX overriding track?
	jr	nz,+			; Branch if not
	; ld	c,(ix+zTrack.AMSFMSPan)		; AMS/FMS/panning flags
	; ld	a,(ix+zTrack.VoiceControl)		; Get voice control bits...
	; and	3				; ... the FM portion of them
	; add	a,0B4h			; Command to select AMS/FMS/panning register
	; rst	zWriteFMIorII
	push	bc			; Save bc
	call	zSetVoiceMusic
	pop	bc				; Restore bc
+
	ld	de,zTrack.len		; de = Track size
	add	ix,de			; Advance to next track
	djnz	zResumeTrack	; loop
	ret
; End of function zResumeTrack


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||
;zsub_674
zCycleQueue:
	ld	a,(zAbsVar.QueueToPlay)	; Check if a sound request was made zComRange+08h
	or	a					; Is queue slot equal to 80h?
	ret	nz					; If not, return
	ld	hl,zAbsVar.SFXToPlay		; Get address of next sound
	ld	a,(zAbsVar.SFXPriorityVal)		; Get current SFX priority
	ld	d,a					; a -> c
	ld	b,zVar.SoundQueueEnd-zVar.SoundQueueStart					; b = 3

-	ld	a,(hl)				; Get sound to play -> 'a'
	ld	e,a					; 'a' -> 'e'
	ld	(hl),0				; Clear it back to zero (we got it)
	inc	hl					; hl = pointer to next queue item
	cp	MusID__First		; Is it before first music?
	jr	c,zlocQueueNext		; if so, branch
	cp	DACSFXID__First		; Is it a special command?
	jr	nc,zlocQueueItem	; If so, branch
	sub	SndID__First		; Subtract first SFX index
	jr	c,zlocQueueItem		; If it was music, branch
	push	af
	rst	zBankSwitchToSFX			; Switch to SFX banks
	pop	af
	ld	hl,zmake68kPtr(SoundIndex+2)
	ld	c,a
	ld	b,0
	add	hl,bc
	add	hl,bc
	add	hl,bc
	ld	a,(hl)				; Get SFX priority
	cp	d					; Is the new SFX of a higher priority?
	jr	c,+					; Branch if not
	ld	d,a					; Save new priotity
	call	zlocQueueItem	; Queue the new SFX
+
	rst	zBankSwitchToMusic			; Switch to music banks
	ld	a,d					; Get back SFX priority
	or	a					; Is it negative (jumping sound)?
	ret	m					; Return if so
	ld	(zAbsVar.SFXPriorityVal),a		; Store the new priority
	ret
; ---------------------------------------------------------------------------
zlocQueueNext:
	djnz	-
	ret
; ---------------------------------------------------------------------------
zlocQueueItem:
	ld	a,e				; restore a to be the last queue item read
	ld	(zAbsVar.QueueToPlay),a	; Put it as the next item to play
	ret
; End of function zCycleQueue


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||
; zsub_6B2:
zPlaySoundByIndex:
	;or	a							; is it sound 00?
	;jp	z,zClearTrackPlaybackMem	; if yes, branch to RESET EVERYTHING!!
    ;if MusID__First-1 == 80h
	;ret	z							; return if it was (invalidates 00h-7Fh; maybe we don't want that someday?)
    ;else
	;cp	MusID__First
	;ret	c		; return if id is less than the first music id
    ;endif

	ld	(ix+zVar.QueueToPlay),0					; Rewrite zComRange+8 flag so we know nothing new is coming in
	cp	MusID__End					; is it music (less than index 20)?
	jp	c,zPlayMusic				; if yes, branch to play the music
	cp	SndID__End					; is it a sound (less than index 71)?
	jp	c,zPlaySound_Main			; if yes, branch to play the sound
	cp	DACSFXID__First
	ret	c
	cp	DACSFXID__End
	jp	c,zPlayDACSFX
	cp	CmdID__First				; is it after the last regular sound but before the first special sound command (between 71 and 78)?
	ret	c							; if yes, return (do nothing)
	; Otherwise, this is a special command to the music engine...
	sub	CmdID__First	; convert index 78-7D to a lookup into the following jump table
	add	a,a
	add	a,zCommandIndex&0FFh
	ld	(.writeme+1),a
.writeme:
	ld	hl,(zCommandIndex)
	jp	(hl)

	ensure1byteoffset 0Ch
; zloc_6D5:
zCommandIndex:
; ---------------------------------------------------------------------------
CmdPtr_StopSFX:		dw	zStopSoundEffects ; sound test index 78
; ---------------------------------------------------------------------------
CmdPtr_FadeOut:		dw	zFadeOutMusic ; 79
; ---------------------------------------------------------------------------
CmdPtr_SegaSound:	dw	zPlaySegaSound ; 7A
; ---------------------------------------------------------------------------
CmdPtr_SpeedUp:		dw	zSpeedUpMusic ; 7B
; ---------------------------------------------------------------------------
CmdPtr_SlowDown:	dw	zSlowDownMusic ; 7C
; ---------------------------------------------------------------------------
CmdPtr_Stop:		dw	zStopSoundAndMusic ; 7D
; ---------------------------------------------------------------------------
CmdPtr__End:
; ---------------------------------------------------------------------------
; zloc_6EF:
zPlaySegaSound:
	; reset panning (don't want Sega sound playing on only one speaker)
	ld	a,0B6h			; Set Panning / AMS / FMS
	ld	c,0C0h			; default Panning / AMS / FMS settings (only stereo L/R enabled)
	rst	zWriteFMII		; Set it!

	ld	a,80h			; Command to enable DAC
	ld	(zDACEnabled),a
	ld	c,a
	ld	a,2Bh			; DAC enable/disable register
	rst	zWriteFMI

	call	zFMSilenceAll
	call	zPSGSilenceAll
	ld	a, zmake68kBank(SegaSndTbl)
	rst	zBankSwitch
	; Table Format:
	; pp bb s1 s0 l1 l0
	; bb = Bank, s1s0 = start offset, l1l0 = data length, pp = pitch
zPCMSound = $+1
	ld	a, 0
	add	a, a
	ld	b, 00h
	ld	c, a
	ld	hl, zmake68kPtr(SegaSndTbl)
	add	hl, bc
	add	hl, bc
	add	hl, bc
	ld	c, (hl)	; pitch
	inc	hl
	ld	a, (hl)	; bank
	inc	hl
	ld	d, (hl)	; start offset MSB
	inc	hl
	ld	e, (hl)	; start offset LSB
	inc	hl
	ld	b, (hl)	; data size MSB
	inc	hl
	ld	l, (hl)	; data size LSB
	ld	h, b

	push	hl
	ld	(zCurPCMBnk), a
	rst	zBankSwitch
	pop	hl
	ex	de, hl

	ld	(iy+0),2Ah	; Select it
zPCMLoop:
	ld	a, (hl)			; Get next PCM byte
	ld	(iy+1), a	; Send to DAC
	inc	hl
	dec	de				; 1 byte less to play
	ld	b, c
	djnz	$			; Delay loop

	ld	a, d			; a = d
	or	e				; Is de zero?
	jr	z, zPCMLoopExit	; If so, exit

	ld	a, (zAbsVar.QueueToPlay)	; Get next item to play
	or	a
	jr	nz, zPCMLoopExit

	or	h
	jp	m, zPCMLoop
zPCMBankAdvance:
	ld	hl, zCurPCMBnk
	inc	(hl)	; next Z80 bank
	ld	a, (hl)
	rst	zBankSwitch
	ld	h, 80h	; L is already 0
	jr	zPCMLoop

zPCMLoopExit:
	xor	a
	ld	(zDoSFXFlag), a
	rst	zBankSwitchToMusic
	call	zRestoreSound
	pop	bc			; prevent music/SFX from being processed this frame
	jp	zUpdateDAC		; (alternatively call zBankSwitchToMusic)
; ---------------------------------------------------------------------------
; zloc_73D:
zPlayMusic:
	; Clownacy: These weren't here in S1's driver, which exposed a bug.
	; Now that the bug's been fixed, this workaround doesn't need to be here anymore.
	;push	af
	;call	zStopSoundEffects		; Stop all sounds before starting BGM
	;pop	af

	; Get requested song's metadata
	sub	MusID__First			; Make it a zero-based entry ...
	ld	e,a						; Transform 'a' into 16-bit de
	ld	d,0
	rst	zBankSwitchToSFX
	ld	hl,zmake68kPtr(zMasterPlaylist); Get address of the zMasterPlaylist
	add	hl,de			; Add the 16-bit offset here
	add	hl,de			; Add the 16-bit offset here
	add	hl,de			; Add the 16-bit offset here
	add	hl,de			; Add the 16-bit offset here
	ld	a,(hl)
	ld	(zBGMLoad_BankLoadInstruction+1),a
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	ld	(zBGMLoad_AddressLoadInstruction+1),de
	ld	a,(hl)			; Get song flags
	rla
	ld	(zBGMLoad_FlagLoadInstruction+1),a
	jr	nc,zloc_784

	; The following code disables all sound (technically for duration of 1-up)
	ld	a,(zAbsVar.1upPlaying)			; Check if 1-up sound is already playing
	or	a							; Test it
	jr	nz,zBGMLoad					; If it is, then just reload it!  (I suppose a humorous restore-to-1up could happen otherwise... with no good results after that)
	ld	ix,zTracksStart				; Starting at beginning of all tracks...
	ld	de,zTrack.len					; Each track size
	ld	b,MUSIC_TRACK_COUNT						; All 10 (DAC, 6FM, 3PSG) tracks

-	res	2,(ix+zTrack.PlaybackControl)					; Clear "SFX is overriding" bit (no SFX are allowed!)
	add	ix,de						; Next track
	djnz	-

	; This performs a "massive" backup of all of the current track positions
	; for restoration after 1-up BGM completes
	; Backup music
	ld	de,zTracksSaveStart	; Backup memory address
	ld	hl,zTracksStart
	ld	bc,zTracksSaveEnd-zTracksSaveStart		; for this many bytes
	ldir					; Go!
	; Backup variables
	ld	hl,zAbsVar
	ld	bc,zVar.len		; for this many bytes
	ldir					; Go!

	ld	a,80h
	ld	(zAbsVar.1upPlaying),a	; Set 1-up song playing flag
	xor	a
	ld	(zAbsVar.SFXPriorityVal),a		; Clears SFX priority
	jr	zBGMLoad			; Now load 1-up BGM
; ---------------------------------------------------------------------------

zloc_784:
	ld	(cfFadeInToPrevious_FlagLoadInstruction+1),a
	ld	(cfFadeInToPrevious_AddressLoadInstruction+1),de

	ld	hl,zAbsVar.1upPlaying
	bit	7,(hl)
	jr	z,+
	; SFX will be re-enabled, but we don't want the backed-up music data being treated as SFX data
	ld	ix,zTracksSFXStart
	ld	b,SFX_TRACK_COUNT
	ld	de,zTrack.len

-	res	7,(ix+zTrack.PlaybackControl)
	add	ix,de
	djnz	-
+
	xor	a
	ld	(hl),a	; clear 1-up is playing flag (it isn't)
	ld	(zAbsVar.FadeInCounter),a	; clear fade-in frame count
	ld	(zAbsVar.FadeOutCounter),a		; clear fade-out frame count

;zloc_78E
zBGMLoad:
	call	zInitMusicPlayback
zBGMLoad_AddressLoadInstruction:
	ld	de,0
zBGMLoad_BankLoadInstruction:
	ld	a,0			; Get song flags
	ld	(zAbsVar.MusicBankNumber),a; Store bank index
	rst	zBankSwitch
zBGMLoad_FlagLoadInstruction:
	ld	c,0			; Get song flags
	sla	c				; Put bit 7 into carry flag (force PAL speed flag)
	ccf					; Invert carry flag...
	sbc	a,a				; ... reverse subtract with carry that was set to zero ... umm.. a=0 in a funny way?
	ld	(zAbsVar.IsPalFlag),a	; Clear IsPalFlag?
	sla	c
	sbc	a,a
	ld	(zCanNotBeSpedUp),a
	sla	c				; Put bit 6 into carry flag (uncompressed data flag)
	; If we bypass the Saxman decompressor, the Z80 engine starts
	; with the assumption that we're already decompressed with 'de' pointing
	; at the decompressed data (which just so happens to be the ROM window)
	jr	c,+	; Bypass the Saxman decompressor if uncompressed

	; This begins a call to the Saxman decompressor:
	ex	de,hl
	call	zSaxmanDec
	ld	de,zMusicData	; Saxman compressed songs start at zMusicData (1380h)
+
	; Begin common track init code
	push	de
	pop	ix					; ix = de (BGM's starting address)
	ld	l,(ix+0)			; Get voice table pointer low byte -> 'e'
	ld	h,(ix+1)			; Get voice table pointer high byte -> 'd'
	add	hl,de
	ld	(zBGMLoad_VoiceAddrInstruction+1),hl	; Set master copy of this value in local memory
	ld	a,(ix+5)			; Get main tempo value
	ld	(zAbsVar.TempoMod),a	; Store it at (zComRange+12h)
	ld	(zAbsVar.CurrentTempo),a		; Current tempo for TempoWait
	ld	(zAbsVar.TempoTimeout),a		; Tempo accumulator for TempoWait
	ld	a,5
	ld	(zPALUpdTick),a		; reset PAL update tick to 5 (update immediately)
	push	ix
	pop	hl					; hl = ix (BGM's starting address)
	ld	de,6
	add	hl,de				; +06h (to DAC pointer)
	ld	a,(ix+2)			; Get number of FM+DAC channels this BGM has
	or	a					; Test it
	jp	z,zloc_884			; If zero, then don't init any
	ld	b,a					; 'a' -> 'b' (num FM+DAC channels this song, for loop)
	push	iy				; Save 'iy'
	ld	iy,zTracksStart		; 'iy' points to start of track memory
	ld	c,(ix+4)			; Get tempo divider -> 'c'
	; The bugfix in zInitMusicPlayback does this, already
	;ld	de,zFMDACInitBytes	; 'de' points to zFMDACInitBytes

-	ld	(iy+zTrack.PlaybackControl),82h			; At "playback control" byte of this track, set "track is playing" bit and "SFX is overriding" (?) bit (I think just to keep it from playing until init is done)
	; The bugfix in zInitMusicPlayback does this, already
	;ld	a,(de)				; Get current byte from zFMDACInitBytes -> 'a'
	;inc	de					; will get next byte from zFMDACInitBytes next time
	;ld	(iy+zTrack.VoiceControl),a			; Store this byte to "voice control" byte
	ld	(iy+zTrack.TempoDivider),c			; Store timing divisor from header for this track
	ld	(iy+zTrack.StackPointer),zTrack.GoSubStack	; set "gosub" (coord flag F8h) stack init value (starts at end of this track's memory)
	ld	(iy+zTrack.AMSFMSPan),0C0h			; default Panning / AMS / FMS settings (only stereo L/R enabled)
	ld	(iy+zTrack.DurationTimeout),1			; set current duration timeout to 1 (should expire next update, play first note, etc.)
zBGMLoad_VoiceAddrInstruction:
	ld	de,0
	ld	(iy+zTrack.VoicePtrLow),e
	ld	(iy+zTrack.VoicePtrHigh),d
	; The bugfix in zInitMusicPlayback does this, already
	;push	de				; saving zFMDACInitBytes pointer
	push	bc				; saving number of channels and tempo divider ('bc' gets needlessly damaged by 'ldi' instructions coming up)

	call	zConvertTrackHeaderPointerToAbsolute

	ld	a,iyl				; current track pointer low byte -> 'a'
	add	a,zTrack.DataPointerLow
	ld	e,a
	adc	a,iyu
	sub	e
	ld	d,a					; de = iy + 3 ('de' is pointing to track offset address)

	call	zStoreAbsoluteTrackAddressToTrackRAM

	ldi						; *de++ = *hl++ (default key offset, typically 0, can be set later by coord flag E9)
	ldi						; *de++ = *hl++ (track default volume)
	ld	de,zTrack.len			; size of all tracks -> 'de'
	add	iy,de				; offset to next track!
	pop	bc					; restore 'bc' (number of channels and tempo divider)
	; The bugfix in zInitMusicPlayback does this, already
	;pop	de					; restore 'de' (zFMDACInitBytes current pointer)
	djnz	-				; loop for all tracks we're init'ing...
	; End of FM+DAC track init loop

	pop	iy					; restore 'iy'
	ld	a,(ix+2)			; 'ix' still points to start of BGM; get number of FM+DAC -> 'a'
	cp	7					; Does it equal 7?  (6 FM channels)
	jr	nz,+				; If not, skip this next part
	xor	a					; Clear 'a'
	jr	zloc_87E			; jump to zloc_87E
+
	; Silence FM Channel 6 specifically if it's not in use
	; ld	a,28h				; Key on/off FM register
	; ld	c,6					; FM channel 6
	; rst	zWriteFMI			; All operators off
	; ld	a,42h				; Starting at FM Channel 6 Operator 1 Total Level register
	; ld	c,0FFh				; Silence value
	; ld	b,4					; Write to all four FM Channel 6 operators

	; ; Set all TL values to silence!
; -	rst	zWriteFMII
	; add	a,4					; Next operator
	; djnz	-

	ld	a,0B6h				; Set Panning / AMS / FMS
	ld	c,0C0h				; default Panning / AMS / FMS settings (only stereo L/R enabled)
	rst	zWriteFMII			; Set it!
	ld	a,80h				; FM Channel 6 is NOT in use (will enable DAC)

zloc_87E:
	; End of DAC/FM init, begin PSG init

zloc_884:
	ld	a,(ix+3)			; Get number of PSG tracks
	or	a					; Test it
	jp	z,zloc_8D0			; If zero, skip this part!
	ld	b,a					; 'a' -> 'b' (num PSG tracks this song, for loop)
	push	iy				; Save 'iy'
	ld	iy,zSongPSG1		; 'iy' points to start of PSG track memory (7 prior tracks were DAC and 6 FM)
	ld	c,(ix+4)			; Get tempo divider -> 'c'
	; The bugfix in zInitMusicPlayback does this, already
	;ld	de,zPSGInitBytes	; 'de' points to zPSGInitBytes

-	ld	(iy+zTrack.PlaybackControl),82h			; At "playback control" byte of this track, set "track is playing" bit and "SFX is overriding" (?) bit (I think just to keep it from playing until init is done)
	; The bugfix in zInitMusicPlayback does this, already
	;ld	a,(de)				; Get current byte from zPSGInitBytes -> 'a'
	;inc	de					; will get next byte from zPSGInitBytes next time
	;ld	(iy+zTrack.VoiceControl),a			; Store this byte to "voice control" byte
	ld	(iy+zTrack.TempoDivider),c			; Store timing divisor from header for this track
	ld	(iy+zTrack.StackPointer),zTrack.GoSubStack	; "gosub" stack init value
	ld	(iy+zTrack.DurationTimeout),1			; set current duration timeout to 1 (should expire next update, play first note, etc.)
	; The bugfix in zInitMusicPlayback does this, already
	;push	de				; saving zPSGInitBytes pointer
	push	bc				; saving number of channels and tempo divider ('bc' gets needlessly damaged by 'ldi' instructions coming up)

	call	zConvertTrackHeaderPointerToAbsolute

	ld	a,iyl				; current track pointer low byte -> 'a'
	add	a,zTrack.DataPointerLow
	ld	e,a
	adc	a,iyu
	sub	e
	ld	d,a					; de = iy + 3 ('de' is pointing to track offset address)

	call	zStoreAbsoluteTrackAddressToTrackRAM

	ldi						; *de++ = *hl++ (default key offset, typically 0, can be set later by coord flag E9)
	ldi						; *de++ = *hl++ (track default volume)
	inc	hl					; Get default PSG tone
	ld	a,(hl)				; -> 'a'
	inc	hl					; This byte is usually the same as the prior, unused
	ld	(iy+zTrack.VoiceIndex),a			; Store current PSG tone
	ld	de,zTrack.len			; size of all tracks -> 'de'
	add	iy,de				; offset to next track!
	pop	bc					; restore 'bc' (number of channels and tempo divider)
	; The bugfix in zInitMusicPlayback does this, already
	;pop	de					; restore 'de' (zPSGInitBytes current pointer)
	djnz	-				; loop for all tracks we're init'ing...

	pop	iy					; restore 'iy'
	; End of PSG tracks init, begin SFX tracks init

zloc_8D0:
	ld	a,(zAbsVar.1upPlaying)
	or	a
	jr	nz,zBGMLoad_SFXEnd

	ld	ix,zTracksSFXStart		; 'ix' points to start of SFX track memory (10 prior tracks were DAC, 6 FM, 3 PSG)
	ld	b,SFX_TRACK_COUNT					; 6 SFX tracks total (3FM, 3PSG)
	ld	de,zTrack.len			; size between tracks

zloc_8D9:
	bit	7,(ix+zTrack.PlaybackControl)			; Is this track currently playing?
	jr	z,zloc_8FB			; If not, jump to zloc_8FB (no work to do!)
	ld	a,(ix+zTrack.VoiceControl)			; Get "voice control" byte...
	or	a					; Test it
	jp	m,+					; If this is a PSG track, jump to '+'
	sub	2					; Otherwise, subtract 2...
	add	a,a					; ... multiply by 2 (preparing to index starting from FM 3 only)
	jr	zloc_8F1			; Jump to zloc_8F1 (general track setup)
+
	rra
	rra
	rra
	rra
	and	0Fh					; for PSG, just shift it down by 4 and we have its index!

zloc_8F1:
	add	a,zMusicTrackOffs&0FFh	; get offset into appropriate music track...
	ld	(zloc_8F6+1),a			; store into the instruction after zloc_8F6 (self-modifying code)
zloc_8F6:
	ld	hl,(zMusicTrackOffs)	; This loads address of corresponding MUSIC track (the track that this SFX track would normally play over)
	; Clownacy: This line is a bug
	;res	2,(hl)				; Clear the "SFX override" bit (Why??? According to S1's driver, this should be a 'set')
	; Clownacy: This is better
	set	2,(hl)				; Set the "SFX override" bit

zloc_8FB:
	add	ix,de				; Next track..
	djnz	zloc_8D9		; Loop for all tracks
	; End of SFX tracks init...

zBGMLoad_SFXEnd:
	ld	ix,zSongFM1	; 'ix' points to first FM music track
	ld	b,MUSIC_FM_TRACK_COUNT							; For all 6 of those...

-	push	bc
	bit	2,(ix+zTrack.PlaybackControl)		; Is bit 2 (SFX overriding) set?
	call	z,zFMSilenceChannel	; If not, branch
	add	ix,de						; Next track
	pop	bc
	djnz	-

	ld	b,MUSIC_PSG_TRACK_COUNT								; For all 3 PSG tracks...

-	call	zPSGNoteOff				; Send Note Off
	add	ix,de						; Next track
	djnz	-

	ret

zFMSilenceChannel:
	call	zSetMaxRelRate
	ld	a,(ix+zTrack.VoiceControl)		; Get voice control byte
	and	3			; Channels only!
	add	a,40h			; Set total level...
	ld	c,7Fh			; ... to minimum envelope amplitude...
	call	zFMOperatorWriteLoop	; ... for all operators of this track's channel
	jp	zFMNoteOff

zSetMaxRelRate:
	ld	a,(ix+zTrack.VoiceControl)		; Get voice control byte
	and	3			; Channels only!
	add	a,80h			; Add register 80, set D1L to minimum and RR to maximum...
	ld	c,0FFh			; ... for all operators on this track's channel

zFMOperatorWriteLoop:
	ld	b,4			; Loop 4 times

.loop:
	rst	zWriteFMIorII		; Write to part I or II, as appropriate
	add	a,4			; a += 4
	djnz	.loop			; Loop
	ret

zConvertTrackHeaderPointerToAbsolute:
	; Get track address, and convert it to absolute
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	ex	hl,de
	add	hl,de
	push	hl
	pop	bc
	ex	hl,de
	ret

zStoreAbsoluteTrackAddressToTrackRAM:
	; Store absolute address (bc) into track RAM
	ex	hl,de
	ld	(hl),c
	inc	hl
	ld	(hl),b
	inc	hl
	ex	hl,de
	ret

; ---------------------------------------------------------------------------
; FM channel assignment bits
;zbyte_916
zFMDACInitBytes:
	db    6,   0,   1,   2,   4,   5,   6		; first byte is for DAC; then notice the 0, 1, 2 then 4, 5, 6; this is the gap between parts I and II for YM2612 port writes

; Default values for PSG tracks
;zbyte_91D
zPSGInitBytes:
	db  80h,0A0h,0C0h	; Specifically, these configure writes to the PSG port for each channel

zPlaySound_Checks:
	xor	a
	ld	(zSpindashActiveFlag),a			; Clear spindash sound flag
	ld	a,c								; Sound index -> 'a'

	cp	SndID_Ring						; is this the ring sound?
	jr	z,zPlaySound_CheckRing			; if not, branch
	cp	SndID_Gloop						; is this the bloop/gloop noise?
	jr	z,zPlaySound_CheckGloop			; if not, branch
	cp	SndID_PushBlock					; is this the pushing block noise?
	jr	z,zPlaySound_CheckPush			; if not, branch
	cp	SndID_SpindashRev				; is this the spindash rev sound playing?
	jr	z,zPlaySound_CheckSpindash		; if not, branch
	ret

zPlaySound_CheckRing:
	; This is the ring sound...
zRingSpeaker = $+1
	ld	a,0							; 0 plays left, FFh plays right
	xor	0FFh							; If it was 0, it's now FFh, or vice versa
	ld	(zRingSpeaker),a							; Store new ring speaker value (other side)
	ret	z								; If it's zero, we play RingRight
	ld	c,SndID_RingLeft				; play RingLeft
	ret									; now play the play the ring sound
; ---------------------------------------------------------------------------
; zloc_942:
zPlaySound_CheckGloop:
zGloopFlag = $+1
	ld	a,0
	cpl
	ld	(zGloopFlag),a
	or	a
	ret	nz ; now play the play the gloop sound
zPlaySound_ret:
	pop	bc ; sometimes don't play it
	ret
; ---------------------------------------------------------------------------
; zloc_942:
zPlaySound_CheckPush:
zPushFlag = $+1
	ld	a,0
	or	a
	jr	nz, zPlaySound_ret
	cpl
	ld	(zPushFlag),a
	ret
; ---------------------------------------------------------------------------
; zloc_953:
zPlaySound_CheckSpindash:
	ld	hl, zSpindashExtraFrequencyIndex
	ld	a,(zSpindashPlayingCounter)
	or	a
	ld	a,(hl)
	jr	nz,+ ; if the spindash sound is already playing, branch
	ld	a,-1 ; reset the extra frequency (becomes 0 on the next line)
+
	inc	a ; increase the frequency
	cp	12
	jr	nc,+
	ld	(hl),a
+
	ld	a,60
	ld	(zSpindashPlayingCounter),a
	ld	a,-1
	ld	(zSpindashActiveFlag),a
	ret

; zloc_920:
zPlaySound_Main:
	ld	c,a								; Store sound index -> 'c'
	ld	a,(ix+zVar.1upPlaying)						; Get "is 1-up playing" flag...
	or	(ix+zVar.FadeInFlag)						; Or it with fading in flag
	jp	nz,zloc_KillSFXPrio				; If either is set, SFX cannot be played!!
	call	zPlaySound_Checks

; zloc_975:
zPlaySound:
	rst	zBankSwitchToSFX			; Switch to SFX banks

	ld	hl,zmake68kPtr(SoundIndex)		; 'hl' points to beginning of SFX bank in ROM window
	ld	a,c								; 'c' -> 'a'
	sub	SndID__First					; Bring 'a' down to index value
	ld	e,a
	ld	d,0								; de = a
	add	hl,de
	add	hl,de
	add	hl,de							; now hl points to a pointer in the SoundIndex list (such as rom_ptr_z80 Sound20)
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a								; now hl points to a sound's data (such as Sound20: ...)
	ld	e,l
	ld	d,h
	ld	c,(hl)
	inc	hl
	ld	b,(hl)							; 'de' points to custom voice table (if any; otherwise is 0000h)
	inc	hl
	ex	hl,de
	add	hl,bc
	ex	hl,de
	ld	(zloc_A26+1),de	; store into the instruction after zloc_A26 (self-modifying code)
	ld	c,(hl)							; Timing divisor -> 'c'
	inc	hl
	ld	b,(hl)							; Total channels used -> 'b'
	inc	hl

zloc_99F:
	push	bc							; backup divisor/channel usage
	xor	a								; a = 0 (will end up being NO CUSTOM VOICE TABLE!)
	ld	(zloc_A1D+1),a ; store into the instruction after zloc_A1D (self-modifying code) (Kind of pointless, always sets it to zero... maybe PSG would've had custom "flutter" tables?)
	push	hl							; save current position within sound (offset 04h)

	ld	a,(hl)							; Track sound def -> 'a' (if 80h set, it's PSG, otherwise it's FM) -- note this also tells what channel it's on (80, A0, C0 for PSG, FM channel assignments otherwise)
	or	a								; test it
	jp	m,+								; if bit 7 (80h) set (meaning PSG track), skip next part...
	sub	2								; Subtract 2 from this value
	add	a,a								; Multiply it by 2
	jp	zloc_9CA						; This is an FM sound track...
+
	; This is a PSG track!
	; Always ends up writing zero to voice table pointer?
	ld	(zloc_A1D+1),a	; store into the instruction after zloc_A1D (self-modifying code)
	cp	0C0h							; Is this PSG3?
	jr	nz,+							; If not, skip this part
	push	af
	or	1Fh								; Set silence on PSG!
	ld	(zPSG),a
	xor	20h
	ld	(zPSG),a
	pop	af
+
	rra
	rra
	rra
	rra
	and	0Fh					; for PSG, just shift it down by 4 and we have its index!

zloc_9CA:
	add	a,zMusicTrackOffs&0FFh			; Offset to corresponding music track
	ld	(zloc_9CF+1),a	; store into the instruction after zloc_9CF (self-modifying code)
zloc_9CF:
	ld	hl,(zMusicTrackOffs)			; 'hl' is now start of corresponding music track
	set	2,(hl)							; Set "SFX is overriding this track!" bit
	add	a,zSFXTrackOffs-zMusicTrackOffs	; Jump to corresponding SFX track
	ld	(zloc_9D9+2),a	; store into the instruction after zloc_9D9 (self-modifying code)
zloc_9D9:
	ld	ix,(zSFXTrackOffs)				; 'ix' is now start of corresponding SFX track

	; Little bit busy there, but basically for a given 'a' value, where a == 0
	; means first SFX track (FM3), 'hl' now points to the music track and 'ix' points
	; to the SFX track that both correspond to track 'a'

	; Now we're going to clear this SFX track...
	ld	e,ixl
	ld	d,ixu							; de = ix
	ld	l,e								; hl = de (start of SFX track)
	ld	h,d
	ld	(hl),0							; store 00h on first byte of track
	inc	de								; next byte...
	push	de							; save 'de'
	ld	bc,zTrack.len-1					; For all bytes in the track, minus 1 (since we're copying 00h from first byte)
	ldir								; Clear track memory!
	pop	de								; Restore 'de' (start of SFX track yet again)
	pop	hl								; Get 'hl' back from way before (offset of sound in ROM + 04h)
;	ld	a,e
;	add	a,zTrack.PlaybackControl
;	ld	e,a
;	adc	a,d
;	sub	e
;	ld	d,a
	ldi									; *de++ = *hl++ (write voice control byte) (sets whether is PSG or what)
	pop	bc								; restore 'bc'...
	push	bc							; ... Um, back it up again!
	set	7,(ix+zTrack.PlaybackControl)						; write playback control byte ('track is playng' bit)
	ld	(ix+zTrack.TempoDivider),c						; Set timing divisor of SFX track
	ld	(ix+zTrack.DurationTimeout),1						; current duration timeout to 1 (will expire immediately and thus update)
	ld	(ix+zTrack.StackPointer),zTrack.GoSubStack				; Reset track "gosub" stack
	inc	de							; de += 1 (skip timing divisor; already set)
	ld	bc,3
	ldir						; while (bc-- > 0) *de++ = *hl++; (copy track address, default key offset)

	; If spindash active, the following block updates its frequency specially:
zSpindashActiveFlag = $+1
	ld	a,0
	or	a
	jr	z,+									; If spindash not last sound played, skip this
	ld	a,(zSpindashExtraFrequencyIndex)	; Get current frequency index
	dec	de									; Go back to key offset
	ex	de,hl								; hl <=> de
	add	a,(hl)								; Add spindash key offset!
	ex	de,hl								; de <=> hl (just done because we wanted add a,(hl))
	ld	(de),a								; Store it!
	inc	de									; Go passed key offset again
+
	ldi									; *de++ = *hl++ (channel volume)
zloc_A1D:	; Modified way back within zloc_99F
	ld	a,0								; "self-modified code"; if 00h, no custom voice table defined for this track
	or	a								; Test it
	jr	nz,+							; If not zero, skip next part...
	ld	(ix+zTrack.AMSFMSPan),0C0h						; Default panning / AMS / FMS settings (just L/R Stereo enabled)
zloc_A26:
	ld	de,0 ; "self-modified code"		; This will be modified to custom voice table address (possibly still 0000h)
	ld	(ix+zTrack.VoicePtrLow),e						; low byte of custom voice table (for SFX)
	ld	(ix+zTrack.VoicePtrHigh),d						; high byte of custom voice table (for SFX)
+
	pop	bc								; restore divisor (c) and channel counts (b0)
	dec	b								; One less FM channel
	jp	nz,zloc_99F						; If more to go, loop!

	;jp	zBankSwitchToMusic				; Otherwise, prepare to do music...
	rst	zBankSwitchToMusic
	ret
; ---------------------------------------------------------------------------

zloc_KillSFXPrio:
	xor	a
	ld	(zAbsVar.SFXPriorityVal),a					; Reset SFX priority
	ret
; End of function zPlaySoundByIndex

zPlayDACSFX:
	sub	DACSFXID__First
	ld	c,a
	ld	b,0
	ld	hl,zDACSFXList
	add	hl,bc
	ld	b,(hl)
	ld	c,0C0h		; default Panning / AMS / FMS settings (only stereo L/R enabled)
	ld	d,80h		; This is a DAC SFX
	jp	zPlayDAC

	include "dacsfxlist.gen.asm"

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

; zsub_A3C:
zStopSoundEffects:
	ld	a,(zAbsVar.1upPlaying)
	or	a
	ret	nz

	xor	a
	ld	(zAbsVar.SFXPriorityVal),a					; Reset SFX priority
	ld	ix,zTracksSFXStart		; 'ix' points to start of SFX track memory (10 prior tracks were DAC, 6 FM, 3 PSG)
	ld	b,SFX_TRACK_COUNT							; All 6 SFX tracks...

zloc_A46:
	push	bc							; Save 'bc'
	bit	7,(ix+zTrack.PlaybackControl)						; Check if this track was playing
	jp	z,zloc_AB6						; If not
	res	7,(ix+zTrack.PlaybackControl)						; You're not playing anymore!
	res	4,(ix+zTrack.PlaybackControl)						; Not not attacking, either
	ld	a,(ix+zTrack.VoiceControl)						; Get "voice control" byte
	or	a								; Test it
	jp	m,zloc_A89						; If 80h set (PSG Track) jump to zloc_A89
	push	af
	call	zFMNoteOff					; FM Key off
	pop	af
	push	ix
	sub	2								; Determine proper corresponding music track (starting on FM3, so subtract 2 from channel assignment)
	add	a,a								; Multiply by 2 (each index 2 bytes)
	add	a,zMusicTrackOffs&0FFh			; Get offset -> 'a'
	ld	(zloc_A6C+2),a	; store into the instruction after zloc_A6C (self-modifying code)
zloc_A6C:
	ld	ix,(zMusicTrackOffs) ; "self-modified code"; will load appropriate corresponding music track address
	bit	2,(ix+zTrack.PlaybackControl)						; Was this music track is overridden by an SFX track?
	jr	z,+								; If not, do nothing
	res	2,(ix+zTrack.PlaybackControl)						; Otherwise, tell it is is no longer!
	set	1,(ix+zTrack.PlaybackControl)						; Set track to rest
	call	zSetVoiceMusic				; Reset FM voice
+
	pop	ix
	jp	zloc_AB6						; jump down to loop
; ---------------------------------------------------------------------------

zloc_A89:
	push	af
	call	zPSGNoteOff					; PSG Note off
	pop	af
	push	ix
	rra
	rra
	rra
	rra
	and	0Fh		; 'a' is now 08, 0A, 0C, or 0E
	add	a,zMusicTrackOffs&0FFh
	ld	(zloc_A9B+2),a	; store into the instruction after zloc_A9B (self-modifying code)
zloc_A9B:
	ld	ix,(zMusicTrackOffs) ; self-modified code from just above; 'ix' points to corresponding Music PSG track
	res	2,(ix+zTrack.PlaybackControl)						; tell this track it is is no longer overridden by SFX!
	set	1,(ix+zTrack.PlaybackControl)						; Set track to rest
	ld	a,(ix+zTrack.VoiceControl)						; Get voice control
	cp	0E0h							; Is this a PSG 3 noise (not tone) track?
	jr	nz,+							; If it isn't, don't do next part (non-PSG Noise doesn't restore)
	ld	a,(ix+zTrack.PSGNoise)						; Get PSG noise setting
	ld	(zPSG),a						; Write it to PSG
+
	pop	ix

zloc_AB6:
	ld	de,zTrack.len
	add	ix,de				; Got to next track
	pop	bc					; Restore 'bc'
	djnz	zloc_A46		; Loop around...
	ret
; End of function zStopSoundEffects

; ---------------------------------------------------------------------------
; zloc_ABF:
zFadeOutMusic:
	ld	a,3
	ld	(zAbsVar.FadeOutDelay),a			; Set delay ticker to 3
	ld	a,28h
	ld	(zAbsVar.FadeOutCounter),a			; Set total frames to decrease volume over
	xor	a
	ld	(zSongDAC.PlaybackControl),a		; Stop DAC track (can't fade it)
	ret

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


;zsub_AD1
zUpdateFadeout:
	ld	a,(zAbsVar.FadeOutDelay)				; Get current tick count before next volume decrease
	or	a
	jr	z,+							; If not yet zero...
	dec	(ix+zVar.FadeOutDelay)						; Just decrement it
	ret
+
	dec	(ix+zVar.FadeOutCounter)						; Otherwise, decrement fadeout!
	jp	z,zClearTrackPlaybackMem	; If it hits zero, clear everything!
	ld	(ix+zVar.FadeOutDelay),3					; Otherwise, reload tick count with 3
	push	ix
	ld	ix,zSongFM1	; 'ix' points to first FM music track
	ld	b,MUSIC_FM_TRACK_COUNT							; 6 FM tracks to follow...

zloc_AED:
	bit	7,(ix+zTrack.PlaybackControl)					; Is this track playing?
	jr	z,zloc_B04					; If not, do nothing
	inc	(ix+zTrack.Volume)						; increment channel volume (remember -- higher is quieter!)
	jp	p,+							; don't let it overflow
	res	7,(ix+zTrack.PlaybackControl)					; otherwise, stop playing this track
	jr	zloc_B04					; just loop
+
	push	bc
	call	zSetChanVol				; need to update volume
	pop	bc

zloc_B04:
	ld	de,zTrack.len
	add	ix,de						; Next track
	djnz	zloc_AED				; Keep going for all FM tracks...
	ld	b,MUSIC_PSG_TRACK_COUNT							; 3 PSG tracks to follow...

zloc_B0D:
	bit	7,(ix+zTrack.PlaybackControl)					; Is this track playing?
	jr	z,zloc_B2C					; If not, do nothing
	inc	(ix+zTrack.Volume)						; increment channel volume (remember -- higher is quieter!)
	ld	a,10h
	cp	(ix+zTrack.Volume)						; don't let volume go over 0Fh on PSG tracks!
	jp	nc,+
	res	7,(ix+zTrack.PlaybackControl)					; Otherwise, stop playing this track
	jr	zloc_B2C
+
	push	bc
	ld	b,(ix+zTrack.Volume)					; Channel volume -> 'b'

	; DANGER! This code ignores volume envelopes, breaking fade on envelope-using tracks.
	; (It's also a part of the envelope-processing code, so calling it here is redundant)
	; This is only useful for envelope 0 (no envelope).
	;call	zPSGUpdateVol			; Update volume (ignores current envelope!!!)

	; Clownacy: This new code only updates PSG if there isn't an envelope to do it instead
	ld	a,(ix+zTrack.VoiceIndex)
	or	a							; Is this track using volume envelope 0 (no envelope)?
	call	z,zPSGUpdateVol			; If so, update volume (this code is only run on envelope 1+, so we need to do it here for envelope 0)

	pop	bc

zloc_B2C:
	ld	de,zTrack.len
	add	ix,de						; Next track
	djnz	zloc_B0D				; Keep going for all PSG tracks...
	pop	ix
	ret
; End of function zUpdateFadeout


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


;zsub_B36
zFMSilenceAll:
	ld	a,28h			; Start at FM KEY ON/OFF register
	ld	b,3				; Three key on/off per part

-	ld	c,b				; Current key off -> 'c'
	dec	c				; c--
	rst	zWriteFMI		; Write key off for part I
	set	2,c				; Set part II select
	rst	zWriteFMI		; Write key off for part II
	djnz	-

	ld	a,30h			; Starting at FM register 30h...
	ld	c,0FFh			; Write dummy kill-all values
	ld	b,60h			; ... up to register 90h

-	rst	zWriteFMI		; ... on part I
	rst	zWriteFMII		; ... and part II
	inc	a				; Next register!
	djnz	-

	ret
; End of function zFMSilenceAll

; ---------------------------------------------------------------------------
; zloc_B4E:
zStopSoundAndMusic:
	xor	a
	ld	(zAbsVar.StopMusic),a

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


;zsub_B52
zClearTrackPlaybackMem:
	; This totally wipes out the track memory and resets playback hardware
	ld	a,27h						; Channel 3 special settings
	ld	c,0							; All clear
	rst	zWriteFMI					; Write it!
	; This performs a full clear across all track/playback memory
	ld	bc, (zAbsVar.SFXToPlay)
	push	bc						; save zSFXToPlay/zSFXStereoToPlay
	ld	a,(zAbsVar.SFXUnknown)
	push	af

	ld	hl,zAbsVar
	ld	de,zAbsVar+1
	ld	(hl),0						; Starting byte is 00h
	ld	bc,(zTracksSFXEnd-zAbsVar)-1						; For 695 bytes...
	ldir							; 695 bytes of clearing!  (Because it will keep copying the byte prior to the byte after; thus 00h repeatedly)
	pop	af
	ld	(zAbsVar.SFXUnknown),a
	pop	bc						; restore zSFXToPlay/zSFXStereoToPlay
	ld	(zAbsVar.SFXToPlay), bc

	xor	a
	ld	(zAbsVar.QueueToPlay),a			; Nothing is queued
	call	zFMSilenceAll			; Silence FM
	jp	zPSGSilenceAll				; Silence PSG
; End of function zClearTrackPlaybackMem


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


;zsub_B78
zInitMusicPlayback:
	; This function saves some of the queue/flag items and
	; otherwise resets all music-related playback memory and
	; silences the hardware.  Used prior to playing a new song.
	; Very similar to zClearTrackPlaybackMem except that it is
	; specific to the music tracks...

	; Save some queues/flags:
	ld	ix,zAbsVar
	ld	b,(ix+zVar.SFXPriorityVal)
	ld	c,(ix+zVar.1upPlaying)		; 1-up playing flag
	push	bc
	ld	b,(ix+zVar.SpeedUpFlag)		; speed shoe tempo
	ld	c,(ix+zVar.FadeInCounter)		; fade in frames
	push	bc
	ld	b,(ix+zVar.SFXToPlay)		; SFX queue slot
	ld	c,(ix+zVar.SFXStereoToPlay)		; Stereo SFX queue slot
	push	bc
	; The following clears all playback memory and non-SFX tracks
	ld	hl,zAbsVar
	ld	de,zAbsVar+1
	ld	(hl),0
	ld	bc,(zTracksEnd-zAbsVar)-1			; this many bytes (from start of zComRange to just short of end of PSG3 music track)
	ldir
	; Restore those queue/flags:
	pop	bc
	ld	(ix+zVar.SFXToPlay),b		; SFX queue slot
	ld	(ix+zVar.SFXStereoToPlay),c		; Stereo SFX queue slot
	pop	bc
	ld	(ix+zVar.SpeedUpFlag),b		; speed shoe tempo
	ld	(ix+zVar.FadeInCounter),c		; fade in frames
	pop	bc
	ld	(ix+zVar.SFXPriorityVal),b
	ld	(ix+zVar.1upPlaying),c		; 1-up playing flag
	xor	a
	ld	(zAbsVar.QueueToPlay),a
	; This silences all channels, even those being used by SFX!
	; zloc_8FB does the same thing, only better (it doesn't affect SFX channels)
	;call	zFMSilenceAll
	;jp	zPSGSilenceAll
	; If a music file's header doesn't define each and every channel, they
	; won't be silenced by zloc_8FB, because their tracks aren't properly
	; initialised. This can cause hanging notes. So, we'll set them up
	; properly here.
	ld	ix,zTracksStart			; Start at the first music track...
	ld	b,MUSIC_TRACK_COUNT	; ...and continue to the last
	ld	de,zTrack.len
	ld	hl,zFMDACInitBytes		; This continues into zPSGInitBytes

-	ld	a,(hl)
	inc	hl
	ld	(ix+zTrack.VoiceControl),a	; Set channel type while we're at it, so subroutines understand what the track is
	add	ix,de				; Next track
	djnz	-				; loop for all channels

	ret
; End of function zInitMusicPlayback

; ---------------------------------------------------------------------------
; zloc_BBE:
; increases the tempo of the music
zSpeedUpMusic:
	ld	a,(zAbsVar.1upPlaying)	; If 1up playing...
	or	a
	ld	a,8
	jr	nz,.1up_playing		; ...set variable in backup instead
	ld	(zAbsVar.SpeedUpFlag),a
	ret

.1up_playing:
	ld	(zSaveVar.SpeedUpFlag),a
	ret

; ===========================================================================
; zloc_BCB:
; returns the music tempo to normal
zSlowDownMusic:
	ld	a,(zAbsVar.1upPlaying)	; If 1up playing...
	or	a
	jr	nz,.1up_playing		; ...set variable in backup instead
	xor	a
	ld	(zAbsVar.SpeedUpFlag),a
	ret

.1up_playing:
	xor	a
	ld	(zSaveVar.SpeedUpFlag),a
	ret

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


;zsub_BE8
zUpdateFadeIn:
	ld	a,(zAbsVar.FadeInDelay)			; Get current tick count before next volume increase
	or	a
	jr	z,+							; If not yet zero...
	dec	(ix+zVar.FadeInDelay)					; Just decrement it
	ret
+
	ld	a,(zAbsVar.FadeInCounter)			; Get current fade out frame count
	or	a
	jr	nz,+						; If fadeout hasn't reached zero yet, skip this
	ld	a,(zSongDAC.PlaybackControl)			; Get DAC's playback control byte
	and	0FBh						; Clear "SFX is overriding" bit
	ld	(zSongDAC.PlaybackControl),a			; Set that
	xor	a
	ld	(zAbsVar.FadeInFlag),a			; Done fading-in, SFX can play now
	ret
+
	dec	(ix+zVar.FadeInCounter)					; Otherwise, we decrement fadein!
	ld	(ix+zVar.FadeInDelay),2					; Otherwise, reload tick count with 2 (little faster than fadeout)
	push	ix
	ld	ix,zSongFM1	; 'ix' points to first FM music track
	ld	b,MUSIC_FM_TRACK_COUNT								; 6 FM tracks to follow...

-	bit	7,(ix+zTrack.PlaybackControl)					; Is this track playing?
	jr	z,+							; If not, do nothing
	dec	(ix+zTrack.Volume)						; decrement channel volume (remember -- lower is louder!)
	push	bc
	call	zSetChanVol				; need to update volume
	pop	bc
+
	ld	de,zTrack.len
	add	ix,de						; Next track
	djnz	-						; Keep going for all FM tracks...

	ld	b,MUSIC_PSG_TRACK_COUNT							; 3 PSG tracks to follow...

-	bit	7,(ix+zTrack.PlaybackControl)					; Is this track playing?
	jr	z,+							; If not, do nothing
	dec	(ix+zTrack.Volume)						; decrement channel volume (remember -- lower is louder!)
	push	bc
	ld	b,(ix+zTrack.Volume)					; Channel volume -> 'b'

	; DANGER! This code ignores volume envelopes, breaking fade on envelope-using tracks.
	; (It's also a part of the envelope-processing code, so calling it here is redundant)
	; This is only useful for envelope 0 (no envelope).
	;call	zPSGUpdateVol			; Update volume (ignores current envelope!!!)

	; Clownacy: This new code only updates PSG if there isn't an envelope to do it instead
	ld	a,(ix+zTrack.VoiceIndex)
	or	a							; Is this track using volume envelope 0 (no envelope)?
	call	z,zPSGUpdateVol			; If so, update volume (this code is only run on envelope 1+, so we need to do it here for envelope 0)

	pop	bc
+
	ld	de,zTrack.len
	add	ix,de						; Next track
	djnz	-						; Keep going for all PSG tracks...

	pop	ix
	ret
; End of function zUpdateFadeIn


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


;zsub_C46
zFMNoteOn:
	ld	a,(ix+zTrack.PlaybackControl)		; Get playback control byte
	and	6
	ret	nz				; If either bit 1 ("track in rest") and 2 ("SFX overriding this track"), quit!
	; Big lump of code to handle FM6/DAC management
	ld	a,(ix+zTrack.VoiceControl)
	cp	6
	jr	nz,+			; Skip this if this isn't FM6
	ld	a,(zDACEnabled)
	or	a
	jr	z,+			; Branch if DAC is already disabled
	ld	a,(zHighPriorityDACPlaying)
	or	a
	ret	nz			; Return if high-priority DAC sample playing
	xor	a			; Disable DAC
	ld	(zDACEnabled),a
	ld	(zDACSFXPlaying),a
	ld	c,a
	ld	a,2Bh
	rst	zWriteFMI
	ld	a,0B6h			; Restore panning while we're at it (DAC could have changed it)
	ld	c,(ix+zTrack.AMSFMSPan)
	rst	zWriteFMII
+
	ld	a,(ix+zTrack.VoiceControl)		; Get "voice control" byte
	or	0F0h			; Turn on ALL operators
	ld	c,a				; Set as data to write to FM
	ld	a,28h			; Write to KEY ON/OFF port (key ON in this case)
	rst	zWriteFMI		; do it!
	ret
; End of function zFMNoteOn


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


;zsub_C56
zFMNoteOff:
	ld	a,(ix+zTrack.PlaybackControl)		; Load this track's playback control byte
	and	14h				; Are bits 4 (no attack) or 2 (SFX overriding) set?
	ret	nz				; If they are, return
	ld	a,28h			; Otherwise, send a KEY ON/OFF
	ld	c,(ix+zTrack.VoiceControl)		; Track's data for this key operation

	; Format of key on/off:
	; 4321 .ccc
	; Where 4321 are the bits for which operator,
	; and ccc is which channel (0-2 for channels 1-3, 4-6 for channels 4-6 WATCH BIT GAP)

	rst	zWriteFMI		; Write to part I (Note this particular register is ALWAYS sent to part I)
	ret
; End of function zFMNoteOff


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

zBankSwitchPart2:
	rept 7
		rra
		ld	(hl), a
	endm
	ld	(hl), l	; write a 0
	ret
; End of function zBankSwitchPart2

; ---------------------------------------------------------------------------

;zloc_C89
zCoordFlag:
	sub	0E0h
	add	a,a
    if 0
	add	a,coordflagLookup&0FFh
	ld	(.writeme+2),a
.writeme:
	ld	bc,(coordflagLookup)
    else
	ex	de, hl
	ld	hl, coordflagLookup
	add	a, l
	ld	l, a
	adc	a, h
	sub	a, l
	ld	h, a
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	ex	de, hl
    endif
	ld	(.writeme2+1),bc ; store into the instruction after coordflagLookup (self-modifying code)
	ld	a,(hl)
	inc	hl
.writeme2:
	jp	$
; This is the lookup for Coordination flag routines

	;ensure1byteoffset 34h
;zloc_C92
coordflagLookup:
; ---------------------------------------------------------------------------
	dw	cfPanningAMSFMS ; E0
; ---------------------------------------------------------------------------
	dw	cfDetune ; E1
; ---------------------------------------------------------------------------
	dw	cfSetCommunication ; E2
; ---------------------------------------------------------------------------
	dw	cfJumpReturn ; E3
; ---------------------------------------------------------------------------
	dw	cfFadeInToPrevious ; E4
; ---------------------------------------------------------------------------
	dw	cfSetTempoDivider ; E5
; ---------------------------------------------------------------------------
	dw	cfChangeFMVolume ; E6
; ---------------------------------------------------------------------------
	dw	cfPreventAttack ; E7
; ---------------------------------------------------------------------------
	dw	cfNoteFill ; E8
; ---------------------------------------------------------------------------
	dw	cfChangeTransposition ; E9
; ---------------------------------------------------------------------------
	dw	cfSetTempo ; EA
; ---------------------------------------------------------------------------
	dw	cfSetTempoMod ; EB
; ---------------------------------------------------------------------------
	dw	cfChangePSGVolume ; EC
; ---------------------------------------------------------------------------
	dw	cfClearPush ; ED
; ---------------------------------------------------------------------------
	dw	cfStopSpecialFM4 ; EE
; ---------------------------------------------------------------------------
	dw	cfSetVoice ; EF
; ---------------------------------------------------------------------------
	dw	cfModulation ; F0
; ---------------------------------------------------------------------------
	dw	cfEnableModulation ; F1
; ---------------------------------------------------------------------------
	dw	cfStopTrack ; F2
; ---------------------------------------------------------------------------
	dw	cfSetPSGNoise ; F3
; ---------------------------------------------------------------------------
	dw	cfDisableModulation ; F4
; ---------------------------------------------------------------------------
	dw	cfSetPSGTone ; F5
; ---------------------------------------------------------------------------
	dw	cfJumpTo ; F6
; ---------------------------------------------------------------------------
	dw	cfRepeatAtPos ; F7
; ---------------------------------------------------------------------------
	dw	cfJumpToGosub ; F8
; ---------------------------------------------------------------------------
	dw	cfOpF9 ; F9
; ---------------------------------------------------------------------------
	dw	cfNoteFillS3K ; FA, new
; ---------------------------------------------------------------------------

; (via Saxman's doc): panning, AMS, FMS
;zloc_CFC
cfPanningAMSFMS:
	;Panning, AMS, FMS
    ;* xx - Value (reg a)
    ;      o Bit 7 - Left channel status
    ;      o Bit 6 - Right channel Status
    ;      o Bit 5-3 - AMS
    ;      o Bit 2 - 0
    ;      o Bit 1-0 - FMS

	; Subject to verification, but even though you COULD set
	; AMS/FMS values, it does not appear that's what they intended
	; here; instead it appears they only meant for panning control.
	; I say this because it retains prior AMS/FMS settings ("and 37h")

	bit	7,(ix+zTrack.VoiceControl)		; a PSG track
	ret	m				; If so, quit!
	; This check is in the wrong place.
	; If this flag is triggered by a music track while it's being overridden
	; by an SFX, it will use the old panning when the SFX ends.
	; This is because zTrack.AMSFMSPan doesn't get updated.
	;bit	2,(ix+zTrack.PlaybackControl)		; If "SFX overriding" bit set...
	;ret	nz				; return
	ld	c,a				; input val 'a' -> c
	ld	a,(ix+zTrack.AMSFMSPan)		; old PAF value
	and	37h				; retains bits 0-2, 3-4?
	or	c				; OR'd with new settings
	ld	(ix+zTrack.AMSFMSPan),a		; new PAF value

	; The check should only stop hardware access, like this.
	bit	2,(ix+zTrack.PlaybackControl)		; If "SFX overriding" bit set...
	ret	nz				; return

	ld	c,a				; a -> c (YM2612 data write)

	; Don't change hardware if being overwritten by DAC SFX
	ld	a,(ix+zTrack.VoiceControl)
	cp	6
	jr	nz,+
	ld	a,(zDACSFXPlaying)
	or	a
	ret	nz
+
	ld	a,(ix+zTrack.VoiceControl)		; Get voice control byte
	and	3				; Channels only!
	add	a,0B4h			; Add register B4, stereo output control and LFO sensitivity
	rst	zWriteFMIorII	; depends on bit 2 of (ix+zTrack.VoiceControl)
	ret

; ---------------------------------------------------------------------------

; (via Saxman's doc): Alter note values by xx
; More or less a pitch bend; this is applied to the frequency as a signed value
;zloc_D1A cfAlterNotesUNK cfAlterNotes:
cfDetune:
	ld	(ix+zTrack.Detune),a		; set new detune value
	ret
; ---------------------------------------------------------------------------

; Set otherwise unused communication byte to parameter
; Used for triggering a boss' attacks in Ristar
;zloc_D1E cfUnknown1
cfSetCommunication:
	ld	(zAbsVar.Communication),a
	ret
; ---------------------------------------------------------------------------

; Return (Sonic 1 & 2)
;zloc_D22
cfJumpReturn:
	ld	c,(ix+zTrack.StackPointer)		; Get current stack offset -> 'c'
	ld	b,0				; b = 0
	push	ix
	pop	hl				; hl = ix
	add	hl,bc			; hl += bc (latest item on "gosub" stack)
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a				; hl = address from "gosub" stack
	inc	c
	inc	c
	ld	(ix+zTrack.StackPointer),c		; add 2 to "gosub" stack offset (pop)
	ret
; ---------------------------------------------------------------------------

; Fade-in to previous song (needed on DAC channel, Sonic 1 & 2)
;zloc_D35
cfFadeInToPrevious:
	; This performs a "massive" restoration of all of the current
	; track positions as they were prior to 1-up BGM
	; Restore music
	ld	hl,zTracksSaveStart	; Backup memory address
	ld	de,zTracksStart
	ld	bc,zTracksSaveEnd-zTracksSaveStart		; for this many bytes
	ldir					; Go!
	; Restore variables
	ld	de,zAbsVar
	ld	bc,zVar.len		; for this many bytes
	ldir					; Go!

	; Here, we decompress the original song again, if needed
	rst	zBankSwitchToMusic

cfFadeInToPrevious_FlagLoadInstruction:
	ld	a,0FFh
	bit	5,a		; Check the 'music is uncompressed' flag (remember, 'a' was shifted before it was stored)
	jr	nz,+		; If it's set, there's nothing to decompress

cfFadeInToPrevious_AddressLoadInstruction:
	ld	hl,0

	call	zSaxmanDec
+

	ld	a,(zSongDAC.PlaybackControl)	; Get DAC's playback bit
	or	4
	ld	(zSongDAC.PlaybackControl),a	; Set "SFX is overriding" on it (not normal, but will work for this purpose)
	ld	a,(zAbsVar.FadeInCounter)	; Get current count of many frames to continue bringing volume up
	ld	c,a					;
	ld	a,28h				;
	sub	c					; a = 28h - c (don't overlap fade-ins?)
	ld	c,a					; 'a' -> 'c'
	ld	b,MUSIC_FM_TRACK_COUNT							; 6 FM tracks to follow...
	ld	ix,zSongFM1	; 'ix' points to first FM music track

-	bit	7,(ix+zTrack.PlaybackControl)			; Is this track playing?
	jr	z,+					; If not, do nothing
	set	1,(ix+zTrack.PlaybackControl)			; Mark track at rest
	ld	a,(ix+zTrack.Volume)			; Get channel volume
	add	a,c					; Apply current fade value
	ld	(ix+zTrack.Volume),a			; Store it back
	push	bc
	call	zSetVoiceMusic	; Update voice (and set volume)
	pop	bc
+
	ld	de,zTrack.len
	add	ix,de				; Next track
	djnz	-				; Keep going for all FM tracks...

	ld	b,MUSIC_PSG_TRACK_COUNT				; 3 PSG tracks to follow...

-	bit	7,(ix+zTrack.PlaybackControl)			; Is this track playing?
	jr	z,+					; If not, do nothing
	set	1,(ix+zTrack.PlaybackControl)			; Set track at rest
	call	zPSGNoteOff		; Shut off PSG
	ld	a,(ix+zTrack.Volume)			; Get channel volume
	add	a,c					; Apply current fade value
	ld	(ix+zTrack.Volume),a			; Store it back
	; Restore PSG noise type
	ld	a,(ix+zTrack.VoiceControl)
	cp	0E0h						; Is this the Noise Channel?
	jr	nz,+						; If not, branch
	ld	a,(ix+zTrack.PSGNoise)
	ld	(zPSG),a					; Restore Noise setting
+
	ld	de,zTrack.len
	add	ix,de				; Next track
	djnz	-				; Keep going for all FM tracks...

	; SFX will be re-enabled, but we don't want the backed-up music data being treated as SFX data
	ld	b,SFX_TRACK_COUNT

-	res	7,(ix+zTrack.PlaybackControl)
	add	ix,de
	djnz	-

	ld	a,80h
	ld	(zAbsVar.FadeInFlag),a	; Stop any SFX during fade-in
	ld	a,28h
	ld	(zAbsVar.FadeInCounter),a	; Fade in for 28h frames
	xor	a
	ld	(zAbsVar.1upPlaying),a	; Set to zero; 1-up ain't playin' no more
	pop	bc
	pop	bc
	pop	bc					; These screw with the return address to make sure DAC doesn't run any further
	jp	zUpdateDAC			; But we update DAC regardless
; ---------------------------------------------------------------------------

; Change tempo divider to xx
;zloc_DB7
cfSetTempoDivider:
	ld	(ix+zTrack.TempoDivider),a		; Set tempo divider on this track only
	ret
; ---------------------------------------------------------------------------

; (via Saxman's doc): Change channel volume BY xx; xx is signed
;zloc_DBB cfSetVolume
cfChangeFMVolume:
	add	a,(ix+zTrack.Volume)		; Add to current volume
	ld	(ix+zTrack.Volume),a		; Update volume
	jp	zSetChanVol		; Immediately set this new volume
; ---------------------------------------------------------------------------

; (via Saxman's doc): prevent next note from attacking
;zloc_DC4
cfPreventAttack:
	set	4,(ix+zTrack.PlaybackControl)		; Set bit 4 (10h) on playback control; do not attack next note
	dec	hl				; Takes no argument, so just put it back
	ret
; ---------------------------------------------------------------------------
; Sets the note fill.
;
; Has one parameter byte, the new note fill. This value is multiplied by the
; tempo divider, and so may overflow.

cfNoteFillS3K:
	call	zComputeNoteDuration	; fall through to cfNoteFill
; ---------------------------------------------------------------------------

; (via Saxman's doc): set note fill amount to xx
;zloc_DCA
cfNoteFill:
	ld	(ix+zTrack.NoteFillTimeout),a		; Note fill value (modifiable)
	ld	(ix+zTrack.NoteFillMaster),a		; Note fill value (master copy, rewrites +0Fh when necessary)
	ret
; ---------------------------------------------------------------------------

; (via Saxman's doc): add xx to channel key
;zloc_DD1 cfAddKey:
cfChangeTransposition:
	add	a,(ix+zTrack.Transpose)	; Add to current transpose value
	ld	(ix+zTrack.Transpose),a	; Store updated transpose value
	ret
; ---------------------------------------------------------------------------

; (via Saxman's doc): set music tempo to xx
;zloc_DD8
cfSetTempo:
	ld	(zAbsVar.CurrentTempo),a		; Set tempo
	ret
; ---------------------------------------------------------------------------

; (via Saxman's doc): Change Tempo Modifier to xx for ALL channels
;zloc_DDC
cfSetTempoMod:
	push	ix			; Save 'ix'
	ld	ix,zTracksStart	; Start at beginning of track memory
	ld	de,zTrack.len		; Track size
	ld	b,MUSIC_TRACK_COUNT			; All 10 tracks

-	ld	(ix+zTrack.TempoDivider),a		; Sets the timing divisor for ALL tracks; this can result in total half-speed, quarter-speed, etc.
	add	ix,de
	djnz	-

	pop	ix				; Restore 'ix'
	ret
; ---------------------------------------------------------------------------
; This controls which TL registers are set for a particular
; algorithm; it actually makes more sense to look at a zVolTLMaskTbl entry as a bitfield.
; Bit 0-4 set which TL operators are actually effected for setting a volume;
; this table helps implement the following from the Sega Tech reference:
; "To make a note softer, only change the TL of the slots (the output operators).
; Changing the other operators will affect the flavor of the note."
; zloc_DF1:
zVolTLMaskTbl:
	db	  8,  8,  8,  8
	db	0Ch,0Eh,0Eh,0Fh
; ---------------------------------------------------------------------------

; (via Saxman's doc): Change channel volume TO xx; xx is signed (Incorrect, see below)
; However, I've noticed this is incorrect; first of all, you'll notice
; it's still doing an addition, not a forced set.  Furthermore, it's
; not actually altering the FM yet; basically, until the next voice
; switch, this volume change will not come into effect.  Maybe a better
; description of it is "change volume by xx when voice changes", which
; makes sense given some voices are quieter/louder than others, and a
; volume change at voice may be necessary... or my guess anyway.

; Alternatively, just think of it as a volume setting optimized for PSG :P
;zloc_DF9 cfChangeVolume
cfChangePSGVolume:
	add	a,(ix+zTrack.Volume)	; Add to channel volume
	ld	(ix+zTrack.Volume),a	; Store updated volume
	ret
; ---------------------------------------------------------------------------

; Ported from S1 EDh
;zlocret_E00 cfUnused cfUnused1
cfClearPush:
	dec	hl		; Put back byte
	xor	a		; Clear a
	ld	(zPushFlag),a	; Clear pushing sound flag
	ret
; ---------------------------------------------------------------------------

; Unused command EEh
; This used to be Sonic 1's cfStopSpecialFM4. But the Special SFX function hasn't been ported...
;zloc_E01 cfVoiceUNK cfUnused2
cfStopSpecialFM4:
	dec	hl		; Put back byte; does nothing
	ret
; ---------------------------------------------------------------------------

; (via Saxman's doc): set voice selection to xx
;zloc_E03
cfSetVoice:
	ld	(ix+zTrack.VoiceIndex),a			; Set current voice
	bit	2,(ix+zTrack.PlaybackControl)			; If "SFX is overriding this track" bit set...
	ret	nz					; .. return!
	push	hl				; Save 'hl'
	call	zSetVoiceMusic	; Set the new voice!
	pop	hl					; Restore 'hl'
	ret

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


zGetCurrentVoice:
	ld	l,(ix+zTrack.VoicePtrLow)
	ld	h,(ix+zTrack.VoicePtrHigh)
	ld	a,(ix+zTrack.VoiceIndex)
	or	a
	ret	z
	ld	b,a

	ld	de,25

-	add	hl,de
	djnz	-
	ret

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


;zsub_E21
zSetVoiceMusic:
	call	zGetCurrentVoice

	; Sets up a value for future Total Level setting...
	ld	a,(hl)				; Get feedback/algorithm -> a
	inc	hl					; next byte of voice...
	ld	(zloc_E65+1),a		; self-modifying code; basically enables 'a' restored to its current value later

	ld	c,a					; a -> c (will be data to YM2612)

	; Don't change pan if being overwritten by DAC SFX
	ld	a,(ix+zTrack.VoiceControl)
	cp	6
	jr	nz,+
	ld	a,(zDACSFXPlaying)
	or	a
	jr	nz,++
+
	ld	a,(ix+zTrack.VoiceControl)			; Get "voice control" byte
	and	3					; only keep bits 0-2 (bit 2 specifies which chip to write to)
	add	a,0B0h				; add to get appropriate feedback/algorithm register
	rst	zWriteFMIorII		; Write new value to appropriate part
+
	; detune/coarse freq, all channels
	sub	80h					; Subtract 80h from 'a' (Detune/coarse frequency of operator 1 register)
	ld	b,4					; Do next 4 bytes (operator 1, 2, 3, and 4)

-	ld	c,(hl)				; Get next detune/coarse freq
	inc	hl					; next voice byte
	rst	zWriteFMIorII		; Write this detune/coarse freq
	add	a,4					; Next detune/coarse freq register
	djnz	-

	push	af				; saving 'a' for much later... will be restored when time to "Total Level"

	; other regs up to just before "Total Level", all channels
	add	a,10h				; we're at 40h+, now at 50h+ (RS/AR of operator 1 register)
	ld	b,10h				; Perform 16 writes (basically goes through RS/AR, AM/D1R, D2R, D1L)

-	ld	c,(hl)				; Get next reg data value
	inc	hl					; next voice byte
	rst	zWriteFMIorII		; Write to FM
	add	a,4					; Next register
	djnz	-

	; Now going to set "stereo output control and LFO sensitivity"
	add	a,24h				; Sets to reg B4h+ (stereo output control and LFO sensitivity)
	ld	c,(ix+zTrack.AMSFMSPan)			; Panning / AMS / FMS settings from track
	rst	zWriteFMIorII		; Write it!

zloc_E65:
	ld	a,0 ; "self-modified code" -- 'a' will actually be set to the feedback/algorithm byte
	and	7					; Only keeping the "algorithm" part of it
	add	a,zVolTLMaskTbl&0FFh		; Adds offset to zVolTLMaskTbl table (low byte only)
	ld	e,a					; Puts this low byte into 'e'
	adc	a,(zVolTLMaskTbl&0FF00h)>>8
	sub	e
	ld	d,a	; Get high byte -> 'd'
	ld	a,(de)				; Get this zVolTLMaskTbl value by algorithm
	ld	(ix+zTrack.VolTLMask),a			; Store this zVolTLMaskTbl value into (ix+1Ah)
	ld	e,a					; Store zVolTLMaskTbl value -> 'e'
	ld	d,(ix+zTrack.Volume)			; Store channel volume -> 'd'
	pop	af					; Restore 'a'; it's now back at appropriate 40h+ register for Total Level setting!

	; Set "Total Levels" (general volume control)
zSetFMTLs:
	ld	b,4					; Loop 4 times (for each Total Level register on this channel)

-	ld	c,(hl)				; Get next TL byte -> c
	inc	hl					; Next voice byte...
	rr	e					; zVolTLMaskTbl value is rotated right; if the bit 0 of this value prior to the rotate was reset (0)...
	jr	nc,+				; ... then we make the jump here (just write the TL value directly, don't modify it)

	; Otherwise, apply channel volume to TL here
	; It's not appropriate to alter ALL TL values, only
	; the ones which are "slots" (output operators)
	push	af				; Save 'a'
	ld	a,d					; Channel volume -> d
	add	a,c					; Add it to the TL value
	ld	c,a					; Modified value -> c
	pop	af					; Restore 'a'
+
	rst	zWriteFMIorII		; Write TL value
	add	a,4					; Next TL reg...
	djnz	-

	ret
; End of function zSetVoiceMusic


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


;zsub_E8A
zSetChanVol:
	bit	7,(ix+zTrack.VoiceControl)		; a PSG track
	ret	nz				; If so, quit!
	bit	2,(ix+zTrack.PlaybackControl)		; If playback control byte "SFX is overriding this track" bit set...
	ret	nz				; ... then quit!

	push	hl			; Save 'hl'

	; Get TL address
	call	zGetCurrentVoice
	ld	de,21		; Get TL data
	add	hl,de

	ld	e,(ix+zTrack.VolTLMask)		; zVolTLMaskTbl value from last voice setting (marks which specific TL operators need updating)
	ld	a,(ix+zTrack.VoiceControl)		; Load current voice control byte
	and	3				; Keep only bits 0-2
	add	a,40h			; Add 40h -- appropriate TL register
	ld	d,(ix+zTrack.Volume)		; Get channel volume
	bit	7,d
	call	z,zSetFMTLs	; Set the appropriate Total Levels
	pop	hl				; Restore 'hl'
	ret
; End of function zSetChanVol

; ---------------------------------------------------------------------------

; (via Saxman's doc): F0wwxxyyzz - modulation
;							o	ww - Wait for ww period of time before modulation starts
;							o	xx - Modulation Speed
;							o	yy - Modulation change per Mod. Step
;							o	zz - Number of steps in modulation
;zloc_EB0
cfModulation:
	set	3,(ix+zTrack.PlaybackControl)		; Set bit 3 (08h) of "playback control" byte (modulation on)
	dec	hl				; Move 'hl' back one...
	ld	(ix+zTrack.ModulationPtrLow),l		; Back up modulation setting address into (ix+11h), (ix+12h)
	ld	(ix+zTrack.ModulationPtrHigh),h

;zloc_EBB
zSetModulation:
	; Sets up modulation for this track; expects 'hl' to point to modulation
	; configuration info...

	; Heh, using some undoc instructions here...
	ld	a,ixl			; Get lower byte of current track address (ew :P)
	add	a,zTrack.ModulationWait			; ... and add 19 bytes to it
	ld	e,a				; put that into 'e'
	adc	a,ixu			; If carry occurred, add that to upper part of address
	sub	e				; subtract 'e'
	ld	d,a				; Basically, 'd' is now the appropriate upper byte of the address, completing de = (ix + 19)
						; Copying next three bytes
	ld	bc,3
	ldir						; while (bc-- > 0) *de++ = *hl++; (wait, modulation speed, modulation change)
	ld	a,(hl)			; Get Number of steps in modulation
	inc	hl				; Next byte...
	srl	a				; divide number of steps by 2
	ld	(ix+zTrack.ModulationSteps),a		; Store this step count into trackPtr+16h
	bit	4,(ix+zTrack.PlaybackControl)		; Is bit 4 "do not attack next note" (10h) set?
	ret	nz				; If so, quit!
	xor	a				; Clear 'a'
	ld	(ix+zTrack.ModulationValLow),a		; Clear modulation value low byte
	ld	(ix+zTrack.ModulationValHigh),a		; Clear modulation value high byte
	ret
; ---------------------------------------------------------------------------

; (via Saxman's doc): Turn on modulation
;zloc_EDE
cfEnableModulation:
	dec	hl
	set	3,(ix+zTrack.PlaybackControl)		; Playback byte bit 3 (08h) -- modulation on
	ret
; ---------------------------------------------------------------------------

; (via Saxman's doc): stop the track
;zloc_EE4
cfStopTrack:
	res	7,(ix+zTrack.PlaybackControl)			; Clear playback byte bit 7 (80h) -- currently playing (not anymore)
	res	4,(ix+zTrack.PlaybackControl)			; Clear playback byte bit 4 (10h) -- do not attack
	bit	7,(ix+zTrack.VoiceControl)			; Is voice control bit 7 (80h) a PSG track set?
	jr	nz,zStopPSGTrack	; If so, skip this next part...
	ld	a,(zAbsVar.DACUpdating)	; Is DAC updating?  (FF if so)
	or	a					; test it
	jp	m,zDACStopTrack		; If DAC is updating, go here (we're in a DAC track)
	call	zFMNoteOff		; Otherwise, stop this FM track
	jr	+

;zcall_zsub_526
zStopPSGTrack:
	call	zPSGNoteOff
+
	; General stop track continues here...

	ld	a,(zDoSFXFlag)		; Check if we're an SFX track
	or	a					; test it
	jp	p,zStopMusicTrack	; If not, jump to zStopMusicTrack
	xor	a					; a = 0
	ld	(zAbsVar.SFXPriorityVal),a		; Reset SFX priority
	ld	a,(ix+zTrack.VoiceControl)			; Load "voice control" byte
	or	a					; test it..
	jp	m,zStopPSGSFXTrack	; If this is PSG SFX track, jump to zStopPSGSFXTrack
	push	ix				; save 'ix'
	; This is an FM SFX track that's trying to stop
	sub	2					; Take channel assignment - 2 (since SFX never use FM 1 or FM 2)
	add	a,a					; a *= 2 (each table entry is 2 bytes wide)
	add	a,zMusicTrackOffs&0FFh	; Get low byte value from zMusicTrackOffs
	ld	(zloc_F1D+2),a			; store into the instruction after zloc_F1D (self-modifying code)
zloc_F1D:
	ld	ix,(zMusicTrackOffs)	; self-modified code from just above; 'ix' points to corresponding Music FM track
	bit	2,(ix+zTrack.PlaybackControl)				; If "SFX is overriding this track" is not set...
	jp	z,+						; Skip this part (i.e. if SFX was not overriding this track, then nothing to restore)
	rst	zBankSwitchToMusic	; Bank switch back to music track
	res	2,(ix+zTrack.PlaybackControl)				; Clear SFX is overriding this track from playback control
	set	1,(ix+zTrack.PlaybackControl)				; Set track as resting bit
	call	zSetVoiceMusic		; And set it!  (takes care of volume too)

	rst	zBankSwitchToSFX
+
	pop	ix						; restore 'ix'
	pop	bc						; removing return address from stack; will not return to coord flag loop
	pop	bc						; removing return address from stack; will not return to z*UpdateTrack function
	ret
; ---------------------------------------------------------------------------

zStopPSGSFXTrack:
	push	ix					; save 'ix'

	; Keep in mind that we just entered with a PSG "voice control" byte
	; which is one of the following values (PSG1-3/3N) -- 80h, A0h, C0h, E0h
	rra
	rra
	rra
	rra			; in effect, ">> 4"
	and	0Fh		; 'a' is now 08, 0A, 0C, or 0E
	add	a,zMusicTrackOffs&0FFh
	ld	(zloc_F5A+2),a	; store into the instruction after zloc_A5A (self-modifying code)
zloc_F5A:
	ld	ix,(zMusicTrackOffs) ; self-modified code from just above; 'ix' points to corresponding Music PSG track
	res	2,(ix+zTrack.PlaybackControl)	; Clear SFX is overriding this track from playback control
	set	1,(ix+zTrack.PlaybackControl)	; Set track as resting bit
	ld	a,(ix+zTrack.VoiceControl)	; Get voice control byte
	cp	0E0h		; Is this a PSG 3 noise (not tone) track?
	jr	nz,+		; If it isn't, don't do next part (non-PSG Noise doesn't restore)
	ld	a,(ix+zTrack.PSGNoise)	; Get PSG noise setting
	ld	(zPSG),a	; Write it to PSG
+
	pop	ix						; restore 'ix'

;zloc_F75
zStopMusicTrack:
	pop	bc						; removing return address from stack; will not return to coord flag loop

;zloc_F76
zDACStopTrack:
	pop	bc						; removing return address from stack; will not return to z*UpdateTrack function (anything othat than DAC) or not to coord flag loop (if DAC)
	ret
; ---------------------------------------------------------------------------

; (via Saxman's doc): Change current PSG noise to xx (For noise channel, E0-E7)
;zloc_F78
cfSetPSGNoise:
	ld	(ix+zTrack.VoiceControl),0E0h		; This is a PSG noise track now!
	ld	(ix+zTrack.PSGNoise),a		; Save PSG noise setting for restoration if SFX overrides it
	bit	2,(ix+zTrack.PlaybackControl)		; If SFX is currently overriding it, don't actually set it!
	ret	nz
	ld	(zPSG),a		; Otherwise, please do
	ret
; ---------------------------------------------------------------------------

; (via Saxman's doc): Turn off modulation
;zloc_F88
cfDisableModulation:
	dec	hl				; No parameters used, must back up a byte
	res	3,(ix+zTrack.PlaybackControl)		; Clear "modulation on" bit setting
	ret
; ---------------------------------------------------------------------------

; (via Saxman's doc): Change current PSG tone to xx
;zloc_F8E
cfSetPSGTone:
	ld	(ix+zTrack.VoiceIndex),a		; Set current PSG tone
	ret
; ---------------------------------------------------------------------------

; (via Saxman's doc): jump to position yyyy
;zloc_F92
cfJumpTo:
	ld	d,(hl)			; Get hight byte of jump destination (since pointer advanced to it)
	ld	e,a				; Put low byte (already retrieved)
	add	hl,de
	ret
; ---------------------------------------------------------------------------

; (via Saxman's doc): $F7xxyyzzzz - repeat section of music
;    * xx - loop index, for loops within loops without confusing the engine.
;          o EXAMPLE: Some notes, then a section that is looped twice, then some more notes, and finally the whole thing is looped three times.
;            The "inner" loop (the section that is looped twice) would have an xx of 01, looking something along the lines of F70102zzzz, whereas the "outside" loop (the whole thing loop) would have an xx of 00, looking something like F70003zzzz.
;    * yy - number of times to repeat
;          o NOTE: This includes the initial encounter of the F7 flag, not number of times to repeat AFTER hitting the flag.
;    * zzzz - position to loop back to
;zloc_F95
cfRepeatAtPos:
					; Loop index is in 'a'
	ld	c,(hl)		; Get next byte (number of repeats) -> 'c'
	inc	hl			; Next byte...
	push	hl		; Save 'hl'
	add	a,zTrack.LoopCounters		; Add to make loop index offset (starts at 20h in track memory)
	ld	l,a			; Set hl = offset index
	ld	h,0
	ld	e,ixl		; Set 'de' to beginning of track
	ld	d,ixu
	add	hl,de		; hl is now pointing to track memory offset for this loop
	ld	a,(hl)		; Get loop count at this address
	or	a			; Test it
	jr	nz,+		; If not zero, then skip next step (i.e. we're currently looping)
	ld	(hl),c		; Otherwise, set it to the new number of repeats
+
	dec	(hl)		; One less loop
	pop	hl			; Restore 'hl' (now at the position)
	jr	z,+			; If counted to zero, skip the rest of this (hence start loop count of 1 terminates the loop without ever looping)
	ld	a,(hl)		; Get low byte of jump address
	inc	hl			; Next byte
	ld	d,(hl)		; Get high byte of jump address -> 'd'
	ld	e,a			; Put low byte of jump address -> 'e'
	add	hl,de

	; Note then that this loop command only works AFTER the section you mean to loop

	ret
+
	; If you get here, the loop terminated; just bypass the loop jump address
	inc	hl
	inc	hl
	ret
; ---------------------------------------------------------------------------

; (via Saxman's doc): jump to position yyyy (keep previous position in memory for returning)
;zloc_FB3
cfJumpToGosub:
	ld	c,a			; a -> c
	ld	a,(ix+zTrack.StackPointer)	; Get current "stack" offset (starts at 2Ah, i.e. beginning of next track)
	sub	2			; Move back by two (we need to store a new return address)
	ld	(ix+zTrack.StackPointer),a	; Set current stack offset
	ld	b,(hl)		; Get high byte of jump position -> 'b'
	inc	hl			; Next byte...
	ex	de,hl		; hl <=> de
	add	a,ixl		; Add low byte of current track pointer to stack offset (low byte of stack location)
	ld	l,a			; Keep this in 'l'
	adc	a,ixu		; Update high byte, if necessary
	sub	l			; Fixup
	ld	h,a			; a -> 'h' (Simply, we just did hl = ix + stack_offset)
	ld	(hl),e		; Store current address low byte (just after jump) into stack
	inc	hl			; Next byte
	ld	(hl),d		; Store current address high byte (just after jump) into stack
	ld	h,b
	ld	l,c			; hl = bc (current location is where you wanted to jump to)
	add	hl,de
	ret
; ---------------------------------------------------------------------------

; Leftover from Sonic 1: was used in SYZ's music.
;zloc_FCC
cfOpF9:
	ld	a,88h		; D1L/RR of Operator 3
	ld	c,0Fh		; Loaded with fixed value (max RR, 1TL?)
	rst	zWriteFMI	; Written to part I
	ld	a,8Ch		; D1L/RR of Operator 4
	ld	c,0Fh		; Loaded with fixed value (max RR, 1TL?)
	rst	zWriteFMI	; Written to part I
	dec	hl			; Doesn't take an arg, so put back one byte
	ret

; ---------------------------------------------------------------------------
; This the note -> frequency setting lookup
; the same array is found at $729CE in Sonic 1, and at $C9C44 in Ristar
; zword_359:
zPSGFrequencies:
		; This table starts with 12 notes not in S1 or S2:
	dw	3FFh, 3FFh, 3FFh, 3FFh, 3FFh, 3FFh, 3FFh, 3FFh, 3FFh, 3F7h, 3BEh, 388h
	dw	356h, 326h, 2F9h, 2CEh, 2A5h, 280h, 25Ch, 23Ah, 21Ah, 1FBh, 1DFh, 1C4h
	dw	1ABh, 193h, 17Dh, 167h, 153h, 140h, 12Eh, 11Dh, 10Dh, 0FEh, 0EFh, 0E2h
	dw	0D6h, 0C9h, 0BEh, 0B4h, 0A9h, 0A0h,  97h,  8Fh,  87h,  7Fh,  78h,  71h
	dw	 6Bh,  65h,  5Fh,  5Ah,  55h,  50h,  4Bh,  47h,  43h,  40h,  3Ch,  39h
	dw	 36h,  33h,  30h,  2Dh,  2Bh,  28h,  26h,  24h,  22h,  20h,  1Fh,  1Dh
	dw	 1Bh,  1Ah,  18h,  17h,  16h,  15h,  13h,  12h,  11h,    0,    0,    0
; lookup table of FM note frequencies for instruments and sound effects
; zbyte_534:
zFrequencies:
	dw 025Eh,0284h,02ABh,02D3h,02FEh,032Dh,035Ch,038Fh,03C5h,03FFh,043Ch,047Ch
; ---------------------------------------------------------------------------
;zbyte_FD8h
;zSFXPriority:
; zSFXPriority is now a part of SoundIndex

; zoff_1029:
;zPSG_Index
zPSG_FlutterTbl:
	; Basically, for any tone 0-11, dynamic volume adjustments are applied to produce a pseudo-decay,
	; or sometimes a ramp up for "soft" sounds, or really any other volume effect you might want!

	; Remember on PSG that the higher the value, the quieter it gets (it's attenuation, not volume);
	; 0 is thus loudest, and increasing values decay, until level $F (silent)

	dw	byte_1043, byte_105A, byte_1061, byte_1072
	dw	byte_108C, byte_107D, byte_10B6, byte_10D2
	dw	byte_10FA, byte_110B, byte_1149, byte_1165
	dw	byte_11E5
byte_1043:
	db	0,0,0,1,1,1,2,2,2,3,3,3,4,4,4,5
	db	5,5,6,6,6,7,80h
byte_105A:
	db	0,2,4,6,8,10h,80h
byte_1061:
	db	0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,80h
byte_1072:
	db	0,0,2,3,4,4,5,5,5,6,80h
byte_107D:
	db	3,3,3,2,2,2,2,1,1,1,0,80h
byte_108C:
	db	0,0,0,0,0,0,0,0,0,0,1,1
	db	1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2
	db	2,2,2,2,3,3,3,3,3,3,3,3,4,80h
byte_10B6:
	db	0,0,0,0,0,0,1,1,1,1,1,2,2,2,2,2
	db	3,3,3,4,4,4,5,5,5,6,7,80h
byte_10D2:
	db	0,0,0,0,0,1,1,1,1,1,2,2,2,2,2,2
	db	3,3,3,3,3,4,4,4,4,4,5,5,5,5,5,6
	db	6,6,6,6,7,80h
byte_10FA:
	db	0,1,2,3,4,5,6,7,8,9,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh,80h
byte_110B:
	db	0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1
	db	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	db	1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2
	db	2,2,3,3,3,3,3,3,3,3,3,3,4,80h
byte_1149:
	db	4,4,4,3,3,3,2,2,2,1,1,1,1,1,1,1
	db	2,2,2,2,2,3,3,3,3,3,4,80h
byte_1165:
	db	4,4,3,3,2,2,1,1,1,1,1,1,1,1,1,1
	db	1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2
	db	2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,3
	db	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
	db	3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4
	db	4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5
	db	5,5,5,5,5,5,5,5,5,5,6,6,6,6,6,6
	db	6,6,6,6,6,6,6,6,6,6,6,6,6,6,7,80h
byte_11E5:
	db	0Eh,0Dh,0Ch,0Bh,0Ah,9,8,7,6,5,4,3,2,1,0,80h

;	END of zPSG_FlutterTbl ---------------------------

	;align	100h	; TODO: without this, ensure1byteoffset below throws a warning (?) that prevents the ROM from building??

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

;zsub_1271
zSaxmanDec:
	exx
	xor	a
	ld	b,a
	ld	c,a
	ld	d,a
	ld	e,a
	exx
	ld	de,zMusicData
	ld	c,(hl)
	inc	hl
	ld	b,(hl)					; bc = (hl) i.e. "size of song"
	inc	hl
	ld	(zGetNextByte+1),hl		; modify inst. @ zGetNextByte -- set to beginning of decompression stream
	inc	bc
	ld	(zDecEndOrGetByte+1),bc ; modify inst. @ zDecEndOrGetByte -- set to length of song, +1

;zloc_1288
zSaxmanReadLoop:

	exx							; shadow reg set
	srl	b						; b >> 1 (just a mask that lets us know when we need to reload)
	jr	c,+					; if it's set, we still have bits left in 'c'; jump to '+'
	; If you get here, we're out of bits in 'c'!
	call	zDecEndOrGetByte	; get next byte -> 'a'
	ld	c,a						; a -> 'c'
	ld	b,7Fh					; b = 7Fh (7 new bits in 'c')
+
	srl	c						; test next bit of 'c'
	exx							; normal reg set
	jr	nc,+						; if bit not set, it's a compression bit; jump to '+'
	; If you get here, there's a non-compressed byte
	call	zDecEndOrGetByte	; get next byte -> 'a'
	ld	(de),a					; store it directly to the target memory address
	inc	de						; de++
	exx							; shadow reg set
	inc	de						; Also increase shadow-side 'de'... relative pointer only, does not point to output Z80_RAM
	exx							; normal reg set
	jr	zSaxmanReadLoop			; loop back around...
+
	call	zDecEndOrGetByte	; get next byte -> 'a'
	ld	c,a						; a -> 'c' (low byte of target address)
	call	zDecEndOrGetByte	; get next byte -> 'a'
	ld	b,a						; a -> 'b' (high byte of target address + count)
	and	0Fh						; keep only lower four bits...
	add	a,3						; add 3 (minimum 3 bytes are to be read in this mode)
	push	af					; save 'a'...
	ld	a,b						; b -> 'a' (low byte of target address)
	rlca
	rlca
	rlca
	rlca
	and	0Fh						; basically (b >> 4) & 0xF (upper four bits now exclusively as lower four bits)
	ld	b,a						; a -> 'b' (only upper four bits of value make up part of the address)
	ld	a,c
	add	a,12h
	ld	c,a
	adc	a,b
	sub	c
	and	0Fh
	ld	b,a						; bc += 12h
	pop	af						; restore 'a' (byte count to read; no less than 3)
	exx							; shadow reg set
	push	de					; keep current 'de' (relative pointer) value...
	ld	l,a						; how many bytes we will read -> 'hl'
	ld	h,0
	add	hl,de					; add current relative pointer...
	ex	de,hl					; effectively, de += a
	exx							; normal reg set
	pop	hl						; shadow 'de' -> 'hl' (relative pointer, prior to all bytes read, relative)
	or	a						; Clear carry
	sbc	hl,bc					; hl -= bc
	jr	nc,+					; if result positive, jump to '+'
	ex	de,hl					; current output pointer -> 'hl'
	ld	b,a						; how many bytes to load -> 'b'

-	ld	(hl),0					; fill in zeroes that many times
	inc	hl
	djnz	-

	ex	de,hl					; output pointer updated
	jr	zSaxmanReadLoop			; loop back around...
+
	ld	hl,zMusicData			; point at beginning of decompression point
	add	hl,bc					; move ahead however many bytes
	ld	c,a
	ld	b,0
	ldir
	jr	zSaxmanReadLoop
; End of function zSaxmanDec


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


; This is an ugly countdown to zero implemented in repeatedly modifying code!!
; But basically, it starts at the full length of the song +1 (so it can decrement)
; and waits until 'hl' decrements to zero
;zsub_12E8
zDecEndOrGetByte:
	ld	hl,0					; "self-modified code" -- starts at full length of song +1, waits until it gets to 1...
	dec	hl						; ... where this will be zero
	ld	(zDecEndOrGetByte+1),hl	; "self-modifying code" -- update the count in case it's not zero
	ld	a,h
	or	l
	jr	z,+						; If 'h' and 'l' both equal zero, we quit!!
;zloc_12F3
zGetNextByte:
	ld	hl,0				; "self-modified code" -- get address of next compressed byte
	ld	a,(hl)				; put it into -> 'a'
	inc	hl					; next byte...
	ld	(zGetNextByte+1),hl	; change inst @ zGetNextByte so it loads next compressed byte
	ret						; still going...
+
	pop	hl					; throws away return address to this function call so that next 'ret' exits decompressor (we're done!)
	ret						; Exit decompressor
; End of function zDecEndOrGetByte

; ---------------------------------------------------------------------------
	; space for a few global variables


; end of Z80 'ROM'
	if MOMPASS=1
		if $>zMusicData
			fatal "Your Z80 code won't fit before the music.. It's \{$-zMusicData}h bytes past the start of music data \{zMusicData}h"
		else
			message "Uncompressed sound driver size: $\{$} bytes."
		endif
	endif

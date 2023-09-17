sonic_4_boss_Header:
	smpsHeaderStartSong 3
	smpsHeaderVoice     sonic_4_boss_Voices
	smpsHeaderChan      $06, $03
	smpsHeaderTempo     $01, $40

	smpsHeaderDAC       sonic_4_boss_DAC
	smpsHeaderFM        sonic_4_boss_FM1,	$0C, $09
	smpsHeaderFM        sonic_4_boss_FM2,	$0C, $19
	smpsHeaderFM        sonic_4_boss_FM3,	$0C, $19
	smpsHeaderFM        sonic_4_boss_FM4,	$00, $0C
	smpsHeaderFM        sonic_4_boss_FM5,	$00, $0C
	smpsHeaderPSG       sonic_4_boss_PSG1,	$F4, $03, $00, $00
	smpsHeaderPSG       sonic_4_boss_PSG2,	$E8, $03, $00, $00
	smpsHeaderPSG       sonic_4_boss_PSG3,	$47, $00, $00, $00

; FM1 Data
sonic_4_boss_FM1:
	smpsSetvoice        $00
	smpsPan             panCenter, $00
	smpsModSet          $07, $01, $03, $05
	dc.b	nEb2, $06, nRst, nEb2, nEb2, nFs2, nRst, nFs2, nRst, nG2, $18, nC3
	dc.b	nG1, $06, nRst, nG2, nG2, nG2, nRst, nG1, nG1, nG1, nRst, nG2
	dc.b	nG2, nG2, nAb2, nG2, nG2

sonic_4_boss_Loop05:
	smpsCall            sonic_4_boss_Call06
	smpsCall            sonic_4_boss_Call07
	smpsLoop            $00, $02, sonic_4_boss_Loop05
	dc.b	nBb1, nRst, nF1, nRst, nBb1, $18, nRst, $0C, nF1, nAb1, nRst, nEb2
	dc.b	nRst, nG2, nD2, nB1, nG1
	smpsCall            sonic_4_boss_Call06
	dc.b	nAb1, $18, nRst, $0C, nEb1, $06, nEb1, nEb2, $0C, nAb1, nBb1, nB1
	smpsCall            sonic_4_boss_Call06
	smpsCall            sonic_4_boss_Call07
	dc.b	nBb1, nRst, nF1, nRst, nBb1, $18, nRst, $0C, nF1, nAb1, nRst, nEb2
	dc.b	nRst, nG2, nEb2, nB1, nFs1
	smpsJump            sonic_4_boss_Loop05

sonic_4_boss_Call06:
	dc.b	nC2, $0C, nRst, nG1, nRst, nC2, $18, nRst, $0C, nG1
	smpsReturn

sonic_4_boss_Call07:
	dc.b	nAb1, nRst, nEb2, nRst, nC2, nEb1, nF1, nEb1
	smpsReturn

; FM2 Data
sonic_4_boss_FM2:
	smpsSetvoice        $03
	smpsPan             panLeft, $00
	smpsFMAlterVol      $FB
	smpsModSet          $07, $01, $03, $05
	dc.b	nEb3, $03, nRst, nEb3, nRst, nEb3, nRst, nEb3, nRst, nEb3, nRst, $09
	dc.b	nEb3, $03, nRst, $09, nEb3, $12, nRst, $06, nG3, $12, nRst, $06
	dc.b	nG3, $12, nC4, $03, nRst, nB3, $12, nAb3, $03, nRst, nG3, nRst
	dc.b	$09, nB3, $03, nRst, $09
	smpsModSet          $0C, $01, $09, $07
	dc.b	nD4, $18
	smpsModSet          $07, $01, $03, $05
	smpsSetvoice        $01
	smpsPan             panCenter, $00
	smpsFMAlterVol      $05

sonic_4_boss_Loop04:
	smpsCall            sonic_4_boss_Call05
	smpsLoop            $00, $02, sonic_4_boss_Loop04
	smpsModSet          $18, $01, $07, $05
	dc.b	nEb4, $2A, nRst, $06, nD4, $12, nRst, $06, nEb4, $12, nRst, $06
	dc.b	nC4, $30, nBb3, $18, nB3
	smpsModSet          $07, $01, $03, $05
	smpsJump            sonic_4_boss_Loop04

sonic_4_boss_Call05:
	dc.b	nC4, $1E, nRst, $06, nG3, nRst, nC4, $12, nRst, $06, nE4, $12
	dc.b	nRst, $06, nEb4, nRst
	smpsModSet          $18, $01, $09, $07
	dc.b	nD4, $4E, nRst, $06
	smpsModSet          $07, $01, $03, $05
	smpsReturn

; FM3 Data
sonic_4_boss_FM3:
	smpsSetvoice        $03
	smpsPan             panRight, $00
	smpsFMAlterVol      $FB
	smpsModSet          $07, $01, $03, $05
	dc.b	nFs3, $03, nRst, nFs3, nRst, nFs3, nRst, nFs3, nRst, nFs3, nRst, $09
	dc.b	nAb3, $03, nRst, $09, nG3, $12, nRst, $06, nC4, $12, nRst, $06
	dc.b	nB3, $12, nAb3, $03, nRst, nD4, $12, nC4, $03, nRst, nB3, nRst
	dc.b	$09, nD4, $03, nRst, $09
	smpsModSet          $0C, $01, $09, $07
	dc.b	nG4, $18
	smpsModSet          $07, $01, $03, $05
	smpsSetvoice        $01
	smpsPan             panCenter, $00
	smpsFMAlterVol      $05

sonic_4_boss_Loop03:
	smpsCall            sonic_4_boss_Call04
	smpsLoop            $00, $02, sonic_4_boss_Loop03
	smpsModSet          $18, $01, $07, $05
	dc.b	nBb3, $2A, nRst, $06, nBb3, $12, nRst, $06, nBb3, $12, nRst, $06
	dc.b	nAb3, $30, nF3, $18, nF3
	smpsModSet          $07, $01, $03, $05
	smpsJump            sonic_4_boss_Loop03

sonic_4_boss_Call04:
	dc.b	nG3, $1E, nRst, $06, nE3, nRst, nG3, $12, nRst, $06, nC4, $12
	dc.b	nRst, $06, nC4, nRst
	smpsModSet          $18, $01, $09, $07
	dc.b	nAb3, $4E
	smpsModSet          $07, $01, $03, $05
	dc.b	nRst, $06
	smpsReturn

; FM4 Data
sonic_4_boss_FM4:
	smpsSetvoice        $02
	smpsPan             panLeft, $00
	smpsModSet          $07, $01, $05, $07
	smpsNoteFill        $04
	dc.b	nFs4, $0C, nFs4, $06, nFs4, nFs4, $0C, nFs4, nG4, nC5
	smpsNoteFill        $00
	dc.b	nEb5, $12, nRst, $06, nB4, $10, nRst, $02, nAb4, $06, nG4, $10
	dc.b	nRst, $02, nF4, $06, nEb4, nD4, nC4, nB3, nAb3, $0C, nG3
	smpsNoteFill        $04

sonic_4_boss_Loop02:
	smpsCall            sonic_4_boss_Call02
	smpsLoop            $00, $02, sonic_4_boss_Loop02
	smpsCall            sonic_4_boss_Call03
	dc.b	nRst, nG4, $04, nRst, $14, nG4, $04, nRst, $14, nC5, $06, nC5
	dc.b	nC5, $0C, nC5, nRst, nEb4, $06, nEb4, nEb4, $0C, nEb4, $04, nRst
	dc.b	$14, nAb4, $06, nAb4, nAb4, $0C, nAb4
	smpsCall            sonic_4_boss_Call02
	smpsCall            sonic_4_boss_Call03
	smpsJump            sonic_4_boss_Loop02

sonic_4_boss_Call02:
	dc.b	nRst, nG4, $04, nRst, $14, nG4, $04, nRst, $14, nC5, $06, nC5
	dc.b	nC5, $0C, nC5, nRst, nEb4, $04, nRst, $14, nEb4, $04, nRst, $14
	dc.b	nEb4, $06, nEb4, nEb4, $0C, nEb4
	smpsReturn

sonic_4_boss_Call03:
	dc.b	nRst, nF4, $04, nRst, $14, nF4, $04, nRst, $14, nF4, $06, nF4
	dc.b	nF4, $0C, nF4, nRst, nEb4, $04, nRst, $14, nEb4, $04, nRst, $14
	dc.b	nD4, $06, nD4, nF4, $0C, nF4
	smpsReturn

; FM5 Data
sonic_4_boss_FM5:
	smpsSetvoice        $02
	smpsPan             panRight, $00
	smpsModSet          $07, $01, $06, $08
	smpsNoteFill        $04
	dc.b	nC5, $0C, nC5, $06, nC5, nC5, $0C, nC5, nEb5, nG5
	smpsNoteFill        $00
	dc.b	nG5, $12, nRst, $06, nG5, $10, nRst, $02, nF5, $06, nEb5, $10
	dc.b	nRst, $02, nD5, $06, nC5, nB4, nAb4, nG4, nF4, $0C, nEb4
	smpsNoteFill        $04

sonic_4_boss_Loop01:
	smpsCall            sonic_4_boss_Call00
	smpsLoop            $00, $02, sonic_4_boss_Loop01
	smpsCall            sonic_4_boss_Call01
	dc.b	nRst, nC5, $04, nRst, $14, nC5, $04, nRst, $14, nE5, $06, nE5
	dc.b	nE5, $0C, nE5, nRst, nAb4, $06, nAb4, nAb4, $0C, nAb4, nRst, nEb5
	dc.b	$06, nEb5, nEb5, $0C, nEb5
	smpsCall            sonic_4_boss_Call00
	smpsCall            sonic_4_boss_Call01
	smpsJump            sonic_4_boss_Loop01

sonic_4_boss_Call00:
	dc.b	nRst, nC5, $04, nRst, $14, nC5, $04, nRst, $14, nE5, $06, nE5
	dc.b	nE5, $0C, nE5, nRst, nAb4, $04, nRst, $14, nAb4, $04, nRst, $14
	dc.b	nAb4, $06, nAb4, nAb4, $0C, nAb4
	smpsReturn

sonic_4_boss_Call01:
	dc.b	nRst, nBb4, $04, nRst, $14, nBb4, $04, nRst, $14, nBb4, $06, nBb4
	dc.b	nBb4, $0C, nBb4, nRst, nAb4, $04, nRst, $14, nAb4, $04, nRst, $14
	dc.b	nG4, $06, nG4, nBb4, $0C, nB4
	smpsReturn

; PSG1 Data
sonic_4_boss_PSG1:
	smpsPSGvoice        sTone_0A
	smpsPSGAlterVol     $FF
	dc.b	nRst, $12, nFs3, $04, nRst, $02, nEb3, $04, nRst, $08, nFs3, $04
	dc.b	nRst, $08, nG3, $04, nRst, $08, nC4, $04, nRst, $08, nC4, $12
	dc.b	nRst, $06
	smpsPSGAlterVol     $03
	dc.b	nG3, $04, nAb3, nG3, nAb3, nG3, nAb3
	smpsPSGAlterVol     $FF
	dc.b	nG3, nAb3, nG3, nAb3, nG3, nAb3
	smpsPSGAlterVol     $FF
	dc.b	nG3, nAb3, nG3, nAb3, nG3, nAb3
	smpsPSGAlterVol     $FF
	dc.b	nG3, nAb3, nG3, nAb3, nG3, nAb3
	smpsPSGAlterVol     $01

sonic_4_boss_Jump02:
	dc.b	nC4, $04, nRst, $2C, nC4, $04, nRst, $2C, nAb3, $04, nRst, $14
	dc.b	nAb3, $04, nRst, $14, nAb3, $04, nRst, $08, nEb3, $04, nRst, $08
	dc.b	nC3, $04, nRst, $08, nEb3, $04, nRst, $08, nC4, $04, nRst, $2C
	dc.b	nC4, $04, nRst, $2C, nAb3, $04, nRst, $14, nEb3, $18, nC3, nEb2
	dc.b	nBb2, $04, nRst, $2C, nBb2, $04, nRst, $2C, nAb2, $04, nRst, $14
	dc.b	nAb2, $04, nRst, $14, nG2, $0C, nF2, nFs2, nG2
	smpsPSGAlterVol     $FF
	dc.b	nC4, $02, nD4, nE4, $14, nC4, $18, nG3, nE3, nAb2, $06, nRst
	dc.b	$0C, nAb2, $06, nC3, nRst, nEb3, nRst, nAb3, nRst, nAb3, nRst, nAb3
	dc.b	nRst, nEb3, nRst
	smpsPSGAlterVol     $01
	dc.b	nE3, $04, nRst, $2C, nE3, $04, nRst, $2C, nAb3, $04, nRst, $14
	dc.b	nAb3, $04, nRst, $14, nAb3, $04, nRst, $08, nEb3, $04, nRst, $08
	dc.b	nC3, $04, nRst, $08, nEb3, $04, nRst, $08, nBb3, $04, nRst, $2C
	dc.b	nBb3, $04, nRst, $2C, nAb3, $04, nRst, $14, nEb3, $18, nB2, nFs2
	smpsJump            sonic_4_boss_Jump02

; PSG2 Data
sonic_4_boss_PSG2:
	smpsPSGvoice        sTone_17
	smpsAlterPitch      $0C
	smpsPSGAlterVol     $FF
	dc.b	nRst, $12, nEb3, $04, nRst, $02, nAb3, $04, nRst, $08, nEb3, $04
	dc.b	nRst, $08, nEb3, $04, nRst, $08, nG3, $04, nRst, $08, nG3, $12
	dc.b	nRst, $06
	smpsPSGAlterVol     $03
	dc.b	nG3, $04, nAb3, nG3, nAb3, nG3, nAb3
	smpsPSGAlterVol     $FF
	dc.b	nG3, nAb3, nG3, nAb3, nG3, nAb3
	smpsPSGAlterVol     $FF
	dc.b	nG3, nAb3, nG3, nAb3, nG3, nAb3
	smpsPSGAlterVol     $FF
	dc.b	nG3, nAb3, nG3, nAb3, nG3, nAb3
	smpsPSGAlterVol     $01
	smpsAlterPitch      $F4

sonic_4_boss_Jump01:
	smpsNoteFill        $04
	dc.b	nC3, $18, nE3, nC3, nE3, nC4
	smpsNoteFill        $00
	smpsPSGAlterVol     $FF
	dc.b	nAb4, $18, nEb4, nC4
	smpsPSGAlterVol     $01
	smpsNoteFill        $04
	dc.b	nC3, $18, nE3, nC3, nE3
	smpsNoteFill        $00
	smpsPSGAlterVol     $FF
	dc.b	nAb4, $18, nEb4, $04, nRst, $10, nEb4, $04, $0C, nC4, nAb3, nEb3
	smpsPSGAlterVol     $01
	smpsNoteFill        $04
	dc.b	nD4, $18, nF4, nD4, nF4, nC4
	smpsNoteFill        $00
	smpsPSGAlterVol     $FF
	dc.b	nAb4, $18, nD4, nEb4
	smpsPSGAlterVol     $01
	smpsNoteFill        $04
	dc.b	nC3, $18, nE3, nC3, nE3
	smpsPSGAlterVol     $FF
	smpsNoteFill        $00
	dc.b	nC4, $30, nRst, $0C, nAb4, $04, nRst, $02, nAb4, $04, nRst, $02
	dc.b	nAb4, $04, nRst, $08, nAb4, $04, nRst, $08
	smpsPSGAlterVol     $01
	smpsNoteFill        $04
	dc.b	nC3, $18, nE3, nC3, nE3, nC4
	smpsNoteFill        $00
	smpsPSGAlterVol     $FF
	dc.b	nAb4, $18, nEb4, nC4
	smpsPSGAlterVol     $01
	smpsNoteFill        $04
	dc.b	nD4, $18, nF4, nD4, nF4
	smpsNoteFill        $00
	smpsPSGAlterVol     $FF
	dc.b	nAb4, $18, nEb4, $06, nRst, $0C, nEb4, $04, nRst, $02, nD4, $0C
	dc.b	nB3, $06, nRst, nB3, $0C, nFs3, $06, nRst
	smpsPSGAlterVol     $01
	smpsJump            sonic_4_boss_Jump01

; PSG3 Data
sonic_4_boss_PSG3:
	smpsPSGform         $E7
	smpsPSGvoice        sTone_27
	dc.b	(nMaxPSG2-$47)&$FF, $30
	smpsPSGvoice        sTone_27
	dc.b	(nMaxPSG2-$47)&$FF
	smpsPSGvoice        sTone_27
	dc.b	(nMaxPSG2-$47)&$FF, $18, $48

sonic_4_boss_Jump00:
	smpsPSGvoice        sTone_27
	dc.b	(nMaxPSG2-$47)&$FF, $30
	smpsPSGvoice        sTone_01
	dc.b	(nMaxPSG2-$47)&$FF
	smpsPSGvoice        sTone_01
	dc.b	(nMaxPSG2-$47)&$FF
	smpsPSGvoice        sTone_01
	dc.b	(nMaxPSG2-$47)&$FF
	smpsPSGvoice        sTone_27
	dc.b	(nMaxPSG2-$47)&$FF
	smpsPSGvoice        sTone_01
	dc.b	(nMaxPSG2-$47)&$FF
	smpsPSGvoice        sTone_01
	dc.b	(nMaxPSG2-$47)&$FF
	smpsPSGvoice        sTone_01
	dc.b	(nMaxPSG2-$47)&$FF
	smpsPSGvoice        sTone_27
	dc.b	(nMaxPSG2-$47)&$FF
	smpsPSGvoice        sTone_27
	dc.b	(nMaxPSG2-$47)&$FF
	smpsPSGvoice        sTone_27
	dc.b	(nMaxPSG2-$47)&$FF
	smpsPSGvoice        sTone_27
	dc.b	(nMaxPSG2-$47)&$FF
	smpsPSGvoice        sTone_27
	dc.b	(nMaxPSG2-$47)&$FF
	smpsPSGvoice        sTone_01
	dc.b	(nMaxPSG2-$47)&$FF
	smpsPSGvoice        sTone_27
	dc.b	(nMaxPSG2-$47)&$FF
	smpsPSGvoice        sTone_27
	dc.b	(nMaxPSG2-$47)&$FF
	smpsPSGvoice        sTone_27
	dc.b	(nMaxPSG2-$47)&$FF
	smpsPSGvoice        sTone_01
	dc.b	(nMaxPSG2-$47)&$FF
	smpsPSGvoice        sTone_01
	dc.b	(nMaxPSG2-$47)&$FF
	smpsPSGvoice        sTone_01
	dc.b	(nMaxPSG2-$47)&$FF
	smpsPSGvoice        sTone_27
	dc.b	(nMaxPSG2-$47)&$FF
	smpsPSGvoice        sTone_27
	dc.b	(nMaxPSG2-$47)&$FF
	smpsPSGvoice        sTone_27
	dc.b	(nMaxPSG2-$47)&$FF
	smpsPSGvoice        sTone_27
	dc.b	(nMaxPSG2-$47)&$FF
	smpsJump            sonic_4_boss_Jump00

; DAC Data
sonic_4_boss_DAC:
	dc.b	dKickS3, $0C, dSnareS3, $03, dSnareS3, dSnareS3, dSnareS3, dSnareS3, $18, dKickS3, $0C, dSnareS3
	dc.b	$03, dSnareS3, dSnareS3, dSnareS3, dSnareS3, $18, dKickS3, $0C, dSnareS3, $04, dSnareS3, dSnareS3
	dc.b	dSnareS3, $06, dSnareS3, dSnareS3, dSnareS3, dSnareS3, dSnareS3, dSnareS3, dSnareS3, dSnareS3, $0C, $06
	dc.b	dSnareS3

sonic_4_boss_Loop00:
	dc.b	dKickS3, $0C, dSnareS3, dKickS3, dSnareS3, dKickS3, dSnareS3, dSnareS3, dSnareS3, dKickS3, dSnareS3, dKickS3
	dc.b	dSnareS3, dKickS3, dSnareS3, dSnareS3, dSnareS3, $04, dSnareS3, dSnareS3
	smpsLoop            $00, $03, sonic_4_boss_Loop00
	dc.b	dKickS3, $0C, dSnareS3, dKickS3, dSnareS3, dKickS3, dSnareS3, dSnareS3, dSnareS3, dKickS3, dSnareS3, dSnareS3
	dc.b	$0F, $03, dSnareS3, dSnareS3, dKickS3, $0C, dSnareS3, dSnareS3, $0F, $03, dSnareS3, dSnareS3
	dc.b	dKickS3, $0C, dSnareS3, dKickS3, dSnareS3, dKickS3, dSnareS3, dSnareS3, dSnareS3, dKickS3, dSnareS3, dKickS3
	dc.b	dSnareS3, dKickS3, dSnareS3, dSnareS3, dSnareS3, $04, dSnareS3, dSnareS3, dKickS3, $0C, dSnareS3, dKickS3
	dc.b	dSnareS3, dKickS3, dSnareS3, dSnareS3, dSnareS3, dKickS3, dSnareS3, dKickS3, dSnareS3, dKickS3, $18, dSnareS3
	dc.b	$0C, $06, dSnareS3
	smpsJump            sonic_4_boss_Loop00

sonic_4_boss_Voices:
;	Voice $04
;	$04
;	$10, $50, $7D, $31, 	$1F, $1F, $1F, $1F, 	$0D, $05, $11, $06
;	$05, $01, $05, $01, 	$FF, $FF, $FF, $FF, 	$00, $82, $0B, $83
	smpsVcAlgorithm     $04
	smpsVcFeedback      $00
	smpsVcUnusedBits    $00
	smpsVcDetune        $03, $07, $05, $01
	smpsVcCoarseFreq    $01, $0D, $00, $00
	smpsVcRateScale     $00, $00, $00, $00
	smpsVcAttackRate    $1F, $1F, $1F, $1F
	smpsVcAmpMod        $00, $00, $00, $00
	smpsVcDecayRate1    $06, $11, $05, $0D	
	smpsVcDecayRate2    $01, $05, $01, $05
	smpsVcDecayLevel    $0F, $0F, $0F, $0F
	smpsVcReleaseRate   $0F, $0F, $0F, $0F
	smpsVcTotalLevel    $83, $0B, $82, $00
;	Voice $04
;	$04
;	$10, $50, $7D, $31, 	$1F, $1F, $1F, $1F, 	$0D, $05, $11, $06
;	$05, $01, $05, $01, 	$FF, $FF, $FF, $FF, 	$00, $82, $0B, $83
	smpsVcAlgorithm     $04
	smpsVcFeedback      $00
	smpsVcUnusedBits    $00
	smpsVcDetune        $03, $07, $05, $01
	smpsVcCoarseFreq    $01, $0D, $00, $00
	smpsVcRateScale     $00, $00, $00, $00
	smpsVcAttackRate    $1F, $1F, $1F, $1F
	smpsVcAmpMod        $00, $00, $00, $00
	smpsVcDecayRate1    $06, $11, $05, $0D	
	smpsVcDecayRate2    $01, $05, $01, $05
	smpsVcDecayLevel    $0F, $0F, $0F, $0F
	smpsVcReleaseRate   $0F, $0F, $0F, $0F
	smpsVcTotalLevel    $83, $0B, $82, $00

;	Voice $04
;	$04
;	$10, $50, $7D, $31, 	$1F, $1F, $1F, $1F, 	$0D, $05, $11, $06
;	$05, $01, $05, $01, 	$FF, $FF, $FF, $FF, 	$00, $82, $0B, $83
	smpsVcAlgorithm     $04
	smpsVcFeedback      $00
	smpsVcUnusedBits    $00
	smpsVcDetune        $03, $07, $05, $01
	smpsVcCoarseFreq    $01, $0D, $00, $00
	smpsVcRateScale     $00, $00, $00, $00
	smpsVcAttackRate    $1F, $1F, $1F, $1F
	smpsVcAmpMod        $00, $00, $00, $00
	smpsVcDecayRate1    $06, $11, $05, $0D	
	smpsVcDecayRate2    $01, $05, $01, $05
	smpsVcDecayLevel    $0F, $0F, $0F, $0F
	smpsVcReleaseRate   $0F, $0F, $0F, $0F
	smpsVcTotalLevel    $83, $0B, $82, $00

;	Voice $04
;	$04
;	$10, $50, $7D, $31, 	$1F, $1F, $1F, $1F, 	$0D, $05, $11, $06
;	$05, $01, $05, $01, 	$FF, $FF, $FF, $FF, 	$00, $82, $0B, $83
	smpsVcAlgorithm     $04
	smpsVcFeedback      $00
	smpsVcUnusedBits    $00
	smpsVcDetune        $03, $07, $05, $01
	smpsVcCoarseFreq    $01, $0D, $00, $00
	smpsVcRateScale     $00, $00, $00, $00
	smpsVcAttackRate    $1F, $1F, $1F, $1F
	smpsVcAmpMod        $00, $00, $00, $00
	smpsVcDecayRate1    $06, $11, $05, $0D	
	smpsVcDecayRate2    $01, $05, $01, $05
	smpsVcDecayLevel    $0F, $0F, $0F, $0F
	smpsVcReleaseRate   $0F, $0F, $0F, $0F
	smpsVcTotalLevel    $83, $0B, $82, $00
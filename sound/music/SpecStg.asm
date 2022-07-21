ssmusic_Header:
	smpsHeaderStartSong 3
	smpsHeaderVoice     ssmusic_Voices
	smpsHeaderChan      $06, $03
	smpsHeaderTempo     $01, $00

	smpsHeaderDAC       ssmusic_DAC
	smpsHeaderFM        ssmusic_FM1,	$08, $10
	smpsHeaderFM        ssmusic_FM2,	$FC, $12
	smpsHeaderFM        ssmusic_FM3,	$FC, $15
	smpsHeaderFM        ssmusic_FM4,	$00, $15
	smpsHeaderFM        ssmusic_FM5,	$00, $15
	smpsHeaderPSG       ssmusic_PSG1,	$00, $05, $00, $00
	smpsHeaderPSG       ssmusic_PSG2,	$00, $05, $00, $00
	smpsHeaderPSG       ssmusic_PSG3,	$23, $02, $00, $00

; FM1 Data
ssmusic_FM1:
	smpsSetvoice        $00
	smpsModSet          $07, $01, $03, $05
	smpsPan             panCenter, $00
	dc.b	nG2, $06, nA2, nB2, nC3, nD3, nE3, nF3, nFs3, nG3, nRst, $12
	dc.b	nG2, $18

ssmusic_Jump02:
	dc.b	nC2, $0C, nC3, $06, nRst, nC2, $0C, nC3, $06, nRst, nC2, $0C
	dc.b	nC3, $06, nRst, nC2, $0C, nC3, $06, nRst, nC2, $0C, nC3, $06
	dc.b	nRst, nC2, $0C, nC3, $06, nRst, nC2, $0C, nC2, nD2, nE2, nF2
	dc.b	$0C, nF3, $06, nRst, nF2, $0C, nF3, $06, nRst, nF2, $0C, nF3
	dc.b	$06, nRst, nF2, $0C, nF3, $06, nRst, nF2, $0C, nF3, $06, nRst
	dc.b	nF2, $0C, nF3, $06, nRst, nF2, $0C, nF2, nE2, nD2, nC2, $18
	dc.b	nE2, nF2, nFs2, nG2, nF2, nE2, nD2, nC2, $05, nRst, $07, nC2
	dc.b	$05, nRst, $07, nC2, $06, nG2, $05, nRst, $07, nG2, $06, nA2
	dc.b	$05, nRst, $07, nA2, $0C, nB2, $05, nRst, $07, nB2, $0C, nC3
	dc.b	nRst, nG2, $18, nF2, nD2
	smpsJump            ssmusic_Jump02

; FM2 Data
ssmusic_FM2:
	smpsSetvoice        $01
	smpsModSet          $07, $01, $05, $07
	smpsPan             panCenter, $00
	dc.b	nG4, $06, nA4, nB4, nC5, nD5, nE5, nF5, nFs5, nG5, nRst, $12
	dc.b	nG4, $18

ssmusic_Jump01:
	dc.b	nG4, $0C, $0C, $0C, $0C, nRst, nG4, nFs4, nG4, nE5, $18, nD5
	dc.b	$0C, nC5, $3C, nA4, $0C, $0C, $0C, $0C, nRst, nA4, nAb4, nA4
	dc.b	nF5, $18, nE5, $0C, nD5, $3C, nRst, $18, nC5, nB4, nC5, nD5
	dc.b	$30, nB4, nC5, $60, smpsNoAttack, $0C, nRst, nG4, $18, nA4, nB4
	smpsJump            ssmusic_Jump01

; FM3 Data
ssmusic_FM3:
	smpsSetvoice        $01
	smpsModSet          $07, $01, $05, $07
	smpsPan             panCenter, $00
	dc.b	nG4, $06, nA4, nB4, nC5, nD5, nE5, nF5, nFs5, nG5, nRst, $12
	dc.b	nG4, $18

ssmusic_Jump00:
	dc.b	nE4, $0C, $0C, $0C, $0C, nRst, nE4, nEb4, nE4, nC5, $18, nB4
	dc.b	$0C, nG4, $3C, nF4, $0C, $0C, $0C, $0C, nRst, nF4, nE4, nF4
	dc.b	nD5, $18, nC5, $0C, nB4, $3C, nRst, $18, nG4, nFs4, nG4, nG4
	dc.b	$30, nF4, nE4, $60, smpsNoAttack, $0C, nRst, nE4, $18, nF4, nD4
	smpsJump            ssmusic_Jump00

; FM4 Data
ssmusic_FM4:
	smpsStop

; FM5 Data
ssmusic_FM5:
	smpsStop

; PSG1 Data
ssmusic_PSG1:
	smpsStop

; PSG2 Data
ssmusic_PSG2:
	smpsStop

; PSG3 Data
ssmusic_PSG3:
	smpsPSGform         $E7
	dc.b	nRst, $48
	smpsPSGvoice        sTone_12
	smpsPSGAlterVol     $FF
	dc.b	(nMaxPSG2-$23)&$FF, $0C
	smpsPSGAlterVol     $01
	dc.b	nRst, $0C

ssmusic_Loop02:
	smpsPSGvoice        sTone_12
	smpsPSGAlterVol     $FF
	dc.b	$0C
	smpsPSGAlterVol     $01
	dc.b	nRst, $0C

ssmusic_Loop01:
	smpsPSGvoice        sTone_0F
	dc.b	$06, $06
	smpsPSGvoice        sTone_12
	dc.b	$0C
	smpsLoop            $00, $07, ssmusic_Loop01
	smpsLoop            $01, $02, ssmusic_Loop02
	smpsPSGvoice        sTone_0F
	dc.b	$18, $18, $18, $18, $18, $18, $18, $18, $18, $18, $18, $18
	dc.b	$18, $18, $0C, $0C, $0C, $0C
	smpsJump            ssmusic_Loop02

; DAC Data
ssmusic_DAC:
	dc.b	dSnareS3, $06, dSnareS3, dSnareS3, dSnareS3, dSnareS3, dSnareS3, dSnareS3, dSnareS3, dSnareS3, $18, dKickS3

ssmusic_Loop00:
	dc.b	dKickS3, $0C, dSnareS3, dKickS3, dSnareS3, dKickS3, dSnareS3, dKickS3, dSnareS3, dKickS3, dSnareS3, dKickS3
	dc.b	dSnareS3, dKickS3, dSnareS3, $06, dSnareS3, dSnareS3, $0C, dSnareS3
	smpsLoop            $00, $02, ssmusic_Loop00
	dc.b	dKickS3, $18, dSnareS3, dKickS3, $0C, dKickS3, dSnareS3, $18, dKickS3, $18, dKickS3, dSnareS3
	dc.b	$0C, dElectricHighTom, $04, dElectricHighTom, dElectricMidTom, dElectricLowTom, $0C, dElectricFloorTom, dElectricFloorTom, $0C, dElectricFloorTom, dMuffledSnare
	dc.b	$12, dElectricHighTom, $06, dKickS3, dElectricHighTom, dElectricMidTom, dElectricMidTom, dElectricLowTom, dElectricLowTom, dClapS3, $0C, dKickS3
	dc.b	$18, dKickS3, dSnareS3, $06, dSnareS3, dSnareS3, dSnareS3, dSnareS3, dSnareS3, dSnareS3, dSnareS3
	smpsJump            ssmusic_Loop00

ssmusic_Voices:
;	Voice $00
;	$08
;	$0A, $70, $30, $00, 	$1F, $1F, $5F, $5F, 	$12, $0E, $0A, $0A
;	$00, $04, $04, $03, 	$2F, $2F, $2F, $2F, 	$24, $2D, $13, $80
	smpsVcAlgorithm     $00
	smpsVcFeedback      $01
	smpsVcUnusedBits    $00
	smpsVcDetune        $00, $03, $07, $00
	smpsVcCoarseFreq    $00, $00, $00, $0A
	smpsVcRateScale     $01, $01, $00, $00
	smpsVcAttackRate    $1F, $1F, $1F, $1F
	smpsVcAmpMod        $00, $00, $00, $00
	smpsVcDecayRate1    $0A, $0A, $0E, $12
	smpsVcDecayRate2    $03, $04, $04, $00
	smpsVcDecayLevel    $02, $02, $02, $02
	smpsVcReleaseRate   $0F, $0F, $0F, $0F
	smpsVcTotalLevel    $00, $13, $2D, $24

;	Voice $01
;	$3A
;	$01, $07, $01, $01, 	$8E, $8E, $8D, $53, 	$0E, $0E, $0E, $03
;	$00, $00, $00, $07, 	$1F, $FF, $1F, $0F, 	$18, $28, $27, $80
	smpsVcAlgorithm     $02
	smpsVcFeedback      $07
	smpsVcUnusedBits    $00
	smpsVcDetune        $00, $00, $00, $00
	smpsVcCoarseFreq    $01, $01, $07, $01
	smpsVcRateScale     $01, $02, $02, $02
	smpsVcAttackRate    $13, $0D, $0E, $0E
	smpsVcAmpMod        $00, $00, $00, $00
	smpsVcDecayRate1    $03, $0E, $0E, $0E
	smpsVcDecayRate2    $07, $00, $00, $00
	smpsVcDecayLevel    $00, $01, $0F, $01
	smpsVcReleaseRate   $0F, $0F, $0F, $0F
	smpsVcTotalLevel    $00, $27, $28, $18


CNZ_Header:
	smpsHeaderStartSong 2
	smpsHeaderVoice     CNZ_Voices
	smpsHeaderChan      $06, $03
	smpsHeaderTempo     $01, $FF

	smpsHeaderDAC       CNZ_DAC
	smpsHeaderFM        CNZ_FM1,	$0C, $08
	smpsHeaderFM        CNZ_FM2,	$F4, $0A
	smpsHeaderFM        CNZ_FM3,	$F4, $12
	smpsHeaderFM        CNZ_FM4,	$F4, $12
	smpsHeaderFM        CNZ_FM5,	$F4, $0F
	smpsHeaderPSG       CNZ_PSG1,	$DC, $05, $00, $00
	smpsHeaderPSG       CNZ_PSG2,	$DC, $05, $00, $00
	smpsHeaderPSG       CNZ_PSG3,	$00, $04, $00, $00

; FM1 Data
CNZ_FM1:
	smpsSetvoice        $00
	dc.b	nRst, $18

CNZ_Jump04:
	dc.b	nC3, $06, nC2, nC3, nC2, nC3, nC2, nC3, nC2, nRst, nG1, $04
	dc.b	nRst, $02, nBb1, $04, nAb1, $06, nG1, $04, nRst, $02, nG2, $02
	dc.b	nG1, $06, nA1, nB1, nC2, $06, nB1, nA1, nG1, nC2, nG1, nC2
	dc.b	nD2, nE2, nD2, nC2, nB1, nE1, nFs1, nAb1, nE1, nA1, nA1, nE2
	dc.b	nE2, nA1, nB1, nC2, nA1, nAb1, nBb1, nC2, nD2, nEb2, $04, $02
	dc.b	nAb1, $06, nC2, nAb1, nC2, nC2, nD2, nEb2, nE2, $04, $02, nE1
	dc.b	$06, nFs1, nAb1, nA1, nA1, nG1, nG1, nF1, nC2, nF1, nA1, nRst
	dc.b	nC2, nRst, nC2, nRst, nF2, nRst, nF2, nAb1, $0C, $06, nRst, $04
	dc.b	nG1, $04, nRst, $02, nG2, nF2, $06, nE2, nD2, nC2, $04, $02
	dc.b	nE1, $06, nF1, nFs1, nG1, nB1, nC2, nD2, nE2, nB1, nAb1, nFs1
	dc.b	nE1, nB1, nE2, nE1, nA1, nB1, nC2, nB1, nA1, nC2, nE2, nA1
	dc.b	nAb1, nBb1, nC2, nBb1, nAb1, nA1, nBb1, nB1, nC2, nB1, nC2, nD2
	dc.b	nE2, $04, $02, nB1, $06, nE1, nAb1, nA1, nB1, nC2, nE2, nF2
	dc.b	$04, nA1, $08, nBb1, $06, nB1, nRst, nC2, nRst, nC2, nRst, nF2
	dc.b	nRst, nF2
	smpsAlterVol        $04
	dc.b	nRst, nC2, nRst, nC2, nRst, nF2, nRst, nF2
	smpsAlterVol        $FC
	dc.b	nRst, nC2, nRst, nC2, nRst, nF2, nRst, nF2, $04, nC2, $02, nRst
	dc.b	$18, nC2, $02, nRst, nC2, nB1, $06, nA1, nG1
	smpsJump            CNZ_Jump04

; FM3 Data
CNZ_FM3:
	smpsSetvoice        $02
	smpsPan             panLeft, $00
	dc.b	nRst, $18

CNZ_Jump03:
	smpsSetvoice        $02
	dc.b	nRst, $06, nG5, nRst, nG5, nRst, nG5, nRst, nG5, nRst, nF5, $02
	dc.b	nRst, $04, nF5, $04, $02, nRst, $04, nF5, $02, nRst, $18
	smpsCall            CNZ_Call02
	smpsSetvoice        $01
	smpsAlterPitch      $F4
	smpsAlterVol        $FC
	smpsCall            CNZ_Call03
	dc.b	nE6, $18, nD6, $0C, nE6, $06, nD6, nC6, $18, nF6, nRst, $06
	dc.b	nG5, nRst, nG5, nRst, nA5, nRst, nA5
	smpsAlterVol        $04
	dc.b	nRst, nG5, nRst, nG5, nRst, nA5, nRst, nA5
	smpsAlterVol        $FC
	dc.b	nRst, nG5, nRst, nG5, nRst, nA5, $0C, $04, nG5, $02, nRst, $30
	smpsAlterPitch      $0C
	smpsAlterVol        $04
	smpsJump            CNZ_Jump03

CNZ_Call02:
	dc.b	nRst, $06, nG4, $02, nRst, $08, nG4, $02, nRst, $06, nG4, $08
	dc.b	nRst, $02, nG4, $06, nRst, $02, nG4, $04, $02, nRst, $06, nAb4
	dc.b	$02, nRst, $08, nAb4, $02, nRst, $06, nAb4, $08, nRst, $02, nAb4
	dc.b	$06, nRst, $02, nAb4, $04, $02, nRst, $06, nA4, $02, nRst, $08
	dc.b	nA4, $02, nRst, $06, nA4, $08, nRst, $02, nA4, $06, nRst, $02
	dc.b	nA4, $04, $02, nRst, $06, nAb4, $02, nRst, $08, nAb4, $02, nRst
	dc.b	$06, nAb4, $08, nRst, $02, nAb4, $06, nRst, $02, nAb4, $04, $02
	dc.b	nRst, $06, nG4, $02, nRst, $08, nG4, $02, nRst, $06, nAb4, $08
	dc.b	nRst, $02, nAb4, $06, nRst, $02, nAb4, $04, $02, nRst, $06, nA4
	dc.b	$02, nRst, $08, nA4, $02, nRst, $06, nA4, $08, nRst, $02, nA4
	dc.b	$06, nRst, $02, nA4, $04, $02, nRst, $06, nG4, nRst, nG4, nRst
	dc.b	nA4, nRst, nA4, nC5, $0C, $06, $04, nB4, $02, nRst, $18
	smpsReturn

CNZ_Call03:
	dc.b	nRst, $06, nE6, $02, nRst, $08, nE6, $02, nRst, $06, nE6, $06
	dc.b	nF6, $04, nE6, $02, nRst, $0C, nRst, $06, nD6, $02, nRst, $08
	dc.b	nD6, $02, nRst, $06, nD6, $06, nE6, $04, nD6, $02, nRst, $0C
	dc.b	nRst, $06, nC6, $02, nRst, $08, nC6, $02, nRst, $06, nC6, $06
	dc.b	nD6, $04, nC6, $02, nRst, $0C, nRst, $06, nC6, $02, nRst, $08
	dc.b	nC6, $02, nRst, $06, nC6, $06, nD6, $04, nC6, $02, nRst, $0C
	smpsReturn

; FM4 Data
CNZ_FM4:
	smpsSetvoice        $02
	smpsPan             panRight, $00
	dc.b	nRst, $18

CNZ_Jump02:
	smpsSetvoice        $02
	dc.b	nRst, $06, nEb5, nRst, nEb5, nRst, nEb5, nRst, nEb5, nRst, nD5, $02
	dc.b	nRst, $04, nD5, $04, $02, nRst, $04, nD5, $02, nRst, $18
	smpsCall            CNZ_Call00
	smpsSetvoice        $01
	smpsAlterPitch      $F4
	smpsAlterVol        $FC
	smpsCall            CNZ_Call01
	dc.b	nC6, $18, nB5, $0C, nC6, $06, nB5, nA5, $18, nC6, nRst, $06
	dc.b	nE5, nRst, nE5, nRst, nF5, nRst, nF5
	smpsAlterVol        $04
	dc.b	nRst, nE5, nRst, nE5, nRst, nF5, nRst, nF5
	smpsAlterVol        $FC
	dc.b	nRst, nE5, nRst, nE5, nRst, nF5, $0C, $04, nE5, $02, nRst, $30
	smpsAlterPitch      $0C
	smpsAlterVol        $04
	smpsJump            CNZ_Jump02

CNZ_Call00:
	dc.b	nRst, $06, nE4, $02, nRst, $08, nE4, $02, nRst, $06, nE4, $08
	dc.b	nRst, $02, nE4, $06, nRst, $02, nE4, $04, $02
	smpsLoop            $00, $03, CNZ_Call00
	dc.b	nRst, $06, nEb4, $02, nRst, $08, nEb4, $02, nRst, $06, nEb4, $08
	dc.b	nRst, $02, nEb4, $06, nRst, $02, nEb4, $04, $02, nRst, $06, nE4
	dc.b	$02, nRst, $08, nE4, $02, nRst, $06, nE4, $08, nRst, $02, nE4
	dc.b	$06, nRst, $02, nE4, $04, $02, nRst, $06, nE4, $02, nRst, $08
	dc.b	nE4, $02, nRst, $06, nF4, $08, nRst, $02, nF4, $06, nRst, $02
	dc.b	nF4, $04, $02, nRst, $06, nE4, nRst, nE4, nRst, nF4, nRst, nF4
	dc.b	nAb4, $0C, $06, $04, nG4, $02, nRst, $18
	smpsReturn

CNZ_Call01:
	dc.b	nRst, $06, nC6, $02, nRst, $08, nC6, $02, nRst, $06, nC6, $06
	dc.b	nD6, $04, nC6, $02, nRst, $0C, nRst, $06, nB5, $02, nRst, $08
	dc.b	nB5, $02, nRst, $06, nB5, $06, nC6, $04, nB5, $02, nRst, $0C
	dc.b	nRst, $06, nA5, $02, nRst, $08, nA5, $02, nRst, $06, nA5, $06
	dc.b	nB5, $04, nA5, $02, nRst, $0C, nRst, $06, nAb5, $02, nRst, $08
	dc.b	nAb5, $02, nRst, $06, nAb5, $06, nBb5, $04, nAb5, $02, nRst, $0C
	smpsReturn

; FM2 Data
CNZ_FM2:
	smpsSetvoice        $01
	smpsModSet          $1C, $01, $06, $04
	dc.b	nRst, $18

CNZ_Jump01:
	smpsSetvoice        $01
	dc.b	nRst, $06, nEb5, $0C, nC5, $02, nRst, $04, nFs5, nF5, $02, nRst
	dc.b	$04, nEb5, $02, nRst, $04, nC5, $08, nRst, $06, nG4, $02, nRst
	dc.b	$04, nBb4, nAb4, $02, nRst, $04, nG4, $02, nRst, $0C, nE4, $04
	dc.b	nRst, $02, nE4, $04, nRst, $02, nE4, $18, nRst, $06, nE4, $04
	dc.b	nRst, $02, nF4, $04, nE4, $08, nAb4, $04, $02, nRst, $04, nE4
	dc.b	$1A, nRst, $06, nE4, nA4, $04, $02, nRst, $04, nE4, $02, nC4
	dc.b	$12, nRst, $06, nC4, $04, nRst, $02, nD4, $04, nC4, $02, nEb4
	dc.b	$06, nD4, $04, nC4, $26, nRst, $06, nE4, $04, nRst, $02, nF4
	dc.b	$04, nRst, $02, nE4, $04, nRst, $02, nAb4, $04, $02, nRst, $04
	dc.b	nE4, $0E, nRst, $06, nA4, $0C, nB4, $04, nA4, $02, nC5, $0C
	dc.b	nRst, $06, nA4, $02, nRst, $04, nG4, $0C, nE4, nC4, nD4, nEb4
	dc.b	nF4, $04, nEb4, $02, nF4, $04, nG4, $02, nRst, $10, nG3, $02
	dc.b	nA3, $04, nC4, $02, nE4, $18, nRst, $06, nE4, $04, nRst, $02
	dc.b	nF4, $04, nE4, $08, nAb4, $04, $02, nRst, $04, nE4, $1A, nRst
	dc.b	$06, nE4, nA4, $04, $02, nRst, $04, nE4, $02, nC4, $12, nRst
	dc.b	$06, nC4, $04, nRst, $02, nD4, $04, nC4, $02, nEb4, $06, nD4
	dc.b	$04, nC4, $26, nRst, $06, nE4, $04, nRst, $02, nF4, $04, nRst
	dc.b	$02, nE4, $04, nRst, $02, nAb4, $04, $02, nRst, $04, nE4, $0E
	dc.b	nRst, $06, nA4, $0C, nB4, $04, nA4, $02, nC5, $0C, nRst, $06
	dc.b	nA4, $02, nRst, $04, nG4, $0C, nE4, nC4, nD4, $06
	smpsAlterVol        $04
	dc.b	nA4, $02, nRst, $04, nG4, $0C, nE4, nC4, nD4, $06
	smpsAlterVol        $FC
	dc.b	nA4, $02, nRst, $04, nG4, $0C, nE4, nC4, nD4, $0A, nC4, $02
	dc.b	nRst, $30
	smpsJump            CNZ_Jump01

; FM5 Data
CNZ_FM5:
	smpsSetvoice        $01
	dc.b	nRst, $18
	smpsModSet          $1C, $01, $06, $04

CNZ_Jump00:
	smpsSetvoice        $01
	dc.b	nRst, $06, nC5, $0C, nG4, $02, nRst, $04, nEb5, nD5, $02, nRst
	dc.b	$04, nC5, $02, nRst, $04, nG4, $08, nRst, $06, nD4, $02, nRst
	dc.b	$04, nF4, nEb4, $02, nRst, $04, nD4, $02, nRst, $0C, nA3, $04
	dc.b	nRst, $02, nB3, $04, nRst, $02, nC4, $18, nRst, $06, nC4, $04
	dc.b	nRst, $02, nD4, $04, nC4, $08, nE4, $04, nE4, $02, nRst, $04
	dc.b	nB3, $1A, nRst, $06, nB3, nE4, $04, $02, nRst, $04, nC4, $02
	dc.b	nA3, $12, nRst, $06, nA3, $04, nRst, $02, nB3, $04, nA3, $02
	dc.b	nC4, $06, nBb3, $04, nAb3, $26, nRst, $06, nC4, $04, nRst, $02
	dc.b	nD4, $04, nRst, $02, nC4, $04, nRst, $02, nE4, $04, nE4, $02
	dc.b	nRst, $04, nB3, $0E, nRst, $06, nE4, $0C, nG4, $04, nE4, $02
	dc.b	nA4, $0C, nRst, $06, nF4, $02, nRst, $04, nE4, $0C, nC4, nA3
	dc.b	nB3, nC4, nD4, $04, nC4, $02, nD4, $04, nD4, $02, nRst, $10
	dc.b	nD3, $02, nE3, $04, nG3, $02, nC4, $18, nRst, $06, nC4, $04
	dc.b	nRst, $02, nD4, $04, nC4, $08, nE4, $04, nE4, $02, nRst, $04
	dc.b	nB3, $1A, nRst, $06, nB3, nE4, $04, $02, nRst, $04, nC4, $02
	dc.b	nA3, $12, nRst, $06, nA3, $04, nRst, $02, nB3, $04, nA3, $02
	dc.b	nC4, $06, nBb3, $04, nAb3, $26, nRst, $06, nC4, $04, nRst, $02
	dc.b	nD4, $04, nRst, $02, nC4, $04, nRst, $02, nE4, $04, nE4, $02
	dc.b	nRst, $04, nB3, $0E, nRst, $06, nE4, $0C, nG4, $04, nE4, $02
	dc.b	nA4, $0C, nRst, $06, nF4, $02, nRst, $04, nE4, $0C, nC4, nA3
	dc.b	nB3, $06
	smpsAlterVol        $04
	dc.b	nF4, $02, nRst, $04, nE4, $0C, nC4, nA3, nB3, $06
	smpsAlterVol        $F8
	dc.b	nF4, $02, nRst, $04, nE4, $0C, nC4, nA3, nF3, $0A, nE3, $02
	dc.b	nRst, $30
	smpsAlterVol        $04
	smpsJump            CNZ_Jump00

; PSG1 Data
CNZ_PSG1:
	dc.b	nRst, $18

CNZ_Jump06:
	dc.b	nRst, $06, nG4, $0C, nEb4, $02, nRst, $04, nA4, nAb4, $02, nRst
	dc.b	$04, nG4, $02, nRst, $04, nEb4, $08, nRst, $06, nB3, $02, nRst
	dc.b	$04, nD4, nC4, $02, nRst, $04, nB3, $02, nRst, $18
	smpsPSGvoice        fTone_01
	smpsPSGAlterVol     $FF
	smpsCall            CNZ_Call02
	smpsPSGAlterVol     $01
	smpsPSGvoice        $00
	smpsAlterPitch      $E8
	smpsCall            CNZ_Call03
	smpsAlterPitch      $18
	smpsPSGAlterVol     $02
	dc.b	nE4, $18, nD4, $0C, nE4, $06, nD4, nC4, $18, nF4
	smpsPSGAlterVol     $FE
	dc.b	nRst, $06, nG4, nRst, nG4, nRst, nA4, nRst, nA4
	smpsPSGAlterVol     $03
	dc.b	nG5, $0C, nE5, nC5, nD5, $06, nRst
	smpsPSGAlterVol     $FC
	dc.b	nRst, nG4, nRst, nG4, nRst, nA4, $0C, $04, nG4, $02, nRst, $30
	smpsPSGAlterVol     $01
	smpsJump            CNZ_Jump06

; PSG2 Data
CNZ_PSG2:
	dc.b	nRst, $18

CNZ_Jump05:
	dc.b	nRst, $06, nEb5, $0C, nC5, $02, nRst, $04, nFs5, nF5, $02, nRst
	dc.b	$04, nEb5, $02, nRst, $04, nC5, $08, nRst, $06, nG4, $02, nRst
	dc.b	$04, nBb4, nAb4, $02, nRst, $04, nG4, $02, nRst, $18
	smpsPSGvoice        fTone_01
	smpsPSGAlterVol     $FF
	smpsCall            CNZ_Call00
	smpsPSGAlterVol     $01
	smpsPSGvoice        $00
	smpsAlterPitch      $E8
	smpsCall            CNZ_Call01
	smpsAlterPitch      $18
	smpsPSGAlterVol     $02
	dc.b	nC4, $18, nB3, $0C, nC4, $06, nB3, nA3, $18, nC4
	smpsPSGAlterVol     $FE
	dc.b	nRst, $06, nE4, nRst, nE4, nRst, nF4, nRst, nF4
	smpsPSGAlterVol     $03
	dc.b	nRst, nC4, nRst, nC4, nRst, nC4, nRst, nC4
	smpsPSGAlterVol     $FC
	dc.b	nRst, nC4, nRst, nC4, nRst, nC4, $0C, $04, nC4, $02
	smpsPSGAlterVol     $01
	dc.b	nRst, $30
	smpsJump            CNZ_Jump05

; PSG3 Data
CNZ_PSG3:
	smpsPSGform         $E7
	dc.b	nRst, $18

CNZ_Loop03:
	smpsCall            CNZ_Call04
	smpsLoop            $01, $07, CNZ_Loop03
	dc.b	$04, $02, $04, $02

CNZ_Loop04:
	smpsCall            CNZ_Call04
	smpsLoop            $01, $1F, CNZ_Loop04
	dc.b	$04, $02, $04, $02

CNZ_Loop05:
	smpsCall            CNZ_Call04
	smpsLoop            $01, $24, CNZ_Loop05
	dc.b	nRst, $30
	smpsJump            CNZ_Loop03

CNZ_Call04:
	smpsPSGvoice        fTone_01
	dc.b	nMaxPSG, $06
	smpsPSGvoice        fTone_02
	smpsPSGAlterVol     $FF
	dc.b	$04
	smpsPSGvoice        fTone_01
	smpsPSGAlterVol     $01
	dc.b	$02
	smpsReturn

; DAC Data
CNZ_DAC:
	dc.b	dKick, $06, dKick, dKick, $04, dSnare, $02, $06

CNZ_Loop00:
	dc.b	dKick, $06, dSnare
	smpsLoop            $00, $04, CNZ_Loop00
	dc.b	dKick, $06, dSnare, dSnare, $04, $06, $06, dKick, $02, $06, $06, dSnare

CNZ_Loop01:
	dc.b	dKick, dSnare
	smpsLoop            $00, $1C, CNZ_Loop01
	dc.b	dKick, dSnare, dSnare, $04, $06, $06, dKick, $02, $06, $06, dSnare

CNZ_Loop02:
	dc.b	dKick, dSnare
	smpsLoop            $00, $20, CNZ_Loop02
	dc.b	dKick, dSnare, dKick, dSnare, dKick, dSnare, dSnare, $04, $06, $02, nRst, $28
	dc.b	dSnare, $02, $06
	smpsJump            CNZ_Loop00

CNZ_Voices:
;	Voice $00
;	$35
;	$10, $51, $00, $11, 	$5F, $5F, $5F, $5F, 	$0E, $1F, $1F, $1F
;	$00, $00, $00, $00, 	$46, $07, $07, $07, 	$1A, $80, $8A, $80
	smpsVcAlgorithm     $05
	smpsVcFeedback      $06
	smpsVcUnusedBits    $00
	smpsVcDetune        $01, $00, $05, $01
	smpsVcCoarseFreq    $01, $00, $01, $00
	smpsVcRateScale     $01, $01, $01, $01
	smpsVcAttackRate    $1F, $1F, $1F, $1F
	smpsVcAmpMod        $00, $00, $00, $00
	smpsVcDecayRate1    $1F, $1F, $1F, $0E
	smpsVcDecayRate2    $00, $00, $00, $00
	smpsVcDecayLevel    $00, $00, $00, $04
	smpsVcReleaseRate   $07, $07, $07, $06
	smpsVcTotalLevel    $00, $0A, $00, $1A

;	Voice $01
;	$34
;	$33, $41, $7E, $74, 	$9B, $5F, $1F, $1F, 	$04, $0A, $07, $08
;	$00, $00, $00, $00, 	$F9, $F7, $EC, $FD, 	$21, $80, $33, $8F
	smpsVcAlgorithm     $04
	smpsVcFeedback      $06
	smpsVcUnusedBits    $00
	smpsVcDetune        $07, $07, $04, $03
	smpsVcCoarseFreq    $04, $0E, $01, $03
	smpsVcRateScale     $00, $00, $01, $02
	smpsVcAttackRate    $1F, $1F, $1F, $1B
	smpsVcAmpMod        $00, $00, $00, $00
	smpsVcDecayRate1    $08, $07, $0A, $04
	smpsVcDecayRate2    $00, $00, $00, $00
	smpsVcDecayLevel    $0F, $0E, $0F, $0F
	smpsVcReleaseRate   $0D, $0C, $07, $09
	smpsVcTotalLevel    $0F, $33, $00, $21

;	Voice $02
;	$3C
;	$01, $02, $0F, $04, 	$8D, $52, $9F, $1F, 	$09, $00, $00, $0D
;	$00, $00, $00, $00, 	$23, $08, $02, $F7, 	$15, $80, $1D, $87
	smpsVcAlgorithm     $04
	smpsVcFeedback      $07
	smpsVcUnusedBits    $00
	smpsVcDetune        $00, $00, $00, $00
	smpsVcCoarseFreq    $04, $0F, $02, $01
	smpsVcRateScale     $00, $02, $01, $02
	smpsVcAttackRate    $1F, $1F, $12, $0D
	smpsVcAmpMod        $00, $00, $00, $00
	smpsVcDecayRate1    $0D, $00, $00, $09
	smpsVcDecayRate2    $00, $00, $00, $00
	smpsVcDecayLevel    $0F, $00, $00, $02
	smpsVcReleaseRate   $07, $02, $08, $03
	smpsVcTotalLevel    $07, $1D, $00, $15

;	Voice $03
;	$04
;	$30, $01, $30, $01, 	$07, $1E, $1A, $1F, 	$00, $0F, $00, $0F
;	$00, $00, $00, $00, 	$1F, $1B, $1F, $18, 	$2C, $80, $1A, $80
	smpsVcAlgorithm     $04
	smpsVcFeedback      $00
	smpsVcUnusedBits    $00
	smpsVcDetune        $00, $03, $00, $03
	smpsVcCoarseFreq    $01, $00, $01, $00
	smpsVcRateScale     $00, $00, $00, $00
	smpsVcAttackRate    $1F, $1A, $1E, $07
	smpsVcAmpMod        $00, $00, $00, $00
	smpsVcDecayRate1    $0F, $00, $0F, $00
	smpsVcDecayRate2    $00, $00, $00, $00
	smpsVcDecayLevel    $01, $01, $01, $01
	smpsVcReleaseRate   $08, $0F, $0B, $0F
	smpsVcTotalLevel    $00, $1A, $00, $2C

;	Voice $04
;	$3D
;	$01, $02, $02, $02, 	$10, $50, $50, $50, 	$07, $08, $08, $08
;	$01, $00, $00, $00, 	$24, $18, $18, $18, 	$1C, $89, $89, $89
	smpsVcAlgorithm     $05
	smpsVcFeedback      $07
	smpsVcUnusedBits    $00
	smpsVcDetune        $00, $00, $00, $00
	smpsVcCoarseFreq    $02, $02, $02, $01
	smpsVcRateScale     $01, $01, $01, $00
	smpsVcAttackRate    $10, $10, $10, $10
	smpsVcAmpMod        $00, $00, $00, $00
	smpsVcDecayRate1    $08, $08, $08, $07
	smpsVcDecayRate2    $00, $00, $00, $01
	smpsVcDecayLevel    $01, $01, $01, $02
	smpsVcReleaseRate   $08, $08, $08, $04
	smpsVcTotalLevel    $09, $09, $09, $1C




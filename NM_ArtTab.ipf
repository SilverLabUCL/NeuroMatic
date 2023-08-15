#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma hide = 1

//****************************************************************
//
//	NeuroMatic: data aquisition, analyses and simulation software that runs with the Igor Pro environment
//	Copyright (C) 2017 Jason Rothman
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// ( at your option ) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
//	Contact Jason@ThinkRandom.com
//	www.NeuroMatic.ThinkRandom.com
//
//****************************************************************
//
//	Stimulus Artefact Subtraction
//
//	NM tab entry "Art"
//
//****************************************************************
//
//	Default Values
//
//****************************************************************

Static StrConstant k_ArtShape = "PN"
	// "PN" - artefact ends with large positive peak followed by small negative peak
	// "NP" - artefact ends with large negative peak followed by small positive peak

Static Constant k_ArtWidth = 0.5 // approximate length of artefact
Static Constant k_ArtLevelDetection = 50 // threshold for artefact level detection
Static Constant k_ArtLevelDetectionEdge = 1 // see Igor FindLevels edge

Static Constant k_ArtFitWin = 0.2 // artefact decay fit window
Static Constant k_ArtPeakDT = 0 // artefact peak detection offset for computing decay fit window, 0 - no time shift
StrConstant k_ArtFitFxnList = "Exp;2Exp;"
Static StrConstant k_ArtFitFxn = "Exp" // decay function for artefact tail fit // "Exp" or "2Exp"

Static Constant k_SubtractWin = 2 // subtraction window
	// SubtractWin should include extrapolation after ArtFitWin to allow decay to fall back to baseline

//StrConstant k_ArtBslnFxnList = "Avg;Line;Exp;2Exp;Zero;" // 2Exp NOT WORKING
StrConstant k_ArtBslnFxnList = "Avg;Line;Exp;Zero;"
Static StrConstant k_BslnFxn = "Avg" // baseline function to compute within BslnWin:
	// "Avg" - baseline is average value, i.e. line with zero slope
	// "Line" - fits a line to baseline data; use if your baseline is not always flat
	// "Exp" - fits an 1-exp to baseline data; use if your baseline has exp decay
	// "Zero" - baseline is zero

Static Constant k_BslnWin = 1.5 // baseline window size; baseline is computed immediately before artefact time
Static Constant k_BslnDT = 0.1 // baseline time shift negative from artefact time, 0 - no time shift
Static Constant k_BslnConvergeWin = 0.5 // length of steady-state convergence test window
Static Constant k_BslnConvergeNstdv = 1 // steady-state convergence test between baseline and artefact fit, number of stdv of the data wave
Static Constant k_BslnExpSlopeThreshold = 0
		// compute baseline exp fit if baseline slope > +threshold, otherwise compute baseline avg
		// compute baseline exp fit if baseline slope < -threshold, otherwise compute baseline avg
		
Static Constant k_DragWaveAll = 1 // (0) drag waves adjust current artefact (1) drag waves adjust all artefacts

Static Constant k_SaveFitParameters = 1 // 0 or 1
Static Constant k_SaveSubtractedArt = 1 // 0 or 1 // AT_A_ waves
		
// Static StrConstant k_WaveNameFormat = "v2" // old
Static StrConstant k_WaveNameFormat = "v3p"

//****************************************************************

Static StrConstant NMArtDF = "root:Packages:NeuroMatic:Art:"

//****************************************************************

Menu "NeuroMatic"

	Submenu StrVarOrDefault( NMDF + "NMMenuShortcuts" , "\\M1(Keyboard Shortcuts" )
		StrVarOrDefault( NMDF + "NMMenuShortcutArt0" , "" )
		StrVarOrDefault( NMDF + "NMMenuShortcutArt1" , "" ), /Q, NMArtCall( "NextArt" )
		StrVarOrDefault( NMDF + "NMMenuShortcutArt2" , "" ), /Q, NMArtCall( "SubtractToggle" )
	End
	
End // NeuroMatic menu

//****************************************************************

Function NMMenuBuildArt()

	if ( NMVarGet( "NMOn" ) && StringMatch( CurrentNMTabName(), "Art" ) )
		SetNMstr( NMDF + "NMMenuShortcutArt0", "-" )
		SetNMstr( NMDF + "NMMenuShortcutArt1", "Next Artefact/4" )
		SetNMstr( NMDF + "NMMenuShortcutArt2", "Subtract/5" )
	else
		SetNMstr( NMDF + "NMMenuShortcutArt0", "" )
		SetNMstr( NMDF + "NMMenuShortcutArt1", "" )
		SetNMstr( NMDF + "NMMenuShortcutArt2", "" )
	endif

End // NMMenuBuildArt

//****************************************************************

Function /S NMTabPrefix_Art()
	
	return "AT_"
	
End // NMTabPrefix_Art

//****************************************************************

Function NMArtTab( enable )
	Variable enable // ( 0 ) disable ( 1 ) enable tab
	
	Variable autoFit //, error = NaN
	
	if ( enable )
		CheckPackage( "Art", 0 ) // declare globals if necessary
		NMArtCheck()
		autoFit = NMArtVarGet( "AutoFit" )
		//error = NMArtWavesCheck( forceMakeFits=autoFit )
		NMArtMake( 0 ) // make tab controls if necessary
		NMArtWaveOfArtTimesSet( "UPDATE", artNum=-1, forceMakeFits=autoFit ) // calls NMArtWavesCheck()
	endif
	
	if ( !DataFolderExists( NMArtDF ) )
		return 0
	endif
	
	NMArtDisplay( enable )
	NMArtChanGraphControls( enable )
	
	if ( enable && autoFit )
		NMArtFit( checkWaves=0 )
	endif

End // NMArtTab

//****************************************************************

Function NMArtTabKill( what )
	String what
	
	String df = NMArtDF
	
	strswitch( what )
		case "waves":
			break
		case "globals":
			if ( DataFolderExists( df ) )
			//	KillDataFolder $df
			endif
			break
	endswitch

End // NMArtTabKill

//****************************************************************

Function NMArtAuto() // called when wave number is incremented or wave-prefix changes
	
	Variable autoFit = NMArtVarGet( "AutoFit" )
	
	NMArtWaveOfArtTimesSet( "UPDATE", artNum=-1, forceMakeFits=autoFit ) // calls NMArtWavesCheck()
	
	if ( autoFit )
		NMArtFit( checkWaves=0 )
	endif
	
	return 0

End // NMArtAuto

//****************************************************************

Function NMArtCheck() // check globals

	String df = NMArtDF
	
	if ( !DataFolderExists( df ) )
		return 0 // Art folder does not exist
	endif
	
	// panel control parameters
	
	CheckNMVar( df+"NumArtefacts", 0 )
	CheckNMVar( df+"ArtNum", NumVarOrDefault( df+"StimNum", 0 ) )
	CheckNMVar( df+"ArtTime", NaN )
	
	CheckNMVar( df+"BslnValue1", Nan )
	CheckNMVar( df+"BslnValue2", Nan )
	CheckNMVar( df+"BslnChi", Nan )
	
	CheckNMVar( df+"DcayValue1", Nan )
	CheckNMVar( df+"DcayValue2", Nan )
	CheckNMVar( df+"DcayChi", Nan )
	
	CheckNMVar( df+"AutoFit", 1 )
	CheckNMVar( df+"FitFlag", NaN )
	
	CheckNMStr( df+"ArtTimeWName", StrVarOrDefault( df+"StimTimeWName", "" ) )
	
	// drag wave variables
	
	CheckNMVar( df+"BslnXbgn", NaN )
	CheckNMVar( df+"BslnXend", NaN )
	CheckNMVar( df+"Xbgn", NaN )
	CheckNMVar( df+"Xend", NaN )
	
	// fit variables
	
	CheckNMStr( df+"BslnFxn", k_BslnFxn )
	CheckNMVar( df+"BslnDT", abs( k_BslnDT ) )
	CheckNMVar( df+"BslnWin", abs( k_BslnWin ) )
	CheckNMVar( df+"BslnSubtract", 0 )
	CheckNMVar( df+"BslnConvergeWin", abs( k_BslnConvergeWin ) )
	CheckNMVar( df+"BslnConvergeNstdv", abs( k_BslnConvergeNstdv ) )
	
	CheckNMStr( df+"ArtShape", k_ArtShape )
	CheckNMVar( df+"ArtWidth", abs( k_ArtWidth ) )
	CheckNMVar( df+"ArtFitWin", abs( NumVarOrDefault( df+"DecayWin", k_ArtFitWin ) ) )
	CheckNMVar( df+"ArtPeakDT", k_ArtPeakDT )
	CheckNMStr( df+"ArtFitFxn", StrVarOrDefault( df+"DecayFxn", k_ArtFitFxn ) )
	
	CheckNMVar( df+"SubtractWin", abs( k_SubtractWin ) )
	
	CheckNMVar( df+"SaveFitParameters", k_SaveFitParameters )
	CheckNMVar( df+"SaveSubtractedArt", k_SaveSubtractedArt )
	
	CheckNMStr( df+"WaveNameFormat", k_WaveNameFormat )
	
	// channel display waves
	
	CheckNMWave( df+"AT_Display", 0, Nan )
	CheckNMWave( df+"AT_Fit", 0, Nan )
	CheckNMWave( df+"AT_FitB", 0, Nan )
	
	CheckNMWave( df+"AT_TimeX", 0, Nan )
	CheckNMWave( df+"AT_TimeY", 0, Nan )
	
	// see NMArtWavesCheck()
	
End // NMArtCheck

//****************************************************************

Function NMArtWavesCheck( [ forceMake, forceMakeFits ] )
	Variable forceMake, forceMakeFits
	
	//print GetRTStackInfo( 1 ), GetRTStackInfo( 2 )
	
	Variable count1, aflag, newWave = 0
	String wList, txt, prefixFolder, groupName
	String df = NMArtDF
	
	if ( !z_NMArtWaveSelectOK() )
		return -1
	endif
	
	Variable saveSubtractedArt = NMArtVarGet( "SaveSubtractedArt" )
	
	Variable currentChan = CurrentNMChannel()
	//Variable currentWave = CurrentNMWave()
	Variable currentGroup = NMGroupsNum( -1 )
	String currentWavePrefix = CurrentNMWavePrefix()
	String wName = CurrentNMWaveName()
	String dwName = ChanDisplayWave( -1 )
	
	String noArtName = NMArtSubWaveName( "no_art" )
	String artName = NMArtSubWaveName( "art" )
	String fwName = NMArtSubWaveName( "finished" )
	
	//wName = NMWaveSelected( currentChan, currentWave )
	//wList = NMWaveSelectList( -1 )
	String xList = NMSetsWaveList( "SetX", currentChan )
	
	Variable excludeThisWave = NMSetXType() && ( WhichListItem( wName, xList ) >= 0 )
	
	if ( excludeThisWave )
	
		if ( WaveExists( $noArtName ) || WaveExists( $artName ) || WaveExists( $fwName ) )
		
			txt = "NMArtWavesCheck: Art waves exist for " + NMQuotes( wName ) + ". "
			txt += "Do you want to delete them?"
		
			aflag = NMDoAlert( txt, title="NM Art Tab", alertType=2 )
			
			if ( aflag == 1 )
				KillWaves /Z $noArtName
				KillWaves /Z $artName
				KillWaves /Z $fwName
			endif
			
		endif
		
		return 0
		
	endif
	
	if ( WaveExists( $dwName ) )
	
		if ( forceMake || !WaveExists( $noArtName ) )
			Duplicate /O $dwname $noArtName
			newWave = 1
		endif
		
		if ( saveSubtractedArt && ( forceMake || !WaveExists( $artName ) ) )
			Duplicate /O $dwname $artName
			Wave wtemp = $artName
			wtemp = NaN
		endif
		
		if ( forceMakeFits || forceMake || !WaveExists( $df+"AT_Fit" ) )
			Duplicate /O $dwname $df+"AT_Fit"
			Wave wtemp = $df+"AT_Fit"
			wtemp = NaN
		endif
		
		if ( forceMakeFits || forceMake || !WaveExists( $df+"AT_FitB" ) )
			Duplicate /O $dwname $df+"AT_FitB"
			Wave wtemp = $df+"AT_FitB"
			wtemp = NaN
		endif
	
	endif
	
	count1 = z_NMArtWavesCheck_TimeXY( forceMake ) // check AT_TimeX and AT_TimeY
	
	z_NMArtWavesCheck_F( forceMake, count1 ) // check AT_F_ wave
	
	wList = WaveList( "AT_" + currentWavePrefix + "*", ";", "" )
	
	if ( ItemsInList( wList ) > 0 )
		NMPrefixAdd( "AT_" + currentWavePrefix )
	endif
	
	if ( newWave && WaveExists( $noArtName ) )
	
		prefixFolder = NMPrefixFolderDF( "", "AT_" + currentWavePrefix )
	
		if ( DataFolderExists( prefixFolder ) )
		
			groupName = NMGroupsName( currentGroup )
			
			if ( strlen( groupName ) > 0 )
				NMSetsWaveListAdd( noArtName, groupName, currentChan, prefixFolder=prefixFolder )
			endif
			
		endif
		
	endif
	
	return 0

End // NMArtWavesCheck

//****************************************************************

Static Function z_NMArtWavesCheck_TimeXY( forceMake )
	Variable forceMake

	Variable icnt, pnts, numArtefacts = 0, count2 = 0, ok = 0
	Variable pbgn, pend
	String wList, wName, xName, yName
	
	String df = NMArtDF
	
	String xWave = NMXwave()
	
	Variable artWidth = NMArtVarGet( "ArtWidth" )
	
	String waveNameOrSpikeSubfolder = NMArtStrGet( "ArtTimeWName" )
	
	Variable currentWave = CurrentNMWave()

	String dwName = ChanDisplayWave( -1 )

	if ( WaveExists( $waveNameOrSpikeSubfolder ) )
	
		wName = waveNameOrSpikeSubfolder
		
		Wave wtemp = $wName
		
		for ( icnt = 0 ; icnt < numpnts( wtemp ) ; icnt += 1 )
			if ( numtype( wtemp[ icnt ] ) == 0 )
				numArtefacts += 1
			endif
		endfor
		
		if ( WaveExists( $df+"AT_TimeX" ) )
			pnts = numpnts( $df+"AT_TimeX" )
		else
			pnts = 0
		endif
		
		if ( forceMake || ( pnts != numArtefacts ) )
		
			Make /O/N=( numArtefacts ) $df+"AT_TimeX" = NaN
			Make /O/N=( numArtefacts ) $df+"AT_TimeY" = NaN
			
			Wave twave = $df+"AT_TimeX"
			
			for ( icnt = 0 ; icnt < numpnts( wtemp ) ; icnt += 1 )
				if ( numtype( wtemp[ icnt ] ) == 0 )
					twave[ count2 ] = wtemp[ icnt ]
					count2 += 1
				endif
			endfor
		
		endif
		
		ok = WaveExists( $df+"AT_TimeX" ) && ( numpnts( $df+"AT_TimeX" ) == numArtefacts )
		
	elseif ( ( strlen( waveNameOrSpikeSubfolder ) > 0 ) && DataFolderExists( waveNameOrSpikeSubfolder ) )
	
		wList = NMSpikeSubfolderRasterList( waveNameOrSpikeSubfolder, 1, 1 )
		
		if ( ItemsInList( wList ) == 2 )
		
			xName = StringFromList( 0, wList )
			yName = StringFromList( 1, wList )
		
			if ( numpnts( $xName ) == numpnts( $yName ) )
		
				Wave wtemp = $xName
				Wave ytemp = $yName
		
				for ( icnt = 0 ; icnt < numpnts( wtemp ) ; icnt += 1 )
					if ( ( numtype( wtemp[ icnt ] ) == 0 ) && ( ytemp[ icnt ] == currentWave ) )
						numArtefacts += 1
					endif
				endfor
				
				if ( WaveExists( $df+"AT_TimeX" ) )
					pnts = numpnts( $df+"AT_TimeX" )
				else
					pnts = 0
				endif
		
				if ( forceMake || ( pnts != numArtefacts) )
				
					Make /O/N=( numArtefacts ) $df+"AT_TimeX" = NaN
					Make /O/N=( numArtefacts ) $df+"AT_TimeY" = NaN
					
					Wave twave = $df+"AT_TimeX"
					
					for ( icnt = 0 ; icnt < numpnts( wtemp ) ; icnt += 1 )
						if ( ( numtype( wtemp[ icnt ] ) == 0 ) && ( ytemp[ icnt ] == currentWave ) )
							twave[ count2 ] = wtemp[ icnt ]
							count2 += 1
						endif
					endfor
				
				endif
				
			endif
			
		endif
		
		ok = WaveExists( $df+"AT_TimeX" ) && ( numpnts( $df+"AT_TimeX" ) == numArtefacts )
		
	endif
	
	if ( ok ) // set y-values for AT_TimeY
			
		Wave twave = $df+"AT_TimeX"
		Wave ywave = $df+"AT_TimeY"
		
		for ( icnt = 0; icnt < numpnts( twave ); icnt += 1 )
		
			if ( numtype( ywave[ icnt ] ) == 0 )
				continue
			endif
			
			pbgn = z_NMX2Pnt( dwName, xWave, twave[ icnt ] - 2 * artWidth )
			pend = z_NMX2Pnt( dwName, xWave, twave[ icnt ] - 1 * artWidth )
			
			WaveStats /Q/R=[ pbgn, pend ] $dwName
			
			ywave[ icnt ] = V_avg
			
		endfor

	else
	
		Make /O/N=0 $df+"AT_TimeX"
		Make /O/N=0 $df+"AT_TimeY"
		
	endif
	
	return numArtefacts
	
End // z_NMArtWavesCheck_TimeXY

//****************************************************************

Static Function z_NMX2Pnt( yWave, xWave, xValue )
	String yWave, xWave
	Variable xValue
	
	if ( !WaveExists( $yWave ) )
		return NaN
	endif
	
	if ( WaveExists( $xWave ) )
		return NMX2Pnt( xWave, xValue )
	else
		return x2pnt( $yWave, xValue )
	endif
	
End // z_NMX2Pnt

//****************************************************************

Static Function z_NMArtWavesCheck_F( forceMake, numArtefacts)
	Variable forceMake
	Variable numArtefacts
	
	Variable icnt, jcnt
	String df = NMArtDF
	
	Variable saveFitParameters = NMArtVarGet( "SaveFitParameters" )
	
	String fwName = NMArtSubWaveName( "finished" )
	
	if ( ( numtype( numArtefacts ) > 0 ) || ( numArtefacts <= 0 ) )
		return NaN
	endif
	
	if ( forceMake || !WaveExists( $fwName ) || ( ( numArtefacts > 0 ) && ( DimSize( $fwName, 0 ) != numArtefacts ) ) )
	
		if ( saveFitParameters )
			Make /O/N=( numArtefacts, 12 ) $fwName = NaN
		else
			Make /O/N=( numArtefacts, 6 ) $fwName = NaN
		endif
			
	endif
	
	if ( DimSize( $fwName, 1 ) == 2 ) // old format
	
		Duplicate /O $fwName $df+"F_Save"
		Wave f_old = $df+"F_Save"
	
		if ( saveFitParameters )
			Make /O/N=( numArtefacts, 12 ) $fwName = NaN
		else
			Make /O/N=( numArtefacts, 6 ) $fwName = NaN
		endif
		
		Wave ftemp = $fwName
		
		for ( icnt = 0; icnt < numArtefacts; icnt += 1 )
			ftemp[ icnt ][ 0 ] = f_old[ icnt ][ 0 ]
			ftemp[ icnt ][ 1 ] = f_old[ icnt ][ 1 ]
		endfor
	
	endif
	
	if ( DimSize( $fwName, 1 ) == 8 ) // old format
	
		Duplicate /O $fwName $df+"F_Save"
		Wave f_old = $df+"F_Save"
	
		Make /O/N=( numArtefacts, 12 ) $fwName = NaN
		
		Wave ftemp = $fwName
		
		for ( icnt = 0; icnt < numArtefacts; icnt += 1 )
		
			ftemp[ icnt ][ 0 ] = f_old[ icnt ][ 0 ]
			ftemp[ icnt ][ 1 ] = f_old[ icnt ][ 1 ]
			
			ftemp[ icnt ][ 4 ] = f_old[ icnt ][ 2 ]
			ftemp[ icnt ][ 5 ] = f_old[ icnt ][ 3 ]
			ftemp[ icnt ][ 6 ] = f_old[ icnt ][ 4 ]
			
			ftemp[ icnt ][ 9 ] = f_old[ icnt ][ 5 ]
			ftemp[ icnt ][ 10 ] = f_old[ icnt ][ 6 ]
			ftemp[ icnt ][ 11 ] = f_old[ icnt ][ 7 ]
			
		endfor
	
	endif
	
	Wave ftemp = $fwName
	
	//SetDimLabel 0, -1, artN, ftemp
	
	SetDimLabel 1, 0, onset, ftemp
	SetDimLabel 1, 1, finished, ftemp
	
	if ( DimSize( ftemp, 1 ) == 6 )
		
		SetDimLabel 1, 2, b_bgn, ftemp
		SetDimLabel 1, 3, b_end, ftemp
		SetDimLabel 1, 4, a_bgn, ftemp
		SetDimLabel 1, 5, a_end, ftemp
		
	elseif ( DimSize( ftemp, 1 ) == 12 )
		
		SetDimLabel 1, 2, b_bgn, ftemp
		SetDimLabel 1, 3, b_end, ftemp
		SetDimLabel 1, 4, b_k1, ftemp
		SetDimLabel 1, 5, b_k2, ftemp
		SetDimLabel 1, 6, b_chi, ftemp
		
		SetDimLabel 1, 7, a_bgn, ftemp
		SetDimLabel 1, 8, a_end, ftemp
		SetDimLabel 1, 9, a_k1, ftemp
		SetDimLabel 1, 10, a_k2, ftemp
		SetDimLabel 1, 11, a_chi, ftemp
		
	else
	
		return NaN
		
	endif
	
	return 0
	
End // z_NMArtWavesCheck_F

//****************************************************************

Function NMArtConfigs()
	
	NMConfigStr( "Art", "ArtShape", k_ArtShape, "artefact end polarity, Pos-Neg or Neg-Pos", "PN;NP;" )
	NMConfigVar( "Art", "ArtWidth", abs( k_ArtWidth ), "approx artefact width", "" )
	NMConfigVar( "Art", "ArtPeakDT", k_ArtPeakDT, "artefact peak detection offset for fit to artefact decay", "" )
	
	NMConfigVar( "Art", "BslnSubtract", 0, "subtract baseline: 0-no, 1-yes", "boolean" )
	NMConfigVar( "Art", "BslnConvergeNstdv", abs( k_BslnConvergeNstdv ), "steady-state convergence test between baseline and artefact fit, number of data stdv", "" )
	NMConfigVar( "Art", "BslnConvergeWin", abs( k_BslnConvergeWin ), "length of steady-state convergence test window", "" )
	NMConfigVar( "Art", "BslnExpSlopeThreshold", k_BslnExpSlopeThreshold, "slope threshold for baseline exp fit", "" )
	
	NMConfigVar( "Art", "SaveFitParameters", k_SaveFitParameters, "Save baseline and artefact fit parameters", "boolean" )
	NMConfigVar( "Art", "SaveSubtractedArt", k_SaveSubtractedArt, "Save subtracted artefacts to AT_A_ wave", "boolean" )
	
	NMConfigStr( "Art", "WaveNameFormat", k_WaveNameFormat, "output wave name format", "v2;v3p;" )

	NMConfigVar( "Art", "t1_hold", NaN, "fit hold value of t1", "" )
	NMConfigVar( "Art", "t1_min", NaN, "t1 min value", "" )
	NMConfigVar( "Art", "t1_max", NaN, "t1 max value", "" )
	NMConfigVar( "Art", "t2_hold", NaN, "fit hold value of t2", "" )
	NMConfigVar( "Art", "t2_min", NaN, "t2 min value", "" )
	NMConfigVar( "Art", "t2_max", NaN, "t2 max value", "" )
	
	NMConfigStr( "Art", "BaseColor", NMGreenStr, "baseline display color", "RGB" )
	NMConfigStr( "Art", "DecayColor", NMRedStr, "decay display color", "RGB" )
	
	NMConfigVar( "Art", "DisplayPrecision", 2, "decimal numbers to display", "" )
	
End // NMArtConfigs

//****************************************************************

Function NMArtVarGet( varName )
	String varName
	
	Variable defaultVal = NaN
	
	strswitch( varName )
	
		case "ArtNum":
			defaultVal = 0
			break
	
		case "ArtWidth":
			defaultVal = abs( k_ArtWidth )
			break
			
		case "ArtFitWin":
			defaultVal = abs( k_ArtFitWin )
			break
			
		case "ArtPeakDT":
			defaultVal = k_ArtPeakDT
			break
			
		case "SubtractWin":
			defaultVal = abs( k_SubtractWin )
			break
			
		case "BslnWin":
			defaultVal = abs( k_BslnWin )
			break
			
		case "BslnDT":
			defaultVal = abs( k_BslnDT )
			break
			
		case "BslnSubtract":
			defaultVal = 0
			break
			
		case "BslnConvergeNstdv":
			defaultVal = abs( k_BslnConvergeNstdv )
			break
			
		case "BslnConvergeWin":
			defaultVal = abs( k_BslnConvergeWin )
			break
			
		case "BslnExpSlopeThreshold":
			defaultVal = k_BslnExpSlopeThreshold
			break
			
		case "SaveFitParameters":
			defaultVal = k_SaveFitParameters
			break
			
		case "SaveSubtractedArt":
			defaultVal = k_SaveSubtractedArt
			break
			
		case "AutoFit":
			defaultVal = 1
			break
			
		case "DragWaveAll":
			defaultVal = k_DragWaveAll
			break
			
		case "FitFlag":
			defaultVal = NaN
			break
	
		case "ArtTime":
		case "t1_hold":
		case "t1_min":
		case "t1_max":
		case "t2_hold":
		case "t2_min":
		case "t2_max":
			break // NaN
			
		case "DisplayPrecision":
			defaultVal = 2 // decimal places
			break
			
		default:
			NM2Error( 13, varName, "" )
			return NaN
	
	endswitch
	
	return NumVarOrDefault( NMArtDF+varName, defaultVal )
	
End // NMArtVarGet

//****************************************************************

Function /S NMArtStrGet( varName )
	String varName
	
	String defaultVal = ""
	
	strswitch( varName )
	
		case "ArtShape":
			defaultVal = k_ArtShape
			break
	
		case "BslnFxn":
			defaultVal = k_BslnFxn
			break
	
		case "ArtFitFxn":
			defaultVal = k_ArtFitFxn
			break
			
		case "DecayColor":
			defaultVal = NMRedStr
			break
			
		case "BaseColor":
			defaultVal = NMGreenStr
			break
			
		case "ArtTimeWName":
			break
			
		case "WaveNameFormat":
			defaultVal = k_WaveNameFormat
			break
			
		default:
			NM2Error( 23, varName, "" )
			return ""
	
	endswitch
	
	return StrVarOrDefault( NMArtDF+varName, defaultVal )
	
End // NMArtStrGet

//****************************************************************

Function /S NMArtSubWaveName( wtype [ wName ] )
	String wtype
	String wName
	
	if ( ParamIsDefault( wName ) )
		wName = CurrentNMWaveName()
	endif
	
	if ( strlen( wName ) == 0 )
		return ""
	endif
	
	if ( StringMatch( wtype, "finished" ) )
		return "AT_F_" + wName
	endif
	
	String format = NMArtStrGet( "WaveNameFormat" )
	
	strswitch( format )
	
		case "v2": // old format
		
			strswitch( wtype )
				case "art":
					return "AT_" + wName + "_stim"
				case "no_art":
					return "AT_" + wName + "_nostim"
			endswitch
			
			return ""
		
		case "v3p":
		default:
		
			strswitch( wtype )
				case "art":
					return "AT_A_" + wName
				case "no_art":
					return "AT_" + wName
			endswitch
			
			return ""
	
	endswitch

End // NMArtSubWaveName

//****************************************************************

Function NMArtDisplay( appnd ) // append/remove Art display waves to current channel graph
	Variable appnd // // ( 0 ) remove ( 1 ) append
	
	Variable icnt, drag = appnd

	String gName = CurrentChanGraphName()
	String xWave = NMXwave()
	
	String df = NMArtDF
	
	STRUCT NMRGB ac
	STRUCT NMRGB bc
	
	NMColorList2RGB( NMArtStrGet( "DecayColor" ), ac )
	NMColorList2RGB( NMArtStrGet( "BaseColor" ), bc )
	
	if ( !DataFolderExists( df ) || !WaveExists( $df+"AT_Display" ) )
		return 0 // Art has not been initialized yet
	endif
	
	if ( Wintype( gName ) == 0 )
		return -1 // window does not exist
	endif
	
	String wName = df+"AT_Display"
	
	if ( !NMVarGet( "DragOn" ) || !StringMatch( CurrentNMTabName(), "Art" ) )
		drag = 0
	endif
	
	RemoveFromGraph /Z/W=$gName AT_Display, AT_Fit, AT_FitB, AT_TimeY
	RemoveFromGraph /Z/W=$gName DragBgnY, DragEndY
	RemoveFromGraph /Z/W=$gName DragBslnBgnY, DragBslnEndY
	
	if ( appnd )
	
		if ( WaveExists( $xWave ) )
			AppendToGraph /W=$gName $df+"AT_Display" vs $xWave
		else
			AppendToGraph /W=$gName $df+"AT_Display"
		endif
		
		if ( WaveExists( $df+"AT_FitB" ) )
			if ( WaveExists( $xWave ) )
				AppendToGraph /W=$gName $df+"AT_FitB" vs $xWave
			else
				AppendToGraph /W=$gName $df+"AT_FitB"
			endif
		endif
		
		if ( WaveExists( $df+"AT_Fit" ) )
			if ( WaveExists( $xWave ) )
				AppendToGraph /W=$gName $df+"AT_Fit" vs $xWave
			else
				AppendToGraph /W=$gName $df+"AT_Fit"
			endif
		endif
		
		if ( WaveExists( $df+"AT_TimeY" ) && WaveExists( $df+"AT_TimeX" ) )
			AppendToGraph /W=$gName $df+"AT_TimeY" vs $df+"AT_TimeX"
		endif
		
		ModifyGraph /W=$gName rgb( AT_Display )=( 0,0,65280 ), lsize( AT_Display )=2
		
		ModifyGraph /W=$gName mode( AT_TimeY )=3, marker( AT_TimeY )=10, rgb( AT_TimeY )=( 65280,0,0 ), msize( AT_TimeY )=20, mrkThick( AT_TimeY )=2
		ModifyGraph /W=$gName mode( AT_FitB )=0, lsize( AT_FitB )=2, rgb( AT_FitB )=( bc.r, bc.g, bc.b )
		
	endif
	
	NMDragEnable( drag, "DragBgn", "", df+"Xbgn", "NMArtDragTrigger", gName, "bottom", "min", ac.r, ac.g, ac.b )
	NMDragEnable( drag, "DragEnd", "", df+"Xend", "NMArtDragTrigger", gName, "bottom", "max", ac.r, ac.g, ac.b )
	NMDragEnable( drag, "DragBslnBgn", "", df+"BslnXbgn", "NMArtDragTrigger", gName, "bottom", "min", bc.r, bc.g, bc.b )
	NMDragEnable( drag, "DragBslnEnd", "", df+"BslnXend", "NMArtDragTrigger", gName, "bottom", "max", bc.r, bc.g, bc.b )
	
End // NMArtDisplay

//****************************************************************

Function NMArtChanGraphControls( enable )
	Variable enable
	
	Variable ccnt, displayWin, lim1, lim2, inc, y0 = 8
	
	Variable currentChan = CurrentNMChannel()
	
	String gName, title
	
	String computer = NMComputerType()
	
	if ( StringMatch( computer, "mac" ) )
		y0 = 4
	endif
	
	for ( ccnt = 0; ccnt < 10; ccnt += 1 ) // remove from all possible channel graphs
	
		if ( enable && ( ccnt == currentChan ) )
			continue
		endif
	
		gName = ChanGraphName( ccnt )
	
		if ( Wintype( gName ) == 0 )
			continue
		endif
		
		KillControl /W=$gName AT_dragWaveAll
		
	endfor
	
	if ( enable )
	
		gName = ChanGraphName( currentChan )
		
		if ( Wintype( gName ) != 1 )
			return NaN
		endif
		
		if ( NMArtVarGet( "DragWaveAll" ) )
			title = "Drag (all artefacts)"
		else
			title = "Drag (current artefact)"
		endif
		
		Checkbox AT_dragWaveAll, title=title, pos={500, y0}, size={100,50}, value=1, proc=NMArtCheckbox, win=$gName
		
	endif
	
End // NMArtChanGraphControls

//****************************************************************

Static Function z_UpdateDragWaveAllCheckbox()

	Variable currentChan = CurrentNMChannel()

	String gName = ChanGraphName( currentChan )
	
	if ( NMArtVarGet( "DragWaveAll" ) )
		Checkbox AT_dragWaveAll, title="Drag (all artefacts)", value=1, win=$gName
	else
		Checkbox AT_dragWaveAll, title="Drag (current artefact)", value=1, win=$gName
	endif
	
End // z_UpdateDragWaveAllCheckbox

//****************************************************************

Function NMArtDragTrigger( offsetStr )
	String offsetStr
	
	Variable t0, t1, tbgn, tend, win, dt, tpeak
	String wname, df = NMArtDF
	
	Variable artNum = NMArtVarGet( "ArtNum" )
	Variable artTime = NMArtVarGet( "ArtTime" )
	Variable autoFit = NMArtVarGet( "AutoFit" )
	
	Variable rflag = NMDragTrigger( offsetStr, callAutoTab = 0 )
	
	if ( rflag < 0 )
		return -1
	endif
	
	String fwName = NMArtSubWaveName( "finished" )
	
	if ( !WaveExists( $fwName ) )
		return -1
	endif
	
	if ( ( numtype( artNum ) != 0 ) || ( artNum < 0 ) || ( artNum >= DimSize( $fwName, 0 ) ) )
		return -1
	endif
	
	wname = StringByKey( "TNAME", offsetStr )
	
	strswitch( wname )
	
		case "DragBgnY":
		case "DragEndY":
		
			Wave ftemp = $fwName
		
			t0 = NumVarOrDefault( df+"Xbgn", NaN )
			t1 = NumVarOrDefault( df+"Xend", NaN )
			
			if ( numtype( t0 * t1 ) > 0 )
				return -1
			endif
			
			tbgn = min( t0, t1 )
			tend = max( t0, t1 )
			
			tpeak = z_ArtPeakT( artNum )
			
			tbgn = max( tbgn, tpeak )
		
			if ( NMArtVarGet( "DragWaveAll" ) )
				
				win = tend - tbgn
				dt = tbgn - tpeak
				
			 	SetNMvar( df+"ArtFitWin", win )
			 	//SetNMvar( df+"ArtPeakDT", dt )
			 	NMConfigVarSet( "Art", "ArtPeakDT", dt, history=0 )
			 	
			 	NMArtNumSet( artNum, recomputeWindows=1 )
			 	
			 else
			 
			 	z_F_WinSet( artNum, a_bgn=tbgn, a_end=tend )
				
				NMArtNumSet( artNum, recomputeWindows=0 )
			 
			 endif

			break
	
		case "DragBslnBgnY":
		case "DragBslnEndY":
		
			t0 = NumVarOrDefault( df+"BslnXbgn", NaN )
			t1 = NumVarOrDefault( df+"BslnXend", NaN )
			
			if ( numtype( t0 * t1 ) > 0 )
				return -1
			endif
			
			tbgn = min( t0, t1 )
			tend = max( t0, t1 )
			
			tend = min( tend, artTime )
			
			if ( NMArtVarGet( "DragWaveAll" ) )
				
				win = tend - tbgn
				dt = abs( artTime - tend )
		
				SetNMvar( df+"BslnWin", win )
				SetNMvar( df+"BslnDT", dt )
				
				NMArtNumSet( artNum, recomputeWindows=1 )
					
			else
				
				z_F_WinSet( artNum, b_bgn=tbgn, b_end=tend )
				
				NMArtNumSet( artNum, recomputeWindows=0 )
					
			endif
			
			break
			
		default:
			return -1
	
	endswitch
	
	if ( autoFit )
		NMArtFit( checkWaves=0, update=0 ) // no update, otherwise "UpdtDisplay: recursion attempted"
	endif
	
	return 0
	
End // NMArtDragTrigger

//****************************************************************

Function NMArtDragUpdate()

	String df = NMArtDF
	
	Variable drag = NMVarGet( "DragOn" )
	
	if ( drag )
		NMDragUpdate( "DragBgn" )
		NMDragUpdate( "DragEnd" )
	else
		NMDragClear( "DragBgn" )
		NMDragClear( "DragEnd" )
	endif
	
	if ( drag )
		NMDragUpdate( "DragBslnBgn" )
		NMDragUpdate( "DragBslnEnd" )
	else
		NMDragClear( "DragBslnBgn" )
		NMDragClear( "DragBslnEnd" )
	endif

End // NMArtDragUpdate

//****************************************************************

Function NMArtDragClear()
	
	NMDragClear( "DragBgn" )
	NMDragClear( "DragEnd" )
	NMDragClear( "DragBslnBgn" )
	NMDragClear( "DragBslnEnd" )
	
End // NMArtDragClear

//****************************************************************

Function NMArtMake( force ) // create Art tab controls
	Variable force
	
	Variable x0, y0, xinc, yinc

	String df = NMArtDF
	
	ControlInfo /W=NMPanel AT_BaseGrp
	
	if ( ( V_Flag != 0 ) && ( force == 0 ) )
		return 0 // Art tab has already been created, return here
	endif
	
	if ( !DataFolderExists( df ) )
		return 0 // Art tab has not been initialized yet
	endif
	
	DoWindow /F NMPanel
	
	x0 = 40
	y0 = NMPanelTabY + 60
	xinc = 125
	yinc = 35
	
	GroupBox AT_BaseGrp, title = "Pre-artefact Baseline Fit", pos={x0-20,y0-25}, size={260,90}
	
	PopupMenu AT_BslnFxn, pos={x0+10,y0}, bodywidth=60
	PopupMenu AT_BslnFxn, value="", proc=NMArtPopup
	
	SetVariable AT_BslnVal1, title="a :", pos={x0+80,y0+2}, size={70,50}, fsize = 12
	SetVariable AT_BslnVal1, value=$df+"BslnValue1", limits={-inf,inf,0}, frame=0
	
	SetVariable AT_BslnVal2, title="t :", pos={x0+155,y0+2}, size={70,50}, fsize = 12
	SetVariable AT_BslnVal2, value=$df+"BslnValue2", limits={-inf,inf,0}, frame=0
	
	SetVariable AT_BslnDT, title="-dt:", pos={x0,y0+yinc}, size={100,50}, fsize = 12
	SetVariable AT_BslnDT, value=$df+"BslnDT", proc=NMArtSetVar
	
	SetVariable AT_BslnWin, title="win:", pos={x0+xinc,y0+yinc}, size={100,50}, fsize = 12
	SetVariable AT_BslnWin, value=$df+"BslnWin", proc=NMArtSetVar
	
	y0 += 100
	
	GroupBox AT_FitGrp, title = "Artefact Tail Fit", pos={x0-20,y0-25}, size={260,90}
	
	PopupMenu AT_FitFxn, pos={x0+10,y0}, bodywidth=60
	PopupMenu AT_FitFxn, value="", proc=NMArtPopup
	
	SetVariable AT_FitVal1, title="a :", pos={x0+80,y0+2}, size={70,50}, fsize = 12
	SetVariable AT_FitVal1, value=$df+"DcayValue1", limits={-inf,inf,0}, frame=0, proc=NMArtSetVar
	
	SetVariable AT_FitVal2, title="t :", pos={x0+155,y0+2}, size={70,50}, fsize = 12
	SetVariable AT_FitVal2, value=$df+"DcayValue2", limits={-inf,inf,0}, frame=0, proc=NMArtSetVar
	
	SetVariable AT_FitWin, title="fit win:", pos={x0,y0+yinc}, size={100,50}, fsize = 12
	SetVariable AT_FitWin, value=$df+"ArtFitWin", proc=NMArtSetVar
	
	SetVariable AT_SubWin, title="sub win:", pos={x0+xinc-10,y0+yinc}, size={110,50}, fsize = 12
	SetVariable AT_SubWin, value=$df+"SubtractWin", proc=NMArtSetVar
	
	y0 += 100
	
	GroupBox AT_TimeGrp, title = "Artefact Onset Times", pos={x0-20,y0-25}, size={260,115}
	
	PopupMenu AT_TimeWave, pos={x0+140,y0}, bodywidth=190, proc=NMArtPopup
	PopupMenu AT_TimeWave, value=""
	
	SetVariable AT_NumArtefacts, title=":", pos={x0+195,y0}, size={40,50}, limits={0,inf,0}
	SetVariable AT_NumArtefacts, value=$df+"NumArtefacts", fsize=12, frame=0, noedit=1
	
	SetVariable AT_ArtNum, title=" ", pos={x0+90,y0+1*yinc}, size={50,50}, limits={0,inf,0}
	SetVariable AT_ArtNum, value=$df+"ArtNum", fsize = 12, proc=NMArtSetVar
	
	Button AT_FirstArt, pos={x0+90-80,y0+1*yinc}, title = "<<", size={30,20}, proc=NMArtButton
	Button AT_PrevArt, pos={x0+90-40,y0+1*yinc}, title = "<", size={30,20}, proc=NMArtButton
	Button AT_NextArt, pos={x0+150,y0+1*yinc}, title = ">", size={30,20}, proc=NMArtButton
	Button AT_LastArt, pos={x0+150+40,y0+1*yinc}, title = ">>", size={30,20}, proc=NMArtButton
	
	SetVariable AT_ArtTime, title="t :", pos={x0+50,y0+2*yinc-8}, size={70,50}, fsize = 12
	SetVariable AT_ArtTime, value=$df+"ArtTime", frame=0, limits={-inf,inf,0}, noedit=1
	
	Checkbox AT_Subtract, title="subtract", pos={x0+50+80,y0+2*yinc-6}, size={100,50}, value=1, fsize = 12, proc=NMArtCheckbox
	
	y0 += 105
	x0 -= 5
	xinc = 80
	
	Button AT_Reset, pos={x0,y0}, title = "Reset", size={70,20}, proc=NMArtButton
	Button AT_Fit, pos={x0+1*xinc,y0}, title = "Fit", size={70,20}, proc=NMArtButton
	Button AT_FitAll, pos={x0+2*xinc,y0}, title = "Fit All", size={70,20}, proc=NMArtButton
	Button AT_FitTable, pos={x0+40,y0+yinc}, title = "Table", size={70,20}, proc=NMArtButton
	Button AT_FitGraph, pos={x0+1*xinc+40,y0+yinc}, title = "Graph", size={70,20}, proc=NMArtButton
	
	Checkbox AT_AutoFit, title="auto fit", pos={x0+1*xinc+75,y0+2*yinc}, size={100,50}, value=1, fsize = 12, proc=NMArtCheckbox
	
End // NMArtMake

//****************************************************************

Function NMArtUpdate()

	Variable md, dt, lx, rx, icnt
	String wList, df = NMArtDF
	
	String xWave = NMXwave()

	String dName = ChanDisplayWave( -1 )
	
	String bslnFxn = NMArtStrGet( "BslnFxn" )
	String exp_fxn = NMArtStrGet( "ArtFitFxn" )
	String twName = NMArtStrGet( "ArtTimeWName" )
	
	Variable autoFit = NMArtVarGet( "AutoFit" )
	Variable t1_hold = NMArtVarGet( "t1_hold" )
	Variable t2_hold = NMArtVarGet( "t2_hold" )
	
	String formatStr = z_PrecisionStr()
	
	md = WhichListItem( bslnFxn, k_ArtBslnFxnList ) + 1
	PopupMenu AT_BslnFxn, win=NMPanel, value =k_ArtBslnFxnList, mode=md
	
	strswitch( bslnFxn )
		case "Avg":
			SetVariable AT_BslnVal1, win=NMPanel, title="a :", format = z_PrecisionStr()
			SetVariable AT_BslnVal2, win=NMPanel, title=" ", disable = 1, format = z_PrecisionStr()
			break
		case "Line":
			SetVariable AT_BslnVal1, win=NMPanel, title="b :", format = z_PrecisionStr()
			SetVariable AT_BslnVal2, win=NMPanel, title="m :", disable = 0, format = z_PrecisionStr()
			break
		case "Exp":
			SetVariable AT_BslnVal1, win=NMPanel, title="a :", format = z_PrecisionStr()
			SetVariable AT_BslnVal2, win=NMPanel, title="t :", disable = 0, format = z_PrecisionStr()
			break
		case "2Exp":
			SetVariable AT_BslnVal1, win=NMPanel, title="t1 :", format = z_PrecisionStr()
			SetVariable AT_BslnVal2, win=NMPanel, title="t2 :", disable = 0, format = z_PrecisionStr()
			break
		case "Zero":
			SetVariable AT_BslnVal1, win=NMPanel, title="a :", format = z_PrecisionStr()
			SetVariable AT_BslnVal2, win=NMPanel, title="t :", disable = 1, format = z_PrecisionStr()
			break
	endswitch
	
	SetVariable AT_BslnDT, win=NMPanel, format = z_PrecisionStr()
	SetVariable AT_BslnWin, win=NMPanel, format = z_PrecisionStr()
	
	md = WhichListItem( exp_fxn, k_ArtFitFxnList ) + 1
	PopupMenu AT_FitFxn, win=NMPanel, value=k_ArtFitFxnList, mode=md
	
	SetVariable AT_FitVal1, win=NMPanel, format = z_PrecisionStr()
	SetVariable AT_FitVal2, win=NMPanel, format = z_PrecisionStr()
	
	strswitch( exp_fxn )
	
		case "Exp":
		
			SetVariable AT_FitVal1, win=NMPanel, title="a :"
			
			if ( ( numtype( t1_hold ) == 0 ) && ( t1_hold > 0 ) )
				SetVariable AT_FitVal2, win=NMPanel, title="t :", valueColor=(65535,0,0)
			else
				SetVariable AT_FitVal2, win=NMPanel, title="t :", valueColor=(0,0,0)
			endif
			
			break
			
		case "2Exp":
		
			if ( ( numtype( t1_hold ) == 0 ) && ( t1_hold > 0 ) )
				SetVariable AT_FitVal1, win=NMPanel, title="t1 :", valueColor=(65535,0,0)
			else
				SetVariable AT_FitVal1, win=NMPanel, title="t1 :", valueColor=(0,0,0)
			endif
			
			if ( ( numtype( t2_hold ) == 0 ) && ( t2_hold > 0 ) )
				SetVariable AT_FitVal2, win=NMPanel, title="t2 :", valueColor=(65535,0,0)
			else
				SetVariable AT_FitVal2, win=NMPanel, title="t2 :", valueColor=(0,0,0)
			endif
			
			break
			
	endswitch
	
	SetVariable AT_FitWin, win=NMPanel, format = z_PrecisionStr()
	SetVariable AT_SubWin, win=NMPanel, format = z_PrecisionStr()
	
	wList = NMArtTimeWaveList()
	
	md = 1
	
	if ( ( strlen( twName ) > 0 ) && ( WaveExists( $twName ) || DataFolderExists(twName ) ) )
	
		icnt = WhichListItem( twName, wList )
		
		if ( icnt >= 0 )
			md = icnt + 3
		endif
		
	endif
	
	PopupMenu AT_TimeWave, win=NMPanel, value="Select Wave of Artefact Times;---;" + NMArtTimeWaveList() + "---;Compute;Other...;", mode=md
	
	if ( WaveExists( $dName ) )
	
		if ( WaveExists( $xWave ) )
		
			Wave xtemp = $xWave
			
			dt = xtemp[ 1 ] - xtemp[ 0 ]
		
		else
		
			dt = deltax( $dName )
			
		endif
	
		lx = NMLeftX( dName, xWave=xWave )
		rx = NMRightX( dName, xWave=xWave )
		
		SetVariable AT_BslnDT, win=NMPanel, limits={0,inf,dt}
		SetVariable AT_BslnWin, win=NMPanel, limits={0,inf,dt}
		SetVariable AT_FitWin, win=NMPanel, limits={0,inf,dt}
		SetVariable AT_SubWin, win=NMPanel, limits={0,inf,dt}
		
	endif
	
	SetVariable AT_ArtTime, win=NMPanel, format = z_PrecisionStr()
	
	Checkbox AT_AutoFit, win=NMPanel, value=autoFit
	
	z_NumArtCount()
	z_UpdateCheckboxSubtract( -1 )
	z_UpdateDragWaveAllCheckbox()

End // NMArtUpdate

//****************************************************************

Static Function /S z_PrecisionStr()

	Variable precision = NMArtVarGet( "DisplayPrecision" )
	
	precision = max( precision, 1 )
	precision = min( precision, 5 )

	return "%." + num2istr( precision ) + "f"

End // z_PrecisionStr

//****************************************************************

Static Function z_UpdateCheckboxSubtract( artNum )
	Variable artNum
	
	if ( z_ArtFinished( artNum ) )
		Checkbox AT_Subtract, win=NMPanel, title="subtracted", disable=0, value=1
	elseif ( NMArtVarGet( "FitFlag" ) == 2 )
		Checkbox AT_Subtract, win=NMPanel, title="subtract", disable=0, value=0
	else
		Checkbox AT_Subtract, win=NMPanel, title="subtract", disable=2, value=0
	endif
	
End // z_UpdateCheckboxSubtract

//****************************************************************

Static function z_ArtFinished( artNum )
	Variable artNum

	String fwName = NMArtSubWaveName( "finished" )

	if ( !WaveExists( $fwName ) || ( DimSize( $fwName, 0 ) == 0 ) )
		return 0
	endif
	
	if ( artNum < 0 )
		artNum = NMArtVarGet( "ArtNum" )
	endif
	
	if ( ( artNum >= 0 ) && ( artNum < DimSize( $fwName, 0 ) ) )
		
		Wave ftemp = $fwName
		
		return ( ftemp[ artNum ][ %finished ] == 1 )
		
	endif
	
	return 0

End // z_ArtFinished

//****************************************************************

Function /S NMArtTimeWaveList()

	String currentWavePrefix = CurrentNMWavePrefix()
	String spikeSubfolderList = NMSubfolderList2( "", "Spike_" + currentWavePrefix, 0, 0 )
	String waveNameOrSpikeSubfolder = NMArtStrGet( "ArtTimeWName" )

	String wList = WaveList( "xAT_" + currentWavePrefix + "*",";","" )
	
	if ( WhichListItem( waveNameOrSpikeSubfolder, spikeSubfolderList ) < 0 )
		if ( WaveExists( $waveNameOrSpikeSubfolder ) && ( FindListItem( waveNameOrSpikeSubfolder, wList ) < 0 ) )
			wList = waveNameOrSpikeSubfolder + ";" + wList
		endif
	endif
	
	if ( ItemsInList( spikeSubfolderList ) > 0 )
	
		if ( ItemsInList( wList ) > 0 )
			wList += "---;"
		endif
		
		wList += spikeSubfolderList
		
	endif
	
	return wList

End // NMArtTimeWaveList

//****************************************************************

Static Function /S z_NMArtTimeWavePrompt()

	String wSelect = " "
	
	String currentFolder = CurrentNMFolder( 0 )
	String currentWavePrefix = CurrentNMWavePrefix()
	
	String wList = WaveList( "*", ";", "Text:0" )
	String cList = WaveList( currentWavePrefix + "*",";","" )
	String aList = WaveList( "AT_*",";","" )
	
	wList = RemoveFromList( cList, wList )
	wList = RemoveFromList( "FileScaleFactors;yLabel;", wList )
	wList = RemoveFromList( aList, wList )
	
	Prompt wSelect, "choose a wave of artefact onset times:", popup " ;" + wList
	DoPrompt "NM Art Tab", wSelect
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( WaveExists( $wSelect ) )
		return wSelect
	endif
	
	return ""

End // z_NMArtTimeWavePrompt

//****************************************************************

Function NMArtPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	Variable rflag, history = 1
	String rstr, df = NMArtDF
	
	strswitch( ctrlName )
	
		case "AT_TimeWave":
		
			strswitch( popStr )
			
				case "Select Wave of Artefact Times":
					popStr = "NONE"
					history = 0
					break
					
				case "---":
					popStr = ""
					break
					
				case "Compute":
					rstr = z_NMArtWaveOfArtTimesMakeCall()
					return 0 // skip Update
					
				case "Other...":
				
					popStr = z_NMArtTimeWavePrompt()
					
					if ( !WaveExists( $popStr ) )
						popStr = ""
					endif
					
			endswitch
			
			if ( strlen( popStr ) == 0 )
				NMArtUpdate()
				return 0
			endif
			
			if ( WaveExists( $popStr ) || DataFolderExists( popStr ) || StringMatch( popStr, "NONE" ) )
				return NMArtSet( waveOfArtTimes=popStr, history=history )	
			endif
			
			NMArtUpdate()
			
			break
			
		case "AT_BslnFxn":
			return NMArtSet( bslnFxn=popStr, history=1 )
			
		case "AT_FitFxn":
			return NMArtSet( artFitFxn=popStr, history=1 )
			
	endswitch
	
	return NaN
	
End // NMArtPopup

//****************************************************************

Function NMArtCheckbox( ctrlName, checked ) : CheckBoxControl
	String ctrlName; Variable checked
	
	strswitch( ctrlName )
	
		case "AT_Subtract":
			
			if ( z_ArtFinished( -1 ) )
				return NMArtCall( "Restore" )
			else
				return NMArtCall( "Subtract" )
			endif
			
		case "AT_AutoFit":
			return NMArtSet( autoFit=checked, history=1 )
			
		case "AT_dragWaveAll":
			return NMArtCall( "DragWaveAllToggle" )
			
	endswitch

End // NMArtCheckbox

//****************************************************************

Function NMArtSetVar( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	String artFitFxn = NMArtStrGet( "ArtFitFxn" )
	
	strswitch( ctrlName )
			
		case "AT_BslnDT":
			return NMArtSet( bslnDT=varNum, history=1 )
			
		case "AT_BslnWin":
			return NMArtSet( bslnWin=varNum, history=1 )
		
		case "AT_FitWin":
			return NMArtSet( artFitWin=varNum, history=1 )
			
		case "AT_SubWin":
			return NMArtSet( subtractWin=varNum, history=1 )
			
		case "AT_FitVal1":
			if ( StringMatch( artFitFxn, "2Exp" ) )
				return NMArtSet( t1_hold=varNum, history=1 )
			else
				return NaN // do nothing
			endif
			
		case "AT_FitVal2":
			if ( StringMatch( artFitFxn, "Exp" ) )
				return NMArtSet( t1_hold=varNum, history=1 )
			elseif ( StringMatch( artFitFxn, "2Exp" ) )
				return NMArtSet( t2_hold=varNum, history=1 )
			else
				return NaN // do nothing
			endif
		
		case "AT_ArtNum":
			return NMArtSet( artNum=varNum, history=1 )
			
	endswitch
	
End // NMArtSetVar

//****************************************************************

Function NMArtSet([ bslnWin, bslnDT, bslnFxn, artFitWin, artFitFxn, t1_hold, t2_hold, subtractWin, waveOfArtTimes, artNum, autoFit, dragWaveAll, update, alerts, history ])
	Variable bslnWin
	Variable bslnDT
	String bslnFxn
	
	Variable artFitWin
	String artFitFxn
	Variable t1_hold, t2_hold
	Variable subtractWin
	
	String waveOfArtTimes
	Variable artNum
	
	Variable autoFit
	Variable dragWaveAll
	
	Variable update // allow updates to NM panels and graphs
	Variable alerts // general alerts ( 0 ) none ( 1 ) yes
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable updateTab, updateBsln, fit, vtemp, rvalue = NaN
	String vlist = ""
	
	String df = NMArtDF
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( ParamIsDefault( alerts ) )
		alerts = 1
	endif
	
	if ( !ParamIsDefault( bslnWin ) )
	
		bslnWin = z_CheckBslnWin( bslnWin )
	
		vlist = NMCmdNumOptional( "bslnWin", bslnWin, vlist )
		
		SetNMvar( df+"BslnWin", bslnWin )
		
		updateBsln = 1
		updateTab = 1
		fit = 1
		
	endif
	
	if ( !ParamIsDefault( bslnDT ) )
	
		bslnDT = z_CheckBslnDT( bslnDT )
	
		vlist = NMCmdNumOptional( "bslnDT", bslnDT, vlist )
		
		SetNMvar( df+"BslnDT", bslnDT )
		
		updateBsln = 1
		updateTab = 1
		fit = 1
		
	endif
	
	if ( !ParamIsDefault( bslnFxn ) )
	
		bslnFxn = z_CheckBslnFxn( bslnFxn )
	
		vlist = NMCmdStrOptional( "bslnFxn", bslnFxn, vlist )
		
		SetNMstr( df+"BslnFxn", bslnFxn )
		SetNMvar( df+"BslnValue1", Nan )
		SetNMvar( df+"BslnValue2", Nan )
		SetNMvar( df+"BslnChi", Nan )
		
		updateTab = 1
		fit = 1
		
		if ( StringMatch( bslnFxn, "Exp" ) || StringMatch( bslnFxn, "2Exp" ) )
			z_FitBaselineExpWarning( bslnFxn, alert=1 )
		endif
		
	endif
	
	if ( !ParamIsDefault( artFitWin ) )
	
		artFitWin = z_CheckArtFitWin( artFitWin )
	
		vlist = NMCmdNumOptional( "artFitWin", artFitWin, vlist )
		
		SetNMvar( df+"ArtFitWin", artFitWin )
		SetNMvar( df+"DcayValue1", Nan )
		SetNMvar( df+"DcayValue2", Nan )
		SetNMvar( df+"DcayChi", Nan )
		
		fit = 1
		
	endif
	
	if ( !ParamIsDefault( artFitFxn ) )
	
		artFitFxn = z_CheckArtFitFxn( artFitFxn )
	
		vlist = NMCmdStrOptional( "artFitFxn", artFitFxn, vlist )
		
		SetNMstr( df+"ArtFitFxn", artFitFxn )
		SetNMvar( df+"DcayValue1", Nan )
		SetNMvar( df+"DcayValue2", Nan )
		SetNMvar( df+"DcayChi", Nan )
		
		updateTab = 1
		fit = 1
		
	endif
	
	if ( !ParamIsDefault( t1_hold ) )
	
		t1_hold = z_CheckTauHold( t1_hold )
	
		//vlist = NMCmdNumOptional( "t1_hold", t1_hold, vlist )
		
		rvalue = NMConfigVarSet( "Art", "t1_hold", t1_hold, history=1 )
		
		history = 0
		updateTab = 1
		fit = 1
		
	endif
	
	if ( !ParamIsDefault( t2_hold ) )
	
		t2_hold = z_CheckTauHold( t2_hold )
	
		//vlist = NMCmdNumOptional( "t2_hold", t2_hold, vlist )
		
		rvalue = NMConfigVarSet( "Art", "t2_hold", t2_hold, history=1 )
		
		history = 0
		updateTab = 1
		fit = 1
		
	endif
	
	if ( !ParamIsDefault( subtractWin ) )
	
		subtractWin = z_CheckSubtractWin( subtractWin )
	
		vlist = NMCmdNumOptional( "subtractWin", subtractWin, vlist )
		
		SetNMvar( df+"SubtractWin", subtractWin )
		
		fit = 1
		
	endif
	
	if ( !ParamIsDefault( waveOfArtTimes ) )
	
		vlist = NMCmdStrOptional( "waveOfArtTimes", waveOfArtTimes, vlist )
		
		rvalue = NMArtWaveOfArtTimesSet( waveOfArtTimes, artNum=-1 )
		
		updateTab = 1
		fit = 1
		
	endif
	
	if ( !ParamIsDefault( artNum ) )
	
		vlist = NMCmdNumOptional( "artNum", artNum, vlist )
		
		rvalue = NMArtNumSet( artNum )
		
		fit = 1
		
	endif
	
	if ( !ParamIsDefault( autoFit ) )
	
		autoFit = BinaryCheck( autoFit )
	
		vlist = NMCmdNumOptional( "autoFit", autoFit, vlist )
		
		SetNMvar( df+"AutoFit", autoFit )
		
		if ( autoFit )
			fit = 1
		endif
		
	endif
	
	if ( !ParamIsDefault( dragWaveAll ) )
	
		dragWaveAll = BinaryCheck( dragWaveAll )
		
		vlist = NMCmdNumOptional( "dragWaveAll", dragWaveAll, vlist )
		
		SetNMvar( df+"DragWaveAll", dragWaveAll )
		
		updateTab = 1
	
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( updateBsln )
		NMArtNumSet( -1, recomputeWindows=1 )
	endif
	
	if ( update && updateTab )
		NMArtUpdate()
	endif
	
	if ( NMArtVarGet( "AutoFit" ) && fit )
		NMArtFit()
	endif
	
	return rvalue

End // NMArtSet

//****************************************************************

Static Function z_CheckBslnWin( bslnWin )
	Variable bslnWin
	
	if ( numtype( bslnWin ) > 0 )
		return k_BslnWin
	else
		return abs( bslnWin )
	endif
	
End // z_CheckBslnWin

//****************************************************************

Static Function z_CheckBslnDT( bslnDT )
	Variable bslnDT
	
	if ( numtype( bslnDT ) > 0 )
		return 0
	else
		return abs( bslnDT )
	endif
	
End // z_CheckBslnDT

//****************************************************************

Static Function /S z_CheckBslnFxn( bslnFxn )
	String bslnFxn
	
	if ( WhichListItem( bslnFxn, k_ArtBslnFxnList ) >= 0 )
		return bslnFxn
	endif
	
	return k_BslnFxn // default
	
End // z_CheckBslnFxn

//****************************************************************

Static Function z_CheckArtFitWin( artFitWin )
	Variable artFitWin
	
	if ( numtype( artFitWin ) > 0 )
		return k_ArtFitWin
	else
		return abs( artFitWin )
	endif
	
End // z_CheckArtFitWin

//****************************************************************

Static Function z_CheckArtPeakDT( artPeakDT )
	Variable artPeakDT
	
	if ( numtype( artPeakDT ) > 0 )
		return 0
	else
		return k_ArtPeakDT
	endif
	
End // z_CheckArtPeakDT

//****************************************************************

Static Function /S z_CheckArtFitFxn( artFitFxn )
	String artFitFxn
	
	if ( WhichListItem( artFitFxn, k_ArtFitFxnList ) >= 0 )
		return artFitFxn
	endif
	
	return k_ArtFitFxn // default
	
End // z_CheckArtFitFxn

//****************************************************************

Static Function z_CheckTauHold( tau_hold )
	Variable tau_hold
	
	if ( ( numtype( tau_hold ) == 0 ) && ( tau_hold > 0 ) )
		return tau_hold
	endif
	
	return NaN
	
End // z_CheckTauHold

//****************************************************************

Static Function z_CheckSubtractWin( subtractWin )
	Variable subtractWin
	
	if ( numtype( subtractWin ) > 0 )
		return k_SubtractWin
	else
		return abs( subtractWin )
	endif
	
End // z_CheckSubtractWin

//****************************************************************

Function NMArtButton( ctrlName ) : ButtonControl
	String ctrlName
	
	String tName

	strswitch( ctrlName )
	
		case "AT_Reset":
			return NMArtCall( "Reset" )
			
		case "AT_Fit":
			return NMArtCall( "Fit" )
			
		case "AT_FitAll":
			return NMArtCall( "FitAll" )
			
		case "AT_FitTable":
			return NMArtCall( "FitTable" )
			
		case "AT_FitGraph":
			return NMArtCall( "FitGraph" )
			
		case "AT_FirstArt":
			return NMArtCall( "FirstArt" )
			
		case "AT_PrevArt":
			return NMArtCall( "PreviousArt" )
			
		case "AT_NextArt":
			return NMArtCall( "NextArt" )
			
		case "AT_LastArt":
			return NMArtCall( "LastArt" )
	
	endswitch
	
	return NaN

End // NMArtButton

//****************************************************************

Function NMArtCall( fxn )
	String fxn
	
	String rList
	
	Variable artNum = NMArtVarGet( "ArtNum" )
	
	strswitch( fxn )
	
		case "Reset":
			rList = z_NMArtResetCall()
			return ItemsInList( rList )
			
		case "Fit":
			return NMArtFit( artNum=artNum, history=1 )
			
		case "FitAll":
			rList = z_FitAllCall()
			return ItemsInList( rList )
			
		case "FitTable":
			rList = z_NMArtFitResultsTableCall()
			return ItemsInList( rList )
			
		case "FitGraph":
			rList = z_NMArtFitResultsGraphCall()
			return ItemsInList( rList )
			
		case "SubtractToggle":
			if ( z_ArtFinished( artNum ) )
				return NMArtFitRestore( artNum=artNum, history=0 ) // no history
			else
				return NMArtFitSubtract( artNum=artNum, history=0 ) // no history
			endif
			
		case "Subtract":
			return NMArtFitSubtract( artNum=artNum, history=1 )
			
		case "Restore": // unsubtract
			return NMArtFitRestore( artNum=artNum, history=1 )
			
		case "FirstArt":
			return NMArtSet( artNum=0, history=1 )
			
		case "PreviousArt":
			artNum -= 1
			return NMArtSet( artNum=artNum, history=0 ) // no history // too many calls
			
		case "NextArt":
			artNum += 1
			return NMArtSet( artNum=artNum, history=0 ) // no history // too many calls
			
		case "LastArt":
			return NMArtSet( artNum=inf, history=1 )
			
		case "DragWaveAllToggle":
			if ( NMArtVarGet( "DragWaveAll" ) )
				return NMArtSet( dragWaveAll=0, history=1 )
			else
				return NMArtSet( dragWaveAll=1, history=1 )
			endif
			
		default:
			NMDoAlert( "NMArtCall: unrecognized function call: " + fxn, title="NM Art Tab" )
			
	endswitch
	
	return NaN
	
End // NMArtCall

//****************************************************************

Static Function /S z_NMArtResetCall()
	Variable history
	
	String pList, df = NMArtDF
	
	Variable artNum = NMArtVarGet( "ArtNum" )
	
	String wName = CurrentNMWaveName()
	String wList = NMWaveSelectList( -1 )
	Variable numActiveWaves = ItemsInList( wList )
	
	Variable select = 1 + NumVarOrDefault( df+"ResetSelect", 0 )
	
	pList = "current artefact (#" + num2istr( artNum ) + ");current wave (" + wName + ");all selected waves (n=" + num2istr( numActiveWaves ) + ");"
	
	Prompt select, "reset analysis for:", popup pList
	
	DoPrompt NMPromptStr( "NM Art Reset" ), select
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	select -= 1
	
	SetNMvar( df+"ResetSelect", select )
	
	switch( select )
		case 0:
			return NMArtReset( artNum=artNum, history=1 )
		case 1:
			return NMArtReset( wList="CURRENTWAVE", history=1 )
		case 2:
			return NMArtReset( wList="ALLWAVES", history=1 )
	endswitch

End // z_NMArtResetCall

//****************************************************************

Function /S NMArtReset( [ artNum, wList, history ] )
	Variable artNum // -1 for current
	String wList // wave list or "CURRENTWAVE" or "ALLWAVES"
	Variable history
	
	Variable wcnt, forceMake = 0
	String select, wName, fwName, noArtName, artName
	String vlist = "", oList = ""
	
	String df = NMArtDF
	
	String xWave = NMXwave()
	
	Variable currentChan = CurrentNMChannel()
	
	Variable autoFit = NMArtVarGet( "AutoFit" )
	
	if ( ParamIsDefault( artNum ) )
	
		if ( ParamIsDefault( wList ) )
			return "" // not allowed
		else
			vlist = NMCmdStrOptional( "wList", wList, vlist )
			select = wList
		endif

		artNum = NaN // all
		
	else
	
		select = "STIM_NUM"
	
		vlist = NMCmdNumOptional( "artNum", artNum, vlist )
		
		if ( ParamIsDefault( wList ) )
			wList = "CURRENTWAVE"
		elseif ( StringMatch( wList, "CURRENTWAVE" ) )
			vlist = NMCmdStrOptional( "wList", wList, vlist )
		else
			return "" // not allowed
		endif
		
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	strswitch( select )
	
		case "STIM_NUM":
		
			fwName = NMArtSubWaveName( "finished" )
			
			if ( !WaveExists( $fwName ) )
				return ""
			endif
			
			Wave ftemp = $fwName
			
			if ( ( numtype( artNum ) > 0 ) || ( artNum < 0 ) || ( artNum >= DimSize( $fwName, 0 ) ) )
				return ""
			endif
			
			NMArtFitRestore( artNum=artNum )
		
			ftemp[ artNum ][ %finished ] = NaN
			
			if ( DimSize( ftemp, 1 ) == 12 )
			
				ftemp[ artNum ][ %b_bgn ] = NaN
				ftemp[ artNum ][ %b_end ] = NaN
				ftemp[ artNum ][ %b_k1 ] = NaN
				ftemp[ artNum ][ %b_k2 ] = NaN
				ftemp[ artNum ][ %b_chi ] = NaN
				
				ftemp[ artNum ][ %a_bgn ] = NaN
				ftemp[ artNum ][ %a_end ] = NaN
				ftemp[ artNum ][ %a_k1 ] = NaN
				ftemp[ artNum ][ %a_k2 ] = NaN
				ftemp[ artNum ][ %a_chi ] = NaN
			
			endif
			
			oList += CurrentNMWaveName() + ";"
			wList = "" // finished
			
			break
			
		case "CURRENTWAVE":
			wList = CurrentNMWaveName()
			break
			
		case "ALLWAVES":
			wList = NMWaveSelectList( -1 )
			break
			
		default:
			return ""
			
	endswitch
	
	if ( ItemsInList( wList ) > 0 )
		
		for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 ) // reset all
		
			wName = StringFromList( wcnt, wList )
			fwName = NMArtSubWaveName( "finished", wName=wName )
			
			if ( !WaveExists( $fwName ) )
				continue
			endif
			
			noArtName = NMArtSubWaveName( "no_art", wName=wName )
			artName = NMArtSubWaveName( "art", wName=wName )
			
			ChanWaveMake( currentChan, wName, noArtName, xWave=xWave ) // xWave not programmed yet
			
			Wave ftemp = $fwName
			ftemp = NaN
			
			if ( WaveExists( $artName ) )
				Wave atemp = $artName
				atemp = NaN
			endif
			
			oList += wName + ";"
			
		endfor
		
		artNum = 0
		forceMake = 1
	
	endif
	
	SetNMvar( df+"FitFlag", NaN )
	SetNMvar( df+"ArtTime", NaN )
	
	SetNMvar( df+"BslnValue1", NaN )
	SetNMvar( df+"BslnValue2", NaN )
	SetNMvar( df+"BslnChi", NaN )
	
	SetNMvar( df+"DcayValue1", NaN )
	SetNMvar( df+"DcayValue2", NaN )
	SetNMvar( df+"DcayChi", NaN )
	
	SetNMvar( df+"fit_a1", NaN )
	SetNMvar( df+"fit_t1", NaN )
	SetNMvar( df+"fit_a2", NaN )
	SetNMvar( df+"fit_t2", NaN )

	NMArtWaveOfArtTimesSet( "UPDATE", artNum=artNum, forceMake=forceMake ) // calls NMArtWavesCheck()
	
	if ( autoFit )
		NMArtFit( checkWaves=0 )
	endif
	
	return oList
	
End // NMArtReset

//****************************************************************

Static Function z_NMArtWaveSelectOK( [ waveNameOrSpikeSubfolder ] )
	String waveNameOrSpikeSubfolder

	Variable ok = 0
	
	String df = NMArtDF
	String folderPrefix
	String currentWavePrefix = CurrentNMWavePrefix()
	String wList = NMWaveSelectList( -1 )
	
	if ( ParamIsDefault( waveNameOrSpikeSubfolder ) )
		waveNameOrSpikeSubfolder = NMArtStrGet( "ArtTimeWName" )
	endif
	
	if ( ( strlen( currentWavePrefix ) == 0 ) || ( ItemsInList( wList ) == 0 ) )
		ok = 0
	elseif ( StringMatch( currentWavePrefix[ 0, 2 ], "AT_" ) )
		ok = 0 // do not work with Art waves
	elseif ( strlen( waveNameOrSpikeSubfolder ) == 0 )
		ok = 0 // nothing selected
	elseif ( WaveExists( $waveNameOrSpikeSubfolder ) )
		ok = 1
	elseif ( DataFolderExists( waveNameOrSpikeSubfolder ) )
		
		folderPrefix = "Spike_" + currentWavePrefix
		
		if ( strsearch( waveNameOrSpikeSubfolder, folderPrefix, 0 ) == 0 )
			ok = 1
		endif
		
	endif
	
	if ( !ok )
	
		SetNMvar( df+"FitFlag", NaN )

		SetNMvar( df+"BslnValue1", NaN )
		SetNMvar( df+"BslnValue2", NaN )
		SetNMvar( df+"BslnChi", NaN )
		
		SetNMvar( df+"DcayValue1", NaN )
		SetNMvar( df+"DcayValue2", NaN )
		SetNMvar( df+"DcayChi", NaN )
		
		SetNMvar( df+"ArtNum", 0 )
		SetNMvar( df+"ArtTime", NaN )
		SetNMvar( df+"NumArtefacts", 0 )
	
	endif
	
	return ok

End // z_NMArtWaveSelectOK

//****************************************************************

Static Function /S z_NMArtWaveOfArtTimesMakeCall()

	String df = NMArtDF
	String promptStr = "Artefact Level Detection"

	String wName = CurrentNMWaveName()

	Variable level = NumVarOrDefault( df+"ArtLevelDetection", k_ArtLevelDetection )
	Variable edge = NumVarOrDefault( df+"ArtLevelDetectionEdge", k_ArtLevelDetectionEdge )
	
	if ( edge == 0 )
		edge = 3
	endif
	
	Prompt level, "level threshold:"
	Prompt edge, "detection on:", popup "increasing data;decreasing data;either;"
	
	DoPrompt promptStr, level, edge
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( edge == 3 )
		edge = 0
	endif
	
	SetNMvar( df+"ArtLevelDetection", level )
	SetNMvar( df+"ArtLevelDetectionEdge", edge )
	
	return NMArtWaveOfArtTimesMake( wName, level=level, edge=edge, select=1, history=1 )

End // z_NMArtWaveOfArtTimesMakeCall

//****************************************************************

Function /S NMArtWaveOfArtTimesMake( wName [ level, edge, select, history ] )
	String wName // input wave name
	Variable level // threshold for level detection of artefacts // see Igor FindLevels
	Variable edge // see Igor FindLevels
		// 1: increasing
		// 2: decreasing
		// 0: either
	Variable select // select output wave
	Variable history
	
	String xName, vlist = ""
	String df = NMArtDF
	
	vlist = NMCmdStr( wName, vlist )
	
	if ( ParamIsDefault( level ) )
		level = NumVarOrDefault( df+"ArtLevelDetection", k_ArtLevelDetection )
	endif
	
	vlist = NMCmdNumOptional( "level", level, vlist )
	
	if ( ParamIsDefault( edge ) )
		edge = NumVarOrDefault( df+"ArtLevelDetection", k_ArtLevelDetectionEdge )
	endif
	
	vlist = NMCmdNumOptional( "edge", edge, vlist )
	
	if ( ParamIsDefault( select ) )
		select = 1
	else
		vlist = NMCmdNumOptional( "select", select, vlist )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( !WaveExists( $wName ) )
		return ""
	endif
	
	xName = "xAT_" + wName // x-wave of artefact times
	
	Make /O/N=1 $xName = NaN
	
	FindLevels /D=$xName/Edge=(edge)/Q $wName, level

	NMHistory( "Art Tab level detection n = " + num2str( V_LevelsFound ) )
	
	if ( select )
		NMArtWaveOfArtTimesSet( xName, artNum=0, history=history )
	endif
	
	return xName

End // NMArtWaveOfArtTimesMake

//****************************************************************

Function NMArtWaveOfArtTimesSet( waveNameOrSpikeSubfolder [ artNum, update, forceMake, forceMakeFits, history ] )
	String waveNameOrSpikeSubfolder // or "UPDATE" or "NONE"
	Variable artNum // set artefact number
	Variable update
	Variable forceMake // for NMArtWavesCheck()
	Variable forceMakeFits // for NMArtWavesCheck()
	Variable history
	
	Variable icnt, pnt, t, count1 = 0, count2 = 0
	String wName, yName = "", xLabel, yLabel, wList, stemp
	String vlist = "", df = NMArtDF
	
	Variable currentWave = CurrentNMWave()
	
	String dwName = ChanDisplayWave( -1 )
	String fwName = NMArtSubWaveName( "finished" )
	
	vlist = NMCmdStr( waveNameOrSpikeSubfolder, vlist )
	
	if ( ParamIsDefault( artNum ) )
		artNum = -1
	else
		vlist = NMCmdNumOptional( "artNum", artNum, vlist )
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	else
		vlist = NMCmdNumOptional( "update", update, vlist )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( StringMatch( waveNameOrSpikeSubfolder, "UPDATE" ) )
	
		waveNameOrSpikeSubfolder = NMNoteStrByKey( fwName, "WaveOfArtTimes" )
		
		if ( strlen( waveNameOrSpikeSubfolder ) == 0 )
			waveNameOrSpikeSubfolder = NMArtStrGet( "ArtTimeWName" )
		endif
		
	elseif ( StringMatch( waveNameOrSpikeSubfolder, "NONE" ) )
		
			waveNameOrSpikeSubfolder = ""
			
	endif
	
	if ( !z_NMArtWaveSelectOK( waveNameOrSpikeSubfolder=waveNameOrSpikeSubfolder ) )
		waveNameOrSpikeSubfolder = ""
		artNum = 0
	endif
	
	SetNMstr( df+"ArtTimeWName", waveNameOrSpikeSubfolder )
	
	NMArtWavesCheck( forceMake=forceMake, forceMakeFits=forceMakeFits )
	NMArtNumSet( artNum, update=update )
	z_F_NotesUpdate()
	
	if ( update )
		NMArtUpdate()
	else
		z_NumArtCount()
	endif
	
	return count2
	
End // NMArtWaveOfArtTimesSet

//****************************************************************

Static Function z_F_NotesUpdate()

	String stemp, xLabel, yLabel

	String fwName = NMArtSubWaveName( "finished" )
	
	String waveNameOrSpikeSubfolder = NMArtStrGet( "ArtTimeWName" )
	
	Variable artNum = NMArtVarGet( "ArtNum" )
	
	if ( !WaveExists( $fwName ) )
		return -1
	endif
	
	if ( strlen( waveNameOrSpikeSubfolder ) == 0 )
		return 0 // nothing to do
	endif
		
	stemp = NMNoteStrByKey( fwName, "Func" )

	if ( strlen( stemp ) == 0 )
		xLabel = "Art #"
		yLabel = "Art Time Finished"
		NMNoteType( fwName, "Art Finished", xLabel, yLabel, "_FXN_" )
	else
		NMNoteStrReplace( fwName, "Func", GetRTStackInfo( 1 ) )
	endif
	
	stemp = NMNoteStrByKey( fwName, "WaveOfArtTimes" )
	
	if ( strlen( stemp ) == 0 )
		Note $fwName, "WaveOfArtTimes:" + waveNameOrSpikeSubfolder
	else
		NMNoteStrReplace( fwName, "WaveOfArtTimes", waveNameOrSpikeSubfolder )
	endif
	
	stemp = NMNoteStrByKey( fwName, "CurrentArtNum" )
	
	if ( strlen( stemp ) == 0 )
		Note $fwName, "CurrentArtNum:" + num2istr( artNum )
	else
		NMNoteVarReplace( fwName, "CurrentArtNum", artNum )
	endif
	
	return 0

End // z_F_NotesUpdate

//****************************************************************

Static Function z_NumArtCount()

	Variable icount = 0
	String df = NMArtDF
	
	String waveNameOrSpikeSubfolder = NMArtStrGet( "ArtTimeWName" )
	
	if ( strlen( waveNameOrSpikeSubfolder ) == 0 )
		icount = 0
	elseif ( !WaveExists( $waveNameOrSpikeSubfolder ) && !DataFolderExists( waveNameOrSpikeSubfolder ) )
		icount = 0
	elseif ( WaveExists( $df+"AT_TimeX" ) && ( numpnts( $df+"AT_TimeX" ) > 0 ) )
		WaveStats /Q $df+"AT_TimeX"
		icount = V_npnts
	endif

	SetNMvar( df+"NumArtefacts", icount )
	
	return icount

End // z_NumArtCount

//****************************************************************

Function NMArtNumSet( artNum [ recomputeWindows, update, history ] )
	Variable artNum // -1 for current artefact
	Variable recomputeWindows
	Variable update
	Variable history
	
	Variable t = NaN
	String vlist = "", df = NMArtDF
	
	Variable autoFit = NMArtVarGet( "AutoFit" )
	
	String waveNameOrSpikeSubfolder = NMArtStrGet( "ArtTimeWName" )
	
	String fwName = NMArtSubWaveName( "finished" )
	
	vlist = NMCmdNum( artNum, vlist )
	
	if ( ParamIsDefault( update ) )
		update = 1
	else
		vlist = NMCmdNumOptional( "update", update, vlist )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( !WaveExists( $df+"AT_TimeX" ) )
		return 0
	endif
	
	//Wave xwave = $df+"AT_TimeX"
	
	if ( WaveExists( $df+"AT_Fit" ) )
		Wave AT_Fit = $df+"AT_Fit"
		AT_Fit = Nan
	endif
	
	if ( WaveExists( $df+"AT_FitB" ) )
		Wave AT_FitB = $df+"AT_FitB"
		AT_FitB = Nan
	endif
	
	artNum = z_CheckArtNum( artNum )
	
	SetNMvar( df+"ArtNum", artNum )
	
	SetNMvar( df+"FitFlag", NaN )
	SetNMvar( df+"BslnChi", NaN )
	SetNMvar( df+"DcayChi", NaN )
	
	if ( z_ArtFinished( artNum ) || !autoFit )
		SetNMvar( df+"BslnValue1", NaN )
		SetNMvar( df+"BslnValue2", NaN )
		SetNMvar( df+"DcayValue1", NaN )
		SetNMvar( df+"DcayValue2", NaN )
	endif
	
	if ( ( strlen( waveNameOrSpikeSubfolder ) > 0 ) && WaveExists( $fwName ) )
		NMNoteVarReplace( fwName, "CurrentArtNum", artNum )
	endif
	
	z_DisplayTimeSet( artNum, update, recomputeWindows )
	
	z_UpdateCheckboxSubtract( artNum )
	
	return 0
	
End // NMArtNumSet

//****************************************************************

Static function z_CheckArtNum( artNum ) // called from NMArtNumSet
	Variable artNum // -1 for current selected
	
	String df = NMArtDF
	
	String fwName = NMArtSubWaveName( "finished" )
	
	if ( !WaveExists( $df+"AT_TimeX" ) || ( numpnts( $df+"AT_TimeX" ) == 0 ) )
		return 0
	endif
	
	if ( artNum == -1 ) // current artefact
	
		if ( WaveExists( $fwName ) )
		
			artNum = NMNoteVarByKey( fwName, "CurrentArtNum" )
			
			if ( numtype( artNum ) > 0 )
				return 0
			endif
			
		else
		
			return 0
		
		endif
		
	endif
	
	artNum = max( artNum, 0 )
	artNum = min( artNum, numpnts( $df+"AT_TimeX" ) - 1 )
	
	return artNum

End // z_CheckArtNum

//****************************************************************

Static Function z_DisplayTimeSet( artNum, update, recomputeWindows ) // called from NMArtNumSet
	Variable artNum
	Variable update // display
	Variable recomputeWindows
	
	Variable bsln, xAxisDelta, yAxisDelta, t = NaN
	Variable bbgn, bend, abgn, aend
	Variable pbgn, pend, ybgn, yend, ymin, ymax
	
	String df = NMArtDF
	
	String xWave = NMXwave()
	
	Variable subtractWin = NMArtVarGet( "SubtractWin" )
	
	Variable bslnWin = NMArtVarGet( "BslnWin" )
	Variable bslnDT = NMArtVarGet( "BslnDT" )
	
	String gName = CurrentChanGraphName()
	String dwName = ChanDisplayWave( -1 )
	String noArtName = NMArtSubWaveName( "no_art" )
	
	if ( !WaveExists( $noArtName ) )
	
		if ( WaveExists( $df+"AT_Display" ) )
			Wave dtemp = $df+"AT_Display"
			dtemp = NaN
		endif
		
		if ( WaveExists( $df+"AT_TimeY" ) )
			Wave ytemp = $df+"AT_TimeY"
			ytemp = NaN
		endif
		
		SetNMvar( df+"ArtTime", NaN )
		
		if ( update )
			NMArtDragClear()
		endif
		
		return 0
		
	endif
	
	t = z_ArtTimeGet( artNum )
	 
	if ( numtype( t ) > 0 )
		
		Wave dtemp = $df+"AT_Display"
		dtemp = NaN
		
		SetNMvar( df+"ArtTime", NaN )
		
		if ( update )
			NMArtDragClear()
		endif
		
		return 0
		
	endif
	
	SetNMvar( df+"ArtTime", t )
	
	Duplicate /O $noArtName $df+"AT_Display"
	
	Make /O/N=2 $df+"AT_WinTemp" = NaN
	Wave win = $df+"AT_WinTemp"
	
	z_BslnWinGet( artNum, win, recompute=recomputeWindows )
	
	bbgn = win[ 0 ]
	bend = win[ 1 ]
	
	SetNMvar( df+"BslnXbgn", bbgn ) // drag wave variable
	SetNMvar( df+"BslnXend", bend )
	
	pbgn = z_NMX2Pnt( dwName, xWave, bbgn )
	pend = z_NMX2Pnt( dwName, xWave, bend )
	
	WaveStats /Q/R=[ pbgn, pend ] $dwname
	
	bsln = V_avg
	
	z_ArtWinGet( artNum, win, recompute=recomputeWindows )
	
	abgn = win[ 0 ]
	aend = win[ 1 ]
	
	SetNMvar( df+"Xbgn", abgn ) // drag wave variable
	SetNMvar( df+"Xend", aend )
	
	if ( update )
	
		DoWindow /F $gName
		
		xAxisDelta = ( bslnDT + bslnWin + subtractWin ) / 4
		SetAxis bottom ( bbgn - xAxisDelta ), ( t + subtractWin + xAxisDelta )
	
		Wave dtemp = $dwName
		
		pbgn = z_NMX2Pnt( dwName, xWave, abgn )
		pend = z_NMX2Pnt( dwName, xWave, aend )
		
		if ( ( pbgn >= 0 ) && ( pbgn < numpnts( dtemp ) ) )
			ybgn = dtemp[ pbgn ]
		endif
		
		if ( ( pend >= 0 ) && ( pend < numpnts( dtemp ) ) )
			yend = dtemp[ pend ]
		endif
		
		ymin = min( ybgn, yend )
		ymax = max( ybgn, yend )
		ymax = max( ymax, bsln )
	
		yAxisDelta = abs( ymax - ymin )
		SetAxis Left ( ymin - yAxisDelta ), ( ymax + yAxisDelta )
		
		NMArtDragUpdate()
		
	endif
	
	KillWaves /Z win
	
End // z_DisplayTimeSet

//****************************************************************

Static Function z_ArtTimeGet( artNum )
	Variable artNum
	
	String df = NMArtDF
	
	if ( !WaveExists( $df+"AT_TimeX" ) )
		return NaN
	endif
	
	Wave twave = $df+"AT_TimeX"
	
	if ( ( artNum >= 0 ) && ( artNum < numpnts( twave ) ) )
		return twave[ artNum ]
	endif
	
	return NaN
	
End // z_ArtTimeGet

//****************************************************************

Static Function z_BslnWinGet( artNum, output [ recompute ] )
	Variable artNum
	Wave output
	Variable recompute

	Variable bbgn, bend, lx, rx
	
	String noArtName = NMArtSubWaveName( "no_art" )
	String fwName = NMArtSubWaveName( "finished" )
	
	String xWave = NMXwave()
	
	if ( !WaveExists( $fwName ) || !WaveExists( $noArtName ) )
		return NaN
	endif
	
	lx = NMLeftX( noArtName, xWave=xWave )
	rx = NMRightX( noArtName, xWave=xWave )
	
	if ( !recompute )
	
		if ( ( numtype( artNum ) == 0 ) && ( artNum >= 0 ) && ( artNum < DimSize( $fwName, 0 ) ) )
		
			Wave ftemp = $fwName
		
			bbgn = ftemp[ artNum][ %b_bgn ]
			bend = ftemp[ artNum][ %b_end ]
		
			if ( ( numtype( bbgn ) == 0 ) && ( bbgn >= lx ) && ( bbgn <= rx ) )
				if ( ( numtype( bend ) == 0 ) && ( bend >= lx ) && ( bend <= rx ) )
					output[ 0 ] = bbgn
					output[ 1 ] = bend
					return 0
				endif
			endif
		
		endif
	
	endif
	
	Variable artTime = NMArtVarGet( "ArtTime" )
	Variable bslnWin = NMArtVarGet( "BslnWin" )
	Variable bslnDT = NMArtVarGet( "BslnDT" )
	
	bbgn = artTime - bslnDT - bslnWin
	bbgn = max( bbgn, lx )
	bbgn = min( bbgn, rx )
	
	bend = artTime - bslnDT
	bend = max( bend, lx )
	bend = min( bend, rx )
	
	output[ 0 ] = bbgn
	output[ 1 ] = bend
	
	//z_F_WinSet( artNum, b_bgn=bbgn, b_end=bend )
	
	return 0

End // z_BslnWinGet

//****************************************************************

Static Function z_ArtWinGet( artNum, output [ recompute ] )
	Variable artNum
	Wave output
	Variable recompute

	Variable abgn, aend, lx, rx
	
	String noArtName = NMArtSubWaveName( "no_art" )
	String fwName = NMArtSubWaveName( "finished" )
	
	String xWave = NMXwave()
	
	if ( !WaveExists( $fwName ) || !WaveExists( $noArtName ) )
		return NaN
	endif
	
	if ( !recompute )
	
		if ( ( numtype( artNum ) == 0 ) && ( artNum >= 0 ) && ( artNum < DimSize( $fwName, 0 ) ) )
		
			Wave ftemp = $fwName
		
			abgn = ftemp[ artNum][ %a_bgn ]
			aend = ftemp[ artNum][ %a_end ]
			
			lx = NMLeftX( noArtName, xWave=xWave )
			rx = NMRightX( noArtName, xWave=xWave )
		
			if ( ( numtype( abgn ) == 0 ) && ( abgn >= lx ) && ( abgn <= rx ) )
				if ( ( numtype( aend ) == 0 ) && ( aend >= lx ) && ( aend <= rx ) )
					output[ 0 ] = abgn
					output[ 1 ] = aend
					return 0
				endif
			endif
		
		endif
	
	endif
	
	Variable peakDT = NMArtVarGet( "ArtPeakDT" )
	Variable artWin = NMArtVarGet( "ArtFitWin" )
	
	abgn = z_ArtPeakT( artNum )
	
	if ( ( numtype( peakDT ) == 0 ) && ( abs( peakDT ) > 0 ) )
		abgn += peakDT
	endif
	
	aend = abgn + artWin
	
	output[ 0 ] = abgn
	output[ 1 ] = aend
	
	//z_F_WinSet( artNum, a_bgn=abgn, a_end=aend )
	
	return 0

End // z_ArtWinGet

//****************************************************************

Function z_ArtPeakT( artNum )
	Variable artNum
	
	Variable tpeak, abgn, aend, pbgn, pend
	
	String xWave = NMXwave()
	
	Variable artWidth = NMArtVarGet( "ArtWidth" )
	String artShape = NMArtStrGet( "ArtShape" )
	
	Variable artTime = z_ArtTimeGet( artNum )
	
	if ( numtype( artTime ) > 0 )
		return NaN
	endif
	
	String noArtName = NMArtSubWaveName( "no_art" )
	
	if ( !WaveExists( $noArtName ) )
		return NaN
	endif
	
	abgn = artTime
	aend = artTime + artWidth
	
	pbgn = z_NMX2Pnt( noArtName, xWave, abgn )
	pend = z_NMX2Pnt( noArtName, xWave, aend )
	
	WaveStats /Q/R=[ pbgn, pend ] $noArtName // find first peak
	
	strswitch( artShape )
	
		case "PN": // max should be "P"
		
			if ( WaveExists( $xWave ) )
			
				Wave xtemp = $xWave
				
				if ( ( V_maxRowLoc >= 0 ) && ( V_maxRowLoc < numpnts( xtemp ) ) )
					tpeak = xtemp[ V_maxRowLoc ]
				else
					return NaN
				endif
				
			else
			
				tpeak = V_maxloc
				
			endif
			
			break
			
		case "NP": // min should be "N"
		
			if ( WaveExists( $xWave ) )
			
				Wave xtemp = $xWave
				
				if ( ( V_minRowLoc >= 0 ) && ( V_minRowLoc < numpnts( xtemp ) ) )
					tpeak = xtemp[ V_minRowLoc ] 
				else
					return NaN
				endif
				
			else
			
				tpeak = V_minloc
				
			endif
			
			break
			
		default:
		
			return NaN
			
	endswitch
	
	abgn = tpeak
	aend = tpeak + artWidth * 0.5
	
	pbgn = z_NMX2Pnt( noArtName, xWave, abgn )
	pend = z_NMX2Pnt( noArtName, xWave, aend )
	
	WaveStats /Q/R=[ pbgn, pend ] $noArtName // find second peak
	
	strswitch( artShape )
	
		case "PN": // min should be "N"
		
			if ( WaveExists( $xWave ) )
			
				Wave xtemp = $xWave
				
				if ( ( V_minRowLoc >= 0 ) && ( V_minRowLoc < numpnts( xtemp ) ) )
					return xtemp[ V_minRowLoc ] 
				else
					return NaN
				endif
				
			else
			
				return V_minloc
				
			endif
			
		case "NP": // max should be "P"
		
			if ( WaveExists( $xWave ) )
			
				Wave xtemp = $xWave
				
				if ( ( V_maxRowLoc >= 0 ) && ( V_maxRowLoc < numpnts( xtemp ) ) )
					return xtemp[ V_maxRowLoc ] 
				else
					return NaN
				endif
				
			else
			
				return V_maxloc
				
			endif
		
	endswitch
	
	return NaN
	
End // z_ArtPeakT

//****************************************************************

Static Function z_F_WinSet( artNum [ b_bgn, b_end, a_bgn, a_end ] )
	Variable artNum
	Variable b_bgn, b_end, a_bgn, a_end

	String fwName = NMArtSubWaveName( "finished" )
	
	if ( !WaveExists( $fwName ) )
		return NaN
	endif
	
	if ( ( numtype( artNum ) != 0 ) || ( artNum < 0 ) || ( artNum >= DimSize( $fwName, 0 ) ) )
		return NaN
	endif
	
	Wave ftemp = $fwName
	
	if ( !ParamIsDefault( b_bgn ) )
		ftemp[ artNum ][ %b_bgn ] = b_bgn
	endif
	
	if ( !ParamIsDefault( b_end ) )
		ftemp[ artNum ][ %b_end ] = b_end
	endif
	
	if ( !ParamIsDefault( a_bgn ) )
		ftemp[ artNum ][ %a_bgn ] = a_bgn
	endif
	
	if ( !ParamIsDefault( a_end ) )
		ftemp[ artNum ][ %a_end ] = a_end
	endif
	
	return 0
	
End // z_F_WinSet

//****************************************************************

Static Function /S z_FitAllCall()

	String twName = NMArtStrGet( "ArtTimeWName" )
	
	if ( strlen( twName ) == 0 )
		return ""
	endif

	String df = NMArtDF
	String title = "NM Art Tab : " + twName
	
	String wName = CurrentNMWaveName()
	String wList = NMWaveSelectList( -1 )
	Variable numActiveWaves = ItemsInList( wList )
	
	Variable allWaves = 1 + NumVarOrDefault( df+"FitAllWaves", 0 )
	Variable update = 1 + NumVarOrDefault( df+"FitAllUpdate", 1 )
	Variable table = 1 + NumVarOrDefault( df+"FitAllTable", 1 )
	
	Prompt allwaves, "compute artefact subtraction for:", popup "current wave (" + wName + ");all selected waves (n=" + num2istr( numActiveWaves ) + ");"
	Prompt update, "display results while computing?", popup "no;yes;"
	Prompt table, "display table of fit results?", popup "no;yes;"
	
	Variable numWaves = NMNumActiveWaves()
	
	if ( numWaves == 0 )
		return ""
	endif
		
	if ( numWaves == 1 )
	
		DoPrompt NMPromptStr( "NM Art Fit All" ), update, table
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		update -= 1
		table -= 1
		
		SetNMvar( df+"FitAllUpdate", update )
		SetNMvar( df+"FitAllTable", table )
		
		allWaves = 0
	
	elseif ( numWaves > 1 )
	
		DoPrompt NMPromptStr( "NM Art Fit All" ), allWaves, update, table
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		allWaves -= 1
		update -= 1
		table -= 1
		
		SetNMvar( df+"FitAllWaves", allWaves )
		SetNMvar( df+"FitAllUpdate", update )
		SetNMvar( df+"FitAllTable", table )
	
	else
	
		return ""
	
	endif
	
	return NMArtFitAll( allWaves=allWaves, table=table, update=update, history=1 )

End // z_FitAllCall

//****************************************************************

Function /S NMArtFitAll( [ allWaves, table, update, history ] )
	Variable allWaves
	Variable table
	Variable update
	Variable history

	Variable wcnt, wbgn, wend, success, failure
	Variable icnt, artTime, numArtefacts, rflag
	String wName, fwName, tName = "", tList = "", vlist = ""
	
	String df = NMArtDF
	
	Variable checkWaves = 1
	
	if ( !z_NMArtWaveSelectOK() )
		return ""
	endif
	
	Variable currentChan = CurrentNMChannel()
	Variable currentWave = CurrentNMWave()
	Variable numWaves = NMNumWaves()
	Variable saveArtNum = NMArtVarGet( "ArtNum" ) 
	
	String twName = NMArtStrGet( "ArtTimeWName" )
	
	if ( strlen( twName ) == 0 )
		return ""
	endif
	
	if ( ParamIsDefault( allWaves ) )
		allWaves = 0
	else
		vlist = NMCmdNumOptional( "allWaves", allWaves, vlist )
	endif
	
	if ( ParamIsDefault( table ) )
		table = 1
	else
		vlist = NMCmdNumOptional( "table", table, vlist )
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	else
		vlist = NMCmdNumOptional( "update", update, vlist )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( allWaves )
		wbgn = 0
		wend = numWaves - 1
	else
		wbgn = currentWave
		wend = currentWave
	endif
	
	for ( wcnt = wbgn ; wcnt <= wend ; wcnt += 1 ) // loop thru waves
	
		wName = NMWaveSelected( currentChan, wcnt )
				
		if ( strlen( wName ) == 0 )
			continue // wave not selected, or does not exist... go to next wave
		endif
		
		if ( allWaves )
			NMCurrentWaveSet( wcnt, update = 0 )
			NMChanGraphUpdate( channel = currentChan, waveNum = wcnt )
			NMArtAuto()
		endif
		
		fwName = NMArtSubWaveName( "finished" )
		
		if ( !WaveExists( $fwName ) )
			continue
		endif
			
		Wave ftemp = $fwName
		
		numArtefacts = DimSize( ftemp, 0 )
	
		for ( icnt = 0; icnt < numArtefacts; icnt += 1 )
		
			if ( NMProgress( icnt, numArtefacts, "Art subtract #" + num2istr( icnt ) ) == 1 ) // update progress display
				break // cancel
			endif
		
			if ( ftemp[ icnt ][ %finished ] == 1 )
				continue
			endif
			
			NMArtNumSet( icnt, update=update )
			
			artTime = NMArtVarGet( "ArtTime" )
			
			if ( numtype( artTime ) > 0 )
				continue
			endif
			
			NMArtFit( checkWaves=checkWaves, update=update )
			
			if ( NMArtVarGet( "FitFlag" ) == 2 )
				NMArtFitSubtract( artNum=icnt, update=update )
				success += 1
			else
				NMHistory( "Art subtract failure : " + wName + " : #" + num2istr( icnt ) )
				failure += 1
			endif
			
			checkWaves = 0 // check only on first pass
			
		endfor
		
		NMArtNumSet( 0, update=0 )
		
		if ( table )
		
			tName = NMArtFitResultsTable( wList=wName )
			
			if ( strlen( tName ) > 0 )
				tList += tName + ";"
			endif
			
		endif
		
		if ( NMProgressCancel() == 1 )
			break
		endif
	
	endfor
	
	if ( wend != currentWave )
		NMSet( waveNum=currentWave )
	endif
	
	NMArtNumSet( saveArtNum )
	
	NMHistory( "Art Fit All : " + num2str( failure ) + " failures out of " + num2str( failure + success ) )
	
	for ( icnt = 0 ; icnt < ItemsInList( tList ) ; icnt += 1 )
		tName = StringFromList( icnt, tList )
		DoWindow /F $tName
	endfor
	
	if ( ItemsInList( tList ) == 1 )
		return StringFromList( 0, tList )
	else
		return tList
	endif

End // NMArtFitAll

//****************************************************************

Static Function /S z_NMArtFitResultsTableCall()

	String df = NMArtDF
	
	String wName = CurrentNMWaveName()
	String wList = NMWaveSelectList( -1 )
	Variable numActiveWaves = ItemsInList( wList )
	
	if ( !WaveExists( $wName ) || ( ItemsInList( wList ) == 0 ) )
		return ""
	endif
	
	Variable allWaves = 1 + NumVarOrDefault( df+"EditAllWaves", 0 )
	
	Prompt allWaves, "create a table for:", popup "current wave (" + wName + ");all selected waves (n=" + num2istr( numActiveWaves ) + ");"
	
	DoPrompt NMPromptStr( "NM Art Table" ), allWaves
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	allWaves -= 1
	
	SetNMvar( df+"EditAllWaves", allWaves )
		
	if ( allWaves == 0 )
		return NMArtFitResultsTable( wList="CURRENTWAVE", history=1 )
	else
		return NMArtFitResultsTable( wList="ALLWAVES", history=1 )
	endif
		
	return ""

End // z_NMArtFitResultsTableCall

//****************************************************************

Function /S NMArtFitResultsTable( [ wList, history ] )
	String wList // list of wave names or "CURRENTWAVE" or "AllWAVES"
	Variable history
	
	Variable wcnt
	String wName, fwName, tName, title, tList = "", vlist = ""
	
	STRUCT Rect w
	
	if ( ParamIsDefault( wList ) )
		wList = "CURRENTWAVE"
	else
		vlist = NMCmdStr( wList, vlist )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( StringMatch( wList, "CURRENTWAVE" ) )
		wList = CurrentNMWaveName()
	elseif ( StringMatch( wList, "ALLWAVES" ) )
		wList = NMWaveSelectList( -1 )
	endif
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		fwName = NMArtSubWaveName( "finished", wName=wName )
	
		if ( !WaveExists( $fwName ) )
			continue
		endif
	
		tName = "AT_" + fwName + "_Table"
		title = NMFolderListName( "" ) + " : " + fwName
	
		Wave ftemp = $fwName
	
		NMWinCascadeRect( w )
		DoWindow /K $tName
		Edit /K=1/N=$tName/W=(w.left,w.top,w.right,w.bottom) ftemp.ld as title
	
		ModifyTable /W=$tName title( Point )="Art#"
		
		tList += tName + ";"
		
	endfor
	
	if ( ItemsInList( tList ) == 1 )
		return StringFromList( 0, tList )
	else
		return tList
	endif

End // NMArtFitResultsTable

//****************************************************************

Static Function /S z_NMArtFitResultsGraphCall()

	String df = NMArtDF
	
	String wName = CurrentNMWaveName()
	String wList = NMWaveSelectList( -1 )
	Variable numActiveWaves = ItemsInList( wList )
	
	if ( !WaveExists( $wName ) || ( ItemsInList( wList ) == 0 ) )
		return ""
	endif
	
	Variable allWaves = 1 + NumVarOrDefault( df+"GraphAllWaves", 0 )
	
	Prompt allWaves, "graph results for:", popup "current wave (" + wName + ");all selected waves (n=" + num2istr( numActiveWaves ) + ");"

	String select = StrVarOrDefault( df+"GraphSelect", " " )
	String sList = "onset;finished;b_k1;b_k2;b_chi;a_k1;a_k2;a_chi;chi;"
	
	Prompt select, "choose a column to plot:", popup " ;" + sList
	DoPrompt NMPromptStr( "NM Art Graph" ), allWaves, select
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	allWaves -= 1
	
	SetNMvar( df+"GraphAllWaves", allWaves )
	
	if ( strlen( select ) > 1 )
	
		SetNMstr( df+"GraphSelect", select )
		
		if ( allWaves == 0 )
			return NMArtFitResultsGraph( select, wList="CURRENTWAVE", history=1 )
		else
			return NMArtFitResultsGraph( select, wList="ALLWAVES", history=1 )
		endif
		
	endif

	return ""

End // NMArtFitResultsGraphCall

//****************************************************************

Function /S NMArtFitResultsGraph( select [ wList, history ] )
	String select // see strswitch
	String wList // list of wave names or "CURRENTWAVE" or "AllWAVES"
	Variable history
	
	Variable wcnt
	String wName, fwName, gName, gList = ""
	String title, ytitle = "", vlist = ""
	
	STRUCT Rect w
	
	STRUCT NMRGB ac
	STRUCT NMRGB bc
	
	NMColorList2RGB( NMArtStrGet( "DecayColor" ), ac )
	NMColorList2RGB( NMArtStrGet( "BaseColor" ), bc )
	
	vlist = NMCmdStr( select, vlist )
	
	if ( ParamIsDefault( wList ) )
		wList = "CURRENTWAVE"
	else
		vlist = NMCmdStr( wList, vlist )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( StringMatch( wList, "CURRENTWAVE" ) )
		wList = CurrentNMWaveName()
	elseif ( StringMatch( wList, "ALLWAVES" ) )
		wList = NMWaveSelectList( -1 )
	endif
	
	if ( ( ItemsInList( wList ) == 0 ) || ( strlen( select ) < 3 ) )
		return ""
	endif
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		fwName = NMArtSubWaveName( "finished", wName=wName )
		
		if ( !WaveExists( $fwName ) )
			continue
		endif
		
		gName = "AT_" + fwName + "_" + select
		title = NMFolderListName( "" ) + " : " + fwName + " : " + select
		ytitle = ""
		
		Wave ftemp = $fwName
		
		NMWinCascadeRect( w )
		DoWindow /K $gName
		
		Display /K=1/N=$gName/W=(w.left,w.top,w.right,w.bottom) as title
	
		strswitch( select )
			case "onset":
				AppendToGraph /W=$gName/C=( ac.r, ac.g, ac.b ) ftemp[][ %onset ]
				ytitle = "Onset Time"
				break
			case "finished":
				AppendToGraph /W=$gName/C=( ac.r, ac.g, ac.b ) ftemp[][ %finished ]
				ytitle = "Finished Flag"
				break
		endswitch
		
		if ( DimSize( ftemp, 1 ) == 12 )
		
			strswitch( select )
				case "onset":
				case "finished":
					break // executed above
				case "b_k1":
					AppendToGraph /W=$gName/C=( bc.r, bc.g, bc.b ) ftemp[][ %b_k1 ]
					ytitle = "Baseline K1"
					break
				case "b_k2":
					AppendToGraph /W=$gName/C=( bc.r, bc.g, bc.b ) ftemp[][ %b_k2 ]
					ytitle = "Baseline K2"
					break
				case "b_chi":
					AppendToGraph /W=$gName/C=( bc.r, bc.g, bc.b ) ftemp[][ %b_chi ]
					ytitle = "Baseline chi-square"
					break
				case "a_k1":
					AppendToGraph /W=$gName/C=( ac.r, ac.g, ac.b ) ftemp[][ %a_k1 ]
					ytitle = "Artefact K1"
					break
				case "a_k2":
					AppendToGraph /W=$gName/C=( ac.r, ac.g, ac.b ) ftemp[][ %a_k2 ]
					ytitle = "Artefact K2"
					break
				case "a_chi":
					AppendToGraph /W=$gName/C=( ac.r, ac.g, ac.b ) ftemp[][ %a_chi ]
					ytitle = "Artefact chi-square"
					break
				case "chi":
					AppendToGraph /W=$gName/C=( ac.r, ac.g, ac.b ) ftemp[][ %a_chi ]
					AppendToGraph /W=$gName/C=( bc.r, bc.g, bc.b ) ftemp[][ %b_chi ]
					ytitle = "Chi-square"
					break
				default:
					DoWindow /K $gName
					return ""
			endswitch
		
		endif
		
		Label /W=$gName bottom "Artefact #"
		Label /W=$gName left ytitle
		
		gList += gName + ";"
	
	endfor
	
	if ( ItemsInList( gList ) == 1 )
		return StringFromList( 0, gList )
	else
		return gList
	endif

End // NMArtFitResultsGraph

//****************************************************************

Function NMArtFit( [ artNum, checkWaves, update, history ] )
	Variable artNum
	Variable checkWaves
	Variable update
	Variable history

	Variable rflag
	String vlist = "", df = NMArtDF

	Variable artTime = NMArtVarGet( "ArtTime" )
	
	String twName = NMArtStrGet( "ArtTimeWName" )
	String fwName = NMArtSubWaveName( "finished" )
	String gName = CurrentChanGraphName()
	String dwName = ChanDisplayWave( -1 )
	
	if ( ParamIsDefault( artNum ) )
		artNum = NMArtVarGet( "ArtNum" )
	else
		vlist = NMCmdNumOptional( "artNum", artNum, vlist )
	endif
	
	if ( ParamIsDefault( checkWaves ) )
		checkWaves = 1
	else
		vlist = NMCmdNumOptional( "checkWaves", checkWaves, vlist )
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	else
		vlist = NMCmdNumOptional( "update", update, vlist )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( !WaveExists( $dwName ) )
		return NaN
	endif
	
	if ( !z_NMArtWaveSelectOK() )
		return -1
	endif
	
	SetNMvar( df+"FitFlag", NaN ) // reset fit flag
	
	if ( checkWaves )
		if ( NMArtWavesCheck( forceMakeFits=1 ) != 0 )
			return NaN
		endif
	endif
	
	if ( ( strlen( twName ) == 0 ) || ( !WaveExists( $twName ) && !DataFolderExists( twName ) ) )
		return NaN
	endif
	
	if ( ( strlen( fwName ) == 0 ) || !WaveExists( $fwName ) )
		return NaN
	endif
	
	if ( numtype( artTime ) > 0 )
		return 0 // nothing to fit
	endif
	
	if ( ( artNum < 0 ) || ( artNum >= DimSize( $fwName, 0 ) ) )
		return 0
	endif
	
	Wave ftemp = $fwName
	
	if ( ftemp[ artNum ][ %finished ] )
		return 0
	endif
	
	ftemp[ artNum ][ %onset ] = artTime
	
	rflag = z_FitBaseline( update = update )
	
	if ( rflag == 0 )
	
		SetNMvar( df+"FitFlag", 1 ) // baseline fit OK
		
		rflag = z_FitArtefact( update = update )
		
		if ( rflag == 0 )
			SetNMvar( df+"FitFlag", 2 ) // decay fit OK
		endif
		
	endif
	
	if ( update )
		DoUpdate
	endif
	
	z_UpdateCheckboxSubtract( artNum )
	
	KillWaves /Z $df+"AT_FitX"
	
	return rflag

End // NMArtFit

//****************************************************************

Static Function z_FitBaselineExpWarning( fxn [ alert ] )
	String fxn
	Variable alert
	
	String title = "NM Art Baseline Fit"

	String aStr = "Warning: the baseline " + fxn + " fit assumes your baseline decays to zero, "
	aStr += "i.e. your data has been baseline subtracted. See Baseline under "
	aStr += "Main Tab Operations or Channel Graph Transforms."

	if ( alert )
		DoAlert /T=title 0, aStr
	endif
	
	NMHistory( aStr )

End // z_FitBaselineExpWarning

//****************************************************************

Static Function z_FitBaseline( [ update ] )
	Variable update

	Variable bbgn, bend, bwin, tau, ybgn, yend, slope, tmax, tlimit
	Variable pcnt, pbgn, pend, ssd = 0
	Variable v1 = Nan, v2 = Nan, chisqr = NaN
	Variable V_FitError, V_FitQuitReason, V_chisq
	String regstr
	
	// V_FitQuitReason:
	// 0 if the fit terminated normally
	// 1 if the iteration limit was reached
	// 2 if the user stopped the fit
	// 3 if the limit of passes without decreasing chi-square was reached.
	
	String S_Info = "" // Keyword-value pairs giving certain kinds of information about the fit.
	
	String xWave = NMXwave()
	 
	String df = NMArtDF
	
	String bslnFxn = NMArtStrGet( "BslnFxn" )
	Variable bslnExpSlopeThreshold = NMArtVarGet( "BslnExpSlopeThreshold" )
	
	Variable artNum = NMArtVarGet( "ArtNum" )
	Variable artTime = NMArtVarGet( "ArtTime" )
	Variable subtractWin = NMArtVarGet( "SubtractWin" )
	
	String dwName = ChanDisplayWave( -1 )
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( !WaveExists( $dwName ) )
		return NaN
	endif
	
	Wave dtemp = $dwName
	
	//Wave AT_A = $df+"AT_A"
	//Wave AT_B = $df+"AT_B"
	
	Duplicate /O $dwname $df+"AT_FitB"
	Wave AT_FitB = $df+"AT_FitB" // channel display wave
	
	if ( WaveExists( $xWave ) )
		Duplicate /O $xWave $df+"AT_FitX"
		Wave AT_FitX = $df+"AT_FitX"
	else
		Duplicate /O $dwname $df+"AT_FitX"
		Wave AT_FitX = $df+"AT_FitX" // x-times for fitting
		AT_FitX = x
	endif
	
	Make /O/N=2 $df+"AT_Temp" = NaN
	Wave btemp = $df+"AT_Temp"
	
	z_BslnWinGet( artNum, btemp )
	
	bbgn = btemp[ 0 ]
	bend = btemp[ 1 ]
	
	if ( ( numtype( bbgn * bend ) > 0 ) || ( bbgn >= bend ) )
		return NaN
	endif
	
	KillWaves /Z btemp
	
	bwin = bend - bbgn
	
	pbgn = z_NMX2Pnt( dwName, xWave, bbgn )
	pend = z_NMX2Pnt( dwName, xWave, bend )
	
	WaveStats /Q/R=[ pbgn, pbgn + 10 ] $dwName
	
	ybgn = V_avg
	
	WaveStats /Q/R=[ pend - 10, pend ] $dwName
	
	yend = V_avg
	
	// yend / ybgn = exp(-1/tau)
	// yend / ybgn = exp(-bwin/tau)
	
	tau = bwin * ( -1 / ln ( yend / ybgn ) )
	
	if ( ( StringMatch( bslnFxn, "Exp" ) || StringMatch( bslnFxn, "2Exp" ) ) && ( abs( bslnExpSlopeThreshold ) > 0 ) )
	
		//slope = ( yend - ybgn ) / ( bend - bbgn )
		regstr = NMLinearRegression( dwName, xWave=xWave, xbgn=bbgn, xend=bend )
		slope = str2num( StringByKey( "m", regstr, "=" ) )
		
		if ( ( bslnExpSlopeThreshold > 0 ) && ( slope > bslnExpSlopeThreshold ) )
			// bslnFxn = "Exp" // ok to fit exp
		elseif ( ( bslnExpSlopeThreshold < 0 ) && ( slope < bslnExpSlopeThreshold ) )
			// bslnFxn = "Exp" // ok to fit exp
		else
			bslnFxn = "Avg" // change to average
		endif
	
	endif
	
	if ( StringMatch( bslnFxn, "Exp" ) || StringMatch( bslnFxn, "2Exp" ) )
	
		pbgn = z_NMX2Pnt( dwName, xWave, 0 )
		pend = z_NMX2Pnt( dwName, xWave, 5 )
	
		WaveStats /Q/R=[ pbgn, pend ] $dwName
		
		if ( abs( V_avg ) > 1 * V_sdev )
			z_FitBaselineExpWarning( bslnFxn )
		endif
	
		Make /O/N=4 $df+"AT_A"
		Wave AT_A = $df+"AT_A"
		
		AT_A[ 0 ] = bbgn // x0 // hold
		AT_A[ 1 ] = 0 // y0 // hold // ASSUMES BASELINE DECAYS TO ZERO
		AT_A[ 2 ] = 1.5 * ( ybgn - yend ) // a1
		AT_A[ 3 ] = tau
		
		Make /O/N=0 $df+"AT_B" // n=0 so NMArtFxnExp computes normal exp
		Wave AT_B = $df+"AT_B"
		
		if ( WaveExists( $xWave ) )
		
			pbgn = z_NMX2Pnt( dwName, xWave, bbgn )
			pend = z_NMX2Pnt( dwName, xWave, bend )
			
			if ( pbgn >= pend )
				return NaN
			endif
			
			FuncFit /Q/W=2/N/H="1100" NMArtFxnExp AT_A $dwName[ pbgn, pend ] /X=$xWave[ pbgn, pend ]
		
		else
		
			FuncFit /Q/W=2/N/H="1100" NMArtFxnExp AT_A $dwName( bbgn, bend )
			// single exp // W=2 suppresses Fit Progress window
			
		endif
		
		if ( strlen( S_Info ) == 0 )
			if ( V_FitQuitReason == 0 )
				V_FitQuitReason = 9
			endif
		endif
		
		if ( ( V_FitQuitReason == 0 ) && ( AT_A[ 3 ] > 0 ) )
			AT_FitB = NMArtFxnExp( AT_A, AT_FitX )
			v1 = AT_A[ 2 ]
			v2 = AT_A[ 3 ]
			chisqr = V_chisq
		elseif ( abs( bslnExpSlopeThreshold ) > 0 )
			bslnFxn = "Avg" // fit failed, so compute average
		else
			AT_FitB = NaN
		endif
		
		Redimension /N=4 AT_B // now n=4 so NMArtFxnExp will use baseline in Decay fit
		AT_B = AT_A
			
	endif
			
	if ( StringMatch( bslnFxn, "2Exp" ) && ( numtype( v1 * v2 ) == 0 ) )
	
			Make /O/N=6 $df+"AT_A"
			Wave AT_A = $df+"AT_A"
			
			AT_A[ 0 ] = bbgn // x0 // hold
			AT_A[ 1 ] = 0 // y0 // hold // ASSUMES BASELINE DECAYS TO ZERO
			AT_A[ 2 ] = v1 // a1
			AT_A[ 3 ] = v2 // t1
			AT_A[ 4 ] = 0.5 * v1 // a2
			AT_A[ 5 ] = 2 * v2 // t2
			
			Make /O/N=0 $df+"AT_B" // n=0 so NMArtFxnExp computes normal exp
			Wave AT_B = $df+"AT_B"
			
			if ( WaveExists( $xWave ) )
			
				pbgn = z_NMX2Pnt( dwName, xWave, bbgn )
				pend = z_NMX2Pnt( dwName, xWave, bend )
				
				if ( pbgn >= pend )
					return NaN
				endif
				
				FuncFit /Q/W=2/N/H="110000" NMArtFxnExp2 AT_A $dwName[ pbgn, pend ] /X=$xWave[ pbgn, pend ]
			
			else
			
				FuncFit /Q/W=2/N/H="110000" NMArtFxnExp2 AT_A $dwName( bbgn, bend )
				// double exp // W=2 suppresses Fit Progress window
				
			endif
			
			if ( strlen( S_Info ) == 0 )
				if ( V_FitQuitReason == 0 )
					V_FitQuitReason = 9
				endif
			endif
			
			//print V_FitQuitReason, AT_A[ 3 ], AT_A[ 5 ]
			
			if ( ( V_FitQuitReason == 0 ) && ( AT_A[ 3 ] > 0 ) && ( AT_A[ 5 ] > 0 ) )
				AT_FitB = NMArtFxnExp2( AT_A, AT_FitX )
				v1 = AT_A[ 3 ]
				v2 = AT_A[ 5 ]
				chisqr = V_chisq
			elseif ( abs( bslnExpSlopeThreshold ) > 0 )
				bslnFxn = "Avg" // fit failed, so compute average
			else
				AT_FitB = NaN
			endif
			
			Redimension /N=6 AT_B // now n=6 so NMArtFxnExp will use baseline in Decay fit
			AT_B = AT_A
			
	endif
	
	strswitch( bslnFxn )
	
		case "Exp":
		case "2Exp":
			break // already computed above
			
		case "Avg":
		
			Make /O/N=1 $df+"AT_B"
			Wave AT_B = $df+"AT_B"
			
			pbgn = z_NMX2Pnt( dwName, xWave, bbgn )
			pend = z_NMX2Pnt( dwName, xWave, bend )
			
			WaveStats /Q/R=[ pbgn, pend ] $dwName
	
			AT_FitB = V_avg
			AT_B = V_avg
			v1 = V_avg
			
			for ( pcnt = pbgn ; pcnt <= pend ; pcnt += 1 )
				ssd += ( dtemp[ pcnt ] - v1 ) ^ 2
			endfor
			
			chisqr = ssd
			V_FitError = 0
			
			break
			
		case "Line":
		
			Make /O/N=2 $df+"AT_B"
			Wave AT_B = $df+"AT_B"
			
			AT_B[ 1 ] = ( yend - ybgn ) / ( bend - bbgn ) // slope m
			AT_B[ 0 ] = ybgn - AT_B[ 1 ] * bbgn // offset b
			
			if ( WaveExists( $xWave ) )
			
				pbgn = z_NMX2Pnt( dwName, xWave, bbgn )
				pend = z_NMX2Pnt( dwName, xWave, bend )
			
				if ( pbgn >= pend )
					return NaN
				endif
				
				FuncFit /Q/W=2/N NMArtFxnLine AT_B $dwName[ pbgn, pend ] /X=$xWave[ pbgn, pend ]
			
			else
			
				FuncFit /Q/W=2/N NMArtFxnLine AT_B $dwName( bbgn, bend )
				
			endif
			
			AT_FitB = NMArtFxnLine( AT_B, AT_FitX )
			
			v1 = AT_B[ 0 ] // b
			v2 = AT_B[ 1 ] // m
			chisqr = V_chisq
			
			break
			
		case "Zero":
		
			Make /O/N=1 $df+"AT_B" = 0
		
			AT_FitB = 0
			v1 = 0
			
			for ( pcnt = pbgn ; pcnt <= pend ; pcnt += 1 )
				ssd += ( dtemp[ pcnt ] - v1 ) ^ 2
			endfor
			
			chisqr = ssd
			V_FitError = 0
			
			break
			
		default:
			return NaN
		
	endswitch
	
	pbgn = 0
	pend = z_NMX2Pnt( df+"AT_FitB", xWave, bbgn ) - 1
	
	if ( ( pend > 0 ) && ( pend < numpnts( AT_FitB ) ) )
		AT_FitB[ pbgn, pend ] = Nan
	endif
	
	tmax = artTime + subtractWin
	tlimit = z_NextArtTimeLimit( artNum )
	tmax = min( tmax, tlimit )
	
	pbgn = z_NMX2Pnt( df+"AT_FitB", xWave, tmax ) + 1
	pend = numpnts( AT_FitB ) - 1
	
	if ( ( pbgn > 0 ) && ( pbgn < numpnts( AT_FitB ) ) )
		if ( ( pend > pbgn ) && ( pend < numpnts( AT_FitB ) ) )
			AT_FitB[ pbgn, pend ] = Nan
		endif
	endif
	
	if ( WaveExists( $df+"AT_FitB" ) )
	
		pbgn = z_NMX2Pnt( df+"AT_FitB", xWave, artTime )
	
		Wave ywave = $df+"AT_TimeY"
	
		ywave[ artNum ] = AT_FitB[ pbgn ]
	
	endif
	
	if ( update )
		DoUpdate
	endif
	
	SetNMvar( df+"BslnValue1", v1 ) // tab display
	SetNMvar( df+"BslnValue2", v2 )
	SetNMvar( df+"BslnChi", chisqr )
	
	KillWaves /Z W_Sigma
	
	return V_FitError
	
End // z_FitBaseline

//****************************************************************

Static Function z_FitArtefact( [ update ] )
	Variable update

	Variable pbgn, pend, y0, ybgn, chisqr, tmax, tlimit
	Variable fit_ss, bsln_ss, data_stdv
	Variable V_FitError, V_FitQuitReason, V_chisq
	String hstr
	
	String xWave = NMXWave()
	
	String df = NMArtDF
	
	Variable tbgn = NumVarOrDefault( df+"Xbgn", NaN ) // drag wave variable
	Variable tend = NumVarOrDefault( df+"Xend", NaN )
	
	if ( ( numtype( tbgn * tend ) > 0 ) || ( tbgn >= tend ) )
		return NaN
	endif
	
	Variable a1 = NumVarOrDefault( df+"fit_a1", NaN )
	Variable t1 = NumVarOrDefault( df+"fit_t1", NaN )
	Variable a2 = NumVarOrDefault( df+"fit_a2", NaN )
	Variable t2 = NumVarOrDefault( df+"fit_t2", NaN )
	
	Variable t1_hold = NMArtVarGet( "t1_hold" )
	Variable t2_hold = NMArtVarGet( "t2_hold" )
	
	Variable artNum = NMArtVarGet( "ArtNum" )
	
	Variable waveNum = CurrentNMWave()
	
	String dwName = ChanDisplayWave( -1 )
	
	if ( !WaveExists( $dwName ) )
		return NaN
	endif
	
	Wave dtemp = $dwName
	Wave AT_Fit = $df+"AT_Fit"
	Wave AT_FitX = $df+"AT_FitX" // created by z_FitBaseline
	Wave AT_FitB = $df+"AT_FitB"
	
	Variable artTime = NMArtVarGet( "ArtTime" )
	Variable subtractWin = NMArtVarGet( "SubtractWin" )
	Variable bslnConvergeNstdv = NMArtVarGet( "BslnConvergeNstdv" )
	Variable bslnConvergeWin = NMArtVarGet( "BslnConvergeWin" )
	
	String exp_fxn = NMArtStrGet( "ArtFitFxn" )
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	pbgn = z_NMX2Pnt( dwName, xWave, tbgn )
	pend = z_NMX2Pnt( dwName, xWave, tend )
	
	if ( ( pbgn >= 0 ) && ( pbgn < numpnts( dtemp ) ) )
		ybgn = dtemp[ pbgn ]
	else
		return NaN // out of range
	endif
	
	if ( ( pend >= 0 ) && ( pend < numpnts( dtemp ) ) )
		// ok
	else
		return NaN // out of range
	endif
	
	WaveStats /Q/R=[ pend - 10, pend ] $dwName
	
	y0 = V_avg
	
	// first do 1-exp fit
	
	Make /T/O/N=0 FitConstraints = ""
	
	z_FitConstraints( "Exp", FitConstraints )
	
	Make /O/N=4 $df+"AT_A" // must be n=4 for 1-exp fit
	
	Wave AT_A = $df+"AT_A"
	
	AT_A[ 0 ] = tbgn // hold
	AT_A[ 1 ] = y0 // hold // during fit y0 is set to baseline function stored in AT_B
	
	hstr = "11"
	
	AT_A[ 2 ] = ybgn - y0
	
	if ( ( numtype( t1_hold ) == 0 ) && ( t1_hold > 0 ) )
		AT_A[ 3 ] = t1_hold
		hstr += "01"
	else
		AT_A[ 3 ] = ( tend - tbgn ) / 5
		hstr += "00"
	endif
	
	//V_FitError = 0
	//V_FitQuitReason = 0
	
	if ( WaveExists( $xWave ) )
	
		pbgn = z_NMX2Pnt( dwName, xWave, tbgn )
		pend = z_NMX2Pnt( dwName, xWave, tend )
		
		if ( pbgn >= pend )
			return NaN
		endif
		
		FuncFit /Q/W=2/N/H=hstr NMArtFxnExp AT_A $dwName[ pbgn, pend ] /C=FitConstraints /X=$xWave[ pbgn, pend ]
		
	else
	
		FuncFit /Q/W=2/N/H=hstr NMArtFxnExp AT_A $dwName( tbgn, tend ) /C=FitConstraints
		
	endif
	
	if ( V_FitError != 0 )
		NMHistory( "1-exp fit error = " + num2str( V_FitError ) )
		AT_Fit = Nan
		SetNMvar( df+"DcayValue1", NaN )
		SetNMvar( df+"DcayValue2", NaN )
		SetNMvar( df+"DcayChi", NaN )
		return V_FitError
	endif
	
	a1 = AT_A[ 2 ]
	t1 = AT_A[ 3 ]
	chisqr = V_chisq
	
	if ( StringMatch( exp_fxn, "2Exp" ) ) // fit 2-exp
	
		Make /T/O/N=0 FitConstraints = ""
	
		z_FitConstraints( exp_fxn, FitConstraints )
	
		Redimension /N=6 AT_A // must be n=6 for 2-exp fit
		
		a2 = a1 * 0.5
		
		if ( ( numtype( t2_hold ) == 0 ) && ( t2_hold > 0 ) )
			t2 = t2_hold
			hstr += "01"
		else
			t2 = t1 * 2
			hstr += "00"
		endif
		
		AT_A[ 4 ] = a2
		AT_A[ 5 ] = t2
		
		//print a1, t1, a2, t2
		
		//V_FitError = 0
		//V_FitQuitReason = 0
		//V_chisq = 0
		
		if ( WaveExists( $xWave ) )
		
			pbgn = z_NMX2Pnt( dwName, xWave, tbgn )
			pend = z_NMX2Pnt( dwName, xWave, tend )

			if ( pbgn >= pend )
				return NaN
			endif
			
			FuncFit /Q/W=2/N/H=hstr NMArtFxnExp2 AT_A $dwName[ pbgn, pend ] /C=FitConstraints /X=$xWave[ pbgn, pend ]
		
		else
		
			FuncFit /Q/W=2/N/H=hstr NMArtFxnExp2 AT_A $dwName( tbgn, tend ) /C=FitConstraints
			
		endif
		
		if ( V_FitError != 0 )
			NMHistory( "2-exp fit error = " + num2str( V_FitError ) + ", reason = " + num2str( V_FitQuitReason ) )
			AT_Fit = Nan
			SetNMvar( df+"DcayValue1", NaN )
			SetNMvar( df+"DcayValue2", NaN )
			SetNMvar( df+"DcayChi", NaN )
			return V_FitError
		endif
		
		a1 = AT_A[ 2 ]
		t1 = AT_A[ 3 ]
		a2 = AT_A[ 4 ]
		t2 = AT_A[ 5 ]
		chisqr = V_chisq
		
		//print a1, t1, a2, t2
	
	endif
	
	if ( StringMatch( exp_fxn, "Exp" ) )
		AT_Fit = NMArtFxnExp( AT_A, AT_FitX )
		SetNMvar( df+"DcayValue1", a1 ) // tab
		SetNMvar( df+"DcayValue2", t1 )
		SetNMvar( df+"DcayChi", chisqr )
		SetNMvar( df+"fit_a1", a1 ) // save for next fit
		SetNMvar( df+"fit_t1", t1 )
		SetNMvar( df+"fit_a2", NaN )
		SetNMvar( df+"fit_t2", NaN )
	elseif ( StringMatch( exp_fxn, "2Exp" ) )
		AT_Fit = NMArtFxnExp2( AT_A, AT_FitX )
		SetNMvar( df+"DcayValue1", t1 ) // tab
		SetNMvar( df+"DcayValue2", t2 )
		SetNMvar( df+"DcayChi", chisqr )
		SetNMvar( df+"fit_a1", a1 ) // save for next fit
		SetNMvar( df+"fit_t1", t1 )
		SetNMvar( df+"fit_a2", a2 )
		SetNMvar( df+"fit_t2", t2 )
	else
		return NaN
	endif
	
	//if ( numpnts( AT_Fit ) == 0 )
	//	return NaN
	//endif
	
	pbgn = z_NMX2Pnt( dwName, xWave, tbgn )
	
	if ( ( pbgn > 1 ) && ( pbgn <= numpnts( AT_Fit ) ) )
		AT_Fit[ 0, pbgn - 1 ] = Nan
	endif
	
	tmax = artTime + subtractWin
	tlimit = z_NextArtTimeLimit( artNum )
	tmax = min( tmax, tlimit )
	
	pbgn = z_NMX2Pnt( dwName, xWave, tmax ) + 1
	pend = numpnts( $dwName ) - 1
	
	if ( ( pbgn > 1 ) && ( pbgn < numpnts( AT_Fit ) ) )
		if ( ( pend > pbgn ) && ( pend < numpnts( AT_Fit ) ) )
			AT_Fit[ pbgn, pend ] = Nan
		endif
	endif
	
	// convergence test - does fit decay to baseline?
	
	pend = pbgn
	pbgn = z_NMX2Pnt( dwName, xWave, tmax - bslnConvergeWin )
	
	WaveStats /Q/R=[ pbgn, pend ]/Z AT_Fit
	
	fit_ss = V_avg
	
	WaveStats /Q/R=[ pbgn, pend ]/Z AT_FitB
	
	bsln_ss = V_avg
	
	WaveStats /Q/R=[ pbgn, pend ]/Z $dwName
	
	data_stdv = V_sdev
	
	if ( ( fit_ss < bsln_ss - bslnConvergeNstdv * data_stdv ) || ( fit_ss > bsln_ss + bslnConvergeNstdv * data_stdv ) )
		AT_Fit = Nan // fit does not converge to baseline
		V_FitError = -1
		//Print "wave " + num2str( waveNum )  + ", #" + num2str( artNum ) + " : decay fit did not converge to baseline"
	endif
	
	if ( update )
		DoUpdate
	endif
	
	KillWaves /Z W_sigma
	KillWaves /Z FitConstraints
	
	return V_FitError

End // z_FitArtefact

//****************************************************************

Static Function z_FitConstraints( exp_fxn, cwave )
	String exp_fxn
	Wave /T cwave // where constraints are saved

	Variable icnt, items
	String cList = ""
	
	Variable t1_min = NMArtVarGet( "t1_min" )
	Variable t1_max = NMArtVarGet( "t1_max" )
	Variable t2_min = NMArtVarGet( "t2_min" )
	Variable t2_max = NMArtVarGet( "t2_max" )
	
	if ( ( numtype( t1_min ) == 0 ) && ( t1_min > 0 ) )
		cList += "K3 > " + num2str( t1_min ) + ";"
	endif
	
	if ( ( numtype( t1_max ) == 0 ) && ( t1_max > 0 ) )
		cList += "K3 < " + num2str( t1_max ) + ";"
	endif
	
	if ( StringMatch( exp_fxn, "2Exp" ) )
		
		if ( ( numtype( t2_min ) == 0 ) && ( t2_min > 0 ) )
			cList += "K5 > " + num2str( t2_min ) + ";"
		endif
		
		if ( ( numtype( t2_max ) == 0 ) && ( t2_max > 0 ) )
			cList += "K5 < " + num2str( t2_max ) + ";"
		endif
	
	endif
	
	items = ItemsInList( cList )
	
	if ( items == 0 )
		return 0
	endif
	
	Redimension /N=( items ) cwave
	
	for ( icnt = 0 ; icnt < items ; icnt += 1 )
		cwave[ icnt ] = StringFromList( icnt, cList )
	endfor
	
	return 0

End // z_FitConstraints

//****************************************************************

Static Function z_NextArtTimeLimit( artNum )
	Variable artNum

	String df = NMArtDF
	
	String dwName = ChanDisplayWave( -1 )
	
	if ( !WaveExists( $dwName ) || !WaveExists( $df+"AT_TimeX" ) )
		return NaN
	endif
	
	Variable next = artNum + 1
	
	if ( ( next >= 0 ) && ( next < numpnts( $df+"AT_TimeX" ) ) )
	
		Wave twave = $df+"AT_TimeX"
		
		return twave[ next ]
		
	endif
	
	return rightx( $dwName )

End // z_NextArtTimeLimit

//****************************************************************

Function NMArtFitSubtract( [ artNum, update, history ] )
	Variable artNum
	Variable update // used during Fit All
	Variable history

	Variable pcnt, pbgn, pend, yvalue, tmax, tlimit, saveArt = 0
	String vlist = "", df = NMArtDF
	
	String xWave = NMXwave()
	
	Variable bbgn = NumVarOrDefault( df+"BslnXbgn", NaN ) // drag wave variable
	Variable bend = NumVarOrDefault( df+"BslnXend", NaN )
	
	Variable abgn = NumVarOrDefault( df+"Xbgn", NaN ) // drag wave variable
	Variable aend = NumVarOrDefault( df+"Xend", NaN )
	
	Variable artTime = NMArtVarGet( "ArtTime" )
	
	Variable bslnDT = NMArtVarGet( "BslnDT" )
	Variable bslnSubtract = NMArtVarGet( "BslnSubtract" )
	Variable subtractWin = NMArtVarGet( "SubtractWin" )
	Variable saveSubtractedArt = NMArtVarGet( "SaveSubtractedArt" )
	
	String currentWavePrefix = CurrentNMWavePrefix()
	String dwName = ChanDisplayWave( -1 )
	String noArtName = NMArtSubWaveName( "no_art" )
	String artName = NMArtSubWaveName( "art" )
	String fwName = NMArtSubWaveName( "finished" )
	
	if ( ParamIsDefault( artNum ) )
		artNum = NMArtVarGet( "ArtNum" )
	else
		vlist = NMCmdNumOptional( "artNum", artNum, vlist )
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	else
		vlist = NMCmdNumOptional( "update", update, vlist )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( NMArtVarGet( "FitFlag" ) != 2 )
		return -1
	endif
	
	if ( numtype( artNum * artTime * bslnDT * subtractWin ) > 0 )
		return -1
	endif
	
	if ( !WaveExists( $noArtName ) || !WaveExists( $df+"AT_Fit" ) || !WaveExists( $fwName ) )
		return -1
	endif

	Wave dtemp = $dwName
	Wave wtemp = $noArtName
	Wave ftemp = $fwName
	
	if ( saveSubtractedArt && WaveExists( $artName ) )
		Wave wArt = $artName
		saveArt = 1
	endif
	
	Wave AT_Fit = $df+"AT_Fit"
	Wave AT_FitB = $df+"AT_FitB"
	
	if ( numpnts( $noArtName ) != numpnts( AT_FitB ) )
		return -1
	endif
	
	if ( ( artNum < 0 ) || ( artNum >= DimSize( ftemp, 0 ) ) )
		return -1
	endif
	
	// zero artefact
	
	pbgn = z_NMX2Pnt( noArtName, xWave, artTime - bslnDT )
	pend = z_NMX2Pnt( noArtName, xWave, abgn ) - 1
	
	if ( ( pbgn < 0 ) || ( pbgn >= numpnts( $noArtName ) ) )
		return -1
	endif
	
	if ( ( pend < 0 ) || ( pend >= numpnts( $noArtName ) ) )
		return -1
	endif

	for ( pcnt = pbgn; pcnt <= pend; pcnt += 1 )
		
		if ( saveArt )
			wArt[ pcnt ] = wtemp[ pcnt ] // save original value before updating
		endif
		
		wtemp[ pcnt ] = AT_FitB[ pcnt ] // artefact before tbgn becomes baseline
		
	endfor
	
	// subtract exponential fit and baseline fit
	
	tmax = artTime + subtractWin
	tlimit = z_NextArtTimeLimit( artNum )
	tmax = min( tmax, tlimit )
	
	pbgn = z_NMX2Pnt( noArtName, xWave, abgn )
	pend = z_NMX2Pnt( noArtName, xWave, tmax )

	for ( pcnt = pbgn; pcnt < pend; pcnt += 1 )
	
		if ( bslnSubtract )
			yvalue = AT_Fit[ pcnt ]
		else
			yvalue = AT_Fit[ pcnt ] - AT_FitB[ pcnt ]
		endif
		
		if ( saveArt )
			wArt[ pcnt ] = yvalue
		endif
		
		//if ( bslnSubtract )
		//	wtemp[ pcnt ] = dtemp[ pcnt ] - yvalue - AT_FitB[ pcnt ]
		//	wtemp[ pcnt ] = dtemp[ pcnt ] - ( AT_Fit[ pcnt ] - AT_FitB[ pcnt ] ) - AT_FitB[ pcnt ]
		//	wtemp[ pcnt ] = dtemp[ pcnt ] - AT_Fit[ pcnt ] + AT_FitB[ pcnt ] - AT_FitB[ pcnt ]
		//	wtemp[ pcnt ] = dtemp[ pcnt ] - AT_Fit[ pcnt ]
		//else
		//	wtemp[ pcnt ] = dtemp[ pcnt ] - yvalue
		//endif
		
		wtemp[ pcnt ] = dtemp[ pcnt ] - yvalue
		
	endfor
	
	if ( artNum < DimSize( ftemp, 0 ) )
	
		ftemp[ artNum ][ %onset ] = artTime
		ftemp[ artNum ][ %finished ] = 1
		
		ftemp[ artNum ][ %b_bgn ] = bbgn
		ftemp[ artNum ][ %b_end ] = bend
		
		ftemp[ artNum ][ %a_bgn ] = abgn
		ftemp[ artNum ][ %a_end ] = aend
		
		if ( DimSize( ftemp, 1 ) == 12 )
		
			ftemp[ artNum ][ %b_k1 ] = NumVarOrDefault( df+"BslnValue1", NaN )
			ftemp[ artNum ][ %b_k2 ] = NumVarOrDefault( df+"BslnValue2", NaN )
			ftemp[ artNum ][ %b_chi ] = NumVarOrDefault( df+"BslnChi", NaN )
			
			ftemp[ artNum ][ %a_k1 ] = NumVarOrDefault( df+"DcayValue1", NaN )
			ftemp[ artNum ][ %a_k2 ] = NumVarOrDefault( df+"DcayValue2", NaN )
			ftemp[ artNum ][ %a_chi ] = NumVarOrDefault( df+"DcayChi", NaN )
		
		endif
		
		AT_Fit = Nan
		AT_FitB = Nan
		SetNMvar( df+"FitFlag", NaN )
		
	endif
	
	Duplicate /O $noArtName $df+"AT_Display"
	
	if ( update )
		DoUpdate
	endif
	
	z_UpdateCheckboxSubtract( artNum )
	
	return 0

End // NMArtFitSubtract

//****************************************************************

Function NMArtFitRestore( [ artNum, history ] )
	Variable artNum
	Variable history

	Variable pcnt, pbgn, pend, pmax, bend, abgn, tend, dt, saveArt = 0
	String vlist = "", df = NMArtDF
	
	//Variable p_extra = 5
	
	Variable saveSubtractedArt = NMArtVarGet( "SaveSubtractedArt" )
	Variable bslnDT = NMArtVarGet( "BslnDT" )
	
	String dwName = ChanDisplayWave( -1 )
	String noArtName = NMArtSubWaveName( "no_art" )
	String artName = NMArtSubWaveName( "art" )
	String fwName = NMArtSubWaveName( "finished" )
	
	String xWave = NMXwave()
	
	if ( ParamIsDefault( artNum ) )
		artNum = NMArtVarGet( "ArtNum" )
	else
		vlist = NMCmdNumOptional( "artNum", artNum, vlist )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( !WaveExists( $noArtName ) || !WaveExists( $dwName ) || !WaveExists( $fwName ) )
		return -1
	endif
	
	if ( numpnts( $noArtName ) != numpnts( $dwName ) )
		return -1
	endif
	
	Wave dtemp = $dwName
	Wave wtemp = $noArtName
	Wave ftemp = $fwName
	
	dt = deltax( dtemp )
	
	if ( saveSubtractedArt && WaveExists( $artName ) )
		Wave wArt = $artName
		saveArt = 1
	endif
	
	if ( ( numtype( artNum ) > 0 ) || ( artNum < 0 ) || ( artNum >= DimSize( ftemp, 0 ) ) )
		return -1
	endif
	
	bend = ftemp[ artNum ][ %b_end ]
	abgn = ftemp[ artNum ][ %a_bgn ]
	
	if ( numtype( bend * abgn ) > 0 )
		return -1
	endif
	
	pbgn = z_NMX2Pnt( dwName, xWave, bend )
	pend = z_NMX2Pnt( dwName, xWave, abgn ) - 1
	pmax = numpnts( $dwName )
	
	if ( ( pbgn < 0 ) || ( pbgn >= pmax ) )
		return -1
	endif
	
	if ( ( pend < 0 ) || ( pend >= pmax ) )
		return -1
	endif
	
	for ( pcnt = pbgn; pcnt <= pend; pcnt += 1 ) // restore artefact
	
		wtemp[ pcnt ] = dtemp[ pcnt ]
	
		if ( saveArt )
			wArt[ pcnt ] = NaN
		endif
		
	endfor
	
	pbgn = pend + 1
	
	if ( artNum == DimSize( ftemp, 0 ) - 1 ) // last artefact
	
		pend = pmax - 1
		
	else
	
		tend = z_NextArtTimeLimit( artNum )
		pend = z_NMX2Pnt( dwName, xWave, tend )
		
		if ( !saveArt )
			pend -= bslnDT / dt
		endif
		
	endif
	
	pend = min( pend, pmax - 1 )
	
	if ( pbgn >= pend )
		return -1
	endif
	
	if ( ( pend < 0 ) || ( pend >= pmax ) )
		return -1
	endif
	
	 // restore post-artefact subtraction
	
	if ( saveArt )
	
		for ( pcnt = pbgn; pcnt <= pend; pcnt += 1 )
			if ( numtype( wArt[ pcnt ] ) == 0 )
				wtemp[ pcnt ] += wArt[ pcnt ]
				wArt[ pcnt ] = NaN
			endif
		endfor
	
	else
	
		for ( pcnt = pbgn; pcnt <= pend; pcnt += 1 )
			wtemp[ pcnt ] = dtemp[ pcnt ]
		endfor
	
	endif
	
	Duplicate /O wtemp $df+"AT_Display"
	
	//ftemp[ artNum ][ %onset ] = NaN
	ftemp[ artNum ][ %finished ] = NaN
	
	if ( NMArtVarGet( "DragWaveAll" ) )
	
		ftemp[ artNum ][ %b_bgn ] = NaN
		ftemp[ artNum ][ %b_end ] = NaN
			
		ftemp[ artNum ][ %a_bgn ] = NaN
		ftemp[ artNum ][ %a_end ] = NaN
	
	endif
	
	if ( DimSize( ftemp, 1 ) == 12 )
		
		ftemp[ artNum ][ %b_k1 ] = NaN
		ftemp[ artNum ][ %b_k2 ] = NaN
		ftemp[ artNum ][ %b_chi ] = NaN
		
		ftemp[ artNum ][ %a_k1 ] = NaN
		ftemp[ artNum ][ %a_k2 ] = NaN
		ftemp[ artNum ][ %a_chi ] = NaN
		
	endif
	
	z_UpdateCheckboxSubtract( artNum )
	
	if ( NMArtVarGet( "AutoFit" ) )
		NMArtFit( artNum=artNum )
	endif

End // NMArtFitRestore

//****************************************************************

Function NMArtFxnLine( w, x )
	Wave w // 2 points
	// w[ 0 ] = offset b
	// w[ 1 ] = slope m
	Variable x
	
	return ( w[ 0 ] + w[ 1 ] * x )

End // NMArtFxnLine

//****************************************************************

Function NMArtFxnExp( w, x )
	Wave w // 4 points
	// w[ 0 ] = x0
	// w[ 1 ] = y0
	// w[ 2 ] = a1
	// w[ 3 ] = t1
	Variable x
	Variable y, y0
	
	Wave AT_B = $NMArtDF+"AT_B" // baseline values
	
	switch( numpnts( AT_B ) )
		case 0: // baseline fit does not exist so this is normal exp fit
			y0 = w[ 1 ]
			break
		case 1: // baseline is constant
			y0 = AT_B[ 0 ]
			break
		case 2: // baseline is line
			y0 = AT_B[ 0 ] + AT_B[ 1 ] * x
			break
		case 4: // baseline is single exp
			y0 = AT_B[ 1 ] + AT_B[ 2 ] * exp( -( x - AT_B[ 0 ] ) / AT_B[ 3 ] )
			break
		case 6: // baseline is double exp
			y0 = AT_B[ 1 ] + AT_B[ 2 ] * exp( -( x - AT_B[ 0 ] ) / AT_B[ 3 ] ) + AT_B[ 4 ] * exp( -( x - AT_B[ 0 ] ) / AT_B[ 5 ] )
			break
	endswitch
	
	y = y0 + w[ 2 ] * exp( -( x - w[ 0 ] )/ w[ 3 ] )
	
	return y

End // NMArtFxnExp

//****************************************************************

Function NMArtFxnExp2( w, x )
	Wave w // 6 points
	// w[ 0 ] = x0
	// w[ 1 ] = y0
	// w[ 2 ] = a1
	// w[ 3 ] = t1
	// w[ 4 ] = a2
	// w[ 5 ] = t2
	Variable x
	
	Variable y, y0
	Variable a1, t1, a2, t2
	
	Wave AT_B = $NMArtDF+"AT_B" // baseline values
	
	//if ( w[ 5 ] < w[ 3 ] ) // keep t1 < t2 // not sure this method words
		
	//	a1 = w[ 4 ]
	//	t1 = w[ 5 ]
	//	a2 = w[ 2 ]
	//	t2 = w[ 3 ]
		
	//	w[ 2 ] = a1
	//	w[ 3 ] = t1
	//	w[ 4 ] = a2
	//	w[ 5 ] = t2
	
	//endif
	
	//if ( w[ 2 ] * w[ 4 ] < 0 ) // a1 and a2 have opposite signs
	//	w[ 4 ] *= w[ 2 ] / abs( w[ 2 ] ) // keep the same sign // not sure this method words
	//endif
	
	switch( numpnts( AT_B ) )
		case 0: // baseline fit does not exist so this is normal exp fit
			y0 = w[ 1 ]
			break
		case 1: // baseline is constant
			y0 = AT_B[ 0 ]
			break
		case 2: // baseline is line
			y0 = AT_B[ 0 ] + AT_B[ 1 ] * x
			break
		case 4: // baseline is single exp
			y0 = AT_B[ 1 ] + AT_B[ 2 ] * exp( -( x - AT_B[ 0 ] ) / AT_B[ 3 ] )
			break
		case 6: // baseline is double exp
			y0 = AT_B[ 1 ] + AT_B[ 2 ] * exp( -( x - AT_B[ 0 ] ) / AT_B[ 3 ] ) + AT_B[ 4 ] * exp( -( x - AT_B[ 0 ] ) / AT_B[ 5 ] )
			break
	endswitch
	
	y = y0 + w[ 2 ] * exp( -( x - w[ 0 ] ) / w[ 3 ] ) + w[ 4 ] * exp( -( x - w[ 0 ] ) / w[ 5 ] )
	
	return y

End // NMArtFxnExp2

//****************************************************************

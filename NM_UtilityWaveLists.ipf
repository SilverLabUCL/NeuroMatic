#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma hide = 1

// SetIgorOption IndependentModuleDev=1 (unhide)

//****************************************************************
//****************************************************************
//
//	NeuroMatic: data aquisition, analyses and simulation software that runs with the Igor Pro environment
//	Copyright (C) 2017 Jason Rothman
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <https://www.gnu.org/licenses/>.
//
//	Contact Jason@ThinkRandom.com
//	www.NeuroMatic.ThinkRandom.com
//
//****************************************************************
//****************************************************************
//
//	Utility Functions that work with Wave Lists
//
//	String folder // NM data folder where waves in wList exist
//	String wList // list of input wave names with ";" seperator ( full-path does not work, use folder )
//	String xWave // name of x-scale wave of wList, only for x-y paired data sets
//	Variable xbgn, xend // x-axis window begin and end
//
//****************************************************************
//****************************************************************

Constant NMGraphAxisStandoff = 0 // ( 0 ) no ( 1 ) yes
Constant NMGraphShowInfo = 0 // ( 0 ) no ( 1 ) yes
StrConstant NMInterpolateAlg = "cubic spline" // "linear" or "cubic spline" or "smoothing spline"

StrConstant NMAlignAtList = "zero;max alignment value;min alignment value;average alignment value;"

Static Constant XaxisStatsTolerance = 1e-4 // for dx, leftx and rightx comparisons

//****************************************************************
//****************************************************************

Structure NMParams

	// inputs

	String fxn // function name
	String paramList // list of parameters used in function execution
	
	String folder // NM data folder where waves in wList exist
	String wList // list of input wave names with ";" seperator ( full-path does not work, use folder )
	String xWave // name of x-scale wave of wList, only for x-y paired data sets
	
	String wavePrefix // wave prefix ( e.g. "Record" )
	String prefixFolder // e.g. "root:nmFolder0:NMPrefix_Record:"
	Variable chanNum // channel number
	Variable transforms // use channel transforms ( 0 ) no ( 1 ) yes
	String waveSelect // wave select ( e.g. "All" or "Set1" )
	String xLabel, yLabel // x-axis and y-axis labels
	
	// outputs
	
	String successList // list of names that successfully pass thru function execution
	String failureList // list of names that failed to pass thru function execution
	String newList // list of names of things created in function ( e.g. waves, variables, strings )
	String windowList // list of windows made

EndStructure // NMParams

//****************************************************************
//****************************************************************

Function NMParamsNull( nm )
	STRUCT NMParams &nm
	
	nm.fxn = ""; nm.paramList = ""
	nm.folder = ""; nm.wList = ""; nm.xWave = ""
	nm.wavePrefix = ""; nm.prefixFolder = ""; nm.chanNum = NaN; nm.transforms = 0; nm.waveSelect = ""
	nm.xLabel = ""; nm.yLabel = ""
	nm.successList = ""; nm.failureList = ""; nm.newList = ""; nm.windowList = ""
	
End // NMParamsNull

//****************************************************************
//****************************************************************

Function NMParamVarAdd( varName, varValue, nm [ integer ])
	String varName
	Variable varValue
	STRUCT NMParams &nm
	Variable integer
	
	if ( integer )
		nm.paramList += varName + "=" + num2istr( varValue ) + ";"
	else
		nm.paramList += varName + "=" + num2str( varValue ) + ";"
	endif
	
End // NMParamVarAdd

//****************************************************************
//****************************************************************

Function NMParamStrAdd( strName, strValue, nm )
	String strName
	String strValue
	STRUCT NMParams &nm
	
	nm.paramList += strName + "=" + strValue + ";"
	
End // NMParamStrAdd

//****************************************************************
//****************************************************************

Function NMParamsInit( folder, wList, nm [ fxn, paramList, xWave ] )
	String folder, wList
	STRUCT NMParams &nm
	String fxn, paramList, xWave
	
	String wName
	
	if ( ItemsInList( wList ) == 0 )
		return 1 // error
	endif
	
	if ( strlen( folder ) == 0 )
	
		folder = NMParent( wList )
		
		if ( ItemsInList( folder ) > 1 )
			return NMError( 90, GetRTStackInfo( 2 ), "wave input list contains multiple parent directories", "" )
		endif
		
	endif
	
	folder = CheckNMFolderPath( folder )
	
	if ( !DataFolderExists( folder ) )
		return NMError( 30, GetRTStackInfo( 2 ), "folder", folder )
	endif
	
	if ( ParamIsDefault( xWave ) )
	
		xWave = ""
		
	elseif ( strlen( xWave ) > 0 )
	
		if ( NMUtilityWaveTest( folder + xWave ) != 0 )
			return NMError( 1, GetRTStackInfo( 2 ), "xWave", xWave )
		endif
		
		wName = StringFromList( 0, wList )
		
		if ( numpnts( $folder + xWave ) != numpnts( $folder + wName ) )
			return NMError( 5, GetRTStackInfo( 2 ), "xWave", xWave )
		endif
		
	endif
	
	NMParamsNull( nm )
	
	nm.folder = folder
	nm.wList = NMChild( wList )
	nm.xWave = xWave
	
	if ( ParamIsDefault( fxn ) )
		nm.fxn = GetRTStackInfo( 2 )
	else
		nm.fxn = fxn
	endif
	
	if ( !ParamIsDefault( paramList ) )
		nm.paramList = NMCmdVarListConvert( paramList )
	endif
	
	return 0
	
End // NMParamsInit

//****************************************************************
//****************************************************************

Function NMParamsError( nm [ skipWaveList, skipXwave ] )
	STRUCT NMParams &nm
	Variable skipWaveList, skipXwave
	
	Variable wcnt, numWaves, npnts
	String wName, badList = ""
	
	if ( ItemsInList( nm.wList ) == 0 )
		return 1 // error
	endif
	
	if ( !DataFolderExists( nm.folder ) )
		return NMError( 30, GetRTStackInfo( 2 ), "folder", nm.folder )
	endif
	
	if ( !skipWaveList )
	
		for ( wcnt = 0 ; wcnt < ItemsInList( nm.wList ) ; wcnt += 1 )
		
			wName = StringFromList( wcnt, nm.wList )
		
			if ( !WaveExists( $nm.folder + wName ) )
				badList += wName + ";"
			endif
			
		endfor
		
		numWaves = ItemsInList( badList )
		
		if ( numWaves >= 1 )
		
			NMDoAlert( "Abort: the following waves do not exist: " + badList, title = GetRTStackInfo( 2 ) )
			
			return 1 // error
		
		endif
	
	endif
	
	if ( !skipXwave && strlen( nm.xWave ) > 0 ) 
	
		if ( NMUtilityWaveTest( nm.folder + nm.xWave ) != 0 )
			return NMError( 1, GetRTStackInfo( 2 ), "xWave", nm.folder + nm.xWave )
		endif
		
		npnts = GetXstats( "numPnts" , nm.wList, folder = nm.folder )
		
		if ( numpnts( $nm.folder + nm.xWave ) != npnts )
			return NMError( 5, GetRTStackInfo( 2 ), "xWave", nm.folder + nm.xWave )
		endif
		
	endif
	
	return 0 // OK

End // NMParamsError

//****************************************************************
//****************************************************************

Function NMParamsComputeFailures( nm )
	STRUCT NMParams &nm
	
	nm.failureList = RemoveFromList( nm.successList, nm.wList )
	
End // NMParamsComputeFailures

//****************************************************************
//****************************************************************
//
//		Edit Functions
//		Make, Move, Duplicate, Rename, Renumber...
//
//****************************************************************
//****************************************************************

Structure NMMakeStruct

	Variable numWaves, xpnts, dx, ypnts, dy, value, noiseStdv, precision, overwrite
	String xLabel, yLabel

EndStructure

//****************************************************************
//****************************************************************

Function NMMakeStructNull( m )
	STRUCT NMMakeStruct &m

	m.xLabel = ""
	m.yLabel = ""

End

//****************************************************************
//****************************************************************

Function NMMakeError( numWaves, xpnts )
	Variable numWaves, xpnts
	
	if ( ( numtype( numWaves ) > 0 ) || ( numWaves <= 0 ) )
		return NM2Error( 10, "numWaves", num2istr( numWaves ) )
	endif
	
	if ( ( numtype( xpnts ) > 0 ) || ( xpnts <= 0 ) )
		return NM2Error( 10, "xpnts", num2istr( xpnts ) )
	endif
	
	//if ( ( numtype( dx ) > 0 ) || ( dx <= 0 ) )
		//return NM2Error( 10, "dx", num2istr( dx ) )
	//endif
	
	return 0
	
End // NMMakeError

//****************************************************************
//****************************************************************

Function /S NMMake2( nm, m [ history ] )
	STRUCT NMParams &nm // uses nm.folder, nm.wList, nm.wavePrefix, nm.chanNum
	STRUCT NMMakeStruct &m
	Variable history
	
	Variable wcnt, createNames, value = m.value
	String wName
	
	SetNMstr( NMDF + "OutputWaveList", "" )
	
	nm.folder = CheckNMFolderPath( nm.folder )
	
	if ( !DataFolderExists( nm.folder ) )
		return NM2ErrorStr( 30, "folder", nm.folder )
	endif
	
	if ( ItemsInList( nm.wList ) > 0 )
		m.numWaves = ItemsInList( nm.wList )
	elseif ( strlen( nm.wavePrefix ) == 0 )
		return ""
	else
		createNames = 1
	endif
	
	if ( ( numtype( m.dx ) > 0 ) || ( m.dx <= 0 ) )
		m.dx = 1
	endif
	
	if ( ( numtype( m.dy ) > 0 ) || ( m.dy <= 0 ) )
		m.dy = 1
	endif
	
	//if ( m.waveLength > 0 )
		//m.xpnts = m.waveLength / m.dx
	//endif
	
	if ( NMMakeError( m.numWaves, m.xpnts ) != 0 )
		return ""
	endif
	
	NMParamVarAdd( "xpnts", m.xpnts, nm )
	NMParamVarAdd( "dx", m.dx, nm )
	
	if ( ( numtype( m.ypnts ) == 0 ) && ( m.ypnts > 0 ) )
		NMParamVarAdd( "ypnts", m.ypnts, nm )
		NMParamVarAdd( "dy", m.dy, nm )
	endif
	
	NMParamVarAdd( "value", m.value, nm )
	
	if ( m.precision != 2 )
		m.precision = 1
	endif
	
	NMParamVarAdd( "precision", m.precision, nm )
	
	if ( ( numtype( m.noiseStdv ) == 0 ) && ( m.noiseStdv > 0 ) )
		NMParamVarAdd( "noiseStdv", m.noiseStdv, nm )
		value = 0
	endif
	
	for ( wcnt = 0 ; wcnt < m.numWaves ; wcnt += 1 )
	
		if ( createNames )
			wName = GetWaveName( nm.wavePrefix, nm.chanNum, wcnt )
			nm.wList += wName + ";"
		else
			wName = StringFromList( wcnt, nm.wList )
		endif
		
		if ( !m.overwrite && WaveExists( $nm.folder + wName ) )
			continue
		endif
		
		if ( ( numtype( m.ypnts ) == 0 ) && ( m.ypnts > 0 ) )
			if ( m.precision == 2 )
				Make /D/O/N=( m.xpnts, m.ypnts ) $nm.folder + wName = value
			else
				Make /O/N=( m.xpnts, m.ypnts ) $nm.folder + wName = value
			endif
		else
			if ( m.precision == 2 )
				Make /D/O/N=( m.xpnts ) $nm.folder + wName = value
			else
				Make /O/N=( m.xpnts ) $nm.folder + wName = value
			endif
		endif
		
		if ( !WaveExists( $nm.folder + wName ) )
			continue
		endif
		
		nm.successList += wName + ";"
		nm.newList += nm.folder + wName + ";"
		
		Wave wtemp = $nm.folder + wName
		
		SetScale /P x 0, m.dx, wtemp
		
		if ( m.noiseSTDV > 0 )
			wtemp += gnoise( m.noiseSTDV )
		endif
		
		NMNoteType( nm.folder + wName, "NMWave", m.xLabel, m.yLabel, "" )
		NMLoopWaveNote( nm.folder + wName, nm.paramList )
		
	endfor
	
	//NMParamVarAdd( "pnts", m.xpnts, nm, integer = 1 )
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.newList )
	
	return nm.newList
	
End // NMMake2

//****************************************************************
//****************************************************************

Function /S NMMove2( nm, toFolder [ copySets, history ] )
	STRUCT NMParams &nm // uses nm.folder, nm.wList // copySets uses nm.wavePrefix, nm.prefixFolder, nm.chanNum
	String toFolder // where to move selected waves
	Variable copySets // copy Sets and Groups ( 0 ) no ( 1 ) yes
	Variable history
	
	Variable icnt, wcnt, numWaves, numSets
	String wName, newPrefixFolder, fromF, toF, chanChar = "", setsList, setName
	String fromSetVarName, toSetVarName, fromWList, toWList
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	SetNMstr( NMDF + "OutputWaveList", "" )
	
	numWaves = ItemsInList( nm.wList )
	
	toFolder = CheckNMFolderPath( toFolder )
	
	if ( !IsNMDataFolder( toFolder ) )
		return NM2ErrorStr( 30, "toFolder", toFolder )
	endif
	
	if ( StringMatch( nm.folder, toFolder ) )
		return NM2ErrorStr( 33, "toFolder", toFolder )
	endif
	
	NMParamStrAdd( "from", NMChild( nm.folder ), nm )
	NMParamStrAdd( "to", NMChild( toFolder ), nm )
	
	if ( copySets && DataFolderExists( nm.prefixFolder ) && ( strlen( nm.wavePrefix ) > 0 ) && ( numtype( nm.chanNum ) == 0 ) )
	
		newPrefixFolder = NMPrefixFolderDF( toFolder, nm.wavePrefix )
		
		if ( !DataFolderExists( newPrefixFolder ) )
			NewDataFolder $RemoveEnding( newPrefixFolder, ":" )
		endif
		
		chanChar = ChanNum2Char( nm.chanNum )
		fromF = nm.prefixFolder + "Chan" + chanChar
		toF = newPrefixFolder + "Chan" + chanChar
	
		if ( DataFolderExists( fromF ) && !DataFolderExists( toF ) )
			DuplicateDataFolder $fromF, $toF // copy channel graph configurations
		endif
		
		setsList = NMSetsListAll( prefixFolder = nm.prefixFolder )
	
		numSets = ItemsInList( setsList )
	
	endif
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		wName = StringFromList( wcnt, nm.wList )
		
		if ( WaveExists( $toFolder + wName ) )
			continue // wave name conflict
		endif
		
		MoveWave $( nm.folder + wName ) $( toFolder + wName )
		
		if ( !WaveExists( $nm.folder + wName ) && WaveExists( $toFolder + wName ) )
			// moved
		else
			continue
		endif
		
		NMLoopWaveNote( toFolder + wName, nm.paramList )
		
		nm.successList += wName + ";"
		nm.newList += toFolder + wName + ";"
		
		for ( icnt = 0 ; icnt < numSets ; icnt += 1 )
	
			setName = StringFromList( icnt, setsList )
			
			fromSetVarName = nm.prefixFolder + setName + NMSetsListSuffix + chanChar
			toSetVarName = newPrefixFolder + setName + NMSetsListSuffix + chanChar
			
			fromWList = StrVarOrDefault( fromSetVarName, "" )
			
			if ( WhichListItem( wName, fromWList ) >= 0 )
				toWList = StrVarOrDefault( toSetVarName, "" )
				toWList = NMAddToList( wName, toWList, ";" )
				SetNMstr( toSetVarName, toWList )
			endif
	
		endfor
		
	endfor
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.newList )
	
	return nm.newList
	
End // NMMove2

//****************************************************************
//****************************************************************

Function /S NMDuplicate( wList [ folder, xWave, xbgn, xend, toFolder, newPrefix, overwrite, deprecation ] )
	String wList, folder, xWave // see description at top
	Variable xbgn, xend // x-axis window begin and end
	String toFolder // copy waves to this folder
	String newPrefix // new wave prefix of duplicated waves ( must specify if there is no toFolder )
	Variable overwrite, deprecation
	
	STRUCT NMParams nm
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( StringMatch( wList, "_ALL_" ) )
		wList = NMFolderWaveList( folder, "*", ";", "", 0 )
	endif
	
	if ( NMParamsInit( folder, wList, nm, xWave = xWave ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( ParamIsDefault( toFolder ) )
	
		if ( ParamIsDefault( newPrefix ) || ( strlen( newPrefix ) == 0 ) )
			return NM2ErrorStr( 21, "newPrefix", "" )
		endif
		
		toFolder = nm.folder
	
	else
	
		toFolder = CheckNMFolderPath( toFolder )
		
		if ( !DataFolderExists( toFolder ) ) // create new NM folder
		
			toFolder = NMChild( toFolder )
			NMFolderNew( toFolder, setCurrent = 0 )
			
			if ( IsNMDataFolder( toFolder ) )
				toFolder = CheckNMFolderPath( toFolder )
			else
				return NM2ErrorStr( 30, "toFolder", toFolder )
			endif
			
		endif
		
		if ( ParamIsDefault( newPrefix ) )
			newPrefix = ""
		endif
		
	endif
	
	if ( StringMatch( nm.folder, toFolder ) && ( strlen( newPrefix ) == 0 ) )
		return NM2ErrorStr( 21, "newPrefix", "" ) // cannot overwrite self
	endif
	
	return NMDuplicate2( nm, xbgn = xbgn, xend = xend, toFolder = toFolder, newPrefix = newPrefix, overwrite = overwrite )
	
End // NMDuplicate

//****************************************************************
//****************************************************************

Function /S NMDuplicate2( nm [ xbgn, xend, toFolder, newPrefix, overwrite, copySets, history ] )
	STRUCT NMParams &nm // uses nm.folder, nm.wList, nm.xWave // copySets uses nm.wavePrefix, nm.prefixFolder, nm.chanNum
	Variable xbgn, xend // x-axis window begin and end
	String toFolder // copy waves to this folder
	String newPrefix // new wave prefix of duplicated waves ( must specify if there is no toFolder )
	Variable overwrite
	Variable copySets
	Variable history
	
	Variable wcnt, icnt, pbgn, pend, xflag, numWaves, npnts, numSets
	String wName, newName, newPrefixFolder, existList = ""
	String chanChar = "", setsList, setName
	String fromF, toF, fromSetVarName, toSetVarName, fromWList, toWList
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	SetNMstr( NMDF + "OutputWaveList", "" )
	
	numWaves = ItemsInList( nm.wList )
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( ParamIsDefault( toFolder ) )
	
		if ( ParamIsDefault( newPrefix ) || ( strlen( newPrefix ) == 0 ) )
			return NM2ErrorStr( 21, "newPrefix", "" )
		endif
		
		toFolder = nm.folder
	
	else
	
		toFolder = CheckNMFolderPath( toFolder )
		
		if ( !DataFolderExists( toFolder ) )
		
			toFolder = NMChild( toFolder )
			NMFolderNew( toFolder, setCurrent = 0 )
			
			if ( IsNMDataFolder( toFolder ) )
				toFolder = CheckNMFolderPath( toFolder )
			else
				return NM2ErrorStr( 30, "toFolder", toFolder )
			endif
			
		endif
		
		if ( ParamIsDefault( newPrefix ) )
			newPrefix = ""
		endif
		
	endif
	
	if ( StringMatch( nm.folder, toFolder ) && ( strlen( newPrefix ) == 0 ) )
		return NM2ErrorStr( 21, "newPrefix", "" ) // cannot overwrite self
	endif
	
	if ( ( numtype( xbgn ) == 0 ) || ( numtype( xend ) == 0 ) )
		NMParamVarAdd( "xbgn", xbgn, nm )
		NMParamVarAdd( "xend", xend, nm )
	endif
	
	if ( strlen( nm.xWave ) > 0 )
		pbgn = NMX2Pnt( nm.folder + nm.xWave, xbgn )
		pend = NMX2Pnt( nm.folder + nm.xWave, xend )
		NMParamStrAdd( "xwave", nm.xWave, nm )
		xflag = 1
	endif
	
	if ( strlen( toFolder ) > 0 )
		NMParamStrAdd( "from", NMChild( nm.folder ), nm )
		NMParamStrAdd( "to", NMChild( toFolder ), nm )
	endif
	
	if ( strlen( newPrefix ) > 0 )
		NMParamStrAdd( "prefix", newPrefix, nm )
	endif
	
	for ( wcnt = 0; wcnt < numWaves; wcnt += 1 )
	
		wName = StringFromList( wcnt, nm.wList )
	
		newName = toFolder + newPrefix + wName
		
		if ( WaveExists( $newName ) )
			existList += newName + ";"
		endif
		
	endfor
	
	if ( !overwrite && ( ItemsInList( existList ) > 0 ) )
		existList = NMUtilityWaveListShort( existList )
		return NM2ErrorStr( 90, "waves have conflicting names: " + existList, "" )
	endif
	
	if ( copySets && DataFolderExists( nm.prefixFolder ) && ( strlen( nm.wavePrefix ) > 0 ) && ( numtype( nm.chanNum ) == 0 ) )
	
		newPrefixFolder = NMPrefixFolderDF( toFolder, newPrefix + nm.wavePrefix )
		
		if ( !DataFolderExists( newPrefixFolder ) )
			NewDataFolder $RemoveEnding( newPrefixFolder, ":" )
		endif
		
		chanChar = ChanNum2Char( nm.chanNum )
		fromF = nm.prefixFolder + "Chan" + chanChar
		toF = newPrefixFolder + "Chan" + chanChar
	
		if ( DataFolderExists( fromF ) && !DataFolderExists( toF ) )
			DuplicateDataFolder $fromF, $toF // copy channel graph configurations
		endif
		
		setsList = NMSetsListAll( prefixFolder = nm.prefixFolder )
	
		numSets = ItemsInList( setsList )
	
	endif
	
	for ( wcnt = 0; wcnt < numWaves; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Copying Waves..." ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		Wave wtemp = $nm.folder + wName
	
		newName = toFolder + newPrefix + wName
		
		if ( ( numtype( xbgn ) == 1 ) && ( numtype( xend ) == 1 ) )
		
			Duplicate /O wtemp $newName // entire wave
			
		else
		
			if ( !xflag )
				pbgn = x2pnt( wtemp, xbgn )
				pend = x2pnt( wtemp, xend )
				pbgn = max( pbgn, 0 )
				pend = min( pend, numpnts( wtemp ) - 1 )
			endif
		
			Duplicate /O/R=[ pbgn, pend ] wtemp $newName
		
		endif
		
		if ( !WaveExists( $newName ) )
			continue
		endif
		
		NMLoopWaveNote( newName, nm.paramList )
		
		nm.successList += wName + ";"
		nm.newList += newName + ";"
		
		for ( icnt = 0 ; icnt < numSets ; icnt += 1 )
	
			setName = StringFromList( icnt, setsList )
			
			fromSetVarName = nm.prefixFolder + setName + NMSetsListSuffix + chanChar
			toSetVarName = newPrefixFolder + setName + NMSetsListSuffix + chanChar
			
			fromWList = StrVarOrDefault( fromSetVarName, "" )
			
			if ( WhichListItem( wName, fromWList ) >= 0 )
			
				toWList = StrVarOrDefault( toSetVarName, "" )
				toWList = NMAddToList( NMChild( newName ), toWList, ";" )
				SetNMstr( toSetVarName, toWList )
				
			endif
	
		endfor
		
	endfor
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.newList )

	return nm.newList
	
End // NMDuplicate2

//****************************************************************
//****************************************************************

Function /S NMConcatenate2( nm, wName [ dimension, overwrite, history ] )
	STRUCT NMParams &nm // uses nm.folder, nm.wList
	String wName // output wave name
	Variable dimension // output wave dimension ( 1 ) 1D, default ( 2 ) 2D
	Variable overwrite
	Variable history
	
	String wList, txt
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	SetNMstr( NMDF + "OutputWaveList", "" )
	
	wList = NMUtilityWaveListShort( nm.wList )
	
	if ( ParamIsDefault( dimension ) )
		dimension = 1
	endif
	
	NMParamVarAdd( "dimension", dimension, nm )
	NMParamStrAdd( "wList", wList, nm )
	
	wList = CheckNMWavePath( nm.folder, nm.wList ) // create full-path wave list
	
	if ( overwrite || !WaveExists( $nm.folder + wName ) )
	
		if ( dimension == 2 )
			Concatenate /O wList, $nm.folder + wName
		else
			Concatenate /O/NP wList, $nm.folder + wName
		endif
		
		if ( WaveExists( $nm.folder + wName ) )
		
			nm.successList = nm.wList
	
			nm.newList = nm.folder + wName
			
			NMLoopWaveNote( nm.folder + wName, nm.paramList )
			
		else
		
			nm.failureList = nm.wList
		
		endif
	
	endif
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.newList )
	
	return nm.newList
	
End // NMConcatenate2

//****************************************************************
//****************************************************************

Function /S NMSplit2( nm, outputWaveLength, newPrefix [ xbgn, xend, overwrite, history ] )
	STRUCT NMParams &nm // uses nm.folder, nm.wList
	Variable outputWaveLength // output wave length
	String newPrefix // prefix name of output wave
	Variable xbgn, xend // x-axis window begin and end of input waves, use ( -inf, inf ) for all
	Variable overwrite, history
	
	Variable wcnt, numWaves, npnts
	String wName, newPrefix2, splitList
	String thisFxn = GetRTStackInfo( 1 )
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	SetNMstr( NMDF + "OutputWaveList", "" )
	
	numWaves = ItemsInList( nm.wList )
	
	if ( ( numtype( outputWaveLength ) > 0 ) || ( outputWaveLength <= 0 ) )
		return NM2ErrorStr( 10, "outputWaveLength", num2str( outputWaveLength ) )
	endif
	
	if ( strlen( newPrefix ) == 0 )
		return NM2ErrorStr( 21, "newPrefix", "" )
	endif
	
	NMParamStrAdd( "prefix", newPrefix, nm )
	
	if ( ParamIsDefault( xbgn ) || ( numtype ( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype ( xend ) > 0 ) )
		xend = inf
	endif
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Splitting Waves..." ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		Wave wtemp = $nm.folder + wName
		
		npnts = outputWaveLength / deltax( wtemp )
			
		if ( npnts >= numpnts( wtemp ) )
			NMHistory( thisFxn + " Error : output wave points is too large for wave " + nm.folder + wName )
			continue
		endif
		
		newPrefix2 = newPrefix + wName + "_"
		
		splitList = NMSplitWave( nm.folder + wName, newPrefix2, -1, xbgn, xend, outputWaveLength, overwrite = overwrite )
		
		if ( ItemsInList( splitList ) > 0 )
			nm.successList += wName + ";"
			nm.newList += splitList
		endif
		
	endfor
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.newList )
	
	return nm.newList
	
End // NMSplit2

//****************************************************************
//****************************************************************

Function /S NMSplitWave( wName, outPrefix, chanNum, xbgn, xend, splitWaveLength [ overwrite, deprecation ] )
	String wName // wave to break up
	String outPrefix // output wave prefix
	Variable chanNum // channel number for output wave ( -1 ) for none
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	Variable splitWaveLength // wave length of new output waves
	Variable overwrite // overwrite output waves if they already exist ( 0 ) no, alert user ( 1 ) yes
	Variable deprecation
	
	Variable npnts, numWaves, wcnt, pbgn, pend, plimit
	String folder, newName, paramList, returnList = ""
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( NMUtilityWaveTest( wName ) < 0 )
		return NM2ErrorStr( 1, "wName", wName )
	endif
	
	if ( strlen( outPrefix ) == 0 )
		return NM2ErrorStr( 21, "outPrefix", outPrefix )
	endif
	
	if ( numtype( xbgn ) == 2 )
		return NM2ErrorStr( 10, "xbgn", num2istr( xbgn ) )
	endif
	
	if ( numtype( xend ) == 2 )
		return NM2ErrorStr( 10, "xend", num2istr( xend ) )
	endif
	
	if ( ( numtype( splitWaveLength ) > 0 ) || ( splitWaveLength <= 0 ) )
		return NM2ErrorStr( 10, "splitWaveLength", num2istr( splitWaveLength ) )
	endif
	
	folder = NMParent( wName )
	
	npnts = splitWaveLength / deltax( $wName )
	
	numWaves = numpnts( $wName ) / npnts
	
	if ( numWaves <= 1 )
		return ""
	endif
	
	if ( numtype( xbgn ) > 0 )
		xbgn = leftx( $wName )
	endif
	
	if ( numtype( xend ) > 0 )
		xend = rightx( $wName )
	endif
	
	pbgn = x2pnt( $wName, xbgn )
	plimit = x2pnt( $wName, xend )
	
	pbgn = max( pbgn, 0 )
	plimit = min( plimit, numpnts( $wName ) - 1 )

	for ( wcnt = 0; wcnt < numWaves; wcnt += 1 )
	
		if ( wcnt > 0 )
			pbgn = pend + 1
		endif
		
		if ( pbgn >= plimit )
			break // finished
		endif
		
		pend = pbgn + npnts - 1
		pend = min( pend, plimit )
		
		newName = folder + GetWaveName( outPrefix, chanNum, wcnt )
		
		if ( strlen( newName ) == 0 )
			return NM2ErrorStr( 21, "newName", newName )
		endif
		
		if ( !overwrite && WaveExists( $newName ) )
			continue
		endif
		
		Duplicate /O/R=[ pbgn, pend ] $wName $newName
		
		paramList = "pbgn" + "=" + num2istr( pbgn ) + ";"
		paramList += "pend" + "=" + num2istr( pend ) + ";"
		
		NMLoopWaveNote( newName, paramList )
		
		returnList += newName + ";"
		
	endfor
	
	return returnList

End // NMSplitWave

//****************************************************************
//****************************************************************

Function /S NMSplit2D( nm, columnsOrRows, newPrefix [ overwrite, history ] )
	STRUCT NMParams &nm // uses nm.folder, nm.wList
	String columnsOrRows // "columns" or "rows"
	String newPrefix // prefix name of output wave
	Variable overwrite, history
	
	Variable wcnt, numWaves, npnts
	String wName, newPrefix2, splitList = ""
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	SetNMstr( NMDF + "OutputWaveList", "" )
	
	numWaves = ItemsInList( nm.wList )
	
	if ( strlen( newPrefix ) == 0 )
		return NM2ErrorStr( 21, "newPrefix", "" )
	endif
	
	NMParamStrAdd( "prefix", newPrefix, nm )
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Splitting Waves..." ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		Wave wtemp = $nm.folder + wName
		
		newPrefix2 = newPrefix + wName + "_"
		
		if ( DimSize( $nm.folder + wName, 1 ) == 0 )
			continue // not a 2D wave
		endif
		
		strswitch( columnsOrRows )
			case "column":
			case "columns":
				splitList = NMMatrixColumns2Waves( nm.folder + wName, newPrefix2, chanNum = nm.chanNum, overwrite = overwrite )
				break
			case "row":
			case "rows":
				splitList = NMMatrixRows2Waves( nm.folder + wName, newPrefix2, chanNum = nm.chanNum, overwrite = overwrite )
				break
			default:
				return NM2ErrorStr( 20, "columnsOrRows", columnsOrRows )
		endswitch
		
		if ( ItemsInList( splitList ) > 0 )
			nm.successList += wName + ";"
			nm.newList += splitList
		endif
		
	endfor
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.newList )
	
	return nm.newList
	
End // NMSplit2D

//****************************************************************
//****************************************************************

Function /S NMRenameWavesSafely( find, replacement, wList [ folder, updateSets, deprecation ] )
	String find // search string
	String replacement // replace string
	String wList, folder // see description at top
	Variable updateSets // change wave names in prefix subfolder wave lists ( 0 ) no ( 1 ) yes
	Variable deprecation
	
	String fxn = "NMRename"
	
	STRUCT NMParams nm
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( StringMatch( wList, "_ALL_" ) )
		wList = NMFolderWaveList( folder, "*", ";", "", 0 )
	endif
	
	if ( NMParamsInit( folder, wList, nm, fxn = fxn ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( updateSets ) )
		updateSets = 1
	endif
	
	if ( strlen( find ) == 0 )
		return NM2ErrorStr( 21, "find", find )
	endif
	
	return NMRenameWavesSafely2( nm, find, replacement, updateSets = updateSets )

End // NMRenameWavesSafely

//****************************************************************
//****************************************************************

Function /S NMRenameWavesSafely2( nm, find, replacement [ updateSets, history ] )
	STRUCT NMParams &nm // uses nm.folder, nm.wList
	String find // search string
	String replacement // replace string
	Variable updateSets // change wave names in prefix subfolder wave lists ( 0 ) no ( 1 ) yes
	Variable history
	
	Variable wcnt, numWaves
	String wName, newName
	String paramList, oldList = "", newList = ""
	
	if ( NMParamsError( nm, skipWaveList = 1, skipXwave = 1 ) != 0 )
		return ""
	endif
	
	SetNMstr( NMDF + "OutputWaveList", "" )
	
	if ( strlen( find ) == 0 )
		return NM2ErrorStr( 21, "find", find )
	endif
	
	if ( ParamIsDefault( updateSets ) )
		updateSets = 1
	endif
	
	if ( StringMatch( nm.wList, "_ALL_" ) )
		nm.wList = NMFolderWaveList( nm.folder, "*", ";", "", 0 )
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	for ( wcnt = 0; wcnt < numWaves; wcnt += 1 )
	
		wName = StringFromList( wcnt, nm.wList )
		newName = ReplaceString( find, wName, replacement )
		
		if ( StringMatch( wName, newName ) )
			continue // no change
		endif
		
		if ( WaveExists( $nm.folder + newName ) )
			NMDoAlert( "Abort: encountered name conflict with wave " + nm.folder + newName )
			return ""
		endif
		
		oldList += wName + ";"
		newList += newName + ";"
		
	endfor
	
	numWaves = ItemsInList( oldList )
	
	for ( wcnt = 0; wcnt < numWaves; wcnt += 1 )
		
		wName = StringFromList( wcnt, oldList )
		newName = StringFromList( wcnt, newList )
		
		if ( StringMatch( nm.folder, GetDataFolder( 1 ) ) )
			Rename $wName $newName
		else
			Rename $( nm.folder + wName ) $newName
		endif
		
		paramList = "oldName=" + wName + ";"
		paramList += "newName=" + newName + ";"
		
		NMLoopWaveNote( newName, paramList )
		
		if ( updateSets )
			NMPrefixFoldersRenameWave( wName, newName, folder = nm.folder )
		endif
		
		nm.successList += wName + ";"
		nm.newList += nm.folder + newName + ";"
		
	endfor
	
	nm.failureList = RemoveFromList( nm.successList, oldList )
	
	//nm.fxn += " " + NMQuotes( find ) + "-->" + NMQuotes( replacement )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.newList )
	
	return nm.newList

End // NMRenameWavesSafely2

//****************************************************************
//****************************************************************

Function /S NMRenumberWavesSafely( [ fromNum, folder, wList, increment, updateSets, deprecation ] )
	Variable fromNum // renumber from
	String folder, wList // see description at top
	Variable increment // renumber increment ( default is 1 )
	Variable updateSets // also change wave names in prefix subfolder wave lists ( 0 ) no ( 1 ) yes
	Variable deprecation
	
	String fxn = "NMRenumber"
	
	STRUCT NMParams nm
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wList ) )
		wList = ""
	endif
	
	if ( NMParamsInit( folder, wList, nm, fxn = fxn ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( increment ) )
		increment = 1
	endif
	
	if ( ParamIsDefault( updateSets ) )
		updateSets = 1
	endif
	
	return NMRenumberWavesSafely2( nm, fromNum = fromNum, increment = increment, updateSets = updateSets )

End // NMRenumberWavesSafely

//****************************************************************
//****************************************************************

Function /S NMRenumberWavesSafely2( nm [ fromNum, increment, updateSets, history ] )
	STRUCT NMParams &nm // uses nm.folder, nm.wList
	Variable fromNum // renumber from ( default 0 )
	Variable increment // renumber increment ( default 1 )
	Variable updateSets // also change wave names in prefix subfolder wave lists ( 0 ) no ( 1 ) yes
	Variable history
	
	Variable wcnt, icnt, jcnt, ok, numWaves
	String wName, oldName, newName, tempPrefix
	String paramList, tempList = "", oldList = "", newList = ""
	String fxn = "NMRenumber"
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	SetNMstr( NMDF + "OutputWaveList", "" )
	
	numWaves = ItemsInList( nm.wList )
	
	if ( ParamIsDefault( increment ) )
		increment = 1
	endif
	
	if ( ParamIsDefault( updateSets ) )
		updateSets = 1
	endif
	
	fromNum = round( fromNum )
	increment = round( increment )
	
	if ( ( numtype( fromNum ) > 0 ) || ( fromNum < 0 ) )
		return NM2ErrorStr( 10, "fromNum", num2istr( fromNum ) )
	endif
	
	if ( ( numtype( increment ) > 0 ) || ( increment <= 0 ) )
		return NM2ErrorStr( 10, "increment", num2istr( increment ) )
	endif
	
	if ( updateSets != 0 )
		updateSets = 1
	endif
	
	NMParamVarAdd( "from", fromNum, nm, integer = 1 )
	
	if ( increment > 1 )
		NMParamVarAdd( "+", increment, nm, integer = 1 )
	endif
	
	jcnt = fromNum
	numWaves = ItemsInList( nm.wList )
	
	for ( wcnt = 0; wcnt < numWaves; wcnt += 1 )
	
		wName = StringFromList( wcnt, nm.wList )
		
		for ( icnt = strlen( wName ) - 1; icnt >= 0 ; icnt -= 1 )
		
			if ( numtype( str2num( wName[ icnt, icnt ] ) ) > 0 )
				break // found first non-number character
			endif
		
		endfor
		
		if ( icnt == 0 )
			return NM2ErrorStr( 90, "cannot compute new wave name for " + wName, "" )
		else
			newName = wName[ 0, icnt ] + num2istr( jcnt )
		endif
		
		if ( !StringMatch( newName, wName ) )
			oldList += wName + ";"
			newList += newName + ";"
		endif
		
		jcnt += increment
		
	endfor
	
	numWaves = ItemsInList( oldList )
	
	if ( numWaves == 0 )
		return "" // nothing to do
	endif
	
	tempList = RemoveFromList( oldList, newList )
	
	for ( wcnt = 0 ; wcnt < ItemsInList( tempList ) ; wcnt += 1 )
		
		newName = StringFromList( wcnt, tempList )
		
		if ( WaveExists( $nm.folder + newName ) )
			return NM2ErrorStr( 90, "name conflict with wave " + NMQuotes( nm.folder + newName ), "" )
		endif
		
	endfor
	
	for ( icnt = 0 ; icnt < 99 ; icnt += 1 )
	
		tempPrefix = "znm" + num2istr( icnt ) + "_"
		tempList = Wavelist( tempPrefix + "*", ";", "" )
		
		if ( ItemsInList( tempList ) == 0 )
			ok = 1
			break
		endif
		
	endfor
	
	if ( !ok )
		return NM2ErrorStr( 90, "failed to find temporary unused wave prefix name", "" )
	endif
	
	tempList = ""
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 ) // rename waves with temporary new prefix name
	
		wName = StringFromList( wcnt, oldList )
		newName = tempPrefix + wName
		
		Rename $( nm.folder + wName ) $newName
		
		if ( updateSets )
			NMPrefixFoldersRenameWave( wName, newName, folder = nm.folder, ignorePrefixMatch = 1 )
		endif
		
		tempList += newName + ";"
		
	endfor
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 ) // rename again to new names
	
		oldName = StringFromList( wcnt, oldList )
		wName = StringFromList( wcnt, tempList )
		newName = StringFromList( wcnt, newList )

		Rename $( nm.folder + wName ) $newName
		
		paramList = "oldName=" + oldName + ";"
		paramList += "newName=" + newName + ";"
		
		NMLoopWaveNote( newName, paramList )
		
		if ( updateSets )
			NMPrefixFoldersRenameWave( wName, newName, folder = nm.folder, ignorePrefixMatch = 1 )
		endif
		
		nm.successList += oldName + ";"
		nm.newList += nm.folder + newName + ";"
		
	endfor
	
	nm.failureList = RemoveFromList( nm.successList, oldList )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.newList )
	
	return nm.newList

End // NMRenumberWavesSafely2

//****************************************************************
//****************************************************************

Function /S NMSave2( nm [ extFolderPath, fileType, saveXaxisWave, saveWaveNotes, saveParams, history ] )
	STRUCT NMParams &nm // uses nm.folder, nm.wList, nm.xWave, nm.chanNum
	String extFolderPath // path to external folder where data is to be saved
	String fileType // "Igor Binary" or "Igor Text" or "General Text" or "Delimited Text"
	Variable saveXaxisWave // ( 0 ) no ( 1 ) yes, save as seperate file ( 2 ) yes, save in same file as data ( General or Delimited Text only )
	Variable saveWaveNotes // ( 0 ) no ( 1 ) yes
	Variable saveParams // ( 0 ) no ( 1 ) yes
	Variable history
	
	Variable wcnt, numWaves, fType, cancel, refNum, xKill
	String wName, xWave, wList = "", wListKill = ""
	String file = "", txt, xLabel, yLabel, chanChar = "", path = "NMSaveWavesPath"
	
	STRUCT NMXAxisStruct s
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	if ( ParamIsDefault( extFolderPath ) || ( strlen( extFolderPath ) == 0 ) )
		extFolderPath = NMGetExternalFolderPath( "select folder on disk where to save", "" )
	endif
	
	if ( strlen( extFolderPath ) == 0 )
		return "" // cancel
	endif
	
	if ( ParamIsDefault( fileType ) )
		fileType = "Igor Binary"
	endif
	
	fType = NMWaveFileTypeNum( fileType )
	
	if ( numtype( fType ) > 0 )
		return NM2ErrorStr( 20, "fileType", fileType )
	endif
	
	if ( ParamIsDefault( saveXaxisWave ) )
		if ( ( fType == 0 ) || ( fType == 1 ) )
			saveXaxisWave = 1
		else
			saveXaxisWave = 2
		endif
	endif
	
	if ( ( saveXaxisWave == 2 ) && ( ( fType == 0 ) || ( fType == 1 ) ) )
		saveXaxisWave = 0 // not allowed
	endif
	
	if ( ( numtype( nm.chanNum ) == 0 ) && ( nm.chanNum >= 0 ) )
		chanChar = ChanNum2Char( nm.chanNum )
	endif
	
	if ( saveXaxisWave == 1 )
		
		if ( WaveExists( $nm.folder + nm.xWave ) )
			
			file = NMSaveWavesToDisk( nm.folder + nm.xWave, extFolderPath, fileType = fileType, overWrite = 1 )
			
			if ( StringMatch( file, NMCancel ) )
				return ""
			endif
			
			saveXaxisWave = 0 // finished
			
		else
		
			xWave = NMXscalePrefix + "TempWave"
			NMXWaveMake2( nm, xWave = xWave )
			
			if ( WaveExists( $nm.folder + xWave ) )
				
				file = NMSaveWavesToDisk( nm.folder + xWave, extFolderPath, fileType = fileType, overWrite = 1 )
				
				KillWaves /Z $nm.folder + xWave
			
				if ( StringMatch( file, NMCancel ) )
					return ""
				endif
				
				saveXaxisWave = 0 // finished
				
			endif
			
		endif
	
	endif
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Saving Waves..." ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		if ( saveXaxisWave == 0 )
		
			if ( fType == 3 )
				wList = AddListItem( nm.folder + wName, wList, ";", inf )
			else
				file = NMSaveWavesToDisk( nm.folder + wName, extFolderPath, fileType = fileType )
			endif
			
		else
		
			if ( !WaveExists( $nm.folder + nm.xWave ) )
		
				xWave = NMXscalePrefix + wName
				
				nm.xWave = NMCheckStringName( xWave )
				
				Duplicate /O $( nm.folder + wName ) $( nm.folder + nm.xWave )
				
				Wave xtemp = $nm.folder + nm.xWave
				
				xtemp = x
				
				xKill = 1
				
			endif
			
			if ( fType == 3 )
			
				if ( saveXaxisWave == 1 )
					file = NMSaveWavesToDisk( nm.folder + nm.xWave, extFolderPath, fileType = fileType )
				elseif ( ( saveXaxisWave == 2 ) && ( wcnt == 0 ) )
					wList = AddListItem( nm.folder + nm.xWave, wList, ";", inf )
				endif
				
				wList = AddListItem( nm.folder + wName, wList, ";", inf )
			
			else
			
				if ( saveXaxisWave == 1 )
					file = NMSaveWavesToDisk( nm.folder + nm.xWave, extFolderPath, fileType = fileType )
					file = NMSaveWavesToDisk( nm.folder + wName, extFolderPath, fileType = fileType )
				elseif ( saveXaxisWave == 2 )
					file = NMSaveWavesToDisk( nm.folder + nm.xWave + ";" + nm.folder + wName + ";", extFolderPath, fileName = wName, fileType = fileType )
				endif
			
			endif
			
			if ( xKill )
				wListKill = AddListItem( nm.xWave, wListKill, ";", inf )
			endif
		
		endif
		
		if ( StringMatch( file, NMCancel ) )
			cancel = 1
			break
		endif
		
		nm.successList += wName + ";"
		
	endfor
	
	if ( !cancel && ( fType == 3 ) )
		file = NMSaveWavesToDisk( wList, extFolderPath, fileType = fileType )
	endif
	
	if ( xKill )
		NMKillWaves( wListKill, folder = nm.folder, noAlert = 1 )
	endif
	
	if ( !cancel && saveWaveNotes )
	
		NewPath /Q/O $path, extFolderPath
	
		if ( V_flag == 0 )
		
			Open /P=$path refNum as NMWaveNotesFileName + chanChar + ".txt" // open file for writing
			
			for ( wcnt = 0 ; wcnt < ItemsInList( nm.wList ) ; wcnt += 1 )
				
				wName = StringFromList( wcnt, nm.wList )
				txt = note( $nm.folder + wName )
				
				if ( strlen( txt ) > 0 )
					fprintf refNum, nm.folder + wName + NMCR
					fprintf refNum, txt + NMCR + NMCR
				endif
				
			endfor
		
			Close refNum
			
			KillPath /Z $path
			
		endif
	
	endif
	
	if ( !cancel && saveParams )
	
		NewPath /Q/O $path, extFolderPath
	
		if ( V_flag == 0 )
	
			NMXAxisStructInit( s, nm.wList, folder = nm.folder )
			NMXAxisStats2( s )
		
			Open /P=$path refNum as NMVariablesFileName + chanChar + ".txt" // open file for writing
			
			fprintf refNum, "NumPnts=%d" + NMCR, s.points
			fprintf refNum, "StartX=%g" + NMCR, s.leftx
			fprintf refNum, "DeltaX=%g" + NMCR, s.dx
			
			if ( strlen( nm.xLabel ) > 0 )
				xLabel = nm.xLabel
			else
				xLabel = NMNoteLabel( "x", nm.wList, "", folder = nm.folder )
			endif
			
			if ( strlen( xLabel ) > 0 )
				fprintf refNum, "xLabel=\"%s\"" + NMCR, xLabel
			endif
			
			if ( strlen( nm.yLabel ) > 0 )
				yLabel = nm.yLabel
			else
				yLabel = NMNoteLabel( "y", nm.wList, "", folder = nm.folder )
			endif
				
			if ( strlen( yLabel ) > 0 )
				fprintf refNum, "yLabel" + chanChar + "=\"%s\"" + NMCR, yLabel
			endif
		
			Close refNum
			
			KillPath /Z $path
			
		endif
	
	endif
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.successList )
	
	return nm.successList
	
End // NMSave2

//****************************************************************
//****************************************************************

Function /S NMKillWaves( wList [ folder, updateSets, noAlert, deprecation ] )
	String wList, folder // see description at top
	Variable updateSets // remove wave names from prefix subfolder wave lists ( 0 ) no ( 1 ) yes
	Variable noAlert, deprecation
	
	STRUCT NMParams nm
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( updateSets ) )
		updateSets = 1
	endif
	
	if ( NMParamsInit( folder, wList, nm ) != 0 )
		return ""
	endif
	
	return NMKillWaves2( nm, updateSets = updateSets, noAlert = noAlert )

End // NMKillWaves

//****************************************************************
//****************************************************************

Function /S NMKillWaves2( nm [ updateSets, history, noAlert ] )
	STRUCT NMParams &nm // uses nm.folder, nm.wList, killPrefixGlobals uses nm.prefixFolder
	Variable updateSets // remove wave names from prefix subfolder wave lists ( 0 ) no ( 1 ) yes
	Variable history, noAlert
	
	Variable wcnt, numWaves, failures
	String wName, txt, prefixFolder, fxn = "NMKillWaves"
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	if ( ParamIsDefault( updateSets ) )
		updateSets = 1
	endif
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Deleting Waves..." ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		if ( WaveExists( $nm.folder + wName ) )
			KillWaves /Z $nm.folder + wName
		endif
		
		if ( !WaveExists( $nm.folder + wName ) )
			nm.successList += wName + ";"
		endif
		
	endfor
	
	NMParamsComputeFailures( nm )
	
	failures = ItemsInList( nm.failureList )
	
	if ( updateSets )
	
		for ( wcnt = 0 ; wcnt < ItemsInList( nm.successList ) ; wcnt += 1 )
			wName = StringFromList( wcnt, nm.successList )
			NMPrefixFoldersRenameWave( wName, "", folder = nm.folder )
		endfor
	
	endif
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.successList )
	
	if ( !noAlert && ( failures > 0 ) )
	
		if ( failures == 1 )
			txt = "Alert: one wave could not be killed. This wave may be currently displayed in a graph or table, or may be locked."
		else
			txt = "Alert: " + num2istr( failures ) + " waves could not be killed. These waves may be currently displayed in a graph or table, or may be locked."
		endif
		
		NMDoAlert( txt, title = fxn )
		
	endif
	
	return nm.successList
	
End // NMKillWaves2

//****************************************************************
//****************************************************************
//
//		Display Functions
//		Graphs, Tables, x-y Labels, Wave Notes, etc
//
//****************************************************************
//****************************************************************

Structure NMGraphStruct

	String gName, gTitle, xLabel, yLabel, color
	Variable xoffset, xoffsetInc, yoffset, yoffsetInc, plotErrors

EndStructure

//****************************************************************
//****************************************************************

Function NMGraphStructNull( g )
	STRUCT NMGraphStruct &g
	
	g.gName = ""; g.gTitle = ""; g.xLabel = ""; g.yLabel = ""; g.color = "black"

End // NMGraphStructNull

//****************************************************************
//****************************************************************

Function NMGraphStructCheck( g )
	STRUCT NMGraphStruct &g
	
	if ( strlen( g.gName ) == 0 )
		g.gName = UniqueName( "NM_Graph", 7, 0 )
	endif
	
	g.gName = NMCheckStringName( g.gName )
	
	if ( strlen( g.gName ) == 0 )
		return -1
	endif
	
	if ( ( WinType( g.gName ) > 0 ) && ( WinType( g.gName ) != 1 ) )
		return NM2Error( 51, "gName", g.gName )
	endif
	
	if ( numtype( g.xoffset ) > 0 )
		g.xoffset = 0
		g.xoffsetInc = 0
	endif
	
	if ( numtype( g.yoffset ) > 0 )
		g.yoffset = 0
		g.yoffsetInc = 0
	endif
	
	if ( numtype( g.xoffsetInc ) > 0 )
		g.xoffsetInc = 0
	endif
	
	if ( numtype( g.yoffsetInc ) > 0 )
		g.yoffsetInc = 0
	endif
	
	if ( strlen( g.color ) == 0 )
		g.color = "black"
	endif
	
	return 0

End // NMGraphStructCheck

//****************************************************************
//****************************************************************

Function /S NMGraph( [ folder, wList, xWave, matchStr, gName, gTitle, xLabel, yLabel, color, xoffset, xoffsetInc, yoffset, yoffsetInc, plotErrors, deprecation ] ) // see NMGraph2
	String folder, wList, xWave // see description at top
	String matchStr // create wave list based on this matching string
	
	String gName // graph name
	String gTitle // graph title
	String xLabel // x axis label
	String yLabel // y axis label
	String color // "rainbow", "black", "red", or rgb list ( e.g. "52224,0,0" ) // see NMPlotColorList
	Variable xoffset, xoffsetInc // 0 for none
	Variable yoffset, yoffsetInc // 0 for none
	Variable plotErrors // ( 0 ) no ( 1 ) yes, if STDV or SEM wave exists
	
	Variable deprecation
	
	STRUCT NMParams nm
	STRUCT NMGraphStruct g
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wList ) )
		wList = ""
	endif
	
	if ( !ParamIsDefault( matchStr ) && ( strlen( matchStr ) > 0 ) )
		wList = NMFolderWaveList( folder, matchStr, ";", "", 0 )
	endif
	
	if ( ParamIsDefault( xWave ) )
		xWave = ""
	endif
	
	if ( NMParamsInit( folder, wList, nm, xWave = xWave ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( gName ) )
		gName = ""
	endif
	
	if ( ParamIsDefault( gTitle ) )
		gTitle = "NM Graph : " + NMUtilityWaveListShort( nm.wList )
	endif
	
	if ( ParamIsDefault( xLabel ) )
		xLabel = NMNoteLabel( "x", nm.wList, "", folder = nm.folder )
	endif
	
	if ( ParamIsDefault( yLabel ) )
		yLabel = NMNoteLabel( "y", nm.wList,"", folder = nm.folder )
	endif
	
	if ( ParamIsDefault( color ) )
		color = "black"
	endif
	
	g.gName = gName
	g.gTitle = gTitle
	g.xLabel = xLabel
	g.yLabel = yLabel
	g.xoffset = xoffset
	g.xoffsetInc = xoffsetInc
	g.yoffset = yoffset
	g.yoffsetInc = yoffsetInc
	g.plotErrors = plotErrors
	g.color = color
	
	return NMGraph2( nm, g )
	
End // NMGraph

//****************************************************************
//****************************************************************

Function /S NMGraph2( nm, g [ history, STDV, SEM ] ) // see Igor Display
	STRUCT NMParams &nm // uses nm.folder, nm.wList, nm.xWave
	STRUCT NMGraphStruct &g
	Variable history
	Variable STDV // look only for STDV waves
	Variable SEM // look only for SEM waves
	
	Variable wcnt, xinc = 1, yinc = 1, npnts, xflag, numWaves
	String wName, errorName
	
	STRUCT Rect w
	STRUCT NMRGB c
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	NMOutputListsReset()
	
	if ( ParamIsDefault( STDV ) && ParamIsDefault( SEM ) )
		STDV = 1
		SEM = 1
	endif
	
	if ( NMGraphStructCheck( g ) != 0 )
		return ""
	endif
	
	if ( ( numtype( g.xoffsetInc ) == 0 ) && ( g.xoffsetInc > 0 ) )
		xinc = 0
	endif
	
	if ( ( numtype( g.yoffsetInc ) == 0 ) && ( g.yoffsetInc > 0 ) )
		yinc = 0
	endif
	
	if ( strlen( nm.xWave ) > 0 )
		xflag = 1
	endif
	
	if ( strlen( g.xLabel ) == 0 )
		if ( strlen( nm.xLabel ) > 0 )
			g.xLabel = nm.xLabel
		else
			g.xLabel = NMNoteLabel( "x", nm.wList, "", folder = nm.folder )
		endif
	endif
	
	if ( strlen( g.yLabel ) == 0 )
		if ( strlen( nm.yLabel ) > 0 )
			g.yLabel = nm.yLabel
		else
			g.yLabel = NMNoteLabel( "y", nm.wList, "", folder = nm.folder )
		endif
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	for ( wcnt = 0; wcnt < numWaves; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Plotting Waves..." ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		if ( g.plotErrors )
			errorName = NMWaveNameError( nm.folder + wName, STDV = STDV, SEM = SEM )
		endif
		
		NMRGBbasic( g.color, c, wcnt = wcnt )
	
		if ( WinType( g.gName ) == 0 )
			
			NMWinCascadeRect( w )
			
			if ( xflag )
				Display /K=(NMK())/N=$g.gName/W=(w.left,w.top,w.right,w.bottom) $( nm.folder + wName ) vs $( nm.folder + nm.xWave ) as g.gTitle
			else
				Display /K=(NMK())/N=$g.gName/W=(w.left,w.top,w.right,w.bottom) $( nm.folder + wName ) as g.gTitle
			endif
			
			ModifyGraph /W=$g.gName rgb( $wName )=(c.r,c.g,c.b), mode=0
			
		elseif ( WinType( g.gName ) == 1 )
		
			if ( xflag )
				AppendToGraph /C=(c.r,c.g,c.b)/W=$g.gName $( nm.folder + wName ) vs $( nm.folder + nm.xWave )
			else
				AppendToGraph /C=(c.r,c.g,c.b)/W=$g.gName $( nm.folder + wName )
			endif
			
		endif
		
		if ( g.plotErrors && WaveExists( $errorName ) )
			
			if ( numpnts( $errorName ) <= NMVarGet( "ErrorPointsLimit" ) )
				ErrorBars /W=$g.gName $wName Y, wave=( $errorName, $errorName )
			else
				ErrorBars /L=0/W=$g.gName/Y=1 $wName Y, wave=( $errorName, $errorName )
			endif
				
		endif
		
		ModifyGraph /W=$g.gName offset( $wName )={ g.xoffset * xinc, g.yoffset * yinc }
		
		if ( g.xoffsetInc > 0 )
			xinc += g.xoffsetInc
		endif
		
		if ( g.yoffsetInc > 0 )
			yinc += g.yoffsetInc
		endif
		
		nm.successList += wName + ";"

	endfor
	
	DoWindow /F $g.gName
	Label /W=$g.gName bottom g.xLabel
	Label /W=$g.gName left g.yLabel
	ModifyGraph /W=$g.gName standoff=NMGraphAxisStandoff
	SetAxis /A /W=$g.gName
	
	if ( NMGraphShowInfo )
		ShowInfo /W=$g.gName
	endif
	
	nm.windowList = g.gName
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.successList )
	SetNMstr( NMDF + "OutputWinList", nm.windowList )

	return nm.windowList
	
End // NMGraph2

//****************************************************************
//****************************************************************

Function /S NMTable( [ folder, wList, xWave, matchStr, tName, tTitle, deprecation ] ) // see NMTable2
	String folder, wList, xWave // see description at top
	String matchStr // create wave list based on this matching string
	String tName
	String tTitle
	Variable deprecation
	
	STRUCT NMParams nm
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wList ) )
		wList = ""
	endif
	
	if ( !ParamIsDefault( matchStr ) && ( strlen( matchStr ) > 0 ) )
		wList = NMFolderWaveList( folder, matchStr, ";", "", 0 )
	endif
	
	if ( NMParamsInit( folder, wList, nm, xWave = xWave ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( tName ) )
		tName = ""
	endif
	
	if ( ParamIsDefault( tTitle ) )
		tTitle = "NM Table : " + NMUtilityWaveListShort( nm.wList )
	endif
	
	return NMTable2( nm, tName = tName, tTitle = tTitle )
	
End // NMTable

//****************************************************************
//****************************************************************

Function /S NMTable2( nm [ tName, tTitle, history ] ) // see Igor Edit
	STRUCT NMParams &nm // uses nm.folder, nm.wList, nm.xWave
	String tName, tTitle // table name and title
	Variable history

	Variable wcnt, numWaves
	String wName
	
	STRUCT Rect w
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	NMOutputListsReset()
	
	if ( ParamIsDefault( tName ) || strlen( tName ) == 0 )
		tName = UniqueName( "NM_Table", 7, 0 )
	elseif ( ( WinType( tName ) > 0 ) && ( WinType( tName ) != 2 ) )
		return NM2ErrorStr( 51, "tName", tName )
	endif
	
	if ( ParamIsDefault( tTitle ) )
		tTitle = ""
	endif
	
	if ( strlen( nm.xWave ) > 0 )
		nm.wList = nm.xWave + ";" + nm.wList // put x-wave first
	endif
	
	numWaves = ItemsInList( nm.wList )

	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Creating Table..." ) == 1 )
			break
		endif
	
		wName = StringFromList( wcnt, nm.wList )
	
		if ( WinType( tName ) == 0 )
		
			NMWinCascadeRect( w )
		
			Edit /K=(NMK())/N=$tName/W=(w.left,w.top,w.right,w.bottom) $( nm.folder + wName ) as tTitle
			
			nm.successList += wName + ";"
			
		elseif ( WinType( tName ) == 2 )
		
			AppendToTable /W=$tName $( nm.folder + wName )
			
			nm.successList += wName + ";"
			
		endif
		
	endfor
	
	if ( WinType( tName ) == 2 )
		DoWindow /F $tName
	else
		tName = ""
	endif
	
	nm.windowList = tName
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.successList )
	SetNMstr( NMDF + "OutputWinList", nm.windowList )
		
	return nm.windowList
	
End // NMTable2

//****************************************************************
//****************************************************************

Function /S NMLabel2( nm [ xLabel, yLabel, history ] )
	STRUCT NMParams &nm // uses nm.folder, nm.wList, nm.xWave
	String xLabel // x-axis label ( e.g. "time (ms)" )
	String yLabel // y-axis label ( e.g. "current (pA)" )
	Variable history
	
	Variable wcnt, numWaves, xFlag, yFlag
	String wName
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	if ( !ParamIsDefault( xLabel ) )
		xFlag = 1
		NMParamStrAdd( "x", xLabel, nm )
	endif
	
	if ( !ParamIsDefault( yLabel ) )
		yFlag = 1
		NMParamStrAdd( "y", yLabel, nm )
	endif
	
	if ( !xFlag && !yFlag )
		return "" // nothing to do
	endif
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		wName = StringFromList( wcnt, nm.wList )
		
		if ( xFlag )
			NMNoteStrReplace( nm.folder + wName, "xLabel", xLabel )
		endif
		
		if ( yFlag )
			NMNoteStrReplace( nm.folder + wName, "yLabel", yLabel )
		endif
		
		RemoveWaveUnits( nm.folder + wName )
		
		nm.successList += wName + ";"
		
	endfor
	
	if ( xFlag && WaveExists( $nm.folder + nm.xWave ) )
		NMNoteStrReplace( nm.folder + nm.xWave, "yLabel", xLabel )
	endif
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.successList )
	
	return nm.successList
	
End // NMLabel2

//****************************************************************
//****************************************************************

Function /S NMWaveNotes( wList [ folder, matchStr, notestr, nbName, nbTitle ] ) // see NMWaveNotes2
	String wList, folder // see description at top
	String matchStr // create wave list based on this matching string
	String notestr // add note to wave notes
	String nbName, nbTitle // notebook name and title
	
	Variable toNotebook
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( !ParamIsDefault( matchStr ) && ( strlen( matchStr ) > 0 ) )
		wList = NMFolderWaveList( folder, matchStr, ";", "", 0 )
	endif
	
	if ( NMParamsInit( folder, wList, nm ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( notestr ) )
		notestr = ""
	else
		return NMWaveNotes2( nm, notestr = notestr )
	endif
	
	if ( ParamIsDefault( nbName ) )
		return NMWaveNotes2( nm )
	endif
	
	if ( ParamIsDefault( nbTitle ) )
		nbTitle = "NM Wave Notes : " + NMChild( nm.folder )
	endif
	
	return NMWaveNotes2( nm, nbName = nbName, nbTitle = nbTitle )
	
End // NMWaveNotes

//****************************************************************
//****************************************************************

Function /S NMWaveNotes2( nm [ notestr, nbName, nbTitle, history ] )
	STRUCT NMParams &nm // uses nm.folder, nm.wList
	String notestr // add note to wave notes
	String nbName, nbTitle // notebook name and title
	Variable history
	
	Variable wcnt, numWaves, toNotebook
	String wName, wNote
	
	STRUCT Rect w
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	NMOutputListsReset()
	
	numWaves = ItemsInList( nm.wList )
	
	if ( ParamIsDefault( notestr ) )
		notestr = ""
	elseif ( strlen( notestr ) == 0 )
		return "" // nothing to do
	endif
	
	if ( ParamIsDefault( nbName ) )
		nbName = ""
	else
		toNotebook = 1
	endif
	
	if ( ParamIsDefault( nbTitle ) )
		nbTitle = "NM Wave Notes : " + NMChild( nm.folder ) // also used with Igor history
	endif
	
	if ( strlen( notestr ) > 0 )
	
		for ( wcnt = 0; wcnt < numWaves; wcnt += 1 )
	
			wName = StringFromList( wcnt, nm.wList )
			
			notestr = ReplaceString( "  ", notestr, " " )
			notestr = ReplaceString( "  ", notestr, " " )
			
			Note $wName, "NMNote:" + notestr
			
			nm.successList += wName + ";"
		
		endfor
		
		NMParamsComputeFailures( nm )
		
		if ( history )
			NMLoopHistory( nm )
		endif
		
		SetNMstr( NMDF + "OutputWaveList", nm.successList )
		
		return nm.successList
	
	endif
	
	if ( toNotebook == 0 ) // print notes to Igor history
	
		if ( numWaves > 1 )
			Print nbTitle + NMCR + NMCR
		endif
	
		for ( wcnt = 0; wcnt < numWaves; wcnt += 1 )
	
			wName = StringFromList( wcnt, nm.wList )
			
			Print "Notes " + nm.folder + wName
			
			wNote = note( $nm.folder + wName )
			
			if ( strlen( wNote ) > 0 )
				Print wNote
				Print " "
			endif
			
			nm.successList += wName + ";"
		
		endfor
		
		NMParamsComputeFailures( nm )
		
		SetNMstr( NMDF + "OutputWaveList", nm.successList )
		
		return nm.successList
	
	endif
	
	// write wave notes to a notebook
	
	if ( WinType( nbName ) == 5 )
		
		DoWindow /F $nbName
		Notebook $nbName selection={endOfFile, endOfFile}
		
	elseif ( WinType( nbName ) == 0 )
	
		NMWinCascadeRect( w )
	
		DoWindow /K $nbName
		NewNotebook /F=0/K=(NMK())/N=$nbName/W=(w.left,w.top,w.right,w.bottom) as nbTitle
		Notebook $nbName selection={endOfFile, endOfFile}
		NoteBook $nbName text="NeuroMatic Wave Notes"
		NoteBook $nbName text=NMCR+"Data Folder: " + NMChild( nm.folder )
		
	else
	
		return NM2ErrorStr( 61, "nbName", nbName )
	
	endif

	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )

		wName = StringFromList( wcnt, nm.wList )
		
		NoteBook $nbName text=NMCR+NMCR+wName
			
		wNote = note( $nm.folder + wName )
		
		if ( strlen( wNote ) == 0 )
			continue
		endif
		
		NoteBook $nbName text=NMCR+wNote
		
		nm.successList += wName + ";"

	endfor
	
	NMParamsComputeFailures( nm )
	nm.windowList = nbName
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.successList )
	SetNMstr( NMDF + "OutputWinList", nm.windowList )
	
	return nm.windowList
	
End // NMWaveNotes2

//****************************************************************
//****************************************************************
//
//		X-Scale Functions
//		Align, SetScale, Redimension, etc
//
//****************************************************************
//****************************************************************

Function /S NMXWaveFunctionError( [ title ] )
	String title
	
	if ( ParamIsDefault( title ) )
		title = "NM Function Error : " + GetRTStackInfo( 2 )
	endif
	
	DoAlert /T=( title ) 0, "Encountered x-scale wave, but this function does not support XY-paired waves."
	
	return ""

End // NMXWaveFunctionError

//****************************************************************
//****************************************************************

Function NMAlignAtValueOld( alignAtZero, waveOfAlignValues )
	Variable alignAtZero // align at zero of x-axis? ( 0 ) no, align at maximum alignment value ( 1 ) yes
	String waveOfAlignValues
	
	if ( alignAtZero )
		return NMAlignAtValue( "0", waveOfAlignValues )
	else
		return NMAlignAtValue( "max", waveOfAlignValues )
	endif

End // NMAlignAtValueOld

//****************************************************************
//****************************************************************

Function NMAlignAtValue( select, waveOfAlignValues )
	String select
	String waveOfAlignValues
	
	if ( !WaveExists( $waveOfAlignValues ) )
		NM2Error( 1, waveOfAlignValues, "" )
		return NaN
	endif
	
	WaveStats /Q $waveOfAlignValues
	
	strswitch( select )
		case "0":
		case "zero":
			return 0
		case "max":
		case "max alignment value":
			return V_max
		case "min":
		case "min alignment value":
			return V_min
		case "avg":
		case "average alignment value":
			return V_avg
	endswitch
	
	return NaN
	
End // NMAlignAtValue

//****************************************************************
//****************************************************************

Function /S NMAlign2( nm, waveOfAlignValues [ alignAt, history ] ) // see Igor SetScale
	STRUCT NMParams &nm // uses nm.folder, nm.wList
	String waveOfAlignValues // wave of x-alignment values
	Variable alignAt // where on x-axis to align waves ( default is 0 )
	Variable history // ( 0 ) no history ( 1 ) print basic results to history ( 2 ) print basic results and wave-by-wave scaling operations
	
	Variable wcnt, numWaves
	Variable maxOffset, dx, startx
	String wName, waveNameShort, offsetStr
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	if ( strlen( nm.xWave ) > 0 )
		return NMXWaveFunctionError()
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	waveOfAlignValues = CheckNMWavePath( nm.folder, waveOfAlignValues )
	
	if ( NMUtilityWaveTest( waveOfAlignValues ) != 0 )
		return NM2ErrorStr( 1, "waveOfAlignValues", waveOfAlignValues )
	endif
	
	waveNameShort = NMChild( waveOfAlignValues )
	NMParamStrAdd( "wave", waveNameShort, nm )
	
	if ( numtype( alignAt ) > 0 )
		return NM2ErrorStr( 10, "alignAt", num2str( alignAt ) )
	endif
	
	NMParamVarAdd( "at", alignAt, nm )
	
	Wave offsetWave = $waveOfAlignValues
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
		
		if ( NMProgressTimer( wcnt, numWaves, "Aligning Waves..." ) == 1 )
			break
		endif
		
		if ( wcnt >= numpnts( offsetWave ) )
			break
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		if ( strlen( wName ) == 0 )
			break
		endif
		
		startx = alignAt - offsetWave[ wcnt ]
		
		if ( numtype( startx ) > 0 )
			continue
		endif
		
		Wave wtemp = $nm.folder + wName
		
		dx = deltax( wtemp )
	
		SetScale /P x startx, dx, wtemp
		
		NMLoopWaveNote( nm.folder + wName, nm.paramList )
		
		nm.successList += wName + ";"
		
		if ( history == 2 )
			NMHistory( wName + " x-axis start = " + num2str( startx ) )
		endif
	
	endfor
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.successList )
	
	if ( DataFolderExists( nm.prefixFolder ) )
		KillVariables /Z $nm.prefixFolder+"WaveStartX"
		KillVariables /Z $nm.prefixFolder+"WaveDeltaX"
	endif
	
	return nm.successList
	
End // NMAlign2

//****************************************************************
//****************************************************************

Function /S NMSetScale( wList [ folder, dim, start, startWaveName, delta, deprecation ] ) // see NMSetScale2
	String wList, folder // see description at top
	String dim // dimension ( e.g. "x" or "y" or "z" )
	Variable start // axis start
	String startWaveName // name of wave containing start values
	Variable delta // axis delta
	Variable deprecation
	
	STRUCT NMParams nm
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( NMParamsInit( folder, wList, nm ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( dim ) )
		dim = ""
	endif
	
	if ( ParamIsDefault( start ) )
		start = NaN
	endif
	
	if ( ParamIsDefault( startWaveName ) )
		startWaveName = ""
	endif
	
	if ( ParamIsDefault( delta ) )
		delta = NaN
	endif
	
	if ( ( numtype( start ) > 0 ) && ( numtype( delta ) > 0 ) && ( strlen( startWaveName ) == 0 ) )
		return "" // nothing to do
	endif
	
	if ( ( numtype( delta ) == 0 ) && ( delta <= 0 ) )
		return NM2ErrorStr( 10, "delta", num2str( delta ) )
	endif
	
	if ( strlen( startWaveName ) > 0 )
		
		if ( strlen( dim ) > 0 )
			return NMSetScale2( nm, dim = dim, startWaveName = startWaveName, delta = delta )
		else
			return NMSetScale2( nm, startWaveName = startWaveName, delta = delta )
		endif
	
	endif
	
	if ( strlen( dim ) > 0 )
		return NMSetScale2( nm, dim = dim, start = start, delta = delta )
	else
		return NMSetScale2( nm, start = start, delta = delta )
	endif
	
End // NMSetScale

//****************************************************************
//****************************************************************

Function /S NMSetScale2( nm [ dim, start, startWaveName, delta, history ] ) // see Igor SetScale
	STRUCT NMParams &nm // uses nm.folder, nm.wList
	String dim // dimension ( e.g. "x" or "y" or "z" )
	Variable start // axis start
	String startWaveName // name of wave containing start values
	Variable delta // axis delta
	Variable history
	
	Variable wcnt, t_start, t_delta, numWaves, useStartWave
	String wName
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	if ( strlen( nm.xWave ) > 0 )
		return NMXWaveFunctionError()
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	if ( ParamIsDefault( dim ) || ( strlen( dim ) == 0 ) )
		dim = "x"
	else
		NMParamStrAdd( "dim", dim, nm )
	endif
	
	if ( ParamIsDefault( start ) )
		start = NaN
	elseif ( numtype( start ) == 0 )
		NMParamVarAdd( "start", start, nm )
	endif
	
	if ( ParamIsDefault( startWaveName ) )
		startWaveName = ""
	else
		NMParamStrAdd( "startWaveName", startWaveName, nm )
	endif
	
	if ( ParamIsDefault( delta ) )
		delta = NaN
	elseif ( numtype( delta ) == 0 )
		NMParamVarAdd( "delta", delta, nm )
	endif
	
	if ( ( numtype( start ) > 0 ) && ( numtype( delta ) > 0 ) && ( strlen( startWaveName ) == 0 ) )
		return "" // nothing to do
	endif
	
	if ( ( numtype( delta ) == 0 ) && ( delta <= 0 ) )
		return NM2ErrorStr( 10, "delta", num2str( delta ) )
	endif
	
	if ( strlen( startWaveName ) > 0 )
	
		if ( WaveExists( $startWaveName ) )
			Wave stemp = $startWaveName
			useStartWave = 1
		else
			return NM2ErrorStr( 1, "startWaveName", startWaveName )
		endif
	
	endif
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		wName = StringFromList( wcnt, nm.wList )
		
		Wave wtemp = $nm.folder + wName
		
		if ( useStartWave )
			
			if ( ( wcnt < numpnts( stemp ) ) && ( numtype( stemp[ wcnt ] ) == 0 ) )
				t_start = stemp[ wcnt ]
			else
				t_start = leftx( wtemp )
			endif
		
		else
		
			if ( numtype( start ) == 0 )
				t_start = start
			else
				t_start = leftx( wtemp )
			endif
		
		endif
		
		if ( ( numtype( delta ) == 0 ) && ( delta > 0 ) )
			t_delta = delta
		else
			t_delta = deltax( wtemp )
		endif
		
		strswitch( dim )
			case "x":
				SetScale /P x t_start, t_delta, wtemp
				break
			case "y":
				SetScale /P y t_start, t_delta, wtemp
				break
			case "z":
				SetScale /P z t_start, t_delta, wtemp
				break
			case "t":
				SetScale /P t t_start, t_delta, wtemp
				break
			case "d":
				SetScale /P d t_start, t_delta, wtemp
				break
		endswitch
		
		NMLoopWaveNote( nm.folder + wName, nm.paramList ) // not necessary
		
		nm.successList += wName + ";"
		
	endfor
	
	if ( DataFolderExists( nm.prefixFolder ) )
		KillVariables /Z $nm.prefixFolder+"WaveStartX"
		KillVariables /Z $nm.prefixFolder+"WaveDeltaX"
	endif
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.successList )
	
	return nm.successList
	
End // NMSetScale2

//****************************************************************
//****************************************************************

Function /S NMXWaveMake( wList [ folder, xWave, multiple, newPrefix, overwrite, deprecation ] ) // see Igor Make
	String wList, folder // see description at top
	String xWave // name of new xWave
	Variable multiple // ( 0 ) make one x-scale wave if possible ( 1 ) make x-scale wave for each input wave
	String newPrefix // prefix name for multiple xWaves ( e.g. "xScale_" )
	Variable overwrite, deprecation
	
	STRUCT NMParams nm
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( NMParamsInit( folder, wList, nm ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( xWave ) )
		xWave = ""
	endif
	
	if ( ParamIsDefault( newPrefix ) )
		newPrefix = ""
	endif
	
	if ( multiple )
		return NMXWaveMake2( nm, multiple = multiple, newPrefix = newPrefix, overwrite = overwrite )
	else
		return NMXWaveMake2( nm, xWave = xWave, overwrite = overwrite )
	endif
	
End // NMXWaveMake

//****************************************************************
//****************************************************************

Function /S NMXWaveMake2( nm [ xWave, multiple, newPrefix, overwrite, history ] )
	STRUCT NMParams &nm // uses nm.folder, nm.wList, nm.xWave, nm.wavePrefix
	String xWave // name of new xWave ( e.g. "xScale_Record" )
	Variable multiple // ( 0 ) make one x-scale wave if possible ( 1 ) make x-scale wave for each input wave
	String newPrefix // prefix name for multiple xWaves ( e.g. "xScale_" )
	Variable overwrite, history
	
	Variable wcnt, numWaves
	String wName, xLabel
	
	STRUCT NMXAxisStruct s
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	SetNMstr( NMDF + "OutputWaveList", "" )
	
	numWaves = ItemsInList( nm.wList )
	
	if ( ( ParamIsDefault( newPrefix ) || strlen( newPrefix ) == 0 ) )
		newPrefix = NMXscalePrefix
	endif
	
	if ( strlen( nm.xLabel ) > 0 )
		xLabel = nm.xLabel
	else
		xLabel = NMNoteLabel( "x", nm.wList, "", folder = nm.folder )
	endif
	
	if ( !multiple )
	
		if ( ParamIsDefault( xWave ) )
			return NM2ErrorStr( 21, "xWave", "" )
		endif
		
		if ( !overwrite && WaveExists( $nm.folder + xWave ) )
			if ( history )
				NMLoopHistory( nm )
			else
				return ""
			endif
		endif
		
		NMParamStrAdd( "xWave", xWave, nm )
	
		NMXAxisStructInit( s, nm.wList, folder = nm.folder )
		NMXAxisStats2( s )
		
		if ( numtype( s.points * s.dx * s.leftx ) > 0 )
			return NM2ErrorStr( 90, "input waves have different time scales", "" )
		endif
			
		Make /O/N=( s.points ) $nm.folder + xWave
		
		if ( WaveExists( $nm.folder + xWave ) )
		
			Wave xtemp = $nm.folder + xWave
		
			SetScale /P x s.leftx, s.dx, xtemp
		
			xtemp = x
		
			NMNoteType( nm.folder + xWave, "NMXscale", xLabel, xLabel, "WavePrefix:" + nm.wavePrefix )
			
			nm.successList = nm.wList
			nm.newList = nm.folder + xWave
		
		endif
		
		NMParamsComputeFailures( nm )
		
		if ( history )
			NMLoopHistory( nm )
		endif
		
		SetNMstr( NMDF + "OutputWaveList", nm.newList )

		return nm.newList
	
	endif
	
	// do multiple xWaves
	
	NMParamStrAdd( "prefix", newPrefix, nm )
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		wName = StringFromList( wcnt, nm.wList )
		
		xWave = newPrefix + wName
		
		if ( !overwrite && WaveExists( $nm.folder + nm.xWave ) )
			continue
		endif
		
		Duplicate /O $( nm.folder + wName ) $nm.folder + xWave
		
		if ( WaveExists( $nm.folder + xWave ) )
		
			Wave xtemp = $nm.folder + xWave
			
			xtemp = x
			
			NMNoteType( nm.folder + xWave, "NMXscale", xLabel, xLabel, "Wave:" + wName )
			
			nm.successList += wName + ";"
			nm.newList += nm.folder + xWave + ";"
		
		endif
		
	endfor
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.newList )

	return nm.newList
	
End // NMXWaveMake2

//****************************************************************
//****************************************************************

Function /S NMRedimension( points, wList [ folder, xWave, value, deprecation ] ) // see NMRedimension2
	Variable points // number of wave points
	String wList, folder, xWave // see description at top
	Variable value // value to give new wave points if size increases
	Variable deprecation
	
	STRUCT NMParams nm
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( NMParamsInit( folder, wList, nm, xWave = xWave ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( value ) )
		value = NaN
	endif
	
	return NMRedimension2( nm, points, value = value )
	
End // NMRedimension

//****************************************************************
//****************************************************************

Function /S NMRedimension2( nm, points [ value, history ] ) // see Igor Redimension
	STRUCT NMParams &nm // uses nm.folder, nm.wList
	Variable points // number of wave points
	Variable value // value to give new wave points if size increases
	Variable history
	
	Variable wcnt, currentPnts, larger, numWaves
	String wName, paramList2
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	if ( ( numtype( points ) > 0 ) || ( points < 0 ) )
		return NM2ErrorStr( 10, "points", num2str( points ) )
	endif
	
	if ( ParamIsDefault( value ) )
		value = NaN // different from Igor, which uses 0s
	endif
	
	NMParamVarAdd( "pnts", points, nm, integer = 1 )
	paramList2 = NMCmdNumOptional( "value", value, nm.paramList )
	
	numWaves = ItemsInList( nm.wList )
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
		
		if ( NMProgressTimer( wcnt, numWaves, "Redimensioning Waves..." ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		Wave wtemp = $nm.folder + wName
		
		currentPnts = numpnts( wtemp )
		
		if ( points > currentPnts )
			
			Redimension /N=( points ) wtemp
			
			wtemp[ currentPnts, points - 1 ] = value
			
			NMLoopWaveNote( nm.folder + wName, paramList2 )
			
			larger = 1
			
		elseif ( points < currentPnts )
		
			Redimension /N=( points ) wtemp
			
			NMLoopWaveNote( nm.folder + wName, nm.paramList )
		
		endif
		
		nm.successList += wName + ";"
		
	endfor
	
	if ( larger )
		nm.paramList = paramList2
	endif
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.successList )
	
	return nm.successList
	
End // NMRedimension2

//****************************************************************
//****************************************************************

Function NMDeletePointsError( from, points )
	Variable from // delete points from this point
	Variable points // number of points to delete

	if ( ( numtype( from ) > 0 ) || ( from < 0 ) )
		return NM2Error( 10, "from", num2istr( from ) )
	endif
	
	if ( ( numtype( points ) > 0 ) || ( points <= 0 ) )
		return NM2Error( 10, "points", num2istr( points ) )
	endif
	
	return 0
	
End // NMDeletePointsError

//****************************************************************
//****************************************************************

Function /S NMDeletePoints2( nm, from, points [ history ] ) // see Igor DeletePoints
	STRUCT NMParams &nm // uses nm.folder, nm.wList
	Variable from // delete starting from this point
	Variable points // number of points to delete
	Variable history
	
	Variable wcnt, numWaves
	String wName
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	if ( NMDeletePointsError( from, points ) != 0 )
		return "" // error
	endif
	
	NMParamVarAdd( "from", from, nm, integer = 1 )
	NMParamVarAdd( "pnts", points, nm, integer = 1 )
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Deleting Wave Points..." ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		Wave wtemp = $nm.folder + wName
		
		if ( from < numpnts( wtemp ) )
		
			DeletePoints from, points, wtemp
			
			NMLoopWaveNote( nm.folder + wName, nm.paramList )
			
		endif
		
		nm.successList += wName + ";"
		
	endfor
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.successList )
	
	return nm.successList
	
End // NMDeletePoints2

//****************************************************************
//****************************************************************

Function NMInsertPointsError( at, points )
	Variable at // insert points starting at this point
	Variable points // number of points to insert
	
	if ( ( numtype( at ) > 0 ) || ( at < 0 ) )
		return NM2Error( 10, "at", num2istr( at ) )
	endif
	
	if ( ( numtype( points ) > 0 ) || ( points <= 0 ) )
		return NM2Error( 10, "points", num2istr( points ) )
	endif
	
	return 0
	
End // NMInsertPointsError

//****************************************************************
//****************************************************************

Function /S NMInsertPoints2( nm, at, points [ value, history ] ) // see Igor InsertPoints
	STRUCT NMParams &nm // uses nm.folder, nm.wList
	Variable at // insert points starting at this point
	Variable points // number of points to insert
	Variable value // value of new inserted points ( default NaN )
	Variable history
	
	Variable wcnt, icnt, numWaves
	String wName
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	if ( NMInsertPointsError( at, points ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( value ) )
		value = NaN
	endif
	
	NMParamVarAdd( "at", at, nm, integer = 1 )
	NMParamVarAdd( "pnts", points, nm, integer = 1 )
	NMParamVarAdd( "value", value, nm )
		
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Inserting Wave Points..." ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		Wave wtemp = $nm.folder + wName
		
		if ( at < numpnts( wtemp ) )
		
			InsertPoints at, points, wtemp
			
			if ( value != 0 )
				wtemp[ at, at + points - 1 ] = value
			endif
			
			NMLoopWaveNote( nm.folder + wName, nm.paramList )
		
		endif
		
		nm.successList += wName + ";"
		
	endfor
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.successList )
	
	return nm.successList
	
End // NMInsertPoints2

//****************************************************************
//****************************************************************

Function /S NMResample( wList [ folder, upSamples, downSamples, rate, deprecation ] ) // see NMResample2
	String wList, folder // see description at top
	Variable upSamples // interpolate points, or nothing for no change
	Variable downSamples // or decimate points, or nothing for no change
	Variable rate // or sample rate
	Variable deprecation
	
	STRUCT NMParams nm
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( NMParamsInit( folder, wList, nm ) != 0 )
		return ""
	endif
	
	if ( ( numtype( rate ) == 0 ) && ( rate > 0 ) )
		
		return NMResample2( nm, rate = rate )
		
	else
	
		if ( ParamIsDefault( upSamples ) )
			upSamples = 1
		endif
		
		if ( ParamIsDefault( downSamples ) )
			downSamples = 1
		endif
	
		if ( ( numtype( upSamples ) > 0 ) || ( upSamples < 1 ) )
			upSamples = 1
		endif
		
		if ( ( numtype( downSamples ) > 0 ) || ( downSamples < 1 ) )
			downSamples = 1
		endif
		
		if ( ( upSamples == 1 ) && ( downSamples == 1 ) )
			return "" // nothing to do
		endif
		
		return NMResample2( nm, upSamples = upSamples, downSamples = downSamples )
	
	endif
	
End // NMResample

//****************************************************************
//****************************************************************

Function /S NMResample2( nm [ upSamples, downSamples, rate, history ] ) // see Igor Resample
	STRUCT NMParams &nm // uses nm.folder, nm.wList
	Variable upSamples // interpolate points, or nothing for no change
	Variable downSamples // or decimate points, or nothing for no change
	Variable rate // or sample rate
	Variable history
	
	Variable wcnt, rateflag, numWaves
	String wName
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	if ( strlen( nm.xWave ) > 0 )
		return NMXWaveFunctionError()
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	if ( ParamIsDefault( upSamples ) )
		upSamples = 1
	endif
	
	if ( ParamIsDefault( downSamples ) )
		downSamples = 1
	endif
	
	if ( ( numtype( rate ) == 0 ) && ( rate > 0 ) )
	
		rateflag = 1
		upSamples = 1
		downSamples = 1
		
		NMParamVarAdd( "rate", rate, nm )
		
	else
	
		if ( ( numtype( upSamples ) > 0 ) || ( upSamples < 1 ) )
			upSamples = 1
		endif
		
		if ( ( numtype( downSamples ) > 0 ) || ( downSamples < 1 ) )
			downSamples = 1
		endif
		
		if ( ( upSamples == 1 ) && ( downSamples == 1 ) )
			return "" // nothing to do
		endif
		
		if ( upSamples != 1 )
			NMParamVarAdd( "up", upSamples, nm, integer = 1 )
		endif
		
		if ( downSamples != 1 )
			NMParamVarAdd( "down", downSamples, nm, integer = 1 )
		endif
	
	endif
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Resampling Waves..." ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		Wave wtemp = $nm.folder + wName
		
		if ( rateflag == 1 )
			Resample /RATE=( rate ) wtemp
		else
			Resample /UP=( upSamples ) /DOWN=( downSamples ) wtemp
		endif
		
		NMLoopWaveNote( nm.folder + wName, nm.paramList )
		
		nm.successList += wName + ";"
		
	endfor
	
	if ( DataFolderExists( nm.prefixFolder ) )
		KillVariables /Z $nm.prefixFolder + "WaveStartX"
		KillVariables /Z $nm.prefixFolder + "WaveDeltaX"
	endif
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.successList )
	
	return nm.successList
	
End // NMResample2

//****************************************************************
//****************************************************************

Function NMDecimateError( alg, downSamples, rate )
	String alg
	Variable downSamples
	Variable rate
	
	strswitch( alg )
		case "linear":
		case "cubic spline":
		case "smoothing spline":
			break
		default:
			return NM2Error( 10, "alg", alg )
	endswitch
	
	if ( ( numtype( rate ) == 0 ) && ( rate > 0 ) )
		return 0 // OK
	endif
		
	if ( ( numtype( downSamples ) == 0 ) && ( round( downSamples ) > 1 ) )
		return 0 // OK
	endif
		
	return -1 // nothing to do

End // NMDecimateError

//****************************************************************
//****************************************************************

Function /S NMDecimate( wList [ folder, xWave, downSamples, rate, algorithm, alg, deprecation ] ) // see NMDecimate2
	String wList, folder, xWave // see description at top
	Variable downSamples // number of points to down sample
	Variable rate // or new rate
	Variable algorithm // ( 1 ) linear ( 2 ) cubic spline ( 3 ) smoothing spline Interpolation
	String alg // // "linear" or "cubic spline" or "smoothing spline"
	Variable deprecation
	
	STRUCT NMParams nm
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( NMParamsInit( folder, wList, nm, xWave = xWave ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( algorithm ) )
	
		if ( ParamIsDefault( alg ) )
			alg = NMInterpolateAlg
		endif
		
	else
	
		alg = NMInterpolateAlgStr( algorithm )
		
	endif
	
	if ( ParamIsDefault( downSamples ) )
	
		if ( ParamIsDefault( rate ) )
			return NM2ErrorStr( 11, "downSamples", "" )
		else
			return NMDecimate2( nm, rate = rate, alg = alg )
		endif	
	
	else
	
		return NMDecimate2( nm, downSamples = downSamples, alg = alg )
		
	endif
	
End // NMDecimate

//****************************************************************
//****************************************************************

Function /S NMDecimate2( nm [ downSamples, rate, algorithm, alg, history ] ) // see Igor Interpolate2
	STRUCT NMParams &nm // uses nm.folder, nm.wList, nm.xWave
	Variable downSamples // number of points to down sample
	Variable rate // or new rate
	Variable algorithm // ( 1 ) linear ( 2 ) cubic spline ( 3 ) smoothing spline Interpolation
	String alg // "linear" or "cubic spline" or "smoothing spline"
	Variable history
	
	Variable wcnt, numWaves, xflag
	Variable newDX, rateFlag, dx, npnts, newNpnts
	String wName, oldnote, uName
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	if ( ParamIsDefault( downSamples ) )
	
		if ( ParamIsDefault( rate ) )
			return NM2ErrorStr( 11, "downSamples", "" )
		else
			rateFlag = 1
			newDX = 1 / rate
			NMParamVarAdd( "rate", rate, nm )
		endif
		
	else
	
		NMParamVarAdd( "down", downSamples, nm, integer = 1 )
		
	endif
	
	if ( ParamIsDefault( algorithm ) )
	
		if ( ParamIsDefault( alg ) )
			alg = NMInterpolateAlg
		endif
		
		algorithm = NMInterpolateAlgNum( alg )
		
	else
	
		alg = NMInterpolateAlgStr( algorithm )
		
	endif
	
	if ( NMDecimateError( alg, downSamples, rate ) != 0 )
		return "" // error
	endif
	
	NMParamStrAdd( "alg", alg, nm )
	
	uName = nm.folder + "U_NMDecimateTemp"
	
	if ( strlen( nm.xWave ) > 0 )
		xflag = 1
	endif
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Decimating Waves..." ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		Wave wtemp = $nm.folder + wName
		
		dx = deltax( wtemp )
		npnts = numpnts( wtemp )
		
		if ( rateFlag )
		
			if ( newDX <= dx )
				continue // this is not decimating
			endif
			
			newNpnts = abs( ( rightx( wtemp ) - leftx( wtemp ) ) / newDX )
		
		else
		
			newNpnts = floor( numpnts( wtemp ) / downSamples )
		
		endif
		
		if ( ( numtype( newNpnts ) > 0 ) || ( newNpnts <= 1 ) )
			continue // not allowed
		endif
		
		if ( newNpnts < npnts )
		
			if ( xflag )
				Interpolate2 /T=( algorithm ) /N=( newNpnts )/Y=$uName $nm.folder + nm.xWave, wtemp
			else
				Interpolate2 /T=( algorithm ) /N=( newNpnts )/Y=$uName wtemp
			endif
			
			if ( WaveExists( $uName ) == 1 )
			
				Wave utemp = $uName
			
				oldnote = note( wtemp )
				
				Duplicate /O $uName, wtemp
				
				if ( rateFlag )
					SetScale /P x 0, ( newDX ), wtemp
				else
					SetScale /P x 0, ( dx * downSamples ), wtemp
				endif
				
				Note /K wtemp
				Note wtemp, oldnote
				
				NMLoopWaveNote( nm.folder + wName, nm.paramList )
			
			endif
			
		endif
		
		nm.successList += wName + ";"
			
	endfor
	
	KillWaves /Z $uName
	
	if ( DataFolderExists( nm.prefixFolder ) )
		KillVariables /Z $nm.prefixFolder + "WaveStartX"
		KillVariables /Z $nm.prefixFolder + "WaveDeltaX"
	endif
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.successList )

	return nm.successList
	
End // NMDecimate2

//****************************************************************
//****************************************************************

Function NMInterpolateError( alg, xmode, xWaveNew )
	String alg // "linear" or "cubic spline" or "smoothing spline"
	Variable xmode // ( 1 ) find common x-axis ( 2 ) use x-axis scale of xWave ( 3 ) use point values of xWave as x-scale
	String xWaveNew // x-scale wave for xmode 2 or 3

	strswitch( alg )
		case "linear":
		case "cubic spline":
		case "smoothing spline":
			break
		default:
			return NM2Error( 10, "alg", alg )
	endswitch
	
	switch( xmode )
	
		case 1:
			break
			
		case 2:
		case 3:
		
			if ( strlen( xWaveNew ) == 0 )
				return NM2Error( 21, "xWaveNew", xWaveNew )
			elseif ( NMUtilityWaveTest( xWaveNew ) != 0 )
				return NM2Error( 1, "xWaveNew", xWaveNew )
			endif
			
			break
		
		default:
			return NM2Error( 10, "xmode", num2istr( xmode ) )
			
	endswitch

	return 0
	
End // NMInterpolateError

//****************************************************************
//****************************************************************

Function /S NMInterpolateAlgStr( algorithm )
	Variable algorithm // ( 1 ) linear ( 2 ) cubic spline ( 3 ) smoothing spline Interpolation
	
	switch( algorithm )
		case 1:
			return "linear"
		case 2:
			return "cubic spline"
		case 3:
			return "smoothing spline"
	endswitch
	
	return "" // error
	
End // NMInterpolateAlgStr

//****************************************************************
//****************************************************************

Function NMInterpolateAlgNum( alg )
	String alg // "linear" or "cubic spline" or "smoothing spline"
	
	strswitch( alg )
		case "linear":
			return 1
		case "cubic spline":
			return 2
		case "smoothing spline":
			return 3
	endswitch
	
	return NaN // error
	
End // NMInterpolateAlgNum

//****************************************************************
//****************************************************************

Function /S NMInterpolate( wList [ folder, xWave, algorithm, alg, xmode, xWaveNew, deprecation ] ) // see NMInterpolate2
	String wList, folder, xWave // see description at top
	Variable algorithm // ( 1 ) linear ( 2 ) cubic spline ( 3 ) smoothing spline Interpolation
	String alg // "linear" or "cubic spline" or "smoothing spline"
	Variable xmode // ( 1 ) find common x-axis ( 2 ) use x-axis scale of xWaveNew ( 3 ) use point values of xWaveNew as x-scale
	String xWaveNew // x-scale wave for xmode 2 or 3
	Variable deprecation
	
	STRUCT NMParams nm
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( NMParamsInit( folder, wList, nm, xWave = xWave ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( algorithm ) )
	
		if ( ParamIsDefault( alg ) )
			alg = NMInterpolateAlg
		endif
		
	else
	
		alg = NMInterpolateAlgStr( algorithm )
		
	endif
	
	if ( ParamIsDefault( xmode ) )
		xmode = 1
	endif
	
	if ( ParamIsDefault( xWaveNew ) )
		xWaveNew = ""
	endif
	
	if ( xmode == 1 )
		return NMInterpolate2( nm, alg = alg, xmode = xmode )
	else
		return NMInterpolate2( nm, alg = alg, xmode = xmode, xWaveNew = xWaveNew )
	endif

End // NMInterpolate

//****************************************************************
//****************************************************************

Function /S NMInterpolate2( nm [ algorithm, alg, xmode, xWaveNew, history ] ) // see Igor Interpolate
	STRUCT NMParams &nm // uses nm.folder, nm.wList, nm.xWave
	Variable algorithm // ( 1 ) linear ( 2 ) cubic spline ( 3 ) smoothing spline Interpolation
	String alg // "linear" or "cubic spline" or "smoothing spline"
	Variable xmode // ( 1 ) find common x-axis ( 2 ) use x-axis scale of xWaveNew ( 3 ) use point values of xWaveNew as x-scale
	String xWaveNew // x-scale wave for xmode 2 or 3
	Variable history
	
	Variable wcnt, numWaves, xflag
	Variable newNpnts, newDX, newLeftX, newRightX, lftx, rgtx, p1, p2
	String wName, oldnote, uNameX, uNameY
	
	STRUCT NMXAxisStruct s
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	if ( ParamIsDefault( algorithm ) )
	
		if ( ParamIsDefault( alg ) )
			alg = NMInterpolateAlg
		endif
		
		algorithm = NMInterpolateAlgNum( alg )
		
	else
	
		alg = NMInterpolateAlgStr( algorithm )
		
	endif
	
	if ( ParamIsDefault( xmode ) )
		xmode = 1
	endif
	
	if ( ParamIsDefault( xWaveNew ) )
		xWaveNew = ""
	endif
	
	if ( NMInterpolateError( alg, xmode, xWaveNew ) != 0 )
		return "" // error
	endif
	
	NMParamStrAdd( "alg", alg, nm )
	NMParamVarAdd( "mode", xmode, nm, integer = 1 )
	
	if ( ( xmode == 2 ) || ( xmode == 3 ) )
		NMParamStrAdd( "xwave", xWaveNew, nm )
	endif
	
	uNameX = nm.folder + "U_NMInterpolateTempX"
	uNameY = nm.folder + "U_NMInterpolateTempY"
	
	if ( strlen( nm.xWave ) > 0 )
		xflag = 1
	endif
	
	switch( xmode )
	
		case 1: // make common x-axis
		
			if ( xflag )
				WaveStats /Q $nm.folder + nm.xWave
				newLeftX = V_min
				newRightX = V_max
				newDX = NMXwaveMinDX( nm.folder + nm.xWave )
			else
				
				NMXAxisStructInit( s, nm.wList, folder = nm.folder )
				NMXAxisStats2( s )
				
				//newDX = s.maxDX
				newDX = s.minDX // probably best to use smallest dx
				newLeftX = s.minLeftx
				newRightX = s.maxRightx
			endif
			
			newNpnts = ( newRightX - newLeftX ) / newDX
			
			if ( ( numtype( newNpnts ) > 0 ) || ( newNpnts <= 0 ) )
				return NM2ErrorStr( 10, "newNpnts", num2istr( newNpnts ) )
			endif
			
			Make /O/N=( newNpnts ) $uNameX
			
			Wave xtemp = $uNameX
			
			xtemp = newLeftX + x * newDX
			
			break
			
		case 2: // use x-axis scale of xWaveNew
			
			newDX = deltax( $xWaveNew )
			newLeftX = leftx( $xWaveNew )
			newRightX = rightx( $xWaveNew )
			newNpnts = numpnts( $xWaveNew )
			
			Duplicate /O $xWaveNew $uNameX
			
			Wave xtemp = $uNameX
			
			xtemp = x
			
			break
			
		case 3: // use point values of xWaveNew as x-scale
			
			WaveStats /Q $xWaveNew
			
			newLeftX = V_min
			newRightX = V_max
			newDX = NMXwaveMinDX( xWaveNew )
			
			newNpnts = ( newRightX - newLeftX ) / newDX
			
			if ( ( numtype( newNpnts ) > 0 ) || ( newNpnts <= 0 ) )
				return NM2ErrorStr( 10, "newNpnts", num2istr( newNpnts ) )
			endif
			
			Make /O/N=( newNpnts ) $uNameX
			
			Wave xtemp = $uNameX
			
			xtemp = newLeftX + x * newDX
			
			break
			
		default:
			return NM2ErrorStr( 10, "xmode", num2istr( xmode ) )
			
	endswitch
	
	if ( ( numtype( newNpnts ) > 0 ) || ( newNpnts <= 0 ) )
		return NM2ErrorStr( 10, "newNpnts", num2istr( newNpnts ) )
	endif
	
	if ( ( numtype( newDX ) > 0 ) || ( newDX <= 0 ) )
		return NM2ErrorStr( 10, "newDX", num2str( newDX ) )
	endif
	
	if ( numtype( newLeftX ) > 0 )
		return NM2ErrorStr( 10, "newLeftX", num2str( newLeftX ) )
	endif
	
	if ( numtype( newRightX ) > 0 )
		return NM2ErrorStr( 10, "newRightX", num2str( newRightX ) )
	endif
	
	for ( wcnt = 0; wcnt < numWaves; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Interpolating Waves..." ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		Wave wtemp = $nm.folder + wName
		
		lftx = leftx( wtemp )
		rgtx = rightx( wtemp )
		
		if ( xflag )
			Interpolate2 /T=( algorithm )/I=3/Y=$uNameY /X=$uNameX $nm.folder + nm.xWave, wtemp
		else
			Interpolate2 /T=( algorithm )/I=3/Y=$uNameY /X=$uNameX wtemp
		endif

		if ( WaveExists( $uNameY ) )
		
			oldnote = note( wtemp )
			
			Duplicate /O $uNameY, wtemp
			SetScale /P x newLeftX, newDX, wtemp
			
			p1 = x2pnt( wtemp, newLeftX )
			p2 = x2pnt( wtemp, lftx )
			
			if ( ( numtype( p1 * p2 ) == 0 ) && ( p2 > p1 ) && ( p1 >= 0 ) && ( p2 < numpnts( wtemp ) ) )
				wtemp[ p1, p2 ] = NaN
			endif
			
			p1 = x2pnt( wtemp, rgtx )
			p2 = x2pnt( wtemp, newRightX )
			
			if ( ( numtype( p1 * p2 ) == 0 ) && ( p2 > p1 ) && ( p1 >= 0 ) && ( p2 < numpnts( wtemp ) ) )
				wtemp[ p1, p2 ] = NaN
			endif
			
			Note /K wtemp
			Note wtemp, oldnote
			
			NMLoopWaveNote( nm.folder + wName, nm.paramList )
			
			nm.successList += wName + ";"
			
		endif
		
	endfor
	
	KillWaves /Z $uNameX, $uNameY
	
	if ( DataFolderExists( nm.prefixFolder ) )
		KillVariables /Z $nm.prefixFolder + "WaveStartX"
		KillVariables /Z $nm.prefixFolder + "WaveDeltaX"
	endif
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.successList )

	return nm.successList

End // NMInterpolate2

//****************************************************************
//****************************************************************

Function NMXwaveMinDX( xWave )
	String xWave
	
	Variable icnt, found, dx, minDX = inf
	
	if ( !WaveExists( $xWave ) )
		return NaN
	endif
	
	Wave xtemp = $xWave
	
	for ( icnt = 1 ; icnt < numpnts( xtemp ) ; icnt += 1 )
	
		dx = xtemp[ icnt ] - xtemp[ icnt - 1 ]
		
		if ( ( numtype( dx ) == 0 ) && ( dx < minDX ) )
			found = 1
			minDX = dx
		endif
		
	endfor
	
	return minDX
	
End // NMXwaveMinDX

//****************************************************************
//****************************************************************

Function /S NMXScaleMode2( nm, mode [ timeBetweenWaves, history ] )
	STRUCT NMParams &nm // uses nm.folder, nm.wList
	String mode // "episodic" or "continuous"
	Variable timeBetweenWaves // for continuous
	Variable history
	
	Variable wcnt, numWaves, dx, xbgn = NaN
	String wName
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	if ( strlen( nm.xWave ) > 0 )
		return NMXWaveFunctionError()
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	strswitch( mode )
		case "episodic":
		case "continuous":
			break
		default:
			return NM2ErrorStr( 21, "mode", mode )
	endswitch
	
	NMParamStrAdd( "mode", mode, nm )
	
	if ( !ParamIsDefault( timeBetweenWaves ) )
		NMParamVarAdd( "dw", timeBetweenWaves, nm )
	endif
	
	if ( ( numtype( timeBetweenWaves ) > 0 ) || ( timeBetweenWaves < 0 ) )
		return NM2ErrorStr( 10, "timeBetweenWaves", num2str( timeBetweenWaves ) )
	endif
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		wName = StringFromList( wcnt, nm.wList )
		
		Wave wtemp = $nm.folder + wName
		
		if ( numtype( xbgn ) > 0 )
			xbgn = leftx( wtemp )
		endif
		
		if ( StringMatch( mode, "continuous" ) )
			dx = deltax( wtemp )
			SetScale /P x xbgn, dx, wtemp
			xbgn = rightx( wtemp ) + timeBetweenWaves
		else // episodic
			dx = deltax( wtemp )
			SetScale /P x xbgn, dx, wtemp
		endif
		
		nm.successList += wName + ";"
		
	endfor
	
	if ( DataFolderExists( nm.prefixFolder ) )
		KillVariables /Z $nm.prefixFolder + "WaveStartX"
		KillVariables /Z $nm.prefixFolder + "WaveDeltaX"
	endif
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.successList )
	
	return nm.successList
	
End // NMXScaleMode2

//****************************************************************
//****************************************************************

Function NMTimeScaleConvertError( oldUnits, newUnits )
	String oldUnits // old time scale units
	String newUnits // new time scale units
	
	if ( strlen( oldUnits ) == 0 )
		return NM2Error( 21, "oldUnits", "" )
	endif
	
	if ( strlen( newUnits ) == 0 )
		return NM2Error( 21, "newUnits", "" )
	endif
	
	if ( strlen( NMTimeUnitsCheck( oldUnits ) ) == 0 )
		return NM2Error( 20, "oldUnits", oldUnits )
	endif
	
	if ( strlen( NMTimeUnitsCheck( newUnits ) ) == 0 )
		return NM2Error( 20, "newUnits", newUnits )
	endif
	
	if ( StringMatch( oldUnits, newUnits ) )
		return 1 // nothing to do
	endif
	
	return 0

End // NMTimeScaleConvertError

//****************************************************************
//****************************************************************

Function /S NMTimeScaleConvert2( nm, oldUnits, newUnits [ history ] )
	STRUCT NMParams &nm // uses nm.folder, nm.wList
	
	String oldUnits // old time scale units
	String newUnits // new time scale units
	Variable history
	
	Variable wcnt, numWaves, scale, newStartX, newDeltaX
	String wName, labelStr, paramList, fxn = "NMTimeScaleConvert"
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	if ( NMTimeScaleConvertError( oldUnits, newUnits ) != 0 )
		return ""
	endif
	
	scale = NMTimeUnitsConvertScale( oldUnits, newUnits )
	
	if ( ( numtype( scale ) > 0 ) || ( scale <= 0 ) )
		return NM2ErrorStr( 10, "scale", num2str( scale ) )
	endif
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		wName = StringFromList( wcnt, nm.wList )
		
		Wave wtemp = $nm.folder + wName
		
		if ( scale != 1 )
		
			newStartX = leftx( wtemp ) * scale
			newDeltaX = deltax( wtemp ) * scale
			
			SetScale /P x newStartX, newDeltaX, wtemp
			
			paramList = "start=" + num2str( newStartX ) + ";"
			paramList += "delta=" + num2str( newDeltaX ) + ";"
			
			NMLoopWaveNote( nm.folder + wName, paramList )
			
			NMNoteStrReplace( nm.folder + wName, "XUnits", newUnits )
			
			labelStr = NMNoteStrByKey( nm.folder + wName, "XLabel" )
			
			if ( strlen( labelStr ) > 0 )
				labelStr = ReplaceString( oldUnits, labelStr, newUnits )
				NMNoteStrReplace( nm.folder + wName, "XLabel", labelStr )
			endif
		
		endif
		
		nm.successList += wName + ";"
		
	endfor
	
	if ( DataFolderExists( nm.prefixFolder ) )
		KillVariables /Z $nm.prefixFolder + "WaveStartX"
		KillVariables /Z $nm.prefixFolder + "WaveDeltaX"
	endif
	
	//nm.fxn += " " + oldUnits + "-->" + newUnits
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.successList )
	
	return nm.successList
	
End // NMTimeScaleConvert2

//****************************************************************
//****************************************************************
//
//	Operations
//	Baseline, Normalize, ScaleByNum, Smooth...
//
//****************************************************************
//****************************************************************

Function /S NMBaseline( wList [ folder, xWave, xbgn, xend, allWavesAvg, DFOF, Zscore, deprecation ] )
	String wList, folder, xWave // see description at top
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	Variable allWavesAvg // ( 0 ) no, baseline to each wave's mean ( 1 ) baseline to mean of all selected waves
	Variable DFOF // compute dF/Fo baseline ( 0 ) no ( 1 ) yes
	Variable Zscore // compute z-score ( 0 ) no ( 1 ) yes
	Variable deprecation
	
	STRUCT NMParams nm
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( NMParamsInit( folder, wList, nm, xWave = xWave ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	return NMBaseline2( nm, xbgn = xbgn, xend = xend, allWavesAvg = allWavesAvg, DFOF = DFOF, Zscore = Zscore )
	
End // NMBaseline

//****************************************************************
//****************************************************************

Function /S NMBaseline2( nm [ xbgn, xend, allWavesAvg, DFOF, Zscore, history ] )
	STRUCT NMParams &nm // uses nm.folder, nm.wList, nm.xWave
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	Variable allWavesAvg // ( 0 ) no, baseline to each wave's mean ( 1 ) baseline to mean of all selected waves
	Variable DFOF // compute dF/Fo ( 0 ) no ( 1 ) yes
	Variable Zscore // compute z-score ( 0 ) no ( 1 ) yes
	Variable history
	
	Variable wcnt, numWaves, pbgn, pend, xflag
	Variable avg, stdv, count, saveValues
	String wName, paramList2
	String mnsd, thisFxn = GetRTStackInfo( 1 )
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( ( numtype( xbgn ) == 0 ) || ( numtype( xend ) == 0 ) )
		NMParamVarAdd( "xbgn", xbgn, nm )
		NMParamVarAdd( "xend", xend, nm )
	endif
	
	if ( strlen( nm.xWave ) > 0 )
		pbgn = NMX2Pnt( nm.folder + nm.xWave, xbgn )
		pend = NMX2Pnt( nm.folder + nm.xWave, xend )
		NMParamStrAdd( "xwave", nm.xWave, nm )
		xflag = 1
	endif
	
	if ( DFOF )
		NMParamVarAdd( "DFOF", DFOF, nm, integer = 1 )
	endif
	
	if ( Zscore )
		NMParamVarAdd( "Zscore", Zscore, nm, integer = 1 )
	endif
	
	if ( allWavesAvg )
	
		for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
		
			wName = StringFromList( wcnt, nm.wList )
			
			Wave wtemp = $nm.folder + wName
			
			if ( !xflag )
				pbgn = x2pnt( wtemp, xbgn )
				pend = x2pnt( wtemp, xend )
				pbgn = max( pbgn, 0 )
				pend = min( pend, numpnts( wtemp ) - 1 )
			endif
			
			WaveStats /Q/R=[ pbgn, pend ] wtemp
			
			avg += V_avg
			stdv += V_sdev
			
		endfor
		
		avg /= numWaves
		stdv /= numWaves
		
		if ( numtype( avg ) > 0 )
			if ( history )
				NMHistory( thisFxn + " Abort : encountered bad baseline average for all waves : " + num2str( avg ) )
			endif
			return ""
		endif
	
	endif
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Baselining Waves..." ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		Wave wtemp = $nm.folder + wName
		
		if ( !allWavesAvg )
		
			if ( !xflag )
				pbgn = x2pnt( wtemp, xbgn )
				pend = x2pnt( wtemp, xend )
				pbgn = max( pbgn, 0 )
				pend = min( pend, numpnts( wtemp ) - 1 )
			endif
		
			WaveStats /Q/R=[ pbgn, pend ] wtemp
			
			avg = V_avg
			stdv = V_sdev
			
		endif
		
		if ( numtype( avg ) > 0 )
			if ( history )
				NMHistory( thisFxn + " Error : encountered bad baseline average for wave " + wName )
			endif
			continue
		endif
		
		if ( DFOF )
		
			if ( avg == 0 )
				if ( history )
					NMHistory( thisFxn + " Error DFOF : encountered divide by zero for wave " + wName )
				endif
				continue // not allowed
			endif
		
			MatrixOp /O wtemp = ( wtemp - avg ) / avg
			
		elseif ( Zscore )
		
			if ( ( numtype( stdv ) > 0 ) || ( stdv == 0 ) )
				if ( history )
					NMHistory( thisFxn + " Error Zscore : encountered bad stdv for wave " + wName )
				endif
				continue // not allowed
			endif
			
			MatrixOp /O wtemp = ( wtemp - avg ) / stdv
			
		else
			
			if ( avg != 0 )
				MatrixOp /O wtemp = wtemp - avg
			endif
			
		endif
		
		paramList2 = NMCmdNumOptional( "avg", avg, nm.paramList )
		
		NMLoopWaveNote( nm.folder + wName, paramList2 )
		
		nm.successList += wName + ";"
		
	endfor
	
	if ( allWavesAvg )
		NMParamVarAdd( "avg", avg, nm )
	endif
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.successList )
	
	return nm.successList
	
End // NMBaseline2

//****************************************************************
//****************************************************************

Function NMNormalizeCall( df [ promptStr, all, n ] )
	String df // data folder where normalize variables are stored
	String promptStr
	Variable all
	STRUCT NMNormalizeStruct &n // or use this structure instead of fxn1, xbgn1, etc

	Variable avgWin1, avgWin2, xbgn1, xend1, xbgn2, xend2, minValue, maxValue, allWavesAvg
	String fxn1, fxn2, mdf = NMMainDF
	
	if ( ParamIsDefault( promptStr ) )
		promptStr = ""
	endif
	
	fxn1 = StrVarOrDefault( mdf+"Norm_Fxn1", "Avg" )
	fxn1 = StrVarOrDefault( df+"Norm_Fxn1", fxn1 )
	
	if ( StringMatch( fxn1[ 0, 5 ], "MinAvg" ) )
		fxn1 = "MinAvg"
		avgWin1 = str2num( fxn1[ 6, inf ] )
	endif
	
	avgWin1 = NumVarOrDefault( mdf+"Norm_AvgWin1", avgWin1 )
	avgWin1 = NumVarOrDefault( df+"Norm_AvgWin1", avgWin1 )
	
	xbgn1 = NumVarOrDefault( mdf+"Bsln_Bgn", NMBaselineXbgn )
	xbgn1 = NumVarOrDefault( mdf+"Norm_Xbgn1", xbgn1 )
	xbgn1 = NumVarOrDefault( df+"Norm_Xbgn1", xbgn1 )
	
	xend1 = NumVarOrDefault( mdf+"Bsln_End", NMBaselineXend )
	xend1 = NumVarOrDefault( mdf+"Norm_Xend1", xend1 )
	xend1 = NumVarOrDefault( df+"Norm_Xend1", xend1 )
	
	minValue = NumVarOrDefault( mdf+"Norm_MinValue", 0 )
	minValue = NumVarOrDefault( df+"Norm_MinValue", minValue )
	
	fxn2 = StrVarOrDefault( mdf+"Norm_Fxn2", "Max" )
	fxn2 = StrVarOrDefault( df+"Norm_Fxn2", fxn2 )
	
	if ( StringMatch( fxn2[ 0, 5 ], "MaxAvg" ) )
		fxn2 = "MaxAvg"
		avgWin2 = str2num( fxn2[ 6, inf ] )
	endif
	
	avgWin2 = NumVarOrDefault( mdf+"Norm_AvgWin2", avgWin2 )
	avgWin2 = NumVarOrDefault( df+"Norm_AvgWin2", avgWin2 )
	
	xbgn2 = NumVarOrDefault( mdf+"Norm_Xbgn2", -inf )
	xbgn2 = NumVarOrDefault( df+"Norm_Xbgn2", xbgn2 )
	
	xend2 = NumVarOrDefault( mdf+"Norm_Xend2", inf )
	xend2 = NumVarOrDefault( df+"Norm_Xend2", xend2 )
	
	maxValue = NumVarOrDefault( mdf+"Norm_MaxValue", 1 )
	maxValue = NumVarOrDefault( df+"Norm_MaxValue", maxValue )
	
	allWavesAvg = NumVarOrDefault( mdf+"Norm_AllWavesAvg", 0 )
	allWavesAvg = NumVarOrDefault( df+"Norm_AllWavesAvg", allWavesAvg )
	
	strswitch( fxn1 )
		case "Avg":
		case "Min":
		case "MinAvg":
			break
		default:
			fxn1 = "Avg"
	endswitch
	
	if ( numtype( xbgn1 ) > 0 )
		xbgn1 = -inf
	endif
	
	if ( numtype( xend1 ) > 0 )
		xend2 = inf
	endif
	
	strswitch( fxn2 )
		case "Avg":
		case "Max":
		case "MaxAvg":
			break
		default:
			fxn2 = "Max"
	endswitch
	
	if ( numtype( xbgn2 ) > 0 )
		xbgn2 = -inf
	endif
	
	if ( numtype( xend2 ) > 0 )
		xend2 = inf
	endif
	
	Prompt fxn1, "algorithm to compute y-minimum:", popup "Avg;Min;MinAvg;"
	Prompt xbgn1, NMPromptAddUnitsX( "x-axis window begin" )
	Prompt xend1, NMPromptAddUnitsX( "x-axis window end" )
	Prompt minValue, "normalize data minimum to:"
	
	DoPrompt "Norm Y-min : " + promptStr, fxn1, xbgn1, xend1, minValue
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	if ( StringMatch( fxn1, "MinAvg" ) )
	
		if ( numtype( avgWin1 ) > 0 )
			avgWin1 = 1
		endif
		
		Prompt avgWin1, "window to average around detected min value (ms):"
		DoPrompt "Norm MinAvg : " + promptStr, avgWin1
		
		if ( V_flag == 1 )
			return -1 // cancel
		endif
		
		if ( ( numtype( avgWin1 ) > 0 ) || ( avgWin1 <= 0 ) )
			return -1 // cancel
		endif
		
		SetNMvar( df+"Norm_AvgWin1", avgWin1 )
		SetNMvar( mdf+"Norm_AvgWin1", avgWin1 )
		
	else
	
		avgWin1 = 0
		
	endif
	
	SetNMstr( df+"Norm_Fxn1", fxn1 )
	SetNMvar( df+"Norm_Xbgn1", xbgn1 )
	SetNMvar( df+"Norm_Xend1", xend1 )
	SetNMvar( df+"Norm_MinValue", minValue )
	
	SetNMstr( mdf+"Norm_Fxn1", fxn1 )
	SetNMvar( mdf+"Norm_Xbgn1", xbgn1 )
	SetNMvar( mdf+"Norm_Xend1", xend1 )
	SetNMvar( mdf+"Norm_MinValue", minValue )
	
	Prompt fxn2, "algorithm to compute y-maximum:", popup "Avg;Max;MaxAvg;"
	Prompt xbgn2, NMPromptAddUnitsX( "x-axis window begin" )
	Prompt xend2, NMPromptAddUnitsX( "x-axis window end" )
	Prompt maxValue, "normalize data maximum to:"
	
	DoPrompt "Norm Y-max : " + promptStr, fxn2, xbgn2, xend2, maxValue
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	if ( StringMatch( fxn2, "MaxAvg" ) )
	
		if ( numtype( avgWin2 ) > 0 )
			avgWin2 = 1
		endif
		
		Prompt avgWin2, "window to average around detected max value (ms):"
		DoPrompt "Norm MaxAvg : " + promptStr, avgWin2
		
		if ( V_flag == 1 )
			return -1 // cancel
		endif
		
		if ( ( numtype( avgWin2 ) > 0 ) || ( avgWin2 <= 0 ) )
			return -1 // cancel
		endif
		
		SetNMvar( df+"Norm_AvgWin2", avgWin2 )
		SetNMvar( mdf+"Norm_AvgWin2", avgWin2 )
		
	else
	
		avgWin2 = 0
		
	endif
	
	SetNMstr( df+"Norm_Fxn2", fxn2 )
	SetNMvar( df+"Norm_Xbgn2", xbgn2 )
	SetNMvar( df+"Norm_Xend2", xend2 )
	SetNMvar( df+"Norm_MaxValue", maxValue )
	
	SetNMstr( mdf+"Norm_Fxn2", fxn2 )
	SetNMvar( mdf+"Norm_Xbgn2", xbgn2 )
	SetNMvar( mdf+"Norm_Xend2", xend2 )
	SetNMvar( mdf+"Norm_MaxValue", maxValue )
	
	if ( all )
	
		allWavesAvg += 1
	
		Prompt allWavesAvg, "normalize each wave to:", popup "its individual avg min/max values;the avg min/max values of all selected waves;"
		DoPrompt "Norm All Avg : " + promptStr, allWavesAvg
		
		if ( V_flag == 1 )
			return -1 // cancel
		endif
		
		allWavesAvg -= 1
		
	else
	
		allWavesAvg = 0
		
	endif
	
	SetNMvar( df+"Norm_AllWavesAvg", allWavesAvg )
	SetNMvar( mdf+"Norm_AllWavesAvg", allWavesAvg )
	
	n.fxn1 = fxn1
	n.avgWin1 = avgWin1
	n.xbgn1 = xbgn1
	n.xend1 = xend1
	n.minValue = minValue
	
	n.fxn2 = fxn2
	n.avgWin2 = avgWin2
	n.xbgn2 = xbgn2
	n.xend2 = xend2
	n.maxValue = maxValue
	
	n.allWavesAvg = allWavesAvg
	
	return 0
	
End // NMNormalizeCall

//****************************************************************
//****************************************************************

Structure NMNormalizeStruct

	String fxn1
	Variable avgWin1, xbgn1, xend1, minValue
	
	String fxn2
	Variable avgWin2, xbgn2, xend2, maxValue
	
	Variable allWavesAvg

EndStructure

//****************************************************************
//****************************************************************

Function NMNormalizeStructInit( n )
	STRUCT NMNormalizeStruct &n
	
	n.fxn1 = ""; n.avgWin1 = 0; n.xbgn1 = -inf; n.xend1 = inf; n.minValue = 0;
	n.fxn2 = ""; n.avgWin2 = 0; n.xbgn2 = -inf; n.xend2 = inf; n.maxValue = 1;
	
End // NMNormalizeStructInit

//****************************************************************
//****************************************************************

Function NMNormalizeError( n )
	STRUCT NMNormalizeStruct &n
	
	if ( numtype( n.xbgn1 ) == 2 )
		return NM2Error( 10, "xbgn1", num2str( n.xbgn1 ) )
	endif
	
	if ( numtype( n.xend1 ) == 2 )
		return NM2Error( 10, "xend1", num2str( n.xend1 ) )
	endif
	
	if ( numtype( n.xbgn2 ) == 2 )
		return NM2Error( 10, "xbgn2", num2str( n.xbgn2 ) )
	endif
	
	if ( numtype( n.xend2 ) == 2 )
		return NM2Error( 10, "xend2", num2str( n.xend2 ) )
	endif
	
	strswitch( n.fxn1 )
		case "Min":
		case "Avg":
			break
		case "MinAvg":
			if ( ( numtype( n.avgWin1 ) > 0 ) || ( n.avgWin1 <= 0 ) )
				return NM2Error( 10, "avgWin1", num2str( n.avgWin1 ) )
			endif
			break
		default:
			return NM2Error( 20, "fxn1", n.fxn1 )
	endswitch
	
	strswitch( n.fxn2 )
		case "Max":
		case "Avg":
			break
		case "MaxAvg":
			if ( ( numtype( n.avgWin2 ) > 0 ) || ( n.avgWin2 <= 0 ) )
				return NM2Error( 10, "avgWin2", num2str( n.avgWin2 ) )
			endif
			break
		default:
			return NM2Error( 20, "fxn2", n.fxn2 )
	endswitch
	
	if ( numtype( n.minValue ) > 0 )
		return NM2Error( 10, "minValue", num2str( n.minValue ) )
	endif
	
	if ( numtype( n.maxValue ) > 0 )
		return NM2Error( 10, "maxValue", num2str( n.maxValue ) )
	endif
	
	return 0

End // NMNormalizeError

//****************************************************************
//****************************************************************

Function /S NMNormalize( wList [ folder, xWave, fxn1, avgWin1, xbgn1, xend1, minValue, fxn2, avgWin2, xbgn2, xend2, maxValue, allWavesAvg, n, deprecation ] )
	String wList, folder, xWave // see description at top
	
	String fxn1 // function to compute min value, "avg" or "min" or "minavg"
	Variable avgWin1 // for minavg
	Variable xbgn1, xend1 // x-axis window begin and end for fxn1, use ( -inf, inf ) for all
	Variable minValue // norm min value, default is 0, but could be -1
	String fxn2 // function to compute max value, "avg" or "max" or "maxavg"
	Variable avgWin2 // for maxavg
	Variable xbgn2, xend2 // x-axis window begin and end for fxn2, use ( -inf, inf ) for all
	Variable maxValue // norm max value, default is 1
	Variable allWavesAvg // ( 0 ) no, normalize to each wave's avgs ( 1 ) normalize to avgs of all selected waves
	STRUCT NMNormalizeStruct &n // or pass this structure instead
	
	Variable  deprecation
	
	STRUCT NMParams nm
	STRUCT NMNormalizeStruct n2
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( xWave ) )
		xWave = ""
	endif
	
	if ( NMParamsInit( folder, wList, nm, xWave = xWave ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( n ) )
	
		if ( ParamIsDefault( fxn1 ) )
			fxn1 = "min"
		endif
		
		if ( ParamIsDefault( xbgn1 ) )
			xbgn1 = -inf
		endif
		
		if ( ParamIsDefault( xend1 ) )
			xend1 = inf
		endif
		
		if ( ParamIsDefault( fxn2 ) )
			fxn2 = "max"
		endif
		
		if ( ParamIsDefault( xbgn2 ) )
			xbgn2 = -inf
		endif
		
		if ( ParamIsDefault( xend2 ) )
			xend2 = inf
		endif
		
		if ( ParamIsDefault( maxValue ) )
			maxValue = 1
		endif
		
		n2.fxn1 = fxn1
		n2.avgWin1 = avgWin1
		n2.xbgn1 = xbgn1
		n2.xend1 = xend1
		n2.minValue = minValue
		
		n2.fxn2 = fxn2
		n2.avgWin2 = avgWin2
		n2.xbgn2 = xbgn2
		n2.xend2 = xend2
		n2.minValue = minValue
		
		n2.allWavesAvg = allWavesAvg
	
	else
	
		n2 = n
		
	endif
	
	return NMNormalize2( nm, n2 )
	
End // NMNormalize

//****************************************************************
//****************************************************************

Function /S NMNormalize2( nm, n [ history ] )
	STRUCT NMParams &nm // uses nm.folder, nm.wList, nm.xWave
	STRUCT NMNormalizeStruct &n
	Variable history
	
	Variable wcnt, scaleNum, npnts, numWaves
	Variable amp, amp1, amp2
	String wName, paramList2, xw = ""
	String thisFxn = GetRTStackInfo( 1 )
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	if ( NMNormalizeError( n ) != 0 )
		return "" // error
	endif
	
	NMParamStrAdd( "fxn1", n.fxn1, nm )
	
	if ( StringMatch( n.fxn1, "MinAvg" ) )
		NMParamVarAdd( "win1", n.avgWin1, nm )
	endif
		
	if ( ( numtype( n.xbgn1 ) == 0 ) || ( numtype( n.xend1 ) == 0 ) )
		NMParamVarAdd( "xbgn1", n.xbgn1, nm )
		NMParamVarAdd( "xend1", n.xend1, nm )
	endif
	
	if ( n.minValue != 0 )
		NMParamVarAdd( "minValue", n.minValue, nm )
	endif
	
	NMParamStrAdd( "fxn2", n.fxn2, nm )
	
	if ( StringMatch( n.fxn1, "MaxAvg" ) )
		NMParamVarAdd( "win2", n.avgWin2, nm )
	endif
	
	if ( ( numtype( n.xbgn2 ) == 0 ) || ( numtype( n.xend2 ) == 0 ) )
		NMParamVarAdd( "xbgn2", n.xbgn2, nm )
		NMParamVarAdd( "xend2", n.xend2, nm )
	endif
	
	if ( strlen( nm.xWave ) > 0 )
		NMParamStrAdd( "xwave", nm.xWave, nm )
		xw = nm.folder + nm.xWave
	endif
	
	if ( n.maxValue != 1 )
		NMParamVarAdd( "maxValue", n.maxValue, nm )
	endif
	
	if ( n.allWavesAvg )
	
		for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
		
			wName = StringFromList( wcnt, nm.wList )
			
			amp = zNMNormalizeAmp( 1, nm.folder + wName, xw, n )
			
			if ( numtype( amp ) > 0 )
				return NM2ErrorStr( 90, "encountered bad amp1 value for wave: " + wName, "" )
			endif
			
			amp1 += amp
			
			amp = zNMNormalizeAmp( 2, nm.folder + wName, xw, n )
			
			if ( numtype( amp ) > 0 )
				return NM2ErrorStr( 90, "encountered bad amp2 value for wave: " + wName, "" )
			endif
			
			amp2 += amp
			
		endfor
		
		amp1 /= numWaves
		amp2 /= numWaves
	
	endif
	
	for ( wcnt = 0; wcnt < numWaves; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Normalizing Waves..." ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		if ( !n.allWavesAvg )
		
			amp1 = zNMNormalizeAmp( 1, nm.folder + wName, xw, n )
			
			if ( numtype( amp1 ) > 0 )
				NMHistory( thisFxn + "Error : encountered bad amp1 value for wave: " + wName )
				continue
			endif
			
			amp2 = zNMNormalizeAmp( 2, nm.folder + wName, xw, n )
			
			if ( numtype( amp2 ) > 0 )
				NMHistory( thisFxn + "Error : encountered bad amp2 value for wave: " + wName )
				continue
			endif
		
		endif
		
		scaleNum = ( n.maxValue - n.minValue ) / ( amp2 - amp1 )
		
		if ( ( scaleNum == 0 ) || ( numtype( scaleNum ) > 0 ) )
			NMHistory( thisFxn + "Error : encountered bad scaleNum value for wave: " + wName )
			continue
		else
		
			Wave wtemp = $nm.folder + wName
		
			MatrixOp /O wtemp = scaleNum * ( wtemp - amp1 )
			
			if ( n.minValue != 0 )
				MatrixOp /O wtemp = wtemp + n.minValue
			endif
			
		endif
		
		paramList2 = NMCmdNumOptional( "min", amp1, nm.paramList )
		paramList2 = NMCmdNumOptional( "max", amp2, paramList2 )
		
		NMLoopWaveNote( nm.folder + wName, paramList2 )
		
		nm.successList += wName + ";"
	
	endfor
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.successList )

	return nm.successList
	
End // NMNormalize2

//****************************************************************
//****************************************************************

Static Function zNMNormalizeAmp( select, wName, xWave, n )
	Variable select // 1 or 2
	String wName, xWave
	STRUCT NMNormalizeStruct &n

	Variable avgWin, xbgn, xend, amp = NaN
	String fxn
	
	STRUCT NMWaveStatsStruct s
	NMWaveStatsStructNull( s )
	
	if ( select == 1 )
		fxn = n.fxn1
		avgWin = n.avgWin1
		xbgn = n.xbgn1
		xend = n.xend1
	elseif ( select == 2 )
		fxn = n.fxn2
		avgWin = n.avgWin2
		xbgn = n.xbgn2
		xend = n.xend2
	else
		return NaN
	endif
	
	strswitch( fxn )
	
		case "Avg":
			NMWaveStatsStructInit( s, wName, xWave = xWave, xbgn = xbgn, xend = xend )
			NMWaveStatsXY2( s )
			amp = s.avg
			break
			
		case "Min":
			NMWaveStatsStructInit( s, wName, xWave = xWave, xbgn = xbgn, xend = xend )
			NMWaveStatsXY2( s )
			amp = s.min
			break
			
		case "Max":
			NMWaveStatsStructInit( s, wName, xWave = xWave, xbgn = xbgn, xend = xend )
			NMWaveStatsXY2( s )
			amp = s.max
			break
			
		case "MinAvg":
		
			STRUCT NMMinAvgStruct mn
			NMMinAvgStructInit( mn, avgWin, wName, xWave = xWave, xbgn = xbgn, xend = xend )
			NMMinAvg2( mn )
			amp = mn.avg
			
			break
			
		case "MaxAvg":
		
			STRUCT NMMaxAvgStruct mx
			NMMaxAvgStructInit( mx, avgWin, wName, xWave = xWave, xbgn = xbgn, xend = xend )
			NMMaxAvg2( mx )
			amp = mx.avg
			
			break
			
	endswitch
	
	return amp

End // NMNormalizeAmp

//****************************************************************
//****************************************************************

Function /S NMScale( op, wList [ folder, xWave, factor, waveOfFactors, wavePntByPnt, xbgn, xend, history, deprecation ] )
	String op // operation ( "x" ... "/" ... "+" ... "-" ... "=" )
	String folder, wList, xWave // see description at top
	Variable factor // single scale factor
	String waveOfFactors // name of wave containing a scale factor for each input wave ( e.g. a Stats wave )
	String wavePntByPnt // name of wave for point-by-point scaling
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	Variable history // ( 0 ) no history ( 1 ) print basic results to history ( 2 ) print basic results and wave-by-wave scaling operations
	Variable deprecation
	
	STRUCT NMParams nm
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( NMParamsInit( folder, wList, nm, xWave = xWave ) != 0 )
		return ""
	endif
	
	if ( strsearch( "x*/+-=", op, 0 ) == -1 )
		return NM2ErrorStr( 20, "op", op )
	endif
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( !ParamIsDefault( factor ) )
		return NMScale2( nm, op, factor = factor, xbgn = xbgn, xend = xend, history = history )
	endif
	
	if ( !ParamIsDefault( waveOfFactors ) )
		return NMScale2( nm, op, waveOfFactors = waveOfFactors, xbgn = xbgn, xend = xend, history = history )
	endif
	
	if ( !ParamIsDefault( wavePntByPnt ) )
		return NMScale2( nm, op, wavePntByPnt = wavePntByPnt, xbgn = xbgn, xend = xend, history = history )
	endif
	
End // NMScale

//****************************************************************
//****************************************************************

Function /S NMScale2( nm, op [ factor, waveOfFactors, wavePntByPnt, xbgn, xend, history ] )
	STRUCT NMParams &nm // uses nm.folder, nm.wList, nm.xWave
	String op // operation ( "x" ... "/" ... "+" ... "-" ... "=" )
	Variable factor // single scale factor
	String waveOfFactors // name of wave containing a scale factor for each input wave ( e.g. a Stats wave )
	String wavePntByPnt // name of wave for point-by-point scaling
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	Variable history // ( 0 ) no history ( 1 ) print basic results to history ( 2 ) print basic results and wave-by-wave scaling operations
	
	Variable wcnt, numWaves, toDo, history2
	String wName, nothingList = "", matrixName = NMMainDF + "ScaleMatrix"
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	if ( strsearch( "x*/+-=", op, 0 ) == -1 )
		return NM2ErrorStr( 20, "op", op )
	endif
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( ParamIsDefault( factor ) )
	
		if ( ParamIsDefault( waveOfFactors ) )
		
			if ( !ParamIsDefault( wavePntByPnt ) )
			
				wavePntByPnt = CheckNMWavePath( nm.folder, wavePntByPnt )
	
				if ( NMUtilityWaveTest( wavePntByPnt ) != 0 )
					return NM2ErrorStr( 1, "wavePntByPnt", "" )
				endif
			
				toDo = 3
				NMParamStrAdd( "op", op + NMChild( wavePntByPnt ) , nm )
				
			endif
		
		else
		
			waveOfFactors = CheckNMWavePath( nm.folder, waveOfFactors )
		
			if ( NMUtilityWaveTest( waveOfFactors ) != 0 )
				return NM2ErrorStr( 1, "waveOfFactors", "" )
			endif
		
			if ( numpnts( $waveOfFactors ) != numWaves )
				return NM2ErrorStr( 5, "waveOfFactors", "" )
			endif
			
			Wave wtemp = $waveOfFactors
			
			toDo = 2
			NMParamStrAdd( "op", op + NMChild( waveOfFactors ) , nm )
			
		endif
	
	else
	
		toDo = 1
		NMParamStrAdd( "op", op + num2str( factor ), nm )
		
	endif
	
	if ( toDo == 0 )
		return "" // nothing to do
	endif
	
	if ( ( numtype( xbgn ) == 0 ) || ( numtype( xend ) == 0 ) )
		NMParamVarAdd( "xbgn", xbgn, nm )
		NMParamVarAdd( "xend", xend, nm )
	endif
	
	if ( strlen( nm.xWave ) > 0 )
		NMParamStrAdd( "xwave", nm.xWave, nm )
	endif
	
	NMMatrixArithmeticMake( matrixName, numWaves )
	
	if ( DimSize( $matrixName, 0 ) != numWaves )
		return "" // error
	endif
	
	Wave /T matrix = $matrixName
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		wName = nm.folder + StringFromList( wcnt, nm.wList )
	
		matrix[ wcnt ][ %wName ] = wName
		matrix[ wcnt ][ %op ] = op
		
		switch( toDo )
			
			case 1:
				matrix[ wcnt ][ %factor ] = num2str( factor )
				break
				
			case 2:
				if ( numtype( wtemp[ wcnt ] ) == 0 )
					matrix[ wcnt ][ %factor ] = num2str( wtemp[ wcnt ] )
				endif
				break
				
			case 3:
			
				if ( numpnts( $wName ) != numpnts( $wavePntByPnt ) )
					return NM2ErrorStr( 5, "wavePntByPnt", "" )
				endif
				
				matrix[ wcnt ][ %factor ] = wavePntByPnt
				
				break
		
		endswitch
	
	endfor
	
	if ( history == 2 )
		history2 = 1
	endif
	
	nm.successList = NMMatrixArithmetic( matrixName, xbgn = xbgn, xend = xend, xWave = nm.xWave, history = history2 )
	
	nm.successList = NMChild( nm.successList )
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.successList )
	
	KillWaves /Z $matrixName
	
	return nm.successList
	
End // NMScale2

//****************************************************************
//****************************************************************

Function /S NMRescale2( nm, oldUnits, newUnits, scale [ history ] )
	STRUCT NMParams &nm // uses nm.folder, nm.wList
	String oldUnits
	String newUnits
	Variable scale
	Variable history
	
	Variable wcnt, numWaves, scaleNum = scale
	String wName, fxn = "NMRescale"
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	if ( strlen( oldUnits ) == 0 )
		return NM2ErrorStr( 21, "oldUnits", "" )
	endif
	
	if ( strlen( newUnits ) == 0 )
		return NM2ErrorStr( 21, "newUnits", "" )
	endif
	
	if ( numtype( scale ) > 0 )
		return NM2ErrorStr( 10, "scale", num2str( scale ) )
	endif
	
	if ( StringMatch( oldUnits, newUnits ) || ( scale == 1 ) )
		return "" // nothing to do
	endif
	
	NMParamVarAdd( "scale", scale, nm )
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Scaling Waves..." ) == 1 )
			break // cancel wave loop
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		//if ( !StringMatch( oldUnits, NMWaveUnits( "y", nm.folder + wName ) ) )
		//	continue // wrong units
		//endif
		
		Wave waveTemp = $nm.folder + wName
		
		MatrixOp /O waveTemp = waveTemp * scaleNum
		
		NMNoteStrReplace( nm.folder + wName, "yLabel", newUnits )
		NMLoopWaveNote( nm.folder + wName, nm.paramList )
		
		nm.successList += wName + ";"
		
	endfor
	
	//nm.fxn = fxn + " " + oldUnits + "-->" + newUnits
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.successList )
	
	return nm.successList
	
End // NMRescale2

//****************************************************************
//****************************************************************

Function NMSmoothError( algorithm, num )
	String algorithm // "binomial", "boxcar" or "polynomial" ( see Igor Smooth )
	Variable num // see Igor Smooth
	
	strswitch( algorithm )
		case "binomial":
		case "boxcar":
		case "polynomial":
			break
		default:
			return NM2Error( 20, "algorithm", algorithm )
	endswitch
	
	if ( ( numtype( num ) > 0 ) || ( num < 1 ) )
		return NM2Error( 10, "num", num2str( num ) )
	endif
	
	if ( StringMatch( algorithm, "binomial" ) && ( ( num < 1 ) || ( num > 32767 ) ) )
		return NM2Error( 90, "number of points must be from 1 to 32767", "" )
	endif
	
	if ( StringMatch( algorithm, "boxcar" ) && ( ( num < 1 ) || ( num > 32767 ) ) )
		return NM2Error( 90, "number of points must be from 1 to 32767", "" )
	endif
	
	if ( StringMatch( algorithm, "polynomial" ) )
	
		if ( ( num < 5 ) || ( num > 25 ) )
			return NM2Error( 90, "for polynomial smoothing, the number of points must be greater than 5 and less than 25", "" )
		endif
		
		if ( mod( num, 2 ) == 0 )
			return NM2Error( 90, "for polynomial smoothing, the number of points must be odd", "" )
		endif
		
	endif
	
	return 0
	
End // NMSmoothError

//****************************************************************
//****************************************************************

Function /S NMSmooth( num, wList [ folder, algorithm, deprecation ] ) // see NMSmooth2
	String folder, wList // see description at top
	String algorithm // "binomial" or "boxcar" or "polynomial"
	Variable num
	Variable deprecation
	
	STRUCT NMParams nm
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( NMParamsInit( folder, wList, nm ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( algorithm ) || ( strlen( algorithm ) == 0 ) )
		algorithm = "binomial"
	endif
	
	return NMSmooth2( nm, num, algorithm = algorithm )

End // NMSmooth

//****************************************************************
//****************************************************************

Function /S NMSmooth2( nm, num [ algorithm, history ] ) // see Igor Smooth
	STRUCT NMParams &nm // uses nm.folder, nm.wList
	Variable num
	String algorithm // "binomial" or "boxcar" or "polynomial"
	Variable history
	
	Variable wcnt, numWaves
	String wName
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	if ( ParamIsDefault( algorithm ) || ( strlen( algorithm ) == 0 ) )
		algorithm = "binomial"
	endif
	
	if ( NMSmoothError( algorithm, num ) != 0 )
		return "" // error
	endif
	
	NMParamStrAdd( "alg", algorithm, nm )
	
	strswitch( algorithm )
		case "binomial":
			NMParamVarAdd( "n", num, nm, integer = 1 )
			break
		case "boxcar":
		case "polynomial":
			NMParamVarAdd( "pnts", num, nm, integer = 1 )
			break
		default:
			return NM2ErrorStr( 20, "algorithm", algorithm )
	endswitch
	
	for ( wcnt = 0; wcnt < numWaves; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Smoothing Waves..." ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		Wave wtemp = $nm.folder + wName
		
		strswitch( algorithm )
			case "binomial":
				Smooth num, wtemp
				break
			case "boxcar": // sliding average
				Smooth /B num, wtemp
				break
			case "polynomial": // Savitzky-Golay
				Smooth /S=2 num, wtemp
				break
			default:
				continue
		endswitch
		
		NMLoopWaveNote( nm.folder + wName, nm.paramList )
		
		nm.successList += wName + ";"
	
	endfor
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.successList )

	return nm.successList

End // NMSmooth2

//****************************************************************
//****************************************************************

Function NMFilterFIRError( algorithm, f1, f2, n, fc, fw )
	String algorithm // "low-pass" or "high-pass" or "notch"
	Variable f1, f2, n // for low-pass or high-pass, see FilterFIR
	Variable fc, fw // for notch, see FilterFIR

	strswitch( algorithm )
		case "low-pass":
		case "high-pass":
		case "notch":
			break
		default:
			if ( ( numtype( fc * fw ) == 0 ) && ( fc > 0 ) && ( fw > 0 ) )
				algorithm = "notch"
			else
				return NM2Error( 20, "algorithm", algorithm )
			endif
	endswitch
	
	if ( StringMatch( algorithm, "notch" ) )
	
		if ( ( numtype( fc ) > 0 ) || ( fc <= 0 ) || ( fc > 0.5 ) )
			return NM2Error( 90, "fc is out of range: " + num2str( fc ), "" )
		endif
	
		if ( ( numtype( fw ) > 0 ) || ( fw <= 0 ) || ( fw > 0.5 ) )
			return NM2Error( 90, "fw is out of range: " + num2str( fw ), "" )
		endif
		
		return 0
	
	endif
	
	// must be low or high pass
	
	if ( ( numtype( f1 ) > 0 ) || ( f1 <= 0 ) || ( f1 > 0.5 ) )
		return NM2Error( 90, "f1 is out of range: " + num2str( f1 ), "" )
	endif
	
	if ( ( numtype( f2 ) > 0 ) || ( f2 <= 0 ) || ( f2 > 0.5 ) )
		return NM2Error( 90, "f2 is out of range: " + num2str( f2 ), "" )
	endif
	
	if ( f1 >= f2 )
		return NM2Error( 90, "filter f1 > f2", "" )
	endif
	
	if ( ( numtype( n ) > 0 ) || ( n <= 0 ) )
		return NM2Error( 10, "n", num2str( n ) )
	endif
	
	return 0

End // NMFilterFIRError

//****************************************************************
//****************************************************************

Function /S NMFilterFIR( wList [ folder, algorithm, f1, f2, n, fc, fw, deprecation ] ) // see NMFilterFIR2
	String wList, folder // see description at top
	String algorithm // "low-pass" or "high-pass" or "notch"
	Variable f1, f2, n // for low-pass or high-pass
	Variable fc, fw // for notch
	Variable deprecation
	
	STRUCT NMParams nm
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( NMParamsInit( folder, wList, nm ) != 0 )
		return ""
	endif

	if ( ParamIsDefault( algorithm ) )
		algorithm = ""
	endif
	
	return NMFilterFIR2( nm, algorithm = algorithm, f1 = f1, f2 = f2, n = n, fc = fc, fw = fw )
	
End // NMFilterFIR

//****************************************************************
//****************************************************************

Function /S NMFilterFIR2( nm [ algorithm, f1, f2, n, fc, fw, history ] ) // see Igor FilterFIR
	STRUCT NMParams &nm // uses nm.folder, nm.wList
	String algorithm // "low-pass" or "high-pass" or "notch"
	Variable f1, f2, n // for low-pass or high-pass
	Variable fc, fw // for notch
	Variable history
	
	Variable wcnt, numWaves
	String wName
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	if ( strlen( nm.xWave ) > 0 )
		return NMXWaveFunctionError()
	endif
	
	numWaves = ItemsInList( nm.wList )

	if ( ParamIsDefault( algorithm ) )
		algorithm = ""
	endif
	
	if ( ( numtype( fc * fw ) == 0 ) && ( fc > 0 ) && ( fw > 0 ) )
		algorithm = "notch"
	endif
	
	if ( NMFilterFIRError( algorithm, f1, f2, n, fc, fw ) != 0 )
		return "" // error
	endif
	
	if ( StringMatch( algorithm, "low-pass" ) )
		NMParamStrAdd( "alg", "LP", nm )
		NMParamVarAdd( "f1", f1, nm )
		NMParamVarAdd( "f2", f2, nm )
		NMParamVarAdd( "n", n, nm )
	elseif ( StringMatch( algorithm, "high-pass" ) )
		NMParamStrAdd( "alg", "HP", nm )
		NMParamVarAdd( "f1", f1, nm )
		NMParamVarAdd( "f2", f2, nm )
		NMParamVarAdd( "n", n, nm )
	elseif ( StringMatch( algorithm, "notch" ) )
		NMParamStrAdd( "alg", algorithm, nm )
		NMParamVarAdd( "fc", fc, nm )
		NMParamVarAdd( "fw", fw, nm )
	else
		return ""
	endif
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "FIR Filtering Waves..." ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		Wave wtemp = $nm.folder + wName
		
		strswitch( algorithm )
			case "low-pass":
				FilterFIR /LO={ f1, f2, n } wtemp
				break
			case "high-pass":
				FilterFIR /HI={ f1, f2, n } wtemp
				break
			case "notch":
				FilterFIR /NMF={ fc, fw } wtemp
				break
			default:
				continue
		endswitch
		
		NMLoopWaveNote( nm.folder + wName, nm.paramList )
		
		nm.successList += wName + ";"
	
	endfor
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.successList )

	return nm.successList
	
End // NMFilterFIR2

//****************************************************************
//****************************************************************

Function NMFilterIIRError( fLow, fHigh, fNotch, notchQ )
	Variable fLow, fHigh, fNotch, notchQ
	
	if ( ( numtype( fLow ) == 0 ) && ( fLow > 0 ) && ( fLow <= 0.5 ) )
		return 0 // OK
	endif
	
	if ( ( numtype( fHigh ) == 0 ) && ( fHigh > 0 ) && ( fHigh <= 0.5 ) )
		return 0 // OK
	endif
	
	if ( ( numtype( fNotch ) == 0 ) && ( fNotch > 0 ) && ( fNotch <= 0.5 ) )
	
		if ( ( numtype( notchQ ) > 0 ) || ( notchQ <= 1 ) )
			return NM2Error( 10, "notchQ", num2str( notchQ ) )
		endif
		
	endif
	
	return -1 // nothing to do
	
End // NMFilterIIRError

//****************************************************************
//****************************************************************

Function /S NMFilterIIR( wList [ folder, fLow, fHigh, fNotch, notchQ, deprecation ] ) // see NMFilterIIR2
	String wList, folder // see description at top
	Variable fLow // -3dB corner for low-pass filter
	Variable fHigh // -3dB corner for high-pass filter
	Variable fNotch, notchQ // center frequency at fNotch, and -3dB width of fNotch
	Variable deprecation
	
	STRUCT NMParams nm
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( NMParamsInit( folder, wList, nm ) != 0 )
		return ""
	endif

	return NMFilterIIR2( nm, fLow = fLow, fHigh = fHigh, fNotch = fNotch, notchQ = notchQ )
	
End // NMFilterIIR

//****************************************************************
//****************************************************************

Function /S NMFilterIIR2( nm [ fLow, fHigh, fNotch, notchQ, history ] ) // see Igor FilterIIR
	STRUCT NMParams &nm // uses nm.folder, nm.wList
	Variable fLow // -3dB corner for low-pass filter
	Variable fHigh // -3dB corner for high-pass filter
	Variable fNotch, notchQ // center frequency at fNotch, and -3dB width of fNotch
	Variable history
	
	Variable wcnt, numWaves
	String algorithm, wName
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	if ( strlen( nm.xWave ) > 0 )
		return NMXWaveFunctionError()
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	if ( NMFilterIIRError( fLow, fHigh, fNotch, notchQ ) != 0 )
		return "" // error
	endif
	
	if ( ( numtype( fLow ) == 0 ) && ( fLow > 0 ) && ( fLow <= 0.5 ) )
		algorithm = "low-pass"
		NMParamVarAdd( "fLow", fLow, nm )
	elseif ( ( numtype( fHigh ) == 0 ) && ( fHigh > 0 ) && ( fHigh <= 0.5 ) )
		algorithm = "high-pass"
		NMParamVarAdd( "fHigh", fHigh, nm )
	elseif ( ( numtype( fNotch * notchQ ) == 0 ) && ( fNotch > 0 ) && ( fNotch <= 0.5 ) && ( notchQ > 1 ) )
		algorithm = "notch"
		NMParamVarAdd( "fNotch", fNotch, nm )
		NMParamVarAdd( "notchQ", notchQ, nm )
	else
		return ""
	endif
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "IIR Filtering Waves..." ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		Wave wtemp = $nm.folder + wName
		
		strswitch( algorithm )
			case "low-pass":
				FilterIIR /LO=( fLow ) wtemp
				break
			case "high-pass":
				FilterIIR /HI=( fHigh ) wtemp
				break
			case "notch":
				FilterIIR /N={ fNotch, notchQ } wtemp
				break
			default:
				continue
		endswitch
		
		NMLoopWaveNote( nm.folder + wName, nm.paramList )
		
		nm.successList += wName + ";"
	
	endfor
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.successList )

	return nm.successList
	
End // NMFilterIIR2


//****************************************************************
//****************************************************************
//
//	"Software-based correction of single compartment series resistance errors"
//	Stephen F. Traynelis
//	J Neurosci Methods. 1998 Dec 31;86(1):25-34.
//
//****************************************************************
//****************************************************************
//
// computer algorithm that corrects capacitative filtering that results from pipette
// series resistance as well as the voltage error for current responses with linear 
//	current–voltage curve
//
//****************************************************************
//****************************************************************

Structure NMRsCorr

	Variable Vhold // mV
	Variable Vrev // mV
	Variable Rs // MOhms
	Variable Cm // pF
	Variable Vcomp // fraction 0 - 1
	Variable Ccomp // fraction 0 - 1
	Variable Fc // kHz
	
	String dataUnits // A, mA, uA, nA, pA

EndStructure

//****************************************************************
//****************************************************************

Function NMRsCorrError( Vhold, Vrev, Rs, Cm, Vcomp, Ccomp, Fc, dataUnits )
	Variable Vhold, Vrev, Rs, Cm, Vcomp, Ccomp, Fc
	String dataUnits
	
	if ( numtype( Vhold ) > 0 )
		return NM2Error( 10, "Vhold", num2str( Vhold ) )
	endif
	
	if ( numtype( Vrev ) > 0 )
		return NM2Error( 10, "Vrev", num2str( Vrev ) )
	endif
	
	if ( ( numtype( Rs ) > 0 ) || ( Rs <= 0 ) )
		return NM2Error( 10, "Rs", num2str( Rs ) )
	endif
	
	if ( ( numtype( Cm ) > 0 ) || ( Cm <= 0 ) )
		return NM2Error( 10, "Cm", num2str( Cm ) )
	endif
	
	if ( ( numtype( Vcomp ) > 0 ) || ( Vcomp < 0 ) || ( Vcomp > 1 ) )
		return NM2Error( 10, "Vcomp", num2str( Vcomp ) )
	endif
	
	if ( ( numtype( Ccomp ) > 0 ) || ( Ccomp < 0 ) || ( Ccomp > 1 ) )
		return NM2Error( 10, "Ccomp", num2str( Ccomp ) )
	endif
	
	if ( ( numtype( Fc ) > 0 ) || ( Fc <= 0 ) )
		return NM2Error( 10, "Fc", num2str( Fc ) )
	endif
	
	strswitch( dataUnits )
		case "A":
		case "mA":
		case "uA":
		case "nA":
		case "pA":
			break
		default:
			return NM2Error( 20, "dataUnits", dataUnits )
	endswitch
	
	return 0

End // NMRsCorrError

//****************************************************************
//****************************************************************

Function /S NMRsCorrection2( nm, rc [ history ] )
	STRUCT NMParams &nm // uses nm.folder, nm.wList
	STRUCT NMRsCorr &rc
	
	Variable history
	
	Variable icnt, wcnt, numWaves, iAmps, dt
	Variable icap, vThisPnt, vLastPnt, vCorrect
	Variable vhold, vrev, Rs, Cm, Fc, dataSCale
	String wName, dataUnits
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	if ( NMRsCorrError( rc.Vhold, rc.Vrev, rc.Rs, rc.Cm, rc.Vcomp, rc.Ccomp, rc.Fc, rc.dataUnits ) != 0 )
		return ""
	endif
	
	NMParamVarAdd( "Vhold", rc.Vhold, nm )
	NMParamVarAdd( "Vrev", rc.Vrev, nm )
	NMParamVarAdd( "Rs", rc.Rs, nm )
	NMParamVarAdd( "Cm", rc.Cm, nm )
	NMParamVarAdd( "Vcomp", rc.Vcomp, nm )
	NMParamVarAdd( "Ccomp", rc.Ccomp, nm )
	NMParamVarAdd( "Fc", rc.Fc, nm )
	NMParamStrAdd( "dataUnits", rc.dataUnits, nm )
	
	vhold = rc.Vhold * 1e-3 // volts
	vrev = rc.Vrev * 1e-3 // volts
	Rs = rc.Rs * 1e6 // Ohms
	Cm = rc.Cm * 1e-12 // F
	Fc = rc.Fc * 1e3 // Hz
	
	// Fc = 1 / ( 2 * pi * tlag )
	
	strswitch( dataUnits )
		case "A":
			dataSCale = 1
			break
		case "mA":
			dataSCale = 1e-3
			break
		case "uA":
			dataSCale = 1e-6
			break
		case "nA":
			dataSCale = 1e-9
			break
		case "pA":
			dataSCale = 1e-12
			break
		default:
			return ""
	endswitch
	
	numWaves = ItemsInList( nm.wList )
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Computing Rs correction..." ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		Wave wtemp = $nm.folder + wName
		
		dt = deltax( wtemp ) // ms
		dt *= 1e-3 // seconds
		
		wtemp *= dataSCale // A
		
		iAmps = wtemp[ 0 ]
		
		vLastPnt = vhold - iAmps * Rs
		
		if ( vLastPnt == vrev )
			vCorrect = 0 // divide by 0
		else
			vCorrect = rc.Vcomp * ( 1 - ( vhold - vrev ) / ( vLastPnt - vrev ) )
		endif
		
		wtemp[ 0 ] = iAmps - iAmps * vCorrect
		
		for ( icnt = 1 ; icnt < numpnts( wtemp ) ; icnt += 1 )
		
			iAmps = wtemp[ icnt ]
			
			vThisPnt = vhold - iAmps * Rs
			
			if ( vThisPnt == vrev )
				vCorrect = 0 // divide by 0
			else
				vCorrect = rc.Vcomp * ( 1 - ( vhold - vrev ) / ( vThisPnt - vrev ) )	
			endif
		
			//wtemp[ icnt ] = iAmps - iAmps * vCorrect // not in Traynelis code
			
			icap = Cm * ( vThisPnt - vLastPnt ) / dt
			icap = icap * ( 1 - exp( -2 * pi * dt * Fc ) ) // if tlag = dt, this equals 0.632121
			
			wtemp[ icnt - 1 ] = wtemp[ icnt - 1 ] - rc.Ccomp * icap
			wtemp[ icnt - 1 ] = wtemp[ icnt - 1 ] - wtemp[ icnt - 1 ] * vCorrect
			
			vLastPnt = vThisPnt
		
		endfor
		
		wtemp /= dataSCale
		
		NMLoopWaveNote( nm.folder + wName, nm.paramList )
		
		nm.successList += wName + ";"
		
	endfor

	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif

	return nm.successList

End // NMRsCorrection2

//****************************************************************
//****************************************************************

Structure NMBinomialNoise

	Variable n, p

EndStructure

//****************************************************************
//****************************************************************

Structure NMExpNoise

	Variable avg // and stdv

EndStructure

//****************************************************************
//****************************************************************

Structure NMGammaNoise

	Variable a, b

EndStructure

//****************************************************************
//****************************************************************

Structure NMGaussNoise // gnoise

	Variable stdv

EndStructure

//****************************************************************
//****************************************************************

Structure NMLogNormalNoise

	Variable m, s

EndStructure

//****************************************************************
//****************************************************************

Structure NMLorentzianNoise

	Variable a, b

EndStructure

//****************************************************************
//****************************************************************

Structure NMPoissonNoise

	Variable avg // and variance

EndStructure

//****************************************************************
//****************************************************************

Structure NMUniformNoise // enoise

	Variable minmax // from -minmax to +minmax

EndStructure

//****************************************************************
//****************************************************************

Function /S NMAddNoise( wList [ folder, nbin, nexp, ngamma, ngauss, nlog, nlor, npois, nuni ] ) // see NMAddNoise2
	String wList, folder // see description at top
	
	STRUCT NMBinomialNoise &nbin
	STRUCT NMExpNoise &nexp
	STRUCT NMGammaNoise &ngamma
	STRUCT NMGaussNoise &ngauss
	STRUCT NMLogNormalNoise &nlog
	STRUCT NMLorentzianNoise &nlor
	STRUCT NMPoissonNoise &npois
	STRUCT NMUniformNoise &nuni
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( NMParamsInit( folder, wList, nm ) != 0 )
		return ""
	endif
	
	if ( !ParamIsDefault( nbin ) )
		return NMAddNoise2( nm, nbin = nbin )
	endif
	
	if ( !ParamIsDefault( nexp ) )
		return NMAddNoise2( nm, nexp = nexp )
	endif
	
	if ( !ParamIsDefault( ngamma ) )
		return NMAddNoise2( nm, ngamma = ngamma )
	endif
	
	if ( !ParamIsDefault( ngauss ) )
		return NMAddNoise2( nm, ngauss = ngauss )
	endif
	
	if ( !ParamIsDefault( nlog ) )
		return NMAddNoise2( nm, nlog = nlog )
	endif
	
	if ( !ParamIsDefault( nlor ) )
		return NMAddNoise2( nm, nlor = nlor )
	endif
	
	if ( !ParamIsDefault( npois ) )
		return NMAddNoise2( nm, npois = npois )
	endif
	
	if ( !ParamIsDefault( nuni ) )
		return NMAddNoise2( nm, nuni = nuni )
	endif
	
End // NMAddNoise

//****************************************************************
//****************************************************************

Function /S NMAddNoise2( nm [ nbin, nexp, ngamma, ngauss, nlog, nlor, npois, nuni, history ] )
	STRUCT NMParams &nm // uses nm.folder, nm.wList
	STRUCT NMBinomialNoise &nbin
	STRUCT NMExpNoise &nexp
	STRUCT NMGammaNoise &ngamma
	STRUCT NMGaussNoise &ngauss
	STRUCT NMLogNormalNoise &nlog
	STRUCT NMLorentzianNoise &nlor
	STRUCT NMPoissonNoise &npois
	STRUCT NMUniformNoise &nuni
	
	Variable history
	
	Variable wcnt, numWaves
	Variable addBinomial, addExp, addGamma, addGauss, addLog
	Variable addLorentzian, addPoisson, addUniform
	String algorithm, wName
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	if ( !ParamIsDefault( nbin ) )
	
		addBinomial = 1
		
		if ( ( numtype( nbin.n ) != 0 )  || ( nbin.n < 0 ) )
			return NM2ErrorStr( 10, "nbin.n", num2str( nbin.n ) )
		endif
		
		if ( ( numtype( nbin.p ) != 0 ) || ( nbin.p < 0 ) || ( nbin.p > 1 ) )
			return NM2ErrorStr( 10, "nbin.p", num2str( nbin.p ) )
		endif
		
		NMParamStrAdd( "type", "binomial", nm )
		NMParamVarAdd( "n", nbin.n, nm )
		NMParamVarAdd( "p", nbin.p, nm )
		
	endif
	
	if ( !ParamIsDefault( nexp ) )
	
		addExp = 1
		
		if ( numtype( nexp.avg ) != 0 )
			return NM2ErrorStr( 10, "nexp.avg", num2str( nexp.avg ) )
		endif
		
		NMParamStrAdd( "type", "exp", nm )
		NMParamVarAdd( "avg", nexp.avg, nm )
		
	endif
	
	if ( !ParamIsDefault( ngamma ) )
	
		addGamma = 1
		
		if ( ( numtype( ngamma.a ) != 0 )  || ( ngamma.a < 0 ) )
			return NM2ErrorStr( 10, "ngamma.a", num2str( ngamma.a ) )
		endif
		
		if ( numtype( ngamma.b ) != 0 )
			return NM2ErrorStr( 10, "ngamma.b", num2str( ngamma.b ) )
		endif
		
		NMParamStrAdd( "type", "gamma", nm )
		NMParamVarAdd( "a", ngamma.a, nm )
		NMParamVarAdd( "b", ngamma.b, nm )
		
	endif
	
	if ( !ParamIsDefault( ngauss ) )
	
		addGauss = 1
		
		if ( numtype( ngauss.stdv ) != 0 )
			return NM2ErrorStr( 10, "ngauss.stdv", num2str( ngauss.stdv ) )
		endif
		
		NMParamStrAdd( "type", "gauss", nm )
		NMParamVarAdd( "stdv", ngauss.stdv, nm )
		
	endif
	
	if ( !ParamIsDefault( nlog ) )
	
		addLog = 1
		
		if ( numtype( nlog.m ) != 0 )
			return NM2ErrorStr( 10, "nlog.m", num2str( nlog.m ) )
		endif
		
		if ( numtype( nlog.s ) != 0 )
			return NM2ErrorStr( 10, "nlog.s", num2str( nlog.s ) )
		endif
		
		NMParamStrAdd( "type", "log", nm )
		NMParamVarAdd( "m", nlog.m, nm )
		NMParamVarAdd( "s", nlog.s, nm )
		
	endif
	
	if ( !ParamIsDefault( nlor ) )
	
		addLorentzian = 1
		
		if ( numtype( nlor.a ) != 0 )
			return NM2ErrorStr( 10, "nlor.a", num2str( nlor.a ) )
		endif
		
		if ( numtype( nlor.b ) != 0 )
			return NM2ErrorStr( 10, "nlor.b", num2str( nlor.b ) )
		endif
		
		NMParamStrAdd( "type", "lorentzian", nm )
		NMParamVarAdd( "a", nlor.a, nm )
		NMParamVarAdd( "b", nlor.b, nm )
		
	endif
	
	if ( !ParamIsDefault( npois ) )
	
		addPoisson = 1
		
		if ( numtype( npois.avg ) != 0 )
			return NM2ErrorStr( 10, "npois.avg", num2str( npois.avg ) )
		endif
		
		NMParamStrAdd( "type", "poisson", nm )
		NMParamVarAdd( "avg", npois.avg, nm )
		
	endif
	
	if ( !ParamIsDefault( nuni ) )
	
		addUniform = 1
		
		if ( numtype( nuni.minmax ) != 0 )
			return NM2ErrorStr( 10, "nuni.minmax", num2str( nuni.minmax ) )
		endif
		
		NMParamStrAdd( "type", "uniform", nm )
		NMParamVarAdd( "minmax", nuni.minmax, nm )
		
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Adding Noise..." ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		Wave wtemp = $nm.folder + wName
		
		if ( addBinomial )
			wtemp += binomialNoise( nbin.n, nbin.p )
		endif
		
		if ( addExp )
			wtemp += expNoise( nexp.avg )
		endif
		
		if ( addGamma )
			wtemp += gammaNoise( ngamma.a, ngamma.b )
		endif
		
		if ( addGauss )
			wtemp += gnoise( ngauss.stdv )
		endif
		
		if ( addLog )
			wtemp += logNormalNoise( nlog.m, nlog.s )
		endif
		
		if ( addLorentzian )
			wtemp += lorentzianNoise( nlor.a, nlor.b )
		endif
		
		if ( addPoisson )
			wtemp += poissonNoise( npois.avg )
		endif
		
		if ( addUniform )
			wtemp += enoise( nuni.minmax )
		endif
		
		NMLoopWaveNote( nm.folder + wName, nm.paramList )
		
		nm.successList += wName + ";"
	
	endfor
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.successList )

	return nm.successList
	
End // NMAddNoise2

//****************************************************************
//****************************************************************

Function /S NMReverse( wList [ folder, deprecation ] )
	String wList, folder // see description at top
	Variable deprecation
	
	STRUCT NMParams nm
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( NMParamsInit( folder, wList, nm ) != 0 )
		return ""
	endif
	
	return NMReverse2( nm )
	
End // NMReverse

//****************************************************************
//****************************************************************

Function /S NMReverse2( nm [ history ] ) // see Igor WaveTransform flip
	STRUCT NMParams &nm // uses nm.folder, nm.wList
	Variable history
	
	Variable wcnt, numWaves
	String wName
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	numWaves = ItemsInList( nm.wList )
		
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Reversing Waves..." ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		WaveTransform /O flip $nm.folder + wName
		
		NMLoopWaveNote( nm.folder + wName, "" )
		
		nm.successList += wName + ";"
		
	endfor
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif

	return nm.successList
	
End // NMReverse2

//****************************************************************
//****************************************************************

Function /S NMRotate2( nm, points [ history ] ) // see Igor Rotate
	STRUCT NMParams &nm // uses nm.folder, nm.wList
	Variable points // number of points to rotate
	Variable history
	
	Variable wcnt, numWaves
	String wName
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	if ( numtype( points ) > 0 )
		return NM2ErrorStr( 10, "points", "" )
	endif
	
	NMParamVarAdd( "pnts", points, nm, integer = 1 )
		
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Rotating Waves..." ) == 1 )
			break // cancel
		endif
		
		wName = StringFromList( wcnt, nm.wList )
		
		if ( points != 0 )
			Rotate points, $nm.folder + wName
		endif
			
		NMLoopWaveNote( nm.folder + wName, nm.paramList )
		
		nm.successList += wName + ";"
		
	endfor
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif

	return nm.successList
	
End // NMRotate2

//****************************************************************
//****************************************************************

Function /S NMSort( sortKeyWave, wList [ folder, deprecation ] )
	String sortKeyWave
	String wList, folder // see description at top
	Variable deprecation
	
	STRUCT NMParams nm
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( NMParamsInit( folder, wList, nm ) != 0 )
		return ""
	endif
	
	return NMSort2( nm, sortKeyWave )
	
End // NMSort

//****************************************************************
//****************************************************************

Function /S NMSort2( nm, sortKeyWave [ history ] ) // see Igor Sort
	STRUCT NMParams &nm // uses nm.folder, nm.wList
	String sortKeyWave // wave name of single-sort key
	Variable history
	
	Variable wcnt, numWaves, npnts
	String wName, badList = ""
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	if ( NMUtilityWaveTest( sortKeyWave ) != 0 )
		return NM2ErrorStr( 1, "sortKeyWave", sortKeyWave )
	endif
	
	npnts = GetXstats( "numPnts" , nm.wList, folder = nm.folder )
	
	if ( numpnts( $sortKeyWave ) != npnts )
		return NM2ErrorStr( 5, "sortKeyWave", sortKeyWave )
	endif
	
	NMParamStrAdd( "sortKeyWave", sortKeyWave, nm )
		
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Sorting Waves via key " + NMChild( sortKeyWave ) ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
	
		Sort $sortKeyWave, $nm.folder + wName
		
		NMLoopWaveNote( nm.folder + wName, nm.paramList )
		
		nm.successList += wName + ";"
		
	endfor
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif

	return nm.successList
	
End // NMSort2

//****************************************************************
//****************************************************************

Function /S SortWaveListByCreation( wList [ folder ] ) // Sort a list of waves by their creation date
	String wList, folder // see description at top
	
	Variable wcnt, numWaves, creation, minCreation = inf
	String wName
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( NMParamsInit( folder, wList, nm ) != 0 )
		return ""
	endif
	
	SetNMstr( NMDF + "OutputWaveList", "" )
	
	numWaves = ItemsInList( nm.wList )
	
	Make /T/O/N=( numWaves ) U_SortWavesNames = ""
	Make /D/O/N=( numWaves ) U_SortWavesDate = inf
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		wName = StringFromList( wcnt, nm.wList )
		
		U_SortWavesNames[ wcnt ] = wName
		
		creation = CreationDate( $nm.folder + wName )
		U_SortWavesDate[ wcnt ] = creation
		
		if ( creation < minCreation )
			minCreation = creation
		endif
		
		nm.successList += wName + ";"
		
	endfor
	
	NMParamsComputeFailures( nm )
	
	U_SortWavesDate -= minCreation
	
	Sort U_SortWavesDate, U_SortWavesDate, U_SortWavesNames
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
		nm.newList = AddListItem( U_SortWavesNames[ wcnt ], nm.newList, ";", inf )
	endfor
	
	KillWaves /Z U_SortWavesDate, U_SortWavesNames
	
	SetNMstr( NMDF + "OutputWaveList", nm.newList )

	return nm.newList

End // SortWaveListByCreation

//****************************************************************
//****************************************************************

Function /S NMIntegrate( wList [ folder, xWave, method, deprecation ] ) // see NMIntegrate2
	String wList, folder, xWave // see description at top
	Variable method // see /Meth of Igor Integrate ( 0 ) Rectangular, default ( 1 ) Trapezoid
	// best to use trapezoid if using x-wave
	Variable deprecation
	
	STRUCT NMParams nm
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( NMParamsInit( folder, wList, nm, xWave = xWave ) != 0 )
		return ""
	endif
	
	return NMIntegrate2( nm, method = method )

End // NMIntegrate

//****************************************************************
//****************************************************************

Function /S NMIntegrate2( nm [ method, history ] ) // see Igor Integrate
	STRUCT NMParams &nm // uses nm.folder, nm.wList, nm.xWave
	Variable method // see /Meth of Igor Integrate ( 0 ) Rectangular, default ( 1 ) Trapezoid
	// best to use trapezoid if using x-wave
	Variable history
	
	Variable wcnt, numWaves, xflag
	String wName

	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	if ( strlen( nm.xWave ) > 0 )
		NMParamStrAdd( "xwave", nm.xWave, nm )
		xflag = 1
	endif
	
	if ( ( numtype( method ) > 0 ) || ( method < 0 ) || ( method > 1 ) )
		return NM2ErrorStr( 10, "method", num2str( method ) )
	endif
		
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Integrating Waves..." ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		Wave wtemp = $nm.folder + wName
		
		if ( xflag )
			Integrate /Meth=( method ) wtemp /X=$nm.folder + nm.xWave
		else
			Integrate /Meth=( method ) wtemp
		endif
		
		NMLoopWaveNote( nm.folder + wName, "" )
		
		nm.successList += wName + ";"
		
	endfor
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif

	return nm.successList
	
End // NMIntegrate2

//****************************************************************
//****************************************************************

Function /S NMDifferentiate( wList [ folder, xWave, deprecation ] ) // see NMDifferentiate2
	String wList, folder, xWave // see description at top
	Variable deprecation
	
	STRUCT NMParams nm
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( NMParamsInit( folder, wList, nm, xWave = xWave ) != 0 )
		return ""
	endif
	
	return NMDifferentiate2( nm )

End // NMDifferentiate

//****************************************************************
//****************************************************************

Function /S NMDifferentiate2( nm [ history ] ) // see Igor Differentiate
	STRUCT NMParams &nm // uses nm.folder, nm.wList, nm.xWave
	Variable history
	
	Variable wcnt, numWaves, xflag
	String wName
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	if ( strlen( nm.xWave ) > 0 )
		NMParamStrAdd( "xwave", nm.xWave, nm )
		xflag = 1
	endif
		
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Differentiating Waves..." ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		Wave wtemp = $nm.folder + wName
		
		if ( xflag )
			Differentiate wtemp /X=$nm.folder + nm.xWave
		else
			Differentiate wtemp
		endif
		
		NMLoopWaveNote( nm.folder + wName, nm.paramList )
		
		nm.successList += wName + ";"
		
	endfor
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif

	return nm.successList
	
End // NMDifferentiate2

//****************************************************************
//****************************************************************

Function /S NMFFTOuputStr( output )
	Variable output
	
	switch( output )
		case 1:
			return "complex"
		case 2:
			return "real"
		case 3:
			return "magnitude"
		case 4:
			return "magnitude square"
		case 5:
			return "phase"
		case 6:
			return "scaled magnitude"
		case 7:
			return "scaled magnitude square"
		default:
			return NM2ErrorStr( 10, "output", num2str( output ) )
	endswitch
	
End // NMFFTOuputStr

//****************************************************************
//****************************************************************

Function /S NMFFT( wList [ folder, xWave, xbgn, xend, output, rotation, updateLabels, deprecation ] ) // see NMFFT2
	String wList, folder, xWave // see description at top
	Variable xbgn, xend // x-axis window begin and end, ( -inf, inf ) for all
	Variable output // see /OUT ( see Igor FFT )
	Variable rotation // ( 0 ) disable rotation of FFT ( 1 ) perform rotation ( see Igor FFT )
	Variable updateLabels // ( 0 ) no ( 1 ) yes
	Variable deprecation
	
	STRUCT NMParams nm
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( NMParamsInit( folder, wList, nm, xWave = xWave ) != 0 )
		return ""
	endif
	
	return NMFFT2( nm, xbgn = xbgn, xend = xend, output = output, rotation = rotation, updateLabels = updateLabels )

End // NMFFT

//****************************************************************
//****************************************************************

Function /S NMFFT2( nm [ xbgn, xend, output, rotation, updateLabels, history ] ) // see Igor FFT
	STRUCT NMParams &nm // uses nm.folder, nm.wList, nm.xWave
	Variable xbgn, xend // x-axis window begin and end, ( -inf, inf ) for all
	Variable output // see /OUT ( see Igor FFT )
	Variable rotation // ( 0 ) disable rotation of FFT ( 1 ) perform rotation ( see Igor FFT )
	Variable updateLabels // ( 0 ) no ( 1 ) yes
	Variable history
	
	Variable wcnt, numWaves, xflag
	String wName, dName, notes, xLabel, yLabel
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	if ( strlen( nm.xWave ) > 0 )
		return NMXWaveFunctionError()
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( ( numtype( xbgn ) == 0 ) || ( numtype( xend ) == 0 ) )
		NMParamVarAdd( "xbgn", xbgn, nm )
		NMParamVarAdd( "xend", xend, nm )
	endif
	
	if ( ParamIsDefault( output ) )
		output = 3 // magnitude
	endif
	
	yLabel = NMFFTOuputStr( output )
	
	if ( strlen( yLabel ) == 0 )
		return ""
	endif
	
	if ( ParamIsDefault( rotation ) )
		rotation = 1
	endif
	
	if ( rotation != 0 )
		rotation = 1
	endif
	
	dName = nm.folder + "U_FFT_TEMP"
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Computing FFTs..." ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		Wave wtemp = $nm.folder + wName
		
		if ( ( numtype( xbgn ) == 1 ) && ( numtype( xend ) == 1 ) )
			if ( !rotation )
				FFT /Dest=$dName/Out=( output )/Z wtemp
			else
				FFT /Dest=$dName/Out=( output ) wtemp
			endif
		else
			if ( !rotation )
				FFT /Dest=$dName/Out=( output )/RX=(xbgn,xend)/Z wtemp
			else
				FFT /Dest=$dName/Out=( output )/RX=(xbgn,xend) wtemp
			endif
		endif
		
		notes = note( wtemp )
		
		xLabel = NMNoteLabel( "x", wName, "", folder = nm.folder )
		
		Duplicate /O $dName wtemp
		
		Note wtemp, notes
		
		if ( updateLabels )
			NMNoteStrReplace( nm.folder + wName, "xLabel", xLabel )
			NMNoteStrReplace( nm.folder + wName, "yLabel", "FFT " + yLabel )
		endif
		
		NMLoopWaveNote( nm.folder + wName, nm.paramList )
		
		nm.successList += wName + ";"
		
	endfor
	
	KillWaves /Z $nm.folder + "U_FFT_TEMP"
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif

	return nm.successList
	
End // NMFFT2

//****************************************************************
//****************************************************************

Function /S NMReplaceValue( find, replacement, wList [ folder ] ) // NMReplaceValue2
	Variable find // value in wave to find
	Variable replacement // replacement value
	String wList, folder // see description at top
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( NMParamsInit( folder, wList, nm ) != 0 )
		return ""
	endif
	
	return NMReplaceValue2( nm, find, replacement )
	
End // NMReplaceValue

//****************************************************************
//****************************************************************

Function /S NMReplaceValue2( nm, find, replacement [ history ] ) // see Igor MatrixOp Replace
	STRUCT NMParams &nm // uses nm.folder, nm.wList
	Variable find // value in wave to find
	Variable replacement // replacement value
	Variable history
	
	Variable wcnt, numWaves
	String wName
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	NMParamVarAdd( "find", find, nm )
	NMParamVarAdd( "replacement", replacement, nm )
	
	numWaves = ItemsInList( nm.wList )
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Replacing Values..." ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		Wave wtemp = $nm.folder + wName
		
		MatrixOp /O wtemp = Replace( wtemp, find, replacement )
		
		NMLoopWaveNote( nm.folder + wName, nm.paramList )
		
		nm.successList += wName + ";"
		
	endfor

	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif

	return nm.successList
	
End // NMReplaceValue2

//****************************************************************
//****************************************************************

Function /S NMDeleteNaNs2( nm [ history ] )
	STRUCT NMParams &nm // uses nm.folder, nm.wList
	Variable history
	
	Variable wcnt, numWaves
	String wName
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	numWaves = ItemsInList( nm.wList )
		
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Deleting NaNs..." ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )

		WaveTransform /O zapNaNs $nm.folder + wName
		
		NMLoopWaveNote( nm.folder + wName, nm.paramList )
		
		nm.successList += wName + ";"
		
	endfor

	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif

	return nm.successList
	
End // NMDeleteNaNs2

//****************************************************************
//****************************************************************

Function NMClipEventsError( xwinBeforeEvent, xwinAfterEvent, findEvents, eventFindLevel, waveOfEventTimes )
	Variable xwinBeforeEvent
	Variable xwinAfterEvent
	Variable findEvents
	Variable eventFindLevel
	String waveOfEventTimes
	
	if ( numtype( xwinBeforeEvent ) > 0 )
		return NM2Error( 10, "xwinBeforeEvent", num2str( xwinBeforeEvent ) )
	endif
	
	if ( numtype( xwinAfterEvent ) > 0 )
		return NM2Error( 10, "xwinAfterEvent", num2str( xwinAfterEvent ) )
	endif
	
	if ( findEvents )
		if ( numtype( eventFindLevel ) > 0 )
			return NM2Error( 10, "eventFindLevel", num2str( eventFindLevel ) )
		endif
	else
		if ( !NMUtilityWaveTest( waveOfEventTimes ) == 0 )
			return NM2Error( 1, "waveOfEventTimes", waveOfEventTimes )
		endif
	endif

	return 0
	
End // NMClipEventsError

//****************************************************************
//****************************************************************

Function /S NMClipEvents( xwinBeforeEvent, xwinAfterEvent, wList [ folder, eventFindLevel, positiveEvents, waveOfEventTimes, clipValue, deprecation ] ) // see NMClipEvents2
	Variable positiveEvents // for FindLevels ( 0 ) negative events ( 1 ) positive events
	Variable eventFindLevel // level for Igor FindLevels
	Variable xwinBeforeEvent // x-axis window to clip before detected event
	Variable xwinAfterEvent // x-axis window to clip after detected event
	String wList, folder // see description at top
	String waveOfEventTimes // name of wave containing event times, will bypass event detection using FindLevels
	Variable clipValue // clip events with this value, rather than linear interpolation method
	Variable deprecation
	
	Variable findEvents = 1 // ( 0 ) use waveOfEventTimes ( 1 ) use FindLevels
	Variable clipMethod = 0 // ( 0 ) linear interpolation ( 1 ) clip with clipValue
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( NMParamsInit( folder, wList, nm ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( positiveEvents ) )
		positiveEvents = 1
	endif
	
	if ( !ParamIsDefault( waveOfEventTimes ) )
		findEvents = 0
	endif
	
	if ( findEvents )
		if ( ParamIsDefault( eventFindLevel ) )
			return NM2ErrorStr( 11, "eventFindLevel", num2str( eventFindLevel ) )
		endif
	endif
	
	if ( !ParamIsDefault( clipValue ) )
		clipMethod = 1
	endif
	
	if ( findEvents )
		if ( clipMethod == 1 )
			return NMClipEvents2( nm, xwinBeforeEvent, xwinAfterEvent, eventFindLevel = eventFindLevel, positiveEvents = positiveEvents, clipValue = clipValue )
		else
			return NMClipEvents2( nm, xwinBeforeEvent, xwinAfterEvent, eventFindLevel = eventFindLevel, positiveEvents = positiveEvents )
		endif
	else
		if ( clipMethod == 1 )
			return NMClipEvents2( nm, xwinBeforeEvent, xwinAfterEvent, waveOfEventTimes = waveOfEventTimes, clipValue = clipValue )
		else
			return NMClipEvents2( nm, xwinBeforeEvent, xwinAfterEvent, waveOfEventTimes = waveOfEventTimes )
		endif
	endif
	
End // NMClipEvents

//****************************************************************
//
//	NMClipEvents2
//	clip/truncate events before/after event times
//	event times are computed via Igor FindLevels for either negative or positive events
// 	or event times can be passed via waveOfEventTimes
//	base on algorithm of Gerard Borst, Erasmus MC, Dept of Neuroscience
//
//****************************************************************

Function /S NMClipEvents2( nm, xwinBeforeEvent, xwinAfterEvent [ eventFindLevel, positiveEvents, waveOfEventTimes, clipValue, history ] )
	STRUCT NMParams &nm // uses nm.folder, nm.wList
	Variable xwinBeforeEvent // x-axis window to clip before detected event
	Variable xwinAfterEvent // x-axis window to clip after detected event
	Variable eventFindLevel // level for Igor FindLevels
	Variable positiveEvents // for FindLevels ( 0 ) negative events ( 1 ) positive events, default
	String waveOfEventTimes // name of wave containing event times, will bypass event detection using FindLevels
	Variable clipValue // clip events with this value, rather than linear interpolation method
	Variable history
	
	Variable numWaves, wcnt, icnt, events, eventTime, edge
	Variable tbgn, tend, lftx, rgtx, npnts, pbgn, pend, m, b
	String wName
	
	Variable findEvents = 1 // ( 0 ) use waveOfEventTimes ( 1 ) use FindLevels
	Variable clipMethod = 0 // ( 0 ) linear interpolation ( 1 ) clip with clipValue
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	if ( strlen( nm.xWave ) > 0 )
		return NMXWaveFunctionError() // currently not working for xwave
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	if ( ParamIsDefault( positiveEvents ) )
		positiveEvents = 1
	endif
	
	if ( ParamIsDefault( waveOfEventTimes ) )
		waveOfEventTimes = ""
	else
		findEvents = 0
	endif
	
	if ( findEvents )
		if ( ParamIsDefault( eventFindLevel ) )
			return NM2ErrorStr( 11, "eventFindLevel", num2str( eventFindLevel ) )
		endif
	endif
	
	if ( NMClipEventsError( xwinBeforeEvent, xwinAfterEvent, findEvents, eventFindLevel, waveOfEventTimes ) != 0 )
		return ""
	endif
	
	if ( !ParamIsDefault( clipValue ) )
		clipMethod = 1
	endif
	
	if ( positiveEvents )
		edge = 1
	else
		edge = 2
	endif
	
	xwinBeforeEvent = abs( xwinBeforeEvent )
	xwinAfterEvent = abs( xwinAfterEvent )
	
	if ( findEvents )
	
		if ( positiveEvents )
			NMParamVarAdd( "level+", eventFindLevel, nm )
		else
			NMParamVarAdd( "level-", eventFindLevel, nm )
		endif
		
		NMParamVarAdd( "before", xwinBeforeEvent, nm )
		NMParamVarAdd( "after", xwinAfterEvent, nm )
	
	else // Find Levels
	
		NMParamStrAdd( "events", NMChild( waveOfEventTimes ), nm )
		NMParamVarAdd( "before", xwinBeforeEvent, nm )
		NMParamVarAdd( "after", xwinAfterEvent, nm )
	
	endif
	
	if ( clipMethod == 1 )
		NMParamVarAdd( "clip", clipValue, nm )
	endif
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Clipping Events... " + num2istr( wcnt ) ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		Wave wtemp = $nm.folder + wName
		
		if ( findEvents )
	
			FindLevels /EDGE=( edge ) /Q wtemp, eventFindLevel
			
			if ( ( V_LevelsFound == 0 ) || !WaveExists( $"W_FindLevels" ) )
				nm.successList += wName + ";" // still count this as success
				continue
			endif
			
			Wave etemp = W_FindLevels
			
		else
		
			Wave etemp = $waveOfEventTimes
			
		endif
		
		events = numpnts( etemp )
		
		lftx = leftx( wtemp )
		rgtx = rightx( wtemp )
		npnts = numpnts( wtemp )
		
		for ( icnt = 0 ; icnt < events ; icnt += 1 )
		
			eventTime = etemp[ icnt ]
			
			if ( ( numtype( eventTime ) > 0 ) || ( eventTime < lftx ) || ( eventTime > rgtx ) )
				continue
			endif
			
			tbgn = eventTime - xwinBeforeEvent
			tend = eventTime + xwinAfterEvent
			
			pbgn = x2pnt( wtemp, tbgn )
			pend = x2pnt( wtemp, tend )
			
			pbgn = max( pbgn, 0 )
			pend = min( pend, npnts - 1 )
			
			if ( clipMethod == 1 )
			
				wtemp[ pbgn, pend ] = clipValue
				
				continue
				
			endif
			
			// compute linear interpolation 1 point before and after pbgn and pend
			
			pbgn -= 1 
			pend += 1
			
			if ( ( pbgn < 0 ) || ( pend >= numpnts( wtemp ) ) )
				continue // out of range
			endif
			
			m = ( wtemp[ pend ] - wtemp[ pbgn ] ) / ( pend - pbgn )
			b = wtemp[ pbgn ] - m * pbgn
			
			wtemp[ pbgn + 1, pend - 1 ] = m * p + b
		
		endfor
		
		nm.successList += wName + ";"
		
		NMLoopWaveNote( nm.folder + wName, nm.paramList )
		
	endfor
	
	KillWaves /Z W_FindLevels
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.successList )

	return nm.successList
	
End // NMClipEvents2

//****************************************************************
//****************************************************************
//
//		Wave Functions
//		WaveStats, Average, Sum, Histogram...
//
//****************************************************************
//****************************************************************

Function /S NMWaveStats( [ folder, wList, xWave, matchStr, chanTransforms, prefixFolder, xbgn, xend, outputSelect, windowName, windowTitle, subfolder, outputPrefix, fullPath, table ] )
	String folder, wList, xWave // see description at top
	String matchStr // create wave list based on this matching string
	Variable chanTransforms // pass channel number to use its Transform and smoothing/filtering settings, pass nothing for none
	String prefixFolder // full-path folder name of prefix folder to use with chanTransforms
	
	Variable xbgn, xend // x-axis window begin and end, ( -inf, inf ) for all
	
	Variable outputSelect // ( 0 ) return stats string list ( 1 ) Igor history ( 2 ) notebook ( 3 ) waves in table
	
	String windowName, windowTitle // for notebook or table
	
	String subfolder // subfolder name where output waves are created, nothing for no subfolder, or "_default_" for auto name generation
	String outputPrefix // prefix name for output waves, default "W_"
	Variable fullPath // format for wave of wave names ( 0 ) just wave name ( 1 ) full-path wave name
	Variable table // display output waves in table ( 0 ) no ( 1 ) yes
	
	Variable numWaves
	String fName
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wList ) )
		wList = ""
	endif
	
	if ( ParamIsDefault( xWave ) )
		xWave = ""
	endif
	
	if ( !ParamIsDefault( matchStr ) && ( strlen( matchStr ) > 0 ) )
		wList = NMFolderWaveList( folder, matchStr, ";", "", 0 )
	endif
	
	if ( NMParamsInit( folder, wList, nm, xWave = xWave ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( chanTransforms ) )
		nm.transforms = 0
		nm.chanNum = NaN
	elseif ( numtype( chanTransforms ) == 0 )
		nm.transforms = 1
		nm.chanNum = chanTransforms
	else
		nm.transforms = 0
		nm.chanNum = NaN
	endif
	
	if ( ParamIsDefault( prefixFolder ) )
		nm.prefixFolder = ""
	else
		nm.prefixFolder = prefixFolder
	endif
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( ParamIsDefault( outputSelect ) )
		outputSelect = 1
	endif
	
	fName = NMChild( nm.folder )
	
	switch( outputSelect )
	
		case 0: // stats string list
		case 1: // history
		
			return NMWaveStats2( nm, xbgn = xbgn, xend = xend, outputSelect = outputSelect )
			
		case 2: // notebook
		
			if ( ParamIsDefault( windowName ) || ( strlen( windowName ) == 0 ) )
				windowName = UniqueName( "NM_WaveStatsNotebook", 10, 0 )
			endif
			
			if ( ParamIsDefault( windowTitle ) )
				windowTitle = "Wave Stats : " + fName + " : n = " + num2istr( numWaves )
			endif
		
			return NMWaveStats2( nm, xbgn = xbgn, xend = xend, outputSelect = outputSelect, windowName = windowName, windowTitle = windowTitle )
			
		case 3: // output waves / table
		
			if ( ParamIsDefault( windowName ) || ( strlen( windowName ) == 0 ) )
				windowName = UniqueName( "NM_WaveStatsTable", 7, 0 )
			endif
			
			if ( ParamIsDefault( windowTitle ) )
				windowTitle = "Wave Stats : " + fName + " : n = " + num2istr( numWaves )
			endif
			
			if ( ParamIsDefault( outputPrefix ) )
				outputPrefix = "W_"
			endif
			
			if ( ParamIsDefault( table ) )
				table = 1
			endif
			
			if ( ParamIsDefault( subfolder ) )
				return NMWaveStats2( nm, xbgn = xbgn, xend = xend, outputSelect = outputSelect, windowName = windowName, windowTitle = windowTitle, outputPrefix = outputPrefix, fullPath = fullPath )
			else
				return NMWaveStats2( nm, xbgn = xbgn, xend = xend, outputSelect = outputSelect, windowName = windowName, windowTitle = windowTitle, subfolder = subfolder, outputPrefix = outputPrefix, fullPath = fullPath )
			endif
			
	endswitch
	
	return ""
	
End // NMWaveStats

//****************************************************************
//****************************************************************

Function /S NMWaveStats2( nm [ xbgn, xend, outputSelect, windowName, windowTitle, subfolder, outputPrefix, fullPath, history ] )
	STRUCT NMParams &nm // uses nm.folder, nm.wList, nm.xWave // nm.transforms uses nm.chanNum and nm.prefixFolder
	
	Variable xbgn, xend // x-axis window begin and end, ( -inf, inf ) for all
	
	Variable outputSelect // ( 0 ) return stats string list ( 1 ) Igor history ( 2 ) notebook ( 3 ) waves in table ( 4 ) waves no table
	
	String windowName, windowTitle // for notebook or table
	
	String subfolder // subfolder name where output waves are created, nothing for no subfolder, or "_default_" for auto name generation
	String outputPrefix // prefix name for output waves, default "W_"
	Variable fullPath // format for wave of wave names ( 0 ) just wave name ( 1 ) full-path wave name
	Variable history
	
	Variable wcnt, numWaves, numChannels, npnts, xflag, returnVal
	String wName, waveOfWaveNames, fName, txt, fxn, xLabel, xLabel2, yLabel
	String tName, tName2
	
	NMOutputListsReset()
	
	STRUCT NMWaveStatsStruct s
	NMWaveStatsStructNull( s )
	
	STRUCT Rect w
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	tName2 = nm.folder + "U_WaveTemp"
	
	numWaves = ItemsInList( nm.wList )
	
	fName = NMChild( nm.folder )
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( ( numtype( xbgn ) == 0 ) || ( numtype( xend ) == 0 ) )
		NMParamVarAdd( "xbgn", xbgn, nm )
		NMParamVarAdd( "xend", xend, nm )
	endif
	
	if ( strlen( nm.xWave ) > 0 )
		NMParamStrAdd( "xwave", nm.xWave, nm )
		xflag = 1
	endif
	
	if ( nm.transforms )
	
		if ( !DataFolderExists( nm.prefixFolder ) )
			return NM2ErrorStr( 30, "prefixFolder", nm.prefixFolder )
		endif
	
		numChannels = NumVarOrDefault( nm.prefixFolder + "NumChannels", 0 )
		
		if ( nm.chanNum >= numChannels )
			return NM2ErrorStr( 10, "chanNum", num2istr( nm.chanNum ) )
		endif
		
		if ( !NMChanTransformExists( channel = nm.chanNum , prefixFolder = nm.prefixFolder ) )
			nm.transforms = 0
		endif
		
		if ( nm.transforms )
			NMParamVarAdd( "transforms", nm.transforms, nm )
		endif
		
	endif
	
	if ( ParamIsDefault( outputSelect ) )
		outputSelect = 1
	endif
	
	if ( ( outputSelect == 0 ) || ( outputSelect == 1 ) ) // print to Igor history
	
		if ( outputSelect == 1 )
			history = 1
		endif
	
		for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
			wName = StringFromList( wcnt, nm.wList )
			
			//if ( outputSelect == 1 )
				//Print NMCR + "WaveStats " + nm.folder + wName
			//endif
			
			if ( nm.transforms )
			
				if ( xflag )
					returnVal = ChanWaveMake( nm.chanNum, nm.folder + wName, tName2, prefixFolder = nm.prefixFolder, xWave = nm.folder + nm.xWave )
				else
					returnVal = ChanWaveMake( nm.chanNum, nm.folder + wName, tName2, prefixFolder = nm.prefixFolder, xWave = "" )
				endif
				
				if ( returnVal < 0 )
					continue
				endif
				
				tName = tName2
				
			else
			
				tName = nm.folder + wName
				
			endif
			
			if ( xflag )
				nm.newList += NMWaveStatsXY( tName, xWave = nm.folder + nm.xWave, xbgn = xbgn, xend = xend, history = history )
			else
				nm.newList += NMWaveStatsXY( tName, xbgn = xbgn, xend = xend, history = history )
			endif
			
			nm.successList += wName + ";"
		
		endfor
		
		NMParamsComputeFailures( nm )
		
		//if ( history )
			//NMLoopHistory( nm ) // not necessary
		//endif
		
		KillWaves /Z $tName2
	
		return nm.newList
	
	endif
	
	if ( outputSelect == 2 ) // notebook
	
		if ( ParamIsDefault( windowName ) || ( strlen( windowName ) == 0 ) )
			windowName = UniqueName( "NM_WaveStatsNotebook", 10, 0 )
		endif
		
		if ( ParamIsDefault( windowTitle ) )
			windowTitle = "Wave Stats : " + fName + " : n = " + num2istr( numWaves )
		endif
	
		if ( WinType( windowName ) == 5 )
		
			DoWindow /F $windowName
			Notebook $windowName selection={endOfFile, endOfFile}
			
		else
		
			NMWinCascadeRect( w )
		
			DoWindow /K $windowName
			NewNotebook /F=0/K=(NMK())/N=$windowName/W=(w.left,w.top,w.right,w.bottom) as windowTitle
			Notebook $windowName selection={endOfFile, endOfFile}
			NoteBook $windowName text="NeuroMatic Wave Stats"
			NoteBook $windowName text=NMCR + "Folder : " + fName
		
		endif
	
		for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
			wName = StringFromList( wcnt, nm.wList )
			
			if ( nm.transforms )
			
				if ( xflag )
					returnVal = ChanWaveMake( nm.chanNum, nm.folder + wName, tName2, prefixFolder = nm.prefixFolder, xWave = nm.folder + nm.xWave )
				else
					returnVal = ChanWaveMake( nm.chanNum, nm.folder + wName, tName2, prefixFolder = nm.prefixFolder, xWave = "" )
				endif
				
				if ( returnVal < 0 )
					continue
				endif
				
				tName = tName2
				
			else
			
				tName = nm.folder + wName
				
			endif
			
			if ( xflag )
				NMWaveStatsStructInit( s, tName, xWave = nm.folder + nm.xWave, xbgn = xbgn, xend = xend )
				txt = NMWaveStatsXY2( s )
			else
				NMWaveStatsStructInit( s, tName, xbgn = xbgn, xend = xend )
				txt = NMWaveStatsXY2( s )
			endif
			
			NoteBook $windowName text=NMCR+NMCR+txt
			
			nm.successList += wName + ";"

		endfor
		
		nm.windowList = windowName
		
		NMParamsComputeFailures( nm )
		
		if ( history )
			NMLoopHistory( nm )
		endif
		
		SetNMstr( NMDF + "OutputWinList", nm.windowList )
		
		KillWaves /Z $tName2
	
		return nm.windowList
	
	endif
	
	if ( ( outputSelect != 3 ) && ( outputSelect != 4 ) )
		return ""
	endif
	
	// create stats waves and table
	
	if ( ParamIsDefault( subfolder ) )
		subfolder = nm.folder
	elseif ( StringMatch( subfolder, "_default_" ) )
		subfolder = UniqueName( "WStats", 11, 0 )
	endif
	
	if ( ParamIsDefault( outputPrefix ) )
		outputPrefix = "W_"
	endif
	
	if ( outputSelect == 3 )
	
		if ( ParamIsDefault( windowName ) || ( strlen( windowName ) == 0 ) )
			windowName = UniqueName( "NM_WaveStatsTable", 7, 0 )
		endif
		
		if ( ParamIsDefault( windowTitle ) )
			windowTitle = "Wave Stats : " + fName + " : n = " + num2istr( numWaves )
		endif
		
		NMWinCascadeRect( w )
	
		DoWindow /K $windowName
		Edit /K=(NMK())/N=$windowName/W=(w.left,w.top,w.right,w.bottom) as windowTitle
		ModifyTable /W=$windowName title( Point )="Wave"
		
		nm.windowList = windowName
		
	endif
		
	if ( strlen( nm.xLabel ) > 0 )
		xLabel = nm.xLabel
	else
		xLabel = NMNoteLabel( "x", nm.wList, "", folder = nm.folder )
	endif
	
	if ( strlen( nm.yLabel ) > 0 )
		yLabel = nm.yLabel
	else
		yLabel = NMNoteLabel( "y", nm.wList, "", folder = nm.folder )
	endif
	
	xLabel2 = "Wave #"
	
	fxn = NMLoopWaveNote( "", nm.paramList )

	waveOfWaveNames = NMWaveStats2MakeWave( subfolder, outputPrefix + "name", numWaves, windowName, fxn, xLabel2, "wave names", "" )
	nm.newList += waveOfWaveNames + ";"
	Wave /T W_names = $waveOfWaveNames
	
	wName = NMWaveStats2MakeWave( subfolder, outputPrefix + "sum", numWaves, windowName, fxn, xLabel2, yLabel, waveOfWaveNames )
	nm.newList += wName + ";"
	Wave W_sum = $wName
	
	wName = NMWaveStats2MakeWave( subfolder, outputPrefix + "avg", numWaves, windowName, fxn, xLabel2, yLabel, waveOfWaveNames )
	nm.newList += wName + ";"
	Wave W_avg = $wName
	
	wName = NMWaveStats2MakeWave( subfolder, outputPrefix + "sdev", numWaves, windowName, fxn, xLabel2, yLabel, waveOfWaveNames )
	nm.newList += wName + ";"
	Wave W_sdev = $wName
	
	wName = NMWaveStats2MakeWave( subfolder, outputPrefix + "sem", numWaves, windowName, fxn, xLabel2, yLabel, waveOfWaveNames )
	nm.newList += wName + ";"
	Wave W_sem = $wName
	
	wName = NMWaveStats2MakeWave( subfolder, outputPrefix + "rms", numWaves, windowName, fxn, xLabel2, yLabel, waveOfWaveNames )
	nm.newList += wName + ";"
	Wave W_rms = $wName
	
	wName = NMWaveStats2MakeWave( subfolder, outputPrefix + "adev", numWaves, windowName, fxn, xLabel2, yLabel, waveOfWaveNames )
	nm.newList += wName + ";"
	Wave W_adev = $wName
	
	wName = NMWaveStats2MakeWave( subfolder, outputPrefix + "skew", numWaves, windowName, fxn, xLabel2, "skew", waveOfWaveNames )
	nm.newList += wName + ";"
	Wave W_skew = $wName
	
	wName = NMWaveStats2MakeWave( subfolder, outputPrefix + "kurt", numWaves, windowName, fxn, xLabel2, "kurt", waveOfWaveNames )
	nm.newList += wName + ";"
	Wave W_kurt = $wName
	
	wName = NMWaveStats2MakeWave( subfolder, outputPrefix + "min", numWaves, windowName, fxn, xLabel2, yLabel, waveOfWaveNames )
	nm.newList += wName + ";"
	Wave W_min = $wName
	
	wName = NMWaveStats2MakeWave( subfolder, outputPrefix + "minLoc", numWaves, windowName, fxn, xLabel2, xLabel, waveOfWaveNames )
	nm.newList += wName + ";"
	Wave W_minLoc = $wName
	
	wName = NMWaveStats2MakeWave( subfolder, outputPrefix + "minRowLoc", numWaves, windowName, fxn, xLabel2, "point", waveOfWaveNames )
	nm.newList += wName + ";"
	Wave W_minRowLoc = $wName
	
	wName = NMWaveStats2MakeWave( subfolder, outputPrefix + "max", numWaves, windowName, fxn, xLabel2, yLabel, waveOfWaveNames )
	nm.newList += wName + ";"
	Wave W_max = $wName
	
	wName = NMWaveStats2MakeWave( subfolder, outputPrefix + "maxLoc", numWaves, windowName, fxn, xLabel2, xLabel, waveOfWaveNames )
	nm.newList += wName + ";"
	Wave W_maxLoc = $wName
	
	wName = NMWaveStats2MakeWave( subfolder, outputPrefix + "maxRowLoc", numWaves, windowName, fxn, xLabel2, "point", waveOfWaveNames )
	nm.newList += wName + ";"
	Wave W_maxRowLoc = $wName
	
	wName = NMWaveStats2MakeWave( subfolder, outputPrefix + "npnts", numWaves, windowName, fxn, xLabel2, "points", waveOfWaveNames )
	nm.newList += wName + ";"
	Wave W_npnts = $wName
	
	wName = NMWaveStats2MakeWave( subfolder, outputPrefix + "numNaNs", numWaves, windowName, fxn, xLabel2, "numNaNs", waveOfWaveNames )
	nm.newList += wName + ";"
	Wave W_numNaNs = $wName
	
	wName = NMWaveStats2MakeWave( subfolder, outputPrefix + "numINFs", numWaves, windowName, fxn, xLabel2, "numINFs", waveOfWaveNames )
	nm.newList += wName + ";"
	Wave W_numINFs = $wName
	
	wName = NMWaveStats2MakeWave( subfolder, outputPrefix + "startRow", numWaves, windowName, fxn, xLabel2, "startRow", waveOfWaveNames )
	nm.newList += wName + ";"
	Wave W_startRow = $wName
	
	wName = NMWaveStats2MakeWave( subfolder, outputPrefix + "endRow", numWaves, windowName, fxn, xLabel2, "endRow", waveOfWaveNames )
	nm.newList += wName + ";"
	Wave W_endRow = $wName
		
	for ( wcnt = 0; wcnt < numWaves; wcnt += 1 )
	
		wName = StringFromList( wcnt, nm.wList )
		
		if ( nm.transforms )
		
			if ( xflag )
				returnVal = ChanWaveMake( nm.chanNum, nm.folder + wName, tName2, prefixFolder = nm.prefixFolder, xWave = nm.folder + nm.xWave )
			else
				returnVal = ChanWaveMake( nm.chanNum, nm.folder + wName, tName2, prefixFolder = nm.prefixFolder, xWave = "" )
			endif
			
			if ( returnVal < 0 )
				continue
			endif
			
			tName = tName2
			
		else
		
			tName = nm.folder + wName
			
		endif
		
		if ( xflag )
			NMWaveStatsStructInit( s, tName, xWave = nm.folder + nm.xWave, xbgn = xbgn, xend = xend )
			txt = NMWaveStatsXY2( s )
		else
			NMWaveStatsStructInit( s, tName, xbgn = xbgn, xend = xend )
			txt = NMWaveStatsXY2( s )
		endif
		
		if ( fullPath )
			W_names[ wcnt ] = nm.folder + wName
		else
			W_names[ wcnt ] = wName
		endif
		
		W_sum[ wcnt ] = s.sum
		W_avg[ wcnt ] = s.avg
		W_sdev[ wcnt ] = s.sdev
		W_sem[ wcnt ] = s.sem
		
		W_rms[ wcnt ] = s.rms
		W_adev[ wcnt ] = s.adev
		W_skew[ wcnt ] = s.skew
		W_kurt[ wcnt ] = s.kurt
		
		W_min[ wcnt ] = s.min
		W_minLoc[ wcnt ] = s.minLoc
		W_minRowLoc[ wcnt ] = s.minRowLoc
		
		W_max[ wcnt ] = s.max
		W_maxLoc[ wcnt ] = s.maxLoc
		W_MaxRowLoc[ wcnt ] = s.maxRowLoc
		
		W_npnts[ wcnt ] = s.points
		W_numNaNs[ wcnt ] = s.numNaNs
		W_numINFs[ wcnt ] = s.numINFs
		W_startRow[ wcnt ] = s.startRow
		W_endRow[ wcnt ] = s.endRow
		
		nm.successList += wName + ";"
		
	endfor
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm, includeOutputSubfolder = 1 )
	endif
	
	KillWaves /Z $tName2
	
	if ( outputSelect == 3 )
		
		SetNMstr( NMDF + "OutputWaveList", nm.newList )
		SetNMstr( NMDF + "OutputWinList", nm.windowList )

		return nm.windowList
	
	else
	
		SetNMstr( NMDF + "OutputWaveList", nm.newList )

		return nm.successList
	
	endif

	return nm.windowList
	
End // NMWaveStats2

//****************************************************************
//****************************************************************

Static Function /S NMWaveStats2MakeWave( folder, wName, npnts, tableName, fxn, xLabel, ylabel, waveOfWaveNames )
	String folder
	String wName
	Variable npnts
	String tableName
	String fxn
	String xLabel, yLabel
	String waveOfWaveNames
	
	if ( strlen( folder ) > 0 )
		if ( strsearch( folder, ":", 0 ) == -1 )
			folder = GetDataFolder( 1 ) + folder + ":"
		endif
	endif
	
	if ( !DataFolderExists( folder ) )
		NewDataFolder $RemoveEnding( folder, ":" )
	endif
	
	if ( strsearch( wName, "name", 0 ) > 0 )
		Make /O/N=( npnts )/T $folder + wName = ""
	else
		Make /O/N=( npnts ) $folder + wName = NaN
	endif
	
	NMNoteType( folder + wName, "NMWaveStats", xLabel, yLabel, "Func:" + fxn )
	
	if ( strlen( waveOfWaveNames ) > 0 )
		Note $folder + wName, "Wave Names:" + waveOfWaveNames
	endif
	
	if ( ( strlen( tableName ) > 0 ) && ( WinType( tableName ) == 2 ) )
		AppendToTable /W=$tableName $folder + wName
	endif
	
	return folder + wName
	
End // NMWaveStats2MakeWave

//****************************************************************
//****************************************************************

Structure NMMatrixStatsStruct

	// inputs
	
	Variable xbgn, xend, ignoreNANs, truncateToCommonXScale, saveMatrix
	
	// outputs
	
	Variable leftx, rightx, dx, points
	Wave avg, stdv, sums, sumsqrs, count, xWave, matrix
	
EndStructure

//****************************************************************
//****************************************************************

Function NMMatrixStatsStructKill( s )
	STRUCT NMMatrixStatsStruct &s

	Wave wtemp = s.avg
	KillWaves /Z wtemp
	
	Wave wtemp = s.stdv
	KillWaves /Z wtemp
	
	Wave wtemp = s.sums
	KillWaves /Z wtemp
	
	Wave wtemp = s.sumsqrs
	KillWaves /Z wtemp
	
	Wave wtemp = s.count
	KillWaves /Z wtemp
	
	Wave wtemp = s.xWave
	KillWaves /Z wtemp
	
	Wave wtemp = s.matrix
	KillWaves /Z wtemp
	
End // NMMatrixStatsStructKill

//****************************************************************
//****************************************************************

Function /S NMMatrixStats( wList [ folder, chanTransforms, prefixFolder, xbgn, xend, ignoreNANs, truncateToCommonXScale, saveMatrix, deprecation ] )
	String wList, folder // see description at top
	Variable chanTransforms // pass channel number to use its Transform and smoothing/filtering settings, pass nothing for none
	String prefixFolder // full-path folder name of prefix folder to use with chanTransforms
	Variable xbgn, xend // x-axis window begin and end
	Variable ignoreNANs // ignore NANs in computation ( 0 ) no ( 1 ) yes, default
	Variable truncateToCommonXScale // ( 0 ) no, if necessary, waves are expanded to fit all x-axis min and max ( 1 ) yes, default, waves are truncated to a common x-axis
	Variable saveMatrix // save list of waves as a 2D matrix called U_2Dmatrix ( 0 ) no, default ( 1 ) yes
	Variable deprecation
	
	Variable numChannels
	
	STRUCT NMParams nm
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( NMParamsInit( folder, wList, nm ) != 0 )
		return ""
	endif
	
	if ( ItemsInList( nm.wList ) < 2 )
		return NM2ErrorStr( 90, "number of input waves is less than 2", "" )
	endif
	
	if ( ParamIsDefault( chanTransforms ) )
		nm.transforms = 0
		nm.chanNum = NaN
	elseif ( numtype( chanTransforms ) == 0 )
		nm.transforms = 1
		nm.chanNum = chanTransforms
	else
		nm.transforms = 0
		nm.chanNum = NaN
	endif
	
	if ( ParamIsDefault( prefixFolder ) )
		nm.prefixFolder = ""
	else
		nm.prefixFolder = prefixFolder
	endif
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( ParamIsDefault( ignoreNANs ) )
		ignoreNANs = 1
	endif
	
	STRUCT NMMatrixStatsStruct s
	
	s.xbgn = xbgn
	s.xend = xend
	s.ignoreNANs = ignoreNANs
	s.truncateToCommonXScale = truncateToCommonXScale
	s.saveMatrix = saveMatrix
		
	return NMMatrixStats2( nm, s )
	
End // NMMatrixStats

//****************************************************************
//****************************************************************
//
//	NMMatrixStats
//	compute avg, stdv, sum, sumsqr, npnts of a list of waves
//	also can create a 2D matrix wave from the input wave list
//
//	Output waves: U_Avg, U_Sdv, U_Pnts, U_Sum, U_SumSqr, U_Xwave, U_2Dmatrix
//
//****************************************************************
//****************************************************************

Function /S NMMatrixStats2( nm, s [ history ] )
	STRUCT NMParams &nm // uses nm.folder, nm.wList, nm.xWave // nm.transforms uses nm.chanNum and nm.prefixFolder
	STRUCT NMMatrixStatsStruct &s
	Variable history
	
	Variable error, numChannels, wcnt, numWaves, returnVal
	Variable interpToSameDX, foundNANs
	Variable pcnt, pbgn, pend, points, lftx, rghtx, dx, dx2, xflag, ipnts, ibgn
	Variable precision = 4 // 64-bit (double precision) floating point
	
	String wName, infoStr, xLabel, yLabel, oList
	String xWaveNew, tName, tName1, tName2, tName3
	String fxn
	
	STRUCT NMXAxisStruct xs

	Variable minNumOfDataPoints = NumVarOrDefault( "U_minNumOfDataPoints", 2 ) // min number of data points to include in average
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	SetNMstr( NMDF + "OutputWaveList", "" )
	
	xWaveNew = nm.folder + "U_Avg"
	tName1 = nm.folder + "U_WaveTemp1"
	tName2 = nm.folder + "U_WaveTemp2"
	tName3 = nm.folder + "U_PntsTemp"
	
	numWaves = ItemsInList( nm.wList )
	
	if ( numWaves < 2 )
		return NM2ErrorStr( 90, "number of input waves is less than 2", "" )
	endif
	
	if ( numtype( s.xbgn ) > 0 )
		s.xbgn = -inf
	endif
	
	if ( numtype( s.xend ) > 0 )
		s.xend = inf
	endif
	
	if ( ( numtype( s.xbgn ) == 0 ) || ( numtype( s.xend ) == 0 ) )
		NMParamVarAdd( "xbgn", s.xbgn, nm )
		NMParamVarAdd( "xend", s.xend, nm )
	endif
	
	if ( strlen( nm.xWave ) > 0 )
	
		NMParamStrAdd( "xwave", nm.xWave, nm )
		
		pbgn = NMX2Pnt( nm.folder + nm.xWave, s.xbgn )
		pend = NMX2Pnt( nm.folder + nm.xWave, s.xend )
		
		points = pend - pbgn + 1
		lftx = 0
		dx = 1
		xflag = 1
		
	else
	
		NMXAxisStructInit( xs, nm.wList, folder = nm.folder )
		NMXAxisStats2( xs )
		
		if ( xs.sameXscale )
	
			dx = xs.dx
			
			if ( ( numtype( s.xbgn ) == 1 ) && ( numtype( s.xend ) == 1 ) ) // -inf to inf
				lftx = xs.leftx
				rghtx = xs.rightx
				points = xs.points
			else
				lftx = max( s.xbgn, xs.leftx )
				rghtx = min( s.xend, xs.rightx )
				//points = floor( ( rghtx - lftx ) / dx )
				points = ceil( ( rghtx - lftx ) / dx )
			endif
		
		else
			
			if ( numtype( xs.dx ) == 0 )
				dx = xs.dx
			else
				dx = xs.minDX
				interpToSameDX = 1
			endif
			
			if ( s.truncateToCommonXScale ) // contract
				lftx = max( s.xbgn, xs.maxLeftx )
				rghtx = min( s.xend, xs.minRightx )
			else // expand
				lftx = max( s.xbgn, xs.minLeftx )
				rghtx = min( s.xend, xs.maxRightx )
			endif
			
			//points = floor( ( rghtx - lftx ) / dx )
			points = ceil( ( rghtx - lftx ) / dx )
			
		endif

	endif
	
	if ( ( numtype( points ) > 0 ) || ( points < 1 ) )
		return NM2ErrorStr( 10, "points", num2str( points ) )
	endif
	
	if ( numtype( lftx ) > 0 )
		return NM2ErrorStr( 10, "lftx", num2str( lftx ) )
	endif
	
	if ( numtype( dx ) > 0 )
		return NM2ErrorStr( 10, "dx", num2str( dx ) )
	endif
	
	if ( nm.transforms )
	
		if ( !DataFolderExists( nm.prefixFolder ) )
			return NM2ErrorStr( 30, "prefixFolder", nm.prefixFolder )
		endif
	
		numChannels = NumVarOrDefault( nm.prefixFolder + "NumChannels", 0 )
		
		if ( nm.chanNum >= numChannels )
			return NM2ErrorStr( 10, "chanNum", num2istr( nm.chanNum ) )
		endif
		
		if ( !NMChanTransformExists( channel = nm.chanNum , prefixFolder = nm.prefixFolder ) )
			nm.transforms = 0
		endif
		
		if ( nm.transforms )
			NMParamVarAdd( "transforms", nm.transforms, nm )
		endif
		
	endif
	
	for ( wcnt = 0 ; wcnt < numWaves; wcnt += 1 )
	
		wName = StringFromList( wcnt, nm.wList )
		
		infoStr = WaveInfo( $wName, 0 )
		
		if ( NumberByKey( "NUMTYPE", infoStr ) == 2 )
			precision = 2 // 32-bit (single precision) floating point
		endif
		
	endfor
	
	Make /D/O/N=( points ) $nm.folder + "U_Avg" = 0
	Make /D/O/N=( points ) $nm.folder + "U_Sdv" = 0
	Make /D/O/N=( points ) $nm.folder + "U_Sum" = 0
	Make /D/O/N=( points ) $nm.folder + "U_SumSqr" = 0
	Make /D/O/N=( points ) $nm.folder + "U_Pnts" = 0
	Make /D/O/N=0 $nm.folder + "U_Xwave" = 0
	Make /D/O/N=( points, 0 ) $nm.folder + "U_2Dmatrix"
	
	Wave s.avg = $nm.folder + "U_Avg"
	Wave s.stdv = $nm.folder + "U_Sdv"
	Wave s.sums = $nm.folder + "U_Sum"
	Wave s.sumsqrs = $nm.folder + "U_SumSqr"
	Wave s.count = $nm.folder + "U_Pnts"
	Wave s.xWave = $nm.folder + "U_Xwave"
	Wave s.matrix = $nm.folder + "U_2Dmatrix"
	
	SetScale /P x lftx, dx, s.avg, s.stdv, s.sums, s.sumsqrs, s.count, s.matrix
	
	if ( ( strlen( nm.xWave ) > 0 ) && ( points < numpnts( $nm.folder + nm.xWave ) ) )
	
		Redimension /N=( points ) s.xWave
		SetScale /P x 0, 1, s.xWave
		
		Wave xtemp = $nm.folder + nm.xWave
		
		for ( pcnt = 0 ; pcnt < points ; pcnt += 1 )
			s.xWave[ pcnt ] = xtemp[ pcnt + pbgn ]
		endfor
		
	endif

	for ( wcnt = 0 ; wcnt < numWaves; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Computing Matrix Stats..." ) == 1 )
			error = 1
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		if ( nm.transforms )
		
			if ( xflag )
				returnVal = ChanWaveMake( nm.chanNum, nm.folder + wName, tName2, prefixFolder = nm.prefixFolder, xWave = nm.folder + nm.xWave )
			else
				returnVal = ChanWaveMake( nm.chanNum, nm.folder + wName, tName2, prefixFolder = nm.prefixFolder, xWave = "" )
			endif
			
			if ( returnVal < 0 )
				continue
			endif
			
			tName = tName2
			
		else
		
			tName = nm.folder + wName
			
		endif
		
		if ( !xflag )
			pbgn = x2pnt( $tName, lftx )
			pend = x2pnt( $tName, rghtx )
			pbgn = max( pbgn, 0 )
			pend = min( pend, numpnts( $tName ) - 1 )
		endif
		
		Duplicate /O/R=[ pbgn, pend ] $tName $tName1
		
		if ( !xflag )

			dx2 = deltax( $tName1 )
			ipnts = floor( ( leftx( $tName1 ) - lftx ) / dx2 )
			
			if ( ipnts >= 1 )
			
				InsertPoints 0, ipnts, $tName1
				
				Wave wtemp = $tName1
				
				wtemp[ 0, ipnts - 1 ] = NaN
				
				SetScale /P x lftx, dx2, $tName1
				
			endif
			
			ipnts = floor( ( rightx( $tName1 ) - rghtx ) / dx2 )
			
			if ( ipnts <= -1 ) // lengthen
			
				ibgn = numpnts( $tName1 )
				ipnts = numpnts( $tName1 ) + abs( ipnts )
				
				Redimension /N=( ipnts ) $tName1
				
				Wave wtemp = $tName1
				
				wtemp[ ibgn, ipnts - 1 ] = NaN
				
			elseif ( ipnts >= 1 ) // shorten
			
				ipnts = numpnts( $tName1 ) - ipnts
			
				Redimension /N=( ipnts ) $tName1
			
			endif
			
		endif
		
		if ( interpToSameDX )
			NMInterpolate( tName1, algorithm = 2, xmode = 2, xWaveNew = xWaveNew )
		endif
		
		if ( numpnts( $tName1 ) != points )
		
			ipnts = floor( ( leftx( $tName1 ) - lftx ) / dx )
			
			if ( ipnts >= 1 )
				NM2Error( 90, "encountered wrong number of wave points during loop execution", "" )
				error = 1
				break
			endif
			
			Redimension /N=( points ) $tName1
			
		endif
		
		Duplicate /O s.count $tName3
		
		Wave wtemp = $tName1
		Wave pntsTemp = $tName3
			
		MatrixOp /O pntsTemp = replace( wtemp, 0, 1 ) // to avoid 0/0 division
		MatrixOp /O pntsTemp = pntsTemp / pntsTemp
		
		WaveStats /Q wtemp
		
		if ( V_numNans > 0 )
			foundNANs = 1
		endif
		
		if ( s.ignoreNANs && ( V_numNans > 0 ) )
			MatrixOp /O s.sums = s.sums + replaceNaNs( wtemp, 0 )
			MatrixOp /O s.sumsqrs = s.sumsqrs + replaceNaNs( powR( wtemp, 2 ), 0 )
			MatrixOp /O s.count = s.count + replaceNaNs( pntsTemp, 0 )
		else
			MatrixOp /O s.sums = s.sums + wtemp
			MatrixOp /O s.sumsqrs = s.sumsqrs + powR( wtemp, 2 )
			MatrixOp /O s.count = s.count + pntsTemp
		endif
		
		if ( s.saveMatrix )
			Concatenate { $tName1 }, s.matrix
		endif
		
	endfor
	
	if ( foundNANs )
		NMParamVarAdd( "ignoreNANs", s.ignoreNANs, nm )
	endif
	
	KillWaves /Z $tName1, $tName2, $tName3
	
	if ( error )
	
		NMMatrixStatsStructKill( s )
		
		nm.failureList = nm.wList
		
		if ( history )
			NMLoopHistory( nm )
		endif
		
		SetNMstr( NMDF + "OutputWaveList", "" )
		
		return ""
		
	else
	
		nm.successList = nm.wList
		
	endif
	
	wName = nm.folder + "U_PntsTemp"
	
	Duplicate /O s.count $wName
	
	Wave pntsTemp = $wName
	
	MatrixOp /O pntsTemp = s.count * greater( s.count, minNumOfDataPoints - 1 ) // reject rows with not enough data points
	MatrixOp /O pntsTemp = pntsTemp * ( pntsTemp / pntsTemp ) // converts 0's to NAN's
	
	MatrixOp /O s.avg = s.sums / pntsTemp
	MatrixOp /O s.stdv = sqrt( ( s.sumsqrs - ( ( powR( s.sums, 2 ) ) / pntsTemp ) ) / ( pntsTemp - 1 ) )
	
	KillWaves /Z pntsTemp
	
	if ( precision == 2 )
		zNMMatrixStatsDouble2Single( s.avg )
		zNMMatrixStatsDouble2Single( s.stdv )
		zNMMatrixStatsDouble2Single( s.sums )
		zNMMatrixStatsDouble2Single( s.sumsqrs )
		zNMMatrixStatsDouble2Single( s.count, integer = 1 )
	endif
	
	nm.newList += nm.folder + "U_Avg;"
	nm.newList += nm.folder + "U_Sdv;"
	nm.newList += nm.folder + "U_Sum;"
	nm.newList += nm.folder + "U_SumSqr;"
	nm.newList += nm.folder + "U_Pnts;"
	
	fxn = NMLoopWaveNote( "", nm.paramList )
	
	if ( strlen( nm.xWave ) > 0 )
		
		nm.newList += nm.folder + "U_Xwave;"
		xLabel = "point"
		
		if ( strlen( nm.xLabel ) > 0 )
			yLabel = nm.xLabel
		else
			yLabel = NMNoteLabel( "x", nm.xWave, "", folder = nm.folder )
		endif
		
		NMNoteType( nm.folder + "U_Xwave", "NMXscale", xLabel, yLabel, fxn )
	
	else
	
		if ( strlen( nm.xLabel ) > 0 )
			xLabel = nm.xLabel
		else
			xLabel = NMNoteLabel( "x", nm.wList, "", folder = nm.folder )
		endif
	
	endif
	
	if ( strlen( nm.yLabel ) > 0 )
		yLabel = nm.yLabel
	else
		yLabel = NMNoteLabel( "y", nm.wList, "", folder = nm.folder )
	endif
	
	NMNoteType( nm.folder + "U_Avg", "NMAvg", xLabel, yLabel, fxn )
	NMNoteType( nm.folder + "U_Sdv", "NMSdv", xLabel, yLabel, fxn )
	NMNoteType( nm.folder + "U_Sum", "NMSum", xLabel, yLabel, fxn )
	NMNoteType( nm.folder + "U_SumSqr", "NMSumSqr", xLabel, yLabel + "*" + yLabel, fxn )
	NMNoteType( nm.folder + "U_Pnts", "NMPnts", xLabel, "count", fxn )
	
	Note s.avg, "Input Waves:" + num2istr( numWaves )
	Note s.stdv, "Input Waves:" + num2istr( numWaves )
	Note s.sums, "Input Waves:" + num2istr( numWaves )
	Note s.sumsqrs, "Input Waves:" + num2istr( numWaves )
	Note s.count, "Input Waves:" + num2istr( numWaves )
	
	oList = NMUtilityWaveListShort( nm.wList )
	
	Note s.avg, "WaveList:" + oList
	Note s.stdv, "WaveList:" + oList
	Note s.sums, "WaveList:" + oList
	Note s.sumsqrs, "WaveList:" + oList
	Note s.count, "WaveList:" + oList
	
	if ( s.saveMatrix )
		nm.newList += nm.folder + "U_2Dmatrix;"
		NMNoteType( nm.folder + "U_2Dmatrix", "NM2Dwave", xLabel, yLabel, fxn )
		Note s.matrix, "WaveList:" + oList
	else
		KillWaves /Z $nm.folder + "U_2Dmatrix"
	endif
	
	if ( numpnts( $nm.folder + "U_Xwave" ) == 0 )
		KillWaves /Z $nm.folder + "U_Xwave"
	endif
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm, includeOutputs = 0 )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.newList )
	
	return nm.newList

End // NMMatrixStats2

//****************************************************************
//****************************************************************

Static Function zNMMatrixStatsSum( s, wName )
	STRUCT NMMatrixStatsStruct &s
	String wName
	
	String wName2 = NameOfWave( s.count ) + "Temp"
	
	Duplicate /O s.count $wName2
	
	Wave wtemp = $wName
	Wave pntsTemp = $wName2
		
	MatrixOp /O pntsTemp = replace( wtemp, 0, 1 ) // to avoid 0/0 division
	MatrixOp /O pntsTemp = pntsTemp / pntsTemp
	
	if ( s.ignoreNANs )
		MatrixOp /O s.sums = s.sums + replaceNaNs( wtemp, 0 )
		MatrixOp /O s.sumsqrs = s.sumsqrs + replaceNaNs( powR( wtemp, 2 ), 0 )
		MatrixOp /O s.count = s.count + replaceNaNs( pntsTemp, 0 )
	else
		MatrixOp /O s.sums = s.sums + wtemp
		MatrixOp /O s.sumsqrs = s.sumsqrs + powR( wtemp, 2 )
		MatrixOp /O s.count = s.count + pntsTemp
	endif
	
	KillWaves /Z pntsTemp
	
	return 0
	
End // zNMMatrixStatsSum

//****************************************************************
//****************************************************************

Static Function zNMMatrixStatsDouble2Single( wave2 [ integer ] )
	Wave wave2 // double precision wave
	Variable integer
	
	Variable lftx = leftx( wave2 )
	Variable dx = deltax( wave2 )
	
	if ( integer )
	
		Make /I/U/O/N=( numpnts( wave2 ) ) U_WaveInteger
		
		Wave wtemp = U_WaveInteger
		
	else
	
		Make /O/N=( numpnts( wave2 ) ) U_WaveSingleFloat
		
		Wave wtemp = U_WaveSingleFloat
		
	endif
		
	wtemp = wave2
	
	Duplicate /O wtemp, wave2
	
	KillWaves /Z wtemp
	
	SetScale /P x lftx, dx, wave2
	
End // zNMMatrixStatsDouble2Single

//****************************************************************
//****************************************************************

Function /S NMTTest( wList [ folder, wName, meanValue, sigLevel, DFM, PAIR, TAIL, subfolder, outputPrefix, fullPath, table, windowName, windowTitle ] )
	String wList, folder // see description at top
	
	String wName
	Variable meanValue
	Variable sigLevel // significance level (default val = 0.05)
	Variable DFM // see StatsTTest
	Variable PAIR // input waves are pairs ( 0 ) no ( 1 ) yes
	Variable TAIL // see StatsTTest
	
	String subfolder // subfolder name where output table waves are created, nothing for no subfolder, or "_default_" for auto name generation
	String outputPrefix // prefix name for table waves, default "W_"
	Variable fullPath // table wave of wave names ( 0 ) just wave name ( 1 ) full-path wave name
	
	Variable table // ( 0 ) no output table ( 1 ) save results to a table
	String windowName, windowTitle
	
	Variable numWaves
	String fName
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( NMParamsInit( folder, wList, nm ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( sigLevel ) )
		sigLevel = 0.05
	elseif ( sigLevel <= 0 )
		return NM2ErrorStr( 10, "sigLevel", num2str( sigLevel ) )
	endif
	
	if ( ParamIsDefault( DFM ) )
		DFM = 0
	elseif ( ( DFM != 1 ) && ( DFM != 2 ) )
		return NM2ErrorStr( 10, "DFM", num2str( DFM ) )
	endif
	
	if ( ParamIsDefault( TAIL ) )
		TAIL = 4
	elseif ( ( TAIL != 1 ) && ( TAIL != 2 ) )
		return NM2ErrorStr( 10, "TAIL", num2str( TAIL ) )
	endif
	
	if ( ParamIsDefault( subfolder ) )
		subfolder = "_default_"
	endif
	
	if ( ParamIsDefault( outputPrefix ) )
		outputPrefix = "W_"
	endif
	
	if ( ParamIsDefault( table ) )
		table = 1
	endif
	
	if ( table )
	
		if ( ParamIsDefault( windowName ) || ( strlen( windowName ) == 0 ) )
			windowName = UniqueName( "NM_WaveStatsTable", 7, 0 )
		endif
		
		if ( ParamIsDefault( windowTitle ) )
			fName = NMChild( nm.folder )
			numWaves = ItemsInList( nm.wList )
			windowTitle = "t-test : " + fName + " : n = " + num2istr( numWaves )
		endif
	
	else
	
		windowName = ""
		windowTitle = ""
	
	endif
	
	if ( ParamIsDefault( wName ) )
	
		if ( ParamIsDefault( meanValue ) )
			return ""
		else
			if ( numtype( meanValue ) != 0 )
				return NM2ErrorStr( 10, "meanValue", num2str( meanValue ) )
			endif
		endif
		
		return NMTTest2( nm, meanValue = meanValue, sigLevel = sigLevel, DFM = DFM, PAIR = PAIR, TAIL = TAIL, subfolder = subfolder, outputPrefix = outputPrefix, fullPath = fullPath, table = table )
		
	else
	
		if ( !WaveExists( $wName ) )
			return NM2ErrorStr( 1, "wName", wName )
		endif
	
		return NMTTest2( nm, wName = wName, sigLevel = sigLevel, DFM = DFM, PAIR = PAIR, TAIL = TAIL, subfolder = subfolder, outputPrefix = outputPrefix, fullPath = fullPath, table = table )
		
	endif

End // NMTTest

//****************************************************************
//****************************************************************

Function /S NMTTest2( nm [ wName, meanValue, sigLevel, DFM, PAIR, TAIL, subfolder, outputPrefix, fullPath, table, windowName, windowTitle, history ] )
	STRUCT NMParams &nm // uses nm.folder, nm.wList
	
	String wName // wave for t-test comparison to wLIst, or specifiy meanValue
	Variable meanValue // mean value for t-test comparison to wLIst, or specifiy wName
	Variable sigLevel // significance level (default val = 0.05)
	Variable DFM // see StatsTTest
	Variable PAIR // input waves are pairs ( 0 ) no ( 1 ) yes
	Variable TAIL // see StatsTTest
	
	String subfolder // subfolder name where output table waves are created, nothing for no subfolder, or "_default_" for auto name generation
	String outputPrefix // prefix name for table waves, default "W_"
	Variable fullPath // table wave of wave names ( 0 ) just wave name ( 1 ) full-path wave name
	
	Variable table // display result waves in a table ( 0 ) no ( 1 ) yes
	String windowName, windowTitle
	
	Variable history
	
	Variable wcnt, numWaves, method = 1
	String wName2, fName, xLabel, yLabel, xLabel2, fxn
	String waveOfWaveNames
	
	STRUCT Rect w
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	NMOutputListsReset()
	
	if ( ParamIsDefault( wName ) )
	
		if ( ParamIsDefault( meanValue ) )
			return ""
		else
			if ( numtype( meanValue ) != 0 )
				return NM2ErrorStr( 10, "meanValue", num2str( meanValue ) )
			endif
		endif
		
		method = 2
		
	else
	
		if ( !WaveExists( $wName ) )
			return NM2ErrorStr( 1, "wName", wName )
		endif
		
		Wave wtemp1 = $wName
		
	endif
	
	if ( ParamIsDefault( sigLevel ) )
		sigLevel = 0.05
	elseif ( sigLevel <= 0 )
		return NM2ErrorStr( 10, "sigLevel", num2str( sigLevel ) )
	endif
	
	if ( ParamIsDefault( DFM ) )
		DFM = 0
	elseif ( ( DFM != 1 ) && ( DFM != 2 ) )
		return NM2ErrorStr( 10, "DFM", num2str( DFM ) )
	endif
	
	if ( ParamIsDefault( TAIL ) )
		TAIL = 4
	elseif ( ( TAIL != 1 ) && ( TAIL != 2 ) )
		return NM2ErrorStr( 10, "TAIL", num2str( TAIL ) )
	endif
	
	if ( ParamIsDefault( subfolder ) )
		subfolder = nm.folder
	elseif ( StringMatch( subfolder, "_default_" ) )
		subfolder = UniqueName( "TTest", 11, 0 )
	endif
	
	if ( ParamIsDefault( outputPrefix ) )
		outputPrefix = "W_"
	endif
	
	if ( ParamIsDefault( table ) )
		table = 1
	endif
	
	if ( table )
	
		if ( ParamIsDefault( windowName ) || ( strlen( windowName ) == 0 ) )
			windowName = UniqueName( "NM_WaveStatsTable", 7, 0 )
		endif
		
		if ( ParamIsDefault( windowTitle ) )
			fName = NMChild( nm.folder )
			numWaves = ItemsInList( nm.wList )
			windowTitle = "Wave Stats : " + fName + " : n = " + num2istr( numWaves )
		endif
		
		NMWinCascadeRect( w )
	
		DoWindow /K $windowName
		Edit /K=(NMK())/N=$windowName/W=(w.left,w.top,w.right,w.bottom) as windowTitle
		ModifyTable /W=$windowName title( Point )="Wave"
		
		nm.windowList = windowName
	
	endif
	
	if ( strlen( nm.xLabel ) > 0 )
		xLabel = nm.xLabel
	else
		xLabel = NMNoteLabel( "x", nm.wList, "", folder = nm.folder )
	endif
	
	if ( strlen( nm.yLabel ) > 0 )
		yLabel = nm.yLabel
	else
		yLabel = NMNoteLabel( "y", nm.wList, "", folder = nm.folder )
	endif
	
	xLabel2 = "Wave #"
	
	fxn = NMLoopWaveNote( "", nm.paramList )

	waveOfWaveNames = NMTTest2MakeWave( subfolder, outputPrefix + "name", numWaves, windowName, fxn, xLabel2, "wave names", "" )
	nm.newList += waveOfWaveNames + ";"
	Wave /T W_names = $waveOfWaveNames
	
	wName2 = NMTTest2MakeWave( subfolder, outputPrefix + "Pnts", numWaves, windowName, fxn, xLabel2, yLabel, waveOfWaveNames )
	nm.newList += wName2 + ";"
	Wave W_sum = $wName2
	
	wName2 = NMTTest2MakeWave( subfolder, outputPrefix + "DF", numWaves, windowName, fxn, xLabel2, yLabel, waveOfWaveNames )
	nm.newList += wName2 + ";"
	Wave W_avg = $wName2
	
	wName2 = NMTTest2MakeWave( subfolder, outputPrefix + "mean", numWaves, windowName, fxn, xLabel2, yLabel, waveOfWaveNames )
	nm.newList += wName2 + ";"
	Wave W_sdev = $wName2
	
	wName2 = NMTTest2MakeWave( subfolder, outputPrefix + "sdev", numWaves, windowName, fxn, xLabel2, yLabel, waveOfWaveNames )
	nm.newList += wName2 + ";"
	Wave W_sem = $wName2
	
	numWaves = ItemsInList( nm.wList )
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Computing T-test..." ) == 1 )
			break // cancel
		endif
	
		wName2 = StringFromList( wcnt, nm.wList )
		
		Wave wtemp2 = $nm.folder + wName2
		
		if ( PAIR )
		
			if ( method == 1 )
				StatsTTest /ALPH=( sigLevel ) /DFM=( DFM ) /TAIL=( TAIL ) /Q wtemp1, wtemp2
			elseif ( method == 2 )
				StatsTTest /ALPH=( sigLevel ) /DFM=( DFM ) /MEAN=( meanValue ) /TAIL=( TAIL ) /Q wtemp2
			endif
		
		else
		
			if ( method == 1 )
				StatsTTest /ALPH=( sigLevel ) /DFM=( DFM ) /PAIR /TAIL=( TAIL ) /Q wtemp1, wtemp2
			elseif ( method == 2 )
				StatsTTest /ALPH=( sigLevel ) /DFM=( DFM ) /MEAN=( meanValue ) /PAIR /TAIL=( TAIL ) /Q wtemp2
			endif

		endif
		
		NMLoopWaveNote( nm.folder + wName2, nm.paramList )
		
		nm.successList += wName2 + ";"
		
	endfor

	NMParamsComputeFailures( nm )
	
	SetNMstr( NMDF + "OutputWaveList", nm.newList )
	SetNMstr( NMDF + "OutputWinList", nm.windowList )
	
	if ( history )
		NMLoopHistory( nm )
	endif

	return nm.newList
	
End // NMTTest2

//****************************************************************
//****************************************************************

Static Function /S NMTTest2MakeWave( folder, wName, npnts, tableName, fxn, xLabel, ylabel, waveOfWaveNames )
	String folder
	String wName
	Variable npnts
	String tableName
	String fxn
	String xLabel, yLabel
	String waveOfWaveNames
	
	if ( strlen( folder ) > 0 )
		if ( strsearch( folder, ":", 0 ) == -1 )
			folder = GetDataFolder( 1 ) + folder + ":"
		endif
	endif
	
	if ( !DataFolderExists( folder ) )
		NewDataFolder $RemoveEnding( folder, ":" )
	endif
	
	if ( strsearch( wName, "name", 0 ) > 0 )
		Make /O/N=( npnts )/T $folder + wName = ""
	else
		Make /O/N=( npnts ) $folder + wName = NaN
	endif
	
	NMNoteType( folder + wName, "NMTTest", xLabel, yLabel, "Func:" + fxn )
	
	if ( strlen( waveOfWaveNames ) > 0 )
		Note $folder + wName, "Wave Names:" + waveOfWaveNames
	endif
	
	if ( ( strlen( tableName ) > 0 ) && ( WinType( tableName ) == 2 ) )
		AppendToTable /W=$tableName $folder + wName
	endif
	
	return folder + wName
	
End // NMTTest2MakeWave

//****************************************************************
//****************************************************************

Structure NMHistrogramBins

	Variable numBins, binWidth, binStart

EndStructure

//****************************************************************
//****************************************************************

Function NMHistrogramBinsAuto( nm, h [ all, paddingBins, numBinsMin, xbgn, xend ] )
	STRUCT NMParams &nm // uses nm.folder, nm.wList // nm.transforms uses nm.chanNum and nm.prefixFolder
	STRUCT NMHistrogramBins &h
	Variable all // compute values for numBins, binWidth and binStart
	Variable paddingBins // add extra bins to each side of histogram
	Variable numBinsMin // minimum number of bins
	Variable xbgn, xend
	
	Variable npnts, minY = inf, maxY = -inf, wcnt, numWaves, returnVal
	
	String wName, tName, tName2
	
	if ( NMParamsError( nm ) != 0 )
		return -1
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	if ( numWaves == 0 )
		return 0
	endif
	
	if ( ParamIsDefault( numBinsMin ) )
		numBinsMin = 1
	endif
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	tName2 = nm.folder + "U_WaveTemp"
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		wName = StringFromList( wcnt, nm.wList )
		
		if ( nm.transforms )
		
			if ( strlen( nm.xWave ) > 0 )
				returnVal = ChanWaveMake( nm.chanNum, nm.folder + wName, tName2, prefixFolder = nm.prefixFolder, xWave = nm.folder + nm.xWave )
			else
				returnVal = ChanWaveMake( nm.chanNum, nm.folder + wName, tName2, prefixFolder = nm.prefixFolder, xWave = "" )
			endif
			
			if ( returnVal < 0 )
				return -1
			endif
			
			tName = tName2
			
		else
		
			tName = nm.folder + wName
			
		endif
		
		WaveStats /Q/R=( xbgn, xend ) $tName
		
		npnts = max( npnts, V_npnts )
		minY = min( minY, V_min )
		maxY = max( maxY, V_max )
		
	endfor
	
	KillWaves /Z $tName2
	
	if ( all || ( numtype( h.numBins ) > 0 ) || ( h.numBins <= 0 ) )
	
		if ( numtype( npnts ) == 0 )
			h.numBins = 1 + ( log( npnts ) / log( 2 ) ) // 1+log2(N) ( see Histogram /B=3 )
		else
			h.numBins = numBinsMin
		endif
		
	endif
	
	h.numBins = max( h.numBins, numBinsMin )
	h.numBins = ceil( h.numBins )
	
	if ( all || ( numtype( h.binWidth ) > 0 ) || ( h.binWidth <= 0 ) )
		h.binWidth = abs( ( maxY - minY ) ) / h.numBins
		h.binWidth = ceil( 100 * h.binWidth ) / 100
	endif
	
	if ( all || ( numtype( h.binStart ) > 0 ) )
		h.binStart = h.binWidth * ceil( minY / h.binWidth )
	endif
	
	if ( ( numtype( paddingBins ) == 0 ) && ( paddingBins > 0 ) )
		h.numBins += 2 * paddingBins
		h.binStart -= paddingBins * h.binWidth
	endif
	
	return 0

End // NMHistrogramBinsAuto

//****************************************************************
//****************************************************************

Function /S NMHistogram2( nm [ binStart, binWidth, numBins, xbgn, xend, optionStr, newPrefix, overwrite, history ] )
	STRUCT NMParams &nm // uses nm.folder, nm.wList // nm.transforms uses nm.chanNum and nm.prefixFolder
	
	Variable binStart, binWidth, numBins // pass nothing for auto bin computation
	Variable xbgn, xend
	String optionStr // e.g. "/C/P/Cum" ( see Igor Histogram Help ), or "/F" for frequency
	String newPrefix // wave prefix for output histograms
	Variable overwrite, history
	
	Variable wcnt, numWaves, numChannels
	Variable cumulative, incomplete, returnVal, normalize, dx
	String wName, optionStr2, fxn, fxn2
	String xLabel, yLabel, histoName, tName, tName2
	String thisFxn = GetRTStackInfo( 1 )
	
	Variable paddingBins = NMVarGet( "HistogramPaddingBins" )
	
	STRUCT NMHistrogramBins h
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	tName2 = nm.folder + "U_WaveTemp"
	
	SetNMstr( NMDF + "OutputWaveList", "" )
	
	numWaves = ItemsInList( nm.wList )
	
	if ( ParamIsDefault( binStart ) || ( numtype( binStart ) > 0 ) )
		binStart = NaN
	endif
	
	if ( ParamIsDefault( binWidth ) || ( numtype( binWidth ) > 0 ) )
		binWidth = NaN
	elseif ( binWidth <= 0 )
		return NM2ErrorStr( 10, "binWidth", num2str( binWidth ) )
	endif
		
	if ( ParamIsDefault( numBins ) || ( numtype( numBins ) > 0 ) )
		numBins = NaN
	elseif ( numBins <= 0 )
		return NM2ErrorStr( 10, "numBins", num2str( numBins ) )
	endif
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( ParamIsDefault( optionStr ) )
		optionStr = ""
	endif
	
	if ( ParamIsDefault( newPrefix ) || ( strlen( newPrefix ) == 0 ) )
		return NM2ErrorStr( 21, "newPrefix", "" )
	endif
	
	NMParamStrAdd( "prefix", newPrefix, nm )
	
	if ( strsearch( optionStr, "/P", 0 ) >= 0 )
		yLabel = "Probability"
		normalize = 1
	elseif ( strsearch( optionStr, "/F", 0 ) >= 0 )
		yLabel = "Frequency"
		normalize = 2
	else
		yLabel = "Count"
		normalize = 0
	endif
	
	if ( strsearch( optionStr, "/Cum", 0 ) >= 0 )
		cumulative = 1
	endif
	
	if ( nm.transforms )
	
		if ( !DataFolderExists( nm.prefixFolder ) )
			return NM2ErrorStr( 30, "prefixFolder", nm.prefixFolder )
		endif
	
		numChannels = NumVarOrDefault( nm.prefixFolder + "NumChannels", 0 )
		
		if ( nm.chanNum >= numChannels )
			return NM2ErrorStr( 10, "chanNum", num2istr( nm.chanNum ) )
		endif
		
		if ( !NMChanTransformExists( channel = nm.chanNum , prefixFolder = nm.prefixFolder ) )
			nm.transforms = 0 // found no transforms
		endif
		
		if ( nm.transforms )
			NMParamVarAdd( "transforms", nm.transforms, nm )
		endif
		
	endif
	
	if ( numtype( binStart * binWidth * numBins ) == 0 )
	
		optionStr = "/B={" + num2str( binStart ) + "," + num2str( binWidth ) + "," + num2str( numBins ) + "}" + optionStr
		
	else
		
		if ( NMHistrogramBinsAuto( nm, h, all = 1, paddingBins = paddingBins, numBinsMin = 10 ) < 0 )
			return ""
		endif
		
		numBins = h.numBins
		binWidth = h.binWidth
		binStart = h.binStart
		
		if ( numtype( binStart * binWidth * numBins ) > 0 )
			return NM2ErrorStr( 10, "binStart * binWidth * numBins", num2str( NaN ) )
		endif
		
		optionStr = "/B={" + num2str( binStart ) + "," + num2str( binWidth ) + "," + num2str( numBins ) + "}" + optionStr
		
		//NMHistory( "binStart = " + num2str( binStart ) + ", binWidth = " + num2str( binWidth ) + ", numBins = " + num2str( numBins ) )
	
	endif
	
	if ( ( numtype( xbgn ) == 0 ) || ( numtype ( xend ) == 0 ) )
		optionStr += "/R=(" + num2str( xbgn ) + "," + num2str( xend ) + ")"
	endif
	
	optionStr2 = optionStr
	optionStr2 = ReplaceString( "/F", optionStr2, "/P" ) // for frequency, compute probability and multiply by binwidth
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Computing Wave Histograms..." ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		Wavestats /Q/Z $nm.folder + wName
	
		if ( V_npnts < 1 )
			continue
		endif
		
		histoName = nm.folder + newPrefix + wName
		
		if ( !overwrite && WaveExists( $histoName ) )
			continue
		endif
		
		Duplicate /O $( nm.folder + wName ) $histoName
		
		Wave wtemp = $histoName
		
		wtemp = NaN
		
		if ( nm.transforms )
		
			if ( strlen( nm.xWave ) > 0 )
				returnVal = ChanWaveMake( nm.chanNum, nm.folder + wName, tName2, prefixFolder = nm.prefixFolder, xWave = nm.folder + nm.xWave )
			else
				returnVal = ChanWaveMake( nm.chanNum, nm.folder + wName, tName2, prefixFolder = nm.prefixFolder, xWave = "" )
			endif
			
			if ( returnVal < 0 )
				continue
			endif
			
			tName = tName2
			
		else
		
			tName = nm.folder + wName
			
		endif
		
		fxn = "Histogram " + optionStr2 + " " + tName + ", " + histoName
		fxn2 = "Histogram " + optionStr + " " + wName + ", " + NMChild( histoName ) // short notation for notes
		
		Execute /Q/Z fxn
		
		if ( V_flag != 0 )
			continue
		endif
		
		//NMHistory( fxn )
		
		if ( !WaveExists( $histoName ) )
			continue
		endif
		
		nm.successList += wName + ";"
		nm.newList += histoName + ";"
		
		xLabel = NMNoteLabel( "y", nm.folder + wName, "" )
		
		if ( ( strlen( xLabel ) == 0 ) && ( strlen( nm.yLabel ) > 0 ) )
			xLabel = nm.yLabel
		endif
		
		NMNoteStrReplace( histoName, "xLabel", xLabel )
		NMNoteStrReplace( histoName, "yLabel", yLabel )
		
		Note $histoName, fxn2
		
		if ( cumulative )
		
			WaveStats /Q $tName
		
			if ( ( V_min < leftx( $histoName ) ) || ( V_max < rightx( $histoName ) ) )
				incomplete = 1
			endif
		
		elseif ( normalize == 2 )
		
			// convert probability to frequency
		
			Wave htemp = $histoName
			
			dx = deltax( htemp )
			
			if ( dx != 1 )
				htemp *= dx
			endif
		
		endif
		
	endfor
	
	nm.fxn = "NMHistogram " + optionStr
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.newList )
	
	if ( cumulative && incomplete )
		NMHistory( thisFxn + " Warning: cumulative histogram bin range did not include entire range of input data." )
	endif
	
	KillWaves /Z $tName2
	
	return nm.newList
	
End // NMHistogram2

//****************************************************************
//****************************************************************

Function /S NMInequality2( nm [ xbgn, xend, greaterThan, lessThan, binaryOutput, newPrefix, overwrite, history ] )
	STRUCT NMParams &nm // uses nm.folder, nm.wList // nm.transforms uses nm.chanNum and nm.prefixFolder
	Variable xbgn, xend
	Variable greaterThan // test if y-value is greater than this value
	Variable lessThan // test if y-value is less than this value
	Variable binaryOutput // ( 0 ) output wave will contain NaN for false or corresponding input wave value for true ( 1 ) output wave will contain '0' for false or '1' for true
	String newPrefix
	Variable overwrite, history
	
	Variable wcnt, numWaves, numChannels, alert, pbgn, pend, xflag, returnVal
	String wName, newName, tName, tName2, fxn2, fxn = "NMInequality"
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	tName2 = nm.folder + "U_WaveTemp"
	
	SetNMstr( NMDF + "OutputWaveList", "" )
	
	numWaves = ItemsInList( nm.wList )
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( ( numtype( xbgn ) == 0 ) || ( numtype( xend ) == 0 ) )
		NMParamVarAdd( "xbgn", xbgn, nm )
		NMParamVarAdd( "xend", xend, nm )
	endif
	
	if ( strlen( nm.xWave ) > 0 )
		pbgn = NMX2Pnt( nm.folder + nm.xWave, xbgn )
		pend = NMX2Pnt( nm.folder + nm.xWave, xend )
		NMParamStrAdd( "xwave", nm.xWave, nm )
		xflag = 1
	endif
	
	if ( ParamIsDefault( greaterThan ) )
		greaterThan = NaN
	endif
	
	if ( ParamIsDefault( lessThan ) )
		lessThan = NaN
	endif
	
	if ( ( numtype( greaterThan ) > 0 ) && ( numtype( lessThan ) > 0 ) )
		return "" // nothing to do
	endif 
	
	if ( ParamIsDefault( binaryOutput ) )
		binaryOutput = 1
	endif
	
	if ( ParamIsDefault( newPrefix ) || strlen( newPrefix ) == 0 )
		return NM2ErrorStr( 21, "newPrefix", "" )
	endif
	
	NMParamStrAdd( "prefix", newPrefix, nm )
	
	if ( nm.transforms )
	
		if ( !DataFolderExists( nm.prefixFolder ) )
			return NM2ErrorStr( 30, "prefixFolder", nm.prefixFolder )
		endif
	
		numChannels = NumVarOrDefault( nm.prefixFolder + "NumChannels", 0 )
		
		if ( nm.chanNum >= numChannels )
			return NM2ErrorStr( 10, "chanNum", num2istr( nm.chanNum ) )
		endif
		
		if ( !NMChanTransformExists( channel = nm.chanNum , prefixFolder = nm.prefixFolder ) )
			nm.transforms = 0
		endif
		
		if ( nm.transforms )
			NMParamVarAdd( "transforms", nm.transforms, nm )
		endif
		
	endif
	
	fxn2 = NMInequalityFxn( greaterThan, lessThan )
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Computing Inequalities..." ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		newName = nm.folder + newPrefix + wName
		
		if ( StringMatch( nm.folder + wName, newName ) )
			continue // cannot duplicate over self
		endif
		
		if ( !overwrite && WaveExists( $newName ) )
			continue
		endif
		
		if ( nm.transforms )
		
			if ( xflag )
				returnVal = ChanWaveMake( nm.chanNum, nm.folder + wName, tName2, prefixFolder = nm.prefixFolder, xWave = nm.folder + nm.xWave )
			else
				returnVal = ChanWaveMake( nm.chanNum, nm.folder + wName, tName2, prefixFolder = nm.prefixFolder, xWave = "" )
			endif
			
			if ( returnVal < 0 )
				continue
			endif
			
			tName = tName2
			
		else
		
			tName = nm.folder + wName
			
		endif
		
		Wave wtemp = $tName
		
		if ( !xflag )
			pbgn = x2pnt( wtemp, xbgn )
			pend = x2pnt( wtemp, xend )
			pbgn = max( pbgn, 0 )
			pend = min( pend, numpnts( wtemp ) - 1 )
		endif
		
		Duplicate /O/R=[ pbgn, pend ] wtemp $newName
		
		Wave otemp = $newName
		
		otemp = NMInequality( wtemp, greaterThan = greaterThan, lessThan = lessThan, binaryOutput = binaryOutput )
		
		if ( binaryOutput )
			NMNoteStrReplace( newName, "yLabel", "True/False" )
		endif
		
		NMLoopWaveNote( newName, fxn2 + ";" + nm.paramList )
		
		nm.successList += wName + ";"
		nm.newList += newName + ";"
		
	endfor
	
	//nm.fxn = fxn + " " + fxn2
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.newList )
	
	KillWaves /Z $tName2
	
	return nm.newList
	
End // NMInequality2

//****************************************************************
//****************************************************************
//
//	X-axis Functions
//
//****************************************************************
//****************************************************************

Function NMXaxisStatsTest()

	Variable same = 1

	String wList = "RecordA0;RecordA1;RecordA2;RecordA3;"
	String folder = ""
	
	if ( same )
	
		Make /O/N=50 RecordA0, RecordA1, RecordA2, RecordA3
		Setscale /P x -20, 0.1, RecordA0, RecordA1, RecordA2, RecordA3
	
	else
	
		Make /O/N=50 RecordA0
		Make /O/N=150 RecordA1
		Make /O/N=200 RecordA2
		Make /O/N=300 RecordA3
	
		Setscale /P x -20, 0.1, RecordA0
		Setscale /P x 0, 0.2, RecordA1
		Setscale /P x 20, 0.3, RecordA2
		Setscale /P x 40, 0.4, RecordA3
	
	endif
	
	STRUCT NMXaxisStruct s
	NMXaxisStructInit( s, wList, folder = folder )
	NMXaxisStats2( s, history = 1 )

End // NMXaxisStatsTest

//****************************************************************
//****************************************************************

Structure NMXaxisStruct

	// inputs
	String wList, folder
	String select

	// outputs
	
	Variable points, minPoints, maxPoints
	Variable leftx, minLeftx, maxLeftx
	Variable rightx, minRightx, maxRightx
	Variable dx, minDX, maxDX
	Variable selectValue, sameXscale
	String successList, failureList, statsList

EndStructure

//****************************************************************
//****************************************************************

Function NMXaxisStructNull( s )
	STRUCT NMXaxisStruct &s
	
	s.wList = ""; s.folder = "", s.select = ""
	s.points = inf; s.minPoints = inf; s.maxPoints = -inf
	s.leftx = inf; s.minLeftx = inf; s.maxLeftx = -inf
	s.rightx = inf; s.minRightx = inf; s.maxRightx = -inf
	s.dx = inf; s.minDX = inf; s.maxDX = -inf
	s.selectValue = NaN; s.sameXscale = NaN
	s.successList = "", s.failureList = "", s.statsList = ""

End // NMXaxisStructNull

//****************************************************************
//****************************************************************

Function NMXaxisStructInit( s, wList [ folder, select ] )
	STRUCT NMXaxisStruct &s
	String wList, folder, select
	
	NMXaxisStructNull( s )
	
	s.wList = wList
	
	if ( !ParamIsDefault( folder ) )
		s.folder = folder
	endif
	
	if ( !ParamIsDefault( select ) )
		s.select = select
	endif

End // NMXaxisStructInit

//****************************************************************
//****************************************************************

Function GetXstats( select, wList [ folder ] )
	String select
	String wList
	String folder
	
	STRUCT NMXaxisStruct s
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	NMXaxisStructInit( s, wList, folder = folder, select = select )
	NMXaxisStats2( s )
	
	return s.selectValue
	
End // GetXstats

//****************************************************************
//****************************************************************

Function /S NMXaxisStats( wList [ folder, select, history ] )
	String wList, folder
	String select
	Variable history
	
	STRUCT NMXaxisStruct s
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( select ) )
		select = ""
	endif
	
	NMXaxisStructInit( s, wList, folder = folder, select = select )
	
	return NMXaxisStats2( s, history = history )
	
End // NMXaxisStats

//****************************************************************
//****************************************************************

Function /S NMXaxisStats2( s [ history ] )
	STRUCT NMXaxisStruct &s
	Variable history
	
	Variable wcnt, points, lftx, rgtx, dx, numWaves = ItemsInList( s.wList )
	Variable computePnts, computeDX, computeLeftx, computeRightx
	String wName
	
	if ( numWaves == 0 )
		return ""
	endif
	
	if ( !DataFolderExists( s.folder ) )
		return NM2ErrorStr( 30, "folder", s.folder )
	endif
	
	strswitch( s.select )
	
		case "npnts":
		case "points":
		case "numPnts":
		case "minPoints":
		case "minNumPnts":
		case "maxPoints":
		case "maxNumPnts":
			computePnts = 1
			break
		
		case "dx":
		case "deltax":
		case "minDX":
		case "minDeltax":
		case "maxDX":
		case "maxDeltax":
			computeDX = 1
			break
		
		case "leftx":
		case "minLeftx":
		case "maxLeftx":
			computeLeftx = 1
			break
			
		case "rightx":
		case "minRightx":
		case "maxRightx":
			computeRightx = 1
			break

		default:
			computePnts = 1
			computeDX = 1
			computeLeftx = 1
			computeRightx = 1
	endswitch
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		wName = StringFromList( wcnt, s.wList )
		wName = StringFromList( 0, wName, "," ) // in case of sub-wavelist
		
		if ( !WaveExists( $s.folder + wName ) )
			continue
		endif
		
		Wave wtemp = $s.folder + wName
		
		if ( computePnts )
			points = numpnts( wtemp )
			s.points = zNMSameValue( s.points, points )
			s.minPoints = min( s.minPoints, points )
			s.maxPoints = max( s.maxPoints, points )
		endif
		
		if ( computeDX )
			dx = deltax( wtemp )
			s.dx = zNMSameValue( s.dx, dx )
			s.minDX = min( s.minDX, dx )
			s.maxDX = max( s.maxDX, dx )
		endif
		
		if ( computeLeftx )
			lftx = leftx( wtemp )
			s.leftx = zNMSameValue( s.leftx, lftx )
			s.minLeftx = min( s.minLeftx, lftx )
			s.maxLeftx = max( s.maxLeftx, lftx )
		endif
		
		if ( computeRightx )
			rgtx = rightx( wtemp )
			s.rightx = zNMSameValue( s.rightx, rgtx )
			s.minRightx = min( s.minRightx, rgtx )
			s.maxRightx = max( s.maxRightx, rgtx )
		endif
		
		s.successList += wName + ";"
		
	endfor
	
	strswitch( s.select )
	
		case "npnts":
		case "points":
		case "numpnts":
			s.selectValue = s.points
			break
		case "minPoints":
		case "minNumPnts":
			s.selectValue = s.minPoints
			break
		case "maxPoints":
		case "maxNumPnts":
			s.selectValue = s.maxPoints
			break
		
		case "dx":
		case "deltax":
			s.selectValue = s.dx
			break
		case "minDX":
		case "minDeltax":
			s.selectValue = s.minDX
			break
		case "maxDX":
		case "maxDeltax":
			s.selectValue = s.maxDX
			break
		
		case "leftx":
			s.selectValue = s.leftx
			break
		case "minLeftx":
			s.selectValue = s.minLeftx
			break
		case "maxLeftx":
			s.selectValue = s.maxLeftx
			break
			
		case "rightx":
			s.selectValue = s.rightx
			break
		case "minRightx":
			s.selectValue = s.minRightx
			break
		case "maxRightx":
			s.selectValue = s.maxRightx
			break
			
		case "sameXscale":
			s.selectValue = s.sameXscale
			break

	endswitch
	
	s.failureList = RemoveFromList( s.successList, s.wList )
	
	if ( computePnts )
		s.statsList += "points=" + num2istr( s.points ) + ";minPoints=" + num2istr( s.minPoints ) + ";maxPoints=" + num2istr( s.maxPoints ) + ";"
	endif
	
	if ( computeDX )
		s.statsList += "dx=" + num2str( s.dx ) + ";minDX=" + num2str( s.minDX ) + ";maxDX=" + num2str( s.maxDX ) + ";"
	endif
	
	if ( computeLeftx )
		s.statsList += "leftx=" + num2str( s.leftx ) + ";minLeftx=" + num2str( s.minLeftx ) + ";maxLeftx=" + num2str( s.maxLeftx ) + ";"
	endif
	
	if ( computeRightx )
		s.statsList += "rightx=" + num2str( s.rightx ) + ";minRightx=" + num2str( s.minRightx ) + ";maxRightx=" + num2str( s.maxRightx ) + ";"
	endif
	
	if ( computePnts && computeDX && computeLeftx )
		s.sameXscale = ( numtype( s.points ) == 0 ) && ( numtype( s.dx ) == 0 ) && ( numtype( s.leftx ) == 0 )
		s.statsList += "sameXscale=" + num2str( s.sameXscale ) + ";"
	endif
	
	if ( history )
		Print s
	endif
	
	if ( strlen( s.select ) > 0 )
		return num2str( s.selectValue )
	else
		return s.statsList
	endif

End // NMXaxisStats2

//****************************************************************
//****************************************************************

Static Function zNMSameValue( v1, v2 )
	Variable v1, v2
	
	if ( numtype( v1 ) == 1 )
		return v2 // this is first value
	endif
	
	if ( abs( v1 - v2 ) < XaxisStatsTolerance )
		return v1
	endif
	
	return NaN
	
End // zNMSameValue

//****************************************************************
//****************************************************************

Function NMWavesHaveSingleXscale( wList )
	String wList
	
	if ( ItemsInList( wList ) <= 0 )
		return 1
	endif
	
	STRUCT NMXaxisStruct s
	NMXaxisStructInit( s, wList )
	NMXaxisStats2( s )
	
	if ( numtype( s.points * s.dx * s.leftx ) == 0 )
		return 1
	else
		return 0
	endif
	
End // NMWavesHaveSingleXscale

//****************************************************************
//****************************************************************
//
//	Functions Not Used
//
//****************************************************************
//****************************************************************

Function /S MeanStdv( xbgn, xend, wList ) // NOT USED
	Variable xbgn, xend
	String wList
	
	Variable wcnt, cnt, avg, stdv
	String wName, successList = ""
	
	if ( numtype( xbgn ) > 0 )
		xbgn = -inf
	endif
	
	if ( numtype( xend ) > 0 )
		xend = inf
	endif
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( NMUtilityWaveTest( wName ) < 0 )
			continue
		endif
		
		WaveStats /Q/R=( xbgn, xend ) $wName
		
		avg += V_avg
		stdv += V_avg * V_avg
		cnt += 1
		
		successList += wName + ";"
		
	endfor
	
	if ( cnt >= 2 )
	
		stdv = sqrt( ( stdv - ( ( avg ^ 2 ) / cnt ) ) / ( cnt - 1 ) )
		avg = avg / cnt
	
	else
	
		stdv = NaN
		avg = NaN
	
	endif
	
	//NMFailureAlert( wList, successList )
	
	return "mean=" + num2str( avg ) + ";stdv=" + num2str( stdv ) + ";count=" + num2istr( cnt )+";"

End // MeanStdv

//****************************************************************
//****************************************************************

Function NMUtilityAlert( fxn, badList ) // NOT USED
	String fxn
	String badList

	if ( ItemsInList( badList ) <= 0 )
		return 0
	endif
	
	badList = NMUtilityWaveListShort( badList )
	
	String alert = fxn + " Alert : the following waves failed function execution : " + badList
	
	NMHistory( alert )
	
End // NMUtilityAlert

//****************************************************************
//****************************************************************

Function /S NMFailureAlert( wList, successList [ functionName, history ] ) // NOT USED
	String wList // list of input waves
	String successList // list of waves that passed thru function successfully
	String functionName
	Variable history
	
	String failureList2, alert
	
	String failureList = RemoveFromList( successList, wList )

	if ( ItemsInList( failureList ) <= 0 )
		return ""
	endif
	
	if ( ParamIsDefault( functionName ) )
	
		functionName = GetRTStackInfo( 2 )
		
		if ( strlen( functionName ) == 0 )
			functionName = "NM"
		endif
		
	endif
	
	if ( ParamIsDefault( history ) )
		history = 1
	endif
	
	alert = functionName + " Alert : the following waves failed function execution : "
	
	failureList2 = NMUtilityWaveListShort( failureList )
	
	if ( strlen( failureList2 ) > 0 )
		alert += failureList2
	else
		alert += failureList
	endif
	
	if ( history )
		NMHistory( alert )
	endif
	
	return alert
	
End // NMFailureAlert

//****************************************************************
//****************************************************************



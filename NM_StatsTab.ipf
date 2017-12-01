#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma hide = 1

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
//	Statistical Analysis Tab
//
//	Set and Get functions:
//
//		NMStatsSet( [ win, fxn, level, levelPos, levelNeg, maxAvgWin, minAvgWin, risePbgn, risePend, decayPcnt, xbgn, xend, bsln, bslnSubtract, filterFxn, filterNum, transform, winSelect, numWindows, folderSelect, waveSelect, allStats2, history ] )
//		NMConfigVarSet( "Stats", varName, value )
//		NMConfigStrSet( "Stats", strVarName, strValue )
//		NMStatsVarGet( varName )
//		NMStatsStrGet( varNameStr )
//
//	Useful Functions:
//
//		NMStatsCompute( [ chanSelectList, waveSelectList, windowList, show, delay, tables, graphs, stats2, history ] )
//		NMStatsPlot( [ folder, wList, xWave, all, onePlot, hide, history ] )
//		NMStatsEdit( [ folder, wList, hide, history ] )
//		NMStatsWaveStats( [ folder, wList, outputSelect, hide, history ] )
//		NMStatsWaveNotes( [ folder, wList, outputSelect, history ] )
//		NMStatsWaveNames( [ folder, fullPath, history ] )
//		NMStatsHistogram( [ folder, wName, binStart, binWidth, numBins, optionStr, noGraph, returnSelect, history ] )
//		NMStatsInequality( [ folder, wName, relationSelect, aValue, sValue, nValue, setName, noGraph, returnSelect, history ] )
//		NMStatsWaveScale( [ folder, waveOfScaleValues, waveOfWaveNames, alg, chanSelect, history ] )
//		NMStatsWaveAlignment( [ folder, waveOfAlignments, waveOfWaveNames, alignAtZero, chanSelect, history ] )
//
//****************************************************************
//****************************************************************

Static Constant NumWindows = 10 // default number of Stats1 windows
Static Constant RiseTimePbgn = 10
Static Constant RiseTimePend = 90
Static Constant DecayTimePercent = 63.2 // = 100 - 36.7879 = 100 * ( 1 - e^-1 )

StrConstant NMStatsDF = "root:Packages:NeuroMatic:Stats:"
StrConstant NMStats2FxnList = "Functions;---;Plot;Edit;Wave Stats;Print Note;Print Name;Histogram;Inequality <>;Stability;Significant Difference;MPFA Stats; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;" // extra at end to create scrollbar
StrConstant NMStats2AllFxnList = "Functions;---;Plot;Edit;Wave Stats;Print Notes;Print Names;"

Static StrConstant StatsFxnList = "Off;Max;Min;Avg;Avg+SDev;Avg+SEM;Median;SDev;SEM;Var;RMS;NumPnts;Area;Sum;PathLength;Slope;Onset;Level;Level+;Level-;MaxAvg;MinAvg;RiseTime+;RTslope+;DecayTime+;FWHM+;RiseTime-;RTslope-;DecayTime-;FWHM-;"
Static StrConstant BslnFxnList = "Max;Min;Avg;Median;SDev;SEM;Var;RMS;Area;Sum;PathLength;Slope;"

Static StrConstant InputWaveList = "AmpSlct;AmpB;AmpE;AmpY;Bflag;BslnSlct;BslnB;BslnE;BslnSubt;RiseBP;RiseEP;DcayP;FilterNum;FilterAlg;Transform;OffsetW;ChanSelect;"
Static StrConstant OutputWaveList = "AmpX;AmpY;BslnX;BslnY;RiseBX;RiseEX;RiseTm;DcayX;DcayT;"

Static StrConstant SELECTED = "_selected_"
Static StrConstant CALCULATED = "_calculated_"
Static StrConstant DEFAULTSUBFOLDER = "_subfolder_"

//****************************************************************
//****************************************************************
//
//	Stats Tab Functions
//
//****************************************************************
//****************************************************************

Function /S NMTabPrefix_Stats()

	return "ST_"

End // NMTabPrefix_Stats

//****************************************************************
//****************************************************************

Function StatsTab( enable )
	Variable enable // ( 0 ) disable ( 1 ) enable tab

	if ( enable )
		CheckNMPackage( "Stats", 1 ) // declare globals if necessary
		StatsChanCheck()
		StatsAmpWinBegin()
		MakeStats( 0 ) // make controls if necessary
	endif
	
	StatsChanControlsEnableAll( enable )
	NMChanGraphUpdate()
	StatsDisplay( -1, enable ) // display/remove stat waves on active channel graph
	
	if ( enable )
		NMStatsAuto()
	endif
	
End // StatsTab

//****************************************************************
//****************************************************************

Function StatsTabKill( what )
	String what
	
	String df = NMStatsDF
	
	strswitch( what )
	
		case "waves":
			return 0
			
		case "folder":
		
			if ( DataFolderExists( df ) )
			
				KillDataFolder $df
				
				if ( DataFolderExists( df ) )
					return -1 // failed to kill
				else
					return 0
				endif
				
			endif
			
			return 0
			
	endswitch
	
	return -1
	
End // StatsTabKill

//****************************************************************
//****************************************************************
//
//		Variables, Strings, Waves and folders
//
//****************************************************************
//****************************************************************

Function NMStatsSet( [ win, fxn, level, levelPos, levelNeg, maxAvgWin, minAvgWin, risePbgn, risePend, decayPcnt, xbgn, xend, bsln, bslnSubtract, filterFxn, filterNum, transform, winSelect, numWindows, folderSelect, waveSelect, allStats2, update, history ] )

	// begin win parameters
	
	Variable win // Stats1 window to change when passing values for fxn, xbgn, xend ... transform ( pass nothing to get currently selected Stats1 window )
	String fxn
	Variable level, levelPos, levelNeg
	Variable maxAvgWin, minAvgWin
	Variable risePbgn, risePend // rise-time percent begin and end ( e.g. 10-90% )
	Variable decayPcnt
	Variable xbgn, xend
	
	Variable bsln // ( 0 ) baseline window off ( 1 ) baseline window on, use fxn, xbgn and xend
	Variable bslnSubtract
	
	String filterFxn
	Variable filterNum
	
	String transform
	
	// end win parameters
	
	Variable winSelect // Stats1 window to display on tab
	Variable numWindows // number of Stats1 windows
	
	String folderSelect // Stats2 folder select
	String waveSelect // Stats2 wave select
	Variable allStats2 // Stats 2 all waves select
	
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	String aName = NMStatsDF + "AmpSlct"
	
	Variable updateStatsTab, statsAuto, timeStamp, updateGraphs, bslnEntry, bslnOnOff = NaN
	String fxn2, tList, vlist = "", vlistWin = ""
	
	STRUCT NMStatsInputWavesStruct si
	NMStatsInputWavesStructRef( si )
	
	STRUCT NMStatsParamStruct sp
	NMStatsParamRef( sp )
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( !ParamIsDefault( bsln ) && bsln )
		bslnEntry = 1
	endif
	
	if ( !ParamIsDefault( numWindows ) )
	
		vlist = NMCmdNumOptional( "numWindows", numWindows, vlist, integer = 1 )
	
		if ( ( numtype( numWindows ) > 0 ) || ( numWindows < 1 ) )
			return NM2Error( 10, "numWindows", num2str( numWindows ) )
		endif
		
		CheckNMStatsWaves( 0, pointsAtLeast = numWindows )
		updateStatsTab = 1
	
	endif
	
	if ( !ParamIsDefault( winSelect ) )
	
		vlist = NMCmdNumOptional( "winSelect", winSelect, vlist, integer = 1 )
	
		if ( ( numtype( winSelect ) > 0 ) || ( winSelect < 0 ) || ( winSelect >= numpnts( $aName ) ) )
			return NM2Error( 10, "winSelect", num2str( winSelect ) )
		endif
	
		if ( winSelect != sp.winSelect )
			sp.winSelect = winSelect
			updateGraphs = 1
			statsAuto = 1
		endif
		
	endif
	
	if ( ParamIsDefault( win ) )
		win = -1
	endif
	
	win = CheckNMStatsWin( win )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	vlistWin = NMCmdNumOptional( "win", win, "", integer = 1 )
		
	if ( !ParamIsDefault( fxn ) && !bslnEntry )
	
		vlistWin = NMCmdStrOptional( "fxn", fxn, vlistWin )
		
		if ( numtype( win ) > 0 )
			return NM2Error( 10, "win", num2str( win ) )
		endif
		
		fxn2 = z_CheckFxn( fxn )
	
		if ( strlen( fxn2 ) > 0 )
			si.select[ win ] = fxn2
			bslnOnOff = z_CheckFxnBaseline( win)
			timeStamp = 1
			statsAuto = 1
		else
			return NM2Error( 20, "fxn", fxn )
		endif
		
	endif
	
	if ( !ParamIsDefault( level ) )
	
		vlistWin = NMCmdNumOptional( "level", level, vlistWin )
		
		if ( numtype( win ) > 0 )
			return NM2Error( 10, "win", num2str( win ) )
		endif
		
		if ( numtype( level ) > 0 )
			return NM2Error( 10, "level", num2str( level ) )
		endif
		
		si.select[ win ] = "Level"
		si.level[ win ] = level
		
		timeStamp = 1
		statsAuto = 1
	
	endif
	
	if ( !ParamIsDefault( levelPos ) )
	
		vlistWin = NMCmdNumOptional( "levelPos", levelPos, vlistWin )
		
		if ( numtype( win ) > 0 )
			return NM2Error( 10, "win", num2str( win ) )
		endif
		
		if ( numtype( levelPos ) > 0 )
			return NM2Error( 10, "levelPos", num2str( levelPos ) )
		endif
		
		si.select[ win ] = "Level+"
		si.level[ win ] = levelPos
		
		timeStamp = 1
		statsAuto = 1
	
	endif
	
	if ( !ParamIsDefault( levelNeg ) )
	
		vlistWin = NMCmdNumOptional( "levelNeg", levelNeg, vlistWin )
		
		if ( numtype( win ) > 0 )
			return NM2Error( 10, "win", num2str( win ) )
		endif
		
		if ( numtype( levelNeg ) > 0 )
			return NM2Error( 10, "levelNeg", num2str( levelNeg ) )
		endif
		
		si.select[ win ] = "Level-"
		si.level[ win ] = levelNeg
		
		timeStamp = 1
		statsAuto = 1
	
	endif
	
	if ( !ParamIsDefault( maxAvgWin ) )
	
		vlistWin = NMCmdNumOptional( "maxAvgWin", maxAvgWin, vlistWin )
		
		if ( numtype( win ) > 0 )
			return NM2Error( 10, "win", num2str( win ) )
		endif
	
		if ( ( numtype( maxAvgWin ) > 0 ) || ( maxAvgWin <= 0 ) )
			return NM2Error( 10, "maxAvgWin", num2str( maxAvgWin ) )
		endif
	
		si.select[ win ] = "MaxAvg" + num2str( maxAvgWin )
		
		timeStamp = 1
		statsAuto = 1
	
	endif
	
	if ( !ParamIsDefault( minAvgWin ) )
	
		vlistWin = NMCmdNumOptional( "minAvgWin", minAvgWin, vlistWin )
		
		if ( numtype( win ) > 0 )
			return NM2Error( 10, "win", num2str( win ) )
		endif
	
		if ( ( numtype( minAvgWin ) > 0 ) || ( minAvgWin <= 0 ) )
			return NM2Error( 10, "minAvgWin", num2str( minAvgWin ) )
		endif
	
		si.select[ win ] = "MinAvg" + num2str( minAvgWin )
		
		timeStamp = 1
		statsAuto = 1
	
	endif
	
	if ( !ParamIsDefault( risePbgn ) )
	
		vlistWin = NMCmdNumOptional( "risePbgn", risePbgn, vlistWin )
		
		if ( numtype( win ) > 0 )
			return NM2Error( 10, "win", num2str( win ) )
		endif
	
		if ( ( numtype( risePbgn ) > 0 ) || ( risePbgn < 0 ) || ( risePbgn > 100 ) )
			return NM2Error( 10, "risePbgn", num2str( risePbgn ) )
		endif
		
		si.risePB[ win ] = risePbgn
		
		timeStamp = 1
		statsAuto = 1
	
	endif
	
	if ( !ParamIsDefault( risePend ) )
	
		vlistWin = NMCmdNumOptional( "risePend", risePend, vlistWin )
		
		if ( numtype( win ) > 0 )
			return NM2Error( 10, "win", num2str( win ) )
		endif
	
		if ( ( numtype( risePend ) > 0 ) || ( risePend < 0 ) || ( risePend > 100 ) )
			return NM2Error( 10, "risePend", num2str( risePend ) )
		endif
		
		si.risePE[ win ] = risePend
		
		timeStamp = 1
		statsAuto = 1
	
	endif
	
	if ( !ParamIsDefault( decayPcnt ) )
	
		vlistWin = NMCmdNumOptional( "decayPcnt", decayPcnt, vlistWin )
		
		if ( numtype( win ) > 0 )
			return NM2Error( 10, "win", num2str( win ) )
		endif
	
		if ( ( numtype( decayPcnt ) > 0 ) || ( decayPcnt < 0 ) || ( decayPcnt > 100 ) )
			return NM2Error( 10, "decayPcnt", num2str( decayPcnt ) )
		endif
		
		si.decayP[ win ] = decayPcnt
		
		timeStamp = 1
		statsAuto = 1
	
	endif
	
	if ( !ParamIsDefault( xbgn ) && !bslnEntry )
	
		vlistWin = NMCmdNumOptional( "xbgn", xbgn, vlistWin )
		
		if ( numtype( win ) > 0 )
			return NM2Error( 10, "win", num2str( win ) )
		endif
		
		si.xbgn[ win ] = z_CheckXbgn( xbgn )
		
		timeStamp = 1
		statsAuto = 1
		
	endif
	
	if ( !ParamIsDefault( xend ) && !bslnEntry )
	
		vlistWin = NMCmdNumOptional( "xend", xend, vlistWin )
		
		if ( numtype( win ) > 0 )
			return NM2Error( 10, "win", num2str( win ) )
		endif
		
		si.xend[ win ] = z_CheckXend( xend )
		
		timeStamp = 1
		statsAuto = 1
		
	endif
	
	if ( numtype( bslnOnOff ) == 0 )
		
		if ( numtype( win ) > 0 )
			return NM2Error( 10, "win", num2str( win ) )
		endif
		
		si.onB[ win ] = bslnOnOff
		
		timeStamp = 1
		statsAuto = 1
		
	elseif ( !ParamIsDefault( bsln ) )
	
		vlistWin = NMCmdNumOptional( "bsln", bsln, vlistWin )
		
		if ( numtype( win ) > 0 )
			return NM2Error( 10, "win", num2str( win ) )
		endif
		
		bslnOnOff = z_CheckFxnBaseline( win )
		
		if ( numtype( bslnOnOff ) > 0 )
		
			SetNMwave( NMStatsDF + "Bflag", win, BinaryCheck( bsln ) )
			
			timeStamp = 1
			statsAuto = 1
		
		endif
		
	endif
	
	if ( !ParamIsDefault( fxn ) && bslnEntry )
	
		vlistWin = NMCmdStrOptional( "fxn", fxn, vlistWin )
		
		if ( numtype( win ) > 0 )
			return NM2Error( 10, "win", num2str( win ) )
		endif
		
		if ( WhichListItem( fxn, BslnFxnList ) < 0 )
			return NM2Error( 20, "bslnFxn", fxn )
		endif
	
		si.selectB[ win ] = fxn
		
		timeStamp = 1
		statsAuto = 1
		
	endif
	
	if ( !ParamIsDefault( xbgn ) && bslnEntry )
	
		vlistWin = NMCmdNumOptional( "xbgn", xbgn, vlistWin )
		
		if ( numtype( win ) > 0 )
			return NM2Error( 10, "win", num2str( win ) )
		endif
		
		si.xbgnB[ win ] = z_CheckXbgn( xbgn )
		
		timeStamp = 1
		statsAuto = 1
		
	endif
	
	if ( !ParamIsDefault( xend ) && bslnEntry )
	
		vlistWin = NMCmdNumOptional( "xend", xend, vlistWin )
		
		if ( numtype( win ) > 0 )
			return NM2Error( 10, "win", num2str( win ) )
		endif
		
		si.xendB[ win ] = z_CheckXend( xend )
		
		timeStamp = 1
		statsAuto = 1
		
	endif
	
	if ( !ParamIsDefault( bslnSubtract ) )
	
		vlistWin = NMCmdNumOptional( "bslnSubtract", bslnSubtract, vlistWin, integer = 1 )
		
		if ( numtype( win ) > 0 )
			return NM2Error( 10, "win", num2str( win ) )
		endif
		
		si.subtractB[ win ] = BinaryCheck( bslnSubtract )
		
		timeStamp = 1
		statsAuto = 1
		
	endif
	
	if ( !ParamIsDefault( transform ) )
	
		vlistWin = NMCmdStrOptional( "transform", transform, vlistWin )
		
		if ( numtype( win ) > 0 )
			return NM2Error( 10, "win", num2str( win ) )
		endif
		
		if ( strlen( transform ) == 0 )
			transform = "Off"
		endif
		
		tList = StringFromList( 0, transform, ";" )
		
		if ( WhichListItem( StringFromList( 0, tList, "," ), "Off;" + NMChanTransformList ) < 0 )
			return NM2Error( 10, "transform", transform )
		endif
		
		si.transform[ win ] = transform
		SetNMstr( NMStatsDF+"TransformStr", transform )
	
		timeStamp = 1
		updateGraphs = 1
		statsAuto = 1
	
	endif
	
	if ( !ParamIsDefault( filterFxn ) )
	
		vlistWin = NMCmdStrOptional( "filterFxn", filterFxn, vlistWin )
		
		if ( numtype( win ) > 0 )
			return NM2Error( 10, "win", num2str( win ) )
		endif
	
		if ( !ParamIsDefault( filterNum ) && ( filterNum == 0 ) )
	
			filterFxn = ""
			
		else
		
			if ( WhichListItem( filterFxn, NMFilterList, ";", 0, 0 ) < 0 )
				return NM2Error( 20, "filterFxn", filterFxn )
			endif
			
		endif
		
		si.filterFxn[ win ] = filterFxn
		
		timeStamp = 1
		updateGraphs = 1
		statsAuto = 1
	
	endif
	
	if ( !ParamIsDefault( filterNum ) )
	
		vlistWin = NMCmdNumOptional( "filterNum", filterNum, vlistWin )
		
		if ( numtype( win ) > 0 )
			return NM2Error( 10, "win", num2str( win ) )
		endif
		
		if ( ( numtype( filterNum ) > 0 ) || ( filterNum < 0 ) )
			return NM2Error( 10, "filterNum", num2str( filterNum ) )
		endif
		
		if ( !ParamIsDefault( filterFxn ) && ( strlen( filterFxn ) == 0 ) )
			filterNum = 0
		endif
		
		if ( filterNum == 0 )
			si.filterFxn[ win ] = ""
		endif

		si.filterNum[ win ] = filterNum
		
		timeStamp = 1
		updateGraphs = 1
		statsAuto = 1
	
	endif
	
	if ( !ParamIsDefault( folderSelect ) )
	
		vlist = NMCmdStrOptional( "folderSelect", folderSelect, vlist )
	
		folderSelect = CheckNMStatsFolderPath( folderSelect )
	
		if ( !DataFolderExists( folderSelect ) )
			return NM2Error( 30, "folderSelect", folderSelect )
		endif
		
		SetNMstr( "CurrentStats2Folder", NMChild( folderSelect ) )
		
		updateStatsTab = 1
		
	endif
	
	if ( !ParamIsDefault( waveSelect ) )
	
		vlist = NMCmdStrOptional( "waveSelect", waveSelect, vlist )
	
		if ( ParamIsDefault( folderSelect ) )
			folderSelect = CheckNMStatsFolderPath( SELECTED )
		endif
	
		if ( !DataFolderExists( folderSelect ) )
			return NM2Error( 30, "folderSelect", folderSelect )
		endif
		
		if ( ( strlen( waveSelect ) > 0 ) && !WaveExists( $folderSelect+waveSelect ) )
			return NM2Error( 1, "waveSelect", waveSelect )
		endif
		
		SetNMstr( folderSelect+"CurrentStats2Wave", waveSelect )
		
		updateStatsTab = 1
		
	endif
	
	if ( !ParamIsDefault( allStats2 ) )
	
		allStats2 = BinaryCheck( allStats2 )
		vlist = NMCmdNumOptional( "allStats2", allStats2, vlist )
		SetNMvar( NMStatsDF + "ST_2FxnAll", allStats2 )
		
		updateStatsTab = 1
		
	endif
	
	if ( !StringMatch( vlistWin, NMCmdNumOptional( "win", win, "", integer = 1 ) ) )
		vlist += vlistWin
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
		
	if ( timeStamp )
		StatsTimeStamp( NMStatsDF )
	endif
	
	if ( update )
	
		if ( updateGraphs )
			StatsChanControlsUpdate( -1, -1, 1 )
			NMChanGraphUpdate()
		endif
	
		if ( statsAuto )
			NMStatsAuto()
		elseif ( updateStatsTab )
			UpdateStats()
		endif
		
	endif
	
	return 0
	
End // NMStatsSet

//****************************************************************
//****************************************************************

Function NMStatsNumWindowsDefault()

	String wName = NMStatsDF + "AmpSlct"
	
	if ( WaveExists( $wName ) )
		return numpnts( $wName )
	endif

	return NumWindows

End // NMStatsNumWindowsDefault

//****************************************************************
//****************************************************************

Function StatsNumWindows()

	String wName = NMStatsDF + "AmpSlct"
	
	if ( WaveExists( $wName ) )
		return numpnts( $wName )
	endif
	
	return 0

End // StatsNumWindows

//****************************************************************
//****************************************************************

Function CheckNMStatsWin( win )
	Variable win // Stats window number

	if ( win == -1 )
		win = NumVarOrDefault( NMStatsDF + "AmpNV", 0 ) // currently selected Stats1 window
	endif
	
	if ( ( numtype( win ) > 0 ) || ( win < 0 ) )
		NM2Error( 10, "win", num2istr( win ) )
		return Nan
	endif
	
	CheckNMStatsWaves( 0, pointsAtLeast = ( win + 1 ), errorAlert = 1 )
	
	return win

End // CheckNMStatsWin

//****************************************************************
//****************************************************************

Function NMStatsCheck()

	KillVariables /Z $NMStatsDF+"Transform" // kill old variable
	KillStrings /Z $NMStatsDF+"Transform" // kill old variable
	
	return CheckNMStatsWaves( 0, errorAlert = 1 ) 
	
End // NMStatsCheck

//****************************************************************
//****************************************************************

Function CheckNMStatsWaves( reset [ df, pointsAtLeast, errorAlert ] )
	Variable reset
	String df
	Variable pointsAtLeast
	Variable errorAlert
	
	Variable points, wcnt
	String strValue, wName
	
	if ( ParamIsDefault( df ) )
		df = NMStatsDF
	endif
	
	if ( !DataFolderExists( df ) )
		return -1
	endif
	
	strValue = NMXaxisStats( InputWaveList, folder = df, select = "maxPoints" )
	points = str2num( strValue )
	
	if ( numtype( points ) > 0 )
		points = NumWindows
	else
		strValue = NMXaxisStats( OutputWaveList, folder = df, select = "maxPoints" )
		points = max( points, str2num( strValue ) )
	endif
	
	if ( numtype( points ) > 0 )
		points = NumWindows
	endif
	
	points = max( points, pointsAtLeast )
	
	CheckNMStatsWaveT( "AmpSlct", "Off", reset, points = points )
	CheckNMStatsWave( "AmpB", -inf, reset, points = points )
	CheckNMStatsWave( "AmpE", inf, reset, points = points )
	CheckNMStatsWave( "AmpY", NaN, reset, points = points )
	
	CheckNMStatsWave( "Bflag", 0, reset, points = points )
	CheckNMStatsWaveT( "BslnSlct", "", reset, points = points )
	CheckNMStatsWave( "BslnB", 0, reset, points = points )
	CheckNMStatsWave( "BslnE", 0, reset, points = points )
	CheckNMStatsWave( "BslnSubt", 0, reset, points = points )
	
	CheckNMStatsWave( "RiseBP", RiseTimePbgn, reset, points = points )
	CheckNMStatsWave( "RiseEP", RiseTimePend, reset, points = points )
	CheckNMStatsWave( "DcayP", DecayTimePercent, reset, points = points )
	
	CheckNMStatsWave( "FilterNum", 0, reset, points = points )
	CheckNMStatsWaveT( "FilterAlg", "", reset, points = points )
	
	CheckNMStatsWaveT( "Transform", "Off", reset, points = points )
	
	CheckNMStatsWaveT( "OffsetW", "", reset, points = points )
	
	CheckNMStatsWave( "ChanSelect", 0, reset, points = points )
	
	for ( wcnt = 0 ; wcnt < ItemsInList( OutputWaveList ) ; wcnt += 1 )
		wName = StringFromList( wcnt, OutputWaveList )
		CheckNMStatsWave( wName, Nan, reset, points = points )
	endfor
	
	CheckNMStatsTransformWave( df + "Transform", errorAlert )
	
	return 0

End // CheckNMStatsWaves

//****************************************************************
//****************************************************************

Function CheckNMStatsTransformWave( wName, errorAlert )
	String wName
	Variable errorAlert
	
	Variable icnt, jcnt, error
	String transformList, tList, alertStr
	
	if ( WaveExists( $wName ) )
		return -1
	endif
	
	Wave /T transform = $wName
	
	for ( icnt = 0 ; icnt < numpnts( transform ) ; icnt += 1 )
	
		transformList = transform[ icnt ]
		
		error = 0
		
		for ( jcnt = 0 ; jcnt < ItemsInList( transformList, ";" ) ; jcnt += 1 )
		
			tList = StringFromList( jcnt, transformList, ";" )
			
			if ( NMChanTransformCheck( tList ) )
			
				error = 1
				
				if ( errorAlert )
					alertStr = "Encountered one or more bad parameters for transform = " + tList + ". Please reset your transform for Stats Win" + num2istr( icnt ) + "."
					NMDoAlert( alertStr, title = "NM Stats Transform Error" )
					NMHistory( "NM Stats Window Transform Error: " + alertStr )
				endif

			endif
			
		endfor
		
		if ( error )
			transform[ icnt ] = "Off"
		endif
	
	endfor
	
End // CheckNMStatsTransformWave

//****************************************************************
//****************************************************************

Function CheckNMStatsWave( wName, value, reset [ points ] )
	String wName // wave name
	Variable value
	Variable reset
	Variable points
	
	String df = NMStatsDF
	
	if ( strlen( wName ) == 0 )
		return NM2Error( 21, "wName", wName )
	endif
	
	if ( !DataFolderExists( df ) )
		return NM2Error( 30, "StatsDF", df )
	endif
	
	if ( ParamIsDefault( points ) )
		points = NMStatsNumWindowsDefault()
	endif
	
	if ( reset )
		return SetNMwave( df + wName, -1, value )
	else
		return CheckNMWaveOfType( df + wName, points, value, "R" )
	endif
	
End // CheckNMStatsWave

//****************************************************************
//****************************************************************

Function CheckNMStatsWaveT( wName, strvalue, reset [ points ] )
	String wName // wave name
	String strvalue
	Variable reset
	Variable points
	
	String df = NMStatsDF
	
	if ( strlen( wName ) == 0 )
		return NM2Error( 21, "wName", wName )
	endif
	
	if ( !DataFolderExists( df ) )
		return NM2Error( 30, "StatsDF", df )
	endif
	
	if ( ParamIsDefault( points ) )
		points = NMStatsNumWindowsDefault()
	endif
	
	if ( reset )
		return SetNMtwave( df + wName, -1, strvalue )
	else
		return CheckNMtwave( df + wName, points, strvalue )
	endif
	
End // CheckNMStatsWaveT

//****************************************************************
//****************************************************************

Function NMStatsWavesReset( [ history ] )
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	if ( history )
		NMCommandHistory( "" )
	endif
	
	CheckNMStatsWaves( 1 )
	UpdateStats1()

End // NMStatsWavesReset

//****************************************************************
//****************************************************************

Structure NMStatsInputWavesStruct

	Wave /T select
	Wave xbgn, xend, level
	Wave /T selectB
	Wave onB, xbgnB, xendB, subtractB
	Wave risePB, risePE, decayP
	Wave filterNum
	Wave /T filterFxn, transform, offset
	Wave chanSelect

EndStructure

//****************************************************************
//****************************************************************

Structure NMStatsOutputWavesStruct
	
	Wave x, y
	Wave xB, yB
	Wave riseXB, riseXE, riseT
	Wave decayX, decayT

EndStructure

//****************************************************************
//****************************************************************

Function NMStatsInputWavesStructRef( si [ df ] )
	STRUCT NMStatsInputWavesStruct &si
	String df
	
	if ( ParamIsDefault( df ) )
		df = NMStatsDF
	endif
	
	if ( CheckNMStatsWaves( 0, df = df ) == -1 )
		return -1
	endif
	
	Wave /T si.select = $df + "AmpSlct"
	Wave si.xbgn = $df + "AmpB"
	Wave si.xend = $df + "AmpE"
	Wave si.level = $df + "AmpY"
	
	Wave si.onB = $df + "Bflag"
	Wave /T si.selectB = $df + "BslnSlct"
	Wave si.xbgnB = $df + "BslnB"
	Wave si.xendB = $df + "BslnE"
	Wave si.subtractB = $df + "BslnSubt"
	
	Wave si.risePB = $df + "RiseBP"
	Wave si.risePE = $df + "RiseEP"
	Wave si.decayP = $df + "DcayP"
	
	Wave si.filterNum = $df + "FilterNum"
	Wave /T si.filterFxn = $df + "FilterAlg"
	
	Wave /T si.transform = $df + "Transform"
	Wave /T si.offset = $df + "OffsetW"
	
	Wave si.chanSelect = $df + "ChanSelect"
	
	return 0

End // NMStatsInputWavesStructRef

//****************************************************************
//****************************************************************

Function NMStatsOutputWavesStructRef( so [ df ] )
	STRUCT NMStatsOutputWavesStruct &so
	String df

	if ( ParamIsDefault( df ) )
		df = NMStatsDF
	endif
	
	if ( CheckNMStatsWaves( 0, df = df ) == -1 )
		return -1
	endif
	
	Wave so.x = $df + "AmpX"
	Wave so.y = $df + "AmpY"
	
	Wave so.xB = $df + "BslnX"
	Wave so.yB = $df + "BslnY"
	
	Wave so.riseXB = $df + "RiseBX"
	Wave so.riseXE = $df + "RiseEX"
	Wave so.riseT = $df + "RiseTm"
	
	Wave so.decayX = $df + "DcayX"
	Wave so.decayT = $df + "DcayT"
	
	return 0

End // NMStatsOutputWavesStructRef

//****************************************************************
//****************************************************************

Function NMStatsOutputWavesStructClear( [ df ] )
	String df
	
	Variable icnt
	String ampSlct
	
	if ( ParamIsDefault( df ) )
		df = NMStatsDF
	endif
	
	Wave /T select = $df + "AmpSlct"
	
	STRUCT NMStatsOutputWavesStruct sw
	NMStatsOutputWavesStructRef( sw, df = df )
	
	for ( icnt = 0 ; icnt < numpnts( select ) ; icnt += 1 )
	
		ampSlct = select[ icnt ]
		
		if ( !StringMatch( ampSlct[ 0, 4 ], "Level" ) && ( icnt < numpnts( sw.y ) ) )
			sw.y[ icnt ] = NaN
		endif
	
	endfor
	
	sw.x = NaN
	
	sw.xB = NaN
	sw.yB = NaN
	
	sw.riseXB = NaN
	sw.riseXE = NaN
	sw.riseT = NaN
	
	sw.decayX = NaN
	sw.decayT = NaN
	
End // NMStatsOutputWavesStructClear

//****************************************************************
//****************************************************************

Structure NMStatsInputsStruct

	String select
	Variable xbgn, xend, level
	String selectB
	Variable onB, xbgnB, xendB, subtractB
	Variable risePB, risePE, decayP
	Variable filterNum
	String filterFxn, transform, offset
	Variable chanSelect

EndStructure

//****************************************************************
//****************************************************************

Structure NMStatsOutputsStruct
	
	Variable x, y
	Variable xB, yB
	Variable riseXB, riseXE, riseT
	Variable decayX, decayT

EndStructure

//****************************************************************
//****************************************************************

Function NMStatsInputsStructNull( si )
	STRUCT NMStatsInputsStruct &si
	
	si.select = ""
	si.xbgn = NaN; si.xend = NaN; si.level = NaN
	si.selectB = ""
	si.onB = NaN; si.xbgnB = NaN; si.xendB = NaN; si.subtractB = NaN
	si.risePB = NaN; si.risePE = NaN; si.decayP = NaN
	si.filterNum = NaN
	si.filterFxn = ""; si.transform = ""; si.offset = ""
	si.chanSelect = NaN
	
End // NMStatsInputsStructNull

//****************************************************************
//****************************************************************

Function NMStatsOutputsStructNull( so )
	STRUCT NMStatsOutputsStruct &so
	
	so.x = NaN; so.y = NaN
	so.xB = NaN; so.yB = NaN
	so.riseXB = NaN; so.riseXE = NaN; so.riseT = NaN
	so.decayX = NaN; so.decayT = NaN
	
End // NMStatsOutputsStructNull

//****************************************************************
//****************************************************************

Function NMStatsInputsGet( si [ win ] )
	STRUCT NMStatsInputsStruct &si
	Variable win
	
	STRUCT NMStatsInputWavesStruct sw
	NMStatsInputWavesStructRef( sw )
	
	if ( ParamIsDefault( win ) || ( win == -1 ) )
		win = NumVarOrDefault( NMStatsDF + "AmpNV", 0 )
	endif
	
	if ( ( numtype( win ) > 0 ) || ( win < 0 ) || ( win >= numpnts( sw.select ) ) )
		NMStatsInputsStructNull( si )
		return -1
	endif
	
	si.select = sw.select[ win ]
	si.xbgn = sw.xbgn[ win ]
	si.xend = sw.xend[ win ]
	si.level = sw.level[ win ]
	
	si.selectB = sw.selectB[ win ]
	si.onB = sw.onB[ win ]
	si.xbgnB = sw.xbgnB[ win ]
	si.xendB = sw.xendB[ win ]
	si.subtractB = sw.subtractB[ win ]
	
	si.risePB = sw.risePB[ win ]
	si.risePE = sw.risePE[ win ]
	si.decayP = sw.decayP[ win ]
	
	si.filterNum = sw.filterNum[ win ]
	si.filterFxn = sw.filterFxn[ win ]
	si.transform = sw.transform[ win ]
	si.offset = sw.offset[ win ]
	
	si.chanSelect = sw.chanSelect[ win ]
	
	return 0
	
End // NMStatsInputsGet

//****************************************************************
//****************************************************************

Function NMStatsOutputsGet( so [ win ] )
	STRUCT NMStatsOutputsStruct &so
	Variable win
	
	STRUCT NMStatsOutputWavesStruct sw
	NMStatsOutputWavesStructRef( sw )
	
	if ( ParamIsDefault( win ) )
		win = NumVarOrDefault( NMStatsDF + "AmpNV", 0 )
	endif
	
	if ( ( numtype( win ) > 0 ) || ( win < 0 ) || ( win >= numpnts( sw.x ) ) )
		NMStatsOutputsStructNull( so )
		return -1
	endif
	
	so.x = sw.x[ win ]
	so.y = sw.y[ win ]
	
	so.xB = sw.xB[ win ]
	so.yB = sw.yB[ win ]
	
	so.riseXB = sw.riseXB[ win ]
	so.riseXE = sw.riseXE[ win ]
	so.riseT = sw.riseT[ win ]
	
	so.decayX = sw.decayX[ win ]
	so.decayT = sw.decayT[ win ]
	
	return 0
	
End // NMStatsOutputsGet

//****************************************************************
//****************************************************************

Function NMStatsOutputsSave( so [ win ] )
	STRUCT NMStatsOutputsStruct &so
	Variable win
	
	STRUCT NMStatsOutputWavesStruct sw
	NMStatsOutputWavesStructRef( sw )
	
	if ( ParamIsDefault( win ) )
		win = NumVarOrDefault( NMStatsDF + "AmpNV", 0 )
	endif
	
	if ( ( numtype( win ) > 0 ) || ( win < 0 ) || ( win >= numpnts( sw.x ) ) )
		return -1
	endif
	
	sw.x[ win ] = so.x
	sw.y[ win ] = so.y
	
	sw.xB[ win ] = so.xB
	sw.yB[ win ] = so.yB
	
	sw.riseXB[ win ] = so.riseXB
	sw.riseXE[ win ] = so.riseXE
	sw.riseT[ win ] = so.riseT
	
	sw.decayX[ win ] = so.decayX
	sw.decayT[ win ] = so.decayT
	
	return 0
	
End // NMStatsOutputsSave

//****************************************************************
//****************************************************************

Structure NMStatsDisplayWavesStruct

	Wave pntX, pntY, winX, winY, bslnX, bslnY, RDX, RDY

EndStructure

//****************************************************************
//****************************************************************

Function NMStatsDisplayWavesStructRef( dw )
	STRUCT NMStatsDisplayWavesStruct &dw
	
	String df = NMStatsDF
	
	CheckNMWaveOfType( df + "ST_PntX", 1, Nan, "R" )
	CheckNMWaveOfType( df + "ST_PntY", 1, Nan, "R" )
	CheckNMWaveOfType( df + "ST_WinX", 2, Nan, "R" )
	CheckNMWaveOfType( df + "ST_WinY", 2, Nan, "R" )
	CheckNMWaveOfType( df + "ST_BslnX", 2, Nan, "R" )
	CheckNMWaveOfType( df + "ST_BslnY", 2, Nan, "R" )
	CheckNMWaveOfType( df + "ST_RDX", 2, Nan, "R" )
	CheckNMWaveOfType( df + "ST_RDY", 2, Nan, "R" )
	
	Wave dw.pntX = $df + "ST_PntX"
	Wave dw.pntY = $df + "ST_PntY"
	Wave dw.winX = $df + "ST_WinX"
	Wave dw.winY = $df + "ST_WinY"
	Wave dw.bslnX = $df + "ST_BslnX"
	Wave dw.bslnY = $df + "ST_BslnY"
	Wave dw.RDX = $df + "ST_RDX"
	Wave dw.RDY = $df + "ST_RDY"

End // NMStatsDisplayWavesStructRef

//****************************************************************
//****************************************************************

Function NMStatsDisplayWavesStructNull( dw )
	STRUCT NMStatsDisplayWavesStruct &dw
	
	dw.pntX = NaN; dw.pntY =  NaN
	dw.winX =  NaN; dw.winY =  NaN
	dw.bslnX =  NaN; dw.bslnY =  NaN
	dw.RDX = NaN; dw.RDY = NaN

End // NMStatsDisplayWavesStructNull

//****************************************************************
//****************************************************************

Function NMStatsConfigEdit() // called from NM_Configurations

	String tName = NMStatsWinTable( "inputs" )

End // NMStatsConfigEdit

//****************************************************************
//****************************************************************

Function NMStatsConfigs() // called from NM_Configurations

	NMStatsConfigsCheck( errorAlert = 1 )
	
	NMStatsConfigVar( "UseSubfolders", "use subfolders when creating Stats waves ( uncheck for previous NM formatting )", "boolean" )
	NMStatsConfigVar( "OverwriteMode", "overwrite existing waves, tables and graphs if their is a name conflict", "boolean" )
	
	NMStatsConfigStr( "WaveNamingFormat", "attach new wave identifier as \"prefix\" or \"suffix\" ( use \"suffix\" for previous NM formatting )", "prefix;suffix;" )
	
	NMStatsConfigVar( "WaveLengthFormat", "Stats1 wave length matches number of ( 0 ) waves per channel ( 1 ) currently selected waves ( use 0 for previous NM formatting )", "waves per channel;currently selected waves;" )
	
	NMStatsConfigVar( "DisplayPrecision", "number of decimal numbers to display", "" )
	
	NMStatsConfigStr( "DisplayError", "Stats2 display error", "STDV;SEM;" )
	
	NMStatsConfigVar( "AutoStats1", "auto Stats1 computation after wave change", "boolean" )
	NMStatsConfigVar( "AutoStats2", "All Waves auto Stats2", "boolean" )
	NMStatsConfigVar( "AutoTables", "All Waves auto tables", "boolean" )
	NMStatsConfigVar( "AutoPlots", "All Waves auto plots", "boolean" )
	
	NMStatsConfigVar( "GraphLabelsOn", "create Stats1 labels on channel displays", "boolean" )
	
	NMStatsConfigVar( "RiseTimeSearchFromPeak", "search backwards from peak for rise-time % points", "boolean" )
	
	NMStatsConfigStr( "AmpColor", "amplitude display color", "RGB" )
	NMStatsConfigStr( "BaseColor", "baseline display color", "RGB" )
	NMStatsConfigStr( "RiseColor", "rise/decay display color", "RGB" )
	
	NMStatsConfigWaveT( "AmpSlct", "Off", "measurement" )
	NMStatsConfigWave( "AmpB", 0, "x-axis window begin" )
	NMStatsConfigWave( "AmpE", 0, "x-axis window end" )
	
	NMStatsConfigWave( "Bflag", 0, "compute baseline" )
	NMStatsConfigWaveT( "BslnSlct", "Avg", "baseline measurement" )
	NMStatsConfigWave( "BslnB", 0, "baseline x-axis window begin" )
	NMStatsConfigWave( "BslnE", 0, "baseline x-axis window end" )
	NMStatsConfigWave( "BslnSubt", 0, "baseline auto subtract" )
	
	NMStatsConfigWave( "RiseBP", RiseTimePbgn, "rise-time begin %" )
	NMStatsConfigWave( "RiseEP", RiseTimePend, "rise-time end %" )
	
	NMStatsConfigWave( "DcayP", DecayTimePercent, "decay %" )
	
	//NMStatsConfigWave( "dtFlag", 0, "channel transform ( 0 ) none ( 1 ) d/dt ( 2 ) dd/dt*dt ( 3 ) integral ( 4 ) normalize ( 5 ) dF/F0 ( 6 ) baseline" )
	
	//NMStatsConfigWaveT( "SmthAlg", "binomial", "smooth/filter algorithm: binomial, boxcar, low-pass, high-pass" )
	//NMStatsConfigWave( "SmthNum", 0, "filter parameter number" )
	
	NMStatsConfigWaveT( "FilterAlg", "binomial", "smooth/filter algorithm: binomial, boxcar, low-pass, high-pass" )
	NMStatsConfigWave( "FilterNum", 0, "filter parameter number" )
	
	NMStatsConfigWaveT( "Transform", "Off", "channel transform algorithm: Off, Baseline, Normalize, dF/Fo..." )
	
	NMStatsConfigWave( "ChanSelect", 0, "channel to analyze" )
	
	NMStatsConfigWaveT( "OffsetW", "", "x-offset wave name ( /g for group num, /w for wave num )" )

End // NMStatsConfigs

//****************************************************************
//****************************************************************

Function NMStatsConfigsCheck( [ errorAlert ])
	Variable errorAlert

	Variable npnts, icnt
	String alertStr

	String cdf = ConfigDF( "Stats" )
	String pdf = NMPackageDF( "Stats" )
	
	NMConfigWaveRename( "Stats", "SmthAlg", "FilterAlg" )
	NMConfigWaveRename( "Stats", "SmthNum", "FilterNum" )
	
	if ( WaveExists( $cdf + "dtFlag" ) )
	
		Wave wtemp = $cdf + "dtFlag"
		
		npnts = numpnts( wtemp )
	
		Make /T/O/N=( npnts ) $cdf + "Transform"
		
		Wave /T stemp = $cdf + "Transform"
		
		stemp = NMChanTransformName( wtemp )
	
	endif
	
	if ( WaveExists( $pdf + "dtFlag" ) )
	
		Wave wtemp = $pdf + "dtFlag"
		
		npnts = numpnts( wtemp )
	
		Make /T/O/N=( npnts ) $pdf + "Transform"
		
		Wave /T stemp = $pdf + "Transform"
	
		stemp = NMChanTransformName( wtemp )
	
	endif
	
	if ( WaveExists( $cdf + "Transform" ) )
		CheckNMStatsTransformWave( cdf + "Transform", errorAlert )
	endif
	
	if ( WaveExists( $pdf + "Transform" ) )
		CheckNMStatsTransformWave( pdf + "Transform", errorAlert )
	endif

End // NMStatsConfigsCheck

//****************************************************************
//****************************************************************

Function NMStatsConfigVar( varName, description, type )
	String varName
	String description
	String type
	
	return NMConfigVar( "Stats", varName, NMStatsVarGet( varName ), description, type )
	
End // NMStatsConfigVar

//****************************************************************
//****************************************************************

Function NMStatsConfigStr( strVarName, description, type )
	String strVarName
	String description
	String type
	
	return NMConfigStr( "Stats", strVarName, NMStatsStrGet( strVarName ), description, type )
	
End // NMStatsConfigStr

//****************************************************************
//****************************************************************

Function NMStatsConfigWave( wName, value, description )
	String wName // wave name
	Variable value
	String description

	return NMConfigWave( "Stats", wName, StatsNumWindows(), value, description )

End // NMStatsConfigWave

//****************************************************************
//****************************************************************

Function NMStatsConfigWaveT( wName, strValue, description )
	String wName // wave name
	String strValue
	String description

	return NMConfigTWave( "Stats", wName, StatsNumWindows(), strValue, description )

End // NMStatsConfigWaveT

//****************************************************************
//****************************************************************

Structure NMStatsParamStruct
	
	NVAR winSelect, xbgn, xend, x, y, yB, filterNum
	SVAR yStr, xBStr, filterFxn

	NVAR count, avg, stdv, sem, min, max

EndStructure

//****************************************************************
//****************************************************************

Function NMStatsParamRef( sp )
	STRUCT NMStatsParamStruct &sp
	
	String df = NMStatsDF
	
	CheckNMvar( df + "AmpNV", 0 )
	CheckNMvar( df + "AmpBV", 0 )
	CheckNMvar( df + "AmpEV", 0 )
	CheckNMvar( df + "AmpXV", NaN )
	CheckNMvar( df + "AmpYV", NaN )
	CheckNMstr( df + "AmpYVS", "" )
	
	CheckNMstr( df + "BslnXVS", "" )
	CheckNMvar( df + "BslnYV", NaN )
	
	CheckNMvar( df + "SmoothN", 0 )
	CheckNMstr( df + "SmoothA", "" )
	
	CheckNMvar( df + "ST_2CNT", NaN )
	CheckNMvar( df + "ST_2AVG", NaN )
	CheckNMvar( df + "ST_2SDV", NaN )
	CheckNMvar( df + "ST_2SEM", NaN )
	CheckNMvar( df + "ST_2MIN", NaN )
	CheckNMvar( df + "ST_2MAX", NaN )
	
	NVAR sp.winSelect = $df + "AmpNV"
	NVAR sp.xbgn = $df + "AmpBV"
	NVAR sp.xend = $df + "AmpEV"
	NVAR sp.x = $df + "AmpXV"
	NVAR sp.y = $df + "AmpYV"
	NVAR sp.yB = $df + "BslnYV"
	NVAR sp.filterNum = $df + "SmoothN"
	
	SVAR sp.yStr = $df + "AmpYVS"
	SVAR sp.xBStr = $df + "BslnXVS"
	SVAR sp.filterFxn = $df + "SmoothA"
	
	NVAR sp.count = $df + "ST_2CNT"
	NVAR sp.avg = $df + "ST_2AVG"
	NVAR sp.stdv = $df + "ST_2SDV"
	NVAR sp.sem = $df + "ST_2SEM"
	NVAR sp.min = $df + "ST_2MIN"
	NVAR sp.max = $df + "ST_2MAX"
	
End // NMStatsParamRef

//****************************************************************
//****************************************************************

Function NMStatsVarGet( varName )
	String varName
	
	String df = NMStatsDF
	
	Variable defaultVal = Nan
	
	strswitch( varName )
	
		case "UseSubfolders":
			defaultVal = 1
			break
			
		case "OverwriteMode":
			defaultVal = 1
			break
			
		case "DisplayPrecision":
			defaultVal = 2 // decimal places
			break
			
		case "WaveLengthFormat":
			defaultVal = 1
			break
			
		case "ComputeAllWin":
			defaultVal = 1
			break
			
		case "ComputeAllDisplay":
			defaultVal = 1
			break
			
		case "ComputeAllSpeed":
			defaultVal = 0
			break
			
		case "AutoStats1": // when stepping thru data
			defaultVal = 1 // ( 0 ) off ( 1 ) on
			break
		
		case "AutoTables": // All Waves
			defaultVal = NumVarOrDefault( df+"TablesOn", 1 )
			defaultVal = NumVarOrDefault( df+"AutoTable", defaultVal )
			break
			
		case "AutoPlots": // All Waves
			defaultVal = NumVarOrDefault( df+"AutoPlot", 1 )
			break
			
		case "AutoStats2": // All Waves
			defaultVal = 0 // ( 0 ) off ( 1 ) on
			break
			
		case "GraphLabelsOn":
			defaultVal = 1 // ( 0 ) off ( 1 ) on
			break
			
		case "RiseTimeSearchFromPeak":
			defaultVal = 1 // ( 0 ) no ( 1 ) yes
			break
			
		case "Stats2DisplaySEM":
			defaultVal = 0 // ( 0 ) STDV ( 1 ) SEM
			break
			
		case "AmpNV":
			defaultVal = 0
			break
			
		case "OffsetType":
			defaultVal = 1
			break
			
		case "OffsetBsln":
			defaultVal = 1
			break
			
		case "HistoBinAuto":
			defaultVal = 1
			break
			
		case "HistoBinStart":
			defaultVal = Nan
			break
			
		case "HistoBinWidth":
			defaultVal = Nan
			break
			
		case "HistoNumBins":
			defaultVal = NaN
			break
			
		case "HistoBinCentered":
			defaultVal = 0
			break
			
		case "HistoCumulative":
			defaultVal = 0
			break
			
		case "HistoNormalize":
			defaultVal = 0
			break
			
		case "RelationalOpCreateSet":
			defaultVal = 0
			break
			
		case "KSdsply":
			defaultVal = 1
			break
			
		case "ST_2FxnAll":
			defaultVal = 0
			break
			
		default:
			NMDoAlert( "NMStatsVar Error: no variable called " + NMQuotes( varName ) )
			return Nan
	
	endswitch
	
	if ( !DataFolderExists( df ) )
		return defaultVal
	endif
	
	return NumVarOrDefault( df+varName, defaultVal )
	
End // NMStatsVarGet

//****************************************************************
//****************************************************************

Function /S NMStatsStrGet( strVarName )
	String strVarName
	
	String df = NMStatsDF
	
	String defaultStr = ""
	
	strswitch( strVarName )
	
		case "WaveNamingFormat":
			defaultStr = "prefix"
			break
			
		case "WaveScaleAlg":
			defaultStr = "x"
			break
			
		case "AmpColor":
			defaultStr = NMRedStr
			break
			
		case "BaseColor":
			defaultStr = NMGreenStr
			break
			
		case "RiseColor":
			defaultStr = NMBlueStr
			break
			
		case "RelationalPrefixOrSuffix":
			defaultStr = "I" // used to be "Sort"
			break
			
		case "DisplayError":
			defaultStr = "STDV" // "STDV" or "SEM"
			break
			
		default:
			NMDoAlert( "NMStatsStr Error: no variable called " + NMQuotes( strVarName ) )
			return ""
	
	endswitch
	
	if ( !DataFolderExists( df ) )
		return defaultStr
	endif
	
	return StrVarOrDefault( df + strVarName, defaultStr )
			
End // NMStatsStrGet

//****************************************************************
//****************************************************************

Function /S StatsWavesCopy( fromDF, toDF )
	String fromDF // data folder copy from
	String toDF // data folder copy to
	
	Variable wcnt
	String parent, wList, wList2, wName, outList //, df = NMStatsDF
	
	fromDF = LastPathColon( fromDF, 1 )
	toDF = LastPathColon( toDF, 1 )
	
	if ( !DataFolderExists( fromDF ) )
		return NM2ErrorStr( 30, "fromDF", fromDF )
	endif
	
	if ( !WaveExists( $fromDF+"AmpE" ) )
		return NM2ErrorStr( 1, "AmpE", fromDF+"AmpE" )
	endif
	
	parent = NMParent( toDF )
	
	if ( !DataFolderExists( parent ) )
		return NM2ErrorStr( 30, "toDF", parent ) // parent directory doesnt exist 
	endif
	
	if ( !DataFolderExists( toDF ) )
		NewDataFolder $RemoveEnding( toDF, ":" ) // make "to" data folder
	endif
	
	wList = NMFolderWaveList( fromDF, "*", ";", "", 0 )
	wList2 = NMFolderWaveList( fromDF, "ST_*", ";", "",0 )
	
	wList = RemoveFromList( wList2, wList ) // remove display waves
	wList = RemoveFromList( "WinSelect", wList )
	outList = RemoveFromList( "AmpY", OutputWaveList ) // keep, used as input wave for level detection
	wList = RemoveFromList( outList, wList )
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( WaveExists( $( fromDF + wName ) ) )
			Duplicate /O $( fromDF + wName ), $( toDF + wName )
		endif
	
	endfor
	
	return wList

End // StatsWavesCopy

//****************************************************************
//****************************************************************

Function /S CheckNMStatsFolderPath( folder )
	String folder
	
	String path, fName
	
	if ( strlen( folder ) == 0 )
		return CurrentNMFolder( 1 ) // current data folder
	endif
	
	if ( StringMatch( folder, DEFAULTSUBFOLDER ) )
		folder = CurrentNMStatsSubfolder()
		CheckNMSubfolder( folder )
		return folder
	endif
	
	if ( StringMatch( folder, SELECTED ) )
		return CurrentNMStats2FolderSelect( 1 )
	endif
	
	path = NMParent( folder )
	fName = NMChild( folder )
	
	if ( strlen( path ) > 0 )
		return folder
	endif
	
	if ( StringMatch( fName, CurrentNMFolder( 0 ) ) )
		return CurrentNMFolder( 1 ) // complete path
	elseif ( DataFolderExists( folder ) ) // subfolder exists
		return CurrentNMFolder( 1 ) + fName + ":" // complete path
	endif
	
	return folder
	
End // CheckNMStatsFolderPath

//****************************************************************
//****************************************************************

Function /S CheckNMStatsWavePath( wName [ folder ] )
	String wName // wave name
	String folder
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ( strlen( wName ) == 0 ) || StringMatch( wName, SELECTED ) )
		return CurrentNMStats2WaveSelect( 1 )
	endif
	
	if ( WaveExists( $folder+wName ) )
		return wName
	endif
	
	wName = GetDataFolder( 1 ) + wName // try subfolder
	
	if ( WaveExists( $wName ) )
		return wName
	endif
	
	return ""
	
End // CheckNMStatsWavePath

//****************************************************************
//****************************************************************
//
//		Tab Panel Functions
//
//****************************************************************
//****************************************************************

Function MakeStats( force ) // create Stats tab controls
	Variable force
	
	Variable x0, y0, xinc, yinc, fs = NMPanelFsize
	String df = NMStatsDF
	
	if ( !IsCurrentNMTab( "Stats" ) )
		return 0
	endif
	
	ControlInfo /W=$NMPanelName ST_AmpSelect
	
	if ( ( V_Flag != 0 ) && !force )
		return 0 // Stats tab controls exist
	endif
	
	if ( !DataFolderExists( df ) )
		return 0 // stats has not been initialized yet
	endif
	
	STRUCT NMStatsParamStruct sp
	NMStatsParamRef( sp )
	
	DoWindow /F $NMPanelName
	
	x0 = 35
	xinc = 150
	y0 = NMPanelTabY + 60
	yinc = 27
	
	GroupBox ST_Group, title="Stats1", pos={x0-15, y0-30}, size={260,255}, fsize=fs, win=$NMPanelName
	
	PopupMenu ST_AmpSelect, pos={x0+85,y0-5}, bodywidth=135, fsize=fs, win=$NMPanelName
	PopupMenu ST_AmpSelect, value =NMStatsFxnList(), proc=NMStatsAmpPopup, win=$NMPanelName
	
	PopupMenu ST_WinSelect, pos={x0+180,y0-5}, bodywidth=85, fsize=fs, win=$NMPanelName
	PopupMenu ST_WinSelect, value="", proc=NMStatsWinPopup, win=$NMPanelName
	
	SetVariable ST_AmpBSet, title="xbgn", pos={x0+18,y0+1*yinc}, size={115,50}, limits={-inf,inf,1}, fsize=fs, win=$NMPanelName
	SetVariable ST_AmpBSet, value=sp.xbgn, proc=NMStatsSetVariable, win=$NMPanelName
	
	SetVariable ST_AmpESet, title="xend", pos={x0+18,y0+2*yinc}, size={115,50}, limits={-inf,inf,1}, fsize=fs, win=$NMPanelName
	SetVariable ST_AmpESet, value=sp.xend, proc=NMStatsSetVariable, win=$NMPanelName
	
	SetVariable ST_AmpYSet, title="y =", pos={x0+xinc,y0+1*yinc}, size={80,50}, limits={-inf,inf,0}, fsize=fs, win=$NMPanelName
	SetVariable ST_AmpYSet, value=sp.yStr, frame=0, proc=NMStatsSetVariable, win=$NMPanelName
	
	SetVariable ST_AmpXSet, title="x =", pos={x0+xinc,y0+2*yinc}, size={80,50}, limits={-inf,inf,0}, fsize=fs, win=$NMPanelName
	SetVariable ST_AmpXSet, value=sp.x, frame=0, proc=NMStatsSetVariable, win=$NMPanelName
	
	SetVariable ST_FilterNSet, title="filter", pos={x0+18,y0+3*yinc}, size={115,50}, limits={0,inf,1}, fsize=fs, win=$NMPanelName
	SetVariable ST_FilterNSet, value=sp.filterNum, proc=NMStatsSetVariable, win=$NMPanelName
	
	SetVariable ST_FilterASet, title=" ", pos={x0+xinc,y0+3*yinc}, size={80,50}, fsize=fs, noedit=1, win=$NMPanelName
	SetVariable ST_FilterASet, value=sp.filterFxn, frame=0, proc=NMStatsSetVariable, win=$NMPanelName
	
	CheckBox ST_Baseline, title="baseline", pos={x0,y0+4*yinc}, size={200,50}, value=0, proc=NMStatsCheckBox, fsize=fs, win=$NMPanelName
	
	SetVariable ST_BslnWin, title="b =", pos={x0+16,y0+4*yinc}, size={140,20}, win=$NMPanelName
	SetVariable ST_BslnWin, value=sp.xBStr, frame=0, fsize=fs, title = " ", proc=NMStatsSetVariable, win=$NMPanelName
	
	SetVariable ST_BslnSet, title="b =", pos={x0+xinc,y0+4*yinc}, size={80,20}, limits={-inf,inf,0}, win=$NMPanelName
	SetVariable ST_BslnSet, value=sp.yB, frame=0, fsize=fs, win=$NMPanelName
	
	CheckBox ST_Transform, title="transform", pos={x0,y0+5*yinc}, size={200,50}, value=0, proc=NMStatsCheckBox, fsize=fs, win=$NMPanelName
	
	CheckBox ST_Offset, title="x-offset", pos={x0,y0+6*yinc}, size={200,50}, value=0, proc=NMStatsCheckBox, fsize=fs, win=$NMPanelName
	
	Button ST_AllWaves, title="All Waves", pos={x0+65,y0+7*yinc}, size={100,20}, proc=NMStatsButton, fsize=fs, win=$NMPanelName
	
	xinc = 135
	y0 = NMPanelTabY + 320
	yinc = 25
	
	GroupBox ST_2Group, title="Stats2", pos={x0-15,y0-25}, size={260,135}, fsize=fs, win=$NMPanelName
	
	PopupMenu ST_2FolderSelect, value="Folder Select", bodywidth=230, pos={x0+180,y0}, proc=NMStats2FolderSelectPopup, fsize=fs, win=$NMPanelName
	
	PopupMenu ST_2WaveSelect, value="Wave Select", bodywidth=230, pos={x0+180,y0+1*yinc}, proc=NMStats2WaveSelectPopup, fsize=fs, win=$NMPanelName
	
	PopupMenu ST_2FxnSelect, value="Functions", bodywidth=100, pos={x0+110,y0+2*yinc}, proc=NMStats2FxnSelectPopup, fsize=fs, win=$NMPanelName
	
	CheckBox ST_2FxnAll, title="all", pos={x0+180,y0+2*yinc+4}, size={200,50}, value=0, proc=NMStats2CheckBox, fsize=fs, win=$NMPanelName
	
	x0 += 5
	y0 += 10 + 3 * yinc
	xinc = 80
	
	SetVariable ST_2AvgSet, title="\F'Symbol'm =", pos={x0,y0}, size={85,50}, fsize=fs, win=$NMPanelName
	SetVariable ST_2AvgSet, value=sp.avg, limits={-inf,inf,0}, frame=0, win=$NMPanelName
	
	SetVariable ST_2SDVSet, title="± ", pos={x0+85,y0}, size={75,50}, fsize=fs, win=$NMPanelName
	SetVariable ST_2SDVSet, value=sp.stdv, limits={0,inf,0}, frame=0, win=$NMPanelName
	
	//SetVariable ST_2SEMSet, title="± ", pos={x0+85,y0}, size={75,50}, fsize=fs, win=$NMPanelName
	//SetVariable ST_2SEMSet, value=sp.sem, limits={0,inf,0}, frame=0, win=$NMPanelName
	
	SetVariable ST_2CNTSet, title="n =", pos={x0+165,y0}, size={70,50}, fsize=fs, win=$NMPanelName
	SetVariable ST_2CNTSet, value=sp.count, limits={0,inf,0}, format="%.0f", frame=0, win=$NMPanelName
	
	UpdateStats()
	
	return 0

End // MakeStats

//****************************************************************
//****************************************************************

Function UpdateStats()

	UpdateStats1()
	UpdateStats2()

End // UpdateStats

//****************************************************************
//****************************************************************

Function UpdateStats1() // update/display current window result values

	Variable off, v1, v2, modeNum, dis2, dis, xdis, yframe, xframe, maxMinAvgWin = NaN
	Variable displayPrecision = NMStatsVarGet( "DisplayPrecision" )
	
	String tstr, xtl, ytl, select, tList, transform
	String df = NMStatsDF
	
	if ( NMVarGet( "ConfigsDisplay" ) > 0 )
		return 0
	endif
	
	if ( !IsCurrentNMTab( "Stats" ) )
		return 0
	endif
	
	STRUCT NMStatsParamStruct sp
	NMStatsParamRef( sp )
	
	STRUCT NMStatsInputsStruct si
	
	if ( NMStatsInputsGet( si ) < 0 )
		return 0
	endif
	
	STRUCT NMStatsOutputsStruct so
	
	if ( NMStatsOutputsGet( so ) < 0 )
		return 0
	endif
	
	Variable currentChan = CurrentNMChannel()
	
	String formatStr = z_PrecisionStr()
	
	CheckStatsWindowSelect()
	
	select = StatsAmpSelectGet( -1 )
	
	if ( StringMatch( select, "Off" ) )
		off = 1
		dis2 = 2
	endif
	
	SetVariable ST_AmpBSet, win=$NMPanelName, disable=dis2, format=formatStr
	SetVariable ST_AmpESet, win=$NMPanelName, disable=dis2, format=formatStr
	
	select =	StatsAmpMenuSwitch( select )
	
	sprintf sp.yStr, formatStr, so.y
	
	tstr = " "
	
	if ( si.filterNum > 0 )
		tstr = "s ="
	endif
	
	SetVariable ST_FilterASet, win=$NMPanelName, title=tstr, disable=dis2
	
	tstr = "filter"
	
	strswitch( si.filterFxn )
	
		case "binomial":
		case "boxcar":
			tstr = "smooth"
			break
			
		case "low-pass":
		case "high-pass":
			tstr = "filter"
			break
			
	endswitch
	
	SetVariable ST_FilterNSet, win=$NMPanelName, title=tstr, disable=dis2, format=formatStr
	
	if ( si.onB && !off )
		sprintf tstr, "bsln (" + si.selectB + ", %.1f, %.1f)", ( si.xbgnB ), ( si.xendB )
		CheckBox ST_Baseline, win=$NMPanelName, disable=0, value=1, title= " "
		SetVariable ST_BslnWin, win=$NMPanelName, disable=0
		SetVariable ST_BslnSet, win=$NMPanelName, disable=0, format=formatStr
	else
		tstr = "baseline"
		CheckBox ST_Baseline, win=$NMPanelName, disable=dis2, value=0, title=" "
		SetVariable ST_BslnWin, win=$NMPanelName, disable=dis2
		SetVariable ST_BslnSet, win=$NMPanelName, disable=1, format=formatStr
	endif
	
	sp.xBStr = tstr
	
	SetNMstr( NMStatsDF+"TransformStr", si.transform )
	
	tList = StringFromList( 0, si.transform, ";" )
	transform = StringFromList( 0, tList, "," )
	
	if ( WhichListItem( transform, NMChanTransformList ) >= 0 )
		CheckBox ST_Transform, win=$NMPanelName, value=1, disable=dis2, title=transform
	else
		CheckBox ST_Transform, win=$NMPanelName, value=0, disable=dis2, title="transform"
	endif
	
	if ( WaveExists( $NMStatsOffsetWaveName( sp.winSelect ) ) )
		CheckBox ST_Offset, win=$NMPanelName, value=1, disable=dis2, title="x-offset = " + num2str( StatsOffsetValue( sp.winSelect ) )
	else
		CheckBox ST_Offset, win=$NMPanelName, value=0, disable=dis2, title="x-offset"
	endif
	
	xtl = "x ="
	ytl = "y ="
		
	strswitch( select )
	
		case "Max":
		case "Min":
			break
			
		case "Avg":
		case "Median":
		case "SDev":
		case "SEM":
		case "Var":
		case "RMS":
		case "NumPnts":
		case "Area":
		case "Sum":
		case "PathLength":
			xdis = 1
			break
			
		case "Avg+SDev":
		case "Avg+SEM":
			xtl = "s ="
			break
			
		case "Level":
		case "Level+":
		case "Level-":
			yframe = 1
			break
			
		case "Slope":
		case "RTslope":
		case "RTslope ":
			xtl = "b ="
			ytl = "m ="
			break
			
		case "RiseTime":
		case "RiseTime ":
			sp.yStr = num2str( si.risePB ) + " - " + num2str( si.risePE ) + "%"
			yframe = 1
			break
			
		case "DecayTime":
		case "DecayTime ":
			sp.yStr = num2str( si.decayP ) + "%"
			yframe = 1
			break
			
		case "FWHM":
		case "FWHM ":
			sp.yStr = "50 - 50%"
			break
			
		case "Off":
			dis = 1
			break
			
		default:
		
			if ( z_IsMaxMinAvg( select ) )
				select = select[ 0, 5 ]
				maxMinAvgWin = StatsMaxMinWinGet( sp.winSelect )
				xtl = "w ="
				xframe = 1
			endif
			
	endswitch
	
	SetVariable ST_AmpYSet, win=$NMPanelName, title=ytl, frame=yframe, disable=dis
	SetVariable ST_AmpXSet, win=$NMPanelName, title=xtl, frame=xframe, format=formatStr, disable=(dis||xdis)
	
	modenum = 1 + WhichListItem( select, NMStatsFxnList(), ";", 0, 0 )
	
	PopupMenu ST_AmpSelect, win=$NMPanelName, value = NMStatsFxnList(), mode = modeNum // reset menu display mode
	
	UpdateNMStatsWinSelect()
	
	DoWindow /F $NMPanelName // bring panel to front for more input
	
	sp.xbgn = si.xbgn
	sp.xend = si.xend
	sp.filterNum = si.filterNum
	sp.filterFxn = si.filterFxn
	
	if ( numtype( maxMinAvgWin ) == 0 )
		sp.x = maxMinAvgWin
	else
		sp.x = so.x
	endif

	sp.y = so.y
	sp.yB = so.yB
	
	return 0

End // UpdateStats1

//****************************************************************
//****************************************************************

Function /S NMStatsFxnList()

	String fList = StatsFxnList
	
	fList = ReplaceString( "Off;", fList, "Off;---;" )
	fList = ReplaceString( "RiseTime+;", fList, " ;--- Pos Peaks ---;RiseTime;" )
	fList = ReplaceString( "RTslope+;", fList, "RTslope;" )
	fList = ReplaceString( "DecayTime+;", fList, "DecayTime;" )
	fList = ReplaceString( "FWHM+;", fList, "FWHM;" )
	fList = ReplaceString( "RiseTime-;", fList, " ;--- Neg Peaks ---;RiseTime ;" ) // WARNING, leave space after entry here!
	fList = ReplaceString( "RTslope-;", fList, "RTslope ;" ) // WARNING, leave space after entry here!
	fList = ReplaceString( "DecayTime-;", fList, "DecayTime ;" ) // WARNING, leave space after entry here!
	fList = ReplaceString( "FWHM-;", fList, "FWHM ;" ) // WARNING, leave space after entry here!
	
	return fList
	
End // NMStatsFxnList

//****************************************************************
//****************************************************************

Function UpdateNMStatsWinSelect()

	Variable ampNV = NumVarOrDefault( NMStatsDF + "AmpNV", 0 )

	PopupMenu ST_WinSelect, value=NMStatsWinMenu(), mode=( ampNV+1 ), win=$NMPanelName

End // UpdateNMStatsWinSelect

//****************************************************************
//****************************************************************

Function /S NMStatsWinMenu()

	return NMStatsWinList( 0, "Win" ) + ";---;More / Less;Reset All;Edit All Inputs;Edit All Outputs;"

End // NMStatsWinMenu

//****************************************************************
//****************************************************************

Function UpdateStats2()

	Variable md
	String wName, folder, df = NMStatsDF
	
	String formatStr = z_PrecisionStr()
	
	String errorType = NMStatsStrGet( "DisplayError" )
	
	Variable allFxn2 = NMStatsVarGet( "ST_2FxnAll" )
	
	STRUCT NMStatsParamStruct sp
	NMStatsParamRef( sp )
	
	CheckNMStats2FolderWaveSelect()

	folder = CurrentNMStats2FolderSelect( 0 )
	wName = CurrentNMStats2WaveSelect( 0 )
	
	if ( NMVarGet( "ConfigsDisplay" ) > 0 )
		return 0
	endif
	
	if ( !DataFolderExists( df ) || !IsCurrentNMTab( "Stats" ) )
		return 0
	endif
	
	md = 1 + WhichListItem( folder, NMStats2FolderMenu() )
	
	PopupMenu ST_2FolderSelect, win=$NMPanelName, value=NMStats2FolderMenu(), mode=max(1,md)
	
	md = 1 + WhichListItem( wName, NMStats2WaveMenu() )
		
	PopupMenu ST_2WaveSelect, win=$NMPanelName, value = NMStats2WaveMenu(), mode=max(1,md)
	
	if ( allFxn2 )
		PopupMenu ST_2FxnSelect, win=$NMPanelName, value = NMStats2AllFxnList, mode=1
	else
		PopupMenu ST_2FxnSelect, win=$NMPanelName, value = NMStats2FxnList, mode=1
	endif
	
	CheckBox ST_2FxnAll, win=$NMPanelName, value = allFxn2
	
	SetVariable ST_2AvgSet, win=$NMPanelName, format=formatStr
	
	if ( StringMatch( errorType, "SEM" ) )
		SetVariable ST_2SDVSet, win=$NMPanelName, format=formatStr, value=sp.sem
	else
		SetVariable ST_2SDVSet, win=$NMPanelName, format=formatStr, value=sp.stdv
	endif
	
	NMStatsWaveStats( wList = wName, outputSelect = 3 )
	
	DoWindow /F $NMPanelName // brings back to front for more input
	
	return 0

End // UpdateStats2

//****************************************************************
//****************************************************************

Static Function /S z_PrecisionStr()

	Variable precision = NMStatsVarGet( "DisplayPrecision" )
	
	precision = max( precision, 1 )
	precision = min( precision, 5 )

	return "%." + num2istr( precision ) + "f"

End // z_PrecisionStr

//****************************************************************
//****************************************************************

Function /S NMStats2FolderMenu()

	String folderMenu = "Folder Select;---;" + NMStats2FolderList( 1 )
	
	String m0 = NMStats2FolderList( 0 )
	
	folderMenu = NMAddToList( m0, folderMenu, ";" )
	
	if ( !StringMatch( CurrentNMStats2FolderSelect( 0 ), GetDataFolder( 0 ) ) )
		folderMenu += "---;Delete Stats Subfolder;"
	endif
	
	return folderMenu

End // NMStats2FolderMenu

//****************************************************************
//****************************************************************

Function /S NMStats2WaveMenu()

	String wList = NMStats2WaveSelectList( 0 )
	
	if ( ItemsInList( wList ) == 0 )
		return "No Stats Waves;---;Change This List;"
	endif
	
	return "Wave Select;---;" + NMStats2WaveSelectList( 0 ) + "---;Change This List;"

End // NMStats2WaveMenu

//****************************************************************
//****************************************************************

Function NMStatsButton( ctrlName ) : ButtonControl
	String ctrlName
	
	ctrlName = ReplaceString( "ST_", ctrlName, "" )
	
	StatsCall( ctrlName, "" )
	
End // NMStatsButton

//****************************************************************
//****************************************************************

Function NMStatsCheckBox( ctrlName, checked ) : CheckBoxControl
	String ctrlName; Variable checked
	
	ctrlName = ReplaceString( "ST_", ctrlName, "" )
	
	StatsCall( ctrlName, num2istr( checked ) )
	
End // NMStatsCheckBox

//****************************************************************
//****************************************************************

Function NMStatsTransformCheckBox( ctrlName, checked ) : CheckBoxControl
	String ctrlName; Variable checked
	
	StatsCall( "Transform", num2istr( checked ) )
	
End // NMStatsTransformCheckBox

//****************************************************************
//****************************************************************

Function NMStatsSetVariable( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	ctrlName = ReplaceString( "ST_", ctrlName, "" )
	
	StatsCall( ctrlName, varStr )
	
End // NMStatsSetVariable

//****************************************************************
//****************************************************************

Function NMStatsSetFilter( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	StatsCall( "FilterNSet", varStr )
	
End // NMStatsSetFilter

//****************************************************************
//****************************************************************

Function NMStatsAmpPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	strswitch( popStr )
	
		case "---":
		case " ":
		case "--- Pos Peaks ---":
		case "--- Neg Peaks ---":
			break
			
		default:
		
			popStr = StatsAmpMenuSwitch( popStr )
			
			return z_FxnCall( popStr )
	
	endswitch
	
	UpdateStats1()

End // NMStatsAmpPopup

//****************************************************************
//****************************************************************

Function NMStatsWinPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	Variable win
	
	strswitch( popStr )
	
		case "---":
			break
	
		case "Edit All Inputs":
			NMStatsWinTableCall( "inputs" )
			break
			
		case "Edit All Outputs":
			NMStatsWinTableCall( "outputs" )
			break
			
		case "Reset All":
			NMStatsWavesReset( history = 1 )
			break
			
			
		case "More / Less":
			StatsNumWindowsCall()
			break
			
		default:
		
			win = str2num( popStr[ 3, inf ] )
			
			if ( numtype( win ) == 0 )
				return NMStatsSet( winSelect = win, history = 1 )
			endif
			
	endswitch
	
	UpdateNMStatsWinSelect()
	
End // NMStatsWinPopup

//****************************************************************
//****************************************************************

Function NMStats2FolderSelectPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	ctrlName = ReplaceString( "ST_", ctrlName, "" )
		
	strswitch( popStr )

		case "Folder Select":
		case "---":
			break
		
		case "Clear Stats Subfolder":
		case "Delete Stats Subfolder":
			NMStats2Call( popStr, "" )
			break
			
		default:
			NMStats2Call( ctrlName, popStr )
			
	endswitch
	
	UpdateStats2()

End // NMStats2FolderSelectPopup

//****************************************************************
//****************************************************************

Function NMStats2WaveSelectPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	ctrlName = ReplaceString( "ST_", ctrlName, "" )
	
	strswitch( popStr )

		case "Wave Select":
		case "No Stats Waves":
		case "---":
			break
			
		case "Change This List":
			NMStats2WaveSelectFilterCall()
			return 0
			
		default:
			NMStats2Call( ctrlName, popStr )
			
	endswitch		
	
	UpdateStats2()

End // NMStats2WaveSelectPopup

//****************************************************************
//****************************************************************

Function NMStats2FxnSelectPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	ctrlName = ReplaceString( "ST_", ctrlName, "" )
		
	PopupMenu ST_2FxnSelect, win=$NMPanelName, mode=1

	strswitch( popStr )
	
		case "Functions":
		case "---":
			break
			
		default:
			NMStats2Call( popStr, "" )
			
	endswitch
	
	UpdateStats2()

End // NMStats2FxnSelectPopup

//****************************************************************
//****************************************************************

Function NMStats2CheckBox( ctrlName, checked ) : CheckBoxControl
	String ctrlName; Variable checked
	
	ctrlName = ReplaceString( "ST_", ctrlName, "" )
	
	NMStats2Call( ctrlName, "" )
	
End // NMStats2CheckBox

//****************************************************************
//****************************************************************

Function /S StatsAmpMenuSwitch( select )
	String select
	Variable direction

	strswitch( select )
	
		case "RiseTime+":
			return "RiseTime"
		case "RiseTime-":
			return "RiseTime "
		case "RTslope+":
			return "RTslope"
		case "RTslope-":
			return "RTslope "
		case "DecayTime+":
			return "DecayTime"
		case "DecayTime-":
			return "DecayTime "
		case "FWHM+":
			return "FWHM"
		case "FWHM-":
			return "FWHM "
			
		case "RiseTime":
			return "RiseTime+"
		case "RiseTime ": // extra space at end
			return "RiseTime-"
		case "RTslope":
			return "RTslope+"
		case "RTslope ": // extra space at end
			return "RTslope-"
		case "DecayTime":
			return "DecayTime+"
		case "DecayTime ": // extra space at end
			return "DecayTime-"
		case "FWHM":
			return "FWHM+"
		case "FWHM ": // extra space at end
			return "FWHM-"
			
	endswitch
	
	return select
	
End // StatsAmpMenuSwitch

//****************************************************************
//****************************************************************
//
//		Set Global Variables, Strings and Waves
//
//****************************************************************
//****************************************************************

Static Function z_FxnCall( fxn )
	String fxn
	
	Variable avgWin, level
	
	strswitch( fxn )
		
		case "MaxAvg":
			avgWin = z_MaxMinWinAvgPrompt( fxn )
			NMStatsSet( maxAvgWin = avgWin, history = 1 )
			break
			
		case "MinAvg":
			avgWin = z_MaxMinWinAvgPrompt( fxn )
			NMStatsSet( minAvgWin = avgWin, history = 1 )
			break
			
		case "Level":
			level = z_LevelPrompt( fxn )
			NMStatsSet( level = level, history = 1 )
			break
			
		case "Level+":
			level = z_LevelPrompt( fxn )
			NMStatsSet( levelPos = level, history = 1 )
			break
			
		case "Level-":
			level = z_LevelPrompt( fxn )
			NMStatsSet( levelNeg = level, history = 1 )
			break
			
		default:
		
			if ( z_IsRiseTime( fxn ) )
				return z_RiseTimeCall( fxn )
			endif
			
			if ( z_IsDecayTime( fxn ) )
				return z_DecayTimeCall( fxn )
			endif
			
			NMStatsSet( fxn = fxn, history = 1 )
		
	endswitch
	
End // z_FxnCall

//****************************************************************
//****************************************************************

Static Function /S z_CheckFxn( fxn )
	String fxn
	
	Variable avgWin
	
	if ( z_IsMaxMinAvg( fxn ) )
	
		avgWin = str2num( fxn[ 6, inf ] )
			
		if ( numtype( avgWin ) == 0 )
		
			return fxn
			
		else
		
			avgWin = z_MaxMinWinAvgPrompt( fxn )
			
			if ( numtype( avgWin ) == 0 )
				return fxn[ 0, 5 ] + num2str( avgWin )
			else
				return ""
			endif
			
		endif
			
	endif
	
	if ( WhichListItem( fxn, StatsFxnList, ";", 0, 0 ) == -1 )
			return ""
	endif
	
	return fxn
	
End // z_CheckFxn

//****************************************************************
//****************************************************************

Static Function z_CheckFxnBaseline( win )
	Variable win
	
	String fxn = StatsAmpSelectGet( win )
	
	strswitch( fxn )
	
		case "Off":
			return 0
	
		case "RiseTime+":
		case "RiseTime-":
		case "RTslope+":
		case "RTslope-":
		case "FWHM+":
		case "FWHM-":
		case "DecayTime+":
		case "DecayTime-":
			return 1
	
	endswitch
	
	return NaN
	
End // z_CheckFxnBaseline

//****************************************************************
//****************************************************************

Static Function z_CheckXbgn( xbgn )
	Variable xbgn
	
	if ( numtype( xbgn ) > 0 )
		return -inf
	else
		return xbgn
	endif
	
End // z_CheckXbgn

//****************************************************************
//****************************************************************

Static Function z_CheckXend( xend )
	Variable xend
	
	if ( numtype( xend ) > 0 )
		return inf
	else
		return xend
	endif
	
End // z_CheckXend

//****************************************************************
//****************************************************************

Function StatsCall( fxn, select )
	String fxn, select
	
	Variable error
	Variable snum = str2num( select )
	String fxn2
	
	strswitch( fxn )
			
		case "AmpBSet":
			error = NMStatsSet( xbgn = snum, history = 1 )
			break
			
		case "AmpESet":
			error = NMStatsSet( xend = snum, history = 1 )
			break
			
		case "AmpYSet":
		
			fxn2 = StatsAmpSelectGet( -1 )
		
			strswitch( fxn2 )
			
				case "Level":
					error = NMStatsSet( level = snum, history = 1 )
					break
					
				case "Level+":
					error = NMStatsSet( levelPos = snum, history = 1 )
					break
					
				case "Level-":
					error = NMStatsSet( levelNeg = snum, history = 1 )
					break
					
				case "RiseTime+":
				case "RiseTime-":
					return z_RiseTimeCall( fxn2 )
					
				case "DecayTime+":
				case "DecayTime-":
					return z_DecayTimeCall( fxn2 )
				
			endswitch
			
			break
			
		case "AmpXSet":
		
			fxn2 = StatsAmpSelectGet( -1 )
		
			strswitch( fxn2[ 0, 5 ] )
			
				case "MaxAvg":
					error = NMStatsSet( maxAvgWin = snum, history = 1 )
					break
					
				case "MinAvg":
					error = NMStatsSet( minAvgWin = snum, history = 1 )
					break
			
			endswitch
			
			break
			
		case "SmthNSet":
		case "FilterNSet":
			error = z_FilterCall( "old", snum )
			break
			
		case "SmthASet":
		case "FilterASet":
			error = z_FilterCall( select, -1 )
			break
	
		case "Baseline":
			error = z_BaselineCall( snum, Nan, Nan )
			break
			
		case "BslnWin":
			error = z_BaselineCallStr( select )
			break
			
		case "Ft":
		case "Transform":
			error = z_TransformCall( snum )
			break
	
		case "Offset":
			error = StatsOffsetWinCall( snum )
			break
			
		case "AllWaves":
		case "All Waves":
			error = z_AllWavesCall()
			break
			
		default:
			error = 20
			NM2Error( error, "fxn", fxn )
			
	endswitch
	
	if ( error != 0 )
		UpdateStats1()
	endif
	
	return error
	
End // StatsCall

//****************************************************************
//****************************************************************

Function StatsTimeStamp( df ) // place time stamp on AmpSlct
	String df
	
	String wName = df + "AmpSlct"
	
	if ( !DataFolderExists( df ) )
		return NM2Error( 30, "df", df )
	endif
	
	if ( !WaveExists( $wName ) )
		return NM2Error( 1, "wName", wName )
	endif
	
	Note /K $wName
	Note $wName, "Stats Date:" + date()
	Note $wName, "Stats Time:" + time()
	
	return 0

End // StatsTimeStamp

//****************************************************************
//****************************************************************

Function StatsTimeStampCompare( df1, df2 )
	String df1, df2
	Variable ok
	
	Variable icnt
	String d1, d2, t1, t2, wName1, wName2
	
	df1 = LastPathColon( df1, 1 )
	df2 = LastPathColon( df2, 1 )
	
	wName1 = df1 + "AmpSlct"
	wName2 = df2 + "AmpSlct"
	
	if ( !DataFolderExists( df1 ) )
		return 0
	endif
	
	if ( !DataFolderExists( df2 ) )
		return 0
	endif
	
	if ( !WaveExists( $wName1 ) )
		return 0
	endif
	
	if ( !WaveExists( $wName2 ) )
		return 0
	endif
	
	d1 = NMNoteStrByKey( wName1, "Stats Date" )
	t1 = NMNoteStrByKey( wName1, "Stats Time" )
	
	t2 = NMNoteStrByKey( wName2, "Stats Time" )
	d2 = NMNoteStrByKey( wName2, "Stats Date" )
	
	if ( ( strlen( d1 ) == 0 ) || ( strlen( t1 ) == 0 ) )
		StatsTimeStamp( df1 )
		ok = 1
	endif
	
	if ( ( strlen( d2 ) == 0 ) || ( strlen( t2 ) == 0 ) )
		StatsTimeStamp( df2 )
		ok = 1
	endif
	
	if ( ok )
		return 1
	endif
	
	Wave /T wtemp1 = $wName1
	Wave /T wtemp2 = $wName2
	
	for ( icnt = 0 ; icnt < numpnts( wtemp1 ) ; icnt += 1 )
		
		if ( !StringMatch( wtemp1[ icnt ], wtemp2[ icnt ] ) )
			return 0 // not equal
		endif
	
	endfor
	
	if ( StringMatch( d1, d2 ) && StringMatch( t1, t2 ) )
		return 1 // equal
	endif
	
	return 0 // not equal

End // StatsTimeStampCompare

//****************************************************************
//****************************************************************

Function StatsChanCheck() // check to see if current channel has changed

	Variable currentChan = CurrentNMChannel()
	
	String wName = NMStatsDF + "ChanSelect"
	
	if ( !WaveExists( $wName ) || ( numpnts( $wName ) == 0 ) )
		return 0 // nothing to do
	endif
	
	Wave wtemp = $wName

	if ( wtemp[ 0 ] != currentChan )
		StatsChan( -1, currentChan )
	endif
	
	return 0
	
End // StatsChanCheck

//****************************************************************
//****************************************************************

Function StatsChanCall( chanNum )
	Variable chanNum // channel number
	
	return StatsChan( -1, chanNum, history = 1 )
	
End // StatsChanCall

//****************************************************************
//****************************************************************

Function StatsChan( win, chanNum [ history ] )
	Variable win // Stats window number ( -1 ) for currently selected window
	Variable chanNum // channel number
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	String vlist = ""
	String df = NMStatsDF
	String wName = df + "ChanSelect"
	
	if ( history )
		vlist = NMCmdNum( win, vlist, integer = 1 )
		vlist = NMCmdNum( chanNum, vlist, integer = 1 )
		NMCommandHistory( vlist )
	endif
	
	CheckNMWaveOfType( wName, NMStatsNumWindowsDefault(), CurrentNMChannel(), "R" )
	
	if ( !WaveExists( $wName ) )
		return NM2Error( 1, "wName", wName )
	endif
	
	win = CheckNMStatsWin( win )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	if ( ( numtype( chanNum ) > 0 ) || ( chanNum < 0 ) || ( chanNum >= NMNumChannels() ) )
		//return NM2Error( 10, "chanNum", num2istr( chanNum ) )
		return -1
	endif
	
	//SetNMwave( wName, win, chanNum )
	Wave wtemp = $wName
	
	wtemp = chanNum // for now, only allow one channel to be selected
	
	NMStatsAuto( force = 1 )
	StatsTimeStamp( df )
	
	return 0

End // StatsChan

//****************************************************************
//****************************************************************

Function StatsChanSelect( win )
	Variable win // Stats window number ( -1 ) for currently selected window
	
	Variable currentChan = CurrentNMChannel()
	
	String wName = NMStatsDF + "ChanSelect"
	
	if ( !WaveExists( $wName ) || ( numpnts( $wName ) == 0 ) )
		return currentChan
	endif
	
	//win = CheckNMStatsWin( "StatsChanSelect", win )
	
	//if ( numtype( win ) > 0 )
		//return -1
	//endif
	
	Wave wtemp = $wName
	
	return wtemp[ 0 ] // for now, return only first channel
	
	//if ( ( win >= 0 ) && ( win < numpnts( wtemp ) ) )
	//	return wtemp[ win ]
	//endif
	
	//return currentChan

End // StatsChanSelect

//****************************************************************
//****************************************************************

Function /S NMStatsWinList( kind, prefix )
	Variable kind // ( 0 ) all available ( 1 ) all windows that are not "Off"
	String prefix // "Win" or ""
	
	Variable icnt
	String select, wList = ""
	
	for ( icnt = 0; icnt < StatsNumWindows(); icnt += 1 )
	
		select = StatsAmpSelectGet( icnt )
	
		if ( kind == 0 )
			wList = AddListItem( prefix + num2istr( icnt ), wList, ";", inf )
		elseif ( ( strlen( select ) > 0 ) && !StringMatch( select, "Off" ) )
			wList = AddListItem( prefix + num2istr( icnt ), wList, ";", inf )
		endif
		
	endfor
	
	return wList
	
End // NMStatsWinList

//****************************************************************
//****************************************************************

Function StatsWinCount() // number of windows that are not off
	
	return ItemsInList( NMStatsWinList( 1, "" ) )

End // StatsWinCount

//****************************************************************
//****************************************************************

Function CheckStatsWindowSelect()

	STRUCT NMStatsParamStruct sp
	NMStatsParamRef( sp )
	
	if ( ( sp.winSelect < 0 ) || ( sp.winSelect >= StatsNumWindows() ) )
		sp.winSelect = 0
	endif

End // CheckStatsWindowSelect

//****************************************************************
//****************************************************************

Function StatsNumWindowsCall()

	Variable numWindows = StatsNumWindows()
	
	Prompt numWindows, "number of measurement windows:"
	DoPrompt "Stats1", numWindows
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	return NMStatsSet( numWindows = numWindows, history = 1 )
	
End // StatsNumWindowsCall

//****************************************************************
//****************************************************************

Function /S NMStatsWinTableName( select )
	String select // ( "inputs" ) input params ( "outputs" ) output params
	
	strswitch( select )
	
		case "inputs":
			 return "ST_InputParams"
			 
		case "outputs":
			return "ST_OutputParams"
			
	endswitch
	
	return ""
	
End // NMStatsWinTableName

//****************************************************************
//****************************************************************

Function /S NMStatsWinTableCall( select )
	String select 

	return NMStatsWinTable( select, history = 1 )

End // NMStatsWinTableCall

//****************************************************************
//****************************************************************

Function /S NMStatsWinTable( select [ history ] )
	String select // ( "inputs" ) input params ( "outputs" ) output params
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	String tName, title, vlist = "", df = NMStatsDF
	
	STRUCT Rect w
	
	NMOutputListsReset()
	
	vlist = NMCmdStr( select, vlist )
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	tName = NMStatsWinTableName( select )
	
	strswitch( select )
	
		case "inputs":
			 title = "Stats1 Window Inputs"
			 break
			 
		case "outputs":
			title = "Stats1 Window Outputs"
			break
			
		default:
			return NM2ErrorStr( 20, "select", select )
			
	endswitch
	
	if ( strlen( tName ) == 0 )
		return ""
	endif
	
	if ( WinType( tName ) == 0 )
		NMWinCascadeRect( w )
		Edit /K=1/N=$tName/W=(w.left,w.top,w.right,w.bottom) as title
		ModifyTable /W=$tName title( Point )="Window"
	else
		DoWindow /F $tName
	endif
	
	if ( WinType( tName ) == 0 )
		return ""
	endif
	
	strswitch( select )
	
		case "inputs":
		
			STRUCT NMStatsInputWavesStruct si
			NMStatsInputWavesStructRef( si )
		
			SetWindow $tName hook(StatsTableHook)=NMStatsWinTableHook
		
			AppendToTable /W=$tName si.select, si.xbgn, si.xend, si.level
			AppendToTable /W=$tName si.onB, si.selectB, si.xbgnB, si.xendB, si.subtractB
			AppendToTable /W=$tName si.risePB, si.risePE, si.decayP
			AppendToTable /W=$tName si.filterNum, si.filterFxn, si.transform, si.offset
			
			break
			
		case "outputs":
		
			STRUCT NMStatsOutputWavesStruct so
			NMStatsOutputWavesStructRef( so )
			
			AppendToTable /W=$tName so.x, so.y, so.xB, so.yB
			AppendToTable /W=$tName so.riseXB, so.riseXE, so.riseT
			AppendToTable /W=$tName so.decayX, so.decayT
			break
			
	endswitch
	
	SetNMstr( NMDF + "OutputWinList", tName )
	
	return tName

End // NMStatsWinTable

//****************************************************************
//****************************************************************

Function NMStatsWinTableHook( s )
	STRUCT WMWinHookStruct &s
	
	switch( s.eventCode )
	
		case 1:
		case 2:
			CheckNMStatsWaves( 0, errorAlert = 1 )
			break
			
		case 11:
		
			if ( s.keycode == 13 )
				Execute /P/Q/Z "NMStatsWinTableExecute()"
			endif
			
			break

	endswitch
	
	return 0

End // NMStatsWinTableHook

//****************************************************************
//****************************************************************

Function NMStatsWinTableExecute()

	CheckNMStatsWaves( 0, errorAlert = 1 )
	NMStatsAuto( force = 1 )
	
	return 0

End // NMStatsWinTableExecute

//****************************************************************
//****************************************************************

Function StatsAmpWinBegin() // find a Stats window that is on

	Variable icnt, xbgn, xend, currentChan
	String select, df = NMStatsDF
	
	STRUCT NMStatsParamStruct sp
	NMStatsParamRef( sp )
	
	select = StatsAmpSelectGet( sp.winSelect )
	
	if ( ( strlen( select ) > 0 ) && !StringMatch( select, "Off" ) )
		return 0 // stats window has already been defined
	endif
	
	for ( icnt = 0; icnt < numpnts( $df+"AmpSlct" ); icnt += 1 ) // look for next available
		
		if ( !StringMatch( StatsAmpSelectGet( icnt ), "Off" ) )
			sp.winSelect = icnt
			return 0
		endif
		
	endfor
	
	// nothing defined yet, set default values for first window
	
	currentChan = CurrentNMChannel()
	xend = floor( rightx( $ChanDisplayWave( -1 ) ) )
	
	//if ( ( numtype( xend ) > 0 ) || ( xend == 0 ) )
		xbgn = -inf	
		xend = inf
	//else
	//	xbgn = floor( xend / 4 )
	//	xend = floor( xend / 2 )
	//endif
	
	sp.winSelect = 0
		
	//SetNMwave( df+"ChanSelect", sp.winSelect, chan )
	//SetNMtwave( df+"Transform", sp.winSelect, NMChanTransformGet( currentChan, list = 1 ) )
	//SetNMwave( df+"FilterNum", sp.winSelect, ChanFilterNumGet( currentChan ) )
	//SetNMtwave( df+"FilterAlg", sp.winSelect, ChanFilterAlgGet( currentChan ) )
	
	SetNMtwave( df+"AmpSlct", sp.winSelect, "Max" )
	SetNMwave( df+"AmpB", sp.winSelect, xbgn )
	SetNMwave( df+"AmpE", sp.winSelect, xend )
	
	xbgn = NumVarOrDefault( NMMainDF+"Bsln_Bgn", NMBaselineXend )
	xend = NumVarOrDefault( NMMainDF+"Bsln_End", floor( xend / 5 ) )

	SetNMwave( df+"Bflag", sp.winSelect, 0 )
	SetNMtwave( df+"BslnSlct", sp.winSelect, "Avg" )
	SetNMwave( df+"BslnB", sp.winSelect, xbgn )
	SetNMwave( df+"BslnE", sp.winSelect, xend )
	SetNMwave( df+"BslnSubt", sp.winSelect, 0 )

End // StatsAmpWinBegin

//****************************************************************
//****************************************************************

Function /S StatsAmpSelectGet( win )
	Variable win // Stats window number ( -1 ) for currently selected window
	
	win = CheckNMStatsWin( win )
	
	if ( numtype( win ) > 0 )
		return "Off"
	endif
	
	STRUCT NMStatsInputsStruct si
	
	if ( NMStatsInputsGet( si, win = win ) < 0 )
		return "Off"
	endif
	
	if ( strlen( si.select ) == 0 )
		return "Off"
	endif
	
	if ( StringMatch( si.select[ 0, 2 ], "Off" ) )
		return "Off"
	else
		return si.select
	endif
	
End // StatsAmpSelectGet

//****************************************************************
//****************************************************************

Static Function z_LevelPrompt( fxn )
	String fxn // "Level", "Level+" or "Level-"
	
	Variable level
	
	STRUCT NMStatsOutputsStruct so
	
	if ( NMStatsOutputsGet( so ) < 0 )
		return -1
	endif
	
	level = so.y
	
	if ( numtype( level ) > 0 )
		level = 1
	endif
	
	Prompt level, NMPromptAddUnitsY( "level detection value" )
	DoPrompt "Stats " + fxn + " Computation", level
			
	return level

End // z_LevelPrompt

//****************************************************************
//****************************************************************

Static Function z_MaxMinWinAvgPrompt( fxn )
	String fxn // "MaxAvg" or "MinAvg"
	
	Variable avgWin = StatsMaxMinWinGet( -1 )
		
	if ( ( numtype( avgWin ) > 0 ) || ( avgWin <= 0 ) )
		avgWin = 1
	endif

	strswitch ( fxn )
	
		case "MaxAvg":
			Prompt avgWin, NMPromptAddUnitsX( "window to average around detected max value" )
			DoPrompt "Stats Max Average Computation", avgWin
			break
			
		case "MinAvg":
			Prompt avgWin, NMPromptAddUnitsX( "window to average around detected min value" )
			DoPrompt "Stats Min Average Computation", avgWin
			break
			
	endswitch
	
	if ( numtype( avgWin ) > 0 )
		return 1
	else
		return avgWin
	endif

End // z_MaxMinWinAvgPrompt

//****************************************************************
//****************************************************************

Function StatsMaxMinWinGet( win )
	Variable win // Stats window number ( -1 ) for currently selected window
	
	String fxn
	
	win = CheckNMStatsWin( win )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	fxn = StatsAmpSelectGet( win )
	
	if ( z_IsMaxMinAvg( fxn ) )
		return str2num( fxn[ 6, inf ] )
	else
		return NaN
	endif

End // StatsMaxMinWinGet

//****************************************************************
//****************************************************************

Static Function z_IsMaxMinAvg( fxn )
	String fxn
	
	if ( StringMatch( fxn[ 0, 5 ], "MaxAvg" ) || StringMatch( fxn[ 0, 5 ], "MinAvg" ) )
		return 1
	else
		return 0
	endif
	
End // z_IsMaxMinAvg

//****************************************************************
//****************************************************************

Static Function z_FilterCall( filterFxn, filterNum )
	String filterFxn
	Variable filterNum
	
	STRUCT NMStatsInputsStruct si
	
	if ( NMStatsInputsGet( si ) < 0 )
		return -1
	endif
	
	if ( filterNum == -1 )
		filterNum = si.filterNum
	endif
	
	strswitch( filterFxn )
	
		case "old":
			filterFxn = si.filterFxn
			break
			
		case "binomial":
		case "boxcar":
			break
			
		case "low-pass":
		case "high-pass":
			break
			
		default: // ERROR
			filterNum = 0
			filterFxn = ""
			
	endswitch
	
	if ( ( strlen( filterFxn ) == 0 ) && ( filterNum > 0 ) )
	
		filterFxn = ChanFilterAlgAsk( -1 )
		
		if ( strlen( filterFxn ) == 0 )
			filterNum = 0
		endif
		
	endif
	
	if ( filterNum > 0 )
		return NMStatsSet( filterFxn = filterFxn, filterNum = filterNum, history = 1 )
	else
		return NMStatsSet( filterNum = 0, history = 1 )
	endif
	
End // z_FilterCall

//****************************************************************
//****************************************************************

Static Function z_BaselineCallStr( bslnStr )
	String bslnStr
	
	Variable icnt, jcnt, xbgn = Nan, xend = Nan, last = strlen( bslnStr ) - 1
	
	icnt = strsearch( bslnStr, ": ", 0 )
	jcnt = strsearch( bslnStr, " - ", 0 )
	
	if ( ( icnt < 0 ) || ( jcnt < 0 ) )
		return z_BaselineCall( 1, xbgn, xend )
	endif
	
	xbgn = str2num( bslnStr[ icnt+2, jcnt-1 ] )
	xend = str2num( bslnStr[ jcnt + 3, last ] )
	
	if ( numtype( xend ) > 0 )
	
		for ( icnt = last; icnt < 0; icnt -= 1 )
		
			xend = str2num( bslnStr[ jcnt + 3, icnt ] )
			
			if ( numtype( str2num( bslnStr[ icnt, icnt ] ) ) == 0 )
				break
			endif
			
		endfor
	
	endif
	
	return z_BaselineCall( 1, xbgn, xend )
	
End // z_BaselineCallStr

//****************************************************************
//****************************************************************

Static Function z_BaselineCall( on, xbgn, xend )
	Variable on // ( 0 ) off ( 1 ) on
	Variable xbgn, xend // x-axis window begin and end, ( -inf / inf ) for all
	
	Variable subtract
	String select, fxn = ""
	
	STRUCT NMStatsInputsStruct si
	
	if ( NMStatsInputsGet( si ) < 0 )
		return -1
	endif
	
	Variable win = NumVarOrDefault( NMStatsDF + "AmpNV", 0 )
	
	if ( !on && ( StatsRiseTimeFlag( win ) || StatsDecayTimeFlag( win ) ) )
		on = 1 // baseline must be on
	endif
	
	if ( !on )
		
		return NMStatsSet( bsln = 0, history = 1 )
	
	else
	
		if ( numtype( xbgn ) == 2 )
			xbgn = si.xbgnB
		endif
		
		if ( numtype( xend ) == 2 )
			xend = si.xendB
		endif
		
		if ( ( xbgn == 0 ) && ( xend == 0 ) )
			xbgn = NumVarOrDefault( NMMainDF+"Bsln_Bgn", NMBaselineXbgn )
			xend = NumVarOrDefault( NMMainDF+"Bsln_End", NMBaselineXend )
		elseif ( xbgn == xend )
			xend = xbgn + 10
		endif
		
		subtract = si.subtractB + 1
		
		select = StatsAmpSelectGet( win )
		
		strswitch( select )
			case "SDev":
			case "SEM":
			case "Var":
			case "RMS":
			case "Area":
			case "Sum":
			case "PathLength":
			case "Slope":
				fxn = select
				break
			default:
				fxn = "Avg"
		endswitch
		
		Prompt xbgn, NMPromptAddUnitsX( "x-axis window begin" )
		Prompt xend, NMPromptAddUnitsX( "x-axis window end" )
		Prompt fxn, "baseline measurement:", popup, BslnFxnList
		Prompt subtract, "subtract baseline from y-measurement?", popup, "no;yes"
		DoPrompt "Stats Baseline Window", xbgn, xend, fxn, subtract
	
		if ( V_Flag == 1 )
			return -1 // cancel
		endif
		
		subtract -= 1
		
		return NMStatsSet( bsln = on, xbgn = xbgn, xend = xend, fxn = fxn, bslnSubtract = subtract, history = 1 )
	
	endif
	
End // z_BaselineCall

//****************************************************************
//****************************************************************

Static Function z_IsRiseTime( fxn )
	String fxn
	
	if ( StringMatch( fxn[ 0, 7 ], "RiseTime" ) || StringMatch( fxn[ 0, 6 ], "RTslope" ) )
		return 1
	else
		return 0
	endif
	
End // z_IsRiseTime

//****************************************************************
//****************************************************************

Static Function z_RiseTimeCall( fxn )
	String fxn
	
	Variable pbgn, pend
	
	if ( !z_IsRiseTime( fxn ) )
		return -1
	endif
	
	STRUCT NMStatsInputsStruct si
	
	if ( NMStatsInputsGet( si ) < 0 )
		return -1
	endif

	pbgn = si.risePB
	pend = si.risePE
	
	pbgn = max( pbgn, 0 )
	pbgn = min( pbgn, 100 )
	
	pend = max( pend, 0 )
	pend = min( pend, 100 )
	
	if ( ( numtype( pbgn * pend ) > 0 ) || ( pbgn == pend ) )
		pbgn = RiseTimePbgn
		pend = RiseTimePend
	endif
	
	Prompt pbgn, "% begin:"
	Prompt pend, "% end:"
	DoPrompt "Stats Percent " + fxn, pbgn, pend
	
	if ( V_Flag == 1 )
		return -1 // cancel
	endif
	
	NMStatsSet( fxn = fxn, risePbgn = pbgn, risePend = pend, history = 1 )
	
End // z_RiseTimeCall

//****************************************************************
//****************************************************************

Function StatsRiseTimeFlag( win )
	Variable win // Stats window number ( -1 ) for currently selected window
	
	win = CheckNMStatsWin( win )
	
	STRUCT NMStatsInputsStruct si
	
	if ( NMStatsInputsGet( si, win = win ) < 0 )
		return -1
	endif
	
	strswitch( si.select )
		case "RiseTime+":
		case "RiseTime-":
		case "RTslope+":
		case "RTslope-":
		case "FWHM+":
		case "FWHM-":
			return 1
	endswitch
	
	return 0
	
End // StatsRiseTimeFlag

//****************************************************************
//****************************************************************

Function StatsDecayTimeFlag( win )
	Variable win // Stats window number ( -1 ) for currently selected window
	
	win = CheckNMStatsWin( win )
	
	STRUCT NMStatsInputsStruct si
	
	if ( NMStatsInputsGet( si, win = win ) < 0 )
		return -1
	endif
	
	strswitch( si.select )
		case "DecayTime+":
		case "DecayTime-":
			return 1
	endswitch
	
	return 0
	
End // StatsDecayTimeFlag

//****************************************************************
//****************************************************************

Static Function z_IsDecayTime( fxn )
	String fxn
	
	if ( StringMatch( fxn[ 0, 8 ], "DecayTime" ) )
		return 1
	else
		return 0
	endif
	
End // z_IsDecayTime

//****************************************************************
//****************************************************************

Static Function z_DecayTimeCall( fxn )
	String fxn
	
	Variable percent
	
	STRUCT NMStatsInputsStruct si
	
	if ( NMStatsInputsGet( si ) < 0 )
		return -1
	endif
	
	percent = si.decayP
	
	percent = max( percent, 0 )
	percent = min( percent, 100 )
	
	if ( ( numtype( percent ) > 0 ) )
		percent = DecayTimePercent
	endif
	
	Prompt percent, "% decay:"
	DoPrompt "Stats Percent Decay-Time", percent
	
	if ( V_Flag == 1 )
		return -1 // cancel
	endif
	
	NMStatsSet( fxn = fxn, decayPcnt = percent, history = 1 )
	
End // z_DecayTimeCall

//****************************************************************
//****************************************************************

Static Function z_TransformCall( on )
	Variable on // ( 0 ) off ( 1 ) on
	
	String transform = ""
	
	if ( on )
	
		transform = NMChanTransformAsk( CurrentNMChannel() )
		
		if ( strlen( transform ) == 0 )
			return -1 // cancel
		endif
		
	else
	
		transform = "Off"
	
	endif
	
	return NMStatsSet( transform = transform, history = 1 )

End // z_TransformCall

//****************************************************************
//****************************************************************

Function StatsOffsetWinCall( on )
	Variable on // ( 0 ) off ( 1 ) on
	
	Variable select, table = 1
	String pName, wName, wName2, wList = ""
	String df = NMStatsDF
	
	Variable offsetType = NMStatsVarGet( "OffsetType" )
	Variable baseline = 1 + NMStatsVarGet( "OffsetBsln" )
	
	STRUCT NMStatsParamStruct sp
	NMStatsParamRef( sp )
	
	if ( on )
		
		if ( !NMVarGet( "GroupsOn" ) )
			offsetType = 2
		endif
		
		Prompt offsetType, "offsets pertain to individual:", popup "group numbers;wave numbers;"
		Prompt baseline, "apply offsets to baseline windows as well?", popup "no;yes;"
		
		DoPrompt "Stats Window X-axis Offset", offsetType, baseline
		
		if ( V_flag == 1 )
			return -1 // cancel
		endif
		
		baseline -= 1
		
		SetNMvar( df + "OffsetType", offsetType )
		SetNMvar( df + "OffsetBsln", baseline )
		
		wList = NMStatsOffsetWaveList( offsetType, 0 )
		
		if ( offsetType == 1 )
			wName = "OffsetGroupsWin" + num2str( sp.winSelect )
		else
			wName = "OffsetWavesWin" + num2str( sp.winSelect )
		endif
		
		if ( ItemsInList( wList ) == 0 )
		
			Prompt wName, "enter name for new offset wave (should contain " + NMQuotes( "Offset" ) + "):"
			DoPrompt "Stats Offset Wave", wName
		
		else
		
			wList = " ;" + wList
			wName2 = " "
			
			Prompt wName, "enter name for new offset wave (should contain " + NMQuotes( "Offset" ) + "):"
			Prompt wName2, "or select an existing wave of offset values:", popup wList
			DoPrompt "Stats Offset Wave", wName, wName2
		
		endif
		
		if ( V_flag == 1 )
			return -1 // cancel
		endif
		
		if ( strlen( wName2 ) > 1 )
			wName = wName2
		endif
		
		if ( !StringMatch( wName, "*Offset*" ) )
			NMDoAlert( "Stats Offset Error: bad offset wave name. " + NMStatsOffsetWaveNameAlert() )
			return -1
		endif
		
		if ( !WaveExists( $df+wName ) )
			
			pName = NMStatsOffsetWave( df, wName, offsetType )
		
			if ( !WaveExists( $pName ) )
				return -1 // cancel
			endif
			
		endif
		
		return NMStatsOffset( folder = df, wName = wName, offsetType = offsetType, baseline = baseline, table = table, history = 1 )
		
	endif
	
	// on = 0
	
	select = 1
	
	Prompt select, "select option:", popup "edit current x-offset wave;turn x-offset off;"
	DoPrompt "Stats Window X-axis Offset", select
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	if ( select == 1 )
	
		NMStatsOffsetWaveEdit2( -1 )
	
	elseif ( select == 2 )
		
		return NMStatsOffset( offsetType = 0, history = 1 )
	
	endif

End // StatsOffsetWinCall

//****************************************************************
//****************************************************************

Function NMStatsOffset( [ win, folder, wName, offsetType, baseline, table, history ] )
	Variable win // Stats window number, or nothing for currently selected window
	String folder // data folder, or nothing for current data folder, or ( "_subfolder_" ) for default subfolder
	String wName // wave name, or nothing for no offset
	Variable offsetType // ( 0 ) off ( 1 ) group x-axis offset ( 2 ) wave x-axis offset
	Variable baseline // offset shift includes baseline window ( 0 ) no ( 1 ) yes
	Variable table // display wave in table ( 0 ) no ( 1 ) yes
	Variable history
	
	String tFlag, bFlag, xLabel, yLabel, vlist = "", df = NMStatsDF
	String owName = df + "OffsetW"
	
	if ( ParamIsDefault( win ) )
		win = -1
	endif
	
	win = CheckNMStatsWin( win )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	vlist = NMCmdNumOptional( "win", win, vlist, integer = 1 )
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	else
		vlist = NMCmdStrOptional( "folder", folder, vlist )
	endif
	
	folder = CheckNMStatsFolderPath( folder )
	
	if ( !DataFolderExists( folder ) )
		NM2Error( 30, "folder", folder )
	endif
	
	if ( ParamIsDefault( wName ) )
		wName = ""
	else
		vlist = NMCmdStrOptional( "wName", wName, vlist )
	endif
	
	if ( strlen( wName ) == 0 )
		folder = ""
	endif
	
	if ( ( strlen( wName ) > 0 ) && !WaveExists( $folder + wName ) )
		return NM2Error( 1, "wName", wName )
	endif
	
	if ( ParamIsDefault( offsetType ) )
		offsetType = 0
	else
		vlist = NMCmdNumOptional( "offsetType", offsetType, vlist, integer = 1 )
	endif
	
	if ( ( offsetType != 0 ) && ( offsetType != 1 ) && ( offsetType != 2 ) )
		return NM2Error( 10, "offsetType", num2str( offsetType ) )
	endif
	
	if ( offsetType == 0 )
		folder = ""
		wName = ""
	endif
	
	if ( ParamIsDefault( baseline ) )
		baseline = 1
	else
		vlist = NMCmdNumOptional( "baseline", baseline, vlist, integer = 1 )
	endif
	
	if ( ( baseline != 0 ) && ( baseline != 1 ) )
		return NM2Error( 10, "baseline", num2str( baseline ) )
	endif
	
	if ( ParamIsDefault( table ) )
		table = 0
	else
		vlist = NMCmdNumOptional( "table", table, vlist, integer = 1 )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( strlen( wName ) > 0 )
		
		if ( offsetType == 1 )
			tFlag = "Stats Offset Type:Group"
			xLabel = "Group #"
		else
			tFlag = "Stats Offset Type:Wave"
			xLabel = "Wave #"
		endif
		
		if ( baseline )
			bFlag = NMCR + "Stats Offset Baseline:Yes"
		else
			bFlag = NMCR + "Stats Offset Baseline:No"
		endif
		
		yLabel = NMChanLabelX()
	
		NMNoteType( folder + wName, "NMStats Offset", xLabel, yLabel, tFlag + bFlag )
		
	endif
	
	SetNMtwave( owName, win, folder + wName )
	
	NMStatsAuto( force = 1 )
	StatsTimeStamp( df )
	
	if ( table )
		NMStatsOffsetWaveEdit( folder + wName )
	endif
	
	return 0
	
End // NMStatsOffset

//****************************************************************
//****************************************************************

Function /S NMStatsOffsetWave( folder, wName, offsetType [ history ] ) // create x-axis offset wave
	String folder // data folder, ( "" ) for current data folder or ( "_subfolder_" ) for default subfolder
	String wName // wave name
	Variable offsetType // ( 1 ) group x-axis offset ( 2 ) wave x-axis offset
	Variable history
	
	Variable npnts
	String vlist = ""
	
	if ( history )
	
		vlist = NMCmdStr( folder, vlist )
		vlist = NMCmdStr( wName, vlist )
		vlist = NMCmdNum( offsetType, vlist, integer = 1 )
		
		NMCommandHistory( vlist )
	
	endif
	
	folder = CheckNMStatsFolderPath( folder )
	
	if ( !DataFolderExists( folder ) )
		return NM2ErrorStr( 30, "folder", folder )
	endif
	
	if ( !StringMatch( wName, "*Offset*" ) )
		NMDoAlert( "Bad Stats offset wave name " + NMQuotes( wName ) + ". " + NMStatsOffsetWaveNameAlert() )
		return ""
	endif
	
	wName = folder + wName
	
	if ( offsetType == 1 )
		npnts = NMGroupsLast( "" ) + 1
	else
		npnts = NMNumWaves()
	endif
	
	CheckNMwave( wName, npnts, 0 )
	
	if ( WaveExists( $wName ) )
		return wName
	else
		return ""
	endif

End // NMStatsOffsetWave

//****************************************************************
//****************************************************************

Function /S NMStatsOffsetWaveList( offsetType, fullPath )
	Variable offsetType // ( 1 ) group x-axis offset ( 2 ) wave x-axis offset
	Variable fullPath // ( 0 ) no, just wave name ( 1 ) yes, directory + wave name
	
	Variable wcnt, ok
	String wName, wList, wList2 = "", offsetTypeStr
	
	wList = NMFolderWaveList( NMStatsDF, "*Offset*", ";", "Text:0", 1 )
	
	wList = RemoveFromList( "OffsetW", wList )
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		offsetTypeStr = NMNoteStrByKey( wName, "Stats Offset Type" )
		
		ok = 0
		
		if ( StringMatch( offsetTypeStr, "Group" ) && ( offsetType == 1 ) )
			ok = 1
		elseif ( StringMatch( offsetTypeStr, "Wave" ) && ( offsetType == 2 ) )
			ok = 1
		endif
		
		if ( ok )
		
			if ( fullPath )
				wList2 = AddListItem( wName, wList2 )
			else
				wList2 = AddListItem( NMChild( wName ), wList2 )
			endif
		
		endif
		
	endfor
	
	return wList2
	
End // NMStatsOffsetWaveList

//****************************************************************
//****************************************************************

Function /S NMStatsOffsetWaveNameAlert()

	return "A Stats offset wave name should contain the string " + NMQuotes( "Offset" ) + "."
	
End // NMStatsOffsetWaveNameAlert

//****************************************************************
//****************************************************************

Function /S NMStatsOffsetWaveEdit2( win )
	Variable win // Stats window number ( -1 ) for currently selected window
	
	win = CheckNMStatsWin( win )
	
	if ( numtype( win ) > 0 )
		return ""
	endif
	
	String wName = NMStatsOffsetWaveName( win )
	
	return NMStatsOffsetWaveEdit( wName )
	
End // NMStatsOffsetWaveEdit2

//****************************************************************
//****************************************************************

Function /S NMStatsOffsetWaveEdit( wName ) // display table
	String wName // stats offset wave name
	
	String offsetType, ttl, tName
	String sName = NMChild( wName )
	
	STRUCT Rect w
	
	if ( !WaveExists( $wName ) )
		return NM2ErrorStr( 1, "wName", wName )
	endif
	
	offsetType = NMNoteStrByKey( wName, "Stats Offset Type" )
	
	strswitch( offsetType )
		case "Group":
		case "Wave":
			break
		default:
			return NM2ErrorStr( 20, "offsetType", offsetType )
	endswitch
	
	if ( StringMatch( sName[ 0,2 ], "ST_" ) )
		tName = sName + "_Table"
	else
		tName = "ST_" + sName
	endif
	
	NMWinCascadeRect( w )
	
	DoWindow /K $tName
	Edit /K=1/N=$tName/W=(w.left,w.top,w.right,w.bottom) $wName as "Stats Offset Wave"
	
	ModifyTable /W=$tName title( Point )=offsetType
	
	return tName

End // NMStatsOffsetWaveEdit

//****************************************************************
//****************************************************************

Function /S NMStatsOffsetWaveName( win ) // will return offset value
	Variable win // Stats window number ( -1 ) for currently selected window
	
	String wName = NMStatsDF + "OffsetW"
	
	if ( !WaveExists( $wName ) )
		return NM2ErrorStr( 1, "wName", wName )
	endif
	
	win = CheckNMStatsWin( win )
	
	if ( numtype( win ) > 0 )
		return ""
	endif
	
	Wave /T wTemp = $wName
	
	return wTemp[ win ]
	
End // NMStatsOffsetWaveName

//****************************************************************
//****************************************************************

Function StatsOffsetValue( win ) // will return offset value
	Variable win // Stats window number ( -1 ) for currently selected window
	
	Variable select = -1
	String offsetType
	String wName = NMStatsDF + "OffsetW"
	
	Variable currentWave = CurrentNMWave()
	
	if ( !WaveExists( $wName ) )
		return Nan
	endif
	
	win = CheckNMStatsWin( win )
	
	if ( numtype( win ) > 0 )
		return Nan
	endif
	
	Wave /T offsetW = $wName
	
	wName = offsetW[ win ]
	
	if ( strlen( wName ) == 0 )
		return Nan
	endif
	
	offsetType = wName[ 0,1 ] // Old Type Flag
	
	strswitch( offsetType )
	
		case "/w":
			select = currentWave
			wName = wName[ 2, inf ]
			break
			
		case "/g":
			select = NMGroupsNum( currentWave )
			wName = wName[ 2, inf ]
			break
			
	endswitch
	
	if ( !WaveExists( $wName ) )
		return Nan
	endif
	
	if ( select < 0 )
	
		offsetType = NMNoteStrByKey( wName, "Stats Offset Type" )
		
		strswitch( offsetType )
	
			case "Wave":
				select = currentWave
				break
				
			case "Group":
				select = NMGroupsNum( currentWave )
				break
				
			default:
				return Nan

		endswitch
	
	endif
	
	Wave wtemp = $wName
	
	if ( ( numtype( select ) > 0 ) || ( select < 0 ) || ( select >= numpnts( wtemp ) ) )
		return 0
	endif
	
	return wtemp[ select ]

End // StatsOffsetValue

//****************************************************************
//****************************************************************

Function NMStatsOffsetBaseline( win ) // get baseline flag
	Variable win // Stats window number ( -1 ) for currently selected window
	
	String bFlag, oldType
	String wName = NMStatsDF + "OffsetW"
	
	Variable currentWave = CurrentNMWave()
	
	if ( !WaveExists( $wName ) )
		return 0
	endif
	
	win = CheckNMStatsWin( win )
	
	if ( numtype( win ) > 0 )
		return 0
	endif
	
	Wave /T offsetW = $wName
	
	wName = offsetW[ win ]
	
	if ( strlen( wName ) == 0 )
		return 0
	endif
	
	oldType = wName[ 0, 1 ] // Old Type Flag
	
	strswitch( oldType )
	
		case "/w":
			wName = wName[ 2, inf ]
			break
			
		case "/g":
			wName = wName[ 2, inf ]
			break
			
	endswitch
	
	if ( !WaveExists( $wName ) )
		return 0
	endif
	
	bFlag = NMNoteStrByKey( wName, "Stats Offset Baseline" )
	
	strswitch( bFlag )
	
		case "Yes":
			return 1
			
		case "No":
			return 0
			
		default:
			return NMStatsVarGet( "OffsetBsln" ) // OLD FLAG
		
	endswitch

End // NMStatsOffsetBaseline

//****************************************************************
//****************************************************************
//
//		Display Graph Functions
//
//****************************************************************
//****************************************************************

Function StatsChanControlsEnableAll( enable )
	Variable enable
	
	Variable ccnt
	String gName
	
	Variable currentChan = CurrentNMChannel()
	Variable numChan = NMNumChannels()
	
	if ( enable )
		SetNMwave( NMStatsDF+"ChanSelect", -1, currentChan )
	endif
	
	for ( ccnt = 0; ccnt < numChan; ccnt += 1 )
	
		gName = ChanGraphName( ccnt ) 
		
		if ( WinType( gname ) != 1 )
			continue
		endif
		
		if ( ( ccnt == currentChan ) && enable )
			StatsChanControlsUpdate( ccnt, -1, 1 )
			NMChannelGraphDisable( channel = ccnt, filter = 1, transform = 1 )
		else
			StatsChanControlsUpdate( ccnt, -1, 0 )
			NMChannelGraphDisable( channel = ccnt, filter = 0, transform = 0 )
		endif
		
	endfor

End // StatsChanControlsEnableAll

//****************************************************************
//****************************************************************

Function StatsChanControlsUpdate( chan, win, enable )
	Variable chan // channel number
	Variable win // Stats window number
	Variable enable
	
	StatsChanControlsEnable( chan, win, enable )
	ChanGraphControlsUpdate( chan )

End // StatsChanControlsUpdate

//****************************************************************
//****************************************************************

Function StatsChanControlsEnable( chan, win, enable )
	Variable chan // channel number
	Variable win // Stats window number
	Variable enable
	
	String df = NMStatsDF
	
	Wave FilterNum = $df+"FilterNum"
	Wave /T FilterFxn = $df+"FilterAlg"
	
	Wave /T Transform = $df+"Transform"
	
	chan = ChanNumCheck( chan )
	
	win = CheckNMStatsWin( win )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	if ( enable )
	
		SetNMvar( df + "SmoothN", FilterNum[ win ] ) // for channel graph display
		SetNMstr( df + "SmoothA", FilterFxn[ win ] ) // for channel graph display
		
		SetNMstr( df + "TransformStr", Transform[ win ] ) // for channel graph display
		
		SetNMstr( NMDF+"ChanFilterDF" + num2istr( chan ), df )
		SetNMstr( NMDF+"ChanFilterProc" + num2istr( chan ), "NMStatsSetFilter" )
		
		SetNMstr( NMDF+"ChanTransformDF" + num2istr( chan ), df )
		SetNMstr( NMDF+"ChanTransformProc" + num2istr( chan ), "NMStatsTransformCheckBox" )
		
	else
		
		KillStrings /Z $( NMDF + "ChanSmthDF" + num2istr( chan ) ) // OLD
		KillStrings /Z $( NMDF + "ChanSmthProc" + num2istr( chan ) ) // OLD
		
		KillStrings /Z $( NMDF + "ChanFilterDF" + num2istr( chan ) )
		KillStrings /Z $( NMDF + "ChanFilterProc" + num2istr( chan ) )
		
		KillStrings /Z $( NMDF + "ChanTransformDF" + num2istr( chan ) )
		KillStrings /Z $( NMDF + "ChanTransformProc" + num2istr( chan ) )
	
	endif
	
	return 0
	
End // StatsChanControlsEnable

//****************************************************************
//****************************************************************

Function StatsDisplay( chan, appnd ) // append/remove display waves to current channel graph
	Variable chan // channel number ( -1 ) for current channel
	Variable appnd // ( 0 ) remove ( 1 ) append
	
	String df = NMStatsDF
	
	Variable anum, xy, icnt, ccnt, drag = appnd
	String gName
	
	STRUCT NMStatsDisplayWavesStruct dw
	NMStatsDisplayWavesStructRef( dw )
	
	STRUCT NMRGB ac
	STRUCT NMRGB bc
	STRUCT NMRGB rc
	
	NMColorList2RGB( NMStatsStrGet( "AmpColor" ), ac )
	NMColorList2RGB( NMStatsStrGet( "BaseColor" ), bc )
	NMColorList2RGB( NMStatsStrGet( "RiseColor" ), rc )
	
	Variable labelsOn = NMStatsVarGet( "GraphLabelsOn" )
	
	if ( !NMVarGet( "DragOn" ) || !StringMatch( CurrentNMTabName(), "Stats" ) )
		drag = 0
	endif
	
	chan = ChanNumCheck( chan )
	
	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 )
	
		gName = ChanGraphName( ccnt )
	
		if ( Wintype( gName ) != 1 )
			continue
		endif
		
		RemoveFromGraph /Z/W=$gName ST_BslnY, ST_WinY, ST_PntY, ST_RDY
		RemoveFromGraph /Z/W=$gName DragBgnY, DragEndY
		RemoveFromGraph /Z/W=$gName DragBslnBgnY, DragBslnEndY
		
	endfor
	
	gName = ChanGraphName( chan )
	
	if ( Wintype( gName ) != 1 )
		return 0
	endif
	
	if ( appnd )

		AppendToGraph /W=$gName dw.bslnY vs dw.bslnX
		AppendToGraph /W=$gName dw.winY vs dw.winX
		AppendToGraph /W=$gName dw.pntY vs dw.pntX
		AppendToGraph /W=$gName dw.RDY vs dw.RDX
		
		ModifyGraph /W=$gName lsize( ST_BslnY )=1.1, rgb( ST_BslnY )=(bc.r,bc.g,bc.b)
		ModifyGraph /W=$gName mode( ST_PntY )=3, marker( ST_PntY )=19, rgb( ST_PntY )=(ac.r,ac.g,ac.b)
		ModifyGraph /W=$gName lsize( ST_WinY )=1.1, rgb( ST_WinY )=(ac.r,ac.g,ac.b)
		ModifyGraph /W=$gName mode( ST_RDY )=3, marker( ST_RDY )=9, mrkThick( ST_RDY )=2
		ModifyGraph /W=$gName msize( ST_RDY )=4, rgb( ST_RDY )=(rc.r,rc.g,rc.b)
		
		Tag /K/N=ST_Win_Tag/W=$gName
		Tag /K/N=ST_Bsln_Tag/W=$gName
		
		Tag /W=$gName/N=ST_Win_Tag/G=(ac.r,ac.g,ac.b)/I=1/F=0/L=0/X=5.0/Y=0.00/V=( labelsOn ) ST_WinY, 1, " \\{\"%.2f\",TagVal( 2 )}"
		Tag /W=$gName/N=ST_Bsln_Tag/G=(bc.r,bc.g,bc.b)/I=1/F=0/L=0/X=5.0/Y=0.00/V=( labelsOn ) ST_BslnY, 1, " \\{\"%.2f\",TagVal( 2 )}"
			
	endif
		
	NMDragEnable( drag, "DragBgn", df+"AmpB", df+"AmpNV", "NMStatsDragTrigger", gName, "bottom", "min", ac.r, ac.g, ac.b )
	NMDragEnable( drag, "DragEnd", df+"AmpE", df+"AmpNV", "NMStatsDragTrigger", gName, "bottom", "max", ac.r, ac.g, ac.b )
	NMDragEnable( drag, "DragBslnBgn", df+"BslnB", df+"AmpNV", "NMStatsDragTrigger", gName, "bottom", "min", bc.r, bc.g, bc.b )
	NMDragEnable( drag, "DragBslnEnd", df+"BslnE", df+"AmpNV", "NMStatsDragTrigger", gName, "bottom", "max", bc.r, bc.g, bc.b )
	
	KillWaves /Z $NMDF + "DragTbgnX" // old waves
	KillWaves /Z $NMDF + "DragTbgnY"
	KillWaves /Z $NMDF + "DragBslnTbgnX"
	KillWaves /Z $NMDF + "DragBslnTbgnY"

	return 0

End // StatsDisplay

//****************************************************************
//****************************************************************

Function NMStatsDragTrigger( offsetStr )
	String offsetStr
	
	if ( !NMDragTrigger( offsetStr ) )
		StatsTimeStamp( NMStatsDF )
	endif
	
End // NMStatsDragTrigger

//****************************************************************
//****************************************************************

Function NMStatsDragUpdate()

	Variable ampDrag, bslnDrag
	String ampStr, df = NMStatsDF
	
	Variable drag = NMVarGet( "DragOn" )
	
	if ( WaveExists( $df + "AmpSlct" ) )
	
		STRUCT NMStatsInputWavesStruct si
		NMStatsInputWavesStructRef( si )
		
		STRUCT NMStatsParamStruct sp
		NMStatsParamRef( sp )
		
		if ( ( sp.winSelect >= 0 ) && ( sp.winSelect < numpnts( si.select ) ) )
			
			ampStr = si.select[ sp.winSelect ]
			
			if ( ( strlen( ampStr ) == 0 ) || StringMatch( ampStr, "Off" ) )
				ampDrag = 0
			else
				ampDrag = 1
			endif
			
		endif
		
		if ( ( sp.winSelect >= 0 ) && ( sp.winSelect < numpnts( si.onB ) ) )
			bslnDrag = BinaryCheck( si.onB[ sp.winSelect ] )
		endif
		
	endif
	
	if ( drag && ampDrag )
		NMDragUpdate( "DragBgn" )
		NMDragUpdate( "DragEnd" )
	else
		NMDragClear( "DragBgn" )
		NMDragClear( "DragEnd" )
	endif
	
	if ( drag && bslnDrag )
		NMDragUpdate( "DragBslnBgn" )
		NMDragUpdate( "DragBslnEnd" )
	else
		NMDragClear( "DragBslnBgn" )
		NMDragClear( "DragBslnEnd" )
	endif

End // NMStatsDragUpdate

//****************************************************************
//****************************************************************

Function NMStatsDragClear()
	
	NMDragClear( "DragBgn" )
	NMDragClear( "DragEnd" )
	NMDragClear( "DragBslnBgn" )
	NMDragClear( "DragBslnEnd" )
	
End // NMStatsDragClear

//****************************************************************
//****************************************************************

Function StatsDisplayClear()
	
	STRUCT NMStatsDisplayWavesStruct dw
	
	NMStatsDisplayWavesStructRef( dw )
	NMStatsDisplayWavesStructNull( dw )
	NMStatsDragClear()

End // StatsDisplayClear

//****************************************************************
//****************************************************************
//
//		Stats1 Computation Functions
//
//****************************************************************
//****************************************************************

Function NMStatsAuto( [ update, force ] ) // compute Stats of currently selected channel / wave
	Variable update
	Variable force // ignore AutoStats1

	Variable icnt, ifirst = 0, ilast
	String select

	String wName = ChanDisplayWave( -1 )
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	STRUCT NMStatsInputWavesStruct si
	NMStatsInputWavesStructRef( si )
	
	StatsDisplayClear()
	NMStatsOutputWavesStructClear()
	
	if ( WaveExists( $wName ) && ( force || NMStatsVarGet( "AutoStats1" ) ) )
	
		ilast = numpnts( si.select )
	
		for ( icnt = ifirst; icnt < ilast; icnt += 1 )
		
			select = StatsAmpSelectGet( icnt )
		
			if ( !StringMatch( select, "Off" ) )
				StatsComputeWin( icnt, wName, 1 )
			endif
			
		endfor
		
	endif
	
	if ( update )
		UpdateStats()
	endif
	
	NMStatsDragUpdate()
	
End // NMStatsAuto

//****************************************************************
//****************************************************************

Static Function z_AllWavesCall()

	Variable allwin, tables, graphs, stats2, numWin = StatsWinCount()
	String chanSelectList, waveSelectList, windowList
	String select, df = NMStatsDF
	
	if ( NMExecutionAlert() )
		return -1
	endif
	
	Variable win = NumVarOrDefault( df + "AmpNV", 0 )
	Variable show = 1 + NMStatsVarGet( "ComputeAllDisplay" )
	Variable delay = NMStatsVarGet( "ComputeAllSpeed" ) 
	
	if ( NMNumActiveWaves() <= 0 )
		NMDoAlert( "No waves selected!" )
		return -1
	endif
	
	if ( numWin <= 0 )
		NMDoAlert( "All Stats windows are off." )
		return -1
	elseif ( numWin == 1 )
		allwin = 1
	elseif ( numWin > 1 )
		allwin = 1 + NMStatsVarGet( "ComputeAllWin" )
	endif
	
	Prompt allwin, "compute:", popup "current stats window;all stats windows;"
	Prompt show, "display results while computing?", popup "no;yes;"
	Prompt delay, "optional display update delay ( seconds ):"
	
	if ( numWin > 1 )
		DoPrompt NMPromptStr( "Stats Compute All" ), allwin, show, delay
		allwin -= 1
	else
		DoPrompt NMPromptStr( "Stats Compute All" ), show, delay
	endif
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	show -= 1
	
	SetNMvar( df + "ComputeAllWin", allwin )
	SetNMvar( df + "ComputeAllDisplay", show )
	SetNMvar( df + "ComputeAllSpeed", delay )
	
	select = StatsAmpSelectGet( win )
	
	if ( !allwin && StringMatch( select, "Off" ) )
		NMDoAlert( "Current Stats window is off." )
		return -1
	endif
		
	if ( allwin )
		windowList = "All"
	else
		windowList = num2istr( win )
	endif
	
	tables = NMStatsVarGet( "AutoTables" )
	graphs = NMStatsVarGet( "AutoPlots" )
	stats2 = NMStatsVarGet( "AutoStats2" )
	
	if ( !NMVarGet( "GraphsAndTablesOn" ) )
		tables = 0
		graphs = 0
	endif
	
	chanSelectList = NMChanSelectAllList()
	
	if ( ItemsInList ( chanSelectList ) == 0 )
		chanSelectList = CurrentNMChanChar()
	endif
	
	waveSelectList = NMWaveSelectAllList()
	
	if ( ItemsInList( waveSelectList ) == 0 )
		waveSelectList = NMWaveSelectGet()
	endif
	
	return NMStatsCompute( chanSelectList = chanSelectList, waveSelectList = waveSelectList, windowList = windowList, show = show, delay = delay, tables = tables, graphs = graphs, stats2 = stats2, history = 1 )

End // z_AllWavesCall

//****************************************************************
//****************************************************************

Function NMStatsCompute( [ chanSelectList, waveSelectList, windowList, show, delay, tables, graphs, stats2, history ] )
	String chanSelectList // channel select list ( e.g. "A;B;" )
	String waveSelectList // wave select list ( e.g. "Set1;Set2;" )
	String windowList // Stats window number list ( e.g. "0;1;2;" or "All" )
	Variable show // show results in channel graphs while computing ( 0 ) no ( 1 ) yes
	Variable delay // delay in seconds ( 0 ) for no delay
	Variable tables // automatically create output tables ( 0 ) no ( 1 ) yes
	Variable graphs // automatically plot default Stats waves ( 0 ) no ( 1 ) yes
	Variable stats2 // automatically compute average/stdv of the output Stats waves ( 0 ) no ( 1 ) yes
	Variable history // print function command to history ( 0 ) no ( 1 ) yes

	Variable icnt, jcnt, ccnt, wcnt, win, pflag, cancel
	Variable channel, waveNum
	Variable chanSelectListItems, waveSelectListItems
	String subfolder
	String wName, windowName, tName2 = "", deleteRowsList = ""
	String outputWinList1, outputWinList2 = "", outputWaveList1, outputWaveList2 = ""
	String chanSelectStr, progressStr, vlist = ""
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = NMChanSelectAllList()
	else
		vlist = NMCmdStrOptional( "chanSelectList", chanSelectList, vlist )
	endif
	
	if ( StringMatch( chanSelectList, "All" ) )
		chanSelectList = NMChanSelectAllList()
	endif
	
	chanSelectListItems = ItemsInList( chanSelectList )
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = NMWaveSelectAllList()
	else
		vlist = NMCmdStrOptional( "waveSelectList", waveSelectList, vlist )
	endif
	
	if ( StringMatch( waveSelectList, "All" ) )
		waveSelectList = NMWaveSelectAllList()
	endif

	waveSelectListItems = ItemsInList( waveSelectList )
	
	if ( ParamIsDefault( windowList ) )
		windowList = NMStatsWinList( 1, "" ) // all windows
	else
		vlist = NMCmdStrOptional( "windowList", windowList, vlist )
	endif
	
	if ( StringMatch( windowList, "All" ) )
		windowList = NMStatsWinList( 1, "" ) // all windows
	endif
	
	if ( ParamIsDefault( show ) )
		show = 1
	else
		vlist = NMCmdNumOptional( "show", show, vlist, integer = 1 )
	endif
	
	if ( ParamIsDefault( delay ) )
		delay = 0
	else
		vlist = NMCmdNumOptional( "delay", delay, vlist )
	endif
	
	if ( ParamIsDefault( tables ) )
		tables = 1
	else
		vlist = NMCmdNumOptional( "tables", tables, vlist, integer = 1 )
	endif
	
	if ( ParamIsDefault( graphs ) )
		graphs = 1
	else
		vlist = NMCmdNumOptional( "graphs", graphs, vlist, integer = 1 )
	endif
	
	if ( !NMVarGet( "GraphsAndTablesOn" ) )
		tables = 0
		graphs = 0
	endif
	
	if ( ParamIsDefault( stats2 ) )
		stats2 = 0
	else
		vlist = NMCmdNumOptional( "stats2", stats2, vlist, integer = 1 )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	Variable numWaves = NMNumWaves()

	String prefixFolder = CurrentNMPrefixFolder()
	
	Variable drag = NMVarGet( "DragOn" )
	
	String saveChanSelectStr = NMChanSelectStr()
	
	String waveSelect = NMWaveSelectGet()
	String saveWaveSelect = waveSelect
	
	Variable saveCurrentWave = CurrentNMWave()
	
	Variable waveLengthFormat = NMStatsVarGet( "WaveLengthFormat" )
	
	CheckNMStatsWaves( 0, errorAlert = 1 )
	
	for ( icnt = 0 ; icnt < max( waveSelectListItems, 1 ) ; icnt += 1 ) // loop thru sets / groups
		
		if ( waveSelectListItems > 0 )
		
			waveSelect = StringFromList( icnt, waveSelectList )
			
			if ( !StringMatch( waveSelect, NMWaveSelectGet() ) )
				NMWaveSelect( waveSelect )
			endif
			
		endif
		
		if ( NMNumActiveWaves() <= 0 )
			continue
		endif
	
		for ( ccnt = 0 ; ccnt < max( chanSelectListItems, 1 ) ; ccnt += 1 ) // loop thru channels
		
			outputWaveList1 = ""
			outputWinList1 = ""
		
			if ( chanSelectListItems > 0 )
			
				chanSelectStr = StringFromList( ccnt, chanSelectList )
				
				if ( !StringMatch( chanSelectStr, CurrentNMChanChar() ) )
					NMChanSelect( chanSelectStr )
					DoUpdate
				endif
				
			endif
			
			channel = CurrentNMChannel()
			
			if ( tables )
			
				windowName = NMStatsWavesTable( DEFAULTSUBFOLDER, channel, windowList, hide = 1 )
				
				if ( WinType( windowName ) == 2 )
					outputWaveList1 = StrVarOrDefault( NMDF + "OutputWaveList", "" )
					outputWinList1 = AddListItem( windowName, outputWinList1, ";", inf )
				endif
				
			else
			
				outputWaveList1 = StatsWavesMake( DEFAULTSUBFOLDER, channel, windowList )
				
			endif
			
			progressStr = "Stats Chan " + ChanNum2Char( channel )
			
			deleteRowsList = ""
		
			for ( wcnt = 0; wcnt < numWaves; wcnt += 1 ) // loop thru waves
				
				if ( NMProgress( wcnt, numWaves, progressStr ) == 1 )
					break
				endif
				
				wName = NMWaveSelected( channel, wcnt )
				
				if ( strlen( wName ) == 0 )
				
					if ( waveLengthFormat == 1 )
						deleteRowsList = AddListItem( num2istr( wcnt ), deleteRowsList, ";", 0 ) // PREPEND
					endif
					
					continue // wave not selected, or does not exist... go to next wave
					
				endif
				
				NMCurrentWaveSet( wcnt, update = 0 )
				
				if ( show )
					NMChanGraphUpdate( channel = channel, waveNum = wcnt )
				endif
		
				for ( jcnt = 0 ; jcnt < ItemsInList( windowList ) ; jcnt += 1 ) // loop thru Stats windows
					win = str2num( StringFromList( jcnt, windowList ) )
					StatsCompute( wName, channel, wcnt, win, 1, show )
				endfor
				
				if ( show && ( numtype( delay ) == 0 ) && ( delay > 0 ) )
					NMwaitMSTimer( delay * 1000 )
				endif
					
			endfor // waves
			
			if ( ( waveLengthFormat == 1 ) && ( ItemsInList( deleteRowsList ) > 0 ) )
				NMStatsDelete( channel, NaN, waveNumList = deleteRowsList, windowList = windowList )
			endif
			
			subfolder = NMStatsSubfolder( "", channel )
			
			NMStats2WaveSelectFilter( "Stats1" )
			NMStatsSet( folderSelect = subfolder, waveSelect = "" ) // set default values
			
			if ( graphs )
			
				windowName = NMStatsPlot( hide = 1 )
				
				if ( ItemsInList( windowName ) > 0 )
					windowName = StringFromList( 0, windowName )
					outputWinList1 = AddListItem( windowName, outputWinList1, ";", inf )
				endif
				
			endif
			
			if ( stats2 )
				
				windowName = NMStatsWaveStats( folder = subfolder, hide = 1 )
				
				if ( strlen( windowName ) > 0 )
					windowName = StringFromList( 0, windowName )
					outputWinList1 = AddListItem( windowName, outputWinList1, ";", inf )
				endif
				
			endif
			
			if ( NMProgressCancel() == 1 )
				break
			endif
			
			if ( ItemsInList( outputWaveList1 ) > 0 )
				outputWaveList2 += outputWaveList1
			endif
			
			if ( ItemsInList( outputWinList1 ) > 0 )
				outputWinList2 += outputWinList1
			endif
			
			SetNMstr( NMDF + "OutputWaveList", outputWaveList1 )
			SetNMstr( NMDF + "OutputWinList", outputWinList1 )
			
			if ( history && !tables )
				NMHistoryOutputWaves( subfolder = subfolder )
			endif
			
		endfor // channels
		
		if ( NMProgressCancel() == 1 )
			break
		endif
		
	endfor // sets
	
	if ( chanSelectListItems > 0 )
		NMChanSelect( saveChanSelectStr, update = 1 )
	endif
	
	if ( waveSelectListItems > 0 )
		NMWaveSelect( saveWaveSelect, update = 1 )
	endif
	
	NMCurrentWaveSet( saveCurrentWave, update = 0 )
	
	StatsDisplayClear()
	NMStatsOutputWavesStructClear()
	ChanGraphsUpdate()
	StatsCompute( "", -1, -1, -1, 0, 1 )
	
	if ( drag )
		StatsDisplay( -1, 1 )
		NMStatsDragUpdate()
	endif
	
	for ( icnt = 0; icnt < ItemsInList( outputWinList2 ); icnt += 1 )
	
		windowName = StringFromList( icnt, outputWinList2 )
	
		if ( ( strlen( windowName ) > 0 ) && ( WinType( windowName ) > 0 ) )
			DoWindow /F/Hide=0 $windowName
		endif
	
	endfor
	
	SetNMstr( NMDF + "OutputWaveList", outputWaveList2 )
	SetNMstr( NMDF + "OutputWinList", outputWinList2 )
	
	StatsChanControlsEnableAll( 1 )
	
	return 0

End // NMStatsCompute

//****************************************************************
//****************************************************************

Function NMStatsDelete( chan, waveNum [ waveNumList, windowList ] )
	Variable chan // channel number ( -1 ) current channel
	Variable waveNum // wave number ( -1 ) current wave
	String waveNumList // list of wave numbers ( use instead of waveNum )
	String windowList // Stats window list, nothing for all
	
	Variable icnt, win, wcnt
	String select, subfolder, wName, df = NMStatsDF
	
	if ( ParamIsDefault( waveNumList ) )
		waveNumList = ""
	endif
	
	if ( ItemsInlist( waveNumList ) == 0 )
	
		if ( ( numtype( waveNum ) == 0 ) && ( waveNum >= 0 ) )
			waveNumList = num2str( waveNum )
		else
			return 0
		endif
	
	endif
	
	if ( ItemsInlist( waveNumList ) == 0 )
		return 0
	endif
	
	if ( ParamIsDefault( windowList ) )
		windowList = ""
	endif
	
	if ( ItemsInlist( windowList ) == 0 )
		windowList = NMStatsWinList( 1, "" )
	endif
	
	if ( ItemsInlist( windowList ) == 0 )
		return NM2Error( 21, "windowList", windowList )
	endif
	
	if ( chan < 0 )
		chan = CurrentNMChannel()
	endif
	
	subfolder = NMStatsSubfolder( "", chan )
	
	for ( wcnt = 0; wcnt < ItemsInList( waveNumList ); wcnt += 1 )
	
		waveNum = str2num( StringFromList( wcnt, waveNumList ) )
	
		wName = NMStatsWaveNameForWName( subfolder, chan, 1 )
		
		StatsAmpSave2( wName, waveNum, Nan, 2 )
	
		for ( icnt = 0; icnt < ItemsInList( windowList ); icnt += 1 )
			
			win = str2num( StringFromList( icnt, windowList ) )
			
			select = StatsAmpSelectGet( win )
		
			if ( StringMatch( select, "Off" ) )
				continue
			endif
			
			StatsAmpSave( subfolder, chan, waveNum, win, 2 )
		
		endfor
	
	endfor
	
	return 0
		
End // NMStatsDelete

//****************************************************************
//****************************************************************

Function StatsCompute( wName, chan, waveNum, win, saveflag, show )
	String wName // wave name, ( "" ) for current channel display wave
	Variable chan // channel number ( -1 ) current channel
	Variable waveNum // wave number ( -1 ) current wave
	Variable win // Stats window number ( -1 ) for all
	Variable saveflag // save to table waves
	Variable show // show results in channel graphs while computing ( 0 ) no ( 1 ) yes
	
	Variable icnt, ifirst, ilast, dFlag, filterNumLast, newWave
	String filterFxnLast, transformLast, waveLast, select, dName, subfolder, xWave, df = NMStatsDF
	
	String tName = "ST_WaveTemp"
	
	Variable ampNV = NumVarOrDefault( df + "AmpNV", 0 )
	
	STRUCT NMStatsInputWavesStruct si
	NMStatsInputWavesStructRef( si )
	
	if ( chan < 0 )
		chan = CurrentNMChannel()
	endif
	
	if ( waveNum < 0 )
		waveNum = CurrentNMWave()
	endif
	
	if ( strlen( wName ) == 0 )
		wName = NMChanWaveName( chan, waveNum )
	endif
	
	xWave = NMXwave( waveNum = waveNum )
	
	if ( win == -1 )
	
		ifirst = 0
		ilast = numpnts( si.select )
		
	else
	
		win = CheckNMStatsWin( win )
		
		if ( numtype( win ) > 0 )
			return -1
		endif
		
		ifirst = win
		ilast = win + 1
		
	endif
	
	transformLast = "" // NMChanTransformGet( chan )
	filterNumLast = 0 // ChanFilterNumGet( chan )
	filterFxnLast = "" // ChanFilterAlgGet( chan )
	waveLast = ChanDisplayWave( chan )

	for ( icnt = ifirst; icnt < ilast; icnt += 1 )
	
		select = StatsAmpSelectGet( icnt )
		
		if ( StringMatch( select, "Off" ) )
			continue
		endif
		
		if ( show )
			dName = ChanDisplayWave( chan )
		else
			dName = tName
		endif
		
		StatsChanControlsEnable( chan, icnt, 1 )
		
		newWave = 0
		
		if ( !WaveExists( $dName ) || !StringMatch( dName, waveLast ) )
			newWave = 1
		elseif ( !StringMatch( si.transform[ icnt ], transformLast ) || ( si.filterNum[ icnt ] != filterNumLast ) )
			newWave = 1
		elseif ( ( si.filterNum[ icnt ] > 0 ) && !StringMatch( si.filterFxn[ icnt ], filterFxnLast ) )
			newWave = 1
		endif
		
		if ( newWave )
			filterNumLast = si.filterNum[ icnt ]
			filterFxnLast = si.filterFxn[ icnt ]
			transformLast = si.transform[ icnt ]
		endif
		
		if ( newWave && ( ChanWaveMake( chan, wName, dName, xWave = xWave ) < 0 ) )
			continue
		endif
		
		if ( icnt == AmpNV )
			dFlag = 1
		else
			dFlag = 0
		endif
		
		if ( StatsComputeWin( icnt, dName, show * dFlag ) < 0 )
			continue // error
		endif
		
		if ( show && ( icnt == AmpNV ) )
			DoUpdate
		endif
	
		if ( saveflag )
			subfolder = NMStatsSubfolder( "", chan )
			StatsAmpSave( subfolder, chan, waveNum, icnt, 0 )
		endif
			
	endfor
	
	KillWaves /Z $tName
	
	return 0
		
End // StatsCompute

//****************************************************************
//****************************************************************

Function StatsComputeWin( win, wName, show [ waveNum ] ) // compute window stats
	Variable win // Stats window number
	String wName // name of wave to measure
	Variable show // show results in channel graphs while computing ( 0 ) no ( 1 ) yes
	Variable waveNum
	
	Variable ay, ax, apnt, by, bx, dumvar, xoffset, off, bsln, edge, avgWin = NaN
	Variable m, b // for line fits
	Variable xbgn, xend, bbgn, bend, yLevel
	String select
	
	win = CheckNMStatsWin( win )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	STRUCT NMWaveStatsStruct s
	STRUCT NMLineStruct line
	STRUCT NMMaxCurvStruct mc
	STRUCT NMFindLevelStruct fl
	STRUCT NMMaxAvgStruct maxavg
	STRUCT NMMinAvgStruct minavg
	STRUCT NMRiseTimeStruct rt
	STRUCT NMDecayTimeStruct dt
	STRUCT NMFWHMStruct fwhm
	
	STRUCT NMStatsInputsStruct si
	
	if ( NMStatsInputsGet( si, win = win ) < 0 )
		return -1
	endif
	
	STRUCT NMStatsOutputsStruct so
	
	STRUCT NMStatsDisplayWavesStruct dw
	NMStatsDisplayWavesStructRef( dw )
	
	if ( ParamIsDefault( waveNum ) || ( waveNum < 0 ) )
		waveNum = -1
	endif
	
	String xWave = NMXwave( waveNum = waveNum )
	
	String df = NMStatsDF
	
	Variable ampNV = NumVarOrDefault( df + "AmpNV", 0 )
	
	if ( !DataFolderExists( df ) )
		return NM2Error( 30, "StatsDF", df )
	endif
	
	if ( strlen( wName ) == 0 )
		return -1
	endif
	
	if ( !WaveExists( $wName ) )
		return NM2Error( 1, "wName", wName )
	endif
	
	if ( !WaveExists( $df+"AmpB" ) )
		return NM2Error( 1, "AmpB", df+"AmpB" )
	endif
	
	xoffset = StatsOffsetValue( win )
	
	if ( numtype( xoffset ) > 0 )
		xoffset = 0
	endif
	
	select = StatsAmpSelectGet( win )
	
	if ( z_IsMaxMinAvg( select ) )
	
		avgWin = str2num( select[ 6, inf ] )
		
		if ( numtype( avgWin ) == 0 )
			select = select[ 0, 5 ]
		endif
		
	endif
	
	strswitch( select )
	
		case "Level":
		case "Level+":
		case "Level-":
			yLevel = 1
			break

	endswitch
	
	NMStatsOutputsStructNull( so )
	
	if ( si.onB )
		bsln = 1
	endif
	
	strswitch( select )
		case "RiseTime+":
		case "RiseTime-":
		case "RTslope+":
		case "RTslope-":
		case "DecayTime+":
		case "DecayTime-":
		case "FWHM+":
		case "FWHM-":
			bsln = 1
	endswitch
	
	if ( StringMatch( select[ 0, 2 ], "Off" ) )
		off = 1
		bsln = 0
	endif
	
	//if ( show )
		//NMStatsDisplayWavesStructNull( dw ) // this incorrectly nulls display waves
	//endif
	
	// compute baseline stats between BslnB and BslnE
	
	bx = NaN
	by = NaN
	
	if ( bsln )
	
		//if ( BslnB[ win ] > BslnE[ win ] )
		//	dumvar = BslnE[ win ] // switch
		//	BslnE[ win ] = BslnB[ win ]
		//	BslnB[ win ] = dumvar
		//endif
		
		if ( numtype( si.xbgnB ) == 0 )
			bbgn = si.xbgnB
		else
			bbgn = NMLeftX( wName, xWave = xWave ) // considers xWave
		endif
		
		if ( numtype( si.xendB ) == 0 )
			bend = si.xendB
		else
			bend = NMRightX( wName, xWave = xWave ) // considers xWave
		endif
	 
	 	if ( ( numtype( xoffset ) == 0 ) && NMStatsOffsetBaseline( win ) )
			bbgn += xoffset
			bend += xoffset
		endif
		
		if ( bbgn > bend )
			dumvar = bend // switch
			bend = bbgn
			bbgn = dumvar
		endif
		
		strswitch( select )
			case "RiseTime+":
			case "RiseTime-":
			case "RTslope+":
			case "RTslope-":
			case "DecayTime+":
			case "DecayTime-":
			case "FWHM+":
			case "FWHM-":
				si.selectB = "" // cancel baseline since it is computed in functions below
				break
		endswitch
		
	else
	
		si.selectB = ""
		
	endif
		
	strswitch( si.selectB )

		case "Max":
		case "Min":
		case "Sum":
		case "Avg":
		case "SDev":
		case "SEM":
		case "Var":
		case "RMS":
			NMWaveStatsStructInit( s, wName, xWave = xWave, xbgn = bbgn, xend = bend, fxnSelect = si.selectB )
			NMWaveStatsXY2( s )
			by = s.y
			bx = s.x
			break
			
		case "Area":
			if ( WaveExists( $xwave ) )
				by = areaXY( $xwave, $wName, bbgn, bend )
			else
				by = area( $wName, bbgn, bend )
			endif
			break
			
		case "Median":
			by = NMMedian( wName, xWave = xWave, xbgn = bbgn, xend = bend )
			break
		
		case "PathLength":
			by = NMPathLength( wName, xWave = xWave, xbgn = bbgn, xend = bend )
			break
			
		case "Slope":
			NMLineStructInit( line, wName, xWave = xWave, xbgn = bbgn, xend = bend )
			NMLinearRegression2( line )
			bx = line.b
			by = line.m
			break
		
	endswitch
	
	// compute amplitude stats between AmpB and AmpE
	
	ay = Nan
	ax = Nan
	apnt = NaN
	m = NaN
	b = Nan
	
	if ( !off )
		
		if ( numtype( si.xbgn ) == 0 )
			xbgn = si.xbgn
		else
			xbgn = NMLeftX( wName, xWave = xWave )
		endif
		
		if ( numtype( si.xend ) == 0 )
			xend = si.xend
		else
			xend = NMRightX( wName, xWave = xWave )
		endif
		
		if ( numtype( xoffset ) == 0 )
			xbgn += xoffset
			xend += xoffset
		endif
		
		if ( xbgn > xend )
			dumvar = xend // switch
			xend = xbgn
			xbgn = dumvar
		endif
	
	endif
	
	strswitch( select )
	
		case "Off":
			break
	
		case "Max":
		case "Min":
		case "Sum":
		case "Avg":
		case "SDev":
		case "SEM":
		case "Var":
		case "RMS":
		case "NumPnts":
			NMWaveStatsStructInit( s, wName, xWave = xWave, xbgn = xbgn, xend = xend, fxnSelect = select )
			NMWaveStatsXY2( s )
			ay = s.y
			ax = s.x
			apnt = s.pnt
			break
			
		case "Avg+SDev":
			NMWaveStatsStructInit( s, wName, xWave = xWave, xbgn = xbgn, xend = xend )
			NMWaveStatsXY2( s )
			ax = s.sdev
			ay = s.avg
			break
			
		case "Avg+SEM":
			NMWaveStatsStructInit( s, wName, xWave = xWave, xbgn = xbgn, xend = xend )
			NMWaveStatsXY2( s )
			ax = s.sem
			ay = s.avg
			break
			
		case "Area":
			if ( WaveExists( $xwave ) )
				ay = areaXY( $xwave, $wName, xbgn, xend )
			else
				ay = area( $wName, xbgn, xend )
			endif
			break
			
		case "Median":
			ay = NMMedian( wName, xWave = xWave, xbgn = xbgn, xend = xend )
			break
		
		case "PathLength":
			ay = NMPathLength( wName, xWave = xWave, xbgn = xbgn, xend = xend )
			break
			
		case "Slope":
			NMLineStructInit( line, wName, xWave = xWave, xbgn = xbgn, xend = xend )
			NMLinearRegression2( line )
			m = line.m
			b = line.b
			break
		
		case "Onset":
			NMMaxCurvStructInit( mc, wName, xWave = xWave, xbgn = xbgn, xend = xend )
			NMMaxCurvatures2( mc )
			ay = mc.y1
			ax = mc.x1
			apnt = mc.pnt1
			break
			
		case "Level":
		case "Level+":
		case "Level-":
		
			if ( StringMatch( select, "Level+" ) )
				edge = 1
			elseif ( StringMatch( select, "Level-" ) )
				edge = 2
			endif
			
			ay = si.level
			NMFindLevelStructInit( fl, si.level, wName, xWave = xWave, xbgn = xbgn, xend = xend, edge = edge )
			NMFindLevel2( fl )
			ax = fl.x
			apnt = fl.pnt
			
			break
		
		case "MaxAvg":
			NMMaxAvgStructInit( maxavg, avgWin, wName, xWave = xWave, xbgn = xbgn, xend = xend )
			NMMaxAvg2( maxavg )
			ay = maxavg.avg
			ax = maxavg.maxLoc
			apnt = maxavg.maxRowLoc
			break
			
		case "MinAvg":
			NMMinAvgStructInit( minavg, avgWin, wName, xWave = xWave, xbgn = xbgn, xend = xend )
			NMMinAvg2( minavg )
			ay = minavg.avg
			ax = minavg.minLoc
			apnt = minavg.minRowLoc
			break
	
		case "RiseTime+":
			NMRiseTimeStructInit( rt, bbgn, bend, xbgn, xend, si.risePB, si.risePE, wName, xWave = xWave )
			NMRiseTime2( rt, searchFromPeak = NMStatsVarGet( "RiseTimeSearchFromPeak" ) )
			so.riseXB = rt.x1
			so.riseXE = rt.x2
			so.riseT = rt.riseTime
			bsln = 1
			by = rt.baseline
			ay = rt.max
			ax = rt.maxLoc
			apnt = rt.maxRowLoc
			break
			
		case "RiseTime-":
			NMRiseTimeStructInit( rt, bbgn, bend, xbgn, xend, si.risePB, si.risePE, wName, xWave = xWave, negative = 1 )
			NMRiseTime2( rt, searchFromPeak = NMStatsVarGet( "RiseTimeSearchFromPeak" ) )
			so.riseXB = rt.x1
			so.riseXE = rt.x2
			so.riseT = rt.riseTime
			bsln = 1
			by = rt.baseline
			ay = rt.min
			ax = rt.minLoc
			apnt = rt.minRowLoc
			break
			
		case "RTslope+":
			NMRiseTimeStructInit( rt, bbgn, bend, xbgn, xend, si.risePB, si.risePE, wName, xWave = xWave )
			NMRiseTime2( rt, slope = 1, searchFromPeak = NMStatsVarGet( "RiseTimeSearchFromPeak" ) )
			so.riseXB = rt.x1
			so.riseXE = rt.x2
			so.riseT = rt.riseTime
			bsln = 1
			by = rt.baseline
			ay = rt.max
			ax = rt.maxLoc
			apnt = rt.maxRowLoc
			m = rt.m
			b = rt.b
			break
			
		case "RTslope-":
			NMRiseTimeStructInit( rt, bbgn, bend, xbgn, xend, si.risePB, si.risePE, wName, xWave = xWave, negative = 1 )
			NMRiseTime2( rt, slope = 1, searchFromPeak = NMStatsVarGet( "RiseTimeSearchFromPeak" ) )
			so.riseXB = rt.x1
			so.riseXE = rt.x2
			so.riseT = rt.riseTime
			bsln = 1
			by = rt.baseline
			ay = rt.min
			ax = rt.minLoc
			apnt = rt.minRowLoc
			m = rt.m
			b = rt.b
			break
			
		case "DecayTime+":
			NMDecayTimeStructInit( dt, bbgn, bend, xbgn, xend, si.decayP, wName, xWave = xWave )
			NMDecayTime2( dt )
			so.decayX = dt.xDecay
			so.decayT = dt.decayTime
			bsln = 1
			by = dt.baseline
			ay = dt.max
			ax = dt.maxLoc
			apnt = dt.maxRowLoc
			break
			
		case "DecayTime-":
			NMDecayTimeStructInit( dt, bbgn, bend, xbgn, xend, si.decayP, wName, xWave = xWave, negative = 1 )
			NMDecayTime2( dt )
			so.decayX = dt.xDecay
			so.decayT = dt.decayTime
			bsln = 1
			by = dt.baseline
			ay = dt.min
			ax = dt.minLoc
			apnt = dt.minRowLoc
			break
			
		case "FWHM+":
			NMFWHMStructInit( fwhm, bbgn, bend, xbgn, xend, wName, xWave = xWave )
			NMFWHM2( fwhm )
			so.riseXB = fwhm.x1
			so.riseXE = fwhm.x2
			so.riseT = fwhm.fwhm
			bsln = 1
			by = fwhm.baseline
			ay = fwhm.max
			ax = fwhm.maxLoc
			apnt = fwhm.maxRowLoc
			break
		
		case "FWHM-":
			NMFWHMStructInit( fwhm, bbgn, bend, xbgn, xend, wName, xWave = xWave, negative = 1 )
			NMFWHM2( fwhm )
			so.riseXB = fwhm.x1
			so.riseXE = fwhm.x2
			so.riseT = fwhm.fwhm
			bsln = 1
			by = fwhm.baseline
			ay = fwhm.min
			ax = fwhm.minLoc
			apnt = fwhm.minRowLoc
			break
			
	endswitch
	
	// save final amp values
	
	if ( !off )
	
		if ( bsln && si.subtractB )
			so.y = ay - by
		else
			so.y = ay
		endif
		
		strswitch( select )
		
			case "Slope":
			case "RTslope+":
			case "RTslope-":
				so.x = b
				so.y = m
				break
		
			case "RiseTime+":
			case "RiseTime-":
			case "FWHM+":
			case "FWHM-":
				so.x = so.riseT
				so.y = Nan
				break
				
			case "DecayTime+":
			case "DecayTime-":
				so.x = so.decayT
				so.y = Nan
				break
			
			default:
				so.x = ax
				
		endswitch
		
		so.xB = bx
		so.yB = by
		
		KillVariables /Z U_ax, U_ay
	
	endif
	
	NMStatsOutputsSave( so, win = win )
	
	if ( win != AmpNV )
		return 0 // only update display waves for current stats window
	endif
	
	if ( !show || off )
		return 0 // no more to do
	endif
	
	// baseline display waves
	
	if ( bsln )
		dw.bslnX[ 0 ] = bbgn
		dw.bslnX[ 1 ] = bend
		dw.bslnY = by
	endif
	
	// amplitude display waves
	
	strswitch( select )
	
		case "Avg":
		case "Avg+SDev":
		case "Avg+SEM":
		case "SDev":
		case "SEM":
		case "Var":
		case "RMS":
		case "NumPnts":
		case "Area":
		case "Sum":
		case "PathLength":
		case "Slope":
		case "RTslope+":
		case "RTslope-":
			dw.pntX = Nan
			dw.pntY = Nan
			break
			
		default:
			dw.pntX = ax
			dw.pntY = ay
			
	endswitch
	
	// rise/decay time display waves ( and FWHM )
	
	strswitch( select )
	
		case "RiseTime+":
		case "RiseTime-":
		case "RTslope+":
		case "RTslope-":
			dw.RDX[ 0 ] = so.riseXB
			dw.RDX[ 1 ] = so.riseXE
			dw.RDY[ 0 ] = ( ( si.risePB / 100 ) * ( ay - by ) ) + by
			dw.RDY[ 1 ] = ( ( si.risePE / 100 ) * ( ay - by ) ) + by
			break
			
		case "DecayTime+":
		case "DecayTime-":
			dw.RDX[ 0 ] = so.decayX
			dw.RDY[ 0 ] = ( ( si.decayP / 100 ) * ( ay - by ) ) + by
			break
		
		case "FWHM+":
		case "FWHM-":
			dw.RDX[ 0 ] = so.riseXB
			dw.RDX[ 1 ] = so.riseXE
			dw.RDY[ 0 ] = 0.5 * ( ay - by ) + by
			dw.RDY[ 1 ] = 0.5 * ( ay - by ) + by
			break
	
	endswitch
	
	// update window display line
	
	if ( StringMatch( select, "Avg+SDev" ) || StringMatch( select, "Avg+SEM" ) )
	
		if ( numpnts( dw.winY ) != 8 )
			Redimension /N=8 dw.winX, dw.winY
		endif
		
		dw.winX = NaN
		dw.winY = NaN
		
		dw.winX[ 0 ] = xbgn
		dw.winX[ 1 ] = xend
		
		dw.winX[ 3 ] = xbgn
		dw.winX[ 4 ] = xend
		
		dw.winX[ 6 ] = xbgn
		dw.winX[ 7 ] = xend
		
		dw.winY[ 0 ] = ay
		dw.winY[ 1 ] = ay
		
		dw.winY[ 3 ] = ay - ax
		dw.winY[ 4 ] = ay - ax
		
		dw.winY[ 6 ] = ay + ax
		dw.winY[ 7 ] = ay + ax
		
	else
	
		if ( numpnts( dw.winY ) != 2 )
			Redimension /N=2 dw.winX, dw.winY
		endif
		
		dw.winX[ 0 ] = xbgn
		dw.winX[ 1 ] = xend
		dw.winY = ay
	
	endif
		
	strswitch( select )
	
		case "SDev":
		case "SEM":
		case "Var":
		case "RMS":
		case "NumPnts":
		case "Area":
		case "Sum":
		case "PathLength":
			dw.winY = Nan // set to NAN because these are usually of different scale
			break
	
		case "Slope":
			dw.winY[ 0 ] = xbgn * m + b
			dw.winY[ 1 ] = xend * m + b
			break
			
		case "RTslope+":
		case "RTslope-":
			dw.winX[ 0 ] = so.riseXB // + xoffset
			dw.winX[ 1 ] = so.riseXE // + xoffset
			dw.winY[ 0 ] = so.riseXB * m + b
			dw.winY[ 1 ] = so.riseXE * m + b
			break
			
		case "MaxAvg":
		case "MinAvg":
			dw.winX[ 0 ] = ax - abs( avgWin / 2 )
			dw.winX[ 1 ] = ax + abs( avgWin / 2 )
			break
			
	endswitch
	
	return 0

End // StatsComputeWin

//****************************************************************
//****************************************************************
//
//	Stats result waves/table functions defined below
//
//****************************************************************
//****************************************************************

Function /S NMStatsWavesTable( folder, chan, windowList [ hide ] ) // create waves/table where Stats are stored
	String folder // data folder, ( "" ) for current data folder or ( "_subfolder_" ) for default subfolder
	Variable chan // channel number , ( -1 ) for current
	String windowList // list of windows to create ( "" ) for all currently active Stats windows
	Variable hide // ( 0 ) no ( 1 ) yes
	
	Variable wcnt
	String wName, wList, wList2, title, tprefix, tName = ""
	
	STRUCT Rect w
	
	NMOutputListsReset()
	
	folder = CheckNMStatsFolderPath( folder )
	
	if ( !DataFolderExists( folder ) )
		return NM2ErrorStr( 30, "folder", folder )
	endif
	
	chan = ChanNumCheck( chan )
	
	if ( ItemsInlist( windowList ) == 0 )
		windowList = NMStatsWinList( 1, "" )
	endif
	
	if ( ItemsInlist( windowList ) == 0 )
		return NM2ErrorStr( 21, "windowList", windowList )
	endif
	
	wList = StatsWavesMake( folder, chan, windowList )
	
	if ( ItemsInList( wList ) == 0 )
		return "" // no waves were made
	endif
	
	tprefix = "ST_" + NMFolderPrefix( "" ) + NMWaveSelectStr() + "_Table_"
	tName = NextGraphName( tprefix, chan, NMStatsVarGet( "OverwriteMode" ) )

	if ( WinType( tName ) == 0 )
	
		title = NMFolderListName( "" ) + " : Ch " + ChanNum2Char( chan ) + " : Stats : " + NMWaveSelectGet()
	
		NMWinCascadeRect( w )
		
		DoWindow /K $tName
		Edit /HIDE=(hide)/K=(NMK())/N=$tName/W=(w.left,w.top,w.right,w.bottom) as title
		ModifyTable /W=$tName title( Point )="Wave"
		
		for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
		
			wName = StringFromList( wcnt, wList )
			
			if ( WaveExists( $wName ) )
				AppendToTable /W=$tName $wName
			endif
			
		endfor
		
	elseif ( WinType( tName ) == 2 )
	
		DoWindow /F/HIDE=(hide) $tName
		
		wList2 = NMTableWaveList( tName, 1 )
	
		for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
		
			wName = StringFromList( wcnt, wList )
			
			if ( WaveExists( $wName ) && ( WhichListItem( wName, wList2 ) < 0 ) )
				AppendToTable /W=$tName $wName
			endif
			
		endfor
		
	endif
	
	SetNMstr( NMDF + "OutputWaveList", wList )
	SetNMstr( NMDF + "OutputWinList", tName )
	
	NMHistoryOutputWaves( subfolder = folder )
	NMHistoryOutputWindows()
	
	return tName

End // NMStatsWavesTable

//****************************************************************
//****************************************************************

Function /S StatsWavesMake( folder, chan, windowList )
	String folder // data folder, ( "" ) for current data folder or ( "_subfolder_" ) for current subfolder
	Variable chan // channel number
	String windowList // list of windows to create ( "" ) for all currently active Stats windows

	Variable icnt, jcnt, win, wselect, offset, xwave, ywave, setDefault, numWin, numWaves
	String wName, wNames, header, statsnote, wnote, xl, yl, select, wList = ""
	String tList, transform, wNameDefault = "", df = NMStatsDF
	
	String currentPrefix = CurrentNMWavePrefix()
	String currentWaveName = CurrentNMWaveName()
	
	String xLabel = NMChanLabelX( channel = chan )
	String yLabel = NMChanLabelY( channel = chan )
	
	String xUnits = UnitsFromStr( xLabel )
	String yUnits = UnitsFromStr( yLabel )
	
	Variable currentWin = NumVarOrDefault( df + "AmpNV", 0 )
	
	STRUCT NMStatsInputsStruct si
	
	folder = CheckNMStatsFolderPath( folder )
	
	if ( !DataFolderExists( folder ) )
		return NM2ErrorStr( 30, "folder", folder )
	endif
	
	chan = ChanNumCheck( chan )
	
	if ( ItemsInlist( windowList ) == 0 )
		windowList = NMStatsWinList( 1, "" )
	endif
	
	if ( ItemsInlist( windowList ) == 0 )
		return ""
	endif
	
	wName = "ST_OutputWaveNames"
	
	numWin = StatsNumWindows()
	
	Make /O/T/N=( numWin , 12 ) $( folder + wName ) = ""
	Wave /T outNames = $( folder + wName )
	
	SetDimLabel 1, 0, bsln, outNames
	SetDimLabel 1, 1, x, outNames
	SetDimLabel 1, 2, y, outNames
	SetDimLabel 1, 3, yerror, outNames
	SetDimLabel 1, 4, riseT, outNames
	SetDimLabel 1, 5, riseBX, outNames
	SetDimLabel 1, 6, riseEX, outNames
	SetDimLabel 1, 7, dcayT, outNames
	SetDimLabel 1, 8, dcayX, outNames
	SetDimLabel 1, 9, fwhmT, outNames
	SetDimLabel 1, 10, fwhmBX, outNames
	SetDimLabel 1, 11, fwhmEX, outNames
	
	wList = NMChanWaveList( chan )
	
	numWaves = ItemsInList( wList )
	
	xl = currentPrefix + " #"
	
	wNames = NMStatsWaveNameForWName( folder, chan, 1 )
	
	Make /T/O/N=( numWaves ) $wNames // create wave of wave names
	
	NMNoteType( wNames, "NMStats Wave Names", "", "", "" )
	
	Wave /T wtext = $wNames
	
	wtext = ""
	
	for ( icnt = 0 ; icnt < numWaves ; icnt += 1 )
		wtext[ icnt ] = StringFromList( icnt, wList )
	endfor
	
	wList = AddListItem( wNames, "", ";", inf )

	for ( icnt = 0; icnt < ItemsInList( windowList ) ; icnt += 1 )
	
		win = str2num( StringFromList( icnt, windowList ) )
		
		select = StatsAmpSelectGet( win )
	
		if ( StringMatch( select, "Off" ) )
			continue
		endif
		
		if ( NMStatsInputsGet( si, win = win ) < 0 )
			continue
		endif
		
		xwave = 1
		ywave = 1
		
		offset = StatsOffsetValue( win )
		
		if ( numtype( offset ) > 0 )
			offset = 0
		endif
		
		header = "WPrefix:" + currentPrefix
		header += NMCR + "ChanSelect:" + ChanNum2Char( chan )
		header += NMCR + "WaveSelect:" + NMWaveSelectGet()
		
		statsnote = NMCR + "Stats Wave Names:" + wNames
		statsnote += NMCR + "Stats Win:" + num2istr( win ) + ";Stats Alg:" + select + ";"
		statsnote += NMCR + "Stats Xbgn:" + num2str( si.xbgn+offset ) + ";Stats Xend:" + num2str( si.xend+offset ) + ";"
		
		if ( si.subtractB )
			statsnote += NMCR + "Stats Baselined:yes"
		else
			statsnote += NMCR + "Stats Baselined:no"
		endif
		
		if ( si.filterNum > 0 )
			statsnote += NMCR + "Filter Alg:" + si.filterFxn + ";Filter Num:" + num2str( si.filterNum ) + ";"
		endif
		
		for ( jcnt = 0 ; jcnt < ItemsInList( si.transform, ";" ) ; jcnt += 1 )
		
			tList = StringFromList( jcnt, si.transform, ";" )
			transform = StringFromList( 0, si.transform, "," )
			
			if ( WhichListItem( transform, NMChanTransformList ) >= 0 )
				statsnote += NMCR + "Transform:" + tList
			endif
			
		endfor
		
		yl = StatsYLabel( select )
		
		strswitch( select )
			case "RiseTime+":
			case "RiseTime-":
			case "DecayTime+":
			case "DecayTime-":
			case "FWHM+":
			case "FWHM-":
				ywave = 0
				break
			
		endswitch
		
		if ( ywave )
		
			wName = StatsWaveMake( folder, "AmpY", win, chan )
			NMNoteType( wName, "NMStats Yvalues", xl, yl, header + statsnote )
			wList = AddListItem( wName, wList, ";", inf )
			outNames[ win ][ %y ] = wName
			
			if ( win == currentWin )
				wNameDefault = NMChild( wName )
			endif
			
		endif
		
		yl = xLabel
		
		xwave = 1
		setDefault = 0
		
		strswitch( select )
		
			case "Avg":
			case "Median":
			case "SDev":
			case "Var":
			case "RMS":
			case "NumPnts":
			case "Area":
			case "Sum":
			case "PathLength":
				xwave = 0
				break
				
			case "Slope":
				yl = yLabel // intercept value
				break
			
			case "Onset":
			case "Level":
			case "Level+":
			case "Level-":
				setDefault = 1
				break
			
			case "RiseTime+":
			case "RiseTime-":
			case "DecayTime+":
			case "DecayTime-":
			case "FWHM+":
			case "FWHM-":
				xwave = 0
				break
		endswitch
		
		if ( xwave )
		
			if ( StringMatch( select, "Avg+SDev" ) )
			
				yl = StatsYLabel( select )
			
				wName = StatsWaveMake( folder, "SDevY", win, chan )
				NMNoteType( wName, "NMStats SDev", xl, yl, header + statsnote )
				wList = AddListItem( wName, wList, ";", inf )
				outNames[ win ][ %yerror ] = wName
				
			elseif ( StringMatch( select, "Avg+SEM" ) )
			
				yl = StatsYLabel( select )
			
				wName = StatsWaveMake( folder, "SEMY", win, chan )
				NMNoteType( wName, "NMStats SDev", xl, yl, header + statsnote )
				wList = AddListItem( wName, wList, ";", inf )
				outNames[ win ][ %yerror ] = wName
			
			else
		
				wName = StatsWaveMake( folder, "AmpX", win, chan )
				NMNoteType( wName, "NMStats Xvalues", xl, yl, header + statsnote )
				wList = AddListItem( wName, wList, ";", inf )
				outNames[ win ][ %x ] = wName
			
			endif
			
			if ( setDefault && ( win == currentWin ) )
				wNameDefault = NMChild( wName )
			endif
			
		endif
		
		if ( StatsRiseTimeFlag( win ) )
		
			if ( StringMatch( select[ 0,3 ], "FWHM" ) )
				
				yl = num2str( si.risePB ) + " - " + num2str( si.risePE ) + "% FWHM Time ( " + xUnits + " )"

				wName = StatsWaveMake( folder, "FwhmT", win, chan )
				wnote = NMCR + "FWHM %bgn:" + num2str( si.risePB ) + ";FWHM %end:" + num2str( si.risePE ) + ";"
				NMNoteType( wName, "NMStats FWHM Time", xl, yl, header + statsnote + wnote )
				wList = AddListItem( wName, wList, ";", inf )
				outNames[ win ][ %fwhmT] = wName
				
				if ( win == currentWin )
					wNameDefault = NMChild( wName )
				endif
				
				yl = num2str( si.risePB ) + "% FWHM Pnt ( " + xUnits + " )"
				
				wName = StatsWaveMake( folder, "FwhmBX", win, chan )
				wnote = NMCR + "FWHM %bgn:" + num2str( si.risePB )
				NMNoteType( wName, "NMStats FWHM Xbgn", xl, yl, header + statsnote + wnote )
				wList = AddListItem( wName, wList, ";", inf )
				outNames[ win ][ %fwhmBX ] = wName
				
				yl = num2str( si.risePE ) + "% FWHM Pnt ( " + xUnits + " )"
				
				wName = StatsWaveMake( folder, "FwhmEX", win, chan )
				wnote = NMCR + "FWHM %end:" + num2str( si.risePE )
				NMNoteType( wName, "NMStats FWHM Xend", xl, yl, header + statsnote + wnote )
				wList = AddListItem( wName, wList, ";", inf )
				outNames[ win ][ %fwhmEX ] = wName
			
			else
		
				yl = num2str( si.risePB ) + " - " + num2str( si.risePE ) + "% Rise Time ( " + xUnits + " )"
	
				wName = StatsWaveMake( folder, "RiseT", win, chan )
				wnote = NMCR + "Rise %bgn:" + num2str( si.risePB ) + ";Rise %end:" + num2str( si.risePE ) + ";"
				NMNoteType( wName, "NMStats Rise Time", xl, yl, header + statsnote + wnote )
				wList = AddListItem( wName, wList, ";", inf )
				outNames[ win ][ %riseT ] = wName
				
				if ( win == currentWin )
					wNameDefault = NMChild( wName )
				endif
				
				yl = num2str( si.risePB ) + "% " + "Rise" + " Pnt ( " + xUnits + " )"
				
				wName = StatsWaveMake( folder, "RiseBX", win, chan )
				wnote = NMCR + "Rise %bgn:" + num2str( si.risePB )
				NMNoteType( wName, "NMStats Rise Xbgn", xl, yl, header + statsnote + wnote )
				wList = AddListItem( wName, wList, ";", inf )
				outNames[ win ][ %riseBX ] = wName
				
				yl = num2str( si.risePE ) + "% Rise Pnt ( " + xUnits + " )"
				
				wName = StatsWaveMake( folder, "RiseEX", win, chan )
				wnote = NMCR + "Rise %end:" + num2str( si.risePE )
				NMNoteType( wName, "NMStats Rise Xend", xl, yl, header + statsnote + wnote )
				wList = AddListItem( wName, wList, ";", inf )
				outNames[ win ][ %riseEX ] = wName
			
			endif
			
		endif
		
		if ( StatsDecayTimeFlag( win ) )
		
			yl = num2str( si.decayP ) + "% Decay Time ( " + xUnits + " )"
		
			wName = StatsWaveMake( folder, "DcayT", win, chan )
			wnote = NMCR + "%Decay:" + num2str( si.decayP )
			NMNoteType( wName, "NMStats DecayTime", xl, yl, header + statsnote + wnote )
			wList = AddListItem( wName, wList, ";", inf )
			outNames[ win ][ %dcayT ] = wName
			
			if ( win == currentWin )
				wNameDefault = NMChild( wName )
			endif
			
			yl = num2str( si.decayP ) + "% Decay Pnt ( " + xUnits + " )"
			
			wName = StatsWaveMake( folder, "DcayX", win, chan ) 
			wnote = NMCR + "%Decay:" + num2str( si.decayP )
			NMNoteType( wName, "NMStats DecayPoint", xl, yl, header + statsnote + wnote )
			wList = AddListItem( wName, wList, ";", inf )
			outNames[ win ][ %dcayX ] = wName
			
		endif
		
		yl = StatsYLabel( si.selectB )
		
		if ( si.onB )
			wName = StatsWaveMake( folder, "Bsln", win, chan )
			wnote = NMCR + "Bsln Alg:" + si.selectB + ";Bsln Xbgn:" + num2str( si.xbgnB+offset ) + ";Bsln Xend:" + num2str( si.xendB+offset ) + ";"
			NMNoteType( wName, "NMStats Bsln", xl, yl, header + statsnote + wnote )
			wList = AddListItem( wName, wList, ";", inf )
			outNames[ win ][ %bsln ] = wName
		endif
		
	endfor
	
	SetNMstr( folder+"DefaultStats2Wave", wNameDefault )
	
	return wList

End // StatsWavesMake

//****************************************************************
//****************************************************************

Function /S NMStatsWaveNoteByKey( wName, keyName )
	String wName // wave name
	String keyName // e.g. "Alg" or "YLabel"
	
	String noteStr
	
	if ( strlen( wName ) == 0 )
		return ""
	endif
	
	if ( !WaveExists( $wName ) )
		return NM2ErrorStr( 1, "wName", wName )
	endif
	
	strswitch( keyName )
	
		case "Win":
		case "Alg":
		case "Xbgn":
		case "Xend":
		case "Baselined":
		case "Offset Type":
		case "Offset Baseline":
			return NMNoteStrByKey( wName, "Stats " + keyName)
	
		case "Xdim": // OLD
		case "XLabel":
		
			noteStr = NMNoteStrByKey( wName, "XLabel" )
			
			if ( strlen( noteStr ) == 0 )
				noteStr = NMNoteStrByKey( wName, "Xdim" )
			endif
	
			return noteStr
	
		case "Ydim": // OLD
		case "YLabel":
		
			noteStr = NMNoteStrByKey( wName, "YLabel" )
			
			if ( strlen( noteStr ) == 0 )
				noteStr = NMNoteStrByKey( wName, "Ydim" )
			endif
	
			return noteStr
		
		case "F(t)": // OLD
		case "Transform":
		
			noteStr = NMNoteStrByKey( wName, "Transform" )
			
			if ( strlen( noteStr ) == 0 )
				noteStr = NMNoteStrByKey( wName, "F(t)" )
			endif
	
			return noteStr
			
		case "Smooth Alg": // OLD
		case "Filter Alg":
		
			noteStr = NMNoteStrByKey( wName, "Filter Alg" )
			
			if ( strlen( noteStr ) == 0 )
				noteStr = NMNoteStrByKey( wName, "Smooth Alg" )
			endif
	
			return noteStr
			
		case "Smooth Num": // OLD
		case "Filter Num":
		
			noteStr = NMNoteStrByKey( wName, "Filter Num" )
			
			if ( strlen( noteStr ) == 0 )
				noteStr = NMNoteStrByKey( wName, "Smooth Num" )
			endif
	
			return noteStr
	
	endswitch
	
	return ""
	
End // NMStatsWaveNoteByKey

//****************************************************************
//****************************************************************

Function /S StatsWaveMake( folder, fxn, win, chan ) // create appropriate stats wave
	String folder
	String fxn
	Variable win // Stats window number
	Variable chan // channel number
	
	Variable overwrite = NMStatsVarGet( "OverwriteMode" )
	
	String wName = StatsWaveName( folder, win, fxn, chan, overwrite, 1 )
	
	if ( strlen( wName ) > 0 )
		Make /O/N=( NMNumWaves() ) $wName = NaN
	endif
	
	return wName

End // StatsWaveMake

//****************************************************************
//****************************************************************

Function /S NMStatsWaveNameForWName( folder, chan, fullPath )
	String folder
	Variable chan // channel number
	Variable fullPath // ( 0 ) only wave name ( 1 ) folder + wname
	
	Variable overwrite = NMStatsVarGet( "OverwriteMode" )

	return StatsWaveName( folder, Nan, "wName_", chan, overwrite, fullPath )
	
End // NMStatsWaveNameForWName

//****************************************************************
//****************************************************************

Function /S NMStatsWaveNameForWNameFind( statsWaveName )
	String statsWaveName // e.g. "ST_MaxY0_RAll_A0"
	
	Variable icnt, jcnt
	String folder, wList, wName, wName2
	
	wName = NMNoteStrByKey( statsWaveName, "Stats Wave Names" )
	
	if ( strlen( wName ) > 0 )
		return wName
	endif

	folder = NMParent( statsWaveName )
	wList = NMFolderWaveList( folder, "*_wName_*", ";", "TEXT:1", 0 )
	
	for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
	
		wName = StringFromList( icnt, wList )
		jcnt = strsearch( wName, "_wName_", 0, 2 )
		wName2 = wName[ jcnt + 7, inf ]
		
		if ( strsearch( statsWaveName, wName2, 0, 2 ) > 0 )
			if ( numpnts( $folder + NMChild( statsWaveName ) ) == numpnts( $folder + wName ) )
				return folder + wName // found the corresponding text wave ( e.g. "ST_wName_RAll_A0" )
			endif
		endif
		
	endfor
	
	return ""
		
End // NMStatsWaveNameForWNameFind

//****************************************************************
//****************************************************************

Function /S StatsWaveName( folder, win, fxn, chan, overWrite, fullPath )
	String folder
	Variable win // Stats window number
	String fxn
	Variable chan // channel number
	Variable overWrite
	Variable fullPath // ( 0 ) only wave name ( 1 ) folder + wname
	
	String wavePrefix, winStr = "", slctStr = ""
	
	if ( numtype( win ) == 0 )
		winStr = num2istr( win ) + "_"
	endif
	
	strswitch( fxn )
		case "AmpX":
			fxn = StatsAmpName( win, "X" )
			break
		case "AmpY":
			fxn = StatsAmpName( win, "Y" )
			break
	endswitch
	
	slctStr = NMWaveSelectStr() + "_"
	
	wavePrefix = "ST_" + fxn + winStr + slctStr
	
	if ( fullPath )
		return folder + NextWaveName2( folder, wavePrefix, chan, overWrite )
	else
		return NextWaveName2( folder, wavePrefix, chan, overWrite )
	endif

End // StatsWaveName

//****************************************************************
//****************************************************************

Function /S StatsAmpName( win, xyStr )
	Variable win // Stats window number
	String xyStr
	
	String fxn = StatsAmpSelectGet( win )
	
	strswitch( fxn )
		case "Avg+SDev":
			if ( stringMatch( xyStr, "x" ) )
				return "SDevY"
			endif
			if ( stringMatch( xyStr, "y" ) )
				return "AvgY"
			endif
			return "Avg" + xyStr
		case "Avg+SEM":
			if ( stringMatch( xyStr, "x" ) )
				return "SEMY"
			endif
			if ( stringMatch( xyStr, "y" ) )
				return "AvgY"
			endif
			return "Avg" + xyStr
		case "RiseTime+":
		case "RiseTime-":
			return "RiseT" + xyStr
		case "DecayTime+":
		case "DecayTime-":
			return "DcayT" + xyStr
		case "Level":
		case "Level+":
		case "Level-":
			return "Lev" + xyStr
		case "Slope":
			return "Slp" + xyStr
		case "RTslope+":
		case "RTslope-":
			return "RTslp" + xyStr
		case "FWHM+":
		case "FWHM-":
			return "Fwhm" + xyStr
		case "Off":
			return ""
	endswitch
	
	if ( StringMatch( fxn[0,5], "MaxAvg" ) )
		fxn = "MaxAvg"
	endif
	
	if ( StringMatch( fxn[0,5], "MinAvg" ) )
		fxn = "MinAvg"
	endif
	
	fxn = ReplaceString( ".", fxn, "p" )
	fxn = ReplaceString( "+", fxn, "p" )
	fxn = ReplaceString( "-", fxn, "n" )
	fxn = ReplaceString( " ", fxn, "" )
	
	return fxn + xyStr

End // StatsAmpName

//****************************************************************
//****************************************************************

Function /S NMStatsOutputWaveName( select [ folder, chan, win ] )
	String select
	String folder
	Variable chan, win
	
	String wName
	
	if ( ParamIsDefault( folder ) )
		folder = DEFAULTSUBFOLDER
	endif
	
	if ( ParamIsDefault( chan ) )
		chan = CurrentNMChannel()
	endif
	
	if ( ParamIsDefault( win ) )
		win = -1
	endif
	
	win = CheckNMStatsWin( win )
	
	if ( numtype( win ) > 0 )
		return ""
	endif
	
	folder = CheckNMStatsFolderPath( folder )
	
	if ( !DataFolderExists( folder ) )
		return NM2ErrorStr( 30, "folder", folder )
	endif
	
	wName = "ST_OutputWaveNames"
	
	if ( !WaveExists( $folder + wName ) )
		return ""
	endif
	
	Wave /T outNames = $folder + wName
	
	if ( ( win < 0 ) || ( win >= DimSize( outNames, 0 ) ) )
		return ""
	endif
	
	strswitch( select )
	
		case "x":
			return outNames[ win ][ %x ]
			
		case "y":
			return outNames[ win ][ %y ]
			
		case "yerror":
			return outNames[ win ][ %yerror ]
			
		case "riseT":
			return outNames[ win ][ %riseT ]
			
		case "riseBX":
			return outNames[ win ][ %riseBX ]
			
		case "riseEX":
			return outNames[ win ][ %riseEX ]
			
		case "dcayT":
			return outNames[ win ][ %dcayT ]
			
		case "dcayX":
			return outNames[ win ][ %dcayX ]
			
		case "bsln":
			return outNames[ win ][ %bsln ]
	
	endswitch
	
	return ""
	
End // NMStatsOutputWaveName

//****************************************************************
//****************************************************************

Function StatsAmpSave( folder, chan, waveNum, win, option ) // save, clear or delete results to appropriate Stat waves
	String folder
	Variable chan // channel number
	Variable waveNum
	Variable win // Stats window number
	Variable option // clear option ( 0 - save; 1 - clear; 2 - delete )
	
	Variable clear = 1
	String wName, select, rf = "Rise"
	
	String wselect = NMWaveSelectGet()
	
	STRUCT NMStatsInputWavesStruct si
	NMStatsInputWavesStructRef( si )
	
	STRUCT NMStatsOutputWavesStruct so
	NMStatsOutputWavesStructRef( so )
	
	win = CheckNMStatsWin( win )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	select = StatsAmpSelectGet( win )
	
	if ( StringMatch( select, "Off" ) )
		return 0
	endif
	
	if ( option == 1 )
		clear = Nan
	else
		clear = 1
	endif
	
	wName = StatsWaveName( folder, win, "AmpX", chan, 1, 1 )
	StatsAmpSave2( wName, waveNum, so.x[ win ], option )
	
	wName = StatsWaveName( folder, win, "AmpY", chan, 1, 1 )
	StatsAmpSave2( wName, waveNum, so.y[ win ], option )

	if ( si.onB[ win ] )
		wName = StatsWaveName( folder, win, "Bsln", chan, 1, 1 )
		StatsAmpSave2( wName, waveNum, so.yB[ win ], option )
	endif
		
	if ( StatsRiseTimeFlag( win ) )
	
		if ( StringMatch( select[ 0,3 ], "FWHM" ) )
			rf = "Fwhm"
		endif
	
		wName = StatsWaveName( folder, win, rf + "BX", chan, 1, 1 )
		StatsAmpSave2( wName, waveNum, so.riseXB[ win ], option )
		
		wName = StatsWaveName( folder, win, rf + "EX", chan, 1, 1 )
		StatsAmpSave2( wName, waveNum, so.riseXE[ win ], option )
		
		wName = StatsWaveName( folder, win, rf + "T", chan, 1, 1 )
		StatsAmpSave2( wName, waveNum, so.riseT[ win ], option )
		
	endif
		
	if ( StatsDecayTimeFlag( win ) )
	
		wName = StatsWaveName( folder, win, "DcayX", chan, 1, 1 )
		StatsAmpSave2( wName, waveNum, so.decayX[ win ], option )
		
		wName = StatsWaveName( folder, win, "DcayT", chan, 1, 1 )
		StatsAmpSave2( wName, waveNum, so.decayT[ win ], option )
		
	endif

End // StatsAmpSave

//****************************************************************
//****************************************************************

Function StatsAmpSave2( wName, waveNum, value, option )
	String wName // wave name
	Variable waveNum
	Variable value
	Variable option // clear option ( 0 - save; 1 - clear; 2 - delete )
	
	if ( !WaveExists( $wName ) )
		return -1
	endif
	
	if ( ( numtype( waveNum ) > 0 ) || ( waveNum < 0 ) || ( waveNum >= numpnts( $wName ) ) )
		return -1
	endif
	
	switch( option )
	
		case 0: // save
		
			Wave wtemp = $wName
			
			wtemp[ waveNum ] = value
			
			return 0
			
		case 1: // clear
		
			Wave wtemp = $wName
			
			wtemp[ waveNum ] = NaN
		
			return 0
			
		case 2: // delete
		
			DeletePoints waveNum, 1, $wName
			
			return 0
	
	endswitch
	
	return -1
	
End // StatsAmpSave2

//****************************************************************
//****************************************************************

Function /S StatsYLabel( select )
	String select
	
	String currentWaveName = CurrentNMWaveName()
	
	String xunits = NMChanLabelX( units = 1 )
	String yunits = NMChanLabelY( units = 1 )
	
	strswitch( select )
		case "SDev":
			return "Stdv ( " + yunits + " )"
		case "Var":
			return "Variance ( " + yunits + "^2 )"
		case "RMS":
			return "RMS ( " + yunits + " )"
		case "NumPnts":
			return "Points"
		case "Area":
			return "Area ( " + yunits + " * " + xunits + " )"
		case "Sum":
			return "Sum ( " + yunits + " * " + xunits + " )"
		case "PathLength":
			return "PathLength"
		case "Slope":
			return "Slope ( " + yunits + " / " + xunits + " )"
	endswitch
	
	return NMChanLabelY()
	
End // StatsYLabel

//****************************************************************
//****************************************************************

Function /S NMStatsWaveListOfType( statsFolder, optionsStr, wType )
	String statsFolder
	String optionsStr
	String wType // wave type, "X" or "Y"
	
	Variable wcnt
	String wName, wtype2, wList2 = ""

	String wList = NMFolderWaveList( statsFolder, "*", ";", optionsStr, 1 )
	
	for ( wcnt= 0 ; wcnt < ItemsInList ( wList ) ; wcnt += 1 )
		
		wName = StringFromList( wcnt, wList )
		
		wtype2 = NMStatsWaveTypeXY( wName )
		
		if ( StringMatch( wtype, wType2 ) )
			wList2 += NMChild( wName ) + ";"
		endif
		
	endfor
	
	return wList2
	
End // NMStatsWaveListOfType

//****************************************************************
//****************************************************************

Function /S NMStatsWaveTypeXY( wName )
	String wName // wave name
	
	String wtype
	
	wName = CheckNMStatsWavePath( wName )
	
	if ( !WaveExists( $wName ) )
		return NM2ErrorStr( 1, "wName", wName )
	endif

	wtype = NMNoteStrByKey( wName, "Type" )
	
	strswitch( wtype )
	
		case "NMStats Xvalues":
		case "NMStats Rise Tbgn":
		case "NMStats Rise Tend":
		case "NMStats Rise Xbgn":
		case "NMStats Rise Xend":
		case "NMStats FWHM Tbgn":
		case "NMStats FWHM Tend":
		case "NMStats FWHM Xbgn":
		case "NMStats FWHM Xend":
		case "NMStats DecayPoint":
			return "X"
	
	endswitch
	
	return "Y"
	
End // NMStatsWaveTypeXY

//****************************************************************
//****************************************************************

Function StatsWinNum( wName ) // return the amplitude/window number, given wave name
	String wName // wave name
	
	Variable win, icnt, ibgn, iend
	String winStr
	
	if ( strlen( wName ) == 0 )
		return -1
	endif
	
	winStr = NMNoteStrByKey( wName, "Stats Win" )
	
	win = str2num( winStr )
	
	if ( ( strlen( winStr ) > 0 ) && ( numtype( win ) == 0 ) && ( win >= 0 ) )
		return win
	endif
	
	if ( !StringMatch( wName[ 0,2 ], "ST_" ) && !StringMatch( wName[ 0,2 ], "ST2_" ) )
		return -1 // not a Stats wave
	endif
	
	iend = strsearch( wName, "_", 4 ) - 1
	
	if ( iend < 0 )
		return -1
	endif
	
	if ( StringMatch( wName[ 0,6 ], "ST_Bsln" ) ) // baseline wave
	
		ibgn = 7
		
	else
	
		for ( icnt = iend - 1; icnt >= iend - 3; icnt -= 1 )
			if ( StringMatch( wName[ icnt, icnt ], "X" ) || StringMatch( wName[ icnt, icnt ], "Y" ) || StringMatch( wName[ icnt, icnt ], "T" ) )
				ibgn = icnt + 1
				break
			endif
		endfor
	
	endif
	
	win = str2num( wName[ ibgn, iend ] )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	if ( win >= 0 )
		return win
	else
		return -1
	endif
	
End // StatsWinNum

//****************************************************************
//****************************************************************
//
//		Stats Subfolder Functions
//
//****************************************************************
//****************************************************************

Function /S CurrentNMStatsSubfolder()

	return NMStatsSubfolder( CurrentNMWavePrefix(), CurrentNMChannel() )
	
End // CurrentNMStatsSubfolder

//****************************************************************
//****************************************************************

Function /S NMStatsSubfolder( wavePrefix, chan )
	String wavePrefix
	Variable chan // channel number
	
	if ( !NMStatsVarGet( "UseSubfolders" ) )
		return ""
	endif
	
	if ( strlen( wavePrefix ) ==0 )
		wavePrefix = CurrentNMWavePrefix()
	endif
	
	return NMSubfolderName( "Stats_", wavePrefix, chan, NMWaveSelectShort() )

End // NMStatsSubfolder

//****************************************************************
//****************************************************************
//
//		Stats2 Functions
//
//****************************************************************
//****************************************************************

Function /S NMStats2Call( fxn, select )
	String fxn
	String select
	
	String folder, wName, errorStr
	
	Variable allStats2 = NMStatsVarGet( "ST_2FxnAll" )
	
	if ( ( strlen( fxn ) == 0 ) || StringMatch( fxn, " " ) )
		return ""
	endif
	
	strswitch( fxn )
	
		case "2FolderSelect":
			NMStatsSet( folderSelect = select, history = 1 )
			return ""
			
		case "2WaveSelect":
			NMStatsSet( waveSelect = select, history = 1 )
			return ""
			
		case "2FxnAll":
			allStats2 = BinaryInvert( allStats2 )
			NMStatsSet( allStats2 = allStats2, history = 1 )
			return ""
			
	endswitch
	
	if ( strlen( CurrentNMStats2WaveSelect( 1 ) ) == 0 )
		NMDoAlert( "There is no Stats2 wave selection." )
		return ""
	endif
	
	strswitch( fxn )
	
		case " ":
			return ""
			
		case "Plot":
			
			if ( allStats2 )
				return z_NMStatsPlotCall( all = 1 )
			else
				return z_NMStatsPlotCall()
			endif
			
		case "Edit":
		
			folder = CurrentNMStats2FolderSelect( 0 )
			wName = CurrentNMStats2WaveSelect( 0 )
			
			if ( allStats2 )
				return NMStatsEdit( folder = folder, history = 1 )
			else
				return NMStatsEdit( folder = folder, wList = wName, history = 1 )
			endif
			
		case "Wave Stats":
		
			if ( allStats2 )
			
				return z_NMStatsWaveStatsCall()
			
			else
			
				folder = CurrentNMStats2FolderSelect( 0 )
				wName = CurrentNMStats2WaveSelect( 0 )
			
				return NMStatsWaveStats( folder = folder, wList = wName, history = 1 )
			
			endif
			
		case "Print Note":
		
			folder = CurrentNMStats2FolderSelect( 0 )
			wName = CurrentNMStats2WaveSelect( 0 )
			
			return NMStatsWaveNotes( folder = folder, wList = wName, history = 1 )
			
		case "Print Notes":
			return z_NMStatsWaveNotesCall()
		
		case "Print Name":
			NMHistory( NMCR + CurrentNMStats2WaveSelect( 1 ) )
			return ""
			
		case "Print Names":
			return z_NMStatsWaveNamesCall()
		
		case "Histogram":
			return NMStatsHistogramCall( "" )
			
		case "Inequality":
		case "Inequality <>":
			return z_NMStatsInequalityCall()
			
		case "Stability":
		case "Stationarity":
			return NMStats2StabilityCall()
			
		case "Significant Difference":
			return NMStats2SigDiffCall()
			
		case "MPFA":
		case "MPFA Stats":
			return z_NMStatsMPFAStatsCall()
			
		case "Use For Wave Scaling":
			return z_NMStatsWaveScaleCall()
			
		case "Use For Wave Alignment":
			return z_NMStatsWaveAlignmentCall()
	
		case "Delete Stats Subfolder":
			return z_NMStatsSubfolderKillCall()
			
		case "Clear Stats Subfolder":
			return z_NMStatsSubfolderClearCall()
			
		default:
			return NM2ErrorStr( 20, "fxn", fxn )
			
	endswitch

End // NMStats2Call

//****************************************************************
//****************************************************************

Function /S NMStats2FolderList( restrictToCurrentPrefix )
	Variable restrictToCurrentPrefix
	
	String folderList = AddListItem( CurrentNMFolder( 0 ), "", ";", inf )
	
	String statsFolderList = NMSubfolderList2( GetDataFolder( 1 ), "Stats_", 0, restrictToCurrentPrefix )
	String spikeFolderList = NMSubfolderList2( GetDataFolder( 1 ), "Spike_", 0, restrictToCurrentPrefix )
	String eventFolderList = NMSubfolderList2( GetDataFolder( 1 ), "Event_", 0, restrictToCurrentPrefix )
	String fitFolderList = NMSubfolderList2( GetDataFolder( 1 ), "Fit_", 0, restrictToCurrentPrefix )

	return folderList + statsFolderList + spikeFolderList + eventFolderList + fitFolderList

End // NMStats2FolderList

//****************************************************************
//****************************************************************

Function /S CheckNMStats2FolderWaveSelect()

	String wList, wName = ""

	String folder = StrVarOrDefault( "CurrentStats2Folder", "" )
	String folderList = NMStats2FolderList( 0 )
	
	if ( ( strlen( folder ) == 0 ) || ( WhichListItem( folder, folderList ) < 0 ) )
		folder = StringFromList( 0, folderList )
		SetNMstr( "CurrentStats2Folder", folder )
	endif
	
	folder = CheckNMStatsFolderPath( folder )
	
	if ( !DataFolderExists( folder ) )
		folder = ""
		SetNMstr( "CurrentStats2Folder", "" )
	endif
	
	wList = NMStats2WaveSelectList( 0 )
	
	if ( ItemsInList( wList ) > 0 )
	
		wName = StrVarOrDefault( folder +"CurrentStats2Wave", "" )
		
		if ( ( strlen( wName ) > 0 ) && ( WhichListItem( wName, wList ) >= 0 ) )
			return wName // current selection is OK
		endif
		
		wName = StrVarOrDefault( folder +"DefaultStats2Wave", "" )
		
		if ( ( strlen( wName ) == 0 ) || ( WhichListItem( wName, wList ) < 0 ) )
			wName = StringFromList( 0, wList )
		endif
		
	endif
	
	SetNMstr( folder +"CurrentStats2Wave", wName )
	
	return wName

End // CheckNMStats2FolderWaveSelect

//****************************************************************
//****************************************************************

Function /S CurrentNMStats2FolderSelect( fullPath )
	Variable fullPath // ( 0 ) only wave name ( 1 ) folder + wname

	String folder = StrVarOrDefault( "CurrentStats2Folder", "" )
	
	if ( StringMatch( folder, CurrentNMFolder( 0 ) ) )
		return CurrentNMFolder( fullPath )
	endif
	
	if ( ( strlen( folder ) == 0 ) || !DataFolderExists( folder ) )
		return ""
	endif
	
	if ( fullPath == 1 )
		return CurrentNMFolder( 1 ) + folder + ":"
	else
		return folder
	endif

End // CurrentNMStats2FolderSelect

//****************************************************************
//****************************************************************

Function /S CurrentNMStats2WaveSelect( fullPath )
	Variable fullPath // ( 0 ) only wave name ( 1 ) folder + wname
	
	String wName
	
	String folder = CurrentNMStats2FolderSelect( 1 )
	
	wName = StrVarOrDefault( folder+"CurrentStats2Wave", "" )
	
	if ( ( strlen( wName ) > 0 ) && WaveExists( $folder+wName ) )
	
		if ( fullPath == 1 )
			return folder + wName
		else
			return wName
		endif
	
	endif
	
	return ""

End // CurrentNMStats2WaveSelect

//****************************************************************
//****************************************************************

Function /S NMStats2WaveSelectList( fullPath [ folder ] )
	Variable fullPath // ( 0 ) only wave name ( 1 ) folder + wname
	String folder

	Variable icnt, wnum, removeMore
	String numstr, wName, removeList = "", wList = "", wList2 = ""
	
	if ( ParamIsDefault( folder ) )
		folder = CurrentNMStats2FolderSelect( 1 )
	elseif ( !DataFolderExists( folder ) )
		return ""
	endif
	
	String filter = StrVarOrDefault( folder+"WaveListFilter", "Stats1" )
	
	if ( strlen( filter ) == 0 )
		filter = "Stats1"
	endif
	
	removeList = NMFolderWaveList( folder, "*Offset*", ";", "Text:0", fullPath )
	
	if ( StringMatch( filter, "All Stats" ) )
	
		wList = NMFolderWaveList( folder, "ST_*", ";", "Text:0", fullPath ) 
		wList += NMFolderWaveList( folder, "ST2_*", ";", "Text:0", fullPath )
		
	elseif ( StringMatch( filter, "Stats1" ) )
	
		wList = NMFolderWaveList( folder, "ST_*", ";", "Text:0", fullPath )
		removeMore = 1
	
	elseif ( StringMatch( filter, "Stats2" ) )
	
		wList = NMFolderWaveList( folder, "ST2_*", ";", "Text:0", fullPath )
		wList += NMFolderWaveList( folder, "ST_*Hist*", ";", "Text:0", fullPath )
		wList += NMFolderWaveList( folder, "ST_*Sort*", ";", "Text:0", fullPath )
		wList += NMFolderWaveList( folder, "ST_*ROp*", ";", "Text:0", fullPath )
		wList += NMFolderWaveList( folder, "ST_*Stb*", ";", "Text:0", fullPath )
		wList += NMFolderWaveList( folder, "ST_*Stable*", ";", "Text:0", fullPath )
		
	elseif ( StringMatch( filter, "Any" ) )
	
		wList = NMFolderWaveList( folder, "*", ";", "Text:0", fullPath )
		
	elseif ( StringMatch( filter[ 0, 2 ], "Win" ) )
		
		removeMore = 1
		wnum = str2num( filter[ 3,inf ] )
		
		if ( numtype( wnum ) > 0 )
			return "" // error
		endif
		
		wList = NMFolderWaveList( folder, "ST_*", ";", "Text:0", fullPath )
	
		numstr = num2istr( wnum ) + "_*"
		
		for ( icnt = 0; icnt < ItemsInList( wList ); icnt += 1 )
		
			wName = StringFromList( icnt, wList )
			
			if ( StringMatch( wName, "*ST_Bsln"+numstr ) )
				wList2 = AddListItem( wName, wList2, ";", inf )
			elseif ( StringMatch( wName, "*ST_*X"+numstr ) )
				wList2 = AddListItem( wName, wList2, ";", inf )
			elseif ( StringMatch( wName, "*ST_*Y"+numstr ) )
				wList2 = AddListItem( wName, wList2, ";", inf )
			elseif ( StringMatch( wName, "*ST_RiseT"+numstr ) )
				wList2 = AddListItem( wName, wList2, ";", inf )
			elseif ( StringMatch( wName, "*ST_DcayT"+numstr ) )
				wList2 = AddListItem( wName, wList2, ";", inf )
			endif
			
		endfor
		
		wList = wList2
		
	else // user-defined "Other"
	
		wList = NMFolderWaveList( folder, filter, ";", "Text:0", fullPath )
	
	endif
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	if ( removeMore )
		//removeList += NMFolderWaveList( folder, "ST_*Hist*", ";", "Text:0", fullPath )
		removeList += NMFolderWaveList( folder, "ST_*Sort*", ";", "Text:0", fullPath )
		removeList += NMFolderWaveList( folder, "ST_*ROp*", ";", "Text:0", fullPath )
		removeList += NMFolderWaveList( folder, "ST_*Stb*", ";", "Text:0", fullPath )
		//removeList += NMFolderWaveList( folder, "ST_*Stable*", ";", "Text:0", fullPath )
	endif
	
	wList = RemoveFromList( removeList, wList, ";" )
	
	return wList
	
End // NMStats2WaveSelectList

//****************************************************************
//****************************************************************

Function /S NMStats2WaveSelectFilterCall()

	String folder = CurrentNMStats2FolderSelect( 1 )
	String filter = StrVarOrDefault( folder+"WaveListFilter", "Stats1" )
	String matchList = "All Stats;Stats1;Stats2;" + NMStatsWinList( 1, "Win" ) + "Any;Other;"
	
	if ( WhichListItem( filter, matchList ) < 0 )
		filter = "Stats1"
	endif
	
	Prompt filter, " ", popup matchList
	DoPrompt "Stats2 Wave List Filter", filter
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( StringMatch( filter, "Other" ) )
	
		filter = "ST_*"
		
		Prompt filter, "enter a wave list match string:"
		DoPrompt "Stats2 Wave List Match String", filter
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		if ( strsearch( filter, "*", 0 ) < 0 )
			NMDoAlert( "Warning: your match string does not contain a star character " + NMQuotes( "*" ) )
		endif
			
	endif
	
	return NMStats2WaveSelectFilter( filter, history = 1 )

End // NMStats2WaveSelectFilterCall

//****************************************************************
//****************************************************************

Function /S NMStats2WaveSelectFilter( filter [ history ] )
	String filter // "All Stats" or "Stats1" or "Stats2" or "Any" or "Win0" or "Win1" or "ST_*"
	Variable history
	
	String wList, wName = "", vlist = ""
	String folder = CurrentNMStats2FolderSelect( 1 )
	
	if ( history )
		vlist = NMCmdStr( filter, vlist )
		NMCommandHistory( vlist )
	endif
	
	if ( strlen( filter ) == 0 )
		filter = "Stats1"
	endif
	
	SetNMstr( folder+"WaveListFilter", filter )
	
	UpdateStats2()
	
	return filter
	
End // NMStats2WaveSelectFilter

//****************************************************************
//****************************************************************

Static Function /S z_NMStatsPlotCall( [ all ] )
	Variable all

	Variable npnts
	String optionStr = ""

	String folder = CurrentNMStats2FolderSelect( 1 )
	String fNameShort = NMChild( folder )
	String fSelect = " "
	String folderList = NMStats2FolderList( 0 )
	
	String waveNameY = CurrentNMStats2WaveSelect( 1 )
	String ySelect = NMChild( waveNameY )
	String yList = NMStats2WaveSelectList( 0 )
	
	String xWave = CALCULATED
	String xSelect = xWave
	String xList = yList
	
	if ( WaveExists( $waveNameY ) )
		npnts = numpnts( $waveNameY )
		optionStr = NMWaveListOptions( npnts, 0 )
	endif
	
	xList = NMFolderWaveList( folder, "*", ";", optionStr, 0 )
	
	folderList = RemoveFromList( fNameShort, folderList )
	
	Prompt ySelect, "select y-axis wave:", popup yList
	Prompt xSelect, "select x-axis wave:", popup "_calculated_;" + xList
	Prompt fSelect, "or select a folder to locate x-axis wave:", popup " ;" + folderList
	
	if ( all )
	
		DoPrompt "Plot All Stats Waves", xSelect, fSelect
	
		if ( V_flag == 1 )
			return "" // cancel
		endif
	
	else
	
		DoPrompt "Plot Stats Wave", ySelect, xSelect, fSelect
	
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		if ( !WaveExists( $folder+ySelect ) )
			return "" // something went wrong
		endif
	
	endif
	
	if ( !StringMatch( xSelect, CALCULATED ) )
		xSelect = folder + xSelect
	endif
	
	if ( !StringMatch( fSelect, " " ) ) // folder has been selected
	
		fSelect = CheckNMStatsFolderPath( fSelect )
	
		npnts = numpnts( $folder+ySelect )
		optionStr = NMWaveListOptions( npnts, 0 )
	
		xList = NMFolderWaveList( fSelect, "*", ";", optionStr, 0 ) // look for waves of same dimension as ySelect
		
		xWave = CALCULATED
		
		Prompt xSelect, "select x-axis wave:", popup "_calculated_;" + xList
		DoPrompt "Plot Stats Wave", xSelect
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		if ( !StringMatch( xSelect, CALCULATED ) )
			
			if ( strlen( fSelect ) > 0 )
				xSelect = fSelect + xSelect
			endif
		endif
	
	endif
	
	if ( all )
		return NMStatsPlot( folder = fNameShort, xWave = xSelect, all = 1, history = 1 )
	else
		return NMStatsPlot( folder = fNameShort, wList = ySelect, xWave = xSelect, history = 1 )
	endif
	
End // NMStatsPlotCall

//****************************************************************
//****************************************************************

Function /S NMStatsPlot( [ folder, wList, xWave, all, onePlot, hide, history ] )
	String folder // folder or subfolder, nothing for current Stats subfolder
	String wList // wave list, nothing for current Stats wave select
	String xWave // x-axis wave name, nothing to use y-wave x-scaling
	Variable all // all waves inside folder ( do not pass wList )
	Variable onePlot // ( 0 ) seperate plot for each wave in wList ( 1 ) one plot for all waves
	Variable hide // ( 0 ) no ( 1 ) yes
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable wcnt
	String wName, gName, gList = "", vlist = ""
	
	if ( ParamIsDefault( folder ) )
		folder = SELECTED
	else
		vlist = NMCmdStrOptional( "folder", folder, vlist )
	endif
	
	folder = CheckNMStatsFolderPath( folder )
	
	if ( !DataFolderExists( folder ) )
		return NM2ErrorStr( 30, "folder", folder )
	endif
	
	if ( ParamIsDefault( wList ) )
	
		if ( ParamIsDefault( all ) )
		
			wList = StrVarOrDefault( folder + "CurrentStats2Wave", "" )
		
		else
		
			wList = NMStats2WaveSelectList( 0, folder = folder )
		
			vlist = NMCmdNumOptional( "all", all, vlist )
		
		endif
		
	else
	
		vlist = NMCmdStrOptional( "wList", wList, vlist )
		
	endif
	
	if ( ( strlen( wList ) == 0 ) || StringMatch( wList, SELECTED ) )
		wList = StrVarOrDefault( folder + "CurrentStats2Wave", "" )
	endif
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	wName = StringFromList( 0, wList )
	
	if ( !WaveExists( $folder+wName ) || ( WaveType( $folder+wName ) == 0 ) )
		return NM2ErrorStr( 1, "wName", wName )
	endif
	
	if ( ParamIsDefault( xWave ) )
		
		xWave = ""
		
	else
	
		if ( StringMatch( xWave, CALCULATED ) )
			xWave = ""
		endif
		
		if ( strlen( xWave ) > 0 )
			vlist = NMCmdStrOptional( "xWave", xWave, vlist )
		endif
		
	endif
	
	if ( strlen( xWave ) > 0 )
	
		if ( strsearch( xWave, ":", 0 ) == -1 )
			xWave = folder + xWave // create full-path name
		endif
		
		if ( !WaveExists( $xWave ) || ( WaveType( $xWave ) == 0 ) )
			return NM2ErrorStr( 1, "xWave", xWave )
		endif
		
	endif
	
	if ( !ParamIsDefault( onePlot ) )
		vlist = NMCmdNumOptional( "onePlot", onePlot, vlist, integer = 1 )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( onePlot )
	
		return z_NMStatsPlot( folder, wList, xWave, hide )
		
	else
		
		for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
			wName = StringFromList( wcnt, wList )
			gName = z_NMStatsPlot( folder, wName, xWave, hide )
			gList = AddListItem( gName, gList, ";", inf )
		endfor
	
		return gList
	
	endif
	
End // NMStatsPlot

//****************************************************************
//****************************************************************

Static Function /S z_NMStatsPlot( folder, wList, xWave, hide )
	String folder // folder or subfolder, nothing for current Stats subfolder
	String wList // wave list
	String xWave // x-axis wave name, nothing to use y-wave x-scaling
	Variable hide
	
	Variable wcnt, xbgn, xend
	String alg, txt, gTitle, sName, xLabelList = "", yLabelList = "", wList2 = ""
	
	STRUCT Rect w
	
	NMOutputListsReset()
	
	Variable numWaves = ItemsInList( wList )
	
	String wName = StringFromList( 0, wList )
	String wNameShort = NMChild( wName )
	
	String gName = wNameShort + "_" + NMFolderPrefix( "" ) + "Plot"
	
	gName = NMCheckStringName( gName )
	
	String type = NMNoteStrByKey( folder+wName, "Type" )
	String transform = NMStatsWaveNoteByKey( folder+wName, "Transform" )
	
	String filterA = NMStatsWaveNoteByKey( folder+wName, "Filter Alg" )
	Variable filterN = str2num( NMStatsWaveNoteByKey( folder+wName, "Filter Num" ) )
	
	String xLabel = NMStatsWaveNoteByKey( folder+wName, "XLabel" )
	String yLabel = NMStatsWaveNoteByKey( folder+wName, "YLabel" )
	
	if ( strlen( xLabel ) == 0 )
		xLabel = "Wave #"
	endif
	
	if ( strlen( yLabel ) == 0 )
		yLabel = wNameShort
	endif
	
	strswitch( type )
	
		default:
			alg = NMNoteStrByKey( folder+wName, "Stats Alg" )
			xbgn = NMNoteVarByKey( folder+wName, "Stats Xbgn" )
			xend = NMNoteVarByKey( folder+wName, "Stats Xend" )
			break
			
		case "NMStats Bsln":
			alg = "Bsln " + NMNoteStrByKey( folder+wName, "Bsln Alg" )
			xbgn = NMNoteVarByKey( folder+wName, "Bsln Xbgn" )
			xend = NMNoteVarByKey( folder+wName, "Bsln Xend" )
			break
			
	endswitch
	
	txt = alg + " ( "
	
	txt += num2str( xbgn ) + " to " + num2str( xend ) + " ms"
	
	if ( strlen( transform ) > 0 )
		txt += ";" + transform
	endif
	
	if ( strlen( filterA ) > 0 )
		txt += ";" + filterA + ",N=" + num2istr( filterN )
	endif
	
	txt += " )"
	
	if ( strlen( folder ) > 0 )
		gTitle = NMFolderListName( "" ) + " : " + NMChild( folder ) + " : " + wNameShort
	else
		gTitle = NMFolderListName( "" ) + " : " + wName
	endif
	
	DoWindow /K $gName
	
	NMWinCascadeRect( w )
	
	if ( ( strlen( xWave ) > 0 ) && WaveExists( $xWave ) )
	
		gTitle += " vs " + NMChild( xWave )
		xLabel = NMStatsWaveNoteByKey( xWave, "YLabel" )
		
		Display /HIDE=(hide)/K=(NMK())/N=$gName/W=(w.left,w.top,w.right,w.bottom) $folder+wName vs $xWave as gTitle
		
	else
	
		Display /HIDE=(hide)/K=(NMK())/N=$gName/W=(w.left,w.top,w.right,w.bottom) $folder+wName as gTitle
		
	endif
	
	wList2 = AddListItem( folder + wName, wList2, ";", inf )
	
	if ( WinType( gName ) == 0 )
		return ""
	endif
	
	if ( numWaves == 1 )
	
		Label /W=$gName bottom xLabel
		Label /W=$gName left yLabel
		TextBox /W=$gName/C/N=stats2title/F=2/E=1/A=MT txt
	
	else
	
		if ( strlen( xLabel ) > 0 )
			xLabelList = NMAddToList( xLabel, xLabelList, ";" )
		endif
		
		if ( strlen( yLabel ) > 0 )
			yLabelList = NMAddToList( yLabel, yLabelList, ";" )
		endif
	
		for ( wcnt = 1 ; wcnt < numWaves ; wcnt += 1 )
		
			wName = StringFromList( wcnt, wList )
			
			if ( strlen( xWave ) > 0 )
				xLabel = NMStatsWaveNoteByKey( xWave, "YLabel" )
			else
				xLabel = NMStatsWaveNoteByKey( folder+wName, "XLabel" )
			endif
			
			yLabel = NMStatsWaveNoteByKey( folder+wName, "YLabel" )
			
			if ( strlen( xLabel ) > 0 )
				xLabelList = NMAddToList( xLabel, xLabelList, ";" )
			endif
			
			if ( strlen( yLabel ) > 0 )
				yLabelList = NMAddToList( yLabel, yLabelList, ";" )
			endif
			
			if ( ( strlen( xWave ) > 0 ) && WaveExists( $xWave ) )
				AppendToGraph /W=$gName $folder+wName vs $xWave
			else
				AppendToGraph /W=$gName $folder+wName
			endif
			
			wList2 = AddListItem( folder + wName, wList2, ";", inf )
			
		endfor
		
		if ( ItemsInList( xLabelList ) == 1 )
			xLabel = StringFromList( 0, xLabelList )
			Label /W=$gName bottom xLabel
		endif
		
		if ( ItemsInList( yLabelList ) == 1 )
			yLabel = StringFromList( 0, yLabelList )
			Label /W=$gName left yLabel
		endif
	
	endif
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		wNameShort = NMChild( wName )
		alg = NMNoteStrByKey( folder+wName, "Stats Alg" )
	
		strswitch( alg )
		
			case "Avg+SDev":
			
				sName = ReplaceString( "Avg", wName, "SDev" )
				
				if ( WaveExists( $folder+sName ) )
					ErrorBars /W=$gName $wNameShort, Y, wave=($folder+sName,$folder+sName)
				endif
				
				break
				
			case "Avg+SEM":
			
				sName = ReplaceString( "Avg", wName, "SEM" )
				
				if ( WaveExists( $sName ) )
					ErrorBars /W=$gName $wNameShort, Y, wave=($folder+sName,$folder+sName)
				endif
				
				break
		
		endswitch
	
	endfor
	
	ModifyGraph /W=$gName mode=4, marker=19, standoff=0, rgb=(0,0,0)
	
	SetNMstr( NMDF + "OutputWaveList", wList2 )
	SetNMstr( NMDF + "OutputWinList", gName )
	
	NMHistoryOutputWindows( fxn = "NMStatsPlot" )
	
	return gName

End // z_NMStatsPlot

//****************************************************************
//****************************************************************

Function /S NMStatsEdit( [ folder, wList, hide, history ] )
	String folder // folder or subfolder, or nothing for current Stats subfolder
	String wList // wave list
	Variable hide // ( 0 ) no ( 1 ) yes
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable wcnt, numWaves
	String wName, wNameShort, title, tName, waveOfWaveNames, vlist = "", wList2 = ""
	
	STRUCT Rect w
	
	NMOutputListsReset()
	
	if ( ParamIsDefault( folder ) )
		folder = SELECTED
	else
		vlist = NMCmdStrOptional( "folder", folder, vlist )
	endif
	
	folder = CheckNMStatsFolderPath( folder )
	
	if ( !DataFolderExists( folder ) )
		return NM2ErrorStr( 30, "folder", folder )
	endif
	
	if ( ParamIsDefault( wList ) )
		wList = NMStats2WaveSelectList( 0, folder = folder )
	else
		vlist = NMCmdStrOptional( "wList", wList, vlist )
	endif
	
	if ( ( strlen( wList ) == 0 ) || StringMatch( wList, SELECTED ) )
		wList = NMStats2WaveSelectList( 0, folder = folder )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	numWaves = ItemsInList( wList )
	
	if ( numWaves == 0 )
		return ""
	endif
	
	wName = StringFromList( 0, wList )
	wNameShort = NMChild( wName )
	
	if ( !WaveExists( $folder+wName ) )
		return NM2ErrorStr( 1, "wName", wName )
	endif
	
	title = NMFolderListName( "" )
	
	if ( strlen( folder ) > 0 )
		title += " : " + NMChild( folder )
	endif
	
	if ( numWaves == 1 )
		title += " : " + wNameShort
	endif
	
	tName = "ST_" + NMFolderPrefix( "" )
	
	if ( strlen( folder ) > 0 )
		tName += NMChild( folder )
	endif
	
	tName += "_Table"
	
	tName = NMCheckStringName( tName )
	tName = tName[ 0, 29 ] // extra space for last seq number
	tName = UniqueName( tName, 7, 0 )
	
	waveOfWaveNames = NMStatsWaveNameForWNameFind( folder + wName )
	
	DoWindow /K $tName
	
	NMWinCascadeRect( w )
	
	if ( WaveExists( $waveOfWaveNames ) )
		Edit /HIDE=(hide)/K=(NMK())/N=$tName/W=(w.left,w.top,w.right,w.bottom) $waveOfWaveNames as title
		AppendToTable /W=$tName $folder + wName
		wList2 = AddListItem( waveOfWaveNames, wList2, ";", inf )
	else
		Edit /HIDE=(hide)/K=(NMK())/N=$tName/W=(w.left,w.top,w.right,w.bottom) $folder + wName as title
	endif
	
	wList2 = AddListItem( folder + wName, wList2, ";", inf )
	
	if ( numWaves > 1 )
	
		waveOfWaveNames = NMChild( waveOfWaveNames )
		
		wList = RemoveFromList( waveOfWaveNames, wList )
		
		for ( wcnt = 1 ; wcnt < numWaves ; wcnt += 1 )
			wName = StringFromList( wcnt, wList )
			AppendToTable /W=$tName $folder + wName
			wList2 = AddListItem( folder + wName, wList2, ";", inf )
		endfor
		
	endif
	
	SetNMstr( NMDF + "OutputWaveList", wList2 )
	SetNMstr( NMDF + "OutputWinList", tName )
	
	NMHistoryOutputWindows()
	
	return tName

End // NMStatsEdit

//****************************************************************
//****************************************************************

Function /S NMStatsHistogramCall( wName )
	String wName // wave name, ( "" ) for prompt
	
	String shortName, optionStr = ""
	String df = NMStatsDF
	
	STRUCT NMParams nm
	STRUCT NMHistrogramBins h
	
	Variable paddingBins = NMVarGet( "HistogramPaddingBins" )
	
	String wList = NMStats2WaveSelectList( 0 )
	String folder = CurrentNMStats2FolderSelect( 1 )
	String currentWaveSelect = CurrentNMStats2WaveSelect( 1 )
	
	Variable autoBins = 1 + NMStatsVarGet( "HistoBinAuto" )
	Variable binStart = NMStatsVarGet( "HistoBinStart" )
	Variable binWidth = NMStatsVarGet( "HistoBinWidth" )
	Variable numBins = NMStatsVarGet( "HistoNumBins" )
	Variable binCentered = 1 + NMStatsVarGet( "HistoBinCentered" )
	Variable cumulative = 1 + NMStatsVarGet( "HistoCumulative" )
	Variable normalize = 1 + NMStatsVarGet( "HistoNormalize" )
	
	if ( ( strlen( wName ) == 0 ) || !WaveExists( $wName ) )
		wName = currentWaveSelect
	endif
	
	if ( WaveExists( $wName ) )
		shortName = NMChild( wName )
	else
		shortName = " "
	endif

	Prompt autoBins, "bin dimensions:", popup "manual;automatic;"
	Prompt shortName, "select wave:", popup " ;" + wList
	DoPrompt "Stats Histogram", shortName, autoBins
	
	if ( ( V_flag == 1 ) || StringMatch( shortName, " " ) )
		return "" // cancel
	endif
	
	autoBins -= 1
	SetNMvar( df+"HistoBinAuto", autoBins )
	
	wName = NMParent( currentWaveSelect ) + shortName
	
	if ( !WaveExists( $wName ) )
		return ""
	endif
		
	if ( autoBins )
	
		NMParamsInit( NMParent( wName ), NMChild( wName ), nm )
		NMHistrogramBinsAuto( nm, h, all = 1, paddingBins = paddingBins, numBinsMin = 10 )
	
		numBins = h.numBins
		binWidth = h.binWidth
		binStart = h.binStart
		
	else
	
		if ( numtype( numBins * binWidth * binStart ) > 0 )
		
			NMParamsInit( NMParent( wName ), NMChild( wName ), nm )
			NMHistrogramBinsAuto( nm, h, all = 1, paddingBins = paddingBins, numBinsMin = 10 )
		
			numBins = h.numBins
			binWidth = h.binWidth
			binStart = h.binStart
		
		endif
		
		Prompt binStart, "bin start:"
		Prompt binWidth, "bin width:"
		Prompt numBins, "number of bins:"
		DoPrompt NMPromptStr( "Histograms" ), binStart, binWidth, numBins
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		SetNMvar( df+"HistoBinStart", binStart )
		SetNMvar( df+"HistoBinWidth", binWidth )
		SetNMvar( df+"HistoNumBins", numBins )

	endif
	
	Prompt binCentered, "bin-centered x values:", popup "no;yes;"
	Prompt cumulative, "cumulative histogram:", popup "no;yes;"
	Prompt normalize, "normalize results to probability density:", popup "no;yes;"
	DoPrompt NMPromptStr( "Histograms" ), binCentered, cumulative, normalize
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	binCentered -= 1
	cumulative -= 1
	normalize -= 1
	
	SetNMvar( df+"HistoBinCentered", binCentered )
	SetNMvar( df+"HistoCumulative", cumulative )
	SetNMvar( df+"HistoNormalize", normalize )
	
	if ( binCentered )
		optionStr += "/C"
	endif
	
	if ( cumulative )
		optionStr += "/Cum"
	endif
	
	if ( normalize )
		optionStr += "/P"
	endif
	
	folder = NMChild( folder )
	wName = NMChild( wName )
	
	return NMStatsHistogram( folder = folder, wName = wName, binStart = binStart, binWidth = binWidth, numBins = numBins, optionStr = optionStr, history = 1 )
	
End // NMStatsHistogramCall

//****************************************************************
//****************************************************************

Function /S NMStatsHistogram( [ folder, wName, binStart, binWidth, numBins, optionStr, noGraph, returnSelect, history ] )
	String folder // folder or subfolder, or nothing for current Stats subfolder
	String wName // wave name, or nothing for current Stats wave select
	Variable binStart // see Igor Histogram Help
	Variable binWidth // see Igor Histogram Help
	Variable numBins // see Igor Histogram Help
	String optionStr // e.g. "/C/P/Cum" ( see Igor Histogram Help )
	Variable noGraph // ( 0 ) display histogram in graph ( 1 ) no graph
	Variable returnSelect // ( 0 ) return histogram wave name ( 1 ) return graph name
	Variable history
	
	Variable normalize, cumulative
	String xLabel, yLabel, histoName, gName = "", gTitle, wNameShort
	String ostr, fxn, vlist = ""
	
	Variable paddingBins = NMVarGet( "HistogramPaddingBins" )
	
	STRUCT Rect w
	STRUCT NMParams nm
	STRUCT NMHistrogramBins h
	
	NMOutputListsReset()
	
	if ( ParamIsDefault( folder ) )
		folder = SELECTED
	else
		vlist = NMCmdStrOptional( "folder", folder, vlist )
	endif
	
	folder = CheckNMStatsFolderPath( folder )
	
	if ( !DataFolderExists( folder ) )
		return NM2ErrorStr( 30, "folder", folder )
	endif
	
	if ( ParamIsDefault( wName ) )
		wName = StrVarOrDefault( folder + "CurrentStats2Wave", "" )
	else
		vlist = NMCmdStrOptional( "wName", wName, vlist )
	endif
	
	if ( ( strlen( wName ) == 0 ) || StringMatch( wName, SELECTED ) )
		wName = StrVarOrDefault( folder + "CurrentStats2Wave", "" )
	endif
	
	if ( !WaveExists( $folder+wName ) || ( WaveType( $folder+wName ) == 0 ) )
		return NM2ErrorStr( 1, "wName", wName )
	endif
	
	Wavestats /Q/Z $folder+wName
	
	if ( V_npnts < 1 )
		Abort "Abort NMStatsHistogram: not enough data points: " + num2istr( V_npnts )
	endif
	
	if ( ParamIsDefault( binStart ) )
	
		binStart = NaN
	
	else
	
		vlist = NMCmdNumOptional( "binStart", binStart, vlist )
	
	endif
	
	if ( ParamIsDefault( binWidth ) )
	
		binWidth = NaN
		
	else
	
		if ( binWidth <= 0 )
			return NM2ErrorStr( 10, "binWidth", num2str( binWidth ) )
		endif
		
		vlist = NMCmdNumOptional( "binWidth", binWidth, vlist )
		
	endif
	
	if ( ParamIsDefault( numBins ) )
	
		numBins = NaN
		
	else
	
		if ( numBins <= 0 )
			return NM2ErrorStr( 10, "numBins", num2str( numBins ) )
		endif
	
		vlist = NMCmdNumOptional( "numBins", numBins, vlist, integer = 1 )
		
	endif
	
	if ( ParamIsDefault( optionStr ) || ( strlen( optionStr ) == 0 ) )
		optionStr = ""
	else
		vlist = NMCmdStrOptional( "optionStr", optionStr, vlist )
	endif
	
	if ( !ParamIsDefault( noGraph ) )
		vlist = NMCmdNumOptional( "noGraph", noGraph, vlist, integer = 1 )
	endif
	
	if ( !ParamIsDefault( returnSelect ) )
		vlist = NMCmdNumOptional( "returnSelect", returnSelect, vlist, integer = 1 )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	wNameShort = NMChild( wName )
	
	if ( numtype( binStart * binWidth * numBins ) == 0 )
	
		ostr = "/B={ " + num2str( binStart ) + ", " + num2str( binWidth ) + ", " + num2str( numBins ) + " } " + optionStr
		
	else
	
		NMParamsInit( NMParent( wName ), wNameShort, nm )
		NMHistrogramBinsAuto( nm, h, all = 1, paddingBins = paddingBins, numBinsMin = 10 )
	
		numBins = h.numBins
		binWidth = h.binWidth
		binStart = h.binStart
		
		ostr = "/B={ " + num2str( binStart ) + ", " + num2str( binWidth ) + ", " + num2str( numBins ) + " } " + optionStr
		
	endif
	
	if ( StringMatch( NMStatsStrGet( "WaveNamingFormat" ), "suffix" ) )
		histoName = wNameShort + "_Histo"
	else
		histoName = "Histo_" + wNameShort
	endif
	
	histoName = folder + histoName
	
	Make /O/N=1 $histoName
	
	xLabel = NMNoteLabel( "y", folder + wName, "" )
	
	if ( strsearch( optionStr, "/P", 0 ) >= 0 )
		yLabel = "Probability"
		normalize = 1
	else
		yLabel = "Count"
	endif
	
	if ( strsearch( optionStr, "/Cum", 0 ) >= 0 )
		cumulative = 1
	endif
	
	fxn = "Histogram " + ostr + " " + folder + wName + ", " + histoName
			
	Execute fxn
	
	NMNoteType( histoName, "NMStats Histo", xLabel, yLabel, "_FXN_" )
	Note $histoName, "Histo Input Wave:" + folder + wName
	Note $histoName, "Histo Bin Start:" + num2str( binStart )
	Note $histoName, "Histo Bin Width:" + num2str( binWidth )
	Note $histoName, "Histo Num Bins:" + num2str( numBins )
	Note $histoName, "Histo Options:" + ostr
	
	if ( cumulative )
			
		WaveStats /Q $folder + wName
	
		if ( ( V_min < leftx( $histoName ) ) || ( V_max < rightx( $histoName ) ) )
			NMDoAlert( "NMStatsHistogram Warning: cumulative histogram bin range did not include entire range of input data." )
		endif
	
	endif
	
	if ( !noGraph )
	
		gName = wNameShort + "_" + NMFolderPrefix( "" ) + "Histo"
		gName = NMCheckStringName( gName )
	
		if ( strlen( folder ) > 0 )
			gTitle = NMFolderListName( "" ) + " : " + NMChild( folder ) + " : " + histoName
		else
			gTitle = NMFolderListName( "" ) + " : " + histoName
		endif
		
		NMWinCascadeRect( w )
	
		DoWindow /K $gName
		Display /K=(NMK())/N=$gName/W=(w.left,w.top,w.right,w.bottom) $histoName as gTitle
		Label /W=$gName bottom xLabel
		Label /W=$gName left yLabel
		ModifyGraph /W=$gName standoff=0, rgb=(0,0,0), mode=5, hbFill=2
		
		SetNMstr( NMDF + "OutputWinList", gName )
	
	endif
	
	SetNMstr( NMDF + "OutputWaveList", histoName )
	
	NMHistoryOutputWaves()
	NMHistoryOutputWindows()
	
	if ( noGraph || ( returnSelect == 0 ) )
		return histoName
	else
		return gName
	endif
	
End // NMStatsHistogram

//****************************************************************
//****************************************************************

Static Function /S z_NMStatsInequalityCall()
	
	Variable icnt
	String wName, wNameShort, setNameSuccess, setNameFailure, setList = ""
 	
 	String wSelect, returnList, promptStr = "Stats Inequality <>"
	String wList = NMStats2WaveSelectList( 0 )
	String folder = CurrentNMStats2FolderSelect( 1 )
	
	Variable createSet = 1 + NMStatsVarGet( "RelationalOpCreateSet" )
 	
	wName = CurrentNMStats2WaveSelect( 1 )
	
	if ( !WaveExists( $wName ) )
		return ""
	endif
	
	wNameShort = NMChild( wName )
	wSelect = wNameShort
	
	STRUCT NMInequalityStruct s
	
	returnList = NMInequalityCall( s, NMStatsDF, promptStr = promptStr )
	
	if ( strlen( returnList ) == 0 )
		return "" // cancel
	endif
	
	Prompt createSet, "save inequality boolean results as Sets?", popup "no;yes, success Set and failure Set;yes, success Set;"
	Prompt wSelect, "select wave:", popup wList
	DoPrompt promptStr, wSelect, createSet
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	createSet -= 1
	
	SetNMvar( NMStatsDF + "RelationalOpCreateSet", createSet )
	
	if ( createSet == 1 )
	
		icnt = NMSetsNumNext()
		
		setNameSuccess = "Set" + num2istr( icnt )
		setNameFailure = "Set" + num2istr( icnt + 1 )
		
		Prompt setNameSuccess, "Set name for successes:"
		Prompt setNameFailure, "Set name for failures:"
		DoPrompt promptStr, setNameSuccess, setNameFailure
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		setList = setNameSuccess + ";" + setNameFailure + ";"
	
	elseif ( createSet == 2 )
	
		icnt = NMSetsNumNext()
		
		setNameSuccess = "Set" + num2istr( icnt )
		
		Prompt setNameSuccess, "success output Set name:"
		DoPrompt promptStr, setNameSuccess
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		setList = setNameSuccess
		
	endif
	
	folder = NMChild( folder )
	wSelect = NMChild( wSelect )
	
	return NMStatsInequality( folder = folder, wName = wSelect, greaterThan = s.greaterThan, lessThan = s.lessThan, binaryOutput = s.binaryOutput, setList = setList, history = 1 )
	
End // z_NMStatsInequalityCall

//****************************************************************
//****************************************************************

Function /S NMStatsInequality( [ folder, wName, greaterThan, lessThan, binaryOutput, setName, setList, noGraph, returnSelect, history, deprecation ] )
	String folder // folder or subfolder, or nothing for current Stats subfolder 
	String wName // wave name, or nothing for current Stats wave select
	Variable greaterThan // y > value
	Variable lessThan // y < value
	Variable binaryOutput // ( 0 ) output wave will contain NaN for false or corresponding input wave value for true ( 1 ) output wave will contain '0' for false or '1' for true
	String setName // optional output Set name (for success), ( "" ) for none
	String setList // optional output Set names (first set for success, second set for failure), ( "" ) for none
	Variable noGraph // ( 0 ) display results in a graph ( 1 ) no graph
	Variable returnSelect // ( 0 ) results wave name ( 1 ) graph name
	Variable history, deprecation
	
	Variable successes, failures, chan, icnt, createSets
	String chanStr, gName = "", gTitle, wavePrefix, wNameShort, currentPrefix, df = NMStatsDF
	String fxn, dName, setNameSuccess = "", setNameFailure = "", waveOfWaveNames = "", vlist = ""
	String thisfxn = GetRTStackInfo( 1 )
	
	STRUCT Rect w
	
	String prefixOrSuffix = NMStatsStrGet( "RelationalPrefixOrSuffix" )
	
	NMOutputListsReset()
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = SELECTED
	else
		vlist = NMCmdStrOptional( "folder", folder, vlist )
	endif
	
	folder = CheckNMStatsFolderPath( folder )
	
	if ( !DataFolderExists( folder ) )
		return NM2ErrorStr( 30, "folder", folder )
	endif
	
	if ( ParamIsDefault( wName ) )
		wName = StrVarOrDefault( folder + "CurrentStats2Wave", "" )
	else
		vlist = NMCmdStrOptional( "wName", wName, vlist )
	endif
	
	if ( ( strlen( wName ) == 0 ) || StringMatch( wName, SELECTED ) )
		wName = StrVarOrDefault( folder + "CurrentStats2Wave", "" )
	endif
	
	if ( !WaveExists( $folder+wName ) || ( WaveType( $folder+wName ) == 0 ) )
		return NM2ErrorStr( 1, "wName", wName )
	endif
	
	if ( ParamIsDefault( greaterThan ) )
		greaterThan = NaN
	else
		vlist = NMCmdNumOptional( "greaterThan", greaterThan, vlist )
	endif
	
	if ( ParamIsDefault( lessThan ) )
		lessThan = NaN
	else
		vlist = NMCmdNumOptional( "lessThan", lessThan, vlist )
	endif
	
	if ( ParamIsDefault( binaryOutput ) )
		binaryOutput = 1
	else
		vlist = NMCmdNumOptional( "binaryOutput", binaryOutput, vlist )
	endif
	
	if ( !ParamIsDefault( setName ) && ( ItemsInList( setName ) > 0 ) )
		createSets = 1
		vlist = NMCmdStrOptional( "setName", setName, vlist )
	endif
	
	if ( !ParamIsDefault( setList ) && ( ItemsInList( setList ) > 0 ) )
		createSets = 1
		vlist = NMCmdStrOptional( "setList", setList, vlist )
		setName = ""
	endif
	
	if ( !ParamIsDefault( noGraph ) )
		vlist = NMCmdNumOptional( "noGraph", noGraph, vlist, integer = 1 )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( ( numtype( greaterThan ) > 0 ) && ( numtype( lessThan ) > 0 ) )
		return "" // nothing to do
	endif
	
	if ( createSets )
	
		waveOfWaveNames = NMStatsWaveNameForWNameFind( folder + wName )
		waveOfWaveNames = NMChild( waveOfWaveNames )
		
		if ( strlen( waveOfWaveNames ) == 0 )
			NMDoAlert( thisfxn + " Abort: could not locate corresponding Stat wave " + NMQuotes( "ST_wName..." ) + " for wave " + NMQuotes( wName ) )
			return ""
		endif
		
		if ( !WaveExists( $folder + waveOfWaveNames ) || ( WaveType( $folder + waveOfWaveNames ) != 0 ) )
			return NM2ErrorStr( 1, "waveOfWaveNames", waveOfWaveNames )
		endif
	
	endif
	
	wNameShort = NMChild( wName )
	
	if ( StringMatch( NMStatsStrGet( "WaveNamingFormat" ), "suffix" ) )
		dName = wNameShort + "_" + prefixOrSuffix
	else
		dName = prefixOrSuffix + "_" + wNameShort
	endif
	
	Duplicate /O $( folder + wName ) $( folder + dName )
	
	Wave wtemp = $folder + wName
	Wave dtemp = $folder + dName
	
	dtemp = NMInequality( wtemp, greaterThan = greaterThan, lessThan = lessThan, binaryOutput = binaryOutput )
	
	fxn = NMInequalityFxn( greaterThan, lessThan )
	
	if ( binaryOutput )
	
		NMNoteStrReplace( folder + dName, "yLabel", "True/False" )
		
		for ( icnt = 0 ; icnt < numpnts( dtemp ) ; icnt += 1 )
		
			if ( dtemp[ icnt ] == 1 )
				successes += 1
			else
				failures += 1
			endif
		
		endfor
		
	else
	
		WaveStats /Q dtemp
		
		for ( icnt = 0 ; icnt < numpnts( dtemp ) ; icnt += 1 )
		
			if ( numtype( dtemp[ icnt ] ) != 2 )
				successes += 1
			else
				failures += 1
			endif
		
		endfor
		
	endif
		
	Note dtemp, thisFxn + "(" + fxn + ")"
	
	chanStr = NMNoteStrByKey( folder + wName, "ChanSelect" )
	
	chan = ChanChar2Num( chanStr )
	
	if ( numtype( chan ) > 0 )
		chan = ChanNumGet( wName )
	endif
	
	if ( ( chan < 0 ) || ( chan >= NMNumChannels() ) )
		chan = NaN
	endif
	
	if ( createSets && ( numtype( chan ) == 0 ) && WaveExists( $folder + waveOfWaveNames ) )
		
		wavePrefix = NMNoteStrByKey( folder + wName, "WPrefix" )
		currentPrefix = CurrentNMWavePrefix()
		
		if ( ( strlen( wavePrefix ) > 0 ) && !StringMatch( wavePrefix, currentPrefix ) )
			
			DoAlert 0, thisfxn + " Error: the current wave prefix ( " + currentPrefix + " ) does not match that of your Stats wave ( " + wavePrefix + " )"
			
		else
		
			if ( ItemsInList( setList ) > 0 )
			
				setNameSuccess = StringFromList( 0, setList )
				
				if ( ItemsInList( setList ) > 1 )
					setNameFailure = StringFromList( 1, setList )
				endif
			
			elseif ( strlen( setName ) > 0 )
				setNameSuccess = setName
			else
				return ""
			endif
			
			if ( AreNMSets( setNameSuccess ) )
				NMSetsClear( setNameSuccess )
			else
				NMSetsNew( setNameSuccess )
			endif
			
			if ( strlen( setNameFailure ) > 0 )
				if ( AreNMSets( setNameFailure ) )
					NMSetsClear( setNameFailure )
				else
					NMSetsNew( setNameFailure )
				endif
			endif
		
			Wave /T wowNames = $folder + waveOfWaveNames
			Wave dtemp = $folder + dName
			
			for ( icnt = 0 ; icnt < numpnts( dtemp ) ; icnt += 1 )
				if ( binaryOutput )
					if ( dtemp[ icnt ] == 1 )
						NMSetsAssign2( setNameSuccess, wowNames[ icnt ], 1 )
					elseif ( strlen( setNameFailure ) > 0 )
						NMSetsAssign2( setNameFailure, wowNames[ icnt ], 1 )
					endif
				else
					if ( numtype( dtemp[ icnt ] ) != 2 )
						NMSetsAssign2( setNameSuccess, wowNames[ icnt ], 1 )
					elseif ( strlen( setNameFailure ) > 0 )
						NMSetsAssign2( setNameFailure, wowNames[ icnt ], 1 )
					endif
				endif
				
			endfor
			
		endif
		
	endif
	
	if ( !noGraph )
	
		gName = wNameShort + "_" + NMFolderPrefix( "" ) + prefixOrSuffix
		gName = NMCheckStringName( gName )
	
		if ( strlen( folder ) > 0 )
			gTitle = NMFolderListName( "" ) + " : " + NMChild( folder ) + " : " + wNameShort + " : " + fxn
		else
			gTitle = NMFolderListName( "" ) + " : " + wNameShort + " : " + fxn
		endif
		
		NMWinCascadeRect( w )
		
		DoWindow /K $gName
		Display /K=(NMK())/N=$gName/W=(w.left,w.top,w.right,w.bottom) $( folder + dName ) as gTitle
			
		ModifyGraph /W=$gName mode=3,marker=19,standoff=0
		Label /W=$gName bottom NMNoteLabel( "x", folder + dName, "Wave #" )
		
		if ( binaryOutput )
			Label /W=$gName left "True/False"
		else
			Label /W=$gName left NMNoteLabel( "y", folder + dName, "" )
		endif
		
		if ( binaryOutput )
			ModifyGraph /W=$gName manTick(left)={0,1,0,0},manMinor(left)={0,0}
		endif
		
		SetNMstr( NMDF + "OutputWinList", gName )
	
	endif
	
	NMHistory( fxn + "; successes = " + num2istr( successes ) + "; failures = " + num2istr( failures ) )
	
	SetNMstr( NMDF + "OutputWaveList", folder + dName )
	
	NMHistoryOutputWaves()
	NMHistoryOutputWindows()
	
	if ( noGraph || ( returnSelect == 0 ) )
		return folder + dName
	elseif ( returnSelect )
		return gName
	endif

End // NMStatsInequality

//****************************************************************
//****************************************************************

Function /S NMStats2StabilityCall()

	Variable dumVar = 0
	
	String folder = CurrentNMStats2FolderSelect( 1 )
	String wList = NMStats2WaveSelectList( 0 )
	String wName = CurrentNMStats2WaveSelect( 0 )
	String wSelect = wName
	
	Variable doWavePrompt = 0
	
	if ( doWavePrompt && ItemsInList( wList ) > 1 )
	
		Prompt wSelect, "select wave:", popup wList
		DoPrompt "Stats Stability", wSelect
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
	
	endif
	
	wSelect = folder + wSelect
	
	Execute "NMStabilityStats( " + NMQuotes( wSelect ) + "," + num2str( dumVar ) + " )"
	
	return ""
	
End // NMStats2StabilityCall

//****************************************************************
//****************************************************************

Function /S NMStats2SigDiffCall()

	Variable error

	String folder = CurrentNMStats2FolderSelect( 1 )
	String fSelect = " "
	String folderList = NMStats2FolderList( 0 )
	
	String waveName1 = CurrentNMStats2WaveSelect( 1 )
	String wSelect1 = NMChild( waveName1 )
	String wList1 = NMStats2WaveSelectList( 0 )
	
	String waveName2 = " "
	String wSelect2 = waveName2
	String wList2 = NMFolderWaveList( folder, "*", ";", "TEXT:0", 0 )
	
	Variable dsply = 1 + NMStatsVarGet( "KSdsply" )
	
	folderList = RemoveFromList( NMChild( folder ), folderList )
	
	Prompt wSelect1, "select first data wave:", popup wList1
	Prompt wSelect2, "select second data wave for comparison:", popup " ;" + wList2
	Prompt fSelect, "or select a folder to locate second data wave:", popup " ;" + folderList
	Prompt dsply,"display cumulative distributions?",popup,"no;yes"
	
	DoPrompt "Kolmogorov-Smirnov Test For Significant Difference", wSelect1, wSelect2, fSelect, dsply
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	dsply -= 1
	
	SetNMvar( NMStatsDF + "KSdsply", dsply )
	
	if ( !WaveExists( $folder+wSelect1 ) )
		return "" // something went wrong
	endif
	
	if ( StringMatch( folder, GetDataFolder( 1 ) ) )
		folder = ""
	endif
	
	if ( strlen( folder ) > 0 )
		wSelect1 = folder + wSelect1
	endif
	
	if ( ( strlen( folder ) > 0 ) && !StringMatch( wSelect2, " " ) )
		wSelect2 = folder + wSelect2
	endif
	
	if ( !StringMatch( fSelect, " " ) )
	
		fSelect = CheckNMStatsFolderPath( fSelect )
	
		wList2 = NMFolderWaveList( fSelect, "*", ";", "TEXT:0", 0 )
		waveName2 = " "
		
		Prompt wSelect2, "select second data wave for comparison:", popup " ;" + wList2
		DoPrompt "Kolmogorov-Smirnov Test For Significant Difference", wSelect2
		
		if ( ( V_flag == 1 ) || ( StringMatch( wSelect2, " " ) ) )
			return "" // cancel
		endif
		
		if ( StringMatch( fSelect, GetDataFolder( 1 ) ) )
			fSelect = ""
		endif
		
		if ( strlen( fSelect ) > 0 )
			wSelect2 = fSelect + wSelect2
		endif

	endif
	
	if ( StringMatch( wSelect2, " " ) )
		return "" // something went wrong
	endif
	
	error = NMKSTest( wName1 = wSelect1, wName2 = wSelect2, noGraph = BinaryInvert( dsply ), history = 1 )
	
	return num2str( error )
	
End // NMStats2SigDiffCall

//****************************************************************
//****************************************************************

Static Function /S z_NMStatsWaveScaleCall()

	Variable icnt
	String wtype, wName2, wList2 = "", chanList2
	
	String folder = CurrentNMStats2FolderSelect( 1 )
	String wList = NMStats2WaveSelectList( 1 )
	String wName = CurrentNMStats2WaveSelect( 1 )
	String wSelect
	String chanSelect = NMChanSelectStr()
	String chanList = NMChanList( "CHAR" )
	
	for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
	
		wName2 = StringFromList( icnt, wList )
		wtype = NMStatsWaveTypeXY( wName2 )
		
		if ( !StringMatch( wtype, "X" ) )
			wList2 += NMChild( wName2 ) + ";"
		endif
		
	endfor
	
	if ( ItemsInList( wList2 ) == 0 )
		NMDoAlert( "NMStatsWaveScaleCall Abort: there are no Stats X-value waves in the currently selected Stats2 folder " + folder )
		return ""
	endif
	
	wtype = NMStatsWaveTypeXY( wName )
	
	if ( !StringMatch( wtype, "X" ) )
		wSelect = NMChild( wName )
	else
		wSelect = " "
	endif
	
	if ( ItemsInList( chanList ) > 0 )
		chanList2 = "All;" + chanList
	else
		chanList2 = chanList
	endif
	
	String alg = NMStatsStrGet( "WaveScaleAlg" )
	
	Prompt wSelect, "select wave of scale values:", popup " ;" + wList2
	Prompt alg, "scale function:", popup "x;/;+;-"
	Prompt chanSelect, "select channel(s) to apply wave scaling:", popup chanList2
	DoPrompt "Stats Wave Scaling", wSelect, alg, chanSelect
	
	if ( ( V_flag == 1 ) || StringMatch( wSelect, " " ) )
		return "" // cancel
	endif
	
	SetNMstr( NMStatsDF + "WaveScaleAlg", alg )
	
	folder = NMChild( folder )
	wSelect = NMChild( wSelect )
	
	return NMStatsWaveScale( folder = folder, waveOfScaleValues = wSelect, alg = alg, chanSelect = chanSelect, history = 1 )

End // z_NMStatsWaveScaleCall

//****************************************************************
//****************************************************************

Function /S NMStatsWaveScale( [ folder, waveOfScaleValues, waveOfWaveNames, alg, chanSelect, history ] )
	String folder // folder or subfolder, or nothing for current Stats subfolder
	String waveOfScaleValues // wave containing scale values, or nothing for current Stats wave select
	String waveOfWaveNames // text wave containing list of waves to align (e.g. "ST_wName_RAll_A0" ), or nothing for default Stats wave
	String alg // "x", "/", "+" or "-"
	String chanSelect // channel number character or "All"
	Variable history
	
	Variable icnt, waveNum, npnts1, npnts2
	String wName, saveChanSelect, outList = "", vlist = ""
	String wNameScale = NMStatsDF + "ST2_WaveScales"
	String thisfxn = GetRTStackInfo( 1 )
	
	Variable numWaves = NMNumWaves()
	
	if ( ParamIsDefault( folder ) )
		folder = SELECTED
	else
		vlist = NMCmdStrOptional( "folder", folder, vlist )
	endif
	
	folder = CheckNMStatsFolderPath( folder )
	
	if ( !DataFolderExists( folder ) )
		return NM2ErrorStr( 30, "folder", folder )
	endif
	
	if ( ParamIsDefault( waveOfScaleValues ) )
		waveOfScaleValues = StrVarOrDefault( folder + "CurrentStats2Wave", "" )
	else
		vlist = NMCmdStrOptional( "waveOfScaleValues", waveOfScaleValues, vlist )
	endif
	
	if ( ( strlen( waveOfScaleValues ) == 0 ) || StringMatch( waveOfScaleValues, SELECTED ) )
		wName = StrVarOrDefault( folder + "CurrentStats2Wave", "" )
	endif
	
	if ( !WaveExists( $folder+waveOfScaleValues ) || ( WaveType( $folder+waveOfScaleValues ) == 0 ) )
		return NM2ErrorStr( 1, "waveOfScaleValues", waveOfScaleValues )
	endif
	
	if ( ParamIsDefault( waveOfWaveNames ) )
		waveOfWaveNames = SELECTED
	else
		vlist = NMCmdStrOptional( "waveOfWaveNames", waveOfWaveNames, vlist )
	endif
	
	if ( ( strlen( waveOfWaveNames ) == 0 ) || StringMatch( waveOfWaveNames, SELECTED ) )
	
		waveOfWaveNames = NMStatsWaveNameForWNameFind( folder + waveOfScaleValues )
		waveOfWaveNames = NMChild( waveOfWaveNames )
		
		if ( strlen( waveOfWaveNames ) == 0 )
			NMDoAlert( thisfxn + " Abort: could not locate corresponding Stat wave " + NMQuotes( "ST_wName..." ) + " for wave " + NMQuotes( waveOfScaleValues ) )
			return ""
		endif
		
	endif
	
	if ( !WaveExists( $folder+waveOfWaveNames ) || ( WaveType( $folder+waveOfWaveNames ) != 0 ) )
		return NM2ErrorStr( 1, "waveOfWaveNames", waveOfWaveNames )
	endif
	
	npnts1 = numpnts( $folder+waveOfWaveNames )
	npnts2 = numpnts( $folder+waveOfScaleValues )
	
	if ( npnts1 != npnts2 )
		NMDoAlert( thisfxn + " Error: input waves have different length: " + num2istr( npnts1 ) + " and " + num2istr( npnts2 ) )
		return ""
	endif
	
	if ( ParamIsDefault( alg ) )
		alg = "error" // user should specify
	else
		vlist = NMCmdStrOptional( "alg", alg, vlist )
	endif
	
	if ( strsearch( "x*/+-", alg, 0 ) == -1 )
		return NM2ErrorStr( 20, "alg", alg )
	endif
	
	if ( ParamIsDefault( chanSelect ) )
		chanSelect = NMNoteStrByKey( folder + waveOfScaleValues, "ChanSelect" )
	else
		vlist = NMCmdStrOptional( "chanSelect", chanSelect, vlist )
	endif
	
	if ( WhichListItem( chanSelect, "All;" + NMChanList( "CHAR" ) ) < 0 )
		return NM2ErrorStr( 20, "chanSelect", chanSelect )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	Make /O/N=( numWaves ) $wNameScale = Inf // create wave of appropriate length for function NMScaleByWave, set default to "inf" since this will be ignored by NMScaleByWave
	
	Wave /T wNames = $folder + waveOfWaveNames
	Wave scaleValues = $folder + waveOfScaleValues
	Wave newScaleValues = $wNameScale
	
	for ( icnt = 0 ; icnt < numpnts( wNames ) ; icnt += 1 )
		
		wName = wNames[ icnt ]
		
		waveNum = NMChanWaveNum( wName )
		
		if ( waveNum < 0 )
			NMDoAlert( thisfxn + " Error: could not locate wave number for wave " + NMQuotes( wName ) + "." )
			KillWaves /Z $wNameScale
			return ""
		endif
		
		newScaleValues[ waveNum ] = scaleValues[ icnt ]
	
	endfor
	
	saveChanSelect = NMChanSelectStr()
	
	if ( !StringMatch( saveChanSelect, chanSelect ) )
		NMChanSelect( chanSelect )
	else
		saveChanSelect = ""
	endif
	
	outList = NMMainScale( op = alg, waveOfFactors = wNameScale )
	
	if ( strlen( saveChanSelect ) > 0 )
		NMChanSelect( saveChanSelect )
	endif
	
	KillWaves /Z $wNameScale
	
	NMStatsAuto( force = 1 )
	
	return outList
	
End // NMStatsWaveScale

//****************************************************************
//****************************************************************

Static Function /S z_NMStatsWaveAlignmentCall()

	Variable icnt, alignAt
	String wtype, wName2, wList2 = "", chanList2
	
	String folder = CurrentNMStats2FolderSelect( 1 )
	String wList = NMStats2WaveSelectList( 1 )
	String wName = CurrentNMStats2WaveSelect( 1 )
	String wSelect
	String chanSelect = NMChanSelectStr()
	String chanList = NMChanList( "CHAR" )
	
	for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
	
		wName2 = StringFromList( icnt, wList )
		wtype = NMStatsWaveTypeXY( wName2 )
		
		if ( StringMatch( wtype, "X" ) )
			wList2 += NMChild( wName2 ) + ";"
		endif
		
	endfor
	
	if ( ItemsInList( wList2 ) == 0 )
		NMDoAlert( "NMStatsWaveAlignmentCall Abort: there are no Stats X-value waves in the currently selected Stats2 folder " + folder )
		return ""
	endif
	
	wtype = NMStatsWaveTypeXY( wName )
	
	if ( StringMatch( wtype, "X" ) )
		wSelect = NMChild( wName )
	else
		wSelect = " "
	endif
	
	if ( ItemsInList( chanList ) > 0 )
		chanList2 = "All;" + chanList
	else
		chanList2 = chanList
	endif
	
	String select = StrVarOrDefault( NMStatsDF + "AlignAtSelect", "zero" )
	
	Prompt wSelect, "select wave of alignment values:", popup " ;" + wList2
	Prompt select, "align at:", popup NMAlignAtList
	Prompt chanSelect, "select channel to apply wave alignment:", popup chanList2
	DoPrompt "Stats Wave Alignment", wSelect, select, chanSelect
	
	if ( ( V_flag == 1 ) || StringMatch( wSelect, " " ) )
		return "" // cancel
	endif
	
	SetNMstr( NMStatsDF + "AlignAtSelect", select )
	
	folder = NMChild( folder )
	wSelect = NMChild( wSelect )
	
	alignAt = NMAlignAtValue( select, wSelect )
	
	return NMStatsWaveAlignment( folder = folder, waveOfAlignments = wSelect, alignAt = alignAt, chanSelect = chanSelect, history = 1 )

End // z_NMStatsWaveAlignmentCall

//****************************************************************
//****************************************************************

Function /S NMStatsWaveAlignment( [ folder, waveOfAlignments, waveOfWaveNames, alignAt, chanSelect, history ] )
	String folder // folder or subfolder, or nothing for current Stats subfolder
	String waveOfAlignments // wave containing x-axis alignment values, or nothing for current Stats wave select
	String waveOfWaveNames // text wave containing list of waves to align (e.g. "ST_wName_RAll_A0" ), or nothing for default Stats wave
	Variable alignAt // where on x-axis to align waves
	String chanSelect // channel number character or "All"
	Variable history
	
	Variable icnt, waveNum, npnts1, npnts2
	String wName, saveChanSelect, outList, vlist = ""
	String waveOfAlignValues = NMStatsDF + "ST2_WaveAlignments"
	String thisfxn = GetRTStackInfo( 1 )
	
	Variable numWaves = NMNumWaves()
	
	if ( ParamIsDefault( folder ) )
		folder = SELECTED
	else
		vlist = NMCmdStrOptional( "folder", folder, vlist )
	endif
	
	folder = CheckNMStatsFolderPath( folder )
	
	if ( !DataFolderExists( folder ) )
		return NM2ErrorStr( 30, "folder", folder )
	endif
	
	if ( ParamIsDefault( waveOfAlignments ) )
		waveOfAlignments = StrVarOrDefault( folder + "CurrentStats2Wave", "" )
	else
		vlist = NMCmdStrOptional( "waveOfAlignments", waveOfAlignments, vlist )
	endif
	
	if ( ( strlen( waveOfAlignments ) == 0 ) || StringMatch( waveOfAlignments, SELECTED ) )
		wName = StrVarOrDefault( folder + "CurrentStats2Wave", "" )
	endif
	
	if ( !WaveExists( $folder+waveOfAlignments ) || ( WaveType( $folder+waveOfAlignments ) == 0 ) )
		return NM2ErrorStr( 1, "waveOfAlignments", waveOfAlignments )
	endif
	
	if ( ParamIsDefault( waveOfWaveNames ) )
		waveOfWaveNames = SELECTED
	else
		vlist = NMCmdStrOptional( "waveOfWaveNames", waveOfWaveNames, vlist )
	endif
	
	if ( ( strlen( waveOfWaveNames ) == 0 ) || StringMatch( waveOfWaveNames, SELECTED ) )
	
		waveOfWaveNames = NMStatsWaveNameForWNameFind( folder + waveOfAlignments )
		waveOfWaveNames = NMChild( waveOfWaveNames )
		
		if ( strlen( waveOfWaveNames ) == 0 )
			NMDoAlert( thisfxn + " Abort: could not locate corresponding Stat wave " + NMQuotes( "ST_wName..." ) + " for wave " + NMQuotes( waveOfAlignments ) )
			return ""
		endif
		
	endif
	
	if ( !WaveExists( $folder+waveOfWaveNames ) || ( WaveType( $folder+waveOfWaveNames ) != 0 ) )
		return NM2ErrorStr( 1, "waveOfWaveNames", waveOfWaveNames )
	endif
	
	npnts1 = numpnts( $folder+waveOfWaveNames )
	npnts2 = numpnts( $folder+waveOfAlignments )
	
	if ( npnts1 != npnts2 )
		NMDoAlert( thisfxn + " Error: input waves have different length: " + num2istr( npnts1 ) + " and " + num2istr( npnts2 ) )
		return ""
	endif
	
	if ( numtype( alignAt ) > 0 )
		return NM2ErrorStr( 10, "alignAt", num2str( alignAt ) )
	endif
	
	if ( !ParamIsDefault( alignAt ) )
		vlist = NMCmdNumOptional( "alignAt", alignAt, vlist )
	endif
	
	if ( ParamIsDefault( chanSelect ) )
		chanSelect = NMNoteStrByKey( folder + waveOfAlignments, "ChanSelect" )
	else
		vlist = NMCmdStrOptional( "chanSelect", chanSelect, vlist )
	endif
	
	if ( WhichListItem( chanSelect, "All;" + NMChanList( "CHAR" ) ) < 0 )
		return NM2ErrorStr( 20, "chanSelect", chanSelect )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	Make /O/N=( numWaves ) $waveOfAlignValues = Nan // create wave of appropriate length for function NMAlignWaves
	
	Wave /T wNames = $folder+waveOfWaveNames
	Wave alignments = $folder+waveOfAlignments
	Wave newAlignments = $waveOfAlignValues
	
	for ( icnt = 0 ; icnt < numpnts( wNames ) ; icnt += 1 )
		
		wName = wNames[ icnt ]
		
		waveNum = NMChanWaveNum( wName )
		
		if ( waveNum < 0 )
			NMDoAlert( thisfxn + " Error: could not locate wave number for wave " + NMQuotes( wName ) + "." )
			KillWaves /Z $waveOfAlignValues
			return ""
		endif
		
		newAlignments[ waveNum ] = alignments[ icnt ]
	
	endfor
	
	saveChanSelect = NMChanSelectStr()
	
	if ( !StringMatch( saveChanSelect, chanSelect ) )
		NMChanSelect( chanSelect )
	else
		saveChanSelect = ""
	endif
	
	outList = NMMainAlign( waveOfAlignValues = waveOfAlignValues, alignAt = alignAt )
	
	if ( strlen( saveChanSelect ) > 0 )
		NMChanSelect( saveChanSelect )
	endif
	
	KillWaves /Z $waveOfAlignValues
	
	NMStatsAuto( force = 1 )
	
	return outList
	
End // NMStatsWaveAlignment

//****************************************************************
//****************************************************************

Static Function /S z_NMStatsSubfolderKillCall()
	
	String subfolder = CurrentNMStats2FolderSelect( 0 )
	
	if ( StringMatch( subfolder, GetDataFolder( 0 ) ) ==1 )
		return "" // not allowed
	endif
	
	DoAlert 1, "Are you sure you want to delete subfolder " + NMQuotes( subfolder ) + "?"
	
	if ( V_flag != 1 )
		return "" // cancel
	endif
	
	return NMStatsSubfolderKill( subfolder = SELECTED, history = 1 )
	
End // z_NMStatsSubfolderKillCall

//****************************************************************
//****************************************************************

Function /S NMStatsSubfolderKill( [ subfolder, history ] )
	String subfolder // data folder, or nothing for current data folder, or "_selected_" for currently selected Stats2 folder
	Variable history
	
	String vlist = ""
	String thisfxn = GetRTStackInfo( 1 )
	
	if ( ParamIsDefault( subfolder ) )
		subfolder = SELECTED
	else
		vlist = NMCmdStrOptional( "subfolder", subfolder, vlist )
	endif
	
	subfolder = CheckNMStatsFolderPath( subfolder )
	
	if ( !DataFolderExists( subfolder ) )
		return NM2ErrorStr( 30, "subfolder", subfolder )
	endif
	
	if ( StringMatch( subfolder, GetDataFolder( 1 ) ) ==1 )
		NMDoAlert( thisfxn + " Abort: cannot close the current data folder." )
		return "" // not allowed
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	Variable error = NMSubfolderKill( subfolder )
	
	UpdateStats2()
	
	if ( error == 0 )
		return subfolder
	else
		return ""
	endif

End // NMStatsSubfolderKill

//****************************************************************
//****************************************************************

Static Function /S z_NMStatsSubfolderClearCall()
	
	String subfolder = CurrentNMStats2FolderSelect( 0 )
	
	if ( StringMatch( subfolder, GetDataFolder( 0 ) ) ==1 )
		return "" // not allowed
	endif
	
	DoAlert 1, "Are you sure you want to kill all waves inside subfolder " + NMQuotes( subfolder ) + "?"
	
	if ( V_flag != 1 )
		return "" // cancel
	endif
	
	return NMStatsSubfolderClear( subfolder = SELECTED, history = 1 )
	
End // z_NMStatsSubfolderClearCall

//****************************************************************
//****************************************************************

Function /S NMStatsSubfolderClear( [ subfolder, history ] )
	String subfolder // data folder, or nothing for current data folder, or "_selected_" for currently selected Stats folder
	Variable history
	
	String vlist = ""
	String thisfxn = GetRTStackInfo( 1 )
	
	if ( ParamIsDefault( subfolder ) )
		subfolder = SELECTED
	else
		vlist = NMCmdStrOptional( "subfolder", subfolder, vlist )
	endif
	
	subfolder = CheckNMStatsFolderPath( subfolder )
	
	if ( !DataFolderExists( subfolder ) )
		return NM2ErrorStr( 30, "subfolder", subfolder )
	endif
	
	if ( StringMatch( subfolder, GetDataFolder( 1 ) ) ==1 )
		NMDoAlert( thisfxn + " Abort: cannot clear the current data folder." )
		return "" // not allowed
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	String failureList = NMSubfolderClear( subfolder )
	
	if ( ItemsInList( failureList ) > 0 )
		NMDoAlert( thisfxn + " Alert: failed to kill the following waves: " + failureList )
	endif
	
	UpdateStats2()
	
	return failureList

End // NMStatsSubfolderClear

//****************************************************************
//****************************************************************

Static Function /S z_NMStatsWaveStatsCall()

	String folder = CurrentNMStats2FolderSelect( 0 )
	
	Variable outputSelect = 1 + NumVarOrDefault( NMStatsDF + "WaveStatsOutputSelect", 2 )
	
	Prompt outputSelect, "save results to:" popup "Igor history;notebook;table;"
	DoPrompt "Wave Stats", outputSelect
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	outputSelect -= 1
	
	SetNMvar( NMStatsDF + "WaveStatsOutputSelect", outputSelect )
	
	return NMStatsWaveStats( folder = folder, outputSelect = outputSelect, history = 1 )

End // z_NMStatsWaveStatsCall

//****************************************************************
//****************************************************************

Function /S NMStatsWaveStats( [ folder, wList, outputSelect, hide, history ] ) // compute AVG, SDV, SEM, etc
	String folder // folder or subfolder, or nothing for current Stats subfolder
	String wList // wave list, or nothing for current Stats wave selection
	Variable outputSelect // ( 0 ) Igor history, default ( 1 ) notebook ( 2 ) table ( 3 ) Stats2 global variables
	Variable hide
	Variable history

	String wName, folderShort, windowName, windowTitle, returnStr, vlist = ""
	
	NMOutputListsReset()
	
	if ( ParamIsDefault( folder ) )
		folder = SELECTED
	else
		vlist = NMCmdStrOptional( "folder", folder, vlist )
	endif
	
	folder = CheckNMStatsFolderPath( folder )
	
	if ( !DataFolderExists( folder ) )
		return NM2ErrorStr( 30, "folder", folder )
	endif
	
	if ( ParamIsDefault( wList ) )
		wList = NMStats2WaveSelectList( 0, folder = folder )
	else
		vlist = NMCmdStrOptional( "wList", wList, vlist )
	endif
	
	if ( ( strlen( wList ) == 0 ) || StringMatch( wList, SELECTED ) )
		wList = NMStats2WaveSelectList( 0, folder = folder )
	endif
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	if ( ParamIsDefault( outputSelect ) )
		outputSelect = 0
	else
		vlist = NMCmdNumOptional( "outputSelect", outputSelect, vlist, integer = 1 )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( outputSelect == 3 ) // Stats2 global variables
	
		STRUCT NMStatsParamStruct sp
		NMStatsParamRef( sp )
	
		wName = StringFromList( 0, wList )
		
		sp.count = NaN
		sp.avg = NaN
		sp.stdv = NaN
		sp.sem = NaN
		sp.min = NaN
		sp.max = NaN
		
		if ( !WaveExists( $folder+wName ) )
			return ""
		endif
	
		WaveStats /Q/Z $folder+wName
		
		if ( V_npnts > 0 )
			sp.count = V_npnts
			sp.avg = V_avg
			sp.stdv = V_sdev
			sp.sem = V_sem
			sp.min = V_min
			sp.max = V_max
		endif
		
		return folder + wName
	
	endif
	
	if ( outputSelect == 0 ) // Igor history
		return NMWaveStats( folder = folder, wList = wList, outputSelect = 1 )
	endif
	
	folderShort = NMChild( folder )
	
	windowName = "ST2_" + NMFolderPrefix( "" ) + ReplaceString( "Stats_", folderShort, "" )
	windowName = ReplaceString( "Stats", windowName, "ST" )
	
	windowTitle = NMFolderListName( "" ) + " : Stats2 : " + folderShort
	
	if ( outputSelect == 1 ) // notebook
	
		returnStr = NMWaveStats( folder = folder, wList = wList, outputSelect = 2, windowName = windowName + "_NB", windowTitle = windowTitle )
		
		NMHistoryOutputWindows()
		
		return returnStr
		
	endif
	
	if ( outputSelect == 2 ) // table
	
		returnStr = NMWaveStats( folder = folder, wList = wList, outputSelect = 3, outputPrefix = "ST2_", windowName = windowName, windowTitle = windowTitle )
		
		NMHistoryOutputWaves( subfolder = folder )
		NMHistoryOutputWindows()
		
		return returnStr
		
	endif
	
	return ""

End // NMStatsWaveStats

//****************************************************************
//****************************************************************

Static Function /S z_NMStatsWaveNotesCall()

	String folder = CurrentNMStats2FolderSelect( 0 )

	Variable toNotebook = 1 + NumVarOrDefault( NMStatsDF + "WaveNotes2Notebook", 0 )
	
	Prompt toNotebook, "print wave notes to:", popup "Igor history;notebook;"
	DoPrompt "Print Wave Notes", toNotebook
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	toNotebook -= 1
	
	SetNMvar( NMStatsDF + "WaveNotes2Notebook", toNotebook )
	
	return NMStatsWaveNotes( folder = folder, toNotebook = toNotebook, history = 1 )

End // z_NMStatsWaveNotesCall

//****************************************************************
//****************************************************************

Function /S NMStatsWaveNotes( [ folder, wList, toNotebook, history ] )
	String folder // folder or subfolder, or nothing for current Stats subfolder
	String wList // wave list, or nothing for current Stats wave selection
	Variable toNotebook // ( 0 ) no, print to history ( 1 ) print to notebook
	Variable history
	
	String folderShort, nbPrefix, nbName, nbTitle, returnStr, vlist = ""
	
	STRUCT NMParams nm
	
	NMOutputListsReset()
	
	if ( ParamIsDefault( folder ) )
		folder = SELECTED
	else
		vlist = NMCmdStrOptional( "folder", folder, vlist )
	endif
	
	folder = CheckNMStatsFolderPath( folder )
	
	if ( !DataFolderExists( folder ) )
		return NM2ErrorStr( 30, "folder", folder )
	endif
	
	if ( ParamIsDefault( wList ) )
		wList = NMStats2WaveSelectList( 0, folder = folder )
	else
		vlist = NMCmdStrOptional( "wList", wList, vlist )
	endif
	
	if ( ( strlen( wList ) == 0 ) || StringMatch( wList, SELECTED ) )
		wList = NMStats2WaveSelectList( 0, folder = folder )
	endif
	
	if ( NMParamsInit( folder, wList, nm ) != 0 )
		return ""
	endif
	
	if ( toNotebook )
		vlist = NMCmdNumOptional( "toNotebook", toNotebook, vlist )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( toNotebook )
	
		folderShort = NMChild( folder )
	
		nbPrefix = "ST_" + NMFolderPrefix( "" ) + folderShort + "_wNotes_"
	
		nbName = NextGraphName( nbPrefix, -1, NMStatsVarGet( "OverwriteMode" ) )
	
		nbTitle = "Wave Notes : " + folderShort
	
		NMWaveNotes2( nm, nbName = nbName, nbTitle = nbTitle )
		
		returnStr = NMHistoryOutputWindows()
		
		return returnStr
		
	else
	
		return NMWaveNotes2( nm )
		
	endif

End // NMStatsWaveNotes

//****************************************************************
//****************************************************************

Static Function /S z_NMStatsWaveNamesCall()

	String folder = CurrentNMStats2FolderSelect( 0 )
		
	Variable fullPath = 1 + NumVarOrDefault( NMStatsDF + "PrintNamesFullPath", 0 )

	Prompt fullPath " ", popup "print wave names only;print folder + wave names;"
	DoPrompt "Print Stats Wave Names", fullPath

	if ( V_flag == 1 )
		return "" // cancel
	endif

	fullPath -= 1

	SetNMvar( NMStatsDF + "PrintNamesFullPath", fullPath )
	
	return NMStatsWaveNames( folder = folder, fullPath = fullPath, history = 1 )

End // z_NMStatsWaveNamesCall

//****************************************************************
//****************************************************************

Function /S NMStatsWaveNames( [ folder, fullPath, history ] )
	String folder // folder or subfolder, or nothing for current Stats subfolder
	Variable fullPath // ( 0 ) print only wave name ( 1 ) print folder + wname
	Variable history
	
	String wList, vlist = ""
	
	if ( ParamIsDefault( folder ) )
		folder = SELECTED
	else
		vlist = NMCmdStrOptional( "folder", folder, vlist )
	endif
	
	folder = CheckNMStatsFolderPath( folder )
	
	if ( !DataFolderExists( folder ) )
		return NM2ErrorStr( 30, "folder", folder )
	endif
	
	if ( ParamIsDefault( fullPath ) )
		fullPath = 0
	else
		vlist = NMCmdNumOptional( "fullPath", fullPath, vlist, integer = 1 )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	wList = NMStats2WaveSelectList( fullPath, folder = folder )
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	NMHistory( wList )
	
	return wList

End // NMStatsWaveNames

//****************************************************************
//****************************************************************
//
//	MPFA functions
//
//****************************************************************
//****************************************************************

Static Function /S z_NMStatsMPFAStatsCall()

	Variable icnt, itest, winNum = NaN
	String wName, nName, ampWaveName, noiseWaveName = ""

	String wList = NMStats2WaveSelectList( 0 )
	String folder = CurrentNMStats2FolderSelect( 1 )
	String currentWaveSelect = CurrentNMStats2WaveSelect( 1 )
	
	ampWaveName = NMChild( currentWaveSelect )
	
	for ( icnt = 0 ; icnt < strlen( ampWaveName ) ; icnt += 1 )
	
		itest = str2num( ampWaveName[ icnt, icnt ] )
		
		if ( numtype( itest ) == 0 )
			winNum = itest
			break
		endif
		
	endfor
	
	for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
	
		wName = StringFromList( icnt, wList )
		
		if ( strsearch( wName, "ST_Bsln" + num2istr( winNum ), 0 ) == 0 )
			noiseWaveName = wName
			break
		endif
	
	endfor
	
	Prompt ampWaveName, "select wave of peak values:", popup " ;" + wList
	Prompt noiseWaveName, "select wave of baseline noise values:", popup " ;" + wList
	DoPrompt "Stats MPFA", ampWaveName, noiseWaveName
	
	if ( ( V_flag == 1 ) || StringMatch( ampWaveName, " " ) || StringMatch( noiseWaveName, " " ) )
		return "" // cancel
	endif
	
	return NMStatsMPFAStats( folder = folder, ampWaveName = ampWaveName, noiseWaveName = noiseWaveName, table = 1, history = 1 )

End // z_NMStatsMPFAStatsCall

//****************************************************************
//****************************************************************

Function /S NMStatsMPFAStats( [ folder, ampWaveName, noiseWaveName, table, history ] )
	String folder
	String ampWaveName
	String noiseWaveName
	Variable table // ( 0 ) no ( 1 ) yes
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable chan
	String olist, tprefix, tName, title, wList, vlist = ""
	
	NMOutputListsReset()
	
	STRUCT Rect w
	
	if ( ParamIsDefault( folder ) )
		folder = SELECTED
	else
		vlist = NMCmdStrOptional( "folder", folder, vlist )
	endif
	
	folder = CheckNMStatsFolderPath( folder )
	
	if ( !DataFolderExists( folder ) )
		return NM2ErrorStr( 30, "folder", folder )
	endif
	
	if ( ParamIsDefault( ampWaveName ) )
		ampWaveName = StrVarOrDefault( folder + "CurrentStats2Wave", "" )
	else
		vlist = NMCmdStrOptional( "ampWaveName", ampWaveName, vlist )
	endif
	
	if ( ParamIsDefault( table ) )
		table = 1
	else
		vlist = NMCmdNumOptional( "table", table, vlist, integer = 1 )
	endif
	
	if ( ( strlen( ampWaveName ) == 0 ) || StringMatch( ampWaveName, SELECTED ) )
		ampWaveName = StrVarOrDefault( folder + "CurrentStats2Wave", "" )
	endif
	
	if ( !WaveExists( $folder+ampWaveName ) || ( WaveType( $folder+ampWaveName ) == 0 ) )
		return NM2ErrorStr( 1, "ampWaveName", ampWaveName )
	endif
	
	if ( ParamIsDefault( noiseWaveName ) )
		noiseWaveName = StrVarOrDefault( folder + "CurrentStats2Wave", "" )
	else
		vlist = NMCmdStrOptional( "noiseWaveName", noiseWaveName, vlist )
	endif
	
	if ( ( strlen( noiseWaveName ) == 0 ) || StringMatch( noiseWaveName, SELECTED ) )
		noiseWaveName = StrVarOrDefault( folder + "CurrentStats2Wave", "" )
	endif
	
	if ( !WaveExists( $folder+noiseWaveName ) || ( WaveType( $folder+noiseWaveName ) == 0 ) )
		return NM2ErrorStr( 1, "noiseWaveName", noiseWaveName )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	Variable varA, avgA, obsA, m4A
	Variable varN, avgN, obsN, m4N
	
	// amplitude stats
	
	if ( !WaveExists( $folder + AmpWaveName ) )
		return ""
	endif
	
	if ( !WaveExists( $folder + NoiseWaveName ) )
		return ""
	endif
	
	Wavestats /Q $( folder + AmpWaveName )
	varA = V_sdev * V_sdev
	avgA = V_avg
	obsA = V_npnts
	
	NMHistory( "Amp mean = " + num2str( avgA ) + ", var = " + num2str( varA ) )
	
	Duplicate /O $( folder + AmpWaveName ) $( folder + "ST_Power4" )
	Wave power4 = $( folder + "ST_Power4" )
	power4= ( power4 - V_avg )^4
	Wavestats /Q power4
	m4A = V_avg
	
	// noise stats
	
	Wavestats /Q $( folder + NoiseWaveName )
	varN = V_sdev * V_sdev
	avgN = V_avg
	obsN = V_npnts
	
	NMHistory( "Noise mean = " + num2str( avgN ) + ", var = " + num2str( varN ) )
	
	Duplicate /O $( folder + NoiseWaveName ) $( folder + "ST_Power4" )
	Wave power4 = $( folder + "ST_Power4" )
	power4 = ( power4 - V_avg )^4
	Wavestats /Q power4
	m4N = V_avg
	
	Variable var = varA - varN
	//print "standard error = ", sqrt( var )
	
	// compute h statistics (Saviane and Silver 2006)
	
	Variable h2A, m2A, h4A
	Variable h2N, m2N, h4N
	Variable varvar, sevar, weight
	
	h2A = varA
	m2A = h2A * ( obsA-1 ) / obsA
	h4A = ( ( 9 - 6*obsA ) * ( obsA^2 ) * ( m2A^2 ) ) + obsA * ( 3*obsA - ( 2*obsA^2 ) + obsA^3 ) * m4A // Eq. 47
	h4A /= obsA * ( obsA-1 ) * ( obsA-2 ) * ( obsA-3 )
	
	h2N = varN
	m2N = h2N * ( obsN-1 ) / obsN
	h4N = ( ( 9 - 6 *obsN ) * ( obsN^2 ) * ( m2N^2 ) ) + obsN * ( 3*obsN - ( 2*obsN^2 ) + obsN^3 ) * m4N // Eq. 47
	h4N /= obsN * ( obsN-1 ) * ( obsN-2 ) * ( obsN-3 )
	
	// compute the error of the sample variance
	
	varvar = ( ( obsA-1 ) / ( obsA^2 - 2*obsA + 3 ) ) * ( h4A - ( ( obsA-3 ) / ( obsA-1 ) ) * h2A^2 ) // Eq. 50
	varvar += ( ( obsN-1 ) / ( obsN^2 - 2*obsN + 3 ) ) * ( h4N - ( ( obsN-3 ) / ( obsN-1 ) ) * h2N^2 ) // Eq. 50
	
	//varvar = ( ( 2*varA^2 )/( obsA-1 ) ) + ( ( 2*varN^2 )/( obsN-1 ) ) // old error computation
	
	sevar = sqrt( varvar ) // standard error
	weight = 1/sevar // weights for igor are 1/SE: used for the NMMPFAFit proceedure
	
	// note, theoretical standard error ( se ) of var is approximate since it assumes normal distibution ( on basis of central limit theorem )
	// and var of var is likely to be Chi square distibution ( see Kendall's advanced theory of statistics, section 10.8 )
	
	KillWaves /Z $( folder + "ST_Power4" )
	
	olist = "mean=" + num2str( avgA ) + ";" +  "var=" + num2str( var ) + ";" + "var error=" + num2str( sevar )
	
	NMHistory( olist )
	
	if ( table )
	
		Make /O/N=1 $folder + "ST_MPFA_MEAN" = avgA
		Make /O/N=1 $folder + "ST_MPFA_VAR" = var
		Make /O/N=1 $folder + "ST_MPFA_SEMVAR" = sevar
		
		chan = CurrentNMChannel()
		tprefix = "ST_" + NMFolderPrefix( "" ) + NMWaveSelectStr() + "_MPFA_"
		tName = NextGraphName( tprefix, CurrentNMChannel(), NMStatsVarGet( "OverwriteMode" ) )
	
		title = NMFolderListName( "" ) + " : MPFA Stats : " + AmpWaveName
	
		NMWinCascadeRect( w )
		
		DoWindow /K $tName
		Edit /K=(NMK())/N=$tName/W=(w.left,w.top,w.right,w.bottom) as title
		AppendToTable /W=$tName $folder + "ST_MPFA_MEAN"
		AppendToTable /W=$tName $folder + "ST_MPFA_VAR"
		AppendToTable /W=$tName $folder + "ST_MPFA_SEMVAR"
		
		wList = folder + "ST_MPFA_MEAN" + ";"
		wList += folder + "ST_MPFA_VAR" + ";"
		wList += folder + "ST_MPFA_SEMVAR" + ";"
		
		SetNMstr( NMDF + "OutputWinList", tName )
		SetNMstr( NMDF + "OutputWaveList", wList )
		
		NMHistoryOutputWaves( subfolder = folder )
		NMHistoryOutputWindows()
	
	endif
	
	return olist
	
End // NMStatsMPFAStats

//****************************************************************
//****************************************************************
//
//	Functions not used anymore
//
//****************************************************************
//****************************************************************

Function CheckNMStatsVar( varName ) // NOT USED
	String varName
	
	if ( strlen( varName ) == 0 )
		return NM2Error( 21, "varName", varName )
	endif
	
	return SetNMvar( NMStatsDF + varName, NMStatsVarGet( varName ) )

End // CheckNMStatsVar

//****************************************************************
//****************************************************************

Function CheckNMStatsStr( strVarName ) // NOT USED
	String strVarName
	
	if ( strlen( strVarName ) == 0 )
		return NM2Error( 21, "strVarName", strVarName )
	endif
	
	return SetNMstr( NMStatsDF + strVarName, NMStatsStrGet( strVarName ) )

End // CheckNMStatsStr

//****************************************************************
//****************************************************************

Function XTimes2Stats() // : GraphMarquee // NOT USED

	String df = NMStatsDF
	
	if ( !DataFolderExists( df ) || !IsCurrentNMTab( "Stats" ) )
		return 0 
	endif

	GetMarquee /K left, bottom
	
	if ( V_Flag == 0 )
		return 0
	endif
	
	Variable win = NumVarOrDefault( df + "AmpNV", 0 )
	
	Wave AmpB = $df+"AmpB"
	Wave AmpE = $df+"AmpE"
	
	AmpB[ win ] = V_left
	AmpE[ win ] = V_right
	
	NMStatsAuto( force = 1 )

End // XTimes2Stats

//****************************************************************
//****************************************************************

Function StatsAmpInit( win ) // NOT USED
	Variable win // Stats window number ( -1 ) for currently selected window
	
	Variable winLast
	String select, windowList, last
	String df = NMStatsDF
	String wName = df + "AmpB"
	
	if ( !WaveExists( $wName ) )
		return NM2Error( 1, "wName", wName )
	endif
	
	Wave AmpB = $df+"AmpB"
	Wave AmpE = $df+"AmpE"
	Wave Bflag = $df+"Bflag"
	Wave BslnB = $df+"BslnB"
	Wave BslnE = $df+"BslnE"
	Wave BslnSubt = $df+"BslnSubt"
	Wave /T BslnSlct = $df+"BslnSlct"
	
	win = CheckNMStatsWin( win )
	
	if ( numtype( win ) > 0 )
		return -1
	endif
	
	select = StatsAmpSelectGet( win )
	
	windowList = NMStatsWinList( 1, "" )
	
	if ( ItemsInList( windowList ) == 0 )
		return 0 // nothing to do
	else
		last = StringFromList( ItemsInList( windowList )-1, windowList )
		winLast = str2num( last )
	endif
	
	if ( ( winLast < 0 ) || ( winLast >= numpnts( AmpB ) ) || ( win == winLast ) )
		return 0 // something wrong
	endif
	
	if ( StringMatch( select, "Off" ) ) // copy previous window values to new window
		
		if ( ( win > 0 ) && ( numtype( AmpB[ win ] ) > 0 ) && ( numtype( AmpE[ win ] ) > 0 ) )
		
			AmpB[ win ] = AmpB[ winLast ]
			AmpE[ win ] = AmpE[ winLast ]
			
			Bflag[ win ] = Bflag[ winLast ]
			BslnB[ win ] = BslnB[ winLast ]
			BslnE[ win ] = BslnE[ winLast ]
			BslnSlct[ win ] = BslnSlct[ winLast ]
			BslnSubt[ win ] = BslnSubt[ winLast ]
			
		endif
		
	endif

End // StatsAmpInit

//****************************************************************
//****************************************************************

Function NMStatsVar( varName ) // NOT USED
	String varName
	
	return NMStatsVarGet( varName )
	
End // NMStatsVar

//****************************************************************
//****************************************************************

Function /S NMStatsStr( strVarName ) // NOT USED
	String strVarName
	
	return NMStatsStrGet( strVarName )
	
End // NMStatsStr

//****************************************************************
//****************************************************************

Function SetNMStatsVar( varName, value ) // NOT USED
	String varName
	Variable value
	
	String df = NMStatsDF
	
	if ( strlen( varName ) == 0 )
		return NM2Error( 21, "varName", varName )
	endif
		
	if ( !DataFolderExists( df ) )
		return NM2Error( 30, "StatsDF", df )
	endif
	
	Variable /G $df+varName = value
	
	return 0
	
End // SetNMStatsVar

//****************************************************************
//****************************************************************

Function SetNMStatsStr( strVarName, strValue ) // NOT USED
	String strVarName
	String strValue
	
	String df = NMStatsDF
	
	if ( strlen( strVarName ) == 0 )
		return NM2Error( 21, "strVarName", strVarName )
	endif
		
	if ( !DataFolderExists( df ) )
		return NM2Error( 30, "StatsDF", df )
	endif
	
	String /G $df+strVarName = strValue
	
	return 0
	
End // SetNMStatsStr
	
//****************************************************************
//****************************************************************
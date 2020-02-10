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
//	Spontaneous Event Detection
//
//	NM tab entry "Event"
//
//	Threshold search algorithm based on Kudoh and Taguchi,
//	Biosensors and Bioelectronics 17, 2002, pp. 773 - 782
//	"A simple exploratory algorithm for accurate detection of 
//	spontaneous synaptic events"
//
//	Template-Matching Algorithm by Clements and Bekkers,
//	Biophysical Journal, 1997, pp. 220-229
//	"Detection of spontaneous synaptic events with an
//	optimally scaled template"
//
//	Set and Get functions:
//
//		NMEventSet( [ xbgn, xend, searchTime, searchMethod, searchMethodStr, searchLevel, searchThreshold, searchNstdv, templateMatching, matchLevel, baseWin, searchDT, searchSkip, OnsetOn, OnsetWin, OnsetNstdv, OnsetLimit, PeakOn, PeakWin, PeakNstdv, PeakLimit, displayWin, tableSelect, review, history ] )
//		NMConfigVarSet( "Event", varName, value )
//		NMConfigStrSet( "Event", strVarName, strValue )
//		NMEventVarGet( varName )
//		NMEventStrGet( strVarName )
//
//	Useful functions:
//
//		NMEventSearch( [ func, history ] )
//		EventFindAll( waveSelect, displayResults [ history ] )
//		NMEventTableClear( tableName [ history ] )
//		NMEventTableKill( tableName [ history ] )
//		NMEventHistogram( [ waveOfEventTimes, repetitions, binSize, xbgn, xend, yUnits, history ] )
//		NMEventIntervalHistogram( [ waveOfEventTimes, binSize, xbgn, xend, minInterval, maxInterval, history ] )
//		NMEvents2Waves( waveOfWaveNums, waveOfEventTimes, xwinBefore, xwinAfter, stopAtNextEvent, allowTruncatedEvents, chanNum, outputWavePrefix [ history ] )
//
//****************************************************************
//****************************************************************
//
//	Default Values
//
//****************************************************************
//****************************************************************

Static Constant SearchMethod = 3 // threshold > baseline
Static Constant SearchThreshold = 10 // absolute value
Static Constant SearchLevel = 10
Static Constant SearchNstdv = 4 // number of standard deviations
Static Constant MatchLevel = 4 // template matching search level

Static Constant BaseWin = 4 // time

Static Constant SearchDT = 2 // time
Static Constant SearchSlope = 1
Static Constant SearchSkip = 5 // points

Static Constant OnsetOn = 1 // ( 0 ) no ( 1 ) yes
Static Constant OnsetWin = 0.5 // time
Static Constant OnsetNstdv = 1 // number of standard deviations
Static Constant OnsetLimit = 2 // time

Static Constant PeakOn = 1 // ( 0 ) no ( 1 ) yes
Static Constant PeakWin = 0.5 // time
Static Constant PeakNstdv = 1 // number of standard deviations
Static Constant PeakLimit = 3 // time

Static Constant UniquenessCriteriaOn = 1 // ( 0 ) no ( 1 ) yes
Static Constant UniquenessWindow = 0.02 // time
Static Constant UniquenessOverwriteAlert = 1 // when saving an event, alert user if a similar event already exists ( 0 ) no alert, just overwrite ( 1 ) ask if to overwrite

Static Constant MatchTau1 = 2 // time constant
Static Constant MatchTau2 = 3 // time constant

Static Constant DsplyWin = 50 // time
Static Constant DsplyFraction = 0.5 // fraction between 0 and 1 ( 0.5 for middle )

Static Constant SaveRejected = 1 // ( 0 ) no ( 1 ) yes
Static Constant FindNextAfterSaving = 1 // ( 0 ) no ( 1 ) yes
Static Constant FindNextAfterDeleting = 1 // ( 0 ) no ( 1 ) yes
Static Constant SearchWaveAdvance = 1 // ( 0 ) no ( 1 ) yes
Static Constant ReviewWaveAdvance = 1 // ( 0 ) no ( 1 ) yes
Static Constant AlertsOn = 1 // ( 0 ) no ( 1 ) yes
Static Constant ReviewAlert = 1 // ( 0 ) no ( 1 ) yes

Static Constant Overwrite = 1

Static StrConstant BslnColor = "65280,43520,0"
Static StrConstant DEFAULTSUBFOLDER = "_subfolder_"

Static StrConstant AlertTitle = "NM Event Detection"
			
//****************************************************************
//****************************************************************
//****************************************************************

StrConstant NMEventDF = "root:Packages:NeuroMatic:Event:"

Static StrConstant OldEventTableSelect = "Event Table "

Static StrConstant NMEventSeachMethodList = "level detection (+slope);level detection (-slope);threshold > baseline;threshold < baseline;Nstdv > baseline;Nstdv < baseline;"
Static StrConstant NMEventSeachMethodListShort = "level+;level-;thresh+;thresh-;Nstdv+;Nstdv-;"

//****************************************************************
//****************************************************************
//****************************************************************

Menu "NeuroMatic"

	Submenu StrVarOrDefault( NMDF + "NMMenuShortcuts" , "\\M1(Keyboard Shortcuts" )
		StrVarOrDefault( NMDF + "NMMenuShortcutEvent0" , "" )
		StrVarOrDefault( NMDF + "NMMenuShortcutEvent1" , "" ), /Q, NMEventSearch( func = "Last" )
		StrVarOrDefault( NMDF + "NMMenuShortcutEvent2" , "" ), /Q, NMEventSearch( func = "Next" )
		StrVarOrDefault( NMDF + "NMMenuShortcutEvent3" , "" ), /Q, NMEventSearch( func = "Save" )
		StrVarOrDefault( NMDF + "NMMenuShortcutEvent4" , "" ), /Q, NMEventSearch( func = "Reject" )
	End
	
End // NeuroMatic menu

//****************************************************************
//****************************************************************
//****************************************************************

Function NMMenuBuildEvent()

	if ( NMVarGet( "NMOn" ) && StringMatch( CurrentNMTabName(), "Event" ) )
		SetNMstr( NMDF + "NMMenuShortcutEvent0", "-" )
		SetNMstr( NMDF + "NMMenuShortcutEvent1", "Previous Event/4" )
		SetNMstr( NMDF + "NMMenuShortcutEvent2", "Next Event/5" )
		SetNMstr( NMDF + "NMMenuShortcutEvent3", "Save Event/6" )
		SetNMstr( NMDF + "NMMenuShortcutEvent4", "Reject Event/7" )
	else
		SetNMstr( NMDF + "NMMenuShortcutEvent0", "" )
		SetNMstr( NMDF + "NMMenuShortcutEvent1", "" )
		SetNMstr( NMDF + "NMMenuShortcutEvent2", "" )
		SetNMstr( NMDF + "NMMenuShortcutEvent3", "" )
		SetNMstr( NMDF + "NMMenuShortcutEvent4", "" )
	endif

End // NMMenuBuildEvent

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMTabPrefix_Event()

	return "EV_"

End // NMTabPrefix_Event

//****************************************************************
//****************************************************************
//****************************************************************

Function EventTab( enable ) // enable/disable Event Tab
	Variable enable // ( 1 ) enable ( 0 ) disable

	if ( enable )
		CheckNMPackage( "Event", 1 ) // create globals if necessary
		MakeEventTab( 0 ) // create controls if necessary
		NMEventAuto()
		UpdateEventTab()
		NMChannelGraphDisable( channel = -2, all = 0 )
	endif
	
	if ( !DataFolderExists( NMEventDF ) )
		return 0 // Event Tab not created yet
	endif
	
	NMEventChanGraphControls( enable )
	EventDisplay( enable )
	EventCursors( enable )

End // EventTab

//****************************************************************
//****************************************************************
//****************************************************************

Function EventTabKill( what )
	String what
	
	String df = NMEventDF
	
	strswitch( what )
		case "waves":
			break
		case "globals":
			if ( DataFolderExists( df ) )
				KillDataFolder $df
			endif 
			break
	endswitch

End // EventTabKill

//****************************************************************
//****************************************************************

Function /S CheckNMEventFolderPath( folder )
	String folder
	
	String path, fName
	
	if ( strlen( folder ) == 0 )
		return CurrentNMFolder( 1 ) // current data folder
	endif
	
	if ( StringMatch( folder, DEFAULTSUBFOLDER ) )
		folder = CurrentNMEventSubfolder()
		CheckNMSubfolder( folder )
		return folder
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
	
End // CheckNMEventFolderPath

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Variables, Strings and Waves
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventCheck()
	
	if ( !DataFolderExists( NMEventDF ) )
		return -1
	endif
	
	CheckNMwave( NMEventDisplayWaveName( "ThreshT" ), 0, 0 )
	CheckNMwave( NMEventDisplayWaveName( "ThreshY" ), 0, 0 )
	CheckNMwave( NMEventDisplayWaveName( "OnsetT" ), 0, 0 )
	CheckNMwave( NMEventDisplayWaveName( "OnsetY" ), 0, 0 )
	CheckNMwave( NMEventDisplayWaveName( "PeakT" ), 0, 0 )
	CheckNMwave( NMEventDisplayWaveName( "PeakY" ), 0, 0 )
	
	CheckNMwave( NMEventDisplayWaveName( "BaseT" ), 2, 0 )
	CheckNMwave( NMEventDisplayWaveName( "BaseY" ), 2, Nan )
	CheckNMwave( NMEventDisplayWaveName( "ThisT" ), 1, 0 )
	CheckNMwave( NMEventDisplayWaveName( "ThisY" ), 1, Nan )
	CheckNMwave( NMEventDisplayWaveName( "SearchT" ), 3, 0 )
	CheckNMwave( NMEventDisplayWaveName( "SearchY" ), 3, Nan )
	
	return 0
	
End // NMEventCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMEventVarGet( varName )
	String varName
	
	return CheckNMvar( NMEventDF+varName, NMEventVarGet( varName ) )

End // CheckNMEventVar

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventConfigs()

	NMEventConfigsCheck()
	
	NMEventConfigVar( "UseSubfolders", "use subfolders when creating Event result waves ( uncheck for previous NM formatting )", "boolean" )
	
	NMEventConfigVar( "SaveRejected", "save rejected events to a rejection table for review", "boolean" )
	
	NMEventConfigVar( "FindNextAfterSaving", "automatically search for next event after saving an event", "boolean" )
	NMEventConfigVar( "FindNextAfterDeleting", "automatically search for next event after deleting an event", "boolean" )
	NMEventConfigVar( "SearchWaveAdvance", "automatically advance to next/previous wave when searching", "boolean" )
	NMEventConfigVar( "ReviewWaveAdvance", "automatically advance to next/previous wave when reviewing", "boolean" )
	
	NMEventConfigVar( "AlertsOn", "global alert flag for Event tab", "boolean" )
	NMEventConfigVar( "ReviewAlert", "alert user about Review checkbox when selecting Auto", "boolean" )

	NMEventConfigVar( "SearchMethod", "(1) level+ (2) level- (3) threshold+ (4) threshold- (5) Nstdv+ (6) Nstdv-", " ;level+;level-;threshold+;threshold-;Nstdv+;Nstdv-;" )
	
	NMEventConfigVar( "SearchBgn", "x-axis search limit begin", "" )
	NMEventConfigVar( "SearchEnd", "x-axis search limit end", "" )
	
	NMEventConfigVar( "SearchThreshold", "threshold value above/below baseline", "" ) // threshold < baseline
	NMEventConfigVar( "SearchNstdv", "number of STDV above/below baseline", "" ) // Nstdv < baseline
	NMEventConfigVar( "SearchLevel", "absolute threshold level value", "" ) // level detection
	
	NMEventConfigVar( "BaseWin", "baseline average window", "" )
	
	NMEventConfigVar( "SearchDT", "search window, starting from mid-baseline point", "" )
	NMEventConfigVar( "SearchSlope", "use event slope to limit threshold crossings", "boolean" )
	NMEventConfigVar( "SearchSkip", "points to advance (skip) when searching for next event (>)", "pnts" )
	
	NMEventConfigVar( "UniquenessCriteriaOn", "determine if detected events are unique before saving to table", "boolean" )
	NMEventConfigVar( "UniquenessWindow", "event uniqueness window", "" )
	NMEventConfigVar( "UniquenessOverwriteAlert", "when saving an event, alert user if a similar event already exists", "" )
	
	NMEventConfigVar( "OnsetOn", "compute onset", "boolean" )
	NMEventConfigVar( "OnsetWin", "onset average window", "" )
	NMEventConfigVar( "OnsetNstdv", "number of STDV above/below onset avg win", "" )
	NMEventConfigVar( "OnsetLimit", "onset search limit", "" )
	
	NMEventConfigVar( "PeakOn", "compute peak", "boolean" )
	NMEventConfigVar( "PeakWin", "peak average window", "" )
	NMEventConfigVar( "PeakNstdv", "number of STDV above/below peak avg win", "" )
	NMEventConfigVar( "PeakLimit", "peak search limit", "" )
	
	NMEventConfigVar( "DsplyWin", "channel display window size", "" )
	NMEventConfigVar( "DsplyFraction", "fraction of display window to view current event", "" )
	
	NMEventConfigStr( "BslnColor", "baseline display color", "RGB" )
	NMEventConfigStr( "SearchColor", "searching display color", "RGB" )
	NMEventConfigStr( "ThreshColor", "threshold/level display color", "RGB" )
	NMEventConfigStr( "OnsetColor", "onset display color", "RGB" )
	NMEventConfigStr( "PeakColor", "peak display color", "RGB" )
	NMEventConfigStr( "MatchColor", "matching template color", "RGB" )
			
End // NMEventConfigs

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventConfigsCheck()

	String cdf = ConfigDF( "Event" )
	
	NMConfigVarRename( "Event", "Thrshld", "SearchThreshold" )
	NMConfigVarRename( "Event", "BaseDT", "SearchDT" )
	//NMConfigVarRename( "Event", "Positive", "PositiveEvents" )
	
	NMConfigVarRename( "Event", "OnsetFlag", "OnsetOn" )
	
	if ( exists( cdf + "OnsetLimit" ) == 0 )
		NMConfigVarRename( "Event", "OnsetWin", "OnsetLimit" )
		NMConfigVarRename( "Event", "OnsetAvg", "OnsetWin" )
	endif
	
	NMConfigVarRename( "Event", "PeakFlag", "PeakOn" )
	
	if ( exists( cdf + "PeakLimit" ) == 0 )
		NMConfigVarRename( "Event", "PeakWin", "PeakLimit" )
		NMConfigVarRename( "Event", "PeakAvg", "PeakWin" )
	endif
	
End // NMEventConfigsCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventConfigVar( varName, description, type )
	String varName
	String description
	String type
	
	return NMConfigVar( "Event", varName, NMEventVarGet( varName ), description, type )
	
End // NMEventConfigVar

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventConfigStr( varName, description, type )
	String varName
	String description
	String type
	
	return NMConfigStr( "Event", varName, NMEventStrGet( varName ), description, type )
	
End // NMEventConfigStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventVarGet( varName )
	String varName
	
	Variable defaultVal = Nan
	String df = NMEventDF
	
	strswitch( varName )
	
		case "UseSubfolders":
			defaultVal = 1
			break
	
		case "SearchMethod":
			defaultVal = SearchMethod
			break
			
		case "SearchThreshold":
			defaultVal = SearchThreshold
			break

		case "SearchNstdv":
			defaultVal = SearchNstdv
			break
			
		case "SearchLevel":
			defaultVal = SearchLevel
			break
			
		case "MatchLevel":
			defaultVal = MatchLevel
			break
			
		case "SearchValue":
			defaultVal = Nan
			break
			
		case "SearchBgn":
			defaultVal = -inf
			break
			
		case "SearchEnd":
			defaultVal = inf
			break
			
		case "SearchTime":
			defaultVal = 0
			break
			
		case "SearchDT":
			defaultVal = SearchDT
			break
			
		case "SearchSlope":
			defaultVal = SearchSlope
			break
			
		case "SearchSkip":
			defaultVal = SearchSkip // points
			break
			
		case "BaseWin":
			defaultVal = BaseWin
			break
			
		case "ThreshX":
			defaultVal = Nan
			break
			
		case "ThreshY":
			defaultVal = Nan
			break
			
		case "OnsetOn":
			defaultVal = OnsetOn
			break
			
		case "OnsetWin":
			defaultVal = OnsetWin
			break
			
		case "OnsetNstdv":
			defaultVal = OnsetNstdv
			break
			
		case "OnsetLimit":
			defaultVal = OnsetLimit
			break
			
		case "OnsetY":
			defaultVal = Nan
			break
			
		case "OnsetX":
			defaultVal = Nan
			break
			
		case "PeakOn":
			defaultVal = PeakOn
			break
			
		case "PeakWin":
			defaultVal = PeakWin
			break
			
		case "PeakNstdv":
			defaultVal = PeakNstdv
			break
		
		case "PeakLimit":
			defaultVal = PeakLimit
			break
			
		case "PeakY":
			defaultVal = Nan
			break
			
		case "PeakX":
			defaultVal = Nan
			break
			
		case "BaseY":
			defaultVal = Nan
			break
			
		case "UniquenessWindow":
			defaultVal = UniquenessWindow
			break
			
		case "UniquenessCriteriaOn":
			defaultVal = UniquenessCriteriaOn
			break
			
		case "UniquenessOverwriteAlert":
			defaultVal = UniquenessOverwriteAlert
			break
			
		case "MatchFlag":
			defaultVal = 0
			break
			
		case "MatchTau1":
			defaultVal = MatchTau1
			break
			
		case "MatchTau2":
			defaultVal = MatchTau2
			break
			
		case "MatchBsln":
			defaultVal = Nan
			break
			
		case "MatchWform":
			defaultVal = 8
			break
			
		//case "EventNum":
		//	defaultVal = 0
		//	break
	
		case "NumEvents":
			defaultVal = 0
			break
			
		case "FoundEventFlag":
			defaultVal = 0
			break
			
		case "DsplyWin":
			defaultVal = DsplyWin
			break
			
		case "DsplyFraction":
			defaultVal = DsplyFraction
			break
			
		//case "TableNum":
		//	defaultVal = -1
		//	break
		
		case "SaveRejected":
			defaultVal = SaveRejected
			break
			
		case "FindNextAfterSaving":
			defaultVal = FindNextAfterSaving
			break
			
		case "FindNextAfterDeleting":
			defaultVal = FindNextAfterDeleting
			break
			
		case "SearchWaveAdvance":
			defaultVal = SearchWaveAdvance
			break
			
		case "ReviewWaveAdvance":
			defaultVal = ReviewWaveAdvance
			break
			
		case "ReviewFlag":
			defaultVal = 0
			break
			
		case "AlertsOn":
			defaultVal = AlertsOn
			break
			
		case "ReviewAlert":
			defaultVal = ReviewAlert
			break
			
		case "AutoTSelect":
			defaultVal = 1
			break
			
		case "AutoTZero":
			defaultVal = 1
			break
			
		case "AutoDsply":
			defaultVal = 1
			break
			
		case "E2W_before":
			defaultVal = 2
			break
			
		case "E2W_after":
			defaultVal = 10
			break
			
		case "E2W_stopAtNextEvent":
			defaultVal = 0
			break
			
		default:
			NMDoAlert( "NMEventVar Error: no variable called " + NMQuotes( varName ) + ".", title=AlertTitle )
			return Nan
	
	endswitch
	
	return NumVarOrDefault( df+varName, defaultVal )
	
End // NMEventVarGet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventStrGet( strVarName )
	String strVarName
	
	String defaultStr = ""
	
	strswitch( strVarName )
	
		case "Template":
			defaultStr = ""
			break
			
		case "E2W_chan":
			defaultStr = ChanNum2Char( CurrentNMChannel() )
			break
			
		case "S2W_WavePrefix":
			defaultStr = "Event"
			break
			
		case "HistoSelect":
			defaultStr = "interval"
			break
			
		case "BslnColor":
			defaultStr = BslnColor
			break
			
		case "SearchColor":
			defaultStr = NMGreenStr
			break
			
		case "ThreshColor":
			defaultStr = NMRedStr
			break
			
		case "OnsetColor":
			defaultStr = NMRedStr
			break
			
		case "PeakColor":
			defaultStr = NMRedStr
			break
			
		case "MatchColor":
			defaultStr = NMBlueStr
			break
			
		default:
			NMDoAlert( "NMEventStr Error: no variable called " + NMQuotes( strVarName ) + ".", title=AlertTitle )
			return ""
	
	endswitch
	
	return StrVarOrDefault( NMEventDF + strVarName, defaultStr )
			
End // NMEventStrGet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventRejectsOn()

	if ( NMEventVarGet( "ReviewFlag" ) == 2 )
		return 1
	else
		return 0
	endif

End // NMEventRejectsOn

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMEventVariables()

	Variable xbgn, xend
	
	Variable searchMethod = NMEventVarGet( "SearchMethod" )
	Variable searchTime = NMEventVarGet( "SearchTime" )
	Variable matchFlag = NMEventVarGet( "MatchFlag" )
	//Variable threshOrLevel = NMEventVarGet( "SearchThreshold" )
	
	SetNMvar( NMEventDF + "SearchValue", NMEventThresholdLevel() ) // update display variable
	
	if ( matchFlag > 0 )
		SetNMvar( NMEventDF + "OnsetOn", 1 )
	endif
	
	xbgn = EventSearchBgn()
	xend = EventSearchEnd()
	
	if ( searchTime < xbgn )
		SetNMvar( NMEventDF + "SearchTime", xbgn )
	endif
	
	if ( searchTime > xend )
		SetNMvar( NMEventDF + "SearchTime", xend )
	endif

End // CheckNMEventVariables

//****************************************************************
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
//****************************************************************

Function EventSearchBgn()

	String dName = ChanDisplayWave( -1 )

	Variable t = NMEventVarGet( "SearchBgn" )

	if ( ( numtype( t ) > 0 ) && WaveExists( $dName ) )
		t = leftx( $dName )
	endif
	
	return t

End // EventSearchBgn

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSearchEnd()

	String dName = ChanDisplayWave( -1 )

	Variable t = NMEventVarGet( "SearchEnd" )

	if ( ( numtype( t ) > 0 ) && WaveExists( $dName ) )
		t = rightx( $dName )
	endif
	
	return t

End // EventSearchEnd

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventBaselineOn()

	Variable searchMethod = NMEventVarGet( "SearchMethod" )
	Variable matchFlag = NMEventVarGet( "MatchFlag" )
	
	if ( matchFlag > 0 )
		return 0
	endif
	
	if ( searchMethod > 2 ) 
		return 1
	endif

	return 0
	
End // NMEventBaselineOn

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Channel Graph Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventDisplayWaveName( wName )
	String wName
	
	return NMEventDF + "EV_" + wName
	
End // NMEventDisplayWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventChanGraphControls( enable )
	Variable enable
	
	Variable ccnt, displayWin, lim1, lim2, inc, y0 = 8
	
	Variable chan = CurrentNMChannel()
	
	String gName, dName
	
	String computer = NMComputerType()
	
	if ( StringMatch( computer, "mac" ) )
		y0 = 3
	endif
	
	for ( ccnt = 0; ccnt < 10; ccnt += 1 ) // remove from all possible channel graphs
	
		if ( enable && ( ccnt == chan ) )
			continue
		endif
	
		gName = ChanGraphName( ccnt )
	
		if ( Wintype( gName ) == 0 )
			continue
		endif
		
		KillControl /W=$gName EV_WinSlide
		KillControl /W=$gName EV_ZoomTxt
		KillControl /W=$gName EV_WinSlide2
		KillControl /W=$gName EV_ZoomTxt2
		
	endfor
	
	if ( enable )
	
		gName = ChanGraphName( chan )
		
		if ( Wintype( gName ) == 0 )
			return 0
		endif
		
		dName = ChanDisplayWave( chan )
		
		lim1 = deltax( $dName ) * 10 * 100
		lim2 = ( rightx( $dName ) - leftx( $dName ) ) * 2 * 100
		
		lim1 = log( lim1 )
		lim2 = log( lim2 )
		
		inc = ( lim2 - lim1 ) / 100
		
		displayWin = log( NMEventVarGet( "DsplyWin" ) * 100 )
		
		SetNMvar( NMEventDF+"DsplyWinSlider", displayWin )
	
		Slider EV_WinSlide, win=$gName, pos={615, y0}, size={80,50}, limits={lim1,lim2,inc}, vert=0, side=2, ticks=0, variable=$(NMEventDF+"DsplyWinSlider"), proc=NMEventWinSlide
		
		TitleBox /Z EV_ZoomTxt, win=$gName, pos={570,y0+2}, size={40,18}, fsize=9, fixedSize=1
		TitleBox /Z EV_ZoomTxt, win=$gName, frame=0, title="x-zoom"
		
		lim1 = leftx( $dName )
		lim2 = rightx( $dName )
		inc = ( lim2 - lim1 ) / 100
		
		displayWin = NMEventVarGet( "SearchTime" )
		
		SetNMvar( NMEventDF+"DsplyWinSlider2", displayWin )
		
		Slider EV_WinSlide2, win=$gName, pos={460, y0}, size={80,50}, limits={lim1,lim2,inc}, vert=0, side=2, ticks=0, variable=$(NMEventDF+"DsplyWinSlider2"), proc=NMEventWinSlide
		
		TitleBox /Z EV_ZoomTxt2, win=$gName, pos={415,y0+2}, size={40,18}, fsize=9, fixedSize=1
		TitleBox /Z EV_ZoomTxt2, win=$gName, frame=0, title="Event x"
		
	endif
	
End // NMEventChanGraphControls

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventWinSlide(ctrlName, value, event) : SliderControl
	String ctrlName
	Variable value // slider value
	Variable event // event - bit 0: value set; 1: mouse down, 2: mouse up, 3: mouse moved
	
	Variable displayWin, history
	
	if ( event == 4 )
		history = 1
	endif
	
	if ( StringMatch( ctrlName, "EV_WinSlide" ) && ( ( event == 4 ) || ( event == 9 ) ) && IsCurrentNMTab( "Event" ) )
		displayWin = 10 ^ value / 100
		NMEventSet( displayWin = displayWin, history = history )
	endif
	
	if ( StringMatch( ctrlName, "EV_WinSlide2" ) && ( ( event == 4 ) || ( event == 9 ) ) && IsCurrentNMTab( "Event" ) )
		NMEventSet( searchTime = value, history = history )
	endif

End // NMEventWinSlide

//****************************************************************
//****************************************************************
//****************************************************************

Function EventDisplay( appnd ) // append/remove event display waves from channel graph
	Variable appnd // ( 0 ) remove wave ( 1 ) append wave
	Variable icnt
	
	Variable ccnt, found
	String gName, xName, yName, color, df = NMEventDF
	
	STRUCT NMRGB c
	
	Variable chan = CurrentNMChannel()
	
	if ( !DataFolderExists( df ) )
		return 0 // event tab has not been initialized yet
	endif
	
	Variable matchFlag = NMEventVarGet( "MatchFlag" )
	
	for ( ccnt = 0; ccnt < 10; ccnt += 1 )
	
		gName = ChanGraphName( ccnt )
	
		if ( Wintype( gName ) == 0 )
			continue
		endif
	
		//DoWindow /F $gName
		
		found = WhichListItem( "EV_ThreshY", TraceNameList( gName, ";", 1 ), ";", 0, 0 )
	
		RemoveFromGraph /Z/W=$gName EV_BaseY, EV_SearchY, EV_ThisY, EV_ThreshY, EV_OnsetY, EV_PeakY, EV_MatchTmplt
	
		if ( ( appnd == 0 ) || ( ccnt != chan ) )
			
			SetAxis /A/W=$gName
			HideInfo /W=$gName
			
			if ( found != -1 ) // remove cursors
				Cursor /K/W=$gName A
				Cursor /K/W=$gName B
			endif
		
			continue
			
		endif
	
		if ( ( matchFlag > 0 ) && ( exists( NMEventDisplayWaveName( "MatchTmplt" ) ) == 1 ) )
		
			yName = NMEventDisplayWaveName( "MatchTmplt" )
		
			AppendToGraph /R=match /W=$gName $yName
			
			yName = NMChild( yName )
			
			NMColorList2RGB( NMEventStrGet( "MatchColor" ), c )
			
			ModifyGraph /W=$gName rgb( $yName )=(c.r,c.g,c.b)
			ModifyGraph /W=$gName axRGB( match )=(c.r,c.g,c.b)
			
			xName = NMEventDisplayWaveName( "ThisT" )
			yName = NMEventDisplayWaveName( "ThisY" )
			
			AppendToGraph /R=match /W=$gName $yName vs $xName
			
			yName = NMChild( yName )
			
			NMColorList2RGB( NMEventStrGet( "SearchColor" ), c )
			
			ModifyGraph /W=$gName mode( $yName )=3, marker( $yName )=9, msize( $yName )=6
			ModifyGraph /W=$gName mrkThick( $yName )=2, rgb( $yName )=(c.r,c.g,c.b)
			
			xName = NMEventDisplayWaveName( "ThreshT" )
			yName = NMEventDisplayWaveName( "ThreshY" )
			
			AppendToGraph /R=match /W=$gName $yName vs $xName
			
			yName = NMChild( yName )
			
			NMColorList2RGB( NMEventStrGet( "ThreshColor" ), c )
			
			ModifyGraph /W=$gName mode( $yName )=3, marker( $yName )=9, msize( $yName )=6
			ModifyGraph /W=$gName mrkThick( $yName )=2, rgb( $yName )=(c.r,c.g,c.b)
			
			Label /W=$gName match "Detection Criteria"
			
		endif
		
		if ( exists( NMEventDisplayWaveName( "ThreshY" ) ) == 1 )
		
			xName = NMEventDisplayWaveName( "BaseT" )
			yName = NMEventDisplayWaveName( "BaseY" )
			
			AppendToGraph /W=$gName $yName vs $xName
			
			yName = NMChild( yName )
			
			NMColorList2RGB( NMEventStrGet( "BslnColor" ), c )
		
			ModifyGraph /W=$gName mode( $yName )=0
			ModifyGraph /W=$gName lsize( $yName )=2, rgb( $yName )=(c.r,c.g,c.b)
			
			if ( !matchFlag )
			
				xName = NMEventDisplayWaveName( "SearchT" )
				yName = NMEventDisplayWaveName( "SearchY" )
			
				AppendToGraph /W=$gName $yName vs $xName
				
				yName = NMChild( yName )
				
				NMColorList2RGB( NMEventStrGet( "SearchColor" ), c )
				
				ModifyGraph /W=$gName mode( $yName )=0, lstyle( $yName )=1
				ModifyGraph /W=$gName rgb( $yName )=(c.r,c.g,c.b)
			
				xName = NMEventDisplayWaveName( "ThisT" )
				yName = NMEventDisplayWaveName( "ThisY" )
			
				AppendToGraph /W=$gName $yName vs $xName
				
				yName = NMChild( yName )
				
				ModifyGraph /W=$gName mode( $yName )=3, marker( $yName )=9, msize( $yName )=4
				ModifyGraph /W=$gName mrkThick( $yName )=2, rgb( $yName )=(c.r,c.g,c.b)
				
				xName = NMEventDisplayWaveName( "ThreshT" )
				yName = NMEventDisplayWaveName( "ThreshY" )
				
				AppendToGraph /W=$gName $yName vs $xName
				
				yName = NMChild( yName )
				
				NMColorList2RGB( NMEventStrGet( "ThreshColor" ), c )
				
				ModifyGraph /W=$gName mode( $yName )=3, marker( $yName )=9, msize( $yName )=4
				ModifyGraph /W=$gName mrkThick( $yName )=2, rgb( $yName )=(c.r,c.g,c.b)
				
			endif
			
			xName = NMEventDisplayWaveName( "OnsetT" )
			yName = NMEventDisplayWaveName( "OnsetY" )
			
			AppendToGraph /W=$gName $yName vs $xName
			
			yName = NMChild( yName )
			
			NMColorList2RGB( NMEventStrGet( "OnsetColor" ), c )
			
			ModifyGraph /W=$gName mode( $yName )=3, marker( $yName )=19, msize( $yName )=4
			ModifyGraph /W=$gName mrkThick( $yName )=2, rgb( $yName )=(c.r,c.g,c.b)
			
			xName = NMEventDisplayWaveName( "PeakT" )
			yName = NMEventDisplayWaveName( "PeakY" )
			
			AppendToGraph /W=$gName $yName vs $xName
			
			yName = NMChild( yName )
			
			NMColorList2RGB( NMEventStrGet( "PeakColor" ), c )
			
			ModifyGraph /W=$gName mode( $yName )=3, marker( $yName )=16, msize( $yName )=3
			ModifyGraph /W=$gName mrkThick( $yName )=2, rgb( $yName )=(c.r,c.g,c.b)
			
			ShowInfo /W=$gName
			
		endif
		
	endfor

End // EventDisplay

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateEventDisplay( [ clearCurrentEventDisplay ] ) // update event display waves from table wave values
	Variable clearCurrentEventDisplay

	Variable icnt, npntsDisplay, npntsTable
	String wNameT, gName
	
	Variable rejections = NMEventRejectsOn()

	Variable currentChan = CurrentNMChannel()
	Variable currentWave = CurrentNMWave()
	
	gName = ChanGraphName( currentChan )
	
	if ( !WaveExists( $NMEventDisplayWaveName( "ThreshT" ) ) )
		return -1
	endif

	Wave ThreshT = $NMEventDisplayWaveName( "ThreshT" )
	Wave ThreshY = $NMEventDisplayWaveName( "ThreshY" )
	Wave OnsetT = $NMEventDisplayWaveName( "OnsetT" )
	Wave OnsetY = $NMEventDisplayWaveName( "OnsetY" )
	Wave PeakT = $NMEventDisplayWaveName( "PeakT" )
	Wave PeakY = $NMEventDisplayWaveName( "PeakY" )
	
	wNameT = NMEventTableWaveName( "ThreshT", rejections = rejections )
	
	if ( !WaveExists( $wNameT ) )
		Redimension /N=0 ThreshT, ThreshY, OnsetT, OnsetY, PeakT, PeakY
		return 0
	endif
	
	Wave waveN = $NMEventTableWaveName( "WaveN", rejections = rejections )
	
	Duplicate /O $wNameT, ThreshT
	Duplicate /O $NMEventTableWaveName( "ThreshY", rejections = rejections ) ThreshY
	Duplicate /O $NMEventTableWaveName( "OnsetT", rejections = rejections ) OnsetT
	Duplicate /O $NMEventTableWaveName( "OnsetY", rejections = rejections ) OnsetY
	Duplicate /O $NMEventTableWaveName( "PeakT", rejections = rejections ) PeakT
	Duplicate /O $NMEventTableWaveName( "PeakY", rejections = rejections ) PeakY
	
	if ( numpnts( waveN ) > 0 )
	
		MatrixOp /O EV_WaveSelectTemp = 1.0 * equal( waveN, currentWave )
		MatrixOp /O EV_WaveSelectTemp = EV_WaveSelectTemp / EV_WaveSelectTemp
	
		ThreshT *= EV_WaveSelectTemp
		ThreshY *= EV_WaveSelectTemp
		OnsetT *= EV_WaveSelectTemp
		OnsetY *= EV_WaveSelectTemp
		PeakT *= EV_WaveSelectTemp
		PeakY *= EV_WaveSelectTemp
		
		KillWaves /Z EV_WaveSelectTemp
	
	endif
	
	if ( clearCurrentEventDisplay )
		NMEventDisplayClearBTS()
		EventCursors( 0 )
	endif
	
	DoUpdate /W=$gName
	
	NMEventChanGraphControls( 1 )
	
End // UpdateEventDisplay

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventDisplayClearBTS()

	SetNMwave( NMEventDisplayWaveName( "BaseT" ), -1, Nan )
	SetNMwave( NMEventDisplayWaveName( "BaseY" ), -1, Nan )
	SetNMwave( NMEventDisplayWaveName( "ThisT" ), -1, Nan )
	SetNMwave( NMEventDisplayWaveName( "ThisY" ), -1, Nan )
	SetNMwave( NMEventDisplayWaveName( "SearchT" ), -1, Nan )
	SetNMwave( NMEventDisplayWaveName( "SearchY" ), -1, Nan )

End // NMEventDisplayClearBTS

//****************************************************************
//****************************************************************
//****************************************************************

Function EventCursors( enable ) // place cursors on onset and peak
	Variable enable // ( 0 ) remove ( 1 ) add
	
	Variable xbgn, xend
	
	Variable displayWin = NMEventVarGet( "DsplyWin" )
	Variable displayFraction = NMEventVarGet( "DsplyFraction" )
	Variable threshX = NMEventVarGet( "ThreshX" )
	Variable onsetX = NMEventVarGet( "OnsetX" )
	Variable peakX = NMEventVarGet( "PeakX" )
	
	Variable currentChan = CurrentNMChannel()
	
	String gName = ChanGraphName( currentChan )
	String dName = ChanDisplayWave( currentChan )
	String dNameShort = NMChild( dName )
	
	Variable tmid = threshX
	
	if ( enable  )
	
		if ( ( WinType( gName ) == 1 ) && ( DimSize( $dName, 2 ) != 3 ) )
	
			if ( numtype( onsetX ) == 0 )
				Cursor /W=$gName A, $dNameShort, onsetX
			else
				Cursor /K/W=$gName A
			endif
			
			if ( numtype( peakX ) == 0 )
				Cursor /W=$gName B, $dNameShort, peakX
			else
				Cursor /K/W=$gName B
			endif
			
			if ( ( numtype( tmid ) > 0 ) || ( tmid == 0 ) )
				tmid = leftx( $dname )
			endif
			
			xbgn = tmid - displayWin * displayFraction
			xend = tmid + displayWin * ( 1 - displayFraction )
			
			SetAxis /W=$gName bottom xbgn, xend
		
		endif
		
	else
	
		if ( WinType( gName ) == 1 )
	
			if ( strlen( CsrInfo( A, gName ) ) > 0 )
				Cursor /K/W=$gName A
			endif
			
			if ( strlen( CsrInfo( B, gName ) ) > 0 )
				Cursor /K/W=$gName B
			endif
		
		endif
		
	endif
	
	DoUpdate
	
End // EventCursors

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Tab Panel Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function MakeEventTab( force ) // create controls
	Variable force
	
	Variable x0, y0, yinc, fs = NMPanelFsize
	String df = NMEventDF
	
	ControlInfo /W=$NMPanelName EV_Grp1
	
	if ( ( V_Flag != 0 ) && !force )
		return 0 // Event tab controls exist
	endif
	
	if ( !DataFolderExists( df ) )
		return 0 // Event tab has not been initialized yet
	endif
	
	CheckNMEventVarGet( "SearchValue" )
	CheckNMEventVarGet( "DsplyWin" )
	CheckNMEventVarGet( "SearchTime" )
	CheckNMEventVarGet( "NumEvents" )

	DoWindow /F $NMPanelName
	
	x0 = 35
	y0 = NMPanelTabY + 55
	yinc = 21
	
	GroupBox EV_Grp1, title = "Settings", pos={x0-15,y0-25}, size={260,185}, fsize=fs
	
	PopupMenu EV_SearchMethod, pos={x0+120,y0}, bodywidth=170, mode=1, proc=NMEventPopupSearchMethod
	PopupMenu EV_SearchMethod, value ="", fsize=fs
	
	SetVariable EV_Threshold, title=" ", pos={x0+180,y0+0*yinc+2}, limits={-inf,inf,0}, size={50,20}
	SetVariable EV_Threshold, value=$( df+"SearchValue" ), proc=NMEventSetVariable, fsize=fs
	
	y0 += 8
	
	Checkbox EV_PosNeg, title="positive events", pos={x0,y0+1*yinc}, size={200,20}, value=1, proc=NMEventCheckBox, fsize=fs
	Checkbox EV_SearchLimits, title="search limits", pos={x0,y0+2*yinc}, size={200,20}, value=1, proc=NMEventCheckBox, fsize=fs
	Checkbox EV_SearchParams, title="baseline", pos={x0,y0+3*yinc}, size={200,20}, value=1, proc=NMEventCheckBox, fsize=fs
	Checkbox EV_OnsetOn, title="onset", pos={x0,y0+4*yinc}, size={200,20}, value=1, proc=NMEventCheckBox, fsize=fs
	Checkbox EV_PeakOn, title="peak", pos={x0,y0+5*yinc}, size={200,20}, value=1, proc=NMEventCheckBox, fsize=fs
	Checkbox EV_MatchOn, title="template matching", pos={x0,y0+6*yinc}, size={200,20}, value=0, proc=NMEventCheckBox, fsize=fs
	
	Button EV_Match, pos={x0+180,y0+ 6*yinc-2}, title="Match", size={50,20}, disable=1, proc=NMEventButton, fsize=fs
	
	y0 = 420
	yinc = 30
	
	GroupBox EV_Grp2, title = "Search >", pos={x0-15,y0-25}, size={260,175}, fsize=fs
	
	PopupMenu EV_TableMenu, value = "Table", bodywidth = 175, pos={x0+125, y0}, proc=NMEventPopupTable, fsize=fs
	
	SetVariable EV_NumEvents, title=":", pos={x0+185,y0+2}, limits={0,inf,0}, size={55,20}
	SetVariable EV_NumEvents, value=$( df+"NumEvents" ), frame=0, fsize=fs, noedit=0
	
	//SetVariable EV_DsplyWin, title="display win ", pos={x0,y0+1*yinc}, limits={0.1,inf,0}, size={175,20}
	//SetVariable EV_DsplyWin, format = "%.1f", value=$( df+"DsplyWin" ), proc=NMEventSetVariable, fsize=fs
	
	SetVariable EV_DsplyTime, title="x =", pos={x0+65,y0+1*yinc+1}, limits={0,inf,0}, size={80,20}
	SetVariable EV_DsplyTime, format = "%.1f", value=$( df+"SearchTime" ), proc=NMEventSetVariable, fsize=fs
	
	Button EV_Xbgn, pos={x0+45,y0+2*yinc}, title="<<", size={30,20}, proc=NMEventButtonSearch, fsize=(fs+2)
	Button EV_Last, pos={x0+85,y0+2*yinc}, title="<", size={25,20}, proc=NMEventButtonSearch, fsize=(fs+2)
	Button EV_Next, pos={x0+120,y0+2*yinc}, title=">", size={25,20}, proc=NMEventButtonSearch, fsize=(fs+2)
	Button EV_Xend, pos={x0+155,y0+2*yinc}, title=">>", size={30,20}, proc=NMEventButtonSearch, fsize=(fs+2)
	
	Button EV_Save, pos={x0+15,y0+3*yinc}, title="Save", size={95,20}, proc=NMEventButtonSearch, fsize=fs
	Button EV_Reject, pos={x0+120,y0+3*yinc}, title="Reject", size={95,20}, proc=NMEventButtonSearch, fsize=fs
	
	Button EV_Auto, pos={70,y0+4*yinc}, title="All Waves", size={110,20}, proc=NMEventButtonSearch, fsize=fs
	
	Checkbox EV_Review, title="review", pos={x0+160,y0+4*yinc+3}, size={200,20}, value=1, proc=NMEventCheckBox, fsize=fs
	
	y0 = 585
	
	Button EV_E2W, pos={x0,y0}, title="Events 2 Waves", size={110,20}, proc=NMEventButtonTable, fsize=fs
	Button EV_Histo, pos={x0+120,y0}, title="Histogram", size={110,20}, proc=NMEventButtonTable, fsize=fs
	
	UpdateEventTab()

End // MakeEventTab

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateEventTab() // update event tab display

	Variable md, dis, basedis, rejections
	String tableTitle
	
	String searchstr, onsetstr = "onset", peakstr = "peak", basestr = "baseline"
	String matchstr = "template matching", grp2str = "Search >", nextstr = "\K("+NMRedStr+")>"
	String posnegstr = "positive events"
	
	if ( NMVarGet( "ConfigsDisplay" ) > 0 )
		return 0
	endif
	
	Variable currentChan = CurrentNMChannel()
	
	CheckNMEventVariables()
	
	String tableSelect = CheckNMEventTableSelect()
	
	Variable positive = z_PositiveEvent()

	Variable searchMethod = NMEventVarGet( "SearchMethod" )
	Variable searchBgn = NMEventVarGet( "SearchBgn" )
	Variable searchEnd = NMEventVarGet( "SearchEnd" )
	Variable searchSkip = NMEventVarGet( "SearchSkip" )
	
	Variable matchFlag = NMEventVarGet( "MatchFlag" )
	Variable MatchTau1 = NMEventVarGet( "MatchTau1" )
	Variable matchTau2 = NMEventVarGet( "MatchTau2" )
	
	Variable onsetOn = NMEventVarGet( "OnsetOn" )
	Variable onsetAvg = NMEventVarGet( "OnsetWin" )
	Variable onsetNstdv = NMEventVarGet( "OnsetNstdv" )
	Variable onsetWin = NMEventVarGet( "OnsetLimit" )
	
	Variable peakOn = NMEventVarGet( "PeakOn" )
	Variable peakAvg = NMEventVarGet( "PeakWin" )
	Variable peakNstdv = NMEventVarGet( "PeakNstdv" )
	Variable peakWin = NMEventVarGet( "PeakLimit" )
	
	Variable baseWin = NMEventVarGet( "BaseWin" )
	Variable searchDT = NMEventVarGet( "SearchDT" )
	
	Variable reviewFlag = NMEventVarGet( "ReviewFlag" )
	
	String template = NMEventStrGet( "Template" )
	
	Variable xbgn = EventSearchBgn()
	Variable xend = EventSearchEnd()
	
	Variable bslnOn = NMEventBaselineOn()
	
	String searchMethodString = EventSearchMethodString()
	
	String xunits = "" // " ms"
	
	if ( matchFlag > 0 )
		onsetstr += " (auto)"
	endif
	
	if ( searchMethod <= 2 )
		basedis = 2
	endif
	
	if ( reviewFlag > 0 )
	
		grp2str = "Review"
		nextstr = "\K(0,0,0)>"
		dis = 2
		
		if ( reviewFlag == 2 )
			rejections = 1
		endif
		
	endif
	
	if ( !z_PositiveEvent() )
		posnegstr = "negative events"
	endif
	
	if ( ( numtype( searchBgn ) > 0 ) && ( numtype( searchEnd ) > 0 ) )
		searchstr = "search limits (" + num2str( searchBgn ) + ", " + num2str( searchEnd ) + ")"
	else
		searchstr = "search limits (" + num2str( searchBgn ) + ", " + num2str( searchEnd ) + xunits + ")"
	endif
	
	if ( bslnOn )
		basestr = "bsln win=" + num2str( baseWin ) + xunits + ", search win=" + num2str( searchDT ) + xunits + ", skip=" + num2istr( searchSkip ) + " pnts"
	endif
	
	if ( onsetOn && !matchFlag )
		onsetstr += ": win=" + num2str( onsetAvg ) + xunits + ", Nstdv=" + num2istr( onsetNstdv ) + ", xlimit=" + num2str( onsetWin ) + xunits
	endif
	
	if ( peakOn )
		peakstr += ": win=" + num2str( peakAvg ) + xunits + ", Nstdv=" + num2istr( peakNstdv ) + ", xlimit=" + num2str( peakWin ) + xunits
	endif
	
	if ( matchFlag == 1 )
		matchstr = "template (tau1=" + num2str( MatchTau1 ) + ", tau2=" + num2str( matchTau2 ) + ")"
	elseif ( matchFlag == 2 )
		matchstr = "template (tau1=" + num2str( MatchTau1 ) + ")"
	elseif ( matchFlag == 3 )
		matchstr = "template (" + template + ")"
	endif
	
	md = WhichListItem( searchMethodString, NMEventSearchMenu(), ";", 0, 0 ) + 1
	md = max( md, 1 )
	
	if ( strlen( searchMethodString ) == 0 )
		md = 1
	endif
	
	PopupMenu EV_SearchMethod, win=$NMPanelName, value=NMEventSearchMenu(), mode=( md )
	
	SetVariable EV_Threshold, win=$NMPanelName, title=" "
	
	Checkbox EV_PosNeg, win=$NMPanelName, value=1, title=posnegstr
	Checkbox EV_SearchLimits, win=$NMPanelName, value=z_SearchLimitsOn(), title=searchstr
	Checkbox EV_SearchParams, win=$NMPanelName, value=BinaryCheck( bslnOn ), title=basestr, disable=basedis
	Checkbox EV_OnsetOn, win=$NMPanelName, value=BinaryCheck( onsetOn ), title=onsetstr
	Checkbox EV_PeakOn, win=$NMPanelName, value=BinaryCheck( peakOn ), title=peakstr
	Checkbox EV_MatchOn, win=$NMPanelName, value=BinaryCheck( matchFlag ), title=matchstr
	
	Button EV_Match, win=$NMPanelName, disable=( !matchFlag )
	
	GroupBox EV_Grp2, win=$NMPanelName, title=grp2str
	
	md = WhichListItem( tableSelect, NMEventTableMenu(), ";", 0, 0 ) + 1
	md = max( md, 1 )
	
	if ( strlen( tableSelect ) == 0 )
		md = 1
	endif
	
	PopupMenu EV_TableMenu, win=$NMPanelName, value=NMEventTableMenu(), mode=( md )
	
	SetVariable EV_DsplyTime, win=$NMPanelName, limits={searchBgn,searchEnd,0}
	
	Button EV_Next, win=$NMPanelName, title=nextstr
	
	if ( reviewFlag == 1 )
		Button EV_Save, win=$NMPanelName, title = "Save", disable=2
		Button EV_Reject, win=$NMPanelName, title = "Reject"
	elseif ( reviewFlag == 2 )
		Button EV_Save, win=$NMPanelName, title = "Save as Success", disable=0
		Button EV_Reject, win=$NMPanelName, title = "Delete"
	else
		Button EV_Save, win=$NMPanelName, title = "Save", disable=0
		Button EV_Reject, win=$NMPanelName, title = "Reject"
	endif
	
	Button EV_Auto, win=$NMPanelName, disable=dis
	
	if ( reviewFlag == 1 )
		Checkbox EV_Review, win=$NMPanelName, title="Successes", value=1
	elseif ( reviewFlag == 2 )
		Checkbox EV_Review, win=$NMPanelName, title="\K("+NMRedStr+")" + "REJECTS", value=1
	else
		Checkbox EV_Review, win=$NMPanelName, title="review", value=0
	endif
	
	EventCount( updateDisplay = 1, rejections = rejections )
	
End // UpdateEventTab

//****************************************************************
//****************************************************************
//****************************************************************

Static Function z_SearchLimitsOn()
	
	if ( ( numtype( NMEventVarGet( "SearchBgn" ) ) == 1 ) && ( numtype( NMEventVarGet( "SearchEnd" )) == 1 ) )
		return 0
	else
		return 1
	endif

End // z_SearchLimitsOn

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventSearchMenu()

	Variable positive = z_PositiveEvent()
	Variable matchFlag = NMEventVarGet( "MatchFlag" )

	if ( NMEventVarGet( "MatchFlag" ) > 0 )
	
		if ( positive )
			return "level cross (+slope);"
		else
			return "level cross (-slope);"
		endif
		
	else
	
		if ( positive )
			return "threshold > baseline;Nstdv > baseline;level detection (+slope);"
		else
			return "threshold < baseline;Nstdv < baseline;level detection (-slope)"
		endif
		
	endif

End // NMEventSearchMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventTableMenu()
	
	String subfolder = CurrentNMEventSubfolder()
	
	if ( StringMatch( subfolder, GetDataFolder( 0 ) ) ==1 )
		subfolder = ""
	endif

	if ( NMEventTableOldExists() )
		return "Event Table;---;" + NMEventTableOldList( CurrentNMChannel() ) + "---;New;Clear;kill;"
	else
		if (NMEventVarGet( "UseSubfolders" ) && ( strlen( subfolder ) > 0 ) && DataFolderExists( subfolder ) )
			return "Event Table;---;" + CurrentNMEventTableSelect() + ";---;Clear;Delete Event Subfolder;"
		else
			return "Event Table;---;" + CurrentNMEventTableSelect() + ";---;Clear;"
		endif
	endif

End // EventTableMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventButton( ctrlName ) : ButtonControl
	String ctrlName
	
	String fxn = ReplaceString( "EV_", ctrlName, "" )
	
	EventCall( fxn, "" )
	
End // NMEventButton

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventButtonSearch( ctrlName ) : ButtonControl
	String ctrlName
	
	String fxn = ReplaceString( "EV_", ctrlName, "" )
	
	NMEventSearch( func = fxn )
	
End // NMEventButtonSearch

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventButtonTable( ctrlName ) : ButtonControl
	String ctrlName
	
	String fxn = ReplaceString( "EV_", ctrlName, "" )
	
	EventTableCall( fxn )
	
End // NMEventButtonTable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventSetVariable( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	String fxn = ReplaceString( "EV_", ctrlName, "" )
	
	EventCall( fxn, varStr )

End // NMEventSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventCheckBox( ctrlName, checked ) : CheckBoxControl
	String ctrlName
	Variable checked
	
	String fxn = ReplaceString( "EV_", ctrlName, "" )
	
	EventCall( fxn, num2istr( checked ) )

End // NMEventCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventPopupSearchMethod( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	String fxn = ReplaceString( "EV_", ctrlName, "" )
	
	Variable method = EventSearchMethodNumber( searchMethodStr = popStr )
	
	if ( numtype( method ) == 0 )
		EventCall( fxn, num2istr( method ) )
	else
		UpdateEventTab()
	endif
	
End // NMEventPopupSearchMethod

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventPopupTable( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	strswitch( popStr )
	
		case "Event Table":
		case "---":
			UpdateEventTab()
			break
		
		
		case "New":
		case "Clear":
		case "Kill":
			EventTableCall( popStr )
			break
			
		case "Delete Event Subfolder":
			z_NMEventSubfolderKillCall()
			break
			
		default:
			NMEventSet( tableSelect = popStr, history = 1 )
			
	endswitch
	
End // NMEventPopupTable

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Set Global Variables, Strings and Waves
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventSet( [ xbgn, xend, searchTime, searchMethod, searchMethodStr, searchLevel, searchThreshold, searchNstdv, templateMatching, matchLevel, baseWin, searchDT, searchSkip, OnsetOn, OnsetWin, OnsetNstdv, OnsetLimit, PeakOn, PeakWin, PeakNstdv, PeakLimit, displayWin, tableSelect, review, update, history ] )

	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all time
	Variable searchTime // current search time 
	
	Variable searchMethod // 1, 2, 3, 4, 5, 6 ( see searchMethodStr )
	String searchMethodStr // Level+, Level-, thresh+, thresh-, Nstdv+, Nstdv-, where ( + ) denotes positive events ( - ) denotes negative events
	
	Variable searchLevel // search value for Level+, Level-
	Variable searchThreshold // threshold value for thresh+, thresh-
	Variable searchNstdv // number of standard deviations for Nstdv+, Nstdv-
	
	Variable templateMatching // ( 0 ) no ( 1 ) yes
	Variable matchLevel // matching level
	
	Variable baseWin, searchDT, searchSkip
	Variable onsetOn, onsetWin, onsetNstdv, onsetLimit
	Variable peakOn, peakWin, peakNstdv, peakLimit
	
	Variable displayWin // change graph window size
	
	String tableSelect
	Variable review // ( 0 ) search mode ( 1 ) review events ( 2 ) review event rejections
	
	Variable update // allow updates to NM panels and graphs
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable updateTab, updateTable, updateDisplay
	String vlist = ""
	
	if ( !ParamIsDefault( xbgn ) )
	
		vlist = NMCmdNumOptional( "xbgn", xbgn, vlist )
		
		SetNMvar( NMEventDF + "SearchBgn", z_CheckXbgn( xbgn ) )
		
		updateTab = 1
		
	endif
	
	if ( !ParamIsDefault( xend ) )
	
		vlist = NMCmdNumOptional( "xend", xend, vlist )
		
		SetNMvar( NMEventDF + "SearchEnd", z_CheckXend( xend ) )
		
		updateTab = 1
		
	endif
	
	if ( !ParamIsDefault( searchTime ) )
	
		vlist = NMCmdNumOptional( "searchTime", searchTime, vlist )
		
		if ( numtype( searchTime ) == 0 )
			EventSearchTime( searchTime )
		else
			NM2Error( 10, "searchTime", num2str( searchTime ) )
		endif
		
	endif
	
	if ( !ParamIsDefault( searchMethod ) )
	
		vlist = NMCmdNumOptional( "searchMethod", searchMethod, vlist, integer = 1 )
		
		if ( ( numtype( searchMethod ) == 0 ) && ( searchMethod >= 0 ) && ( searchMethod < ItemsInList( NMEventSeachMethodList ) ) )
			SetNMvar( NMEventDF + "SearchMethod", searchMethod )
			updateTab = 1
		else
			NM2Error( 10, "searchMethod", num2str( searchMethod ) )
		endif
	
	endif
	
	if ( !ParamIsDefault( searchMethodStr ) )
	
		vlist = NMCmdStrOptional( "searchMethodStr", searchMethodStr, vlist )
		
		searchMethod = EventSearchMethodNumber( searchMethodStr = searchMethodStr )
		
		if ( ( numtype( searchMethod ) == 0 ) && ( searchMethod >= 0 ) && ( searchMethod < 1 + ItemsInList( NMEventSeachMethodList ) ) )
			SetNMvar( NMEventDF + "SearchMethod", searchMethod )
			updateTab = 1
		else
			NM2Error( 20, "searchMethodStr", searchMethodStr )
		endif
		
	endif
	
	if ( !ParamIsDefault( searchLevel ) )
	
		vlist = NMCmdNumOptional( "searchLevel", searchLevel, vlist )
	
		if ( numtype( searchLevel ) == 0 )
			SetNMvar( NMEventDF + "SearchLevel", searchLevel )
		else
			NM2Error( 10, "searchLevel", num2str( searchLevel ) )
		endif
	
	endif
	
	if ( !ParamIsDefault( searchThreshold ) )
	
		vlist = NMCmdNumOptional( "searchThreshold", searchThreshold, vlist )
		
		searchThreshold = abs( searchThreshold )
	
		if ( ( numtype( searchThreshold ) == 0 ) && ( searchThreshold > 0 ) )
			SetNMvar( NMEventDF + "SearchThreshold", searchThreshold )
		else
			NM2Error( 10, "searchThreshold", num2str( searchThreshold ) )
		endif
	
	endif
	
	if ( !ParamIsDefault( searchNstdv ) )
	
		vlist = NMCmdNumOptional( "searchNstdv",  searchNstdv, vlist )
		
		searchNstdv = abs( searchNstdv )
	
		if ( ( numtype( searchNstdv ) == 0 ) && ( searchNstdv > 0 ) )
			SetNMvar( NMEventDF + "SearchNstdv",  searchNstdv )
		else
			NM2Error( 10, "searchNstdv", num2str( searchNstdv ) )
		endif
	
	endif
	
	if ( !ParamIsDefault( templateMatching ) )
	
		vlist = NMCmdNumOptional( "templateMatching", templateMatching, vlist, integer = 1 )
	
		MatchTemplateOn( templateMatching, update = 0 )
		
		updateTab = 1
		
	endif
	
	if ( !ParamIsDefault( matchLevel ) )
	
		vlist = NMCmdNumOptional( "matchLevel", matchLevel, vlist )
	
		if ( numtype( matchLevel ) == 0 )
			SetNMvar( NMEventDF + "MatchLevel", matchLevel )
		else
			NM2Error( 10, "matchLevel", num2str( matchLevel ) )
		endif
		
	endif
	
	if ( !ParamIsDefault( baseWin ) )
	
		vlist = NMCmdNumOptional( "baseWin", baseWin, vlist )
		
		baseWin = abs( baseWin )
	
		if ( numtype( baseWin ) == 0 )
			SetNMvar( NMEventDF + "BaseWin", baseWin )
			updateTable = 1
			updateTab = 1
		else
			NM2Error( 10, "baseWin", num2str( baseWin ) )
		endif
		
	endif
	
	if ( !ParamIsDefault( searchDT ) )
	
		vlist = NMCmdNumOptional( "searchDT", searchDT, vlist )
	
		searchDT = abs( searchDT )
		
		if ( ( numtype( searchDT ) == 0 ) && ( searchDT > 0 ) )
			SetNMvar( NMEventDF + "SearchDT", searchDT )
			updateTable = 1
			updateTab = 1
		else
			NM2Error( 10, "searchDT", num2str( searchDT ) )
		endif
		
	endif
	
	if ( !ParamIsDefault( searchSkip ) )
	
		vlist = NMCmdNumOptional( "searchSkip", searchSkip, vlist )
		
		searchSkip = abs( round( searchSkip ) )
	
		if ( ( numtype( searchSkip ) == 0 ) && ( searchSkip > 0 ) )
			SetNMvar( NMEventDF + "SearchSkip", searchSkip )
			updateTable = 1
			updateTab = 1
		else
			NM2Error( 10, "searchSkip", num2str( searchSkip ) )
		endif
		
	endif
	
	if ( !ParamIsDefault( onsetOn ) )
	
		vlist = NMCmdNumOptional( "OnsetOn", onsetOn, vlist, integer = 1 )
	
		SetNMvar( NMEventDF + "OnsetOn", BinaryCheck( onsetOn ) )
		
		updateTable = 1
		updateTab = 1
	
	endif
	
	if ( !ParamIsDefault( onsetWin ) )
	
		vlist = NMCmdNumOptional( "OnsetWin", onsetWin, vlist )
		
		onsetWin = abs( onsetWin )
		
		if ( ( numtype( onsetWin ) == 0 ) && ( onsetWin > 0 ) )
			SetNMvar( NMEventDF + "OnsetWin",  onsetWin )
			updateTable = 1
			updateTab = 1
		else
			NM2Error( 10, "onsetWin", num2str( onsetWin ) )
		endif
		
	endif
	
	if ( !ParamIsDefault( onsetNstdv ) )
	
		vlist = NMCmdNumOptional( "OnsetNstdv", onsetNstdv, vlist )
		
		onsetNstdv = abs( onsetNstdv )
	
		if ( ( numtype( onsetNstdv ) == 0 ) && ( onsetNstdv > 0 ) )
			SetNMvar( NMEventDF + "OnsetNstdv",  onsetNstdv )
			updateTable = 1
			updateTab = 1
		else
			NM2Error( 10, "onsetNstdv", num2str( onsetNstdv ) )
		endif
		
	endif
	
	if ( !ParamIsDefault( onsetLimit ) )
	
		vlist = NMCmdNumOptional( "OnsetLimit", onsetLimit, vlist )
		
		onsetLimit = abs( onsetLimit )
	
		if ( ( numtype( onsetLimit ) == 0 ) && ( onsetLimit > 0 ) )
			SetNMvar( NMEventDF + "OnsetLimit",  onsetLimit )
			updateTable = 1
			updateTab = 1
		else
			NM2Error( 10, "onsetLimit", num2str( onsetLimit ) )
		endif
	
	endif
	
	if ( !ParamIsDefault( peakOn ) )
	
		vlist = NMCmdNumOptional( "PeakOn", peakOn, vlist, integer = 1 )
	
		SetNMvar( NMEventDF + "PeakOn", BinaryCheck( peakOn ) )
		
		updateTable = 1
		updateTab = 1
	
	endif
	
	if ( !ParamIsDefault( peakWin ) )
	
		vlist = NMCmdNumOptional( "PeakWin", peakWin, vlist )
		
		peakWin = abs( peakWin )
		
		if ( ( numtype( peakWin ) == 0 ) && ( peakWin > 0 ) )
			SetNMvar( NMEventDF + "PeakWin",  peakWin )
			updateTable = 1
			updateTab = 1
		else
			NM2Error( 10, "peakWin", num2str( peakWin ) )
		endif
	
	endif
	
	if ( !ParamIsDefault( peakNstdv ) )
	
		vlist = NMCmdNumOptional( "PeakNstdv", peakNstdv, vlist )
	
		peakNstdv = abs( peakNstdv )
		
		if ( ( numtype( peakNstdv ) == 0 ) && ( peakNstdv > 0 ) )
			SetNMvar( NMEventDF + "PeakNstdv",  peakNstdv )
			updateTable = 1
			updateTab = 1
		else
			NM2Error( 10, "peakNstdv", num2str( peakNstdv ) )
		endif
		
	endif
	
	if ( !ParamIsDefault( peakLimit ) )
	
		vlist = NMCmdNumOptional( "PeakLimit", peakLimit, vlist )
	
		peakLimit = abs( peakLimit )
		
		if ( ( numtype( peakLimit ) == 0 ) && ( peakLimit > 0 ) )
			SetNMvar( NMEventDF + "PeakLimit",  peakLimit )
			updateTable = 1
			updateTab = 1
		else
			NM2Error( 10, "peakLimit", num2str( peakLimit ) )
		endif
	
	endif
	
	if ( !ParamIsDefault( displayWin ) )
	
		vlist = NMCmdNumOptional( "displayWin", displayWin, vlist )
		
		displayWin = abs( displayWin )
	
		if ( ( numtype( displayWin ) == 0 ) && ( displayWin > 0 ) )
			SetNMvar( NMEventDF + "DsplyWin", displayWin )
			EventCursors( 1 )
		else
			NM2Error( 10, "displayWin", num2str( displayWin ) )
		endif
	
	endif
	
	if ( !ParamIsDefault( tableSelect ) )
	
		vlist = NMCmdStrOptional( "tableSelect", tableSelect, vlist )
		
		NMEventTableSelect( tableSelect, update = 0 )
		
		updateDisplay = 1
		updateTab = 1
		
	endif
	
	if ( !ParamIsDefault( review ) )
	
		vlist = NMCmdNumOptional( "review", review, vlist, integer = 1 )
		
		if ( ( review < 0 ) || ( review > 2 ) )
			review = 0
		endif
	
		SetNMvar( NMEventDF + "ReviewFlag", review )
	
		updateTab = 1
		updateDisplay = 1
	
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( update && updateDisplay )
		UpdateEventDisplay( clearCurrentEventDisplay = 1 )
	endif
	
	if ( update && updateTable )
		NMEventTableManager( "", "update" )
	endif
	
	if ( update && updateTab )
		UpdateEventTab()
	endif
	
End // NMEventSet

//****************************************************************
//****************************************************************
//****************************************************************

Function EventCall( fxn, select )
	String fxn, select
	
	Variable snum = str2num( select )
	
	strswitch( fxn )
	
		case "SearchMethod":
			return EventSearchMethodCall( snum )
	
		case "Threshold":
			return EventThresholdCall( snum )
			
		case "PosNeg":
			return z_PositiveEventToggleCall()
	
		case "SearchLimits":
			return EventSearchWindowCall( snum )
	
		case "SearchParams":
			return NMEventSearchParamsCall()
			
		case "OnsetOn":
			return EventOnsetCall( snum )
			
		case "PeakOn":
			return EventPeakCall( snum )
			
		case "MatchOn":
			return NMEventSet( templateMatching = snum, history = 1 )
			
		case "Match":
			MatchTemplateCall( 1 )
			EventDisplay( 1 )
			break
			
		case "DsplyWin":
			return NMEventSet( displayWin = snum, history = 1 )
			
		case "DsplyTime":
			return NMEventSet( searchTime = snum, history = 1 )
			
		case "Review":
			NMEventReviewCall( snum )
			break
			
		default:
			NMDoAlert( "EventCall: unrecognized function call: " + fxn, title=AlertTitle )
	
	endswitch
	
End // EventCall

//****************************************************************
//****************************************************************
//****************************************************************

Static Function z_PositiveEventToggleCall()
	
	Variable positiveEvents = BinaryInvert( z_PositiveEvent() )
	Variable searchMethod = z_PositiveEventToggle( positiveEvents )
	
	return EventSearchMethodCall( searchMethod )
	
End // z_PositiveEventToggleCall

//****************************************************************
//****************************************************************
//****************************************************************

Static Function z_PositiveEventToggle( positiveEvents )
	Variable positiveEvents // ( 0 ) negative events ( 1 ) positive events
	
	Variable searchMethod = NMEventVarGet( "SearchMethod" )
	
	if ( BinaryCheck( positiveEvents ) )
	
		switch( searchMethod )
	
			case 1: // level detection (+slope)
			case 2: // level detection (-slope)
				return 1
				
			case 3: // threshold > baseline
			case 4: // threshold < baseline
				return 3
				
			case 5: // Nstdv > baseline
			case 6: // Nstdv < baseline
				return 5
		
		endswitch
	
	else
	
		switch( searchMethod )
	
			case 1: // level detection (+slope)
			case 2: // level detection (-slope)
				return 2
				
			case 3: // threshold > baseline
			case 4: // threshold < baseline
				return 4
				
			case 5: // Nstdv > baseline
			case 6: // Nstdv < baseline
				return 6
		
		endswitch
	
	endif
	
	return NaN
	
End // z_PositiveEventToggle

//****************************************************************
//****************************************************************
//****************************************************************

Static Function z_PositiveEvent()

	switch( NMEventVarGet( "SearchMethod" ) )
	
		case 1: // level detection (+slope)
			return 1
		case 2: // level detection (-slope)
			return 0
		case 3: // threshold > baseline
			return 1
		case 4: // threshold < baseline
			return 0
		case 5: // Nstdv > baseline
			return 1
		case 6: // Nstdv < baseline
			return 0
	endswitch

End // z_PositiveEvent

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSearchMethodCall( searchMethod )
	Variable searchMethod
	
	Variable yvalue
	
	Variable matchFlag = NMEventVarGet( "MatchFlag" )
	
	String searchMethodStr = EventSearchMethodString( methodNum = searchMethod, short = 1 )
	
	if ( matchFlag )
	
		yvalue = NMEventVarGet( "MatchLevel" )
		
		return NMEventSet( searchMethodStr = searchMethodStr, matchLevel = yvalue, history = 1 )
		
	else
	
		switch( searchMethod )
		
			case 1: // level detection (+slope)
			case 2: // level detection (-slope)
				
				yvalue = NMEventVarGet( "SearchLevel" )
		
				if ( numtype( yvalue ) > 0 )
				
					if ( searchMethod == 1 )
						yvalue = abs( SearchLevel )
					else
						yvalue = -1 * abs( SearchLevel )
					endif
					
				endif
				
				return NMEventSet( searchMethodStr = searchMethodStr, searchLevel = yvalue, history = 1 )
				
			case 3: // threshold > baseline
			case 4: // threshold < baseline
			
				yvalue = NMEventVarGet( "SearchThreshold" )
				
				if ( numtype( yvalue ) > 0 )
					yvalue = SearchThreshold
				endif
			
				return NMEventSet( searchMethodStr = searchMethodStr, searchThreshold = yvalue, history = 1 )
				
			case 5: // Nstdv > baseline
			case 6: // Nstdv < baseline
			
				yvalue = NMEventVarGet( "SearchNstdv" )
				
				if ( numtype( yvalue ) > 0 )
					yvalue = SearchNstdv
				endif
				
				return NMEventSet( searchMethodStr = searchMethodStr, searchNstdv = yvalue, history = 1 )
				
		endswitch
	
	endif
	
	return NaN
	
End // EventSearchMethodCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S EventSearchMethodString( [ methodNum, short ] )
	Variable methodNum
	Variable short
	
	if ( ParamIsDefault( methodNum ) )
		methodNum = NMEventVarGet( "SearchMethod" )
	endif
	
	if ( ParamIsDefault( short ) )
		short = 0
	endif
	
	if ( short )
		return StringFromList( methodNum - 1, NMEventSeachMethodListShort )
	else
		return StringFromList( methodNum - 1, NMEventSeachMethodList )
	endif

End // EventSearchMethodString

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSearchMethodNumber( [ searchMethodStr ] )
	String searchMethodStr
	
	if ( ParamIsDefault( searchMethodStr ) )
		searchMethodStr = EventSearchMethodString()
	endif
	
	Variable methodNum = WhichListItem( searchMethodStr, NMEventSeachMethodList )
	
	if ( methodNum >= 0 )
		return methodNum + 1
	endif
	
	methodNum = WhichListItem( searchMethodStr, NMEventSeachMethodListShort )
	
	if ( methodNum >= 0 )
		return methodNum + 1
	endif
	
	return NaN
	
End // EventSearchMethodNumber

//****************************************************************
//****************************************************************
//****************************************************************

Function EventThresholdCall( threshOrLevel )
	Variable threshOrLevel
	
	Variable searchMethod = NMEventVarGet( "SearchMethod" )
	Variable matchFlag = NMEventVarGet( "MatchFlag" )
	
	if ( numtype( threshOrLevel ) > 0 )
		return NM2Error( 10, "threshOrLevel", num2str( threshOrLevel ) )
	endif
	
	if ( MatchFlag )
	
		switch( searchMethod )
		
			case 1:
			case 2:
				NMEventSet( matchLevel = threshOrLevel, history = 1 )
				break
				
			default:
				return NM2Error( 10, "searchMethod", num2str( searchMethod ) )
				
		endswitch

	else
	
		switch( searchMethod )
		
			case 1: // level+
			case 2: // level-
				NMEventSet( searchLevel = threshOrLevel, history = 1 )
				break
				
			case 3: // thresh+
			case 4: // thresh-
				NMEventSet( searchThreshold = threshOrLevel, history = 1 )
				break
				
			case 5: // Nstdv+
			case 6: // Nstdv-
				NMEventSet( searchNstdv = threshOrLevel, history = 1 )
				break
				
			default:
				return NM2Error( 10, "searchMethod", num2str( searchMethod ) )
		
		endswitch
	
	endif
	
	return threshOrLevel
	
End // EventThresholdCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventThresholdLevel( [ searchMethod ] )
	Variable searchMethod

	Variable v

	Variable positive = z_PositiveEvent()
	Variable matchFlag = NMEventVarGet( "MatchFlag" )
	
	if ( ParamIsDefault( searchMethod ) )
		searchMethod = NMEventVarGet( "SearchMethod" )
	endif
	
	String dName = ChanDisplayWave( -1 )
	
	if ( MatchFlag )
	
		switch( searchMethod )
		
			case 1:
			case 2:
			
				v = NMEventVarGet( "MatchLevel" )
				
				if ( numtype( v )== 0 )
					return v
				endif
				
			default:
			
				if ( positive )
					return 4
				else
					return -4
				endif
		
		endswitch
		
	else
	
		switch( searchMethod )
		
			case 1: // level+
			case 2: // level-
			
				v = NMEventVarGet( "SearchLevel" )
				
				if ( ( numtype( v ) > 0 ) && WaveExists( $dName ) )
				
					WaveStats /Q $dName
					
					if ( positive )
						v = V_avg + 0.5 * abs( V_avg - V_max )
					else
						v = V_avg - 0.5 * abs( V_avg - V_min )
					endif
					
					if ( abs( v ) > 1 )
						v = floor( v )
					endif
				
				endif
				
				return v
				
			case 3: // thresh+
			case 4: // thresh-
			
				v = abs( NMEventVarGet( "SearchThreshold" ) )
				
				if ( numtype( v ) == 0 )
					return v
				else
					return SearchThreshold
				endif
				
			case 5: // Nstdv+
			case 6: // Nstdv-
			
				v = abs( NMEventVarGet( "SearchNstdv" ) )
			
				if ( numtype( v ) == 0 )
					return v
				else
					return SearchNstdv
				endif
		
		endswitch
	
	endif
	
	return 10

End // NMEventThresholdLevel

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSearchWindowCall( on )
	Variable on

	String dName = ChanDisplayWave( -1 )
	
	Variable xbgn = NMEventVarGet( "SearchBgn" )
	Variable xend = NMEventVarGet( "SearchEnd" )
	
	if ( on )
	
		if ( ( numtype( xbgn ) > 0 ) && WaveExists( $dName ) )
			xbgn = leftx( $dName )
		endif
		
		if ( ( numtype( xend ) > 0 ) && WaveExists( $dName ) )
			xend = rightx( $dName )
		endif
		
		if ( numtype( xbgn ) > 0 )
			xbgn = -inf
		endif
		
		if ( numtype( xend ) > 0 )
			xend = inf
		endif
		
		Prompt xbgn, NMPromptAddUnitsX( "x-axis limit search begin" )
		Prompt xend, NMPromptAddUnitsX( "x-axis limit search end" )
		DoPrompt "Event Search or Review", xbgn, xend
		
		if ( V_flag == 1 )
			UpdateEventTab()
			return 0
		endif
		
	else
	
		xbgn = -inf
		xend = inf
	
	endif
	
	return NMEventSet( xbgn = xbgn, xend = xend, history = 1 )

End // EventSearchWindowCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventSearchParamsCall()
	
	Variable baseWin = NMEventVarGet( "BaseWin" )
	Variable searchDT = NMEventVarGet( "SearchDT" )
	Variable searchSkip = NMEventVarGet( "SearchSkip" )
	
	Prompt baseWin, NMPromptAddUnitsX( "x-axis baseline window" )
	Prompt searchDT, NMPromptAddUnitsX( "search window, starting from mid-baseline point" )
	Prompt searchSkip, "points to advance (skip) when searching for next event (>):"
	DoPrompt "Event Search Parameters", baseWin, searchDT, searchSkip
		
	if ( V_flag == 1 )
		UpdateEventTab()
		return 0 // cancel
	endif
	
	return NMEventSet( baseWin = baseWin, searchDT = searchDT, searchSkip = searchSkip, history = 1 )
	
End // NMEventSearchParamsCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventOnsetCall( onsetOn )
	Variable onsetOn
	
	Variable onsetWin, onsetNstdv, onsetLimit
	
	Variable matchFlag = NMEventVarGet( "MatchFlag" )
	
	if ( onsetOn && !matchFlag )
			
		onsetWin = NMEventVarGet( "OnsetWin" )
		onsetNstdv = NMEventVarGet( "OnsetNstdv" )
		onsetLimit = NMEventVarGet( "OnsetLimit" )
		
		Prompt onsetWin, NMPromptAddUnitsX( "sliding average window" )
		Prompt onsetNstdv, "number of STDV above/below avg win:"
		Prompt onsetLimit, NMPromptAddUnitsX( "search window limit" )
		DoPrompt "Onset Search", onsetWin, onsetNstdv, onsetLimit
		
		if ( V_flag == 1 )
			onsetOn = 0
			onsetWin = Nan
			onsetNstdv = Nan
			onsetLimit = Nan
		endif
		
		return NMEventSet( onsetOn = onsetOn, onsetWin = onsetWin, onsetNstdv = onsetNstdv, onsetLimit = onsetLimit, history = 1 )
		
	else
	
		return NMEventSet( onsetOn = 0, history = 1 )
		
	endif

End // EventOnsetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventPeakCall( peakOn )
	Variable peakOn
	
	Variable peakWin, peakNstdv, peakLimit
	
	if ( peakOn )
			
		peakWin = NMEventVarGet( "PeakWin" )
		peakNstdv = NMEventVarGet( "PeakNstdv" )
		peakLimit = NMEventVarGet( "PeakLimit" )
		
		Prompt peakWin, NMPromptAddUnitsX( "sliding average window" )
		Prompt peakNstdv, "number of STDV above/below avg win:"
		Prompt peakLimit, NMPromptAddUnitsX( "search window limit" )
		DoPrompt "Peak Time Search", peakWin, peakNstdv, peakLimit
		
		if ( V_flag == 1 )
			peakOn = 0
			peakWin = Nan
			peakNstdv = Nan
			peakLimit = Nan
		endif
		
		return NMEventSet( peakOn = peakOn, peakWin = peakWin, peakNstdv = peakNstdv, peakLimit = peakLimit, history = 1 )
		
	else
	
		return NMEventSet( peakOn = 0, history = 1 )
		
	endif
	
End // EventPeakCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSearchTime( searchTime ) // set current search time
	Variable searchTime // current time
	
	Variable lx = -inf, rx = inf
	
	String dName = ChanDisplayWave( -1 )
	
	Variable xbgn = EventSearchBgn()
	Variable xend = EventSearchEnd()
	
	if ( numtype( searchTime ) == 2 )
		searchTime = xbgn
	endif
	
	if ( WaveExists( $dName ) )
		lx = leftx( $dName )
		rx = rightx( $dName )
	endif
	
	searchTime = max( searchTime, lx )
	searchTime = min( searchTime, rx )
	
	SetNMvar( NMEventDF + "SearchTime", searchTime )
	
	SetNMvar( NMEventDF + "ThreshX", searchTime )
	SetNMvar( NMEventDF + "ThreshY", Nan )
	
	SetNMvar( NMEventDF + "OnsetX", searchTime )
	SetNMvar( NMEventDF + "OnsetY", Nan )
	SetNMvar( NMEventDF + "PeakX", searchTime )
	SetNMvar( NMEventDF + "PeakY", Nan )
	
	SetNMvar( NMEventDF + "FoundEventFlag", 0 )
	
	NMEventDisplayClearBTS()
	EventCursors( 1 )
	SetNMvar( NMEventDF+"DsplyWinSlider2", searchTime )
	
	return searchTime
	
End // EventSearchTime

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventReviewCall( on )
	Variable on
	
	Variable successes, rejections
	
	if ( on )
	
		successes = EventCount()
		rejections = EventCount( rejections = 1 )
		
		if ( ( successes == 0 ) && ( rejections == 0 ) )
		
			NMDoAlert( "There are no saved events to review", title = "NM Review" )
			on = 0
		
		elseif ( ( successes > 0 ) && ( rejections == 0 ) )
		
			on = 1
			
		elseif ( ( successes == 0 ) && ( rejections > 0 ) )
		
			on = 2
		
		else
		
			Prompt on, "review event", popup "successes;rejections;"
			DoPrompt "Event Search Review", on
			
			if ( V_flag == 1 )
				on = 0
			endif

		endif
	
	endif
	
	return NMEventSet( review = on, history = 1 )

End // NMEventReviewCall

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Template Matching Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Static Function z_MatchTemplateXOPAlert()

	String txt = "To use template matching you need to install the MatchTemplate XOP. "
	
	txt += "Download the XOP from www.neuromatic.thinkrandom.com/NMInstall.html "
	txt += "and place it in the Igor Extensions folder."
		
	NMDoAlert( txt, title = "Download Match Template XOP Alert" )
	NMHistory( txt )

End // z_MatchTemplateXOPAlert

//****************************************************************
//****************************************************************
//****************************************************************

Function MatchTemplateOn( on [ update ] )
	Variable on // ( 0 ) off ( 1 ) on
	Variable update
	
	Variable searchMethod, level
	
	Variable positive = z_PositiveEvent()
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( on )
	
		if ( exists( "MatchTemplate" ) != 4 )
			z_MatchTemplateXOPAlert()
			on = 0
		endif
	
		if ( on )
			on = MatchTemplateSelect()
		endif
		
		if ( on > 0 )
		
			if ( positive )
				SetNMvar( NMEventDF + "SearchMethod", 1 )
			else
				SetNMvar( NMEventDF + "SearchMethod", 2 )
			endif
			
			SetNMvar( NMEventDF + "PeakOn", 0 )
		
			//MatchTemplateCall( 0 )
			NMDoAlert( "Select Match button to match your template waveform to the current data wave.", title=AlertTitle )
			
		endif
		
	else
	
		MatchTemplateKill()
		on = 0
		
	endif
	
	SetNMvar( NMEventDF + "MatchFlag", on )
	
	EventDisplay( 1 )
	
	if ( update )
		UpdateEventTab()
	endif
	
	return on
	
End // MatchTemplateOn

//****************************************************************
//****************************************************************
//****************************************************************

Function MatchTemplateSelect()

	Variable wcnt, fxn, tau1, tau2, bslnTime, waveformTime, dx
	String tname, wList, wList2 = "", wName

	Prompt fxn, "select template:", popup "2-Exp;Alpha Function;Your Wave;"
	DoPrompt "Template Matching Search", fxn
	
	if ( V_flag == 1 )
		return 0
	endif
	
	tau1 = NMEventVarGet( "MatchTau1" )
	tau2 = NMEventVarGet( "MatchTau2" )
	bslnTime = NMEventVarGet( "MatchBsln" )
	waveformTime = NMEventVarGet( "MatchWform" )
	
	tname = NMEventStrGet( "Template" )
	
	if ( numtype( bslnTime ) > 0 )
		bslnTime = NMEventVarGet( "BaseWin" )
	endif
	
	Prompt tau1, NMPromptAddUnitsX( "rise time" )
	Prompt tau2, NMPromptAddUnitsX( "decay time" )
	Prompt bslnTime, NMPromptAddUnitsX( "extra zero-baseline time before waveform" )
	Prompt waveformTime, NMPromptAddUnitsX( "total template waveform time" )
	
	switch( fxn )
	
		case 1:
		
			DoPrompt "Create 2-Exp Template", tau1, tau2, bslnTime, waveformTime
			
			if ( V_flag == 1 )
				return 0 // cancel
			endif
			
			SetNMvar( NMEventDF + "MatchTau1", tau1 )
			SetNMvar( NMEventDF + "MatchTau2", tau2 )
			SetNMvar( NMEventDF + "MatchBsln", bslnTime )
			SetNMvar( NMEventDF + "MatchWform", waveformTime )
			break
		
		case 2:
	
			Prompt tau1, NMPromptAddUnitsX( "tau" )
			DoPrompt "Create Alpha-Function Template", tau1, bslnTime, waveformTime
			
			if ( V_flag == 1 )
				return 0 // cancel
			endif
			
			tau2 = 0
			SetNMvar( NMEventDF + "MatchTau1", tau1 )
			SetNMvar( NMEventDF + "MatchBsln", bslnTime )
			SetNMvar( NMEventDF + "MatchWform", waveformTime )
			break
		
		case 3:
	
			bslnTime = 0
			
			dx = deltax( $ChanDisplayWave( -1 ) )
			
			wList = WaveList( "*", ";", "Text:0" )
			
			for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
			
				wName = StringFromList( wcnt, wList )
				
				if ( deltax( $wName ) == dx )
					wList2 += wName + ";"
				endif
				
			endfor
			
			Prompt tname, "select your pre-defined template wave:", popup wList2
			Prompt bslnTime, NMPromptAddUnitsX( "zero-baseline length of your pre-defined template wave" )
			DoPrompt "Template Matching Search", tname, bslnTime
			
			if ( V_flag == 1 )
				return 0 // cancel
			endif
			
			SetNMvar( NMEventDF + "MatchBsln", bslnTime )
			
			WaveStats /Q/Z $tname
			
			if ( V_max > 1 )
				NMDoAlert( "Your template waveform should be normalized to one and have zero baseline.", title=AlertTitle )
			endif
			
			break
		
	endswitch
	
	if ( ( fxn == 1 ) || ( fxn == 2 ) )
	
		dx = deltax( $ChanDisplayWave( -1 ) )
		
		tname = MatchTemplateMake( fxn, tau1, tau2, bslnTime, waveformTime, dx, history = 1 )
		
	endif
	
	if ( strlen( tname ) > 0 )
		SetNMvar( NMEventDF + "MatchFlag", fxn )
		SetNMstr( NMEventDF + "Template", tname )
	endif
	
	return fxn

End // MatchTemplateSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S MatchTemplateMake( fxn, tau1, tau2, bslnTime, waveformTime, dx [ history ] )
	Variable fxn // ( 1 ) 2-exp ( 2 ) alpha
	Variable tau1 // first exp time constant, or alpha
	Variable tau2 // second exp time constant
	Variable bslnTime // baseline time
	Variable waveformTime // waveform time
	Variable dx // x-axis delta
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable pnt
	String gName, gTitle, vlist = ""
	
	if ( history )
		vlist = NMCmdNum( fxn, vlist, integer = 1 )
		vlist = NMCmdNum( tau1, vlist )
		vlist = NMCmdNum( tau2, vlist )
		vlist = NMCmdNum( bslnTime, vlist )
		vlist = NMCmdNum( waveformTime, vlist )
		vlist = NMCmdNum( dx, vlist )
		NMCommandHistory( vlist )
	endif
	
	if ( ( numtype( tau1 ) > 0 ) || ( tau1 <= 0 ) )
		return NM2ErrorStr( 10, "tau1", num2str( tau1 ) )
	endif
	
	if ( fxn == 1 )
		if ( ( numtype( tau2 ) > 0 ) || ( tau2 <= 0 ) )
			return NM2ErrorStr( 10, "tau2", num2str( tau2 ) )
		endif
	endif
	
	if ( ( numtype( bslnTime ) > 0 ) || ( bslnTime < 0 ) )
		return NM2ErrorStr( 10, "bslnTime", num2str( bslnTime ) )
	endif
	
	if ( ( numtype( waveformTime ) > 0 ) || ( waveformTime <= 0 ) )
		return NM2ErrorStr( 10, "waveformTime", num2str( waveformTime ) )
	endif
	
	if ( ( numtype( dx ) > 0 ) || ( dx <= 0 ) )
		return NM2ErrorStr( 10, "dx", num2str( dx ) )
	endif

	String wName = NMEventDF + "TemplateWave"
	
	Make /D/O/N=( ( bslnTime + waveformTime ) / dx ) $wName
	SetScale /P x, 0, dx, $wName
	
	Wave pulse = $wName
	
	if ( fxn == 2 ) // alpha
		pulse = ( x - bslnTime ) * exp( ( bslnTime - x ) / tau1 )
	else // 2-exp
		pulse = ( 1 - exp( ( bslnTime - x ) / tau1 ) ) * exp( ( ( bslnTime - x ) ) / tau2 )
	endif
	
	pnt = x2pnt( pulse, bslnTime )
	
	if ( ( pnt >= 0 ) && ( pnt < numpnts( pulse ) ) )
		pulse[ 0, pnt ] = 0
	endif
	
	Wavestats /Q/Z pulse
	pulse /= v_max
	
	if ( NMVarGet( "GraphsAndTablesOn" ) )
		gName = "EV_Tmplate"
		gTitle = "Event Template"
		NMGraph( wList = wName, gName = gName, gTitle = gTitle, xLabel = NMXunits, yLabel = "" )
	endif
	
	NMHistory( "Created Template Wave " + NMQuotes( wName ) )

	return wName

End // MatchTemplateMake

//****************************************************************
//****************************************************************
//****************************************************************

Function MatchTemplateCall( force )
	Variable force
	
	Variable matchFlag = NMEventVarGet( "MatchFlag" )
	
	String templateName = NMEventStrGet( "Template" )
	
	String wName = CurrentNMWaveName()
	String tname = "EV_" + wName + "_matched"
	String mtname = NMEventDisplayWaveName( "MatchTmplt" )
	
	if ( !matchFlag || !WaveExists( $wName ) )
		return 0
	endif
	
	if ( !force )
	
		if ( WaveExists( $tname ) )
			Duplicate /O $tname $mtname
			return 0
		endif
		
		//DoAlert 2, "Match template to " + NMQuotes( wName ) + "? ( This may take a few minutes... )"
		
		//if ( V_Flag != 1 )
		//	if ( WaveExists( $mtname ) )
		//		Wave temp = $mtname
		//		temp = Nan
		//	endif
		//	return 0
		//endif
		
	endif

	MatchTemplateCompute( wName, templateName, history = 1 )
	
	Duplicate /O $mtname $tname

End // MatchTemplateCall

//****************************************************************
//****************************************************************
//****************************************************************

Function MatchTemplateKill()
	Variable icnt

	String wName, wlist = WaveList( "*_matched",";","" )
	
	for ( icnt = 0; icnt < ItemsInList( wlist ); icnt += 1 )
		wName = StringFromList( icnt, wlist )
		KillWaves /Z $wName
	endfor

End // MatchTemplateKill

//****************************************************************
//****************************************************************
//****************************************************************

Function MatchTemplateCompute( wName, templateName [ history ] ) // match template to wave
	String wName // wave name
	String templateName // template name
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	String title, oName, vlist = ""
	
	if ( history )
		vlist = NMCmdStr( wName, vlist )
		vlist = NMCmdStr( templateName, vlist )
		NMCommandHistory( vlist )
	endif
	
	if ( !WaveExists( $wName ) )
		return NM2Error( 1, "wName", wName )
	endif
	
	if ( !WaveExists( $templateName ) )
		return NM2Error( 1, "templateName", templateName )
	endif
	
	if ( round( deltax( $wName ) * 1000) != round( deltax( $templateName ) * 1000 ) )
		return NM2Error( 90, "template wave delta-x does not match that of wave to measure: " + num2str(1.0/deltax( $wName )) + " vs " + num2str(1.0/deltax( $templateName )), "" )
	endif
	
	if ( numtype( sum( $templateName, -inf, inf ) ) > 0 )
	
		title = "NM Compute Match Template"
	
		DoAlert /T=title 2, "template wave contains not-a-numbers (NANs). Do you want NM to replace them with zeroes?"
		
		if ( V_flag != 1 )
			return -1
		endif
		
		NMReplaceValue( Nan, 0, templateName )
		
	endif
	
	NMProgressCall( -1, "Matching Template..." )
	DoUpdate
	
	oName = NMEventDisplayWaveName( "MatchTmplt" )
	
	Duplicate /O $wName $oName
	
	Execute /Z "MatchTemplate /C " + templateName + " " + oName
	
	if ( V_flag != 0 )
	
		Execute /Z "MatchTemplate /C " + templateName + ", " + oName // NEW FORMAT
		
		if ( V_flag != 0 )
			NM2Error( 90, "MatchTemplate XOP execution error", "" )
		endif
		
	endif
	
	NMProgressKill()
	
	if ( V_flag > 0 )
		NMDoAlert( "Encounter Match Template XOP error.", title=AlertTitle )
	endif
	
End // MatchTemplateCompute

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Event Search Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventSearch( [ func, history ] )
	String func // "Next" or "Last" or "Save" or "Reject" or "xbgn" or "xend"
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable xbgn
	String vlist = ""
	
	if ( ParamIsDefault( func ) )
		func = "Next"
	else
		vlist = NMCmdStrOptional( "func", func, vlist )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	Variable reviewFlag = NMEventVarGet( "ReviewFlag" )
	
	if ( NMExecutionAlert() )
		return -1
	endif

	strswitch( func )
	
		case "Next":
		
			if ( reviewFlag > 0 )
				EventRetrieveNextCall()
			else
				EventFindNextCall()
			endif
			
			break
			
		case "Last":
			EventRetrieveLastCall()
			break
			
		case "Save":
			EventSaveCall()
			break
			
		case "Reject":
		case "Delete":
			//EventDeleteCall( alert = 1 )
			EventDeleteCall()
			break
		
		case "All":
		case "Auto":
			if ( reviewFlag == 0 )
				EventFindAllCall()
			endif
			break
			
		case "Xbgn":
			NMEventAdvanceCall( -1 )
			break
			
		case "Xend":
			NMEventAdvanceCall( 1 )
			break
			
		default:
			NM2Error( 20, "func", func )
			
	endswitch
	
	Dowindow /F $NMPanelName
	
End // NMEventSearch

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventAdvanceCall( direction )
	Variable direction // -1 or +1

	Variable autoAdvance, wNum

	Variable searchTime = NMEventVarGet( "SearchTime" )
	Variable xbgn = EventSearchBgn()
	Variable xend = EventSearchEnd()

	if ( direction < 0 )
	
		if ( searchTime > xbgn )
			return NMEventSet( searchTime = xbgn, history = 1 )
		endif
		
	elseif ( direction > 0 )
	
		if ( searchTime < xend )
			return NMEventSet( searchTime = xend, history = 1 )
		endif
	
	else
		
		return -1
			
	endif
	
	if ( NMEventVarGet( "ReviewFlag" ) > 0 )
		autoAdvance = NMEventVarGet( "ReviewWaveAdvance" )
	else
		autoAdvance = NMEventVarGet( "SearchWaveAdvance" )
	endif
	
	if ( !autoAdvance )
		return 0
	endif
	
	if ( direction < 0 )
	
		wNum = CurrentNMWave() - 1
		
		if ( wNum >= 0 )
			NMCurrentWaveSet( wNum )
		endif
	
	else
	
		wNum = CurrentNMWave() + 1
		
		if ( wNum < NMNumWaves() )
			NMCurrentWaveSet( wNum )
		endif
	
	endif

End // NMEventAdvanceCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventRetrieveNextCall()

	Variable next, alert, waveNum
	
	Variable numWaves = NMNumWaves()
	Variable currentChan = CurrentNMChannel()
	Variable currentWave = CurrentNMWave()
	
	Variable searchTime = NMEventVarGet( "SearchTime" )
	Variable auto = NMEventVarGet( "ReviewWaveAdvance" )
	
	Variable rejections = NMEventRejectsOn()
	
	next = EventRetrieveNext( currentWave, searchTime, rejections = rejections )
			
	if ( auto && ( next < 0 ) )
	
		waveNum = EventRetrieveNextWaveNum( currentWave, rejections = rejections )
		
		if ( ( waveNum >= 0 ) && ( waveNum < numWaves ) )
		
			NMCurrentWaveSet( waveNum )
			next = EventRetrieveNext( waveNum, -inf, rejections = rejections )
			
			if ( next < 0 )
				alert = 1
			endif
			
		else
		
			alert = 1
			
		endif
			
	endif
	
	if ( NMVarGet( "AlertUser" ) && NMEventVarGet( "AlertsOn" ) && alert )
		NMDoAlert( "There are no more saved events.", title=AlertTitle )
	endif
	
	return next
				
End // EventRetrieveNextCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventRetrieveLastCall()

	variable last, alert, waveNum
	
	Variable numWaves = NMNumWaves()
	Variable currentChan = CurrentNMChannel()
	Variable currentWave = CurrentNMWave()
	
	Variable searchTime = NMEventVarGet( "SearchTime" )
	Variable auto = NMEventVarGet( "ReviewWaveAdvance" )
	
	Variable rejections = NMEventRejectsOn()
	
	last = EventRetrieveLast( currentWave, searchTime, rejections = rejections )
	
	if ( auto && ( last < 0 ) )
				
		waveNum = EventRetrieveLastWaveNum( currentWave, rejections = rejections )
			
		if ( ( waveNum >= 0 ) && ( waveNum < numWaves ) )
		
			NMCurrentWaveSet( waveNum )
			last = EventRetrieveLast( waveNum, inf, rejections = rejections )
			
			if ( last < 0 )
				alert = 1
			endif
			
		else
		
			alert = 1
			
		endif
		
	endif
	
	if ( NMVarGet( "AlertUser" ) && NMEventVarGet( "AlertsOn" ) && alert )
		NMDoAlert( "There are no more saved events.", title=AlertTitle )
	endif

	return last
	
End // EventRetrieveLastCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventFindNextCall()

	Variable next, alert, waveNum, pflag
	
	Variable numWaves = NMNumWaves()
	Variable currentChan = CurrentNMChannel()
	
	Variable auto = NMEventVarGet( "SearchWaveAdvance" )
	Variable saveRejected = NMEventVarGet( "SaveRejected" )
	
	do
	
		next = EventFindNext( 1 )
		
		if ( next <= 0 )
			break // found event or finished search
		elseif ( saveRejected )
			pflag = EventSaveCurrent( 0, rejections = 1, noAlert = 1 )
		endif
	
	while ( 1 )

	if ( next == -1 )
				
		if ( auto )
		
			waveNum = EventFindNextActiveWave( currentChan, CurrentNMWave() )
			
			if ( ( waveNum >= 0 ) && ( waveNum < numWaves ) )
			
				NMCurrentWaveSet( waveNum )
				EventSearchTime( EventSearchBgn() )
				
				do
	
					next = EventFindNext( 1 )
		
					if ( next <= 0 )
						break // found event or finished search
					elseif ( saveRejected )
						pflag = EventSaveCurrent( 0, rejections = 1, noAlert = 1 )
					endif
	
				while ( 1 )
				
				if ( next == -1 )
					//alert = 1
				endif
				
			else
			
				alert = 1
				
			endif
			
		else
			
			alert = 1
			
		endif
		
	endif
	
	if ( NMVarGet( "AlertUser" ) && NMEventVarGet( "AlertsOn" ) && alert )
		
		NMDoAlert( "Found no more events in " + CurrentNMWaveName() + ".", title=AlertTitle )
		
		waveNum = EventFindNextActiveWave( currentChan, -1 )
		
		if ( waveNum < 0 )
			NMEventReviewAlert()
		endif
		
	endif
	
	return next

End // EventFindNextCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventReviewAlert()

	if ( NMVarGet( "AlertUser" ) && NMEventVarGet( "AlertsOn" ) && NMEventVarGet( "ReviewAlert" ) )
	
		if ( !NumVarOrDefault( NMEventDF+"ReviewAlertFinished", 0 ) )
		
			NMDoAlert( "To review the current event detection results, click the " + NMQuotes( "review" ) + " checkbox.", title=AlertTitle )
		
			SetNMvar( NMEventDF+"ReviewAlertFinished", 1 ) // alert once
		
		endif
		
	endif
	
End // NMEventReviewAlert

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventAuto() // called when user changes CurrentWave
	
	Variable currentChan = CurrentNMChannel()
	Variable currentWave = CurrentNMWave()
	
	Variable eventChan = NumVarOrDefault( NMEventDF + "CurrentChan", 0 )
	Variable eventWave = NumVarOrDefault( NMEventDF + "CurrentWave", 0 )
	
	if ( ( eventChan != currentChan ) || ( eventWave != currentWave ) )
		EventSearchTime( NMEventVarGet( "SearchBgn" ) )
		SetNMvar( NMEventDF + "CurrentChan", currentChan )
		SetNMvar( NMEventDF + "CurrentWave", currentWave )
	endif
	
	UpdateEventDisplay()
	//MatchTemplateCall( 0 )

End // NMEventAuto

//****************************************************************
//****************************************************************
//****************************************************************

Function EventFindAllCall()

	Variable waveSelect = 1

	String wlist = NMWaveSelectList( CurrentNMChannel() )
	Variable nwaves = ItemsInList( wlist )
	
	Variable tableNum = NMEventTableOldNum()

	Variable tselect = NMEventVarGet( "AutoTSelect" )
	Variable tzero = 1+ NMEventVarGet( "AutoTZero" )
	Variable displayResults = 1 + NMEventVarGet( "AutoDsply" )
	
	if ( EventCount() == 0 )
		tselect = 2 // current table
	endif
	
	Prompt tselect, "save events where?", popup "new table;current table;"
	Prompt tzero, "search from time zero?", popup "no;yes;"
	Prompt displayResults, "display results while detecting?", popup "no;yes;"
	
	if ( tableNum == -1 )
	
		DoPrompt "Auto Event Detection", tzero, displayResults
		
		if ( V_flag == 1 )
			return 0 // cancel
		endif
	
	else
	
		DoPrompt "Auto Event Detection", tselect, tzero, displayResults
		
		if ( V_flag == 1 )
			return 0 // cancel
		endif
		
		SetNMvar( NMEventDF + "AutoTSelect", tselect )
	
	endif
	
	tzero -= 1
	displayResults -= 1
	
	SetNMvar( NMEventDF + "AutoTZero", tzero )
	SetNMvar( NMEventDF + "AutoDsply", displayResults )
	
	if ( tselect == 0 )
		NMEventTableNew()
	endif
	
	if ( tzero )
		EventSearchTime( EventSearchBgn() )
	endif
	
	return EventFindAll( waveSelect, displayResults, history = 1 )

End // EventFindAllCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventFindAll( waveSelect, displayResults [ history ] ) // find events until end of trace
	Variable waveSelect // ( 0 ) current wave ( 1 ) all waves
	Variable displayResults // ( 0 ) no ( 1 ) yes, update display
	Variable history // print function command to history ( 0 ) no ( 1 ) yes

	Variable pflag, next
	Variable wcnt, ecnt, events
	String wName, setName, vlist = ""
	
	if ( history )
		vlist = NMCmdNum( waveSelect, vlist, integer = 1 )
		vlist = NMCmdNum( displayResults, vlist, integer = 1 )
		NMCommandHistory( vlist )
	endif
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	Variable currentChan = CurrentNMChannel()
	Variable currentWave = CurrentNMWave()
	
	Variable tableNum = NMEventTableOldNum()
	
	Variable searchTime = NMEventVarGet( "SearchTime" )
	Variable saveRejected = NMEventVarGet( "SaveRejected" )
	
	Wave ThreshT = $NMEventDisplayWaveName( "ThreshT" )
	
	Variable wbgn = currentWave
	Variable wend = currentWave
	Variable savewave = currentWave
	Variable savetime = searchTime
	
	String tableName = CurrentNMEventTableName()

	if ( strlen( tableName ) == 0 )
		NMEventTableNew()
	endif
	
	if ( waveSelect == 1 )
		wbgn = 0
		wend = NMNumWaves() - 1
	endif
	
	DoWindow /F $ChanGraphName( currentChan )
	
	//Print ""
	//Print "Auto event detection for Ch " + ChanNum2Char( chan ) + " saved in Table " + num2istr( tableNum )
	
	SetNMstr( NMDF+"ProgressStr", "Detecting Events..." )

	for ( wcnt = wbgn; wcnt <= wend; wcnt += 1 ) // loop thru waves
	
		if ( ( waveSelect == 0 ) || ( ( waveSelect == 1 ) && NMWaveIsSelected( currentChan, wcnt ) ) )
		
			if ( NMProgressCall( -1, "Detecting Events..." ) == 1 )
				break
			endif
		
			if ( ( waveSelect == 1 ) && ( wcnt != currentWave ) ) // all waves
				currentWave = wcnt
				NMCurrentWaveSet( wcnt )
				MatchTemplateCall( 0 )
				UpdateEventDisplay()
			endif
			
			ecnt = 0
			
			do
			
				if ( NMProgressCall( -2, "Detecting Events... n=" + num2istr(ecnt) ) == 1 )
					break
				endif
				
				next = EventFindNext( displayResults )
				
				if ( next >= 0 )
				
					if ( next == 0 )
						pflag = EventSaveCurrent( 0 )
					elseif ( saveRejected )
						pflag = EventSaveCurrent( 0, rejections = 1 )
					endif
				
					if ( pflag == -3 )
						break // user cancel
					endif
					
					ecnt += 1
					
				else
				
					break // no more events
					
				endif
				
			while ( 1 )
			
			if ( pflag == -3 )
				break // cancel search
			endif
			
			Print "Located " + num2istr( ecnt ) + " event(s) in wave " + CurrentNMWaveName()
			
		endif
	
	endfor
	
	NMProgressKill()
	
	NMHistoryOutputWaves( subfolder = CurrentNMEventSubfolder() )
	
	if ( currentWave != saveWave )
		NMCurrentWaveSet( saveWave )
	endif
	
	EventSearchTime( savetime )
	
	UpdateEventTab()
	NMEventReviewAlert()
	
	DoWindow /F $tableName

End // EventFindAll

//****************************************************************
//****************************************************************
//****************************************************************

Function EventFindNext( displayResults [ xbgn, xend, eventFlag ] ) // find next event
	Variable displayResults // ( 0 ) no ( 1 ) yes, update display
	Variable xbgn, xend
	Variable eventFlag
	
	Variable wbgn, wend, nstdv, posneg = -1, successFlag, pnt, by, t2
	Variable jlimit = 100000 // should be large number
	Variable xbgnLimit, xendLimit, dx
	
	//Variable first = 1 // dead parameter, removed 30 Apr 2019
	
	Variable currentChan = CurrentNMChannel()
	Variable currentWave = CurrentNMWave()
	
	if ( !NMWaveIsSelected( currentChan, currentWave ) )
		NMDoAlert( "Event Find Next Abort: the current wave is not selected for analysis.", title=AlertTitle )
		NMWaveSelectStr()
		return -2
	endif
	
	Variable searchMethod = NMEventVarGet( "SearchMethod" )
	Variable searchTime = NMEventVarGet( "SearchTime" )
	Variable threshLevel = NMEventVarGet( "SearchValue" )
	Variable searchSkip = NMEventVarGet( "SearchSkip" )
	
	Variable onsetOn = NMEventVarGet( "OnsetOn" )
	Variable onsetAvg = NMEventVarGet( "OnsetWin" )
	Variable onsetNstdv = NMEventVarGet( "OnsetNstdv" )
	Variable onsetWin = NMEventVarGet( "OnsetLimit" )
	
	Variable peakOn = NMEventVarGet( "PeakOn" )
	Variable peakAvg = NMEventVarGet( "PeakWin" )
	Variable peakNstdv = NMEventVarGet( "PeakNstdv" )
	Variable peakWin = NMEventVarGet( "PeakLimit" )
	
	Variable matchFlag = NMEventVarGet( "MatchFlag" )
	Variable matchBsln = NMEventVarGet( "MatchBsln" )
	
	Variable threshX = NMEventVarGet( "ThreshX" )
	Variable threshY = NMEventVarGet( "ThreshY" )
	Variable onsetX = NMEventVarGet( "OnsetX" )
	Variable onsetY = NMEventVarGet( "OnsetY" )
	Variable peakX = NMEventVarGet( "PeakX" )
	Variable peakY = NMEventVarGet( "PeakY" )
	
	Variable searchDT = NMEventVarGet( "SearchDT" )
	Variable baseWin = NMEventVarGet( "BaseWin" )
	
	//Variable eventFlag = NMEventVarGet( "FoundEventFlag" )
	
	Variable bslnOn = NMEventBaselineOn()
	
	Wave ThreshT = $NMEventDisplayWaveName( "ThreshT" )
	Wave BaseT = $NMEventDisplayWaveName( "BaseT" )
	Wave BaseY = $NMEventDisplayWaveName( "BaseY" )
	Wave ThisT = $NMEventDisplayWaveName( "ThisT" )
	Wave ThisY = $NMEventDisplayWaveName( "ThisY" )
	Wave SearchT = $NMEventDisplayWaveName( "SearchT" )
	Wave SearchY = $NMEventDisplayWaveName( "SearchY" )
	
	String dName = ChanDisplayWave( currentChan )
	
	if ( !WaveExists( $dName ) )
		return -2
	endif
	
	Wave eWave = $dName
	
	String wName2 = dName
	
	if ( matchFlag > 0 )
		wName2 = NMEventDisplayWaveName( "MatchTmplt" )
	endif
	
	dx = deltax( $dName )
	
	by = NaN
	BaseY = Nan
	threshY = threshLevel
	
	if ( ParamIsDefault( eventFlag ) )
		eventFlag = NMEventVarGet( "FoundEventFlag" )
	endif
	
	xbgnLimit = EventSearchBgn()
	xendLimit = EventSearchEnd()
	
	if ( ParamIsDefault( xbgn ) )
	
		if ( numtype( searchTime ) == 0 )
			xbgn = searchTime
		else
			xbgn = xbgnLimit
		endif
	
	endif
	
	if ( ParamIsDefault( xend ) )
		xend = xendLimit
	endif
	
	xbgn = max( xbgn, xbgnLimit )
	xend = min( xend, xendLimit )
	
	searchSkip = max( searchSkip, 1 ) // advance at least 1 pnt
	
	if ( matchFlag > 0 )
	
		if ( peakOn && ( numtype( peakX ) == 0 ) )
			xbgn = peakX + dx
		elseif ( numtype( onsetX ) == 0 )
			xbgn = onsetX + dx
		endif
		
	else
	
		switch( eventFlag )
		
			case 0: // no current events
				// do nothing
				break
				
			case 1: // there is a detected event but it is not saved
			
				if ( numtype( threshX ) == 0 )
					xbgn = threshX - searchDT + 5 * dx // advance 5 points
				endif
			
				break
				
			case 2: // there is a current event and it is saved
			
				if ( peakOn && ( numtype( peakX ) == 0 ) )
					//xbgn = peakX + dx
					xbgn = peakX + searchSkip * dx
				elseif ( numtype( threshX ) == 0 ) 
					//xbgn = threshX + dx
					xbgn = threshX + searchSkip * dx
				endif
			
				break
		
		endswitch
		
	endif
		
	xbgn = max( xbgn, xbgnLimit )
	
	switch( searchMethod )
	
		case 1: // Level+
		
			FindLevel /EDGE=1/Q/R=( xbgn, xend ) $wName2, threshLevel
			
			if ( V_flag == 0 )
				threshX = V_LevelX
			else
				threshX = NaN
			endif
			
			posneg = 1
			break
			
		case 2: // Level-
		
			FindLevel /EDGE=2/Q/R=( xbgn, xend ) $wName2, threshLevel
			
			if ( V_flag == 0 )
				threshX = V_LevelX
			else
				threshX = NaN
			endif

			break
			
		case 3: // thresh > baseline
			posneg = 1
			threshX = NMEventFindNext( wName2, xbgn, xend, baseWin/dx, searchDT/dx, 0, threshLevel )
			break
			
		case 4: // thresh < baseline
			threshX = NMEventFindNext( wName2, xbgn, xend, baseWin/dx, searchDT/dx, 1, threshLevel )
			break
			
		case 5: // Nstdv > baseline
			posneg = 1
			threshX = NMEventFindNext( wName2, xbgn, xend, baseWin/dx, searchDT/dx, 2, threshLevel )
			break
			
		case 6: // // Nstdv < baseline
			threshX = NMEventFindNext( wName2, xbgn, xend, baseWin/dx, searchDT/dx, 3, threshLevel )
			break
			
	endswitch
	
	if ( numtype( threshX ) > 0 ) // no event found
		return -1
	endif
		
	Wave eWave2 = $wName2
	
	pnt = x2pnt( eWave2, threshX )
	
	if ( ( pnt >= 0 ) && ( pnt < numpnts( eWave2 ) ) )
		threshY = eWave2[ pnt ]
	endif
		
	// find onsets and peaks

	if ( matchFlag > 0 )
	
		t2 = NaN
	
		if ( searchMethod == 1 )
		
			FindLevel /EDGE=2/Q/R=( threshX, xend ) $wName2, threshLevel
			
			if ( V_flag == 0 )
				t2 = V_LevelX
			endif
			
		elseif ( searchMethod == 2 )
		
			FindLevel /EDGE=1/Q/R=( threshX, xend ) $wName2, threshLevel
			
			if ( V_flag == 0 )
				t2 = V_LevelX
			endif
			
		endif
		
		if ( numtype( t2 ) > 0 )
			t2 = threshX + onsetWin
		endif
		
		// have negative and positive level crossings
		// now mind min location beween the two points
	
		//WaveStats /Q/Z/R=( threshX, threshX+peakWin ) $wName2 // window is too large
		WaveStats /Q/Z/R=( threshX, t2 ) $wName2
		
		if ( searchMethod == 1 )
			onsetX = V_maxloc + matchBsln
		elseif ( searchMethod == 2 )
			onsetX = V_minloc + matchBsln
		else
			onsetX = Nan
		endif
		
		pnt = x2pnt( eWave, onsetX )
		
		if ( ( pnt >= 0 ) && ( pnt < numpnts( eWave ) ) )
			onsetY = eWave[ pnt ]
		endif

		if ( peakOn )
		
			peakX = NMFindPeak( dName, onsetX, onsetX+peakWin, floor( peakAvg/dx ), peakNstdv, posneg )
			
			pnt = x2pnt( eWave, peakX )
			
			if ( ( pnt >= 0 ) && ( pnt < numpnts( eWave ) ) )
				peakY = eWave[ pnt ]
			endif
			
		else
			peakX = Nan
			peakY = Nan
		endif
		
	else
	
		if ( onsetOn ) // search backward from ThreshX
		
			onsetX = NMFindOnset( dName, threshX-onsetWin, threshX, floor( onsetAvg/dx ), onsetNstdv, posneg, -1 )
			
			pnt = x2pnt( eWave, onsetX )
			
			if ( ( pnt >= 0 ) && ( pnt < numpnts( eWave ) ) )
				onsetY = eWave[ pnt ]
			endif
			
		else
		
			onsetX = Nan
			onsetY = Nan
			
		endif
		
		if ( peakOn )
		
			peakX = NMFindPeak( dName, threshX, threshX+peakWin, floor( peakAvg/dx ), peakNstdv, posneg )
			
			pnt = x2pnt( eWave, peakX )
			
			if ( ( pnt >= 0 ) && ( pnt < numpnts( eWave ) ) )
				peakY = eWave[ pnt ]
			endif
			
		else
		
			peakX = Nan
			peakY = Nan
			
		endif
		
	endif
		
	if ( searchMethod > 2 )
		xbgn = threshX - searchDT
	else
		xbgn = threshX + dx
	endif
	
	successFlag = 0

	if ( onsetOn && ( numtype( onsetX ) > 0 ) )
		successFlag += 1 // failed onset detection
	endif
	
	if ( peakOn && ( numtype( peakX ) > 0 ) )
		successFlag += 1 // failed peak detection
	endif
	
	if ( bslnOn ) // compute baseline display
	
		wbgn = threshX - searchDT - baseWin/2
		wend = threshX - searchDT + baseWin/2
		
		WaveStats /Q/Z/R=( wbgn,wend ) $dName
		
		if ( numpnts( BaseT ) == 2 )
			BaseT[ 0 ] = wbgn
			BaseT[ 1 ] = wend
		endif
		
		BaseY = V_avg
		by = V_avg
		
		if ( numpnts( SearchT ) == 3 )
			SearchT[ 0 ] = ( wbgn + wend ) / 2
			SearchT[ 1 ] = ( wbgn + wend ) / 2
			SearchY[ 0 ] = V_avg
		endif
		
	endif
	
	if ( numpnts( ThisT ) == 1 )
		ThisT[ 0 ] = threshX
		ThisY[ 0 ] = threshY
	endif
	
	if ( numpnts( SearchT ) == 3 )
		SearchT[ 2 ] = threshX
		SearchY[ 1 ] = threshY
		SearchY[ 2 ] = threshY
	endif
	
	SetNMvar( NMEventDF + "SearchTime", threshX )
	SetNMvar( NMEventDF + "ThreshX", threshX )
	SetNMvar( NMEventDF + "ThreshY", threshY )
	
	SetNMvar( NMEventDF + "OnsetX", onsetX )
	SetNMvar( NMEventDF + "OnsetY", onsetY )
	SetNMvar( NMEventDF + "PeakX", peakX )
	SetNMvar( NMEventDF + "PeakY", peakY )
	
	SetNMvar( NMEventDF + "BaseY", by )
	
	SetNMvar( NMEventDF + "FoundEventFlag", 1 )
	
	//EventFindSaved( NMEventTableWaveName( "WaveN" ), NMEventDisplayWaveName( "ThreshT" ), threshX, 0.01, currentWave )
	
	if ( displayResults )
		EventCursors( 1 )
	endif
	
	return successFlag

End // EventFindNext

//****************************************************************
//****************************************************************
//****************************************************************

Function EventFindNextActiveWave( chanNum, currentWave )
	Variable chanNum
	Variable currentWave
	
	Variable wcnt
	
	chanNum = ChanNumCheck( chanNum )
	
	if ( ( numtype( currentWave ) > 0 ) || ( currentWave < 0 ) )
		currentWave = CurrentNMWave()
	endif
	
	for ( wcnt = currentWave + 1 ; wcnt < NMNumWaves() ; wcnt += 1 )
		if ( NMWaveIsSelected( chanNum, wcnt ) )
			return wcnt
		endif
	endfor
	
	return -1
	
End // EventFindNextActiveWave

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventFindNext( wName, xbgn, xend, bslnPnts, deltaPnts, searchMethod, threshOrNstdv )
	String wName // wave name
	Variable xbgn, xend // x-axis search limits, ( -inf / inf ) for all possible time
	Variable bslnPnts // baseline average points
	Variable deltaPnts // points between mid-baseline and threshold crossing point
	Variable searchMethod // ( 0 ) threshold > baseline ( 1 ) threshold < baseline ( 2 ) Nstdv > baseline ( 3 ) Nstdv < baseline
	Variable threshOrNstdv // threshold level value or Nstdv
	
	Variable icnt, ibgn, iend, level, xpnt, avg, stdv, posneg
	
	Variable slope = NMEventVarGet( "SearchSlope" )
	
	if ( !WaveExists( $wName ) )
		NM2Error( 1, "wName", wName )
		return Nan
	endif
	
	if ( numtype( xbgn ) > 0 )
		xbgn = -inf
	endif
	
	if ( numtype( xend ) > 0 )
		xend = inf
	endif
	
	if ( ( numtype( bslnPnts ) > 0 ) || ( bslnPnts < 0 ) )
		NM2Error( 10, "bslnPnts", num2istr( bslnPnts ) )
		return Nan
	endif
	
	if ( ( searchMethod == 2 ) || ( searchMethod == 3 ) )
	
		if ( bslnPnts == 0 )
			NM2Error( 10, "bslnPnts", num2istr( bslnPnts ) )
			return Nan
		endif
	
	endif
	
	if ( ( numtype( deltaPnts ) > 0 ) || ( deltaPnts <= 0 ) )
		NM2Error( 10, "deltaPnts", num2istr( deltaPnts ) )
		return Nan
	endif
	
	if ( numtype( threshOrNstdv ) > 0 )
		NM2Error( 10, "threshOrNstdv", num2str( threshOrNstdv ) )
		return Nan
	endif
	
	Wave eWave = $wName
	
	Variable dx = deltax( eWave )
	Variable lx = leftx( eWave )
	Variable rx = rightx( eWave )
	
	ibgn = x2pnt( eWave, xbgn )
	ibgn = max( ibgn, 0 )
	
	if ( slope )
		iend = x2pnt( eWave, xend ) - deltaPnts - 1
	else
		iend = x2pnt( eWave, xend ) - deltaPnts
	endif
	
	if ( bslnPnts > 0 )
		iend = min( iend, numpnts( eWave ) - bslnPnts/2 )
	else
		iend = min( iend, numpnts( eWave ) )
	endif

	// search forward from xbgn until right-most data point falls above ( below ) threshold value
	
	for ( icnt = ibgn; icnt < iend; icnt+=1 )
	
		if ( bslnPnts > 0 )
			if ( icnt + bslnPnts/2 >= numpnts( eWave ) )
				return NaN
			endif
			WaveStats /Q/Z/R=[ icnt - bslnPnts/2, icnt + bslnPnts/2 ] eWave
			avg = V_avg
			stdv = V_sdev
		else
			avg = eWave[ icnt ]
		endif
		
		if ( numtype( avg ) > 0 )
			continue
		endif
		
		switch( searchMethod )
		
			case 0: // threshold > baseline
				level = avg + abs( threshOrNstdv )
				posneg = 1
				break
				
			case 1: // threshold < baseline
				level = avg - abs( threshOrNstdv )
				posneg = -1
				break
				
			case 2: // threshold > Nstdv
				level = avg + abs( threshOrNstdv ) * stdv
				posneg = 1
				break
				
			case 3: // threshold < Nstdv
				level = avg - abs( threshOrNstdv ) * stdv
				posneg = -1
				break
				
			default:
				return NaN

		endswitch
		
		xpnt = icnt + deltaPnts
		
		if ( xpnt >= numpnts( eWave ) )
			return NaN
		endif
		
		if ( ( posneg > 0 ) && ( eWave[ xpnt ] >= level ) )
		
			if ( slope )
			
				if ( ( eWave[ xpnt - 1 ] < eWave[ xpnt ] ) && ( eWave[ xpnt ] < eWave[ xpnt + 1 ] ) )
					return pnt2x( eWave, xpnt )
				endif
			
			else
			
				return pnt2x( eWave, xpnt )
				
			endif
			
		elseif ( ( posneg < 0 ) && ( eWave[ xpnt ] <= level ) )
		
			if ( slope )
			
				if ( ( eWave[ xpnt - 1 ] > eWave[ xpnt ] ) && ( eWave[ xpnt ] > eWave[ xpnt + 1 ] ) )
					return pnt2x( eWave, xpnt )
				endif
			
			else
			
				return pnt2x( eWave, xpnt )
				
			endif
			
		endif
		
	endfor
	
	return Nan

End // NMEventFindNext

//****************************************************************
//****************************************************************
//****************************************************************

Function EventRetrieveNext( waveNum, currentTime [ rejections ] )
	Variable waveNum
	Variable currentTime
	Variable rejections // event rejections
	
	Variable ecnt, ebgn, t
	String wname
	
	Variable xbgn = NMEventVarGet( "SearchBgn" )
	Variable xend = NMEventVarGet( "SearchEnd" )
	
	if ( ( numtype( waveNum ) > 0 ) || ( waveNum < 0 ) )
		waveNum = CurrentNMWave()
	endif
	
	if ( ( numtype( currentTime ) > 0 ) || ( currentTime < 0 ) )
		currentTime = NMEventVarGet( "ThreshX" )
	endif
	
	wname = NMEventTableWaveName( "ThreshT", rejections = rejections )
	
	if ( !WaveExists( $wname ) )
		NMDoAlert( "No events to retrieve.", title=AlertTitle )
		return 0
	endif
	
	Wave threshT = $wname
	Wave waveN = $NMEventTableWaveName( "WaveN", rejections = rejections )
	
	for ( ecnt = ebgn ; ecnt < numpnts( waveN ) ; ecnt += 1 )
		
		if ( waveN[ ecnt ] != waveNum )
			continue
		endif
		
		t = threshT[ ecnt ]
		
		if ( t > currentTime )
			EventRetrieve( ecnt, rejections = rejections )
			return ecnt
		endif
	
	endfor
	
	return -1
	
End // EventRetrieveNext

//****************************************************************
//****************************************************************
//****************************************************************

Function EventRetrieveLast( waveNum, currentTime [ rejections ] )
	Variable waveNum
	Variable currentTime
	Variable rejections // event rejections
	
	Variable ecnt, ebgn, t
	String wname
	
	Variable xbgn = NMEventVarGet( "SearchBgn" )
	Variable xend = NMEventVarGet( "SearchEnd" )
	
	if ( ( numtype( waveNum ) > 0 ) || ( waveNum < 0 ) )
		waveNum = CurrentNMWave()
	endif
	
	if ( numtype( currentTime ) == 2 )
		return -1
	endif
	
	wname = NMEventTableWaveName( "ThreshT", rejections = rejections )
	
	if ( !WaveExists( $wname ) )
		NMDoAlert( "No events to retrieve.", title=AlertTitle )
		return 0
	endif
	
	Wave threshT = $wname
	Wave waveN = $NMEventTableWaveName( "WaveN", rejections = rejections )
	
	ebgn = numpnts( waveN ) - 1
	
	for ( ecnt = ebgn ; ecnt >= 0 ; ecnt -= 1 )
		
		if ( waveN[ ecnt ] != waveNum )
			continue
		endif
		
		t = threshT[ ecnt ] 
		
		if ( t < currentTime )
			EventRetrieve( ecnt, rejections = rejections )
			return ecnt
		endif
	
	endfor
	
	return -1
	
End // EventRetrieveLast

//****************************************************************
//****************************************************************
//****************************************************************

Function EventRetrieveLastWaveNum( currentWave [ rejections ] )
	Variable currentWave
	Variable rejections // event rejections
	
	Variable ecnt, wnum
	String wname
	
	if ( ( numtype( currentWave ) > 0 ) || ( currentWave < 0 ) )
		currentWave = CurrentNMWave()
	endif
	
	wname = NMEventTableWaveName( "WaveN", rejections = rejections )
	
	if ( !WaveExists( $wname ) )
		NMDoAlert( "No events to retrieve.", title=AlertTitle )
		return 0
	endif
	
	Wave waveN = $wname
	
	for ( ecnt = numpnts( waveN ) - 1 ; ecnt >= 0 ; ecnt -= 1 )
	
		wnum = waveN[ ecnt ]
	
		if ( wnum < currentWave )
			return wnum
		endif
	
	endfor
	
	return -1
	
End // EventRetrieveLastWaveNum

//****************************************************************
//****************************************************************
//****************************************************************

Function EventRetrieveNextWaveNum( currentWave [ rejections ] )
	Variable currentWave
	Variable rejections // event rejections
	
	Variable ecnt, wnum
	String wname
	
	if ( currentWave < 0 )
		currentWave = CurrentNMWave()
	endif
	
	wname = NMEventTableWaveName( "WaveN", rejections = rejections )
	
	if ( !WaveExists( $wname ) )
		NMDoAlert( "No events to retrieve.", title=AlertTitle )
		return 0
	endif
	
	Wave waveN = $wname
	
	for ( ecnt = 0 ; ecnt < numpnts( waveN ) ; ecnt += 1 )
	
		wnum = waveN[ ecnt ]
	
		if ( wnum > currentWave )
			return wnum
		endif
	
	endfor
	
	return -1
	
End // EventRetrieveNextWaveNum

//****************************************************************
//****************************************************************
//****************************************************************

Function EventRetrieve( event [ rejections ] ) // retrieve event times from wave
	Variable event // event number
	Variable rejections // event rejections
	
	Variable wbgn, wend, threshx
	
	String wname = NMEventTableWaveName( "ThreshT", rejections = rejections )
	
	if ( !WaveExists( $wname ) )
		return -1
	endif
	
	Variable bslnOn = NMEventBaselineOn()
	
	Variable baseWin = NMEventVarGet( "BaseWin" )
	Variable searchDT = NMEventVarGet( "SearchDT" )
	
	Wave ThreshT = $NMEventTableWaveName( "ThreshT", rejections = rejections )
	Wave ThreshY = $NMEventTableWaveName( "ThreshY", rejections = rejections )
	Wave OnsetT = $NMEventTableWaveName( "OnsetT", rejections = rejections )
	Wave OnsetY = $NMEventTableWaveName( "OnsetY", rejections = rejections )
	Wave PeakT = $NMEventTableWaveName( "PeakT", rejections = rejections )
	Wave PeakY = $NMEventTableWaveName( "PeakY", rejections = rejections )
	Wave BaseY = $NMEventTableWaveName( "BaseY", rejections = rejections )
	
	Wave dBaseT = $NMEventDisplayWaveName( "BaseT" )
	Wave dBaseY = $NMEventDisplayWaveName( "BaseY" )
	Wave ThisT = $NMEventDisplayWaveName( "ThisT" )
	Wave ThisY = $NMEventDisplayWaveName( "ThisY" )
	Wave SearchT = $NMEventDisplayWaveName( "SearchT" )
	Wave SearchY = $NMEventDisplayWaveName( "SearchY" )
	
	if ( ( numtype( event ) > 0 ) || ( event < 0 ) || ( event >= numpnts( ThreshT ) ) )
		return -1 // out of range
	endif
	
	threshx = ThreshT[ event ]
	
	SetNMvar( NMEventDF + "ThreshX", threshx )
	SetNMvar( NMEventDF + "ThreshY", ThreshY[ event ] )
	SetNMvar( NMEventDF + "OnsetX", OnsetT[ event ] )
	SetNMvar( NMEventDF + "OnsetY", OnsetY[ event ] )
	SetNMvar( NMEventDF + "PeakX", PeakT[ event ] )
	SetNMvar( NMEventDF + "PeakY", PeakY[ event ] )
	SetNMvar( NMEventDF + "baseY", BaseY[ event ] )
	SetNMvar( NMEventDF + "SearchTime", threshx )
	
	if ( numpnts( ThisT ) == 1 )
		ThisT[ 0 ] = ThreshT[ event ]
		ThisY[ 0 ] = ThreshY[ event ]
	endif
	
	if ( bslnOn ) // compute baseline display
	
		wbgn = threshx - searchDT - baseWin/2
		wend = threshx - searchDT + baseWin/2
		
		if ( numtype( BaseY[ event ] ) > 0 )
			WaveStats /Q/Z/R=( wbgn,wend ) $ChanDisplayWave( -1 )
			dBaseY = V_avg
		else
			dBaseY = BaseY[ event ]
		endif
		
		if ( numpnts( dBaseT ) == 2 )
			dBaseT[ 0 ] = wbgn
			dBaseT[ 1 ] = wend
		endif
		
		if ( ( numpnts( SearchT ) == 3 ) && ( numpnts( ThisT ) ==  1 ) )
		
			SearchT[ 0 ] = ( wbgn + wend ) / 2
			SearchT[ 1 ] = ( wbgn + wend ) / 2
			SearchY[ 0 ] = BaseY[ event ]
			
			SearchT[ 2 ] = ThisT[ 0 ]
			SearchY[ 1 ] = ThisY[ 0 ]
			SearchY[ 2 ] = ThisY[ 0 ]
		
		endif
		
	endif
	
	EventCursors( 1 )
	
	Return 0

End // EventRetrieve

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSaveCall()

	Variable error = EventSave()

	if ( ( error == 0 ) && ( NMEventVarGet( "ReviewFlag" ) == 0 ) && NMEventVarGet( "FindNextAfterSaving" ) )
		EventFindNextCall()
	endif

	return error

End // EventSaveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSave( [ update ] )
	Variable update
	
	Variable error
	
	Variable currentWave = CurrentNMWave()
	
	Variable threshX = NMEventVarGet( "ThreshX" )
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif

	if ( NMEventRejectsOn() ) // convert rejected to saved
	
		EventSaveCurrent( 1, rejections = 0 )
		EventDelete( currentWave, threshX, rejections = 1 )
	
	else
	
		error = EventSaveCurrent( 1 )
		
	endif
	
	if ( update )
		UpdateEventTab()
	endif
	
	return error
	
End // EventSave

//****************************************************************
//****************************************************************
//****************************************************************

Function EventSaveCurrent( cursors [ rejections, noAlert ] ) // save event times to table
	Variable cursors // ( 0 ) save computed values ( 1 ) save values from cursors A, B
	Variable rejections // event rejections
	Variable noAlert
	
	Variable event, npnts
	String wname
	
	Variable currentChan = CurrentNMChannel()
	Variable currentWave = CurrentNMWave()
	
	String gName = ChanGraphName( currentChan )
	
	Variable xbgn = EventSearchBgn()
	Variable xend = EventSearchEnd()
	
	Variable onsetX = NMEventVarGet( "OnsetX" )
	Variable onsetY = NMEventVarGet( "OnsetY" )
	Variable peakX = NMEventVarGet( "PeakX" )
	Variable peakY = NMEventVarGet( "PeakY" )
	Variable threshX = NMEventVarGet( "ThreshX" )
	Variable threshY = NMEventVarGet( "ThreshY" )
	Variable baseY = NMEventVarGet( "BaseY" )
	
	Variable uniquenessCriteriaOn = NMEventVarGet( "UniquenessCriteriaOn" )
	Variable uniquenessWindow = NMEventVarGet( "UniquenessWindow" )
	Variable uniquenessOverwriteAlert = NMEventVarGet( "UniquenessOverwriteAlert" )
	
	if ( numtype( threshX * threshY ) > 0 )
		//NMDoAlert( "No event to save.", title=AlertTitle )
		return -1
	endif
	
	NMEventTableManager( "", "make", rejections = rejections )
	
	wname = NMEventTableWaveName( "ThreshT", rejections = rejections )
	
	if ( !WaveExists( $wname ) )
		NMDoAlert( "Event Save Abort: cannot locate current table wave: " + wname, title=AlertTitle )
		return -1
	endif
	
	Wave wvN = $NMEventTableWaveName( "WaveN", rejections = rejections )
	Wave thT = $NMEventTableWaveName( "ThreshT", rejections = rejections )
	Wave thY = $NMEventTableWaveName( "ThreshY", rejections = rejections )
	Wave onT = $NMEventTableWaveName( "OnsetT", rejections = rejections )
	Wave onY = $NMEventTableWaveName( "OnsetY", rejections = rejections )
	Wave pkT = $NMEventTableWaveName( "PeakT", rejections = rejections )
	Wave pkY = $NMEventTableWaveName( "PeakY", rejections = rejections )
	Wave bsY = $NMEventTableWaveName( "BaseY", rejections = rejections )
	Wave ampY = $NMEventTableWaveName( "AmpY", rejections = rejections )
	
	if ( cursors ) // get cursor points from graph ( allows user to move onset/peak cursors )
	
		if ( strlen( CsrInfo( A, gName ) ) > 0 )
			onsetX = xcsr( A, gName )
			onsetY = vcsr( A, gName )
		endif
		
		if ( strlen( CsrInfo( B, gName ) ) > 0 )
			peakX = xcsr( B, gName )
			peakY = vcsr( B, gName )
		endif
		
	endif
	
	if ( ( numtype( onsetX*onsetY ) > 0 ) || ( onsetX <= xbgn ) || ( onsetX >= xend ) )
		onsetX = Nan
		onsetY = Nan
	endif
	
	if ( ( numtype( peakX*peakY ) > 0 ) || ( peakX <= xbgn ) || ( peakX >= xend ) )
		peakX = Nan
		peakY = Nan
	endif

	if ( uniquenessCriteriaOn )
	
		event = EventFindSaved( NMEventTableWaveName( "WaveN", rejections = rejections ), wname, threshX, uniquenessWindow, currentWave )
	
		if ( event != -1 ) // found a similar event
		
			if ( noAlert || !uniquenessOverwriteAlert )
			
				DeletePoints event, 1, wvN, thT, thY, onT, onY, pkT, pkY, bsY, ampY
			
			else
				
				DoAlert 2, "EventSaveCurrent Alert: a similar event already exists. Do you want to replace it?"
			
				if ( V_flag == 1 )
					DeletePoints event, 1, wvN, thT, thY, onT, onY, pkT, pkY, bsY, ampY
				else
					return -3 // cancel
				endif
			
			endif
			
		endif
	
	endif
	 
	npnts = numpnts( thT )

	Redimension /N=( npnts+1 ) wvN, thT, thY, onT, onY, pkT, pkY, bsY, ampY
	
	wvN[ npnts ] = currentWave
	thT[ npnts ] = threshX
	thY[ npnts ] = threshY
	onT[ npnts ] = onsetX
	onY[ npnts ] = onsetY
	pkT[ npnts ] = peakX
	pkY[ npnts ] = peakY
	bsY[ npnts ] = baseY
	ampY[ npnts ] = peakY - baseY
	
	Sort { wvN, thT }, wvN, thT, thY, onT, onY, pkT, pkY, bsY, ampY
	
	WaveStats /Q/Z thT
	
	if ( ( V_numNans > 0 ) && ( V_npnts != numpnts( wvN ) ) )
		Redimension /N=( V_npnts ) wvN, thT, thY, onT, onY, pkT, pkY, bsY, ampY // remove NANs if they exist
	endif
	
	//SetNMvar( NMEventDF + "ThreshY", Nan ) // Null existing event
	//SetNMvar( NMEventDF + "OnsetY", Nan )
	//SetNMvar( NMEventDF + "PeakY", Nan )
	//SetNMvar( NMEventDF + "BaseY", Nan )
	
	EventCount( updateDisplay = 1, rejections = rejections )
	UpdateEventDisplay()
	
	SetNMvar( NMEventDF + "FoundEventFlag", 2 )
	
	return 0
	
End // EventSaveCurrent

//****************************************************************
//****************************************************************
//****************************************************************

Function EventFindSaved( nwName, ewName, eventTime, uniquenessWindow, waveNum ) // locate saved event time
	String nwName // wave of record numbers
	String ewName // wave of event times
	Variable eventTime // ms
	Variable uniquenessWindow // tolerance/uniqueness window
	Variable waveNum // record number
	
	Variable ecnt
	
	if ( !WaveExists( $nwName ) )
		//NMDoAlert( "EventFindSaved Abort: cannot locate wave " + nwName )
		return -1
	endif
	
	if ( !WaveExists( $ewName ) )
		//NMDoAlert( "EventFindSaved Abort: cannot locate wave " + ewName )
		return -1
	endif
	
	if ( numpnts( $nwName ) != numpnts( $ewName ) )
		return -1
	endif
	
	Wave waveN = $nwName
	Wave waveE = $ewName
	
	for ( ecnt = 0 ; ecnt < numpnts( waveE ) ; ecnt += 1 )
	
		if ( waveN[ ecnt ] != waveNum )
			continue
		endif
		
		if ( ( waveE[ ecnt ] > eventTime - abs( uniquenessWindow / 2 ) ) && ( waveE[ ecnt ] < eventTime + abs( uniquenessWindow / 2 ) ) )
			return ecnt
		endif
		
	endfor

	return -1

End // EventFindSaved

//****************************************************************
//****************************************************************
//****************************************************************

Function EventDeleteCall( [ alert ] )
	Variable alert

	Variable rejections, error, pflag
	
	Variable currentWave = CurrentNMWave()
	
	Variable threshX = NMEventVarGet( "ThreshX" )
	Variable reviewFlag = NMEventVarGet( "ReviewFlag" )
	Variable saveRejected = NMEventVarGet( "SaveRejected" )
	
	switch( reviewFlag )
	
		case 0: // manual search, save as reject
		
			if ( saveRejected )
				pflag = EventSaveCurrent( 0, rejections = 1, noAlert = 1 )
			endif
			
			break
			
		case 1: // review successes (move success to reject)
		
			if ( saveRejected )
				pflag = EventSaveCurrent( 0, rejections = 1, noAlert = 1 ) // save to rejects
			endif
			
			error = EventDelete( currentWave, threshX, rejections = 0 ) // delete from successes
			//NMHistory( "rejected event #" + num2istr( event ) + " from table " + tableName )
			
			break
	
		case 2: // review rejections (delete rejection)
		
			rejections = 1
		
			if ( alert )
		
				DoAlert 1, "Permanently delete rejected event at t = " + num2str( threshX ) + "?"
			
				if ( V_flag != 1 )
					return 0 // cancel
				endif
			
			endif
			
			error = EventDelete( currentWave, threshX, rejections = 1 )
		
	endswitch

	if ( ( error == 0 ) && ( reviewFlag == 0 ) && NMEventVarGet( "FindNextAfterDeleting" ) )
		EventFindNextCall()
	endif

	return error
	
End // EventDeleteCall

//****************************************************************
//****************************************************************
//****************************************************************

Function EventDelete( waveNum, eventTime [ rejections, noAlert ] ) // delete saved event from table/display waves
	Variable waveNum
	Variable eventTime
	Variable rejections // event rejections
	Variable noAlert
	
	Variable event
	String wNameN, wNameT
	
	String tableName = CurrentNMEventTableName()
	
	wNameN = NMEventTableWaveName( "WaveN", rejections = rejections )
	wNameT = NMEventTableWaveName( "ThreshT", rejections = rejections )
	
	if ( !WaveExists( $wNameT ) )
		return -1
	endif
	 
	Wave wvN = $wNameN
	Wave thT = $wNameT
	Wave thY = $NMEventTableWaveName( "ThreshY", rejections = rejections )
	Wave onT = $NMEventTableWaveName( "OnsetT", rejections = rejections )
	Wave onY = $NMEventTableWaveName( "OnsetY", rejections = rejections )
	Wave pkT = $NMEventTableWaveName( "PeakT", rejections = rejections )
	Wave pkY = $NMEventTableWaveName( "PeakY", rejections = rejections )
	Wave bsY = $NMEventTableWaveName( "BaseY", rejections = rejections )
	Wave ampY = $NMEventTableWaveName( "AmpY", rejections = rejections )
	
	event = EventFindSaved( wNameN, wNameT, eventTime, 0.01, waveNum )
	
	if ( event == -1 )
		if ( !noAlert )
			NMDoAlert( "Delete Alert: no event exists with threshold time " + num2str( eventTime ) + " ms.", title=AlertTitle )
		endif
		return 0 // event does not exist
	endif
	
	if ( ( numtype( event ) > 0 ) || ( event < 0 ) || ( event >= numpnts( wvN ) ) )
		return -1
	endif
	
	DeletePoints event, 1, wvN, thT, thY, onT, onY, pkT, pkY, bsY, ampY
	
	EventCount( updateDisplay = 1, rejections = rejections)
	UpdateEventDisplay( clearCurrentEventDisplay = 1 )
	
	return 0

End // EventDelete

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Event Subfolder Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventSubfolder( wavePrefix, waveSelect )
	String wavePrefix
	String waveSelect
	
	if ( !NMEventVarGet( "UseSubfolders" ) )
		return ""
	endif
	
	return NMSubfolderName( "Event_", wavePrefix, CurrentNMChannel(), waveSelect )

End // NMEventSubfolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMEventSubfolder()

	return NMEventSubfolder( CurrentNMWavePrefix(), NMWaveSelectShort() )
	
End // CurrentNMEventSubfolder

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMEventSubfolder()
	
	String subfolder = CurrentNMEventSubfolder()
	
	if ( strlen( subfolder ) > 0 )
		return CheckNMSubfolder( subfolder )
	else
		return 0
	endif
	
End // CheckNMEventSubfolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventSubfolderWaveName( subfolder, type [ rejections ] )
	String subfolder
	String type // e.g. "ThreshT" or "OnsetY"
	Variable rejections // event rejections
	
	Variable icnt
	String wname, wList
	
	if ( rejections )
		wList = NMFolderWaveList( subfolder, "EVX_*", ";", "", 1 )
	else
		wList = NMFolderWaveList( subfolder, "EV_*", ";", "", 1 )
	endif
	
	for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
	
		wname = StringFromList( icnt, wList )
		
		if ( strsearch( wname, type, 0, 2 ) > 0 )
			return wname
		endif
	
	endfor
	
	return ""
	
End // NMEventSubfolderWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventSubfolderTableName( subfolder [ rejections ] )
	String subfolder
	Variable rejections // event rejections
	
	if ( strlen( subfolder ) == 0 )
		subfolder = CurrentNMEventSubfolder()
	endif
	
	if ( rejections )
		return NMSubfolderTableName( subfolder, "EVX_" )
	else
		return NMSubfolderTableName( subfolder, "EV_" )
	endif
	
End // NMEventSubfolderTableName

//****************************************************************
//****************************************************************

Static Function /S z_NMEventSubfolderKillCall()
	
	String subfolder = CurrentNMEventSubfolder()
	
	if ( StringMatch( subfolder, GetDataFolder( 0 ) ) ==1 )
		return "" // not allowed
	endif
	
	DoAlert 1, "Are you sure you want to delete subfolder " + NMQuotes( subfolder ) + "?"
	
	if ( V_flag != 1 )
		return "" // cancel
	endif
	
	return NMEventSubfolderKill( subfolder = DEFAULTSUBFOLDER, history = 1 )
	
End // z_NNMEventSubfolderKillCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventSubfolderKill( [ subfolder, update, history ] )
	String subfolder // data folder, or nothing for current data folder, or "_subfolder_" for currently selected Event folder
	Variable update
	Variable history
	
	String vlist = ""
	String thisfxn = GetRTStackInfo( 1 )
	
	if ( ParamIsDefault( subfolder ) )
		subfolder = CurrentNMEventSubfolder()
	else
		vlist = NMCmdStrOptional( "subfolder", subfolder, vlist )
	endif
	
	subfolder = CheckNMEventFolderPath( subfolder )
	
	if ( !DataFolderExists( subfolder ) )
		return NM2ErrorStr( 30, "subfolder", subfolder )
	endif
	
	if ( StringMatch( subfolder, GetDataFolder( 1 ) ) ==1 )
		NMDoAlert( thisfxn + " Abort: cannot close the current data folder.", title=AlertTitle )
		return "" // not allowed
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	Variable error = NMSubfolderKill( subfolder )
	
	if ( update )
		UpdateEventTab()
	endif
	
	if ( error == 0 )
		return subfolder
	else
		return ""
	endif

End // NMStatsSubfolderKill

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Event Table Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function EventTableCall( fxn )
	String fxn
	
	String tableSelect = StrVarOrDefault( "EventTableSelected", "" )
	String tableName = CurrentNMEventTableName()

	strswitch( fxn )
	
		case "New": // for old table formats only
			NMEventTableNew( history = 1 )
			return 0
			
		case "Clear":
			return NMEventTableClearCall()
			
		case "Kill":
			return NMEventTableKillCall()
			
		case "E2W":
		case "Events2Waves":
			return NMEvents2WavesCall()
			
		case "Histo":
			return EventHistoCall()
			
		default:
			NMDoAlert( "EventTableCall Error: unrecognized function call: " + fxn, title=AlertTitle )
		
	endswitch
	
End // EventTableCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S EventTableList()
	
	if ( NMEventTableOldExists() )
		return NMEventTableOldList( CurrentNMChannel() )
	else
		return NMSubfolderList2( "", "Event_", 0, 0 )
	endif

End // EventTableList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CheckNMEventTableSelect()

	String tableList, tableSelect
	
	if ( !NMEventTableOldExists() )
		return CurrentNMEventTableSelect()
	endif
	
	tableSelect = StrVarOrDefault( "EventTableSelected", "" )
	
	if ( strlen( tableSelect ) > 0 )
		return tableSelect
	endif
	
	tableList = NMEventTableOldList( CurrentNMChannel() )
		
	if ( ItemsInList( tableList ) == 1 )
	
		tableSelect = StringFromList( 0, tableList )
		
		SetNMstr( "EventTableSelected", tableSelect )
		
		return tableSelect
	
	elseif ( ItemsInList( tableList ) > 1 )

		Prompt tableSelect, "please select current Event table:" popup tableList
		DoPrompt "Current Event Table", tableSelect
		
		if ( V_flag == 1 )
			return ""
		endif
		
		SetNMstr( "EventTableSelected", tableSelect )
		
		return tableSelect
	
	endif
	
	return ""

End // CheckNMEventTableSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventTableSelect( tableSelect [ update ] )
	String tableSelect
	Variable update
	
	Variable tableNum
	String tableName, xtableName = ""
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	Variable currentChan = CurrentNMChannel()
	
	SetNMstr( "EventTableSelected", tableSelect )
	
	if ( NMEventTableOldFormat( tableSelect ) )
		
		tableNum = EventNumFromName( tableSelect )
		tableName = NMEventTableOldName( currentChan, tableNum )
		
	else
	
		tableName = CurrentNMEventTableName()
		xtableName = CurrentNMEventTableName( rejections = 1 )
		
	endif
	
	if ( strlen( tableName ) > 0 )
	
		if ( WaveExists( $NMEventTableWaveName( "WaveN", rejections = 1 ) ) )
			NMEventTableManager( "", "make", rejections = 1 )
			DoWindow /F $xtableName
		endif
	
		NMEventTableManager( tableName, "make" )
		DoWindow /F $tableName
		
	endif
	
	if ( update )
		UpdateEventDisplay( clearCurrentEventDisplay = 1 )
		UpdateEventTab()
	endif
	
	return tableName
	
End // NMEventTableSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMEventTableSelect()
	
	if ( NMEventTableOldExists() )
	
		return NMEventTableOldSelect( CurrentNMChannel(), NMEventTableOldNum() )
		
	else
	
		if ( NMEventVarGet( "UseSubfolders" ) )
			return NMChild( CurrentNMEventSubfolder() )
		else
			if ( NMEventRejectsOn() )
				return CurrentNMEventTableName( rejections = 1 )
			else
				return CurrentNMEventTableName()
			endif
			
		endif
		
	endif
	
	return ""

End // CurrentNMEventTableSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMEventTableName( [ rejections ] )
	Variable rejections // event rejections

	Variable tableNum
	String tablePrefix, tableName
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	Variable chanNum = CurrentNMChannel()
	
	String tableSelect = StrVarOrDefault( "EventTableSelected", "" )
	
	if ( !rejections && NMEventTableOldFormat( tableSelect ) )
		
		tableNum = EventNumFromName( tableSelect )
	
		if ( tableNum >= 0 )
			return NMEventTableOldName( chanNum, tableNum )
		endif
		
	else
	
		if ( NMEventVarGet( "UseSubfolders" ) )
		
			return NMEventSubfolderTableName( "", rejections = rejections )
			
		else
		
			if ( rejections )
				tablePrefix = "EVX_"
			else
				tablePrefix = "EV_"
			endif
		
			tablePrefix += CurrentNMFolderPrefix() + NMWaveSelectStr() + "_Table_"
			
			return NextGraphName( tablePrefix, chanNum, 1 )
	
		endif
		
	
	endif
	
	return ""

End // CurrentNMEventTableName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventTableClearCall()

	String tableSelect = StrVarOrDefault( "EventTableSelected", "" )
	String tableName = CurrentNMEventTableName()

	if ( strlen( tableName ) == 0 )
		//NMDoAlert( "No event table to clear." )
		return -1
	endif
	
	DoAlert 1, "Are you sure you want to clear tables for " + NMQuotes( tableSelect ) + "?"
	
	if ( V_flag != 1 )
		return -1
	endif
	
	return NMEventTableClear( "", history = 1 )

End // NMEventTableClearCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventTableClear( tableName [ update, history ] )
	String tableName // ( "" ) for current event table
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	Variable rejections // event rejections
	
	String vlist = ""
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( history )
		vlist = NMCmdStr( tableName, vlist )
		NMCommandHistory( vlist )
	endif
	
	NMEventTableManager( tableName, "clear" )
	NMEventTableManager( tableName, "clear", rejections = 1 )
	
	SetNMvar( NMEventDF + "ReviewFlag", 0 )
	
	if ( update )
		UpdateEventDisplay( clearCurrentEventDisplay = 1 )
		UpdateEventTab()
	endif
	
	return 0

End // NMEventTableClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventTableKillCall()

	String tableSelect = StrVarOrDefault( "EventTableSelected", "" )
	String tableName = CurrentNMEventTableName()

	if ( strlen( tableName ) == 0 )
		//NMDoAlert( "No event table to kill." )
		return -1
	endif
	
	DoAlert 1, "Are you sure you want to kill table " + NMQuotes( tableSelect ) + "?"
	
	if ( V_flag != 1 )
		return -1
	endif
	
	NMEventTableKill( "", history = 1 )
			
End // NMEventTableKillCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventTableKill( tableName [ update, history ] )
	String tableName // ( "" ) for current event table
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable items
	String tableList, vlist = ""
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( history )
		vlist = NMCmdStr( tableName, vlist )
		NMCommandHistory( vlist )
	endif
	
	NMEventTableManager( tableName, "kill" )
	NMEventTableManager( tableName, "kill", rejections = 1 )
	
	tableList = EventTableList()
	
	items = ItemsInList( tableList )
	
	if ( items > 0 )
		tableName = StringFromList( items-1, tableList )
	else
		tableName = ""
	endif
	
	SetNMstr( "EventTableSelected", tableName )
	
	SetNMvar( NMEventDF + "ReviewFlag", 0 )
	
	if ( update )
		UpdateEventDisplay( clearCurrentEventDisplay = 1 )
		UpdateEventTab()
	endif
	
	return 0
	
End // NMEventTableKill

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventTableManager( tableName, option [ rejections ] )
	String tableName
	String option // "make" or "update" or "clear" or "kill"
	Variable rejections // event rejections
	
	STRUCT Rect w
	
	if ( !NMEventTableOldExists() )
		CheckNMEventSubfolder()
	endif
	
	SetNMstr( "EventTableSelected", CurrentNMEventTableSelect() )
	
	if ( strlen( tableName ) == 0 )
		tableName = CurrentNMEventTableName( rejections = rejections )
	endif
	
	strswitch( option )
	
		case "make":
		
			if ( WinType( tableName ) == 2 )
				//DoWindow /F $tableName
				return 0 // table already exists
			endif
			
			NMOutputListsReset()
			
			NMWinCascadeRect( w )
			
			Make /O/N=0 EV_DumWave
			DoWindow /K $tableName
			Edit /K=1/N=$tableName/W=(w.left,w.top,w.right,w.bottom) EV_DumWave as NMEventTableTitle( rejections = rejections )
			ModifyTable /W=$tableName title( Point )="Event"
			RemoveFromTable /W=$tableName EV_DumWave
			KillWaves /Z EV_DumWave
			
			SetNMstr( NMDF + "OutputWinList", tableName )
		
			NMHistoryOutputWindows()
			
			break
			
		case "update":
		case "clear":
			DoWindow /F $tableName
			break
			
		case "kill":
			DoWindow /K $tableName
			break
			
		default:
			return NM2Error( 20, "option", option )
	
	endswitch 
	
	NMEventTableWaveManager( option, "WaveN", tableName, rejections = rejections )
	NMEventTableWaveManager( option, "ThreshT", tableName, rejections = rejections )
	NMEventTableWaveManager( option, "ThreshY", tableName, rejections = rejections )
	NMEventTableWaveManager( option, "OnsetT", tableName, rejections = rejections )
	NMEventTableWaveManager( option, "OnsetY", tableName, rejections = rejections )
	NMEventTableWaveManager( option, "PeakT", tableName, rejections = rejections )
	NMEventTableWaveManager( option, "PeakY", tableName, rejections = rejections )
	NMEventTableWaveManager( option, "BaseY", tableName, rejections = rejections )
	NMEventTableWaveManager( option, "AmpY", tableName, rejections = rejections )
	
	strswitch( option )
	
		case "make":
		case "update":
	
			NMEventTableWaveManager( "remove", "WaveN", tableName, rejections = rejections )
			NMEventTableWaveManager( "remove", "ThreshT", tableName, rejections = rejections )
			NMEventTableWaveManager( "remove", "ThreshY", tableName, rejections = rejections )
			NMEventTableWaveManager( "remove", "OnsetT", tableName, rejections = rejections )
			NMEventTableWaveManager( "remove", "OnsetY", tableName, rejections = rejections )
			NMEventTableWaveManager( "remove", "PeakT", tableName, rejections = rejections )
			NMEventTableWaveManager( "remove", "PeakY", tableName, rejections = rejections )
			NMEventTableWaveManager( "remove", "BaseY", tableName, rejections = rejections )
			NMEventTableWaveManager( "remove", "AmpY", tableName, rejections = rejections )
			
			NMEventTableWaveManager( "append", "WaveN", tableName, rejections = rejections )
			
			NMEventTableWaveManager( "append", "ThreshT", tableName, rejections = rejections )
			NMEventTableWaveManager( "append", "ThreshY", tableName, rejections = rejections )
			
			if ( NMEventVarGet( "OnsetOn" ) )
				NMEventTableWaveManager( "append", "OnsetT", tableName, rejections = rejections )
				NMEventTableWaveManager( "append", "OnsetY", tableName, rejections = rejections )
			endif
			
			if ( NMEventVarGet( "PeakOn" ) )
				NMEventTableWaveManager( "append", "PeakT", tableName, rejections = rejections )
				NMEventTableWaveManager( "append", "PeakY", tableName, rejections = rejections )
			endif
			
			if ( NMEventBaselineOn() )
			
				NMEventTableWaveManager( "append", "BaseY", tableName, rejections = rejections )
				
				if ( NMEventVarGet( "PeakOn" ) )
					NMEventTableWaveManager( "append", "AmpY", tableName, rejections = rejections )
				endif
				
			endif
		
	endswitch

End // NMEventTableManager

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventTableTitle( [ rejections ] )
	Variable rejections // event rejections
	
	String tt = "Events"
	
	if ( rejections )
		tt = "Event Rejections"
	endif
	
	return NMFolderListName("") + " : " + tt + " : Ch " + ChanNum2Char( CurrentNMChannel() ) + " : " + CurrentNMWavePrefix() + " : " + NMWaveSelectGet()

End // NMEventTableTitle

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventTableWaveManager( option, wtype, tableName [ rejections ] )
	String option // "make" or "clear" or "kill" or "append" or "remove"
	String wtype // e.g. "ThreshY" or "PeakY"
	String tableName
	Variable rejections // event rejections
	
	String wName = NMEventTableWaveName( wtype, rejections = rejections )
	
	strswitch( option )
	
		case "make":
		
			if ( !WaveExists( $wName ) )
				Make /D/O/N=0 $wName
				NMEventTableWaveNote( wName, wtype, rejections = rejections )
				return 0
			else
				return -1
			endif
			
		case "clear":
		
			if ( WaveExists( $wName ) )
				Wave evWave = $wName
				Redimension /N=0 evWave
				return 0
			else
				return -1
			endif
			
		case "kill":
			KillWaves /Z $wName
			return 0
			
		case "append":
		
			if ( WaveExists( $wName ) && ( WinType( tableName ) == 2 ) )
				AppendToTable /W=$tableName $wName
				return 0
			else
				return -1
			endif
			
		case "remove":
		
			if ( WaveExists( $wName ) && ( WinType( tableName ) == 2 ) )
				RemoveFromTable /W=$tableName $wName
				return 0
			else
				return -1
			endif
			
		case "update":
			return 0
			
		default:
			return NM2Error( 20, "option", option )
			
	endswitch

End // NMEventTableWaveManager

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventTableWaveName( wtype [ rejections ] ) // return appropriate event wave name
	String wtype // type of measurement ( e.g. "ThreshT" )
	Variable rejections // event rejections
	
	String wavePrefix, wname, subfolder
	
	Variable currentChan = CurrentNMChannel()
	
	if ( strlen( wtype ) == 0 )
		return ""
	endif
	
	if ( rejections )
		wavePrefix = "EVX_"
	else
		wavePrefix = "EV_"
	endif
	
	if ( !rejections && CurrentNMEventTableOldFormat() )
	
		wname = NMEventTableOldWaveName( wtype, currentChan, NMEventTableOldNum() )
		
		return wname[ 0,30 ]
	
	else
	
		subfolder = CurrentNMEventSubfolder()
		 wavePrefix += wtype + "_" + NMWaveSelectStr() + "_"
		 wname = NextWaveName2( subfolder, wavePrefix, currentChan, Overwrite )
		 
		 return subfolder + wname[ 0,30 ]
	
	endif
	
End // NMEventTableWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventTableWaveNote( wName, wtype [ rejections ] )
	String wName
	String wtype
	Variable rejections // event rejections
	
	if ( !WaveExists( $wName ) )
		return -1
	endif
	
	String yLabel, xLabel = "Event Rejection#", txt = ""
	
	String wavePrefix = CurrentNMWavePrefix()
	
	String chX = NMChanLabelX()
	String chY = NMChanLabelY()
	
	Variable xbgn = EventSearchBgn()
	Variable xend = EventSearchEnd()
	
	Variable searchMethod = NMEventVarGet( "SearchMethod" )
	Variable threshLevel = NMEventVarGet( "SearchValue" )
	
	Variable baseWin = NMEventVarGet( "BaseWin" )
	Variable searchDT = NMEventVarGet( "SearchDT" )
	
	Variable onsetAvg = NMEventVarGet( "OnsetWin" )
	Variable onsetNstdv = NMEventVarGet( "OnsetNstdv" )
	Variable onsetWin = NMEventVarGet( "OnsetLimit" )
	
	Variable peakAvg = NMEventVarGet( "PeakWin" )
	Variable peakNstdv = NMEventVarGet( "PeakNstdv" )
	Variable peakWin = NMEventVarGet( "PeakLimit" )
	
	Variable matchFlag = NMEventVarGet( "MatchFlag" )
	Variable matchWform = NMEventVarGet( "MatchWform" )
	Variable matchTau1 = NMEventVarGet( "MatchTau1" )
	Variable matchTau2 = NMEventVarGet( "MatchTau2" )
	Variable matchBsln = NMEventVarGet( "MatchBsln" )
	
	String template = NMEventStrGet( "Template" )
	
	txt = "Event Prefix:" + wavePrefix
	txt += NMCR + "Event Method:" + EventSearchMethodString() + ";Event Thresh:" + num2str( threshLevel ) + ";"
	txt += NMCR + "Event Xbgn:" + num2str( xbgn ) + ";Event Xend:" + num2str( xend ) + ";"
	txt += NMCR + "Base Avg:" + num2str( baseWin ) + ";Base DT:" + num2str( searchDT ) + ";"
	txt += NMCR + "Onset Limit:" + num2str( onsetWin ) + ";Onset Avg:" + num2str( onsetAvg ) + ";"
	txt += "Onset Nstdv:" + num2str( onsetNstdv ) + ";"
	txt += NMCR + "Peak Limit:" + num2str( peakWin ) + ";Peak Avg:" + num2str( peakAvg ) + ";"
	txt += "Peak Nstdv:" + num2str( peakNstdv ) + ";"
	
	switch( matchFlag )
		case 1:
			txt += NMCR + "Match Template: 2-exp;Match Tau1:" + num2str( matchTau1 ) + ";Match Tau2:" + num2str( matchTau2 ) + ";"
			txt += NMCR + "Match Bsln:" + num2str( matchBsln ) + ";Match Win:" + num2str( matchWform ) + ";"
			break
		case 2: // tau1
			txt += NMCR + "Match Template: alpha;Match Tau1:" + num2str( matchTau1 ) + ";"
			txt += NMCR + "Match Bsln:" + num2str( matchBsln ) + ";Match Win:" + num2str( matchWform ) + ";"
			break
		case 3: // template
			txt += NMCR + "Match Template:" + template + ";"
			break
	endswitch
	
	strswitch( wtype )
	
		case "WaveN":
			yLabel = wavePrefix + "#"
			break
			
		case "OnsetT":
			yLabel = chX
			break
			
		case "OnsetY":
			yLabel = chY
			break
			
		case "ThreshT":
			yLabel = chX
			break
			
		case "ThreshY":
			yLabel = chY
			break
			
		case "PeakT":
			yLabel = chX
			break
			
		case "PeakY":
			yLabel = chY
			break
			
		case "BaseY":
			yLabel = chY
			break
			
		case "AmpY":
			yLabel = chY
			break
			
	endswitch
	
	NMNoteType( wName, "NMEvent "+wtype, xLabel, yLabel, txt )
	
End // NMEventTableWaveNote

//****************************************************************
//****************************************************************
//****************************************************************

Function EventCount( [ updateDisplay, rejections ] )
	Variable updateDisplay
	Variable rejections

	Variable events
	String wname
	
	wname = NMEventTableWaveName( "ThreshT", rejections = rejections )
	
	if ( WaveExists( $wname ) )
		events = numpnts( $wname )
	endif
	
	if ( updateDisplay )
		SetNMvar( NMEventDF + "NumEvents", events )
	endif
	
	return events

End // EventCount

//****************************************************************
//****************************************************************
//****************************************************************

Function EventRepsCount( waveN )
	String waveN
	
	Variable icnt, jcnt, rcnt
	
	if ( !WaveExists( $waveN ) )
		return 0
	endif
	
	Wave yWave = $waveN
	
	for ( icnt = 0 ; icnt < NMNumWaves() ; icnt += 1 )
	
		for ( jcnt = 0 ; jcnt < numpnts( yWave ) ; jcnt += 1 )
		
			if ( yWave[ jcnt ] == icnt )
				rcnt += 1
				break
			endif
			
		endfor
	
	endfor
	
	return rcnt
	
End // EventRepsCount

//****************************************************************
//****************************************************************
//****************************************************************

Function EventNumFromName( wName )
	String wName
	
	Variable num, foundNum, icnt, slength = strlen( wName )
	
	if ( slength == 0 )
		return Nan
	endif
	
	for ( icnt = slength-1; icnt >= 0; icnt -= 1 )
	
		num = str2num( wName[ icnt ] )
		
		if ( numtype( num ) == 0 )
			foundNum = 1
		else
			break // found letter
		endif
		
	endfor
	
	if ( foundNum )
		return str2num( wName[ icnt+1, slength-1 ] )
	else
		return Nan
	endif
	
End // EventNumFromName

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Misc Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventCallWaveNames( callFxn, table, wName [ rejections ] )
	String callFxn
	String table
	String wName
	Variable rejections // event rejections
	
	String df, suffix, subfolder
	String waveOfEventTimes, waveOfOnsetTimes, waveOfWaveNums
	
	String wavePrefix = CurrentNMWavePrefix()

	if ( WaveExists( $wName ) )
	
		waveOfEventTimes = wName
		waveOfOnsetTimes = ReplaceString( "ThreshT", wName, "OnsetT" )
		waveOfWaveNums = ReplaceString( "ThreshT", wName, "WaveN" )
	
	elseif ( NMEventTableOldFormat( table ) )
	
		suffix = ReplaceString( OldEventTableSelect, table, "" )
		waveOfEventTimes = "EV_ThreshT_" + suffix
		waveOfOnsetTimes = "EV_OnsetT_" + suffix
		waveOfWaveNums = "EV_WaveN_" + suffix
		
	elseif ( strlen( table ) > 0 )
	
		subfolder = GetDataFolder(1) + table + ":"
		
		waveOfEventTimes = NMEventSubfolderWaveName( subfolder, "ThreshT", rejections=rejections )
		waveOfOnsetTimes = NMEventSubfolderWaveName( subfolder, "OnsetT", rejections=rejections )
		waveOfWaveNums = NMEventSubfolderWaveName( subfolder, "WaveN", rejections=rejections )
		
	else
	
		NMDoAlert( callFxn + " Abort: cannot locate wave of event times." )
		
		return ""
	
	endif
	
	if ( strlen( NMNoteStrByKey( waveOfOnsetTimes, "Match Template" ) ) > 0 )
		waveOfEventTimes = waveOfOnsetTimes // use OnsetT instead of ThreshT
	endif
	
	if ( !WaveExists( $waveOfEventTimes ) )
		NMDoAlert( callFxn + " Abort: cannot locate wave of event times " + NMQuotes( waveOfEventTimes ) )
		return ""
	endif
	
	if ( !WaveExists( $waveOfWaveNums ) )
		NMDoAlert( callFxn + " Abort: cannot locate wave of wave numbers " + NMQuotes( waveOfWaveNums ) )
		return ""
	endif
	
	if ( !StringMatch( wavePrefix, NMNoteStrByKey( waveOfEventTimes, "Event Prefix" ) ) )
		
		DoAlert 1, "Warning: the current wave prefix does not match that of " + NMQuotes( NMChild( waveOfEventTimes ) ) + ". Do you want to continue?"
		
		if ( V_Flag != 1 )
			return ""
		endif
		
	endif
	
	if ( numpnts( $waveOfEventTimes ) == 0 )
		NMDoAlert( callFxn + " Abort: detected no events in " + waveOfEventTimes )
		return ""
	endif 
	
	if ( numpnts( $waveOfWaveNums ) == 0 )
		NMDoAlert( callFxn + " Abort: detected no events in " + waveOfWaveNums )
		return ""
	endif
	
	df = GetDataFolder(1)
	
	waveOfEventTimes = ReplaceString( df, waveOfEventTimes , "" )
	waveOfWaveNums = ReplaceString( df, waveOfWaveNums , "" )
	
	return waveOfWaveNums + ";" + waveOfEventTimes + ";"
	
End // NMEventCallWaveNames

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEvents2WavesCall()

	Variable icnt, ccnt, cbgn, cend, jcnt, found, slen
	Variable askwhichwave, chanNum, stopyesno = 2 // waveSelect
	
	String tableList, table, fname, xLabel, yLabel, shortstr
	String wName, waveOfEventTimes, waveOfWaveNums, outputWavePrefix
	String wlist, wList2, suffix, subfolder
	String gPrefix, gName, gTitle
	String thisfxn = GetRTStackInfo( 1 )
	
	String tableSelect = CurrentNMEventTableSelect()
	
	Variable tableNum = NMEventTableOldNum()
	
	Variable currentChan = CurrentNMChannel()
	Variable numChannels = NMNumChannels()
	
	String wavePrefix = CurrentNMWavePrefix()
	
	Variable before = NMEventVarGet( "E2W_before" )
	Variable after = NMEventVarGet( "E2W_after" )
	Variable stop = NMEventVarGet( "E2W_stopAtNextEvent" )
	String chanStr = NMEventStrGet( "E2W_chan" )
	
	String defaultPrefix = NMEventStrGet( "S2W_WavePrefix" )
	
	Variable useSubfolders = NMEventVarGet( "UseSubfolders" )
	
	Variable rejections = NMEventRejectsOn()
	
	tableList = NMSubfolderList2( "", "Event_", 0, 0 ) + NMEventTableOldListAll()
	
	wList2 = WaveList( "EV_ThreshT*", ";", "" )
	wList = wList2
	
	for ( icnt = 0 ; icnt < ItemsInList( wList2 ) ; icnt += 1 )
	
		wName = StringFromList( icnt, wList2 )
		
		if ( strsearch( wName, "_intvl", 0, 2 ) > 0 )
			wList = RemoveFromList( wName, wList )
		endif
		
	endfor
	
	if ( ( ItemsInList( tableList ) == 0 ) && ( ItemsInList( wList ) == 0 ) )
	
		NMDoAlert( thisfxn + " Abort: detected no event waves." )
		
		return -1
		
	endif
	
	if ( ItemsInList( tableList ) > 0 )
	
		table = tableSelect
		
		if ( WhichListItem( table, tableList ) < 0 )
			table = StringFromList( 0, tableList )
		endif
		
		if ( ItemsInList( wList ) > 0 )
			wList = " ;" + wList
		endif
		
		wName = ""
		
	else
	
		table = ""
		
		wName = NMEventTableWaveName( "ThreshT" )
		
		if ( !WaveExists( $wName ) && ( ItemsInList( wList ) > 0 ) )
			wName = StringFromList( 0, wList )
		endif
	
	endif
	
	if ( stop < 0 )
		stopyesno = 1
	endif
	
	Prompt table, "select event table:", popup tableList
	Prompt wName, "or select wave of event times:", popup wList
	Prompt before, NMPromptAddUnitsX( "x-axis window to copy before event" )
	Prompt after, NMPromptAddUnitsX( "x-axis window to copy after event" )
	Prompt stopyesno, "limit new waves to time before next event?", popup "no;yes;"
	Prompt stop, NMPromptAddUnitsX( "additional x-axis window to limit before next event" )
	Prompt chanStr, "channel waves to copy from:", popup "All;" + NMChanList( "CHAR" )
	//Prompt waveSelect, "select wave of event times:", popup ""
	Prompt outputWavePrefix, "prefix name of new event waves:"
	
	if ( numChannels > 1 )
	
		if ( ItemsInList( wList ) > 0 )
			DoPrompt "Copy Events to Waves", table, wName, before, after, stopyesno, chanStr
		else
			DoPrompt "Copy Events to Waves", table, before, after, stopyesno, chanStr
		endif
	
		if ( V_flag == 1 )
			return 0 // cancel
		endif
		
		cbgn = ChanChar2Num( chanStr )
		cend = ChanChar2Num( chanStr )
		
		SetNMstr( NMEventDF + "E2W_chan", chanStr )
		
	else
	
		if ( ItemsInList( wList ) > 0 )
			DoPrompt "Copy Events to Waves", table, wName, before, after, stopyesno
		else
			DoPrompt "Copy Events to Waves", table, before, after, stopyesno	
		endif
		
		if ( V_flag == 1 )
			return 0 // cancel
		endif
		
		cbgn = currentChan
		cend = currentChan
		
	endif
	
	SetNMvar( NMEventDF + "E2W_before", before )
	SetNMvar( NMEventDF + "E2W_after", after )
	
	if ( StringMatch( table, tableSelect ) )
		waveOfEventTimes = "_selected_"
		waveOfWaveNums = "_selected_"
	else
	
		wList = NMEventCallWaveNames( thisfxn, table, wName, rejections=rejections )
		
		if ( ItemsInList( wList ) == 0 )
			return 0 // cancel
		endif
		
		waveOfWaveNums = StringFromList( 0, wList )
		waveOfEventTimes = StringFromList( 1, wList )
		
	endif
	
	if ( NMEventTableOldFormat( table ) )
		tableNum = EventNumFromName( NMChild( waveOfEventTimes ) )
	else
		tableNum = -1
	endif
	
	if ( StringMatch( chanStr, "All" ) )
		cbgn = 0
		cend = numChannels - 1
		chanNum = -1
	else
		chanNum = ChanChar2Num( chanStr )
	endif
	
	if ( tableNum >= 0 )
	
		outputWavePrefix = defaultPrefix + num2istr( tableNum )
		
	else
		
		if ( rejections )
			if ( !StringMatch( defaultPrefix[0], "x" ) )
				defaultPrefix = "x" + defaultPrefix
			endif
		endif
		
		outputWavePrefix = NMPrefixUnique( defaultPrefix )
		
	endif
	
	outputWavePrefix = CheckNMPrefixUnique( outputWavePrefix, defaultPrefix, chanNum )
	
	if ( stopyesno == 2 )
	
		if ( stop < 0 )
			stop = 0
		endif
		
		DoPrompt "Events to Waves", stop, outputWavePrefix
		
		if ( V_flag == 1 )
			return 0 // cancel
		endif
		
		SetNMvar( NMEventDF + "E2W_stopAtNextEvent", stop )
		
	else
	
		stop = -1
		
		DoPrompt "Events to Waves", outputWavePrefix
		
		if ( V_flag == 1 )
			return 0 // cancel
		endif
		
	endif
	
	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
	
		wlist = NMEvents2Waves( waveOfWaveNums, waveOfEventTimes, before, after, stop, 1, ccnt, outputWavePrefix, history=1 )
		
		if ( ItemsInList( wList ) == 0 )
			continue
		endif
		
		wname = outputWavePrefix + "Times"
		
		if ( WaveExists( $wname ) )
			Duplicate /O $wname, $"EV_Times_" + outputWavePrefix
			KillWaves /Z $wname
		endif
		
		if ( !NMVarGet( "GraphsAndTablesOn" ) )
			continue
		endif
		
		xLabel = NMChanLabelX( channel = ccnt )
		yLabel = NMChanLabelY( channel = ccnt )
		
		if ( tableNum >= 0 )
		
			gPrefix = outputWavePrefix + "_" + CurrentNMFolderPrefix() + ChanNum2Char( ccnt ) + num2istr( tableNum ) 
			gName = NMCheckStringName( gPrefix )
			gTitle = NMFolderListName( "" ) + " : Ch " + ChanNum2Char( ccnt ) + " : " + table
		
		else
		
			gPrefix = outputWavePrefix + "_" + CurrentNMFolderPrefix() + ChanNum2Char( ccnt ) + num2istr( 0 ) 
			gName = NMCheckStringName( gPrefix )
			gTitle = NMFolderListName( "" ) + " : Ch " + ChanNum2Char( ccnt ) + " : " + table
		
		endif
	
		NMGraph( wList = wList, gName = gName, gTitle = gTitle, xLabel = xLabel, yLabel = yLabel )
		
	endfor

End // NMEvents2WavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEvents2Waves( waveOfWaveNums, waveOfEventTimes, xwinBefore, xwinAfter, stopAtNextEvent, allowTruncatedEvents, chanNum, outputWavePrefix [ history ] )
	String waveOfWaveNums // wave of wave numbers
	String waveOfEventTimes // wave of event times
	Variable xwinBefore, xwinAfter // copy x-scale window before and after event
	Variable stopAtNextEvent // ( < 0 ) no ( >= 0 ) yes... if greater than zero, use value to limit time before next event
	Variable allowTruncatedEvents // ( 0 ) no ( 1 ) yes
	Variable chanNum // channel number ( pass -1 for current )
	String outputWavePrefix // prefix name for new waves
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	String wList, vlist = ""
	String thisfxn = GetRTStackInfo( 1 )
	
	Variable rejections = NMEventRejectsOn()
	
	if ( history )
		vlist = NMCmdStr( waveOfWaveNums, vlist )
		vlist = NMCmdStr( waveOfEventTimes, vlist )
		vlist = NMCmdNum( xwinBefore, vlist )
		vlist = NMCmdNum( xwinAfter, vlist )
		vlist = NMCmdNum( stopAtNextEvent, vlist, integer = 1 )
		vlist = NMCmdNum( allowTruncatedEvents, vlist, integer = 1 )
		vlist = NMCmdNum( chanNum, vlist, integer = 1 )
		vlist = NMCmdStr( outputWavePrefix, vlist )
		NMCommandHistory( vlist )
	endif
	
	if ( StringMatch( waveOfWaveNums, "_selected_" ) )
	
		wList = NMEventCallWaveNames( thisfxn, CurrentNMEventTableSelect(), "", rejections=rejections )
		
		if ( ItemsInList( wList ) == 0 )
			return ""
		endif
		
		waveOfWaveNums = StringFromList( 0, wList )
		
	endif
	
	if ( StringMatch( waveOfEventTimes, "_selected_" ) )
	
		wList = NMEventCallWaveNames( thisfxn, CurrentNMEventTableSelect(), "", rejections=rejections )
		
		if ( ItemsInList( wList ) == 0 )
			return ""
		endif
		
		waveOfEventTimes = StringFromList( 1, wList )
		
	endif
	
	if ( !WaveExists( $waveOfWaveNums ) )
		
		if ( WaveExists( $GetDataFolder( 1 ) + waveOfWaveNums ) )
			waveOfWaveNums = GetDataFolder( 1 ) + waveOfWaveNums
		else
			NMDoAlert( thisfxn + " Abort: cannot locate wave of wave numbers : " + waveOfWaveNums )
			return ""
		endif
		
	endif
	
	if ( !WaveExists( $waveOfEventTimes ) )
		
		if ( WaveExists( $GetDataFolder( 1 ) + waveOfEventTimes ) )
			waveOfEventTimes = GetDataFolder( 1 ) + waveOfEventTimes
		else
			NMDoAlert( thisfxn + " Abort: cannot locate wave of event times : " + waveOfEventTimes )
			return ""
		endif
		
	endif
	
	return NMEventsToWaves( waveOfWaveNums, waveOfEventTimes, xwinBefore, xwinAfter, stopAtNextEvent, allowTruncatedEvents, chanNum, outputWavePrefix )
	
End // NMEvents2Waves

//****************************************************************
//****************************************************************
//****************************************************************

Function EventHistoCall()

	Variable icnt
	
	String yUnits, subfolder, suffix, tableList, table
	String wName = "", waveOfWaveNums, waveOfEventTimes, wList, wList2 
	String thisfxn = GetRTStackInfo( 1 )
	
	String histoType = NMEventStrGet( "HistoSelect" )
	
	String tableSelect = CurrentNMEventTableSelect()
	
	Variable rejections = NMEventRejectsOn()
	
	Variable repetitions = 0
	Variable binSize = 1
	Variable xbgn = -inf
	Variable xend = inf
	Variable minInterval = 0
	Variable maxInterval = inf
	
	tableList = NMSubfolderList2( "", "Event_", 0, 0 ) + NMEventTableOldListAll()
	
	wList2 = WaveList( "EV_ThreshT*", ";", "" )
	wList = wList2
	
	for ( icnt = 0 ; icnt < ItemsInList( wList2 ) ; icnt += 1 )
	
		wName = StringFromList( icnt, wList2 )
		
		if ( strsearch( wName, "_intvl", 0, 2 ) > 0 )
			wList = RemoveFromList( wName, wList )
		endif
		
	endfor
	
	if ( ( ItemsInList( tableList ) == 0 ) && ( ItemsInList( wList ) == 0 ) )
	
		NMDoAlert( thisfxn + " Abort: detected no event waves." )
		
		return -1
		
	endif
	
	if ( ItemsInList( tableList ) > 0 )
	
		table = CurrentNMEventTableSelect()
		
		if ( WhichListItem( table, tableList ) < 0 )
			table = StringFromList( 0, tableList )
		endif
		
		if ( ItemsInList( wList ) > 0 )
			wList = " ;" + wList
		endif
		
		wName = ""
		
	else
	
		table = ""
		
		wName = NMEventTableWaveName( "ThreshT" )
		
		if ( !WaveExists( $wName ) && ( ItemsInList( wList ) > 0 ) )
			wName = StringFromList( 0, wList )
		endif
	
	endif
	
	Prompt table, "select event table:", popup tableList
	Prompt wName, "or select wave of event times:", popup wList
	Prompt histoType, "historgram type:", popup "time;interval;"
	
	Prompt xbgn, NMPromptAddUnitsX( "include events from" )
	Prompt xend, NMPromptAddUnitsX( "include events to" )
	Prompt minInterval, NMPromptAddUnitsX( "minimum interval allowed" )
	Prompt maxInterval, NMPromptAddUnitsX( "maximum interval allowed" )
	
	Prompt binSize, NMPromptAddUnitsX( "histogram bin size" )
	
	if ( ItemsInList( wList ) > 0 )
		DoPrompt "Event Histogram", table, wName, histoType
	else
		DoPrompt "Event Histogram", table, histoType
	endif
	
	if ( V_flag == 1 )
		return 0 // cancel
	endif
	
	SetNMstr( NMEventDF + "HistoSelect", histoType )
	
	if ( StringMatch( table, tableSelect ) )
	
		waveOfEventTimes = "_selected_"
		waveOfWaveNums = "_selected_"
		
	else
	
		wList = NMEventCallWaveNames( thisfxn, table, wName, rejections=rejections )
		
		if ( ItemsInList( wList ) == 0 )
			return 0 // cancel
		endif
		
		waveOfWaveNums = StringFromList( 0, wList )
		waveOfEventTimes = StringFromList( 1, wList )
		
	endif
	
	strswitch( histoType )
			
		case "time":
		
			yUnits = "Events / bin"
			
			Prompt yUnits, "y-axis:" popup "Events / bin;Events / sec;Probability;"
			Prompt repetitions, "verifiy events were collected from this number of waves:"
			
			DoPrompt "Event Histogram", binSize, xbgn, xend, yUnits
			
			if ( V_flag == 1 )
				break
			endif
			
			strswitch( yUnits )
			
				case "Events / sec":
				case "Probability":
			
					if ( WaveExists( $waveOfWaveNums ) ) 
						repetitions = EventRepsCount( waveOfWaveNums ) // get number of waves
					endif
					
					DoPrompt "Event Time Histogram", repetitions
					
					if ( V_flag == 1 )
						break
					endif
					
					if ( repetitions < 1 )
						NMDoAlert( thisfxn + " Abort: bad number of waves: " + num2str( repetitions ) )
						return -1
					endif
				
			endswitch
			
			NMEventHistogram( waveOfEventTimes = waveOfEventTimes, repetitions = repetitions, xbgn = xbgn, xend = xend, binSize = binSize, yUnits = yUnits, history = 1 )
			
			break
			
		case "interval":
			
			DoPrompt "Event Interval Histogram", binSize, xbgn, xend, minInterval, maxInterval
			
			if ( V_flag == 1 )
				break
			endif
			
			NMEventIntervalHistogram( waveOfEventTimes = waveOfEventTimes, xbgn = xbgn, xend = xend, minInterval = minInterval, maxInterval = maxInterval, binSize = binSize, history = 1 )
			
			break
			
	endswitch

End // EventHistoCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventHistogram( [ waveOfEventTimes, repetitions, xbgn, xend, binSize, yUnits, history ] )
	String waveOfEventTimes // wave of event times
	Variable repetitions // number of repetitions ( number of waves )
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all time
	Variable binSize // histo bin size
	String yUnits // y-axis dimensions, "Events/bin" or "Events/sec" or "Probability"
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable nbins
	String hName, gPrefix, gName, gTitle, sName, path, xLabel, wList, vlist = ""
	String thisfxn = GetRTStackInfo( 1 )
	
	Variable rejections = NMEventRejectsOn()
	
	if ( ParamIsDefault( waveOfEventTimes ) )
		waveOfEventTimes = ""
	else
		vlist = NMCmdStrOptional( "waveOfEventTimes",  waveOfEventTimes, vlist )
	endif
	
	if ( ParamIsDefault( repetitions ) )
		repetitions = NaN
	else
		vlist = NMCmdNumOptional( "repetitions",  repetitions, vlist, integer = 1 )
	endif
	
	if ( ParamIsDefault( xbgn ) )
		xbgn = -inf
	else
		vlist = NMCmdNumOptional( "xbgn",  xbgn, vlist )
	endif
	
	if ( ParamIsDefault( xend ) )
		xend = inf
	else
		vlist = NMCmdNumOptional( "xend",  xend, vlist )
	endif
	
	if ( ParamIsDefault( binSize ) )
		binSize = 1
	else
		vlist = NMCmdNumOptional( "binSize",  binSize, vlist )
	endif
	
	if ( ParamIsDefault( yUnits ) )
		yUnits = "Events/bin"
	else
		vlist = NMCmdStrOptional( "yUnits",  yUnits, vlist )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( ( strlen( waveOfEventTimes ) == 0 ) || StringMatch( waveOfEventTimes, "_selected_" ) )
	
		wList = NMEventCallWaveNames( thisfxn, CurrentNMEventTableSelect(), "", rejections=rejections )
		
		if ( ItemsInList( wList ) == 0 )
			return ""
		endif
		
		waveOfEventTimes = StringFromList( 1, wList )
	
	endif
	
	if ( !WaveExists( $waveOfEventTimes ) )
		
		if ( WaveExists( $GetDataFolder( 1 ) + waveOfEventTimes ) )
			waveOfEventTimes = GetDataFolder( 1 ) + waveOfEventTimes
		else
			NMDoAlert( thisfxn + " Abort: cannot locate wave of event times : " + waveOfEventTimes )
			return ""
		endif
		
	endif
	
	strswitch( yUnits )
		case "Events/bin":
		case "Events / bin":
			break
		case "Events/sec":
		case "Events / sec":
		case "Probability":
			if ( ( numtype( repetitions ) > 0 ) || ( repetitions < 1 ) )
				NM2Error( 10, "repetitions", num2str( repetitions ) )
				return ""
			endif
	endswitch
	
	if ( ( numtype( binSize ) > 0 ) || ( binSize <= 0 ) )
		NM2Error( 10, "binSize", num2str( binSize ) )
		return ""
	endif
	
	if ( numtype( xbgn ) > 0 )
		xbgn = -inf
	endif
	
	if ( numtype( xend ) > 0 )
		xend = inf
	endif
	
	xLabel = NMNoteLabel( "y", waveOfEventTimes, "" )
	
	sName = NMChild( waveOfEventTimes )
	path = NMParent( waveOfEventTimes )
	hName = NextWaveName2( "", sName + "_hist", -1, Overwrite )
	gPrefix = sName + "_" + CurrentNMFolderPrefix() + "PSTH"
	gName = NextGraphName( gPrefix, -1, 0 ) // no overwrite, due to long name
	gTitle = NMFolderListName( "" ) + " : " + sName + " Histogram"
	
	hName = path + hName
	
	Make /D/O/N=1 $hName
	
	WaveStats /Q/Z $waveOfEventTimes
	
	nbins = ceil( ( V_max - V_min ) / binSize )
	
	Histogram /B={V_min, binSize, nbins} $waveOfEventTimes, $hName
	
	if ( !WaveExists( $hName ) )
		return ""
	endif
	
	wave histo = $hName
	
	strswitch( yUnits )
		case "Events/bin":
		case "Events / bin":
			break
		case "Events/sec":
		case "Events / sec":
			histo /= repetitions * binSize * 0.001
			break
		case "Probability":
			histo /= repetitions
			break
	endswitch
	
	NMGraph( wList = hName, gName = gName, gTitle = gTitle, xLabel = xLabel, yLabel = yUnits )
	
	ModifyGraph /W=$gName mode=5, hbFill=2
	
	NMNoteType( hName, "NMEventHisto", xLabel, yUnits, "_FXN_" )
	
	Note $hName, "Histo Bin:" + num2str( binSize ) + ";Histo Xbgn:" + num2str( xbgn ) + ";Histo Xend:" + num2str( xend ) + ";"
	Note $hName, "Histo Source:" + waveOfEventTimes
	
	return hName
	
End // NMEventHistogram
	
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventIntervalHistogram( [ waveOfEventTimes, xbgn, xend, minInterval, maxInterval, binSize, history ] )
	String waveOfEventTimes // wave of event times
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	Variable minInterval // minimum allowed interval ( 0 ) for no lower limit
	Variable maxInterval // maximum allowed interval ( inf ) for no upper limit
	Variable binSize // histo bin size
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable icnt, nbins
	String hName, gPrefix, gName, gTitle, sName, path, xLabel, yUnits, wList, vlist = ""
	String thisfxn = GetRTStackInfo( 1 )
	
	Variable rejections = NMEventRejectsOn()
	
	if ( ParamIsDefault( waveOfEventTimes ) )
		waveOfEventTimes = ""
	else
		vlist = NMCmdStrOptional( "waveOfEventTimes",  waveOfEventTimes, vlist )
	endif
	
	if ( ParamIsDefault( xbgn ) )
		xend = -inf
	else
		vlist = NMCmdNumOptional( "xbgn",  xbgn, vlist )
	endif
	
	if ( ParamIsDefault( xend ) )
		xend = inf
	else
		vlist = NMCmdNumOptional( "xend",  xend, vlist )
	endif
	
	if ( ParamIsDefault( minInterval ) )
		minInterval = 0
	else
		vlist = NMCmdNumOptional( "minInterval",  minInterval, vlist )
	endif
	
	if ( ParamIsDefault( maxInterval ) )
		maxInterval = inf
	else
		vlist = NMCmdNumOptional( "maxInterval",  maxInterval, vlist )
	endif
	
	if ( ParamIsDefault( binSize ) )
		binSize = 1
	else
		vlist = NMCmdNumOptional( "binSize",  binSize, vlist )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( ( strlen( waveOfEventTimes ) == 0 ) || StringMatch( waveOfEventTimes, "_selected_" ) )
	
		wList = NMEventCallWaveNames( thisfxn, CurrentNMEventTableSelect(), "", rejections=rejections )
		
		if ( ItemsInList( wList ) == 0 )
			return ""
		endif
		
		waveOfEventTimes = StringFromList( 1, wList )
	
	endif
	
	if ( !WaveExists( $waveOfEventTimes ) )
		
		if ( WaveExists( $GetDataFolder( 1 ) + waveOfEventTimes ) )
			waveOfEventTimes = GetDataFolder( 1 ) + waveOfEventTimes
		else
			NMDoAlert( thisfxn + " Abort: cannot locate wave of event times : " + waveOfEventTimes )
			return ""
		endif
		
	endif
	
	yUnits = "Intvls / bin"
	xLabel = NMNoteLabel( "y", waveOfEventTimes, "" )
	
	if ( numtype( xbgn ) > 0 )
		xbgn = -inf
	endif
	
	if ( numtype( xend ) > 0 )
		xend = inf
	endif
	
	if ( numtype( minInterval ) > 0 )
		minInterval = 0
	endif
	
	if ( numtype( maxInterval ) > 0 )
		maxInterval = inf
	endif
	
	Variable events = Time2Intervals( waveOfEventTimes, xbgn, xend, minInterval, maxInterval ) // results saved in U_INTVLS ( function in Utility.ipf )

	if ( events <= 0 )
		NMDoAlert( thisfxn + "Abort: no inter-event intervals detected." )
		return ""
	endif
	
	if ( !WaveExists( $"U_INTVLS" ) )
		return ""
	endif
	
	Wave U_INTVLS
	
	sName = NMChild( waveOfEventTimes )
	path = NMParent( waveOfEventTimes )
	hName = NextWaveName2( "", sName + "_intvl", -1, Overwrite )
	gPrefix = sName + "_" + CurrentNMFolderPrefix() + "ISIH"
	gName = NextGraphName( gPrefix, -1, 0 ) // no overwrite, due to long name
	gTitle = NMFolderListName( "" ) + " : " + sName + " Interval Histogram"
	
	hName = path + hName

	Make /D/O/N=1 $hName
	
	WaveStats /Q/Z U_INTVLS
	
	nbins = ceil( ( V_max - minInterval ) / binSize )
	
	Histogram /B={minInterval, binSize, nbins} U_INTVLS, $hName
	
	if ( !WaveExists( $hName ) )
		return ""
	endif
	
	Wave histo = $hName
	
	for ( icnt = numpnts( histo ) - 1; icnt >= 0; icnt -= 1 )
		if ( histo[ icnt ] > 0 )
			break
		elseif ( histo[ icnt ] == 0 )
			histo[ icnt ] = Nan
		endif
	endfor
	
	WaveStats /Q/Z histo
	
	Redimension /N=( V_npnts ) histo
	
	NMGraph( wList = hName, gName = gName, gTitle = gTitle, xLabel = xLabel, yLabel = yUnits )
		
	ModifyGraph /W=$gName mode=5, hbFill=2
		
	WaveStats /Q/Z U_INTVLS
	
	SetAxis /W=$gName bottom 0, ( V_max*1.1 )
	
	NMNoteType( hName, "NMEventIntvlHisto", xLabel, yUnits, "_FXN_" )
	
	Note $hName, "Intvl Bin:" + num2str( binSize ) + ";Intvl Xbgn:" + num2str( xbgn ) + ";Intvl Xend:" + num2str( xend ) + ";"
	Note $hName, "Intvl Min:" + num2str( minInterval ) + ";Intvl Max:" + num2str( maxInterval ) + ";"
	Note $hName, "Intvl Source:" + waveOfEventTimes
	
	Print NMCR + "Intervals stored in wave U_INTVLS"
	
	return hName

End // NMEventIntervalHistogram

//****************************************************************
//****************************************************************
//****************************************************************

Menu "GraphMarquee"

	NMEventGraphMarqueeMenuStr( "-" )
	
	NMEventGraphMarqueeMenuStr( "reject" ), NMEventMarqueeReject()
	NMEventGraphMarqueeMenuStr( "find" ), NMEventMarqueeFind()
	NMEventGraphMarqueeMenuStr( "save" ), NMEventMarqueeSaveByCursors()
	
End // GraphMarquee

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventGraphMarqueeMenuStr( menuStr )
	String menuStr
	
	if ( !IsCurrentNMTab( "Event" ) )
		return ""
	endif
	
	if ( !StringMatch( WinName( 0, 1 ), ChanGraphName( -1 ) ) )
		return ""
	endif

	Variable events = NumVarOrDefault( NMEventDF + "NumEvents", 0 )
	Variable reviewFlag = NMEventVarGet( "ReviewFlag" )

	if ( events > 0 )
	
		if ( reviewFlag == 2 )
			return ""
		endif
	
		strswitch( menuStr )
			case "reject":
				return "NM reject events inside marquee"
			case "find":
				return "NM find event inside marquee"
			case "save":
				return "NM save cursors as an event"
			default:
				return menuStr
		endswitch
		
	endif
	
	return ""

End // NMEventGraphMarqueeMenuStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventMarqueeFind() // use marquee x-values for event xbgn and xend

	Variable xbgn, xend, icnt, waveNum, found
	String gName

	if ( !DataFolderExists( NMEventDF ) || !IsCurrentNMTab( "Event" ) )
		return 0 
	endif

	GetMarquee /K left, bottom
	
	if ( V_Flag == 0 )
		return 0
	endif
	
	xbgn = V_left
	xend = V_right
	
	gName = S_marqueeWin
	
	if ( !StringMatch( gName, ChanGraphName( -1 ) ) )
		return -1
	endif
	
	if ( !WaveExists( $NMEventTableWaveName( "ThreshY" ) ) )
		return -1
	endif
	
	found = EventFindNext( 1, xbgn = xbgn, xend = xend, eventFlag = 0 )
	
	if ( found != 0 )
		DoAlert 0, "Found no event inside marquee window."
		return -1
	endif
	
	DoAlert 1, "Add detected event to table?"
	
	if ( V_Flag != 1 )
		return 0 // cancel
	endif
	
	EventSave()
	
	return 0

End // NMEventMarqueeFind

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventMarqueeSaveByCursors() // use marquee x-values for event xbgn and xend

	Variable xbgn, xend, icnt, npnts, baseY = NaN
	Variable threshX = NaN, threshY = NaN, onsetX = NaN, onsetY = NaN, peakX = NaN, peakY = NaN
	String gName, dName
	
	if ( !DataFolderExists( NMEventDF ) || !IsCurrentNMTab( "Event" ) )
		return 0 
	endif

	GetMarquee /K left, bottom
	
	if ( V_Flag == 0 )
		return 0
	endif
	
	xbgn = V_left
	xend = V_right
	
	gName = S_marqueeWin
	
	if ( !StringMatch( gName, ChanGraphName( -1 ) ) )
		return -1
	endif
	
	if ( !WaveExists( $NMEventTableWaveName( "ThreshY" ) ) )
		return -1
	endif
	
	Variable searchMethod = NMEventVarGet( "SearchMethod" )
	Variable baseWin = NMEventVarGet( "BaseWin" )
	
	if ( strlen( CsrInfo( A, gName ) ) > 0 )
	
		if ( strlen( CsrInfo( B, gName ) ) > 0 )
		
			onsetX = xcsr( A, gName )
			onsetY = vcsr( A, gName )
			peakX = xcsr( B, gName )
			peakY = vcsr( B, gName )
			
			dName = ChanDisplayWave( -1 )
			
			Wave wtemp = $dName
			
			switch( searchMethod )
		
				case 1: // Level+
				
					threshY = NMEventVarGet( "SearchLevel" )
					FindLevel /EDGE=1/P/Q/R=( onsetX, peakX ) wtemp, threshY
					
					threshX = NaN
					threshY = NaN
					
					if ( V_flag == 0 )
					
						threshX = pnt2x( wtemp, V_LevelX )
						
						if ( ( V_LevelX >= 0 ) && ( V_LevelX < numpnts( wtemp ) ) )
							threshY = wtemp[ V_LevelX ]
						endif
						
					endif
					
					break
					
				case 2: // Level-
					
					threshY = NMEventVarGet( "SearchLevel" )
					FindLevel /EDGE=2/P/Q/R=( onsetX, peakX ) wtemp, threshY
					
					threshX = NaN
					threshY = NaN
					
					if ( V_flag == 0 )
					
						threshX = pnt2x( wtemp, V_LevelX )
						
						if ( ( V_LevelX >= 0 ) && ( V_LevelX < numpnts( wtemp ) ) )
							threshY = wtemp[ V_LevelX ]
						endif
						
					endif
					
					break
					
				case 3: // thresh > baseline
				
					Wavestats /Q/R=( onsetX - baseWin, onsetX ) wtemp
					baseY = V_avg
					threshY = baseY + NMEventVarGet( "SearchThreshold" )
					FindLevel /EDGE=1/P/Q/R=( onsetX, peakX ) wtemp, threshY
					
					threshX = NaN
					threshY = NaN
					
					if ( V_flag == 0 )
					
						threshX = pnt2x( wtemp, V_LevelX )
						
						if ( ( V_LevelX >= 0 ) && ( V_LevelX < numpnts( wtemp ) ) )
							threshY = wtemp[ V_LevelX ]
						endif
						
					endif
					
					break
					
				case 4: // thresh < baseline
				
					Wavestats /Q/R=( onsetX - baseWin, onsetX ) wtemp
					baseY = V_avg
					threshY = baseY - NMEventVarGet( "SearchThreshold" )
					FindLevel /EDGE=2/P/Q/R=( onsetX, peakX ) wtemp, threshY
					
					threshX = NaN
					threshY = NaN
					
					if ( V_flag == 0 )
					
						threshX = pnt2x( wtemp, V_LevelX )
						
						if ( ( V_LevelX >= 0 ) && ( V_LevelX < numpnts( wtemp ) ) )
							threshY = wtemp[ V_LevelX ]
						endif
						
					endif
					
					break
					
				case 5: // Nstdv > baseline
				
					Wavestats /Q/R=( onsetX - baseWin, onsetX ) wtemp
					baseY = V_avg
					threshY = baseY + NMEventVarGet( "SearchNstdv" ) * V_sdev
					FindLevel /EDGE=1/P/Q/R=( onsetX, peakX ) wtemp, threshY
					
					threshX = NaN
					threshY = NaN
					
					if ( V_flag == 0 )
					
						threshX = pnt2x( wtemp, V_LevelX )
						
						if ( ( V_LevelX >= 0 ) && ( V_LevelX < numpnts( wtemp ) ) )
							threshY = wtemp[ V_LevelX ]
						endif
						
					endif
					
					break
					
				case 6: // // Nstdv < baseline
				
					Wavestats /Q/R=( onsetX - baseWin, onsetX ) wtemp
					baseY = V_avg
					threshY = baseY - NMEventVarGet( "SearchNstdv" ) * V_sdev
					FindLevel /EDGE=2/P/Q/R=( onsetX, peakX ) wtemp, threshY
					
					threshX = NaN
					threshY = NaN
					
					if ( V_flag == 0 )
					
						threshX = pnt2x( wtemp, V_LevelX )
						
						if ( ( V_LevelX >= 0 ) && ( V_LevelX < numpnts( wtemp ) ) )
							threshY = wtemp[ V_LevelX ]
						endif
					
					endif
					
					break
					
			endswitch
		
		else
		
			threshX = xcsr( A, gName )
			threshY = vcsr( A, gName )
		
		
		endif
		
	elseif ( strlen( CsrInfo( B, gName ) ) > 0 )
	
		threshX = xcsr( B, gName )
		threshY = vcsr( B, gName )
		
	else
	
		DoAlert 0, "Abort NMEventMarqueeSave : found no cursor inside marquee."
		return -1
		
	endif
	
	if ( numtype( threshX * threshY ) > 0 )
		DoAlert 0, "Abort NMEventMarqueeSave : failed to find threshold value."
		return -1
	endif
	
	if ( ( threshX < xbgn ) || ( threshX > xend ) )
		DoAlert 0, "Abort NMEventMarqueeSave : found no cursor inside marquee."
		return -1
	endif
	
	SetNMvar( NMEventDF + "ThreshX", threshX )
	SetNMvar( NMEventDF + "ThreshY", threshY )
	
	SetNMvar( NMEventDF + "OnsetX", onsetX )
	SetNMvar( NMEventDF + "OnsetY", onsetY )
	SetNMvar( NMEventDF + "PeakX", peakX )
	SetNMvar( NMEventDF + "PeakY", peakY )
	
	SetNMvar( NMEventDF + "BaseY", baseY )
	
	SetNMvar( NMEventDF + "FoundEventFlag", 1 )
	
	EventSave()

End // NMEventMarqueeSaveByCursors

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventMarqueeReject() // use marquee x-values for event xbgn and xend

	Variable xbgn, xend, icnt, ibgn = inf, iend = -inf
	Variable waveNum, events, rejections, error, pflag
	String gName
	
	Variable saveRejected = NMEventVarGet( "SaveRejected" )
	
	if ( !DataFolderExists( NMEventDF ) || !IsCurrentNMTab( "Event" ) )
		return 0 
	endif

	GetMarquee /K left, bottom
	
	if ( V_Flag == 0 )
		return 0
	endif
	
	xbgn = V_left
	xend = V_right
	
	gName = S_marqueeWin
	
	if ( !StringMatch( gName, ChanGraphName( -1 ) ) )
		return -1
	endif
	
	rejections = NMEventRejectsOn()
	
	if ( !WaveExists( $NMEventTableWaveName( "ThreshY", rejections = rejections ) ) )
		return -1
	endif
	 
	Wave wvN = $NMEventTableWaveName( "WaveN", rejections = rejections )
	Wave thT = $NMEventTableWaveName( "ThreshT", rejections = rejections )
	Wave thY = $NMEventTableWaveName( "ThreshY", rejections = rejections )
	Wave onT = $NMEventTableWaveName( "OnsetT", rejections = rejections )
	Wave onY = $NMEventTableWaveName( "OnsetY", rejections = rejections )
	Wave pkT = $NMEventTableWaveName( "PeakT", rejections = rejections )
	Wave pkY = $NMEventTableWaveName( "PeakY", rejections = rejections )
	Wave bsY = $NMEventTableWaveName( "BaseY", rejections = rejections )
	Wave ampY = $NMEventTableWaveName( "AmpY", rejections = rejections )
	
	waveNum = CurrentNMWave()
	
	for ( icnt = numpnts( wvN ) - 1 ; icnt >= 0 ; icnt -= 1 )
	
		if ( ( wvN[ icnt ] == waveNum ) && ( thT[ icnt ] > xbgn ) && ( thT[ icnt ] < xend ) )
		
			events += 1
			
			ibgn = min( ibgn, icnt )
			iend = max( iend, icnt )
			
		endif
		
	endfor
	
	if ( events > 0 )
	
		if ( events == 1 )
			DoAlert 1, "Located " + num2istr( events ) + " event inside marquee. Do you wish to reject it?"
		else
			DoAlert 1, "Located " + num2istr( events ) + " events inside marquee. Do you wish to reject them?"
		endif
		
		if ( V_Flag != 1 )
			return 0 // cancel
		endif
		
	else
	
		DoAlert 0, "Located no events inside marquee."
	
		return 0
		
	endif
	
	events = 0
	
	for ( icnt = iend ; icnt >= ibgn ; icnt -= 1 )
	
		if ( ( wvN[ icnt ] == waveNum ) && ( thT[ icnt ] > xbgn ) && ( thT[ icnt ] < xend ) )
			
			if ( rejections )
			
				error = EventDelete( wvN[ icnt ], thT[ icnt ], rejections = 1, noAlert = 1 )
				
			else
			
				if ( saveRejected )
					EventRetrieve( icnt )
					pflag = EventSaveCurrent( 0, rejections = 1, noAlert = 1 )
				endif
			
				error = EventDelete( wvN[ icnt ], thT[ icnt ], rejections = 0, noAlert = 1 )
				
			endif
			
			if ( error == 0 )
				events += 1
			endif
			
		endif
		
	endfor
	
	if ( events == 1 )
		NMHistory( "Rejected " + num2str( events ) + " event" )
	else
		NMHistory( "Rejected " + num2str( events ) + " events" )
	endif
	
	EventCount( updateDisplay = 1, rejections = rejections )
	UpdateEventDisplay( clearCurrentEventDisplay = 1 )

End // NMEventMarqueeReject

//****************************************************************
//****************************************************************
//****************************************************************

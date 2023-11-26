#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma version = 3.0
#pragma hide = 1
#pragma IgorVersion = 6.3

//****************************************************************
//****************************************************************
//
//	NeuroMatic: data aquisition, analyses and simulation software that runs with the Igor Pro environment
//	Copyright (C) 2019 Jason Rothman
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
//	http://www.neuromatic.thinkrandom.com
//	https://github.com/SilverLabUCL/NeuroMatic
//
//****************************************************************
//****************************************************************
//
//	Main Functions
//
//	Set and Get functions:
//		
//		NMSet( [ on, tab, folder, wavePrefix, wavePrefixNoPrompt, PrefixSelectPrompt, OrderWavesBy, waveNum, waveInc, chanSelect, waveSelect, xProgress, yProgress, winCascade, configsDisplay, errorPointsLimit, openPath, savePath, history ] )
//		NMConfigVarSet( "NM" , varName, value )
//		NMConfigStrSet( "NM", strVarName, strValue )
//		NMVarGet( varName )
//		NMStrGet( strVarName )
//
//	Useful Functions:
//
//		NMTabAdd( tabName, tabprefix [ history ] )
//		NMTabRemove( tabName [ history ] )
//		NMTabKill( tabName [ history ] )
//		
//****************************************************************
//****************************************************************

StrConstant NMPackage = "NeuroMatic"
StrConstant NMVersionStr = "3.0s"
Static StrConstant NMHTTP = "http://www.neuromatic.thinkrandom.com/"
Static StrConstant NMRights = "Copyright (c) 2024 The Silver Lab, UCL"
Static StrConstant NMEmail = "Jason@ThinkRandom.com"
Static StrConstant NMUCL = "UCL Neuroscience, Physiology and Pharmacology Department, London, UK"

StrConstant NMDF = "root:Packages:NeuroMatic:"
StrConstant NMClampDF = "root:Packages:NeuroMatic:Clamp:"
StrConstant NMWavePrefixList = "Record;Wave;NMWave;Avg_;Pulse_;ST_;SP_;EV_;Fit_;Histo_;Sort_;Sim_;ROI;"
StrConstant NMXscalePrefix = "xScale_"
StrConstant NMTabList = "Main;Stats;Spike;Event;Fit;"

StrConstant NMRedStr = "52224,0,0"
StrConstant NMGreenStr = "0,39168,0"
StrConstant NMBlueStr = "0,0,65535"

StrConstant NMWinColor = "51000,51000,51000" // background color of panel and graphs
//StrConstant NMWinColor2 = "47616,53760,59904" // highlight color of panel and graphs
StrConstant NMWinColor2 = "47360,40960,40704" // highlight color of panel and graphs
//StrConstant NMWinColor2 = "59904,40448,0" // highlight color of panel and graphs
//StrConstant NMWinColor2 = "16384,32768,32768" // highlight color of panel and graphs

Static Constant NMAutoStart = 1 // auto start NM ( 0 ) no ( 1 ) yes

Static Constant NMHideProcedureFiles = 1

Static Constant MakeNMPanelOnFolderChange = 0
// JSR: this parameter is for a bug fix, when set to 1. cannot remember what bug is. however this fix causes annoying flashing of NM panel.
// 7 Aug 2019, setting to 0. perhaps with latest Igor version this is not necessary.

Static Constant NMPanelResolution = 72 // for Windows OS // NM Panel was designed for 72 panel resolution
// NM uses this parameter to execute the following Igor command: SetIgorOption PanelResolution = <resolution>
// 0:	Coordinates and sizes are treated as points regardless of the screen resolution.
// 1:	Coordinates and sizes are treated as pixels if the screen resolution is 96 DPI, points otherwise. This is the default setting in effect when Igor starts.
// 72:	Coordinates and sizes are treated as pixels regardless of the screen resolution (Igor6 mode).

Constant NMBaselineXbgn = 0 // default x-scale baseline window begin
Constant NMBaselineXend = 10 // default x-scale baseline window end

StrConstant NMXunits = "ms"

Constant NMPrefixFolderHistory = 0 // ( 0 ) do not include ( 1 ) include current prefix folder name in command history

Static Constant NMErrorPointsLimit = 200 // default value

Static Constant NMCascadeWidthPC = 425 // window width for PCs
Static Constant NMCascadeHeightPC = 275 // window height for PCs

Static Constant NMCascadeWidthMac = 525 // window width for Macs
Static Constant NMCascadeHeightMac = 340 // window height for Macs

Static Constant NMCascadeIncPC = 15 // window cascade increment PCs
Static Constant NMCascadeIncMac = 28 // window cascade increment Macs

Static Constant NMKillWinNoDialog = 1 // kill window ( 0 ) with dialog ( 1 ) without dialog

Static Constant NMHistogramPaddingBins = 4 // extra bins on each side of histogram ( auto bin sizing )

Static Constant ConfigsEditByPrompt = 1 // edit configs ( 0 ) directly via listbox ( 1 ) by user prompts

Static StrConstant NMDeprecationIPF = "NM_Deprecated.ipf"

//****************************************************************
//****************************************************************

Function NMVersionNum()

	String versionStr = NMVersionStr
	
	Variable ilength = strlen( versionStr )

	String numStr = versionStr[ 0, ilength-2 ]
	String suffix = num2istr( char2num( versionStr[ ilength-1, ilength-1 ] ) ) // convert last character to ascii code

	return str2num( numStr + suffix ) 

End // NMVersionNum

//****************************************************************
//****************************************************************

Function NMWebpage()

	BrowseURL /Z NMHTTP

End // NMWebpage

//****************************************************************
//****************************************************************

Function NMContact()

	Print "Send email inquiries to " + NMEmail
	
	DoAlert 0, "Send email inquiries to " + NMEmail

End // NMContact

//****************************************************************
//****************************************************************

Function /S NMversion( [ short ] )
	Variable short
	
	if ( short )
		return "NeuroMatic v" + NMVersionStr
	else
		return "NeuroMatic version " + NMVersionStr + " (" + num2str( NMVersionNum() ) + ")"
	endif

End // NMversion

//****************************************************************
//****************************************************************

Function NMAbout()

	NMHistory( NMCR )
	NMHistory( NMversion( short=1 ) + " " + NMRights )
	//NMHistory( NMUCL )
	NMHistory( NMEmail )
	NMHistory( NMHTTP )
	NMHistory( NMCR )
	NMGNUGPL()
	NMHistory( NMCR )
	NMCitation()
	//NMWarranty()
	
	//DoAlert 0, version

End // NMAbout

//****************************************************************
//****************************************************************

Function NMGNUGPL()

	NMHistory( "This program comes with ABSOLUTELY NO WARRANTY. This is free software, " )
	NMHistory( "and you are welcome to redistribute it under certain conditions." )
	NMHistory( "For more information see LICENSE.txt inside NeuroMatic's procedure folder." )
	
End // NMGNUGPL

//****************************************************************
//****************************************************************

Function NMWarranty()

	NMHistory( "THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY" )
	NMHistory( "APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT" )
	NMHistory( "HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM " + NMQuotes( "AS IS" ) + " WITHOUT WARRANTY" )
	NMHistory( "OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO," )
	NMHistory( "THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR" )
	NMHistory( "PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM" )
	NMHistory( "IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF" )
	NMHistory( "ALL NECESSARY SERVICING, REPAIR OR CORRECTION." )

End // NMWarranty

//****************************************************************
//****************************************************************

Function NMCitation()

	NMHistory( "Please support NeuroMatic by citing the following Frontiers article:" )
	NMHistory( "Rothman JS and Silver RA." )
	NMHistory( "NeuroMatic: An Integrated Open-Source Software Toolkit for Acquisition, Analysis and Simulation of Electrophysiological Data." )
	NMHistory( "Front Neuroinform. 2018 Apr 4;12:14." )
	NMHistory( "https://doi.org/10.3389/fninf.2018.00014" )

End // NMCitation

//****************************************************************
//****************************************************************
//
//	Package Functions
//
//****************************************************************
//****************************************************************

Function /S NMPackageDF( subfolderName )
	String subfolderName
	
	if ( StringMatch( subfolderName, NMPackage ) )
		return NMDF
	endif
	
	return LastPathColon( NMDF + subfolderName, 1 )
	
End // NMPackageDF

//****************************************************************
//****************************************************************

Function CheckNMPackageDF( subfolderName ) // check Package data folder exists
	String subfolderName // subfolder
	
	if ( !DataFolderExists( "root:Packages:" ) )
		NewDataFolder root:Packages
	endif
	
	if ( !DataFolderExists( NMDF ) )
		NewDataFolder $RemoveEnding( NMDF, ":" )
	endif
	
	if ( !DataFolderExists( NMDF + "Configurations:" ) )
		NewDataFolder $NMDF + "Configurations"
	endif
	
	if ( ( strlen( subfolderName ) == 0 ) || StringMatch( subfolderName, NMPackage ) )
		return 0
	endif

	if ( ( strlen( subfolderName ) > 0 ) && !DataFolderExists( NMDF + subfolderName + ":" ) )
		NewDataFolder $( NMDF + subfolderName )
		return 1 // yes, made the folder
	endif
	
	return 0 // did not make folder

End // CheckNMPackageDF

//****************************************************************
//****************************************************************

Function CheckNMPackage( package, forceVariableCheck [ update ] ) // check folder / globals
	String package // package folder name
	Variable forceVariableCheck // ( 0 ) no ( 1 ) yes
	Variable update
	
	String fxn, df = NMPackageDF( package )
	
	Variable made = CheckNMPackageDF( package ) // check folder
	
	if ( !made && !forceVariableCheck )
		return 0
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	fxn = "NM" + package + "Check" // e.g. "NMStatsCheck()"
	
	if ( exists( fxn ) != 6 )
		fxn = "Check" + package // e.g. "CheckStats()"
	endif
	
	if ( exists( fxn ) == 6 )
		Execute /Z fxn + "()"
	endif
	
	if ( made )
		NMConfig( package, -1, update = update ) // copy configs to new folder
	else
		NMConfig( package, 1, update = update ) // copy folder vars to configs
	endif
	
	return made
	
End // CheckNMPackage

//****************************************************************
//****************************************************************

Function CheckNMPackageFormat6()

	Variable icnt
	String iName
	
	String moveList = "Configurations;Event;Fit;Import;Main;MyTab;Spike;Stats;Clamp;AMPAR;EPSC;RiseT;Model;"
	String deleteList = "Chan;"
	
	String cdf = ConfigDF( "" )
	
	for ( icnt = 0 ; icnt < ItemsInList( moveList ) ; icnt += 1 )
	
		iName = StringFromList( icnt, moveList )
		
		if ( DataFolderExists( "root:Packages:" + iName + ":" ) )
		
			if ( !DataFolderExists( NMDF + iName + ":" ) )
				MoveDataFolder $( "root:Packages:" + iName ), $NMDF
				//Print "moved " + iName + " package folder to " + NMDF
			endif
			
		endif
		
	endfor
	
	for ( icnt = 0 ; icnt < ItemsInList( deleteList ) ; icnt += 1 )
	
		iName = StringFromList( icnt, deleteList )
		
		if ( DataFolderExists( "root:Packages:" + iName + ":" ) )
			KillDataFolder /Z $"root:Packages:" + iName
		endif
		
		if ( DataFolderExists(cdf + iName + ":" ) )
			KillDataFolder /Z $cdf + iName
		endif
		
	endfor

End // CheckNMPackageFormat6

//****************************************************************
//****************************************************************

Function IgorStartOrNewHook( igorApplicationNameStr )
	String igorApplicationNameStr

	if ( NMAutoStart )
		CheckNMVersion()
	endif
	
End // IgorStartOrNewHook

//****************************************************************
//****************************************************************

Static Function BeforeExperimentSaveHook( refNum, fileNameStr, pathNameStr, fileTypeStr, fileCreatorStr, fileKind )
	Variable refNum
	String fileNameStr, pathNameStr, fileTypeStr, fileCreatorStr
	Variable fileKind
	
	KillNMPaths()
	
	if ( NMConfigsAutoOpenSave )
		NMConfigsSaveToPackages()
	endif
	
	return 0

End // BeforeExperimentSaveHook

//****************************************************************
//****************************************************************

Static Function AfterFileOpenHook( refNum, fileName, path, type, creator, kind )
	Variable refNum
	String fileName, path, type, creator
	Variable kind
	
	if ( NMAutoStart )
		CheckNMVersion()
	endif
	
	if ( StringMatch( type,"IGsU" ) ) // Igor Experiment, packed
		CheckFileOpen( fileName )
	endif
	
	//MakeNMPanel()
	
	return 0
	
End // AfterFileOpenHook

//****************************************************************
//****************************************************************

Static Function IgorBeforeNewHook( igorApplicationNameStr )
	String igorApplicationNameStr
	
	if ( NMConfigsAutoOpenSave )
		NMConfigsSaveToPackages()
	endif
	
End // IgorBeforeNewHook

//****************************************************************
//****************************************************************

Function CheckNMVersion()
	
	String existingVersion = StrVarOrDefault( NMDF + "NMVersionStr", "" )
	
	if ( !StringMatch( existingVersion, NMVersionStr ) )
		return ResetNM( 0, quiet = 1, oldVersionStr = existingVersion )
	endif
	
	return 0

End // CheckNMVersion

//****************************************************************
//****************************************************************

Function ResetNM( killFirst [ quiet, history, oldVersionStr ] ) // use this function to re-initialize neuromatic
	Variable killfirst // kill variables first flag
	Variable history
	String oldVersionStr
	Variable quiet
	
	Variable fatal, deprecations
	String fList, vlist = ""
	
	if ( history )
		vlist = NMCmdNum( killFirst, "", integer = 1 )
		NMCommandHistory( vlist )
	endif
	
	if ( !quiet )
	
		DoAlert /T="NM Alert" 1, "Are you sure you want to re-initialize NM globals?"
		
		if ( V_flag != 1 )
			return 0
		endif
		
	endif
	
	DoWindow /K $NMPanelName
	
	CheckNMPackageFormat6()
	
	//CheckCurrentFolder() // must set this here, otherwise Igor is at root directory // removed
	NMTabControlList()
	
	ChanGraphClose( -2, 0 ) // close all graphs
	
	Execute /Q/Z "CheckClampTab2()" // added this so Clamp Tab is updated for new NM versions
	
	if ( killfirst )
		NMKill() // this is hard kill, and will reset previous global variables to default values
	endif
	
	if ( CheckNM() < 0 )
		return -1
	endif
	
	SetNMvar( NMDF + "CurrentTab", 0 ) // set Main Tab as current tab
	
	CheckNMDataFolders()
	CheckNMFolderList()
	NMChanWaveListSet( 0 )
	
	SetNMstr( NMDF + "NMVersionStr", NMVersionStr )
	SetNMstr( NMDF + "NMMenuLoad", "" )
	
	if ( WinType( NMPanelName ) != 7 )
		MakeNMPanel()
	endif
	
	CheckCurrentFolder()
	
	if ( IsNMDataFolder( "" ) )
		UpdateCurrentWave()
	endif
	
	NMProceduresHideUpdate()
	NMMenuBuild()
	
	if ( ParamIsDefault( oldVersionStr ) || ( strlen( oldVersionStr ) == 0 ) )
		NMHistory( "Initialized " + NMversion( short=1 ) )
	else
		NMHistory( NMCR + "Updated NeuroMatic from version " + oldVersionStr + " to " + NMVersionStr )
	endif
	
	return 0

End // ResetNM

//****************************************************************
//****************************************************************

Function CheckNM()

	Variable madeNMDF
	String ftype
	
	if ( !NMVarGet( "NMon" ) )
		return 1
	endif
	
	if ( !DataFolderExists( NMDF ) )
		madeNMDF = 1
	endif
	
	CheckNMPackageDF( "" )
	
	if ( !DataFolderExists( NMDF ) )
		return -1
	endif
	
	if ( madeNMDF )
		CheckNeuroMatic()
		NMConfig( NMPackage, -1, update = 0 )
	else
		NMConfig( NMPackage, 0, update = 0 )
	endif
	
	NMProgressOn( NMProgFlagDefault() ) // test progress window

	CheckNMPaths()
	CheckFileOpen( "" )
	
	if ( madeNMDF )
	
		if ( NMConfigsAutoOpenSave )
			NMConfigsOpenFromPackages() // Igor Packages
		endif
		
		NMConfigOpenAuto() // configs saved in NM folder
		
		CheckNMPaths()
		
		ftype = StrVarOrDefault( "FileType", "" )
		
		if ( StringMatch( ftype, "NMData" ) )
			UpdateNM( 1 )
		else
			NMFolderNew( "", update = 0 )
		endif
		
	endif
	
	CheckNMPanelResolution()
	
	KillGlobals( "root:", "V_*", "110" ) // clean root directory
	KillGlobals( "root:", "S_*", "110" )
	
	return madeNMDF

End // CheckNM

//****************************************************************
//****************************************************************

Function UpdateNM( forceMakeNewPanel )
	Variable forceMakeNewPanel
	
	Variable isNMfolder
	
	String ftype = StrVarOrDefault( "FileType", "" )
	
	if ( StringMatch( ftype, "NMData" ) )
		isNMfolder = 1
	endif
	
	if ( WinType( NMPanelName ) == 7 )
	
		if ( forceMakeNewPanel && MakeNMPanelOnFolderChange )
			MakeNMPanel()
		else
			UpdateNMPanel( 1 )
		endif
	
	else
	
		// MakeNMPanel() // causes bug
	
	endif
	
	CheckCurrentFolder()
	CheckNMFolderList()
	NMSetsPanelUpdate( 1 )
	NMGroupsPanelUpdate( 1 )
	NMMenuBuild()
	
	if ( isNMfolder )
		UpdateCurrentWave()
	endif
	
End // UpdateNM

//****************************************************************
//****************************************************************

Function NMKill( [ quiet ] ) // use this with caution!
	Variable quiet

	String df
	
	if ( !quiet )
	
		DoAlert /T="NM Alert" 1, "Are you sure you want to kill NeuroMatic from the current experiment?"
		
		if ( V_flag != 1 )
			return 0
		endif
		
	endif

	DoWindow /K $NMPanelName

	KillTabs( NMTabControlList() ) // kill tab plots, tables and globals
	
	ChanGraphClose( -2, 0 ) // close all graphs
	
	if ( DataFolderExists( NMDF ) )
		KillDataFolder $NMDF
	endif
	
	//NMProceduresKill( quiet = 1 )

End // NMKill

//****************************************************************
//****************************************************************

Function NMProceduresHideUpdate()
	
	if ( NMHideProcedureFiles )
		Execute /Q/Z "SetIgorOption IndependentModuleDev = 0"
	else
		Execute /Q/Z "SetIgorOption IndependentModuleDev = 1" // unhide procedures
	endif

End // NMProceduresHideUpdate

//****************************************************************
//****************************************************************

Function NMProceduresHide( hide )
	Variable hide // ( 0 ) no ( 1 ) yes

	if ( hide )
		NMHistory( "SetIgorOption IndependentModuleDev = 0" )
		Execute /Q/Z "SetIgorOption IndependentModuleDev = 0"
	else
		NMMenuProceduresList( "misc", update = 1 ) // update lists of procedure names
		NMHistory( "SetIgorOption IndependentModuleDev = 1" )
		Execute /Q/Z "SetIgorOption IndependentModuleDev = 1" // unhide
	endif
	
	NMMenuBuild()

End // NMProceduresHide

//****************************************************************
//****************************************************************

Function /S NMProceduresList()

	String pList

	Execute /Z "SetIgorOption IndependentModuleDev = ?"
	
	Variable saveIMD = NumVarOrDefault( "V_Flag", NaN )
	
	Execute /Q/Z "SetIgorOption IndependentModuleDev = 1" // unhide procedures
	
	pList = SortList( WinList( "NM_*", ";", "WIN:128" ), ";", 16 ) // all procedures
	
	Execute /Z "SetIgorOption IndependentModuleDev = " + num2istr( saveIMD )
	
	return pList

End // NMProceduresList

//****************************************************************
//****************************************************************

Function NMProceduresKill( [ quiet ] )
	Variable quiet
	
	Variable icnt
	String windowList, windowName
	
	if ( !quiet )
	
		DoAlert /T="NM Alert" 1, "Are you sure you want to kill all NeuroMatic procedure files from the current experiment?"
		
		if ( V_flag != 1 )
			return 0
		endif
		
	endif
	
	Execute /Q/Z "SetIgorOption IndependentModuleDev = 1" // unhide procedures
	
	windowList = NMProceduresList()
	
	for ( icnt = 0 ; icnt < ItemsInList( windowList ) ; icnt += 1 )
		windowName = StringFromList( icnt, windowList )
		Execute /P/Q/Z "CloseProc /NAME=" + NMQuotes( windowName ) + " /COMP=0 /D=0"
		windowName = ReplaceString( ".ipf", windowName, "" )
		Execute /P/Q/Z "DELETEINCLUDE \"" + windowName + "\""
	endfor
	
	Execute/P/Q/Z "COMPILEPROCEDURES "		// Note the space before final quote
	
	DoWindow /K $NMPanelName
	
End // NMProceduresKill

//****************************************************************
//****************************************************************
//
//	NeuroMatic Global Functions
//
//****************************************************************
//****************************************************************

Function CheckNeuroMatic() // check main NeuroMatic globals

	CheckNMtwave( NMDF + "FolderList", 0, "" ) // wave of NM folder names

End // CheckNeuroMatic

//****************************************************************
//****************************************************************

Function NMSet( [ on, tab, folder, wavePrefix, wavePrefixNoPrompt, PrefixSelectPrompt, OrderWavesBy, waveNum, waveInc, chanSelect, waveSelect, xProgress, yProgress, winCascade, configsDisplay, errorPointsLimit, openPath, savePath, prefixFolder, history ] )
	
	Variable on
	String tab
	String folder
	
	String wavePrefix, wavePrefixNoPrompt
	Variable PrefixSelectPrompt // config variable
	String OrderWavesBy // config string
	
	Variable waveNum, waveInc
	String chanSelect, waveSelect
	
	Variable xProgress, yProgress // config variables
	
	Variable winCascade
	Variable configsDisplay
	Variable errorPointsLimit
	
	String openPath, savePath
	
	String prefixFolder // used with waveNum, chanSelect, waveSelect
	
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	String vlist = "", vlist2 = ""
	
	if ( ParamIsDefault( prefixFolder ) )
	
		prefixFolder = CurrentNMPrefixFolder()
		
	else
	
		if ( strlen( prefixFolder ) > 0 )
			vlist2 = NMCmdStrOptional( "prefixFolder", prefixFolder, vlist2 )
		elseif ( NMPrefixFolderHistory && ( strlen( prefixFolder ) == 0 ) )
			prefixFolder = CurrentNMPrefixFolder()
			vlist2 = NMCmdStrOptional( "prefixFolder", prefixFolder, vlist2 )
		endif
		
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
		
	endif
	
	if ( !ParamIsDefault( on ) )
	
		vlist = NMCmdNumOptional( "on", on, vlist, integer = 1 )
		
		NMon( BinaryCheck( on ) )
		
	endif
	
	if ( !ParamIsDefault( tab ) )
	
		vlist = NMCmdStrOptional( "tab", tab, vlist )
		
		NMTab( tab )
		
	endif
	
	if ( !ParamIsDefault( folder ) )
	
		vlist = NMCmdStrOptional( "folder", folder, vlist )
		
		if ( IsNMFolder( folder, "NMLog" ) )
			folder = CheckNMFolderPath( folder )
			LogDisplayCall( folder )
		elseif ( IsNMFolder( folder,"NMData" ) )
			NMFolderChange( folder )
		else
			NMFolderNew( folder )
		endif
		
	endif

	if ( !ParamIsDefault( wavePrefix ) )
	
		vlist = NMCmdStrOptional( "wavePrefix", wavePrefix, vlist )
	
		if ( NMVarGet( "PrefixSelectPrompt" ) )
			NMPrefixSelect( wavePrefix )
		else
			NMPrefixSelect( wavePrefix, noPrompts = 1 )
		endif
		
	endif
	
	if ( !ParamIsDefault( wavePrefixNoPrompt ) )
	
		vlist = NMCmdStrOptional( "wavePrefixNoPrompt", wavePrefixNoPrompt, vlist )
		
		NMPrefixSelect( wavePrefixNoPrompt, noPrompts = 1 )
		
	endif
	
	if ( !ParamIsDefault( PrefixSelectPrompt ) )
	
		vlist = NMCmdNumOptional( "PrefixSelectPrompt", PrefixSelectPrompt, vlist )
		
		NMConfigVarSet( "NM" , "PrefixSelectPrompt" , BinaryCheck( PrefixSelectPrompt ) )
		
	endif
	
	if ( !ParamIsDefault( OrderWavesBy ) )
	
		vlist = NMCmdStrOptional( "OrderWavesBy", OrderWavesBy, vlist )
	
		if ( !StringMatch( OrderWavesBy, "date" ) )
			OrderWavesBy = "name"
		endif
		
		NMConfigStrSet( "NM" , "OrderWavesBy" , OrderWavesBy )
		
	endif
	
	if ( !ParamIsDefault( waveNum ) )
	
		vlist = NMCmdNumOptional( "waveNum", waveNum, vlist, integer = 1 )
		
		NMCurrentWaveSet( waveNum, prefixFolder = prefixFolder )
		
	endif
	
	if ( !ParamIsDefault( waveInc ) )
	
		vlist = NMCmdNumOptional( "waveInc", waveInc, vlist, integer = 1 )
		
		NMWaveInc( waveInc )
		
	endif
	
	if ( !ParamIsDefault( chanSelect ) )
	
		vlist = NMCmdStrOptional( "chanSelect", chanSelect, vlist )
		
		NMChanSelect( chanSelect, prefixFolder = prefixFolder )
		
	endif
	
	if ( !ParamIsDefault( waveSelect ) )
	
		vlist = NMCmdStrOptional( "waveSelect", waveSelect, vlist )
		
		NMWaveSelect( waveSelect, prefixFolder = prefixFolder )
		
	endif
	
	if ( !ParamIsDefault( xProgress ) )
	
		vlist = NMCmdNumOptional( "xProgress", xProgress, vlist )
		
		if ( ( numtype( xProgress ) > 0 ) || ( xProgress < 0 ) )
			xProgress = NaN
		endif
		
		SetNMvar( NMDF + "xProgress", xProgress )
		NMConfigVarSet( "NeuroMatic", "xProgress", xProgress )
		
	endif
	
	if ( !ParamIsDefault( yProgress ) )
	
		vlist = NMCmdNumOptional( "yProgress", yProgress, vlist )
		
		if ( ( numtype( yProgress ) > 0 ) || ( yProgress < 0 ) )
			yProgress = NaN
		endif
		
		SetNMvar( NMDF + "yProgress", yProgress )
		NMConfigVarSet( "NeuroMatic", "yProgress", yProgress )
		
	endif
	
	if ( !ParamIsDefault( winCascade ) )
	
		vlist = NMCmdNumOptional( "winCascade", winCascade, vlist, integer = 1 )
	
		if ( ( numtype( winCascade ) > 0 ) || ( winCascade < 0 ) )
			winCascade = 0
		endif
		
		SetNMvar( NMDF + "Cascade", floor( winCascade ) )
		
	endif
	
	if ( !ParamIsDefault( configsDisplay ) )
	
		vlist = NMCmdNumOptional( "configsDisplay", configsDisplay, vlist )
		
		NMConfigsDisplay( BinaryCheck( configsDisplay ) )
		
	endif
	
	if ( !ParamIsDefault( errorPointsLimit ) )
	
		vlist = NMCmdNumOptional( "errorPointsLimit", errorPointsLimit, vlist, integer = 1 )
		
		if ( errorPointsLimit >= 0 )
			NMConfigVarSet( "NM" , "ErrorPointsLimit" , errorPointsLimit )
		endif
		
	endif
	
	if ( !ParamIsDefault( openPath ) )
		
		vlist = NMCmdStrOptional( "openPath", openPath, vlist )
	
		NewPath /Q/O/M="Set Open File Path" OpenDataPath, openPath
	
		if ( V_flag == 0 )
			NMConfigStrSet( "NM", "OpenDataPath", openPath )
		endif
		
	endif
	
	if ( !ParamIsDefault( savePath ) )
	
		vlist = NMCmdStrOptional( "savePath", savePath, vlist )
	
		NewPath /Q/O/M="Set Save File Path" SaveDataPath, savePath
		
		if ( V_flag == 0 )
			NMConfigStrSet( "NM", "SaveDataPath", savePath )
		endif
		
	endif
	
	if ( history )
		NMCommandHistory( vlist + vlist2 )
	endif
	
End // NMSet

//****************************************************************
//****************************************************************

Function NMVarGet( varName )
	String varName
	
	Variable defaultVal = Nan
	String thisfxn = GetRTStackInfo( 1 )
	
	strswitch( varName )
			
		case "AlertUser":
			defaultVal = 1
			break

		case "DeprecationAlert":
			defaultVal = 0
			break
			
		case "WriteHistory":
			defaultVal = 1
			break
		
		case "CmdHistory":
			defaultVal = 1
			break
			
		case "CmdHistoryLongFormat":
			defaultVal = 0
			break
			
		case "ConfigsDisplay":
			defaultVal = 0
			break
			
		case "ForceNMFolderPrefix":
			defaultVal = 1
			break
			
		case "ImportPrompt":
			defaultVal = 0
			break
			
		case "LoadWithPrefixDF":
			defaultVal = 1
			break
			
		case "ABF_GapFreeConcat":
			defaultVal = 1
			break
			
		case "ABF_HeaderReadAll":
			defaultVal = 0
			break
			
		case "CreateOldFolderGlobals":
			defaultVal = 0
			break
			
		case "WaveSkip":
			defaultVal = 1
			break
			
		case "NMon":
			defaultVal = 1
			break
			
		case "PanelResolution":
			defaultVal = NMPanelResolution
			break
			
		case "NMPanelUpdate":
			defaultVal = 1
			break
			
		case "CurrentTab":
			defaultVal = 0
			break
			
		case "Cascade":
			defaultVal = 0
			break
			
		case "NumActiveWaves":
			defaultVal = 0
			break
			
		case "CurrentWave":
			defaultVal = 0
			break
			
		case "CurrentGrp":
			defaultVal = 0
			break
			
		case "GroupsOn":
			defaultVal = 0
			break
			
		case "SumSet0":
			defaultVal = 0
			break
			
		case "SumSet1":
			defaultVal = 0
			break
			
		case "SumSet2":
			defaultVal = 0
			break
			
		case "ProgFlag":
			defaultVal = 1
			break
			
		case "NMPanelX0":
			defaultVal = NaN // will be computed by NM
			break
			
		case "NMPanelY0":
			defaultVal = NaN // will be computed by NM
			break
			
		case "xProgress":
			defaultVal = Nan // will be computed in NMProgressX
			break
			
		case "yProgress":
			defaultVal = Nan // will be computed in NMProgressY
			break
			
		case "ProgressTimerLimit":
			defaultVal = 4000 // msec
			break
			
		case "NMProgressCancel":
			defaultVal = 0
			break
			
		case "SetsAutoAdvance":
			defaultVal = 0
			break
			
		case "StimRetrieveAs":
			defaultVal = 1
			break
			
		case "PrefixSelectPrompt":
			defaultVal = 1
			break
			
		case "OrderWaves":
			defaultVal = 2
			break
			
		case "DragOn":
			defaultVal = 1
			break
			
		case "AutoDoUpdate":
			defaultVal = 1
			break

		case "GraphsAndTablesOn":
			defaultVal = 1
			break
			
		case "ErrorPointsLimit":
			defaultVal = NMErrorPointsLimit
			break
			
		case "KillWindowNoDialog":
			defaultVal = NMKillWinNoDialog
			break
			
		case "ChanGraphStandoff":
			defaultVal = NMChanGraphStandoff
			break
			
		case "ChanGraphGrid":
			defaultVal = NMChanGraphGrid
			break
			
		case "ChanGraphTraceMode":
			defaultVal = NMChanGraphTraceMode
			break
			
		case "ChanGraphTraceMarker":
			defaultVal = NMChanGraphTraceMarker
			break
			
		case "ChanGraphTraceLineStyle":
			defaultVal = NMChanGraphTraceLineStyle
			break
			
		case "ChanGraphTraceLineSize":
			defaultVal = NMChanGraphTraceLineSize
			break
			
		case "HistogramPaddingBins":
			defaultVal = NMHistogramPaddingBins
			break
			
		case "ConfigsEditByPrompt":
			defaultVal = ConfigsEditByPrompt
			break
			
		default:
			NMDoAlert( thisfxn + " Error: no variable called " + NMQuotes( varName ) )
			return Nan
	
	endswitch
	
	return NumVarOrDefault( NMDF + varName, defaultVal )
	
End // NMVarGet

//****************************************************************
//****************************************************************

Function NMK()

	return NMVarGet( "KillWindowNoDialog" )

End // NMK

//****************************************************************
//****************************************************************

Function /S NMStrGet( strVarName )
	String strVarName
	
	String defaultStr = ""
	String thisfxn = GetRTStackInfo( 1 )
	
	strswitch( strVarName )
	
		case "NMVersionStr":
			defaultStr = NMVersionStr
			break
	
		case "OrderWavesBy":
			defaultStr = "name"
			break
			
		case "WavePrefix":
			defaultStr = "Record"
			break
			
		case "PrefixList":
			defaultStr = ""
			break
			
		case "NMTabList":
			defaultStr = NMTabList
			break
			
		case "TabControlList":
			defaultStr = "" // DO NOT CHANGE
			break
			
		case "OpenDataPath":
			defaultStr = ""
			break
			
		case "SaveDataPath":
			defaultStr = ""
			break
			
		case "FileNameReplaceStringList":
			defaultStr = ""
			break
			
		case "CurrentFolder":
			defaultStr = ""
			break
			
		case "WaveSelectAdded":
			defaultStr = ""
			break
			
		case "ProgressStr":
			defaultStr = ""
			break
			
		case "ErrorStr":
			defaultStr = ""
			
		case "ChanGraphGridColor":
			defaultStr = NMChanGraphGridColor
			break
			
		case "ChanGraphTraceOverlayColor":
			defaultStr = NMChanGraphTraceOverlayColor
			break
			
		case "ChanGraphTraceColor":
			defaultStr = NMChanGraphTraceColor
			break
			
		case "D3D_UnpackWavePrefix":
			defaultStr = "prompt" // for user-prompt during import dialogue
			break
			
		default:
			NMDoAlert( thisfxn + " Error: no variable called " + NMQuotes( strVarName ) )
			return ""
	
	endswitch
	
	return StrVarOrDefault( NMDF + strVarName, defaultStr )
			
End // NMStrGet

//****************************************************************
//****************************************************************

Function NeuroMaticConfigs()
	
	NeuroMaticConfigVar( "WriteHistory", "analysis history (0) off (1) Igor history (2) notebook (3) both", "off;Igor history;notebook;both;" )
	NeuroMaticConfigVar( "CmdHistory", "NM command history (0) off (1) Igor history (2) notebook (3) both", "off;Igor history;notebook;both;" )
	NeuroMaticConfigVar( "CmdHistoryLongFormat", "include folder, wave prefix, channel and wave select in NM command history", "boolean" )
	
	NeuroMaticConfigStr( "OpenDataPath", "open data file path (e.g. C:Jason:TestData:)", "DIR" )
	NeuroMaticConfigStr( "SaveDataPath", "save data file path (e.g. C:Jason:TestData:)", "DIR" )
	
	NeuroMaticConfigVar( "ImportPrompt", "display user-input panel while importing data", "boolean" )
	NeuroMaticConfigVar( "LoadWithPrefixDF", "attach wave-prefix DF when loading waves from multiple files", "boolean" )
	NeuroMaticConfigStr( "FileNameReplaceStringList", "replace string list when opening files (e.g. " + NMQuotes( "_ChA,_A;_ChB,_B;_Trial-,;" ) + ")", "" )
	NeuroMaticConfigVar( "ABF_GapFreeConcat", "concat Pclamp gap-free waves (for ReadPClampDataXOP only)", "boolean" )
	NeuroMaticConfigVar( "ABF_HeaderReadAll", "read all header parameters", "boolean" )
	
	NeuroMaticConfigVar( "AlertUser", "alert user (0) never (1) by Igor alert prompt (2) by NM history", "never;by DoAlert Prompt;by NM history;" )
	NeuroMaticConfigVar( "DeprecationAlert", "print deprecation alerts", "boolean" )
	
	NeuroMaticConfigStr( "NMTabList", "tabs to display", "" )
	
	NeuroMaticConfigVar( "PrefixSelectPrompt", "allow user prompts during wave prefix selections", "boolean" )
	NeuroMaticConfigStr( "OrderWavesBy", "order waves by " + NMQuotes( "name" ) + " or creation " + NMQuotes( "date" ), "name;creation date;" )
	NeuroMaticConfigStr( "PrefixList", "list of wave prefix names", "" )
	NeuroMaticConfigStr( "WavePrefix", "default NM wave prefix", "" )
	
	NeuroMaticConfigVar( "PanelResolution", "treat coordinates on Windows OS (0) as points (1) conditional 96 DPI (72) as pixels", "" )
	NeuroMaticConfigVar( "NMPanelX0", "NM panel X0 pixel position, (NAN) for automatic placement", "pixels" )
	NeuroMaticConfigVar( "NMPanelY0", "NM panel Y0 pixel position, (NAN) for automatic placement", "pixels" )
	
	NeuroMaticConfigVar( "xProgress", "progress window x pixel position, (NAN) for automatic placement", "pixels" )
	NeuroMaticConfigVar( "yProgress", "progress window y pixel position, (NAN) for automatic placement", "pixels" )
	NeuroMaticConfigVar( "ProgressTimerLimit", "minimum execution time for showing progress display", NMXunits )
	
	NeuroMaticConfigVar( "ForceNMFolderPrefix", "force " + NMQuotes( "nm" ) + " prefix for NM folders", "boolean" )
	NeuroMaticConfigVar( "CreateOldFolderGlobals", "create old folder globals, such as Set waves, ChanSelect, WaveSelect...", "boolean" )
	
	NeuroMaticConfigVar( "GraphsAndTablesOn", "allow NM functions to create graphs and tables", "boolean" )
	NeuroMaticConfigVar( "KillWindowNoDialog", "kill windows without dialog", "boolean" )
	
	NeuroMaticConfigVar( "ErrorPointsLimit", "upper points limit for drawing display error bars", "pnts" )
	
	NeuroMaticConfigVar( "ChanGraphStandoff", "default channel graph axes standoff", "boolean" )
	NeuroMaticConfigVar( "ChanGraphGrid", "default channel graph axes grids", "boolean" )
	NeuroMaticConfigStr( "ChanGraphGridColor", "default channel graph grid color", "RGB" )
	NeuroMaticConfigStr( "ChanGraphTraceOverlayColor", "default channel graph overlay trace color", "RGB" )
	NeuroMaticConfigStr( "ChanGraphTraceColor", "default channel graph trace color", "RGB" )
	NeuroMaticConfigVar( "ChanGraphTraceMode", "default channel graph trace mode (0 - 8)", "" )
	NeuroMaticConfigVar( "ChanGraphTraceMarker", "default channel graph trace marker (0 - 62)", "" )
	NeuroMaticConfigVar( "ChanGraphTraceLineStyle", "default channel graph trace line style (0 - 17)", "" )
	NeuroMaticConfigVar( "ChanGraphTraceLineSize", "default channel graph trace line size", "" )
	
	NeuroMaticConfigVar( "HistogramPaddingBins", "extra bins on each side of histogram (auto bin sizing)", "" )
	
	NeuroMaticConfigVar( "ConfigsEditByPrompt", "edit configs via prompts", "boolean" )
	
	NeuroMaticConfigStr( "D3D_UnpackWavePrefix", "wave prefix of unpacked D3D data file", "" )
			
End // NeuroMaticConfigs

//****************************************************************
//****************************************************************

Function NeuroMaticConfigVar( varName, description, type )
	String varName
	String description
	String type
	
	return NMConfigVar( NMPackage, varName, NMVarGet( varName ), description, type )
	
End // NeuroMaticConfigVar

//****************************************************************
//****************************************************************

Function NeuroMaticConfigStr( strVarName, description, type )
	String strVarName
	String description
	String type
	
	return NMConfigStr( NMPackage, strVarName, NMStrGet( strVarName ), description, type )
	
End // NeuroMaticConfigStr

//****************************************************************
//****************************************************************

Function CheckNMPaths()
	
	String opath = NMStrGet( "OpenDataPath" )
	String spath = NMStrGet( "SaveDataPath" )
	
	if ( strlen( opath ) > 0 )
	
		PathInfo OpenDataPath
		
		if ( !StringMatch( opath, S_path ) )
			NewPath /O/Q/Z OpenDataPath opath
		endif
		
	endif
	
	if ( strlen( spath ) > 0 )
	
		PathInfo SaveDataPath
		
		if ( !StringMatch( spath, S_path ) )
			NewPath /O/Q/Z SaveDataPath spath
		endif
		
	endif

End // CheckNMPaths

//****************************************************************
//****************************************************************

Function KillNMPaths()
	
	PathInfo igor
	
	if ( V_flag == 0 )
		return -1
	endif
	
	PathInfo NMPath
	
	if ( V_flag == 1 )
		NewPath /O/Q NMPath, S_path
		KillPath /Z NMPath
	endif
	
	PathInfo OpenDataPath
	
	if ( V_flag == 1 )
		NewPath /O/Q OpenDataPath, S_path
		KillPath /Z OpenDataPath
	endif
	
	PathInfo SaveDataPath
	
	if ( V_flag == 1 )
		NewPath /O/Q SaveDataPath, S_path
		KillPath /Z SaveDataPath
	endif
	
	PathInfo ClampPath
	
	if ( V_flag == 1 )
		NewPath /O/Q ClampPath, S_path
		KillPath /Z ClampPath
	endif
	
	PathInfo StimPath
	
	if ( V_flag == 1 )
		NewPath /O/Q StimPath, S_path
		KillPath /Z StimPath
	endif
	
	PathInfo OpenAllPath
	
	if ( V_flag == 1 )
		NewPath /O/Q OpenAllPath, S_path
		KillPath /Z OpenAllPath
	endif

End // KillNMPaths

//****************************************************************
//****************************************************************

Function NMon( on )
	Variable on // ( 0 ) off ( 1 ) on ( -1 ) toggle
	
	if ( on == -1 )
		on = BinaryInvert( NMVarGet( "NMon" ) )
	else
		on = BinaryCheck( on )
	endif
	
	if ( on )
	
		ResetNM( 0, quiet = 1 )
		SetNMvar( NMDF + "NMon", 1 )
		
	else
	
		if ( DataFolderExists( NMDF ) )
			SetNMvar( NMDF + "NMon", 0 )
		endif
		
		DoWindow /K $NMPanelName
		
	endif
	
	NMMenuBuild()
	
	return on

End // NMon

//****************************************************************
//****************************************************************

Function IsNMon()

	if ( DataFolderExists( NMDF ) && NMVarGet( "NMOn" ) )
		return 1
	else
		return 0
	endif

End // IsNMon

//****************************************************************
//****************************************************************

Function CheckNMPanelResolution()

	if ( StringMatch( NMComputerType(), "PC" ) )
		Execute /Q/Z "SetIgorOption PanelResolution = " + num2istr( NMVarGet( "PanelResolution" ) )
	endif

End // CheckNMPanelResolution

//****************************************************************
//****************************************************************
//
//	Loop Execution Functions
//	see NMLoopDemo and NMLoopDemo2
//
//****************************************************************
//****************************************************************

Structure NMLoopExecStruct // parameters for NMLoopExecute

	String fxn // function name
	String folderList // NM folder list ( e.g. "nmFolder0;nmFolder1;" or "All" )
	String wavePrefixList // wave prefix list ( e.g. "Record;Wave;" )
	String chanSelectList // channel select list ( e.g. "A;B;" or "All" )
	String waveSelectList // wave select list ( e.g. "All" or "Set1;Set2;" or "All Sets" )
	String paramList // list if input parameters
	String returnWaveList // list of waves or windows created by function
	String returnWinList // list of waves or windows created by function
	
	Variable updateWaveLists
	Variable updateGraphs
	Variable updatePanel
	Variable ignorePrefixFolder

EndStructure

//****************************************************************
//****************************************************************

Function NMLoopExecStructNull( nm )
	STRUCT NMLoopExecStruct &nm
	
	nm.fxn = ""; nm.folderList = ""; nm.wavePrefixList = ""; nm.chanSelectList = ""; nm.waveSelectList = "";
	nm.paramList = ""; nm.returnWaveList = ""; nm.returnWinList = "";

End // NMLoopExecStructNull

//****************************************************************
//****************************************************************

Function NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm )
	String folderList
	String wavePrefixList
	String chanSelectList
	String waveSelectList
	STRUCT NMLoopExecStruct &nm
	
	nm.fxn = GetRTStackInfo( 2 )
	nm.folderList = folderList
	nm.wavePrefixList = wavePrefixList
	nm.chanSelectList = chanSelectList
	nm.waveSelectList = waveSelectList
	
	return 0

End // NMLoopExecStructInit

//****************************************************************
//****************************************************************

Function NMLoopExecVarAdd( varName, varValue, nm [ integer ] )
	String varName
	Variable varValue
	STRUCT NMLoopExecStruct &nm
	Variable integer
	
	nm.paramList = NMCmdNumOptional( varName, varValue, nm.paramList, integer = integer )
	
End // NMLoopExecVarAdd

//****************************************************************
//****************************************************************

Function NMLoopExecStrAdd( strName, strValue, nm )
	String strName
	String strValue
	STRUCT NMLoopExecStruct &nm
	
	nm.paramList = NMCmdStrOptional( strName, strValue, nm.paramList )
	
End // NMLoopExecStrAdd

//****************************************************************
//****************************************************************

Function NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm [ fullPath, transforms ] )
	String fxn
	String folder, wavePrefix
	Variable chanNum
	String waveSelect
	STRUCT NMParams &nm
	Variable fullPath
	Variable transforms
	
	Variable numChannels
	
	if ( ParamIsDefault( transforms ) )
		transforms = 1
	endif
	
	if ( strlen( fxn ) == 0 )
		fxn = GetRTStackInfo( 2 )
	endif
	
	folder = CheckNMFolderPath( folder )
	
	if ( !IsNMDataFolder( folder ) )
		return NMError( 30, GetRTStackInfo( 2 ), "folder", folder )
	endif
	
	if ( strlen( wavePrefix ) == 0 )
		wavePrefix = CurrentNMWavePrefix()
	endif
	
	if ( chanNum == -1 )
		chanNum = CurrentNMChannel()
	endif
	
	if ( strlen( waveSelect ) == 0 )
		waveSelect = NMWaveSelectGet()
	endif
	
	NMParamsNull( nm )
	
	nm.fxn = fxn
	nm.folder = folder
	nm.wavePrefix = wavePrefix
	nm.prefixFolder = NMPrefixFolderDF( folder, wavePrefix )
	
	if ( ( strlen( nm.prefixFolder ) == 0 ) || !DataFolderExists( nm.prefixFolder ) )
		return NMError( 30, GetRTStackInfo( 2 ), "prefixFolder", nm.prefixFolder )
	endif
	
	numChannels = NumVarOrDefault( nm.prefixFolder + "NumChannels", 0 )
	
	if ( ( numtype( chanNum ) > 0 ) || ( chanNum < 0 ) || ( chanNum >= numChannels ) )
		NMError( 10, GetRTStackInfo( 2 ), "chanNum", num2str( chanNum ) )
	endif
	
	nm.chanNum = chanNum
	nm.transforms = transforms
	nm.waveSelect = waveSelect
	
	nm.wList = NMWaveSelectListMaster( prefixFolder = nm.prefixFolder, chanNum = nm.chanNum, waveSelect = nm.waveSelect, fullPath = fullPath )
	
	if ( ItemsInList( nm.wList ) == 0 )
		return 1 // no waves
	endif
	
	nm.xWave = NMXwave( prefixFolder = nm.prefixFolder, fullPath = fullPath )
	nm.xLabel = NMChanLabelXAll( prefixFolder = nm.prefixFolder )
	nm.yLabel = NMChanLabelY( prefixFolder = nm.prefixFolder, channel = chanNum )
	
	return 0
	
End // NMLoopStructInit

//****************************************************************
//****************************************************************

Function /S NMLoopExecute( nm, cmdHistory, deprecation )
	STRUCT NMLoopExecStruct &nm
	Variable cmdHistory // print function call command to history
	Variable deprecation // print deprecation alert
	
	Variable fcnt, pcnt, wcnt, ccnt, icnt
	Variable chanNum, numChannels, cancel
	
	String oldFunction, newFunction, fList
	String folder, wavePrefix, wavePrefixList2, pList, prefixFolder
	String chanSelectStr, chanSelectList2, waveSelect, waveSelectList2
	String paramList1 = "", paramList2, vlist = "", returnStr
	
	String fxnName = GetRTStackInfo( 2 )
	String fxnToExecute = fxnName + "2"
	
	SetNMvar( NMDF + "ErrorNum", 0 ) // reset error number
	
	NMOutputListsReset()
	
	if ( exists( fxnToExecute ) != 6 )
		return NM2ErrorStr( 90, "failed to find function " + fxnToExecute, "" )
	endif
	
	if ( ItemsInList( nm.folderList ) == 0 )
		nm.folderList = GetDataFolder( 0 )
	elseif ( StringMatch( nm.folderList, "All" ) && !IsNMDataFolder( "All" ) )
		nm.folderList = NMDataFolderList()
	endif
	
	if ( ItemsInList( nm.wavePrefixList ) == 0 )
			
		nm.wavePrefixList = CurrentNMWavePrefix()
		
		if ( strlen( nm.wavePrefixList ) == 0 )
			return NM2ErrorStr( 21, "wavePrefixList", "" )
		endif
		
	endif
	
	if ( ItemsInList( nm.chanSelectList ) == 0 )
	
		nm.chanSelectList = NMChanSelectStr()
		
		if ( ItemsInList ( nm.chanSelectList ) == 0 )
			return NM2ErrorStr( 21, "chanSelectList", "" )
		endif
		
	endif
	
	if ( ItemsInList( nm.waveSelectList ) == 0 )
			
		nm.waveSelectList = NMWaveSelectGet()
		
		if ( ItemsInList( nm.waveSelectList ) == 0 )
			return NM2ErrorStr( 21, "waveSelectList", "" )
		endif
		
	endif
		
	if ( NMVarGet( "CmdHistoryLongFormat" ) )
	
		if ( !StringMatch( nm.folderList, "RemoveFromHistory" ) )
			vlist = NMCmdStrOptional( "folderList", nm.folderList, vlist )
		else
			nm.folderList = ""
		endif
		
		if ( !StringMatch( nm.wavePrefixList, "RemoveFromHistory" ) )
			vlist = NMCmdStrOptional( "wavePrefixList", nm.wavePrefixList, vlist )
		else
			nm.wavePrefixList = ""
		endif
		
		if ( !StringMatch( nm.chanSelectList, "RemoveFromHistory" ) )
			vlist = NMCmdStrOptional( "chanSelectList", nm.chanSelectList, vlist )
		else
			nm.chanSelectList = ""
		endif
		
		if ( !StringMatch( nm.waveSelectList, "RemoveFromHistory" ) )
			vlist = NMCmdStrOptional( "waveSelectList", nm.waveSelectList, vlist )
		else
			nm.waveSelectList = ""
		endif
		
	else
	
		if ( WhichListItem( "ForceHistory", nm.folderList ) >= 0 )
			nm.folderList = RemoveFromList( "ForceHistory", nm.folderList )
			vlist = NMCmdStrOptional( "folderList", nm.folderList, vlist )
		endif
		
		if ( WhichListItem( "ForceHistory", nm.wavePrefixList ) >= 0 )
			nm.wavePrefixList = RemoveFromList( "ForceHistory", nm.wavePrefixList )
			vlist = NMCmdStrOptional( "wavePrefixList", nm.wavePrefixList, vlist )
		endif
		
		if ( WhichListItem( "ForceHistory", nm.chanSelectList ) >= 0 )
			nm.chanSelectList = RemoveFromList( "ForceHistory", nm.chanSelectList )
			vlist = NMCmdStrOptional( "chanSelectList", nm.chanSelectList, vlist )
		endif
		
		if ( WhichListItem( "ForceHistory", nm.waveSelectList ) >= 0 )
			nm.waveSelectList = RemoveFromList( "ForceHistory", nm.waveSelectList )
			vlist = NMCmdStrOptional( "waveSelectList", nm.waveSelectList, vlist )
		endif
		
	endif
		
	if ( cmdHistory )
		
		NMCmdHistory( fxnName, vlist + nm.paramList )
	
	endif
	
	if ( deprecation )
		fList = GetRTStackInfo( 0 )
		icnt = ItemsInList( fList )
		oldFunction = StringFromList( icnt - 3, fList )
		newFunction = StringFromList( icnt - 2, fList )
		NMDeprecatedAlert( newFunction, oldFunction = oldFunction )
	endif
	
	nm.paramList = NMCmdVarListConvert( nm.paramList )
	
	NMProgressCancel( reset = 1 )
	
	for ( fcnt = 0 ; fcnt < ItemsInList( nm.folderList ) ; fcnt += 1 ) // loop thru folders
	
		folder = StringFromList( fcnt, nm.folderList )
		
		if ( !IsNMDataFolder( folder ) )
			NM2Error( 34, "folderList", folder )
			continue
		endif
		
		if ( StringMatch( nm.wavePrefixList, "All" ) )
		
			pList = NMPrefixSubfolderList( 0, folder = folder )
			
			if ( WhichListItem( "All", pList ) >= 0 )
				wavePrefixList2 = "All" // this is a wave prefix
			else
				wavePrefixList2 = pList
			endif
			
		else
		
			wavePrefixList2 = nm.wavePrefixList
		
		endif
		
		for ( pcnt = 0 ; pcnt < ItemsInList( wavePrefixList2 ) ; pcnt += 1 ) // loop thru wave prefixes
		
			wavePrefix = StringFromList( pcnt, wavePrefixList2 )
			
			prefixFolder = ""
			numChannels = 0
			
			chanSelectList2 = nm.chanSelectList
			waveSelectList2 = nm.waveSelectList
			
			if ( !nm.ignorePrefixFolder )
			
				prefixFolder = NMPrefixFolderDF( folder, wavePrefix )
			
				if ( DataFolderExists( prefixFolder ) )
					numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
				else
					NM2Error( 90, "no prefix folder for " + NMQuotes( wavePrefix ), "" )
					continue
				endif
				
				if ( numChannels == 0 )
					//NM2Error( 90, "no channels for prefix folder " + NMQuotes( wavePrefix ), "" )
					continue
				endif
				
				if ( StringMatch( nm.chanSelectList, "All" ) )
					chanSelectList2 = NMChanList( "CHAR", prefixFolder = prefixFolder )
				endif
				
				if ( StringMatch( nm.waveSelectList, "All" ) || StringMatch( nm.waveSelectList, "All+" ) )
					// do nothing
				elseif ( strsearch( nm.waveSelectList, "All", 0, 2 ) == 0 ) // All Sets or All Groups
					waveSelectList2 = NMWaveSelectAllList( prefixFolder = prefixFolder, waveSelect = nm.waveSelectList )
				endif
			
			endif
				
			for ( ccnt = 0; ccnt < ItemsInList( chanSelectList2 ) ; ccnt += 1 ) // loop thru channels
			
				chanSelectStr = StringFromList( ccnt, chanSelectList2 )
				chanNum = ChanChar2Num( chanSelectStr )
				
				if ( ( numtype( chanNum ) > 0 ) || ( chanNum < 0 ) || ( !nm.ignorePrefixFolder && ( chanNum >= numChannels ) ) )
					NM2Error( 20, "chanSelectList", chanSelectStr )
					continue
				endif
				
				for ( wcnt = 0 ; wcnt < ItemsInList( waveSelectList2 ) ; wcnt += 1 ) // loop thru Sets and Groups
			
					waveSelect = StringFromList( wcnt, waveSelectList2 )
					
					paramList1 = ""
					paramList1 = NMCmdStrOptional( "folder", folder, paramList1 )
					paramList1 = NMCmdStrOptional( "wavePrefix", wavePrefix, paramList1 )
					paramList1 = NMCmdNumOptional( "chanNum", chanNum, paramList1 )
					paramList1 = NMCmdStrOptional( "waveSelect", waveSelect, paramList1 )
					
					paramList1 = NMCmdVarListConvert( paramList1 )
					
					if ( strlen( nm.paramList ) > 0 )
						paramList2 = paramList1 + "," + nm.paramList
					else
						paramList2 = paramList1
					endif
					
					//Print fxnToExecute + "(" + paramList2 + ")"
					
					Execute /Q/Z fxnToExecute + "(" + paramList2 + ")"
					
					if ( V_flag != 0 )
					
						//Print fxnToExecute + "(" + paramList + ")"
					
						Execute /Q/Z fxnToExecute + "(" + nm.paramList + ")" // try again
						
						if ( V_flag != 0 )
							return NM2ErrorStr( 90, "failed to execute function " + fxnToExecute, "" )
						endif
						
					endif
					
					returnStr = StrVarOrDefault( NMDF + "OutputWaveList", "" )
					
					if ( ItemsInList( returnStr ) > 0 )
						if ( strsearch( returnStr, ";", 0 ) >= 0 )
							nm.returnWaveList += returnStr
						else
							nm.returnWaveList = AddListItem( returnStr, nm.returnWaveList, ";", inf )
						endif
					endif
					
					returnStr = StrVarOrDefault( NMDF + "OutputWinList", "" )
					
					if ( ItemsInList( returnStr ) > 0 )
						if ( strsearch( returnStr, ";", 0 ) >= 0 )
							nm.returnWinList += returnStr
						else
							nm.returnWinList = AddListItem( returnStr, nm.returnWinList, ";", inf )
						endif
					endif
					
					if ( NMProgressCancel() || ( NumVarOrDefault( NMDF + "ErrorNum", 0 ) != 0 ) )
						cancel = 1
						break
					endif
			
				endfor // wave select
				
				if ( cancel )
					break
				endif
			
			endfor // channel select
			
			if ( cancel )
				break
			endif
			
		endfor // waveprefix select
		
		if ( cancel )
			break
		endif
	
	endfor // folder select
	
	if ( nm.updateWaveLists )
		NMWaveSelectListMaster( updateNM = 1 )
	endif
	
	if ( nm.updateGraphs )
		ChanGraphsUpdate()
	endif
	
	if ( nm.updatePanel )
		//UpdateNMPanelSets( 1 )
		UpdateNMPanel( 1 )
	endif
	
	if ( ItemsInList( nm.returnWinList ) > 0 )
		return nm.returnWinList
	elseif ( ItemsInList( nm.returnWaveList ) > 0 )
		return nm.returnWaveList
	else
		return ""
	endif
	
End // NMLoopExecute

//****************************************************************
//****************************************************************

Function /S NMLoopHistory( nm [ includeParamList, includeWaveNames, includeOutputs, includeOutputSubfolder, fullPath, compact, quiet, skipFailures ] )
	STRUCT NMParams &nm
	Variable includeParamList // ( 0 ) no ( 1 ) yes
	Variable includeWaveNames // ( 0 ) no ( 1 ) yes
	Variable includeOutputs // ( 0 ) no ( 1 ) yes
	Variable includeOutputSubfolder // print subfolder name rather than output wave names ( 0 ) no ( 1 ) yes
	Variable fullPath // fullpath wave names ( ignores compact flag )
	Variable compact // use compact list for wave names ( 0 ) no ( 1 )
	Variable quiet // ( 0 ) print to history ( 1 ) do not print to history, return history as string
	Variable skipFailures
	
	Variable numWaves, failures
	String wName, ftxt, wList, txt, cstr = " : "
	String outWaveList = "", outWinList = ""
	
	if ( ParamIsDefault( includeOutputs ) )
		includeOutputs = 1
	endif
	
	if ( ParamIsDefault( compact ) )
		compact = 1
	endif
	
	if ( strlen( nm.fxn ) == 0 )
		txt = GetRTStackInfo( 2 )
	else
		txt = nm.fxn
	endif
	
	if ( includeParamList && ( strlen( nm.paramList ) > 0 ) )
		txt += " (" + RemoveEnding( nm.paramList, ";" ) + ")"
	endif
	
	if ( strlen( nm.folder ) > 0 )
		txt += cstr + NMChild( nm.folder )
	endif
	
	if ( strlen( nm.wavePrefix ) > 0 )
		txt += cstr + nm.wavePrefix
	endif
	
	if ( numtype( nm.chanNum ) == 0 )
		txt += cstr + "Ch " + ChanNum2Char( nm.chanNum )
	endif
	
	if ( StringMatch( nm.waveSelect, "This Wave" ) )
		wName = StringFromList( 0, nm.wList )
		wName = NMChild( wName )
		txt += cstr + wName
	elseif ( strlen( nm.waveSelect ) > 0 )
		txt += cstr + nm.waveSelect
	endif
	
	numWaves = ItemsInlist( nm.successList )
	
	txt += cstr + "N = " + num2istr( numWaves ) + " of " + num2istr( ItemsInlist( nm.wList ) )
	
	if ( numWaves == 0 )
	
		txt += cstr + "No Waves!!"
		
	elseif ( includeWaveNames )
	
		if ( fullPath )
		
			wList = nm.wList
			
		else
		
			wList = NMChild( nm.wList )
		
			if ( compact )
				wList = NMUtilityWaveListShort( wList )
			endif
		
		endif
		
		if ( numWaves == 1 )
			txt += cstr + StringFromList( 0, wList )
		else
			txt += cstr + wList
		endif
		
	endif
	
	if ( !quiet )
	
		NMHistory( txt )
		
		if ( ( includeOutputs ) && ( ItemsInList( nm.newList ) > 0 ) )
		
			if ( includeOutputSubfolder )
			
				outWaveList = nm.fxn + " Output Folder" + cstr + StringFromList( 0, NMParent( nm.newList ) )
				
			else
			
				wList = NMChild( nm.newList )
				
				if ( ItemsInList( nm.newList ) == 1 )
				
					outWaveList = nm.fxn + " Output Wave" + cstr + wList
					
				else
					
					wList = NMUtilityWaveListShort( wList )
					outWaveList = nm.fxn + " Output Waves" + cstr + wList
					
				endif
				
			endif
			
			NMHistory( outWaveList )
			
		endif
		
		if ( includeOutputs && ( ItemsInList( nm.windowList ) > 0 ) )
		
			if ( ItemsInList( nm.windowList ) == 1 )
				outWinList = nm.fxn + " Output Window" + cstr + nm.windowList
			else
				outWinList = nm.fxn + " Output Windows" + cstr + nm.windowList
			endif
			
			NMHistory( outWinList )
			
		endif
		
	endif
	
	if ( skipFailures )
		return txt
	endif
	
	failures = ItemsInList( nm.failureList )
	
	if ( failures == 0 )
		return txt
	endif
	
	ftxt = nm.fxn + " Failures"
	
	if ( strlen( nm.folder ) > 0 )
		ftxt += cstr + NMChild( nm.folder )
	endif
	
	if ( strlen( nm.wavePrefix ) > 0 )
		ftxt += cstr + nm.wavePrefix
	endif
	
	if ( numtype( nm.chanNum ) == 0 )
		ftxt += cstr + "Ch " + ChanNum2Char( nm.chanNum )
	endif
	
	if ( failures == 1 )
		ftxt += cstr + "N = " + num2istr( failures ) + cstr + StringFromList( 0, nm.failureList )
	else
		ftxt += cstr + "N = " + num2istr( failures ) + cstr + nm.failureList
	endif
	
	if ( !quiet )
		NMHistory( ftxt )
	endif
	
	return txt

End // NMLoopHistory

//****************************************************************
//****************************************************************

Function /S NMLoopWaveNote( wList, paramList )
	String wList // wave name list
	String paramList
	
	Variable wcnt
	String wName, noteStr
	String fxnName = GetRTStackInfo( 2 )
	
	paramList = NMCmdVarListConvert( paramList )
	paramList = ReplaceString( " ", paramList, "" )
	
	if ( strlen( paramList ) > 0 )
		noteStr = fxnName + "(" + paramList + ")"
	else
		noteStr = fxnName
	endif
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
	
		if ( WaveExists( $wName ) )
			Note $wName, noteStr
		endif
		
	endfor
	
	return noteStr
	
End // NMLoopWaveNote

//****************************************************************
//****************************************************************

Function NMOutputListsReset()

	SetNMstr( NMDF + "OutputWinList", "" )
	SetNMstr( NMDF + "OutputWaveList", "" )
	
End // NMOutputListsReset

//****************************************************************
//****************************************************************

Function /S NMOutputWaveList( [ history ] )
	Variable history
	
	String wList = StrVarOrDefault( NMDF + "OutputWaveList", "" )
	
	if ( history )
		NMHistory( wList )
	endif
	
	return wList
	
End // NMOutputWaveList

//****************************************************************
//****************************************************************

Function /S NMOutputWinList( [ history ] )
	Variable history
	
	String wList = StrVarOrDefault( NMDF + "OutputWinList", "" )
	
	if ( history )
		NMHistory( wList )
	endif
	
	return wList
	
End //  NMOutputWinList

//****************************************************************
//****************************************************************
//
//	Tab Functions
//
//****************************************************************
//****************************************************************

Function /S NMTabsAvailable()

	Variable fcnt
	String fList, fname, tabList = ""
	
	fList = FunctionList( "NM*TabPrefix", ";", "KIND:2" )
	
	fList = RemoveFromList( "NMTabPrefix", fList )
	
	for ( fcnt = 0 ; fcnt < ItemsInList( fList ) ; fcnt += 1 )
	
		fname = StringFromList( fcnt, fList )
		fname = ReplaceString( "NM", fname, "" )
		fname = ReplaceString( "TabPrefix", fname, "" )
		
		if ( strlen( fname ) > 0 )
			tabList = AddListItem( fname, tabList, ";", inf )
		endif
	
	endfor
	
	fList = FunctionList( "NMTabPrefix_*", ";", "KIND:2" )
	
	for ( fcnt = 0 ; fcnt < ItemsInList( fList ) ; fcnt += 1 )
	
		fname = StringFromList( fcnt, fList )
		fname = ReplaceString( "NMTabPrefix_", fname, "" )
		
		if ( strlen( fname ) > 0 )
			tabList = AddListItem( fname, tabList, ";", inf )
		endif
	
	endfor
	
	return tabList

End // NMTabsAvailable

//****************************************************************
//****************************************************************

Function /S NMTabControlList()
	
	Variable icnt
	String tabName, prefix
	
	String tabCntrlList = NMStrGet( "TabControlList" ) // current list of tabs in TabManager format
	String currentList = NMTabListConvert( tabCntrlList )
	String defaultList = NMStrGet( "NMTabList" )
	
	String win = TabWinName( tabCntrlList )
	String tab = TabCntrlName( tabCntrlList )
	
	if ( !DataFolderExists( NMDF ) )
		return "" // nothing to do yet
	endif
	
	if ( StringMatch( win, NMPanelName ) && StringMatch( tab, "NM_Tab" ) )
		
		if ( !StringMatch( defaultList, currentList ) )
			SetNMstr( NMDF + "NMTabList", currentList ) // defaultList has inappropriately changed
			print "changing tab list back"
		endif
		
		return tabCntrlList // OK format
		
	endif
	
	// need to create tabCntrlList from defaultList
	
	if ( ItemsInList( defaultList ) == 0 )
	
		if ( ItemsInList( currentList ) > 0 )
			defaultList = currentList
		else
			defaultList = "Main;"
		endif
	
	endif
	
	tabCntrlList = ""
	
	for ( icnt = 0; icnt < ItemsInList( defaultList ); icnt += 1 )
	
		tabName = StringFromList( icnt, defaultList )
		prefix = NMTabPrefix( tabName )
		
		if ( strlen( prefix ) > 0 )
			tabCntrlList = AddListItem( tabName + "," + prefix, tabCntrlList, ";", inf )
		else
			NMHistory( "NM Tab Entry Failure : " + tabName )
		endif
		
	endfor
	
	tabCntrlList = AddListItem( NMPanelName + ",NM_Tab", tabCntrlList, ";", inf )
	
	SetNMstr( NMDF + "TabControlList", tabCntrlList )

	return tabCntrlList

End // NMTabControlList

//****************************************************************
//****************************************************************

Function /S NMTabPrefix( tabName )
	String tabName
	
	String fxn = "NM" + tabName + "TabPrefix"
	String prefix = StrVarOrDefault( NMDF + "TabPrefix" + tabName, "" )
	
	if ( strlen( prefix ) > 0 )
		return prefix
	endif
	
	if ( exists( fxn ) != 6 )
		fxn = "NMTabPrefix_" + tabName // try another fxn name format
	endif
	
	if ( exists( fxn ) != 6 )
		fxn = tabName + "Prefix" // try another fxn name format
	endif
	
	if ( exists( fxn ) == 6 ) // attemp to create tab prefix string by calling tab prefix function
		Execute /Z "SetNMstr( " + NMQuotes( NMDF + "TabPrefix" + tabName ) + ", " + fxn + "() )"
	endif
		
	return StrVarOrDefault( NMDF + "TabPrefix" + tabName, "" )

End // NMTabPrefix

//****************************************************************
//****************************************************************

Function /S NMTabListConvert( tabCntrlList )
	String tabCntrlList // ( '' ) for current
	
	Variable icnt
	
	String simpleList = ""
	
	if ( strlen( tabCntrlList ) == 0 )
		tabCntrlList = NMStrGet( "TabControlList" )
	endif
	
	for ( icnt = 0; icnt < ItemsInList( tabCntrlList )-1; icnt += 1 )
		simpleList = AddListItem( TabName( icnt, tabCntrlList ), simpleList, ";", inf )
	endfor
	
	return simpleList
	
End // NMTabListConvert

//****************************************************************
//****************************************************************

Function CheckNMTabs( forceVariableCheck )
	Variable forceVariableCheck
	
	Variable icnt
	
	String tabList = NMTabControlList()
	
	for ( icnt = 0; icnt < NumTabs( tabList ); icnt += 1 ) // go through each tab and check variables
		CheckNMPackage( TabName( icnt, tabList ), forceVariableCheck, update = 0 )
	endfor

End // CheckNMTabs

//****************************************************************
//****************************************************************

Function NMAutoTabCall()
	
	Variable tabNum = NMVarGet( "CurrentTab" )
	
	String tName = TabName( tabNum, NMTabControlList() )
	
	String fxn = "NM" + tName + "Auto"
	
	if ( exists( fxn ) != 6 )
		fxn = "Auto" + tName
	endif
	
	Execute /Z fxn + "()"
		
	if ( V_Flag == 0 )
		return 0
	else	
		return -1
	endif

End // NMAutoTabCall

//****************************************************************
//****************************************************************

Function NMTab( tabName ) // change NMPanel tab
	String tabName
	
	String tabList = NMTabControlList()
	
	Variable tab = TabNumber( tabName, tabList ) // NM_TabManager.ipf
	
	Variable configsOn = NMVarGet( "ConfigsDisplay" )
	
	if ( tab < 0 )
	
		if ( NMTabAdd( tabName, "" ) == -1 )
			return -1 // tab does not exist
		endif
		
		tabList = NMTabControlList()
		tab = TabNumber( tabName, tabList )
		
	endif
	
	Variable lastTab = NMVarGet( "CurrentTab" )
	
	CheckCurrentFolder()
	
	if ( ( tab != lastTab ) || configsOn )
	
		SetNMvar( NMDF + "CurrentTab", tab )
		
		if ( configsOn )
			NMConfigsListBoxWavesUpdate( "" )
			Execute /Z "NM" + tabName + "ConfigEdit()"
		endif
		
		ChangeTab( lastTab, tab, tabList ) // NM_TabManager.ipf
		//ChanGraphsUpdate() // removed 29 March 2012 because it conflicted with Event Tab
		
		NMMenuBuild()
		
	endif
	
	DoWindow /F $NMPanelName
	
	return 0

End // NMTab

//****************************************************************
//****************************************************************

Function /S CurrentNMTabName()

	return TabName( NMVarGet( "CurrentTab" ), NMTabControlList() )

End // CurrentNMTabName

//****************************************************************
//****************************************************************

Function /S CurrentNMTabPrefix()

	String tabName = CurrentNMTabName()

	return NMTabPrefix( tabName )

End // CurrentNMTabPrefix

//****************************************************************
//****************************************************************

Function NMTabKillCall()

	String tabList = NMTabControlList()
	
	if ( strlen( tabList ) == 0 )
		return -1
	endif
	
	String tabName
	Prompt tabName, "select tab:", popup TabNameList( tabList )
	DoPrompt "Kill Tab", tabName
	
	if ( V_flag == 1 )
		return 0 // cancel
	endif
	
	return NMTabKill( tabName, history = 1 )

End // NMTabKillCall

//****************************************************************
//****************************************************************

Function NMTabKill( tabName [ history ] )
	String tabName
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	String vlist = ""
	
	if ( history )
		vlist = NMCmdStr( tabName, vlist )
		NMCommandHistory( vlist )
	endif

	String tabList = NMTabControlList()
	
	Variable tabNum = TabNumber( tabName, tabList )
	String prefix = TabPrefix( tabNum, tabList ) + "*"
	
	if ( tabNum == -1 )
		return -1
	endif
	
	KillTab( tabNum, tabList, 1 )
	
	Execute /Z "Kill" + tabName + "( " + NMQuotes( "globals" ) + " )" // execute user-defined kill function, if it exists
	
	//DoAlert 1, "Kill " + NMQuotes( tabName ) + " controls?"
	
	//if ( V_Flag == 1 )
	//	KillControls( TabWinName( tabList ), prefix ) // kill controls
	//endif
	
	//KillControls( NMPanelName, NMTabPrefix( tabName ) )
	
	return 0

End // NMTabKill

//****************************************************************
//****************************************************************

Function NMTabAddCall()

	String tabName = ""
	String tabprefix = "" // auto-detected
	
	String tabList = TabNameList( NMTabControlList() )
	String allTabs = NMTabsAvailable()
	String addTabs = RemoveFromList( tabList, allTabs )

	Prompt tabName, "select tab to add:", popup addTabs
	DoPrompt "Add Tab", tabName
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	return NMTabAdd( tabName, tabprefix, history = 1 )

End // NMTabAddCall

//****************************************************************
//****************************************************************

Function NMTabAdd( tabName, tabprefix [ history ] )
	String tabName, tabprefix
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	String vlist = ""
	
	if ( history )
		vlist = NMCmdStr( tabName, vlist )
		vlist = NMCmdStr( tabprefix, vlist )
		NMCommandHistory( vlist )
	endif
	
	String tabList = NMStrGet( "NMTabList" )
	
	if ( strlen( tabprefix ) == 0 )
		tabprefix = NMTabPrefix( tabName )
	endif
	
	if ( ( strlen( tabName ) == 0 ) || ( strlen( tabprefix ) == 0 ) )
		return -1
	endif
	
	if ( WhichListItem( tabName, tabList, ";", 0, 0 ) == -1 )
		tabList = AddListItem( tabName, tabList, ";", inf )
		SetNMstr( NMDF + "NMTabList", tabList )
		UpdateNMPanel( 1 )
	endif
	
	return 0

End // NMTabAdd

//****************************************************************
//****************************************************************

Function NMTabRemoveCall()
	
	String tabList = NMTabControlList()
	
	if ( StringMatch( tabList, "" ) )
		return -1
	endif

	String tabName
	Prompt tabName, "select tab:", popup TabNameList( tabList )
	DoPrompt "Kill Tab", tabName
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	return NMTabRemove( tabName, history = 1 )

End // NMTabRemoveCall

//****************************************************************
//****************************************************************

Function NMTabRemove( tabName [ history ] )
	String tabName
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	String vlist = ""
	
	if ( history )
		vlist = NMCmdStr( tabName, vlist )
		NMCommandHistory( vlist )
	endif
	
	String tabList = NMStrGet( "NMTabList" )
	
	if ( ( strlen( tabName ) == 0 ) || ( strlen( tabList ) == 0 ) )
		return -1
	endif
	
	Variable tabNum = WhichListItem( tabName, tabList, ";", 0, 0 )
	
	if ( tabNum < 0 )
		return -1
	elseif ( tabNum == NMVarGet( "CurrentTab" ) )
		SetNMvar( NMDF + "CurrentTab", 0 )
	endif
	
	tabList = RemoveFromList( tabName, tabList, ";" )
	SetNMstr( NMDF + "NMTabList", tabList )
	
	KillControls( NMPanelName, NMTabPrefix( tabName ) )
	
	UpdateNMPanel( 1 )
	
	return 0
	
End // NMTabRemove

//****************************************************************
//****************************************************************

Function IsCurrentNMTab( tName )
	String tName // tab name
	
	String tabList = NMTabControlList()
	String ctab = TabName( NMVarGet( "CurrentTab" ), tabList )
	
	if ( StringMatch( tName, ctab ) )
		return 1
	else
		return 0
	endif
	
End // IsCurrentNMTab

//****************************************************************
//****************************************************************

Function NMChangeTabsCall()

	String tabprefix = "", vlist = ""

	String tabList = TabNameList( NMTabControlList() )
	String allTabs = NMTabsAvailable()
	String addTabs = RemoveFromList( tabList, allTabs )
	
	String addTab = " "
	String removeTab = " "
	Prompt addTab, "add:", popup " ;" + addTabs
	Prompt removeTab, "remove:", popup " ;" + tabList
	DoPrompt "Change NeuroMatic Tabs", addTab, removeTab
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	if ( !StringMatch( addTab, " " ) )
		NMTabAdd( addTab, tabprefix, history = 1 )
	endif
	
	if ( !StringMatch( removeTab, " " ) )
		NMTabRemove( removeTab, history = 1 )
	endif
	
End // NMChangeTabsCall

//****************************************************************
//****************************************************************
//
//	Wave Increment / Skip Functions
//
//****************************************************************
//****************************************************************

Function NMWaveIncCall( select )
	String select

	Variable waveInc = 1
	String vlist
	
	strswitch( select ) // set appropriate WaveSkip flag
	
		case "Wave Increment = 1":
			break
			
		case "Wave Increment > 1":
			waveInc = 2
				
			Prompt waveInc, "set wave increment to:"
			DoPrompt "Change Wave Increment", waveInc // call for user input
				
			if ( V_flag == 1 )
				return 0
			endif
				
			if ( waveInc < 1 )
				waveInc = 1
			endif
			
			break
			
		case "As Wave Select":
			waveInc = 0
			break
			
		default:
			return 0

	endswitch
	
	return NMSet( waveInc = waveInc, history = 1 )

End // NMWaveIncCall

//****************************************************************
//****************************************************************

Function NMWaveInc( waveInc )
	Variable waveInc // increment value or ( 0 ) for "As Wave Select"
	
	if ( ( numtype( waveInc ) > 0 ) || ( waveInc < 0 ) )
		waveInc = 1
	endif
	
	SetNMvar( NMDF + "WaveSkip", waveInc )
	
	return waveInc
	
End // NMWaveInc

//****************************************************************
//****************************************************************
//
//	Channel and Wave Functions
//
//****************************************************************
//****************************************************************

Function /S ChanNum2Char( chanNum )
	Variable chanNum
	
	if ( ( numtype( chanNum ) > 0 ) || ( chanNum < 0 ) )
		return ""
	endif
	
	return num2char( 65+chanNum )

End // ChanNum2Char

//****************************************************************
//****************************************************************

Function ChanChar2Num( chanChar )
	String chanChar
	
	return char2num( UpperStr( chanChar ) ) - 65

End // ChanChar2Num

//****************************************************************
//****************************************************************

Function /S ChanCharGet( wName )
	String wName // wave name
	
	Variable icnt
	
	for ( icnt = strlen( wName )-1; icnt >= 0; icnt -= 1 )
		if ( numtype( str2num( wName[ icnt ] ) ) != 0 )
			break // found Channel letter
		endif
	endfor
	
	return wName[ icnt ] // return channel character, given wave name

End // ChanCharGet

//****************************************************************
//****************************************************************

Function ChanNumGet( wName )
	String wName // wave name
	
	return ( char2num( ChanCharGet( wName ) ) - 65 ) // return chan number, given wave name

End // ChanNumGet

//****************************************************************
//
//	GetWaveName()
//	return NM wave name string, given prefix, channel and wave number
//
//****************************************************************

Function /S GetWaveName( prefix, chanNum, waveNum )
	String prefix // wave prefix name ( pass "default" to use data's WavePrefix )
	Variable chanNum // channel number ( pass -1 for none )
	Variable waveNum // wave number
	
	String name
	
	if ( StringMatch( prefix, "default" ) || StringMatch( prefix, "Default" ) )
		prefix = StrVarOrDefault( "WavePrefix", "Wave" )
	endif
	
	if ( chanNum == -1 )
		name = prefix + num2istr( waveNum )
	else
		name = prefix + ChanNum2Char( chanNum ) + num2istr( waveNum )
	endif
	
	return NMCheckStringName( name )

End // GetWaveName

//****************************************************************
//****************************************************************

Function /S GetWaveNamePadded( prefix, chanNum, waveNum, maxNum )
	String prefix // wave prefix name ( pass "default" to use data's WavePrefix )
	Variable chanNum // channel number ( pass -1 for none )
	Variable waveNum // wave number
	Variable maxNum
	
	Variable pad, icnt
	String name, snum
	
	pad = strlen( ( num2istr( maxNum ) ) )
	
	if ( StringMatch( prefix, "default" ) || StringMatch( prefix, "Default" ) )
		prefix = StrVarOrDefault( "WavePrefix", "Wave" )
	endif
	
	snum = num2istr( waveNum )
	
	for ( icnt = strlen( snum ); icnt < pad; icnt += 1 )
		snum = "0" + snum
	endfor
	
	if ( chanNum == -1 )
		name = prefix + snum
	else
		name = prefix + ChanNum2Char( chanNum ) + snum
	endif
	
	return NMCheckStringName( name )

End // GetWaveNamePadded

//****************************************************************
//
//	NextWaveNum()
//
//****************************************************************

Function NextWaveNum( df, prefix, chanNum, overwrite )
	String df // data folder
	String prefix // wave prefix name
	Variable chanNum // channel number ( pass -1 for none )
	Variable overwrite // overwrite flag: ( 1 ) return last name in sequence ( 0 ) return next name in sequence
	
	Variable count
	String wName
	
	if ( strlen( df ) > 0 )
		df = LastPathColon( df, 1 )
	endif
	
	for ( count = 0; count <= 9999; count += 1 ) // search thru sequence numbers
	
		if ( chanNum == -1 )
			wName = df + prefix + num2istr( count )
		else
			wName = df + prefix+ ChanNum2Char( chanNum ) + num2istr( count )
		endif
		
		if ( !WaveExists( $wName ) )
			break
		endif
		
	endfor
	
	if ( ( overwrite == 0 ) || ( count == 0 ) )
		return count
	else
		return ( count-1 )
	endif

End // NextWaveNum

//****************************************************************
//****************************************************************

Function /S NextWaveName2( datafolder, prefix, chanNum, overwrite ) 
	String datafolder // data folder ( enter "" for current data folder )
	String prefix // wave prefix name
	Variable chanNum // channel number ( pass -1 for none )
	Variable overwrite // overwrite flag: ( 1 ) return last name in sequence ( 0 ) return next name in sequence
	
	Variable waveNum = NextWaveNum( datafolder, prefix, chanNum, overwrite )
	
	return GetWaveName( prefix, chanNum, waveNum )
	
End // NextWaveName2

//****************************************************************
//****************************************************************

Function /S NextWaveNamePadded( df, prefix, chanNum, overwrite, maxNum ) 
	String df // data folder
	String prefix // wave prefix name
	Variable chanNum // channel number ( pass -1 for none )
	Variable overwrite // overwrite flag: ( 1 ) return last name in sequence ( 0 ) return next name in sequence
	Variable maxNum
	
	Variable waveNum = NextWaveNum( df, prefix, chanNum, overwrite )
	
	return GetWaveNamePadded( prefix, chanNum, waveNum, maxNum )
	
End // NextWaveNamePadded

//****************************************************************
//****************************************************************

Function /S NMPrefixUnique( wavePrefix )
	String wavePrefix
	
	Variable icnt
	String prefix, wList
	
	for ( icnt = 0 ; icnt < 9999 ; icnt += 1 )
	
		prefix = wavePrefix + num2istr( icnt )
		wList = WaveList( prefix + "*", ";", "" )
				
		if ( ItemsInList( wList ) == 0 )
			return prefix
		endif
	
	endfor
	
	return ""

End // NMPrefixUnique

//****************************************************************
//****************************************************************

Function /S CheckNMPrefixUnique( wavePrefix, defaultPrefix, chanNum )
	String wavePrefix // wave prefix to test
	String defaultPrefix // wave prefix to use if there is a conflict
	Variable chanNum // ( -1 ) for all
	
	Variable seq, wcnt, ccnt, cbgn = chanNum, cend = chanNum, conflict
	String wNameMatch, wList, wName, prefix
	
	if ( chanNum < 0 )
		cbgn = 0
		cend = NMNumChannels() - 1
	endif
	
	do
	
		conflict = 0
	
		for ( ccnt = cbgn ; ccnt <= cend ; ccnt += 1 )
		
			wNameMatch = wavePrefix + "*" + ChanNum2Char( ccnt ) + "*"
				
			wList = WaveList( wNameMatch, ";", "" )
				
			if ( ItemsInList( wList ) > 0 )
				conflict = 1
				break
			endif
		
		endfor
		
		if ( !conflict )
			return wavePrefix
		endif
					
		DoAlert 2, "Warning: waves already exist with prefix " + NMQuotes( wavePrefix ) + ". Do you want to overwrite these waves?"
		
		if ( V_flag == 1 )
		
			for ( ccnt = cbgn ; ccnt <= cend ; ccnt += 1 )
		
				wNameMatch = wavePrefix + "*" + ChanNum2Char( ccnt ) + "*"
					
				wList = WaveList( wNameMatch, ";", "Text:0" )
					
				for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
					wName = StringFromList( wcnt, wList )
					KillWaves /Z $wName
				endfor
				
				wList = WaveList( wNameMatch, ";", "Text:0" )
				
				if ( ItemsInList( wList ) > 0 )
					NMDoAlert( "New Wave Prefix Abort: failed to kill the following waves: " + wList )
					return ""
				endif
			
			endfor
			
		elseif ( V_flag == 2 )
		
			wavePrefix = NMPrefixUnique( defaultPrefix )
			
			Prompt wavePrefix, "enter new wave prefix name:"
			DoPrompt "New Wave Prefix", wavePrefix
			
			if ( V_flag == 1 )
				return ""
			endif
			
		else
		
			return ""
			
		endif
	
	while( 1 )
	
End // CheckNMPrefixUnique

//****************************************************************
//****************************************************************
//
//	Graph Functions
//
//****************************************************************
//****************************************************************

Function /S NextGraphName( prefix, chanNum, overwrite )
	String prefix // graph name prefix
	Variable chanNum // channel number ( pass -1 for none )
	Variable overwrite // overwrite flag: ( 1 ) return last name in sequence ( 0 ) return next name in sequence
	
	Variable count
	String gName
	
	for ( count = 0; count <= 99; count += 1 ) // search thru sequence numbers
	
		if ( chanNum == -1 )
			gName = prefix + num2istr( count )
		else
			gName = prefix + ChanNum2Char( chanNum ) + num2istr( count )
		endif
		
		if ( WinType( gName ) == 0 )
			break // found name not in use
		endif
		
	endfor
	
	if ( ( overwrite == 0 ) || ( count == 0 ) )
		return NMCheckStringName( gName )
	elseif ( chanNum < 0 )
		return NMCheckStringName( prefix + num2istr( count-1 ) )
	else
		return NMCheckStringName( prefix + ChanNum2Char( chanNum ) + num2istr( count-1 ) )
	endif

End // NextGraphName

//****************************************************************
//****************************************************************
//
//	Display Functions ( Computer Stats and Window Cascade )
//
//****************************************************************
//****************************************************************

Function NMScreenPixelsX([igorFrame])
	Variable igorFrame

	Variable d0, x0, y0, x1, y1, defaultPixels = 1000
	String s0
	
	if ( igorFrame && StringMatch( NMComputerType(), "pc" ) )
		GetWindow kwFrameInner wsizeDC // frames on Windows only
		return v_right - v_left
	endif

	s0 = IgorInfo( 0 )
	s0 = StringByKey( "SCREEN1", s0, ":" )
	
	sscanf s0, "%*[ DEPTH= ]%d%*[ ,RECT= ]%d%*[ , ]%d%*[ , ]%d%*[ , ]%d", d0, x0, y0, x1, y1
	
	if ( numtype( x1 ) == 0 )
		return x1
	endif
	
	return defaultPixels

End // NMScreenPixelsX

//****************************************************************
//****************************************************************

Function NMScreenPixelsY([igorFrame])
	Variable igorFrame

	Variable d0, x0, y0, x1, y1, defaultPixels = 800
	String s0
	
	if ( igorFrame && StringMatch( NMComputerType(), "pc" ) )
		GetWindow kwFrameInner wsizeDC // frames on Windows only
		return v_bottom - v_top
	endif
	
	s0 = IgorInfo( 0 )
	s0 = StringByKey( "SCREEN1", s0, ":" )
	
	sscanf s0, "%*[ DEPTH= ]%d%*[ ,RECT= ]%d%*[ , ]%d%*[ , ]%d%*[ , ]%d", d0, x0, y0, x1, y1
	
	if ( numtype( y1 ) == 0 )
		return y1
	endif
	
	return defaultPixels

End // NMScreenPixelsY

//****************************************************************
//****************************************************************

Function NMScreenPointsX([igorFrame])
	Variable igorFrame
	
	return NMScreenPixelsX(igorFrame=igorFrame) * NMPointsPerPixel()
	
End // NMScreenPointsX

//****************************************************************
//****************************************************************

Function NMScreenPointsY([igorFrame])
	Variable igorFrame
	
	return NMScreenPixelsY(igorFrame=igorFrame) * NMPointsPerPixel()
	
End // NMScreenPointsY

//****************************************************************
//****************************************************************

Function NMPointsPerPixel()

	// Display - coordinates in points
	// Edit - coordinates in points
	// MoveWindow - coordinates in points
	// NewPanel - coordinates in pixels
	// GetWindow wsize - coordinates in points (Windows only)
	// GetWindow wsizeDC - coordinates in pixels (Windows only)

	Variable panelRes = PanelResolution( "" ) // points per inch (usually 72)
	
	Variable screenRes = ScreenResolution // pixels (dots) per inch (DPI)
	// Mac, 72 DPI
	// Windows, 96 (small fonts) or 120 (large fonts)
	
	return panelRes / screenRes

End // NMPointsPerPixel

//****************************************************************
//****************************************************************

Function /S NMComputerType()

	String s0 = IgorInfo( 2 )
	
	strswitch( s0 )
		case "Macintosh":
			return "mac"
	endswitch
	
	return "pc"

End // NMComputerType

//****************************************************************
//****************************************************************

Function NMWinCascade( windowName [ width, height, increment ] ) // cascade graph size and placement
	String windowName
	Variable width, height // set the width or height
	Variable increment // increment cascade counter ( 0 ) no ( 1 ) yes
	
	STRUCT Rect w
	
	if ( ( strlen( windowName ) == 0 ) || ( WinType( windowName ) == 0 ) )
		return -1
	endif
	
	if ( ParamIsDefault( increment ) )
		increment = 1
	endif
	
	NMWinCascadeRect( w, increment = increment )
	
	MoveWindow /W=$windowName w.left, w.top, w.right, w.bottom
	
	return 0

End // NMWinCascade

//****************************************************************
//****************************************************************
//
//		STRUCT Rect w
//		NMWinCascadeRect( w )
//		Display /W=(w.left,w.top,w.right,w.bottom) testing
//		
//****************************************************************
//****************************************************************

Function NMWinCascadeRect( w [ width, height, increment ] ) // cascade graph size and placement
	STRUCT Rect &w
	Variable width, height
	Variable increment // increment cascade counter ( 0 ) no ( 1 ) yes
	
	Variable offsetPC = 75, offsetMac = 50
	
	Variable xpoints = NMScreenPointsX()
	Variable ypoints = NMScreenPointsY()
	
	Variable cascade = NMVarGet( "Cascade" )
	String computer = NMComputerType()
	
	if ( ParamIsDefault( width ) || ( numtype( width ) > 0 ) )
		
		if ( StringMatch( computer, "pc" ) )
			width = NMCascadeWidthPC
		else
			width = NMCascadeWidthMac
		endif
	
	endif
	
	if ( ParamIsDefault( height ) || ( numtype( height ) > 0 ) )
		
		if ( StringMatch( computer, "pc" ) )
			height = NMCascadeHeightPC
		else
			height = NMCascadeHeightMac
		endif
	
	endif
	
	if ( ParamIsDefault( increment ) )
		increment = 1
	endif
	
	if ( StringMatch( computer, "pc" ) )
		w.left = offsetPC + NMCascadeIncPC * cascade
		w.top = offsetPC + NMCascadeIncPC * cascade
	else
		w.left = offsetMac + NMCascadeIncMac * cascade
		w.top = offsetMac + NMCascadeIncMac * cascade
	endif
	
	w.right = w.left + width
	w.bottom = w.top + height
	
	if ( increment )
	
		if ( ( w.left > xpoints * 0.5 ) || ( w.top > ypoints * 0.5 ) )
			cascade = 0 // reset Cascade counter
		else
			cascade += 1 // increment Cascade counter
		endif
		
		SetNMvar( NMDF + "Cascade", floor( cascade ) )
	
	endif
	
	return 0

End // NMWinCascadeRect

//****************************************************************
//****************************************************************

Function NMWinCascadeReset()

	SetNMvar( NMDF + "Cascade", 0 )
	
End // NMWinCascadeReset

//****************************************************************
//****************************************************************
//
//	NM history/notebook functions
//
//****************************************************************
//****************************************************************

Function NMHistoryManager( message, where ) // print notes to Igor history and/or notebook
	String message
	Variable where // use negative numbers for command history
	
	String nbName
	
	if ( ( strlen( message ) == 0 ) || ( where == 0 ) )
		return 0
	endif
	
	if ( ( abs( where ) == 1 ) || ( abs( where ) == 3 ) )
		Print message // Igor History
	endif
	
	if ( ( where == 2 ) || ( where == 3 ) ) // results notebook
		nbName = NMNotebookName( "results" )
		NMNotebookResults()
		Notebook $nbName selection={endOfFile, endOfFile}
		NoteBook $nbName text=NMCR + message
	elseif ( ( where == -2 ) || ( where == -3 ) ) // command notebook
		nbName = NMNotebookName( "commands" )
		NMNotebookCommands()
		Notebook $nbName selection={endOfFile, endOfFile}
		NoteBook $nbName text=NMCR + message
	endif

End // NMHistoryManager

//****************************************************************
//****************************************************************

Function /S NMNotebookName( select )
	String select // "results" or "commands"
	
	strswitch( select )
		case "results":
			return "NM_ResultsHistory"
		case "commands":
			return "NM_CommandHistory"
	endswitch
	
	return ""

End // NMNotebookName

//****************************************************************
//****************************************************************

Function NMNotebookResults()

	String nbName = NMNotebookName( "results" )
	
	STRUCT Rect w
		
	if ( WinType( nbName ) == 5 ) // create new notebook
		return 0
	endif
	
	NMWinCascadeRect( w )
	
	NewNotebook /F=0/N=$nbName/W=(w.left,w.top,w.right,w.bottom) as "NeuroMatic Results Notebook"
	
	NoteBook $nbName text="Date: " + date()
	NoteBook $nbName text=NMCR + "Time: " + time()
	NoteBook $nbName text=NMCR

End // NMNotebookResults

//****************************************************************
//****************************************************************

Function NMNotebookCommands()

	String nbName = NMNotebookName( "commands" )

	if ( WinType( nbName ) == 5 ) // create new notebook
		return 0
	endif
	
	NewNotebook /F=0/N=$nbName/W=( 400,100,800,400 ) as "NeuroMatic Command Notebook"
	
	NoteBook $nbName text="Date: " + date()
	NoteBook $nbName text=NMCR + "Time: " + time()
	NoteBook $nbName text=NMCR + NMCR + "**************************************************************************************"
	NoteBook $nbName text=NMCR + "**************************************************************************************"
	NoteBook $nbName text=NMCR + "***\tNote: the following commands can be copied to an Igor procedure file"
	NoteBook $nbName text=NMCR + "***\t( such as NM_DemoTab.ipf ) and used in your own macros or functions."
	NoteBook $nbName text=NMCR + "***\tFor example:"
	NoteBook $nbName text=NMCR + "***"
	NoteBook $nbName text=NMCR + "***\t\tMacro MyMacro()"
	NoteBook $nbName text=NMCR + "***\t\t\tNMChanSelect( \"A\" )"
	NoteBook $nbName text=NMCR + "***\t\t\tNMWaveSelect( \"Set1\" )"
	NoteBook $nbName text=NMCR + "***\t\t\tNMPlot( \"rainbow\" , 0 , 0 )"
	NoteBook $nbName text=NMCR + "***\t\t\tNMBaselineWaves( 1 , 0 , 15 )"
	NoteBook $nbName text=NMCR + "***\t\t\tNMWavesStats( 2 , 0 , 1 , 1 , 0 , 0 , 1 , 1 )"
	NoteBook $nbName text=NMCR + "***\t\tEnd"
	NoteBook $nbName text=NMCR + "***"
	NoteBook $nbName text=NMCR + "**************************************************************************************"
	NoteBook $nbName text=NMCR + "**************************************************************************************"

End // NMNotebookCommands

//****************************************************************
//****************************************************************

Function NMHistory( message ) // print notes to Igor history and/or notebook
	String message
	
	NMHistoryManager( message, NMVarGet( "WriteHistory" ) )

End // NMHistory

//****************************************************************
//****************************************************************

Function NMCommandWindowReposition()

	Variable vleft, vtop, vright, vbottom // points
	Variable yheight, yoffset // points
	
	DoWindow /F/H/Hide=0
	
	Variable xpoints = NMScreenPointsX(igorFrame=1)
	Variable ypoints = NMScreenPointsY(igorFrame=1)
	
	if ( StringMatch( NMComputerType(), "pc" ) )
		
		yheight = 150
		yoffset = 13
		
		vleft = 6
		vright = xpoints - 6
		vbottom = ypoints + yoffset
		vtop = vbottom - yheight
	
	else
	
		yheight = 180
		yoffset = 50
	
		vleft = 0
		vright = xpoints
		vbottom = ypoints - yoffset
		vtop = vbottom - yheight
	
	endif
	
	MoveWindow /C vleft, vtop, vright, vbottom
	
End // NMCommandWindowReposition

//****************************************************************
//****************************************************************

Function NMCommandHistory( varList ) // print NM function command to history
	String varList // "5;8;10;\stest;" ( \s for string )
	
	String fxnName = GetRTStackInfo( 2 )
	
	return NMCmdHistory( fxnName, varList )
	
End // NMCommandHistory

//****************************************************************
//****************************************************************

Function NMCmdHistory( fxnName, varList [ extraSpaces ] ) // print NM command to history
	String fxnName // e.g. "NMSpikeRasterPSTH"
	String varList // "5;8;10;\stest;" ( \s for string )
	Variable extraSpaces
	
	Variable extraReturn = 0
	String bullet = "", cmd, returnStr = ""
	
	Variable history = NMVarGet( "WriteHistory" )
	Variable cmdhistory = NMVarGet( "CmdHistory" )
	
	String computer = NMComputerType()
	
	if ( strlen( fxnName ) == 0 )
		fxnName = GetRTStackInfo( 2 )
	endif
	
	if ( extraReturn )
		returnStr = NMCR
	endif
	
	switch( cmdhistory )
		default:
			return 0
		case 1:
			bullet = NMCmdHistoryBullet()
			cmd = returnStr + bullet + fxnName + "( "
			break
		case 2:
		case 3:
			cmd = returnStr + fxnName + "( "
			break
	endswitch
	
	cmd += NMCmdVarListConvert( varList )
	
	cmd += " )"
	
	cmd = ReplaceString( "  ", cmd, " " )
	cmd = ReplaceString( "  ", cmd, " " )
	cmd = ReplaceString( "( )", cmd, "()" )
	
	if ( !extraSpaces )
		cmd = ReplaceString( " = ", cmd, "=" )
		cmd = ReplaceString( " , ", cmd, ", " )
	endif
	
	NMHistoryManager( cmd, -1 * cmdhistory )
	
End // NMCmdHistory

//****************************************************************
//****************************************************************

Function /S NMCmdHistoryBullet()

	String computer = NMComputerType()
	
	if ( StringMatch( computer, "pc" ) )
		return "•"
	else
		return "¥"
	endif

End // NMCmdHistoryBullet

//****************************************************************
//****************************************************************

Function /S NMHistoryOutputWaves( [ fxn, wList, subfolder, noHistory ] )
	String fxn
	String wList
	String subfolder
	Variable noHistory // use this to get text
	
	String txt
	
	if ( NMVarGet( "WriteHistory" ) == 0 )
		return ""
	endif
	
	if ( ParamIsDefault( fxn ) )
		fxn = GetRTStackInfo( 2 )
	endif
	
	if ( ParamIsDefault( wList ) )
		wList = StrVarOrDefault( NMDF + "OutputWaveList", "" )
	endif
	
	if ( ParamIsDefault( subfolder ) )
		subfolder = ""
	endif
	
	if ( ( ItemsInList( wList ) == 0 ) && ( strlen( subfolder ) == 0 ) )
		return "" // no waves
	endif
	
	txt = fxn
	
	if ( strlen( subfolder ) > 0 )
	
		txt += " Output Subfolder : " + subfolder
		
	else
	
		if ( ItemsInList( wList ) == 1 )
			txt += " Output Wave : " + StringFromList( 0, wList )
		else
			txt += " Output Waves : " + wList
		endif
	
	endif
	
	if ( !noHistory )
		NMHistory( txt )
	endif
	
	return txt
	
End // NMHistoryOutputWaves

//****************************************************************
//****************************************************************

Function /S NMHistoryOutputWindows( [ fxn, windowList, noHistory ] )
	String fxn
	String windowList
	Variable noHistory // use this to get text
	
	String txt
	
	if ( NMVarGet( "WriteHistory" ) == 0 )
		return ""
	endif
	
	if ( ParamIsDefault( fxn ) )
		fxn = GetRTStackInfo( 2 )
	endif
	
	if ( ParamIsDefault( windowList ) )
		windowList = StrVarOrDefault( NMDF + "OutputWinList", "" )
	endif
	
	if ( ItemsInList( windowList ) == 0 )
		return "" // no windows
	endif
	
	txt = fxn
	
	if ( ItemsInList( windowList ) == 1 )
		txt += " Output Window : " + StringFromList( 0, windowList )
	else
		txt += " Output Windows : " + windowList
	endif
	
	if ( !noHistory )
		NMHistory( txt )
	endif
	
	return txt
	
End // NMHistoryOutputWindows

//****************************************************************
//****************************************************************

Function /S NMCmdVarListConvert( varList )
	String varList
	
	Variable icnt, jcnt, comma
	String varStr, listStr, cmd = ""
	
	for ( icnt = 0; icnt < ItemsInList( varList ); icnt += 1 )
	
		varStr = StringFromList( icnt, varList )
		
		if ( StringMatch( varStr[ 0, 1 ], "\s" ) ) // string variable
		
			varStr = varStr[ 2, inf ]
			varStr = NMQuotes( varStr )
			
		elseif ( StringMatch( varStr[ 0, 1 ], "\l" ) ) // string list
		
			listStr = varStr[ 2, inf ]
			listStr = ReplaceString( "\c", listStr, "," )
			listStr = ReplaceString( "\i", listStr, ";" )
			varStr = NMQuotes( listStr )
			
		elseif ( StringMatch( varStr[ 0, 2 ], "\os" ) ) // optional string variable
		
			varStr = varStr[ 3, inf ]
			
			jcnt = strsearch( varStr, " = ", 0 )
			
			if ( jcnt < 0 )
				continue
			endif
			
			jcnt += 2
			
			varStr = varStr[ 0, jcnt ] + NMQuotes( varStr[ jcnt + 1, inf ] )
			
		elseif ( StringMatch( varStr[ 0, 2 ], "\ol" ) ) // optional string list
		
			varStr = varStr[ 3, inf ]
			
			jcnt = strsearch( varStr, " = ", 0 )
			
			if ( jcnt < 0 )
				continue
			endif
			
			jcnt += 2
			
			listStr = varStr[ jcnt + 1, inf ]
			listStr = ReplaceString( "\c", listStr, "," )
			listStr = ReplaceString( "\i", listStr, ";" )
			varStr = varStr[ 0, jcnt ] + NMQuotes( listStr )
			
		endif
		
		if ( comma )
			cmd += ","
		endif
		
		cmd += " " + varStr + " "
		
		comma = 1
		
	endfor
	
	return cmd
	
End // NMCmdVarListConvert

//****************************************************************
//****************************************************************

Function /S NMCmdHistoryNumOptional( fxnName, varName, numVar [ integer ] )
	String fxnName // e.g. "NMStatsSet"
	String varName
	Variable numVar
	Variable integer

	String vlist = NMCmdNumOptional( varName, numVar, "", integer = integer )
	
	if ( strlen( fxnName ) == 0 )
		fxnName = GetRTStackInfo( 2 )
	endif
	
	NMCmdHistory( fxnName, vlist )

End // NMCmdHistoryNumOptional

//****************************************************************
//****************************************************************

Function /S NMCmdHistoryStrOptional( fxnName, strVarName, strVar )
	String fxnName // e.g. "NMStatsSet"
	String strVarName
	String strVar

	String vlist = NMCmdStrOptional( strVarName, strVar, "" )
	
	if ( strlen( fxnName ) == 0 )
		fxnName = GetRTStackInfo( 2 )
	endif
	
	NMCmdHistory( fxnName, vlist )

End // NMCmdHistoryStrOptional

//****************************************************************
//****************************************************************

Function /S NMCmdStr( strVar, varList )
	String strVar, varList
	
	Variable foundList = 0
	
	if ( strsearch( strVar, ",", 0 ) > 0 )
		foundList = 1
		strVar = ReplaceString( ",", strVar, "\c" )
	endif
		
	if ( strsearch( strVar, ";", 0 ) > 0 )
		foundList = 1
		strVar = ReplaceString( ";", strVar, "\i" )
	endif
	
	if ( foundList )
		return AddListItem( "\l"+strVar, varList, ";", inf )
	else
		return AddListItem( "\s"+strVar, varList, ";", inf )
	endif

End // NMCmdStr

//****************************************************************
//****************************************************************

Function /S NMCmdStrOptional( strVarName, strVar, varList )
	String strVarName
	String strVar, varList
	
	Variable foundList = 0
	
	if ( strsearch( strVar, ",", 0 ) > 0 )
		foundList = 1
		strVar = ReplaceString( ",", strVar, "\c" )
	endif
	
	if ( strsearch( strVar, ";", 0 ) > 0 )
		foundList = 1
		strVar = ReplaceString( ";", strVar, "\i" )
	endif
	
	if ( foundList )
		return AddListItem( "\ol" + strVarName + " = " + strVar, varList, ";", inf )
	else
		return AddListItem( "\os" + strVarName + " = " + strVar, varList, ";", inf )
	endif
	
End // NMCmdStrOptional

//****************************************************************
//****************************************************************

Function /S NMCmdNum( numVar, varList [ integer ] )
	Variable numVar
	String varList
	Variable integer

	if ( integer )
		return AddListItem( num2istr( numVar ), varList, ";", inf )
	else
		return AddListItem( num2str( numVar ), varList, ";", inf )
	endif
	
End // NMCmdNum

//****************************************************************
//****************************************************************

Function /S NMCmdNumOptional( varName, numVar, varList [ integer ] )
	String varName
	Variable numVar
	String varList
	Variable integer
	
	if ( integer )
		return AddListItem( varName + " = " + num2istr( numVar ), varList, ";", inf )
	else
		return AddListItem( varName + " = " + num2str( numVar ), varList, ";", inf )
	endif

End // NMCmdNumOptional

//****************************************************************
//****************************************************************

Function NMDoAlert( promptStr [ title, alertType ] )
	String promptStr
	String title
	Variable alertType
		// 0:	Dialog with an OK button.
		// 1:	Dialog with Yes and No buttons.
		// 2:	Dialog with Yes, No, and Cancel buttons.
		
	Variable alert = NMVarGet( "AlertUser" )
	
	if ( ( alert == 0 ) || ( strlen( promptStr ) == 0 ) )
		return 0
	endif
	
	promptStr = promptStr[ 0, 250 ] // limit alert string
	
	if ( alert == 1 ) // execute Igor DoAlert
		
		if ( ParamIsDefault( title ) || ( strlen( title ) == 0 ) )
			title = "NM alert from function " + GetRTStackInfo( 2 )
		endif
		
		if ( ParamIsDefault( alertType ) || ( alertType > 2 ) )
			alertType = 0
		endif
	
		DoAlert /T=( title ) alertType, promptStr
		
		return V_flag
		// 1:	Yes clicked.
		// 2:	No clicked.
		// 3:	Cancel clicked.
	
	elseif  ( alert == 2 ) // print to command window
	
		NMHistory( promptStr )
		
	endif
	
	return 0

End // NMDoAlert

//****************************************************************
//****************************************************************
//
//	Misc Utility Functions
//
//****************************************************************
//****************************************************************

Function SetNMvar( varName, value ) // set variable to passed value within folder
	String varName
	Variable value
	
	String path = NMParent( varName )
	String vName = NMChild( varName )
	
	if ( strlen( varName ) == 0 )
		NM2Error( 21, "varName", varName )
		return -1
	endif
	
	if ( strlen( vName ) > 31 )
		NM2Error( 22, "varName", vName )
		return -1
	endif

	if ( ( strlen( path ) > 0 ) && !DataFolderExists( path ) )
		NM2Error( 30, "varName", varName )
		return -1
	endif

	if ( WaveExists( $varName ) && ( WaveType( $varName ) > 0 ) )
	
		NVAR tempVar = $varName
		
		tempVar = value
		
	else
	
		SVAR /Z stemp = $varName
		
		if ( SVAR_Exists( stemp ) )
			KillStrings /Z stemp // string exists, so need to kill it first
		endif
	
		Variable /G $varName = value
		
	endif
	
	return 0

End // SetNMvar

//****************************************************************
//****************************************************************

Function SetNMstr( strVarName, strValue ) // set string to passed value within NeuroMatic folder
	String strVarName, strValue
	
	String path = NMParent( strVarName )
	String vName = NMChild( strVarName )
	
	if ( strlen( strVarName ) == 0 )
		NM2Error( 21, "strVarName", strVarName )
		return -1
	endif
	
	if ( strlen( vName ) > 31 )
		NM2Error( 22, "strVarName", vName )
		return -1
	endif
	
	if ( ( strlen( path ) > 0 ) && !DataFolderExists( path ) )
		NM2Error( 30, "strVarName", strVarName )
		return -1
	endif

	if ( WaveExists( $strVarName ) && ( WaveType( $strVarName ) == 0 ) )
	
		SVAR tempStr = $strVarName
		
		tempStr = strValue
		
	else
	
		NVAR /Z vtemp = $strVarName
		
		if ( NVAR_Exists( vtemp ) )
			KillVariables /Z vtemp // numeric variable exists, so need to kill it first
		endif
		
		String /G $strVarName = strValue
		
	endif
	
	return 0

End // SetNMstr

//****************************************************************
//****************************************************************

Function SetNMwave( wname, pointNum, value )
	String wname
	Variable pointNum // point to set, or ( -1 ) all points
	Variable value
	
	String path = NMParent( wname )
	String swname = NMChild( wname )
	
	if ( strlen( wname ) == 0 )
		NM2Error( 21, "wname", wname )
		return -1
	endif
	
	if ( strlen( swname ) > 31 )
		NM2Error( 3, "wname", swname )
		return -1
	endif
	
	if ( numtype( pointNum ) > 0 )
		NM2Error( 10, "pointNum", num2istr( pointNum ) )
		return -1
	endif
	
	if ( ( strlen( path ) > 0 ) && !DataFolderExists( path ) )
		NM2Error( 30, "wname", wname )
		return -1
	endif
	
	if ( !WaveExists( $wname ) )
		CheckNMwave( wname, pointNum+1, Nan )
	endif
	
	Wave tempWave = $wname
	
	if ( pointNum < 0 )
		tempWave = value
	elseif ( pointNum < numpnts( tempWave ) )
		tempWave[ pointNum ] = value
	endif
	
	return 0

End // SetNMwave

//****************************************************************
//****************************************************************

Function SetNMtwave( wname, pointNum, strValue )
	String wname
	Variable pointNum // point to set, or ( -1 ) all points
	String strValue
	
	String path = NMParent( wname )
	String swname = NMChild( wname )
	
	if ( strlen( wname ) == 0 )
		NM2Error( 21, "wname", wname )
		return -1
	endif
	
	if ( strlen( swname ) > 31 )
		NM2Error( 3, "wname", swname )
		return -1
	endif
	
	if ( numtype( pointNum ) > 0 )
		NM2Error( 10, "pointNum", num2istr( pointNum ) )
		return -1
	endif
	
	if ( ( strlen( path ) > 0 ) && !DataFolderExists( path ) )
		NM2Error( 30, "wname", wname )
		return -1
	endif
	
	if ( !WaveExists( $wname ) )
		CheckNMtwave( wname, pointNum+1, strValue )
	endif
	
	Wave /T tempWave = $wname
	
	if ( pointNum < 0 )
		tempWave = strValue
	elseif ( pointNum < numpnts( tempWave ) )
		tempWave[ pointNum ] = strValue
	endif
	
	return 0

End // SetNMtwave

//****************************************************************
//****************************************************************

Function CheckNMvar( varName, defaultValue )
	String varName
	Variable defaultValue
	
	return SetNMvar( varName, NumVarOrDefault( varName, defaultValue ) )
	
End // CheckNMvar

//****************************************************************
//****************************************************************

Function CheckNMstr( strVarName, defaultValue )
	String strVarName
	String defaultValue
	
	return SetNMstr( strVarName, StrVarOrDefault( strVarName, defaultValue ) )
	
End // CheckNMstr

//****************************************************************
//****************************************************************

Function CheckNMwave( wList, nPoints, defaultValue )
	String wList // wave list
	Variable nPoints // ( -1 ) dont care
	Variable defaultValue
	
	return CheckNMwaveOfType( wList, nPoints, defaultValue, "R" )
	
End // CheckNMwave

//****************************************************************
//****************************************************************

Function CheckNMtwave( wList, nPoints, defaultStr )
	String wList
	Variable nPoints // ( -1 ) dont care
	String defaultStr
	
	Variable wcnt, error
	String wname, path
	
	if ( numtype( nPoints ) > 0 )
		return -1
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
		
		wname = StringFromList( wcnt, wList )
		path = NMParent( wName )
		
		if ( ( strlen( path ) > 0 ) && !DataFolderExists( path ) )
			error = -1
			continue
		endif
		
		CheckNMwaveOfType( wname, nPoints, 0, "T", defaultStr = defaultStr )
	
	endfor
	
	return error
	
End // CheckNMtwave

//****************************************************************
//****************************************************************

Function CheckNMWaveOfType( wList, nPoints, defaultValue, wType [ defaultStr ] ) // returns ( 0 ) did not make wave ( 1 ) did make wave
	String wList // wave list
	Variable nPoints // ( -1 ) dont care
	Variable defaultValue
	String wType // ( B ) 8-bit signed integer ( C ) complex ( D ) double precision ( I ) 32-bit signed integer ( R ) single precision real ( W ) 16-bit signed integer ( T ) text
	// ( UB, UI or UW ) unsigned integers
	String defaultStr // for text wave
	
	String wName, path
	Variable wcnt, nPoints2, makeFlag, error = 0
	
	if ( numtype( nPoints ) > 0 )
		return -1
	endif
	
	if ( nPoints < 0 )
		nPoints = 128
	endif
	
	if ( ParamIsDefault( defaultStr ) )
		defaultStr = ""
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		nPoints2 = numpnts( $wName )
		
		path = NMParent( wName )
		
		if ( ( strlen( path ) > 0 ) && !DataFolderExists( path ) )
			error = -1
			continue
		endif
		
		makeFlag = 0
		
		if ( !WaveExists( $wName ) )
		
			strswitch( wType )
				case "B":
					if ( ( WaveType( $wName ) & 0x08 ) != 1 )
						makeFlag = 1
					endif
					break
				case "UB":
					if ( ( ( WaveType( $wName ) & 0x08 ) != 1 ) && ( ( WaveType( $wName ) & 0x40 ) != 1 ) )
						makeFlag = 1
					endif
					break
				case "C":
					if ( ( WaveType( $wName ) & 0x01 ) != 1 )
						makeFlag = 1
					endif
					break
				case "D":
					if ( ( WaveType( $wName ) & 0x04 ) != 1 )
						makeFlag = 1
					endif
					break
				case "I":
					if ( ( WaveType( $wName ) & 0x20 ) != 1 )
						makeFlag = 1
					endif
					break
				case "UI":
					if ( ( ( WaveType( $wName ) & 0x20 ) != 1 ) && ( ( WaveType( $wName ) & 0x40 ) != 1 ) )
						makeFlag = 1
					endif
					break
				case "T":
					if ( WaveType( $wName ) != 0 )
						makeFlag = 1
					endif
					break
				case "W":
					if ( ( WaveType( $wName ) & 0x10 ) != 1 )
						makeFlag = 1
					endif
					break
				case "UW":
					if ( ( ( WaveType( $wName ) & 0x10 ) != 1 ) && ( ( WaveType( $wName ) & 0x40 ) != 1 ) )
						makeFlag = 1
					endif
					break
				case "R":
				default:
					if ( ( WaveType( $wName ) & 0x02 ) != 1 )
						makeFlag = 1
					endif
			endswitch
		
		endif
			
		if ( !WaveExists( $wName ) || makeFlag )
		
			strswitch( wType )
				case "B":
					Make /B/O/N=( nPoints ) $wName = defaultValue
					break
				case "UB":
					Make /B/U/O/N=( nPoints ) $wName = defaultValue
					break
				case "C":
					Make /C/O/N=( nPoints ) $wName = defaultValue
					break
				case "D":
					Make /D/O/N=( nPoints ) $wName = defaultValue
					break
				case "I":
					Make /I/O/N=( nPoints ) $wName = defaultValue
					break
				case "T":
					Make /T/O/N=( nPoints ) $wName = defaultStr
					break
				case "UI":
					Make /I/U/O/N=( nPoints ) $wName = defaultValue
					break
				case "W":
					Make /W/O/N=( nPoints ) $wName = defaultValue
					break
				case "UW":
					Make /W/U/O/N=( nPoints ) $wName = defaultValue
					break
				case "R":
				default:
					Make /O/N=( nPoints ) $wName = defaultValue
			endswitch
			
		elseif ( WaveExists( $wName ) && ( nPoints > 0 ) )
		
			strswitch( wType )
			
				case "T":
				
					nPoints2 = numpnts( $wName )
		
					if ( nPoints > nPoints2 )
					
						Redimension /N=( nPoints ) $wName
						
						Wave /T wtemp = $wName
						
						wtemp[ nPoints2, nPoints - 1 ] = defaultStr
						
					elseif ( nPoints < nPoints2 )
					
						Redimension /N=( nPoints ) $wName
						
					endif
				
					break
			
				default:
		
					nPoints2 = numpnts( $wName )
				
					if ( nPoints > nPoints2 )
					
						Redimension /N=( nPoints ) $wName
						
						Wave wtemp2 = $wName
						
						wtemp2[ nPoints2, nPoints - 1 ] = defaultValue
						
					elseif ( nPoints < nPoints2 )
					
						Redimension /N=( nPoints ) $wName
						
					endif
				
			endswitch
			
		endif
	
	endfor
	
	return error
	
End // CheckNMWaveOfType

//****************************************************************
//****************************************************************

Function /S NMNoteString( wname )
	String wname // wave name with note
	
	Variable icnt
	String txt, txt2 = ""

	if ( !WaveExists( $wname ) )
		return ""
	endif
	
	txt = note( $wname )
	
	for ( icnt = 0; icnt < strlen( txt ); icnt += 1 )
		if ( char2num( txt[ icnt ] ) == 13 ) // remove carriage return
			txt2 += ";"
		elseif ( char2num( txt[ icnt ] ) == 10 ) // remove new line
			// do nothing
		else
			txt2 += txt[ icnt ]
		endif
	endfor
	
	return txt2
	
End // NMNoteString

//****************************************************************
//****************************************************************

Function NMNoteExists( wname, key )
	String wname // wave name with note
	String key // "thresh", "xbgn", "xend", etc...

	if ( !WaveExists( $wname ) )
		return 0
	endif
	
	if ( numtype( NMNoteVarByKey( wname, key ) ) == 0 )
		return 1
	endif
	
	if ( strlen( NMNoteStrByKey( wname, key ) ) > 0 )
		return 1
	endif
	
	return 0
	
End // NMNoteExists

//****************************************************************
//****************************************************************

Function NMNoteVarByKey( wname, key )
	String wname // wave name with note
	String key // "thresh", "xbgn", "xend", etc...

	if ( !WaveExists( $wname ) )
		return Nan
	endif
	
	return str2num( StringByKey( key, NMNoteString( wname ) ) )

End // NMNoteVarByKey

//****************************************************************
//****************************************************************

Function /S NMNoteStrByKey( wname, key )
	String wname // wave name with note
	String key // "thresh", "xbgn", "xend", etc...

	if ( !WaveExists( $wname ) )
		return ""
	endif
	
	return StringByKey( key, NMNoteString( wname ) )

End // NMNoteStrByKey

//****************************************************************
//****************************************************************

Function NMNoteVarReplace( wname, key, replace )
	String wname // wave name with note
	String key // "thresh", "xbgn", "xend", etc...
	Variable replace // replace string
	
	NMNoteStrReplace( wname, key, num2str( replace ) )
	
End // NMNoteVarReplace

//****************************************************************
//****************************************************************

Function NMNoteStrReplace( wname, key, replace )
	String wname // wave name with note
	String key // "thresh", "xbgn", "xend", etc...
	String replace // replace string
	
	Variable icnt, jcnt, found, sl = strlen( key )
	String txt
	
	if ( !WaveExists( $wname ) )
		return -1
	endif
	
	txt = note( $wname )
	
	for ( icnt = 0; icnt < strlen( txt ); icnt += 1 )
		if ( StringMatch( txt[ icnt,icnt+sl-1 ], key ) )
			found = 1
			break
		endif
	endfor
	
	if ( !found )
		Note $wname, key + ":" + replace
		return -1
	endif
	
	found = 0
	
	for ( icnt = icnt+sl; icnt < strlen( txt ); icnt += 1 )
	
		if ( StringMatch( txt[ icnt,icnt ], ":" ) )
			found = icnt
			break
		endif
		
		if ( StringMatch( txt[ icnt,icnt ], "=" ) )
			found = icnt
			break
		endif
		
	endfor
	
	if ( !found )
		return -1
	endif
	
	for ( jcnt = icnt+1; jcnt < strlen( txt ); jcnt += 1 )
	
		if ( StringMatch( txt[ jcnt,jcnt ], ";" ) )
			found = jcnt
			break
		endif
		
		if ( char2num( txt[ jcnt ] ) == 13 )
			found = jcnt
			break
		endif
		
	endfor
	
	txt = txt[ 0, icnt ] + replace + txt[ jcnt, inf ]
	
	Note /K $wname
	Note $wname, txt

End // NMNoteStrReplace

//****************************************************************
//****************************************************************

Function NMNoteDelete( wname, key )
	String wname // wave name with note
	String key // find line with this key
	
	Variable icnt, jcnt, found, replace, ibgn, iend, sl, kl = strlen( key )
	String txt
	
	if ( !WaveExists( $wname ) )
		return -1
	endif
	
	txt = note( $wname )
	
	do 
	
		sl = strlen( txt )
		found = 0
	
		for ( icnt = sl-kl; icnt >= 0 ; icnt -= 1 )
			if ( StringMatch( txt[ icnt,icnt+kl-1 ], key ) )
				found = 1
				break
			endif
		endfor
		
		if ( found )
		
			ibgn = Nan
			iend = Nan
		
			for ( jcnt = icnt; jcnt >= 0; jcnt -= 1 )
			
				if ( StringMatch( txt[ jcnt,jcnt ], ";" ) )
					ibgn = jcnt
					break
				endif
				
				if ( char2num( txt[ jcnt ] ) == 13 )
					ibgn = jcnt
					break
				endif
				
			endfor
			
			if ( numtype( ibgn ) > 0 )
				break
			endif
			
			for ( jcnt = icnt; jcnt < sl; jcnt += 1 )
			
				if ( StringMatch( txt[ jcnt,jcnt ], ";" ) )
					iend = jcnt+1
					break
				endif
				
				if ( char2num( txt[ jcnt ] ) == 13 )
					iend = jcnt+1
					break
				endif
				
			endfor
			
			if ( numtype( iend ) > 0 )
				txt = txt[ 0, ibgn ]
			else
				txt = txt[ 0, ibgn ] + txt[ iend, inf ]
			endif
			
			replace = 1
			
		else
		
			break
			
		endif
	
	
	while ( 1 )
	
	
	if ( !replace )
		return -1
	endif
	
	Note /K $wname
	Note $wname, txt

End // NMNoteDelete

//****************************************************************
//****************************************************************

Function /S NMNoteLabel( xy, wList, defaultStr [ folder ] ) // quick search for first label in wave list
	String xy // "x" or "y"
	String wList
	String defaultStr
	String folder
	
	Variable wcnt
	String wName, xyLabel = ""
	
	if ( ItemsInList( wList ) == 0 )
		return defaultStr
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		xyLabel = NMNoteStrByKey( folder + wName, xy+"Label" )
		
		if ( strlen( xyLabel ) == 0 )
			xyLabel = NMNoteStrByKey( folder + wName, xy+"dim" )
		endif
		
		if ( strlen( xyLabel ) > 0 )
			return xyLabel // returns first finding of label
		endif
	
	endfor
	
	return defaultStr

End // NMNoteLabel

//****************************************************************
//****************************************************************

Function /S NMNoteLabelList( xy, wList [ folder ] )
	String xy // "x" or "y"
	String wList
	String folder
	
	Variable wcnt
	String wName, xyLabel, labelList = ""
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		xyLabel = NMNoteStrByKey( folder + wName, xy+"Label" )
		
		if ( strlen( xyLabel ) == 0 )
			xyLabel = NMNoteStrByKey( folder + wName, xy+"dim" )
		endif
		
		if ( strlen( xyLabel ) > 0 )
			labelList = NMAddToList( xyLabel, labelList, ";" )
		endif
	
	endfor
	
	return labelList

End // NMNoteLabelList

//****************************************************************
//****************************************************************

Function NMNoteType( wName, wType, xLabel, yLabel, wNote )
	String wName, wType, xLabel, yLabel, wNote
	
	if ( !WaveExists( $wName ) )
		return -1
	endif
	
	Note /K $wName
	Note $wName, "Source:" + wName // NMChild( wName )
	Note $wName, "Type:" + wType
	Note $wName, "XLabel:" + xLabel
	Note $wName, "YLabel:" + yLabel
	
	if ( StringMatch( wNote, "_FXN_" ) )
		wNote = "Func:" + GetRTStackInfo( 2 )
	endif
	
	if ( strlen( wNote ) > 0 )
		Note $wName, wNote
	endif
	
	return 0

End // NMNoteType

//****************************************************************
//****************************************************************

Function /S NMNoteCheck( noteStr )
	String noteStr
	
	noteStr = ReplaceString( ":", noteStr, "," )
	
	return noteStr
	
End // NMNoteCheck

//****************************************************************
//****************************************************************

Function /S NMPromptStr( title )
	String title
	
	Variable numActiveWaves
	
	String prefixFolder = CurrentNMPrefixFolder()
	String chanSelect = NMChanSelectStr()
	String waveSelect = NMWaveSelectGet()
	
	if ( strlen( prefixFolder ) > 0 )
		numActiveWaves = NMVarGet( "NumActiveWaves" )
	endif
	
	if ( strlen( title ) > 0 )
		title += " : "
	endif
	
	if ( StringMatch( chanSelect, "All" ) )
		title += "All Ch"
	else
		title += "Ch " + NMChanSelectStr()
	endif
	
	if ( StringMatch( waveSelect, "All" ) )
		title += " : All Waves"
	else
		title += " : " + waveSelect
	endif
	
	title += " : n = " + num2istr( numActiveWaves )
	
	return title

End // NMPromptStr

//****************************************************************
//****************************************************************

Function NMReturnStr2Num( returnStr )
	String returnStr
	
	if ( strlen( returnStr ) > 0 )
		return 1
	else
		return 0
	endif
	
End // NMReturnStr2Num

//****************************************************************
//****************************************************************

Function /S NMPrefixNext( pPrefix, wPrefix )
	String pPrefix // pre-prefix ( e.g. "MN" or "ST" )
	String wPrefix // wave prefix or ( "" ) for current
	
	Variable icnt
	String newPrefix, wlist
	
	if ( strlen( wPrefix ) == 0 )
		wPrefix = CurrentNMWavePrefix()
	endif
	
	if ( StringMatch( wPrefix[ 0,1 ], pPrefix ) )
		icnt = strsearch( wPrefix, "_", 0 )
		wPrefix = wPrefix[ icnt+1,inf ]
	endif
	
	newPrefix = pPrefix + "_" + wPrefix
	
	wlist = WaveList( newPrefix + "*", ";", "" )
	
	if ( ItemsInlist( wlist ) == 0 )
		return newPrefix
	endif
	
	for ( icnt = 0; icnt < 99; icnt += 1 )
	
		newPrefix = pPrefix + num2istr( icnt ) + "_" + wPrefix
		wlist = WaveList( newPrefix + "*", ";", "" )
		
		if ( ItemsInList( wlist ) == 0 )
			return newPrefix
		endif
		
	endfor
	
	return ""

End // NMPrefixNext

//****************************************************************
//****************************************************************

Function /S NMWaveUnitsList( xy, wList )
	String xy // "x" or "y"
	String wList // wave list
	
	Variable wcnt
	String wName, str, units, unitsList = ""
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( !WaveExists( $wName ) )
			continue
		endif
		
		units = NMWaveUnits( xy, wName )
		
		if ( strlen( units ) > 0 )
			unitsList = NMAddToList( units, unitsList, ";" )
		endif
		
	endfor
	
	if ( ItemsInList( unitsList ) == 1 )
		return StringFromList( 0, unitsList )
	elseif ( ItemsInList( unitsList ) > 1 )
		return unitsList
	endif
	
	return ""
		
End // NMWaveUnitsList

//****************************************************************
//****************************************************************

Function /S NMWaveUnits( xy, wName )
	String xy // "x" or "y"
	String wName // wave name
	
	String str, units
		
	if ( !WaveExists( $wName ) )
		return ""
	endif
	
	str = WaveInfo( $wName, 0 )

	if ( StringMatch( xy, "x" ) )
		units = StringByKey( "XUNITS", str ) // Igor wave x-units
	elseif ( StringMatch( xy, "y" ) )
		units = StringByKey( "DUNITS", str ) // Igor wave y-units
	else
		units = ""
	endif
	
	if ( strlen( units ) > 0 )
		return units
	endif
	
	if ( StringMatch( xy, "x" ) )
		
		units = NMNoteStrByKey( wName, "ADCunitsX" ) // NM acquisition units
		
		if ( ( strlen( units ) > 0 ) && StringMatch( units[ 0, 3 ] , "msec" ) )
			return units[ 0, 3 ]
		endif
		
		if ( ( strlen( units ) > 0 ) && StringMatch( units[ 0, 1] , "ms" ) )
			return units[ 0, 1 ]
		endif
		
		if ( strlen( units ) > 0 )
			return units
		endif
		
		units = NMNoteStrByKey( wName, "XUnits" ) // general NM units
		
		if ( strlen( units ) > 0 )
			return units
		endif
	
	elseif ( StringMatch( xy, "y" ) )
	
		units = NMNoteStrByKey( wName, "ADCunits" ) // NM acquisition units
		
		if ( strlen( units ) > 0 )
			return units
		endif
		
		units = NMNoteStrByKey( wName, "YUnits" ) // general NM units
		
		if ( strlen( units ) > 0 )
			return units
		endif
	
	endif
	
	// still did not find...
	
	str = NMNoteLabel( xy, wName, "" ) // try general NM xy-label
	
	if ( strlen( str ) > 0 )
	
		units = UnitsFromStr( str )
		
		if ( strlen( units ) > 0 )
			return units
		else
			return str
		endif
		
	endif
	
	return "" // found nothing
	
End // NMWaveUnits

//****************************************************************
//****************************************************************

Function RemoveWaveUnits( wName )
	String wName
	
	Variable xstart, dx, ystart = 0, dy = 1
	
	if ( !WaveExists( $wName ) )
		return -1
	endif
	
	dx = DimDelta( $wName, 0 )
	xstart = DimOffset( $wName, 0 )
	
	SetScale /P x, xstart, dx, "", $wName
	
	if ( DimSize( $wName, 1 ) > 1 )
		dy = DimDelta( $wName, 1 )
		ystart = DimOffset( $wName, 1 )
	endif
	
	SetScale /P y, ystart, dy, "", $wName

End // RemoveWaveUnits

//****************************************************************
//****************************************************************
//
//	NM Error Functions
//
//****************************************************************
//****************************************************************

Function /S NMErr( errorStr )
	String errorStr
	
	errorStr = "NM Error : " + GetRTStackInfo( 2 ) + " : " + errorStr
	
	SetNMstr( NMDF + "ErrorStr", errorStr )

	NMDoAlert( errorStr )
	
	return errorStr
	
End // NMErr

//****************************************************************
//****************************************************************

Function NM2Error( errorNum, objectName, objectValue ) // e.g. NM2Error( 10, "searchTime", num2str( searchTime ) )
	Variable errorNum
	String objectName
	String objectValue
	
	String functionName = GetRTStackInfo( 2 )
	
	if ( IsNMon() )
		return NMError( errorNum, functionName, objectName, objectValue )
	endif
	
End // NM2Error

//****************************************************************
//****************************************************************

Function /S NM2ErrorStr( errorNum, objectName, objectValue )
	Variable errorNum
	String objectName
	String objectValue
	
	String functionName = GetRTStackInfo( 2 )
	
	if ( IsNMon() )
		NMError( errorNum,  functionName, objectName, objectValue )
	endif
	
	//return "NMError " + num2istr( errorNum )
	return ""
	
End // NM2ErrorStr

//****************************************************************
//****************************************************************

Function /S NMErrorStr( errorNum, functionName, objectName, objectValue )
	Variable errorNum
	String functionName
	String objectName
	String objectValue
	
	if ( IsNMon() )
		NMError( errorNum, functionName, objectName, objectValue )
	endif
	
	//return "NMError " + num2istr( errorNum )
	return ""
	
End // NMErrorStr

//****************************************************************
//****************************************************************

Function NMError( errorNum, functionName, objectName, objectValue )
	Variable errorNum
	String functionName
	String objectName
	String objectValue
	
	String title, errorStr = ""
	
	if ( !IsNMon() )
		return -1
	endif
	
	if ( strlen( functionName ) == 0 )
		functionName = GetRTStackInfo( 2 )
	endif
	
	title = "NM Error From " + functionName
	
	if ( strlen( objectName ) > 0 )
		errorStr += objectName
	endif

	switch( errorNum )
	
		// case 0: // DO NOT USE, error 0 indicates there is no error
	
		// wave errors
	
		case 1:
			if ( strlen( objectValue ) > 0 )
				errorStr += " : wave " + NMQuotes( objectValue ) + " does not exist or is the wrong type."
			else
				errorStr += " : wave does not exist or is the wrong type."
			endif
			break
			
		case 2:
			errorStr += " : wave " + NMQuotes( objectValue ) + " already exists."
			break
			
		case 3:
			errorStr += " : wave name exceeds 31 characters : " + objectValue
			break
			
		case 4:
			errorStr += " : detected no waves to process."
			break
			
		case 5:
			errorStr += " : wave " + NMQuotes( objectValue ) + " has wrong dimensions."
			break
			
			
		// variable errors
		
		case 10:
			errorStr += " : variable has an unnacceptable value of " + objectValue
			break
			
		case 11:
			errorStr += " : variable has no value."
			break
			
		case 12:
			errorStr += " : variable name exceeds 31 characters : " + objectValue
			break
			
		case 13:
			errorStr += " : variable does not exist."
			break
		
		
		// string errors
		
		case 20:
			errorStr += " : string has an unnacceptable value of " + NMQuotes( objectValue )
			break
			
		case 21:
			errorStr += " : string has no value."
			break
			
		case 22:
			errorStr += " : string name exceeds 31 characters : " + NMQuotes( objectValue )
			break
			
		case 23:
			errorStr += " : string does not exist."
			break
			
		case 24:
			errorStr += " : string name already exists as a function/operation name."
			break
		
		
		// folder errors
		
		case 30:
			errorStr += " : folder " + NMQuotes( objectValue ) + " does not exist."
			break
			
		case 31:
			errorStr += " : folder " + NMQuotes( objectValue ) + " already exists."
			break
			
		case 32:
			errorStr += " : folder name exceeds 31 characters : " + objectValue
			break
			
		case 33:
			errorStr += " : destination folder is the same as source : " + objectValue
			break
			
		case 34:
			errorStr += " : folder " + NMQuotes( objectValue ) + " is not a NM data folder."
			break
			
		// graph errors
		
		case 40:
			errorStr += " : graph " + NMQuotes( objectValue ) + " does not exist."
			break
		
		case 41:
			errorStr += " : graph name conflict with " + NMQuotes( objectValue ) + "."
			break
		
			
		// table errors
			
		case 50:
			errorStr += " : table " + NMQuotes( objectValue ) + " does not exist."
			break
			
		case 51:
			errorStr += " : table name conflict with " + NMQuotes( objectValue ) + "."
			break
			
		// notebook errors
			
		case 60:
			errorStr += " : notebook " + NMQuotes( objectValue ) + " does not exist."
			break
			
		case 61:
			errorStr += " : notebook name conflict with " + NMQuotes( objectValue ) + "."
			break
			
		case 90: // generic error
			break
			
		default:
			errorStr = "NMerror : unrecognized error number " + num2istr( errorNum )
	
	endswitch
	
	SetNMstr( NMDF + "ErrorStr", errorStr )
	SetNMvar( NMDF + "ErrorNum", errorNum )

	NMDoAlert( errorStr, title = title )
	
	return errorNum

End // NMError

//****************************************************************
//****************************************************************

Function NMExecutionAlert()

	if ( strlen( CurrentNMPrefixFolder() ) == 0 )
	
		NMDoAlert( "No waves! You may need to select " + NMQuotes( "Wave Prefix" ) + " first." )
	
		return 1
		
	endif
	
	if ( NMNumActiveWaves() <= 0 )
	
		NMDoAlert( "No waves! You may need to change the Channel or Wave Selectors." )
		
		return 1
		
	endif
	
	return 0

End // NMExecutionAlert

//****************************************************************
//****************************************************************
//
//	Deprecation Functions ( see NM_Deprecated.ipf )
//
//****************************************************************
//****************************************************************

Function NMDeprecationAlert( [ newFunction, oldFunction ] )
	String newFunction
	String oldFunction
	
	String fxnList = GetRTStackInfo( 0 )
	Variable items = ItemsInList( fxnList )
	
	if ( ParamIsDefault( newFunction ) )
		if ( items >= 2 )
			newFunction = StringFromList( items - 2, fxnList )
		else
			return -1
		endif
	endif
	
	if ( ParamIsDefault( oldFunction ) && ( Items >= 3 ) )
		if ( items >= 3 )
			oldFunction = StringFromList( items - 3, fxnList )
		else
			return -1
		endif
	endif
	
	return NMDeprecatedAlert( newFunction, oldFunction = oldFunction )
	
End // NMDeprecationAlert

//****************************************************************
//****************************************************************

Function NMDeprecatedAlert( newFunction [ oldFunction ] )
	String newFunction
	String oldFunction
	
	String alert

	if ( NMVarGet( "DeprecationAlert" ) == 0 )
		return 0
	endif
	
	if ( ParamIsDefault( oldFunction ) )
		oldFunction = GetRTStackInfo( 2 )
	endif
	
	alert = "Alert: NeuroMatic function " + NMQuotes( oldFunction ) + " has been deprecated. "
	
	if ( strlen( newFunction ) > 0 )
		alert += "Please use function " + NMQuotes( newFunction ) + " instead."
	endif
	
	NMHistory( alert )
	NMDeprecationNotebook( alert )
	
	Execute /Q/Z "SetIgorOption IndependentModuleDev = 1" // unhide procedures
	DisplayProcedure oldFunction

End // NMDeprecatedAlert

//****************************************************************
//****************************************************************

Function NMDeprecatedFatalError( newFunction [ oldFunction ] )
	String newFunction
	String oldFunction
	
	if ( ParamIsDefault( oldFunction ) )
		oldFunction = GetRTStackInfo( 2 )
	endif
	
	String alert = "Alert: NeuroMatic function " + NMQuotes( oldFunction ) + " has been deprecated. "
	
	if ( strlen( newFunction ) > 0 )
		alert += "Please use function " + NMQuotes( newFunction ) + " instead."
	endif
	
	NMHistory( alert )
	NMDeprecationNotebook( alert )
	
	Execute /Q/Z "SetIgorOption IndependentModuleDev = 1" // unhide procedures
	DisplayProcedure oldFunction
	
	DoAlert /T=( "NeuroMatic Deprecation" ) 0, alert

End // NMDeprecatedFatalError

//****************************************************************
//****************************************************************

Function NMDeprecationNotebook( alert )
	String alert
	
	String nbName = "NM_DeprecationAlerts"
	
	STRUCT Rect w

	if ( WinType( nbName ) != 5 )
	
		DoWindow /K $nbName
		
		NMWinCascadeRect( w )
		
		NewNotebook /F=0/K=1/N=$nbName/W=(w.left,w.top,w.right,w.bottom) as "NM Deprecation Alerts"
		
		NoteBook $nbName text = "To find a function, place cursor inside function name, right click and select " + NMQuotes( "Go to..." ) + NMCR
		NoteBook $nbName text = "Turn these deprecation alerts off via the DeprecationAlert flag in NeuroMatic Configurations." + NMCR + NMCR
	
	endif
	
	Notebook $nbName selection = { endOfFile, endOfFile }
	NoteBook $nbName text = alert + NMCR
	
	DoWindow /F $nbName
	
End // NMDeprecationNotebook

//****************************************************************
//****************************************************************

Function /S NMDeprecationList( [ fatal ] )
	Variable fatal // only fatal deprecated functions

	Variable fcnt
	String fatalList = "", fxn, txt
	
	String fxnList = FunctionList( "*", ";", "WIN:" + NMDeprecationIPF )
	
	if ( !fatal )
		return fxnList
	endif

	for ( fcnt = 0 ; fcnt < ItemsInList( fxnList ) ; fcnt += 1 )
		
		fxn = StringFromList( fcnt, fxnList )
		txt = ProcedureText( fxn, 0, NMDeprecationIPF )
		
		if ( strsearch( txt, "FatalError", 0 ) > 0 )
			fatalList += fxn + ";"
		endif
			
	endfor
	
	return fatalList

End // NMDeprecationList

//****************************************************************
//****************************************************************

Function NMDeprecationCheck()

	Variable fcnt, icnt, ibgn, iend
	String fxn, txt, newFxn
	
	String fxnList = FunctionList( "*", ";", "WIN:" + NMDeprecationIPF )

	for ( fcnt = 0 ; fcnt < ItemsInList( fxnList ) ; fcnt += 1 )
		
		fxn = StringFromList( fcnt, fxnList )
		txt = ProcedureText( fxn, 0, NMDeprecationIPF )
		
		if ( strsearch( txt, "NMDeprecatedFatalError(", 0 ) > 0 )
			continue
		endif
		
		icnt = strsearch( txt, "NMDeprecatedAlert(", 0 )
		
		if ( icnt > 0 )
				
			ibgn = strsearch( txt, "\"", icnt )
			iend = strsearch( txt, "\"", ibgn + 1 )
			
			newFxn = txt[ ibgn + 1, iend - 1 ]
			
			if ( strsearch( txt, newFxn + "(", iend ) == -1 )
				NMDeprecationNotebook( "Error : " + fxn + " : missing call to new function " + NMQuotes( newFxn ) )
			endif
			
		else
		
			icnt = strsearch( txt, "deprecation = 1", 0 )
			
			if ( icnt > 0 )
			
				icnt = strsearch( txt, "return ", icnt, 3 )
				
				if ( icnt > 0 )
				
					ibgn = icnt + 7
					iend = strsearch( txt, "(", ibgn )
				
					newFxn = txt[ ibgn, iend - 1 ]
				
				endif
				
			else
			
				NMDeprecationNotebook( "Error : " + fxn + " : missing call to new function" )
			
			endif
			
		endif
			
	endfor

End // NMDeprecationCheck

//****************************************************************
//****************************************************************

Structure NMDeprecationStruct

	String procedureList, fxnList, fatalList
	
EndStructure

//****************************************************************
//****************************************************************

Function NMDeprecationFindAll()

	Variable deprecations, fatal
	String txt

	STRUCT NMDeprecationStruct d
	  
	NMDeprecationFind( noHistory = 1, d = d )
	deprecations = ItemsInList( d.fxnList )
	fatal = ItemsInList( d.fatalList )
	
	if ( deprecations > 0 )
	
		txt = NMCR + "Found user-defined calls to " + num2istr( deprecations ) + " deprecated NeuroMatic function(s), "
	
		if ( fatal == 0 )
			txt += "none fatal"
		else
			txt += num2istr( fatal ) + " fatal"
		endif
		
		NMHistory( txt )
		
		d.fxnList = RemoveFromList( d.fatalList, d.fxnList )
		
		if ( ItemsInList( d.procedureList ) == 1 )
			d.procedureList = StringFromList( 0, d.procedureList )
		endif
		
		if ( ItemsInList( d.fxnList ) == 1 )
			d.fxnList = StringFromList( 0, d.fxnList )
		endif
		
		if ( ItemsInList( d.fatalList ) == 1 )
			d.fatalList = StringFromList( 0, d.fatalList )
		endif
		
		d.procedureList = ReplaceString( ";", d.procedureList, "," )
		d.fxnList = ReplaceString( ";", d.fxnList, "," )
		d.fatalList = ReplaceString( ";", d.fatalList, "," )
		
		NMHistory( "  Deprecated functions located in the following procedure files: " + d.procedureList )
		NMHistory( "  Non-Fatal Deprecated functions: " + d.fxnList )
		
		if ( fatal > 0 )
			NMHistory( "  Fatal Deprecated functions: " + d.fatalList )
		endif
		
		NMHistory( "  To find out more select: NeuroMatic > Procedures Files > Find Deprecated Functions" )
		
	endif
	
End // NMDeprecationFindAll

//****************************************************************
//****************************************************************

Function /S NMDeprecationFindCall()

	String pWindow = ""

	String windowList = WinList( "*", ";", "WIN:128" )
	String windowListNM = WinList( "NM_*", ";", "WIN:128" )
	
	windowList = RemoveFromList( windowListNM, windowList )
	windowList = RemoveFromList( "Procedure", windowList )
	windowList += "Procedure" + ";"

	Prompt pWindow, "procedure window to scan:", popup "All;" + windowList
	DoPrompt "Find Deprecated NM Functions", pWindow
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( !StringMatch( pWindow, "All" ) )
		windowList = pWindow
	endif
	
	return NMDeprecationFind( windowList = windowList )

End // NMDeprecationFindCall

//****************************************************************
//****************************************************************

Function /S NMDeprecationFind( [ windowList, NM, fatal, noHistory, d ] )
	String windowList // list of procedure files to scan
	Variable NM // scan only NM procedure files
	Variable fatal // only fatal deprecated functions
	Variable noHistory
	STRUCT NMDeprecationStruct &d
	
	Variable wcnt, fcnt, dcnt, icnt, ibgn, iend, fxnIsFatal
	String windowListNM, windowName, newFxn
	String fxnList, fxn, txt, txt2, dfxn, pstr
	String procedureList = "", foundList = "", foundFatalList = ""
	
	String dList = NMDeprecationList( fatal = fatal )
	String fatalList = NMDeprecationList( fatal = 1 )
	
	Execute /Q/Z "SetIgorOption IndependentModuleDev = 1" // unhide procedures
	
	if ( ParamIsDefault( windowList ) )
	
		if ( NM )
			windowList = WinList( "NM_*", ";", "WIN:128" )
			windowList = RemoveFromList( NMDeprecationIPF, windowList )
		else
			windowList = WinList( "*", ";", "WIN:128" )
			windowListNM = WinList( "NM_*", ";", "WIN:128" )
			windowList = RemoveFromList( windowListNM, windowList )
		endif
	
	endif
	
	for ( wcnt = 0 ; wcnt < ItemsInList( windowList ) ; wcnt += 1 )
	
		windowName = StringFromList( wcnt, windowList )
		
		fxnList = FunctionList( "*", ";", "WIN:" + windowName )
		
		for ( fcnt = 0 ; fcnt < ItemsInList( fxnList ) ; fcnt += 1 )
		
			fxn = StringFromList( fcnt, fxnList )
			txt = ProcedureText( fxn, 0, windowName )
			
			for ( dcnt = 0 ; dcnt < ItemsInList( dList ) ; dcnt += 1 )
			
				dfxn = StringFromList( dcnt, dList )
				
				icnt = zNMDeprecationFindFunction( dfxn, txt )
				
				if ( icnt == -1 )
					continue
				endif
				
				procedureList = NMAddToList( windowName, procedureList, ";" )
				
				foundList = NMAddToList( dfxn, foundList, ";" )
				
				txt2 = ProcedureText( dfxn, 0, NMDeprecationIPF )
				
				newFxn = ""
				icnt = strsearch( txt2, "NMDeprecatedAlert(", 0 )
				
				if ( icnt > 0 )
				
					ibgn = strsearch( txt2, "\"", icnt )
					iend = strsearch( txt2, "\"", ibgn + 1 )
					
					newFxn = txt2[ ibgn + 1, iend - 1 ]
					
				else
				
					icnt = strsearch( txt2, "deprecation = 1", 0 )
					
					if ( icnt > 0 )
					
						icnt = strsearch( txt2, "return ", icnt, 3 )
						
						if ( icnt > 0 )
						
							ibgn = icnt + 7
							iend = strsearch( txt2, "(", ibgn )
						
							newFxn = txt2[ ibgn, iend - 1 ]
						
						endif
					
					endif
					
				endif
				
				if ( WhichListItem( dfxn, fatalList ) >= 0 )
					pstr = "FATAL Deprecation : "
					fxnIsFatal = 1
					foundFatalList = NMAddToList( dfxn, foundFatalList, ";" )
				else
					pstr = "Deprecation : "
					fxnIsFatal = 0
				endif
				
				pstr += windowName + " : " + fxn + " : " + dfxn
				
				if ( strlen( newFxn ) > 0 )
					pstr += " ----> " + newFxn
				endif
				
				if ( !noHistory )
				
					NMDeprecationNotebook( pstr )
					
					NMHistory( pstr )

					Execute /Q/Z "SetIgorOption IndependentModuleDev = 1" // unhide procedures
					DisplayProcedure /W=$windowName fxn
				
				endif
				
			endfor
			
		endfor
		
	endfor
	
	if ( !noHistory && ( ItemsInList( foundList ) == 0 ) )
		NMHistory( "Found no deprecated NeuroMatic functions" )
	endif
	
	if ( !ParamIsDefault( d ) )
		d.procedureList = procedureList
		d.fxnList = foundList
		d.fatalList = foundFatalList
	endif
	
	return foundList
	
End // NMDeprecationFind

//****************************************************************
//****************************************************************

Static Function zNMDeprecationFindFunction( fxn, txt )
	String fxn, txt
	
	Variable icnt, jcnt, kcnt, start = 0
	String char
	
	String charList = "abcdefghijklmnopqrstuvwxyz"
	String charList2 = "1234567890_"
	
	for ( kcnt = 0 ; kcnt < 100 ; kcnt += 1 )
	
		icnt = strsearch( txt, fxn + "(", start )
					
		if ( icnt == -1 )
			return -1
		endif
		
		char = txt[ icnt - 1, icnt - 1 ] // character just before function name
		
		jcnt = strsearch( charList, char, 0, 2 )
		
		if ( jcnt >= 0 ) // this is not the function
			start = icnt + strlen( fxn )
			continue
		endif
		
		jcnt = strsearch( charList2, char, 0 )
		
		if ( jcnt >= 0 ) // this is not the function
			start = icnt + strlen( fxn )
			continue
		endif
		
		return icnt
	
	endfor
				
End // zNMDeprecationFindFunction

//****************************************************************
//****************************************************************
//
//	Functions not used anymore
//
//****************************************************************
//****************************************************************

Function NeuroMaticVar( varName ) // NOT USED
	String varName
	
	return NMVarGet( varName )
	
End // NeuroMaticVar

//****************************************************************
//****************************************************************

Function /S NeuroMaticStr( strVarName ) // NOT USED
	String strVarName
	
	return NMStrGet( strVarName )
	
End // NeuroMaticStr

//****************************************************************
//****************************************************************

Function SetNeuroMaticVar( varName, value ) // NOT USED
	String varName
	Variable value
	
	return SetNMvar( NMDF + varName, value )
	
End // SetNeuroMaticVar

//****************************************************************
//****************************************************************

Function SetNeuroMaticStr( strVarName, strValue ) // NOT USED
	String strVarName
	String strValue
	
	return SetNMstr( NMDF + strVarName, strValue )
	
End // SetNeuroMaticStr

//****************************************************************
//****************************************************************

Function NMHistoryCall() // NOT USED
	
	Variable writeHistory = NMVarGet( "WriteHistory" ) + 1
	
	Prompt writeHistory, "print function results to:", popup "nowhere;Igor history;Igor notebook;both;"
	DoPrompt "NeuroMatic Results History", writeHistory
	
	if ( V_flag == 1 )
		return 0 // cancel
	endif
	
	writeHistory -= 1
	
	NMCmdHistory( "NMHistorySelect", NMCmdNum( writeHistory, "", integer = 1 ) )
	
	return NMHistorySelect( writeHistory )

End // NMHistoryCall

//****************************************************************
//****************************************************************

Function NMHistorySelect( writeHistory ) // NOT USED
	Variable writeHistory
	
	SetNMvar( NMDF + "WriteHistory", writeHistory )
	
	return writeHistory
	
End // NMHistorySelect

//****************************************************************
//****************************************************************

Function NMCmdHistoryCall() // NOT USED
	
	Variable cmdhistory = NMVarGet( "CmdHistory" ) + 1
	
	Prompt cmdhistory "print function commands to:", popup "nowhere;Igor history;Igor notebook;both;"
	DoPrompt "NeuroMatic Commands History", cmdhistory
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	cmdhistory -= 1
	
	NMCmdHistory( "NMCmdHistorySelect", NMCmdNum( cmdhistory, "", integer = 1 ) )
	
	return NMCmdHistorySelect( cmdhistory )

End // NMCmdHistoryCall

//****************************************************************
//****************************************************************

Function NMCmdHistorySelect( cmdhistory ) // NOT USED
	Variable cmdhistory
	
	SetNMvar( NMDF + "CmdHistory", cmdhistory )
	
	return cmdhistory
	
End // NMCmdHistorySelect

//****************************************************************
//****************************************************************

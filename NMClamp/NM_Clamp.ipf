#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma hide = 1

//****************************************************************
//****************************************************************
//
//	NeuroMatic: data aquisition, analyses and simulation software that runs with the Igor Pro environment
//	Copyright (C) 2024 The Silver Lab, UCL
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
//	NeuroMatic Clamp tab for data acquisition
//
//	Created in the Laboratory of Dr. Angus Silver
//	NPP Department, UCL, London
//
//	This work was supported by the Medical Research Council
//	"Grid Enabled Modeling Tools and Databases for NeuroInformatics"
//
//	Began 1 July 2003
//
//****************************************************************
//****************************************************************

//StrConstant NMClampDF = "root:Packages:NeuroMatic:Clamp:"
Static StrConstant DateFormat = "DDMMMYYYY" // e.g. MMM = "Jan" and MM = "01"
Static StrConstant DateFormatList = "DDMMMYYYY;DD_MM_YYYY;DDMMYYYY;YYYYMMMDD;YYYY_MM_DD;YYYYMMDD;"

//****************************************************************
//****************************************************************

Menu "NeuroMatic"

	Submenu StrVarOrDefault( NMDF + "NMMenuShortcuts" , "\\M1(Keyboard Shortcuts" )
		StrVarOrDefault( NMDF + "NMMenuShortcutClamp0" , "" )
		StrVarOrDefault( NMDF + "NMMenuShortcutClamp1" , "" ), /Q, ClampButton( "CT0_StartPreview" )
		StrVarOrDefault( NMDF + "NMMenuShortcutClamp2" , "" ), /Q, ClampButton( "CT0_StartRecord" )
		StrVarOrDefault( NMDF + "NMMenuShortcutClamp3" , "" ), /Q, ClampButton( "CT0_Note" )
		StrVarOrDefault( NMDF + "NMMenuShortcutClamp4" , "" ), /Q, ClampAutoScale()
	End
	
End // NeuroMatic menu

//****************************************************************
//****************************************************************

Function NMMenuBuildClamp()

	if ( NMVarGet( "NMOn" ) && StringMatch( CurrentNMTabName(), "Clamp" ) )
		SetNMstr( NMDF + "NMMenuShortcutClamp0", "-" )
		SetNMstr( NMDF + "NMMenuShortcutClamp1", "Preview/4" )
		SetNMstr( NMDF + "NMMenuShortcutClamp2", "Record/5" )
		SetNMstr( NMDF + "NMMenuShortcutClamp3", "Add Note/6" )
		SetNMstr( NMDF + "NMMenuShortcutClamp4", "Auto Scale/7" )
	else
		SetNMstr( NMDF + "NMMenuShortcutClamp0", "" )
		SetNMstr( NMDF + "NMMenuShortcutClamp1", "" )
		SetNMstr( NMDF + "NMMenuShortcutClamp2", "" )
		SetNMstr( NMDF + "NMMenuShortcutClamp3", "" )
		SetNMstr( NMDF + "NMMenuShortcutClamp4", "" )
	endif

End // NMMenuBuildClamp

//****************************************************************
//****************************************************************

//Menu "NeuroMatic", dynamic

	//Submenu NMMainMenuOnStr( "Clamp" ) + "Hot Keys"
		//"-"
		//"Preview/4", ClampButton( "CT0_StartPreview" )
		//"Record/5", ClampButton( "CT0_StartRecord" )
		//"Add Note/6", ClampButton( "CT0_Note" )
		//"Auto Scale/7", ClampAutoScale()
	//End

//End // NeuroMatic menu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMTabPrefix_Clamp()

	return "CT0_"

End // NMTabPrefix_Clamp

//****************************************************************
//****************************************************************
//****************************************************************

Function NMClampTab( enable )
	Variable enable // ( 0 ) disable ( 1 ) enable
	
	Variable clampExists = DataFolderExists( NMStimsDF )

	if ( enable == 1 )

		CheckNMPackage( "Stats", 1 ) // necessary for auto-stats
		CheckNMPackage( "Spike", 1 ) // necessary for auto-spike
		CheckNMPackage( "Clamp", 1 ) // create clamp global variables
		CheckNMPackageNotes()
		
		//LogParentCheck()
		CheckNMStimsDF()
		
		ClampConfigsUpdate() // set data paths, open stim files, test board config
		
		NMChannelGraphDisable( channel = -2, all = 0 )
		
		ClampStats( NMStimStatsOn() )
		ClampSpike( NMStimSpikeOn() )

		ClampAutoBackupNM_Start()
		
		NMGroupsSet( on = 1 )
		
		if ( !clampExists )
			NMNotesClearFileVars() // clear file note vars at start
		endif
		
	else
	
		ClampStats( 0 )
		ClampSpike( 0 )
		
	endif
	
	NMClampTabEnable( enable ) // NM_ClampTab.ipf
	
	NMStimCurrentChanSet( "", CurrentNMChannel() ) // update current channel

End // NMClampTab

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMPackageNotes()

	String df, oldDF, newDF
	String newName = "ClampNotes"
	
	df = "root:Packages:NeuroMatic:"
	oldDF = df + "Notes:"
	newDF = df + newName + ":"
	
	if ( DataFolderExists( oldDF ) && !DataFolderExists( newDF ) )
		RenameDataFolder $oldDF, $newName
	endif
	
	df = "root:Packages:NeuroMatic:Configurations:"
	oldDF = df + "Notes:"
	newDF = df + newName + ":"
	
	if ( DataFolderExists( oldDf ) && !DataFolderExists( newDF ) )
		RenameDataFolder $oldDf, $newName
	endif
	
	CheckNMPackage( newName, 1 )

End // CheckNMPackageNotes

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampTabKill( what )
	String what // to kill

	strswitch( what )
		case "waves":
			break
		case "globals":
			if ( DataFolderExists( NMClampDF ) == 1 )
				KillDataFolder $NMClampDF
			endif 
			break
	endswitch

End // KillClampTabKill

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampExitHook()

	// nothing to do

End // ClampExitHook

//****************************************************************
//****************************************************************
//****************************************************************

Function NMClampCheck()
	
	Variable saveformat = 2 // Igor binary
	
	String cdf = NMClampDF

	if ( DataFolderExists( cdf ) == 0 )
		return -1
	endif
	
	CheckNMstr( cdf+"ClampErrorStr", "" )				// error message
	CheckNMvar( cdf+"ClampError", 0 )					// error number ( 0 ) no error ( -1 ) error
	
	CheckNMvar( cdf+"DemoMode", 1 )					// demo mode ( 0 ) off ( 1 ) on
	
	CheckNMvar( cdf+"BoardDriver", 0 )					// main board driver number
	
	CheckNMvar( cdf+"LogDisplay", 1 )					// log notes display flag
	CheckNMvar( cdf+"LogAutoSave", 1 )				// auto save log notes flag
	
	//CheckNMstr( cdf+"TGainList", "" )					// telegraph gain ADC channel list // DEPRECATED
	//CheckNMstr( cdf+"ClampInstrument", "" )			// clamp instrument name // DEPRECATED
	
	// data folder variables
	
	CheckNMstr( cdf+"CurrentFolder", "" )				// current data file
	
	CheckNMstr( cdf+"FolderPrefix", ClampDateName() )	// data folder/file prefix name
	CheckNMstr( cdf+"FolderNameDateFormat", DateFormat ) // data folder/file name data format ( see above )
	
	CheckNMstr( cdf+"ClampPath", "" )					// external save data path
	CheckNMstr( cdf+"DataPrefix", NMStrGet( "WavePrefix" ) )	// default data prefix name
	CheckNMstr( cdf+"WavePrecision", "D" )			// wave precision ( "D" ) double ( "S" ) single
	
	CheckNMvar( cdf+"DataFileCell", 0 )				// data file cell number
	CheckNMvar( cdf+"DataFileSeq", 0 )				// data file sequence number
	CheckNMvar( cdf+"SeqAutoZero", 1 )				// auto zero seq number after cell increment
	
	CheckNMvar( cdf+"AcquisitionBeep", 0 )				// beep at the start of acquisition ( 0 ) no ( 1 ) yes
	
	CheckNMvar( cdf+"Backup", 20 )					// time to backup ( save ) current Igor experiment ( minutes ). Enter 0 for no backup.
	CheckNMvar( cdf+"SaveWhen", 1 )					// ( 0 ) never ( 1 ) after recording ( 2 ) while recording
	//CheckNMvar( cdf+"SaveFormat", saveformat )	// ( 1 ) NM binary ( 2 ) Igor binary ( 3 ) NM and Igor Binary ( 4 ) HDF5 // DEPRECATED
	CheckNMstr( cdf+"SaveFileFormat", "Igor Binary" )		// "Igor binary" or "HDF5"
	CheckNMvar( cdf+"SaveWithDialogue", 0 )			// ( 0 ) no dialogue ( 1 ) save with dialogue
	CheckNMvar( cdf+"SaveInSubfolder", 1 )			// save data in subfolders ( 0 ) no ( 1 ) yes
	CheckNMvar( cdf+"AutoCloseFolder", 1 )			// auto delete data folder flag ( 0 ) no ( 1 ) yes
	CheckNMvar( cdf+"CopyStim2Folder", 1 )			// copy stim to data folder flag ( 0 ) no ( 1 ) yes
	CheckNMvar( cdf+"SaveDACwaves", 1 )				// copy stim DAC waves to data folder flag ( 0 ) no ( 1 ) yes
	CheckNMvar( cdf+"SaveTTLwaves", 1 )				// copy stim TTL waves to data folder flag ( 0 ) no ( 1 ) yes
	
	CheckNMvar( cdf+"MultiClamp700Save", 0 )		// save MultiClamp 700 Commander variables ( 0 ) no ( 1 ) yes
	
	// stim protocol variables
	
	CheckNMstr( cdf+"StimPath", "" )					// external save stim path
	CheckNMstr( cdf+"OpenStimList", "All" )			// external stim files to open
	CheckNMstr( cdf+"CurrentStim", "" ) 				// current stimulus protocol
	CheckNMvar( cdf+"ZeroDACLastPoints", 1 )			// zero last points in DAC waves ( 0 ) no ( 1 ) yes
	CheckNMvar( cdf+"ForceEvenPoints", 0 )			// force even number of sample points ( 0 ) no ( 1 ) yes
	
	CheckNMvar( cdf+"PulsePromptBinomial", 0 )
	CheckNMvar( cdf+"PulsePromptSTDV", 0 )
	CheckNMvar( cdf+"PulsePromptCV", 0 )
	CheckNMvar( cdf+"PulsePromptDelta", 1 )
	CheckNMvar( cdf+"PulsePromptPlasticity", 0 )
	
	ClampBoardWavesCheckAll()						// board configuration waves
	
	return 0
	
End // NMClampCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function NMClampConfigEdit() // called from NM_Configurations

	//NMConfigEdit( "ClampNotes" )

End // NMClampConfigEdit

//****************************************************************
//****************************************************************
//****************************************************************

Function NMClampConfigs()

	String fname = "Clamp"
	
	NMConfigVar( fname, "BoardDriver", 0, "NIDAQ board driver number", "" )
	NMConfigStr( fname, "DataPrefix", NMStrGet( "WavePrefix" ), "data wave prefix name", "" )
	NMConfigStr( fname, "WavePrecision", "D", "data wave Precision ( D ) double ( S ) single", "D;S;" )
	
	NMConfigStr( fname, "ClampPath", "C:Jason:TestData:", "directory where data is to be saved", "DIR" )
	NMConfigStr( fname, "FolderNameDateFormat", DateFormat, "date format for creating data folder/file names", DateFormatList )
	
	NMConfigStr( fname, "StimPath", "C:Jason:TestStims:", "directory where stim protocols are saved", "DIR" )
	NMConfigStr( fname, "OpenStimList", "All", "list of stim files to open within StimPath ( \"All\" ) for all stim files", "" )
	
	NMConfigVar( fname, "SeqAutoZero", 1, "auto zero seq num after cell increment", "boolean" )
	NMConfigVar( fname, "AcquisitionBeep", 0, "beep at the start of acquisition", "boolean" )
	
	NMConfigVar( fname, "Backup", 30, "backup ( save ) time for current Igor experiment ( minutes ). Enter 0 for no backup.", "min" )
	//NMConfigVar( fname, "SaveFormat", 2, "save data format ( 1 ) NM binary file ( 2 ) Igor binary file ( 3 ) NM and Igor Binary ( 4 ) HDF5", " ;NM binary;Igor binary;NM and Igor binary;HDF5;" ) // DEPRECATED
	NMConfigStr( fname, "SaveFileFormat", "Igor Binary", "Igor Binary or HDF5", "Igor Binary;HDF5;" )
	NMConfigVar( fname, "SaveWhen", 1, "save data when ( 0 ) never ( 1 ) after recording ( 2 ) while recording", "never;after recording all episodes;after recording each episode;" )
	NMConfigVar( fname, "SaveWithDialogue", 0, "save with dialogue prompt", "boolean" )
	NMConfigVar( fname, "SaveInSubfolder", 1, "save data in subfolders", "boolean" )
	NMConfigVar( fname, "SaveDACwaves", 1, "save stim DAC waves", "boolean" )
	NMConfigVar( fname, "SaveTTLwaves", 1, "save stim TTL waves", "boolean" )
	NMConfigVar( fname, "AutoCloseFolder", 1, "close previous data folder before creating new one", "boolean" )
	
	NMConfigVar( fname, "LogDisplay", 1, "clamp log display ( 0 ) none ( 1 ) notebook ( 2 ) table", "none;notebook;table;" )
	NMConfigVar( fname, "LogAutoSave", 1, "log folder auto save", "boolean" )
	
	NMConfigVar( fname, "MultiClamp700Save", 0, "save MultiClamp 700 Commander variables", "boolean" )
	
	NMConfigVar( fname, "ZeroDACLastPoints", 1, "zero last points in DAC waves", "boolean" )
	NMConfigVar( fname, "ForceEvenPoints", 0, "force even number of sample points", "boolean" )
	
	NMConfigVar( fname, "PulsePromptBinomial", 0, "prompt for binomial pulses", "boolean" )
	NMConfigVar( fname, "PulsePromptPlasticity", 0, "prompt for plasticity of pulse trains", "boolean" )
	NMConfigStr( fname, "PulsePromptTypeDSC", "delta", "prompt for \"delta\" or \"stdv\" or \"cv\" of pulse parameters", "delta;stdv;cv;" )
	
	NMConfigVar( fname, "TModeChan", Nan, "ADC input channel for telegraph mode", "" )
	
	NMConfigVar( fname, "TempChan", Nan, "ADC input channel for temperature", "" )
	NMConfigVar( fname, "TempSlope", 1, "temperature slope factor ( 100 degreesC / Volts )", "" )
	NMConfigVar( fname, "TempOffset", 0, "temperature offset ( degreesC )", "" )
	
	ClampBoardConfigs()
	
	CheckNMConfig( "ClampNotes" )

End // NMClampConfigs

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampConfigsUpdate()

	Variable test
	String cdf = NMClampDF
	
	String saveFileFormat = StrVarOrDefault(cdf+"SaveFileFormat", "Igor Binary")
	
	if ( StringMatch( saveFileFormat, "HDF5" ) && !NMHDF5OK() )
		NMHDF5Allert()
		NMConfigStrSet( "Clamp", "SaveFileFormat", "Igor Binary" )
	endif
	
	if ( NumVarOrDefault( cdf+"ClampSetPreferences", 0 ) == 1 )
		return 0 // already set
	endif

	String ClampPathStr = StrVarOrDefault( cdf+"ClampPath", "" )
	String StimPathStr = StrVarOrDefault( cdf+"StimPath", "" )
	String sList = StrVarOrDefault( cdf+"OpenStimList", "All" )
	
	ClampPathsCheck()
	
	if ( ( strlen( StimPathStr ) > 0 ) && ( strlen( sList ) > 0 ) )
	
		if ( StringMatch( sList, "All" ) == 1 )
			NMStimOpenAll( StimPathStr, 0 )
		else
			NMStimOpenList( StimPathStr, sList )
		endif
		
	endif
	
	ClampConfigBoard()
	
	test = ClampAcquireManager( StrVarOrDefault( cdf+"AcqBoard","Demo" ), -2, 0 ) // test configuration
	
	if ( test < 0 )
		SetNMstr( cdf+"AcqBoard","Demo" )
	endif
	
	ClampProgressInit() // make sure progress display is OK
	
	SetNMvar( cdf+"ClampSetPreferences", 1 )
	
	NMMultiClampTelegraphSaveCheck()
	
	ClampDataFolderName( 0 )
	
	SetIgorHook IgorQuitHook = ClampExitHook // runs this fxn before quitting Igor
	
End // ClampConfigsUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampConfigBoard()

	Variable demoMode = 1

	String blist = "", board = "Demo", cdf = NMClampDF
	
	Variable driver = NumVarOrDefault( cdf+"BoardDriver", 0 )
	
	if ( exists( "NidaqBoardList" ) == 6 )
	
		Execute /Z "NidaqBoardList()"
	
		if ( V_flag == 0 )
		
			blist = StrVarOrDefault( cdf+"BoardList", "" )
			
			if ( ItemsInList( blist ) > 0 )
				demoMode = 0
				board = "NIDAQ"
				driver = ClampBoardDriverPrompt()
				Print "NeuroMatic configured for NIDAQ acquisition"
			endif
			
		endif
		
	endif
	
	if ( ( strlen( blist ) == 0 ) && ( exists( "ITC16stopacq" ) == 4 ) )
	
		Execute /Z "ITC16stopacq"
		
		if ( V_flag == 0 )
			demoMode = 0
			blist = "ITC16"
			board = "ITC16"
			driver = 0
			Print "NeuroMatic configured for ITC16 acquisition"
		endif
		
	endif
	
	if ( ( strlen( blist ) == 0 ) && ( exists( "ITC18stopacq" ) == 4 ) )
		
		Execute /Z "ITC18stopacq"

		if ( V_flag == 0 )
			demoMode = 0
			blist = "ITC18"
			board = "ITC18"
			driver = 0
			Print "NeuroMatic configured for ITC18 acquisition"
		endif
	
	endif
	
	if ( ( strlen( blist ) == 0 ) && ( exists( "NM_LIH_InitInterfaceName" ) == 6 ) )
		
		Execute /Z "NM_LIH_InitInterfaceName()"
		
		if ( V_flag == 0 )
		
			blist = StrVarOrDefault( cdf+"BoardList", "" )
			
			if ( ItemsInList( blist ) > 0 )
				demoMode = 0
				board = blist
				driver = 0
				Print "NeuroMatic configured for " + board + " acquisition"
			endif
			
		endif
	
	endif
	
	if ( ( strlen( blist ) == 0 ) && ( exists( "NMAlembicBoardList" ) == 6 ) )
	
		Execute /Z "NMAlembicBoardList()"
		
		if ( V_flag == 0 )
		
			blist = StrVarOrDefault( cdf+"BoardList", "" )
		
			if ( ItemsInList( blist ) > 0 )
				demoMode = 0
				board = "Alembic"
				driver = 0
				Print "NeuroMatic configured for Alembic acquisition"
			endif
			
		endif
	
	endif
	
	if ( ( strlen( blist ) == 0 ) && ( exists( "NMClampDemoBoardList" ) == 6 ) )
	
		Execute /Z "NMClampDemoBoardList()"
		
		if ( V_flag == 0 )
		
			blist = StrVarOrDefault( cdf+"BoardList", "" )
			
			if ( ItemsInList( blist ) > 0 )
				demoMode = 1
				board = "Demo"
				driver = 0
				Print "NeuroMatic configured for Demo acquisition"
			endif
			
		endif
	
	endif
	
	if ( strlen( blist ) == 0 )
		demoMode = 1
		blist = "Demo"
		board = "Demo"
		driver = 0
	endif
	
	if ( demoMode )
		DoAlert 0, "Detected no acquisition boards. NeuroMatic Clamp tab has been set to Demo Mode." 
	endif
		
	SetNMstr( cdf+"BoardList", blist )
	SetNMstr( cdf+"AcqBoard", board )
	SetNMstr( cdf+"BoardSelect", board )
	SetNMvar( cdf+"BoardDriver", driver )
	SetNMvar( cdf+"DemoMode", demoMode )
	
	return blist

End // ClampConfigBoard

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampPathsCheck()

	String cdf = NMClampDF
	String ClampPathStr = StrVarOrDefault( cdf+"ClampPath", "" )
	String StimPathStr = StrVarOrDefault( cdf+"StimPath", "" )
	
	PathInfo /S ClampSaveDataPath
	
	if ( ( strlen( S_path ) == 0 ) && ( strlen( ClampPathStr ) > 0 ) )
	
		NewPath /Z/O/Q ClampSaveDataPath ClampPathStr
		
		if ( V_flag != 0 )
			NMDoAlert( "Failed to create external path to: " + ClampPathStr )
			SetNMstr( cdf+"ClampPath", "" )
		endif
		
	endif
	
	PathInfo ClampStimPath
	
	if ( ( strlen( S_path ) == 0 ) && ( strlen( StimPathStr ) > 0 ) )
	
		NewPath /Z/O/Q ClampStimPath StimPathStr
		
		if ( V_flag != 0 )
			NMDoAlert( "Failed to create external path to: " + StimPathStr )
			SetNMstr( cdf+"StimPath", "" )
		endif
		
	endif

End // ClampPathsCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampPathSet( pathStr )
	String pathStr
	
	String message = "Please specifiy directory where Clamp acquisition data files are to be saved."

	if ( strlen( pathStr ) == 0 )
		pathStr = StrVarOrDefault( NMClampDF + "ClampPath", "" )
	endif
	
	pathStr = NMGetExternalFolderPath( message, pathStr )
	
	if ( strlen( pathStr ) == 0 )
		return ""
	endif
	
	NewPath /Q/O/M=(message) ClampSaveDataPath pathStr
	
	if ( V_flag == 0 )
		PathInfo ClampSaveDataPath
		pathStr = S_path
		NMConfigStrSet( "Clamp", NMClampDF + "ClampPath", S_path )
		SetNMstr( NMClampDF + "ClampPath", S_path )
	else
		//ClampError( 1, "Failed to create external path to: " + pathStr )
		pathStr = ""
	endif
	
	return pathStr
	
End // ClampPathSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampDateName( [ promptFormat ] )
	Variable promptFormat

	Variable month, useMonthName = 0
	String findSepStr, sepStr = ""
	
	String format = StrVarOrDefault( NMClampDF + "FolderNameDateFormat", DateFormat )
	
	if ( promptFormat )
	
		Prompt format, "choose date format:", popup DateFormatList
		DoPrompt "NM Clamp Data Folder Name Prefix", format
		
		if ( V_flag == 1 )
			//return "" // cancel not allowed here
		endif
		
		SetNMstr( NMClampDF + "FolderNameDateFormat", format )
	
	endif

	String dateList = Secs2Date( DateTime, -2 , ";" )
	
	String yearStr = StringFromList( 0, dateList ) // YYYY
	String monthStr = StringFromList( 1, dateList ) // MM
	String dayStr = StringFromList( 2, dateList ) // DD
	
	if ( strsearch( format, "MMM", 0 ) > 0 )
		useMonthName = 1
	endif
	
	findSepStr = ReplaceString( "Y", format, "" )
	findSepStr = ReplaceString( "M", findSepStr, "" )
	findSepStr = ReplaceString( "D", findSepStr, "" )
	
	if ( strlen( findSepStr ) > 0 )
		sepStr = findSepStr[ 0, 0 ]
	endif
	
	if ( useMonthName )
	
		month = str2num( monthStr )
	
		switch( month )
			case 1:
				monthStr = "Jan"
				break
			case 2:
				monthStr = "Feb"
				break
			case 3:
				monthStr = "Mar"
				break
			case 4:
				monthStr = "Apr"
				break
			case 5:
				monthStr = "May"
				break
			case 6:
				monthStr = "Jun"
				break
			case 7:
				monthStr = "Jul"
				break
			case 8:
				monthStr = "Aug"
				break
			case 9:
				monthStr = "Sep"
				break
			case 10:
				monthStr = "Oct"
				break
			case 11:
				monthStr = "Nov"
				break
			case 12:
				monthStr = "Dec"
				break
			default:
				return ""
		endswitch
		
	endif
	
	strswitch( sepStr )
		case ".":
		case "-":
			sepStr = "_"
			break
	endswitch
	
	if ( strlen( sepStr ) > 1 )
		sepStr = sepStr[ 0, 0 ]
	endif
	
	if ( StringMatch( format[ 0, 1], "DD" ) )
		return "nm" + dayStr + sepStr + monthStr + sepStr + yearStr
	else
		return "nm" + yearStr + sepStr + monthStr + sepStr + dayStr
	endif

End // ClampDateName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampFolderPrefix()

	CheckFileNamePrefix()

	return StrVarOrDefault( NMClampDF+"FolderPrefix", ClampDateName() )

End // ClampFolderPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckFileNamePrefix()

	String cdf = NMClampDF
	
	String userPrefix = StrVarOrDefault( cdf + "UserFolderPrefix", "" )
	String prefix = StrVarOrDefault( cdf + "FolderPrefix", "" )
	String datePrefix = ClampDateName()

	if ( (strlen( userPrefix ) == 0 ) && ( StringMatch( prefix, datePrefix ) == 0 ) )
		prefix = datePrefix // update auto prefix name
		SetNMstr(cdf+"FolderPrefix", prefix)
	endif

End // CheckFileNamePrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampFileNamePrefixSet( prefix )
	String prefix
	
	if ( strlen( prefix ) == 0 )
		prefix = ClampDateName( promptFormat = 1 )
	endif
	
	prefix = NMCheckStringName( prefix )
	
	SetNMstr( NMClampDF+"FolderPrefix", prefix )
	SetNMstr( NMClampDF+"UserFolderPrefix", prefix )
	
	return prefix
	
End // ClampFileNamePrefixSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampErrorCheck( mssg )
	String mssg
	
	String rte = GetRTErrMessage()

	if ( GetRTError( 1 ) == 0 )
		return 0
	endif
	
	Print ""
	ClampError( 0, mssg )
	
	if ( strlen( rte ) > 0 )
		Print "Igor Runtime Error:" + rte
	endif
	
	Print ""
	
	return -1
	
End // ClampErrorCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampError( alert, errorStr )
	Variable alert // ( 0 ) no ( 1 ) yes
	String errorStr
	
	String cdf = NMClampDF
	
	String functionName = GetRTStackInfo( 2 )
	
	if ( strlen( errorStr ) == 0 )
	
		SetNMstr( cdf+"ClampErrorStr", "" )
		SetNMvar( cdf+"ClampError", 0 )
		
	else
	
		SetNMstr( cdf+"ClampErrorStr", errorStr )
		SetNMvar( cdf+"ClampError", -1 )
		
		if ( alert == 1 )
			DoAlert 0, "Clamp Error: " + functionName + " : " + errorStr
		else
			Print "Clamp Error: " + functionName + " : " + errorStr
		endif
		
		ClampButtonDisable( -1 )
		
	endif
	
	return -1
	
End // ClampError

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampProgressInit() // use ProgWin XOP display to allow cancel of acquisition

	Variable pflag = NMVarGet( "ProgFlag" )
	
	//String txt = "Alert: Clamp Tab requires ProgWin XOP to cancel acquisition."
	//txt += "Download from ftp site www.wavemetrics.com/Support/ftpinfo.html ( IgorPro/User_Contributions/ )."
	
	if ( pflag != 1 )
	
		//Execute /Z "ProgressWindow kill" // try to use ProgWin function
	
		//if ( V_flag == 0 )
		//	SetNMvar( NMDF+"ProgFlag", 1 )
		//else
		//	NMDoAlert( txt )
		//endif
		
		pflag = 1
		
		SetNMvar( NMDF+"ProgFlag", 1 )
	
	endif
	
	if ( ( pflag == 1 ) && ( ( NMProgressX() < 0 ) || ( NMProgressY() < 0 ) ) )
		SetNMvar( NMDF+"xProgress", ( NMScreenPixelsX() - NMProgWinWidth ) * 0.5 )
		SetNMvar( NMDF+"yProgress", NMScreenPixelsY(igorFrame=1) * 0.7 )
	endif

End // ClampProgress

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampDemoModeSet( on )
	Variable on // ( 0 ) off ( 1 ) on
	
	Variable icnt
	String board = "", btemp, cdf = NMClampDF
	
	String boardList = StrVarOrDefault( cdf+"BoardList", "" )
	
	if ( on == 0 )
	
		for ( icnt = 0 ; icnt < ItemsInList( boardList ) ; icnt += 1 )
		
			btemp = StringFromList( icnt, boardList )
		
			if ( StringMatch( btemp, "Demo" ) || StringMatch( btemp, "None" ) )
				continue
			endif
			
			board = btemp
			
			break
		
		endfor
	
		if ( strlen( board ) == 0 )
		
			NMDoAlert( "NeuroMatic must remain in Demo Mode since no acquisition boards have been detected." )
	
			on = 1
			
		endif
	
	else
	
		on = 1
	
	endif
	
	SetNMvar( cdf+"DemoMode", on )
	
	return on

End // ClampDemoModeSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampFolderAutoCloseSet( on [ userPrompt ] )
	Variable on // ( 0 ) off ( 1 ) on
	Variable userPrompt // ( 0 ) no ( 1 ) yes
	
	if ( userPrompt )
	
		on = 1 + NumVarOrDefault( NMClampDF+"AutoCloseFolder", 1 )
		
		Prompt on, "automatically close current NM data folder before creating a new one?", popup "no;yes (recommended);"
		DoPrompt "Configuration for Local Memory Conservation", on
		
		if ( V_flag == 1 )
			return on // cancel
		endif
		
		on -= 1
	
	endif
	
	SetNMvar( NMClampDF+"AutoCloseFolder", on )
	
	return on
	
End // ClampFolderAutoCloseSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampLogAutoSaveSet( on )
	Variable on // ( 0 ) off ( 1 ) on
	
	SetNMvar( NMClampDF+"LogAutoSave", on )

End // ClampLogAutoSaveSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampLogDisplaySet( selectStr )
	String selectStr // "None", "Both", "Text" or "Table"
	
	Variable nb, table, select
	
	String cdf = NMClampDF, ldf = LogDF()
	
	String nbName = LogNoteBookName( ldf )
	String tName = LogTableName( ldf )
	
	strswitch( selectStr )
	
		case "None":
			break
			
		case "Text":
			nb = 1
			select = 1
			break
		
		case "Table":
			table = 1
			select = 2
			break
			
		case "Both":
			nb = 1
			table = 1
			select = 3
			break
			
		default:
			return -1
			
	endswitch
	
	SetNMvar( cdf+"LogDisplay", select )
	
	if ( nb == 0 )
		DoWindow /K $nbName
	elseif ( WinType( nbName ) == 5 )
		DoWindow /F $nbName
	else
		LogNoteBook( ldf )
	endif
	
	if ( table == 0 )
		DoWindow /K $tName
	elseif ( WinType( tName ) == 2 )
		DoWindow /F $tName
	else
		LogTable( ldf )
	endif
	
	return select
	
End // ClampLogDisplaySet

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStimPathAsk()

	String cdf = NMClampDF
	
	String pathStr = StrVarOrDefault( cdf + "StimPath", "" )
	
	pathStr = NMGetExternalFolderPath( "Select Stim File Directory", pathStr )
	
	if ( strlen( pathStr ) == 0 )
		return -1
	endif
	
	NewPath /Q/O/M="Select Stim File Directory" ClampStimPath, pathStr
	
	if ( V_flag == 0 )
	
		PathInfo ClampStimPath
		
		if ( strlen( S_path ) > 0 )
			SetNMstr( cdf + "StimPath", S_path )
			NMDoAlert( "Don't forget to save changes by saving your Configs ( NeuroMatic > Configs > Save )." )
		endif
		
		return 0
		
	endif
	
	return -1

End // ClampStimPathSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStimListAsk()

	String cdf = NMClampDF
	String openList = StrVarOrDefault( cdf+"OpenStimList", "All" )
	
	//if ( strlen( openList ) == 0 )
		openList = StimList()
	//endif
	
	Prompt openList, "list of stim files to open when starting Clamp tab, or \"All\":"
	DoPrompt "Set Stim List", openList
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	SetNMstr( cdf+"OpenStimList", openList )
	
	NMDoAlert( "Don't forget to save changes by saving your Configurations ( NeuroMatic > Configs > Save )." )

End // ClampStimListSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampSaveAsk()

	String cdf = NMClampDF
	
	String txt1 = "Warning: depending on the speed of your computer, Save While Recording option may slow acquisition. Please use long stimulus interludes to allow time for saving each episodic recording."
	String txt2 = "Save While Recording: data will be saved as a NM binary file during acquisition and also an Igor or HDF5 binary file after acquisition is finished."
	
	Variable saveWhen = NumVarOrDefault( cdf+"SaveWhen", 1 ) + 1
	Variable savePrompt = NumVarOrDefault( cdf+"SaveWithDialogue", 1 ) + 1
	String saveFileFormat = StrVarOrDefault( cdf+"SaveFileFormat", "Igor Binary" )
	
	strswitch( saveFileFormat )
		case "HDF5":
			if ( !NMHDF5OK() )
				saveFileFormat = "Igor Binary"
			endif
			break
		default:
			saveFileFormat = "Igor Binary"
	endswitch
	
	Prompt saveWhen, "save data to disk when?", popup "never (not recommended);after recording all stimulus episodes (recommended);after recording each stimulus episode (requires longer interludes);"
	Prompt savePrompt, "save with dialogue prompt?", popup "no (recommended);yes;"
	Prompt saveFileFormat, "binary file format:", popup "Igor Binary;HDF5;"
	
	DoPrompt "Save NM Data Folder To Disk", saveWhen, savePrompt, saveFileFormat
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	if ( saveWhen == 3 ) // save while recording
		NMDoAlert( txt1 )
		NMDoAlert( txt2 )
		Print txt1
		Print txt2
	endif
	
	if ( StringMatch( saveFileFormat, "HDF5" ) && !NMHDF5OK() )
		NMHDF5Allert()
		saveFileFormat = "Igor Binary"
	endif
	
	SetNMvar( cdf+"SaveWhen", saveWhen - 1 )
	SetNMvar( cdf+"SaveWithDialogue", savePrompt - 1 )
	SetNMstr( cdf+"SaveFileFormat", saveFileFormat )

End // ClampSaveAsk

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAutoBackupNM_Start()

	String cdf = NMClampDF
	Variable backup = NumVarOrDefault( cdf+"BackUp", 20 ) // minutes
	
	if ( ( DataFolderExists( cdf ) == 0 ) || ( backup <= 0 ) || ( numtype( backup ) > 0 ) )
		return -1
	endif
	
	BackgroundInfo
	
	if ( V_flag > 0 )
		if ( StringMatch( S_value, "ClampAutoBackupNM()" ) == 1 )
			return 0 // already started
		else
			KillBackground
		endif
	endif

	SetBackground ClampAutoBackupNM()
	CtrlBackground period=( 60 * 60 * 10 ), start=( 60 * 5 )
	
	return 0

End // ClampAutoBackupNM_Start

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAutoBackupNM()
	
	String fname, cdf = NMClampDF
	Variable minutes = DateTime / 60
	Variable backup = NumVarOrDefault( cdf+"BackUp", 20 ) // minutes
	Variable lastbackup = NumVarOrDefault( cdf+"LastBackUp", Nan ) // minutes
	String path = StrVarOrDefault( cdf+"ClampPath", "" )
	String folderPrefix = ClampFolderPrefix()
	
	if ( ( DataFolderExists( cdf ) == 0 ) || ( backup <= 0 ) || ( numtype( backup ) > 0 ) )
		return 1
	endif
	
	ClampPathsCheck()
	
	PathInfo ClampSaveDataPath
	
	if ( ( strlen( S_path ) == 0 ) || ( strlen( folderPrefix ) == 0 ) )
		return 1 // nowhere to save
	endif
	
	if ( ( numtype( lastbackup ) > 0 ) || ( minutes >= lastbackup + backup ) )
		fname = folderPrefix + "_backup.pxp"
		//NMProgressCall( -1, "Backing up current Igor experiment..." )
		//NMProgressCall( -2, "Backing up current Igor experiment..." )
		SaveExperiment /P=ClampSaveDataPath as fname
		//NMProgressKill()
		Print time() + " backed up current Igor experiment as " + S_path + fname
		SetNMvar( cdf+"LastBackUp", minutes )
	endif
	
	return 0

End // ClampAutoBackupNM

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Current Stim Functions
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimCurrent()

	return StrVarOrDefault( NMClampDF+"CurrentStim", "" )
	
End // StimCurrent

//****************************************************************
//****************************************************************
//****************************************************************

Function StimCurrentCheck() // check current stim is OK
	
	String cdf = NMClampDF
	String currentStim = StimCurrent()
	String sList = StimList()
	
	if ( strlen( CurrentStim+sList ) == 0 ) // nothing is open
	
		currentStim = "nmStim0"
		NMStimNew( currentStim ) // begin with blank stim
		StimCurrentSet( currentStim )
		
	elseif ( WhichListItem( UpperStr( currentStim ), UpperStr( sList ) ) == -1 )
	
		StimCurrentSet( StringFromList( 0, sList ) )
		
	endif

End // StimCurrentCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function /S StimCurrentSet( fname ) // set current stim
	String fname // stimulus name
	
	Variable icnt, update1, update2, update3, ADCnum
	String sdf, df = NMStimsDF, cdf = NMClampDF
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	Variable lastMode = NumVarOrDefault( "CT_RecordMode", 0 )
	
	if ( strlen( fname ) == 0 )
		SetNMstr( cdf+"CurrentStim", "" )
		return ""
	endif
	
	if ( stringmatch( fname, StimCurrent() ) == 1 )
		//return 0 // already current stim
	endif
	
	if ( DataFolderExists( df+fname ) == 0 )
		return ""
	endif
	
	if ( IsStimFolder( df, fname ) == 0 )
		ClampError( 1, NMQuotes( fname ) + " is not a NeuroMatic stimulus folder.")
		return ""
	endif
	
	ClampSpikeDisplaySavePosition()
	ClampStatsDisplaySavePositions()
	
	sdf = df + fname + ":"
	
	SetNMstr( cdf+"CurrentStim", fname )
	
	if ( NMStimChainOn( "" ) == 1 )
		NMStimChainEdit( "" )
		//ClampTabUpdate()
		return fname
	endif
	
	if ( ( lastmode == 0 ) && ( strlen( prefixFolder ) > 0 ) ) // empty folder
		SetNMvar( prefixFolder+"CurrentChan", NumVarOrDefault( sdf+"CurrentChan", 0 ) )
		SetNMvar( prefixFolder+"NumChannels", NMStimBoardNumADCchan( sdf ) )
	endif
	
	NMStimBoardConfigsOld2NewAll( "" )
	NMStimBoardConfigsUpdateAll( "" )
	
	ClampStatsRetrieveFromStim() // get Stats from new stim
	ClampStats( NMStimStatsOn() )
	ClampGraphsCopy( -1, -1 ) // get Chan display variables
	ChanGraphsReset()
	ClampStatsDisplaySetPositions()
	ClampSpikeDisplaySetPosition()
	
	//UpdateNMPanel( 0 )
	//ClampTabUpdate()
	//ChanGraphsUpdate()
	
	StatsDisplayClear()
	
	return fname
	
End // StimCurrentSet

//****************************************************************
//****************************************************************
//****************************************************************
//
//
//	Channel graph functions defined below
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ClampGraphsCopy( chanNum, direction )
	Variable chanNum // ( -1 ) for all
	Variable direction // ( 1 ) data folder to clamp data folder ( -1 ) visa versa

	String stim = StimCurrent(), sdf = StimDF()
	String gdf = GetDataFolder( 1 )
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( direction == 1 )
		//if ( StringMatch( stim, StrVarOrDefault( gdf+"CT_Stim", "" ) ) == 1 )
			ChanFolderCopy( -2, prefixFolder, sdf, 1 )
		//endif
	elseif ( direction == -1 )
		ChanFolderCopy( -2, sdf, prefixFolder, 0 )
		//SetNMstr( gdf+"CT_Stim", stim )
	endif

End // ClampGraphsCopy

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampGraphsCloseUnecessary()

	Variable icnt
	Variable ADCnum = NMStimBoardOnCount( "", "ADC" )
	
	for ( icnt = ADCnum ; icnt < 20 ; icnt += 1 )
		ChanGraphClose( icnt, 0 )
	endfor
	
End // ClampGraphsCloseUnecessary

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampGraphsUpdate( mode )
	Variable mode // ( 0 ) preview ( 1 ) record 
	
	Variable ccnt, icnt
	String gName, wlist, wname, cdf = NMClampDF
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	Variable numChannels = NMNumChannels()
	Variable GetChanConfigs = NumVarOrDefault( cdf+"GetChanConfigs", 0 )
	
	if ( GetChanConfigs == 1 )
		ClampGraphsCopy( -1, -1 )
		SetNMvar( cdf+"GetChanConfigs", 0 )
	else
		ClampGraphsCopy( -1, 1 )
	endif
	
	ChanGraphsUpdate() // set scales
	ChanWavesClear( -2 ) // clear all display waves
	
	for ( ccnt = 0; ccnt < numChannels; ccnt += 1 )
	
		gName = ChanGraphName( ccnt )
	
		if ( Wintype( gName ) == 0 )
			continue
		endif
		
		NMChannelGraphDisable( channel = ccnt, all = 1 ) // turn off controls ( eliminates flashing )
		
		wlist = WaveList( "*", ";", "WIN:" + gName )
		
		for ( icnt = 0; icnt < ItemsInList( wlist ); icnt += 1 )
			wname = StringFromList( icnt, wlist )
			RemoveFromGraph /Z/W=$gName $wname // remove extra waves
		endfor
		
		ChanGraphTagsKill( ccnt )
		
		DoWindow /T $gName, NMFolderListName( "" ) + " : Ch " + ChanNum2Char( ccnt )
		
		DoWindow /F $gName
		
		HideInfo /W=$gName
		
		// kill cursors in case they exist
		Cursor /K/W=$gName A // kill cursor A
		Cursor /K/W=$gName B // kill cursor B
		
	endfor
	
	if ( NumChannels > 0 )
		ChanGraphClose( -3, 0 ) // close unnecessary graphs ( kills Chan DF )
	endif
	
	StatsDisplay( -1, NMStimStatsOn() )

End // ClampGraphsUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampGraphsFinish()

	Variable ccnt
	String gname, wname
	
	String fname = NMFolderListName( "" )
	
	Variable currentWave = CurrentNMWave()
	
	for ( ccnt = 0; ccnt < NMNumChannels(); ccnt += 1 )
	
		NMChannelGraphDisable( channel = ccnt, all = 0 )
		
		gname = ChanGraphName( ccnt )
		wname = GetWaveName( "default", ccnt, currentWave )
		
		if ( strlen( fName ) > 0 )
			DoWindow /T $gname, fname + " : Ch " + ChanNum2Char( ccnt ) + " : " + wname
		else
			DoWindow /T $gname, "Ch " + ChanNum2Char( ccnt ) + " : " + wname
		endif
		
	endfor

End // ClampGraphsFinish

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampAutoScale()
	Variable chan
	
	String gName = WinName( 0,1 ) // top graph
	
	if ( IsChanGraph( gname ) == 1 )
		chan = ChanNumGet( gName )
	else
		chan = 0
		gName = ChanGraphName( chan )
	endif
	
	SetAxis /A/W=$gName
	
	NMChannelGraphSet( channel = chan, autoscale = 1 )

End // ClampAutoScale

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampZoom( xzoom, yzoom, xshift, yshift )
	Variable xzoom, yzoom, xshift, yshift
	Variable chan, xmin, xmax, ymin, ymax, ydelta, xdelta
	
	Variable zfactor = 0.1 // zoom factor
	
	String gName = WinName( 0,1 ) // top graph
	String cdf = NMClampDF
	
	if ( IsChanGraph( gName ) == 1 )
		chan = ChanNumGet( gName )
	else
		chan = 0
		gName = ChanGraphName( chan )
	endif
	
	String wName = ChanDisplayWave( chan ) // display wave
	
	GetAxis /Q/W=$gName bottom
	xmin = V_min; xmax = V_max
		
	GetAxis /Q/W=$gName left
	ymin = V_min; ymax = V_max
	
	ydelta = abs( ymax - ymin )
	xdelta = abs( xmax - xmin )
	
	ymin -= yzoom * zfactor * ydelta
	ymax += yzoom * zfactor * ydelta
	
	ymin += yshift * zfactor * ydelta
	ymax += yshift * zfactor * ydelta
	
	xmin -= xzoom * zfactor * xdelta
	xmax += xzoom * zfactor * xdelta
	
	xmin += xshift * zfactor * xdelta
	xmax += xshift * zfactor * xdelta
	
	SetAxis /W=$gName bottom xmin, xmax
	SetAxis /W=$gName left ymin, ymax
	
	NMChannelGraphSet( channel = chan, autoscale = 0 )
	
	SetNMvar( cdf+"AutoScale" + num2istr( chan ), 0 )
	SetNMvar( cdf+"xAxisMin" + num2istr( chan ), xmin )
	SetNMvar( cdf+"xAxisMax" + num2istr( chan ), xmax )
	SetNMvar( cdf+"yAxisMin" + num2istr( chan ), ymin )
	SetNMvar( cdf+"yAxisMax" + num2istr( chan ), ymax )

End // ClampZoom

//****************************************************************
//****************************************************************
//****************************************************************
//
//
//	Acquisition board configuration functions
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampBoardName( boardNum )
	Variable boardNum // ( 0 ) driver ( > 0 ) for name from BoardList
	
	String cdf = NMClampDF
	
	Variable driver = NumVarOrDefault( cdf+"BoardDriver", 0 )
	
	String bList = StrVarOrDefault( cdf+"BoardList", "" )
	
	if ( boardNum == 0 )
		boardNum = driver
	endif
	
	if ( ItemsInList( bList ) == 1 )
	
		return StringFromList( 0, bList )
		
	elseif ( ItemsInList( bList ) > 1 )
	
		if ( boardNum <= 0 )
			return StringFromList( 0, bList )
		elseif ( ( boardNum > 0 ) && ( boardNum <= ItemsInList( bList ) ) )
			return StringFromList( boardNum-1, bList )
		endif
		
	endif
	
	return ""

End // ClampBoardName

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampBoardSet( select )
	String select
	
	Variable driver
	String cdf = NMClampDF
	String blist = StrVarOrDefault( cdf+"BoardList", "" )
	
	strswitch( select )
	
		case "ITC16":
		case "ITC18":
			SetNMvar( cdf+"BoardDriver", 0 )
			break
			
		case "NIDAQ":
			driver = ClampBoardDriverPrompt()
			SetNMvar( cdf+"BoardDriver", driver )
			break
			
		default:
			select = "Demo"
			
	endswitch
	
	ClampAcquireManager( select, -2, 0 ) // test interface board
	
	if ( NumVarOrDefault( cdf+"ClampError", -1 ) == 0 )
		SetNMstr( cdf+"BoardSelect", select )
	endif
	
End // ClampBoardSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampBoardDriverPrompt()

	String cdf = NMClampDF
	String blist = StrVarOrDefault( cdf + "BoardList", "" )
	Variable driver = NumVarOrDefault( cdf+"BoardDriver", 0 )

	if ( ItemsInList( blist ) > 1 )
		
		Prompt driver, "please select your default board:", popup blist
		DoPrompt "NIDAQ board configuration", driver
		
		if ( V_flag == 1 )
			driver = 1
		endif
			
	endif
	
	return driver

End // ClampBoardDriverPrompt

//****************************************************************
//****************************************************************
//****************************************************************












#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma hide = 1

//****************************************************************
//****************************************************************
//
//	NeuroMatic: data aquisition, analyses and simulation software that runs with the Igor Pro environment
//	Copyright (C) 2018 Jason Rothman
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
//	For users who do not want NeuroMatic procedure files loaded automatically,
// this procedure file contains code to load the files via a "Load Procedures" menu item. 
//
//	To use this code, place an alias of NeuroMatic's folder in the User Procedures
//	folder, and place an alias of this procedure file (NM_Loader.ipf) in the Igor Procedures folder.
//
//****************************************************************
//****************************************************************

Menu "NeuroMatic"
	StrVarOrDefault( "root:Packages:NeuroMatic:" + "NMMenuLoad", "Load Procedures" ), /Q, LoadNM() // only appears when NM is not initialized
End

//****************************************************************
//****************************************************************

Function LoadNM()
	// Opens procedure files that are in same disk location as NM_Loader.ipf
	// NM_Loader.ipf should be located within NM folder on disk

	Variable icnt
	String flist, fileName, path = ""
	String wName = "NM_Loader.ipf"
	
	GetWindow /Z $wName file
	
	if ( ItemsInList( S_value ) == 3 )
		path = StringFromList( 1, S_value )
	endif
	
	if ( strlen( path ) == 0 )
		return -1
	endif
	
	NewPath /O/Q NMPath, path
	
	PathInfo NMPath
	
	if ( V_flag == 0 )
		return -1
	endif
	
	flist = IndexedFile( NMPath, -1, "????" )
	
	for ( icnt = 0; icnt < ItemsInList( flist ); icnt += 1 )
	
		fileName = StringFromList( icnt, flist )
		
		if ( StrSearch( fileName, ".ipf", 0, 2 ) >= 0 )
			Execute /P/Q/Z "OpenProc /P=NMPath/V=0 \"" + filename + "\""
		endif
		
	endfor
	
	NewPath /O/Q NMClamp, path + "NMClamp:" // load IPF files from NMClamp subfolder
	
	PathInfo NMClamp
	
	if ( V_flag == 0 )
		return -1
	endif
	
	flist = IndexedFile( NMClamp, -1, "????" )
	
	for ( icnt = 0; icnt < ItemsInList( flist ); icnt += 1 )
	
		fileName = StringFromList( icnt, flist )
		
		if ( StrSearch( fileName, ".ipf", 0, 2 ) >= 0 )
			Execute /P/Q/Z "OpenProc /P=NMClamp/V=0 \"" + filename + "\""
		endif
		
	endfor
	
	Execute /P/Q/Z "COMPILEPROCEDURES "		// Note the space before final quote
	
	Execute /P/Q/Z "NMon( 1 )"
	
	Execute /P/Q/Z "KillPath NMClamp"

End // LoadNM

//****************************************************************
//****************************************************************

Function LoadNM2()
	// To use this function procedure files need to be located in
	// "User Procedures" folder

	Execute/P/Q/Z "INSERTINCLUDE \"NM_aMenu\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_ChanGraphs\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_ClampLog\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_ClampNotes\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_ClampStim\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_Configurations\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_DemoTab\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_Deprecated\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_EventTab\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_EventTabOld\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_FileIO\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_FitTab\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_Folders\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_FoldersPrefix\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_Groups\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_Import\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_ImportAxograph\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_ImportPclamp\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_Main\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_MainTab\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_MainTabScalePanel\""
	
	Execute/P/Q/Z "INSERTINCLUDE \"NM_ModelTab0\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_ModelTab1_IAF\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_ModelTab2_IAF_AdEx\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_ModelTab3_HodgkinHuxley1952\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_ModelTab4_Rothman2003\""
			
	Execute/P/Q/Z "INSERTINCLUDE \"NM_Panel\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_Progress\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_PulseGen\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_PulseGenOld\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_PulseTab\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_Sets\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_SpikeTab\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_StatsTab\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_StatsTabKolmogorov\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_StatsTabStability\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_TabManager\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_Utility\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_UtilityWaveLists\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_UtilityWaveStats\""
	
	Execute/P/Q/Z "INSERTINCLUDE \"NM_Clamp\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_ClampAcquire\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_ClampAcquireDemo\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_ClampBoardConfigs\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_ClampFolders\""
	
	if ( ( exists( "ITC16Reset" ) == 4 ) || ( exists( "ITC18Reset" ) == 4 ) )
		Execute/P/Q/Z "INSERTINCLUDE \"NM_ClampITC\""
	endif
	
	if ( exists( "fDAQmx_ErrorString" ) == 4 )
		Execute/P/Q/Z "INSERTINCLUDE \"NM_ClampNIDAQmx\""
	endif
	
	Execute/P/Q/Z "INSERTINCLUDE \"NM_ClampNotes2\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_ClampSpike\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_ClampStats\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_ClampStim2\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_ClampTab\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_ClampTelegraphs\""
	Execute/P/Q/Z "INSERTINCLUDE \"NM_ClampUtility\""
	
	Execute/P/Q/Z "COMPILEPROCEDURES "		// Note the space before final quote
	
	Execute/P/Q/Z "NMon( 1 )"
	
End // LoadNM2

//****************************************************************
//****************************************************************

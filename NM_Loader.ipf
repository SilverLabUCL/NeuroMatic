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

Menu "Macros"
	"Load NeuroMatic", /Q, LoadNM()
End

Function LoadNM()

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
	
End // LoadNM

//****************************************************************
//****************************************************************

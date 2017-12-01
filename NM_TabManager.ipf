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
//	Tab Control Manager
//
//	To use this Tab Manager, create a "tab list" of each tab ( ";" delineated ) where 
//	each list item consists of the tab name, followed by a comma ( "," ), followed by a tab prefix
//	for all control and global variables pertaining to that tab. The last list item should be the 
//	window name in conjunction with the tab control name. One example of a tab list is as follows:
//
//	String TabList = "Main,MN_;Stats,ST_;MyPanel,myTabCntrl"
//
//	This tab list defines two tabs named "Main" and "Stats", for the tab control named "myTabCntrl"
//	on the window "MyPanel". This tab list should be saved as a global variable, and passed
//	to the tab manager functions listed below, where "tabList" is a required input. Note, you should
//	first create your tab control before calling MakeTabs().
//
//	As an example, here are things to do to create a new tab window called "Crunch" on the
//	the tab control named "myTabCntrl" on window "MyPanel":
//
//	1 ) add the name of your tab, with its identifying prefix to TabList. For example,
//		TabList = "Main,MN_;Stats,ST_;Crunch,CR_;MyPanel,myTabCntrl"
//
//	2 ) create a function called Crunch( enable ), which accepts an enable variable flag ( 1 - enable; 0 - disable ).
//		Within this function you should call functions that create controls and global variables that
//		pertain to your tab if enable is one, if they do not already exist. All control names and global
//		variable names should begin with the prefix defined in the tab list, such as "CR_" for Crunch.
//
//		Button MY_Button
//		String MY_StringVar
//
//	3 ) call function ChangeTab( tabNum ) when changing to a new tab. this function automatically
//		enables/disables the appropriate controls, so long as you use the tab's prefix to name your controls.
//
//	4 ) if your tab window creates lots of windows, waves and variables, it might be desireable to kill these
//		"outputs" at some point. Use KillTab( tabNum ) to kill these outputs; however, the output names must begin
//		with the tab's prefix string, such as "My_String" or "My_Table".
//
//	5 ) to call a more specific function pertaining to your tab window, use CallTabFunction( prefixName, tabNum ),
//		which will call a function named "prefixName + tabName". For example, CallTabFunction( "Auto", 2 ) will
//		call AutoCrunch().
//			
//	6 ) See NM_DemoTab.ipf for an example of the above explanation.
//
//****************************************************************
//****************************************************************

Function MakeTabs( tabList ) // set up tab controls
	String tabList	 // list of: tab name, tab prefix
					// followed by: window name, control name
					// for example: "Main,MN_;Stats,ST_;Spike,SP_;MyPanel,myTabCntrl"
	
	if ( TabExists( tabList ) == 0 ) // "empty" tab control should have already been created
		//DoAlert 0, "MakeTabs Abort: tab control does not exist: " + TabCntrlName( tabList )
		return -1
	endif

	Variable icnt
	
	Variable nTabs = NumTabs( tabList )
	String tName = TabCntrlName( tabList )
	String windowName = TabWinName( tabList )
	
	for ( icnt = 0; icnt < nTabs; icnt += 1 ) // add tabs
		TabControl $tName, win=$windowName, tabLabel( icnt )=tabName( icnt, tabList )
	endfor
	
End // MakeTabs

//****************************************************************
//****************************************************************
//****************************************************************

Function ClearTabs( tabList ) // clear tab control
	String tabList	 // list of: tab name, tab prefix
					// followed by: window name, control name
					// for example: "Main,MN_;Stats,ST_;Spike,SP_;MyPanel,myTabCntrl"
					
	Variable iend = NumTabs( tabList ) + 10
	
	if ( TabExists( tabList ) == 0 ) // "empty" tab control should have already been created
		//DoAlert 0, "ClearTabs Abort: tab control does not exist: " + TabCntrlName( tabList )
		return -1
	endif

	Variable icnt
	String tName = TabCntrlName( tabList )
	
	for ( icnt = iend; icnt >= 0; icnt -= 1 )
		TabControl $tName, win=$TabWinName( tabList ), tabLabel( icnt )=""
	endfor
	
End // ClearTabs

//****************************************************************
//****************************************************************
//****************************************************************

Function ChangeTab( fromTab, toTab, tabList ) // change to new tab window
	Variable fromTab
	Variable toTab // tab number
	String tabList // list of tab names
	
	String fromTabName = TabName( fromTab, tabList )
	String toTabName = TabName( toTab, tabList )
	
	Variable configsOn = NMVarGet( "ConfigsDisplay" )
	
	if ( TabExists( tabList ) == 0 )
		//DoAlert 0, "ChangeTabs Abort: tab control does not exist: " + TabCntrlName( tabList )
		return -1
	endif
	
	if ( fromTab != toTab )
		EnableTab( fromTab, tabList, 0 ) // disable controls if they exist
		ExecuteUserTabEnable( fromTabName, 0 )
	endif
	
	EnableTab( toTab, tabList, 1 ) // enable controls if they exist
	
	if ( configsOn == 0 )
		ExecuteUserTabEnable( toTabName, 1 )
	endif
	
	TabControl $TabCntrlName( tabList ), win=$TabWinName( tabList ), value = toTab // reset control

End // ChangeTab

//****************************************************************
//****************************************************************
//****************************************************************

Function ExecuteUserTabEnable( tabName, enable )
	String tabName
	Variable enable
	
	String fxnParams = "( " + num2str( enable ) + " )"
	String fxn = tabName + "Tab"
	
	if ( exists( fxn ) != 6 )
	
		fxn = "NM" + fxn
		
		if ( exists( fxn ) != 6 )
			return -1
		endif
		
	endif
	
	Execute /Z fxn + fxnParams
	
	if ( V_Flag == 0 )
		return 0
	else
		return -1 // no function execution
	endif
	
End // ExecuteUserTabEnable

//****************************************************************
//****************************************************************
//****************************************************************

Function EnableTab( tabNum, tabList, enable ) // enable/disable a tab window
	Variable tabNum // tab number
	String tabList // list of tab names
	Variable enable // 1 - enable; 0 - disable
	
	Variable configsOn = NMVarGet( "ConfigsDisplay" )
	
	String cList
	String windowName = TabWinName( tabList )
	
	if ( TabExists( tabList ) == 0 )
		//DoAlert 0, "EnableTabs Abort: tab control does not exist: " + TabCntrlName( tabList )
		return -1
	endif
	
	DoWindow /F $windowName
	
	cList = ControlList( windowName, "CF_*", ";" )
	
	if ( configsOn > 0 )
		EnableTabList( windowName, cList, 1 )
		enable = 0
	else
		EnableTabList( windowName, cList, 0 )
	endif
	
	cList = ControlList( windowName, TabPrefix( tabNum, tabList ) + "*", ";" )
	
	EnableTabList( windowName, cList, enable )

End // EnableTab

//****************************************************************
//****************************************************************
//****************************************************************

Function EnableTabList( windowName, cList, enable )
	String windowName
	String cList // control name list
	Variable enable // 1 - enable; 0 - disable
	
	Variable icnt
	String cname
	
	if ( ItemsInList( cList ) == 0 )
		return 0
	endif
	
	for ( icnt = 0; icnt < ItemsInList( cList ); icnt += 1 )
	
		cname = StringFromList( icnt, cList )
		
		ControlInfo /W=$windowName $cname
		
		switch( abs( V_Flag ) )
			case 1:
				Button $cname, disable=( !enable ), win=$windowName
				break
			case 2:
				CheckBox $cname, disable=( !enable ), win=$windowName
				break
			case 3:
				PopupMenu $cname, disable=( !enable ), win=$windowName
				break
			case 4:
				ValDisplay $cname, disable=( !enable ), win=$windowName
				break
			case 5:
				SetVariable $cname, disable=( !enable ), win=$windowName
				break
			case 6:
				Chart $cname, disable=( !enable ), win=$windowName
				break
			case 7:
				Slider $cname, disable=( !enable ), win=$windowName
				break
			case 8:
				TabControl $cname, disable=( !enable ), win=$windowName
				break
			case 9:
				GroupBox $cname, disable=( !enable ), win=$windowName
				break
			case 10:
				TitleBox $cname, disable=( !enable ), win=$windowName
				break
			case 11:
				ListBox $cname, disable=( !enable ), win=$windowName
				break
		endswitch
		
	endfor
	
	return 0
	
End // EnableTabList

//****************************************************************
//****************************************************************
//****************************************************************

Function ExecuteUserTabKill( tabName, select )
	String tabName
	String select
	
	String fxnParams = "( " + TMQuotes( select ) + " )"
	String fxn = tabName + "TabKill"
	
	if ( exists( fxn ) != 6 )
	
		fxn = "NM" + fxn
		
		if ( exists( fxn ) != 6 )
	
			fxn = "Kill" + tabName
			
			if ( exists( fxn ) != 6 )
				return -1
			endif
		
		endif
		
	endif
	
	Execute /Z fxn + fxnParams
	
	if ( V_Flag == 0 )
		return 0
	else
		return -1 // no function execution
	endif
	
End // ExecuteUserTabKill

//****************************************************************
//****************************************************************
//****************************************************************

Function KillTab( tabNum, tabList, dialogue ) // kill global variables, controls and windows related to a tab
	Variable tabNum // tab number
	String tabList // list of tab names
	Variable dialogue // call dialogue flag ( 1 - yes; 0 - no )
	
	String prefix = TabPrefix( tabNum, tabList ) + "*"
	String tname = TabName( tabNum, tabList )
	
	if ( TabExists( tabList ) == 0 )
		//DoAlert 0, "KillTabs Abort: tab control does not exist: " + TabCntrlName( tabList )
		return -1
	endif
	
	if ( ExecuteUserTabEnable( tName, 0 ) < 0 )
		return -1
	endif
	
	If ( dialogue == 1 )
		DoAlert 1, "Kill " + TMQuotes( tname ) + " plots and tables?"
	endif
		
	if ( ( V_Flag == 1 ) || ( dialogue == 0 ) )
		KillWindows( prefix )
	endif
	
	If ( dialogue == 1 )
		DoAlert 1, "Kill " + TMQuotes( tname ) + " output waves?"
	endif
		
	if ( ( V_Flag == 1 ) || ( dialogue == 0 ) )
	
		KillGlobals( GetDataFolder( 1 ), prefix, "001" ) // kill waves
		
		ExecuteUserTabKill( tName, "waves" )
		
	endif
	
	If ( dialogue == 1 )
		DoAlert 1, "Kill " + TMQuotes( tname ) + " strings and variables?"
	endif
	
	if ( ( V_Flag == 1 ) || ( dialogue == 0 ) )
	
		KillGlobals( GetDataFolder( 1 ), prefix, "110" ) // kill variables and strings in current folder
		
		ExecuteUserTabKill( tName, "folder" )
		
	endif
	
End // KillTab

//****************************************************************
//****************************************************************
//****************************************************************

Function KillTabs( tabList ) // kill all tabs, no dialogue
	String tabList // list of tab names
	
	if ( TabExists( tabList ) == 0 )
		//DoAlert 0, "KillTabs Abort: tab control does not exist: " + TabCntrlName( tabList )
		return -1
	endif
	
	Variable icnt
	
	for ( icnt = 0; icnt < NumTabs( tabList ); icnt += 1 ) // kill each tab
		KillTab( icnt, tabList, 0 ) // no dialogue
	endfor

End // KillTabs

//****************************************************************
//****************************************************************
//****************************************************************

Function KillTabControls( tabNum, tabList ) // kill tab controls
	Variable tabNum // tab number
	String tabList // list of tab names
	
	String prefix = TabPrefix( tabNum, tabList ) + "*"
	String tname = TabName( tabNum, tabList )
	
	if ( TabExists( tabList ) == 0 )
		//DoAlert 0, "KillTabControls Abort: tab control does not exist: " + TabCntrlName( tabList )
		return -1
	endif

	KillControls( TabWinName( tabList ), prefix ) // kill controls
	
End // KillTabControls

//****************************************************************
//****************************************************************
//****************************************************************

Function CallTabFunction( funcPrefix, tabNum, tabList ) // call a tab's function, whose name is Prefix + TabName
	String funcPrefix // function prefix name, such as "Auto", to be conjoined with the tab's name
	Variable tabNum // tab number
	String tabList // list of tab names
	
	// execute function PrefixTabName().
	// for example, if the prefix is "Auto" and tab name is "Main", AutoMain() will be executed.
	
	if ( TabExists( tabList ) == 0 )
		//DoAlert 0, "CallTabFunction Abort: tab control does not exist: " + TabCntrlName( tabList )
		return -1
	endif
	
	Execute /Z funcPrefix + TabName( tabNum, tabList ) + "()"
	
	return V_flag // return error flag ( zero if no error )

End // CallTabFunction

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Tab Manager utility functions defined below
//
//****************************************************************
//****************************************************************
//****************************************************************

Function TabExists( tabList ) // determine if tab control exists, as defined by tab list
	String tabList // list of tab names
	
	ControlInfo /W=$TabWinName( tabList ) $TabCntrlName( tabList )
	
	if ( V_Flag == 8 )
		return 1
	else
		return 0
	endif
	
End // TabExists

//****************************************************************
//****************************************************************
//****************************************************************

Function NumTabs( tabList ) // compute the number of tabs defined by tab list
	String tabList // list of tab names
	
	return ItemsInList( tabList, ";" )-1

End // NumTabs

//****************************************************************
//****************************************************************
//****************************************************************

Function /S TabWinName( tabList ) // extract window name from the tab list
	String tabList // list of tab names
	String name = ""
	
	name = StringFromList( ItemsInList( tabList, ";" )-1, tabList, ";" )
	name = StringFromList( 0, name, "," )
	
	return name

End // TabWinName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S TabCntrlName( tabList ) // extract control name from the tab list
	String tabList // list of tab names
	String name = ""
	
	name = StringFromList( ItemsInList( tabList, ";" )-1, tabList, ";" )
	name = StringFromList( 1, name, "," )
	
	return name

End // TabCntrlName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S TabName( tabNum, tabList ) // extract tab name from the tab list
	Variable tabNum // tab number
	String tabList // list of tab names
	String name = ""
	
	name = StringFromList( tabNum, tabList, ";" )
	name = StringFromList( 0, name, "," )
	
	return name

End // TabName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S TabNameList( tabList ) // create a list of tab names given TabManager list
	String tabList // list of tab names
	String name, tlist = ""
	Variable icnt
	
	for ( icnt = 0; icnt < ItemsInList( tabList, ";" )-1;icnt += 1 )
		name = StringFromList( icnt, tabList, ";" )
		name = StringFromList( 0, name, "," )
		tlist = AddListItem( name, tlist,";",inf )
	endfor
	
	return tlist

End // TabNameList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S TabPrefix( tabNum, tabList ) // extract tab prefix name of controls and globals from the tab list
	Variable tabNum // tab number
	String tabList // list of tab names
	
	String name
	
	name = StringFromList( tabNum, tabList, ";" )
	name = StringFromList( 1, name, "," )
	
	return name

End // TabPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function TabNumber( tName, tabList ) // determine the tab number, given the tab's name
	String tName // tab name
	String tabList // list of tab names
	
	Variable icnt
	
	for ( icnt = 0; icnt < NumTabs( tabList ); icnt += 1 )
		if ( StringMatch( TabName( icnt, tabList ), tName ) == 1 )
			return icnt
		endif
	endfor
	
	return -1

End // TabNumber

//****************************************************************
//
//	ControlList(): create a list of control names that match matchStr
//
//****************************************************************

Function /S ControlList( wName, mtchStr, listSepStr )
	String wName // window string
	String mtchStr // string match item
	String listSepStr // string list seperator
	
	String olist = ""
	String cList = ControlNameList( wName )
		
	if ( ItemsInList( cList ) == 0 )
		return ""
	endif
	
	Variable icnt
	String cname
	
	for ( icnt = 0; icnt < ItemsInList( cList ); icnt += 1 )
		cname = StringFromList( icnt, cList )
		if ( StringMatch( cname, mtchStr ) == 1 )
			olist = AddListItem( cname, olist, listSepStr, inf )
		endif
	endfor

	return olist
	
End // ControlList

//****************************************************************
//
//	KillControls(): kill a group of controls
//
//****************************************************************

Function KillControls( wName, matchStr )
	String wName // window name
	String matchStr // control name to match ( ie. "ST_*", or "*" for all )
	
	Variable icnt
	
	DoWindow /F $wName
	
	String cList = ControlList( wName, matchStr, ";" )
	
	if ( ItemsInList( cList ) == 0 )
		return 0
	endif
	
	for ( icnt = 0; icnt < ItemsInList( cList ); icnt += 1 )
		KillControl $StringFromList( icnt, cList )
	endfor

End // KillControls

//****************************************************************
//
//	KillGlobals(): kill a group of variables, strings and/or waves
//
//****************************************************************

Function KillGlobals( folder, matchStr, select )
	String folder	// folder name ( "" ) current folder
	String matchStr	// variable/string name to match ( ie. "ST_*", or "*" for all )
	String select	// variable | string | wave ( e.g. "111" for all, or "001" for waves )
	
	Variable icnt
	String vList, sList, wList, saveDF
	
	if ( strlen( folder ) == 0 )
		folder = GetDataFolder( 1 )
	elseif ( DataFolderExists( folder ) == 0 )
		return -1
	endif
	
	saveDF = GetDataFolder( 1 )
	
	SetDataFolder $folder
	
	vList = VariableList( matchStr, ";", 4+2 )
	sList = StringList( matchStr, ";" )
	wList = WaveList( matchStr, ";", "" )
	
	if ( ( StringMatch( select[ 0,0 ], "1" ) == 1 ) && ( ItemsInList( vList ) > 0 ) )
		for ( icnt = 0; icnt < ItemsInList( vList ); icnt += 1 )
			KillVariables /Z $StringFromList( icnt, vList )
		endfor
	endif
	
	if ( ( StringMatch( select[ 1,1 ], "1" ) == 1 ) && ( ItemsInList( sList ) > 0 ) )
		for ( icnt = 0; icnt < ItemsInList( sList ); icnt += 1 )
			KillStrings /Z $StringFromList( icnt, sList )
		endfor
	endif
	
	if ( ( StringMatch( select[ 2,2 ], "1" ) == 1 ) && ( ItemsInList( wList ) > 0 ) )
		for ( icnt = 0; icnt < ItemsInList( wList ); icnt += 1 )
			KillWaves /Z $StringFromList( icnt, wList )
		endfor
	endif
	
	SetDataFolder $saveDF

End // KillGlobals

//****************************************************************
//
//	KillWindows(): kill a group of windows
//
//****************************************************************

Function KillWindows( matchStr )
	String matchStr // window name to match ( ie. "ST_*", or "*" for all )
	
	Variable wcnt, killwin
	String wName, wList
	
	wList = WinList( matchStr, ";","WIN:3" )
	
	if ( ItemsInList( wList ) == 0 )
		return 0
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
		wName = StringFromList( wcnt, wList )
		DoWindow /K $wName // close graphs and tables
	endfor

End // KillWindows

//****************************************************************
//****************************************************************
//****************************************************************

Function /S TMQuotes( istring )
	String istring

	return "\"" + istring + "\""

End // TMQuotes

//****************************************************************
//****************************************************************
//****************************************************************

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
//	Panel Functions
//
//****************************************************************
//****************************************************************

//StrConstant NMPopupFolderList = "Open Data File;---;New;Close;Save;Duplicate;Rename;Merge;---;Save All;Close All;---;Load Waves;Load Waves From Folder;Reload Waves;Save Waves;Rename Waves;Make Waves;---;Set Open Path;Set Save Path;---;Edit FolderList;"
StrConstant NMPopupFolderList = "Open Data Files;Open All Data Files Inside Subfolders;Load Waves From Files;File Name Replace Strings;---;New;Close;Save;Duplicate;Rename;Merge;---;Save All;Close All;---;Set Open Path;Set Save Path;---;Edit FolderList;"
StrConstant NMPanelName = "NMPanel"

Constant NMPanelWidth = 300 // pixels
Constant NMPanelHeight = 640 // pixels
Constant NMPanelTabY = 170 // pixels
Constant NMPanelFsize = 11

// NM panel was designed using Igor 5/6.
// Hence, it is best viewed with 72 Panel Resolution.

//****************************************************************
//****************************************************************

#if Exists("PanelResolution") != 3
Function PanelResolution(wName)	// for compatibility with Igor 6
	String wName // window name
	return 72 // for Igor 6 and earlier, this is always 72
End
#endif

//****************************************************************
//****************************************************************

Function NMPanelSaveXY()

	if (WinType( NMPanelName ) == 0)
		return 0
	endif
	
	Variable scale = 1
	
	GetWindow $NMPanelName wsizeDC // pixels
	
	if ( ( V_right > V_left ) && ( V_top < V_bottom ) )
		SetNMvar( NMDF + "NMPanelX0", V_left * scale )
		SetNMvar( NMDF + "NMPanelY0", V_top * scale )
		NMConfigVarSet( "NeuroMatic", "NMPanelX0", V_left * scale )
		NMConfigVarSet( "NeuroMatic", "NMPanelY0", V_top * scale )
	endif

End // NMPanelSaveXY

//****************************************************************
//****************************************************************

Function MakeNMPanel( [ history ] )
	Variable history

	Variable x0, y0, x1, y1, yinc, icnt, lineheight, autoX0, autoY0
	String ctrlName, setName
	
	if ( history )
		NMCommandHistory( "" )
	endif

	if (DataFolderExists( NMDF ) == 0)
		CheckNMVersion()
	endif
	
	if (NMVarGet( "NMon" ) == 0 )
		SetNMvar( NMDF + "NMon", 1 )
	endif
	
	CheckNMvar(NMDF+"SumSet0", 0)				// set counters
	CheckNMvar(NMDF+"SumSet1", 0)
	CheckNMvar(NMDF+"SumSet2", 0)
	
	CheckNMvar(NMDF+"NumActiveWaves", 0) 	// number of active waves to analyze
	
	CheckNMvar(NMDF+"CurrentWave", 0)			// current wave to display
	CheckNMvar(NMDF+"CurrentGrp", 0)			// current group number
	CheckNMstr(NMDF+"CurrentGrpStr", "0")		// current group number string
	
	Variable fs = NMPanelFsize
	
	String tabList = NMTabControlList() 
	
	STRUCT NMRGB c
	STRUCT NMRGB c2
	
	NMColorList2RGB( NMWinColor, c )
	
	NMColorList2RGB( NMWinColor2, c2 )
	
	x0 = NMVarGet( "NMPanelX0" )
	y0 = NMVarGet( "NMPanelY0" )
	
	autoX0 = NMScreenPixelsX() - NMPanelWidth - 10
	autoY0 = 53//43
	
	if ( ( numtype( x0 ) > 0 ) || ( x0 > autoX0 ) )
		x0 = autoX0
	endif
	
	if ( numtype( y0 ) > 0 )
		y0 = autoY0
	endif
	
	x1 = x0 + NMPanelWidth
	y1 = y0 + NMPanelHeight
	
	DoWindow /K $NMPanelName
	NewPanel /K=1/N=$NMPanelName/W=(x0, y0, x1, y1) as "NeuroMatic v" + NMVersionStr
	// Igor help says 'coordinates are in points', but seems like pixels?
	SetWindow $NMPanelName, hook=NMPanelHook
	
	ModifyPanel cbRGB = (c.r,c.g,c.b)
	
	x0 = 40
	y0 = 6
	yinc = 29
	lineheight = y0 + 94
	
	//focusRing=fr
	
	PopupMenu NM_FolderMenu, title=" ", pos={x0+240, y0+0*yinc}, size={0,0}, bodyWidth=260, help={"data folders"}, win=$NMPanelName
	PopupMenu NM_FolderMenu, mode=1, value = " ", proc=NMPopupFolder, fsize=fs, win=$NMPanelName
	
	PopupMenu NM_PrefixMenu, title=" ", pos={x0+140, y0+1*yinc}, size={0,0}, bodyWidth=130, help={"wave prefix select"}, win=$NMPanelName
	PopupMenu NM_PrefixMenu, mode=1, value="Wave Prefix", proc=NMPopupPrefix, fsize=fs, win=$NMPanelName
	
	PopupMenu NM_SetsMenu, pos={x0+240, y0+1*yinc}, size={0,0}, bodyWidth=85, proc=NMPopupSets, help={"Set functions"}, win=$NMPanelName
	PopupMenu NM_SetsMenu, value = " ", fsize=fs, win=$NMPanelName
	
	PopupMenu NM_GroupMenu, title="G ", pos={x0, y0+2*yinc}, size={0,0}, bodyWidth=20, proc=NMPopupGroups, help={"Groups"}, win=$NMPanelName
	PopupMenu NM_GroupMenu, mode=1, value = "", fsize=fs, win=$NMPanelName
	
	SetVariable NM_SetWaveNum, title= " ", pos={x0+20, y0+2*yinc+2}, size={55,50}, limits={0,inf,0}, value=$(NMDF+"CurrentWave"), win=$NMPanelName
	SetVariable NM_SetWaveNum, frame=1, fsize=fs, proc=NMSetVariable, help={"current wave"}, win=$NMPanelName
	
	SetVariable NM_SetGrpStr, title="Grp", pos={x0+80, y0+2*yinc+3}, size={55,50}, limits={0,inf,0}, value=$(NMDF+"CurrentGrpStr"), win=$NMPanelName
	SetVariable NM_SetGrpStr, frame=1, fsize=fs, proc=NMSetVariable, help={"current group"}, win=$NMPanelName
	
	Button NM_JumpBck, title="<", pos={x0+21, y0+3*yinc}, size={20,20}, proc=NMButton, help={"previous wave"}, win=$NMPanelName, fsize=14
	Button NM_JumpFwd, title=">", pos={x0+112, y0+3*yinc}, size={20,20}, proc=NMButton, help={"next wave"}, win=$NMPanelName, fsize=14
	
	Slider NM_WaveSlide, pos={x0+45, y0+3*yinc}, size={61,50}, limits={0,0,1}, vert=0, side=2, ticks=0, variable = $(NMDF+"CurrentWave"), proc=NMWaveSlide, win=$NMPanelName
	
	PopupMenu NM_SkipMenu, title="+ ", pos={x0, y0+3*yinc-1}, size={0,0}, bodyWidth=20, help={"wave increment"}, proc=NMPopupSkip, win=$NMPanelName
	PopupMenu NM_SkipMenu, mode=1, value=" ;Wave Increment = 1;Wave Increment > 1;As Wave Select;", fsize=14, win=$NMPanelName
	
	yinc = 31.5
	
	GroupBox NM_ChanWaveGroup, title = "", pos={0,y0+4*yinc-9}, size={NMPanelWidth, 39}, win=$NMPanelName, labelBack=(c2.r,c2.g,c2.b)
	
	PopupMenu NM_ChanMenu, title="", pos={x0-20, y0+4*yinc}, bodywidth=50, value=" ", mode=1, proc=NMPopupChan, help={"limit channels to analyze"}, fsize=fs, win=$NMPanelName
	
	PopupMenu NM_WaveMenu, title="", value ="Wave Select", mode=1, pos={x0+160, y0+4*yinc}, bodywidth=160, proc=NMPopupWaveSelect, help={"limit waves to analyze"}, fsize=fs, win=$NMPanelName
	
	SetVariable NM_WaveCount, title=" ", pos={x0+215, y0+4*yinc+2}, size={40,50}, limits={0,inf,0}, value=$(NMDF+"NumActiveWaves"), fsize=fs, win=$NMPanelName
	SetVariable NM_WaveCount, frame=0, help={"number of currently selected waves"}, win=$NMPanelName, labelBack=(c2.r,c2.g,c2.b), noedit=1
	
	y0 += yinc
	
	for ( icnt = 0 ; icnt <= 2 ; icnt += 1 )
	
		setName = NMSetsDisplayName( icnt )
		ctrlName = "NM_Set" + num2istr( icnt ) + "Check"
		
		CheckBox $ctrlName, title=setName+" ", pos={x0+165, y0+28+18*icnt}, value=0, proc=NMSetsCheckBox, help={"include in "+setName}, fsize=fs, win=$NMPanelName
	
	endfor
	
	SetNMvar( NMDF+"ConfigsDisplay", 0 )
	
	NMConfigsListBoxMake( 1 )
	
	CheckBox NM_Configs, title="Configs", pos={20,615}, size={16,18}, value=NMVarGet("ConfigsDisplay"), win=$NMPanelName
	CheckBox NM_Configs, proc=NMConfigsCheckBox, help={"display tab configurations"}, fsize=fs, win=$NMPanelName
	
	TabControl $NMTabControlName(), win=$NMPanelName, pos={0, NMPanelTabY}, size={NMPanelWidth*1.0, NMPanelHeight}, labelBack=(c.r,c.g,c.b), proc=NMTabControl, fsize=fs, win=$NMPanelName
	
	UpdateNMPanel( 1, makeTabs = 1 )
	
	return 0
	
End // MakeNMPanel

//****************************************************************
//****************************************************************

Function NMPanelHook(infoStr)
	String infoStr
	
	String event= StringByKey("EVENT",infoStr)
	String win= StringByKey("WINDOW",infoStr)
	
	if (StringMatch(win, NMPanelName) == 0)
		return 0 // wrong window
	endif
	
	if (StringMatch(event, "activate") == 1)
		CheckCurrentFolder()
		//CheckNMFolderList()
	endif

End // NMPanelHook

//****************************************************************
//****************************************************************

Function NMPanelDisable()
	
	if ( strlen( CurrentNMPrefixFolder() ) == 0 )
		return 2
	endif
	
	if ( NMNumChannels() <= 0 )
		return 2
	endif
	
	if ( NMNumWaves() <= 0 )
		return 2
	endif
	
	return 0
	
End // NMPanelDisable

//****************************************************************
//****************************************************************

Function NMPanelUpdateSet( on )
	Variable on // ( 0 ) off ( 1 ) on
	
	if ( on == 0 )
		SetNMvar( NMDF + "NMPanelUpdate", 0 )
	else
		SetNMvar( NMDF + "NMPanelUpdate", 1 )
	endif

End // NMPanelUpdateSet

//****************************************************************
//****************************************************************

Function UpdateNMPanel( updateTab [ makeTabs ] )
	Variable updateTab
	Variable makeTabs
	
	Variable icnt, dis, thisTab
	String ctrlName, tabList
	
	if ( WinType( NMPanelName ) != 7 )
		return 0
	endif
	
	if ( !NMVarGet( "NMPanelUpdate" ) )
		return 0
	endif
	
	if ( updateTab || makeTabs )
		thisTab = NMVarGet( "CurrentTab" )
		NMTabsMake( makeTabs )
		tabList = NMTabControlList()
		ChangeTab( thisTab, thisTab, tabList )
	endif
	
	UpdateNMPanelTabNames()
	UpdateNMPanelVariables()
	
	UpdateNMPanelFolderMenu()
	UpdateNMPanelGroupMenu()
	UpdateNMPanelSetVariables()
	UpdateNMPanelPrefixMenu()
	UpdateNMPanelChanSelect()
	UpdateNMPanelWaveSelect()
	UpdateNMPanelSets( 1 )
	
	CheckBox NM_Configs, value=NMVarGet("ConfigsDisplay"), win=$NMPanelName

End // UpdateNMPanel

//****************************************************************
//****************************************************************

Function UpdateNMPanelVariables()

	Variable currentWave, currentGroup
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		
		SetNMvar( NMDF+"SumSet0", 0 )
		SetNMvar( NMDF+"SumSet1", 0 )
		SetNMvar( NMDF+"SumSet2", 0 )
		SetNMvar( NMDF+"NumActiveWaves", 0 )
		SetNMvar( NMDF+"CurrentWave", 0 )
		SetNMvar( NMDF+"CurrentGrp", 0)
		SetNMstr( NMDF+"CurrentGrpStr", "0")
	
	else
	
		currentWave = CurrentNMWave()
		currentGroup = NMGroupsNum( -1 )
	
		//SetNMvar( NMDF+"NumActiveWaves", NumVarOrDefault(prefixFolder+"NumActiveWaves", 0) )
		SetNMvar( NMDF+"CurrentWave", currentWave )
		SetNMvar( NMDF+"CurrentGrp", currentGroup )
		SetNMstr( NMDF+"CurrentGrpStr", NMGroupsStr( currentGroup ) )
	
	endif

End // UpdateNMPanelVariables

//****************************************************************
//****************************************************************

Function /S UpdateNMPanelTitle()
	
	if (WinType(NMPanelName) == 7)
		DoWindow /T $NMPanelName, NMFolderListName("") + " : " + CurrentNMFolder( 0 )
	endif

End // UpdateNMPanelTitle

//****************************************************************
//****************************************************************

Function UpdateNMPanelTabNames()

	Variable configs = NMVarGet("ConfigsDisplay")
	
	String ctrlName = NMTabControlName()
	
	Variable extraTabNum = NMTabsExtraNum()
	
	if ( configs == 1 )
		TabControl $ctrlName, win=$NMPanelName, tabLabel( extraTabNum )="NM"
	else
		TabControl $ctrlName, win=$NMPanelName, tabLabel( extraTabNum )="+"
	endif
	
End // UpdateNMPanelTabNames

//****************************************************************
//****************************************************************

Function UpdateNMPanelSetVariables()

	Variable numWaves, numWavesMax, x0 = 40, y0 = 6, yinc = 29
	
	String prefixFolder = CurrentNMPrefixFolder()

	Variable grpsOn = NMVarGet( "GroupsOn" )
	
	Variable dis = NMPanelDisable()
	
	if ( strlen( prefixFolder ) > 0 )
		numWaves = NMNumWaves()
		numWavesMax = max( 0, numWaves - 1 )
	else
		grpsOn = 0
	endif
	
	if (grpsOn == 1)
		SetVariable NM_SetWaveNum, win=$NMPanelName, limits={0,numWavesMax,0}, pos={x0+20, y0+2*yinc+3}, disable=dis
		SetVariable NM_SetGrpStr, win=$NMPanelName, disable=0
	else
		SetVariable NM_SetWaveNum, win=$NMPanelName, limits={0,numWavesMax,0}, pos={x0+49, y0+2*yinc+3}, disable=dis
		SetVariable NM_SetGrpStr, win=$NMPanelName, disable=1
	endif
	
	Slider NM_WaveSlide, win=$NMPanelName, limits={0,numWavesMax,1}, disable=dis
	
	Button NM_JumpBck, win=$NMPanelName, disable=dis
	Button NM_JumpFwd, win=$NMPanelName, disable=dis

End // UpdateNMPanelSetVariables

//****************************************************************
//****************************************************************

Function UpdateNMPanelChanSelect()

	Variable cmode
	
	Variable numChannels = NMNumChannels()
	Variable dis = NMPanelDisable()
	
	String chanStr = NMChanSelectStr()
	String chanMenu = NMChanSelectMenu()
	
	cmode = WhichListItem( chanStr , chanMenu, ";", 0, 0 )
	
	cmode = max( cmode, 0 )
	
	PopupMenu NM_ChanMenu, win=$NMPanelName, mode=(cmode+1), value=NMChanSelectMenu(), disable=dis

End // UpdateNMPanelChanSelect

//****************************************************************
//****************************************************************

Function /S NMChanSelectMenu()

	String allStr = "All;"
	
	Variable numChannels = NMNumChannels()
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( ( strlen( prefixFolder ) == 0 ) || ( numChannels == 0 ) )
		return " "
	endif
	
	strswitch( CurrentNMTabName() )
		case "Event":
		//case "Fit":
		case "EPSC":
			allStr = "" // "All" is not allowed on these tabs
			break
	
	endswitch
	
	if ( numChannels == 1 )
		return "A;"
	elseif ( numChannels < 3 )
		return "Channel Select;---;" + allStr + NMChanList( "CHAR" )
	endif
	
	return "Channel Select;---;" + allStr + NMChanList( "CHAR" ) + "---;Edit List;"

End // NMChanSelectMenu

//****************************************************************
//****************************************************************

Function UpdateNMPanelWaveSelect()

	Variable modenum
	
	Variable dis = NMPanelDisable()
	
	String waveSelect = NMWaveSelectGet()
	String wmenu = NMWaveSelectMenu()
	
	if ( StringMatch( wmenu, "Wave Select" ) == 1 )
		waveSelect = "Wave Select"
	endif
	
	modenum = WhichListItem(waveSelect, wmenu, ";", 0, 0)
			
	if (modenum == -1) // not in list
		waveSelect = "Wave Select"
		modenum = WhichListItem(waveSelect, wmenu, ";", 0, 0)
	endif
	
	modenum = max( modenum , 0 )
	
	PopupMenu NM_WaveMenu, win=$NMPanelName, mode=(modenum+1), value=NMWaveSelectMenu(), disable=dis

End // UpdateNMPanelWaveSelect

//****************************************************************
//****************************************************************

Function /S NMWaveSelectMenu()

	Variable numSets, numGrps, numAdded
	String grpList = "", otherList = "", outList
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( ( strlen( prefixFolder ) == 0 ) || ( NMNumWaves() < 1 ) )
		return " "
	endif
	
	Variable grpsOn = NMVarGet( "GroupsOn" )
	
	String waveSelect = NMWaveSelectGet()
	String setList = NMSetsList()
	String addedList = NMStrGet( "WaveSelectAdded" )
	
	numSets = ItemsInList( setList )
	numAdded = ItemsInList( addedList )
	
	if ( numSets > 1 )
		otherList = AddListItem( "All Sets", otherList, ";", inf )
		otherList = NMAddToList( "Set x Set;", otherList, ";" )
	endif
	
	if ( grpsOn == 1 )
		grpList = NMGroupsList( 1 )
		numGrps = ItemsInList( grpList )
	endif
	
	if ( numGrps > 0 )
	
		otherList = AddListItem("---", otherList, ";", 0 )
		
		if ( numGrps > 1 )
			otherList = NMAddToList( "All Groups;", otherList, ";" )
		endif
		
		if ( numSets > 0 )
			otherList = NMAddToList( "Set x Group;", otherList, ";" )
		endif
		
		grpList = AddListItem("---", grpList, ";", 0 )
		
	endif
	
	if ( numAdded > 0 )
		addedList = AddListItem("---", addedList, ";", 0 )
		addedList = AddListItem( "Clear List", addedList, ";", inf )
	endif
	
	otherList = AddListItem( "This Wave", otherList, ";", inf )
	
	outList = "Wave Select;---;All;" + setList + otherList + addedList + grpList
	
	//outList = AddWaveListCheckMark( waveSelect, outList, ";", 1 )
	
	return outList

End // NMWaveSelectMenu

//****************************************************************
//****************************************************************

Function UpdateNMPanelFolderMenu()

	if (WinType(NMPanelName) == 0)
		return 0
	endif
	
	String item = NMFolderListName("") + " : " + CurrentNMFolder( 0 )
	
	Variable md = max(1, 1 + WhichListItem(item, NMFolderMenu(), ";", 0, 0))

	PopupMenu NM_FolderMenu, mode=md, value=NMFolderMenu(), win=$NMPanelName

End // UpdateNMPanelFolderMenu

//****************************************************************
//****************************************************************

Function /S NMFolderMenu()

	String txt = "---;" + NMPopupFolderList
	
	String folderList = NMDataFolderListLong()
	
	String logList = NMLogFolderListLong()
	
	if (strlen( folderList) > 0)
		
		folderList = "---;" + folderList
	
	endif
	
	if (strlen(logList) > 0)
		
		logList = "---;" + logList
	
	endif

	return "Folder Select;" + folderList + logList + txt

End // NMFolderMenu

//****************************************************************
//****************************************************************

Function UpdateNMPanelGroupMenu()

	PopupMenu NM_GroupMenu, mode=1, value=NMGroupsMenu(), win=$NMPanelName

End // UpdateNMPanelGroupMenu

//****************************************************************
//****************************************************************

Function /S NMGroupsMenu()

	Variable numWaves, numStimWaves, numGrps

	String menuList
	
	Variable on = NMVarGet( "GroupsOn" )
	
	String prefixFolder = CurrentNMPrefixFolder()
	String subStimFolder = SubStimDF()

	if ( strlen( prefixFolder ) == 0 )
	
		menuList = "Groups;"
	
	else
	
		numGrps = NMGroupsNumCount()
		
		menuList = "Groups;---;Define;Convert;"
		
		if ( numGrps > 0 )
			menuList += "Clear;"
		endif
		
		menuList += "Edit Panel;"
	
	endif
		
	if ( on == 1 )
		menuList = AddListItem("Off", menuList, ";", inf)
	else
		menuList = AddListItem("On", menuList, ";", inf)
	endif
	
	if (strlen(subStimFolder) > 0)
	
		numWaves = NumVarOrDefault(prefixFolder+"NumWaves", 0)
	
		numStimWaves = NumVarOrDefault(subStimFolder+"NumStimWaves", numWaves)
		
		menuList += ";---;Groups=" + num2istr(numStimWaves) + ";Blocks="+num2istr(numStimWaves)
		
	endif
	
	return menuList

End // NMGroupsMenu

//****************************************************************
//****************************************************************

Function UpdateNMPanelPrefixMenu()
	
	if (WinType(NMPanelName) == 0)
		return 0
	endif
	
	String cPrefix = CurrentNMWavePrefix()
	String pList = NMPrefixList()
	
	if ((strlen(cPrefix) > 0) && (WhichListItem(cPrefix, pList, ";", 0, 0) == -1))
		pList = AddListItem(cPrefix, pList, ";", inf) // add prefix to list
		SetNMstr( NMDF+"PrefixList", pList )
	endif
	
	PopupMenu NM_PrefixMenu, win=$NMPanelName, mode=1, value=NMPrefixMenu(), popvalue=CurrentNMWavePrefix()

End // UpdateNMPanelPrefixMenu

//****************************************************************
//****************************************************************

Function /S NMPrefixMenu()
	
	return "Wave Prefix;---;" + NMPrefixList() + ";---;Other;Edit Default List;Kill Prefix Globals;User Prompts On/Off;---;Order Waves;Order Waves Preference;"

End // NMPrefixMenu

//****************************************************************
//****************************************************************

Function NMPrefixCall(fxn)
	String fxn
	
	Variable error = -1
	
	strswitch( fxn )
	
		case "Wave Prefix":
			SetNMstr( "CurrentPrefix", "" )
			UpdateNM( 1 )
			break
			
		case "---":
			break
		
		case "Other":
			return NMPrefixOtherCall()
			
		case "Kill Prefix Globals":
			return NMPrefixSubfolderKillCall()
			
		case "User Prompts On/Off":
			return NMPrefixSelectPromptCall()
			
		case "Edit Default List":
			return NMPrefixListSetCall()
			
		case "Clear List":
			return NMPrefixListClear( history = 1 )
			
		case "Remove from List":
			return NMPrefixRemoveCall()
		
		case "Order Waves":
			NMOrderWavesCall()
			break
			
		case "Order Waves Preference":
			NMOrderWavesPrefCall()
			break
		
		default:
		
			NMSet( wavePrefix = fxn, history = 1 )
			
	endswitch
	
	return 0

End // NMPrefixCall

//****************************************************************
//****************************************************************

Function UpdateNMPanelSets( recount ) // udpate Sets display
	Variable recount
	
	Variable icnt, setValue, count, locked
	String ttle, setList, setName, ctrlName
	
	Variable dis = NMPanelDisable()
	
	Variable currentChan = CurrentNMChannel()
	Variable currentWave = CurrentNMWave()
	
	String wname = CurrentNMWaveName()
	
	STRUCT NMRGB c
	
	if ( WinType( NMPanelName ) != 7 )
		return 0
	endif
	
	PopupMenu NM_SetsMenu, disable=dis, value=NMSetsMenu(), mode=1, win=$NMPanelName
	
	if ( recount == 1 )
		UpdateNMSetsDisplayCount()
		UpdateNMWaveSelectCount()
	endif
	
	for ( icnt = 0 ; icnt <= 2 ; icnt += 1 )
	
		setName = NMSetsDisplayName( icnt )
		
		locked = IsNMSetLocked( setName )
		
		if ( locked == 1 )
			NMColorList2RGB( NMRedStr, c )
		else
			c.r = 0
			c.g = 0
			c.b = 0
		endif
		
		ttle = " "
		setValue = 0
		dis = 2
		
		if ( ( strlen( setName ) > 0 ) && ( AreNMSets( setName ) == 1 ) )
		
			setList = NMSetsWaveList( setName, currentChan )
			
			count = NMVarGet( "SumSet" + num2istr( icnt ) )
		
			ttle = setName + " : " + num2str( count ) + " "
		
			if ( ( ItemsInList( setList ) > 0 ) && ( WhichListItem( wname, setList, ";", 0, 0 ) >= 0 ) )
				setValue = 1
			endif
			
			dis = 0
		
		endif
		
		ctrlName = "NM_Set" + num2istr( icnt ) + "Check"
		
		CheckBox $ctrlName, title=ttle, value=(setValue), fcolor=(c.r,c.g,c.b), disable=dis, win=$NMPanelName
	
	endfor

End // UpdateNMPanelSets

//****************************************************************
//****************************************************************

Function /S NMSetsMenu()

	String wName, menuStr
	
	if ( strlen( CurrentNMPrefixFolder() ) == 0 )
		return " "
	endif
	
	menuStr = "Sets;---;Define;Equation;Convert;Invert;Clear;---;Edit Panel;---;New;New via String Key;Copy;Rename;Kill;---;Exclude SetX?;Auto Advance;Display;"
	
	wName = NMSetsEqLockWaveName()
	
	if ( WaveExists( $wName ) == 1 )
		menuStr += "Print Equations;"
	endif
	
	return menuStr

End // NMSetsMenu

//****************************************************************
//****************************************************************

Function /S CurrentNMTabControlName()

	if ( WinType( NMPanelName ) == 7 )

		ControlInfo /W=$NMPanelName $NMTabControlName()
	
		return S_Value
	
	endif
	
	return ""
	
End // CurrentNMTabControlName

//****************************************************************
//****************************************************************

Function NMTabsExtraNum()

	return NumTabs( NMStrGet( "TabControlList" ) )
	
End // NMTabsExtraNum

//****************************************************************
//****************************************************************

Function /S NMTabControlName()

	return TabCntrlName( NMStrGet( "TabControlList" ) )
	
End // NMTabControlName

//****************************************************************
//****************************************************************

Function NMTabControl(name, tab) // called when user clicks on NMPanel tab
	String name; Variable tab
	
	Variable configs = NMVarGet("ConfigsDisplay")
	
	String tabList = NMStrGet( "NMTabList" )
	
	if ( tab < ItemsInList( tabList ) )
	
		name = TabName(tab, NMTabControlList())
		
		NMSet( tab = name, history = 1 )
	
	elseif ( tab == NMTabsExtraNum() )
	
		if ( configs == 0 )
		
			TabControl $NMTabControlName() value=NMVarGet( "CurrentTab" )
		
			NMChangeTabsCall()
			
		else
		
			NMConfigsListBoxWavesUpdate( "NeuroMatic" )
		
		endif
	
	endif

End // NMTabControl

//****************************************************************
//****************************************************************

Function UpdateNMTab( [ forceMakeTabs ] ) // NOT USED
	Variable forceMakeTabs

	Variable thisTab = NMVarGet( "CurrentTab" )
	
	NMTabsMake( forceMakeTabs ) // checks if tablist has changed
	
	ChangeTab( thisTab, thisTab, NMTabControlList() )

End // UpdateNMTab

//****************************************************************
//****************************************************************

Function NMTabsMake( force )
	Variable force // (0) check (1) make

	Variable icnt, tnum
	String tabName
	
	String tabCntrlList = NMStrGet( "TabControlList" )
	String currentList = NMTabListConvert( tabCntrlList )
	String defaultList = NMStrGet( "NMTabList" )
	
	//print currentList
	//print defaultList
	
	String ctrlName = NMTabControlName()
	Variable extraTabNum = NMTabsExtraNum()
	
	if ((force == 1) || (StringMatch(currentList, defaultList) == 0))
	
		for (icnt = 0; icnt < ItemsInList(currentList); icnt += 1)
		
			tabName = StringFromList(icnt, currentList)
			
			if (WhichListItem(tabName, defaultList, ";", 0, 0) < 0)
				tnum = WhichListItem(tabName, currentList, ";", 0, 0)
				KillTabControls(tnum, tabCntrlList)
			endif
			
		endfor
		
		ClearTabs(tabCntrlList) // clear old tabs
		SetNMstr( NMDF+"TabControlList", "" ) // clear old list
		tabCntrlList = NMTabControlList() // update control list
		MakeTabs( tabCntrlList )
		CheckNMTabs( 1 )
		
	endif
	
End // NMTabsMake

//****************************************************************
//****************************************************************

Function NMPopupFolder(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	Variable found
	String vlist
	
	PopupMenu NM_FolderMenu, win=$NMPanelName, mode=1
	
	strswitch(popStr)
	
		case "Folder Select":
		case "---":
			break
			
		default:
		
			if ( WhichListItem( popStr, NMPopupFolderList ) >= 0 )
				NMFolderCall( popStr )
				break
			endif
		
			found = strsearch(popstr, " : ", 0)
		
			if (found >= 0)
				popstr = popstr[found+3,inf]
			endif
		
			if (StringMatch( popstr, CurrentNMFolder( 0 ) ) == 0 )
				NMSet( folder = popStr, history = 1 )
			endif
			
			break
			
	endswitch
	
	UpdateNMPanelFolderMenu()
	CheckNMFolderList()
	
	DoWindow /F $NMPanelName
	
End // NMPopupFolder

//****************************************************************
//****************************************************************

Function NMPopupPrefix(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	strswitch( popStr)
	
		case "---":
			break
			
		default:
	
			NMPrefixCall( popStr )
	
	endswitch
	
	UpdateNMPanelPrefixMenu()
	
	DoWindow /F $NMPanelName

End // NMPopupPrefix

//****************************************************************
//****************************************************************

Function NMPopupGroups(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	PopupMenu NM_GroupMenu, win=$NMPanelName, mode=1
	
	strswitch( popStr)
	
		case "Groups":
		case "---":
			return 0
			
		default:
			NMGroupsCall( popStr, "" )
	
	endswitch
	
End // NMPopupGroups

//****************************************************************
//****************************************************************

Function NMPopupSets(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	PopupMenu NM_SetsMenu, win=$NMPanelName, mode=1
	
	strswitch( popStr)
	
		case "Sets":
		case "---":
			return 0
			
		default:
			NMSetsCall( popStr, "" )
		
	endswitch
	
End // NMPopupSets

//****************************************************************
//****************************************************************

Function NMPopupSkip(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	PopupMenu NM_SkipMenu, win=$NMPanelName, mode=1
	
	strswitch( popStr )
		case " ":
			return 0 // nothing
	
		default:
			NMWaveIncCall( popStr )
			
	endswitch

End // NMPopupSkip

//****************************************************************
//****************************************************************

Function NMPopupChan(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	strswitch( popStr )
	
		case "Channel":
		case "Channel Select":
		case "---":
			UpdateNMPanelChanSelect()
			return 0
			
		case "Edit List":
			if ( NMChanSelectListEdit() < 0 )
				UpdateNMPanelChanSelect()
			endif
			return 0
			
	endswitch
	
	if ( strlen( prefixFolder ) > 0 )
		NMSet( chanSelect = popStr, prefixFolder = "", history = 1 )
	endif
	
	DoWindow /F $NMPanelName
	
End // NMPopupChan

//****************************************************************
//****************************************************************

Function NMPopupWaveSelect(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	strswitch( popStr )
	
		case "Wave Select":
		case "---":
			UpdateNMPanelWaveSelect()
			return 0
	
	endswitch
	
	if ( strlen( prefixFolder ) > 0 )
		NMWaveSelectCall( popStr )
	endif
	
	if ( StringMatch( popStr, "Clear List" ) )
		UpdateNMPanelWaveSelect()
	endif

End // NMPopupWaveSelect

//****************************************************************
//****************************************************************

Function NMButton(ctrlName) : ButtonControl
	String ctrlName
	
	ctrlName = ReplaceString( "NM_", ctrlName, "" )
	
	strswitch( ctrlName )
	
		case "JumpFwd":
			NMNextWave( +1 )
			break
			
		case "JumpBck":
			NMNextWave( -1 )
			break
			
		case "SetsEdit":
			return NMSetsPanel( history = 1 )
			
	endswitch
	
	DoWindow /F $NMPanelName
	
End // NMButton

//****************************************************************
//****************************************************************

Function NMSetVariable(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	Variable waveNum
	
	ctrlName = ReplaceString( "NM_", ctrlName, "" )
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	strswitch( ctrlName )
	
		case "SetWaveNum":
			return NMSet( waveNum = varNum, prefixFolder = "", history = 1 )
			
		case "SetGrpStr":
		
			waveNum = NumVarOrDefault( prefixFolder + "CurrentWave", 0 )
			
			NMGroupsSet( waveNum = waveNum, group = varNum, prefixFolder = "", history = 1 )
			
			return 0
			
	endswitch
	
End // NMSetVariable

//****************************************************************
//****************************************************************

Function NMSetsCheckBox(ctrlName, checked) : CheckBoxControl
	String ctrlName; Variable checked
	
	if ( !NMSetsOK() )
		UpdateNMPanelSets(0)
		return -1
	endif
	
	ctrlName = ReplaceString( "NM_", ctrlName, "" )
	
	NMSetsCall( ctrlName, num2istr( checked ) )
	
	DoWindow /F $NMPanelName

End // NMSetsCheckBox

//****************************************************************
//****************************************************************

Function NMConfigsCheckBox(ctrlName, checked) : CheckBoxControl
	String ctrlName; Variable checked
	
	NMSet( configsDisplay = checked, history = 1 )

End // NMConfigsDisplayCheckBox

//****************************************************************
//****************************************************************

Function NMWaveSlide(ctrlName, value, event) // SlideVariable Control
	String ctrlName
	Variable value // slider value
	Variable event // event - bit 0: value set; 1: mouse down, 2: mouse up, 3: mouse moved
	
	if ( ( event == 4 ) && ( NMPrefixFolderAlert() == 0 ) )
		NMCurrentWaveSet( value )
	endif

End // NMWaveSlide

//****************************************************************
//****************************************************************
//
//	Configuration Listbox Functions
//
//****************************************************************
//****************************************************************

Function /S NMConfigsListBoxWaveName()

	return NMDF + "ConfigVariables"

End // NMConfigsListBoxWaveName

//****************************************************************
//****************************************************************

Function NMConfigsListBoxWavesUpdate( tabName )
	String tabName

	Variable icnt, ocnt, varItems, strItems, items, value
	String varList, strList, objName, objType, strValue, cdf, vList
	
	STRUCT NMRGB c
	
	Variable configs = NMVarGet( "ConfigsDisplay" )
	Variable editByPrompt = NMVarGet( "ConfigsEditByPrompt" )
	
	String wName = NMConfigsListBoxWaveName()
	String wName2 = wName + "Select"
	String wName3 = wName + "Color"
	
	if ( strlen( tabName ) == 0 )
		tabName = CurrentNMTabName()
	endif
	
	cdf = ConfigDF( tabName )
	
	vList = StrVarOrDefault( cdf + "C_VarList", "" )
	
	varList = NMConfigVarList( tabName, 2 )
	
	if ( ItemsInList( varList ) == 0 )
	
		CheckNMConfig( tabName )
		
		varList = NMConfigVarList( tabName, 2 )
		
	endif
	
	strList = NMConfigVarList( tabName, 3 )
	
	varItems = ItemsInList( varList )
	strItems = ItemsInList( strList )
	
	items = varItems + strItems
	
	if ( WaveExists( $wName ) == 0 )
		Make /O/T/N=( items, 4 ) $wName = ""
	else
		Redimension /N=( items, 4 ) $wName
	endif
	
	if ( WaveExists( $wName2 ) == 0 )
		Make /O/N=( items, 4, 2 ) $wName2 = 0
	else
		Redimension /N=( items, 4, 2 ) $wName2
	endif
	
	if ( WaveExists( $wName3 ) == 0 )
		Make /O/N=( items, 3 ) $wName3 = 0
	else
		Redimension /N=( items, 3 ) $wName3
	endif
	
	Wave /T wtemp = $wName
	Wave stemp = $wName2
	Wave ctemp = $wName3
	
	SetDimLabel 1, 0, parameter, wtemp
	SetDimLabel 1, 1, value, wtemp
	SetDimLabel 1, 2, type, wtemp
	SetDimLabel 1, 3, definition, wtemp
	
	SetDimLabel 1, 0, parameter, stemp
	SetDimLabel 1, 1, value, stemp
	SetDimLabel 1, 2, type, stemp
	SetDimLabel 1, 3, definition, stemp
	
	SetDimLabel 2, 0, state, stemp
	//SetDimLabel 2, 1, backColors, stemp
	SetDimLabel 2, 1, foreColors, stemp
	
	SetDimLabel 1, 0, r, ctemp
	SetDimLabel 1, 1, g, ctemp
	SetDimLabel 1, 2, b, ctemp
	
	for (ocnt = 0; ocnt < varItems ; ocnt += 1)
	
		objName = StringFromList( ocnt, varList )
		value = NumVarOrDefault( cdf + objName , Nan )
		objType = StrVarOrDefault( cdf + "T_" + objName, "" )
		
		icnt = WhichListItem( objName, vList, ";", 0, 0 )
		
		if ( icnt < 0 )
			continue
		endif
		
		wtemp[ icnt ][ %parameter ] = objName
		
		wtemp[ icnt ][ %type ] = ""
		wtemp[ icnt ][ %definition ] = StrVarOrDefault( cdf + "D_" + objName, "" )
		
		strswitch( objType )
		
			case "boolean":
			
				if ( value != 1 )
					value = 0
				endif
				
				wtemp[ icnt ][ %value ] = ""
				stemp[ icnt ][ %value ][ %state ] = 2^5 + 2^4 * value // checkbox
				
				break
				
			default:
			
				wtemp[ icnt ][ %value ] = num2str( value )
				
				if ( editByPrompt || ( ItemsInList( objType ) > 1 ) )
					stemp[ icnt ][ %value ][ %state ] = 0
				else
					stemp[ icnt ][ %value ][ %state ] = 2^1
				endif
				
				if ( ItemsInList( objType ) > 1 )
					wtemp[ icnt ][ %type ] = ""
				else
					wtemp[ icnt ][ %type ] = objType
				endif
		
		endswitch
		
		ctemp[ icnt ][ %r ] = 0
		ctemp[ icnt ][ %g ] = 0
		ctemp[ icnt ][ %b ] = 0

		//icnt += 1
		
	endfor
	
	for (ocnt = 0; ocnt < strItems ; ocnt += 1)
	
		objName = StringFromList( ocnt, strList )
		strValue = StrVarOrDefault( cdf + objName , "" )
		objType = StrVarOrDefault( cdf + "T_" + objName, "" )
		
		icnt = WhichListItem( objName, vList, ";", 0, 0 )
		
		if ( ( icnt < 0 ) || ( icnt >= DimSize( wtemp, 0) ) )
			continue
		endif
		
		wtemp[ icnt ][ %parameter ] = objName
		wtemp[ icnt ][ %value ] = strValue
		wtemp[ icnt ][ %type ] = ""
		wtemp[ icnt ][ %definition ] = StrVarOrDefault( cdf + "D_" + objName, "" )
		
		ctemp[ icnt ][ %r ] = 0
		ctemp[ icnt ][ %g ] = 0
		ctemp[ icnt ][ %b ] = 0
		
		if ( editByPrompt || ( ItemsInList( objType ) > 1 ) )
			stemp[ icnt ][ %value ][ %state ] = 0
		else
			stemp[ icnt ][ %value ][ %state ] = 2^1
		endif
		
		if ( ItemsInList( objType ) > 1 )
		
			wtemp[ icnt ][ %type ] = ""

		elseif ( StringMatch( objType, "RGB" ) == 1 )
		
			wtemp[ icnt ][ %type ] = "RGB"
			
			stemp[ icnt ][ %value ][ %foreColors ] = icnt
			
			NMColorList2RGB( strValue, c )
			
			ctemp[ icnt ][ %r ] = c.r
			ctemp[ icnt ][ %g ] = c.g
			ctemp[ icnt ][ %b ] = c.b
			
		elseif ( StringMatch( objType, "DIR" ) == 1 )
		
			wtemp[ icnt ][ %type ] = "DIR"
			
		else
		
			wtemp[ icnt ][ %type ] = objType
			
		endif
		
		//icnt += 1
		
	endfor
	
	ControlInfo /W=$NMPanelName CF_parameters
	
	if ( V_Flag == 11 )
		ListBox CF_parameters, selRow=-1, win=$NMPanelName // remove row selection
	endif

End // NMConfigsListBoxWavesUpdate

//****************************************************************
//****************************************************************

Function NMConfigsListBoxMake( force )
	Variable force
	
	Variable x0, y0, fs = NMPanelFsize
	
	String wName = NMConfigsListBoxWaveName()
	String wName2 = wName + "Select"
	String wName3 = wName + "Color"
	
	NMConfigsListBoxWavesUpdate( "" )
	
	ControlInfo /W=$NMPanelName CF_parameters
	
	if ( ( V_Flag != 0 ) && ( force == 0 ) )
		return 0 // controls exist
	endif
	
	x0 = 10
	y0 = NMPanelTabY + 40
	
	ListBox CF_parameters, pos={x0,y0}, size={280,380}, fsize=fs, disable=1, win=$NMPanelName
	ListBox CF_parameters, listWave=$wName, selWave=$wName2, colorWave=$wName3, win=$NMPanelName
	ListBox CF_parameters, mode=1, selRow=-1, userColumnResize=1, proc=NMConfigsListBoxInput, widths={120, 60, 35, 700}, win=$NMPanelName
	
	//Button CF_Save, pos={x0+15,y0+360}, size={70,20}, proc=NMConfigsButton, title="Save", fsize=fs, disable=1, win=$NMPanelName
	//Button CF_Open, pos={x0+105,y0+360}, size={70,20}, proc=NMConfigsButton, title="Open", fsize=fs, disable=1, win=$NMPanelName
	//Button CF_Reset, pos={x0+195,y0+360}, size={70,20}, proc=NMConfigsButton, title="Reset", fsize=fs, disable=1, win=$NMPanelName
	
End // NMConfigsListBoxMake

//****************************************************************
//****************************************************************

Function NMConfigsListBoxInput( ctrlName, row, col, event ) : ListboxControl
	String ctrlName // name of this control
	Variable row // row if click in interior, -1 if click in title
	Variable col // column number
	Variable event // event code
		// 1 - mouse down
		// 2 - mouse up
		// 3 - double click
		// 4 - cell selection
		// 6 - begin cell edit
		// 7 - end cell edit
		// 13 - checkbox clicked
	
	Variable selValue, typeItems, currentValue, newValue
	String objName, valueStr, type, objType, description
	String currentStr, newStr, rlist
	String tabName, cdf
	
	STRUCT NMRGB c
	
	//Variable configs = NMVarGet( "ConfigsDisplay" )
	Variable editByPrompt = NMVarGet( "ConfigsEditByPrompt" )
	
	String wName = NMConfigsListBoxWaveName()
	String wName2 = wName + "Select"
	String wName3 = wName + "Color"
	
	if ( WaveExists( $wName ) == 0 )
		return -1
	endif
	
	if ( ( row < 0 ) || ( row >= DimSize( $wName, 0 ) ) )
		return 0
	endif
	
	tabName = CurrentNMTabControlName()
	
	if ( StringMatch( tabName, "NM" ) == 1 )
		tabName = "NeuroMatic"
	endif
	
	//if ( configs == 2 )
	//	tabName = "NeuroMatic"
	//else
	//	tabName = CurrentNMTabName()
	//endif
	
	//print configs, tabName
	
	cdf = ConfigDF( tabName )
	
	String varList = NMConfigVarList( tabName, 2 )
	String strList = NMConfigVarList( tabName, 3 )
	
	Wave /T wtemp = $wName
	Wave stemp = $wName2
	Wave ctemp = $wName3
	
	objName = wtemp[ row ][ %parameter ]
	valueStr = wtemp[ row ][ %value ]
	selValue = stemp[ row ][ %value ][ %state ]
	
	type = StrVarOrDefault( cdf + "T_" + objName, "" )
	description = StrVarOrDefault( cdf + "D_" + objName, "" )
	
	typeItems = ItemsInList( type )
	
	if ( WhichListItem( objName, varList ) >= 0 )
		objType = "variable"
		currentValue = NumVarOrDefault( cdf + objName , Nan )
	elseif ( WhichListItem( objName, strList ) >= 0 )
		objType = "string"
		currentStr = StrVarOrDefault( cdf + objName , "" )
	else
		return 0 // unknown
	endif
	
	if ( StringMatch( type, "boolean" ) )
	
		if ( event != 13 )
			return 0
		endif
		
		if ( selValue == 2^5 )
			newValue = 0
		else
			newValue = 1
		endif
			
		NMConfigVarSet( tabName, objName, newValue, history = 1 )
		
	elseif ( StringMatch( type, "RGB" ) )
	
		if ( ( event != 4 ) || !StringMatch( objType, "string" ) )
			return 0
		endif
		
		NMColorList2RGB( currentStr, c )
		
		ChooseColor /C=( c.r,c.g,c.b )
		
		if ( V_Flag == 1 )
		
			c.r = min( max( V_Red, 0 ), 65535 )
			c.g = min( max( V_Green, 0 ), 65535 )
			c.b = min( max( V_Blue, 0 ), 65535 )
			
			newStr = num2str( c.r ) + "," + num2str( c.g ) + "," + num2str( c.b )
			
			wtemp[ row ][ %value ] = newStr
			ctemp[ row ][ %r ] = c.r
			ctemp[ row ][ %g ] = c.g
			ctemp[ row ][ %b ] = c.b
			
			NMConfigStrSet( tabName, objName, newStr, history = 1 )
		
		endif
		
		KillVariables /Z V_Red, V_Gree, V_Blue
		
	elseif ( StringMatch( type, "DIR" ) )
	
		if ( ( event != 4 ) || !StringMatch( objType, "string" ) )
			return 0
		endif
	
		newStr = NMGetExternalFolderPath( "Please specify directory for " + objName, currentStr )
			
		wtemp[ row ][ %value ] = newStr
			
		NMConfigStrSet( tabName, objName, newStr, history = 1 )
		
	elseif ( StringMatch( objType, "variable" ) )
	
		if ( event != 4 )
			return 0
		endif
	
		if ( typeItems > 1 )
			newValue = NMConfigsListBoxInputVarList( objName, currentValue, type )
			newStr = num2str( newValue )
			wtemp[ row ][ %value ] = newStr
			NMConfigVarSet( tabName, objName, newValue, history = 1 )
		elseif ( editByPrompt )
			rlist = NMConfigEditPrompt( tabName, objName, editDefinition = 1 )
			if ( ItemsInList( rlist ) == 3 )
				newStr = StringFromList( 0, rlist )
				wtemp[ row ][ %value ] = newStr
			endif
		else
			newValue = str2num( valueStr )
			NMConfigVarSet( tabName, objName, newValue, history = 1 )
		endif
		
	elseif ( StringMatch( objType, "string" ) )
	
		if ( event != 4 )
			return 0
		endif
	
		if ( typeItems > 1 )
			newStr = NMConfigsListBoxInputStrList( objName, currentStr, type )
			wtemp[ row ][ %value ] = newStr
			NMConfigStrSet( tabName, objName, newStr, history = 1 )
		elseif ( editByPrompt )
			rlist = NMConfigEditPrompt( tabName, objName, editDefinition = 1 )
			if ( ItemsInList( rlist ) == 3 )
				newStr = StringFromList( 0, rlist )
				wtemp[ row ][ %value ] = newStr
			endif
		else
			newStr = valueStr
			NMConfigStrSet( tabName, objName, newStr, history = 1 )
		endif
	
	endif
	
	ListBox CF_parameters, selRow=-1, win=$NMPanelName // remove selection when finished
	
	return 0
			
End // NMConfigsListBoxInput

//****************************************************************
//****************************************************************

Static Function NMConfigsListBoxInputVarList( varName, defaultValue, strList )
	String varName
	Variable defaultValue
	String strList
	
	if ( ItemsInList( strList ) <= 1 )
		return defaultValue
	endif
	
	Variable select = defaultValue + 1
	
	String tabName = CurrentNMTabName()
	
	Prompt select, varName + ":", popup strList
	DoPrompt tabName + " Tab Configuration", select
	
	if ( V_flag == 1 )
		return defaultValue
	endif
	
	return select - 1
	
End // NMConfigsListBoxInputVarList

//****************************************************************
//****************************************************************

Static Function /S NMConfigsListBoxInputStrList( varName, defaultString, strList )
	String varName, defaultString, strList
	
	if ( ItemsInList( strList ) <= 1 )
		return defaultString
	endif
	
	String select = defaultString
	
	String tabName = CurrentNMTabName()
	
	Prompt select, varName + ":", popup strList
	DoPrompt tabName + " Tab Configuration", select
	
	if ( V_flag == 1 )
		return defaultString
	endif
	
	return select
	
End // NMConfigsListBoxInputStrList

//****************************************************************
//****************************************************************

Function NMConfigsButton( ctrlname ): ButtonControl
	String ctrlname
	
	Variable configs
	
	ctrlname = ReplaceString( "CF_", ctrlname, "" )
	
	strswitch( ctrlname )
	
		case "Save":
			NMConfigSaveCall( "All" )
			return 0
			
		case "Open":
			return NMConfigOpen( "" )
			
		case "Reset":
		
			configs = NMVarGet( "ConfigsDisplay" )
			
			if ( configs == 2 )
				NMConfigResetCall( "NeuroMatic" )
			else
				NMConfigResetCall( CurrentNMTabName() )
			endif
			
			NMConfigsListBoxWavesUpdate( "" )
			
			return 0
	
	endswitch
	
End // NMConfigsButton

//****************************************************************
//****************************************************************

Function NMConfigsDisplay( on )
	Variable on // ( 0 ) off ( 1 ) tab configs on ( 2 ) NM configs on
	
	String tabName = CurrentNMTabName()
	String tabList = NMTabControlList()
	Variable tabNum = TabNumber( tabName, tabList )
	
	if ( on == 1 )
		EnableTab( tabNum, tabList, 0 ) // disable
		ExecuteUserTabEnable( tabName, 0 )
		Execute /Z "NM" + tabName + "ConfigEdit()" // extra tab function, may not exist
	elseif ( on == 2 )
		EnableTab( tabNum, tabList, 0 ) // disable
		ExecuteUserTabEnable( tabName, 0 )
	endif
	
	SetNMvar( NMDF+"ConfigsDisplay", on )
	
	if ( on == 0 )
		if ( NMConfigsAutoOpenSave )
			NMConfigsSaveToPackages()
		endif
	else
		NMConfigsListBoxWavesUpdate( "" )
	endif
	
	UpdateNMPanel( 1 )
	
End // NMConfigsDispaly

//****************************************************************
//****************************************************************

Function NMConfigsTabEdit( configName [ history ] )
	String configName
	Variable history
	
	Variable tab, extraTab
	String cntrlName, vlist = ""
	
	String tabList = NMTabControlList()
	
	if ( history )
		vlist = NMCmdStr( configName, vlist )
		NMCommandHistory( vlist )
	endif
	
	if ( WinType( NMPanelName ) == 0 )
		MakeNMPanel()
	endif
	
	if ( StringMatch( configName, "NeuroMatic" ) == 1 )
		
		NMSet( configsDisplay = 1, history = 1 )
		
		extraTab = NMTabsExtraNum()
		
		cntrlName = NMTabControlName()
		
		TabControl $cntrlName, win=$NMPanelName, value=( extraTab )
		
		NMTabControl( cntrlName, extraTab )
		
		return 0
		
	endif
	
	tab = TabNumber( configName, tabList )
	
	if ( tab < 0 )
		return -1
	endif
	
	NMTab( configName )
	
	NMSet( configsDisplay = 1, history = 1 )
	
	return 0
	
End // NMConfigsTabEdit

//****************************************************************
//****************************************************************

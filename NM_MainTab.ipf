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
//	Main Tab Functions
//
//	Set and Get functions:
//		
//		NMConfigVarSet( "Main" , varName, value )
//		NMConfigStrSet( "Main", strVarName, strValue )
//		NMMainVarGet( varName )
//		NMMainStrGet( strVarName )
//
//****************************************************************
//****************************************************************
//
//	Input Parameter Defintions:
//
//		String folderList // NM folder list ( e.g. "nmFolder0;nmFolder1;" or "All" )
//		String wavePrefixList // wave prefix list ( e.g. "Record;Wave;" or "All" )
//		String chanSelectList // channel select list ( e.g. "A;B;" or "All" )
//		String waveSelectList // wave select list ( e.g. "All" or "Set1;Set2;" or "All Sets" or "All Groups" )
//		Variable history // print function command to history
//		Variable deprecation // print deprecation alert
//
//		String folder // e.g. "nmFolder0"
//		String wavePrefix // wave prefix ( e.g. "Record" or "Avg_" )
//		Variable chanNum // channel number ( e.g. 0, 1, 2... )
//		String waveSelect // wave select ( e.g. "All" or "Set1" or "Group1" )
//
//		Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
//
//****************************************************************
//****************************************************************

StrConstant NMMainDF = "root:Packages:NeuroMatic:Main:"

StrConstant NMMainDisplayList = "Display;---;Graph;Table;XLabel;YLabel;Print Notes;Print Names;Print Missing Seq #;"
StrConstant NMMainEditList = "Edit;---;Make;Move;Copy;Save;Kill;---;Concatenate;2D Wave;Split;---;Redimension;Delete Points;Insert Points;---;Rename;Renumber;---;Add Note;Clear Notes;"
StrConstant NMMainXScaleList = "X-scale;---;Align;StartX;DeltaX;XLabel;Xwave;Make Xwave;---;Resample;Decimate;Interpolate;---;Continuous;Episodic;---;sec;msec;usec;"
StrConstant NMMainOperationsList = "Operations;---;Baseline;dF/Fo;Normalize;Scale By Num;Scale By Wave;Rescale;Smooth;FilterFIR;FilterIIR;Rs Correction;Add Noise;Reverse;Rotate;Sort;Integrate;Differentiate;FFT;Replace Value;Delete NANs;Clip Events;"
StrConstant NMMainFunctionList = "Functions;---;Wave Stats;Average;Sum;SumSqrs;Histogram;Inequality <>=;"
Static StrConstant NMInterpolateAlgList = "linear;cubic spline;smoothing spline;"

Static StrConstant NMNewPrefix = "C_"
StrConstant NMAvgColor = "52224,0,0"
StrConstant NMAvgDataColor = "34816,34816,34816"
StrConstant NMErrorColor = "0,12800,52224"

//****************************************************************
//****************************************************************

Menu "NeuroMatic"

	Submenu StrVarOrDefault( NMDF + "NMMenuShortcuts" , "\\M1(Keyboard Shortcuts" )
		StrVarOrDefault( NMDF + "NMMenuShortcutMain0" , "" )
		StrVarOrDefault( NMDF + "NMMenuShortcutMain1" , "" ), /Q, NMMainCall( "Graph", "" )
		StrVarOrDefault( NMDF + "NMMenuShortcutMain2" , "" ), /Q, NMMainCall( "Table", "" )
		StrVarOrDefault( NMDF + "NMMenuShortcutMain3" , "" ), /Q, NMMainCall( "Copy", "" )
		StrVarOrDefault( NMDF + "NMMenuShortcutMain4" , "" ), /Q, NMMainCall( "Average", "" )
	End
	
End // NeuroMatic menu

//****************************************************************
//****************************************************************

Function NMMenuBuildMain()

	if ( NMVarGet( "NMOn" ) && StringMatch( CurrentNMTabName(), "Main" ) )
		SetNMstr( NMDF + "NMMenuShortcutMain0", "-" )
		SetNMstr( NMDF + "NMMenuShortcutMain1", "Graph/4" )
		SetNMstr( NMDF + "NMMenuShortcutMain2", "Table/5" )
		SetNMstr( NMDF + "NMMenuShortcutMain3", "Copy/6" )
		SetNMstr( NMDF + "NMMenuShortcutMain4", "Average/7" )
	else
		SetNMstr( NMDF + "NMMenuShortcutMain0", "" )
		SetNMstr( NMDF + "NMMenuShortcutMain1", "" )
		SetNMstr( NMDF + "NMMenuShortcutMain2", "" )
		SetNMstr( NMDF + "NMMenuShortcutMain3", "" )
		SetNMstr( NMDF + "NMMenuShortcutMain4", "" )
	endif

End // NMMenuBuildMain

//****************************************************************
//****************************************************************

Function /S NMTabPrefix_Main()

	return "MN_"

End // NMTabPrefix_Main

//****************************************************************
//****************************************************************

Function MainTab( enable )
	Variable enable // ( 0 ) disable ( 1 ) enable tab
	
	if ( enable )
		CheckNMPackage( "Main", 1 ) // declare folder/globals if necessary
		NMMainTabMake()
		NMMainTabUpdate()
		NMChannelGraphDisable( channel=-2, all=0 )
	endif

End // MainTab

//****************************************************************
//****************************************************************

Function MainTabKill( what )
	String what
	
	strswitch( what )
	
		case "waves":
			//KillGlobals( GetDataFolder( 1 ), "Avg*", "001" )
			//KillGlobals( GetDataFolder( 1 ), "Sum*", "001" )
			return 0
			
		case "folder":
			if ( DataFolderExists( NMMainDF ) )
				KillDataFolder $NMMainDF
			endif
			return 0
			
	endswitch
	
	return -1

End // MainTabKill

//****************************************************************
//****************************************************************

Function NMMainVarGet( varName )
	String varName
	
	Variable defaultVal = NaN
	
	strswitch( varName )
	
		case "OverwriteMode":
			defaultVal = 1
			break
	
		case "Bsln_Method":
			defaultVal = 1
			break
			
		case "Bsln_Bgn":
			defaultVal = NMBaselineXbgn
			break
		
		case "Bsln_End":
			defaultVal = NMBaselineXend
			break
		
		case "WaveDetailsOn":
			defaultVal = 1
			break
			
		default:
			NMDoAlert( "NMMainVar Error : no variable called " + NMQuotes( varName ) )
			return NaN
	
	endswitch
	
	return NumVarOrDefault( NMMainDF + varName, defaultVal )
	
End // NMMainVarGet

//****************************************************************
//****************************************************************

Function /S NMMainStrGet( strVarName )
	String strVarName
	
	String defaultStr = ""
	
	strswitch( strVarName )
	
		case "PlotColor":
		case "GraphColor":
			defaultStr = "rainbow"
			break
			
		default:
			NMDoAlert( "NMMainStr Error : no variable called " + NMQuotes( strVarName ) )
			return ""
	
	endswitch
	
	return StrVarOrDefault( NMMainDF + strVarName, defaultStr )
			
End // NMMainStrGet

//****************************************************************
//****************************************************************

Function NMWaveDetailsOnCall( on )
	Variable on // ( 0 ) no ( 1 ) yes
	
	NMCmdHistory( "NMWaveDetailsOn", NMCmdNum( on,"", integer=1 ) )
	
	return NMWaveDetailsOn( on )
	
End // NMWaveDetailsOnCall

//****************************************************************
//****************************************************************

Function NMWaveDetailsOn( on )
	Variable on // ( 0 ) no ( 1 ) yes
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	on = BinaryCheck( on )
	
	SetNMvar( NMMainDF + "WaveDetailsOn", on )
	
	NMMainTabUpdate()
	
	return on
	
End // NMWaveDetailsOn

//****************************************************************
//****************************************************************

Function NMMainConfigs()
	
	NMMainConfigVar( "OverwriteMode", "overwrite existing waves, tables and graphs if their is a name conflict", "boolean" )
	NMMainConfigVar( "WaveDetailsOn", "compute/display deltax and x-y labels for currently selected wave prefix", "boolean" )

	NMMainConfigVar( "Bsln_Method", "baseline subtraction method", " ;subtract wave's individual mean;subtract mean of all waves;" )
	NMMainConfigVar( "Bsln_Bgn", "x-axis baseline window begin", "" )
	NMMainConfigVar( "Bsln_End", "x-axis baseline window end", "" )
	
End // NMMainConfig

//****************************************************************
//****************************************************************

Function NMMainConfigVar( varName, description, type )
	String varName
	String description
	String type
	
	return NMConfigVar( "Main", varName, NMMainVarGet( varName ), description, type )
	
End // NMMainConfigVar

//****************************************************************
//****************************************************************

Function NMMainConfigStr( strVarName, description, type )
	String strVarName
	String description
	String type
	
	return NMConfigStr( "Main", strVarName, NMMainStrGet( strVarName ), description, type )
	
End // NMMainConfigStr

//****************************************************************
//****************************************************************
//
//		Tab Control Functions
//
//****************************************************************
//****************************************************************

Function NMMainTabMake() // create Main tab controls

	Variable x0 = 40, xinc = 120, y0, yinc = 35, fs = NMPanelFsize
	String blankStr
	
	y0 = NMPanelTabY + 35

	ControlInfo /W=$NMPanelName MN_Graph
	
	CheckNMstr( NMMainDF + "XAxisStart", "" )
	CheckNMstr( NMMainDF + "XAxisDX", "" )
	CheckNMstr( NMMainDF + "XAxisLabel", "" )
	CheckNMstr( NMMainDF + "YAxisLabel0", "" )
	CheckNMstr( NMMainDF + "YAxisLabel1", "" )
	
	if ( V_Flag != 0 ) 
		return 0 // main tab controls already exist
	endif
	
	DoWindow /F $NMPanelName // bring NMPanel to front
	
	Button MN_Graph, pos={x0,y0}, title="Graph", size={100,20}, proc=NMMainButton, fsize=fs, win=$NMPanelName
	Button MN_Copy, pos={x0+xinc,y0}, title="Copy", size={100,20}, proc=NMMainButton, fsize=fs, win=$NMPanelName
	
	Button MN_Baseline, pos={x0,y0+1*yinc}, title="Baseline", size={100,20}, proc=NMMainButton, fsize=fs, win=$NMPanelName
	Button MN_Average, pos={x0+xinc,y0+1*yinc}, title="Average", size={100,20}, proc=NMMainButton, fsize=fs, win=$NMPanelName
	
	Button MN_Scale, pos={x0,y0+2*yinc}, title="Scale x/+-=", size={100,20}, proc=NMMainButton, fsize=fs, win=$NMPanelName
	Button MN_WaveStats, pos={x0+xinc,y0+2*yinc}, title="Wave Stats", size={100,20}, proc=NMMainButton, fsize=fs, win=$NMPanelName
	
	y0 += 135
	
	GroupBox MN_More, title="More...", pos={x0-20,y0-30}, size={260,135}, fsize=fs, win=$NMPanelName
	
	PopupMenu MN_EditMenu, pos={x0+100,y0+0*yinc}, size={0,0}, bodyWidth=100, fsize=fs, win=$NMPanelName
	PopupMenu MN_EditMenu, value=NMMainEditList, proc=NMMainPopup, win=$NMPanelName
	
	PopupMenu MN_DisplayMenu, pos={x0+100+xinc,y0+0*yinc}, size={0,0}, bodyWidth=100, fsize=fs, win=$NMPanelName
	PopupMenu MN_DisplayMenu, value=NMMainDisplayList, proc=NMMainPopup, win=$NMPanelName
	
	PopupMenu MN_TScaleMenu, pos={x0+100,y0+1*yinc}, size={0,0}, bodyWidth=100, fsize=fs, win=$NMPanelName
	PopupMenu MN_TScaleMenu, value=NMMainXScaleList, proc=NMMainPopup, win=$NMPanelName
	
	PopupMenu MN_OpMenu, pos={x0+100+xinc,y0+1*yinc}, size={0,0}, bodyWidth=100, fsize=fs, win=$NMPanelName
	PopupMenu MN_OpMenu, value=NMMainOperationsList, proc=NMMainPopup, win=$NMPanelName
	
	PopupMenu MN_FxnMenu, pos={x0+100+xinc/2,y0+2*yinc}, size={0,0}, bodyWidth=100, fsize=fs, win=$NMPanelName
	PopupMenu MN_FxnMenu, value=NMMainFunctionList, proc=NMMainPopup, win=$NMPanelName
	
	y0 += 145
	
	blankStr = "                                                                           "
	GroupBox MN_WaveDetails, title=blankStr, pos={x0-20,y0-22}, size={260,140}, fsize=fs, win=$NMPanelName
	
	CheckBox MN_WaveDetailsOn, title="Wave Details", pos={x0,y0-22}, size={16,18}, value=NMMainVarGet( "WaveDetailsOn" ), win=$NMPanelName
	CheckBox MN_WaveDetailsOn, fsize=fs, proc=NMMainCheckBox, win=$NMPanelName
	
	yinc = 23
	
	SetVariable MN_StartX, title="x-axis start ", pos={x0,y0+0*yinc}, limits={-inf,inf,1}, size={220,20}, frame=1, value=$( NMMainDF + "XAxisStart" ), proc=NMMainSetVariable, fsize=fs, win=$NMPanelName
	SetVariable MN_DeltaX, title="x-axis delta ", pos={x0,y0+1*yinc}, limits={-inf,inf,1}, size={220,20}, frame=1, value=$( NMMainDF + "XAxisDX" ), proc=NMMainSetVariable, fsize=fs, win=$NMPanelName
	SetVariable MN_XLabel, title="x-axis label ", pos={x0,y0+2*yinc}, limits={-inf,inf,1}, size={220,20}, frame=1, value=$( NMMainDF + "XAxisLabel" ), proc=NMMainSetVariable, fsize=fs, win=$NMPanelName
	SetVariable MN_YLabel0, title="y-axis label A ", pos={x0,y0+3*yinc}, limits={-inf,inf,1}, size={220,20}, frame=1, value=$( NMMainDF + "YAxisLabel0" ), proc=NMMainSetVariable, fsize=fs, win=$NMPanelName
	SetVariable MN_YLabel1, title="y-axis label B ", pos={x0,y0+4*yinc}, limits={-inf,inf,1}, size={220,20}, frame=1, value=$( NMMainDF + "YAxisLabel1" ), proc=NMMainSetVariable, fsize=fs, win=$NMPanelName
	
End // NMMainTabMake

//****************************************************************
//****************************************************************

Function NMMainTabUpdate()

	Variable icnt, startx, dx
	String txtStr, labelList, xWave, xWavePrefix
	
	STRUCT NMRGB c
	
	Variable numChannels = NMNumChannels()
	
	Variable detailsOn = NMMainVarGet( "WaveDetailsOn" )
	
	String currentPrefix = CurrentNMWavePrefix()
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( ( strlen( currentPrefix ) == 0 ) || ( numChannels <= 0 ) )
	
		KillVariables /Z $prefixFolder+"WaveStartX"
		KillVariables /Z $prefixFolder+"WaveDeltaX"
	
		SetNMstr( NMMainDF + "XAxisStart", "" )
		SetNMstr( NMMainDF + "XAxisDX", "" )
		SetNMstr( NMMainDF + "XAxisLabel", "" )
		SetNMstr( NMMainDF + "YAxisLabel0", "" )
		SetNMstr( NMMainDF + "YAxisLabel1", "" )
	
		GroupBox MN_WaveDetails, win=$NMPanelName, disable=1
		CheckBox MN_WaveDetailsOn, win=$NMPanelName, disable=1, title="No Waves"
		SetVariable MN_StartX, win=$NMPanelName, disable=1, valueColor=( 0, 0, 0 )
		SetVariable MN_DeltaX, win=$NMPanelName, disable=1, title="x-axis delta ", valueColor=( 0, 0, 0 )
		SetVariable MN_XLabel, win=$NMPanelName, disable=1
		SetVariable MN_YLabel0, win=$NMPanelName, disable=1
		SetVariable MN_YLabel1, win=$NMPanelName, disable=1
		
	elseif ( !detailsOn )
	
		KillVariables /Z $prefixFolder+"WaveStartX"
		KillVariables /Z $prefixFolder+"WaveDeltaX"
	
		SetNMstr( NMMainDF + "XAxisStart", "" )
		SetNMstr( NMMainDF + "XAxisDX", "" )
		SetNMstr( NMMainDF + "XAxisLabel", "" )
		SetNMstr( NMMainDF + "YAxisLabel0", "" )
		SetNMstr( NMMainDF + "YAxisLabel1", "" )
	
		GroupBox MN_WaveDetails, win=$NMPanelName, disable=1
		CheckBox MN_WaveDetailsOn, win=$NMPanelName, disable=0, value=detailsOn, title="Wave Details"
		SetVariable MN_StartX, win=$NMPanelName, disable=1, valueColor=( 0, 0, 0 )
		SetVariable MN_DeltaX, win=$NMPanelName, disable=1, title="x-axis delta ", valueColor=( 0, 0, 0 )
		SetVariable MN_XLabel, win=$NMPanelName, disable=1
		SetVariable MN_YLabel0, win=$NMPanelName, disable=1
		SetVariable MN_YLabel1, win=$NMPanelName, disable=1
	
	else
	
		GroupBox MN_WaveDetails, win=$NMPanelName, disable=0
		CheckBox MN_WaveDetailsOn, win=$NMPanelName, value=detailsOn, title="Wave Details ( " + currentPrefix + " : All )"
		
		startx = NMChanStartX( 0, 1 )
		
		if ( numtype( startx ) == 0 )
			txtStr = num2str( startx )
			c.r = 0
			c.g = 0
			c.b = 0
		else
			txtStr = "multiple"
			NMColorList2RGB( NMRedStr, c )
		endif
		
		SetNMstr( NMMainDF + "XAxisStart", txtStr )
		
		xWave = NMXwave( waveNum = 0 )
		
		if ( strlen( xWave ) > 0 )
		
			KillVariables /Z $prefixFolder+"WaveStartX"
			KillVariables /Z $prefixFolder+"WaveDeltaX"
			
			xWavePrefix = StrVarOrDefault( prefixFolder + "XwavePrefix", "" )
			
			if ( strlen( xWavePrefix ) > 0 )
				SetNMstr( NMMainDF + "XAxisDX", xWavePrefix )
				SetVariable MN_DeltaX, win=$NMPanelName, title="x-axis prefix ", disable=0, valueColor=( 0, 0, 0 )
			else
				SetNMstr( NMMainDF + "XAxisDX", xwave )
				SetVariable MN_DeltaX, win=$NMPanelName, title="x-axis wave ", disable=0, valueColor=( 0, 0, 0 )
			endif
		
			SetVariable MN_StartX, win=$NMPanelName, disable=2, valueColor=( 0, 0, 0 )
		
		else
			
			SetVariable MN_StartX, win=$NMPanelName, disable=0, valueColor=(c.r,c.g,c.b)
			
			dx = NMChanDeltaX( 0, 0 )
	
			if ( numtype( dx ) == 0 )
			
				txtStr = num2str( dx )
				
				if ( dx == 1 )
					NMColorList2RGB( NMRedStr, c )
				else
					c.r = 0
					c.g = 0
					c.b = 0
				endif
				
			else
			
				txtStr = "multiple"
				NMColorList2RGB( NMRedStr, c )
				
			endif
			
			SetNMstr( NMMainDF + "XAxisDX", txtStr )
			
			SetVariable MN_DeltaX, win=$NMPanelName, title="x-axis delta ", disable=0, valueColor=(c.r,c.g,c.b )
		
		endif
		
		txtStr = NMChanLabelXAll()
		
		SetNMstr( NMMainDF + "XAxisLabel", txtStr )
		
		SetVariable MN_XLabel, win=$NMPanelName, disable=0, valueColor=( 0, 0, 0 )
		
		if ( numChannels > 0 )
		
			txtStr = NMChanLabelY( channel = 0 )
			
			SetNMstr( NMMainDF + "YAxisLabel0", txtStr )
			
		else
		
			SetNMstr( NMMainDF + "YAxisLabel0", "" )
			
		endif
		
		SetVariable MN_YLabel0, win=$NMPanelName, disable=0
		
		if ( numChannels > 1 )
		
			txtStr = NMChanLabelY( channel = 1 )
		
			SetNMstr( NMMainDF + "YAxisLabel1", txtStr )
			
			SetVariable MN_YLabel1, win=$NMPanelName, disable=0
			
		else
		
			SetNMstr( NMMainDF + "YAxisLabel1", "" )
			
			SetVariable MN_YLabel1, win=$NMPanelName, disable=2
			
		endif
	
	endif

End // NMMainTabUpdate

//****************************************************************
//****************************************************************

Function NMMainPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	PopupMenu $ctrlName, win=$NMPanelName, mode=1 // force menus back to title
	
	strswitch( popStr )
		case "Display":
		case "X-scale":
		case "Edit":
		case "Operations":
		case "Functions":
		case "---":
			break
		default:
			NMMainCall( popStr, "" )
	endswitch
	
End // NMMainPopup

//****************************************************************
//****************************************************************

Function NMMainButton( ctrlName ) : ButtonControl
	String ctrlName
	
	ctrlName = ReplaceString( "MN_", ctrlName, "" )
	
	NMMainCall( ctrlName, "" )

End // NMMainButton

//****************************************************************
//****************************************************************

Function NMMainSetVariable( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	ctrlName = ReplaceString( "MN_", ctrlName, "" )
	
	NMMainCall( ctrlName, varStr )

End // NMMainSetVariable

//****************************************************************
//****************************************************************

Function NMMainCheckBox(ctrlName, checked) : CheckBoxControl
	String ctrlName; Variable checked
	
	ctrlName = ReplaceString( "MN_", ctrlName, "" )
	
	NMMainCall( ctrlName, num2istr( checked ) )

End // NMMainCheckBox

//****************************************************************
//****************************************************************

Function /S NMMainCall( fxn, varStr [ deprecation ] )
	String fxn, varStr
	Variable deprecation
	
	Variable varNum
	String promptStr, returnStr = ""
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( !StringMatch( fxn, "Make" ) && NMExecutionAlert() )
		return ""
	endif
	
	if ( !CheckCurrentFolder() )
		return ""
	endif
	
	strswitch( fxn )
	
		// Display Functions
			
		case "Plot":
		case "Graph":
			returnStr = zCall_NMMainGraph()
			break
			
		case "Edit":
		case "Table":
			returnStr = zCall_NMMainTable()
			break
		
		case "Names":
		case "List Names":
		case "Print Names":
			returnStr = zCall_NMMainWaveList()
			break
		
		case "Notes":
		case "Print Notes":
		case "Wave Notes":
			returnStr = zCall_NMMainWaveNotesPrint()
			break
			
		case "Print Missing Seq #":
			returnStr = zCall_NMMainFindMissingSeqNums()
			break
			
		case "XLabel":
		
			if ( strlen( varStr ) > 0 )
				NMChanXLabelSetAll( varStr, history = 1 )
			else
				returnStr = zCall_NMMainLabelX()
			endif
			
			break
			
		case "YLabel":
			returnStr = zCall_NMMainLabelY()
			break
			
		case "YLabel0":
			NMChanLabelSetCall( 0, "y", varStr )
			break
			
		case "YLabel1":
			NMChanLabelSetCall( 1, "y", varStr )
			break
		
		// Edit Functions
		
		case "Make":
			returnStr = zCall_NMMainMake()
			break
			
		case "Move":
			returnStr = zCall_NMMainMove()
			break
			
		case "Copy":
		case "Copy To":
			returnStr = zCall_NMMainDuplicate()
			break
			
		case "Concat":
		case "Concatenate":
			returnStr = zCall_NMMainConcatenate( 1 )
			break
			
		case "2D Wave":
		case "2D Matrix":
			returnStr = zCall_NMMainConcatenate( 2 )
			break
			
		case "Split":
			returnStr = zCall_NMMainSplit()
			break
			
		case "Rename":
			promptStr = NMPromptStr( "Rename Waves" )
			returnStr = NMRenameWavesCall( "Selected", promptStr = promptStr )
			break
			
		case "Renumber":
			returnStr = zCall_NMMainRenumber()
			break
			
		case "Save":
			returnStr = zCall_NMMainSave()
			break
			
		case "Kill":
		case "Delete":
			returnStr = zCall_NMMainKillWaves()
			break
		
		case "Add Note":
			returnStr = zCall_NMMainWaveNotesAdd()
			break
			
		case "Clear Notes":
			returnStr = zCall_NMMainWaveNotesClear()
			break
			
		// X-scale Functions
		
		case "Align":
		case "XAlign":
			returnStr = NMScalePanel( align = 1 )
			break
			
		case "StartX":
		
			if ( strlen( varStr ) > 0 )
			
				if ( strlen( NMXwave( waveNum = 0 ) ) > 0 )
					returnStr = NMXwaveSetCall()
				else
					varNum = str2num( varStr )
					returnStr = NMMainSetScale( start = varNum, history = 1 )
				endif
				
			else
			
				returnStr = zCall_NMMainStartX()
				
			endif
			
			break
		
		case "Delta":
		case "DeltaX":
		
			if ( strlen( varStr ) > 0 )
			
				if ( strlen( NMXwave( waveNum = 0 ) ) > 0 )
					returnStr = NMXwaveSetCall()
				else
					returnStr = NMDeltaXAllCall( str2num( varStr ) )
				endif
				
			else
			
				returnStr = zCall_NMMainDeltaX()
				
			endif
			
			break
			
		case "Xwave":
			returnStr = NMXwaveSetCall()
			break
			
		case "Make Xwave":
			returnStr = zCall_NMMainXWaveMake()
			break
			
		case "Resample":
			returnStr = zCall_NMMainResample()
			break
		
		case "Decimate":
			//returnStr = zCall_NMMainDecimate()
			returnStr = zCall_NMMainDecimate2()
			break
			
		case "Interpolate":
			returnStr = zCall_NMMainInterpolate()
			break
			
		case "Redimension":
			returnStr = zCall_NMMainRedimension()
			break
			
		case "Delete Points":
			returnStr = zCall_NMMainDeletePoints()
			break
			
		case "Insert Points":
			returnStr = zCall_NMMainInsertPoints()
			break
			
		case "Continuous":
		case "Episodic":
			returnStr = zCall_NMMainXScaleMode( fxn )
			break
			
		case "sec":
		case "msec":
		case "usec":
			returnStr = zCall_NMMainTimeScaleConvert( fxn )
			break
			
		// Operations
		
		case "Baseline":
			returnStr = zCall_NMMainBaseline()
			break
		
		case "Scale":
			returnStr = NMScalePanel()
			break
		
		case "Scale By Num":
		case "Scale By Number":
			returnStr = NMScalePanel( mode = "value" )
			break
			
		case "Scale By Wave":
			returnStr = NMScalePanel( mode = "wave of values" )
			break
			
		case "Rescale":
			returnStr = zCall_NMMainRescale()
			break
			
		case "Normalize":
			returnStr = zCall_NMMainNormalize()
			break
		
		case "DFOF":
		case "dF/Fo":
			returnStr = zCall_NMMainBaseline( DFOF = 1 )
			break
			
		case "Blank":
		case "Blank Events":
		case "Clip Events":
			returnStr = zCall_NMMainClipEvents()
			break
			
		case "d/dt":
		case "Differentiate":
			returnStr = zCall_NMMainDIfferentiate()
			break
			
		case "integral":
		case "Integrate":
			returnStr = zCall_NMMainIntegrate()
			break
			
		case "FFT":
			returnStr = zCall_NMMainFFT()
			break
			
		case "Smooth":
			returnStr = zCall_NMMainSmooth()
			break
			
		case "FilterFIR":
			returnStr = zCall_NMMainFilterFIR()
			break
			
		case "FilterIIR":
			returnStr = zCall_NMMainFilterIIR()
			break
			
		case "Rs Correction":
			returnStr = zCall_NMMainRsCorrection()
			break
			
		case "Add Noise":
			returnStr = zCall_NMMainAddNoise()
			break
			
		case "Replace Value":
			returnStr = zCall_NMMainReplaceValue()
			break
			
		case "Delete NANs":
			returnStr = zCall_NMMainDeleteNaNs()
			break
			
		case "Rotate":
			returnStr = zCall_NMMainRotate()
			break
			
		case "Reverse":
			returnStr = zCall_NMMainReverse()
			break
			
		case "Sort":
			returnStr = zCall_NMMainSort()
			break
			
		// Misc Functions
		
		case "WaveStats":
		case "Wave Stats":
			returnStr = zCall_NMMainWaveStats()
			break
			
		case "Average":
			returnStr = zCall_NMMainMatrixStats( "Average" )
			break
			
		case "Sum":
			returnStr = zCall_NMMainMatrixStats( "Sum" )
			break
			
		case "SumSqrs":
			returnStr = zCall_NMMainMatrixStats( "SumSqrs" )
			break
		
		case "Inequality":
		case "Inequality <>=":
			returnStr = zCall_NMMainInequality()
			break
			
		case "Histogram":
			returnStr = zCall_NMMainHistogram()
			break
			
		case "IV":
			returnStr = NMIVCall()
			break
			
		// Wave Details
		
		case "WaveDetailsOn":
			NMWaveDetailsOnCall( str2num( varStr ) )
			break
			
		default:
			NMDoAlert( "NMMainCall: unrecognized function call: " + fxn )

	endswitch
	
	NMProgressKill()
	
	//if ( ItemsInList( outList ) == 0 )
		//NMDoAlert( "Alert: no waves passed through " + NMQuotes( fxn ) + " function."
	//endif
	
	return returnStr
	
End // NMMainCall

//****************************************************************
//****************************************************************
//
//		Edit Functions
//		Make, Move, Duplicate, Rename, Renumber...
//
//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainMake()

	Variable icnt, ccnt, found, overwrite, noiseStdv = 1
	String wavePrefix2, returnList, wList, chanList = "", promptStr = "Make Waves"

	String wavePrefix = StrVarOrDefault( NMMainDF + "MakePrefix", NMStrGet( "WavePrefix" ) )
	
	Variable numChannels = NumVarOrDefault( NMMainDF + "MakeNumChannels", 1 )
	Variable numWaves = NumVarOrDefault( NMMainDF + "MakeNumWaves", 10 )
	Variable dimensions = NumVarOrDefault( NMMainDF + "MakeDimensions", 1 )
	
	Variable xLength = NumVarOrDefault( NMMainDF + "MakeXLength", 100 )
	Variable xpnts = NumVarOrDefault( NMMainDF + "MakeXpnts", 100 )
	Variable dx = NumVarOrDefault( NMMainDF + "MakeDX", 1 )
	Variable ypnts = NumVarOrDefault( NMMainDF + "MakeYpnts", 100 )
	Variable dy = NumVarOrDefault( NMMainDF + "MakeDY", 1 )
	
	String fillWith = StrVarOrDefault( NMMainDF + "MakeFillWith", "NaN's" )
	String xLabel = StrVarOrDefault( NMMainDF + "MakeLabelX", NMXunits )
	String yLabel = StrVarOrDefault( NMMainDF + "MakeLabelY", "" )
	Variable selectNewPrefix = 1 + NumVarOrDefault( NMMainDF + "MakeSelectPrefix", 1 )
	
	wList = WaveList( wavePrefix + "*", ";", "" )
	
	if ( 0 && ItemsInList( wList ) > 0 )
	
		for ( icnt = 0 ; icnt <= 25 ; icnt += 1 )
		
			wavePrefix2 = ChanNum2Char( icnt ) + "_" + wavePrefix
			wList = WaveList( wavePrefix2 + "*", ";", "" )
			
			if ( ItemsInList( wList ) == 0 )
				found = 1
				break
			endif
			
		endfor
		
		if ( found )
			wavePrefix = wavePrefix2
		endif
	
	endif
	
	Prompt wavePrefix, "prefix name of new output waves:"
	Prompt numChannels, "number of channels:"
	Prompt numWaves, "waves per channel:"
	Prompt dimensions, "wave dimensions:", popup "1 ( e.g. time series );2 ( e.g. image );"
	
	Prompt xLength, "wave length:" // x-axis
	Prompt xpnts, "number of x-axis points:"
	Prompt dx, "x-axis delta:"
	Prompt ypnts, "number of y-axis points:"
	Prompt dy, "y-axis delta:"
	
	Prompt xLabel, "x-axis label:"
	Prompt yLabel, "y-axis label:"
	Prompt fillWith, "fill waves with:", popup "0's;NaN's;Noise;"
	Prompt selectNewPrefix, "select as current waves?", popup "no;yes;"
	
	DoPrompt promptStr, wavePrefix, numChannels, numWaves, dimensions
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( strlen( wavePrefix ) == 0 )
		return ""
	endif
	
	if ( StringMatch( wavePrefix, "All" ) )
		DoAlert /T=( promptStr ) 0, "Abort: wavePrefix " + NMQuotes( "All" ) + " is not possible with this function."
		return ""
	endif
	
	if ( ( numtype( numChannels * numWaves ) > 0 ) || ( numChannels <= 0 ) || ( numWaves <= 0 ) )
		return ""
	endif
	
	SetNMstr( NMMainDF + "MakePrefix", wavePrefix )
	SetNMvar( NMMainDF + "MakeNumChannels", numChannels )
	SetNMvar( NMMainDF + "MakeNumWaves", numWaves )
	SetNMvar( NMMainDF + "MakeDimensions", dimensions )
	
	wList = WaveList( wavePrefix + "*", ";", "" )
	
	if ( ItemsInList( wList ) > 0 )
	
		DoAlert /T=( promptStr ) 1, "Alert: waves with prefix " + NMQuotes( wavePrefix ) + " already exist and may be overwritten. Do you want to continue?"
		
		if ( V_flag == 1 )
			overwrite = 1
		else
			return "" // cancel
		endif
	
	endif
	
	if ( dimensions == 2 )
	
		DoPrompt promptStr, xpnts, dx, ypnts, dy
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		if ( ( numtype( xpnts * dx  ) > 0 ) || ( xpnts <= 0 ) || ( dx <= 0 ) )
			return ""
		endif
		
		if ( ( numtype( ypnts * dy  ) > 0 ) || ( ypnts <= 0 ) || ( dy <= 0 ) )
			return ""
		endif
		
		SetNMvar( NMMainDF + "MakeXpnts", xpnts )
		SetNMvar( NMMainDF + "MakeDX", dx )
		SetNMvar( NMMainDF + "MakeYpnts", ypnts )
		SetNMvar( NMMainDF + "MakeDY", dy )
	
	else
	
		DoPrompt promptStr, xLength, dx
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		if ( ( numtype( xLength * dx  ) > 0 ) || ( xLength <= 0 ) || ( dx <= 0 ) )
			return ""
		endif
		
		xpnts = 1 + xLength / dx
		ypnts = 0
		dy = 1
		
		SetNMvar( NMMainDF + "MakeXLength", xLength )
		SetNMvar( NMMainDF + "MakeDX", dx )
	
	endif
	
	DoPrompt promptStr, xLabel, yLabel, fillWith, selectNewPrefix
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	selectNewPrefix -= 1
	
	SetNMstr( NMMainDF + "MakeLabelX", xLabel )
	SetNMstr( NMMainDF + "MakeLabelY", yLabel )
	SetNMStr( NMMainDF + "MakeFillWith", fillWith )
	SetNMvar( NMMainDF + "MakeSelectPrefix", selectNewPrefix )
	
	if ( numChannels == 1 )
		chanList = ChanNum2Char( ccnt )
	else
		for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
			chanList += ChanNum2Char( ccnt ) + ";"
		endfor
	endif
	
	if ( StringMatch( fillWith, "0's" ) )
	
		returnList = NMMainMake( wavePrefixList=wavePrefix, chanSelectList=chanList, numWaves=numWaves, xpnts=xpnts, dx=dx, ypnts=ypnts, dy=dy, value=0, overwrite=overwrite, xLabel=xLabel, yLabel=yLabel, history=1 )
	
	elseif ( StringMatch( fillWith, "NaN's" ) )
	
		returnList = NMMainMake( wavePrefixList=wavePrefix, chanSelectList=chanList, numWaves=numWaves, xpnts=xpnts, dx=dx, ypnts=ypnts, dy=dy, value=NaN, overwrite=overwrite, xLabel=xLabel, yLabel=yLabel, history=1 )
		
	elseif ( StringMatch( fillWith, "noise" ) )
	
		returnList = NMMainMake( wavePrefixList=wavePrefix, chanSelectList=chanList, numWaves=numWaves, xpnts=xpnts, dx=dx, ypnts=ypnts, dy=dy, noiseStdv=noiseStdv, overwrite=overwrite, xLabel=xLabel, yLabel=yLabel, history=1 )
	
	endif
	
	if ( ItemsInList( returnList ) == 0 )
		return ""
	endif
	
	if ( selectNewPrefix )
		NMPrefixSelect( wavePrefix, noPrompts=1 )
	else
		NMPrefixAdd( wavePrefix )
	endif
	
	return returnList

End // zCall_NMMainMake

//****************************************************************
//****************************************************************

Function /S NMMainMake( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, numWaves, waveLength, xpnts, dx, ypnts, dy, value, noiseStdv, precision, overwrite, xLabel, yLabel ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	Variable numWaves // number of waves to make
	Variable waveLength // xpnts * dx
	Variable xpnts, dx // x-axis
	Variable ypnts, dy // y-axis ( 2D waves )
	Variable value // value of data points ( default is NaN )
	Variable noiseStdv // standard deviation of Gaussian noise ( 0 ) for no noise
	Variable precision // ( 1 ) single, default ( 2 ) double
	Variable overwrite // overwrite output wave if it already exists ( 0 ) no ( 1 ) yes
	String xLabel, yLabel
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )

	String thisFxn = GetRTStackInfo( 1 )
	
	if ( !ParamIsDefault( numWaves ) )
		NMLoopExecVarAdd( "numWaves", numWaves, nm, integer=1 )
	endif
	
	if ( !ParamIsDefault( waveLength ) )
		NMLoopExecVarAdd( "waveLength", waveLength, nm )
	endif
	
	if ( !ParamIsDefault( xpnts ) )
		NMLoopExecVarAdd( "xpnts", xpnts, nm )
	endif
	
	if ( !ParamIsDefault( dx ) )
		NMLoopExecVarAdd( "dx", dx, nm )
	endif
	
	if ( !ParamIsDefault( ypnts ) )
		NMLoopExecVarAdd( "ypnts", ypnts, nm )
	endif
	
	if ( !ParamIsDefault( dy ) )
		NMLoopExecVarAdd( "dy", dy, nm )
	endif
	
	if ( !ParamIsDefault( value ) )
		NMLoopExecVarAdd( "value", value, nm )
	endif
	
	if ( !ParamIsDefault( noiseStdv ) && ( noiseStdv > 0 ) )
		NMLoopExecVarAdd( "noiseStdv", noiseStdv, nm )
	endif
	
	if ( !ParamIsDefault( precision ) )
		NMLoopExecVarAdd( "precision", precision, nm, integer=1 )
	endif
	
	if ( overwrite )
		NMLoopExecVarAdd( "overwrite", overwrite, nm, integer=1 )
	endif
	
	if ( !ParamIsDefault( xLabel ) && ( strlen( xLabel ) > 0 ) )
		NMLoopExecStrAdd( "xLabel", xLabel, nm )
	endif
	
	if ( !ParamIsDefault( yLabel ) && ( strlen( yLabel ) > 0 ) )
		NMLoopExecStrAdd( "yLabel", yLabel, nm )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( StringMatch( wavePrefixList, "All" ) )
		DoAlert /T=( thisFxn ) 0, "Abort: wavePrefixList " + NMQuotes( "All" ) + " is not possible with this function. Use " + thisFxn + "2 instead."
		return ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	waveSelectList = "All" // NOT USED
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	//nm.updateGraphs = 1
	//nm.updatePanel = 1
	nm.ignorePrefixFolder = 1
	
	nm.waveSelectList = "RemoveFromHistory"
	
	nm.wavePrefixList = AddListItem( "ForceHistory", nm.wavePrefixList, ";", inf )
	nm.chanSelectList = AddListItem( "ForceHistory", nm.chanSelectList, ";", inf )
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainMake

//****************************************************************
//****************************************************************

Function /S NMMainMake2( [ folder, wavePrefix, chanNum, waveSelect, numWaves, waveLength, xpnts, dx, ypnts, dy, value, noiseStdv, precision, overwrite, xLabel, yLabel ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	Variable numWaves // number of waves to make
	Variable waveLength // xpnts * dx
	Variable xpnts, dx // x-axis
	Variable ypnts, dy // y-axis ( 2D image )
	Variable value // value of data points ( default NaN )
	Variable noiseStdv // standard deviation of Gaussian noise ( 0 ) for no noise
	Variable precision // ( 1 ) single, default ( 2 ) double
	Variable overwrite // overwrite output wave if it already exists ( 0 ) no ( 1 ) yes
	String xLabel, yLabel
	
	if ( ParamIsDefault( numWaves ) )
		numWaves = 1
	endif
	
	if ( ParamIsDefault( dx ) )
		dx = 1	
	endif
	
	if ( ParamIsDefault( dy ) )
		dy = 1	
	endif
	
	if ( ParamIsDefault( waveLength ) )
		if ( ParamIsDefault( xpnts ) )
			xpnts = 10
		endif
	else
		xpnts = waveLength
	endif
	
	if ( ParamIsDefault( value ) )
		value = NaN
	endif
	
	if ( ParamIsDefault( precision ) )
		precision = 1
	elseif ( precision != 2 )
		precision = 1
	endif
	
	if ( NMMakeError( numWaves, xpnts ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( xLabel ) )
		xLabel = ""
	endif
	
	if ( ParamIsDefault( yLabel ) )
		yLabel = ""
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = CurrentNMFolder( 1 )
	endif
	
	folder = CheckNMFolderPath( folder )
	
	if ( !IsNMDataFolder( folder ) )
		return NM2ErrorStr( 30, "folder", folder )
	endif
	
	if ( ParamIsDefault( wavePrefix ) || ( strlen( wavePrefix ) == 0 ) )
		wavePrefix = NMStrGet( "WavePrefix" )
	endif
	
	if ( ( numtype( chanNum ) > 0 ) || ( chanNum < 0 ) )
		chanNum = 0
	endif
	
	STRUCT NMMakeStruct m
	
	m.numWaves = numWaves
	m.xpnts = xpnts
	m.dx = dx
	m.ypnts = ypnts
	m.dy = dy
	m.value = value
	m.noiseStdv = noiseStdv
	m.precision = precision
	m.overwrite = overwrite
	m.xLabel = xLabel
	m.yLabel = yLabel
	
	STRUCT NMParams nm
	NMParamsNull( nm )
	
	nm.fxn = "NMMake"
	nm.folder = folder
	nm.wavePrefix = wavePrefix
	nm.chanNum = chanNum
	nm.waveSelect = "All"
	
	return NMMake2( nm, m, history=1 )
	
End // NMMainMake2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainMove()

	String returnList, wList, txt, promptStr = NMPromptStr( "NM Move Waves" )
	
	String currentFolder = CurrentNMFolder( 0 )
	String currentWavePrefix = CurrentNMWavePrefix()
	String setsWaveList = NMSetsWaveListAll()
	String folderList = NMDataFolderList()
	
	String toFolder = StrVarOrDefault( NMMainDF + "MoveToFolder", "" )
	Variable copySets = 1 + NumVarOrDefault( NMMainDF + "MoveCopySets", 1 )
	Variable select = 1 + NumVarOrDefault( NMMainDF + "MoveSelect", 1 )
	
	folderList = RemoveFromList( currentFolder, folderList )
	
	if ( ItemsInList( folderList ) == 0 )
		DoAlert /T=( promptStr ) 0, "Cannot move waves: there are no other NM folders."
		return ""
	endif
	
	Prompt toFolder, "move selected waves to:", popup folderList
	Prompt copySets, "copy Sets and Groups?", popup "no;yes;"
	Prompt select, "select as current waves?", popup "no;yes;"
	
	if ( strlen( setsWaveList ) > 0 )
	
		DoPrompt promptStr, toFolder, copySets, select
	
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		copySets -= 1
		
		SetNMvar( NMMainDF + "MoveCopySets", copySets )
	
	else
	
		DoPrompt promptStr, toFolder, select
	
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		copySets = 0
	
	endif
	
	select -= 1
	
	SetNMstr( NMMainDF + "MoveToFolder", toFolder )
	SetNMvar( NMMainDF + "MoveSelect", select )
	
	wList = NMFolderWaveList( toFolder, currentWavePrefix + "*", ";", "", 0 )
	
	if ( ItemsInList( wList ) > 0 )
	
		txt = "Move Alert: waves with prefix " + NMQuotes( currentWavePrefix ) + " already exist in "
		txt += toFolder + ". Do you want to continue?"
		
		DoAlert /T=( promptStr ) 1, txt
		
		if ( V_flag != 1 )
			return "" // cancel
		endif
	
	endif
	
	returnList = NMMainMove( toFolder=toFolder, copySets=copySets, history=1 )
	
	if ( ItemsInList( returnList ) == 0 )
		return ""
	endif
	
	if ( select )
		NMFolderChange( toFolder )
		NMPrefixSelect( currentWavePrefix, noPrompts=1 )
	endif
	
	return returnList

End // zCall_NMMainMove

//****************************************************************
//****************************************************************

Function /S NMMainMove( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, toFolder, copySets ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	String toFolder // where to move selected waves
	Variable copySets // copy Sets and Groups ( 0 ) no ( 1 ) yes
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( toFolder ) || ( strlen( toFolder ) == 0 ) )
		return NM2ErrorStr( 21, "toFolder", "" )
	endif
	
	NMLoopExecStrAdd( "toFolder", toFolder, nm )
	
	toFolder = CheckNMFolderPath( toFolder )
	
	if ( !IsNMDataFolder( toFolder ) )
		return NM2ErrorStr( 30, "toFolder", toFolder )
	endif
	
	if ( copySets )
		NMLoopExecVarAdd( "copySets", copySets, nm, integer = 1 )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	//nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainMove

//****************************************************************
//****************************************************************

Function /S NMMainMove2( [ folder, wavePrefix, chanNum, waveSelect, toFolder, copySets ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	String toFolder // where to move selected waves
	Variable copySets // copy Sets and Groups ( 0 ) no ( 1 ) yes
	
	String fxn = "NMMove"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( toFolder ) || ( strlen( toFolder ) == 0 ) )
		return NM2ErrorStr( 21, "toFolder", "" )
	endif
	
	toFolder = CheckNMFolderPath( toFolder )
	
	if ( !IsNMDataFolder( toFolder ) )
		return NM2ErrorStr( 30, "toFolder", toFolder )
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = CurrentNMFolder( 1 )
	endif
	
	if ( StringMatch( folder, toFolder ) )
		return NM2ErrorStr( 33, "toFolder", toFolder )
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	return NMMove2( nm, toFolder, copySets=copySets, history=1 )
	
End // NMMainMove2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainDuplicate()
	
	Variable overwrite
	String returnList, wList, txt, promptStr = NMPromptStr( "NM Copy Waves" )
	
	String currentWavePrefix = CurrentNMWavePrefix()
	String setsWaveList = NMSetsWaveListAll()
	String folderList = NMDataFolderList()
	String stimList = NMFolderList( NMStimsDF, "NMStim" )
	
	if ( ( ItemsInList( folderList ) > 1 ) || ( ItemsInList( stimList ) > 1 ) )
		return zCall_NMMainDuplicateToFolder()
	endif
	
	String newPrefix = StrVarOrDefault( NMMainDF + "DuplicatePrefix", NMNewPrefix )
	Variable selectNewPrefix = 1 + NumVarOrDefault( NMMainDF + "DuplicateSelectPrefix", 1 )
	Variable xbgn = NumVarOrDefault( NMMainDF + "DuplicateXbgn", -inf )
	Variable xend = NumVarOrDefault( NMMainDF + "DuplicateXend", inf )
	Variable copySets = 1 + NumVarOrDefault( NMMainDF + "DuplicateSets", 1 )
	
	if ( strlen( newPrefix ) == 0 )
		newPrefix = NMNewPrefix
	endif
	
	Prompt xbgn, NMPromptAddUnitsX( "copy x-axis from" )
	Prompt xend, NMPromptAddUnitsX( "copy x-axis to" )
	Prompt copySets, "copy Sets and Groups?", popup "no;yes;"
	Prompt newPrefix, "prefix name for copied waves:"
	Prompt selectNewPrefix, "select copied waves?", popup "no;yes;"
	
	if ( strlen( setsWaveList ) > 0 )
	
		DoPrompt promptStr, xbgn, xend, copySets, newPrefix, selectNewPrefix
	
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		copySets -= 1
		
		SetNMvar( NMMainDF + "DuplicateSets", copySets )
	
	else
	
		DoPrompt promptStr, newPrefix, xbgn, xend, selectNewPrefix
	
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		copySets = 0
	
	endif
	
	selectNewPrefix -= 1
	
	SetNMvar( NMMainDF + "DuplicateXbgn", xbgn )
	SetNMvar( NMMainDF + "DuplicateXend", xend )
	SetNMvar( NMMainDF + "DuplicateSelectPrefix", selectNewPrefix )
	
	if ( strlen( newPrefix ) == 0 )
		DoAlert /T=( promptStr ) 0, "Abort: source and destination waves are the same."
		return "" // cancel
	endif
	
	SetNMstr( NMMainDF + "DuplicatePrefix", newPrefix )
	
	wList = WaveList( newPrefix + currentWavePrefix + "*", ";", "" )
	
	if ( ItemsInList( wList ) > 0 )
	
		txt = "Alert: waves with prefix " + NMQuotes( newPrefix + currentWavePrefix ) + " already exist and may be overwritten. Do you want to continue?"
		
		DoAlert /T=( promptStr ) 1, txt
		
		if ( V_flag == 1 )
			overwrite = 1
		else
			return "" // cancel
		endif
	
	endif
	
	returnList = NMMainDuplicate( xbgn=xbgn, xend=xend, newPrefix=newPrefix, overwrite=overwrite, copySets=copySets, history=1 )
	
	if ( ItemsInList( returnList ) == 0 )
		return ""
	endif
	
	if ( selectNewPrefix )
		NMPrefixSelect( newPrefix + currentWavePrefix, noPrompts=1 )
	else
		NMPrefixAdd( newPrefix + currentWavePrefix )
	endif
	
	return returnList
	
End // zCall_NMMainDuplicate

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainDuplicateToFolder()
	
	Variable overwrite, copyToStimFolder, toFolderNum
	String returnList, wList, txt, toFolderFP, allFolderList, dividerStr = "---"
	String promptStr = NMPromptStr( "NM Copy Waves" )
	
	String currentWavePrefix = CurrentNMWavePrefix()
	String setsWaveList = NMSetsWaveListAll()
	String folderList = NMDataFolderList()
	String stimList = NMFolderList( NMStimsDF, "NMStim" )
	
	Variable xbgn = NumVarOrDefault( NMMainDF + "DuplicateXbgn", -inf )
	Variable xend = NumVarOrDefault( NMMainDF + "DuplicateXend", inf )
	String toFolder = StrVarOrDefault( NMMainDF + "DuplicateToFolder", "This Folder" )
	Variable copySets = 1 + NumVarOrDefault( NMMainDF + "DuplicateSets", 1 )
	
	String newPrefix = StrVarOrDefault( NMMainDF + "DuplicatePrefix", "" )
	Variable selectNewPrefix = 1 + NumVarOrDefault( NMMainDF + "DuplicateSelectPrefix", 1 )
	
	folderList = RemoveFromList( GetDataFolder( 0 ), folderList )
	
	folderList = "This Folder;" + folderList
	
	allFolderList = folderList + dividerStr + ";" + stimList
	
	toFolderNum = WhichListItem( toFolder, allFolderList )
	
	if ( toFolderNum < 0 )
		toFolderNum = 1
	else
		toFolderNum += 1
	endif
	
	if ( strlen( newPrefix ) == 0 )
		newPrefix = NMNewPrefix
	endif
	
	Prompt xbgn, NMPromptAddUnitsX( "copy x-axis from" )
	Prompt xend, NMPromptAddUnitsX( "copy x-axis to" )
	Prompt toFolderNum, "copy selected waves to:", popup allFolderList
	Prompt copySets, "copy Sets and Groups?", popup "no;yes;"
	Prompt newPrefix, "prefix name for copied waves:"
	Prompt selectNewPrefix, "select copied waves?", popup "no;yes;"
	
	DoPrompt promptStr, xbgn, xend, toFolderNum
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	toFolderNum -= 1
	
	toFolder = StringFromList( toFolderNum, allFolderList )
	
	if ( StringMatch( toFolder, dividerStr ) )
		return "" // cancel
	endif
	
	if ( toFolderNum > ItemsInList( folderList ) )
		copyToStimFolder = 1
	endif
	
	SetNMvar( NMMainDF + "DuplicateXbgn", xbgn )
	SetNMvar( NMMainDF + "DuplicateXend", xend )
	
	if ( StringMatch( toFolder, "This Folder" ) )
	
		if ( strlen( newPrefix ) == 0 )
			newPrefix = NMNewPrefix
			Prompt newPrefix, "new prefix name for copied waves:"
		endif
		
		toFolderFP = GetDataFolder( 1 )
		
	else
	
		if ( copyToStimFolder )
			toFolderFP = "root:NMStims:" + toFolder + ":"
		else
			toFolderFP = "root:" + toFolder + ":"
		endif
	
		wList = NMFolderWaveList( toFolderFP, currentWavePrefix + "*", ";", "", 0 )
	
		if ( ItemsInList( wList ) == 0 )
			newPrefix = ""
			Prompt newPrefix, "optional new prefix name for copied waves:"
		endif
		
	endif
	
	SetNMstr( NMMainDF + "DuplicateToFolder", toFolder )
	
	if ( copyToStimFolder )
	
		selectNewPrefix = 0
		copySets = 0
	
		DoPrompt promptStr, newPrefix
	
		if ( V_flag == 1 )
			return "" // cancel
		endif
	
	else
	
		if ( strlen( setsWaveList ) > 0 )
		
			DoPrompt promptStr, copySets, newPrefix, selectNewPrefix
	
			if ( V_flag == 1 )
				return "" // cancel
			endif
		
			copySets -= 1
		
			SetNMvar( NMMainDF + "DuplicateSets", copySets )
		
		else
		
			DoPrompt promptStr, newPrefix, selectNewPrefix
	
			if ( V_flag == 1 )
				return "" // cancel
			endif
		
			copySets = 0
		
		endif
		
		selectNewPrefix -= 1
		
		SetNMvar( NMMainDF + "DuplicateSelectPrefix", selectNewPrefix )
	
	endif
	
	if ( StringMatch( toFolder, "This Folder" ) )
		toFolder = ""
		toFolderFP = ""
	endif
	
	//if ( StringMatch( toFolder, "This Folder" ) )
	
	//	toFolder = ""
		
	//	DoPrompt promptStr, newPrefix
	
	//	if ( V_flag == 1 )
	//		return "" // cancel
	//	endif
			
	//else
	
	//	wList = NMFolderWaveList( toFolder, currentWavePrefix + "*", ";", "", 0 )
	
	//	if ( ItemsInList( wList ) > 0 )
			
	//		DoPrompt promptStr, newPrefix
	
	//		if ( V_flag == 1 )
	//			return "" // cancel
	//		endif
			
	//	else
		
	//		newPrefix = ""
			
	//	endif
	
	//endif
	
	if ( ( strlen( toFolder ) == 0 ) && ( strlen( newPrefix ) == 0 ) )
		DoAlert /T=( promptStr ) 0, "Abort: source and destination waves are the same."
		return "" // cancel
	endif
	
	if ( strlen( newPrefix ) > 0 )
		SetNMstr( NMMainDF + "DuplicatePrefix", newPrefix )
	endif
	
	wList = NMFolderWaveList( toFolderFP, newPrefix + currentWavePrefix + "*", ";", "", 0 )
	
	if ( ItemsInList( wList ) > 0 )
	
		txt = "Copy Alert: waves with prefix " + NMQuotes( newPrefix + currentWavePrefix ) + " already exist in "
	
		if ( strlen( toFolder ) == 0 )
			txt += CurrentNMFolder( 0 ) + " and may be overwritten. Do you want to continue?"
		else
			txt += toFolder + " and may be overwritten. Do you want to continue?"
		endif
		
		DoAlert /T=( promptStr ) 1, txt
		
		if ( V_flag == 1 )
			overwrite = 1
		else
			return "" // cancel
		endif
	
	endif
	
	returnList = NMMainDuplicate( xbgn=xbgn, xend=xend, toFolder=toFolderFP, newPrefix=newPrefix, overwrite=overwrite, copySets=copySets, history=1 )
	
	if ( ItemsInList( returnList ) == 0 )
		return ""
	endif
	
	if ( copyToStimFolder )
		return returnList
	endif
	
	if ( selectNewPrefix )
	
		if ( strlen( toFolder ) > 0 )
			NMFolderChange( toFolder )
		endif
		
		NMPrefixSelect( newPrefix + currentWavePrefix, noPrompts=1 )
		
	elseif ( strlen( newPrefix ) > 0 )
	
		NMPrefixAdd( newPrefix + currentWavePrefix )
		
	endif
	
	return returnList
	
End // zCall_NMMainDuplicateToFolder

//****************************************************************
//****************************************************************

Function /S NMMainDuplicate( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, xbgn, xend, toFolder, newPrefix, overwrite, copySets ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	Variable xbgn, xend
	String toFolder // where to copy selected waves, pass "" for current folder
	String newPrefix // wave prefix of copied waves, nothing for current prefix for when copying to a different folder
	Variable overwrite // overwrite output wave if it already exists ( 0 ) no ( 1 ) yes
	Variable copySets // copy Sets and Groups ( 0 ) no ( 1 ) yes
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( ( numtype( xbgn ) == 0 ) || ( numtype( xend ) == 0 ) )
		NMLoopExecVarAdd( "xbgn", xbgn, nm )
		NMLoopExecVarAdd( "xend", xend, nm )
	endif
	
	if ( ParamIsDefault( toFolder ) )
		toFolder = ""
	elseif ( strlen( toFolder ) > 0 )
		NMLoopExecStrAdd( "toFolder", toFolder, nm )
	endif
	
	toFolder = CheckNMFolderPath( toFolder )
	
	if ( !IsNMFolder( toFolder, "NMData" ) && !IsNMFolder( toFolder, "NMStim" ) )
		return NM2ErrorStr( 30, "toFolder", toFolder )
	endif
	
	if ( !ParamIsDefault( newPrefix ) && ( strlen( newPrefix ) > 0 ) )
		NMLoopExecStrAdd( "newPrefix", newPrefix, nm )
	endif
	
	if ( overwrite )
		NMLoopExecVarAdd( "overwrite", overwrite, nm, integer = 1 )
	endif
	
	if ( copySets )
		NMLoopExecVarAdd( "copySets", copySets, nm, integer = 1 )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	//nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainDuplicate

//****************************************************************
//****************************************************************

Function /S NMMainDuplicate2( [ folder, wavePrefix, chanNum, waveSelect, xbgn, xend, toFolder, newPrefix, overwrite, copySets ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	Variable xbgn, xend
	String toFolder // where to copy selected waves, nothing for current folder
	String newPrefix // wave prefix, nothing for current prefix
	Variable overwrite // overwrite output wave if it already exists ( 0 ) no ( 1 ) yes
	Variable copySets // copy Sets and Groups ( 0 ) no ( 1 ) yes
	
	STRUCT NMParams nm
	
	String fxn = "NMDuplicate"
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( ParamIsDefault( toFolder ) )
		toFolder = ""
	endif
	
	toFolder = CheckNMFolderPath( toFolder )
	
	if ( !IsNMFolder( toFolder, "NMData" ) && !IsNMFolder( toFolder, "NMStim" ) )
		return NM2ErrorStr( 30, "toFolder", toFolder )
	endif
	
	if ( ParamIsDefault( newPrefix ) )
		newPrefix = ""
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	return NMDuplicate2( nm, xbgn=xbgn, xend=xend, toFolder=toFolder, newPrefix=newPrefix, overwrite=overwrite, copySets=copySets, history=1 )
	
End // NMMainDuplicate2

//****************************************************************
//****************************************************************

Static Function /S zNMMainConcatenatePrefix( waveSelect, wavePrefix, prefixFolder, newPrefix )
	String waveSelect, wavePrefix, prefixFolder, newPrefix
	
	String wPrefix
	
	if ( StringMatch( waveSelect, "All" ) || StringMatch( waveSelect, "All+" ) )
	
		return newPrefix + wavePrefix
		
	else
	
		wPrefix = wavePrefix + NMWaveSelectShort( prefixFolder=prefixFolder, waveSelect=waveSelect )
		wPrefix = NMNameStrShort( wPrefix ) + "_"
		wPrefix = wPrefix[ 0, 11 ]
		
		return newPrefix + wPrefix
		
	endif
	
End // zNMMainConcatenatePrefix

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainConcatenate( dimension )
	Variable dimension // ( 1 ) 1D wave ( 2 ) 2D wave

	Variable overwrite
	String returnList, wList, wstr, promptStr = NMPromptStr( "NM Concatenate" )
	
	Variable numChannels = NMNumChannels()
	String currentWavePrefix = CurrentNMWavePrefix()
	String prefixFolder = CurrentNMPrefixFolder()
	String waveSelect = NMWaveSelectGet()
	
	String newPrefix //= StrVarOrDefault( NMMainDF + "ConcatPrefix", NMNewPrefix )
	Variable selectNewPrefix = 1 + NumVarOrDefault( NMMainDF + "ConcatSelectPrefix", 1 )
	
	if ( numChannels == 1 )
		wstr = "wave"
	elseif ( numChannels > 1 )
		wstr = "waves"
	else
		return ""
	endif
	
	newPrefix = zNMMainConcatenatePrefix( waveSelect, currentWavePrefix, prefixFolder, "C_" )
	
	Prompt dimension, "output wave dimension:", popup "1 dimension;2 dimensions;"
	Prompt newPrefix, "prefix name for concatenated " + wstr + ":"
	Prompt selectNewPrefix, "select concatenated " + wstr + "?", popup "no;yes;"
	
	DoPrompt promptStr, dimension, newPrefix, selectNewPrefix
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	selectNewPrefix -= 1
	
	SetNMstr( NMMainDF + "ConcatPrefix", newPrefix )
	SetNMvar( NMMainDF + "ConcatSelectPrefix", selectNewPrefix )
	
	wList = WaveList( newPrefix + "*", ";", "" )
	
	if ( ItemsInList( wList ) > 0 )
		
		DoAlert /T=( promptStr ) 1, "Alert: waves with prefix " + NMQuotes( newPrefix ) + " already exist and may be overwritten. Do you want to continue?"
		
		if ( V_flag == 1 )
			overwrite = 1
		else
			return "" // cancel
		endif
	
	endif
	
	returnList = NMMainConcatenate( dimension=dimension, newPrefix=newPrefix, overwrite=overwrite, history=1 )
	
	if ( ItemsInList( returnList ) == 0 )
		return ""
	endif
	
	if ( selectNewPrefix )
		NMPrefixSelect( newPrefix, noPrompts=1 )
	else
		NMPrefixAdd( newPrefix )
	endif
	
	return returnList

End // zCall_NMMainConcatenate

//****************************************************************
//****************************************************************

Function /S NMMainConcatenate( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, dimension, newPrefix, overwrite ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	Variable dimension // output wave dimension ( 1 ) 1D, default ( 2 ) 2D
	String newPrefix // prefix name of output waves ( must specify )
	Variable overwrite // overwrite output wave if it already exists ( 0 ) no ( 1 ) yes
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( !ParamIsDefault( dimension ) )
		NMLoopExecVarAdd( "dimension", dimension, nm, integer = 1 )
	endif
	
	if ( ParamIsDefault( newPrefix ) || ( strlen( newPrefix ) == 0 ) )
		return NM2ErrorStr( 21, "newPrefix", "" )
	endif
	
	NMLoopExecStrAdd( "newPrefix", newPrefix, nm )
	
	if ( overwrite )
		NMLoopExecVarAdd( "overwrite", overwrite, nm, integer = 1 )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	//nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainConcatenate

//****************************************************************
//****************************************************************

Function /S NMMainConcatenate2( [ folder, wavePrefix, chanNum, waveSelect, dimension, newPrefix, overwrite ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	Variable dimension // output wave dimension ( 1 ) 1D, default ( 2 ) 2D
	String newPrefix // prefix name of output waves
	Variable overwrite // overwrite output wave if it already exists ( 0 ) no, alert user ( 1 ) yes
	
	String wName, fxn = "NMConcat"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( dimension ) )
		dimension = 1
	endif
	
	if ( ParamIsDefault( newPrefix ) || ( strlen( newPrefix ) == 0 ) )
		return NM2ErrorStr( 21, "newPrefix", "" )
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	wName = GetWaveName( newPrefix, nm.chanNum, 0 )
	
	return NMConcatenate2( nm, wName, dimension=dimension, overwrite=overwrite, history=1 )
	
End // NMMainConcatenate2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainSplit()
	
	Variable overwrite, numOutputWaves = 10
	String wList, returnList, promptStr = NMPromptStr( "NM Split Waves" )
	
	String dName = ChanDisplayWave( -1 )
	String currentWavePrefix = CurrentNMWavePrefix()
	
	if ( DimSize( $dName, 1 ) > 0 )
		return zCall_NMMainSplit2D()
	endif
	
	Variable xbgn = NumVarOrDefault( NMMainDF + "SplitXbgn", -inf )
	Variable xend = NumVarOrDefault( NMMainDF + "SplitXend", inf )
	
	Variable outputWaveLength = ( rightx( $dName ) - leftx( $dName ) ) / numOutputWaves
	
	outputWaveLength = NumVarOrDefault( NMMainDF + "SplitLength", outputWaveLength )
	
	Variable selectNewPrefix = 1 + NumVarOrDefault( NMMainDF + "SplitSelectPrefix", 1 )
	String newPrefix = StrVarOrDefault( NMMainDF + "SplitPrefix", NMNewPrefix )
	
	Prompt xbgn, NMPromptAddUnitsX( "x-axis window begin" )
	Prompt xend, NMPromptAddUnitsX( "x-axis window end" )
	Prompt outputWaveLength, NMPromptAddUnitsX( "wave length of new output waves" )
	Prompt newPrefix, "prefix name for output split waves:"
	Prompt selectNewPrefix, "select split waves?", popup "no;yes;"
	
	DoPrompt promptStr, xbgn, xend, outputWaveLength, newPrefix, selectNewPrefix
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	selectNewPrefix -= 1
	
	SetNMstr( NMMainDF + "SplitPrefix", newPrefix )
	SetNMvar( NMMainDF + "SplitLength", outputWaveLength )
	SetNMvar( NMMainDF + "SplitSelectPrefix", selectNewPrefix )
	
	wList = WaveList( newPrefix + currentWavePrefix + "*", ";", "" )
	
	if ( ItemsInList( wList ) > 0 )
		
		DoAlert /T= ( promptStr ) 1, "Alert: waves with prefix " + NMQuotes( newPrefix + currentWavePrefix ) + " already exist and may be overwritten. Do you want to continue?"
		
		if ( V_flag == 1 )
			overwrite = 1
		else
			return "" // cancel
		endif
	
	endif
	
	returnList = NMMainSplit( xbgn=xbgn, xend=xend, outputWaveLength=outputWaveLength, newPrefix=newPrefix, overwrite=overwrite, history=1 )
	
	if ( ItemsInList( returnList ) == 0 )
		return ""
	endif
	
	if ( selectNewPrefix )
		NMPrefixSelect( newPrefix + currentWavePrefix, noPrompts=1 )
	else
		NMPrefixAdd( newPrefix + currentWavePrefix )
	endif
	
	return returnList

End // zCall_NMMainSplit

//****************************************************************
//****************************************************************

Function /S NMMainSplit( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, xbgn, xend, outputWaveLength, newPrefix, overwrite ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	Variable xbgn, xend
	Variable outputWaveLength // output wave length ( must specify )
	String newPrefix // prefix name of output wave ( must specify )
	Variable overwrite // overwrite output waves if they already exist ( 0 ) no ( 1 ) yes
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( ( numtype( xbgn ) == 0 ) || ( numtype( xend ) == 0 ) )
		NMLoopExecVarAdd( "xbgn", xbgn, nm )
		NMLoopExecVarAdd( "xend", xend, nm )
	endif
	
	if ( ParamIsDefault( outputWaveLength ) )
		return NM2ErrorStr( 11, "outputWaveLength", "" )
	endif
	
	if ( ( numtype( outputWaveLength ) > 0 ) || ( outputWaveLength <= 0 ) )
		return NM2ErrorStr( 10, "outputWaveLength", num2str( outputWaveLength ) )
	endif
	
	if ( ParamIsDefault( newPrefix ) || ( strlen( newPrefix ) == 0 ) )
		return NM2ErrorStr( 21, "newPrefix", "" )
	endif
	
	NMLoopExecVarAdd( "outputWaveLength", outputWaveLength, nm )
	NMLoopExecStrAdd( "newPrefix", newPrefix, nm )
	
	if ( overwrite )
		NMLoopExecVarAdd( "overwrite", overwrite, nm, integer = 1 )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	//nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainSplit

//****************************************************************
//****************************************************************

Function /S NMMainSplit2( [ folder, wavePrefix, chanNum, waveSelect, xbgn, xend, outputWaveLength, newPrefix, overwrite ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	Variable xbgn, xend
	Variable outputWaveLength // output wave length
	String newPrefix // prefix name of output wave
	Variable overwrite // overwrite output waves if they already exist ( 0 ) no ( 1 ) yes
	
	String fxn = "NMSplit"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( xbgn ) || ( numtype ( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype ( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( ParamIsDefault( outputWaveLength ) )
		return NM2ErrorStr( 11, "outputWaveLength", "" )
	endif
	
	if ( ( numtype( outputWaveLength ) > 0 ) || ( outputWaveLength <= 0 ) )
		return NM2ErrorStr( 10, "outputWaveLength", num2str( outputWaveLength ) )
	endif
	
	if ( ParamIsDefault( newPrefix ) || ( strlen( newPrefix ) == 0 ) )
		return NM2ErrorStr( 21, "newPrefix", "" )
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	return NMSplit2( nm, outputWaveLength, newPrefix, xbgn=xbgn, xend=xend, overwrite=overwrite, history=1 )
	
End // NMMainSplit2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainSplit2D()

	Variable overwrite
	String wList, returnList, promptStr = NMPromptStr( "NM Split 2D Waves" )
	String columnsOrRows
	
	String dName = ChanDisplayWave( -1 )
	String currentWavePrefix = CurrentNMWavePrefix()
	
	if ( DimSize( $dName, 1 ) == 0 )
		return "" // not a 2D wave
	endif
	
	if ( DimSize( $dName, 1 ) < DimSize( $dName, 0 ) )
		columnsOrRows = "columns"
	else
		columnsOrRows = "rows"
	endif
	
	columnsOrRows = StrVarOrDefault( NMMainDF + "SplitColumnsOrRows", columnsOrRows )
	Variable selectNewPrefix = 1 + NumVarOrDefault( NMMainDF + "SplitSelectPrefix", 1 )
	String newPrefix = StrVarOrDefault( NMMainDF + "SplitPrefix", NMNewPrefix )
	
	Prompt columnsOrRows, "split 2D wave along:", popup "columns;rows;"
	Prompt newPrefix, "prefix name for output split waves:"
	Prompt selectNewPrefix, "select split waves?", popup "no;yes;"
	
	DoPrompt promptStr, columnsOrRows, newPrefix, selectNewPrefix
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	selectNewPrefix -= 1
	
	SetNMstr( NMMainDF + "SplitColumnsOrRows", columnsOrRows )
	SetNMstr( NMMainDF + "SplitPrefix", newPrefix )
	SetNMvar( NMMainDF + "SplitSelectPrefix", selectNewPrefix )
	
	wList = WaveList( newPrefix + currentWavePrefix + "*", ";", "" )
	
	if ( ItemsInList( wList ) > 0 )
		
		DoAlert /T= ( promptStr ) 1, "Alert: waves with prefix " + NMQuotes( newPrefix + currentWavePrefix ) + " already exist and may be overwritten. Do you want to continue?"
		
		if ( V_flag == 1 )
			overwrite = 1
		else
			return "" // cancel
		endif
	
	endif
	
	returnList = NMMainSplit2D( columnsOrRows=columnsOrRows, newPrefix=newPrefix, overwrite=overwrite, history=1 )
	
	if ( ItemsInList( returnList ) == 0 )
		return ""
	endif
	
	if ( selectNewPrefix )
		NMPrefixSelect( newPrefix + currentWavePrefix, noPrompts=1 )
	else
		NMPrefixAdd( newPrefix + currentWavePrefix )
	endif
	
	return returnList

End // zCall_NMMainSplit2D

//****************************************************************
//****************************************************************

Function /S NMMainSplit2D( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, columnsOrRows, newPrefix, overwrite ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	String columnsOrRows // default is "columns"
	String newPrefix // prefix name of output wave ( must specify )
	Variable overwrite // overwrite output waves if they already exist ( 0 ) no ( 1 ) yes
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( columnsOrRows ) )
		columnsOrRows = "columns"
	endif
	
	strswitch( columnsOrRows )
		case "column":
		case "columns":
		case "row":
		case "rows":
			break
		default:
			return NM2ErrorStr( 20, "columnsOrRows", columnsOrRows )
	endswitch
	
	if ( ParamIsDefault( newPrefix ) || ( strlen( newPrefix ) == 0 ) )
		return NM2ErrorStr( 21, "newPrefix", "" )
	endif
	
	NMLoopExecStrAdd( "columnsOrRows", columnsOrRows, nm )
	NMLoopExecStrAdd( "newPrefix", newPrefix, nm )
	
	if ( overwrite )
		NMLoopExecVarAdd( "overwrite", overwrite, nm, integer = 1 )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	//nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainSplit2D

//****************************************************************
//****************************************************************

Function /S NMMainSplit2D2( [ folder, wavePrefix, chanNum, waveSelect, columnsOrRows, newPrefix, overwrite ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	String columnsOrRows // "columns" is default
	String newPrefix // prefix name of output wave
	Variable overwrite // overwrite output waves if they already exist ( 0 ) no ( 1 ) yes
	
	String fxn = "NMSplit2D"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( columnsOrRows ) )
		columnsOrRows = "columns"
	endif
	
	strswitch( columnsOrRows )
		case "column":
		case "columns":
		case "row":
		case "rows":
			break
		default:
			return NM2ErrorStr( 20, "columnsOrRows", columnsOrRows )
	endswitch
	
	if ( ParamIsDefault( newPrefix ) || ( strlen( newPrefix ) == 0 ) )
		return NM2ErrorStr( 21, "newPrefix", "" )
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	return NMSplit2D( nm, columnsOrRows, newPrefix, overwrite=overwrite, history=1 )
	
End // NMMainSplit2D2

//****************************************************************
//****************************************************************

Function /S NMRenameWavesCall( search [ promptStr ] )
	String search // ( "All" ) search all waves ( "Selected" ) search selected waves
	String promptStr

	Variable wcnt, items, numWaves, selectedWaves, updateSets = 1
	String txt, wList, wList2 = "", wName, newname
	String returnList, prefixList, conflictList = "", vlist = ""
	
	String currentPrefix = CurrentNMWavePrefix()
	
	String find = StrVarOrDefault( NMDF + "RenameWavesFind", "" )
	String replacement = StrVarOrDefault( NMDF + "RenameWavesReplacement", "" )
	
	if ( strlen( search ) == 0 )
	
		search = "All"
		
		Prompt search, "waves to rename:", popup "All;Currently Selected;"
		DoPrompt promptStr, search
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		search = ReplaceString( "Currently Selected", search, "Selected" )
	
	endif
	
	Prompt find, "wave name search string:"
	Prompt replacement, "replacement string:"
	DoPrompt promptStr, find, replacement
	
	if ( ( V_flag == 1 ) || ( strlen( find ) == 0 ) || StringMatch( find, replacement ) )
		return "" // cancel
	endif
	
	SetNMstr( NMDF + "RenameWavesFind", find )
	SetNMstr( NMDF + "RenameWavesReplacement", replacement )
	
	if ( StringMatch( search, "All" ) )
	
		wList = WaveList( "*" + find + "*", ";", "" )
		
		numWaves = ItemsInList( wList )
		
		for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
		
			wName = StringFromList( wcnt, wList )
			newName = ReplaceString( find, wName, replacement )
			
			if ( StringMatch( wName, newName ) )
				continue // no change
			endif
			
			if ( WaveExists( $newName ) )
				conflictList += newName + ","
			endif
		
		endfor
	
	else
	
		selectedWaves = 1
	
		wList = NMWaveSelectList( -2 )
		
		for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
	
			wName = StringFromList( wcnt, wList )
			newName = ReplaceString( find, wName, replacement )
			
			if ( StringMatch( wName, newName ) )
				continue // no change
			endif
			
			wList2 += wName + ";"
			
			if ( WaveExists( $newName ) )
				conflictList += newName + ","
			endif
		
		endfor
		
		wList = wList2
		
		numWaves = ItemsInList( wList )
		
	endif
	
	if ( numWaves == 0 )
		DoAlert /T=( promptStr ) 0, "Abort: found no wave names containing string " + NMQuotes( find )
		return "" // cancel
	endif
	
	promptStr += " : " + NMQuotes( find ) + "-->" + NMQuotes( replacement ) + " : n = " + num2istr( numWaves ) + " waves"
	
	if ( ItemsInList( conflictList, "," ) > 0 )
	
		DoAlert /T=( promptStr ) 0, "Abort: encountered one or more name conflicts with existing waves."
		
		NMHistory( "Rename Waves Abort : name conflict with " + conflictList )
		
		return "" // cancel
		
	endif
	
	prefixList = zCheck_NMRenameWavesPrefix( wList )
	
	if ( selectedWaves )
		prefixList = RemoveFromList( currentPrefix, prefixList )
	endif
	
	items = ItemsInList( prefixList )
	
	if ( items > 0 )
		
		txt = "Alert: the string replacement you entered will alter the wave lists for "
	
		if ( items == 1 )
			prefixList = StringFromList( 0, prefixList )
			txt += "wave-prefix folder " + NMQuotes( prefixList ) + ". "
		else
			prefixList = ReplaceString( ";", prefixList, "," )
			txt += "the following wave-prefix folders: " + prefixList + ". "
		endif
		
		txt = ReplaceString( ",.", txt, "." )
	
	else
	
		txt = "Located " + num2istr( numWaves ) + " wave names containing " + NMQuotes( find ) + ". "
	
	endif
	
	txt += "Do you want to continue?"
	
	DoAlert /T=( promptStr ) 1, txt
		
	if ( V_flag != 1 )
		return "" // cancel
	endif
	
	if ( selectedWaves )
	
		returnList = NMMainRename( find = find, replacement = replacement, history = 1 )
		
	else
		
		vlist = NMCmdStr( find, vlist )
		vlist = NMCmdStr( replacement, vlist )
		vlist = NMCmdStr( "_All_", vlist )
		vlist = NMCmdNumOptional( "updateSets", updateSets, vlist, integer = 1 )
		
		NMCmdHistory( "NMRenameWavesSafely", vlist )
		
		returnList = NMRenameWavesSafely( find, replacement, wList, updateSets = updateSets )
		
	endif
	
	if ( ItemsInList( returnList ) > 0 )
		NMDoAlert( "Alert: renamed waves may no longer be recognized by NeuroMatic. If necessary, use the Wave Prefix popup to re-select your waves, and check your Sets and Groups." )
	endif
	
	return returnList

End // NMRenameWavesCall

//****************************************************************
//****************************************************************

Static Function /S zCheck_NMRenameWavesPrefix( wList )
	String wList // wave list to change names
	
	Variable wcnt, pcnt, change, ccnt, numChannels
	
	String wName, wList2, changeList = ""
	String prefixName, prefixFolder
	
	String prefixList = NMPrefixSubfolderList( 0 )
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		for ( pcnt = 0 ; pcnt < ItemsInList( prefixList ) ; pcnt += 1 ) // check change to prefix
		
			prefixName = StringFromList( pcnt, prefixList )
			prefixFolder = NMPrefixFolderDF( "", prefixName )
			
			numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
			
			change = 0
			
			for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
			
				wList2 = StrVarOrDefault( prefixFolder + "Chan_WaveList" + ChanNum2Char( ccnt ), "" )
				
				if ( WhichListItem( wName, wList2 ) >= 0 )
					change = 1
					break
				endif
			
			endfor
			
			if ( change )
				changeList = NMAddToList( prefixName, changeList, ";" )
			endif
			
		endfor
		
	endfor
	
	return changeList
	
End // zCheck_NMRenameWavesPrefix

//****************************************************************
//****************************************************************

Function /S NMMainRename( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, find, replacement, updateSets ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	String find // string to find in wave name ( must specify )
	String replacement // replace with this string ( must specify )
	Variable updateSets // also change wave names in prefix subfolder wave lists ( 0 ) no ( 1 ) yes
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( find ) || ( strlen( find ) == 0 ) )
		return NM2ErrorStr( 21, "find", "" )
	endif
	
	if ( ParamIsDefault( replacement ) )
		return NM2ErrorStr( 21, "replacement", "" )
	endif
	
	NMLoopExecStrAdd( "find", find, nm )
	NMLoopExecStrAdd( "replacement", replacement, nm )
	
	if ( !ParamIsDefault( updateSets ) )
		NMLoopExecVarAdd( "updateSets", updateSets, nm, integer = 1 )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	nm.updateWaveLists = 1
	nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainRename

//****************************************************************
//****************************************************************

Function /S NMMainRename2( [ folder, wavePrefix, chanNum, waveSelect, find, replacement, updateSets ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	String find // string to find in wave name
	String replacement // replace with this string
	Variable updateSets // also change wave names in prefix subfolder wave lists ( 0 ) no ( 1 ) yes
	
	String fxn = "NMRename"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( find ) || ( strlen( find ) == 0 ) )
		return NM2ErrorStr( 21, "find", "" )
	endif
	
	if ( ParamIsDefault( replacement ) )
		return NM2ErrorStr( 21, "replacement", "" )
	endif
	
	if ( ParamIsDefault( updateSets ) )
		updateSets = 1
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	return NMRenameWavesSafely2( nm, find, replacement, updateSets=updateSets, history=1 )
	
End // NMMainRename2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainRenumber()
	
	Variable fromNum = 0
	Variable increment = 1
	
	Prompt fromNum, "renumber selected waves from:"
	Prompt increment, "wave number increment:"
	DoPrompt NMPromptStr( "NM Renumber Waves" ), fromNum, increment
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	return NMMainRenumber( fromNum=fromNum, increment=increment, updateSets=1, history=1 )

End // zCall_NMMainRenumber

//****************************************************************
//****************************************************************

Function /S NMMainRenumber( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, fromNum, increment, updateSets ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	Variable fromNum // renumber waves starting from this number
	Variable increment // renumber increment ( default is 1 )
	Variable updateSets // also change wave names in prefix subfolder wave lists ( 0 ) no ( 1 ) yes
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( !ParamIsDefault( fromNum ) )
		NMLoopExecVarAdd( "fromNum", fromNum, nm, integer=1 )
	endif
	
	if ( ParamIsDefault( increment ) )
		increment = 1
	else
		NMLoopExecVarAdd( "increment", increment, nm, integer=1 )
	endif
	
	if ( !ParamIsDefault( updateSets ) )
		NMLoopExecVarAdd( "updateSets", updateSets, nm, integer=1 )
	endif
	
	fromNum = round( fromNum )
	increment = round( increment )
	
	if ( ( numtype( fromNum ) > 0 ) || ( fromNum < 0 ) )
		return NM2ErrorStr( 10, "fromNum", num2istr( fromNum ) )
	endif
	
	if ( ( numtype( increment ) > 0 ) || ( increment <= 0 ) )
		return NM2ErrorStr( 10, "increment", num2istr( increment ) )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	nm.updateWaveLists = 1
	nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainRenumber

//****************************************************************
//****************************************************************

Function /S NMMainRenumber2( [ folder, wavePrefix, chanNum, waveSelect, fromNum, increment, updateSets ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	Variable fromNum // renumber waves starting from this number ( default 0 )
	Variable increment // renumber increment ( default 1 )
	Variable updateSets // also change wave names in prefix subfolder wave lists ( 0 ) no ( 1 ) yes
	
	String fxn = "NMRenumber"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( increment ) )
		increment = 1
	endif
	
	if ( ParamIsDefault( updateSets ) )
		updateSets = 1
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	return NMRenumberWavesSafely2( nm, fromNum=fromNum, increment=increment, updateSets=updateSets, history=1 )
	
End // NMMainRenumber2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainSave()

	Variable saveXaxisWaveTemp, igorType
	String promptStr = NMPromptStr( "NM Save Waves" )

	String extFolderPath = StrVarOrDefault( NMMainDF + "SaveWavesPath", "" )
	String fileType = StrVarOrDefault( NMMainDF + "SaveWavesFileType", "Igor Binary" )
	Variable saveXaxisWave = 1 + NumVarOrDefault( NMMainDF + "SaveWavesXaxisWave", 0 )
	Variable saveWaveNotes = 1 + NumVarOrDefault( NMMainDF + "SaveWavesNotes", 0 )
	Variable saveParams = 1 + NumVarOrDefault( NMMainDF + "SaveWavesParams", 0 )
	
	if ( saveXaxisWave > 1 )
		saveXaxisWaveTemp = 2
	else
		saveXaxisWaveTemp = 1
	endif
	
	Prompt fileType, "save waves as:", popup "Igor Binary;Igor Text;General Text;Delimited Text;"
	Prompt saveXaxisWaveTemp, "save x-axis waves?", popup "no;yes;"
	Prompt saveWaveNotes, "save wave notes to a text file?", popup "no;yes;"
	Prompt saveParams, "save relevant parameters to a text file?", popup "no;yes;"
	
	DoPrompt promptStr, fileType, saveXaxisWaveTemp, saveWaveNotes, saveParams
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	saveWaveNotes -= 1
	saveParams -= 1
	
	SetNMstr( NMMainDF + "SaveWavesFileType", fileType )
	SetNMvar( NMMainDF + "SaveWavesNotes", saveWaveNotes )
	SetNMvar( NMMainDF + "SaveWavesParams", saveParams )
	
	igorType = StringMatch( fileType, "Igor Binary" ) || StringMatch( fileType, "Igor Text" )
	
	if ( ( saveXaxisWaveTemp == 2 ) && !igorType )
	
		if ( saveXaxisWave == 2 )
			saveXaxisWaveTemp = 1
		endif
		
		Prompt saveXaxisWaveTemp, "save time waves:", popup "in seperate text files;with data inside text files;"
		DoPrompt promptStr, saveXaxisWaveTemp
	
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		saveXaxisWaveTemp += 1 // add 1, since first option is really "no"
	
	endif
	
	saveXaxisWave = saveXaxisWaveTemp - 1
	
	SetNMvar( NMMainDF + "SaveWavesXaxisWave", saveXaxisWave )
	
	extFolderPath = NMGetExternalFolderPath( "select folder on disk where to save", extFolderPath )
	
	if ( strlen( extFolderPath ) == 0 )
		return "" // cancel
	endif
	
	SetNMstr( NMMainDF + "SaveWavesPath", extFolderPath )

	return NMMainSave( extFolderPath=extFolderPath, fileType=fileType, saveXaxisWave=saveXaxisWave, saveWaveNotes=saveWaveNotes, saveParams=saveParams, history=1 )

End // zCall_NMMainSave

//****************************************************************
//****************************************************************

Function /S NMMainSave( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, extFolderPath, fileType, saveXaxisWave, saveWaveNotes, saveParams ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	String extFolderPath // path to external folder where data is to be saved ( pass nothing to get browser )
	String fileType // ( "binary" ) Igor Binary ( "text" ) Igor Text ( "general text" ) General Text ( "delimited text" ) Delimited Text
	Variable saveXaxisWave // ( 0 ) no ( 1 ) yes, save as seperate ( 2 ) yes, save in same file as data ( General or Delimited Text only )
	Variable saveWaveNotes // ( 0 ) no ( 1 ) yes
	Variable saveParams // ( 0 ) no ( 1 ) yes
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	Variable fType
	
	if ( ParamIsDefault( extFolderPath ) || ( strlen( extFolderPath ) == 0 ) )
		extFolderPath = NMGetExternalFolderPath( "select folder on disk where to save", "" )
	endif
	
	if ( strlen( extFolderPath ) == 0 )
		return "" // cancel
	endif
	
	NMLoopExecStrAdd( "extFolderPath", extFolderPath, nm )
	
	if ( !ParamIsDefault( fileType ) )
	
		fType = NMWaveFileTypeNum( fileType )
		
		if ( numtype( fType ) > 0 )
			return NM2ErrorStr( 20, fileType, fileType )
		endif
		
		NMLoopExecStrAdd( "fileType", fileType, nm )
		
	endif
	
	if ( !ParamIsDefault( saveXaxisWave ) )
		NMLoopExecVarAdd( "saveXaxisWave", saveXaxisWave, nm, integer=1 )
	endif
	
	if ( saveWaveNotes )
		NMLoopExecVarAdd( "saveWaveNotes", saveWaveNotes, nm, integer=1 )
	endif
	
	if ( saveParams )
		NMLoopExecVarAdd( "saveParams", saveParams, nm, integer=1 )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	//nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainSave

//****************************************************************
//****************************************************************

Function /S NMMainSave2( [ folder, wavePrefix, chanNum, waveSelect, extFolderPath, fileType, saveXaxisWave, saveWaveNotes, saveParams ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	String extFolderPath // path to external folder where data is to be saved
	String fileType // "Igor Binary" or "Igor Text" or "General Text" or "Delimited Text"
	Variable saveXaxisWave // ( 0 ) no ( 1 ) yes, save as seperate file ( 2 ) yes, save in same file as data ( General or Delimited Text only )
	Variable saveWaveNotes // ( 0 ) no ( 1 ) yes
	Variable saveParams // ( 0 ) no ( 1 ) yes
	
	Variable fType
	String fxn = "NMSave"
	
	STRUCT NMParams nm
	
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
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	return NMSave2( nm, extFolderPath=extFolderPath, fileType=fileType, saveXaxisWave=saveXaxisWave, saveWaveNotes=saveWaveNotes, saveParams=saveParams, history=1 )
	
End // NMMainSave2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainKillWaves()

	Variable killPrefixGlobals
	String returnStr, promptStr = NMPromptStr( "NM Kill Waves" )

	String currentPrefix = CurrentNMWavePrefix()
	String chanList = NMChanSelectCharList()
	String currentWaveSelect = NMWaveSelectGet()
	
	Variable numChannels = NMNumChannels()
	
	if ( ( ItemsInList( chanList ) == numChannels ) && StringMatch( currentWaveSelect, "All" ) )
	
		killPrefixGlobals = 1 + NumVarOrDefault( NMMainDF + "KillPrefixGlobals", 1 )
		
		Prompt killPrefixGlobals, "also kill prefix globals associated with the currently selected waves?", popup "no;yes;"
		DoPrompt promptStr, killPrefixGlobals
	
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		killPrefixGlobals -= 1
		SetNMvar( NMMainDF + "KillPrefixGlobals", killPrefixGlobals )
		
	else
	
		DoAlert /T=( promptStr ) 1, "Are you sure you want to kill the currently selected waves?"
	
		if ( V_Flag != 1 )
			return ""
		endif
	
	endif
	
	returnStr = NMMainKillWaves( history=1 )
	
	if ( killPrefixGlobals )
		NMPrefixSubfolderKill( currentPrefix )
	endif
	
	return returnStr
	
End // zCall_NMMainKillWaves

//****************************************************************
//****************************************************************

Function /S NMMainKillWaves( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, updateSets ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	Variable updateSets // remove wave names from prefix subfolder wave lists ( 0 ) no ( 1 ) yes
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( !ParamIsDefault( updateSets ) )
		NMLoopExecVarAdd( "updateSets", updateSets, nm, integer=1 )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	nm.updateWaveLists = 1
	nm.updateGraphs = 1
	nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )
	
End // NMMainKillWaves

//****************************************************************
//****************************************************************

Function /S NMMainKillWaves2( [ folder, wavePrefix, chanNum, waveSelect, updateSets, killPrefixGlobals ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	Variable updateSets // remove wave names from prefix subfolder wave lists ( 0 ) no ( 1 ) yes
	Variable killPrefixGlobals // kill wave prefix subfolder globals ( 0 ) no ( 1 ) yes
	
	String fxn = "NMKillWaves"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( updateSets ) )
		updateSets = 1
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	return NMKillWaves2( nm, updateSets=updateSets, history=1 )
	
End // NMMainKillWaves2

//****************************************************************
//****************************************************************
//
//		Display Functions
//		Graphs, Tables, x-y Labels, Wave Notes, etc
//
//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainGraph()

	Variable errors
	
	String selectList = NMWaveSelectAllList()
	String waveSelect = NMWaveSelectGet()
	
	String promptStr = NMPromptStr( "NM Graph" )
	String color = NMMainStrGet( "GraphColor" )
	
	Variable foundErrors = NMWaveNameErrorExists( NMWaveSelectListAllChannels() )
	
	if ( foundErrors )
		errors = 1 + NumVarOrDefault( NMMainDF + "GraphErrors", 1 )
	endif
	
	Variable onePerChannel = 1 + NumVarOrDefault( NMMainDF + "GraphOnePerChannel", 1 )
	Variable reverseOrder = 1 + NumVarOrDefault( NMMainDF + "GraphReverseOrder", 0 )
	Variable xOffset = NumVarOrDefault( NMMainDF + "GraphXoffset", 0 )
	Variable yOffset = NumVarOrDefault( NMMainDF + "GraphYoffset", 0 )
	
	Prompt color, "select wave color:", popup "rainbow;" + NMPlotColorList
	Prompt onePerChannel, "plot " + NMQuotes( waveSelect ) + " in the same graph?", popup "no;yes;"
	Prompt reverseOrder, "reverse order of waves?", popup "no;yes;"
	Prompt errors, "plot error bars if STDV or SEM waves exist?", popup "no;yes;"
	Prompt xOffset, "x-offset increment:"
	Prompt yOffset, "y-offset increment:"
	
	if ( StringMatch( waveSelect, "All Groups" ) || StringMatch( waveSelect, "All Sets" ) )
		
		if ( foundErrors )
		
			DoPrompt promptStr, color, onePerChannel, reverseOrder, errors, xOffset, yOffset
		
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
			errors -= 1
			
			SetNMvar( NMMainDF + "GraphErrors", errors )
		
		else
		
			DoPrompt promptStr, color, onePerChannel, reverseOrder, xOffset, yOffset
		
			if ( V_flag == 1 )
				return "" // cancel
			endif
		
		endif
	
		onePerChannel -= 1
		reverseOrder -= 1
		
		SetNMstr( NMMainDF + "GraphColor", color )
		SetNMvar( NMMainDF + "GraphOnePerChannel", onePerChannel )
		SetNMvar( NMMainDF + "GraphReverseOrder", reverseOrder )
		SetNMvar( NMMainDF + "GraphXoffset", xOffset )
		SetNMvar( NMMainDF + "GraphYoffset", yOffset )
		
		if ( onePerChannel )
			return NMMainGraph( color=color, reverseOrder=reverseOrder, xoffset=xoffset, yoffset=yoffset, errors=errors, all=waveSelect, history=1 )
		else
			return NMMainGraph( color=color, reverseOrder=reverseOrder, xoffset=xoffset, yoffset=yoffset, errors=errors, history=1 )
		endif
		
	else
		
		if ( foundErrors )
		
			DoPrompt promptStr, color, reverseOrder, errors, xOffset, yOffset
		
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
			errors -= 1
		
			SetNMvar( NMMainDF + "GraphErrors", errors )
		
		else
		
			DoPrompt promptStr, color, reverseOrder, xOffset, yOffset
		
			if ( V_flag == 1 )
				return "" // cancel
			endif
		
		endif
		
		reverseOrder -= 1
		
		SetNMstr( NMMainDF + "GraphColor", color )
		SetNMvar( NMMainDF + "GraphReverseOrder", reverseOrder )
		SetNMvar( NMMainDF + "GraphXoffset", xOffset )
		SetNMvar( NMMainDF + "GraphYoffset", yOffset )
		
		return NMMainGraph( color=color, reverseOrder=reverseOrder, xoffset=xoffset, yoffset=yoffset, errors=errors, history=1 )
		
	endif

End // zCall_NMMainGraph

//****************************************************************
//****************************************************************

Function /S NMMainGraph( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, color, reverseOrder, xoffset, yoffset, errors, all ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	String color // "rainbow", "black", "red", or rgb list ( e.g. "52224,0,0" ) // "black;gray;red;yellow;green;blue;purple;white;"
	Variable reverseOrder // ( 0 ) no (1 ) yes
	Variable xoffset // see Igor ModifyGraph offset
	Variable yoffset // see Igor ModifyGraph offset
	Variable errors // ( 0 ) no ( 1 ) yes plot errors if appropriately named STDV or SEM wave exists
	String all // "All Sets" or "All Groups" - puts them all in one graph
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( !ParamIsDefault( color ) && ( strlen( color ) > 0 ) )
		NMLoopExecStrAdd( "color", color, nm )
	endif
	
	if ( reverseOrder )
		NMLoopExecVarAdd( "reverseOrder", reverseOrder, nm, integer=1 )
	endif
	
	if ( !ParamIsDefault( xoffset ) && ( xoffset != 0 ) )
		NMLoopExecVarAdd( "xoffset", xoffset, nm )
	endif
	
	if ( !ParamIsDefault( yoffset ) && ( yoffset != 0 ) )
		NMLoopExecVarAdd( "yoffset", yoffset, nm )
	endif
	
	if ( errors )
		NMLoopExecVarAdd( "errors", errors, nm, integer=1 )
	endif
	
	if ( !ParamIsDefault( all ) && ( strlen( all ) > 0 ) )
		NMLoopExecStrAdd( "all", all, nm )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	//nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainGraph

//****************************************************************
//****************************************************************

Function /S NMMainGraph2( [ folder, wavePrefix, chanNum, waveSelect, gName, gTitle, color, reverseOrder, xoffset, yoffset, errors, all ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	String gName, gTitle // graph name and title
	String color // "rainbow", "black", "red", or rgb list ( e.g. "52224,0,0" ) // see NMPlotColorList
	Variable reverseOrder // ( 0 ) no ( 1 ) yes
	Variable xoffset // see Igor ModifyGraph offset
	Variable yoffset // see Igor ModifyGraph offset
	Variable errors // ( 0 ) no ( 1 ) yes plot errors if appropriately named STDV or SEM wave exists
	String all // "All Sets" or "All Groups" - puts them all in one graph
	
	Variable allFlag, allNum, xoffsetInc = 1, yoffsetInc = 1
	String allList, waveSelect2, fxn = "NMGraph"
	
	STRUCT NMParams nm
	
	STRUCT NMRGB c
	
	if ( ParamIsDefault( color ) )
		color = "black"
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
		
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	waveSelect2 = nm.waveSelect
	
	if ( ParamIsDefault( gName ) || ( strlen( gName ) == 0 ) )
	
		if ( !ParamIsDefault( all ) && ( strlen( all ) > 0 ) )
			allFlag = 1
			waveSelect2 = all
		endif
		
		gName = NMMainWindowName( nm.folder, nm.wavePrefix, nm.chanNum, waveSelect2, "graph" )
		
	endif
	
	if ( ( WinType( gName ) > 0 ) && ( WinType( gName ) != 1 ) )
		return NM2ErrorStr( 51, "gName", gName )
	endif
	
	if ( reverseOrder )
		nm.wList = NMReverseList( nm.wList, ";" )
	endif
		
	if ( allFlag )
		
		if ( StringMatch( nm.waveSelect[ 0, 4 ], "Group" ) )
			allList = NMGroupsList( 1, prefixFolder=nm.prefixFolder )
		else
			allList = NMSetsList( prefixFolder=nm.prefixFolder )
		endif
		
		allNum = WhichListItem( nm.waveSelect, allList )
		
		if ( allNum < 0 )
		
			if ( WinType( gName ) == 0 )
				allNum = 0
			else
				allNum = 1
			endif
		
		endif
		
		color = NMRGBrainbow( allNum, c )
		
	endif
	
	if ( ( allNum == 0 ) && ( strlen( gName ) > 0 ) && ( WinType( gName ) == 1 ) )
		DoWindow /K $gName // kill existing graph
	endif
	
	if ( ParamIsDefault( gTitle ) )
		gTitle = NMMainWindowTitle( "", nm.folder, nm.wavePrefix, nm.chanNum, waveSelect2, nm.wList )
	endif
	
	STRUCT NMGraphStruct g
	NMGraphStructNull( g )
	
	g.gName = gName
	g.gTitle = gTitle
	g.xLabel = ""
	g.yLabel = ""
	g.xoffset = xoffset
	g.xoffsetInc = xoffsetInc
	g.yoffset = yoffset
	g.yoffsetInc = yoffsetInc
	g.plotErrors = errors
	g.color = color
	
	return NMGraph2( nm, g, history=1 )
	
End // NMMainGraph2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainTable()
	
	String xWave = NMXwave( waveNum=0 )
	
	if ( strlen( xWave ) == 0 )
		return NMMainTable( history=1 )
	endif
	
	Variable noXwave = NumVarOrDefault( NMMainDF + "TableNoXwave", 0 )
	Variable include = BinaryInvert( noXwave )
	
	include += 1
	
	Prompt include, "include x-scale wave in table?", popup "no;yes;"
	DoPrompt NMPromptStr( "NM Table" ), include
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	include -= 1
	noXwave = BinaryInvert( include )
	
	SetNMvar( NMMainDF + "TableNoXwave", noXwave )

	return NMMainTable( noXwave=noXwave, history=1 )
	
End // zCall_NMMainTable

//****************************************************************
//****************************************************************

Function /S NMMainTable( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, noXwave ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	Variable noXwave // do not include x-scale wave
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( noXwave )
		NMLoopExecVarAdd( "noXwave", noXwave, nm, integer=1 )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	//nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainTable

//****************************************************************
//****************************************************************

Function /S NMMainTable2( [ folder, wavePrefix, chanNum, waveSelect, tName, tTitle, noXwave ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	String tName, tTitle // table name and title
	Variable noXwave // do not include x-scale wave
	
	String fxn = "NMTable"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( tName ) || ( strlen( tName ) == 0 ) )
	
		tName = NMMainWindowName( nm.folder, nm.wavePrefix, nm.chanNum, nm.waveSelect, "table" )
		
		if ( WinType( tName ) == 2 )
			DoWindow /K $tName // kill existing table
		endif
		
	endif
	
	if ( ( strlen( tName ) > 0 ) && ( WinType( tName ) > 0 ) && ( WinType( tName ) != 2 ) )
		return NM2ErrorStr( 51, "tName", tName )
	endif
	
	if ( ParamIsDefault( tTitle ) )
		tTitle = NMMainWindowTitle( "", nm.folder, nm.wavePrefix, nm.chanNum, nm.waveSelect, nm.wList )
	endif
	
	if ( noXwave )
		nm.xWave = ""
	endif
	
	return NMTable2( nm, tName=tName, tTitle=tTitle, history=1 )
	
End // NMMainTable2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainWaveNotesAdd()

	String notestr = ""
	
	Prompt notestr, "enter note:"
	DoPrompt NMPromptStr( "NM Wave Notes" ), notestr
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	return NMMainWaveNotes( notestr=notestr, history=1 )

End // zCall_NMMainWaveNotesAdd

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainWaveNotesClear()

	String promptStr = "NM Wave Notes"

	DoAlert /T=( promptStr ) 2, "Alert: Are you sure you want to clear the notes of all selected waves?"
		
	if ( V_flag != 1 )
		return "" // cancel
	endif
	
	return NMMainWaveNotes( kill=1, history=1 )

End // zCall_NMMainWaveNotesClear

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainWaveNotesPrint()

	Variable to = 1 + NumVarOrDefault( NMMainDF + "WaveNotesPrintTo", 0 )
	
	Prompt to, "print wave notes to:", popup "Igor history;notebook;"
	DoPrompt NMPromptStr( "NM Wave Notes" ), to
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	to -= 1
	
	SetNMvar( NMMainDF + "WaveNotesPrintTo", to )
	
	if ( to == 0 )
		return NMMainWaveNotes( toHistory=1, history=1 )
	endif
	
	if ( to == 1 )
		return NMMainWaveNotes( toNotebook=1, history=1 )
	endif
	
	return ""

End // zCall_NMMainWaveNotesPrint

//****************************************************************
//****************************************************************

Function /S NMMainWaveNotes( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, kill, notestr, toHistory, toNotebook ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	Variable kill // kill all wave notes (executed first)
	String notestr // add note to wave notes
	Variable toHistory // print wave notes to Igor history
	Variable toNotebook // print wave notes to notebook
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( kill )
		NMLoopExecVarAdd( "kill", kill, nm, integer = 1 )
	endif
	
	if ( ParamIsDefault( notestr ) )
		notestr = ""
	elseif (strlen( notestr ) > 0 )
		NMLoopExecStrAdd( "notestr", notestr, nm )
	endif
	
	if ( toNotebook )
		NMLoopExecVarAdd( "toNotebook", toNotebook, nm, integer = 1 )
	endif
	
	if ( toHistory )
		NMLoopExecVarAdd( "toHistory", toHistory, nm, integer = 1 )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	//nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainWaveNotes

//****************************************************************
//****************************************************************

Function /S NMMainWaveNotes2( [ folder, wavePrefix, chanNum, waveSelect, kill, notestr, toHistory, toNotebook ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	Variable kill // kill all wave notes (executed first)
	String notestr // add note to wave notes
	Variable toHistory // print wave notes to Igor history
	Variable toNotebook // print wave notes to notebook
	
	String nbName = "", nbTitle = "", fxn = "NMWaveNotes"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( notestr ) )
		notestr = ""
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	if ( toNotebook )
		nbName = NMMainWindowName( folder, wavePrefix, chanNum, waveSelect, "notebook" )
		nbTitle = NMMainWindowTitle( "Wave Notes", folder, wavePrefix, chanNum, waveSelect, nm.wList )
	endif
	
	return NMWaveNotes2( nm, kill=kill, notestr=notestr, toHistory=toHistory, nbName=nbName, nbTitle=nbTitle, history=1 )

End // NMMainWaveNotes2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainWaveList()

	Variable format = NumVarOrDefault( NMMainDF + "PrintNamesFormat", 1 )
	
	Prompt format, "print:", popup "wave names;compact wave names;folder path + wave names;"
	DoPrompt NMPromptStr( "NM Wave Names" ), format
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMvar( NMMainDF + "PrintNamesFormat", format )
	
	if ( format == 1 )
		return NMMainWaveList( printToHistory=1, history=1 )
	elseif ( format == 2 )
		return NMMainWaveList( printToHistory=1, compact=1, history=1 )
	elseif ( format == 3 )
		return NMMainWaveList( printToHistory=1, fullPath=1, history=1 )
	endif

End // zCall_NMMainWaveList

//****************************************************************
//****************************************************************

Function /S NMMainWaveList( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, fullPath, compact, printToHistory ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	Variable fullPath // print full-path names ( 0 ) no ( 1 ) yes
	Variable compact // use compact list for wave names ( 0 ) no ( 1 )
	Variable printToHistory // ( 0 ) no, just return wave list ( 1 ) yes, print to history and return wave list
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( fullPath )
		NMLoopExecVarAdd( "fullPath", fullPath, nm, integer=1 )
	endif
	
	if ( compact )
		NMLoopExecVarAdd( "compact", compact, nm, integer=1 )
	endif
	
	if ( printToHistory )
		NMLoopExecVarAdd( "printToHistory", printToHistory, nm, integer=1 )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	//nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainWaveList

//****************************************************************
//****************************************************************

Function /S NMMainWaveList2([ folder, wavePrefix, chanNum, waveSelect, fullPath, compact, printToHistory ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	Variable fullPath // print full-path names ( 0 ) no ( 1 ) yes
	Variable compact // use compact list for wave names ( 0 ) no ( 1 )
	Variable printToHistory // ( 0 ) no, just return wave list ( 1 ) yes, print to history and return wave list
	
	String fxn = "NMWaveList"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif

	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm, fullPath=1 ) != 0 )
		return ""
	endif
	
	nm.successList = nm.wList
	
	if ( printToHistory )
		NMLoopHistory( nm, includeWaveNames=1, fullPath=fullPath, compact=compact, SkipFailures=1 )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.wList )
	
	return nm.wList
	
End // NMMainWaveList2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainFindMissingSeqNums()

	Variable lastNum, numWaves
	String wName

	String wList = NMChanWaveList( -1 )
	
	numWaves = ItemsInList( wList )
	
	if ( numWaves > 0 )
		wName = StringFromList( numWaves - 1, wList )
		lastNum = GetSeqNum( wName )
	endif

	Variable firstNum = NumVarOrDefault( NMMainDF + "FindMissingSeqFirst", 0 )
	Variable seqStep = NumVarOrDefault( NMMainDF + "FindMissingSeqStep", 1 )
	
	Prompt firstNum, "sequence should begin with:"
	Prompt lastNum, "sequence should end with:"
	Prompt seqStep, "sequence should have step size of:"
	DoPrompt NMPromptStr( "NM Find Missing Wave Sequence Numbers" ), firstNum, lastNum, seqStep
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMvar( NMMainDF + "FindMissingSeqFirst", firstNum )
	SetNMvar( NMMainDF + "FindMissingSeqStep", seqStep )

	return NMMainFindMissingSeqNums( firstNum=firstNum, lastNum=lastNum, seqStep=seqStep, history=1 )
	
End // zCall_NMMainFindMissingSeqNums

//****************************************************************
//****************************************************************

Function /S NMMainFindMissingSeqNums( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, firstNum, lastNum, seqStep ] )
	String folderList // NM folder list ( e.g. "nmFolder0;nmFolder1;" or "All" )
	String wavePrefixList // wave prefix list ( e.g. "Record;Wave;" )
	String chanSelectList // channel select list ( e.g. "A;B;" or "All" )
	String waveSelectList // wave select list ( e.g. "All" or "Set1;Set2;" or "All Sets" )
	Variable history // print function call command to history
	Variable deprecation // print deprecation alert
	
	Variable firstNum // first number of sequence, pass nothing for do not care
	Variable lastNum // last number of sequence, pass nothing for do not care
	Variable seqStep // sequence step, default 1
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( !ParamIsDefault( firstNum ) )
		NMLoopExecVarAdd( "firstNum", firstNum, nm, integer=1 )
	endif
	
	if ( !ParamIsDefault( lastNum ) )
		NMLoopExecVarAdd( "lastNum", lastNum, nm, integer=1 )
	endif
	
	if ( !ParamIsDefault( seqStep ) )
		NMLoopExecVarAdd( "seqStep", seqStep, nm, integer=1 )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	//nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation ) // loop thru lists

End // NMMainFindMissingSeqNums

//****************************************************************
//****************************************************************

Function /S NMMainFindMissingSeqNums2( [ folder, wavePrefix, chanNum, waveSelect, firstNum, lastNum, seqStep, quiet ] )
	String folder // e.g. "nmFolder0"
	String wavePrefix // wave prefix ( e.g. "Record" )
	Variable chanNum // channel number
	String waveSelect // wave select ( e.g. "All" or "Set1" )
	
	Variable firstNum // first number of sequence, pass nothing for do not care
	Variable lastNum // last number of sequence, pass nothing for do not care
	Variable seqStep // sequence step, default 1
	Variable quiet
	
	Variable found
	String txt, fxn = "NMFindMissingSeqNums"
	
	STRUCT NMParams nm
	NMParamsNull( nm )
	
	if ( ParamIsDefault( firstNum ) )
		firstNum = NaN
	endif
	
	if ( ParamIsDefault( seqStep ) )
		seqStep = 1
	endif
	
	if ( ParamIsDefault( lastNum ) )
		lastNum = NaN
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	if ( ItemsInList( nm.wList ) > 1 )
	
		nm.newList = NMFindMissingSeqNums( nm.wList, firstNum=firstNum, lastNum=lastNum, seqStep=seqStep )
		nm.successList = nm.wList
		
		if ( !quiet )
		
			found = ItemsInList( nm.newList )
		
			txt = NMLoopHistory( nm, quiet=1 )
			
			if ( found == 0 )
				txt += " : found no missing seq numbers"
			else
				txt += " : found " + num2istr( found ) + " missing seq numbers " + nm.newList
			endif
		
			NMHistory( txt )
			
		endif
		
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.newList )
	
	return nm.newList
	
End // NMMainFindMissingSeqNums2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainLabelX()

	Variable numChannels = NMNumChannels()
	
	String chanSelect = NMChanSelectStr()
	String waveSelect = NMWaveSelectGet()
	String promptStr = NMPromptStr( "NM X-Axis Label" )
	String promptStr2 = zError_AllChanWavesPromptStr( promptStr )
	
	if ( StringMatch( promptStr2, NMCancel ) )
	
		return ""
		
	elseif ( strlen( promptStr2 ) > 0 )
	
		promptStr = promptStr2
		
		if ( numChannels > 1 )
			chanSelect = "All"
		endif
		
		waveSelect = "All+" // all possible channel waves

	endif
	
	String xLabel = NMChanLabelX()
	
	if ( strlen( xLabel ) == 0 )
		xLabel = NMXunits
	endif
	
	Prompt xLabel, "label:"
	DoPrompt promptStr, xLabel
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	return NMMainLabel( chanSelectList=chanSelect, waveSelectList=waveSelect, xLabel=xLabel, history=1 )
	
End // zCall_NMMainLabelX

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainLabelY()

	Variable numChannels = NMNumChannels()
	
	String chanSelect = NMChanSelectStr()
	String waveSelect = NMWaveSelectGet()
	String promptStr = NMPromptStr( "NM Y-Axis Label" )
	String promptStr2 = zError_AllChanWavesPromptStr( promptStr, ignoreChannels=1 )
	
	if ( StringMatch( promptStr2, NMCancel ) )
	
		return ""
		
	elseif ( strlen( promptStr2 ) > 0 )
	
		promptStr = promptStr2
		
		waveSelect = "All+" // all possible channel waves

	endif
	
	String yLabel = NMChanLabelY()
	
	Prompt yLabel, "label:"
	DoPrompt promptStr, yLabel
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	return NMMainLabel( chanSelectList=chanSelect, waveSelectList=waveSelect, yLabel=yLabel, history=1 )
	
End // zCall_NMMainLabelY

//****************************************************************
//****************************************************************

Function /S NMMainLabel( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, xLabel, yLabel ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	String xLabel // x-axis label ( e.g. "time (ms)" )
	String yLabel // y-axis label ( e.g. "current (pA)" )
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	Variable xFlag, yFlag
	
	if ( !ParamIsDefault( xLabel ) )
		xFlag = 1
		NMLoopExecStrAdd( "xLabel", xLabel, nm )
	endif
	
	if ( !ParamIsDefault( yLabel ) )
		yFlag = 1
		NMLoopExecStrAdd( "yLabel", yLabel, nm )
	endif
	
	if ( !xFlag && !yFlag )
		return "" // nothing to do
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		if ( xFlag && !yFlag )
			chanSelectList = "All"
		else
			chanSelectList = ""
		endif
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = "All+" // all possible channel waves
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	nm.updateGraphs = 1
	nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainLabel

//****************************************************************
//****************************************************************

Function /S NMMainLabel2( [ folder, wavePrefix, chanNum, waveSelect, xLabel, yLabel ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum

	String xLabel // x-axis label ( e.g. "time (ms)" )
	String yLabel // y-axis label ( e.g. "current (pA)" )
	
	Variable xFlag, yFlag
	String fxn = "NMLabel"
	
	STRUCT NMParams nm
	
	if ( !ParamIsDefault( xLabel ) )
		xFlag = 1
	endif
	
	if ( !ParamIsDefault( yLabel ) )
		yFlag = 1
	endif
	
	if ( !xFlag && !yFlag )
		return "" // nothing to do
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = "All+" // all possible channel waves
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	if ( xFlag && yFlag )
		return NMLabel2( nm, xLabel=xLabel, yLabel=yLabel, history=1 )
	elseif ( xFlag )
		return NMLabel2( nm, xLabel=xLabel, history=1 )
	elseif ( yFlag )
		return NMLabel2( nm, yLabel=yLabel, history=1 )
	else
		return ""
	endif
	
End // NMMainLabel2

//****************************************************************
//****************************************************************
//
//		X-Scale Functions
//		Align, SetScale, Redimension, etc
//
//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainAlign()

	Variable alignAt, statsPrompt, restrictToCurrentPrefix = 0
	String txt, optionsStr, statsFolderList, statsFolderPath, wList
	String promptStr = NMPromptStr( "NM StartX Alignment" )
	
	if ( WaveExists( $NMXwave( waveNum=0 ) ) )
		return NMXWaveFunctionError( title=promptStr )
	endif
	
	Variable numWaves = NMNumWaves()
	
	String currentFolder = CurrentNMFolder( 1 )
	
	String wName = StrVarOrDefault( NMMainDF + "AlignWName", "" )
	String statsFolder = StrVarOrDefault( NMMainDF + "AlignFolder", "" )
	String wNameStats = StrVarOrDefault( NMMainDF + "AlignWNameStats", "" )
	String select = StrVarOrDefault( NMMainDF + "AlignAtSelect", "zero" )
	
	optionsStr = NMWaveListOptions( numWaves, 0 )
	
	wList = WaveList( "*", ";", optionsStr )
	
	statsFolderList = NMSubfolderList2( currentFolder, "Stats_", 0, restrictToCurrentPrefix )
	
	if ( ( ItemsInList( wList ) == 0 ) && ( ItemsInList( statsFolderList ) == 0 ) )
	
		txt = "There are no waves in the current data folder with the appropriate length. "
		txt += "Waves with alignment values must equal the number of waves per channel "
		txt += "which for prefix " + NMQuotes( CurrentNMWavePrefix() ) + " is " + num2istr( numWaves ) + "."
	
		DoAlert /T=( promptStr ) 0, txt
	
		return ""
		
	endif
	
	Prompt wName, "select a wave of alignment values:", popup " ;" + wList
	Prompt select, "align at:", popup NMAlignAtList
	
	if ( ItemsInList( statsFolderList ) == 0 )
		
		DoPrompt promptStr, wName, select
	
		if ( ( V_flag == 1 ) || StringMatch( wName, " " ) )
			return "" // cancel
		endif
		
		SetNMstr( NMMainDF + "AlignWName", wName )
	
	elseif ( ItemsInList( wList ) == 0 )
	
		Prompt statsFolder, "select a Stats subfolder that contains a wave of alignment values:", popup " ;" + StatsFolderList
		DoPrompt promptStr, statsFolder
	
		if ( ( V_flag == 1 ) || StringMatch( statsFolder, " " ) )
			return "" // cancel
		endif
		
		statsPrompt = 1
	
	else
	
		if ( strlen( statsFolder ) > 1 )
			wName = ""
		endif
	
		Prompt statsFolder, "or select a Stats subfolder that contains a wave of alignment values:", popup " ;" + StatsFolderList
		DoPrompt promptStr, wName, statsFolder, select
	
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		if ( !StringMatch( statsFolder, " " ) )
			statsPrompt = 1
		elseif ( !StringMatch( wName, " " ) )
			SetNMstr( NMMainDF + "AlignWName", wName )
		else
			return ""
		endif
	
	endif
	
	if ( statsPrompt )
	
		SetNMstr( NMMainDF + "AlignFolder", statsFolder )
	
		statsFolderPath = currentFolder + statsFolder + ":"
		
		wList = NMStatsWaveListOfType( statsFolderPath, optionsStr, "X" )
		
		if ( ItemsInList( wList ) == 0 )
			DoAlert /T=( promptStr ) 0, "Found no appropriate waves in Stats subfolder " + statsFolder
			return ""
		endif
		
		wName = wNameStats
		
		Prompt wName, "select a wave of alignment values:", popup " ;" + wList
		DoPrompt promptStr, wName, select
	
		if ( ( V_flag == 1 ) || StringMatch( wName, " " ) )
			return "" // cancel
		endif
	
		SetNMstr( NMMainDF + "AlignWNameStats", wName )
		
		wName = statsFolderPath + wName
		
	else
	
		SetNMstr( NMMainDF + "AlignFolder", "" )
		
	endif
	
	SetNMstr( NMMainDF + "AlignAtSelect", select )
	
	alignAt = NMAlignAtValue( select, wName )
	
	wName = ReplaceString( currentFolder, wName, "" )
	
	return NMMainAlign( waveOfAlignValues=wName, alignAt=alignAt, history=1 )

End // zCall_NMMainAlign

//****************************************************************
//****************************************************************

Function /S NMMainAlign( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, waveOfAlignValues, alignAt, printToHistory ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	String waveOfAlignValues // wave of x-alignment values
	Variable alignAt // where on x-axis to align waves
	Variable printToHistory // ( 0 ) no history ( 1 ) print basic results to history ( 2 ) print basic results and wave-by-wave scaling operations
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( waveOfAlignValues ) || ( strlen( waveOfAlignValues ) == 0 ) )
		return NM2ErrorStr( 21, "waveOfAlignValues", "" )
	endif
	
	NMLoopExecStrAdd( "waveOfAlignValues", waveOfAlignValues, nm )
	
	if ( numtype( alignAt ) > 0 )
		return NM2ErrorStr( 10, "alignAt", num2str( alignAt ) )
	endif
	
	if ( !ParamIsDefault( alignAt ) )
		NMLoopExecVarAdd( "alignAt", alignAt, nm )
	endif
	
	if ( !ParamIsDefault( printToHistory ) )
		NMLoopExecVarAdd( "printToHistory", printToHistory, nm, integer=1 )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	nm.updateGraphs = 1
	nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainAlign

//****************************************************************
//****************************************************************

Function /S NMMainAlign2( [ folder, wavePrefix, chanNum, waveSelect, waveOfAlignValues, alignAt, printToHistory ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	String waveOfAlignValues // wave of x-alignment values
	Variable alignAt // where on x-axis to align waves
	Variable printToHistory // ( 0 ) no history ( 1 ) print basic results to history ( 2 ) print basic results and wave-by-wave scaling operations
	
	String fxn = "NMAlign"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( waveOfAlignValues ) || ( strlen( waveOfAlignValues ) == 0 ) )
		return NM2ErrorStr( 21, "waveOfAlignValues", "" )
	endif
	
	if ( numtype( alignAt ) > 0 )
		return NM2ErrorStr( 10, "alignAt", num2str( alignAt ) )
	endif
	
	if ( ParamIsDefault( printToHistory ) )
		printToHistory = 1
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif

	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	return NMAlign2( nm, waveOfAlignValues, alignAt=alignAt, history=printToHistory )
	
End // NMMainAlign2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainStartX()

	Variable icnt
	String wList, optionsStr
	
	String promptStr = NMPromptStr( "NM X-Axis Start" )
	
	if ( WaveExists( $NMXwave( waveNum=0 ) ) )
		return NMXWaveFunctionError( title=promptStr )
	endif
	
	String promptStr2 = zError_AllChanWavesPromptStr( promptStr )

	Variable numChannels = NMNumChannels()
	Variable numWaves = NMNumWaves()
	
	String chanSelect = NMChanSelectStr()
	String waveSelect = NMWaveSelectGet()
	
	if ( StringMatch( promptStr2, NMCancel ) )
	
		return ""
		
	elseif ( strlen( promptStr2 ) > 0 )
	
		promptStr = promptStr2
		
		if ( numChannels > 1 )
			chanSelect = "All"
		endif
		
		waveSelect = "All+" // all possible channel waves
		
	endif
	
	Variable startx = NumVarOrDefault( NMMainDF + "StartX", 0 )
	String startWaveName = StrVarOrDefault( NMMainDF + "StartWaveName", "" )
	
	wList = ""
	
	optionsStr = NMWaveListOptions( numWaves, 0 )
	
	wList = WaveList( "*", ";", optionsStr )
	
	Prompt startx, NMPromptAddUnitsX( "x-axis start" )
	Prompt startWaveName, "or choose a wave of x-axis start values", popup " ;" + wList
	DoPrompt promptStr, startx, startWaveName
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( ( strlen( startWaveName ) > 0 ) && !StringMatch( startWaveName, " " ) )
	
		SetNMstr( NMMainDF + "StartWaveName", startWaveName )
	
		return NMMainSetScale( chanSelectList=chanSelect, waveSelectList=waveSelect, startWaveName=startWaveName, history=1 )
	
	else
	
		SetNMvar( NMMainDF + "StartX", startx )
		
		return NMMainSetScale( chanSelectList=chanSelect, waveSelectList=waveSelect, start=startx, history=1 )
		
	endif
	
End // zCall_NMMainStartX

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainDeltaX()

	Variable all
	
	String promptStr = NMPromptStr( "NM X-Axis Delta" )
	
	if ( WaveExists( $NMXwave( waveNum=0 ) ) )
		return NMXWaveFunctionError( title=promptStr )
	endif
	
	String promptStr2 = zError_AllChanWavesPromptStr( promptStr )

	Variable numChannels = NMNumChannels()
	
	String chanSelect = NMChanSelectStr()
	String waveSelect = NMWaveSelectGet()
	
	if ( StringMatch( promptStr2, NMCancel ) )
	
		return ""
		
	elseif ( strlen( promptStr2 ) > 0 )
	
		promptStr = promptStr2
		
		if ( numChannels > 1 )
			chanSelect = "All"
		endif
		
		waveSelect = "All+" // all possible channel waves
		
		all = 1
		
	endif

	Variable dx = zError_DeltaX( all, "NMDeltaX" )
	
	if ( numtype( dx ) > 0 )
		return "" // cancel
	endif
	
	Prompt dx, NMPromptAddUnitsX( "x-axis delta:" )
	DoPrompt promptStr, dx
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	return NMMainSetScale( chanSelectList=chanSelect, waveSelectList=waveSelect, delta=dx, history=1 )
	
End // zCall_NMMainDeltaX

//****************************************************************
//****************************************************************

Function /S NMDeltaXAllCall( dx ) // does all channels and waves
	Variable dx
	
	Variable all = 1
	
	if ( numtype( dx ) > 0 )
		UpdateNMPanel( 1 )
		return ""
	endif

	Variable dx2 = zError_DeltaX( all, "NMXScaleWavesAll" )
	
	if ( numtype( dx2 ) > 0 )
		UpdateNMPanel( 1 )
		return "" // user cancel
	endif
	
	return NMMainSetScale( delta=dx, history=1 )
	
End // NMDeltaXAllCall

//****************************************************************
//****************************************************************

Function /S NMMainSetScale( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, dim, start, startWaveName, delta ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	String dim // dimension ( e.g. "x" or "y" or "z" )
	Variable start // axis start
	String startWaveName // name of wave containing start values
	Variable delta // axis delta
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( !ParamIsDefault( dim ) )
		NMLoopExecStrAdd( "dim", dim, nm )
	endif
	
	if ( ParamIsDefault( start ) )
		start = NaN
	else
		NMLoopExecVarAdd( "start", start, nm )
	endif
	
	if ( ParamIsDefault( startWaveName ) )
		startWaveName = ""
	else
		NMLoopExecStrAdd( "startWaveName", startWaveName, nm )
	endif
	
	if ( ParamIsDefault( delta ) )
		delta = NaN
	else
		NMLoopExecVarAdd( "delta", delta, nm )
	endif
	
	if ( ( numtype( start ) > 0 ) && ( numtype( delta ) > 0 ) && ( strlen( startWaveName ) == 0 ) )
		return "" // nothing to do
	endif
	
	if ( ( numtype( delta ) == 0 ) && ( delta <= 0 ) )
		return NM2ErrorStr( 10, "delta", num2str( delta ) )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = "All"
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = "All+" // all possible channel waves
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	nm.updateGraphs = 1
	nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainSetScale

//****************************************************************
//****************************************************************

Function /S NMMainSetScale2( [ folder, wavePrefix, chanNum, waveSelect, dim, start, startWaveName, delta ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	String dim // dimension ( e.g. "x" or "y" or "z" )
	Variable start // x-axis start
	String startWaveName // name of wave containing start values
	Variable delta // axis delta
	
	String fxn = "NMSetScale"
	
	STRUCT NMParams nm
	
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
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = "All+" // all possible channel waves
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	if ( strlen( startWaveName ) > 0 )
	
		if ( strlen( dim ) > 0 )
			return NMSetScale2( nm, dim=dim, startWaveName=startWaveName, delta=delta, history=1 )
		else
			return NMSetScale2( nm, startWaveName=startWaveName, delta=delta, history=1 )
		endif
	
	endif
	
	if ( strlen( dim ) > 0 )
		return NMSetScale2( nm, dim=dim, start=start, delta=delta, history=1 )
	else
		return NMSetScale2( nm, start=start, delta=delta, history=1 )
	endif
	
End // NMMainSetScale2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainRedimension()

	Variable numChannels = NMNumChannels()
	
	String chanSelect = NMChanSelectStr()
	String waveSelect = NMWaveSelectGet()
	String promptStr = NMPromptStr( "NM Redimension" )
	String promptStr2 = zError_AllChanWavesPromptStr( promptStr )
	
	String xWave = NMXwave( waveNum=0 )
	
	if ( WaveExists( $xWave ) )
	
		DoAlert /T=( promptStr ) 1, "Encountered x-scale wave, but this function will create XY-paired waves unequal in size. Do you want to continue?"
	
		if ( V_flag != 1 )
			return ""
		endif
	
	endif
	
	if ( StringMatch( promptStr2, NMCancel ) )
	
		return ""
		
	elseif ( strlen( promptStr2 ) > 0 )
	
		promptStr = promptStr2
		
		if ( numChannels > 1 )
			chanSelect = "All"
		endif
		
		waveSelect = "All+" // all possible channel waves
		
	endif
	
	Variable value = NumVarOrDefault( NMMainDF + "RedimensionValue", NaN )
	Variable minNumPnts = GetXstats( "minNumPnts" , NMWaveSelectList( -1 ) )
	Variable points = minNumPnts
	
	if ( points < 0 )
		points = 100
	endif
	
	Prompt points, "number of wave points:"
	DoPrompt promptStr, points

	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( points > minNumPnts )
	
		Prompt value, "value to give new wave points:"
		DoPrompt promptStr, value
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		SetNMvar( NMMainDF + "RedimensionValue", value )
		
		return NMMainRedimension( chanSelectList=chanSelect, waveSelectList=waveSelect, points=points, value=value, history=1 )
		
	else
	
		return NMMainRedimension( chanSelectList=chanSelect, waveSelectList=waveSelect, points=points, history=1 )
	
	endif
	
End // zCall_NMMainRedimension

//****************************************************************
//****************************************************************

Function /S NMMainRedimension( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, points, value ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	Variable points // number of wave points
	Variable value // value to give new wave points
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( points ) )
		return NM2ErrorStr( 11, "points", "" )
	endif
	
	NMLoopExecVarAdd( "points", points, nm, integer=1 )
	
	if ( ( numtype( points ) > 0 ) || ( points < 0 ) )
		return NM2ErrorStr( 10, "points", num2str( points ) )
	endif
	
	if ( !ParamIsDefault( value ) )
		NMLoopExecVarAdd( "value", value, nm )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = "All"
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = "All+" // all possible channel waves	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainRedimension

//****************************************************************
//****************************************************************

Function /S NMMainRedimension2( [ folder, wavePrefix, chanNum, waveSelect, points, value ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	Variable points // number of wave points
	Variable value // value to give new wave points
	
	String fxn = "NMRedimension"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( points ) )
		return NM2ErrorStr( 11, "points", "" )
	endif
	
	if ( ( numtype( points ) > 0 ) || ( points < 0 ) )
		return NM2ErrorStr( 10, "points", num2str( points ) )
	endif
	
	if ( ParamIsDefault( value ) )
		value = NaN
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = "All+" // all possible channel waves
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	return NMRedimension2( nm, points, value=value, history=1 )
	
End // NMMainRedimension2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainDeletePoints()
	
	Variable numChannels = NMNumChannels()
	
	String xWave = NMXwave( waveNum=0 )
	
	String chanSelect = NMChanSelectStr()
	String waveSelect = NMWaveSelectGet()
	String promptStr = NMPromptStr( "NM Delete Points" )
	String promptStr2 = zError_AllChanWavesPromptStr( promptStr )
	
	if ( WaveExists( $xWave ) )
	
		DoAlert /T=( promptStr ) 1, "Encountered x-scale wave, but this function will create XY-paired waves unequal in size. Do you want to continue?"
	
		if ( V_flag != 1 )
			return ""
		endif
	
	endif
	
	if ( StringMatch( promptStr2, NMCancel ) )
	
		return ""
		
	elseif ( strlen( promptStr2 ) > 0 )
	
		promptStr = promptStr2
		
		if ( numChannels > 1 )
			chanSelect = "All"
		endif
		
		waveSelect = "All+" // all possible channel waves
		
	endif

	Variable from = NumVarOrDefault( NMMainDF + "DeletePointsFrom", 0 )
	Variable points = NumVarOrDefault( NMMainDF + "DeletePoints", 1 )
	
	Prompt from, "delete starting at point:"
	Prompt points, "number of points to delete:"
	DoPrompt promptStr, from, points
	
	if ( V_flag == 1 )
		return "" // cancel
	endif

	SetNMvar( NMMainDF + "DeletePointsFrom", from )
	SetNMvar( NMMainDF + "DeletePoints", points )
	
	return NMMainDeletePoints( chanSelectList=chanSelect, waveSelectList=waveSelect, from=from, points=points, history=1 )

End // zCall_NMMainDeletePoints

//****************************************************************
//****************************************************************

Function /S NMMainDeletePoints( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, from, points ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	Variable from // delete points from this point
	Variable points // number of points to delete
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( from ) )
		return NM2ErrorStr( 11, "from", "" )
	endif
	
	if ( ParamIsDefault( points ) )
		return NM2ErrorStr( 11, "points", "" )
	endif
	
	if ( NMDeletePointsError( from, points ) != 0 )
		return ""
	endif
	
	NMLoopExecVarAdd( "from", from, nm, integer=1 )
	NMLoopExecVarAdd( "points", points, nm, integer=1 )
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = "All"
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = "All+" // all possible channel waves
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainDeletePoints

//****************************************************************
//****************************************************************

Function /S NMMainDeletePoints2( [ folder, wavePrefix, chanNum, waveSelect, from, points ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	Variable from // delete points starting from this point
	Variable points // number of points to delete
	
	String fxn = "NMDeletePoints"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( from ) )
		return NM2ErrorStr( 11, "from", "" )
	endif
	
	if ( ParamIsDefault( points ) )
		return NM2ErrorStr( 11, "points", "" )
	endif
	
	if ( NMDeletePointsError( from, points ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = "All+" // all possible channel waves
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	return NMDeletePoints2( nm, from, points, history=1 )
	
End // NMMainDeletePoints2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainInsertPoints()
	
	Variable numChannels = NMNumChannels()
	
	String xWave = NMXwave( waveNum=0 )
	
	String chanSelect = NMChanSelectStr()
	String waveSelect = NMWaveSelectGet()
	String promptStr = NMPromptStr( "NM Insert Points" )
	String promptStr2 = zError_AllChanWavesPromptStr( promptStr )
	
	if ( WaveExists( $xWave ) )
	
		DoAlert /T=( promptStr ) 1, "Encountered x-scale wave, but this function will create XY-paired waves unequal in size. Do you want to continue?"
	
		if ( V_flag != 1 )
			return ""
		endif
	
	endif
	
	if ( StringMatch( promptStr2, NMCancel ) )
	
		return ""
		
	elseif ( strlen( promptStr2 ) > 0 )
	
		promptStr = promptStr2
		
		if ( numChannels > 1 )
			chanSelect = "All"
		endif
		
		waveSelect = "All+" // all possible channel waves
		
	endif

	Variable at = NumVarOrDefault( NMMainDF + "InsertPointsAt", 0 )
	Variable points = NumVarOrDefault( NMMainDF + "InsertPoints", 1 )
	Variable value = NumVarOrDefault( NMMainDF + "InsertPointsValue", NaN )
	
	Prompt at, "insert points starting at point:"
	Prompt points, "number of points to insert:"
	Prompt value, "value of inserted points:"
	DoPrompt promptStr, at, points, value

	if ( V_flag == 1 )
		return "" // cancel
	endif

	SetNMvar( NMMainDF + "InsertPointsAt", at )
	SetNMvar( NMMainDF + "InsertPoints", points )
	SetNMvar( NMMainDF + "InsertPointsValue", value )
	
	return NMMainInsertPoints( chanSelectList=chanSelect, waveSelectList=waveSelect, at=at, points=points, value=value, history=1 )
	
End // zCall_NMMainInsertPoints

//****************************************************************
//****************************************************************

Function /S NMMainInsertPoints( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, at, points, value ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	Variable at // insert points starting at this point
	Variable points // number of points to insert
	Variable value // value of new inserted points
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( at ) )
		return NM2ErrorStr( 11, "at", "" )
	endif
	
	if ( ParamIsDefault( points ) )
		return NM2ErrorStr( 11, "points", "" )
	endif
	
	if ( NMInsertPointsError( at, points ) != 0 )
		return ""
	endif
	
	NMLoopExecVarAdd( "at", at, nm, integer=1 )
	NMLoopExecVarAdd( "points", points, nm, integer=1 )
	
	if ( !ParamIsDefault( value ) )
		NMLoopExecVarAdd( "value", value, nm )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = "All"
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = "All+" // all possible channel waves	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainInsertPoints

//****************************************************************
//****************************************************************

Function /S NMMainInsertPoints2( [ folder, wavePrefix, chanNum, waveSelect, at, points, value ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	Variable at // insert points starting at this point
	Variable points // number of points to insert
	Variable value // value of new inserted points
	
	String fxn = "NMInsertPoints"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( at ) )
		return NM2ErrorStr( 11, "at", "" )
	endif
	
	if ( ParamIsDefault( points ) )
		return NM2ErrorStr( 11, "points", "" )
	endif
	
	if ( NMInsertPointsError( at, points ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( value ) )
		value = NaN
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = "All+" // all possible channel waves
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	return NMInsertPoints2( nm, at, points, value=value, history=1 )
	
End // NMMainInsertPoints2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainResample()

	Variable all

	String promptStr = NMPromptStr( "NM Resample" )
	
	if ( WaveExists( $NMXwave( waveNum=0 ) ) )
		return NMXWaveFunctionError( title=promptStr )
	endif
	
	String promptStr2 = zError_AllChanWavesPromptStr( promptStr )
	
	Variable numChannels = NMNumChannels()
	
	String chanSelect = NMChanSelectStr()
	String waveSelect = NMWaveSelectGet()
	
	if ( StringMatch( promptStr2, NMCancel ) )
	
		return ""
		
	elseif ( strlen( promptStr2 ) > 0 )
	
		promptStr = promptStr2
		
		if ( numChannels > 1 )
			chanSelect = "All"
		endif
		
		waveSelect = "All+" // all possible channel waves
		
		all = 1
		
	endif
	
	Variable dx = zError_DeltaX( all, "Resample" )
	
	if ( numtype( dx ) > 0 )
		return "" // user cancel
	endif
	
	Variable upSamples = 1
	Variable downSamples = 1
	Variable oldRate = 1 / dx
	Variable rate = oldRate
	
	Prompt upSamples, "resample UP by x number of points:"
	Prompt downSamples, "resample DOWN by x number of points:"
	Prompt rate, NMPromptAddUnitsX( "or specify a new sample rate", hz=1 )
	
	DoPrompt promptStr, upSamples, downSamples, rate
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( rate != oldRate )
		return NMMainResample( chanSelectList=chanSelect, waveSelectList=waveSelect, rate=rate, history=1 )
	elseif ( ( upSamples >= 1 ) && ( downSamples >= 1 ) )
		return NMMainResample( chanSelectList=chanSelect, waveSelectList=waveSelect, upSamples=upSamples, downSamples=downSamples, history=1 )
	else
		return ""
	endif

End // zCall_NMMainResample

//****************************************************************
//****************************************************************

Function /S NMMainResample( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, upSamples, downSamples, rate ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	Variable upSamples // interpolate points, or nothing for no change
	Variable downSamples // decimate points, or nothing for no change
	Variable rate // sample rate
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( upSamples ) )
		upSamples = 1
	else
		NMLoopExecVarAdd( "upSamples", upSamples, nm, integer=1 )
	endif
	
	if ( ParamIsDefault( downSamples ) )
		downSamples = 1
	else
		NMLoopExecVarAdd( "downSamples", downSamples, nm, integer=1 )
	endif
	
	if ( ParamIsDefault( rate ) )
		if ( ( upSamples == 1 ) && ( downSamples == 1 ) )
			return "" // nothing to do
		endif
	else
		NMLoopExecVarAdd( "rate", rate, nm )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = "All"
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = "All+" // all possible channel waves	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	nm.updateGraphs = 1
	nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainResample

//****************************************************************
//****************************************************************

Function /S NMMainResample2( [ folder, wavePrefix, chanNum, waveSelect, upSamples, downSamples, rate ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	Variable upSamples // interpolate points, or nothing for no change
	Variable downSamples // or decimate points, or nothing for no change
	Variable rate // or sample rate
	
	String fxn = "NMResample"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( upSamples ) )
		upSamples = 1
	endif
	
	if ( ParamIsDefault( downSamples ) )
		downSamples = 1
	endif
	
	if ( ParamIsDefault( rate ) )
	
		if ( ( upSamples == 1 ) && ( downSamples == 1 ) )
			return "" // nothing to do
		endif
		
		rate = NaN
		
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = "All+" // all possible channel waves
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	return NMResample2( nm, upSamples=upSamples, downSamples=downSamples, rate=rate, history=1 )
	
End // NMMainResample2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainDecimate()

	Variable all
	
	String promptStr = NMPromptStr( "NM Decimate" )
	String promptStr2 = zError_AllChanWavesPromptStr( promptStr )
	
	Variable numChannels = NMNumChannels()
	
	String chanSelect = NMChanSelectStr()
	String waveSelect = NMWaveSelectGet()
	
	if ( StringMatch( promptStr2, NMCancel ) )
	
		return ""
		
	elseif ( strlen( promptStr2 ) > 0 )
	
		promptStr = promptStr2
		
		if ( numChannels > 1 )
			chanSelect = "All"
		endif
		
		waveSelect = "All+" // all possible channel waves
		
		all = 1
		
	endif
	
	Variable dx = zError_DeltaX( all, "Decimate" )
	
	if ( numtype( dx ) > 0 )
		return "" // cancel
	endif
	
	Variable downSamples = NumVarOrDefault( NMMainDF + "DecimateN", 4 )
	String alg = StrVarOrDefault( NMMainDF + "DecimateAlg", NMInterpolateAlg )
	
	Prompt downSamples, "decimate waves by x number of points:"
	Prompt alg, "interpolation method:", popup NMInterpolateAlgList
	DoPrompt promptStr, downSamples, alg
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMvar( NMMainDF + "DecimateN", downSamples )
	SetNMstr( NMMainDF + "DecimateAlg", alg )
	
	return NMMainDecimate( chanSelectList=chanSelect, waveSelectList=waveSelect, downSamples=downSamples, alg=alg, history=1 )

End // zCall_NMMainDecimate()

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainDecimate2()

	Variable all
	String xunits
	
	String promptStr = NMPromptStr( "NM Decimate" )
	String promptStr2 = zError_AllChanWavesPromptStr( promptStr )
	
	Variable numChannels = NMNumChannels()
	
	String chanSelect = NMChanSelectStr()
	String waveSelect = NMWaveSelectGet()
	
	if ( StringMatch( promptStr2, NMCancel ) )
	
		return ""
		
	elseif ( strlen( promptStr2 ) > 0 )
	
		promptStr = promptStr2
		
		if ( numChannels > 1 )
			chanSelect = "All"
		endif
		
		waveSelect = "All+" // all possible channel waves
		
		all = 1
		
	endif
	
	Variable oldDeltax = zError_DeltaX( all, "Decimate" )
	
	if ( numtype( oldDeltax ) > 0 )
		return "" // cancel
	endif
	
	Variable newDeltaX = NumVarOrDefault( NMMainDF + "DecimateDeltaX", oldDeltax )
	String alg = StrVarOrDefault( NMMainDF + "DecimateAlg", NMInterpolateAlg )
	
	xunits = NMChanLabelX( units=1 )
	
	Prompt newDeltaX, "new sample interval > " + num2str( oldDeltax ) + " " + xunits
	Prompt alg, "interpolation method:", popup NMInterpolateAlgList
	DoPrompt promptStr, newDeltaX, alg
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( newDeltaX <= oldDeltaX )
		DoAlert /T=( promptStr ) 0, "To decimate, the new sample interval must be larger than the old sample interval."
		return ""
	endif
	
	SetNMvar( NMMainDF + "DecimateDeltaX", newDeltaX )
	SetNMstr( NMMainDF + "DecimateAlg", alg )
	
	Variable rate = 1 / newDeltaX
	
	return NMMainDecimate( chanSelectList=chanSelect, waveSelectList=waveSelect, rate=rate, alg=alg, history=1 )

End // zCall_NMMainDecimate2

//****************************************************************
//****************************************************************

Function /S NMMainDecimate( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, downSamples, rate, algorithm, alg ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	Variable downSamples // number of points to down sample
	Variable rate // or new sample rate
	Variable algorithm // ( 1 ) linear ( 2 ) cubic spline ( 3 ) smoothing spline Interpolation
	String alg // "linear" or "cubic spline" or "smoothing spline"
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( downSamples ) )
	
		if ( ParamIsDefault( rate ) )
			return NM2ErrorStr( 11, "downSamples", "" )
		else
			NMLoopExecVarAdd( "rate", rate, nm )
		endif
	
	else
	
		NMLoopExecVarAdd( "downSamples", downSamples, nm, integer=1 )
		
	endif
	
	if ( ParamIsDefault( algorithm ) )
	
		if ( ParamIsDefault( alg ) )
			alg = NMInterpolateAlg
		endif
		
	else
	
		alg = NMInterpolateAlgStr( algorithm )
		
	endif
	
	NMLoopExecStrAdd( "alg", alg, nm )
	
	if ( NMDecimateError( alg, downSamples, rate ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = "All"
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = "All+" // all possible channel waves	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	nm.updateGraphs = 1
	nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainDecimate

//****************************************************************
//****************************************************************

Function /S NMMainDecimate2( [ folder, wavePrefix, chanNum, waveSelect, downSamples, rate, algorithm, alg ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	Variable downSamples // number of points
	Variable rate // or new rate
	Variable algorithm
	String alg
	
	Variable rateFlag
	String fxn = "NMDecimate"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( downSamples ) )
	
		if ( ParamIsDefault( rate ) || ( numtype( rate ) > 0 ) )
			return NM2ErrorStr( 11, "downSamples", "" )
		else
			rateFlag = 1
		endif
		
	endif
	
	if ( ParamIsDefault( algorithm ) )
	
		if ( ParamIsDefault( alg ) )
			alg = NMInterpolateAlg
		endif
		
	else
	
		alg = NMInterpolateAlgStr( algorithm )
		
	endif
	
	if ( NMDecimateError( alg, downSamples, rate ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = "All+" // all possible channel waves
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	if ( rateFlag )
		return NMDecimate2( nm, rate=rate, alg=alg, history=1 )
	else
		return NMDecimate2( nm, downSamples=downSamples, alg=alg, history=1 )
	endif
	
End // NMMainDecimate2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainInterpolate()

	String promptStr = NMPromptStr( "NM Interpolate" )
	String promptStr2 = zError_AllChanWavesPromptStr( promptStr )
	
	Variable numChannels = NMNumChannels()
	
	String chanSelect = NMChanSelectStr()
	String waveSelect = NMWaveSelectGet()
	
	if ( StringMatch( promptStr2, NMCancel ) )
	
		return ""
		
	elseif ( strlen( promptStr2 ) > 0 )
	
		promptStr = promptStr2
		
		if ( numChannels > 1 )
			chanSelect = "All"
		endif
		
		waveSelect = "All+" // all possible channel waves
		
	endif

	Variable npnts
	String optionsStr, wList = ""
	
	String alg = StrVarOrDefault( NMMainDF + "InterpolateAlg", NMInterpolateAlg )
	Variable xmode = NumVarOrDefault( NMMainDF + "InterpolateXMode", 1 )
	String xWaveNew = StrVarOrDefault( NMMainDF + "InterpolatexWaveNew", "" )
	
	Prompt alg, "interpolation method:", popup NMInterpolateAlgList
	Prompt xmode, "select x-axis for interpolation:" popup "use common x-axis computed by NeuroMatic;use x-axis of a selected wave;use data values of a selected wave;"
	
	DoPrompt promptStr, alg, xmode
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	switch( xmode )
	
		case 2:
		
			Prompt xWaveNew, "select wave to supply x-axis for interpolation:", popup WaveList( "*", ";", "" )
			
		case 3:
		
			npnts = NMWaveSelectXstats( "numpnts", -1 )
			optionsStr = NMWaveListOptions( npnts, 0 )
			
			if ( ( numtype( npnts ) == 0 ) && ( npnts > 0 ) )
				wList = " ;" + WaveList( "*", ";", optionsStr )
			endif
			
			Prompt xWaveNew, "select wave to supply data values for interpolation:", popup wList
			DoPrompt promptStr, xWaveNew
			
			if ( strlen( xWaveNew ) == 0 )
				return ""
			endif
			
	endswitch
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMstr( NMMainDF + "InterpolateAlg", alg )
	SetNMvar( NMMainDF + "InterpolateXMode", xmode )
	SetNMstr( NMMainDF + "InterpolatexWaveNew", xWaveNew )
	
	if ( xmode == 1 )
		return NMMainInterpolate( chanSelectList=chanSelect, waveSelectList=waveSelect, alg=alg, xmode=1, history=1 )
	else
		return NMMainInterpolate( chanSelectList=chanSelect, waveSelectList=waveSelect, alg=alg, xmode=xmode, xWaveNew=xWaveNew, history=1 )
	endif

End // zCall_NMMainInterpolate

//****************************************************************
//****************************************************************

Function /S NMMainInterpolate( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, algorithm, alg, xmode, xWaveNew ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	Variable algorithm // ( 1 ) linear ( 2 ) cubic spline ( 3 ) smoothing spline Interpolation
	String alg // "linear" or "cubic spline" or "smoothing spline"
	Variable xmode // ( 1 ) find common x-axis ( 2 ) use x-axis scale of xWaveNew ( 3 ) use values of xWaveNew as x-scale
	String xWaveNew // wave for xmode 2 or 3
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( algorithm ) )
	
		if ( ParamIsDefault( alg ) )
			alg = NMInterpolateAlg
		endif
		
	else
	
		alg = NMInterpolateAlgStr( algorithm )
		
	endif
	
	NMLoopExecStrAdd( "alg", alg, nm )
	
	if ( ParamIsDefault( xmode ) )
		xmode = 1
	else
		NMLoopExecVarAdd( "xmode", xmode, nm, integer=1 )
	endif
	
	if ( ParamIsDefault( xWaveNew ) )
		xWaveNew = ""
		xmode = 1
	else
		NMLoopExecStrAdd( "xWaveNew", xWaveNew, nm )
	endif
	
	if ( NMInterpolateError( alg, xmode, xWaveNew ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = "All"
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = "All+" // all possible channel waves	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	nm.updateGraphs = 1
	nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainInterpolate

//****************************************************************
//****************************************************************

Function /S NMMainInterpolate2( [ folder, wavePrefix, chanNum, waveSelect, algorithm, alg, xmode, xWaveNew ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	Variable algorithm // ( 1 ) linear ( 2 ) cubic spline ( 3 ) smoothing spline Interpolation
	String alg // "linear" or "cubic spline" or "smoothing spline"
	Variable xmode // ( 1 ) find common x-axis ( 2 ) use x-axis scale of xWaveNew ( 3 ) use point values of xWaveNew as x-scale
	String xWaveNew // wave for xmode 2 or 3
	
	String fxn = "NMInterpolate"
	
	STRUCT NMParams nm
	
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
		xmode = 1
	endif
	
	if ( NMInterpolateError( alg, xmode, xWaveNew ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = "All+" // all possible channel waves
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	if ( xmode == 1 )
		return NMInterpolate2( nm, alg=alg, xmode=1, history=1 )
	else
		return NMInterpolate2( nm, alg=alg, xmode=xmode, xWaveNew=xWaveNew, history=1 )
	endif
	
End // NMMainInterpolate2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainXScaleMode( mode )
	String mode // "episodic" or "continuous"
	
	Variable timeBetweenWaves
	String sdf
	
	if ( WaveExists( $NMXwave( waveNum=0 ) ) )
		return NMXWaveFunctionError()
	endif
	
	if ( StringMatch( mode, "continuous" ) )
	
		sdf = SubStimDF()
		
		if ( DataFolderExists( sdf ) )
			timeBetweenWaves = NumVarOrDefault( sdf + "InterStimTime", 0 )
		endif
	
		Prompt timeBetweenWaves, NMPromptAddUnitsX( "optional interlude between waves" )
		
		DoPrompt NMPromptStr( "NM Continuous X-Scale" ), timeBetweenWaves
	
		if ( V_flag == 1 )
			return "" // cancel
		endif
	
		if ( ( numtype( timeBetweenWaves ) == 0 ) && ( timeBetweenWaves > 0 ) )
			return NMMainXScaleMode( mode=mode, timeBetweenWaves=timeBetweenWaves, history=1 )
		endif
		
	endif
	
	return NMMainXScaleMode( mode=mode, history=1 )
	
End // zCall_NMMainXScaleMode

//****************************************************************
//****************************************************************

Function /S NMMainXScaleMode( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, mode, timeBetweenWaves ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	String mode // "episodic" or "continuous"
	Variable timeBetweenWaves // for continuous
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( !ParamIsDefault( mode ) )
		NMLoopExecStrAdd( "mode", mode, nm )
	endif
	
	if ( !ParamIsDefault( timeBetweenWaves ) && ( timeBetweenWaves != 0 ) )
		NMLoopExecVarAdd( "timeBetweenWaves", timeBetweenWaves, nm )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = "All"
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = "All+"	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	nm.updateGraphs = 1
	nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainXScaleMode

//****************************************************************
//****************************************************************

Function /S NMMainXScaleMode2( [ folder, wavePrefix, chanNum, waveSelect, mode, timeBetweenWaves ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	String mode // "episodic" or "continuous"
	Variable timeBetweenWaves // for continuous
	
	String fxn = "NMXscaleMode"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( mode ) )
		mode = "episodic"
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = "All+"
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	return NMXScaleMode2( nm, mode, timeBetweenWaves=timeBetweenWaves, history=1 )
	
End // NMMainXScaleMode2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainTimeScaleConvert( newUnits )
	String newUnits
	
	Variable icnt
	String oldUnits, unitsList
	
	String promptStr = NMPromptStr( "Time Scale Conversion" )
	
	if ( WaveExists( $NMXwave( waveNum=0 ) ) )
		return NMXWaveFunctionError( title=promptStr )
	endif
	
	unitsList = NMChanXUnitsList()
	unitsList = NMTimeUnitsListStandard( unitsList )
	
	icnt = ItemsInList( unitsList )
	
	if ( icnt == 0 )
	
		oldUnits = NMXunits
	
		Prompt oldUnits, "please select the current x-scale units of your data waves:", popup "sec;msec;usec;nsec;"

		DoPrompt NMPromptStr( "NM Unknown Timescale Units" ), oldUnits
	
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		NMMainLabel( xLabel=oldUnits, history=1 )
	
	elseif ( icnt == 1 )
	
		oldUnits = StringFromList( 0, unitsList )
		
		NMMainLabel( xLabel=oldUnits, history=1 )
	
	elseif ( icnt > 1 )
		
		DoAlert 1, "Warning: detected multiple x-scale units for currently selected waves ( " + unitsList + " ). Do you want to continue?"
		
		if ( V_flag != 1 )
			return "" // cancel
		endif
		
		oldUnits = StringFromList( 0, unitsList )
	
		Prompt oldUnits, "please select the current x-scale units of your data waves:", popup "sec;msec;usec;nsec;"

		DoPrompt NMPromptStr( "NM Found Multiple Timescale Units" ), oldUnits
	
		if ( V_flag == 1 )
			return "" // cancel
		endif
	
		NMMainLabel( xLabel=oldUnits, history=1 )
		
	else
	
		return ""
		
	endif
	
	if ( StringMatch( oldUnits, newUnits ) )
		return ""
	endif
		
	return NMMainTimeScaleConvert( oldUnits=oldUnits, newUnits=newUnits, history=1 )

End // zCall_NMMainTimeScaleConvert

//****************************************************************
//****************************************************************

Function /S NMMainTimeScaleConvert( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, oldUnits, newUnits ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	String oldUnits // old time scale units ( must specify )
	String newUnits // new time scale units ( must specify )
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( oldUnits ) || ( strlen( oldUnits ) == 0 ) )
		return NM2ErrorStr( 21, "oldUnits", "" )
	endif
	
	if ( ParamIsDefault( newUnits ) || ( strlen( newUnits ) == 0 ) )
		return NM2ErrorStr( 21, "newUnits", "" )
	endif
	
	if ( NMTimeScaleConvertError( oldUnits, newUnits ) != 0 )
		return ""
	endif
	
	NMLoopExecStrAdd( "oldUnits", oldUnits, nm )
	NMLoopExecStrAdd( "newUnits", newUnits, nm )
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = "All"
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = "All+"	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	nm.updateGraphs = 1
	nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainTimeScaleConvert

//****************************************************************
//****************************************************************

Function /S NMMainTimeScaleConvert2( [ folder, wavePrefix, chanNum, waveSelect, oldUnits, newUnits ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	String oldUnits // old time scale units
	String newUnits // new time scale units
	
	String fxn = "NMTimeScale"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( oldUnits ) || ( strlen( oldUnits ) == 0 ) )
		return NM2ErrorStr( 21, "oldUnits", "" )
	endif
	
	if ( ParamIsDefault( newUnits ) || ( strlen( newUnits ) == 0 ) )
		return NM2ErrorStr( 21, "newUnits", "" )
	endif
	
	if ( NMTimeScaleConvertError( oldUnits, newUnits ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = "All+"
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	return NMTimeScaleConvert2( nm, oldUnits, newUnits, history=1 )
	
End // NMMainTimeScaleConvert2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainXWaveMake()

	Variable singleXscale, nwaves, multiple = 1
	String wList
	
	String xWave = NMXwave( waveNum = 0 )
	String currentPrefix = CurrentNMWavePrefix()
	String newPrefix = NMXscalePrefix
		
	if ( WaveExists( $xWave ) )
	
		DoAlert 1, "X-scale wave for prefix " + NMQuotes( currentPrefix ) + " already exists: " + xWave + ". Do you want to make a new one?"
		
		if ( V_flag != 1 )
			return "" // cancel
		endif
		
	endif
	
	wList = NMWaveSelectList( -2 )
	nwaves = ItemsInList( wList )
	singleXscale = NMWavesHaveSingleXscale( wList )
	
	Prompt newPrefix, "prefix name for x-scale wave:"
	
	if ( singleXscale )
		Prompt multiple, " ", popup "create a single x-scale wave;create an x-scale wave for each data wave ( n=" + num2istr( nwaves ) + " );"
	else
		Prompt multiple, "your data waves have different x-scales so you must:", popup "create an x-scale wave for each data wave ( n=" + num2istr( nwaves ) + " );"
	endif
	
	DoPrompt "Make X-scale Waves", newPrefix, multiple
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( !singleXscale || ( multiple == 2 ) )
		return NMMainXWaveMake( newPrefix=newPrefix, multiple=1, overwrite=1, history=1 )
	else
		return NMMainXWaveMake( newPrefix=newPrefix, overwrite=1, history=1 )
	endif

End // zCall_NMMainXWaveMake

//****************************************************************
//****************************************************************

Function /S NMMainXWaveMake( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, newPrefix, multiple, overwrite ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	String newPrefix // e.g. "xScale_"
	Variable multiple // ( 0 ) make single x-scale wave if possible ( 1 ) make multiple x-scale waves
	Variable overwrite // ( 0 ) no ( 1 ) yes
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( !ParamIsDefault( newPrefix ) )
		NMLoopExecStrAdd( "newPrefix", newPrefix, nm )
	endif
	
	if ( multiple )
		NMLoopExecVarAdd( "multiple", multiple, nm, integer=1 )
	endif
	
	if ( overwrite )
		NMLoopExecVarAdd( "overwrite", overwrite, nm, integer=1 )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = "A"
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = "All+"	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	//nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainXWaveMake

//****************************************************************
//****************************************************************

Function /S NMMainXWaveMake2( [ folder, wavePrefix, chanNum, waveSelect, newPrefix, multiple, overwrite ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	String newPrefix // e.g. "xScale_"
	Variable multiple // ( 0 ) no, make single x-scale wave if possible ( 1 ) yes
	Variable overwrite // overwrite output wave if it already exists ( 0 ) no, alert user ( 1 ) yes
	
	String xWave, fxn = "NMXwave"
	
	STRUCT NMParams nm
	
	if ( ( ParamIsDefault( newPrefix ) || strlen( newPrefix ) == 0 ) )
		newPrefix = NMXscalePrefix	
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = 0 // first channel only
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = "All+"
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	if ( multiple )
	
		return NMXWaveMake2( nm, newPrefix=newPrefix, multiple=1, overwrite=overwrite, history=1 )
		
	else
	
		xWave = newPrefix + wavePrefix
		
		return NMXWaveMake2( nm, xWave=xWave, overwrite=overwrite, history=1 )
		
	endif
	
End // NMMainXWaveMake2

//****************************************************************
//****************************************************************
//
//	Operations
//	Baseline, Normalize, ScaleByNum, Smooth...
//
//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainBaseline( [ DFOF ] )
	Variable DFOF // ( 0 ) no ( 1 ) yes
	
	String promptStr = NMPromptStr( "NM Baseline Waves" )
	
	if ( DFOF )
		promptStr = NMPromptStr( "NM dF/Fo Baseline Waves" )
	endif
	
	Variable allWavesAvg = 1 + NumVarOrDefault( NMMainDF + "Bsln_AllWavesAvg", 0 )
	Variable xbgn = NumVarOrDefault( NMMainDF + "Bsln_Bgn", NMBaselineXbgn )
	Variable xend = NumVarOrDefault( NMMainDF + "Bsln_End", NMBaselineXend )
	
	Prompt xbgn, NMPromptAddUnitsX( "x-axis baseline window average begin" )
	Prompt xend, NMPromptAddUnitsX( "x-axis baseline window average end" )
	Prompt allWavesAvg, "subtract from each wave:", popup "its individual baseline value;the average baseline of all selected waves;"
	
	DoPrompt promptStr, xbgn, xend, allWavesAvg
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	allWavesAvg -= 1
	
	SetNMvar( NMMainDF + "Bsln_AllWavesAvg", allWavesAvg )
	SetNMvar( NMMainDF + "Bsln_Bgn", xbgn )
	SetNMvar( NMMainDF + "Bsln_End", xend )
	
	if ( DFOF )
	
		if ( allWavesAvg )
			return NMMainBaseline( xbgn=xbgn, xend=xend, allWavesAvg=1, DFOF=1, history=1 )
		else
			return NMMainBaseline( xbgn=xbgn, xend=xend, DFOF=1, history=1 )
		endif
	
	else
	
		if ( allWavesAvg )
			return NMMainBaseline( xbgn=xbgn, xend=xend, allWavesAvg=1, history=1 )
		else
			return NMMainBaseline( xbgn=xbgn, xend=xend, history=1 )
		endif
	
	endif

End // zCall_NMMainBaseline

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMainBaseline( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, xbgn, xend, allWavesAvg, DFOF ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	Variable xbgn, xend
	Variable allWavesAvg // ( 0 ) no, baseline to each wave's mean ( 1 ) baseline to mean of all selected waves
	Variable DFOF // compute dF/Fo baseline ( 0 ) no ( 1 ) yes
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( ( numtype( xbgn ) == 0 ) || ( numtype( xend ) == 0 ) )
		NMLoopExecVarAdd( "xbgn", xbgn, nm )
		NMLoopExecVarAdd( "xend", xend, nm )
	endif
	
	if ( allWavesAvg )
		NMLoopExecVarAdd( "allWavesAvg", allWavesAvg, nm, integer=1 )
	endif
	
	if ( DFOF )
		NMLoopExecVarAdd( "DFOF", DFOF, nm, integer=1 )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainBaseline

//****************************************************************
//****************************************************************

Function /S NMMainBaseline2( [ folder, wavePrefix, chanNum, waveSelect, xbgn, xend, allWavesAvg, DFOF ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	Variable xbgn, xend
	Variable allWavesAvg // ( 0 ) no, baseline to each wave's mean ( 1 ) baseline to mean of all selected waves
	Variable DFOF // compute dF/Fo baseline ( 0 ) no ( 1 ) yes
	
	String fxn = "NMBaseline"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( DFOF )
		fxn = "dF/Fo"
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	return NMBaseline2( nm, xbgn=xbgn, xend=xend, allWavesAvg=allWavesAvg, DFOF=DFOF, history=1 )
	
End // NMMainBaseline2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainNormalize()

	String promptStr = NMPromptStr( "" )

	STRUCT NMNormalizeStruct n
	
	if ( NMNormalizeCall( NMMainDF, promptStr=promptStr, all=1, n=n ) == 0 )
		return NMMainNormalize( n=n, history=1 )
	endif
	
	return ""
	
End // zCall_NMMainNormalize

//****************************************************************
//****************************************************************

Function /S NMMainNormalize( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, fxn1, avgWin1, xbgn1, xend1, minValue, fxn2, avgWin2, xbgn2, xend2, maxValue, allWavesAvg, n ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	String fxn1 // function to compute min value, "avg" or "min" or "minavg"
	Variable avgWin1 // for minavg
	Variable xbgn1, xend1 // x-axis window begin and end for fxn1, use ( -inf, inf ) for all
	Variable minValue // norm min value, default is 0, but could be -1 for example
	String fxn2 // function to compute max value, "avg" or "max" or "maxavg"
	Variable avgWin2 // for maxavg
	Variable xbgn2, xend2 // x-axis window begin and end for fxn2, use ( -inf, inf ) for all
	Variable maxValue // norm max value, default is 1
	Variable allWavesAvg // ( 0 ) no, normalize to each wave's avgs ( 1 ) normalize to avgs of all selected waves
	STRUCT NMNormalizeStruct &n // or pass this structure
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	STRUCT NMNormalizeStruct n2
	
	if ( ParamIsDefault( n ) )
	
		if ( ParamIsDefault( fxn1 ) )
			fxn1 = "min"
		endif
		
		if ( ParamIsDefault( xbgn1 ) || ( numtype( xbgn1 ) > 0 ) )
			xbgn1 = -inf
		endif
		
		if ( ParamIsDefault( xend1 ) || ( numtype( xend1 ) > 0 ) )
			xend1 = inf
		endif
		
		if ( ParamIsDefault( fxn2 ) )
			fxn2 = "max"
		endif
		
		if ( ParamIsDefault( xbgn2 ) || ( numtype( xbgn2 ) > 0 ) )
			xbgn2 = -inf
		endif
		
		if ( ParamIsDefault( xend2 ) || ( numtype( xend2 ) > 0 ) )
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
		n2.maxValue = maxValue
		
		n2.allWavesAvg = allWavesAvg
		
	else
	
		n2 = n
	
	endif
	
	if ( NMNormalizeError( n2 ) != 0 )
		return "" // error
	endif
	
	NMLoopExecStrAdd( "fxn1", n2.fxn1, nm )
	
	if ( StringMatch( n2.fxn1, "MinAvg" ) )
		NMLoopExecVarAdd( "avgWin1", n2.avgWin1, nm )
	endif
	
	if ( ( numtype( n2.xbgn1 ) == 0 ) || ( numtype( n2.xend1 ) == 0 ) )
		NMLoopExecVarAdd( "xbgn1", n2.xbgn1, nm )
		NMLoopExecVarAdd( "xend1", n2.xend1, nm )
	endif
	
	if ( n2.minValue != 0 )
		NMLoopExecVarAdd( "minValue", n2.minValue, nm )
	endif
	
	NMLoopExecStrAdd( "fxn2", n2.fxn2, nm )
	
	if ( StringMatch( n2.fxn2, "MaxAvg" ) )
		NMLoopExecVarAdd( "avgWin2", n2.avgWin2, nm )
	endif
	
	if ( ( numtype( n2.xbgn2 ) == 0 ) || ( numtype( n2.xend2 ) == 0 ) )
		NMLoopExecVarAdd( "xbgn2", n2.xbgn2, nm )
		NMLoopExecVarAdd( "xend2", n2.xend2, nm )
	endif
	
	if ( n2.maxValue != 1 )
		NMLoopExecVarAdd( "maxValue", n2.maxValue, nm )
	endif
	
	if ( n2.allWavesAvg )
		NMLoopExecVarAdd( "allWavesAvg", n2.allWavesAvg, nm, integer=1 )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainNormalize

//****************************************************************
//****************************************************************

Function /S NMMainNormalize2( [ folder, wavePrefix, chanNum, waveSelect, fxn1, avgWin1, xbgn1, xend1, minValue, fxn2, avgWin2, xbgn2, xend2, maxValue, allWavesAvg, n ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	String fxn1 // function to compute min value, "avg" or "min" or "minavg"
	Variable avgWin1 // for minavg
	Variable xbgn1, xend1 // x-axis window begin and end for fxn1, use ( -inf, inf ) for all
	Variable minValue // norm min value, default is 0, but could be -1
	String fxn2 // function to compute max value, "avg" or "max" or "maxavg"
	Variable avgWin2 // for maxavg
	Variable xbgn2, xend2 // x-axis window begin and end for fxn2, use ( -inf, inf ) for all
	Variable maxValue // norm max value, default is 1
	Variable allWavesAvg // ( 0 ) no, normalize to each wave's avgs ( 1 ) normalize to avgs of all selected waves
	STRUCT NMNormalizeStruct &n // or pass this structure
	
	String fxn = "NMNormalize"
	
	STRUCT NMParams nm
	STRUCT NMNormalizeStruct n2
	
	if ( ParamIsDefault( n ) )
	
		if ( ParamIsDefault( fxn1 ) )
			fxn1 = "min"
		endif
		
		if ( ParamIsDefault( xbgn1 ) || ( numtype( xbgn1 ) > 0 ) )
			xbgn1 = -inf
		endif
		
		if ( ParamIsDefault( xend1 ) || ( numtype( xend1 ) > 0 ) )
			xend1 = inf
		endif
		
		if ( ParamIsDefault( fxn2 ) )
			fxn2 = "max"
		endif
		
		if ( ParamIsDefault( xbgn2 ) || ( numtype( xbgn2 ) > 0 ) )
			xbgn2 = -inf
		endif
		
		if ( ParamIsDefault( xend2 ) || ( numtype( xend2 ) > 0 ) )
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
		n2.maxValue = maxValue
		
		n2.allWavesAvg = allWavesAvg
	
	else
	
		n2 = n
		
	endif
	
	if ( NMNormalizeError( n2 ) != 0 )
		return "" // error
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	return NMNormalize2( nm, n2, history=1 )
	
End // NMMainNormalize2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainScaleByNum()

	String promptStr = NMPromptStr( "NM Scale x / + - =" )
	
	String op = StrVarOrDefault( NMMainDF + "ScaleByNumOp", "x" )
	Variable factor = NumVarOrDefault( NMMainDF + "ScaleByNumFactor", 1 )
	Variable xbgn = NumVarOrDefault( NMMainDF + "ScaleByNumXbgn", -inf )
	Variable xend = NumVarOrDefault( NMMainDF + "ScaleByNumXend", inf )
		
	Prompt op, "choose arithmatic operation:", popup "x;/;+;-;=;"
	Prompt factor, "enter scale factor:"
	Prompt xbgn, NMPromptAddUnitsX( "x-axis window begin" )
	Prompt xend, NMPromptAddUnitsX( "x-axis window end" )
	
	DoPrompt promptStr, op, factor, xbgn, xend
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( numtype( factor ) > 0 )
	
		DoAlert /T=( promptStr ) 1, "Alert: the scale factor you entered ( " + num2str( factor ) + " ) is not a number. Do you want to continue?"
		
		if ( V_flag != 1 )
			return "" // cancel
		endif
		
	endif
	
	if ( StringMatch( op, "/" ) && ( factor == 0 ) )
		DoAlert /T=( promptStr ) 0, "Abort: cannot divide by zero."
		return "" // cancel
	endif
	
	SetNMstr( NMMainDF + "ScaleByNumAlg", op )
	SetNMvar( NMMainDF + "ScaleByNumFactor", factor )
	SetNMvar( NMMainDF + "ScaleByNumXbgn", xbgn )
	SetNMvar( NMMainDF + "ScaleByNumXend", xend )
	
	return NMMainScale( xbgn=xbgn, xend=xend, op=op, factor=factor, history=1 )
	
End // zCall_NMMainScaleByNum

//****************************************************************
//****************************************************************

Function /S NMMainScale( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, xbgn, xend, op, factor, waveOfFactors, wavePntByPnt, printToHistory ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	Variable xbgn, xend
	String op // operation ( "x" ... "/" ... "+" ... "-" ... "=" )
	Variable factor // scale factor for all input waves
	String waveOfFactors // name of wave containing a scale factor for each input wave ( e.g. a stats wave ), length of wave must equal number of selected input waves
	String wavePntByPnt // name of wave for point-by-point scaling of each input wave
	Variable printToHistory // ( 0 ) no history ( 1 ) print basic results to history ( 2 ) print basic results and wave-by-wave scaling operations
	
	Variable toDo
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( ( numtype( xbgn ) == 0 ) || ( numtype( xend ) == 0 ) )
		NMLoopExecVarAdd( "xbgn", xbgn, nm )
		NMLoopExecVarAdd( "xend", xend, nm )
	endif
	
	if ( ParamIsDefault( op ) || ( strlen( "op" ) == 0 ) )
		return NM2ErrorStr( 21, "op", "" )
	endif
	
	if ( strsearch( "x*/+-=", op, 0 ) == -1 )
		return NM2ErrorStr( 20, "op", op )
	endif
	
	NMLoopExecStrAdd( "op", op, nm )
	
	if ( !ParamIsDefault( factor ) )
		NMLoopExecVarAdd( "factor", factor, nm )
		toDo += 1
	endif
	
	if ( !ParamIsDefault( waveOfFactors ) )
		NMLoopExecStrAdd( "waveOfFactors", waveOfFactors, nm )
		toDo += 1
	endif
	
	if ( !ParamIsDefault( wavePntByPnt ) )	
		NMLoopExecStrAdd( "wavePntByPnt", wavePntByPnt, nm )
		toDo += 1
	endif
	
	if ( toDo != 1 )
		return "" // can have only one scaling operation
	endif
	
	if ( !ParamIsDefault( printToHistory ) )
		NMLoopExecVarAdd( "printToHistory", printToHistory, nm, integer = 1 )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainScale

//****************************************************************
//****************************************************************

Function /S NMMainScale2( [ folder, wavePrefix, chanNum, waveSelect, xbgn, xend, op, factor, waveOfFactors, wavePntByPnt, printToHistory ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	Variable xbgn, xend
	String op // operation ( "x" ... "/" ... "+" ... "-" ... "=" )
	Variable factor // scale factor for all input waves
	String waveOfFactors // name of wave containing a scale factor for each input wave ( e.g. a stats wave ), length of wave must equal number of selected input waves
	String wavePntByPnt // name of wave for point-by-point scaling of each input wave
	Variable printToHistory // ( 0 ) no history ( 1 ) print basic results to history ( 2 ) print basic results and wave-by-wave scaling operations
	
	Variable toDo
	String fxn = "NMScale"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( ParamIsDefault( op ) || ( strlen( "op" ) == 0 ) )
		return NM2ErrorStr( 21, "op", "" )
	endif
	
	if ( strsearch( "x*/+-=", op, 0 ) == -1 )
		return NM2ErrorStr( 20, "op", op )
	endif
	
	if ( ParamIsDefault( factor ) )
	
		if ( ParamIsDefault( waveOfFactors ) )
		
			if ( !ParamIsDefault( wavePntByPnt ) )
				toDo = 3
			endif
		
		else
		
			toDo = 2
			
		endif
	
	else
	
		toDo = 1
		
	endif
	
	if ( toDo == 0 )
		return ""
	endif
	
	if ( ParamIsDefault( printToHistory ) )
		printToHistory = 1
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	switch( toDo )
		case 1:
			return NMScale2( nm, op, factor=factor, xbgn=xbgn, xend=xend, history=printToHistory )
		case 2:
			return NMScale2( nm, op, waveOfFactors=waveOfFactors, xbgn=xbgn, xend=xend, history=printToHistory )
		case 3:
			return NMScale2( nm, op, wavePntByPnt=wavePntByPnt, xbgn=xbgn, xend=xend, history=printToHistory )
	endswitch
	
End // NMMainScale2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainScaleByWave()

	Variable browse = 1
	String txt, wList, optionsStr, menuList, promptStr = NMPromptStr( "NM Scale by Wave" )

	Variable select = NumVarOrDefault( NMMainDF + "ScaleByWaveSelect", 1 )
	String algorithm = StrVarOrDefault( NMMainDF + "ScaleByWaveAlg", "x" )
	String waveSelect = StrVarOrDefault( NMMainDF + "ScaleByWaveSelect", "" )
	
	Variable npnts = NMWaveSelectXstats( "numpnts", -1 )
	
	String wSelectList = NMWaveSelectList( -1 )
	Variable activeWaves = ItemsInList( wSelectList )
	
	if ( activeWaves == 0 )
		return ""
	endif
	
	if ( ( numtype( npnts ) == 0 ) && ( npnts > 0 ) )

		menuList = "scale by values in a wave ( " + num2istr( activeWaves ) + " points );point-by-point scaling by a single wave ( " + num2istr( npnts ) + " points );"

		Prompt select, "What would you like to do?", popup menuList
		Prompt algorithm, "select function:", popup "x;/;+;-;=;"
	
		DoPrompt promptStr, select
	
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		SetNMvar( NMMainDF + "ScaleByWaveSelect", select )
		
	else
	
		select = 1
		
	endif
	
	if ( select == 1 )
	
		optionsStr = NMWaveListOptions( activeWaves, 0 )
	
		wList = WaveList( "*", ";", optionsStr )
		
		Prompt waveSelect, "select a wave of scale values ( " + num2istr( activeWaves ) + " points ):", popup " ;" + wList
		Prompt browse, "or use browser to look for a wave of scale values:", popup "no;yes;"
		
		if ( ItemsInList( wList ) == 0 )
		
			browse = 2
			
			DoPrompt promptStr, algorithm
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
		
		else
		
			DoPrompt promptStr, algorithm, waveSelect, browse
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
			SetNMstr( NMMainDF + "ScaleByWaveSelect", waveSelect )
			
		endif
		
		SetNMstr( NMMainDF + "ScaleByWaveAlg", algorithm )
		
		if ( browse == 2 )
		
			txt = "select a wave of scale values (" + num2istr( activeWaves ) + " points)"
		
			waveSelect = NMWaveBrowser( txt, numWavesLimit = 1, numPoints = activeWaves, noText = 1 )
			
			if ( WaveExists( $waveSelect ) == 0 )
				return ""
			endif
			
		else
		
			waveSelect = GetDataFolder( 1 ) + waveSelect

		endif
	
	elseif ( select == 2 )
	
		optionsStr = NMWaveListOptions( npnts, 0 )
	
		wList = WaveList( "*", ";", optionsStr )
		
		Prompt waveSelect, "select a wave to scale by ( " + num2istr( npnts ) + " points ):", popup " ;" + wList
		Prompt browse, "or use browser to look for a wave to scale by:", popup "no;yes;"
		
		if ( ItemsInList( wList ) == 0 )
		
			browse = 2
			
			DoPrompt promptStr, algorithm
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
		
		else
		
			DoPrompt promptStr, algorithm, waveSelect, browse
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
			SetNMstr( NMMainDF + "ScaleByWaveSelect", waveSelect )
			
		endif
		
		SetNMstr( NMMainDF + "ScaleByWaveAlg", algorithm )
		
		if ( browse == 2 )
		
			txt = "select a wave to scale by (" + num2istr( npnts ) + " points)"
		
			waveSelect = NMWaveBrowser( txt, numWavesLimit=1, numPoints=npnts, noText=1 )
			
			if ( WaveExists( $waveSelect ) == 0 )
				return ""
			endif
			
		else
		
			waveSelect = GetDataFolder( 1 ) + waveSelect

		endif
	
	endif
	
	WaveStats /Q $waveSelect
	
	if ( V_numNANs > 0 )
	
		DoAlert /T=( promptStr ) 1, "the chosen wave contains non-numbers (NANs,n=" + num2istr( V_numNANs ) + "). Do you want to continue?"
		
		if ( V_flag != 1 )
			return ""
		endif
	
	endif
	
	if ( V_numINFs > 0 )
	
		DoAlert /T=( promptStr ) 1, "the chosen wave contains infinity values (n=" + num2istr( V_numINFs ) + "). Do you want to continue?"
		
		if ( V_flag != 1 )
			return ""
		endif
	
	endif
	
	return ""

End // zCall_NMMainScaleByWave

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainScaleByWave1()

	Variable npnts, icnt, grpNum
	String optionsStr, wList, wList2 = "", sname
	String setList = "", setName, promptStr = NMPromptStr( "NM Scale by Wave" )
	
	Variable numWaves = NMNumWaves()
	Variable numActiveWaves = NMNumActiveWaves()
	Variable currentChan = CurrentNMChannel()
	
	String currentWaveSelect = NMWaveSelectGet()
	
	Variable SetOrGroup = 0
	
	Variable method = NumVarOrDefault( NMMainDF + "ScaleByWaveMthd", 0 )
	String algorithm = StrVarOrDefault( NMMainDF + "ScaleByWaveAlg", "x" )
	String waveSelect = StrVarOrDefault( NMMainDF + "ScaleByWaveSelect", "" )
	String waveSelect2 = StrVarOrDefault( NMMainDF + "ScaleByWaveSelect2", "" )
	String setOrGroupSelect = StrVarOrDefault( NMMainDF + "ScaleByWaveSetOrGroup", "" )
	
	if ( !WaveExists( $waveSelect ) )
		waveSelect = ""
	endif
	
	if ( !WaveExists( $waveSelect2 ) )
		waveSelect2 = ""
	endif
	
	if ( AreNMSets( currentWaveSelect ) )
	
		SetOrGroup = 1
		
		if ( !AreNMSets( setOrGroupSelect ) )
			setOrGroupSelect = ""
		endif
		
		wList2 = NMSetsList() + NMGroupsList( 1 )
		setList = ""
		
		for ( icnt = 0 ; icnt < ItemsInList( wList2 ) ; icnt += 1 )
		
			setName = StringFromList( icnt, wList2 )
			wList = NMSetsWaveList( setName, currentChan )
			
			if ( ItemsInList( wList ) == numActiveWaves )
				setList = AddListItem( setName, setList, ";", inf )
			endif
			
		endfor
	
	endif
	
	optionsStr = NMWaveListOptions( numWaves, 0 )
	
	wList = WaveList( "*", ";", optionsStr )
	
	npnts = NMWaveSelectXstats( "numpnts", -1 )
	
	if ( ( numtype( npnts ) == 0 ) && ( npnts > 0 ) )
	
		optionsStr = NMWaveListOptions( npnts, 0 )
	
		wList2 = WaveList( "*", ";", optionsStr )
		
	endif
	
	if ( ItemsInList( wList ) > 0 )
		wList = " ;" + wList
	endif
	
	if ( ItemsInList( wList2 ) > 0 )
		wList2 = " ;" + wList2
	endif
	
	if ( ItemsInList( setList ) > 0 )
		setList = " ;" + setList
	endif
	
	Prompt algorithm, "function:", popup "x;/;+;-;=;"
	Prompt waveSelect, "select a wave of scale values:", popup wList
	Prompt waveSelect2, "or select a wave to scale by:", popup wList2
	Prompt setOrGroupSelect, "or select a Set or Group to scale by:", popup setList
	
	if ( SetOrGroup )
		DoPrompt promptStr, algorithm, waveSelect, waveSelect2, setOrGroupSelect
	else
		DoPrompt promptStr, algorithm, waveSelect, waveSelect2
	endif
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( WaveExists( $waveSelect ) ) // scale by wave of values
		SetOrGroup = 0
		method = 1
		sname = waveSelect
		waveSelect2 = ""
	elseif ( WaveExists( $waveSelect2 ) ) // scale by wave
		SetOrGroup = 0
		method = 2
		sname = waveSelect2
		waveSelect = ""
	elseif ( AreNMSets( setOrGroupSelect ) )
		SetOrGroup = 1
		waveSelect = ""
		waveSelect2 = ""
	else
		return ""
	endif
	
	SetNMvar( NMMainDF + "ScaleByWaveMthd", method )
	SetNMstr( NMMainDF + "ScaleByWaveAlg", algorithm )
	SetNMstr( NMMainDF + "ScaleByWaveSelect", waveSelect )
	SetNMstr( NMMainDF + "ScaleByWaveSelect2", waveSelect2 )
	SetNMstr( NMMainDF + "ScaleByWaveSetOrGroup", setOrGroupSelect )
	
	if ( SetOrGroup )
	
		//return NMScaleBySet( algorithm, currentWaveSelect, setOrGroupSelect )
	
	else
		
		//return NMScaleByWave( method, algorithm, sname )

	endif
	
	return ""

End // zCall_NMMainScaleByWave

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainScaleBySet()

	Variable icnt, groups, numActiveWaves, currentChan
	String txt, wList, wList2, setName, setList = ""
	String promptStr = NMPromptStr( "NM Scale by Set" )
	
	String currentWaveSelect = NMWaveSelectGet()
	
	if ( !AreNMSets( currentWaveSelect ) )
		DoAlert /T=( promptStr ) 0, "To use this function, the current wave selection needs to be a Set or Grounm."
		return ""
	endif
	
	String algorithm = StrVarOrDefault( NMMainDF + "ScaleBySetAlg", "x" )
	String setSelect = StrVarOrDefault( NMMainDF + "ScaleBySet", "" )
		
	if ( !AreNMSets( setSelect ) )
		setSelect = ""
	endif
	
	currentChan = CurrentNMChannel()
	
	wList = NMSetsWaveList( currentWaveSelect, currentChan )
	
	numActiveWaves = ItemsInList( wList )
	
	wList2 = NMSetsList() + NMGroupsList( 1 )
	
	for ( icnt = 0 ; icnt < ItemsInList( wList2 ) ; icnt += 1 )
	
		setName = StringFromList( icnt, wList2 )
		
		if ( StringMatch( setName, currentWaveSelect ) )
			continue
		endif
		
		wList = NMSetsWaveList( setName, currentChan )
		
		if ( ItemsInList( wList ) == numActiveWaves )
			setList = AddListItem( setName, setList, ";", inf )
		endif
		
	endfor
	
	if ( ItemsInList( setList ) == 0 )
		txt = "Found no Sets or Groups with matching number of waves (n=" + num2istr( numActiveWaves) + ")."
		DoAlert /T=( promptStr ) 0, txt
		return ""
	endif
	
	Prompt algorithm, "function:", popup "x;/;+;-;=;" 
	Prompt setSelect, "select a Set or Group to scale by:", popup setList
	DoPrompt promptStr, setSelect
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMstr( NMMainDF + "ScaleBySet", setSelect )
	SetNMstr( NMMainDF + "ScaleBySetAlg", algorithm )
	
	//return NMMainScaleBySet( set1=currentWaveSelect, algorithm=algorithm, set2=setSelect )

End // zCall_NMMainScaleBySet

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainRescale()
	
	Variable scale1, scale2
	Variable chan = CurrentNMChannel()
	
	String oldunits = NMWaveUnits( "y", CurrentNMWaveName() )
	String newUnits, ulist = "", promptStr = NMPromptStr( "NM Rescale" )
	
	if ( ( strlen( oldunits ) == 0 ) && WaveExists( $"yLabel" ) )
	
		Wave /T yLabel
		
		if ( ( chan >= 0 ) && ( chan < numpnts( yLabel ) ) )
		
			oldunits = yLabel[ chan ]
			
			if ( strlen( oldunits ) > 0 )
			
				NMChanLabelSet( chan, 1, "y", oldunits )
				
				oldunits = UnitsFromStr( oldunits )
				
			endif
			
		endif
	
	endif
	
	if ( strlen( oldunits ) == 0 )
	
		Prompt oldUnits, "please enter the current y-scale units of your data (e.g. mV or pA):"
		
		DoPrompt promptStr, oldUnits
	
		if ( V_flag == 1 )
			return "" // cancel
		endif
	
	endif
	
	strswitch( oldunits )
	
		case "A":
		case "Amps":
			ulist = "A;mA;uA;nA;pA;"
			oldUnits = "A"
			break
		case "mA":
		case "mAmps":
		case "milliAmps":
			ulist = "A;mA;uA;nA;pA;"
			oldUnits = "mA"
			break
		case "uA":
		case "uAmps":
		case "microAmps":
			ulist = "A;mA;uA;nA;pA;"
			oldUnits = "uA"
			break
		case "nA":
		case "nAmps":
		case "nanoAmps":
			ulist = "A;mA;uA;nA;pA;"
			oldUnits = "nA"
			break
		case "pA":
		case "pAmps":
		case "picoAmps":
			ulist = "A;mA;uA;nA;pA;"
			oldUnits = "pA"
			break
		
		case "V":
		case "Volts":
			ulist = "V;mV;uV;nV;pV;"
			oldUnits = "V"
			break
		case "mV":
		case "mVolts":
		case "milliVolts":
			ulist = "V;mV;uV;nV;pV;"
			oldUnits = "mV"
			break
		case "uV":
		case "uVolts":
		case "microVolts":
			ulist = "V;mV;uV;nV;pV;"
			oldUnits = "uV"
			break
		case "nV":
		case "nVolts":
		case "nanoVolts":
			ulist = "V;mV;uV;nV;pV;"
			oldUnits = "nV"
			break
		case "pV":
		case "pVolts":
		case "picoVolts":
			ulist = "V;mV;uV;nV;pV;"
			oldUnits = "pV"
			break
			
		case "s":
		case "sec":
		case "seconds":
			ulist = "s;ms;us;ns;ps;"
			oldUnits = "s"
			break
		case "ms":
		case "msec":
		case "milliseconds":
			ulist = "s;ms;us;ns;ps;"
			oldUnits = "ms"
			break
		case "us":
		case "usec":
		case "microseconds":
			ulist = "s;ms;us;ns;ps;"
			oldUnits = "us"
			break
		case "ns":
		case "nsec":
		case "nanoseconds":
			ulist = "s;ms;us;ns;ps;"
			oldUnits = "ns"
			break
		case "ps":
		case "psec":
		case "picoseconds":
			ulist = "s;ms;us;ns;ps;"
			oldUnits = "ps"
			break
			
		default:
			DoAlert /T=( promptStr ) 0, "Abort: cannot determine y-scale units"
			return ""
			
	endswitch
	
	newUnits = oldUnits
	
	Prompt oldUnits, "please confirm the current y-scale units of your data:", popup ulist
	Prompt newUnits, "new units to convert to:", popup ulist
	DoPrompt promptStr, oldUnits, newUnits
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( StringMatch( newUnits, oldUnits ) )
		return ""
	endif
	
	switch( WhichListItem( oldUnits, ulist ) )
		case 0:
			scale1 = 1
			break
		case 1:
			scale1 = 1e-3
			break
		case 2:
			scale1 = 1e-6
			break
		case 3:
			scale1 = 1e-9
			break
		case 4:
			scale1 = 1e-12
			break
		default:
			return ""
	endswitch
	
	switch( WhichListItem( newUnits, ulist ) )
		case 0:
			scale2 = 1
			break
		case 1:
			scale2 = 1e-3
			break
		case 2:
			scale2 = 1e-6
			break
		case 3:
			scale2 = 1e-9
			break
		case 4:
			scale2 = 1e-12
			break
		default:
			return ""
	endswitch
	
	scale1 /= scale2
	
	return NMMainRescale( oldUnits=oldUnits, newUnits=newUnits, scale=scale1, history=1 )

End // zCall_NMMainRescale

//****************************************************************
//****************************************************************

Function /S NMMainRescale( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, oldUnits, newUnits, scale ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	String oldUnits // ( must specify )
	String newUnits // ( must specify )
	Variable scale // ( must specify )
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( oldUnits ) || ( strlen( oldUnits ) == 0 ) )
		return NM2ErrorStr( 21, "oldUnits", "" )
	endif
	
	if ( ParamIsDefault( newUnits ) || ( strlen( newUnits ) == 0 ) )
		return NM2ErrorStr( 21, "newUnits", "" )
	endif
	
	if ( ParamIsDefault( scale ) )
		return NM2ErrorStr( 11, "scale", "" )
	endif
	
	if ( numtype( scale ) > 0 )
		return NM2ErrorStr( 10, "scale", num2str( scale ) )
	endif
	
	if ( StringMatch( oldUnits, newUnits ) || ( scale == 1 ) )
		return "" // nothing to do
	endif
	
	NMLoopExecStrAdd( "oldUnits", oldUnits, nm )
	NMLoopExecStrAdd( "newUnits", newUnits, nm )
	NMLoopExecVarAdd( "scale", scale, nm )
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainRescale

//****************************************************************
//****************************************************************

Function /S NMMainRescale2( [ folder, wavePrefix, chanNum, waveSelect, oldUnits, newUnits, scale ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	String oldUnits
	String newUnits
	Variable scale
	
	String fxn = "NMRescale"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( oldUnits ) || ( strlen( oldUnits ) == 0 ) )
		return NM2ErrorStr( 21, "oldUnits", "" )
	endif
	
	if ( ParamIsDefault( newUnits ) || ( strlen( newUnits ) == 0 ) )
		return NM2ErrorStr( 21, "newUnits", "" )
	endif
	
	if ( ParamIsDefault( scale ) )
		return NM2ErrorStr( 11, "scale", "" )
	endif
	
	if ( numtype( scale ) > 0 )
		return NM2ErrorStr( 10, "scale", num2str( scale ) )
	endif
	
	if ( StringMatch( oldUnits, newUnits ) || ( scale == 1 ) )
		return "" // nothing to do
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	return NMRescale2( nm, oldUnits, newUnits, scale, history=1 )
	
End // NMMainRescale2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainSmooth()

	String promptStr = NMPromptStr( "NM Smooth Waves" )
	
	String algorithm = StrVarOrDefault( NMMainDF + "SmoothAlg", "binomial" )
	Variable num = NumVarOrDefault( NMMainDF + "SmoothNum", 3 )
	
	Prompt algorithm, "select smoothing algorithm:", popup "binomial;boxcar (sliding average);polynomial;"
	Prompt num, "number of smoothing points:"
	DoPrompt promptStr, algorithm
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( strsearch( algorithm, "boxcar", 0 ) >= 0 )
		algorithm = "boxcar"
	endif
	
	strswitch( algorithm )
		case "binomial":
			Prompt num, "number of smoothing operations:"
			promptStr = NMPromptStr( "NM Binomial Smoothing" )
			break
		case "boxcar":
			promptStr = NMPromptStr( "NM Boxcar (Sliding Average) Smoothing" )
			break
		case "polynomial":
			promptStr = NMPromptStr( "NM Savitzky-Golay Polynomial Smoothing" )
			break
		default:
			return ""
	endswitch
	
	DoPrompt promptStr, num
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMstr( NMMainDF + "SmoothAlg", algorithm )
	SetNMvar( NMMainDF + "SmoothNum", num )
	
	return NMMainSmooth( algorithm=algorithm, num=num, history=1 )
	
End // zCall_NMMainSmooth

//****************************************************************
//****************************************************************

Function /S NMMainSmooth( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, algorithm, num ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	String algorithm // "binomial", "boxcar" or "polynomial" ( see Igor Smooth )
	Variable num // see Igor Smooth ( must specify )
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( algorithm ) )
		algorithm = "binomial"
	else
		NMLoopExecStrAdd( "algorithm", algorithm, nm )
	endif
	
	if ( ParamIsDefault( num ) )
		return NM2ErrorStr( 11, "num", "" )
	endif
	
	NMLoopExecVarAdd( "num", num, nm, integer = 1 )
	
	if ( NMSmoothError( algorithm, num ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainSmooth

//****************************************************************
//****************************************************************

Function /S NMMainSmooth2( [ folder, wavePrefix, chanNum, waveSelect, algorithm, num ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	String algorithm // "binomial", "boxcar" or "polynomial" ( see Igor Smooth )
	Variable num // see Igor Smooth
	
	String fxn = "NMSmooth"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( algorithm ) )
		algorithm = "binomial"
	endif
	
	if ( ParamIsDefault( num ) )
		return NM2ErrorStr( 11, "num", "" )
	endif
	
	if ( NMSmoothError( algorithm, num ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif

	return NMSmooth2( nm, num, algorithm=algorithm, history=1 )
	
End // NMMainSmooth2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainFilterFIR()

	Variable f1, f2, n, fc, fw, sfreq, upperLimit, lowerLimit
	
	Variable all = 0
	Variable dx = zError_DeltaX( all, "Filter FIR" )
	
	if ( numtype( dx ) > 0 )
		return "" // cancel
	endif
	
	String algorithm = StrVarOrDefault( NMMainDF + "FilterFIRalg", "low-pass" )
	
	sfreq = 1 / dx // kHz
	upperLimit = 0.5 * sfreq
	lowerLimit = 0.0158 * sfreq
	
	Prompt algorithm, "select filter algorithm:", popup "low-pass;high-pass;notch;"
	DoPrompt NMPromptStr( "NM Filter FIR" ), algorithm
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMstr( NMMainDF + "FilterFIRalg", algorithm )
	
	strswitch( algorithm )
	
		case "low-pass":
		
			f1 = NumVarOrDefault( NMMainDF + "FilterFIRLPf1", 0.4 )
			f2 = NumVarOrDefault( NMMainDF + "FilterFIRLPf2", 0.5 )
			n = NumVarOrDefault( NMMainDF + "FilterFIRLPn", 101 )
			
			f1 = floor( f1 * sfreq * 10000 ) / 10000 // convert to kHz
			f2 = floor( f2 * sfreq * 10000 ) / 10000
			
			Prompt f1, "end of pass band ( 0 < f1 < " + num2str(upperLimit ) + " kHz ):"
			Prompt f2, "start of reject band ( f1 < f2 < " + num2str(upperLimit ) + " kHz ):"
			Prompt n, "number of filter coefficients to generate:"
			
			DoPrompt NMPromptStr( "NM Low-pass filter" ), f1, f2, n
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
			f1 /= sfreq // convert back to fraction of sample frequency
			f2 /= sfreq
	
			SetNMvar( NMMainDF + "FilterFIRLPf1", f1 )
			SetNMvar( NMMainDF + "FilterFIRLPf2", f2 )
			SetNMvar( NMMainDF + "FilterFIRLPn", n )
	
			return NMMainFilterFIR( algorithm=algorithm, f1=f1, f2=f2, n=n, history=1 )
			
		case "high-pass":
		
			f1 = NumVarOrDefault( NMMainDF + "FilterFIRHPf1", 0.1 )
			f2 = NumVarOrDefault( NMMainDF + "FilterFIRHPf2", 0.2 )
			n = NumVarOrDefault( NMMainDF + "FilterFIRHPn", 101 )
			
			f1 = floor( f1 * sfreq * 10000 ) / 10000
			f2 = floor( f2 * sfreq * 10000 ) / 10000
			
			Prompt f1, "end of reject band ( 0 < f1 < " + num2str(upperLimit ) + " kHz ):"
			Prompt f2, "start of pass band ( f1 < f2 < " + num2str(upperLimit ) + " kHz ):"
			Prompt n, "number of filter coefficients to generate:"
			
			DoPrompt NMPromptStr( "NM High-pass filter" ), f1, f2, n
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
			f1 /= sfreq // convert back to fraction of sample frequency
			f2 /= sfreq
	
			SetNMvar( NMMainDF + "FilterFIRHPf1", f1 )
			SetNMvar( NMMainDF + "FilterFIRHPf2", f2 )
			SetNMvar( NMMainDF + "FilterFIRHPn", n )
			
			return NMMainFilterFIR( algorithm=algorithm, f1=f1, f2=f2, n=n, history=1 )
			
		case "notch":
		
			fc = NumVarOrDefault( NMMainDF + "FilterFIRfc", 0.5 )
			fw = NumVarOrDefault( NMMainDF + "FilterFIRfw", 0.1 )
			
			fc = floor( fc * sfreq * 10000 ) / 10000
			fw = floor( fw * sfreq * 10000 ) / 10000
			
			Prompt fc, "center frequency ( 0 < fc < " + num2str(upperLimit ) + " kHz ):"
			Prompt fw, "width frequency ( " + num2str(lowerLimit ) + " < fw < " + num2str(upperLimit ) + " kHz ):"
			
			DoPrompt NMPromptStr( "NM Notch filter" ), fc, fw
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
			SetNMvar( NMMainDF + "FilterFIRfc", fc )
			SetNMvar( NMMainDF + "FilterFIRfw", fw )
			
			return NMMainFilterFIR( fc=fc, fw=fw, history=1 )
			
	endswitch
	
	return ""
	
End // zCall_NMMainFilterFIR

//****************************************************************
//****************************************************************

Function /S NMMainFilterFIR( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, algorithm, f1, f2, n, fc, fw ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	String algorithm // "low-pass" or "high-pass" or "notch"
	Variable f1, f2, n // for low-pass or high-pass, see FilterFIR
	Variable fc, fw // for notch
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( algorithm ) )
		algorithm = ""
	else
		NMLoopExecStrAdd( "algorithm", algorithm, nm )
	endif
	
	if ( !ParamIsDefault( f1 ) )
		NMLoopExecVarAdd( "f1", f1, nm )
	endif
	
	if ( !ParamIsDefault( f2 ) )
		NMLoopExecVarAdd( "f2", f2, nm )
	endif
	
	if ( !ParamIsDefault( n ) )
		NMLoopExecVarAdd( "n", n, nm )
	endif
	
	if ( !ParamIsDefault( fc ) )
		NMLoopExecVarAdd( "fc", fc, nm )
	endif
	
	if ( !ParamIsDefault( fw ) )
		NMLoopExecVarAdd( "fw", fw, nm )
	endif
	
	if ( NMFilterFIRError( algorithm, f1, f2, n, fc, fw ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainFilterFIR

//****************************************************************
//****************************************************************

Function /S NMMainFilterFIR2( [ folder, wavePrefix, chanNum, waveSelect, algorithm, f1, f2, n, fc, fw ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	String algorithm // "low-pass" or "high-pass" or "notch"
	Variable f1, f2, n // for low-pass or high-pass, see FilterFIR
	Variable fc, fw // for notch
	
	String fxn = "NMFilterFIR"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( algorithm ) )
		algorithm = ""
	endif
	
	if ( NMFilterFIRError( algorithm, f1, f2, n, fc, fw ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	if ( ( numtype( fc * fw ) == 0 ) && ( fc > 0 ) && ( fw > 0 ) )
		return NMFilterFIR2( nm, algorithm=algorithm, fc=fc, fw=fw, history=1 )
	else
		return NMFilterFIR2( nm, algorithm=algorithm, f1=f1, f2=f2, n=n, history=1 )
	endif
	
End // NMMainFilterFIR2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainFilterIIR()

	Variable sfreq, fLow, fHigh, fNotch, notchQ, all = 0
	String freqLimitStr
	
	Variable dx = zError_DeltaX( all, "Filter IIR" )
	
	if ( numtype( dx ) > 0 )
		return "" // cancel
	endif
	
	String algorithm = StrVarOrDefault( NMMainDF + "FilterIIRalg", "low-pass" )
	
	sfreq = 1 / dx // kHz
	freqLimitStr = num2str( 0.5 / dx )
	
	Prompt algorithm, "select filter algorithm:", popup "low-pass;high-pass;notch;"
	DoPrompt NMPromptStr( "NM Filter IIR" ), algorithm
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMstr( NMMainDF + "FilterIIRalg", algorithm )
	
	strswitch( algorithm )
	
		case "low-pass":
			
			fLow = NumVarOrDefault( NMMainDF + "FilterIIRfLow", 0.25 ) // fraction of sample rate
			fLow = floor( fLow * sfreq * 10000 ) / 10000 // convert to kHz
			
			Prompt fLow, "corner frequency ( 0 < f < " + freqLimitStr + " kHz ):"
			DoPrompt NMPromptStr( "NM Low-pass Butterworth filter" ), fLow
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
			fLow /= sfreq // convert back to fraction of sample frequency
			
			SetNMvar( NMMainDF + "FilterIIRfLow", fLow )
			
			return NMMainFilterIIR( fLow=fLow, history=1 )
			
		case "high-pass":
		
			fHigh = NumVarOrDefault( NMMainDF + "FilterIIRfHigh", 0.25 ) // fraction of sample rate
			fHigh = floor( fHigh * sfreq * 10000 ) / 10000 // convert to kHz
			
			Prompt fHigh, "corner frequency ( 0 < f < " + freqLimitStr + " kHz ):"
			DoPrompt NMPromptStr( "NM High-pass Butterworth filter" ), fHigh
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
			fHigh /= sfreq // convert back to fraction of sample frequency
			
			SetNMvar( NMMainDF + "FilterIIRfHigh", fHigh )
			
			return NMMainFilterIIR( fHigh=fHigh, history=1 )
			
		case "notch":
		
			fNotch = NumVarOrDefault( NMMainDF + "FilterIIRfNotch", 0.25 ) // fraction of sample rate
			fNotch = floor( fNotch * sfreq * 10000 ) / 10000 // convert to kHz
			
			notchQ = NumVarOrDefault( NMMainDF + "FilterIIRnotchQ", 10 )
		
			Prompt fNotch, "center frequency ( 0 < f < " + freqLimitStr + " kHz ):"
			Prompt notchQ, "filter width Q factor ( width = f / Q ):"
			DoPrompt NMPromptStr( "NM Notch filter" ), fNotch, notchQ
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
			fNotch /= sfreq // convert back to fraction of sample frequency
			
			SetNMvar( NMMainDF + "FilterIIRfNotch", fNotch )
			SetNMvar( NMMainDF + "FilterIIRnotchQ", notchQ )
			
			return NMMainFilterIIR( fNotch=fNotch, notchQ=notchQ, history=1 )
			
	endswitch
	
	return ""
	
End // zCall_NMMainFilterIIR

//****************************************************************
//****************************************************************

Function /S NMMainFilterIIR( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, fLow, fHigh, fNotch, notchQ ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	Variable fLow // -3dB corner for low-pass filter, see Igor FilterIIR
	Variable fHigh // -3dB corner for high-pass filter
	Variable fNotch, notchQ // center frequency at fNotch, and -3dB width of fNotch
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( !ParamIsDefault( fLow ) )
		NMLoopExecVarAdd( "fLow", fLow, nm )
	endif
	
	if ( !ParamIsDefault( fHigh ) )
		NMLoopExecVarAdd( "fHigh", fHigh, nm )
	endif
	
	if ( !ParamIsDefault( fNotch ) )
		NMLoopExecVarAdd( "fNotch", fNotch, nm )
	endif
	
	if ( !ParamIsDefault( notchQ ) )	
		NMLoopExecVarAdd( "notchQ", notchQ, nm )
	endif
	
	if ( NMFilterIIRError( fLow, fHigh, fNotch, notchQ ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainFilterIIR

//****************************************************************
//****************************************************************

Function /S NMMainFilterIIR2( [ folder, wavePrefix, chanNum, waveSelect, fLow, fHigh, fNotch, notchQ ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	Variable fLow // -3dB corner for low-pass filter, see Igor FilterIIR
	Variable fHigh // -3dB corner for high-pass filter
	Variable fNotch, notchQ // center frequency at fNotch, and -3dB width of fNotch
	
	String fxn = "NMFilterIIR"
	
	STRUCT NMParams nm
	
	if ( NMFilterIIRError( fLow, fHigh, fNotch, notchQ ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	return NMFilterIIR2( nm, fLow=fLow, fHigh=fHigh, fNotch=fNotch, notchQ=notchQ, history=1 )
	
End // NMMainFilterIIR2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainRsCorrection()
	
	String promptStr = NMPromptStr( "" )
	String xLabel = NMChanLabelX()
	String yLabel = NMChanLabelY()
	
	Variable warning = NumVarOrDefault( NMDF + "RsCorrWarning", 1 )
	
	Variable dx = NMChanDeltaX( 0, 1 )
	
	STRUCT NMRsCorrParams rc
	
	if ( NMRsCorrectionCall( NMDF, promptStr=promptStr, xLabel=xLabel, yLabel=yLabel, dx=dx, warning=warning, rc=rc ) == 0 )
		SetNMvar( NMDF + "RsCorrWarning", 0 ) // turn off warning after first use
		return NMMainRsCorrection( Vhold=rc.Vhold, Vrev=rc.Vrev, Rs=rc.Rs, Cm=rc.Cm, Vcomp=rc.Vcomp, Ccomp=rc.Ccomp, Fc=rc.Fc, dataUnitsX=rc.dataUnitsX, dataUnitsY=rc.dataUnitsY, history=1 )
	endif
	
	return ""
	
End // zCall_NMMainRsCorrection

//****************************************************************
//****************************************************************

Function /S NMMainRsCorrection( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, Vhold, Vrev, Rs, Cm, Vcomp, Ccomp, Fc, dataUnitsX, dataUnitsY ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	Variable Vhold, Vrev, Rs, Cm, Vcomp, Ccomp, Fc
	String dataUnitsX, dataUnitsY
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( Vhold ) )
		return NM2ErrorStr( 11, "Vhold", num2str( Vhold ) )
	endif
	
	NMLoopExecVarAdd( "Vhold", Vhold, nm )
	
	if ( ParamIsDefault( Vrev ) )
		return NM2ErrorStr( 11, "Vrev", num2str( Vrev ) )
	endif
	
	NMLoopExecVarAdd( "Vrev", Vrev, nm )
	
	if ( ParamIsDefault( Rs ) )
		return NM2ErrorStr( 11, "Rs", num2str( Rs ) )
	endif
	
	NMLoopExecVarAdd( "Rs", Rs, nm )
	
	if ( ParamIsDefault( Cm ) )
		return NM2ErrorStr( 11, "Cm", num2str( Cm ) )
	endif
	
	NMLoopExecVarAdd( "Cm", Cm, nm )
	
	if ( ParamIsDefault( Vcomp ) )
		return NM2ErrorStr( 11, "Vcomp", num2str( Vcomp ) )
	endif
	
	NMLoopExecVarAdd( "Vcomp", Vcomp, nm )
	
	if ( ParamIsDefault( Ccomp ) )
		return NM2ErrorStr( 11, "Ccomp", num2str( Ccomp ) )
	endif
	
	NMLoopExecVarAdd( "Ccomp", Ccomp, nm )
	
	if ( ParamIsDefault( Fc ) )
		return NM2ErrorStr( 11, "Fc", num2str( Fc ) )
	endif
	
	NMLoopExecVarAdd( "Fc", Fc, nm )
	
	if ( ParamIsDefault( dataUnitsX ) )
		return NM2ErrorStr( 21, "dataUnitsX", dataUnitsX )
	endif
	
	if ( ParamIsDefault( dataUnitsY ) )
		return NM2ErrorStr( 21, "dataUnitsY", dataUnitsY )
	endif
	
	NMLoopExecStrAdd( "dataUnitsX", dataUnitsX, nm )
	NMLoopExecStrAdd( "dataUnitsY", dataUnitsY, nm )
	
	STRUCT NMRsCorrParams rc
	
	rc.Vhold = Vhold
	rc.Vrev = Vrev
	rc.Rs = Rs
	rc.Cm = Cm
	rc.Vcomp = Vcomp
	rc.Ccomp = Ccomp
	rc.Fc = Fc
	rc.dataUnitsX = dataUnitsX
	rc.dataUnitsY = dataUnitsY
	
	if ( NMRsCorrError( rc ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainRsCorrection

//****************************************************************
//****************************************************************

Function /S NMMainRsCorrection2( [ folder, wavePrefix, chanNum, waveSelect, Vhold, Vrev, Rs, Cm, Vcomp, Ccomp, Fc, dataUnitsX, dataUnitsY ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	Variable Vhold, Vrev, Rs, Cm, Vcomp, Ccomp, Fc
	String dataUnitsX, dataUnitsY
	
	String fxn = "NMRsCorrection"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	STRUCT NMRsCorrParams rc
	
	rc.Vhold = Vhold
	rc.Vrev = Vrev
	rc.Rs = Rs
	rc.Cm = Cm
	rc.Vcomp = Vcomp
	rc.Ccomp = Ccomp
	rc.Fc = Fc
	rc.dataUnitsX = dataUnitsX
	rc.dataUnitsY = dataUnitsY
	
	return NMRsCorrection( nm, rc, history = 1 )
	
End // NMMainRsCorrection2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainAddNoise()

	Variable num1, num2

	String fxn = StrVarOrDefault( NMMainDF + "NoiseFxn", "Gaussian" )
	
	Prompt  fxn, "type of noise to add:", popup "Binomial;Exponential;Gamma;Gaussian;LogNormal;Lorentzian;Poisson;Uniform;"
	DoPrompt NMPromptStr( "NM Add Noise" ), fxn
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMstr( NMMainDF + "NoiseFxn",  fxn )
	
	strswitch( fxn )
	
		case "Binomial":
			
			num1 = NumVarOrDefault(  NMMainDF + "NoiseBinomialN", 10 )
			num2 = NumVarOrDefault(  NMMainDF + "NoiseBinomialP", 0.5 )
			
			Prompt  num1, "n:"
			Prompt  num2, "p ( 0 to 1 ):"
			DoPrompt NMPromptStr( "NM Add Igor binomialNoise " ), num1, num2
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
	
			SetNMvar( NMMainDF + "NoiseBinomialN",  num1 )
			SetNMvar( NMMainDF + "NoiseBinomialP",  num2 )
			
			return NMMainAddNoise( fxn = fxn, num1 = num1, num2 = num2, history = 1 )
			
		case "Exponential":
		
			num1 = NumVarOrDefault(  NMMainDF + "NoiseExpAvg", 1 )
			
			Prompt  num1, "average ( = stdv ):"
			DoPrompt NMPromptStr( "NM Add Igor expNoise" ), num1
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
	
			SetNMvar( NMMainDF + "NoiseExpAvg",  num1 )
		
			return NMMainAddNoise( fxn = fxn, num1 = num1, history = 1 )
			
		case "Gamma":
		
			num1 = NumVarOrDefault(  NMMainDF + "NoiseGammA", 2 )
			num2 = NumVarOrDefault(  NMMainDF + "NoiseGammB", 1 )
			
			Prompt  num1, "gamma a ( > 0 ):"
			Prompt  num2, "gamma b ( > 0 ):"
			DoPrompt NMPromptStr( "NM Add Igor gammaNoise" ), num1, num2
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
	
			SetNMvar( NMMainDF + "NoiseGammA",  num1 )
			SetNMvar( NMMainDF + "NoiseGammB",  num2 )
		
			return NMMainAddNoise( fxn = fxn, num1 = num1, num2 = num2, history = 1 )
			
		case "Gaussian":
		
			num1 = NumVarOrDefault(  NMMainDF + "NoiseGaussStdv", 1 )
			
			Prompt  num1, "standard deviation:"
			DoPrompt NMPromptStr( "NM Add Igor gnoise" ), num1
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
	
			SetNMvar( NMMainDF + "NoiseGaussStdv",  num1 )
		
			return NMMainAddNoise( fxn = fxn, num1 = num1, num2 = num2, history = 1 )
			
		case "LogNormal":
		
			num1 = NumVarOrDefault(  NMMainDF + "NoiseLogNormalM", 1 )
			num2 = NumVarOrDefault(  NMMainDF + "NoiseLogNormalS", 1 )
			
			Prompt  num1, "enter log normal parameter m:"
			Prompt  num2, "enter log normal parameter s:"
			DoPrompt NMPromptStr( "NM Add Igor logNormalNoise" ), num1, num2
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
	
			SetNMvar( NMMainDF + "NoiseLogNormalM",  num1 )
			SetNMvar( NMMainDF + "NoiseLogNormalS",  num2 )
		
			return NMMainAddNoise( fxn = fxn, num1 = num1, num2 = num2, history = 1 )
			
		case "Lorentzian":
		
			num1 = NumVarOrDefault(  NMMainDF + "NoiseLorentzianA", 1 )
			num2 = NumVarOrDefault(  NMMainDF + "NoiseLorentzianB", 1 )
			
			Prompt  num1, "a ( center ):"
			Prompt  num2, "b ( FWHM ):"
			DoPrompt NMPromptStr( "NM Add Igor lorentzianNoise" ), num1, num2
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
	
			SetNMvar( NMMainDF + "NoiseLorentzianA",  num1 )
			SetNMvar( NMMainDF + "NoiseLorentzianB",  num2 )
		
			return NMMainAddNoise( fxn = fxn, num1 = num1, num2 = num2, history = 1 )
			
		case "Poisson":
		
			num1 = NumVarOrDefault(  NMMainDF + "NoisePoissonAvg", 1 )
			
			Prompt  num1, "average ( = variance ):"
			DoPrompt NMPromptStr( "NM Add Igor poissonNoise" ), num1
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
	
			SetNMvar( NMMainDF + "NoisePoissonAvg",  num1 )
		
			return NMMainAddNoise( fxn = fxn, num1 = num1, history = 1 )
			
		case "Uniform":
		
			num1 = NumVarOrDefault(  NMMainDF + "NoiseUniformMinMax", 1 )
			
			Prompt  num1, "limit of uniform distribution ( -limit to +limit ):"
			DoPrompt NMPromptStr( "NM Add Igor enoise" ), num1
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
	
			SetNMvar( NMMainDF + "NoiseUniformMinMax",  num1 )
		
			return NMMainAddNoise( fxn = fxn, num1 = num1, history = 1 )
		
	endswitch
	
	return ""
	
End // zCall_NMMainAddNoise

//****************************************************************
//****************************************************************

Function /S NMMainAddNoise( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, fxn, num1, num2 ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	String fxn
	Variable num1, num2
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( fxn ) )
		return NM2ErrorStr( 21, "fxn", fxn )
	endif
	
	if ( ParamIsDefault( num1 ) )
		return NM2ErrorStr( 11, "num1", num2str( num1 ) )
	endif
	
	NMLoopExecStrAdd( "fxn", fxn, nm )
	NMLoopExecVarAdd( "num1", num1, nm )
	
	if ( !ParamIsDefault( num2 ) )
		NMLoopExecVarAdd( "num2", num2, nm )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainAddNoise

//****************************************************************
//****************************************************************

Function /S NMMainAddNoise2( [ folder, wavePrefix, chanNum, waveSelect, fxn, num1, num2 ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	String fxn
	Variable num1, num2
	
	String fxn2 = "NMAddNoise"
	
	STRUCT NMParams nm
	STRUCT NMBinomialNoise nbin
	STRUCT NMExpNoise nexp
	STRUCT NMGammaNoise ngamma
	STRUCT NMGaussNoise ngauss
	STRUCT NMLogNormalNoise nlog
	STRUCT NMLorentzianNoise nlor
	STRUCT NMPoissonNoise npois
	STRUCT NMUniformNoise nuni
	
	if ( ParamIsDefault( fxn ) )
		return NM2ErrorStr( 21, "fxn", fxn )
	endif
	
	if ( ParamIsDefault( num1 ) )
		return NM2ErrorStr( 11, "num1", num2str( num1 ) )
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn2, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	strswitch( fxn )
	
		case "Binomial":
		
			nbin.n = num1
			nbin.p = num2
			
			return NMAddNoise2( nm, nbin = nbin, history = 1 )
			
		case "Exponential":
		
			nexp.avg = num1
		
			return NMAddNoise2( nm, nexp = nexp, history = 1 )
			
		case "Gamma":
		
			ngamma.a = num1
			ngamma.b = num2
		
			return NMAddNoise2( nm, ngamma = ngamma, history = 1 )
			
		case "Gaussian":
		
			ngauss.stdv = num1
		
			return NMAddNoise2( nm, ngauss = ngauss, history = 1 )
			
		case "LogNormal":
		
			nlog.m = num1
			nlog.s = num2
		
			return NMAddNoise2( nm, nlog = nlog, history = 1 )
			
		case "Lorentzian":
		
			nlor.a = num1
			nlor.b = num2
		
			return NMAddNoise2( nm, nlor = nlor, history = 1 )
			
		case "Poisson":
		
			npois.avg = num1
		
			return NMAddNoise2( nm, npois = npois, history = 1 )
			
		case "Uniform":
		
			nuni.minmax = num1
		
			return NMAddNoise2( nm, nuni = nuni, history = 1 )
		
	endswitch
	
	return ""
	
End // NMMainAddNoise2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainReverse()

	DoAlert /T=( NMPromptStr( "NM Reverse Waves" ) ) 1, "Are you sure you want to reverse the points of the currently selected waves?"
	
	if ( V_Flag == 1 )
		return NMMainReverse( history = 1 )
	endif
	
	return ""

End // zCall_NMMainReverse

//****************************************************************
//****************************************************************

Function /S NMMainReverse( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainReverse

//****************************************************************
//****************************************************************

Function /S NMMainReverse2( [ folder, wavePrefix, chanNum, waveSelect ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum

	String fxn = "NMReverse"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	return NMReverse2( nm, history = 1 )
	
End // NMMainReverse2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainRotate()
	
	Variable points = NumVarOrDefault( NMMainDF + "RotatePoints", 0 )
	Variable direction = 1 + NumVarOrDefault( NMMainDF + "RotateDirection", 0 )

	Prompt points, "number of points to rotate:"
	Prompt direction, "rotate from:", popup "start of wave to end;end of wave to start;"
	DoPrompt NMPromptStr( "NM Rotate Wave Y-Values" ), points, direction
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	direction -= 1
	
	SetNMvar( NMMainDF + "RotatePoints", points )
	SetNMvar( NMMainDF + "RotateDirection", direction )
	
	if ( direction )
		points = -1 * abs( round( points ) ) // negative
	else
		points = abs( round( points ) ) // positive
	endif
	
	return NMMainRotate( points = points, history = 1 )

End // zCall_NMMainRotate

//****************************************************************
//****************************************************************

Function /S NMMainRotate( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, points ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	Variable points // number of points to rotate, see Igor Rotate
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( points ) )
		return NM2ErrorStr( 11, "points", "" )
	endif
	
	NMLoopExecVarAdd( "points", points, nm, integer = 1 )
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainRotate

//****************************************************************
//****************************************************************

Function /S NMMainRotate2( [ folder, wavePrefix, chanNum, waveSelect, points ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	Variable points // number of points to rotate, see Igor Rotate
	
	String fxn = "NMRotate"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( points ) )
		return NM2ErrorStr( 11, "points", "" )
	endif
	
	if ( numtype( points ) > 0 )
		return NM2ErrorStr( 10, "points", "" )
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	return NMRotate2( nm, points, history = 1 )
	
End // NMMainRotate2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainSort()

	String optionsStr, wList = ""
	String folder = CurrentNMFolder( 1 )
	
	String sortKeyWave = StrVarOrDefault( NMMainDF + "SortKeyWaveName", "" )
	
	Variable npnts = NMWaveSelectXstats( "numpnts", -1 )
	
	if ( numtype( npnts ) == 0 )
		optionsStr = NMWaveListOptions( npnts, 0 )
		wList = NMFolderWaveList( folder, "*", ";", optionsStr, 0 )
	endif
	
	Prompt sortKeyWave, "select a wave of key values to sort selected waves against:", popup " ;" + wList
	DoPrompt NMPromptStr( "NM Sort Waves" ), sortKeyWave
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMstr( NMMainDF + "SortKeyWaveName", sortKeyWave )

	return NMMainSort( sortKeyWave = sortKeyWave, history = 1 )

End // zCall_NMMainSort

//****************************************************************
//****************************************************************

Function /S NMMainSort( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, sortKeyWave ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	String sortKeyWave // wave name of single-sort key
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( sortKeyWave ) || ( strlen( sortKeyWave ) == 0 ) )
		return NM2ErrorStr( 21, "sortKeyWave", "" )
	endif
	
	if ( !WaveExists( $sortKeyWave ) )
		return NM2ErrorStr( 1, "sortKeyWave", sortKeyWave )		
	endif
	
	NMLoopExecStrAdd( "sortKeyWave", sortKeyWave, nm )
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainSort

//****************************************************************
//****************************************************************

Function /S NMMainSort2( [ folder, wavePrefix, chanNum, waveSelect, sortKeyWave ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	String sortKeyWave // wave name of single-sort key
	
	String fxn = "NMSort"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( sortKeyWave ) || ( strlen( sortKeyWave ) == 0 ) )
		return NM2ErrorStr( 21, "sortKeyWave", "" )
	endif
	
	if ( !WaveExists( $sortKeyWave ) )
		return NM2ErrorStr( 1, "sortKeyWave", sortKeyWave )
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	return NMSort2( nm, sortKeyWave, history = 1 )
	
End // NMMainSort2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainIntegrate()
	
	Variable method = NumVarOrDefault( NMMainDF + "IntegrateMethod", 1 ) // ( 0 ) rectangular ( 1 ) trapezoid
	
	method += 1
	
	Prompt method, "select integration method:", popup "rectangular;trapezoid;"
	DoPrompt NMPromptStr( "NM Integrate Waves" ), method
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	method -= 1
	
	SetNMvar( NMMainDF + "IntegrateMethod", method )
	
	return NMMainIntegrate( method = method, history = 1 )

End // zCall_NMMainIntegrate

//****************************************************************
//****************************************************************

Function /S NMMainIntegrate( [ folderList, wavePrefixList, chanSelectList, waveSelectList, method, history, deprecation ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable method // ( 0 ) rectangular, default ( 1 ) trapezoid
	Variable history, deprecation
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ( numtype( method ) > 0 ) || ( method < 0 ) || ( method > 1 ) )
		return NM2ErrorStr( 10, "method", num2str( method ) )		
	endif
	
	NMLoopExecVarAdd( "method", method, nm )
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainIntegrate

//****************************************************************
//****************************************************************

Function /S NMMainIntegrate2( [ folder, wavePrefix, chanNum, waveSelect, method ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	Variable method // ( 0 ) rectangular, default ( 1 ) trapezoid
	
	String fxn = "NMIntegrate"
	
	STRUCT NMParams nm
	
	if ( ( numtype( method ) > 0 ) || ( method < 0 ) || ( method > 1 ) )
		return NM2ErrorStr( 10, "method", num2str( method ) )		
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	return NMIntegrate2( nm, method = method, history = 1 )
	
End // NMMainIntegrate2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainDifferentiate()

	DoAlert /T=( NMPromptStr( "NM Differentiate" ) ) 1, "Are you sure you want to differentiate the currently selected waves?"
	
	if ( V_Flag == 1 )
		return NMMainDifferentiate( history = 1 )
	endif
	
	return ""

End // zCall_NMMainDifferentiate

//****************************************************************
//****************************************************************

Function /S NMMainDifferentiate( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainDifferentiate

//****************************************************************
//****************************************************************

Function /S NMMainDifferentiate2( [ folder, wavePrefix, chanNum, waveSelect ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	String fxn = "NMDifferentiate"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	return NMDifferentiate2( nm, history = 1 )
	
End // NMMainDifferentiate2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainFFT()
	
	String promptStr = NMPromptStr( "NM FFT Waves" )
	
	Variable xbgn = NumVarOrDefault( NMMainDF + "FFT_Bgn", -inf )
	Variable xend = NumVarOrDefault( NMMainDF + "FFT_End", inf )
	Variable output = NumVarOrDefault( NMMainDF + "FFT_Output", 3 )
	Variable rotation = 1 + NumVarOrDefault( NMMainDF + "FFT_Rotation", 1 )
	
	Prompt xbgn, NMPromptAddUnitsX( "x-axis FFT window begin" )
	Prompt xend, NMPromptAddUnitsX( "x-axis FFT window end" )
	Prompt output, "select FFT output wave type:", popup "complex;real;magnitude;magnitude square;phase;scaled magnitude;scaled magnitude square;"
	Prompt rotation, "rotate FFT by N/2?", popup "no;yes;"
	
	DoPrompt promptStr, xbgn, xend, output, rotation
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	rotation -= 1
	
	SetNMvar( NMMainDF + "FFT_Bgn", xbgn )
	SetNMvar( NMMainDF + "FFT_End", xend )
	SetNMvar( NMMainDF + "FFT_Output", output )
	SetNMvar( NMMainDF + "FFT_Rotation", rotation )
	
	return NMMainFFT( xbgn = xbgn, xend = xend, output = output, rotation = rotation, history = 1 )

End // zCall_NMMainFFT

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMMainFFT( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, xbgn, xend, output, rotation ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	Variable xbgn, xend
	Variable output // 1-6 ( see Igor FFT )
	Variable rotation // ( 0 ) no ( 1 ) yes
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( ( numtype( xbgn ) == 0 ) || ( numtype( xend ) == 0 ) )
		NMLoopExecVarAdd( "xbgn", xbgn, nm )
		NMLoopExecVarAdd( "xend", xend, nm )
	endif
	
	if ( ParamIsDefault( output ) )
		output = 3
	endif
	
	NMLoopExecVarAdd( "output", output, nm, integer = 1 )
	
	if ( ParamIsDefault( rotation ) )
		rotation = 1
	endif
	
	if ( !rotation )
		NMLoopExecVarAdd( "rotation", rotation, nm, integer = 1 )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainFFT

//****************************************************************
//****************************************************************

Function /S NMMainFFT2( [ folder, wavePrefix, chanNum, waveSelect, xbgn, xend, output, rotation ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	Variable xbgn, xend
	Variable output // 1-6 ( see Igor FFT )
	Variable rotation // ( 0 ) no ( 1 ) yes
	
	String returnStr, chanChar, xLabel, yLabel, fxn = "NMFFT"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( ParamIsDefault( output ) )
		output = 3
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	returnStr = NMFFT2( nm, xbgn = xbgn, xend = xend, output = output, rotation = rotation, updateLabels = 0, history = 1 )
	
	xLabel = "1/" + NMChanLabelX()
	yLabel = "FFT " + NMFFTOuputStr( output )
	chanChar = ChanNum2Char( nm.chanNum )
	
	NMMainLabel( folderList=nm.folder, wavePrefixList=nm.wavePrefix, chanSelectList= chanChar, waveSelectList=nm.waveSelect, xLabel=xLabel, yLabel=yLabel )
	
	return returnStr
	
End // NMMainFFT2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainReplaceValue()
	
	Variable find = NumVarOrDefault( NMMainDF + "ReplaceFind", 0 )
	Variable replacement = NumVarOrDefault( NMMainDF + "ReplaceValue", 0 )
	
	Prompt find, "wave value to find:"
	Prompt replacement, "replacement value:"
	
	DoPrompt NMPromptStr( "NM Replace Wave Value" ), find, replacement
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMvar( NMMainDF + "ReplaceFind", find )
	SetNMvar( NMMainDF + "ReplaceValue", replacement )

	return NMMainReplaceValue( find = find, replacement = replacement, history = 1 )

End // zCall_NMMainReplaceValue

//****************************************************************
//****************************************************************

Function /S NMMainReplaceValue( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, find, replacement ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	Variable find // value in wave to find ( must specify )
	Variable replacement // replacement value ( must specify )
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( find ) )
		return NM2ErrorStr( 11, "find", "" )
	endif
	
	if ( ParamIsDefault( replacement ) )
		return NM2ErrorStr( 11, "replacement", "" )
	endif
	
	NMLoopExecVarAdd( "find", find, nm )
	NMLoopExecVarAdd( "replacement", replacement, nm )
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainReplaceValue

//****************************************************************
//****************************************************************

Function /S NMMainReplaceValue2( [ folder, wavePrefix, chanNum, waveSelect, find, replacement ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	Variable find // value in wave to find
	Variable replacement // replacement value
	
	String fxn = "NMReplaceValue"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( find ) )
		return NM2ErrorStr( 11, "find", "" )
	endif
	
	if ( ParamIsDefault( replacement ) )
		return NM2ErrorStr( 11, "replacement", "" )
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	return NMReplaceValue2( nm, find, replacement, history = 1 )
	
End // NMMainReplaceValue2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainDeleteNaNs()

	DoAlert /T=( NMPromptStr( "NM Delete NaNs" ) ) 1, "Are you sure you want to delete all NAN's from the currently selected waves?"
	
	if ( V_Flag == 1 )
		return NMMainDeleteNaNs( history = 1 )
	endif
	
	return ""

End // zCall_NMMainDeleteNaNs

//****************************************************************
//****************************************************************

Function /S NMMainDeleteNaNs( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainDeleteNaNs

//****************************************************************
//****************************************************************

Function /S NMMainDeleteNaNs2( [ folder, wavePrefix, chanNum, waveSelect ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	String fxn = "NMDeleteNaNs"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	return NMDeleteNaNs2( nm, history = 1 )
	
End // NMMainDeleteNaNs2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainClipEvents()
	
	String promptStr = NMPromptStr( "NM Clip Events" )
	String wList = " ;" + WaveList( "*",";","TEXT:0" )
	
	Variable findEvents = NumVarOrDefault( NMMainDF + "ClipEventsFind", 1 )
	Variable clipAlg = NumVarOrDefault( NMMainDF + "ClipEventsAlgorithm", 1 )
	Variable positiveEvents = 1 + NumVarOrDefault( NMMainDF + "ClipEventsPositive", 1 )
	Variable eventFindLevel = NumVarOrDefault( NMMainDF + "ClipEventsLevel", 10 )
	Variable xwinBeforeEvent = NumVarOrDefault( NMMainDF + "ClipEventsXwinBefore", 1 )
	Variable xwinAfterEvent = NumVarOrDefault( NMMainDF + "ClipEventsXwinAfter", 1 )
	Variable clipValue = NumVarOrDefault( NMMainDF + "ClipEventsValue", NaN )
	
	String waveOfEventTimes = StrVarOrDefault( NMMainDF + "ClipEventsWaveName", "" )
	
	Prompt findEvents, "locate event times via:", popup "level detection;existing wave of event times;"
	Prompt clipAlg, "clip events via:", popup "linear interpolation;a single clip value;"
	Prompt xwinBeforeEvent, NMPromptAddUnitsX( "x-axis window to clip before events" )
	Prompt xwinAfterEvent, NMPromptAddUnitsX( "x-axis window to clip after events" )
	Prompt positiveEvents, " ", popup "clip negative events;clip positive events;"
	Prompt eventFindLevel, "event detection level:"
	Prompt waveOfEventTimes, "select wave containing x-axis event values:", popup wList
	Prompt clipValue, "clip with value:"
	
	DoPrompt promptStr, findEvents, clipAlg, xwinBeforeEvent, xwinAfterEvent
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMvar( NMMainDF + "ClipEventsFind", findEvents )
	SetNMvar( NMMainDF + "ClipEventsAlgorithm", clipAlg )
	SetNMvar( NMMainDF + "ClipEventsXwinBefore", xwinBeforeEvent )
	SetNMvar( NMMainDF + "ClipEventsXwinAfter", xwinAfterEvent )
	
	if ( findEvents == 1 ) // level detection
	
		if ( clipAlg == 1 ) // linear interp
		
			DoPrompt promptStr, positiveEvents, eventFindLevel
	
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
			positiveEvents -= 1
			
			SetNMvar( NMMainDF + "ClipEventsPositive", positiveEvents )
			SetNMvar( NMMainDF + "ClipEventsLevel", eventFindLevel )
			
			return NMMainClipEvents( positiveEvents = positiveEvents, eventFindLevel = eventFindLevel, xwinBeforeEvent = xwinBeforeEvent, xwinAfterEvent = xwinAfterEvent, history = 1 )
		
		else // clip value
		
			DoPrompt promptStr, positiveEvents, eventFindLevel, clipValue
	
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
			positiveEvents -= 1
			
			SetNMvar( NMMainDF + "ClipEventsPositive", positiveEvents )
			SetNMvar( NMMainDF + "ClipEventsLevel", eventFindLevel )
			SetNMvar( NMMainDF + "ClipEventsValue", clipValue )
			
			return NMMainClipEvents( positiveEvents = positiveEvents, eventFindLevel = eventFindLevel, xwinBeforeEvent = xwinBeforeEvent, xwinAfterEvent = xwinAfterEvent, clipValue = clipValue, history = 1 )
		
		endif
	
	elseif ( findEvents == 2 ) // existing wave of event times
	
		if ( clipAlg == 1 ) // linear interp
		
			DoPrompt promptStr, waveOfEventTimes
	
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
			SetNMstr( NMMainDF + "ClipEventsWaveName", waveOfEventTimes )
			
			return NMMainClipEvents( xwinBeforeEvent = xwinBeforeEvent, xwinAfterEvent = xwinAfterEvent, waveOfEventTimes = waveOfEventTimes, history = 1 )
		
		else // use clip value
		
			DoPrompt promptStr, waveOfEventTimes, clipValue
	
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
			SetNMstr( NMMainDF + "ClipEventsWaveName", waveOfEventTimes )
			SetNMvar( NMMainDF + "ClipEventsValue", clipValue )
	
			return NMMainClipEvents( xwinBeforeEvent = xwinBeforeEvent, xwinAfterEvent = xwinAfterEvent, clipValue = clipValue, waveOfEventTimes = waveOfEventTimes, history = 1 )
		
		endif
	
	endif
	
End // zCall_NMMainClipEvents

//****************************************************************
//****************************************************************

Function /S NMMainClipEvents( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, xwinBeforeEvent, xwinAfterEvent, eventFindLevel, positiveEvents, waveOfEventTimes, clipValue ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	Variable xwinBeforeEvent // x-axis window to clip before detected event
	Variable xwinAfterEvent // x-axis window to clip after detected event
	Variable eventFindLevel // see parameter "level" for Igor function FindLevels 
	Variable positiveEvents // ( 0 ) negative events ( 1 ) positive events for FindLevels
	String waveOfEventTimes // name of wave containing event times, if used this will bypass event detection using FindLevels
	Variable clipValue // clip event with this value, rather than interpolation method
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	Variable findEvents = 1 // ( 0 ) use waveOfEventTimes ( 1 ) use FindLevels
	
	if ( ParamIsDefault( xwinBeforeEvent ) )
		return NM2ErrorStr( 11, "xwinBeforeEvent", "" )
	endif
	
	if ( ParamIsDefault( xwinAfterEvent ) )
		return NM2ErrorStr( 11, "xwinAfterEvent", "" )
	endif
	
	NMLoopExecVarAdd( "xwinBeforeEvent", xwinBeforeEvent, nm )
	NMLoopExecVarAdd( "xwinAfterEvent", xwinAfterEvent, nm )
	
	if ( ParamIsDefault( waveOfEventTimes ) )
	
		waveOfEventTimes = ""
	
		if ( ParamIsDefault( eventFindLevel ) )
			return NM2ErrorStr( 11, "eventFindLevel", "" )
		endif
		
		NMLoopExecVarAdd( "eventFindLevel", eventFindLevel, nm )
		
		if ( !ParamIsDefault( positiveEvents ) )
			NMLoopExecVarAdd( "positiveEvents", positiveEvents, nm, integer = 1 )
		endif
	
	else
	
		NMLoopExecStrAdd( "waveOfEventTimes", waveOfEventTimes, nm )
		findEvents = 0
	
	endif
	
	if ( NMClipEventsError( xwinBeforeEvent, xwinAfterEvent, findEvents, eventFindLevel, waveOfEventTimes ) != 0 )
		return ""
	endif
	
	if ( !ParamIsDefault( clipValue ) )
		NMLoopExecVarAdd( "clipValue", clipValue, nm )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainClipEvents

//****************************************************************
//****************************************************************

Function /S NMMainClipEvents2( [ folder, wavePrefix, chanNum, waveSelect, xwinBeforeEvent, xwinAfterEvent, eventFindLevel, positiveEvents, waveOfEventTimes, clipValue ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	Variable xwinBeforeEvent // x-axis window to clip before detected event
	Variable xwinAfterEvent // x-axis window to clip after detected event
	Variable eventFindLevel // see parameter "level" for Igor function FindLevels 
	Variable positiveEvents // ( 0 ) negative events ( 1 ) positive events for FindLevels
	String waveOfEventTimes // name of wave containing event times, if used this will bypass event detection using FindLevels
	Variable clipValue // clip event with this value, rather than interpolation method
	
	String fxn = "NMClipEvents"
	
	STRUCT NMParams nm
	
	Variable findEvents = 1 // ( 0 ) use waveOfEventTimes ( 1 ) use FindLevels
	Variable clipMethod = 0 // ( 0 ) linear interpolation ( 1 ) clip with clipValue
	
	if ( ParamIsDefault( xwinBeforeEvent ) )
		return NM2ErrorStr( 11, "xwinBeforeEvent", "" )
	endif
	
	if ( ParamIsDefault( xwinAfterEvent ) )
		return NM2ErrorStr( 11, "xwinAfterEvent", "" )
	endif
	
	if ( ParamIsDefault( waveOfEventTimes ) )
	
		waveOfEventTimes = ""
	
		if ( ParamIsDefault( eventFindLevel ) )
			return NM2ErrorStr( 11, "eventFindLevel", "" )
		endif
	
	else
	
		findEvents = 0
	
	endif
	
	if ( NMClipEventsError( xwinBeforeEvent, xwinAfterEvent, findEvents, eventFindLevel, waveOfEventTimes ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( positiveEvents ) )
		positiveEvents = 1
	endif
	
	if ( !ParamIsDefault( clipValue ) )
		clipMethod = 1
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm ) != 0 )
		return ""
	endif
	
	if ( findEvents )
		if ( clipMethod == 1 )
			return NMClipEvents2( nm, xwinBeforeEvent, xwinAfterEvent, eventFindLevel = eventFindLevel, positiveEvents = positiveEvents, clipValue = clipValue, history = 1 )
		else
			return NMClipEvents2( nm, xwinBeforeEvent, xwinAfterEvent, eventFindLevel = eventFindLevel, positiveEvents = positiveEvents, history = 1 )
		endif
	else
		if ( clipMethod == 1 )
			return NMClipEvents2( nm, xwinBeforeEvent, xwinAfterEvent, waveOfEventTimes = waveOfEventTimes, clipValue = clipValue, history = 1 )
		else
			return NMClipEvents2( nm, xwinBeforeEvent, xwinAfterEvent, waveOfEventTimes = waveOfEventTimes, history = 1 )
		endif
	endif
	
End // NMMainClipEvents2

//****************************************************************
//****************************************************************
//
//		Wave Functions
//		WaveStats, Average, Sum, Histogram...
//
//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainWaveStats()

	String promptStr = NMPromptStr( "NM Wave Stats" )
	
	Variable transforms
	
	Variable xbgn = NumVarOrDefault( NMMainDF + "WaveStatsXbgn", -inf )
	Variable xend = NumVarOrDefault( NMMainDF + "WaveStatsXend", inf )
	Variable outputSelect = NumVarOrDefault( NMMainDF + "WaveStatsOutputSelect", 3 )
	Variable useSubfolders = 1 + NumVarOrDefault( NMMainDF + "WaveStatsUseSubfolders", 1 )
	
	Prompt transforms, "Use channel Filter/Transforms on your data?", popup "no;yes;"
	Prompt xbgn, NMPromptAddUnitsX( "x-axis window begin" )
	Prompt xend, NMPromptAddUnitsX( "x-axis window end" )
	Prompt outputSelect, "save results to:" popup "Igor history;notebook;table;"
	Prompt useSubfolders, "create table waves in a subfolder?" popup "no;yes;"
	
	if ( NMChanTransformExists( chanCharList = NMChanSelectCharList() ) )
	
		transforms = 1 + NumVarOrDefault( NMMainDF + "WaveStatsTransforms", 1 )
		
		DoPrompt promptStr, transforms
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		transforms -= 1
		
		SetNMvar( NMMainDF + "WaveStatsTransforms", transforms )
		
	else
	
		transforms = -1
		
	endif
	
	DoPrompt promptStr, xbgn, xend, outputSelect
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMvar( NMMainDF + "WaveStatsXbgn", xbgn )
	SetNMvar( NMMainDF + "WaveStatsXend", xend )
	SetNMvar( NMMainDF + "WaveStatsOutputSelect", outputSelect )
	
	if ( outputSelect == 3 )
	
		DoPrompt promptStr, useSubfolders
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		useSubfolders -= 1
		
		SetNMvar( NMMainDF + "WaveStatsUseSubfolders", useSubfolders )
		
	endif
	
	switch( outputSelect )
		case 1:
		case 2:
			return NMMainWaveStats( transforms = transforms, xbgn = xbgn, xend = xend, outputSelect = outputSelect, history = 1 )
		case 3:
			if ( useSubfolders )
				return NMMainWaveStats( transforms = transforms, xbgn = xbgn, xend = xend, outputSelect = outputSelect, subfolder = "_default_", history = 1 )
			else
				return NMMainWaveStats( transforms = transforms, xbgn = xbgn, xend = xend, outputSelect = outputSelect, history = 1 )
			endif
	endswitch
	
End // zCall_NMMainWaveStats

//****************************************************************
//****************************************************************

Function /S NMMainWaveStats( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, transforms, xbgn, xend, outputSelect, subfolder ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	Variable transforms // use channel Filter/Transform on input data waves ( 0 ) no ( 1 ) yes
	Variable xbgn, xend
	Variable outputSelect // ( 0 ) return stats string list ( 1 ) Igor history ( 2 ) notebook ( 3 ) table
	String subfolder // subfolder name for table waves, pass nothing for no subfolder, or "_default_" for automatic name generation
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( ( numtype( xbgn ) == 0 ) || ( numtype( xend ) == 0 ) )
		NMLoopExecVarAdd( "xbgn", xbgn, nm )
		NMLoopExecVarAdd( "xend", xend, nm )
	endif
	
	if ( !ParamIsDefault( outputSelect ) )
		NMLoopExecVarAdd( "outputSelect", outputSelect, nm, integer = 1 )
	endif
	
	if ( !ParamIsDefault( subfolder ) )
		NMLoopExecStrAdd( "subfolder", subfolder, nm )
	endif
	
	if ( transforms >= 0 )
		NMLoopExecVarAdd( " transforms",  transforms, nm, integer = 1 )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	//nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainWaveStats

//****************************************************************
//****************************************************************

Function /S NMMainWaveStats2( [ folder, wavePrefix, chanNum, waveSelect, transforms, xbgn, xend, outputSelect, subfolder ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	Variable transforms // use channel Filter/Transform on input data waves ( 0 ) no ( 1 ) yes
	Variable xbgn, xend
	Variable outputSelect // ( 0 ) return stats string list ( 1 ) Igor history, default ( 2 ) notebook ( 3 ) table
	String subfolder // subfolder name for table waves, pass nothing for no subfolder, or "_default_" for automatic name generation
	
	Variable useSubfolders
	String fxn = "NMWaveStats"
	String winPrefix, windowName, windowTitle, folderPrefix = "WStats_"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( transforms ) )
		transforms = 1
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
	
	if ( !ParamIsDefault( subfolder ) )
		useSubfolders = 1
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm, transforms = transforms ) != 0 )
		return ""
	endif
	
	if ( ( outputSelect == 0 ) || ( outputSelect == 1 ) ) // return string list or Igor history
		
		return NMWaveStats2( nm, xbgn = xbgn, xend = xend, outputSelect = outputSelect )
		
	endif
	
	if ( outputSelect == 2 ) // notebook
	
		windowName = NMMainWindowName( folder, wavePrefix, chanNum, waveSelect, "notebook" )
		windowTitle = NMMainWindowTitle( "WaveStats", folder, wavePrefix, chanNum, waveSelect, nm.wList )
	
		return NMWaveStats2( nm, xbgn = xbgn, xend = xend, outputSelect = 2, windowName = windowName, windowTitle = windowTitle, history = 1 )
		
	endif
	
	if ( outputSelect != 3 )
		return ""
	endif
	
	// table
	
	windowName = NMMainWindowName( folder, wavePrefix, chanNum, waveSelect, "table" )
	windowTitle = NMMainWindowTitle( "WaveStats", folder, wavePrefix, chanNum, waveSelect, nm.wList )
	
	if ( !useSubfolders )
		return NMWaveStats2( nm, xbgn = xbgn, xend = xend, outputSelect = 3, windowName = windowName, windowTitle = windowTitle )
	endif
	
	if ( StringMatch( subfolder, "_default_" ) || ( strlen( subfolder ) == 0 ) )
		subfolder = NMSubfolderName( folderPrefix, wavePrefix, chanNum, waveSelect )
		CheckNMSubfolder( subfolder )
	endif
	
	return NMWaveStats2( nm, xbgn = xbgn, xend = xend, outputSelect = 3, subfolder = subfolder, windowName = windowName, windowTitle = windowTitle, history = 1 )
		
End // NMMainWaveStats2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainMatrixStats( select )
	String select // "Average" or "Sum" or "SumSqrs"

	Variable ccnt, dx, waveNANs, lftx, rghtx, all, errors2flag, sameDx = 1
	String sprefix = select, selectList, vList = ""
	
	String promptStr = NMPromptStr( "NM Matrix Stats" )
	
	String waveSelect = NMWaveSelectGet()
	
	if ( StringMatch( waveSelect, "All Groups" ) || StringMatch( waveSelect, "All Sets" ) )
		all = 1
	endif
	
	Variable sameXScale = NMWavesHaveSameXScale()
	Variable mode = 2
	Variable xbgn = -inf
	Variable xend = inf
	Variable errors2 = 0
	Variable transforms = 1
	Variable ignoreNANs = 1
	Variable truncateToCommonXScale = 1
	Variable saveMatrix = 0
	Variable graph = 1
	Variable graphInputs = 1
	Variable oneGraphPerChan = 1
	
	for ( ccnt = 0 ; ccnt < NMNumChannels() ; ccnt += 1 )
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue
		endif
		
		dx = NMWaveSelectXstats( "deltax", ccnt )
		
		if ( numtype( dx ) > 0 )
			sameDx = 0
		endif
	
	endfor
	
	Prompt transforms, "Use channel Filter/Transforms on your data?", popup "no;yes;"
	Prompt mode, "Compute:", popup "Avg;Avg + Stdv;Avg + SEM;Avg + Var;Sum;SumSqrs;"
	Prompt xbgn, NMPromptAddUnitsX( "x-axis window begin" )
	Prompt xend, NMPromptAddUnitsX( "x-axis window end" )
	Prompt errors2, "create errors as:", popup "one wave;two waves;"
	Prompt ignoreNANs, "Your data contains NANs (non-numbers). Do you want to ignore them?", popup "no;yes;"
	Prompt truncateToCommonXScale, "Your data waves have different x-scales. " + select + " should include:", popup "all given x-axis points;only common x-axis points;"
	Prompt graph, "Display results in a graph?", popup, "no;yes;"
	Prompt graphInputs, "Include selected data waves in final graph?", popup "no;yes;"
	Prompt oneGraphPerChan, "Plot " + NMQuotes( waveSelect ) + " in the same graph?", popup, "no;yes;"
	
	String modeStr = "Mode"
	String xbgnStr = "Xbgn"
	String xendStr = "Xend"
	String errors2Str = "Errors2"
	String transformsStr = "Transforms"
	String NANstr = "IgnoreNANs"
	String truncateStr = "Truncate"
	String graphStr = "Graph"
	String graphInputsStr = "GraphInputs"
	String oneGraphStr = "OneGraphPerChan"
	
	strswitch( select )
	
		case "Average":
			sprefix = "Avg"
			break
			
		case "Sum":
			mode = 5
			modeStr = ""
			errors2Str = ""
			break
			
		case "SumSqrs":
			mode = 6
			modeStr = ""
			errors2Str = ""
			break
			
		default:
			return ""

	endswitch
	
	if ( strlen( modeStr ) > 0 )
		mode = NumVarOrDefault( NMMainDF + sprefix + modeStr, mode )
	endif
	
	if ( strlen( xbgnStr ) > 0 )
		xbgn = NumVarOrDefault( NMMainDF + sprefix + xbgnStr, xbgn )
	endif
	
	if ( strlen( xendStr ) > 0 )
		xend = NumVarOrDefault( NMMainDF + sprefix + xendStr, xend )
	endif
	
	if ( strlen( errors2Str ) > 0 )
		errors2 = NumVarOrDefault( NMMainDF + sprefix + errors2Str, errors2 )
	endif
	
	if ( strlen( transformsStr ) > 0 )
		transforms = BinaryCheck( NumVarOrDefault( NMMainDF + sprefix + transformsStr, transforms ) )
	endif
	
	if ( strlen( NANstr ) > 0 )
		ignoreNANs = BinaryCheck( NumVarOrDefault( NMMainDF + sprefix + NANstr, ignoreNANs ) )
	endif
	
	if ( strlen( truncateStr ) > 0 )
		truncateToCommonXScale = BinaryCheck( NumVarOrDefault( NMMainDF + sprefix + truncateStr, truncateToCommonXScale ) )
	endif
	
	if ( strlen( graphStr ) > 0 )
		graph = BinaryCheck( NumVarOrDefault( NMMainDF + sprefix + graphStr, graph ) )
	endif
	
	if ( strlen( graphInputsStr ) > 0 )
		graphInputs = BinaryCheck( NumVarOrDefault( NMMainDF + sprefix + graphInputsStr, graphInputs ) )
	endif
	
	if ( strlen( oneGraphStr ) > 0 )
		oneGraphPerChan = BinaryCheck( NumVarOrDefault( NMMainDF + sprefix + oneGraphStr, oneGraphPerChan ) )
	endif
	
	graph += 1
	
	if ( NMChanTransformExists( chanCharList = NMChanSelectCharList() ) )
	
		transforms += 1
		
		DoPrompt promptStr, transforms
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		transforms -= 1
		
	else
	
		transformsStr = ""
		transforms = -1
		
	endif
	
	DoPrompt promptStr, mode, xbgn, xend, graph
		
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	graph -= 1
	
	if ( ( mode == 2 ) || ( mode == 3 ) )
		errors2flag = 1
	endif
	
	if ( graph )
	
		if ( transforms == 1 )
			graphInputs = 0
			Prompt graphInputs, "Include selected data waves in final graph?", popup "no ( transforms are on );"
		endif
	
		graphInputs += 1
	
		if ( all )
		
			oneGraphPerChan += 1
			
			if ( errors2flag )
			
				errors2 += 1
			
				DoPrompt promptStr, errors2, graphInputs, oneGraphPerChan
				
				errors2 -= 1
			
			else
			
				DoPrompt promptStr, graphInputs, oneGraphPerChan
			
			endif
			
			oneGraphPerChan -= 1
			
		else
		
			oneGraphStr = ""
			oneGraphPerChan = 1
			
			if ( errors2flag )
			
				errors2 += 1
				
				DoPrompt promptStr, errors2, graphInputs
				
				errors2 -= 1
				
			elseif ( transforms != 1 )
			
				DoPrompt promptStr, graphInputs
			
			endif
			
		endif
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		graphInputs -= 1
		
	else
	
		graphInputsStr = ""
		graphInputs = 0
		oneGraphStr = ""
		oneGraphPerChan = 1
		
		if ( errors2flag )
			
			errors2 += 1
		
			DoPrompt promptStr, errors2
			
			errors2 -= 1
			
		endif
	
	endif
	
	sameXScale = NMWavesHaveSameXScale( xbgn = xbgn, xend = xend )
	
	if ( !sameXScale )
	
		truncateToCommonXScale += 1
	
		DoPrompt promptStr, truncateToCommonXScale
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		truncateToCommonXScale -= 1
		
	else
	
		truncateStr = ""
		truncateToCommonXScale = 1
		
	endif
	
	if ( truncateToCommonXScale )
		lftx = NMChanXstats( "maxLeftx" )
		rghtx = NMChanXstats( "minRightx" )
	else
		lftx = NMChanXstats( "minLeftx" )
		rghtx = NMChanXstats( "maxRightx" )
	endif
	
	waveNANs = NMWavesHaveNANs( lftx, rghtx )
	
	if ( waveNANs && truncateToCommonXScale )
	
		ignoreNANs += 1
	
		DoPrompt promptStr, ignoreNANs
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		ignoreNANs -= 1
		
	endif
	
	if ( !truncateToCommonXScale )
		ignoreNANs = 1 // NANs must be ignored in this case
	endif
	
	if ( strlen( modeStr ) > 0 )
		SetNMvar( NMMainDF + sprefix + modeStr, mode )
	endif
	
	if ( strlen( xbgnStr ) > 0 )
		SetNMvar( NMMainDF + sprefix + xbgnStr, xbgn )
	endif
	
	if ( strlen( xendStr ) > 0 )
		SetNMvar( NMMainDF + sprefix + xendStr, xend )
	endif
	
	if ( strlen( errors2Str ) > 0 )
		SetNMvar( NMMainDF + sprefix + errors2Str, errors2 )
	endif
	
	if ( strlen( transformsStr ) > 0 )
		SetNMvar( NMMainDF + sprefix + transformsStr, transforms )
	endif
	
	if ( strlen( NANstr ) > 0 )
		SetNMvar( NMMainDF + sprefix + NANstr, ignoreNANs )
	endif
	
	if ( strlen( truncateStr ) > 0 )
		SetNMvar( NMMainDF + sprefix + truncateStr, truncateToCommonXScale )
	endif
	
	if ( strlen( graphStr ) > 0 )
		SetNMvar( NMMainDF + sprefix + graphStr, graph )
	endif
	
	if ( strlen( graphInputsStr ) > 0 )
		SetNMvar( NMMainDF + sprefix + graphInputsStr, graphInputs )
	endif
	
	if ( strlen( oneGraphStr ) > 0 )
		SetNMvar( NMMainDF + sprefix + oneGraphStr, oneGraphPerChan )
	endif
	
	STRUCT NMMatrixStatsStruct s
	
	s.xbgn = xbgn
	s.xend = xend
	s.ignoreNANs = ignoreNANs
	s.truncateToCommonXScale = truncateToCommonXScale
	s.saveMatrix = saveMatrix
	
	switch( mode )
		case 1:
			selectList = "avg"
			break
		case 2:
			selectList = "avg;stdv;"
			break
		case 3:
			selectList = "avg;sem;"
			break
		case 4:
			selectList = "avg;var;"
			break
		case 5:
			selectList = "sum"
			break
		case 6:
			selectList = "sumsqrs"
			break
		default:
			return ""
	endswitch
	
	if ( all && oneGraphPerChan )
		if ( errors2flag )
			return NMMainMatrixStats( transforms = transforms, selectList = selectList, s = s, errors2 = errors2, graph = graph, graphInputs = graphInputs, all = waveSelect, history = 1 )
		else
			return NMMainMatrixStats( transforms = transforms, selectList = selectList, s = s, graph = graph, graphInputs = graphInputs, all = waveSelect, history = 1 )
		endif
	else
		if ( errors2flag )
			return NMMainMatrixStats( transforms = transforms, selectList = selectList, s = s, errors2 = errors2, graph = graph, graphInputs = graphInputs, history = 1 )
		else
			return NMMainMatrixStats( transforms = transforms, selectList = selectList, s = s, graph = graph, graphInputs = graphInputs, history = 1 )
		endif
	endif
	
End // zCall_NMMainMatrixStats

//****************************************************************
//****************************************************************

Function /S NMMainMatrixStats( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, transforms, selectList, xbgn, xend, ignoreNANs, truncateToCommonXScale, saveMatrix, s, errors2, graph, graphInputs, all ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	Variable transforms // use channel Filter/Transform on input data waves ( 0 ) no ( 1 ) yes ( -1 ) transforms do not exist
	String selectList // list of what to compute, e.g. "avg;stdv;sem;var;sum;sumsqrs;"
	Variable xbgn, xend
	Variable ignoreNANs // ( 0 ) no ( 1 ) yes
	Variable truncateToCommonXScale // ( 0 ) no. if necessary, inputs waves are expanded to fit all min and max x-values ( 1 ) yes. input waves are truncated to a common x-axis ( temporary operations )
	Variable saveMatrix // save input waves as 2D matrix ( 0 ) no ( 1 ) yes ( includes transformations and interpolation )
	STRUCT NMMatrixStatsStruct &s // or pass this structure
	
	Variable errors2 // ( 0 ) one error wave ( 1 ) two error waves ( mean - error, mean + error )
	Variable graph // create output graph ( 0 ) no ( 1 ) yes
	Variable graphInputs // include input waves in graphs ( 0 ) no ( 1 ) yes, default
	String all // "All Sets" or "All Groups" for graphs - puts them all in one graph
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( selectList ) || ( ItemsInList( selectList ) == 0 ) )
		return NM2ErrorStr( 21, "selectList", "" )
	endif
	
	NMLoopExecStrAdd( "selectList", selectList, nm )
	
	if ( ParamIsDefault( s ) )
	
		if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
			xbgn = -inf
		endif
		
		if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
			xend = inf
		endif
		
		if ( ( numtype( xbgn ) == 0 ) || ( numtype( xend ) == 0 ) )
			NMLoopExecVarAdd( "xbgn", xbgn, nm )
			NMLoopExecVarAdd( "xend", xend, nm )
		endif
	
		if ( !ParamIsDefault( ignoreNANs ) )
			NMLoopExecVarAdd( "ignoreNANs", ignoreNANs, nm, integer = 1 )
		endif
		
		if ( !ParamIsDefault( truncateToCommonXScale ) )
			NMLoopExecVarAdd( "truncateToCommonXScale", truncateToCommonXScale, nm, integer = 1 )
		endif
		
		if ( saveMatrix )
			NMLoopExecVarAdd( "saveMatrix", saveMatrix, nm, integer = 1 )
		endif
	
	else
	
		if ( numtype( s.xbgn ) > 0 )
			s.xbgn = -inf
		endif
		
		if ( numtype( s.xend ) > 0 )
			s.xend = inf
		endif
		
		if ( ( numtype( s.xbgn ) == 0 ) || ( numtype( s.xend ) == 0 ) )
			NMLoopExecVarAdd( "xbgn", s.xbgn, nm )
			NMLoopExecVarAdd( "xend", s.xend, nm )
		endif
		
		NMLoopExecVarAdd( "ignoreNANs", s.ignoreNANs, nm, integer = 1 )
		NMLoopExecVarAdd( "truncateToCommonXScale", s.truncateToCommonXScale, nm, integer = 1 )
		
		if ( s.saveMatrix )
			NMLoopExecVarAdd( "saveMatrix", 1, nm, integer = 1 )
		endif
	
	endif
	
	if ( errors2 )
		NMLoopExecVarAdd( "errors2", errors2, nm, integer = 1 )
	endif
	
	if ( ParamIsDefault( graph ) )
		graph = 1
	else
		NMLoopExecVarAdd( "graph", graph, nm, integer = 1 )
	endif
	
	if ( graph )
		
		if ( !ParamIsDefault( graphInputs ) )
			NMLoopExecVarAdd( "graphInputs", graphInputs, nm, integer = 1 )
		endif
		
		if ( !ParamIsDefault( all ) && ( strlen( all ) > 0 ) )
			NMLoopExecStrAdd( "all", all, nm )
		endif
		
	endif
	
	if ( transforms >= 0 )
		NMLoopExecVarAdd( "transforms", transforms, nm, integer = 1 )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	//nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainMatrixStats

//****************************************************************
//****************************************************************

Function /S NMMainMatrixStats2( [ folder, wavePrefix, chanNum, waveSelect, transforms, selectList, xbgn, xend, ignoreNANs, truncateToCommonXScale, saveMatrix, errors2, graph, graphInputs, all ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	Variable transforms // use channel Filter/Transform on input data waves ( 0 ) no ( 1 ) yes
	String selectList // list of what to compute, e.g. "avg;stdv;sem;var;sum;sumsqrs;"
	Variable xbgn, xend
	Variable ignoreNANs // ( 0 ) no ( 1 ) yes
	Variable truncateToCommonXScale // ( 0 ) no. if necessary, inputs waves are expanded to fit all min and max x-values ( 1 ) yes. input waves are truncated to a common x-axis ( temporary operations )
	Variable saveMatrix // save input waves as 2D matrix ( 0 ) no ( 1 ) yes ( includes transformations and interpolation )
	Variable errors2 // ( 0 ) one error wave ( 1 ) two error waves ( mean - error, mean + error )
	Variable graph // create output graph ( 0 ) no ( 1 ) yes
	Variable graphInputs // include input waves in graphs ( 0 ) no ( 1 ) yes, default
	String all // "All Sets" or "All Groups" for graphs - puts them all in one graph
	
	Variable icount, icnt, jcnt, STDV, SEM
	String wName, wName2, wList, xWave = "", gName, fxn = "NMMatrixStats"
	
	Variable history = 1
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( transforms ) )
		transforms = 1
	endif
	
	if ( ParamIsDefault( selectList ) || ( ItemsInList( selectList ) == 0 ) )
		return NM2ErrorStr( 21, "selectList", "" )
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
	
	if ( ParamIsDefault( truncateToCommonXScale ) )
		truncateToCommonXScale = 1
	endif
	
	if ( ParamIsDefault( graph ) )
		graph = 1
	endif
	
	if ( ParamIsDefault( graphInputs ) )
		graphInputs = 1
	endif
	
	if ( ParamIsDefault( all ) )
		all = ""
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm, transforms = transforms ) != 0 )
		return ""
	endif
	
	STRUCT NMMatrixStatsStruct s
	
	s.xbgn = xbgn
	s.xend = xend
	s.ignoreNANs = ignoreNANs
	s.truncateToCommonXScale = truncateToCommonXScale
	s.saveMatrix = saveMatrix
	
	NMMatrixStats2( nm, s, history = history )
	
	if ( ItemsInList( nm.newList ) == 0 )
		return "" // nothing to do
	endif
	
	if ( WhichListItem( "stdv", selectList ) >= 0 )
		STDV = 1
	elseif ( WhichListItem( "sem", selectList ) >= 0 )
		SEM = 1
	endif
	
	zNMMainMatrixStatsRename( selectList, errors2, nm, s )
	NMMatrixStatsStructKill( s )
	
	if ( graph )
	
		nm.windowList = ""
		
		icount = ItemsInList( nm.newList )
		
		for ( icnt = 0 ; icnt < icount ; icnt += 1 )
		
			wName = StringFromList( icnt, nm.newList )
			wList = wName + ";"
			
			for ( jcnt = icnt + 1 ; jcnt <= icnt + 2 ; jcnt += 1 ) // find associated error waves
			
				if ( jcnt >= icount )
					break
				endif
			
				wName2 = StringFromList( jcnt, nm.newList )
				
				if ( strsearch( wName2, "xScale_", 0 ) > 0 )
					xWave = wName2
					icnt = jcnt
				elseif ( strsearch( wName2, "P_" + NMChild( wName ), 0 ) > 0 )
					wList += wName2 + ";"
					icnt = jcnt
				elseif( strsearch( wName2, "M_" + NMChild( wName ), 0 ) > 0 )
					wList += wName2 + ";"
					icnt = jcnt
				elseif( strsearch( wName2, NMChild( wName ), 0 ) > 0 )
					//wList += wName2 + ";" // error wave
					icnt = jcnt
				endif
			
			endfor
			
			gName = zNMMainMatrixStatsGraph( wList, xWave, all, graphInputs, errors2, STDV, SEM, nm )
			
			if ( ( strlen( gName ) > 0 ) && ( WhichListItem( gName, nm.windowList ) < 0 ) )
				nm.windowList += gName + ";"
			endif
		
		endfor
	
	endif
	
	
	if ( history )
	
		if ( ItemsInList( nm.newList ) > 0 )
			Print "NMMatrixStats Output Waves : " + NMChild( nm.newList )
		endif
		
		if ( graph && ( ItemsInList( nm.windowList ) > 0 ) )
			Print "NMMatrixStats Output Window : " + nm.windowList
		endif
		
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.newList )
	
	return nm.newList
	
End // NMMainMatrixStats2

//****************************************************************
//****************************************************************

Static Function zNMMainMatrixStatsRename( selectList, errors2, nm, s )
	String selectList
	Variable errors2
	STRUCT NMParams &nm
	STRUCT NMMatrixStatsStruct &s
	
	Variable icnt
	String select, wName, waveSelect
	
	Variable overwrite = NMMainVarGet( "OverwriteMode" )
	
	waveSelect = nm.wavePrefix + NMWaveSelectShort( prefixFolder = nm.prefixFolder, waveSelect = nm.waveSelect )
	waveSelect = NMNameStrShort( waveSelect )
	waveSelect = waveSelect[ 0, 11 ]
	
	nm.newList = ""
	
	if ( overwrite )
		wName = NextWaveName2( "", "StdvP_Avg_" + waveSelect + "_", nm.chanNum, overwrite ) // Plus
		KillWaves /Z $wName
		wName = NextWaveName2( "", "StdvM_Avg_" + waveSelect + "_", nm.chanNum, overwrite ) // Minus
		KillWaves /Z $wName
		wName = NextWaveName2( "", "Stdv_Avg_" + waveSelect + "_", nm.chanNum, overwrite )
		KillWaves /Z $wName
		wName = NextWaveName2( "", "SemP_Avg_" + waveSelect + "_", nm.chanNum, overwrite ) // Plus
		KillWaves /Z $wName
		wName = NextWaveName2( "", "SemM_Avg_" + waveSelect + "_", nm.chanNum, overwrite ) // Minus
		KillWaves /Z $wName
		wName = NextWaveName2( "", "Sem_Avg_" + waveSelect + "_", nm.chanNum, overwrite )
		KillWaves /Z $wName
		wName = NextWaveName2( "", "Var_Avg_" + waveSelect + "_", nm.chanNum, overwrite )
		KillWaves /Z $wName
	endif
	
	for ( icnt = 0 ; icnt < ItemsInList( selectList ) ; icnt += 1 )
		
		select = StringFromList( icnt, selectList )
		wName = ""
		
		strswitch( select )
		
			case "avg":
				wName = NextWaveName2( "", "Avg_" + waveSelect + "_", nm.chanNum, overwrite )
				Duplicate /O s.avg $nm.folder + wName
				NMNoteStrReplace( nm.folder + wName, "Source", wName )
				nm.newList += nm.folder + wName + ";"
				break
				
			case "stdv":
			
				if ( errors2 )
				
					wName = NextWaveName2( "", "StdvP_Avg_" + waveSelect + "_", nm.chanNum, overwrite ) // Plus
					Duplicate /O s.stdv $nm.folder + wName
					NMNoteStrReplace( nm.folder + wName, "Source", wName )
					nm.newList += nm.folder + wName + ";"
					
					Wave wtemp = $nm.folder + wName
					wtemp = s.avg + s.stdv
					
					wName = NextWaveName2( "", "StdvM_Avg_" + waveSelect + "_", nm.chanNum, overwrite ) // Minus
					Duplicate /O s.stdv $nm.folder + wName
					NMNoteStrReplace( nm.folder + wName, "Source", wName )
					nm.newList += nm.folder + wName + ";"
					
					Wave wtemp = $nm.folder + wName
					wtemp = s.avg - s.stdv
				
				else
				
					wName = NextWaveName2( "", "Stdv_Avg_" + waveSelect + "_", nm.chanNum, overwrite )
					Duplicate /O s.stdv $nm.folder + wName
					NMNoteStrReplace( nm.folder + wName, "Source", wName )
					nm.newList += nm.folder + wName + ";"
					
				endif
				
				break
				
			case "sem":
			
				if ( errors2 )
				
					wName = NextWaveName2( "", "SemP_Avg_" + waveSelect + "_", nm.chanNum, overwrite ) // Plus
					Duplicate /O s.stdv $nm.folder + wName
					NMNoteStrReplace( nm.folder + wName, "Source", wName )
					nm.newList += nm.folder + wName + ";"
					
					Wave wtemp = $nm.folder + wName
					wtemp = s.avg + s.stdv / sqrt( s.count )
					
					wName = NextWaveName2( "", "SemM_Avg_" + waveSelect + "_", nm.chanNum, overwrite ) // Minus
					Duplicate /O s.stdv $nm.folder + wName
					NMNoteStrReplace( nm.folder + wName, "Source", wName )
					nm.newList += nm.folder + wName + ";"
					
					Wave wtemp = $nm.folder + wName
					wtemp = s.avg - s.stdv / sqrt( s.count )
				
				else
				
					wName = NextWaveName2( "", "Sem_Avg_" + waveSelect + "_", nm.chanNum, overwrite )
					Duplicate /O s.stdv $nm.folder + wName
					NMNoteStrReplace( nm.folder + wName, "Source", wName )
					nm.newList += nm.folder + wName + ";"
					
					Wave wtemp = $nm.folder + wName
					wtemp = s.stdv / sqrt( s.count )
				
				endif
				
				break
				
			case "var":
			
				wName = NextWaveName2( "", "Var_Avg_" + waveSelect + "_", nm.chanNum, overwrite )
				Duplicate /O s.stdv $nm.folder + wName
				NMNoteStrReplace( nm.folder + wName, "Source", wName )
				nm.newList += nm.folder + wName + ";"
				
				Wave wtemp = $nm.folder + wName
				wtemp = s.stdv * s.stdv
				
				break
				
			case "sum":
				wName = NextWaveName2( "", "Sum_" + waveSelect + "_", nm.chanNum, overwrite )
				Duplicate /O s.sums $nm.folder + wName
				NMNoteStrReplace( nm.folder + wName, "Source", wName )
				nm.newList += nm.folder + wName + ";"
				break
				
			case "sumsqrs":
				wName = NextWaveName2( "", "SumSqrs_" + waveSelect + "_", nm.chanNum, overwrite )
				Duplicate /O s.sumsqrs $nm.folder + wName
				NMNoteStrReplace( nm.folder + wName, "Source", wName )
				nm.newList += nm.folder + wName + ";"
				break
			
		endswitch
	
	endfor
	
	if ( ( strlen( nm.xWave ) > 0 ) && WaveExists( s.xWave ) )
		wName = "xScale_" + NMChild( StringFromList( 0, nm.newList ) )
		Duplicate /O s.xWave $nm.folder + wName
		NMNoteStrReplace( nm.folder + wName, "Source", wName )
		nm.newList += nm.folder + wName + ";"
	endif
	
	if ( s.saveMatrix && WaveExists( s.matrix ) )
		wName = NextWaveName2( "", "Matrix_" + waveSelect + "_", nm.chanNum, overwrite )
		Duplicate /O s.matrix $nm.folder + wName
		NMNoteStrReplace( nm.folder + wName, "Source", wName )
		nm.newList += nm.folder + wName + ";"
	endif
			
	WaveStats /Q s.count
			
	if ( ( V_numNaNs > 0 ) || ( V_min != V_max ) )
		wName = NextWaveName2( "", "Pnts_" + waveSelect + "_", nm.chanNum, overwrite )
		Duplicate /O s.count $nm.folder + wName
		NMNoteStrReplace( nm.folder + wName, "Source", wName )
		nm.newList += nm.folder + wName + ";"
	endif

End // NMMainMatrixStatsRename

//****************************************************************
//****************************************************************

Static Function /S zNMMainMatrixStatsGraph( wList, xWave, all, graphInputs, errors2, STDV, SEM, nm )
	String wList, xWave, all
	Variable graphInputs, errors2, STDV, SEM
	STRUCT NMParams &nm
	
	Variable allFlag, allNum, lineSize = 1
	String waveSelect2, allList, gPrefix, gName, gTitle, color, wType, wName, returnList
	
	STRUCT NMParams nm2
	STRUCT NMRGB c
	
	String cdf = ChanDF( nm.chanNum, prefixFolder = nm.prefixFolder )
	
	Variable tMode = NumVarOrDefault( cdf + "TraceMode", NMVarGet( "ChanGraphTraceMode" ) )
	Variable tMarker = NumVarOrDefault( cdf + "TraceMarker", NMVarGet( "ChanGraphTraceMarker" ) )
	
	Variable overwrite = NMMainVarGet( "OverwriteMode" )
	
	waveSelect2 = nm.waveSelect
	
	if ( errors2 && ( ItemsInList( wList ) != 3 ) )
		errors2 = 0
	endif
	
	if ( strlen( all ) > 0 )
		allFlag = 1
		waveSelect2 = all
	endif
	
	if ( strsearch( wList, "Avg_", 0 ) >= 0 )
		wType = "Avg"
	elseif( strsearch( wList, "Sum_", 0 ) >= 0 )
		wType = "Sum"
	elseif( strsearch( wList, "SumSqrs_", 0 ) >= 0 )
		wType = "SumSqrs"
	else
		return ""
	endif
	
	gName = NMMainWindowName( nm.folder, nm.wavePrefix, nm.chanNum, waveSelect2, wType )
	
	if ( ( WinType( gName ) > 0 ) && ( WinType( gName ) != 1 ) )
		return NM2ErrorStr( 51, "gName", gName )
	endif
		
	if ( allFlag )
		
		if ( StringMatch( nm.waveSelect[ 0, 4 ], "Group" ) )
			allList = NMGroupsList( 1, prefixFolder = nm.prefixFolder )
		else
			allList = NMSetsList( prefixFolder = nm.prefixFolder )
		endif
		
		allNum = WhichListItem( nm.waveSelect, allList )
		
		if ( allNum < 0 )
		
			if ( WinType( gName ) == 0 )
				allNum = 0
			else
				allNum = 1
			endif
		
		endif
		
		color = NMRGBrainbow( allNum, c )
		
	else
	
		color = NMAvgColor
		
	endif
	
	if ( ( allNum == 0 ) && ( strlen( gName ) > 0 ) && ( WinType( gName ) == 1 ) )
		DoWindow /K $gName // kill existing graph
	endif

	gTitle = NMMainWindowTitle( "", nm.folder, nm.wavePrefix, nm.chanNum, waveSelect2, nm.wList, ending = wType )
	
	STRUCT NMGraphStruct g
	NMGraphStructNull( g )
	
	g.gName = gName
	g.gTitle = gTitle
	
	nm2 = nm
	
	if ( graphInputs )
	
		g.plotErrors = 0
		g.color = NMAvgDataColor
		returnList = NMGraph2( nm, g )
		
		if ( strlen( returnList ) == 0 )
			DoWindow /K $gName
			return ""
		endif
		
	endif
	
	g.color = color
	
	if ( errors2 )
		nm2.wList = NMChild( wList )
		g.plotErrors = 0
	else
		g.plotErrors = 1
		nm2.wList = NMChild( StringFromList( 0, wList ) )
	endif
	
	if ( strlen( xWave ) > 0 )
		nm2.xWave = NMChild( xWave )
	endif
	
	returnList = NMGraph2( nm2, g, STDV = STDV, SEM = SEM )
	
	if ( strlen( returnList ) == 0 )
		DoWindow /K $gName
		return ""
	endif
	
	wName = NMChild( StringFromList( 0, wList ) )
	
	if ( graphInputs )
		ModifyGraph /W=$gName lsize($wName)=1.5
		lineSize = 1.5
	endif
	
	ModifyGraph /W=$gName mode( $wName )=( tMode )
	ModifyGraph /W=$gName marker( $wName )=( tMarker )
	
	if ( errors2 )
	
		NMColorList2RGB( NMErrorColor, c )
	
		wName = NMChild( StringFromList( 1, wList ) )
		
		ModifyGraph /W=$gName rgb($wName)=(c.r,c.g,c.b), lsize($wName)=lineSize
		
		wName = NMChild( StringFromList( 2, wList ) )
		
		ModifyGraph /W=$gName rgb($wName)=(c.r,c.g,c.b), lsize($wName)=lineSize
	
	endif
	
	TextBox /W=$gName/C/N=avgtext/F=0/A=MT wName
	
	return gName
	
End // NMMainMatrixStatsGraph

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainHistogram()

	Variable overwrite, transforms, autoBins
	String wList, returnList, txt, optionStr = "", promptStr = NMPromptStr( "NM Histogram" )
	
	Variable paddingBins = NMVarGet( "HistogramPaddingBins" )
	
	String currentWavePrefix = CurrentNMWavePrefix()
	String dName = ChanDisplayWave( -1 )
	String chanCharList = NMChanSelectCharList()
	
	STRUCT NMParams nm
	STRUCT NMHistrogramBins h
	
	String newPrefix = StrVarOrDefault( NMMainDF + "HistoWavePrefix", "H_" )
	Variable selectNewPrefix = 1 + NumVarOrDefault( NMMainDF + "HistoSelectPrefix", 1 )
	String autoBinsStr = StrVarOrDefault( NMMainDF + "HistoBinAuto", "automatic" )
	Variable numBins = NumVarOrDefault( NMMainDF + "HistoNumBins", NaN )
	Variable binStart = NumVarOrDefault( NMMainDF + "HistoBinStart", NaN )
	Variable binWidth = NumVarOrDefault( NMMainDF + "HistoBinWidth", NaN )
	Variable xbgn = NumVarOrDefault( NMMainDF + "HistoXbgn", -inf )
	Variable xend = NumVarOrDefault( NMMainDF + "HistoXend", inf )
	Variable binCentered = 1 + NumVarOrDefault( NMMainDF + "HistoBinCentered", 0 )
	Variable cumulative = 1 + NumVarOrDefault( NMMainDF + "HistoCumulative", 0 )
	Variable normalize = 1 + NumVarOrDefault( NMMainDF + "HistoNormalize", 0 ) // 0 - count, 1 - probability density, 2 - frequency distribution
	
	Prompt transforms, "Use channel Filter/Transforms on your data?", popup "no;yes;"
	Prompt autoBinsStr, "bin dimensions:", popup "manual;automatic;"
	Prompt xbgn, NMPromptAddUnitsX( "input wave x-axis window begin" )
	Prompt xend, NMPromptAddUnitsX( "input wave x-axis window end" )
	Prompt newPrefix, "prefix name for output histograms:"
	Prompt selectNewPrefix, "select histograms as current waves?", popup "no;yes;"
	
	if ( NMChanTransformExists( chanCharList = chanCharList ) )
	
		transforms = 1 + NumVarOrDefault( NMMainDF + "HistoTransforms", 1 )
		
		DoPrompt promptStr, transforms
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		transforms -= 1
		
		SetNMvar( NMMainDF + "HistoTransforms", transforms )
		
	else
	
		transforms = -1
		
	endif
	
	if ( ItemsInList( chanCharList ) > 1 )
		autoBinsStr = "automatic" // force auto bins since there are multiple channels
		Prompt autoBinsStr, "bin dimensions:", popup "automatic;"
	endif
	
	DoPrompt promptStr, xbgn, xend, autoBinsStr, newPrefix, selectNewPrefix
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	selectNewPrefix -= 1
	
	SetNMstr( NMMainDF + "HistoBinAuto", autoBinsStr )
	SetNMvar( NMMainDF + "HistoXbgn", xbgn )
	SetNMvar( NMMainDF + "HistoXend", xend )
	SetNMstr( NMMainDF + "HistoWavePrefix", newPrefix )
	SetNMvar( NMMainDF + "HistoSelectPrefix", selectNewPrefix )
	
	wList = WaveList( newPrefix + currentWavePrefix + "*", ";", "" )
	
	if ( ItemsInList( wList ) > 0 )

		txt = "Alert: waves with prefix " + NMQuotes( newPrefix + currentWavePrefix ) + " already exist and may be overwritten. Do you want to continue?"
		
		DoAlert /T=( promptStr ) 1, txt
		
		if ( V_flag == 1 )
			overwrite = 1
		else
			return "" // cancel
		endif
	
	endif
	
	autoBins = StringMatch( autoBinsStr, "automatic" )
	
	if ( autoBins )
	
		if ( ItemsInList( chanCharList ) > 1 )
		
			numBins = NaN
			binWidth = NaN
			binStart = NaN
		
		else
		
			if ( NMLoopStructInit( "NMHistogram", "", "", -1, "", nm, transforms = transforms ) != 0 )
				return ""
			endif
		
			NMHistrogramBinsAuto( nm, h, all = 1, paddingBins = paddingBins, numBinsMin = 10, xbgn = xbgn, xend = xend )
		
			numBins = h.numBins
			binWidth = h.binWidth
			binStart = h.binStart
		
		endif
	
	else
	
		if ( numtype( numBins * binWidth * binStart ) > 0 )
		
			if ( NMLoopStructInit( "NMHistogram", "", "", -1, "", nm, transforms = transforms ) != 0 )
				return ""
			endif
		
			NMHistrogramBinsAuto( nm, h, all = 1, paddingBins = paddingBins, numBinsMin = 10, xbgn = xbgn, xend = xend )
		
			numBins = h.numBins
			binWidth = h.binWidth
			binStart = h.binStart
		
		endif
		
		Prompt binStart, NMPromptAddUnitsX( "bin start" )
		Prompt binWidth, NMPromptAddUnitsX( "bin width" )
		Prompt numBins, "number of bins:"
		DoPrompt promptStr, binStart, binWidth, numBins
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		SetNMvar( NMMainDF + "HistoBinStart", binStart )
		SetNMvar( NMMainDF + "HistoBinWidth", binWidth )
		SetNMvar( NMMainDF + "HistoNumBins", numBins )
	
	endif
	
	Prompt normalize, "normalize:", popup "no;yes, probability density;yes, frequency distribution;"
	Prompt cumulative, "cumulative histogram:", popup "no;yes;"
	Prompt binCentered, "bin-centered x values:", popup "no, x-values located at left edge of bins;yes, x-values located at center of bins;"
	
	DoPrompt promptStr, normalize, cumulative

	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	normalize -= 1
	cumulative -= 1
	
	SetNMvar( NMMainDF + "HistoNormalize", normalize )
	SetNMvar( NMMainDF + "HistoCumulative", cumulative )
	
	if ( normalize == 0 )
	
		DoPrompt promptStr, binCentered
	
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		binCentered -= 1
		
		SetNMvar( NMMainDF + "HistoBinCentered", binCentered )
		
	else
	
		binCentered = 1 // for /P, x-values are bin centered
		
	endif
	
	if ( binCentered )
		optionStr += "/C"
	endif
	
	if ( cumulative )
		optionStr += "/Cum"
	endif
	
	if ( normalize == 1 )
		optionStr += "/P"
	elseif ( normalize == 2 )
		optionStr += "/F"
	endif
	
	if ( numtype( numBins * binWidth * binStart ) > 0 )
		returnList = NMMainHistogram( transforms = transforms, xbgn = xbgn, xend = xend, optionStr = optionStr, newPrefix = newPrefix, overwrite = overwrite, history = 1 )
	else
		returnList = NMMainHistogram( transforms = transforms, xbgn = xbgn, xend = xend, binStart = binStart, binWidth = binWidth, numBins = numBins, optionStr = optionStr, newPrefix = newPrefix, overwrite = overwrite, history = 1 )
	endif
	
	if ( selectNewPrefix )
		NMPrefixSelect( newPrefix + currentWavePrefix, noPrompts = 1 )
	else
		NMPrefixAdd( newPrefix + currentWavePrefix )
	endif
	
	return returnList

End // zCall_NMMainHistogram

//****************************************************************
//****************************************************************

//Function /S NMMainHistogram( binStart, binWidth, numBins, newPrefix ) // OLD FUNCTION HAS BEEN OVERWRITTEN
//	Variable binStart
//	Variable binWidth
//	Variable numBins
//	String newPrefix

//End // NMMainHistogram

//****************************************************************
//****************************************************************

Function /S NMMainHistogram( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, transforms, xbgn, xend, binStart, binWidth, numBins, optionStr, newPrefix, overwrite ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	Variable transforms // use channel Filter/Transform on input data waves ( 0 ) no ( 1 ) yes
	Variable xbgn, xend
	Variable binStart
	Variable binWidth
	Variable numBins
	String optionStr // e.g. "/C/P/Cum" ( see Igor Histogram Help ), or "/F" for frequency
	String newPrefix // wave prefix for output histograms ( must specify )
	Variable overwrite
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( ( numtype( xbgn ) == 0 ) || ( numtype( xend ) == 0 ) )
		NMLoopExecVarAdd( "xbgn", xbgn, nm )
		NMLoopExecVarAdd( "xend", xend, nm )
	endif
	
	if ( !ParamIsDefault( binStart ) )
		NMLoopExecVarAdd( "binStart", binStart, nm )
	endif
	
	if ( !ParamIsDefault( binWidth ) )
		NMLoopExecVarAdd( "binWidth", binWidth, nm )
	endif
	
	if ( !ParamIsDefault( numBins ) )
		NMLoopExecVarAdd( "numBins", numBins, nm, integer = 1 )
	endif
	
	if ( !ParamIsDefault( optionStr ) && ( strlen( optionStr ) > 0 ) )
		NMLoopExecStrAdd( "optionStr", optionStr, nm )
	endif
	
	if ( ParamIsDefault( newPrefix ) || ( strlen( newPrefix ) == 0 ) )
		return NM2ErrorStr( 21, "newPrefix", "" )
	endif
	
	NMLoopExecStrAdd( "newPrefix", newPrefix, nm )
	
	if ( overwrite )
		NMLoopExecVarAdd( "overwrite", overwrite, nm, integer = 1 )
	endif
	
	if ( transforms >= 0 )
		NMLoopExecVarAdd( "transforms", transforms, nm, integer = 1 )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	//nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainHistogram

//****************************************************************
//****************************************************************

Function /S NMMainHistogram2( [ folder, wavePrefix, chanNum, waveSelect, transforms, xbgn, xend, binStart, binWidth, numBins, optionStr, newPrefix, overwrite ] )
	String folder, wavePrefix, waveSelect // see description at top
	Variable chanNum
	
	Variable transforms // use channel Filter/Transform on input data waves ( 0 ) no ( 1 ) yes
	Variable xbgn, xend
	Variable binStart // see Igor Histogram
	Variable binWidth
	Variable numBins
	String optionStr // e.g. "/C/P/Cum" // see Igor Histogram, or "/F" for frequency
	String newPrefix // wave prefix for output histograms ( must specify )
	Variable overwrite
	
	String fxn = "NMHistogram"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( transforms ) )
		transforms = 1
	endif
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( ParamIsDefault( binStart ) )
		binStart = NaN
	endif
	
	if ( ParamIsDefault( binWidth ) )
		binWidth = NaN
	endif
		
	if ( ParamIsDefault( numBins ) )
		numBins = NaN
	endif
	
	if ( ParamIsDefault( optionStr ) )
		optionStr = ""
	endif
	
	if ( ParamIsDefault( newPrefix ) || ( strlen( newPrefix ) == 0 ) )
		return NM2ErrorStr( 21, "newPrefix", "" )
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( fxn, folder, wavePrefix, chanNum, waveSelect, nm, transforms = transforms ) != 0 )
		return ""
	endif
	
	if ( numtype( numBins * binWidth * binStart ) > 0 )
		return NMHistogram2( nm, xbgn = xbgn, xend = xend, optionStr = optionStr, newPrefix = newPrefix, overwrite = overwrite, history = 1 )
	else
		return NMHistogram2( nm, xbgn = xbgn, xend = xend, binStart = binStart, binWidth = binWidth, numBins = numBins, optionStr = optionStr, newPrefix = newPrefix, overwrite = overwrite, history = 1 )
	endif
	
End // NMMainHistogram2

//****************************************************************
//****************************************************************

Static Function /S zCall_NMMainInequality()

	Variable overwrite, transforms
	String returnList, fxn, wList, txt, promptStr = NMPromptStr( "NM Inequality <>=" )
	
	String currentWavePrefix = CurrentNMWavePrefix()
	
	STRUCT NMInequalityStruct s
	
	Variable xbgn = NumVarOrDefault( NMMainDF + "InequalityXbgn", -inf )
	Variable xend = NumVarOrDefault( NMMainDF + "InequalityXend", inf )
	String newPrefix = StrVarOrDefault( NMMainDF + "InequalityWavePrefix", "I_" )
	Variable selectNewPrefix = 1 + NumVarOrDefault( NMMainDF + "InequalitySelectPrefix", 1 )
	
	Prompt transforms, "Use channel Filter/Transforms on your data?", popup "no;yes;"
	Prompt xbgn, NMPromptAddUnitsX( "x-axis window begin" )
	Prompt xend, NMPromptAddUnitsX( "x-axis window end" )
	Prompt newPrefix, "prefix name for output inequality waves:"
	Prompt selectNewPrefix, "select output inequality waves?", popup "no;yes;"
	
	if ( NMChanTransformExists( chanCharList = NMChanSelectCharList() ) )
	
		transforms = 1 + NumVarOrDefault( NMMainDF + "InequalityTransforms", 1 )
		
		DoPrompt promptStr, transforms
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		transforms -= 1
		
		SetNMvar( NMMainDF + "InequalityTransforms", transforms )
		
	else
	
		transforms = -1
		
	endif
	
	returnList = NMInequalityCall( s, NMMainDF, promptStr=promptStr )
	
	if ( strlen( returnList ) == 0 )
		return "" // cancel
	endif
	
	fxn = StringByKey( "inequality", returnList, "=" )
	
	if ( strlen( fxn ) == 0 )
		return "" // cancel
	endif
	
	DoPrompt promptStr, xbgn, xend, newPrefix, selectNewPrefix
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( strlen( newPrefix ) == 0 )
		return "" // cancel
	endif
	
	selectNewPrefix -= 1
	
	SetNMvar( NMMainDF + "InequalityXbgn", xbgn )
	SetNMvar( NMMainDF + "InequalityXend", xend )
	SetNMstr( NMMainDF + "InequalityWavePrefix", newPrefix )
	SetNMvar( NMMainDF + "InequalitySelectPrefix", selectNewPrefix )
	
	wList = WaveList( newPrefix + currentWavePrefix + "*", ";", "" )
	
	if ( ItemsInList( wList ) > 0 )
	
		txt = "Alert: waves with prefix " + NMQuotes( newPrefix + currentWavePrefix ) + " already exist and may be overwritten. Do you want to continue?"
		
		DoAlert /T=( promptStr ) 1, txt
		
		if ( V_flag == 1 )
			overwrite = 1
		else
			return "" // cancel
		endif
	
	endif
	
	strswitch( fxn ) // "y > a;y ≥ a;y < b;y ≤ b;a < y < b;a ≤ y ≤ b;y = a;y ≠ a;"
		case "y > a":
			returnList = NMMainInequality( transforms=transforms, xbgn=xbgn, xend=xend, greaterThan=s.greaterThan, binaryOutput=s.binaryOutput, newPrefix=newPrefix, overwrite=overwrite, history=1 )
			break
		case "y ≥ a":
			returnList = NMMainInequality( transforms=transforms, xbgn=xbgn, xend=xend, greaterThanOrEqual=s.greaterThanOrEqual, binaryOutput=s.binaryOutput, newPrefix=newPrefix, overwrite=overwrite, history=1 )
			break
		case "y < b":
			returnList = NMMainInequality( transforms=transforms, xbgn=xbgn, xend=xend, lessThan=s.lessThan, binaryOutput=s.binaryOutput, newPrefix=newPrefix, overwrite=overwrite, history=1 )
			break
		case "y ≤ b":
			returnList = NMMainInequality( transforms=transforms, xbgn=xbgn, xend=xend, lessThanOrEqual=s.lessThanOrEqual, binaryOutput=s.binaryOutput, newPrefix=newPrefix, overwrite=overwrite, history=1 )
			break
		case "a < y < b":
			returnList = NMMainInequality( transforms=transforms, xbgn=xbgn, xend=xend, greaterThan=s.greaterThan, lessThan=s.lessThan, binaryOutput=s.binaryOutput, newPrefix=newPrefix, overwrite=overwrite, history=1 )
			break
		case "a ≤ y ≤ b":
			returnList = NMMainInequality( transforms=transforms, xbgn=xbgn, xend=xend, greaterThanOrEqual=s.greaterThanOrEqual, lessThanOrEqual=s.lessThanOrEqual, binaryOutput=s.binaryOutput, newPrefix=newPrefix, overwrite=overwrite, history=1 )
			break
		case "y = a":
			returnList = NMMainInequality( transforms=transforms, xbgn=xbgn, xend=xend, equal=s.equal, binaryOutput=s.binaryOutput, newPrefix=newPrefix, overwrite=overwrite, history=1 )
			break
		case "y ≠ a":
			returnList = NMMainInequality( transforms=transforms, xbgn=xbgn, xend=xend, notEqual=s.notEqual, binaryOutput=s.binaryOutput, newPrefix=newPrefix, overwrite=overwrite, history=1 )
			break
		default:
			returnList = ""
	endswitch
	
	if ( selectNewPrefix )
		NMPrefixSelect( newPrefix + currentWavePrefix, noPrompts = 1 )
	else
		NMPrefixAdd( newPrefix + currentWavePrefix )
	endif
	
	return returnList
	
End // zCall_NMMainInequality

//****************************************************************
//****************************************************************

Function /S NMMainInequality( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation, transforms, xbgn, xend, greaterThan, greaterThanOrEqual, lessThan, lessThanOrEqual, equal, notEqual, binaryOutput, newPrefix, overwrite ] )
	String folderList, wavePrefixList, chanSelectList, waveSelectList // see description at top
	Variable history, deprecation
	
	Variable transforms
	Variable xbgn, xend
	Variable greaterThan // y-value > greaterThan
	Variable greaterThanOrEqual // y-value ≥ greaterThanOrEqual
	Variable lessThan // y-value < lessThan
	Variable lessThanOrEqual // y-value ≤ lessThanOrEqual
	Variable equal // y-value == equal
	Variable notEqual // y-value != notEqual
	Variable binaryOutput // ( 0 ) output wave will contain NaN for false or corresponding input wave value for true ( 1 ) output wave will contain '0' for false or '1' for true
	String newPrefix // wave prefix for output inequality waves ( must specify )
	Variable overwrite // overwrite output wave if it already exists ( 0 ) no, alert user ( 1 ) yes
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	String fxn = ""
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( ( numtype( xbgn ) == 0 ) || ( numtype( xend ) == 0 ) )
		NMLoopExecVarAdd( "xbgn", xbgn, nm )
		NMLoopExecVarAdd( "xend", xend, nm )
	endif
	
	if ( !ParamIsDefault( greaterThan ) )
		NMLoopExecVarAdd( "greaterThan", greaterThan, nm )
		fxn = "y > a"
	endif
	
	if ( !ParamIsDefault( greaterThanOrEqual ) )
		NMLoopExecVarAdd( "greaterThanOrEqual", greaterThanOrEqual, nm )
		fxn = "y ≥ a"
	endif
	
	if ( !ParamIsDefault( lessThan ) )
		NMLoopExecVarAdd( "lessThan", lessThan, nm )
		if ( StringMatch( fxn, "y > a" ) )
			fxn = "a < y < b"
		elseif ( StringMatch( fxn, "y ≥ a" ) )
			fxn = "a ≤ y < b"
		else
			fxn = "y < b"
		endif
	endif
	
	if ( !ParamIsDefault( lessThanOrEqual ) )
		NMLoopExecVarAdd( "lessThanOrEqual", lessThanOrEqual, nm )
		if ( StringMatch( fxn, "y > a" ) )
			fxn = "a < y ≤ b"
		elseif ( StringMatch( fxn, "y ≥ a" ) )
			fxn = "a ≤ y ≤ b"
		else
			fxn = "y ≤ b"
		endif
	endif
	
	if ( !ParamIsDefault( equal ) )
		NMLoopExecVarAdd( "equal", equal, nm )
		fxn = "y = a"
	endif
	
	if ( !ParamIsDefault( notEqual ) )
		NMLoopExecVarAdd( "notEqual", notEqual, nm )
		fxn = "y ≠ a"
	endif
	
	if ( strlen( fxn ) == 0 )
		return "" // nothing to do
	endif
	
	if ( !ParamIsDefault( binaryOutput ) )
		NMLoopExecVarAdd( "binaryOutput", binaryOutput, nm, integer = 1 )
	endif
	
	if ( ParamIsDefault( newPrefix ) || ( strlen( newPrefix ) == 0 ) )
		return NM2ErrorStr( 21, "newPrefix", "" )
	endif
	
	NMLoopExecStrAdd( "newPrefix", newPrefix, nm )
	
	if ( overwrite )
		NMLoopExecVarAdd( "overwrite", overwrite, nm, integer = 1 )
	endif
	
	if ( transforms >= 0 )
		NMLoopExecVarAdd( "transforms", transforms, nm, integer = 1 )
	endif
	
	if ( ParamIsDefault( folderList ) )
		folderList = ""
	endif
	
	if ( ParamIsDefault( wavePrefixList ) )
		wavePrefixList = ""
	endif
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = ""
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = ""	
	endif
	
	if ( NMLoopExecStructInit( folderList, wavePrefixList, chanSelectList, waveSelectList, nm ) != 0 )
		return ""
	endif
	
	//nm.updateWaveLists = 1
	//nm.updateGraphs = 1
	//nm.updatePanel = 1
	//nm.ignorePrefixFolder = 1
	
	return NMLoopExecute( nm, history, deprecation )

End // NMMainInequality

//****************************************************************
//****************************************************************

Function /S NMMainInequality2( [ folder, wavePrefix, chanNum, waveSelect, transforms, xbgn, xend, greaterThan, greaterThanOrEqual, lessThan, lessThanOrEqual, equal, notEqual, binaryOutput, newPrefix, overwrite ] )
	String folder, wavePrefix // see description at top
	Variable chanNum
	String waveSelect
	
	Variable transforms
	Variable xbgn, xend
	Variable greaterThan // y-value > greaterThan
	Variable greaterThanOrEqual // y-value ≥ greaterThanOrEqual
	Variable lessThan // y-value < lessThan
	Variable lessThanOrEqual // y-value ≤ lessThanOrEqual
	Variable equal // y-value == equal
	Variable notEqual // y-value != notEqual
	Variable binaryOutput
				// ( 0 ) output wave will contain NaN for false or corresponding input wave value for true
				// ( 1 ) output wave will contain '0' for false or '1' for true
	String newPrefix // wave prefix for output inequality waves ( must specify )
	Variable overwrite // overwrite output wave if it already exists ( 0 ) no ( 1 ) yes
	
	String fxn = "", loopfxn = "NMInequality"
	
	STRUCT NMParams nm
	
	if ( ParamIsDefault( transforms ) )
		transforms = 1
	endif
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( !ParamIsDefault( greaterThan ) )
		fxn = "y > a"
	endif
	
	if ( !ParamIsDefault( greaterThanOrEqual ) )
		fxn = "y ≥ a"
	endif
	
	if ( !ParamIsDefault( lessThan ) )
		if ( StringMatch( fxn, "y > a" ) )
			fxn = "a < y < b"
		elseif ( StringMatch( fxn, "y ≥ a" ) )
			fxn = "a ≤ y < b"
		else
			fxn = "y < b"
		endif
	endif
	
	if ( !ParamIsDefault( lessThanOrEqual ) )
		if ( StringMatch( fxn, "y > a" ) )
			fxn = "a < y ≤ b"
		elseif ( StringMatch( fxn, "y ≥ a" ) )
			fxn = "a ≤ y ≤ b"
		else
			fxn = "y ≤ b"
		endif
	endif
	
	if ( !ParamIsDefault( equal ) )
		fxn = "y = a"
	endif
	
	if ( !ParamIsDefault( notEqual ) )
		fxn = "y ≠ a"
	endif
	
	if ( strlen( fxn ) == 0 )
		return "" // nothing to do
	endif
	
	if ( ParamIsDefault( binaryOutput ) )
		binaryOutput = 1
	endif
	
	if ( ParamIsDefault( newPrefix ) || strlen( newPrefix ) == 0 )
		return NM2ErrorStr( 21, "newPrefix", "" )
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = ""
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = ""
	endif
	
	if ( NMLoopStructInit( loopfxn, folder, wavePrefix, chanNum, waveSelect, nm, transforms = transforms ) != 0 )
		return ""
	endif
	
	strswitch( fxn ) // "y > a;y ≥ a;y < b;y ≤ b;a < y < b;a ≤ y ≤ b;y = a;y ≠ a;"
		case "y > a":
			return NMInequality2( nm, xbgn=xbgn, xend=xend, greaterThan=greaterThan, binaryOutput=binaryOutput, newPrefix=newPrefix, overwrite=overwrite, history=1 )
		case "y ≥ a":
			return NMInequality2( nm, xbgn=xbgn, xend=xend, greaterThanOrEqual=greaterThanOrEqual, binaryOutput=binaryOutput, newPrefix=newPrefix, overwrite=overwrite, history=1 )
		case "y < b":
			return NMInequality2( nm, xbgn=xbgn, xend=xend, lessThan=lessThan, binaryOutput=binaryOutput, newPrefix=newPrefix, overwrite=overwrite, history=1 )
		case "y ≤ b":
			return NMInequality2( nm, xbgn=xbgn, xend=xend, lessThanOrEqual=lessThanOrEqual, binaryOutput=binaryOutput, newPrefix=newPrefix, overwrite=overwrite, history=1 )
		case "a < y < b":
			return NMInequality2( nm, xbgn=xbgn, xend=xend, greaterThan=greaterThan, lessThan=lessThan, binaryOutput=binaryOutput, newPrefix=newPrefix, overwrite=overwrite, history=1 )
		case "a ≤ y ≤ b":
			return NMInequality2( nm, xbgn=xbgn, xend=xend, greaterThanOrEqual=greaterThanOrEqual, lessThanOrEqual=lessThanOrEqual, binaryOutput=binaryOutput, newPrefix=newPrefix, overwrite=overwrite, history=1 )
		case "y = a":
			return NMInequality2( nm, xbgn=xbgn, xend=xend, equal=equal, binaryOutput=binaryOutput, newPrefix=newPrefix, overwrite=overwrite, history=1 )
		case "y ≠ a":
			return NMInequality2( nm, xbgn=xbgn, xend=xend, notEqual=notEqual, binaryOutput=binaryOutput, newPrefix=newPrefix, overwrite=overwrite, history=1 )
	endswitch
	
	return ""
	
End // NMMainInequality2

//****************************************************************
//****************************************************************
//
//		Misc Main Utility Functions
//
//****************************************************************
//****************************************************************

Function /S NMMainWindowName( folder, wavePrefix, chanNum, waveSelect, wType )
	String folder
	String wavePrefix
	Variable chanNum
	String waveSelect
	String wType // "graph" or "table" or "layout" or "notebook" or "panel"
	
	Variable overwrite = NMMainVarGet( "OverwriteMode" )
	String wtag = ""
	
	String folderPrefix = NMFolderListName( folder )
	String prefixFolder = NMPrefixFolderDF( folder, wavePrefix )
	String winPrefix = wavePrefix + NMWaveSelectShort( prefixFolder = prefixFolder, waveSelect = waveSelect )
	
	winPrefix = NMNameStrShort( winPrefix )
	
	strswitch ( wType )
		case "graph":
		case "plot":
			wtag = "G_"
			break
		case "table":
			wtag = "T_"
			break
		case "layout":
			wtag = "L_"
			break	
		case "notebook":
			wtag = "N_"
			break
		case "panel":
			wtag = "P_"
			break
		default:
			wtag = wType + "_"
	endswitch
	
	winPrefix = "MN_" + wtag + folderPrefix + "_" + winPrefix
	
	return NextGraphName( winPrefix, chanNum, overwrite )
	
End // NMMainWindowName

//****************************************************************
//****************************************************************

Function /S NMMainWindowTitle( fxn, folder, wavePrefix, chanNum, waveSelect, wList [ ending ] )
	String fxn
	String folder
	String wavePrefix
	Variable chanNum
	String waveSelect
	String wList
	String ending
	
	String wName, title = "", sepStr = ""
	
	if ( strlen( fxn ) > 0 )
		title = fxn
		sepStr = " : "
	endif
	
	if ( strlen( folder ) > 0 )
		title += sepStr + NMFolderListName( folder )
		sepStr = " : "
	endif
	
	if ( strlen( wavePrefix ) > 0 )
		title += sepStr + wavePrefix
		sepStr = " : "
	endif
	
	if ( numtype( chanNum ) == 0 )
		title += sepStr + "Ch " + ChanNum2Char( chanNum )
		sepStr = " : "
	endif
	
	if ( strlen( waveSelect ) > 0 )
	
		if ( StringMatch( waveSelect, "This Wave" ) )
			wName = StringFromList( 0, wList )
			waveSelect = NMChild( wName )
		endif
		
		title += sepStr + waveSelect
		
	endif
	
	if ( !ParamIsDefault( ending ) && ( strlen( ending ) > 0 ) )
		title += sepStr + ending
	endif
	
	return title

End // NMMainWindowTitle

//****************************************************************
//****************************************************************

Function /S zError_AllChanWavesPromptStr( promptStr [ ignoreChannels ] )
	String promptStr
	Variable ignoreChannels
	
	Variable all, allWavesAlert, allChanAlert, newNumActiveWaves, setXAlert
	String txt

	Variable numChannels = NMNumChannels()
	Variable numWaves = NMNumWaves()
	Variable numActiveWaves = NMVarGet( "NumActiveWaves" )
	Variable numSetX = NMSetsCount( "SetX", 0 )
	
	String chanSelect = NMChanSelectStr()
	String waveSelect = NMWaveSelectGet()
	
	if ( !ignoreChannels && ( numChannels > 1 ) && !StringMatch( chanSelect, "All" ) )
		allChanAlert = 1
	endif
	
	if ( StringMatch( waveSelect, "All" ) && ( numSetX > 0 ) )
		allWavesAlert = 1
		setXAlert = 1
	elseif ( !StringMatch( waveSelect, "All" ) )
		allWavesAlert = 1
	endif
	
	if ( allChanAlert || allWavesAlert )
	
		txt = "Only a subset of your original data set is currently chosen. Do you want to execute this function on your original data set"
	
		if ( allChanAlert )
			if ( setXAlert )
				txt += ", including all channels and waves and SetX waves?"
			else
				txt += ", including all channels and waves?"
			endif
		else
			if ( setXAlert )
				txt += ", including SetX waves?"
			else
				txt += " instead?"
			endif
		endif
		
		DoAlert /T=( promptStr ) 2, txt
	
		if ( V_flag == 1 ) // yes
		
			all = 1
			
			if ( allChanAlert )
				promptStr = ReplaceString( "Ch " + chanSelect, promptStr, "All Ch" )
			endif
			
			if ( allWavesAlert )
				promptStr = ReplaceString( waveSelect, promptStr, "All Waves" )
			endif
			
			if ( ignoreChannels )
			
				if ( StringMatch( chanSelect, "All" ) )
					newNumActiveWaves = numChannels * numWaves
				else
					newNumActiveWaves = 1 * numWaves
				endif
			
			else
			
				newNumActiveWaves = numChannels * numWaves
				
			endif
			
			promptStr = ReplaceString( "n = " + num2istr( numActiveWaves ), promptStr, "n = " + num2istr( newNumActiveWaves ) )
			
			return promptStr
			
		elseif ( V_flag == 2 ) // no
		
			return ""
			
		elseif ( V_flag == 3 )
		
			return NMCancel
			
		endif
		
	endif
	
	return ""

End // zError_AllChanWavesPromptStr

//****************************************************************
//****************************************************************

Function zError_DeltaX( allWaves, prompStr [ alert ] )
	Variable allWaves // ( 0 ) no, only selected waves ( 1 ) all channel waves
	String prompStr // DoAlert title
	Variable alert
	
	Variable dx
	String txt
	
	if ( ParamIsDefault( alert ) )
		alert = 1
	endif
	
	if ( allWaves )
		dx = NMChanDeltaX( 0, 1 )
	else
		dx = NMChanDeltaX( 1, 1 )
	endif
	
	if ( numtype( dx ) > 0 )
	
		if ( alert )
		
			txt = "Alert: currently selected waves have different sample rates. "
			txt += "If you want them to have the same sample rate, you can use the NM Main Tab Interpolate or Resample function. "
			txt += "Do you want to continue?"
		
			DoAlert /T=( prompStr ) 1, txt
		
		endif
		
		if ( V_flag != 1 )
			return NaN
		endif
		
		dx = NMWaveSelectXstats( "minDeltax", -1 )
		
		if ( numtype( dx ) > 0 )
			dx = 1
		endif
		
	endif
	
	return dx

End // zError_DeltaX

//****************************************************************
//****************************************************************

Function NMWavesHaveSameXScale( [ xbgn, xend ] )
	Variable xbgn, xend
	
	Variable ccnt
	String wSelectList
	
	STRUCT NMXAxisStruct s
	
	Variable numChannels = NMNumChannels()
	
	if ( numChannels == 0 )
		return 1
	endif
	
	if ( ParamIsDefault( xbgn ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) )
		xend = inf
	endif
	
	for ( ccnt = 0; ccnt < numChannels; ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
		
		wSelectList = NMWaveSelectList( ccnt )
		
		if ( strlen( wSelectList ) == 0 )
			continue
		endif
	
		NMXAxisStructInit( s, wSelectList )
		NMXAxisStats2( s )
		
		if ( numtype( s.dx ) > 0 )
			return 0 // different
		endif
		
		if ( ( numtype( s.leftx ) > 0 ) && ( xbgn < s.maxLeftx ) )
			return 0 // different
		endif
		
		if ( ( numtype( s.rightx ) > 0 ) && ( xend > s.minRightx ) )
			return 0 // different
		endif
		
	endfor
	
	return 1 // same
	
End // NMWavesHaveSameXScale

//****************************************************************
//****************************************************************

Function NMWavesHaveNANs( xbgn, xend )
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	
	Variable ccnt, wcnt
	String wName
	
	Variable numChannels = NMNumChannels()
	Variable numWaves = NMNumWaves()
	
	if ( numtype( xbgn ) > 0 )
		xbgn = -inf
	endif
	
	if ( numtype( xend ) > 0 )
		xend = inf
	endif
	
	if ( ( numChannels <= 0 ) || ( numWaves <= 0 ) )
		return 0
	endif
	
	for ( ccnt = 0; ccnt < numChannels; ccnt += 1 ) // loop thru channels
	
		if ( NMChanSelected( ccnt ) != 1 )
			continue // channel not selected
		endif
		
		for ( wcnt = 0; wcnt < numWaves; wcnt += 1 ) // loop thru waves
		
			wName = NMWaveSelected( ccnt, wcnt )
			
			if ( !WaveExists( $wName ) )
				continue
			endif
			
			WaveStats /Q/Z/R=( xbgn, xend ) $wName
			
			if ( V_numNans > 0 )
				return 1
			endif
			
		endfor
		
	endfor
	
	return 0
	
End // NMWavesHaveNANs

//****************************************************************
//****************************************************************

Function /S NMMainHistory( mssg, chanNum, wList, namesFlag [ folder, wavePrefix, waveSelect ] )
	String mssg
	Variable chanNum
	String wList // wave list ";"
	Variable namesFlag // print wave names ( 0 ) no ( 1 ) yes
	String folder
	String wavePrefix
	String waveSelect
	
	Variable numWaves = ItemsInlist( wList )
	
	if ( ParamIsDefault( folder ) )
		folder = GetDataFolder( 0 )
	endif
	
	folder = CheckNMFolderPath( folder )
	
	if ( !IsNMDataFolder( folder ) )
		return NM2ErrorStr( 30, "folder", folder )
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = CurrentNMWavePrefix()
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = NMWaveSelectGet()
	endif
	
	strswitch( waveSelect )
		case "This Wave":
			waveSelect = CurrentNMWaveName()
			break
	endswitch
	
	folder = NMChild( folder )
	
	String txt = folder + " : " + wavePrefix + " : Ch " + ChanNum2Char( chanNum ) + " : " + waveSelect + " : N = " + num2istr( numWaves )
	
	if ( numWaves == 0 )
		txt += " : No Waves!!"
	endif
	
	if ( strlen( mssg ) == 0 )
		mssg = txt
	else
		mssg += " : " + txt
	endif
	
	if ( namesFlag )
		mssg += " : " + wList
	endif
	
	NMHistory( mssg )
	
	return mssg

End // NMMainHistory

//****************************************************************
//****************************************************************
//
//	Functions not used anymore
//
//****************************************************************
//****************************************************************

Function NMMainVar( varName ) // NOT USED
	String varName
	
	return NMMainVarGet( varName )
	
End // NMMainVar

//****************************************************************
//****************************************************************

Function /S NMMainStr( strVarName ) // NOT USED
	String strVarName
	
	return NMMainStrGet( strVarName )
	
End // NMMainStr

//****************************************************************
//****************************************************************

Function /S NMIVCall()

	Variable numChannels = NMNumChannels()
	
	if ( numChannels < 2 )
		NMDoAlert( "Abort NMIVCall : this function requires two or more data channels." )
		return ""
	endif
	
	String vList = "", df = NMMainDF
	
	Variable rx = rightx( $ChanDisplayWave( -1 ) )
	
	String fxnX = StrVarOrDefault( df+"IVFxnX", "Avg" )
	String fxnY = StrVarOrDefault( df+"IVFxnY", "Avg" )
	
	Variable chX = NumVarOrDefault( df+"IVChX", 1 )
	Variable chY = NumVarOrDefault( df+"IVChY", 0 )
	Variable xbgnX = NumVarOrDefault( df+"IVXbgnX", 0 )
	Variable xendX = NumVarOrDefault( df+"IVXendX", rx )
	Variable xbgnY = NumVarOrDefault( df+"IVXbgnY", 0 )
	Variable xendY = NumVarOrDefault( df+"IVXendY", rx )
	
	chX += 1
	chY += 1

	Prompt chX, "select channel for x-data:", popup, NMChanList( "CHAR" )
	Prompt fxnX, "wave statistic for x-data:", popup, "Max;Min;Avg;Slope"
	Prompt xbgnX, NMPromptAddUnitsX( "x-axis window begin" )
	Prompt xendX, NMPromptAddUnitsX( "x-axis window end" )
	
	DoPrompt NMPromptStr( "IV : X Data" ), chX, fxnX, xbgnX, xendX
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	xbgnY = xbgnX
	xendY = xendX
	
	Prompt chY, "channel for y-data:", popup, NMChanList( "CHAR" )
	Prompt fxnY, "wave statistic for y-data:", popup, "Max;Min;Avg;Slope;"
	Prompt xbgnY, NMPromptAddUnitsX( "x-axis window begin" )
	Prompt xendY, NMPromptAddUnitsX( "x-axis window end" )
	
	DoPrompt NMPromptStr( "IV : Y Data" ), chY, fxnY, xbgnY, xendY
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	chY -= 1
	chX -= 1
	
	SetNMvar( df+"IVChY", chY )
	SetNMvar( df+"IVChX", chX )
	SetNMstr( df+"IVFxnY", fxnY )
	SetNMstr( df+"IVFxnX", fxnX )
	SetNMvar( df+"IVXbgnY", xbgnY )
	SetNMvar( df+"IVXendY", xendY )
	SetNMvar( df+"IVXbgnX", xbgnX )
	SetNMvar( df+"IVXendX", xendX )
	
	vList = NMCmdNum( chX, vList, integer = 1 )
	vList = NMCmdStr( fxnX, vList )
	vList = NMCmdNum( xbgnX, vList )
	vList = NMCmdNum( xendX, vList )
	vList = NMCmdNum( chY, vList, integer = 1 )
	vList = NMCmdStr( fxnY, vList )
	vList = NMCmdNum( xbgnY, vList )
	vList = NMCmdNum( xendY, vList )
	NMCmdHistory( "NMIV", vList )
	
	return NMIV( chX, fxnX, xbgnX, xendX, chY, fxnY, xbgnY, xendY )
	
End // NMIVCall

//****************************************************************
//****************************************************************

Function /S NMIV( chX, fxnX, xbgnX, xendX, chY, fxnY, xbgnY, xendY ) // can use Stats tab
	Variable chx // channel for x data
	String fxnX // "min", "max", "avg", "slope"
	Variable xbgnX, xendX // x-axis window begin and end for fxnX, use ( -inf, inf ) for all
	Variable chy // channel for y data
	String fxnY // "min", "max", "avg", "slope"
	Variable xbgnY, xendY // x-axis window begin and end for fxnY, use ( -inf, inf ) for all
	
	Variable error, overwrite
	String xl, yl, wList, wName1, wName2, gPrefix, gName = "", gTitle, aName, uName
	
	STRUCT Rect w
	
	Variable numChannels = NMNumChannels()
	
	if ( ( numtype( chX ) > 0 ) || ( chX < 0 ) || ( chX >= numChannels ) )
		return NM2ErrorStr( 10, "chX", num2istr( chX ) )
	endif
	
	strswitch( fxnX )
		case "Max":
		case "Min":
		case "Avg":
		case "Slope":
			break
		default:
			return NM2ErrorStr( 20, "fxnX", fxnX )
	endswitch
	
	if ( numtype( xbgnX ) > 0 )
		xbgnX = -inf
	endif
	
	if ( numtype( xendX ) > 0 )
		xendX = inf
	endif
	
	if ( ( numtype( chY ) > 0 ) || ( chY < 0 ) || ( chY >= numChannels ) )
		return NM2ErrorStr( 10, "chY", num2istr( chY ) )
	endif
	
	strswitch( fxnY )
		case "Max":
		case "Min":
		case "Avg":
		case "Slope":
			break
		default:
			return NM2ErrorStr( 20, "fxnY", fxnY )
	endswitch
	
	if ( numChannels == 0 )
		return ""
	endif
	
	if ( numtype( xbgnY ) > 0 )
		xbgnY = -inf
	endif
	
	if ( numtype( xendY ) > 0 )
		xendY = inf
	endif
	
	aName = fxnY
	uName = "U_AmpY"
	
	if ( StringMatch( aName, "Slope" ) )
		aName = "Slp"
		uName = "U_AmpX"
	endif
	
	overwrite = NMMainVarGet( "OverwriteMode" )
	
	wList = NMChanWaveList( chY )
	error = WaveListStats( fxnY, xbgnY, xendY, wList )
	yl = NMChanLabel( chY, "y", wList )
	
	wName1 = NextWaveName2( "", "MN_" + aName + "_", chY, overwrite )
	Duplicate /O $uName $wName1
	
	NMNoteStrReplace( wName1, "Source", wName1 )
	
	aName = fxnX
	uName = "U_AmpY"
	
	if ( StringMatch( aName, "Slope" ) )
		aName = "Slp"
		uName = "U_AmpX"
	endif
	
	wList = NMChanWaveList( chX )
	error = WaveListStats( fxnX, xbgnX, xendX, wList )
	xl = NMChanLabel( chX, "x", wList )
	
	wName2 = NextWaveName2( "", "MN_" + aName + "_", chX, overwrite )
	Duplicate /O $uName $wName2
	
	NMNoteStrReplace( wName2, "Source", wName2 )
	
	KillWaves /Z U_AmpX, U_AmpY
	
	if ( NMVarGet( "GraphsAndTablesOn" ) )
	
		gPrefix = "MN_IV_" + CurrentNMFolderPrefix() + NMWaveSelectStr() + "_" + aName
		gName = NextGraphName( gPrefix, -1, overwrite )
		gTitle = NMFolderListName( "" ) + " : IV : " + wName2
		
		gTitle = NMFolderListName( "" ) + " : IV : " + CurrentNMWavePrefix() + " : Ch " + ChanNum2Char( chY ) + " vs " + ChanNum2Char( chX ) + " : " + NMWaveSelectGet()
		
		NMWinCascadeRect( w )
		
		DoWindow /K $gName
		Display /K=(NMK())/N=$gName/W=(w.left,w.top,w.right,w.bottom) $wName1 vs $wName2 as gTitle
		
		ModifyGraph /W=$gName mode=3,marker=19,rgb=(65535,0,0)
		Label /W=$gName left yl
		Label /W=$gName bottom xl
		ModifyGraph /W=$gName standoff=0
		SetAxis /W=$gName /A
	
	endif
	
	return gName
	
End // NMIV

//****************************************************************
//****************************************************************

Function NMMainTest()

	Variable pcnt, fcnt, numFolders = 3
	String prefix, folder, folderList = ""
	
	String prefixList = "Record;Wave;"
	String chanSelectList = "A;B;"
	String waveSelectList = "All Sets"
	
	for ( fcnt = 0 ; fcnt < numFolders ; fcnt += 1 )
	
		folder = "nmFolder" + num2istr( fcnt )
		folderList += folder + ";"
	
		NMFolderNew( folder )
		
		for ( pcnt = 0 ; pcnt < ItemsInList( prefixList ) ; pcnt += 1 )
			
			prefix = StringFromList( pcnt, prefixList )
			NMMainMake( folderList=folder, wavePrefixList=prefix, chanSelectList=chanSelectList, numWaves=10, waveLength=100, dx=0.5, noiseStdv=1, xLabel=NMXunits )
			NMSet( wavePrefixNoPrompt=prefix )
			NMSetsSet( setList="Set1", value=1, fromWave=0, toWave=9, skipWaves=1, clearFirst=1 )
			NMSetsSet( setList="Set2", value=1, fromWave=1, toWave=9, skipWaves=1, clearFirst=1 )
			NMGroupsSet( groupSeq="0-2", fromWave=0, toWave=9, blocks=1, clearFirst=1 )
			
		endfor
	
	endfor
	
	NMMainGraph( folderList=folderList, wavePrefixList=prefixList, chanSelectList=chanSelectList, waveSelectList=waveSelectList, color="rainbow" )
	NMMainTable( folderList=folderList, wavePrefixList=prefixList, chanSelectList=chanSelectList, waveSelectList=waveSelectList )

End // NMMainTest

//****************************************************************
//****************************************************************
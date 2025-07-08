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

Static Constant NumWavesDefault = 1
Static Constant DeltaxDefault = 0.1
Static Constant WaveLengthDefault = 100
Static StrConstant WavePrefixDefault = "Pulse"
Static StrConstant ConfigWaveName = "PulseParamLists"

//****************************************************************
//****************************************************************

Function /S NMTabPrefix_Pulse() // this function allows NM to determine tab name and prefix

	return "PU_"

End // NMTabPrefix_Pulse

//****************************************************************
//****************************************************************

Function NMPulseSubfolderExists()

	String sf, wavePrefix

	if ( exists( "CurrentPrefixPulse" ) == 2 )
	
		wavePrefix = StrVarOrDefault( "CurrentPrefixPulse", "" )
		
		if ( strlen( wavePrefix ) == 0 )
			return 0
		endif
		
		sf = CurrentNMFolder( 1 ) + "Pulse_" + wavePrefix  + ":"
			
		if ( DataFolderExists( sf ) )
			return 1
		endif
		
	endif

	return 0
	
End // NMPulseSubfolderExists

//****************************************************************
//****************************************************************

Function /S NMPulseDF() // data folder where tab globals are stored

	if ( NMPulseSubfolderExists() )
		return CurrentNMFolder( 1 )
	else
		return NMPulseDF
	endif

End // NMPulseDF

//****************************************************************
//****************************************************************

Function /S NMPulseSubfolder()

	String sf, wavePrefix
	
	if ( exists( "CurrentPrefixPulse" ) == 2 )
	
		wavePrefix = StrVarOrDefault( "CurrentPrefixPulse", "" )
		
		if ( strlen( wavePrefix ) > 0 )
		
			sf = CurrentNMFolder( 1 ) + "Pulse_" + wavePrefix  + ":"
			
			if ( DataFolderExists( sf ) )
				return sf // found a pulse subfolder
			endif
			
		endif
		
	endif
	
	wavePrefix = StrVarOrDefault( NMPulseDF + "CurrentPrefixPulse", "" )
	
	if ( strlen( wavePrefix ) == 0 )
		SetNMstr( NMPulseDF + "CurrentPrefixPulse", WavePrefixDefault )
		wavePrefix = WavePrefixDefault
	endif

	return NMPulseDF + "Pulse_" + wavePrefix  + ":"

End // NMPulseSubfolder

//****************************************************************
//****************************************************************

Function /S NMPulseSubfolderList( [ df, fullPath ] )
	String df
	Variable fullPath
	
	String fList
	String folderPrefix = "Pulse_"
	
	if ( ParamIsDefault( df ) || ( strlen( df ) == 0 ) )
		df = NMPulseDF()
	elseif ( !DataFolderExists( df ) )
		return NM2ErrorStr( 30, "df", df )
	endif
	
	return NMSubfolderList( folderPrefix, df, fullPath )

End // NMPulseSubfolderList

//****************************************************************
//****************************************************************

Static Function /S z_NMPulseWavePrefixNewCall()

	String wavePrefix = ""
	String pList = NMPulseWavePrefixList()
	
	Prompt wavePrefix, "enter new pulse wave prefix:"
	DoPrompt "Pulse Wave Prefix", wavePrefix
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( WhichListItem( wavePrefix, pList ) >= 0 )
		return "" // already exists
	endif

	NMPulseSet( wavePrefix = wavePrefix, history = 1 )
	
	return wavePrefix

End // z_NMPulseWavePrefixNewCall

//****************************************************************
//****************************************************************

Static Function /S z_NMPulseWavePrefixKillCall()
	
	String wavePrefix = CurrentNMPulseWavePrefix()
	String pList = NMPulseWavePrefixList()
	
	Prompt wavePrefix, "select wave prefix to kill:", popup pList
	DoPrompt "Pulse Wave Prefix", wavePrefix
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	return NMPulseWavePrefixKill( wavePrefix = wavePrefix, history = 1 )
	
End // z_NMPulseWavePrefixKillCall

//****************************************************************
//****************************************************************

Function /S NMPulseWavePrefixKill( [ wavePrefix, update, history ] )
	String wavePrefix
	Variable update
	Variable history
	
	String subfolder, pList, vlist = ""
	String thisfxn = GetRTStackInfo( 1 )
	
	String df = NMPulseDF()
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = CurrentNMPulseWavePrefix()
	else
		vlist = NMCmdStrOptional( "wavePrefix", wavePrefix, vlist )
	endif
	
	subfolder = df + "Pulse_" + wavePrefix  + ":"
	
	if ( !DataFolderExists( subfolder ) )
		return "" // NM2ErrorStr( 30, "subfolder", subfolder )
	endif
	
	if ( StringMatch( subfolder, GetDataFolder( 1 ) ) == 1 )
		NMDoAlert( thisfxn + " Abort: cannot close the current data folder." )
		return "" // not allowed
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	Variable error = NMSubfolderKill( subfolder )
	
	if ( error == 0 )
	
		pList = NMPulseWavePrefixList()
		
		if ( ItemsInList( pList ) == 0 )
			SetNMstr( df + "CurrentPrefixPulse", WavePrefixDefault )
		else
			SetNMstr( df + "CurrentPrefixPulse", StringFromList( 0, pList ) )
		endif
		
	else
	
		subfolder = ""
		
	endif
	
	if ( update )
		NMPulseUpdate()
	endif
	
	return subfolder

End // NMPulseWavePrefixKill

//****************************************************************
//****************************************************************

Function /S CurrentNMPulseWavePrefix()

	String df = NMPulseDF()

	String wavePrefix = StrVarOrDefault( df + "CurrentPrefixPulse", "" )
	String subfolder = df + "Pulse_" + wavePrefix  + ":"
	
	if ( DataFolderExists( subfolder ) )
		return wavePrefix
	else
		return ""
	endif

End // CurrentNMPulseWavePrefix

//****************************************************************
//****************************************************************

Function /S NMPulseWavePrefixList( [ df ] )
	String df

	if ( ParamIsDefault( df ) || ( strlen( df ) == 0 ) )
		df = NMPulseDF()
	elseif ( !DataFolderExists( df ) )
		return NM2ErrorStr( 30, "df", df )
	endif

	String fList =  NMPulseSubfolderList( df = df )
	
	String prefixList = ReplaceString( "Pulse_", fList, "" )
	
	if ( ItemsInList( prefixList ) == 0 )
		prefixList = "Pulse;"
	endif
	
	return prefixList

End // NMPulseWavePrefixList

//****************************************************************
//****************************************************************

Function PulseTab( enable ) // called my ChangeTab
	Variable enable // ( 0 ) disable ( 1 ) enable tab
	
	if ( enable == 1 )
		CheckNMPackage( "Pulse", 1 ) // declare globals if necessary
		NMPulseMake() // create tab controls if necessary
		NMChannelGraphDisable( channel = -2, all = 0 )
	endif

End // PulseTab

//****************************************************************
//****************************************************************

Function PulseTabKill( what ) // called my KillTab
	String what
	
	String df = NMPulseDF
	
	strswitch( what )
	
		case "waves":
			// kill any other waves here
			break
			
		case "folder":
			if ( DataFolderExists( df ) == 1 )
				KillDataFolder $df
			endif
			break
			
	endswitch

End // PulseTabKill

//****************************************************************
//****************************************************************

Function NMPulseCheck() // declare global variables

	String df = NMPulseDF
	String sf = NMPulseSubfolder()
	
	if ( DataFolderExists( sf ) == 0 )
		NewDataFolder $RemoveEnding( sf, ":" )
	endif
	
	CheckNMvar( sf + "NumWaves", NumWavesDefault )
	CheckNMvar( sf + "DeltaX", DeltaxDefault )
	CheckNMvar( sf + "WaveLength", WaveLengthDefault )
	CheckNMstr( sf + "Xunits", NMXunits )
	CheckNMstr( sf + "Yunits", "" )
	CheckNMvar( sf + "PulseConfigNum", -1 )
	
	CheckNMvar( df + "AutoExecute", 0 )
	CheckNMvar( df + "OverwriteMode", 1 )
	CheckNMvar( df + "PromptBinomial", 1 )
	CheckNMstr( df + "PromptTypeDSCG", "stdv" )
	CheckNMvar( df + "PromptPlasticity", 1 )
	CheckNMvar( df + "WaveNotes", 1 )
	CheckNMvar( df + "SaveStochasticValues", 1 )
	CheckNMvar( df + "SavePlasticityWaves", 1 )
	CheckNMvar( df + "TTL", 0 )
	
	STRUCT NMPulseLBWaves lb
	
	NMPulseTabLBWavesDefault( lb )
	
	return 0
	
End // NMPulseCheck

//****************************************************************
//****************************************************************

Function /S NMPulseConfigWaveName()
	
	return NMPulseSubfolder() + ConfigWaveName

End // NMPulseConfigWaveName

//****************************************************************
//****************************************************************

Function NMPulseTabLBWavesDefault( lb )
	STRUCT NMPulseLBWaves &lb
	
	String sf = NMPulseSubfolder()
	
	lb.pcwName = sf + ConfigWaveName // same as NMPulseConfigWaveName()
	lb.lb1wName = sf + "LB1Configs"
	lb.lb1wNameSel = sf + "LB1ConfigsEditable"
	lb.lb2wName = sf + "LB2Configs"
	lb.lb2wNameSel = sf + "LB2ConfigsEditable"
	lb.pcvName = sf + "LB1ConfigNum"
	
	NMPulseLBWavesCheck( lb )
	
End // NMPulseTabLBWavesDefault

//****************************************************************
//****************************************************************

Function NMPulseVar( varName )
	String varName
	
	String df = NMPulseDF
	String sf = NMPulseSubfolder()
	
	strswitch( varName )
	
		case "ConfigNum":
		case "PulseConfigNum":
			return NumVarOrDefault( sf + varName, -1 )
	
		case "NumWaves":
			return NumVarOrDefault( sf + varName, NumWavesDefault )
			
		case "DeltaX":
			return NumVarOrDefault( sf + varName, DeltaxDefault )
			
		case "WaveLength":
			return NumVarOrDefault( sf + varName, WaveLengthDefault )
			
		case "AutoExecute":
			return NumVarOrDefault( df + varName, 1 )
			
		case "OverwriteMode":
			return NumVarOrDefault( df + varName, 1 )
			
		case "PromptBinomial":
			return NumVarOrDefault( df + varName, 1 )
			
		case "PromptPlasticity":
			return NumVarOrDefault( df + varName, 1 )
			
		case "WaveNotes":
			return NumVarOrDefault( df + varName, 1 )
			
		case "SaveStochasticValues":
			return NumVarOrDefault( df + varName, 1 )
			
		case "SavePlasticityWaves":
			return NumVarOrDefault( df + varName, 1 )
			
		case "TTL":
			return NumVarOrDefault( df + varName, 0 )
	
	endswitch
	
	return NaN
	
End // NMPulseVar

//****************************************************************
//****************************************************************

Function /S NMPulseStr( varName )
	String varName
	
	String df = NMPulseDF()
	String sf = NMPulseSubfolder()
	
	strswitch( varName )
	
		case "WavePrefix":
			//return StrVarOrDefault( xsf + varName, WavePrefixDefault )
			return StrVarOrDefault( df + "CurrentPrefixPulse", WavePrefixDefault )
			
		case "Xunits":
			return StrVarOrDefault( sf + varName, NMXunits )
			
		case "Yunits":
			return StrVarOrDefault( sf + varName, "" )
			
		case "PromptTypeDSCG":
			return StrVarOrDefault( NMPulseDF + varName, "stdv" )
	
	endswitch
	
	return ""
	
End // NMPulseStr

//****************************************************************
//****************************************************************

Function NMPulseConfigs()

	NMConfigVar( "Pulse", "AutoExecute", 1, "auto compute waves after adding/editing pulses", "boolean" )
	NMConfigVar( "Pulse", "OverwriteMode", 1, "overwrite existing waves, tables and graphs if their is a name conflict", "boolean" )
	NMConfigVar( "Pulse", "PromptBinomial", 1, "prompt for binomial pulses", "boolean" )
	NMConfigVar( "Pulse", "PromptPlasticity", 1, "prompt for plasticity of pulse trains", "boolean" )
	NMConfigStr( "Pulse", "PromptTypeDSCG", "stdv", "prompt for \"delta\" or \"stdv\" or \"cv\" or \"gamma\" of pulse parameters", "delta;stdv;cv;gamma;" )
	NMConfigVar( "Pulse", "WaveNotes", 1, "save pulse parameters to wave notes", "boolean" )
	NMConfigVar( "Pulse", "SaveStochasticValues", 1, "save parameters that vary to output waves", "boolean" )
	NMConfigVar( "Pulse", "SavePlasticityWaves", 1, "save plasticity states variables (e.g. D and F) to waves", "boolean" )
	NMConfigVar( "Pulse", "TTL", 0, "sum waves using TTL logic", "boolean" )
	
End // NMPulseConfigs

//****************************************************************
//****************************************************************

Function NMPulseMake()

	Variable x0 = 20, xinc = 140, yinc = 25, fs = NMPanelFsize
	Variable y0 = NMPanelTabY + 35
	
	NMPulseCheck()
	
	String df = NMPulseDF
	String sf = NMPulseSubfolder()
	
	STRUCT NMPulseLBWaves lb
	
	NMPulseTabLBWavesDefault( lb )

	ControlInfo /W=$NMPanelName $"PU_configs"
	
	if ( V_Flag != 0 )
		NMPulseUpdate( stopAutoExecute = 1 )
		return 0 // tab controls exist, return here
	endif

	DoWindow /F $NMPanelName
	
	SetVariable PU_NumWaves, title="waves", pos={x0+xinc,y0}, limits={1,inf,0}, size={120,20}, win=$NMPanelName
	SetVariable PU_NumWaves, value=$( sf+"NumWaves" ), fsize=fs, proc=NMPulseSetVariable, win=$NMPanelName
	
	SetVariable PU_DeltaX, title="x-delta", pos={x0+xinc,y0+1*yinc}, limits={0,inf,0}, size={120,20}, win=$NMPanelName
	SetVariable PU_DeltaX, value=$( sf+"DeltaX" ), fsize=fs, proc=NMPulseSetVariable, win=$NMPanelName
	
	SetVariable PU_WaveLength, title="wave length", pos={x0+xinc,y0+2*yinc}, limits={0,inf,0}, size={120,20}, win=$NMPanelName
	SetVariable PU_WaveLength, value=$( sf+"WaveLength" ), fsize=fs, proc=NMPulseSetVariable, win=$NMPanelName
	
	//SetVariable PU_WavePrefix, title="wave prefix", pos={x0+xinc,y0}, size={120,20}, win=$NMPanelName
	//SetVariable PU_WavePrefix, value=$( df+"WavePrefix" ), fsize=fs, proc=NMPulseSetVariable, win=$NMPanelName
	PopupMenu PU_PrefixMenu, title=" ", pos={x0,y0-3}, size={120,20}, bodyWidth=120, win=$NMPanelName
	PopupMenu PU_PrefixMenu, mode=1, value="Wave Prefix", fsize=fs, proc=NMPulsePopup, win=$NMPanelName
	
	SetVariable PU_Xunits, title="x-units", pos={x0,y0+1*yinc}, size={120,20}, win=$NMPanelName
	SetVariable PU_Xunits, value=$( sf+"Xunits" ), fsize=fs, proc=NMPulseSetVariable, win=$NMPanelName
	
	SetVariable PU_Yunits, title="y-units", pos={x0,y0+2*yinc}, size={120,20}, win=$NMPanelName
	SetVariable PU_Yunits, value=$( sf+"Yunits" ), fsize=fs, proc=NMPulseSetVariable, win=$NMPanelName
	
	y0 += 80
	
	ListBox PU_configs, pos={x0,y0}, size={260,100}, fsize=fs, listWave=$lb.lb1wName, selWave=$lb.lb1wNameSel, win=$NMPanelName
	ListBox PU_configs, mode=1, userColumnResize=1, proc=NMPulseLB1Control, widths={25,1500}, win=$NMPanelName
	
	y0 += 115
	
	ListBox PU_params, pos={x0,y0}, size={260,120}, fsize=fs, listWave=$lb.lb2wName, selWave=$lb.lb2wNameSel, win=$NMPanelName
	ListBox PU_params, mode=1, userColumnResize=1, selRow=-1, proc=NMPulseLB2Control, widths={35,70,45}, win=$NMPanelName
	
	y0 += 135
	yinc = 30
	
	Button PU_Execute, pos={x0+20,y0}, title="Execute", size={100,20}, proc=NMPulseButton, fsize=fs, win=$NMPanelName
	Button PU_Model, pos={x0+140,y0}, title="Model", size={100,20}, proc=NMPulseButton, fsize=fs, win=$NMPanelName
	Button PU_Graph, pos={x0+20,y0+yinc}, title="Graph", size={100,20}, proc=NMPulseButton, fsize=fs, win=$NMPanelName
	Button PU_Table, pos={x0+140,y0+yinc}, title="Table", size={100,20}, proc=NMPulseButton, fsize=fs, win=$NMPanelName
	//Button PU_Clear, pos={x0+55,y0+yinc}, title="Remove", size={70,20}, proc=NMPulseButton, fsize=fs, win=$NMPanelName
	
	y0 += 65
	
	CheckBox PU_AutoExecute, title="auto execute", pos={x0+125,y0}, size={200,50}, value=0, proc=NMPulseCheckBox, fsize=fs, win=$NMPanelName
	
	NMPulseUpdate( stopAutoExecute = 1 )
	
End // NMPulseMake

//****************************************************************
//****************************************************************

Function NMPulseUpdate( [ stopAutoExecute ] )
	Variable stopAutoExecute

	Variable configNum
	String sf, wavePrefix
	
	Variable auto = NMPulseVar( "AutoExecute" )
	Variable editByPrompt = NMVarGet( "ConfigsEditByPrompt" )
	
	STRUCT NMPulseLBWaves lb

	NMPulseCheck()
	
	sf = NMPulseSubfolder()
	
	NMPulseTabLBWavesDefault( lb )
	
	if ( !WaveExists( $lb.pcwName ) || ( numpnts( $lb.pcwName ) == 0 ) )
		configNum = -1
	else
		configNum = NumVarOrDefault( lb.pcvName, 0 )
	endif
	
	PopupMenu PU_PrefixMenu, mode=1, value=NMPulseWavePrefixMenu(), popvalue=CurrentNMPulseWavePrefix(), win=$NMPanelName
	
	SetVariable PU_NumWaves, value=$( sf + "NumWaves" ), win=$NMPanelName
	SetVariable PU_DeltaX, value=$( sf + "DeltaX" ), win=$NMPanelName
	SetVariable PU_WaveLength, value=$( sf + "WaveLength" ), win=$NMPanelName
	SetVariable PU_Xunits, value=$( sf + "Xunits" ), win=$NMPanelName
	SetVariable PU_Yunits, value=$( sf + "Yunits" ), win=$NMPanelName
	
	CheckBox PU_AutoExecute, value=auto, win=$NMPanelName
	
	ListBox PU_configs, listWave=$lb.lb1wName, selWave=$lb.lb1wNameSel, selRow=( configNum ), win=$NMPanelName
	ListBox PU_params, listWave=$lb.lb2wName, selWave=$lb.lb2wNameSel, selRow=-1, win=$NMPanelName
	
	NMPulseLB1Update( lb )
	NMPulseLB2Update( lb, editByPrompt=editByPrompt )
	
	if ( !stopAutoExecute && auto )
		NMPulseExecute()
	endif

End // NMPulseUpdate

//****************************************************************
//****************************************************************

Function /S NMPulseWavePrefixMenu()

	return "Wave Prefix;---;" + NMPulseWavePrefixList() + "---;Other;Kill;"

End //  NMPulseWavePrefixMenu

//****************************************************************
//****************************************************************

Function NMPulseButton( ctrlName ) : ButtonControl
	String ctrlName
	
	String fxn = ReplaceString( NMTabPrefix_Pulse(), ctrlName, "" )
	
	NMPulseCall( fxn, "" )
	
End // NMPulseButton

//****************************************************************
//****************************************************************

Function NMPulseSetVariable( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	String fxn = ReplaceString( NMTabPrefix_Pulse(), ctrlName, "" )
	
	NMPulseCall( fxn, varStr )
	
End // NMPulseSetVariable

//****************************************************************
//****************************************************************

Function NMPulseCheckBox( ctrlName, checked ) : CheckBoxControl
	String ctrlName; Variable checked
	
	ctrlName = ReplaceString( "PU_", ctrlName, "" )
	
	NMPulseCall( ctrlName, num2istr( checked ) )
	
End // NMPulseCheckBox

//****************************************************************
//****************************************************************

Function NMPulsePopup(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	ctrlName = ReplaceString( "PU_", ctrlName, "" )
	
	if ( StringMatch( ctrlName, "PrefixMenu" ) )
	
		strswitch( popStr)
	
		case "---":
		case "Wave Prefix":
			break
			
		case "Other":
			z_NMPulseWavePrefixNewCall()
			break
			
		case "Kill":
			z_NMPulseWavePrefixKillCall()
			break
			
		default:
	
			NMPulseSet( wavePrefix = popStr, history = 1 )
	
		endswitch
	
	endif

End // NMPulsePopup

//****************************************************************
//****************************************************************

Function NMPulseLB1Control( ctrlName, row, col, event ) : ListboxControl
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
	
	String paramList, ood, titleStr, trainStr
	String sf = NMPulseSubfolder()
	
	Variable editByPrompt = NMVarGet( "ConfigsEditByPrompt" )
	
	STRUCT NMPulseLBWaves lb
	
	NMPulseTabLBWavesDefault( lb )
	
	String estr = NMPulseLB1Event( row, col, event, lb )
	
	if ( StringMatch( estr, "+" ) )
	
		paramList = NMPulseLB1PromptNew()
		
		if ( ItemsInList( paramList ) > 0 )
			return NMPulseConfigAdd( paramList, history = 1 )
		endif
	
	elseif ( StringMatch( estr, "-" ) )

		ood = NMPulseLB1PromptOODE( lb, sf )
		NMPulseConfigOODE( lb, sf, ood )
		
	else
		
		NMPulseLB2Update( lb, editByPrompt=editByPrompt )
		
	endif
	
End // NMPulseLB1Control

//****************************************************************
//****************************************************************

Function NMPulseLB2Control( ctrlName, row, col, event ) : ListboxControl
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
	
	Variable numWaves = NMPulseVar( "NumWaves" )
	Variable TTL = NMPulseVar( "TTL" )
	String sf = NMPulseSubfolder()
	String timeUnits = NMPulseStr( "Xunits" )
	String ampUnits = NMPulseStr( "Yunits" )
	
	STRUCT NMPulseLBWaves lb
	
	NMPulseTabLBWavesDefault( lb )
	
	NMPulseLB2Event( row, col, event, lb, numWaves=numWaves, TTL=TTL, timeUnits=timeUnits, ampUnits=ampUnits )
	
	NMPulseUpdate()
	
End // NMPulseLB2Control

//****************************************************************
//****************************************************************

Function /S NMPulseCall( fxn, select )
	String fxn // function name
	String select // parameter string variable
	
	Variable snum = str2num( select ) // parameter variable number
	
	String df = NMPulseDF
	
	strswitch( fxn )
	
		case "AutoExecute":
			NMConfigVarSet( "Pulse", "AutoExecute", BinaryCheck( snum  ) )
			break
	
		case "Execute":
			return NMPulseExecute( history = 1 )
			
		case "Graph":
			return NMMainCall( "Graph", "" )
			
		case "Table":
			return NMPulseTableCall()
			
		case "Clear":
			NMPulseConfigRemoveCall()
			break
			
		case "Model":
			NMPulseModelsCall()
			break
		
		case "WavePrefix":
			NMPulseSet( wavePrefix = select, history = 1 )
			break
			
		case "NumWaves":
			NMPulseSet( numWaves = snum, history = 1 )
			break
			
		case "DeltaX":
			NMPulseSet( dx = snum, history = 1 )
			break
			
		case "WaveLength":
			NMPulseSet( waveLength = snum, history = 1 )
			break
			
		case "Xunits":
			NMPulseSet( xunits = select, history = 1 )
			break
			
		case "Yunits":
			NMPulseSet( yunits = select, history = 1 )
			break

	endswitch
	
	return ""
	
End // NMPulseCall

//****************************************************************
//****************************************************************

Function NMPulseSet( [ wavePrefix, numWaves, dx, waveLength, xunits, yunits, update, history ] )
	String wavePrefix
	Variable numWaves, dx, waveLength
	String xunits, yunits
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	String vlist = ""
	String df = NMPulseDF()
	String sf = NMPulseSubfolder()
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( !ParamIsDefault( wavePrefix ) && ( strlen( wavePrefix ) > 0 ) )
		vlist = NMCmdStrOptional( "wavePrefix", wavePrefix, vlist )
		SetNMstr( df + "CurrentPrefixPulse", wavePrefix )
	endif
	
	if ( !ParamIsDefault( xunits ) && ( strlen( xunits ) > 0 ) )
		vlist = NMCmdStrOptional( "xunits", xunits, vlist )
		SetNMstr( sf + "Xunits", xunits )
	endif
	
	if ( !ParamIsDefault( yunits ) && ( strlen( yunits ) > 0 ) )
		vlist = NMCmdStrOptional( "yunits", yunits, vlist )
		SetNMstr( sf + "Yunits", yunits )
	endif
	
	if ( !ParamIsDefault( numWaves ) && ( numWaves > 0 ) )
		vlist = NMCmdNumOptional( "numWaves", numWaves, vlist )
		SetNMvar( sf + "NumWaves", numWaves )
	endif
	
	if ( !ParamIsDefault( dx ) && ( dx > 0 ) )
		vlist = NMCmdNumOptional( "dx", dx, vlist )
		SetNMvar( sf + "DeltaX", dx )
	endif
	
	if ( !ParamIsDefault( waveLength ) && ( waveLength > 0 ) )
		vlist = NMCmdNumOptional( "waveLength", waveLength, vlist )
		SetNMvar( sf + "WaveLength", waveLength )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( update )
		NMPulseUpdate()
	endif

End // NMPulseSet

//****************************************************************
//****************************************************************

Function /S NMPulseLB1PromptNew()
	
	String titleEnding = ""
	String sf = NMPulseSubfolder()
	
	Variable numWaves = NMPulseVar( "NumWaves" )
	Variable waveLength = NMPulseVar( "WaveLength" )
	
	Variable TTL = NMPulseVar( "TTL" )
	Variable binom = NMPulseVar( "PromptBinomial" )
	Variable plasticity = NMPulseVar( "PromptPlasticity" )
	
	String DSCG = NMPulseStr( "PromptTypeDSCG" )
	String timeUnits = NMPulseStr( "Xunits" )
	String ampUnits = NMPulseStr( "Yunits" )
	
	return NMPulsePrompt( udf=sf, pdf=NMPulseDF, numWaves=numWaves, timeLimit=waveLength, TTL=TTL, titleEnding=titleEnding, binom=binom, DSC=DSCG, plasticity=plasticity, timeUnits=timeUnits, ampUnits=ampUnits )

End // NMPulseLB1PromptNew

//****************************************************************
//****************************************************************

Function NMPulseConfigAdd( paramList [ pcwName, update, history ] )
	String paramList
	String pcwName
	Variable update
	Variable history
	
	Variable error
	String cmd
	
	String sf = NMPulseSubfolder()
	
	String bullet = NMCmdHistoryBullet()
	
	Variable cmdhistory = NMVarGet( "CmdHistory" )
	
	if ( ParamIsDefault( pcwName ) )
		pcwName = NMPulseConfigWaveName()
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( cmdhistory && history )
	
		cmd = GetRTStackInfo( 1 ) + "( \"" + paramList + "\" )"
		
		NMHistoryManager( bullet + cmd, -1 * cmdhistory )
		
	endif
	
	error = NMPulseConfigWaveSave( pcwName, paramList )
	
	if ( update )
		NMPulseUpdate()
	endif
	
	return error
	
End // NMPulseConfigAdd

//****************************************************************
//****************************************************************

Function NMPulseConfigRemoveCall()

	Variable select = 1
	
	String pcwName = NMPulseConfigWaveName()
	
	Prompt select, " ", popup "clear all pulse configs;turn off all pulse configs;turn on all pulse configs;"
	DoPrompt "NM Pulse Configs", select
	
	if ( V_flag == 1 )
		return 0 // cancel
	endif
	
	if ( select == 1 )
		return NMPulseConfigRemove( all = 1 )
	elseif ( select == 2 )
		return NMPulseConfigRemove( all = 1, off = 1 )
	elseif ( select == 3 )
		return NMPulseConfigRemove( all = 1, off = 0 )
	endif

End // NMPulseConfigRemoveCall

//****************************************************************
//****************************************************************

Function NMPulseConfigOODE( lb, udf, ood [ noPrompt ] ) // code copied from NMPulseLB1OODE()
	STRUCT NMPulseLBWaves &lb
	String udf // data folder where user waves are located 
	String ood // see NMPulseLB1PromptOOD
	Variable noPrompt // for delete
	
	Variable configNum, deleteAll = 0
	Variable deleteTrain = 2 // user prompt to delete
	String trainStr, titleStr
	
	if ( !WaveExists( $lb.pcwName ) )
		return -1
	endif
	
	if ( noPrompt )
		deleteTrain = 1 // delete w/o prompt
	endif
	
	configNum = NumVarOrDefault( lb.pcvName, 0 )
	
	strswitch( ood )
		
			case "on":
				//return NMPulseConfigWaveRemove( lb.pcwName, configNum = configNum, off = 0 )
				return NMPulseConfigRemove( configNum = configNum, off = 0, history = 1 )
			case "off":
				//return NMPulseConfigWaveRemove( lb.pcwName, configNum = configNum, off = 1 )
				return NMPulseConfigRemove( configNum = configNum, off = 1, history = 1 )
			case "delete":
				//return NMPulseConfigWaveRemove( lb.pcwName, configNum = configNum, deleteTrain = deleteTrain )
				return NMPulseConfigRemove( configNum = configNum, deleteTrain = deleteTrain, history = 1 )
			case "off all":
				//return NMPulseConfigWaveRemove( lb.pcwName, all = 1, off = 1 )
				return NMPulseConfigRemove( off = 1, all = 1, history = 1 )
			case "on all":
				//return NMPulseConfigWaveRemove( lb.pcwName, all = 1, off = 0 )
				return NMPulseConfigRemove( off = 0, all = 1, history = 1 )
				
			case "delete all":
			
				if ( noPrompt )
				
					deleteAll = 1
					
				else
			
					DoAlert 2, "Are you sure you want to delete all pulse configurations?"
					
					if ( V_flag == 1 ) // yes
						deleteAll = 1
					endif
				
				endif
				
				if ( deleteAll )
					//return NMPulseConfigWaveRemove( lb.pcwName, all = 1, deleteTrain = deleteTrain )
					return NMPulseConfigRemove( all = 1, deleteTrain = deleteTrain, history = 1 )
				endif
				
				break
		
			default:
			
				if ( StringMatch( ood[ 0, 3 ], "edit" ) )
				
					trainStr = ReplaceString( "edit ", ood, "" )
				
					if ( ( strlen( trainStr ) > 0 ) && ( WaveExists( $udf + trainStr ) ) )
						titleStr = udf + trainStr
						Edit /K=1 $udf + trainStr as titleStr
					endif
					
				endif
		
		endswitch
		
		return 0
	
End // NMPulseConfigOODE

//****************************************************************
//****************************************************************

Function NMPulseConfigRemove( [ configNum, all, off, deleteTrain, update, history ] )
	// wrapper to NMPulseConfigWaveRemove(), this function adds history option
	Variable configNum
	Variable all
	Variable off // ( 0 ) turn on config ( 1 ) turn off config
	Variable deleteTrain // delete wave of random pulse times ( 0 ) no ( 1 ) yes ( 2 ) user prompt
	Variable update
	Variable history
	
	Variable error
	String vlist = ""
	String pcwName = NMPulseConfigWaveName()
	
	if ( ParamIsDefault( configNum ) )
		configNum = -1
	else
		vlist = NMCmdNumOptional( "configNum", configNum, vlist )
	endif
	
	if ( !ParamIsDefault( all ) )
		vlist = NMCmdNumOptional( "all", all, vlist )
	endif
	
	if ( ParamIsDefault( off ) )
		off = -1
	else
		vlist = NMCmdNumOptional( "off", off, vlist )
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	else
		vlist = NMCmdNumOptional( "update", update, vlist )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	error = NMPulseConfigWaveRemove( pcwName, configNum = configNum, all = all, off = off, deleteTrain = deleteTrain )
	
	if ( update )
		NMPulseUpdate()
	endif
	
	return error
	
End // NMPulseConfigRemove

//****************************************************************
//****************************************************************

Function /S NMPulseTableCall()

	Variable type = NumVarOrDefault( NMPulseDF + "Prompt_TableType", 2 )
	
	Prompt type, "select table type:", popup "configs;stochastic parameters;"
	DoPrompt "NM Pulse Table", type
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMvar( NMPulseDF + "Prompt_TableType", type )
	
	switch( type )
		case 1:
			return NMPulseConfigsTable( history = 1 )
		case 2:
			return NMPulseOutputTable( history = 1 )
	endswitch
		
	return ""

End // NMPulseTableCall

//****************************************************************
//****************************************************************

Function /S NMPulseConfigsTable( [ history ] )
	Variable history

	String pcwName = NMPulseConfigWaveName()
	String folderPrefix = NMFolderListName( "" )
	String wavePrefix = NMPulseStr( "WavePrefix" )
	String tName = NMTabPrefix_Pulse() + "Configs_" + folderPrefix + "_" + wavePrefix
	String title =  folderPrefix + " : " + wavePrefix + " : Pulse Configs"
	
	STRUCT Rect w
	
	NMOutputListsReset()
	
	if ( history )
		NMCommandHistory( "" )
	endif
	
	if ( !WaveExists( $pcwName ) )
		NMPulseConfigAdd( "" )
	endif
	
	if ( ( strlen( tName ) > 0 ) && ( WinType( tName ) == 0 ) )
	
		NMWinCascadeRect( w )
		
		Edit /K=1/N=$tName/W=(w.left,w.top,w.right,w.bottom) $pcwName as title
		
		ModifyTable /W=$tName title(Point)="Config"
		ModifyTable /W=$tName alignment=0
		ModifyTable /W=$tName width=400
		ModifyTable /W=$tName width(Point)=40
		
		SetWindow $tName hook=NMPulseConfigsTableHook, hookevents=1
		
	else
	
		DoWindow /F $tName
		
	endif
	
	SetNMstr( NMDF + "OutputWinList", tName )
	
	NMHistoryOutputWindows()
	
	return tName

End // NMPulseConfigsTable

//****************************************************************
//****************************************************************

Function NMPulseConfigsTableHook( infoStr )
	string infoStr
	
	string event = StringByKey( "EVENT", infoStr )
	string winNameStr = StringByKey( "WINDOW", infoStr )
	
	strswitch( event )
		case "activate":
		case "moved":
			break
		case "deactivate":
		case "kill":
			NMPulseUpdate( stopAutoExecute = 1 )
	endswitch
	
	return 0

End // NMPulseConfigsTableHook

//****************************************************************
//****************************************************************

Function /S NMPulseOutputTable( [ sf, wList, history ] )
	String sf // subfolder
	String wList // output wave name list or "all"
	Variable history
	
	Variable wcnt
	String wName, tName, title, vlist = "", tList = ""
	
	String folderPrefix = NMFolderListName( "" )
	String wavePrefix = NMPulseStr( "WavePrefix" )
	
	STRUCT Rect w
	
	NMOutputListsReset()

	if ( ParamIsDefault( sf ) )
		sf = NMPulseSubfolder()
	else
		vlist = NMCmdStrOptional( "sf", sf, vlist )
	endif
	
	if ( ParamIsDefault( wList ) )
		wList = "all"
	else
		vlist = NMCmdStrOptional( "wList", wList, vlist )
	endif
	
	if ( history )
		NMCommandHistory( "" )
	endif
	
	If ( !DataFolderExists( sf ) )
		return ""
	endif
	
	if ( StringMatch( wList, "all" ) )
		wList = NMFolderWaveList( sf, "PC*", ";", "", 0 )
	endif
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
		
		wName = StringFromList( wcnt, wList )
		
		if ( !WaveExists( $sf + wName ) )
			continue
		endif
		
		tName = NMTabPrefix_Pulse() + folderPrefix + "_" + wavePrefix + "_" + wName
		title =  folderPrefix + " : " + wavePrefix + " : " + wName
		
		if ( ( strlen( tName ) > 0 ) && ( WinType( tName ) == 0 ) )
	
			NMWinCascadeRect( w )
			
			Edit /K=1/N=$tName/W=(w.left,w.top,w.right,w.bottom) $( sf + wName ) as title
			
		else
		
			DoWindow /F $tName
			
		endif
		
		tList += tName + ";"
		
	endfor
	
	SetNMstr( NMDF + "OutputWinList", tList )
	
	NMHistoryOutputWindows()

	return tList

End // NMPulseOutputTable

//****************************************************************
//****************************************************************

Function /S NMPulseExecute( [ history ] )
	Variable history

	Variable wcnt, wavesExist, waveLength, dx
	String wName, wList
	
	String sf = NMPulseSubfolder()
	String pcwName = NMPulseConfigWaveName()
	
	String currentPrefix = CurrentNMWavePrefix()
	Variable currentNumWaves = NMNumWaves()
	
	Variable overwrite = NMPulseVar( "OverwriteMode" )
	Variable wNotes = NMPulseVar( "WaveNotes" )
	Variable saveStochastic = NMPulseVar( "SaveStochasticValues" )
	Variable savePlasticity = NMPulseVar( "SavePlasticityWaves" )
	
	STRUCT NMParams nm
	STRUCT NMMakeStruct m
	STRUCT NMPulseSaveToWaves s
	
	NMParamsNull( nm )
	NMMakeStructNull( m )
	
	waveLength = NMPulseVar( "WaveLength" )
	dx = NMPulseVar( "DeltaX" )
	
	nm.folder = CurrentNMFolder( 1 )
	nm.wavePrefix = NMPulseStr( "WavePrefix" )
	
	m.numWaves = NMPulseVar( "NumWaves" )
	m.xpnts = 1 + waveLength / dx
	m.dx = dx
	m.xLabel = NMPulseStr( "Xunits" )
	m.yLabel = NMPulseStr( "Yunits" )
	
	if ( history )
		NMCommandHistory( "" )
	endif
	
	if ( ( numtype( m.numWaves ) > 0 ) || ( m.numWaves < 1 ) )
		return ""
	endif
	
	if ( ( numtype( m.dx ) > 0 ) || ( m.dx <= 0 ) )
		m.dx = 1
	endif
	
	if ( ( numtype( m.xpnts ) > 0 ) || ( m.xpnts <= 0 ) )
		return ""
	endif
	
	if ( strlen( nm.wavePrefix ) == 0 )
		nm.wavePrefix = WavePrefixDefault
	endif
	
	//m.rows = 1 + m.waveLength / m.dx
	
	nm.wList = ""
	
	for ( wcnt = 0 ; wcnt < m.numWaves ; wcnt += 1 )
	
		wName = nm.wavePrefix + num2istr( wcnt )
		
		if ( WaveExists( $nm.folder + wName ) )
			wavesExist = 1
		endif
		
		nm.wList += wName + ";"
		
	endfor
	
	if ( wavesExist && !overwrite )
	
		NMDoAlert( "Abort Pulse Execution: waves with prefix " + NMQuotes( nm.wavePrefix ) + " already exist", title = "Pulse Execute" )
	
		return ""
	
	endif
	
	wList = WaveList( nm.wavePrefix + "*", ";", "" )
	
	wList = RemoveFromList( nm.wList, wList )
	
	if ( ItemsInList( wList ) > 0 )
	
		DoAlert /T="NM Pulse Wave Generator" 1, "There are extra waves with prefix " + NMQuotes( nm.wavePrefix ) + " in the current data folder. Do you want to delete them?"
		
		if ( V_flag == 1 )
		
			for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
				wName = StringFromList( wcnt, wList )
				KillWaves /Z $wName
			endfor
			
		endif
	
	endif
	
	//Variable timerRefNum = startMSTimer
	
	if ( saveStochastic )
	
		s.sf = sf
	
		NMPulseWavesMake2( pcwName, nm, m, notes = wNotes, savePlasticityWaves = savePlasticity, s = s )
	
	else
	
		NMPulseWavesMake2( pcwName, nm, m, notes = wNotes, savePlasticityWaves = savePlasticity )
	
	endif
	
	NMPulseSave()
	
	//print round( stopMSTimer( timerRefNum ) / 1000 ), "ms"
	
	if ( StringMatch( currentPrefix, nm.wavePrefix ) && ( currentNumWaves == m.numWaves ) )
		UpdateCurrentWave()
	else
		NMPrefixSelect( nm.wavePrefix, noPrompts = 1 )
	endif
	
	NMLoopHistory( nm )
	
	return nm.wList

End // NMPulseExecute

//****************************************************************
//****************************************************************

Function NMPulseSave() // copy Pulse subfolder to current folder - this saves variables used in current simulation

	String wavePrefix, sf, sfnew
	String df = NMPulseDF()
	
	if ( StringMatch( df, NMPulseDF ) ) // using Package Pulse directory
		
		wavePrefix = StrVarOrDefault( NMPulseDF + "CurrentPrefixPulse", "" )
		
		if ( strlen( wavePrefix ) == 0 )
			return -1 // something is wrong
		endif
		
		sf = NMPulseDF + "Pulse_" + wavePrefix  + ":"
		
		if ( !DataFolderExists( sf ) )
			return -1 // something is wrong
		endif
		
		sfnew = CurrentNMFolder( 1 ) + "Pulse_" + wavePrefix  + ":"
		
		if ( DataFolderExists( sfnew ) )
			KillDataFolder /Z $RemoveEnding( sfnew, ":" )
		endif
		
		SetNMstr( CurrentNMFolder( 1 ) + "CurrentPrefixPulse", wavePrefix )
		
		DuplicateDataFolder $RemoveEnding( sf, ":" ) $RemoveEnding( sfnew, ":" )
	
	endif

End // NMPulseSave

//****************************************************************
//****************************************************************

Function NMPulseModelsCall()

	String df = NMPulseDF

	Variable model = NumVarOrDefault( df + "Prompt_GCModelSelect", 1 )

	String modelList = " ;Granule Cell Multinomial Synapse;Granule Cell Synaptic Conductance Train with Short-Term Plasticity;"
	
	Prompt model, "select model to run:", popup modelList
	DoPrompt "NM Pulse Models", model
	
	if ( V_flag == 1 )
		return 0 // cancel
	endif
	
	SetNMvar( df + "Prompt_GCModelSelect", model )
	
	switch( model )
	
		case 2:
			return NMPulseGCBinomSynCall()
			
		case 3:
			NMPulseGCTrainCall()
			break
	
	endswitch

End // NMPulseModelsCall

//****************************************************************
//****************************************************************

Function NMPulseGCBinomSynCall()

	String df = NMPulseDF
	String sf = NMPulseSubfolder()
	
	String title = "NM Pulse GC Binomial Synapse"

	Variable numWaves = NumVarOrDefault( df + "NumWaves", 100 )
	numWaves = NumVarOrDefault( sf + "NumWaves", numWaves )
	
	Variable dx = NumVarOrDefault( df + "DeltaX", 0.005 )
	dx = NumVarOrDefault( sf + "DeltaX", dx )
	
	Variable waveLength = NumVarOrDefault( df + "WaveLength", 8 )
	waveLength = NumVarOrDefault( sf + "WaveLength", waveLength )
	
	if ( ( numWaves == NumWavesDefault ) && ( dx == DeltaxDefault ) && ( waveLength == WaveLengthDefault ) )
		numWaves = 100
		dx = 0.005
		waveLength = 8
	endif
	
	Variable Nsites = NumVarOrDefault( df + "Prompt_GCBinomN", 5 )
	Variable Pr = NumVarOrDefault( df + "Prompt_GCBinomP", 0.5 )
	Variable Q = NumVarOrDefault( df + "Prompt_GCBinomQ", -16 )
	
	Variable latencySTDV = NumVarOrDefault( df + "Prompt_GCBinomLatSTDV", 0.08 )
	Variable CVQS = NumVarOrDefault( df + "Prompt_GCBinomCVQS", 0.3 )
	Variable CVQ2 = NumVarOrDefault( df + "Prompt_GCBinomCVQ2", 0.3 )
	
	Variable FixCVQ2 = 1 + NumVarOrDefault( df + "Prompt_GCBinomFixCVQ2", 1 )
	Variable CVQ2precision = NumVarOrDefault( df + "Prompt_GCBinomCVQ2precision", 1 ) // %
	Variable CVQ2precisionAmp = NumVarOrDefault( df + "Prompt_GCBinomCVQ2precisionAmp", 1 ) // %
	Variable addSpillover = 1 + NumVarOrDefault( df + "Prompt_GCBinomAddSpillover", 0 )
	
	if ( numWaves <= 1 )
		numWaves = 100
	endif
	
	Prompt numWaves, "number of waves to compute:"
	Prompt dx, "wave sample interval (delta-x):"
	Prompt waveLength, "wave length:"
	
	Prompt Nsites, "release sites per synapse:"
	Prompt Pr, "release probability:"
	Prompt Q, "quantal peak response per site:"
	Prompt latencySTDV, "STDV of quantal latency:"
	Prompt CVQS, "within-site Q variability ( CVQS ):"
	Prompt CVQ2, "between-site Q variability ( CVQ2 ):"
	Prompt FixCVQ2, "fix simulated CVQ2 to a given precision?", popup "no;yes;"
	Prompt CVQ2precision, "% precision to fix CVQ2:"
	Prompt CVQ2precisionAmp, "% precision to fix mean Q:"
	Prompt addSpillover, "add spillover?", popup "no;yes;"
	
	DoPrompt title, numWaves, dx, waveLength
	
	if ( V_flag == 1 )
		return 0 // cancel
	endif
	
	SetNMvar( sf + "NumWaves", numWaves )
	SetNMvar( sf + "DeltaX", dx )
	SetNMvar( sf + "WaveLength", waveLength )
	
	DoPrompt title, Nsites, Pr, Q, addSpillover
	
	if ( V_flag == 1 )
		return 0 // cancel
	endif
	
	addSpillover -= 1
	
	SetNMvar( df + "Prompt_GCBinomN", Nsites )
	SetNMvar( df + "Prompt_GCBinomP", Pr )
	SetNMvar( df + "Prompt_GCBinomQ", Q )
	SetNMvar( df + "Prompt_GCBinomAddSpillover", addSpillover )
	
	DoPrompt title, latencySTDV, CVQS, CVQ2
	
	if ( V_flag == 1 )
		return 0 // cancel
	endif
	
	SetNMvar( df + "Prompt_GCBinomLatSTDV", latencySTDV )
	SetNMvar( df + "Prompt_GCBinomCVQS", CVQS )
	SetNMvar( df + "Prompt_GCBinomCVQ2", CVQ2 )
	
	if ( CVQ2 > 0 )
	
		DoPrompt title, FixCVQ2
		
		if ( V_flag == 1 )
			return 0 // cancel
		endif
		
		FixCVQ2 -= 1
		
		SetNMvar( df + "Prompt_GCBinomFixCVQ2", FixCVQ2 )
		
		if ( FixCVQ2 )
	
			DoPrompt title, CVQ2precision, CVQ2precisionAmp
		
			if ( V_flag == 1 )
				return 0 // cancel
			endif
			
			SetNMvar( df + "Prompt_GCBinomCVQ2precision", CVQ2precision )
			SetNMvar( df + "Prompt_GCBinomCVQ2precisionAmp", CVQ2precisionAmp )
		
		endif
	
	endif

	return NMPulseGCBinomSyn( numWaves=numWaves, dx=dx, waveLength=waveLength, Nsites=Nsites, Pr=Pr, Q=Q, latencySTDV=latencySTDV, CVQS=CVQS, CVQ2=CVQ2, FixCVQ2=FixCVQ2, CVQ2precision=CVQ2precision, CVQ2precisionAmp=CVQ2precisionAmp, addSpillover=addSpillover, history=1 )
	
End // NMPulseGCBinomSynCall

//****************************************************************
//****************************************************************

Function NMPulseGCBinomSyn( [ numWaves, dx, waveLength, Nsites, Pr, Q, latencySTDV, CVQS, CVQ2, FixCVQ2, CVQ2precision, CVQ2precisionAmp, addSpillover, update, history ] )
	Variable numWaves, dx, waveLength
	Variable Nsites, Pr, Q // binomial, number of release sites, probability of release, quantal size
	Variable latencySTDV // creates CVQL
	Variable CVQS, CVQ2
	Variable FixCVQ2, CVQ2precision, CVQ2precisionAmp
	Variable addSpillover
	Variable update
	Variable history

	Variable Qvalue, amp, site
	String sf, paramList, wName, pcwName
	
	String wavePrefix = "EPSC"
	String df = NMPulseDF()
	
	if ( ParamIsDefault( numWaves ) )
		numWaves = 10
	endif
	
	if ( ParamIsDefault( dx ) )
		dx = 0.01
	endif
	
	if ( ParamIsDefault( waveLength ) )
		waveLength = 5
	endif
	
	if ( ParamIsDefault( Nsites ) )
		Nsites = 5
	endif
	
	if ( ParamIsDefault( Pr ) )
		Pr = 0.5
	endif
	
	if ( ParamIsDefault( Q ) )
		Q = -16
	endif
	
	if ( ParamIsDefault( latencySTDV ) )
		latencySTDV = 0 // 0.08
	endif
	
	if ( ParamIsDefault( CVQS ) )
		CVQS = 0 // 0.3
	endif
	
	if ( ParamIsDefault( CVQ2 ) )
		CVQ2 = 0 // 0.3
	endif
	
	if ( ParamIsDefault( FixCVQ2 ) )
		FixCVQ2 = 1
	endif
	
	if ( ParamIsDefault( CVQ2precision ) )
		CVQ2precision = 1 // %
	endif
	
	if ( ParamIsDefault( CVQ2precisionAmp ) )
		CVQ2precisionAmp = 1 // %
	endif
	
	//Variable APonset = 0.44 // 0.5
	
	Variable latencyFromAP = 0.5 // 1.0 // APonset + latencySTDV * 7
	
	Variable spilloverLatency = latencyFromAP + 0.18 // 0.18 + 7 * 0.08 = 0.74 // from AP
	Variable spilloverAmp = -3.471
	Variable spilloverAmpCV = 0.31
	
	Variable year = 2005 // 2002 // or 2012
	
	String directList = NMPulseSynExp4_GC_AMPAdirect( year=year )
	String spillList = NMPulseSynExp4_GC_AMPAspill( year=year )
	
	directList = RemoveFromList( "pulse=synexp4", directList, ";" )
	spillList = RemoveFromList( "pulse=synexp4", spillList, ";" )
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( history )
		NMCommandHistory( "" )
	endif
	
	NMPulseCheck()
	
	sf = NMPulseSubfolder()
	pcwName = NMPulseConfigWaveName()
	
	NMPulseConfigWaveRemove( pcwName, all = 1 )
	
	SetNMstr( df + "CurrentPrefixPulse", wavePrefix )
	
	SetNMvar( sf + "NumWaves", numWaves )
	SetNMvar( sf + "WaveLength", waveLength )
	SetNMvar( sf + "DeltaX", dx )
	
	SetNMstr( sf + "Xunits", NMXunits )
	SetNMstr( sf + "Yunits", "pA" )
	
	if ( CVQ2 > 0 )
	
		wName = NMPulseGCBinomSynSiteAmps( Nsites, Q, CVQ2, CVQ2precision = CVQ2precision, CVQ2precisionAmp = CVQ2precisionAmp )
	
		if ( strlen( wName ) == 0 )
			return -1 // error
		endif
		
		Wave amps = $wName
	
		for ( site = 0 ; site < Nsites ; site += 1 )
		
			if ( site >= numpnts( amps ) )
				break
			endif
	
			//amp = Q + gnoise( Q * CVQ2 )
			//amps[ site ] = amp
			amp = amps[ site ]
		
			paramList = "wave=all;pulse=synexp4;"
			paramList += NMPulseParamList( "amp", amp, cv = CVQS, fixPolarity = 1 )
			paramList += NMPulseParamList( "onset", latencyFromAP, stdv = latencySTDV )
			//paramList += NMPulseParamList( "width", inf )
			paramList += directList
			paramList += NMPulseParamList( "binomialN", 1 )
			paramList += NMPulseParamList( "binomialP", Pr )
			
			NMPulseConfigAdd( paramList, history = 1 )
		
		endfor
	
	else
	
		paramList = "wave=all;pulse=synexp4;"
		paramList += NMPulseParamList( "amp", Q )
		paramList += NMPulseParamList( "onset", latencyFromAP, stdv = latencySTDV )
		//paramList += NMPulseParamList( "width", inf )
		paramList += directList
		paramList += NMPulseParamList( "binomialN", Nsites )
		paramList += NMPulseParamList( "binomialP", Pr )
		
		NMPulseConfigAdd( paramList, history = 1 )
	
	endif
	
	if ( addSpillover )
	
		paramList = "wave=all;pulse=synexp4;"
		paramList += NMPulseParamList( "amp", spilloverAmp, cv = spilloverAmpCV, fixPolarity = 1 )
		paramList += NMPulseParamList( "onset", spilloverLatency )
		//paramList += NMPulseParamList( "width", inf )
		paramList += spillList
		
		NMPulseConfigAdd( paramList, history = 1 )
		
	endif
	
	if ( update )
		NMPulseUpdate()
	endif
	
End // NMPulseGCBinomSyn

//****************************************************************
//****************************************************************

Function /S NMPulseGCBinomSynSiteAmps( binomialN, Q, CVQ2 [ CVQ2precision, CVQ2precisionAmp ] ) // set mean amplitude of individual sites ( added 19/01/04 )
	Variable binomialN, Q, CVQ2
	Variable CVQ2precision, CVQ2precisionAmp
	
	Variable icnt, cvlogic, avglogic, avgAmp, sqrtN, CVQ22, FixCVQ2, maxloops = 1e20
	String sf = NMPulseSubfolder()
	
	String wName = "MeanSiteAmp"
	
	Make /D/O/N=( binomialN ) $sf + wName = Q
	
	Wave amps = $sf + wName
	
	//sqrtN = sqrt( N / ( N - 1 ) ) // David's old code
	sqrtN = 1 // Federico's code, POPULATION VERSUS SAMPLE VARIANCE ????
	
	if ( !ParamIsDefault( CVQ2precision ) && ( CVQ2precision > 0 ) && ( CVQ2precision < 100 ) )
		if ( !ParamIsDefault( CVQ2precisionAmp ) && ( CVQ2precisionAmp > 0 ) && ( CVQ2precisionAmp < 100 ) )
			FixCVQ2 = 1
		endif
	endif
	
	CVQ2 = abs( CVQ2 )
	
	CVQ2precision /= 100 // convert to fraction
	CVQ2precisionAmp /= 100 // convert to fraction
	
	if ( ( binomialN > 1 ) && ( CVQ2 > 0 ) )
	
		if ( FixCVQ2 )
		
			do
	
				amps = Q + gnoise( Q * CVQ2 * sqrtN )
				
				WaveStats /Q amps
				
				CVQ22 = ( V_sdev * sqrtN / V_avg ) ^ 2
				avgAmp = abs( V_avg )
				
				cvlogic = ( CVQ22 > CVQ2 ^ 2 * ( 1 + CVQ2precision ) ) || ( CVQ22 < CVQ2 ^ 2 * ( 1 - CVQ2precision ) )
				avglogic = ( avgAmp > abs( Q * ( 1 + CVQ2precisionAmp ) ) ) || ( avgAmp < abs( Q * ( 1 - CVQ2precisionAmp ) ) )
				
				if ( icnt > maxloops )
					NMDoAlert( "Error: FixCVQ2 failed to converge. Try running again." )
					return ""
				endif
				
				icnt += 1
				
			while ( cvlogic || avglogic ) // loop while this expression is TRUE
			
			//Print icnt, "trials to compute site Q amplitudes"
			
		else
			
			amps = Q + gnoise( Q * CVQ2 * sqrtN )
			
		endif
		
	endif
	
	WaveStats /Q amps
	
	Print "Average site Q amplitude =", V_avg, "±", V_sdev
	Print "CVQ2 =", abs( V_sdev * sqrtN / V_avg )
	
	return sf + wName
	
End // NMPulseGCBinomSynSiteAmps

//****************************************************************
//****************************************************************

Function /S NMPulseGCTrainCall()

	Variable useExisting, stdSelect
	String wavePrefix, wList, std2
	String AMPAmodel, NMDAmodel
	
	String df = NMPulseDF
	String sf = NMPulseSubfolder()
	
	String title = "Pulse GC Synaptic Conductance Train"
	
	Variable numWaves = NumVarOrDefault( df + "NumWaves", 100 )
	numWaves = NumVarOrDefault( sf + "NumWaves", numWaves )
	
	Variable dx = NumVarOrDefault( df + "DeltaX", 0.005 )
	dx = NumVarOrDefault( sf + "DeltaX", dx )
	
	Variable waveLength = NumVarOrDefault( df + "WaveLength", 8 )
	waveLength = NumVarOrDefault( sf + "WaveLength", waveLength )
	
	if ( ( numWaves == NumWavesDefault ) && ( dx == DeltaxDefault ) && ( waveLength == WaveLengthDefault ) )
		numWaves = 1
		dx = 0.01
		waveLength = 1000
	endif
	
	numWaves = max( numWaves, 1 )
	
	Prompt numWaves, "number of waves to compute:"
	Prompt dx, "wave sample interval (delta-x):"
	Prompt waveLength, "wave length:"

	String type = StrVarOrDefault( df + "Prompt_GCTrainType", "AMPA" )
	String STPmodel = StrVarOrDefault( df + "Prompt_GCTrainSTP", "RP" )
	Variable freq = NumVarOrDefault( df + "Prompt_GCTrainFreq", 0.03 ) // kHz
	Variable random = 1 + NumVarOrDefault( df + "Prompt_GCTrainRandom", 1 )
	Variable numInputs = NumVarOrDefault( df + "Prompt_GCTrainNumInputs", 4 )
	
	strswitch( STPmodel )
		case "DF":
			stdSelect = 1
			break
		default:
			stdSelect = 2
			break
	endswitch
	
	Prompt type, "conductance type:", popup "AMPA;NMDA;"
	Prompt stdSelect, "plasticity model:", popup "DF (Rothman 2012);RP (Billings 2014);"
	Prompt freq, "frequency of input train (kHz):"
	Prompt random, "input intervals:", popup "fixed;random;"
	Prompt numInputs, "input trains per wave:"
	
	DoPrompt title, numWaves, dx, waveLength
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMvar( sf + "NumWaves", numWaves )
	SetNMvar( sf + "DeltaX", dx )
	SetNMvar( sf + "WaveLength", waveLength )
	
	DoPrompt title, type, stdSelect, freq, random, numInputs
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	switch( stdSelect )
		case 1:
			STPmodel = "DF"
			AMPAmodel = "Rothman"
			NMDAmodel = "Rothman"
			break
		case 2:
			STPmodel = "RP"
			AMPAmodel = "Billings"
			NMDAmodel = "Billings"
			break
		default:
			return ""
	endswitch
	
	random -= 1
	
	SetNMstr( df + "Prompt_GCTrainType", type )
	SetNMstr( df + "Prompt_GCTrainSTP", STPmodel )
	SetNMvar( df + "Prompt_GCTrainFreq", freq )
	SetNMvar( df + "Prompt_GCTrainRandom", random )
	SetNMvar( df + "Prompt_GCTrainNumInputs", numInputs )
	SetNMvar( df + "Prompt_GCTrainNumWaves", numWaves )
	
	wavePrefix = "PU_Ran" + num2istr( round( freq * 1000 ) ) + "Hz_w0"
	
	wList = WaveList( wavePrefix + "*", ";", "" )
	
	if ( random && ItemsInList( wList ) > 0 )
	
		useExisting = 2
	
		Prompt useExisting, "using existing waves of pulse times if they exist?", popup "no;yes;"
		DoPrompt title, useExisting
	
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		useExisting -= 1
		
	endif
	
	return NMPulseGCTrain( numWaves = numWaves, dx = dx, waveLength = waveLength, type = type, AMPAmodel = AMPAmodel, NMDAmodel = NMDAmodel, STPmodel = STPmodel, freq = freq, random = random, numInputs = numInputs, useExistingRanTrains = useExisting, history = 1 )

End // NMPulseGCTrainCall

//****************************************************************
//****************************************************************

Function /S NMPulseGCTrain( [ numWaves, dx, waveLength, type, AMPAmodel, NMDAmodel, STPmodel, freq, random, numInputs, useExistingRanTrains, update, history ] )
	Variable numWaves, dx, waveLength
	String type // "AMPA" or "NMDA"
	String AMPAmodel // "Digregorio" or "Rothman" or "Billings" // 2002 or 2012 or 2014
	String NMDAmodel // "Rothman" or "Billings"
	String STPmodel // "DF" for Rothman or "RP" for Billings
	Variable freq
	Variable random
	Variable numInputs
	
	Variable useExistingRanTrains
	Variable update
	Variable history
	
	Variable icnt, wcnt, amp1, amp2, pinf, RPmodel, BillingsModel, normValue
	Variable AMPAnorm
	String sf, pcwName, wavePrefix, wName, wList = ""
	String trainList, trainList2, paramList, paramList2, paramList3
	String directSTPlist, spillSTPlist, nmdaSTPlist 
	
	Variable timeLimit = waveLength - 50
	
	Variable amp = 0.63
	
	String df = NMPulseDF()
	
	if ( ParamIsDefault( numWaves ) || ( numWaves <= 0 ) )
		numWaves = 1
	endif
	
	if ( ParamIsDefault( dx ) || ( numWaves <= 0 ) )
		dx = 0.01
	endif
	
	if ( ParamIsDefault( waveLength ) || ( waveLength <= 0 ) )
		waveLength = 1000
	endif
	
	if ( ParamIsDefault( type ) )
		type = "AMPA"
	endif
	
	if ( !StringMatch( type, "AMPA" ) && !StringMatch( type, "NMDA" ) )
		return "" // unknown type
	endif
	
	wavePrefix = "g" + type
	
	if ( ParamIsDefault( AMPAmodel ) )
		AMPAmodel = "Rothman"
	endif
	
	if ( ParamIsDefault( NMDAmodel ) )
		NMDAmodel = "Rothman"
	endif
	
	if ( ParamIsDefault( STPmodel ) )
		STPmodel = "DF"
	endif
	
	if ( ParamIsDefault( freq ) )
		freq = 0.01 // kHz
	endif
	
	if ( ParamIsDefault( numInputs ) )
		numInputs = 4
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( history )
		NMCommandHistory( "" )
	endif
	
	SetNMstr( df + "CurrentPrefixPulse", wavePrefix )
	
	NMPulseCheck()
	
	sf = NMPulseSubfolder()
	pcwName = NMPulseConfigWaveName()
	
	NMPulseConfigWaveRemove( pcwName, all = 1 )
	
	SetNMvar( sf + "NumWaves", numWaves )
	SetNMvar( sf + "WaveLength", waveLength )
	SetNMvar( sf + "DeltaX", dx )
	SetNMstr( sf + "Xunits", NMXunits )
	SetNMstr( sf + "Yunits", "nS" )
	
	STRUCT NMPulseTrain t
	
	if ( random )
		t.type = ""
	else
		t.type = "fixed"
	endif
	
	t.tbgn = -inf
	t.tend = inf
	t.interval = 1 / freq
	t.refrac = 1
	
	trainList = NMPulseTrainParamList( t )
	trainList2 = trainList
	
	strswitch( AMPAmodel )
		case "Digregorio":
			AMPAnorm = 1.12551 // THE WAVEFORMS ARE NORMALIZED???
		case "Rothman":
			AMPAnorm = 1.16655 // THE WAVEFORMS ARE NORMALIZED???
			break
		case "Billings":
			AMPAnorm = 1
			break
		default:
			return ""
	endswitch
	
	strswitch( STPmodel )
		case "DF":
			directSTPlist = NMPulseTrainDF_GC_AMPAdirect()
			spillSTPlist = NMPulseTrainDF_GC_AMPAspill()
			nmdaSTPlist = NMPulseTrainDF_GC_NMDA()
			RPmodel = 0
			break
		case "RP":
			directSTPlist = NMPulseTrainRP_GC_AMPAdirect()
			spillSTPlist = NMPulseTrainRP_GC_AMPAspill()
			nmdaSTPlist = NMPulseTrainRP_GC_NMDA()
			RPmodel = 1
			break
		default:
			return ""
	endswitch
	
	for ( wcnt = 0 ; wcnt < numWaves; wcnt += 1 )
	
		for ( icnt = 0 ; icnt < numInputs ; icnt += 1 )
		
			if ( random )
		
				wName = "PU_Ran" + num2istr( round( freq * 1000 ) ) + "Hz_w" + num2istr( wcnt ) + "i" + num2istr( icnt )

				if ( !WaveExists( $sf + wName ) || !useExistingRanTrains )
					// wave of pulse times are saved where pulse config waves are located
					// however, this may be problematic for using pulse-time waves to create other waveforms
					// e.g. for creating both gAMPA and gNMDA waveforms using same pulse times
					NMPulseTrainRandomTimes( sf, wName, trainList, timeLimit )
				endif
				
				if ( !WaveExists( $sf + wName ) )
					continue
				endif
				
				wList += wName + ";"
				
				trainList2 = "train=" + wName + ";"
			
			endif
			
			if ( StringMatch( type, "AMPA" ) )
			
				// direct
			
				amp1 = amp / AMPAnorm
				
				if ( RPmodel )
				
					pinf = str2num( StringByKey( "Pinf", directSTPlist, "=", ";" ) )
					
					if ( ( numtype( pinf ) == 0 ) && ( pinf > 0 ) && ( pinf < 1 ) )
						amp1 /= pinf
					endif
					
				endif
				
				amp2 = amp1
			
				paramList = "wave=" + num2istr( wcnt ) + ";"
				paramList += trainList2
				
				paramList2 = paramList
				
				strswitch( AMPAmodel )
					case "Rothman":
						paramList += NMPulseSynExp4_GC_AMPAdirect( model=AMPAmodel, amp=amp2 )
						paramList += directSTPlist
						NMPulseConfigAdd( paramList, history = 1 )
						break
					case "Billings":
						paramList += NMPulseExp_GC_AMPAdirect( select = 0 )
						paramList += directSTPlist
						paramList2 += NMPulseExp_GC_AMPAdirect( select = 1 )
						paramList2 += directSTPlist
						NMPulseConfigAdd( paramList, history = 1 )
						NMPulseConfigAdd( paramList2, history = 1 )
						break
					default:
						return ""
				endswitch
				
				// spillover
				
				amp1 *= 0.34 // Rothman 2016
				
				if ( RPmodel )
				
					pinf = str2num( StringByKey( "Pinf", spillSTPlist, "=", ";" ) )
					
					if ( ( numtype( pinf ) == 0 ) && ( pinf > 0 ) && ( pinf < 1 ) )
						amp1 /= pinf
					endif
					
				endif
				
				amp2 = amp1
				
				paramList = "wave=" + num2istr( wcnt ) + ";"
				paramList += trainList2
				
				paramList2 = paramList
				paramList3 = paramList
				
				strswitch( AMPAmodel )
					case "Rothman":
						paramList +=  NMPulseSynExp4_GC_AMPAspill( model=AMPAmodel, amp=amp2 )
						paramList += spillSTPlist
						NMPulseConfigAdd( paramList, history = 1 )
						break
					case "Billings":
						paramList += NMPulseExp_GC_AMPAspill( select = 0 )
						paramList += spillSTPlist
						paramList2 += NMPulseExp_GC_AMPAspill( select = 1 )
						paramList2 += spillSTPlist
						paramList3 += NMPulseExp_GC_AMPAspill( select = 2 )
						paramList3 += spillSTPlist
						NMPulseConfigAdd( paramList, history = 1 )
						NMPulseConfigAdd( paramList2, history = 1 )
						NMPulseConfigAdd( paramList3, history = 1 )
						break
					default:
						return ""
				endswitch
			
			elseif ( StringMatch( type, "NMDA" ) )
			
				paramList = "wave=" + num2istr( wcnt ) + ";"
				paramList += trainList2
				
				paramList2 = paramList
				
				strswitch( NMDAmodel )
					case "Rothman":
						paramList += NMPulseSynExp4_GC_NMDA( amp=amp )
						paramList += nmdaSTPlist
						break
					case "Billings":
						paramList += NMPulseExp_GC_NMDA( select = 0 )
						paramList += nmdaSTPlist
						paramList2 += NMPulseExp_GC_NMDA( select = 1 )
						paramList2 += nmdaSTPlist
						NMPulseConfigAdd( paramList, history = 1 )
						NMPulseConfigAdd( paramList2, history = 1 )
						break
					default:
						return ""
				endswitch
			
			endif
		
		endfor
	
	endfor
	
	if ( update )
		NMPulseUpdate()
	endif
	
	return wList

End // NMPulseGCTrain

//****************************************************************
//****************************************************************

Function /S NMPulsePromptCall( [ row, OOD ] ) // DEPRECATED // use NMPulseLB1PromptNew() and NMPulseLB1PromptOOD()
	Variable row
	Variable OOD // on / off / delete
	
	String sf = NMPulseSubfolder()
	
	STRUCT NMPulseLBWaves lb
	
	NMPulseTabLBWavesDefault( lb )
	
	if ( OOD )
		return NMPulseLB1PromptOODE( lb, sf )
	else
		return NMPulseLB1PromptNew()
	endif

End // NMPulsePromptCall

//****************************************************************
//****************************************************************



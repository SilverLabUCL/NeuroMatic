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
//	Model Tab Functions 
//
//	Set and Get functions:
//
//		NMModelSet( [ modelSelect, clampSelect, history ] )
//		NMModelVarSet( varName, value [ history ] )
//		NMModelStrSet( strVarName, strValue [ history ] )
//		NMModelVarGet( varName )
//		NMModelStrGet( strVarName )
//
//	Useful functions:
//
//		NMModelRun( [ history ] )
//		NMModelEdit( [ history ] )
//		NMModelKineticWavesAll( [ plotWaves, history ] )
//		NMModelProcedureCode( [ history ] )
//		
//****************************************************************
//****************************************************************

StrConstant NMModelDF = "root:Packages:NeuroMatic:Model:"

Static StrConstant GnmdaBlockFxnList = "Boltzmann;GC_Rothman2009;GC_Schwartz2012;"
Static Constant GnmdaBlockVhalf = -12.8
Static Constant GnmdaBlockVslope = 22.4

Static Constant printIntegrateODE = 0 // print IntegrateODE command to history ( 0 ) no ( 1 ) yes

Static StrConstant IonChannelList = "TonicGABA;Leak;Na;NaR;NaP;K;KA;KD;KCa;Kir;Kslow;H;Ca;"
Static StrConstant iClampParList = "iClampAmp;iClampAmpInc;iClampOnset;iClampDuration;"
Static StrConstant vClampParList = "vClampAmp;vClampAmpInc;vClampOnset;vClampDuration;"

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMTabPrefix_Model()

	return "MD_"

End // NMTabPrefix_Model

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMModelDF() // data folder where tab globals are stored

	String pdf = NMModelSubDF()

	if ( DataFolderExists( pdf ) )
		return pdf
	endif
	
	return NMModelDF

End // NMModelDF

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMModelSubDF()
	
	String currentFolder = CurrentNMFolder( 1 )
	String subFolder
	
	if ( strlen( currentFolder ) == 0 )
		return ""
	endif
	
	subfolder = "Model"
	//subfolder = "Model_" + StrVarOrDefault(  "ModelSelect" )

	return currentFolder + subfolder + ":" // subfolder in current data folder

End // NMModelSubDF

//****************************************************************
//****************************************************************
//****************************************************************

Function ModelTab( enable ) // activate or inactivate the tab
	Variable enable

	if ( enable )
		CheckNMPackage( "Model" , 1 ) // declare globals if necessary
		NMModelTabMake( 0 )
	endif

End // ModelTab

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelCheck() // create global variables for tab display

	Variable icnt, initModel
	String aList, cName
	String df = NMModelDF()
	
	if ( exists( df + "ModelSelect" ) == 0 )
		initModel = 1
	endif
	
	CheckNMvar( NMModelDF + "OverwriteMode", 1 )
	CheckNMvar( NMModelDF + "IntegrateODEMethod", 1 )
	
	zCheckStrList( "ModelSelect;CellName;ClampSelect;WavePrefix;" )
	zCheckVarList( "FirstSimulation;LastSimulation;NumSimulations;SimulationCounter;" )
	zCheckVarList( "SimulationTime;TimeStep;NumTimeSteps;" )
	zCheckVarList( "Temperature;gQ10;tauQ10;CaInside;CaOutside;V0;" )
	zCheckVarList( "Diameter;SurfaceArea;CmDensity;Cm;" )
	
	zCheckVarList( iClampParList )
	zCheckVarList( vClampParList )
	
	zCheckStrList( "gGABA_WavePrefix;gAMPA_WavePrefix;gNMDA_WavePrefix;gNMDA_BlockFxnList;" )
	zCheckVarList( "gGABA_NumWaves;gAMPA_NumWaves;gNMDA_NumWaves;" )
	zCheckVarList( "eGABA;eAMPA;eNMDA;" )
	
	zCheckVarList( "AP_Threshold;AP_Peak;AP_Reset;AP_Refrac;" )
	
	zCheckVarList( "AP_ThreshSlope;W_Tau;W_A;W_B;" )
	
	for ( icnt = 0 ; icnt < ItemsInList( IonChannelList ) ; icnt += 1 )
	
		cName = StringFromList( icnt, IonChannelList )
		aList = AddListItem( "g" + cName + "Density", "", ";", inf )
		aList = AddListItem( "g" + cName, aList, ";", inf )
		aList = AddListItem( "e" + cName, aList, ";", inf )
		
		zCheckVarList( aList )
		
	endfor
	
	if ( initModel )
		NMModelSelect( NMModelStrGet( "ModelSelect" ) )
	else
		NMModelVariablesInit()
	endif
	
End // NMModelCheck

//****************************************************************
//****************************************************************
//****************************************************************

Static Function zCheckVarList( varNameList )
	String varNameList
	
	Variable icnt
	String varName, df = NMModelDF()
	
	for ( icnt = 0 ; icnt < ItemsInList( varNameList ) ; icnt += 1 )
		varName = StringFromList( icnt, varNameList )
		CheckNMvar( df + varName, NMModelVarGet( varName ) )
	endfor
	
End // zCheckVarList

//****************************************************************
//****************************************************************
//****************************************************************

Static Function zCheckStrList( strVarNameList )
	String strVarNameList
	
	Variable icnt
	String strVarName, df = NMModelDF()
	
	for ( icnt = 0 ; icnt < ItemsInList( strVarNameList ) ; icnt += 1 )
		strVarName = StringFromList( icnt, strVarNameList )
		CheckNMstr( df+strVarName, NMModelStrGet( strVarName ) )
	endfor
	
End // zCheckStrList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelConfigs()
	
	NMConfigVar( "Model", "OverwriteMode", 1, "overwrite existing waves, tables and graphs if their is a name conflict", "boolean" )
	NMConfigVar( "Model", "IntegrateODEMethod", 0, "see IntegrateODE Method flag, 0, 1, 2, 3", "" )
			
End // NMModelConfigs

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Model Variable / String functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelSet( [ modelSelect, clampSelect, history ] )
	String modelSelect
	String clampSelect
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	String vlist = ""
	
	if ( !ParamIsDefault( modelSelect ) )
	
		vlist = NMCmdStrOptional( "modelSelect", modelSelect, vlist )
		
		NMModelSelect( modelSelect )
		
	endif
	
	if ( !ParamIsDefault( clampSelect ) )
	
		vlist = NMCmdStrOptional( "clampSelect", clampSelect, vlist )
		
		NMModelClampSelect( clampSelect )
		
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif

End // NMModelSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelVarGet( varName )
	String varName
	
	String sdf = NMModelDF()
	String thisfxn = GetRTStackInfo( 1 )
	
	Variable defaultVal = NaN
	
	strswitch( varName )
	
		case "OverwriteMode":
			defaultVal = 1
			sdf = NMModelDF
			break
			
		case "IntegrateODEMethod":
			defaultVal = 0
			sdf = NMModelDF
			break
	
		case "FirstSimulation":
			defaultVal = 0
			break
			
		case "LastSimulation":
			defaultVal = 0
			break
	
		case "NumSimulations":
			defaultVal = 1
			break
			
		case "SimulationCounter":
			defaultVal = 0
			break
			
		case "SimulationTime":
			defaultVal = 50 // ms
			break
			
		case "TimeStep":
			defaultVal = 0.02 // ms
			break
			
		case "NumTimeSteps":
			defaultVal = 100 / 0.01
			break
			
		case "Temperature":
			defaultVal = 37 // C
			break
			
		case "gQ10":
			defaultVal = 2
			break
			
		case "tauQ10":
			defaultVal = 3
			break
			
		case "CaInside":
			defaultVal = 30e-6 // mM
			break
			
		case "CaOutside":
			defaultVal = 2 // mM
			break
			
		case "V0":
			defaultVal = -65 // mV
			break
			
		case "Diameter":
			defaultVal = 20 // um
			break
			
		case "SurfaceArea":
			defaultVal = NaN
			break
			
		case "CmDensity":
			defaultVal = 1e-2 // pF / um^2
			break
			
		case "Cm":
			defaultVal = NaN
			break
			
		case "iClampAmp":
			defaultVal = 0 // pA
			break
			
		case "iClampAmpInc":
			defaultVal = 0 // pA
			break
			
		case "iClampOnset":
			defaultVal = 10 // ms
			break
			
		case "iClampDuration":
			defaultVal = 100 // ms
			break
			
		case "vClampAmp":
			defaultVal = 0 // mV
			break
			
		case "vClampAmpInc":
			defaultVal = 0 // mV
			break
			
		case "vClampOnset":
			defaultVal = 20 // ms
			break
			
		case "vClampDuration":
			defaultVal = 100 // ms
			break
			
		case "gLeakDensity":
			defaultVal = 0
			break
			
		case "gLeak":
			defaultVal = NaN
			break
			
		case "eLeak":
			defaultVal = NaN
			break
			
		case "gNaDensity":
			defaultVal = 0
			break
			
		case "gNa":
			defaultVal = NaN
			break
			
		case "eNa":
			defaultVal = NaN
			break
			
		case "gNaRDensity":
			defaultVal = 0
			break
			
		case "gNaR":
			defaultVal = NaN
			break
			
		case "eNaR":
			defaultVal = NaN
			break
			
		case "gNaPDensity":
			defaultVal = 0
			break
			
		case "gNaP":
			defaultVal = NaN
			break
			
		case "eNaP":
			defaultVal = NaN
			break
			
		case "gKDensity":
			defaultVal = 0
			break
			
		case "gK":
			defaultVal = NaN
			break
			
		case "eK":
			defaultVal = NaN
			break
			
		case "gKADensity":
			defaultVal = 0
			break
			
		case "gKA":
			defaultVal = NaN
			break
			
		case "eKA":
			defaultVal = NaN
			break
			
		case "gKDDensity":
			defaultVal = 0
			break
			
		case "gKD":
			defaultVal = NaN
			break
			
		case "eKD":
			defaultVal = NaN
			break
			
		case "gKslowDensity":
			defaultVal = 0
			break
			
		case "gKslow":
			defaultVal = NaN
			break
			
		case "eKslow":
			defaultVal = NaN
			break
			
		case "gKCaDensity":
			defaultVal = 0
			break
			
		case "gKCa":
			defaultVal = NaN
			break
			
		case "eKCa":
			defaultVal = NaN
			break
			
		case "gKirDensity":
			defaultVal = 0
			break
			
		case "gKir":
			defaultVal = NaN
			break
			
		case "eKir":
			defaultVal = NaN
			break
			
		case "gHDensity":
			defaultVal = 0
			break
			
		case "gH":
			defaultVal = NaN
			break
			
		case "eH":
			defaultVal = NaN
			break
			
		case "gCaDensity":
			defaultVal = 0
			break
			
		case "gCa":
			defaultVal = NaN
			break
			
		case "eCa":
			defaultVal = NaN
			break
			
		case "gTonicGABADensity":
			defaultVal = 0
			break
			
		case "gTonicGABA":
			defaultVal = NaN
			break
			
		case "gGABA_NumWaves":
			defaultVal = 0
			break
			
		case "eGABA":
		case "eTonicGABA":
			defaultVal = -75 // mV
			break
			
		case "gAMPA_NumWaves":
			defaultVal = 0
			break
			
		case "eAMPA":
			defaultVal = 0
			break
			
		case "gNMDA_NumWaves":
			defaultVal = 0
			break
			
		case "eNMDA":
			defaultVal = 0
			break
			
		case "AP_Threshold":
			defaultVal = -40
			break
			
		case "AP_Peak":
			defaultVal = -40 + 72
			break
			
		case "AP_Reset":
			defaultVal = -40 + -21
			break
			
		case "AP_Refrac":
			defaultVal = 0.9
			break
			
		case "AP_ThreshSlope":
			defaultVal = 2
			break
			
		case "W_Tau":
			defaultVal = 300
			break
			
		case "W_A":
			defaultVal = 2
			break
			
		case "W_B":
			defaultVal = 60
			break
			
		case "gLeak_gRest":
			defaultVal = 0.462
			break
			
		case "gLeak_gDepo":
			defaultVal = 1
			break
			
		case "gLeak_vHalf":
			defaultVal = -43
			break
			
		case "gLeak_vSlope":
			defaultVal = 2.2
			break
			
		default:
			NMDoAlert( thisfxn + " error: no such variable: " + NMQuotes( varName ) )
			return NaN
	
	endswitch
	
	if ( !DataFolderExists( sdf ) )
		return defaultVal
	endif
	
	return NumVarOrDefault( sdf+varName, defaultVal )
	
End // NMModelVarGet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMModelStrGet( strVarName )
	String strVarName
	
	String sdf = NMModelDF()
	String thisfxn = GetRTStackInfo( 1 )
	
	String defaultStr = ""
	
	strswitch( strVarName )
	
		case "ModelSelect":
			defaultStr = "HodgkinHuxley"
			break
			
		case "ClampSelect":
			defaultStr = "Iclamp"
			break
			
		case "CellName":
			defaultStr = "Model"
			break
			
		case "WavePrefix":
			defaultStr = "Sim_"
			break
			
		case "gGABA_WavePrefix":
			defaultStr = "gGABA_"
			break
			
		case "gAMPA_WavePrefix":
			defaultStr = "gAMPA_"
			break
			
		case "gNMDA_WavePrefix":
			defaultStr = "gNMDA_"
			break
			
		case "gNMDA_BlockFxnList":
			defaultStr = "Boltzmann;Vhalf=" + num2str( GnmdaBlockVhalf ) + ";Vslope=" + num2str( GnmdaBlockVslope ) + ";"
			break
			
		default:
			NMDoAlert( thisfxn + "error: cannot find string variable " + NMQuotes( strVarName ) )
			return ""
			
	endswitch
	
	if ( !DataFolderExists( sdf ) )
		return defaultStr
	endif
	
	return StrVarOrDefault( sdf + strVarName, defaultStr )
			
End // NMModelStrGet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMModelStr2( modelName, strVarName )
	String modelName
	String strVarName
	
	String tempStr, df = NMModelDF()
	String thisfxn = GetRTStackInfo( 1 )
	
	String /G MD_StrVarTemp
	
	String fxn = "NMModelStr_" + modelName
	
	if ( exists( fxn ) != 6 )
		NMDoAlert( thisfxn + " error: cannot find function " + NMQuotes( fxn ) )
		return ""
	endif
	
	Execute "MD_StrVarTemp = " + fxn + "(" + NMQuotes( strVarName ) + ")"
	
	tempStr = MD_StrVarTemp
	
	KillStrings /Z MD_StrVarTemp
	
	return tempStr
	
End // NMModelStr2

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMModelList()

	String funcList = FunctionList( "NMModelStr_*", ";", "KIND:2" )
	
	funcList = ReplaceString( "NMModelStr_", funcList, "" )
	
	return funcList

End // NMModelList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelVariablesInit() // initialize input variables

	Variable icnt
	String cName
	String wPrefix, wList, df = NMModelDF()
	String thisfxn = GetRTStackInfo( 1 )
	
	Variable FirstSimulation = NumVarOrDefault( df + "FirstSimulation", 0 )
	Variable LastSimulation = NumVarOrDefault( df + "LastSimulation", 0 )
	
	FirstSimulation = min( FirstSimulation, LastSimulation )
	LastSimulation = max( FirstSimulation, LastSimulation )
	
	Variable simTime = NMModelSimTime( 0 )
	Variable dt = NumVarOrDefault( df + "TimeStep", 0.01 )
	Variable npnts = ( simTime / dt ) + 1
	Variable numSimulations = LastSimulation - FirstSimulation + 1
	
	if ( ( numtype( numSimulations ) > 0 ) || ( numSimulations < 0 ) )
		numSimulations = 0
	endif
	
	SetNMvar( df + "NumSimulations", numSimulations )
	
	SetNMvar( df + "NumTimeSteps", npnts )
	
	Variable diameter = NumVarOrDefault( df + "Diameter", 20 ) // um
	Variable SA = pi * diameter ^ 2 // um^2
	
	SetNMvar( df + "SurfaceArea", SA )
	
	NMModelVariablesInit2( "Cm", SA )
	
	for ( icnt = 0 ; icnt < ItemsInList( IonChannelList ) ; icnt += 1 )
		cName = StringFromList( icnt, IonChannelList )
		NMModelVariablesInit2( "g" + cName, SA )
	endfor
	
	wPrefix = StrVarOrDefault( df + "gGABA_WavePrefix", "" )
	
	icnt = 0
	
	if ( strlen( wPrefix ) > 0 )
		wList = WaveList( wPrefix + "*", ";", "" )
		icnt = ItemsInList( wList )
	endif
	
	SetNMvar( df + "gGABA_NumWaves", icnt )
	
	wPrefix = StrVarOrDefault( df + "gAMPA_WavePrefix", "" )
	
	icnt = 0
	
	if ( strlen( wPrefix ) > 0 )
		wList = WaveList( wPrefix + "*", ";", "" )
		icnt = ItemsInList( wList )
	endif
	
	SetNMvar( df + "gAMPA_NumWaves", icnt )
	
	wPrefix = StrVarOrDefault( df + "gNMDA_WavePrefix", "" )
	
	icnt = 0
	
	if ( strlen( wPrefix ) > 0 )
		wList = WaveList( wPrefix + "*", ";", "" )
		icnt = ItemsInList( wList )
	endif
	
	SetNMvar( df + "gNMDA_NumWaves", icnt )
	
	return 0

End // NMModelVariablesInit

//****************************************************************
//****************************************************************
//****************************************************************

Static Function NMModelVariablesInit2( varName, SA )
	String varName
	Variable SA // surface area
	
	String df = NMModelDF()
	String thisfxn = GetRTStackInfo( 1 )
	
	String varNameDensity = df + varName + "Density"
	
	if ( exists( varNameDensity ) != 2 )
		NMDoAlert( thisfxn + " error: cannot find variable " + NMQuotes( varNameDensity ) )
		return -1
	endif
	
	Variable density = NumVarOrDefault( varNameDensity, NaN )
	
	SetNMvar( df + varName, density * SA )
	
	return 0
	
End // NMModelVariablesInit2

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelSelect( modelName [ update ] )
	String modelName
	Variable update
	
	String fxn, df = NMModelDF()
	String thisfxn = GetRTStackInfo( 1 )
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	String stateList = NMModelStr2( modelName, "StateList" )
	
	if ( ItemsInList( stateList ) == 0 )
		NMDoAlert( thisfxn + " error:  cannot find StateList for model " + NMQuotes( modelName ) )
		return -1 // no states, something is wrong
	endif
	
	SetNMstr( df + "StateList", stateList )
	
	fxn = modelName + "_Init"
	
	if ( exists( fxn ) != 6 )
		NMDoAlert( thisfxn + " error: cannot find function " + NMQuotes( fxn ) )
		return -1 // no init function, something is wrong
	endif
	
	SetNMstr( df + "ModelSelect" , modelName )
	
	NMModelInit()
	
	Execute fxn + "()"
	
	if ( update )
		NMModelTabUpdate()
	endif
	
	return 0
	
End // NMModelSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelInit()

	String df = NMModelDF()

	SetNMvar( df + "gLeakDensity", 0 )
	SetNMvar( df + "gTonicGABADensity", 0 )

End // NMModelInit

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelSelectNum( modelSelect )
	String modelSelect // ( "" ) for current model select
	
	Variable icnt
	String itemStr, df = NMModelDF()
	
	String mList = NMModelList()
	
	if ( strlen( modelSelect ) == 0 )
		modelSelect = StrVarOrDefault( df + "ModelSelect", "" )
	endif
	
	for ( icnt = 0 ; icnt < ItemsInList( mList ) ; icnt += 1 )
		
		itemStr = StringFromList( icnt, mList )
		
		if ( StringMatch( itemStr, modelSelect ) )
			return icnt
		endif
	
	endfor
	
	return NaN
	
End // NMModelSelectNum

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelClampSelectToggle()

	Variable clampSelect = NMModelClampSelectNum()
	
	if ( clampSelect == 0 )
		return NMModelSet( ClampSelect = "Vclamp", history = 1 )
	else
		return NMModelSet( ClampSelect = "Iclamp", history = 1 )
	endif
	
End // NMModelClampSelectCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelClampSelect( select [ update ] )
	String select // "Iclamp" or "Vclamp"
	Variable update
	
	String df = NMModelDF()
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	strswitch( select )
		case "Voltage Clamp":
		case "Vclamp":
			SetNMstr( df + "ClampSelect", "Vclamp" )
			break
		default:
			SetNMstr( df + "ClampSelect", "Iclamp" )
	endswitch
	
	if ( update )
		NMModelTabUpdate()
	endif
	
End // NMModelClampSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelClampSelectNum()

	String df = NMModelDF()
	
	String clampSelect = StrVarOrDefault( df + "ClampSelect", "" )
	
	strswitch( clampSelect )
		case "Current":
		case "Iclamp":
			return 0
		case "Voltage":
		case "Vclamp":
			return 1
	endswitch

End // NMModelClampSelectNum

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelVarSet( varName, value [ history ] )
	String varName
	Variable value
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	String vlist = ""
	String df = NMModelDF()
	
	if ( history )
		vlist = NMCmdStr( varName, vlist )
		vlist = NMCmdNum( value, vlist )
		NMCommandHistory( vlist )
	endif
	
	if ( strlen( varName ) == 0 )
		return NM2Error( 21, "varName", varName )
	endif
	
	if ( !DataFolderExists( df ) )
		return NM2Error( 30, "ModelDF", df )
	endif
	
	if ( exists( df+varName ) != 2 )
		return NM2Error( 13, "varName", df+varName )
	endif
	
	Variable /G $df+varName = value
	
	//UpdateModelList( varName, num2str( value ) )
	
	return 0
	
End // NMModelVarSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelStrSet( strVarName, strValue [ history ] )
	String strVarName
	String strValue
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	String vlist = ""
	String df = NMModelDF()
	
	if ( history )
		vlist = NMCmdStr( strVarName, vlist )
		vlist = NMCmdStr( strValue, vlist )
		NMCommandHistory( vlist )
	endif
	
	if ( strlen( strVarName ) == 0 )
		return NM2Error( 21, "strVarName", strVarName )
	endif
	
	if ( !DataFolderExists( df ) )
		return NM2Error( 30, "ModelDF", df )
	endif
	
	if ( exists( df+strVarName ) != 2 )
		return NM2Error( 13, "strVarName", df+strVarName )
	endif
	
	String /G $df+strVarName = strValue
	
	return 0
	
End // NMModelStrSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMModelGnmdaBlockPrompt( selected )
	String selected
	
	String fxn = StringFromList( 0, selected )
	Variable vHalf, vSlope
	
	if ( StringMatch( fxn, "Boltzmann" ) )
		vHalf = str2num( StringFromList( 1, selected ) )
		vSlope = abs( str2num( StringFromList( 2, selected ) ) )
	endif
	
	Prompt fxn, "select model", popup GnmdaBlockFxnList
	Prompt vHalf, "half-max voltage (mV)"
	Prompt vSlope, "slope factor (mV)"
	
	DoPrompt "gNMDA Block", fxn
			 	
	if ( V_flag == 1 )
		return selected // cancel
	endif
	
	if ( StringMatch( fxn, "Boltzmann" ) )
		
		if ( ( numtype( vHalf ) > 0 ) || ( vHalf == 0 ) )
			vHalf = GnmdaBlockVhalf
		endif
		
		if ( ( numtype( vSlope ) > 0 ) || ( vSlope == 0 ) )
			vSlope = GnmdaBlockVslope
		endif
		
		DoPrompt "gNMDA Block - Boltzmann Function", vHalf, vSlope
		
		if ( V_flag == 1 )
			return selected // cancel
		endif
		
		return "Boltzmann;Vhalf=" + num2str( vHalf ) + ";Vslope=" + num2str( vSlope ) + ";"
	
	endif
	
	return fxn
	
End // NMModelGnmdaBlockPrompt

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelSave() // copy Model package folder to current folder - this saves the variables used in current simulation
	
	String df = NMPackageDF( "Model" )
	String pdf = NMModelSubDF()
	
	if ( !DataFolderExists( pdf ) )
		DuplicateDataFolder $RemoveEnding( df, ":" ) $RemoveEnding( pdf, ":" )
		KillVariables /Z $pdf + "OverwriteMode"
		KillVariables /Z $pdf + "IntegrateODEMethod"
	endif

End // NMModelSave

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Model ListBox Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelListUpdate()

	Variable icnt, nrows = 100
	String wName = "Params", ename = "ParamsEditable", df = NMModelDF()
	
	String modelSelect = StrVarOrDefault( df + "ModelSelect", "" )
	String chanList = StrVarOrDefault( df + "StateList", "" )
	
	Make /O/T/N=( nrows, 4 ) $( df+wName ) = ""
	
	Make /O/N=( nrows, 4 ) $( df+ename ) = 0
	
	//Wave /T Params = $df+wName
	//Wave ParamsEditable = $df+ename
	
	NMModelVariablesInit()
	
	NMModelListAddStr( "CellName", 1, "", "cell name / type" )
	
	NMModelListBlank()
	NMModelListAddStr( "WavePrefix", 1, "", "wave prefix for output waves" )
	
	NMModelListBlank()
	NMModelListAddVar( "FirstSimulation", 1, "", "first simulation number" )
	NMModelListAddVar( "LastSimulation", 1, "", "last simulation number" )
	NMModelListAddVar( "NumSimulations", 0, "", "number of simulations" )
	NMModelListAddVar( "SimulationCounter", 0, "", "current simulation number" )
	
	NMModelListBlank()
	NMModelListAddVar( "SimulationTime", 1, NMXunits, "total simulation time" )
	NMModelListAddVar( "TimeStep", 1, NMXunits, "simulation time step" )
	NMModelListAddVar( "NumTimeSteps", 0, "", "number of time steps" )
	
	NMModelListBlank()
	NMModelListAddVar( "Temperature", 1, "", "number of simulation trials" )
	NMModelListAddVar( "gQ10", 1, "", "conductance Q10 factor" )
	NMModelListAddVar( "tauQ10", 1, "", "time constant Q10 factor" )
	
	if ( ( WhichListItem( "Ca", chanList ) >= 0 ) || ( StrSearch( chanList, "Ca_m", 0, 2 ) >= 0 ) )
		NMModelListBlank()
		NMModelListAddVar( "CaInside", 1, "mM", "initial internal [Ca]" )
		NMModelListAddVar( "CaOutside", 1, "mM", "initial internal [Ca]" )
	endif
	
	NMModelListBlank()
	NMModelListAddVar( "V0", 1, "mV", "initial membrane potential" )
	
	NMModelListBlank()
	NMModelListAddVar( "Diameter", 1, "um", "Model diameter" )
	NMModelListAddVar( "SurfaceArea", 1, "um^2", "Model surface area" )
	
	NMModelListBlank()
	NMModelListAddVar( "CmDensity", 1, "pF/um^2", "specific membrane capacitance" )
	NMModelListAddVar( "Cm", 0, "pF", "Model capacitance" )
	
	strswitch( NMModelStrGet( "ClampSelect" ) )
	
		case "Iclamp":
			NMModelListBlank()
			NMModelListAddVar( "iClampAmp", 1, "pA", "current-clamp amplitude" )
			NMModelListAddVar( "iClampAmpInc", 1, "pA", "current-clamp amplitude increment ( NumSimulations > 1 )" )
			NMModelListAddVar( "iClampOnset", 1, NMXunits, "current-clamp step onset" )
			NMModelListAddVar( "iClampDuration", 1, NMXunits, "current-clamp step duration" )
			break
			
		case "Vclamp":
			NMModelListBlank()
			NMModelListAddVar( "vClampAmp", 1, "mV", "voltage-clamp amplitude" )
			NMModelListAddVar( "vClampAmpInc", 1, "mV", "voltage-clamp amplitude increment ( NumSimulations > 1 )" )
			NMModelListAddVar( "vClampOnset", 1, NMXunits, "voltage-clamp step onset" )
			NMModelListAddVar( "vClampDuration", 1, NMXunits, "voltage-clamp step duration" )
			break
	
	endswitch
	
	NMModelListBlank()
	NMModelListAddVar( "gTonicGABADensity", 1, "nS/um^2", "tonic GABA conductance density" )
	NMModelListAddVar( "gTonicGABA", 0, "nS", "tonic GABA conductance" )
	
	NMModelListBlank()
	NMModelListAddStr( "gGABA_WavePrefix", 1, "nS", "gGABA wave prefix name" )
	NMModelListAddVar( "gGABA_NumWaves", 1, "", "number of located gGABA waveforms" )
	NMModelListAddVar( "eGABA", 1, "mV", "GABA reversal potential" )
	
	NMModelListBlank()
	NMModelListAddStr( "gAMPA_WavePrefix", 1, "nS", "gAMPA wave prefix name" )
	NMModelListAddVar( "gAMPA_NumWaves", 1, "", "number of located gAMPA waveforms" )
	NMModelListAddVar( "eAMPA", 1, "mV", "AMPA synaptic current reversal potential" )
	
	NMModelListBlank()
	NMModelListAddStr( "gNMDA_WavePrefix", 1, "nS", "gNMDA wave prefix name" )
	NMModelListAddVar( "gNMDA_NumWaves", 1, "", "number of located gNMDA waveforms" )
	NMModelListAddVar( "eNMDA", 1, "mV", "NMDA synaptic current reversal potential" )
	NMModelListAddStr( "gNMDA_BlockFxnList", 0, "", "gNMDA block function" )
	
	NMModelListBlank()
	NMModelListAddVar( "gLeakDensity", 1, "nS/um^2", "leak conductance density" )
	NMModelListAddVar( "gLeak", 0, "nS", "leak conductance" )
	NMModelListAddVar( "eLeak", 1, "mV", "leak reversal potential" )
	
	if ( StrSearch( chanList, "Na_", 0, 2 ) >= 0 )
		NMModelListBlank()
		NMModelListAddVar( "gNaDensity", 1, "nS/um^2", "Na conductance density" )
		NMModelListAddVar( "gNa", 0, "nS", "Na conductance" )
		NMModelListAddVar( "eNa", 1, "mV", "Na reversal potential" )
	endif
	
	if ( StrSearch( chanList, "NaR_", 0, 2 ) >= 0 )
		NMModelListBlank()
		NMModelListAddVar( "gNaRDensity", 1, "nS/um^2", "Na conductance density" )
		NMModelListAddVar( "gNaR", 0, "nS", "Na conductance" )
		NMModelListAddVar( "eNaR", 1, "mV", "Na reversal potential" )
	endif
	
	if ( StrSearch( chanList, "NaP_", 0, 2 ) >= 0 )
		NMModelListBlank()
		NMModelListAddVar( "gNaPDensity", 1, "nS/um^2", "persistent Na conductance density" )
		NMModelListAddVar( "gNaP", 0, "nS", "persistent Na conductance" )
		NMModelListAddVar( "eNaP", 1, "mV", "persistent Na reversal potential" )
	endif
	
	if ( StrSearch( chanList, "K_", 0, 2 ) >= 0 )
		NMModelListBlank()
		NMModelListAddVar( "gKDensity", 1, "nS/um^2", "K delayed rectifier conductance density" )
		NMModelListAddVar( "gK", 0, "nS", "K delayed rectifier conductance" )
		NMModelListAddVar( "eK", 1, "mV", "K delayed rectifier reversal potential" )
	endif
	
	if ( StrSearch( chanList, "KA_", 0, 2 ) >= 0 )
		NMModelListBlank()
		NMModelListAddVar( "gKADensity", 1, "nS/um^2", "K A-type conductance density" )
		NMModelListAddVar( "gKA", 0, "nS", "K A-type conductance" )
		NMModelListAddVar( "eKA", 1, "mV", "K A-type reversal potential" )
	endif
	
	if ( StrSearch( chanList, "KD_", 0, 2 ) >= 0 )
		NMModelListBlank()
		NMModelListAddVar( "gKDDensity", 1, "nS/um^2", "K low-threshold conductance density" )
		NMModelListAddVar( "gKD", 0, "nS", "K low-threshold conductance" )
		NMModelListAddVar( "eKD", 1, "mV", "K low-threshold reversal potential" )
	endif
	
	if ( StrSearch( chanList, "KCa_", 0, 2 ) >= 0 )
		NMModelListBlank()
		NMModelListAddVar( "gKCaDensity", 1, "nS/um^2", "Ca-activated K conductance density" )
		NMModelListAddVar( "gKCa", 0, "nS", "Ca-activated K conductance" )
		NMModelListAddVar( "eKCa", 1, "mV", "Ca-activated K reversal potential" )
	endif
	
	if ( StrSearch( chanList, "Kslow_", 0, 2 ) >= 0 )
		NMModelListBlank()
		NMModelListAddVar( "gKslowDensity", 1, "nS/um^2", "slow K conductance density" )
		NMModelListAddVar( "gKslow", 0, "nS", "slow K conductance" )
		NMModelListAddVar( "eKslow", 1, "mV", "slow K reversal potential" )
	endif
	
	if ( StrSearch( chanList, "Kir_", 0, 2 ) >= 0 )
		NMModelListBlank()
		NMModelListAddVar( "gKirDensity", 1, "nS/um^2", "K inward-rectifier conductance density" )
		NMModelListAddVar( "gKir", 0, "nS", "K inward-rectifier conductance" )
		NMModelListAddVar( "eKir", 1, "mV", "K inward-rectifier reversal potential" )
	endif
	
	if ( StrSearch( chanList, "H_", 0, 2 ) >= 0 )
		NMModelListBlank()
		NMModelListAddVar( "gHDensity", 1, "nS/um^2", "inward H conductance density" )
		NMModelListAddVar( "gH", 0, "nS", "inward H conductance" )
		NMModelListAddVar( "eH", 1, "mV", "inward H reversal potential" )
	endif
	
	if ( StrSearch( chanList, "Ca_", 0, 2 ) >= 0 )
		NMModelListBlank()
		NMModelListAddVar( "gCaDensity", 1, "nS/um^2", "Ca conductance density" )
		NMModelListAddVar( "gCa", 0, "nS", "Ca conductance" )
		NMModelListAddVar( "eCa", 1, "mV", "Ca reversal potential" )
	endif
	
	if ( StringMatch( modelSelect, "IAF" ) || StringMatch( modelSelect, "IAF_IK" ) )
	
		NMModelListBlank()
		NMModelListAddVar( "AP_Threshold", 1, "mV", "action potential threshold" )
		NMModelListAddVar( "AP_Peak", 1, "mV", "action potential peak" )
		NMModelListAddVar( "AP_Reset", 1, "mV", "action potential reset (AHP)" )
		NMModelListAddVar( "AP_Refrac", 1, NMXunits, "action potential refractory period" )
		
	endif
	
	if ( StringMatch( modelSelect, "IAF_AdEx" ) )
	
		NMModelListBlank()
		NMModelListAddVar( "AP_Threshold", 1, "mV", "effective action potential threshold" )
		NMModelListAddVar( "AP_ThreshSlope", 1, NMXunits, "threshold slope factor" )
		NMModelListAddVar( "AP_Peak", 1, "mV", "action potential peak" )
		NMModelListAddVar( "AP_Reset", 1, "mV", "action potential reset (AHP)" )
		NMModelListAddVar( "AP_Refrac", 1, NMXunits, "action potential refractory period" )
		
		NMModelListBlank()
		NMModelListAddVar( "W_Tau", 1, NMXunits, "adaptation time constant" )
		NMModelListAddVar( "W_A", 1, "nS", "adaptation conductance" )
		NMModelListAddVar( "W_B", 1, "nS", "spike-triggered adaptation conductance" )

	endif
	
	if ( StringMatch( modelSelect, "IAF_gLeak" ) )
	
		NMModelListBlank()
		NMModelListAddVar( "AP_Threshold", 1, "mV", "effective action potential threshold" )
		NMModelListAddVar( "AP_ThreshSlope", 1, NMXunits, "threshold slope factor" )
		NMModelListAddVar( "AP_Peak", 1, "mV", "action potential peak" )
		NMModelListAddVar( "AP_Reset", 1, "mV", "action potential reset (AHP)" )
		NMModelListAddVar( "AP_Refrac", 1, NMXunits, "action potential refractory period" )
	
		NMModelListBlank()
		NMModelListAddVar( "gLeak_gRest", 1, "nS", "" )
		NMModelListAddVar( "gLeak_gDepo", 1, "nS", "" )
		NMModelListAddVar( "gLeak_vHalf", 1, "mV", "" )
		NMModelListAddVar( "gLeak_vSlope", 1, "", "" )

	endif
	
End // NMModelListUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelListBlank()

	NMModelListAdd( "blank", "", 0, "", "" )
	
End // NMModelListBlank

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelListAddVar( varName, canedit, units, about )
	String varName
	Variable canedit // ( 0 ) no ( 1 ) yes
	String units
	String about
	
	Variable v = NMModelVarGet( varName )
	
	NMModelListAdd( varName, num2str( v ) , canedit, units, about )
	
End // NMModelListAddVar

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelListAddStr( strVarName, canedit, units, about )
	String strVarName
	Variable canedit // ( 0 ) no ( 1 ) yes
	String units
	String about
	
	NMModelListAdd( strVarName, NMModelStrGet( strVarName ), canedit, units, about )

End // NMModelListAddStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelListAdd( varName, valueStr, canedit, units, about ) // add to list wave for listbox control
	String varName
	String valueStr
	Variable canedit // ( 0 ) no ( 1 ) yes ( NaN ) dont change
	String units
	String about
	
	Variable icnt, nrows = 100
	String wName = "Params", ename = "ParamsEditable", df = NMModelDF()
	
	if ( !WaveExists( $df+wName ) )
		Make /T/N=( nrows, 4 ) $( df+wName ) = ""
	endif
	
	if ( !WaveExists( $df+ename ) )
		Make /N=( nrows, 4 ) $( df+ename ) = 0
	endif
	
	Wave /T Params = $df+wName
	Wave ParamsEditable = $df+ename
	
	nrows = DimSize( Params, 0 )
	
	if ( canedit == 1 )
		canedit = 3
	endif
	
	if ( StringMatch( varName, "blank" ) )
	
		varName = " "
	
	else
	
		for ( icnt = 0 ; icnt < nrows ; icnt += 1 )
		
			if ( StringMatch( Params[ icnt ][ 0 ], varName ) )
			
				Params[ icnt ][ 1 ] = valueStr
				
				if ( strlen( units ) > 0 )
					Params[ icnt ][ 2 ] = units
				endif
				
				if ( strlen( about ) > 0 )
					Params[ icnt ][ 3 ] = about
				endif
				
				if ( numtype( canedit ) == 0 )
					ParamsEditable[ icnt ][ 1 ] = canedit
				endif
				
				return 0
				
			endif
			
		endfor
	
	endif
	
	// no entry found, make a new entry
	
	for ( icnt = nrows - 1 ; icnt >= 0 ; icnt -= 1 )
		if ( strlen( Params[ icnt ][ 0 ] ) > 0 )
			break
		endif
	endfor
	
	icnt += 1
	
	if ( icnt < nrows )
	
		Params[ icnt ][ 0 ] = varName
		Params[ icnt ][ 1 ] = valueStr
		
		if ( strlen( units ) > 0 )
			Params[ icnt ][ 2 ] = units
		endif
		
		if ( strlen( about ) > 0 )
			Params[ icnt ][ 3 ] = about
		endif
		
		if ( numtype( canedit ) == 0 )
			ParamsEditable[ icnt ][ 1 ] = canedit
		endif
	
	endif

End // NMModelListAdd

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMModelParamList()

	Variable rcnt, nrows
	String pname, valueStr, pList = ""
	String listSep = ";"
	
	String pSkip = "WavePrefix;FirstSimulation;LastSimulation;NumSimulations;SimulationCounter;SimulationTime;TimeStep;NumTimeSteps;"

	String pdf = NMModelSubDF()

	if ( !WaveExists( $pdf+"Params" ) )
		return ""
	endif
	
	Wave /T params = $pdf+"Params"
	
	nrows = DimSize( params, 0 )
	
	for ( rcnt = 0 ; rcnt < nrows ; rcnt += 1 )
		
		pname = params[ rcnt ][ 0 ]
		
		if ( strlen( pname ) <= 1 )
			continue
		endif
		
		if ( WhichListItem( pname, pSkip ) >= 0 )
			continue
		endif
		
		valueStr = params[ rcnt ][ 1 ]
		
		pList += pname + "=" + valueStr + listSep
		
	endfor
	
	return pList

End // NMModelParamList

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Model Table Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMModelTableName()
	
	return NMFolderPrefix( "" ) + "Model_Params"
	
End // NMModelTableName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelEdit( [ history ] )
	Variable history // print function command to history ( 0 ) no ( 1 ) yes

	Variable found
	String wName, tname = "", ttl
	
	STRUCT Rect w
	
	NMOutputListsReset()
	
	if ( history )
		NMCommandHistory( "" )
	endif
	
	String df = NMModelDF()
	String pdf = NMModelSubDF()

	if ( WaveExists( $pdf+"Params" ) )
	
		tname = NMModelTableName()
		ttl = NMFolderListName( "" ) + " : Model Parameters"
		
		if ( WinType( tname ) > 0 )
			DoWindow /F $tname
		else
			NMWinCascadeRect( w )
			Edit /K=1/N=$tname/W=(w.left,w.top,w.right,w.bottom) $pdf+"Params" as ttl
		endif
		
		found = 1
		
	endif
	
	SetNMstr( NMDF + "OutputWinList", tName )
	
	NMHistoryOutputWindows()
	
	if ( !found )
		NMDoAlert( "Results have not been generated for Model simulation. Please select Run first." )
	endif
	
End // NMModelEdit

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Model Tab GUI Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelTabMake( force ) // create Model tab on NM panel
	Variable force
	
	Variable x0, y0, xinc, yinc, fs = NMPanelFsize
	String df = NMModelDF()
	
	if ( !IsCurrentNMTab( "Model" ) )
		return 0
	endif
	
	ControlInfo /W=$NMPanelName MD_ModelSelect
	
	if ( ( V_Flag != 0 ) && !force )
		NMModelTabUpdate()
		return 0 // Model tab controls exist
	endif
	
	if ( !DataFolderExists( df ) )
		return 0 // Model has not been initialized yet
	endif
	
	DoWindow /F $NMPanelName
	
	x0 = 10
	xinc = 160
	y0 = NMPanelTabY + 35
	yinc = 35
	
	PopupMenu MD_ModelSelect, pos={x0+190,y0}, bodywidth=200, fsize=fs, win=$NMPanelName
	PopupMenu MD_ModelSelect, value="Model Select;---;" + NMModelList(), proc=NMModelPopup, win=$NMPanelName
	
	ListBox MD_Inputs, pos={x0,y0+1*yinc}, size={280,280}, fsize=fs, listWave=$df+"Params", selWave=$df+"ParamsEditable", win=$NMPanelName
	ListBox MD_Inputs, mode=1, userColumnResize=1, proc=NMModelListbox, widths={110, 70, 55, 400}, win=$NMPanelName
	
	y0 += 280 + 35 + 15
	
	Button MD_Run, pos={x0+55,y0}, size={80,20}, proc=NMModelButton, title="Run", fsize=fs, win=$NMPanelName
	Button MD_Table, pos={x0+10,y0+1*yinc}, size={80,20}, proc=NMModelButton, title="Table", fsize=fs, win=$NMPanelName
	Button MD_Kinetics, pos={x0+100,y0+1*yinc}, size={80,20}, proc=NMModelButton, title="Kinetics", fsize=fs, win=$NMPanelName
	Button MD_Code, pos={x0+190,y0+1*yinc}, size={80,20}, proc=NMModelButton, title="Code", fsize=fs, win=$NMPanelName
	
	CheckBox MD_ClampSelect, title="Current Clamp", pos={x0+55+95,y0+2}, size={20,18}, value=1, win=$NMPanelName
	CheckBox MD_ClampSelect, fsize=fs, proc=NMModelCheckBox, win=$NMPanelName
	
	NMModelTabUpdate()
	
End // NMModelTabMake

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelTabUpdate()
	
	Variable modelSelectNum = NMModelSelectNum( "" )
	Variable clampSelectNum = NMModelClampSelectNum()
	
	String df = NMModelDF()
	String mList = NMModelList()
	
	NMModelListUpdate()
	
	ControlInfo /W=$NMPanelName MD_ModelSelect
	
	if ( V_Flag == 0 )
		return 0
	endif
	
	if ( ( numtype( modelSelectNum ) == 0 ) && ( modelSelectNum < ItemsInList( mList ) ) )
	
		PopupMenu MD_ModelSelect, win=$NMPanelName, value="Model Select;---;" + NMModelList(), mode=( 3 + modelSelectNum )
		
	else
	
		SetNMstr( df + "ModelSelect", "" ) // cannot find appropriate model
		
		PopupMenu MD_ModelSelect, win=$NMPanelName, value="Model Select;---;" + NMModelList(), mode=1
		
	endif
	
	if ( clampSelectNum == 0 )
		CheckBox MD_ClampSelect, title="Current Clamp  ", value=1, win=$NMPanelName
	else
		CheckBox MD_ClampSelect, title="Voltage Clamp  ", value=1, win=$NMPanelName
	endif
	
	ListBox MD_Inputs, win=$NMPanelName, listWave=$df+"Params", selWave=$df+"ParamsEditable"
	
End // NMModelTabUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	ctrlName = ReplaceString( "MD_", ctrlName, "" )
	
	strswitch( ctrlName )
	
		case "ModelSelect":
			NMModelSet( ModelSelect = popStr, history = 1 )
			break
	
		case "ClampSelect":
			NMModelSet( ClampSelect = popStr, history = 1 )
			break
	
	endswitch
	
End // NMModelPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelButton( ctrlname ): ButtonControl
	String ctrlname
	
	ctrlname = ReplaceString( "MD_", ctrlname, "" )
	
	strswitch( ctrlname )
	
		case "Code":
			return NMModelProcedureCode( history = 1 )
	
		case "Run":
			return NMModelRun( history = 1 )
			
		case "Table":
			return NMModelEdit( history = 1 )
			
		case "Kinetics":
			return NMModelKineticWavesAll( graph = 1, history = 1 )
	
	endswitch
	
End // NMModelButton

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelCheckBox(ctrlName, checked) : CheckBoxControl
	String ctrlName; Variable checked
	
	ctrlName = ReplaceString( "MD_", ctrlName, "" )
	
	strswitch( ctrlname )
	
		case "ClampSelect":
			return NMModelClampSelectToggle()
	
	endswitch

End // NMModelCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelListbox( ctrlName, row, col, event ) : ListboxControl
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
	
	Variable value
	String varName, valueStr, wName, df = NMModelDF()
	String thisfxn = GetRTStackInfo( 1 )
	
	if ( col != 1 )
		return 0 // nothing to do
	endif
	
	wName = df+"Params"
	
	if ( !WaveExists( $wName ) )
		NMDoAlert( thisfxn + " error: cannot find wave " + NMQuotes( wName ) )
		return -1
	endif
	
	Wave /T Params = $wName
	
	varName = Params[ row ]
	valueStr = Params[ row ][ 1 ]
	value = str2num( valueStr )
	
	strswitch( varName )
	
		case "":
		case " ":
			return 0 // nothing to do
			
		case "gNMDA_BlockFxnList":
			if ( ( event == 4 ) && ( col == 1 ) )
				valueStr = NMModelGnmdaBlockPrompt( valueStr )
				NMModelStrSet( varName, valueStr, history = 1 )
				ListBox MD_Inputs, win=$NMPanelName, selRow=-1
			endif
			break
			
		default:
		
			if ( event == 7 )
				if ( numtype( value ) == 0 )
					NMModelVarSet( varName, value, history = 1 )
				else
					NMModelStrSet( varName, valueStr, history = 1 )
				endif
			endif
			
	endswitch
	
	DoWindow /F $NMPanelName
	
	NMModelTabUpdate()
	
End // NMModelListbox

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Model Run Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelRun( [ history ] )
	Variable history // print function command to history ( 0 ) no ( 1 ) yes

	Variable icnt, timerRefNum, microSeconds
	String runFxn, ifxn, wList, wName, df = NMModelDF()
	
	if ( history )
		NMCommandHistory( "" )
	endif
	
	Variable /G MD_xinf, MD_taux
	
	String modelSelect = StrVarOrDefault( df + "ModelSelect", "" )
	
	Variable clampSelect = NMModelClampSelectNum()
	
	Variable FirstSimulation = NumVarOrDefault( df + "FirstSimulation", 0 )
	Variable LastSimulation = NumVarOrDefault( df + "LastSimulation", 0 )
	
	FirstSimulation = min( FirstSimulation, LastSimulation )
	LastSimulation = max( FirstSimulation, LastSimulation )
	
	Variable NumSimulations = LastSimulation - FirstSimulation + 1
	
	for ( icnt = 0 ; icnt < 10 ; icnt += 1 )
		microSeconds = stopMSTimer( icnt )
	endfor
	
	timerRefNum = startMSTimer
	
	if ( NMModelCleanUpWaves() < 0 )
		return -1 // error
	endif
	
	if ( NMModelVariablesInit() < 0 )
		return -1 // error
	endif
	
	if ( NMModelClampWavesUpdate() < 0 )
		return -1 // error
	endif
	
	runFxn = ""
	
	if ( clampSelect == 0 ) // Iclamp
	
		runFxn = modelSelect + "_RunIclamp"
	
		if ( exists( runFxn ) != 6 )
			runFxn = ""
		endif
		
	else
	
		runFxn = modelSelect + "_RunVclamp"
	
		if ( exists( runFxn ) != 6 )
			runFxn = ""
		endif
	
	endif
	
	NMProgressCall( -1, "Running Model Simulation #0" )
	
	for ( icnt = FirstSimulation ; icnt <= LastSimulation ; icnt += 1 )
	
		if ( NMProgressCall(-2, "Running Model Simulation #" + num2istr( icnt ) ) == 1 )
			break // cancel
		endif
		
		SetNMvar( df + "SimulationCounter", icnt )
		
		if ( clampSelect == 0 )
		
			if ( strlen( runFxn ) > 0 )
				Execute runFxn + "()" // specific RunIclamp function
			else
				NMModelRunIclamp() // generic RunIclamp function
			endif
		
		else
		
			if ( strlen( runFxn ) > 0 )
				Execute runFxn + "(" + num2str( icnt ) + ")" // specific RunVclamp function
			else
				NMModelRunVclamp() // generic RunVclamp function
			endif
			
		endif
		
		ifxn = modelSelect + "_Imem"
	
		if ( exists( ifxn ) == 6 )
			Execute ifxn + "(" + num2str( icnt ) + ")"
		endif
		
		NMModelWavesSave( icnt )
	
	endfor
	
	NMProgressKill()
	
	microSeconds = stopMSTimer(timerRefNum)
	
	NMHistory( "Model simulation time: " + num2str( microSeconds/1000000 ) + " seconds" )
	
	KillVariables /Z MD_xinf, MD_taux
	
	NMModelSave()
	NMModelTabUpdate()
	
	return 0

End // NMModelRun

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelRunIclamp()

	Variable icnt
	String wName, fxn, efxn, state, df = NMModelDF()
	String thisfxn = GetRTStackInfo( 1 )
	
	String modelSelect = StrVarOrDefault( df + "ModelSelect", "" )
	
	Variable simNum = NumVarOrDefault( df + "SimulationCounter", NaN )

	Variable simTime = NMModelSimTime( simNum )
	Variable dt = NumVarOrDefault( df + "TimeStep", NaN )
	Variable npnts = ( simTime / dt ) + 1
	
	Variable V0 = NumVarOrDefault( df + "V0", NaN )
	Variable CaInside = NumVarOrDefault( df + "CaInside", NaN ) // mM
	
	String stateList = StrVarOrDefault( df + "StateList", "" )
	Variable numStates = ItemsInList( stateList )
	
	Variable method = NumVarOrDefault( NMModelDF + "IntegrateODEMethod", 0 )
	
	Make /D/O/N=1 Model_PP = NAN // contains nothing
	
	wName = "Model_States_" + num2str( simNum )
	
	//npnts *= 100
	
	Make /O/N=( npnts, numStates ) $wName = NaN
	SetScale /P x 0, dt, $wName
	
	//Make /O/N=( npnts ) MD_FreeRunX
	
	Wave Model_States = $wName
	
	NVAR MD_xinf
	
	for ( icnt = 0 ; icnt < numStates ; icnt += 1 )
	
		state = StringFromList( icnt, stateList )
		
		SetDimLabel 1, icnt, $state, Model_States
		
		if ( StringMatch( state, "Vmem" ) )
		
			Model_States[ 0 ][ icnt ] = V0
			
		elseif ( StringMatch( state, "Ca" ) )
		
			Model_States[ 0 ][ icnt ] = CaInside
			
		else
		
			fxn = modelSelect + "_Kinetics"
			
			if ( exists( fxn ) != 6 )
				NMDoAlert( thisfxn + " error: cannot find function " + NMQuotes( fxn ) )
				return -1
			endif
			
			Execute fxn + "( " + NMQuotes( state ) + ", " + num2str( V0 ) + ", " + num2str( CaInside ) + ", " + NMQuotes( "SS" ) + " )"
			
			Model_States[ 0 ][ icnt ] = MD_xinf
			
		endif
		
	endfor
	
	fxn = modelSelect + "_DYDT"
	
	if ( exists( fxn ) != 6 )
		NMDoAlert( thisfxn + " error: cannot find function " + NMQuotes( fxn ) )
		return -1
	endif
	
	efxn = "IntegrateODE /M=" + num2str( method ) + "/U=1000000 " + fxn + ", Model_PP, " + wName
	
	//efxn = "IntegrateODE /E=1e-3 /U=1000000 /X=MD_FreeRunX /XRUN={ 0.01, 20 } " + fxn + ", Model_PP, " + wName
	
	Execute efxn
	
	if ( printIntegrateODE )
		NMHistory( efxn )
	endif
	
	KillWaves /Z Model_PP
	
	return 0

End // NMModelRunIclamp

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelRunVclamp()

	Variable icnt, ipnt, v, npnts, error
	String wName, state, fxn, df = NMModelDF()
	String thisfxn = GetRTStackInfo( 1 )
	
	Variable method = NumVarOrDefault( NMModelDF + "IntegrateODEMethod", 0 )
	
	SVAR modelSelect = $df + "ModelSelect"
	
	Variable V0 = NumVarOrDefault( df + "V0", NaN )
	
	NVAR simNum = $df + "SimulationCounter"
	NVAR dt = $df + "TimeStep"
	NVAR CaInside = $df + "CaInside"
	
	NVAR MD_xinf
	
	String stateList = StrVarOrDefault( df + "StateList", "" )
	Variable numStates = ItemsInList( stateList )
	
	wName = "Model_vClamp_" + num2str( simNum )
	
	if ( !WaveExists( $wName ) )
		NMDoAlert( thisfxn + " error: cannot find wave " + NMQuotes( wName ) )
		return -1 // not allowed
	endif
	
	Wave Model_vClamp = $wName
	
	npnts = numpnts( Model_vClamp )
	
	if ( npnts == 0 )
		return -1
	endif
	
	v = Model_vClamp[ 0 ]
	
	Make /D/O/N=1 Model_PP = NAN // contains nothing
	
	wName = "Model_States_" + num2str( simNum )
	
	Make /O/N=( npnts, numStates ) $wName = NaN
	SetScale /P x 0, dt, $wName
	
	Wave Model_States = $wName
	
	ipnt = 0
	
	for ( icnt = 0 ; icnt < numStates ; icnt += 1 )
	
		state = StringFromList( icnt, stateList )
		
		SetDimLabel 1, icnt, $state, Model_States
		
		if ( StringMatch( state, "Vmem" ) )
		
			Model_States[ ipnt ][ icnt ] = v
			
		elseif ( StringMatch( state, "Ca" ) )
		
			Model_States[ ipnt ][ icnt ] = CaInside
			
		else
		
			fxn = modelSelect + "_Kinetics"
			
			if ( exists( fxn ) != 6 )
				NMDoAlert( thisfxn + " error: cannot find function " + NMQuotes( fxn ) )
				return -1
			endif
			
			Execute fxn + "( " + NMQuotes( state ) + ", " + num2str( v ) + ", " + num2str( CaInside ) + ", " + NMQuotes( "SS" ) + " )"
			
			Model_States[ ipnt ][ icnt ] = MD_xinf
			
		endif
		
	endfor
	
	fxn = modelSelect + "_DYDT"
	
	if ( exists( fxn ) != 6 )
		NMDoAlert( thisfxn + " error: cannot find function " + NMQuotes( fxn ) )
		return -1
	endif
	
	Execute "IntegrateODE /M=" + num2str( method ) + " " + fxn + ", Model_PP, " + wName
	
	//fxn = modelSelect + "_Imem"
	
	//if ( exists( fxn ) != 6 )
	//	return -1
	//endif
	
	//Execute fxn + "()"
	
	KillWaves /Z Model_PP

End // NMModelRunVclamp

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelSimTime( simCounter )
	Variable simCounter

	String wPrefix, wName, df = NMModelDF()
	
	Variable simTime = NumVarOrDefault( df + "SimulationTime", NaN )
	
	if ( ( numtype( simTime ) == 0 ) && ( simTime > 0 ) )
		return simTime
	endif
		
	wPrefix = StrVarOrDefault( df + "gAMPA_WavePrefix", "" )
	
	if ( strlen( wPrefix ) > 0 )
	
		wName = wPrefix + num2str( simCounter )
			
		if ( WaveExists( $wName ) )
			return rightx( $wName )
		endif
	
	endif
	
	wPrefix = StrVarOrDefault( df + "gNMDA_WavePrefix", "" )
	
	if ( strlen( wPrefix ) > 0 )
	
		wName = wPrefix + num2str( simCounter )
			
		if ( WaveExists( $wName ) )
			return rightx( $wName )
		endif
	
	endif
	
	wPrefix = StrVarOrDefault( df + "gGABA_WavePrefix", "" )
	
	if ( strlen( wPrefix ) > 0 )
	
		wName = wPrefix + num2str( simCounter )
			
		if ( WaveExists( $wName ) )
			return rightx( $wName )
		endif
	
	endif
	
	wName = "Model_iClamp_" + num2str( simCounter )
		
	if ( WaveExists( $wName ) )
		return rightx( $wName )
	endif
	
	return NaN
	
End // NMModelSimTime

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelCleanUpWaves()

	Variable icnt, kill
	String wName, wList, newPrefix, df = NMModelDF()
	
	Variable overwrite = NumVarOrDefault( NMModelDF + "OverwriteMode", 1 )
	
	String wavePrefix = StrVarOrDefault( df + "WavePrefix", "Sim_" )
	
	wList = WaveList( wavePrefix + "*", ";", "" )
	
	if ( ItemsInList( wList ) > 0 )
	
		if ( overwrite )
		
			kill = 1
		
		else
		
			//DoAlert /T="Model Clean Up" 2, "Simulation waves with prefix " + NMQuotes( wavePrefix ) + " already exist. Do you want to delete them?"
			DoAlert 2, "Simulation waves with prefix " + NMQuotes( wavePrefix ) + " already exist. Do you want to delete them?"
			
			if ( V_flag == 1 ) // yes
			
				kill = 1
			
			elseif ( V_flag == 2 ) // no
			
				newPrefix = wavePrefix
		
				Prompt newPrefix, "please enter a different wave prefix:"
				DoPrompt "Model Output Wave Prefix", newPrefix
			 	
			 	if ( V_flag == 1 )
					return -1 // cancel
				endif
				
				if ( StringMatch( newPrefix, wavePrefix ) )
					//DoAlert /T="Model Clean Up" 0, "Error: you entered the same wave prefix. Aborting simulation."
					DoAlert 0, "Error: you entered the same wave prefix. Aborting simulation."
					return -1
				else
					SetNMstr( df + "WavePrefix", newPrefix )
				endif
			
			else
			
				return 0 // cancel
				
			endif
		
		endif

		if ( kill )
			
			for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
				wName = StringFromList( icnt, wList )
				KillWaves /Z $wName
			endfor
			
		endif
	
	endif
	
	wList = WaveList( "Model_States_*", ";", "" )
		
	for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
		wName = StringFromList( icnt, wList )
		KillWaves /Z $wName
	endfor

	wList = WaveList( "Model_iClamp_*", ";", "" )
		
	for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
		wName = StringFromList( icnt, wList )
		KillWaves /Z $wName
	endfor
	
	wList = WaveList( "Model_vClamp_*", ";", "" )
		
	for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
		wName = StringFromList( icnt, wList )
		KillWaves /Z $wName
	endfor
	
	return 0

End // NMModelCleanUpWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelKineticWavesAll( [ graph, history ] )
	Variable graph // plot waves in graph ( 0 ) no ( 1 ) yes
	Variable history // print function command to history ( 0 ) no ( 1 ) yes

	Variable icnt, wcnt, numWaves
	String wavePrefix, stateName, wList, wName, df = NMModelDF()
	String vlist = ""
	
	if ( ParamIsDefault( graph ) )
		graph = 1
	else
		vlist = NMCmdNumOptional( "graph", graph, vlist, integer = 1 )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif

	String modelSelect = StrVarOrDefault( df + "ModelSelect", "" )
	
	String stateList = StrVarOrDefault( df + "stateList", "" )
	
	if ( strlen( modelSelect ) == 0 )
		return -1
	endif
	
	if ( ItemsInList( stateList ) == 0 )
		return -1
	endif
	
	wavePrefix = NMModelStr2( modelSelect, "Prefix" )
	
	if ( strlen( wavePrefix ) == 0 )
		wavePrefix = modelSelect + "_"
	endif
	
	for ( icnt = 0 ; icnt < ItemsInList( stateList ) ; icnt += 1 )
	
		stateName = StringFromList( icnt, stateList )
		
		if ( StringMatch( stateName, "Vmem" ) )
			continue
		endif
		
		if ( StringMatch( stateName, "Ca" ) )
			continue
		endif
		
		NMModelKineticWaves( stateName = stateName, wavePrefix = wavePrefix )
	
	endfor
	
	NMSet( wavePrefixNoPrompt = wavePrefix )
	
	wList = NMChanWaveList( -1 )
	numWaves = ItemsInList( wList )
	
	if ( numWaves == 0 )
		return 0
	endif
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( StringMatch( wName, "*_inf" ) )
			NMGroupsSet( waveNum = wcnt , group = 0 )
		elseif ( StringMatch( wName, "*_tau" ) )
			NMGroupsSet( waveNum = wcnt , group = 1 )
		endif
		
	endfor
	
	if ( graph )
		NMWaveSelect( "All Groups" )
		NMMainGraph( color = "rainbow" )
	else
		NMWaveSelect( "All" )
	endif

End // NMModelKineticWavesAll

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelKineticWaves( [ model, stateName, CaInside, temperature, vBgn, vEnd, vStep, wavePrefix ] )
	String model // e.g. "HodgkinHuxley" or "IAF"
	String stateName // e.g. "Na_m"
	Variable CaInside // mM ( NaN for global variable )
	Variable temperature // C ( NaN for global variable )
	Variable vBgn // mV
	Variable vEnd // mV
	Variable vStep // mV
	String wavePrefix // wave prefix name
	
	Variable vpnts, saveTemp = NaN
	String xstr, tstr, stateList, df = NMModelDF()
	
	Variable /G MD_xinf, MD_taux
	
	if ( ParamIsDefault( model ) )
		model = StrVarOrDefault( df + "ModelSelect", "" )
	endif
	
	if ( strlen( model ) == 0 )
		return -1
	endif
	
	if ( ParamIsDefault( stateName ) )
		stateList = NMModelStr2( model, "StateList" )
		stateName = StringFromList( 0, stateList )
	endif
	
	if ( strlen( stateName ) == 0 )
		return -1
	endif
	
	if ( ParamIsDefault( CaInside ) )
		CaInside = NumVarOrDefault( df + "CaInside", 0 )
	endif
	
	if ( ParamIsDefault( temperature ) )
	
		saveTemp = NumVarOrDefault( df + "Temperature", NaN )
	
		SetNMvar( df + "Temperature", temperature )
	
	endif
	
	if ( ParamIsDefault( vBgn ) )
		vBgn = -100
	endif
	
	if ( ParamIsDefault( vEnd ) )
		vEnd = 100
	endif
	
	if ( ParamIsDefault( vStep ) )
		vStep = 1
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = model + "_"
	endif
	
	vpnts = 1 + ( vEnd - vBgn ) / Vstep
	
	String xName = wavePrefix + stateName + "_inf"
	String tName = wavePrefix + stateName + "_tau"
	
	Make /O/N=( vpnts ) MD_TempWave = NaN
	SetScale /P x vBgn, vStep, MD_TempWave
	
	xstr = "MD_TempWave = " + model + "_Kinetics( " + NMQuotes( stateName ) + ", x, " + num2str( CaInside ) + ", " + NMQuotes( "SS" ) + " )"
	
	//Print xstr
	Execute xstr
	
	Duplicate /O MD_TempWave $xName
	
	tstr = "MD_TempWave = " + model + "_Kinetics( " + NMQuotes( stateName ) + ", x, " + num2str( CaInside ) + ", " + NMQuotes( "Tau" ) + " )"
	
	Execute tstr
	
	Duplicate /O MD_TempWave $tName
	
	if ( numtype( saveTemp ) == 0 )
		SetNMvar( df + "Temperature", saveTemp )
	endif
	
	KillWaves /Z MD_TempWave

End // NMModelKineticWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelClampWavesUpdate() // update simulation waves

	Variable icnt, pnt1, pnt2, simTime, npnts
	String wList, wPrefix, wName, df = NMModelDF()
	String thisfxn = GetRTStackInfo( 1 )
	
	Variable clampSelect = NMModelClampSelectNum()
	
	Variable FirstSimulation = NumVarOrDefault( df + "FirstSimulation", 0 )
	Variable LastSimulation = NumVarOrDefault( df + "LastSimulation", 0 )
	
	FirstSimulation = min( FirstSimulation, LastSimulation )
	LastSimulation = max( FirstSimulation, LastSimulation )
	
	Variable NumSimulations = LastSimulation - FirstSimulation + 1

	Variable iClampAmp = NumVarOrDefault( df + "iClampAmp", 0 ) // pA
	Variable iClampAmpInc = NumVarOrDefault( df + "iClampAmpInc", 0 ) // pA
	Variable iClampOnset = NumVarOrDefault( df + "iClampOnset", 20 ) // ms
	Variable iClampDuration = NumVarOrDefault( df + "iClampDuration", 100 ) // ms
	
	Variable vClampAmp = NumVarOrDefault( df + "vClampAmp", 0 ) // mV
	Variable vClampAmpInc = NumVarOrDefault( df + "vClampAmpInc", 0 ) // mV
	Variable vClampOnset = NumVarOrDefault( df + "vClampOnset", 20 ) // ms
	Variable vClampDuration = NumVarOrDefault( df + "vClampDuration", 100 ) // ms
	
	Variable dt = NumVarOrDefault( df + "TimeStep", 0.01 )
	
	Variable V0 = NumVarOrDefault( df + "V0", -75 )
	
	wPrefix = StrVarOrDefault( df + "gAMPA_WavePrefix", "" )
	
	if ( strlen( wPrefix ) > 0 )
	
		wList = WaveList( wPrefix + "*", ";", "" )
		
		for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
		
			wName = StringFromList( icnt, wList )
			
			if ( deltax( $wName ) - dt > 0.001 )
				NMDoAlert( thisfxn + " error: gAMPA waveform " + NMQuotes( wName ) + " has wrong time step: " + num2str( deltax( $wName ) - dt ) + " ms" )
				return -1
			endif
		
		endfor
		
		icnt = ItemsInList( wList )
		
		if ( icnt > 0 )
			NMHistory( "Located " + num2str( icnt ) + " gAMPA waveforms." )
		endif
	
	endif
	
	wPrefix = StrVarOrDefault( df + "gNMDA_WavePrefix", "" )
	
	if ( strlen( wPrefix ) > 0 )
	
		wList = WaveList( wPrefix + "*", ";", "" )
	
		for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
		
			wName = StringFromList( icnt, wList )
			
			if ( deltax( $wName ) - dt > 0.001 )
				NMDoAlert( thisfxn + " error: gNMDA waveform " + NMQuotes( wName ) + " has wrong time step: " + num2str( deltax( $wName ) - dt ) + " ms" )
				return -1
			endif
		
		endfor
		
		icnt = ItemsInList( wList )
		
		if ( icnt > 0 )
			NMHistory( "Located " + num2str( icnt ) + " gNMDA waveforms." )
		endif
		
	endif
	
	wPrefix = StrVarOrDefault( df + "gGABA_WavePrefix", "" )
	
	if ( strlen( wPrefix ) > 0 )
	
		wList = WaveList( wPrefix + "*", ";", "" )
	
		for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
		
			wName = StringFromList( icnt, wList )
			
			if ( deltax( $wName ) - dt > 0.001 )
				NMDoAlert( thisfxn + " error: gGABA waveform " + NMQuotes( wName ) + " has wrong time step: " + num2str( deltax( $wName ) - dt ) + " ms" )
				return -1
			endif
		
		endfor
		
		icnt = ItemsInList( wList )
		
		if ( icnt > 0 )
			NMHistory( "Located " + num2str( icnt ) + " gGABA waveforms." )
		endif
		
	endif
	
	if ( clampSelect == 0 )
			
		if ( ( numtype( iClampAmp ) > 0 ) || ( numtype( iClampAmpInc ) > 0 ) )
			return 0
		endif
		
		if ( NumSimulations == 1 )
		
			if ( iClampAmp == 0 )
				return 0
			endif
		
		elseif ( NumSimulations > 1 )
		
			if ( ( iClampAmp == 0 ) && ( iClampAmpInc == 0 ) )
				return 0
			endif
		
		else
			return 0
		endif
			
	else
			
		if ( ( numtype( vClampAmp ) > 0 ) || ( numtype( vClampAmpInc ) > 0 ) )
			return 0
		endif
	
	endif
	
	for ( icnt = FirstSimulation ; icnt <= LastSimulation ; icnt += 1 )
	
		if ( clampSelect == 0 )
	
			wName = "Model_iClamp_" + num2str( icnt )
			
			simTime = NMModelSimTime( icnt )
			npnts = ( simTime / dt ) + 1
	
			Make /O/N=( npnts ) $wName = 0
			SetScale /P x 0, dt, $wName
			
			Wave wtemp = $wName
			
			pnt1 = x2pnt( wtemp, iClampOnset )
			pnt2 = x2pnt( wtemp, iClampOnset + iClampDuration ) - 1
			
			pnt1 = max( pnt1, 0 )
			pnt2 = min( pnt2, numpnts( wtemp ) - 1 )
			
			wtemp[ pnt1, pnt2 ] = iClampAmp + icnt * iClampAmpInc
		
		else
		
			wName = "Model_vClamp_" + num2str( icnt )
			
			simTime = NMModelSimTime( icnt )
			npnts = ( simTime / dt ) + 1
	
			Make /O/N=( npnts ) $wName = V0
			SetScale /P x 0, dt, $wName
			
			Wave wtemp = $wName
			
			pnt1 = x2pnt( wtemp, vClampOnset )
			pnt2 = x2pnt( wtemp, vClampOnset + vClampDuration ) - 1
			
			pnt1 = max( pnt1, 0 )
			pnt2 = min( pnt2, numpnts( wtemp ) - 1 )
			
			wtemp[ pnt1, pnt2 ] = V0 + vClampAmp + icnt * vClampAmpInc
		
		endif
	
	endfor
	
	return 0

End // NMModelClampWavesUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelWavesSave( simNum )
	Variable simNum

	Variable jcnt, kcnt, dt, npnts, chanNum, numStates
	String wPrefix, wName, wName2, dLabel, pList, df = NMModelDF()
	String thisfxn = GetRTStackInfo( 1 )
	String firstPrefix = ""
	
	Variable saveAllStates = 1 // ( 0 ) no ( 1 ) yes
	
	Variable clampSelect = NMModelClampSelectNum()
	
	String modelSelect = NMModelStrGet( "ModelSelect" )
	
	String wavePrefix = StrVarOrDefault( df + "WavePrefix", "Sim_" )
	
	chanNum = 0

	wName = "Model_States_" + num2str( simNum )

	if ( !WaveExists( $wName ) )
		NMDoAlert( thisfxn + " error: cannot find wave " + NMQuotes( wName ) )
		return -1
	endif
	
	Wave Model_States = $wName
	
	npnts = DimSize( Model_States, 0 )
	dt = DimDelta( Model_States, 0 )
	
	numStates = DimSize( Model_States, 1 )
	
	if ( !saveAllStates )
		numStates = 1 // save only first state
	endif
	
	pList = NMModelParamList()
	
	for ( jcnt = 0 ; jcnt < numStates ; jcnt += 1 )
	
		dLabel = GetDimLabel( Model_States, 1, jcnt )
		
		if ( jcnt == 0 )
			firstPrefix = wavePrefix + dLabel
		endif
		
		wName2 = wavePrefix + dLabel + "_" + ChanNum2Char( chanNum ) + num2str( simNum )
		Make /O/N=( npnts ) $wName2 = NaN
		SetScale /P x 0, dt, $wName2
		
		NMNoteType( wName2, "NMModel_" + modelSelect, NMXunits, NMModelStateLabel( dLabel ), "_FXN_" ) 
		
		Wave wtemp = $wName2
		
		Note wtemp, pList
		
		for ( kcnt = 0 ; kcnt < npnts ; kcnt += 1 )
			wtemp[ kcnt ] = Model_States[ kcnt ][ jcnt ]
		endfor
	
	endfor
	
	NMSet( wavePrefixNoPrompt = firstPrefix )
	
	return 0

End // NMModelWavesSave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMModelStateLabel( stateName )
	String stateName
	
	strswitch( stateName )
	
		case "Vmem":
			return "Vmem ( mV )"
			
		case "Imem":
			return "Imem ( pA )" 
			
		case "Ca":
			return "[Ca] ( mM )"
	
	endswitch
	
	return stateName
	
End // NMModelStateLabel

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelIsum( clampSelect, tt, v, gTC )
	Variable clampSelect // ( 0 ) Iclamp ( 1 ) Vclamp
	Variable tt
	Variable v
	Variable gTC
	
	Variable timePoint = NaN
	Variable iClampValue, iLeak, iAMPA, iNMDA, iGABA, iTonicGABA
	String wPrefix, wName, df = NMModelDF()
	
	NVAR simNum = $df + "SimulationCounter"
	
	NVAR TimeStep = $df + "TimeStep"
	
	NVAR gLeak = $df + "gLeak"
	NVAR eLeak = $df + "eLeak"
	
	NVAR gTonicGABA = $df + "gTonicGABA"
	NVAR eGABA = $df + "eGABA"
	
	NVAR eAMPA = $df + "eAMPA"
	NVAR eNMDA = $df + "eNMDA"
	
	if ( gLeak > 0 )
		iLeak = gTC * gLeak * ( v - eLeak )
	endif
	
	if ( gTonicGABA > 0 )
		iTonicGABA = gTC * gTonicGABA * ( v - eGABA )
	endif
	
	timePoint = tt / TimeStep
	
	wName = "Model_iClamp_" + num2str( simNum )
	
	if ( ( clampSelect == 0 ) && WaveExists( $wName ) )
	
		Wave Model_iClamp = $wName
		
		if ( ( timePoint >= 0 ) && ( timePoint < numpnts( Model_iClamp ) ) )
			iClampValue = Model_iClamp[ timePoint ]
		endif
	
	endif
	
	wPrefix = StrVarOrDefault( df + "gAMPA_WavePrefix", "" )
	
	if ( strlen( wPrefix ) > 0 )

		wName = wPrefix + num2str( simNum )
		
		if ( WaveExists( $wName ) )
		
			Wave gAMPA = $wName
			
			if ( ( timePoint >= 0 ) && ( timePoint < numpnts( gAMPA ) ) )
				iAMPA = gAMPA[ timePoint ] * ( v - eAMPA )
			endif
			
		endif
	
	endif
	
	wPrefix = StrVarOrDefault( df + "gNMDA_WavePrefix", "" )
	
	if ( strlen( wPrefix ) > 0 )

		wName = wPrefix + num2str( simNum )
	
		if ( WaveExists( $wName ) )
		
			Wave gNMDA = $wName
			
			if ( ( timePoint >= 0 ) && ( timePoint < numpnts( gNMDA ) ) )
				iNMDA = gNMDA[ timePoint ] * NMModelNMDAblock( v ) * ( v - eNMDA )
			endif
			
		endif
		
	endif
	
	wPrefix = StrVarOrDefault( df + "gGABA_WavePrefix", "" )
	
	if ( strlen( wPrefix ) > 0 )

		wName = wPrefix + num2str( simNum )
	
		if ( WaveExists( $wName ) )
		
			Wave gGABA = $wName
			
			eGABA = NumVarOrDefault( df + "eGABA", NaN )
			
			if ( ( timePoint >= 0 ) && ( timePoint < numpnts( gGABA ) ) )
				iGABA = gGABA[ timePoint ] * ( v - eGABA )
			endif
			
		endif
		
	endif
	
	return iLeak + iAMPA + iNMDA + iGABA + iTonicGABA - iClampValue

End // NMModelIsum

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelNMDAblock( v )

	Variable v // membrane potential
	
	String df = NMModelDF()
	
	String fxnList = StrVarOrDefault( df + "gNMDA_BlockFxnList", "" )
	// first item in fxnList should be function name, followed by optional parameter list
	// e.g. "Boltzmann;Vhalf=-12.8;Vslope=22.4;" or "GC_Rothman2009" or "GC_Schwartz2012"
	
	Variable vHalf, vSlope // Boltzmann function
	
	String fxn = StringFromList( 0, fxnList ) 
	
	strswitch( fxn )
		
		case "Boltzmann":
		
			vHalf = str2num( StringByKey( "Vhalf", fxnList, "=", ";" ) )
			vSlope = str2num( StringByKey( "Vslope", fxnList, "=", ";" ) )
			
			return 1 / ( 1 + exp( -( v - vHalf ) / vSlope ) )
			
		case "GC_Rothman2009": // Boltzmann
			
			vHalf = -12.8
			vSlope = 22.4
			
			return 1 / ( 1 + exp( -( v - vHalf ) / vSlope ) )
			
		case "GC_Schwartz2012":
			
			//Variable w0 = 4.0171e-13 // conductance
			//Variable w1 = 2.404 // reversal potential
			Variable w2 = 38.427
			Variable w3 = 28.357
			Variable w4 = -119.51
			Variable w5 = -45.895
			Variable w6 = 84.784
		
			Variable e1 = exp( ( v - w4 ) / w2 ) + exp( -( v - w5 ) / w3 )
			Variable e2 = e1 + exp( -( v - w6 ) / w2 )
			
			return e1 / e2
			
		// USERS CAN ADD THEIR OWN BLOCK FUNCTIONS HERE...
	
	endswitch
	
	return NaN
	
End // NMModelNMDAblock

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelVclamp( simNum, tt )
	Variable simNum
	Variable tt
	
	Variable timePoint
	
	String df = NMModelDF()
	
	NVAR TimeStep = $df + "TimeStep"
	
	timePoint = tt / TimeStep

	String wName = "Model_vClamp_" + num2str( simNum )
	
	if ( !WaveExists( $wName ) || ( timePoint < 0 ) || ( timePoint >= numpnts( $wName ) ) )
		return 0
	endif
	
	Wave Model_vClamp = $wName
	
	return Model_vClamp[ timePoint ]
	
End // NMModelVclamp

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Misc Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelProcedureCode( [ history ] )
	Variable history // print function command to history ( 0 ) no ( 1 ) yes

	String fxn, df = NMModelDF()
	String thisfxn = GetRTStackInfo( 1 )
	
	if ( history )
		NMCommandHistory( "" )
	endif

	String procedureName = "NM_Model.ipf"
	
	String modelSelect = StrVarOrDefault( df + "ModelSelect", "" )
	
	fxn = modelSelect + "_Init"
	
	if ( exists( fxn ) != 6 )
		NMDoAlert( thisfxn + " error: cannot find function " + NMQuotes( fxn ) )
		return -1
	endif
	
	//Execute fxn + "()"
	
	Execute "SetIgorOption IndependentModuleDev = 1"

	DisplayProcedure fxn
	
	return 0

End // NMModelProcedureCode

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelQ10( recordingTemp, temperature, Q10 )
	Variable recordingTemp, temperature, Q10

	return Q10 ^ ( ( temperature - recordingTemp ) / 10 )

End // NMModelQ10

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelQ10g( recordingTemp )
	Variable recordingTemp
	
	String df = NMModelDF()
	
	NVAR temperature = $df + "Temperature"
	NVAR gQ10 = $df + "gQ10"

	return gQ10 ^ ( ( temperature - recordingTemp ) / 10 )

End // NMModelQ10

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelQ10tau( recordingTemp )
	Variable recordingTemp
	
	String df = NMModelDF()
	
	NVAR temperature = $df + "Temperature"
	NVAR tauQ10 = $df + "tauQ10"

	return tauQ10 ^ ( ( temperature - recordingTemp ) / 10 )

End // NMModelQ10tau

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelExp( v, x, y )
	Variable v, x, y
	
	return exp( ( v - x ) / y )
	
End // NMModelExp

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelLinoid( v, x, y )
	Variable v, x, y
	
	Variable expValue = ( v - x ) / y
	
	if ( abs( expValue ) < 1e-6 )
		//print "discontinuity"
		return y * ( 1 + ( v - x ) / ( 2 * y ) )
	else
		return ( v - x ) / ( 1 - exp( -( v - x ) / y ) )
	endif
	
End // NMModelLinoid

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModelSigmoid( v, x, y )
	Variable v, x, y
	
	return 1 / ( 1 + exp ( -( v - x ) / y ) )
	
End // NMModelSigmoid

//****************************************************************
//****************************************************************
//****************************************************************

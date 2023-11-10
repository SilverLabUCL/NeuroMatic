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
//	Demo Tab
//	
//	How to create your own tab from this code:
//
//	1. Come up with a short name for your tab like "FRAP" and a unique prefix identifier like "FR_".
//	2. Open a new procedure file ( Windows/New/Procedure ) and name it something like "NMFRAP".
//	3. Copy the code in this procedure and paste it into the new procedure file.
//	4. Using Igor edit command ( Edit/Replace ) replace all occurences of "Demo" with "FRAP".
//	5. Replace all occurences of "DM_" with "FR_".
//	6. Add your tab to the NeuroMatic panel ( NeuroMatic/Tabs/Add ).
//	7. Replace Function0, Function1, etc, with your own functions.
//	8. Add buttons, popup menus, checkboxes, etc, in function NMFRAPMake. Their names should begin with your tab prefix "FR_".
//	9. SAVE your procedure file to disk ( File/Save Procedure As... ). If you save in your own Igor Procedures folder
//	( Me/Documents/WaveMetrics/Igor Pro 6 User Files/Igor Procedures ) then your procedure file will automatically be loaded
//	once you start Igor.
//
//****************************************************************
//****************************************************************

Static StrConstant tabName = "Demo"
Static StrConstant tabPrefix = "DM_"

//****************************************************************
//****************************************************************

Function /S NMTabPrefix_Demo() // this function allows NM to determine tab name and prefix

	return tabPrefix

End // NMTabPrefix_Demo

//****************************************************************
//****************************************************************

Function /S NMDemoDF()

	return NMPackageDF( tabName )

End // NMDemoDF

//****************************************************************
//****************************************************************

Function NMDemoTab( enable ) // called by ChangeTab
	Variable enable // ( 0 ) disable ( 1 ) enable tab
	
	if ( enable == 1 )
		CheckNMPackage( tabName, 1 ) // declare globals if necessary
		NMDemoMake() // create tab controls if necessary
		NMChannelGraphDisable( channel = -2, all = 0 )
		NMDemoAuto()
	endif

End // NMDemoTab

//****************************************************************
//****************************************************************

Function NMDemoTabKill( what ) // called by KillTab
	String what
	
	String df = NMDemoDF()

	// KillTab will automatically kill objects that begin with appropriate prefix.
	// Place any other things to kill here.
	
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

End // NMDemoTabKill

//****************************************************************
//****************************************************************

Function NMDemoCheck() // declare global variables

	String df = NMDemoDF()
	
	if ( DataFolderExists( df ) == 0 )
		return -1 // folder doesnt exist
	endif
	
	CheckNMvar( df+"DumVar", 11 ) // create variable ( also see NM_Configurations.ipf )
	
	CheckNMstr( df+"DumStr", "Anything" ) // create string
	
	CheckNMwave( df+"DumWave", 5, 22 ) // numeric wave
	
	CheckNMtwave( df+"DumTxtWave", 5, "Anything" ) // text wave
	
	return 0
	
End // NMDemoCheck

//****************************************************************
//****************************************************************

Function NMDemoAuto()

// put a function here that runs each time CurrentWave number has been incremented 
// see "NMSpikeAuto" for example

End // NMDemoAuto

//****************************************************************
//****************************************************************

Function NMDemoConfigs()

	NMConfigVar( tabName, "DumVar", 11, "dummy variable", "units" )
	NMConfigStr( tabName, "DumStr", "Anything", "dummy text variable", "units" )
	
	NMConfigWave( tabName, "DumWave", 5, 22, "dummy wave" )
	NMConfigTWave( tabName, "DumTxtWave", 5, "anything", "dummy text wave" )

End // NMDemoConfigs
	
//****************************************************************
//****************************************************************

Function NMDemoMake() // create controls that will begin with appropriate prefix

	Variable x0 = 50, xinc, yinc = 60, fs = NMPanelFsize
	Variable y0 = NMPanelTabY + 80
	
	String df = NMDemoDF()

	ControlInfo /W=$NMPanelName $"DM_Function0" // check first in a list of controls
	
	if ( V_Flag != 0 )
		return 0 // tab controls exist, return here
	endif

	DoWindow /F $NMPanelName
	
	Button DM_Function0, pos={x0,y0+0*yinc}, title="Your button can go here", size={200,20}, proc=NMDemoButton, fsize=fs
	Button DM_Demo, pos={x0,y0+1*yinc}, title="Demo Function", size={200,20}, proc=NMDemoButton, fsize=fs
	Button DM_Function1, pos={x0,y0+2*yinc}, title="My Function 1", size={200,20}, proc=NMDemoButton, fsize=fs
	Button DM_Function2, pos={x0,y0+3*yinc}, title="My Function 2", size={200,20}, proc=NMDemoButton
	
	SetVariable DM_Function3, title="my variable", pos={x0,y0+4*yinc}, size={200,50}, limits={-inf,inf,1}
	SetVariable DM_Function3, value=$( df+"DumVar" ), proc=NMDemoSetVariable, fsize=fs

End // NMDemoMake

//****************************************************************
//****************************************************************

Function NMDemoButton( ctrlName ) : ButtonControl
	String ctrlName
	
	String fxn = ReplaceString( tabPrefix, ctrlName, "" )
	
	NMDemoCall( fxn, "" )
	
End // NMDemoButton

//****************************************************************
//****************************************************************

Function NMDemoSetVariable( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	String fxn = ReplaceString( tabPrefix, ctrlName, "" )
	
	NMDemoCall( fxn, varStr )
	
End // NMDemoSetVariable

//****************************************************************
//****************************************************************

Function NMDemoCall( fxn, select )
	String fxn // function name
	String select // parameter string variable
	
	Variable snum = str2num( select ) // parameter variable number
	
	strswitch( fxn )
	
		case "Demo":
			NMDemoLoopThruChanWaves()
			return 0
	
		case "Function0":
			return NMDemoFunction0( history = 1 )
			
		case "Function1":
			//return NMDemoFunction1( history = 1 )
			zCall_NMDemoLoop()
			return 0
			
		case "Function2":
			return NMDemoFunction2( history = 1 )

	endswitch
	
End // NMDemoCall

//****************************************************************
//****************************************************************

Function NMDemoFunction0( [ history ] )
	Variable history
	
	if ( history )
		NMCommandHistory( "" ) // print function command to history
	endif

	String df = NMDemoDF()
	
	Variable dumVar = NumVarOrDefault( df+"DumVar", 0 )
	String dumStr = StrVarOrDefault( df+"DumStr", "" )
	
	Wave dumWave = $( df+"DumWave" )
	Wave /T dumTxtWave = $( df+"DumTxtWave" )
	
	NMDoAlert( "Your macro can be run here." )

End // NMDemoFunction0

//****************************************************************
//****************************************************************

Function NMDemoFunction1( [ history ] )
	Variable history

	if ( history )
		NMCommandHistory( "" ) // print function command to history
	endif

	//Print "My Function 1"

End // NMDemoFunction1

//****************************************************************
//****************************************************************

Function NMDemoFunction2( [ history ] )
	Variable history

	if ( history )
		NMCommandHistory( "" ) // print function command to history
	endif

	//Print "My Function 2"

End // NMDemoFunction2

//****************************************************************
//****************************************************************

Function NMDemoFunction3Call( select )
	String select
	
	Variable dumvar

	return NMDemoFunction3( select, dumvar )

End // NMDemoFunction3Call

//****************************************************************
//****************************************************************

Function NMDemoFunction3( select, dumvar [ history ] )
	String select
	Variable dumvar
	Variable history
	
	String vlist = ""
	
	if ( history )
		vlist = NMCmdStr( select, vlist )
		vlist = NMCmdNum( dumvar, vlist )
		NMCommandHistory( vlist ) // print function command to history
	endif

	Print "You entered : " + select

End // NMDemoFunction3

//****************************************************************
//****************************************************************

Static Function /S zCall_NMDemoLoop()

	String promptStr = NMPromptStr( "NM Demo Loop" )

	String df = NMDemoDF()
	
	Variable transforms = 1 // use channel filter and transform
	
	Variable dumVar = NumVarOrDefault( df + "DumVar", 11 )
	String dumStr = StrVarOrDefault( df + "DumStr", "nothing" )
	
	Prompt dumVar, "my variable:"
	Prompt dumStr, "my string:"
	
	DoPrompt promptStr, dumVar, dumStr
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMvar( df + "DumVar", dumVar )
	SetNMstr( df + "DumStr", dumStr )
	
	return NMDemoLoop(  transforms =  transforms, myVariable = dumVar, myString = dumStr , history = 1 )

End // zCall_NMDemoLoop

//****************************************************************
//****************************************************************

Function /S NMDemoLoop( [ folderList, wavePrefixList, chanSelectList, waveSelectList, history, deprecation,  transforms, myVariable, myString ] )
	String folderList // NM folder list ( e.g. "nmFolder0;nmFolder1;" or "All" )
	String wavePrefixList // wave prefix list ( e.g. "Record;Wave;" )
	String chanSelectList // channel select list ( e.g. "A;B;" or "All" )
	String waveSelectList // wave select list ( e.g. "All" or "Set1;Set2;" or "All Sets" )
	Variable history // print function call command to history
	Variable deprecation // print deprecation alert
	
	// >>>>> begin my function parameters >>>>>
	
	Variable transforms // use channel Filter/Transform on input data waves ( 0 ) no ( 1 ) yes
	Variable myVariable // dummy variable
	String myString // dummy string
	
	STRUCT NMLoopExecStruct nm
	NMLoopExecStructNull( nm )
	
	if ( !ParamIsDefault(  transforms ) )
		NMLoopExecVarAdd( " transforms",  transforms, nm )
	endif
	
	if ( !ParamIsDefault( myVariable ) )
		NMLoopExecVarAdd( "myVariable", myVariable, nm )
	endif
	
	if ( !ParamIsDefault( myString ) )
		NMLoopExecStrAdd( "myString", myString, nm )
	endif
	
	// <<<<< end my function parameters <<<<<
	
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
	
	return NMLoopExecute( nm, history, deprecation ) // loop thru lists and call NMDemoLoop2

End // NMDemoLoop

//****************************************************************
//****************************************************************

Function /S NMDemoLoop2( [ folder, wavePrefix, chanNum, waveSelect,  transforms, myVariable, myString ] )
	String folder // e.g. "nmFolder0"
	String wavePrefix // wave prefix ( e.g. "Record" )
	Variable chanNum // channel number
	String waveSelect // wave select ( e.g. "All" or "Set1" )
	
	Variable  transforms // use channel filter and transforms ( 0 ) no ( 1 ) yes
	Variable myVariable // dummy variable
	String myString // dummy string
	
	STRUCT NMParams nm
	NMParamsNull( nm )
		
	Variable wcnt, numWaves, returnVal
	String wName, tName, tName2 = "U_WaveTemp2", fxn = "Demo Loop"
	
	if ( ParamIsDefault(  transforms ) )
		 transforms = 1
	endif
	
	if ( ParamIsDefault( myVariable ) )
		myVariable = NaN
	endif
	
	if ( ParamIsDefault( myString ) )
		myString = "nothing" // be sure to give optional string parameters a value if default ( e.g. "" or "not specified" )
	endif
	
	NMParamVarAdd( " transforms",  transforms, nm )
	NMParamVarAdd( "myVariable", myVariable, nm )
	NMParamStrAdd( "myString", myString, nm )
	
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
	
	numWaves = ItemsInList( nm.wList )
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 ) // loop thru waves
	
		if ( NMProgress( wcnt, numWaves, "Demo : Ch " + ChanNum2Char( chanNum ) + " : Wave #"  + num2istr( wcnt ) ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		if ( !WaveExists( $nm.folder + wName ) )
			continue
		endif
		
		if (  transforms )
		
			if ( strlen( nm.xWave ) > 0 )
				returnVal = ChanWaveMake( chanNum, nm.folder + wName, nm.folder + tName2, prefixFolder = nm.prefixFolder, xWave = nm.folder + nm.xWave )
			else
				returnVal = ChanWaveMake( chanNum, nm.folder + wName, nm.folder + tName2, prefixFolder = nm.prefixFolder, xWave = "" )
			endif
			
			if ( returnVal < 0 )
				continue // error, could not make channel wave
			endif
			
			tName = tName2 // use output of ChanWaveMake
			
		else
		
			tName = nm.folder + wName // use raw data
			
		endif
		
		//Print tName
		
		Wave waveTemp = $tName // create local reference to wave
		
		if ( strlen( nm.xWave ) > 0 )
			Wave xtemp = $nm.folder + nm.xWave // create local reference to x-wave
		endif
		
		// >>>>> Put Your Code Starting Here >>>>>
		
		// tempWave *= myVariable // do something to the wave
		
		NMWait( 100 ) // simulate computation with time delay for demo
		
		//NMLoopWaveNote( wName, paramList ) // save function name and parameters to wave notes
		
		// <<<<< Put Your Code Ending Here <<<<<
		
		nm.successList += wName + ";"
		
	endfor
	
	KillWaves /Z $nm.folder + tName2 // delete output of ChanWaveMake
	
	NMParamsComputeFailures( nm )
	NMLoopHistory( nm )
	
	SetNMstr( NMDF + "OutputWaveList", nm.successList )
	
	return nm.successList
	
End // NMDemoLoop2

//****************************************************************
//****************************************************************

Function /S NMDemoLoop3( nm [ history ] )
	STRUCT NMParams &nm
	Variable history
	
	Variable wcnt, numWaves
	String wName
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Performing demo analysis..." ) == 1 )
			break // cancel
		endif
	
		wName = StringFromList( wcnt, nm.wList )
		
		Wave wtemp = $nm.folder + wName // create local reference to wave
		
		if ( strlen( nm.xWave ) > 0 )
			Wave xtemp = $nm.folder + nm.xWave // create local reference to x-wave
		endif
	
		// do something to wave here
		
		nm.successList += wName + ";"
		
	endfor
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif

	return nm.successList
	
End // NMDemoLoop3

//****************************************************************
//****************************************************************

Function /S NMDemoLoopThruChanWaves() // example function that loops thru all currently selected channels and waves
	
	Variable icnt, ccnt, wcnt, numWaves, cancel
	String wName, waveSelectList, cList, wList = ""
	
	Variable numChannels = NMNumChannels()
	
	String waveSelect = NMWaveSelectGet()
	String saveWaveSelect = waveSelect
	String allList = NMWaveSelectAllList()
	Variable allListItems = ItemsInList( allList )
	
	Variable printNames = 0
	Variable addDelay = 250 // ms
	
	if ( numChannels <= 0 )
		return ""
	endif
	
	for ( icnt = 0; icnt < max( allListItems, 1 ); icnt += 1 ) // loop thru wave selections ( e.g. "All" or "Set1" or "All Groups" )
		
		if ( allListItems > 0 )
			waveSelect = StringFromList( icnt, allList )
			NMWaveSelect( waveSelect )
		endif
		
		if ( NMNumActiveWaves() <= 0 )
			continue
		endif
	
		for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 ) // loop thru channels
		
			if ( NMChanSelected( ccnt ) != 1 )
				continue // channel is not selected
			endif
			
			waveSelectList = NMWaveSelectList( ccnt )
			
			numWaves = ItemsInList( waveSelectList )
			
			if ( numWaves == 0 )
				continue
			endif
			
			cList = ""
			
			for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 ) // loop thru selected waves
			
				//if ( NMProgressTimer( wcnt, numWaves, "My Demo Function..." ) == 1 ) // update progress display only for long computations
				if ( NMProgress( wcnt, numWaves, "Demo Function Wave Count: " + num2istr( wcnt ) ) == 1 ) // update progress display
					cancel = 1
					break // cancel wave loop
				endif
			
				wName = StringFromList( wcnt, waveSelectList )
				
				if ( WaveExists( $wName ) == 0 )
					continue // wave does not exist... go to next wave
				endif
				
				Wave tempWave = $wName // create local reference to wave
				
				// PutYourCodeStartingHere
				// PutYourCodeStartingHere
				// PutYourCodeStartingHere
				
				// tempWave *= 1 // do something to the wave
				
				if ( PrintNames == 1 )
					Print "Demo Loop wave: " + wName
				endif
				
				if ( addDelay > 0 )
					NMWait( addDelay ) // as demo, simulate computation with time delay
				endif
				
				// PutYourCodeEndingHere
				// PutYourCodeEndingHere
				// PutYourCodeEndingHere
				
				cList = AddListItem( wName, cList, ";", inf )
				
			endfor
			
			wList += cList
			
			NMMainHistory( "Demo Loop", ccnt, cList, 0 ) // print results to history for this channel
			
			if ( cancel == 1 )
				break // cancel channel loop
			endif
			
		endfor
		
		if ( cancel == 1 )
			break // cancel wave select loop
		endif
		
	endfor
	
	if ( allListItems > 0 )
		NMWaveSelect( saveWaveSelect ) // back to original wave select
	endif
	
	return wList // return list of waves that successfully made it thru the loop

End // NMDemoLoopThruChanWaves

//****************************************************************
//****************************************************************

Function /S NMDemoLoopThruFolders()

	Variable numFolders, fcnt
	String folderName

	String folderList = NMDataFolderList()
	String saveFolder = CurrentNMFolder( 0 )
	
	numFolders = ItemsInList( folderList )
	
	for ( fcnt = 0 ; fcnt < numFolders ; fcnt += 1 )
	
		folderName = StringFromList( fcnt, folderList )
		
		NMFolderChange( folderName )
		
		// PutYourCodeHere
	
	endfor
	
	if ( StringMatch( folderName, saveFolder ) == 0 )
		NMFolderChange( saveFolder )
	endif
	
	return folderList

End // NMDemoLoopThruFolders

//****************************************************************
//****************************************************************

Function NMDemoAnalysisCall()

	String txt = "This demo function creates folder nmDemo with waves filled with noise and performs a simple spike detection on the waves. "
	
	txt += "Do you want to continue?"

	DoAlert /T="NM Demo Analysis" 1, txt
		
	if ( V_flag == 1 )
		return NMDemoAnalysis()
	endif
	
End // NMDemoAnalysisCall

//****************************************************************
//****************************************************************

Function NMDemoAnalysis()

	If ( IsNMFolder( "nmDemo", "NMData" ) )
		DoAlert /T="NM Alert" 0, "Folder nmDemo already exists. To run this demo function please close nmDemo first."
		return -1
	endif
	
	NMFolderNew( "nmDemo", history = 1 )
	
	If ( IsNMFolder( "nmDemo", "NMData" ) == 0 )
		return -1
	endif

	NMMainMake( wavePrefixList="Record;", chanSelectList="A;", numWaves=10, waveLength=100, dx=0.2, noiseStdv=1, xLabel="ms", history = 1 )
	NMSet( wavePrefix="Record" )
	
	NMSetsSet( setList="Set1", value=1, fromWave=0, toWave=5, skipWaves=0, clearFirst=1, history = 1 )
	NMSet( waveSelect="Set1", history = 1 )
	
	NMSet( tab="Spike", history = 1 )
	NMSpikeSet( threshold=1.5, history = 1 )
	NMSpikeRasterComputeAll( chanSelectList="A", waveSelectList="Set1", displayMode=1, delay=0, plot=1, table=0 )
	NMSpikePSTH( xbgn=0, xend=100, binSize=5, yUnits="Spikes/bin", history = 1 )
	
End // NMDemoAnalysis

//****************************************************************
//****************************************************************

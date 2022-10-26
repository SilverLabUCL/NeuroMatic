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
//****************************************************************

Constant NMStimWaveLength = 100 // ms // default
Constant NMStimSampleInterval = 0.2 // ms
Constant NMStimInterStimTime = 900 // ms

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMStim(dp, sname) // declare stim global variables
	String dp // path
	String sname // stim name
	
	String sdf = LastPathColon(dp, 1) + sname + ":"
	String cdf = NMClampDF
	
	// default values
	
	Variable nStimWaves = 1
	Variable stimRate = 1000 / ( NMStimWaveLength + NMStimInterStimTime ) // Hz
	Variable nReps = 1
	Variable interRepT = 0
	Variable repRate = 1000 / ( interRepT + nStimWaves * ( NMStimWaveLength + NMStimInterStimTime ) )
	Variable totalTime = nReps / repRate
	
	if (DataFolderExists(sdf) == 0)
		NewDataFolder $RemoveEnding( sdf, ":" ) // make new stim folder
	endif
	
	CheckNMstr(sdf+"FileType", "NMStim") // type of data file
	
	CheckNMvar(sdf+"Version", NMVersionNum() )
	CheckNMstr(sdf+"VersionStr", NMVersionStr )
	
	CheckNMstr(sdf+"StimTag", "") // stimulus file suffix tag
	
	CheckNMstr(sdf+"WavePrefix", NMStrGet( "WavePrefix" )) // wave prefix name
	
	CheckNMvar(sdf+"AcqMode", 0) // acquisition mode (0) epic precise (1) continuous (2) episodic (3) epic triggered (4) continuous triggered
	
	CheckNMvar(sdf+"CurrentChan", 0) // channel select
	
	CheckNMvar(sdf+"NumStimWaves", nStimWaves) // stim waves per channel
	CheckNMvar(sdf+"WaveLength", NMStimWaveLength) // ms
	
	CheckNMvar(sdf+"SampleInterval", NMStimSampleInterval) // ms
	CheckNMvar(sdf+"SamplesPerWave", floor( NMStimWaveLength / NMStimSampleInterval ))
	
	CheckNMvar(sdf+"InterStimTime", NMStimInterStimTime) // time between stim waves (ms)
	CheckNMvar(sdf+"StimRate", stimRate) // Hz
	
	CheckNMvar(sdf+"NumStimReps", nReps) // repitions of stimulus
	CheckNMvar(sdf+"TotalTime", totalTime) // seconds
	
	CheckNMvar(sdf+"InterRepTime", interRepT) // time between stimulus repititions (ms)
	CheckNMvar(sdf+"RepRate", repRate) // Hz
	
	CheckNMvar(sdf+"NumPulseVar", 12) // number of variables in pulse waves
	
	CheckNMstr(sdf+"InterStimFxnList", "") // during acquisition run function list
	CheckNMstr(sdf+"PreStimFxnList", "") // pre-acquisition run function list
	CheckNMstr(sdf+"PostStimFxnList", "") // post-acquisition run function list
	
	// IO Channels
	
	CheckNMvar(sdf+"UseGlobalBoardConfigs", 1) // use global board configs (0) no (1) yes
	
	NMStimBoardWavesCheckAll(sdf)
	
	return 0
	
End // CheckNMStim

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStimWavePrefix(sdf) // return stim wave prefix name if it exists
	String sdf
	
	String wPrefix
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return ""
	endif
	
	wPrefix = StrVarOrDefault(sdf+"WavePrefix", StrVarOrDefault(NMClampDF+"DataPrefix", NMStrGet( "WavePrefix" )))
	
	if ( strlen( wPrefix ) == 0 )
		wPrefix = NMStrGet( "WavePrefix" )
	endif
	
	if ( strlen( wPrefix ) == 0 )
		wPrefix = "Record"
	endif

	return wPrefix
	
End // NMStimWavePrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimWaveLength( sdf, waveNum )
	String sdf
	Variable waveNum
	
	Variable icnt
	String wname
	
	sdf = CheckStimDF( sdf )
	
	Variable pgOff = NumVarOrDefault( sdf + "PulseGenOff", 0 )
	
	if ( pgOff )
	
		for (icnt = 0; icnt < 50; icnt += 1)
		
			//wname = sdf + "MyDAC_" + num2istr(icnt) + "_" + num2istr(waveNum)
			wname = sdf + "DAC_" + num2istr(icnt) + "_" + num2istr(waveNum) // changed to "DAC" to allow RandomOrder
			
			if ( WaveExists( $wname ) )
				return rightx( $wname )
			endif
		
		endfor
		
	endif
	
	return NumVarOrDefault( sdf + "WaveLength", NaN )

End // NMStimWaveLength

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimWavePoints( sdf, waveNum )
	String sdf
	Variable waveNum
	
	Variable icnt, wLength, sInterval
	String wname
	
	sdf = CheckStimDF( sdf ) 
	
	Variable pgOff = NumVarOrDefault( sdf + "PulseGenOff", 0 )
	
	if ( pgOff )
	
		for ( icnt = 0; icnt < 50; icnt += 1 )
		
			//wname = sdf + "MyDAC_" + num2istr(icnt) + "_" + num2istr(waveNum)
			wname = sdf + "DAC_" + num2istr( icnt ) + "_" + num2istr( waveNum ) // changed to "DAC" to allow RandomOrder
			
			if ( WaveExists($wname) )
				return numpnts( $wname )
			endif
		
		endfor
		
	endif
	
	sInterval = NumVarOrDefault( sdf + "SampleInterval", NaN )
	wLength = NumVarOrDefault( sdf + "WaveLength", NaN )
	
	return floor( wLength / sInterval )

End // NMStimWavePoints

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimNumStimWaves(sdf)
	String sdf
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return -1
	endif
	
	return NumVarOrDefault(sdf+"NumStimWaves", 1)
	
End // NMStimNumStimWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimNumStimReps(sdf)
	String sdf
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return -1
	endif
	
	return NumVarOrDefault(sdf+"NumStimReps", 0)
	
End // NMStimNumStimReps

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimNumWavesTotal(sdf)
	String sdf
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return -1
	endif

	return NumVarOrDefault(sdf+"NumStimWaves", 1) * NumVarOrDefault(sdf+"NumStimReps", 0)

End // NMStimNumWavesTotal

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimCurrentChanSet(sdf, chan)
	String sdf
	Variable chan
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return -1
	endif
	
	SetNMvar(sdf+"CurrentChan", chan)
	
	return chan
	
End // NMStimCurrentChanSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimAcqMode(sdf)
	String sdf
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return -1
	endif
	
	return NumVarOrDefault( sdf + "AcqMode", 0 )
	
End // NMStimAcqMode

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimAcqModeSet(sdf, select)
	String sdf
	String select
	
	Variable mode
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return -1
	endif
	
	strswitch(select)
		case "epic precise":
			mode = 0
			break
		case "continuous":
			mode = 1
			break
		case "episodic":
			mode = 2
			break
		case "triggered":
		case "epic triggered":
			mode = 3
			break
		case "continuous triggered":
			mode = 4
			break
		default:
			return -1
	endswitch
	
	SetNMvar(sdf+"AcqMode", mode)
	
	return mode
	
End // NMStimAcqModeSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimTauCheck( sdf ) // check/update time variables
	String sdf

	sdf = CheckStimDF( sdf )
	
	if ( strlen( sdf ) == 0 )
		return -1
	endif
	
	Variable acqMode = NumVarOrDefault( sdf + "AcqMode", NaN )
	
	Variable nStimWaves = NumVarOrDefault( sdf + "NumStimWaves", NaN )
	Variable wLength = NumVarOrDefault( sdf + "WaveLength", NaN )
	
	Variable sInterval = NumVarOrDefault( sdf + "SampleInterval", NaN )
	
	Variable interStimT = NumVarOrDefault( sdf + "InterStimTime", NaN )
	Variable stimRate //= NumVarOrDefault( sdf + "StimRate", NaN )
	
	Variable nStimReps = NumVarOrDefault( sdf + "NumStimReps", NaN )
	
	Variable interRepT = NumVarOrDefault( sdf + "InterRepTime", NaN )
	Variable repRate //= NumVarOrDefault( sdf + "RepRate", NaN )
	
	String acqBoard = StrVarOrDefault( NMClampDF + "AcqBoard", "" )
	
	switch( acqMode )
		case 0: // epic precise
		case 2: // episodic
		case 3: // episodic triggered
		case 1: // continuous
		case 4: // continuous triggered
			break
		default:
			ClampError( 1, "Unknown acquisition mode: " + num2str( acqMode ) )
			SetNMvar( sdf + "AcqMode", 0 )
	endswitch
	
	if ( ( numtype( nStimWaves ) > 0 ) || ( nStimWaves <= 0 ) )
		ClampError( 1, "bad number of waves: " + num2str( nStimWaves ) )
		nStimWaves = 1
		SetNMvar( "NumStimWaves", 1 )
	endif
	
	SetNMvar( "NumGrps", round( nStimWaves ) )
	
	if ( ( numtype( wLength ) > 0 ) || ( wLength <= 0 ) )
		ClampError( 1, "bad wave length: " + num2str( wLength ) )
		wLength = NMStimWaveLength
		SetNMvar( "WaveLength", NMStimWaveLength )
	endif
	
	if ( ( numtype( sInterval ) > 0 ) || ( sInterval <= 0 ) )
		ClampError( 1, "bad sample interval: " + num2str( sInterval ) )
		sInterval = NMStimSampleInterval
	endif
	
	//sInterval = ( floor( 1e6 * sInterval ) / 1e6 ) // round off
	SetNMvar( sdf + "SampleInterval", sInterval )
	
	SetNMvar( sdf + "SamplesPerWave", floor( wLength / sInterval ) )
	
	switch( acqMode )
	
		case 0: // epic precise
		case 2: // episodic
		case 3: // episodic triggered
		
			if ( ( numtype( interStimT ) > 0 ) || ( interStimT < 0 ) )
				ClampError( 1, "bad stimulus interlude time: " + num2str( interStimT ) )
				interStimT = NMStimInterStimTime
				SetNMvar( sdf + "InterStimTime", NMStimInterStimTime )
			endif
		
			if ( interStimT == 0 )
				ClampError( 1, "InterStimTime = 0 not allowed with episodic acquisition." )
				interStimT = NMStimInterStimTime
				SetNMvar( sdf + "InterStimTime", NMStimInterStimTime )
			endif
			
			break
			
		case 1: // continuous
		case 4: // continuous triggered
		
			if ( StringMatch( acqBoard, "NIDAQ" ) && ( nStimWaves > 1 ) )
				ClampError( 1, "only one stimulus wave is allowed with continuous acquisition." )
				nStimWaves = 1
				SetNMvar( "NumStimWaves", 1 )
			endif
			
			interStimT = 0 // no time between episodes
			SetNMvar( sdf + "InterStimTime", 0 )
	
	endswitch
	
	stimRate = 1000 / ( wLength + interStimT ) // Hz
	SetNMvar( sdf + "StimRate", stimRate )
	
	if ( ( numtype( nStimReps ) > 0 ) || ( nStimReps <= 0 ) )
		ClampError( 1, "bad number of stimulus repetitions: " + num2str( nStimReps ) )
		nStimReps = 1
		SetNMvar( sdf + "NumStimReps", 1 )
	endif
	
	if ( ( numtype( interRepT ) > 0 ) || ( interRepT < 0 ) )
		ClampError( 1, "bad repetition interlude: " + num2str( interRepT ) )
		interRepT = 0
		SetNMvar( sdf + "InterRepTime", 0 )
	endif
	
	repRate = 1000 / ( interRepT + nStimWaves * ( wLength + interStimT ) ) // Hz
	SetNMvar( sdf + "RepRate", repRate )
	SetNMvar( sdf + "TotalTime", ( nStimReps / repRate ) )
	
	return 0

End // NMStimTauCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimDACUpSamplingCall( sdf )
	String sdf // stim data folder bath
	
	Variable upsamples = NumVarOrDefault( sdf + "DACUpsamples", 1 )
	
	if ( !NMStimDACUpSamplingOK() )
		return -1
	endif
	
	Prompt upsamples, "integer scale factor for rate increase (1 for no increase):"
	DoPrompt "DAC Upsampling ( n > 1 )", upsamples

	if (V_flag == 1)
		return 0
	endif
	
	if ( ( numtype( upsamples ) > 0 ) || ( upsamples < 1 ) )
		upsamples = 1
	endif
	
	return NMStimDACUpSampling( sdf, upsamples )

End // NMStimDACUpSamplingCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimDACUpSampling( sdf, upsamples )
	String sdf // stim data folder bath
	Variable upsamples // integer factor: ( 1 ) off, ( > 1 ) upsampling
	
	if ( !NMStimDACUpSamplingOK() )
		return -1
	endif
	
	if ( ( numtype( upsamples ) > 0 ) || ( upsamples < 1 ) )
		upsamples = 1
	endif
	
	SetNMvar( sdf + "DACUpsamples", round( upsamples ) )
	
	StimWavesCheck( sdf, 1 )
	
	return 0
	
End // NMStimDACUpSampling

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimIntervalSet( sdf, intvl )
	String sdf // stim data folder bath
	Variable intvl
	
	sdf = CheckStimDF(sdf)
	
	if ( strlen( sdf ) == 0 )
		return -1
	endif
	
	if ( ( numtype( intvl ) > 0 ) || ( intvl <= 0 ) )
		return -1
	endif
	
	//intvl = ( floor( 1e6 * intvl ) / 1e6 ) // round off
	
	SetNMvar( sdf + "SampleInterval", intvl )
	
	return intvl
	
End // NMStimIntervalSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimIntervalSet_DEPRECATED(sdf, boardNum, boardDriver, intvl)
	String sdf // stim data folder bath
	Variable boardNum, boardDriver, intvl
	
	Variable bcnt, driverIntvl
	String varName, boards, cdf = NMClampDF
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return -1
	endif
	
	driverIntvl = NumVarOrDefault(sdf+"SampleInterval", NMStimSampleInterval)
	boards = StrVarOrDefault(cdf+"BoardList", "")
	
	varName = sdf + "SampleInterval_" + num2istr(boardNum)
	
	if (boardNum == boardDriver)
		SetNMvar(sdf+"SampleInterval", intvl)
	elseif (intvl == driverIntvl)
		KillVariables /Z $varName // no longer need variable
	else
		SetNMvar(varName, intvl) // create new sample interval variable
	endif
	
	return intvl
	
End // NMStimIntervalSet_DEPRECATED

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStimWavePrefixSet(sdf, prefix)
	String sdf
	String prefix
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return ""
	endif
	
	prefix = NMCheckStringName(prefix)
	
	if ( strlen( prefix ) == 0 )
		prefix = NMStrGet( "WavePrefix" )
	endif
	
	if ( strlen( prefix ) == 0 )
		prefix = "Record"
	endif
	
	SetNMstr(sdf+"WavePrefix", prefix)
	
	return prefix
	
End // NMStimWavePrefixSet(

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStimTagSet(sdf, suffix)
	String sdf
	String suffix
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return ""
	endif
	
	suffix = NMCheckStringName(suffix)
	
	SetNMstr(sdf+"StimTag", suffix)
	
	return suffix
	
End // NMStimTagSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStimTag(sdf)
	String sdf
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return ""
	endif
	
	return StrVarOrDefault(sdf+"StimTag", "")

End // NMStimTag

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStimChainEdit(sdf)
	String sdf
	Variable npnts = -1

	String tName = StimCurrent() + "Chain"
	String tableTitle = StimCurrent() + " Acquisition Table"
	
	STRUCT Rect w
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return ""
	endif
	
	if (WaveExists($sdf+"Stim_Name") == 0)
		npnts = 5
	endif
	
	CheckNMtwave(sdf+"Stim_Name", npnts, "")
	CheckNMwave(sdf+"Stim_Wait", npnts, 0)
	
	if (WinType(tName) == 0)
		NMWinCascadeRect( w )
		Edit /K=1/N=$tName/W=(w.left,w.top,w.right,w.bottom) $(sdf+"Stim_Name"), $(sdf+"Stim_Wait") as tableTitle
	else
		DoWindow /F $tName
	endif
	
	return tName

End // NMStimChainEdit

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimChainOn(sdf)
	String sdf
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return -1
	endif

	return BinaryCheck(NumVarOrDefault(sdf+"AcqStimChain", 0))
	
End // NMStimChainOn

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimChainSet(sdf, on)
	String sdf
	Variable on // (0) off (1) on
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return -1
	endif
	
	on = BinaryCheck(on)
	
	SetNMvar(sdf+"AcqStimChain", on)
	
	if (on == 1)
		NMStimChainEdit(sdf)
	endif
	
	return on
	
End // NMStimChainSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimUseGlobalBoardConfigsChk(sdf)
	String sdf

	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return -1
	endif
	
	if ( exists( sdf+"UseGlobalBoardConfigs" ) == 2 )
		return 0 // variable already exists
	endif
	
	Variable on = 1
	
	if (WaveExists($sdf+"ADCname") == 1)
	
		on += 1
	
		Prompt on, "please select which configs to use:", popup "old configs inside stim folder;globals configs displayed on Clamp Configs Tab;"
		DoPrompt "Encountered Old Stim Protocol : " + StimCurrent(), on
		
		if (V_flag == 1)
			on = 1
		endif
		
		on -= 1
		
	endif
	
	SetNMvar(sdf+"UseGlobalBoardConfigs", on)
	
	NMStimBoardConfigsUpdateAll(sdf)
	
	return on

End // NMStimUseGlobalBoardConfigsChk

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimUseGlobalBoardConfigs(sdf)
	String sdf

	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return -1
	endif
	
	Variable on = NumVarOrDefault(sdf+"UseGlobalBoardConfigs", 0)
	
	if (WaveExists($sdf+"ADCname") == 0)
		on = 1
	endif
	
	return BinaryCheck(on)

End // NMStimUseGlobalBoardConfigs

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimUseGlobalBoardConfigsSet(sdf, on)
	String sdf
	Variable on // (0) off (1) on
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return -1
	endif
	
	on = BinaryCheck(on)
	
	if ((on == 0) && (WaveExists($sdf+"ADCname") == 0))
		DoAlert 0, "Alert: " + NMQuotes( StimCurrent() ) + " does not contain its own board configs. You must use the global board configs which you can create using the Board tab."
		on = 1
	endif
	
	SetNMvar(sdf+"UseGlobalBoardConfigs", on)
	
	NMStimBoardConfigsUpdateAll(sdf)
	
	return on
	
End // NMStimUseGlobalBoardConfigsSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStimFxnList(sdf, select)
	String sdf
	String select // "Before" or "During" or "After"
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return ""
	endif

	strswitch(select)
		case "Before":
			return StrVarOrDefault(sdf+"PreStimFxnList", "")
		case "During":
			return StrVarOrDefault(sdf+"InterStimFxnList", "")
		case "After":
			return StrVarOrDefault(sdf+"PostStimFxnList", "")
	endswitch
	
	return ""

End // NMStimFxnList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStimFxnListSet(sdf, select, flist)
	String sdf
	String select // "Before" or "During" or "After"
	String flist // function name list
	
	Variable icnt
	String fxn, alist = ""
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return ""
	endif
	
	for (icnt = 0; icnt < ItemsInList(flist); icnt += 1)
	
		fxn = StringFromlist(icnt, flist)
		
		if (exists(fxn) != 6)
			DoAlert 0, "Error: function " + fxn + "() does not appear to exist."
			return ""
		else
			alist = AddListItem(fxn, alist, ";", inf)
		endif
		
	endfor

	strswitch(select)
		case "Before":
			SetNMstr(sdf+"PreStimFxnList", alist)
			break
		case "During":
			SetNMstr(sdf+"InterStimFxnList", alist)
			break
		case "After":
			SetNMstr(sdf+"PostStimFxnList", alist)
			break
		default:
			return ""
	endswitch
	
	return alist

End // NMStimFxnListSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStimFxnListAddAsk(sdf, select)
	String sdf
	String select // "Before" or "During" or "After"
	
	String fxn, otherfxn, flist, flist2, prompStr
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return ""
	endif
	
	flist = NMStimFxnList(sdf, select)
	flist2 = ClampUtilityList(select)
	
	strswitch( select )
		case "Before":
			prompStr = "Macro To Run Before Acquisition"
			break
		case "During":
			prompStr = "Macro To Run During Acquisition"
			break
		case "After":
			prompStr = "Macro To Run After Acquisition"
			break
		default:
			return ""
	endswitch

	if (strlen(flist2) > 0)
		Prompt fxn, "select utility function:", popup flist2
		Prompt otherfxn, "or enter function name, such as " + NMQuotes( "MyFunction" ) + ":"
		DoPrompt prompStr, fxn, otherfxn
	else
		Prompt otherfxn, "enter function name, such as " + NMQuotes( "MyFunction" ) + ":"
		DoPrompt prompStr, otherfxn
	endif
	
	if (V_flag == 1)
		return "" // cancel
	endif
	
	if (strlen(otherfxn) > 0)
		fxn = otherfxn
	endif
	
	return NMStimFxnListAdd(sdf, select, fxn)

End // NMStimFxnListAddCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStimFxnListAdd(sdf, select, fxn)
	String sdf
	String select // "Before" or "During" or "After"
	String fxn // function name
	
	String listname, flist
	
	sdf = CheckStimDF(sdf)
	
	if ((strlen(sdf) == 0) || (strlen(fxn) == 0))
		return ""
	endif
	
	if (exists(fxn) != 6)
		ClampError( 1, "function " + fxn + "() does not appear to exist.")
		return ""
	endif
	
	Execute /Z fxn + "(1)" // call function config
	
	strswitch(select)
		case "Before":
			listname = "PreStimFxnList"
			break
		case "During":
			listname = "InterStimFxnList"
			break
		case "After":
			listname = "PostStimFxnList"
			break
		default:
			return ""
	endswitch
	
	flist = NMStimFxnList(sdf, select)
	
	if (WhichListItem(fxn, flist, ";", 0, 0 ) == -1)
		flist = AddListItem(fxn,StrVarOrDefault(sdf+listname,""),";",inf)
		SetNMstr(sdf+listname,flist)
	endif
	
	return fxn
	
End // NMStimFxnListAdd

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStimFxnListRemoveAsk(sdf, select)
	String sdf
	String select // "Before" or "During" or "After"
	
	String fxn, flist
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return ""
	endif
	
	flist = NMStimFxnList(sdf, select)

	if (ItemsInlist(flist) == 0)
		DoAlert 0, "No funtions to remove."
		return ""
	endif
	
	Prompt fxn, "select function to remove:", popup flist
	DoPrompt "Remove Stim Function", fxn

	if (V_flag == 1)
		return ""
	endif
	
	return NMStimFxnListRemove(sdf, select, fxn)

End // NMStimFxnListRemoveAsk

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStimFxnListRemove(sdf, select, fxn)
	String sdf
	String select // "Before" or "During" or "After"
	String fxn // function name
	
	String flist
	
	sdf = CheckStimDF(sdf)
	
	if ((strlen(sdf) == 0) || (strlen(fxn) == 0))
		return ""
	endif
	
	Execute /Z fxn + "(-1)" // call function to kill variables
	
	flist = NMStimFxnList(sdf, select)
	flist = RemoveFromList(fxn, flist)
	NMStimFxnListSet(sdf, select, flist)
	
	return fxn
	
End // NMStimFxnListRemove

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimFxnListClear(sdf, select)
	String sdf
	String select // "Before" or "During" or "After"
	
	Variable icnt
	String flist, fxn
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return -1
	endif
	
	flist = NMStimFxnList(sdf, select)
	
	for (icnt = 0; icnt < ItemsInList(flist); icnt += 1)
		fxn = StringFromlist(icnt, flist)
		Execute /Z fxn + "(-1)" // call function to kill variables
	endfor
	
	NMStimFxnListSet(sdf, select, "")
	
	return 0

End // NMStimFxnListClear

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Stim Folder Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStimNew( sname ) // create a new stimulus folder
	String sname // stim name
	
	Variable icnt, init
	String df, dp = NMStimsDF
	
	Prompt sname, "stimulus name:"
	
	if (StringMatch(sname, "") == 1)
		
		for ( icnt = 0 ; icnt < 999 ; icnt += 1 )
		
			sname = "nmStim" + num2istr( icnt )
			df = dp + sname + ":"
			
			if ( DataFolderExists( df ) == 0 )
				break
			endif
			
		endfor
		
		DoPrompt "Create a New Stimulus", sname // prompt for user input if no name was passed
	
		if (V_flag == 1)
			return "" // cancel
		endif
		
	endif
	
	df = dp + sname + ":"
	
	if ( DataFolderExists( df ) == 0 )
	
		init = 1
		
	else
	
		DoAlert 1, "Warning: stim protocol name '" + sname + "' is already in use. Do you want to overwrite the existing protocol?"
		
		if ( V_Flag == 1 )
			init = 1
		endif
		
	endif
	
	if (init == 1)
		CheckNMStim(dp, sname)
	endif
	
	return sname

End // NMStimNew

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStimCopy(oldName, newName)
	String oldName // old stim name
	String newName // new stim name
	
	String dp = NMStimsDF
	
	if (IsStimFolder(dp, oldName) == 0)
		return ""
	endif
	
	if (DataFolderExists(dp+newName) == 1)
		DoAlert 2, "Stim protocol " + NMQuotes( newName ) + " is already open. Do you want to replace it?"
		if (V_flag == 1)
			KillDataFolder $(dp+newName)
		else
			return ""
		endif
	endif
	
	if ((DataFolderExists(dp+oldName) == 1) && (DataFolderExists(dp+newName) == 0))
		DuplicateDataFolder $(dp+oldName), $(dp+newName)
	endif
	
	SetNMstr(LastPathColon(dp+newName,1)+"CurrentFile", "")
	
	return newName
	
End // NMStimCopy

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimRename(oldName, newName)
	String oldName // old stim name
	String newName // new stim name
	
	String dp = NMStimsDF
	
	if (IsStimFolder(dp, oldName) == 0)
		return -1
	endif

	oldName = dp + oldName
	
	if (DataFolderExists(dp + newName) == 1)
		DoAlert 0, "Abort NMStimRename: stim protocol name " + NMQuotes( newName ) + " is already in use."
		return -1
	endif
	
	RenameDataFolder $oldName, $newName
	
	SetNMstr(LastPathColon(dp + newName,1)+"CurrentFile","")
	
	return 0
	
End // NMStimRename

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimClose(slist)
	String slist // stim list
	
	Variable icnt
	String sname, dp = NMStimsDF
	
	for (icnt = 0; icnt < ItemsInlist(slist); icnt += 1)
	
		sname = StringFromList(icnt, slist)
	
		if (IsStimFolder(dp, sname) == 0)
			return -1
		endif
		
		String df = dp + sname
		
		if (DataFolderExists(df) == 0)
			DoAlert 0, "Error: stim protocol " + NMQuotes( sname ) + " does not exist."
			return -1
		endif
		
		if (strlen(StrVarOrDefault(LastPathColon(df,1)+"CurrentFile","")) == 0)
			DoAlert 1, "Warning: stim protocol " + NMQuotes( sname ) + " has not been saved. Do you want to close it anyway?"
			if (V_flag != 1)
				return -1
			endif
		endif
		
		DoWindow /K $(sname + "Chain")
		
		PulseGraphRemoveWaves()
		
		KillDataFolder $df
		
	endfor
	
	return 0

End // NMStimClose

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStimOpenAll( path, userPrompt)
	String path // Igor path name
	Variable userPrompt // ( 0 ) no ( 1 ) yes
	
	String file, slist, filepath = path
	
	if ( userPrompt == 1 )
	
		file = NMFileOpenDialogue( path, "" )
		
		if (strlen(file) == 0)
			return "" // cancel
		endif
		
		filepath = NMParent( file )
	
	endif
	
	NewPath /Z/Q/O TempPath filePath
	
	slist = IndexedFile(TempPath,-1,"????")
	
	KillPath /Z TempPath
		
	if (ItemsInList(slist) == 0)
		return ""
	endif
	
	NMStimOpenList(filepath, slist)
	
	return ""

End // NMStimOpenAll

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimOpenList(filepath, slist)
	String filepath // external folder where stim files exist
	String slist // list of stimulus file names
	
	Variable icnt
	
	if (ItemsInList(slist) == 0)
		return -1
	endif
	
	for (icnt = 0; icnt < ItemsInList(slist); icnt += 1)
		NMStimOpen(0, "", filepath+StringFromList(icnt, slist))
	endfor
	
	StimCurrentSet(StringFromList(0, slist))

End // NMStimOpenList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStimOpen( dialogue, path, filePathList )
	Variable dialogue // ( 0 ) no ( 1 ) yes
	String path
	String filePathList // string list of external file paths
	
	Variable fcnt
	String file, filePathList2 = "", folder, folderList, stimName, stimList = ""
	
	Variable changeFolder = 0
	Variable nmPrefix = 0 // leave folder name as is
	
	for ( fcnt = 0 ; fcnt < ItemsInList( filePathList ) ; fcnt += 1 )
		
		file = StringFromList( fcnt, filePathList )
		file = FileExtCheck(file, ".pxp", 1)
		
		filePathList2 = AddListItem( file, filePathList2, ";", inf )
		
	endfor
	
	folderList = NMFileBinOpen( dialogue, ".pxp", NMStimsDF, path, filePathList2, changeFolder, nmPrefix = nmPrefix )
	
	if ( ItemsInList( folderList ) == 0 )
		return ""
	endif
	
	for ( fcnt = 0 ; fcnt < ItemsInList( folderList ) ; fcnt += 1 )
	
		folder = StringFromList( fcnt, folderList )
		
		stimName = NMChild( folder )
		
		if ( IsNMFolder( folder, "NMStim") == 0 )
		
			NMDoAlert( "Open Stim Error: folder " + NMQuotes( stimName ) + " is not a NeuroMatic stim protocol." )
			
			if ( DataFolderExists( folder ) == 1 )
				KillDataFolder $folder
			endif
			
			continue
			
		endif
		
		if ( strlen(stimName) > 0 )
			StimCurrentSet( stimName )
			StimWavesCheck( "", 0 )
			NMStimUseGlobalBoardConfigsChk( "" )
		endif
		
	endfor
	
	return stimList

End // NMStimOpen

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStimSave(dialogue, new, sname)
	Variable dialogue // (0) no prompt (1) prompt
	Variable new // (0) no (1) yes
	String sname // stim folder name

	String newname = "", folder, temp, path = "ClampStimPath", extFile = ""
	String saveCurrentFile, saveCurrentFile2, dp = NMStimsDF
	
	if (IsStimFolder(dp, sname) == 0)
		return ""
	endif
	
 	folder = dp + sname + ":"
	temp = dp + "TempXYZ:"

	if (DataFolderExists(folder) == 0)
		return ""
	endif
	
	if (DataFolderExists(temp) == 1)
		KillDataFolder $temp // clean-up
	endif
	
	if ((strlen(extFile) == 0) && (new == 1))
		extFile = sname
		//path = "StimPath"
	endif
	
	saveCurrentFile = StrVarOrDefault(folder + "CurrentFile", "")

	extFile = NMFolderSaveToDisk( folder = dp+sname, extFile = extFile, new = new, dialogue = dialogue, path = path )

	if (strlen(extFile) > 0)
	
		newname = NMChild( extFile ) // create stim folder name
		newname = FileExtCheck(newname, ".*", 0) // remove file extension if necesary
		newname = NMFolderNameCreate(newname)
		
		if (StringMatch(sname, newname) == 0)
		
			saveCurrentFile2 = StrVarOrDefault(folder + "CurrentFile", "")
			
			newname = NMStimCopy(sname, newname)
			
			SetNMstr(folder + "CurrentFile", saveCurrentFile)
			SetNMstr(dp+newname + ":" + "CurrentFile", saveCurrentFile2)
			
		endif
		
		return newname
	
	else
	
		return ""
		
	endif

End // NMStimSave

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimSaveList(dialogue, new, slist)
	Variable dialogue // (0) no prompt (1) prompt
	Variable new // (0) no (1) yes
	String slist // stim list
	
	Variable icnt
	
	for (icnt = 0; icnt < ItemsInList(slist); icnt += 1)
		NMStimSave(dialogue, new, StringFromList(icnt, slist))
	endfor
	
End // NMStimSaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function XXXXCheckStimChanFoldersXXXXX()

	Variable ccnt, nchan
	String gName, df, ddf, cdf = NMClampDF, sdf = StimDF(), pdf = NMPackageDF("Chan")
	String currFolder = StrVarOrDefault(cdf + "CurrentFolder", "")
	
	nchan = NMStimBoardNumADCchan(sdf)
	
	for (ccnt = 0; ccnt < nchan; ccnt += 1)
	
		gName = ChanGraphName(ccnt)
		
		df = sdf + gName + ":"
		
		if (DataFolderExists(df) == 1)
			continue
		endif
		
		// copy default channel graph settings to stim folder
		
		//DuplicateDataFolder $RemoveEnding( pdf, ":" ) $RemoveEnding( df, ":" ) // no longer exists
		
		if (strlen(currFolder) == 0)
			continue
		endif
		
		df = "root:" + currFolder + ":" + gName + ":"
		
		if (DataFolderExists(df) == 1)
			KillDataFolder df
		endif
		
		// copy to current data folder as well
		
		DuplicateDataFolder $RemoveEnding( pdf, ":" ) $RemoveEnding( df, ":" )
	
	endfor
		
End // CheckStimChanFolders

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Stim board config wave functions defined below
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStimBoardLookUpDF(sdf) // the directory where to find look-up table of existing configs
	String sdf
	
	sdf = CheckStimDF(sdf)
	
	if ((strlen(sdf) > 0) && (NMStimUseGlobalBoardConfigs(sdf) == 1))
		return NMClampDF // use new global board configs in Clamp folder
	endif
	
	return sdf // use old board configs saved in stim folder

End // NMStimBoardLookUpDF

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimBoardWavesCheckAll(sdf)
	String sdf

	NMStimBoardWavesCheck(sdf, "ADC")
	NMStimBoardWavesCheck(sdf, "DAC")
	NMStimBoardWavesCheck(sdf, "TTL")

End // NMStimBoardWavesCheckAll

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimBoardWavesCheck(sdf, io)	
	String sdf
	String io
	
	String bdf = NMStimBoardDF(sdf)

	Variable npnts = NM_ClampNumIO
	
	if ((strlen(ClampIOcheck(io)) == 0) || (strlen(bdf) == 0))
		return -1
	endif
	
	if (DataFolderExists(bdf) == 0)
		NewDataFolder $RemoveEnding( bdf, ":" ) 			// make new board config subfolder
	endif
	
	CheckNMtwave(bdf+io+"name", npnts,"")			// config name
	CheckNMtwave(bdf+io+"units", npnts, "")			// config units
	CheckNMwave(bdf+io+"scale", npnts, Nan)			// scale factor
	CheckNMwave(bdf+io+"board", npnts, Nan)			// board number
	CheckNMwave(bdf+io+"chan", npnts, Nan)			// board chan
	
	if (StringMatch(io, "ADC") == 1)
		CheckNMtwave(bdf+io+"mode", npnts, "")		// input mode
		CheckNMwave(bdf+io+"gain", npnts, Nan)		// channel gain
		CheckNMwave(bdf+io+"tgain", npnts, Nan)		// telegraph gain
	endif

End // NMStimBoardWavesCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimBoardConfigsOld2NewAll(sdf)
	String sdf
	
	String bdf = NMStimBoardDF(sdf)
	
	if ((DataFolderExists(bdf) == 1) || (strlen(bdf) == 0))
		return 0 // new board configs already exist
	endif

	Variable new1 = NMStimBoardConfigsOld2New(sdf, "ADC")
	Variable new2 = NMStimBoardConfigsOld2New(sdf, "DAC")
	Variable new3 = NMStimBoardConfigsOld2New(sdf, "TTL")
	
	if (new1 + new2 + new3 > 0)
		Print "Updated " + StimCurrent() + " to version " + NMVersionStr
	endif
	
	return new1 + new2 + new3
	
End // NMStimBoardConfigsOld2NewAll

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimBoardConfigsOld2New(sdf, io)
	String sdf
	String io

	Variable icnt, npnts
	String bdf
	
	sdf = CheckStimDF(sdf)
	bdf = NMStimBoardDF(sdf)
	
	if ((strlen(ClampIOcheck(io)) == 0) || (strlen(sdf) == 0))
		return 0
	endif
	
	if (WaveExists($sdf+io+"name") == 0)
		return 0 // nothing to do
	endif
	
	Variable numIO = numpnts($sdf+io+"name")

	NMStimBoardWavesCheckAll(sdf)
	
	if (WaveExists($bdf+io+"name") == 0)
		return 0 // something went wrong
	endif
	
	Wave /T nameN = $bdf+io+"name"
	Wave /T unitsN = $bdf+io+"units"
	Wave scaleN = $bdf+io+"scale"
	Wave boardN = $bdf+io+"board"
	Wave chanN = $bdf+io+"chan"
	
	Wave /T nameO = $sdf+io+"name"
	Wave /T unitsO = $sdf+io+"units"
	Wave scaleO = $sdf+io+"scale"
	Wave boardO = $sdf+io+"board"
	Wave chanO = $sdf+io+"chan"
	Wave onO = $sdf+io+"on"
	
	if (StringMatch(io, "ADC") == 1)
		Wave /T modeN = $bdf+io+"mode"
		Wave gainN = $bdf+io+"gain"
		Wave tgainN = $bdf+io+"tgain"
		Wave modeO = $sdf+io+"mode"
		Wave gainO = $sdf+io+"gain"
	endif
	
	npnts = numpnts(onO)
	
	if (numpnts(nameN) < npnts)
	
		npnts = max(npnts+5, NM_ClampNumIO)
	
		Redimension /N=(npnts) nameN, unitsN, scaleN, boardN, chanN
		
		if (StringMatch(io, "ADC") == 1)
			Redimension /N=(npnts) modeN, gainN, tgainN
		endif
		
	endif
	
	for (icnt = 0; icnt < numpnts(onO); icnt += 1)
	
		if (onO[icnt] == 1)
		
			nameN[icnt] = nameO[icnt]
			unitsN[icnt] = unitsO[icnt]
			scaleN[icnt] = scaleO[icnt]
			boardN[icnt] = boardO[icnt]
			chanN[icnt] = chanO[icnt]
			
			if (StringMatch(io, "ADC") == 1)
			
				gainN[icnt] = gainO[icnt]
				
				if (modeO[icnt] > 0)
					modeN[icnt] = "PreSamp=" + num2str(modeO[icnt])
				else
					modeN[icnt] = ""
				endif
				
			endif
			
		else
		
			nameN[icnt] = ""
			unitsN[icnt] = ""
			scaleN[icnt] = Nan
			boardN[icnt] = Nan
			chanN[icnt] = Nan
			
			if (StringMatch(io, "ADC") == 1)
				modeN[icnt] = ""
				gainN[icnt] = Nan
			endif
			
		endif
		
	endfor
	
	return 1

End // NMStimBoardConfigsOld2New

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimBoardConfigsUpdateAll(sdf)
	String sdf
	
	Variable update1 = NMStimBoardConfigsUpdate(sdf, "ADC")
	Variable update2 = NMStimBoardConfigsUpdate(sdf, "DAC")
	Variable update3 = NMStimBoardConfigsUpdate(sdf, "TTL")
	
	if ((update2 == 1) || (update3 == 1))
		StimWavesCheck(sdf, 1)
	endif
	
End // NMStimBoardConfigsUpdateAll

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimBoardConfigsUpdate(sdf, io)
	String sdf
	String io
	
	Variable icnt, jcnt, found, updated, board, chan, achan, gchan, npnts, board2
	String cname, modeStr, item, instr
	String cdf = NMClampDF, ludf = NMStimBoardLookUpDF(sdf), bdf = NMStimBoardDF(sdf)
	
	Variable driver = NumVarOrDefault(cdf+"BoardDriver", 0)
	
	String tGainList = StrVarOrDefault(cdf+"TGainList", "")
	
	if (strlen(ClampIOcheck(io)) == 0)
		return 0
	endif
	
	if ((WaveExists($ludf+io+"name") == 0) || (WaveExists($bdf+io+"name") == 0))
		return 0
	endif
	
	Wave /T nameG = $ludf+io+"name"
	Wave /T unitsG = $ludf+io+"units"
	Wave scaleG = $ludf+io+"scale"
	Wave boardG = $ludf+io+"board"
	Wave chanG = $ludf+io+"chan"
	
	Wave /T nameS = $bdf+io+"name"
	Wave /T unitsS = $bdf+io+"units"
	Wave scaleS = $bdf+io+"scale"
	Wave boardS = $bdf+io+"board"
	Wave chanS = $bdf+io+"chan"
	
	if (StringMatch(io, "ADC") == 1)
		Wave /T modeG = $ludf+io+"mode"
		Wave gainG = $ludf+io+"gain"
		Wave /T modeS = $bdf+io+"mode"
		Wave gainS = $bdf+io+"gain"
		Wave tgainS = $bdf+io+"tgain"
	endif
	
	npnts = numpnts(nameG)
	
	if (numpnts(nameS) < npnts)
	
		npnts = max(npnts + 5, NM_ClampNumIO)
	
		Redimension /N=(npnts) nameS, unitsS, scaleS, boardS, chanS
		
		if (StringMatch(io, "ADC") == 1)
			Redimension /N=(npnts) modeS, gainS, tgainS
		endif
	
	endif
	
	if (StringMatch(io, "ADC") == 1)
	
		tgainS[icnt] = Nan // unnecessary??
		
		for (icnt = 0; icnt < numpnts(nameS); icnt += 1)
		
			cname = nameS[icnt]
			
			for (jcnt = 0; jcnt < 10; jcnt += 1)
				if (StringMatch(cname, "TGain_" + num2istr(jcnt)) == 1)
					nameS[icnt] = "" // clear old telegraph gain configs before updating
				endif
			endfor
			
		endfor
		
	endif
	
	for (icnt = 0; icnt < numpnts(nameS); icnt += 1)
	
		cname = nameS[icnt]
	
		if (strlen(cname) == 0)
		
			unitsS[icnt] = ""
			scaleS[icnt] = Nan
			boardS[icnt] = Nan
			chanS[icnt] = Nan
	
			if (StringMatch(io, "ADC") == 1)
				modeS[icnt] = ""
				gainS[icnt] = Nan
			endif
			
			continue
	
		endif
		
		found = 0
		
		for (jcnt = 0; jcnt < numpnts(nameG); jcnt += 1)
		
			if (StringMatch(cname, nameG[jcnt]) == 1)
			
				found = 1
				
				if (StringMatch(unitsS[icnt], unitsG[jcnt]) == 0)
					unitsS[icnt] = unitsG[jcnt]
					updated = 1
				endif
				
				if (scaleS[icnt] != scaleG[jcnt])
					scaleS[icnt] = scaleG[jcnt]
					updated = 1
				endif
				
				if (boardS[icnt] != boardG[jcnt])
					boardS[icnt] = boardG[jcnt]
					updated = 1
				endif
				
				if (chanS[icnt] != chanG[jcnt])
					chanS[icnt] = chanG[jcnt]
					updated = 1
				endif
				
				if (StringMatch(io, "ADC") == 1)
				
					if (StringMatch(modeS[icnt], modeG[jcnt]) == 0)
						modeS[icnt] = modeG[jcnt]
						updated = 1
					endif
					
					if (gainS[icnt] != gainG[jcnt])
						gainS[icnt] = gainG[jcnt]
						updated = 1
					endif
					
				endif
				
				break
				
			endif
			
		endfor
		
		if (found == 0)
		
			unitsS[icnt] = ""
			scaleS[icnt] = Nan
			boardS[icnt] = Nan
			chanS[icnt] = Nan
	
			if (StringMatch(io, "ADC") == 1)
				modeS[icnt] = ""
				gainS[icnt] = Nan
			endif
		
		endif
		
	endfor
	
	//
	// BEGIN TELEGRAPH CONFIGS
	//
	
	if (StringMatch(io, "ADC") == 1)
	
		for (icnt = 0; icnt < numpnts(nameS); icnt += 1)
		
			cname = nameS[icnt]
			
			if (StringMatch(cname[0,5], "TGain_") == 1)
				nameS[icnt] = "" // remove pre-existing TGain configs
			endif
			
			if (StringMatch(cname[0,5], "TMode_") == 1)
				nameS[icnt] = ""
			endif
			
			if (StringMatch(cname[0,5], "TFreq_") == 1)
				nameS[icnt] = ""
			endif
			
			if (StringMatch(cname[0,5], "TCap_") == 1)
				nameS[icnt] = ""
			endif
			
		endfor
		
		// add new global TGain configs if they exist
		
		for (icnt = 0; icnt < numpnts(nameG); icnt += 1)
		
			cname = nameG[icnt]
			
			if (StringMatch(cname[0,5], "TGain_") == 1)
					
				modeStr = modeG[icnt]
				board = ClampTGainBoard(modeStr)
				chan = ClampTGainChan(modeStr)
				
				if (board == 0)
					board = driver
				endif
				
				found = 0
				
				for (jcnt = 0; jcnt < numpnts(nameS); jcnt += 1)
				
					board2 = boardS[jcnt]
					
					if (board2 == 0)
						board2 = driver
					endif
					
					if ((strlen(nameS[jcnt]) > 0) && (board2 == board) && (chanS[jcnt] == chan))
						found = 1
						break
					endif
					
				endfor
				
				if (found == 1)
	
					found = 0
					
					for (jcnt = 0; jcnt < numpnts(nameS); jcnt += 1)
						if (strlen(nameS[jcnt]) == 0)
							found = 1 // this is the first empty location
							break
						endif
					endfor
					
					if (found == 1)
						nameS[jcnt] = nameG[icnt]
					endif
				
				endif
			
			endif
			
		endfor
		
		if (ItemsInList(tGainList) > 0) // check for old telegraph-gain configs
		
			for (jcnt = 0; jcnt < ItemsInList(tGainList); jcnt += 1)
			
				cname = "TGain_" + num2istr(jcnt)
				item = StringFromList(jcnt, tGainList)
				board = 0 // default driver
				gchan = str2num(StringFromList(0, item, ",")) // telegraph gain ADC input channel
				achan = str2num(StringFromList(1, item, ",")) // ADC input channel to scale
				instr = StringFromList(2, item, ",") // amplifier instrument
				
				if (strlen(instr) == 0)
					instr = StrVarOrDefault(cdf+"ClampInstrument", "")
				endif
				
				if (strlen(instr) == 0)
					continue
				endif
				
				modeStr = "TGain=B" + num2istr(board) + "_C" + num2istr(achan) + "_" + instr
				
				found = 0
				
				for (icnt = 0; icnt < numpnts(modeS); icnt += 1)
					if (StringMatch(modeS[icnt], modeStr) == 1)
						found = 1
						break
					endif
				endfor
				
				if (found == 1)
					continue // config already exists, go to next TGain config
				endif
				
				board = driver
				
				for (icnt = 0; icnt < numpnts(nameS); icnt += 1)
				
					board2 = boardS[icnt]
					
					if (board2 == 0)
						board2 = driver
					endif
					
					if ((strlen(nameS[icnt]) > 0) && (board2 == board) && (chanS[icnt] == achan))
						found = 1
						break
					endif
				endfor
				
				if (found == 1)
	
					found = 0
					
					for (icnt = 0; icnt < numpnts(nameS); icnt += 1)
						if (strlen(nameS[icnt]) == 0)
							found = 1 // this is the first empty location
							break
						endif
					endfor
					
					if (found == 1)
						nameS[icnt] = "TGain_" + num2istr(jcnt)
						UnitsS[icnt] = "V"
						boardS[icnt] = 0
						chanS[icnt] = gchan
						scaleS[icnt] = 1
						modeS[icnt] = "TGain=B0_C" + num2istr(achan) + "_" + instr
						gainS[icnt] = 1
					endif
				
				endif
			
			endfor
		
		endif
		
		// udpate new telegraph-grain configs
	
		for (icnt = 0; icnt < numpnts(nameS); icnt += 1)
		
			modeStr = modeS[icnt]
			
			if (ClampTelegraphCheck( "Gain", modeStr ) == 1)
			
				board = ClampTGainBoard(modeStr)
				chan = ClampTGainChan(modeStr)
				
				if (board == 0)
					board = driver
				endif
				
				if ((numtype(chan) == 0) || (numtype(board) == 0))
				
					for (jcnt = 0; jcnt < numpnts(nameS); jcnt += 1)
					
						board2 = boardS[jcnt]
						
						if (board2 == 0)
							board2 = driver
						endif
						
						if ((board == board2) && (chan == chanS[jcnt]))
							tgainS[jcnt] = icnt
						endif
						
					endfor
				
				endif
				
				//if ((numtype(chan) == 0) && (chan >= 0) && (chan < numpnts(nameS)) && (strlen(nameS[chan]) > 0))
				//	tgainS[chan] = icnt
				//else
				
			endif
			
		endfor
		
		for (icnt = 0; icnt < numpnts(nameG); icnt += 1) // Add other existing telegraphs
		
			cname = nameG[icnt]
			
			if ( (StringMatch(cname[0,5], "TMode_") == 1) || (StringMatch(cname[0,5], "TFreq_") == 1) || (StringMatch(cname[0,5], "TCap_") == 1) )
			
				if ( strlen( modeG[icnt] ) > 0 )
			
					found = 0
							
					for (jcnt = 0; jcnt < numpnts(nameS); jcnt += 1)
						if (strlen(nameS[jcnt]) == 0)
							found = 1 // this is the first empty location
							break
						endif
					endfor
					
					if (found == 1)
						nameS[jcnt] = nameG[icnt]
					endif
				
				endif
				
			endif
			
		endfor
		
	endif
		
	return updated

End // NMStimBoardConfigsUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimBoardConfigsCheckDups(sdf)
	String sdf

	Variable config, jcnt, test, on
	String bdf = NMStimBoardDF(sdf)
	
	sdf = CheckStimDF(sdf)
	
	if (WaveExists($bdf+"ADCname") == 0)
		return -1
	endif
	
	Wave /T ADCname = $bdf+"ADCname"
	Wave ADCchan = $bdf+"ADCchan"
	Wave /T ADCmode = $bdf+"ADCmode"
	Wave ADCboard = $bdf+"ADCboard"

	Wave /T DACname = $bdf+"DACname"
	Wave DACchan = $bdf+"DACchan"
	Wave DACboard = $bdf+"DACboard"
	
	Wave /T TTLname = $bdf+"TTLname"
	Wave TTLchan = $bdf+"TTLchan"
	Wave TTLboard = $bdf+"TTLboard"
	
	for (config = 0; config < numpnts(ADCname); config += 1)
	
		if (strlen(ADCname[config]) > 0)
		
			for (jcnt = 0; jcnt < numpnts(ADCname); jcnt += 1)
			
				test = 0
				
				if (strlen(ADCname[jcnt]) > 0)
					test = 1
				endif
			
				test = test && (ADCboard[jcnt] == ADCboard[config])
				test = test && (ADCchan[jcnt] == ADCchan[config]) && (StringMatch(ADCmode[jcnt], ADCmode[config]) == 1)
				
				if ((jcnt != config) && (test == 1))
					ClampError( 1, "duplicate ADC inputs for configs " + num2istr(config) + " and " + num2istr(jcnt))
					return -1
				endif
				
			endfor
			
		endif
		
	endfor
	
	for (config = 0; config < numpnts(DACname); config += 1)
	
		if (strlen(DACname[config]) > 0)
		
			for (jcnt = 0; jcnt < numpnts(DACname); jcnt += 1)
			
				test = 0
				
				if (strlen(DACname[jcnt]) > 0)
					test = 1
				endif
			
				test = test && (DACboard[jcnt] == DACboard[config]) && (DACchan[jcnt] == DACchan[config])
				
				if ((jcnt != config) && (test == 1))
					ClampError( 1, "duplicate DAC outputs for configs " + num2istr(config) + " and " + num2istr(jcnt))
					return -1
				endif
				
			endfor
			
		endif
		
	endfor
	
	for (config = 0; config < numpnts(TTLname); config += 1)
	
		if (strlen(TTLname[config]) > 0)
		
			for (jcnt = 0; jcnt < numpnts(TTLname); jcnt += 1)
			
				test = 0
				
				if (strlen(TTLname[jcnt]) > 0)
					test = 1
				endif
			
				test = test && (TTLboard[jcnt] == TTLboard[config]) && (TTLchan[jcnt] == TTLchan[config])
			
				if ((jcnt != config) && (test == 1))
					ClampError( 1, "duplicate TTL outputs for configs " + num2istr(config) + " and " + num2istr(jcnt))
					return -1
				endif
				
			endfor
			
		endif
		
	endfor
	
	return 0

End // NMStimBoardConfigsCheckDups

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimBoardConfigEdit(sdf, io, configName)
	String sdf
	String io
	String configName
	
	Variable icnt, board, chan, scale, config = -1
	String units, ludf = NMStimBoardLookUpDF(sdf)
	String unitsList = StrVarOrDefault(NMClampTabDF+"UnitsList", "")
	
	if (strlen(ClampIOcheck(io)) == 0)
		return -1
	endif
	
	if (WaveExists($ludf+io+"name") == 0)
		return -1
	endif
	
	Wave /T nameG = $ludf+io+"name"
	Wave /T unitsG = $ludf+io+"units"
	Wave scaleG = $ludf+io+"scale"
	Wave boardG = $ludf+io+"board"
	Wave chanG = $ludf+io+"chan"
	
	if (StringMatch(io, "ADC") == 1)
		Wave /T modeG = $ludf+io+"mode"
		Wave gainG = $ludf+io+"gain"
	endif
	
	for (icnt = 0; icnt < numpnts(nameG); icnt += 1)
		if (StringMatch(nameG[icnt], configName) == 1)
			config = icnt
			break
		endif
	endfor
	
	if ((config < 0) || (config >= numpnts(unitsG)))
		return -1
	endif
	
	units = unitsG[config]
	board = boardG[config]
	chan = chanG[config]
	scale = scaleG[config]
	
	prompt units, "units:", popup unitsList
	prompt board, "board:"
	prompt chan, "chan:"
	prompt scale, "scale:"
	
	DoPrompt io + " Config " + configName, units, board, chan, scale
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	unitsG[config] = units
	boardG[config] = board
	chanG[config] = chan
	scaleG[config] = scale
	
	return 0

End // NMStimBoardConfigEdit

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimBoardConfigActivate(sdf, io, config, configName)
	String sdf
	String io
	Variable config // (-1) next available
	String configName

	Variable icnt, npnts, configG = -1
	String tgain, wPrefix = StimWaveName(io, config, -1)
	String bdf = NMStimBoardDF(sdf), ludf = NMStimBoardLookUpDF(sdf)
	
	if (strlen(ClampIOcheck(io)) == 0)
		return -1
	endif
	
	if ((WaveExists($bdf+io+"name") == 0) || (WaveExists($ludf+io+"name") == 0))
		return -1
	endif
	
	Wave /T nameS = $bdf+io+"name"
	Wave /T unitsS = $bdf+io+"units"
	Wave scaleS = $bdf+io+"scale"
	Wave boardS = $bdf+io+"board"
	Wave chanS = $bdf+io+"chan"
	
	Wave /T nameG = $ludf+io+"name"
	Wave /T unitsG = $ludf+io+"units"
	Wave scaleG = $ludf+io+"scale"
	Wave boardG = $ludf+io+"board"
	Wave chanG = $ludf+io+"chan"
	
	if (StringMatch(io, "ADC") == 1)
		Wave /T modeS = $bdf+io+"mode"
		Wave gainS = $bdf+io+"gain"
		Wave /T modeG = $ludf+io+"mode"
		Wave gainG = $ludf+io+"gain"
	endif
	
	npnts = numpnts(nameS)
	
	if (config < 0)
	
		for (icnt = 0; icnt < npnts; icnt += 1)
			if (strlen(nameS[icnt]) == 0)
				config = icnt
				break
			endif
		endfor
	
	endif
	
	if (config < 0)
		return -1
	endif
	
	if (strlen(configName) > 0)
	
		for (icnt = 0; icnt < numpnts(nameS); icnt += 1)
			if (StringMatch(nameS[icnt], configName) == 1)
				return -1 // already exists
			endif
		endfor
	
		for (icnt = 0; icnt < numpnts(nameG); icnt += 1)
			if (StringMatch(nameG[icnt], configName) == 1)
				configG = icnt
			endif
		endfor
		
	endif
	
	if ( ( config < 0 ) || ( config >= numpnts( nameS ) ) )
		return -1
	endif
		
	if ( ( configG >= 0 ) && ( configG < numpnts( unitsG ) ) )
	
		nameS[config] = configName
		unitsS[config] = unitsG[configG]
		scaleS[config] = scaleG[configG]
		boardS[config] = boardG[configG]
		chanS[config] = chanG[configG]
		
		if (StringMatch(io, "ADC") == 1)
		
			modeS[config] = modeG[configG]
			gainS[config] = gainG[configG]
			
			//CheckStimChanFolders()
			
		else // DAC and TTL
		
			PulseWaveCheck(io, config)
			StimWavesCheck(sdf, 1) // this creates waves
			
		endif
		
	else
	
		nameS[config] = ""
		unitsS[config] = ""
		scaleS[config] = Nan
		boardS[config] = Nan
		chanS[config] = Nan
		
		if (StringMatch(io, "ADC") == 1)
		
			modeS[config] = ""
			gainS[config] = Nan
			
		else // DAC and TTL
		
			PulseWavesKill(sdf, wPrefix)
			PulseWavesKill(sdf, "u"+wPrefix)
			
		endif
		
	endif
	
	return 0

End // NMStimBoardConfigActivate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimBoardConfigIsActive(sdf, io, config)
	String sdf // stim data folder
	String io // "ADC", "DAC" or "TTL"
	Variable config
	
	if (strlen(NMStimBoardConfigName(sdf, io, config)) > 0)
		return 1
	endif
	
	return 0
	
End // NMStimBoardConfigIsActive

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStimBoardConfigActiveList(sdf, io)
	String sdf // stim data folder
	String io // "ADC", "DAC" or "TTL"
	
	Variable icnt
	String alist = "", bdf = NMStimBoardDF(sdf)
	
	if (WaveExists($bdf+io+"name") == 0)
		return ""
	endif
	
	Wave /T name = $bdf+io+"name"
	
	for (icnt = 0; icnt < numpnts(name); icnt += 1)
		if (strlen(name[icnt]) > 0)
			alist = AddListItem(num2istr(icnt), alist, ";", inf)
		endif
	endfor
	
	return alist
	
End // NMStimBoardConfigActiveList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStimBoardConfigActiveNameList(sdf, io)
	String sdf // stim data folder
	String io // "ADC", "DAC" or "TTL"
	
	Variable icnt
	String alist = "", bdf = NMStimBoardDF(sdf)
	
	if (WaveExists($bdf+io+"name") == 0)
		return ""
	endif
	
	Wave /T name = $bdf+io+"name"
	
	for (icnt = 0; icnt < numpnts(name); icnt += 1)
		if (strlen(name[icnt]) > 0)
			alist = AddListItem(name[icnt], alist, ";", inf)
		endif
	endfor
	
	return alist
	
End // NMStimBoardConfigActiveNameList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStimBoardConfigName(sdf, io, config)
	String sdf // stim data folder
	String io // "ADC", "DAC" or "TTL"
	Variable config
	
	String bdf = NMStimBoardDF(sdf)
	
	if (WaveExists($bdf+io+"name") == 0)
		return ""
	endif
	
	Wave /T name = $bdf+io+"name"
	
	if ((config >= 0) && (config < numpnts(name)) && (strlen(name[config]) > 0))
		return name[config]
	endif
	
	return ""

End // NMStimBoardConfigName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimBoardConfigNum(sdf, io, configName)
	String sdf // stim data folder
	String io // "ADC", "DAC" or "TTL"
	String configName
	
	Variable icnt
	String bdf = NMStimBoardDF(sdf)
	
	if ((strlen(configName) == 0) || (WaveExists($bdf+io+"name") == 0))
		return 0
	endif
	
	Wave /T name = $bdf+io+"name"
	
	for (icnt = 0; icnt < numpnts(name); icnt += 1)
	
		if (StringMatch(name[icnt], configName) == 1)
			return icnt
		endif
		
	endfor
	
	return -1

End // NMStimBoardConfigNum

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimADCmodeNormal( modeStr )
	String modeStr
	
	if ( strlen( modeStr ) == 0 )
		return 1 // yes, normal mode
	endif
	
	if ( strsearch( modeStr, "PreSamp", 0 ) >= 0 )
		return 0 // telegraph configuration
	endif
	
	if ( ClampTelegraphCheck( "Gain", modeStr ) == 1 )
		
		strswitch( ClampTelegraphInstrument( modeStr ) )
			case "MultiClamp700":
				return 1 // normal ( channel is scaled via NMMultiClampTelegraphsConfig )
			default:
				return 0 // telegraph configuration
		endswitch
		
	endif
	
	if ( strsearch( modeStr, "Mode", 0 ) >= 0 )
		return 0 // telegraph configuration
	endif
	
	if ( strsearch( modeStr, "Freq", 0 ) >= 0 )
		return 0 // telegraph configuration
	endif
	
	if ( strsearch( modeStr, "Cap", 0 ) >= 0 )
		return 0 // telegraph configuration
	endif
	
	return 1 // default is normal mode
	
End // NMStimADCmodeNormal

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimBoardNumADCchan( sdf )
	String sdf // stim data folder
	
	Variable config, ccnt
	String bdf = NMStimBoardDF(sdf)
	
	if ( ( WaveExists($bdf+"ADCname") == 0) || (WaveExists($bdf+"ADCmode") == 0) )
		return 0
	endif
	
	Wave /T name = $bdf+"ADCname"
	Wave /T mode = $bdf+"ADCmode"

	for (config = 0; config < numpnts(name); config += 1)
	
		if ( config >= numpnts( mode ) )
			break
		endif
	
		if ( (strlen(name[config]) > 0) && ( NMStimADCmodeNormal( mode[ config ] ) == 1 ) )
			ccnt += 1
		endif
		
	endfor

	return ccnt

End // NMStimBoardNumADCchan

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStimBoardOnList(sdf, io)
	String sdf // stim data folder
	String io // "ADC", "DAC" or "TTL"
	
	Variable config
	String name, mode, list = ""
	String bdf = NMStimBoardDF(sdf)
	
	if (strlen(bdf) == 0)
		return ""
	endif
	
	strswitch(io)
	
		case "ADC":
	
			for (config = 0; config < numpnts($bdf+io+"name"); config += 1)
			
				name = WaveStrOrDefault(bdf+io+"name", config, "")
				mode = WaveStrOrDefault(bdf+io+"mode", config, "")
				
				if ((strlen(name) > 0) && (NMStimADCmodeNormal(mode) == 1))
					list = AddListItem(num2istr(config), list, ";", inf)
				endif
				
			endfor
			
			break
	
		case "DAC":
		case "TTL":
		
			for (config = 0; config < numpnts($bdf+io+"name"); config += 1)
				name = WaveStrOrDefault(bdf+io+"name", config, "")
				if (strlen(name) > 0)
					list = AddListItem(num2istr(config), list, ";", inf)
				endif
			endfor
			
	endswitch
	
	return list
	
End // NMStimBoardOnList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimBoardOnCount(sdf, io)
	String sdf // stim data folder
	String io // "ADC", "DAC" or "TTL"
	
	sdf = CheckStimDF(sdf)
	
	if (strlen(sdf) == 0)
		return -1
	endif
	
	return ItemsInList(NMStimBoardOnList(sdf, io))
	
End // NMStimBoardOnCount

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStimBoardNamesTable(sdf, hook)
	String sdf // stim data folder path
	Variable hook // (0) no update (1) updateNM
	
	String wName, tName, title, bdf
	
	STRUCT Rect w
	
	sdf = CheckStimDF(sdf)
	bdf = NMStimBoardDF(sdf)
	
	String stim = NMChild( sdf )
	
	if (strlen(bdf) == 0)
		return ""
	endif
	
	tName = NMCheckStringName(stim + "_config_names")
	
	if (WinType(tName) == 2)
		DoWindow /F $tName
		return tName
	endif
	
	title = "Stim config names : " + stim
	
	NMWinCascadeRect( w )
	
	DoWindow /K $tName
	Edit /N=$tName/W=(w.left,w.top,w.right,w.bottom)/K=1 as title[0,30]
	ModifyTable /W=$tName title(Point)="Config"
	
	if (hook == 1)
		SetWindow $tName hook=NMStimBoardNamesTableHook
	endif
	
	wName = bdf + "ADCname"
	
	if (WaveExists($wName) == 1)
		AppendToTable /W=$tName $wName
	endif
	
	wName = bdf + "DACname"
	
	if (WaveExists($wName) == 1)
		AppendToTable /W=$tName $wName
	endif
	
	wName = bdf + "TTLname"
	
	if (WaveExists($wName) == 1)
		AppendToTable /W=$tName $wName
	endif
	
	return tName

End // NMStimBoardNamesTable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimBoardNamesTableHook(infoStr)
	string infoStr
	
	string event= StringByKey("EVENT",infoStr)
	string win= StringByKey("WINDOW",infoStr)
	
	strswitch(event)
		case "deactivate":
		case "kill":
			UpdateNM(0)
	endswitch

End // NMStimBoardNamesTableHook

//****************************************************************
//****************************************************************
//****************************************************************
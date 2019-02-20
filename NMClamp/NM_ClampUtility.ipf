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
//****************************************************************
//****************************************************************
//
//	Variable mode:
//		(-1) Kill. Kill waves/variables. Called when user removes macro from stim macro list. 
//		(0) Run. Do computation. Called during acquisition. 
//		(1) Config. Prompt user for parameter values. Called when user adds macro to stim macro list.
//		(2) Init. Init computation. Called before acquisition starts.
//		(3) Finish. Finilize computation. Called after acquisition ends.
//
//****************************************************************
//****************************************************************

Function /S ClampUtilityList(select)
	String select
	
	strswitch(select)
		case "Before":
			return ClampUtilityPreList()
		case "During":
			return ClampUtilityInterList()
		case "After":
			return ClampUtilityPostList()
	endswitch
	
	return ""
	
End // ClampUtilityList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampUtilityPreList()

	return "ReadTemp;TModeCheck;TcapRead;TfreqRead;"
	
End // ClampUtilityPreList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampUtilityInterList()

	//return "OnlineAvg;Rstep;RCstep;TempRead;StatsRatio;ModelCell;"
	return "OnlineAvg;Rstep;RCstep;TempRead;StatsRatio;RandomOrder;"
	
End // ClampUtilityInterList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampUtilityPostList()

	return ""
	
End // ClampUtilityPostList

//****************************************************************
//****************************************************************
//****************************************************************

Static Function ClampUtilityKill( varPrefix )
	String varPrefix

	Variable icnt
	String oList, objName, sdf = StimDF()
	
	oList = NMFolderVariableList( sdf, varPrefix + "*", ";", 4, 1 )
	
	for ( icnt = 0 ; icnt < ItemsInlist( oList ) ; icnt += 1 )
		objName = StringFromList( icnt, oList )
		KillVariables /Z $objName
	endfor
	
	oList = NMFolderStringList( sdf, varPrefix + "*", ";", 1 )
	
	for ( icnt = 0 ; icnt < ItemsInlist( oList ) ; icnt += 1 )
		objName = StringFromList( icnt, oList )
		KillStrings /Z $objName
	endfor
	
	oList = NMFolderWaveList( sdf, varPrefix + "*", ";", "", 1 )
	
	for ( icnt = 0 ; icnt < ItemsInlist( oList ) ; icnt += 1 )
		objName = StringFromList( icnt, oList )
		KillWaves /Z $objName
	endfor

End // ClampUtilityKill

//****************************************************************
//
//	OnlineAvg()
//	computes online average of channel graphs
//	add this function to inter-stim fxn execution list
//
//****************************************************************

Function OnlineAvg(mode)
	Variable mode // see definition at top
	
	Variable ccnt, cbeg, cend
	String wname, avgname, gname, sdf = StimDF()
	
	Variable chan = NumVarOrDefault(sdf+"OnlineAvgChan", -1)
	Variable currentWave = NMVarGet( "CurrentWave" )
	Variable nchans = NMNumChannels()
	
	switch(mode)
	
		case 0:
			break
	
		case 1:
			OnlineAvgConfig()
			return 0
	
		case -1:
			KillVariables /Z $(sdf+"OnlineAvgChan")
			return 0
		
		case 2:
		default:
			return 0
			
	endswitch
	
	if (chan == -1)
		cbeg = 0
		cend = nchans - 1
	else
		cbeg = chan
		cend = chan
	endif
	
	for (ccnt = cbeg; ccnt <= cend; ccnt += 1)
	
		wname = ChanDisplayWave(ccnt)
		avgname = GetWaveName("CT_Avg", ccnt, 0)
		gName = ChanGraphName(ccnt)
		
		if (WaveExists($wname) == 0)
			continue
		endif
		
		Wave wtemp = $wname
		
		if (currentWave == 0)
			Duplicate /O $wname $avgname
			RemoveFromGraph /Z/W=$gname $avgname
			AppendToGraph /W=$gname $avgname
		else
			Wave avgtemp = $avgname
			avgtemp = ((avgtemp * currentWave) + wtemp) / (currentWave + 1)
		endif
		
	endfor
	
End // OnlineAvg

//****************************************************************
//****************************************************************
//****************************************************************

Function OnlineAvgConfig()

	String sdf = StimDF()

	Variable numchan = NMStimBoardOnCount("", "ADC")
	String chanList = NMChanList( "CHAR" )
	
	if (numchan == 1)
		return 0
	endif
	
	Variable chan = NumVarOrDefault(sdf+"OnlineAvgChan", -1)
	
	if (numchan > 1)
		chanList += "All"
	endif
	
	if (chan == -1) // All
		chan = ItemsInList(chanList)
	else
		chan += 1
	endif
	
	Prompt chan, "channel to average:", popup chanList
	DoPrompt "Online Average Configuration", chan
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	chan -= 1
	
	if (chan >= numchan)
		chan = -1
	endif
	
	SetNMvar(sdf+"OnlineAvgChan", chan)

End // OnlineAvgConfig

//****************************************************************
//
//	ReadTemp()
//	read temperature from ADC input (read once)
//
//
//****************************************************************

Function ReadTemp(mode)
	Variable mode // see definition at top
	
	Variable telValue
	String cdf = NMClampDF
	
	switch(mode)
	
		case 0:
			break
	
		case 1:
			ReadTempConfig()
			break
	
		case 2:
		case -1:
		default:
			return 0
			
	endswitch
	
	Variable driver = NumVarOrDefault(cdf+"BoardDriver", 0)
	Variable chan = NumVarOrDefault(cdf+"TempChan", -1)
	Variable slope = NumVarOrDefault(cdf+"TempSlope", Nan)
	Variable offset = NumVarOrDefault(cdf+"TempOffset", Nan)
	
	if ((chan < 0) || (numtype(chan*slope*offset) > 0))
		return -1
	endif
	
	telValue = ClampReadManager(StrVarOrDefault(cdf+"AcqBoard", ""), driver, chan, 1, 50)
	
	telValue = telValue * slope + offset
	
	NMHistory(NMCR + "Temperature: " + num2str(telValue))
	
	NMNotesFileVar("F_Temp", telValue)
	
End // ReadTemp

//****************************************************************
//****************************************************************
//****************************************************************

Function ReadTempConfig()

	String cdf = NMClampDF
	
	Variable chan = NumVarOrDefault(cdf+"TempChan", -1) + 1
	Variable slope = NumVarOrDefault(cdf+"TempSlope", 1)
	Variable offset = NumVarOrDefault(cdf+"TempOffset", 0)
	
	Prompt chan, "select ADC input to acquire temperature:", popup "0;1;2;3;4;5;6;7;"
	Prompt slope, "enter slope conversion factor (degrees / V) :"
	Prompt offset, "enter offset factor (degrees) :"
	DoPrompt "Read Temperature", chan, slope, offset
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	SetNMvar(cdf+"TempChan", chan-1)
	SetNMvar(cdf+"TempSlope", slope)
	SetNMvar(cdf+"TempOffset", offset)

End // ReadTempConfig

//****************************************************************
//
//	TempRead()
//	read temperature from ADC input (saves to a wave)
//
//
//****************************************************************

Function TempRead(mode)
	Variable mode // see definition at top
	
	Variable telValue
	String cdf = NMClampDF, sdf = StimDF()
	
	switch(mode)
	
		case 0:
			break
	
		case 1:
			ReadTempConfig()
			break
	
		case 2:
		case -1:
		default:
			return 0
	
	endswitch
	
	Variable driver = NumVarOrDefault(cdf+"BoardDriver", 0)
	Variable chan = NumVarOrDefault(cdf+"TempChan", -1)
	Variable slope = NumVarOrDefault(cdf+"TempSlope", Nan)
	Variable offset = NumVarOrDefault(cdf+"TempOffset", Nan)
	
	Variable currentWave = NMVarGet( "CurrentWave" )
	
	Variable numStimWaves = NumVarOrDefault( sdf+"NumStimWaves", 1 )
	Variable numStimReps = NumVarOrDefault( sdf+"NumStimReps", 1 )
		
	Variable nwaves = numStimWaves * numStimReps
	
	if ((chan < 0) || (numtype(chan*slope*offset) > 0))
		return -1
	endif
	
	telValue = ClampReadManager(StrVarOrDefault(cdf+"AcqBoard", ""), driver, chan, 1, 50)
	
	telValue = telValue * slope + offset
	
	if (WaveExists($"CT_Temp") == 0)
		Make /N=(nwaves) CT_Temp = Nan
	endif
	
	if (numpnts(CT_Temp) != nwaves)
		Redimension /N=(nwaves) CT_Temp
	endif
	
	if (currentWave >= nwaves)
		Redimension /N=(currentWave+1) CT_Temp
	endif
	
	Wave CT_Temp
	
	CT_Temp = Zero2Nan(CT_Temp)
	
	if (currentWave == 0)
		CT_Temp = Nan
	endif
	
	CT_Temp[ currentWave ] = telValue
	
	WaveStats /Q CT_Temp
	
	NMNotesFileVar("F_Temp", V_avg)
	
End // TempRead

//****************************************************************
//
//	ModelCell()
//	simulate a neuron using RC circuit in Demo Mode
//
//****************************************************************

Function ModelCell( mode )
	Variable mode // see definition at top
	
	String clampMode, sdf = StimDF()
	
	Variable demo = NumVarOrDefault( NMClampDF + "DemoMode", 0 )
	
	switch( mode )
	
		case 0: // run
			break
			
		case 1: // config
			ModelCellConfig( 1 )
			return 0
		
		case 2: // init
			ModelCellConfig( 0 )
			return 0
			
		case -1: // kill
			ClampUtilityKill( "MCell" )
			return 0
			
		default:
			return 0
			
	endswitch
	
	if ( !demo )
		return 0
	endif
	
	clampMode = StrVarOrDefault( sdf+"MCell_ClampMode", "" )
	
	strswitch( clampMode )
	
		case "CurrentClamp":
			ModelCell_RunIclamp()
			break
			
		case "VoltageClamp":
			ModelCell_RunVclamp()
			break
	
	endswitch
	
	return 0
	
End // ModelCell

//****************************************************************
//****************************************************************
//****************************************************************

Static Function ModelCellConfig( userInput )
	Variable userInput // ( 0 ) no ( 1 ) yes
	
	String ADCstr, DACstr, ADCunits, DACunits, clampMode = ""
	String cdf = NMClampDF, sdf = StimDF(), bdf = NMStimBoardDF( sdf )
	
	String ADClist = NMStimBoardOnList( "", "ADC" )
	String DAClist = NMStimBoardOnList( "", "DAC" )
	
	Variable ADCcount = ItemsInList( ADClist )
	Variable DACcount = ItemsInList( DAClist )
	
	if ( ADCcount == 0 )
		//ClampError( "No ADC input channels to measure." )
		Print "ModelCell error: no ADC input channels."
		return 0
	endif
	
	if ( DACcount == 0 )
		//ClampError( "No DAC output channels to measure." )
		Print "ModelCell error: no DAC output channels."
		return 0
	endif
	
	Variable ADCconfig = str2num( StringFromList( 0, ADClist ) )
	Variable DACconfig = str2num( StringFromList( 0, DAClist ) )
	
	ADCconfig = NumVarOrDefault( sdf+"MCell_ADC", ADCconfig )
	DACconfig = NumVarOrDefault( sdf+"MCell_DAC", DACconfig )
	
	Variable Cm = NumVarOrDefault( sdf+"MCell_Cm", 3 ) // pF
	Variable Rm = NumVarOrDefault( sdf+"MCell_Rm", 1 ) // GigaOhms
	
	Variable V0 = NumVarOrDefault( sdf+"MCell_V0", -80 ) // mV
	Variable AP_On = NumVarOrDefault( sdf + "MCell_AP_On", 1 )
	Variable AP_Threshold = NumVarOrDefault( sdf + "MCell_AP_Threshold", -40 ) // mV
	Variable AP_Peak = NumVarOrDefault( sdf + "MCell_AP_Peak", 40 ) // mV
	Variable AP_Reset = NumVarOrDefault( sdf + "MCell_AP_Reset", -60 ) // mV
	Variable AP_Refrac = NumVarOrDefault( sdf + "MCell_AP_Refrac", 1 ) // ms

	if ( userInput )
	
		ADCstr = num2istr( ADCconfig )
		DACstr = num2istr( DACconfig )

		Prompt ADCstr, "ADC input config to represent membrane:", popup ADClist
		Prompt DACstr, "DAC output config for clamp stimulus:", popup DAClist
		Prompt Cm, "membrane capacitance (pF):"
		Prompt Rm, "membrane resistance (GigaOhms):"
		DoPrompt "Model Cell", ADCstr, DACstr, Cm, Rm
		
		if ( V_flag == 1 )
			return 0 // cancel
		endif
		
		ADCconfig = str2num( ADCstr )
		DACconfig = str2num( DACstr )
		
		SetNMvar( sdf+"MCell_ADC", ADCconfig )
		SetNMvar( sdf+"MCell_DAC", DACconfig )
		SetNMvar( sdf+"MCell_Cm", Cm )
		SetNMvar( sdf+"MCell_Rm", Rm )
	
	endif
	
	Wave /T unitsADC = $( bdf+"ADCunits" )
	Wave /T unitsDAC = $( bdf+"DACunits" )
	
	if ( ( ADCconfig >= 0 ) && ( ADCconfig < numpnts( unitsADC ) ) )
		ADCunits = unitsADC[ ADCconfig ]
	else
		return 0
	endif
	
	if ( ( DACconfig >= 0 ) && ( DACconfig < numpnts( unitsDAC ) ) )
		DACunits = unitsDAC[ DACconfig ]
	else
		return 0
	endif
	
	if ( StringMatch( ADCunits, "mV" ) )
	
		if ( StringMatch( DACunits, "pA" ) )
			clampMode = "CurrentClamp"
		else
			Print "ModelCell error: unfamiliar DAC units: " + DACunits
		endif
	
	elseif ( StringMatch( ADCunits, "pA" ) )
	
		if ( StringMatch( DACunits, "mV" ) )
			clampMode = "VoltageClamp"
		else
			Print "ModelCell error: unfamiliar DAC units: " + DACunits
		endif
	
	else
	
		Print "ModelCell error: unfamiliar ADC units: " + ADCunits
		
	endif
	
	if ( strlen( clampMode )  == 0 )
	
		NMDoAlert( "To run NM ModelCell function, voltage units need to be mV and current units need to be pA" )
	
	endif
	
	SetNMstr( sdf+"MCell_ClampMode", clampMode )
	
	if ( userInput )
	
		if ( StringMatch( clampMode, "CurrentClamp" ) )
		
			AP_On += 1
		
			Prompt V0, "membrane resting potential (mV):"
			Prompt AP_On, "generate action potentials?", popup "no;yes;"
			DoPrompt "Model Cell", V0, AP_On
			
			if ( V_flag == 1 )
				return 0 // cancel
			endif
			
			AP_On -= 1
			
			SetNMvar( sdf+"MCell_V0", V0 )
			SetNMvar( sdf+"MCell_AP_On", AP_On )
			
			if ( AP_On )
			
				Prompt AP_Threshold, "AP threshold (mV):"
				Prompt AP_Peak, "AP peak (mV):"
				Prompt AP_Reset, "AP reset (mV):"
				Prompt AP_Refrac, "AP refractory period (ms):"
				
				DoPrompt "Model Cell", AP_Threshold, AP_Peak, AP_Reset, AP_Refrac
			
				if ( V_flag == 1 )
					return 0 // cancel
				endif
				
				SetNMvar( sdf+"MCell_AP_Threshold", AP_Threshold )
				SetNMvar( sdf+"MCell_AP_Peak", AP_Peak )
				SetNMvar( sdf+"MCell_AP_Reset", AP_Reset )
				SetNMvar( sdf+"MCell_AP_Refrac", AP_Refrac )
			
			endif
			
		elseif ( StringMatch( clampMode, "VoltageClamp" ) )
		
			Prompt V0, "holding potential (mV):"
			DoPrompt "Model Cell", V0
			
			if ( V_flag == 1 )
				return 0 // cancel
			endif
			
			SetNMvar( sdf+"MCell_V0", V0 )
	
		endif
		
	endif
	
End // ModelCellConfig

//****************************************************************
//****************************************************************
//****************************************************************

Function ModelCell_InputChan()

	String sdf = StimDF()
	
	String ADClist = NMStimBoardOnList( "", "ADC" )

	Variable ADCconfig = NumVarOrDefault( sdf+"MCell_ADC", NaN )

	Variable chan = WhichListItem( num2istr( ADCconfig ), ADClist, ";" )
	
	return chan
	
End // ModelCell_InputChan

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ModelCell_OutputName()

	String sdf = StimDF()

	Variable DACconfig = NumVarOrDefault( sdf+"MCell_DAC", NaN )
	
	Variable grp = NumVarOrDefault( NMClampDF + "CurrentGrp", NaN )
	
	if ( numtype( DACconfig * grp ) > 0 )
		return ""
	endif

	return sdf + "DAC_" + num2istr( DACconfig ) + "_" + num2istr( grp )
	
End // ModelCell_OutputName

//****************************************************************
//****************************************************************
//****************************************************************

Function ModelCell_RunIclamp()

	Variable icnt, rpnts, p1, p2, pSpike, chan, mode, waveNum
	String wName, dName, sdf = StimDF()
	
	String outputName = ModelCell_OutputName()
	
	if ( strlen( outputName ) == 0 )
		return 0
	endif
	
	Variable V0 = NumVarOrDefault( sdf + "MCell_V0", NaN )
	
	Variable AP_On = NumVarOrDefault( sdf + "MCell_AP_On", NaN )
	Variable AP_Threshold = NumVarOrDefault( sdf + "MCell_AP_Threshold", NaN )
	Variable AP_Peak = NumVarOrDefault( sdf + "MCell_AP_Peak", NaN )
	Variable AP_Reset = NumVarOrDefault( sdf + "MCell_AP_Reset", NaN )
	Variable AP_Refrac = NumVarOrDefault( sdf + "MCell_AP_Refrac", NaN )
	
	Variable dt = deltax( $outputName )
	Variable npnts = numpnts( $outputName )
	
	Make /D/O/N=1 ModelCell_PP = 0 // not used
	
	Make /O/N=( 4, 1 ) ModelCell_Stop
	
	ModelCell_Stop[ 0 ][ 0 ] = 1
	ModelCell_Stop[ 1 ][ 0 ] = AP_Threshold
	ModelCell_Stop[ 2 ][ 0 ] = 0
	ModelCell_Stop[ 3 ][ 0 ] = 0
	
	wName = "Model_States"
	
	Make /O/N=( npnts, 1 ) $wName = NaN
	SetScale /P x 0, dt, $wName
	
	Wave States = $wName
	
	SetDimLabel 1, 0, Vmem, States
	
	States[ 0 ][ %Vmem ] = V0
	
	p1 = 0
	p2 = npnts - 1
	
	rpnts = 1 + AP_Refrac / dt
	
	do
	
		if ( AP_On )
		
			IntegrateODE /Q/R=[ p1, p2 ] /STOP={ ModelCell_Stop, 0 } ModelCell_DYDT, ModelCell_PP, States
		
			if ( V_Flag == 8 ) // spike here
			
				pSpike = V_ODEStepCompleted + 1
				
				States[ pSpike ][ 0 ] = AP_Peak
				States[ pSpike + 1, pSpike + rpnts ][ 0 ] = AP_Reset
				
				p1 = pSpike + rpnts // skip refractory period
			
			else
				
				break // no spikes
			
			endif
		
		else
		
			IntegrateODE /Q ModelCell_DYDT, ModelCell_PP, States
			
			break
		
		endif
	
	while ( p1 < npnts )
	
	chan = ModelCell_InputChan()
	mode = NumVarOrDefault( NMClampDF + "PreviewOrRecord", NaN )
	
	if ( mode == 0 )
		waveNum = 0
	else
		waveNum = CurrentNMWave()
	endif
	
	wName = GetWaveName( "default", chan, waveNum )
	dName = ChanDisplayWave( chan )
	
	if ( WaveExists( $wName ) )
	
		Wave wtemp = $wName
		Wave dtemp = $dName
		
		for ( icnt = 0 ; icnt < npnts ; icnt += 1 )
			wtemp[ icnt ] = States[ icnt ][ 0 ]
		endfor
		
		dtemp = wtemp
		
	endif
	
	KillWaves /Z ModelCell_PP, ModelCell_Stop
	KillWaves /Z States

End // ModelCell_RunIclamp

//****************************************************************
//****************************************************************
//****************************************************************

Function ModelCell_RunVclamp()

	Variable icnt, dt, npnts, error
	String wName, state, fxn, sdf = StimDF()
	
	String outputName = ModelCell_OutputName()
	
	if ( strlen( outputName ) == 0 )
		return 0
	endif
	
	Variable V0 = NumVarOrDefault( sdf + "MCell_V0", NaN )
	
	Wave vClamp = $outputName
	
	dt = deltax( vClamp )
	npnts = numpnts( vClamp )
	
	Make /D/O/N=1 ModelCell_PP = 0 // contains nothing
	
	wName = "Model_States"
	
	Make /O/N=( npnts, 1 ) $wName = NaN
	SetScale /P x 0, dt, $wName
	
	Wave States = $wName
	
	SetDimLabel 1, 0, Vmem, States
	
	States[ 0 ][ %Vmem ] = vClamp[ 0 ]
	
	IntegrateODE /Q ModelCell_DYDT, ModelCell_PP, States
	
	KillWaves /Z ModelCell_PP

End // ModelCell_RunVclamp

//****************************************************************
//****************************************************************
//****************************************************************

Function ModelCell_DYDT( pw, tt, yw, dydt )
	Wave pw	// parameter wave, NOT USED
	Variable tt	// time
	Wave yw	// voltage wave
	Wave dydt	// voltage derivative wave
	
	Variable v, dt, timePoint, isum = NaN
	String sdf = StimDF()
	
	String outputName = ModelCell_OutputName()
	
	String clampMode = StrVarOrDefault( sdf+"MCell_ClampMode", "" )
	
	Variable Cm = NumVarOrDefault( sdf+"MCell_Cm", NaN ) // pF
	Variable Rm = NumVarOrDefault( sdf+"MCell_Rm", NaN ) // GigaOhms
	Variable V0 = NumVarOrDefault( sdf+"MCell_V0", NaN ) // mV
	
	Wave clamp = $outputName
	
	dt = deltax( clamp )
	
	timePoint = tt / dt
	
	if ( ( timePoint >= 0 ) && ( timePoint >= numpnts( clamp ) ) )
	
		strswitch( clampMode )
		
			case "CurrentClamp":
				
				if ( 0 < numpnts( yw ) )
				
					v = yw[ 0 ]
	
					isum = ( ( v - V0 ) / Rm ) - clamp[ timePoint ]
					
				endif
				
				break
				
			case "VoltageClamp":
			
				v = clamp[ timePoint ]
				
				break
				
			default:
			
				isum = NaN
		
		endswitch
		
	endif
	
	if ( 0 < numpnts( dydt ) )
		dydt[ 0 ] = -isum / Cm
	endif
	
	//if ( v > 0 )
	//	return 1
	//endif
	
	//return 0
	
End // ModelCell_DYDT

//****************************************************************
//
//	Rstep()
//	measure resistance of voltage/current step
//
//****************************************************************

Function Rstep( mode )
	Variable mode // see definition at top
	
	Variable icnt, numWindows
	String sdf = StimDF()
	
	switch( mode )
	
		case 0: // run
			break
			
		case 1: // config
			RstepConfig( 1 )
			return 0
		
		case 2: // init
			RstepConfig( 0 )
			return 0
			
		case -1: // kill
			ClampUtilityKill( "Rstep" )
			return 0
			
		default:
			return 0
			
	endswitch
	
	numWindows = NumVarOrDefault( sdf+"RstepNumWindows", 1 )
	
	if ( numWindows < 1 )
		return 0
	endif
	
	for ( icnt = 1 ; icnt <= numWindows ; icnt += 1 )
		RstepCompute( icnt )
	endfor
	
End // Rstep

//****************************************************************
//****************************************************************
//****************************************************************

Static Function RstepCompute( winNum )
	Variable winNum // 1, 2, 3...
	
	Variable chan, base, output, input, tscale = 1
	Variable /G CT_R_Electrode
	
	String outName, inName, gname, winStr, tagName
	String cdf = NMClampDF, sdf = StimDF()
	
	if ( winNum > 1 )
		winStr = num2str( winNum )
	else
		winStr = ""
	endif
	
	Variable ADCconfig = NumVarOrDefault( sdf+"RstepADC" + winStr, Nan )
	Variable DACconfig = NumVarOrDefault( sdf+"RstepDAC" + winStr, Nan )
	Variable tbgn = NumVarOrDefault( sdf+"RstepTbgn" + winStr, Nan )
	Variable tend = NumVarOrDefault( sdf+"RstepTend" + winStr, Nan )
	Variable scale = NumVarOrDefault( sdf+"RstepScale" + winStr, Nan )
	
	String board = StrVarOrDefault( cdf+"AcqBoard", "" )
	
	if ( numtype( ADCconfig*DACconfig*tbgn*tend*scale ) > 0 )
		return 0
	endif
	
	String ADClist = NMStimBoardOnList( "", "ADC" )
	
	Variable grp =  NumVarOrDefault( NMClampDF + "CurrentGrp", NaN )
	
	outName = sdf + "DAC_" + num2istr( DACconfig ) + "_" + num2istr( grp )
	
	chan = WhichListItem( num2istr( ADCconfig ), ADClist, ";" )
	
	//inName = GetWaveName( "default", chan, 0 )
	inName = ChanDisplayWave( chan )
	
	if ( ( WaveExists( $outName ) == 0 ) || ( WaveExists( $inName ) == 0 ) )
		return -1
	endif
	
	if ( StringMatch( board, "NIDAQ" ) == 1 )
		tscale = 0.001 // convert to seconds for NIDAQ boards
	endif
	
	WaveStats /Q/R=( 0*tscale,2*tscale ) $outName
	
	base = V_avg
	
	WaveStats /Q/R=( tbgn*tscale, tend*tscale ) $outName
	
	output = abs( V_avg - base )
	
	WaveStats /Q/R=( 0,1 ) $inName
	
	base = V_avg
	
	WaveStats /Q/R=( tbgn, tend ) $inName
	
	input = abs( V_avg - base )
	
	if ( scale < 0 )
		CT_R_Electrode = -1 * output * scale / input
	else
		CT_R_Electrode = input * scale / output
	endif
	
	CT_R_Electrode = round( CT_R_Electrode * 100 ) / 100
	
	gName = ChanGraphName( chan )
	outName = GetWaveName( "Display", chan, 0 )
	
	tagName = "Rtag" + winStr
	
	Tag /C/W=$gname/N=$tagName bottom, tend, num2str( CT_R_Electrode ) + " Mohms"
	
	NMNotesFileVar( "F_Relectrode" + winStr, CT_R_Electrode )
	
End // RstepCompute

//****************************************************************
//****************************************************************
//****************************************************************

Static Function RstepConfig( userInput )
	Variable userInput // ( 0 ) no ( 1 ) yes
	
	Variable icnt, numWindows
	String cdf = NMClampDF, sdf = StimDF(), bdf = NMStimBoardDF( sdf )
	
	String ADClist = NMStimBoardOnList( "", "ADC" )
	String DAClist = NMStimBoardOnList( "", "DAC" )
	
	Variable ADCcount = ItemsInList( ADClist )
	Variable DACcount = ItemsInList( DAClist )
	
	if ( ADCcount == 0 )
		//ClampError( "No ADC input channels to measure." )
		Print "Rstep Error: no ADC input channels to measure."
		return 0
	endif
	
	if ( DACcount == 0 )
		//ClampError( "No DAC output channels to measure." )
		Print "Rstep Error: no DAC output channels to measure."
		return 0
	endif
	
	numWindows = NumVarOrDefault( sdf+"RstepNumWindows", 1 )
	
	if ( userInput )
	
		Prompt numWindows, "number of Rstep measurements to compute:"
		DoPrompt "Compute Resistance", numWindows
		
		if ( V_flag == 1 )
			return 0 // cancel
		endif
		
		SetNMvar( sdf+"RstepNumWindows", numWindows )
	
	endif
	
	for ( icnt = 1 ; icnt <= numWindows ; icnt += 1 )
		RstepConfig2( userInput, icnt )
	endfor
	
End // RstepConfig

//****************************************************************
//****************************************************************
//****************************************************************

Static Function RstepConfig2( userInput, winNum )
	Variable userInput // ( 0 ) no ( 1 ) yes
	Variable winNum // 1, 2, 3...
	
	Variable icnt, onset, width
	String ADCstr, DACstr, ADCunit, DACunit, winStr, wName
	String sdf = StimDF(), bdf = NMStimBoardDF( sdf )
	
	if ( winNum > 1 )
		winStr = num2str( winNum )
	else
		winStr = ""
	endif
	
	String ADClist = NMStimBoardOnList( "", "ADC" )
	String DAClist = NMStimBoardOnList( "", "DAC" )
	
	Variable ADCconfig = str2num( StringFromList( winNum - 1, ADClist ) )
	Variable DACconfig = str2num( StringFromList( winNum - 1, DAClist ) )
	
	ADCconfig = NumVarOrDefault( sdf+"RstepADC" + winStr, ADCconfig )
	DACconfig = NumVarOrDefault( sdf+"RstepDAC" + winStr, DACconfig )
	
	Variable tbgn = NumVarOrDefault( sdf+"RstepTbgn" + winStr, NaN )
	Variable tend = NumVarOrDefault( sdf+"RstepTend" + winStr, NaN )
	Variable scale = NumVarOrDefault( sdf+"RstepScale" + winStr, 1 )

	if ( userInput )
	
		ADCstr = num2istr( ADCconfig )
		DACstr = num2istr( DACconfig )

		Prompt ADCstr, "ADC input configuration to measure:", popup ADClist
		Prompt DACstr, "DAC output configuration to measure:", popup DAClist
		Prompt tbgn, "measure time begin (ms):"
		Prompt tend, "measure time end (ms):"
		DoPrompt "Compute Resistance Window #" + num2str( winNum ), ADCstr, DACstr
		
		if ( V_flag == 1 )
			return 0 // cancel
		endif
		
		ADCconfig = str2num( ADCstr )
		DACconfig = str2num( DACstr )
		
		SetNMvar( sdf+"RstepADC" + winStr, ADCconfig )
		SetNMvar( sdf+"RstepDAC" + winStr, DACconfig )
		
		if ( numtype( tbgn * tend ) > 0 )
		
			wName = PulseWaveName( sdf, "DAC_" + DACstr )
			
			if ( WaveExists( $wName ) && ( numpnts( $wName ) > 8 ) )
			
				Wave wtemp = $wName
				
				onset = wtemp[ 4 ]
				width = wtemp[ 8 ]
				
				tend = onset + width
				tbgn = tend - 10
				
				if ( tbgn < onset )
					tbgn = ( onset + tend ) / 2
				endif
			
			endif
		
		endif
		
		DoPrompt "Compute Resistance Window #" + num2str( winNum ), tbgn, tend
		
		if ( V_flag == 1 )
			return 0 // cancel
		endif
		
		SetNMvar( sdf+"RstepTbgn" + winStr, tbgn )
		SetNMvar( sdf+"RstepTend" + winStr, tend )
	
	endif
	
	SetNMvar( sdf+"RstepScale", NaN )
	
	Wave DACscale = $( bdf+"DACscale" )
	
	Wave /T ADCunits = $( bdf+"ADCunits" )
	Wave /T DACunits = $( bdf+"DACunits" )
	
	if ( ( ADCconfig >= 0 ) && ( ADCconfig < numpnts( ADCunits ) ) )
		ADCstr = ADCunits[ ADCconfig ]
	else
		ADCstr = ""
	endif
	
	if ( ( DACconfig >= 0 ) && ( DACconfig < numpnts( DACunits ) ) )
		DACstr = DACunits[ DACconfig ]
	else
		DACstr = ""
	endif
	
	if ( strlen( ADCstr ) == 0 )
		Print "Rstep Error: win #" + num2str( winNum ) + ": no ADC units"
		return 0
	endif
	
	if ( strlen( DACstr ) == 0 )
		Print "Rstep Error: win #" + num2str( winNum ) + ": no DAC units"
		return 0
	endif
	
	icnt = strlen( ADCstr ) - 1
	
	ADCunit = ADCstr[ icnt, icnt ]
	DACunit = DACstr[ icnt, icnt ]
	
	if ( ( StringMatch( ADCunit,"A" ) == 1 ) && ( StringMatch( DACunit,"V" ) == 1 ) )
		scale = -1
	elseif ( ( StringMatch( ADCunit,"V" ) == 1 ) && ( StringMatch( DACunit,"A" ) == 1 ) )
		scale = 1
	else
		Print "Rstep Error: win #" + num2str( winNum ) + ": cannot compute resistance from ADC units (" + ADCunit + ") and DAC units (" + DACunit + ")"
		return 0
	endif
	
	ADCunit = ""
	DACunit = ""
	
	if ( strlen( ADCstr ) > 1 )
		ADCunit = ADCstr[ 0, 0 ]
	endif
	
	if ( strlen( DACstr ) > 1 )
		DACunit = DACstr[ 0, 0 ]
	endif
	
	if ( scale == 1 ) // compute appropriate scale to get Mohms
		scale *= 1e-6 * MetricValue( ADCunit ) / ( MetricValue( DACunit ) * DACscale[ DACconfig ] )
	else
		scale *= 1e-6 * MetricValue( DACunit ) * DACscale[ DACconfig ] / MetricValue( ADCunit )
	endif
	
	SetNMvar( sdf+"RstepScale" + winStr, scale )

End // RstepConfig2

//****************************************************************
//
//	RCstep()
//	measure resistance and capacitence of cell membrane
//
//****************************************************************

Function RCstep( mode )
	Variable mode // see definition at top
	
	Variable icnt, numWindows
	String sdf = StimDF()
	
	switch( mode )
	
		case 0: // run
			break
	
		case 1: // config
			RCstepConfig( 1 )
			return 0
		
		case 2: // init
			RCstepConfig( 0 )
			return 0
			
		case -1: // kill
			ClampUtilityKill( "RCstep" )
			return 0
			
		default:
			return 0
			
	endswitch
	
	numWindows = NumVarOrDefault( sdf+"RCstepNumWindows", 1 )
	
	if ( numWindows < 1 )
		return 0
	endif
	
	for ( icnt = 1 ; icnt <= numWindows ; icnt += 1 )
		RCstepCompute( icnt )
	endfor
	
End // RCstep

//****************************************************************
//****************************************************************
//****************************************************************

Static Function RCstepCompute( winNum )
	Variable winNum // 1, 2, 3...
	
	//Variable toffset = 0.02 // time after step to start curve fit
	
	Variable icnt, fbgn, fend, nwaves, numStimWaves, numStimReps
	Variable chan, base, vstep, input, tbase, tscale = 1, negstep = 0
	Variable Ipeak, Iss, tau, Rp, Rm, Cm
	
	String outName, inName, inName2, gname, winStr
	String wName, wList
	String cdf = NMClampDF, sdf = StimDF()
	
	Variable currentWave = NMVarGet( "CurrentWave" )
	Variable grp =  NumVarOrDefault( NMClampDF + "CurrentGrp", NaN )
	
	if ( winNum > 1 )
		winStr = num2str( winNum )
	else
		winStr = ""
	endif
	
	Variable ADCconfig = NumVarOrDefault( sdf+"RCstepADC" + winStr, Nan )
	Variable DACconfig = NumVarOrDefault( sdf+"RCstepDAC" + winStr, Nan )
	Variable tbgn = NumVarOrDefault( sdf+"RCstepTbgn" + winStr, Nan )
	Variable tend = NumVarOrDefault( sdf+"RCstepTend" + winStr, Nan )
	Variable scale = NumVarOrDefault( sdf+"RCstepScale" + winStr, Nan )
	
	Variable dsply = NumVarOrDefault( sdf+"RCstepDisplay" + winStr, 1 )
	
	String ADClist = NMStimBoardOnList( "", "ADC" )
	String board = StrVarOrDefault( cdf+"AcqBoard", "" )
	
	if ( numtype( ADCconfig*DACconfig*tbgn*tend*scale ) > 0 )
		return 0 // bad parameters
	endif
	
	if ( StringMatch( board, "NIDAQ" ) == 1 )
		tscale = 0.001 // convert to seconds for NIDAQ boards
	endif
	
	if ( currentWave == 0 )
	
		numStimWaves = NumVarOrDefault( sdf+"NumStimWaves", 1 )
		numStimReps = NumVarOrDefault( sdf+"NumStimReps", 1 )
		
		nwaves = numStimWaves * numStimReps
		
		Make /O/N=( nwaves ) CT_Cm = NaN
		Make /O/N=( nwaves ) CT_Rm = NaN
		Make /O/N=( nwaves ) CT_Rp = NaN
		
	else
	
		Wave CT_Cm, CT_Rm, CT_Rp
		
	endif
	
	outName = sdf + "DAC_" + num2istr( DACconfig ) + "_" + num2istr( grp )
	
	chan = WhichListItem( num2istr( ADCconfig ), ADClist, ";" )
	
	inName = ChanDisplayWave( chan )
	
	if ( ( WaveExists( $outName ) == 0 ) || ( WaveExists( $inName ) == 0 ) )
		return -1
	endif
	
	tbase = tbgn - 0.5
	
	WaveStats /Q/R=( 0, tbase*tscale ) $outName // baseline
	
	base = V_avg // should be zero
	
	WaveStats /Q/R=( tbgn*tscale, tend*tscale ) $outName
	
	vstep = abs( V_avg - base )
	
	if ( V_avg < base )
		negstep = 1
	endif
	
	WaveStats /Q/R=( tbgn*tscale, tend*tscale ) $inName
	
	//if ( negstep == 1 )
	//	fbgn = V_minloc + toffset
	//else
	//	fbgn = V_maxloc + toffset
	//endif
	
	fbgn = tbgn //+ toffset
	fend = tend
	
	gName = ChanGraphName( chan )
	inName2 = GetWaveName( "Display", chan, 0 )
	
	// prepare graph and do curve fit
	
	DoWindow /F $gName
	
	//if ( currentWave == 0 )
		//ShowInfo /W=$gName
		//Cursor /W=$gName A, $inName2, fbgn
		//Cursor /W=$gName B, $inName2, fend
	//endif
	
	Wave wtemp = $ChanDisplayWave( chan )
	
	WaveStats /Q/R=( 0, tbase ) wtemp // baseline
	
	base = V_avg
	
	if ( WaveExists( $"RCparams" ) == 0 )
		Make /N=4 RCparams
	endif
	
	Wave RCparams
	
	RCparams[ 0 ] = tbgn
	RCparams[ 1 ] = V_avg
	RCparams[ 3 ] = ( fend - fbgn ) / 4
	
	if ( negstep == 1 )
		RCparams[ 2 ] = V_min // probably a negative transient
	else
		RCparams[ 2 ] = V_max // probably a positive transient
	endif
	
	Variable /G V_fitOptions = 4 // suppress fit display
	Variable /G V_FitError = 0 // prevents procedure aborts from error
	String /G S_Info = ""
	
	FuncFit /Q/W=0/H="1000"/N RCfit RCparams wtemp( fbgn, fend ) /D
	
	if ( ( V_FitError == 0 ) && ( strlen( S_Info ) > 0 ) )
	
		Ipeak = abs( RCparams[ 1 ] + RCparams[ 2 ] - base )
		Iss = abs( RCparams[ 1 ] - base )
		tau = 1 / RCparams[ 3 ]
		
		Rp = Vstep * scale / Ipeak // recording pipette
		Rm = ( Vstep * scale / Iss ) - Rp // membrane resistance
		Cm = ( tau / 0.001 ) * ( 1 / Rp + 1 / Rm ) // membrane cap
	
	else
	
		wList = WaveList( "fit_Display*", ";", "" )
		
		for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
		
			wName = StringFromList( icnt, wList )
			Wave wtemp = $wName
			wtemp = NaN
			
		endfor
	
		Ipeak = NaN
		Iss = NaN
		tau = NaN
		Rp = NaN
		Rm = NaN
		Cm = NaN
	
	endif
	
	if ( ( CurrentWave >= 0 ) && ( CurrentWave < numpnts( CT_Rp ) ) )
		CT_Rp[ CurrentWave ] = Rp
		CT_Rm[ CurrentWave ] = Rm
		CT_Cm[ CurrentWave ] = Cm
	endif
	
	NMNotesFileVar( "F_Relectrode" + winStr, Rp )
	NMNotesFileVar( "F_Cm" + winStr, Cm )
	NMNotesFileVar( "F_Rm" + winStr, Rm )
	
	if ( dsply == 1 )
		Print NMCR + inName
		//Print "Ipeak = " + num2str( Ipeak )
		//Print "Iss = " + num2str( Iss )
		//Print "Tau = " + num2str( tau )
		Print "Rp = " + num2str( Rp )
		Print "Rm = " + num2str( Rm )
		Print "Cm = " + num2str( Cm )
	elseif ( dsply == 2 )
		RCstepDisplay()
	endif
	
End // RCstepCompute

//****************************************************************
//****************************************************************
//****************************************************************

Static Function RCstepDisplay()
	
	Variable num, inc = 10
	Variable currentWave = NMVarGet( "CurrentWave" )
	Variable numWaves
	
	String gName = "ClampRC"
	
	String cdf = NMClampDF, stdf = NMStatsDF
	
	if ( WaveExists( $"CT_Rm" ) == 0 )
		return -1
	endif
	
	if ( WinType( gName ) == 0 )
	
		Wave CT_Rp, CT_Rm, CT_Cm
	
		Display /K=1/N=$gName/W=( 0,0,200,100 ) CT_Rp, CT_Rm as "NeuroMatic RC Estimation"
		
		AppendToGraph /R=Cm /W=$gName CT_Cm
		
		Label /W=$gName bottom StrVarOrDefault( "WavePrefix", "Wave" )
		Label /W=$gName left "MOhm"
		Label /W=$gName Cm "pF"
		
		SetAxis /W=$gName bottom 0,10
		
		ModifyGraph /W=$gName mode=4
		ModifyGraph /W=$gName marker( CT_Rp )=5, rgb( CT_Rp )=( 0,0,39168 )
		ModifyGraph /W=$gName marker( CT_Rm )=16, rgb( CT_Rm )=( 0,0,39168 )
		ModifyGraph /W=$gName marker( CT_Cm )=19, rgb( CT_Cm )=( 65280,0,0 )
		
		ModifyGraph /W=$gName axRGB( Cm )=( 65280,0,0 ), alblRGB( Cm )=( 65280,0,0 )
		
		Legend/C/N=text0/A=LT
			
	endif
	
	if ( ( currentWave > 0 ) && ( WinType( gName ) == 1 ) )
		numWaves = numpnts( $"CT_Rm" )
		num = inc * ( 1 + floor( currentWave / inc ) )
		num = min( numwaves, num )
		SetAxis /Z/W=$gName bottom 0, num
	endif

End // RCstepDisplay

//****************************************************************
//****************************************************************
//****************************************************************

Function RCfit( w, x ) : FitFunc
	Wave w
	Variable x
	
	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f( x ) = Yss + Y0 * exp( -( x - X0 ) * invTau )
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 4
	//CurveFitDialog/ w[ 0 ] = X0
	//CurveFitDialog/ w[ 1 ] = Yss
	//CurveFitDialog/ w[ 2 ] = Y0
	//CurveFitDialog/ w[ 3 ] = invTau
	
	Variable y
	
	//if ( numpnts( w ) !=4 )
	//	return Nan
	//endif
	
	// w[ 0 ] = X0
	// w[ 1 ] = Yss
	// w[ 2 ] = Y0
	// w[ 3 ] = invTau
	
	y = w[ 1 ] + w[ 2 ] * exp( -( x - w[ 0 ] ) * w[ 3 ] )
	
	return y
	
	//if ( ( x < w[ 0 ] ) || ( numtype( y ) > 0 ) )
	//	return 0
	//else
		return y
	//endif
	
End // RCfit

//****************************************************************
//****************************************************************
//****************************************************************

Static Function RCstepConfig( userInput )
	Variable userInput // ( 0 ) no ( 1 ) yes
	
	Variable icnt, numWindows
	String sdf = StimDF()
	
	String ADClist = NMStimBoardOnList( "", "ADC" )
	String DAClist = NMStimBoardOnList( "", "DAC" )
	
	Variable ADCcount = ItemsInList( ADClist )
	Variable DACcount = ItemsInList( DAClist )
	
	if ( ADCcount == 0 )
		//ClampError( "No ADC input channels to measure." )
		Print "RCstep Error: no ADC input channels to measure."
		return 0
	endif
	
	if ( DACcount == 0 )
		//ClampError( "No DAC output channels to measure." )
		Print "RCstep Error: no DAC output channels to measure."
		return 0
	endif
	
	numWindows = NumVarOrDefault( sdf+"RCstepNumWindows", 1 )
	
	if ( userInput )
	
		Prompt numWindows, "number of RCstep measurements to compute:"
		DoPrompt "Compute Rm and Cm", numWindows
		
		if ( V_flag == 1 )
			return 0 // cancel
		endif
		
		SetNMvar( sdf+"RCstepNumWindows", numWindows )
	
	endif
	
	for ( icnt = 1 ; icnt <= numWindows ; icnt += 1 )
		RCstepConfig2( userInput, icnt )
	endfor
	
End // RCstepConfig
	
//****************************************************************
//****************************************************************
//****************************************************************

Static Function RCstepConfig2( userInput, winNum )
	Variable userInput // ( 0 ) no ( 1 ) yes
	Variable winNum // 1, 2, 3...
	
	Variable icnt, onset, width, scale = 1
	String ADCstr, DACstr, ADCunit, DACunit, winStr, wName
	String cdf = NMClampDF, sdf = StimDF(), bdf = NMStimBoardDF( sdf )
	
	if ( winNum > 1 )
		winStr = num2str( winNum )
	else
		winStr = ""
	endif
	
	String ADClist = NMStimBoardOnList( "", "ADC" )
	String DAClist = NMStimBoardOnList( "", "DAC" )
	
	Variable ADCconfig = str2num( StringFromList( winNum - 1, ADClist ) )
	Variable DACconfig = str2num( StringFromList( winNum - 1, DAClist ) )
	
	ADCconfig = NumVarOrDefault( sdf+"RCstepADC" + winStr, ADCconfig )
	DACconfig = NumVarOrDefault( sdf+"RCstepDAC" + winStr, DACconfig )
	
	Variable tbgn = NumVarOrDefault( sdf+"RCstepTbgn" + winStr, NaN )
	Variable tend = NumVarOrDefault( sdf+"RCstepTend" + winStr, NaN )
	
	Variable dsply = NumVarOrDefault( sdf+"RCstepDisplay" + winStr, 2 )
	
	if ( userInput )
	
		ADCstr = num2istr( ADCconfig )
		DACstr = num2istr( DACconfig )
	
		Prompt ADCstr, "ADC input configuration to measure:", popup ADClist
		Prompt DACstr, "DAC output configuration to measure:", popup DAClist
		Prompt tbgn, "exponential fit time begin (ms):"
		Prompt tend, "exponential fit time end (ms):"
		Prompt dsply, "display results in:", popup "Igor history;graph;"
		DoPrompt "Compute Rm and Cm Window #" + num2str( winNum ), ADCstr, DACstr, dsply
		
		if ( V_flag == 1 )
			return 0 // cancel
		endif
		
		ADCconfig = str2num( ADCstr )
		DACconfig = str2num( DACstr )
	
		SetNMvar( sdf+"RCstepADC" + winStr, ADCconfig )
		SetNMvar( sdf+"RCstepDAC" + winStr, DACconfig )
		SetNMvar( sdf+"RCstepDisplay" + winStr, dsply )
		
		if ( numtype( tbgn * tend ) > 0 )
		
			wName = PulseWaveName( sdf, "DAC_" + DACstr )
			
			if ( WaveExists( $wName ) && ( numpnts( $wName ) > 8 ) )
			
				Wave wtemp = $wName
				
				onset = wtemp[ 4 ]
				width = wtemp[ 8 ]
				
				tbgn = onset
				tend = onset + width
			
			endif
		
		endif
		
		DoPrompt "Compute Rm and Cm Window #" + num2str( winNum ), tbgn, tend
		
		if ( V_flag == 1 )
			return 0 // cancel
		endif
		
		SetNMvar( sdf+"RCstepTbgn" + winStr, tbgn )
		SetNMvar( sdf+"RCstepTend" + winStr, tend )
		
	endif
	
	Wave DACscale = $( bdf+"DACscale" )
	
	Wave /T ADCunits = $( bdf+"ADCunits" )
	Wave /T DACunits = $( bdf+"DACunits" )
	
	if ( ( ADCconfig >= 0 ) && ( ADCconfig < numpnts( ADCunits ) ) )
		ADCstr = ADCunits[ ADCconfig ]
	else
		ADCstr = ""
	endif
	
	if ( ( DACconfig >= 0 ) && ( DACconfig < numpnts( DACunits ) ) )
		DACstr = DACunits[ DACconfig ]
	else
		DACstr = ""
	endif
	
	if ( strlen( ADCstr ) == 0 )
		Print "Rstep Error: win #" + num2str( winNum ) + ": no ADC units"
		return 0
	endif
	
	if ( strlen( DACstr ) == 0 )
		Print "Rstep Error: win #" + num2str( winNum ) + ": no DAC units"
		return 0
	endif
	
	icnt = strlen( ADCstr ) - 1
	
	ADCunit = ADCstr[ icnt, icnt ]
	DACunit = DACstr[ icnt, icnt ]
	
	if ( ( StringMatch( ADCunit,"A" ) == 1 ) && ( StringMatch( DACunit,"V" ) == 1 ) )
	
		ADCunit = ""
		DACunit = ""
		
		if ( strlen( ADCstr ) > 1 )
			ADCunit = ADCstr[ 0, 0 ]
		endif
		
		if ( strlen( DACstr ) > 1 )
			DACunit = DACstr[ 0, 0 ]
		endif
		
		scale = 1e-6 * MetricValue( DACunit ) * DACscale[ DACconfig ] / MetricValue( ADCunit )
		
	else
	
		//DoAlert 0, "RCStep warning: input / output units do not appear to be correct. This function works only in voltage-clamp mode."
		Print "RCstep error: input / output units do not appear to be correct. This function works only in voltage-clamp mode."
		scale = 1
		
	endif
	
	SetNMvar( sdf+"RCstepScale" + winStr, scale )

End // RCstepConfig2

//****************************************************************
//
//	StatsRatio()
//	computes ratio of two Stats1 window measurements
//	add this function to inter-stim fxn execution list
//
//****************************************************************

Function StatsRatio(mode)
	Variable mode // see definition at top
	
	Variable currentWave
	
	String wname1, wname2, sdf = StimDF()
	
	String folder = CurrentNMStatsSubfolder()
	
	switch(mode)
	
		case 0:
			break
	
		case 1:
			return StatsRatioConfig()
	
		case -1:
			KillVariables /Z $(sdf+"StatsRatioNumer")
			KillVariables /Z $(sdf+"StatsRatioDenom")
			return 0
		
		case 2:
		default:
			return 0
			
	endswitch
	
	if ( NMStimStatsOn() == 0 )
		return -1 // Stats not on
	endif
	
	Variable n = NumVarOrDefault(sdf+"StatsRatioNumer", 0)
	Variable d = NumVarOrDefault(sdf+"StatsRatioDenom", 1)
	
	wname1 = StatsWaveName( folder, n, "AmpY", 0, 1, 1 )
	wname2 = StatsWaveName( folder, d, "AmpY", 0, 1, 1 )
	
	if ( ( WaveExists( $wname1 ) == 0 ) || ( WaveExists( $wname2 ) == 0 ) )
		return -1
	endif
	
	currentWave = NMVarGet( "CurrentWave" )
	
	Wave numer = $wname1
	Wave denom = $wname2
	
	if ( ( currentWave >= 0 ) && ( currentWave < numpnts( numer ) ) )
		numer[ currentWave ] = numer[ currentWave ] / denom[ currentWave ]
		denom[ currentWave ] = Nan
	endif
	
End // StatsRatio

//****************************************************************
//****************************************************************
//****************************************************************

Function StatsRatioConfig()

	String sdf = StimDF()
	
	Variable n = NumVarOrDefault(sdf+"StatsRatioNumer", 0) + 1
	Variable d = NumVarOrDefault(sdf+"StatsRatioDenom", 1) + 1
	
	Prompt n, "select Stats1 window for numerator:", popup "0;1;2;3;4;5;6;7;8;9;"
	Prompt d, "select Stats1 window for denominator:", popup "0;1;2;3;4;5;6;7;8;9;"
	DoPrompt "Online Stats Ratio", n, d
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	n -= 1
	d -= 1
	
	if ( n == d )
		DoAlert 0, "Warning: the same Stats1 window was chosen for the numberator and denominator: " + num2str( n )
	endif
	
	SetNMvar(sdf+"StatsRatioNumer", n )
	SetNMvar(sdf+"StatsRatioDenom", d )
	
	return 0

End // StatsRatioConfig

//****************************************************************
//****************************************************************
//****************************************************************

Function MetricValue( unitsMetric )
	String unitsMetric
	Variable char = char2num( unitsMetric )
	
	if ( strlen( unitsMetric ) == 0 )
		return 1
	endif
	
	switch( char )
	
		case 71: // "G"
			return 1e9
		case 77: // "M"
			return 1e6
		case 107: // "k"
			return 1e3
			
		case 99: // "c"
			return 1e-2
		case 109: // "m"
			return 1e-3
		case 117: // "u"
			return 1e-6
		case 110: // "n"
			return 1e-9
		case 112: // "p"
			return 1e-12
			
	endswitch
	
	return 1
	
End // MetricValue

//****************************************************************
//
//	RandomOrder()
//	Random DAC outputs
//
//****************************************************************

Function RandomOrder(mode)
	Variable mode // see definition at top
	
	Variable icnt, jcnt, pcnt, grpNum1, grpNum2, npnts, items, foundGrp
	String wName1, wName2, wNameTemp, wPrefix
	String sdf = StimDF()
	String plist = StimPrefixListAll( sdf )
	
	String grpStr, grpList = "", grpList2 = ""
	
	Variable numStimWaves = NumVarOrDefault( sdf + "NumStimWaves", 0 )
	Variable numStimReps = NumVarOrDefault( sdf + "NumStimReps", 0 )
	Variable currentWave = NumVarOrDefault( NMDF + "CurrentWave", 0 )
	
	Variable randomOrderReps = NumVarOrDefault( sdf + "RandomOrderReps", 1 )
	
	Variable randomize = 0
	Variable firstRep = 0
	Variable nextWave = currentWave + 1
	
	switch( mode )
	
		case -1: // kill
			// nothing to do
			return 0
	
		case 0: // run, called via ClampAcquireNext()
			
			// randomization needs to occur after acquisition of last group
			// this is when:
			// current wave, stim wave # = numStimReps - 1
			// next wave, stim wave # = 0
			
			if ( nextWave >= numStimWaves * numStimReps )
				return 0 // finished, no more reps
			endif
			
			if ( mod( nextWave, numStimWaves ) != 0 )
				return 0
			endif
			
			// next wave will be stim wave #0
			
			firstRep = 0
			
			if ( randomOrderReps )
				randomize = 1
			endif
			
			break // this mode runs after first repetition
			
		case 1: // config
			RandomOrderConfig()
			return 0
		
		case 2: // init, called via ClampAcquireStart()
			randomize = 1
			firstRep = 1
			break
			
		case 3: // finish
			StimWavesCheck(StimDF(), 1) // reset DAC order
			return 0
			
		default:
			return 0 // do nothing
			
	endswitch
	
	if ( mode == 2 ) // save original Group #s to DAC waves when initializing
	
		for ( icnt = 0; icnt < numStimWaves; icnt += 1 )
			for (pcnt = 0; pcnt < ItemsInList(plist); pcnt += 1)
			
				wPrefix = StringFromList(pcnt, plist)
				wName1 = wPrefix + "_" + num2str( icnt )
				
				grpNum1 = NMNoteVarByKey( sdf+wName1, "Group" )
				
				if ( numtype( grpNum1 ) > 0 )
					NMNoteVarReplace( sdf+wName1, "Group", icnt ) 
				endif
				
			endfor
		endfor
	
	endif
	
	// randomize group order
	
	if ( randomize )
	
		for ( icnt = 0; icnt < numStimWaves; icnt += 1 )
			grpList += num2istr( icnt ) + ";"
		endfor
		
		// randomize group list
			
		for ( icnt = 0; icnt < numStimWaves * 2; icnt += 1 )
		
			items = ItemsInList( grpList )
		
			if ( items == 0 )
				break // finished
			endif
			
			jcnt = floor( abs( enoise( items ) ) )
			grpStr = StringFromList( jcnt, grpList )
			grpList = RemoveListItem( jcnt, grpList )
			grpList2 += grpStr + ";"
			
		endfor
		
		if ( ItemsInList( grpList2 ) != numStimWaves )
			return -1
		endif
	
		// rename DAC waves with temporary names
		
		for ( icnt = 0; icnt < numStimWaves; icnt += 1 )
			for (pcnt = 0; pcnt < ItemsInList(plist); pcnt += 1)
			
				wPrefix = StringFromList(pcnt, plist)
				wName1 = wPrefix + "_" + num2str( icnt )
				wNameTemp = "x_" + wName1
				
				if ( WaveExists( $sdf+wName1 ) == 0 )
					Print "RandomOrder Error: wave does not exist: " + wName1
					return -1
				endif
				
				if ( WaveExists( $sdf+wNameTemp ) == 1 )
					KillWaves /Z $sdf+wNameTemp
				endif
				
				if ( WaveExists( $sdf+wNameTemp ) == 1 )
					Print "RandomOrder Error: wave cannot be deleted: " + wNameTemp
					return -1
				endif
				
				Rename $sdf+wName1, $wNameTemp
				
				if ( WaveExists( $sdf+wName1 ) == 1 )
					Print "RandomOrder Error: failed to rename " + wName1 + " to " + wNameTemp
					return -1
				endif
				
			endfor
		endfor
	
		// rename temporary waves using random sequence in grpList2
		
		for ( icnt = 0; icnt < numStimWaves; icnt += 1 )
		
			grpStr = StringFromList( icnt, grpList2 )
			grpNum2 = str2num( grpStr )
			
			for (pcnt = 0; pcnt < ItemsInList(plist); pcnt += 1)
			
				wPrefix = StringFromList(pcnt, plist)
				
				wName2 = wPrefix + "_" + num2str( icnt )
				
				foundGrp = 0
				
				for ( jcnt = 0; jcnt < numStimWaves; jcnt += 1 )
				
					wName1 = "x_" + wPrefix + "_" + num2str( jcnt )
					
					if ( !WaveExists( $sdf+wName1 ) )
						continue
					endif
					
					grpNum1 = NMNoteVarByKey( sdf+wName1, "Group" )
					
					if ( numtype( grpNum1 ) > 0 )
						Print "RandomOrder Error: failed to find group number for " + wName1
						return -1 
					endif
					
					if ( grpNum1 == grpNum2 )
						foundGrp = 1
						break
					endif
				
				endfor
				
				if ( !foundGrp )
					Print "RandomOrder Error: failed to find DAC wave for group #" + num2istr( grpNum2 )
					return -1
				endif
				
				if ( WaveExists( $sdf+wName1 ) == 0 )
					Print "RandomOrder Error: wave does not exist: " + wName1
					return -1
				endif
				
				if ( WaveExists( $sdf+wName2 ) == 1 )
					KillWaves /Z $sdf+wName2
				endif
				
				if ( WaveExists( $sdf+wName2 ) == 1 )
					Print "RandomOrder Error: wave cannot be deleted: " + wName2
					return -1
				endif
				
				Rename $sdf+wName1, $wName2
				
				if ( WaveExists( $sdf+wName1 ) == 1 )
					Print "RandomOrder Error: failed to rename " + wName1 + " to " + wName2
					return -1
				endif
				
			endfor
			
		endfor
		
	endif
	
	// configure Groups wave to save group #s
	
	wName2 = "Groups"
	
	if ( WaveExists( $wName2 ) )
	
		npnts = numpnts( $wName2 )
		
		if ( npnts != numStimWaves * numStimReps )
		
			Redimension /N=( numStimWaves * numStimReps ) $wName2
			
			Wave grps = $wName2
			
			for ( icnt = npnts ; icnt < numpnts( grps ) ; icnt += 1 )
				grps[ icnt ] = NaN
			endfor
			
		endif
		
	else
	
		Make /O/N=( numStimWaves * numStimReps ) $wName2 = NaN
		
	endif
	
	Wave grps = $wName2
	
	for ( icnt = 0; icnt < numStimWaves; icnt += 1 )
		
		pcnt = 0 // first one only
		
		wPrefix = StringFromList(pcnt, plist)
		wName1 = wPrefix + "_" + num2str( icnt )
		
		grpNum1 = NMNoteVarByKey( sdf+wName1, "Group" )
		
		if ( firstRep )
			grps[ icnt ] = grpNum1 // update Groups wave
		else
			grps[ icnt + nextWave ] = grpNum1 // update Groups wave
		endif
		
	endfor
	
	//RandomOrderSave( grpList2 ) // for testing randomness
	
	NMHistory( "Randomized DAC/TTL stim waves to group sequence: " + grpList2 )
	
	return 0
	
End // RandomOrder

//****************************************************************
//****************************************************************
//****************************************************************

Function RandomOrderSave( grpList ) // for testing randomness. Use lots of reps.
	String grpList

	Variable icnt, npnts
	String wName, grpStr
	
	String cdf = NMClampDF
	String sdf = StimDF()

	Variable numStimWaves = NumVarOrDefault( sdf + "NumStimWaves", 0 )
	
	for ( icnt = 0 ; icnt < numStimWaves ; icnt += 1 )
		
		wName = "CT_RO_" +  num2istr( icnt )
		
		if ( !WaveExists( $cdf + wName ) )
			Make /N=0 $cdf + wName = NaN
		endif
		
		Wave wtemp = $cdf + wName
		
		npnts = numpnts( wtemp )
		
		Redimension /N=( npnts + 1 ) wtemp
		
		grpStr = StringFromList( icnt, grpList )
		
		wtemp[ npnts ] = str2num( grpStr )
	
	endfor


End // RandomOrderSave

//****************************************************************
//****************************************************************
//****************************************************************

Function RandomOrderConfig()

	String sdf = StimDF()
	
	Variable reps = NumVarOrDefault( sdf + "RandomOrderReps", 1 )
	
	reps += 1
	
	Prompt reps, "select when to randomize stimulus waves:", popup "once at the start of acquisition;before each repetition;"
	DoPrompt "Random Order Configuration", reps
	
	if ( V_flag == 1 )
		return 0 // cancel
	endif
	
	reps -= 1
	
	SetNMvar( sdf+"RandomOrderReps", reps )

End // RandomOrderConfig

//****************************************************************
//****************************************************************
//****************************************************************
//
//
//	Igor-timed clock functions
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ClampWait(t)
	Variable t
	
	if (t == 0)
		return 0
	endif
	
	return ClampWaitMSTimer( t )
	
End // ClampWait

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampWaitTicks(t) // wait t msec (only accurate to 17 msec)
	Variable t
	
	if (t == 0)
		return 0
	endif
	
	Variable t0 = ticks
	
	t *= 60 / 1000

	do
	while ((NMProgressCancel() == 0) && (ticks - t0 < t ))
	
	return 0
	
End // ClampWaitTicks

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampWaitMSTimer( t ) // wait t msec ( this is more accurate )
	Variable t
	
	if ( t <= 0 )
		return 0
	endif
	
	Variable dt, t0 = stopMSTimer( -2 )
	
	do
		dt = ( stopMSTimer( -2 ) - t0 ) / 1000 // msec
	while ( ( NMProgressCancel() == 0 ) && ( dt < t ) )
	
	return 0
	
End // ClampWaitMSTimer

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampWaitProgress( t ) // wait t msec ( this is more accurate )
	Variable t
	
	if ( t <= 0 )
		return 0
	endif
	
	Variable dt, t0 = stopMSTimer( -2 )
	
	NMProgressCall( -1, "Waiting " + num2str( t ) + " ms" )
	
	do
		dt = ( stopMSTimer( -2 ) - t0 ) / 1000 // msec
		NMProgressCall( -2, "Waiting " + num2str( t ) + " ms" )
	while ( ( NMProgressCancel() == 0 ) && ( dt < t ) )
	
	NMProgressKill()
	
	return 0
	
End // ClampWaitProgress

//****************************************************************
//****************************************************************
//****************************************************************


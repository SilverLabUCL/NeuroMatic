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
//	Model Tab Functions
//
//	Adaptive Exponential Integrate and Fire ( IAF ) Functions
//
//****************************************************************
//****************************************************************

Static StrConstant Name = "IAF_AdEx"
Static StrConstant Prefix = "IAF_"
Static StrConstant Title = "Adaptive Exponential Integrate and Fire Model"
Static StrConstant StateList = "Vmem;Wadapt;"

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMModelStr_IAF_AdEx( varName )
	String varName
	
	String thisfxn = GetRTStackInfo( 1 )
	
	strswitch( varName )
		
		case "Name":
			return Name
			
		case "Prefix":
			return Prefix
			
		case "Title":
			return Title
			
		case "StateList":
			return StateList
			
		default:
			NMDoAlert( thisfxn + " Error: no variable called " + NMQuotes( varName ) )
		
	endswitch
	
	return ""
	
End // NMModelStr_IAF_AdEx

//****************************************************************
//****************************************************************
//****************************************************************

Function IAF_AdEx_Init()

	String df = NMModelDF()
	
	Variable diameter = 10 // um
	Variable SA = pi * diameter ^ 2 // um^2
	
	Variable CmDensity = 1e-2 // pF / um^2
	
	Variable gTonicGABA = 0 // nS
	Variable eGABA = -75 // mV
	
	Variable gLeak = 0.7 // nS
	
	Variable V0 = -75 // mV
	
	Variable AP_Threshold = -48 // mV
	Variable AP_Peak = 10 // mV
	Variable AP_Reset = -60 // mV
	
	Variable AP_ThreshSlope = 2
	Variable W_Tau = 300
	Variable W_A = 2
	Variable W_B = 60
	
	SetNMstr( df + "CellName", "IAF" )
	
	SetNMvar( df + "Diameter", diameter ) // um
	
	SetNMvar( df + "CmDensity", CmDensity ) // pF / um^2
	
	SetNMvar( df + "gLeakDensity", gLeak / SA ) // nS / um^2
	SetNMvar( df + "eLeak", V0 ) // mV
	
	SetNMvar( df + "gTonicGABADensity", gTonicGABA / SA )
	SetNMvar( df + "eGABA", eGABA )
	
	SetNMvar( df + "V0", V0 )
	
	SetNMvar( df + "Temperature", 37 )
	SetNMvar( df + "gQ10", 2 )
	SetNMvar( df + "tauQ10", 3 )
	
	SetNMvar( df + "AP_Threshold", AP_Threshold )
	SetNMvar( df + "AP_ThreshSlope", AP_ThreshSlope )
	SetNMvar( df + "AP_Peak", AP_Peak )
	SetNMvar( df + "AP_Reset", AP_Reset )
	
	SetNMvar( df + "W_Tau", W_Tau )
	SetNMvar( df + "W_A", W_A )
	SetNMvar( df + "W_B", W_B )
	
	Print "Initialized " + Title

End // IAF_AdEx_Init

//****************************************************************
//****************************************************************
//****************************************************************

Function IAF_AdEx_RunIclamp()

	Variable p1, p2, pend, rpnts, w
	String wName, df = NMModelDF()
	
	NVAR AP_Threshold = $df + "AP_Threshold"
	NVAR AP_Peak = $df + "AP_Peak"
	NVAR AP_Reset = $df + "AP_Reset"
	NVAR AP_Refrac = $df + "AP_Refrac"
	
	NVAR W_B = $df + "W_B"
	
	NVAR simNum = $df + "SimulationCounter"
	NVAR dt = $df + "TimeStep"
	NVAR V0 = $df + "V0"
	
	Variable method = NumVarOrDefault( NMModelDF + "IntegrateODEMethod", 0 )
	
	Variable simTime = NMModelSimTime( simNum )
	Variable npnts = ( simTime / dt ) + 1
	
	Make /D/O/N=1 Model_PP = 0 // not used
	
	Make /O/N=( 4, 2 ) Model_Stop
	
	Model_Stop[ 0 ][ 0 ] = 1
	Model_Stop[ 1 ][ 0 ] = AP_Threshold
	Model_Stop[ 2 ][ 0 ] = 0
	Model_Stop[ 3 ][ 0 ] = 0
	
	Model_Stop[ 0 ][ 1 ] = 0
	Model_Stop[ 1 ][ 1 ] = 0
	Model_Stop[ 2 ][ 1 ] = 0
	Model_Stop[ 3 ][ 1 ] = 0
	
	wName = "Model_States_" + num2str( simNum )
	
	Make /O/N=( npnts, 2 ) $wName = NaN
	SetScale /P x 0, dt, $wName
	
	Wave States = $wName
	
	SetDimLabel 1, 0, Vmem, States
	SetDimLabel 1, 1, Wadapt, States
	
	States[ 0 ][ %Vmem ] = V0
	States[ 0 ][ %Wadapt ] = 0
	
	p1 = 0
	pend = npnts - 1
	
	rpnts = AP_Refrac / dt
	
	Make /O/N=( npnts ) XWAVE
	
	do
	
		IntegrateODE /M=( method )/Q/R=[ p1, pend ] /STOP={ Model_Stop, 0 } IAF_AdEx_DYDT, Model_PP, States
		
		if ( V_Flag == 8 ) // spike
		
			p1 = V_ODEStepCompleted
			
			States[ p1 ][ 0 ] = AP_Peak
			w = States[ p1 ][ 1 ]
			
			p1 += 1
			
			if ( p1 < pend )
			
				States[ p1 ][ 0 ] = AP_Reset
				States[ p1 ][ 1 ] = w + W_B
				
				if ( rpnts > 0 )
				
					p2 = min( p1 + rpnts, pend )
				
					IntegrateODE /M=( method )/Q/R=[ p1, p2 ] IAF_AdEx_DYDT, Model_PP, States // integrate w during the refractory period
				
					States[ p1, p2 ][ 0 ] = AP_Reset
				
					p1 = p2
					
				endif
			
			endif
			
		elseif ( V_Flag == 0 )
			
			break // no spikes
			
		else
		
			Print "IntegrateODE did not finished correctly, V_Flag = ", V_Flag
			break
		
		endif
	
	while ( p1 < npnts )
	
	KillWaves /Z Model_PP, Model_Stop

End // IAF_AdEx_RunIclamp

//****************************************************************
//****************************************************************
//****************************************************************

Function IAF_AdEx_DYDT( pw, tt, yw, dydt )
	Wave pw	// parameter wave, NOT USED
	Variable tt	// time
	Wave yw	// voltage wave
	Wave dydt	// voltage derivative wave
	
	Variable v, w, isum, iLeak, iAP, gTC = 1
	String df = NMModelDF()
	
	Variable clampSelect = NMModelClampSelectNum()
	
	NVAR simNum = $df + "SimulationCounter"
	
	NVAR Cm = $df + "Cm"
	
	NVAR gLeak = $df + "gLeak"
	NVAR eLeak = $df + "eLeak"
	
	NVAR AP_Threshold = $df + "AP_Threshold"
	NVAR AP_ThreshSlope = $df + "AP_ThreshSlope"
	
	NVAR W_A = $df + "W_A"
	NVAR W_Tau = $df + "W_Tau"
	
	w = yw[ 1 ]
	
	if ( clampSelect == 0 ) // Iclamp
	
		v = yw[ 0 ]
		
		//iAP = gLeak * AP_ThreshSlope * exp( ( v - AP_Threshold ) / AP_ThreshSlope )
	
		isum = -1 * NMModelIsum( 0, tt, v, gTC ) - w //+ iAP
		
	else
	
		v = NMModelVclamp( simNum, tt )
	
	endif
	
	dydt[ 0 ] = isum / Cm
	dydt[ 1 ] = ( W_A * ( v - eLeak ) - w ) / W_Tau
	
	//if ( v > 0 )
	//	return 1
	//endif
	
	//return 0
	
End // IAF_AdEx_DYDT

//****************************************************************
//****************************************************************
//****************************************************************

Function IAF_AdEx_Imem( simNum )
	Variable simNum

	Variable icnt, npnts, v, gTC = 1
	String wName, df = NMModelDF()

	NVAR dt = $df + "TimeStep"
	
	wName = "Model_vClamp_" + num2str( simNum )
	
	if ( WaveExists( $wName ) == 0 )
		return -1 // error
	endif
	
	Wave Model_vClamp = $wName
	
	npnts = numpnts( Model_vClamp )
	
	wName = "Model_States_" + num2str( simNum )
	
	if ( WaveExists( $wName ) == 0 )
		return -1 // error
	endif
	
	Wave Model_States = $wName

	for ( icnt = 0 ; icnt < npnts ; icnt += 1 )
		
		v = Model_vClamp[ icnt ]
	
		Model_States[ icnt ][ 0 ] = NMModelIsum( 1, icnt * dt, v, gTC )
	
	endfor
	
	SetDimLabel 1, 0, Imem, Model_States

End // IAF_AdEx_Imem

//****************************************************************
//****************************************************************
//****************************************************************
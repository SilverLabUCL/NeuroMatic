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
//	Integrate and Fire ( IAF ) Functions
//
//****************************************************************
//****************************************************************

Static StrConstant Name = "IAF"
Static StrConstant Prefix = "IAF_"
Static StrConstant Title = "Integrate and Fire Model"
Static StrConstant StateList = "Vmem;"

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMModelStr_IAF( varName )
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
	
End // NMModelStr_IAF


//****************************************************************
//****************************************************************
//****************************************************************

Function IAF_Init()

	String df = NMModelDF()
	
	Variable diameter = 10 // um
	Variable SA = pi * diameter ^ 2 // um^2
	
	Variable CmDensity = 1e-2 // pF / um^2
	
	Variable gTonicGABA = 0.438 // nS
	Variable eGABA = -80 // mV
	
	Variable gLeak = 0.9 - gTonicGABA // nS
	
	Variable V0 = -80 // mV
	
	Variable AP_Threshold = -40 // mV
	Variable AP_Peak = AP_Threshold + 72 // mV
	Variable AP_Reset = AP_Threshold - 21 // mV
	Variable AP_Refrac = 2.0 // 0.9 // ms
	
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
	SetNMvar( df + "AP_Peak", AP_Peak )
	SetNMvar( df + "AP_Reset", AP_Reset )
	SetNMvar( df + "AP_Refrac", AP_Refrac )
	
	Print "Initialized " + Title

End // IAF_Init

//****************************************************************
//****************************************************************
//****************************************************************

Function IAF_RunIclamp()

	Variable rpnts, p1, p2, pSpike, pbgn, pend
	String wName, df = NMModelDF()
	
	Variable AP_Threshold = NumVarOrDefault( df + "AP_Threshold", NaN )
	Variable AP_Peak = NumVarOrDefault( df + "AP_Peak", NaN )
	Variable AP_Reset = NumVarOrDefault( df + "AP_Reset", NaN )
	Variable AP_Refrac = NumVarOrDefault( df + "AP_Refrac", NaN )

	Variable simNum = NumVarOrDefault( df + "SimulationCounter", NaN )
	
	Variable simTime = NMModelSimTime( simNum )
	Variable dt = NumVarOrDefault( df + "TimeStep", NaN )
	Variable npnts = ( simTime / dt ) + 1
	
	Variable V0 = NumVarOrDefault( df + "V0", NaN )
	
	Variable method = NumVarOrDefault( NMModelDF + "IntegrateODEMethod", 0 )
	
	Make /D/O/N=1 Model_PP = 0 // not used
	
	Make /O/N=( 4, 1 ) Model_Stop
	
	Model_Stop[ 0 ][ 0 ] = 1
	Model_Stop[ 1 ][ 0 ] = AP_Threshold
	Model_Stop[ 2 ][ 0 ] = 0
	Model_Stop[ 3 ][ 0 ] = 0
	
	wName = "Model_States_" + num2str( simNum )
	
	Make /O/N=( npnts, 1 ) $wName = NaN
	SetScale /P x 0, dt, $wName
	
	Wave States = $wName
	
	SetDimLabel 1, 0, Vmem, States
	
	States[ 0 ][ %Vmem ] = V0
	
	p1 = 0
	p2 = npnts - 1
	
	rpnts = 1 + AP_Refrac / dt
	
	do
	
		IntegrateODE /M=( method )/Q/R=[ p1, p2 ] /STOP={ Model_Stop, 0 } IAF_DYDT, Model_PP, States
		
		if ( V_Flag == 8 ) // spike here
		
			pSpike = V_ODEStepCompleted + 1
			
			States[ pSpike ][ 0 ] = AP_Peak
			
			pbgn = min( pSpike + 1, npnts - 1 )
			pend = min( pSpike + rpnts, npnts - 1 )
			
			States[ pbgn, pend ][ 0 ] = AP_Reset
			
			p1 = pSpike + rpnts // skip refractory period
		
		else
			
			break // no spikes
		
		endif
	
	while ( p1 < npnts )
	
	KillWaves /Z Model_PP, Model_Stop

End // IAF_RunIclamp

//****************************************************************
//****************************************************************
//****************************************************************

Function IAF_DYDT( pw, tt, yw, dydt )
	Wave pw	// parameter wave, NOT USED
	Variable tt	// time
	Wave yw	// voltage wave
	Wave dydt	// voltage derivative wave
	
	Variable v, isum, gTC = 1
	String df = NMModelDF()
	
	Variable clampSelect = NMModelClampSelectNum()
	
	NVAR simNum = $df + "SimulationCounter"
	
	NVAR Cm = $df + "Cm"
	
	if ( clampSelect == 0 ) // Iclamp
	
		v = yw[ 0 ]
	
		isum = -1 * NMModelIsum( 0, tt, v, gTC )
		
	else
	
		v = NMModelVclamp( simNum, tt )
	
	endif
	
	dydt[ 0 ] = isum / Cm
	
	//if ( v > 0 )
	//	return 1
	//endif
	
	//return 0
	
End // IAF_DYDT

//****************************************************************
//****************************************************************
//****************************************************************

Function IAF_Imem( simNum )
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
	
	if ( !WaveExists( $wName ) || ( DimSize( $wName, 0 ) != npnts ) )
		return -1 // error
	endif
	
	Wave Model_States = $wName

	for ( icnt = 0 ; icnt < npnts ; icnt += 1 )
		v = Model_vClamp[ icnt ]
		Model_States[ icnt ][ 0 ] = NMModelIsum( 1, icnt * dt, v, gTC )
	endfor
	
	SetDimLabel 1, 0, Imem, Model_States

End // IAF_Imem

//****************************************************************
//****************************************************************
//****************************************************************

Function GC_gLeak( v )
	Variable v
	
	Variable w0 = 0.6
	Variable w1 = 4
	Variable w2 = -43
	Variable w3 = 2.2
	
	return w0 + w1 / ( 1 + exp( -( v - w2 ) / w3 ) )
	
End // GC_gLeak

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModel_GC_Current( v )
	Variable v
	
	return 75.339 + 0.95758 * v
	
End // NMModel_GC_Current

//****************************************************************
//****************************************************************
//****************************************************************

Function NMModel_GC_Current_Vramp( v ) // from Vramp data
	Variable v
	
	v -= 12
	
	return 410.77 + 14.309 * v + 0.094928 * v ^ 2 - 0.002168 * v ^ 3 - 3.2745e-5 * v ^ 4 - 1.1307e-7 * v ^ 5
	
End // NMModel_GC_Current_Vramp

//****************************************************************
//****************************************************************
//****************************************************************
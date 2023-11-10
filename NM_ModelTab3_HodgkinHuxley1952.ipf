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
//	Hodgkin-Huxley Model
//
//	"A QUANTITATIVE DESCRIPTION OF MEMBRANE CURRENT 
//	AND ITS APPLICATION TO CONDUCTION AND EXCITATION IN NERVE"
//
//	A. L. HODGKIN AND A. F. HUXLEY
//	J. Physiol. (I952) I I7, 500-544
//
//****************************************************************
//****************************************************************

Static Constant Temperature = 6.3 // C

Static StrConstant Name = "HodgkinHuxley"
Static StrConstant Prefix = "HH_"
Static StrConstant Title = "Hodgkin Huxley Squid Giant Axon Model"
Static StrConstant StateList = "Vmem;Na_m;Na_h;K_n;"

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMModelStr_HodgkinHuxley( varName )
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
	
End // NMModelStr_HodgkinHuxley

//****************************************************************
//****************************************************************
//****************************************************************

Function HodgkinHuxley_Init()
	
	Variable Cm = 12 // pF
	Variable CmDensity = 1 * 1e6 * 1e-8 // pF / um^2
	Variable SA = Cm / CmDensity
	Variable diameter = sqrt( SA / pi )
	
	Variable gLeakDensity = 0.3 * 1e6 * 1e-8 // nS / um^2
	Variable gNaDensity = 120 * 1e6 * 1e-8 // nS / um^2
	Variable gKDensity = 36 * 1e6 * 1e-8 // nS / um^2
	
	Variable vShift = 65 // reference voltage shift
	
	Variable V0 = 0 - vShift // initial potential
	
	Variable eLeak = 10.613 - vShift
	Variable eNa = 115 - vShift
	Variable eK = -12 - vShift
	
	NMModelStrSet( "CellName", "Squid Giant Axon" )
	
	NMModelVarSet( "Diameter", diameter )
	
	NMModelVarSet( "CmDensity", CmDensity )
	
	NMModelVarSet( "gLeakDensity", gLeakDensity )
	NMModelVarSet( "eLeak", eLeak )
	
	NMModelVarSet( "gNaDensity", gNaDensity )
	NMModelVarSet( "eNa", eNa )
	
	NMModelVarSet( "gKDensity", gKDensity )
	NMModelVarSet( "eK", eK )
	
	NMModelVarSet( "V0", V0 )
	
	NMModelVarSet( "Temperature", Temperature )
	NMModelVarSet( "gQ10", 2 )
	NMModelVarSet( "tauQ10", 3 )
	
	Print "Initialized " + Title
	
End // HodgkinHuxley_Init

//****************************************************************
//****************************************************************
//****************************************************************

Function HodgkinHuxley_DYDT( pw, tt, yw, dydt ) // see IntegrateODE
	Wave pw	// parameter wave (NOT USED)
	Variable tt	// time value at which to calculate derivatives
	Wave yw 	// wave containing y[i] (input)	
	Wave dydt	// wave to receive dy[i]/dt (output)
	
	if ( NMProgressCancel() == 1 )
		return 0 // cancel
	endif
	
	Variable v, icnt, gTC
	Variable isum, iNa, iK
	String state, df = NMModelDF()
	
	String stateList = NMModelStr_HodgkinHuxley( "StateList" )
	Variable numStates = ItemsInList( stateList )
	
	Variable clampSelect = NMModelClampSelectNum()
	
	NVAR simNum = $df + "SimulationCounter"
	
	NVAR Cm = $df + "Cm"
	
	NVAR gNa = $df + "gNa"
	NVAR eNa = $df + "eNa"
	
	NVAR gK = $df + "gK"
	NVAR eK = $df + "eK"
	
	NVAR MD_xinf, MD_taux
	
	if ( clampSelect == 0 ) // Iclamp
	
		gTC = NMModelQ10g( Temperature )
		
		v = yw[ 0 ]
		iNa = gTC * gNa * ( yw[ 1 ] ^ 3 ) * yw[ 2 ] * ( v - eNa )
		iK = gTC * gK * ( yw[ 3 ] ^ 4 ) * ( v - eK )
	
		isum = -1 * NMModelIsum( 0, tt, v, gTC ) - iNa - iK
		
	else // Vclamp
	
		v = NMModelVclamp( simNum, tt )
		
	endif
	
	dydt[ 0 ] = isum / Cm // -Cm * dV/dt = iNa + iK + iLeak + iAMPA + iNMDA + iGABA + iTonicGABA - iClampValue
	
	for ( icnt = 1 ; icnt < numStates ; icnt += 1 )
		state = StringFromList( icnt, stateList )
		HodgkinHuxley_Kinetics( state, v, NaN, "SS" )
		dydt[ icnt ] = ( MD_xinf - yw[ icnt ] ) / MD_taux
	endfor

End // HodgkinHuxley_DYDT

//****************************************************************
//****************************************************************
//****************************************************************

Function HodgkinHuxley_Imem( simNum )
	Variable simNum

	Variable icnt, npnts, gTC, v
	Variable iNa, iK
	String wName, df = NMModelDF()

	NVAR dt = $df + "TimeStep"
	
	NVAR gNa = $df + "gNa"
	NVAR eNa = $df + "eNa"
	
	NVAR gK = $df + "gK"
	NVAR eK = $df + "eK"
	
	gTC = NMModelQ10g( Temperature )
	
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
		
		iNa = gTC * gNa * ( Model_States[ icnt ][ 1 ] ^ 3 ) * Model_States[ icnt ][ 2 ] * ( v - eNa )
		iK = gTC * gK * ( Model_States[ icnt ][ 3 ] ^ 4 ) * ( v - eK )
	
		Model_States[ icnt ][ 0 ] = NMModelIsum( 1, icnt * dt, v, gTC ) + iNa + iK
	
	endfor
	
	SetDimLabel 1, 0, Imem, Model_States

End // HodgkinHuxley_Imem

//****************************************************************
//****************************************************************
//****************************************************************

Function HodgkinHuxley_Kinetics( select, v, CaConc, SSorTau )
	String select // see switch below
	Variable v // membrane potential
	Variable CaConc // calcium concentration (NOT USED)
	String SSorTau // "SS" or "Tau"
	
	Variable a, b
	
	Variable v65 = v + 65 // shift 65 mV because HH resting potential is 0 mV
	
	Variable TC = NMModelQ10tau( Temperature )
	
	NVAR MD_xinf, MD_taux
	
	strswitch( select )
			
		case "Na_m":
			a = 0.1 * NMModelLinoid( v65, 25, 10 )
			b = 4 * exp( -v65 / 18 )
			break
			
		case "Na_h":
			a = 0.07 * exp( -v65 / 20 )
			b = 1 / ( 1 + exp( -( v65 - 30 ) / 10 ) )
			break
			
		case "K_n":
			a = 0.01 * NMModelLinoid( v65, 10, 10 )
			b = 0.125 * exp( -v65 / 80 )
			break
			
		default:
			Print "HodgkinHuxley_Kinetics select error: no such equation: " + select
			return NaN
			
	endswitch
	
	MD_xinf = a / ( a + b )
	MD_taux = 1 / ( a + b )
	MD_taux /= TC
	
	if ( StringMatch( SSorTau, "SS" ) == 1 )
		return MD_xinf
	else
		return MD_taux
	endif
	
End // HodgkinHuxley_Kinetics

//****************************************************************
//****************************************************************
//****************************************************************
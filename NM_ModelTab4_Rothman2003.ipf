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
//	VCN Model
//
//	"The Roles Potassium Currents Play in Regulating the Electrical Activity
//	of Ventral Cochlear Nucleus Neurons"
//
//	Jason S Rothman and Paul B Manis
//	J Neurophysiol 89: 3097-3113, 2003
//
//****************************************************************
//****************************************************************

Static Constant Temperature = 22 // C

Static StrConstant Name = "Rothman_VCN"
Static StrConstant Prefix = "VCN_"
Static StrConstant Title = "Rothman Ventral Cochlear Nucleus Models"
Static StrConstant StateList = "Vmem;Na_m;Na_h;K_n;K_p;KA_a;KA_b;KA_c;KD_w;KD_z;H_r;"

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMModelStr_Rothman_VCN( varName )
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
	
End // NMModelStr_Rothman_VCN

//****************************************************************
//****************************************************************
//****************************************************************

Function /S Rothman_VCN_Init()

	String cellName = "I-c"
		
	Prompt cellName, "select VCN cell type:", popup "I-c;I-t;I-II;II-I;II;"
	DoPrompt "Initialize Rothman VCN model", cellName
 	
 	if ( V_flag == 1 )
		//return "" // cancel
	endif
	
	Variable Cm = 12 // pF
	Variable CmDensity = 0.9e-2 // pF / um^2
	Variable SA = Cm / CmDensity
	Variable diameter = sqrt( SA / pi )
	
	Variable gLeak = 2
	Variable gNa = 1000
	Variable gK = 150 // gHT
	Variable gKA = 0
	Variable gKD = 0 // gLT
	Variable gH = 0.5
	
	Variable V0 = -64 // initial potential
	Variable eLeak = -65
	Variable eNa = 55
	Variable eK = -70
	Variable eH = -43
	
	NMModelVarSet( "Diameter", diameter )
	
	NMModelVarSet( "CmDensity", CmDensity )
	
	NMModelVarSet( "gLeakDensity", gLeak / SA )
	NMModelVarSet( "eLeak", eLeak )
	
	NMModelVarSet( "gNaDensity", gNa / SA )
	NMModelVarSet( "eNa", eNa )
	
	strswitch( cellName )
	
		case "I-c":
			gK = 150
			gKA = 0
			gKD = 0
			gH = 0.5
			V0 = -63.9311
			break
			
		case "I-t":
			gK = 80
			gKA = 65
			gKD = 0
			gH = 0.5
			V0 = -64.1973
			break
			
		case "I-II":
			gK = 150
			gKA = 0
			gKD = 20
			gH = 2
			V0 = -64.0523
			break
			
		case "II-I":
			gK = 150
			gKA = 0
			gKD = 35
			gH = 3.5
			V0 = -63.8959
			break
			
		case "II":
			gK = 150
			gKA = 0
			gKD = 200
			gH = 20
			V0 = -63.6284
			break
		
	endswitch
	
	NMModelStrSet( "CellName", "VCN Type " + cellName )
	
	NMModelVarSet( "gKDensity", gK / SA )
	NMModelVarSet( "eK", eK )
	
	NMModelVarSet( "gKADensity", gKA / SA )
	NMModelVarSet( "eKA", eK )
	
	NMModelVarSet( "gKDDensity", gKD / SA )
	NMModelVarSet( "eKD", eK )
	
	NMModelVarSet( "gHDensity", gH / SA )
	NMModelVarSet( "eH", eH )
	
	NMModelVarSet( "V0", V0 )
	
	NMModelVarSet( "Temperature", Temperature )
	NMModelVarSet( "gQ10", 2 )
	NMModelVarSet( "tauQ10", 3 )
	
	Print "Initialized Rothman VCN Type " + cellName + " Model"
	
	return cellName
	
End // Rothman_VCN_Init

//****************************************************************
//****************************************************************
//****************************************************************

Function Rothman_VCN_Init_Fig2( cellName )
	String cellName
	
	Variable iClampAmp = -50
	Variable iClampAmpInc = 100
	
	NMModelVarSet( "NumSimulations", 2 )

	NMModelVarSet( "SimulationTime", 200 )
	NMModelVarSet( "Temperature", 22 )
	
	NMModelVarSet( "iClampOnset", 50 )
	NMModelVarSet( "iClampDuration", 100 )
	
	strswitch( cellName )
	
		case "I-c":
		case "I-t":
			iClampAmp = -50
			iClampAmpInc = 100
			break
		
		case "I-II":
		case "II-I":
			iClampAmp = -100
			iClampAmpInc = 200
			break
			
		case "II":
			iClampAmp = -300
			iClampAmpInc = 600
			break
		
	endswitch
	
	NMModelVarSet( "iClampAmp", iClampAmp )
	NMModelVarSet( "iClampAmpInc", iClampAmpInc )
	
	Rothman_VCN_Init()

End // Rothman_VCN_Init_Fig2

//****************************************************************
//****************************************************************
//****************************************************************

Function Rothman_VCN_DYDT( pw, tt, yw, dydt ) // see IntegrateODE
	Wave pw	// parameter wave (NOT USED)
	Variable tt	// time value at which to calculate derivatives
	Wave yw 	// wave containing y[i] (input)	
	Wave dydt	// wave to receive dy[i]/dt (output)
	
	if ( NMProgressCancel() == 1 )
		return 0 // cancel
	endif
	
	Variable v, icnt, gTC
	Variable isum, iLeak, iNa, iK, iKA, iKD, iH
	String state, df = NMModelDF()
	
	Variable gHT_fraction = 0.85 // as defined in paper
	
	String stateList = NMModelStr_Rothman_VCN( "StateList" )
	Variable numStates = ItemsInList( stateList )
	
	Variable clampSelect = NMModelClampSelectNum()
	
	NVAR simNum = $df + "SimulationCounter"

	NVAR Cm = $df + "Cm"
	
	NVAR gNa = $df + "gNa"
	NVAR eNa = $df + "eNa"
	
	NVAR gK = $df + "gK"
	NVAR eK = $df + "eK"
	
	NVAR gKA = $df + "gKA"
	NVAR eKA = $df + "eKA"
	
	NVAR gKD = $df + "gKD"
	NVAR eKD = $df + "eKD"
	
	NVAR gH = $df + "gH"
	NVAR eH = $df + "eH"
	
	NVAR MD_xinf, MD_taux
	
	if ( clampSelect == 0 ) // Iclamp
		
		gTC = NMModelQ10g( Temperature )
		
		v = yw[ 0 ]
		iNa = gTC * gNa * ( yw[ 1 ] ^ 3 ) * yw[ 2 ] * ( v - eNa )
		iK = gTC * gK * ( gHT_fraction * ( yw[ 3 ] ^ 2 ) + ( 1 - gHT_fraction ) * yw[ 4 ] ) * ( v - eK )
		iKA = gTC * gKA * ( yw[ 5 ] ^ 4 ) * yw[ 6 ] * yw[ 7 ] * ( v - eKA )
		iKD = gTC * gKD * ( yw[ 8 ] ^ 4 ) * yw[ 9 ] * ( v - eKD )
		iH = gTC * gH * yw[ 10 ] * ( v - eH )
		
		isum = -1 * NMModelIsum( 0, tt, v, gTC ) - iNa - iK - iKA - iKD - iH
	
	else // Vclamp
	
		v = NMModelVclamp( simNum, tt )
	
	endif
	
	dydt[ 0 ] = isum / Cm
	
	for ( icnt = 1 ; icnt < numStates ; icnt += 1 )
		state = StringFromList( icnt, stateList )
		Rothman_VCN_Kinetics( state, v, NaN, "SS" )
		dydt[ icnt ] = ( MD_xinf - yw[ icnt ] ) / MD_taux
	endfor

End // Rothman_VCN_DYDT

//****************************************************************
//****************************************************************
//****************************************************************

Function Rothman_VCN_Imem( simNum )
	Variable simNum
	
	Variable icnt, npnts, gTC, v
	Variable iNa, iK, iKA, iKD, iH
	String wName, df = NMModelDF()
	
	Variable gHT_fraction = 0.85 // as defined in paper

	NVAR dt = $df + "TimeStep"
	
	NVAR gNa = $df + "gNa"
	NVAR eNa = $df + "eNa"
	
	NVAR gK = $df + "gK"
	NVAR eK = $df + "eK"
	
	NVAR gKA = $df + "gKA"
	NVAR eKA = $df + "eKA"
	
	NVAR gKD = $df + "gKD"
	NVAR eKD = $df + "eKD"
	
	NVAR gK = $df + "gK"
	NVAR eK = $df + "eK"
	
	NVAR gNa = $df + "gNa"
	NVAR eNa = $df + "eNa"
	
	NVAR gH = $df + "gH"
	NVAR eH = $df + "eH"
	
	gTC = NMModelQ10g( Temperature )
	
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
		
		iNa = gTC * gNa * ( Model_States[ icnt ][ 1 ] ^ 3 ) * Model_States[ icnt ][ 2 ] * ( v - eNa )
		iK = gTC * gK * ( gHT_fraction * ( Model_States[ icnt ][ 3 ] ^ 2 ) + ( 1 - gHT_fraction ) * Model_States[ icnt ][ 4 ] ) * ( v - eK )
		iKA = gTC * gKA * ( Model_States[ icnt ][ 5 ] ^ 4 ) * Model_States[ icnt ][ %b ] * Model_States[ icnt ][ 6 ] * ( v - eKA )
		iKD = gTC * gKD * ( Model_States[ icnt ][ %w ] ^ 4 ) * Model_States[ icnt ][ %z ] * ( v - eKD )
		iH = gTC * gH * Model_States[ icnt ][ 7 ] * ( v - eH )
	
		Model_States[ icnt ][ 0 ] = NMModelIsum( 1, icnt * dt, v, gTC ) + iNa + iK + iKA + iKD + iH
	
	endfor
	
	SetDimLabel 1, 0, Imem, Model_States

End // Rothman_VCN_Imem

//****************************************************************
//****************************************************************
//****************************************************************

Function Rothman_VCN_Kinetics( select, v, CaConc, SSorTau )
	String select // see switch below
	Variable v // membrane potential
	Variable CaConc // Calcium concentration ( NOT USED )
	String SSorTau // "SS" or "Tau"
	
	Variable v60 = v + 60
	
	Variable TC = NMModelQ10tau( Temperature )
	
	Variable zfraction = 0.5 // as defined in paper
	
	NVAR MD_xinf, MD_taux
	
	strswitch( select )
	
		case "KA_a":
			MD_xinf = ( 1 + exp( -( v + 31 ) / 6 ) ) ^ -0.25
			MD_taux = 0.1 + 100 / ( 7 * exp( v60 / 14 ) + 29 * exp( -v60 / 24 ) )
			MD_taux /= TC
			break
			
		case "KA_b":
			MD_xinf = ( 1 + exp( ( v + 66 ) / 7 ) ) ^ -0.5
			MD_taux = 1 + 1000 / ( 14 * exp( v60 / 27 ) + 29 * exp( -v60 / 24 ) )
			MD_taux /= TC
			break
			
		case "KA_c":
			MD_xinf = ( 1 + exp( ( v + 66 ) / 7 ) ) ^ -0.5
			MD_taux = 10 + 90 / ( 1 + exp( -( v + 66 ) / 17 ) )
			MD_taux /= TC
			break
			
		case "KD_w":
			MD_xinf = ( 1 + exp( -( v + 48 ) / 6 ) ) ^ -0.25
			MD_taux = 1.5 + 100 / ( 6 * exp( v60 / 6 ) + 16 * exp( -v60 / 45 ) )
			MD_taux /= TC
			break
			
		case "KD_z":
			MD_xinf = zfraction + ( 1 - zfraction ) / ( 1 + exp( ( v + 71 ) / 10 ) )
			MD_taux = 50 + 1000 / ( exp( v60 / 20 ) + exp( -v60 / 8 ) )
			MD_taux /= TC
			break
			
		case "K_n":
			MD_xinf = ( 1 + exp( -( v + 15 ) / 5 ) ) ^ -0.5
			MD_taux = 0.7 + 100 / ( 11 * exp( v60 / 24 ) + 21 * exp( -v60 / 23 ) )
			MD_taux /= TC
			break
			
		case "K_p":
			MD_xinf = 1 / ( 1 + exp( -( v + 23 ) / 6 ) )
			MD_taux = 5 + 100 / ( 4 * exp( v60 / 32 ) + 5 * exp( -v60 / 22 ) )
			MD_taux /= TC
			break
	
		case "Na_m":
			MD_xinf = 1 / ( 1 + exp( -( v + 38 ) / 7 ) )
			MD_taux = 0.04 + 10 / ( 5 * exp( v60 / 18 ) + 36 * exp( -v60 / 25 ) )
			MD_taux /= TC
			break
			
		case "Na_h":
			MD_xinf = 1 / ( 1 + exp( ( v + 65 ) / 6 ) )
			MD_taux = 0.6 + 100 / ( 7 * exp( v60 / 11 ) + 10 * exp( -v60 / 25 ) )
			MD_taux /= TC
			break
			
		case "H_r":
			MD_xinf = 1 / ( 1 + exp( ( v + 76 ) / 7 ) )
			MD_taux = 25 + 100000 / ( 237 * exp( v60 / 12 ) + 17 * exp( -v60 / 14 ) )
			MD_taux /= TC
			break
			
		default:
			Print "Rothman_VCN_Kinetics select error: no such equation: " + select
			return NaN
			
	endswitch
	
	if ( StringMatch( SSorTau, "SS" ) == 1 )
		return MD_xinf
	else
		return MD_taux
	endif
	
End // Rothman_VCN_Kinetics

//****************************************************************
//****************************************************************
//****************************************************************


#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma hide = 1

// SetIgorOption IndependentModuleDev=1 (unhide)

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
//	Utility Functions for Wave Statistics
//
//****************************************************************
//****************************************************************

Function NMX2Pnt( xWave, xValue ) // like x2pnt but uses x-scale wave
	String xWave // x-axis wave name, must be in ascending order
	Variable xValue // x-scale value to find
	
	//if ( numtype( xValue ) > 0 )
	//	return NaN
	//endif
	
	if ( !WaveExists( $xWave ) )
		return NaN
	endif
	
	WaveStats /Q $xWave
	
	if ( xValue <= V_min )
	
		return V_minRowLoc
		
	elseif ( xValue >= V_max )
	
		return V_maxRowLoc
	
	else

		FindLevel /EDGE=1/P/Q $xWave, xValue
		
		if ( ( V_flag == 1 ) || ( V_rising == 0 ) )
			//NM2Error( 90, "error in locating xValue = " + num2str( xValue ) + " in x-scale wave " + xWave, "" )
			return NaN
		endif
		
		return round( V_LevelX )
 	
 	endif
	
End // NMX2Pnt

//****************************************************************
//****************************************************************

Structure NMWaveStatsStruct

	// inputs
	
	String wName, xWave, fxnSelect
	Variable xbgn, xend

	// outputs

	Variable sum, avg, sdev, sem, rms
	Variable adev, skew, kurt
	Variable min, minLoc, minRowLoc
	Variable max, maxLoc, maxRowLoc
	Variable points, numNaNs, numINFs
	Variable startRow, endRow
	Variable y, x, pnt // for fxnSelect

EndStructure // NMWaveStatsStruct

//****************************************************************
//****************************************************************

Function NMWaveStatsStructNull( s )
	STRUCT NMWaveStatsStruct &s
	
	s.wName = ""; s.xWave = ""; s.fxnSelect = ""
	s.xbgn = -inf; s.xend = inf
	s.sum = NaN; s.avg = NaN; s.sdev = NaN; s.sem = NaN; s.rms = NaN
	s.adev = NaN; s.skew = NaN; s.kurt = NaN
	s.min = NaN; s.minLoc = NaN; s.minRowLoc = NaN
	s.max = NaN; s.maxLoc = NaN; s.maxRowLoc = NaN
	s.points = NaN; s.numNaNs = NaN; s.numINFs = NaN
	s.startRow = NaN; s.endRow = NaN
	s.y = NaN; s.x = NaN; s.pnt = NaN
	
End // NMWaveStatsStructNull

//****************************************************************
//****************************************************************

Function NMWaveStatsStructInit( s, wName [ xWave, xbgn, xend, fxnSelect ] )
	STRUCT NMWaveStatsStruct &s
	String wName, xWave
	Variable xbgn, xend
	String fxnSelect
	
	NMWaveStatsStructNull( s )
	
	s.wName = wName
	
	if ( !ParamIsDefault( xWave ) )
		s.xWave = xWave
	endif
	
	if ( !ParamIsDefault( xbgn ) )
		s.xbgn = xbgn
	endif
	
	if ( !ParamIsDefault( xend ) )
		s.xend = xend
	endif
	
	if ( !ParamIsDefault( fxnSelect ) )
		s.fxnSelect = fxnSelect
	endif
	
End // NMWaveStatsStructInit

//****************************************************************
//****************************************************************

Function /S NMWaveStatsXY( wName [ xWave, xbgn, xend, fxnSelect, history ] ) // see NMWaveStatsXY2
	String wName // wave name
	String xWave // x-axis wave name
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	String fxnSelect // select fxn to save x-y values
	Variable history
	
	STRUCT NMWaveStatsStruct s
	
	if ( ParamIsDefault( xWave ) )
		xWave = ""
	endif
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( ParamIsDefault( fxnSelect ) )
		fxnSelect = ""
	endif
	
	NMWaveStatsStructInit( s, wName, xWave = xWave, xbgn = xbgn, xend = xend, fxnSelect = fxnSelect )
	
	return NMWaveStatsXY2( s, history = history )
	
End // NMWaveStatsXY

//****************************************************************
//****************************************************************

Function /S NMWaveStatsXY2( s [ history ] ) // see Igor WaveStats
	STRUCT NMWaveStatsStruct &s
	Variable history
	
	Variable pbgn, pend, npnts, xflag
	String statsList = ""
	
	if ( NMUtilityWaveTest( s.wName ) < 0 )
		return NM2ErrorStr( 1, "wName", s.wName )
	endif
	
	if ( numtype( s.xbgn ) > 0 )
		s.xbgn = -inf
	endif
	
	if ( numtype( s.xend ) > 0 )
		s.xend = inf
	endif
	
	if ( strlen( s.xWave ) > 0 ) 
	
		if ( NMUtilityWaveTest( s.xWave ) < 0 )
			return NM2ErrorStr( 1, "xWave", s.xWave )
		endif
		
		if ( numpnts( $s.xWave ) != numpnts( $s.wName ) )
			return NM2ErrorStr( 5, "xWave", s.xWave )
		endif
		
		pbgn = NMX2Pnt( s.xWave, s.xbgn )
		pend = NMX2Pnt( s.xWave, s.xend )
		xflag = 1
		
	endif
	
	if ( xflag )
		WaveStats /Q/Z/R=[ pbgn, pend ] $s.wName
	else
		WaveStats /Q/Z/R=( s.xbgn, s.xend ) $s.wName
	endif
	
	s.sum = V_sum
	s.avg = V_avg
	s.sdev = V_sdev
	s.sem = V_sem
	s.rms = V_rms
	s.adev = V_adev
	s.skew = V_skew
	s.kurt = V_kurt
	s.min = V_min
	s.minLoc = V_minLoc
	s.minRowLoc = V_minRowLoc
	s.max = V_max
	s.maxLoc = V_maxLoc
	s.maxRowLoc = V_maxRowLoc
	s.points = V_npnts
	s.numNaNs = V_numNaNs
	s.numINFs = V_numINFs
	s.startRow = V_startRow
	s.endRow = V_endRow
	
	if ( xflag )
	
		Wave xtemp = $s.xWave
		
		if ( ( s.minRowLoc >= 0 ) && ( s.minRowLoc < numpnts( xtemp ) ) )
			s.minLoc = xtemp[ s.minRowLoc ]
		else
			s.minLoc = NaN
		endif
		
		if ( ( s.maxRowLoc >= 0 ) && ( s.maxRowLoc < numpnts( xtemp ) ) )
			s.maxLoc = xtemp[ s.maxRowLoc ]
		else
			s.maxLoc = NaN
		endif
		
	endif
	
	strswitch( s.fxnSelect )
		case "sum":
			s.y = s.sum
			break
		case "avg":
			s.y = s.avg
			break
		case "sdev":
			s.y = s.sdev
			break
		case "sem":
			s.y = s.sem
			break
		case "var":
			s.y = s.sdev * s.sdev
			break
		case "rms":
			s.y = s.rms
			break
		case "adev":
			s.y = s.adev
			break
		case "skew":
			s.y = s.skew
			break
		case "kurt":
			s.y = s.kurt
			break
		case "min":
			s.y = s.min
			s.x = s.minLoc
			s.pnt = s.minRowLoc
			break
		case "max":
			s.y = s.max
			s.x = s.maxLoc
			s.pnt = s.maxRowLoc
			break
		case "npnts":
		case "points":
		case "NumPnts":
			s.y = s.points
			break
		case "numNaNs":
			s.y = s.numNaNs
			break
		case "numINFs":
			s.y = s.numINFs
			break
	endswitch
	
	String scstr = ";"
	
	statsList += "wName=" + s.wName + scstr
	
	if ( strlen( s.xWave ) > 0 )
		statsList += "xWave=" + s.xWave + scstr
	endif
	
	statsList += NMCR
	
	statsList += "xbgn=" + num2str( s.xbgn ) + scstr
	statsList += "xend=" + num2str( s.xend ) + scstr + NMCR
	
	statsList += "npnts=" + num2istr( s.points ) + scstr
	statsList += "numNaNs=" + num2istr( s.numNaNs ) + scstr
	statsList += "numINFs=" + num2istr( s.numINFs ) + scstr
	statsList += "startRow=" + num2istr( s.startRow ) + scstr
	statsList += "endRow=" + num2istr( s.endRow ) + scstr + NMCR
	
	statsList += "sum=" + num2str( s.sum ) + scstr
	statsList += "avg=" + num2str( s.avg ) + scstr
	statsList += "sdev=" + num2str( s.sdev ) + scstr
	statsList += "sem=" + num2str( s.sem ) + scstr + NMCR
	
	statsList += "rms=" + num2str( s.rms ) + scstr
	statsList += "adev=" + num2str( s.adev ) + scstr
	statsList += "skew=" + num2str( s.skew ) + scstr
	statsList += "kurt=" + num2str( s.kurt ) + scstr + NMCR
	
	statsList += "min=" + num2str( s.min ) + scstr
	statsList += "minLoc=" + num2str( s.minLoc ) + scstr
	statsList += "minRowLow=" + num2istr( s.minRowLoc ) + scstr + NMCR
	
	statsList += "max=" + num2str( s.max ) + scstr
	statsList += "maxLoc=" + num2str( s.maxLoc ) + scstr
	statsList += "maxRowLoc=" + num2istr( s.maxRowLoc ) + scstr + NMCR
	
	if ( history )
		//Print s
		Print statsList
	endif
	
	return statsList
	
End // NMWaveStatsXY

//****************************************************************
//
//	WaveListStats
//	compute stats of a list of waves
//	results returned in waves U_AmpX and U_AmpY
//	stats can be Max, Min, Avg or Slope
//	also see NMWaveStats
//
//****************************************************************

Function WaveListStats( alg, xbgn, xend, wList [ folder, xWave, history ] )
	String alg // statistic to compute ( "Max", "Min", "Avg" or "Slope" )
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	String wList, folder, xWave // see description at top
	Variable history
	
	Variable wcnt, ampy, ampx, npnts, xflag, numWaves
	String xl, yl, txt, wName, mbStr
	String thisFxn = GetRTStackInfo( 1 )
	
	STRUCT NMParams nm
	STRUCT NMWaveStatsStruct s
	
	KillWaves /Z U_AmpX, U_AmpY
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	if ( ParamIsDefault( xWave ) )
		xWave = ""
	endif
	
	if ( NMParamsInit( folder, wList, nm, xWave = xWave ) != 0 )
		return -1 //
	endif
	
	numWaves = ItemsInList( nm.wList )
	
	if ( numtype( xbgn ) > 0 )
		xbgn = -inf
	endif
	
	if ( numtype( xend ) > 0 )
		xend = inf
	endif
	
	if ( ParamIsDefault( xWave ) )
	
		xWave = ""
		
	elseif ( strlen( xWave ) > 0 ) 
	
		if ( NMUtilityWaveTest( nm.folder + xWave ) < 0 )
			NM2Error( 1, "xWave", xWave )
			return -1
		endif
		
		npnts = GetXstats( "points" , nm.wList, folder = nm.folder )
		
		if ( numpnts( $nm.folder + xWave ) != npnts )
			NM2Error( 5, "xWave", xWave )
			return -1
		endif
		
		//paramList = NMCmdStrOptional( "xwave", xWave, paramList )
		
		xWave = nm.folder + xWave
		xflag = 1
		
	endif
	
	Make /O/N=( numWaves ) U_AmpX
	Make /O/N=( numWaves ) U_AmpY
	
	for ( wcnt = 0; wcnt < numWaves; wcnt += 1 )
	
		wName = StringFromList( wcnt, nm.wList )
		
		strswitch( alg )
		
			case "Max":
				NMWaveStatsStructInit( s, nm.folder + wName, xWave = xWave, xbgn = xbgn, xend = xend )
				NMWaveStatsXY2( s )
				ampy = s.max
				ampx = s.maxLoc
				break
				
			case "Min":
				NMWaveStatsStructInit( s, nm.folder + wName, xWave = xWave, xbgn = xbgn, xend = xend )
				NMWaveStatsXY2( s )
				ampy = s.min
				ampx = s.minLoc
				break
				
			case "Avg":
				NMWaveStatsStructInit( s, nm.folder + wName, xWave = xWave, xbgn = xbgn, xend = xend )
				NMWaveStatsXY2( s )
				ampy = s.avg
				ampx = NaN
				break
				
			case "Slope":
				STRUCT NMLineStruct line
				NMLineStructInit( line, nm.folder + wName, xWave = xWave, xbgn = xbgn, xend = xend )
				NMLinearRegression2( line )
				ampy = line.b
				ampx = line.m
				break
				
			default:
				return NM2Error( 20, "alg", alg )
				
		endswitch
	
		U_AmpY[ wcnt ] = ampy
		U_AmpX[ wcnt ] = ampx
		
		nm.successList += wName + ";"
	
	endfor
	
	xl = NMNoteLabel( "x", nm.wList, "", folder = nm.folder)
	yl = NMNoteLabel( "y", nm.wList, "", folder = nm.folder )
	
	NMNoteType( "U_AmpX", "NMStatsX", xl, yl, "_FXN_" )
	NMNoteType( "U_AmpY", "NMStatsY", xl, yl, "_FXN_" )
	
	txt = "Stats Alg:" + alg + ";Stats Xbgn:" + num2str( xbgn ) + ";Stats Xend:" + num2str( xend ) + ";"
	
	Note U_AmpX, txt
	Note U_AmpY, txt
	
	txt = "WaveList:" + NMUtilityWaveListShort( wList )
	
	Note U_AmpX, txt
	Note U_AmpY, txt
	
	NMParamsComputeFailures( nm )
	
	if ( history )
		NMLoopHistory( nm )
	endif
	
	SetNMstr( NMDF + "OutputWaveList", nm.successList )

	return 0 // nm.successList
	
End // WaveListStats

//****************************************************************
//****************************************************************

Structure NMLineStruct
	
	// inputs
	
	String wName, xWave
	Variable xbgn, xend
	
	// outputs
	
	Variable m, b // y = mx + b

EndStructure

//****************************************************************
//****************************************************************

Function NMLineStructNull( s )
	STRUCT NMLineStruct &s
	
	s.wName = ""; s.xWave = ""
	s.xbgn = -inf; s.xend = inf
	s.m = NaN; s.b = NaN
	
End // NMLineStructNull

//****************************************************************
//****************************************************************

Function NMLineStructInit( s, wName [ xWave, xbgn, xend ] )
	STRUCT NMLineStruct &s
	String wName, xWave
	Variable xbgn, xend
	
	NMLineStructNull( s )
	
	s.wName = wName
	
	if ( !ParamIsDefault( xWave ) )
		s.xWave = xWave
	endif
	
	if ( !ParamIsDefault( xbgn ) )
		s.xbgn = xbgn
	endif
	
	if ( !ParamIsDefault( xend ) )
		s.xend = xend
	endif
	
End // NMLineStructInit

//****************************************************************
//****************************************************************

Function /S NMLinearRegression( wName [ xWave, xbgn, xend, history, deprecation ] )
	String wName // wave name
	String xWave // x-axis wave name
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	Variable history, deprecation
	
	STRUCT NMLineStruct s
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( ParamIsDefault( xWave ) )
		xWave = ""
	endif
	
	NMLineStructInit( s, wName, xWave = xWave, xbgn = xbgn, xend = xend )
	
	return NMLinearRegression2( s, history = history )
	
End // NMLinearRegression

//****************************************************************
//****************************************************************

Function /S NMLinearRegression2( s [ history ] )
	STRUCT NMLineStruct &s
	Variable history
	
	Variable pbgn, pend, pcnt
	Variable xavg, xsum, yavg, ysum, xysum, sumsqr, npnts
	String statsList
	
	if ( NMUtilityWaveTest( s.wName ) < 0 )
		return NM2ErrorStr( 1, "wName", s.wName )
	endif
	
	if ( numtype( s.xbgn ) > 0 )
		s.xbgn = -inf
	endif
	
	if ( numtype( s.xend ) > 0 )
		s.xend = inf
	endif
		
	if ( strlen( s.xWave ) > 0 ) 
	
		if ( NMUtilityWaveTest( s.xWave ) < 0 )
			return NM2ErrorStr( 1, "xWave", s.xWave )
		endif
		
		if ( numpnts( $s.wName ) != numpnts( $s.xWave ) )
			return NM2ErrorStr( 5, "xWave", s.xWave )
		endif
		
		pbgn = NMX2Pnt( s.xWave, s.xbgn )
		pend = NMX2Pnt( s.xWave, s.xend )
		
		Duplicate /O/R=[ pbgn, pend ] $s.xWave U_SlopeX
		Duplicate /O/R=[ pbgn, pend ] $s.wName U_SlopeY
		
	else
		
		Duplicate /O/R=( s.xbgn, s.xend ) $s.wName U_SlopeX, U_SlopeY
		
		U_SlopeX = x
		
	endif
	
	for ( pcnt = 0 ; pcnt < numpnts( U_SlopeX ) ; pcnt += 1 )
	
		if ( numtype( U_SlopeX[ pcnt ] * U_SlopeY[ pcnt ] ) > 0 )
			U_SlopeX[ pcnt ] = NaN
			U_SlopeY[ pcnt ] = NaN
		endif
		
	endfor
	
	Wavestats /Q/Z U_SlopeX
	
	if ( V_npnts < 2 )
		return ""
	endif
	
	xavg = V_avg
	xsum = V_sum
	
	Wavestats /Q/Z U_SlopeY
	
	yavg = V_avg
	ysum = V_sum
	
	for ( pcnt = 0 ; pcnt < numpnts( U_SlopeX ) ; pcnt += 1 )
	
		if ( numtype( U_SlopeY[ pcnt ] ) > 0 )
			continue
		endif
		
		xysum += ( U_SlopeX[ pcnt ] - xavg ) * ( U_SlopeY[ pcnt ] - yavg )
		sumsqr += ( U_SlopeX[ pcnt ] - xavg ) ^ 2
		npnts += 1
		
	endfor
	
	s.m = xysum / sumsqr
	s.b = ( ysum - s.m * xsum ) / npnts
	
	if ( numtype( s.m * s.b ) > 0 )
		s.m = NaN
		s.b = NaN
	endif
	
	KillWaves /Z U_SlopeY, U_SlopeX
	
	statsList = "m=" + num2str( s.m ) + ";b=" + num2str( s.b ) + ";"
	
	if ( history )
		Print s
	endif
	
	return statsList

End // NMLinearRegression2

//****************************************************************
//
//	NMMaxCurvatures
//	find maximum curvature by fitting sigmoidal function ( Boltzmann equation ) 
//	based on analysis of Fedchyshyn and Wang, J Physiol 2007 June, 581:581-602
//	returns three times t1, t2, t3, where max occurs
//
//****************************************************************

Structure NMMaxCurvStruct

	// inputs
	
	String wName, xWave
	Variable xbgn, xend

	// outputs
	
	Variable y1, y2, y3, x1, x2, x3, pnt1, pnt2, pnt3

EndStructure

//****************************************************************
//****************************************************************

Function NMMaxCurvStructNull( s )
	STRUCT NMMaxCurvStruct &s
	
	s.wName = ""; s.xWave = ""
	s.xbgn = -inf; s.xend = inf
	s.y1 = NaN; s.y2 = NaN; s.y3 = NaN
	s.x1 = NaN; s.x2 = NaN; s.x3 = NaN
	s.pnt1 = NaN; s.pnt2 = NaN; s.pnt3 = NaN
	
End // NMMaxCurvStructNull

//****************************************************************
//****************************************************************

Function NMMaxCurvStructInit( s, wName [ xWave, xbgn, xend ] )
	STRUCT NMMaxCurvStruct &s
	String wName, xWave
	Variable xbgn, xend
	
	NMMaxCurvStructNull( s )
	
	s.wName = wName
	
	if ( !ParamIsDefault( xWave ) )
		s.xWave = xWave
	endif
	
	if ( !ParamIsDefault( xbgn ) )
		s.xbgn = xbgn
	endif
	
	if ( !ParamIsDefault( xend ) )
		s.xend = xend
	endif
	
End // NMMaxCurvStructInit

//****************************************************************
//****************************************************************

Function /S NMMaxCurvatures( wName [ xWave, xbgn, xend, history, deprecation ] )
	String wName // wave name
	String xWave // x-axis wave name
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	Variable history, deprecation
	
	STRUCT NMMaxCurvStruct s
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( xWave ) )
		xWave = ""
	endif
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	NMMaxCurvStructInit( s, wName, xWave = xWave, xbgn = xbgn, xend = xend )
	
	return NMMaxCurvatures2( s, history = history )
	
End // NMMaxCurvatures

//****************************************************************
//****************************************************************

Function /S NMMaxCurvatures2( s [ history ] )
	STRUCT NMMaxCurvStruct &s
	Variable history
	
	Variable pbgn, pend, xflag, xmid = NaN, xc = NaN
	String statsList
	
	if ( NMUtilityWaveTest( s.wName ) < 0 )
		return NM2ErrorStr( 1, "wName", s.wName ) // bad input wave
	endif
	
	if ( numtype( s.xbgn ) > 0 )
		s.xbgn = -inf
	endif
	
	if ( numtype( s.xend ) > 0 )
		s.xend = inf
	endif
	
	if ( strlen( s.xWave ) > 0 ) 
	
		if ( NMUtilityWaveTest( s.xWave ) < 0 )
			return NM2ErrorStr( 1, "xWave", s.xWave )
		endif
		
		if ( numpnts( $s.wName ) != numpnts( $s.xWave ) )
			return NM2ErrorStr( 5, "xWave", s.xWave )
		endif
		
		pbgn = NMX2Pnt( s.xWave, s.xbgn )
		pend = NMX2Pnt( s.xWave, s.xend )
		
		xflag = 1
		
	endif
	
	if ( !xflag )
		pbgn = x2pnt( $s.wName, s.xbgn )
		pend = x2pnt( $s.wName, s.xend )
	endif
	
	WaveStats /Q/Z/R=[ pbgn, pend ] $s.wName
	
	if ( V_npnts < 2 )
		//return NM2ErrorStr( 90, "not enough data points to compute Sigmoid fit", "" )
		return ""
	endif
	
	Variable V_fitOptions = 4
	Variable V_FitError = 0
	Variable V_FitQuitReason = 0
	String S_Info = ""
	
	if ( xflag )
		Curvefit /Q/N Sigmoid $s.wName [ pbgn, pend ] /X=$s.xWave
	else
		Curvefit /Q/N Sigmoid $s.wName ( s.xbgn, s.xend )
	endif
	
	// y = K0 + K1 / ( 1 + exp( -( x - K2 ) / K3 ) )
	
	if ( ( strlen( S_Info ) > 0 ) && ( V_FitQuitReason == 0 ) && WaveExists( $"W_Coef" ) && ( numpnts( $"W_Coef" ) > 3 ) )
	
		Wave W_Coef
	
		xmid = W_Coef[ 2 ] // K2
		xc = W_Coef[ 3 ] // K3
	
	endif
	
	KillWaves /Z W_coef, W_sigma
	
	if ( numtype( xmid * xc ) > 0 )
		return ""
	endif
	
	s.x1 = xmid - ln( 5 + 2 * sqrt( 6 ) ) * xc
	s.x2 = xmid
	s.x3 = xmid - ln( 5 - 2 * sqrt( 6 ) ) * xc
	
	if ( ( s.x1 < s.xbgn ) || ( s.x1 > s.xend ) )
		s.x1 = NaN
	endif
	
	if ( ( s.x2 < s.xbgn ) || ( s.x2 > s.xend ) )
		s.x2 = NaN
	endif
	
	if ( ( s.x3 < s.xbgn ) || ( s.x3 > s.xend ) )
		s.x3 = NaN
	endif
	
	if ( xflag )
	
		Wave xtemp = $s.xWave
	
		s.pnt1 = NMX2Pnt( s.xWave, s.x1 )
		s.pnt2 = NMX2Pnt( s.xWave, s.x2 )
		s.pnt3 = NMX2Pnt( s.xWave, s.x3 )
		
	else
	
		s.pnt1 = x2pnt( $s.wName, s.x1 )
		s.pnt2 = x2pnt( $s.wName, s.x2 )
		s.pnt3 = x2pnt( $s.wName, s.x3 )
	
	endif
	
	Wave wtemp = $s.wName
	
	if ( ( s.pnt1 >= 0 ) && ( s.pnt1 < numpnts( wtemp ) ) )
		s.y1 = wtemp[ s.pnt1 ]
	else
		s.x1 = NaN
		s.y1 = NaN
	endif
	
	if ( ( s.pnt2 >= 0 ) && ( s.pnt2 < numpnts( wtemp ) ) )
		s.y2 = wtemp[ s.pnt2 ]
	else
		s.x2 = NaN
		s.y2 = NaN
	endif
	
	if ( ( s.pnt3 >= 0 ) && ( s.pnt3 < numpnts( wtemp ) ) )
		s.y3 = wtemp[ s.pnt3 ]
	else
		s.x3 = NaN
		s.y3 = NaN
	endif
	
	statsList = "t1=" + num2str( s.x1 ) + ";t2=" + num2str( s.x2 ) + ";t3=" + num2str( s.x3 ) + ";"
	
	if ( history )
		Print s
	endif
	
	return statsList

End // NMMaxCurvatures2

//****************************************************************
//****************************************************************

Structure NMFindLevelStruct

	// inputs
	
	Variable level, xbgn, xend, edge
	String wName, xWave
	
	// outputs
	
	Variable x, pnt

EndStructure

//****************************************************************
//****************************************************************

Function NMFindLevelStructNull( s )
	STRUCT NMFindLevelStruct &s
	
	s.level = NaN; s.xbgn = -inf; s.xend = inf; s.edge = 0
	s.wName = ""; s.xWave = ""
	s.x = NaN; s.pnt = NaN
	
End // NMFindLevelStructNull

//****************************************************************
//****************************************************************

Function NMFindLevelStructInit( s, level, wName [ xWave, xbgn, xend, edge ] )
	STRUCT NMFindLevelStruct &s
	Variable level
	String wName, xWave
	Variable xbgn, xend, edge
	
	NMFindLevelStructNull( s )
	
	s.level = level
	s.wName = wName
	s.edge = edge
	
	if ( !ParamIsDefault( xWave ) )
		s.xWave = xWave
	endif
	
	if ( !ParamIsDefault( xbgn ) )
		s.xbgn = xbgn
	endif
	
	if ( !ParamIsDefault( xend ) )
		s.xend = xend
	endif
	
End // NMFindLevelStructInit

//****************************************************************
//****************************************************************

Function NMFindLevel( level, wName [ xWave, xbgn, xend, edge, point ] ) // like Igor FindLevel but allows xy-paired data
	Variable level // level to find
	String wName // wave name
	String xWave // x-axis wave name
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	Variable edge // see FindLevel EDGE flag ( 0 ) either increasing or decreasing ( 1 ) increasing ( 2 ) decreasing
	Variable point // return V_LevelX in point value
	
	STRUCT NMFindLevelStruct s
	
	if ( NMUtilityWaveTest( wName ) < 0 )
		NM2Error( 1, "wName", wName )
		return NaN
	endif
	
	if ( ParamIsDefault( xWave ) )
		xWave = ""
	endif
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) == 2 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) == 2 ) )
		xend = inf
	endif
	
	NMFindLevelStructInit( s, level, wName, xWave = xWave, xbgn = xbgn, xend = xend, edge = edge )
	NMFindLevel2( s )
	
	if ( point )
		return s.pnt
	else
		return s.x
	endif
	
End // NMFindLevel

//****************************************************************
//****************************************************************

Function NMFindLevel2( s ) // like Igor FindLevel but allows xy-paired data
	STRUCT NMFindLevelStruct &s
	
	Variable pbgn, pend
	
	if ( NMUtilityWaveTest( s.wName ) < 0 )
		NM2Error( 1, "wName", s.wName )
		return NaN
	endif
	
	if ( numtype( s.xbgn ) == 2 )
		s.xbgn = -inf
	endif
	
	if ( numtype( s.xend ) == 2 )
		s.xend = inf
	endif
	
	if ( ( s.edge != 0 ) && ( s.edge != 1 ) && ( s.edge != 2 ) )
		NM2Error( 10, "edge", num2str( s.edge ) )
		return NaN
	endif
	
	s.pnt = NaN
	s.x = NaN
	
	if ( strlen( s.xWave ) > 0 )
	
		if ( NMUtilityWaveTest( s.xWave ) < 0 )
			NM2Error( 1, "xWave", s.xWave )
			return NaN
		endif
		
		if ( numpnts( $s.xWave ) != numpnts( $s.wName ) )
			NM2Error( 5, "xWave", s.xWave )
			return NaN
		endif
		
		pbgn = NMX2Pnt( s.xWave, s.xbgn )
		pend = NMX2Pnt( s.xWave, s.xend )
	
		FindLevel /EDGE=( s.edge )/P/Q/R=[ pbgn, pend ] $s.wName, s.level
		
		if ( V_flag == 0 ) // found
		
			s.pnt = V_LevelX
			
			Wave xtemp = $s.xWave
			
			if ( ( s.pnt >= 0 ) && ( s.pnt < numpnts( xtemp ) ) )
				s.x = xtemp[ s.pnt ]
			endif
		
		endif
		
	else
	
		FindLevel /EDGE=( s.edge )/Q/R=( s.xbgn, s.xend ) $s.wName, s.level
		
		if ( V_flag == 0 ) // found
		
			s.x = V_LevelX
			s.pnt = x2pnt( $s.wName, s.x )
			
			if ( ( s.pnt < 0 ) || ( s.pnt >= numpnts( $s.wName ) ) )
				s.pnt = NaN
				s.x = NaN
			endif
		
		endif
		
	endif
	
	return s.x
	
End // NMFindLevel2

//****************************************************************
//****************************************************************

Structure NMMinAvgStruct

	// inputs
	
	String wName, xWave
	Variable avgWin, xbgn, xend
	
	// outputs

	Variable min, minLoc, minRowLoc, avg

EndStructure // NMMinAvgStruct

//****************************************************************
//****************************************************************

Function NMMinAvgStructNull( s )
	STRUCT NMMinAvgStruct &s
	
	s.wName = ""; s.xWave = ""
	s.avgWin = NaN; s.xbgn = -inf; s.xend = inf
	s.min = NaN; s.minLoc = NaN; s.minRowLoc = NaN; s.avg = NaN
	
End // NMMinAvgStructNull

//****************************************************************
//****************************************************************

Function NMMinAvgStructInit( s, avgWin, wName [ xWave, xbgn, xend ] )
	STRUCT NMMinAvgStruct &s
	Variable avgWin, xbgn, xend
	String wName, xWave
	
	NMMinAvgStructNull( s )
	
	s.avgWin = avgWin
	s.wName = wName
	
	if ( !ParamIsDefault( xWave ) )
		s.xWave = xWave
	endif
	
	if ( !ParamIsDefault( xbgn ) )
		s.xbgn = xbgn
	endif
	
	if ( !ParamIsDefault( xend ) )
		s.xend = xend
	endif
	
End // NMMinAvgStructInit

//****************************************************************
//****************************************************************

Function /S NMMinAvg( avgWin, wName [ xWave, xbgn, xend, history ] )
	Variable avgWin // x-scale size of average window
	String wName // wave name
	String xWave // x-axis wave name
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	Variable history
	
	STRUCT NMMinAvgStruct s
	
	if ( ParamIsDefault( xWave ) )
		s.xWave = ""
	endif
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	NMMinAvgStructInit( s, avgWin, wName, xWave = xWave, xbgn = xbgn, xend = xend )
	
	return NMMinAvg2( s, history = history )
	
End // NMMinAvg

//****************************************************************
//****************************************************************

Function /S NMMinAvg2( s [ history ] )
	STRUCT NMMinAvgStruct &s
	Variable history
	
	Variable x1, x2, p1, p2, pbgn, pend, xflag
	String statsList
	
	if ( numtype( s.avgWin ) > 0 )
		return NM2ErrorStr( 10, "avgWin", num2str( s.avgWin ) )
	endif
	
	if ( NMUtilityWaveTest( s.wName ) < 0 )
		return NM2ErrorStr( 1, "wName", s.wName )
	endif
	
	if ( numtype( s.xbgn ) > 0 )
		s.xbgn = -inf
	endif
	
	if ( numtype( s.xend ) > 0 )
		s.xend = inf
	endif
	
	if ( strlen( s.xWave ) > 0 ) 
	
		if ( NMUtilityWaveTest( s.xWave ) < 0 )
			return NM2ErrorStr( 1, "xWave", s.xWave )
		endif
		
		if ( numpnts( $s.xWave ) != numpnts( $s.wName ) )
			return NM2ErrorStr( 5, "xWave", s.xWave )
		endif
		
		pbgn = NMX2Pnt( s.xWave, s.xbgn )
		pend = NMX2Pnt( s.xWave, s.xend )
		
		xflag = 1
		
	endif
	
	if ( xflag )
	
		WaveStats /Q/R=[ pbgn, pend ] $s.wName
	
		if ( numtype( V_min * V_minLoc * V_minRowLoc ) > 0 )
			return ""
		endif
		
		s.min = V_min
		s.minLoc = V_minLoc
		s.minRowLoc = V_minRowLoc
	
		Wave xtemp = $s.xWave
		
		if ( ( V_minRowLoc >= 0 ) && ( V_minRowLoc < numpnts( xtemp ) ) )
	
			s.minLoc = xtemp[ V_minRowLoc ]
			
			x1 = s.minLoc - s.avgWin / 2
			x2 = s.minLoc + s.avgWin / 2
			
			p1 = NMX2Pnt( s.xWave, x1 )
			p2 = NMX2Pnt( s.xWave, x2 )
		
			WaveStats /Q/R=[ p1, p2 ] $s.wName
			
			s.avg = V_avg
		
		endif
	
	else
	
		WaveStats /Q/R=( s.xbgn, s.xend ) $s.wName
	
		if ( numtype( V_min * V_minLoc * V_minRowLoc ) > 0 )
			return ""
		endif
		
		s.min = V_min
		s.minLoc = V_minLoc
		s.minRowLoc = V_minRowLoc
	
		x1 = s.minLoc - s.avgWin / 2
		x2 = s.minLoc + s.avgWin / 2
	
		WaveStats /Q/R=( x1, x2 ) $s.wName
		
		s.avg = V_avg
	
	endif
	
	statsList = "min=" + num2str( s.min ) + ";minLoc=" + num2str( s.minLoc ) + ";"
	statsList += ";minRowLoc=" + num2str( s.minRowLoc ) + ";avg=" + num2str( s.avg ) + ";"
	
	if ( history )
		Print s
	endif
	
	return statsList

End // NMMinAvg2

//****************************************************************
//****************************************************************

Structure NMMaxAvgStruct

	// inputs
	
	String wName, xWave
	Variable avgWin, xbgn, xend
	
	// outputs

	Variable max, maxLoc, maxRowLoc, avg

EndStructure // NMMaxAvgStruct

//****************************************************************
//****************************************************************

Function NMMaxAvgStructNull( s )
	STRUCT NMMaxAvgStruct &s
	
	s.wName = ""; s.xWave = ""
	s.avgWin = NaN; s.xbgn = -inf; s.xend = inf
	s.max = NaN; s.maxLoc = NaN; s.maxRowLoc = NaN; s.avg = NaN
	
End // NMMaxAvgStructNull

//****************************************************************
//****************************************************************

Function NMMaxAvgStructInit( s, avgWin, wName [ xWave, xbgn, xend ] )
	STRUCT NMMaxAvgStruct &s
	Variable avgWin, xbgn, xend
	String wName, xWave
	
	NMMaxAvgStructNull( s )
	
	s.avgWin = avgWin
	s.wName = wName
	
	if ( !ParamIsDefault( xWave ) )
		s.xWave = xWave
	endif
	
	if ( !ParamIsDefault( xbgn ) )
		s.xbgn = xbgn
	endif
	
	if ( !ParamIsDefault( xend ) )
		s.xend = xend
	endif
	
End // NMMaxAvgStructInit

//****************************************************************
//****************************************************************

Function /S NMMaxAvg( avgWin, wName [ xWave, xbgn, xend, history ] )
	Variable avgWin // x-scale size of average window
	String wName // wave name
	String xWave // x-axis wave name
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	Variable history
	
	STRUCT NMMaxAvgStruct s
	
	if ( ParamIsDefault( xWave ) )
		s.xWave = ""
	endif
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	NMMaxAvgStructInit( s, avgWin, wName, xWave = xWave, xbgn = xbgn, xend = xend )
	
	return NMMaxAvg2( s, history = history )
	
End // NMMaxAvg

//****************************************************************
//****************************************************************

Function /S NMMaxAvg2( s [ history ] )
	STRUCT NMMaxAvgStruct &s
	Variable history
	
	Variable x1, x2, p1, p2, pbgn, pend, xflag
	String statsList
	
	if ( numtype( s.avgWin ) > 0 )
		return NM2ErrorStr( 10, "avgWin", num2str( s.avgWin ) )
	endif
	
	if ( NMUtilityWaveTest( s.wName ) < 0 )
		return NM2ErrorStr( 1, "wName", s.wName )
	endif
	
	if ( numtype( s.xbgn ) > 0 )
		s.xbgn = -inf
	endif
	
	if ( numtype( s.xend ) > 0 )
		s.xend = inf
	endif
	
	if ( strlen( s.xWave ) > 0 ) 
	
		if ( NMUtilityWaveTest( s.xWave ) < 0 )
			return NM2ErrorStr( 1, "xWave", s.xWave )
		endif
		
		if ( numpnts( $s.wName ) != numpnts( $s.xWave ) )
			return NM2ErrorStr( 5, "xWave", s.xWave )
		endif
		
		pbgn = NMX2Pnt( s.xWave, s.xbgn )
		pend = NMX2Pnt( s.xWave, s.xend )
		
		xflag = 1
		
	endif
	
	if ( xflag )
	
		WaveStats /Q/R=[ pbgn, pend ] $s.wName
	
		if ( numtype( V_max * V_maxLoc * V_maxRowLoc ) > 0 )
			return ""
		endif
		
		s.max = V_max
		s.maxLoc = V_maxLoc
		s.maxRowLoc = V_maxRowLoc
	
		Wave xtemp = $s.xWave
		
		if ( ( V_maxRowLoc >= 0 ) && ( V_maxRowLoc < numpnts( xtemp ) ) )
	
			s.maxLoc = xtemp[ V_maxRowLoc ]
			
			x1 = s.maxLoc - s.avgWin / 2
			x2 = s.maxLoc + s.avgWin / 2
			
			p1 = NMX2Pnt( s.xWave, x1 )
			p2 = NMX2Pnt( s.xWave, x2 )
		
			WaveStats /Q/R=[ p1, p2 ] $s.wName
			
			s.avg = V_avg
		
		endif
	
	else
	
		WaveStats /Q/R=( s.xbgn, s.xend ) $s.wName
	
		if ( numtype( V_max * V_maxLoc * V_maxRowLoc ) > 0 )
			return ""
		endif
		
		s.max = V_max
		s.maxLoc = V_maxLoc
		s.maxRowLoc = V_maxRowLoc
	
		x1 = s.maxLoc - s.avgWin / 2
		x2 = s.maxLoc + s.avgWin / 2
	
		WaveStats /Q/R=( x1, x2 ) $s.wName
		
		s.avg = V_avg
	
	endif
	
	statsList = "max=" + num2str( s.max ) + ";maxLoc=" + num2str( s.maxLoc ) + ";"
	statsList += ";maxRowLoc=" + num2str( s.maxRowLoc ) + ";avg=" + num2str( s.avg ) + ";"
	
	if ( history )
		Print s
	endif
	
	return statsList

End // NMMaxAvg2

//****************************************************************
//****************************************************************

Function NMMedian( wName [ xWave, xbgn, xend ] )
	String wName // wave name
	String xWave // x-axis wave name
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	
	Variable pbgn, pend, xflag, npnts, median
	
	if ( NMUtilityWaveTest( wName ) < 0 )
		NM2Error( 1, "wName", wName )
		return NaN
	endif
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( ParamIsDefault( xWave ) )
	
		xWave = ""
		
	elseif ( strlen( xWave ) > 0 ) 
	
		if ( NMUtilityWaveTest( xWave ) < 0 )
			NM2Error( 1, "xWave", xWave )
			return NaN
		endif
		
		if ( numpnts( $wName ) != numpnts( $xWave ) )
			NM2Error( 5, "xWave", xWave )
			return NaN
		endif
		
		pbgn = NMX2Pnt( xWave, xbgn )
		pend = NMX2Pnt( xWave, xend )
		
		xflag = 1
		
	endif
	
	npnts = numpnts( $wName )
	
	if ( !xflag )
		pbgn = x2pnt( $wName, xbgn )
		pend = x2pnt( $wName, xend )
		pbgn = max( pbgn, 0 )
		pend = min( pend, npnts - 1 )
	endif
	
	if ( ( pbgn == 0 ) && ( pend == npnts - 1 ) )
	
		median = StatsMedian( $wName )
		
	else
	
		Duplicate /O/R=[ pbgn, pend ] $wName U_NMStatsMedian
		median = StatsMedian( U_NMStatsMedian )
		KillWaves /Z U_NMStatsMedian
	
	endif
	
	return median
	
End // NMMedian

//****************************************************************
//
//	NMPathLength
//	compute the distance between data points ( coastline function )
//
//****************************************************************

Function NMPathLength( wName [ xWave, xbgn, xend ] )
	String wName // wave name
	String xWave // x-axis wave name
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	
	Variable icnt, distance, dx, dy, pbgn, pend, xflag, npnts, xscale
	String rslts = ""
	
	if ( NMUtilityWaveTest( wName ) < 0 )
		NM2Error( 1, "wName", wName )
		return NaN
	endif
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( ParamIsDefault( xWave ) )
	
		xWave = ""
		
	elseif ( strlen( xWave ) > 0 ) 
	
		if ( NMUtilityWaveTest( xWave ) < 0 )
			NM2Error( 1, "xWave", xWave )
			return NaN
		endif
		
		if ( numpnts( $wName ) != numpnts( $xWave ) )
			NM2Error( 5, "xWave", xWave )
			return NaN
		endif
		
		Wave xtemp = $xWave
		
		pbgn = NMX2Pnt( xWave, xbgn )
		pend = NMX2Pnt( xWave, xend )
		
		xflag = 1
		
	endif
	
	Wave wtemp = $wName
	
	npnts = numpnts( wtemp )
	dx = deltax( wtemp )
	
	if ( !xflag )
		pbgn = x2pnt( wtemp, xbgn )
		pend = x2pnt( wtemp, xend )
		pbgn = max( pbgn, 0 )
		pend = min( pend, npnts - 1 )
	endif
	
	for ( icnt = pbgn ; icnt <= pend ; icnt += 1 )
	
		if ( icnt + 1 >= npnts )
			break // no more data points
		endif
		
		dy = wtemp[ icnt + 1 ] - wtemp[ icnt ]
		
		if ( xflag )
			dx = xtemp[ icnt + 1 ] - xtemp[ icnt ]
		endif
		
		distance += sqrt( dx * dx + dy * dy ) 
		
	endfor
	
	return distance

End // NMPathLength

//****************************************************************
//****************************************************************

Structure NMRiseTimeStruct

	// inputs

	String wName, xWave
	Variable bbgn, bend, xbgn, xend, pcnt1, pcnt2, negative

	// outputs
	
	Variable baseline
	Variable min, minLoc, minRowLoc
	Variable max, maxLoc, maxRowLoc
	Variable y1, y2, x1, x2, pnt1, pnt2, riseTime
	Variable m, b // linear regression

EndStructure // NMRiseTimeStruct

//****************************************************************
//****************************************************************

Function NMRiseTimeStructNull( s )
	STRUCT NMRiseTimeStruct &s
	
	s.wName = ""; s.xWave= ""
	s.bbgn = NaN; s.bend = NaN; s.xbgn = NaN; s.xend = NaN
	s.pcnt1 = NaN; s.pcnt2 = NaN; s.negative = 0

	s.baseline = NaN
	s.min = NaN; s.minLoc = NaN; s.minRowLoc = NaN
	s.max = NaN; s.maxLoc = NaN; s.maxRowLoc = NaN
	s.y1 = NaN; s.y2 = NaN; s.x1 = NaN; s.x2 = NaN; s.pnt1 = NaN; s.pnt2 = NaN
	s.riseTime = NaN; s.m = NaN; s.b = NaN

End // NMRiseTimeStructNull

//****************************************************************
//****************************************************************

Function NMRiseTimeStructInit( s, bbgn, bend, xbgn, xend, pcnt1, pcnt2, wName [ xWave, negative ] )
	STRUCT NMRiseTimeStruct &s
	Variable bbgn, bend, xbgn, xend, pcnt1, pcnt2
	String wName, xWave
	Variable negative
	
	NMRiseTimeStructNull( s )
	
	s.wName = wName
	s.bbgn = bbgn; s.bend = bend; s.xbgn = xbgn; s.xend = xend
	s.pcnt1 =pcnt1; s.pcnt2 = pcnt2; s.negative = negative
	
	if ( !ParamIsDefault( xWave ) )
		s.xWave= xWave
	endif
	
End // NMRiseTimeStructInit

//****************************************************************
//****************************************************************

Function NMRiseTime( bbgn, bend, xbgn, xend, pcnt1, pcnt2, wName [ xWave, negative, slope, searchFromPeak, history ] )
	Variable bbgn, bend // x-axis baseline window
	Variable xbgn, xend // x-axis rise-time window ( should include max/min location )
	Variable pcnt1, pcnt2 // % begin and end ( e.g. 10 and 90 )
	String wName // wave name
	String xWave // x-axis wave name
	Variable negative // ( 0 ) positive peak, default ( 1 ) negative peak
	Variable slope // compute slope between x1 and x2
	Variable searchFromPeak // ( 0 ) search forward from xbgn ( 1 ) search backward from peak location
	Variable history
	
	STRUCT NMRiseTimeStruct s
	
	if ( ParamIsDefault( xWave ) )
		xWave = ""
	endif
	
	NMRiseTimeStructInit( s, bbgn, bend, xbgn, xend, pcnt1, pcnt2, wName, xWave = xWave, negative = negative )
	
	return NMRiseTime2( s, slope = slope, searchFromPeak = searchFromPeak, history = history )
	
End // NMRiseTime

//****************************************************************
//****************************************************************

Function NMRiseTime2( s [ slope, searchFromPeak, history ] )
	STRUCT NMRiseTimeStruct &s
	Variable slope // compute slope between x1 and x2
	Variable searchFromPeak // ( 0 ) search forward from xbgn ( 1 ) search backward from peak location
	Variable history
	
	Variable xflag, edge
	
	STRUCT NMWaveStatsStruct stats
	NMWaveStatsStructNull( stats )
	
	if ( NMUtilityWaveTest( s.wName ) < 0 )
		NM2Error( 1, "wName", s.wName )
		return NaN
	endif
	
	if ( ( numtype( s.pcnt1 ) > 0 ) || ( s.pcnt1 < 0 ) || ( s.pcnt1 > 100 ) )
		NM2Error( 10, "pcnt1", num2str( s.pcnt1 ) )
		return NaN
	endif
	
	if ( ( numtype( s.pcnt2 ) > 0 ) || ( s.pcnt2 < 0 ) || ( s.pcnt2 > 100 ) )
		NM2Error( 10, "pcnt2", num2str( s.pcnt2 ) )
		return NaN
	endif
	
	if ( numtype( s.bbgn ) > 0 )
		s.bbgn = -inf
	endif
	
	if ( numtype( s.bend ) > 0 )
		s.bend = inf
	endif
	
	if ( numtype( s.xbgn ) > 0 )
		s.xbgn = -inf
	endif
	
	if ( numtype( s.xend ) > 0 )
		s.xend = inf
	endif
	
	if ( strlen( s.xWave ) > 0 ) 
	
		if ( NMUtilityWaveTest( s.xWave ) < 0 )
			NM2Error( 1, "xWave", s.xWave )
			return NaN
		endif
		
		if ( numpnts( $s.xWave ) != numpnts( $s.wName ) )
			NM2Error( 5, "xWave", s.xWave )
			return NaN
		endif
		
		xflag = 1
		
	endif
	
	NMWaveStatsStructInit( stats, s.wName, xWave = s.xWave, xbgn = s.bbgn, xend = s.bend )
	NMWaveStatsXY2( stats )
	
	if ( numtype( stats.avg ) > 0 )
		return NaN
	endif
	
	s.baseline = stats.avg
	
	NMWaveStatsStructInit( stats, s.wName, xWave = s.xWave, xbgn = s.xbgn, xend = s.xend )
	NMWaveStatsXY2( stats )
	
	if ( s.negative )
	
		edge = 2
	
		s.min = stats.min
		s.minLoc = stats.minLoc
		s.minRowLoc = stats.minRowLoc
		
		s.y1 = s.baseline + s.pcnt1 * ( s.min - s.baseline ) / 100
		s.y2 = s.baseline + s.pcnt2 * ( s.min - s.baseline ) / 100
		
		if ( searchFromPeak )
			s.x1 = NMFindLevel( s.y1, s.wName, xWave = s.xWave, xbgn = s.minLoc, xend = s.xbgn, edge = edge )
			s.x2 = NMFindLevel( s.y2, s.wName, xWave = s.xWave, xbgn = s.minLoc, xend = s.xbgn, edge = edge )
		else
			s.x1 = NMFindLevel( s.y1, s.wName, xWave = s.xWave, xbgn = s.xbgn, xend = s.minLoc, edge = edge )
			s.x2 = NMFindLevel( s.y2, s.wName, xWave = s.xWave, xbgn = s.xbgn, xend = s.minLoc, edge = edge )
		endif
		
		if ( xflag )
			s.pnt1 = NMX2Pnt( s.xWave, s.x1 )
			s.pnt2 = NMX2Pnt( s.xWave, s.x2 )
		else
		
			s.pnt1 = x2pnt( $s.wName, s.x1 )
			s.pnt2 = x2pnt( $s.wName, s.x2 )
			
			if ( ( s.pnt1 < 0 ) || ( s.pnt1 >= numpnts( $s.wName ) ) )
				s.pnt1 = NaN
				s.x1 = NaN
			endif
			
			if ( ( s.pnt2 < 0 ) || ( s.pnt2 >= numpnts( $s.wName ) ) )
				s.pnt2 = NaN
				s.x2 = NaN
			endif
			
		endif
		
		s.riseTime = s.x2 - s.x1
		
	else
	
		edge = 1
	
		s.max = stats.max
		s.maxLoc = stats.maxLoc
		s.maxRowLoc = stats.maxRowLoc
		
		s.y1 = s.baseline + s.pcnt1 * ( s.max - s.baseline ) / 100
		s.y2 = s.baseline + s.pcnt2 * ( s.max - s.baseline ) / 100
		
		if ( searchFromPeak )
			s.x1 = NMFindLevel( s.y1, s.wName, xWave = s.xWave, xbgn = s.maxLoc, xend = s.xbgn, edge = edge )
			s.x2 = NMFindLevel( s.y2, s.wName, xWave = s.xWave, xbgn = s.maxLoc, xend = s.xbgn, edge = edge )
		else
			s.x1 = NMFindLevel( s.y1, s.wName, xWave = s.xWave, xbgn = s.xbgn, xend = s.maxLoc, edge = edge )
			s.x2 = NMFindLevel( s.y2, s.wName, xWave = s.xWave, xbgn = s.xbgn, xend = s.maxLoc, edge = edge )
		endif
		
		if ( xflag )
			s.pnt1 = NMX2Pnt( s.xWave, s.x1 )
			s.pnt2 = NMX2Pnt( s.xWave, s.x2 )
		else
			s.pnt1 = x2pnt( $s.wName, s.x1 )
			s.pnt2 = x2pnt( $s.wName, s.x2 )
			
			if ( ( s.pnt1 < 0 ) || ( s.pnt1 >= numpnts( $s.wName ) ) )
				s.pnt1 = NaN
				s.x1 = NaN
			endif
			
			if ( ( s.pnt2 < 0 ) || ( s.pnt2 >= numpnts( $s.wName ) ) )
				s.pnt2 = NaN
				s.x2 = NaN
			endif
		
		endif
		
		s.riseTime = s.x2 - s.x1
		
	endif
	
	if ( slope )
		STRUCT NMLineStruct line
		NMLineStructInit( line, s.wName, xWave = s.xWave, xbgn = s.x1, xend = s.x2 )
		NMLinearRegression2( line )
		s.m = line.m
		s.b = line.b
	endif
	
	if ( history )
		Print s
	endif
	
	return s.riseTime
	
End // NMRiseTime2

//****************************************************************
//****************************************************************

Structure NMDecayTimeStruct

	// inputs

	String wName, xWave
	Variable bbgn, bend, xbgn, xend, pcntDecay, negative

	// outputs
	
	Variable baseline
	Variable min, minLoc, minRowLoc
	Variable max, maxLoc, maxRowLoc
	Variable yDecay, xDecay, pntDecay, decayTime

EndStructure // NMDecayTimeStruct

//****************************************************************
//****************************************************************

Function NMDecayTimeStructNull( s )
	STRUCT NMDecayTimeStruct &s
	
	s.wName = ""; s.xWave= ""
	s.bbgn = NaN; s.bend = NaN; s.xbgn = NaN; s.xend = NaN
	s.pcntDecay = NaN; s.negative = 0

	s.baseline = NaN
	s.min = NaN; s.minLoc = NaN; s.minRowLoc = NaN
	s.max = NaN; s.maxLoc = NaN; s.maxRowLoc = NaN
	s.yDecay = NaN; s.xDecay = NaN; s.pntDecay = NaN; s.decayTime = NaN

End // NMDecayTimeStructNull

//****************************************************************
//****************************************************************

Function NMDecayTimeStructInit( s, bbgn, bend, xbgn, xend, pcntDecay, wName, [ xWave, negative ] )
	STRUCT NMDecayTimeStruct &s
	Variable bbgn, bend, xbgn, xend, pcntDecay
	String wName, xWave
	Variable negative
	
	NMDecayTimeStructNull( s )
	
	s.wName = wName
	s.bbgn = bbgn; s.bend = bend; s.xbgn = xbgn; s.xend = xend
	s.pcntDecay =pcntDecay; s.negative = negative
	
	if ( !ParamIsDefault( xWave ) )
		s.xWave= xWave
	endif
	
End // NMDecayTimeStructInit

//****************************************************************
//****************************************************************

Function NMDecayTime( bbgn, bend, xbgn, xend, pcntDecay, wName [ xWave, negative history ] ) // see NMDecayTime2
	Variable bbgn, bend // x-axis baseline window
	Variable xbgn, xend // x-axis decay-time window ( should include max/min location )
	Variable pcntDecay // % decay ( e.g. 36.8 )
	String wName // wave name
	String xWave // x-axis wave name
	Variable negative // ( 0 ) positive peak, default ( 1 ) negative peak
	Variable history
	
	STRUCT NMDecayTimeStruct s
	
	if ( ParamIsDefault( xWave ) )
		xWave = ""
	endif
	
	NMDecayTimeStructInit( s, bbgn, bend, xbgn, xend, pcntDecay, wName, xWave = xWave, negative = negative )
	
	return NMDecayTime2( s, history = history )
	
End // NMDecayTime

//****************************************************************
//****************************************************************

Function NMDecayTime2( s [ history ] )
	STRUCT NMDecayTimeStruct &s
	Variable history
	
	Variable xflag, edge
	
	STRUCT NMWaveStatsStruct stats
	NMWaveStatsStructNull( stats )
	
	if ( NMUtilityWaveTest( s.wName ) < 0 )
		NM2Error( 1, "wName", s.wName )
		return NaN
	endif
	
	if ( ( numtype( s.pcntDecay ) > 0 ) || ( s.pcntDecay < 0 ) || ( s.pcntDecay > 100 ) )
		NM2Error( 10, "pcntDecay", num2str( s.pcntDecay ) )
		return NaN
	endif
	
	if ( numtype( s.bbgn ) > 0 )
		s.bbgn = -inf
	endif
	
	if ( numtype( s.bend ) > 0 )
		s.bend = inf
	endif
	
	if ( numtype( s.xbgn ) > 0 )
		s.xbgn = -inf
	endif
	
	if ( numtype( s.xend ) > 0 )
		s.xend = inf
	endif
	
	if ( strlen( s.xWave ) > 0 ) 
	
		if ( NMUtilityWaveTest( s.xWave ) < 0 )
			NM2Error( 1, "xWave", s.xWave )
			return NaN
		endif
		
		if ( numpnts( $s.xWave ) != numpnts( $s.wName ) )
			NM2Error( 5, "xWave", s.xWave )
			return NaN
		endif
		
		xflag = 1
		
	endif
	
	NMWaveStatsStructInit( stats, s.wName, xWave = s.xWave, xbgn = s.bbgn, xend = s.bend )
	NMWaveStatsXY2( stats )
	
	if ( numtype( stats.avg ) > 0 )
		return NaN
	endif
	
	s.baseline = stats.avg
	
	NMWaveStatsStructInit( stats, s.wName, xWave = s.xWave, xbgn = s.xbgn, xend = s.xend )
	NMWaveStatsXY2( stats )
	
	if ( s.negative )
	
		//edge = 2
	
		s.min = stats.min
		s.minLoc = stats.minLoc
		s.minRowLoc = stats.minRowLoc
		
		s.yDecay = s.baseline + s.pcntDecay * ( s.min - s.baseline ) / 100
		s.xDecay = NMFindLevel( s.yDecay, s.wName, xWave = s.xWave, xbgn = s.minLoc, xend = s.xend, edge = edge )
		
		if ( xflag )
			s.pntDecay = NMX2Pnt( s.xWave, s.xDecay )
		else
		
			s.pntDecay = x2pnt( $s.wName, s.xDecay )
			
			if ( ( s.pntDecay < 0 ) || ( s.pntDecay >= numpnts( $s.wName ) ) )
				s.pntDecay = NaN
				s.xDecay = NaN
			endif
		
		endif
		
		s.decayTime = s.xDecay - s.minLoc
		
	else
	
		//edge = 1
	
		s.max = stats.max
		s.maxLoc = stats.maxLoc
		s.maxRowLoc = stats.maxRowLoc
		
		s.yDecay = s.baseline + s.pcntDecay * ( s.max - s.baseline ) / 100
		s.xDecay = NMFindLevel( s.yDecay, s.wName, xWave = s.xWave, xbgn = s.maxLoc, xend = s.xend, edge = edge )
		
		if ( xflag )
			s.pntDecay = NMX2Pnt( s.xWave, s.xDecay )
		else
		
			s.pntDecay = x2pnt( $s.wName, s.xDecay )
			
			if ( ( s.pntDecay < 0 ) || ( s.pntDecay >= numpnts( $s.wName ) ) )
				s.pntDecay = NaN
				s.xDecay = NaN
			endif
			
		endif
		
		s.decayTime = s.xDecay - s.maxLoc
		
	endif
	
	if ( history )
		Print s
	endif
	
	return s.decayTime
	
End // NMDecayTime2

//****************************************************************
//****************************************************************

Structure NMFWHMStruct

	// inputs

	String wName, xWave
	Variable bbgn, bend, xbgn, xend, negative

	// outputs
	
	Variable baseline
	Variable min, minLoc, minRowLoc
	Variable max, maxLoc, maxRowLoc
	Variable y, x1, x2, pnt1, pnt2, fwhm

EndStructure // NMFWHMStruct

//****************************************************************
//****************************************************************

Function NMFWHMStructNull( s )
	STRUCT NMFWHMStruct &s
	
	s.wName = ""; s.xWave= ""
	s.bbgn = NaN; s.bend = NaN; s.xbgn = NaN; s.xend = NaN
	s.negative = 0

	s.baseline = NaN
	s.min = NaN; s.minLoc = NaN; s.minRowLoc = NaN
	s.max = NaN; s.maxLoc = NaN; s.maxRowLoc = NaN
	s.y = NaN; s.x1 = NaN; s.x2 = NaN; s.pnt1 = NaN; s.pnt2 = NaN
	s.fwhm = NaN

End // NMFWHMStructNull

//****************************************************************
//****************************************************************

Function NMFWHMStructInit( s, bbgn, bend, xbgn, xend, wName [ xWave, negative ] )
	STRUCT NMFWHMStruct &s
	Variable bbgn, bend, xbgn, xend
	String wName, xWave
	Variable negative
	
	NMFWHMStructNull( s )
	
	s.wName = wName
	s.bbgn = bbgn; s.bend = bend; s.xbgn = xbgn; s.xend = xend
	s.negative = negative
	
	if ( !ParamIsDefault( xWave ) )
		s.xWave= xWave
	endif
	
End // NMFWHMStructInit

//****************************************************************
//****************************************************************

Function NMFWHM( bbgn, bend, xbgn, xend, wName [ xWave, negative, history ] )
	Variable bbgn, bend // x-axis baseline window
	Variable xbgn, xend // x-axis fwhm window ( should include max/min location )
	String wName // wave name
	String xWave // x-axis wave name
	Variable negative // ( 0 ) positive peak, default ( 1 ) negative peak
	Variable history
	
	STRUCT NMFWHMStruct s
	
	if ( ParamIsDefault( xWave ) )
		xWave = ""
	endif
	
	NMFWHMStructInit( s, bbgn, bend, xbgn, xend, wName, xWave = xWave, negative = negative )
	
	return NMFWHM2( s, history = history )
	
End // NMFWHM

//****************************************************************
//****************************************************************

Function NMFWHM2( s [ history ] )
	STRUCT NMFWHMStruct &s
	Variable history
	
	Variable xflag, edge
	
	STRUCT NMWaveStatsStruct stats
	NMWaveStatsStructNull( stats )
	
	if ( NMUtilityWaveTest( s.wName ) < 0 )
		NM2Error( 1, "wName", s.wName )
		return NaN
	endif
	
	if ( numtype( s.bbgn ) > 0 )
		s.bbgn = -inf
	endif
	
	if ( numtype( s.bend ) > 0 )
		s.bend = inf
	endif
	
	if ( numtype( s.xbgn ) > 0 )
		s.xbgn = -inf
	endif
	
	if ( numtype( s.xend ) > 0 )
		s.xend = inf
	endif
	
	if ( strlen( s.xWave ) > 0 ) 
	
		if ( NMUtilityWaveTest( s.xWave ) < 0 )
			NM2Error( 1, "xWave", s.xWave )
			return NaN
		endif
		
		if ( numpnts( $s.xWave ) != numpnts( $s.wName ) )
			NM2Error( 5, "xWave", s.xWave )
			return NaN
		endif
		
		xflag = 1
		
	endif
	
	NMWaveStatsStructInit( stats, s.wName, xWave = s.xWave, xbgn = s.bbgn, xend = s.bend )
	NMWaveStatsXY2( stats )
	
	if ( numtype( stats.avg ) > 0 )
		return NaN
	endif
	
	s.baseline = stats.avg
	
	NMWaveStatsStructInit( stats, s.wName, xWave = s.xWave, xbgn = s.xbgn, xend = s.xend )
	NMWaveStatsXY2( stats )
	
	if ( s.negative )
	
		s.min = stats.min
		s.minLoc = stats.minLoc
		s.minRowLoc = stats.minRowLoc
		
		s.y = s.baseline + 0.5 * ( s.min - s.baseline ) // 50%
		
		s.x1 = NMFindLevel( s.y, s.wName, xWave = s.xWave, xbgn = s.minLoc, xend = s.xbgn, edge = edge )
		s.x2 = NMFindLevel( s.y, s.wName, xWave = s.xWave, xbgn = s.minLoc, xend = s.xend, edge = edge )
		
		if ( xflag )
			s.pnt1 = NMX2Pnt( s.xWave, s.x1 )
			s.pnt2 = NMX2Pnt( s.xWave, s.x2 )
		else
		
			s.pnt1 = x2pnt( $s.wName, s.x1 )
			s.pnt2 = x2pnt( $s.wName, s.x2 )
			
			if ( ( s.pnt1 < 0 ) || ( s.pnt1 >= numpnts( $s.wName ) ) )
				s.pnt1 = NaN
				s.x1 = NaN
			endif
			
			if ( ( s.pnt2 < 0 ) || ( s.pnt2 >= numpnts( $s.wName ) ) )
				s.pnt2 = NaN
				s.x2 = NaN
			endif
			
		endif
		
		s.fwhm = s.x2 - s.x1
		
	else
	
		s.max = stats.max
		s.maxLoc = stats.maxLoc
		s.maxRowLoc = stats.maxRowLoc
		
		s.y = s.baseline + 0.5 * ( s.max - s.baseline ) // 50%
		
		s.x1 = NMFindLevel( s.y, s.wName, xWave = s.xWave, xbgn = s.maxLoc, xend = s.xbgn, edge = edge )
		s.x2 = NMFindLevel( s.y, s.wName, xWave = s.xWave, xbgn = s.maxLoc, xend = s.xend, edge = edge )
		
		if ( xflag )
			s.pnt1 = NMX2Pnt( s.xWave, s.x1 )
			s.pnt2 = NMX2Pnt( s.xWave, s.x2 )
		else
		
			s.pnt1 = x2pnt( $s.wName, s.x1 )
			s.pnt2 = x2pnt( $s.wName, s.x2 )
			
			if ( ( s.pnt1 < 0 ) || ( s.pnt1 >= numpnts( $s.wName ) ) )
				s.pnt1 = NaN
				s.x1 = NaN
			endif
			
			if ( ( s.pnt2 < 0 ) || ( s.pnt2 >= numpnts( $s.wName ) ) )
				s.pnt2 = NaN
				s.x2 = NaN
			endif
			
		endif
		
		s.fwhm = s.x2 - s.x1
		
	endif
	
	if ( history )
		Print s
	endif
	
	return s.fwhm
	
End // NMFWHM2

//****************************************************************
//
//	NMFindOnset()
//	find onset of when signal rises above baseline noise
//
//****************************************************************

Function NMFindOnset( wName, xbgn, xend, avgN, Nstdv, negpos, direction )
	String wName // wave name
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	Variable avgN // avg points
	Variable Nstdv // number of stdv's above baseline
	Variable negpos // ( 1 ) pos onset ( -1 ) neg onset
	Variable direction // ( 1 ) forward search ( -1 ) backward search
	
	Variable icnt, ibgn, iend, level
	
	if ( NMUtilityWaveTest( wName ) < 0 )
		return NM2Error( 1, "wName", wName )
	endif
	
	if ( numtype( xbgn ) > 0 )
		xbgn = -inf
	endif
	
	if ( numtype( xend ) > 0 )
		xend = inf
	endif
	
	if ( ( numtype( avgN ) > 0 ) || ( avgN <= 0 ) )
		return NM2Error( 10, "avgN", num2istr( avgN ) )
	endif
	
	if ( ( numtype( Nstdv ) > 0 ) || ( Nstdv <= 0 ) )
		return NM2Error( 10, "Nstdv", num2istr( Nstdv ) )
	endif
	
	Wave eWave = $wName
	
	Variable dx = deltax( eWave )
	
	xbgn = max( xbgn, leftx( eWave ) )
	xend = min( xend, rightx( eWave ) )
	
	if ( direction == 1 )
	
		// search forward from xbgn until right-most data point falls above ( Avg + N*Stdv ), the baseline
		
		ibgn = x2pnt( eWave, xbgn )
		iend = x2pnt( eWave, xend ) - AvgN
		
		if ( ibgn >= iend )
			return NaN
		endif
	
		for ( icnt = ibgn; icnt < iend; icnt += 1 )
			
			WaveStats /Q/Z/R=[icnt, icnt + avgN] eWave
			
			if ( negpos > 0 )
			
				level = V_avg + Nstdv * V_sdev
				
				if ( ( numtype( level ) == 0 ) && ( eWave[icnt+AvgN] >= level ) )
					return pnt2x( eWave, ( icnt+AvgN ) )
				endif
				
			else
			
				level = V_avg - Nstdv * V_sdev
				
				if ( ( numtype( level ) == 0 ) && ( eWave[icnt+AvgN] <= level ) )
					return pnt2x( eWave, ( icnt+AvgN ) )
				endif
				
			endif
	
		endfor
	
	else
	
	// search backward from xend until right-most data point falls below ( Avg + N*Stdv ), the baseline
		
		ibgn = x2pnt( eWave, xbgn ) + AvgN
		iend = x2pnt( eWave, xend )
		
		if ( ibgn >= iend )
			return NaN
		endif
	
		for ( icnt = iend; icnt > ibgn; icnt -= 1 )
		
			WaveStats /Q/Z/R=[icnt - avgN, icnt] eWave
			
			if ( negpos > 0 )
			
				level = V_avg + Nstdv * V_sdev
				
				if ( ( numtype( level ) == 0 ) && ( eWave[icnt] <= level ) )
					return pnt2x( eWave, icnt )
				endif
				
			else
			
				level = V_avg - Nstdv * V_sdev
				
				if ( ( numtype( level ) == 0 ) && ( eWave[icnt] >= level ) )
					return pnt2x( eWave, icnt )
				endif
			
			endif
	
		endfor
	
	endif
	
	return NaN

End // NMFindOnset

//****************************************************************
//
//	NMFindPeak()
//	find time of peak y-value
//
//****************************************************************

Function NMFindPeak( wName, xbgn, xend, avgN, Nstdv, negpos )
	String wName // wave name
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	Variable avgN // avg points
	Variable Nstdv // number of stdv's above baseline
	Variable negpos // ( -1 ) neg peak ( 1 ) pos peak 

	Variable icnt, ibgn, iend, ybgn, level
	
	if ( NMUtilityWaveTest( wName ) < 0 )
		return NM2Error( 1, "wName", wName )
	endif
	
	if ( numtype( xbgn ) > 0 )
		xbgn = -inf
	endif
	
	if ( numtype( xend ) > 0 )
		xend = inf
	endif
	
	if ( ( numtype( avgN ) > 0 ) || ( avgN <= 0 ) )
		return NM2Error( 10, "avgN", num2istr( avgN ) )
	endif
	
	if ( ( numtype( Nstdv ) > 0 ) || ( Nstdv <= 0 ) )
		return NM2Error( 10, "Nstdv", num2istr( Nstdv ) )
	endif
	
	Wave eWave = $wName
	
	Variable dx = deltax( eWave )
	
	xbgn = max( xbgn, leftx( eWave ) )
	xend = min( xend, rightx( eWave ) )
	
	ibgn = x2pnt( eWave, xbgn )
	iend = x2pnt( eWave, xend ) - avgN
	
	ybgn = eWave[ibgn]
	
	if ( ibgn >= iend )
		return NaN
	endif
	
	// search forward from xbgn until left-most data point resides above ( Avg + N*Stdv )

	for ( icnt = ibgn+1; icnt < iend; icnt += 1 )
		
		WaveStats /Q/Z/R=[icnt, icnt + avgN] eWave
		
		if ( negpos > 0 )
		
			level = V_avg + Nstdv * V_sdev
			
			if ( ( numtype( level ) == 0 ) && ( V_avg > ybgn ) && ( eWave[icnt] >= level ) )
				return pnt2x( eWave, icnt )
			endif
			
		else
		
			level = V_avg - Nstdv * V_sdev
			
			if ( ( numtype( level ) == 0 ) && ( V_avg < ybgn ) && ( eWave[icnt] <= level ) )
				return pnt2x( eWave, icnt )
			endif
		
		endif
	
	endfor
	
	return NaN

End // NMFindPeak

//****************************************************************
//****************************************************************

Function WaveCountValue( wName, valueToCount )
	String wName
	Variable valueToCount // value to count, or ( inf ) all positive numbers ( -inf ) all negative numbers
	
	Variable icnt, count

	if ( NMUtilityWaveTest( wName ) < 0 )
		return 0
	endif
	
	Wave wtemp = $wName
	
	if ( numtype( valueToCount ) == 0 )
	
		MatrixOp /O U_wCount = sum( equal( wtemp, valueToCount ) )
		
	elseif ( valueToCount == inf )
	
		MatrixOp /O U_wCount = sum( equal( wtemp/abs(wtemp), 1 ) )
	
	elseif ( valueToCount == -inf )
	
		MatrixOp /O U_wCount = sum( equal( wtemp/abs(wtemp), -1 ) )
	
	else
	
		return NaN
		
	endif
	
	if ( 0 < numpnts( U_wCount ) )
		count = U_wCount[ 0 ]
	endif
	
	KillWaves /Z U_wCount
	
	return count

End // WaveCountValue

//****************************************************************
//****************************************************************

Function NMLeftXGet( select, wList [ folder ] ) // NOT USED // see GetXstats
	String select
	String wList
	String folder
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	return GetXstats( select, wList, folder = folder )
	
End // NMLeftXGet

//****************************************************************
//****************************************************************

Function NMRightXGet( select, wList [ folder ] ) // NOT USED // see GetXstats
	String select
	String wList
	String folder
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	return GetXstats( select, wList, folder = folder )
	
End // NMRightXGet

//****************************************************************
//****************************************************************

Function NMNumPntsGet( select, wList [ folder ] ) // NOT USED // see GetXstats
	String select
	String wList
	String folder
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	return GetXstats( select, wList, folder = folder )
	
End // NMNumPntsGet

//****************************************************************
//****************************************************************

Function NMDeltaXGet( select, wList [ folder ] ) // NOT USED // see GetXstats
	String select
	String wList
	String folder
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	endif
	
	return GetXstats( select, wList, folder = folder )
	
End // NMDeltaXGet

//****************************************************************
//****************************************************************

Function ComputeWaveStats( wv, xbgn, xend, fxn, level ) // NOT USED
	Wave wv // wave to measure
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	String fxn // function ( Max, Min, Avg, Avg+SDev, Avg+SEM, Median, SDev, Var, RMS, Area, Slope, Level, Level+, Level-, NumPnts )
	Variable level // level detection value
	
	Variable ipnt
	String dumstr
	String wName = GetWavesDataFolder( wv, 2 )
	
	Variable ax = NaN // x value ( e.g. time ) or SDev for Avg+SDev or b for Slope
	Variable ay = NaN // y value ( e.g. volts ) or m for Slope
	
	if ( numtype( xbgn ) > 0 )
		xbgn = leftx( wv )
	endif
	
	if ( numtype( xend ) > 0 )
		xend = rightx( wv )
	endif
	
	if ( ( xbgn < leftx( wv ) ) && ( xend < leftx( wv ) ) )
		fxn = ""
	endif
	
	if ( ( xbgn > rightx( wv ) ) && ( xend > rightx( wv ) ) )
		fxn = ""
	endif
	
	strswitch( fxn )
			
		case "Max":
		
			WaveStats /Q/Z/R=( xbgn, xend ) wv
			
			ay = V_max
			ax = V_maxloc
			
			if ( numtype( ax * ay ) > 0 )
				ax = NaN
				ay = NaN
			endif
			
			break
			
		case "Min":
		
			WaveStats /Q/Z/R=( xbgn, xend ) wv
			
			ay = V_min
			ax = V_minloc
			
			if ( numtype( ax * ay ) > 0 )
				ax = NaN
				ay = NaN
			endif
			
			break
			
		case "Avg":
		
			WaveStats /Q/Z/R=( xbgn, xend ) wv
			
			ay = V_avg
			ax = NaN
			
			break
			
		case "Avg+SDev":
		
			WaveStats /Q/Z/R=( xbgn, xend ) wv
			
			ay = V_avg
			ax = V_Sdev
			
			break
			
		case "Avg+SEM":
		
			WaveStats /Q/Z/R=( xbgn, xend ) wv
			
			ay = V_avg
			ax = V_sem
			
			break
			
		case "Sdev":
			WaveStats /Q/Z/R=( xbgn, xend ) wv
			ay = V_sdev
			ax = NaN
			break
			
		case "Var":
			WaveStats /Q/Z/R=( xbgn, xend ) wv
			ay = V_sdev * V_sdev
			ax = NaN
			break
			
		case "RMS":
			WaveStats /Q/Z/R=( xbgn, xend ) wv
			ay = V_rms
			ax = NaN
			break
			
		case "NumPnts":
			WaveStats /Q/Z/R=( xbgn, xend ) wv
			ay = V_npnts
			ax = NaN
			break
			
		case "NumNaNs":
			WaveStats /Q/Z/R=( xbgn, xend ) wv
			ay = V_numNans
			ax = NaN
			break
			
		case "NumINFs":
			WaveStats /Q/Z/R=( xbgn, xend ) wv
			ay = V_numINFs
			ax = NaN
			break
			
		case "Median": // NMMedian
		
			if ( ( xbgn > leftx( wv ) ) || ( xend < rightx( wv ) ) )
				Duplicate /O/R=( xbgn, xend ) wv U_ComputeWaveStats
				ay = StatsMedian( U_ComputeWaveStats )
				ax = NaN
				KillWaves /Z U_ComputeWaveStats
			else
				ay = StatsMedian( wv )
				ax = NaN
				KillWaves /Z wv
			endif
			
			break
			
		case "Area":
			ay = area( wv, xbgn, xend )
			ax = NaN
			break
			
		case "Sum":
			ay = sum( wv, xbgn, xend )
			ax = NaN
			break
			
		case "PathLength":
			ay = NMPathLength( wName, xbgn = xbgn, xend = xend ) // xWave
			ax = NaN
			break
			
		case "Slope":
		
			STRUCT NMLineStruct line
			NMLineStructInit( line, wName, xbgn = xbgn, xend = xend ) // xWave
			NMLinearRegression2( line )
			
			ay = line.m
			ax = line.b
			
			break
			
		case "Onset":
		
			STRUCT NMMaxCurvStruct mc
			NMMaxCurvStructInit( mc, wName, xbgn = xbgn, xend = xend ) // xWave
			NMMaxCurvatures2( mc )
			
			ax = mc.x1 // use the first time value
			
			if ( ( ax < xbgn ) || ( ax > xend ) )
				ax = NaN
			endif
			
			if ( numtype( ax ) == 0 )
			
				ipnt = x2pnt( wv, ax )
				
				if ( ( ipnt >= 0 ) && ( ipnt < numpnts( wv ) ) )
					ay = wv[ ipnt ]
				else
					ay = NaN
				endif
				
			endif
		
			break
			
		case "Level":
			FindLevel /Q/R=( xbgn, xend ) wv, level
			ax = V_LevelX
			ay = level
			break
			
		case "Level+":
			FindLevel /EDGE=1/Q/R=( xbgn, xend ) wv, level
			ax = V_LevelX
			ay = level
			break
			
		case "Level-":
			FindLevel /EDGE=2/Q/R=( xbgn, xend ) wv, level
			ax = V_LevelX
			ay = level
			break
			
	endswitch
	
	SetNMvar( "U_ax", ax )
	SetNMvar( "U_ay", ay )
	
	KillVariables /Z V_Flag
	
End // ComputeWaveStats

//****************************************************************
//****************************************************************

Function /S NMLineFit( wName [ xWave, xbgn, xend, deprecation, s ] ) // NOT USED // can use NMLinearRegression
	String wName // wave name
	String xWave // x-axis wave name
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	Variable deprecation
	STRUCT NMLineStruct &s
	
	Variable pbgn, pend, xflag
	
	STRUCT NMLineStruct line
	NMLineStructNull( line )
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( NMUtilityWaveTest( wName ) < 0 )
		return NM2ErrorStr( 1, "wName", wName )
	endif
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( ParamIsDefault( xWave ) )
	
		xWave = ""
		
	elseif ( strlen( xWave ) > 0 ) 
	
		if ( NMUtilityWaveTest( xWave ) < 0 )
			return NM2ErrorStr( 1, "xWave", xWave )
		endif
		
		if ( numpnts( $wName ) != numpnts( $xWave ) )
			return NM2ErrorStr( 5, "xWave", xWave )
		endif
		
		pbgn = NMX2Pnt( xWave, xbgn )
		pend = NMX2Pnt( xWave, xend )
		
		xflag = 1
		
	endif
	
	if ( !xflag )
		pbgn = x2pnt( $wName, xbgn )
		pend = x2pnt( $wName, xend )
		pbgn = max( pbgn, 0 )
		pend = min( pend, numpnts( $wName ) - 1 )
	endif
	
	WaveStats /Q/Z/R=[ pbgn, pend ] $wName
	
	if ( V_npnts < 2 )
		return NM2ErrorStr( 90, "not enough data points to compute line fit", "" )
	endif
	
	Variable /G V_FitQuitReason = 0
	String /G S_Info = ""
	
	if ( xflag )
		Curvefit /Q/N line $wName ( xbgn, xend ) /X=$xWave
	else
		Curvefit /Q/N line $wName ( xbgn, xend )
	endif
	
	// y = K0 + K1 * x
	
	if ( ( strlen( S_Info ) > 0 ) && ( V_FitQuitReason == 0 ) )
	
		Wave W_Coef
	
		line.b = W_Coef[ 0 ] // K0
		line.m = W_Coef[ 1 ] // K1
	
	endif
	
	KillWaves /Z W_coef, W_sigma
	KillStrings /Z S_Info
	KillVariables /Z V_FitQuitReason
	
	if ( !ParamIsDefault( s ) )
		s = line
	endif
	
	return "m=" + num2str( line.m ) + ";b=" + num2str( line.b )+";"

End // NMLineFit

//****************************************************************
//****************************************************************

Static Function NMWeightedDecay( wName, maxOrMin, bbgn, bend, xbgn, xend, fromPeak ) // NOT USED
	String wName // wave name
	Variable maxOrMin // ( -1 ) min ( 1 ) max
	Variable bbgn, bend // baseline window
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	Variable fromPeak // integrate from peak ( 0 ) no ( 1 ) yes
	
	Variable wd, peakT
	
	if ( !WaveExists( $wName ) )
		return NaN
	endif
	
	Duplicate /O $wName U_WeightedDecay
	
	WaveStats /Q/R=( bbgn, bend ) U_WeightedDecay
	
	U_WeightedDecay -= V_avg // subtract baseline
	
	WaveStats /Q U_WeightedDecay
	
	if ( maxOrMin == -1 )
		U_WeightedDecay /= V_min // normalize
		peakT = V_minloc
	else
		U_WeightedDecay /= V_max // normalize
		peakT = V_maxloc
	endif
	
	if ( fromPeak )
		xbgn = peakT
	endif
	
	wd = area( U_WeightedDecay, xbgn, xend )
	
	KillWaves /Z U_WeightedDecay
	
	return wd
	
End // NMWeightedDecay

//****************************************************************
//****************************************************************

Function /S BinAndAverage( xWave, yWave, xbgn, binSize ) // NOT USED
	String xWave // x-axis wave name, ( "" ) enter null-string to use x-scale of y-wave
	String yWave // y-wave name
	Variable xbgn // beginning x-value
	Variable binSize // bin size
	
	Variable x0 = xbgn, x1 = xbgn + binSize
	Variable sumy, count, nbins, icnt, jcnt, savex
	
	String outputWave = yWave + "_binned"
	
	if ( numtype( xbgn ) > 0 )
		return NM2ErrorStr( 10, "xbgn", num2str( xbgn ) )
	endif
	
	if ( ( numtype( binSize ) > 0 ) || ( binsize <= 0 ) )
		return NM2ErrorStr( 10, "binSize", num2str( binSize ) )
	endif
	
	If ( NMUtilityWaveTest( yWave ) < 0 )
		return NM2ErrorStr( 1, "yWave", yWave )
	endif
	
	If ( ( strlen( xWave ) > 0 ) && ( NMUtilityWaveTest( xWave ) < 0 ) )
		return NM2ErrorStr( 1, "xWave", xWave )
	endif
	
	if ( strlen( xWave ) == 0 )
		Duplicate /O $yWave U_BinAvg_x
		Wave xtemp = U_BinAvg_x
		xtemp = x
	else
		Duplicate /O $xWave U_BinAvg_x
	endif
	
	Duplicate /O $yWave U_BinAvg_y
	
	Sort U_BinAvg_x U_BinAvg_y, U_BinAvg_x
	
	nbins = ceil( ( WaveMax( U_BinAvg_x ) - xbgn ) / binSize )
	
	Make /O/N=( nbins ) $outputWave
	Wave outy = $outputWave
	
	Setscale /P x xbgn, binSize, outy
	
	for ( icnt = 0; icnt < nbins; icnt += 1 )
	
		sumy = 0
		count = 0
	
		for ( jcnt = 0; jcnt < numpnts( U_BinAvg_x ); jcnt += 1 )
			if ( ( U_BinAvg_x[jcnt] > x0 ) && ( U_BinAvg_x[jcnt] <= x1 ) )
				sumy += U_BinAvg_y[jcnt]
				count += 1
			endif
		endfor
		
		outy[icnt] = sumy / count
		
		x0 += binSize
		x1 += binSize
		
	endfor
	
	KillWaves /Z U_BinAvg_x, U_BinAvg_y
	
	return outputWave
	
End // BinAndAverage

//****************************************************************
//****************************************************************
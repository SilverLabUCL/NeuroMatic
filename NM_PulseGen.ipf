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
//	Pulse Generator Functions
//
//****************************************************************
//****************************************************************

StrConstant NMPulseList = "square;squareTTL;+ramp;-ramp;exp;synexp4;alpha;gauss;cos;sin;sinzap;other;"
StrConstant NMPulsePlasticityList = "R*P model;D*F model;Dittman model;"
StrConstant NMPulseGraphName = "NM_PulseGenGraph"

Static Constant ampDefault = 1
Static Constant onsetDefault = 0
Static Constant widthDefault = 1
Static Constant tauDefault = 1
Static Constant sinWidthDefault = 50 // sin cos sinzap
Static Constant periodDefault = 2 // sin cos
Static Constant periodBgnDefault = 100
Static Constant periodEndDefault = 10
Static StrConstant trainDefault = "fixed"
Static Constant tbgnDefault = -inf
Static Constant tendDefault = +inf
Static Constant intervalDefault = 10
Static Constant refracDefault = 0

Static StrConstant promptPrefix = "Prompt_"
Static StrConstant paramWavePrefix = "PP_"

StrConstant NMPulseDF = "root:Packages:NeuroMatic:Pulse:"

//****************************************************************
//****************************************************************
//
//	Pulse Definitions ( see NMPulse )
//
//	sqaure = 1
//	squareTTL = 1
//	+ramp = ( x - onset ) / width 
//	-ramp = = 1 - ( x - onset ) / width
//	gauss = gauss( x, center, stdv ) // see Igor gauss function
//	alpha = ( x - onset ) * exp( -( x - onset ) / abs( tau ) )
//	exp = amp1 * exp( -( x - onset ) / abs( tau1 ) ) + amp2 * exp( -( x - onset ) / abs( tau2 ) ) + amp3 * exp( -( x - onset ) / abs( tau3 ) )
//	synexp4 = [ ( 1 - exp( -( x - onset ) / tauRise ) ) ^ power ] * [ amp1 * exp( -( x - onset ) / tau1 ) + amp2 * exp( -( x - onset ) / tau2 ) + amp3 * exp( -( x - onset ) / tau3 ) ]
//	sin = sin( 2 * pi * ( x - onset ) / period )
//	cos = cos( 2 * pi * ( x - onset ) / period )
//		
//	pulse begin = onset
//	pulse end = onset + width
//	pulse peak normalized to amp
//
//****************************************************************
//****************************************************************
//
//	NMPulseAdd, add pulse to wave
//
//	examples:
//
//	paramList = "pulse=square;amp=5;onset=5;width=10;"
//	paramList = "pulse=squareTTL;amp=5;onset=5;width=10;"
//	paramList = "pulse=+ramp;amp=5;onset=5;width=10;"
//	paramList = "pulse=alpha;amp=5;onset=5;tau=3;"
//	paramList = "pulse=exp;amp=5;onset=5;width=inf;amp1=30;tau1=1;amp2=70;tau2=5;"
//	paramList = "pulse=sin;amp=5;onset=5;width=10;period=2;"
//
//****************************************************************
//****************************************************************
//
//	NMPulseTrainAdd, add train of pulses to wave
//
//	examples:
//
//	paramList = "train=fixed;interval=10;tbgn=10;tend=80;pulse=square;amp=1;width=0.2;"
//	paramList = "train=UserWaveName;interval=10;refrac=0.5;tbgn=10;tend=80;pulse=square;amp=1;width=0.2;"
//
//	see NMPulse for pulses
//
//****************************************************************
//****************************************************************
//
//	DSCG: delta or stdv or cv or gamma
//	
//	use a comma for delta format ( e.g. paramName=firstValue,delta )
//	and use DSCG to compute final value:
//
//	finalValue = firstValue + DSCG * delta
//
//	paramList = "pulse=square;amp=50,delta=10;onset=5;width=10;" ( equivalent, as delta format is default )
//
//	this produces pulse amplitudes 50, 60, 70, 80, 90 for DSCG 0, 1, 2, 3, 4
//	hence, one pulse definition for 5 different pulses. 
//
//	second value can denote STDV by including "stdv" as follows:
//
//	paramList = "pulse=square;amp=50,stdv=5;onset=5;width=10;"
//
// 	in this case final value is random number drawn from gaussian:
//
//	finalValue = firstValue + gnoise( stdv )
//
//	or second and third values can denote gamma by including "gammaA" and "gammaB" as follows:
//
//	paramList = "pulse=square;amp=50,gammaA=2,gammaB=1;onset=5;width=10;"
//
// 	in this case final value is random number drawn from gamma distribution:
//
//	finalValue = firstValue + gammaNoise( gammaA, gammaB )
//	
//****************************************************************
//****************************************************************

Function NMPulseTest()

	Variable wcnt, numWaves = 250
	Variable dx = 0.05
	String paramList, wName

	STRUCT NMParams nm
	STRUCT NMMakeStruct m

	NMParamsNull( nm )
	NMMakeStructNull( m )
	
	wName = "pAlpha"
	nm.wList = wName
	m.xpnts = 100 / dx
	m.dx = dx
	m.xLabel = NMXunits
	m.yLabel = "nS"
	m.overwrite = 1
	
	NMMake2( nm, m )
	
	if ( !WaveExists( $wName ) )
		return -1
	endif
	
	paramList = "pulse=alpha;amp=-5;onset=5;tau=3;"
	//paramList = "pulse=gauss;amp=5;center=35;stdv=3;"
	
	NMPulseAdd( nm.wList, paramList, clear = 1 )
	
	nm.wList = "pAlphaBinomial"
	paramList = "pulse=square;amp=1;width=0.2;onset=5;"
	
	NMMake2( nm, m )
	NMPulseBinomial( nm.wList, paramList, 5, 0.5 )

	nm.wList = "pTrain"
	NMMake2( nm, m )
	
	//paramList = "train=fixed;interval=10;tbgn=10;tend=inf;"
	paramList = "train=fixed;interval=10;tbgn=10;tend=150;binomialN=5;binomialP=0.5;"

	NMPulseTrainAdd( nm.wList, paramList, clear = 1 )
	
	// plasticity R and P
	
	nm.wList = "pTrainRP"
	NMMake2( nm, m )
	
	paramList = "train=fixed;interval=10;tbgn=10;tend=inf;tauR=50;Pinf=0.5;tauP=12;Pscale=0;"
	//paramList = "train=fixed;interval=10;tbgn=10;tend=inf;tauR=50;Pinf=0.5;tauP=12;Pscale=0;binomialN=5;"
	
	NMPulseTrainRPadd( nm.wList, paramList, clear = 1 )
	
	Wave pTrainRP
	
	pTrainRP *= 2
	
	// binomial
	
	Duplicate /O $wName Avg_pTrainNRP
	
	Avg_pTrainNRP = 0
	
	paramList = "train=fixed;interval=10;tbgn=10;tend=inf;tauR=50;Pinf=0.5;tauP=12;Pscale=0;binomialN=5;"
	
	nm.wList = "pTrainNRP"
	
	NMMake2( nm, m )
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
		
		NMPulseTrainRPadd( nm.wList, paramList, clear = 1 )
		
		Wave pTrainNRP
		
		Avg_pTrainNRP += pTrainNRP
	
	endfor
	
	Avg_pTrainNRP /= numWaves
	Avg_pTrainNRP /= 2.5
	
	// plasticity D and F
	
	nm.wList = "pTrainDF"
	NMMake2( nm, m )
	
	//paramList = "train=fixed;interval=10;tbgn=10;tend=inf;Dinf=1;tauD=50;Dscale=0.5;Fscale=0;"
	paramList = "train=fixed;interval=10;tbgn=10;tend=inf;Dinf=1;tauD=30;Dscale=0.5;tauF=50;Fscale=1.2;Falg=x"
	
	NMPulseTrainDFadd( nm.wList, paramList, clear = 1 )
	
End // NMPulseTest

//****************************************************************
//****************************************************************

Function /S NMPulseAdd( wName, paramList [ df, clear, DSCG, notes, s ] )
	String wName // name of input wave to add pulse
	String paramList // see above examples
	String df // data folder
	Variable clear // clear input wave before adding pulse
	Variable DSCG
	Variable notes
	STRUCT NMPulseSaveToWaves &s
	
	STRUCT NMPulseSaveToWaves ss
	
	Variable binomialN, binomialP
	String pList
	
	if ( ParamIsDefault( df ) )
		df = ""
	endif
	
	if ( ParamIsDefault( s ) )
		NMPulseSaveToWavesInit( ss )
	else
		ss = s
	endif
	
	if ( strlen( StringByKey( "binomialN", paramList, "=" ) ) > 0 )
	
		binomialN = NMPulseNumByKey( "binomialN", paramList, NaN, positive = 1 )
		binomialP = NMPulseNumByKey( "binomialP", paramList, NaN, positive = 1 )
	
		pList = NMPulseBinomial( wName, paramList, binomialN, binomialP, df = df, clear = clear, DSCG = DSCG, notes = notes, s = ss )
	
	else
	
		pList = NMPulse( wName, paramList, df = df, clear = clear, DSCG = DSCG, notes = notes, s = ss )
	
	endif
	
	return pList
	
End // NMPulseAdd

//****************************************************************
//****************************************************************

Function /S NMPulse( wName, paramList [ df, clear, DSCG, notes, s ] )
	String wName // name of input wave to add pulse
	String paramList // see above examples
	String df // data folder
	Variable clear // clear input wave before adding pulse
	Variable DSCG
	Variable notes
	STRUCT NMPulseSaveToWaves &s
	
	Variable off, width, TTL, tpeak, normFactor, normalize, infWidth, numExps, userWave
	Variable center, stdv
	Variable pslope, Lvar
	Variable pbgn, pend, ipnt
	String pulse, paramList2, wNameTemp = "PU_PulseAddTemp"
	
	STRUCT NMPulseAOW aow
	STRUCT NMPulseSaveToWaves ss
	
	if ( ParamIsDefault( df ) )
		df = ""
	endif
	
	if ( ParamIsDefault( s ) )
		NMPulseSaveToWavesInit( ss )
	else
		ss = s
	endif
	
	if ( ( strlen( wName ) == 0 ) || !WaveExists( $df + wName ) )
		return "" // nothing to do
	endif
	
	if ( ItemsInList( paramList ) == 0 )
		return "" // nothing to do
	endif
	
	off = str2num( StringByKey( "off", paramList, "=" ) )
	
	if ( off )
		return "" // nothing to do
	endif
	
	pulse = StringByKey( "pulse", paramList, "=" )
	
	if ( strlen( pulse ) == 0 )
		return "" // nothing to do
	endif
	
	paramList2 = "pulse=" + pulse + ";"
	
	NMPulseAOWinit( aow, paramList = paramList, DSCG = DSCG )
	
	width = aow.width
	
	Duplicate /O $( df + wName ) $( df + wNameTemp )
		
	Wave wtemp = $df + wNameTemp
		
	wtemp = 0
	
	if ( numtype( aow.amp ) > 0 )
		aow.amp = NaN
	endif
	
	if ( numtype( aow.onset ) > 0 )
		aow.onset = NaN
	endif
	
	if ( numtype( width ) > 0 )
		width = rightx( wtemp ) - aow.onset
		infWidth = 1
	endif
	
	paramList2 += NMPulseAOWparamList( aow )
	
	strswitch( pulse )
	
		case "square":
		
			wtemp = 1
			
			ss.wavePrefix = paramWavePrefix + "Square_"
			ss.pulseType = "Square"
			NMPulseAOWsaveToWaves( aow, ss )
			
			break
		
		case "TTL":
		case "squareTTL":
		
			wtemp = 1
			TTL = 1
			
			ss.wavePrefix = paramWavePrefix + "SquareTTL_"
			ss.pulseType = "SquareTTL"
			NMPulseAOWsaveToWaves( aow, ss )
			
			break
			
		case "+ramp": // positive ramp
		
			if ( numtype( aow.onset * width ) == 0 )
				wtemp = ( x - aow.onset ) / abs( width )
			endif
			
			ss.wavePrefix = paramWavePrefix + "Ramp_"
			ss.pulseType = "Ramp"
			NMPulseAOWsaveToWaves( aow, ss )
			
			break
			
		case "-ramp": // negative ramp
		
			if ( numtype( aow.onset * width ) == 0 )
				wtemp = 1 - ( x - aow.onset ) / abs( width )
			endif
			
			ss.wavePrefix = paramWavePrefix + "Ramp_"
			ss.pulseType = "Ramp"
			NMPulseAOWsaveToWaves( aow, ss )
			
			break
			
		case "gauss":
		
			STRUCT NMPulseGauss gs
			
			NMPulseGaussInit( gs, paramList = paramList, DSCG = DSCG )
			
			if ( numtype( gs.center * gs.stdv ) == 0 )
				wtemp = Gauss( x, gs.center, abs( gs.stdv ) ) * ( abs( gs.stdv ) * sqrt( 2 * pi ) )
			endif
			
			paramList2 += NMPulseGaussParamList( gs )
			
			NMPulseGaussSaveToWaves( aow, gs, ss )
			
			break
			
		case "alpha":
		
			STRUCT NMPulseAlpha aa
			
			NMPulseAlphaInit( aa, paramList = paramList, DSCG = DSCG )
			
			if ( numtype( aa.tau * aow.onset ) == 0 )
				
				//tpeak = aow.onset + abs( aa.tau )
				//normFactor = ( tpeak - aow.onset ) * exp( -( tpeak - aow.onset ) / abs( aa.tau ) )
				normFactor = abs( aa.tau ) * exp( -1 )
				
				wtemp = ( x - aow.onset ) * exp( -( x - aow.onset ) / abs( aa.tau ) ) / normFactor
				
			endif
			
			paramList2 += NMPulseAlphaParamList( aa )
			
			NMPulseAlphaSaveToWaves( aow, aa, ss )
			
			break
			
		case "exp": // sum of 4 exponentials
		
			STRUCT NMPulseExp ex
			
			NMPulseExpInit( ex, paramList = paramList, DSCG = DSCG )
			
			if ( ( numtype( aow.onset * ex.amp1 * ex.tau1 ) == 0 ) && ( ex.amp1 != 0 ) && ( ex.tau1 > 0 ) )
				numExps += 1
			endif
			
			if ( ( numtype( aow.onset * ex.amp2 * ex.tau2 ) == 0 ) && ( ex.amp2 != 0 ) && ( ex.tau2 > 0 ) )
				numExps += 1
			endif
			
			if ( ( numtype( aow.onset * ex.amp3 * ex.tau3 ) == 0 ) && ( ex.amp3 != 0 ) && ( ex.tau3 > 0 ) )
				numExps += 1
			endif
			
			if ( ( numtype( aow.onset * ex.amp4 * ex.tau4 ) == 0 ) && ( ex.amp4 != 0 ) && ( ex.tau4 > 0 ) )
				numExps += 1
			endif
			
			if ( ( numExps == 0 ) && ( numtype( ex.tau1 ) == 0 ) && ( ex.tau1 > 0 ) )
				ex.amp1 = 1 // single exp
			endif
			
			if ( ( numtype( aow.onset * ex.amp1 * ex.tau1 ) == 0 ) && ( ex.amp1 != 0 ) && ( ex.tau1 > 0 ) )
				wtemp += ex.amp1 * exp( -( x - aow.onset ) / ex.tau1 )
			endif
			
			if ( ( numtype( aow.onset * ex.amp2 * ex.tau2 ) == 0 ) && ( ex.amp2 != 0 ) && ( ex.tau2 > 0 ) )
				wtemp += ex.amp2 * exp( -( x - aow.onset ) / ex.tau2 )
			endif
			
			if ( ( numtype( aow.onset * ex.amp3 * ex.tau3 ) == 0 ) && ( ex.amp3 != 0 ) && ( ex.tau3 > 0 ) )
				wtemp += ex.amp3 * exp( -( x - aow.onset ) / ex.tau3 )
			endif
			
			if ( ( numtype( aow.onset * ex.amp4 * ex.tau4 ) == 0 ) && ( ex.amp4 != 0 ) && ( ex.tau4 > 0 ) )
				wtemp += ex.amp4 * exp( -( x - aow.onset ) / ex.tau4 )
			endif
			
			if ( ( ex.amp1 >= 0 ) && ( ex.amp2 >= 0 ) && ( ex.amp3 >= 0 ) && ( ex.amp4 >= 0 ) )
				wtemp /= ex.amp1 + ex.amp2 + ex.amp3 + ex.amp4
			elseif ( ( ex.amp1 <= 0 ) && ( ex.amp2 <= 0 ) && ( ex.amp3 <= 0 ) && ( ex.amp4 <= 0 ) )
				wtemp /= ex.amp1 + ex.amp2 + ex.amp3 + ex.amp4
			else
				normalize = 1
			endif
			
			paramList2 += NMPulseExpParamList( ex )
			
			NMPulseExpSaveToWaves( aow, ex, ss )
			
			break
			
		case "synexp":
		case "synexp4":
		
			STRUCT NMPulseSynExp4 sx4
			
			NMPulseSynExp4Init( sx4, paramList = paramList, DSCG = DSCG )
			
			//ponset = 0
			normalize = 1
			
			if ( numtype( aow.onset ) == 0 )
			
				if ( sx4.amp1 != 0 )
					wtemp += sx4.amp1 * exp( -( x - aow.onset ) / abs( sx4.tau1 ) ) // decay #1
				endif
				
				if ( sx4.amp2 != 0 )
					wtemp += sx4.amp2 * exp( -( x - aow.onset ) / abs( sx4.tau2 ) ) // decay #2
				endif
				
				if ( sx4.amp3 != 0 )
					wtemp += sx4.amp3 * exp( -( x - aow.onset ) / abs( sx4.tau3 ) ) // decay #3
				endif
			
				if ( numtype( sx4.tauRise * sx4.power ) == 0 )
					wtemp *= ( ( 1 - exp( -( x - aow.onset ) / abs( sx4.tauRise ) ) ) ^ abs( sx4.power ) ) // sigmoidal rise time
				endif
				
			endif
		
			paramList2 += NMPulseSynExp4ParamList( sx4 )
			
			NMPulseSynExp4SaveToWaves( aow, sx4, ss )
			
			break
			
		case "sin":
		case "sine":
		
			STRUCT NMPulseSin sn
			
			NMPulseSinInit( sn, paramList = paramList, DSCG = DSCG )
			
			if ( numtype( aow.onset * sn.period ) == 0 )
				wtemp = sin( 2 * pi * ( x - aow.onset ) / abs( sn.period ) )
			endif
			
			paramList2 += NMPulseSinParamList( sn )
			
			NMPulseSinSaveToWaves( aow, sn, ss )
			
			break
			
		case "cos":
		case "cosine":
		
			STRUCT NMPulseSin cn
			
			NMPulseSinInit( cn, paramList = paramList, DSCG = DSCG, cosine = 1 )
			
			if ( numtype( aow.onset * cn.period ) == 0 )
				wtemp = cos( 2 * pi * ( x - aow.onset ) / abs( cn.period ) )
			endif
			
			paramList2 += NMPulseSinParamList( cn )
			
			NMPulseSinSaveToWaves( aow, cn, ss )
			
			break
			
		case "sinzap":
		
			STRUCT NMPulseSinZap sz
			
			NMPulseSinZapInit( sz, paramList = paramList, DSCG = DSCG )
		
			sz.periodBgn = NMPulseNumByKey( "periodBgn", paramList, 0, DSCG = DSCG, positive = 1 )
			sz.periodEnd = NMPulseNumByKey( "periodEnd", paramList, 0, DSCG = DSCG, positive = 1 )
			
			//Lvar = log( fmax / fmin )
			//wtemp = sin( 2 * pi * ( x - onset ) * ( fmin / Lvar ) * ( exp( Lvar * ( x - onset ) / 1000 ) - 1 ) ) // Tohidi and Nadim 2009
			
			if ( numtype( aow.onset * sz.periodBgn * sz.periodEnd ) == 0 )
			
				pslope = ( abs( sz.periodEnd ) - abs( sz.periodBgn ) ) / ( rightx( wtemp ) - aow.onset ) // linear
				
				//Duplicate /O wtemp SinZapPeriod
				//SinZapPeriod = pslope * ( x - onset ) + periodBgn
				
				wtemp = sin( 2 * pi * ( x - aow.onset ) / ( pslope * ( x - aow.onset ) + abs( sz.periodBgn ) ) ) // linear
				//wtemp = sin( 2 * pi * ( x - onset ) / periodBgn )
				//wtemp = sin( 2 * pi * ( x - onset ) / periodEnd )
			
			endif
			
			paramList2 += NMPulseSinZapParamList( sz )
			
			NMPulseSinZapSaveToWaves( aow, sz, ss )
		
			break
			
		default: // user-defined pulse wave
		
			if ( WaveExists( $df+pulse ) )
			
				Wave yourpulse = $df+pulse
				
				ipnt = numpnts( yourpulse )
				
				ipnt = min( ipnt, numpnts( wtemp ) )
				
				if ( ipnt - 1 > 0 )
					wtemp[ 0, ipnt-1] = yourpulse
				endif
				
				ipnt += 1
				
				if ( ipnt < numpnts( wtemp ) )
					wtemp[ ipnt, numpnts( wtemp ) - 1 ] = 0
				endif
				
				ipnt = aow.onset / deltax( wtemp )
				
				if ( ipnt > 0 )
					MatrixOp /O wtemp = shiftVector( wtemp, ipnt, 0 )
				endif
				
				normalize = 1
				userWave = 1
				
			else
			
				return ""
				
			endif
			
	endswitch
	
	if ( aow.onset > 0 )
	
		pbgn = 0
		pend = round( aow.onset / deltax( wtemp ) )
		
		if ( ( pend > pbgn ) && ( pend < numpnts( wtemp ) ) )
			wtemp[ pbgn, pend ] = 0 // zero before onset
		endif
		
	else
	
		pbgn = 0
		pend = 0
	
	endif
	
	if ( !infWidth )
	
		pbgn = pend + round( width / deltax( wtemp ) ) + 1
		pend = numpnts( wtemp ) - 1
			
		if ( pend > pbgn )
			wtemp[ pbgn, pend ] = 0 // zero after tend
		endif
	
	endif
	
	if ( numtype( aow.amp ) == 0 )
	
		if ( normalize )
		
			Wavestats /Q/Z wtemp
			
			if ( abs( V_max ) > abs( V_min ) )
				wtemp *= aow.amp / V_max
			elseif ( abs( V_min ) > abs( V_max ) )
				wtemp *= aow.amp / V_min
			endif
		
		else
		
			wtemp *= aow.amp
		
		endif
		
	elseif ( !userWave )
	
		wtemp = 0
	
	endif
		
	Wave wtemp2 = $df + wName
	
	if ( clear )
		wtemp2 = wtemp
	elseif ( TTL )
		wtemp2 = zPulseTTL( wtemp, wtemp2, aow.amp )
	else
		wtemp2 += wtemp
	endif
	
	if ( notes )
		Note wtemp2, paramList2 + "|"
	endif
	
	KillWaves /Z $df + wNameTemp
	
	return paramList2
	
End // NMPulse

//****************************************************************
//****************************************************************

Function /S NMPulseBinomial( wName, paramList, binomialN, binomialP [ df, clear, DSCG, notes, s ] )
	String wName // name of input wave to add pulse
	String paramList // see above examples
	Variable binomialN // number of trials (N)
	Variable binomialP // probability of success (P)
	String df // data folder
	Variable clear // clear input wave before adding pulse
	Variable DSCG // compute with delta or stdv or cv or gamma
	Variable notes
	STRUCT NMPulseSaveToWaves &s
	
	STRUCT NMPulseSaveToWaves ss
	
	Variable trial, off, onset
	String pulse, paramList2, outList = ""
	
	if ( ParamIsDefault( df ) )
		df = ""
	endif
	
	if ( ParamIsDefault( s ) )
		NMPulseSaveToWavesInit( ss )
	else
		ss = s
	endif
	
	if ( ( strlen( wName ) == 0 ) || !WaveExists( $df + wName ) )
		return "" // nothing to do
	endif
	
	if ( ItemsInList( paramList ) == 0 )
		return "" // nothing to do
	endif
	
	off = str2num( StringByKey( "off", paramList, "=" ) )
	
	if ( off )
		return "" // nothing to do
	endif
	
	pulse = StringByKey( "pulse", paramList, "=" )
	
	if ( strlen( pulse ) == 0 )
		return "" // nothing to do
	endif
	
	if ( clear )
		Wave wtemp = $wName
		wtemp = 0
	endif
	
	ss.binomialN = binomialN
	
	for ( trial = 0 ; trial < binomialN ; trial += 1 )
		
		if ( abs( enoise( 1.0 ) ) < binomialP )
			ss.failure = 0
			paramList2 = paramList
		else
			ss.failure = 1
			paramList2 = NMPulseNumReplace( "amp", paramList, NaN )
		endif
		
		ss.trial = trial
		
		outList += NMPulse( wName, paramList2, df = df, DSCG = DSCG, notes = notes, s = ss )
		
	endfor
	
	return outList
		
End // NMPulseBinomial

//****************************************************************
//****************************************************************

Structure NMPulseTrain

	String type
	Variable tbgn, tend, interval, refrac

EndStructure

//****************************************************************
//****************************************************************

Function NMPulseTrainInit( t [ pdf, paramList ] ) 
	STRUCT NMPulseTrain &t
	String pdf, paramList
	
	String vp = promptPrefix + "Train"
	Variable freq, freqD
	
	if ( ParamIsDefault( pdf ) || ( strlen( pdf ) == 0 ) )
		t.type = trainDefault
		t.tbgn = tbgnDefault
		t.tend = tendDefault
		t.interval = intervalDefault
		t.refrac = refracDefault
	else
		t.type = StrVarOrDefault( pdf + vp + "Type", trainDefault )
		t.tbgn = NumVarOrDefault( pdf + vp + "Tbgn", tbgnDefault )
		t.tend = NumVarOrDefault( pdf + vp + "Tend", tendDefault )
		t.interval = NumVarOrDefault( pdf + vp + "Interval", intervalDefault )
		t.refrac = NumVarOrDefault( pdf + vp + "Refrac", refracDefault )
	endif
	
	if ( ParamIsDefault( paramList ) || ( strlen( paramList ) == 0 ) )
		return 0
	endif
	
	t.type = StringByKey( "train", paramList, "=" )
	t.tbgn = NMPulseNumByKey( "tbgn", paramList, t.tbgn )
	t.tend = NMPulseNumByKey( "tend", paramList, t.tend )
	t.interval = NMPulseNumByKey( "interval", paramList, t.interval, positive = 1 )
	freq = NMPulseNumByKey( "freq", paramList, NaN, positive = 1 )
	t.refrac = NMPulseNumByKey( "refrac", paramList, t.refrac, positive = 1 )
	
	if ( ( numtype( freq ) == 0 ) && ( freq >= 0 ) )
		t.interval = 1 / freq
	endif
	
	if ( StringMatch( t.type, "random" ) && ( numtype( t.refrac ) > 0 ) )
		t.refrac = 0
	endif
	
End // NMPulseTrainInit

//****************************************************************
//****************************************************************

Function NMPulseTrainSave( t, pdf )
	STRUCT NMPulseTrain &t
	String pdf
	
	String vp = promptPrefix + "Train"
	
	if ( strlen( pdf ) == 0 )
		return 0
	endif
	
	SetNMstr( pdf + vp + "Type", t.type )
	zSetVarD( pdf, vp, "Tbgn", t.tbgn, 0, 1 )
	zSetVarD( pdf, vp, "Tend", t.tend, 0, 1 )
	zSetVarD( pdf, vp, "Interval", t.interval, 0, 1 )
	zSetVarD( pdf, vp, "Refrac", t.refrac, 0, 1 )
	
End // NMPulseTrainSave

//****************************************************************
//****************************************************************

Function /S NMPulseTrainParamList( t [ skipRefrac ] )
	STRUCT NMPulseTrain &t
	Variable skipRefrac
	
	String pstr = "train=" + t.type + ";"
	
	pstr += NMPulseParamList( "tbgn", t.tbgn )
	pstr += NMPulseParamList( "tend", t.tend )
	pstr += NMPulseParamList( "interval", t.interval )
	
	if ( !skipRefrac )
		pstr += NMPulseParamList( "refrac", t.refrac )
	endif
	
	return pstr 
	
End // NMPulseTrainParamList

//****************************************************************
//****************************************************************

Function /S NMPulseTrainAdd( wName, paramList [ df, clear, DSCG, notes, s ] )
	String wName // name of input wave to add pulse train
	String paramList // train parameter list
	String df // data folder
	Variable clear // clear wave before adding pulses
	Variable DSCG // compute with delta or stdv or cv or gamma
	Variable notes
	STRUCT NMPulseSaveToWaves &s
	
	Variable icnt, ipnt, trial, foundPulse, off, numPulses, fixed, stochastic, TTL
	Variable amp, onset, interval
	Variable binomialN, binomialP
	String pulse, paramList2
	
	String pName = "PU_PulseAddTemp2"
	String wNameTemp = "PU_PulseTrainAddTemp"
	
	STRUCT NMPulseTrain t
	STRUCT NMPulseSaveToWaves ss
	
	if ( ParamIsDefault( df ) )
		df = ""
	endif
	
	if ( ParamIsDefault( s ) )
		NMPulseSaveToWavesInit( ss )
	else
		ss = s
	endif
	
	if ( ( strlen( wName ) == 0 ) || !WaveExists( $df + wName ) )
		return "" // nothing to do
	endif
	
	if ( ItemsInList( paramList ) == 0 )
		return "" // nothing to do
	endif
	
	off = str2num( StringByKey( "off", paramList, "=" ) )
	
	if ( off )
		return "" // nothing to do
	endif
	
	NMPulseTrainInit( t, paramList = paramList )
	
	if ( strlen( t.type ) == 0 )
		return "" // nothing to do
	endif
	
	pulse = StringByKey( "pulse", paramList, "=" )
	
	if ( strlen( pulse ) > 0 )
	
		foundPulse = 1
		
		if ( StringMatch( pulse, "squareTTL" ) )
			TTL = 1
		endif
		
	endif
	
	binomialN = NMPulseNumByKey( "binomialN", paramList, NaN, positive = 1 )
	binomialP = NMPulseNumByKey( "binomialP", paramList, NaN, positive = 1 )
	
	if ( ( numtype( binomialN ) == 0 ) && ( binomialN > 0 ) )
		if ( ( numtype( binomialP ) == 0 ) && ( binomialP > 0 ) && ( binomialP <= 1 ) )
			binomialN = round( binomialN )
			stochastic = 1
		else
			binomialN = 0
			binomialP = 0
		endif
	else
		binomialN = 0
		binomialP = 0
	endif
	
	if ( ( strsearch( paramList, ",stdv,", 0 ) > 0 ) || ( strsearch( paramList, ",cv,", 0 ) > 0 ) || ( strsearch( paramList, ",gammaA,", 0 ) > 0 ) )
		stochastic = 1
	endif
	
	Duplicate /O $( df + wName ) $( df + wNameTemp )
		
	Wave wtemp = $df + wNameTemp
		
	wtemp = 0
	
	if ( numtype( t.tbgn ) > 0 )
		t.tbgn = leftx( wtemp )
	endif
	
	if ( numtype( t.tend ) > 0 )
		t.tend = rightx( wtemp )
	endif
	
	if ( foundPulse && !stochastic )
		Duplicate /O $( df + wName ) $( df + pName )
		paramList2 = NMPulse( pName, paramList, df = df, clear = 1, DSCG = DSCG )
	endif
	
	if ( StringMatch( t.type, "fixed" ) )
	
		fixed = 1
		
		numPulses = 1 + floor( ( t.tend - t.tbgn ) / t.interval )
		
		if ( ( numtype( numPulses ) > 0 ) || ( numPulses < 0 ) )
			numPulses = 0
		endif
		
	else
	
		if ( WaveExists( $df + t.type ) )
			Wave pTimes = $df + t.type // user wave should have pulse times
			numPulses = numpnts( pTimes )
		else
			KillWaves /Z $df + pName
			KillWaves /Z $df + wNameTemp
			return ""
		endif
	
	endif
	
	ss.pulsesPerConfig = numPulses
	
	if ( notes )
		Note $( df + wName ), paramList + "|"
	endif
	
	if ( binomialN == 0 )
	
		for ( icnt = 0 ; icnt < numPulses ; icnt += 1 )
		
			ss.pulseNum = icnt
				
			if ( fixed )
				onset = t.tbgn + icnt * t.interval
			elseif ( icnt < numpnts( pTimes ) )
				onset = pTimes[ icnt ]
			else
				break
			endif
			
			if ( ( onset < leftx( wtemp ) ) || ( onset > rightx( wtemp ) ) )
				continue
			endif
			
			if ( ( onset < t.tbgn ) || ( onset > t.tend ) )
				continue
			endif
			
			if ( stochastic )
				paramList2 = NMPulseNumReplace( "onset", paramList, onset )
				paramList2 = NMPulse( wNameTemp, paramList2, df = df, DSCG = DSCG, s = ss )
			else
			
				ipnt = x2pnt( wtemp, onset )
				
				if ( ( ipnt >= 0 ) && ( ipnt < numpnts( wtemp ) ) )
					wtemp[ ipnt, ipnt ] += 1 // convolve method
				endif
				
			endif
			
		endfor

	else
	
		ss.binomialN = binomialN
	
		for ( icnt = 0 ; icnt < numPulses ; icnt += 1 )
		
			ss.pulseNum = icnt
	
			for ( trial = 0 ; trial < binomialN ; trial += 1 )
		
				if ( abs( enoise( 1.0 ) ) < binomialP )
					ss.failure = 0
				else
					ss.failure = 1
				endif
				
				ss.trial = trial
				
				if ( fixed )
					onset = t.tbgn + icnt * t.interval
				elseif ( icnt < numpnts( pTimes ) )
					onset = pTimes[ icnt ]
				else
					break
				endif
				
				if ( ( onset < leftx( wtemp ) ) || ( onset > rightx( wtemp ) ) )
					continue
				endif
				
				if ( ( onset < t.tbgn ) || ( onset > t.tend ) )
					continue
				endif
				
				paramList2 = NMPulseNumReplace( "onset", paramList, onset )
				
				if ( ss.failure )
					paramList2 = NMPulseNumReplace( "amp", paramList2, NaN )
				endif
				
				paramList2 = NMPulse( wNameTemp, paramList2, df = df, DSCG = DSCG, s = ss )
				
			endfor
			
		endfor
	
	endif
	
	if ( foundPulse && !stochastic )
		Convolve $( df + pName ) wtemp
		Redimension /N=( numpnts( $df + wName ) ) wtemp
	endif
	
	Wave wtemp2 = $df + wName
	
	if ( clear )
		wtemp2 = wtemp
	elseif ( TTL )
		amp = NMPulseNumByKey( "amp", paramList, NaN, DSCG = DSCG )
		wtemp2 = zPulseTTL( wtemp, wtemp2, amp )
	else
		wtemp2 += wtemp
	endif
	
	KillWaves /Z $df + pName
	KillWaves /Z $df + wNameTemp
	
	return df + wName
	
End // NMPulseTrainAdd

//****************************************************************
//****************************************************************

Structure NMPulseTrainRP

	Variable Rinf, Rmin, tauR, Pinf, Pmax, tauP, Pscale

EndStructure

//****************************************************************
//****************************************************************

Function NMPulseTrainRPinit( p [ pdf, paramList ] ) 
	STRUCT NMPulseTrainRP &p
	String pdf, paramList
	
	String vp = promptPrefix + "TrainRP"
	
	if ( ParamIsDefault( pdf ) || ( strlen( pdf ) == 0 ) )
		p.Rinf = 1
		p.Rmin = 0
		p.tauR = 1
		p.Pinf = 0.5
		p.Pmax = inf
		p.tauP = -1
		p.Pscale = 0
	else
		p.Rinf = NumVarOrDefault( pdf + vp + "Rinf", 1 )
		p.Rmin = NumVarOrDefault( pdf + vp + "Rmin", 0 )
		p.tauR = NumVarOrDefault( pdf + vp + "tauR", 1 )
		p.Pinf = NumVarOrDefault( pdf + vp + "Pinf", 0.5 )
		p.Pmax = NumVarOrDefault( pdf + vp + "Pmax", inf )
		p.tauP = NumVarOrDefault( pdf + vp + "tauP", -1 )
		p.Pscale = NumVarOrDefault( pdf + vp + "Pscale", 0)
	endif
	
	if ( ParamIsDefault( paramList ) || ( strlen( paramList ) == 0 ) )
		return 0
	endif
	
	p.Rinf = NMPulseNumByKey( "Rinf", paramList, p.Rinf, positive = 1 )
	p.Rmin = NMPulseNumByKey( "Rmin", paramList, p.Rmin, positive = 1 )
	p.tauR = NMPulseNumByKey( "tauR", paramList, p.tauR )
	p.Pinf = NMPulseNumByKey( "Pinf", paramList, p.Pinf, positive = 1 )
	p.Pmax = NMPulseNumByKey( "Pmax", paramList, p.Pmax, positive = 1 )
	p.tauP = NMPulseNumByKey( "tauP", paramList, p.tauP )
	p.Pscale = NMPulseNumByKey( "Pscale", paramList, p.Pscale, positive = 1 )
	
End // NMPulseTrainRPinit

//****************************************************************
//****************************************************************

Function NMPulseTrainRPsave( p, pdf )
	STRUCT NMPulseTrainRP &p
	String pdf
	
	String vp = promptPrefix + "TrainRP"
	
	if ( strlen( pdf ) == 0 )
		return 0
	endif
	
	SetNMvar( pdf + vp + "Rinf", p.Rinf )
	SetNMvar( pdf + vp + "Rmin", p.Rmin )
	SetNMvar( pdf + vp + "tauR", p.tauR )
	SetNMvar( pdf + vp + "Pinf", p.Pinf )
	SetNMvar( pdf + vp + "Pmax", p.Pmax )
	SetNMvar( pdf + vp + "tauP", p.tauP )
	SetNMvar( pdf + vp + "Pscale", p.Pscale )
	
End // NMPulseTrainRPsave

//****************************************************************
//****************************************************************

Function /S NMPulseTrainRPparamList( p )
	STRUCT NMPulseTrainRP &p
	
	String pstr =  NMPulseParamList( "Rinf", p.Rinf )
	
	pstr += NMPulseParamList( "Rmin", p.Rmin )
	pstr += NMPulseParamList( "tauR", p.tauR )
	pstr += NMPulseParamList( "Pinf", p.Pinf )
	pstr += NMPulseParamList( "Pmax", p.Pmax )
	pstr += NMPulseParamList( "tauP", p.tauP )
	pstr += NMPulseParamList( "Pscale", p.Pscale )
	
	return pstr 
	
End // NMPulseTrainRPparamList

//****************************************************************
//****************************************************************

Function NMPulseTrainRPexists( paramList )
	String paramList
	
	if ( strlen( StringByKey( "Rinf", paramList, "=" ) ) == 0 )
		return 0
	endif
	
	if ( strlen( StringByKey( "Pinf", paramList, "=" ) ) == 0 )
		return 0
	endif
	
	return 1
	
End // NMPulseTrainRPexists

//****************************************************************
//****************************************************************

Function /S NMPulseTrainRPadd( wName, paramList [ df, clear, DSCG, notes, wNameR, wNameP, s ] )
	String wName // name of input wave to add pulse train
	String paramList // train parameter list
	String df // data folder
	Variable clear // clear wave before adding pulses
	Variable DSCG // compute with delta or stdv or cv or gamma
	Variable notes
	String wNameR, wNameP
	STRUCT NMPulseSaveToWaves &s
	
	Variable icnt, xpnt1, xpnt2, xlast, trial, foundPulse, off, numPulses
	Variable fixed, stochastic, successN, doConvolution
	Variable amp, onset, interval, binomialN
	Variable R, P, foundP, saveR, saveP
	String pulse, paramList2
	
	String pName = "PU_PulseAddTemp2"
	String wNameTemp = "PU_PulseTrainAddTemp"
	
	STRUCT NMPulseTrain t
	STRUCT NMPulseTrainRP rp
	STRUCT NMPulseSaveToWaves ss
	
	if ( ParamIsDefault( df ) )
		df = ""
	endif
	
	if ( ParamIsDefault( wNameR ) )
		wNameR = ""
	endif
	
	if ( ParamIsDefault( wNameP ) )
		wNameP = ""
	endif
	
	if ( ParamIsDefault( s ) )
		NMPulseSaveToWavesInit( ss )
	else
		ss = s
		//stochastic = 1
	endif
	
	if ( ( strlen( wName ) == 0 ) || !WaveExists( $df + wName ) )
		return "" // nothing to do
	endif
	
	if ( ItemsInList( paramList ) == 0 )
		return "" // nothing to do
	endif
	
	off = str2num( StringByKey( "off", paramList, "=" ) )
	
	if ( off )
		return "" // nothing to do
	endif
	
	NMPulseTrainInit( t, paramList = paramList )
	
	if ( strlen( t.type ) == 0 )
		return "" // nothing to do
	endif
	
	pulse = StringByKey( "pulse", paramList, "=" )
	
	if ( strlen( pulse ) > 0 )
		foundPulse = 1
	endif
	
	NMPulseTrainRPinit( rp, paramList = paramList )
	
	if ( ( numtype( rp.tauR ) > 0 ) || ( rp.tauR <= 0 ) )
		return "" // nothing to do
	endif
	
	if ( ( numtype( rp.tauP ) == 0 ) && ( rp.tauP > 0 ) && ( numtype( rp.Pscale ) == 0 ) && ( rp.Pscale > 0 ) )
		foundP = 1
	endif
	
	binomialN = NMPulseNumByKey( "binomialN", paramList, NaN, positive = 1 )
	
	if ( ( numtype( binomialN ) == 0 ) && ( binomialN > 0 ) )
		binomialN = round( binomialN )
		stochastic = 1
	else
		binomialN = 0
		stochastic = 0
	endif
	
	if ( ( strsearch( paramList, ",stdv,", 0 ) > 0 ) || ( strsearch( paramList, ",cv,", 0 ) > 0 ) || ( strsearch( paramList, ",gammaA,", 0 ) > 0 ) )
		stochastic = 1
	endif
	
	Duplicate /O $( df + wName ) $( df + wNameTemp )
		
	Wave wtemp = $df + wNameTemp
		
	wtemp = 0
	
	if ( numtype( t.tbgn ) > 0 )
		t.tbgn = leftx( wtemp )
	endif
	
	if ( numtype( t.tend ) > 0 )
		t.tend = rightx( wtemp )
	endif
	
	xlast = numpnts( wtemp ) - 1
	
	if ( foundPulse && !stochastic )
		Duplicate /O $( df + wName ) $( df + pName )
		paramList2 = NMPulse( pName, paramList, df = df, clear = 1, DSCG = DSCG )
	endif
	
	if ( StringMatch( t.type, "fixed" ) )
	
		fixed = 1
		
		numPulses = 1 + floor( ( t.tend - t.tbgn ) / t.interval )
		
		if ( ( numtype( numPulses ) > 0 ) || ( numPulses < 0 ) )
			numPulses = 0
		endif
		
	else
	
		if ( WaveExists( $df + t.type ) )
			Wave pTimes = $df + t.type // user wave should have pulse times
			numPulses = numpnts( pTimes )
		else
			KillWaves /Z $df + pName
			KillWaves /Z $df + wNameTemp
			return ""
		endif
	
	endif
	
	amp = NMPulseNumByKey( "amp", paramList, NaN )
	
	ss.pulsesPerConfig = numPulses
	
	if ( strlen( wNameR ) > 0 )
	
		Duplicate /O $( df + wName ) $( df + wNameR )
		
		Wave wtempR = $df + wNameR
		
		saveR = 1
		wtempR = rp.Rinf
		
	endif
	
	if ( ( strlen( wNameP ) > 0 ) && foundP )
	
		Duplicate /O $( df + wName ) $( df + wNameP )
		
		Wave wtempP = $df + wNameP
		
		saveP = 1
		wtempP = rp.Pinf
		
	endif
	
	if ( notes )
		Note $( df + wName ), paramList + "|"
	endif

	if ( binomialN == 0 )
	
		interval = t.interval
		R = rp.Rinf
		P = rp.Pinf
		
		for ( icnt = 0 ; icnt < numPulses ; icnt += 1 )
		
			ss.pulseNum = icnt
		
			if ( fixed )
			
				onset = t.tbgn + icnt * interval
				
			elseif ( icnt < numpnts( pTimes ) )
			
				onset = pTimes[ icnt ]
				
				if ( icnt > 0 )
					interval = onset - pTimes[ icnt - 1 ]
				endif
				
			else
			
				break
				
			endif
			
			xpnt2 = x2pnt( wtemp, onset )
		
			R = rp.Rinf + ( R - rp.Rinf ) * exp( -interval / rp.tauR ) // recovery
			
			if ( foundP )
				P = rp.Pinf + ( P - rp.Pinf ) * exp( -interval / rp.tauP ) // recovery
			endif
			
			if ( ( onset >= leftx( wtemp ) ) && ( onset <= rightx( wtemp ) ) )
				if ( ( onset >= t.tbgn ) && ( onset <= t.tend ) )
			
					if ( stochastic )
						paramList2 = NMPulseNumReplace( "onset", paramList, onset )
						paramList2 = NMPulseNumReplace( "amp", paramList2, amp * R * P )
						paramList2 = NMPulse( wNameTemp, paramList2, df = df, DSCG = DSCG, s = ss )
					else
						if ( ( xpnt2 >= 0 ) && ( xpnt2 < numpnts( wtemp ) ) )
							wtemp[ xpnt2 ] += R * P
						endif
						doConvolution = 1
					endif

				endif
			endif
			
			R = R * ( 1 - P )
			R = max( rp.Rmin, R )
			
			if ( foundP )
				P = P + rp.Pscale * ( 1 - P )
				P = min( rp.Pmax, P )
			endif
			
			xpnt1 = xpnt2 + 1
			
			if ( saveR && ( xpnt1 < xlast ) )
				wtempR[ xpnt1, xlast ] = rp.Rinf + ( R - rp.Rinf ) * exp( -( x - onset ) / rp.tauR )
			endif
			
			if ( saveP && ( xpnt1 < xlast ) )
				wtempP[ xpnt1, xlast ] = rp.Pinf + ( P - rp.Pinf ) * exp( -( x - onset ) / rp.tauP )
			endif
		
		endfor
	
	else
	
		interval = t.interval
		
		ss.binomialN = binomialN
	
		for ( trial = 0 ; trial < binomialN ; trial += 1 )
		
			R = rp.Rinf
			P = rp.Pinf
			
			if ( saveR )
				wtempR = rp.Rinf
			endif
			
			if ( saveP )
				wtempP = rp.Pinf
			endif
			
			ss.trial = trial
			
			for ( icnt = 0 ; icnt < numPulses ; icnt += 1 )
			
				ss.pulseNum = icnt
	
				if ( abs( enoise( 1.0 ) ) < R * P )
					successN = 1
				else
					successN = 0
				endif
				
				if ( fixed )
				
					onset = t.tbgn + icnt * interval
					
				elseif ( icnt < numpnts( pTimes ) )
				
					onset = pTimes[ icnt ]
					
					if ( icnt > 0 )
						interval = onset - pTimes[ icnt - 1 ]
					endif
					
				else
				
					break
				
				endif
				
				xpnt2 = x2pnt( wtemp, onset )
				
				R = rp.Rinf + ( R - rp.Rinf ) * exp( -interval / rp.tauR ) // recovery
				
				if ( foundP )
					P = rp.Pinf + ( P - rp.Pinf ) * exp( -interval / rp.tauP ) // recovery
				endif
				
				if ( successN && ( onset >= leftx( wtemp ) ) && ( onset <= rightx( wtemp ) ) )
					if ( ( onset >= t.tbgn ) && ( onset <= t.tend ) )
					
						if ( stochastic )
							paramList2 = NMPulseNumReplace( "onset", paramList, onset )
							paramList2 = NMPulse( wNameTemp, paramList2, df = df, DSCG = DSCG, s = ss )
						else
							if ( ( xpnt2 >= 0 ) && ( xpnt2 < numpnts( wtemp ) ) )
								wtemp[ xpnt2 ] += 1
							endif
							doConvolution = 1
						endif
						
					endif
				endif
				
				if ( successN )
					R = 0
				endif
				
				if ( foundP )
					P = P + rp.Pscale * ( 1 - P )
					P = min( rp.Pmax, P )
				endif
				
				xpnt1 = xpnt2 + 1
			
				if ( successN && saveR && ( xpnt1 < xlast ) )
					wtempR[ xpnt1, xlast ] = rp.Rinf + ( R - rp.Rinf ) * exp( -( x - onset ) / rp.tauR )
				endif
				
				if ( saveP && ( xpnt1 < xlast ) )
					wtempP[ xpnt1, xlast ] = rp.Pinf + ( P - rp.Pinf ) * exp( -( x - onset ) / rp.tauP )
				endif
			
			endfor
			
		endfor

	endif
	
	if ( foundPulse && doConvolution )
		Convolve $( df + pName ) wtemp
		Redimension /N=( numpnts( $df + wName ) ) wtemp
	endif
	
	Wave wtemp2 = $df + wName
	
	if ( clear )
		wtemp2 = wtemp
	else
		wtemp2 += wtemp
	endif
	
	KillWaves /Z $df + pName
	KillWaves /Z $df + wNameTemp
	
	return df + wName
	
End // NMPulseTrainRPadd

//****************************************************************
//****************************************************************

Structure NMPulseTrainDF

	Variable Dinf, Dmin, tauD, Dscale, Finf, Fmax, tauF, Fscale

EndStructure

//****************************************************************
//****************************************************************

Function NMPulseTrainDFinit( p [ pdf, paramList ] ) 
	STRUCT NMPulseTrainDF &p
	String pdf, paramList
	
	String vp = promptPrefix + "TrainDF"
	
	if ( ParamIsDefault( pdf ) || ( strlen( pdf ) == 0 ) )
		p.Dinf = 1
		p.Dmin = 0
		p.tauD = 20
		p.Dscale = 0.5
		p.Finf = 1
		p.Fmax = inf
		p.tauF = -1
		p.Fscale = 1
	else
		p.Dinf = NumVarOrDefault( pdf + vp + "Dinf", 1 )
		p.Dmin = NumVarOrDefault( pdf + vp + "Dmin", 0 )
		p.tauD = NumVarOrDefault( pdf + vp + "tauD", 20 )
		p.Dscale = NumVarOrDefault( pdf + vp + "Dscale", 0.5)
		p.Finf = NumVarOrDefault( pdf + vp + "Finf", 1 )
		p.Fmax = NumVarOrDefault( pdf + vp + "Fmax", inf )
		p.tauF = NumVarOrDefault( pdf + vp + "tauF", NaN )
		p.Fscale = NumVarOrDefault( pdf + vp + "Fscale", 1 )
	endif
	
	if ( ParamIsDefault( paramList ) || ( strlen( paramList ) == 0 ) )
		return 0
	endif
	
	p.Dinf = NMPulseNumByKey( "Dinf", paramList, p.Dinf, positive = 1 )
	p.Dmin = NMPulseNumByKey( "Dmin", paramList, p.Dmin, positive = 1 )
	p.tauD = NMPulseNumByKey( "tauD", paramList, p.tauD, positive = 1 )
	p.Dscale = NMPulseNumByKey( "Dscale", paramList, p.Dscale, positive = 1 )
	p.Finf = NMPulseNumByKey( "Finf", paramList, p.Finf, positive = 1 )
	p.Fmax = NMPulseNumByKey( "Fmax", paramList, p.Fmax, positive = 1 )
	p.tauF = NMPulseNumByKey( "tauF", paramList, p.tauF, positive = 1 )
	p.Fscale = NMPulseNumByKey( "Fscale", paramList, p.Fscale, positive = 1 )
	
End // NMPulseTrainDFinit

//****************************************************************
//****************************************************************

Function NMPulseTrainDFsave( p, pdf )
	STRUCT NMPulseTrainDF &p
	String pdf
	
	String vp = promptPrefix + "TrainDF"
	
	if ( strlen( pdf ) == 0 )
		return 0
	endif
	
	SetNMvar( pdf + vp + "Dinf", p.Dinf )
	SetNMvar( pdf + vp + "Dmin", p.Dmin )
	SetNMvar( pdf + vp + "tauD", p.tauD )
	SetNMvar( pdf + vp + "Dscale", p.Dscale )
	SetNMvar( pdf + vp + "Finf", p.Finf )
	SetNMvar( pdf + vp + "Fmax", p.Fmax )
	SetNMvar( pdf + vp + "tauF", p.tauF )
	SetNMvar( pdf + vp + "Fscale", p.Fscale )
	
End // NMPulseTrainDFsave

//****************************************************************
//****************************************************************

Function /S NMPulseTrainDFparamList( p )
	STRUCT NMPulseTrainDF &p
	
	String pstr =  NMPulseParamList( "Dinf", p.Dinf )
	
	pstr += NMPulseParamList( "Dmin", p.Dmin )
	pstr += NMPulseParamList( "tauD", p.tauD )
	pstr += NMPulseParamList( "Dscale", p.Dscale )
	pstr += NMPulseParamList( "Finf", p.Finf )
	pstr += NMPulseParamList( "Fmax", p.Fmax )
	pstr += NMPulseParamList( "tauF", p.tauF )
	pstr += NMPulseParamList( "Fscale", p.Fscale )
	
	return pstr 
	
End // NMPulseTrainDFparamList

//****************************************************************
//****************************************************************

Function NMPulseTrainDFexists( paramList )
	String paramList
	
	if ( strlen( StringByKey( "Dinf", paramList, "=" ) ) == 0 )
		return 0
	endif
	
	if ( strlen( StringByKey( "Finf", paramList, "=" ) ) == 0 )
		return 0
	endif
	
	return 1
	
End // NMPulseTrainDFexists

//****************************************************************
//****************************************************************

Function /S NMPulseTrainDFadd( wName, paramList [ df, clear, DSCG, notes, wNameD, wNameF, s ] )
	String wName // name of input wave to add pulse train
	String paramList // train parameter list
	String df // data folder
	Variable clear // clear wave before adding pulses
	Variable DSCG // compute with delta or stdv or cv or gamma
	Variable notes
	String wNameD, wNameF
	STRUCT NMPulseSaveToWaves &s
	
	Variable icnt, trial, foundPulse, off, numPulses, fixed, doConvolution
	Variable stochastic, binomialN, successN
	Variable amp, onset, interval
	Variable D, F, foundD, foundF, saveD, saveF, xpnt1, xpnt2, xlast
	String pulse, wName2, paramList2
	
	String pName = "PU_PulseAddTemp2"
	String wNameTemp = "PU_PulseTrainAddTemp"
	
	STRUCT NMPulseTrain t
	STRUCT NMPulseTrainDF p
	STRUCT NMPulseSaveToWaves ss
	
	if ( ParamIsDefault( df ) )
		df = ""
	endif
	
	if ( ParamIsDefault( s ) )
		NMPulseSaveToWavesInit( ss )
	else
		ss = s
		stochastic = 1
	endif
	
	if ( ParamIsDefault( wNameD ) )
		wNameD = ""
	endif
	
	if ( ParamIsDefault( wNameF ) )
		wNameF = ""
	endif
	
	if ( ( strlen( wName ) == 0 ) || !WaveExists( $df + wName ) )
		return "" // nothing to do
	endif
	
	if ( ItemsInList( paramList ) == 0 )
		return "" // nothing to do
	endif
	
	off = str2num( StringByKey( "off", paramList, "=" ) )
	
	if ( off )
		return "" // nothing to do
	endif
	
	NMPulseTrainInit( t, paramList = paramList )
	
	if ( strlen( t.type ) == 0 )
		return "" // nothing to do
	endif
	
	pulse = StringByKey( "pulse", paramList, "=" )
	
	if ( strlen( pulse ) > 0 )
		foundPulse = 1
	endif
	
	NMPulseTrainDFinit( p, paramList = paramList )
	
	if ( ( numtype( p.tauD ) == 0 ) && ( p.tauD > 0 ) && ( numtype( p.Dscale ) == 0 ) && ( p.Dscale > 0 ) && ( p.Dscale < 1 ) )
		foundD = 1
	endif
	
	if ( ( numtype( p.tauF ) == 0 ) && ( p.tauF > 0 ) && ( numtype( p.Fscale ) == 0 ) && ( p.Fscale > 0 ) && ( p.Fscale < 1 ) )
		foundF = 1
	endif
	
	binomialN = NMPulseNumByKey( "binomialN", paramList, NaN, positive = 1 )
	
	if ( ( numtype( binomialN ) == 0 ) && ( binomialN > 0 ) )
		binomialN = round( binomialN )
		stochastic = 1
	else
		binomialN = 0
	endif
	
	if ( ( strsearch( paramList, ",stdv,", 0 ) > 0 ) || ( strsearch( paramList, ",cv,", 0 ) > 0 ) || ( strsearch( paramList, ",gammaA,", 0 ) > 0 ) )
		stochastic = 1
	endif
	
	Duplicate /O $( df + wName ) $( df + wNameTemp )
		
	Wave wtemp = $df + wNameTemp
		
	wtemp = 0
	
	if ( numtype( t.tbgn ) > 0 )
		t.tbgn = leftx( wtemp )
	endif
	
	if ( numtype( t.tend ) > 0 )
		t.tend = rightx( wtemp )
	endif
	
	xlast = numpnts( wtemp ) - 1
	
	if ( foundPulse && !stochastic )
		Duplicate /O $( df + wName ) $( df + pName )
		paramList2 = NMPulse( pName, paramList, df = df, clear = 1, DSCG = DSCG )
	endif
	
	if ( StringMatch( t.type, "fixed" ) )
	
		fixed = 1
		
		numPulses = 1 + floor( ( t.tend - t.tbgn ) / t.interval )
		
		if ( ( numtype( numPulses ) > 0 ) || ( numPulses < 0 ) )
			numPulses = 0
		endif
		
	else
	
		if ( WaveExists( $df + t.type ) )
			Wave pTimes = $df + t.type // user wave should have pulse times
			numPulses = numpnts( pTimes )
		else
			KillWaves /Z $df + pName
			KillWaves /Z $df + wNameTemp
			return ""
		endif
	
	endif
	
	amp = NMPulseNumByKey( "amp", paramList, NaN )
	
	ss.pulsesPerConfig = numPulses
	
	if ( ( strlen( wNameD ) > 0 ) && foundD )
	
		Duplicate /O $( df + wName ) $( df + wNameD )
		
		Wave wtempD = $df + wNameD
		
		saveD = 1
		wtempD = p.Dinf
		
	endif
	
	if ( ( strlen( wNameF ) > 0 ) && foundF )
	
		Duplicate /O $( df + wName ) $( df + wNameF )
		
		Wave wtempF = $df + wNameF
		
		saveF = 1
		wtempF = p.Finf
		
	endif
	
	if ( notes )
		Note $( df + wName ), paramList + "|"
	endif
	
	if ( binomialN == 0 )
	
		interval = t.interval
		D = p.Dinf
		F = p.Finf
		
		for ( icnt = 0 ; icnt < numPulses ; icnt += 1 )
		
			ss.pulseNum = icnt
		
			if ( fixed )
			
				onset = t.tbgn + icnt * interval
				
			elseif ( icnt < numpnts( pTimes ) )
			
				onset = pTimes[ icnt ]
				
				if ( icnt > 0 )
					interval = onset - pTimes[ icnt - 1 ]
				endif
				
			else
			
				break
				
			endif
			
			xpnt2 = x2pnt( wtemp, onset )
		
			if ( foundD )
				D = p.Dinf + ( D - p.Dinf ) * exp( -interval / p.tauD ) // recovery
			endif
			
			if ( foundF )
				F = p.Finf + ( F - p.Finf ) * exp( -interval / p.tauF ) // recovery
			endif
			
			if ( ( onset >= leftx( wtemp ) ) && ( onset <= rightx( wtemp ) ) )
				if ( ( onset >= t.tbgn ) && ( onset <= t.tend ) )
				
					if ( stochastic )
						paramList2 = NMPulseNumReplace( "onset", paramList, onset )
						paramList2 = NMPulseNumReplace( "amp", paramList2, amp * D * F )
						paramList2 = NMPulse( wNameTemp, paramList2, df = df, DSCG = DSCG, s = ss )
					else
						if ( ( xpnt2 >= 0 ) && ( xpnt2 < numpnts( wtemp ) ) )
							wtemp[ xpnt2 ] += D * F
						endif
						doConvolution = 1
					endif
				
				endif
			endif
			
			if ( foundD )
				D *= p.Dscale
				D = max( p.Dmin, D )
			endif
			
			if ( foundF )
				F *= p.Fscale
				F = min( p.Fmax, F )
			endif
			
			xpnt1 = xpnt2 + 1
			
			if ( saveD && ( xpnt1 < xlast ) )
				wtempD[ xpnt1, xlast ] = p.Dinf + ( D - p.Dinf ) * exp( -( x - onset ) / p.tauD )
			endif
			
			if ( saveF && ( xpnt1 < xlast ) )
				wtempF[ xpnt1, xlast ] = p.Finf + ( F - p.Finf ) * exp( -( x - onset ) / p.tauF )
			endif
		
		endfor
	
	else
	
		interval = t.interval
		
		ss.binomialN = binomialN
	
		for ( trial = 0 ; trial < binomialN ; trial += 1 )
		
			D = p.Dinf
			F = p.Finf
			
			if ( saveD )
				wtempD = p.Dinf
			endif
			
			if ( saveF )
				wtempF = p.Finf
			endif
			
			ss.trial = trial
			
			for ( icnt = 0 ; icnt < numPulses ; icnt += 1 )
			
				ss.pulseNum = icnt
	
				if ( abs( enoise( 1.0 ) ) < D * F )
					successN = 1
				else
					successN = 0
				endif
				
				if ( fixed )
				
					onset = t.tbgn + icnt * interval
					
				elseif ( icnt < numpnts( pTimes ) )
				
					onset = pTimes[ icnt ]
					
					if ( icnt > 0 )
						interval = onset - pTimes[ icnt - 1 ]
					endif
					
				else
				
					break
				
				endif
				
				xpnt2 = x2pnt( wtemp, onset )
		
				if ( foundD )
					D = p.Dinf + ( D - p.Dinf ) * exp( -interval / p.tauD ) // recovery
				endif
				
				if ( foundF )
					F = p.Finf + ( F - p.Finf ) * exp( -interval / p.tauF ) // recovery
				endif
				
				if ( successN && ( onset >= leftx( wtemp ) ) && ( onset <= rightx( wtemp ) ) )
					if ( ( onset >= t.tbgn ) && ( onset <= t.tend ) )
					
						if ( stochastic )
							paramList2 = NMPulseNumReplace( "onset", paramList, onset )
							paramList2 = NMPulse( wNameTemp, paramList2, df = df, DSCG = DSCG, s = ss )
						else
							if ( ( xpnt2 >= 0 ) && ( xpnt2 < numpnts( wtemp ) ) )
								wtemp[ xpnt2 ] += 1
							endif
							doConvolution = 1
						endif
						
					endif
				endif
				
				if ( successN )
					D = 0
				endif
				
				if ( foundF && ( p.Fscale != 1 ) )
					F *= p.Fscale
					F = min( p.Fmax, F )
				endif
				
				xpnt1 = xpnt2 + 1
				
				if ( successN && saveD && ( xpnt1 < xlast ) )
					wtempD[ xpnt1, xlast ] = p.Dinf + ( D - p.Dinf ) * exp( -( x - onset ) / p.tauD )
				endif
				
				if ( saveF && ( xpnt1 < xlast ) )
					wtempF[ xpnt1, xlast ] = p.Finf + ( F - p.Finf ) * exp( -( x - onset ) / p.tauF )
				endif
				
			endfor
	
		endfor
	
	endif
	
	if ( foundPulse && doConvolution )
		Convolve $( df + pName ) wtemp
		Redimension /N=( numpnts( $df + wName ) ) wtemp
	endif
	
	Wave wtemp2 = $df + wName
	
	if ( clear )
		wtemp2 = wtemp
	else
		wtemp2 += wtemp
	endif
	
	KillWaves /Z $df + pName
	KillWaves /Z $df + wNameTemp
	
	return df + wName
	
End // NMPulseTrainDFadd

//****************************************************************
//****************************************************************

Structure NMPulseTrainDittman

	Variable tauD, K0, Kmax, KD, deltaD
	Variable tauF, F1, Fratio, KF, deltaF

EndStructure

//****************************************************************
//****************************************************************

Function NMPulseTrainDittmanInit( p [ pdf, paramList, model ] ) 
	STRUCT NMPulseTrainDittman &p
	String pdf, paramList, model
	
	Variable paramsOnly
	String vp
	
	if ( !ParamIsDefault( paramList ) && ( strlen( paramList ) > 0 ) )
	
		p.tauD = NMPulseNumByKey( "tauD", paramList, p.tauD, positive = 1 )
		p.K0 = NMPulseNumByKey( "K0", paramList, p.K0, positive = 1 )
		p.Kmax = NMPulseNumByKey( "Kmax", paramList, p.Kmax, positive = 1 )
		p.KD = NMPulseNumByKey( "KD", paramList, p.KD, positive = 1 )
		p.deltaD = NMPulseNumByKey( "deltaD", paramList, p.deltaD, positive = 1 )
		
		p.tauF = NMPulseNumByKey( "tauF", paramList, p.tauF, positive = 1 )
		p.F1 = NMPulseNumByKey( "F1", paramList, p.F1, positive = 1 )
		p.Fratio = NMPulseNumByKey( "Fratio", paramList, p.Fratio, positive = 1 )
		p.KF = NMPulseNumByKey( "KF", paramList, p.KF, positive = 1 )
		p.deltaF = NMPulseNumByKey( "deltaF", paramList, p.deltaF, positive = 1 )
	
		return 0
	
	endif
	
	if ( ParamIsDefault( model ) )
		model = "parallel fiber"
	else
		paramsOnly = 1
	endif
	
	strswitch( model ) // Table 2 of Dittman 2000
	
		case "Climbing Fiber":
			
			p.tauD = 50
			p.K0 = 0.7 / 1000
			p.Kmax = 20 / 1000
			p.KD = 2
			
			p.Fratio = NaN
			p.F1 = 0.35
			p.tauF = -1
			
			break
		
		case "Parallel Fiber":
			
			p.tauD = 50
			p.K0 = 2 / 1000
			p.Kmax = 30 / 1000
			p.KD = 2
			
			p.Fratio = 3.1
			p.F1 = 0.05
			p.tauF = 100
			
			break
			
		case "Schaffer Collateral":
			
			p.tauD = 50
			p.K0 = 2 / 1000
			p.Kmax = 30 / 1000
			p.KD = 2
			
			p.Fratio = 2.2
			p.F1 = 0.24
			p.tauF = 100
			
			break
			
		default:
		
			p.tauD = -1
			p.K0 = NaN
			p.Kmax = NaN
			p.KD = NaN
			
			p.Fratio = NaN
			p.F1 = NaN
			p.tauF = -1
			
	endswitch
	
	p.deltaD = 1 // Fig 3C Dittman 2000
	p.deltaF = 1
	
	p.KF = NMPulseTrainDittmanKF( p.F1, P.Fratio, P.deltaF )
	
	if ( paramsOnly )
		return 0
	endif
	
	if ( !ParamIsDefault( pdf ) && ( strlen( pdf ) > 0 ) )
	
		vp = promptPrefix + "Dittman"
	
		p.tauD = NumVarOrDefault( pdf + vp + "tauD", p.tauD )
		p.K0 = NumVarOrDefault( pdf + vp + "K0", p.K0 )
		p.Kmax = NumVarOrDefault( pdf + vp + "Kmax", p.Kmax )
		p.KD = NumVarOrDefault( pdf + vp + "KD", p.KD )
		p.deltaD = NumVarOrDefault( pdf + vp + "deltaD", p.deltaD )
		
		p.tauF = NumVarOrDefault( pdf + vp + "tauF", p.tauF )
		p.F1 = NumVarOrDefault( pdf + vp + "F1", p.F1 )
		p.Fratio = NumVarOrDefault( pdf + vp + "Fratio", p.Fratio )
		p.KF = NumVarOrDefault( pdf + vp + "KF", p.KF )
		p.deltaF = NumVarOrDefault( pdf + vp + "deltaF", p.deltaF )
		
	endif
	
End // NMPulseTrainDittmanInit

//****************************************************************
//****************************************************************

Function NMPulseTrainDittmanKF( F1, Fratio, deltaF )
	Variable F1, Fratio, deltaF
	
	Variable KF
	
	if ( numtype( Fratio ) > 0 )
		return NaN
	endif
	
	KF = ( ( F1 / ( 1 - F1 ) ) * Fratio ) - F1
	KF = ( (1 - F1 ) / KF ) - 1
	KF *= deltaF // Eq 7 of Dittman 2000
	
	return KF
	
End // NMPulseTrainDittmanKF

//****************************************************************
//****************************************************************

Function NMPulseTrainDittmanSave( p, pdf )
	STRUCT NMPulseTrainDittman &p
	String pdf
	
	String vp = promptPrefix + "Dittman"
	
	if ( strlen( pdf ) == 0 )
		return 0
	endif
	
	SetNMvar( pdf + vp + "tauD", p.tauD )
	SetNMvar( pdf + vp + "K0", p.K0 )
	SetNMvar( pdf + vp + "Kmax", p.Kmax )
	SetNMvar( pdf + vp + "KD", p.KD )
	SetNMvar( pdf + vp + "deltaD", p.deltaD )
	
	SetNMvar( pdf + vp + "tauF", p.tauF )
	SetNMvar( pdf + vp + "F1", p.F1 )
	SetNMvar( pdf + vp + "Fratio", p.Fratio )
	SetNMvar( pdf + vp + "KF", p.KF )
	SetNMvar( pdf + vp + "deltaF", p.deltaF )
	
End // NMPulseTrainDittmanSave

//****************************************************************
//****************************************************************

Function /S NMPulseTrainDittmanParamList( p )
	STRUCT NMPulseTrainDittman &p
	
	String pstr =  NMPulseParamList( "tauD", p.tauD )
	
	pstr += NMPulseParamList( "K0", p.K0 )
	pstr += NMPulseParamList( "Kmax", p.Kmax )
	pstr += NMPulseParamList( "KD", p.KD )
	pstr += NMPulseParamList( "deltaD", p.deltaD )
	pstr += NMPulseParamList( "tauF", p.tauF )
	pstr += NMPulseParamList( "F1", p.F1 )
	
	if ( numtype( p.Fratio ) == 0 )
		pstr += NMPulseParamList( "Fratio", p.Fratio )
	endif
	
	pstr += NMPulseParamList( "KF", p.KF )
	pstr += NMPulseParamList( "deltaF", p.deltaF )
	
	return pstr 
	
End // NMPulseTrainDittmanParamList

//****************************************************************
//****************************************************************

Function NMPulseTrainDittmanExists( paramList )
	String paramList
	
	if ( strlen( StringByKey( "K0", paramList, "=" ) ) == 0 )
		return 0
	endif
	
	if ( strlen( StringByKey( "Kmax", paramList, "=" ) ) == 0 )
		return 0
	endif
	
	if ( strlen( StringByKey( "KD", paramList, "=" ) ) == 0 )
		return 0
	endif
	
	if ( strlen( StringByKey( "F1", paramList, "=" ) ) == 0 )
		return 0
	endif
	
	return 1
	
End // NMPulseTrainDittmanExists

//****************************************************************
//****************************************************************

Function /S NMPulseTrainDittmanAdd( wName, paramList [ df, clear, DSCG, notes, wNameD, wNameF, wNameCaXD, wNameCaXF, s ] )
	String wName // name of input wave to add pulse train
	String paramList // train parameter list
	String df // data folder
	Variable clear // clear wave before adding pulses
	Variable DSCG // compute with delta or stdv or cv or gamma
	Variable notes
	String wNameD, wNameF, wNameCaXD, wNameCaXF
	STRUCT NMPulseSaveToWaves &s
	
	Variable icnt, jcnt, foundPulse, off, numPulses, fixed, xpnts, dx
	Variable amp, onset, interval
	Variable foundF, saveD, saveF, saveCaXD, saveCaXF, xpnt1, xpnt2
	String pulse, paramList2, wName2
	
	String pName = "PU_PulseAddTemp2"
	String wNameTemp = "PU_PulseTrainAddTemp"
	
	STRUCT NMPulseTrain t
	STRUCT NMPulseTrainDittman p
	STRUCT NMPulseSaveToWaves ss
	
	if ( ParamIsDefault( df ) )
		df = ""
	endif
	
	if ( ParamIsDefault( wNameD ) || ( strlen( wNameD ) == 0 ) )
		wNameD = "PU_D"
	else
		saveD = 1
	endif
	
	if ( ParamIsDefault( wNameF ) || ( strlen( wNameF ) == 0 ) )
		wNameF = "PU_F"
	else
		saveF = 1
	endif
	
	if ( ParamIsDefault( wNameCaXD ) || ( strlen( wNameCaXD ) == 0 ) )
		wNameCaXD = "PU_CaXD"
	else
		saveCaXD = 1
	endif
	
	if ( ParamIsDefault( wNameCaXF ) || ( strlen( wNameCaXF ) == 0 ) )
		wNameCaXF = "PU_CaXF"
	else
		saveCaXF = 1
	endif
	
	if ( ParamIsDefault( s ) )
		NMPulseSaveToWavesInit( ss )
	else
		ss = s
	endif
	
	if ( ( strlen( wName ) == 0 ) || !WaveExists( $df + wName ) )
		return "" // nothing to do
	endif
	
	if ( ItemsInList( paramList ) == 0 )
		return "" // nothing to do
	endif
	
	off = str2num( StringByKey( "off", paramList, "=" ) )
	
	if ( off )
		return "" // nothing to do
	endif
	
	NMPulseTrainInit( t, paramList = paramList )
	
	if ( strlen( t.type ) == 0 )
		return "" // nothing to do
	endif
	
	pulse = StringByKey( "pulse", paramList, "=" )
	
	if ( strlen( pulse ) > 0 )
		foundPulse = 1
	endif
	
	NMPulseTrainDittmanInit( p, paramList = paramList )
	
	if ( ( numtype( p.tauF ) == 0 ) && ( p.tauF > 0 ) && ( numtype( p.KF ) == 0 ) && ( p.KF > 0 ) )
		foundF = 1
	endif
	
	Duplicate /O $( df + wName ) $( df + wNameTemp )
		
	Wave wtemp = $df + wNameTemp
		
	wtemp = 0
	
	xpnts = numpnts( wtemp )
	dx = deltax( wtemp )
	
	if ( numtype( t.tbgn ) > 0 )
		t.tbgn = leftx( wtemp )
	endif
	
	if ( numtype( t.tend ) > 0 )
		t.tend = rightx( wtemp )
	endif
	
	if ( foundPulse )
		Duplicate /O $( df + wName ) $( df + pName )
		paramList2 = NMPulse( pName, paramList, df = df, clear = 1, DSCG = DSCG )
	endif
	
	if ( StringMatch( t.type, "fixed" ) )
	
		fixed = 1
		
		numPulses = 1 + floor( ( t.tend - t.tbgn ) / t.interval )
		
		if ( ( numtype( numPulses ) > 0 ) || ( numPulses < 0 ) )
			numPulses = 0
		endif
		
	else
	
		if ( WaveExists( $df + t.type ) )
			Wave pTimes = $df + t.type // user wave should have pulse times
			numPulses = numpnts( pTimes )
		else
			KillWaves /Z $df + pName
			KillWaves /Z $df + wNameTemp
			return ""
		endif
	
	endif
	
	wName2 = "PU_States3"
	
	Make /O/N=( xpnts, 3 ) $( df + wName2 ) = NaN // we have 3 first-order differential equations
	
	Wave states = $df + wName2
	
	SetScale /P x 0, dx, states
	SetDimLabel 1, 0, CaXF, states
	SetDimLabel 1, 1, CaXD, states
	SetDimLabel 1, 2, DT, states
	
	states[ 0 ][ 0 ] = 0 // initial condition ( CaXF = 0 )
	states[ 0 ][ 1 ] = 0 // initial condition ( CaXD = 0 )
	states[ 0 ][ 2 ] = 1 // initial condition ( D = 1 )
	
	wName2 = "PU_PW"
	Make /O/N=5 $( df + wName2 ) = NaN
	Wave pw = $df + wName2
	
	pw[ 0 ] = p.tauF
	pw[ 1 ] = p.tauD
	pw[ 2 ] = p.K0
	pw[ 3 ] = p.Kmax
	pw[ 4 ] = p.KD
	
	wName2 = "PU_D"
	Make /O/N=( xpnts ) $( df + wNameD ) = NaN
	Wave Dt = $df + wNameD
	SetScale /P x 0, dx, Dt
	
	Make /O/N=( xpnts ) $( df + wNameF ) = NaN
	Wave Ft = $df + wNameF
	SetScale /P x 0, dx, Ft
	
	Make /O/N=( xpnts ) $( df + wNameCaXD ) = NaN
	Wave CaXD = $df + wNameCaXD
	SetScale /P x 0, dx, CaXD
	
	Make /O/N=( xpnts ) $( df + wNameCaXF ) = NaN
	Wave CaXF = $df + wNameCaXF
	SetScale /P x 0, dx, CaXF
	
	interval = t.interval
	xpnt1 = 0
	
	if ( notes )
		Note $( df + wName ), paramList + "|"
	endif
	
	for ( icnt = 0 ; icnt < numPulses ; icnt += 1 )
	
		if ( fixed )
		
			onset = t.tbgn + icnt * interval
			
		elseif ( icnt < numpnts( pTimes ) )
		
			onset = pTimes[ icnt ]
			
			if ( icnt > 0 )
				interval = onset - pTimes[ icnt - 1 ]
			endif
			
		else
		
			break
			
		endif
		
		if ( ( onset < leftx( wtemp ) ) || ( onset > rightx( wtemp ) ) )
			continue
		endif
		
		if ( ( onset < t.tbgn ) || ( onset > t.tend ) )
			continue
		endif
		
		xpnt2 = x2pnt( wtemp, onset )
		xpnt2 = min( xpnt2, numpnts( wtemp ) - 1 )
		
		IntegrateODE /R=[ xpnt1, xpnt2 ] NM_Dittman_DYDT, pw, states
		
		if ( foundF )
		
			for ( jcnt = xpnt1 ; jcnt <= xpnt2 ; jcnt += 1 )
				Ft[ jcnt ] = p.F1 + ( 1 - p.F1 ) / ( 1 + ( p.KF / states[ jcnt ][ 0 ] ) )
			endfor
		
		else
		
			Ft = p.F1
			
		endif
		
		wtemp[ xpnt2 ] += Ft[ xpnt2 ] * states[ xpnt2 ][ 2 ]
		
		states[ xpnt2 ][ 0 ] += p.deltaF
		states[ xpnt2 ][ 1 ] += p.deltaD
		states[ xpnt2 ][ 2 ] -= states[ xpnt2 ][ 2 ] * Ft[ xpnt2 ]
		
		xpnt1 = xpnt2
	
	endfor
	
	for ( icnt = 0 ; icnt < xpnts ; icnt += 1 )
		CaXF[ icnt ] = states[ icnt ][ 0 ]
		CaXD[ icnt ] = states[ icnt ][ 1 ]
		Dt[ icnt ] = states[ icnt ][ 2 ]
	endfor
	
	if ( foundPulse )
		Convolve $( df + pName ) wtemp
		Redimension /N=( numpnts( $df + wName ) ) wtemp
	endif
	
	Wave wtemp2 = $df + wName
	
	if ( clear )
		wtemp2 = wtemp
	else
		wtemp2 += wtemp
	endif
	
	KillWaves /Z $df + pName
	KillWaves /Z $df + wNameTemp
	KillWaves /Z states, pw
	
	if ( !saveD )
		KillWaves /Z Dt
	endif
	
	if ( !saveF )
		KillWaves /Z Ft
	endif
	
	if ( !saveCaXD )
		KillWaves /Z CaXD
	endif
	
	if ( !saveCaXF )
		KillWaves /Z CaXF
	endif
	
	return df + wName
	
End // NMPulseTrainDittmanAdd

//****************************************************************
//****************************************************************

Function NM_Dittman_Testing()

	Variable icnt, jcnt, spike, xpnt1, xpnt2
	Variable interval = 10
	Variable firstSpike = 10
	Variable numSpikes = 10

	Variable waveLength = 100
	Variable dx = 0.01
	Variable xpnts = 1 + waveLength / dx
	
	Variable /G tauF = 100
	Variable F1 = 0.15
	Variable KF = NaN
	Variable Pratio = 3.4
	Variable deltaF = 1
	
	Variable /G tauD = 50
	Variable /G K0 = 2 / 1000
	Variable /G Kmax = 30 / 1000
	Variable /G KD = 2
	Variable deltaD = 1
	
	KF = ( F1 / ( 1 - F1 ) ) * Pratio - F1
	KF = ( (1 - F1 ) / KF ) - 1
	KF *= deltaF
	
	Make /O/N=( xpnts, 3 ) States = NaN // we have 3 first-order differential equations
	SetScale /P x 0, dx, States
	
	SetDimLabel 1, 0, CaXF, States
	SetDimLabel 1, 1, CaXD, States
	SetDimLabel 1, 2, DT, States
	
	States[ 0 ][ 0 ] = 0 // initial condition ( CaXF = 0 )
	States[ 0 ][ 1 ] = 0 // initial condition ( CaXD = 0 )
	States[ 0 ][ 2 ] = 1 // initial condition ( D = 1 )
	
	Make /O/N=1 PP // NOT USED
	
	Make /O/N=( xpnts ) State_CaXF, State_FT
	SetScale /P x 0, dx, State_CaXF, State_FT
	
	Make /O/N=( xpnts ) State_CaXD, State_DT
	SetScale /P x 0, dx, State_CaXD, State_DT
	
	Make /O/N=( xpnts ) EPSCs
	SetScale /P x 0, dx, EPSCs
	
	xpnt1 = 0
	
	for ( icnt = 0 ; icnt < numSpikes ; icnt += 1 )
	
		spike = firstSpike + icnt * interval
		xpnt2 = x2pnt( State_CaXF, spike )
		xpnt2 = min( xpnt2, xpnts - 1 )
		
		if ( ( xpnt1 == xpnt2 ) || ( xpnt1 >= xpnts ) )
			break
		endif
		
		IntegrateODE /R=[ xpnt1, xpnt2 ] NM_Dittman_DYDT, PP, States
		
		for ( jcnt = xpnt1 ; jcnt <= xpnt2 ; jcnt += 1 )
			State_FT[ jcnt ] = F1 + ( 1 - F1 ) / ( 1 + ( KF / States[ jcnt ][ 0 ] ) )
		endfor
		
		States[ xpnt2 ][ 0 ] += deltaF
		States[ xpnt2 ][ 1 ] += deltaD
		States[ xpnt2 ][ 2 ] -= States[ xpnt2 ][ 2 ] * State_FT[ xpnt2 ]
		
		xpnt1 = xpnt2
	
	endfor
	
	for ( icnt = 0 ; icnt < xpnts ; icnt += 1 )
		State_CaXF[ icnt ] = States[ icnt ][ 0 ]
		State_CaXD[ icnt ] = States[ icnt ][ 1 ]
		State_DT[ icnt ] = States[ icnt ][ 2 ]
	endfor

End // NM_Dittman_Testing

//****************************************************************
//****************************************************************

Function NM_Dittman_DYDT( pw, tt, yw, dydt ) // see IntegrateODE
	Wave pw	// parameter wave
	Variable tt	// time value at which to calculate derivatives
	Wave yw 	// wave containing y[i] (input)	
	Wave dydt	// wave to receive dy[i]/dt (output)
	
	Variable Krecov
	
	Variable tauF = pw[ 0 ] // ms
	Variable tauD = pw[ 1 ] // ms
	Variable K0 = pw[ 2 ] // ms-1
	Variable Kmax = pw[ 3 ] // ms-1
	Variable KD = pw[ 4 ]
	
	dydt[ 0 ] = -yw[ 0 ] / tauF // dCaXF/dt (Eq 3)
	dydt[ 1 ] = -yw[ 1 ] / tauD // dCaXD/dt (Eq 12)
	
	Krecov = K0 + ( Kmax - K0 ) / ( 1 + ( KD / yw[ 1 ] ) ) // Eq. 14
	
	dydt[ 2 ] = ( 1 - yw[ 2 ] ) * Krecov  // dD/dt (Eq 13)
	
End // NM_Dittman_DYDT

//****************************************************************
//****************************************************************

Function NMPulseTrainRandomTimes( df, wName, paramList, timeLimit )
	String df // data folder
	String wName // wave name
	String paramList // "interval=10;tbgn=20;tend=1000;refrac=1;" // all in ms
	Variable timeLimit
	
	Variable interval, intervalCorrected, freq, refrac, tbgn, tend, tlast, pcnt, plimit, onset
	String xLabel, yLabel
	
	if ( strlen( wName ) == 0 )
		return 0
	endif
	
	if ( strlen( paramList ) == 0 )
		return 0
	endif
	
	if ( ( numtype( timeLimit ) > 0 ) || ( timeLimit <= 0 ) )
		return 0
	endif
	
	interval = NMPulseNumByKey( "interval", paramList, 0, positive = 1 )
	
	if ( ( numtype( interval ) > 0 ) || ( interval <= 0 ) )
	
		freq = NMPulseNumByKey( "freq", paramList, 0, positive = 1 )	
		
		if ( ( numtype( freq ) == 0 ) || ( freq > 0 ) )
			interval = 1 / freq
		else
			return 0
		endif
		
	endif
	
	if ( ( numtype( interval ) > 0 ) || ( interval <= 0 ) )
		return 0
	endif
	
	tbgn = NMPulseNumByKey( "tbgn", paramList, 0 )
	tend = NMPulseNumByKey( "tend", paramList, inf )
	
	if ( numtype( tbgn ) > 0 )
		tbgn = 0
	endif
	
	if ( ( numtype( tend ) > 0 ) || ( tend > timeLimit ) )
		tend = timeLimit
	endif
	
	if ( tend <= tbgn )
		return 0
	endif
	
	refrac = NMPulseNumByKey( "refrac", paramList, 0, positive = 1 )

	if ( ( numtype( refrac ) > 0 ) || ( refrac < 0 ) )
		refrac = 0
	endif
	
	intervalCorrected = interval
	
	if ( refrac > 0 )
		intervalCorrected -= refrac // correct rate for refractory period
	endif

	tlast = tbgn + ln( abs( enoise( 1 ) ) ) * intervalCorrected // start before tbgn
	
	plimit = floor( 400 + ( ( tend - tbgn ) / intervalCorrected ) )
	
	Make /O/N=( plimit ) $df + wName = NaN
	
	Wave wtemp = $df + wName
		
	do // compute random pulse times

		onset = tlast - ln( abs( enoise( 1 ) ) ) * intervalCorrected // add random interval
		
		if ( ( onset > tlast + refrac ) && ( onset >= tbgn ) && ( onset <= tend ) )
			wtemp[ pcnt ] = onset
			tlast = onset
			pcnt += 1
		endif
		
	while ( ( onset < tend ) && ( pcnt < plimit ) )
	
	Redimension /N=( pcnt ) wtemp
	
	xLabel = "pulse number"
	yLabel = NMXunits
	
	NMNoteType( df + wName, "NM Random Pulses", xLabel, yLabel, "_FXN_" )
		
	Note $df + wName, ReplaceString( "=", paramList, ":" )
	
	return pcnt
			
End // NMPulseTrainRandomTimes

//****************************************************************
//****************************************************************

Function /S NMPulseWavesMake( pulseWaveName, df, wList, xpnts, dx [ scale, notes, savePlasticityWaves ] )
	String pulseWaveName // text wave containing pulse configs
	String df // data folder where output waves are to be made
	String wList // list of output wave names
	Variable xpnts, dx
	Variable scale // final scale factor
	Variable notes
	Variable savePlasticityWaves
	
	Variable wcnt, pcnt, numWaves, waveNum, wnum
	String valueStr, wName, outputName, paramList, train
	
	STRUCT NMParams nm
	STRUCT NMMakeStruct m
	
	NMParamsNull( nm )
	NMMakeStructNull( m )
	
	nm.folder = df
	nm.wList = wList
	m.xpnts = xpnts
	m.dx = dx
	
	return NMPulseWavesMake2( pulseWaveName, nm, m, scale = scale, notes = notes, savePlasticityWaves = savePlasticityWaves )
	
End // NMPulseWavesMake

//****************************************************************
//****************************************************************

Function /S NMPulseWavesMake2( pulseWaveName, nm, m [ scale, notes, savePlasticityWaves, s ] )
	String pulseWaveName // text wave containing pulse configs
	STRUCT NMParams &nm // uses nm.folder, nm.wList, nm.wavePrefix, nm.chanNum
	STRUCT NMMakeStruct &m
	Variable scale // final scale factor
	Variable notes // ( 0 ) no ( 1 ) yes
	Variable savePlasticityWaves // ( 0 ) no ( 1 ) yes
	STRUCT NMPulseSaveToWaves &s
	
	Variable wcnt, ccnt, numWaves, wnum, numConfigs
	String valueStr, wName, outputName, paramList, paramList2, waveNumList
	String train, wList, wList2, progressStr, noteStr = ""
	String wNameD = "", wNameF = "", wNameCaXD = "", wNameCaXF = "", wNameR = "", wNameP = ""
	
	STRUCT NMPulseSaveToWaves ss
	
	if ( ParamIsDefault( s ) )
		NMPulseSaveToWavesInit( ss )
	else
		ss = s
	endif

	if ( !DataFolderExists( nm.folder ) )
		NewDataFolder $RemoveEnding( nm.folder, ":" ) // create data folder if it does not exist
	endif
	
	//if ( ItemsInList( nm.wList ) > 0 )
		//NMMake2( nm, m )
	//endif
	
	wList = nm.wList
	numWaves = ItemsInList( wList )
	
	//if ( numWaves == 0 )
		//wList = nm.newList
		//numWaves = ItemsInList( wList )
	//endif
	
	if ( numWaves == 0 )
		return ""
	endif
	
	if ( ( strlen( pulseWaveName ) == 0 ) || !WaveExists( $pulseWaveName ) )
		return wList
	endif
	
	if ( ( strlen( ss.sf ) > 0 ) && DataFolderExists( ss.sf ) )
		ss.numWaves = numWaves
	endif
	
	Wave /T pulse = $pulseWaveName
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
		
		wName = StringFromList( wcnt, wList )
		
		if ( strlen( wName ) == 0 )
			continue
		endif
		
		Make /O/N=( m.xpnts ) $( nm.folder + wName ) = 0
		SetScale /P x 0, m.dx, "", $nm.folder + wName
		
		nm.successList += nm.folder + wName + ";"
		
		NMNoteType( nm.folder + wName, "NMPulse", m.xLabel, m.yLabel, "PulseConfigs|" )
			
	endfor
	
	numConfigs = numpnts( pulse )
	
	progressStr = "Computing Pulse Waves..."
	
	for ( ccnt = 0 ; ccnt < numConfigs ; ccnt += 1 )
	
		if ( NMProgress( ccnt, numConfigs, progressStr ) == 1 )
			break
		endif
	
		paramList = pulse[ ccnt ]
		
		if ( ItemsInList( paramList ) == 0 )
			continue
		endif
		
		waveNumList = NMPulseWaveNumSeq( paramList, numWaves, convert2list = 1 )
		
		train = StringByKey( "train", paramList, "=" )
		
		if ( ItemsInList( waveNumList ) == 0 )
			continue
		endif
		
		ss.pulseConfigNum = ccnt
		
		for ( wcnt = 0 ; wcnt < ItemsInList( waveNumList ) ; wcnt += 1 )
		
			wnum = str2num( StringFromList( wcnt, waveNumList ) )
			
			wName = StringFromList( wnum, wList )
			
			if ( ( strlen( wName ) == 0 ) || !WaveExists( $nm.folder + wName ) )
				continue
			endif
			
			ss.waveNum = wnum
			
			if ( strlen( train ) > 0 )
			
				if ( NMPulseTrainRPexists( paramList ) )
				
					ss.plasticity = 1
					
					if ( savePlasticityWaves )
						wNameR = "PU_R_c" + num2istr( ccnt ) + "w" + num2istr( wnum )
						wNameP = "PU_P_c" + num2istr( ccnt ) + "w" + num2istr( wnum )
					endif
					
					NMPulseTrainRPadd( wName, paramList, df=nm.folder, DSCG=wcnt, notes=notes, wNameR=wNameR, wNameP=wNameP, s=ss )
					
				elseif ( NMPulseTrainDFexists( paramList ) )
				
					ss.plasticity = 1
					
					if ( savePlasticityWaves )
						wNameD = "PU_D_c" + num2istr( ccnt ) + "w" + num2istr( wnum )
						wNameF = "PU_F_c" + num2istr( ccnt ) + "w" + num2istr( wnum )
					endif
					
					NMPulseTrainDFadd( wName, paramList, df=nm.folder, DSCG=wcnt, notes=notes, wNameD=wNameD, wNameF=wNameF, s=ss )
					
				elseif ( NMPulseTrainDittmanExists( paramList ) )
				
					ss.plasticity = 1
					
					if ( savePlasticityWaves )
						wNameD = "PU_D_c" + num2istr( ccnt ) + "w" + num2istr( wnum )
						wNameF = "PU_F_c" + num2istr( ccnt ) + "w" + num2istr( wnum )
						wNameCaXD = "PU_CaXD_c" + num2istr( ccnt ) + "w" + num2istr( wnum )
						wNameCaXF = "PU_CaXF_c" + num2istr( ccnt ) + "w" + num2istr( wnum )
					endif
					
					NMPulseTrainDittmanAdd( wName, paramList, df=nm.folder, DSCG=wcnt, notes=notes, wNameD=wNameD, wNameF=wNameF, wNameCaXD=wNameCaXD, wNameCaXF=wNameCaXF, s=ss )
					
				else
				
					NMPulseTrainAdd( wName, paramList, df=nm.folder, DSCG=wcnt, notes=notes, s=ss )
					
				endif
				
			else
			
				paramList2 = NMPulseAdd( wName, paramList, df=nm.folder, DSCG=wcnt, notes=notes, s=ss )
				
			endif
				
		endfor
		
		if ( NMProgressCancel() == 1 )
			return wList
		endif
	
	endfor
	
	if ( ( scale == 1 ) || ( scale == 0 ) || ( numtype( scale ) > 0 ) )
		return wList
	endif
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
		
		wName = StringFromList( wcnt, wList )
		
		if ( WaveExists( $nm.folder+wName ) )
			
			Wave wtemp = $nm.folder+wName
		
			wtemp *= scale
		
		endif
		
	endfor
	
	return wList
	
End // NMPulseWavesMake2

//****************************************************************
//****************************************************************

Function PulseWavesKill(df, wPrefix)
	String df // directory folder
	String wPrefix // wave prefix
	
	Variable icnt
	
	String thisDF = GetDataFolder(1) // save current directory

	SetDataFolder $df
	
	String wlist = WaveList(wPrefix + "*", ";", "")
	String wlist2 = WaveList("*_Pulse*", ";", "")

	for (icnt = 0; icnt < ItemsInList(wlist2); icnt += 1)
		wlist = RemoveFromList(StringFromList(icnt, wlist2), wlist)
	endfor
	
	if (strlen(wlist) > 0)
	
		PulseGraphRemove(wlist)
		
		for (icnt = 0; icnt < ItemsInList(wlist); icnt += 1)
			KillWaves /Z $StringFromList(icnt, wlist)
		endfor
		
	endif
	
	SetDataFolder $thisDF // back to original data folder
	
End // PulseWavesKill

//****************************************************************
//****************************************************************

Structure NMPulseParams

	Variable value, delta, stdv, cv, gammaA, gammaB
	Variable foundDelta, foundSTDV, foundCV, foundGamma, fixPolarity

EndStructure

//****************************************************************
//****************************************************************

Function NMPulseParamsInit( p, varName, paramList )
	STRUCT NMPulseParams &p
	String varName, paramList
	
	Variable items, icnt, value, found = 0
	String valueStr, str0, str1, stemp, select, select2
	
	p.value = NaN
	p.delta = NaN
	p.stdv = NaN
	p.cv = NaN
	p.gammaA = NaN
	p.gammaB = NaN
	
	p.foundDelta = 0
	p.foundSTDV = 0
	p.foundCV = 0
	p.foundGamma = 0
	p.fixPolarity = 0
	
	valueStr = StringByKey( varName, paramList, "=", ";" )
	
	valueStr = ReplaceString( ",delta,", valueStr, ",delta=" )
	valueStr = ReplaceString( ",stdv,", valueStr, ",stdv=" )
	valueStr = ReplaceString( ",cv,", valueStr, ",cv=" )
	valueStr = ReplaceString( ",gammaA,", valueStr, ",gammaA=" )
	valueStr = ReplaceString( ",gammaB,", valueStr, ",gammaB=" )
	
	items = ItemsInList( valueStr, "," )
	
	if ( items == 0 )
		return 0
	endif
	
	str0 = StringFromList( 0, valueStr, "," )
	p.value = str2num( str0 )
	
	if ( items == 1 )
		return 0 // finished
	endif
	
	for ( icnt = 1 ; icnt < items ; icnt += 1 )
	
		stemp = StringFromList( icnt, valueStr, "," )
		
		if ( StringMatch( stemp[ 0, 4 ], "delta" ) )
			found = 1
			p.foundDelta = 1
			p.delta = NumberByKey( "delta", stemp, "=", "," )
		elseif ( StringMatch( stemp[ 0, 3 ], "stdv" ) )
			found = 1
			p.foundSTDV = 1
			p.stdv = NumberByKey( "stdv", stemp, "=", "," )
		elseif ( StringMatch( stemp[ 0, 1 ], "cv" ) )
			found = 1
			p.foundCV = 1
			p.cv = NumberByKey( "cv", stemp, "=", "," )
		elseif ( StringMatch( stemp[ 0, 5 ], "gammaA" ) )
			found = 1
			p.foundGamma = 1
			p.gammaA = NumberByKey( "gammaA", stemp, "=", "," )
		elseif ( StringMatch( stemp[ 0, 5 ], "gammaB" ) )
			found = 1
			p.foundGamma = 1
			p.gammaB = NumberByKey( "gammaB", stemp, "=", "," )
		elseif ( StringMatch( stemp, "FP" ) )
			found = 1
			p.fixPolarity = 1
		endif
	
	endfor
	
	if ( p.foundGamma && ( numtype( p.gammaA * p.gammaB ) > 0 ) )
		p.foundGamma = 0
	endif
	
	if ( !found ) // try old delta format
	
		str1 = StringFromList( 1, valueStr, "," )
		value = str2num( str1 )
		
		if ( numtype( value ) == 0 ) // old delta format
			p.foundDelta = 1
			p.delta = value
		endif
	
	endif
	
End // NMPulseParamsInit

//****************************************************************
//****************************************************************

Function NMPulseNumByKey( varName, paramList, defaultValue [ DSCG, positive ] )
	String varName, paramList
	Variable defaultValue
	Variable DSCG // compute with delta or stdv or cv or gamma
	Variable positive // force returned value to be positive value
	
	Variable newValue
	
	STRUCT NMPulseParams p
	
	NMPulseParamsInit( p, varName, paramList )
	
	if ( positive )
		p.value = abs( p.value )
		defaultValue = abs( defaultValue )
	endif
	
	if ( numtype( p.value ) == 2 )
		return defaultValue
	endif
	
	if ( ParamIsDefault( DSCG ) )
		return p.value
	endif
	
	if ( ( numtype( DSCG ) > 0 ) || ( DSCG < 0 ) )
		return p.value
	endif
	
	if ( p.foundDelta && ( numtype( DSCG * p.delta ) == 0 ) )
		newValue = p.value + DSCG * p.delta
	elseif ( p.foundSTDV && ( numtype( p.stdv ) == 0 ) )
		newValue = p.value + gnoise( p.stdv )
	elseif ( p.foundCV && ( numtype( p.cv ) == 0 ) )
		newValue = p.value + gnoise( p.cv * p.value )
	elseif ( p.foundGamma && ( numtype( p.gammaA * p.gammaB ) == 0 ) )
		newValue = p.value + gammaNoise( p.gammaA, p.gammaB )
	else
		return p.value
	endif
	
	if ( p.fixPolarity )
	
		if ( ( ( p.value > 0 ) && ( newValue > 0 ) ) || ( ( p.value < 0 ) && ( newValue < 0 ) ) )
			return newValue
		else
			return 0 // clip
		endif
		
	else
	
		return newValue
		
	endif
	
End // NMPulseNumByKey

//****************************************************************
//****************************************************************

Function NMPulseNumByKeyDSCG( varName, paramList )
	String varName, paramList
	
	STRUCT NMPulseParams p
	
	NMPulseParamsInit( p, varName, paramList )
	
	if ( p.foundDelta && ( numtype( p.delta ) == 0 ) )
		return p.delta
	endif

	if ( p.foundSTDV && ( numtype( p.stdv ) == 0 ) )
		return p.stdv
	endif
	
	if ( p.foundCV && ( numtype( p.cv ) == 0 ) )
		return p.cv
	endif
	
	if ( p.foundGamma && ( numtype( p.gammaA ) == 0 ) )
		return p.gammaA
	endif
	
	if ( p.foundGamma && ( numtype( p.gammaB ) == 0 ) )
		return p.gammaB
	endif
	
	return 0
	
End // NMPulseNumByKeyDSCG

//****************************************************************
//****************************************************************

Function /S NMPulseNumReplace( varName, paramList, newNum )
	String varName, paramList
	Variable newNum
	
	Variable icnt, items, oldNum
	String oldStr, newStr, s0, s1, s2, s3, s4, pList2
	
	String pList = StringByKey( varName, paramList, "=", ";" )
	
	items = ItemsInList( pList, "," )
	
	if ( items <= 1 )
		return ReplaceNumberByKey( varName, paramList, newNum, "=" , ";" )
	endif
	
	pList2 = num2str( newNum )
			
	for ( icnt = 1; icnt <= items - 1 ; icnt += 1 )
		pList2 += "," + StringFromList( icnt, pList, "," )
	endfor
	
	return ReplaceStringByKey( varName, paramList, pList2, "=" , ";" )
	
End // NMPulseNumReplace

//****************************************************************
//****************************************************************

Function NMPulseWaveNum( paramList )
	String paramList

	String valueStr = StringByKey( "wave", paramList, "=" )
		
	if ( strsearch( valueStr, "all", 0 ) == 0 )
		return 0
	else
		return NMPulseNumByKey( "wave", paramList, NaN, positive = 1 )
	endif

End // NMPulseWaveNum

//****************************************************************
//****************************************************************

Function /S NMPulseWaveNumSeq( paramList, numWaves [ convert2list ] )
	String paramList
	Variable numWaves
	Variable convert2list // convert sequence (e.g. "1-3") to list (e.g. "1;2;3;")
	
	Variable icnt, jcnt, value, delta = 0
	String seqStr, seqStr2, istr, valueStr, deltaStr = ""
	
	paramList = ReplaceString( " ", paramList, "" )
	paramList = ReplaceString( ",delta,", paramList, ",delta=" )

	valueStr = StringByKey( "wave", paramList, "=", ";" )
	deltaStr = StringByKey( "delta", valueStr, "=", "," )
	
	if ( strlen( deltaStr ) > 0 )
		
		delta = round( str2num( deltaStr ) )
		
		if ( ( numtype( delta ) > 0 ) || ( delta < 0 ) )
			delta = 0 // bad delta
		endif
		
		icnt = strsearch( valueStr, ",delta", 0 )
		
		if ( icnt > 0 )
			valueStr = valueStr[ 0, icnt - 1 ]
		endif
	
	endif
	
	if ( !convert2list )
		return valueStr
	endif
	
	if ( strsearch( valueStr, "all", 0 ) >= 0 )
	
		valueStr = "0-" + num2istr( numWaves - 1 )
		seqStr = RangeToSequenceStr( valueStr )
		
	else
	
		seqStr = ""
	
		for ( icnt = 0 ; icnt < ItemsInList( valueStr, "," ); icnt += 1 )
		
			istr = StringFromList( icnt, valueStr, "," )
			istr = RangeToSequenceStr( istr )
			
			
			if ( strlen( istr ) > 0 )
				seqStr += istr + ";"
			endif
			
		endfor
		
		seqStr = ReplaceString( ";;", seqStr, ";" )
		
	endif
	
	if ( delta > 1 )
	
		seqStr2 = ""
		
		if ( ItemsInlist( seqStr ) == 1 )
		
			jcnt = str2num( StringFromList( 0, seqStr ) )
		
			for ( icnt = jcnt ; icnt < numWaves ; icnt += delta )
				seqStr2 += num2istr( icnt ) + ";"
			endfor
		
		elseif ( ItemsInlist( seqStr ) > 1 )
		
			for ( icnt = 0 ; icnt < ItemsInlist( seqStr ) ; icnt += delta )
				seqStr2 += StringFromList( icnt, seqStr ) + ";"
			endfor
		
		endif
		
		return seqStr2
	
	endif
	
	return seqStr

End // NMPulseWaveNumSeq

//****************************************************************
//****************************************************************

Function NMPulseWaveDelta( paramList )
	String paramList

	String valueStr = StringByKey( "wave", paramList, "=" )
	String deltaStr = StringByKey( "delta", valueStr, "=", "," )
		
	if ( strlen( deltaStr ) > 0 )
		return round( str2num( deltaStr ) )
	endif
	
	return 0

End // NMPulseWaveDelta

//****************************************************************
//****************************************************************

Static Function zPulseTTL( x1, x2, amp )
	Variable x1, x2, amp
	
	Variable tolerance = 0.00001
	
	if ( numtype( amp ) > 0 )
		amp = 5
	endif
	
	if ( ( x1 >= amp - tolerance ) || ( x2 >= amp - tolerance ) )
		return amp
	else
		return 0
	endif
	
End // zPulseTTL

//****************************************************************
//****************************************************************
//
//		Pulse Config Wave Functions
//		text waves where pulse configs are saved
//
//****************************************************************
//****************************************************************

Function /S PulseWaveName( df, wPrefix )
	String df // data folder
	String wPrefix // wave prefix
	
	return df + wPrefix + "_pulse"
	
End // PulseWaveName

//****************************************************************
//****************************************************************

Function NMPulseConfigWaveSave( wName, paramList [ configNum ] )
	String wName // full-path wave name
	String paramList
	Variable configNum // pulse number
	
	Variable icnt, xpnts, foundEmpty
	String parentFolder
	
	if ( WaveExists( $wName ) && ( WaveType( $wName, 1 ) != 2 ) )
		return NM2Error( 1, "wName", wName )
	endif

	if ( !WaveExists( $wName ) )
	
		parentFolder = NMParent( wName )
	
		if ( DataFolderExists( parentFolder ) )
			Make /N=( configNum + 1 )/T $wName
		else
			return NM2Error( 30, "parentFolder", parentFolder )
		endif
		
	endif
	
	Wave /T pulses = $wName
	
	if ( !ParamIsDefault( configNum ) )
	
		if ( ( numtype( configNum ) == 0 ) && ( configNum >= 0 ) && ( configNum < numpnts( pulses ) ) )
			pulses[ configNum ] = paramList
			return 0
		else
			return NM2Error( 10, "configNum", num2str( configNum ) )
		endif
	
	endif
	
	for ( icnt = 0 ; icnt < numpnts( pulses ) ; icnt += 1 )
	
		if ( strlen( pulses[ icnt ] ) == 0 )
			foundEmpty = 1
			break
		endif
	
	endfor
	
	if ( !foundEmpty )
	
		xpnts = numpnts( pulses ) + 5
		
		Redimension /N=( xpnts ) pulses
		
		for ( icnt = 0 ; icnt < numpnts( pulses ) ; icnt += 1 )
		
			if ( strlen( pulses[ icnt ] ) == 0 )
				foundEmpty = 1
				break
			endif
		
		endfor
		
	endif
	
	if ( foundEmpty )
		pulses[ icnt ] = paramList
	endif
	
	return 0
	
End // NMPulseConfigWaveSave

//****************************************************************
//****************************************************************

Function NMPulseConfigWaveRemove( wName [ configNum, all, off ] )
	String wName // full-path wave name
	Variable configNum // pulse config number
	Variable all // all configs
	Variable off // ( 0 ) turn on config ( 1 ) turn off config
	
	Variable icnt, xpnts
	
	if ( !WaveExists( $wName ) || ( WaveType( $wName, 1 ) != 2 ) )
		return NM2Error( 1, "wName", wName )
	endif
	
	if ( ParamIsDefault( configNum ) )
	
		configNum = -1
	
		if ( !all )
			return NM2Error( 10, "configNum", num2str( configNum ) )
		endif
	
	else
	
		if ( ( numtype( configNum ) > 0 ) || ( configNum < 0 ) || ( configNum >= numpnts( $wName ) ) )
			return NM2Error( 10, "configNum", num2str( configNum ) )
		endif
	
	endif
	
	if ( ParamIsDefault( off ) )
		off = -1
	endif
	
	Wave /T pulses = $wName
	
	xpnts = numpnts( pulses )
	
	if ( xpnts == 0 )
		return 0
	endif
	
	if ( off == 1 ) // turn off
	
		if ( all )
		
			for ( icnt = 0 ; icnt <  xpnts ; icnt += 1 )
				pulses[ icnt ] = "off=1;" + pulses[ icnt ]
			endfor
		
		elseif ( ( configNum >= 0 ) && ( configNum <  xpnts ) )
		
			pulses[ configNum ] = "off=1;" + pulses[ configNum ]
			
		endif
		
	elseif ( off == 0 ) // turn on
	
		if ( all )
		
			for ( icnt = 0 ; icnt <  xpnts ; icnt += 1 )
				pulses[ icnt ] = ReplaceString( "off=1;", pulses[ icnt ], "" )
			endfor
		
		elseif ( ( configNum >= 0 ) && ( configNum <  xpnts ) )
		
			pulses[ configNum ] = ReplaceString( "off=1;", pulses[ configNum ], "" )
			
		endif
		
	else // delete
	
		if ( all )
			Redimension /N=0 pulses
		elseif ( ( configNum >= 0 ) && ( configNum <  xpnts ) )
			DeletePoints configNum, 1, pulses
		endif
	
	endif
	
	return 0

End // NMPulseConfigWaveRemove

//****************************************************************
//****************************************************************

Function NMPulseConfigWaveUpdate( df, wNameOld, wNameNew [ TTL ] )
	String df
	String wNameOld
	String wNameNew
	Variable TTL
	
	Variable numPulses, pcnt
	Variable shapeNum, waveNum, waveNumD, onset, onsetD, amp, ampD, width, widthD, tau2, tau2D
	String pulseStr
	
	STRUCT NMPulseEntryOld p
	
	if ( !WaveExists( $df+wNameOld ) || ( WaveType( $df+wNameOld, 1 ) != 1 ) )
		return 0
	endif
	
	Wave wtemp = $df+wNameOld
	
	if ( numpnts( wtemp ) == 0 )
		return 0
	endif
	
	WaveStats /Q wtemp
	
	if ( V_npnts == 0 )
		return 0
	endif
	
	numPulses = abs( V_Min ) + 1
	
	if ( numPulses < 1 )
		return 0
	endif
	
	Make /N=( numPulses )/O/T $df+wNameNew = ""
	
	Wave /T ttemp = $df+wNameNew
	
	for ( pcnt = 0; pcnt < numPulses; pcnt += 1 )
	
		if ( pcnt * NMPulseGenEntries + 11 >= numpnts( wtemp ) )
			break
		endif
	
		p.shapeNum = wtemp[ pcnt * NMPulseGenEntries + 1 ]
		p.waveNum = wtemp[ pcnt * NMPulseGenEntries + 2 ]
		p.waveNumD = wtemp[ pcnt * NMPulseGenEntries + 3 ]
		p.onset = wtemp[ pcnt * NMPulseGenEntries + 4 ]
		p.onsetD = wtemp[ pcnt * NMPulseGenEntries + 5 ]
		p.amp = wtemp[ pcnt * NMPulseGenEntries + 6 ]
		p.ampD = wtemp[ pcnt * NMPulseGenEntries + 7 ]
		p.width = wtemp[ pcnt * NMPulseGenEntries + 8 ]
		p.widthD = wtemp[ pcnt * NMPulseGenEntries + 9 ]
		p.tau2 = wtemp[ pcnt * NMPulseGenEntries + 10 ]
		p.tau2D = wtemp[ pcnt * NMPulseGenEntries + 11 ]
		
		ttemp[ pcnt ] = NMPulseNewParamList( p, df, TTL=TTL )
	
	endfor
	
End // NMPulseConfigWaveUpdate

//****************************************************************
//****************************************************************

Function /S NMPulseNewParamList( p, df [ TTL ] )
	STRUCT NMPulseEntryOld &p
	String df
	Variable TTL
	
	String pulseStr, aowList, paramList = ""
	
	String shapeStr = PulseShape( df, p.shapeNum )
	
	if ( ( p.waveNum == 0 ) && ( p.waveNumD == 1 ) )
		pulseStr = "wave=all;"
	else
		pulseStr = NMPulseParamList( "wave", p.waveNum, delta = p.waveNumD )
	endif
	
	STRUCT NMPulseAOW aow
			
	aow.amp = p.amp
	aow.ampD = p.ampD
	aow.onset = p.onset
	aow.onsetD = p.onsetD
	aow.width = p.width
	aow.widthD = p.widthD
	
	if ( StringMatch( shapeStr, "ramp" ) &&  ( p.width < 0 ) )
		shapeStr = "-ramp"
	endif
	
	aowList = NMPulseAOWparamList( aow, DSC = "delta" )
	
	strswitch( shapeStr )
	
		case "square":
		case "ramp":
			break
			
		case "alpha":
		
			STRUCT NMPulseAlpha aa
			
			aa.tau = p.width
			aa.tauD = p.widthD
		
			paramList = NMPulseAlphaParamList( aa, DSC = "delta" )
			
			break
			
		case "exp":
		
			STRUCT NMPulseExp ex
			
			ex.amp1 = -1
			ex.amp1D = 0
			ex.tau1 = p.width
			ex.tau1D = p.widthD
			ex.amp2 = 1
			ex.amp2D = 0
			ex.tau2 = p.tau2
			ex.tau2D = p.tau2D
			
			paramList = NMPulseExpParamList( ex, DSC = "delta" )
			
			break
			
		case "sin":
		case "sine":
		
			STRUCT NMPulseSin sn
			
			sn.period = p.tau2
			sn.periodD = p.tau2D
			
			paramList = NMPulseSinParamList( sn, DSC = "delta" )
			
			break
			
		case "cos":
		case "cosine":
		
			STRUCT NMPulseSin cs
			
			cs.cosine = 1
			cs.period = p.tau2
			cs.periodD = p.tau2D
			
			paramList = NMPulseSinParamList( cs, DSC = "delta" )
			
			break
			
		default:
		
			if ( !WaveExists( $df + shapeStr ) )
				return "" // unknown pulse config
			endif
	
	endswitch
	
	if ( TTL )
		shapeStr = "squareTTL"
	endif
	
	return pulseStr + "pulse=" + shapeStr + ";" + aowList + paramList
		
End // NMPulseNewParamList

//****************************************************************
//****************************************************************
//
//	Prompt Functions
//
//****************************************************************
//****************************************************************

Static Function /S zPromptStr( varName [ DSC, ampUnits, timeUnits ] )
	String varName
	String DSC // "delta" or "stdv" or "cv"
	String ampUnits // "pA"
	String timeUnits // "ms"
	
	if ( ParamIsDefault( DSC ) )
		DSC = ""
	endif
	
	if ( ParamIsDefault( ampUnits ) || ( strlen( ampUnits ) == 0 ) )
		ampUnits = ""
	else
		ampUnits = " (" + ampUnits + ")"
	endif
	
	if ( ParamIsDefault( timeUnits ) || ( strlen( timeUnits ) == 0 ) )
		timeUnits = ""
	else
		timeUnits = " (" + timeUnits + ")"
	endif

	strswitch( varName )
	
		case "amp":
		
			strswitch( DSC )
				case "delta":
					return "peak amplitude delta" + ampUnits + ":"
				case "stdv":
					return "peak amplitude stdv" + ampUnits + ":"
				case "cv":
					return "peak amplitude cv" + ampUnits + ":"
				default:
					return "peak amplitude" + ampUnits + ":"
			endswitch
			
		case "amp1":
		case "amp2":
		case "amp3":
		
			strswitch( DSC )
				case "delta":
					return varName + " delta:"
				case "stdv":
					return varName + " stdv:"
				case "cv":
					return varName + " cv:"
				default:
					return varName + " (%):"
			endswitch
	
		case "width":
		case "onset":
		case "tau":
		case "tau1":
		case "tau2":
		case "tau3":
		case "tau4":
		case "tauRise":
		case "tauDecay":
		case "period":
		case "begin period":
		case "end period":
		case "center":
		case "stdv":
		
			strswitch( DSC )
				case "delta":
					return varName + " delta" + timeUnits + ":"
				case "stdv":
					return varName + " stdv" + timeUnits + ":"
				case "cv":
					return varName + " cv" + timeUnits + ":"
				default:
					return varName + timeUnits + ":"
			endswitch
	
	endswitch

	return ""

End // zPromptStr

//****************************************************************
//****************************************************************

Function /S NMPulsePrompt( [ df, pdf, numWaves, timeLimit, paramList, TTL, configNum, titleEnding, binom, plasticity, DSC, ampUnits, timeUnits ] )
	String df // data folder
	String pdf // prompt data folder ( where prompt variables are saved )
	Variable numWaves // total number of possible waves
	Variable timeLimit // for random train
	String paramList
	Variable TTL // ( 0 ) no ( 1 ) yes
	Variable configNum
	String titleEnding
	Variable binom // prompt for binomial pulse
	Variable plasticity // prompt for plasticity train
	String DSC // "delta" or "stdv" or "cv"
	String ampUnits // "pA"
	String timeUnits // "ms"
	
	Variable waveNum, waveDelta, newPulse, train, pulseType
	Variable binomYN, binomialN, binomialP, trainRP, trainDF, trainDittman
	String title, paramList1, paramList2, paramList3 = "", binomList = ""
	String shape, waveNumStr, trainParamList, trainType = ""
	
	STRUCT NMPulseTrainRP tRP
	STRUCT NMPulseTrainDF tDF
	STRUCT NMPulseTrainDittman tDittman
	
	if ( ParamIsDefault( df ) )
		df = ""
	endif
	
	if ( ParamIsDefault( pdf ) )
		pdf = NMPulseDF
	endif
	
	if ( ParamIsDefault( paramList ) )
		paramList = ""
	endif
	
	if ( ParamIsDefault( configNum ) )
		configNum = -1
	endif
	
	if ( ParamIsDefault( titleEnding ) )
		titleEnding = ""
	endif
	
	if ( ParamIsDefault( DSC ) )
		DSC = ""
	endif
	
	if ( ParamIsDefault( ampUnits ) )
		ampUnits = ""
	endif
	
	if ( ParamIsDefault( timeUnits ) )
		timeUnits = ""
	endif
	
	if ( strlen( paramList ) == 0 )
		title = "New Pulse Config"
		newPulse = 1
	else
		title = "Edit Pulse Config"
	endif
	
	if ( ( numtype( configNum ) == 0 ) && ( configNum >= 0 ) )
		title += " #" + num2istr( configNum )
	endif
	
	if ( strlen( titleEnding ) > 0 )
		title += " : " + titleEnding
	endif
	
	if ( TTL )
		binom = 0
		plasticity = 0
	endif
	
	if ( newPulse )
	
		pulseType = NumVarOrDefault( pdf + promptPrefix + "Type", 1 )
		binomYN = 1 + NumVarOrDefault( pdf + promptPrefix + "Binomial", 0 )
	
		Prompt pulseType, "add:", popup "single pulse;fixed-interval pulse train;random-interval pulse train;user-defined pulse train;"
		Prompt binomYN, "make binomial ( N * P ):", popup "no;yes;"
		
		if ( binom )
		
			DoPrompt title, pulseType, binomYN
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
			binomYN -= 1
			
			SetNMvar( pdf + promptPrefix + "Type", pulseType )
			SetNMvar( pdf + promptPrefix + "Binomial", binomYN )
		
		else
		
			DoPrompt title, pulseType
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
			SetNMvar( pdf + promptPrefix + "Type", pulseType )
			
			binomYN = 0
			
		endif
		
		if ( pulseType > 1 )
			title = ReplaceString( "Pulse Config", title, "Pulse Train Config" )
		endif
		
	else
	
		trainType = StringByKey( "train", paramList, "=" )
		
		if ( strlen( trainType ) == 0 )
			pulseType = 1
		elseif ( StringMatch( trainType, "Fixed" ) )
			pulseType = 2
		//elseif ( StringMatch( trainType[ 0, 5 ], "Random" ) )
		//	pulseType = 3
		elseif ( WaveExists( $df + trainType ) )
			pulseType = 4
		else
			pulseType = 1
		endif
		
		if ( strlen( StringByKey( "binomialN", paramList, "=" ) ) > 0 )
			binomYN = 1
		endif
		
	endif
	
	if ( 0 )
		print NMPulsePromptWaveSeq( df, pdf, numWaves, paramList, title, pulseType )
		return ""
	endif
	
	if ( binomYN )
		paramList1 = NMPulsePromptWaveAndShape( df, pdf, -1, paramList, title, TTL, pulseType, plasticity = plasticity )
	else
		paramList1 = NMPulsePromptWaveAndShape( df, pdf, numWaves, paramList, title, TTL, pulseType, plasticity = plasticity )
	endif
	
	if ( strlen( paramList1 ) == 0 )
		return "" // cancel
	endif
	
	shape = StringByKey( "pulse", paramList1, "=" )
	waveNumStr = StringByKey( "wave", paramList1, "=" )
	waveDelta = NMPulseWaveDelta( paramList1 )
	
	trainRP = NMPulseTrainRPexists( paramList1 )
	trainDF = NMPulseTrainDFexists( paramList1 )
	trainDittman = NMPulseTrainDittmanExists( paramList1 )
	
	if ( trainRP )
		NMPulseTrainRPinit( tRP, pdf = pdf, paramList = paramList1 )
		paramList3 = NMPulseTrainRPparamList( tRP )
	elseif ( trainDF )
		NMPulseTrainDFinit( tDF, pdf = pdf, paramList = paramList1 )
		paramList3 = NMPulseTrainDFparamList( tDF )
	elseif ( trainDittman )
		NMPulseTrainDittmanInit( tDittman, pdf = pdf, paramList = paramList1 )
		paramList3 = NMPulseTrainDittmanParamList( tDittman )
	endif
	
	STRUCT NMPulseTrain t
	
	switch( pulseType )
		
		case 2: // fixed-interval train
			
			NMPulseTrainInit( t, pdf = pdf, paramList = paramList )
		
			trainParamList = NMPulsePromptTrainFixed( pdf = pdf, t = t )
			train = 1
			
			if ( strlen( trainParamList ) == 0 )
				return "" // cancel
			endif
	
			break
			
		case 3: // random-interval train
		
			NMPulseTrainInit( t, pdf = pdf, paramList = paramList )
		
			trainParamList = NMPulsePromptTrainRandom( df, pdf = pdf, timeLimit = timeLimit, t = t )
			train = 1
			
			if ( strlen( trainParamList ) == 0 )
				return "" // cancel
			endif
			
			break
			
		case 4: // user-defined train
		
			trainParamList = NMPulsePromptTrainUser( df, paramList )
			train = 1
			
			if ( strlen( trainParamList ) == 0 )
				return "" // cancel
			endif
			
			break
			
		default:
		
			trainParamList = ""
	
	endswitch
	
	if ( StringMatch( DSC, "delta" ) && ( waveDelta == 0 ) )
		DSC = ""
	endif
	
	paramList2 = NMPulsePromptPulseParams( shape, df = df, pdf = pdf, paramList = paramList, DSC = DSC, ampUnits = ampUnits, timeUnits = timeUnits, TTL = TTL, train = train )
	
	if ( strlen( paramList2 ) == 0 )
		return "" // cancel
	endif
	
	if ( binomYN )
	
		binomialN = NumVarOrDefault( pdf + promptPrefix + "BinomialN", 10 )
		binomialP = NumVarOrDefault( pdf + promptPrefix + "BinomialP", 0.5 )
		
		binomialN = NMPulseNumByKey( "binomialN", paramList, binomialN, positive = 1 )
		binomialP = NMPulseNumByKey( "binomialP", paramList, binomialP, positive = 1 )
		
		Prompt binomialN, "binomial N:"
		Prompt binomialP, "binomial P:"
	
		if ( trainDF )
		
			NMDoAlert( "Alert: binomial N*P does not work for D*F plasticity train. You can use R*P plasticity model instead.", title = title )
			binomYN = 0
			
		elseif ( trainRP )
		
			DoPrompt title, binomialN
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
			binomialN = round( binomialN )
			
			SetNMvar( pdf + promptPrefix + "BinomialN", binomialN )
			
			binomList = "binomialN=" + num2istr( binomialN ) + ";"
			
		else
		
			DoPrompt title, binomialN, binomialP
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
			binomialN = round( binomialN )
			
			SetNMvar( pdf + promptPrefix + "BinomialN", binomialN )
			SetNMvar( pdf + promptPrefix + "BinomialP", binomialP )
			
			binomList = "binomialN=" + num2istr( binomialN ) + ";binomialP=" + num2str( binomialP ) + ";"
		
		endif
	
	endif
	
	return "wave=" + waveNumStr + ";" + trainParamList + paramList2 + paramList3 + binomList
	
End // NMPulsePrompt

//****************************************************************
//****************************************************************

Function /S NMPulsePromptWaveSeq( df, pdf, numWaves, paramList, title, pulseType )
	String df
	String pdf
	Variable numWaves
	String paramList
	String title
	Variable pulseType
	
	Variable icnt, wnum, delta
	String waveNumStr = "", waveNumSeq = "", deltaStr = ""
	String wNumList = " ", deltaList = " "
	
	if ( numWaves == 1 )
		return "wave=0;"
	endif
	
	if ( strlen( paramList ) > 0 )
		waveNumSeq = NMPulseWaveNumSeq( paramList, numWaves )
		delta = NMPulseWaveDelta( paramList )
	endif
	
	for ( icnt = 0; icnt < numWaves; icnt += 1 )
		wNumList = AddListItem( num2istr( icnt ), wNumList, ";", inf ) // list of wave #s
	endfor
	
	if ( numWaves > 1 )
		wNumList += "all;"
	endif
	
	for ( icnt = 2; icnt < numWaves; icnt += 1 )
		deltaList = AddListItem( num2istr( icnt ), deltaList, ";", inf ) // list of wave #s
	endfor
	
	if ( strlen( waveNumSeq ) > 0 ) // existing sequence
		
		if ( ( strsearch( waveNumSeq, "-", 0 ) >= 0 ) || ( strsearch( waveNumSeq, ",", 0 ) >= 0 ) )
		
			waveNumStr = " "
		
		else
		
			wnum = str2num( waveNumSeq )
			
			if ( ( numtype( wnum ) == 0 ) && ( wnum >= 0 ) && ( wnum < numWaves ) )
				waveNumStr = num2istr( wnum )
			else
				waveNumStr = "all"
			endif
			
			waveNumSeq = ""
		
		endif
	
	else
		
		waveNumStr = "all"
		
	endif
	
	if ( ( numtype( delta ) == 0 ) && ( delta >= 1 ) && ( delta < numWaves ) )
		deltaStr = num2istr( delta )
	else
		deltaStr = " "
	endif
	
	if ( pulseType > 1 )
		Prompt waveNumStr, "add pulse train to output wave:", popup wNumList
	else
		Prompt waveNumStr, "add pulse to output wave:", popup wNumList
	endif
	
	Prompt waveNumSeq, "or enter a comma-delimited sequence (e.g. 1-5,7,9):"
	Prompt deltaStr, "add optional wave increment:", popup deltaList
		
	DoPrompt title, waveNumStr, waveNumSeq, deltaStr
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( strlen( waveNumSeq ) > 0 )
	
		waveNumStr = NMPulseWaveNumSeq( "wave=" + waveNumSeq, numWaves, convert2list = 1 )
		
		if ( ItemsInList( waveNumStr ) > 0 )
			waveNumStr = waveNumSeq
		else
			return "" // cancel // bad sequence
		endif
		
	endif
	
	if ( StringMatch( deltaStr, " " ) )
		return "wave=" + waveNumStr + ";"
	else
		return "wave=" + waveNumStr + ",delta=" + deltaStr + ";"
	endif
	
End // NMPulsePromptWaveSeq

//****************************************************************
//****************************************************************

Function /S NMPulsePromptWaveAndShape( df, pdf, numWaves, paramList, title, TTL, pulseType [ plasticity ] )
	String df
	String pdf
	Variable numWaves
	String paramList
	String title
	Variable TTL
	Variable pulseType
	Variable plasticity
	
	Variable icnt, waveNum = 0, delta
	String shape, plasticityModel, waveNumStr, waveNumSeq = ""
	String paramList2 = "", wNumList = " ", wNumList2 = " ", otherWave = ""
	
	if ( strlen( paramList ) > 0 )
	
		shape = StringByKey( "pulse", paramList, "=" )
		
		if ( WhichListItem( shape, NMPulseList, ";", 0, 0 ) == -1 )
		
			if ( WaveExists( $df+shape ) )
				otherWave = shape
				shape = "other"
			else
				shape = "square"
			endif
			
		endif
		
		waveNumSeq = NMPulseWaveNumSeq( paramList, numWaves )
		delta = NMPulseWaveDelta( paramList )
		
	else
	
		waveNum = NumVarOrDefault( pdf + promptPrefix + "WaveN", -1 )
		delta = NumVarOrDefault( pdf + promptPrefix + "WaveND", 0 )
		shape = StrVarOrDefault( pdf + promptPrefix + "Shape", "square" )
	
	endif
	
	plasticityModel = StrVarOrDefault( pdf + promptPrefix + "Plasticity", "none" )
	
	for ( icnt = 0; icnt < numWaves; icnt += 1 )
		wNumList = AddListItem( num2istr( icnt ), wNumList, ";", inf ) // list of wave #s
	endfor
	
	if ( numWaves > 1 )
		wNumList += "all;"
	endif
	
	for ( icnt = 1; icnt < numWaves; icnt += 1 )
		wNumList2 = AddListItem( num2istr( icnt ), wNumList2, ";", inf ) // list of wave #s
	endfor
	
	if ( numWaves == 1 )
	
		waveNumStr = "0"
		delta = 0
	
	elseif ( strlen( waveNumSeq ) > 0 ) // existing sequence
		
		if ( ( strsearch( waveNumSeq, "-", 0 ) >= 0 ) || ( strsearch( waveNumSeq, ",", 0 ) >= 0 ) )
		
			waveNumStr = " "
		
		else
		
			waveNum = str2num( waveNumSeq )
			
			if ( ( waveNum >= 0 ) && ( waveNum < numWaves ) )
				waveNumStr = num2istr( waveNum )
			else
				waveNumStr = "all"
			endif
			
			waveNumSeq = ""
		
		endif
	
	else
		
		waveNumStr = "all"
		
	endif
	
	if ( pulseType > 1 )
		Prompt waveNumStr, "add pulse train to output wave:", popup wNumList
	else
		Prompt waveNumStr, "add pulse to output wave:", popup wNumList
		plasticity = 0 // not a pulse train
	endif
	
	Prompt waveNumSeq, "or enter a comma-delimited sequence (e.g. 1-5,7,9):"
	Prompt delta, "add optional wave increment:", popup wNumList2
	
	Prompt shape, "pulse shape:", popup RemoveFromList( "squareTTL", NMPulseList )
	Prompt plasticityModel, "train plasticity:", popup "none;" + NMPulsePlasticityList
	
	if ( TTL )
	
		shape = "squareTTL"
	
		if ( numWaves > 1 )
			DoPrompt title, waveNumStr
		endif
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
	
	else
	
		if ( plasticity )
		
			if ( numWaves == 1 )
				DoPrompt title, shape, plasticityModel
			else
				DoPrompt title, waveNumStr, shape, plasticityModel
			endif
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
			SetNMstr( pdf + promptPrefix + "Plasticity", plasticityModel )
			
			strswitch( plasticityModel )
			
				case "R*P model":
				
					STRUCT NMPulseTrainRP rp
				
					NMPulseTrainRPinit( rp, pdf = pdf, paramList = paramList )
				
					paramList2 = NMPulsePromptTrainRP( pdf = pdf, p = rp )
					
					if ( strlen( paramList2 ) == 0 )
						return "" // cancel
					endif
				
					break
					
				case "D*F model":
				
					STRUCT NMPulseTrainDF fd
				
					NMPulseTrainDFinit( fd, pdf = pdf, paramList = paramList )
				
					paramList2 = NMPulsePromptTrainDF( pdf = pdf, p = fd )
					
					if ( strlen( paramList2 ) == 0 )
						return "" // cancel
					endif
				
					break
			
				case "Dittman model":
				
					STRUCT NMPulseTrainDittman dn
				
					NMPulseTrainDittmanInit( dn, pdf = pdf, paramList = paramList )
				
					paramList2 = NMPulsePromptTrainDittman( pdf = pdf, p = dn )
					
					if ( strlen( paramList2 ) == 0 )
						return "" // cancel
					endif
					
					break
					
			endswitch
		
		else
		
			if ( numWaves > 1 )
			
				DoPrompt title, waveNumStr, waveNumSeq, delta
				
				if ( V_flag == 1 )
					return "" // cancel
				endif
				
			endif
			
			DoPrompt title, shape
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
		
		endif
		
		SetNMstr( pdf + promptPrefix + "Shape", shape )
	
	endif
	
	if ( StringMatch( waveNumStr, " " ) )
	
	elseif ( StringMatch( waveNumStr, "all" ) )
		waveNum = 0
		delta = 1
		waveNumStr = "wave=all;"
		SetNMvar( pdf + promptPrefix + "WaveN", -1 )
	else
		delta = 0
		waveNum = str2num( waveNumStr )
		waveNumStr = NMPulseParamList( "wave", waveNum )
		SetNMvar( pdf + promptPrefix + "WaveN", waveNum )
	endif
	
	SetNMvar( pdf + promptPrefix + "WaveND", delta )
	
	if ( StringMatch( shape, "other" ) && ( strlen( otherWave ) > 0 ) )
		shape = otherWave
	endif
	
	return waveNumStr + "pulse=" + shape + ";" + paramList2

End // NMPulsePromptWaveAndShape

//****************************************************************
//****************************************************************

Function /S NMPulsePromptTrainRP( [ pdf, p ] )
	String pdf
	STRUCT NMPulseTrainRP &p
	
	STRUCT NMPulseTrainRP pp
	
	Variable Rinf, Rmin, tauR, Pinf, Pmax, tauP, Pscale
	String title = "Pulse Train Plasticity R * P Model"
	
	if ( ParamIsDefault( pdf ) )
		pdf = NMPulseDF
	endif
	
	if ( ParamIsDefault( p ) )
		NMPulseTrainRPinit( pp, pdf = pdf )
	else
		pp = p
	endif
	
	Rinf = pp.Rinf
	Rmin = pp.Rmin
	tauR = pp.tauR
	Pinf = pp.Pinf
	Pmax = pp.Pmax
	tauP = pp.tauP
	Pscale = pp.Pscale
	
	Prompt Rinf, "steady-state R value ( 0 < Rinf <= 1 ):"
	Prompt Rmin, "minimum allowed R value ( 0 < Rmin <= 1 ):"
	Prompt tauR, "recovery time constant of R ( tauR ):"
	
	Prompt Pinf, "steady-state P value ( 0 < Pinf <= 1 ):"
	Prompt Pmax, "maximum allowed P value ( Pmax > 1 ):"
	Prompt tauP, "recovery time constant of P ( tauP ):"
	Prompt Pscale, "scale factor for P facilitation ( Pscale, 0 for none ):"
	
	DoPrompt title, Rinf, Rmin, tauR
		
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	pp.Rinf = Rinf
	pp.Rmin = Rmin
	pp.tauR = tauR
	
	DoPrompt title, Pinf, Pmax, Pscale
		
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	pp.Pinf = Pinf
	pp.Pmax = Pmax
	pp.Pscale = Pscale
	
	if ( Pscale != 0 )
	
		DoPrompt title, tauP
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		pp.tauP = tauP
		
	else
	
		pp.tauP = -1
	
	endif
	
	if ( !ParamIsDefault( p ) )
		p = pp
	endif
	
	NMPulseTrainRPsave( pp, pdf )
	
	return NMPulseTrainRPparamList( pp )
	
End // NMPulsePromptTrainRP

//****************************************************************
//****************************************************************

Function /S NMPulsePromptTrainDF( [ pdf, p ] )
	String pdf
	STRUCT NMPulseTrainDF &p
	
	STRUCT NMPulseTrainDF pp
	
	Variable Dinf, Dmin, tauD, Dscale, Finf, Fmax, tauF, Fscale
	String title = "Pulse Train Plasticity D * F Model"
	
	if ( ParamIsDefault( pdf ) )
		pdf = NMPulseDF
	endif
	
	if ( ParamIsDefault( p ) )
		NMPulseTrainDFinit( pp, pdf = pdf )
	else
		pp = p
	endif
	
	Dinf = pp.Dinf
	Dmin = pp.Dmin
	tauD = pp.tauD
	Dscale = pp.Dscale
	
	Finf = pp.Finf
	Fmax = pp.Fmax
	tauF = pp.tauF
	Fscale = pp.Fscale
	
	Prompt Dinf, "steady-state D value ( 0 < Dinf <= 1 ):"
	Prompt Dmin, "minimum allowed D value ( 0 < Dmin <= 1 ):"
	Prompt tauD, "recovery time constant of D ( tauD ):"
	Prompt Dscale, "D scale factor ( 0 < Dscale <= 1, enter 1 for none ):"
	
	Prompt Finf, "steady-state F value ( 0 < Finf <= 1 ):"
	Prompt Fmax, "maximum allowed F value ( Fmax > 1 ):"
	Prompt tauF, "recovery time constant of F ( tauF ):"
	Prompt Fscale, "F scale factor ( Fscale >= 1, enter 1 for none ):"
	
	DoPrompt title, Dinf, Dmin, Dscale, tauD
		
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	pp.Dinf = Dinf
	pp.Dmin = Dmin
	pp.Dscale = Dscale
	pp.tauD = tauD
	
	DoPrompt title, Finf, Fmax, Fscale, tauF
		
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	pp.Finf = Finf
	pp.Fmax = Fmax
	pp.Fscale = Fscale
	pp.tauF = tauF
	
	if ( !ParamIsDefault( p ) )
		p = pp
	endif
	
	NMPulseTrainDFsave( pp, pdf )
	
	return NMPulseTrainDFparamList( pp )
	
End // NMPulsePromptTrainDF

//****************************************************************
//****************************************************************

Function /S NMPulsePromptTrainDittman( [ pdf, p ] )
	String pdf
	STRUCT NMPulseTrainDittman &p
	
	STRUCT NMPulseTrainDittman pp
	
	Variable tauD, K0, Kmax, KD, deltaD
	Variable tauF, F1, Fratio, KF, deltaF
	String model, vp
	
	Variable chooseModel = 1
	
	String title = "Pulse Train Plasticity D * F Dittman Model"
	String modelList = "Climbing Fiber;Parallel Fiber;Schaffer Collateral;"
	
	if ( ParamIsDefault( pdf ) )
		pdf = NMPulseDF
	endif
	
	if ( ParamIsDefault( p ) )
		NMPulseTrainDittmanInit( pp, pdf = pdf )
	else
		pp = p
	endif
	
	vp = promptPrefix + "Dittman"
	
	model = StrVarOrDefault( pdf + vp + "model", "Parallel Fiber" )
	
	tauD = pp.tauD
	K0 = pp.K0
	Kmax = pp.Kmax
	KD = pp.KD
	deltaD = pp.deltaD
	
	tauF = pp.tauF
	F1 = pp.F1
	Fratio = pp.Fratio
	KF = pp.KF
	deltaF = pp.deltaF
	
	Prompt tauD, "recovery time constant of D ( tauD ):"
	Prompt K0, "baseline recovery rate from refractory state ( K0 ):"
	Prompt Kmax, "maximum recovery rate from refractory state ( Kmax ):"
	Prompt KD, "affinity of CaXD for release site ( KD ):"
	Prompt deltaD, "increment of CaXD after stimulus ( deltaD ):"
	
	Prompt tauF, "recovery time constant of F ( tauF ):"
	Prompt F1, "initial probability of release ( F1 ):"
	Prompt Fratio, "facilitation ratio EPSC2/EPSC1 ( Fratio ):"
	Prompt KF, "affinity of CaXF for release site ( KF ):"
	Prompt deltaF, "increment of CaXF after stimulus ( deltaF ):"
	
	Prompt model, "plasticity model type:", popup modelList
	
	if ( chooseModel )
	
		DoPrompt title, model
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		SetNMstr( pdf + vp + "model", model )
		
		NMPulseTrainDittmanInit( pp, pdf = pdf, model = model )
		NMPulseTrainDittmanSave( pp, pdf )
	
	else
	
		DoPrompt title, tauD, K0, Kmax, KD, deltaD
			
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		pp.tauD = tauD
		pp.K0 = K0
		pp.Kmax = Kmax
		pp.KD = KD
		pp.deltaD = deltaD
		
		DoPrompt title,  tauF, F1, Fratio, deltaF
			
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		pp.tauF = tauF
		pp.F1 = F1
		pp.Fratio = Fratio
		pp.KF = KF
		pp.deltaF = deltaF
		
		if ( !ParamIsDefault( p ) )
			p = pp
		endif
		
		NMPulseTrainDittmanSave( pp, pdf )
	
	endif
	
	return NMPulseTrainDittmanParamList( pp )
	
End // NMPulsePromptTrainDittman

//****************************************************************
//****************************************************************

Function /S NMPulsePromptTrainFixed( [ pdf, t ] )
	String pdf
	STRUCT NMPulseTrain &t
	
	STRUCT NMPulseTrain tt
	
	Variable tbgn, tend, interval
	String train, title = "Fixed-Interval Pulse Train"
	
	if ( ParamIsDefault( pdf ) )
		pdf = NMPulseDF
	endif
	
	if ( ParamIsDefault( t ) )
		NMPulseTrainInit( tt, pdf = pdf )
	else
		tt = t
	endif
		
	tbgn = tt.tbgn
	tend = tt.tend
	interval = tt.interval
	
	Prompt tbgn, "train begin time (ms):"
	Prompt tend, "train end time (ms):"
	Prompt interval, "inter-pulse interval (ms):"
	
	DoPrompt title, tbgn, tend, interval
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	tt.type = "fixed"
	tt.tbgn = tbgn
	tt.tend = tend
	tt.interval = interval
	tt.refrac = 0
	
	if ( !ParamIsDefault( t ) )
		t = tt
	endif
	
	NMPulseTrainSave( tt, pdf )
	
	return NMPulseTrainParamList( tt, skipRefrac = 1 )
		
End // NMPulsePromptTrainFixed

//****************************************************************
//****************************************************************

Function /S NMPulsePromptTrainRandom( df [ pdf, timeLimit, t ] )
	String df
	String pdf
	Variable timeLimit
	STRUCT NMPulseTrain &t
	
	STRUCT NMPulseTrain tt
	
	Variable tbgn, tend, interval, refrac, numPulses, icnt
	String train, pstr, wName
	String title = "Random-Interval Pulse Train"
	
	if ( ParamIsDefault( pdf ) )
		pdf = NMPulseDF
	endif
	
	if ( ParamIsDefault( t ) )
		NMPulseTrainInit( tt, pdf = pdf )
	else
		tt = t
	endif
		
	tbgn = tt.tbgn
	tend = tt.tend
	interval = tt.interval
	refrac = tt.refrac
	
	if ( numtype( refrac ) > 0 )
		refrac = 0
	endif
	
	Prompt tbgn, "train begin time (ms):"
	Prompt tend, "train end time (ms):"
	Prompt interval, "mean inter-pulse interval (ms):"
	Prompt refrac, "refractory period (ms):"
	DoPrompt title, tbgn, tend, interval, refrac
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	tt.type = "random"
	tt.tbgn = tbgn
	tt.tend = tend
	tt.interval = interval
	tt.refrac = refrac
	
	if ( !ParamIsDefault( t ) )
		t = tt
	endif
	
	NMPulseTrainSave( tt, pdf )
	
	pstr = NMPulseTrainParamList( tt )
	
	for ( icnt = 0 ; icnt < 100 ; icnt += 1 )
	
		wName = "Random" + num2istr( icnt )
		
		if ( !WaveExists( $df + wName ) )
			break
		endif
		
	endfor
	
	Prompt wName, "enter unique wave name for random pulse times:"

	DoPrompt title, wName
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( WaveExists( $df + wName ) )
	
		DoAlert 1, "Wave " + NMQuotes( wName ) + "exists already. Do you want to overwrite it?"
		
		if ( V_flag == 2 )
			return "" // cancel
		endif
		
	endif
	
	numPulses = NMPulseTrainRandomTimes( df, wName, pstr, timeLimit )
	
	return "train=" + wName + ";"
		
End // NMPulsePromptTrainRandom

//****************************************************************
//****************************************************************

Function /S NMPulsePromptTrainUser( df, paramList )
	String df
	String paramList
	
	Variable icnt
	String trainType, wName, wList2 = ""
	
	String wList1 = NMFolderWaveList( df, "!*DAC*", ";", "TEXT:0", 0 )
	
	for ( icnt = 0 ; icnt < ItemsInList( wList1 ) ; icnt += 1 )
		
		wName = StringFromList( icnt, wList1 )
		
		if ( strsearch( wName, "TTL", 0 ) == -1 )
			wList2 = AddListItem( wName, wList2, ";", inf )
		endif
	
	endfor
	
	if ( ItemsInList( wList2 ) == 0 )
		DoAlert 0, "No user-defined waves detected in folder: " + df
		return ""
	endif
	
	wName = " "
	
	if ( strlen( paramList ) > 0 )
	
		trainType = StringByKey( "train", paramList, "=" )
		
		if ( WaveExists( $df + trainType ) )
			wName = trainType
		endif
		
	endif
	
	Prompt wName, "choose a user-defined wave containing your pulse times:", popup " ;" + wList2
	DoPrompt "User-Defined Pulse Train", wName

	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	return "train=" + wName + ";"
		
End // NMPulsePromptTrainUser

//****************************************************************
//****************************************************************

Function /S NMPulsePromptPulseParams( type [ df, pdf, paramList, DSC, ampUnits, timeUnits, TTL, train ] )
	String type
	String df, pdf
	String paramList
	String DSC // "delta" or "stdv" or "cv"
	String ampUnits // "pA"
	String timeUnits // "ms"
	Variable TTL
	Variable train
	
	Variable cosine
	String aowList, pList = ""
	
	STRUCT NMPulseAOW p
	
	if ( ParamIsDefault( df ) )
		df = ""
	endif
	
	if ( ParamIsDefault( pdf ) )
		pdf = NMPulseDF
	endif
	
	if ( ParamIsDefault( paramList ) )
		paramList = ""
	endif
	
	if ( ParamIsDefault( DSC ) )
		DSC = ""
	endif
	
	if ( ParamIsDefault( ampUnits ) )
		ampUnits = ""
	endif
	
	if ( ParamIsDefault( timeUnits ) )
		timeUnits = ""
	endif
			
	NMPulseAOWinit( p, pdf = pdf, type = type, paramList = paramList )
	
	if ( TTL )
		p.amp = 1 // 5 // NIDAQmx requires TTL = 0 or 1
		p.ampD = 0
		aowList = NMPulsePromptOW( pdf = pdf, type = "TTL", DSC = DSC, timeUnits = timeUnits, train = train, p = p )
	else
		aowList = NMPulsePromptAOW( pdf = pdf, type = type, DSC = DSC, ampUnits = ampUnits, timeUnits = timeUnits, train = train, p = p )
	endif
	
	if ( strlen( aowList ) == 0 )
		return "" // cancel
	endif

	strswitch( type )
	
		case "square":
		case "TTL":
		case "squareTTL":
		case "-ramp":
		case "+ramp":
			break
			
		case "alpha":
		
			STRUCT NMPulseAlpha aa
			
			NMPulseAlphaInit( aa, pdf = pdf, paramList = paramList )
			
			pList = NMPulsePromptAlpha( pdf = pdf, DSC = DSC, ampUnits = ampUnits, timeUnits = timeUnits, p = aa )
			
			if ( strlen( pList ) == 0 )
				return "" // cancel
			endif
			
			break
			
		case "gauss":
		
			STRUCT NMPulseGauss ga
			
			NMPulseGaussInit( ga, pdf = pdf, paramList = paramList )
			
			pList = NMPulsePromptGauss( pdf = pdf, DSC = DSC, ampUnits = ampUnits, timeUnits = timeUnits, p = ga )
			
			if ( strlen( pList ) == 0 )
				return "" // cancel
			endif
			
			break
			
		case "exp":
		
			STRUCT NMPulseExp ex
			
			NMPulseExpInit( ex, pdf = pdf, paramList = paramList )
			
			pList = NMPulsePromptExp( pdf = pdf, DSC = DSC, ampUnits = ampUnits, timeUnits = timeUnits, p = ex )
			
			if ( strlen( pList ) == 0 )
				return "" // cancel
			endif
			
			break
			
		case "synexp":
		case "synexp4":
		
			STRUCT NMPulseSynExp4 sx4
			
			NMPulseSynExp4Init( sx4, pdf = pdf, paramList = paramList )
			
			pList = NMPulsePromptSynExp4( pdf = pdf, DSC = DSC, ampUnits = ampUnits, timeUnits = timeUnits, p = sx4 )
			
			if ( strlen( pList ) == 0 )
				return "" // cancel
			endif
			
			break
		
		case "cos":
		
			cosine = 1
			
		case "sin":
		
			STRUCT NMPulseSin sc
			
			NMPulseSinInit( sc, pdf = pdf, paramList = paramList, cosine = cosine )
			
			pList = NMPulsePromptSin( pdf = pdf, cosine = cosine, DSC = DSC, ampUnits = ampUnits, timeUnits = timeUnits, p = sc )
			
			if ( strlen( pList ) == 0 )
				return "" // cancel
			endif
			
			break
			
		case "sinzap":
		
			STRUCT NMPulseSinZap sz
			
			NMPulseSinZapInit( sz, pdf = pdf, paramList = paramList )
			
			pList = NMPulsePromptSinZap( pdf = pdf, DSC = DSC, ampUnits = ampUnits, timeUnits = timeUnits, p = sz )
			
			if ( strlen( pList ) == 0 )
				return "" // cancel
			endif
			
			break
			
		default: // Other
			
			type = NMPulsePromptUserWave( df, type, pdf = pdf )
			
			if ( strlen( type ) == 0 )
				return "" // cancel
			endif
				
	endswitch
	
	return "pulse=" + type + ";" + aowList + pList
	
End // NMPulsePromptPulseParams

//****************************************************************
//****************************************************************

Function /S NMPulsePromptAOW( [ pdf, type, DSC, ampUnits, timeUnits, train, p ] )
	String pdf, type
	String DSC // "delta" or "stdv" or "cv"
	String ampUnits // "pA"
	String timeUnits // "ms"
	Variable train
	STRUCT NMPulseAOW &p
	
	STRUCT NMPulseAOW pp
	
	Variable amp, onset, width, skipOnset, skipWidth
	Variable ampD, onsetD, widthD, foundDSC
	String title = "Pulse Config"
	
	if ( ParamIsDefault( pdf ) )
		pdf = NMPulseDF
	endif
	
	if ( !ParamIsDefault( type ) )
		title += " : " + type
	endif
	
	if ( ParamIsDefault( DSC ) )
		DSC = ""
	endif
	
	if ( ParamIsDefault( ampUnits ) )
		ampUnits = ""
	endif
	
	if ( ParamIsDefault( timeUnits ) )
		timeUnits = ""
	endif
	
	if ( ParamIsDefault( p ) )
		NMPulseAOWinit( pp, pdf = pdf, type = type )
	else
		pp = p
	endif
	
	amp = pp.amp
	ampD = pp.ampD
	onset = pp.onset
	onsetD = pp.onsetD
	width = pp.width
	widthD = pp.widthD
	
	Prompt amp, zPromptStr( "amp", ampUnits = ampUnits )
	Prompt onset, zPromptStr( "onset", timeUnits = timeUnits )
	Prompt width, zPromptStr( "width", timeUnits = timeUnits )
	
	Prompt ampD, zPromptStr( "amp", DSC = DSC, ampUnits = ampUnits )
	Prompt onsetD, zPromptStr( "onset", DSC = DSC, timeUnits = timeUnits )
	Prompt widthD, zPromptStr( "width", DSC = DSC, timeUnits = timeUnits )
	
	foundDSC = zFoundDSC( DSC )
	
	if ( foundDSC )
		
		if ( train )
		
			onset = 0
		
			if ( StringMatch( DSC, "stdv" ) || StringMatch( DSC, "cv" ) )
			
				DoPrompt title, amp, ampD, onset, onsetD, width, widthD
			
				if ( V_flag == 1 )
					return "" // cancel
				endif
				
				if ( onsetD == 0 )
					skipOnset = 1
				endif
			
			else
			
				DoPrompt title, amp, ampD, width, widthD
			
				if ( V_flag == 1 )
					return "" // cancel
				endif
				
				onsetD = 0
				skipOnset = 1
			
			endif
			
			onset = 0
	
		else
		
			DoPrompt title, amp, ampD, onset, onsetD, width, widthD
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
		endif
	
	else
		
		if ( train )
		
			DoPrompt title, amp, width
		
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
			onset = 0
			skipOnset = 1
		
		else
		
			DoPrompt title, amp, onset, width
		
			if ( V_flag == 1 )
				return "" // cancel
			endif
		
		endif
		
		ampD = 0
		onsetD = 0
		widthD = 0
		
	endif
	
	pp.amp = amp
	pp.ampD = ampD
	pp.onset = onset
	pp.onsetD = onsetD
	pp.width = width
	pp.widthD = widthD
	
	if ( !ParamIsDefault( p ) )
		p = pp
	endif
	
	if ( train && numtype( width ) == 1 )
		skipWidth = 1
	endif
	
	NMPulseAOWsave( pp, pdf = pdf, type = type, skipOnset = skipOnset, skipWidth = skipWidth, saveD = ( foundDSC ) )
	
	return NMPulseAOWparamList( pp, skipOnset = skipOnset, skipWidth = skipWidth, DSC = DSC )
	
End // NMPulsePromptAOW

//****************************************************************
//****************************************************************

Function /S NMPulsePromptOW( [ pdf, type, DSC, ampUnits, timeUnits, train, p ] )
	String pdf, type
	String DSC // "delta" or "stdv" or "cv"
	String ampUnits // "pA"
	String timeUnits // "ms"
	Variable train
	STRUCT NMPulseAOW &p
	
	STRUCT NMPulseAOW pp
	
	Variable onset, width, skipOnset
	Variable onsetD, widthD, foundDSC
	String title = "Pulse Config"
	
	if ( ParamIsDefault( pdf ) )
		pdf = NMPulseDF
	endif
	
	if ( !ParamIsDefault( type ) )
		title += " : " + type
	endif
	
	if ( ParamIsDefault( DSC ) )
		DSC = ""
	endif
	
	if ( ParamIsDefault( ampUnits ) )
		ampUnits = ""
	endif
	
	if ( ParamIsDefault( timeUnits ) )
		timeUnits = ""
	endif
	
	if ( ParamIsDefault( p ) )
		NMPulseAOWinit( pp, pdf = pdf, type = type )
	else
		pp = p
	endif
	
	onset = pp.onset
	onsetD = pp.onsetD
	width = pp.width
	widthD = pp.widthD
	
	Prompt onset, zPromptStr( "onset", timeUnits = timeUnits )
	Prompt width, zPromptStr( "width", timeUnits = timeUnits )
	
	Prompt onsetD, zPromptStr( "onset", DSC = DSC, timeUnits = timeUnits )
	Prompt widthD, zPromptStr( "width", DSC = DSC, timeUnits = timeUnits )
	
	foundDSC = zFoundDSC( DSC )
	
	if ( foundDSC )
		
		if ( train )
		
			onset = 0
		
			if ( StringMatch( DSC, "stdv" ) || StringMatch( DSC, "cv" ) )
			
				DoPrompt title, onset, onsetD, width, widthD
			
				if ( V_flag == 1 )
					return "" // cancel
				endif
			
			else
			
				DoPrompt title, width, widthD
			
				if ( V_flag == 1 )
					return "" // cancel
				endif
				
				onsetD = 0
				skipOnset = 1
			
			endif
	
		else
		
			DoPrompt title, onset, onsetD, width, widthD
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
		endif
	
	else
		
		if ( train )
		
			DoPrompt title, width
		
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
			onset = 0
			skipOnset = 1
		
		else
		
			DoPrompt title, onset, width
		
			if ( V_flag == 1 )
				return "" // cancel
			endif
		
		endif
		
		onsetD = 0
		widthD = 0
		
	endif
	
	pp.onset = onset
	pp.onsetD = onsetD
	pp.width = width
	pp.widthD = widthD
	
	if ( !ParamIsDefault( p ) )
		p = pp
	endif
	
	NMPulseAOWsave( pp, pdf = pdf, type = type, skipOnset = skipOnset, saveD = ( foundDSC ) )
	
	return NMPulseAOWparamList( pp, skipOnset = skipOnset, DSC = DSC )
	
End // NMPulsePromptOW

//****************************************************************
//****************************************************************

Function /S NMPulsePromptAlpha( [ pdf, DSC, ampUnits, timeUnits, p ] )
	String pdf
	String DSC // "delta" or "stdv" or "cv"
	String ampUnits // "pA"
	String timeUnits // "ms"
	STRUCT NMPulseAlpha &p
	
	STRUCT NMPulseAlpha pp
	
	Variable tau, tauD, foundDSC
	String title = "Pulse Config : Alpha"
	
	if ( ParamIsDefault( pdf ) )
		pdf = NMPulseDF
	endif
	
	if ( ParamIsDefault( DSC ) )
		DSC = ""
	endif
	
	if ( ParamIsDefault( ampUnits ) )
		ampUnits = ""
	endif
	
	if ( ParamIsDefault( timeUnits ) )
		timeUnits = ""
	endif
	
	if ( ParamIsDefault( p ) )
		NMPulseAlphaInit( pp, pdf = pdf )
	else
		pp = p
	endif
	
	tau = pp.tau
	tauD = pp.tauD
	
	Prompt tau, zPromptStr( "tau", timeUnits = timeUnits )
	Prompt tauD, zPromptStr( "tau", DSC = DSC, timeUnits = timeUnits )
	
	foundDSC = zFoundDSC( DSC )
	
	if ( foundDSC )
	
		DoPrompt title, tau, tauD
			
		if ( V_flag == 1 )
			return "" // cancel
		endif
	
	else
	
		DoPrompt title, tau
			
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		tauD = 0
		
	endif
	
	pp.tau = tau
	pp.tauD = tauD
	
	if ( !ParamIsDefault( p ) )
		p = pp
	endif
	
	NMPulseAlphaSave( pp, pdf = pdf, saveD = ( foundDSC ) )
	
	return NMPulseAlphaParamList( pp, DSC = DSC )
	
End // NMPulsePromptAlpha

//****************************************************************
//****************************************************************

Function /S NMPulsePromptGauss( [ pdf, DSC, ampUnits, timeUnits, p ] )
	String pdf
	String DSC // "delta" or "stdv" or "cv"
	String ampUnits // "pA"
	String timeUnits // "ms"
	STRUCT NMPulseGauss &p
	
	STRUCT NMPulseGauss pp
	
	Variable center, sdv
	Variable centerD, sdvD, foundDSC
	String title = "Pulse Config : Gauss"
	
	if ( ParamIsDefault( pdf ) )
		pdf = NMPulseDF
	endif
	
	if ( ParamIsDefault( DSC ) )
		DSC = ""
	endif
	
	if ( ParamIsDefault( ampUnits ) )
		ampUnits = ""
	endif
	
	if ( ParamIsDefault( timeUnits ) )
		timeUnits = ""
	endif
	
	if ( ParamIsDefault( p ) )
		NMPulseGaussInit( pp, pdf = pdf )
	else
		pp = p
	endif
	
	center = pp.center
	centerD = pp.centerD
	sdv = pp.stdv
	sdvD = pp.stdvD
	
	Prompt center, zPromptStr( "center", timeUnits = timeUnits )
	Prompt sdv, zPromptStr( "stdv", timeUnits = timeUnits )
	
	Prompt centerD, zPromptStr( "center", DSC = DSC, timeUnits = timeUnits )
	Prompt sdvD, zPromptStr( "stdv", DSC = DSC, timeUnits = timeUnits )
	
	foundDSC = zFoundDSC( DSC )
	
	if ( foundDSC )
	
		DoPrompt title, center, centerD, sdv, sdvD
			
		if ( V_flag == 1 )
			return "" // cancel
		endif
	
	else
	
		DoPrompt title, center, sdv
			
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		centerD = 0
		sdvD = 0
		
	endif
	
	pp.center = center
	pp.centerD = centerD
	pp.stdv = sdv
	pp.stdvD = sdvD
	
	if ( !ParamIsDefault( p ) )
		p = pp
	endif
	
	NMPulseGaussSave( pp, pdf = pdf, saveD = ( foundDSC ) )
	
	return NMPulseGaussParamList( pp, DSC = DSC )
	
End // NMPulsePromptGauss

//****************************************************************
//****************************************************************

Function /S NMPulsePromptExp( [ pdf, DSC, ampUnits, timeUnits, p ] )
	String pdf
	String DSC // "delta" or "stdv" or "cv"
	String ampUnits // "pA"
	String timeUnits // "ms"
	STRUCT NMPulseExp &p
	
	STRUCT NMPulseExp pp
	
	Variable amp1, tau1, amp2, tau2, amp3, tau3, amp4, tau4, ampsum
	Variable amp1D, tau1D, amp2D, tau2D, amp3D, tau3D, amp4D, tau4D, foundDSC
	String numExpStr
	String title = "Pulse Config : Exp"
	
	Variable numExp = NumVarOrDefault( pdf + "NumExp", 1 )
	
	numExp = min( numExp, 4 )
	numExp = max( numExp, 1 )
	numExpStr = num2istr( numExp )
	
	if ( ParamIsDefault( pdf ) )
		pdf = NMPulseDF
	endif
	
	if ( ParamIsDefault( DSC ) )
		DSC = ""
	endif
	
	if ( ParamIsDefault( ampUnits ) )
		ampUnits = ""
	endif
	
	if ( ParamIsDefault( timeUnits ) )
		timeUnits = ""
	endif
	
	if ( ParamIsDefault( p ) )
		NMPulseExpInit( pp, pdf = pdf )
	else
		pp = p
	endif
	
	amp1 = pp.amp1
	amp1D = pp.amp1D
	tau1 = pp.tau1
	tau1D = pp.tau1D
	
	amp2 = pp.amp2
	amp2D = pp.amp2D
	tau2 = pp.tau2
	tau2D = pp.tau2D
	
	amp3 = pp.amp3
	amp3D = pp.amp3D
	tau3 = pp.tau3
	tau3D = pp.tau3D
	
	amp4 = pp.amp4
	amp4D = pp.amp4D
	tau4 = pp.tau4
	tau4D = pp.tau4D
	
	Prompt amp1, zPromptStr( "amp1", ampUnits = ampUnits )
	Prompt tau1, zPromptStr( "tau1", timeUnits = timeUnits )
	Prompt amp2, zPromptStr( "amp2", ampUnits = ampUnits )
	Prompt tau2, zPromptStr( "tau2", timeUnits = timeUnits )
	Prompt amp3, zPromptStr( "amp3", ampUnits = ampUnits )
	Prompt tau3, zPromptStr( "tau3", timeUnits = timeUnits )
	Prompt amp4, zPromptStr( "amp4", ampUnits = ampUnits )
	Prompt tau4, zPromptStr( "tau4", timeUnits = timeUnits )
	
	Prompt amp1D, zPromptStr( "amp1", DSC = DSC, ampUnits = ampUnits )
	Prompt tau1D, zPromptStr( "tau1", DSC = DSC, timeUnits = timeUnits )
	Prompt amp2D, zPromptStr( "amp2", DSC = DSC, ampUnits = ampUnits )
	Prompt tau2D, zPromptStr( "tau2", DSC = DSC, timeUnits = timeUnits )
	Prompt amp3D, zPromptStr( "amp3", DSC = DSC, ampUnits = ampUnits )
	Prompt tau3D, zPromptStr( "tau3", DSC = DSC, timeUnits = timeUnits )
	Prompt amp4D, zPromptStr( "amp4", DSC = DSC, ampUnits = ampUnits )
	Prompt tau4D, zPromptStr( "tau4", DSC = DSC, timeUnits = timeUnits )
	
	foundDSC = zFoundDSC( DSC )
	
	Prompt numExpStr, "number of exponentials", popup "1;2;3;4;"
	
	DoPrompt title, numExpStr
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	numExp = str2num( numExpStr )
	SetNMvar( pdf + "NumExp", numExp )
	
	amp1 = zPromptExpAmpCheck( amp1 )
	tau1 = zPromptExpTauCheck( tau1 )
	
	switch( numExp )
		case 1:
			
			amp1 = 0 // not needed
			amp2 = 0
			tau2 = 99
			amp3 = 0
			tau3 = 99
			amp4 = 0
			tau4 = 99
			
			break
			
		case 2:
		
			amp2 = zPromptExpAmpCheck( amp2 )
			tau2 = zPromptExpTauCheck( tau2 )
			amp3 = 0
			tau3 = 99
			amp4 = 0
			tau4 = 99
			
			ampsum = amp1 + amp2
			amp1 *= 100 / ampsum // weighted %
			amp2 *= 100 / ampsum
			
			break
			
		case 3:
		
			amp2 = zPromptExpAmpCheck( amp2 )
			tau2 = zPromptExpTauCheck( tau2 )
			amp3 = zPromptExpAmpCheck( amp3 )
			tau3 = zPromptExpTauCheck( tau3 )
			
			if ( amp3 == 0 )
				amp3 = 1
			endif 
			
			amp4 = 0
			tau4 = 99
			
			ampsum = amp1 + amp2 + amp3
			amp1 *= 100 / ampsum // weighted %
			amp2 *= 100 / ampsum
			amp3 *= 100 / ampsum
			
			break
			
		case 4:
		
			amp2 = zPromptExpAmpCheck( amp2 )
			tau2 = zPromptExpTauCheck( tau2 )
			amp3 = zPromptExpAmpCheck( amp3 )
			tau3 = zPromptExpTauCheck( tau3 )
			amp4 = zPromptExpAmpCheck( amp4 )
			tau4 = zPromptExpTauCheck( tau4 )
			
			ampsum = amp1 + amp2 + amp3 + amp4
			amp1 *= 100 / ampsum // weighted %
			amp2 *= 100 / ampsum
			amp3 *= 100 / ampsum
			amp4 *= 100 / ampsum
			
			break
	endswitch
	
	if ( foundDSC )
	
		if ( numExp == 1 )
			DoPrompt title, tau1, tau1D
		else
			DoPrompt title, amp1, amp1D, tau1, tau1D
		endif
			
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		if ( numExp > 1 )
		
			DoPrompt title, amp2, amp2D, tau2, tau2D
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
		endif
		
		if ( numExp > 2 )
		
			DoPrompt title, amp3, amp3D, tau3, tau3D
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
		
		endif
		
		if ( numExp > 3 )
		
			DoPrompt title, amp4, amp4D, tau4, tau4D
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
		
		endif
	
	else
	
		switch( numExp )
			case 1:
				DoPrompt title, tau1
				break
			case 2:
				DoPrompt title, amp1, tau1, amp2, tau2
				break
			case 3:
				DoPrompt title, amp1, tau1, amp2, tau2, amp3, tau3
				break
			case 4:
				DoPrompt title, amp1, tau1, amp2, tau2, amp3, tau3, amp4, tau4
				break
		endswitch
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		amp1D = 0
		tau1D = 0
		amp2D = 0
		tau2D = 0
		amp3D = 0
		tau3D = 0
		amp4D = 0
		tau4D = 0
		
	endif
	
	pp.amp1 = amp1
	pp.amp1D = amp1D
	pp.tau1 = tau1
	pp.tau1D = tau1D
	
	pp.amp2 = amp2
	pp.amp2D = amp2D
	pp.tau2 = tau2
	pp.tau2D = tau2D
	
	pp.amp3 = amp3
	pp.amp3D = amp3D
	pp.tau3 = tau3
	pp.tau3D = tau3D
	
	pp.amp4 = amp4
	pp.amp4D = amp4D
	pp.tau4 = tau4
	pp.tau4D = tau4D
	
	if ( !ParamIsDefault( p ) )
		p = pp
	endif
	
	NMPulseExpSave( pp, pdf = pdf, saveD = ( foundDSC ) )
	
	return NMPulseExpParamList( pp, DSC = DSC )
	
End // NMPulsePromptExp

//****************************************************************
//****************************************************************

Static Function zPromptExpAmpCheck( amp )
	Variable amp
	
	if ( ( numtype( amp ) > 0 ) || ( amp == 0 ) )
		return 1
	else
		return amp
	endif
	
End // zPromptExpAmpCheck

//****************************************************************
//****************************************************************

Static Function zPromptExpTauCheck( tau )
	Variable tau
	
	if ( ( numtype( tau ) > 0 ) || ( tau == 0 ) )
		return 1
	else
		return abs( tau )
	endif
	
End // zPromptExpTauCheck

//****************************************************************
//****************************************************************

Function /S NMPulsePromptSynExp4( [ pdf, DSC, ampUnits, timeUnits, p ] )
	String pdf
	String DSC // "delta" or "stdv" or "cv"
	String ampUnits // "pA"
	String timeUnits // "ms"
	STRUCT NMPulseSynExp4 &p
	
	STRUCT NMPulseSynExp4 pp
	
	Variable tauRise, power
	Variable tauRiseD, powerD, foundDSC
	Variable amp1, tau1, amp2, tau2, amp3, tau3
	Variable amp1D, tau1D, amp2D, tau2D, amp3D, tau3D
	String title = "Pulse Config : SynExp4"
	
	if ( ParamIsDefault( pdf ) )
		pdf = NMPulseDF
	endif
	
	if ( ParamIsDefault( DSC ) )
		DSC = ""
	endif
	
	if ( ParamIsDefault( ampUnits ) )
		ampUnits = ""
	endif
	
	if ( ParamIsDefault( timeUnits ) )
		timeUnits = ""
	endif
	
	if ( ParamIsDefault( p ) )
		NMPulseSynExp4Init( pp, pdf = pdf )
	else
		pp = p
	endif
	
	tauRise = pp.tauRise
	tauRiseD = pp.tauRiseD
	power = pp.power
	powerD = pp.powerD

	amp1 = pp.amp1
	amp1D = pp.amp1D
	tau1 = pp.tau1
	tau1D = pp.tau1D
	
	amp2 = pp.amp2
	amp2D = pp.amp2D
	tau2 = pp.tau2
	tau2D = pp.tau2D
	
	amp3 = pp.amp3
	amp3D = pp.amp3D
	tau3 = pp.tau3
	tau3D = pp.tau3D
	
	Prompt tauRise, zPromptStr( "tauRise", timeUnits = timeUnits )
	Prompt power, "rise-time power:"
	Prompt amp1, zPromptStr( "amp1", ampUnits = ampUnits )
	Prompt tau1, zPromptStr( "tau1", timeUnits = timeUnits )
	Prompt amp2, zPromptStr( "amp2", ampUnits = ampUnits )
	Prompt tau2, zPromptStr( "tau2", timeUnits = timeUnits )
	Prompt amp3, zPromptStr( "amp3", ampUnits = ampUnits )
	Prompt tau3, zPromptStr( "tau3", timeUnits = timeUnits )
	
	Prompt tauRiseD, zPromptStr( "tauRise", DSC = DSC )
	Prompt powerD, "rise-time power D:" 
	Prompt amp1D, zPromptStr( "amp1", DSC = DSC, ampUnits = ampUnits )
	Prompt tau1D, zPromptStr( "tau1", DSC = DSC, timeUnits = timeUnits )
	Prompt amp2D, zPromptStr( "amp2", DSC = DSC, ampUnits = ampUnits )
	Prompt tau2D, zPromptStr( "tau2", DSC = DSC, timeUnits = timeUnits )
	Prompt amp3D, zPromptStr( "amp3", DSC = DSC, ampUnits = ampUnits )
	Prompt tau3D, zPromptStr( "tau3", DSC = DSC, timeUnits = timeUnits )
	
	foundDSC = zFoundDSC( DSC )
	
	if ( foundDSC )
		
		DoPrompt title, tauRise, tauRiseD, power, powerD, amp1, amp1D, tau1, tau1D
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		DoPrompt title, amp2, amp2D, tau2, tau2D, amp3, amp3D, tau3, tau3D
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
	
	else
	
		DoPrompt title, tauRise, power
			
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		DoPrompt title, amp1, tau1, amp2, tau2, amp3, tau3
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		tauRiseD = 0
		powerD = 0
		amp1D = 0
		tau1D = 0
		amp2D = 0
		tau2D = 0
		amp3D = 0
		tau3D = 0
		
	endif
	
	pp.tauRise = tauRise 
	pp.tauRiseD = tauRiseD
	pp.power = power
	pp.powerD = powerD
	
	pp.amp1 = amp1
	pp.amp1D = amp1D
	pp.tau1 = tau1
	pp.tau1D = tau1D
	
	pp.amp2 = amp2
	pp.amp2D = amp2D
	pp.tau2 = tau2
	pp.tau2D = tau2D
	
	pp.amp3 = amp3
	pp.amp3D = amp3D
	pp.tau3 = tau3
	pp.tau3D = tau3D
	
	if ( !ParamIsDefault( p ) )
		p = pp
	endif
	
	NMPulseSynExp4Save( pp, pdf = pdf, saveD = ( foundDSC ) )
	
	return NMPulseSynExp4ParamList( pp, DSC = DSC )
	
End // NMPulsePromptSynExp4

//****************************************************************
//****************************************************************

Function /S NMPulsePromptSin( [ pdf, cosine, DSC, ampUnits, timeUnits, p ] )
	String pdf
	Variable cosine // ( 0 ) no ( 1 ) yes
	String DSC // "delta" or "stdv" or "cv"
	String ampUnits // "pA"
	String timeUnits // "ms"
	STRUCT NMPulseSin &p
	
	STRUCT NMPulseSin pp
	
	Variable period, periodD, foundDSC
	String title = "Pulse Config : Sine"
	
	if ( ParamIsDefault( pdf ) )
		pdf = NMPulseDF
	endif
	
	if ( ParamIsDefault( DSC ) )
		DSC = ""
	endif
	
	if ( ParamIsDefault( ampUnits ) )
		ampUnits = ""
	endif
	
	if ( ParamIsDefault( timeUnits ) )
		timeUnits = ""
	endif
	
	if ( ParamIsDefault( p ) )
		NMPulseSinInit( pp, pdf = pdf, cosine = cosine )
	else
		pp = p
	endif
	
	if ( cosine )
		title = "Pulse Config : Cosine"
		pp.cosine = 1
	endif
	
	period = pp.period
	periodD = pp.periodD
	
	Prompt period, zPromptStr( "period", timeUnits = timeUnits )
	Prompt periodD, zPromptStr( "period", DSC = DSC, timeUnits = timeUnits )
	
	foundDSC = zFoundDSC( DSC )
	
	if ( foundDSC )
	
		DoPrompt title, period, periodD
			
		if ( V_flag == 1 )
			return "" // cancel
		endif
	
	else
	
		DoPrompt title, period
			
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		periodD = 0
		
	endif
	
	pp.period = period
	pp.periodD = periodD
	
	if ( !ParamIsDefault( p ) )
		p = pp
	endif
	
	NMPulseSinSave( pp, pdf = pdf, saveD = ( foundDSC ) )
	
	return NMPulseSinParamList( pp, DSC = DSC )
	
End // NMPulsePromptSin

//****************************************************************
//****************************************************************

Function /S NMPulsePromptSinZap( [ pdf, DSC, ampUnits, timeUnits, p ] )
	String pdf
	String DSC // "delta" or "stdv" or "cv"
	String ampUnits // "pA"
	String timeUnits // "ms"
	STRUCT NMPulseSinZap &p
	
	STRUCT NMPulseSinZap pp
	
	Variable periodBgn, periodEnd
	Variable periodBgnD, periodEndD, foundDSC
	String title = "Pulse Config : SinZap"
	
	if ( ParamIsDefault( pdf ) )
		pdf = NMPulseDF
	endif
	
	if ( ParamIsDefault( DSC ) )
		DSC = ""
	endif
	
	if ( ParamIsDefault( ampUnits ) )
		ampUnits = ""
	endif
	
	if ( ParamIsDefault( timeUnits ) )
		timeUnits = ""
	endif
	
	if ( ParamIsDefault( p ) )
		NMPulseSinZapInit( pp, pdf = pdf )
	else
		pp = p
	endif
	
	periodBgn = pp.periodBgn
	periodBgnD = pp.periodBgnD
	periodEnd = pp.periodEnd
	periodEndD = pp.periodEndD
	
	Prompt periodBgn, zPromptStr( "begin period", timeUnits = timeUnits )
	Prompt periodEnd, zPromptStr( "end period", timeUnits = timeUnits )
	
	Prompt periodBgnD, zPromptStr( "begin period", DSC = DSC, timeUnits = timeUnits )
	Prompt periodEndD, zPromptStr( "end period", DSC = DSC, timeUnits = timeUnits )
	
	foundDSC = zFoundDSC( DSC )
	
	if ( foundDSC )
	
		DoPrompt title, periodBgn, periodBgnD, periodEnd, periodEndD
			
		if ( V_flag == 1 )
			return "" // cancel
		endif
	
	else
	
		DoPrompt title, periodBgn, periodEnd
			
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		periodBgnD = 0
		periodEndD = 0
		
	endif
	
	pp.periodBgn = periodBgn
	pp.periodBgnD = periodBgnD
	pp.periodEnd = periodEnd
	pp.periodEndD = periodEndD
	
	if ( !ParamIsDefault( p ) )
		p = pp
	endif
	
	NMPulseSinZapSave( pp, pdf = pdf, saveD = ( foundDSC ) )
	
	return NMPulseSinZapParamList( pp, DSC = DSC )
	
End // NMPulsePromptSinZap

//****************************************************************
//****************************************************************

Function /S NMPulsePromptUserWave( df, wName [ pdf ] )
	String df, wName
	String pdf

	String wList
	String title = "Pulse Config : User Wave"
	
	if ( ParamIsDefault( pdf ) )
		pdf = NMPulseDF
	endif
	
	if ( !WaveExists( $df + wName ) )
		wName = " "
	endif
	
	wList = NMFolderWaveList( df, "!*DAC_*", ";", "TEXT:0", 0 )
	
	if ( ItemsInList( wList ) == 0 )
		DoAlert 0, "There are no user-defined waves in stimulus folder " + df
		return ""
	endif
	
	Prompt wName, "select user-defined pulse wave:", popup wList
	
	DoPrompt title, wName
			
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	return wName
			
End // NMPulsePromptUserWave

//****************************************************************
//****************************************************************
//
//		Pulse Graph Functions
//
//****************************************************************
//****************************************************************

Function PulseGraphMake()
	
	Variable pw=500, ph=300
	
	String computer = NMComputerType()
	
	if ( StringMatch(computer, "mac") )
		pw = 600
	endif
	
	Variable x0 = ceil((NMComputerPixelsX() - pw)/4)
	Variable y0 = ceil((NMComputerPixelsY() - ph)/4)
	
	Make /O/N=0 PU_DumWave
	
	DoWindow /K $NMPulseGraphName
	Display /K=(NMK())/N=$NMPulseGraphName/W=(x0,y0,x0+pw,y0+ph) PU_DumWave as "Pulse Generator"
	
	Label /W=$NMPulseGraphName bottom, NMXunits
	
	RemoveFromGraph /Z/W=$NMPulseGraphName PU_DumWave
	
	KillWaves /Z PU_DumWave
	
End // PulseGraphMake

//****************************************************************
//****************************************************************

Function PulseGraphUpdate(df, wlist)
	String df // data folder
	String wlist // wave list
	
	Variable icnt, madeGraph
	String rlist
	
	STRUCT NMRGB c

	if (WinType(NMPulseGraphName) == 0)
		PulseGraphMake()
		madeGraph = 1
	endif
	
	if (WinType(NMPulseGraphName) == 0)
		return -1
	endif
	
	rlist = TraceNameList(NMPulseGraphName,";",1)
	
	for (icnt = 0; icnt < ItemsInList(rlist); icnt += 1) // remove all waves first
		RemoveFromGraph /Z/W=$NMPulseGraphName $StringFromList(icnt, rlist)
	endfor
	
	if (ItemsInList(wlist) > 0)
	
		PulseGraphAppend(df, wlist)
		
		NMColorList2RGB( NMWinColor, c )
		
		ModifyGraph /W=$NMPulseGraphName mode=6, standoff=0
		ModifyGraph /W=$NMPulseGraphName wbRGB = (c.r,c.g,c.b), cbRGB = (c.r,c.g,c.b)
		
		GraphRainbow( NMPulseGraphName, "_All_" ) // set waves to raindow colors
	
	endif
	
	return madeGraph

End // PulseGraphUpdate

//****************************************************************
//****************************************************************

Function PulseGraphRemove(wlist)
	String wlist // wave list
	
	String wname
	Variable icnt
	
	if ( WinType( NMPulseGraphName ) == 0 )
		return 0
	endif

	for (icnt = 0; icnt < ItemsInList(wlist); icnt += 1)
		wname = StringFromList(icnt, wlist)
		RemoveFromGraph /Z/W=$NMPulseGraphName $wname
	endfor
	
End // PulseGraphRemove

//****************************************************************
//****************************************************************

Function PulseGraphAppend(df, wlist)
	String df // data folder
	String wlist // wave list
	
	String wname
	Variable icnt
	
	if ( WinType( NMPulseGraphName ) == 0 )
		return 0
	endif

	for (icnt = 0; icnt < ItemsInList(wlist); icnt += 1)
	
		wname = StringFromList(icnt, wlist)
		
		if ( WaveExists( $df+wname ) )
			AppendToGraph /W=$NMPulseGraphName $df+wname
		endif
		
	endfor
	
End // PulseGraphAppend

//****************************************************************
//****************************************************************
//
//	Misc Pulse Functions
//
//****************************************************************
//****************************************************************

Function NMRefracRateCorrection( desiredFreq, refrac ) 
	Variable desiredFreq // end product frequency that is desired (kHz)
	Variable refrac // refractory period (ms)
	
	// desiredFreq = 1 / [ ( 1 / useThisFreq ) + refrac ]
	
	Variable interval = 1 / desiredFreq
	
	if ( interval <= refrac )
		return NaN // not possible
	endif
	
	Variable useThisFreq = 1 / ( interval - refrac ) // kHz
	
	return useThisFreq
	
End // NMRefracRateCorrection

//****************************************************************
//****************************************************************

Function NMRateWave( wName, dx, waveLength, tbgn, tend, meanFreq, modFreq, modPcnt ) // NOT USED
	String wName // output wave name
	Variable dx // output wave time step (ms)
	Variable waveLength // output wave length (ms)
	Variable tbgn, tend // time window of rate function
	Variable meanFreq // mean rate (kHz)
	Variable modFreq // modulation frequency (kHz)
	Variable modPcnt // rate modulation % ( 0 ) none (100) complete
	
	Variable xpnts = 1 + waveLength / dx
	Variable pbgn, pend // points

	Make /O/N=( xpnts ) $wName
	
	Wave temp = $wName
	
	Setscale /P x 0, dx, temp
	
	modPcnt /= 100 // convert % to fraction
	
	tbgn = max( tbgn, leftx( temp ) )
	tend = min( tend, rightx( temp ) )
	
	temp = meanFreq * ( 1 + modPcnt * sin( ( x - tbgn ) * modFreq * 2 * pi - pi / 2 ) )
	
	if ( tbgn > 0 )
	
		pbgn = 0
		pend = x2pnt( temp, tbgn ) - 1
		
		if ( ( pend > pbgn ) && ( pend < numpnts( temp ) ) )
			temp[ pbgn, pend ] = 0
		endif
	
	endif
	
	if ( tend < waveLength )
	
		pbgn = x2pnt( temp, tend ) + 1
		pend = numpnts( temp ) - 1
		
		if ( pend > pbgn )
			temp[ pbgn, pend ] = 0
		endif
	
	endif
	
	return 0
	
End // NMRateWave

//****************************************************************
//****************************************************************

Function /S NMRateToRandomTrain( rateWave, waveformName, outputPrefix, chanNum, numWaves, refrac, savePulseTimes, savePulseIntervals )
	String rateWave // wave generated by NMRateWave, or equivalent, in kHz
	String waveformName // name of wave containing impulse waveform, or ("") for simple impulse train of 1's
	String outputPrefix // output wave prefix name
	Variable chanNum // output channel number ( -1 ) for none
	Variable numWaves // number of waves to generate
	Variable refrac // refractory period, ms ( 0 ) for none
	Variable savePulseTimes, savePulseIntervals // ( 0 ) no ( 1 ) yes
	
	Variable wcnt, icnt, jcnt, pcnt, pnt
	Variable prob, onset, tlast, intvl, userWaveform
	
	if ( ( strlen( rateWave ) == 0 ) || !WaveExists( $rateWave ) )
		return ""
	endif
	
	if ( ( strlen( waveformName ) > 0 ) && !WaveExists( $waveformName ) )
		return ""
	endif
	
	Variable pulsePnts = 1
	
	Variable xpnts = numpnts( $rateWave )
	Variable dx = deltax( $rateWave )
	Variable tbgn = leftx( $rateWave )
	Variable tend = rightx( $rateWave )
	
	Variable pulseLimit = 99999 // max number of pulses
	
	String wName, wList
	String chanStr = ChanNum2Char( chanNum )
	
	wList = WaveList( outputPrefix + "*", ";", "" )
	
	if ( ItemsInList( wList ) > 0 )
	
		//DoAlert 1, "NMRateToRandomTrain alert: waves with prefix name " + outputPrefix + " already exist and may be overwritten. Do you want to continue?"
			
		//if ( V_flag != 1 )
		//	return "" // cancel
		//endif
	
	endif
	
	wList = ""
	
	pulsePnts = max( 1, pulsePnts )
	
	Duplicate /O $rateWave U_RateWaveCorrected
	
	Wave inputRate = $rateWave
	Wave U_RateWaveCorrected
	
	if ( ( numtype( refrac ) == 0 ) && ( refrac > 0 ) )
		U_RateWaveCorrected = NMRefracRateCorrection( inputRate, refrac )
	endif
	
	if ( ( strlen( waveformName ) > 0 ) && WaveExists( $waveformName ) )
	
		if ( deltax( $waveformName ) != dx )
		
			DoAlert 0, "NMRateToRandomTrain alert: waveform sample interval " + num2str( deltax( $waveformName ) ) + " does not equal " + num2str( dx )
			
			return ""
		
		endif
		
		pulsePnts = 1 // only one point for convolution to work
		userWaveform = 1
		
	endif
	
	for ( wcnt = 0; wcnt < numWaves; wcnt += 1 )
	
		wName = "P_Intervals_" + outputPrefix + chanStr + num2str( wcnt )
		
		Make /O/N=( pulseLimit ) $wName = NaN
		
		Wave intvls = $wName
		
		wName = "P_Times_" + outputPrefix + chanStr + num2str( wcnt )
		
		Make /O/N=( pulseLimit ) $wName = NaN
		
		Wave times = $wName
	
		wName = outputPrefix + chanStr + num2str( wcnt )
		
		wList = AddListItem( wName, wList, ";", inf )
		
		Make /O/N=( xpnts ) $wName = 0
		
		Wave wtemp = $wName
		
		Setscale /P x 0, dx, wtemp
		
		jcnt = 0
		tlast = tbgn
	
		do
			
			Duplicate /O/R=( tlast, inf ) U_RateWaveCorrected, Interval
			Setscale /P x 0, dx, Interval
			
			if ( ( numtype( refrac ) == 0 ) && ( refrac > 0 ) )
			
				pnt = x2pnt( Interval, refrac )
				
				if ( ( pnt > 0 ) && ( pnt < numpnts( Interval ) ) )
					Interval[ 0, pnt ] = 0
				endif
				
			endif
			
			Integrate /T Interval /D=U_Integral
		
			prob = - ln( abs( enoise( 1 ) ) )
			
			for ( icnt = 0; icnt < numpnts( U_Integral ); icnt += 1 )
			
				if ( U_Integral[ icnt ] >= prob )
					intvl = pnt2x( U_Integral, icnt )
					onset = tlast + intvl
					break
				endif
				
				if ( icnt == numpnts( U_Integral ) - 1 )
					onset = inf // force quit here
				endif
				
			endfor
			
			if ( ( onset > tbgn ) && ( onset < tend ) )
		
				pnt = x2pnt( U_RateWaveCorrected, onset )
				
				pnt = max( pnt, 0 )
				pnt = min( pnt, numpnts( U_RateWaveCorrected ) )
				
				for ( pcnt = pnt; pcnt < pnt + pulsePnts ; pcnt += 1 )
					if ( pcnt >= numpnts( wtemp ) )
						break
					endif
					wtemp[ pcnt ] = 1
				endfor
				
				tlast = onset
				times[ jcnt ] = onset
				
				if ( jcnt == 0 )
					intvls[ jcnt ] = NaN
				else
					intvls[ jcnt ] = intvl
				endif
				
				jcnt += 1
				
			endif
			
		while ( ( onset < tend ) && ( jcnt < pulseLimit ) )
		
		if ( savePulseTimes )
			Redimension /N=( jcnt ) times
		else
			KillWaves /Z times
		endif
		
		if ( savePulseIntervals )
			Redimension /N=( jcnt ) intvls
		else
			KillWaves /Z intvls
		endif
		
		if ( userWaveform )
			Convolve $waveformName wtemp
			Redimension /N=( xpnts ) wtemp
		endif
	
	endfor
	
	KillWaves /Z U_RateWaveCorrected, U_Integral
	
	return wList

End // NMRateToRandomTrain

//****************************************************************
//****************************************************************

Function NMPulseTimes2Wave( waveOfPulseTimes, waveformName, outputWaveName, waveLength, dx )
	String waveOfPulseTimes
	String waveformName // name of wave containing impulse waveform, or ("") for simple impulse train of 1's
	String outputWaveName
	Variable waveLength, dx // wave length and time step of output wave (ms)
	
	Variable icnt, pnt, xpnts, userWaveform
	
	if ( ( strlen( waveOfPulseTimes ) == 0 ) || !WaveExists( $waveOfPulseTimes ) )
		return -1
	endif
	
	if ( strlen( waveformName ) > 0 )
		if ( !WaveExists( $waveformName ) )
			return -1
		else
			userWaveform = 1
		endif
	endif
	
	xpnts = 1 + waveLength / dx
	
	Make /O/N=( xpnts ) $outputWaveName = 0
	Setscale /P x 0, dx, $outputWaveName
	
	Wave wtemp = $outputWaveName
	Wave times = $waveOfPulseTimes
	
	for ( icnt = 0 ; icnt < numpnts( times ) ; icnt += 1 )
		
		pnt = x2pnt( wtemp, times[ icnt ] )
		
		if ( ( pnt >= 0 ) && ( pnt < xpnts ) )
			wtemp[ pnt ] = 1
		endif
		
	endfor
	
	if ( userWaveform )
		Convolve $waveformName wtemp
		Redimension /N=( xpnts ) wtemp
	endif

	return 0

End // NMPulseTimes2Wave

//****************************************************************
//****************************************************************

Function NMPulseTimeWave( outputName, tbgn, tend, rate )
	String outputName
	Variable tbgn, tend // window of pulse times
	Variable rate // kHz
	
	Variable icnt, jcnt, ptime = tbgn
	
	Variable intvl = 1 / rate // ms
	
	Variable xpnts = 10 + ( tend - tbgn ) / intvl
	
	if ( xpnts <= 0 )
		return -1
	endif
	
	Make /O/N=( xpnts ) $outputName = NaN
	
	Wave wtemp = $outputName
	
	for ( icnt = 0 ; icnt < xpnts; icnt += 1 )
	
		if ( ( ptime >= tbgn ) && ( ptime <= tend ) )
			wtemp[ icnt ] = ptime
			jcnt += 1
		endif
		
		ptime += intvl
		
	endfor
	
	Redimension /N=( jcnt ) wtemp
	
	return 0
	
End // NMPulseTimeWave

//****************************************************************
//****************************************************************
//
//	Pulse Structure Functions
//
//****************************************************************
//****************************************************************

Function /S NMPulseTypeName( type )
	String type
	
	strswitch( type )
		case "square":
			return "Square"
		case "TTL":
		case "squareTTL":
			return "SquareTTL"
		case "+ramp":
		case "-ramp":
			return "Ramp"
		case "exp":
			return "Exp"
		case "synexp":
		case "synexp4":
			return "SynExp"
		case "alpha":
			return "Alpha"
		case "cos":
		case "cosine":
			return "Cos"
		case "sin":
		case "sine":
			return "Sin"
		case "sinzap":
			return "SinZap"
		case "other":
			return "Other"
	endswitch
	
	return ""
	
End // NMPulseTypeName

//****************************************************************
//****************************************************************

Function NMPulseWidthDefault( type [ waveLength ] )
	String type
	Variable waveLength
	
	if ( ParamIsDefault( waveLength ) || ( numtype( waveLength ) > 0 ) || ( waveLength == 0 ) )
		waveLength = NumVarOrDefault( NMPulseDF + "WaveLength", 100 )
	endif
	
	strswitch( type )
	
		case "square":
		case "TTL":
		case "squareTTL":
			return widthDefault
		
		case "+ramp":
		case "-ramp":
			return ( waveLength * 0.8 )
			
		case "exp":
		case "synexp":
		case "synexp4":
		case "alpha":
		case "gauss":
		case "other":
			return inf
			
		case "cos":
		case "cosine":
		case "sin":
		case "sine":
		case "sinzap":
			return ( waveLength * 0.8 )
			
	endswitch
	
	return widthDefault
	
End // NMPulseWidthDefault

//****************************************************************
//****************************************************************

Static Structure DSC

	Variable delta, stdv, cv

EndStructure

//****************************************************************
//****************************************************************

Static Function DSCinit( d, DSC )
	STRUCT DSC &d
	String DSC
	
	strswitch( DSC )
		case "delta":
			d.delta = 1
			d.stdv = 0
			d.cv = 0
			break
		case "stdv":
			d.delta = 0
			d.stdv = 1
			d.cv = 0
			break
		case "cv":
			d.delta = 0
			d.stdv = 0
			d.cv = 1
			break
	endswitch
	
End // DSCinit

//****************************************************************
//****************************************************************

Structure NMPulseAOW // Amp, Onset and Width

	Variable amp, onset, width
	Variable ampD, onsetD, widthD

EndStructure

//****************************************************************
//****************************************************************

Function NMPulseAOWinit( p [ pdf, type, paramList, waveLength, DSCG ] ) 
	STRUCT NMPulseAOW &p
	String pdf, type, paramList
	Variable waveLength
	Variable DSCG
	
	Variable wDefault
	String vp = promptPrefix
	
	if ( ParamIsDefault( pdf ) )
		pdf = NMPulseDF
	endif
	
	if ( ParamIsDefault( type ) )
		type = ""
	else
		vp += NMPulseTypeName( type )
	endif
	
	wDefault = NMPulseWidthDefault( type, waveLength = waveLength )
	
	if ( ParamIsDefault( pdf ) || ( strlen( pdf ) == 0 ) )
		p.amp = ampDefault
		p.ampD = 0
		p.onset = onsetDefault
		p.onsetD = 0
		p.width = wDefault
		p.widthD = 0
	else
		p.amp = NumVarOrDefault( pdf + vp + "Amp", ampDefault )
		p.ampD = NumVarOrDefault( pdf + vp + "AmpD", 0 )
		p.onset = NumVarOrDefault( pdf + vp + "Onset", onsetDefault )
		p.onsetD = NumVarOrDefault( pdf + vp + "OnsetD", 0 )
		p.width = abs( NumVarOrDefault( pdf + vp + "Width", wDefault ) )
		p.widthD = NumVarOrDefault( pdf + vp + "WidthD", 0 )
	endif
	
	if ( ParamIsDefault( paramList ) || ( strlen( paramList ) == 0 ) )
		return 0
	endif
	
	if ( ParamIsDefault( DSCG ) )
		DSCG = NaN
	endif
	
	p.amp = NMPulseNumByKey( "amp", paramList, NaN, DSCG = DSCG )
	p.ampD = NMPulseNumByKeyDSCG( "amp", paramList )
	p.onset = NMPulseNumByKey( "onset", paramList, 0, DSCG = DSCG )
	p.onsetD = NMPulseNumByKeyDSCG( "onset", paramList )
	p.width = NMPulseNumByKey( "width", paramList, inf, DSCG = DSCG, positive = 1 )
	p.widthD = NMPulseNumByKeyDSCG( "width", paramList )
	
End // NMPulseAOWinit

//****************************************************************
//****************************************************************

Function NMPulseAOWsave( p [ pdf, type, skipAmp, skipOnset, skipWidth, saveD ] )
	STRUCT NMPulseAOW &p
	String pdf, type
	Variable skipAmp, skipOnset, skipWidth, saveD
	
	String vp = promptPrefix
	
	if ( ParamIsDefault( pdf ) )
		pdf = NMPulseDF
	endif
	
	if ( !ParamIsDefault( type ) )
		vp += NMPulseTypeName( type )
	endif
	
	if ( !skipAmp )
		zSetVarD( pdf, vp, "Amp", p.amp, p.ampD, saveD )
	endif
	
	if ( !skipOnset )
		zSetVarD( pdf, vp, "Onset", p.onset, p.onsetD, saveD )
	endif
	
	if ( !skipWidth )
		zSetVarD( pdf, vp, "Width", abs( p.width ), p.widthD, saveD )
	endif
	
End // NMPulseAOWsave

//****************************************************************
//****************************************************************

Structure NMPulseSaveToWaves

	String sf, wavePrefix, pulseType
	Variable numWaves, waveNum
	Variable pulseConfigNum
	Variable pulsesPerConfig, pulseNum
	Variable binomialN, trial, failure
	Variable plasticity

EndStructure

//****************************************************************
//****************************************************************

Function NMPulseSaveToWavesInit( s ) 
	STRUCT NMPulseSaveToWaves &s
	
	s.sf = ""
	s.wavePrefix = paramWavePrefix
	s.pulseType = ""
	
End // NMPulseSaveToWavesInit

//****************************************************************
//****************************************************************

Function  NMPulseAOWsaveToWaves( a, s )
	STRUCT NMPulseAOW &a
	STRUCT NMPulseSaveToWaves &s
	
	zSaveToWave( s, "Amp", a.amp, a.ampD )
	zSaveToWave( s, "Onset", a.onset, a.onsetD )
	zSaveToWave( s, "Width", abs( a.width ), a.widthD )
	
End //  NMPulseAOWsaveToWaves

//****************************************************************
//****************************************************************

Function /S NMPulseAOWparamList( p [ skipAmp, skipOnset, skipWidth, DSC ] )
	STRUCT NMPulseAOW &p
	Variable skipAmp, skipOnset, skipWidth
	String DSC // "delta" or "stdv" or "cv"
	
	String pstr = ""
	
	STRUCT DSC d
	
	if ( ParamIsDefault( DSC ) )
		DSC = ""
	endif
	
	DSCinit( d, DSC )
	
	if ( !skipAmp )
		pstr += NMPulseParamList( "amp", p.amp, delta = ( p.ampD * d.delta ), stdv = ( p.ampD * d.stdv ), cv = ( p.ampD * d.cv ) )
	endif
	
	if ( !skipOnset )
		pstr += NMPulseParamList( "onset", p.onset, delta = ( p.onsetD * d.delta ), stdv = ( p.onsetD * d.stdv ), cv = ( p.onsetD * d.cv ) )
	endif
	
	if ( !skipWidth )
		pstr += NMPulseParamList( "width", abs( p.width ), delta = ( p.widthD * d.delta), stdv = ( p.widthD * d.stdv ), cv = ( p.widthD * d.cv ), fixPolarity = 1 )
	endif
	
	return pstr 
	
End // NMPulseAOWparamList

//****************************************************************
//****************************************************************

Structure NMPulseAlpha

	Variable tau, tauD

EndStructure

//****************************************************************
//****************************************************************

Function NMPulseAlphaInit( p [ pdf, paramList, DSCG ] ) 
	STRUCT NMPulseAlpha &p
	String pdf, paramList
	Variable DSCG
	
	String vp = promptPrefix + "Alpha"
	
	if ( ParamIsDefault( pdf ) )
		p.tau = tauDefault
		p.tauD = 0
	else
		p.tau = abs( NumVarOrDefault( pdf + vp + "Tau", tauDefault ) )
		p.tauD = NumVarOrDefault( pdf + vp + "tauD", 0 )
	endif
	
	if ( ParamIsDefault( paramList ) || ( strlen( paramList ) == 0 ) )
		return 0
	endif
	
	if ( ParamIsDefault( DSCG ) )
		DSCG = NaN
	endif
	
	p.tau = NMPulseNumByKey( "tau", paramList, p.tau, DSCG = DSCG, positive = 1 )
	p.tauD = NMPulseNumByKeyDSCG( "tau", paramList )
	
End // NMPulseAlphaInit

//****************************************************************
//****************************************************************

Function NMPulseAlphaSave( p [ pdf, saveD ] )
	STRUCT NMPulseAlpha &p
	String pdf
	Variable saveD
	
	String vp = promptPrefix + "Alpha"
	
	if ( ParamIsDefault( pdf ) )
		pdf = NMPulseDF
	endif
	
	zSetVarD( pdf, vp, "Tau", abs( p.tau ), p.tauD, saveD )
	
End // NMPulseAlphaSave

//****************************************************************
//****************************************************************

Function NMPulseAlphaSaveToWaves( a, p, s )
	STRUCT NMPulseAOW &a
	STRUCT NMPulseAlpha &p
	STRUCT NMPulseSaveToWaves &s
	
	s.wavePrefix = paramWavePrefix + "Alpha_"
	s.pulseType = "Alpha"
	
	NMPulseAOWsaveToWaves( a, s )
	
	zSaveToWave( s, "Tau", abs( p.tau ), p.tauD )
	
End // NMPulseAlphaSaveToWaves

//****************************************************************
//****************************************************************

Function /S NMPulseAlphaParamList( p [ DSC ] )
	STRUCT NMPulseAlpha &p
	String DSC // "delta" or "stdv" or "cv"
	
	STRUCT DSC d
	
	if ( ParamIsDefault( DSC ) )
		DSC = ""
	endif
	
	DSCinit( d, DSC )
	
	return NMPulseParamList( "tau", abs( p.tau ), delta = ( p.tauD * d.delta ), stdv = ( p.tauD * d.stdv ), cv = ( p.tauD * d.cv ), fixPolarity = 1 )
	
End // NMPulseAlphaParamList

//****************************************************************
//****************************************************************

Structure NMPulseGauss

	Variable center, stdv
	Variable centerD, stdvD

EndStructure

//****************************************************************
//****************************************************************

Function NMPulseGaussInit( p [ pdf, paramList, DSCG ] ) 
	STRUCT NMPulseGauss &p
	String pdf, paramList
	Variable DSCG
	
	String vp = promptPrefix + "Gauss"
	
	if ( ParamIsDefault( pdf ) )
		p.center = 10
		p.centerD = 0
		p.stdv = 1
		p.stdvD = 0
	else
		p.center = NumVarOrDefault( pdf + vp + "Center", 10 )
		p.centerD = NumVarOrDefault( pdf + vp + "CenterD", 0 )
		p.stdv = abs( NumVarOrDefault( pdf + vp + "Stdv", 1 ) )
		p.stdvD = NumVarOrDefault( pdf + vp + "StdvD", 0 )
	endif
	
	if ( ParamIsDefault( paramList ) || ( strlen( paramList ) == 0 ) )
		return 0
	endif
	
	if ( ParamIsDefault( DSCG ) )
		DSCG = NaN
	endif
	
	p.center = NMPulseNumByKey( "center", paramList, p.center, DSCG = DSCG )
	p.centerD = NMPulseNumByKeyDSCG( "center", paramList )
	p.stdv =NMPulseNumByKey( "stdv", paramList, p.stdv, DSCG = DSCG, positive = 1 )
	p.stdvD = NMPulseNumByKeyDSCG( "stdv", paramList )
	
End // NMPulseGaussInit

//****************************************************************
//****************************************************************

Function NMPulseGaussSave( p [ pdf, saveD ] )
	STRUCT NMPulseGauss &p
	String pdf
	Variable saveD
	
	String vp = promptPrefix + "Gauss"
	
	if ( ParamIsDefault( pdf ) )
		pdf = NMPulseDF
	endif
	
	zSetVarD( pdf, vp, "Center", p.center, p.centerD, saveD )
	zSetVarD( pdf, vp, "Stdv", abs( p.stdv ), p.stdvD, saveD )
	
End // NMPulseGaussSave

//****************************************************************
//****************************************************************

Function NMPulseGaussSaveToWaves( a, p, s )
	STRUCT NMPulseAOW &a
	STRUCT NMPulseGauss &p
	STRUCT NMPulseSaveToWaves &s
	
	s.wavePrefix = paramWavePrefix + "Gauss_"
	s.pulseType = "Gauss"
	
	NMPulseAOWsaveToWaves( a, s )
	
	zSaveToWave( s, "Center", p.center, p.centerD )
	zSaveToWave( s, "Stdv", abs( p.stdv ), p.stdvD )
	
End // NMPulseGaussSaveToWaves

//****************************************************************
//****************************************************************

Function /S NMPulseGaussParamList( p [ DSC ] )
	STRUCT NMPulseGauss &p
	String DSC // "delta" or "stdv" or "cv"
	
	String pstr = ""
	
	STRUCT DSC d
	
	if ( ParamIsDefault( DSC ) )
		DSC = ""
	endif
	
	DSCinit( d, DSC )
	
	pstr += NMPulseParamList( "center", p.center, delta = ( p.centerD * d.delta ), stdv = ( p.centerD * d.stdv ), cv = ( p.centerD * d.cv ) )
	pstr += NMPulseParamList( "stdv", abs( p.stdv ), delta = ( p.stdvD * d.delta ), stdv = ( p.stdvD * d.stdv ), cv = ( p.stdvD * d.cv ), fixPolarity = 1 )
	
	return pstr
	
End // NMPulseGaussParamList

//****************************************************************
//****************************************************************

Structure NMPulseExp

	Variable amp1, tau1, amp2, tau2, amp3, tau3, amp4, tau4
	Variable amp1D, tau1D, amp2D, tau2D, amp3D, tau3D, amp4D, tau4D

EndStructure

//****************************************************************
//****************************************************************

Function NMPulseExpInit( p [ pdf, paramList, DSCG ] )
	STRUCT NMPulseExp &p
	String pdf, paramList
	Variable DSCG
	
	String vp = promptPrefix + "Exp"
	
	if ( ParamIsDefault( pdf ) )
		
		p.amp1 = ampDefault
		p.amp1D = 0
		p.tau1 = tauDefault
		p.tau1D = 0
		
		p.amp2 = ampDefault
		p.amp2D = 0
		p.tau2 = tauDefault
		p.tau2D = 0
		
		p.amp3 = ampDefault
		p.amp3D = 0
		p.tau3 = tauDefault
		p.tau3D = 0
		
		p.amp4 = ampDefault
		p.amp4D = 0
		p.tau4 = tauDefault
		p.tau4D = 0
		
	else
		
		p.amp1 = NumVarOrDefault( pdf + vp + "Amp1", ampDefault )
		p.amp1D = NumVarOrDefault( pdf + vp + "Amp1D", 0 )
		p.tau1 = abs( NumVarOrDefault( pdf + vp + "Tau1", tauDefault ) )
		p.tau1D = NumVarOrDefault( pdf + vp + "Tau1D", 0 )
		
		p.amp2 = NumVarOrDefault( pdf + vp + "Amp2", ampDefault )
		p.amp2D = NumVarOrDefault( pdf + vp + "Amp2D", 0 )
		p.tau2 = abs( NumVarOrDefault( pdf + vp + "Tau2", tauDefault ) )
		p.tau2D = NumVarOrDefault( pdf + vp + "Tau2D", 0 )
		
		p.amp3 = NumVarOrDefault( pdf + vp + "Amp3", ampDefault )
		p.amp3D = NumVarOrDefault( pdf + vp + "Amp3D", 0 )
		p.tau3 = abs( NumVarOrDefault( pdf + vp + "Tau3", tauDefault ) )
		p.tau3D = NumVarOrDefault( pdf + vp + "Tau3D", 0 )
		
		p.amp4 = NumVarOrDefault( pdf + vp + "Amp4", ampDefault )
		p.amp4D = NumVarOrDefault( pdf + vp + "Amp4D", 0 )
		p.tau4 = abs( NumVarOrDefault( pdf + vp + "Tau4", tauDefault ) )
		p.tau4D = NumVarOrDefault( pdf + vp + "Tau4D", 0 )
		
	endif
	
	if ( ParamIsDefault( paramList ) || ( strlen( paramList ) == 0 ) )
		return 0
	endif
	
	if ( ParamIsDefault( DSCG ) )
		DSCG = NaN
	endif
	
	p.amp1 = NMPulseNumByKey( "amp1", paramList, NaN, DSCG = DSCG )
	p.amp1D = NMPulseNumByKeyDSCG( "amp1", paramList )
	p.tau1 = NMPulseNumByKey( "tau1", paramList, NaN, DSCG = DSCG, positive = 1 )
	p.tau1D = NMPulseNumByKeyDSCG( "tau1", paramList )
	
	p.amp2 = NMPulseNumByKey( "amp2", paramList, NaN, DSCG = DSCG )
	p.amp2D = NMPulseNumByKeyDSCG( "amp2", paramList )
	p.tau2 = NMPulseNumByKey( "tau2", paramList, p.tau2, DSCG = DSCG, positive = 1 )
	p.tau2D = NMPulseNumByKeyDSCG( "tau2", paramList )
	
	p.amp3 = NMPulseNumByKey( "amp3", paramList, 0, DSCG = DSCG )
	p.amp3D = NMPulseNumByKeyDSCG( "amp3", paramList )
	p.tau3 = NMPulseNumByKey( "tau3", paramList, p.tau3, DSCG = DSCG, positive = 1 )
	p.tau3D = NMPulseNumByKeyDSCG( "tau3", paramList )
	
	p.amp4 = NMPulseNumByKey( "amp4", paramList, 0, DSCG = DSCG )
	p.amp4D = NMPulseNumByKeyDSCG( "amp4", paramList )
	p.tau4 = NMPulseNumByKey( "tau4", paramList, p.tau4, DSCG = DSCG, positive = 1 )
	p.tau4D = NMPulseNumByKeyDSCG( "tau4", paramList )
	
End // NMPulseExpInit

//****************************************************************
//****************************************************************

Function NMPulseExpSave( p [ pdf, saveD ] )
	STRUCT NMPulseExp &p
	String pdf
	Variable saveD
	
	String vp = promptPrefix + "Exp"
	
	if ( ParamIsDefault( pdf ) )
		pdf = NMPulseDF
	endif
	
	zSetVarD( pdf, vp, "Amp1", p.amp1, p.amp1D, saveD )
	zSetVarD( pdf, vp, "Tau1", abs( p.tau1 ), p.tau1D, saveD )
	zSetVarD( pdf, vp, "Amp2", p.amp2, p.amp2D, saveD )
	zSetVarD( pdf, vp, "Tau2", abs( p.tau2 ), p.tau2D, saveD )
	zSetVarD( pdf, vp, "Amp3", p.amp3, p.amp3D, saveD )
	zSetVarD( pdf, vp, "Tau3", abs( p.tau3 ), p.tau3D, saveD )
	zSetVarD( pdf, vp, "Amp4", p.amp4, p.amp4D, saveD )
	zSetVarD( pdf, vp, "Tau4", abs( p.tau4 ), p.tau4D, saveD )

End // NMPulseExpSave

//****************************************************************
//****************************************************************

Function NMPulseExpSaveToWaves( a, p, s )
	STRUCT NMPulseAOW &a
	STRUCT NMPulseExp &p
	STRUCT NMPulseSaveToWaves &s
	
	s.wavePrefix = paramWavePrefix + "Exp_"
	s.pulseType = "Exp"
	
	NMPulseAOWsaveToWaves( a, s )
	
	zSaveToWave( s, "Amp1", p.amp1, p.amp1D )
	zSaveToWave( s, "Tau1", abs( p.tau1 ), p.tau1D )
	zSaveToWave( s, "Amp2", p.amp2, p.amp2D )
	zSaveToWave( s, "Tau2", abs( p.tau2 ), p.tau2D )
	zSaveToWave( s, "Amp3", p.amp3, p.amp3D )
	zSaveToWave( s, "Tau3", abs( p.tau3 ), p.tau3D )
	zSaveToWave( s,  "Amp4", p.amp4, p.amp4D )
	zSaveToWave( s, "Tau4", abs( p.tau4 ), p.tau4D )
	
End // NMPulseAlphaSaveToWaves

//****************************************************************
//****************************************************************

Function /S NMPulseExpParamList( p [ DSC ] )
	STRUCT NMPulseExp &p
	String DSC // "delta" or "stdv" or "cv"
	
	String pstr = ""
	
	STRUCT DSC d
	
	if ( ParamIsDefault( DSC ) )
		DSC = ""
	endif
	
	DSCinit( d, DSC )
	
	if ( p.amp1 != 0 )
		pstr += NMPulseParamList( "amp1", p.amp1, delta = ( p.amp1D * d.delta ), stdv = ( p.amp1D * d.stdv ), cv = ( p.amp1D * d.cv ) ) 
	endif
	
	if ( p.tau1 > 0 )
		pstr += NMPulseParamList( "tau1", abs( p.tau1 ), delta = ( p.tau1D * d.delta ), stdv = ( p.tau1D * d.stdv ), cv = ( p.tau1D * d.cv ), fixPolarity = 1 )
	endif
	
	if ( p.amp2 != 0 )
		pstr += NMPulseParamList( "amp2", p.amp2, delta = ( p.amp2D * d.delta ), stdv = ( p.amp2D * d.stdv ), cv = ( p.amp2D * d.cv ) )
		pstr += NMPulseParamList( "tau2", abs( p.tau2 ), delta = ( p.tau2D * d.delta ), stdv = ( p.tau2D * d.stdv ), cv = ( p.tau2D * d.cv ), fixPolarity = 1 )
	endif
	
	if ( p.amp3 != 0 )
		pstr += NMPulseParamList( "amp3", p.amp3, delta = ( p.amp3D * d.delta ), stdv = ( p.amp3D * d.stdv ), cv = ( p.amp3D * d.cv ) )
		pstr += NMPulseParamList( "tau3", abs( p.tau3 ), delta = ( p.tau3D * d.delta ), stdv = ( p.tau3D * d.stdv ), cv = ( p.tau3D * d.cv ), fixPolarity = 1 )
	endif
	
	if ( p.amp4 != 0 )
		pstr += NMPulseParamList( "amp4", p.amp4, delta = ( p.amp4D * d.delta ), stdv = ( p.amp4D * d.stdv ), cv = ( p.amp4D * d.cv ) )
		pstr += NMPulseParamList( "tau4", abs( p.tau4 ), delta = ( p.tau4D * d.delta ), stdv = ( p.tau4D * d.stdv ), cv = ( p.tau4D * d.cv ), fixPolarity = 1 )
	endif
	
	return pstr
	
End // NMPulseExpParamList

//****************************************************************
//****************************************************************

Structure NMPulseSynExp4

	Variable tauRise, power, amp1, tau1, amp2, tau2, amp3, tau3
	Variable tauRiseD, powerD, amp1D, tau1D, amp2D, tau2D, amp3D, tau3D

EndStructure

//****************************************************************
//****************************************************************

Function NMPulseSynExp4Init( p [ pdf, paramList, DSCG ] )
	STRUCT NMPulseSynExp4 &p
	String pdf, paramList
	Variable DSCG
	
	String vp = promptPrefix + "SynExp4"
	
	if ( ParamIsDefault( pdf ) )
		
		p.amp1 = ampDefault
		p.amp1D = 0
		p.tau1 = tauDefault
		p.tau1D = 0
		
		p.amp2 = ampDefault
		p.amp2D = 0
		p.tau2 = tauDefault
		p.tau2D = 0
		
		p.amp3 = ampDefault
		p.amp3D = 0
		p.tau3 = tauDefault
		p.tau3D = 0
		
	else
		
		p.tauRise = abs( NumVarOrDefault( pdf + vp + "TauRise", tauDefault ) )
		p.tauRiseD = NumVarOrDefault( pdf + vp + "TauRiseD", 0 )
		p.power = abs( NumVarOrDefault( pdf + vp + "Power", 1 ) )
		p.powerD = NumVarOrDefault( pdf + vp + "PowerD", 0 )
		
		p.amp1 = NumVarOrDefault( pdf + vp + "Amp1", ampDefault )
		p.amp1D = NumVarOrDefault( pdf + vp + "Amp1D", 0 )
		p.tau1 = abs( NumVarOrDefault( pdf + vp + "Tau1", tauDefault ) )
		p.tau1D = NumVarOrDefault( pdf + vp + "Tau1D", 0 )
		
		p.amp2 = NumVarOrDefault( pdf + vp + "Amp2", ampDefault )
		p.amp2D = NumVarOrDefault( pdf + vp + "Amp2D", 0 )
		p.tau2 = abs( NumVarOrDefault( pdf + vp + "Tau2", tauDefault ) )
		p.tau2D = NumVarOrDefault( pdf + vp + "Tau2D", 0 )
		
		p.amp3 = NumVarOrDefault( pdf + vp + "Amp3", ampDefault )
		p.amp3D = NumVarOrDefault( pdf + vp + "Amp3D", 0 )
		p.tau3 = abs( NumVarOrDefault( pdf + vp + "Tau3", tauDefault ) )
		p.tau3D = NumVarOrDefault( pdf + vp + "Tau3D", 0 )
		
	endif
	
	if ( ParamIsDefault( paramList ) || ( strlen( paramList ) == 0 ) )
		return 0
	endif
	
	if ( ParamIsDefault( DSCG ) )
		DSCG = NaN
	endif
	
	p.tauRise =NMPulseNumByKey( "tauRise", paramList,  p.tauRise, DSCG = DSCG, positive = 1 )
	p.tauRiseD = NMPulseNumByKeyDSCG( "tauRise", paramList )
	p.power = NMPulseNumByKey( "power", paramList, p.power, DSCG = DSCG, positive = 1 )
	p.powerD = NMPulseNumByKeyDSCG( "power", paramList )
	
	p.amp1 = NMPulseNumByKey( "amp1", paramList, p.amp1, DSCG = DSCG )
	p.amp1D = NMPulseNumByKeyDSCG( "amp1", paramList )
	p.tau1 = NMPulseNumByKey( "tau1", paramList, p.tau1, DSCG = DSCG, positive = 1 )
	p.tau1D = NMPulseNumByKeyDSCG( "tau1", paramList )
	
	p.amp2 = NMPulseNumByKey( "amp2", paramList, 0, DSCG = DSCG )
	p.amp2D = NMPulseNumByKeyDSCG( "amp2", paramList )
	p.tau2 = NMPulseNumByKey( "tau2", paramList,  p.tau2, DSCG = DSCG, positive = 1 )
	p.tau2D = NMPulseNumByKeyDSCG( "tau2", paramList )
	
	p.amp3 = NMPulseNumByKey( "amp3", paramList, 0, DSCG = DSCG )
	p.amp3D = NMPulseNumByKeyDSCG( "amp3", paramList )
	p.tau3 = NMPulseNumByKey( "tau3", paramList, p.tau3, DSCG = DSCG, positive = 1 )
	p.tau3D = NMPulseNumByKeyDSCG( "tau3", paramList )
	
End // NMPulseSynExp4Init

//****************************************************************
//****************************************************************

Function NMPulseSynExp4Save( p [ pdf, saveD ] )
	STRUCT NMPulseSynExp4 &p
	String pdf
	Variable saveD
	
	String vp = promptPrefix + "SynExp4"
	
	if ( ParamIsDefault( pdf ) )
		pdf = NMPulseDF
	endif
	
	zSetVarD( pdf, vp, "TauRise", abs( p.tauRise ), p.tauRiseD, saveD )
	zSetVarD( pdf, vp, "Power", abs( p.power ), p.powerD, saveD )
	zSetVarD( pdf, vp, "Amp1", p.amp1, p.amp1D, saveD )
	zSetVarD( pdf, vp, "Tau1", abs( p.tau1 ), p.tau1D, saveD )
	zSetVarD( pdf, vp, "Amp2", p.amp2, p.amp2D, saveD )
	zSetVarD( pdf, vp, "Tau2", abs( p.tau2 ), p.tau2D, saveD )
	zSetVarD( pdf, vp, "Amp3", p.amp3, p.amp3D, saveD )
	zSetVarD( pdf, vp, "Tau3", abs( p.tau3 ), p.tau3D, saveD )
	
End // NMPulseSynExp4Save

//****************************************************************
//****************************************************************

Function NMPulseSynExp4SaveToWaves( a, p, s )
	STRUCT NMPulseAOW &a
	STRUCT NMPulseSynExp4 &p
	STRUCT NMPulseSaveToWaves &s
	
	s.wavePrefix = paramWavePrefix + "SynExp4_"
	s.pulseType = "SynExp4"
	
	NMPulseAOWsaveToWaves( a, s )
	
	zSaveToWave( s, "TauRise", abs( p.tauRise ), p.tauRiseD )
	zSaveToWave( s, "Power", abs( p.power ), p.powerD )
	zSaveToWave( s, "Amp1", p.amp1, p.amp1D )
	zSaveToWave( s, "Tau1", abs( p.tau1 ), p.tau1D )
	zSaveToWave( s, "Amp2", p.amp2, p.amp2D )
	zSaveToWave( s, "Tau2", abs( p.tau2 ), p.tau2D )
	zSaveToWave( s,  "Amp3", p.amp3, p.amp3D )
	zSaveToWave( s, "Tau3", abs( p.tau3 ), p.tau3D )
	
End // NMPulseAlphaSaveToWaves

//****************************************************************
//****************************************************************

Function /S NMPulseSynExp4ParamList( p [ DSC ] )
	STRUCT NMPulseSynExp4 &p
	String DSC // "delta" or "stdv" or "cv"
	
	String pstr = ""
	
	STRUCT DSC d
	
	if ( ParamIsDefault( DSC ) )
		DSC = ""
	endif
	
	DSCinit( d, DSC )
	
	pstr += NMPulseParamList( "tauRise", abs( p.tauRise ), delta = ( p.tauRiseD * d.delta ), stdv = ( p.tauRiseD * d.stdv ), cv = ( p.tauRiseD * d.cv ), fixPolarity = 1 )
	pstr += NMPulseParamList( "power", abs( p.power ), delta = ( p.powerD * d.delta ), stdv = ( p.powerD * d.stdv ), cv = ( p.powerD * d.cv ), fixPolarity = 1 )
	
	if ( ( p.amp1 != 0 ) && ( p.tau1 > 0 ) )
		pstr += NMPulseParamList( "amp1", p.amp1, delta = ( p.amp1D * d.delta ), stdv = ( p.amp1D * d.stdv ), cv = ( p.amp1D * d.cv ) )
		pstr += NMPulseParamList( "tau1", abs( p.tau1 ), delta = ( p.tau1D * d.delta ), stdv = ( p.tau1D * d.stdv ), cv = ( p.tau1D * d.cv ), fixPolarity = 1 )
	endif
	
	if ( ( p.amp2 != 0 ) && ( p.tau2 > 0 ) )
		pstr += NMPulseParamList( "amp2", p.amp2, delta = ( p.amp2D * d.delta ), stdv = ( p.amp2D * d.stdv ), cv = ( p.amp2D * d.cv ) )
		pstr += NMPulseParamList( "tau2", abs( p.tau2 ), delta = ( p.tau2D * d.delta ), stdv = ( p.tau2D * d.stdv ), cv = ( p.tau2D * d.cv ), fixPolarity = 1 )
	endif
	
	if ( ( p.amp3 != 0 ) && ( p.tau3 > 0 ) )
		pstr += NMPulseParamList( "amp3", p.amp3, delta = ( p.amp3D * d.delta ), stdv = ( p.amp3D * d.stdv ), cv = ( p.amp3D * d.cv ) )
		pstr += NMPulseParamList( "tau3", abs( p.tau3 ), delta = ( p.tau3D * d.delta ), stdv = ( p.tau3D * d.stdv ), cv = ( p.tau3D * d.cv ), fixPolarity = 1 )
	endif
	
	return pstr
	
End // NMPulseSynExp4ParamList

//****************************************************************
//****************************************************************

Structure NMPulseSin

	Variable period, periodD, cosine

EndStructure

//****************************************************************
//****************************************************************

Function NMPulseSinInit( p [ pdf, paramList, cosine, DSCG ] )
	STRUCT NMPulseSin &p
	String pdf, paramList
	Variable cosine, DSCG
	
	String vp
	
	if ( cosine )
		vp = promptPrefix + "Cos"
		p.cosine = 1
	else
		vp = promptPrefix + "Sin"
	endif
	
	if ( ParamIsDefault( pdf ) )
		p.period = periodDefault
		p.periodD = 0
	else
		p.period = abs( NumVarOrDefault( pdf + vp + "Period", periodDefault ) )
		p.periodD = NumVarOrDefault( pdf + vp + "PeriodD", 0 )
	endif
	
	if ( ParamIsDefault( paramList ) || ( strlen( paramList ) == 0 ) )
		return 0
	endif
	
	if ( ParamIsDefault( DSCG ) )
		DSCG = NaN
	endif
	
	p.period = NMPulseNumByKey( "period", paramList, p.period, DSCG = DSCG, positive = 1 )
	p.periodD = NMPulseNumByKeyDSCG( "period", paramList )
	
End // NMPulseSinSave

//****************************************************************
//****************************************************************

Function /S NMPulseSinSave( p [ pdf, saveD ] )
	STRUCT NMPulseSin &p
	String pdf
	Variable saveD
	
	String vp = promptPrefix + "Sin"
	
	if ( p.cosine )
		vp = promptPrefix + "Cos"
	endif
	
	if ( ParamIsDefault( pdf ) )
		pdf = NMPulseDF
	endif
	
	zSetVarD( pdf, vp, "Period", abs( p.period ), p.periodD, saveD )
	
End // NMPulseSinSave

//****************************************************************
//****************************************************************

Function NMPulseSinSaveToWaves( a, p, s )
	STRUCT NMPulseAOW &a
	STRUCT NMPulseSin &p
	STRUCT NMPulseSaveToWaves &s
	
	s.wavePrefix = paramWavePrefix + "Sin_"
	
	if ( p.cosine )
		s.pulseType = "Cos"
	else
		s.pulseType = "Sin"
	endif
	
	NMPulseAOWsaveToWaves( a, s )
	
	zSaveToWave( s, "Period", abs( p.period ), p.periodD )
	
End // NMPulseSinSaveToWaves

//****************************************************************
//****************************************************************

Function /S NMPulseSinParamList( p [ DSC ] )
	STRUCT NMPulseSin &p
	String DSC // "delta" or "stdv" or "cv"
	
	STRUCT DSC d
	
	if ( ParamIsDefault( DSC ) )
		DSC = ""
	endif
	
	DSCinit( d, DSC )
	
	return NMPulseParamList( "period", abs( p.period ), delta = ( p.periodD * d.delta ), stdv = ( p.periodD * d.stdv ), cv = ( p.periodD * d.cv ), fixPolarity = 1 )
	
End // NMPulseSinParamList

//****************************************************************
//****************************************************************

Structure NMPulseSinZap

	Variable periodBgn, periodEnd
	Variable periodBgnD, periodEndD

EndStructure

//****************************************************************
//****************************************************************

Function NMPulseSinZapInit( p [ pdf, paramList, DSCG ] )
	STRUCT NMPulseSinZap &p
	String pdf, paramList
	Variable DSCG
	
	String vp = promptPrefix + "SinZap"
	
	if ( ParamIsDefault( pdf ) )
		p.periodBgn = periodBgnDefault
		p.periodBgnD = 0
		p.periodEnd = periodEndDefault
		p.periodEndD = 0
	else
		p.periodBgn = abs( NumVarOrDefault( pdf + vp + "PeriodBgn", periodBgnDefault ) )
		p.periodBgnD = NumVarOrDefault( pdf + vp + "PeriodBgnD", 0 )
		p.periodEnd = abs( NumVarOrDefault( pdf + vp + "PeriodEnd", periodEndDefault ) )
		p.periodEndD = NumVarOrDefault( pdf + vp + "PeriodEndD", 0 )
	endif
	
	if ( ParamIsDefault( paramList ) || ( strlen( paramList ) == 0 ) )
		return 0
	endif
	
	if ( ParamIsDefault( DSCG ) )
		DSCG = NaN
	endif
	
	p.periodBgn = NMPulseNumByKey( "periodBgn", paramList, p.periodBgn, DSCG = DSCG, positive = 1 )
	p.periodBgnD = NMPulseNumByKeyDSCG( "periodBgn", paramList )
	p.periodEnd = NMPulseNumByKey( "periodEnd", paramList, p.periodEnd, DSCG = DSCG, positive = 1 )
	p.periodEndD = NMPulseNumByKeyDSCG( "periodEnd", paramList )
	
End // NMPulseDefaultsToStrucSinZap

//****************************************************************
//****************************************************************

Function /S NMPulseSinZapSave( p [ pdf, saveD ] )
	STRUCT NMPulseSinZap &p
	String pdf
	Variable saveD
	
	String vp = promptPrefix + "SinZap"
	
	zSetVarD( pdf, vp, "PeriodBgn", abs( p.periodBgn ), p.periodBgnD, saveD )
	zSetVarD( pdf, vp, "PeriodEnd", abs( p.periodEnd ), p.periodEndD, saveD )
	
End // NMPulseSinZapSave

//****************************************************************
//****************************************************************

Function NMPulseSinZapSaveToWaves( a, p, s )
	STRUCT NMPulseAOW &a
	STRUCT NMPulseSinZap &p
	STRUCT NMPulseSaveToWaves &s
	
	s.wavePrefix = paramWavePrefix + "SinZap_"
	s.pulseType = "SinZap"
	
	NMPulseAOWsaveToWaves( a, s )
	
	zSaveToWave( s, "PeriodBgn", abs( p.periodBgn ), p.periodBgnD )
	zSaveToWave( s, "PeriodEnd", abs( p.periodEnd ), p.periodEndD )
	
End // NMPulseSinSaveToWaves

//****************************************************************
//****************************************************************

Function /S NMPulseSinZapParamList( p [ DSC ] )
	STRUCT NMPulseSinZap &p
	String DSC // "delta" or "stdv" or "cv"
	
	String pstr = ""
	
	STRUCT DSC d
	
	if ( ParamIsDefault( DSC ) )
		DSC = ""
	endif
	
	DSCinit( d, DSC )
	
	pstr += NMPulseParamList( "periodBgn", abs( p.periodBgn ), delta = ( p.periodBgnD * d.delta ), stdv = ( p.periodBgnD * d.stdv ), cv = ( p.periodBgnD * d.cv ), fixPolarity = 1 )
	pstr += NMPulseParamList( "periodEnd", abs( p.periodEnd ), delta = ( p.periodEndD * d.delta ), stdv = ( p.periodEndD * d.stdv ), cv = ( p.periodEndD * d.cv ), fixPolarity = 1 )
	
	return pstr
	
End // NMPulseSinZapParamList

//****************************************************************
//****************************************************************

Static Function zSetVarD( pdf, vp, varName, value, valueD, saveD )
	String pdf, vp, varName
	Variable value, valueD, saveD
	
	SetNMvar( pdf + vp + varName, value )
	
	if ( saveD )
		SetNMvar( pdf + vp + varName + "D", valueD )
	endif
	
End // zSetVarD

//****************************************************************
//****************************************************************

Static Function zFoundDSC( DSC )
	String DSC
	
	if ( StringMatch( DSC, "delta" ) || StringMatch( DSC, "stdv" ) || StringMatch( DSC, "cv" ) )
		return 1
	endif
	
	return 0
	
End // zFoundDSC

//****************************************************************
//****************************************************************

Function /S NMPulseParamList( varName, value [ delta, stdv, cv, gammaA, gammaB, fixPolarity ] )
	String varName
	Variable value
	Variable delta, stdv, cv, gammaA, gammaB
	Variable fixPolarity
	
	Variable DSCG
	
	String pstr = varName + "=" + num2str( value )
	
	if ( !ParamIsDefault( delta ) && ( numtype( delta ) == 0 ) && ( delta != 0 ) )
		pstr += ",delta=" + num2str( delta )
		DSCG = 1
	elseif ( !ParamIsDefault( stdv ) && ( numtype( stdv ) == 0 ) && ( stdv != 0 ) )
		pstr += ",stdv=" + num2str( stdv )
		DSCG = 1
	elseif ( !ParamIsDefault( cv ) && ( numtype( cv ) == 0 ) && ( cv != 0 ) )
		pstr += ",cv=" + num2str( cv )
		DSCG = 1
	elseif ( !ParamIsDefault( gammaA ) && ( numtype( gammaA ) == 0 ) && ( gammaA != 0 ) )
		if ( !ParamIsDefault( gammaB ) && ( numtype( gammaB ) == 0 ) && ( gammaB != 0 ) )
			pstr += ",gammaA=" + num2str( gammaA ) + ",gammaB=" + num2str( gammaB )
			DSCG = 1
		endif
	endif
	
	if ( DSCG && fixPolarity )
		pstr += ",FP"
	endif
	
	return pstr + ";"
	
End // NMPulseParamList

//****************************************************************
//****************************************************************

Static Function zSaveToWave( s, varName, value, valueD )
	STRUCT NMPulseSaveToWaves &s
	String varName
	Variable value, valueD
	
	if ( ( s.binomialN > 0 ) && StringMatch( varName, "amp" ) )
		// continue
	elseif ( s.plasticity && StringMatch( varName, "amp" ) )
		// continue
	elseif ( valueD == 0 )
		return 0 // param does not vary, so no need to save
	endif
	
	if ( s.failure )
		value = NaN
	endif
	
	if ( s.pulsesPerConfig > 1 )
	
		if ( s.numWaves > 1 )
		
			if ( s.binomialN > 1 )
				zSaveToWave3Dwpt( s, varName, value ) // wave, pulse, trial
			else
				zSaveToWave2Dwp( s, varName, value ) // wave, pulse
			endif
		
		else
			
			if ( s.binomialN > 1 )
				zSaveToWave2Dpt( s, varName, value ) // pulse, trial
			else
				zSaveToWave1Dp( s, varName, value ) // pulse
			endif
			
		endif
	
	else
	
		if ( s.binomialN > 1 )
			zSaveToWave2Dwt( s, varName, value ) // wave, trial
		else
			zSaveToWave1Dw( s, varName, value ) // wave
		endif
	
	endif
	
End // zSaveToWave

//****************************************************************
//****************************************************************

Static Function zSaveToWave1Dw( s, varName, value )
	STRUCT NMPulseSaveToWaves &s
	String varName
	Variable value
	
	String wName = "PC" + num2istr( s.pulseConfigNum ) + "_" + s.pulseType + "_" + varName
	
	if ( !WaveExists( $s.sf + wName ) )
		Make /O/N=( s.numWaves ) $s.sf + wName = NaN
	else
		Redimension /N=( s.numWaves ) $s.sf + wName
	endif
	
	Wave wtemp = $s.sf + wName
	
	if ( ( DimSize( wtemp, 0 ) == s.numWaves ) && ( DimSize( wtemp, 1 ) == 0 ) )
		if ( s.waveNum < DimSize( wtemp, 0 ) )
			wtemp[ s.waveNum ] = value
		endif
	endif
	
End // zSaveToWave1Dw

//****************************************************************
//****************************************************************

Static Function zSaveToWave2Dwt( s, varName, value )
	STRUCT NMPulseSaveToWaves &s
	String varName
	Variable value
	
	String wName = "PC" + num2istr( s.pulseConfigNum ) + "_" + s.pulseType + "_" + varName
	
	if ( !WaveExists( $s.sf + wName ) )
		Make /O/N=( s.numWaves, s.binomialN ) $s.sf + wName = NaN
	else
		Redimension /N=( s.numWaves, s.binomialN ) $s.sf + wName
	endif
	
	Wave wtemp = $s.sf + wName
	
	if ( ( s.waveNum < 0 ) || ( s.waveNum >= s.numWaves ) )
		return -1
	endif
	
	if ( ( s.pulseNum < 0 ) || ( s.trial >= s.binomialN ) )
		return -1
	endif
	
	if ( ( s.waveNum < DimSize( wtemp, 0 ) ) && ( s.trial < DimSize( wtemp, 1 ) ) )
		wtemp[ s.waveNum ][ s.trial ] = value
	endif
	
End // zSaveToWave2Dwt

//****************************************************************
//****************************************************************

Static Function zSaveToWave3Dwpt( s, varName, value )
	STRUCT NMPulseSaveToWaves &s
	String varName
	Variable value
	
	String wName = "PC" + num2istr( s.pulseConfigNum ) + "_" + s.pulseType + "_" + varName
	
	if ( !WaveExists( $s.sf + wName ) )
		Make /O/N=( s.numWaves, s.pulsesPerConfig, s.binomialN ) $s.sf + wName = NaN
	else
		Redimension /N=( s.numWaves, s.pulsesPerConfig, s.binomialN ) $s.sf + wName
	endif
	
	Wave wtemp = $s.sf + wName
	
	if ( ( s.waveNum < 0 ) || ( s.waveNum >= s.numWaves ) )
		return -1
	endif
	
	if ( ( s.pulseNum < 0 ) || ( s.pulseNum >= s.pulsesPerConfig ) )
		return -1
	endif
	
	if ( ( s.trial < 0 ) || ( s.trial >= s.binomialN ) )
		return -1
	endif
	
	if ( ( s.waveNum < DimSize( wtemp, 0 ) ) && ( s.pulseNum < DimSize( wtemp, 1 ) ) && ( s.trial < DimSize( wtemp, 2 ) ) )
		wtemp[ s.waveNum ][ s.pulseNum ][ s.trial ] = value
	endif
	
End // zSaveToWave3Dwpt

//****************************************************************
//****************************************************************

Static Function zSaveToWave2Dwp( s, varName, value )
	STRUCT NMPulseSaveToWaves &s
	String varName
	Variable value
	
	String wName = "PC" + num2istr( s.pulseConfigNum ) + "_" + s.pulseType + "_" + varName
	
	if ( !WaveExists( $s.sf + wName ) )
		Make /O/N=( s.numWaves, s.pulsesPerConfig ) $s.sf + wName = NaN
	else
		Redimension /N=( s.numWaves, s.pulsesPerConfig ) $s.sf + wName
	endif
	
	Wave wtemp = $s.sf + wName
	
	if ( ( s.waveNum < 0 ) || ( s.waveNum >= s.numWaves ) )
		return -1
	endif
	
	if ( ( s.pulseNum < 0 ) || ( s.pulseNum >= s.pulsesPerConfig ) )
		return -1
	endif
	
	if ( ( s.waveNum < DimSize( wtemp, 0 ) ) && ( s.pulseNum < DimSize( wtemp, 1 ) ) )
		wtemp[ s.waveNum ][ s.pulseNum ] = value
	endif
	
End // zSaveToWave2Dwp

//****************************************************************
//****************************************************************

Static Function zSaveToWave2Dpt( s, varName, value )
	STRUCT NMPulseSaveToWaves &s
	String varName
	Variable value
	
	String wName = "PC" + num2istr( s.pulseConfigNum ) + "_" + s.pulseType + "_" + varName
	
	if ( !WaveExists( $s.sf + wName ) )
		Make /O/N=( s.pulsesPerConfig, s.binomialN ) $s.sf + wName = NaN
	else
		Redimension /N=( s.pulsesPerConfig, s.binomialN ) $s.sf + wName
	endif
	
	Wave wtemp = $s.sf + wName
	
	if ( ( s.pulseNum < 0 ) || ( s.pulseNum >= s.pulsesPerConfig ) )
		return -1
	endif
	
	if ( ( s.trial < 0 ) || ( s.trial >= s.binomialN ) )
		return -1
	endif
	
	if ( ( s.pulseNum < DimSize( wtemp, 0 ) ) && ( s.trial < DimSize( wtemp, 1 ) ) )
		wtemp[ s.pulseNum ][ s.trial ] = value
	endif
	
End // zSaveToWave2Dpt

//****************************************************************
//****************************************************************

Static Function zSaveToWave1Dp( s, varName, value )
	STRUCT NMPulseSaveToWaves &s
	String varName
	Variable value
	
	String wName = "PC" + num2istr( s.pulseConfigNum ) + "_" + s.pulseType + "_" + varName
	
	if ( !WaveExists( $s.sf + wName ) )
		Make /O/N=( s.pulsesPerConfig ) $s.sf + wName = NaN
	else
		Redimension /N=( s.pulsesPerConfig ) $s.sf + wName
	endif
	
	Wave wtemp = $s.sf + wName
	
	if ( ( s.pulseNum < 0 ) || ( s.pulseNum >= s.pulsesPerConfig ) )
		return -1
	endif
	
	if ( s.pulseNum < DimSize( wtemp, 0 ) )
		wtemp[ s.pulseNum ] = value
	endif
	
End // zSaveToWave1Dp

//****************************************************************
//****************************************************************
//
//	Plasticity Functions
//
//****************************************************************
//****************************************************************

Function /S NMPulseTimes2WaveSTD2( wList, waveformName, Rdelta, tauR ) // NOT USED
	String wList // list of waves returned from NMRateToRandomTrain
	String waveformName // name of wave containing impulse waveform, or ("") for simple impulse train of 1's
	Variable Rdelta // depression scale factor ( e.g. 0.5 )
	Variable tauR // depression recovery time constant ( e.g. 40 ms )
	
	Variable wcnt, dx, waveLength
	String wName, waveOfPulseTimes, outputWaveName, wList2 = ""
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( !WaveExists( $wName ) )
			continue
		endif
		
		dx = deltax( $wName )
		waveLength = rightx( $wName )
		
		waveOfPulseTimes = "P_Times_" + wName
		outputWaveName = "STD_" + wName
		
		wList2 = AddListItem( outputWaveName, wList2, ";", inf )
		
		NMPulseTimes2WaveSTD( waveOfPulseTimes, waveformName, outputWaveName, dx, waveLength, Rdelta, tauR, 1, 9999 )
	
	endfor
	
	return wList2

End // NMPulseTimes2WaveSTD2

//****************************************************************
//****************************************************************

Function NMPulseTimes2WaveSTD( waveOfPulseTimes, waveformName, outputWaveName, waveLength, dx, Dscale, tauD, Fscale, tauF [ Dmin, Fmax ] ) // NOT USED
	String waveOfPulseTimes
	String waveformName // name of wave containing impulse waveform, or ("") for simple impulse train of 1's
	String outputWaveName
	Variable waveLength, dx // wave length and time step of output wave (ms)
	Variable Dscale // depression scale factor ( 1 ) for none
	Variable tauD // depression recovery time constant (ms)
	Variable Fscale // facilitation increment factor ( 1 ) for none
	Variable tauF // facilitation recovery time constant (ms)
	Variable Dmin // lower limit for D ( default - no limit )
	Variable Fmax // upper limit for F ( default - no limit )
	
	Variable icnt, pnt, xpnts, userWaveform
	Variable tvalue, D, F, intvl
	Variable maxF = 1, minD = 1
	
	if ( ParamIsDefault( Dmin ) )
		Dmin = 0
	endif
	
	if ( ParamIsDefault( Fmax ) )
		Fmax = inf
	endif
	
	if ( ( strlen( waveOfPulseTimes ) == 0 ) || !WaveExists( $waveOfPulseTimes ) )
		return -1
	endif
	
	if ( ( Dscale <= 0 ) || ( Dscale > 1 ) || ( Fscale < 0 ) )
		return -1
	endif
	
	if ( strlen( waveformName ) > 0 )
		if ( !WaveExists( $waveformName ) )
			return -1
		else
			userWaveform = 1
		endif
	endif
	
	xpnts = 1 + waveLength / dx
	
	Make /O/N=( xpnts ) $outputWaveName = 0
	Setscale /P x 0, dx, $outputWaveName
	
	Wave wtemp = $outputWaveName
	Wave times = $waveOfPulseTimes
	
	for ( icnt = 0 ; icnt < numpnts( times ) ; icnt += 1 )
		
		tvalue = times[ icnt ]
		
		if ( numtype( tvalue ) > 0 )
			continue
		endif
			
		pnt = x2pnt( wtemp, tvalue )
		
		if ( ( pnt < 0 ) || ( pnt >= xpnts ) )
			continue
		endif
		
		if ( ( icnt == 0 ) || ( Dscale == 1 ) )
		
			D = 1
		
		else
		
			intvl = tvalue - times[ icnt - 1 ]
			D = 1 + ( D - 1 ) * exp( -intvl / tauD ) // recovery
		
		endif
		
		if ( ( icnt == 0 ) || ( Fscale <= 1 ) )
		
			F = 1
		
		else
		
			intvl = tvalue - times[ icnt - 1 ]
			F = 1 + ( F - 1 ) * exp( -intvl / tauF ) // recovery
		
		endif
		
		wtemp[ pnt ] = D * F
		
		D *= Dscale
		
		F *= Fscale
		//F += Fscale
		
		D = max( Dmin, D )
		F = min( Fmax, F )
		
		//maxF = max( maxF, F )
		//minD = min( minD, D )
		
	endfor
	
	if ( userWaveform )
		Convolve $waveformName wtemp
		Redimension /N=( xpnts ) wtemp
	endif

	return 0

End // NMPulseTimes2WaveSTD

//****************************************************************
//****************************************************************

Function NMSTD( w,x ) : FitFunc // DOES NOT SEEM TO WORK
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = STD model
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 5
	//CurveFitDialog/ w[0] = scale
	//CurveFitDialog/ w[1] = D
	//CurveFitDialog/ w[2] = tauR
	//CurveFitDialog/ w[3] = F
	//CurveFitDialog/ w[4] = tauP
	
	Variable waveLength, dx, pnt
	
	Variable Rdelta = w[ 1 ]
	Variable tauR = w[ 2 ]
	Variable Pscale = w[ 3 ]
	Variable tauP = w[ 4 ]
	
	Variable freq = 100
	Variable grpNum = 0
	
	String waveOfPulseTimes = "gp" + num2str( grpNum ) + "_" + num2str( freq ) + "hz_times"
	String impulseWaveName = "gp" + num2str( grpNum ) + "_" + num2str( freq ) + "hz_impulse"
	String waveformName = "NMDApulse"
	String outputWaveName = "U_NMSTD"
	
	waveLength = rightx( $impulseWaveName )
	dx = deltax( $impulseWaveName )
	
	NMPulseTimes2WaveSTD( waveOfPulseTimes, waveformName, outputWaveName, waveLength, dx, Rdelta, tauR, Pscale, tauP )
	
	Wave wtemp = $outputWaveName
	
	pnt = x2pnt( wtemp, x )
	
	if ( ( pnt >= 0 ) && ( pnt < numpnts( wtemp ) ) )
		return w[ 0 ] * wtemp[ pnt ]
	else
		return NaN
	endif
	
End // NMSTD

//****************************************************************
//****************************************************************

Function /S NMPulseSynExp4_GC_AMPAdirect( [ model, year, amp, p ] )
	String model // "Digregorio" or "Sargent" or "Rothman"
	Variable year // 2002 or 2005 or 2012
	Variable amp // amplitude value
	STRUCT NMPulseSynExp4 &p
	STRUCT NMPulseSynExp4 pp
	
	String pList = "pulse=synexp4;"
	
	if ( !ParamIsDefault( amp ) && ( numtype( amp ) == 0 ) )
		pList += "amp=" + num2str( amp ) + ";"
	endif
	
	if ( ParamIsDefault( model ) )
	
		if ( ParamIsDefault( year ) )
			
			return ""
			
		else
		
			if ( year == 2002 )
				model = "Digregorio"
			elseif ( year == 2005 )
				model = "Sargent"
			elseif ( year == 2012 )
				model = "Rothman"
			else
				return ""
			endif
			
		endif
	
	endif
	
	if ( !ParamIsDefault( p ) )
		pp = p
	endif
	
	strswitch( model )
	
		case "Digregorio": // 2002
			pp.tauRise = 0.1849
			pp.power = 1.1267
			pp.amp1 = 86.49
			pp.tau1 = 0.3555
			pp.amp2 = 13.51
			pp.tau2 = 2.3025
			pp.amp3 = 0
			pp.tau3 = 999
			break
			
		case "Sargent": // 2005
			pp.tauRise = 0.116
			pp.power = 1.0
			pp.amp1 = 86.72
			pp.tau1 = 0.36
			pp.amp2 = 13.28
			pp.tau2 = 2.034
			pp.amp3 = 0
			pp.tau3 = 999
			break
			
		case "Rothman": // 2012
			pp.tauRise = 0.16
			pp.power = 1.94
			pp.amp1 = 89.38
			pp.tau1 = 0.32
			pp.amp2 = 9.57
			pp.tau2 = 1.73
			pp.amp3 = 1.05
			pp.tau3 = 19.69
			break
			
		default:
			return ""
			
	endswitch
	
	return pList + NMPulseSynExp4ParamList( pp )
	
End // NMPulseSynExp4_GC_AMPAdirect

//****************************************************************
//****************************************************************

Function /S NMPulseExp_GC_AMPAdirect( [ select, p ] ) // Billings 2014
	Variable select // 0 or 1
	STRUCT NMPulseExp &p
	STRUCT NMPulseExp pp
	
	Variable amp = NaN
	
	if ( !ParamIsDefault( p ) )
		pp = p
	endif
	
	pp.amp1 = -1
	pp.tau1 = 0.3274 // ms
	
	pp.amp2 = 1
	
	switch( select )
		case 0:
			amp = 3.724 // nS
			pp.tau2 =  0.3351 // ms
			break
		case 1:
			amp = 0.3033 // nS
			pp.tau2 = 1.651 // ms
			break
	endswitch
	
	pp.amp3 = 0
	pp.amp4 = 0
	
	return "pulse=exp;amp=" + num2str( amp ) + ";" + NMPulseExpParamList( pp )
	
End // NMPulseExp_GC_AMPAdirect

//****************************************************************
//****************************************************************

Function /S NMPulseTrainDF_GC_AMPAdirect( [ p ] )
	STRUCT NMPulseTrainDF &p
	STRUCT NMPulseTrainDF pp
	
	if ( !ParamIsDefault( p ) )
		pp = p
	endif
	
	// Rothman 2012
	
	pp.Dinf = 1
	pp.Dmin = 0.1
	pp.tauD = 50
	pp.Dscale = 0.6
	pp.Finf = 1
	pp.Fmax = 1
	pp.tauF = -1 // this turns F off
	pp.Fscale = 1
	
	return NMPulseTrainDFparamList( pp )

End // NMPulseTrainDF_GC_AMPAdirect

//****************************************************************
//****************************************************************

Function /S NMPulseTrainRP_GC_AMPAdirect( [ p ] )
	STRUCT NMPulseTrainRP &p
	STRUCT NMPulseTrainRP pp
	
	if ( !ParamIsDefault( p ) )
		pp = p
	endif
	
	// Billings 2014
	
	pp.Rinf = 1
	pp.Rmin = 0
	pp.tauR = 131
	pp.Pinf = 0.1249
	pp.Pmax = inf
	pp.tauP = -1 // this turns P off
	pp.Pscale = 0
	
	return NMPulseTrainRPparamList( pp )

End // NMPulseTrainRP_GC_AMPAdirect

//****************************************************************
//****************************************************************

Function /S NMPulseSynExp4_GC_AMPAspill( [ model, year, amp, p ] )
	String model // "Digregorio" or "Rothman"
	Variable year // 2002 ( Digregorio ) or 2012 ( Rothman )
	Variable amp // amplitude value
	STRUCT NMPulseSynExp4 &p
	STRUCT NMPulseSynExp4 pp
	
	if ( ParamIsDefault( model ) )
	
		if ( ParamIsDefault( year ) )
			
			return ""
			
		else
		
			if ( year == 2002 )
				model = "Digregorio"
			elseif ( year == 2012 )
				model = "Rothman"
			else
				return ""
			endif
			
		endif
	
	endif
	
	if ( ParamIsDefault( amp ) )
		amp = 1
	endif
	
	if ( !ParamIsDefault( p ) )
		pp = p
	endif
	
	strswitch( model )
	
		case "Digregorio":
			pp.tauRise = 0.4
			pp.power = 1.799
			pp.amp1 = 53.0
			pp.tau1 = 2.657
			pp.amp2 = 47.0
			pp.tau2 = 7.169
			pp.amp3 = 0
			pp.tau3 = 999
			break
		
		case "Rothman":
			pp.tauRise = 0.38
			pp.power = 1.74
			pp.amp1 = 42.78
			pp.tau1 = 1.38
			pp.amp2 = 53.59
			pp.tau2 = 7.27
			pp.amp3 = 3.63
			pp.tau3 = 30.86
			break
			
		default:
			return ""

	endswitch
	
	return "pulse=synexp4;amp=" + num2str( amp ) + ";" + NMPulseSynExp4ParamList( pp )
	
End // NMPulseSynExp_GC_AMPAspill2002

//****************************************************************
//****************************************************************

Function /S NMPulseExp_GC_AMPAspill( [ select, p ] ) // Billings 2014
	Variable select // 0 or 1 or 2
	STRUCT NMPulseExp &p
	STRUCT NMPulseExp pp
	
	Variable amp = NaN
	
	if ( !ParamIsDefault( p ) )
		pp = p
	endif
	
	pp.amp1 = -1
	pp.tau1 = 0.5548 // ms
	
	pp.amp2 = 1
	
	switch( select )
	
		case 0:
			amp = 0.2487 // nS
			pp.tau2 = 0.4 // ms
			break
			
		case 1:
			amp = 0.2799 // nS
			pp.tau2 = 4.899 // ms
			break
			
		case 2:
			amp = 0.1268 // nS
			pp.tau2 = 43.1 // ms
			break
	
		default:
			return ""
			
	endswitch
	
	return "pulse=exp;amp=" + num2str( amp ) + ";" + NMPulseExpParamList( pp )
	
End // NMPulseExp_GC_AMPAspill

//****************************************************************
//****************************************************************

Function /S NMPulseTrainDF_GC_AMPAspill( [ p ] )
	STRUCT NMPulseTrainDF &p
	STRUCT NMPulseTrainDF pp
	
	if ( !ParamIsDefault( p ) )
		pp = p
	endif
	
	// Rothman 2012
	
	pp.Dinf = 1
	pp.Dmin = 0.6
	pp.tauD = 50
	pp.Dscale = 0.95
	pp.Finf = 1
	pp.Fmax = 1
	pp.tauF = -1 // this turns F off
	pp.Fscale = 1
	
	return NMPulseTrainDFparamList( pp )

End // NMPulseTrainDF_GC_AMPAspill

//****************************************************************
//****************************************************************

Function /S NMPulseTrainRP_GC_AMPAspill( [ p ] )
	STRUCT NMPulseTrainRP &p
	STRUCT NMPulseTrainRP pp
	
	if ( !ParamIsDefault( p ) )
		pp = p
	endif
	
	// Billings 2014
	
	pp.Rinf = 1
	pp.Rmin = 0
	pp.tauR = 14.85
	pp.Pinf = 0.2792
	pp.Pmax = inf
	pp.tauP = -1 // this turns P off
	pp.Pscale = 0
	
	return NMPulseTrainRPparamList( pp )

End // NMPulseTrainRP_GC_AMPAspill

//****************************************************************
//****************************************************************

Function /S NMPulseSynExp4_GC_NMDA( [ amp, p ] )
	Variable amp // amplitude value
	STRUCT NMPulseSynExp4 &p
	STRUCT NMPulseSynExp4 pp
	
	if ( ParamIsDefault( amp ) )
		amp = 1
	endif
	
	if ( !ParamIsDefault( p ) )
		pp = p
	endif
	
	// Rothman 2012
	
	pp.tauRise = 1.14
	pp.power = 1
	pp.amp1 = 64.12
	pp.tau1 = 8.10
	pp.amp2 = 35.88
	pp.tau2 = 37.00
	pp.amp3 = 0
	pp.tau3 = 999
	
	return "pulse=synexp4;amp=" + num2str( amp ) + ";" + NMPulseSynExp4ParamList( pp )
	
End // NMPulseSynExp4_GC_NMDA

//****************************************************************
//****************************************************************

Function /S NMPulseExp_GC_NMDA( [ select, p ] ) // Billings 2014
	Variable select // 0 or 1
	STRUCT NMPulseExp &p
	STRUCT NMPulseExp pp
	
	Variable amp = NaN
	
	if ( !ParamIsDefault( p ) )
		pp = p
	endif
	
	pp.amp1 = -1
	pp.tau1 = 0.8647 // ms
	
	pp.amp2 = 1
	
	switch( select )
	
		case 0:
			amp = 17 // nS
			pp.tau2 = 13.52 // ms
			break
			
		case 1:
			amp = 2.645 // nS
			pp.tau2 = 121.9 // ms
			break
	
		default:
			return ""
			
	endswitch
	
	return "pulse=exp;amp=" + num2str( amp ) + ";" + NMPulseExpParamList( pp )
	
End // NMPulseExp_GC_NMDA

//****************************************************************
//****************************************************************

Function /S NMPulseTrainDF_GC_NMDA( [ p ] )
	STRUCT NMPulseTrainDF &p
	STRUCT NMPulseTrainDF pp
	
	if ( !ParamIsDefault( p ) )
		pp = p
	endif
	
	// Rothman 2012
	
	pp.Dinf = 1
	pp.Dmin = 0.1
	pp.tauD = 70
	pp.Dscale = 0.9
	pp.Finf = 1
	pp.Fmax = 3.4
	pp.tauF = 3.5
	pp.Fscale = 1.7
	
	return NMPulseTrainDFparamList( pp )

End // NMPulseTrainDF_GC_NMDA

//****************************************************************
//****************************************************************

Function /S NMPulseTrainRP_GC_NMDA( [ p ] )
	STRUCT NMPulseTrainRP &p
	STRUCT NMPulseTrainRP pp
	
	if ( !ParamIsDefault( p ) )
		pp = p
	endif
	
	// Billings 2014
	
	pp.Rinf = 1
	pp.Rmin = 0
	pp.tauR = 236.1
	pp.Pinf = 0.0322
	pp.Pmax = inf
	pp.tauP = 6.394
	pp.Pscale = 0.0322
	
	return NMPulseTrainRPparamList( pp )

End // NMPulseTrainRP_GC_NMDA

//****************************************************************
//****************************************************************

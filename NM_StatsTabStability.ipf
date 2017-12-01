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
//	Spearman Rank-Order Stability Test
//
//	Original Igor code from Dr. Angus Silver and Simon Mitchell
//	Department of Physiology, University College London
//	Spearman Rank-Order macro from Numerical Recipes in C (NRC)
//	PRESS, WV. H., TEUKOLSKY, S. A. VETTERLING, W. T. & FLANNERY, B. P. (1994)
//	Numerical Recipes in C, pp. 623-626. Cambridge University Press, UK.
//
//****************************************************************
//****************************************************************

Static Constant SecondPassRefinement = 0 // ( 0 ) no ( 1 ) yes
Static Constant MinimumSearchWindow = 10 // minimum seach window of consecutive data points

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStabilityCall0()

	NMStabilityCall( "", 1 )

End // NMStabilityCall0

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStabilityStats( wName, wSelect )
	String wName // wave name
	Variable wSelect // NOT USED ANYMORE
	
	String gName, gTitle
	
	gName = NMStabilityCall(wName, 0)
	
	gTitle = "Stability : " + NMChild( wName )
	
	if (strlen(gName) == 0)
		return ""
	endif
	
	DoWindow /T $gName, gTitle
	
	return gName
	
End // NMStabilityStats

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStabilityCall( wName, resultsWave )
	String wName // wave name or ( "" ) for prompt
	Variable resultsWave // NOT USED ANYMORE
	
	Variable pbgn, pend, minArray, sig, win2Frac, pnts
	String wlist, setName = ""
	String sdf = NMStatsDF
	
	String df = NMParent( wName )
	
	CheckNMPackage( "Stats", 1 ) // create Stats Package folder if necessary
	
	Variable refine = 1 + NumVarOrDefault( sdf+"StbRefine", SecondPassRefinement )
	Variable createSet = 1 + NumVarOrDefault( sdf+"StbCreateSet", 0 )
	
	Prompt refine, "perform second pass refinement?", popup "no;yes;"
	Prompt createSet, "save results as a new Set?", popup "no;yes;"
	
	if ( strlen( wName ) == 0 )
	
		wlist = WaveList( "*", ";", "Text:0" )
		
		Prompt wName, "select wave:", popup wlist
		DoPrompt "Stability Analysis", wName, refine, createSet
		
	else
	
		DoPrompt "Stability Analysis", refine, createSet
		
	endif
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	refine -= 1
	createSet -= 1
		
	SetNMvar( sdf+"StbRefine", refine )
	SetNMvar( sdf+"StbCreateSet", createSet )
		
	//NMStabilityPlot( wName )
	
	pnts = numpnts( $wName )
	pend = pnts - 1
	minArray = NumVarOrDefault( sdf+"StbMinArray", MinimumSearchWindow )
	sig = NumVarOrDefault( sdf+"StbSig", 0.05 )
	win2Frac = NumVarOrDefault( sdf+"StbWin2Frac", 0.5 )
	
	Prompt pbgn, "start wave point:"
	Prompt pend, "end wave point:"
	Prompt sig, "significance level:"
	Prompt win2Frac, "refinement window fraction ( 2nd pass ):"
	
	if ( refine == 0 )
		Prompt minArray, "min search window in points:"
		DoPrompt "Spearman Stability Analysis", pbgn, pend, minArray, sig
		win2Frac = 1
	else
		Prompt minArray, "min search window in points ( 1st pass ):"
		DoPrompt "Spearman Stability Analysis", pbgn, pend, minArray, win2Frac, sig
	endif

	if ( V_flag == 1 )
		return "" // user cancelled
	endif
	
	SetNMvar( sdf+"StbMinArray", minArray )
	SetNMvar( sdf+"StbSig", sig )
	
	if ( refine == 1 )
		SetNMvar( sdf+"StbWin2Frac", win2Frac )
	endif
	
	if ( pend == pnts - 1 )
		pend = inf
	endif
	
	if ( createSet == 1 )
	
		//setName = ReplaceString( "ST_", NMChild( wName ), "" )
		//setName = ReplaceString( "_", NMChild( setName ), "" )
		//setName = "Stable_" + setName
		//setName = setName[ 0,30 ]
		setName = StrVarOrDefault( df + "StabilitySetName", NMSetsNameNext() )
		
		Prompt setName, "output Set name:"
		DoPrompt "Sort Stats Wave", setName
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		if ( strlen( setName ) > 0 )
			SetNMstr( df + "StabilitySetName", setName )
		endif
	
	endif
	
	return NMStabilityRankOrderTest( wName, pbgn, pend, minArray, sig, win2Frac, setName, history = 1 )
	
End // NMStabilityCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStabilityRankOrderTest( wName, pbgn, pend, minArray, significance, win2Frac, setName [ history ] )
	String wName // input wave name
	Variable pbgn, pend // begin/end search point
	Variable minArray // min sliding search window size
	Variable significance // significance level ( 0.05 )
	Variable win2Frac // fraction of minArray for 2nd refinement pass, ( 1 ) for no refinement
	String setName // optional output Set name, ( "" ) for none
	Variable history
	
	Variable useNRC = 1
	
	Variable sf, sg, npnts, numArr, arrPnts, acnt, passes, prob, regrs, stableFrom, stableTo
	Variable pcnt, plast, pfirst = -1, pmax = 0
	Variable thisProb, lastProb, overwrite = 1
	String xl, yl, txt, gName = "", sName, wNameShort, df, vlist = ""
	String wNamePass1, wNamePass2, wNameFitLine
	String wNameAllProbs, wNameSigProbs, wNameSigLine, wNameAllRegrs, wNameSigRegrs
	String outWaveList = "", outWinList = ""
	
	String sdf = NMStatsDF
	
	STRUCT Rect w
	STRUCT NMSpearmanStructure s
	
	String probGraph = NMStabilityGraphName( wName, "STBpr", overwrite ) // "ST_Probs_all_Plot" // probability graph name
	String regGraph = NMStabilityGraphName( wName, "STBrg", overwrite ) // "ST_Regrs_all_Plot" // regression graph name
	
	df = NMParent( wName )
	wNameShort = NMChild( wName )
	
	CheckNMPackage( "Stats", 1 ) // create Stats folder if necessary
	
	String waveNamingFormat = StrVarOrDefault( NMStatsDF+"WaveNamingFormat", "prefix" )
	
	DoWindow /K $probGraph
	DoWindow /K $regGraph
	
	NMOutputListsReset()
	
	if ( ( WaveExists( $wName ) == 0 ) || ( WaveType( $wName ) == 0 ) )
		Abort "Abort NMStability: bad wave name."
	endif
	
	if ( history )
		vlist = NMCmdStr( wName, vlist )
		vlist = NMCmdNum( pbgn, vlist, integer = 1 )
		vlist = NMCmdNum( pend, vlist, integer = 1 )
		vlist = NMCmdNum( minArray, vlist )
		vlist = NMCmdNum( significance, vlist )
		vlist = NMCmdNum( win2Frac, vlist )
		vlist = NMCmdStr( setName, vlist )
		NMCommandHistory( vlist )
	endif
	
	if ( numtype( pbgn ) > 0 )
		pbgn = 0
	endif
	
	if ( numtype( pend ) > 0 )
		pend = numpnts( $wName ) - 1
	endif
	
	if ( pend > 999 )
	
		DoAlert 1, "Warning: this is a large wave. Stability analysis may take a long time. Do you want to continue?"
		
		if ( V_Flag == 2 )
			return ""
		endif
		
	endif
	
	Wave data = $wName
	
	//if ( StringMatch( waveNamingFormat, "prefix" ) == 1 )
	//	wNamePass1 = "STBP1_" + wNameShort
	//else
	//	wNamePass1 = wNameShort + "_STBP1"
	//endif
	
	wNamePass1 = "Stable_Pass1"
	//wNamePass1 = NMCheckStringName( wNamePass1 )
	Duplicate /O $wName $df + wNamePass1
	outWaveList += df + wNamePass1 + ";"
	Wave stable_pass1 = $df + wNamePass1
	
	//if ( StringMatch( waveNamingFormat, "prefix" ) == 1 )
	//	wNameFitLine = "STBLN_" + wNameShort
	//else
	//	wNameFitLine = wNameShort + "_STBLN"
	//endif
	
	wNameFitLine = "Stable_LineFit"
	//wNameFitLine = NMCheckStringName( wNameFitLine )
	Duplicate /O $wName $df + wNameFitLine
	outWaveList += df + wNameFitLine + ";"
	Wave stable_linefit = $df + wNameFitLine
	
	stable_linefit = Nan
	
	//NMHistory( NMCR + "Stability analysis of " + wName )
	
	npnts = pend - pbgn + 1
	
	Make /D/O/N=( npnts ) $NMStatsDF + "ST_inWaveY"
	Make /D/O/N=( npnts ) $NMStatsDF + "ST_inWaveX"
	
	Wave ST_inWaveY = $NMStatsDF + "ST_inWaveY"
	Wave ST_inWaveX = $NMStatsDF + "ST_inWaveX"
	
	ST_inWaveY = data[ p + pbgn ]
	ST_inWaveX = p + pbgn
	
	for ( pcnt = 0; pcnt < npnts; pcnt += 1 )
		if ( numtype( ST_inWaveY[ pcnt ] ) != 0 )
			ST_inWaveX[ pcnt ] = Nan
		endif
	endfor
	
	Sort ST_inWaveY ST_inWaveY, ST_inWaveX // sort according to y-values
	
	//
	// initial check for ties ( equal y-values )
	//
	
	for ( pcnt = 0; pcnt < npnts-1; pcnt+=1 ) 
		if ( ST_inWaveY[ pcnt ] == ST_inWaveY[ pcnt+1 ] )
			Print "Stability Alert: located equal data values at points " + num2str( ST_inWaveX[ pcnt ] ) + " and " + num2str( ST_inWaveX[ pcnt+1 ] ) + " ( " + num2str( ST_inWaveY[ pcnt ] ) + " )"
		endif
	endfor
	
	Sort ST_inWaveX ST_inWaveY, ST_inWaveX // back to original
	
	WaveStats /Q/Z ST_inWaveX // count the number of points, excluding NANs
	
	npnts = V_maxloc+1
	
	Redimension /N=( npnts ) ST_inWaveX, ST_inWaveY // eliminate NANs
	Redimension /N=( npnts ) stable_pass1, stable_linefit
	
	stable_pass1 = ST_inWaveY
	
	//
	// find largest section of data that gives StbProbs > sig
	//
	
	numArr = npnts - minArray + 1 // number of possible arrays, given minArray
	
	for ( acnt = 0; acnt < numArr; acnt+=1 ) // loop thru arrays, from largest to smallest
	
		arrPnts = npnts - acnt
		passes = npnts - arrPnts + 1
		
		Make /D/O/N=( arrPnts ) $NMStatsDF + "ST_xArray"
		Make /D/O/N=( arrPnts ) $NMStatsDF + "ST_yArray"
		
		Wave ST_xArray = $NMStatsDF + "ST_xArray"
		Wave ST_yArray = $NMStatsDF + "ST_yArray"
		
		for ( pcnt = 0; pcnt < passes; pcnt+=1 ) // slide array thru data points
		
			ST_xArray = ST_inWaveX[ pcnt+p ]
			ST_yArray = ST_inWaveY[ pcnt+p ]
			
			StatsRankCorrelationTest /ALPH=( significance )/Q ST_xArray, ST_yArray
			
			Wave W_StatsRankCorrelationTest
			
			Variable SpearmanR = W_StatsRankCorrelationTest[ 4 ]
			Variable critical = W_StatsRankCorrelationTest[ 5 ]
			// try to convert critical value to prob?
			
			if ( useNRC )
			
				NMSpearmanNRC( ST_xArray, ST_yArray, s = s )
				
				prob = s.probrs
				regrs = s.rs
				
			else
				
				Sort ST_yArray ST_yArray, ST_xArray
				sf = NMStabilityRank( ST_yArray )
			
				Sort ST_xArray ST_yArray, ST_xArray
				sg = NMStabilityRank( ST_xArray ) // x-wave will not have any ties
			
				NMStabilityCorr( ST_xArray, ST_yArray, sf, sg )
				
				prob = NumVarOrDefault( NMStatsDF+"StbProbs", 0 )
				regrs = NumVarOrDefault( NMStatsDF+"StbRegrs", 0 )
			
			endif
			
			//print regrs, SpearmanR
			//print prob, critical
			
			if ( ( prob > significance ) && ( prob > pmax ) ) // stable region, save values
				pfirst = pcnt
				pmax = prob
			endif
			
		endfor
		
		if ( pfirst >= 0 )
			break
		endif
	
	endfor
	
	if ( pfirst < 0 ) // no stable region detected
	
		stable_pass1 = Nan
		NMDoAlert( "NMStability Abort: no stable region detected during first stability test. Try using a smaller analysis window." )
		NMStabilityKill()
		return ""
		
	else // first pass through stability analyses, displayed by stable_pass1
	
		plast = pfirst + arrPnts - 1
		
		if ( ( pfirst < numpnts( ST_inWaveX ) ) && ( plast < numpnts( ST_inWaveX ) ) )
			stableFrom = ST_inWaveX[ pfirst ]
			stableTo = ST_inWaveX[ plast ]
		else
			stableFrom = NaN
			stableTo = NaN
		endif
		
		NMHistory( "First pass successful ( " + num2istr( arrPnts ) + " point window ): stable from point " + num2istr( StableFrom ) + " to " + num2istr( StableTo ) )
		
	 	if ( ( pfirst > 0 ) && ( pfirst - 1 < npnts ) )
			stable_pass1[ 0, ( pfirst-1 ) ] = NaN
		endif
		
		if ( plast + 1 <= npnts - 1 )
			stable_pass1[ plast + 1, npnts - 1 ] = NaN
		endif
		
		NMStabilityReplaceNANs( ST_inWaveX, stable_pass1 )
		
	endif
	
	//
	// pass through selected array again with smaller window
	// save results to Probs and Regres waves
	//
	
	if ( win2Frac < 1 )
	
		//if ( StringMatch( waveNamingFormat, "prefix" ) == 1 )
		//	wNamePass2 = "STBP2_" + wNameShort
		//else
		//	wNamePass2 = wNameShort + "_STBP2"
		//endif
		
		wNamePass2 = "Stable_Pass2"
		//wNamePass2 = NMCheckStringName( wNamePass2 )
		Duplicate /O $wName $df + wNamePass2
		outWaveList += df + wNamePass2 + ";"
		Wave STBL_Pass2 = $df + wNamePass2
		
		if ( StringMatch( waveNamingFormat, "prefix" ) == 1 )
			wNameAllProbs = "STBPA_" + wNameShort
		else
			wNameAllProbs = wNameShort + "_STBPA"
		endif
		
		wNameAllProbs = "StableRefine_Probabilities"
		//wNameAllProbs = NMCheckStringName( wNameAllProbs )
		Duplicate /O $wName $df + wNameAllProbs
		outWaveList += df + wNameAllProbs + ";"
		Wave STBL_AllProbs = $df + wNameAllProbs
		
		//if ( StringMatch( waveNamingFormat, "prefix" ) == 1 )
		//	wNameSigProbs = "STBPS_" + wNameShort
		//else
		//	wNameSigProbs = wNameShort + "_STBPS"
		//endif
		
		wNameSigProbs = "StableRefine_ProbabilitiesSig"
		//wNameSigProbs = NMCheckStringName( wNameSigProbs )
		Duplicate /O $wName $df + wNameSigProbs
		outWaveList += df + wNameSigProbs + ";"
		Wave STBL_SigProbs = $df + wNameSigProbs
		
		//if ( StringMatch( waveNamingFormat, "prefix" ) == 1 )
		//	wNameSigLine = "STBPL_" + wNameShort
		//else
		//	wNameSigLine = wNameShort + "_STBPL"
		//endif
		
		wNameSigLine = "StableRefine_Significance"
		//wNameSigLine = NMCheckStringName( wNameSigLine )
		Duplicate /O $wName $df + wNameSigLine
		outWaveList += df + wNameSigLine + ";"
		Wave STBL_SigLine = $df + wNameSigLine
		
		//if ( StringMatch( waveNamingFormat, "prefix" ) == 1 )
		//	wNameAllRegrs = "STBRA_" + wNameShort
		//else
		//	wNameAllRegrs = wNameShort + "_STBRA"
		//endif
		
		wNameAllRegrs = "StableRefine_Regressions"
		//wNameAllRegrs = NMCheckStringName( wNameAllRegrs )
		Duplicate /O $wName $df + wNameAllRegrs
		outWaveList += df + wNameAllRegrs + ";"
		Wave STBL_AllRegrs = $df + wNameAllRegrs
		
		//if ( StringMatch( waveNamingFormat, "prefix" ) == 1 )
		//	wNameSigRegrs = "STBRS_" + wNameShort
		//else
		//	wNameSigRegrs = wNameShort + "_STBRS"
		//endif
		
		wNameSigRegrs = "StableRefine_RegressionsSig"
		//wNameSigRegrs = NMCheckStringName( wNameSigRegrs )
		Duplicate /O $wName $df + wNameSigRegrs
		outWaveList += df + wNameSigRegrs + ";"
		Wave STBL_SigRegrs = $df + wNameSigRegrs
		
		arrPnts = round( arrPnts * win2Frac )
		passes = ( plast - pfirst + 1 ) - arrPnts + 1
		
		Redimension /N=( npnts ) STBL_Pass2
		Redimension /N=( npnts ) STBL_AllProbs, STBL_SigProbs, STBL_AllRegrs, STBL_SigRegrs, STBL_SigLine
		
		STBL_Pass2 = ST_inWaveY
	
		Make /D/O/N=( arrPnts ) $NMStatsDF + "ST_xArray"
		Make /D/O/N=( arrPnts ) $NMStatsDF + "ST_yArray"
		
		Wave ST_xArray = $NMStatsDF + "ST_xArray"
		Wave ST_yArray = $NMStatsDF + "ST_yArray"
		
		STBL_AllProbs = Nan
		STBL_AllRegrs = Nan
		
		for ( pcnt = pfirst; pcnt < pfirst + passes; pcnt+=1 )
		
			ST_xArray = ST_inWaveX[ p+pcnt ]
			ST_yArray = ST_inWaveY[ p+pcnt ]
			
			if ( useNRC )
			
				NMSpearmanNRC( ST_xArray, ST_yArray )
			
			else
			
				Sort ST_yArray ST_yArray, ST_xArray
				sf = NMStabilityRank( ST_yArray )
			
				Sort ST_xArray ST_yArray, ST_xArray
				sg = NMStabilityRank( ST_xArray ) // x-wave will not have any ties
			
				NMStabilityCorr( ST_xArray, ST_yArray, sf, sg )
			
			endif
			
			STBL_AllProbs[ pcnt ] = NumVarOrDefault( NMStatsDF+"StbProbs", 0 )
			STBL_AllRegrs[ pcnt ] = NumVarOrDefault( NMStatsDF+"StbRegrs", 0 )
			
		endfor
		
		STBL_SigProbs = STBL_AllProbs
		STBL_SigRegrs = STBL_AllRegrs
		
		//
		// now locate stretch where Prob > sig
		// JSR 28/04/2016: changed this code to search for LONGEST stretch
		//
		
		Make /O/N=50 $NMStatsDF + "ST_pfirst" = NaN
		Make /O/N=50 $NMStatsDF + "ST_counter" = NaN
		
		Wave pfirstAll = $NMStatsDF + "ST_pfirst"
		Wave counter = $NMStatsDF + "ST_counter"
		
		Variable icnt = 0, imax = -1, counterMax
		
		for ( pcnt = pfirst; pcnt < npnts; pcnt+=1 )
		
			if ( icnt >= numpnts( counter ) )
				break
			endif
		
			lastProb = thisProb
			thisProb = STBL_AllProbs[ pcnt ]
			
			if ( numtype( thisProb ) != 0 )
				break
			endif
			
			if ( thisProb >= significance )
			
				if ( lastProb < significance )
					pfirstAll[ icnt ] = pcnt
					counter[ icnt ] = 1 // transition from sig to non-sig
					continue
				else 	
					counter[ icnt ] += 1 // continuation of non-sig region
				endif
				
			else
			
				if ( lastProb >= significance )
					//break // end of significant region
					icnt += 1 // next region
				endif
			
			endif
			
		endfor
		
		for ( icnt = 0 ; icnt < numpnts( counter ) ; icnt += 1 )
		
			if ( numtype( counter[ icnt ] ) > 0 )
				break
			endif
			
			if ( counter[ icnt ] > counterMax )
				counterMax = counter[ icnt ]
				imax = icnt
			endif
			
		endfor
		
		if ( ( imax < 0 ) || ( imax >= numpnts( counter ) ) )
			NMDoAlert( "NMStability Abort: no stable region detected during second stability test." )
			return ""
		endif
		
		pfirst = pfirstAll[ imax ]
		counterMax = counter[ imax ]
		
		if ( pfirst > 0 )
			STBL_SigProbs[ 0, pfirst - 1 ] = NaN
			STBL_SigRegrs[ 0, pfirst- 1 ] = NaN
		endif
		
		plast = pfirst + counterMax - 1
		
		if ( plast + 1 <= npnts - 1 )
			STBL_SigProbs[ plast + 1, npnts - 1 ] = NaN
			STBL_SigRegrs[ plast + 1, npnts - 1 ] = NaN
		endif
		
		plast = plast + arrPnts - 1
		
		stableFrom = ST_inWaveX[ pfirst ]
		stableTo = ST_inWaveX[ plast ]
		
		NMHistory( "Second pass successful ( " + num2istr( arrPnts ) + " point window ): stable from point " + num2istr( stableFrom ) + " to " + num2istr( stableTo ) )
		
		if ( pfirst > 0 )
			STBL_Pass2[ 0, pfirst - 1 ] = NaN
		endif
		
		if ( plast + 1 <= npnts - 1 )
			STBL_Pass2[ plast + 1, npnts - 1 ] = NaN
		endif
		
		//
		// put NANs back in display waves
		//
		
		NMStabilityReplaceNANs( ST_inWaveX, STBL_Pass2 )
		NMStabilityReplaceNANs( ST_inWaveX, STBL_AllProbs )
		NMStabilityReplaceNANs( ST_inWaveX, STBL_SigProbs )
		NMStabilityReplaceNANs( ST_inWaveX, STBL_SigLine )
		NMStabilityReplaceNANs( ST_inWaveX, STBL_AllRegrs )
		NMStabilityReplaceNANs( ST_inWaveX, STBL_SigRegrs )
	
		//
		// display results
		//
		
		STBL_SigLine = significance
		
		plast = pfirst + counterMax - 1
		
		NMWinCascadeRect( w )
		Display /K=(NMK())/N=$regGraph/W=(w.left,w.top,w.right,w.bottom) STBL_AllRegrs, STBL_SigRegrs as "Stability Analysis : Regression"	 
		Label /W=$regGraph/Z Bottom "First point of " + num2istr( Arrpnts ) + " point window ( second pass )"
		Label /W=$regGraph/Z Left "Regression Coefficent"
		ModifyGraph /W=$regGraph mode( $wNameAllRegrs )=4, marker( $wNameAllRegrs )=19, rgb( $wNameAllRegrs )=(0,0,0)
		ModifyGraph /W=$regGraph mode( $wNameSigRegrs )=4, marker( $wNameSigRegrs )=0, rgb( $wNameSigRegrs )=(65535,0,0)
		//SetAxis /W=$regGraph bottom 0, plast
		OutWinList += regGraph + ";"
		
		NMWinCascadeRect( w )
		Display /K=(NMK())/N=$probGraph/W=(w.left,w.top,w.right,w.bottom) STBL_AllProbs, STBL_SigProbs, STBL_SigLine as "Stability Analysis : Probability"
		Label /W=$probGraph/Z Bottom "First point of " + num2istr( Arrpnts ) + " point window ( second pass )"
		Label /W=$probGraph/Z Left "Probability"
		ModifyGraph /W=$probGraph mode( $wNameAllProbs )=4, marker( $wNameAllProbs )=19, rgb( $wNameAllProbs )=(0,0,0)
		ModifyGraph /W=$probGraph mode( $wNameSigProbs )=4, marker( $wNameSigProbs )=0, rgb( $wNameSigProbs )=(65535,0,0)
		ModifyGraph /W=$probGraph rgb( $wNameSigLine )=(65535,0,0)
		Setaxis /W=$probGraph left 0,1
		//SetAxis /W=$probGraph bottom 0, plast
		OutWinList += probGraph + ";"
	
	endif
	
	gName = NMStabilityPlot( wName )
	
	if ( strlen( gName ) > 0 )
	
		OutWinList += gName + ";"
		
		AppendToGraph /W=$gName /C=(0,0,65535) stable_pass1
		AppendToGraph /W=$gName /C=(0,0,0) stable_linefit
		ModifyGraph /W=$gName mode( $wNamePass1 )=4, marker( $wNamePass1 )=1
	
	endif
	
	Redimension /N=( numpnts( stable_pass1 ) ) stable_linefit
	
	stable_linefit = Nan
	
	if ( win2Frac == 1 )
		CurveFit /Q line stable_pass1 /D=stable_linefit
		//NMHistory( "WaveStats of stable_pass1:" )
		//Wavestats stable_pass1
	else
	
		if ( strlen( gName ) > 0 )
			Appendtograph /W=$gName /C=(65535,0,0) STBL_Pass2
			ModifyGraph /W=$gName mode( $wNamePass2 )=4, marker( $wNamePass2 )=0
		endif
		
		CurveFit /Q line STBL_Pass2 /D=stable_linefit
		//NMHistory( "WaveStats of STBL_Pass2:" )
		//Wavestats STBL_Pass2
		
	endif
	
	SetNMvar( df+"StableFrom", stableFrom )
	SetNMvar( df+"StableTo", stableTo )
	SetNMvar( sdf+"StableFrom", stableFrom )
	SetNMvar( sdf+"StableTo", stableTo )
	
	DrawText 0.1,0.1,"Stable from point " + num2istr( stableFrom ) + " to " + num2istr( stableTo )
	
	if ( StringMatch( waveNamingFormat, "prefix" ) == 1 )
		sName = "Stable_" + wNameShort
	else
		sName = wNameShort + "_Stable"
	endif
	
	sName = NMCheckStringName( sName )
	
	Duplicate /O $wName, $df + sName
	
	xl = NMNoteLabel( "x", wName, "Wave#" )
	
	txt = "Stbl Pbgn:" + num2istr( pbgn ) + ";Stbl Pend:" + num2istr( pend ) + ";Stbl MinArray:" + num2str( minArray )
	txt += ";Stbl Sig:" + num2str( significance ) + ";Stbl Win2Frac:" + num2str( win2Frac ) + ";"
	
	NMNoteType( df + sName, "NMSet", xl, "Stable Region ( 1 )", "_FXN_" )
	Note $df + sName, "Stbl Wave:" + wName
	Note $df + sName, txt
	
	Wave wtemp = $df + sName
	
	wtemp = 0
	wtemp[ stableFrom, stableTo ] = 1
	
	//NMHistory( "Stability results stored in wave: " + df + sName )
	
	if ( strlen( setName ) > 0 )
		NMSetsWaveToLists( df + sName, setName )
		NMWaveSelect( "Update" )
	endif
	
	NMStabilityKill()
	
	SetNMstr( NMDF + "OutputWaveList", OutWaveList )
	SetNMstr( NMDF + "OutputWinList", OutWinList )
	
	NMHistoryOutputWaves( subfolder = df )
	NMHistoryOutputWindows()
	
	return gName
	
End // NMStabilityRankOrderTest

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStabilityKill()

	KillWaves /Z $NMStatsDF + "ST_inWaveX"
	KillWaves /Z $NMStatsDF + "ST_inWaveY"
	KillWaves /Z $NMStatsDF + "ST_yArray"
	KillWaves /Z $NMStatsDF + "ST_xArray"
	
	KillWaves /Z W_coef, W_sigma

End // NMStabilityKill

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStabilityGraphName( wName, suffix, overwrite )
	String wName // fullpath
	String suffix
	Variable overwrite
	
	String folder = NMParent( wName )
	String pName = NMChild( wName )
	String folderPrefix = NMFolderListName( folder ) + "_"
	String gPrefix = pName + "_" + folderPrefix + "_" + suffix
	
	return NextGraphName( gPrefix, -1, overwrite )
	
End // NMStabilityGraphName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMStabilityPlot( wName )
	String wName // fullpath
	
	STRUCT Rect w
	
	Variable overwrite = 1
	
	String pName = NMChild( wName )
	String gName = NMStabilityGraphName( wName, "STB", overwrite )
	
	String gTitle = NMFolderListName( "" ) + " : Stability Analysis : " + pName
	
	NMWinCascadeRect( w )
	
	Dowindow /K $gName
	Display /K=(NMK())/N=$gName/W=(w.left,w.top,w.right,w.bottom) $wName as gTitle
	ModifyGraph /W=$gName mode=4, marker=19, rgb=(500,500,500)
	Label /W=$gName/Z Bottom NMNoteLabel( "x", wName, "" )
	Label /W=$gName/Z Left NMNoteLabel( "y", wName, "" )
	
	DoUpdate
	
	return gName
	
End // NMStabilityPlot

//****************************************************************
//****************************************************************

Function NMRankNRC( sortedWave ) //  // Numerical Recipes in C (NRC)
	Wave sortedWave // sorted input wave name
	
	Variable j = 1, ji, jt
	Variable npnts = numpnts( sortedWave )
	Variable t, rank, s = 0
	
	do
	
		if ( j >= npnts )
			break
		endif
	
		if ( sortedWave[ j ] != sortedWave[ j - 1 ] ) // not a tie
		
			sortedWave[ j - 1 ] = j
			j += 1
		
		else // a tie
		
			for ( jt = j + 1 ; jt <= npnts ; jt += 1 ) // search for more ties
				if ( sortedWave[ jt - 1 ] != sortedWave[ j - 1 ] )
					break // no more ties
				endif
			endfor
			
			rank = 0.5 * ( j + jt - 1 ) // mean rank of the tie
			
			for ( ji = j ; ji <= jt - 1 ; ji += 1 )
				sortedWave[ ji - 1 ] = rank // enter mean rank for all the tied entries
			endfor
			
			t = jt - j
			s += t * t * t - t // update s
			j = jt
		
		endif
	
	while ( j < npnts )
	
	if ( j == npnts )
		sortedWave[ npnts - 1 ] = npnts // if last element was not tied, enter its rank
	endif
	
	return s // if no ties, s = 0
	
End // NMRankNRC

//****************************************************************
//****************************************************************

Function NMStabilityRank( sortedWave )
	Wave sortedWave // sorted input wave name
	
	Variable j, ji, jt, ntie, s, rank
	
	Variable npnts = numpnts( sortedWave )
	
	for ( j = 0; j < npnts-1; j+=1 )
	
		if ( sortedWave[ j ] == sortedWave[ j+1 ] ) // found tie
		
			jt = j+1
			ntie = 1
			
			for ( jt = j+1; jt < npnts; jt+=1 ) // find more ties
				if ( sortedWave[ jt ] == sortedWave[ j ] )
					ntie += 1
				else
					jt -= 1
					break
				endif
			endfor
			
			rank = 0.5*( j + jt ) // mean rank of the tie
			
			for ( ji = j; ji <= jt; ji+=1 )
				sortedWave[ ji ] = rank
			endfor
			
			s+=( ntie*ntie*ntie )-ntie
			
			j = jt
		
		else
		
			sortedWave[ j ] = j
			
		endif
		
	endfor
	
	if ( j == npnts - 1 )
		sortedWave[ j ] = j
	endif
	
	return s // if no ties, s = 0
	
End // NMStabilityRank

//****************************************************************
//****************************************************************

Structure NMSpearmanStructure

	Variable d // sum squared difference of ranks
	Variable zd // the number of STDVS by which d deviates from its null-hypothesis expected value
	Variable probd // the two-sided p-value of this deviation
	Variable rs // Spearman’s rank correlation
	Variable probrs // the two-sided p-value of its deviation from zero

EndStructure

//****************************************************************
//****************************************************************

Function NMSpearmanNRC( data1, data2 [ s ] ) // Numerical Recipes in C (NRC)
	Wave data1 // x-data
	Wave data2 // y-data
	STRUCT NMSpearmanStructure &s
	
	Variable j
	Variable vard, t, sg, sf, fac, en3n, en, df, aved
	Variable d = 0, zd, probd, rs, probrs
	
	Variable npnts = numpnts( data1 )
	
	Duplicate /O data1, wksp1
	Duplicate /O data2, wksp2
	
	Sort wksp2 wksp2, wksp1
	sf = NMRankNRC( wksp2 )
	
	Sort wksp1 wksp2, wksp1
	sg = NMRankNRC( wksp1 )
	
	for ( j = 0 ; j < npnts ; j += 1 )
		d += ( wksp2[ j ] - wksp1[ j ] ) ^ 2 // sum of square difference of ranks
	endfor
	
	en = npnts
	en3n = en * en * en - en
	df = en - 2.0
	
	aved = ( en3n / 6.0 ) - ( ( sf + sg ) / 12.0 )
	fac = ( 1.0 - sf / en3n ) * ( 1.0 - sg / en3n )
	vard = fac * ( en - 1.0 ) * en * en * ( en + 1.0 ) * ( en + 1.0 ) / 36.0
	zd = ( d - aved ) / sqrt( vard )
	probd = erfc( abs( zd ) / 1.4142136 )
	rs = ( 1.0 - ( 6.0 / en3n ) * ( d + ( sf + sg ) / 12.0 ) ) / sqrt( fac )
	fac = ( rs + 1.0 ) * ( 1.0 - rs )
	
	if ( fac > 0 )
		t = rs * sqrt( df / fac )
		probrs = betai( 0.5 * df, 0.5, df / ( df + t * t ) )
	else
		probrs = 0
	endif
	
	SetNMvar( NMStatsDF+"StbProbs", probrs )
	SetNMvar( NMStatsDF+"StbRegrs", rs )
	
	if ( !ParamIsDefault( s ) )
		s.d = d
		s.zd = zd
		s.probd = probd 
		s.rs = rs
		s.probrs = probrs
	endif

End // NMSpearmanNRC

//****************************************************************
//****************************************************************

Function NMStabilityCorr( xWave, yWave, sf, sg ) // compute correlation
	Wave xWave
	Wave yWave
	Variable sf, sg
	
	Variable i, t, d, npnts, n3n, dnum
	Variable top, bottom, prob, regrs
	
	npnts = numpnts( yWave )
	n3n = npnts^3 - npnts
	dnum = npnts - 2
	
	for ( i = 0; i < npnts; i+=1 )
		d += ( xWave[ i ]-yWave[ i ] )^2 // sum of squared differences
	endfor
	
	top = 1 - ( 6/n3n ) * ( d + ( sf + sg )/12 )
	bottom = sqrt( 1-( sf/n3n ) ) * sqrt( 1-( sg/n3n ) )
	regrs = top/bottom // regression
	
	bottom = ( 1 + regrs )*( 1 - regrs )
	
	if ( bottom > 0 ) // calculate Probability
		t = regrs * sqrt( dnum/bottom )						
		prob = betai( ( 0.5*dnum ), 0.5, ( dnum/( dnum+t*t ) ) )
	endif
	
	//print regrs, prob
	
	SetNMvar( NMStatsDF+"StbProbs", prob )
	SetNMvar( NMStatsDF+"StbRegrs", regrs )
	
End // NMStabilityCorr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStabilityReplaceNANs( xWave, yWave )
	Wave xWave, yWave
	
	Variable icnt, opnts, xpnt
	Variable npnts = numpnts( xWave )
	
	WaveStats /Q/Z xWave
	
	opnts = V_max + 1
	
	if ( opnts == npnts )
		return 0 // nothing to do
	endif
	
	Redimension /N=( opnts ) yWave
	
	Duplicate /O yWave tempWave
	
	tempWave = Nan
	
	for ( icnt = 0; icnt < npnts; icnt += 1 )
		xpnt = xWave[ icnt ]
		tempWave[ xpnt ] = yWave[ icnt ]
	endfor
	
	yWave = tempWave
	
	KillWaves /Z tempWave
	
End // NMStabilityReplaceNANs

//****************************************************************
//****************************************************************
//****************************************************************
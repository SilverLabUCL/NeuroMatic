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
//****************************************************************
//
//	Set functions:
//
//		NMChannelGraphSet( [ channel, autoScale, freezeX, freezeY, xmin, xmax, ymin, ymax, overlayNum, overlayColor, grid, gridColor, traceMode, traceMarker, traceLineStyle, traceLineSize, errors, errorPointsLimit, toFront, drag, left, top, right, bottom, reposition, on, prefixFolder, history ] )
//		NMChannelFilterSet( [ channel, smoothAlg, smoothNum, lowPass, highPass, off, prefixFolder, history ] )
//
//****************************************************************
//****************************************************************
//****************************************************************

Static StrConstant NMChanGraphPrefix = "Chan"
StrConstant NMChanPopupList = "Overlay;Grid;Drag;Errors;XLabel;YLabel;FreezeX;FreezeY;To Front;Reset Position;Off;"
StrConstant NMChanTransformList = "Baseline;Normalize;dF/Fo;Z-score;Rs Correction;Invert;Differentiate;Double Differentiate;Integrate;Phase Plane;FFT;Log;Ln;Running Average;Histogram;Clip Events;"
StrConstant NMChanFFTList = "real;magnitude;magnitude square;phase;"
StrConstant NMFilterList = "binomial;boxcar;low-pass;high-pass;"

Constant NMChanGraphStandoff = 0 // default channel graph axes standoff ( 0 ) off ( 1 ) on
Constant NMChanGraphGrid = 1 // default channel graph grids ( 0 ) off ( 1 ) on
StrConstant NMChanGraphGridColor = "24576,24576,65535" // default channel graph grid color rgb
StrConstant NMChanGraphTraceOverlayColor = "34800,34800,34800" // default channel graph overlay trace color rgb
StrConstant NMChanGraphTraceColor = "0,0,0" // default channel graph trace color rgb
Constant NMChanGraphTraceMode = 0 // default channel graph trace mode ( 0 - 8, 0 = line only )
Constant NMChanGraphTraceMarker = 19 // default channel graph trace marker ( 0 - 62, 19 = closed circle )
Constant NMChanGraphTraceLineStyle = 0 // default channel graph trace line style ( 0 - 17, 0 = solid line )
Constant NMChanGraphTraceLineSize = 1 // default channel graph trace line size

Static Constant TraceModeMax = 8 // ModifyGraph mode
Static Constant TraceMarkerMax = 62 // ModifyGraph marker
Static Constant TraceLineStyleMax = 17 // ModifyGraph lstyle

Static Constant ImageMargin = 50

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanDF( channel [ prefixFolder ] ) // channel folder path
	Variable channel // ( -1 ) for current channel
	String prefixFolder
	
	String cdf
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	cdf = ChanDFname( channel, prefixFolder = prefixFolder )
	
	if ( ( strlen( cdf ) == 0 ) || !DataFolderExists( cdf ) )
		return ""
	endif
	
	return cdf
	
End // ChanDF

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanDFname( channel [ prefixFolder ] )
	Variable channel // ( -1 ) for current channel
	String prefixFolder
	
	String gName
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	gName = ChanGraphName( channel )
	
	return prefixFolder + gName + ":"
	
End // ChanDFname

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentChanGraphName()

	return ChanGraphName( -1 )
	
End // CurrentChanGraphName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanGraphName( channel )
	Variable channel // ( -1 ) for current channel
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	return NMCheckStringName( NMChanGraphPrefix + ChanNum2Char( channel ) )
	
End // ChanGraphName

//****************************************************************
//****************************************************************
//****************************************************************

Function IsChanGraph( gName )
	String gName
	
	if ( ( strlen( gName ) > 0 ) && ( strsearch( gName, NMChanGraphPrefix, 0, 2 ) == 0 ) )
		return 1
	endif

	return 0
	
End // IsChanGraph

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanDisplayWaveNameX( chanDisplayWaveName )
	String chanDisplayWaveName
	
	if ( strlen( chanDisplayWaveName ) == 0 )
		return ""
	endif
	
	String df = NMParent( chanDisplayWaveName )
	String wName = NMChild( chanDisplayWaveName )
	
	return df + "xScale_" + wName
	
End // NMChanDisplayWaveNameX

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanDisplayWave( channel )
	Variable channel // ( -1 ) for current channel

	return ChanDisplayWaveName( 1, channel, 0 )

End // ChanDisplayWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanDisplayWaveName( directory, channel, wavNum )
	Variable directory // ( 0 ) no directory ( 1 ) include directory
	Variable channel // ( -1 ) for current channel
	Variable wavNum
	Variable xwave // ( 1 ) for x-wave name
	
	String df = ""
	
	if ( directory )
		df = NMDF
	endif
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	return df + GetWaveName( "Display", channel , wavNum )
	
End // ChanDisplayWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckChanSubfolder( channel [ prefixFolder ] )
	Variable channel // ( -1 ) for current channel ( -2 ) for all channels
	String prefixFolder
	
	Variable snum, ft, ccnt, cbgn, cend, numChannels
	String cdf, transform
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	if ( channel == -1 )
		cbgn = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
		cend = cbgn
	elseif ( channel == -2 )
		cbgn = 0
		cend = numChannels - 1
	elseif ( ( channel >= 0 ) && ( channel < numChannels ) )
		cbgn = channel
		cend = channel
	else
		//return NM2Error( 10, "channel", num2str( channel ) )
		return 0
	endif
	
	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
	
		cdf = ChanDFname( ccnt, prefixFolder = prefixFolder )
		
		if ( strlen( cdf ) == 0 )
			continue
		endif
		
		if ( !DataFolderExists( cdf ) )
			NewDataFolder $RemoveEnding( cdf, ":" )
		endif
		
		CheckNMvar( cdf + "SmoothN", 0 )
		CheckNMvar( cdf + "Overlay", 0 )
		
		ft = NumVarOrDefault( cdf + "Ft", NaN ) // this variable has been changed to a string variable called "TransformStr"
		
		if ( numtype( ft ) == 0 )
		
			transform = NMChanTransformName( ft )
			
			SetNMstr( cdf + "TransformStr", transform )
			
			KillVariables /Z $cdf + "Ft"
			
		endif
		
		if ( exists( cdf + "Transform" ) == 2 )
		
			transform = StrVarOrDefault( cdf + "Transform", "" )
			
			if ( strlen( transform ) > 0 )
				SetNMstr( cdf + "TransformStr", transform )
			endif
			
			KillVariables /Z $cdf + "Transform"
			KillStrings /Z $cdf + "Transform"
		
		endif
	
	endfor
	
	return 0

End // CheckChanSubfolder

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanFolderCopy( channel, fromDF, toDF, saveGraphStats )
	Variable channel // ( -1 ) for current channel ( -2 ) for all channels
	String fromDF, toDF
	Variable saveGraphStats
	
	Variable ccnt, cbgn, cend
	String gName
	
	Variable numChannels = NMNumChannels()
	
	if ( channel == -1 )
		cbgn = CurrentNMChannel()
		cend = cbgn
	elseif ( channel == -2 )
		cbgn = 0
		cend = numChannels - 1
	elseif ( ( channel >= 0 ) && ( channel < numChannels ) )
		cbgn = channel
		cend = channel
	else
		//return NM2Error( 10, "channel", num2str( channel ) )
		return 0
	endif
	
	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
	
		gName = ChanGraphName( ccnt )
		
		if ( !DataFolderExists( fromDF+gName ) )
			continue
		endif
	
		if ( DataFolderExists( toDF+gName ) )
			KillDataFolder $( toDF+gName )
		endif
		
		if ( saveGraphStats )
			ChanScaleSave( ccnt )
		endif
		
		DuplicateDataFolder $( fromDF+gName ), $( toDF+gName )
		
	endfor

End // ChanFolderCopy

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Channel Graph Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanGraphMake( [ channel, waveNum, image ] ) // create channel display graph
	Variable channel
	Variable waveNum
	Variable image // ( 0 ) Display 1D wave ( 1 ) Image 2D wave

	Variable scale, tMode, tMarker, tLineStyle, tLineSize, grid, y0 = 8
	Variable gx0, gy0, gx1, gy1
	String tColor, gColor, cdf, xdName = ""
	
	STRUCT NMRGB c
	
	if ( ParamIsDefault( channel ) || ( channel < 0 ) )
		channel = CurrentNMChannel()
	endif
	
	if ( ParamIsDefault( waveNum ) || ( waveNum < 0 ) )
		waveNum = CurrentNMWave()
	endif
	
	String cc = num2istr( channel )
	
	String computer = NMComputerType()
	
	String gName = ChanGraphName( channel )
	String dName = ChanDisplayWave( channel )
	String dNameShort = NMChild( dName )
	String xWave = NMXwave( waveNum = waveNum )
	
	if ( ( strlen( xWave ) > 0 ) && WaveExists( $xWave ) )
		xdName = NMChanDisplayWaveNameX( dName )
	endif
	
	CheckChanSubfolder( channel )
	cdf = ChanDF( channel )
	
	if ( strlen( cdf ) == 0 )
		return -1
	endif
	
	ChanGraphSetCoordinates( channel )
	
	gx0 = NumVarOrDefault( cdf + "GX0", Nan )
	gy0 = NumVarOrDefault( cdf + "GY0", Nan )
	gx1 = NumVarOrDefault( cdf + "GX1", Nan )
	gy1 = NumVarOrDefault( cdf + "GY1", Nan )
	
	if ( numtype( gx0 * gy1 * gx1 * gy1 ) > 0 )
		return 0
	endif
	
	if ( WinType( gName ) != 0 )
		DoWindow /K $gName
	endif
	
	if ( image )
	
		Make /O/N=( 10, 10 ) $dName = Nan
		
		Display /N=$gName/W=( gx0, gy0, gx1, gy1 )/K=1
		AppendImage /W=$gName $dName
		
	else
	
		Make /O/N=10 $dName = Nan
		
		if ( strlen( xdName ) > 0 )
			Make /O/N=10 $xdName = Nan
			//Display /N=$gName/W=( gx0, gy0, gx1, gy1 )/K=1 $dName vs $xWave
			Display /N=$gName/W=( gx0, gy0, gx1, gy1 )/K=1 $dName vs $xdName
		else
			Display /N=$gName/W=( gx0, gy0, gx1, gy1 )/K=1 $dName
		endif
		
		tColor = StrVarOrDefault( cdf + "TraceColor", NMStrGet( "ChanGraphTraceColor" ) )
		tMode = NumVarOrDefault( cdf + "TraceMode", NMVarGet( "ChanGraphTraceMode" ) )
		tMarker = NumVarOrDefault( cdf + "TraceMarker", NMVarGet( "ChanGraphTraceMarker" ) )
		tLineStyle = NumVarOrDefault( cdf + "TraceLineStyle", NMVarGet( "ChanGraphTraceLineStyle" ) )
		tLineSize = NumVarOrDefault( cdf + "TraceLineSize", NMVarGet( "ChanGraphTraceLineSize" ) )
		
		NMColorList2RGB( tColor, c )
		
		ModifyGraph /W=$gName rgb( $dNameShort )=(c.r,c.g,c.b)
		ModifyGraph /W=$gName mode( $dNameShort )=( tMode )
		ModifyGraph /W=$gName marker( $dNameShort )=( tMarker )
		ModifyGraph /W=$gName lstyle( $dNameShort )=( tLineStyle )
		ModifyGraph /W=$gName lsize( $dNameShort )=( tLineSize )
		
	endif
	
	NMColorList2RGB( NMWinColor, c )
	
	ModifyGraph /W=$gName wbRGB = (c.r,c.g,c.b), cbRGB = (c.r,c.g,c.b) // set margin color
	
	grid = NumVarOrDefault( cdf + "Grid", NMVarGet( "ChanGraphGrid" ) )
	gColor = StrVarOrDefault( cdf + "GridColorLeft", NMStrGet( "ChanGraphGridColor" ) )
	
	NMColorList2RGB( gColor, c )
		
	ModifyGraph /W=$gName grid( left )=( grid ), gridRGB( left )=(c.r,c.g,c.b)
	
	grid = NumVarOrDefault( cdf + "GridBottom", NMVarGet( "ChanGraphGrid" ) )
	gColor = StrVarOrDefault( cdf + "GridColorBottom", NMStrGet( "ChanGraphGridColor" ) )
	
	NMColorList2RGB( gColor, c )
		
	ModifyGraph /W=$gName grid( bottom )=( grid ), gridRGB( bottom )=(c.r,c.g,c.b)
	
	ModifyGraph /W=$gName standoff=( NMVarGet( "ChanGraphStandoff" ) )
	
	if ( image )
		ModifyGraph /W=$gName margin=ImageMargin
	else
		ModifyGraph /W=$gName margin( left )=50, margin( right )=22, margin( top )=22, margin( bottom )=40
	endif
	
	if ( StringMatch( computer, "mac" ) )
		y0 = 4
	endif
	
	PopupMenu $( "PlotMenu"+cc ), pos={0,0}, size={15,0}, bodyWidth= 20, mode=1, value=" ;" + NMChanPopupList, proc=NMChanPopup, win=$gName
	CheckBox $( "ScaleCheck"+cc ), title="Autoscale", pos={70,y0}, size={16,18}, value=1, proc=NMChanCheckbox, win=$gName
	SetVariable $( "SmoothSet"+cc ), title="Filter", pos={170,y0-1}, size={90,50}, limits={0,inf,1}, value=$( cdf + "SmoothN" ), proc=NMChanSetVariable, win=$gName
	CheckBox $( "TransformCheck"+cc ), title="Transform", pos={300,y0}, size={16,18}, value=0, proc=NMChanCheckbox, win=$gName
	
End // NMChanGraphMake

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphsUpdate() // update channel display graphs

	Variable ccnt
	
	Variable numChannels = NMNumChannels()
	
	for ( ccnt = 0; ccnt < numChannels; ccnt+=1 )
		NMChanGraphUpdate( channel = ccnt )
		ChanGraphControlsUpdate( ccnt )
	endfor
	
	if ( numChannels == 0 )
		ChanGraphClose( -3, 0 ) // close unnecessary graphs
	endif

End // ChanGraphsUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanGraphUpdate( [ channel, waveNum, makeChanWave ] ) // update channel display graphs
	Variable channel
	Variable waveNum
	Variable makeChanWave // ( 0 ) no ( 1 ) yes
	
	Variable autoscale, count, grid, dualDisplay, errorsOn, noErrorCheck, xwaveOn = 0
	Variable md, image, npnts, dx, phaseplane = 0
	Variable tMode, tMarker, tLineStyle, tLineSize
	String sName, dName, dNameShort, xdName = "", errorName, gName
	String transformList, transform, info, gColor, gColorCurrent, tColor, tColorCurrent, cdf
	String axisName, histoName, histoNameX, histoNameXshort, wList, xWave
	
	STRUCT NMRGB c
	
	String fname = NMFolderListName( "" )
	
	if ( ParamIsDefault( channel ) || ( channel < 0 ) )
		channel = CurrentNMChannel()
	endif
	
	if ( ParamIsDefault( waveNum ) || ( waveNum < 0 ) )
		waveNum = CurrentNMWave()
	endif
	
	if ( ParamIsDefault( makeChanWave ) )
		makeChanWave = 1
	endif
	
	gName = ChanGraphName( channel )
	dName = ChanDisplayWave( channel )
	dNameShort = NMChild( dName )
	xdName = NMChanDisplayWaveNameX( dName )
	sName = NMChanWaveName( channel, waveNum ) // source wave
	
	transformList = NMChanTransformGet( channel, itemNum = 0, errorAlert = 1 )
	transform = StringFromList( 0, transformList, "," )
	
	xWave = NMXwave( waveNum = waveNum )
	
	CheckChanSubfolder( channel )
	
	cdf = ChanDF( channel )
	
	if ( strlen( cdf ) == 0 )
		return ""
	endif
	
	autoscale = NumVarOrDefault( cdf + "AutoScale", 1 )
	dualDisplay = NumVarOrDefault( cdf + "Histo_DualDisplay", 0 )
	errorsOn = NumVarOrDefault( cdf + "ErrorsOn", 1 )
	
	if ( DimSize( $sName, 1 ) > 1 )
	
		image = 1
		
		if ( DimSize( $dName, 1 ) == 0 )
			DoWindow /K $gName
		endif
		
	else
	
		image = 0
	
		if ( DimSize( $dName, 1 ) > 0 )
			DoWindow /K $gName
		endif
		
	endif
	
	if ( strlen( cdf ) == 0 )
		return ""
	endif
	
	if ( !NumVarOrDefault( cdf + "On", 1 ) )
		ChanGraphClose( channel, 0 )
		return ""
	endif

	if ( Wintype( gName ) == 0 )
		NMChanGraphMake( channel = channel, image = image )
	endif
	
	if ( Wintype( gName ) == 0 )
		return ""
	endif
	
	if ( strlen( fName ) > 0 )
		DoWindow /T $gName, fname + " : Ch " + ChanNum2Char( channel ) + " : " + sName
	else
		DoWindow /T $gName, "Ch " + ChanNum2Char( channel ) + " : " + sName
	endif
	
	if ( !image && ( strlen( xWave ) > 0 ) && WaveExists( $xWave ) )
		xwaveOn = 1
	endif
	
	if ( !image && StringMatch( transform, "Phase Plane" ) )
		phaseplane = 1
		xwaveOn = 1
	endif
	
	if ( makeChanWave ) // moved here 9 March 2020
	
		if ( ChanWaveMake( channel, sName, dName, xWave = xWave ) < 0 )
			// error, display wave is copy of source
			if ( WaveExists( $sName ) )
				Duplicate /O $sName $dName
				Wave wtemp = $dName
				wtemp = NaN
			endif
		endif
		
		if ( xwaveOn && !phaseplane )
			Duplicate /O $xWave $xdName
		endif
	
	endif
	
	if ( !image )
	
		wList = TraceNameList( gName, ";", 1 )
		
		if ( xwaveOn )
			if ( WaveExists( $xdName ) && ( strlen( XWaveName( gName, dNameShort ) ) == 0 ) )
				RemoveFromGraph /W=$gName /Z $dNameShort // force AppendToGraph with x-wave
				wList = ""
			endif
		else
			if ( strlen( XWaveName( gName, dNameShort ) ) > 0 )
				RemoveFromGraph /W=$gName /Z $dNameShort // force AppendToGraph without x-wave
				wList = ""
			endif
			KillWaves /Z $xdName
		endif
		
		if ( WhichListItem( dNameShort, wList ) < 0 )
			if ( WaveExists( $xdName ) )
				AppendToGraph /W=$gName $dName vs $xdName
			else
				AppendToGraph /W=$gName $dName
			endif
		endif
	
		tColor = StrVarOrDefault( cdf + "TraceColor", NMStrGet( "ChanGraphTraceColor" ) )
		tMode = NumVarOrDefault( cdf + "TraceMode", NMVarGet( "ChanGraphTraceMode" ) )
		tMarker = NumVarOrDefault( cdf + "TraceMarker", NMVarGet( "ChanGraphTraceMarker" ) )
		tLineStyle = NumVarOrDefault( cdf + "TraceLineStyle", NMVarGet( "ChanGraphTraceLineStyle" ) )
		tLineSize = NumVarOrDefault( cdf + "TraceLineSize", NMVarGet( "ChanGraphTraceLineSize" ) )
		
		NMColorList2RGB( tColor, c )
		
		ModifyGraph /W=$gName rgb( $dNameShort )=( c.r,c.g,c.b )
		ModifyGraph /W=$gName mode( $dNameShort )=( tMode )
		ModifyGraph /W=$gName marker( $dNameShort )=( tMarker )
		ModifyGraph /W=$gName lstyle( $dNameShort )=( tLineStyle )
		ModifyGraph /W=$gName lsize( $dNameShort )=( tLineSize )
	
	endif

	if ( !image && ( NumVarOrDefault( cdf + "Overlay", 0 ) > 0 ) )
		ChanOverlayUpdate( channel, xWave = xWave )
	endif
	
	//if ( makeChanWave )
	
		//if ( ChanWaveMake( channel, sName, dName, xWave = xWave ) < 0 )
			// error, display wave is copy of source
			//if ( WaveExists( $sName ) )
				//Duplicate /O $sName $dName
				//Wave wtemp = $dName
				//wtemp = NaN
			//endif
		//endif
		
		//if ( ( strlen( xWave ) > 0 ) && WaveExists( $xWave ) )
			//Duplicate /O $xWave $xdName
		//endif
	
	//endif
	
	//ChanGraphControlsUpdate( channel )
	
	//if ( numpnts( $dName ) < 0 ) // if waves have Nans, change mode to line+symbol
		
	//	WaveStats /Q $dName
		
	//	count = ( V_numNaNs * 100 / V_npnts )

	//	if ( ( numtype( count ) == 0 ) && ( count > 25 ) )
	//		ModifyGraph /W=$gName mode( $dNameShort )=4
	//	else
	//		ModifyGraph /W=$gName mode( $dNameShort )=0
	//	endif
	
	//endif
	
	if ( autoscale || image )
	
		if ( image )
		
			npnts = DimSize( $sName, 0 )
			dx = DimDelta($sName, 0 )
			SetAxis /W=$gName/Z bottom -0.5 * dx, (npnts-0.5) * dx
			
			npnts = DimSize( $sName, 1 )
			dx = DimDelta($sName, 1 )
			SetAxis /W=$gName/Z left (npnts-0.5) * dx, -0.5 * dx
			
		else
		
			SetAxis /A/W=$gName/Z
			
		endif
		
	else
	
		ChanGraphAxesSet( channel )
		
	endif
	
	info = AxisInfo( gName, "bottom" )
	
	histoName = dName + "_histo"
	histoNameX = dName + "_histoX"
	histoNameXshort = NMChild( histoNameX )
	
	if ( !image && StringMatch( transform, "Histogram" ) && dualDisplay )
	
		wList = TraceNameList( gName, ";", 1 )
		
		if ( WhichListItem( histoNameXshort, wList ) < 0 )
			AppendToGraph /W=$gName $histoNameX vs $histoName
			ModifyGraph /W=$gName mode($histoNameXshort)=6
		endif
		
	else
	
		RemoveFromGraph /W=$gName /Z $histoNameXshort
		
		KillWaves /Z $histoName, $histoNameX
		
	endif
	
	if ( strlen( info ) > 0 )
		
		strswitch( transform )
		
			case "FFT":
				axisName = "1/" + NMChanLabelX( channel = channel, waveNum = waveNum )
				break
		
			case "Histogram":
			
				if ( dualDisplay )
					axisName = NMChanLabelX( channel = channel, waveNum = waveNum )
				else
					axisName = NMChanLabelY( channel = channel, waveNum = waveNum )
				endif
				
				break
				
			case "Phase Plane":
				axisName = NMChanLabelY( channel = channel, waveNum = waveNum )
				break
				
			default:
			
				//NMChanLabel( nm.chanNum, "x", nm.inputList, prefixFolder = nm.prefixFolder )
			
				axisName = NMChanLabelX( channel = channel, waveNum = waveNum )
			
				if ( WaveExists( $Xwave ) )
					axisName = NMNoteLabel( "y", Xwave, axisName )
				endif
				
		endswitch
	
		Label /W=$gName bottom axisName
		
	endif
	
	info = AxisInfo( gName, "left" )
	
	if ( strlen( info ) > 0 )
	
		strswitch( transform )
		
			case "Differentiate":
				axisName = "Derivative"
				break
				
			case "Double Differentiate":
				axisName = "Double Derivative"
				break
				
			case "Integrate":
				axisName = "Integral"
				break
				
			case "FFT":
				axisName = "FFT " + StringByKey("output", transformList, "=", ",")
				break
				
			case "Normalize":
				axisName = "Normalized"
				break
				
			case "dF/Fo":
				axisName = "dF/Fo"
				break
				
			case "Z-score":
				axisName = "Z-score"
				break
				
			case "Log":
				axisName = "Log"
				break
				
			case "Ln":
				axisName = "Ln"
				break
				
			case "Histogram":
			
				if ( dualDisplay )
					axisName = NMChanLabelY( channel = channel, waveNum = waveNum )
				else
					axisName = "Count"
				endif
				
				break
				
			case "Phase Plane":
				axisName = "Derivative"
				break
				
			default:
			
				axisName = NMChanLabelY( channel = channel, waveNum = waveNum )
				
		endswitch
		
		Label /W=$gName left axisName
	
	endif
	
	grid = NumVarOrDefault( cdf + "Grid", NMVarGet( "ChanGraphGrid" ) )
	gColor = StrVarOrDefault( cdf + "GridColor", NMStrGet( "ChanGraphGridColor" ) )
	
	NMColorList2RGB( gColor, c )
		
	ModifyGraph /W=$gName grid=( grid ), gridRGB=(c.r,c.g,c.b)
	
	ModifyGraph /W=$gName standoff=( NMVarGet( "ChanGraphStandoff" ) )
	
	if ( !image && errorsOn && !noErrorCheck )
	
		errorName = NMWaveNameError( sName )
		
		if ( strlen( errorName ) > 0 )
		
			if ( strsearch( errorName, "STDV", 0, 2 ) >= 0 )
			
				Duplicate /O $errorName $dName + "_STDV"
				
				errorName = dName + "_STDV"
				
			elseif ( strsearch( errorName, "SEM", 0, 2 ) >= 0 )
			
				Duplicate /O $errorName $dName + "_SEM"
				
				errorName = dName + "_SEM"
				
			else
				
				errorName = ""
				
			endif
		
			if ( strlen( errorName ) > 0 )
				
				if ( numpnts( $errorName ) <= NMVarGet( "ErrorPointsLimit" ) )
					ErrorBars /W=$gName $dNameShort Y, wave=( $errorName, $errorName )
				else
					ErrorBars /L=0/W=$gName/Y=1 $dNameShort Y, wave=( $errorName, $errorName )
				endif
				
			endif
			
		else
		
			ErrorBars /W=$gName $dNameShort OFF
			
		endif
		
	elseif ( !image && !noErrorCheck )
	
		ErrorBars /W=$gName $dNameShort OFF
		
	endif
	
	ChanGraphMove( channel )
	
	if ( NMChanGraphToFront( channel ) )
		DoWindow /F $gName
	endif
	
	return gName

End // NMChanGraphUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChannelGraphConfigsSave( channel )
	Variable channel // ( -1 ) for current channel ( -2 ) for all channels
	
	Variable ccnt, cbgn, cend
	Variable tMode, tModeCurrent, tMarker, tMarkerCurrent, tLineStyle, tLineStyleCurrent, tLineSize, tLineSizeCurrent
	Variable grid, gridLeft, gridBottom, gridCurrent
	String info, tColor, tColorCurrent, gColor, gColorLeft, gColorBottom
	String gName, dName, dNameShort, cdf
	
	Variable numChannels = NMNumChannels()
	
	if ( channel == -1 )
		cbgn = CurrentNMChannel()
		cend = cbgn
	elseif ( channel == -2 )
		cbgn = 0
		cend = numChannels - 1
	elseif ( ( channel >= 0 ) && ( channel < numChannels ) )
		cbgn = channel
		cend = channel
	else
		//return NM2Error( 10, "channel", num2str( channel ) )
		return 0
	endif
	
	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
		
		cdf = ChanDF( ccnt )
		gName = ChanGraphName( ccnt )
		dName = ChanDisplayWave( ccnt )
		dNameShort = NMChild( dName )
		
		if ( ( strlen( cdf ) == 0 ) || ( WinType( gName ) != 1 ) )
			continue
		endif

		info = TraceInfo( gName, dNameShort, 0 )
		
		if ( strlen( info ) == 0 )
			continue
		endif
	
		tColor = StrVarOrDefault( cdf + "TraceColor", NMStrGet( "ChanGraphTraceColor" ) )
		
		tColorCurrent = StringByKey( "rgb(x)", info, "=" )
		tColorCurrent = ReplaceString( "(", tColorCurrent, "" )
		tColorCurrent = ReplaceString( ")", tColorCurrent, "" )
	
		if ( NMisRGBlist( tColorCurrent ) && !StringMatch( tColor, tColorCurrent ) )
			SetNMstr( cdf + "TraceColor", tColorCurrent )
		endif
		
		tMode = NumVarOrDefault( cdf + "TraceMode", NMVarGet( "ChanGraphTraceMode" ) )
		
		tModeCurrent = str2num( StringByKey( "mode(x)", info, "=" ) )
		
		if ( ( numtype( tModeCurrent ) == 0 ) && ( tModeCurrent != tMode ) )
			if ( ( tModeCurrent >= 0 ) && ( tModeCurrent <= TraceModeMax ) )
				SetNMvar( cdf + "TraceMode", tModeCurrent )
			endif
		endif
		
		tMarker = NumVarOrDefault( cdf + "TraceMarker", NMVarGet( "ChanGraphTraceMarker" ) )
		
		tMarkerCurrent = str2num( StringByKey( "marker(x)", info, "=" ) )
		
		if ( ( numtype( tMarkerCurrent ) == 0 ) && ( tMarkerCurrent != tMarker ) )
			if ( ( tMarkerCurrent >= 0 ) && ( tMarkerCurrent <= TraceMarkerMax ) )
				SetNMvar( cdf + "TraceMarker", tMarkerCurrent )
			endif
		endif
		
		tLineStyle = NumVarOrDefault( cdf + "TraceLineStyle", NMVarGet( "ChanGraphTraceLineStyle" ) )
		
		tLineStyleCurrent = str2num( StringByKey( "lstyle(x)", info, "=" ) )
		
		if ( ( numtype( tLineStyleCurrent ) == 0 ) && ( tLineStyleCurrent != tLineStyle ) )
			if ( ( tLineStyleCurrent >= 0 ) && ( tLineStyleCurrent <= TraceLineStyleMax ) )
				SetNMvar( cdf + "TraceLineStyle", tLineStyleCurrent )
			endif
		endif
		
		tLineSize = NumVarOrDefault( cdf + "TraceLineSize", NMVarGet( "ChanGraphTraceLineSize" ) )
		
		tLineSizeCurrent = str2num( StringByKey( "lsize(x)", info, "=" ) )
		
		if ( ( numtype( tLineSizeCurrent ) == 0 ) && ( tLineSizeCurrent != tLineSize ) )
			if ( tLineSizeCurrent >= 0 )
				SetNMvar( cdf + "TraceLineSize", tLineSizeCurrent )
			endif
		endif
		
		grid = NumVarOrDefault( cdf + "Grid", NMVarGet( "ChanGraphGrid" ) )
		gColor = StrVarOrDefault( cdf + "GridColor", NMStrGet( "ChanGraphGridColor" ) )
		
		info = AxisInfo( gName, "left" )
		
		if ( strlen( info ) == 0 )
			return 0
		endif
		
		gridLeft = str2num( StringByKey( "grid(x)", info, "=" ) )
		
		gColorLeft = StringByKey( "gridRGB(x)", info, "=" )
		gColorLeft = ReplaceString( "(", gColorLeft, "" )
		gColorLeft = ReplaceString( ")", gColorLeft, "" )
		
		info = AxisInfo( gName, "bottom" )
		
		if ( strlen( info ) == 0 )
			return 0
		endif
		
		gridBottom = str2num( StringByKey( "grid(x)", info, "=" ) )
		
		gColorBottom = StringByKey( "gridRGB(x)", info, "=" )
		gColorBottom = ReplaceString( "(", gColorBottom, "" )
		gColorBottom = ReplaceString( ")", gColorBottom, "" )
			
		gridCurrent = gridLeft || gridBottom
		
		if ( grid != gridCurrent )
			SetNMvar( cdf + "Grid", gridCurrent )
		endif
			
		if ( NMisRGBlist( gColorLeft ) && !StringMatch( gColor, gColorLeft ) )
			SetNMstr( cdf + "GridColor", gColorLeft )
		elseif ( NMisRGBlist( gColorBottom ) && !StringMatch( gColor, gColorBottom ) )
			SetNMstr( cdf + "GridColor", gColorBottom )
		endif
		
	endfor

End // NMChannelGraphConfigsSave

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanGraphToFront( channel )
	Variable channel // ( -1 ) for current channel
	
	Variable icnt, foundGraphInFront
	String gName2
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	String gName = ChanGraphName( channel )
	String cdf = ChanDF( channel )
	
	if ( ( strlen( cdf ) == 0 ) || ( WinType( gName ) == 0 ) )
		return 0
	endif
	
	Variable toFront = NumVarOrDefault( cdf + "ToFront", 1 )
	
	if ( !toFront )
		return 0
	endif
	
	String gList = WinList("*", ";", "Visible:1")
	
	for ( icnt = 0 ; icnt < ItemsInList( gList ) ; icnt += 1 )
	
		gName2 = StringFromList( icnt, gList )
		
		if ( StringMatch( gName2, gName ) )
			break
		endif
		
		if ( strsearch( gName2, NMChanGraphPrefix, 0 ) == 0 )
			continue
		endif
		
		return 1
		
	endfor
	
	return 0
	
End // NMChanGraphToFront

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphsRemoveWaves()

	Variable ccnt, numChannels = NMNumChannels()
	
	for ( ccnt = 0; ccnt < numChannels; ccnt+=1 )
		ChanGraphRemoveWaves( ccnt )
	endfor

End // ChanGraphsRemoveWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphRemoveWaves( channel )
	Variable channel // ( -1 ) for current channel
	
	Variable wcnt
	String wname, wList, gName
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	gName = ChanGraphName( channel )
	
	if ( WinType( gName ) != 1 )
		return -1
	endif
	
	wList = TraceNameList( gName, ";", 1 )
	
	for ( wcnt = 0; wcnt < ItemsInlist( wList ); wcnt += 1 )
		wname = StringFromList( wcnt, wList )
		RemoveFromGraph /W=$gName $wname
	endfor
	
	wList = ImageNameList( gName, ";" )
	
	for ( wcnt = 0; wcnt < ItemsInlist( wList ); wcnt += 1 )
		wname = StringFromList( wcnt, wList )
		RemoveImage  /W=$gName/Z $wname
	endfor
	
	return 0

End // ChanGraphRemoveWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphsAppendDisplayWave()

	Variable ccnt
	
	Variable numChannels = NMNumChannels()
	Variable waveNum = CurrentNMWave()
	
	for ( ccnt = 0; ccnt < numChannels; ccnt+=1 )
		ChanGraphAppendDisplayWave( ccnt, waveNum = waveNum )
	endfor

End // ChanGraphsAppendDisplayWave

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphAppendDisplayWave( channel [ waveNum ] )
	Variable channel // ( -1 ) for current channel
	Variable waveNum
	
	Variable tMode, tMarker, tLineStyle, tLineSize
	String xWave, tColor, xdName
	
	STRUCT NMRGB c
	
	if ( channel < 0 )
		channel = CurrentNMChannel()
	endif
	
	if ( ParamIsDefault( waveNum ) || ( waveNum < 0 ) )
		waveNum = CurrentNMWave()
	endif
	
	String cdf = ChanDF( channel )
	String gName = ChanGraphName( channel )
	String dName = ChanDisplayWave( channel )
	String dNameShort = NMChild( dName )
	
	if ( ( strlen( cdf ) == 0 ) || ( WinType( gName ) != 1 ) || !WaveExists( $dName ) )
		return -1
	endif
	
	if ( DimSize( $dName, 1 ) > 1 )
	
		AppendImage /W=$gName $dName
	
	else
	
		xWave = NMXWave( waveNum = waveNum )
	
		if ( WaveExists( $xWave ) )
			xdName = NMChanDisplayWaveNameX( dName )
			Duplicate /O $xWave $xdName
			AppendToGraph /W=$gName $dName vs $xdName
		else
			AppendToGraph /W=$gName $dName
		endif
		
		tMode = NumVarOrDefault( cdf + "TraceMode", NMVarGet( "ChanGraphTraceMode" ) )
		tMarker = NumVarOrDefault( cdf + "TraceMarker", NMVarGet( "ChanGraphTraceMarker" ) )
		tLineStyle = NumVarOrDefault( cdf + "TraceLineStyle", NMVarGet( "ChanGraphTraceLineStyle" ) )
		tLineSize = NumVarOrDefault( cdf + "TraceLineSize", NMVarGet( "ChanGraphTraceLineSize" ) )
		
		tColor = StrVarOrDefault( cdf + "TraceColor", NMStrGet( "ChanGraphTraceColor" ) )
		
		NMColorList2RGB( tColor, c )
	
		ModifyGraph /W=$gName rgb( $dNameShort )=(c.r,c.g,c.b)
		ModifyGraph /W=$gName mode( $dNameShort )=( tMode )
		ModifyGraph /W=$gName marker( $dNameShort )=( tMarker )
		ModifyGraph /W=$gName lstyle( $dNameShort )=( tLineStyle )
		ModifyGraph /W=$gName lsize( $dNameShort )=( tLineSize )
	
	endif

End // ChanGraphAppendDisplayWave

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphControlsUpdate( channel )
	Variable channel // ( -1 ) for current channel
	
	Variable autoscale
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	String gName = ChanGraphName( channel )
	String cdf = ChanDF( channel )
	String cc = num2istr( channel )
	
	if ( strlen( cdf ) == 0 )
		return -1
	endif
	
	autoscale = NumVarOrDefault( cdf + "AutoScale", 1 )
	
	if ( ( strlen( cdf ) == 0 ) || ( winType( gName ) == 0 ) )
		return 0
	endif
	
	CheckBox $( "ScaleCheck"+cc ), value=autoscale, win=$gName, proc=NMChanCheckbox
	
	NMChanFilterSetVariableUpdate( channel )
	NMChanTransformCheckboxUpdate( channel )
	
End // ChanGraphControlsUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanFilterSetVariableUpdate( channel )
	Variable channel // ( -1 ) for current channel
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	String gName = ChanGraphName( channel )
	String cc = num2istr( channel )
	String titlestr = "Filter"
	
	String cdf = ChanDF( channel )
	
	if ( strlen( cdf ) == 0 )
		return -1
	endif
	
	String filterAlg = ChanFilterAlgGet( channel )
	
	ControlInfo /W=$gName $( "SmoothSet"+cc )
	
	if ( V_flag == 0 )
		return 0
	endif
	
	strswitch( filterAlg )
		case "binomial":
		case "boxcar":
			titlestr = "Smooth"
			break
		case "low-pass":
			titlestr = "Low"
			break
		case "high-pass":
			titlestr = "High"
			break
		default:
			titlestr = "Filter"
	endswitch
	
	SetVariable $( "SmoothSet"+cc ), win=$gName, title=titlestr, proc=$ChanFilterProc( channel ), value=$( cdf + "SmoothN" )
	
	return 0
	
End // NMChanFilterSetVariableUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanTransformCheckboxUpdate( channel )
	Variable channel // ( -1 ) for current channel
	
	Variable v, numWaves
	String wList
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	String gName = ChanGraphName( channel )
	String cc = num2istr( channel )
	String transformList = NMChanTransformGet( channel, itemNum = 0 )
	String transform = StringFromList( 0, transformList, "," )
	
	if ( WinType( gName ) != 1 )
		return -1
	endif
	
	ControlInfo /W=$gName $( "TransformCheck"+cc )
	
	if ( V_flag == 0 )
		return 0
	endif
	
	if ( WhichListItem( transform, NMChanTransformList ) >= 0 )
		v = 1
	else
		transform = "Transform"
	endif
	
	if ( StringMatch( transform, "Running Average" ) )
	
		wList = z_RunningAvgWaveList( channel, -1, -1, -1 )
		
		numWaves = ItemsInList( wList )
		
		if ( numWaves == 0 )
			numWaves = 1
		endif
		
		transform = "Avg (n=" + num2istr( numWaves ) + ")"
		
	endif
	
	CheckBox $( "TransformCheck"+cc ), value=v, title=transform, win=$gName, proc=$NMChanTransformProc( channel )
	
End // NMChanTransformCheckboxUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphsReset()

	ChanGraphClose( -3, 0 ) // close unnecessary graphs
	ChanOverlayKill( -2 ) // kill unecessary waves
	ChanGraphClear( -2 )
	ChanGraphsRemoveWaves()
	ChanGraphsAppendDisplayWave()
	ChanGraphTagsKill( -2 )
	ChanGraphMove( -2 )

End // ChanGraphsReset

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphTagsKill( channel )
	Variable channel // ( -1 ) for current channel ( -2 ) for all channels
	
	Variable icnt, ccnt, cbgn, cend
	String gName, aName, aList
	
	Variable numChannels = NMNumChannels()
	
	if ( channel == -1 )
		cbgn = CurrentNMChannel()
		cend = cbgn
	elseif ( channel == -2 )
		cbgn = 0
		cend = numChannels - 1
	elseif ( ( channel >= 0 ) && ( channel < numChannels ) )
		cbgn = channel
		cend = channel
	else
		//return NM2Error( 10, "channel", num2str( channel ) )
		return 0
	endif
	
	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
	
		gName = ChanGraphName( ccnt )
		
		if ( Wintype( gName ) == 0 )
			continue
		endif
		
		alist = AnnotationList( gName ) // list of tags
			
		for ( icnt = 0; icnt < ItemsInList( alist ); icnt += 1 )
			aName = StringFromList( icnt, alist )
			Tag /W=$gName /N=$aName /K // kill tags
		endfor
		
	endfor
	
	return 0
	
End // ChanGraphTagsKill

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphsToFront()

	Variable ccnt, cbgn, cend = NMNumChannels() - 1
	String gName, cdf
	
	for ( ccnt = cbgn; ccnt <= cend; ccnt+=1 )
		
		cdf = ChanDF( ccnt )
		
		if ( strlen( cdf ) == 0 )
			continue
		endif
		
		if ( NumVarOrDefault( cdf + "ToFront", 1 ) )
		
			gName = ChanGraphName( ccnt )
			
			if ( WinType( gName ) == 1 )
				DoWindow /F $gName
			endif
			
		endif
		
	endfor
	
End // ChanGraphsToFront

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphAxesSet( channel ) // set channel graph size and placement
	Variable channel // ( -1 ) for current channel
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	String gName = ChanGraphName( channel )
	String wname = ChanDisplayWave( channel )
	String cdf = ChanDF( channel )
	
	if ( ( strlen( cdf ) == 0 ) || ( WinType( gName ) != 1 ) )
		return -1
	endif
	
	Variable freezeX = NumVarOrDefault( cdf + "FreezeX", 0 )
	Variable freezeY = NumVarOrDefault( cdf + "FreezeY", 0 )
	
	Variable xmin = NumVarOrDefault( cdf + "Xmin", 0 )
	Variable xmax = NumVarOrDefault( cdf + "Xmax", 1 )
	Variable ymin = NumVarOrDefault( cdf + "Ymin", 0 )
	Variable ymax = NumVarOrDefault( cdf + "Ymax", 1 )
	
	if ( freezeX && freezeY )
		freezeX = 0
		freezeY = 0
	endif
	
	if ( freezeY )
	
		SetAxis /W=$gName/A
		SetAxis /W=$gName left ymin, ymax
		
		return 0
		
	elseif ( freezeX )
	
		WaveStats /Q/R=( xmin, xmax ) $wname
		
		ymin = V_min
		ymax = V_max
		
	endif
	
	SetAxis /W=$gName bottom xmin, xmax
	SetAxis /W=$gName left ymin, ymax
		
End // ChanGraphAxesSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanScaleSave( channel ) // save graph x-y ranges and graph positions
	Variable channel // ( -1 ) for current channel ( -2 ) for all channels
	
	Variable ccnt, cbgn, cend
	String gName, dName, cdf
	
	Variable numChannels = NMNumChannels()
	
	if ( channel == -1 )
		cbgn = CurrentNMChannel()
		cend = cbgn
	elseif ( channel == -2 )
		cbgn = 0
		cend = numChannels - 1
	elseif ( ( channel >= 0 ) && ( channel < numChannels ) )
		cbgn = channel
		cend = channel
	else
		//return NM2Error( 10, "channel", num2str( channel ) )
		return 0
	endif
	
	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
		
		cdf = ChanDF( ccnt )
		gName = ChanGraphName( ccnt )
		dName = ChanDisplayWave( ccnt )
		
		if ( ( strlen( cdf ) == 0 ) || ( WinType( gName ) != 1 ) )
			continue
		endif
		
		GetAxis /Q/W=$gName bottom
		
		if ( V_max > V_min )
			SetNMvar( cdf + "Xmin", V_min )
			SetNMvar( cdf + "Xmax", V_max )
		endif
		
		GetAxis /Q/W=$gName left
		
		if ( V_max > V_min )
			SetNMvar( cdf + "Ymin", V_min )
			SetNMvar( cdf + "Ymax", V_max )
		endif
		
		// save graph position
		
		GetWindow $gName wsize
		
		if ( ( V_right > V_left ) && ( V_top < V_bottom ) )
			SetNMvar( cdf + "GX0", V_left )
			SetNMvar( cdf + "GY0", V_top )
			SetNMvar( cdf + "GX1", V_right )
			SetNMvar( cdf + "GY1", V_bottom )
		endif
	
	endfor
	
	return 0
	
End // ChanScaleSave

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphMove( channel ) // set channel graph size and placement
	Variable channel // ( -1 ) for current channel ( -2 ) for all channels
	
	Variable ccnt, cbgn, cend, vleft, vtop, vright, vbottom, rows, columns, layers, scale
	Variable xyRatio, width, height
	String gName, dName, cdf
	
	Variable numChannels = NMNumChannels()
	
	if ( channel == -1 )
		cbgn = CurrentNMChannel()
		cend = cbgn
	elseif ( channel == -2 )
		cbgn = 0
		cend = numChannels - 1
	elseif ( ( channel >= 0 ) && ( channel < numChannels ) )
		cbgn = channel
		cend = channel
	else
		//return NM2Error( 10, "channel", num2str( channel ) )
		return 0
	endif
	
	for ( ccnt = cbgn ; ccnt <= cend ; ccnt += 1 )
		
		cdf = ChanDF( ccnt )
		gName = ChanGraphName( ccnt )
		dName = ChanDisplayWave( ccnt )
		
		if ( ( strlen( cdf ) == 0 ) || ( WinType ( gName ) != 1 ) )
			continue
		endif
		
		vleft = NumVarOrDefault( cdf + "GX0", Nan )
		vtop = NumVarOrDefault( cdf + "GY0", Nan )
		vright = NumVarOrDefault( cdf + "GX1", Nan )
		vbottom = NumVarOrDefault( cdf + "GY1", Nan )
		
		rows = DimSize( $dName, 0 )
		columns = DimSize( $dName, 1 )
		layers = DimSize( $dName, 2 )
		
		//if ( layers == 3 ) // image
		if (  columns > 0 ) // image
		
			if ( ( numtype( vleft * vtop * vbottom ) == 0 ) && ( vtop < vbottom ) )
			
				if ( NumVarOrDefault( cdf + "AutoScale", 1 ) )
					xyRatio = columns / rows
					height = vbottom - vtop - ImageMargin * 2
					width = height / xyRatio
					vright = vleft + width + ImageMargin * 2
				endif
				
				MoveWindow /W=$gName vleft, vtop, vright, vbottom
				
			endif
		
		else
		
			if ( ( numtype( vleft * vtop * vright * vbottom ) == 0 ) && ( vright > vleft ) && ( vtop < vbottom ) )
				MoveWindow /W=$gName vleft, vtop, vright, vbottom
			endif
		
		endif
	
	endfor

End // ChanGraphMove

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphsSetCoordinates() // NOT USED

	Variable ccnt
	
	for (ccnt = 0; ccnt < NMNumChannels(); ccnt+=1)
		ChanGraphSetCoordinates(ccnt)
	endfor

End // ChanGraphsSetCoordinates

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphSetCoordinates( channel ) // set default channel graph position
	Variable channel // ( -1 ) for current channel
	
	Variable yinc, width, height, ccnt, counter
	Variable xextra, yextra, yextra2, heightPcnt
	
	Variable widthPcnt = 0.7
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	String cdf = ChanDF( channel )
	
	if ( strlen( cdf ) == 0 )
		return -1
	endif
	
	Variable x0 = NumVarOrDefault( cdf + "GX0", Nan )
	Variable y0 = NumVarOrDefault( cdf + "GY0", Nan )
	Variable x1 = NumVarOrDefault( cdf + "GX1", Nan )
	Variable y1 = NumVarOrDefault( cdf + "GY1", Nan )
	
	Variable xpoints = NMScreenPointsX(igorFrame=1)
	Variable ypoints = NMScreenPointsY(igorFrame=1)
	String computer = NMComputerType()
	
	Variable numChannels = NMNumChannels()
	
	for ( ccnt = 0; ccnt < numChannels; ccnt+=1 )
	
		cdf = ChanDF( ccnt )
		
		if ( ( strlen( cdf ) > 0 ) && !NumVarOrDefault( cdf + "On", 1 ) )
			numChannels -= 1
		endif
		
	endfor
	
	if ( numChannels <= 0 )
		return -1
	elseif ( numChannels == 1 )
		heightPcnt = 0.5
	elseif ( numChannels == 2 )
		heightPcnt = 0.8
	else
		heightPcnt = 0.9
	endif
	
	for ( ccnt = 0; ccnt < channel; ccnt+=1 )
		
		cdf = ChanDF( ccnt )
		
		if ( strlen( cdf ) == 0 )
			continue
		endif
		
		if ( NumVarOrDefault( cdf + "On", 1 ) )
			counter += 1
		endif
		
	endfor
	
	cdf = ChanDF( channel )
	
	if ( numtype( x0 * y0 * x1 * y1 ) > 0 )
	
		strswitch( computer )
			case "pc":
				xextra = 5 // extra, adjusted by hand
				yextra = 40.25 // 42 // extra (menu bar), adjusted by hand
				yextra2 = 26 // top of graph
				//yinc = height + 26
				break
			default:
				xextra = 10
				yextra = 44
				yextra2 = 25
				//yinc = height + 25
				break
		endswitch
		
		width = ( xpoints - 2 * xextra) * widthPcnt
		height = ( ypoints - yextra2 * numChannels) * heightPcnt / numChannels
		
		x0 = xextra
		y0 = yextra + ( height + yextra2 ) * counter
		x1 = x0 + width
		y1 = y0 + height
		
		SetNMvar( cdf + "GX0", x0 )
		SetNMvar( cdf + "GY0", y0 )
		SetNMvar( cdf + "GX1", x1 )
		SetNMvar( cdf + "GY1", y1 )
	
	endif

End // ChanGraphSetCoordinates

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphClose( channel, KillFolders )
	Variable channel // ( -1 ) for current channel ( -2 ) for all channels ( -3 ) for all unecessary channels
	Variable KillFolders // to kill global variables

	Variable ccnt, cbgn, cend
	String gName, cdf, ndf = NMDF
	
	if ( NumVarOrDefault( ndf+"ChanGraphCloseBlock", 0 ) )
		//KillVariables /Z $( ndf+"ChanGraphCloseBlock" )
		return 0
	endif
	
	Variable numChannels = NMNumChannels()
	
	if ( channel == -1 )
		cbgn = CurrentNMChannel()
		cend = cbgn
	elseif ( channel == -2 )
		cbgn = 0
		cend = 9 // numChannels - 1
	elseif ( channel == -3 )
		cbgn = numChannels
		cend = cbgn + 10
	elseif ( ( channel >= 0 ) && ( channel < numChannels ) )
		cbgn = channel
		cend = channel
	else
		//return NM2Error( 10, "channel", num2str( channel ) )
		return 0
	endif
	
	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
	
		cdf = ChanDF( ccnt )
		gName = ChanGraphName( ccnt )
		
		if ( WinType( gName ) == 1 )
			DoWindow /K $gName
		endif
		
		if ( KillFolders && ( strlen( cdf ) > 0 ) && DataFolderExists( cdf ) )
			KillDataFolder $RemoveEnding( cdf, ":" )
		endif
		
	endfor
	
	return 0

End // ChanGraphClose

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGraphClear( channel )
	Variable channel // ( -1 ) for current channel ( -2 ) for all channels
	
	Variable ccnt, cbgn, cend
	String wname
	
	Variable numChannels = NMNumChannels()
	
	if ( channel == -1 )
		cbgn = CurrentNMChannel()
		cend = cbgn
	elseif ( channel == -2 )
		cbgn = 0
		cend = 9 // numChannels - 1
	elseif ( ( channel >= 0 ) && ( channel < numChannels ) )
		cbgn = channel
		cend = channel
	else
		//return NM2Error( 10, "channel", num2str( channel ) )
		return 0
	endif
	
	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
	
		wname = ChanDisplayWave( ccnt )
		
		ChanOverlayClear( ccnt )
		
		if ( WaveExists( $wname ) )
			Wave wtemp = $wname
			wtemp = Nan
		endif
		
	endfor

End // ChanGraphClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChannelGraphDisable( [ channel, filter, transform, autoscale, popMenu, all ] )
	Variable channel // ( -1 ) for current channel ( -2 ) for all channels
	Variable filter, transform, autoscale, popMenu, all // ( 0 ) enable control ( 1 ) disable control
	
	Variable ccnt, cbgn, cend
	Variable z_filter = NaN, z_transform = NaN, z_autoscale = NaN, z_popMenu = NaN
	String cc, gName
	
	Variable numChannels = NMNumChannels()
	
	if ( channel == -1 )
		cbgn = CurrentNMChannel()
		cend = cbgn
	elseif ( channel == -2 )
		cbgn = 0
		cend = numChannels - 1
	elseif ( ( channel >= 0 ) && ( channel < numChannels ) )
		cbgn = channel
		cend = channel
	else
		//return NM2Error( 10, "channel", num2str( channel ) )
		return 0 // nothing to do
	endif
	
	if ( ParamIsDefault( all ) )
	
		if ( !ParamIsDefault( filter ) )
			z_filter = binarycheck( filter )
		endif
		
		if ( !ParamIsDefault( transform ) )
			z_transform = binarycheck( transform )
		endif
		
		if ( !ParamIsDefault( autoscale ) )
			z_autoscale = binarycheck( autoscale )
		endif
		
		if ( !ParamIsDefault( popMenu ) )
			z_popMenu = binarycheck( popMenu )
		endif
	
	
	else
	
		all = BinaryCheck( all )
		
		z_filter = all
		z_transform = all
		z_autoscale = all
		z_popMenu = all
		
	endif
	
	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
		
		cc = num2istr( ccnt )
		gName = ChanGraphName( ccnt )
		
		if ( WinType( gName ) != 1 )
			continue
		endif

		if ( !ParamIsDefault( filter ) )
			SetVariable $( "SmoothSet"+cc ), disable=z_filter, win=$gName
		endif
		
		if ( !ParamIsDefault( transform ) )
			CheckBox $( "TransformCheck"+cc ), disable=z_transform, win=$gName
		endif
		
		if ( !ParamIsDefault( autoscale ) )
			CheckBox $( "ScaleCheck"+cc ), disable=z_autoscale, win=$gName
		endif
		
		if ( !ParamIsDefault( popMenu ) )
			PopupMenu $( "PlotMenu"+cc ), disable=z_popMenu, win=$gName
		endif
		
	endfor
	
	return 0

End // NMChannelGraphDisable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanPopup( ctrlName, popNum, popStr ) : PopupMenuControl // display graph menu
	String ctrlName; Variable popNum; String popStr
	
	Variable channel
	
	sscanf ctrlName, "PlotMenu%f", channel // determine chan number
	
	PopupMenu $ctrlName, mode=1 // reset the drop-down menu
	
	ChanCall( popStr, channel, "" )

End // NMChanPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanCheckbox( ctrlName, checked ) : CheckBoxControl // change differentiation flag
	String ctrlName; Variable checked
	
	Variable channel, rvalue
	String numstr = num2istr( checked )
	String cname = z_ControlPrefix( ctrlName )
	
	sscanf ctrlName, cname + "%f", channel // determine channel number
	
	return ChanCall( cname, channel, numstr )

End // NMChanCheckbox

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanSetVariable( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	Variable channel, rvalue
	
	strswitch( z_ControlPrefix( ctrlName ) )
	
		case "SmoothSet":
			sscanf ctrlName, "SmoothSet%f", channel // determine channel number
			return ChanCall( "Filter", channel, varStr )

		//case "Overlay":
			//sscanf ctrlName, "Overlay%f", channel // determine channel number
			//return ChanCall( "Overlay", channel, varStr )
	
	endswitch
	
End // NMChanSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S z_ControlPrefix( ctrlName )
	String ctrlName
	
	Variable icnt
	
	for ( icnt = strlen( ctrlName )-1; icnt > 0; icnt -= 1 )
		if ( numtype( str2num( ctrlName[icnt,icnt] ) ) > 0 )
			break
		endif
	endfor
	
	return ctrlName[0,icnt]

End // z_ControlPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanOverlayUpdate( channel [ xWave ] )
	Variable channel // ( -1 ) for current channel
	String xWave
	
	Variable tMode, tMarker, tLineStyle, tLineSize
	String xdName, xodName
	
	STRUCT NMRGB c
	
	if ( channel < 0 )
		channel = CurrentNMChannel()
	endif
	
	if ( ParamIsDefault( xWave ) )
		xWave = ""
	endif
	
	String cdf = ChanDF( channel )
	String gName = ChanGraphName( channel )
	
	if ( ( strlen( cdf ) == 0 ) || ( WinType( gName ) != 1 ) )
		return -1
	endif
	
	Variable overlay = NumVarOrDefault( cdf + "Overlay", 0 )
	Variable ocnt = NumVarOrDefault( cdf + "OverlayCount", 0 )
	
	String tColor = StrVarOrDefault( cdf + "TraceColor", NMStrGet( "ChanGraphTraceColor" ) )
	String oColor = StrVarOrDefault( cdf + "OverlayColor", NMStrGet( "ChanGraphTraceOverlayColor" ) )
	
	tMode = NumVarOrDefault( cdf + "TraceMode", NMVarGet( "ChanGraphTraceMode" ) )
	tMarker = NumVarOrDefault( cdf + "TraceMarker", NMVarGet( "ChanGraphTraceMarker" ) )
	tLineStyle = NumVarOrDefault( cdf + "TraceLineStyle", NMVarGet( "ChanGraphTraceLineStyle" ) )
	tLineSize = NumVarOrDefault( cdf + "TraceLineSize", NMVarGet( "ChanGraphTraceLineSize" ) )
	
	if ( !overlay )
		return -1
	endif
	
	if ( ocnt == 0 )
		SetNMvar( cdf + "OverlayCount", 1 )
		return 0
	endif
	
	String dName = ChanDisplayWave( channel )
	String dNameShort = NMChild( dName )
	
	String odName = ChanDisplayWaveName( 1, channel, ocnt )
	String odNameShort = NMChild( odName )
	
	String wList = TraceNameList( gName,";",1 )
	
	if ( StringMatch( dName, odName ) )
		return -1
	endif
	
	Duplicate /O $dName $odName
	
	if ( WaveExists( $xWave ) )
		xdName = NMChanDisplayWaveNameX( dName )
		xodName = NMChanDisplayWaveNameX( odName )
		Duplicate /O $xdName $xodName
	endif
	
	RemoveWaveUnits( odName )
	
	if ( WhichListItem( odNameShort, wList, ";", 0, 0 ) < 0 )
	
		if ( WaveExists( $xWave ) )
			//AppendToGraph /W=$gName $odName vs $xWave
			AppendToGraph /W=$gName $odName vs $xodName
		else
			AppendToGraph /W=$gName $odName
		endif
		
		NMColorList2RGB( oColor, c )
	
		ModifyGraph /W=$gName rgb( $odNameShort )=(c.r,c.g,c.b)
		ModifyGraph /W=$gName mode( $odNameShort )=( tMode )
		ModifyGraph /W=$gName marker( $odNameShort )=( tMarker )
		ModifyGraph /W=$gName lstyle( $odNameShort )=( tLineStyle )
		ModifyGraph /W=$gName lsize( $odNameShort )=( tLineSize )
		
		odName = ChanDisplayWaveName( 1, channel, 0 )
		odNameShort = NMChild( odName )
		
		RemoveFromGraph /W=$gName/Z $odNameShort
		
		if ( WaveExists( $xWave ) )
			xodName = NMChanDisplayWaveNameX( odName )
			//AppendToGraph /W=$gName $odName vs $xWave
			AppendToGraph /W=$gName $odName vs $xodName
		else
			AppendToGraph /W=$gName $odName
		endif
		
		NMColorList2RGB( tColor, c )
		
		ModifyGraph /W=$gName rgb( $odNameShort )=(c.r,c.g,c.b)
		ModifyGraph /W=$gName mode( $odNameShort )=( tMode )
		ModifyGraph /W=$gName marker( $odNameShort )=( tMarker )
		ModifyGraph /W=$gName lstyle( $odNameShort )=( tLineStyle )
		ModifyGraph /W=$gName lsize( $odNameShort )=( tLineSize )
		
	endif

	ocnt += 1
	
	if ( ocnt > overlay )
		ocnt = 1
	endif
	
	SetNMvar( cdf + "OverlayCount", ocnt )
	
	return 0

End // ChanOverlayUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanOverlayClear( channel )
	Variable channel // ( -1 ) for current channel ( -2 ) for all channels
	
	Variable wcnt, ccnt, cbgn, cend
	String gName, wname, xName, wList, cdf
	
	Variable numChannels = NMNumChannels()
	
	if ( channel == -1 )
		cbgn = CurrentNMChannel()
		cend = cbgn
	elseif ( channel == -2 )
		cbgn = 0
		cend = numChannels - 1
	//elseif ( ( channel >= 0 ) && ( channel < numChannels ) )
	elseif ( channel >= 0 )
		cbgn = channel
		cend = channel
	else
		//return NM2Error( 10, "channel", num2str( channel ) )
		return 0 // nothing to do
	endif
	
	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
	
		wname = ChanDisplayWave( ccnt )
		xName = ChanDisplayWaveName( 0, ccnt, 0 )
		gName = ChanGraphName( ccnt )
		cdf = ChanDF( ccnt )
		
		if ( WinType( gName ) == 1 )
			
			wList = TraceNameList( gName,";",1 )
			wList = RemoveFromList( xName, wList )
			
			for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
				RemoveFromGraph /W=$gName/Z $StringFromList( wcnt, wList )
			endfor
		
		endif
		
		if ( strlen( cdf ) > 0 )
			SetNMvar( cdf + "OverlayCount", 0 )
		endif
		
	endfor
	
	return 0

End // ChanOverlayClear

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanOverlayKill( channel )
	Variable channel // ( -1 ) for current channel ( -2 ) for all channels

	Variable cbgn, cend
	
	Variable wcnt, ccnt, overlay
	String wName, xName, wList, cdf
	
	Variable numChannels = NMNumChannels()
	
	if ( channel == -1 )
		cbgn = CurrentNMChannel()
		cend = cbgn
	elseif ( channel == -2 )
		cbgn = 0
		cend = numChannels - 1
	elseif ( ( channel >= 0 ) && ( channel < numChannels ) )
		cbgn = channel
		cend = channel
	else
		//return NM2Error( 10, "channel", num2str( channel ) )
		return 0 // nothing to do
	endif

	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
	
		cdf = ChanDF( ccnt )
		
		if ( strlen( cdf ) == 0 )
			continue
		endif
	
		wList = NMFolderWaveList( NMDF, "Display" + ChanNum2Char( ccnt ) + "*", ";", "", 0 )
	
		overlay = NumVarOrDefault( cdf + "Overlay", 0 )
	
		for ( wcnt = 0; wcnt <= overlay; wcnt += 1 )
			wName = ChanDisplayWaveName( 0, ccnt, wcnt )
			wList = RemoveFromList( wName, wList )
		endfor
		
		for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
			wName = StringFromList( wcnt, wList )
			xName = "xScale_" + wName
			KillWaves /Z $NMDF+wName
			KillWaves /Z $NMDF+xName
		endfor
		
	endfor
	
	return 0

End // ChanOverlayKill

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Channel Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMChannelGraphSet( [ channel, autoScale, freezeX, freezeY, xmin, xmax, ymin, ymax, overlayNum, overlayColor, grid, gridColor, traceMode, traceMarker, traceLineStyle, traceLineSize, errors, errorPointsLimit, toFront, drag, left, top, right, bottom, reposition, on, prefixFolder, update, history ] )
	
	Variable channel // ( -1 ) for current channel ( -2 ) for all channels
	
	Variable autoScale, freezeX, freezeY // auto-scaling
	Variable xmin, xmax, ymin, ymax // x-scale and y-scale min/max values
	
	Variable overlayNum // number of waves to overlay
	String overlayColor // overlay wave color (rgb list)
	
	Variable grid // ( 0 ) off ( 1 ) on
	String gridColor // grid color (rgb list)
	
	Variable traceMode // 0 - 8
	Variable traceMarker // 0 - 62
	Variable traceLineStyle // 0 - 17
	Variable traceLineSize // > 0
	Variable errors // ( 0 ) off ( 1 ) on
	Variable errorPointsLimit // upper points limit for displaying errors
	Variable toFront // ( 0 ) off ( 1 ) on
	Variable drag // vertical drag waves ( 0 ) off ( 1 ) on
	
	Variable left, top, right, bottom // graph window coordinates
	Variable reposition // reset graph positions
	
	Variable on // ( 0 ) hide graph ( 1 ) show graph
	
	String prefixFolder
	
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable updateNM, updateAll, ccnt, cbgn = 0, cend = -1
	Variable numChannels, currentChannel
	String gName, dName, dNameShort, vlist = "", vlist2 = "", cdf = ""
	
	STRUCT NMRGB c
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( ParamIsDefault( prefixFolder ) )
	
		prefixFolder = CurrentNMPrefixFolder()
		
	else
	
		if ( strlen( prefixFolder ) > 0 )
			vlist2 = NMCmdStrOptional( "prefixFolder", prefixFolder, vlist2 )
		elseif ( NMPrefixFolderHistory && ( strlen( prefixFolder ) == 0 ) )
			prefixFolder = CurrentNMPrefixFolder()
			vlist2 = NMCmdStrOptional( "prefixFolder", prefixFolder, vlist2 )
		endif
		
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
		
	endif
	
	numChannels =  NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	currentChannel = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	
	if ( ParamIsDefault( channel ) )
		channel = currentChannel
	else
		vlist = NMCmdNumOptional( "channel", channel, vlist, integer = 1 )
	endif
	
	if ( numtype( channel ) == 0 )
	
		if ( channel == -1 )
			cbgn = currentChannel
			cend = cbgn
		elseif ( channel == -2 )
			cbgn = 0
			cend = numChannels - 1
		elseif ( ( channel >= 0 ) && ( channel < numChannels ) )
			cbgn = channel
			cend = channel
		else
			//return NM2Error( 10, "channel", num2str( channel ) )
			return 0
		endif
		
		for ( ccnt = cbgn ; ccnt <= cend ; ccnt += 1 )
		
			cdf = ChanDF( ccnt, prefixFolder = prefixFolder )
			gName = ChanGraphName( ccnt )
			
			if ( !DataFolderExists( cdf ) )
				continue
			endif
			
			if ( !ParamIsDefault( autoscale ) )
			
				vlist = NMCmdNumOptional( "autoscale", autoscale, vlist, integer = 1 )
			
				autoscale = BinaryCheck( autoscale )
			
				if ( !autoscale )
					ChanScaleSave( ccnt )
				endif
	
				SetNMvar( cdf + "AutoScale", autoscale )
				SetNMvar( cdf + "FreezeX", 0 ) // turn off
				SetNMvar( cdf + "FreezeY", 0 ) // turn off
				
				updateNM = 1
			
			endif
			
			if ( !ParamIsDefault( freezeX ) )
			
				vlist = NMCmdNumOptional( "freezeX", freezeX, vlist, integer = 1 )
			
				freezeX = BinaryCheck( freezeX )
	
				if ( freezeX )
					SetNMvar( cdf + "AutoScale", 0 )
					SetNMvar( cdf + "FreezeX", 1 )
					SetNMvar( cdf + "FreezeY", 0 )
				else
					SetNMvar( cdf + "AutoScale", 1 )
					SetNMvar( cdf + "FreezeX", 0 )
					SetNMvar( cdf + "FreezeY", 0 )
				endif
				
				updateNM = 1
			
			endif
			
			if ( !ParamIsDefault( freezeY ) )
			
				vlist = NMCmdNumOptional( "freezeY", freezeY, vlist, integer = 1 )
			
				freezeY = BinaryCheck( freezeY )
	
				if ( freezeY )
					SetNMvar( cdf + "AutoScale", 0 )
					SetNMvar( cdf + "FreezeX", 0 )
					SetNMvar( cdf + "FreezeY", 1 )
				else
					SetNMvar( cdf + "AutoScale", 1 )
					SetNMvar( cdf + "FreezeX", 0 )
					SetNMvar( cdf + "FreezeY", 0 )
				endif
				
				updateNM = 1
			
			endif
			
			if ( !ParamIsDefault( xmin ) && !ParamIsDefault( xmax ) )
			
				vlist = NMCmdNumOptional( "xmin", xmin, vlist )
				vlist = NMCmdNumOptional( "xmax", xmax, vlist )
			
				if ( ( numtype( xmin * xmax ) == 0 ) && ( WinType( gName ) == 1 ) )
				
					SetAxis /W=$gName bottom xmin, xmax
					DoUpdate /W=$gName
	
					SetNMvar( cdf + "Xmin", xmin )
					SetNMvar( cdf + "Xmax", xmax )
					SetNMvar( cdf + "AutoScale", 0 )
					SetNMvar( cdf + "FreezeX", 1 )
					updateNM = 1
					
				endif
			
			endif
			
			if ( !ParamIsDefault( ymin ) && !ParamIsDefault( ymax ) )
			
				vlist = NMCmdNumOptional( "ymin", ymin, vlist )
				vlist = NMCmdNumOptional( "ymax", ymax, vlist )
			
				if ( ( numtype( ymin * ymax ) == 0 ) && ( WinType( gName ) == 1 ) )
				
					SetAxis /W=$gName left ymin, ymax
					DoUpdate /W=$gName
					
					SetNMvar( cdf + "Ymin", ymin )
					SetNMvar( cdf + "Ymax", xmax )
					SetNMvar( cdf + "AutoScale", 0 )
					SetNMvar( cdf + "FreezeY", 1 )
					updateNM = 1
					
				endif
			
			endif
			
			if ( !ParamIsDefault( overlayNum ) )
			
				vlist = NMCmdNumOptional( "overlayNum", overlayNum, vlist, integer = 1 )
			
				if ( ( numtype( overlayNum ) > 0 ) || ( overlayNum < 0 ) )
					overlayNum = 0
				endif
	
				ChanOverlayClear( ccnt )
			
				SetNMvar( cdf + "Overlay", overlayNum )
				SetNMvar( cdf + "OverlayCount", 1 )
			
				ChanOverlayKill( ccnt )
				
			endif
			
			if ( !ParamIsDefault( overlayColor ) )
			
				vlist = NMCmdStrOptional( "overlayColor", overlayColor, vlist )
				
				if ( NMisRGBlist( overlayColor ) )
					ChanOverlayClear( ccnt )
					SetNMstr( cdf + "OverlayColor", overlayColor )
				endif
				
			endif
			
			if ( !ParamIsDefault( grid ) )
			
				vlist = NMCmdNumOptional( "grid", grid, vlist, integer = 1 )
				
				grid = BinaryCheck( grid )
				
				SetNMvar( cdf + "Grid", grid )
				
				ModifyGraph /W=$gName grid=( grid )
				
				updateNM = 1
				
			endif
			
			if ( !ParamIsDefault( gridColor ) )
			
				vlist = NMCmdStrOptional( "gridColor", gridColor, vlist )
				
				if ( NMisRGBlist( gridColor ) )
				
					SetNMstr( cdf + "GridColor", gridColor )
					
					NMColorList2RGB( gridColor, c )
					
					ModifyGraph /W=$gName gridRGB=(c.r,c.g,c.b)
				
					updateNM = 1
				
				endif
				
			endif
			
			if ( !ParamIsDefault( traceMode ) )
	
				vlist = NMCmdNumOptional( "traceMode", traceMode, vlist, integer = 1 )
				
				if ( ( traceMode >= 0 ) && ( traceMode <= TraceModeMax ) )
				
					SetNMvar( cdf + "TraceMode", traceMode )
						
					dName = ChanDisplayWave( ccnt )
					dNameShort = NMChild( dName )
					
					ModifyGraph /W=$gName mode( $dNameShort )=( traceMode )
					
					updateNM = 1
						
				endif
	
			endif
			
			if ( !ParamIsDefault( traceMarker ) )
	
				vlist = NMCmdNumOptional( "traceMarker", traceMarker, vlist, integer = 1 )
				
				if ( ( traceMarker >= 0 ) && ( traceMarker <= TraceMarkerMax ) )
			
					SetNMvar( cdf + "TraceMarker", traceMarker )
							
					dName = ChanDisplayWave( ccnt )
					dNameShort = NMChild( dName )
					
					ModifyGraph /W=$gName marker( $dNameShort )=( traceMarker )
					
					updateNM = 1
				
				endif
	
			endif
			
			if ( !ParamIsDefault( traceLineStyle ) )
	
				vlist = NMCmdNumOptional( "traceLineStyle", traceLineStyle, vlist, integer = 1 )
				
				if ( ( traceLineStyle >= 0 ) && ( traceLineStyle <= TraceLineStyleMax ) )
			
					SetNMvar( cdf + "TraceLineStyle", traceLineStyle)
							
					dName = ChanDisplayWave( ccnt )
					dNameShort = NMChild( dName )
					
					ModifyGraph /W=$gName lstyle( $dNameShort )=( traceLineStyle )
					
					updateNM = 1
				
				endif
	
			endif
			
			if ( !ParamIsDefault( traceLineSize ) )
	
				vlist = NMCmdNumOptional( "traceLineSize", traceLineSize, vlist )
				
				if ( traceLineSize >= 0 )
			
					SetNMvar( cdf + "TraceLineSize", traceLineSize)
							
					dName = ChanDisplayWave( ccnt )
					dNameShort = NMChild( dName )
					
					ModifyGraph /W=$gName lsize( $dNameShort )=( traceLineSize )
					
					updateNM = 1
				
				endif
	
			endif
			
			if ( !ParamIsDefault( errors ) )
			
				vlist = NMCmdNumOptional( "errors", errors, vlist, integer = 1 )
				
				SetNMvar( cdf + "ErrorsOn", BinaryCheck( errors ) )
				updateNM = 1
				
			endif
			
			if ( !ParamIsDefault( toFront ) )
			
				vlist = NMCmdNumOptional( "toFront", toFront, vlist, integer = 1 )
				
				SetNMvar( cdf + "ToFront", BinaryCheck( toFront ) )
				updateNM = 1
				
			endif
			
			if ( !ParamIsDefault( left ) && !ParamIsDefault( top ) && !ParamIsDefault( right ) && !ParamIsDefault( bottom ) )
			
				vlist = NMCmdNumOptional( "left", left, vlist )
				vlist = NMCmdNumOptional( "top", top, vlist )
				vlist = NMCmdNumOptional( "right", right, vlist )
				vlist = NMCmdNumOptional( "bottom", bottom, vlist )
			
				if ( ( numtype( left * top * right * bottom ) == 0 ) && ( right > left ) && ( top < bottom ) ) 
					MoveWindow /W=$gName left, top, right, bottom
					updateNM = 1
				endif
	
			endif
			
			if ( !ParamIsDefault( reposition ) && reposition )
			
				vlist = NMCmdNumOptional( "reposition", reposition, vlist, integer = 1 )
			
				SetNMvar( cdf + "GX0", Nan )
				SetNMvar( cdf + "GY0", Nan )
				SetNMvar( cdf + "GX1", Nan )
				SetNMvar( cdf + "GY1", Nan )
			
				ChanGraphSetCoordinates( ccnt )
				ChanGraphMove( ccnt )
				updateNM = 1
				
			endif
			
			if ( !ParamIsDefault( on ) )
			
				vlist = NMCmdNumOptional( "on", on, vlist, integer = 1 )
				
				SetNMvar( cdf + "On", BinaryCheck( on ) )
				updateNM = 1
				
			endif
			
		endfor
	
	endif
	
	if ( !ParamIsDefault( errorPointsLimit )  && ( errorPointsLimit >= 0 ) )
	
		vlist = NMCmdNumOptional( "errorPointsLimit", errorPointsLimit, vlist, integer = 1 )
		
		NMConfigVarSet( "NM" , "ErrorPointsLimit" , errorPointsLimit )
		updateAll = 1
		
	endif
	
	if ( !ParamIsDefault( drag ) )
	
		vlist = NMCmdNumOptional( "drag", drag, vlist, integer = 1 )
			
		drag = BinaryCheck( drag )
		SetNMvar( NMDF + "DragOn", drag )

		if ( drag )
		
			Execute /Z CurrentNMTabName() + "Tab( 1 )" // should append drag waves for specific tab
			
		else
			
			for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
				gName = ChanGraphName( ccnt )
				NMDragGraphUtility( gName, "remove" )
			endfor
	
		endif

	endif
	
	if ( history )
		NMCommandHistory( vlist + vlist2 )
	endif
	
	if ( update )
	
		if ( updateAll )
		
			ChanGraphsUpdate()
			
		elseif ( updateNM )
		
			for ( ccnt = cbgn ; ccnt <= cend ; ccnt += 1 )
				NMChanGraphUpdate( channel = ccnt )
				ChanGraphControlsUpdate( ccnt )
			endfor
			
		endif
	
	endif
	
End // NMChannelGraphSet

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanCall( fxn, channel, select )
	String fxn
	Variable channel
	String select
	
	Variable snum = str2num( select )

	strswitch( fxn )
	
		case "Grid":
			return ChanGridCall( channel )
			
		case "XLabel":
			return ChanLabelCall( channel, "x" )
			
		case "YLabel":
			return ChanLabelCall( channel, "y" )
			
		case "Reset Position":
			return NMChannelGraphSet( channel = channel , reposition = 1, history = 1 )
			
		case "Drag":
			return ChanDragCall()

		case "Off":
			return z_ChanGraphOnCall( channel, on = 0 )
			
		case "Overlay":
			return z_OverlayCall( channel )
			
		case "Filter":
			return ChanFilterNumCall( channel, snum )
			
		case "AutoScale":
		case "ScaleCheck":
			return NMChannelGraphSet( channel = channel, autoscale = snum, history = 1 )
			
		case "FreezeX":
			return NMChannelGraphSet( channel = channel, freezeX = 1, history = 1 )
		
		case "FreezeY":
			return NMChannelGraphSet( channel = channel, freezeY = 1, history = 1 )
			
		case "ToFront":
		case "To Front":
			return z_ToFrontCall( channel )
			
		case "F(t)":
		case "F( t )":
		case "TransformCheck":
		case "Transform":
			NMChanTransformCall( channel, snum )
			return 0
			
		case "Errors":
			return NMChanErrorsCall( channel )
			
		default:
			NMDoAlert( "ChanCall: unrecognized function call: " + fxn )
	
	endswitch
	
End // ChanCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanErrorsCall( channel )
	Variable channel // ( -1 ) for current channel
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	Variable newErrors, newPointsLimit
	String vlist, cdf = ChanDF( channel )
	
	if ( strlen( cdf ) == 0 )
		return 0
	endif

	Variable errors = NumVarOrDefault( cdf + "ErrorsOn", 1 )
	Variable pointsLimit = NMVarGet( "ErrorPointsLimit" )
	
	newErrors = errors + 1
	newPointsLimit = pointsLimit
	
	Prompt newErrors, "display STDV or SEM if appropriate waves exist?", popup "no;yes;"
	Prompt newPointsLimit, "upper limit for drawing error bar lines (data points):"
	DoPrompt "Channel Wave STDV or SEM", newErrors, newPointsLimit
	
	if ( V_flag == 1 )
		return 0
	endif
	
	newErrors -= 1
	
	if ( newErrors != errors )
		NMChannelGraphSet( channel = channel, errors = newErrors, history = 1 )
	endif
	
	if ( newPointsLimit != pointsLimit )
		NMChannelGraphSet( errorPointsLimit = newPointsLimit, history = 1 )
	endif
	
	return 0
	
End // NMChanErrorsCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanLabelCall( channel, xySelect ) // set channel labels
	Variable channel // ( -1 ) for current channel
	String xySelect // "x" or "y"
	
	Variable waveSelect = 2
	String labelStr
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	strswitch( xySelect )
	
		case "x":
			labelStr = NMChanLabelX( channel = channel )
			channel = -2
			break
			
		case "y":
			labelStr = NMChanLabelY( channel = channel )
			break
			
		default:
			return -1
	
	endswitch
	
	Prompt labelStr, xySelect + " label:"
	
	DoPrompt "Set Channel Label", labelStr
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
		
	NMChanLabelSet( channel, waveSelect, xySelect, labelStr, history = 1 )
	
	return 0

End // ChanLabelCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanGridCall( channel )
	Variable channel // ( -1 ) for current channel
	
	String cdf
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	cdf = ChanDF( channel )
	
	if ( strlen( cdf ) == 0 )
		return -1
	endif
	
	Variable grid = 1 + NumVarOrDefault( cdf + "Grid", NMVarGet( "ChanGraphGrid" ) )
	
	Prompt grid, "turn axes grid lines:", popup "off;on;"
	DoPrompt "Channel Grid Lines", grid
	
	if ( V_flag == 1 )
		return 0
	endif
	
	grid -= 1
	
	NMChannelGraphSet( channel = channel, grid = grid, history = 1 )
	
End // ChanGridCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanDragCall()
	
	Variable drag = 1 + NMVarGet( "DragOn" )
	
	Prompt drag, "turn vertical red / green drag waves:", popup "off;on;"
	DoPrompt "Channel Drag Waves", drag
	
	if ( V_flag == 1 )
		return 0
	endif
	
	drag -= 1
	
	return NMChannelGraphSet( drag = drag, history = 1 )
	
End // ChanDragCall

//****************************************************************
//****************************************************************
//****************************************************************

Static Function z_ToFrontCall( channel )
	Variable channel // ( -1 ) for current channel
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	String cdf = ChanDF( channel )
	
	if ( strlen( cdf ) == 0 )
		return -1
	endif
	
	Variable toFront = 1 + NumVarOrDefault( cdf + "ToFront", 1 )
		
	Prompt toFront, "keep channel graph in front of others?", popup "no;yes;"
	DoPrompt "Channel Graph To Front", toFront
	
	if ( V_flag == 1 )
		return 0
	endif
	
	toFront -= 1
	
	return NMChannelGraphSet( channel = channel, toFront = toFront, history = 1 )
	
End // z_ToFrontCall

//****************************************************************
//****************************************************************
//****************************************************************

Static Function z_ChanGraphOnCall( channel [ on ] )
	Variable channel // ( -1 ) for current channel
	Variable on
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	String cdf = ChanDF( channel )
	
	if ( strlen( cdf ) == 0 )
		return -1
	endif
	
	if ( ParamIsDefault( on ) )
		on = NumVarOrDefault( cdf + "On", 1 )
	endif
	
	on += 1
	
	Prompt on, "display channel graph:", popup "no;yes;"
	DoPrompt "Channel Graph", on
	
	if ( V_flag == 1 )
		return 0
	endif
	
	on -= 1
	
	return NMChannelGraphSet( channel = channel, on = on, history = 1 )
	
End // z_ChanGraphOnCall

//****************************************************************
//****************************************************************
//****************************************************************

Static Function z_OverlayCall( channel )
	Variable channel // ( -1 ) for current channel
	
	Variable newNumber
	String newColor, cdf
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	cdf = ChanDF( channel )
	
	if ( strlen( cdf ) == 0 )
		return -1
	endif
	
	Variable overlayNum = NumVarOrDefault( cdf + "Overlay", 0 )
	String color = StrVarOrDefault( cdf + "OverlayColor", NMStrGet( "ChanGraphTraceOverlayColor" ) )
	
	newNumber = overlayNum
	newColor = color
	
	Prompt newNumber, "number of waves to overlay:"
	Prompt newColor, "overlay wave color (r,g,b):"
	DoPrompt "Channel Graph Overlay", newNumber, newColor
	
	if ( V_flag == 1 )
		return 0
	endif
	
	if ( ( numtype( newNumber ) > 0 ) || ( newNumber < 0 ) )
		newNumber = 0
	endif
	
	if ( newNumber != overlayNum )
		NMChannelGraphSet( channel = channel, overlayNum = newNumber, history = 1 )
	endif
	
	if ( !StringMatch( color, newColor ) )
		NMChannelGraphSet( channel = channel, overlayColor = newColor, history = 1 )
	endif
	
	return 0
	
End // z_OverlayCall

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Channel Transform and Filter Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanTransformProc( channel )
	Variable channel // ( -1 ) for current channel
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	return StrVarOrDefault( NMDF + "ChanTransformProc" + num2istr( channel ), "NMChanCheckbox" )

End // NMChanTransformProc

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanTransformDF( channel [ prefixFolder ] )
	Variable channel // ( -1 ) for current channel
	String prefixFolder
	
	String cdf
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	if ( channel == -1 )
		channel = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	endif
	
	cdf = ChanDF( channel, prefixFolder = prefixFolder )
	
	return StrVarOrDefault( NMDF + "ChanTransformDF" + num2istr( channel ), cdf )

End // NMChanTransformDF

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanTransformName( ft )
	Variable ft // ( 0 ) none ( > 0 ) see NMChanTransformList
	
	// old transform flag, not used anymore
	// one should use "Transform" string variable instead
	
	switch( ft )
		case 0:
			return "Off"
		case 1:
			return "Differentiate"
		case 2:
			return "Double Differentiate"
		case 3:
			return "Integrate"
		case 4:
			return "Normalize"
		case 5:
			return "dF/Fo"
		case 6:
			return "Baseline"
		case 7:
			return "Running Average"
		case 8:
			return "Histogram"
		case 9:
			return "Clip Events" 
	endswitch
	
	return "Off"
	
End // NMChanTransformName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanTransformExists( [ channel, chanCharList, prefixFolder, includeFilter ] )
	Variable channel
	String chanCharList
	String prefixFolder
	Variable includeFilter // or if filter exists
	
	Variable filterNum, ccnt, numChannels
	String transform, filterAlg, chanChar
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	if ( ParamIsDefault( channel ) )
	
		if ( ParamIsDefault( chanCharList ) )
		
			channel = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
			
			if ( ( channel >= 0 ) && ( channel < numChannels ) )
				chanCharList = ChanNum2Char( channel )
			else
				return 0
			endif
			
		endif
		
	else
	
		if ( channel < 0 )
			channel = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
		endif
		
		chanCharList = ChanNum2Char( channel )
		
	endif
	
	if ( ItemsInList( chanCharList ) == 0 )
		return 0
	endif
	
	if ( ParamIsDefault( includeFilter ) )
		includeFilter = 1
	endif
	
	for ( ccnt = 0; ccnt < ItemsInList( chanCharList ) ; ccnt += 1 )
	
		chanChar = StringFromList( ccnt, chanCharList )
		channel = ChanChar2Num( chanChar )
	
		transform = NMChanTransformGet( channel, prefixFolder = prefixFolder )
		transform = StringFromList( 0, transform, "," )
		
		if ( WhichListItem( transform, NMChanTransformList ) >= 0 )
			return 1 // found transform
		endif
	
	endfor
	
	if ( !includeFilter )
		return 0
	endif
	
	for ( ccnt = 0; ccnt < ItemsInList( chanCharList ) ; ccnt += 1 )
	
		chanChar = StringFromList( ccnt, chanCharList )
		channel = ChanChar2Num( chanChar )
	
		filterNum = ChanFilterNumGet( channel, prefixFolder = prefixFolder )
		filterAlg = ChanFilterAlgGet( channel, prefixFolder = prefixFolder )
		
		if ( ( filterNum > 0 ) && ( strlen( filterAlg ) > 0 ) )
			return 1 // found filter
		endif
	
	endfor
	
	return 0
	
End // NMChanTransformExists

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanTransformGet( channel [ prefixFolder, itemNum, errorAlert ] )
	Variable channel // ( -1 ) for current channel
	String prefixFolder
	Variable itemNum // transform list item number ( otherwise will return all items )
	Variable errorAlert // ( 0 ) no ( 1 ) yes
	
	Variable icnt
	String cdf, transformList, tList, alertStr
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	if ( ParamIsDefault( itemNum ) )
		itemNum = -1
	endif
	
	if ( channel == -1 )
		channel = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	endif
	
	cdf = NMChanTransformDF( channel, prefixFolder = prefixFolder )
	
	if ( strlen( cdf ) == 0 )
		return "Off"
	endif
	
	transformList = StrVarOrDefault( cdf + "TransformStr", "Off" )
	
	for ( icnt = 0 ; icnt < ItemsInList( transformList, ";" ) ; icnt += 1 )
	
		tList = StringFromList( icnt, transformList, ";" )
		
		if ( NMChanTransformCheck( tList ) )
			if ( errorAlert )
				alertStr = "Encountered one or more bad parameters for transform = " + tList + ". Please reset this transform for Channel " + ChanNum2Char( channel ) + "."
				NMDoAlert( alertStr, title = "NM Channel Transform Error" )
				NMHistory( "NM Channel Transform Error: " + alertStr )
			endif
			SetNMstr( cdf + "TransformStr", "Off" )
			return "Error"
		endif
		
	endfor
	
	if ( itemNum < 0 )
		return transformList
	else
		return StringFromList( itemNum, transformList, ";" )
	endif
	
End // NMChanTransformGet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanTransformCheck( transformList )
	String transformList
	
	Variable icnt, xbgn, xend
	String tList, transform
	
	for ( icnt = 0 ; icnt < ItemsInList( transformList, ";" ) ; icnt += 1 )
	
		tList = StringFromList( icnt, transformList, ";" )
		transform = StringFromList( 0, tList, "," )
	
		strswitch( transform )
		
			case "dF/Fo":
			case "Baseline":
			case "Z-score":
			
				xbgn = str2num( StringByKey("xbgn", tList, "=", ",") )
				xend = str2num( StringByKey("xend", tList, "=", ",") )
				
				if ( numtype( xbgn * xend ) == 2 ) // NAN
					return 1 
				endif
				
				return 0
				
			case "Normalize":
			
				String fxn1 = StringByKey("fxn1", tList, "=", ",")
				Variable avgWin1 = str2num( StringByKey("avgWin1", tList, "=", ",") )
				Variable xbgn1 = str2num( StringByKey("xbgn1", tList, "=", ",") )
				Variable xend1 = str2num( StringByKey("xend1", tList, "=", ",") )
				Variable minValue = str2num( StringByKey("minValue", tList, "=", ",") )
				
				String fxn2 = StringByKey("fxn2", tList, "=", ",")
				Variable avgWin2 = str2num( StringByKey("avgWin2", tList, "=", ",") )
				Variable xbgn2 = str2num( StringByKey("xbgn2", tList, "=", ",") )
				Variable xend2 = str2num( StringByKey("xend2", tList, "=", ",") )
				Variable maxValue = str2num( StringByKey("maxValue", tList, "=", ",") )
				
				if ( WhichListItem( fxn1, "Avg;Min;MinAvg;" ) < 0 )
					return 1
				endif
				
				if ( WhichListItem( fxn2, "Avg;Max;MaxAvg;" ) < 0 )
					return 1
				endif
				
				if ( numtype( xbgn1 * xend1 * xbgn2 * xend2 ) == 2 )
					return 1
				endif
				
				if ( numtype( minValue * maxValue ) > 0 )
					return 1
				endif
				
				return 0
				
			case "Rs Correction":
				
				Variable Vhold = str2num( StringByKey("Vhold", tList, "=", ",") )
				Variable Vrev = str2num( StringByKey("Vrev", tList, "=", ",") )
				Variable Rs = str2num( StringByKey("Rs", tList, "=", ",") )
				Variable Cm = str2num( StringByKey("Cm", tList, "=", ",") )
				Variable Vcomp = str2num( StringByKey("Vcomp", tList, "=", ",") )
				Variable Ccomp = str2num( StringByKey("Ccomp", tList, "=", ",") )
				Variable Fc = str2num( StringByKey("Fc", tList, "=", ",") )
				String dataUnits = StringByKey("dataUnits", tList, "=", ",")
				
				if ( NMRsCorrError( Vhold, Vrev, Rs, Cm, Vcomp, Ccomp, Fc, dataUnits ) == 0 )
					return 0 // OK
				endif
			
				return 1
				
			case "Integrate":
			
				Variable method = str2num( StringByKey("method", tList, "=", ",") )
				
				switch( method )
					case 0:
					case 1:
						return 0
				endswitch
				
				return 1
				 
			case "FFT":
			
				String output = StringByKey("output", tList, "=", ",")
				
				if ( WhichListItem( output, NMChanFFTList ) < 0 )
					return 1
				endif
				
				return 0
				
			case "Running Average":
			
				Variable numAvgWaves = str2num( StringByKey("numWaves", tList, "=", ",") )
				Variable wrap = str2num( StringByKey("wrap", tList, "=", ",") )
				
				if ( numtype( numAvgWaves * wrap ) > 0 )
					return 1
				endif
				
				if ( ( wrap != 0 ) && ( wrap != 1 ) )
					return 1
				endif
				
				if ( numAvgWaves <= 1 )
					return 1
				endif
				
				return 0
				
			case "Histogram":
			
				xbgn = str2num( StringByKey("xbgn", tList, "=", ",") )
				xend = str2num( StringByKey("xend", tList, "=", ",") )
				Variable binWidth = str2num( StringByKey("binWidth", tList, "=", ",") )
				Variable dualDisplay = str2num( StringByKey("dualDisplay", tList, "=", ",") )
				
				if ( numtype( xbgn * xend ) == 2 ) // NAN
					return 1
				endif
				
				if ( ( numtype( binWidth ) > 0 ) || ( binWidth <= 0 ) )
					return 1
				endif
				
				if ( ( dualDisplay != 0 ) && ( dualDisplay != 1 ) )
					return 1
				endif
				
				return 0
			
			case "Clip Events":
			
				Variable positiveEvents = str2num( StringByKey("positiveEvents", tList, "=", ",") )
				Variable eventFindLevel = str2num( StringByKey("eventFindLevel", tList, "=", ",") )
				Variable xwinBeforeEvent = str2num( StringByKey("xwinBeforeEvent", tList, "=", ",") )
				Variable xwinAfterEvent = str2num( StringByKey("xwinAfterEvent", tList, "=", ",") )
				
				if ( numtype( positiveEvents * eventFindLevel * xwinBeforeEvent * xwinAfterEvent ) > 0 )
					return 1
				endif
				
				if ( ( positiveEvents != 0 ) && ( positiveEvents != 1 ) )
					return 1
				endif
				
				if ( ( xwinBeforeEvent <= 0 ) || ( xwinAfterEvent <= 0 ) )
					return 1
				endif
				
				return 0
				
		endswitch
	
	endfor
	
	return 0

End // NMChanTransformCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanTransformCall( channel, on )
	Variable channel // ( -1 ) for current channel
	Variable on // ( 0 ) off ( 1 ) on
	
	String vlist = ""
	
	String transformList, tList, transform = "Off"
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	if ( on )
		transformList = NMChanTransformAsk( channel )
		tList = StringFromList( 0, transformList, ";" )
		transform = StringFromList( 0, transformList, "," )
	endif
	
	strswitch( transform )
	
		case "Off":
		case "Differentiate":
		case "Double Differentiate":
		case "Phase Plane":
		case "Invert":
		case "Log":
		case "Ln":
			return NMChannelTransformSet( channel = channel, transform = transform, history = 1 ) // simple transforms
		
		case "Normalize":
		case "dF/Fo":
		case "Baseline":
		case "Rs Correction":
		case "Z-score":
		case "Integrate":
		case "FFT":
		case "Running Average":
		case "Histogram":
		case "Clip Events":
			return transform
		
	endswitch
	
	ChanGraphsUpdate()
	
	return ""

End // NMChanTransformCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanTransformAsk( channel ) // request channel transform function
	Variable channel // ( -1 ) for current channel
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	String transform = ""
	
	Prompt transform, "select function:", popup " ;" + NMChanTransformList
	DoPrompt "Channel Wave Transform", transform
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	strswitch( transform )
		case " ":
			transform = "Off"
			break
		case "Normalize":
			transform = NMChanTransformNormalizeCall( channel )
			break
		case "dF/Fo":
			transform = NMChanTransformDFOFCall( channel )
			break
		case "Baseline":
			transform = NMChanTransformBaselineCall( channel )
			break
		case "Rs Correction":
			transform = NMChanTransformRsCorrCall( channel )
			break
		case "Z-score":
			transform = NMChanTransformZscoreCall( channel )
			break
		case "Integrate":
			transform = NMChanTransformIntegrateCall( channel )
			break
		case "FFT":
			transform = NMChanTransformFFTCall( channel )
			break
		case "Running Average":
			transform = NMChanTransformRunningAvgCall( channel )
			break
		case "Histogram":
			transform = NMChanTransformHistogramCall( channel )
			break
		case "Clip Events":
			transform = NMChanTransformClipEventsCall( channel )
			break
	endswitch
	
	return transform

End // NMChanTransformAsk

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChannelTransformSet( [ prefixFolder, channel, transform, history ] ) // set channel transform function
	String prefixFolder
	Variable channel // ( -1 ) for current channel
	String transform // "Off" or see NMChanTransformList
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	String cdf, vlist = "", thisfxn = GetRTStackInfo( 1 )
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		vlist = NMCmdStrOptional( "prefixFolder", prefixFolder, vlist )
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( ParamIsDefault( channel ) )
		channel = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	else
		vlist = NMCmdNumOptional( "channel", channel, vlist, integer = 1 )
	endif
	
	if ( ParamIsDefault( transform ) )
		transform = "Off"
	else
		vlist = NMCmdStrOptional( "transform", transform, vlist )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	if ( channel == -1 )
		channel = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	endif
	
	strswitch( transform )
	
		case "Off":
		case "Differentiate":
		case "Double Differentiate":
		case "Phase Plane":
		case "Invert":
		case "Log":
		case "Ln":
			break
			
		case "Normalize":
			NMDoAlert( thisfxn + " Error: please use " + NMQuotes( "NMChanTransformNormalize" ) + " for this channel transformation." )
			return ""
			
		case "dF/Fo":
			NMDoAlert( thisfxn + " Error: please use " + NMQuotes( "NMChanTransformDFOF" ) + " for this channel transformation." )
			return ""
			
		case "Baseline":
			NMDoAlert( thisfxn + " Error: please use " + NMQuotes( "NMChanTransformBaseline" ) + " for this channel transformation." )
			return ""
			
		case "Rs Correction":
			NMDoAlert( thisfxn + " Error: please use " + NMQuotes( "NMChanTransformRsCorrection" ) + " for this channel transformation." )
			return ""
			
		case "Z-score":
			NMDoAlert( thisfxn + " Error: please use " + NMQuotes( "NMChanTransformZscore" ) + " for this channel transformation." )
			return ""
			
		case "Integrate":
			NMDoAlert( thisfxn + " Error: please use " + NMQuotes( "NMChanTransformIntegrate" ) + " for this channel transformation." )
			return ""
			
		case "FFT":
			NMDoAlert( thisfxn + " Error: please use " + NMQuotes( "NMChanTransformFFT" ) + " for this channel transformation." )
			return ""
			
		case "Running Average":
			NMDoAlert( thisfxn + " Error: please use " + NMQuotes( "NMChanTransformRunningAvg" ) + " for this channel transformation." )
			return ""
			
		case "Histogram":
			NMDoAlert( thisfxn + " Error: please use " + NMQuotes( "NMChanTransformHistogram" ) + " for this channel transformation." )
			return ""
			
		case "Clip Events":
			NMDoAlert( thisfxn + " Error: please use " + NMQuotes( "NMChanTransformClipEvents" ) + " for this channel transformation." )
			return ""
			
		default:
			return ""
			
	endswitch
	
	cdf = NMChanTransformDF( channel, prefixFolder = prefixFolder )
	
	if ( strlen( cdf ) == 0 )
		return ""
	endif
	
	SetNMstr( cdf + "TransformStr", transform )
	
	ChanGraphsUpdate()
	NMAutoTabCall()
	
	return transform

End // NMChannelTransformSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanTransformRSCorrCall( channel )
	Variable channel // ( -1 ) for current channel
	
	String promptStr
	
	String currentPrefix = CurrentNMWavePrefix()
	
	STRUCT NMRsCorr rc
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	String cdf = NMChanTransformDF( channel ) 
	
	if ( strlen( cdf ) == 0 )
		return ""
	endif
	
	promptStr = currentPrefix + " : " + ChanNum2Char( channel )
	
	if ( NMRsCorrectionCall( cdf, promptStr=promptStr, rc=rc ) == 0 )
		return NMChanTransformRsCorrect( channel=channel, rc=rc, history=1 )
	endif
	
	return ""

End // NMChanTransformRSCorrCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanTransformRsCorrect( [ prefixFolder, channel, Vhold, Vrev, Rs, Cm, Vcomp, Ccomp, FC, dataUnits, rc, history ] )
	String prefixFolder // prefix folder, pass nothing for current
	Variable channel // pass nothing for current channel
	
	Variable Vhold // mV
	Variable Vrev // mV
	Variable Rs // MOhms
	Variable Cm // pF
	Variable Vcomp // fraction 0 - 1
	Variable Ccomp // fraction 0 - 1
	Variable Fc // kHz
	String dataUnits // A, mA, uA, nA, pA
	
	STRUCT NMRsCorr &rc // or pass this structure instead
	
	Variable history
	
	String cdf, transformList, paramList = ""
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		paramList = NMCmdStrOptional( "prefixFolder", prefixFolder, paramList )
	endif
	
	prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	if ( ParamIsDefault( channel ) || ( channel == -1 ) )
		channel = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	endif
	
	cdf = NMChanTransformDF( channel, prefixFolder = prefixFolder )
	
	if ( strlen( cdf ) == 0 )
		return ""
	endif
	
	paramList = NMCmdNumOptional( "channel", channel, paramList )
	
	if ( ParamIsDefault( rc ) )
	
		if ( ParamIsDefault( Vhold ) )
			return ""
		endif
		
		if ( ParamIsDefault( Vrev ) )
			return ""
		endif
		
		if ( ParamIsDefault( Rs ) )
			return ""
		endif
		
		if ( ParamIsDefault( Cm ) )
			return ""
		endif
		
		if ( ParamIsDefault( Vcomp ) )
			return ""
		endif
		
		if ( ParamIsDefault( Ccomp ) )
			return ""
		endif
		
		if ( ParamIsDefault( dataUnits ) )
			return ""
		endif
	
	else
	
		Vhold = rc.Vhold
		Vrev = rc.Vrev
		Rs = rc.Rs
		Cm = rc.Cm
		Vcomp = rc.Vcomp
		Ccomp = rc.Ccomp
		Fc = rc.Fc
		dataUnits = rc.dataUnits
		
	endif
	
	if ( NMRsCorrError( Vhold, Vrev, Rs, Cm, Vcomp, Ccomp, Fc, dataUnits ) != 0 )
		return "" // error
	endif
	
	paramList = NMCmdNumOptional( "Vhold", Vhold, paramList )
	paramList = NMCmdNumOptional( "Vrev", Vrev, paramList )
	paramList = NMCmdNumOptional( "Rs", Rs, paramList )
	paramList = NMCmdNumOptional( "Cm", Cm, paramList )
	paramList = NMCmdNumOptional( "Vcomp", Vcomp, paramList )
	paramList = NMCmdNumOptional( "Ccomp", Ccomp, paramList )
	paramList = NMCmdNumOptional( "Fc", Fc, paramList )
	paramList = NMCmdStrOptional( "dataUnits", dataUnits, paramList )
	
	if ( history )
		NMCommandHistory( paramList )
	endif
	
	String p1List = "Vhold=" + num2str( Vhold ) + ",Vrev=" + num2str( Vrev ) + ",Rs=" + num2str( Rs ) + ",Cm=" + num2str( Cm ) + ","
	String p2List = "Vcomp=" + num2str( Vcomp ) + ",Ccomp=" + num2str( Ccomp ) + ",Fc=" + num2str( Fc ) + ",dataUnits=" + dataUnits + ","
	
	transformList = "Rs Correction," + p1List + p2List + ";"
	SetNMstr( cdf + "TransformStr", transformList )
	
	ChanGraphsUpdate()
	NMAutoTabCall()
	
	return transformList
	
End // NMChanTransformRsCorrect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanTransformNormalizeCall( channel )
	Variable channel // ( -1 ) for current channel
	
	String promptStr
	
	String currentPrefix = CurrentNMWavePrefix()
	
	STRUCT NMNormalizeStruct n
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	String cdf = NMChanTransformDF( channel ) 
	
	if ( strlen( cdf ) == 0 )
		return ""
	endif
	
	promptStr = currentPrefix + " : " + ChanNum2Char( channel )
	
	if ( NMNormalizeCall( cdf, promptStr = promptStr, n = n ) == 0 )
		return NMChanTransformNorm( channel = channel, n = n, history = 1 )
	endif
	
	return ""

End // NMChanTransformNormalizeCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanTransformNorm( [ prefixFolder, channel, fxn1, avgWin1, xbgn1, xend1, minValue, fxn2, avgWin2, xbgn2, xend2, maxValue, n, deprecation, history ] )
	String prefixFolder // prefix folder, pass nothing for current
	Variable channel // pass nothing for current channel
	
	String fxn1 // function to compute min value, "avg" or "min" or "minavg"
	Variable avgWin1 // for minavg
	Variable xbgn1, xend1 // x-axis window begin and end for fxn1, use ( -inf, inf ) for all
	Variable minValue // norm min value, default is 0, but could be -1
	String fxn2 // function to compute max value, "avg" or "max" or "maxavg"
	Variable avgWin2 // for maxavg
	Variable xbgn2, xend2 // x-axis window begin and end for fxn2, use ( -inf, inf ) for all
	Variable maxValue // norm max value, default is 1
	STRUCT NMNormalizeStruct &n // or pass this structure instead
	
	Variable deprecation, history
	
	String cdf, transformList, paramList = ""
	
	STRUCT NMNormalizeStruct n2
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		paramList = NMCmdStrOptional( "prefixFolder", prefixFolder, paramList )
	endif
	
	prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	if ( ParamIsDefault( channel ) || ( channel == -1 ) )
		channel = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	endif
	
	cdf = NMChanTransformDF( channel, prefixFolder = prefixFolder )
	
	if ( strlen( cdf ) == 0 )
		return ""
	endif
	
	paramList = NMCmdNumOptional( "channel", channel, paramList )
	
	if ( ParamIsDefault( n ) )
	
		if ( ParamIsDefault( fxn1 ) )
			fxn1 = "min"
		endif
		
		if ( ParamIsDefault( xbgn1 ) )
			xbgn1 = -inf
		endif
		
		if ( ParamIsDefault( xend1 ) )
			xend1 = inf
		endif
		
		if ( ParamIsDefault( fxn2 ) )
			fxn2 = "max"
		endif
		
		if ( ParamIsDefault( xbgn2 ) )
			xbgn2 = -inf
		endif
		
		if ( ParamIsDefault( xend2 ) )
			xend2 = inf
		endif
		
		if ( ParamIsDefault( maxValue ) )
			maxValue = 1
		endif
		
		n2.fxn1 = fxn1
		n2.avgWin1 = avgWin1
		n2.xbgn1 = xbgn1
		n2.xend1 = xend1
		n2.minValue = minValue
		
		n2.fxn2 = fxn2
		n2.avgWin2 = avgWin2
		n2.xbgn2 = xbgn2
		n2.xend2 = xend2
		n2.minValue = minValue
	
	else
	
		n2 = n
		
	endif
	
	if ( NMNormalizeError( n2 ) != 0 )
		return "" // error
	endif
	
	paramList = NMCmdStrOptional( "fxn1", n2.fxn1, paramList )
	
	if ( StringMatch( n2.fxn1, "MinAvg" ) )
		paramList = NMCmdNumOptional( "avgWin1", n2.avgWin1, paramList )
	endif
	
	paramList = NMCmdNumOptional( "xbgn1", n2.xbgn1, paramList )
	paramList = NMCmdNumOptional( "xend1", n2.xend1, paramList )
	
	if ( n2.minValue != 0 )
		paramList = NMCmdNumOptional( "minValue", n2.minValue, paramList )
	endif
	
	paramList = NMCmdStrOptional( "fxn2", n2.fxn2, paramList )
	
	if ( StringMatch( n2.fxn2, "MaxAvg" ) )
		paramList = NMCmdNumOptional( "avgWin2", n2.avgWin2, paramList )
	endif
	
	paramList = NMCmdNumOptional( "xbgn2", n2.xbgn2, paramList )
	paramList = NMCmdNumOptional( "xend2", n2.xend2, paramList )
	
	if ( n2.maxValue != 1 )
		paramList = NMCmdNumOptional( "maxValue", n2.maxValue, paramList )
	endif
	
	if ( history )
		NMCommandHistory( paramList )
	endif
	
	String p1List = "fxn1=" + n2.fxn1 + ",avgWin1=" + num2str( n2.avgWin1 ) + ",xbgn1=" + num2str( n2.xbgn1 ) + ",xend1=" + num2str( n2.xend1 ) + ",minValue=" + num2str( n2.minValue ) + ","
	String p2List = "fxn2=" + n2.fxn2 + ",avgWin2=" + num2str( n2.avgWin2 ) + ",xbgn2=" + num2str( n2.xbgn2 ) + ",xend2=" + num2str( n2.xend2 ) + ",maxValue=" + num2str( n2.maxValue ) + ","
	
	transformList = "Normalize," + p1List + p2List + ";"
	SetNMstr( cdf + "TransformStr", transformList )
	
	ChanGraphsUpdate()
	NMAutoTabCall()
	
	return transformList
	
End // NMChanTransformNorm

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanTransformDFOFCall( channel )
	Variable channel // ( -1 ) for current channel
	
	Variable xbgn, xend
	String cdf, mdf = NMMainDF
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	cdf = NMChanTransformDF( channel )
	
	if ( strlen( cdf ) == 0 )
		return ""
	endif
	
	xbgn = NumVarOrDefault( mdf+"Bsln_Bgn", NMBaselineXbgn )
	xend = NumVarOrDefault( mdf+"Bsln_End", NMBaselineXend )
	
	xbgn = NumVarOrDefault( cdf + "DFOF_Bbgn", xbgn )
	xend = NumVarOrDefault( cdf + "DFOF_Bend", xend )
	
	Prompt xbgn, NMPromptAddUnitsX( "compute baseline Fo from" )
	Prompt xend, NMPromptAddUnitsX( "compute baseline Fo to" )
	
	DoPrompt "dF/Fo", xbgn, xend
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMvar( cdf + "DFOF_Bbgn", xbgn )
	SetNMvar( cdf + "DFOF_Bend", xend )
	
	return NMChanTransformDFOF( channel, xbgn, xend, history = 1 )

End // NMChanTransformDFOFCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanTransformDFOF( channel, xbgn, xend [ prefixFolder, history ] )
	Variable channel // ( -1 ) for current channel
	Variable xbgn, xend // x-axis begin and end, use ( -inf, inf ) for all
	String prefixFolder
	Variable history
	
	String cdf, transformList, vlist = ""
	
	vList = NMCmdNum( channel, vList, integer = 1 )
	vList = NMCmdNum( xbgn, vList )
	vList = NMCmdNum( xend, vList )
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		vlist = NMCmdStrOptional( "prefixFolder", prefixFolder, vlist )
	endif
	
	prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( channel == -1 )
		channel = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	endif
	
	cdf = NMChanTransformDF( channel, prefixFolder = prefixFolder )
	
	if ( strlen( cdf ) == 0 )
		return ""
	endif
	
	if ( numtype( xbgn ) > 0 )
		xbgn = -inf
	endif
	
	if ( numtype( xend ) > 0 )
		xend = inf
	endif
	
	transformList = "dF/Fo,xbgn=" + num2str( xbgn ) + ",xend=" + num2str( xend ) + "," + ";"
	SetNMstr( cdf + "TransformStr", transformList )
	
	ChanGraphsUpdate()
	NMAutoTabCall()
	
	return transformList
	
End // NMChanTransformDFOF

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanTransformBaselineCall( channel )
	Variable channel // ( -1 ) for current channel
	
	Variable xbgn, xend
	String cdf, mdf = NMMainDF
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	cdf = NMChanTransformDF( channel )
	
	if ( strlen( cdf ) == 0 )
		return ""
	endif
	
	xbgn = NumVarOrDefault( mdf+"Bsln_Bgn", NMBaselineXbgn )
	xend = NumVarOrDefault( mdf+"Bsln_End", NMBaselineXend )
	
	xbgn = NumVarOrDefault( cdf + "Bsln_Bbgn", xbgn )
	xend = NumVarOrDefault( cdf + "Bsln_Bend", xend )
	
	Prompt xbgn, NMPromptAddUnitsX( "compute baseline from" )
	Prompt xend, NMPromptAddUnitsX( "compute baseline to" )
	
	DoPrompt "Baseline Subtract", xbgn, xend
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMvar( cdf + "Bsln_Bbgn", xbgn )
	SetNMvar( cdf + "Bsln_Bend", xend )
	
	return NMChanTransformBaseline( channel, xbgn, xend, history = 1 )

End // NMChanTransformBaselineCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanTransformBaseline( channel, xbgn, xend [ prefixFolder, history ] )
	Variable channel // ( -1 ) for current channel
	Variable xbgn, xend // x-axis begin and end, use ( -inf, inf ) for all
	String prefixFolder
	Variable history
	
	String transformList, vlist = "", cdf
	
	vList = NMCmdNum( channel, vList, integer = 1 )
	vList = NMCmdNum( xbgn, vList )
	vList = NMCmdNum( xend, vList )
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		vlist = NMCmdStrOptional( "prefixFolder", prefixFolder, vlist )
	endif
	
	prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( channel == -1 )
		channel = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	endif
	
	cdf = NMChanTransformDF( channel, prefixFolder = prefixFolder )
	
	if ( strlen( cdf ) == 0 )
		return ""
	endif
	
	if ( numtype( xbgn ) > 0 )
		xbgn = -inf
	endif
	
	if ( numtype( xend ) > 0 )
		xend = inf
	endif
	
	transformList = "Baseline,xbgn=" + num2str( xbgn ) + ",xend=" + num2str( xend ) + "," + ";"
	SetNMstr( cdf + "TransformStr", transformList )
	
	ChanGraphsUpdate()
	NMAutoTabCall()
	
	return transformList
	
End // NMChanTransformBaseline

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanTransformZscoreCall( channel )
	Variable channel // ( -1 ) for current channel
	
	Variable xbgn, xend
	String cdf, mdf = NMMainDF
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	cdf = NMChanTransformDF( channel )
	
	if ( strlen( cdf ) == 0 )
		return ""
	endif
	
	xbgn = NumVarOrDefault( mdf+"Bsln_Bgn", NMBaselineXbgn )
	xend = NumVarOrDefault( mdf+"Bsln_End", NMBaselineXend )
	
	xbgn = NumVarOrDefault( cdf + "ZscoreBgn", xbgn )
	xend = NumVarOrDefault( cdf + "ZscoreEnd", xend )
	
	Prompt xbgn, NMPromptAddUnitsX( "compute mean/stdv from" )
	Prompt xend, NMPromptAddUnitsX( "compute mean/stdv to" )
	
	DoPrompt "Z-score", xbgn, xend
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMvar( cdf + "ZscoreBgn", xbgn )
	SetNMvar( cdf + "ZscoreEnd", xend )
	
	return NMChanTransformZscore( channel, xbgn, xend, history = 1 )

End // NMChanTransformZscoreCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanTransformZscore( channel, xbgn, xend [ prefixFolder, history ] )
	Variable channel // ( -1 ) for current channel
	Variable xbgn, xend // x-axis begin and end, use ( -inf, inf ) for all
	String prefixFolder
	Variable history
	
	String transformList, vlist = "", cdf
	
	vList = NMCmdNum( channel, vList, integer = 1 )
	vList = NMCmdNum( xbgn, vList )
	vList = NMCmdNum( xend, vList )
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		vlist = NMCmdStrOptional( "prefixFolder", prefixFolder, vlist )
	endif
	
	prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( channel == -1 )
		channel = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	endif
	
	cdf = NMChanTransformDF( channel, prefixFolder = prefixFolder )
	
	if ( strlen( cdf ) == 0 )
		return ""
	endif
	
	if ( numtype( xbgn ) > 0 )
		xbgn = -inf
	endif
	
	if ( numtype( xend ) > 0 )
		xend = inf
	endif
	
	transformList = "Z-score,xbgn=" + num2str( xbgn ) + ",xend=" + num2str( xend ) + "," + ";"
	SetNMstr( cdf + "TransformStr", transformList )
	
	ChanGraphsUpdate()
	NMAutoTabCall()
	
	return transformList
	
End // NMChanTransformZscore

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanTransformIntegrateCall( channel )
	Variable channel // ( -1 ) for current channel
	
	Variable method
	String cdf
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	cdf = NMChanTransformDF( channel )
	
	if ( strlen( cdf ) == 0 )
		return ""
	endif
	
	method = NumVarOrDefault( cdf + "IntegrateMethod", 1 )
	
	method += 1
	
	Prompt method, "select integration method:", popup "rectangular;trapezoid;"
	
	DoPrompt "Integrate", method
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	method -= 1
	
	SetNMvar( cdf + "IntegrateMethod", method )
	
	return NMChanTransformIntegrate( channel, method = method, history = 1 )

End // NMChanTransformIntegrateCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanTransformIntegrate( channel [ prefixFolder, method, history ] )
	Variable channel // ( -1 ) for current channel
	String prefixFolder
	Variable method // ( 0 ) rectangular ( 1 ) trapezoid
	Variable history
	
	String transformList, cdf, vlist = ""
	
	vList = NMCmdNum( channel, vList, integer = 1 )
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		vlist = NMCmdStrOptional( "prefixFolder", prefixFolder, vlist )
	endif
	
	prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	if ( !ParamIsDefault( method ) )
		vlist = NMCmdNumOptional( "method", method, vlist )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( channel == -1 )
		channel = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	endif
	
	cdf = NMChanTransformDF( channel, prefixFolder = prefixFolder )
	
	if ( strlen( cdf ) == 0 )
		return ""
	endif
	
	switch( method )
	
		case 0: // rectangular
		case 1: // trapezoid
			break
	
		default:
			return ""

	endswitch
	
	transformList = "Integrate,method=" + num2istr( method ) + "," + ";"
	SetNMstr( cdf + "TransformStr", transformList )
	
	ChanGraphsUpdate()
	NMAutoTabCall()
	
	return transformList
	
End // NMChanTransformIntegrate

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanTransformFFTCall( channel )
	Variable channel // ( -1 ) for current channel
	
	String output, cdf
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	cdf = NMChanTransformDF( channel )
	
	if ( strlen( cdf ) == 0 )
		return ""
	endif
	
	output = StrVarOrDefault( cdf + "FFToutput", "magnitude" )
	
	Prompt output, "select what to display of complex FFT:", popup NMChanFFTList
	
	DoPrompt "FFT", output
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMstr( cdf + "FFToutput", output )
	
	return NMChanTransformFFT( channel, output, history = 1 )

End // NMChanTransformFFTCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanTransformFFT( channel, output [ prefixFolder, history ] )
	Variable channel // ( -1 ) for current channel
	String output // what to display of complex FFT, "real" or "magnitude" or "magnitude square" or "phase"
	String prefixFolder
	Variable history
	
	String transformList, cdf, vlist = ""
	
	vList = NMCmdNum( channel, vList, integer = 1 )
	vList = NMCmdStr( output, vList )
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		vlist = NMCmdStrOptional( "prefixFolder", prefixFolder, vlist )
	endif
	
	prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( channel == -1 )
		channel = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	endif
	
	cdf = NMChanTransformDF( channel, prefixFolder = prefixFolder )
	
	if ( strlen( cdf ) == 0 )
		return ""
	endif
	
	strswitch( output )
	
		case "real":
		case "magnitude":
		case "magnitude square":
		case "phase":
			break
	
		default:
			return ""

	endswitch
	
	transformList = "FFT,output=" + output + "," + ";"
	SetNMstr( cdf + "TransformStr", transformList )
	
	ChanGraphsUpdate()
	NMAutoTabCall()
	
	return transformList
	
End // NMChanTransformFFT

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanTransformRunningAvgCall( channel )
	Variable channel // ( -1 ) for current channel
	
	String cdf, mdf = NMMainDF
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	cdf = NMChanTransformDF( channel )
	
	if ( strlen( cdf ) == 0 )
		return ""
	endif
	
	Variable numWaves = NumVarOrDefault( cdf + "RunAvg_NumWaves", 3 )
	Variable wrapAround = 1 + NumVarOrDefault( cdf + "RunAvg_Wrap", 1 )
	
	Prompt numWaves, "number of sequential waves to average:"
	Prompt wrapAround, "treat first and last waves in series to maintain correct number of waves?", popup "no;yes;"
	
	DoPrompt "Running Average", numWaves, wrapAround
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( ( numtype( numWaves ) > 0 ) || ( numWaves < 2 ) )
		numWaves = 1
	endif
	
	wrapAround -= 1
	
	SetNMvar( cdf + "RunAvg_NumWaves", numWaves )
	SetNMvar( cdf + "RunAvg_Wrap", wrapAround )
	
	return NMChanTransformRunningAvg( channel, numWaves, wrapAround, history = 1 )

End // NMChanTransformRunningAvgCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanTransformRunningAvg( channel, numWaves, wrapAround [ prefixFolder, history ] )
	Variable channel // ( -1 ) for current channel
	Variable numWaves // number of sequential waves to average
	Variable wrapAround // treat first and last waves in series, to maintain correct number of waves ( 0 ) no ( 1 ) yes
	String prefixFolder
	Variable history
	
	String transformList, cdf, vlist = ""
	
	vList = NMCmdNum( channel, vList, integer = 1 )
	vList = NMCmdNum( numWaves, vList )
	vList = NMCmdNum( wrapAround, vList )
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		vlist = NMCmdStrOptional( "prefixFolder", prefixFolder, vlist )
	endif
	
	prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( channel == -1 )
		channel = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	endif
	
	cdf = NMChanTransformDF( channel, prefixFolder = prefixFolder )
	
	if ( strlen( cdf ) == 0 )
		return ""
	endif
	
	if ( ( numtype( numWaves ) > 0 ) || ( numWaves < 2 ) )
		return ""
	endif
	
	transformList = "Running Average,numWaves=" + num2str( numWaves ) + ",wrap=" + num2str( wrapAround ) + "," + ";"
	
	SetNMstr( cdf + "TransformStr", transformList )
	
	ChanGraphsUpdate()
	NMAutoTabCall()
	
	return transformList
	
End // NMChanTransformRunningAvg

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S z_RunningAvgWaveList( channel, waveNum, numAvgWaves, wrapAround [ prefixFolder ] )
	Variable channel // ( -1 ) for current channel
	Variable waveNum
	Variable numAvgWaves
	Variable wrapAround
	String prefixFolder
	
	Variable wcnt, wcnt2, wbgn, wend, numWaves
	String cdf, wName, avgList = ""
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	if ( channel == -1 )
		channel = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	endif
	
	numWaves = NumVarOrDefault( prefixFolder + "NumWaves", 0 )
	
	cdf = NMChanTransformDF( channel, prefixFolder = prefixFolder )
	
	if ( strlen( cdf ) == 0 )
		return ""
	endif
	
	if ( numAvgWaves < 0 )
		numAvgWaves = NumVarOrDefault( cdf + "RunAvg_NumWaves", 1 )
	endif
	
	if ( wrapAround < 0 )
		wrapAround = NumVarOrDefault( cdf + "RunAvg_Wrap", 1 )
	endif
	
	if ( numAvgWaves < 2 )
		return ""
	endif
	
	if ( waveNum < 0 )
		waveNum = NumVarOrDefault( prefixFolder + "CurrentWave", 0 )
	endif
	
	if ( waveNum >= numWaves )
		return ""
	endif
	
	wbgn = waveNum - floor( ( numAvgWaves - 1 ) / 2 )
	wend = wbgn + numAvgWaves - 1
	
	for ( wcnt = wbgn ; wcnt <= wend ; wcnt += 1 )
	
		if ( wcnt < 0 )
		
			if ( wrapAround )
				wcnt2 = numWaves + wcnt
			else
				continue
			endif
			
		elseif ( wcnt >= numWaves )
		
			if ( wrapAround )
				wcnt2 = wcnt - numWaves
			else
				continue
			endif
			
		else
		
			wcnt2 = wcnt
		
		endif
		
		wName = NMChanWaveName( channel, wcnt2 )
		
		if ( WaveExists( $wName ) )
			avgList = NMAddToList( wName, avgList, ";" )
		endif
		
	endfor
	
	return avgList
	
End // z_RunningAvgWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanTransformHistogramCall( channel )
	Variable channel // ( -1 ) for current channel
	
	Variable xbgn, xend, binWidth, dualDisplay
	String wName, dName, cdf, mdf = NMMainDF
	
	STRUCT NMParams nm
	STRUCT NMHistrogramBins h
	
	h.numBins = NaN
	h.binStart = NaN
	h.binWidth = NaN
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	cdf = NMChanTransformDF( channel )
	
	if ( strlen( cdf ) == 0 )
		return ""
	endif
	
	xbgn = NumVarOrDefault( cdf + "Histo_Xbgn", -inf )
	xend = NumVarOrDefault( cdf + "Histo_Xend", inf )
	binWidth = NumVarOrDefault( cdf + "Histo_BinWidth", NaN )
	dualDisplay = 1 + NumVarOrDefault( cdf + "Histo_DualDisplay", 0 )
	
	if ( numtype( binWidth ) > 0 )
		dName = GetWaveName( "Display", channel , 0 )
		NMParamsInit( NMDF, dName, nm )
		NMHistrogramBinsAuto( nm, h, numBinsMin = 10 )
		binWidth = h.binWidth
	endif
	
	Prompt xbgn, NMPromptAddUnitsX( "compute histogram from" )
	Prompt xend, NMPromptAddUnitsX( "compute histogram to" )
	Prompt binWidth, "bin width:"
	Prompt dualDisplay, "display histogram:", popup "by itself;beside the raw data;"
	
	DoPrompt "Histogram", xbgn, xend, binWidth, dualDisplay
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	dualDisplay -= 1
	
	SetNMvar( cdf + "Histo_Xbgn", xbgn )
	SetNMvar( cdf + "Histo_Xend", xend )
	SetNMvar( cdf + "Histo_BinWidth", binWidth )
	SetNMvar( cdf + "Histo_DualDisplay", dualDisplay )
	
	return NMChanTransformHistogram( channel, xbgn, xend, binWidth, dualDisplay, history = 1 )

End // NMChanTransformHistogramCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanTransformHistogram( channel, xbgn, xend, binWidth, dualDisplay [ prefixFolder, history ] )
	Variable channel // ( -1 ) for current channel
	Variable xbgn, xend // x-axis begin and end, use ( -inf, inf ) for all
	Variable binWidth // ms
	Variable dualDisplay // ( 0 ) by itself ( 1 ) beside the raw data
	String prefixFolder
	Variable history
	
	String transformList, cdf, vlist = ""
	
	vList = NMCmdNum( channel, vList, integer = 1 )
	vList = NMCmdNum( xbgn, vList )
	vList = NMCmdNum( xend, vList )
	vList = NMCmdNum( binWidth, vList )
	vList = NMCmdNum( dualDisplay, vList, integer = 1 )
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		vlist = NMCmdStrOptional( "prefixFolder", prefixFolder, vlist )
	endif
	
	prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( channel == -1 )
		channel = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	endif
	
	cdf = NMChanTransformDF( channel, prefixFolder = prefixFolder )
	
	if ( strlen( cdf ) == 0 )
		return ""
	endif
	
	if ( numtype( xbgn ) > 0 )
		xbgn = -inf
	endif
	
	if ( numtype( xend ) > 0 )
		xend = inf
	endif
	
	transformList = "Histogram,xbgn=" + num2str( xbgn ) + ",xend=" + num2str( xend ) + ",binWidth=" + num2str( binWidth ) + ",dualDisplay=" + num2str( dualDisplay ) + "," + ";"
	SetNMstr( cdf + "TransformStr", transformList )
	
	ChanGraphsUpdate()
	NMAutoTabCall()
	
	return transformList
	
End // NMChanTransformHistogram

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanTransformClipEventsCall( channel )
	Variable channel // ( -1 ) for current channel
	
	Variable positiveEvents, eventFindLevel, xwinBeforeEvent, xwinAfterEvent
	String cdf
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	cdf = NMChanTransformDF( channel )
	
	if ( strlen( cdf ) == 0 )
		return ""
	endif
	
	positiveEvents = 1 + NumVarOrDefault( cdf + "ClipEvents_Positive", 1 )
	eventFindLevel = NumVarOrDefault( cdf + "ClipEvents_Level", 10 )
	xwinBeforeEvent = NumVarOrDefault( cdf + "ClipEvents_XwinBefore", 1 )
	xwinAfterEvent = NumVarOrDefault( cdf + "ClipEvents_XwinAfter", 1 )
	
	Prompt positiveEvents, " ", popup "clip negative events;clip positive events;"
	Prompt eventFindLevel, NMPromptAddUnitsY( "event detection level" )
	Prompt xwinBeforeEvent, NMPromptAddUnitsX( "x-axis window to clip before event" )
	Prompt xwinAfterEvent, NMPromptAddUnitsX( "x-axis window to clip after event" )
	
	DoPrompt "Clip Events", positiveEvents, eventFindLevel, xwinBeforeEvent, xwinAfterEvent
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	positiveEvents -= 1
	
	SetNMvar( cdf + "ClipEvents_Positive", positiveEvents )
	SetNMvar( cdf + "ClipEvents_Level", eventFindLevel )
	SetNMvar( cdf + "ClipEvents_XwinBefore", xwinBeforeEvent )
	SetNMvar( cdf + "ClipEvents_XwinAfter", xwinAfterEvent )
	
	return NMChanTransformClipEvents( channel, positiveEvents, eventFindLevel, xwinBeforeEvent, xwinAfterEvent, history = 1 )

End // NMChanTransformClipEventsCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanTransformClipEvents( channel, positiveEvents, eventFindLevel, xwinBeforeEvent, xwinAfterEvent [ prefixFolder, history ] )
	Variable channel // ( -1 ) for current channel
	Variable positiveEvents // ( 0 ) negative events ( 1 ) positive events
	Variable eventFindLevel // see parameter "level" for Igor function FindLevels 
	Variable xwinBeforeEvent // x-axis window to clip before detected event
	Variable xwinAfterEvent // x-axis window to clip after detected event
	String prefixFolder
	Variable history
	
	String transformList, cdf, vlist = ""
	
	vList = NMCmdNum( channel, vList, integer = 1 )
	vList = NMCmdNum( positiveEvents, vList, integer = 1 )
	vList = NMCmdNum( eventFindLevel, vList )
	vList = NMCmdNum( xwinBeforeEvent, vList )
	vList = NMCmdNum( xwinAfterEvent, vList )
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		vlist = NMCmdStrOptional( "prefixFolder", prefixFolder, vlist )
	endif
	
	prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( channel == -1 )
		channel = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	endif
	
	cdf = NMChanTransformDF( channel, prefixFolder = prefixFolder )
	
	if ( strlen( cdf ) == 0 )
		return ""
	endif
	
	if ( positiveEvents != 0 )
		positiveEvents = 1
	endif
	
	if ( numtype( eventFindLevel * xwinBeforeEvent * xwinAfterEvent ) > 0 )
		return ""
	endif
	
	transformList = "Clip Events,positiveEvents=" + num2str( positiveEvents ) + ",eventFindLevel=" + num2str( eventFindLevel ) + ",xwinBeforeEvent=" + num2str( xwinBeforeEvent ) + ",xwinAfterEvent=" + num2str( xwinAfterEvent ) + "," + ";"
	SetNMstr( cdf + "TransformStr", transformList )
	
	ChanGraphsUpdate()
	NMAutoTabCall()
	
	return transformList
	
End // NMChanTransformClipEvents

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Channel Filter Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanFilterProc( channel )
	Variable channel // ( -1 ) for current channel
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	return StrVarOrDefault( NMDF + "ChanFilterProc" + num2istr( channel ), "NMChanSetVariable" )

End // ChanFilterProc

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanFilterDF( channel [ prefixFolder ] )
	Variable channel // ( -1 ) for current channel
	String prefixFolder
	
	String cdf
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	if ( channel == -1 )
		channel = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	endif
	
	cdf = ChanDF( channel, prefixFolder = prefixFolder )
	
	return StrVarOrDefault( NMDF + "ChanFilterDF" + num2istr( channel ), cdf )

End // ChanFilterDF

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanFilterNumGet( channel [ prefixFolder ] )
	Variable channel // ( -1 ) for current channel
	String prefixFolder
	
	String cdf
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif
	
	if ( channel == -1 )
		channel = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	endif
	
	cdf = ChanFilterDF( channel )
	
	if ( strlen( cdf ) == 0 )
		return 0
	endif
	
	return NumVarOrDefault( cdf + "SmoothN", 0 ) // filter number saved as old smooth number
	
End // ChanFilterNumGet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanFilterAlgGet( channel [ prefixFolder ] ) // get channel smooth/filter alrgorithm
	Variable channel // ( -1 ) for current channel
	String prefixFolder
	
	String alg, cdf
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	if ( channel == -1 )
		channel = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	endif
	
	cdf = ChanFilterDF( channel, prefixFolder = prefixFolder )
	
	if ( strlen( cdf ) == 0 )
		return ""
	endif

	alg = StrVarOrDefault( cdf + "SmoothA", "" )
	
	strswitch( alg )
	
		case "binomial": // smooth
		case "boxcar": // smooth
			break
			
		case "low-pass": // Filter IIR
		case "high-pass": // Filter IIR
			break
			
		default:
			alg = ""
			
	endswitch
	
	return alg

End // ChanFilterAlgGet

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanFilterNumCall( channel, filterNum )
	Variable channel // ( -1 ) for current channel
	Variable filterNum
	
	Variable rvalue, off
	String filterAlg, alg = "", vlist = ""
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	filterAlg = ChanFilterAlgGet( channel )
	
	if ( ( strlen( filterAlg ) == 0 ) && ( filterNum > 0 ) )
		filterAlg = ChanFilterAlgAsk( channel )
	elseif ( filterNum == 0 )
		filterAlg = ""
	endif
		
	strswitch( filterAlg )
	
		case "binomial":
		case "boxcar":
			return NMChannelFilterSet( channel = channel, smoothAlg = filterAlg, smoothNum = filterNum, prefixFolder = "", history = 1 )
		
		case "low-pass":
			return NMChannelFilterSet( channel = channel, lowPass = filterNum, prefixFolder = "", history = 1 )
		
		case "high-pass":
			return NMChannelFilterSet( channel = channel, highPass = filterNum, prefixFolder = "", history = 1 )
			
	endswitch
			
	return NMChannelFilterSet( channel = channel, off = 1, prefixFolder = "", history = 1 )

End // ChanFilterNumCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ChanFilterAlgAsk( channel ) // request channel smooth or filter alrgorithm
	Variable channel // ( -1 ) for current channel
	
	String cdf, alg, gName
	
	String s1 = "smooth binomial"
	String s2 = "smooth boxcar"
	String f1 = "low-pass Butterworth filter (kHz)"
	String f2 = "high-pass Butterworth filter (kHz)"
	String slist = s1 + ";" + s2 + ";"
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	cdf = ChanFilterDF( channel )
	
	alg = ChanFilterAlgGet( channel )
	gName = ChanGraphName( channel )
	
	if ( ( strlen( cdf ) == 0 ) || ( WinType( gName ) != 1 ) )
		return ""
	endif
	
	strswitch( alg )
		case "binomial":
			alg = s1
			break
		case "boxcar":
			alg = s2
			break
		case "low-pass":
			alg = f1
			break
		case "high-pass":
			alg = f2
			break
		default:
			alg = s1
	endswitch
	
	slist = s1 + ";" + s2 + ";" + f1 + ";" + f2 + ";"
	
	Prompt alg, " ", popup slist
	
	DoPrompt "Select Algorithm", alg
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( StringMatch( alg, s1 ) )
		alg = "binomial"
	elseif ( StringMatch( alg, s2 ) )
		alg = "boxcar"
	elseif ( StringMatch( alg, f1 ) )
		alg = "low-pass"
	elseif ( StringMatch( alg, f2 ) )
		alg = "high-pass"
	else
		alg = ""
	endif
	
	return alg

End // ChanFilterAlgAsk

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChannelFilterSet( [ channel, smoothAlg, smoothNum, lowPass, highPass, off, prefixFolder, update, history ] )
	Variable channel // ( -1 ) for current channel ( -2 ) for all channels
	String smoothAlg // "binomial" or "boxcar"
	Variable smoothNum // smoothing number (see Igor Smooth function)
	Variable lowPass // low-pass frequency
	Variable highPass // high-pass frequency
	Variable off // no filter
	String prefixFolder
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable ccnt, cbgn, cend, filterNum = NaN
	Variable numChannels, currentChannel
	String filterAlg = "NOTHING", vlist = "", vlist2 = "", cdf
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( ParamIsDefault( prefixFolder ) )
	
		prefixFolder = CurrentNMPrefixFolder()
		
	else
	
		if ( strlen( prefixFolder ) > 0 )
			vlist2 = NMCmdStrOptional( "prefixFolder", prefixFolder, vlist2 )
		elseif ( NMPrefixFolderHistory && ( strlen( prefixFolder ) == 0 ) )
			prefixFolder = CurrentNMPrefixFolder()
			vlist2 = NMCmdStrOptional( "prefixFolder", prefixFolder, vlist2 )
		endif
		
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
		
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	currentChannel = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	
	if ( ParamIsDefault( channel ) )
		channel = currentChannel
	else
		vlist = NMCmdNumOptional( "channel", channel, vlist, integer = 1 )
	endif
	
	if ( channel == -1 )
		cbgn = currentChannel
		cend = cbgn
	elseif ( channel == -2 )
		cbgn = 0
		cend = numChannels - 1
	elseif ( ( channel >= 0 ) && ( channel < numChannels ) )
		cbgn = channel
		cend = channel
	else
		//return NM2Error( 10, "channel", num2str( channel ) )
		return 0
	endif
	
	if ( !ParamIsDefault( off ) && ( off == 1 ) )
	
		vlist = NMCmdNumOptional( "off", off, vlist, integer = 1 )
	
		filterNum = 0
		
	elseif ( !ParamIsDefault( lowPass ) )

		vlist = NMCmdNumOptional( "lowPass", lowPass, vlist )
	
		filterAlg = "low-pass"
		
		if ( numtype( lowPass ) == 0 )
			filterNum = lowPass
		else
			filterNum = 0
		endif
		
	elseif ( !ParamIsDefault( highPass ) )
	
		vlist = NMCmdNumOptional( "highPass", highPass, vlist )
	
		filterAlg = "high-pass"
		
		if ( numtype( highPass ) == 0 )
			filterNum = highPass
		else
			filterNum = 0
		endif
		
	elseif ( !ParamIsDefault( smoothAlg ) )
	
		vlist = NMCmdStrOptional( "smoothAlg", smoothAlg, vlist )
	
		if ( StringMatch( smoothAlg, "binomial" ) || StringMatch( smoothAlg, "boxcar" ) )
			filterAlg = smoothAlg
		else
			filterNum = 0
		endif
		
		if ( !ParamIsDefault( smoothNum ) && ( smoothNum >= 0 ) )
		
			vlist = NMCmdNumOptional( "smoothNum", smoothNum, vlist, integer = 1 )
		
			filterNum = smoothNum
			
		endif
	
	elseif ( !ParamIsDefault( smoothNum ) )
	
		vlist = NMCmdNumOptional( "smoothNum", smoothNum, vlist, integer = 1 )
	
		if ( ( numtype( smoothNum ) == 0 ) && ( smoothNum >= 0 ) )
			filterNum = smoothNum
		endif
	
	else
		
		return 0 // nothing to do
		
	endif
	
	if ( filterNum == 0 )
		filterAlg = ""
	endif
	
	for ( ccnt = cbgn ; ccnt <= cend ; ccnt += 1 )
	
		cdf = ChanFilterDF( channel, prefixFolder = prefixFolder )
	
		if ( strlen( cdf ) == 0 )
			continue
		endif
		
		if ( !StringMatch( filterAlg, "NOTHING" ) )
			SetNMstr( cdf + "SmoothA", filterAlg )
		endif
		
		if ( numtype( filterNum ) == 0 )
			SetNMvar( cdf + "SmoothN", filterNum )
		endif
		
	endfor
	
	if ( history )
		NMCommandHistory( vlist + vlist2 )
	endif
	
	if ( update )
		ChanGraphsUpdate()
		NMAutoTabCall()
	endif
	
	return 0

End // NMChannelFilterSet

//****************************************************************
//****************************************************************
//****************************************************************
//
//	channel display wave functions
//
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ChanWaveMake( channel, srcName, dstName [ prefixFolder, filterAlg, filterNum, transformList, xWave ] )
	Variable channel // ( -1 ) for current channel
	String srcName // source wave name
	String dstName // destination wave name
	String prefixFolder
	String filterAlg
	Variable filterNum
	String transformList
	String xWave
	
	Variable icnt, wcnt, xbgn1, xend1, xbgn2, xend2
	Variable outputNum, minValue, maxValue, negone = -1
	Variable sfreq, fratio, numWaves, numAvgWaves, wrap, bbgn, bend, dx, offset, npnts, method
	
	String fxn1, fxn2, wName, wName2, dNameX, tList, transform, output, mdf = NMMainDF
	
	String avgList = "" // running avg wave list
	String avgList2 = "" // for filtering
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( channel == -1 )
		channel = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	endif
	
	if ( ParamIsDefault( filterAlg ) )
		filterAlg = ChanFilterAlgGet( channel, prefixFolder = prefixFolder  )
	endif
	
	if ( ParamIsDefault( filterNum ) )
		filterNum = ChanFilterNumGet( channel, prefixFolder = prefixFolder  )
	endif
	
	if ( ParamIsDefault( transformList ) )
		transformList = NMChanTransformGet( channel, prefixFolder = prefixFolder, errorAlert = 1  ) 
	endif
	
	if ( ParamIsDefault( xWave ) )
		//xWave = NMXwave( prefixFolder = prefixFolder, fullPath = 1 ) 
		NM2Error( 21, "xWave", "" ) // NEED TO SPECIFY
		return -1
	endif
	
	if ( StringMatch( srcName, dstName ) )
		return -1 // not to over-write source wave
	endif
	
	if ( WaveExists( $dstName ) )
		
		if ( WaveType( $dstName ) & 0x01 )
			return -1 // wave is complex
		endif
		
		if ( WaveType( $dstName ) == 0 )
			return -1 // text wave
		endif
	
		Wave wtemp = $dstName
		wtemp = Nan
		
	endif
		
	if ( !WaveExists( $srcName ) )
		return -1 // source wave does not exist
	endif
	
	if ( WaveType( $srcName ) & 0x01 )
		return -1 // wave is complex
	endif

	if ( WaveType( $srcName ) == 0 )
		return -1 // text wave
	endif
	
	sfreq = 1 / deltax( $srcName ) // kHz
	
	Duplicate /O $srcName, $dstName
	
	RemoveWaveUnits( dstName )
	
	for ( icnt = 0 ; icnt < ItemsInList( transformList ) ; icnt += 1 )
	
		tList = StringFromList( icnt, transformList, ";" )
		transform = StringFromList( 0, tList, "," )
		
		if ( StringMatch( transform, "Error" ) )
			return -1
		endif
	
		if ( StringMatch( transform, "Running Average" ) )
			
			if ( !StringMatch( srcName, NMChanWaveName( channel, -1 ) ) )
				return -1
			endif
			
			numAvgWaves = str2num( StringByKey("numWaves", tList, "=", ",") )
			wrap = str2num( StringByKey("wrap", tList, "=", ",") )
			
			avgList = z_RunningAvgWaveList( channel, -1, numAvgWaves, wrap, prefixFolder = prefixFolder  )
			
			if ( ItemsInList( avgList ) < 2 )
				avgList = ""
			endif
			
			if ( filterNum > 0 )
			
				for ( wcnt = 0 ; wcnt < ItemsInList( avgList ) ; wcnt += 1 )
				
					wName = StringFromList( wcnt, avgList )
					
					if ( !WaveExists( $wName ) )
						continue
					endif
					
					wName2 = "CWM_" + wName
					
					Duplicate /O $wName $wName2
					
					avgList2 = AddListItem( wName2, avgList2, ";", inf )
					
				endfor
			
			endif
			
		endif
	
	endfor
	
	if ( filterNum > 0 )
	
		strswitch( filterAlg )
		
			case "binomial":
			case "boxcar":
				
				if ( ItemsInList( avgList2 ) >= 2 )
					NMSmooth( filterNum, avgList2, algorithm = filterAlg )
				else
					NMSmooth( filterNum, dstName, algorithm = filterAlg )
				endif
				
				break
				
			case "low-pass":
			
				if ( WaveExists( $xWave ) )
					return NM2Error( 90, "low-pass filtering is not allowed with XY-paired data", "" )
				endif
			
				fratio = filterNum / sfreq // kHz
			
				if ( ( numtype( fratio ) > 0 ) || ( fratio > 0.5 ) )
					NMHistory( "Channel " + ChanNum2Char( channel ) + " warning: filter frequency cannot exceed " + num2str( sfreq * 0.5 ) + " kHz" )
				elseif ( ItemsInList( avgList2 ) >= 2 )
					NMFilterIIR( avgList2, fLow = fratio )
				else
					NMFilterIIR( dstName, fLow = fratio )
				endif
				
				break
				
			case "high-pass":
			
				if ( WaveExists( $xWave ) )
					return NM2Error( 90, "high-pass filtering is not allowed with XY-paired data", "" )
				endif
			
				fratio = filterNum / sfreq // kHz
			
				if ( ( numtype( fratio ) > 0 ) || ( fratio > 0.5 ) )
					NMHistory( "Channel " + ChanNum2Char( channel ) + " warning: filter frequency cannot exceed " + num2str( sfreq * 0.5 ) + " kHz" )
				elseif ( ItemsInList( avgList2 ) >= 2 )
					NMFilterIIR( avgList2, fHigh = fratio )
				else
					NMFilterIIR( dstName, fHigh = fratio )
				endif
			
				break
				
		endswitch
	
	endif
	
	for ( icnt = 0 ; icnt < ItemsInList( transformList ) ; icnt += 1 )
	
		tList = StringFromList( icnt, transformList, ";" )
		transform = StringFromList( 0, tList, "," )
	
		strswitch( transform )
		
			default:
				break
				
			case "Error":
				return -1
				
			case "Differentiate":
			
				if ( WaveExists( $xWave ) )
					Differentiate $dstName /X=$xWave
				else
					Differentiate $dstName
				endif
					
				break
				
			case "Double Differentiate":
				if ( WaveExists( $xWave ) )
					Differentiate $dstName /X=$xWave
					Differentiate $dstName /X=$xWave
				else
					Differentiate $dstName
					Differentiate $dstName
				endif
				break
				
			case "Phase Plane":
			
				dNameX = NMChanDisplayWaveNameX( dstName )
				
				Duplicate /O $dstName $dNameX // y-wave becomes x-wave
				
				if ( WaveExists( $xWave ) )
					Differentiate $dstName /X=$xWave
				else
					Differentiate $dstName
				endif
				
				break
				
			case "Integrate":
				
				method = str2num( StringByKey("method", tList, "=", ",") )
				
				if ( WaveExists( $xWave ) )
					Integrate /Meth=( method ) $dstName /X=$xWave
				else
					Integrate /Meth=( method ) $dstName
				endif
				
				break
				
			case "FFT":
			
				npnts = numpnts( $dstName )
				
				if ( mod( npnts, 2 ) > 0 )
					Redimension /N=( npnts + 1 ) $dstName // force even number of points
				endif
				
				wName2 = NMDF + "U_FFT_TEMP"
				
				output = StringByKey("output", tList, "=", ",")
				
				strswitch( output )
				
					case "real":
						outputNum = 2
						break
						
					default: // case "magnitude":
						output = "magnitude"
						outputNum = 3
						break
						
					case "magnitude square":
						outputNum = 4
						break
					
					case "phase":
						outputNum = 5
						break
					
				endswitch
				
				FFT /Dest=$wName2 /Out=( outputNum ) $dstName
				
				Duplicate /O $wName2 $dstName
				KillWaves /Z $wName2
				
				break
				
			case "Normalize":
			
				STRUCT NMNormalizeStruct n
				
				n.fxn1 = StringByKey("fxn1", tList, "=", ",")
				n.avgWin1 = str2num( StringByKey("avgWin1", tList, "=", ",") )
				n.xbgn1 = str2num( StringByKey("xbgn1", tList, "=", ",") )
				n.xend1 = str2num( StringByKey("xend1", tList, "=", ",") )
				n.minValue = str2num( StringByKey("minValue", tList, "=", ",") )
				
				n.fxn2 = StringByKey("fxn2", tList, "=", ",")
				n.avgWin2 = str2num( StringByKey("avgWin2", tList, "=", ",") )
				n.xbgn2 = str2num( StringByKey("xbgn2", tList, "=", ",") )
				n.xend2 = str2num( StringByKey("xend2", tList, "=", ",") )
				n.maxValue = str2num( StringByKey("maxValue", tList, "=", ",") )
				
				NMNormalize( dstName, n = n )
				
				break
				
			case "Baseline":
			
				bbgn = str2num( StringByKey("xbgn", tList, "=", ",") )
				bend = str2num( StringByKey("xend", tList, "=", ",") )
				
				NMBaseline( dstName, xbgn = bbgn, xend = bend, xWave = xWave )
				
				break
				
			case "dF/Fo":
			
				bbgn = str2num( StringByKey("xbgn", tList, "=", ",") )
				bend = str2num( StringByKey("xend", tList, "=", ",") )
				
				NMBaseline( dstName, xbgn = bbgn, xend = bend, xWave = xWave, DFOF = 1 )
				
				break
				
			case "Rs Correction":
			
				STRUCT NMRsCorr rc
				
				rc.Vhold = str2num( StringByKey("Vhold", tList, "=", ",") )
				rc.Vrev = str2num( StringByKey("Vrev", tList, "=", ",") )
				rc.Rs = str2num( StringByKey("Rs", tList, "=", ",") )
				rc.Cm = str2num( StringByKey("Cm", tList, "=", ",") )
				rc.Vcomp = str2num( StringByKey("Vcomp", tList, "=", ",") )
				rc.Ccomp = str2num( StringByKey("Ccomp", tList, "=", ",") )
				rc.Fc = str2num( StringByKey("Fc", tList, "=", ",") )
				rc.dataUnits = StringByKey("dataUnits", tList, "=", ",")
				
				STRUCT NMParams nm
				
				NMParamsNull( nm )
				nm.folder = NMParent( dstName )
				nm.wList = NMChild( dstName )
				
				NMRsCorrection2( nm, rc )
				
				break
				
			case "Z-score":
			
				bbgn = str2num( StringByKey("xbgn", tList, "=", ",") )
				bend = str2num( StringByKey("xend", tList, "=", ",") )
				
				NMBaseline( dstName, xbgn = bbgn, xend = bend, xWave = xWave, Zscore = 1 )
				
				break
				
			case "Invert":
			
				Wave wtemp = $dstName
				
				MatrixOp /O wtemp = wtemp * negone
				
				break
				
			case "Log":
			
				Wave wtemp = $dstName
				
				wtemp = log( wtemp )
				
				break
				
			case "Ln":
			
				Wave wtemp = $dstName
				
				wtemp = ln( wtemp )
				
				break
				
			case "Running Average":
				
				if ( ItemsInList( avgList2 ) > 0 )
					NMMatrixStats( avgList2, truncateToCommonXScale = 0 )
				elseif ( ItemsInList( avgList ) > 0 )
					NMMatrixStats( avgList, truncateToCommonXScale = 0 )
				else
					break
				endif
				
				if ( WaveExists( $"U_Avg" ) )
					Duplicate /O $"U_Avg" $dstName
				endif
				
				Killwaves /Z U_Avg, U_Sdv, U_Sum, U_SumSqr, U_Pnts, U_2Dmatrix // kill output waves from WavesStatistics
				
				for ( wcnt = 0 ; wcnt < ItemsInList( avgList2 ) ; wcnt += 1 )
					wName = StringFromList( wcnt, avgList2 )
					KillWaves /Z $wName
				endfor
				
				break
				
			case "Histogram":
			
				Variable scale
				Variable dualDisplayPercent = 0.25
				Variable paddingBins = NMVarGet( "HistogramPaddingBins" )
				
				Variable xbgn = str2num( StringByKey("xbgn", tList, "=", ",") )
				Variable xend = str2num( StringByKey("xend", tList, "=", ",") )
				Variable binWidth = abs( str2num( StringByKey("binWidth", tList, "=", ",") ) )
				Variable dualDisplay = str2num( StringByKey("dualDisplay", tList, "=", ",") )
				
				Variable binStart, numBins
				
				String histoName, histoNameX
				
				if ( numtype( xbgn ) > 0 )
					xbgn = -inf
				endif
				
				if ( numtype( xend ) > 0 )
					xend = inf
				endif
				
				Duplicate /O/R=( xbgn, xend ) $dstName NMChanWaveMakeTemp
				
				WaveStats /Q NMChanWaveMakeTemp
				
				binStart = V_min - paddingBins * binWidth
				
				numBins = abs( V_max - V_min ) / binWidth
				numBins += 2 * paddingBins
				
				histoName = dstName + "_histo"
				histoNameX = dstName + "_histoX"
			
				Make /O/N=( numBins ) $histoName
				
				Histogram /B={ binStart, binWidth, numBins } NMChanWaveMakeTemp, $histoName
				
				if ( dualDisplay )
				
					WaveStats /Q NMChanWaveMakeTemp
					
					scale = dualDisplayPercent * abs( ( rightx( NMChanWaveMakeTemp ) - leftx( NMChanWaveMakeTemp ) ) )
				
					Duplicate /O $histoName, $histoNameX
					
					Wave wtemp = $histoNameX
					
					wtemp = x
					
					Wave wtemp = $histoName
					
					WaveStats /Q wtemp
					
					wtemp /= V_max
					wtemp *= -scale
					
					wtemp += leftx( NMChanWaveMakeTemp )
					
				else
				
					Duplicate /O $histoName $dstName
					KillWaves /Z $histoName
					
				endif
				
				KillWaves /Z NMChanWaveMakeTemp
			
				break
				
			case "Clip Events":
			
				Variable positiveEvents = str2num( StringByKey("positiveEvents", tList, "=", ",") )
				Variable eventFindLevel = str2num( StringByKey("eventFindLevel", tList, "=", ",") )
				Variable xwinBeforeEvent = str2num( StringByKey("xwinBeforeEvent", tList, "=", ",") )
				Variable xwinAfterEvent = str2num( StringByKey("xwinAfterEvent", tList, "=", ",") )
				
				NMClipEvents( xwinBeforeEvent, xwinAfterEvent, dstName, eventFindLevel = eventFindLevel, positiveEvents = positiveEvents )
				
				break
				
		endswitch
	
	endfor
	
	return 0

End // ChanWaveMake

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanWavesClear( channel )
	Variable channel // ( -1 ) for current channel ( -2 ) for all channels
	
	Variable wcnt, ccnt, cbgn, cend, overlay
	String wname, cdf
	
	Variable numChannels = NMNumChannels()
	
	if ( channel == -1 )
		cbgn = CurrentNMChannel()
		cend = cbgn
	elseif ( channel == -2 )
		cbgn = 0
		cend = numChannels - 1
	elseif ( ( channel >= 0 ) && ( channel < numChannels ) )
		cbgn = channel
		cend = channel
	else
		//return NM2Error( 10, "channel", num2str( channel ) )
		return 0
	endif

	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
	
		cdf = ChanDF( ccnt )
		
		if ( strlen( cdf ) == 0 )
			continue
		endif
		
		overlay = NumVarOrDefault( cdf + "Overlay", 0 )
		
		for ( wcnt = 0; wcnt <= overlay; wcnt += 1 ) // Nan display waves
		
			wname = ChanDisplayWaveName( 1, ccnt, wcnt )
			
			if ( WaveExists( $wname ) )
				Wave wtemp = $wname
				wtemp = Nan
			endif
			
		endfor
	
	endfor

End // ChanWavesClear

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Channel Graph Drag Wave Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMDragEnable( enable, wPrefix, waveVarName, varName, fxnName, gName, graphAxis, graphMinMax, colorR, colorG, colorB )
	Variable enable // ( 0 ) remove from graph ( 1 ) append to graph
	String wPrefix // wave prefix name ( e.g. "DragBgn" )
	String waveVarName // wave variable name
	String varName // variable name, where values are updated ( or point number of waveVarName )
	String fxnName // trigger function ( "" ) for NMDragTrigger
	String graphAxis // only "bottom" for now
	String gName // graph name
	String graphMinMax // "min" or "max"
	Variable colorR, colorG, colorB
	
	String xName = wPrefix + "X"
	String yName = wPrefix + "Y"
	String xNamePath = NMDF+xName
	String yNamePath = NMDF+yName
	
	graphAxis = "bottom"
	
	if ( WinType( gName ) != 1 )
		return -1
	endif
	
	strswitch( graphMinMax )
		case "max":
		case "min":
			break
		default:
			return -1
	endswitch
	
	RemoveFromGraph /Z/W=$gName $yName
	
	if ( ( NMVarGet( "DragOn" ) == 1 ) && ( enable == 1 ) )
	
		NMDragFoldersCheck( gName, fxnName )
	
		CheckNMwave( xNamePath, 2, -1 )
		CheckNMwave( yNamePath, 2, -1 )
		
		NMNoteType( xNamePath, "Drag Wave X", "", "", "_FXN_" )
		Note $xNamePath, "Wave Prefix:" + wPrefix
		Note $xNamePath, "WaveY:" + yNamePath
		Note $xNamePath, "Graph:" + gName
		Note $xNamePath, "Graph Axis:" + graphAxis
		Note $xNamePath, "Graph Axis MinMax:" + graphMinMax
		Note $xNamePath, "Wave Variable Name:" + waveVarName
		Note $xNamePath, "Variable Name:" + varName
		
		NMNoteType( yNamePath, "Drag Wave Y", "", "", "_FXN_" )
		Note $yNamePath, "Wave Prefix:" + wPrefix
		Note $yNamePath, "WaveX:" + xNamePath
		Note $yNamePath, "Graph:" + gName
		Note $yNamePath, "Graph Axis:" + graphAxis
		Note $yNamePath, "Graph Axis MinMax:" + graphMinMax
		Note $yNamePath, "Wave Variable Name:" + waveVarName
		Note $yNamePath, "Variable Name:" + varName
		
		NMDragUpdate2( xNamePath, yNamePath )
		
		if ( WaveExists( $yNamePath ) == 1 )
			AppendToGraph /W=$gName $yNamePath vs $xNamePath
			ModifyGraph /W=$gName lstyle( $yName )=3, rgb( $yName )=( colorR, colorG, colorB )
			ModifyGraph /W=$gName quickdrag( $yName )=1, live( $yName )=1, offset( $yName )={0,0}
		endif
		
	else
	
		if ( WaveExists( $xNamePath ) == 1 )
			Note /K $xNamePath
		endif
		
		if ( WaveExists( $yNamePath ) == 1 )
			Note /K $yNamePath
		endif
		
	endif
			
End // NMDragEnable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMDragFoldersCheck( gName, fxnName )
	String gName
	String fxnName

	String wdf = "root:WinGlobals:"
	String cdf = "root:WinGlobals:" + gName + ":"
	
	if ( WinType( gName ) != 1 )
		return -1
	endif
	
	if ( exists( fxnName ) != 6 )
		fxnName = "NMDragTrigger"
	endif
	
	if ( DataFolderExists( wdf ) == 0 )
		NewDataFolder $( RemoveEnding( wdf, ":" ) )
	endif
	
	if ( DataFolderExists( cdf ) == 0 )
		NewDataFolder $( RemoveEnding( cdf, ":" ) )
	endif
	
	CheckNMstr( cdf+"S_TraceOffsetInfo", "" )
	CheckNMvar( cdf+"HairTrigger", 0 )
	
	SetFormula $( cdf+"HairTrigger" ), fxnName + "( " + cdf + "S_TraceOffsetInfo )"

End // NMDragCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function NMDragVariableGet( wName, defaultValue )
	String wName
	Variable defaultValue
	
	Variable pnt
	
	if ( WaveExists( $wName ) == 0 )
		return defaultValue
	endif
	
	String waveVarName = NMNoteStrByKey( wName, "Wave Variable Name" )
	String varName = NMNoteStrByKey( wName, "Variable Name" )
	
	if ( exists( varName ) != 2 )
		return defaultValue
	endif
	
	if ( WaveExists( $waveVarName ) )
	
		Wave wtemp = $waveVarName 
		
		pnt = NumVarOrDefault( varName, Nan )
		
		if ( ( pnt >= 0 ) && ( pnt < numpnts( wtemp ) ) )
			return wtemp[ pnt ]
		endif
	
	endif
	
	return NumVarOrDefault( varName, defaultValue )
	
End // NMDragVariableGet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMDragVariableSet( wName, value )
	String wName
	Variable value
	
	Variable pnt
	
	if ( WaveExists( $wName ) == 0 )
		return -1
	endif
	
	String waveVarName = NMNoteStrByKey( wName, "Wave Variable Name" )
	String varName = NMNoteStrByKey( wName, "Variable Name" )
	
	if ( exists( varName ) != 2 )
		return -1
	endif
	
	if ( WaveExists( $waveVarName ) == 1 )
	
		Wave wtemp = $waveVarName 
		
		pnt = NumVarOrDefault( varName, Nan )
		
		if ( ( pnt >= 0 ) && ( pnt < numpnts( wtemp ) ) )
			wtemp[ pnt ] = value
			return 0
		endif
		
		return -1
	
	endif
	
	Variable /G $varName = value
	
	return 0
	
End // NMDragVariableSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMDragTrigger( offsetStr [ callAutoTab ] )
	String offsetStr
	Variable callAutoTab
	
	Variable tt, offset, pnt
	String gName, wName, xNamePath, yNamePath, graphMinMax, waveVarName, varName
	
	if ( strlen( offsetStr ) == 0 )
		return -1
	endif
	
	if ( ParamIsDefault( callAutoTab ) )
		callAutoTab = 1
	endif
	
	gname = StringByKey( "GRAPH", offsetStr )
	offset = str2num( StringByKey( "XOFFSET", offsetStr ) )
	wname = StringByKey( "TNAME", offsetStr )
	yNamePath = NMDF+wName
	
	if ( ( WinType( gname ) != 1 ) || ( WaveExists( $yNamePath ) == 0 ) || ( offset == 0 ) )
		return -1
	endif
	
	xNamePath = NMNoteStrByKey( yNamePath, "WaveX" )
	graphMinMax = NMNoteStrByKey( yNamePath, "Graph Axis MinMax" )
	waveVarName = NMNoteStrByKey( yNamePath, "Wave Variable Name" )
	varName = NMNoteStrByKey( yNamePath, "Variable Name" )
	
	if ( StringMatch( graphMinMax, "min" ) == 1 )
		tt = -inf
	else
		tt = inf
	endif
	
	tt = NMDragVariableGet( yNamePath, tt )
	
	if ( numtype( tt ) == 0 )
	
		tt += offset
		
	else
	
		GetAxis /W=$gName/Q bottom
		
		if ( StringMatch( graphMinMax, "min" ) == 1 )
			tt = V_min + offset
		else
			tt = V_max + offset
		endif
		
	endif
	
	if ( WaveExists( $xNamePath ) == 1 )
	
		Wave xWave = $xNamePath
	
		xWave = tt
		
	endif
	
	NMDragVariableSet( yNamePath, tt )
	
	ModifyGraph /W=$gname offset( $wname )={0,0} // remove offset
	
	SetNMvar( NMDF+"AutoDoUpdate", 0 ) // prevent DoUpdate in Tab Auto functions
	
	if ( callAutoTab )
		NMAutoTabCall()
	endif
	
	SetNMvar( NMDF+"AutoDoUpdate", 1 ) // reset update flag
	
	DoWindow /F $gname
	
	return 0
	
End // NMDragTrigger

//****************************************************************
//****************************************************************
//****************************************************************

Function NMDragClear( wPrefix )
	String wPrefix

	String xNamePath = NMDF+wPrefix + "X"
	String yNamePath = NMDF+wPrefix + "Y"
	
	if ( WaveExists( $xNamePath ) == 0 )
		return -1
	endif
	
	Wave dragX = $xNamePath
	Wave dragY = $yNamePath
	
	dragX = Nan
	dragY = Nan

End // NMDragClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMDragUpdate( wPrefix ) // Note, this must be called AFTER graphs have been auto scaled
	String wPrefix
	
	String xNamePath = NMDF+wPrefix + "X"
	String yNamePath = NMDF+wPrefix + "Y"
	
	if ( WaveExists( $xNamePath ) == 0 )
		return -1
	endif
	
	String gName = NMNoteStrByKey( yNamePath, "Graph" )
	
	if ( WinType( gName ) != 1 )
		return -1
	endif
	
	return NMDragUpdate2( xNamePath, yNamePath )
	
End // NMDragUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMDragUpdate2( xNamePath, yNamePath ) // Note, this must be called AFTER graphs have been auto scaled
	String xNamePath, yNamePath 
	
	Variable value, pnt
	
	if ( WaveExists( $xNamePath ) == 0 )
		return -1
	endif
	
	String gName = NMNoteStrByKey( yNamePath, "Graph" )
	String graphMinMax = NMNoteStrByKey( yNamePath, "Graph Axis MinMax" )
	String waveVarName = NMNoteStrByKey( yNamePath, "Wave Variable Name" )
	String varName = NMNoteStrByKey( yNamePath, "Variable Name" )
	
	if ( WinType( gName ) != 1 )
		return -1
	endif

	Wave dragX = $xNamePath
	Wave dragY = $yNamePath
	
	if ( NMVarGet( "DragOn" ) == 1 )
	
		if ( NMVarGet( "AutoDoUpdate" ) == 1 )
			DoUpdate /W=$gName
		endif
		
		if ( StringMatch( graphMinMax, "min" ) == 1 )
			value = -inf
		else
			value = inf
		endif
		
		value = NMDragVariableGet( yNamePath, value )
		
		if ( numtype( value ) == 0 )
		
			dragX = value
			
		elseif ( numtype( value ) == 1 ) // inf
		
			GetAxis /W=$gName/Q bottom
			
			if ( StringMatch( graphMinMax, "min" ) == 1 )
				dragX = V_min
			else
				dragX = V_max
			endif
		
		endif
		
		GetAxis /W=$gName/Q left
		
		if ( numpnts( dragY ) == 2 )
			dragY[ 0 ] = V_min
			dragY[ 1 ] = V_max
		endif
	
	else
	
		dragX = Nan
		dragY = Nan
		
	endif

End // NMDragUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMDragExists( gName )
	String gName
	
	Variable wcnt
	String wList, yNamePath, type
	
	if ( WinType( gName ) != 1 )
		return 0
	endif
	
	wList = TraceNameList( gName, ";", 1 )
	
	if ( ItemsInList( wList ) == 0 )
		return 0
	endif
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
	
		yNamePath = NMDF+StringFromList( wcnt, wList )
		
		if ( WaveExists( $yNamePath ) == 0 )
			continue
		endif
		
		type = NMNoteStrByKey( yNamePath, "Type" )
		
		if ( StringMatch( type, "Drag Wave Y" ) == 1 )
			return 1
		endif
	
	endfor
	
	return 0
	
End // NMDragExists

//****************************************************************
//****************************************************************
//****************************************************************

Function NMDragGraphUtility( gName, select )
	String gName
	String select // "clear" or "remove" or "update"
	
	Variable wcnt
	String wList, yName, yNamePath, type, wPrefix
	
	if ( WinType( gName ) != 1 )
		return 0
	endif
	
	wList = TraceNameList( gName, ";", 1 )
	
	if ( ItemsInList( wList ) == 0 )
		return 0
	endif
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
	
		yName = StringFromList( wcnt, wList )
		yNamePath = NMDF+yName
		
		type = NMNoteStrByKey( yNamePath, "Type" )
		wPrefix = NMNoteStrByKey( yNamePath, "Wave Prefix" )
		
		if ( StringMatch( type, "Drag Wave Y" ) == 0 )
			continue
		endif
		
		strswitch( select )
		
			case "clear":
				if ( strlen( wPrefix ) > 0 )
					NMDragClear( wPrefix )
				endif
				break
				
			case "remove":
				RemoveFromGraph /Z/W=$gName $yName
				break
				
			case "update":
				if ( strlen( wPrefix ) > 0 )
					NMDragUpdate( wPrefix )
				endif
				break
				
		endswitch
	
	endfor
	
	return 0
	
End // NMDragGraphUtility

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Channel Graph Marquee Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Menu "GraphMarquee"
	
	NMExpandAndFreezeMenuStr( "-" )
	NMExpandAndFreezeMenuStr( "NM Expand and Freeze" ), NMExpandAndFreeze()
	NMExpandAndFreezeMenuStr( "NM Expand and Freeze Y" ), NMExpandAndFreezeY()
	NMExpandAndFreezeMenuStr( "NM Expand and Freeze X" ), NMExpandAndFreezeX()
	NMExpandAndFreezeMenuStr( "NM Expand and Freeze All X" ), NMExpandAndFreezeAllX()
	
End

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMExpandAndFreezeMenuStr( menuStr )
	String menuStr
	
	String gName = WinName( 0, 1 )
	
	if ( strsearch( gName, NMChanGraphPrefix, 0 ) != 0 )
		return ""
	endif
	
	if ( ( strsearch( menuStr, "All X", 0 ) > 0 ) && ( NMNumChannels() <= 1 ) )
		return ""
	endif
	
	return menuStr

End // NMExpandAndFreezeMenuStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMExpandAndFreeze() // freeze channel graph xy scales

	GetMarquee /K left, bottom
	
	String gName = WinName( 0,1 )
	
	if ( ( V_Flag == 0 ) || !IsChanGraph( gName ) )
		return 0
	endif
	
	Variable channel = ChanChar2Num( gName[4,4] )
	
	if ( NMChannelOK( channel ) )
		NMChannelGraphSet( channel = channel , xmin = V_left, xmax = V_right, ymin = V_bottom, ymax = V_top, history = 1 )
	endif
	
	return 0

End //NMExpandAndFreeze

//****************************************************************
//****************************************************************
//****************************************************************

Function NMExpandAndFreezeX() // freeze channel graph x scale

	GetMarquee /K left, bottom
	
	String gName = WinName( 0,1 )
	
	if ( ( V_Flag == 0 ) || !IsChanGraph( gName ) )
		return 0
	endif
	
	Variable channel = ChanChar2Num( gName[ 4, 4 ] )
	
	if ( NMChannelOK( channel ) )
		NMChannelGraphSet( channel = channel , xmin = V_left, xmax = V_right, history = 1 )
	endif
	
	return 0

End //NMExpandAndFreezeX

//****************************************************************
//****************************************************************
//****************************************************************

Function NMExpandAndFreezeY() // freeze channel graph x scale

	GetMarquee /K left, bottom
	
	String gName = WinName( 0,1 )
	
	if ( ( V_Flag == 0 ) || !IsChanGraph( gName ) )
		return 0
	endif
	
	Variable channel = ChanChar2Num( gName[ 4, 4 ] ) 
	
	if ( NMChannelOK( channel ) )
		NMChannelGraphSet( channel = channel , ymin = V_bottom, ymax = V_top, history = 1 )
	endif
	
	return 0

End //NMExpandAndFreezeY

//****************************************************************
//****************************************************************
//****************************************************************

Function NMExpandAndFreezeAllX()

	GetMarquee /K left, bottom
	
	String gName = WinName( 0,1 )
	
	if ( ( V_Flag == 0 ) || !IsChanGraph( gName ) )
		return 0
	endif
	
	NMChannelGraphSet( channel = -2 , xmin = V_left, xmax = V_right, history = 1 )
	
	return 0
	
End //NMExpandAndFreezeAllX

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Functions No Longer Used
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ChanDragUtility( select ) // NOT USED
	String select // "clear" or "remove" or "update"

	Variable ccnt, numChannels = NMNumChannels()
	String gName
	
	for ( ccnt = 0; ccnt < numChannels; ccnt+=1 )
		gName = ChanGraphName( ccnt )
		NMDragGraphUtility( gName, select )
	endfor

End // ChanDragUtility

//****************************************************************
//****************************************************************
//****************************************************************
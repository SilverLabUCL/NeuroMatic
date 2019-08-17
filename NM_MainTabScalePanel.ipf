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
//	Main Tab Scale Panel Functions 
//
//****************************************************************
//****************************************************************

StrConstant NMScalePanelName = "NMScalePanel2"

//****************************************************************
//****************************************************************
//
//		Scale Panel Functions */+-=
//
//****************************************************************
//****************************************************************

Function /S NMScalePanel( [ mode, align ] )
	String mode // "value" or "wave of values" or "wave point-by-point"
	Variable align // ( 0 ) scale panel ( 1 ) align panel
	
	Variable fs, xPixels, x1, x2, y1, y2, width = 800, height = 400
	Variable x0 = 20, y0 = 20, yinc = 40
	Variable w0, w1, w2, w3, w4
	String title, paramList = ""
	
	String wNameLB = NMMainDF + "ScaleLB"
	String wNameLBS = NMMainDF + "ScaleLBselect"
	String wNameLBC = NMMainDF + "ScaleLBcolor"
	
	if ( align )
		mode = "wave of values"
		SetNMstr( NMMainDF + "ScaleMode", mode )
	endif
	
	SetNMvar( NMMainDF + "ScaleAlign", align )
	
	if ( !ParamIsDefault( mode ) )
	
		strswitch( mode )
			case "value":
			case "wave of values":
			case "wave point-by-point":
				SetNMstr( NMMainDF + "ScaleMode", mode )
				paramList = NMCmdStrOptional( "mode", mode, paramList )
		endswitch
		
	endif
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	KillWaves /Z $wNameLB
	KillWaves /Z $wNameLBS
	KillWaves /Z $wNameLBC
	
	zListBoxUpdate()
	
	SetNMstr( NMMainDF + "ScaleOp", "" )
	SetNMstr( NMMainDF + "ScaleFactor", "" )
	CheckNMvar( NMMainDF + "ScaleXbgn", -inf )
	CheckNMvar( NMMainDF + "ScaleXend", inf )
	SetNMstr( NMMainDF + "ScaleWaveSelect", "" )
	SetNMvar( NMMainDF + "ScalezEditCells", 0 )
	CheckNMvar( NMMainDF + "ScalezWaveLengthFormat", 1 )
	
	xPixels = NMComputerPixelsX()
	x1 = ( xPixels - width ) / 2
	y1 = 140
	x2 = x1 + width
	y2 = y1 + height
	
	fs = NMPanelFsize
	
	if ( align )
		title = NMPromptStr( "NM StartX Alignment" )
	else
		title = NMPromptStr( "NM Scale" )
	endif
	
	DoWindow /K $NMScalePanelName
	NewPanel /K=1/N=$NMScalePanelName/W=(x1,y1,x2,y2) as title
	
	PopupMenu MN_ScaleMode, pos={x0,y0}, size={214,20}, bodyWidth=160, fsize=fs, win=$NMScalePanelName
	PopupMenu MN_ScaleMode, mode=1, value=NMScalePanelModeList(), proc=NMScalePanelPopup, win=$NMScalePanelName
	
	if ( align )
		PopupMenu MN_ScaleMode, title = "align by a ", win=$NMScalePanelName
	else
		PopupMenu MN_ScaleMode, title = "scale by a ", win=$NMScalePanelName
	endif
	
	PopupMenu MN_ScaleAlignAt, disable=1, pos={x0,y0+1*yinc}, size={214,20}, bodywidth=160, fsize=fs, win=$NMScalePanelName
	PopupMenu MN_ScaleAlignAt, title = "align at ", proc=NMScalePanelPopup, win=$NMScalePanelName
	PopupMenu MN_ScaleAlignAt, value=NMAlignAtList, win=$NMScalePanelName
	
	PopupMenu MN_ScaleOp, disable=1, pos={x0,y0+1*yinc}, size={139,20}, bodywidth=60, fsize=fs, win=$NMScalePanelName
	PopupMenu MN_ScaleOp, title = "select operation ", value=NMScalePanelOpList( all = 2 ), proc=NMScalePanelPopup, win=$NMScalePanelName
	
	SetVariable MN_ScaleXbgn, disable=1, title="xbgn", pos={x0,y0+2*yinc}, size={100,20}, limits={-inf,inf,0}, win=$NMScalePanelName
	SetVariable MN_ScaleXbgn, frame=1, value=$( NMMainDF + "ScaleXbgn" ), fsize=fs, proc=NMScalePanelSetVariable, win=$NMScalePanelName
	
	SetVariable MN_ScaleXend, disable=1, title="xend", pos={x0+114,y0+2*yinc}, size={100,20}, limits={-inf,inf,0}, win=$NMScalePanelName
	SetVariable MN_ScaleXend, frame=1, value=$( NMMainDF + "ScaleXend" ), fsize=fs, proc=NMScalePanelSetVariable, win=$NMScalePanelName
	
	SetVariable MN_ScaleValue, disable=1, pos={x0,y0+3*yinc}, size={214,20}, limits={-inf,inf,1}, win=$NMScalePanelName
	SetVariable MN_ScaleValue frame=1, value=$( NMMainDF + "ScaleFactor" ), fsize=fs, proc=NMScalePanelSetVariable, win=$NMScalePanelName
	
	if ( align )
		SetVariable MN_ScaleValue title="enter alignment value", win=$NMScalePanelName
	else
		SetVariable MN_ScaleValue title="enter scale value", win=$NMScalePanelName
	endif
	
	y0 += 3 * yinc + 10
	yinc = 30
	
	GroupBox MN_ScaleGroup, title = "", pos={x0,y0-5}, size={215,90}, fsize=fs, win=$NMScalePanelName
	
	y0 += 20
	
	PopupMenu MN_ScaleWave, pos={x0+15,y0}, size={185,20}, bodyWidth=185, fsize=fs, win=$NMScalePanelName
	PopupMenu MN_ScaleWave, value="", proc=NMScalePanelPopup, win=$NMScalePanelName
	
	Button MN_ScaleBrowse, title="Browse", pos={x0+60,y0+1*yinc}, size={100,20}, fsize=fs, proc=NMScalePanelButton, win=$NMScalePanelName
	
	CheckBox MN_ScalezWaveLengthFormat, title="Wave Length Format", pos={x0+15,y0+2*yinc}, size={16,18}, value=0, win=$NMScalePanelName
	CheckBox MN_ScalezWaveLengthFormat, fsize=fs, proc=NMScalePanelCheckBox, win=$NMScalePanelName
	
	y0 = height - 110
	yinc = 35
	
	CheckBox MN_ScalezEditCells, title="Edit Cells", pos={x0+15,y0}, size={16,18}, value=0, win=$NMScalePanelName
	CheckBox MN_ScalezEditCells, fsize=fs, proc=NMScalePanelCheckBox, win=$NMScalePanelName
	
	CheckBox MN_ScaleLongHistory, title="Short History", pos={x0+110,y0}, size={16,18}, value=1, win=$NMScalePanelName
	CheckBox MN_ScaleLongHistory, fsize=fs, proc=NMScalePanelCheckBox, win=$NMScalePanelName
	
	Button MN_ScaleReset, title="Reset", pos={x0,y0+1*yinc}, size={100,20}, fsize=fs, proc=NMScalePanelButton, win=$NMScalePanelName
	Button MN_ScaleCancel, title="Cancel", pos={x0+115,y0+1*yinc}, size={100,20}, fsize=fs, proc=NMScalePanelButton, win=$NMScalePanelName
	Button MN_ScaleExecute, title="\K("+NMRedStr+")Execute", pos={x0+60,y0+2*yinc}, size={100,20}, fsize=fs, proc=NMScalePanelButton, win=$NMScalePanelName
	
	x0 = 255
	y0 = 20
	
	height -= 2 * y0
	width = 520
	
	w0 = 20; w1 = 100; w2 = 20; w3 = 100; w4 = 0

	ListBox MD_ScaleInputs, pos={x0,y0}, size={width,height}, fsize=fs, win=$NMScalePanelName
	ListBox MD_ScaleInputs, listWave=$wNameLB, selWave=$wNameLBS, colorWave=$wNameLBC, win=$NMScalePanelName
	ListBox MD_ScaleInputs, mode=1, proc=NMScalePanelListBoxInput, win=$NMScalePanelName
	ListBox MD_ScaleInputs, selRow=-1, editStyle=1, userColumnResize=1, win=$NMScalePanelName
	ListBox MD_ScaleInputs, widths={w0,w1,w2,w3,w4}, win=$NMScalePanelName
	
	zPanelUpdate()
	
	return ""
	
End // NMScalePanel

//****************************************************************
//****************************************************************

Static Function zPanelUpdate( [ reset, browserSelect ] )
	Variable reset, browserSelect

	Variable md, numRows, numCols, numPoints, source, zWaveLengthFormat, longHistory, align
	Variable w0, w1, w2, w3, w4, w5, w6, opWidth
	String alignAtSelect, scaleMode, scaleModeList, op, wName, txt
	
	if ( WinType( NMScalePanelName ) != 7 )
		return -1
	endif
	
	DoWindow /F $NMScalePanelName
	
	align = NumVarOrDefault( NMMainDF + "ScaleAlign", 0 )
	scaleMode = StrVarOrDefault( NMMainDF + "ScaleMode", "" )
	scaleModeList = NMScalePanelModeList()
	
	md = 1 + WhichListItem( scaleMode, scaleModeList )
	md = max( md, 1 )
	
	if ( strlen( scaleMode ) > 0 )
		PopupMenu MN_ScaleMode, mode=md, popValue=scaleMode, win=$NMScalePanelName
	else
		PopupMenu MN_ScaleMode, mode=1, win=$NMScalePanelName
	endif
	
	if ( reset )
	
		SetNMstr( NMMainDF + "ScaleOp", "" )
		SetNMstr( NMMainDF + "ScaleFactor", "" )
		SetNMvar( NMMainDF + "ScaleXbgn", -inf )
		SetNMvar( NMMainDF + "ScaleXend", inf )
		SetNMstr( NMMainDF + "ScaleWaveSelect", "" )

		if ( WaveExists( $NMMainDF + "ScaleLB" ) )
		
			Wave /T scaleLB = $NMMainDF + "ScaleLB"
			Wave scaleLBS = $NMMainDF + "ScaleLBselect"
	
			scaleLB[][ %n ] = num2istr( x )
			
			scaleLB[][ %source ] = ""
			scaleLBS[][][ %foreColors ] = 0
			
			if ( align )
				scaleLB[][ %value ] = ""
				scaleLB[][ %startx ] = ""
			else
				scaleLB[][ %op ] = ""
				scaleLB[][ %factor ] = ""
			endif
			
		endif
	
		PopupMenu MN_ScaleOp, mode=1, win=$NMScalePanelName
		PopupMenu MN_ScaleWave, mode=1, win=$NMScalePanelName
		ListBox MD_ScaleInputs, selRow=-1, win=$NMScalePanelName
		
		SetNMvar( NMMainDF + "ScalezEditCells", 0 )
	
		if ( align )
			scaleLBS[][ %value ][ 0 ] = 0
			scaleLBS[][ %startx ][ 0 ] = 0
		else
			scaleLBS[][ %op ][ 0 ] = 0
			scaleLBS[][ %factor ][ 0 ] = 0
		endif
		
	endif
	
	if ( align )
	
		alignAtSelect = StrVarOrDefault( NMMainDF + "ScaleAlignAtSelect", "zero" )
		
		md = 1 + WhichListItem( alignAtSelect, NMAlignAtList )
		md = max( md, 1 )
	
		PopupMenu MN_ScaleAlignAt, disable=0, mode=md, popValue=alignAtSelect, win=$NMScalePanelName
		PopupMenu MN_ScaleOp, disable=1, win=$NMScalePanelName
		SetVariable MN_ScaleXbgn, disable=1, win=$NMScalePanelName
		SetVariable MN_ScaleXend, disable=1, win=$NMScalePanelName
		scaleMode = "wave of values"
		
	else
	
		PopupMenu MN_ScaleAlignAt, disable=1, win=$NMScalePanelName
		PopupMenu MN_ScaleOp, disable=0, win=$NMScalePanelName
		SetVariable MN_ScaleXbgn, disable=0, win=$NMScalePanelName
		SetVariable MN_ScaleXend, disable=0, win=$NMScalePanelName
		
	endif
	
	strswitch( scaleMode )
		
		case "value":
		
			SetVariable MN_ScaleValue, disable=0, win=$NMScalePanelName
			
			GroupBox MN_ScaleGroup, disable=1, size={215,90}, win=$NMScalePanelName
			PopupMenu MN_ScaleWave, disable=1, win=$NMScalePanelName
			Button MN_ScaleBrowse, disable=1, win=$NMScalePanelName
			CheckBox MN_ScalezWaveLengthFormat, disable=1, win=$NMScalePanelName
			
			break
			
		case "wave of values":
		
			zWaveLengthFormat = NumVarOrDefault( NMMainDF + "ScalezWaveLengthFormat", 1 )
		
			numPoints = zPanelNumPoints( 1 )
			
			txt = "choose wave ( " + num2istr( numPoints ) + " points )"
		
			SetVariable MN_ScaleValue, disable=1, win=$NMScalePanelName
			
			GroupBox MN_ScaleGroup, disable=0, size={215,115}, title=txt, win=$NMScalePanelName
			PopupMenu MN_ScaleWave, disable=0, win=$NMScalePanelName
			Button MN_ScaleBrowse, disable=0, win=$NMScalePanelName
			
			if ( zWaveLengthFormat == 1 )
				txt = "pnts = # selected waves"
			else
				txt = "pnts = total # waves       "
			endif
			
			CheckBox MN_ScalezWaveLengthFormat, title=txt, disable=0, value = zWaveLengthFormat, win=$NMScalePanelName
			
			source = 1
			
			break
			
		case "wave point-by-point":
		
			numPoints = zPanelNumPoints( 1 )
			
			txt = "choose wave ( " + num2istr( numPoints ) + " points )"
		
			SetVariable MN_ScaleValue, disable=1, win=$NMScalePanelName
			
			GroupBox MN_ScaleGroup, disable=0, size={215,90}, title=txt, win=$NMScalePanelName
			PopupMenu MN_ScaleWave, disable=0, win=$NMScalePanelName
			Button MN_ScaleBrowse, disable=0, win=$NMScalePanelName
			CheckBox MN_ScalezWaveLengthFormat, disable=1, win=$NMScalePanelName
			
			break
			
		default:
		
			SetVariable MN_ScaleValue, disable=1, win=$NMScalePanelName
			
			GroupBox MN_ScaleGroup, disable=1, size={215,90}, win=$NMScalePanelName
			PopupMenu MN_ScaleWave, disable=1, win=$NMScalePanelName
			Button MN_ScaleBrowse, disable=1, win=$NMScalePanelName
			CheckBox MN_ScalezWaveLengthFormat, disable=1, win=$NMScalePanelName

	endswitch
	
	if ( browserSelect )
	
		wName = StrVarOrDefault( NMMainDF + "ScaleWaveSelect", "" )
		
		md = 1 + WhichListItem( wName, NMScalePanelWaveList() )
		
		PopupMenu MN_ScaleWave, mode=md, value=NMScalePanelWaveList(), win=$NMScalePanelName
		
	else
	
		PopupMenu MN_ScaleWave, value=NMScalePanelWaveList(), win=$NMScalePanelName
	
	endif
	
	CheckBox MN_ScalezEditCells, value=NumVarOrDefault( NMMainDF + "ScalezEditCells", 0 ) , win=$NMScalePanelName
	
	longHistory = NumVarOrDefault( NMMainDF + "ScaleLongHistory", 0 )
	
	if ( longHistory )
		CheckBox MN_ScaleLongHistory, title = "Long History     ", value=1, win=$NMScalePanelName
	else
		CheckBox MN_ScaleLongHistory, title = "Short History     ", value=1, win=$NMScalePanelName
	endif
	
	numCols = DimSize( $NMMainDF + "ScaleLB" , 1 )
	
	if ( align )
		opWidth = 100
	else
		opWidth = 20
	endif
	
	switch( numCols )
		case 5: // 1 channel
			if ( source )
				w0 = 20; w1 = 100; w2 = opWidth; w3 = 100; w4 = 100
			else
				w0 = 20; w1 = 100; w2 = opWidth; w3 = 100; w4 = 0
			endif
			break
		case 6: // 2 channels
			if ( source )
				w0 = 20; w1 = 80; w2 = 80; w3 = opWidth; w4 = 80; w5 = 100
			else
				w0 = 20; w1 = 80; w2 = 80; w3 = opWidth; w4 = 80; w5 = 0
			endif
			break
		case 7: // 3 channels
			if ( source )
				w0 = 20; w1 = 60; w2 = 60; w3 = 60; w4 = opWidth; w5 = 60; w6 = 100
			else
				w0 = 20; w1 = 60; w2 = 60; w3 = 60; w4 = opWidth; w5 = 60; w6 = 0
			endif
			break
	endswitch
	
	ListBox MD_ScaleInputs, widths={w0,w1,w2,w3,w4,w5,w6}, win=$NMScalePanelName
	
	zListBoxUpdate()
	
	return 0

End // zPanelUpdate

//****************************************************************
//****************************************************************

Static Function zListBoxMake()

	Variable numRows, numCols
	
	Variable numChanLimit = 3
	Variable extraColumns = 4

	String wNameLB = NMMainDF + "ScaleLB"
	String wNameLBS = wNameLB + "select"
	String wNameLBC = wNameLB + "color"
	
	String chanList = NMChanSelectCharList()
	Variable numChannels = ItemsInList( chanList )
	
	if ( ItemsInList( chanList ) == 0 )
		return -1
	endif
	
	numChannels = min( numChannels, numChanLimit )
	
	numCols = numChannels + extraColumns
			
	numRows = zPanelNumPoints( 0 )
	
	if ( WaveExists( $wNameLB ) )
		Redimension /N=( numRows, numCols ) $wNameLB
		Redimension /N=( numRows, numCols, 2 ) $wNameLBS
	else
		Make /O/T/N=( numRows, numCols ) $wNameLB = ""
		Make /B/U/O/N=( numRows, numCols, 2 ) $wNameLBS = 0
		Make /O/W/U/N=( 4, 3 ) $wNameLBC = 0
	endif
		
End // zListBoxMake

//****************************************************************
//****************************************************************

Static Function zListBoxUpdate()

	Variable ccnt, wcnt, numRows, numCols, numChannels, numWaves, chanNum
	Variable zEditCells, zWaveLengthFormat, wListFormat
	String wList, wList2, wName, chanChar, chanList, scaleMode
	
	STRUCT NMRGB c

	String wNameLB = NMMainDF + "ScaleLB"
	String wNameLBS = wNameLB + "select"
	String wNameLBC = wNameLB + "color"
	
	Variable align = NumVarOrDefault( NMMainDF + "ScaleAlign", 0 )
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	chanList = NMChanSelectCharList()
	
	numChannels = ItemsInList( chanList )
	
	if ( numChannels == 0 )
		return -1
	endif

	zListBoxMake()
	
	numRows = DimSize( $wNameLB, 0 )
	numCols = DimSize( $wNameLB, 1 )
	
	Wave /T scaleLB = $wNameLB
	Wave scaleLBS = $wNameLBS
	Wave scaleLBC = $wNameLBC
	
	SetDimLabel 1, 0, n, scaleLB
	
	if ( align )
		SetDimLabel 1, ( numCols - 3 ), value, scaleLB
		SetDimLabel 1, ( numCols - 2 ), startx, scaleLB
	else
		SetDimLabel 1, ( numCols - 3 ), op, scaleLB
		SetDimLabel 1, ( numCols - 2 ), factor, scaleLB
	endif
	
	SetDimLabel 1, ( numCols - 1 ), source, scaleLB
	
	SetDimLabel 1, 0, n, scaleLBS
	
	if ( align )
		SetDimLabel 1, ( numCols - 3 ), value, scaleLBS
		SetDimLabel 1, ( numCols - 2 ), startx, scaleLBS
	else
		SetDimLabel 1, ( numCols - 3 ), op, scaleLBS
		SetDimLabel 1, ( numCols - 2 ), factor, scaleLBS
	endif
	
	SetDimLabel 1, ( numCols - 1 ), source, scaleLBS
	
	SetDimLabel 2, 0, state, scaleLBS
	//SetDimLabel 2, 1, backColors, scaleLBS
	SetDimLabel 2, 1, foreColors, scaleLBS
	
	SetDimLabel 1, 0, r, scaleLBC
	SetDimLabel 1, 1, g, scaleLBC
	SetDimLabel 1, 2, b, scaleLBC
	
	NMColorList2RGB( NMRedStr, c )
	
	scaleLBC[ 1 ][ %r ] = c.r
	scaleLBC[ 1 ][ %g ] = c.g
	scaleLBC[ 1 ][ %b ] = c.b
	
	NMColorList2RGB( NMGreenStr, c )
	
	scaleLBC[ 2 ][ %r ] = c.r
	scaleLBC[ 2 ][ %g ] = c.g
	scaleLBC[ 2 ][ %b ] = c.b
	
	NMColorList2RGB( NMBlueStr, c )
	
	scaleLBC[ 3 ][ %r ] = c.r
	scaleLBC[ 3 ][ %g ] = c.g
	scaleLBC[ 3 ][ %b ] = c.b
	
	zEditCells = NumVarOrDefault( NMMainDF + "ScalezEditCells", 0 )
	
	scaleLB[][ %n ] = num2istr( x )
	
	scaleLBS[][][%foreColors] = 0
	
	if ( align )
	
		if ( zEditCells )
			scaleLBS[][ %value ][ 0 ] = 3
			scaleLBS[][ %startx ][ 0 ] = 0
		else
			scaleLBS[][ %value ][ 0 ] = 0
			scaleLBS[][ %startx ][ 0 ] = 0
		endif
	
	else
	
		if ( zEditCells )
			scaleLBS[][ %op ][ 0 ] = 3
			scaleLBS[][ %factor ][ 0 ] = 3
		else
			scaleLBS[][ %op ][ 0 ] = 0
			scaleLBS[][ %factor ][ 0 ] = 0
		endif
		
	endif
	
	scaleMode = StrVarOrDefault( NMMainDF + "ScaleMode", "" )
	zWaveLengthFormat = NumVarOrDefault( NMMainDF + "ScalezWaveLengthFormat", 1 )
	
	if ( StringMatch( scaleMode, "wave of values" ) && ( zWaveLengthFormat == 0 ) )
		wListFormat = 1
	endif
	
	for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
	
		chanChar = StringFromList( ccnt, chanList )
		chanNum = ChanChar2Num( chanChar )
		
		wList = NMWaveSelectList( chanNum )
	
		if ( wListFormat )
			wList2 = NMChanWaveList( ccnt )
		else
			wList2 = wList
		endif
			
		numWaves = ItemsInList( wList2 )
		
		if ( numWaves == 0 )
			continue
		endif
		
		switch( chanNum )
			case 0:
				SetDimLabel 1, ( ccnt + 1 ), ChA, scaleLB
				break
			case 1:
				SetDimLabel 1, ( ccnt + 1 ), ChB, scaleLB
				break
			case 2:
				SetDimLabel 1, ( ccnt + 1 ), ChC, scaleLB
				break
			case 3:
				SetDimLabel 1, ( ccnt + 1 ), ChD, scaleLB
				break
		endswitch
		
		for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
			
			wName = StringFromList( wcnt, wList2 )
			
			if ( wListFormat && ( WhichListItem( wName, wList) == -1 ) )
				scaleLB[ wcnt ][ ccnt + 1 ] = ""
			else
				scaleLB[ wcnt ][ ccnt + 1 ] = wName
			endif
		
		endfor
	
	endfor

End // zListBoxUpdate

//****************************************************************
//****************************************************************

Static Function zListBoxCheck()

	Variable wcnt, ccnt, numRows, numCols, numChans, extraColumns = 4
	String sName

	if ( !WaveExists( $NMMainDF + "ScaleLB" ) )
		return NM2Error( 1, "ScaleLB", "" )
	endif
	
	Wave /T scaleLB = $NMMainDF + "ScaleLB"
	Wave scaleLBS = $NMMainDF + "ScaleLBselect"
	
	Variable align = NumVarOrDefault( NMMainDF + "ScaleAlign", 0 )
	
	numRows = DimSize( scaleLB , 0 )
	numCols = DimSize( scaleLB , 1 )
	numChans = numCols - extraColumns
	
	scaleLBS[][][ %foreColors ] = 0
	
	for ( wcnt = 0 ; wcnt < numRows ; wcnt += 1 )
	
		for ( ccnt = 0 ; ccnt < numChans ; ccnt += 1 )
		
			if ( !align )
				if ( StringMatch( scaleLB[ wcnt ][ ccnt + 1 ], scaleLB[ wcnt ][ %factor ] ) )
					scaleLBS[ wcnt ][ %factor ][ %foreColors ] = 1 // scale by self ( point-by-point )
				endif
			endif
			
			sName = scaleLB[ wcnt ][ %source ]
			
			if ( ( strlen( sName ) > 0 ) && !StringMatch( scaleLB[ wcnt ][ ccnt + 1 ], sName ) )
				scaleLBS[ wcnt ][ %source ][ %foreColors ] = 1
			endif
			
		endfor
		
	endfor

End // zListBoxCheck

//****************************************************************
//****************************************************************

Static Function zPanelNumPoints( select )
	Variable select // number of points for ( 0 ) Listbox ( 1 ) waves in popup mneu

	Variable zWaveLengthFormat
	
	String scaleMode = StrVarOrDefault( NMMainDF + "ScaleMode", "" )

	strswitch( scaleMode )
		
		case "value":
			if ( select == 0 )
				return ItemsInList( NMWaveSelectList( -1 ) )
			else
				return NaN
			endif
			
		case "wave of values":
		
			zWaveLengthFormat = NumVarOrDefault( NMMainDF + "ScalezWaveLengthFormat", 1 )
			
			if ( zWaveLengthFormat == 1 )
				return ItemsInList( NMWaveSelectList( -1 ) )
			else
				return NMNumWaves()
			endif
		
		case "wave point-by-point":
			if ( select == 0 )
				return ItemsInList( NMWaveSelectList( -1 ) )
			else
				return NMWaveSelectXstats( "numpnts", -1 )
			endif
		
	endswitch

	return ItemsInList( NMWaveSelectList( -1 ) )

End // zPanelNumPoints

//****************************************************************
//****************************************************************

Function NMScalePanelCheckBox(ctrlName, checked) : CheckBoxControl
	String ctrlName; Variable checked
	
	ctrlName = ReplaceString( "MN_", ctrlName, "" )
	
	strswitch( ctrlName )
			
		case "ScalezWaveLengthFormat":
			zWaveLengthFormat( checked )
			break
			
		case "ScalezEditCells":
			zEditCells( checked )
			break
			
		case "ScaleLongHistory":
			zHistoryToggle()
			break
	
	endswitch

End // NMScalePanelCheckBox

//****************************************************************
//****************************************************************

Function NMScalePanelButton( ctrlName ): ButtonControl
	String ctrlname
	
	ctrlName = ReplaceString( "MN_", ctrlName, "" )
	
	strswitch( ctrlName )
	
		case "ScaleBrowse":
			zWaveBrowser()
			break
			
		case "ScaleExecute":
			zPanelExecute()
			//DoWindow /K $NMScalePanelName
			break
		
		case "ScaleReset":
			zPanelUpdate( reset = 1 )
			break
			
		case "ScaleCancel":
			DoWindow /K $NMScalePanelName
			break
	
	endswitch
	
End // NMScalePanelButton

//****************************************************************
//****************************************************************

Function NMScalePanelPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	ctrlName = ReplaceString( "MN_", ctrlName, "" )
	
	strswitch( ctrlName )
	
		case "ScaleMode":
			SetNMstr( NMMainDF + "ScaleMode", popStr )
			zPanelUpdate( reset = 1 )
			break
	
		case "ScaleOp":
			zOperationSet( popStr )
			break
			
		case "ScaleWave":
			zScaleByWaveSet( popStr )
			break
			
		case "ScaleAlignAt":
			SetNMstr( NMMainDF + "ScaleAlignAtSelect", popStr )
			zStartXCompute()
			break
	
	endswitch
	
End // NMScalePanelPopup

//****************************************************************
//****************************************************************

Function NMScalePanelSetVariable( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	ctrlName = ReplaceString( "MN_", ctrlName, "" )
	
	strswitch( ctrlName )
	
		case "ScaleValue":
			if ( zScaleFactorSet( varStr ) != 0 )
				SetNMstr( NMMainDF + "ScaleFactor", "" )
			endif
			break
			
		case "ScaleXbgn":
			if ( numtype( varNum ) > 0 )
				SetNMvar( NMMainDF + "ScaleXbgn", -inf )
			endif
			break
			
		case "ScaleXend":
			if ( numtype( varNum ) > 0 )
				SetNMvar( NMMainDF + "ScaleXend", inf )
			endif
			break
	
	endswitch

End // NMScalePanelSetVariable

//****************************************************************
//****************************************************************

Function NMScalePanelListBoxInput( ctrlName, row, col, event ) : ListboxControl
	String ctrlName // name of this control
	Variable row // row if click in interior, -1 if click in title
	Variable col // column number
	Variable event // event code
		// 1 - mouse down
		// 2 - mouse up
		// 3 - double click
		// 4 - cell selection
		// 6 - begin cell edit
		// 7 - end cell edit
		// 13 - checkbox clicked
	
	Variable value
	String scaleMode, dimLabel, op, opList, valueStr, wName
	
	if ( event != 7 )
		return 0 // editing not finished
	endif
	
	if ( !WaveExists( $NMMainDF + "ScaleLB" ) )
		return NM2Error( 1, "ScaleLB", "" )
	endif
	
	scaleMode = StrVarOrDefault( NMMainDF + "ScaleMode", "" )
	
	Wave /T scaleLB = $NMMainDF + "ScaleLB"
	
	dimLabel = GetDimLabel( scaleLB, 1, col )
	
	strswitch( dimLabel )
	
		case "op":
		
			op = scaleLB[ row ][ col ]
			opList = NMScalePanelOpList( all = 1 )
			
			if ( strlen( scaleLB[ row ][ 1 ] ) == 0 )
				scaleLB[ row ][ col ] = ""
				break
			endif
			
			if ( ( strlen( op ) > 0 ) && ( WhichListItem( op, opList ) == -1 ) )
				DoAlert /T="NM Scale Error" 0, "Encountered illegal operation " + NMQuotes( op )
				scaleLB[ row ][ col ] = ""
			endif
		
			break
			
		case "factor":
		case "value":
		
			if ( strlen( scaleLB[ row ][ 1 ] ) == 0 )
				scaleLB[ row ][ col ] = ""
				break
			endif
		
			strswitch( scaleMode )
			
				case "value":
				case "wave of values":
				
					valueStr = scaleLB[ row ][ col ]
					value = str2num( valueStr )
					
					if ( ( strlen( valueStr ) > 0 ) && ( numtype( value ) == 2 ) && !StringMatch( valueStr, "NaN" ) )
						DoAlert /T="NM Scale Error" 0, "Encountered bad number " + NMQuotes( valueStr )
						scaleLB[ row ][ col ] = ""
					endif
	
					break
			
				case "wave point-by-point":
				
					wName = scaleLB[ row ][ col ]
				
					if ( !WaveExists( $wName ) )
						DoAlert /T="NM Scale Error" 0, "Wave does not exist : " + NMQuotes( wName )
						scaleLB[ row ][ col ] = ""
					endif
					
					break
			
			endswitch
		
			break
			
	endswitch
	
	if ( StringMatch( dimLabel, "value" ) )
		zStartXCompute()
	endif
		
	return 0
	
End // NMScalePanelListBoxInput

//****************************************************************
//****************************************************************

Function /S NMScalePanelModeList()

	Variable align = NumVarOrDefault( NMMainDF + "ScaleAlign", 0 )
	
	if ( align )
		return "wave of values;"
	else
		return " ;value;wave of values;wave point-by-point;"
	endif

End // NMScalePanelModeList

//****************************************************************
//****************************************************************

Function /S NMScalePanelOpList( [ all ] )
	Variable all

	if ( all == 1 )
		return "x;*;/;+;-;=;"
	elseif ( all == 2 )
		return " ;x;/;+;-;=;"
	else
		return "x;/;+;-;=;"
	endif
	
End // NMScalePanelOpList

//****************************************************************
//****************************************************************

Function /S NMScalePanelWaveList()

	Variable numPoints, fcnt, icnt
	String optionsStr, wList, wList2, wName, subfolderList, subfolder, df, sdf

	String scaleMode = StrVarOrDefault( NMMainDF + "ScaleMode", "" )
	
	strswitch( scaleMode )
		
		case "value":
			return ""
			
		case "wave of values":
			numPoints = DimSize( $NMMainDF + "ScaleLB" , 0 )
			break
			
		case "wave point-by-point":
			numPoints = NMWaveSelectXstats( "numpnts", -1 )
			break
	
	endswitch
	
	if ( numPoints == 0 )
		return ""
	endif
	
	optionsStr = NMWaveListOptions( numPoints, 0 )
	
	wList = WaveList( "*", ";", optionsStr )
	
	df = CurrentNMFolder( 1 )
	subfolderList = FolderObjectList( df, 4 )
	
	for ( fcnt = 0 ; fcnt < ItemsInList( subfolderList ) ; fcnt += 1 )
		
		subfolder = StringFromList( fcnt, subfolderList )
		
		if ( strsearch( subfolder, NMPrefixSubfolderPrefix, 0 ) == 0 )
			continue
		endif
		
		sdf = df + subfolder + ":"
		
		wList2 = NMFolderWaveList( sdf, "*", ";", optionsStr, 1 )
		wList2 = ReplaceString( df, wList2, "" )
		
		if ( ItemsInList( wList2 ) > 0 )
			wList += "---;" + wList2
		endif
	
	endfor
	
	wName = StrVarOrDefault( NMMainDF + "ScaleWaveSelect", "" )
	
	if ( ( strlen( wName ) > 0 ) && ( WhichListItem( wName, wList ) == -1 ) )
		wList += "---;" + wName
	endif
	
	return " ;" + wList

End // NMScalePanelWaveList

//****************************************************************
//****************************************************************

Static Function zEditCells( on )
	Variable on // ( 0 ) off ( 1 ) on
	
	String wNameLB = NMMainDF + "ScaleLB"
	String wNameLBS = wNameLB + "select"
	
	Variable align = NumVarOrDefault( NMMainDF + "ScaleAlign", 0 )
	
	on = BinaryCheck( on )
	
	SetNMvar( NMMainDF + "ScalezEditCells", on )
	
	if ( !WaveExists( $wNameLBS ) )
		return 0
	endif

	Wave scaleLBS = $wNameLBS
			
	if ( on )
		if ( align )
			scaleLBS[][ %value ][ 0 ] = 3
			scaleLBS[][ %startx ][ 0 ] = 0
		else
			scaleLBS[][ %op ][ 0 ] = 3
			scaleLBS[][ %factor ][ 0 ] = 3
		endif
	else
		zPanelUpdate( reset = 1 )
	endif
	
End // zEditCells

//****************************************************************
//****************************************************************

Static Function zWaveLengthFormat( format )
	Variable format
	
	SetNMvar( NMMainDF + "ScalezWaveLengthFormat", BinaryCheck( format ) )
	
	zPanelUpdate( reset = 1 )
	
End // zWaveLengthFormat

//****************************************************************
//****************************************************************

Static Function zHistoryToggle()
	
	Variable history = NumVarOrDefault( NMMainDF + "ScaleLongHistory", 0 )
	
	SetNMvar( NMMainDF + "ScaleLongHistory", BinaryInvert( history ) )
	
	zPanelUpdate()
	
End // zHistoryToggle

//****************************************************************
//****************************************************************

Static Function zOperationSet( op )
	String op
	
	Variable icnt, numRows
	
	String opList = NMScalePanelOpList( all = 1 )
	
	if ( !WaveExists( $NMMainDF + "ScaleLB" ) )
		return NM2Error( 1, "ScaleLB", "" )
	endif
	
	Wave /T scaleLB = $NMMainDF + "ScaleLB"
	
	if ( WhichListItem( op, opList ) == -1 )
		op = "" // invalid op
	endif
	
	SetNMstr( NMMainDF + "ScaleOp", op )
	
	numRows = DimSize( scaleLB, 0 )
	
	for ( icnt = 0 ; icnt < numRows ; icnt += 1 )
	
		if ( strlen( scaleLB[ icnt ][ 1 ] ) > 0 )
			scaleLB[ icnt ][ %op ] = op
		else
			scaleLB[ icnt ][ %op ] = ""
		endif
		
	endfor
	
	return 0
	
End // zOperationSet

//****************************************************************
//****************************************************************

Static Function zScaleFactorSet( factor )
	String factor
	
	Variable align = NumVarOrDefault( NMMainDF + "ScaleAlign", 0 )
	
	if ( align )
		return 0 // not used
	endif
	
	Variable value = str2num( factor )
	
	if ( !WaveExists( $NMMainDF + "ScaleLB" ) )
		return NM2Error( 1, "ScaleLB", "" )
	endif
	
	Wave /T scaleLB = $NMMainDF + "ScaleLB"
			
	if ( ( strlen( factor ) > 0 ) && ( numtype( value ) == 2 ) && !StringMatch( factor, "NaN" ) )
		factor = "" // invalid number
	endif
	
	SetNMstr( NMMainDF + "ScaleFactor", factor )
	
	scaleLB[][ %factor ] = factor
	
	return 0
	
End // zScaleFactorSet

//****************************************************************
//****************************************************************

Static Function zScaleByWaveSet( wName )
	String wName
	
	Variable ccnt, wcnt, numRows
	String df, scaleMode, wNameFullPath, statsWName, sName
	String parent, strValue, formatStr = "%.8f"
	
	Variable align = NumVarOrDefault( NMMainDF + "ScaleAlign", 0 )
	
	if ( align )
		return zAlignByWaveSet( wName )
	endif
	
	if ( !WaveExists( $NMMainDF + "ScaleLB" ) )
		return NM2Error( 1, "ScaleLB", "" )
	endif
	
	Wave /T scaleLB = $NMMainDF + "ScaleLB"
	
	numRows = DimSize( scaleLB , 0 )
	
	df = CurrentNMFolder( 1 )
	wNameFullPath = CheckNMWavePath( df, wName )
	
	if ( !WaveExists( $wNameFullPath ) )
		scaleLB[][ %factor ] = ""
		return 0
	endif
	
	SetNMstr( NMMainDF + "ScaleWaveSelect", wName )
	
	scaleMode = StrVarOrDefault( NMMainDF + "ScaleMode", "" )
	
	strswitch( scaleMode )
	
		case "wave of values":
		
			if ( numpnts( $wNameFullPath ) != numRows )
				scaleLB[][ %factor ] = ""
				return 0
			endif
		
			Wave wtemp = $wNameFullPath
			
			statsWName = NMNoteStrByKey( wNameFullPath, "Stats Wave Names" )
	
			if ( WaveExists( $statsWName ) && ( WaveType( $statsWName, 1 ) == 2 ) )
			
				Wave /T stemp = $statsWName
				
				parent = ParseFilePath( 1, statsWName, ":", 0, 2 )
			
				for ( wcnt = 0 ; wcnt < numRows ; wcnt += 1 )
				
					if ( strlen( scaleLB[ wcnt ][ 1 ] ) == 0 )
						scaleLB[ wcnt ][ %factor ] = ""
						scaleLB[ wcnt ][ %source ] = ""
						continue
					endif
				
					sprintf strValue, formatStr, wtemp[ wcnt ]
					
					scaleLB[ wcnt ][ %factor ] = strValue
					
					sName = stemp[ wcnt ]
					
					if ( stringMatch( parent, df ) )
						scaleLB[ wcnt ][ %source ] = sName
					else
						scaleLB[ wcnt ][ %source ] = parent + sName
					endif
					
				endfor
			
			else
			
				for ( wcnt = 0 ; wcnt < numpnts( wtemp ) ; wcnt += 1 )
					sprintf strValue, formatStr, wtemp[ wcnt ]
					scaleLB[ wcnt ][ %factor ] = strValue
				endfor
				
			endif
			
			break
			
		case "wave point-by-point":
			scaleLB[][ %factor ] = wName
			scaleLB[][ %source ] = ""
			break
			
	endswitch
	
	zListBoxCheck()
	
	return 0
	
End // zScaleByWaveSet

//****************************************************************
//****************************************************************

Static Function zAlignByWaveSet( wName )
	String wName
	
	Variable ccnt, wcnt, numRows
	String df, scaleMode, wNameFullPath, statsWName, sName
	String parent, strValue, formatStr = "%.8f"
	
	if ( !WaveExists( $NMMainDF + "ScaleLB" ) )
		return NM2Error( 1, "ScaleLB", "" )
	endif
	
	Wave /T scaleLB = $NMMainDF + "ScaleLB"
	
	numRows = DimSize( scaleLB , 0 )
	
	df = CurrentNMFolder( 1 )
	wNameFullPath = CheckNMWavePath( df, wName )
	
	if ( !WaveExists( $wNameFullPath ) )
		scaleLB[][ %value ] = ""
		return 0
	endif
	
	SetNMstr( NMMainDF + "ScaleWaveSelect", wName )
	
	scaleMode = StrVarOrDefault( NMMainDF + "ScaleMode", "" )
	
	strswitch( scaleMode )
	
		case "wave of values":
		
			if ( numpnts( $wNameFullPath ) != numRows )
				scaleLB[][ %value ] = ""
				return 0
			endif
		
			Wave wtemp = $wNameFullPath
			
			statsWName = NMNoteStrByKey( wNameFullPath, "Stats Wave Names" )
	
			if ( WaveExists( $statsWName ) && ( WaveType( $statsWName, 1 ) == 2 ) )
			
				Wave /T stemp = $statsWName
				
				parent = ParseFilePath( 1, statsWName, ":", 0, 2 )
			
				for ( wcnt = 0 ; wcnt < numRows ; wcnt += 1 )
				
					if ( strlen( scaleLB[ wcnt ][ 1 ] ) == 0 )
						scaleLB[ wcnt ][ %value ] = ""
						scaleLB[ wcnt ][ %source ] = ""
						continue
					endif
				
					sprintf strValue, formatStr, wtemp[ wcnt ]
					
					scaleLB[ wcnt ][ %value ] = strValue
					
					sName = stemp[ wcnt ]
					
					if ( stringMatch( parent, df ) )
						scaleLB[ wcnt ][ %source ] = sName
					else
						scaleLB[ wcnt ][ %source ] = parent + sName
					endif
					
				endfor
			
			else
			
				for ( wcnt = 0 ; wcnt < numpnts( wtemp ) ; wcnt += 1 )
					sprintf strValue, formatStr, wtemp[ wcnt ]
					scaleLB[ wcnt ][ %value ] = strValue
				endfor
				
			endif
			
			break
			
		case "wave point-by-point":
			scaleLB[][ %value ] = wName
			scaleLB[][ %source ] = ""
			break
			
	endswitch
	
	zListBoxCheck()
	zStartXCompute()
	
	return 0
	
End // zAlignByWaveSet

//****************************************************************
//****************************************************************

Static Function zStartXCompute()
	
	Variable wcnt, startx, alignAt, numRows
	String df, wName, wNameFullPath, strValue
	String formatStr = "%.8f"

	String alignAtSelect = StrVarOrDefault( NMMainDF + "ScaleAlignAtSelect", "zero" )
	
	df = CurrentNMFolder( 1 )
	wName = StrVarOrDefault( NMMainDF + "ScaleWaveSelect", "" )
	
	if ( strlen( wName ) == 0 )
		return 0
	endif
	
	wNameFullPath = CheckNMWavePath( df, wName )

	if ( !WaveExists( $wNameFullPath ) )
		return 0
	endif
		
	alignAt = NMAlignAtValue( alignAtSelect, wNameFullPath )
	
	Wave /T scaleLB = $NMMainDF + "ScaleLB"
	
	numRows = DimSize( scaleLB , 0 )
	
	for ( wcnt = 0 ; wcnt < numRows ; wcnt += 1 )
		startx = alignAt - str2num( scaleLB[ wcnt ][ %value ] )
		sprintf strValue, formatStr, startx
		scaleLB[ wcnt ][ %startx ] = strValue
	endfor
	
End // zStartXCompute

//****************************************************************
//****************************************************************

Static Function /S zWaveBrowser()

	Variable numPoints
	String promptStr, wName

	String scaleMode = StrVarOrDefault( NMMainDF + "ScaleMode", "" )
	
	if ( !WaveExists( $NMMainDF + "ScaleLB" ) )
		return ""
	endif
	
	strswitch( scaleMode )
		
		case "value":
			return ""
			
		case "wave of values":
			numPoints = DimSize( $NMMainDF + "ScaleLB" , 0 )
			promptStr = "choose wave of scale values (" + num2istr( numPoints ) + " points)"
			break
			
		case "wave point-by-point":
			numPoints = NMWaveSelectXstats( "numpnts", -1 )
			promptStr = "choose wave to scale point-by-point (" + num2istr( numPoints ) + " points)"
			break
	
	endswitch
	
	if ( ( numtype( numPoints ) > 0 ) || ( numPoints == 0 ) )
		return ""
	endif
	
	wName = NMWaveBrowser( promptStr, numWavesLimit = 1, numPoints = numPoints, noText = 1, noSelect = 1 )
			
	if ( !WaveExists( $wName ) )
		return ""
	endif
	
	SetNMstr( NMMainDF + "ScaleWaveSelect", wName )
	
	zScaleByWaveSet( wName )
	zPanelUpdate( browserSelect = 1 )

	return wName

End // zWaveBrowser

//****************************************************************
//****************************************************************

Static Function /S zPanelExecute()

	Variable numRows, numCols, numChans, ccnt, icnt, xbgn, xend
	Variable factor, zWaveLengthFormat, success, failure, history2
	Variable w0, w1, w2, w3, w4, w5, w6
	String wName, xWave, matrixName, successStr, successList = ""
	String opList, op, factorStr, waveOfFactors, wavePntByPnt, df, wNameFullPath
	
	Variable align = NumVarOrDefault( NMMainDF + "ScaleAlign", 0 )
	
	if ( align )
		return zPanelExecuteAlign()
	endif
	
	Variable zEditCells = NumVarOrDefault( NMMainDF + "ScalezEditCells", 0 )
	Variable history = NumVarOrDefault( NMMainDF + "ScaleLongHistory", 0 )
	String scaleMode = StrVarOrDefault( NMMainDF + "ScaleMode", "" )
	
	Variable extraColumns = 4
	
	history2 = history + 1

	if ( !WaveExists( $NMMainDF + "ScaleLB" ) )
		return ""
	endif
	
	Wave /T scaleLB = $NMMainDF + "ScaleLB"
	Wave scaleLBS = $NMMainDF + "ScaleLBselect"
	
	numRows = DimSize( scaleLB , 0 )
	numCols = DimSize( scaleLB , 1 )
	
	numChans = numCols - extraColumns
	
	if ( numChans < 1 )
		return ""
	endif
	
	opList = NMScalePanelOpList( all = 1 )
	
	for ( icnt = 0 ; icnt < numRows ; icnt += 1 )
	
		op = scaleLB[ icnt ][ %op ]
		factorStr = scaleLB[ icnt ][ %factor ]
	
		if ( ( WhichListItem( op, opList ) >= 0 ) && ( strlen( factorStr ) > 0 ) )
			success = 1
			break
		endif
		
	endfor
	
	if ( !success )
		DoAlert /T="NM Scale" 0, "Detected no operations to execute."
		return ""
	endif
	
	xbgn = NumVarOrDefault( NMMainDF + "ScaleXbgn", -inf )
	xend = NumVarOrDefault( NMMainDF + "ScaleXend", -inf )
	xWave = NMXwave()
	
	if ( zEditCells )
	
		matrixName = NMMainDF + "ScaleMatrix"
	
		NMMatrixArithmeticMake( matrixName, numRows )
		
		if ( !WaveExists( $matrixName ) )
			return ""
		endif
		
		Wave /T matrix = $matrixName
		
		for ( ccnt = 0 ; ccnt < numChans ; ccnt += 1 )
		
			for ( icnt = 0 ; icnt < numRows ; icnt += 1 )
			
				wName = scaleLB[ icnt ][ ccnt + 1 ]
				op = scaleLB[ icnt ][ %op ]
				factorStr = scaleLB[ icnt ][ %factor ]
				
				if ( ( strlen( wName ) == 0 ) || ( strlen( op ) == 0 ) || ( strlen( factorStr ) == 0 ) )
					continue
				endif
				
				matrix[ icnt ][ %wName ] = wName
				matrix[ icnt ][ %op ] = scaleLB[ icnt ][ %op ]
				matrix[ icnt ][ %factor ] = scaleLB[ icnt ][ %factor ]
				
				scaleLBS[ icnt ][][ %foreColors ] = 0 // black
				
			endfor
			
			successList += NMMatrixArithmetic( NMMainDF + "ScaleMatrix", xbgn = xbgn, xend = xend, xWave = xWave, history = history )
			
			for ( icnt = 0 ; icnt < numRows ; icnt += 1 )
		
				successStr = matrix[ icnt ][ %success ]
				success = str2num( successStr )
				
				if ( scaleLBS[ icnt ][0][ %foreColors ] == 1 )
					continue // keep red
				endif
				
				if ( success )
					scaleLBS[ icnt ][][ %foreColors ] = 2 // green
				else
					scaleLBS[ icnt ][][ %foreColors ] = 1 // red
					failure = 1
				endif
				
			endfor
			
		endfor
	
		KillWaves /Z $matrixName
	
	else
	
		op = StrVarOrDefault( NMMainDF + "ScaleOp", "" )
		
		if ( WhichListItem( op, opList ) == -1 )
			return NM2ErrorStr( 90, "No operation", "" )
		endif
	
		strswitch( scaleMode )
		
			case "value":
			
				factorStr = StrVarOrDefault( NMMainDF + "ScaleFactor", "" )
				
				if ( strlen( factorStr ) == 0 )
					return NM2ErrorStr( 21, "factor", "" )
				endif
				
				factor = str2num( factorStr )
				
				if ( ( numtype( factor ) == 2 ) && !StringMatch( factorStr, "NaN" ) )
					return NM2ErrorStr( 21, "factor", "" )
				endif
				
				successList = NMMainScale( op = op, factor = factor, xbgn = xbgn, xend = xend, history = 1, printToHistory = history2 )
				
				break
				
			case "wave of values":
			
				waveOfFactors = StrVarOrDefault( NMMainDF + "ScaleWaveSelect", "" )
				
				df = CurrentNMFolder( 1 )
				wNameFullPath = CheckNMWavePath( df, waveOfFactors )
				
				if ( NMUtilityWaveTest( wNameFullPath ) != 0 )
					return NM2ErrorStr( 1, "waveOfFactors", "" )
				endif
				
				zWaveLengthFormat = NumVarOrDefault( NMMainDF + "ScalezWaveLengthFormat", 1 )
				
				if ( zWaveLengthFormat == 0 )
					successList = NMMainScale( waveSelectList = "All+", op = op, waveOfFactors = waveOfFactors, xbgn = xbgn, xend = xend, history = 1, printToHistory = history2 )
				else
					successList = NMMainScale( op = op, waveOfFactors = waveOfFactors, xbgn = xbgn, xend = xend, history = 1, printToHistory = history2 )
				endif
				
				break
				
			case "wave point-by-point":
			
				wavePntByPnt = StrVarOrDefault( NMMainDF + "ScaleWaveSelect", "" )
				
				df = CurrentNMFolder( 1 )
				wNameFullPath = CheckNMWavePath( df, wavePntByPnt )
			
				if ( NMUtilityWaveTest( wNameFullPath ) != 0 )
					return NM2ErrorStr( 1, "wavePntByPnt", "" )
				endif
				
				successList = NMMainScale( op = op, wavePntByPnt = wavePntByPnt, xbgn = xbgn, xend = xend, history = 1, printToHistory = history2 )
				
				break
				
		endswitch
	
	endif
	
	DoWindow /K $NMScalePanelName
	
	return successList

End // zPanelExecute

//****************************************************************
//****************************************************************

Static Function /S zPanelExecuteAlign()

	Variable icnt, numRows, numCols, numChans, success
	Variable zWaveLengthFormat, alignAt, history2
	String df, valueStr, waveOfFactors, wNameFullPath, alignAtSelect
	String successList = ""

	Variable zEditCells = NumVarOrDefault( NMMainDF + "ScalezEditCells", 0 )
	Variable longHistory = NumVarOrDefault( NMMainDF + "ScaleLongHistory", 0 )
	String scaleMode = StrVarOrDefault( NMMainDF + "ScaleMode", "" )
	
	Variable extraColumns = 4

	if ( !WaveExists( $NMMainDF + "ScaleLB" ) )
		return ""
	endif
	
	Wave /T scaleLB = $NMMainDF + "ScaleLB"
	Wave scaleLBS = $NMMainDF + "ScaleLBselect"
	
	numRows = DimSize( scaleLB , 0 )
	numCols = DimSize( scaleLB , 1 )
	
	numChans = numCols - extraColumns
	
	if ( numChans < 1 )
		return ""
	endif
	
	history2 = longHistory + 1
	
	for ( icnt = 0 ; icnt < numRows ; icnt += 1 )
	
		valueStr = scaleLB[ icnt ][ %value ]
	
		if ( strlen( valueStr ) > 0 )
			success = 1
			break
		endif
		
	endfor
	
	if ( !success )
		DoAlert /T="NM Align" 0, "Detected no alignments to execute."
		return ""
	endif
	
	zWaveLengthFormat = NumVarOrDefault( NMMainDF + "ScalezWaveLengthFormat", 1 )
	
	alignAtSelect = StrVarOrDefault( NMMainDF + "ScaleAlignAtSelect", "zero" )
	
	if ( zEditCells )
	
		wNameFullPath = "U_AlignmentValues"
	
		Make /O/N=( numRows ) $wNameFullPath = NaN
		
		Wave wtemp = $wNameFullPath
	
		for ( icnt = 0 ; icnt < numRows ; icnt += 1 )
			wtemp[ icnt ] = str2num( scaleLB[ icnt ][ %value ] )
		endfor
		
		alignAt = NMAlignAtValue( alignAtSelect, wNameFullPath )
		
		if ( zWaveLengthFormat == 0 )
			successList = NMMainAlign( waveSelectList = "All+", waveOfAlignValues = wNameFullPath, alignAt = alignAt, printToHistory = history2, history = 1 )
		else
			successList = NMMainAlign( waveOfAlignValues = wNameFullPath, alignAt = alignAt, printToHistory = history2, history = 1 )
		endif
		
		KillWaves /Z $wNameFullPath
	
	else
	
		waveOfFactors = StrVarOrDefault( NMMainDF + "ScaleWaveSelect", "" )
				
		df = CurrentNMFolder( 1 )
		wNameFullPath = CheckNMWavePath( df, waveOfFactors )
		
		if ( NMUtilityWaveTest( wNameFullPath ) != 0 )
			return NM2ErrorStr( 1, "waveOfFactors", "" )
		endif
		
		alignAt = NMAlignAtValue( alignAtSelect, wNameFullPath )
		
		if ( zWaveLengthFormat == 0 )
			successList = NMMainAlign( waveSelectList = "All+", waveOfAlignValues = waveOfFactors, alignAt = alignAt, printToHistory = history2, history = 1 )
		else
			successList = NMMainAlign( waveOfAlignValues = waveOfFactors, alignAt = alignAt, printToHistory = history2, history = 1 )
		endif
	
	endif
	
	DoWindow /K $NMScalePanelName
	
	return successList

End // zPanelExecuteAlign

//****************************************************************
//****************************************************************
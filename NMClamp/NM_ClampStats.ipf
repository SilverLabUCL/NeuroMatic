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
//
//****************************************************************
//****************************************************************

Function /S NMStimStatsDF()

	String sdf = StimDF()
	
	if ( strlen( sdf ) > 0 )
		return sdf + "Stats:"
	else
		return ""
	endif

End // NMStimStatsDF

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimStatsOn()

	Variable on = NumVarOrDefault( NMStimStatsDF()+"StatsOn", 0 )
	
	return BinaryCheck( on )
	
End // NMStimStatsOn

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimStatsOnSet( on )
	Variable on // ( 0 ) off ( 1 ) on
	
	String ssdf = NMStimStatsDF()
	
	on = BinaryCheck( on )
	
	if ( ( on == 1 ) && ( DataFolderExists( ssdf ) == 0 ) )
		NewDataFolder $RemoveEnding( ssdf, ":" )
		SetNMvar( ssdf + "StatsOn", 1 )
		NMStimStatsUpdate()
	endif
	
	if ( DataFolderExists( ssdf ) == 1 )
		SetNMvar( ssdf + "StatsOn", on )
	endif
	
	ClampStats( on )
	
	return on

End // NMStimStatsOnSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimStatsUpdateAsk()
	
	if ( StatsTimeStampCompare( NMStatsDF, NMStimStatsDF() ) == 0 )
	
		DoAlert 1, "Your Stats configuration has changed. Do you want to update the current stimulus configuration to reflect these changes?"
		
		if ( V_flag == 1 )
			NMStimStatsUpdate()
			return 1
		endif
	
	endif
	
	return 0

End // NMStimStatsUpdateAsk

//****************************************************************
//****************************************************************
//****************************************************************

Function NMStimStatsUpdate() // save Stats waves to stim folder
	
	String stdf = NMStatsDF
	String ssdf = NMStimStatsDF()
	
	if ( ( NMStimStatsOn() == 0 ) || ( DataFolderExists( ssdf ) == 0 ) )
		return 0
	endif
	
	StatsWavesCopy( stdf, ssdf )
	SetNMvar( ssdf + "AmpNV", NumVarOrDefault( stdf+"AmpNV", 0 ) ) // copy current stats window
	
End // NMStimStatsUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsRetrieveFromStim() // retrieve Stats waves from stim folder
	String sdf // stim data folder
	
	String stdf = NMStatsDF
	String ssdf = NMStimStatsDF()
	
	if ( ( NMStimStatsOn() == 0 ) || ( DataFolderExists( stdf ) == 0 ) )
		return 0
	endif
	
	StatsWavesCopy( ssdf, stdf )
	
	if ( ( NMNumChannels() > 0 ) && ( WaveExists( $( stdf+"ChanSelect" ) ) == 1 ) )
	
		Wave chan = $( stdf+"ChanSelect" )
		
		if ( 0 < numpnts( chan ) )
			NMChanSelect( num2istr( chan[ 0 ] ), update = 0 )
		endif
		
	endif
	
	SetNMvar( stdf+"AmpNV", NumVarOrDefault( ssdf + "AmpNV", 0 ) )
		
	return 0

End // ClampStatsRetrieveFromStim

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStats( enable )
	Variable enable // ( 0 ) no ( 1 ) yes
	
	if ( DataFolderExists( StimDF() ) == 0 )
		return -1
	endif
	
	if ( enable == 1 )
		NMChanGraphUpdate()
	endif
	
	StatsDisplay( -1, enable )
	
	return 0
	
End // ClampStats

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsInit()

	if ( NMStimStatsOn() == 1 )
	
		if ( NMStimStatsUpdateAsk() == 0 )
			ClampStatsRetrieveFromStim() // get Stats from new stim
		endif
		
		StatsDisplayClear()
		ClampStatsDisplaySavePositions()
		NMChanSelect( num2istr( StatsChanSelect( -1 ) ), update = 0 )
		
	else
	
		ClampStatsRemoveWavesAll( 1 )
		
	endif
	
	ClampStatsDisplaySetPositions()

End // ClampStatsInit()

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsStart()

	String subfolder
	
	ClampStatsDisplays( 0 ) // clear display
	ClampStatsRemoveWavesAll( 1 ) // kill waves
	
	if ( NMStimStatsOn() == 1 )
		subfolder = CurrentNMStatsSubfolder()
		CheckNMSubfolder( subfolder )
		ClampStatsKill()
		StatsWavesMake( subfolder, StatsChanSelect( -1 ), "" )
		ClampStatsDisplays( 1 )
	endif

End // ClampStatsStart

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsCompute( mode, currentWave, numWaves [ updateGraphs ] )
	Variable mode // ( 0 ) preview ( 1 ) record
	Variable currentWave
	Variable numWaves
	Variable updateGraphs
	
	Variable chan
	String wName = ""

	if ( NMStimStatsOn() == 0 )
		return 0
	endif
	
	if ( ParamIsDefault( updateGraphs ) )
		updateGraphs = 1
	endif
	
	chan = StatsChanSelect( -1 )
	
	if ( mode == 0 )
		wName = GetWaveName( "default", chan, 0 )
	else
		wName = GetWaveName( "default", chan, currentWave )
	endif
	
	StatsCompute( wName, chan, currentWave, -1, 1, 1 )
	
	if ( updateGraphs )
		ClampStatsDisplaysUpdate( currentWave, numWaves )
	endif

End // ClampStatsCompute()

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsFinish( currentWave )
	Variable currentWave
	
	if ( NMStimStatsOn() == 0 )
		return 0
	endif
	
	ClampStatsResize( CurrentWave + 1 )
	
End // ClampStatsFinish

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsKill()
	
	Variable icnt
	String wname
	
	String folder = CurrentNMStatsSubfolder()
	
	String wlist = NMFolderWaveList( folder, "ST_*", ";", "", 1 )
	
	for ( icnt = 0; icnt < ItemsInList( wlist ); icnt += 1 )
		wname = StringFromList( icnt, wlist )
		KillWaves /Z $wname
	endfor

End // ClampStatsKill

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsResize( npnts )
	Variable npnts
	
	Variable icnt
	String wname
	
	String folder = CurrentNMStatsSubfolder()
	
	String wlist = NMFolderWaveList( folder, "ST_*", ";", "", 1 )
	
	for ( icnt = 0; icnt < ItemsInList( wlist ); icnt += 1 )
		wname = StringFromList( icnt, wlist )
		Redimension /N=( npnts ) $wname
	endfor

End // ClampStatsResize

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ClampStatsDisplayName( select )
	String select

	return "ClampStats" + select

End // ClampStatsDisplayAmpName

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsDisplays( enable )
	Variable enable
	
	ClampStatsDisplayClear( "Amp" )
	ClampStatsDisplayClear( "Tau" )
	
	if ( ( NMStimStatsOn() == 0 ) || ( enable == 0 ) )
		return 0
	endif
	
	ClampStatsDisplay( enable, "Amp" )
	ClampStatsDisplay( enable, "Tau" )

End // ClampStatsDisplays

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsDisplay( enable, select )
	Variable enable
	String select // "Amp" or "Tau"
	
	Variable red, green, blue, wcnt, win, lastwin = -1, acnt = -1, plottedXY, y1, y2
	String wlist, wname, amp, amp2, xyt = "", tbox = "", yaxis = ""
	
	String folder = CurrentNMStatsSubfolder()
	
	String gName = ClampStatsDisplayName( select )
	
	String stdf = NMStatsDF, ssdf = NMStimStatsDF()
	
	Variable numWaves = NumVarOrDefault( "NumWaves", 0 )
	
	Variable bsln = NumVarOrDefault( ssdf + "StatsDisplay" + select + "Bsln", 1 )
	Variable multipleY = NumVarOrDefault( ssdf + "StatsDisplay" + select + "MultipleY", 0 )
	Variable autoscale = NumVarOrDefault( ssdf + "StatsDisplay" + select + "AutoScale", 1 )
	
	if ( WaveExists( $( stdf+"AmpSlct" ) ) == 0 )
		return 0
	endif
	
	Wave /T AmpSlct = $( stdf+"AmpSlct" )
	
	wlist = NMFolderWaveList( folder, "ST_*",";","TEXT:0", 0 )
	
	if ( ItemsInList( wlist ) == 0 )
		return 0 // nothing to plot
	endif
	
	if ( StringMatch( select, "Tau" ) == 1 )
		if ( ( StringMatch( wlist, "*ST_RiseT*" ) == 0 ) && ( StringMatch( wlist, "*ST_DcayT*" ) == 0 ) && ( StringMatch( wlist, "*ST_FwhmT*" ) == 0 ) )
			return 0 // nothing to plot
		endif
	endif
	
	if ( WinType( gName ) == 0 )
	
		Make /O/N=0 CT_DummyWave
		DoWindow /K $gName
		Display /K=(NMK())/N=$gName/W=( 0,0,200,100 ) CT_DummyWave
		RemoveFromGraph /Z CT_DummyWave
		KillWaves /Z CT_DummyWave
		ClampStatsDisplaySetPosition( select )
		
		strswitch( select )
			case "Amp": 
				DoWindow /T $gName, "NM Online Stats"
				PopupMenu SDMenu, pos={0,0}, size={15,0}, bodyWidth= 20, mode=1, value=" ;Baseline;Multiple Y;AutoScale;", proc=ClampStatsDisplayAmpPopup, win=$gName
				break
			case "Tau":
				DoWindow /T $gName, "NM Online Stats : Time Constants"
				PopupMenu SDMenu, pos={0,0}, size={15,0}, bodyWidth= 20, mode=1, value=" ;Multiple Y;AutoScale;", proc=ClampStatsDisplayTauPopup, win=$gName
				break
		endswitch
		
	else
	
		DoWindow /F $gName
		
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wlist ); wcnt += 1 )
	
		wname = StringFromList( wcnt, wlist )
		win = StatsWinNum( wname )
		
		if ( ( win < 0 ) || ( win >= numpnts( AmpSlct ) ) )
			continue // window number not recognized
		endif
		
		amp = AmpSlct[ win ]
		xyt = ""
		
		strswitch( amp )
		
			case "Off":
				continue
		
			case "Onset":
			case "Level":
			case "Level+":
			case "Level-":

				if ( StringMatch( select, "Amp" ) == 1 )
					xyt = "X" + num2istr( win ) + "_"
					break
				endif
				
				continue
				
			case "RiseTime+":
			case "RiseTime-":
			case "DecayTime+":
			case "DecayTime-":
			case "FWHM+":
			case "FWHM-":
				
				if ( StringMatch( select, "Tau" ) == 1 )
					xyt = "T" + num2istr( win ) + "_"
					bsln = 0 // no baseline to plot
					break
				endif
				
				continue // time waves
				
			default:
				
				if ( StringMatch( select, "Amp" ) == 1 )
					xyt = "Y" + num2istr( win ) + "_"
					break
				endif
				
				continue
				
		endswitch
		
		if ( win != lastwin )
		
			if ( acnt == 0 )
				ModifyGraph /W=$gName axRGB(left) = (red,green,blue)
			endif
			
			acnt += 1
			lastwin = win
			plottedXY = 0
			
		endif
		
		yaxis = "StatsYaxis" + num2istr( acnt )
		red = ClampStatsColor( acnt, "r" )
		green = ClampStatsColor( acnt, "g" )
		blue = ClampStatsColor( acnt, "b" )
		
		if ( ( StringMatch( wname[ 0, 6 ], "ST_Bsln" ) == 1 ) )
		
			if ( bsln == 0 )
				continue
			endif
			
			if ( ( acnt > 0 ) && ( multipleY == 1 ) )
				AppendToGraph /W=$gName /R=$yaxis $folder+wname
			else
				AppendToGraph /W=$gName $folder+wname
			endif
			
			ModifyGraph /W=$gName rgb( $wname ) = (red,green,blue)
			ModifyGraph /W=$gName marker( $wname ) = 8 // ClampStatsMarker( acnt )
			
			tbox += "    bsln" + num2istr( win ) + " \\s(" + wname + ")"
			
		else
		
			if ( plottedXY == 1 )
				continue
			endif
			
			if ( strsearch( wname, xyt, 0 ) < 0 )
				continue
			endif

			if ( ( acnt > 0 ) && ( multipleY == 1 ) )
				AppendToGraph /W=$gName /R=$yaxis $folder+wname
				ModifyGraph /W=$gName freePos($yaxis) = {0.1*(acnt-1),kwFraction}
				ModifyGraph /W=$gName axRGB($yaxis) = (red,green,blue)
			else
				AppendToGraph /W=$gName $folder+wname
				ModifyGraph /W=$gName axRGB(left) = (0,0,0)
			endif
			
			ModifyGraph /W=$gName rgb( $wname ) = (red,green,blue)
			ModifyGraph /W=$gName marker( $wname ) = 19 // ClampStatsMarker( acnt )
			
			amp2 = amp
		
			y1 = strlen(amp2) -1
			y2 = y1
			
			if ( StringMatch( amp2[y1,y2], "-" ) == 1 )
				amp2 = amp2[0,y2-1]
			endif
			
			if ( StringMatch( amp2[y1,y2], "+" ) == 1 )
				amp2 = amp2[0,y2-1]
			endif
			
			tbox += NMCR + amp2 + num2istr( win ) + " \\s(" + wname + ")"
			
			plottedXY = 1
		
		endif
		
	endfor
	
	ModifyGraph /W=$gName mode=4, msize=4, standoff=0
	
	if ( ( acnt > 0 ) && ( multipleY == 1 ) )
		ModifyGraph /W=$gName margin(right) = 50
	else
		ModifyGraph /W=$gName margin(right) = 0
	endif
	
	if ( strlen( tbox ) > 0 )
	
		tbox = tbox[ 1, inf ] // remove first carriage return
		
		TextBox /W=$gName/E/C/N=text0/A=MT/W=$gName tbox
		TextBox /W=$gName/C/N=text0/X=0.00/Y=0.00/W=$gName
		
		Label /W=$gName bottom StrVarOrDefault( "WavePrefix", "Wave" )
		
		if ( numWaves > 0 )
			SetAxis /W=$gName bottom 0,( min( numWaves,10 ) )
		endif
	
		if ( autoscale == 1 )
		
			SetAxis /A/W=$gName/Z
	
		else
		
			y1 = NumVarOrDefault( ssdf + "CS" + select[0,0] + "_Ymin", 0 )
			y2 = NumVarOrDefault( ssdf + "CS" + select[0,0] + "_Ymax", 100 )
			
			SetAxis /W=$gName/Z left y1, y2
			
			for ( acnt = 0 ; acnt < 10 ; acnt += 1 )
			
				yaxis = "StatsYaxis" + num2istr( acnt )
				
				y1 = NumVarOrDefault( ssdf + "CS" + select[0,0] + num2istr( acnt ) + "_Ymin", 0 )
				y2 = NumVarOrDefault( ssdf + "CS" + select[0,0] + num2istr( acnt ) + "_Ymax", 100 )
				
				SetAxis /W=$gName/Z $yaxis y1, y2
				
			endfor
			
		endif
	
	endif
	
	//wlist = NMFolderWaveList( folder, "*", ";", "WIN:"+gName, 0 )
	
	ClampStatsDisplaySetPosition( select )

End // ClampStatsDisplay

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsDisplayClear( select )
	String select // "Amp" or "Tau"

	Variable wcnt
	String wlist, wname
	
	String gName = ClampStatsDisplayName( select )
	String folder = CurrentNMStatsSubfolder()
	
	if ( WinType( gName ) == 1 )
		
		wlist = TraceNameList( gName, ";", 1 )
		
		for ( wcnt = 0; wcnt < ItemsInList( wlist ); wcnt += 1 )
			wname = StringFromList( wcnt, wlist )
			RemoveFromGraph /Z/W=$gName $wname
		endfor
		
		TextBox /K/N=text0/W=$gName
	
	endif
		
End // ClampStatsDisplayClear

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsDisplaysUpdate( currentWave, numwaves ) // resize stats display x-scale
	Variable currentWave
	Variable numwaves
	
	ClampStatsDisplayUpdate( "Amp", currentWave, numwaves )
	ClampStatsDisplayUpdate( "Tau", currentWave, numwaves )
	
End // ClampStatsDisplaysUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsDisplayUpdate( select, currentWave, numwaves ) // resize stats display x-scale
	String select // "Amp" or "Tau"
	Variable currentWave
	Variable numwaves
	
	String gname = ClampStatsDisplayName( select )
	
	Variable inc = 10
	Variable num = inc * ( 1 + floor( currentWave / inc ) )
	
	num = min( numwaves, num )

	if ( WinType( gname ) == 1 )
		SetAxis /Z/W=$gname bottom 0, num
	endif
	
End // ClampStatsDisplayUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsDisplaySavePositions()

	ClampStatsDisplaySavePosition( "Amp" )
	ClampStatsDisplaySavePosition( "Tau" )

End // ClampStatsDisplaySavePositions

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsDisplaySavePosition( select )
	String select // "Amp" or "Tau"
	
	Variable icnt
	String yaxis
	
	String gname = ClampStatsDisplayName( select )
	String ssdf = NMStimStatsDF()
	
	if ( ( WinType( gname ) == 1 ) && ( DataFolderExists( ssdf ) == 1 ) )
	
		GetWindow $gname wsize
		
		if ( ( V_right > V_left ) && ( V_top < V_bottom ) )
			SetNMvar( ssdf + "CS" + select[0,0] + "_X0", V_left )
			SetNMvar( ssdf + "CS" + select[0,0] + "_Y0", V_top )
			SetNMvar( ssdf + "CS" + select[0,0] + "_X1", V_right )
			SetNMvar( ssdf + "CS" + select[0,0] + "_Y1", V_bottom )
		endif
		
		GetAxis /Q/W=$gName left
		
		if ( V_flag == 0 )
			SetNMvar( ssdf + "CS" + select[0,0] + "_Ymin", V_min)
			SetNMvar( ssdf + "CS" + select[0,0] + "_Ymax", V_max)
		endif
		
		for ( icnt = 0 ; icnt < 10 ; icnt += 1 )
		
			yaxis = "StatsYaxis" + num2istr( icnt )
			GetAxis /Q/W=$gName $yaxis
			
			if ( V_flag == 0 )
				SetNMvar( ssdf + "CS" + select[0,0] + num2istr( icnt ) + "_Ymin", V_min)
				SetNMvar( ssdf + "CS" + select[0,0] + num2istr( icnt ) + "_Ymax", V_max)
			endif
			
		endfor
		
	else
	
		if ( exists( ssdf + "CS" + select[0,0] + "_X0" ) == 2 )
			KillVariables /Z $( ssdf + "CS" + select[0,0] + "_X0" )
			KillVariables /Z $( ssdf + "CS" + select[0,0] + "_Y0" )
			KillVariables /Z $( ssdf + "CS" + select[0,0] + "_X1" )
			KillVariables /Z $( ssdf + "CS" + select[0,0] + "_Y1" )
		endif
		
	endif

End // ClampStatsDisplaySavePosition

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsDisplaySetPositions()

	ClampStatsDisplaySetPosition( "Amp" )
	ClampStatsDisplaySetPosition( "Tau" )

End // ClampStatsDisplaySetPositions

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsDisplaySetPosition( select )
	String select // "Amp" or "Tau"
	
	Variable x0, y0, x1, y1, xshift
	
	Variable xpoints = NMScreenPointsX()
	Variable ypoints = NMScreenPointsY()

	String gname = ClampStatsDisplayName( select )
	String ssdf =NMStimStatsDF()
	
	Variable statsOn = NMStimStatsOn()
	
	if ( StringMatch( select, "Tau" ) == 1 )
		xshift = 270
	endif
	
	if ( WinType( gname ) == 0 )
		return 0
	endif
	
	if ( statsOn == 1 )
		
		x0 = NumVarOrDefault( ssdf + "CS" + select[0,0] + "_X0", xpoints * 0.1 + xshift)
		y0 = NumVarOrDefault( ssdf + "CS" + select[0,0] + "_Y0", ypoints * 0.5 )
		x1 = NumVarOrDefault( ssdf + "CS" + select[0,0] + "_X1", x0 + 260 )
		y1 = NumVarOrDefault( ssdf + "CS" + select[0,0] + "_Y1", y0 + 170 )
		
		if ( numtype( x0 * y0 * x1 * y1 ) == 0 )
			MoveWindow /W=$gname x0, y0, x1, y1
			DoWindow /hide=0 $gname
		endif
		
	else
	
		DoWindow /Hide=1 $gname
	
	endif
	
End // ClampStatsDisplaySetPosition

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsRemoveWavesAll( kill )
	Variable kill // ( 0 ) dont kill waves ( 1 ) kill waves
	
	ClampStatsRemoveWaves( "Amp" )
	ClampStatsRemoveWaves( "Tau" )
	
	if ( kill == 1 )
		KillGlobals( "", "ST_*", "001" ) // kill Stats waves in current folder
	endif
	
End // ClampStatsRemoveWavesAll

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsRemoveWaves( select )
	String select // "Amp" or "Tau"
	
	Variable wcnt
	String wname, wlist
	
	String gName = ClampStatsDisplayName( select )
	
	wlist = TraceNameList( gName, ";", 1 )
	
	for ( wcnt = 0; wcnt < ItemsInList( wlist ); wcnt += 1 )
		wname = StringFromList( wcnt, wlist )
		RemoveFromGraph /Z/W=$gname $wname
	endfor

End // ClampStatsRemoveWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsColor( amp, rgb )
	Variable amp
	String rgb
	
	strswitch( rgb )
	
		case "r":

			switch( amp )
				case 0:
					return 65280
				case 1:
					return 0
				case 2:
					return 0
				case 3:
					return 65280
				case 4:
					return 26368
				case 5:
					return 52224
				case 6:
					return 0
				case 7:
					return 65280
				case 8:
					return 0
				case 9:
					return 0
				default:
					return 0
			endswitch
			
			break
		
		case "g":

			switch( amp )
				case 0:
					return 0
				case 1:
					return 0
				case 2:
					return 52224
				case 3:
					return 21760
				case 4:
					return 0
				case 5:
					return 52224
				case 6:
					return 0
				case 7:
					return 0
				case 8:
					return 65280
				case 9:
					return 26112
				default:
					return 0
			endswitch
			
			break
			
		case "b":

			switch( amp )
				case 0:
					return 0
				case 1:
					return 65280
				case 2:
					return 0
				case 3:
					return 0
				case 4:
					return 52224
				case 5:
					return 0
				case 6:
					return 0
				case 7:
					return 52224
				case 8:
					return 65280
				case 9:
					return 0
				default:
					return 0
			endswitch
			
			break
	
	endswitch

End // ClampStatsMarker

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsDisplayAmpPopup(ctrlName, popNum, popStr) : PopupMenuControl // display graph menu
	String ctrlName; Variable popNum; String popStr
	
	String select = "Amp"
	
	PopupMenu $ctrlName, mode=1, win=$ClampStatsDisplayName( select ) // reset the drop-down menu
	
	ClampStatsDisplayCall( popStr, select )

End // ClampStatsDisplayPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsDisplayTauPopup(ctrlName, popNum, popStr) : PopupMenuControl // display graph menu
	String ctrlName; Variable popNum; String popStr
	
	String select = "Tau"
	
	PopupMenu $ctrlName, mode=1, win=$ClampStatsDisplayName( select ) // reset the drop-down menu
	
	ClampStatsDisplayCall( popStr, select )

End // ClampStatsDisplayPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsDisplayCall( fxn, select )
	String fxn, select
	
	strswitch( fxn )
	
		case "Baseline":
			return ClampStatsDisplayBaseline( select )
			
		case "Multiple Y":
		case "MultipleY":
			return ClampStatsDisplayMultipleY( select )
			
		case "AutoScale":
			return ClampStatsDisplayAutoScale( select )
	
	endswitch
	
End // ClampStatsDisplayCall

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsDisplayBaseline( select )
	String select // "Amp" or "Tau"

	String ssdf = NMStimStatsDF()
	
	if ( DataFolderExists( ssdf ) == 0 )
		return 0
	endif

	Variable bsln = 1 + NumVarOrDefault( ssdf + "StatsDisplay" + select + "Bsln", 1 )

	Prompt bsln, "Display baseline values?", popup "no;yes;"
	DoPrompt "Clamp Online Stats Display", bsln
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	bsln -= 1
	
	SetNMvar( ssdf + "StatsDisplay" + select + "Bsln", bsln )
	
	return bsln
		
End // ClampStatsDisplayBaseline

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsDisplayMultipleY( select )
	String select // "Amp" or "Tau"

	String ssdf = NMStimStatsDF()
	
	if ( DataFolderExists( ssdf ) == 0 )
		return 0
	endif

	Variable y = 1 + NumVarOrDefault( ssdf + "StatsDisplay" + select + "MultipleY", 0 )

	Prompt y, "Display stats windows with multiple y-axes?", popup "no;yes;"
	DoPrompt "Clamp Online Stats Display", y
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	y -= 1
	
	SetNMvar( ssdf + "StatsDisplay" + select + "MultipleY", y )
	
	return y
		
End // ClampStatsDisplayMultipleY

//****************************************************************
//****************************************************************
//****************************************************************

Function ClampStatsDisplayAutoScale( select )
	String select // "Amp" or "Tau"

	String ssdf = NMStimStatsDF()
	
	if ( DataFolderExists( ssdf ) == 0 )
		return 0
	endif

	Variable y = 1 + NumVarOrDefault( ssdf + "StatsDisplay" + select + "AutoScale", 1 )

	Prompt y, "Auto scale y-axes?", popup "no;yes;"
	DoPrompt "Clamp Online Stats Display", y
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	y -= 1
	
	SetNMvar( ssdf + "StatsDisplay" + select + "AutoScale", y )
	
	return y
		
End // ClampStatsDisplayAutoScale

//****************************************************************
//****************************************************************
//****************************************************************


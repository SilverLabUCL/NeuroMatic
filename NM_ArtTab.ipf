#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma hide = 1

//****************************************************************
//****************************************************************
//
//	NeuroMatic: data aquisition, analyses and simulation software that runs with the Igor Pro environment
//	Copyright (C) 2017 Jason Rothman
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// ( at your option ) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
//	Contact Jason@ThinkRandom.com
//	www.NeuroMatic.ThinkRandom.com
//
//****************************************************************
//****************************************************************
//
//	Stimulus Artifact Subtraction
//
//	NM tab entry "Art"
//
//****************************************************************
//****************************************************************
//
//	Default Values
//
//****************************************************************
//****************************************************************

Static Constant ArtWidth = 0.5 // approximate length of artefact

Static StrConstant ArtShape = "PN"
// "PN" - artifact ends with positive peak followed by negative peak
// "NP" - artifact ends with negative peak followed by positive peak

Static StrConstant bslnFxn = "avg" // baseline function to compute within bslnWin: "avg", "line", "exp" or "zero"
// "avg" - baseline is average value - a line with zero slope
// "line" or "exp" - fits a line to baseline data - use this if your baseline is not always flat
// "exp" - fits an exponential to baseline data - use this if your baseline has exp decay

Static Constant bslnWin = 1.5 // baseline window size computed before stim time
Static Constant bslnDT = 0 // optional baseline time shift negative from stim time, 0 - no time shift

Static StrConstant decayFxn = "2exp" // "exp" or "2exp"

Static Constant decayWin = 0.2 // fit window, time after cursor A
Static Constant sbtrctWin = 2 // subtraction window, time after cursor A ( includes extrapolation after fit window )

Static StrConstant NMArtDF = "root:Packages:NeuroMatic:Art:"
Static StrConstant NMArtPrefix = "AT_"

//****************************************************************
//****************************************************************

Function /S NMTabPrefix_Art()
	
	return NMArtPrefix
	
End // NMTabPrefix_Art

//****************************************************************
//****************************************************************

Function NMArtTab( enable )
	Variable enable // ( 0 ) disable ( 1 ) enable tab
	
	if ( enable == 1 )
		CheckPackage( "Art", 0 ) // declare globals if necessary
		NMArtCheck() // declare Spike globals if necessary
		NMArtWavesCheck()
		NMArtMake( 0 ) // make controls if necessary
		NMArtUpdate()
	endif
	
	if ( DataFolderExists( NMArtDF ) == 1 )
		NMArtDisplay( enable )
	endif

End // NMArtTab

//****************************************************************
//****************************************************************

Function NMArtTabKill( what )
	String what
	
	String df = NMArtDF
	
	strswitch( what )
		case "waves":
			break
		case "globals":
			if ( DataFolderExists( df ) == 1 )
			//	KillDataFolder $df
			endif
			break
	endswitch

End // NMArtTabKill

//****************************************************************
//****************************************************************

Function NMArtCheck() // check globals

	String df = NMArtDF
	
	if ( DataFolderExists( df ) == 0 )
		return 0 // spike folder doesnt exist
	endif
	
	// panel control parameters
	
	CheckNMVar( df+"StimNum", 0 )
	CheckNMVar( df+"StimTime", 0 )
	CheckNMVar( df+"NumStims", 0 )
	
	CheckNMVar( df+"BslnValue1", Nan )
	CheckNMVar( df+"BslnValue2", Nan )
	CheckNMVar( df+"DcayValue1", Nan )
	CheckNMVar( df+"DcayValue2", Nan )
	
	CheckNMVar( df+"AutoFit", 1 )
	CheckNMVar( df+"TableFit", 0 )
	
	CheckNMStr( df+"StimTimeWName", "" )
	
	// drag wave variables
	
	CheckNMVar( df+"BslnXbgn", NaN )
	CheckNMVar( df+"BslnXend", NaN )
	CheckNMVar( df+"Xbgn", NaN )
	CheckNMVar( df+"Xend", NaN )
	
	// fit variables
	
	CheckNMVar( df+"BslnDT", bslnDT )
	CheckNMVar( df+"BslnWin", bslnWin ) // time before cursor A, for baseline curve fit function
	CheckNMVar( df+"DcayWin", decayWin ) // time after cursor A, for stim curve fit function
	CheckNMVar( df+"SbtrctWin", sbtrctWin ) // time after cursor A, for subtraction
	
	CheckNMStr( df+"BslnFxn", bslnFxn ) // "avg", "line", "exp" or "zero"
	CheckNMStr( df+"DcayFxn", decayFxn ) // "exp" or "2exp"
	
	// fit display waves
	
	CheckNMWave( df+"AT_fit", 0, Nan ) // exp fit
	CheckNMWave( df+"AT_fitb", 0, Nan ) // baseline fit
	CheckNMWave( df+"AT_fitx", 0, Nan ) // fit x times
	
	CheckNMWave( df+"AT_timeX", 0, Nan )
	CheckNMWave( df+"AT_timeY", 0, Nan )
	
	// fit parameter waves
	
	CheckNMWave( df+"AT_a", 4, Nan )
	CheckNMWave( df+"AT_b", 4, Nan )
	
	CheckNMWave( df+"AT_ArtSubFin", 0, 0 )
	
End // NMArtCheck

//****************************************************************
//****************************************************************

Function NMArtWavesCheck()

	String df = NMArtDF
	String wName = ChanDisplayWave( - 1 )
	
	Wave StimFit = $( df+"AT_fit" )
	
	if ( ( WaveExists( $NMArtSubWaveName( "nostim" ) ) == 0 ) || ( numpnts( StimFit ) != numpnts( $wName ) ) )
		NMArtReset()
	endif

End // NMArtWavesCheck

//****************************************************************
//****************************************************************

Function NMArtConfigs()

	NMConfigVar( "Art", "DisplayPrecision", 2, "number of decimal numbers to display", "" )
	NMConfigVar( "Art", "ArtWidth", ArtWidth, "approximate width of artifact", "" )
	NMConfigVar( "Art", "t1_hold", NaN, "fit hold value of 2-exp t1", "" )
	NMConfigVar( "Art", "t1_min", NaN, "min value of 2-exp t1", "" )
	NMConfigVar( "Art", "t1_max", NaN, "max value of 2-exp t1", "" )
	NMConfigVar( "Art", "t2_hold", NaN, "fit hold value of 2-exp t2", "" )
	NMConfigVar( "Art", "t2_min", NaN, "min value of 2-exp t2", "" )
	NMConfigVar( "Art", "t2_max", NaN, "max value of 2-exp t2", "" )
	
End // NMArtConfigs

//****************************************************************
//****************************************************************

Function NMArtVarGet( varName )
	String varName
	
	Variable defaultVal = NaN
	
	strswitch( varName )
	
		case "DisplayPrecision":
			defaultVal = 2 // decimal places
			break
	
		case "ArtWidth":
			defaultVal = ArtWidth
			break
	
		case "t1_hold":
			defaultVal = NaN
			break
			
		case "t1_min":
			defaultVal = NaN
			break
			
		case "t1_max":
			defaultVal = NaN
			break
	
		case "t2_hold":
			defaultVal = NaN
			break
			
		case "t2_min":
			defaultVal = NaN
			break
			
		case "t2_max":
			defaultVal = NaN
			break
			
		default:
			NMDoAlert ( "NMSpikeVar Error: no variable called " + NMQuotes( varName ) )
			return NaN
	
	endswitch
	
	return NumVarOrDefault( NMArtDF+varName, defaultVal )
	
End // NMArtVarGet

//****************************************************************
//****************************************************************

Function /S NMArtSubWaveName( wname )
	String wname
	
	Variable CurrentChan = NumVarOrDefault( "CurrentChan", 0 )
	Variable CurrentWave = NumVarOrDefault( "CurrentWave", 0 )
	
	return NMArtPrefix + NMChanWaveName( CurrentChan,CurrentWave ) + "_" + wname

End // NMArtSubWaveName

//****************************************************************
//****************************************************************

Function NMArtDisplay( appnd ) // append/remove Art display waves to current channel graph
	Variable appnd // // ( 0 ) remove ( 1 ) append
	
	Variable icnt, drag = appnd

	String gName = CurrentChanGraphName()
	
	String df = NMArtDF
	
	STRUCT NMRGB ac
	STRUCT NMRGB bc
	STRUCT NMRGB rc
	
	NMColorList2RGB( NMStatsStrGet( "AmpColor" ), ac )
	NMColorList2RGB( NMStatsStrGet( "BaseColor" ), bc )
	NMColorList2RGB( NMStatsStrGet( "RiseColor" ), rc )
	
	if ( DataFolderExists( df ) == 0 )
		return 0 // Art has not been initialized yet
	endif
	
	if ( Wintype( gName ) == 0 )
		return -1 // window does not exist
	endif
	
	String wlist = WaveList( "*_nostim", ";", "WIN:"+gName )
	
	String wName = NMArtSubWaveName( "nostim" )
	
	if ( !NMVarGet( "DragOn" ) || !StringMatch( CurrentNMTabName(), "Art" ) )
		drag = 0
	endif
	
	RemoveFromGraph /Z/W=$gName AT_fit, AT_fitb, AT_timeY
	
	for ( icnt = 0; icnt < ItemsInlist( wlist ); icnt += 1 )
		RemoveFromGraph /Z/W=$gName $( StringFromList( icnt, wlist ) )
		RemoveFromGraph /Z/W=$gName DragBgnY, DragEndY
		RemoveFromGraph /Z/W=$gName DragBslnBgnY, DragBslnEndY
	endfor
	
	if ( appnd == 1 )

		AppendToGraph /W=$gName $wName
		
		if ( WaveExists( $df+"AT_fit" ) )
			AppendToGraph /W=$gName $( df+"AT_fitb" ), $( df+"AT_fit" )
		endif
		
		if ( WaveExists( $df+"AT_timeX" ) )
			AppendToGraph /W=$gName $( df+"AT_timeY" ) vs $( df+"AT_timeX" )
		endif
		
		ModifyGraph /W=$gName rgb( $wName )=( 0,0,65280 ), lsize( $wName )=2
		
		ModifyGraph /W=$gName mode( AT_timeY )=3, marker( AT_timeY )=10, rgb( AT_timeY )=( 65280,0,0 ), msize( AT_timeY )=20, mrkThick( AT_timeY )=2
		ModifyGraph /W=$gName mode( AT_fitb )=0, lsize( AT_fitb )=2, rgb( AT_fitb )=( bc.r, bc.g, bc.b )
		
		//ShowInfo /W=$gName
		
	endif
	
	NMDragEnable( drag, "DragBgn", "", df+"Xbgn", "NMArtDragTrigger", gName, "bottom", "min", ac.r, ac.g, ac.b )
	NMDragEnable( drag, "DragEnd", "", df+"Xend", "NMArtDragTrigger", gName, "bottom", "max", ac.r, ac.g, ac.b )
	NMDragEnable( drag, "DragBslnBgn", "", df+"BslnXbgn", "NMArtDragTrigger", gName, "bottom", "min", bc.r, bc.g, bc.b )
	NMDragEnable( drag, "DragBslnEnd", "", df+"BslnXend", "NMArtDragTrigger", gName, "bottom", "max", bc.r, bc.g, bc.b )
	
End // NMArtDisplay

//****************************************************************
//****************************************************************

Function NMArtDragTrigger( offsetStr )
	String offsetStr
	
	Variable tbgn, tend, win, dt
	String wname, df = NMArtDF
	
	Variable StimTime = NumVarOrDefault( df+"StimTime", 0 )
	Variable AutoFit = NumVarOrDefault( df+"AutoFit", 0 )
	
	if ( NMDragTrigger( offsetStr ) < 0 )
		return -1
	endif
	
	wname = StringByKey( "TNAME", offsetStr )
	
	strswitch( wname )
	
		case "DragBgnY":
			//tbgn = NumVarOrDefault( df + "Xbgn", NaN )
			// do nothing
			break
			
		case "DragEndY":
		
			tbgn = NumVarOrDefault( df + "Xbgn", NaN )
			tend = NumVarOrDefault( df + "Xend", NaN )
			
			if ( numtype( tbgn * tend ) > 0 )
				return -1
			endif
			
			win = tend - tbgn
			
		   SetNMvar( df+"DcayWin", win )

			break
	
		case "DragBslnBgnY":
		case "DragBslnEndY":
		
			tbgn = NumVarOrDefault( df + "BslnXbgn", NaN )
			tend = NumVarOrDefault( df + "BslnXend", NaN )
			
			if ( numtype( tbgn * tend ) > 0 )
				return -1
			endif
			
			win = tend - tbgn
			dt = StimTime - tend
			
			SetNMvar( df+"BslnWin", win )
			SetNMvar( df+"BslnDT", dt )
			
			break
	
	
	endswitch
	
	if ( AutoFit )
		NMArtFit( update = 0 ) // no update, otherwise "UpdtDisplay: recursion attempted"
	endif
	
End // NMArtDragTriggerBsln

//****************************************************************
//****************************************************************

Function NMArtDragUpdate()

	String df = NMArtDF
	
	Variable drag = NMVarGet( "DragOn" )
	
	if ( drag )
		NMDragUpdate( "DragBgn" )
		NMDragUpdate( "DragEnd" )
	else
		NMDragClear( "DragBgn" )
		NMDragClear( "DragEnd" )
	endif
	
	if ( drag )
	
		NMDragUpdate( "DragBslnBgn" )
		NMDragUpdate( "DragBslnEnd" )
		
	else
	
		NMDragClear( "DragBslnBgn" )
		NMDragClear( "DragBslnEnd" )
		
	endif

End // NMArtDragUpdate

//****************************************************************
//****************************************************************

Function NMArtDragClear()
	
	NMDragClear( "DragBgn" )
	NMDragClear( "DragEnd" )
	NMDragClear( "DragBslnBgn" )
	NMDragClear( "DragBslnEnd" )
	
End // NMArtDragClear

//****************************************************************
//****************************************************************

Function NMArtMake( force ) // create Art tab controls
	Variable force
	
	Variable x0, y0, xinc, yinc

	String df = NMArtDF
	
	ControlInfo /W=NMPanel AT_BaseGrp
	
	if ( ( V_Flag != 0 ) && ( force == 0 ) )
		return 0 // Art tab has already been created, return here
	endif
	
	if ( DataFolderExists( df ) == 0 )
		return 0 // Art has not been initialized yet
	endif
	
	DoWindow /F NMPanel
	
	x0 = 40
	y0 = NMPanelTabY + 60
	xinc = 125
	yinc = 35
	
	GroupBox AT_BaseGrp, title = "Baseline", pos={x0-20,y0-25}, size={260,90}
	
	PopupMenu AT_BslnFxn, pos={x0+10,y0}, bodywidth=60
	PopupMenu AT_BslnFxn, value="", proc=NMArtPopup
	
	SetVariable AT_BslnVal1, title="a :", pos={x0+80,y0+2}, size={70,50}, fsize = 12
	SetVariable AT_BslnVal1, value=$( df+"BslnValue1" ), limits={-inf,inf,0}, frame=0
	
	SetVariable AT_BslnVal2, title="t :", pos={x0+155,y0+2}, size={70,50}, fsize = 12
	SetVariable AT_BslnVal2, value=$( df+"BslnValue2" ), limits={-inf,inf,0}, frame=0
	
	SetVariable AT_BslnDT, title="-dt:", pos={x0,y0+yinc}, size={100,50}, fsize = 12
	SetVariable AT_BslnDT, value=$( df+"BslnDT" ), proc=NMArtSetVar
	
	SetVariable AT_BslnWin, title="win:", pos={x0+xinc,y0+yinc}, size={100,50}, fsize = 12
	SetVariable AT_BslnWin, value=$( df+"BslnWin" ), proc=NMArtSetVar
	
	y0 += 100
	
	GroupBox AT_FitGrp, title = "Decay", pos={x0-20,y0-25}, size={260,90}
	
	PopupMenu AT_FitFxn, pos={x0+10,y0}, bodywidth=60
	PopupMenu AT_FitFxn, value="", proc=NMArtPopup
	
	SetVariable AT_FitVal1, title="a :", pos={x0+80,y0+2}, size={70,50}, fsize = 12
	SetVariable AT_FitVal1, value=$( df+"DcayValue1" ), limits={-inf,inf,0}, frame=0, proc=NMArtSetVar
	
	SetVariable AT_FitVal2, title="t :", pos={x0+155,y0+2}, size={70,50}, fsize = 12
	SetVariable AT_FitVal2, value=$( df+"DcayValue2" ), limits={-inf,inf,0}, frame=0, proc=NMArtSetVar
	
	SetVariable AT_FitWin, title="fit win:", pos={x0,y0+yinc}, size={100,50}, fsize = 12
	SetVariable AT_FitWin, value=$( df+"DcayWin" ), proc=NMArtSetVar
	
	SetVariable AT_SubWin, title="sub win:", pos={x0+xinc-10,y0+yinc}, size={110,50}, fsize = 12
	SetVariable AT_SubWin, value=$( df+"SbtrctWin" ), proc=NMArtSetVar
	
	y0 += 100
	
	GroupBox AT_TimeGrp, title = "Time", pos={x0-20,y0-25}, size={260,110}
	
	PopupMenu AT_TimeWave, pos={x0+140,y0}, bodywidth=190, proc=NMArtPopup
	PopupMenu AT_TimeWave, value=""
	
	SetVariable AT_NumStims, title=":", pos={x0+195,y0}, size={40,50}, limits={0,inf,0}
	SetVariable AT_NumStims, value=$( df+"NumStims" ), fsize=12, frame=0, noedit=1
	
	SetVariable AT_StimNum, title=" ", pos={x0+90,y0+1*yinc}, size={50,50}, limits={0,inf,0}
	SetVariable AT_StimNum, value=$( df+"StimNum" ), fsize = 12, proc=NMArtSetVar
	
	Button AT_FirstStim, pos={x0+90-80,y0+1*yinc}, title = "<<", size={30,20}, proc=NMArtButton
	Button AT_PrevStim, pos={x0+90-40,y0+1*yinc}, title = "<", size={30,20}, proc=NMArtButton
	Button AT_NextStim, pos={x0+150,y0+1*yinc}, title = ">", size={30,20}, proc=NMArtButton
	Button AT_LastStim, pos={x0+150+40,y0+1*yinc}, title = ">>", size={30,20}, proc=NMArtButton
	
	SetVariable AT_StimTime, title="t :", pos={x0+70+15,y0+2*yinc-10}, size={80,50}, fsize = 12
	SetVariable AT_StimTime, value=$( df+"StimTime" ), frame=0, limits={-inf,inf,0}, noedit=1
	
	y0 += 105
	x0 -= 5
	xinc = 80
	
	Button AT_Reset, pos={x0,y0}, title = "Reset", size={70,20}, proc=NMArtButton
	Button AT_StimFit, pos={x0+1*xinc,y0}, title = "Fit", size={70,20}, proc=NMArtButton
	Button AT_StimSubtract, pos={x0+2*xinc,y0}, title = "Subtract", size={70,20}, proc=NMArtButton
	
	Checkbox AT_AutoFit, title="auto fit", pos={x0,y0+yinc}, size={100,50}, value=1, fsize = 12, proc=NMArtCheckbox
	Button AT_StimFitAll, pos={x0+1*xinc,y0+yinc}, title = "Fit All", size={70,20}, proc=NMArtButton
	Button AT_StimRestore, pos={x0+2*xinc,y0+yinc}, title = "Undo", size={70,20}, proc=NMArtButton
	
	//Checkbox AT_TableFit, title="table", pos={x0+150,y0+yinc}, size={100,50}, value=1, fsize = 12, proc=NMArtCheckbox
	
End // NMArtMake

//****************************************************************
//****************************************************************

Function NMArtUpdate()

	Variable md
	String wList, df = NMArtDF

	String wName = ChanDisplayWave( -1 )
	
	String BslnFxn = StrVarOrDefault( df+"BslnFxn", "line" )
	String DcayFxn = StrVarOrDefault( df+"DcayFxn", "2exp" )
	String StimTimeWName = StrVarOrDefault( df+"StimTimeWName", "" )
	
	Variable t1_hold = NMArtVarGet( "t1_hold" )
	Variable t2_hold = NMArtVarGet( "t2_hold" )
	
	String formatStr = z_PrecisionStr()
	
	md = WhichListItem( BslnFxn, "avg;line;exp;zero;" ) + 1
	PopupMenu AT_BslnFxn, win=NMPanel, value ="avg;line;exp;zero;", mode=md
	
	strswitch( BslnFxn )
		case "avg":
			SetVariable AT_BslnVal1, win=NMPanel, title="a :", format = z_PrecisionStr()
			SetVariable AT_BslnVal2, win=NMPanel, title=" ", disable = 1, format = z_PrecisionStr()
			break
		case "line":
			SetVariable AT_BslnVal1, win=NMPanel, title="b :", format = z_PrecisionStr()
			SetVariable AT_BslnVal2, win=NMPanel, title="m :", disable = 0, format = z_PrecisionStr()
			break
		case "exp":
			SetVariable AT_BslnVal1, win=NMPanel, title="a :", format = z_PrecisionStr()
			SetVariable AT_BslnVal2, win=NMPanel, title="t :", disable = 0, format = z_PrecisionStr()
			break
		case "zero":
			SetVariable AT_BslnVal1, win=NMPanel, title="a :", format = z_PrecisionStr()
			SetVariable AT_BslnVal2, win=NMPanel, title="t :", disable = 1, format = z_PrecisionStr()
			break
	endswitch
	
	SetVariable AT_BslnDT, win=NMPanel, format = z_PrecisionStr()
	SetVariable AT_BslnWin, win=NMPanel, format = z_PrecisionStr()
	
	md = WhichListItem( DcayFxn, "exp;2exp;" ) + 1
	PopupMenu AT_FitFxn, win=NMPanel, value="exp;2exp;", mode=md
	
	SetVariable AT_FitVal1, win=NMPanel, format = z_PrecisionStr()
	SetVariable AT_FitVal2, win=NMPanel, format = z_PrecisionStr()
	
	strswitch( DcayFxn )
	
		case "exp":
		
			SetVariable AT_FitVal1, win=NMPanel, title="a :"
			
			if ( ( numtype( t1_hold ) == 0 ) && ( t1_hold > 0 ) )
				SetVariable AT_FitVal2, win=NMPanel, title="t :", valueColor=(65535,0,0)
			else
				SetVariable AT_FitVal2, win=NMPanel, title="t :", valueColor=(0,0,0)
			endif
			
			break
			
		case "2exp":
		
			if ( ( numtype( t1_hold ) == 0 ) && ( t1_hold > 0 ) )
				SetVariable AT_FitVal1, win=NMPanel, title="t1 :", valueColor=(65535,0,0)
			else
				SetVariable AT_FitVal1, win=NMPanel, title="t1 :", valueColor=(0,0,0)
			endif
			
			if ( ( numtype( t2_hold ) == 0 ) && ( t2_hold > 0 ) )
				SetVariable AT_FitVal2, win=NMPanel, title="t2 :", valueColor=(65535,0,0)
			else
				SetVariable AT_FitVal2, win=NMPanel, title="t2 :", valueColor=(0,0,0)
			endif
			
			break
			
	endswitch
	
	SetVariable AT_FitWin, win=NMPanel, format = z_PrecisionStr()
	SetVariable AT_SubWin, win=NMPanel, format = z_PrecisionStr()
	
	wList = NMArtTimeWaveList()
	
	md = WhichListItem( StimTimeWName, wList )
	
	if ( md == 0 )
		md = 1
	else
		md += 3
	endif
	
	PopupMenu AT_TimeWave, win=NMPanel, value="Select Wave of Stim Times;---;" + NMArtTimeWaveList(), mode=md
	
	SetVariable AT_BslnWin, win=NMPanel, limits={leftx( $wname ),rightx( $wname ),deltax( $wname )}
	SetVariable AT_FitWin, win=NMPanel, limits={0,inf,deltax( $wname )}
	SetVariable AT_SubWin, win=NMPanel, limits={0,inf,deltax( $wname )}
	SetVariable AT_StimTime, win=NMPanel, format = z_PrecisionStr()
	
	Checkbox AT_AutoFit, win=NMPanel, value=NumVarOrDefault( df+"AutoFit",1 )
	//Checkbox AT_TableFit, win=NMPanel, value=NumVarOrDefault( df+"TableFit",0 )
	
	NMArtStimsCount()

End // NMArtUpdate

//****************************************************************
//****************************************************************

Static Function /S z_PrecisionStr()

	Variable precision = NMArtVarGet( "DisplayPrecision" )
	
	precision = max( precision, 1 )
	precision = min( precision, 5 )

	return "%." + num2istr( precision ) + "f"

End // z_PrecisionStr

//****************************************************************
//****************************************************************

Function /S NMArtTimeWaveList()

	String currentWavePrefix = CurrentNMWavePrefix()

	String wList = WaveList( "*",";","" )
	String wListSP = WaveList( "SP_*",";","" )
	String cList = WaveList( currentWavePrefix + "*",";","" )
	String aList = WaveList( "AT*stim",";","" )
	
	wList = RemoveFromList( cList, wList )
	wList = RemoveFromList( "FileScaleFactors;yLabel;", wList )
	wList = RemoveFromList( wListSP, wList )
	wList = RemoveFromList( aList, wList )
	
	wList = wListSP + wList
	
	return wList

End NMArtTimeWaveList

//****************************************************************
//****************************************************************

Function NMArtPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	String df = NMArtDF
	
	Variable autoFit = NumVarOrDefault( df+"AutoFit", 0 )
	
	strswitch( ctrlName )
	
		case "AT_TimeWave":
		
			if ( WaveExists( $popStr ) )
				NMArtTimeWaveSet( popStr )
				NMArtReset()
			else
				autoFit = 0
			endif
			
			NMArtUpdate()
			
			break
			
		case "AT_BslnFxn":
			SetNMstr( df+"BslnFxn", popStr )
			SetNMvar( df+"BslnValue1", Nan )
			SetNMvar( df+"BslnValue2", Nan )
			break
			
		case "AT_FitFxn":
			SetNMstr( df+"DcayFxn", popStr )
			SetNMvar( df+"DcayValue1", Nan )
			SetNMvar( df+"DcayValue2", Nan )
			break
			
	endswitch
	
	NMArtUpdate()
	
	if ( autoFit )
		NMArtFit()
	endif
	
End // NMArtPopup

//****************************************************************
//****************************************************************

Function NMArtCheckbox( ctrlName, checked ) : CheckBoxControl
	String ctrlName; Variable checked

	String df = NMArtDF
	
	strswitch( ctrlName )
		case "AT_AutoFit":
			SetNMvar( df+"AutoFit",checked )
			break
		//case "AT_TableFit":
			//NMArtTable( checked )
			//SetNMvar( df+"TableFit", checked )
			//break
	endswitch

End // NMArtCheckbox

//****************************************************************
//****************************************************************

Function NMArtSetVar( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	String df = NMArtDF
	
	Variable StimNum = NumVarOrDefault( df+"StimNum", 0 )
	
	strswitch( ctrlName )
	
		case "AT_FitVal1":
			z_SetTauHold( 1, varNum )
			break
		case "AT_FitVal2":
			z_SetTauHold( 2, varNum )
			break
	
		case "AT_StimTime":
			//NMArtStimTimeSet( varNum )
			break
			
		case "AT_BslnDT":
		case "AT_BslnWin":
		case "AT_SubWin":
		case "AT_FitWin":
			//varNum = StimNum
			varStr = num2istr( stimNum )
		case "AT_StimNum":
			NMArtGoTo( varStr )
			break
			
	endswitch
	
End // NMArtSetVar

//****************************************************************
//****************************************************************

Static Function z_SetTauHold( select, holdValue )
	Variable select, holdValue
	
	String df = NMArtDF
	
	String dcayFxn = StrVarOrDefault( df+"DcayFxn", "" )
	
	if ( ( numtype( holdValue ) > 0 ) || ( holdValue <= 0 ) )
		holdValue = NaN
	endif
	
	if ( StringMatch( dcayFxn, "exp" ) )
		if ( select == 2 )
			NMConfigVarSet( "Art", "t1_hold", holdValue )
			NMHistory( "Art t1_hold = " + num2str( holdValue ) )
		endif
	elseif ( StringMatch( dcayFxn, "2exp" ) )
		if ( select == 1 )
			NMConfigVarSet( "Art", "t1_hold", holdValue )
			NMHistory( "Art t1_hold = " + num2str( holdValue ) )
		elseif ( select == 2 )
			NMConfigVarSet( "Art", "t2_hold", holdValue )
			NMHistory( "Art t2_hold = " + num2str( holdValue ) )
		endif
	endif
	
	NMArtUpdate()

End // z_SetTauHold

//****************************************************************
//****************************************************************

Function NMArtButton( ctrlName ) : ButtonControl
	String ctrlName

	strswitch( ctrlName )
	
		case "AT_Reset":
			NMArtReset()
			break
			
		case "AT_StimFit":
			NMArtFit()
			break
			
		case "AT_StimFitAll":
			z_FitAllCall()
			break
			
		case "AT_StimSubtract":
			NMArtFitSubtract()
			break
			
		case "AT_StimRestore":
			NMArtRestore()
			break
			
		case "AT_FirstStim":
			NMArtGoTo( "-inf" )
			break
			
		case "AT_PrevStim":
			NMArtGoTo( "-1" )
			break
			
		case "AT_NextStim":
			NMArtGoTo( "+1" )
			break
			
		case "AT_LastStim":
			NMArtGoTo( "inf" )
			break
	
	endswitch

End // NMArtButton

//****************************************************************
//****************************************************************

Function NMArtReset()

	String df = NMArtDF
	String wName = ChanDisplayWave( -1 )

	if ( WaveExists( $wName ) == 1 )
		Duplicate /O $wname $NMArtSubWaveName( "nostim" )
		Duplicate /O $wname $NMArtSubWaveName( "stim" )
		Duplicate /O $wname $( df+"AT_fit" )
		Duplicate /O $wname $( df+"AT_fitb" )
		Duplicate /O $wname $( df+"AT_fitx" )
	endif
	
	Wave StimFit = $( df+"AT_fit" )
	Wave StimFitb = $( df+"AT_fitb" )
	Wave StimFitx = $( df+"AT_fitx" )
	Wave AT_ArtSubFin = $( df+"AT_ArtSubFin" )
	
	StimFit = Nan
	StimFitb = Nan
	StimFitx = x
	AT_ArtSubFin = 0
	
	SetNMvar( df+"StimTime", 0 )
	SetNMvar( df+"StimNum", 0 )
	
	SetNMvar( df+"BslnValue1", NaN ) // tab display
	SetNMvar( df+"BslnValue2", NaN )
	SetNMvar( df+"DcayValue1", NaN )
	SetNMvar( df+"DcayValue2", NaN )
	
	SetNMvar( df+"fit_a1", NaN )
	SetNMvar( df+"fit_t1", NaN )
	SetNMvar( df+"fit_a2", NaN )
	SetNMvar( df+"fit_t2", NaN )
	
	NMArtGoTo( "0" )
	
End // NMArtReset

//****************************************************************
//****************************************************************

Function NMArtStimsCount()

	String df = NMArtDF
	
	if ( !WaveExists( $df+"AT_timeX" ) || ( numpnts( $df+"AT_timeX" ) == 0 ) )
		return 0
	endif
	
	WaveStats /Q $( df+"AT_timeX" )

	SetNMvar( df+"NumStims", V_npnts )

End // NMArtStimsCount

//****************************************************************
//****************************************************************

Function NMArtTimeWaveSet( wname )
	String wname
	
	Variable icnt, pnt
	String df = NMArtDF
	
	if ( ( strlen( wname ) == 0 ) || ( WaveExists( $wname ) == 0 ) )
		return 0
	endif
	
	SetNMstr( df+"StimTimeWName", wname )
	
	Duplicate /O $wname $( df+"AT_timeX" ), $( df+"AT_timeY" ), $( df+"AT_ArtSubFin" ) 
	
	Wave xwave = $( df+"AT_timeX" )
	Wave ywave = $( df+"AT_timeY" )
	Wave fwave = $( df+"AT_ArtSubFin" )
	Wave dwave = $ChanDisplayWave( -1 )
	
	ywave = Nan
	fwave = 0
	
	for ( icnt = 0; icnt < numpnts( xwave ); icnt += 1 )
		pnt = x2pnt( dwave, xwave[icnt] )
		ywave[ icnt ] = dwave[ pnt ]
	endfor
	
End // NMArtTimeWaveSet

//****************************************************************
//****************************************************************

Function NMArtGoTo( select ) // jump to new stim time
	String select
	// "-1" - previous
	// "+1" - next
	// "-inf" - first 
	// "inf" - last
	// otherwise pass array number of stim time wave
	
	Variable next, doFit
	String df = NMArtDF
	
	Variable StimNum = NumVarOrDefault( df+"StimNum", 0 )
	Variable AutoFit = NumVarOrDefault( df+"AutoFit", 0 )
	
	Variable pmax = z_StimNumMax()

	strswitch( select )
			
		case "-inf":
			next = 0
			break
			
		case "-1":
			next = StimNum - 1
			break
			
		case "+1":
			next = StimNum + 1
			break
			
		case "inf":
			next = pmax
			break
			
		default:
		
			next = str2num( select )
			
			if ( numtype( next ) > 0 )
				next = 0
			endif
	
	endswitch
	
	next = max( next, 0 )
	next = min( next, pmax )
	
	if ( AutoFit )
	
		if ( WaveExists( $df+"AT_ArtSubFin" ) )
		
			Wave AT_ArtSubFin = $( df+"AT_ArtSubFin" )
			
			if ( next < numpnts( AT_ArtSubFin ) )
			
				if ( AT_ArtSubFin[next] == 0 )
					doFit = 1
				endif
			
			endif
		
		endif
	
	endif
	
	NMArtStimNumSet( next, doFit = doFit )

End // NMArtGoTo

//****************************************************************
//****************************************************************

Static function z_StimNumMax()
	
	Variable icnt
	
	String df = NMArtDF
	
	String wName = StrVarOrDefault( df+"StimTimeWName", "" )
	
	if ( !WaveExists( $wName ) )
		return NaN
	endif
	
	Wave wtemp = $wName
	
	for ( icnt = numpnts( wtemp ) - 1 ; icnt >= 0 ; icnt -= 1 )
		if ( numtype( wtemp[ icnt ] ) == 0 )
			return icnt
		endif
	endfor
	
	return NaN

End // z_StimNumMax

//****************************************************************
//****************************************************************

Function NMArtStimNumSet( stimNum [ doFit ] )
	Variable stimNum
	Variable doFit
	
	Variable t
	String df = NMArtDF
	
	if ( ( numtype( stimNum) > 0 ) || ( stimNum < 0 ) )
		return -1 // out of range
	endif
	
	if ( !WaveExists( $df+"AT_timeX" ) || ( numpnts( $df+"AT_timeX" ) == 0 ) )
		return -1 // out of range
	endif
	
	Wave xwave = $( df+"AT_timeX" )
	Wave AT_fit = $( df+"AT_fit" )
	Wave AT_fitb = $( df+"AT_fitb" )
	
	if ( stimNum > numpnts( xwave ) - 1 )
		return -1 // out of range
	endif
	
	SetNMvar( df+"StimNum", stimNum )
	
	t = xwave[stimNum]
	z_DisplayTimeSet( stimNum, t )
	
	AT_fit = Nan
	AT_fitb = Nan
	
	if ( doFit )
		return NMArtFit()
	endif
	
	return 0
	
End // NMArtStimNumSet

//****************************************************************
//****************************************************************

Static Function z_DisplayTimeSet( stimNum, t )
	Variable stimNum
	Variable t // stim time, ( 0 ) to reset
	
	Variable bsln, tpeak, xAxisDelta, yAxisDelta
	Variable bbgn, bend, abgn, aend, dbgn, dend
	Variable pbgn, pend, ybgn, yend, ymin, ymax
	String df = NMArtDF
	
	Variable CurrentChan = NumVarOrDefault( "CurrentChan", 0 )
	
	Variable BslnWin = NumVarOrDefault( df+"BslnWin", 0 )
	Variable BslnDT = NumVarOrDefault( df+"BslnDT", 0 )
	Variable SbtrctWin = NumVarOrDefault( df+"SbtrctWin", 0 )
	Variable DcayWin = NumVarOrDefault( df+"DcayWin", 0 )
	
	String gName = CurrentChanGraphName()
	String wName = ChanDisplayWave( CurrentChan )
	
	Wave timeY = $( df+"AT_timeY" )
	
	wName = GetPathName( wName, 0 )
	
	SetNMvar( df+"StimTime", t )
	 
	if ( t == 0 ) // reset
		//Cursor /W=$gName A, $wName, 0
		//Cursor /W=$gName B, $wName, 0
		SetAxis /A
		return 0
	elseif ( numtype( t ) > 0 )
		return 0
	endif
	
	String dName = ChanDisplayWave( -1 )
	
	bbgn = z_BslnBgn()
	bend = z_BslnEnd()
	
	SetNMvar( df + "BslnXbgn", bbgn ) // drag wave variable
	SetNMvar( df + "BslnXend", bend )
	
	WaveStats /Q/R=( bbgn, bend ) $dname
	
	bsln = V_avg
	
	if ( ( stimNum >= 0 ) && ( stimNum < numpnts( timeY ) ) )
		timeY[ stimNum ] = bsln
	endif
	
	abgn = t // artifact window
	aend = t + ArtWidth
	
	WaveStats /Q/R=( abgn, aend ) $dname
	
	strswitch( ArtShape )
		case "PN":
			tpeak = V_maxloc // this should be "P"
			break
		case "NP":
			tpeak = V_minloc // this should be "N"
			break
		default:
			return 0
	endswitch
	
	WaveStats /Q/R=( tpeak, aend ) $dname
	
	strswitch( ArtShape )
		case "PN":
			tpeak = V_minloc // this should be "N"
			break
		case "NP":
			tpeak = V_maxloc // this should be "P"
			break
		default:
			return 0
	endswitch
	
	dbgn = tpeak // decay window
	//dbgn += deltax( $dname ) // shift one time delta
	dend = dbgn + DcayWin
	
	xAxisDelta = ( BslnDT + BslnWin + SbtrctWin ) / 4 // for channel display
	
	//Cursor /W=$gName A, $wName, dbgn
	//Cursor /W=$gName B, $wName, dend
	
	SetNMvar( df + "Xbgn", dbgn ) // drag wave variable
	SetNMvar( df + "Xend", dend )

	DoWindow /F $gName
	
	SetAxis bottom ( bbgn - xAxisDelta ), ( t + SbtrctWin + xAxisDelta )
	
	Wave wtemp = $dName
	
	pbgn = x2pnt( wtemp, dbgn )
	pend = x2pnt( wtemp, dend )
	ybgn = wtemp[ pbgn ]
	yend = wtemp[ pend ]
	
	ymin = min( ybgn, yend )
	ymax = max( ybgn, yend )
	ymax = max( ymax, bsln )
	yAxisDelta = abs( ymax - ymin ) // for channel display
	
	SetAxis Left ( ymin - yAxisDelta ), ( ymax + yAxisDelta )
	
	NMArtDragUpdate()
	
End // z_DisplayTimeSet

//****************************************************************
//****************************************************************

Static Function z_BslnBgn()

	String df = NMArtDF

	Variable StimTime = NumVarOrDefault( df+"StimTime", 0 )
	Variable BslnWin = NumVarOrDefault( df+"BslnWin", 0 )
	Variable BslnDT = NumVarOrDefault( df+"BslnDT", 0 )
	
	return StimTime - BslnDT - BslnWin

End // z_BslnBgn

//****************************************************************
//****************************************************************

Static Function z_BslnEnd()

	String df = NMArtDF

	Variable StimTime = NumVarOrDefault( df+"StimTime", 0 )
	Variable BslnWin = NumVarOrDefault( df+"BslnWin", 0 )
	Variable BslnDT = NumVarOrDefault( df+"BslnDT", 0 )
	
	return StimTime - BslnDT

End // z_BslnEnd

//****************************************************************
//****************************************************************

Static Function z_FitAllCall()

	String df = NMArtDF
	String StimTimeWName = StrVarOrDefault( df+"StimTimeWName", "" )
	String title = "NM Art Tab : " + StimTimeWName
	
	Variable vflag = NMDoAlert( "Fit and subtract all stimulus artifacts?", title = title, alertType = 1 )

	if ( vflag == 1 )
		NMArtFitAll()
	endif

End // z_FitAllCall

//****************************************************************
//****************************************************************

Function NMArtFitAll()

	Variable icnt, flag, stimTime, numStim
	String df = NMArtDF
	
	Variable stimNumSave = NumVarOrDefault( df+"StimNum", 0 )
	
	if ( !WaveExists( $df+"AT_ArtSubFin" ) )
		return 0
	endif
	
	Wave AT_ArtSubFin = $( df+"AT_ArtSubFin" )
	
	numStim = numpnts( AT_ArtSubFin )
	
	for ( icnt = 0; icnt < numStim; icnt += 1 )
	
		if ( NMProgress( icnt, numStim, "Art Subtracting..." ) == 1 ) // update progress display
			break // cancel
		endif
	
		if ( AT_ArtSubFin[icnt] )
			continue
		endif
		
		NMArtStimNumSet( icnt )
		
		stimTime = NumVarOrDefault( df+"StimTime", NaN )
		
		if ( numtype( stimTime ) > 0 )
			continue
		endif
		
		flag = NMArtFit()
		
		if ( flag == 0 )
			NMArtFitSubtract()
		else
			NMHistory( "Art all waves failed to fit stim #" + num2istr( icnt ) )
		endif
		
	endfor
	
	NMArtStimNumSet( stimNumSave )

End // NMArtFitAll

//****************************************************************
//****************************************************************

Function NMArtFit( [ update ] )
	Variable update

	Variable flag
	String df = NMArtDF

	Variable StimTime = NumVarOrDefault( df+"StimTime", NaN )
	String gName = CurrentChanGraphName()
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( numtype( StimTime ) > 0 )
		return -1 // nothing to fit
	endif
	
	flag = NMArtFitBsln()
	
	if ( flag == 0 )
		flag = NMArtFitDecay()
	endif
	
	if ( update )
		DoUpdate
	endif
	
	return flag

End // NMArtFit

//****************************************************************
//****************************************************************

Function NMArtFitBsln( [ update ] )
	Variable update

	Variable bbgn, bend, dt, ybgn, yend, pbgn, pend
	Variable v1 = Nan, v2 = Nan
	Variable V_FitError = 0, V_chisq
	 
	String df = NMArtDF
	
	String fxn = StrVarOrDefault( df+"BslnFxn", "" )
	
	Variable StimTime = NumVarOrDefault( df+"StimTime", NaN )
	
	Wave eWave = $ChanDisplayWave( -1 )
	Wave AT_a = $( df+"AT_a" )
	Wave AT_b = $( df+"AT_b" )
	Wave AT_fitb = $( df+"AT_fitb" ) // channel display wave
	Wave AT_fitx = $( df+"AT_fitx" ) // x-times for fitting
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	bbgn = z_BslnBgn()
	bend = z_BslnEnd()
	
	dt = deltax( eWave )
	
	WaveStats /Q/R=( bbgn, bbgn + 10 * dt ) eWave
	
	ybgn = V_avg
	
	WaveStats /Q/R=( bend - 10 * dt, bend ) eWave
	
	yend = V_avg

	strswitch( fxn )
	
		case "exp":
	
			Redimension /N=4 AT_a
			Redimension /N=0 AT_b // n=0 so NMArtFxnExp computes normal exp
			
			AT_a[0] = bbgn // x0 // hold
			AT_a[1] = yend // y0
			AT_a[2] = 1.5 * ( ybgn - yend ) // a1
			AT_a[3] = ( bend - bbgn ) / 5 // t1
			
			FuncFit /Q/W=2/N/H="1001" NMArtFxnExp AT_a ewave( bbgn,bend ) // single exp // W=2 suppresses Fit Progress window
			FuncFit /Q/W=2/N/H="1000" NMArtFxnExp AT_a ewave( bbgn,bend ) // single exp
			
			AT_fitb = NMArtFxnExp( AT_a, AT_fitx )
			
			Redimension /N=4 AT_b // now n=4 so NMArtFxnExp will use baseline in Decay fit
			AT_b = AT_a
			
			v1 = AT_a[2]
			v2 = AT_a[3]
		
			break
			
		case "line":
		
			Redimension /N=2 AT_b
			
			AT_b[1] = ( yend - ybgn ) / ( bend - bbgn ) // slope m
			AT_b[0] = ybgn - AT_b[1] * bbgn // offset b
			
			FuncFit /Q/W=2/N NMArtFxnLine AT_b ewave( bbgn,bend ) // line fit
			
			AT_fitb = NMArtFxnLine( AT_b, AT_fitx )
			
			v1 = AT_b[0] // b
			v2 = AT_b[1] // m
			
			break
			
		case "avg":
		
			Redimension /N=1 AT_b
			
			WaveStats /Q/R=( bbgn, bend ) ewave
	
			AT_fitb = V_avg
			AT_b = V_avg
			v1 = V_avg
			
			break
			
		case "zero":
			AT_fitb = 0
			AT_b = 0
			v1 = 0
			break
			
		default:
			return NaN
		
	endswitch
	
	pbgn = 0
	pend = x2pnt( eWave, bbgn ) - 1

	AT_fitb[ pbgn, pend ] = Nan
	
	pbgn = x2pnt( eWave, StimTime + SbtrctWin ) + 1
	pend = numpnts( AT_fitb ) - 1
	AT_fitb[ pbgn, pend ] = Nan
	
	if ( update )
		DoUpdate
	endif
	
	SetNMvar( df+"BslnValue1", v1 ) // tab display
	SetNMvar( df+"BslnValue2", v2 )
	
	KillWaves /Z W_Sigma
	
	return V_FitError
	
End // NMArtFitBsln

//****************************************************************
//****************************************************************

Function NMArtFitDecay( [ update ] )
	Variable update

	Variable pbgn, pend, y0, dt
	Variable V_FitError = 0, V_FitQuitReason, V_chisq
	String hstr
	
	String df = NMArtDF
	
	Variable tbgn = NumVarOrDefault( df + "Xbgn", NaN ) // drag wave variable
	Variable tend = NumVarOrDefault( df + "Xend", NaN )
	
	Variable a1 = NumVarOrDefault( df+"fit_a1", NaN )
	Variable t1 = NumVarOrDefault( df+"fit_t1", NaN )
	Variable a2 = NumVarOrDefault( df+"fit_a2", NaN )
	Variable t2 = NumVarOrDefault( df+"fit_t2", NaN )
	
	Variable t1_hold = NMArtVarGet( "t1_hold" )
	Variable t2_hold = NMArtVarGet( "t2_hold" )
	
	Wave wtemp = $ChanDisplayWave( -1 )
	Wave AT_a = $( df+"AT_a" )
	Wave AT_fit = $( df+"AT_fit" )
	Wave AT_fitb = $( df+"AT_fitb" )
	Wave AT_fitx = $( df+"AT_fitx" )
	
	NVAR StimTime = $( df+"StimTime" )
	NVAR StimNum = $( df+"StimNum" )
	NVAR BslnWin = $( df+"BslnWin" )
	NVAR DcayWin = $( df+"DcayWin" )
	NVAR SbtrctWin = $( df+"SbtrctWin" )
	
	SVAR DcayFxn = $( df+"DcayFxn" )
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	pbgn = x2pnt( wtemp, tbgn )
	pend = x2pnt( wtemp, tend )
	dt = deltax( wtemp )
	
	WaveStats /Q/R=( tend - 10 * dt, tend ) wtemp
	
	y0 = V_avg
	
	a1 = NaN
	t1 = NaN // force new 1-exp fit, this improves 2-exp fit
	
	if ( StringMatch( DcayFxn, "exp" ) || ( numtype( a1 * t1 ) > 0 ) ) // fit 1-exp
	
		Redimension /N=4 AT_a // must be n=4 for 1-exp fit
		
		AT_a[0] = tbgn // x0 // hold
		AT_a[1] = y0 // hold // during fit y0 is set to baseline function stored in AT_b
		
		if ( numtype( a1 ) == 0 )
			AT_a[2] = a1
		else
			AT_a[2] = wtemp[ pbgn ] - y0
		endif
		
		if ( numtype( t1 ) == 0 )
			AT_a[3] = t1
		else
			AT_a[3] = ( tend - tbgn ) / 5
		endif
		
		FuncFit /Q/W=2/N/H="1100" NMArtFxnExp AT_a wtemp( tbgn, tend )
		
		if ( V_FitError != 0 )
			NMHistory( "1-exp fit error = " + num2str( V_FitError ) )
			AT_fit = Nan
			SetNMvar( df+"DcayValue1", NaN )
			SetNMvar( df+"DcayValue2", NaN )
			return V_FitError
		endif
		
		a1 = AT_a[2]
		t1 = AT_a[3]
	
	endif
	
	a2 = NaN
	t2 = NaN
	
	if ( StringMatch( DcayFxn, "2exp" ) ) // fit 2-exp
	
		Make /T/O/N=0 FitConstraints = ""
	
		z_Constraints( DcayFxn, FitConstraints )
	
		Redimension /N=6 AT_a // must be n=6 for 2-exp fit
		
		AT_a[0] = tbgn // x0 // hold
		AT_a[1] = y0 // hold // during fit y0 is set to baseline function stored in AT_b
		
		hstr = "11"
		
		if ( ( numtype( a1 ) > 0 ) || ( a1 == 0 ) )
			a1 = wtemp[ pbgn ] - y0
		endif
		
		if ( ( numtype( t1_hold ) == 0 ) || ( t1_hold > 0 ) )
			t1 = t1_hold
			hstr += "01"
		elseif ( ( numtype( t1 ) > 0 ) || ( t1 <= 0 ) )
			t1 = ( tend - tbgn ) / 5
			hstr += "00"
		else // t1 ok
			hstr += "00"
		endif
		
		if ( ( numtype( a2 ) > 0 ) || ( a2 == 0 ) )
			a2 = a1 * 0.5
		endif
		
		if ( ( numtype( t2_hold ) == 0 ) || ( t2_hold > 0 ) )
			t2 = t2_hold
			hstr += "01"
		elseif ( ( numtype( t2 ) > 0 ) || ( t2 <= 0 ) )
			t2 = 3 * t1
			hstr += "00"
		else // t2 ok
			hstr += "00"
		endif
		
		AT_a[2] = a1
		AT_a[3] = t1
		AT_a[4] = a2
		AT_a[5] = t2
		
		//print a1, t1, a2, t2
		
		FuncFit /Q/W=2/N/H=hstr NMArtFxnExp2 AT_a wtemp( tbgn, tend ) /C=FitConstraints
		
		if ( V_FitError != 0 )
			NMHistory( "2-exp fit error = " + num2str( V_FitError ) + ", reason = " + num2str( V_FitQuitReason ) )
			AT_fit = Nan
			SetNMvar( df+"DcayValue1", NaN )
			SetNMvar( df+"DcayValue2", NaN )
			return V_FitError
		endif
		
		a1 = AT_a[2]
		t1 = AT_a[3]
		a2 = AT_a[4]
		t2 = AT_a[5]
		
		//print a1, t1, a2, t2
	
	endif
	
	if ( StringMatch( DcayFxn, "exp" ) )
		AT_fit = NMArtFxnExp( AT_a, AT_fitx )
		SetNMvar( df+"DcayValue1", a1 ) // tab
		SetNMvar( df+"DcayValue2", t1 )
		SetNMvar( df+"fit_a1", a1 ) // save for next fit
		SetNMvar( df+"fit_t1", t1 )
		SetNMvar( df+"fit_a2", NaN )
		SetNMvar( df+"fit_t2", NaN )
	elseif ( StringMatch( DcayFxn, "2exp" ) )
		AT_fit = NMArtFxnExp2( AT_a, AT_fitx )
		SetNMvar( df+"DcayValue1", t1 ) // tab
		SetNMvar( df+"DcayValue2", t2 )
		SetNMvar( df+"fit_a1", a1 ) // save for next fit
		SetNMvar( df+"fit_t1", t1 )
		SetNMvar( df+"fit_a2", a2 )
		SetNMvar( df+"fit_t2", t2 )
	endif 
	
	AT_fit[ 0, pbgn - 1 ] = Nan
	
	pbgn = x2pnt( wtemp, StimTime + SbtrctWin ) + 1
	pend = numpnts( wtemp ) - 1
	
	AT_fit[ pbgn, pend ] = Nan
	
	WaveStats /Q AT_fit
	
	Variable fmax = max( abs( V_max ), abs( V_min ) )
	
	WaveStats /Q wtemp
	
	Variable wmax = max( abs( V_max ), abs( V_min ) )
	
	if ( fmax > wmax )
		AT_fit = Nan // probably a bad fit
	endif
	
	if ( update )
		DoUpdate
	endif
	
	KillWaves /Z W_sigma
	KillWaves /Z FitConstraints
	
	return V_FitError

End // NMArtFitDecay

//****************************************************************
//****************************************************************

Static Function z_Constraints( dcayFxn, cwave )
	String dcayFxn
	Wave /T cwave

	Variable icnt, items
	String cList = ""
	
	Variable t1_min = NMArtVarGet( "t1_min" )
	Variable t1_max = NMArtVarGet( "t1_max" )
	Variable t2_min = NMArtVarGet( "t2_min" )
	Variable t2_max = NMArtVarGet( "t2_max" )
	
	if ( ( numtype( t1_min ) == 0 ) && ( t1_min > 0 ) )
		cList += "K3 > " + num2str( t1_min ) + ";"
	endif
	
	if ( ( numtype( t1_max ) == 0 ) && ( t1_max > 0 ) )
		cList += "K3 < " + num2str( t1_max ) + ";"
	endif
	
	if ( StringMatch( dcayFxn, "2exp" ) )
		
		if ( ( numtype( t2_min ) == 0 ) && ( t2_min > 0 ) )
			cList += "K5 > " + num2str( t2_min ) + ";"
		endif
		
		if ( ( numtype( t2_max ) == 0 ) && ( t2_max > 0 ) )
			cList += "K5 < " + num2str( t2_max ) + ";"
		endif
	
	endif
	
	items = ItemsInList( cList )
	
	if ( items == 0 )
		return 0
	endif
	
	Redimension /N=( items ) cwave
	
	for ( icnt = 0 ; icnt < items ; icnt += 1 )
		cwave[ icnt ] = StringFromList( icnt, cList )
	endfor
	
	return 0

End // z_Constraints

//****************************************************************
//****************************************************************

Function NMArtFitSubtract( [ update ] )
	Variable update

	Variable pcnt, pbgn, pend

	String df = NMArtDF
	
	Variable tbgn = NumVarOrDefault( df + "Xbgn", NaN ) // drag wave variable
	Variable tend = NumVarOrDefault( df + "Xend", NaN )

	Wave wtempNoStim = $NMArtSubWaveName( "nostim" )
	Wave wtempStim = $NMArtSubWaveName( "stim" )
	Wave wtemp = $ChanDisplayWave( -1 )
	
	Wave AT_fit = $( df+"AT_fit" )
	Wave AT_fitb = $( df+"AT_fitb" )
	Wave AT_ArtSubFin = $( df+"AT_ArtSubFin" )
	
	Variable StimNum = NumVarOrDefault( df+"StimNum", NaN )
	Variable StimTime = NumVarOrDefault( df+"StimTime", NaN )
	Variable BslnDT = NumVarOrDefault( df+"BslnDT", NaN )
	Variable SbtrctWin = NumVarOrDefault( df+"SbtrctWin", NaN )
	
	if ( numtype( StimNum * StimTime * BslnDT * SbtrctWin ) > 0 )
		return -1
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	// zero stim artifact
	
	pbgn = x2pnt( wtempNoStim, StimTime - BslnDT )
	pend = x2pnt( wtempNoStim, tbgn ) - 1

	for ( pcnt = pbgn; pcnt <= pend; pcnt += 1 )
		wtempNoStim[pcnt] = AT_fitb[pcnt] // artifact before tbgn becomes baseline
	endfor
	
	// subtract exponential fit and baseline fit
	
	pbgn = x2pnt( wtempNoStim, tbgn )
	pend = x2pnt( wtempNoStim, StimTime + SbtrctWin )

	for ( pcnt = pbgn; pcnt < pend; pcnt += 1 )
		wtempNoStim[pcnt] = wtemp[pcnt] - ( AT_fit[pcnt] - AT_fitb[pcnt] )
	endfor
	
	if ( stimNum < numpnts( AT_ArtSubFin ) )
		AT_ArtSubFin[StimNum] = 1
	endif
	
	wtempStim = wtemp - wtempNoStim
	
	if ( update )
		DoUpdate
	endif
	
	return 0

End // NMArtFitSubtract

//****************************************************************
//****************************************************************

Function NMArtRestore()

	Variable pcnt, pbgn, pend
	String df = NMArtDF
	
	Variable StimNum = NumVarOrDefault( df+"StimNum", NaN )
	Variable StimTime = NumVarOrDefault( df+"StimTime", NaN )
	Variable BslnDT = NumVarOrDefault( df+"BslnDT", NaN )
	Variable SbtrctWin = NumVarOrDefault( df+"SbtrctWin", NaN )
	
	if ( numtype( StimNum * StimTime * BslnDT * SbtrctWin ) > 0 )
		return -1
	endif
	
	if ( !WaveExists( $( df+"AT_ArtSubFin" ) ) )
		return -1
	endif

	Wave wtempNoStim = $NMArtSubWaveName( "nostim" )
	Wave oWave = $ChanDisplayWave( -1 )
	Wave AT_ArtSubFin = $( df+"AT_ArtSubFin" )
	
	pbgn = x2pnt( wtempNoStim, StimTime - BslnDT )
	pend = x2pnt( wtempNoStim, StimTime + SbtrctWin )

	for ( pcnt = pbgn; pcnt <= pend; pcnt += 1 )
		wtempNoStim[pcnt] = oWave[pcnt]
	endfor
	
	AT_ArtSubFin[ StimNum ] = 0

End // NMArtRestore

//****************************************************************
//****************************************************************

Function NMArtFxnLine( w, x )
	Wave w // 2 points
	// w[0] = offset b
	// w[1] = slope m
	Variable x
	
	return ( w[0] + w[1] * x )

End // NMArtFxnLine

//****************************************************************
//****************************************************************

Function NMArtFxnExp( w, x )
	Wave w // 4 points
	// w[0] = x0
	// w[1] = y0
	// w[2] = a1
	// w[3] = t1
	Variable x
	Variable y, y0
	
	Wave AT_b = $( NMArtDF+"AT_b" ) // baseline values
	
	if ( w[3] < 0 )
		w[3] = -w[3] // keep positive
	endif
	
	switch( numpnts( AT_b ) )
		case 0: // baseline fit does not exist so this is normal exp fit
			y0 = w[1]
			break
		case 1: // baseline is constant
			y0 = AT_b[0]
			break
		case 2: // baseline is line
			y0 = AT_b[0] + AT_b[1] * x
			break
		case 4: // baseline is single exp
			y0 = AT_b[1] + AT_b[2] * exp( -( x - AT_b[0] ) / AT_b[3] )
			break
	endswitch
	
	y = y0 + w[2] * exp( -( x - w[0] )/ w[3] )
	
	return y

End // NMArtFxnExp

//****************************************************************
//****************************************************************

Function NMArtFxnExp2( w, x )
	Wave w // 6 points
	// w[0] = x0
	// w[1] = y0
	// w[2] = a1
	// w[3] = t1
	// w[4] = a2
	// w[5] = t2
	Variable x
	
	Variable y, y0
	Variable a1, t1, a2, t2
	
	Wave AT_b = $( NMArtDF+"AT_b" ) // baseline values
	
	if ( w[3] < 0 )
		w[3] = -w[3]
	endif
	
	if ( w[5] < 0 )
		w[5] = -w[5]
	endif
	
	if ( w[5] < w[3] ) // keep t1 < t2
		
		a1 = w[4]
		t1 = w[5]
		a2 = w[2]
		t2 = w[3]
		
		w[2] = a1
		w[3] = t1
		w[4] = a2
		w[5] = t2
	
	endif
	
	//if ( w[2] * w[4] < 0 ) // a1 and a2 have opposite signs
		//w[4] *= w[2] / abs( w[2] ) // keep the same sign
	//endif
	
	switch( numpnts( AT_b ) )
		case 0: // baseline fit does not exist so this is normal exp fit
			y0 = w[1]
			break
		case 1:
			y0 = AT_b[0]
			break
		case 2:
			y0 = AT_b[0] + AT_b[1] * x
			break
		case 4:
			y0 = AT_b[1] + AT_b[2] * exp( -( x - AT_b[0] ) / AT_b[3] )
			break
	endswitch
	
	y = y0 + w[2] * exp( -( x - w[0] ) / w[3] ) + w[4] * exp( -( x - w[0] ) / w[5] )
	
	return y

End // NMArtFxnExp2

//****************************************************************
//****************************************************************
//
// OLD CODE BELOW
//
//****************************************************************
//****************************************************************

Function xNMArtAuto() // NOT USED

	Variable icnt
	
	String df = NMArtDF

	Variable tableFit = NumVarOrDefault( df+"TableFit", 0 )
	
	Variable CurrentChan = NumVarOrDefault( "CurrentChan", 0 )
	Variable CurrentWave = NumVarOrDefault( "CurrentWave", 0 )
	
	String dName = NMChanWaveName( CurrentChan,CurrentWave )
	
	NMArtWavesCheck()
	
	if ( tableFit )
	
		Wave /T fwave = $( df+"AT_FitWaves" )
		Wave /T twave = $( df+"AT_TimeWaves" )
		
		for ( icnt = 0; icnt < numpnts( fwave ); icnt += 1 )
			if ( StringMatch( fwave[icnt], dname ) == 1 )
				NMArtTimeWaveSet( twave[icnt] )
				break
			endif
		endfor
		
	endif
	
	NMArtDisplay( 1 )
	NMArtUpdate()
	NMArtGoTo( "0" )

End // NMArtAuto

//****************************************************************
//****************************************************************

Function xNMArtStimTimeSet( t ) // NOT USED
	Variable t
	
	String df = NMArtDF
	String wName = StrVarOrDefault( df+"StimTimeWName", "" )
	
	Variable StimNum = NumVarOrDefault( df+"StimNum", 0 )
	
	Wave xwave = $( df+"AT_timeX" )
	Wave ywave = $( df+"AT_timeY" )
	Wave dwave = $ChanDisplayWave( -1 )
	
	if ( WaveExists( $wName ) == 1 )
	
		Wave tWave = $wName
		//twave[StimNum] = t // change original wave
		
	else // manual mode
	
		if ( numpnts( xwave ) < StimNum + 1 )
			Redimension /N=( StimNum + 1 ) xwave, ywave
		endif
		
	endif
	
	xwave[StimNum] = t
	ywave[StimNum] = dwave[x2pnt( dwave, t )]
	
	NMArtStimsCount()
	NMArtStimNumSet( StimNum )

End // NMArtStimTimeSet

//****************************************************************
//****************************************************************

Function xNMArtFitAllTable() // NOT USED

	Variable icnt, jcnt, inum
	String wname, tname, wlist
	
	String df = NMArtDF
	
	if ( ( WaveExists( $( df+"AT_FitWaves" ) ) == 0 ) || ( WaveExists( $( df+"AT_TimeWaves" ) ) == 0 ) )
		return -1
	endif 
	
	Wave /T fwave = $( df+"AT_FitWaves" )
	Wave /T twave = $( df+"AT_TimeWaves" )
	Wave /T chanWList = ChanWaveList
	
	Wave AT_ArtSubFin = $( df+"AT_ArtSubFin" )
	
	Variable stimNum = NumVarOrDefault( df+"StimNum", 0 )
	Variable saveNum = NumVarOrDefault( "CurrentWave", 0 )
	
	wlist = chanWList[NumVarOrDefault( "CurrentChan", 0 )]
	
	for ( jcnt = 0; jcnt < numpnts( fwave ); jcnt += 1 )
	
		wname = fwave[jcnt]
		tname = twave[jcnt]
		
		if ( ( strlen( wname ) == 0 ) || ( strlen( tname ) == 0 ) )
			continue
		endif
		
		inum = WhichListItem( wname, wlist )
		
		if ( inum == -1 )
			continue
		endif
		
		SetNMvar( "CurrentWave", inum )
		UpdateCurrentWave()
		
		NMArtTimeWaveSet( tname )
		
		xNMArtAuto()
		NMArtReset()
		NMArtUpdate()
		
		for ( icnt = 0; icnt < numpnts( AT_ArtSubFin ); icnt += 1 )
	
			if ( AT_ArtSubFin[icnt] == 0 )
				NMArtStimNumSet( icnt, doFit = 1 )
				DoUpdate
			endif
		
		endfor
		
		print "Art Subtracted " + wname + " : N = " + num2str( icnt )
		
	endfor
	
	//SetNMvar( "CurrentWave", saveNum )
	//UpdateCurrentWave()
	
	//NMArtStimNumSet( stimNum )

End // NMArtFitAllTable

//****************************************************************
//****************************************************************

Function xNMArtTable( mode ) // NOT USED
	Variable mode
	
	String tname = "AT_FitTable"
	String df = NMArtDF
	
	if ( mode == 0 )
		DoWindow /K $tname
		return 0
	endif
	
	CheckNMtwave( df+"AT_FitWaves", 10, "" )
	CheckNMtwave( df+"AT_TimeWaves", 10, "" )
	
	if ( Wintype( tname ) == 0 )
		Wave fwaves = $( df+"AT_FitWaves" )
		Wave twaves = $( df+"AT_TimeWaves" )
		DoWindow /K $tname
		Edit /K=1/W=( 0,0,0,0 ) fwaves, twaves as "Art Subtract Table"
		DoWindow /C $tname
		SetCascadeXY( tname )
	endif
	
	DoWindow /F $tname
	
End // NMArtTable

//****************************************************************
//****************************************************************

Function xNMArtImpulseMake() // NOT USED

	Variable icnt, tbgn, pmin, pmax, t, t2peak, dt, vmax
	String tName = "ArtTemplate"
	
	String df = NMArtDF
	
	String wname = ChanDisplayWave( -1 )
	
	if ( ( strlen( wname ) == 0 ) || ( WaveExists( $wname ) == 0 ) )
		return 0
	endif
	
	if ( WaveExists( $tName ) == 0 )
		xNMArtTemplateSave( 0 )
	endif
	
	WaveStats /Q $tName
	
	dt = x2pnt( $tName, V_maxloc ) - x2pnt( $tName, V_minloc )
	
	t2peak = xNMArtMinAlignment( dt )
	
	Wave xwave = $( df+"AT_timeX" )
	Wave oWave = $wname
	
	Duplicate /O oWave ArtImpulse
	
	ArtImpulse = 0
	
	WaveStats /Q $tName
	
	vmax = V_max
	
	for ( icnt = 0; icnt < numpnts( xwave ); icnt += 1 )
	
		tbgn = xwave[icnt]
		
		if ( numtype( tbgn ) > 0 )
			continue
		endif
	
		WaveStats /Q/R=( tbgn, tbgn + 0.4 ) oWave
		
		pmin = x2pnt( oWave, V_minloc )
		pmax = x2pnt( oWave, V_maxloc )
		
		if ( ( pmax - pmin != dt ) || ( V_max < vmax - 50 ) )
			//print "peak mismatch " + wname + ": skipped stim time", tbgn
			//continue
		endif
		
		ArtImpulse[pmax - t2peak] = 1
	
	endfor
	
End // NMArtImpulseMake

//****************************************************************
//****************************************************************

Function xNMArtMinAlignment( dt ) // determine min time to peak ( tmax - tstim ) // NOT USED
	Variable dt
	
	Variable icnt, p0, pmin, pmax, tbgn, minalign = 999
	String df = NMArtDF

	Wave xwave = $( df+"AT_timeX" )
	Wave oWave = $ChanDisplayWave( -1 )
	
	String tName = "ArtTemplate"
	
	for ( icnt = 0; icnt < numpnts( xwave ); icnt += 1 )
	
		tbgn = xwave[icnt]
	
		WaveStats /Q/R=( tbgn, tbgn + 0.4 ) oWave
		
		p0 = x2pnt( $tName, tbgn )
		pmin = x2pnt( $tName, V_minloc )
		pmax = x2pnt( $tName, V_maxloc )
		
		if ( pmax - pmin != dt )
			continue
		endif
		
		if ( pmax - p0 < minalign )
			minalign = pmax - p0
		endif
		
	endfor
	
	return minalign

End // NMArtMinAlignment

//****************************************************************
//****************************************************************

Function xNMArtTemplateSave( flag ) // NOT USED
	Variable flag // ( -1 ) reset counter ( 0 ) save to template avg
	
	Variable dt
	
	String df = NMArtDF
	
	String wName = NMArtSubWaveName( "stim" )
	String tName = "ArtTemplate"
	
	if ( ( strlen( wname ) == 0 ) || ( WaveExists( $wname ) == 0 ) )
		return 0
	endif
	
	switch( flag )
		default:
			return -1
		case -1:
			KillWaves /Z ArtTemplate
			SetNMvar( df+"TemplateN", 0 )
			return 0
		case 0:
			break
	endswitch

	Wave stimWave = $wName
	
	Variable SbtrctWin = NumVarOrDefault( df+"SbtrctWin", 0 )
	Variable TemplateN = NumVarOrDefault( df+"TemplateN", 0 )
	
	Variable tbgn = NumVarOrDefault( df+"StimTime", 0 )
	Variable tend = tbgn + SbtrctWin
	
	dt = deltax( stimWave )
	
	Duplicate /O/R=( tbgn, tend ) stimWave, ArtTemplateTemp
	Setscale /P x 0, dt, ArtTemplateTemp
	
	if ( WaveExists( $tName ) == 0 )
		Duplicate /O/R=( tbgn, tend ) stimWave, ArtTemplate
		Setscale /P x 0, dt, ArtTemplate
		TemplateN = 0
	endif
	
	ArtTemplate = ( ( ArtTemplate * TemplateN ) + ArtTemplateTemp ) / ( TemplateN + 1 )
	
	SetNMvar( df+"TemplateN", TemplateN + 1 )
	
	KillWaves /Z ArtTemplateTemp

End // NMArtTemplateSave

//****************************************************************
//****************************************************************

Function xNMArtBump() // NOT USED

	Variable m, b, dx = 0.4
	
	String wName = NMArtSubWaveName( "nostim" )
	
	if ( ( strlen( wname ) == 0 ) || ( WaveExists( $wname ) == 0 ) )
		return 0
	endif
	
	DoWindow /F ChanA

	Wave stimWave = $NMArtSubWaveName( "stim" )
	
	Variable pbgn = pcsr( B )
	Variable pend = xcsr( B ) + dx
	
	pend = x2pnt( stimWave, pend )
	
	Duplicate /O $wName, nostimTemp, lineTemp
	
	m = ( 0 - 1 ) / ( pend - pbgn )
	
	b = - ( m * pend )
	
	lineTemp = p * m + b
	
	lineTemp[0,pbgn] = 0
	lineTemp[pend,inf] = 0
	
	nostimTemp[0,pbgn] = 0
	nostimTemp[pend,inf] = 0
	
	stimWave += nostimTemp * lineTemp
	
	KillWaves /Z lineTemp, nostimTemp

End // xNMArtBump

//****************************************************************
//****************************************************************


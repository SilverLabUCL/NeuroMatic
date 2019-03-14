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
//	Stimulus Artefact Subtraction
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
// "PN" - artefact ends with large positive peak followed by small negative peak
// "NP" - artefact ends with large negative peak followed by small positive peak

Static StrConstant BslnFxn = "avg" // baseline function to compute within bslnWin:
// "avg" - baseline is average value, i.e. line with zero slope
// "line" - fits a line to baseline data; use if your baseline is not always flat
// "exp" - fits an 1-exp to baseline data; use if your baseline has exp decay
// "zero" - baseline is zero

Static Constant BslnWin = 1.5 // baseline window size; baseline is computed immediately before stim artefact time
Static Constant BslnDT = 0 // optional baseline time shift negative from stim time, 0 - no time shift

Static StrConstant DecayFxn = "2exp" // "exp" or "2exp"

Static Constant DecayWin = 0.2 // fit window size
Static Constant SubtractWin = 2 // subtraction window
// SubtractWin should include extrapolation after DecayWin to allow decay to fall back to baseline

//****************************************************************
//****************************************************************

Static StrConstant NMArtDF = "root:Packages:NeuroMatic:Art:"

//****************************************************************
//****************************************************************

Function /S NMTabPrefix_Art()
	
	return "AT_"
	
End // NMTabPrefix_Art

//****************************************************************
//****************************************************************

Function NMArtTab( enable )
	Variable enable // ( 0 ) disable ( 1 ) enable tab
	
	if ( enable )
	
		CheckPackage( "Art", 0 ) // declare globals if necessary
		NMArtCheck()
		NMArtWavesCheck()
		NMArtMake( 0 ) // make tab controls if necessary
		NMArtUpdate()
		
		if ( WaveExists( $NMArtSubWaveName( "nostim" ) ) )
			NMArtTimeWaveSet( "" ) // update
			NMArtStimNumSet( -1 ) // update
		endif
		
	endif
	
	if ( DataFolderExists( NMArtDF ) )
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
			if ( DataFolderExists( df ) )
			//	KillDataFolder $df
			endif
			break
	endswitch

End // NMArtTabKill

//****************************************************************
//****************************************************************

Function NMArtCheck() // check globals

	String df = NMArtDF
	
	if ( !DataFolderExists( df ) )
		return 0 // Art folder does not exist
	endif
	
	// panel control parameters
	
	CheckNMVar( df+"NumStims", 0 )
	CheckNMVar( df+"StimNum", 0 )
	CheckNMVar( df+"StimTime", NaN )
	
	CheckNMVar( df+"BslnValue1", Nan )
	CheckNMVar( df+"BslnValue2", Nan )
	CheckNMVar( df+"DcayValue1", Nan )
	CheckNMVar( df+"DcayValue2", Nan )
	
	CheckNMVar( df+"AutoFit", 1 )
	CheckNMVar( df+"FitFlag", NaN )
	
	CheckNMStr( df+"StimTimeWName", "" )
	
	// drag wave variables
	
	CheckNMVar( df+"BslnXbgn", NaN )
	CheckNMVar( df+"BslnXend", NaN )
	CheckNMVar( df+"Xbgn", NaN )
	CheckNMVar( df+"Xend", NaN )
	
	// fit variables
	
	CheckNMStr( df+"BslnFxn", BslnFxn )
	CheckNMVar( df+"BslnDT", BslnDT )
	CheckNMVar( df+"BslnWin", BslnWin )
	
	CheckNMStr( df+"ArtShape", ArtShape )
	CheckNMStr( df+"DecayFxn", DecayFxn )
	CheckNMVar( df+"ArtWidth", ArtWidth )
	CheckNMVar( df+"DecayWin", DecayWin )
	CheckNMVar( df+"SubtractWin", SubtractWin )
	
	// channel display waves
	
	CheckNMWave( df+"AT_Display", 0, Nan )
	
	CheckNMWave( df+"AT_Fit", 0, Nan ) // exp fit
	CheckNMWave( df+"AT_FitB", 0, Nan ) // baseline fit
	CheckNMWave( df+"AT_FitX", 0, Nan ) // fit x times
	
	CheckNMWave( df+"AT_TimeX", 0, Nan )
	CheckNMWave( df+"AT_TimeY", 0, Nan )
	
	// fit parameter waves
	
	CheckNMWave( df+"AT_A", 0, Nan ) // decay
	CheckNMWave( df+"AT_B", 0, Nan ) // baseline
	
End // NMArtCheck

//****************************************************************
//****************************************************************

Function NMArtWavesCheck( [ forceMake ] )
	Variable forceMake

	String df = NMArtDF
	
	String wName = CurrentNMWaveName()
	String dwName = ChanDisplayWave( -1 )
	String noStimName = NMArtSubWaveName( "nostim" )
	String stimName = NMArtSubWaveName( "stim" )
	
	Variable thisIsAnArtWave = StringMatch( wName[ 0, 2 ], "AT_" )
	
	if ( thisIsAnArtWave )
		return 0 // do not work with Art waves if they are selected
	endif
	
	if ( !WaveExists( $dwName ) )
		return 0
	endif
	
	if ( !forceMake && WaveExists( $noStimName ) )
		return 0
	endif
	
	Duplicate /O $dwname $noStimName
	Duplicate /O $dwname $stimName
	Duplicate /O $dwname $df+"AT_Fit"
	Duplicate /O $dwname $df+"AT_FitB"
	Duplicate /O $dwname $df+"AT_FitX"
	
	Wave wtemp = $stimName
	Wave fit = $df+"AT_Fit"
	Wave fitb = $df+"AT_FitB"
	Wave fitx = $df+"AT_FitX"
	
	wtemp = 0
	fit = Nan
	fitb = Nan
	fitx = x

End // NMArtWavesCheck

//****************************************************************
//****************************************************************

Function NMArtConfigs()
	
	NMConfigVar( "Art", "ArtWidth", ArtWidth, "approx artefact width", "" )
	NMConfigStr( "Art", "ArtShape", ArtShape, "artefact end polarity, Pos-Neg or Neg-Pos", "PN;NP;" )
	
	NMConfigVar( "Art", "t1_hold", NaN, "fit hold value of t1", "" )
	NMConfigVar( "Art", "t1_min", 0, "t1 min value", "" )
	NMConfigVar( "Art", "t1_max", NaN, "t1 max value", "" )
	NMConfigVar( "Art", "t2_hold", NaN, "fit hold value of t2", "" )
	NMConfigVar( "Art", "t2_min", 0, "t2 min value", "" )
	NMConfigVar( "Art", "t2_max", NaN, "t2 max value", "" )
	
	
	NMConfigStr( "Art", "BaseColor", NMGreenStr, "baseline display color", "RGB" )
	NMConfigStr( "Art", "DecayColor", NMRedStr, "decay display color", "RGB" )
	
	NMConfigVar( "Art", "DisplayPrecision", 2, "decimal numbers to display", "" )
	
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
			
		case "StimNum":
			defaultVal = 0
			break
			
		case "BslnWin":
			defaultVal = BslnWin
			break
			
		case "BslnDT":
			defaultVal = BslnDT
			break
			
		case "DecayWin":
			defaultVal = DecayWin
			break
			
		case "SubtractWin":
			defaultVal = SubtractWin
			break
			
		case "AutoFit":
			defaultVal = 1
			break
			
		case "FitFlag":
			defaultVal = NaN
			break
	
		case "StimTime":
		case "t1_hold":
		case "t1_min":
		case "t1_max":
		case "t2_hold":
		case "t2_min":
		case "t2_max":
			break // NaN
			
		default:
			NM2Error( 13, varName, "" )
			return NaN
	
	endswitch
	
	return NumVarOrDefault( NMArtDF+varName, defaultVal )
	
End // NMArtVarGet

//****************************************************************
//****************************************************************

Function /S NMArtStrGet( varName )
	String varName
	
	String defaultVal = ""
	
	strswitch( varName )
	
		case "ArtShape":
			defaultVal = ArtShape
			break
	
		case "BslnFxn":
			defaultVal = BslnFxn
			break
	
		case "DecayFxn":
			defaultVal = DecayFxn
			break
			
		case "DecayColor":
			defaultVal = NMRedStr
			break
			
		case "BaseColor":
			defaultVal = NMGreenStr
			break
			
		case "StimTimeWName":
			break
			
		default:
			NM2Error( 23, varName, "" )
			return ""
	
	endswitch
	
	return StrVarOrDefault( NMArtDF+varName, defaultVal )
	
End // NMArtStrGet

//****************************************************************
//****************************************************************

Function /S NMArtSubWaveName( wtype )
	String wtype
	
	String wName = CurrentNMWaveName()
	
	if ( strlen( wName ) == 0 )
		return ""
	endif
	
	if ( StringMatch( wtype, "finished" ) )
		return "AT_F_" + wName
	else
		return "AT_" + wName + "_" + wtype
	endif

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
	
	NMColorList2RGB( NMArtStrGet( "DecayColor" ), ac )
	NMColorList2RGB( NMArtStrGet( "BaseColor" ), bc )
	
	if ( !DataFolderExists( df ) || !WaveExists( $df+"AT_Display" ) )
		return 0 // Art has not been initialized yet
	endif
	
	if ( Wintype( gName ) == 0 )
		return -1 // window does not exist
	endif
	
	String wName = df+"AT_Display"
	
	if ( !NMVarGet( "DragOn" ) || !StringMatch( CurrentNMTabName(), "Art" ) )
		drag = 0
	endif
	
	RemoveFromGraph /Z/W=$gName AT_Display, AT_Fit, AT_FitB, AT_TimeY
	RemoveFromGraph /Z/W=$gName DragBgnY, DragEndY
	RemoveFromGraph /Z/W=$gName DragBslnBgnY, DragBslnEndY
	
	if ( appnd )

		AppendToGraph /W=$gName $df+"AT_Display"
		
		if ( WaveExists( $df+"AT_Fit" ) )
			AppendToGraph /W=$gName $df+"AT_FitB", $df+"AT_Fit"
		endif
		
		if ( WaveExists( $df+"AT_TimeX" ) )
			AppendToGraph /W=$gName $df+"AT_TimeY" vs $df+"AT_TimeX"
		endif
		
		ModifyGraph /W=$gName rgb( AT_Display )=( 0,0,65280 ), lsize( AT_Display )=2
		
		ModifyGraph /W=$gName mode( AT_TimeY )=3, marker( AT_TimeY )=10, rgb( AT_TimeY )=( 65280,0,0 ), msize( AT_TimeY )=20, mrkThick( AT_TimeY )=2
		ModifyGraph /W=$gName mode( AT_FitB )=0, lsize( AT_FitB )=2, rgb( AT_FitB )=( bc.r, bc.g, bc.b )
		
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
	
	Variable stimTime = NMArtVarGet( "StimTime" )
	Variable autoFit = NMArtVarGet( "AutoFit" )
	
	Variable rflag = NMDragTrigger( offsetStr, callAutoTab = 0 )
	
	if ( rflag < 0 )
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
			
		 SetNMvar( df+"DecayWin", win )

			break
	
		case "DragBslnBgnY":
		case "DragBslnEndY":
		
			tbgn = NumVarOrDefault( df + "BslnXbgn", NaN )
			tend = NumVarOrDefault( df + "BslnXend", NaN )
			
			if ( numtype( tbgn * tend ) > 0 )
				return -1
			endif
			
			win = tend - tbgn
			dt = stimTime - tend
			
			SetNMvar( df+"BslnWin", win )
			SetNMvar( df+"BslnDT", dt )
			
			break
	
	
	endswitch
	
	if ( autoFit )
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
	
	if ( !DataFolderExists( df ) )
		return 0 // Art tab has not been initialized yet
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
	SetVariable AT_BslnVal1, value=$df+"BslnValue1", limits={-inf,inf,0}, frame=0
	
	SetVariable AT_BslnVal2, title="t :", pos={x0+155,y0+2}, size={70,50}, fsize = 12
	SetVariable AT_BslnVal2, value=$df+"BslnValue2", limits={-inf,inf,0}, frame=0
	
	SetVariable AT_BslnDT, title="-dt:", pos={x0,y0+yinc}, size={100,50}, fsize = 12
	SetVariable AT_BslnDT, value=$df+"BslnDT", proc=NMArtSetVar
	
	SetVariable AT_BslnWin, title="win:", pos={x0+xinc,y0+yinc}, size={100,50}, fsize = 12
	SetVariable AT_BslnWin, value=$df+"BslnWin", proc=NMArtSetVar
	
	y0 += 100
	
	GroupBox AT_FitGrp, title = "Decay", pos={x0-20,y0-25}, size={260,90}
	
	PopupMenu AT_FitFxn, pos={x0+10,y0}, bodywidth=60
	PopupMenu AT_FitFxn, value="", proc=NMArtPopup
	
	SetVariable AT_FitVal1, title="a :", pos={x0+80,y0+2}, size={70,50}, fsize = 12
	SetVariable AT_FitVal1, value=$df+"DcayValue1", limits={-inf,inf,0}, frame=0, proc=NMArtSetVar
	
	SetVariable AT_FitVal2, title="t :", pos={x0+155,y0+2}, size={70,50}, fsize = 12
	SetVariable AT_FitVal2, value=$df+"DcayValue2", limits={-inf,inf,0}, frame=0, proc=NMArtSetVar
	
	SetVariable AT_FitWin, title="fit win:", pos={x0,y0+yinc}, size={100,50}, fsize = 12
	SetVariable AT_FitWin, value=$df+"DecayWin", proc=NMArtSetVar
	
	SetVariable AT_SubWin, title="sub win:", pos={x0+xinc-10,y0+yinc}, size={110,50}, fsize = 12
	SetVariable AT_SubWin, value=$df+"SubtractWin", proc=NMArtSetVar
	
	y0 += 100
	
	GroupBox AT_TimeGrp, title = "Time", pos={x0-20,y0-25}, size={260,115}
	
	PopupMenu AT_TimeWave, pos={x0+140,y0}, bodywidth=190, proc=NMArtPopup
	PopupMenu AT_TimeWave, value=""
	
	SetVariable AT_NumStims, title=":", pos={x0+195,y0}, size={40,50}, limits={0,inf,0}
	SetVariable AT_NumStims, value=$df+"NumStims", fsize=12, frame=0, noedit=1
	
	SetVariable AT_StimNum, title=" ", pos={x0+90,y0+1*yinc}, size={50,50}, limits={0,inf,0}
	SetVariable AT_StimNum, value=$df+"StimNum", fsize = 12, proc=NMArtSetVar
	
	Button AT_FirstStim, pos={x0+90-80,y0+1*yinc}, title = "<<", size={30,20}, proc=NMArtButton
	Button AT_PrevStim, pos={x0+90-40,y0+1*yinc}, title = "<", size={30,20}, proc=NMArtButton
	Button AT_NextStim, pos={x0+150,y0+1*yinc}, title = ">", size={30,20}, proc=NMArtButton
	Button AT_LastStim, pos={x0+150+40,y0+1*yinc}, title = ">>", size={30,20}, proc=NMArtButton
	
	SetVariable AT_StimTime, title="t :", pos={x0+50,y0+2*yinc-8}, size={70,50}, fsize = 12
	SetVariable AT_StimTime, value=$df+"StimTime", frame=0, limits={-inf,inf,0}, noedit=1
	
	Checkbox AT_Subtract, title="subtract", pos={x0+50+80,y0+2*yinc-6}, size={100,50}, value=1, fsize = 12, proc=NMArtCheckbox
	
	y0 += 105
	x0 -= 5
	xinc = 80
	
	Button AT_Reset, pos={x0,y0}, title = "Reset", size={70,20}, proc=NMArtButton
	Button AT_StimFit, pos={x0+1*xinc,y0}, title = "Fit", size={70,20}, proc=NMArtButton
	Button AT_StimFitAll, pos={x0+2*xinc,y0}, title = "Fit All", size={70,20}, proc=NMArtButton
	
	Checkbox AT_AutoFit, title="auto fit", pos={x0+xinc+20,y0+yinc}, size={100,50}, value=1, fsize = 12, proc=NMArtCheckbox
	
End // NMArtMake

//****************************************************************
//****************************************************************

Function NMArtUpdate()

	Variable md, dt, lx, rx
	String wList, df = NMArtDF

	String dName = ChanDisplayWave( -1 )
	
	String bslnFxn = NMArtStrGet( "BslnFxn" )
	String decayFxn = NMArtStrGet( "DecayFxn" )
	String twName = NMArtStrGet( "StimTimeWName" )
	
	Variable autoFit = NMArtVarGet( "AutoFit" )
	Variable t1_hold = NMArtVarGet( "t1_hold" )
	Variable t2_hold = NMArtVarGet( "t2_hold" )
	
	String formatStr = z_PrecisionStr()
	
	md = WhichListItem( bslnFxn, "avg;line;exp;zero;" ) + 1
	PopupMenu AT_BslnFxn, win=NMPanel, value ="avg;line;exp;zero;", mode=md
	
	strswitch( bslnFxn )
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
	
	md = WhichListItem( decayFxn, "exp;2exp;" ) + 1
	PopupMenu AT_FitFxn, win=NMPanel, value="exp;2exp;", mode=md
	
	SetVariable AT_FitVal1, win=NMPanel, format = z_PrecisionStr()
	SetVariable AT_FitVal2, win=NMPanel, format = z_PrecisionStr()
	
	strswitch( decayFxn )
	
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
	
	md = WhichListItem( twName, wList )
	
	if ( md < 0 )
		md = 1
	else
		md += 3
	endif
	
	PopupMenu AT_TimeWave, win=NMPanel, value="Select Wave of Stim Times;---;" + NMArtTimeWaveList(), mode=md
	
	if ( WaveExists( $dName ) )
	
		dt = deltax( $dName )
		lx = leftx( $dName )
		rx = rightx( $dName )
		
		SetVariable AT_BslnDT, win=NMPanel, limits={0,inf,dt}
		SetVariable AT_BslnWin, win=NMPanel, limits={lx,rx,dt}
		SetVariable AT_FitWin, win=NMPanel, limits={0,inf,dt}
		SetVariable AT_SubWin, win=NMPanel, limits={0,inf,dt}
		
	endif
	
	SetVariable AT_StimTime, win=NMPanel, format = z_PrecisionStr()
	
	Checkbox AT_AutoFit, win=NMPanel, value=autoFit
	
	z_UpdateCheckboxSubtract()

End // NMArtUpdate

//****************************************************************
//****************************************************************

Static Function z_UpdateCheckboxSubtract()

	if ( z_StimFinished() == 1 )
		Checkbox AT_Subtract, win=NMPanel, title="subtracted", disable=0, value=1
	elseif ( NMArtVarGet( "FitFlag" ) == 2 )
		Checkbox AT_Subtract, win=NMPanel, title="subtract", disable=0, value=0
	else
		Checkbox AT_Subtract, win=NMPanel, title="subtract", disable=2, value=0
	endif
	
End // z_UpdateCheckboxSubtract

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
	String xWaveOrFolder = CurrentNMSpikeRasterOrFolder()

	String wList = WaveList( "*",";","" )
	String wListSP = WaveList( "SP_*",";","" )
	String cList = WaveList( currentWavePrefix + "*",";","" )
	String aList = WaveList( "AT_*stim",";","" ) + WaveList( "AT_F_*",";","" )
	
	wList = RemoveFromList( cList, wList )
	wList = RemoveFromList( "FileScaleFactors;yLabel;", wList )
	wList = RemoveFromList( wListSP, wList )
	wList = RemoveFromList( aList, wList )
	
	wList = wListSP + wList
	
	if ( DataFolderExists( xWaveOrFolder ) )
	
		if ( ItemsInList( wList ) > 0 )
			wList += "---;"
		endif
		
		wList += xWaveOrFolder
		
	endif
	
	return wList

End NMArtTimeWaveList

//****************************************************************
//****************************************************************

Function NMArtPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	Variable rflag
	String df = NMArtDF
	
	Variable autoFit = NMArtVarGet( "AutoFit" )
	
	strswitch( ctrlName )
	
		case "AT_TimeWave":
		
			if ( WaveExists( $popStr ) )
				rflag = NMArtTimeWaveSet( popStr )
			elseif ( DataFolderExists( popStr ) )
				rflag = NMArtTimeWaveSet( popStr )
			else
				autoFit = 0
			endif
			
			if ( rflag > 0 )
				NMArtWavesCheck()
				NMArtStimNumSet( 0 )
			else
				autoFit = 0
			endif
			
			break
			
		case "AT_BslnFxn":
			SetNMstr( df+"BslnFxn", popStr )
			SetNMvar( df+"BslnValue1", Nan )
			SetNMvar( df+"BslnValue2", Nan )
			break
			
		case "AT_FitFxn":
			SetNMstr( df+"DecayFxn", popStr )
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
	
		case "AT_Subtract":
			if ( checked )
				NMArtFitSubtract()
			else
				NMArtRestore()
			endif
			break
			
		case "AT_AutoFit":
			SetNMvar( df+"AutoFit", checked )
			break
			
	endswitch

End // NMArtCheckbox

//****************************************************************
//****************************************************************

Function NMArtSetVar( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	String df = NMArtDF
	
	strswitch( ctrlName )
	
		case "AT_FitVal1":
			z_SetTauHold( 1, varNum )
			break
			
		case "AT_FitVal2":
			z_SetTauHold( 2, varNum )
			break
	
		//case "AT_StimTime":
			//NMArtStimTimeSet( varNum )
			//break
			
		case "AT_BslnDT":
		case "AT_BslnWin":
		case "AT_SubWin":
		case "AT_FitWin":
			NMArtStimNumSet( -1 )
			break
		
		case "AT_StimNum":
			NMArtStimNumSet( varNum )
			break
			
	endswitch
	
End // NMArtSetVar

//****************************************************************
//****************************************************************

Static Function z_SetTauHold( select, holdValue )
	Variable select, holdValue
	
	String df = NMArtDF
	
	String decayFxn = NMArtStrGet( "DecayFxn" )
	
	if ( ( numtype( holdValue ) > 0 ) || ( holdValue <= 0 ) )
		holdValue = NaN
	endif
	
	if ( StringMatch( decayFxn, "exp" ) )
		if ( select == 2 )
			NMConfigVarSet( "Art", "t1_hold", holdValue )
			NMHistory( "Art t1_hold = " + num2str( holdValue ) )
		endif
	elseif ( StringMatch( decayFxn, "2exp" ) )
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
			
		//case "AT_StimSubtract":
			//NMArtFitSubtract()
			//break
			
		//case "AT_StimRestore": // undo
			//NMArtRestore()
			//break
			
		case "AT_FirstStim":
			NMArtStimNumSet( 0 )
			break
			
		case "AT_PrevStim":
			NMArtStimNumSet( NMArtVarGet( "StimNum" ) - 1 )
			break
			
		case "AT_NextStim":
			NMArtStimNumSet( NMArtVarGet( "StimNum" ) + 1 )
			break
			
		case "AT_LastStim":
			NMArtStimNumSet( inf )
			break
	
	endswitch

End // NMArtButton

//****************************************************************
//****************************************************************

Function NMArtAuto()
	
	NMArtWavesCheck()
	
	if ( WaveExists( $NMArtSubWaveName( "nostim" ) ) )
		NMArtTimeWaveSet( "" )
		NMArtStimNumSet( 0 )
	endif

End // NMArtAuto

//****************************************************************
//****************************************************************

Function NMArtReset()

	String df = NMArtDF
	String fwName = NMArtSubWaveName( "finished" )

	NMArtWavesCheck( forceMake = 1 )
	
	SetNMvar( df+"FitFlag", NaN )
	SetNMvar( df+"StimTime", NaN )
	SetNMvar( df+"StimNum", 0 )
	
	SetNMvar( df+"BslnValue1", NaN ) // tab display
	SetNMvar( df+"BslnValue2", NaN )
	SetNMvar( df+"DcayValue1", NaN )
	SetNMvar( df+"DcayValue2", NaN )
	
	SetNMvar( df+"fit_a1", NaN )
	SetNMvar( df+"fit_t1", NaN )
	SetNMvar( df+"fit_a2", NaN )
	SetNMvar( df+"fit_t2", NaN )
	
	if ( WaveExists( $fwName ) )
		Wave finished = $fwName
		finished = NaN
	endif
	
	NMArtStimNumSet( 0 )
	
End // NMArtReset

//****************************************************************
//****************************************************************

Function NMArtTimeWaveSet( waveNameOrSpikeSubfolder )
	String waveNameOrSpikeSubfolder // enter "" to update current StimTimeWName
	
	Variable icnt, pnt, t, count, yWaveExists = 0
	String wName, yName = "", wList, df = NMArtDF
	
	Variable currentWave = CurrentNMWave()
	
	String dwName = ChanDisplayWave( -1 )
	String fwName = NMArtSubWaveName( "finished" )
	
	if ( strlen( waveNameOrSpikeSubfolder ) == 0 )
		waveNameOrSpikeSubfolder = NMArtStrGet( "StimTimeWName" )
	endif
	
	if ( WaveExists( $waveNameOrSpikeSubfolder ) )
	
		wName = waveNameOrSpikeSubfolder
		
		Wave wtemp = $wName
		
		for ( icnt = 0 ; icnt < numpnts( wtemp ) ; icnt += 1 )
			if ( numtype( wtemp[ icnt ] ) == 0 )
				count += 1
			endif
		endfor
		
		Make /O/N=( count ) $df+"AT_TimeX" = NaN
		Make /O/N=( count ) $df+"AT_TimeY" = NaN
		
		if ( !WaveExists( $fwName ) || ( DimSize( $fwName, 0 ) != count ) )
			Make /O/N=( count, 2 ) $fwName = NaN
		endif
		
		Wave xwave = $df+"AT_TimeX"
		
		count = 0
		
		for ( icnt = 0 ; icnt < numpnts( wtemp ) ; icnt += 1 )
			if ( numtype( wtemp[ icnt ] ) == 0 )
				xwave[ count ] = wtemp[ icnt ]
				count += 1
			endif
		endfor
		
	elseif ( DataFolderExists( waveNameOrSpikeSubfolder ) )
	
		wList = NMSpikeSubfolderRasterList( waveNameOrSpikeSubfolder, 1, 1 )
		
		if ( ItemsInList( wList ) != 2 )
			return 0
		endif
		
		wName = StringFromList( 0, wList )
		yName = StringFromList( 1, wList )
		
		if ( numpnts( $wName ) != numpnts( $yName ) )
			return 0
		endif
		
		Wave wtemp = $wName
		Wave ytemp = $yName
		
		for ( icnt = 0 ; icnt < numpnts( wtemp ) ; icnt += 1 )
			if ( ( numtype( wtemp[ icnt ] ) == 0 ) && ( ytemp[ icnt ] == currentWave ) )
				count += 1
			endif
		endfor
		
		Make /O/N=( count ) $df+"AT_TimeX" = NaN
		Make /O/N=( count ) $df+"AT_TimeY" = NaN
		
		if ( !WaveExists( $fwName ) || ( DimSize( $fwName, 0 ) != count ) )
			Make /O/N=( count, 2 ) $fwName = NaN
		endif
		
		Wave xwave = $df+"AT_TimeX"
		
		count = 0
		
		for ( icnt = 0 ; icnt < numpnts( wtemp ) ; icnt += 1 )
			if ( ( numtype( wtemp[ icnt ] ) == 0 ) && ( ytemp[ icnt ] == currentWave ) )
				xwave[ count ] = wtemp[ icnt ]
				count += 1
			endif
		endfor
		
	endif
	
	SetNMstr( df+"StimTimeWName", waveNameOrSpikeSubfolder )
	
	Wave xwave = $df+"AT_TimeX"
	Wave ywave = $df+"AT_TimeY"
	
	Wave dtemp = $dwName
	
	for ( icnt = 0; icnt < numpnts( xwave ); icnt += 1 )
		t = xwave[ icnt ]
		pnt = x2pnt( dtemp, t )
		ywave[ icnt ] = dtemp[ pnt ]
	endfor
	
	z_NumStimsCount()
	
	return count
	
End // NMArtTimeWaveSet

//****************************************************************
//****************************************************************

Static Function z_NumStimsCount()

	String df = NMArtDF
	
	if ( ( !WaveExists( $df+"AT_TimeX" ) || ( numpnts( $df+"AT_TimeX" ) == 0 ) ) )
		SetNMvar( df+"NumStims", 0 )
		return 0
	endif
	
	WaveStats /Q $df+"AT_TimeX"

	SetNMvar( df+"NumStims", V_npnts )
	
	return V_npnts

End // z_NumStimsCount()

//****************************************************************
//****************************************************************

Function NMArtStimNumSet( stimNum [ doFit ] )
	Variable stimNum // -1 for current stim number (for update)
	Variable doFit
	
	Variable nmax, finished, t = NaN
	String df = NMArtDF
	
	Variable autoFit = NMArtVarGet( "AutoFit" )
	
	String twName = NMArtStrGet( "StimTimeWName" )
	
	if ( !WaveExists( $df+"AT_TimeX" ) )
		return 0
	endif
	
	Wave xwave = $df+"AT_TimeX"
	Wave AT_Fit = $df+"AT_Fit"
	Wave AT_FitB = $df+"AT_FitB"
	
	AT_Fit = Nan
	AT_FitB = Nan
	
	SetNMvar( df+"FitFlag", NaN )
	
	nmax = z_StimNumMax()
	
	if ( stimNum < 0 )
		stimNum = NMArtVarGet( "StimNum" )
	endif
	
	stimNum = max( stimNum, 0 )
	stimNum = min( stimNum, nmax )
	
	SetNMvar( df+"StimNum", stimNum )
	
	finished = z_StimFinished()
	
	if ( ParamIsDefault( doFit ) )
		doFit = autoFit && !finished
	endif
	
	if ( strlen( twName ) == 0 )
		doFit = 0
	elseif ( stimNum < numpnts( xwave ) )
		t = xwave[ stimNum ]
	endif
	
	z_DisplayTimeSet( stimNum, t )
	
	z_UpdateCheckboxSubtract()
	
	if ( ( numtype( t ) == 0 ) && doFit )
		return NMArtFit()
	endif
	
	return 0
	
End // NMArtStimNumSet

//****************************************************************
//****************************************************************

Static function z_StimFinished()

	Variable stimNum = NMArtVarGet( "StimNum" )

	String fwName = NMArtSubWaveName( "finished" )

	if ( !WaveExists( $fwName ) || ( DimSize( $fwName, 0 ) == 0 ) )
		return 0
	endif
	
	if ( ( stimNum < 0 ) || ( stimNum >= DimSize( $fwName, 0 ) ) )
		return 0
	endif
	
	Wave ftemp = $fwName
		
	return ftemp[ stimNum ][ 1 ] == 1

End // z_StimFinished

//****************************************************************
//****************************************************************

Static function z_StimNumMax()
	
	Variable icnt
	String df = NMArtDF
	
	if ( !WaveExists( $df+"AT_TimeX" ) || ( numpnts( $df+"AT_TimeX" ) == 0 ) )
		return 0
	endif
	
	Wave wtemp = $df+"AT_TimeX"
	
	for ( icnt = numpnts( wtemp ) - 1 ; icnt >= 0 ; icnt -= 1 )
		if ( numtype( wtemp[ icnt ] ) == 0 )
			return icnt
		endif
	endfor
	
	return 0

End // z_StimNumMax

//****************************************************************
//****************************************************************

Static Function z_DisplayTimeSet( stimNum, t ) // called from NMArtStimNumSet
	Variable stimNum
	Variable t // stim time, ( NaN ) to reset
	
	Variable bsln, tpeak, xAxisDelta, yAxisDelta
	Variable bbgn, bend, abgn, aend, dbgn, dend
	Variable pbgn, pend, ybgn, yend, ymin, ymax
	
	String df = NMArtDF
	
	Variable bslnWin = NMArtVarGet( "BslnWin" )
	Variable bslnDT = NMArtVarGet( "BslnDT" )
	Variable subtractWin = NMArtVarGet( "SubtractWin" )
	Variable decayWin = NMArtVarGet( "DecayWin" )
	
	String artShape = NMArtStrGet( "ArtShape" )
	
	String gName = CurrentChanGraphName()
	String dwName = ChanDisplayWave( -1 )
	String noStimName = NMArtSubWaveName( "nostim" )
	
	if ( !WaveExists( $noStimName ) )
	
		if ( WaveExists( $df+"AT_Display" ) )
			Wave dtemp = $df+"AT_Display"
			dtemp = NaN
		endif
		
		if ( WaveExists( $df+"AT_TimeY" ) )
			Wave ytemp = $df+"AT_TimeY"
			ytemp = NaN
		endif
		
		SetNMvar( df+"StimTime", NaN )
		
		NMArtDragClear()
		
		return 0
		
	endif
	 
	if ( numtype( t ) > 0 )
		
		Wave dtemp = $df+"AT_Display"
		
		dtemp = NaN
		
		SetNMvar( df+"StimTime", NaN )
		
		NMArtDragClear()
		
		return 0
		
	endif
	
	SetNMvar( df+"StimTime", t )
	
	Duplicate /O $noStimName $df+"AT_Display"
	
	bbgn = z_BslnBgn()
	bend = z_BslnEnd()
	
	SetNMvar( df + "BslnXbgn", bbgn ) // drag wave variable
	SetNMvar( df + "BslnXend", bend )
	
	WaveStats /Q/R=( bbgn, bend ) $dwname
	
	bsln = V_avg
	
	Wave ytemp = $df+"AT_TimeY"
	
	if ( ( stimNum >= 0 ) && ( stimNum < numpnts( ytemp ) ) )
		ytemp[ stimNum ] = bsln
	endif
	
	abgn = t // artefact window
	aend = t + ArtWidth
	
	WaveStats /Q/R=( abgn, aend ) $dwname
	
	strswitch( artShape )
		case "PN":
			tpeak = V_maxloc // this should be "P"
			break
		case "NP":
			tpeak = V_minloc // this should be "N"
			break
		default:
			return 0
	endswitch
	
	WaveStats /Q/R=( tpeak, aend ) $dwname
	
	strswitch( artShape )
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
	dend = dbgn + decayWin
	
	xAxisDelta = ( bslnDT + bslnWin + subtractWin ) / 4 // for channel display
	
	SetNMvar( df + "Xbgn", dbgn ) // drag wave variable
	SetNMvar( df + "Xend", dend )

	DoWindow /F $gName
	
	SetAxis bottom ( bbgn - xAxisDelta ), ( t + subtractWin + xAxisDelta )
	
	Wave dtemp = $dwName
	
	pbgn = x2pnt( dtemp, dbgn )
	pend = x2pnt( dtemp, dend )
	
	if ( ( pbgn >= 0 ) && ( pbgn < numpnts( dtemp ) ) )
		ybgn = dtemp[ pbgn ]
	endif
	
	if ( ( pend >= 0 ) && ( pend < numpnts( dtemp ) ) )
		yend = dtemp[ pend ]
	endif
	
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

	Variable stimTime = NMArtVarGet( "StimTime" )
	Variable bslnWin = NMArtVarGet( "BslnWin" )
	Variable bslnDT = NMArtVarGet( "BslnDT" )
	
	return stimTime - bslnDT - bslnWin

End // z_BslnBgn

//****************************************************************
//****************************************************************

Static Function z_BslnEnd()

	String df = NMArtDF

	Variable stimTime = NMArtVarGet( "StimTime" )
	Variable bslnDT = NMArtVarGet( "BslnDT" )
	
	return stimTime - bslnDT

End // z_BslnEnd

//****************************************************************
//****************************************************************

Static Function z_FitAllCall()

	Variable vflag
	String df = NMArtDF
	String twName = NMArtStrGet( "StimTimeWName" )
	String title = "NM Art Tab : " + twName
	
	Variable allWaves = 1 + NumVarOrDefault( df + "FitAllWaves", 0 )
	
	Variable numWaves = NMNumActiveWaves()
	
	if ( numWaves == 0 )
		return 0
	endif
	
	if ( strlen( twName ) == 0 )
		return 0
	endif
		
	if ( numWaves == 1 )
	
		vflag = NMDoAlert( "Fit and subtract all stimulus artefacts in the currently selected wave?", title = title, alertType = 1 )
		
		if ( vflag == 2 )
			return -1 // no
		endif
		
		allWaves = 0
	
	elseif ( NMNumActiveWaves() > 1 )
	
		Prompt allwaves, "compute fit and subtraction for:", popup "current wave;all selected waves;"
		DoPrompt NMPromptStr( "NM Art Fit All" ), allWaves
		
		if ( V_flag == 1 )
			return -1 // cancel
		endif
		
		allWaves -= 1
		
		SetNMvar( df + "FitAllWaves", allWaves )
	
	else
	
		return 0
	
	endif
	
	return NMArtFitAll( allWaves = allWaves )
	
End // z_FitAllCall

//****************************************************************
//****************************************************************

Function NMArtFitAll( [ allWaves ] )
	Variable allWaves

	Variable wcnt, wbgn, wend
	Variable icnt, stimTime, numStim, rflag
	String wName, fwName
	
	String df = NMArtDF
	
	Variable currentChan = CurrentNMChannel()
	Variable currentWave = CurrentNMWave()
	Variable numWaves = NMNumWaves()
	
	String twName = NMArtStrGet( "StimTimeWName" ) 
	
	if ( strlen( twName ) == 0 )
		return 0
	endif
	
	if ( allWaves )
		wbgn = 0
		wend = numWaves - 1
	else
		wbgn = currentWave
		wend = currentWave
	endif
	
	for ( wcnt = wbgn ; wcnt <= wend ; wcnt += 1 ) // loop thru waves
	
		wName = NMWaveSelected( currentChan, wcnt )
				
		if ( strlen( wName ) == 0 )
			continue // wave not selected, or does not exist... go to next wave
		endif
		
		if ( allWaves )
			NMCurrentWaveSet( wcnt, update = 0 )
			NMChanGraphUpdate( channel = currentChan, waveNum = wcnt )
			NMArtAuto()
		endif
		
		fwName = NMArtSubWaveName( "finished" )
		
		if ( !WaveExists( $fwName ) )
			continue
		endif
			
		Wave finished = $fwName
		
		numStim = DimSize( finished, 0 )
	
		for ( icnt = 0; icnt < numStim; icnt += 1 )
		
			if ( NMProgress( icnt, numStim, "Art Subtracting stim " + num2istr( icnt ) ) == 1 ) // update progress display
				break // cancel
			endif
		
			if ( finished[ icnt ][ 1 ] == 1 )
				continue
			endif
			
			NMArtStimNumSet( icnt, doFit = 0 )
			
			stimTime = NMArtVarGet( "StimTime" )
			
			if ( numtype( stimTime ) > 0 )
				continue
			endif
			
			NMArtFit()
			
			if ( NMArtVarGet( "FitFlag" ) == 2 )
				NMArtFitSubtract()
			else
				NMHistory( "Art subtract failure : " + wName + " : stim " + num2istr( icnt ) )
			endif
			
		endfor
		
		if ( NMProgressCancel() == 1 )
			break
		endif
	
	endfor
	
	if ( wend != currentWave )
		NMSet( waveNum=currentWave )
	endif
	
	NMArtStimNumSet( 0 )

End // NMArtFitAll

//****************************************************************
//****************************************************************

Function NMArtFit( [ update ] )
	Variable update

	Variable rflag
	String df = NMArtDF

	Variable stimNum = NMArtVarGet( "StimNum" )
	Variable stimTime = NMArtVarGet( "StimTime" )
	
	String twName = NMArtStrGet( "StimTimeWName" )
	String fwName = NMArtSubWaveName( "finished" )
	String gName = CurrentChanGraphName()
	
	SetNMvar( df + "FitFlag", NaN ) // reset fit flag
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( ( strlen( twName ) == 0 ) || !WaveExists( $fwName ) )
		return 0
	endif
	
	if ( numtype( stimTime ) > 0 )
		return 0 // nothing to fit
	endif
	
	if ( ( stimNum < 0 ) || ( stimNum >= DimSize( $fwName, 0 ) ) )
		return 0
	endif
	
	Wave finished = $fwName
	
	finished[ stimNum ][ 0 ] = stimTime
	
	rflag = NMArtFitBsln( update = update )
	
	if ( rflag == 0 )
	
		SetNMvar( df + "FitFlag", 1 ) // baseline fit OK
		
		rflag = NMArtFitDecay( update = update )
		
		if ( rflag == 0 )
			SetNMvar( df + "FitFlag", 2 ) // decay fit OK
		endif
		
	endif
	
	if ( update )
		DoUpdate
	endif
	
	z_UpdateCheckboxSubtract()
	
	return rflag

End // NMArtFit

//****************************************************************
//****************************************************************

Function NMArtFitBsln( [ update ] )
	Variable update

	Variable bbgn, bend, dt, ybgn, yend, pbgn, pend
	Variable v1 = Nan, v2 = Nan
	Variable V_FitError = 0, V_chisq
	 
	String df = NMArtDF
	
	String bslnFxn = NMArtStrGet( "BslnFxn" )
	
	Variable stimTime = NMArtVarGet( "StimTime" )
	Variable subtractWin = NMArtVarGet( "SubtractWin" )
	
	String dwName = ChanDisplayWave( -1 )
	
	if ( !WaveExists( $df+"AT_FitB" ) )
		return NaN
	endif
	
	Wave dtemp = $dwName
	
	Wave AT_A = $df+"AT_A"
	Wave AT_B = $df+"AT_B"
	Wave AT_FitB = $df+"AT_FitB" // channel display wave
	Wave AT_FitX = $df+"AT_FitX" // x-times for fitting
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	bbgn = z_BslnBgn()
	bend = z_BslnEnd()
	
	dt = deltax( dtemp )
	
	WaveStats /Q/R=( bbgn, bbgn + 10 * dt ) dtemp
	
	ybgn = V_avg
	
	WaveStats /Q/R=( bend - 10 * dt, bend ) dtemp
	
	yend = V_avg

	strswitch( bslnFxn )
	
		case "exp":
	
			Redimension /N=4 AT_A
			Redimension /N=0 AT_B // n=0 so NMArtFxnExp computes normal exp
			
			AT_A[ 0 ] = bbgn // x0 // hold
			AT_A[ 1 ] = 0 // y0 // hold
			AT_A[ 2 ] = 1.5 * ( ybgn - yend ) // a1
			AT_A[ 3 ] = ( bend - bbgn ) / 5 // t1
			
			//FuncFit /Q/W=2/N/H="1101" NMArtFxnExp AT_A ewave( bbgn,bend ) // single exp // W=2 suppresses Fit Progress window
			FuncFit /Q/W=2/N/H="1100" NMArtFxnExp AT_A dtemp( bbgn,bend ) // single exp
			
			AT_FitB = NMArtFxnExp( AT_A, AT_FitX )
			
			Redimension /N=4 AT_B // now n=4 so NMArtFxnExp will use baseline in Decay fit
			AT_B = AT_A
			
			v1 = AT_A[ 2 ]
			v2 = AT_A[ 3 ]
		
			break
			
		case "line":
		
			Redimension /N=2 AT_B
			
			AT_B[ 1 ] = ( yend - ybgn ) / ( bend - bbgn ) // slope m
			AT_B[ 0 ] = ybgn - AT_B[ 1 ] * bbgn // offset b
			
			FuncFit /Q/W=2/N NMArtFxnLine AT_B dtemp( bbgn,bend ) // line fit
			
			AT_FitB = NMArtFxnLine( AT_B, AT_FitX )
			
			v1 = AT_B[ 0 ] // b
			v2 = AT_B[ 1 ] // m
			
			break
			
		case "avg":
		
			Redimension /N=1 AT_B
			
			WaveStats /Q/R=( bbgn, bend ) dtemp
	
			AT_FitB = V_avg
			AT_B = V_avg
			v1 = V_avg
			
			break
			
		case "zero":
			AT_FitB = 0
			AT_B = 0
			v1 = 0
			break
			
		default:
			return NaN
		
	endswitch
	
	pbgn = 0
	pend = x2pnt( AT_FitB, bbgn ) - 1
	
	if ( ( pend > 0 ) && ( pend < numpnts( AT_FitB ) ) )
		AT_FitB[ pbgn, pend ] = Nan
	endif
	
	pbgn = x2pnt( AT_FitB, stimTime + subtractWin ) + 1
	pend = numpnts( AT_FitB ) - 1
	
	if ( ( pbgn > 0 ) && ( pbgn < numpnts( AT_FitB ) ) )
		if ( ( pend > pbgn ) && ( pend < numpnts( AT_FitB ) ) )
			AT_FitB[ pbgn, pend ] = Nan
		endif
	endif
	
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

	Variable pbgn, pend, y0, ybgn, dt
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
	
	String dwName = ChanDisplayWave( -1 )
	
	if ( !WaveExists( $df+"AT_Fit" ) )
		return NaN
	endif
	
	Wave dtemp = $dwName
	Wave AT_A = $df+"AT_A"
	Wave AT_Fit = $df+"AT_Fit"
	Wave AT_FitX = $df+"AT_FitX"
	
	Variable stimTime = NMArtVarGet( "StimTime" )
	Variable subtractWin = NMArtVarGet( "SubtractWin" )
	
	String decayFxn = NMArtStrGet( "DecayFxn" )
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	dt = deltax( dtemp )
	
	pbgn = x2pnt( dtemp, tbgn )
	pend = x2pnt( dtemp, tend )
	
	if ( ( pbgn >= 0 ) && ( pbgn < numpnts( dtemp ) ) )
		ybgn = dtemp[ pbgn ]
	endif
	
	WaveStats /Q/R=( tend - 10 * dt, tend ) dtemp
	
	y0 = V_avg
	
	// first do 1-exp fit
	
	Redimension /N=4 AT_A // must be n=4 for 1-exp fit
	
	AT_A[ 0 ] = tbgn // hold
	AT_A[ 1 ] = y0 // hold // during fit y0 is set to baseline function stored in AT_B
	
	hstr = "11"
	
	AT_A[ 2 ] = ybgn - y0
	
	if ( ( numtype( t1_hold ) == 0 ) && ( t1_hold > 0 ) )
		AT_A[ 3 ] = t1_hold
		hstr += "01"
	else
		AT_A[ 3 ] = ( tend - tbgn ) / 5
		hstr += "00"
	endif
	
	FuncFit /Q/W=2/N/H=hstr NMArtFxnExp AT_A dtemp( tbgn, tend )
	
	if ( V_FitError != 0 )
		NMHistory( "1-exp fit error = " + num2str( V_FitError ) )
		AT_Fit = Nan
		SetNMvar( df+"DcayValue1", NaN )
		SetNMvar( df+"DcayValue2", NaN )
		return V_FitError
	endif
	
	a1 = AT_A[ 2 ]
	t1 = AT_A[ 3 ]
	
	if ( StringMatch( decayFxn, "2exp" ) ) // fit 2-exp
	
		Make /T/O/N=0 FitConstraints = ""
	
		z_FitConstraints( decayFxn, FitConstraints )
	
		Redimension /N=6 AT_A // must be n=6 for 2-exp fit
		
		a2 = a1 * 0.5
		
		if ( ( numtype( t2_hold ) == 0 ) && ( t2_hold > 0 ) )
			t2 = t2_hold
			hstr += "01"
		else
			t2 = t1 * 2
			hstr += "00"
		endif
		
		AT_A[ 4 ] = a2
		AT_A[ 5 ] = t2
		
		//print a1, t1, a2, t2
		
		FuncFit /Q/W=2/N/H=hstr NMArtFxnExp2 AT_A dtemp( tbgn, tend ) /C=FitConstraints
		
		if ( V_FitError != 0 )
			NMHistory( "2-exp fit error = " + num2str( V_FitError ) + ", reason = " + num2str( V_FitQuitReason ) )
			AT_Fit = Nan
			SetNMvar( df+"DcayValue1", NaN )
			SetNMvar( df+"DcayValue2", NaN )
			return V_FitError
		endif
		
		a1 = AT_A[ 2 ]
		t1 = AT_A[ 3 ]
		a2 = AT_A[ 4 ]
		t2 = AT_A[ 5 ]
		
		//print a1, t1, a2, t2
	
	endif
	
	if ( StringMatch( decayFxn, "exp" ) )
		AT_Fit = NMArtFxnExp( AT_A, AT_FitX )
		SetNMvar( df+"DcayValue1", a1 ) // tab
		SetNMvar( df+"DcayValue2", t1 )
		SetNMvar( df+"fit_a1", a1 ) // save for next fit
		SetNMvar( df+"fit_t1", t1 )
		SetNMvar( df+"fit_a2", NaN )
		SetNMvar( df+"fit_t2", NaN )
	elseif ( StringMatch( decayFxn, "2exp" ) )
		AT_Fit = NMArtFxnExp2( AT_A, AT_FitX )
		SetNMvar( df+"DcayValue1", t1 ) // tab
		SetNMvar( df+"DcayValue2", t2 )
		SetNMvar( df+"fit_a1", a1 ) // save for next fit
		SetNMvar( df+"fit_t1", t1 )
		SetNMvar( df+"fit_a2", a2 )
		SetNMvar( df+"fit_t2", t2 )
	else
		return NaN
	endif 
	
	
	if ( ( pbgn > 2 ) && ( pbgn <= numpnts( AT_Fit ) ) )
		AT_Fit[ 0, pbgn - 1 ] = Nan
	endif
	
	pbgn = x2pnt( dtemp, stimTime + subtractWin ) + 1
	pend = numpnts( dtemp ) - 1
	
	if ( ( pbgn > 1 ) && ( pbgn < numpnts( AT_Fit ) ) )
		if ( ( pend > pbgn ) && ( pend < numpnts( AT_Fit ) ) )
			AT_Fit[ pbgn, pend ] = Nan
		endif
	endif
	
	WaveStats /Q AT_Fit
	
	Variable fmax = max( abs( V_max ), abs( V_min ) )
	
	WaveStats /Q dtemp
	
	Variable wmax = max( abs( V_max ), abs( V_min ) )
	
	if ( fmax > wmax )
		AT_Fit = Nan // probably a bad fit
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

Static Function z_FitConstraints( decayFxn, cwave )
	String decayFxn
	Wave /T cwave // where constraints are saved

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
	
	if ( StringMatch( decayFxn, "2exp" ) )
		
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

End // z_FitConstraints

//****************************************************************
//****************************************************************

Function NMArtFitSubtract( [ update ] )
	Variable update

	Variable pcnt, pbgn, pend, stimValue

	String df = NMArtDF
	
	Variable tbgn = NumVarOrDefault( df + "Xbgn", NaN ) // drag wave variable
	Variable tend = NumVarOrDefault( df + "Xend", NaN )
	
	Variable stimNum = NMArtVarGet( "StimNum" )
	Variable stimTime = NMArtVarGet( "StimTime" )
	Variable bslnDT = NMArtVarGet( "BslnDT" )
	Variable subtractWin = NMArtVarGet( "SubtractWin" )
	
	String dwName = ChanDisplayWave( -1 )
	String noStimName = NMArtSubWaveName( "nostim" )
	String stimName = NMArtSubWaveName( "stim" )
	String fwName = NMArtSubWaveName( "finished" )
	
	if ( NMArtVarGet( "FitFlag" ) != 2 )
		return -1
	endif
	
	if ( numtype( stimNum * stimTime * bslnDT * subtractWin ) > 0 )
		return -1
	endif
	
	if ( !WaveExists( $noStimName ) || !WaveExists( $df+"AT_Fit" ) || !WaveExists( $fwName ) )
		return -1
	endif

	Wave dtemp = $dwName
	Wave wNoStim = $noStimName
	Wave wStim = $stimName
	Wave finished = $fwName
	
	Wave AT_Fit = $df+"AT_Fit"
	Wave AT_FitB = $df+"AT_FitB"
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( numpnts( wNoStim ) != numpnts( AT_FitB ) )
		return -1
	endif
	
	if ( ( stimNum < 0 ) || ( stimNum >= DimSize( finished, 0 ) ) )
		return -1
	endif
	
	// zero stim artefact
	
	pbgn = x2pnt( wNoStim, stimTime - bslnDT )
	pend = x2pnt( wNoStim, tbgn ) - 1
	
	if ( ( pbgn < 0 ) || ( pbgn >= numpnts( wNoStim ) ) )
		return -1
	endif
	
	if ( ( pend < 0 ) || ( pend >= numpnts( wNoStim ) ) )
		return -1
	endif

	for ( pcnt = pbgn; pcnt <= pend; pcnt += 1 )
		wStim[ pcnt ] = wNoStim[ pcnt ]
		wNoStim[ pcnt ] = AT_FitB[ pcnt ] // artefact before tbgn becomes baseline
	endfor
	
	// subtract exponential fit and baseline fit
	
	pbgn = x2pnt( wNoStim, tbgn )
	pend = x2pnt( wNoStim, stimTime + subtractWin )

	for ( pcnt = pbgn; pcnt < pend; pcnt += 1 )
		stimValue = AT_Fit[ pcnt ] - AT_FitB[ pcnt ]
		wStim[ pcnt ] = stimValue
		wNoStim[ pcnt ] = dtemp[ pcnt ] - stimValue
	endfor
	
	if ( stimNum < DimSize( finished, 0 ) )
		finished[ stimNum ][ 0 ] = stimTime
		finished[ stimNum ][ 1 ] = 1
	endif
	
	//wtempStim = wtemp - wNoStim
	Duplicate /O wNoStim $df + "AT_Display"
	
	if ( update )
		DoUpdate
	endif
	
	z_UpdateCheckboxSubtract()
	
	return 0

End // NMArtFitSubtract

//****************************************************************
//****************************************************************

Function NMArtRestore()

	Variable pcnt, pbgn, pend
	String df = NMArtDF
	
	String dwName = ChanDisplayWave( -1 )
	String noStimName = NMArtSubWaveName( "nostim" )
	String stimName = NMArtSubWaveName( "stim" )
	String fwName = NMArtSubWaveName( "finished" )
	
	Variable stimNum = NMArtVarGet( "StimNum" )
	Variable stimTime = NMArtVarGet( "StimTime" )
	Variable bslnDT = NMArtVarGet( "BslnDT" )
	Variable subtractWin = NMArtVarGet( "SubtractWin" )
	
	if ( numtype( stimNum * stimTime * bslnDT * subtractWin ) > 0 )
		return -1
	endif
	
	if ( !WaveExists( $noStimName ) || !WaveExists( $dwName ) || !WaveExists( $fwName ) )
		return -1
	endif
	
	if ( numpnts( $noStimName ) != numpnts( $dwName ) )
		return -1
	endif
	
	Wave dtemp = $dwName
	Wave wNoStim = $noStimName
	Wave wStim = $stimName
	Wave finished = $fwName
	
	if ( ( stimNum < 0 ) || ( stimNum >= DimSize( finished, 0 ) ) )
		return -1
	endif
	
	pbgn = x2pnt( wNoStim, stimTime - bslnDT )
	pend = x2pnt( wNoStim, stimTime + subtractWin )
	
	if ( ( pbgn < 0 ) || ( pbgn >= numpnts( wNoStim ) ) )
		return -1
	endif
	
	if ( ( pend < 0 ) || ( pend >= numpnts( wNoStim ) ) )
		return -1
	endif

	for ( pcnt = pbgn; pcnt <= pend; pcnt += 1 )
		wNoStim[ pcnt ] = dtemp[ pcnt ]
		wStim[ pcnt ] = 0
	endfor
	
	Duplicate /O wNoStim $df + "AT_Display"
	
	//finished[ stimNum ][ 0 ] = stimTime
	finished[ stimNum ][ 1 ] = 0
	
	z_UpdateCheckboxSubtract()

End // NMArtRestore

//****************************************************************
//****************************************************************

Function NMArtFxnLine( w, x )
	Wave w // 2 points
	// w[ 0 ] = offset b
	// w[ 1 ] = slope m
	Variable x
	
	return ( w[ 0 ] + w[ 1 ] * x )

End // NMArtFxnLine

//****************************************************************
//****************************************************************

Function NMArtFxnExp( w, x )
	Wave w // 4 points
	// w[ 0 ] = x0
	// w[ 1 ] = y0
	// w[ 2 ] = a1
	// w[ 3 ] = t1
	Variable x
	Variable y, y0
	
	Wave AT_B = $NMArtDF+"AT_B" // baseline values
	
	switch( numpnts( AT_B ) )
		case 0: // baseline fit does not exist so this is normal exp fit
			y0 = w[ 1 ]
			break
		case 1: // baseline is constant
			y0 = AT_B[ 0 ]
			break
		case 2: // baseline is line
			y0 = AT_B[ 0 ] + AT_B[ 1 ] * x
			break
		case 4: // baseline is single exp
			y0 = AT_B[ 1 ] + AT_B[ 2 ] * exp( -( x - AT_B[ 0 ] ) / AT_B[ 3 ] )
			break
	endswitch
	
	y = y0 + w[ 2 ] * exp( -( x - w[ 0 ] )/ w[ 3 ] )
	
	return y

End // NMArtFxnExp

//****************************************************************
//****************************************************************

Function NMArtFxnExp2( w, x )
	Wave w // 6 points
	// w[ 0 ] = x0
	// w[ 1 ] = y0
	// w[ 2 ] = a1
	// w[ 3 ] = t1
	// w[ 4 ] = a2
	// w[ 5 ] = t2
	Variable x
	
	Variable y, y0
	Variable a1, t1, a2, t2
	
	Wave AT_B = $NMArtDF+"AT_B" // baseline values
	
	if ( w[ 5 ] < w[ 3 ] ) // keep t1 < t2
		
		a1 = w[ 4 ]
		t1 = w[ 5 ]
		a2 = w[ 2 ]
		t2 = w[ 3 ]
		
		w[ 2 ] = a1
		w[ 3 ] = t1
		w[ 4 ] = a2
		w[ 5 ] = t2
	
	endif
	
	if ( w[ 2 ] * w[ 4 ] < 0 ) // a1 and a2 have opposite signs
		w[ 4 ] *= w[ 2 ] / abs( w[ 2 ] ) // keep the same sign
	endif
	
	switch( numpnts( AT_B ) )
		case 0: // baseline fit does not exist so this is normal exp fit
			y0 = w[ 1 ]
			break
		case 1:
			y0 = AT_B[ 0 ]
			break
		case 2:
			y0 = AT_B[ 0 ] + AT_B[ 1 ] * x
			break
		case 4:
			y0 = AT_B[ 1 ] + AT_B[ 2 ] * exp( -( x - AT_B[ 0 ] ) / AT_B[ 3 ] )
			break
	endswitch
	
	y = y0 + w[ 2 ] * exp( -( x - w[ 0 ] ) / w[ 3 ] ) + w[ 4 ] * exp( -( x - w[ 0 ] ) / w[ 5 ] )
	
	return y

End // NMArtFxnExp2

//****************************************************************
//****************************************************************

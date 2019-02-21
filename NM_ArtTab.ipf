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

Static Constant bslnWin = 2 // baseline window size computed before stim time
Static Constant bslnDT = 0 // optional baseline time shift negative from stim time, 0 - no time shift

Static Constant decayWin = 0.2 // fit window, time after cursor A
Static Constant sbtrctWin = 2 // subtraction window, time after cursor A ( includes extrapolation after fit window )

Static StrConstant bslnFxn = "avg" // baseline function to compute within bslnWin: "avg", "line", "exp" or "zero"
// "avg" - baseline is average value - a line with zero slope
// "line" or "exp" - fits a line to baseline data - use this if your baseline is not always flat
// "exp" - fits an exponential to baseline data - use this if your baseline has exp decay

Static StrConstant decayFxn = "2exp" // "exp" or "2exp" 

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
		CheckArtWaves()
		MakeArt( 0 ) // make controls if necessary
		UpdateArt()
	endif
	
	if ( DataFolderExists( NMArtDF ) == 1 )
		DisplayArtWaves( enable )
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

Function CheckArtWaves()

	String df = NMArtDF
	String wName = ChanDisplayWave( - 1 )
	
	Wave StimFit = $( df+"AT_fit" )
	
	if ( ( WaveExists( $ArtSubWaveName( "nostim" ) ) == 0 ) || ( numpnts( StimFit ) != numpnts( $wName ) ) )
		ArtReset()
	endif

End // CheckArtWaves

//****************************************************************
//****************************************************************

Function /S ArtSubWaveName( wname )
	String wname
	
	Variable CurrentChan = NumVarOrDefault( "CurrentChan", 0 )
	Variable CurrentWave = NumVarOrDefault( "CurrentWave", 0 )
	
	return NMArtPrefix + NMChanWaveName( CurrentChan,CurrentWave ) + "_" + wname

End // ArtSubWaveName

//****************************************************************
//****************************************************************

Function NMArtAuto()
	Variable icnt
	
	String df = NMArtDF

	Variable tableFit = NumVarOrDefault( df+"TableFit", 0 )
	
	Variable CurrentChan = NumVarOrDefault( "CurrentChan", 0 )
	Variable CurrentWave = NumVarOrDefault( "CurrentWave", 0 )
	
	String dName = NMChanWaveName( CurrentChan,CurrentWave )
	
	CheckArtWaves()
	
	if ( tableFit == 1 )
	
		Wave /T fwave = $( df+"AT_FitWaves" )
		Wave /T twave = $( df+"AT_TimeWaves" )
		
		for ( icnt = 0; icnt < numpnts( fwave ); icnt += 1 )
			if ( StringMatch( fwave[icnt], dname ) == 1 )
				NewArtTimeWave( twave[icnt] )
				break
			endif
		endfor
		
	endif
	
	DisplayArtWaves( 1 )
	UpdateArt()
	ArtGoTo( 0 )

End // NMArtAuto

//****************************************************************
//****************************************************************

Function DisplayArtWaves( appnd ) // append/remove Art display waves to current channel graph
	Variable appnd // // ( 0 ) remove ( 1 ) append
	
	Variable icnt

	String gName = CurrentChanGraphName()
	
	String df = NMArtDF
	
	if ( DataFolderExists( df ) == 0 )
		return 0 // Art has not been initialized yet
	endif
	
	if ( Wintype( gName ) == 0 )
		return -1 // window does not exist
	endif
	
	String wlist = WaveList( "*_nostim", ";", "WIN:"+gName )
	
	String wName = ArtSubWaveName( "nostim" )
	
	RemoveFromGraph /Z/W=$gName AT_fit, AT_fitb, AT_timeY
	
	for ( icnt = 0; icnt < ItemsInlist( wlist ); icnt += 1 )
		RemoveFromGraph /Z/W=$gName $( StringFromList( icnt, wlist ) )
	endfor
	
	if ( appnd == 1 )

		AppendToGraph /W=$gName $wName
		AppendToGraph /W=$gName $( df+"AT_fit" ), $( df+"AT_fitb" )
		AppendToGraph /W=$gName $( df+"AT_timeY" ) vs $( df+"AT_timeX" )
		
		ModifyGraph /W=$gName rgb( $wName )=( 0,0,65280 ), lsize( $wName )=2
		
		ModifyGraph /W=$gName mode( AT_timeY )=3, marker( AT_timeY )=10, rgb( AT_timeY )=( 65280,0,0 ), msize( AT_timeY )=20
		ModifyGraph /W=$gName mode( AT_fitb )=3, marker( AT_fitb )=10, rgb( AT_fitb )=( 0,65280,0 )
		
		ShowInfo /W=$gName
		
	endif
	
End // DisplayArtWaves

//****************************************************************
//****************************************************************

Function MakeArt( force ) // create Art tab controls
	Variable force
	
	Variable x0, y0, xinc, yinc

	String df = NMArtDF
	
	ControlInfo /W=NMPanel AT_AutoFit
	
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
	PopupMenu AT_BslnFxn, value="", proc=ArtPopup
	
	SetVariable AT_BslnVal1, title="a :", pos={x0+80,y0+2}, size={70,50}, fsize = 12, format = "%.2f"
	SetVariable AT_BslnVal1, value=$( df+"BslnValue1" ), limits={-inf,inf,0}, frame=0
	
	SetVariable AT_BslnVal2, title="t :", pos={x0+155,y0+2}, size={70,50}, fsize = 12, format = "%.2f"
	SetVariable AT_BslnVal2, value=$( df+"BslnValue2" ), limits={-inf,inf,0}, frame=0
	
	SetVariable AT_BslnDT, title="-dt:", pos={x0,y0+yinc}, size={100,50}, fsize = 12, format = "%.2f"
	SetVariable AT_BslnDT, value=$( df+"BslnDT" ), proc=ArtSetVar
	
	SetVariable AT_BslnWin, title="win:", pos={x0+xinc,y0+yinc}, size={100,50}, fsize = 12, format = "%.2f"
	SetVariable AT_BslnWin, value=$( df+"BslnWin" ), proc=ArtSetVar
	
	y0 += 100
	
	GroupBox AT_FitGrp, title = "Decay", pos={x0-20,y0-25}, size={260,90}
	
	PopupMenu AT_FitFxn, pos={x0+10,y0}, bodywidth=60
	PopupMenu AT_FitFxn, value="", proc=ArtPopup
	
	SetVariable AT_FitVal1, title="a :", pos={x0+80,y0+2}, size={70,50}, fsize = 12, format = "%.2f"
	SetVariable AT_FitVal1, value=$( df+"DcayValue1" ), limits={-inf,inf,0}, frame=0
	
	SetVariable AT_FitVal2, title="t :", pos={x0+155,y0+2}, size={70,50}, fsize = 12, format = "%.2f"
	SetVariable AT_FitVal2, value=$( df+"DcayValue2" ), limits={-inf,inf,0}, frame=0
	
	SetVariable AT_FitWin, title="fit win:", pos={x0,y0+yinc}, size={100,50}, fsize = 12, format = "%.2f"
	SetVariable AT_FitWin, value=$( df+"DcayWin" ), proc=ArtSetVar
	
	SetVariable AT_SubWin, title="sub win:", pos={x0+xinc-10,y0+yinc}, size={110,50}, fsize = 12, format = "%.2f"
	SetVariable AT_SubWin, value=$( df+"SbtrctWin" ), proc=ArtSetVar
	
	y0 += 100
	
	GroupBox AT_TimeGrp, title = "Time", pos={x0-20,y0-25}, size={260,130}
	
	PopupMenu AT_TimeWave, pos={x0+140,y0}, bodywidth=190, proc=ArtPopup
	PopupMenu AT_TimeWave, value=""
	
	SetVariable AT_NumStims, title=":", pos={x0+195,y0}, size={40,50}, limits={0,inf,0}
	SetVariable AT_NumStims, value=$( df+"NumStims" ), fsize=12, frame=0, noedit=1
	
	SetVariable AT_StimTime, title="t =", pos={x0+60,y0+yinc}, size={100,50}, fsize = 12, format = "%.2f"
	SetVariable AT_StimTime, value=$( df+"StimTime" ), proc=ArtSetVar
	
	SetVariable AT_StimNum, title=" ", pos={x0+90,y0+2*yinc}, size={50,50}, limits={0,inf,0}
	SetVariable AT_StimNum, value=$( df+"StimNum" ), fsize = 12, proc=ArtSetVar
	
	Button AT_FirstStim, pos={x0+90-80,y0+2*yinc}, title = "<<", size={30,20}, proc=ArtButton
	Button AT_PrevStim, pos={x0+90-40,y0+2*yinc}, title = "<", size={30,20}, proc=ArtButton
	Button AT_NextStim, pos={x0+150,y0+2*yinc}, title = ">", size={30,20}, proc=ArtButton
	Button AT_LastStim, pos={x0+150+40,y0+2*yinc}, title = ">>", size={30,20}, proc=ArtButton
	
	y0 += 130
	x0 -= 5
	xinc = 80
	
	Button AT_Reset, pos={x0,y0}, title = "Reset", size={70,20}, proc=ArtButton
	Button AT_FitStim, pos={x0+1*xinc,y0}, title = "Fit", size={70,20}, proc=ArtButton
	Button AT_AutoStim, pos={x0+2*xinc,y0}, title = "Auto", size={70,20}, proc=ArtButton
	
	Checkbox AT_AutoFit, title="auto fit", pos={x0+50,y0+yinc}, size={100,50}, value=1, fsize = 12, proc=ArtCheckbox
	
	Checkbox AT_TableFit, title="table", pos={x0+150,y0+yinc}, size={100,50}, value=1, fsize = 12, proc=ArtCheckbox
	
End // MakeArt

//****************************************************************
//****************************************************************

Function UpdateArt()

	Variable md
	String df = NMArtDF

	String wName = ChanDisplayWave( -1 )
	
	String BslnFxn = StrVarOrDefault( df+"BslnFxn", "line" )
	String DcayFxn = StrVarOrDefault( df+"DcayFxn", "2exp" )
	String StimTimeWName = StrVarOrDefault( df+"StimTimeWName", "" )
	
	md = WhichListItem( BslnFxn, "avg;line;exp;zero;" ) + 1
	PopupMenu AT_BslnFxn, win=NMPanel, value ="avg;line;exp;zero;", mode=md
	
	md = WhichListItem( DcayFxn, "exp;2exp;" ) + 1
	PopupMenu AT_FitFxn, win=NMPanel, value="exp;2exp;", mode=md
	
	md = WhichListItem( StimTimeWName, WaveList( "*",";","" ) ) + 2
	
	if ( md == 0 )
		md = 1
	endif
	
	strswitch( BslnFxn )
		case "avg":
			SetVariable AT_BslnVal1, win=NMPanel, title="a :"
			SetVariable AT_BslnVal2, win=NMPanel, title=" ", disable = 1
			break
		case "line":
			SetVariable AT_BslnVal1, win=NMPanel, title="b :"
			SetVariable AT_BslnVal2, win=NMPanel, title="m :", disable = 0
			break
		case "exp":
			SetVariable AT_BslnVal1, win=NMPanel, title="a :"
			SetVariable AT_BslnVal2, win=NMPanel, title="t :", disable = 0
			break
		case "zero":
			SetVariable AT_BslnVal1, win=NMPanel, title="a :"
			SetVariable AT_BslnVal2, win=NMPanel, title="t :", disable = 1
			break
	endswitch
	
	strswitch( DcayFxn )
		case "exp":
			SetVariable AT_FitVal1, win=NMPanel, title="a :"
			SetVariable AT_FitVal2, win=NMPanel, title="t :"
			break
		case "2exp":
			SetVariable AT_FitVal1, win=NMPanel, title="t1 :"
			SetVariable AT_FitVal2, win=NMPanel, title="t2 :"
			break
	endswitch
	
	PopupMenu AT_TimeWave, win=NMPanel, value="--- manual ---;" + WaveList( "*",";","" ), mode=md
	
	SetVariable AT_BslnWin, win=NMPanel, limits={leftx( $wname ),rightx( $wname ),deltax( $wname )}
	SetVariable AT_FitWin, win=NMPanel, limits={0,inf,deltax( $wname )}
	SetVariable AT_SubWin, win=NMPanel, limits={0,inf,deltax( $wname )}
	SetVariable AT_StimTime, win=NMPanel, limits={leftx( $wname ),rightx( $wname ),deltax( $wname )}
	
	Checkbox AT_AutoFit, win=NMPanel, value=NumVarOrDefault( df+"AutoFit",1 )
	Checkbox AT_TableFit, win=NMPanel, value=NumVarOrDefault( df+"TableFit",0 )
	
	ArtCountStims()

End // UpdateArt

//****************************************************************
//****************************************************************

Function ArtPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	String df = NMArtDF
	
	strswitch( ctrlName )
	
		case "AT_TimeWave":
			if ( WaveExists( $popStr ) == 0 )
				ArtManualMode()
			else
				NewArtTimeWave( popStr )
			endif
			ArtReset()
			UpdateArt()
			ArtFit()
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
	
	UpdateArt()
	
End // ArtPopup

//****************************************************************
//****************************************************************

Function ArtCheckbox( ctrlName, checked ) : CheckBoxControl
	String ctrlName; Variable checked

	String df = NMArtDF
	
	strswitch( ctrlName )
		case "AT_AutoFit":
			SetNMvar( df+"AutoFit",checked )
			break
		case "AT_TableFit":
			ArtTable( checked )
			SetNMvar( df+"TableFit", checked )
			break
	endswitch

End // ArtCheckbox

//****************************************************************
//****************************************************************

Function ArtSetVar( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	String df = NMArtDF
	
	Variable StimNum = NumVarOrDefault( df+"StimNum", 0 )
	
	strswitch( ctrlName )
		case "AT_StimTime":
			SetArtWaveTime( varNum )
			break
		case "AT_BslnDT":
		case "AT_BslnWin":
		case "AT_SubWin":
			SetNMvar( df+"ArtRestoreFlag", 1 )
		case "AT_FitWin":
			varNum = StimNum
		case "AT_StimNum":
			SetArtTime( varNum )
			break
	endswitch
	
End // ArtSetVar

//****************************************************************
//****************************************************************

Function ArtButton( ctrlName ) : ButtonControl
	String ctrlName

	strswitch( ctrlName )
		case "AT_AutoStim":
			ArtAllFitCall()
			break
			
		case "AT_FitStim":
			ArtFit()
			break
			
		case "AT_Reset":
			ArtReset()
			break
			
		case "AT_FirstStim":
			ArtGoTo( 0 )
			break
			
		case "AT_PrevStim":
			ArtGoTo( -1 )
			break
			
		case "AT_NextStim":
			ArtGoTo( +1 )
			break
			
		case "AT_LastStim":
			ArtGoTo( 9 )
			break
	
	endswitch

End // ArtButton

//****************************************************************
//****************************************************************

Function ArtReset()

	String df = NMArtDF
	String wName = ChanDisplayWave( -1 )

	if ( WaveExists( $wName ) == 1 )
		Duplicate /O $wname $ArtSubWaveName( "nostim" )
		Duplicate /O $wname $ArtSubWaveName( "stim" )
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
	
	SetArtTime( 0 )
	
End // ArtReset

//****************************************************************
//****************************************************************

Function ArtCountStims()
	String df = NMArtDF

	SetNMvar( df+"NumStims", numpnts( $( df+"AT_timeX" ) ) )

End // ArtCountStims

//****************************************************************
//****************************************************************

Function ArtManualMode()
	String df = NMArtDF

	SetNMstr( df+"StimTimeWName", "" )
	SetNMvar( df+"NumStims", 0 )
	
	Wave xwave = $( df+"AT_timeX" )
	Wave ywave = $( df+"AT_timeY" )
	
	Redimension /N=0 xwave, ywave
	
	xwave = 0; ywave = 0

End // ArtManualMode

//****************************************************************
//****************************************************************

Function IsArtManualMode()
	String df = NMArtDF

	if ( strlen( StrVarOrDefault( df+"StimTimeWName", "" ) ) == 0 )
		return 1
	else
		return 0
	endif

End // IsArtManualMode

//****************************************************************
//****************************************************************

Function NewArtTimeWave( wname )
	String wname
	
	Variable icnt
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
		ywave[icnt] = dwave[x2pnt( dwave, xwave[icnt] )]
	endfor
	
End // NewArtTimeWave

//****************************************************************
//****************************************************************

Function SetArtWaveTime( t )
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
	
	ArtCountStims()
	SetArtTime( StimNum )

End // SetArtWaveTime

//****************************************************************
//****************************************************************

Function ArtGoTo( select ) // jump to a new stim
	Variable select // ( -1 ) previous ( 1 ) next ( 0 ) first ( 9 ) last
	
	Variable next
	String df = NMArtDF
	
	Variable StimNum = NumVarOrDefault( df+"StimNum", 0 )
	Variable AutoFit = NumVarOrDefault( df+"AutoFit", 0 )

	Wave AT_ArtSubFin = $( df+"AT_ArtSubFin" )

	switch( select )
			
		case 0:
			next = 0
			break
			
		case -1:
			next = StimNum - 1
			break
			
		case 1:
			next = StimNum + 1
			break
			
		case 9:
			next = numpnts( AT_ArtSubFin ) - 1
			break
	
	endswitch
	
	if ( ( SetArtTime( next ) != -1 ) && ( AutoFit == 1 ) && ( AT_ArtSubFin[next] == 0 ) )
		ArtFit()
	endif

End // ArtGoTo

//****************************************************************
//****************************************************************

Function SetArtTime( stimNum )
	Variable stimNum
	
	Variable t
	String df = NMArtDF
	
	if ( stimNum < 0 )
		return -1 // out of range
	endif
	
	Wave xwave = $( df+"AT_timeX" )
	Wave AT_fit = $( df+"AT_fit" )
	Wave AT_fitb = $( df+"AT_fitb" )
	
	if ( IsArtManualMode() == 1 ) // manual mode
	
		if ( stimNum > numpnts( xwave ) )
			return -1 // out of range
		endif
		
		SetNMvar( df+"StimNum", stimNum )
		
		if ( stimNum == numpnts( xwave ) )
			return -1 // does not exist yet
		endif
	
	else
	
		if ( stimNum > numpnts( xwave ) - 1 )
			return -1 // out of range
		endif
		
		SetNMvar( df+"StimNum", stimNum )
		
	endif
	
	t = xwave[stimNum]
	SetNMvar( df+"StimTime", t )
	SetArtDisplay( t )
	
	AT_fit = Nan
	AT_fitb = Nan
	
	return 0
	
End // SetArtTime

//****************************************************************
//****************************************************************

Function SetArtDisplay( t )
	Variable t
	
	Variable kbgn, kend, kdelta, tmax, tmin
	String df = NMArtDF
	
	Variable CurrentChan = NumVarOrDefault( "CurrentChan", 0 )
	
	Variable BslnWin = NumVarOrDefault( df+"BslnWin", 0 )
	Variable SbtrctWin = NumVarOrDefault( df+"SbtrctWin", 0 )
	Variable BslnDT = NumVarOrDefault( df+"BslnDT", 0 )
	Variable DcayWin = NumVarOrDefault( df+"DcayWin", 0 )
	
	String gName = CurrentChanGraphName()
	String wName = ChanDisplayWave( CurrentChan )
	
	wName = GetPathName( wName, 0 )
	 
	if ( t == 0 )
		Cursor /W=$gName A, $wName, 0
		Cursor /W=$gName B, $wName, 0
		SetAxis /A
		return 0
	endif
	
	String dName = ChanDisplayWave( -1 )
	
	WaveStats /Q/R=( t, t+0.4 ) $dname
	
	tmax = V_maxloc
	
	WaveStats /Q/R=( tmax, tmax+0.2 ) $dname
	
	kbgn = V_minloc + deltax( $dname )
	kend = kbgn + DcayWin
	kdelta = ( BslnDT + BslnWin + SbtrctWin ) / 4
	
	Cursor /W=$gName A, $wName, kbgn
	Cursor /W=$gName B, $wName, kend

	DoWindow /F $gName
	
	SetAxis bottom ( t - BslnDT - BslnWin - kdelta ), ( t + SbtrctWin + kdelta )
	
	kbgn = vcsr( A )
	kend =vcsr( B )
	kdelta = abs( kbgn - kend )/ 1
	
	SetAxis Left ( kbgn-kdelta ), ( kend + kdelta )
	
End // SetArtDisplay

//****************************************************************
//****************************************************************

Function ArtAllFitCall()

	String tname = "ArtFitTable"
	String df = NMArtDF
	
	Variable tableFit = NumVarOrDefault( df+"TableFit", 0 )
	
	if ( tableFit == 0 )
		ArtAllFit()
	else
		ArtAllFitTable()
	endif

End // ArtAllFitCall

//****************************************************************
//****************************************************************

Function ArtAllFit()
	Variable icnt
	
	String df = NMArtDF
	
	Variable stimNum = NumVarOrDefault( df+"StimNum", 0 )
	
	Wave AT_ArtSubFin = $( df+"AT_ArtSubFin" )
	
	for ( icnt = 0; icnt < numpnts( AT_ArtSubFin ); icnt += 1 )
	
		if ( AT_ArtSubFin[icnt] == 0 )
			SetArtTime( icnt )
			ArtFit()
			DoUpdate
		endif
		
	endfor
	
	SetArtTime( stimNum )

End // ArtAllFit

//****************************************************************
//****************************************************************

Function ArtAllFitTable()
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
		
		NewArtTimeWave( tname )
		
		NMArtAuto()
		ArtReset()
		UpdateArt()
		
		for ( icnt = 0; icnt < numpnts( AT_ArtSubFin ); icnt += 1 )
	
			if ( AT_ArtSubFin[icnt] == 0 )
				SetArtTime( icnt )
				ArtFit()
				DoUpdate
			endif
		
		endfor
		
		print "Art Subtracted " + wname + " : N = " + num2str( icnt )
		
	endfor
	
	//SetNMvar( "CurrentWave", saveNum )
	//UpdateCurrentWave()
	
	//SetArtTime( stimNum )

End // ArtAllFitTable

//****************************************************************
//****************************************************************

Function ArtTable( mode )
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
	
End // ArtTable

//****************************************************************
//****************************************************************

Function ArtFit()
	String df = NMArtDF

	Variable StimTime = NumVarOrDefault( df+"StimTime", 0 )
	
	if ( ( numpnts( $( df+"AT_timeX" ) ) == 0 ) && ( StimTime == 0 ) )
		return -1 // nothing to fit
	endif

	if ( ( ArtBslnFit() == 0 ) && ( ArtStimFit() == 0 ) )
		ArtSubtract()
	endif

End // ArtFit

//****************************************************************
//****************************************************************

Function ArtBslnFit()
	Variable tbgn, tend, ybgn, yend, v1 = Nan, v2 = Nan
	Variable V_FitError = 0, V_chisq
	 
	String df = NMArtDF
	
	String fxn = StrVarOrDefault( df+"BslnFxn", "line" )
	
	Variable StimTime = NumVarOrDefault( df+"StimTime", 0 )
	Variable BslnDT = NumVarOrDefault( df+"BslnDT", 0 )
	Variable BslnWin = NumVarOrDefault( df+"BslnWin", 0 )
	Variable SbtrctWin = NumVarOrDefault( df+"SbtrctWin", 0 )
	
	Wave eWave = $ChanDisplayWave( -1 )
	Wave AT_a = $( df+"AT_a" )
	Wave AT_b = $( df+"AT_b" )
	Wave AT_fitb = $( df+"AT_fitb" )
	Wave AT_fitx = $( df+"AT_fitx" )
	
	tbgn = StimTime - BslnWin - BslnDT
	tend = StimTime - BslnDT
	
	ybgn = eWave[x2pnt( eWave, tbgn )]
	yend = eWave[x2pnt( eWave, tend )]

	strswitch( fxn )
		case "exp":
	
			Redimension /N=4 AT_a
			Redimension /N=0 AT_b
			
			AT_a[0] = yend // y0
			AT_a[1] = tbgn // t0
			AT_a[2] = ybgn - yend // a1
			AT_a[3] = ( tend - tbgn ) / 5 // tau1
			
			FuncFit /Q/W=0/N/H="0101" ArtExpFxn AT_a ewave( tbgn,tend ) // single exp
			FuncFit /Q/W=0/N/H="0100" ArtExpFxn AT_a ewave( tbgn,tend ) // single exp
			
			AT_fitb = ArtExpFxn( AT_a, AT_fitx )
			
			Redimension /N=4 AT_b
			AT_b = AT_a
			
			v1 = AT_a[2]
			v2 = AT_a[3]
		
			break
			
		case "line":
		
			Redimension /N=2 AT_b
			
			AT_b[1] = ( yend - ybgn ) / ( tend - tbgn )
			AT_b[0] = ybgn - AT_b[1] * tbgn
			
			FuncFit /Q/W=0/N ArtLineFxn AT_b ewave( tbgn,tend ) // line fit
			
			AT_fitb = ArtLineFxn( AT_b, AT_fitx )
			
			v1 = AT_b[0]
			v2 = AT_b[1]
			
			break
			
		case "avg":
		
			Redimension /N=1 AT_b
			
			WaveStats /Q/R=( tbgn, tend ) ewave
	
			AT_fitb = V_avg
			AT_b = V_avg
			v1 = V_avg
			
			break
			
		case "zero":
		
			AT_fitb = 0
			AT_b = 0
			v1 = 0
			break
		
	endswitch

	AT_fitb[0, x2pnt( eWave, tbgn )] = Nan
	AT_fitb[x2pnt( eWave, StimTime + SbtrctWin ), inf] = Nan
	
	SetNMvar( df+"BslnValue1", v1 )
	SetNMvar( df+"BslnValue2", v2 )
	
	return V_FitError
	
End // ArtBslnFit

//****************************************************************
//****************************************************************
//****************************************************************

Function ArtStimFit()
	Variable v1 = Nan, v2 = Nan
	Variable V_FitError = 0, V_chisq
	
	String df = NMArtDF
	
	Wave eWave = $ChanDisplayWave( -1 )
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
	
	// fit single exponential
	
	Redimension /N=4 AT_a
	
	AT_a[0] = vcsr( B )
	AT_a[1] = xcsr( A )
	AT_a[2] = vcsr( A ) - AT_a[0]
	AT_a[3] = ( xcsr( B ) - xcsr( A ) ) / 5
	
	FuncFit /Q/W=0/N/H="1100" ArtExpFxn AT_a ewave( xcsr( A ),xcsr( B ) )
	
	// now double exponential
	
	if ( StringMatch( DcayFxn, "2exp" ) == 1 )
	
		Redimension /N=6 AT_a
	
		AT_a[4] = AT_a[2] / 2
		AT_a[5] = AT_a[3] * 2
		
		FuncFit /Q/W=0/N/H="110000" ArtDblExpFxn AT_a ewave( xcsr( A ),xcsr( B ) )
	
	endif
	
	if ( numpnts( AT_a ) == 4 )
		AT_fit = ArtExpFxn( AT_a, AT_fitx )
		v1 = AT_a[2]
		v2 = AT_a[3]
	elseif ( numpnts( AT_a ) == 6 )
		AT_fit = ArtDblExpFxn( AT_a, AT_fitx )
		v1 = AT_a[3]
		v2 = AT_a[5]
	endif
	
	AT_fit[0, pcsr( A )-1] = Nan
	AT_fit[x2pnt( eWave, StimTime + SbtrctWin ), inf] = Nan
	
	WaveStats /Q AT_fit
	
	Variable fmax = max( abs( V_max ), abs( V_min ) )
	
	WaveStats /Q ewave
	
	Variable wmax = max( abs( V_max ), abs( V_min ) )
	
	if ( fmax > wmax )
		AT_fit = Nan // probably a bad fit
		return -1
	endif
	
	SetNMvar( df+"DcayValue1", v1 )
	SetNMvar( df+"DcayValue2", v2 )
	
	DoUpdate
	
	return V_FitError

End // ArtStimFit

//****************************************************************
//****************************************************************

Function ArtSubtract()
	Variable pcnt, pbgn, pend

	String df = NMArtDF

	Wave cWave = $ArtSubWaveName( "nostim" )
	Wave dWave = $ArtSubWaveName( "stim" )
	Wave oWave = $ChanDisplayWave( -1 )
	
	Wave AT_fit = $( df+"AT_fit" )
	Wave AT_fitb = $( df+"AT_fitb" )
	Wave AT_ArtSubFin = $( df+"AT_ArtSubFin" )
	
	Variable StimNum = NumVarOrDefault( df+"StimNum", 0 )
	Variable StimTime = NumVarOrDefault( df+"StimTime", 0 )
	Variable BslnDT = NumVarOrDefault( df+"BslnDT", 0 )
	Variable SbtrctWin = NumVarOrDefault( df+"SbtrctWin", 0 )
	
	if ( NumVarOrDefault( df+"ArtRestoreFlag", 0 ) == 1 )
		ArtRestore()
	endif
	
	// zero stim artifact
	
	pbgn = x2pnt( cWave, StimTime - BslnDT )
	pend = pcsr( A ) - 1
	
	SetNMvar( df+"SubPbgn", pbgn )

	for ( pcnt = pbgn; pcnt <= pend; pcnt += 1 )
		cWave[pcnt] = AT_fitb[pcnt]
	endfor
	
	// set exponential
	
	pbgn = pcsr( A )
	pend = x2pnt( cWave, StimTime + SbtrctWin )

	for ( pcnt = pbgn; pcnt < pend; pcnt += 1 )
		cWave[pcnt] = oWave[pcnt] - ( AT_fit[pcnt] - AT_fitb[pcnt] )
	endfor
	
	SetNMvar( df+"SubPend", pend )
	
	AT_ArtSubFin[StimNum] = 1
	
	dWave = oWave - cWave

End // ArtSubtract

//****************************************************************
//****************************************************************

Function ArtRestore()

	Variable pcnt, pbgn, pend
	String df = NMArtDF

	Wave cWave = $ArtSubWaveName( "nostim" )
	Wave oWave = $ChanDisplayWave( -1 )
	
	pbgn = NumVarOrDefault( df+"SubPbgn", 0 )
	pend = NumVarOrDefault( df+"SubPend", 0 )

	for ( pcnt = pbgn; pcnt <= pend; pcnt += 1 )
		cWave[pcnt] = oWave[pcnt]
	endfor
	
	SetNMvar( df+"ArtRestoreFlag", 0 )

End // ArtRestore

//****************************************************************
//****************************************************************

Function ArtMakeImpulse()

	Variable icnt, tbgn, pmin, pmax, t, t2peak, dt, vmax
	String tName = "ArtTemplate"
	
	String df = NMArtDF
	
	String wname = ChanDisplayWave( -1 )
	
	if ( ( strlen( wname ) == 0 ) || ( WaveExists( $wname ) == 0 ) )
		return 0
	endif
	
	if ( WaveExists( $tName ) == 0 )
		ArtSaveTemplate( 0 )
	endif
	
	WaveStats /Q $tName
	
	dt = x2pnt( $tName, V_maxloc ) - x2pnt( $tName, V_minloc )
	
	t2peak = ArtMinAlignment( dt )
	
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
	
End // ArtMakeImpulse

//****************************************************************
//****************************************************************

Function ArtSaveTemplate( flag )
	Variable flag // ( -1 ) reset counter ( 0 ) save to template avg
	
	Variable dt
	
	String df = NMArtDF
	
	String wName = ArtSubWaveName( "stim" )
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

End // ArtSaveTemplate

//****************************************************************
//****************************************************************

Function ArtBump()

	Variable m, b, dx = 0.4
	
	String wName = ArtSubWaveName( "nostim" )
	
	if ( ( strlen( wname ) == 0 ) || ( WaveExists( $wname ) == 0 ) )
		return 0
	endif
	
	DoWindow /F ChanA

	Wave stimWave = $ArtSubWaveName( "stim" )
	
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

End // ArtBump

//****************************************************************
//****************************************************************

Function ArtMinAlignment( dt ) // determine min time to peak ( tmax - tstim )
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

End // ArtMinAlignment

//****************************************************************
//****************************************************************

Function ArtLineFxn( w, x )
	Wave w // 2 points
	Variable x
	
	return ( w[0] + w[1]*x )

End // ArtLineFxn

//****************************************************************
//****************************************************************

Function ArtExpFxn( w, x )
	Wave w // 4 points
	Variable x
	Variable y, y0
	
	Wave AT_b = $( NMArtDF+"AT_b" )
	
	if ( w[3] <= 0 )
		w[3] = -w[3] + 0.0001
	endif
	
	switch( numpnts( AT_b ) )
		case 0:
			y0 = w[0]
			break
		case 1:
			y0 = AT_b[0]
			break
		case 2:
			y0 = AT_b[0] + AT_b[1]*x
			break
		case 4:
			y0 = AT_b[0] + AT_b[2]*exp( -( x - AT_b[1] )/AT_b[3] )
			break
	endswitch
	
	y = y0 + w[2]*exp( -( x - w[1] )/w[3] )
	
	return y

End // ArtExpFxn

//****************************************************************
//****************************************************************

Function ArtDblExpFxn( w, x )
	Wave w // 6 points
	Variable x
	Variable y, y0
	
	Wave AT_b = $( NMArtDF+"AT_b" )
	
	if ( w[3] <= 0 )
		w[3] = -w[3] + 0.0001
	endif
	
	if ( w[5] <= 0 )
		w[5] = -w[5] + 0.0001
	endif
	
	if ( w[5] > 100 )
		w[5] = w[3] * 10
	endif
	
	if ( w[2] * w[4] < 0 )
		w[4] *= w[2] / abs( w[2] ) // keep exponentials the same sign
	endif
	
	switch( numpnts( AT_b ) )
		case 0:
			y0 = w[0]
			break
		case 1:
			y0 = AT_b[0]
			break
		case 2:
			y0 = AT_b[0] + AT_b[1]*x
			break
		case 4:
			y0 = AT_b[0] + AT_b[2]*exp( -( x - AT_b[1] )/AT_b[3] )
			break
	endswitch
	
	y = y0 + w[2]*exp( -( x - w[1] )/w[3] ) + w[4]*exp( -( x - w[1] )/w[5] )
	
	return y

End // ArtDblExpFxn

//****************************************************************
//****************************************************************


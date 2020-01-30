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
//	Progress Display Functions
//
//****************************************************************
//****************************************************************

Constant NMProgWinWidth = 260 // pixels
Constant NMProgWinHeight = 100 // pixels

Static Constant NMProgButtonX0 = 90
Static Constant NMProgButtonY0 = 70
Static Constant NMProgButtonXwidth = 80
Static Constant NMProgButtonYwidth = 20

Static Constant NMProgPopupX0 = 240
Static Constant NMProgPopupY0 = 70

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressX()

	Variable xprogress = NMVarGet( "xProgress" )
	Variable xpixels = NMScreenPixelsX()
	Variable xlimit = xpixels - NMProgWinWidth
	
	if ( numtype( xprogress ) > 0 )
		xprogress = ( xpixels - NMProgWinWidth ) * 0.5
	endif
	
	xprogress = max( xprogress, 0 )
	xprogress = min( xprogress, xlimit )
	
	return xprogress
	
End // NMProgressX

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressY()
	
	Variable yprogress = NMVarGet( "yProgress" )
	Variable ypixels = NMScreenPixelsY(igorFrame=1)
	Variable ylimit = ypixels - NMProgWinHeight
	
	if ( numtype( yprogress ) > 0 )
		yprogress = 0.7 * ypixels
	endif
	
	yprogress = max( yprogress, 0 )
	yprogress = min( yprogress, ylimit )
	
	return yprogress

End // NMProgressY

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressFlag()

	Variable progflag = NMVarGet( "ProgFlag" )
	
	if ( progflag > 0 )
	
		if ( IgorVersion() >= 6.1 )
			return 2 // new Igor Progress Window
			//return 1 // use ProgWin XOP
		endif
		
		return 1 // use ProgWin XOP
	
	endif
	
	return 0

End // NMProgressFlag

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgFlagDefault()

	if ( IgorVersion() >= 6.1 )
		return 2 // use Igor built-in Progress Window
	endif
	
	Execute /Z "ProgressWindow kill"
			
	if ( V_flag == 0 )
		return 1 // ProgWin XOP exists, so use this
	endif
	
	Execute /Z "ProgressWindow kill"
		
	if ( V_flag != 0 )
		NMDoAlert( "NM Alert: ProgWin XOP cannot be located. This XOP can be downloaded from www.wavemetrics.com/Support/ftpinfo.html." )
	endif
	
	return 0 // no progress window exists

End // NMProgFlagDefault

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressOn( pflag ) // set Progress flag
	Variable pflag // ( 0 ) off ( 1 ) use ProgWin XOP ( 2 ) use Igor Progress Window
	
	if ( pflag == 1 )
		
		Execute /Z "ProgressWindow kill"
		
		if ( V_flag != 0 )
		
			if ( IgorVersion() >= 6.1 )
				pflag = 2
			else
				NMDoAlert( "NM Alert: ProgWin XOP cannot be located. This XOP can be downloaded from www.wavemetrics.com/Support/ftpinfo.html." )
				pflag = 0
			endif
			
		endif
		
	endif
		
	if ( pflag == 2 )
	
		if ( IgorVersion() < 6.1 )
			NMDoAlert( "NM Alert: this version of Igor does not support Progress Windows." )
			pflag = 0
		endif
		
	endif
	
	SetNMvar( NMDF+"ProgFlag", pflag )
	
	return pflag

End // NMProgressOn

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressCancel( [ reset ] )
	Variable reset
	
	if ( reset )
	
		SetNMvar( "V_Progress", 0 )
		SetNMvar( NMDF + "NMProgressCancel", 0 )
		
		return 0
	
	endif
	
	switch( NMProgressFlag() )
	
		case 1:
			return NumVarOrDefault( "V_Progress", 0 ) // ProgWin XOP
			
		case 2:
			return NumVarOrDefault( NMDF + "NMProgressCancel", 0 )
	
	endswitch

	return 0

End // NMProgressCancel

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressTimer( currentCount, maxIterations, progressStr )
	Variable currentCount, maxIterations
	String progressStr
	
	Variable t, ref
	
	if ( currentCount == 0 )
	
		SetNMstr( NMDF+"ProgressStr", progressStr )
	
		ref = startMSTimer // start usec timer
		
		if ( ref > 0 )
			SetNMvar( NMDF+"ProgressLoopTimer", ref )
		endif
		
		return 0
		
	endif
	
	if ( exists( NMDF+"ProgressLoopTimer" ) == 0 )
	
		SetNMstr( NMDF+"ProgressStr", "" )
		
		return 0 // progress display is not on
		
	endif
		
	if ( currentCount == 1 )
	
		ref = NumVarOrDefault( NMDF+"ProgressLoopTimer", NaN )
		
		t = stopMSTimer( ref ) / 1000 // time in msec
		
		//Print "estimated function time:", ( t * maxIterations ), "ms"
		
		if ( t * maxIterations > NMVarGet( "ProgressTimerLimit" ) )
		
			NMProgress( 0, maxIterations, progressStr ) // open window
			
			return NMProgress( 1, maxIterations, progressStr ) // first increment
			
		else
		
			KillVariables /Z $NMDF+"ProgressLoopTimer"
		
		endif
		
	else
	
		if ( currentCount == maxIterations - 1 )
			KillVariables /Z $NMDF+"ProgressLoopTimer"
		endif
	
		return NMProgress( currentCount, maxIterations, progressStr )
		
	endif

End // NMProgressTimer

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgress( currentCount, maxIterations, progressStr )
	Variable currentCount, maxIterations
	String progressStr
	
	Variable fraction = currentCount / ( maxIterations - 1 )
	
	return NMProgressCall( fraction, progressStr )
	
End // NMProgress

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressKill()

	return NMProgressCall( 1, "" )

End // NMProgressKill

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressCall( fraction, progressStr )
	Variable fraction // fraction of progress ( 0 ) create ( 1 ) kill prog window ( -1 ) create candy ( -2 ) spin
	String progressStr
	
	SetNMstr( NMDF+"ProgressStr", progressStr )
	
	// returns 1 for cancel
	
	if ( numtype( fraction ) > 0 )
		return -1
	endif
	
	switch( NMProgressFlag() )
	
		case 1:
			return NMProgWinXOP( fraction )
			
		case 2:
			return NMProgWin61( fraction, progressStr )
			
	endswitch
	
	return 0

End // NMProgressCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgWinXOP( fraction )
	Variable fraction // fraction of progress ( 0 ) create ( 1 ) kill prog window ( -1 ) create candy ( -2 ) spin
	
	Variable xProgress = NMProgressX()
	Variable yProgress = NMProgressY()
	
	String ProgressStr = NMStrGet( "ProgressStr" )
	
	String win = "win=( " + num2str( xProgress ) + "," + num2str( yProgress ) + " )"
	String txt = "text=" + NMQuotes( ProgressStr )
	
	if ( numtype( fraction ) > 0 )
		return -1
	endif

	if ( fraction == -1 )
		Execute /Z "ProgressWindow open=candy, button=\"cancel\", buttonProc=NMProgWinXOPCancel," + win + "," + txt
		KillVariables /Z V_Progress
	elseif ( fraction == -2 )
		Execute /Z "ProgressWindow spin"
	elseif ( fraction == 0 )
		Execute /Z "ProgressWindow open, button=\"cancel\", buttonProc=NMProgWinXOPCancel," + win + "," + txt
		KillVariables /Z V_Progress
	endif
	
	if ( fraction >= 0 )
		Execute /Z "ProgressWindow frac=" + num2str( fraction )
	endif
	
	if ( fraction >= 1 )
		Execute /Z "ProgressWindow kill"
		KillVariables /Z V_Progress
		KillVariables /Z $NMDF+"ProgressLoopTimer"
		SetNMstr( NMDF+"ProgressStr", "" )
	endif
	
	Variable pflag = NumVarOrDefault( "V_Progress", 0 ) // progress flag, set to 1 if user hits "cancel" on ProgWin
	
	if ( pflag == 1 )
		Execute /Z "ProgressWindow kill"
	endif
	
	return pflag // returns the value of V_Progress ( WinProg XOP ), or 0 if it does not exist

End // NMProgWinXOP

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgWinXOPCancel( buttonNum, buttonName )
	Variable buttonNum
	String buttonName
	
	Execute /Z "ProgressWindow kill"
	
	SetNMstr( NMDF+"ProgressStr", "" )
	
End // NMProgWinXOPCancel

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgWin61( fraction, progressStr [ buttonNameList, buttonFxn ] ) // Igor Progress Window
	Variable fraction
	String progressStr
	String buttonNameList
	String buttonFxn
	
	// fraction of progress between 0 and 1, where ( 0 ) creates and ( 1 ) kills progress window
	// candy ( -1 ) create candy ( -2 ) spin candy ( 1 ) kill candy
	
	Variable xProgress, yProgress, pheight, icnt
	Variable x0, y0, x1, y1, xw
	Variable fs = 12
	String bname, btitle
	
	if ( ParamIsDefault( buttonNameList ) )
		buttonNameList = ""
	endif
	
	if ( ParamIsDefault( buttonFxn ) )
		buttonFxn = ""
	endif
	
	if ( numtype( fraction ) > 0 )
		return -1
	endif
	
	if ( IgorVersion() < 6.1 )
		return -1 // not available
	endif
	
	pheight = NMProgWinHeight + 30 * ItemsInList( buttonNameList ) // extra buttons
		
	if ( fraction >= 1 ) // kill progress display
	
		NMProgWin61Kill()
		
		return 0
	
	elseif ( ( fraction == 0 ) || ( fraction == -1 ) ) // create progress display
	
		if ( WinType( "NMProgressPanel" ) != 0 )
			KillWindow NMProgressPanel
		endif
		
		xProgress = NMProgressX()
		yProgress = NMProgressY()
		
		xw = NMProgWinWidth - 10
		
		x0 = xProgress
		y0 = yProgress
		x1 = xProgress + NMProgWinWidth
		y1 = yProgress + pheight
	
		NewPanel /FLT/K=1/N=NMProgressPanel /W=(x0,y0,x1,y1 ) as "NM Progress"
		
		TitleBox /Z NM_ProgWinTitle, pos={5,10}, size={xw,18}, fsize=fs, fixedSize=1, win=NMProgressPanel
		TitleBox /Z NM_ProgWinTitle, frame=0, title=progressStr, anchor=MC, win=NMProgressPanel
	
		ValDisplay /Z NM_ProgWinValDisplay, pos={5,40}, size={xw,18}, limits={0,1,0}, barmisc={0,0}, win=NMProgressPanel
		ValDisplay /Z NM_ProgWinValDisplay, highColor=(1,34817,52428), win=NMProgressPanel // green
		
		if ( fraction == -1 )
			ValDisplay /Z NM_ProgWinValDisplay, mode=4, value= _NUM:0, win=NMProgressPanel // candy stripe
		else
			ValDisplay /Z NM_ProgWinValDisplay, mode=3, value= _NUM:0, win=NMProgressPanel // bar with no fractional part
		endif
		
		x0 = NMProgButtonX0
		y0 = NMProgButtonY0
	
		Button NM_ProgWinButtonCancel, pos={x0,y0}, size={NMProgButtonXwidth,NMProgButtonYwidth}, fsize=fs, title="Cancel", win=NMProgressPanel, proc=NMProgWin61Button
	
		if ( ( ItemsInList( buttonNameList ) > 0 ) && ( exists( buttonFxn ) == 6 ) )
		
			for ( icnt = 0 ; icnt < ItemsInList( buttonNameList ) ; icnt += 1 )
			
				bname = "NM_ProgWinButton" + num2istr( icnt )
				btitle = StringFromList( icnt, buttonNameList )
				
				y0 += 30
				
				Button $bname, pos={x0,y0}, size={NMProgButtonXwidth,NMProgButtonYwidth}, fsize=fs, title=btitle, win=NMProgressPanel, proc=$buttonFxn
			
			endfor
			
		endif
		
		SetActiveSubwindow _endfloat_
		
		DoUpdate /W=NMProgressPanel /E=1 // mark this as our progress window
		
		if ( WinType( "NMProgressPanel" ) == 7 ) // need if-statement to prevent Igor error
			SetWindow NMProgressPanel, hook(nmprogwin61)=NMProgWin61Hook
		endif
		
		SetNMvar( NMDF+"NMProgressCancel", 0 )
		
		return 0
		
	elseif ( NumVarOrDefault( NMDF + "NMProgressCancel", 0 ) == 1 )
	
		NMProgWin61Kill()
	
		return 1 // cancel
	
	elseif ( WinType( "NMProgressPanel" ) == 7 )
	
		DoWindow /F NMProgressPanel
		DoUpdate /W=NMProgressPanel /E=1
		
		TitleBox /Z NM_ProgWinTitle, title=progressStr, win=NMProgressPanel
		DoUpdate /W=NMProgressPanel
		
		if ( fraction > 0 )
			ValDisplay /Z NM_ProgWinValDisplay,mode=3,value= _NUM:fraction,win=NMProgressPanel // update bar fraction
		elseif ( fraction < 0 )
			ValDisplay /Z NM_ProgWinValDisplay,mode=4,value= _NUM:1,win=NMProgressPanel // update candy
		endif
	
	endif
	
	return 0

End // NMProgWin61

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgWin61Kill()

	if ( WinType( "NMProgressPanel" ) == 0 )
		return 0
	endif
	
	GetWindow NMProgressPanel, wsize
	
	Variable scale = 1 / NMPointsPerPixel()
	
	SetNMvar( NMDF + "xProgress", V_left * scale )
	SetNMvar( NMDF + "yProgress", V_top * scale ) // save progress window position
	
	KillWindow NMProgressPanel

	return 0
	
End // NMProgWin61Kill

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgWin61Hook(s)
	STRUCT WMWinHookStruct &s
	
	if ( ( s.eventCode == 5 ) || ( s.eventCode == 17 ) )
	
		//DoUpdate /W=$s.winName // THIS CODE FROM IGOR HELP DOES NOT WORK
	
		//if ( V_Flag == 2 )	// we only have one button and that means abort
		//	KillWindow $s.winName
		//	return 1
		//endif
		
		if ( ( s.mouseLoc.h >= NMProgButtonX0 ) && ( s.mouseLoc.h <= NMProgButtonX0 + NMProgButtonXwidth ) )
			if ( ( s.mouseLoc.v >= NMProgButtonY0 ) && ( s.mouseLoc.v <= NMProgButtonY0 + NMProgButtonYwidth ) )
				SetNMvar( NMDF + "NMProgressCancel", 1 )
				return 1
			endif
		endif
		
	endif
	
	return 0
	
End //NMProgWin61Hook

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgWin61Button( ctrlName ) : ButtonControl // DOES NOT ALWAYS WORK
	String ctrlName
	
	strswitch( ctrlName )
	
		case "NM_ProgWinButtonCancel":
			SetNMvar( NMDF + "NMProgressCancel", 1 )
			//KillWindow NMProgressPanel
			break
			
		case "NM_ProgWinButton0":
			//print "Button0"
			//NMNotesAddNote("Button0")
			break
	
	
	endswitch
	
	return 0

End // NMProgWin61Button

//****************************************************************
//****************************************************************

Function NMProgWin61Popup(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	PopupMenu NM_ProgWinPopup, mode=1, win=NMProgressPanel
	
	strswitch( popStr )
	
		case " ":
			return 0 // nothing
	
		default:

			Print popStr
			
	endswitch

End // NMProgWin61Popup

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressXYPanel() // set Progress X,Y location
	
	Variable xProgress = NMProgressX()
	Variable yProgress = NMProgressY()
	
	Variable x2 = xProgress + NMProgWinWidth
	Variable y2 = yProgress + NMProgWinHeight
	
	String titleStr = "Move to desired location and click save..."
	
	DoWindow /K NMProgressPanel
	NewPanel /K=1/N=NMProgressPanel/W=(xProgress,yProgress,x2,y2) as "NM Progress Window"
	
	TitleBox /Z NM_ProgTitle, pos={5,15}, size={NMProgWinWidth-10,18}, fsize=11,fixedSize=1,win=NMProgressPanel
	TitleBox /Z NM_ProgTitle, frame=0,title=titleStr, anchor=MC,win=NMProgressPanel
	
	Button NM_ProgButton, pos={65,50}, title = "Save Location", size={130,20}, proc=NMProgressXYButton

End // NMProgressXYPanel

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressXYButton( ctrlName ) : ButtonControl
	String ctrlName
	
	Variable x, y, scale = 1
	
	if ( NMProgressFlag() == 2 )
		scale = 1 / NMPointsPerPixel()
	endif
	
	GetWindow NMProgressPanel, wsize
	
	x = round( V_left * scale )
	y = round( V_top * scale )
	
	NMSet( xProgress = x, yProgress = y, history = 1 )
	
	DoWindow /K NMProgressPanel
	
End // NMProgressXYButton

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressTest( candy )
	Variable candy // ( 0 ) no ( 1 ) yes

	Variable t0, icnt, jcnt, imax = 100
	
	if ( candy == 1 )
		NMProgressCall( -1, "Testing Progress..." ) // make candy
	endif
	
	for ( icnt = 0; icnt < imax; icnt += 1 )
	
		if ( candy == 1 )
			jcnt = -2
		else
			jcnt = icnt / ( imax - 1 )
		endif
		
		if ( NMProgressCall( jcnt, "Testing Progress: " + num2str( icnt ) ) == 1 )
			break // cancel
		endif
	
		t0 = ticks
	
		do
		while( ticks < ( t0 + 3 ) ) // slow down the loop
		
	endfor
	
	NMProgressKill()
	
	return 0

End // NMProgressTest

//****************************************************************
//****************************************************************
//****************************************************************

Function NMProgressXY( xpixels, ypixels ) // NOT USED
	Variable xpixels, ypixels
	
	if ( ( numtype( xpixels ) > 0 ) || ( xpixels < 0 ) )
		xpixels = NaN
	endif
	
	if ( ( numtype( ypixels ) > 0 ) || ( ypixels < 0 ) )
		ypixels = NaN
	endif
	
	SetNMvar( NMDF+"xProgress", xpixels )
	SetNMvar( NMDF+"yProgress", ypixels )
	
	return 0

End // NMProgressXY

//****************************************************************
//****************************************************************
//****************************************************************
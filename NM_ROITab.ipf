#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma hide = 1

//****************************************************************
//****************************************************************
//
//	ROI Tab for ROI analysis
//	To be run with NeuroMatic
//	NeuroMatic.ThinkRandom.com
//	Code for WaveMetrics Igor Pro
//
//	By Jason Rothman ( Jason@ThinkRandom.com )
//
//****************************************************************
//****************************************************************

Static StrConstant tabPrefix = "ROI_"

StrConstant NMROIDF = "root:Packages:NeuroMatic:ROI:"

//****************************************************************
//****************************************************************
//
//	ROI Tab Functions
//
//****************************************************************
//****************************************************************

Function /S NMTabPrefix_ROI() // this function allows NM to determine tab name and prefix

	return tabPrefix

End // NMTabPrefix_ROI

//****************************************************************
//****************************************************************

Function NMROITab( enable ) // called by ChangeTab
	Variable enable // ( 0 ) disable ( 1 ) enable tab
	
	if ( enable == 1 )
		CheckNMPackage( "ROI", 1 ) // declare globals if necessary
		NMROIMake() // create tab controls if necessary
		NMChannelGraphDisable( channel = -2, all = 0 )
		NMROIAuto()
	endif
	
	NMROIDisplay( -1, enable )

End // NMROITab

//****************************************************************
//****************************************************************

Function NMROITabKill( what ) // called by KillTab
	String what
	
	String df = NMROIDF

	// KillTab will automatically kill objects that begin with appropriate prefix.
	// Place any other things to kill here.
	
	strswitch( what )
	
		case "waves":
			// kill any other waves here
			break
			
		case "folder":
			if ( DataFolderExists( df ) == 1 )
				KillDataFolder $df
			endif
			break
			
	endswitch

End // NMROITabKill

//****************************************************************
//****************************************************************
//
//		Variables, Strings, Waves and folders
//
//****************************************************************
//****************************************************************

Function NMROISet( [ currentROI, setNum, xbgn, xend, wavePrefix, history ] )
	
	Variable currentROI // current ROI for display on NM panel and graphs
	
	Variable setNum // ROI number for xbgn, xend, wavePrefix ( pass nothing to get currentROI )
	Variable xbgn, xend
	String wavePrefix
	
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable foundWin, updateROITab = 0, updateGraphs = 0
	String vlist = "", vlistWin = ""
	
	String df = NMROIDF
	
	if ( !ParamIsDefault( currentROI ) )
	
		vlist = NMCmdNumOptional( "currentROI", currentROI, vlist )
	
		if ( ( numtype( currentROI ) > 0 ) || ( currentROI < 0 ) )
			return NM2Error( 10, "currentROI", num2str( currentROI ) )
		endif
		
		SetNMvar( df + "CurrentROI", currentROI )
		
		NMROICheck()
		
		updateGraphs = 1
	
	endif
	
	if ( ParamIsDefault( setNum ) )
		setNum = NumVarOrDefault( df + "CurrentROI", NaN )
	endif
	
	vlistWin = NMCmdNumOptional( "setNum", setNum, "", integer = 1 )
	
	if ( !ParamIsDefault( xbgn ) )
	
		vlistWin = NMCmdNumOptional( "xbgn", xbgn, vlistWin )
		
		if ( numtype( setNum ) > 0 )
			return NM2Error( 10, "setNum", num2str( setNum ) )
		endif
		
		//si.xbgn[ win ] = z_CheckXbgn( xbgn )
		
		Wave wtemp = $df + "wleft"
		
		wtemp[ setNum ] = z_CheckXend( xbgn )
		
		updateGraphs = 1
		foundWin = 1
		
	endif
	
	if ( !ParamIsDefault( xend ) )
	
		vlistWin = NMCmdNumOptional( "xend", xend, vlistWin )
		
		if ( numtype( setNum ) > 0 )
			return NM2Error( 10, "setNum", num2str( setNum ) )
		endif
		
		//si.xend[ win ] = z_CheckXend( xend )
		
		Wave wtemp = $df + "wright"
		
		wtemp[ setNum ] = z_CheckXend( xend )
		
		updateGraphs = 1
		foundWin = 1
		
	endif
	
	if ( !ParamIsDefault( wavePrefix ) )
	
		vlistWin = NMCmdStrOptional( "wavePrefix", wavePrefix, vlistWin )
		
		if ( numtype( setNum ) > 0 )
			return NM2Error( 10, "setNum", num2str( setNum ) )
		endif
	
		Wave /T stemp = $df + "WavePrefixes"
		
		stemp[ setNum ] = wavePrefix
		foundWin = 1
	
	endif
	
	if ( history )
		if ( foundWin )
			NMCommandHistory( vlist + vlistWin )
		else
			NMCommandHistory( vlist )
		endif
		
	endif
	
	if ( updateGraphs )
		//StatsChanControlsUpdate( -1, -1, 1 )
		//NMChanGraphUpdate()
		NMROIDisplay( -1, 1 )
		
	endif
	
	NMROIUpdate()
	
	//if ( statsAuto )
		//NMStatsAuto()
	//elseif ( updateStatsTab )
		//UpdateStats()
	//endif
	
End // NMROISet

//****************************************************************
//****************************************************************

Static Function z_CheckXbgn( xbgn )
	Variable xbgn
	
	if ( numtype( xbgn ) > 0 )
		return -inf
	else
		return xbgn
	endif
	
End // z_CheckXbgn

//****************************************************************
//****************************************************************

Static Function z_CheckXend( xend )
	Variable xend
	
	if ( numtype( xend ) > 0 )
		return inf
	else
		return xend
	endif
	
End // z_CheckXend

//****************************************************************
//****************************************************************

Function CheckNMROILineScanSelect( select )
	Variable select

	if ( select == -1 )
		select = NumVarOrDefault( NMROIDF + "LineScanSelect", 0 ) // currently selected line scan
	endif
	
	if ( ( numtype( select ) > 0 ) || ( select < 0 ) )
		NM2Error( 10, "select", num2istr( select ) )
		return Nan
	endif
	
	CheckNMROIWaves( 0, pointsAtLeast = ( select + 1 ), errorAlert = 1 )
	
	return select

End // CheckNMROILineScanSelect

//****************************************************************
//****************************************************************

Function NMROICheck() // declare global variables

	Variable currentROI
	String df = NMROIDF
	
	if ( DataFolderExists( df ) == 0 )
		return -1 // folder doesnt exist
	endif
	
	CheckNMvar( df + "CurrentROI", 0 )
	CheckNMvar( df + "Vleft", -inf )
	CheckNMvar( df + "Vtop", -inf )
	CheckNMvar( df + "Vright", inf )
	CheckNMvar( df + "Vbottom", inf )
	CheckNMstr( df + "WavePrefix", "ROI" )
	
	currentROI = NumVarOrDefault( df + "CurrentROI", 0 )
	
	CheckNMROIWaves( 0, pointsAtLeast = ( currentROI + 1 ), errorAlert = 1 ) 
	
	return 0
	
End // NMROICheck

//****************************************************************
//****************************************************************

Function CheckNMROIWaves( reset [ df, pointsAtLeast, errorAlert ] )
	Variable reset
	String df
	Variable pointsAtLeast
	Variable errorAlert
	
	Variable icnt, points = 1
	
	if ( ParamIsDefault( df ) )
		df = NMROIDF
	endif
	
	if ( !DataFolderExists( df ) )
		return -1
	endif
	
	if ( WaveExists( $df + "wleft" ) )
		points = numpnts( $df + "wleft" )
	endif
	
	points = max( points, pointsAtLeast )
	
	CheckNMROIWave( "wleft", -inf, reset, points = points )
	CheckNMROIWave( "wright", inf, reset, points = points )
	
	CheckNMROIWaveT( "WavePrefixes", "", reset, points = points )
	
	Wave /T wprefix = $df + "WavePrefixes"
	
	for ( icnt = 0 ; icnt < numpnts( wprefix ) ; icnt += 1 )
		
		if ( strlen( wprefix[ icnt ] ) == 0 )
			wprefix[ icnt ] = "ROI" + num2istr( icnt )
		endif
	
	endfor
	
	return 0

End // CheckNMROIWaves

//****************************************************************
//****************************************************************

Function CheckNMROIWave( wName, value, reset [ points ] )
	String wName // wave name
	Variable value
	Variable reset
	Variable points
	
	String df = NMROIDF
	
	if ( strlen( wName ) == 0 )
		return NM2Error( 21, "wName", wName )
	endif
	
	if ( !DataFolderExists( df ) )
		return NM2Error( 30, "ROIDF", df )
	endif
	
	if ( ParamIsDefault( points ) )
		points = 1
	endif
	
	if ( reset )
		return SetNMwave( df + wName, -1, value )
	else
		return CheckNMWaveOfType( df + wName, points, value, "R" )
	endif
	
End // CheckNMROIWave

//****************************************************************
//****************************************************************

Function CheckNMROIWaveT( wName, strvalue, reset [ points ] )
	String wName // wave name
	String strvalue
	Variable reset
	Variable points
	
	String df = NMROIDF
	
	if ( strlen( wName ) == 0 )
		return NM2Error( 21, "wName", wName )
	endif
	
	if ( !DataFolderExists( df ) )
		return NM2Error( 30, "ROIDF", df )
	endif
	
	if ( ParamIsDefault( points ) )
		points = 1
	endif
	
	if ( reset )
		return SetNMtwave( df + wName, -1, strvalue )
	else
		return CheckNMtwave( df + wName, points, strvalue )
	endif
	
End // CheckNMROIWaveT

//****************************************************************
//****************************************************************

Function NMROIConfigs()

	//NMConfigVar( tabName, "DumVar", 11, "dummy variable", "units" )
	//NMConfigStr( tabName, "DumStr", "Anything", "dummy text variable", "units" )
	
	//NMConfigWave( tabName, "DumWave", 5, 22, "dummy wave" )
	//NMConfigTWave( tabName, "DumTxtWave", 5, "anything", "dummy text wave" )

End // NMROIConfigs

//****************************************************************
//****************************************************************
//
//		Tab Panel Functions
//
//****************************************************************
//****************************************************************

Function NMROIAuto()

	NMROIUpdate()

End // NMROIAuto
	
//****************************************************************
//****************************************************************

Function NMROIMake()

	Variable x0 = 50, xinc, yinc = 60, fs = NMPanelFsize
	Variable y0 = NMPanelTabY + 80
	
	String df = NMROIDF

	ControlInfo /W=$NMPanelName $"ROI_AllWaves"
	
	if ( V_Flag != 0 )
		return 0 // tab controls exist, return here
	endif

	DoWindow /F $NMPanelName
	
	x0 = 90
	xinc = 150
	y0 = NMPanelTabY + 60
	yinc = 27
	
	SetVariable ROI_NumSet, title="ROI #", pos={x0,y0+0*yinc}, size={115,50}, limits={0,9999,1}, fsize=fs, format = "%d", win=$NMPanelName
	SetVariable ROI_NumSet, value=$df+"CurrentROI", proc=NMROISetVariable, win=$NMPanelName
	
	SetVariable ROI_VleftSet, title="xbgn", pos={x0,y0+1*yinc}, size={115,50}, limits={-inf,inf,1}, fsize=fs, format = "%d", win=$NMPanelName
	SetVariable ROI_VleftSet, value=$df+"vleft", proc=NMROISetVariable, win=$NMPanelName
	
	SetVariable ROI_VrightSet, title="xend", pos={x0,y0+2*yinc}, size={115,50}, limits={-inf,inf,1}, fsize=fs, format = "%d", win=$NMPanelName
	SetVariable ROI_VrightSet, value=$df+"vright", proc=NMROISetVariable, win=$NMPanelName
	
	SetVariable ROI_PrefixSet, title="wave prefix", pos={x0,y0+3*yinc}, size={115,50}, fsize=fs, win=$NMPanelName
	SetVariable ROI_PrefixSet, value=$df+"WavePrefix", proc=NMROISetVariable, win=$NMPanelName
	
	Button ROI_AllWaves, title="All Waves", pos={x0,y0+5*yinc}, size={100,20}, proc=NMROIButton, fsize=fs, win=$NMPanelName
	
	NMROIUpdate()

End // NMROIMake

//****************************************************************
//****************************************************************

Function NMROIUpdate()

	Variable xleft, xright, lx, rx, updateDisplay
	String df = NMROIDF
	
	Variable num = NumVarOrDefault( df+"CurrentROI", 0 )
	String dName = ChanDisplayWave( -1 )
	
	Wave wleft = $df+"wleft"
	Wave wright = $df+"wright"
	
	Wave /T wprefix = $df+"WavePrefixes"
	
	if ( ( numtype( num ) == 0 ) && ( num >= 0 ) && ( num < numpnts( wleft ) ) )
	
		xleft = wleft[ num ]
		xright = wright[ num ]
		
		if ( numtype( xleft ) > 0 )
			lx = leftx( $dName )
			rx = rightx( $dName )
			xleft = lx + 0.4 * ( rx - lx ) // move to center
			wleft[ num ] = xleft
			updateDisplay = 1
		endif
		
		if ( numtype( xright ) > 0 )
			lx = leftx( $dName )
			rx = rightx( $dName )
			xright = rx - 0.4 * ( rx - lx ) // move to center
			wright[ num ] = xright
			updateDisplay = 1
		endif
		
		SetNMvar( df+"vleft", xleft )
		SetNMvar( df+"vright", xright )
		SetNMstr( df+"WavePrefix", wprefix[ num ] )
		
		if ( updateDisplay )
			NMROIDisplay( -1, 1 )
		endif
		
	endif

End // NMROIUpdate

//****************************************************************
//****************************************************************

Function NMROIButton( ctrlName ) : ButtonControl
	String ctrlName
	
	String fxn = ReplaceString( tabPrefix, ctrlName, "" )
	
	NMROICall( fxn, "" )
	
End // NMROIButton

//****************************************************************
//****************************************************************

Function NMROISetVariable( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	String fxn = ReplaceString( tabPrefix, ctrlName, "" )
	
	NMROICall( fxn, varStr )
	
End // NMROISetVariable

//****************************************************************
//****************************************************************

Function NMROICall( fxn, select )
	String fxn // function name
	String select // parameter string variable
	
	Variable error
	
	Variable snum = str2num( select ) // parameter variable number
	
	strswitch( fxn )
	
		case "NumSet":
			error = NMROISet( currentROI = snum, history = 1 )
			break
	
		case "VleftSet":
			error = NMROISet( xbgn = snum, history = 1 )
			break
			
		case "VrightSet":
			error = NMROISet( xend = snum, history = 1 )
			break
			
		case "PrefixSet":
			error = NMROISet( wavePrefix = select, history = 1 )
			break
			
		case "AllWaves":
		case "All Waves":
			NMROICompute( history = 1 )
			break

	endswitch
	
End // NMROICall

//****************************************************************
//****************************************************************
//
//	Channel Graph Functions
//
//****************************************************************
//****************************************************************

Function NMROIDisplay( chan, appnd )
	Variable chan // channel number ( -1 ) for current channel
	Variable appnd // 1 - append wave; 0 - remove wave
	
	Variable ccnt, drag = appnd
	String gName, sname
	
	String df = NMROIDF
	
	if ( !DataFolderExists( df ) )
		return 0
	endif
	
	if ( !StringMatch( CurrentNMTabName(), "ROI" ) )
		drag = 0
	endif
	
	for ( ccnt = 0 ; ccnt < NMNumChannels() ; ccnt += 1 )
	
		gName = ChanGraphName( ccnt )
	
		if ( Wintype( gName ) == 0 )
			continue // window does not exist
		endif

		RemoveFromGraph /Z/W=$gName DragBgnY, DragEndY
		
	endfor

	gName = ChanGraphName( chan )
	
	sName = NMChanWaveName( chan, 0 )
	
	if ( DimSize( $sName, 1 ) == 0 )
		drag = 0
	endif
	
	NMDragEnable( drag, "DragBgn", df+"wleft", df+"CurrentROI", "", gName, "bottom", "min", 65535, 0, 0 )
	NMDragEnable( drag, "DragEnd", df+"wright", df+"CurrentROI", "", gName, "bottom", "max", 65535, 0, 0 )
	
	if ( !appnd )
		//NMROIRemoveDisplayWaves()
	endif

End // NMROIDisplay

//****************************************************************
//****************************************************************

Function NMROIDragClear()
	
	NMDragClear( "DragBgn" )
	NMDragClear( "DragEnd" )
	NMDragClear( "DragBslnBgn" )
	NMDragClear( "DragBslnEnd" )

End // NMFitDragClear

//****************************************************************
//****************************************************************

Function NMROICompute( [ chanSelectList, waveSelectList, windowList, graph, history ] )
	String chanSelectList // channel select list ( e.g. "A;B;" )
	String waveSelectList // wave select list ( e.g. "Set1;Set2;" )
	String windowList // window number list ( e.g. "0;1;2;" or "All" )
	Variable graph // plot output waves
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable icnt, ccnt, channel, wcnt, jcnt, win, xbgn, xend
	Variable xpnts, ypnts, xcnt, ycnt, xsum, xcount
	String wName, outName, newPrefix, wavePrefix
	Variable chanSelectListItems, waveSelectListItems
	String chanSelectStr, progressStr, vlist = ""
	
	String df = NMROIDF
	
	Wave wleft = $df + "wleft"
	Wave wright = $df + "wright"
	Wave /T wprefix = $df + "WavePrefixes"
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = NMChanSelectAllList()
	else
		vlist = NMCmdStrOptional( "chanSelectList", chanSelectList, vlist )
	endif
	
	if ( StringMatch( chanSelectList, "All" ) )
		chanSelectList = NMChanSelectAllList()
	endif
	
	chanSelectListItems = ItemsInList( chanSelectList )
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = NMWaveSelectAllList()
	else
		vlist = NMCmdStrOptional( "waveSelectList", waveSelectList, vlist )
	endif
	
	if ( StringMatch( waveSelectList, "All" ) )
		waveSelectList = NMWaveSelectAllList()
	endif

	waveSelectListItems = ItemsInList( waveSelectList )
	
	if ( ParamIsDefault( windowList ) )
		windowList = "All" // NMStatsWinList( 1, "" ) // all windows
	else
		vlist = NMCmdStrOptional( "windowList", windowList, vlist )
	endif
	
	if ( StringMatch( windowList, "All" ) )
	
		windowList = ""
		
		for ( icnt = 0 ; icnt < numpnts( wleft ) ; icnt += 1 )
			windowList += num2istr( icnt ) + ";"
		endfor
		
	endif
	
	if ( ParamIsDefault( graph ) )
		graph = 1
	else
		vlist = NMCmdNumOptional( "graph", graph, vlist, integer = 1 )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	Variable numWaves = NMNumWaves()
	
	String saveChanSelectStr = NMChanSelectStr()
	
	String waveSelect = NMWaveSelectGet()
	String saveWaveSelect = waveSelect
	
	Variable saveCurrentWave = CurrentNMWave()
	
	Variable waveLengthFormat = NMStatsVarGet( "WaveLengthFormat" )
	
	for ( icnt = 0 ; icnt < max( waveSelectListItems, 1 ) ; icnt += 1 ) // loop thru sets / groups
		
		if ( waveSelectListItems > 0 )
		
			waveSelect = StringFromList( icnt, waveSelectList )
			
			if ( !StringMatch( waveSelect, NMWaveSelectGet() ) )
				NMWaveSelect( waveSelect )
			endif
			
		endif
		
		if ( NMNumActiveWaves() <= 0 )
			continue
		endif
	
		for ( ccnt = 0 ; ccnt < max( chanSelectListItems, 1 ) ; ccnt += 1 ) // loop thru channels
		
			if ( chanSelectListItems > 0 )
			
				chanSelectStr = StringFromList( ccnt, chanSelectList )
				
				if ( !StringMatch( chanSelectStr, CurrentNMChanChar() ) )
					NMChanSelect( chanSelectStr )
					DoUpdate
				endif
				
			endif
			
			channel = CurrentNMChannel()
			
			//outputWaveList += StatsWavesMake( DEFAULTSUBFOLDER, channel, windowList )
			
			progressStr = "Line Scan Chan " + ChanNum2Char( channel )
		
			for ( wcnt = 0; wcnt < numWaves; wcnt += 1 ) // loop thru waves
				
				if ( NMProgress( wcnt, numWaves, progressStr ) == 1 )
					break
				endif
				
				wName = NMWaveSelected( channel, wcnt )
				
				if ( strlen( wName ) == 0 )
					continue // wave not selected, or does not exist... go to next wave
				endif
				
				NMCurrentWaveSet( wcnt )
				DoUpdate
				
				Wave wtemp = $wName
		
				for ( jcnt = 0 ; jcnt < ItemsInList( windowList ) ; jcnt += 1 ) // loop thru line scans windows
				
					win = str2num( StringFromList( jcnt, windowList ) )
					
					xbgn = wleft[ win ]
					xend = wright[ win ]
					
					wavePrefix = wprefix[ win ]
					
					xpnts = DimSize( wtemp, 0 )
					ypnts = DimSize( wtemp, 1 )
					
					if ( ( numtype( xbgn ) > 0 ) || ( xbgn < 0 ) || ( xbgn >= xpnts ) )
						continue
					endif
					
					if ( ( numtype( xend ) > 0 ) || ( xend < 0 ) || ( xend >= xpnts ) )
						continue
					endif
					
					//newPrefix = wavePrefix + num2str( win ) + "_"
					newPrefix = wavePrefix
					
					if ( strlen( newPrefix ) == 0 )
						newPrefix = "ROI" + num2istr( win ) + "_"
					endif
					
					outName = newPrefix + CurrentNMChanChar() + num2istr( wcnt )
					
					Make /O/N=( ypnts ) $outName = NaN
					
					Wave otemp = $outName
					
					for ( ycnt = 0 ; ycnt < ypnts ; ycnt += 1 )
					
						xcount = 0
						xsum = 0
					
						for ( xcnt = xbgn ; xcnt <= xend ; xcnt += 1 )
							xsum += wtemp[ xcnt ][ ycnt ]
							xcount += 1
						endfor
					
						otemp[ ycnt ] = xsum / xcount
					
					endfor
					
					NMPrefixAdd( newPrefix )
					
				endfor
					
			endfor
			
			if ( NMProgressCancel() == 1 )
				break
			endif
			
		endfor
		
		if ( NMProgressCancel() == 1 )
			break
		endif
		
	endfor
	
	if ( chanSelectListItems > 0 )
		NMChanSelect( saveChanSelectStr, update = 0 )
	endif
	
	if ( waveSelectListItems > 0 )
		NMWaveSelect( saveWaveSelect, update = 0 )
	endif
	
	NMCurrentWaveSet( saveCurrentWave, update = 0 )
	
End // NMROICompute

//****************************************************************
//****************************************************************
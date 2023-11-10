#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma hide = 1

//****************************************************************
//****************************************************************
//
//	NeuroMatic: data aquisition, analyses and simulation software that runs with the Igor Pro environment
//	Copyright (C) 2024 The Silver Lab, UCL
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
//	Fit Tab
//
//	Set and Get functions:
//
//		NMFitSet( [ fxn, numTerms, xoffset, pntsPerCycle, synExpSign, xbgn, xend, cursors, weighting, fitFullWidth, fitSave, fitPoints, fitResiduals, autoFit, printResults, update, history ] )
//		NMConfigVarSet( "Fit" , varName, value )
//		NMConfigStrSet( "Fit" , strVarName, strValue )
//		NMFitVarGet( varName )
//		NMFitStrGet( strVarName )
//
//	Useful functions:
//
//		NMFitUserFxnAdd( fxn, numParams [ history ] )
//		NMFitFxnListRemove( fxn [ history ] )
//		NMFitAll( [ chanSelectList, waveSelectList, pause, history ] )
//		NMFitWave( [ history ] )
//		NMFitWaveCompute( guessORfit [ history ] )
//		NMFitSaveCurrent( [ history ] )
//		NMFitClearCurrent( [ history ] )
//		NMFitClearAll( [ history ] )
//		NMFitPlotAll( plotData [ history ] )
//		NMFitSubfolderTable( subfolder [ history ] )
//
//****************************************************************
//****************************************************************

Static Constant OverwriteMode = 1 // ( 0 ) no ( 1 ) yes
Static Constant UserSubfolders = 1 // ( 0 ) no ( 1 ) yes
Static Constant FitAuto = 0 // compute fit when incrementing thru waves ( 0 ) no ( 1 ) yes
Static Constant AutoTable = 1 // create table of fit results ( 0 ) no ( 1 ) yes
Static Constant AutoGraph = 1 // create graph of fit results ( 0 ) no ( 1 ) yes
Static Constant SaveFitWaves = 1 // ( 0 ) no ( 1 ) yes
Static Constant FullGraphWidth = 0 // ( 0 ) no ( 1 ) yes
Static Constant Residuals = 0 // ( 0 ) no ( 1 ) yes
Static Constant PrintResults = 0 // ( 0 ) no ( 1 ) yes
Static Constant Weighting = 0 // ( 0 ) no ( 1 ) yes
Static Constant SynExpSign = 1 // ( -1 ) negative events ( 1 ) positive events
Static Constant printCurveFitCommand = 0 // print CurveFit command to history ( 0 ) no ( 1 )
			
Static Constant MaxIterations = 40
Static Constant Tolerance = 0.001
Static Constant MultiThreads = 1 // ( 0 ) no ( 1 ) yes
Static Constant FitMethod = 0 // 0, 1, 2, 3 ( see Igor CurveFit /ODR )

Static Constant KeidingGuessAuto = 1 // ( 0 ) no ( 1 ) yes
//Static Constant KeidingConstraints = 0 // ( 0 ) no ( 1 ) yes

Static StrConstant WeightingPrefix = "Stdv_" // weighting wave name prefix

Static StrConstant GHK_Xunits = "mV" // "V" or "mV"

StrConstant NMFitDF = "root:Packages:NeuroMatic:Fit:"

Static StrConstant IgorFitFxnList = "f:Line,n:2;f:Poly,n:3;f:Poly_XOffset,n:3;f:Gauss,n:4;f:Lor,n:4;f:Exp,n:3;f:Exp_XOffset,n:3;f:DblExp,n:5;f:DblExp_XOffset,n:5;f:Sin,n:4;f:HillEquation,n:4;f:Sigmoid,n:4;f:Power,n:3;f:LogNormal,n:4;"
Static StrConstant NMFitFxnList = "f:NMExp3,n:8;f:NMAlpha,n:4;f:NMGamma,n:3;f:NMGauss,n:2;f:NMGauss1,n:4;f:NMSynExp3,n:7;f:NMSynExp4,n:9;f:NM_IV,n:2;f:NM_IV_Boltzmann,n:5;f:NM_IV_GHK,n:4;f:NM_IV_GHK_Boltzmann,n:7;f:NM_MPFA1,n:4;f:NM_MPFA2,n:5;f:NM_RCvstep,n:6;f:NMCircle,n:3;f:NMEllipse,n:4;f:NMKeidingGauss,n:6;f:NMKeidingChi,n:4;f:NMKeidingGamma,n:5;"

//****************************************************************
//****************************************************************

Menu "NeuroMatic"

	Submenu StrVarOrDefault( NMDF + "NMMenuShortcuts" , "\\M1(Keyboard Shortcuts" )
		StrVarOrDefault( NMDF + "NMMenuShortcutFit0" , "" )
		StrVarOrDefault( NMDF + "NMMenuShortcutFit1" , "" ), /Q, NMFitCall( "Fit", "" )
		StrVarOrDefault( NMDF + "NMMenuShortcutFit2" , "" ), /Q, NMFitCall( "Save", "" )
		StrVarOrDefault( NMDF + "NMMenuShortcutFit3" , "" ), /Q, NMFitCall( "Clear", "" )
	End
	
End // NeuroMatic menu

//****************************************************************
//****************************************************************

Function NMMenuBuildFit()

	if ( NMVarGet( "NMOn" ) && StringMatch( CurrentNMTabName(), "Fit" ) )
		SetNMstr( NMDF + "NMMenuShortcutFit0", "-" )
		SetNMstr( NMDF + "NMMenuShortcutFit1", "Fit Wave/4" )
		SetNMstr( NMDF + "NMMenuShortcutFit2", "Save Fit/5" )
		SetNMstr( NMDF + "NMMenuShortcutFit3", "Clear Fit/6" )
	else
		SetNMstr( NMDF + "NMMenuShortcutFit0", "" )
		SetNMstr( NMDF + "NMMenuShortcutFit1", "" )
		SetNMstr( NMDF + "NMMenuShortcutFit2", "" )
		SetNMstr( NMDF + "NMMenuShortcutFit3", "" )
	endif

End // NMMenuBuildFit

//****************************************************************
//****************************************************************

Function /S NMTabPrefix_Fit()

	return "FT_"

End // NMTabPrefix_Fit

//****************************************************************
//****************************************************************
//****************************************************************

Function FitTab( enable )
	Variable enable // ( 0 ) disable ( 1 ) enable tab
	
	if ( enable )
		CheckNMPackage( "Fit", 1 ) // declare globals if necessary
		NMChannelGraphDisable( channel = CurrentNMChannel(), all = 0 )
		NMFitMake() // create tab controls if necessary
		NMFitUpdate()
	endif
	
	NMFitDisplay( -1, enable )
	
	if ( enable )
		NMFitAuto()
	endif

End // FitTab

//****************************************************************
//****************************************************************
//****************************************************************

Function FitTabKill( what )
	String what
	
	strswitch( what )
	
		case "waves":
			// kill any other waves here
			break
			
		case "folder":
			if ( DataFolderExists( NMFitDF ) )
				KillDataFolder $NMFitDF
			endif
			break
			
	endswitch

End // FitTabKill

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Channel Graph Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitDisplay( chan, appnd )
	Variable chan // channel number ( -1 ) for current channel
	Variable appnd // 1 - append wave; 0 - remove wave
	
	Variable ccnt, drag = appnd
	String gName
	
	if ( !DataFolderExists( NMFitDF ) )
		return 0
	endif
	
	if ( !NMVarGet( "DragOn" ) || !StringMatch( CurrentNMTabName(), "Fit" ) )
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
	
	NMDragEnable( drag, "DragBgn", "", NMFitDF+"Xbgn", "", gName, "bottom", "min", 65535, 0, 0 )
	NMDragEnable( drag, "DragEnd", "", NMFitDF+"Xend", "", gName, "bottom", "max", 65535, 0, 0 )
	
	if ( !appnd )
		NMFitRemoveDisplayWaves()
	endif
	
	KillWaves /Z $NMDF + "DragTbgnX" // old waves
	KillWaves /Z $NMDF + "DragTbgnY"

End // NMFitDisplay

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitDisplayClear()

	String dwave = NMFitDisplayWaveName()
	String df = NMFitWaveDF()
	String wName = df + "W_sigma"
	
	if ( WaveExists( $dwave ) )
		Wave wtemp = $dwave
		wtemp = Nan
	endif
	
	if ( WaveExists( $wName ) )
		Wave wtemp = $wName
		wtemp = Nan
	endif
	
	NMFitRemoveDisplayWaves()
	
	NMDragClear( "DragBgn" )
	NMDragClear( "DragEnd" )

End // NMFitDisplayClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitRemoveDisplayWaves()

	Variable ccnt, wcnt
	String gName, wName

	for ( ccnt = 0 ; ccnt < NMNumChannels() ; ccnt += 1 )
	
		gName = ChanGraphName( ccnt )
	
		if ( Wintype( gName ) == 0 )
			continue
		endif
		
		GetWindow $gName wavelist
		
		if ( !WaveExists( $"W_WaveList" ) )
			continue
		endif
		
		Wave /T W_WaveList // 3 column text wave
		
		if ( DimSize( W_WaveList, 1 ) != 3 )
			continue
		endif
		
		for ( wcnt = 0 ; wcnt < DimSize( W_WaveList, 0 ) ; wcnt += 1 )
		
			wName = W_WaveList[ wcnt ][ 0 ]
			
			if ( ( StrSearch( wName, "Fit_", 0, 2 ) >= 0 ) || ( StrSearch( wName, "Res_", 0, 2 ) >= 0 ) )
				RemoveFromGraph /W=$gName /Z $wName
			endif
			
		endfor
		
	endfor
	
	KillWaves /Z W_WaveList
	
	return 0

End // NMFitRemoveDisplayWaves

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Global Variables, Strings and Waves
//
//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMFitVar( varName )
	String varName
	
	return CheckNMvar( NMFitDF+varName, NMFitVarGet( varName ) )

End // CheckNMFitVar

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMFitStr( strVarName )
	String strVarName
	
	return CheckNMstr( NMFitDF+strVarName, NMFitStrGet( strVarName ) )

End // CheckNMFitStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitConfigs()
			
	NMConfigVar( "Fit", "UseSubfolders", UserSubfolders, "use subfolders when creating Fit result waves ( uncheck for previous NM formatting )", "boolean" )
	NMConfigVar( "Fit", "MaxIterations", MaxIterations, "maximum number of passes before stopping fit", "" )
	NMConfigVar( "Fit", "Tolerance", Tolerance, "fit termination tolerance", "" )
	NMConfigVar( "Fit", "MultiThreads", MultiThreads, "use multiple processors", "boolean" )
	NMConfigVar( "Fit", "FitMethod", FitMethod, "fitting method as defined by Igor CurveFit ODR", "0;1;2;3;" )
	
	NMConfigVar( "Fit", "Weighting", Weighting, "use STDV or SEM values to compute weighted fit", "boolean" )
	NMConfigStr( "Fit", "WeightingWavePrefix", WeightingPrefix, "weighting wave name prefix", "" )
	
	NMConfigVar( "Fit", "FullGraphWidth", FullGraphWidth, "compute fits for entire x-axis", "boolean" )
	NMConfigVar( "Fit", "SaveFitWaves", SaveFitWaves, "save fits to current data folder", "boolean" )
	NMConfigVar( "Fit", "Residuals", Residuals, "compute residuals", "boolean" )
	NMConfigVar( "Fit", "FitAuto", FitAuto, "auto fit when changing wave number", "boolean" )
	NMConfigVar( "Fit", "AutoTable", AutoTable, "create table of fit results", "boolean" )
	NMConfigVar( "Fit", "AutoGraph", AutoGraph, "create graph of fit results", "boolean" )
	NMConfigVar( "Fit", "PrintResults", PrintResults, "print fit results to Igor Command Window", "boolean" )
	
	NMConfigVar( "Fit", "KeidingGuessAuto", KeidingGuessAuto, "auto compute initial guesses for Keiding function", "boolean" )
	//NMConfigVar( "Fit", "KeidingConstraints", KeidingConstraints, "set parameter constraints for Keiding function", "boolean" )
	
	NMConfigStr( "Fit", "GHK_Xunits", GHK_Xunits, "x-scale units for GHK fit fxn", "V;mV;" )
	
End // NMFitConfigs

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitVarGet( varName )
	String varName
	
	Variable defaultVal = Nan
	
	strswitch( varName )
	
		case "UseSubfolders":
			defaultVal = UserSubfolders
			break
			
		case "Coefficients":
			defaultVal = 0
			break
			
		case "XOffset":
			defaultVal = NaN
			break
			
		case "SinPointsPerCycle":
			defaultVal = 0
			break
			
		case "Xbgn":
			defaultVal = -inf
			break
			
		case "Xend":
			defaultVal = inf
			break
			
		case "Cursors":
			defaultVal = 0
			break
			
		case "FitAuto":
			defaultVal = FitAuto
			break
			
		case "AutoTable":
			defaultVal = AutoTable
			break
			
		case "AutoGraph":
			defaultVal = AutoGraph
			break
			
		case "SaveFitWaves":
			defaultVal = SaveFitWaves
			break
			
		case "FullGraphWidth":
			defaultVal = FullGraphWidth
			break
			
		case "Residuals":
			defaultVal = Residuals
			break
			
		case "PrintResults":
			defaultVal = PrintResults
			break
			
		case "Weighting":
			defaultVal = Weighting
			break
			
		case "MultiThreads":
			defaultVal = MultiThreads
			break
			
		case "FitMethod":
			defaultVal = FitMethod
			break
			
		case "MaxIterations":
			defaultVal = MaxIterations
			break
			
		case "Tolerance":
			defaultVal = Tolerance
			break
			
		case "FitAllWavesPause":
			defaultVal = 0
			break
			
		case "ClearWavesSelect":
			defaultVal = 1
			break
			
		case "SynExpSign":
			defaultVal = SynExpSign // ( -1 ) negative events ( 1 ) positive events
			break
			
		case "KeidingGuessAuto":
			defaultVal = KeidingGuessAuto
			break
			
		//case "KeidingConstraints":
			//defaultVal = KeidingConstraints
			//break
			
		case "V_FitQuitReason":
			defaultVal = 0
			break
			
		case "V_chisq":
			defaultVal = Nan
			break
			
		case "V_npnts":
			defaultVal = Nan
			break
			
		case "V_numNaNs":
			defaultVal = Nan
			break
			
		case "V_numINFs":
			defaultVal = Nan
			break
			
		case "V_startRow":
			defaultVal = Nan
			break
			
		case "V_endRow":
			defaultVal = Nan
			break
			
		default:
			NMDoAlert( "NMFitVar Error: no variable called " + NMQuotes( varName ) )
			return Nan
	
	endswitch
	
	return NumVarOrDefault( NMFitDF+varName, defaultVal )
	
End // NMFitVarGet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitStrGet( strVarName )
	String strVarName
	
	String defaultStr = ""
	
	strswitch( strVarName )
	
		case "Equation":
			defaultStr = ""
			break
			
		case "Function":
			defaultStr = ""
			break
			
		case "WeightingWavePrefix":
			defaultStr = "Stdv_"
			break
			
		case "FxnShort":
			defaultStr = StrVarOrDefault( NMFitDF+"Function", "" )
			break
			
		case "FxnList":
			defaultStr = IgorFitFxnList
			break
			
		case "UserFxnList":
			defaultStr = ""
			break
			
		case "S_Info":
			defaultStr = ""
			break
			
		case "S_FitNumPnts":
			defaultStr= "auto"
			break
			
		case "S_XOffset":
			defaultStr= "auto"
			break
			
		case "S_UserInput":
			defaultStr= ""
			break
		
		case "GHK_Xunits":
			defaultStr = GHK_Xunits
			break
	
		default:
			NMDoAlert( "NMFitStr Error: no variable called " + NMQuotes( strVarName ) )
			return ""
	
	endswitch
	
	return StrVarOrDefault( NMFitDF+strVarName, defaultStr )
	
End // NMFitStrGet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitWavePath( wName )
	String wName
	
	return NMFitDF + "FT_" + wName
	
End // NMFitWavePath

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitNumParams()

	return NMFitFxnListNumParams( "" )

End // NMFitNumParams

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Fit Function Lists
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitFxnListAll()

	Variable icnt
	String item, fname, userList = ""

	String flist = NMFitStrGet( "FxnList" )
	String user = NMFitFxnList + NMFitStrGet( "UserFxnList" )

	if ( ItemsInList( flist ) == 0 )
		flist = IgorFitFxnList
	endif
	
	for ( icnt = 0 ; icnt < ItemsInList( user ) ; icnt += 1 )
	
		item = StringFromList( icnt, user )
		fname = StringByKey( "f", item, ":", "," )
		
		if ( exists( fname ) == 6 )
			userList = AddListItem( item, userList, ";", inf )
		endif
	
	endfor

	return flist + userList

End // NMFitFxnListAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitFxnListShort()
	
	return NMFitFxnListByKey( NMFitFxnListAll(), "f" )

End // NMFitFxnListShort

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitFxnListByKey( fList, key )
	String fList
	String key
	
	Variable icnt
	String istr, kList = ""
	
	for ( icnt = 0 ; icnt < ItemsInList( fList ) ; icnt += 1 )
		istr = StringFromList( icnt, fList, ";" )
		istr = StringByKey( key, istr, ":", "," )
		kList = AddListItem( istr, kList, ";", inf )
	endfor

	return kList

End // NMFitFxnListByKey

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFxnListNumParams( fxn )
	String fxn
	
	if ( strlen( fxn ) == 0 )
		fxn = NMFitStrGet( "Function" )
	endif
	
	Variable item = WhichListItem( fxn, NMFitFxnListShort(), ";", 0, 0 )
	
	if ( item < 0 )
		return 0
	endif
	
	String f = StringFromList( item, NMFitFxnListAll(), ";" )
	
	f = StringByKey( "n", f, ":", "," )
	
	return str2num( f )

End // NMFitFxnListNumParams

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFxnListNumParamsSet( fxn, numParams )
	String fxn
	Variable numParams
	
	Variable oldNum = NMFitFxnListNumParams( fxn )
	
	if ( numParams == oldNum )
		return 0
	endif
	
	String fList = NMFitStrGet( "FxnList" )
	
	String fold = "f:" + fxn + ",n:" + num2istr( oldNum )
	String fnew = "f:" + fxn + ",n:" + num2istr( numParams )
	
	fList = ReplaceString( fold, fList, fnew )
	
	SetNMstr( NMFitDF + "FxnList", fList )
	
End // NMFitFxnListNumParamsSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitIgorListShort()
	
	return NMFitFxnListByKey( IgorFitFxnList, "f" )

End // NMFitIgorListShort

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitFuncListShort()
	
	return NMFitFxnListByKey( NMFitFxnList, "f" )

End // NMFitFuncListShort

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitUserFxnListShort()
	
	return NMFitFxnListByKey( NMFitStrGet( "UserFxnList" ), "f" )

End // NMFitUserFxnListShort

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Tab Panel Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitMake() // create controls that will begin with appropriate prefix

	Variable x0 = 40, y0 = 205, xinc, yinc = 25, fs = NMPanelFsize
	
	y0 = NMPanelTabY + 55
	
	CheckNMFitVar( "Coefficients" )
	CheckNMFitVar( "Xbgn" )
	CheckNMFitVar( "Xend" )
	CheckNMFitVar( "V_FitQuitReason" )
	
	CheckNMFitStr( "Equation" )
	CheckNMFitStr( "S_FitNumPnts" )
	CheckNMFitStr( "S_UserInput" )

	ControlInfo /W=$NMPanelName FT_FxnGroup // check first in a list of controls
	
	if ( V_Flag != 0 )
		return 0 // tab controls exist, return here
	endif

	DoWindow /F $NMPanelName
	
	GroupBox FT_FxnGroup, title = "Function", pos={x0-20,y0-23}, size={260,85}, win=$NMPanelName, fsize=fs
	
	PopupMenu FT_FxnMenu, pos={x0+225,y0+0*yinc}, size={0,0}, bodyWidth=230, fsize=14, proc=NMFitFxnPopup, win=$NMPanelName
	PopupMenu FT_FxnMenu, value=NMFitPopupList(), win=$NMPanelName, fsize=fs
	
	SetVariable FT_UserInput, title="", pos={x0+5,y0+1*yinc+10}, size={100,50}, limits={0,inf,0}, frame=1, win=$NMPanelName
	SetVariable FT_UserInput, value=$( NMFitDF+"S_UserInput" ), proc=SetNMFitUserValue, win=$NMPanelName, fsize=fs
	
	Checkbox FT_SynExpSign, title="positive peaks", pos={x0+5,y0+1*yinc+10}, size={200,50}, value=1, proc=NMFitCheckBox, win=$NMPanelName, fsize=fs
	
	SetVariable FT_Coefficients, title="coefficients:", pos={x0+120,y0+1*yinc+10}, size={100,50}, limits={0,inf,0}, frame=1, win=$NMPanelName
	SetVariable FT_Coefficients, value=$( NMFitDF+"Coefficients" ), proc=SetNMFitUserValue, win=$NMPanelName, fsize=fs, format="%.0f"
	
	y0 += 95
	
	GroupBox FT_RangeGroup, title = "Data Options", pos={x0-20,y0-23}, size={260,75}, win=$NMPanelName, fsize=fs
	
	SetVariable FT_Xbgn, title="xbgn", pos={x0-5,y0+0*yinc+2}, size={80,50}, limits={-inf,inf,0}, win=$NMPanelName
	SetVariable FT_Xbgn, value=$( NMFitDF+"Xbgn" ), proc=SetNMFitVariable, win=$NMPanelName, fsize=fs, format="%.3f"
	
	SetVariable FT_Xend, title="xend", pos={x0+85,y0+0*yinc+2}, size={80,50}, limits={-inf,inf,0}, win=$NMPanelName
	SetVariable FT_Xend, value=$( NMFitDF+"Xend" ), proc=SetNMFitVariable, win=$NMPanelName, fsize=fs, format="%.3f"
	
	Button FT_ClearRange, pos={x0+175,y0+0*yinc}, title="Clear", size={50,20}, proc=NMFitButton, win=$NMPanelName, fsize=fs
	
	Checkbox FT_Cursors, title="cursors", pos={x0+40,y0+1*yinc+2}, size={200,50}, value=NMFitVarGet( "Cursors" ), proc=NMFitCheckBox, win=$NMPanelName, fsize=fs
	Checkbox FT_Weighting, title="weighting", pos={x0+125,y0+1*yinc+2}, size={200,50}, value=NMFitVarGet( "Weighting" ), proc=NMFitCheckBox, win=$NMPanelName, fsize=fs
	
	y0 += 85
	
	GroupBox FT_FitWaveGroup, title = "Output Options", pos={x0-20,y0-23}, size={260,77}, win=$NMPanelName, fsize=fs
	
	Checkbox FT_FullGraphWidth, title="full graph width", pos={x0-5,y0+0*yinc}, size={200,50}, value=NMFitVarGet( "SaveFitWaves" ), proc=NMFitCheckBox, win=$NMPanelName, fsize=fs
	Checkbox FT_SaveFits, title="save", pos={x0-5,y0+1*yinc+2}, size={200,50}, value=NMFitVarGet( "SaveFitWaves" ), proc=NMFitCheckBox, win=$NMPanelName, fsize=fs
	Checkbox FT_Residuals, title="residuals", pos={x0+60,y0+1*yinc+2}, size={200,50}, value=NMFitVarGet( "Residuals" ), proc=NMFitCheckBox, win=$NMPanelName, fsize=fs
	
	SetVariable FT_FitNumPnts, title="points", pos={x0+130,y0+0*yinc}, size={95,50}, limits={0,inf,0}, win=$NMPanelName
	SetVariable FT_FitNumPnts, value=$( NMFitDF+"S_FitNumPnts" ), proc=SetNMFitVariable, win=$NMPanelName, fsize=fs, format="%.0f"
	
	Button FT_Compute, pos={x0+145,y0+1*yinc}, title="Graph Now", size={80,20}, proc=NMFitButton, win=$NMPanelName, fsize=fs
	
	y0 += 87
	
	GroupBox FT_FitExecuteGroup, title = "Execute", pos={x0-20,y0-23}, size={260,130}, win=$NMPanelName, fsize=fs
	
	Button FT_Fit, pos={x0-5,y0+0*yinc}, title="Fit", size={70,20}, proc=NMFitButton, win=$NMPanelName, fsize=fs
	Button FT_Save, pos={x0+75,y0+0*yinc}, title="Save", size={70,20}, proc=NMFitButton, win=$NMPanelName, fsize=fs
	Button FT_Clear, pos={x0+155,y0+0*yinc}, title="Clear", size={70,20}, proc=NMFitButton, win=$NMPanelName, fsize=fs
	Button FT_FitAll, pos={x0-5+40,y0+1*yinc}, title="Fit All", size={70,20}, proc=NMFitButton, win=$NMPanelName, fsize=fs
	//Button FT_PlotAll, pos={x0+75,y0+1*yinc}, title="Plot All", size={70,20}, proc=NMFitButton, win=$NMPanelName, fsize=fs
	Button FT_Table, pos={x0+155-40,y0+1*yinc}, title="Table", size={70,20}, proc=NMFitButton, win=$NMPanelName, fsize=fs
	
	y0 += 30
	
	Checkbox FT_FitAuto, title="auto fit", pos={x0+25,y0+1*yinc}, size={100,50}, value=NMFitVarGet( "FitAuto" ), proc=NMFitCheckBox, win=$NMPanelName, fsize=fs
	
	Checkbox FT_Print, title="print results", pos={x0+120,y0+1*yinc}, size={100,50}, value=NMFitVarGet( "PrintResults" ), proc=NMFitCheckBox, win=$NMPanelName, fsize=fs
	
	SetVariable FT_Error, title="error #", pos={x0+70,y0+2*yinc}, size={80,50}, limits={5,500,0}, win=$NMPanelName
	SetVariable FT_Error, value=$( NMFitDF+"V_FitQuitReason" ), win=$NMPanelName, fsize=fs, noedit=1

End // NMFitMake

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitUpdate()

	Variable igorFxn
	String ttl, userInput = ""
	
	if ( NMVarGet( "ConfigsDisplay" ) > 0 )
		return 0
	endif

	String fxn = NMFitStrGet( "Function" )
	String eq = NMFitStrGet( "Equation" )
	String flist = NMFitPopupList()
	
	Variable fmode = WhichListItem( fxn, flist, ";", 0, 0 )
	
	if ( ( strlen( fxn ) > 0 ) && ( WhichListItem( fxn, NMFitIgorListShort(), ";", 0, 0 ) >= 0 ) )
		igorFxn = 1
	endif
	
	ttl = "Function"
	
	if ( strlen( eq ) > 0 )
		ttl = "F=" + eq
	endif
	
	//GroupBox FT_FxnGroup, win=$NMPanelName, title=ttl
	
	if ( fmode < 0 )
		fmode = 0
	endif
	
	fmode += 1
	
	PopupMenu FT_FxnMenu, win=$NMPanelName, mode=( fmode ), value =NMFitPopupList()
	
	strswitch( fxn )
	
		case "Poly":
			SetVariable FT_UserInput, title="", disable=1, win=$NMPanelName
			Checkbox FT_SynExpSign, title = "", disable=1, win=$NMPanelName
			SetVariable FT_Coefficients, frame=1, noedit=0, pos={100, 260}, win=$NMPanelName
			break
		
		case "Poly_XOffset":
			SetVariable FT_UserInput, title="offset:", disable=0, win=$NMPanelName
			Checkbox FT_SynExpSign, title = "", disable=1, win=$NMPanelName
			SetVariable FT_Coefficients, frame=1, noedit=0, pos={160, 260}, win=$NMPanelName
			userInput = NMFitStrGet( "S_XOffset" )
			break
			
		case "Exp_XOffset":
		case "DblExp_XOffset":
			SetVariable FT_UserInput, title="offset:", disable=0, win=$NMPanelName
			Checkbox FT_SynExpSign, title = "", disable=1, win=$NMPanelName
			SetVariable FT_Coefficients, frame=0, noedit=1, pos={160, 260}, win=$NMPanelName
			userInput = NMFitStrGet( "S_XOffset" )
			break
			
		case "Sin":
			SetVariable FT_UserInput, title="pnts/cycle:", disable=0, win=$NMPanelName
			Checkbox FT_SynExpSign, title = "", disable=1, win=$NMPanelName
			SetVariable FT_Coefficients, frame=0, noedit=1, pos={160, 260}, win=$NMPanelName
			userInput = num2str( NMFitVarGet( "SinPointsPerCycle" ) )
			break
			
		case "NMSynExp3":
		case "NMSynExp4":
			SetVariable FT_UserInput, title="", disable=1, win=$NMPanelName
			SetVariable FT_Coefficients, frame=0, noedit=1, pos={160, 260}, win=$NMPanelName
			
			if ( NMFitVarGet( "SynExpSign" ) == 1 )
				Checkbox FT_SynExpSign, title = "positive peak", disable=0, value=1, win=$NMPanelName
			else
				Checkbox FT_SynExpSign, title = "negative peak", disable=0, value=1, win=$NMPanelName
			endif
			
			break
	
		default:
			SetVariable FT_UserInput, title="", disable=1, win=$NMPanelName
			Checkbox FT_SynExpSign, title = "", disable=1, win=$NMPanelName
			SetVariable FT_Coefficients, frame=0, noedit=1, pos={100, 260}, win=$NMPanelName
			
	endswitch
	
	if ( ( strlen( fxn ) > 0 ) && !igorFxn )
		//SetVariable FT_UserInput, title="", disable=1, win=$NMPanelName
		//SetVariable FT_Coefficients, frame=0, noedit=1, pos={100, 260}, win=$NMPanelName
	endif
	
	SetNMstr( NMFitDF + "S_UserInput", userInput )
	
	Checkbox FT_Cursors, value=NMFitVarGet( "Cursors" ), win=$NMPanelName
	Checkbox FT_Weighting, value=NMFitVarGet( "Weighting" ), win=$NMPanelName
	
	Checkbox FT_FullGraphWidth, value=NMFitVarGet( "FullGraphWidth" ), win=$NMPanelName
	Checkbox FT_SaveFits, value=NMFitVarGet( "SaveFitWaves" ), win=$NMPanelName
	Checkbox FT_Residuals, value=NMFitVarGet( "Residuals" ), win=$NMPanelName
	
	Checkbox FT_FitAuto, value=NMFitVarGet( "FitAuto" ), win=$NMPanelName
	Checkbox FT_Print, value=NMFitVarGet( "PrintResults" ), win=$NMPanelName
	
	NMFitCursorsSetTimes()
	
End // NMFitUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitPopupList()
	
	return " ;" + NMFitFxnListShort() + "---;Other;Remove from List;Print Equation;"
	
End // NMFitPopupList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	String callFxn = ReplaceString( "FT_", ctrlName, "" )
		
	NMFitCall( callFxn, popStr )
			
End // NMFitPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFxnPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	strswitch( popStr )
		case "---":
			NMFitUpdate()
			break
		default:
			NMFitFxnCall( popStr )
	endswitch
			
End // NMFitFxnPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitButton( ctrlName ) : ButtonControl
	String ctrlName
	
	String callFxn = ReplaceString( "FT_", ctrlName, "" )
	
	NMFitCall( callFxn, "" )
	
End // NMFitButton

//****************************************************************
//****************************************************************
//****************************************************************

Function SetNMFitVariable( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	String callFxn = ReplaceString( "FT_", ctrlName, "" )
	
	NMFitCall( callFxn, varStr )
	
End // SetNMFitVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function SetNMFitUserValue( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	String callFxn = ReplaceString( "FT_", ctrlName, "" )
	
	NMFitFxnUserValueCall( callFxn, varStr )
	
End // SetNMFitUserValue

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitCheckBox( ctrlName, checked ) : CheckBoxControl
	String ctrlName; Variable checked
	
	String callFxn = ReplaceString( "FT_", ctrlName, "" )
	
	NMFitCall( callFxn, num2istr( checked ) )
	
End // NMFitCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFxnCall( select )
	String select
	
	strswitch( select )
		case "Add to List":
		case "Other":
			if ( NMFitUserFxnAddCall() != 0 )
				NMFitUpdate()
			endif
			break
		case "Remove from List":
			if ( NMFitFxnListRemoveCall() != 0 )
				NMFitUpdate()
			endif
			break
		case "Print Equation":
			NMFitFunctionPrint()
			break
		default:
			NMFitSet( fxn = select, history = 1 )
	endswitch
	
	return 0

End // NMFitFxnCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFxnUserValueCall( select, valueStr )
	String select // select function
	String valueStr
	
	Variable value = str2num( valueStr )
	
	String fxn = NMFitStrGet( "Function" )
	
	strswitch( select )
	
		case "Coefficients":
			NMFitSet( fxn = fxn, numTerms = value, history = 1 )
			break
			
		case "UserInput":
		
			strswitch( fxn )
			
				case "Poly_XOffset":
				case "Exp_XOffset":
				case "DblExp_XOffset":
					NMFitSet( xoffset = value, history = 1 )
					break
					
				case "Sin":
					NMFitSet( pntsPerCycle = value, history = 1 )
					break
					
			endswitch
			
			break
	
	endswitch
			
End // NMFitFxnUserValueCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitCall( fxn, select )
	String fxn // function name
	String select // parameter string variable
	
	Variable snum = str2num( select ) // parameter variable number
	
	strswitch( fxn )
	
		case "SynExpSign": // toggle
		
			if ( NMFitVarGet( "SynExpSign" ) == 1 )
				snum = -1
			else
				snum = 1
			endif
			
			NMFitSet( synExpSign = snum, history = 1 )
			
			break
			
		case "Xbgn":
			NMFitSet( xbgn = snum, history = 1 )
			break
			
		case "Xend":
			NMFitSet( xend = snum, history = 1 )
			break
			
		case "ClearRange":
			NMFitSet( xbgn = -inf, xend = inf, history = 1 )
			break
			
		case "Cursors":
			NMFitSet( cursors = snum, history = 1 )
			break
			
		case "Weight":
		case "Weighting":
			NMFitSet( weighting = snum, history = 1 )
			break
			
		case "FullGraphWidth":
			NMFitSet( fitFullWidth = snum, history = 1 )
			break
			
		case "SaveFits":
			NMFitSet( fitSave = snum, history = 1 )
			break
			
		case "Residuals":
			NMFitSet( fitResiduals = snum, history = 1 )
			break
			
		case "FitNumPnts":
			NMFitSet( fitPoints = snum, history = 1 )
			break
			
		case "FitAuto":
			NMFitSet( autoFit = snum, history = 1 )
			break
			
		case "Print":
			NMFitSet( printResults = snum, history = 1 )
			break
			
		case "Compute":
			NMFitWaveComputeCall()
			break
			
		case "Fit":
			NMFitWave( history = 1 )
			break
			
		case "FitAll":
			z_FitAllCall()
			break
		
		case "Save":
			NMFitSaveCurrentCall()
			break
		
		case "Clear":
		case "ClearAll":
			NMFitClearCall()
			break
			
		case "Plot":
			NMFitPlotAllCall( 0 )
			break
			
		case "PlotAll":
			//NMFitPlotAllCall( 1 )
			break
			
		case "Table":
			NMFitSubfolderTableCall()
			break
			
		default:
			NMDoAlert( "NMFitCall: unrecognized function call: " + fxn )

	endswitch
	
End // NMFitCall

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Set Global Values Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitSet( [ fxn, numTerms, xoffset, pntsPerCycle, synExpSign, xbgn, xend, cursors, weighting, fitFullWidth, fitSave, fitPoints, fitResiduals, autoFit, printResults, update, alerts, history ] )
	
	String fxn // fit function name
	Variable numTerms // number of fit terms ( e.g. for Poly ) - must also specify fxn
	Variable xoffset // x-axis offset ( e.g. for Poly_XOffset )
	Variable pntsPerCycle // for sin fit
	Variable synExpSign // ( -1 ) negative sign ( 1 ) positive sign ( SynExp functions )
	
	Variable xbgn, xend
	Variable cursors // fit between cursors ( 0 ) no ( 1 ) yes
	Variable weighting // stdv weighting ( 0 ) no ( 1 ) yes
	
	Variable fitFullWidth // make fit wave the full-width of graph ( 0 ) no ( 1 ) yes
	Variable fitSave // save fit wave // ( 0 ) no ( 1 ) yes
	Variable fitPoints // number of points of fit wave
	Variable fitResiduals // ( 0 ) no ( 1 ) yes
	
	Variable autoFit // automatically fit data waves ( 0 ) no ( 1 ) yes
	Variable printResults // ( 0 ) no ( 1 ) yes
	
	Variable update // allow updates to NM panels and graphs
	Variable alerts // general alerts ( 0 ) none ( 1 ) yes
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable updateTab, auto
	String vlist = ""
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( ParamIsDefault( alerts ) )
		alerts = 1
	endif

	if ( !ParamIsDefault( fxn ) )
	
		vlist = NMCmdStrOptional( "fxn", fxn, vlist )
	
		if ( !ParamIsDefault( numTerms ) )
		
			vlist = NMCmdNumOptional( "numTerms", numTerms, vlist, integer = 1 )
		
			if ( strsearch( fxn, "Poly", 0 ) == 0 )
				NMFitPolyNumSet( fxn, numTerms, update = update )
			else
				NMFitFxnListNumParamsSet( fxn, numTerms )
				NMFitWaveTable( 0 )
			endif
			
		else
		
			NMFitFunctionSet( fxn )
			
		endif
		
		auto = 1
	
	endif
	
	if ( !ParamIsDefault( xoffset ) )
	
		vlist = NMCmdNumOptional( "xoffset", xoffset, vlist )
		
		SetNMstr( NMFitDF + "S_XOffset", z_CheckOffset( xoffset ) )
		
		auto = 1
		
	endif
	
	if ( !ParamIsDefault( pntsPerCycle ) )
	
		vlist = NMCmdNumOptional( "pntsPerCycle", pntsPerCycle, vlist, integer = 1 )
		
		SetNMvar( NMFitDF + "SinPointsPerCycle", z_CheckSinPointsPerCycle( pntsPerCycle ) )
		
		auto = 1
		
	endif
	
	if ( !ParamIsDefault( synExpSign ) )
	
		vlist = NMCmdNumOptional( "synExpSign", synExpSign, vlist, integer = 1 )
		
		SetNMvar( NMFitDF + "SynExpSign", z_CheckSynExpSign( synExpSign ) )
		
		auto = 1
		
	endif
		
	if ( !ParamIsDefault( xbgn ) )
	
		vlist = NMCmdNumOptional( "xbgn", xbgn, vlist )
		
		SetNMvar( NMFitDF + "Xbgn", z_CheckXbgn( xbgn ) )
		
		if ( update )
			NMDragUpdate( "DragBgn" )
		endif
		
		auto = 1
		
	endif
	
	if ( !ParamIsDefault( xend ) )
	
		vlist = NMCmdNumOptional( "xend", xend, vlist )
		
		SetNMvar( NMFitDF + "Xend", z_CheckXend( xend ) )
		
		if ( update )
			NMDragUpdate( "DragEnd" )
		endif
		
		auto = 1
		
	endif
	
	if ( !ParamIsDefault( cursors ) )
	
		vlist = NMCmdNumOptional( "cursors", cursors, vlist, integer = 1 )
		
		NMFitCursorsSet( cursors )
		
		auto = 1
		
	endif
	
	if ( !ParamIsDefault( weighting ) )
		
		weighting = BinaryCheck( weighting )
		vlist = NMCmdNumOptional( "weighting", weighting, vlist, integer = 1 )
		NMConfigVarSet( "Fit", "Weighting", weighting )
		
		if ( weighting && alerts )
			z_WeightingAlert()
		endif
		
		auto = 1
		
	endif
	
	if ( !ParamIsDefault( fitFullWidth ) )
		fitFullWidth = BinaryCheck( fitFullWidth )
		vlist = NMCmdNumOptional( "fitFullWidth", fitFullWidth, vlist, integer = 1 )
		NMConfigVarSet( "Fit", "FullGraphWidth", fitFullWidth )
	endif
	
	if ( !ParamIsDefault( fitSave ) )
		fitSave = BinaryCheck( fitSave )
		vlist = NMCmdNumOptional( "fitSave", fitSave, vlist, integer = 1 )
		NMConfigVarSet( "Fit", "SaveFitWaves", fitSave )
	endif
	
	if ( !ParamIsDefault( fitPoints ) )
		vlist = NMCmdNumOptional( "fitPoints", fitPoints, vlist, integer = 1 )
		SetNMstr( NMFitDF + "S_FitNumPnts", z_CheckNumPnts( fitPoints ) )
	endif
	
	if ( !ParamIsDefault( fitResiduals ) )
		fitResiduals = BinaryCheck( fitResiduals )
		vlist = NMCmdNumOptional( "fitResiduals", fitResiduals, vlist, integer = 1 )
		NMConfigVarSet( "Fit", "Residuals", fitResiduals )
	endif
	
	if ( !ParamIsDefault( autoFit ) )
		autoFit = BinaryCheck( autoFit )
		vlist = NMCmdNumOptional( "autoFit", autoFit, vlist, integer = 1 )
		NMConfigVarSet( "Fit", "FitAuto", autoFit )
	endif
	
	if ( !ParamIsDefault( printResults ) )
		printResults = BinaryCheck( printResults )
		vlist = NMCmdNumOptional( "printResults", printResults, vlist, integer = 1 )
		NMConfigVarSet( "Fit", "PrintResults", printResults )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( update && updateTab )
		NMFitUpdate()
	endif
	
	if ( update && auto )
		NMFitAuto()
	endif
	
End // NMFitSet

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S z_CheckNumPnts( npnts )
	Variable npnts
	
	if ( ( numtype( npnts ) > 0 ) || ( npnts <= 1 ) )
		return "auto"
	else
		return num2istr( npnts )
	endif
	
End // z_CheckNumPnts

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S z_CheckOffset( offset )
	Variable offset
	
	if ( numtype( offset ) > 0 )
		return "auto"
	else
		return num2str( offset )
	endif
	
End // z_CheckOffset

//****************************************************************
//****************************************************************
//****************************************************************

Static Function z_CheckSinPointsPerCycle( points )
	Variable points
	
	if ( ( numtype( points ) == 0 ) && ( points > 0 ) )
		return points
	else
		return 0
	endif
		
End // z_CheckSinPointsPerCycle

//****************************************************************
//****************************************************************
//****************************************************************

Static Function z_CheckSynExpSign( expSign )
	Variable expSign
	
	if ( expSign == 1 )
		return 1
	else
		return -1
	endif
	
End // z_CheckSynExpSign

//****************************************************************
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
//****************************************************************

Static Function z_WeightingAlert()

	String prefix = NMFitStr( "WeightingWavePrefix" )

	String alert = "Note: weighting waves must have the same name as your data waves, but with " + NMQuotes( prefix ) + " as the prefix ( e.g. " + prefix + "AvgRAll_A0 )."

	NMDoAlert( alert )
	
End // z_WeightingAlert

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitUserFxnAddCall()

	String fxn = "", cmdstr = ""
	Variable numParams = 2
	
	Prompt fxn, "function name:"
	Prompt numParams, "number of fitting parameters:"
	DoPrompt "Add Function", fxn, numParams
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	return NMFitUserFxnAdd( fxn, numParams, history = 1 )

End // NMFitUserFxnAddCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitUserFxnAdd( fxn, numParams [ update, history ] )
	String fxn
	Variable numParams
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable item
	String userList, fList, vlist = ""
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( history )
		vlist = NMCmdStr( fxn, vlist )
		vlist = NMCmdNum( numParams, vlist, integer = 1 )
		NMCommandHistory( vlist )
	endif
	
	if ( strlen( fxn ) == 0 )
		return NM2Error( 21, "fxn", fxn )
	endif
	
	item = WhichListItem( fxn, NMFitFxnListShort(), ";", 0, 0 )
	
	if ( item >= 0 )
		return -1 // name already exists
	endif
	
	if ( ( numtype( numParams ) > 0 ) || ( numParams < 1 ) )
		return NM2Error( 10, "numParams", num2istr( numParams ) )
	endif
	
	userList = NMFitStrGet( "UserFxnList" )
	
	fList = AddListItem( "f:" + fxn + ",n:" + num2istr( numParams ), userList, ";", inf )
	
	SetNMstr( NMFitDF + "UserFxnList", fList )
	
	NMFitFunctionSet( fxn )
	
	if ( update )
		NMFitUpdate()
	endif
	
	return 0
	
End // NMFitUserFxnAdd

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFxnListRemoveCall()

	String fxn = ""
	String fxnList = NMFitUserFxnListShort()
	
	if ( ItemsInList( fxnList ) == 0 )
		DoAlert 0, "There are no user-defined fit functions to remove."
		return -1
	endif
	
	Prompt fxn, "remove:", popup fxnList
	DoPrompt "Remove Function", fxn
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	return NMFitFxnListRemove( fxn, history = 1 )
	
End // NMFitFxnListRemoveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFxnListRemove( fxn [ update, history ] )
	String fxn
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	String vlist = ""
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( history )
		vlist = NMCmdStr( fxn, vlist )
		NMCommandHistory( vlist )
	endif
	
	String fxnList = NMFitStrGet( "UserFxnList" )
	String fxnListShort = NMFitUserFxnListShort()
	
	Variable item = WhichListItem( fxn, fxnListShort, ";", 0, 0 )
	
	if ( item < 0 )
		return -1
	endif
	
	fxnList = RemoveListItem( item, fxnList, ";" )
	
	SetNMstr( NMFitDF + "UserFxnList", fxnList )
	
	if ( update )
		NMFitUpdate()
	endif
	
	return 0
	
End // NMFitFxnListRemove

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitPolyNumSet( fxn, numParams [ update ] )
	String fxn
	Variable numParams
	Variable update

	Variable icnt
	String pList = ""
	
	strswitch( fxn )
		case "Poly":
		case "Poly_XOffset":
			break
		default:
			return NaN
	endswitch
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( ( numtype( numParams ) > 0 ) || ( numParams < 3 ) )
		numParams = 3
	endif
	
	NMFitFxnListNumParamsSet( fxn, numParams )
	
	SetNMvar( NMFitDF + "Coefficients", numParams )
	SetNMstr( NMFitDF + "Function", fxn )
	SetNMstr( NMFitDF + "FxnShort", "Poly" )
	SetNMstr( NMFitDF + "Equation", "K0+K1*x+K2*x^2..." )
	
	NMFitWaveTable( 1 )
	NMFitCoefNamesSet( pList )
	
	if ( update )
		NMFitUpdate()
	endif
	
	return numParams

End // NMFitPolyNumSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFunctionSet( fxn [ update ] )
	String fxn
	Variable update
	
	Variable numParams
	String sfxn = fxn, pList = "", eq = ""
	
	String fList = NMFitFxnListShort()
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	NMFitWaveTableSave()
	
	if ( StringMatch( fxn, " " ) )
		SetNMvar( NMFitDF + "Coefficients", 0 )
		SetNMstr( NMFitDF + "Function", "" )
		SetNMstr( NMFitDF + "FxnShort", "" )
		SetNMstr( NMFitDF + "Equation", "" )
	endif
	
	if ( WhichListItem( fxn, fList ) < 0 )
		NMFitUpdate()
		return 0
	endif
	
	strswitch( fxn )
		case " ":
			sfxn = ""
			eq = ""
			break
		case "Line":
			pList = "A;B;"
			eq = "A+Bx"
			break
		case "Poly":
			return NMFitPolyNumSet( fxn, 3 )
		case "Poly_XOffset":
			return NMFitPolyNumSet( fxn, 3 )
		case "Gauss":
			pList = "Y0;A;X0;W;"
			eq = "Y0+A·exp(-((x-X0)/W)^2)"
			break
		case "Lor":
			pList = "Y0;A;X0;B;"
			eq = "Y0+A/((x-X0)^2+B)"
			break
		case "Exp":
			pList = "Y0;A;InvT;"
			eq = "Y0+A·exp(-InvT·x)"
			break
		case "Exp_XOffset":
			sfxn = "Exp"
			pList = "Y0;A;T;"
			eq = "Y0+A·exp(-(x-X0)/T)"
			break
		case "DblExp":
			sfxn = "2Exp"
			pList = "Y0;A1;InvT1;A2;InvT2;"
			eq = "Y0+A1·exp(-InvT1·x)+A2·exp(-InvT2·x)"
			break
		case "DblExp_XOffset":
			sfxn = "2Exp"
			pList = "Y0;A1;T1;A2;T2;"
			eq = "Y0+A1·exp(-(x-X0)/T1)+A2·exp(-(x-X0)/T2)"
			break
		case "Sin":
			pList = "Y0;A;F;P;"
			eq = "Y0+A·sin(F·x+P)"
			break
		case "HillEquation":
			sfxn = "Hill"
			pList = "B;M;R;XH;"
			eq = "B+(M-B)·(x^R/(1+(x^R+XH^R)))"
			break
		case "Sigmoid":
			sfxn = "Sig"
			pList = "B;M;XH;R;"
			eq = "B+M/(1+exp(-(x-XH)/R))"
			break
		case "Power":
			sfxn = "Pow"
			pList = "Y0;A;P;"
			eq = "Y0+A·x^P"
			break
		case "LogNormal":
			sfxn = "Log"
			pList = "Y0;A;X0;W;"
			eq = "Y0+A·exp(-(ln(x/X0)/W)^2)"
			break
		case "NMExp3":
			sfxn = "3Exp"
			pList = "X0;Y0;A1;T1;A2;T2;A3;T3;"
			eq = "Y0+A1·exp(-(x-X0)/T1)+A2·exp(-(x-X0)/T2)+A3·exp(-(x-X0)/T3)"
			break
		case "NMAlpha":
			sfxn = "Alpha"
			pList = "X0;Y0;A;T;"
			eq = "Y0+A·exp(-(x-X0)/T)·(x-X0)/T"
			break
		case "NMGamma":
			sfxn = "Gamma"
			pList = "X0;Sigma;Gamma;"
			eq = "Gamma(x0,sigma,gamma)"
			break
		case "NMGauss":
			sfxn = "Gauss"
			pList = "X0;STDVx;"
			eq = "Gauss(x,X0,STDVx)"
			break
		case "NMGauss1":
			sfxn = "Gauss1"
			pList = "A0;A;X0;STDVx;"
			eq = "A0+A·Gauss(x,X0,STDVx)"
			break
		case "NMGauss2":
			sfxn = "Gauss2"
			pList = "Y0;A;X0;STDVx;Y0;STDVy;"
			eq = "Y0+A·Gauss(x,X0,STDVx,y,Y0,STDVy)"
			break
		case "NMGauss3":
			sfxn = "Gauss3"
			pList = "Y0;A;X0;STDVx;Y0;STDVy;Z0;STDVz;"
			eq = "Y0+A·Gauss(x,X0,STDVx,y,Y0,STDVy,z,Z0,STDVz)"
			break
		case "NMSynExp3":
			sfxn = "Syn3"
			pList = "X0;TR1;N;A1;TD1;A2;TD2;"
			eq = "(1-exp(-(x-X0)/TR1))^N·(A1·exp(-(x-X0)/TD1)+A2·exp(-(x-X0)/TD2))"
			break
		case "NMSynExp4":
			sfxn = "Syn4"
			pList = "X0;TR1;N;A1;TD1;A2;TD2;A3;TD3;"
			eq = "(1-exp(-(x-X0)/TR1))^N·(A1·exp(-(x-X0)/TD1)+A2·exp(-(x-X0)/TD2))+A3·exp(-(x-X0)/TD3))"
			break
		case "NM_IV":
			sfxn = "IV"
			pList = "G;Vrev;"
			eq = "G·(x-Vrev)"
			break
		case "NM_IV_Boltzmann":
			sfxn = "IVBoltz"
			pList = "G;Vrev;Vhalf;Vslope;N;"
			eq = "G·(x-Vrev)·Boltzmann(x)^N"
			break
		case "NM_IV_GHK":
			sfxn = "IVGHK"
			pList = "G;Vrev;Temp;z;"
			eq = "G·GHK(x)"
			break
		case "NM_IV_GHK_Boltzmann":
			sfxn = "IVGHKBoltz"
			pList = "G;Vrev;Temp;z;Vhalf;Vslope;N;"
			eq = "G·GHK(x)·Boltzmann(x)^N)"
			break
		case "NM_MPFA1":
			sfxn = "MPFAb"
			pList = "Q;N;CV1;CV2;"
			eq = "(Q·x-x^2/N)·(1+CV2^2)+Q·x·CV1^2"
			break
		case "NM_MPFA2":
			sfxn = "MPFAm"
			pList = "Q;N;alpha;CV1;CV2;"
			eq = "(Q·x-x^2·Q·(1+alpha)/(x+Q·N·alpha))·(1+CV2^2)+Q·x·CV1^2"
			break
		case "NM_RCvstep":
			sfxn = "RCstep"
			pList = "Vstep;X0;I0;Rp;Rm;Cm;"
			eq = "I0+Iss+Iexp·exp(-(x-X0)/TD)"
			break
		case "NMKeidingGauss":
			sfxn = "KeidingGauss"
			pList = "X0;STDVx;Phi;T;N;PhiCutoff;"
			eq = "KeidingGauss(x0,stdv,Phi,T,N,PhiCutoff)"
			break
		case "NMKeidingChi":
			sfxn = "KeidingChi"
			pList = "F;Beta;Phi;T;"
			eq = "KeidingChi(f,beta,Phi,T)"
			break
		case "NMKeidingGamma":
			sfxn = "KeidingGamma"
			pList = "X0;F;Beta;Phi;T;"
			eq = "KeidingGamma(x0,f,beta,Phi,T)"
			break
		case "NMCircle":
			sfxn = "Circle"
			pList = "X0;DX;R;"
			eq = "sqrt(R^2-(x·DX-X0)^2)"
			break
		case "NMEllipse":
			sfxn = "Ellipse"
			pList = "X0;DX;R;E;"
			eq = "sqrt(R^2-((x·DX-X0)/E)^2)"
			break
		default:
			sfxn = fxn
			eq = ""
	endswitch
	
	numParams = NMFitFxnListNumParams( fxn )
	
	SetNMvar( NMFitDF + "Coefficients", numParams )
	SetNMstr( NMFitDF + "Function", fxn )
	SetNMstr( NMFitDF + "FxnShort", sfxn )
	SetNMstr( NMFitDF + "Equation", eq )
	
	NMHistory( fxn + ": " + eq )
	
	NMFitWaveTable( 1 )
	NMFitCoefNamesSet( pList )
	NMFitGuess()
	//NMFitX0Set()
	
	if ( update )
		NMFitUpdate()
	endif
	
	return 0
	
End // NMFitFunctionSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitFunctionPrint()
	
	Variable coefficients = NMFitVarGet( "Coefficients" )
	String fxn = NMFitStrGet( "Function" )
	String eq = NMFitStrGet( "Equation" )

	NMHistory( fxn + "(k=" + num2istr( coefficients ) + "): " + eq )
	
End // NMFitFunctionPrint

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitCursorsSet( on )
	Variable on
	
	Variable currentChan = CurrentNMChannel()
	
	String gName = ChanGraphName( currentChan )
	
	on = BinaryCheck( on )
	
	SetNMvar( NMFitDF + "Cursors", on )
	
	if ( on )
	
		if ( WinType( gName ) == 1 )
			ShowInfo /W=$gName
		endif
		
		SetNMvar( NMFitDF + "XbgnOld", NumVarOrDefault( NMFitDF+"Xbgn", Nan ) )
		SetNMvar( NMFitDF + "XendOld", NumVarOrDefault( NMFitDF+"Xend", Nan ) )
		
		NMFitCursorsSetTimes()
		
	else
	
		SetNMvar( NMFitDF + "Xbgn", NumVarOrDefault( NMFitDF+"XbgnOld", Nan ) )
		SetNMvar( NMFitDF + "Xend", NumVarOrDefault( NMFitDF+"XendOld", Nan ) )
		
	endif
	
	return on

End // NMFitCursorsSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitCursorsSetTimes()

	Variable xbgn = NaN, xend = NaN
	String gName

	if ( !NMFitVarGet( "Cursors" ) )
		return 0
	endif
	
	gName = ChanGraphName( CurrentNMChannel() )
	
	if ( WinType( gName ) == 0 )
		return 0
	endif

	if ( strlen( CsrInfo( A, gName ) ) > 0 )
		xbgn = xcsr( A, gName )
	endif
	
	if ( strlen( CsrInfo( B, gName ) ) > 0 )
		xend = xcsr( B, gName )
	endif
	
	if ( numtype( xbgn * xend ) == 0 )
		xbgn = min( xbgn, xend )
		xend = max( xbgn, xend )
	endif
	
	if ( numtype( xbgn ) == 0 )
		SetNMvar( NMFitDF+"Xbgn", xbgn )
		NMDragUpdate( "DragBgn" )
	endif
	
	if ( numtype( xend ) == 0 )
		SetNMvar( NMFitDF+"Xend", xend )
		NMDragUpdate( "DragEnd" )
	endif
	
	return 0
	
End // NMFitCursorsSetTimes

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Curve Fit Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitAuto( [ update ] )
	Variable update

	Variable fitError
	String gName, fitWaveName, gfitWaveName
	
	Variable currentWave = CurrentNMWave()

	if ( strlen( CurrentNMPrefixFolder() ) == 0 )
		return 0
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	gName = ChanGraphName( CurrentNMChannel() )
	fitWaveName = NMFitWaveName( currentWave )
	gfitWaveName = "GFit_" + NMChanWaveName( CurrentNMChannel(), currentWave )
	
	NMFitDisplayClear()
	
	if ( NMFitVarGet( "FitAuto" ) )
		fitError = NMFitWave()
	elseif ( WinType( gName ) == 1 )
		if ( WaveExists( $fitWaveName ) )
			AppendToGraph /W=$gName $fitWaveName
			NMFitSaveRetrieve( currentWave )
		elseif ( WaveExists( $gfitWaveName ) )
			//AppendToGraph /W=$gName $gfitWaveName
		endif
	endif
	
	if ( update )
		NMDragUpdate( "DragBgn" )
		NMDragUpdate( "DragEnd" )
	endif

End // NMFitAuto

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S z_FitAllCall()

	Variable p, startFrom = 0
	String returnStr, chanSelectList, waveSelectList, title = "Fit All Waves"
	
	Variable currentWaveNum = CurrentNMWave()
	Variable numWaves = NMNumWaves()
	
	Variable start = NumVarOrDefault( NMFitDF + "FitAllWavesStart", 1 )
	Variable pauseMode = NumVarOrDefault( NMFitDF + "FitAllWavesPause", NMFitVarGet( "FitAllWavesPause" ) )
	Variable pauseValue = 0
	
	if ( NMExecutionAlert() )
		return ""
	endif
	
	if ( pauseMode > 0 )
		p = 2
		pauseValue = pauseMode
	elseif ( pauseMode < 0 )
		p = 3
		pauseValue = 0
	else
		p = 1
		pauseValue = 0
	endif
	
	Prompt start, "starting from wave number:", popup "0;" + num2istr( currentWaveNum ) + ";"
	Prompt p, "pause after each fit?", popup "no;yes;yes, with OK prompt;"
	Prompt pauseValue, "pause time ( sec ):"
	
	if ( currentWaveNum > 0 )
		DoPrompt title, start, p
	else
		DoPrompt "Fit All Waves", p
	endif
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMvar( NMFitDF + "FitAllWavesStart", start )
	
	if ( start == 2 )
		startFrom = currentWaveNum
	endif
	
	if ( p == 2 )
	
		Prompt pauseValue, "pause time ( sec ):"
	
		DoPrompt "Fit All Waves", pauseValue
	
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
	endif
	
	switch( p )
		case 1:
			pauseMode = 0
			break
		case 2:
			pauseMode = abs( pauseValue )
			break
		case 3:
			pauseMode = -1
			break
	endswitch
	
	SetNMvar( NMFitDF + "FitAllWavesPause", pauseMode )
	
	chanSelectList = NMChanSelectAllList()
	
	if ( ItemsInList ( chanSelectList ) == 0 )
		chanSelectList = CurrentNMChanChar()
	endif
	
	waveSelectList = NMWaveSelectAllList()
	
	if ( ItemsInList( waveSelectList ) == 0 )
		waveSelectList = NMWaveSelectGet()
	endif

	if ( startFrom > 0 )
		returnStr = NMFitAll( chanSelectList = chanSelectList, waveSelectList = waveSelectList, startWaveNum = startFrom, pause = pauseMode, history = 1 )
	else
		returnStr = NMFitAll( chanSelectList = chanSelectList, waveSelectList = waveSelectList, pause = pauseMode, history = 1 )
	endif
	
	if ( NMFitVarGet( "SaveFitWaves" ) && NMFitVarGet( "AutoGraph" ) && NMVarGet( "GraphsAndTablesOn" ) )
		NMFitPlotAll( 1 )
	endif
	
	return returnStr

End // z_FitAllCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitAll( [ chanSelectList, waveSelectList, startWaveNum, pause, history ] )
	String chanSelectList // channel select list ( e.g. "A;B;" )
	String waveSelectList // wave select list ( e.g. "Set1;Set2;" )
	Variable startWaveNum // start from wave number (in waveSelectList)
	Variable pause // ( 0 ) no pause ( > 0 ) pause for given sec ( < 0 ) pause with OK prompt
	Variable history // print function command to history ( 0 ) no ( 1 ) yes

	Variable icnt, ccnt, wcnt, wcnt2, chanNum, changeChan, fitError
	Variable numChannels, numWaves, currentChan, currentWave
	Variable chanSelectListItems, waveSelectListItems
	
	String wName, tableName, tableList = "", vlist = ""
	String chanSelectStr, subFolderName, progressStr
	String folderList = "", folderSelect = ""
	String thisFxn = GetRTStackInfo( 1 )
	
	if ( NMPrefixFolderAlert() )
		return ""
	endif
	
	Variable useSubfolders = NMFitVarGet( "UseSubfolders" )
	Variable drag = NMVarGet( "DragOn" )
	
	Variable saveCurrentWave = CurrentNMWave()
	
	String prefixFolder = CurrentNMPrefixFolder()
	String wavePrefix = CurrentNMWavePrefix()
	String saveChanSelectStr = NMChanSelectStr()
	String waveSelect = NMWaveSelectGet()
	String saveWaveSelect = waveSelect
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = NMChanSelectAllList()
	else
		vlist = NMCmdStrOptional( "chanSelectList", chanSelectList, vlist )
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = NMWaveSelectAllList()
	else
		vlist = NMCmdStrOptional( "waveSelectList", waveSelectList, vlist )
	endif
	
	if ( ParamIsDefault( startWaveNum ) )
		startWaveNum = 0
	else
		vlist = NMCmdNumOptional( "startWaveNum", startWaveNum, vlist )
	endif
	
	if ( ParamIsDefault( pause ) )
		pause = 0
	else
		vlist = NMCmdNumOptional( "pause", pause, vlist )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( numtype( pause ) > 0 )
		pause = 0
	endif
	
	chanSelectListItems = ItemsInList( chanSelectList )
	waveSelectListItems = ItemsInList( waveSelectList )
	
	for ( icnt = 0 ; icnt < max( waveSelectListItems, 1 ) ; icnt += 1 ) // loop thru sets
		
		if ( waveSelectListItems > 0 )
		
			waveSelect = StringFromList( icnt, waveSelectList )
			
			if ( !StringMatch( waveSelect, NMWaveSelectGet() ) )
				NMWaveSelect( waveSelect )
			endif
			
		endif
		
		if ( NMNumActiveWaves() <= 0 )
			continue
		endif
		
		for ( ccnt = 0; ccnt < max( chanSelectListItems, 1 ) ; ccnt += 1 ) // loop thru channels
		
			if ( chanSelectListItems > 0 )
			
				chanSelectStr = StringFromList( ccnt, chanSelectList )
				
				if ( !StringMatch( chanSelectStr, CurrentNMChanChar() ) )
					NMChanSelect( chanSelectStr )
					DoUpdate
				endif
				
			endif
			
			chanNum = CurrentNMChannel()
			
			if ( useSubfolders )
				subFolderName = NMSubfolderName( NMFitSubfolderPrefix(), wavePrefix, chanNum, NMWaveSelectShort() )
			else
				subFolderName = ""
			endif
			
			CheckNMSubfolder( subFolderName )
			folderList = AddListItem( NMChild( subFolderName ), folderList, ";", inf )
			
			if ( strlen( folderSelect ) == 0 )
				folderSelect = subFolderName
			endif
			
			SetNMvar( prefixFolder + "CurrentChan", chanNum )
			
			numChannels = NMNumChannels()
			numWaves = NMNumWaves()
			currentWave = CurrentNMWave()
			currentChan = CurrentNMChannel()
			
			tableName = NMFitTable( 1, hide = 1 )
			
			if ( WinType( tableName ) == 2 )
				tableList = AddListItem( tableName, tableList, ";", inf )
			endif
			
			DoWindow /F $ChanGraphName( currentChan )
			
			if ( drag )
				NMChannelGraphSet( drag = 0 )
				NMDragClear( "DragBgn" )
				NMDragClear( "DragEnd" )
			endif
			
			progressStr = "Fit Chan " + ChanNum2Char( currentChan )
			
			NMProgress( 0, numWaves, progressStr ) // if startWaveNum > 0
			
			for ( wcnt = startWaveNum ; wcnt < numWaves ; wcnt += 1 ) // loop thru waves
		
				if ( ( pause >= 0 ) && ( NMProgress( wcnt, numWaves, progressStr ) == 1 ) )
					break
				endif
				
				wName = NMWaveSelected( currentChan, wcnt )
				
				if ( strlen( wName ) == 0 )
					continue // wave not selected, or does not exist... go to next wave
				endif
				
				NMCurrentWaveSet( wcnt, update = 0 )
				
				NMChanGraphUpdate( channel = currentChan, waveNum = wcnt )
				
				fitError = NMFitWave()
				
				if ( numtype( fitError ) == 2 )
					break // fatal error
				endif
				
				DoUpdate
				
				if ( pause < 0 )
					
					DoAlert 2, thisFxn + " Alert: do you want to save results?"
					
					if ( V_flag == 1 )
						NMFitSaveCurrent( fitError = fitError )
					elseif ( V_flag == 3 )
						break // cancel
					endif
					
					continue
					
				else
				
					NMFitSaveCurrent( fitError = fitError )
					
				endif
				
				if ( pause > 0 )
					NMwaitMSTimer( pause * 1000 )
				endif
					
				//NMFitSaveCurrent()
				
				if ( NMProgressCancel() == 1 )
					break
				endif
				
			endfor // waves
			
			if ( drag )
				NMChannelGraphSet( drag = 1 )
				NMDragUpdate( "DragBgn" )
				NMDragUpdate( "DragEnd" )
			endif
			
			NMHistoryOutputWaves( subfolder = subFolderName )
			
		endfor // channels
		
	endfor // sets
	
	if ( chanSelectListItems > 0 )
		NMChanSelect( saveChanSelectStr )
	endif
	
	if ( waveSelectListItems > 0 )
		NMWaveSelect( saveWaveSelect )
	endif
	
	NMCurrentWaveSet( saveCurrentWave )
	
	for ( icnt = 0 ; icnt < ItemsInList( tableList ) ; icnt += 1 )
		tableName = StringFromList( icnt, tableList )
		DoWindow /F $tableName
	endfor
	
	return tableList

End // NMFitAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitWaveDF() // directory where curve fitting is performed
	
	//return CurrentNMFolder( 1 )

	return NMDF // where display waves are

End // NMFitWaveDF

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitWave( [ history ] )
	Variable history // print function command to history ( 0 ) no ( 1 ) yes

	Variable pbgn, pend, icnt, changeFolder, fitPoints
	String wsigma, guessName, weightingPrefix, fitWaveName, wnote
	
	if ( history )
		NMCommandHistory( "" )
	endif

	String IgorFitFxn = "CurveFit", cmd = "", sp = " "
	String B_cycle = "", G_guess = "", H_hold = "", K_const = "", L_fitpnts = ""
	String N_noUpdates = "/N", NTHR_thread = "", ODR_method = "", Q_quiet = "", X_fullgraph = ""
	String coef = "", range = ""
	String D_dest = "/D", R_resid = "", X_xwave = "", I_weight = "", W_weightwave = "", C_constraints = ""
	
	if ( NMExecutionAlert() )
		return NaN
	endif
	
	Variable currentChan = CurrentNMChannel()
	Variable currentWave = CurrentNMWave()
	
	String currentWaveName = CurrentNMWaveName()
	String wName = ChanDisplayWave( currentChan )
	String rName = NMDF + "Res_" + ChanDisplayWaveName( 0, currentChan, 0 )
	String gName = ChanGraphName( currentChan )
	String sourceWave = NMChanWaveName( currentChan, currentWave )
	
	Variable numParams = NMFitNumParams()
	Variable pointsPerCycle = NMFitVarGet( "SinPointsPerCycle" )
	Variable weight = NMFitVarGet( "Weighting" )
	Variable xbgn = NMFitVarGet( "Xbgn" )
	Variable xend = NMFitVarGet( "Xend" )
	Variable fullGraphWidth = NMFitVarGet( "FullGraphWidth" )
	Variable residuals = NMFitVarGet( "Residuals" )
	Variable maxIter = NMFitVarGet( "MaxIterations" )
	Variable tolerance = NMFitVarGet( "Tolerance" )
	Variable thread = NMFitVarGet( "MultiThreads" )
	Variable method = NMFitVarGet( "FitMethod" )
	Variable printResults = NMFitVarGet( "PrintResults" )
	
	String fxn = NMFitStrGet( "Function" )
	String offsetStr = NMFitStrGet( "S_XOffset" )
	String fitPointsStr = NMFitStrGet( "S_FitNumPnts" )
	String xWave = NMXwave( waveNum = currentWave )
	
	String saveDF = CurrentNMFolder( 1 )
	String df = NMFitWaveDF()
	
	NMFitWaveTable( 0 )
	NMFitCursorsSetTimes()
	NMFitRemoveDisplayWaves()
	
	if ( strlen( fxn ) == 0 )
		//return NM2Error( 21, "fxn", fxn )
		return NaN
	endif
	
	if ( ( numtype( numParams ) > 0 ) || ( numParams <= 0 ) )
		//return NM2Error( 10, "numParams", num2istr( numParams ) )
		return NaN
	endif
	
	if ( !WaveExists( $wName ) )
		//return NM2Error( 1, "wName", wName )
		return NaN
	endif
	
	if ( strlen( currentWaveName ) == 0 )
		//return NM2Error( 21, "currentWaveName", currentWaveName )
		return NaN
	endif
	
	if ( !StringMatch( df, saveDF ) )
		changeFolder = 1
	endif
	
	if ( strlen( xWave ) > 0 )
	
		if ( !WaveExists( $xWave ) )
			NM2Error( 1, "xWave", xWave )
			return NaN
		endif
		
		if ( ( numpnts( $xWave ) != numpnts( $wName ) ) )
			NM2Error( 5, "xWave", xWave )
			return NaN
		endif
		
		X_xwave = "/X=" + saveDF + xWave
		
	endif
	
	DoWindow /F $gName
	
	if ( ( numtype( xbgn ) == 0 ) || ( numtype( xend ) == 0 ) )
	
		if ( strlen( xWave ) == 0 )
		
			range = "(" + num2str( xbgn ) + "," + num2str( xend ) + ")"
			
		elseif ( WaveExists( $xWave ) )
		
			Wave xtemp = $xWave
			
			pbgn = 0
			pend = numpnts( xtemp ) - 1
			
			if ( numtype( xbgn ) == 0 )
			
				for ( icnt = 0 ; icnt < numpnts( xtemp ) ; icnt += 1 )
					if ( xtemp[ icnt ] >= xbgn )
						pbgn = icnt
						break
					endif
				endfor
			
			endif
			
			if ( numtype( xend ) == 0 )
			
				for ( icnt = numpnts( xtemp ) - 1 ; icnt > 0 ; icnt -= 1 )
					if ( xtemp[ icnt ] <= xend )
						pend = icnt
						break
					endif
				endfor
				
			endif
			
			range = "[" + num2istr( pbgn ) + "," + num2istr( pend ) + "]"
			
			X_xwave += range
		
		endif
		
	endif
	
	if ( NMFitVarGet( "Cursors" ) )
	
		if ( ( strlen( CsrInfo( A, gName ) ) == 0 ) && ( strlen( CsrInfo( B, gName ) ) == 0 ) )
			NM2Error( 90, "cannot locate Cursor information on current graph", "" )
			return NaN
		endif
		
		pbgn = pcsr( A )
		pend = pcsr( B )
		
		if ( pbgn < 0 )
			pbgn = 0
		endif
	
		if ( pend >= numpnts( $wName ) )
			pend = numpnts( $wName ) - 1
		endif
		
		range = "[" + num2istr( pbgn ) + "," + num2istr( pend ) + "]"
		
	endif
	
	wsigma = df + "W_sigma"
	
	if ( WaveExists( $wsigma ) )
		Wave wtemp = $wsigma
		wtemp = Nan
	endif
	
	guessName = NMFitWavePath( "guess" )
	
	if ( !WaveExists( $guessName ) )
		NM2Error( 1, "guessName", guessName )
		return NaN
	endif
	
	Wave FT_guess = $guessName
	Wave FT_coef = $NMFitWavePath( "coef" )
	Wave FT_sigma = $NMFitWavePath( "sigma" )
	Wave FT_hold = $NMFitWavePath( "hold" )
	
	SetNMVar( NMFitDF + "Cancel", 0 )
	
	strswitch( fxn )
		case "NMKeidingGauss":
			if ( exists("NMKeidingGaussInit") == 6 )
				Execute /Q/Z "NMKeidingGaussInit()"
			endif
			break
		case "NMKeidingChi":
			if ( exists("NMKeidingChiInit") == 6 )
				Execute /Q/Z "NMKeidingChiInit()"
			endif
			break
		case "NMKeidingGamma":
			if ( exists("NMKeidingGammaInit") == 6 )
				Execute /Q/Z "NMKeidingGammaInit()"
			endif
			break
		default:
			break
	endswitch
	
	If ( NumVarOrDefault( NMFitDF + "Cancel", 0 ) == 1 )
		NMHistory( "NM Fit Cancel" )
		return NaN
	endif
	
	FT_sigma = Nan
	
	if ( WhichListItem( fxn, NMFitIgorListShort() ) < 0 )
	
		IgorFitFxn = "FuncFit"
		
		if ( NumType( sum( FT_guess ) ) > 0 )
			NM2Error( 90, "you must provide initial guesses for user-defined equations", "" )
			return NaN
		endif
		
	endif
	
	if ( StringMatch( fxn, "Sin" ) && ( pointsPerCycle > 0 ) )
		B_cycle = "/B=" + num2str( pointsPerCycle )
	endif
	
	for ( icnt = 0 ; icnt < numParams ; icnt += 1 )
	
		if ( ( icnt >= numpnts( FT_hold ) ) || ( icnt >= numpnts( FT_guess ) ) )
			break
		endif
	
		if ( FT_hold[ icnt ] == 1 )
		
			if ( numtype( FT_guess[ icnt ] ) > 0 )
				NM2Error( 90, "to hold parameters you must specify a hold value in wave FT_guess", "" )
				return NaN
			endif
			
			H_hold = "/H=\""
			
		endif
		
	endfor
	
	if ( strlen( H_hold ) > 0 )
	
		for ( icnt = 0 ; icnt < numParams ; icnt += 1 )
		
			if ( ( icnt >= numpnts( FT_hold ) ) || ( icnt >= numpnts( FT_guess ) ) || ( icnt >= numpnts( FT_coef ) ) )
				break
			endif
			
			if ( FT_hold[ icnt ] == 1 )
				FT_coef[ icnt ] = FT_guess[ icnt ]
				Variable /G $( "K" + num2istr( icnt ) ) = FT_guess[ icnt ]
				H_hold += "1"
			else
				H_hold += "0"
			endif
			
		endfor
		
		H_hold += "\""
	
	endif
	
	for ( icnt = 0 ; icnt < numParams ; icnt += 1 )
	
		if ( ( icnt >= numpnts( FT_hold ) ) || ( icnt >= numpnts( FT_guess ) ) || ( icnt >= numpnts( FT_coef ) ) )
			break
		endif
	
		if ( numtype( FT_guess[ icnt ] ) == 0 )
		
			FT_coef[ icnt ] = FT_guess[ icnt ]
			
			if ( FT_hold[ icnt ] != 1 )
				G_guess = "/G"
			endif
			
		else
		
			FT_coef[ icnt ] = Nan
			
			if ( strlen( G_guess ) > 0 )
				FT_coef = NaN
				NM2Error( 90, "to set initial guess values you must specify all parameters in wave FT_guess", "" )
				return NaN
			endif
			
		endif
		
	endfor
	
	strswitch( fxn )
		
		case "Poly_XOffset":
		case "Exp_XOffset":
		case "DblExp_XOffset":
			if ( numtype( str2num( offsetStr ) ) == 0 ) 
				K_const = "/K={" + offsetStr + "}"
			endif
			break
			
	endswitch
	
	if ( !StringMatch( fitPointsStr, "auto" ) )
	
		fitPoints = str2num( fitPointsStr )
		
		if ( ( numtype( fitPoints ) == 0 ) && ( fitPoints > 1 ) )
			L_fitpnts = "/L=" + num2istr( fitPoints )
		endif
	
	endif
	
	if ( thread )
		NTHR_thread = "/NTHR=0"
	else
		NTHR_thread = "/NTHR=1"
	endif
	
	switch( method )
		case 1:
		case 2:
		case 3:
			ODR_method = "/ODR=" + num2str( method )
			break
		default:
			ODR_method = "/ODR=0"
	endswitch
	
	if ( !printResults )
		Q_quiet = "/Q"
	endif
	
	if ( fullGraphWidth )
		X_fullgraph = "/X=1"
	endif
	
	strswitch( fxn )
	
		case "Poly":
		case "Poly_XOffset":
			fxn += " " + num2istr( numParams ) + ","
			break
			
		case "NMKeidingGauss":
		case "NMKeidingChi":
		case "NMKeidingGamma":
			SetNMvar( NMFitDF + "NMKeidingXmax", rightx( $currentWaveName ) )
			break
	
	endswitch
	
	coef = "kwCWave=" + NMFitWavePath( "coef" )
	
	C_constraints = z_Constraints()
	
	if ( weight )
	
		weightingPrefix = NMFitStr( "WeightingWavePrefix" )
		
		if ( WaveExists( $( weightingPrefix + sourceWave ) ) )
		
			if ( StringMatch( weightingPrefix[ 0, 2 ], "Inv" ) )
				I_weight = "/I=0" // reciprocal or inverse
			else
				I_weight = "/I=1"
			endif
			
			W_weightwave = "/W=" + saveDF + weightingPrefix + sourceWave
			
		elseif ( WaveExists( $( weightingPrefix ) ) )
		
			W_weightwave = "/W=" + saveDF + weightingPrefix
			
			if ( StringMatch( weightingPrefix[ 0, 2 ], "Inv" ) )
				I_weight = "/I=0" // reciprocal or inverse
			else
				I_weight = "/I=1"
			endif
			
		else
		
			NM2Error( 90, "cannot locate weighting wave: " + weightingPrefix + sourceWave, "" )
			return NaN
			
		endif
		
	endif
	
	if ( residuals )
	
		R_resid = "/R "
		
		if ( WaveExists( $rName ) )
			Wave rtemp = $rName
			rtemp = NaN // null wave because Igor does not update this wave
		endif
		
	endif
	
	if ( ( maxIter != 40 ) || ( exists( "V_FitMaxIters" ) == 2 ) )
		Variable /G V_FitMaxIters = maxIter
	endif
	
	if ( ( tolerance != 0.001 ) || ( exists( "V_FitTol" ) == 2 ) )
		Variable /G V_FitTol = tolerance
	endif
	
	cmd = IgorFitFxn + B_cycle + G_guess + H_hold + K_const + L_fitpnts + N_noUpdates + NTHR_thread + ODR_method + Q_quiet + X_fullgraph + sp
	cmd += fxn + ", " + coef + ", " + wName + range + sp
	cmd += C_constraints + D_dest + I_weight + R_resid + W_weightwave + X_xwave
	
	if ( changeFolder )
		SetDataFolder $df
	endif
	
	//Variable /G V_FitError = Nan
	Variable /G V_FitOptions = 4 // suppress fit display
	Variable /G V_chisq = NaN
	Variable /G V_npnts = NaN
	Variable /G V_numNaNs = NaN
	Variable /G V_numINFs = NaN
	Variable /G V_startRow = NaN
	Variable /G V_endRow = NaN
	Variable /G V_FitQuitReason = 0
	String /G S_Info = ""
	
	if ( printResults )
		NMHistory( cmd )
	endif
	
	Execute /Z cmd
	
	if ( printCurveFitCommand )
		NMHistory( cmd )
	endif
	
	if ( changeFolder )
		SetDataFolder $saveDF
	endif
	
	if ( strlen( S_Info ) == 0 )
		if ( V_FitQuitReason == 0 )
			V_FitQuitReason = 9
			FT_coef = NaN
		endif
	endif
	
	SetNMvar( NMFitDF + "V_chisq", V_chisq )
	SetNMvar( NMFitDF + "V_npnts", V_npnts )
	SetNMvar( NMFitDF + "V_numNaNs", V_numNaNs )
	SetNMvar( NMFitDF + "V_numINFs", V_numINFs )
	SetNMvar( NMFitDF + "V_startRow", V_startRow )
	SetNMvar( NMFitDF + "V_endRow", V_endRow )
	SetNMvar( NMFitDF + "V_FitQuitReason", V_FitQuitReason )
	SetNMstr( NMFitDF + "S_Info", S_Info )
	
	SetNMvar( "V_FitQuitReason", V_FitQuitReason )
	SetNMstr( "S_Info", S_Info )
	
	// V_FitQuitReason:
	// 0 if the fit terminated normally
	// 1 if the iteration limit was reached
	// 2 if the user stopped the fit
	// 3 if the limit of passes without decreasing chi-square was reached.
	
	fitWaveName = StringByKey( "AUTODESTWAVE", S_Info, "=" )
	
	if ( WaveExists( $NMDF + fitWaveName ) ) // fix wave note
	
		Wave wtemp = $NMDF + fitWaveName
		
		wnote = note( wtemp )
		wnote = ReplaceString(  NMChild( wName ), wnote, currentWaveName )
		
		Note /K wtemp
		Note wtemp, wnote
		
	endif
		
	if ( WaveExists( $wsigma ) && ( numpnts( $wsigma ) == numpnts( FT_sigma ) ) )
	
		Wave wtemp = $wsigma
		
		FT_sigma = wtemp
		
		if ( numtype( sum( $wsigma ) ) > 0 )
			FT_coef = NaN
		endif
		
	endif
	
	if ( StringMatch( fxn, "NMKeidingGauss" ) )
		Execute /Z "NMKeidingGaussPhiCutoffEstimate(" + NMQuotes( NMFitWavePath( "coef" ) ) + ")"
	endif
	
	return V_FitQuitReason

End // NMFitWave

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S z_Constraints()

	Variable icnt, jcnt, found
	
	String wName = NMFitWavePath( "constraints" )
	
	Variable numParams = NMFitNumParams()

	Wave FT_low = $NMFitWavePath( "low" )
	Wave FT_high = $NMFitWavePath( "high" )
	
	for ( icnt = 0 ; icnt < numParams ; icnt += 1 )
	
		if ( ( icnt >= numpnts( FT_low ) ) || ( icnt >= numpnts( FT_high ) ) )
			break
		endif
	
		if ( numtype( FT_low[ icnt ] ) == 0 )
			found += 1
		endif
		
		if ( numtype( FT_high[ icnt ] ) == 0 )
			found += 1
		endif
		
	endfor

	Make /T/O/N=( found ) $wName = ""
	
	if ( found == 0 )
		return ""
	endif
	
	Wave /T wtemp = $wName
	
	for ( icnt = 0 ; icnt < numParams ; icnt += 1 )
	
		if ( jcnt >= numpnts( wtemp ) )
			break
		endif
	
		if ( ( icnt >= numpnts( FT_low ) ) || ( icnt >= numpnts( FT_high ) ) )
			break
		endif
	
		if ( numtype( FT_low[ icnt ] ) == 0 )
			wtemp[ jcnt ] = "K" + num2str( icnt ) + " > " + num2str( FT_low[ icnt ] )
			jcnt += 1
		endif
		
		if ( numtype( FT_high[ icnt ] ) == 0 )
			wtemp[ jcnt ] = "K" + num2str( icnt ) + " < " + num2str( FT_high[ icnt ] )
			jcnt += 1
		endif
		
	endfor
	
	return "/C=" + wName

End // z_Constraints

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitWaveName( waveNum )
	Variable waveNum // ( -1 ) for current

	return "Fit_" + NMChanWaveName( CurrentNMChannel(), waveNum )
	
End // NMFitWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitResidWaveName( waveNum )
	Variable waveNum // ( -1 ) for current

	return "Res_" + NMChanWaveName( CurrentNMChannel(), waveNum )
	
End // NMFitResidWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitDisplayWaveName()
	
	return NMFitWaveDF() + "Fit_" + ChanDisplayWaveName( 0, CurrentNMChannel(), 0 )

End // NMFitDisplayWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitResidDisplayWaveName()
	
	return NMFitWaveDF() + "Res_" + ChanDisplayWaveName( 0, CurrentNMChannel(), 0 )

End // NMFitResidDisplayWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitWaveComputeCall()

	Variable guessORfit
	String guessName = NMFitWavePath( "guess" )
	
	if ( !WaveExists( $guessName ) )
		return -1
	endif
	
	WaveStats /Q $guessName
	
	if ( V_npnts != numpnts( $guessName ) )
	
		if ( !WaveExists( $NMFitWavePath( "coef" ) ) )
			return -1
		endif
		
		guessORfit = 1
	
	endif

	return NMFitWaveCompute( guessORfit, history = 1 )

End // NMFitWaveComputeCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitWaveCompute( guessORfit [ history ] )
	Variable guessORfit // ( 0 ) guess ( 1 ) fit
	Variable history // print function command to history ( 0 ) no ( 1 ) yes

	Variable icnt, dt, pnt, lastpnt, offset, fitPoints, xbgn2, xend2
	String vlist = ""
	
	if ( history )
		vlist = NMCmdNum( guessORfit, vlist, integer = 1 )
		NMCommandHistory( vlist )
	endif
	
	Variable xbgn = NMFitVarGet( "Xbgn" )
	Variable xend = NMFitVarGet( "Xend" )
	Variable fullGraphWidth = NMFitVarGet( "FullGraphWidth" )
	
	String offsetStr = NMFitStrGet( "S_XOffset" )
	String fitPointsStr = NMFitStrGet( "S_FitNumPnts" )
	
	Variable currentChan = CurrentNMChannel()
	
	String paramWave
	String cmd = ""
	String fxn = NMFitStrGet( "Function" )
	String igorFxns = NMFitIgorListShort()
	String gName = ChanGraphName( currentChan )
	String displayWave = ChanDisplayWave( currentChan )
	String fitWave = NMFitDisplayWaveName()
	
	if ( WhichListItem( fxn, igorFxns ) < 0 ) // user defined function here
		//NMDoAlert( "Sorry, this function does not work for user-defined curve fit functions." )
		//return 0
	endif
	
	NMFitRemoveDisplayWaves()
	
	if ( guessORfit == 1 )
		paramWave = NMFitWavePath( "coef" )
	else
		paramWave = NMFitWavePath( "guess" )
	endif

	if ( !WaveExists( $paramWave ) )
		return NM2Error( 1, "paramWave", paramWave )
	endif
	
	WaveStats /Q/Z $paramWave

	if ( V_numNaNs > 0 )
		return NM2Error( 90, "parameter wave contains NANs", "" )
	endif
	
	fitPoints = str2num( fitPointsStr )
	
	xbgn2 = leftx( $displayWave )
	xend2 = rightx( $displayWave )
	
	if ( numtype( xbgn ) > 0 )
		xbgn = xbgn2
	else
		xbgn = max( xbgn, xbgn2 )
	endif
	
	if ( numtype( xend ) > 0 )
		xend = xend2
	else
		xend = min( xend, xend2 )
	endif
	
	if ( StringMatch( fitPointsStr, "auto" ) || ( numtype( fitPoints ) > 0 ) || ( fitPoints <= 1 ) )
		WaveStats /Q/R=( xbgn, xend ) $displayWave
		fitPoints = V_npnts
	endif
	
	dt = ( xend - xbgn ) / ( fitPoints - 1 )
	
	Wave w = $paramWave
	
	//Duplicate /O $displayWave $fitWave
	Make /O/N=( fitPoints ) $fitWave
	Setscale /P x xbgn, dt, $fitWave
	
	Wave fit = $fitWave
	
	if ( StringMatch( offsetStr, "auto" ) )
		offset = xbgn
	else
		offset = str2num( offsetStr )
	endif
	
	if ( numtype( offset ) > 0 )
		offset = 0
	endif
	
	strswitch( fxn )
		case "Line":
			//pList = "A;B;"
			//eq = "A+Bx"
			if ( numpnts( w ) == 2 )
				fit = w[0] + w[1] * x
			endif
			break
		case "Poly":
			fit = 0
			for ( icnt = 0 ; icnt < numpnts( w ) ; icnt += 1 )
				fit += w[icnt]*x^icnt
			endfor
			break
		case "Poly_XOffset":
			fit = 0
			for ( icnt = 0 ; icnt < numpnts( w ) ; icnt += 1 )
				fit += w[icnt]*(x-offset)^icnt
			endfor
			break
		case "Gauss":
			//pList = "Y0;A;X0;W;"
			//eq = "Y0+A*exp( -( ( x -X0 )/W )^2 )"
			if ( numpnts( w ) == 4 )
				fit = w[0] + w[1]*exp( -( ( x -w[2] )/w[3] )^2 )
			endif
			break
		case "Lor":
			//pList = "Y0;A;X0;B;"
			//eq = "Y0+A/( ( x-X0 )^2+B )"
			if ( numpnts( w ) == 4 )
				fit = w[0]+w[1]/( ( x-w[2] )^2+w[3] )
			endif
			break
		case "Exp":
			//pList = "Y0;A;InvT;"
			//eq = "Y0+A*exp( -InvT*x )"
			if ( numpnts( w ) == 3 )
				fit = w[0]+w[1]*exp( -w[2]*x )
			endif
			break
		case "Exp_XOffset":
			//pList = "Y0;A;T;"
			//eq = "Y0+A*exp( -( x-X0 )/T )"
			if ( numpnts( w ) == 3 )
				fit = w[0]+w[1]*exp( -( x-offset )/w[2] )
			endif
			break
		case "DblExp":
			//pList = "Y0;A1;InvT1;A2;InvT2;"
			//eq = "Y0+A1*exp( -InvT1*x )+A2*exp( -InvT2*x )"
			if ( numpnts( w ) == 5 )
				fit = w[0]+w[1]*exp( -w[2]*x )+w[3]*exp( -w[4]*x )
			endif
			break
		case "DblExp_XOffset":
			//pList = "Y0;A1;T1;A2;T2;"
			//eq = "Y0+A1*exp( -( x-X0 )/T1 )+A2*exp( -( x-X0 )/T2 )"
			if ( numpnts( w ) == 5 )
				fit = w[0]+w[1]*exp( -( x-offset )/w[2] )+w[3]*exp( -( x-offset )/w[4] )
			endif
			break
		case "Sin":
			//pList = "Y0;A;F;P;"
			//eq = "Y0+A*sin( F*x+P )"
			if ( numpnts( w ) == 4 )
				fit = w[0]+w[1]*sin( w[2]*x+w[3] )
			endif
			break
		case "HillEquation":
			//pList = "B;M;R;XH;"
			//eq = "B+( M-B )*( x^R/( 1+( x^R+XH^R ) ) )"
			if ( numpnts( w ) == 4 )
				fit = w[0]+( w[1]-w[0] )*( x^w[2]/( 1+( x^w[2]+w[3]^w[2] ) ) )
			endif
			break
		case "Sigmoid":
			//pList = "B;M;XH;R;"
			//eq = "B+M/( 1+exp( -( x-XH )/R ) )"
			if ( numpnts( w ) == 4 )
				fit = w[0]+w[1]/( 1+exp( -( x-w[2] )/w[3] ) )
			endif
			break
		case "Power":
			//pList = "Y0;A;P;"
			//eq = "Y0+A*x^P"
			if ( numpnts( w ) == 3 )
				fit = w[0]+w[1]*x^w[2]
			endif
			break
		case "LogNormal":
			//pList = "Y0;A;X0;W;"
			//eq = "Y0+A*exp( -( ln( x/X0 )/W )^2 )"
			if ( numpnts( w ) == 4 )
				fit = w[0]+w[1]*exp( -( ln( x/w[2] )/w[3] )^2 )
			endif
			break
		case "NMExp3":
			fit = NMExp3( w, x )
			break
		case "NMAlpha":
			fit = NMAlpha( w, x )
			break
		case "NMGamma":
			fit = NMGamma( w, x )
			break
		case "NMGauss":
			fit = NMGauss( w, x )
			break
		case "NMGauss1":
			fit = NMGauss1( w, x )
			break
		case "NMGauss2":
			//fit = NMGauss2( w, x, y ) // 2D waves not yet
			break
		case "NMGauss3":
			//fit = NMGauss3( w, x, y, z ) // 3D waves not yet
			break
		case "NMSynExp3":
			fit = NMSynExp3( w, x )
			break
		case "NMSynExp4":
			fit = NMSynExp4( w, x )
			break
		case "NM_IV":
			fit = NM_IV( w, x )
			break
		case "NM_IV_Boltzmann":
			fit = NM_IV_Boltzmann( w, x )
			break
		case "NM_IV_GHK":
			fit = NM_IV_GHK( w, x )
			break
		case "NM_IV_GHK_Boltzmann":
			fit = NM_IV_GHK_Boltzmann( w, x )
			break
		case "NM_MPFA1":
			fit = NM_MPFA1( w, x )
			break
		case "NM_MPFA2":
			fit = NM_MPFA2( w, x )
			break
		case "NM_RCvstep":
			fit = NM_RCvstep( w, x )
			break
		case "NMKeidingGauss":
			NMKeidingExecute( fitWave, paramWave, "Gauss" )
			break
		case "NMKeidingChi":
			NMKeidingExecute( fitWave, paramWave, "Chi" )
			break
		case "NMKeidingGamma":
			NMKeidingExecute( fitWave, paramWave, "Gamma" )
			break
		case "NMCircle":
			fit = NMCircle( w, x )
			break
		case "NMEllipse":
			fit = NMEllipse( w, x )
			break
		default:
			return NM2Error( 90, "cannot compute function for " + NMQuotes( fxn ), "" )
	endswitch
	
	AppendToGraph /W=$gName fit
	
	if ( fullGraphWidth && ( guessORfit == 1 ) )
		return 0
	endif
	
	if ( numtype( xbgn ) == 0 )
	
		pnt = x2pnt( fit, xbgn ) - 1
	
		if ( ( pnt > 0 ) && ( pnt < numpnts( fit ) ) )
			fit[ 0, pnt ] = Nan
		endif
		
	endif
	
	if ( numtype( xend ) == 0 )
	
		pnt = x2pnt( fit, xend ) + 1
		lastpnt = numpnts( fit ) - 1
		
		if ( ( pnt >= 0 ) && ( pnt < lastpnt ) )
			fit[ pnt, lastpnt ] = Nan
		endif
	
	endif
	
	return 0

End // NMFitWaveCompute

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Table Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitSubDirectory()

	String fxn = NMFitStrGet( "Function" )
	
	if ( strlen( fxn ) > 0 )
		return NMFitDF + "FT_" + fxn + ":"
	else
		return ""
	endif 

End // NMFitSubDirectory

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitSubDirWavePath( wName )
	String wName
	
	return NMFitSubDirectory() + "FT_" + wName
	
End // NMFitSubDirWavePath

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitWaveTable( new )
	Variable new // ( 0 ) no ( 1 ) yes
	
	Variable numParams = NMFitNumParams()
	String tName = "NM_Fit_Parameters"
	
	STRUCT Rect w
	
	if ( new || !WaveExists( $NMFitWavePath( "cname" ) ) )
	
		if ( WaveExists( $NMFitSubDirWavePath( "cname" ) ) )
			Duplicate /T/O $NMFitSubDirWavePath( "cname" ) $NMFitWavePath( "cname" )
		else
			Make /O/T/N=( numParams ) $NMFitWavePath( "cname" ) = ""
		endif
		
	endif
	
	if ( new || !WaveExists( $NMFitWavePath( "coef" ) ) )
		Make /D/O/N=( numParams ) $NMFitWavePath( "coef" ) = Nan
	endif
	
	if ( new || !WaveExists( $NMFitWavePath( "sigma" ) ) )
		Make /D/O/N=( numParams ) $NMFitWavePath( "sigma" ) = Nan
	endif
	
	if ( new || !WaveExists( $NMFitWavePath( "guess" ) ) )
	
		if ( WaveExists( $NMFitSubDirWavePath( "guess" ) ) )
			Duplicate /O $NMFitSubDirWavePath( "guess" ) $NMFitWavePath( "guess" )
		else
			Make /O/N=( numParams ) $NMFitWavePath( "guess" ) = Nan
		endif
		
	endif
	
	if ( new || !WaveExists( $NMFitWavePath( "hold" ) ) )
	
		if ( WaveExists( $NMFitSubDirWavePath( "guess" ) ) )
			Duplicate /O $NMFitSubDirWavePath( "guess" ) $NMFitWavePath( "hold" )
		else
			Make /O/N=( numParams ) $NMFitWavePath( "hold" ) = Nan
		endif
		
	endif
	
	CheckNMtwave( NMFitWavePath( "cname" ), numParams, "" )
	CheckNMwave( NMFitWavePath( "coef" ), numParams, Nan )
	CheckNMwave( NMFitWavePath( "sigma" ), numParams, Nan )
	CheckNMwave( NMFitWavePath( "guess" ), numParams, Nan )
	CheckNMwave( NMFitWavePath( "hold" ), numParams, Nan )
	CheckNMwave( NMFitWavePath( "low" ), numParams, Nan )
	CheckNMwave( NMFitWavePath( "high" ), numParams, Nan )
	
	Wave /T FT_cname = $NMFitWavePath( "cname" )
	Wave FT_coef = $NMFitWavePath( "coef" )
	Wave FT_sigma = $NMFitWavePath( "sigma" )
	Wave FT_guess = $NMFitWavePath( "guess" )
	Wave FT_hold = $NMFitWavePath( "hold" )
	Wave FT_low = $NMFitWavePath( "low" )
	Wave FT_high = $NMFitWavePath( "high" )
	
	if ( WinType( tName ) == 2 )
		DoWindow /F $tName
		return tName
	endif
	
	if ( NMVarGet( "GraphsAndTablesOn" ) )
	
		NMWinCascadeRect( w, width = 700 )
	
		Edit /K=1/N=$tName/W=(w.left,w.top,w.right,w.bottom) FT_cname, FT_coef, FT_sigma, FT_guess, FT_hold, FT_low, FT_high as "Fit Coefficients"
		
		return tName
	
	else
	
		return ""
	
	endif

End // NMFitWaveTable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitCoefNamesSet( paramList )
	String paramList
	
	Variable icnt, numParams = NMFitNumParams()
	String param
	
	Wave /T FT_cname = $NMFitWavePath( "cname" )

	for ( icnt = 0 ; icnt < numParams ; icnt += 1 )
	
		if ( icnt >= numpnts( FT_cname ) )
			break
		endif
		
		param = StringFromList( icnt, paramList )
		
		if ( strlen( param ) == 0 )
			param = "K" + num2istr( icnt )
		endif
		
		if ( strlen( FT_cname[ icnt ] ) == 0 )
			FT_cname[ icnt ] = param
		endif
		
	endfor
	
	return 0
	
End // NMFitCoefNamesSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitGuess()

	Variable icnt, foundValue = 0
	
	Variable xbgn = NMFitVarGet( "Xbgn" )
	String fxn = NMFitStrGet( "Function" )
	
	Wave FT_guess = $NMFitWavePath( "guess" )
	Wave FT_hold = $NMFitWavePath( "hold" )
	
	Variable minNumParameters = 2 // change this if adding to fxn switch
	
	if ( numpnts( FT_guess ) < minNumParameters )
		return 0 // something is wrong
	endif
	
	for ( icnt = 0 ; icnt < minNumParameters ; icnt += 1 )
		if ( numtype( FT_guess[ icnt ] ) == 0 )
			foundValue += 1
		endif
	endfor
	
	if ( foundValue == minNumParameters )
		return 0 // guesses already exist
	endif
	
	if ( numtype( xbgn ) > 0 )
		xbgn = 0
	endif
	
	strswitch( fxn )
		case "NMExp3":
			if ( numpnts( FT_guess ) == 8 )
				FT_guess[0] = xbgn // X0
				FT_guess[1] = 0 // Y0
				FT_guess[2] = 1 // A1
				FT_guess[3] = 1 // T1
				FT_guess[4] = 1 // A2
				FT_guess[5] = 50 // T2
				FT_guess[6] = 1 // A3
				FT_guess[7] = 500 // T3
			endif
			break
		case "NMAlpha":
			if ( numpnts( FT_guess ) == 4 )
				FT_guess[0] = xbgn // X0
				FT_guess[1] = 0 // Y0
				FT_guess[2] = 1 // A
				FT_guess[3] = 1 // T
			endif
			break
		case "NMGamma":
			if ( numpnts( FT_guess ) == 3 )
				FT_guess[0] = xbgn // X0
				FT_guess[1] = 3 // Sigma
				FT_guess[2] = 1 // Gamma
			endif
			break
		case "NMGauss":
			if ( numpnts( FT_guess ) == 2 )
				FT_guess[0] = 0 // X0
				FT_guess[1] = 1 // STDVx
			endif
			break
		case "NMGauss1":
			if ( numpnts( FT_guess ) == 4 )
				FT_guess[0] = 0 // A0
				FT_guess[1] = 1 // A
				FT_guess[2] = 0 // X0
				FT_guess[3] = 1 // STDVx
			endif
			break
		case "NMSynExp3":
			if ( numpnts( FT_guess ) == 7 )
				FT_guess[0] = xbgn // X0
				FT_guess[1] = 0.1 // TR1
				FT_guess[2] = 11 // N
				FT_guess[3] = 2 // A1
				FT_guess[4] = 0.5 // TD1
				FT_guess[5] = 0.3 // A2
				FT_guess[6] = 3 // TD2
			endif
			break
		case "NMSynExp4":
			if ( numpnts( FT_guess ) == 9 )
				FT_guess[0] = xbgn // X0
				FT_guess[1] = 0.1 // TR1
				FT_guess[2] = 11 // N
				FT_guess[3] = 2 // A1
				FT_guess[4] = 0.5 // TD1
				FT_guess[5] = 0.3 // A2
				FT_guess[6] = 3 // TD2
				FT_guess[7] = 0.1 // A3
				FT_guess[8] = 20 // TD3
			endif
			break
		case "NM_IV":
			if ( numpnts( FT_guess ) == 2 )
				FT_guess[0] = 1 // G
				FT_guess[1] = 0 // Vrev
			endif
			break
		case "NM_IV_Boltzmann":
			if ( numpnts( FT_guess ) == 5 )
				FT_guess[0] = 1 // G
				FT_guess[1] = 0 // Vrev
				FT_guess[2] = 0 // Vhalf
				FT_guess[3] = 1 // Vslope
				FT_guess[4] = 1 // N
			endif
			break
		case "NM_IV_GHK":
			if ( numpnts( FT_guess ) == 4 )
				FT_guess[0] = 1 // G
				FT_guess[1] = 0 // Vrev
				FT_guess[2] = 22 // Temp
				FT_guess[3] = 1 // z
				FT_hold[2] = 1
				FT_hold[3] = 1
			endif
			break
		case "NM_IV_GHK_Boltzmann":
			if ( numpnts( FT_guess ) == 7 )
				FT_guess[0] = 1 // G
				FT_guess[1] = 0 // Vrev
				FT_guess[2] = 22 // Temp
				FT_guess[3] = 1 // z
				FT_guess[4] = 0 // Vhalf
				FT_guess[5] = 1 // Vslope
				FT_guess[6] = 1 // N
				FT_hold[2] = 1
				FT_hold[3] = 1
			endif
			break
		case "NM_MPFA1": // 4
			if ( ( numpnts( FT_guess ) == 4 ) && ( numpnts( FT_hold ) == 4 ) )
				FT_guess[0] = 10 // Q
				FT_guess[1] = 5 // N
				FT_guess[2] = 0.39 // CV1
				FT_guess[3] = 0.31 // CV2
				FT_hold[2] = 1
				FT_hold[3] = 1
			endif
			break
		case "NM_MPFA2": // 5
			if ( ( numpnts( FT_guess ) == 5 ) && ( numpnts( FT_hold ) == 5 ) )
				FT_guess[0] = 10 // Q
				FT_guess[1] = 5 // N
				FT_guess[2] = 0.5 // alpha
				FT_guess[3] = 0.39 // CV2
				FT_guess[4] = 0.31 // CV2
				FT_hold[3] = 1
				FT_hold[4] = 1
			endif
			break
		case "NM_RCvstep": // 6
			if ( ( numpnts( FT_guess ) == 6 ) && ( numpnts( FT_hold ) == 6 ) )
				FT_guess[0] = 10 // Vstep // mV
				FT_guess[1] = 5 // X0 // Vstep onset // ms
				FT_guess[2] = 0 // I0 // baseline current // pA
				FT_guess[3] = 0.01 // Rp // GOhms
				FT_guess[4] = 0.5 // Rm // GOhms
				FT_guess[5] = 10 // Cm // pF
				FT_hold[0] = 1
				FT_hold[1] = 1
			endif
			break
		case "NMKeidingGauss":
			if ( ( numpnts( FT_guess ) == 6 ) && ( numpnts( FT_hold ) == 6 ) )
				FT_guess[0] = 1 // X0
				FT_guess[1] = 0.1 // STDVx
				FT_guess[2] = 20 // phi
				FT_guess[3] = 0 // T
				FT_guess[4] = 0 // N // not a fit parameter // used to compute phi-cutoff
				FT_guess[5] = 0 // phi-cutoff // not a fit parameter // used to compute phi-cutoff
				FT_hold[3] = 1
				FT_hold[4] = 1
				FT_hold[5] = 1
			endif
			break
		case "NMKeidingChi":
			if ( ( numpnts( FT_guess ) == 4 ) && ( numpnts( FT_hold ) == 4 ) )
				FT_guess[0] = 100 // f
				FT_guess[1] = 0.01 // beta
				FT_guess[2] = 20 // phi
				FT_guess[3] = 0 // T
				FT_hold[3] = 1
			endif
			break
		case "NMKeidingGamma":
			if ( ( numpnts( FT_guess ) == 5 ) && ( numpnts( FT_hold ) == 5 ) )
				FT_guess[0] = 0 // X0
				FT_guess[1] = 100 // f
				FT_guess[2] = 0.01 // beta
				FT_guess[3] = 20 // phi
				FT_guess[4] = 0 // T
				FT_hold[0] = 1
				FT_hold[4] = 1
			endif
			break
		case "NMCircle":
			if ( numpnts( FT_guess ) == 3 )
				FT_guess[0] = 0 // X0
				FT_guess[1] = 1 // DX
				FT_guess[2] = 1 // R
				FT_hold[1] = 1
			endif
			break
		case "NMEllipse":
			if ( numpnts( FT_guess ) == 4 )
				FT_guess[0] = 0 // X0
				FT_guess[1] = 1 // DX
				FT_guess[2] = 1 // R
				FT_guess[3] = 1 // E
				FT_hold[1] = 1
			endif
			break
	endswitch
	
	return 0

End // NMFitGuess

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitWaveTableSave()

	String subD = NMFitSubDirectory()
	
	if ( strlen( subD ) == 0 )
		return 0
	endif
	
	if ( !DataFolderExists( subD ) )
		NewDataFolder $RemoveEnding( subD, ":" )
	endif
	
	if ( WaveExists( $NMFitWavePath( "cname" ) ) )
		Duplicate /O $NMFitWavePath( "cname" ), $NMFitSubDirWavePath( "cname" )
	endif
	
	if ( WaveExists( $NMFitWavePath( "guess" ) ) )
		Duplicate /O $NMFitWavePath( "guess" ), $NMFitSubDirWavePath( "guess" )
	endif
	
	if ( WaveExists( $NMFitWavePath( "hold" ) ) )
		Duplicate /O $NMFitWavePath( "hold" ), $NMFitSubDirWavePath( "guess" )
	endif
	
	return 0

End // NMFitWaveTableSave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitSaveCurrentCall()

	String tName = NMFitTableName()
	
	if ( WinType( tName ) == 2 )
		DoWindow /F $tName
	endif

	return NMFitSaveCurrent( history = 1 )

End // NMFitSaveCurrentCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitSaveCurrent( [ fitError, history ] )
	Variable history // print function command to history ( 0 ) no ( 1 ) yes

	Variable fitError
	String fitwave, reswave, wnote
	
	if ( ParamIsDefault( fitError ) )
		fitError = NMFitVarGet( "V_FitQuitReason" )
	endif
	
	if ( history )
		NMCommandHistory( "" )
	endif
	
	Variable currentChan = CurrentNMChannel()
	Variable currentWave = CurrentNMWave()
	
	String sourceWave = NMChanWaveName( currentChan, currentWave )

	if ( NMFitVarGet( "SaveFitWaves" ) )
	
		fitwave = NMFitDisplayWaveName()
		reswave = NMFitResidDisplayWaveName()
		
		if ( fitError == 0 )
		
			WaveStats /Q/Z $fitwave
			
			if ( numtype( V_avg ) > 0 )
			
				NMFitWaveCompute( 1 ) // something went wrong - recompute fit wave
				
				if ( WaveExists( $reswave ) )
				
					Wave res = $reswave
				
					res = Nan
					
				endif
				
			endif
		
		endif
		
		if ( fitError == 0 )
		
			if ( WaveExists( $fitwave ) )
				Duplicate /O $fitwave $( "Fit_" + sourceWave )
			endif
			
			if ( WaveExists( $reswave ) )
				Duplicate /O $reswave $( "Res_" + sourceWave )
			endif
		
		else
		
			if ( WaveExists( $( "Fit_" + sourceWave ) ) )
			
				Wave wtemp = $( "Fit_" + sourceWave )
				wtemp = NaN
				
			endif
			
			if ( WaveExists( $( "Res_" + sourceWave ) ) )
				
				Wave wtemp = $( "Res_" + sourceWave )
				wtemp = NaN
				
			endif
		
		endif
		
	endif

	return NMFitSaveClear( CurrentNMWave(), 0, fitError = fitError )
	
End // NMFitSaveCurrent

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitClearCall()

	Variable clear = NMFitVarGet( "ClearWavesSelect" )
	
	Prompt clear, "clear results for:", popup "current wave;all waves;"
	DoPrompt "Clear Fit Results", clear
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMvar( NMFitDF + "ClearWavesSelect", clear )
	
	if ( clear == 1 )
		return NMFitClearCurrent( history = 1 )
	elseif ( clear == 2 )
		return NMFitClearAll( history = 1 )
	endif
	
	return ""

End // NMFitClearCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitClearCurrent( [ history ] )
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable waveNum = CurrentNMWave()
	String returnStr
	
	if ( history )
		NMCommandHistory( "" )
	endif

	String tName = NMFitTableName()
	
	if ( WinType( tName ) == 2 )
		DoWindow /F $tName
	endif

	returnStr = NMFitSaveClear( waveNum, 1 )
	
	if ( strlen( returnStr ) == 0 )
		NMDoAlert( "NMFitClearCurrent error: failed to clear fit results for wave #" + num2istr( waveNum ) )
	endif
	
	return returnStr
	
End // NMFitClearCurrent

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitClearAll( [ history ] )
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	if ( history )
		NMCommandHistory( "" )
	endif

	Variable wcnt, nwaves = NMNumWaves()
	String wName, tList = ""
	
	Variable chan = CurrentNMChannel()
	
	String tName = NMFitTableName()
	
	for ( wcnt = 0 ; wcnt < nwaves ; wcnt += 1 )
		NMFitSaveClear( wcnt, 1 )
	endfor
	
	DoWindow /K $tName
	
	return NMSubfolderClear( CurrentNMFitSubfolder() )
	
End // NMFitClearAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitSaveClear( waveNum, select [ fitError ] )
	Variable waveNum
	Variable select // ( 0 ) save ( 1 ) clear
	Variable fitError

	Variable icnt, scaleFactor = 1
	Variable chan = CurrentNMChannel()
	Variable numParams = NMFitNumParams()

	String wName = NMChanWaveName( chan, waveNum )
	String tName = NMFitTable( 0 )
	String fitWave = NMFitWaveName( waveNum )
	String resWave = NMFitResidWaveName( waveNum )
	String fitDisplay = NMFitDisplayWaveName()
	String resDisplay = NMFitResidDisplayWaveName()
	String df = NMFitWaveDF()
	
	if ( !WaveExists( $NMFitWavePath( "coef" ) ) || !WaveExists( $NMFitWavePath( "sigma" ) ) )
		return ""
	endif
	
	if ( ParamIsDefault( fitError ) )
		fitError = NMFitVarGet( "V_FitQuitReason" )
	endif
	
	Wave FT_coef = $NMFitWavePath( "coef" )
	Wave FT_sigma = $NMFitWavePath( "sigma" )
	
	Variable rowNum = NMFitTableRow( wName )
	
	if ( ( numtype( rowNum ) > 0 ) || ( rowNum < 0 ) )
		return ""
	endif
	
	if ( select == 1 ) // clear
	
		scaleFactor = Nan
		
		if ( WaveExists( $fitWave ) )
			Wave wtemp = $fitWave
			wtemp = Nan
		endif
		
		if ( WaveExists( $resWave ) )
			Wave wtemp = $resWave
			wtemp = Nan
		endif
		
		if ( WaveExists( $fitDisplay ) )
			Wave wtemp = $fitDisplay
			wtemp = Nan
		endif
		
		if ( WaveExists( $resDisplay ) )
			Wave wtemp = $resDisplay
			wtemp = Nan
		endif
		
	endif
	
	for ( icnt = 0 ; icnt < numParams ; icnt += 1 )
	
		if ( ( icnt >= numpnts( FT_coef ) ) || ( icnt >= numpnts( FT_sigma ) ) )
			break
		endif
	
		if ( ( fitError != 0 ) || ( numtype( FT_coef[ icnt ] ) > 0 ) || ( numtype( FT_sigma[ icnt ] ) > 0 ) )
			scaleFactor = Nan
		endif
		
		wName = NMFitTableWaveNameCoef( icnt, 0, chan, OverwriteMode )
		
		if ( WaveExists( $wName ) && ( rowNum < numpnts( $wName ) ) )
			Wave wtemp = $wName
			wtemp[ rowNum ] = FT_coef[ icnt ] * scaleFactor
		endif
	
		wName = NMFitTableWaveNameCoef( icnt, 1, chan, OverwriteMode )
		
		if ( WaveExists( $wName ) && ( rowNum < numpnts( $wName ) ) )
			Wave wtemp = $wName
			wtemp[ rowNum ] = FT_sigma[ icnt ] * scaleFactor
		endif
		
	endfor
	
	wName = NMFitTableWaveName( "ChiSqr", chan, OverwriteMode )
	
	if ( WaveExists( $wName ) && ( rowNum < numpnts( $wName ) ) )
		Wave wtemp = $wName
		wtemp[ rowNum ] = NMFitVarGet( "V_chisq" ) * scaleFactor
	endif
	
	wName = NMFitTableWaveName( "NumPnts", chan, OverwriteMode )
	
	if ( WaveExists( $wName ) && ( rowNum < numpnts( $wName ) ) )
		Wave wtemp = $wName
		wtemp[ rowNum ] = NMFitVarGet( "V_npnts" ) * scaleFactor
	endif
	
	wName = NMFitTableWaveName( "NumNANs", chan, OverwriteMode )
	
	if ( WaveExists( $wName ) && ( rowNum < numpnts( $wName ) ) )
		Wave wtemp = $wName
		wtemp[ rowNum ] = NMFitVarGet( "V_numNaNs" ) * scaleFactor
	endif
	
	wName = NMFitTableWaveName( "NumINFs", chan, OverwriteMode )
	
	if ( WaveExists( $wName ) && ( rowNum < numpnts( $wName ) ) )
		Wave wtemp = $wName
		wtemp[ rowNum ] = NMFitVarGet( "V_numINFs" ) * scaleFactor
	endif
	
	wName = NMFitTableWaveName( "StartRow", chan, OverwriteMode )
	
	if ( WaveExists( $wName ) && ( rowNum < numpnts( $wName ) ) )
		Wave wtemp = $wName
		wtemp[ rowNum ] = NMFitVarGet( "V_startRow" ) * scaleFactor
	endif
	
	wName = NMFitTableWaveName( "EndRow", chan, OverwriteMode )
	
	if ( WaveExists( $wName ) && ( rowNum < numpnts( $wName ) ) )
		Wave wtemp = $wName
		wtemp[ rowNum ] = NMFitVarGet( "V_endRow" ) * scaleFactor
	endif
	
	return tName
	
End // NMFitSaveClear

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitSaveRetrieve( waveNum )
	Variable waveNum

	Variable icnt
	Variable chan = CurrentNMChannel()
	Variable numParams = NMFitNumParams()

	String wName = NMChanWaveName( chan, waveNum )
	String tName = NMFitTable( 0 )
	String fitWave = NMFitWaveName( waveNum )
	String resWave = NMFitResidWaveName( waveNum )
	String fitDisplay = NMFitDisplayWaveName()
	String resDisplay = NMFitResidDisplayWaveName()
	String df = NMFitWaveDF()
	
	if ( !WaveExists( $NMFitWavePath( "coef" ) ) || !WaveExists( $NMFitWavePath( "sigma" ) ) )
		return ""
	endif
	
	Wave FT_coef = $NMFitWavePath( "coef" )
	Wave FT_sigma = $NMFitWavePath( "sigma" )
	
	Variable rowNum = NMFitTableRow( wName )
	
	if ( numtype( rowNum ) > 0 )
		return ""
	endif
	
	for ( icnt = 0 ; icnt < numParams ; icnt += 1 )
		
		wName = NMFitTableWaveNameCoef( icnt, 0, chan, OverwriteMode )
		
		if ( WaveExists( $wName ) && ( rowNum < numpnts( $wName ) ) && ( icnt < numpnts( FT_coef ) ) )
			Wave wtemp = $wName
			FT_coef[ icnt ] = wtemp[ rowNum ]
		endif
	
		wName = NMFitTableWaveNameCoef( icnt, 1, chan, OverwriteMode )
		
		if ( WaveExists( $wName ) && ( rowNum < numpnts( $wName ) ) && ( icnt < numpnts( FT_sigma ) ) )
			Wave wtemp = $wName
			FT_sigma[ icnt ] = wtemp[ rowNum ]
		endif
		
	endfor
	
	return tName
	
End // NMFitSaveRetrieve

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Fit Table Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitTableName()

	String fxn = NMFitStrGet( "FxnShort" )
	
	if ( strlen( fxn ) == 0 )
		return ""
	endif

	String tName = "FT_" + fxn + "_" + CurrentNMFolderPrefix() + NMWaveSelectStr() + "_"
	
	tName = NextGraphName( tName, CurrentNMChannel(), OverwriteMode )
	
	//return NMSubfolderTableName( CurrentNMFitSubfolder(), "FT_" )
	return tName

End // NMFitTableName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitTableRow( wName )
	String wName

	Variable icnt

	Variable chanNum = CurrentNMChannel()

	String wName2 = NMFitTableWaveName( "wName", chanNum, OverwriteMode )
	
	if ( !WaveExists( $wName2 ) )
		return NaN
	endif
	
	Wave /T wtemp = $wName2
	
	for ( icnt = 0 ; icnt < numpnts( wtemp ) ; icnt += 1 )
		if ( StringMatch( wName, wtemp[ icnt ] ) )
			return icnt
		endif
	endfor

	return NaN

End // NMFitTableRow

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitTableWaveName( name, chanNum, overwrite )
	String name
	Variable chanNum
	Variable overwrite // ( 0 ) no ( 1 ) yes
	
	String fname
	String fxn = NMFitStrGet( "FxnShort" )
	String subfolder = CurrentNMFitSubfolder()
	
	if ( strlen( fxn ) == 0 )
		return ""
	endif
	
	if ( strlen( fxn ) > 5 )
		fxn = ReplaceString( "_", fxn, "" )
		fxn = ReplaceString( "-", fxn, "" )
		fxn = fxn[0, 4]
	endif
	
	String wPrefix = "FT_" + fxn + "_" + name+ "_" + NMWaveSelectStr() + "_"
	
	fname = NextWaveName2( subfolder, wPrefix, chanNum, overwrite )
	
	fname = NMCheckStringName( fname )
	
	return subfolder + fname

End // NMFitTableWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitTableWaveNameCoef( coefNum, sig, chanNum, overwrite )
	Variable coefNum
	Variable sig // ( 0 ) no ( 1 ) yes
	Variable chanNum
	Variable overwrite // ( 0 ) no ( 1 ) yes
	
	String wName = NMFitWavePath( "cname" )
	
	if ( !WaveExists( $wName ) || ( coefNum < 0 ) || ( coefNum >= numpnts( $wName ) ) )
		return ""
	endif
	
	Wave /T FT_cname = $wName
	
	String fxn = FT_cname[ coefNum ]
	
	if ( sig )
		fxn += "sig"
	endif
	
	return NMFitTableWaveName( fxn, chanNum, overwrite )

End // NMFitTableWaveNameCoef

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitTable( forceNew [ hide ] )
	Variable forceNew // ( 0 ) no ( 1 ) yes
	Variable hide

	Variable icnt, numWaves
	String wName, outList = ""
	
	STRUCT Rect w

	NMChanWaveList2Waves()
	
	Variable chan = CurrentNMChannel()
	
	Variable autoTable = NMFitVarGet( "AutoTable" )

	String fxn = NMFitStrGet( "FxnShort" )
	
	if ( strlen( fxn ) == 0 )
		return ""
	endif
	
	String tName = NMFitTableName()
	//String waveOfNames = NMChanWaveListName( CurrentNMChannel() )
	String wList = NMWaveSelectList( CurrentNMChannel() )
	String title = NMFolderListName( "" ) + " : Fit " + fxn + " : Ch" + ChanNum2Char( CurrentNMChannel() ) + " : " + CurrentNMWavePrefix() + " : " + NMWaveSelectGet()
	
	numWaves = ItemsInList( wList )
	
	if ( numWaves <= 0 )
		return ""
	endif
	
	wName = NMFitWavePath( "cname" )
	
	if ( !WaveExists( $wName ) )
		//return NM2ErrorStr( 1, "wName", wName )
		return ""
	endif
	
	Wave /T FT_cname = $wName
	
	if ( ( WinType( tName ) == 2 ) && !forceNew )
		//DoWindow /F $tName
		return tName
	endif
	
	if ( !NMVarGet( "GraphsAndTablesOn" ) )
		autoTable = 0
	endif
	
	CheckNMFitSubfolder( "" )
	
	wName = NMFitTableWaveName( "wName", chan, OverwriteMode )
	
	if ( WaveExists( $wName ) )
		NMFitSubfolderTable( "" )
		return tName
	endif
	
	if ( autoTable )
		NMOutputListsReset()
		NMWinCascadeRect( w )
		DoWindow /K $tName
		Edit /HIDE=(hide)/K=1/N=$tName/W=(w.left,w.top,w.right,w.bottom) as title
	endif
	
	KillWaves /Z $wName
	
	List2Wave( wList, wName, overwrite = 1 )
	
	if ( !WaveExists( $wName ) )
		return ""
	endif
	
	if ( autoTable )
		AppendToTable /W=$tName $wName
	endif
	
	for ( icnt = 0 ; icnt < numpnts( FT_cname ) ; icnt += 1 )
	
		wName = NMFitTableWaveNameCoef( icnt, 0, chan, OverwriteMode )
		Make /O/N=( numWaves ) $wName = Nan
		outList += wName + ";"
		
		if ( autoTable )
			AppendToTable /W=$tName $wName
		endif
		
		wName = NMFitTableWaveNameCoef( icnt, 1, chan, OverwriteMode )
		Make /O/N=( numWaves ) $wName = Nan
		outList += wName + ";"
		
		if ( autoTable )
			AppendToTable /W=$tName $wName
		endif
		
	endfor
	
	wName = NMFitTableWaveName( "ChiSqr", chan, OverwriteMode )
	Make /O/N=( numWaves ) $wName = Nan
	outList += wName + ";"
	
	if ( autoTable )
		AppendToTable /W=$tName $wName
	endif
	
	wName = NMFitTableWaveName( "NumPnts", chan, OverwriteMode )
	Make /O/N=( numWaves ) $wName = Nan
	outList += wName + ";"
	
	if ( autoTable )
		AppendToTable /W=$tName $wName
	endif
	
	wName = NMFitTableWaveName( "NumNANs",chan, OverwriteMode )
	Make /O/N=( numWaves ) $wName = Nan
	outList += wName + ";"
	
	if ( autoTable )
		AppendToTable /W=$tName $wName
	endif
	
	wName = NMFitTableWaveName( "NumINFs", chan, OverwriteMode )
	Make /O/N=( numWaves ) $wName = Nan
	outList += wName + ";"
	
	if ( autoTable )
		AppendToTable /W=$tName $wName
	endif
	
	wName = NMFitTableWaveName( "StartRow",chan, OverwriteMode )
	Make /O/N=( numWaves ) $wName = Nan
	outList += wName + ";"
	
	if ( autoTable )
		AppendToTable /W=$tName $wName
	endif
	
	wName = NMFitTableWaveName( "EndRow", chan, OverwriteMode )
	Make /O/N=( numWaves ) $wName = Nan
	outList += wName + ";"
	
	if ( autoTable )
		AppendToTable /W=$tName $wName
	endif
	
	if ( !autoTable )
		tName = ""
	endif
	
	SetNMstr( NMDF + "OutputWaveList", outList )
	SetNMstr( NMDF + "OutputWinList", tName )
	
	NMHistoryOutputWindows()
	
	return tName

End // NMFitTable

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Graph Display Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitPlotAllCall( plotData )
	Variable plotData // ( 0 ) no ( 1 ) yes
	
	return NMFitPlotAll( plotData, history = 1 )
	
End // NMFitPlotAllCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitPlotAll( plotData [ history ] )
	Variable plotData // ( 0 ) no ( 1 ) yes
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable wcnt, error
	String cList = "", fList = "", fitWave, xLabel, yLabel, vlist = ""
	
	NMOutputListsReset()
	
	if ( history )
		vlist = NMCmdNum( plotData, vlist, integer = 1 )
		NMCommandHistory( vlist )
	endif
	
	Variable currentChan = CurrentNMChannel()
	Variable nwaves = NMNumWaves()
	
	String fxn = NMFitStrGet( "FxnShort" )
	String wavePrefix = CurrentNMWavePrefix()
	String gPrefix = "FT_" + CurrentNMFolderPrefix() + NMWaveSelectStr() + fxn + num2istr( plotData )
	String gName = NextGraphName( gPrefix, currentChan, OverwriteMode )
	String gTitle = NMFolderListName( "" ) + " : Ch" + ChanNum2Char( currentChan ) + " : " + wavePrefix + " : " + NMWaveSelectGet() + " : " + fxn + " Fits"
	String xWave = NMXwave()
	
	String prefixFolder = CurrentNMPrefixFolder()
	String xWavePrefix = StrVarOrDefault( prefixFolder + "XwavePrefix", "" )
	
	if ( strlen( xWavePrefix ) > 0 )
		NMDoAlert( "xWavePrefix is not allowed with this function", title = "NMFitPlotAll Error" )
		return -1
	endif
	
	for ( wcnt = 0 ; wcnt < nwaves ; wcnt += 1 )
	
		fitWave = NMFitWaveName( wcnt )
		
		if ( WaveExists( $fitWave ) )
			cList = AddListItem( NMChanWaveName( currentChan, wcnt ), cList, ";", inf )
			fList = AddListItem( fitWave, fList, ";", inf )
		endif
		
	endfor
	
	If ( ItemsInList( fList ) <= 0 )
		NMDoAlert( "There are no saved fits to plot." )
		return 0
	endif
	
	xLabel = NMChanLabelX()
	yLabel = NMChanLabelY()

	if ( plotData )
	
		NMGraph( wList = cList, xWave = xWave, gName = gName, gTitle = gTitle, xLabel = xLabel, yLabel = yLabel )
		
		if ( WinType( gName ) != 1 )
			return -1
		endif
		
		ModifyGraph /W=$gName rgb=(0,0,0)
		
		for ( wcnt = 0 ; wcnt < ItemsInlist( fList ) ; wcnt += 1 )
			AppendToGraph /Q/W=$gName $StringFromList( wcnt, fList )
		endfor
		
	else
	
		NMGraph( wList = fList, xWave = xWave, gName = gName, gTitle = gTitle, xLabel = xLabel, yLabel = yLabel )
		ModifyGraph /W=$gName rgb=(65280,0,0)
	
	endif
	
	SetNMstr( NMDF + "OutputWinList", gName )
	
	NMHistoryOutputWindows()
	
	return 0

End // NMFitPlotAll

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Subfolder Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitSubfolderPrefix()

	String fxn = NMFitStrGet( "FxnShort" )
	
	if ( strlen( fxn ) > 0 )
		return "Fit_" + NMFitStrGet( "FxnShort" ) + "_"
	else
		return "Fit_"
	endif

End //NMFitSubfolderPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitSubfolder( wavePrefix, waveSelect )
	String wavePrefix
	String waveSelect
	
	if ( !NMFitVarGet( "UseSubfolders" ) )
		return ""
	endif
	
	return NMSubfolderName( NMFitSubfolderPrefix(), wavePrefix, CurrentNMChannel(), waveSelect )

End // NMFitSubfolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMFitSubfolder()

	return NMFitSubfolder( CurrentNMWavePrefix(), NMWaveSelectShort() )
	
End // CurrentNMFitSubfolder

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMFitSubfolder( subfolder )
	String subfolder // ( "" ) for current
	
	if ( strlen( subfolder ) == 0 )
		subfolder = CurrentNMFitSubfolder()
	endif
	
	return CheckNMSubfolder( subfolder )
	
End // CheckNMFitSubfolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitSubfolderTableCall()

	Variable items
	
	String subfolderPrefix = NMFitSubfolderPrefix()
	String fList = NMSubfolderList2( CurrentNMFolder( 1 ), subfolderPrefix, 0, 0 )
	
	String subfolder = StringFromList( 0, fList )
	
	items = ItemsInList( fList )
	
	if ( items <= 0 )
		NMDoAlert( "Fit Table Alert: there are currently no Fit subfolders in the current NM folder to create a table." )
		return ""
	endif
	
	if ( items > 1 )
	
		subfolder = StrVarOrDefault( NMFitDF+"SubfolderTableSelect", subfolder )
		
		Prompt subfolder, "select results subfolder:", popup fList
		DoPrompt "Fit Table", subfolder
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		SetNMstr( NMFitDF + "SubfolderTableSelect", subfolder )
		
	endif
	
	return NMFitSubfolderTable( subfolder, history = 1 )

End // NMFitSubfolderTableCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitSubfolderTable( subfolder [ history ] )
	String subfolder
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	String vlist = ""
	String tName = NMFitTableName()
	
	NMOutputListsReset()
	
	if ( history )
		vlist = NMCmdStr( subfolder, vlist )
		NMCommandHistory( vlist )
	endif
	
	if ( strlen( subfolder ) == 0 )
		subfolder = CurrentNMFitSubfolder()
	endif
	
	tName = NMSubfolderTable( subfolder, "FT_", tName = tName )
	
	SetNMstr( NMDF + "OutputWinList", tName )
	
	NMHistoryOutputWindows()
	
	return tName
	
End // NMFitSubfolderTable

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Fit functions not used anymore
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitX0Set() // NOT USED

	Variable x0 = 0
	Variable xbgn = NMFitVarGet( "Xbgn" )
	
	Variable currentChan = CurrentNMChannel()
	
	String gName = ChanGraphName( currentChan )
	String wName = ChanDisplayWave( currentChan )
	
	strswitch( NMFitStrGet( "Function" ) )
	
		case "Poly_XOffset":
		case "Exp_XOffset":
		case "DblExp_XOffset":
			break
	
		default:
			return 0
			
	endswitch

	if ( NMFitVarGet( "Cursors" ) && ( strlen( CsrInfo( A, gName ) ) > 0 ) )
		x0 = xcsr( A )
	elseif ( numtype( xbgn ) == 0 )
		x0 = xbgn
	else
		if ( WaveExists( $wName ) )
			x0 = leftx( $wName )
		endif
	endif
	
	SetNMvar( NMFitDF + "UserInput", x0 )
	
	return x0

End // NMFitX0Set

//****************************************************************
//****************************************************************
//****************************************************************

Function SetNMFitVar( varName, value ) // NOT USED ANYMORE
	String varName
	Variable value
	
	if ( strlen( varName ) == 0 )
		return NM2Error( 21, "varName", varName )
	endif
	
	if ( !DataFolderExists( NMFitDF ) )
		return NM2Error( 30, "NMFitDF", NMFitDF )
	endif
	
	Variable /G $NMFitDF+varName = value
	
	return 0
	
End // SetNMFitVar

//****************************************************************
//****************************************************************
//****************************************************************

Function SetNMFitStr( strVarName, strValue ) // NOT USED ANYMORE
	String strVarName
	String strValue
	
	if ( strlen( strVarName ) == 0 )
		return NM2Error( 21, "strVarName", strVarName )
	endif
	
	if ( !DataFolderExists( NMFitDF ) )
		return NM2Error( 30, "NMFitDF", NMFitDF )
	endif
	
	String /G $NMFitDF+strVarName = strValue
	
	return 0
	
End // SetNMFitStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFitVar( varName ) // NOT USED
	String varName
	
	return NMFitVarGet( varName )
	
End // NMFitVar

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFitStr( strVarName ) // NOT USED
	String strVarName
	
	return NMFitStrGet( strVarName )
	
End // NMFitStr

//****************************************************************
//****************************************************************
//****************************************************************
//
//	More Fit Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMAlpha( w, x ) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = A0+A·exp(-(x-X0)/T)·(x-X0)/T
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 4
	//CurveFitDialog/ w[0] = x0
	//CurveFitDialog/ w[1] = A0
	//CurveFitDialog/ w[2] = A
	//CurveFitDialog/ w[3] = tau
	
	if ( x < w[0] )
		return 0
	endif
	
	return w[1] + w[2] * exp( -( x - w[0] ) / w[3] ) * ( x - w[0] ) / w[3]
	
End // NMAlpha

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGamma( w, x ) : FitFunc // see Igor StatsGammaPDF
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = StatsGammaPDF(x0,sigma,gamma)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 3
	//CurveFitDialog/ w[0] = x0
	//CurveFitDialog/ w[1] = sigma
	//CurveFitDialog/ w[2] = gamma
	
	if ( x < w[0] )
		return 0
	endif
	
	return StatsGammaPDF( x, w[0], w[1], w[2] )
	
End // NMGamma

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGauss( w, x ) : FitFunc // PDF // see Igor Gauss
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the Function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = Gauss(x,x0,STDVx)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 2
	//CurveFitDialog/ w[0] = x0
	//CurveFitDialog/ w[1] = STDVx
	
	return Gauss( x, w[0], w[1] )

End // NMGauss

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGauss1( w, x ) : FitFunc // uses Igor "gauss" function. removes confusion about "w" parameter.
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the Function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = A0 + A·Gauss(x,x0,STDVx)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 4
	//CurveFitDialog/ w[0] = A0
	//CurveFitDialog/ w[1] = A
	//CurveFitDialog/ w[2] = x0
	//CurveFitDialog/ w[3] = STDVx
	
	Variable amp = 1 / ( w[3] * sqrt( 2 * pi ) )
	
	return w[0] + w[1] * Gauss( x, w[2], w[3] ) / amp

End // NMGauss1

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGaussSum( w, x ) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the Function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = A0 + A1·Gauss(x,x1,STDV1) + A2·Gauss(x,x2,STDV2)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 7
	//CurveFitDialog/ w[0] = A0
	//CurveFitDialog/ w[1] = A1
	//CurveFitDialog/ w[2] = x1
	//CurveFitDialog/ w[3] = STDV1
	//CurveFitDialog/ w[4] = A2
	//CurveFitDialog/ w[5] = x2
	//CurveFitDialog/ w[6] = STDV2
	
	Variable amp1 = 1 / ( w[3] * sqrt( 2 * pi ) )
	Variable amp2 = 1 / ( w[6] * sqrt( 2 * pi ) )
	
	Variable g1 = w[1] * Gauss( x, w[2], w[3] ) / amp1
	Variable g2 = w[4] * Gauss( x, w[5], w[6] ) / amp2
	
	return w[0] + g1 + g2

End // NMGaussSum

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGauss2( w, x, y ) : FitFunc
	Wave w
	Variable x
	Variable y

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the Function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x,y) = A0 + A·Gauss(x,x0,STDVx,y,y0,STDVy)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 2
	//CurveFitDialog/ x
	//CurveFitDialog/ y
	//CurveFitDialog/ Coefficients 6
	//CurveFitDialog/ w[0] = A0
	//CurveFitDialog/ w[1] = A
	//CurveFitDialog/ w[2] = x0
	//CurveFitDialog/ w[3] = STDVx
	//CurveFitDialog/ w[4] = y0
	//CurveFitDialog/ w[5] = STDVy
	
	Variable amp = 1 / ( w[3] * w[5] * 2 * pi )
	
	return w[0] + w[1] * Gauss( x, w[2], w[3], y, w[4], w[5] ) / amp

End // NMGauss2

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGauss3( w, x, y, z ) : FitFunc
	Wave w
	Variable x
	Variable y
	Variable z

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the Function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x,y,z) = A0 + A·Gauss(x,x0,STDVx,y,y0,STDVy,z,z0,STDVz)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 3
	//CurveFitDialog/ x
	//CurveFitDialog/ y
	//CurveFitDialog/ z
	//CurveFitDialog/ Coefficients 8
	//CurveFitDialog/ w[0] = A0
	//CurveFitDialog/ w[1] = A
	//CurveFitDialog/ w[2] = x0
	//CurveFitDialog/ w[3] = STDVx
	//CurveFitDialog/ w[4] = y0
	//CurveFitDialog/ w[5] = STDVy
	//CurveFitDialog/ w[6] = z0
	//CurveFitDialog/ w[7] = STDVz
	
	Variable amp = 1 / ( w[3] * w[5] * w[7] * 2 * pi * sqrt( 2 * pi ) )
	
	return w[0] + w[1] * Gauss( x, w[2], w[3], y, w[4], w[5], z, w[6], w[7] )

End // NMGauss3

//****************************************************************
//****************************************************************
//****************************************************************

Function NMExp3( w,x ) : FitFunc // triple exponential function
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = A0+A1·exp(-(x-X0)/T1)+A2·exp(-(x-X0)/T2)+A3·exp(-(x-X0)/T3)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 8
	//CurveFitDialog/ w[0] = X0
	//CurveFitDialog/ w[1] = A0
	//CurveFitDialog/ w[2] = A1
	//CurveFitDialog/ w[3] = T1
	//CurveFitDialog/ w[4] = A2
	//CurveFitDialog/ w[5] = T2
	//CurveFitDialog/ w[6] = A3
	//CurveFitDialog/ w[7] = T3
	
	Variable e1 = w[2] * exp( -( x - w[0] ) / w[3] )
	Variable e2 = w[4] * exp( -( x - w[0] ) / w[5] )
	Variable e3 = w[6] * exp( -( x - w[0] ) / w[7] )
	
	return w[1] + e1 + e2 + e3
	
End // NMExp3

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSynExp3( w,x ) : FitFunc // multiplication of the rise and decay exponentials // decay is sum of 2 exp
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = (1-exp(-(x-X0)/TR1))^N·(A1·exp(-(x-X0)/TD1)+A2·exp(-(x-X0)/TD2))
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 7
	//CurveFitDialog/ w[0] = X0
	//CurveFitDialog/ w[1] = TR1
	//CurveFitDialog/ w[2] = N
	//CurveFitDialog/ w[3] = A1
	//CurveFitDialog/ w[4] = TD1
	//CurveFitDialog/ w[5] = A2
	//CurveFitDialog/ w[6] = TD2
	
	Variable scale = NMFitVarGet( "SynExpSign" )
	Variable hold, e1, e2, e3
	
	if ( x < w[0] )
		return 0
	endif
	
	switch( scale )
		case 1:
		case -1:
			break
		default:
			scale = 1
	endswitch
	
	w[3] = scale * abs( w[3] )
	w[5] = scale * abs( w[5] )
	
	if ( w[6] < w[4] )
		hold = w[6]
		w[6] = w[4]
		w[4] = hold
		hold = w[5]
		w[5] = w[3]
		w[3] = hold
	endif
	
	e1 = ( 1 - exp( -( x - w[0] ) / w[1] ) ) ^ w[2]
	e2 = w[3] * exp( -( x - w[0] ) / w[4] )
	e3 = w[5] * exp( -( x - w[0] ) / w[6] )
	
	return e1 * ( e2 + e3 )
	
End // NMSynExp3

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSynExp3F( w,x ) : FitFunc // multiplication of the rise and decay exponentials // decay is sum of 2 exp
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = A0·(1-exp(-(x-X0)/TR1))^N·(F·exp(-(x-X0)/TD1)+(1-F)·exp(-(x-X0 )/TD2))
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 7
	//CurveFitDialog/ w[0] = X0
	//CurveFitDialog/ w[1] = TR1
	//CurveFitDialog/ w[2] = N
	//CurveFitDialog/ w[3] = A0
	//CurveFitDialog/ w[4] = TD1
	//CurveFitDialog/ w[5] = F
	//CurveFitDialog/ w[6] = TD2
	
	Variable scale = NMFitVarGet( "SynExpSign" )
	Variable e1, e2, e3
	
	if ( x < w[0] )
		return 0
	endif
	
	switch( scale )
		case 1:
		case -1:
			break
		default:
			scale = 1
	endswitch
	
	w[3] = scale * abs( w[3] )
	w[5] = scale * abs( w[5] )
	
	e1 = w[3] * ( 1 - exp( -( x - w[0] ) / w[1] ) ) ^ w[2]
	e2 = w[5] * exp( -( x - w[0] ) / w[4] )
	e3 = ( 1 - w[5] ) * exp( -( x - w[0] ) / w[6] )
	
	return e1 * ( e2 + e3 )
	
End // NMSynExp3F

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSynExp4( w,x ) : FitFunc // multiplication of the rise and decay exponentials // decay is sum of 3 exp
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = (1-exp(-(x-X0)/TR1))^N·(A1·exp(-(x-X0)/TD1)+A2·exp(-(x-X0)/TD2)+A3·exp(-(x-X0)/TD3))
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 9
	//CurveFitDialog/ w[0] = X0
	//CurveFitDialog/ w[1] = TR1
	//CurveFitDialog/ w[2] = N
	//CurveFitDialog/ w[3] = A1
	//CurveFitDialog/ w[4] = TD1
	//CurveFitDialog/ w[5] = A2
	//CurveFitDialog/ w[6] = TD2
	//CurveFitDialog/ w[7] = A3
	//CurveFitDialog/ w[8] = TD3
	
	Variable scale = NMFitVarGet( "SynExpSign" )
	Variable e1, e2, e3, e4
	
	if( x < w[0] )
		return 0
	endif
	
	switch( scale )
		case 1:
		case -1:
			break
		default:
			scale = 1
	endswitch
	
	w[3] = scale * abs( w[3] )
	w[5] = scale * abs( w[5] )
	w[7] = scale * abs( w[7] )
	
	e1 = ( 1 - exp( -( x - w[0] ) / w[1] ) ) ^ w[2]
	e2 = w[3] * exp( -( x - w[0] ) / w[4] )
	e3 = w[5] * exp( -( x - w[0] ) / w[6] )
	e4 = w[7] * exp( -( x - w[0] ) / w[8] )
	
	return e1 * ( e2 + e3 + e4 )
	
End // NMSynExp4

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSynExpSum6( w,x ) : FitFunc // sum of the rise and decay exponentials // 3 rise and 3 decay exp
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = A1·norm[exp(-(x-X0)/TD1)-exp(-(x-X0)/TR)] + A2·norm[exp(-(x-X0)/TD2)-exp(-(x-X0)/TR)] + A3·norm[exp(-(x-X0)/TD3)-exp(-(x-X0)/TR)]
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 8
	//CurveFitDialog/ w[0] = X0
	//CurveFitDialog/ w[1] = A1
	//CurveFitDialog/ w[2] = TR // all share the same TR
	//CurveFitDialog/ w[3] = TD1
	//CurveFitDialog/ w[4] = A2
	//CurveFitDialog/ w[5] = TD2
	//CurveFitDialog/ w[6] = A3
	//CurveFitDialog/ w[7] = TD3
	
	Variable s1, s2, s3
	
	if ( x < w[0] )
		return 0
	endif
	
	Variable tpeak1 = w[0] + ( ( w[3] * w[2] ) / ( w[3] - w[2] ) ) * ln( w[3] / w[2] )
			
	Variable normFactor1 = ( exp( -( tpeak1 - w[0] ) / w[3] ) - exp( -( tpeak1 - w[0] ) / w[2] ) )
	
	Variable tpeak2 = w[0] + ( ( w[5] * w[2] ) / ( w[5] - w[2] ) ) * ln( w[5] / w[2] )
			
	Variable normFactor2 = ( exp( -( tpeak2 - w[0] ) / w[5] ) - exp( -( tpeak2 - w[0] ) / w[2] ) )
	
	Variable tpeak3 = w[0] + ( ( w[7] * w[2] ) / ( w[7] - w[2] ) ) * ln( w[7] / w[2] )
			
	Variable normFactor3 = ( exp( -( tpeak3 - w[0] ) / w[7] ) - exp( -( tpeak3 - w[0] ) / w[2] ) )
	
	s1 = w[1] * ( ( exp( -( x - w[0] ) / w[3] ) - exp( -( x - w[0] ) / w[2] ) ) ) / normFactor1
	s2 = w[4] * ( ( exp( -( x - w[0] ) / w[5] ) - exp( -( x - w[0] ) / w[2] ) ) ) / normFactor2
	s3 = w[6] * ( ( exp( -( x - w[0] ) / w[7] ) - exp( -( x - w[0] ) / w[2] ) ) ) / normFactor3
		
	return s1 + s2 + s3
	
End // NMSynExpSum6

//****************************************************************
//****************************************************************
//****************************************************************

Function NM_MPFA1( w, x ) : FitFunc
	Wave w
	Variable x
	
	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the Function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = (Q·x-x^2/N)·(1+CV2^2) + Q·x·CV1^2
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 4
	//CurveFitDialog/ w[0] = Q
	//CurveFitDialog/ w[1] = N
	//CurveFitDialog/ w[2] = CV1
	//CurveFitDialog/ w[3] = CV2
	
	w[1] = abs( w[1] )
	
	//if ( w[1] > 1 )
		//w[1] = round( w[1] )
	//endif
	
	return ( w[0] * x - ( x * x / w[1] ) ) * ( 1 + w[3] ^ 2 ) + w[0] * x * w[2] ^ 2
	
End // NM_MPFA1

//****************************************************************
//****************************************************************
//****************************************************************

Function NM_MPFA2( w, x ) : FitFunc
	Wave w
	Variable x
	
	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the Function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = (Q·x-x^2·Q·(1+alpha)/(x+Q·N·alpha))·(1+CV2^2) + Q·x·CV1^2
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 5
	//CurveFitDialog/ w[0] = Q
	//CurveFitDialog/ w[1] = N
	//CurveFitDialog/ w[2] = alpha
	//CurveFitDialog/ w[3] = CV1
	//CurveFitDialog/ w[4] = CV2
	
	Variable v1, v2
	
	//If ( w[0] <= 0 )
	//	w[0] = -w[0]/2 + 0.0001
	//endif
	
	//If ( w[2] < 0 )
	//	w[2] = -w[2]/2
	//endif
	
	v1 = w[0] * ( x ^ 2 ) * ( 1 + w[2] )
	v2 = x + w[0] * w[1] * w[2]
	
	return ( w[0] * x - ( v1 / v2 ) ) * ( 1 + w[4] ^ 2 ) + w[0] * x * w[3] ^ 2
	
End // NM_MPFA2

//****************************************************************
//****************************************************************
//****************************************************************
//
// NM_RCvstep( w, x )
//
// Data should be membrane current in response to a voltage-clamp step
// Units must be consistent, for example:
//		V (mV) = I * R = pA * GOhms = nA * MOhms
//		tau (ms) = R * C = GOhms * pF = MOhms * nF
// w[0] is vstep value // should "hold" during fit
// w[1] is vstep onset // should "hold" during fit
// w[2] is baseline current before vstep (x < Xstep)
// Rp - pipette/access resistance
// Rm - membrane resistance
// Req - equivalent resistance - RpRm/(Rp+Rm)
// Tau - decay time constant
//
// https://www.sciencedirect.com/topics/medicine-and-dentistry/voltage-clamp
//
// Istep = Vstep / Rp // for x = Xstep, Rm is short-circuited by Cm
// Iss = Vstep / ( Rp + Rm ) // at long time, Cm is open-circuit, so Rp and Rm are in series
// Istep = Iss + Iexp
// Tau = Req * Cm
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NM_RCvstep( w, x ) : FitFunc
	Wave w
	Variable x
	
	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = I0 + Iss + Iexp·exp(-(x-Xstep )/Tau )
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 6
	//CurveFitDialog/ w[0] = Vstep
	//CurveFitDialog/ w[1] = Xstep
	//CurveFitDialog/ w[2] = I0
	//CurveFitDialog/ w[3] = Rp
	//CurveFitDialog/ w[4] = Rm
	//CurveFitDialog/ w[5] = Cm
	
	Variable Istep = w[0] / w[3]
	Variable Iss = w[0] / ( w[3] + w[ 4] )
	Variable Iexp = Istep - Iss
	Variable Req = 1 / ( ( 1 / w[3] ) + ( 1 / w[4] ) ) 
	Variable Tau = w[5] * Req
	
	if ( x < w[1] )
		return w[2] // I0
	else
		return w[2] + Iss + Iexp * exp( -( x - w[1] ) / Tau ) // Itotal
	endif
	
End // NM_RCvstep

//****************************************************************
//****************************************************************
//****************************************************************

Function NMAxelrodFrapDiffusion( w,x ) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = FRAP
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 4
	//CurveFitDialog/ w[0] = Kvalue
	//CurveFitDialog/ w[1] = w
	//CurveFitDialog/ w[2] = D
	//CurveFitDialog/ w[3] = Finf
	
	Variable icnt, y0, yvalue = 0
	Variable iLimit = 19 // n = 20
	
	Variable TauD = w[1] * w[1] / ( 4 * w[2] )
	
	for ( icnt = 0 ; icnt <= iLimit ; icnt += 1 )
		yvalue += ( ( ( -1 * w[0] ) ^ icnt ) / factorial( icnt ) ) / ( 1 + icnt * ( 1 + 2 * x / TauD  ) )
	endfor
	
	y0 = ( 1 - exp( -w[0] ) ) / w[0]
	
	yvalue = ( w[3] - y0 ) * ( yvalue - y0 ) / ( 1 - y0 ) + y0 // normalize to include Finf
	
	return yvalue
	
End // NMAxelrodFrapDiffusion

//****************************************************************
//****************************************************************
//****************************************************************

Function NMAxelrodFrapDiffusionPR( w,x ) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = FRAP
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 4
	//CurveFitDialog/ w[0] = Kvalue
	//CurveFitDialog/ w[1] = w
	//CurveFitDialog/ w[2] = D
	//CurveFitDialog/ w[3] = Finf
	
	Variable icnt, yvalue = 0
	Variable iLimit = 19 // n = 20
	
	Variable y0 = ( 1 - exp( -w[0] ) ) / w[0]
	
	Variable TauD = w[1] * w[1] / ( 4 * w[2] )
	
	for ( icnt = 0 ; icnt <= iLimit ; icnt += 1 )
		yvalue += ( ( ( -1 * w[0] ) ^ icnt ) / factorial( icnt ) ) / ( 1 + icnt * ( 1 + 2 * x / TauD  ) )
	endfor
	
	yvalue = w[3] * ( yvalue - y0 ) / ( 1 - y0 ) // percent recovered after bleaching
	
	return yvalue
	
End // NMAxelrodFrapDiffusionPR

//****************************************************************
//****************************************************************
//****************************************************************

Function NMAxelrodFrapFlow( w,x ) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = FRAP
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 4
	//CurveFitDialog/ w[0] = Kvalue
	//CurveFitDialog/ w[1] = w
	//CurveFitDialog/ w[2] = V
	//CurveFitDialog/ w[3] = Finf
	
	Variable icnt, y0, yinf, yvalue = 0
	Variable iLimit = 19 // n = 20
	
	Variable TauF = w[1] / w[2]
	
	for ( icnt = 0 ; icnt <= iLimit ; icnt += 1 )
		yvalue += ( ( ( -1 * w[0] ) ^ icnt ) / factorial( icnt + 1 ) ) * exp( ( ( -2 * icnt ) / ( icnt + 1 ) ) * ( x / TauF ) ^ 2 )
	endfor
	
	y0 = ( 1 - exp( -w[0] ) ) / w[0]
	yvalue = ( w[3] - y0 ) * ( yvalue - y0 ) / ( 1 - y0 ) + y0
	
	return yvalue
	
End // NMAxelrodFrapFlow

//****************************************************************
//****************************************************************
//****************************************************************

Function NM_IV( w,x ) : FitFunc // linear IV
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = G·(x-Vrev)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 2
	//CurveFitDialog/ w[0] = G
	//CurveFitDialog/ w[1] = Vrev
	
	return w[0] * ( x - w[1] )
	
End // NM_IV

//****************************************************************
//****************************************************************
//****************************************************************

Function NM_IV_Boltzmann( w,x ) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = G·(x-Vrev)·Boltzmann(x)^N
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 5
	//CurveFitDialog/ w[0] = G
	//CurveFitDialog/ w[1] = Vrev
	//CurveFitDialog/ w[2] = Vhalf
	//CurveFitDialog/ w[3] = Vslope
	//CurveFitDialog/ w[4] = N
	
	Variable Boltzmann = 1 / ( 1 + exp( -( x - w[2] ) / w[3] ) )
	
	return w[0] * ( x - w[1] ) * Boltzmann ^ w[4]
	
End // NM_IV_Boltzmann

//****************************************************************
//****************************************************************
//****************************************************************
//
// NM_IV_GHK( w,x )
//
// https://en.wikipedia.org/wiki/Goldman%E2%80%93Hodgkin%E2%80%93Katz_flux_equation
//
// I = P·zF(zFV/RT)·(Si - So·exp(-zFV/RT))/(1 - exp(-zFV/RT))		GHK
//
// Vzt = RT/zF		(volts)
// U = P·zF(V/Vzt)
//
// I = U·(Si - So·exp(-V/Vzt))/(1 - exp(-V/Vzt))
//
// Si = So·exp(-Vrev/Vzt)
// Vrev = -(RT/zF)·ln(Si/So)
// Vrev = Vzt·ln(So/Si)		Nernst Potential
//
// flux = U·(So·exp(-Vrev/Vzt) - So·exp(-V/Vzt)) / (1 - exp(-V/Vzt)) // substitute in Nernst
// flux = U·So·(exp(-Vrev/Vzt) - exp(-V/Vzt)) / (1 - exp(-V/Vzt))
// flux = U·So·(exp(V/Vzt)·exp(-Vrev/Vzt) - 1) / (exp(V/Vzt) - 1)
// flux = U·So·(exp(V/Vzt - Vrev/Vzt) - 1) / (exp(V/Vzt) - 1)
// flux = U·So·(exp((V - Vrev)/Vzt) - 1) / (exp(V/Vzt) - 1)
// flux = G·V·(exp((V - Vrev)/Vzt) - 1) / (exp(V/Vzt) - 1)
// G = P·zF·So/Vzt

// Fitmaster format:
// flux = G·V·(exp(-V/Vzt)exp(V/Vzt)exp(-Vrev/Vzt) - exp(-V/Vzt)) / ( exp(-V/Vzt)exp(V/Vzt) - exp(-V/Vzt) )
// flux = G·V·(exp(-Vrev/Vzt) - exp(-V/Vzt)) / ( 1 - exp(-V/Vzt) )
// flux = G·V·exp(-Vrev/Vzt)(1 - exp(Vrev/Vzt)exp(-V/Vzt)) / ( 1 - exp(-V/Vzt) )
// flux = G·V·exp(-Vrev/Vzt)(1 - exp((Vrev-V)/Vzt) / ( 1 - exp(-V/Vzt) )
// flux = G·V·exp(-Vrev/Vzt)(1 - exp(-(V-Vrev)/Vzt) / ( 1 - exp(-V/Vzt) )
//
// G' = G·exp(-Vrev/Vzt)		
// G = G'·exp(Vrev/Vzt)			difference in G by scale factor = exp(Vrev/Vzt)
//
// flux = G'·V·(1 - exp(-(V-Vrev)/Vzt) / ( 1 - exp(-V/Vzt) ) // USED IN FIT FXN
//
// G = P·zF·So/Vzt
// (m·s−1)(C·mol−1)(mol·m−3)/V = C·s−1·m−2/V = (A/V)·m−2 = S·m−2
//
//	Units
// I : A·m−2
// P : permeability : m·s−1
// G : S·m−2
// F : Faraday : C·mol−1
// V, Vzt : volts
//	T : Kelvin
// Si, So : mM : mol·m−3
//
// If units of data are A·m−2 and mV:
//
// G : A·m−2/mV = kS·m−2
//
// By default this fit function is configured to work with x-scale units of mV.
// To change to volts, use NM Fit tab config variable GHK_Xunits.
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NM_IV_GHK( w,x ) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = G·GHK(x)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 4
	//CurveFitDialog/ w[0] = G
	//CurveFitDialog/ w[1] = Vrev
	//CurveFitDialog/ w[2] = Temp
	//CurveFitDialog/ w[3] = z
	
	Variable xv, xscale
	
	String xunits = StrVarOrDefault( NMFitDF + "GHK_Xunits", GHK_Xunits )
	
	strswitch( xunits )
		case "V":
		case "volts":
			xscale = 1 // GHK equation has x-scale units of volts
			break
		case "mV":
		case "millivolts":
			xscale = 1000
			break
		default:
			return NaN // error, unknown x-scale
	endswitch
	
	if ( x == 0 )
		xv = 1e-8 // discontinuity at x = 0, so use small value instead
	else
		xv = x
	endif
	
	Variable Vzt = xscale * NMGasConstant * ( w[2] + 273.15 ) / ( w[3] * NMFaradayConstant )
	
	//Variable GHK =  xv * ( exp( ( xv - w[1] ) / Vzt ) - 1 ) / ( exp( xv / Vzt ) - 1 )
	// **** Singular matrix error during curve fitting ****
	// There may be no dependence on these parameters: W_coef[1]
	
	Variable sf = 1 // this works, but G will be scaled by exp(-Vrev/Vzt)
	//Variable sf = exp( -w[1] / Vzt ) // no stable solution for Vrev
	Variable GHK =  xv * sf * ( 1 - exp( -( xv - w[1] ) / Vzt ) ) / ( 1 - exp( -xv / Vzt ) )
	
	return w[0] * GHK
	
End // NM_IV_GHK

//****************************************************************
//****************************************************************
//****************************************************************

Function NM_IV_GHK_Boltzmann( w,x ) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = G·GHK(x)·Boltzmann(x)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 7
	//CurveFitDialog/ w[0] = G
	//CurveFitDialog/ w[1] = Vrev
	//CurveFitDialog/ w[2] = Temp
	//CurveFitDialog/ w[3] = z
	//CurveFitDialog/ w[4] = Vhalf
	//CurveFitDialog/ w[5] = Vslope
	//CurveFitDialog/ w[6] = N
	
	Variable xv, xscale
	
	String xunits = StrVarOrDefault( NMFitDF + "GHK_Xunits", GHK_Xunits )
	
	strswitch( xunits )
		case "V":
		case "volts":
			xscale = 1 // GHK equation has x-scale units of volts
			break
		case "mV":
		case "millivolts":
			xscale = 1000
			break
		default:
			return NaN // error, unknown x-scale
	endswitch
	
	if ( x == 0 )
		xv = 1e-8 // discontinuity at x = 0, so use small value instead
	else
		xv = x
	endif
	
	Variable Vzt = xscale * NMGasConstant * ( w[2] + 273.15 ) / ( w[3] * NMFaradayConstant )
	
	//Variable GHK =  xv * ( exp( ( xv - w[1] ) / Vzt ) - 1 ) / ( exp( xv / Vzt ) - 1 )
	// **** Singular matrix error during curve fitting ****
	// There may be no dependence on these parameters: W_coef[1]
	
	Variable sf = 1 // this works, but G will be scaled by exp(-Vrev/Vzt)
	//Variable sf = exp( -w[1] / Vzt ) // no stable solution for Vrev
	Variable GHK =  xv * sf * ( 1 - exp( -( xv - w[1] ) / Vzt ) ) / ( 1 - exp( -xv / Vzt ) )
	
	Variable Boltzmann = 1 / ( 1 + exp( -( xv - w[4] ) / w[5] ) )
	
	//w[7] = w[0] * exp( w[1] / Vzt ) // Gactual, not used in equation
	
	return w[0] * GHK * Boltzmann ^ w[6]
	
End // NM_IV_GHK_Boltzmann

//****************************************************************
//****************************************************************
//****************************************************************

Function NMCircle( w,x ) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = SQRT(R^2 - (x * dx)^2)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 3
	//CurveFitDialog/ w[0] = x0
	//CurveFitDialog/ w[1] = dx
	//CurveFitDialog/ w[2] = R
	
	// R^2 = x^2 + y^2
	// y = sqrt(R^2 - x^2)
	
	
	if ( numtype( x ) > 0  )
		return 0
	endif
	
	Variable xvalue = x * w[1] - w[0] // x: 0, 1, 2, 3...
	
	return sqrt(w[2]^2 - xvalue^2)

End // NMCircle

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEllipse( w,x ) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = SQRT(R^2 - (x*dx/E)^2)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 4
	//CurveFitDialog/ w[0] = x0
	//CurveFitDialog/ w[1] = dx
	//CurveFitDialog/ w[2] = R
	//CurveFitDialog/ w[3] = E
	
	// 1 = (x/Rx)^2 + (y/Ry)^2
	// 1 = (x/ERy)^2 + (y/(Ry))^2
	// 1 = (x/ER)^2 + (y/R)^2
	// R^2 = (x/E)^2 + y^2
	//	y^2 = R^2 - (x/E)^2
	// y = sqrt(R^2 - (x/E)^2)
	
	if ( numtype( x ) > 0  )
		return 0
	endif
	
	Variable xvalue = x * w[1] - w[0] // x: 0, 1, 2, 3...
	
	return sqrt(w[2]^2 - (xvalue/w[3])^2)

End // NMEllipse

//****************************************************************
//****************************************************************
//****************************************************************

Function NMKeidingExecute( wName, paramWaveName, select )
	String wName, paramWaveName, select
	
	if ( exists("NMKeidingCompute") == 6 )
		Execute /Q/Z "NMKeidingCompute(" + NMQuotes( wName ) + "," + NMQuotes( paramWaveName ) + "," + NMQuotes( select ) + ")"
	endif
	
End // NMKeidingExecute

//****************************************************************
//****************************************************************
//****************************************************************


		

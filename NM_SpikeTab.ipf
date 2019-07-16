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
//	Spike Analysis
//
//	Compute spike rasters, PST histograms, interspike interval histograms, avg rates
//
//	Set and Get functions:
//
//		NMSpikeSet( [ threshold, xbgn, xend, review, rasterSelect ] )
//		NMConfigVarSet( "Spike", varName, value )
//		NMConfigStrSet( "Spike", strVarName, strValue )
//		NMSpikeVarGet( varName )
//		NMSpikeStrGet( strVarName )
//
//	Useful functions:
//	
//		NMSpikeRasterComputeAll( [ chanSelectList, waveSelectList, displayMode, delay, plot, table, history ] )
//		NMSpikeRasterCompute( [ chanNum, waveNum, threshold, xbgn, xend, xRaster, yRaster, displayMode, delay ] )
//		NMSpikeRasterPlot( [ folder, xRasterList, yRasterList, xbgn, xend, history ] )
//		NMSpikeTable( [ subfolder, history ] )
//		NMSpikePSTH( [ folder, xRasterList, yRasterList, xbgn, xend, binSize, yUnits, noGraph, history ] )
//		NMSpikePSTHJoint( [ folder, xRasterList, yRasterList, xbgn, xend, binSize, yUnits, noGraph, history ] )
//		NMSpikeISIH( [ folder, xRasterList, xbgn, xend, minInterval, maxInterval, binSize, yUnits, noGraph, history ] )
//		NMSpikeISIHJoint( [ folder, xRasterList, xbgn, xend, minInterval, maxInterval, binSize, yUnits, noGraph, history ] )
//		NMSpikeRate( [ folder, xRasterList, yRasterList, xbgn, xend, noGraph, history ] )
//		NMSpikesToWaves( [ folder, xRaster, yRaster, xwinBefore, xwinAfter, stopAtNextSpike, chanNum, wavePrefix, history ] )
//
//****************************************************************
//****************************************************************
//
//	Default Values
//
//****************************************************************
//****************************************************************
//****************************************************************

Static Constant Threshold = 10 // arbitrary units
Static Constant UseSubfolders = 1 // ( 0 ) no ( 1 ) yes
Static Constant OverwriteMode = 1 // ( 0 ) no ( 1 ) yes
Static Constant AutoSpike = 1 // ( 0 ) no ( 1 ) yes, auto spike detection after wave change
Static Constant AutoRaster = 1 // create raster plot after executing All Waves ( 0 ) no ( 1 ) yes
Static Constant AutoTable = 0 // create raster table after executing All Waves ( 0 ) no ( 1 ) yes
Static Constant ReviewAlert1 = 1 // ( 0 ) no ( 1 ) yes
Static Constant ReviewAlert2 = 1 // ( 0 ) no ( 1 ) yes
Static Constant PositiveSpikes = 1 // ( 0 ) negative ( 1 ) positive spike deflections
Static Constant RasterNaNs = 1 // ( 0 ) no NaNs ( 1 ) use NaNs
Static Constant DisplaySpikesLimit = 2000 // limit for display spikes (displaying 1000s of spikes can be slow)

Static StrConstant WaveNamingFormat = "prefix" // "prefix" or "suffix"

//****************************************************************
//****************************************************************
//****************************************************************

Static StrConstant SELECTED = "_selected_"

StrConstant NMSpikeDF = "root:Packages:NeuroMatic:Spike:"

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMTabPrefix_Spike()

	return "SP_"

End // NMTabPrefix_Spike

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeTab( enable )
	Variable enable // ( 0 ) disable ( 1 ) enable tab
	
	if ( enable )
		CheckNMPackage( "Spike", 1 ) // declare globals if necessary
		CheckNMSpikeThresh()
		CheckNMSpikeWindows()
		NMSpikeMake( 0 ) // make controls if necessary
		NMSpikeUpdate()
		NMChannelGraphDisable( channel = -2, all = 0 )
	endif
	
	NMSpikeDisplay( -1, enable )
	
	if ( enable )
		NMSpikeAuto()
	endif

End // SpikeTab

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeTabKill( what )
	String what
	
	strswitch( what )
	
		case "waves":
			return 0
			
		case "folder":
		
			if ( DataFolderExists( NMSpikeDF ) )
			
				KillDataFolder $NMSpikeDF
				
				if ( DataFolderExists( NMSpikeDF ) )
					return -1
				else
					return 0
				endif
				
			endif
			
	endswitch
	
	return -1

End // SpikeTabKill

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeCheck()
	
	if ( !DataFolderExists( NMSpikeDF ) )
		return NM2Error( 30, "SpikeDF", NMSpikeDF )
	endif

	CheckNMwave( NMSpikeDF + "SP_SpikeX", 0, NaN ) // waves for display graphs
	CheckNMwave( NMSpikeDF + "SP_SpikeY", 0, NaN )
	
	return 0
	
End // NMSpikeCheck

//****************************************************************
//****************************************************************
//****************************************************************

Static Function zCheck_NMSpikeVar( varName )
	String varName
	
	return CheckNMvar( NMSpikeDF+varName, NMSpikeVarGet( varName ) )

End // zCheck_NMSpikeVar

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeConfigs()

	NMConfigVar( "Spike", "UseSubfolders", UseSubfolders, "use subfolders when creating Spike waves ( uncheck for previous NM formatting )", "boolean" )
	NMConfigVar( "Spike", "OverwriteMode", OverwriteMode, "overwrite existing waves, tables and graphs if their is a name conflict", "boolean" )
	NMConfigVar( "Spike", "AutoSpike", AutoSpike, "auto spike detection after wave change", "boolean" )
	NMConfigVar( "Spike", "AutoRaster", AutoRaster, "create raster plot after executing All Waves", "boolean" )
	NMConfigVar( "Spike", "AutoTable", AutoTable, "create raster table after executing All Waves", "boolean" )
	NMConfigVar( "Spike", "ReviewAlert1", ReviewAlert1, "alert user once about Review checkbox when selecting All Waves", "boolean" )
	NMConfigVar( "Spike", "ReviewAlert2", ReviewAlert2, "alert user once how to use Review square marquee", "boolean" )
	NMConfigVar( "Spike", "PositiveSpikes", PositiveSpikes, "detect spikes on positive deflections (uncheck for negative deflections)", "boolean" )
	NMConfigVar( "Spike", "RasterNaNs", RasterNaNs, "use NaNs to seperate wave # results in raster waves", "boolean" )
	NMConfigVar( "Spike", "DisplaySpikesLimit", DisplaySpikesLimit, "upper limit for display spike times on channel graphs", "" )
	
	NMConfigStr( "Spike", "WaveNamingFormat", WaveNamingFormat, "attach new wave identifier as \"prefix\" or \"suffix\" ( use \"suffix\" for previous NM formatting )", "prefix;suffix;" )
	
End // NMSpikeConfigs

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeVarGet( varName )
	String varName
	
	Variable defaultVal = NaN
	
	strswitch( varName )
	
		case "UseSubfolders":
			defaultVal = UseSubfolders
			break
			
		case "OverwriteMode":
			defaultVal = OverwriteMode
			break
			
		case "AutoSpike":
			defaultVal = AutoSpike
			break
			
		case "AutoRaster":
			defaultVal = AutoRaster
			break
			
		case "AutoTable":
			defaultVal = AutoTable
			break
			
		case "Thresh":
			defaultVal = Threshold
			break
			
		case "Xbgn":
			defaultVal = -inf
			break
			
		case "Xend":
			defaultVal = inf
			break
			
		case "PositiveSpikes":
			defaultVal = PositiveSpikes
			break
			
		case "RasterNaNs":
			defaultVal = RasterNaNs
			break
			
		case "DisplaySpikesLimit":
			defaultVal = 2000
			break
			
		case "ChanSelect":
			defaultVal = 0
			break
			
		case "Spikes":
			defaultVal = 0
			break
			
		case "Rate":
			defaultVal = 0
			break
			
		case "NumSpikes":
			defaultVal = 0
			break
			
		case "Review":
			return NMSpikeReviewGet()
			
		case "ReviewAlert1":
			defaultVal = ReviewAlert1
			break
			
		case "ReviewAlert2":
			defaultVal = ReviewAlert2
			break
			
		case "ComputeAllDisplay":
			defaultVal = 1
			break
			
		case "ComputeAllDelay":
			defaultVal = 0
			break
			
		case "ComputeAllFormat":
			defaultVal = 0
			break
			
		case "ComputeAllPlot":
			defaultVal = 1
			break
			
		case "ComputeAllTable":
			defaultVal = 0
			break
			
		case "PSTHdelta":
			defaultVal = 1
			break
			
		case "ISIHdelta":
			defaultVal = 1
			break
			
		case "S2W_XwinBefore":
			defaultVal = 2
			break
			
		case "S2W_XwinAfter":
			defaultVal = 5
			break
			
		case "S2W_StopAtNextSpike":
			defaultVal = 0
			break
			
		case "S2W_chan":
			defaultVal = CurrentNMChannel()
			break
			
		case "S2W_SelectAsCurrent":
			defaultVal = 1
			break
			
		case "S2W_SetGroups":
			defaultVal = 0
			break
			
		default:
			NMDoAlert ( "NMSpikeVar Error: no variable called " + NMQuotes( varName ) )
			return NaN
	
	endswitch
	
	return NumVarOrDefault( NMSpikeDF+varName, defaultVal )
	
End // NMSpikeVarGet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeStrGet( strVarName )
	String strVarName
	
	String defaultStr = ""
	
	strswitch( strVarName )
	
		case "WaveNamingFormat":
			defaultStr = WaveNamingFormat
			break
			
		case "PSTHyaxis":
			defaultStr = "Spikes/bin"
			break
			
		case "ISIHyaxis":
			defaultStr = "Intervals/bin"
			break
			
		case "S2W_WavePrefix":
			//defaultStr = "SP_Rstr"
			defaultStr = "Spike"
			break
			
		default:
			NMDoAlert( "NMSpikeStr Error: no variable called " + NMQuotes( strVarName ) )
			return ""
	
	endswitch
	
	return StrVarOrDefault( NMSpikeDF + strVarName, defaultStr )
			
End // NMSpikeStrGet

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMSpikeThresh()
	
	Variable minThresh = 5
	
	String wname = ChanDisplayWave( -1 )
	
	Variable thresh = NMSpikeVarGet( "Thresh" )
	
	if ( ( numtype( thresh ) == 0 ) || !WaveExists( $wname ) )
		return 0
	endif
	
	WaveStats /Q/Z $wname
	
	thresh = ( V_max - 0.2*abs( V_max - V_avg ) )
	thresh = ceil( 10 * thresh ) / 10
	
	if ( V_avg < minThresh )
		thresh = max( thresh, minThresh )
	endif
	
	SetNMvar( NMSpikeDF + "Thresh", thresh )
	
	return 0
	
End // CheckNMSpikeThresh

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMSpikeWindows()

	if ( numtype( NMSpikeVarGet( "Xbgn" ) ) > 0 )
		SetNMvar( NMSpikeDF + "Xbgn", -inf )
	endif
	
	if ( numtype( NMSpikeVarGet( "Xend" ) ) > 0 )
		SetNMvar( NMSpikeDF + "Xend", inf )
	endif

End // CheckNMSpikeWindows

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeReviewGet()

	String xWaveOrFolder

	Variable review = NumVarOrDefault( NMSpikeDF + "Review", 0 )
	
	if ( review )
	
		xWaveOrFolder = CurrentNMSpikeRasterXSelect()
		
		if ( strlen( xWaveOrFolder ) > 0 )
			return 1
		endif
	
	endif

	return 0
	
End // NMSpikeReviewGet

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Channel Graph Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeDisplay( chanNum, appnd ) // append/remove spike wave from channel graph
	Variable chanNum // channel number ( -1 ) for current channel
	Variable appnd // ( 0 ) remove wave ( 1 ) append wave
	
	Variable ccnt, drag = appnd
	String gName
	
	if ( !DataFolderExists( NMSpikeDF ) )
		return 0 // spike has not been initialized yet
	endif
	
	if ( !NMVarGet( "DragOn" ) || !StringMatch( CurrentNMTabName(), "Spike" ) )
		drag = 0
	endif 
	
	if ( !appnd )
		SetNMwave( NMSpikeDF+"SP_SpikeX", -1, NaN )
		SetNMwave( NMSpikeDF+"SP_SpikeY", -1, NaN )
	endif
	
	chanNum = ChanNumCheck( chanNum )
	
	for ( ccnt = 0 ; ccnt < NMNumChannels() ; ccnt += 1 )
	
		gName = ChanGraphName( ccnt )
	
		if ( Wintype( gName ) == 0 )
			continue // window does not exist
		endif
	
		RemoveFromGraph /Z/W=$gName SP_SpikeY
		RemoveFromGraph /Z/W=$gName DragBgnY, DragEndY
		
	endfor
	
	gName = ChanGraphName( chanNum )
	
	if ( appnd && ( WinType( gName ) == 1 ) )
		AppendToGraph /W=$gName $NMSpikeDF+"SP_SpikeY" vs $NMSpikeDF+ "SP_SpikeX"
		ModifyGraph /W=$gName mode( SP_SpikeY )=3, marker( SP_SpikeY )=9
		ModifyGraph /W=$gName mrkThick( SP_SpikeY )=2, rgb( SP_SpikeY )=( 65535,0,0 )
	endif
	
	NMSpikeDisplayUpdate()
	
	NMDragEnable( drag, "DragBgn", "", NMSpikeDF+"Xbgn", "", gName, "bottom", "min", 65535, 0, 0 )
	NMDragEnable( drag, "DragEnd", "", NMSpikeDF+"Xend", "", gName, "bottom", "max", 65535, 0, 0 )
	
	KillWaves /Z $NMDF + "DragTbgnX" // old waves
	KillWaves /Z $NMDF + "DragTbgnY"

End // NMSpikeDisplay

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeDisplayUpdate()

	Variable review = NMSpikeReviewGet()
	
	String gName = ChanGraphName( -1 )
	
	String wList
	
	if ( WinType( gName ) == 0 )
		return 0
	endif
	
	wList = TraceNameList( gName, ";", 1 )
	
	if ( WhichListItem( "SP_SpikeY", wList ) < 0 )
		return 0
	endif
	
	if ( review )
		ModifyGraph /W=$gName rgb(SP_SpikeY)=(0,0,65280)
	else
		ModifyGraph /W=$gName rgb(SP_SpikeY)=(65280,0,0)
	endif

End // NMSpikeDisplayUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeDisplayClear()

	SetNMwave( NMSpikeDF+"SP_SpikeX", -1, NaN )
	SetNMwave( NMSpikeDF+"SP_SpikeY", -1, NaN )
	
	NMDragClear( "DragBgn" )
	NMDragClear( "DragEnd" )

End // NMSpikeDisplayClear

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Tab Controls Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeMake( force ) // create Spike tab controls
	Variable force

	Variable x0 = 40, y0 = 195, xinc = 120, yinc = 35, fs = NMPanelFsize
	
	y0 = NMPanelTabY + 40
	
	ControlInfo /W=$NMPanelName SP_Thresh
	
	if ( ( V_Flag != 0 ) && !force )
		return 0 // Spike tab has already been created, return here
	endif
	
	if ( !DataFolderExists( NMSpikeDF ) )
		return 0 // spike has not been initialized yet
	endif
	
	zCheck_NMSpikeVar( "Thresh" )
	zCheck_NMSpikeVar( "Xbgn" )
	zCheck_NMSpikeVar( "Xend" )
	zCheck_NMSpikeVar( "Spikes" )
	zCheck_NMSpikeVar( "Rate" )
	zCheck_NMSpikeVar( "NumSpikes" )
	
	DoWindow /F $NMPanelName
	
	GroupBox SP_Grp1, title = "Spike Detection", pos={20,y0}, size={260,150}, fsize=fs, win=$NMPanelName
	
	xinc = 145
	yinc = 26
	
	SetVariable SP_Thresh, title="threshold", pos={x0,y0+1*yinc}, limits={-inf,inf,0}, size={130,20}, frame=1, value=$( NMSpikeDF+"Thresh" ), proc=NMSpikeSetVariable, fsize=fs, win=$NMPanelName
	
	SetVariable SP_Xbgn, title="xbgn", pos={x0,y0+2*yinc}, limits={-inf,inf,0}, size={130,20}, frame=1, value=$( NMSpikeDF+"Xbgn" ), proc=NMSpikeSetVariable, fsize=fs, win=$NMPanelName
	SetVariable SP_Xend, title="xend", pos={x0,y0+3*yinc}, limits={-inf,inf,0}, size={130,20}, frame=1, value=$( NMSpikeDF+"Xend" ), proc=NMSpikeSetVariable, fsize=fs, win=$NMPanelName
	
	Checkbox SP_Auto, title="auto", pos={x0+xinc,y0+1*yinc+1}, size={16,18}, value=NumVarOrDefault( NMSpikeDF+"AutoSpike", 0 ) , proc = NMSpikeCheckBox, win=$NMPanelName
	
	SetVariable SP_Count, title="spikes : ", pos={x0+xinc,y0+2*yinc}, limits={0,inf,0}, size={90,20}, frame=0, value=$( NMSpikeDF+"Spikes" ), fsize=fs, win=$NMPanelName
	SetVariable SP_WRate, title="rate : ", pos={x0+xinc,y0+3*yinc}, limits={0,inf,0}, size={90,20}, frame=0, value=$( NMSpikeDF+"Rate" ), fsize=fs, win=$NMPanelName
	
	yinc = 35
	
	y0 += 10
	
	Button SP_All, title = "All Waves", pos={x0+30,y0+3*yinc}, size={100,20}, proc = NMSpikeButton, fsize=fs, win=$NMPanelName
	
	Checkbox SP_Review, title="review", pos={x0+40+105,y0+3*yinc+3}, size={16,18}, value=0, proc = NMSpikeCheckBox, win=$NMPanelName
	
	y0 = 380
	yinc = 30
	
	GroupBox SP_Grp2, title = "Spike Analysis", pos={20,y0}, size={260,215}, fsize=fs, win=$NMPanelName
	
	PopupMenu SP_RasterSelect, pos={x0+120,y0+1*yinc}, bodywidth=170, fsize=fs, win=$NMPanelName
	PopupMenu SP_RasterSelect, value="Spike Raster Select", proc=NMSpikePopup
	
	SetVariable SP_NumSpikes, title=":", pos={x0+180,y0+1*yinc+2}, limits={0,inf,0}, size={55,20}
	SetVariable SP_NumSpikes, value=$( NMSpikeDF+"NumSpikes" ), frame=0, fsize=fs, noedit=0
	
	xinc = 120
	yinc = 35
	
	Button SP_Raster, title="Raster Plot", pos={x0,y0+2*yinc}, size={100,20}, proc=NMSpikeAnalysisButton, fsize=fs, win=$NMPanelName
	Button SP_Table, title = "Table", pos={x0+xinc,y0+2*yinc}, size={100,20}, proc = NMSpikeAnalysisButton, fsize=fs, win=$NMPanelName
	Button SP_PSTH, title="PST Histo", pos={x0,y0+3*yinc}, size={100,20}, proc=NMSpikeAnalysisButton, fsize=fs, win=$NMPanelName
	Button SP_Rate, title="Count / Rate", pos={x0+xinc,y0+3*yinc}, size={100,20}, proc=NMSpikeAnalysisButton, fsize=fs, win=$NMPanelName
	Button SP_ISIH, title="ISI Histo", pos={x0,y0+4*yinc}, size={100,20}, proc=NMSpikeAnalysisButton, fsize=fs, win=$NMPanelName
	Button SP_Joint, title="Joint", pos={x0+xinc,y0+4*yinc}, size={100,20}, proc=NMSpikeAnalysisButton, fsize=fs, win=$NMPanelName
	Button SP_2Waves, title="Spikes 2 Waves", pos={x0+xinc/2,y0+5*yinc}, size={100,20}, proc=NMSpikeAnalysisButton, fsize=fs, win=$NMPanelName
	
	return 0
	
End // NMSpikeMake

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeUpdate()

	Variable dis
	String txt
	
	String spikeMenu = NMSpikeRasterSelectMenu()
	String xWaveOrFolder = CurrentNMSpikeRasterOrFolder()
	
	String xRaster = CheckNMSpikeRasterXPath( SELECTED )
	
	Variable spikeCount = SpikeRasterCountSpikes( xRaster )
	
	Variable review = NMSpikeReviewGet()
	
	if ( NMVarGet( "ConfigsDisplay" ) > 0 )
		return 0
	endif
	
	SetNMvar( NMSpikeDF + "NumSpikes", spikeCount )
	
	Variable md = 1 + WhichListItem( xWaveOrFolder, SpikeMenu, ";", 0, 0 )
	
	if ( review )
		txt = "Spike Review"
	else
		txt = "Spike Detection"
	endif
	
	GroupBox SP_Grp1, win=$NMPanelName, title=txt

	PopupMenu SP_RasterSelect, win=$NMPanelName, mode=max(md,1), value=NMSpikeRasterSelectMenu()
	
	dis = 2
	
	if ( strlen( xWaveOrFolder ) > 0 )
		dis = 0
	endif
	
	if ( review )
		Checkbox SP_Review, win=$NMPanelName, disable=dis, value=review, fColor=(0,0,65280)
	else
		Checkbox SP_Review, win=$NMPanelName, disable=dis, value=review, fColor=(0,0,0)
	endif
	
	dis = 0
	
	if ( review )
		dis = 2
	endif
	
	SetVariable SP_Thresh, win=$NMPanelName, disable=dis
	//SetVariable SP_Xbgn, win=$NMPanelName, disable=dis
	//SetVariable SP_Xend, win=$NMPanelName, disable=dis
	
	Checkbox SP_Auto, win=$NMPanelName, value=NumVarOrDefault( NMSpikeDF+"AutoSpike", 0 ), disable=dis
	
	Button SP_All, win=$NMPanelName, disable=dis
	
	SetNMvar( NMSpikeDF + "ChanSelect", CurrentNMChannel() )
	
	NMSpikeDisplayUpdate()

End // NMSpikeUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeRasterSelectMenu()

	String menuStr = "Spike Raster Select;"
	String folderList = NMSubfolderList2( "", "Spike_", 0, 1 )
	String xWaveOrFolder = CurrentNMSpikeRasterOrFolder()
	
	String oldRasterList = SpikeRasterList()
	
	if ( ItemsInList( folderList ) > 0 )
		menuStr += "---;" + folderList
	endif
	
	if ( ItemsInList( oldRasterList ) > 0 )
		menuStr += "---;" + oldRasterList
	endif

	menuStr += "---;Other...;Clear;"
	
	if ( WhichListItem( xWaveOrFolder, folderList ) >= 0 )
		menuStr += "Delete Spike Subfolder;"
	endif
	
	return menuStr

End // NMSpikeRasterSelectMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeSetVariable( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	ctrlName = ReplaceString( "SP_", ctrlName, "" )
	
	NMSpikeCall( ctrlName, varStr )

End // NMSpikeSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikePopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	ctrlName = ReplaceString( "SP_", ctrlName, "" )
	
	String xWaveOrFolder = popStr
	
	strswitch( popStr )
	
		case "---":
			break
			
		case "Delete Spike Subfolder":
			NMSpikeAnalysisCall( popStr )
			break
			
		case "Clear":
			NMSpikeRasterClearCall()
			return 0
	
		case "Other...":
		
			xWaveOrFolder = zRasterSelectPrompt()
			
			if ( strlen( xWaveOrFolder ) == 0 )
				break
			endif
			
		default:
		
			if ( strlen( xWaveOrFolder ) > 0 )
				NMSpikeSet( raster = xWaveOrFolder, history = 1 )
			endif
	
	endswitch
	
	NMSpikeUpdate()
	
End // NMSpikePopup

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeButton( ctrlName ) : ButtonControl
	String ctrlName
	
	ctrlName = ReplaceString( "SP_", ctrlName, "" )
	
	NMSpikeCall( ctrlName, "" )
	
End // NMSpikeButton

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeAnalysisButton( ctrlName ) : ButtonControl
	String ctrlName
	
	ctrlName = ReplaceString( "SP_", ctrlName, "" )
	
	NMSpikeAnalysisCall( ctrlName )
	
End // NMSpikeAnalysisButton

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeCheckBox(ctrlName, checked) : CheckBoxControl
	String ctrlName; Variable checked
	
	ctrlName = ctrlName[ 3, inf ]
	
	NMSpikeCall( ctrlName, num2str( checked ) )

End // NMSpikeCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeCall( fxn, select )
	String fxn, select
	
	Variable snum = str2num( select )
	
	strswitch( fxn )
	
		case "Auto":
			NMSpikeSet( auto = snum, history = 1 )
			return ""
	
		case "Thresh":
			NMSpikeSet( threshold = snum, history = 1 )
			return ""
			
		case "Xbgn":
			NMSpikeSet( xbgn = snum, history = 1 )
			return ""
		
		case "Xend":
			NMSpikeSet( xend = snum, history = 1 )
			return ""
			
		case "All":
		case "All Waves":
			return NMSpikeRasterComputeAllCall()
			
		case "Review":
			NMSpikeSet( review = snum, history = 1 )
			return ""
			
		default:
			NMDoAlert( "NMSpikeCall: unrecognized function call: " + fxn )
			
	endswitch
	
	return ""
	
End // NMSpikeCall

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Global Variable Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeSet( [ threshold, xbgn, xend, auto, review, raster, update, history ] )
	Variable threshold // threshold trigger level
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	Variable auto // auto spike detection afer wave change ( 0 ) off ( 1 ) on
	Variable review // spike detection review mode ( 0 ) off ( 1 ) on
	String raster // spike raster select
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable autoSpike, updateTab
	String wName, path, subfolder, paramList = ""
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( !ParamIsDefault( auto ) )
	
		paramList = NMCmdNumOptional( "auto", auto, paramList )
	
		if ( numtype( auto ) > 0 )
			return NM2Error( 10, "auto", num2str( auto ) )
		endif
		
		NMConfigVarSet( "Spike", "AutoSpike", auto )
		autoSpike = auto
		
	endif
	
	if ( !ParamIsDefault( threshold ) )
	
		paramList = NMCmdNumOptional( "threshold", threshold, paramList )
	
		if ( numtype( threshold ) > 0 )
			return NM2Error( 10, "threshold", num2str( threshold ) )
		endif
		
		SetNMvar( NMSpikeDF + "Thresh", threshold )
		autoSpike = 1
		
	endif
	
	if ( !ParamIsDefault( xbgn ) )
	
		paramList = NMCmdNumOptional( "xbgn", xbgn, paramList )
	
		SetNMvar( NMSpikeDF + "Xbgn", zCheck_Xbgn( xbgn ) )
		autoSpike = 1
		
	endif
	
	if ( !ParamIsDefault( xend ) )
	
		paramList = NMCmdNumOptional( "xend", xend, paramList )
	
		SetNMvar( NMSpikeDF + "Xend", zCheck_Xend( xend ) )
		autoSpike = 1
		
	endif
	
	if ( !ParamIsDefault( review ) )
	
		paramList = NMCmdNumOptional( "review", review, paramList, integer = 1 )
	
		review = BinaryCheck( review )
	
		SetNMvar( NMSpikeDF + "Review", review )
	
		autoSpike = 1
		updateTab = 1
		
		if ( review )
			zReviewAlertUser2()
		endif
	
	endif
	
	if ( !ParamIsDefault( raster ) && ( strlen( raster ) > 0 ) )
	
		paramList = NMCmdStrOptional( "raster", raster, paramList )
	
		if ( !WaveExists( $raster ) && !DataFolderExists( raster ) )
			return NM2Error( 20, "raster", raster )
		endif
		
		subfolder = NMParent( raster, noPath = 1 )

		if ( ( strlen( subfolder ) > 0 ) && DataFolderExists( subfolder ) )
		
			wName = NMChild( raster )
			path = NMParent( raster )
			
			SetNMstr( path + "RasterXSelect", wName )
			
			raster = subfolder
			
		endif
		
		SetNMstr( CurrentNMPrefixFolder() + "SpikeRasterXSelect", raster )

		autoSpike = 1
		updateTab = 1
		
	endif
	
	if ( history )
		NMCommandHistory( paramList )
	endif
	
	if ( update && autoSpike )
		NMSpikeAuto()
	endif
	
	if ( update && updateTab )
		NMSpikeUpdate()
	endif
	
End // NMSpikeSet

//****************************************************************
//****************************************************************
//****************************************************************

Static Function zCheck_Xbgn( xbgn )
	Variable xbgn
	
	if ( numtype( xbgn ) > 0 )
		return -inf
	else
		return xbgn
	endif
	
End // zCheck_Xbgn

//****************************************************************
//****************************************************************
//****************************************************************

Static Function zCheck_Xend( xend )
	Variable xend
	
	if ( numtype( xend ) > 0 )
		return inf
	else
		return xend
	endif
	
End // zCheck_Xend

//****************************************************************
//****************************************************************
//****************************************************************

Static Function zReviewAlertUser1()

	if ( NMSpikeVarGet( "ReviewAlert1" ) && !NumVarOrDefault( NMSpikeDF+"ReviewAlert1Finished", 0 ) )
		NMDoAlert( "To review spike detection results, click the " + NMQuotes( "review" ) + " checkbox." )
		SetNMvar( NMSpikeDF+"ReviewAlert1Finished", 1 )
	endif
	
End // zReviewAlertUser1

//****************************************************************
//****************************************************************
//****************************************************************

Static Function zReviewAlertUser2()

	String atext1 = "To delete detected spikes, draw a square marquee around unwanted spikes in the channel graph, click inside the marquee and select NM Delete Spikes From Raster."

	if ( NMSpikeVarGet( "ReviewAlert2" ) && !NumVarOrDefault( NMSpikeDF+"ReviewAlert2Finished", 0 ) )
		NMDoAlert( atext1 )
		SetNMvar( NMSpikeDF+"ReviewAlert2Finished", 1 )
	endif
	
End // zReviewAlertUser2

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Spike Raster Subfolder Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMSpikeSubfolder()

	if ( !NMSpikeVarGet( "UseSubfolders" ) )
		return ""
	endif
	
	return NMSubfolderName( "Spike_", CurrentNMWavePrefix(), CurrentNMChannel(), NMWaveSelectShort() )
	
End // CurrentNMSpikeSubfolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeSubfolder( wavePrefix, chanNum )
	String wavePrefix
	Variable chanNum
	
	if ( !NMSpikeVarGet( "UseSubfolders" ) )
		return ""
	endif
	
	if ( strlen( wavePrefix ) == 0 )
		wavePrefix = CurrentNMWavePrefix()
	endif
	
	return NMSubfolderName( "Spike_", wavePrefix, chanNum, NMWaveSelectShort() )

End // NMSpikeSubfolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeSubfolderRasterList( subfolder, fullPath, includeRasterY )
	String subfolder
	Variable fullPath // ( 0 ) no ( 1 ) yes
	Variable includeRasterY // ( 0 ) no ( 1 ) yes

	Variable icnt
	String xList, xRaster, yRaster, xyList = ""
	
	if ( ( strlen( subfolder ) == 0 ) || StringMatch( subfolder, SELECTED ) )
		subfolder = CurrentNMSpikeSubfolder()
	endif
	
	if ( !DataFolderExists( subfolder ) )
		return ""
	endif
	
	subfolder = CheckNMFolderPath( subfolder )
	
	xList = NMFolderWaveList( subfolder, "SP_RX*", ";", "", fullPath )
	xList = SpikeRasterListStrict( xList )
	
	if ( !includeRasterY )
		return xList
	endif
	
	for ( icnt = 0 ; icnt < ItemsInList( xList ) ; icnt += 1 )
		
		xRaster = StringFromList( icnt, xList )
		
		yRaster = SpikeRasterNameY( xRaster )
		
		if ( WaveExists( $yRaster ) )
			xyList = AddListItem( xRaster, xyList, ";", inf )
			xyList = AddListItem( yRaster, xyList, ";", inf )
		endif
		
	endfor
	
	return xyList

End // NMSpikeSubfolderRasterList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeSubfolderTable( subfolder [ hide ] )
	String subfolder
	Variable hide
	
	String tName
	
	if ( ( strlen( subfolder ) == 0 ) || StringMatch( subfolder, SELECTED ) )
		subfolder = CurrentNMSpikeSubfolder()
	endif
	
	if ( !StringMatch( subfolder[ 0, 4 ], "root:" ) )
		subfolder = CurrentNMFolder( 1 ) + subfolder // change to full-path
	endif
	
	if ( !DataFolderExists( subfolder ) )
		return NM2ErrorStr( 30, "subfolder", subfolder )
	endif
	
	tName = NMSubfolderTable( subfolder, "SP_", hide = hide )
	
	NMHistoryOutputWindows()
	
	return tName
	
End // NMSpikeSubfolderTable

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeTableCall()

	String subfolder = "", folderList
	String thisFxn = GetRTStackInfo( 1 )
	
	String xWaveOrFolder = CurrentNMSpikeRasterOrFolder()
	
	if ( DataFolderExists( xWaveOrFolder ) )
	
		subfolder = xWaveOrFolder
		
	else
		
		folderList = NMSubfolderList2( "", "Spike_", 0, 0 )
		
		if ( ItemsInList( folderList ) == 0 )
			NMDoAlert( thisFxn + " Abort: located no Spike subfolders." )
			return ""
		endif
		
		subfolder = StringFromList( 0, folderList )
		
		Prompt subfolder, "select Spike subfolder:", popup folderList
		DoPrompt "Spike Subfolder Table", subfolder
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
	
	endif
	
	return NMSpikeTable( subfolder = subfolder, history = 1 )
	
End // NMSpikeTableCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeTable( [ subfolder, history ] )
	String subfolder
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	String paramList = ""
	
	if ( ParamIsDefault( subfolder ) )
		subfolder = ""
	else
		paramList = NMCmdStrOptional( "subfolder", subfolder, paramList )
	endif
	
	if ( history )
		NMCommandHistory( paramList )
	endif
	
	return NMSpikeSubfolderTable( subfolder )
	
End // NMSpikeTable

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Spike Raster Computation Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeAuto( [ force ] ) // compute raster on currently selected channel/wave, display on channel graph
	Variable force // force auto spike detection

	Variable spikes = NaN, rate = NaN
	
	String xRaster = NMSpikeDF + "SP_RasterX_Auto"
	String yRaster = NMSpikeDF + "SP_RasterY_Auto"
	
	Variable review = NMSpikeReviewGet()
	
	NMSpikeDisplayClear()
	
	if ( review )
	
		spikes = NMSpikeRasterReview()
	
	else
	
		if ( force || NMSpikeVarGet( "AutoSpike" ) )
			spikes = NMSpikeRasterCompute( waveNum = CurrentNMWave(), xRaster = xRaster, yRaster = yRaster )
		endif
	
	endif
	
	if ( spikes >= 0 )
		//rate = 1000 * spikes / ( SpikeTmax( xRaster ) - SpikeTmin( xRaster ) )
		rate = spikes / ( SpikeTmax( xRaster ) - SpikeTmin( xRaster ) )
		rate = round( rate * 1000 ) / 1000
	else
		spikes = NaN
		rate = NaN
	endif
	
	SetNMvar( NMSpikeDF + "Spikes", spikes )
	SetNMvar( NMSpikeDF + "Rate", rate )
	
	NMDragUpdate( "DragBgn" )
	NMDragUpdate( "DragEnd" )
	
End // NMSpikeAuto

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeRasterComputeAllCall()
	
	String returnStr, chanSelectList, waveSelectList
	
	if ( NMExecutionAlert() )
		return ""
	endif

	Variable displayMode = 1 + NMSpikeVarGet( "ComputeAllDisplay" )
	Variable delay = NMSpikeVarGet( "ComputeAllDelay" )
	
	Prompt displayMode, "display results while computing?", popup "no;yes;yes, with accept/reject prompt;"
	Prompt delay, "optional display update delay ( seconds ):"
	
	DoPrompt "Spike Compute All", displayMode, delay
		
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	displayMode -= 1
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMvar( NMSpikeDF + "ComputeAllDisplay", displayMode )
	SetNMvar( NMSpikeDF + "ComputeAllDelay", delay )
	
	chanSelectList = NMChanSelectAllList()
	
	if ( ItemsInList ( chanSelectList ) == 0 )
		chanSelectList = CurrentNMChanChar()
	endif
	
	waveSelectList = NMWaveSelectAllList()
	
	if ( ItemsInList( waveSelectList ) == 0 )
		waveSelectList = NMWaveSelectGet()
	endif
	
	returnStr = NMSpikeRasterComputeAll( chanSelectList = chanSelectList, waveSelectList = waveSelectList, displayMode = displayMode, delay = delay, history = 1 )
	
	zReviewAlertUser1()
	
	return returnStr

End // NMSpikeRasterComputeAllCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeRasterComputeAll( [ chanSelectList, waveSelectList, displayMode, delay, plot, table, history ] )
	String chanSelectList // channel select list ( e.g. "A;B;" )
	String waveSelectList // wave select list ( e.g. "Set1;Set2;" )
	Variable displayMode // display results while computing ( 0 ) no ( 1 ) yes ( 2 ) yes, accept/reject prompt
	Variable delay // delay in seconds ( 0 ) for fastest
	Variable plot // automatically display raster plot ( 0 ) no ( 1 ) yes
	Variable table // automatically display raster table ( 0 ) no ( 1 ) yes
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable icnt, ccnt, wcnt, spikes, chanNum, cancel
	Variable chanSelectListItems, waveSelectListItems
	Variable format = 0 // save spikes to ( 0 ) one wave ( 1 ) one wave per input wave ( NOT USED )
	
	String pName, windowName, windowList = ""
	String xRaster, yRaster, xRasterList = "", yRasterList = ""
	String subFolderName, folderList = "", folderSelect = ""
	String chanSelectStr, paramList = ""
	
	if ( NMPrefixFolderAlert() )
		return ""
	endif
	
	NMOutputListsReset()
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( ParamIsDefault( chanSelectList ) )
		chanSelectList = NMChanSelectAllList()
	else
		paramList = NMCmdStrOptional( "chanSelectList", chanSelectList, paramList )
	endif
	
	if ( ParamIsDefault( waveSelectList ) )
		waveSelectList = NMWaveSelectAllList()
	else
		paramList = NMCmdStrOptional( "waveSelectList", waveSelectList, paramList )
	endif
	
	chanSelectListItems = ItemsInList( chanSelectList )
	waveSelectListItems = ItemsInList( waveSelectList )
	
	if ( ParamIsDefault( displayMode ) )
		displayMode = 1
	else
		paramList = NMCmdNumOptional( "displayMode", displayMode, paramList, integer = 1 )
	endif
	
	if ( ParamIsDefault( delay ) )
		delay = 0
	else
		paramList = NMCmdNumOptional( "delay", delay, paramList )
	endif
	
	if ( ParamIsDefault( plot ) )
		plot = NMSpikeVarGet( "AutoRaster" )
	else
		paramList = NMCmdNumOptional( "plot", plot, paramList, integer = 1 )
	endif
	
	if ( ParamIsDefault( table ) )
		table = NMSpikeVarGet( "AutoTable" )
	else
		paramList = NMCmdNumOptional( "table", table, paramList, integer = 1 )
	endif
	
	if ( !NMVarGet( "GraphsAndTablesOn" ) )
		plot = 0
		table = 0
	endif
	
	if ( history )
		NMCommandHistory( paramList )
	endif
	
	Variable overwrite = NMSpikeVarGet( "OverwriteMode" )
	Variable useSubfolders = NMSpikeVarGet( "UseSubfolders" )
	
	Variable xbgn = NMSpikeVarGet( "Xbgn" )
	Variable xend = NMSpikeVarGet( "Xend" )
	Variable thresh = NMSpikeVarGet( "Thresh" )
	
	Variable drag = NMVarGet( "DragOn" )
	
	Variable numWaves = NMNumWaves()
	Variable saveCurrentWave = CurrentNMWave()
	
	String saveChanSelectStr = NMChanSelectStr()
	
	String wavePrefix = CurrentNMWavePrefix()
	
	String waveSelect = NMWaveSelectGet()
	String saveWaveSelect = waveSelect
	
	if ( ( numtype( displayMode ) > 0 ) || ( displayMode < 0 ) )
		displayMode = 1
	endif
	
	if ( ( numtype( delay ) > 0 ) || ( delay < 0 ) )
		delay = 0
	endif
	
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
				subFolderName = NMSubfolderName( "Spike_", wavePrefix, chanNum, NMWaveSelectShort() )
			else
				subFolderName = ""
			endif
			
			CheckNMSubfolder( subFolderName )
			folderList = AddListItem( NMChild( subFolderName ), folderList, ";", inf )
			
			if ( strlen( folderSelect ) == 0 )
				folderSelect = subFolderName
			endif
			
			SetNMvar( prefixFolder+"CurrentChan", chanNum )
			
			if ( format == 0 )
			
				pName = NMWaveSelectStr() + "_"
				xRaster = subFolderName + NextWaveName2( subFolderName, "SP_RX_" + pName, chanNum, overwrite )
				yRaster = subFolderName + NextWaveName2( subFolderName, "SP_RY_" + pName, chanNum, overwrite )
			
				spikes = NMSpikeRasterCompute( chanNum = chanNum, waveNum = -1, xbgn = xbgn, xend = xend, xRaster = xRaster, yRaster = yRaster, displayMode = displayMode, delay = delay * 1000 )
				
				NMHistoryOutputWaves()
				
				if ( plot )
					windowName = NMSpikeRasterPlot( xRasterList = xRaster, yRasterList = yRaster, xbgn = xbgn, xend = xend, hide = 1 )
				else
					windowName = ""
				endif
				
				if ( WavesExist( xRaster + ";" + yRaster + ";" ) )
					xRasterList = AddListItem( xRaster, xRasterList, ";", inf )
					yRasterList = AddListItem( yRaster, yRasterList, ";", inf )
				endif
				
				SetNMStr( NMDF + "OutputWaveList", xRaster + ";" + yRaster + ";" )
				
			elseif ( format == 1 ) // NOT USED
			
				for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
				
					if ( NMProgressTimer( wcnt, numWaves, "Detecting Spikes..." ) == 1 ) // update progress display
						break // cancel
					endif
				
					if ( !NMWaveIsSelected( chanNum, wcnt ) )
						continue
					endif
				
					pName = "R" + num2istr( wcnt ) + "_"
					xRaster = subFolderName + NextWaveName2( subFolderName, "SP_RX_" + pName, chanNum, overwrite )
					yRaster = subFolderName + NextWaveName2( subFolderName, "SP_RY_" + pName, chanNum, overwrite )
				
					spikes = NMSpikeRasterCompute( chanNum = chanNum, waveNum = wcnt, xbgn = xbgn, xend = xend, xRaster = xRaster, yRaster = yRaster, displayMode = displayMode, delay = delay * 1000 )
					
					if ( WavesExist( xRaster + ";" + yRaster + ";" ) )
						xRasterList = AddListItem( xRaster, xRasterList, ";", inf )
						yRasterList = AddListItem( yRaster, yRasterList, ";", inf )
					endif
				
				endfor // waves
				
				windowName = NMSpikeRasterPlot( xRasterList = xRaster, yRasterList = yRaster, xbgn = xbgn, xend = xend )
			
			else
			
				return ""
			
			endif
			
			if ( useSubfolders )
				NMSpikeSet( raster = NMChild( subFolderName ) )
			else
				NMSpikeSet( raster = xRaster )
			endif
			
			if ( strlen( windowName ) > 0 )
				windowList = AddListItem( windowName, windowList, ";", inf )
			endif
			
			if ( table )
			
				if ( useSubfolders )
					windowName = NMSpikeSubfolderTable( subFolderName, hide = 1 )
				else
					windowName = SpikeTable( xRaster, hide = 1 )
				endif
				
			else
			
				windowName = ""
				
			endif
			
			if ( strlen( windowName ) > 0 )
				windowList = AddListItem( windowName, windowList, ";", inf )
			endif
			
		endfor // channels
		
	endfor // sets
	
	if ( drag )
		NMDragUpdate( "DragBgn" )
		NMDragUpdate( "DragEnd" )
	endif
	
	if ( chanSelectListItems > 0 )
		NMChanSelect( saveChanSelectStr )
	endif
	
	if ( waveSelectListItems > 0 )
		NMWaveSelect( saveWaveSelect )
	endif
	
	NMCurrentWaveSet( saveCurrentWave )
	
	ChanGraphsUpdate()
	NMSpikeAuto( force = 1 )
	NMSpikeUpdate()
	
	for ( icnt = 0 ; icnt < ItemsInList( windowList ) ; icnt += 1 )
	
		windowName = StringFromList( icnt, windowList )
	
		if ( ( strlen( windowName ) > 0 ) && ( ( WinType( windowName ) == 1 ) || ( WinType( windowName ) == 2 ) ) )
			DoWindow /F/HIDE=0 $windowName
		endif
	
	endfor
	
	SetNMstr( NMDF + "OutputWaveList", xRasterList + yRasterList )
	SetNMstr( NMDF + "OutputWinList", windowList )
	
	return folderList
	
End // NMSpikeRasterComputeAll

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeRasterCompute( [ chanNum, waveNum, threshold, xbgn, xend, xRaster, yRaster, displayMode, delay ] )
	Variable chanNum // channel number ( -1 ) for current channel
	Variable waveNum // wave number ( -1 ) for all waves
	Variable threshold // threshold trigger level
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	String xRaster // output raster x-wave name
	String yRaster // output raster y-wave name
	Variable displayMode // display results while computing ( 0 ) no ( 1 ) yes ( 2 ) yes, accept/reject prompt
	Variable delay // delay in milliseconds ( 0 ) for fastest
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	endif
	
	if ( ParamIsDefault( waveNum ) )
		waveNum = -1
	endif
	
	if ( ParamIsDefault( threshold ) )
		threshold = NMSpikeVarGet( "Thresh" )
	endif
	
	if ( ParamIsDefault( xbgn ) )
		xbgn = NMSpikeVarGet( "Xbgn" )
	endif
	
	if ( ParamIsDefault( xend ) )
		xend = NMSpikeVarGet( "Xend" )
	endif
	
	if ( ParamIsDefault( xRaster ) )
		xRaster = "SP_RasterX"
	endif
	
	if ( ParamIsDefault( yRaster ) )
		yRaster = "SP_RasterY"
	endif
	
	if ( ParamIsDefault( displayMode ) )
		displayMode = 1
	endif
	
	if ( ParamIsDefault( delay ) )
		delay = 0
	endif
	
	Variable wcnt, ncnt, scnt, spkcnt, found, event, allFlag, wbgn, wend, numWaves = 1
	Variable xbgn1, xend1, xbgn2, xend2, tmin = inf, tmax = -inf
	Variable returnVal
	
	Variable positiveSpikes = NMSpikeVarGet( "PositiveSpikes" )
	Variable rasterNaNs = NMSpikeVarGet( "RasterNaNs" )
	Variable spikeLimit = NMSpikeVarGet( "DisplaySpikesLimit" )
	
	String transform, wName, xWave, wList = "", aName = ""
	String xLabel = "Spike Event", yLabel = ""
	String copy = "SP_WaveTemp"
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	Variable saveCurrentWave = CurrentNMWave()
	Variable currentChan = CurrentNMChannel()
	
	String wavePrefix = CurrentNMWavePrefix()
	
	SetNMstr( NMDF + "OutputWaveList", "" )
	
	if ( strlen( prefixFolder ) == 0 )
		//NM2Error( 30, "PrefixFolder", prefixFolder )
		return -1
	endif
	
	chanNum = ChanNumCheck( chanNum )
	
	if ( ( numtype( waveNum ) > 0 ) || ( waveNum >= NMNumWaves() ) )
		NM2Error( 10, "waveNum", num2istr( waveNum ) )
		return -1
	endif
	
	transform = NMChanTransformGet( chanNum )
	transform = StringFromList( 0, transform, "," )
	
	if ( StringMatch( transform, "Error" ) )
		return -1
	endif
	
	if ( waveNum < 0 )
		numWaves = NMNumWaves()
		allFlag = 1
		wbgn = 0
		wend = numWaves - 1
	else
		wbgn = waveNum
		wend = waveNum
	endif
	
	if ( numtype( threshold ) > 0 )
		NM2Error( 10, "threshold", num2str( threshold ) )
		return -1
	endif
	
	if ( numtype( xbgn ) > 0 )
		xbgn = -inf
	endif
	
	if ( numtype( xend ) > 0 )
		xend = inf
	endif
	
	if ( strlen( xRaster ) == 0 )
		NM2Error( 21, "xRaster", xRaster )
		return -1
	endif
	
	if ( strlen( yRaster ) == 0 )
		NM2Error( 21, "yRaster", yRaster )
		return -1 // not allowed
	endif
	
	Make /O/N=0 SP_xvalues=NaN
	Make /O/N=0 $xRaster=NaN
	Make /O/N=0 $yRaster=NaN
	
	Wave xWaveR = $xRaster
	Wave yWaveR = $yRaster
	
	for ( wcnt = wbgn ; wcnt <= wend ; wcnt += 1 )
	
		if ( NMProgressTimer( wcnt, numWaves, "Detecting Spikes..." ) == 1 ) // update progress display
			break // cancel
		endif
	
		wName = NMChanWaveName( chanNum, wcnt )
		xWave = NMXwave( waveNum = wcnt )
	
		if ( allFlag )
		
			if ( !NMWaveIsSelected( chanNum, wcnt ) )
				continue
			endif
			
			NMCurrentWaveSet( wcnt, update = 0 )
			
			if ( displayMode > 0 )
				NMChanGraphUpdate( channel = chanNum, waveNum = wcnt )
				aName = ChanDisplayWave( chanNum )
			else
				returnVal = ChanWaveMake( currentChan, wName, copy, xWave = xWave )
				aName = copy
			endif
			
		else
		
			returnVal = ChanWaveMake( chanNum, wName, copy, xWave = xWave )
			aName = copy
			
		endif
		
		if ( returnVal < 0 )
			continue
		endif
		
		if ( strlen( yLabel ) == 0 )
			yLabel = NMNoteLabel( "x", aName, "" )
		endif
		
		if ( !WaveExists( $aName ) )
			continue // wave does not exist
		endif
		
		if ( numtype( xbgn ) == 0 )
			xbgn1 = xbgn
		else
			xbgn1 = NMLeftX( aName, xWave = xWave )
		endif
		
		if ( numtype( xend ) == 0 )
			xend1 = xend
		else
			xend1 = NMRightX( aName, xWave = xWave )
		endif
		
		if ( numtype( xbgn1 ) > 0 )
			xbgn1 = leftx( $aName )
		endif
		
		if ( numtype( xend1 ) > 0 )
			xend1 = rightx( $aName )
		endif
		
		if ( xbgn1 < tmin )
			tmin = xbgn1
		endif
		
		if ( xend1 > tmax )
			tmax = xend1
		endif
		
		xbgn2 = NMXscaleTransform( xbgn1, "x2y", yWave = aName, xWave = xWave )
		xend2 = NMXscaleTransform( xend1, "x2y", yWave = aName, xWave = xWave )
		
		if ( xend2 < xbgn2 + 2*deltax( $aName ) )
			//NMHistory( "SpikeRaster: out of range: ", xbgn2, xend2
			//continue // out of range
		endif
		
		if ( xbgn2 == xend2 )
			continue
		endif
		
		if ( positiveSpikes )
			Findlevels /Q/R=( xbgn2, xend2 )/D=SP_xvalues/Edge=1 $aName, threshold
		else
			Findlevels /Q/R=( xbgn2, xend2 )/D=SP_xvalues/Edge=2 $aName, threshold
		endif
		
		if ( V_LevelsFound > 0 )
		
			for ( scnt = 0 ; scnt < V_LevelsFound ; scnt += 1 )
				if ( scnt < numpnts( SP_xvalues ) )
					SP_xvalues[scnt] = NMXscaleTransform( SP_xvalues[scnt], "y2x", yWave = aName, xWave = xWave )
				endif
			endfor
			
			WaveStats /Q/Z SP_xvalues
				
			found = V_npnts
				
		else
		
			found = 0
		
		endif
		
		if ( displayMode > 0 )
		
			if ( V_LevelsFound > 0 )
		
				WaveStats /Q/Z SP_xvalues
				
				if ( V_npnts < spikeLimit )
					Duplicate /O SP_xvalues $NMSpikeDF+"SP_SpikeX"
					Duplicate /O SP_xvalues $NMSpikeDF+"SP_SpikeY"
					SetNMwave( NMSpikeDF+"SP_SpikeY", -1, threshold )
				endif
				
			else
			
				SetNMwave( NMSpikeDF+"SP_SpikeX", -1, NaN )
				SetNMwave( NMSpikeDF+"SP_SpikeY", -1, NaN )
			
			endif
			
			if ( NMVarGet( "AutoDoUpdate" ) )
				DoUpdate
			endif
			
			if ( ( displayMode == 1 ) && ( numtype( delay ) == 0 ) && ( delay > 0 ) )
			
				NMwaitMSTimer( delay )
				
			elseif ( ( displayMode == 2 ) && ( found > 0 ) )
			
				DoAlert 2, "Accept results?"
				
				if ( V_flag == 1 )
					
				elseif ( V_flag == 2 )
					continue
				elseif ( V_flag == 3 )
					break
				endif
				
			endif
			
		endif
		
		ncnt = numpnts( xWaveR )
		
		if ( found > 0 )
		
			Redimension /N=( ncnt + found ) xWaveR, yWaveR
			
			for ( scnt = 0 ; scnt < V_LevelsFound ; scnt += 1 )
			
				if ( scnt >= numpnts( SP_xvalues ) )
					break
				endif
			
				event = SP_xvalues[scnt]
				
				if ( numtype( event ) == 0 )
					xWaveR[ncnt] = event
					yWaveR[ncnt] = wcnt
					spkcnt += 1
					ncnt += 1
				endif
			
			endfor
		
		else
		
			Redimension /N=( ncnt + 1 ) xWaveR, yWaveR
			xWaveR[ncnt] = NaN
			yWaveR[ncnt] = wcnt
		
		endif
		
		if ( RasterNaNs )
		
			ncnt = numpnts( xWaveR )
				
			Redimension /N=( ncnt + 1 ) xWaveR, yWaveR
				
			xWaveR[ncnt] = NaN // add extra row for NaN's
			yWaveR[ncnt] = NaN
		
		endif
		
		wList = AddListItem( wName, wList, ";", inf )
		
	endfor
	
	NMNoteType( xRaster, "Spike RasterX", xLabel, yLabel, "_FXN_" )
	Note $xRaster, "Spike Thresh:" + num2str( threshold )
	Note $xRaster, "Spike Xbgn:" + num2str( xbgn ) + ";Spike Xend:" + num2str( xend ) + ";"
	Note $xRaster, "Spike Tmin:" + num2str( tmin ) + ";Spike Tmax:" + num2str( tmax ) + ";"
	Note $xRaster, "Spike Prefix:" + wavePrefix
	Note $xRaster, "Spike Channel:" + num2str( chanNum )
	Note $xRaster, "Spike Channel Transform:" + transform
	Note $xRaster, "Wave List:" + NMUtilityWaveListShort( wList )
	Note $xRaster, "Spike RasterY:" + yRaster
	
	xLabel = "Spike Event"
	yLabel = wavePrefix + " #"
	
	NMNoteType( yRaster, "Spike RasterY", xLabel, yLabel, "_FXN_" )
	Note $yRaster, "Spike Thresh:" + num2str( threshold )
	Note $yRaster, "Spike Xbgn:" + num2str( xbgn ) + ";Spike Xend:" + num2str( xend ) + ";"
	Note $yRaster, "Spike Tmin:" + num2str( tmin ) + ";Spike Tmax:" + num2str( tmax ) + ";"
	Note $yRaster, "Spike Prefix:" + wavePrefix
	Note $yRaster, "Spike Channel:" + num2str( chanNum )
	Note $yRaster, "Spike Channel Transform:" + transform
	Note $yRaster, "Wave List:" + NMUtilityWaveListShort( wList )
	Note $yRaster, "Spike RasterX:" + xRaster
	
	KillWaves /Z SP_xvalues
	KillWaves /Z $copy
	
	NMCurrentWaveSet( saveCurrentWave, update = 0 )
	
	SetNMstr( NMDF + "OutputWaveList", xRaster + ";" + yRaster + ";" )
	
	return spkcnt // return spike count

End // NMSpikeRasterCompute

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeRasterReview()
	
	Variable icnt, jcnt, spikes, thresh, chan
	
	String currentRasterX = CheckNMSpikeRasterXPath( SELECTED )
	String currentRasterY = CheckNMSpikeRasterYPath( SELECTED, SELECTED )
	
	String displayRasterX = NMSpikeDF + "SP_SpikeX"
	String displayRasterY = NMSpikeDF + "SP_SpikeY"
	
	if ( !WaveExists( $currentRasterX ) || !WaveExists( $currentRasterY ) )
		return 0
	endif
	
	Wave cRX = $currentRasterX
	Wave cRY = $currentRasterY
	
	Variable waveNum = CurrentNMWave()
	
	if ( !NMSpikeReviewGet() )
		return 0
	endif
	
	icnt = strsearch( currentRasterX, "_", inf, 1 )
	
	chan = ChanChar2Num( currentRasterX[ icnt + 1, icnt + 1 ] )
	
	if ( chan != CurrentNMChannel() )
	
		NMDoAlert( "NM Spike Review Alert: changing Channel Select to " + ChanNum2Char( chan ) )
	
		NMChanSelect( ChanNum2Char( chan ) )
		
		return 0 // this function will be called again from NMChanSelect
		
	endif
	
	thresh = NMNoteVarByKey( currentRasterX, "Spike Thresh" )
	
	for ( icnt = 0 ; icnt < numpnts( cRY ) ; icnt += 1 )
	
		if ( cRY[ icnt ] > waveNum )
			break
		endif
	
		if ( cRY[ icnt ] == waveNum )
			spikes += 1
		endif
		
	endfor
	
	Make /O/N=( spikes ) $displayRasterX = NaN
	Make /O/N=( spikes ) $displayRasterY = NaN
	
	Wave outX = $displayRasterX
	Wave outY = $displayRasterY
	
	for ( icnt = 0 ; icnt < numpnts( cRY ) ; icnt += 1 )
	
		if ( cRY[ icnt ] > waveNum )
			break
		endif
	
		if ( cRY[ icnt ] == waveNum )
		
			if ( jcnt >= numpnts( outX ) )
				break
			endif
		
			outX[ jcnt ] = cRX[ icnt ]
			outY[ jcnt ] = thresh
			
			jcnt += 1
		
		endif
		
	endfor
	
	return spikes
	
End // NMSpikeRasterReview

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Spike Raster Wave Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeTmin( xRaster )
	String xRaster
	
	Variable tmin
	
	xRaster = CheckNMSpikeRasterXPath( xRaster )
	
	if ( !WaveExists( $xRaster ) )
		return 0
	endif
	
	tmin = NMNoteVarByKey( xRaster, "Spike Tmin" )
	
	if ( numtype( tmin ) == 0 )
		return tmin
	endif
	
	tmin = NMNoteVarByKey( xRaster, "Spike Xbgn" )
	
	if ( numtype( tmin ) == 0 )
		return tmin
	endif
	
	tmin = NMNoteVarByKey( xRaster, "Spike Tbgn" )
		
	if ( numtype( tmin ) == 0 )
		return tmin
	endif
	
	return leftx( $ChanDisplayWave( -1 ) )

End // SpikeTmin

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeTmax( xRaster )
	String xRaster
	
	Variable tmax
	
	xRaster = CheckNMSpikeRasterXPath( xRaster )
	
	if ( !WaveExists( $xRaster ) )
		return 0
	endif
	
	tmax = NMNoteVarByKey( xRaster, "Spike Tmax" )
	
	if ( numtype( tmax ) == 0 )
		return tmax
	endif
	
	tmax = NMNoteVarByKey( xRaster, "Spike Xend" )
	
	if ( numtype( tmax ) == 0 )
		return tmax
	endif
		
	tmax = NMNoteVarByKey( xRaster, "Spike Tend" )
	
	if ( numtype( tmax ) == 0 )
		return tmax
	endif
	
	if ( numpnts( $xRaster ) > 0 )
	
		WaveStats /Q $xRaster
		
		if ( numtype( V_max ) == 0 )
			return V_max
		endif
		
	endif
	
	return rightx( $ChanDisplayWave( -1 ) )

End // SpikeTmax

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeRasterCountSpikes( xRaster )
	String xRaster
	
	xRaster = CheckNMSpikeRasterXPath( xRaster )
	
	if ( WaveExists( $xRaster ) && ( numpnts( $xRaster ) > 0 ) )
		WaveStats /Q/Z $xRaster
		return V_npnts
	else
		return 0
	endif
	
End // SpikeRasterCountSpikes

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeRasterCountReps( yRaster )
	String yRaster
	
	Variable icnt, jcnt, rcnt
	
	if ( !WaveExists( $yRaster ) )
		return 0
	endif
	
	WaveStats /Q/Z $yRaster
	
	Wave yWave = $yRaster
	
	for ( icnt = V_min ; icnt <= V_max ; icnt += 1 )
		for ( jcnt = 0 ; jcnt < numpnts( yWave ) ; jcnt += 1 )
			if ( yWave[jcnt] == icnt )
				rcnt += 1
				break
			endif
		endfor
	endfor
	
	return rcnt
	
End // SpikeRasterCountReps

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeRasterNameX( yRaster )
	String yRaster
	
	String xRaster
	
	if ( !WaveExists( $yRaster ) )
		NM2Error( 1, "yRaster", yRaster )
		return ""
	endif
	
	xRaster = NMNoteStrByKey( yRaster, "Spike RasterX" )
	
	if ( WaveExists( $xRaster ) )
		return xRaster
	endif
	
	if ( strsearch( xRaster, "SP_RY_", 0, 2 ) >= 0 )
	
		xRaster = ReplaceString( "SP_RY_", yRaster, "SP_RX_" )
		
		if ( WaveExists( $xRaster ) )
			return xRaster
		endif
		
	endif
	
	if ( strsearch( xRaster, "SP_RasterY_", 0, 2 ) >= 0 )
	
		xRaster = ReplaceString( "SP_RasterY_", yRaster, "SP_RasterX_" )
		
		if ( WaveExists( $xRaster ) )
			return xRaster
		endif
	
	endif
	
	return ""
	
End // SpikeRasterNameX

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeRasterNameY( xRaster )
	String xRaster
	
	String yRaster = ""
	
	xRaster = CheckNMSpikeRasterXPath( xRaster )
	
	if ( !WaveExists( $xRaster ) )
		NM2Error( 1, "xRaster", xRaster )
		return ""
	endif
	
	yRaster = NMNoteStrByKey( xRaster, "Spike RasterY" )
	
	if ( WaveExists( $yRaster ) )
		return yRaster
	endif
	
	if ( strsearch( xRaster, "SP_RX_", 0, 2 ) >= 0 )
	
		yRaster = ReplaceString( "SP_RX_", xRaster, "SP_RY_" )
	
		if ( WaveExists( $yRaster ) )
			return yRaster
		endif
		
	endif
	
	if ( strsearch( xRaster, "SP_RasterX_", 0, 2 ) >= 0 )
	
		yRaster = ReplaceString( "SP_RasterX_", xRaster, "SP_RasterY_" )
		
		if ( WaveExists( $yRaster ) )
			return yRaster
		endif
	
	endif
	
	return ""
	
End // SpikeRasterNameY

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeRasterListStrict( rasterList )
	String rasterList
	
	Variable icnt
	String rasterName, wList = ""
	
	for ( icnt = 0 ; icnt < ItemsInList( rasterList ) ; icnt += 1 )
		
		rasterName = StringFromList( icnt, rasterList )
		
		if ( strsearch( rasterName, "_Rate", 0, 2 ) > 0 )
			continue
		endif
		
		if ( strsearch( rasterName, "Rate_", 0, 2 ) > 0 )
			continue
		endif
		
		if ( strsearch( rasterName, "_PSTH", 0, 2 ) > 0 )
			continue
		endif
		
		if ( strsearch( rasterName, "PSTH_", 0, 2 ) > 0 )
			continue
		endif
		
		if ( strsearch( rasterName, "_ISIH", 0, 2 ) > 0 )
			continue
		endif
		
		if ( strsearch( rasterName, "ISIH_", 0, 2 ) > 0 )
			continue
		endif
		
		if ( strsearch( rasterName, "_Intvls", 0, 2 ) > 0 )
			continue
		endif
		
		if ( strsearch( rasterName, "Intvls_", 0, 2 ) > 0 )
			continue
		endif
		
		wList = AddListItem( rasterName, wList, ";", inf )
		
	endfor
	
	return wList
	
End // SpikeRasterListStrict

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeRasterList() // old spike raster waves that DO NOT reside in spike subfolder

	String wList = WaveList( "SP_RasterX_*", ";", "Text:0" ) + WaveList( "SP_RX_*", ";", "Text:0" )
	
	return SpikeRasterListStrict( wList )

End // SpikeRasterList

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Spike Raster Select Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMSpikeRasterOrFolder()

	return StrVarOrDefault( CurrentNMPrefixFolder() + "SpikeRasterXSelect", "" )

End // CurrentNMSpikeRasterOrFolder

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zRasterSelectPrompt()

	String xRaster = CurrentNMSpikeRasterOrFolder()
	
	if ( !WaveExists( $xRaster ) )
		xRaster = " "
	endif
	
	Prompt xRaster, "select wave of spike times ( e.g. SP_RX_RAll_A0 ):", popup " ;" + WaveList( "*", ";", "Text:0" )
	DoPrompt "Spike Raster Plot", xRaster
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	return xRaster

End // zRasterSelectPrompt

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMSpikeRasterXSelect()

	Variable wcnt
	String wName, wList, path, notestr

	String xWaveOrFolder = CurrentNMSpikeRasterOrFolder()
	
	if ( DataFolderExists( xWaveOrFolder ) )
	
		path = CurrentNMFolder( 1 ) + xWaveOrFolder + ":"
		wName = StrVarOrDefault( path + "RasterXSelect", "" )
		
		if ( ( strlen( wName ) == 0 ) || !WaveExists( $path+wName ) )
		
			wList = NMFolderWaveList( path, "*", ";", "", 0 )
			
			for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
				
				wName = StringFromList( wcnt, wList )
				notestr = note( $path + wName )
				
				SetNMstr( path + "RasterXSelect", wName )
				
				if ( strsearch( notestr, "RasterX", 0 ) > 0 )
					return path + wName
				endif
				 
			endfor
			
		endif
		
		if ( WaveExists( $path + wName ) )
			return path + wName
		endif
	
	elseif ( WaveExists( $xWaveOrFolder ) )
	
		return xWaveOrFolder
		
	endif

	return ""
	
End // CurrentNMSpikeRasterXSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CheckNMSpikeRasterXPath( xRaster )
	String xRaster
	
	String wList
	
	if ( ( strlen( xRaster ) == 0 ) || StringMatch( xRaster, SELECTED ) )
		return CurrentNMSpikeRasterXSelect()
	endif
	
	if ( WaveExists( $xRaster ) )
		return xRaster
	endif
	
	xRaster = CurrentNMFolder( 1 ) + xRaster
	
	if ( WaveExists( $xRaster ) )
		return xRaster
	endif
	
	if ( DataFolderExists( xRaster ) )
		
		wList = NMFolderWaveList( xRaster, "SP_RX_*", ";", "", 1 )
		
		if ( ItemsInList( wList ) > 0 )
			return StringFromList( 0, wList )
		endif
		
	endif
	
	return ""
	
End // CheckNMSpikeRasterXPath

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CheckNMSpikeRasterYPath( xRaster, yRaster )
	String xRaster, yRaster
	
	String wList
	
	if ( ( strlen( yRaster ) == 0 ) || StringMatch( yRaster, SELECTED ) )
		return SpikeRasterNameY( xRaster )
	endif
	
	if ( WaveExists( $yRaster ) )
		return yRaster
	endif
	
	yRaster = CurrentNMFolder( 1 ) + yRaster // try subfolder
	
	if ( WaveExists( $yRaster ) )
		return yRaster
	endif
	
	if ( DataFolderExists( yRaster ) )
		
		wList = NMFolderWaveList( yRaster, "SP_RY_*", ";", "", 1 )
		
		if ( ItemsInList( wList ) > 0 )
			return StringFromList( 0, wList )
		endif
		
	endif
	
	return ""
	
End // CheckNMSpikeRasterYPath

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zFullPathRasterXList( folder, xRasterList )
	String folder, xRasterList
	
	Variable icnt
	String rasterOrFolder, xRaster, xRasterList2 = ""
	
	if ( ( strlen( folder ) == 0 ) && ( strlen( xRasterList ) == 0 ) )
	
		rasterOrFolder = CurrentNMSpikeRasterOrFolder()
		
		if ( DataFolderExists( rasterOrFolder ) )
		
			return NMSpikeSubfolderRasterList( rasterOrFolder, 1, 0 ) // full-path list
		
		elseif ( WaveExists( $rasterOrFolder ) )
		
			return rasterOrFolder
			
		else
		
			return ""
			
		endif
		
	endif
	
	if ( strlen( folder ) > 0 )
	
		if ( StringMatch( folder, SELECTED ) )
			folder = CurrentNMSpikeRasterOrFolder()
		endif
		
		folder = CheckNMFolderPath( folder )
	
		if ( !DataFolderExists( folder ) )
			return ""
		endif
	
		if ( ( strlen( xRasterList ) == 0 ) || StringMatch( xRasterList, SELECTED ) )
		
			return NMSpikeSubfolderRasterList( folder, 1, 0 ) // full-path list
			
		else
			
			if ( !StringMatch( folder[ 0, 4 ], "root:" ) )
				folder = CurrentNMFolder( 1 ) + folder // change to full-path
			endif
		
			folder = LastPathColon( folder, 1 )
			
			for ( icnt = 0 ; icnt < ItemsInList( xRasterList ) ; icnt += 1 )
				xRaster = folder + StringFromList( icnt, xRasterList )
				xRasterList2 = AddListItem( xRaster, xRasterList2, ";", inf )
			endfor
			
			return xRasterList2 // convert to full-path list
			
		endif
		
	endif
		
	if ( ( strlen( xRasterList ) == 0 ) || StringMatch( xRasterList, SELECTED ) )
	
		rasterOrFolder = CurrentNMSpikeRasterOrFolder()
		
		if ( WaveExists( $rasterOrFolder ) )
			return rasterOrFolder
		endif
	
		xRasterList = WaveList( "SP_RX*", ";", "" )
		
	endif
	
	return xRasterList

End // zFullPathRasterXList

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Spike Analysis Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeAnalysisCall( fxn )
	String fxn
	
	strswitch( fxn )
			
		case "Raster":
			return zCall_NMSpikeRasterPlot()
	
		case "PSTH":
			return zCall_NMSpikePSTH()
			
		case "JPSTH":
			return zCall_NMSpikePSTHJoint()
			
		case "ISIH":
			return zCall_NMSpikeISIH()
			
		case "JISIH":
			return zCall_NMSpikeISIHJoint()
			
		case "Joint":
			return zCall_NMSpikeJoint()
			
		case "Rate":
			return zCall_NMSpikeRate()
			
		case "2Waves":
		case "Spike2Waves":
			return zCall_NMSpikesToWaves()
			
		case "Table":
			return zCall_NMSpikeTable()
			
		case "Delete Spike Subfolder":
			return zCall_NMSpikeFolderKill()
			
		default:
			NMDoAlert( "NMSpikeAnalysisCall: unrecognized function call: " + fxn )
			
	endswitch
	
	return ""
	
End // NMSpikeAnalysisCall

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zCall_NMSpikeJoint()

	Variable select = NumVarOrDefault( NMSpikeDF + "JointSelect", 1 )
	
	Prompt select, " ", popup "Joint InterSpike Interval Histogram (cross-correlation);Joint Peri-Stimulus Time Histogram;"
	
	DoPrompt "Joint Spike Histogram", select

	if ( V_flag == 1 )
		return ""
	endif
	
	SetNMvar( NMSpikeDF + "JointSelect", select )

	if ( select == 1 )
		return zCall_NMSpikeISIHJoint()
	elseif ( select == 2 )
		return zCall_NMSpikePSTHJoint()
		
	endif
	
	return ""

End // zCall_NMSpikeJoint

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMSpikeAnalysisWaves( xRaster, yRaster, yMustExist )
	String xRaster, yRaster
	Variable yMustExist // ( 0 ) no ( 1 ) yes
	
	Variable xpnts, ypnts
	String txt
	
	String fxnName = GetRTStackInfo( 2 )
	
	if ( !WaveExists( $xRaster ) )
		NM2ErrorStr( 1, "xRaster", xRaster )
		return -1
	endif
	
	if ( WaveExists( $yRaster ) )
	
		xpnts = numpnts( $xRaster )
		ypnts = numpnts( $yRaster )
		
		if ( xpnts != ypnts )
			NMDoAlert( fxnName + " Error: x- and y-raster waves have different length: " + num2istr( xpnts ) + " and " + num2istr( ypnts ) )
			return -1
		endif
	
	else
	
		txt = fxnName + " Alert: failed to find corresponding y-raster wave for " + NMQuotes( xRaster )
	
		if ( yMustExist )
			NMDoAlert( txt )
			return -1
		else
			NMHistory( txt )
			return 0
		endif
		
	endif
	
	return 0
	
End // CheckNMSpikeAnalysisWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeAnalysisTbgn( xRasterList )
	String xRasterList
	
	Variable icnt, xbgn, xbgnMin = inf
	String xRaster
	
	for ( icnt = 0 ; icnt < ItemsInList( xRasterList ) ; icnt += 1 )
		
		xRaster = StringFromList( icnt, xRasterList )
		xRaster = CheckNMSpikeRasterXPath( xRaster )
		
		if ( WaveExists( $xRaster ) )
	
			xbgn = SpikeTmin( xRaster )
			
			if ( ( numtype( xbgn ) == 0 ) && ( xbgn < xbgnMin ) )
				xbgnMin = xbgn
			endif
		
		endif
	
	endfor
	
	return xbgnMin

End // NMSpikeAnalysisTbgn

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeAnalysisTend( xRasterList )
	String xRasterList
	
	Variable icnt, xend, xendMax = -inf
	String xRaster
	
	for ( icnt = 0 ; icnt < ItemsInList( xRasterList ) ; icnt += 1 )
		
		xRaster = StringFromList( icnt, xRasterList )
		xRaster = CheckNMSpikeRasterXPath( xRaster )
		
		if ( WaveExists( $xRaster ) )
	
			xend = SpikeTmax( xRaster )
			
			if ( ( numtype( xend ) == 0 ) && ( xend > xendMax ) )
				xendMax = xend
			endif
		
		endif
	
	endfor
	
	return xendMax

End // NMSpikeAnalysisTend

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zCall_NMSpikeRasterGet2( promptStr, xRaster1 )
	String promptStr
	String xRaster1
	
	String xRaster2 = "", folder2, folderList2
	
	String currentFolder = CurrentNMFolder( 1 )
	String xRasterList = SpikeRasterList()
	
	if ( strlen( xRaster1 ) == 0 )
		xRaster1 = CurrentNMSpikeRasterOrFolder()
	endif
	
	if ( ( strlen( xRaster1 ) == 0 ) || !WaveExists( $xRaster1 ) )
		return NM2ErrorStr( 1, "xRaster1", xRaster1 )
	endif
	
	Prompt xRaster1, "select spike raster #1:", popup xRasterList
	Prompt xRaster2, "select spike raster #2:", popup " ;" + xRasterList
	
	folderList2 = NMDataFolderList()
	folderList2 = RemoveFromList( CurrentNMFolder( 0 ), folderList2 )
	
	if ( ItemsInList( folderList2 ) >= 1 )
	
		Prompt folder2, "or choose a folder to locate spike raster #2:", popup " ;" + folderList2
		DoPrompt promptStr, xRaster1, xRaster2, folder2
	
		if ( V_flag == 1 )
			return ""
		endif
		
		if ( strlen( folder2 ) > 1 )
		
			xRasterList = NMFolderWaveList( folder2, "SP_RasterX_*", ";", "Text:0", 0 )
			xRasterList += NMFolderWaveList( folder2, "SP_RX_*", ";", "Text:0", 0 )
			
			if ( ItemsInList( xRasterList ) == 0 )
				DoAlert /T=( promptStr ) 0, "Abort: failed to locate any Spike Raster waves in NM folder " + folder2
				return ""
			endif
			
			xRaster2 = StringFromList( 0, xRasterList )
			
			Prompt xRaster2, "select spike raster #2:", popup xRasterList
			
			DoPrompt promptStr, xRaster2
	
			if ( V_flag == 1 )
				return ""
			endif
			
			xRaster1 = currentFolder + xRaster1
			xRaster2 = "root:" + folder2 + ":" + xRaster2
			
		elseif ( StringMatch( xRaster2, " " ) )
		
			DoAlert /T=( promptStr ) 0, "Abort: no selection for spike raster #2"
			return ""
		
		endif
	
	else
	
		DoPrompt promptStr, xRaster1, xRaster2
	
		if ( V_flag == 1 )
			return ""
		endif
	
	endif
	
	return xRaster1 + ";" + xRaster2 + ";"
	
End // zCall_NMSpikeRasterGet2

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zCall_NMSpikeSubfolderGet2( promptStr, subfolder1 )
	String promptStr
	String subfolder1
	
	String subfolder2, folder2, folderList2
	String xRaster1, xRaster2, xRasterList1, xRasterList2
	
	if ( strlen( subfolder1 ) == 0 )
		subfolder1 = CurrentNMSpikeRasterOrFolder()
	endif
	
	if ( ( strlen( subfolder1 ) == 0 ) || !DataFolderExists( subfolder1 ) )
		return NM2ErrorStr( 30, "subfolder1", subfolder1 )
	endif
	
	String currentFolder = CurrentNMFolder( 1 )
	
	String subfolderList = NMSubfolderList2( "", "Spike_", 0, 0 )
	
	Prompt subfolder1, "select spike raster subfolder #1:", popup subfolderList
	Prompt subfolder2, "select spike raster subfolder #2:", popup " ;" + subfolderList
	
	folderList2 = NMDataFolderList()
	folderList2 = RemoveFromList( CurrentNMFolder( 0 ), folderList2 )
	
	if ( ItemsInList( folderList2 ) >= 1 )
	
		Prompt folder2, "or choose a folder to locate spike raster subfolder #2:", popup " ;" + folderList2
		DoPrompt promptStr, subfolder1, subfolder2, folder2
	
		if ( V_flag == 1 )
			return ""
		endif
		
		if ( strlen( folder2 ) > 1 )
		
			subfolderList = NMSubfolderList2( folder2, "Spike_", 0, 0 )
			
			if ( ItemsInList( subfolderList ) == 0 )
				DoAlert /T=( promptStr ) 0, "Abort: failed to locate any Spike subfolders in NM folder " + folder2
				return ""
			endif
			
			subfolder2 = StringFromList( 0, subfolderList )
			
			Prompt subfolder2, "select spike raster subfolder #2:", popup subfolderList
			
			DoPrompt promptStr, subfolder2
	
			if ( V_flag == 1 )
				return ""
			endif
			
			subfolder2 = "root:" + folder2 + ":" + subfolder2 + ":"
			
		elseif ( strlen( subfolder2 ) > 1 )
		
			subfolder2 = currentFolder + subfolder2 + ":"
			
		else
		
			DoAlert /T=( promptStr ) 0, "Abort: no selection for spike raster subfolder #2"
			return ""
		
		endif
	
	else
	
		DoPrompt promptStr, subfolder1, subfolder2
	
		if ( V_flag == 1 )
			return ""
		endif
		
		subfolder2 = currentFolder + subfolder2 + ":"
	
	endif
	
	subfolder1 = currentFolder + subfolder1 + ":"
	
	xRasterList1 = NMSpikeSubfolderRasterList( subfolder1, 0, 0 )
	xRasterList2 = NMSpikeSubfolderRasterList( subfolder2, 0, 0 )
	
	if ( ItemsInList( xRasterList1 ) == 0 )
		DoAlert /T=( promptStr ) 0, "Abort: failed to locate any Spike rasters in folder " + subfolder1
		return ""
	endif
	
	if ( ItemsInList( xRasterList2 ) == 0 )
		DoAlert /T=( promptStr ) 0, "Abort: failed to locate any Spike rasters in folder " + subfolder2
		return ""
	endif
	
	xRaster1 = StringFromList( 0, xRasterList1 )
	xRaster2 = StringFromList( 0, xRasterList2 )
	
	Prompt xRaster1, "select spike raster #1:", popup xRasterList1
	Prompt xRaster2, "select spike raster #2:", popup xRasterList2
	
	if ( ( ItemsInList( xRasterList1 ) > 1 ) && ( ItemsInList( xRasterList2 ) > 1 ) )
		
		DoPrompt promptStr, xRaster1, xRaster2
	
		if ( V_flag == 1 )
			return ""
		endif
		
	elseif ( ItemsInList( xRasterList1 ) > 1 )
	
		DoPrompt promptStr, xRaster1
	
		if ( V_flag == 1 )
			return ""
		endif
	
	elseif ( ItemsInList( xRasterList2 ) > 1 )
	
		DoPrompt promptStr, xRaster2
	
		if ( V_flag == 1 )
			return ""
		endif
	
	endif
	
	xRaster1 = subfolder1 + xRaster1
	xRaster2 = subfolder2 + xRaster2
	
	if ( !WaveExists( $xRaster1 ) )
		DoAlert /T=( promptStr ) 0, "Abort: bad fullpath name for raster1 : " + xRaster1
		return ""
	endif
	
	if ( !WaveExists( $xRaster2 ) )
		DoAlert /T=( promptStr ) 0, "Abort: bad fullpath name for raster2 : " + xRaster2
		return ""
	endif
	
	return xRaster1 + ";" + xRaster2 + ";"

End // zCall_NMSpikeSubfolderGet2

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zCall_NMSpikeRasterListGet( promptStr )
	String promptStr
	
	String xRasterList

	String xWaveOrFolder = CurrentNMSpikeRasterOrFolder()
	
	if ( strlen( xWaveOrFolder ) == 0 )
		DoAlert /T=( promptStr ) 0, "There is no Spike Raster selection."
		return ""
	endif
	
	if ( DataFolderExists( xWaveOrFolder ) )
		
		xRasterList = zCall_NMSpikeSubfolderGet( promptStr, xWaveOrFolder )
		
		if ( ItemsInList( xRasterList ) == 0 )
			return ""
		endif
	
	elseif ( WaveExists( $xWaveOrFolder ) )
	
		xRasterList = CurrentNMFolder( 1 ) + xWaveOrFolder
	
	else
	
		DoAlert /T=( promptStr ) 0, "The current Spike Raster selection " + NMQuotes( xWaveOrFolder ) + " does not appear to exist."
		return ""
		
	endif
	
	return xRasterList

End // zCall_NMSpikeRasterListGet

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zCall_NMSpikeSubfolderGet( promptStr, subfolder )
	String promptStr
	String subfolder
	
	Variable icnt
	String xRaster, xRasterList2 = ""
	
	String xRasterList = NMSpikeSubfolderRasterList( subfolder, 0, 0 )
	String currentFolder = CurrentNMFolder( 1 )
	
	if ( ItemsInList( xRasterList ) == 0 )
		return ""
	endif
	
	if ( ItemsInList( xRasterList ) == 1 )
	
		xRaster = StringFromList( 0, xRasterList )
		
		return currentFolder + subfolder + ":" + xRaster
		
	endif

	xRaster = StrVarOrDefault( currentFolder + subfolder + ":RasterXSelect", "" )
	
	if ( strlen( xRaster ) == 0 )
		xRaster = StringFromList( 0, xRasterList )
	endif

	Prompt xRaster, "select spike raster:", popup xRasterList //+ "All;"
	DoPrompt "Spike Raster Plot", xRaster
	
	if ( V_flag == 1 )
		return ""
	endif
	
	SetNMstr( currentFolder + subfolder + ":RasterXSelect", xRaster )
	
	if ( StringMatch( xRaster, "All" ) )
	
		for ( icnt = 0 ; icnt < ItemsInList( xRasterList ) ; icnt += 1 )
			xRasterList2 += currentFolder + subfolder + ":" + StringFromList( icnt, xRasterList ) + ";"
		endfor
		
		return xRasterList2
	
	endif

	return currentFolder + subfolder + ":" + xRaster
	
End // zCall_NMSpikeSubfolderGet

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zCall_NMSpikeRasterPlot()
	
	String folder, promptStr = "Spike Raster Plot"
	
	String xRasterList = zCall_NMSpikeRasterListGet( promptStr )
	
	if ( ItemsInList( xRasterList) == 0 )
		return NM2ErrorStr( 1, "xRasterList", xRasterList )
	endif
	
	Variable xbgn = NMSpikeAnalysisTbgn( xRasterList )
	Variable xend = NMSpikeAnalysisTend( xRasterList )
	
	Prompt xbgn, NMPromptAddUnitsX( "x-axis window begin" )
	Prompt xend, NMPromptAddUnitsX( "x-axis window end" )
	DoPrompt promptStr, xbgn, xend
	
	if ( V_flag == 1 )
		return ""
	endif
	
	folder = StringFromList( 0, xRasterList )
	folder = NMParent( folder, noPath = 1 )
	
	xRasterList = NMChild( xRasterList )
	
	return NMSpikeRasterPlot( folder = folder, xRasterList = xRasterList, xbgn = xbgn, xend = xend, history = 1 )

End // zCall_NMSpikeRasterPlot

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeRasterPlot( [ folder, xRasterList, yRasterList, xbgn, xend, onePlot, hide, history ] )
	String folder // folder or subfolder, pass nothing for current folder
	String xRasterList // x-raster wave list, pass nothing for current x-raster
	String yRasterList // y-raster wave list, pass nothing for automatic search based on x-raster
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	Variable onePlot // ( 0 ) new graph for each raster ( 1 ) one plot for all rasters
	Variable hide // hide raster plot ( 0 ) no ( 1 ) yes
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable icnt, wcnt, vertical, xpnts, ypnts, ymin = inf, ymax = -inf, yAxisOffset = 0.25
	String xRaster, yRaster, wName, wavePrefix, folderPrefix, paramList = ""
	String gName, gList = "", gTitle, yLabel
	
	STRUCT Rect w
	
	NMOutputListsReset()
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	else
		paramList = NMCmdStrOptional( "folder", folder, paramList )
	endif
	
	if ( ParamIsDefault( xRasterList ) )
		xRasterList = ""
	else
		paramList = NMCmdStrOptional( "xRasterList", xRasterList, paramList )
	endif
	
	if ( ParamIsDefault( yRasterList ) )
		yRasterList = ""
	else
		paramList = NMCmdStrOptional( "yRasterList", yRasterList, paramList )
	endif
	
	if ( ParamIsDefault( xbgn ) )
		xbgn = NaN
	else
		paramList = NMCmdNumOptional( "xbgn", xbgn, paramList )
	endif
	
	if ( ParamIsDefault( xend ) )
		xend = NaN
	else
		paramList = NMCmdNumOptional( "xend", xend, paramList )
	endif
	
	if ( history )
		NMCommandHistory( paramList )
	endif
	
	xRasterList = zFullPathRasterXList( folder, xRasterList )
	
	if ( ItemsInList( xRasterList ) == 0 )
		return NM2ErrorStr( 21, "xRasterList", xRasterList )
	endif
	
	xRaster = StringFromList( 0, xRasterList )
	yRaster = StringFromList( 0, yRasterList )
	
	xRaster = CheckNMSpikeRasterXPath( xRaster )
	yRaster = CheckNMSpikeRasterYPath( xRaster, yRaster )
	
	if ( CheckNMSpikeAnalysisWaves( xRaster, yRaster, 0 ) )
		return ""
	endif
	
	if ( numtype( xbgn ) > 0 )
		xbgn = SpikeTmin( xRaster )
	endif
	
	if ( numtype( xend ) > 0 )
		xend = SpikeTmax( xRaster )
	endif
	
	wName = NMChild( xRaster )
	folderPrefix = NMFolderListName( folder )
	gName = "SP_" + folderPrefix + "_" + wName
	gTitle = folderPrefix + " : " + wName
	
	gName = ReplaceString( "SP_RX_", gName, "Rstr_" )
	gName = ReplaceString( "SP_RasterX_", gName, "Rstr_" )
	
	gName = NMCheckStringName( gName )

	DoWindow /K $gName
	
	NMWinCascadeRect( w )
	
	if ( ( strlen( yRaster ) > 0 ) && WaveExists( $yRaster ) )
	
		Display /HIDE=(hide)/K=(NMK())/N=$gName/W=(w.left,w.top,w.right,w.bottom) $yRaster vs $xRaster as gTitle
		
		WaveStats /Q/Z $yRaster
		
		if ( V_min < ymin )
			ymin = V_min
		endif
		
		if ( V_max > ymax )
			ymax = V_max
		endif
		
		wavePrefix = NMNoteStrByKey( xRaster, "Spike Prefix" )
		
		if ( strlen( wavePrefix ) == 0 )
			wavePrefix = "Wave"
		endif
		
		yLabel = NMNoteLabel( "y", yRaster, wavePrefix+" #" )
	
	else
	
		yRaster = ""
	
		Display /HIDE=(hide)/K=(NMK())/N=$gName/W=(w.left,w.top,w.right,w.bottom)/VERT $xRaster as gTitle
		
		vertical = 1
		yLabel = ""
		
	endif
	
	for ( wcnt = 1 ; wcnt < ItemsInList( xRasterList ) ; wcnt += 1 )
	
		xRaster = StringFromList( wcnt, xRasterList )
		yRaster = StringFromList( wcnt, yRasterList )
		
		xRaster = CheckNMSpikeRasterXPath( xRaster )
		yRaster = CheckNMSpikeRasterYPath( xRaster, yRaster )
		
		if ( !WaveExists( $xRaster ) || !WaveExists( $yRaster ) )
			continue
		endif
		
		if ( vertical )
		
			AppendToGraph /W=$gName/VERT $xRaster
		
		else
		
			if ( !WaveExists( $yRaster ) )
				continue
			endif
			
			AppendToGraph /W=$gName $yRaster vs $xRaster
			
			WaveStats /Q/Z $yRaster
			
			if ( V_min < ymin )
				ymin = V_min
			endif
			
			if ( V_max > ymax )
				ymax = V_max
			endif
		
		endif
		
	endfor
	
	if ( ItemsInList( xRasterList ) > 1 )
		GraphRainbow( gName, "" )
	else
		ModifyGraph /W=$gName rgb=(65535,0,0)
	endif
	
	if ( numtype( xbgn * xend ) == 0 )
		SetAxis /W=$gName bottom xbgn, xend
	endif
	
	Label /W=$gName bottom NMNoteLabel( "y", xRaster, "" )
	
	ModifyGraph /W=$gName mode=3, marker=10, standoff( left )=0
	
	if ( vertical )
		Label /W=$gName left yLabel
	else
		SetAxis /W=$gName left ymin-yAxisOffset, ymax+yAxisOffset
		//ModifyGraph /W=$gName manTick( left )={0,1,0,0},manMinor( left )={0,0}
		Label /W=$gName left yLabel
	endif
	
	SetNMstr( NMDF + "OutputWaveList", xRasterList + yRasterList )
	SetNMstr( NMDF + "OutputWinList", gName )
	
	NMHistoryOutputWindows()
	
	return gName

End // NMSpikeRasterPlot

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zCall_NMSpikePSTH()
	
	String folder, xRaster, promptStr = "Peri-Stimulus Time Histogram"
	
	String xRasterList = zCall_NMSpikeRasterListGet( promptStr )
	
	if ( ItemsInList( xRasterList ) == 0 )
		return NM2ErrorStr( 1, "xRasterList", xRasterList )
	endif
	
	Variable xbgn = NMSpikeAnalysisTbgn( xRasterList )
	Variable xend = NMSpikeAnalysisTend( xRasterList )
	Variable binSize = NMSpikeVarGet( "PSTHdelta" )
	String yUnits = NMSpikeStrGet( "PSTHyaxis" )
	String xUnits = zCall_Xunits( xRasterList )
	
	Prompt xbgn, NMPromptAddUnitsX( "x-axis window begin" )
	Prompt xend, NMPromptAddUnitsX( "x-axis window end" )
	Prompt binSize, NMPromptAddUnitsX( "histogram bin size" )
	Prompt yUnits, "y-dimensions to compute:", popup "Spikes/bin;Spikes/s;Spikes/ms;Probability;"
	DoPrompt promptStr, xbgn, xend, binSize, yUnits
		
	if ( V_flag == 1 )
		return ""
	endif
	
	SetNMvar( NMSpikeDF + "PSTHdelta", binSize )
	SetNMstr( NMSpikeDF + "PSTHyaxis", yUnits )
	
	folder = StringFromList( 0, xRasterList )
	folder = NMParent( folder, noPath = 1 )
	
	xRasterList = NMChild( xRasterList )
	
	if ( StringMatch( yUnits, "Spikes/s" ) || StringMatch( yUnits, "Spikes/ms" ) )
		xUnits = zCall_CheckXunits( xUnits )
	else
		xUnits = ""
	endif
	
	if ( strlen( xUnits ) > 0 )
		return NMSpikePSTH( folder = folder, xRasterList = xRasterList, xbgn = xbgn, xend = xend, binSize = binSize, xUnits = xUnits, yUnits = yUnits, history = 1 )
	endif
	
	return NMSpikePSTH( folder = folder, xRasterList = xRasterList, xbgn = xbgn, xend = xend, binSize = binSize, yUnits = yUnits, history = 1 )

End // zCall_NMSpikePSTH

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikePSTH( [ folder, xRasterList, yRasterList, xbgn, xend, binSize, xUnits, yUnits, noGraph, history ] )
	String folder // folder or subfolder, pass nothing for current folder
	String xRasterList // x-raster wave list, pass nothing for current x-raster
	String yRasterList // y-raster wave list, pass nothing for automatic search based on x-raster
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	Variable binSize // histogram bin size
	String xUnits // "ms" or "s" // use this to specify time units if they are not in notes of x-raster wave
	String yUnits // "Spikes/bin" or "Spikes/s" or "Spikes/ms" or "Probability"
	Variable noGraph // ( 0 ) create graph ( 1 ) no graph
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable npnts, reps, yMustExist
	String xRaster, yRaster
	String wName, subfolder, psthName, gName, gTitle, xLabel, paramList = ""
	
	STRUCT Rect w
	
	NMOutputListsReset()
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	else
		paramList = NMCmdStrOptional( "folder", folder, paramList )
	endif
	
	if ( ParamIsDefault( xRasterList ) )
		xRasterList = ""
	else
		paramList = NMCmdStrOptional( "xRasterList", xRasterList, paramList )
	endif
	
	if ( ParamIsDefault( yRasterList ) )
		yRasterList = ""
	else
		paramList = NMCmdStrOptional( "yRasterList", yRasterList, paramList )
	endif
	
	if ( ParamIsDefault( xbgn ) )
		xbgn = NaN
	else
		paramList = NMCmdNumOptional( "xbgn", xbgn, paramList )
	endif
	
	if ( ParamIsDefault( xend ) )
		xend = NaN
	else
		paramList = NMCmdNumOptional( "xend", xend, paramList )
	endif
	
	if ( ParamIsDefault( binSize ) )
		binSize = 1
	else
		paramList = NMCmdNumOptional( "binSize", binSize, paramList )
	endif
	
	if ( ParamIsDefault( xUnits ) )
		xUnits = ""
	else
		paramList = NMCmdStrOptional( "xUnits", xUnits, paramList )
	endif
	
	if ( ParamIsDefault( yUnits ) )
		yUnits = "Spikes/bin"
	else
		paramList = NMCmdStrOptional( "yUnits", yUnits, paramList )
	endif
	
	if ( !ParamIsDefault( noGraph ) )
		paramList = NMCmdNumOptional( "noGraph", noGraph, paramList, integer = 1 )
	endif
	
	if ( history )
		NMCommandHistory( paramList )
	endif
	
	yUnits = zCall_CheckYunits( yUnits )
	
	strswitch( yUnits )
		case "Probability":
		case "Spikes/s":
		case "Spikes/ms":
			yMustExist = 1
	endswitch
	
	xRasterList = zFullPathRasterXList( folder, xRasterList )
	
	if ( ItemsInList( xRasterList ) == 0 )
		return NM2ErrorStr( 21, "xRasterList", xRasterList )
	endif
	
	xRaster = StringFromList( 0, xRasterList ) // implement loop here
	yRaster = StringFromList( 0, yRasterList )
	
	xRaster = CheckNMSpikeRasterXPath( xRaster )
	yRaster = CheckNMSpikeRasterYPath( xRaster, yRaster )
	
	if ( CheckNMSpikeAnalysisWaves( xRaster, yRaster, yMustExist ) )
		return ""
	endif
	
	if ( ( numtype( binSize ) > 0 ) || ( binSize <= 0 ) )
		return NM2ErrorStr( 10, "binSize", num2str( binSize ) )
	endif
	
	xLabel = NMNoteLabel( "y", xRaster, "" )
	
	wName = NMChild( xRaster )
	subfolder = NMParent( xRaster )
	
	if ( StringMatch( NMSpikeStrGet( "WaveNamingFormat" ), "suffix" ) )
		psthName = wName + "_PSTH"
	else
		psthName = "PSTH_" + wName
	endif
	
	psthName = NMCheckStringName( psthName )
	
	gName = "SP_" + CurrentNMFolderPrefix() + psthName
	gTitle = NMFolderListName( "" ) + " : " + psthName
	
	gName = NMCheckStringName( gName )
	
	if ( numtype( xbgn ) > 0 )
		xbgn = SpikeTmin( xRaster )
	endif
	
	if ( numtype( xend ) > 0 )
		xend = SpikeTmax( xRaster )
	endif
	
	npnts = ceil( ( xend - xbgn ) / binSize )
	
	if ( strlen( subfolder ) > 0 )
		psthName = subfolder + psthName
	endif
	
	Make /O/N=1 $psthName
	
	Histogram /B={ xbgn, binSize, npnts } $xRaster, $psthName
	
	if ( !WaveExists( $psthName ) )
		return "" // failed to create histogram
	endif
	
	Wave PSTH = $psthName
	
	strswitch( yUnits )
	
		case "Probability":
			
			reps = SpikeRasterCountReps( yRaster )
			
			if ( ( numtype( reps ) == 0 ) && ( reps > 0 ) )
				PSTH /= reps
			else
				yUnits = "Spikes/bin"
			endif
		
			break
		
		case "Spikes/s":
			
			reps = SpikeRasterCountReps( yRaster )
			
			if ( ( numtype( reps ) == 0 ) && ( reps > 0 ) )
			
				PSTH /= reps * binSize
				
				if ( strlen( xUnits ) == 0 )
					xUnits = NMNoteLabel( "y", xRaster, "time unit" )
				endif
				
				strswitch( xUnits )
					case "ms":
					case "msec":
					PSTH *= 1000 // time conversion
				endswitch
				
			else
			
				yUnits = "Spikes/bin"
				
			endif
			
			break
			
		case "Spikes/ms":
		
			reps = SpikeRasterCountReps( yRaster )
			
			if ( ( numtype( reps ) == 0 ) && ( reps > 0 ) )
			
				PSTH /= reps * binSize
				
				if ( strlen( xUnits ) == 0 )
					xUnits = NMNoteLabel( "y", xRaster, "time unit" )
				endif
				
				strswitch( xUnits )
					case "s":
					case "sec":
					PSTH *= 0.001 // time conversion
				endswitch
				
			else
			
				yUnits = "Spikes/bin"
				
			endif
			
			break
			
		default:
		
			yUnits = "Spikes/bin"
			
	endswitch
	
	NMNoteType( psthName, "Spike PSTH", xLabel, yUnits, "_FXN_" )
	Note $psthName, "PSTH Bin:" + num2str( binSize ) + ";PSTH Xbgn:" + num2str( xbgn ) + ";PSTH Xend:" + num2str( xend ) + ";"
	Note $psthName, "PSTH xRaster:" + xRaster
	Note $psthName, "PSTH yRaster:" + yRaster
	
	SetNMstr( NMDF + "OutputWaveList", psthName )
	
	if ( !noGraph )
	
		DoWindow /K $gName
		
		NMWinCascadeRect( w )
	
		Display /K=(NMK())/N=$gName/W=(w.left,w.top,w.right,w.bottom) PSTH as gTitle
		
		SetAxis /W=$gName bottom xbgn, xend
		ModifyGraph /W=$gName standoff=0, rgb=(0,0,0), mode=5, hbFill=2
		
		Label /W=$gName bottom xLabel
		Label /W=$gName left yUnits
		
		SetNMstr( NMDF + "OutputWinList", gName )
	
	endif
	
	NMHistoryOutputWaves()
	NMHistoryOutputWindows()
	
	return psthName

End // NMSpikePSTH

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zCall_NMSpikePSTHJoint()

	Variable xbgn, xend, binSize
	String xRasterList, folder, xUnits, yUnits
	
	String xWaveOrFolder = CurrentNMSpikeRasterOrFolder()
	String promptStr = "Joint Peri-Stimulus Time Histogram"
	
	if ( strlen( xWaveOrFolder ) == 0 )
		DoAlert /T=( promptStr ) 0, "There is no Spike Raster selection."
		return ""
	endif
	
	if ( DataFolderExists( xWaveOrFolder ) )
		xRasterList = zCall_NMSpikeSubfolderGet2( promptStr, xWaveOrFolder )
	elseif ( WaveExists( $xWaveOrFolder ) )
		xRasterList = zCall_NMSpikeRasterGet2( promptStr, xWaveOrFolder )
	else
		DoAlert /T=( promptStr ) 0, "The current Spike Raster selection " + NMQuotes( xWaveOrFolder ) + " does not appear to exist."
		return ""
	endif
	
	if ( ItemsInList( xRasterList ) != 2 )
		return ""
	endif
	
	xbgn = NMSpikeAnalysisTbgn( xRasterList )
	xend = NMSpikeAnalysisTend( xRasterList )
	binSize = NMSpikeVarGet( "PSTHdelta" )
	yUnits = NMSpikeStrGet( "PSTHyaxis" )
	xUnits = zCall_Xunits( xRasterList )
	
	Prompt xbgn, NMPromptAddUnitsX( "x-axis window begin" )
	Prompt xend, NMPromptAddUnitsX( "x-axis window end" )
	Prompt binSize, NMPromptAddUnitsX( "histogram bin size" )
	Prompt yUnits, "y-dimensions to compute:", popup "Spikes/bin;Spikes/s;Spikes/ms;Probability;"
	DoPrompt "Joint Peri-Stimulus Time Histogram", xbgn, xend, binSize, yUnits
		
	if ( V_flag == 1 )
		return ""
	endif
	
	SetNMvar( NMSpikeDF + "PSTHdelta", binSize )
	SetNMstr( NMSpikeDF + "PSTHyaxis", yUnits )
	
	folder = NMParent( xRasterList, noDuplications = 1 )
	
	if ( ItemsInList( folder ) == 1 ) // rasters are in same folder
		folder = NMChild( folder )
		xRasterList = NMChild( xRasterList )
	else
		folder = ""
	endif
	
	if ( StringMatch( yUnits, "Spikes/s" ) || StringMatch( yUnits, "Spikes/ms" ) )
		xUnits = zCall_CheckXunits( xUnits )
	else
		xUnits = ""
	endif
	
	if ( strlen( xUnits ) > 0 )
		if ( strlen( folder ) > 0 )
			return NMSpikePSTHJoint( folder = folder, xRasterList = xRasterList, xbgn = xbgn, xend = xend, binSize = binSize, xUnits = xUnits, yUnits = yUnits, history = 1 )
		else
			return NMSpikePSTHJoint( xRasterList = xRasterList, xbgn = xbgn, xend = xend, binSize = binSize, xUnits = xUnits, yUnits = yUnits, history = 1 )
		endif
	endif
	
	if ( strlen( folder ) > 0 )
		return NMSpikePSTHJoint( folder = folder, xRasterList = xRasterList, xbgn = xbgn, xend = xend, binSize = binSize, yUnits = yUnits, history = 1 )
	else
		return NMSpikePSTHJoint( xRasterList = xRasterList, xbgn = xbgn, xend = xend, binSize = binSize, yUnits = yUnits, history = 1 )
	endif
	
End // zCall_NMSpikePSTHJoint

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikePSTHJoint( [ folder, xRasterList, yRasterList, xbgn, xend, binSize, xUnits, yUnits, noGraph, history ] )
	String folder // folder or subfolder, pass nothing for current folder
	String xRasterList // x-raster wave list, pass nothing for current x-raster
	String yRasterList // y-raster wave list, pass nothing for automatic search based on xRaster
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	Variable binSize // histogram bin size
	String xUnits // "ms" or "s" // use this to specify time units if they are not in notes of x-raster wave
	String yUnits // "Spikes/bin" or "Spikes/s" or "Spikes/ms" or "Probability"
	Variable noGraph // ( 0 ) create graph ( 1 ) no graph
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable npnts, reps, yMustExist, wcnt, wbgn, wend, icnt, jcnt, xpnt, ypnt
	String xRaster1, yRaster1, xRaster2, yRaster2, wName, wNameShort, paramList = ""
	String subfolder, psthName2D, psthName1D, gName1, gName2, gTitle, xLabel1, xLabel2
	
	STRUCT Rect w
	
	NMOutputListsReset()
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	else
		paramList = NMCmdStrOptional( "folder", folder, paramList )
	endif
	
	if ( ParamIsDefault( xRasterList ) )
		xRasterList = ""
	else
		paramList = NMCmdStrOptional( "xRasterList", xRasterList, paramList )
	endif
	
	if ( ParamIsDefault( yRasterList ) )
		yRasterList = ""
	else
		paramList = NMCmdStrOptional( "yRasterList", yRasterList, paramList )
	endif
	
	if ( ParamIsDefault( xbgn ) )
		xbgn = NaN
	else
		paramList = NMCmdNumOptional( "xbgn", xbgn, paramList )
	endif
	
	if ( ParamIsDefault( xend ) )
		xend = NaN
	else
		paramList = NMCmdNumOptional( "xend", xend, paramList )
	endif
	
	if ( ParamIsDefault( binSize ) )
		binSize = 1
	else
		paramList = NMCmdNumOptional( "binSize", binSize, paramList )
	endif
	
	if ( ParamIsDefault( xUnits ) )
		xUnits = ""
	else
		paramList = NMCmdStrOptional( "xUnits", xUnits, paramList )
	endif
	
	if ( ParamIsDefault( yUnits ) )
		yUnits = "Spikes/bin"
	else
		paramList = NMCmdStrOptional( "yUnits", yUnits, paramList )
	endif
	
	if ( !ParamIsDefault( noGraph ) )
		paramList = NMCmdNumOptional( "noGraph", noGraph, paramList, integer = 1 )
	endif
	
	if ( history )
		NMCommandHistory( paramList )
	endif
	
	yUnits = zCall_CheckYunits( yUnits )
	
	strswitch( yUnits )
		case "Probability":
		case "Spikes/s":
		case "Spikes/ms":
			yMustExist = 1
	endswitch
	
	xRasterList = zFullPathRasterXList( folder, xRasterList )
	
	if ( ItemsInList( xRasterList ) < 2 ) // need at last 2 waves
		return NM2ErrorStr( 21, "xRasterList", xRasterList )
	endif
	
	xRaster1 = StringFromList( 0, xRasterList )
	yRaster1 = StringFromList( 0, yRasterList )
	
	xRaster1 = CheckNMSpikeRasterXPath( xRaster1 )
	yRaster1 = CheckNMSpikeRasterYPath( xRaster1, yRaster1 )
	
	if ( CheckNMSpikeAnalysisWaves( xRaster1, yRaster1, yMustExist ) )
		return ""
	endif
	
	xRaster2 = StringFromList( 1, xRasterList ) // implement loop here
	yRaster2 = StringFromList( 1, yRasterList )
	
	xRaster2 = CheckNMSpikeRasterXPath( xRaster2 )
	yRaster2 = CheckNMSpikeRasterYPath( xRaster2, yRaster2 )
	
	if ( CheckNMSpikeAnalysisWaves( xRaster2, yRaster2, yMustExist ) )
		return ""
	endif
	
	if ( ( numtype( binSize ) > 0 ) || ( binSize <= 0 ) )
		return NM2ErrorStr( 10, "binSize", num2str( binSize ) )
	endif
	
	xLabel1 = NMNoteLabel( "y", xRaster1, "" )
	xLabel2 = NMNoteLabel( "y", xRaster2, "" )
	
	wName = NMChild( xRaster1 )
	subfolder = NMParent( xRaster1 )
	
	if ( StringMatch( NMSpikeStrGet( "WaveNamingFormat" ), "suffix" ) )
		psthName2D = wName + "_JPSTH2"
	else
		psthName2D = "JPSTH2_" + wName
	endif
	
	psthName2D = NMCheckStringName( psthName2D )
	
	if ( strlen( subfolder ) > 0 )
		psthName2D = subfolder + psthName2D
	endif
	
	if ( numtype( xbgn ) > 0 )
		xbgn = SpikeTmin( xRaster1 )
	endif
	
	if ( numtype( xend ) > 0 )
		xend = SpikeTmax( xRaster1 )
	endif
	
	npnts = ceil( ( xend - xbgn ) / binSize )
	
	Make /O/N=( npnts, npnts ) $psthName2D = 0
	SetScale /P x xbgn, binSize, $psthName2D
	SetScale /P y xbgn, binSize, $psthName2D
	
	Wave JPSTH = $psthName2D
	
	Wave rx1 = $xRaster1
	Wave ry1 = $yRaster1
	
	Wave rx2 = $xRaster2
	Wave ry2 = $yRaster2
	
	WaveStats /Q ry1
	
	wbgn = V_min
	wend = V_max
	
	for ( wcnt = wbgn ; wcnt <= wend ; wcnt += 1 ) // wave counter
	
		for ( icnt = 0 ; icnt < numpnts( ry1 ) ; icnt += 1 )
	
			if ( ( numtype( ry1[ icnt ] ) > 0 ) || ( ry1[ icnt ] != wcnt ) )
				continue
			endif
			
			xpnt = floor ( ( rx1[ icnt ] - xbgn ) / binSize )
			
			if ( ( xpnt < 0 ) || ( xpnt >= npnts ) )
				continue
			endif
			
			for ( jcnt = 0 ; jcnt < numpnts( ry2 ) ; jcnt += 1 )
			
				if ( ( numtype( ry2[ jcnt ] ) > 0 ) || ( ry2[ jcnt ] != wcnt ) )
					continue
				endif
				
				ypnt = floor( ( rx2[ jcnt ] - xbgn ) / binSize )
				
				if ( ( ypnt < 0 ) || ( ypnt >= npnts ) )
					continue
				endif
				
				JPSTH[ xpnt ][ ypnt ] += 1
			
			endfor
	
		endfor
	
	endfor
	
	if ( StringMatch( NMSpikeStrGet( "WaveNamingFormat" ), "suffix" ) )
		psthName1D = wName + "_JPSTH1"
	else
		psthName1D = "JPSTH1_" + wName
	endif
	
	psthName1D = NMCheckStringName( psthName1D )
	
	if ( strlen( subfolder ) > 0 )
		psthName1D = subfolder + psthName1D
	endif
	
	Make /O/N=( npnts ) $psthName1D = 0
	SetScale /P x xbgn, binSize, $psthName1D
	
	Wave JPSTH2 = $psthName1D
	
	for ( icnt = 0 ; icnt < npnts ; icnt += 1 )
		JPSTH2[ icnt ] = JPSTH[ icnt ][ icnt ]
	endfor
	
	strswitch( yUnits )
	
		case "Probability":
			
			reps = SpikeRasterCountReps( yRaster1 )
			
			if ( ( numtype( reps ) == 0 ) && ( reps > 0 ) )
				JPSTH /= reps
				JPSTH2 /= reps
			else
				yUnits = "Spikes/bin"
			endif
		
			break
		
		case "Spikes/s":
			
			reps = SpikeRasterCountReps( yRaster1 )
			
			if ( ( numtype( reps ) == 0 ) && ( reps > 0 ) )
			
				JPSTH /= reps * binSize
				JPSTH2 /= reps * binSize
				
				if ( strlen( xUnits ) == 0 )
					xUnits = NMNoteLabel( "y", xRaster1, "time unit" )
				endif
				
				strswitch( xUnits )
					case "ms":
					case "msec":
						JPSTH *= 1000 // time conversion
						JPSTH2 *= 1000
				endswitch
				
			else
			
				yUnits = "Spikes/bin"
				
			endif
			
			break
			
		case "Spikes/ms":
			
			reps = SpikeRasterCountReps( yRaster1 )
			
			if ( ( numtype( reps ) == 0 ) && ( reps > 0 ) )
			
				JPSTH /= reps * binSize
				JPSTH2 /= reps * binSize
				
				
				if ( strlen( xUnits ) == 0 )
					xUnits = NMNoteLabel( "y", xRaster1, "time unit" )
				endif
				
				strswitch( xUnits )
					case "s":
					case "sec":
						JPSTH *= 0.001 // time conversion
						JPSTH2 *= 0.001
				endswitch
				
			else
			
				yUnits = "Spikes/bin"
				
			endif
			
			break
			
		default:
		
			yUnits = "Spikes/bin"
			
	endswitch
	
	NMNoteType( psthName2D, "Spike JPSTH", xLabel1, yUnits, "_FXN_" )
	Note $psthName2D, "JPSTH Bin:" + num2str( binSize ) + ";JPSTH Xbgn:" + num2str( xbgn ) + ";JPSTH Xend:" + num2str( xend ) + ";"
	Note $psthName2D, "JPSTH xRaster1:" + xRaster1
	Note $psthName2D, "JPSTH yRaster1:" + yRaster1
	Note $psthName2D, "JPSTH xRaster2:" + xRaster2
	Note $psthName2D, "JPSTH yRaster2:" + yRaster2
	
	NMNoteType( psthName1D, "Spike JPSTH", xLabel1, yUnits, "_FXN_" )
	Note $psthName1D, "JPSTH Bin:" + num2str( binSize ) + ";JPSTH Xbgn:" + num2str( xbgn ) + ";JPSTH Xend:" + num2str( xend ) + ";"
	Note $psthName1D, "JPSTH xRaster1:" + xRaster1
	Note $psthName1D, "JPSTH yRaster1:" + yRaster1
	Note $psthName1D, "JPSTH xRaster2:" + xRaster2
	Note $psthName1D, "JPSTH yRaster2:" + yRaster2
	
	SetNMstr( NMDF + "OutputWaveList", psthName2D + ";" + psthName1D + ";" )
	
	if ( !noGraph )
	
		wNameShort = NMChild( psthName2D )
	
		gName1 = "SP_" + CurrentNMFolderPrefix() + wNameShort
		gTitle = NMFolderListName( "" ) + " : " + wNameShort
	
		gName1 = NMCheckStringName( gName1 )
	
		DoWindow /K $gName1
		NewImage /F/K=(NMK())/N=$gName1 JPSTH
		DoWindow /T $gName1, gTitle
		ModifyImage /W=$gName1 $wNameShort ctab={*,*,YellowHot,0}
		ModifyGraph margin=28
		
		Label /W=$gName1 bottom "Raster #1 " + xLabel1
		Label /W=$gName1 left "Raster #2 " + xLabel2
		
		wNameShort = NMChild( psthName1D )
	
		gName2 = "SP_" + CurrentNMFolderPrefix() + wNameShort
		gTitle = NMFolderListName( "" ) + " : " + wNameShort
	
		gName2 = NMCheckStringName( gName2 )
		
		NMWinCascadeRect( w )
		
		DoWindow /K $gName2
		Display /K=(NMK())/N=$gName2/W=(w.left,w.top,w.right,w.bottom) JPSTH2 as gTitle
		
		SetAxis /W=$gName2 bottom xbgn, xend
		ModifyGraph /W=$gName2 standoff=0, rgb=(0,0,0), mode=5, hbFill=2
		
		Label /W=$gName2 bottom xLabel1
		Label /W=$gName2 left yUnits
		
		SetNMstr( NMDF + "OutputWinList", gName1 + ";" + gName2 + ";" )
	
	endif
	
	return psthName2D + ";" + psthName1D + ";"

End // NMSpikePSTHJoint

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zCall_NMSpikeISIH()
	
	String folder, promptStr = "InterSpike Interval Histogram"
	
	String xRasterList = zCall_NMSpikeRasterListGet( promptStr )
	
	if ( ItemsInList( xRasterList) == 0 )
		return NM2ErrorStr( 1, "xRasterList", xRasterList )
	endif
	
	Variable xbgn = NMSpikeAnalysisTbgn( xRasterList )
	Variable xend = NMSpikeAnalysisTend( xRasterList )
	Variable minInterval = 0
	Variable maxInterval = inf
	Variable binSize = NMSpikeVarGet( "ISIHdelta" )
	String yUnits = NMSpikeStrGet( "ISIHyaxis" )
	String xUnits = zCall_Xunits( xRasterList )
	
	Prompt xbgn, NMPromptAddUnitsX( "x-axis window begin" )
	Prompt xend, NMPromptAddUnitsX( "x-axis window end" )
	Prompt minInterval, "minimum allowed interval:"
	Prompt maxInterval, "maximum allowed interval:"
	Prompt binSize, NMPromptAddUnitsX( "histogram bin size" )
	Prompt yUnits, "y-dimensions to compute:", popup "Intervals/bin;Intervals/s;Intervals/ms;Probability"
	
	DoPrompt promptStr, xbgn, xend, binSize, yUnits
		
	if ( V_flag == 1 )
		return ""
	endif
	
	DoPrompt promptStr, minInterval, maxInterval
		
	if ( V_flag == 1 )
		return ""
	endif
	
	SetNMvar( NMSpikeDF + "ISIHdelta", binSize )
	SetNMstr( NMSpikeDF + "ISIHyaxis", yUnits )
	
	folder = StringFromList( 0, xRasterList )
	folder = NMParent( folder, noPath = 1 )
	
	xRasterList = NMChild( xRasterList )
	
	if ( StringMatch( yUnits, "Intervals/s" ) || StringMatch( yUnits, "Intervals/ms" ) )
		xUnits = zCall_CheckXunits( xUnits )
	else
		xUnits = ""
	endif
	
	if ( strlen( xUnits ) > 0 )
		return NMSpikeISIH( folder = folder, xRasterList = xRasterList, xbgn = xbgn, xend = xend, minInterval = minInterval, maxInterval = maxInterval, binSize = binSize, xUnits = xUnits, yUnits = yUnits, history = 1 )
	endif
	
	return NMSpikeISIH( folder = folder, xRasterList = xRasterList, xbgn = xbgn, xend = xend, minInterval = minInterval, maxInterval = maxInterval, binSize = binSize, yUnits = yUnits, history = 1 )

End // zCall_NMSpikeISIH

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeISIH( [ folder, xRasterList, xbgn, xend, minInterval, maxInterval, binSize, xUnits, yUnits, noGraph, history ] )
	String folder // folder or subfolder, pass nothing for current folder
	String xRasterList // x-raster wave, pass nothing for current x-raster
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	Variable minInterval // minimum allowed interval ( 0 ) for no lower limit
	Variable maxInterval // maximum allowed interval ( inf ) for no upper limit
	Variable binSize // histogram bin size
	String xUnits // "ms" or "s" // use this to specify time units if they are not in notes of x-raster wave
	String yUnits // "Intervals/bin" or "Intervals/s" or "Intervals/ms" or "Probability"
	Variable noGraph // ( 0 ) create graph ( 1 ) no graph
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable events, npnts
	String xRaster, xLabel, wName, subfolder, ISIHname, intvlsName, gName, gTitle, paramList = ""
	
	STRUCT Rect w
	
	NMOutputListsReset()
	
	if ( ParamIsDefault( folder ) )
		folder = CurrentNMFolder( 1 )
	else
		paramList = NMCmdStrOptional( "folder", folder, paramList )
	endif
	
	if ( ParamIsDefault( xRasterList ) )
		xRasterList = ""
	else
		paramList = NMCmdStrOptional( "xRasterList", xRasterList, paramList )
	endif
	
	if ( ParamIsDefault( xbgn ) )
		xbgn = NaN
	else
		paramList = NMCmdNumOptional( "xbgn", xbgn, paramList )
	endif
	
	if ( ParamIsDefault( xend ) )
		xend = NaN
	else
		paramList = NMCmdNumOptional( "xend", xend, paramList )
	endif
	
	if ( ParamIsDefault( minInterval ) )
		minInterval = 0
	else
		paramList = NMCmdNumOptional( "minInterval", minInterval, paramList )
	endif
	
	if ( ParamIsDefault( maxInterval ) )
		maxInterval = inf
	else
		paramList = NMCmdNumOptional( "maxInterval", maxInterval, paramList )
	endif
	
	if ( ParamIsDefault( binSize ) )
		binSize = 1
	else
		paramList = NMCmdNumOptional( "binSize", binSize, paramList )
	endif
	
	if ( ParamIsDefault( xUnits ) )
		xUnits = ""
	else
		paramList = NMCmdStrOptional( "xUnits", xUnits, paramList )
	endif
	
	if ( ParamIsDefault( yUnits ) )
		yUnits = "Intervals/bin"
	else
		paramList = NMCmdStrOptional( "yUnits", yUnits, paramList )
	endif
	
	if ( !ParamIsDefault( noGraph ) )
		paramList = NMCmdNumOptional( "noGraph", noGraph, paramList, integer = 1 )
	endif
	
	if ( history )
		NMCommandHistory( paramList )
	endif
	
	xRasterList = zFullPathRasterXList( folder, xRasterList )
	
	if ( ItemsInList( xRasterList ) == 0 )
		return NM2ErrorStr( 21, "xRasterList", xRasterList )
	endif
	
	xRaster = StringFromList( 0, xRasterList ) // implement loop here
	xRaster = CheckNMSpikeRasterXPath( xRaster )
	
	if ( !WaveExists( $xRaster ) )
		return NM2ErrorStr( 1, "xRaster", xRaster )
	endif
	
	if ( numtype( xbgn ) > 0 )
		xbgn = SpikeTmin( xRaster )
	endif
	
	if ( numtype( xend ) > 0 )
		xend = SpikeTmax( xRaster )
	endif
	
	if ( ( numtype( binSize ) > 0 ) || ( binSize <= 0 ) )
		return NM2ErrorStr( 10, "binSize", num2str( binSize ) )
	endif
	
	if ( ( numtype( minInterval ) > 0 ) || ( minInterval < 0 ) )
		minInterval = 0
	endif
	
	if ( ( numtype( maxInterval ) == 2 ) || ( maxInterval <= 0 ) )
		maxInterval = inf
	endif
	
	xLabel = NMNoteLabel( "y", xRaster, "" )
	
	events = Time2Intervals( xRaster, xbgn, xend, minInterval, maxInterval ) // results saved in U_INTVLS
	
	wName = NMChild( xRaster )
	subfolder = NMParent( xRaster )
		
	if ( ( events <= 0 ) || !WaveExists( $"U_INTVLS" ) )
		NMDoAlert( GetRTStackInfo( 1 ) + " Alert: no interspike intervals detected for raster wave " + wName )
		return ""
	endif
	
	if ( StringMatch( NMSpikeStrGet( "WaveNamingFormat" ), "suffix" ) )
		intvlsName = wName + "_Intvls"
		ISIHname = wName + "_ISIH"
	else
		intvlsName = "Intvls_" + wName
		ISIHname = "ISIH_" + wName
	endif
	
	ISIHname = NMCheckStringName( ISIHname )
	
	if ( strlen( subfolder ) > 0 )
		intvlsName = subfolder + intvlsName
		ISIHname = subfolder + ISIHname
	endif
	
	Wave U_INTVLS
	
	WaveStats /Q/Z U_INTVLS
	
	npnts = 2 + ( V_max - V_min ) / binSize
	
	Make /O/N=1 $ISIHname
	
	Histogram /B={ minInterval, binSize, npnts } U_INTVLS, $ISIHname
	
	Wave ISIH = $ISIHname
	
	Duplicate /O U_INTVLS $intvlsName
	
	yUnits = zCall_CheckYunits( yUnits )
	
	strswitch( yUnits )
	
		case "Probability":
			ISIH /= events
			break
			
		case "Intervals/s":
		
			ISIH /= binSize
			
			if ( strlen( xUnits ) == 0 )
				xUnits = NMNoteLabel( "y", xRaster, "time unit" )
			endif
			
			strswitch( xUnits )
				case "ms":
				case "msec":
					ISIH *= 1000 // time conversion
			endswitch
			
			break
			
		case "Intervals/ms":
		
			ISIH /= binSize
			
			if ( strlen( xUnits ) == 0 )
				xUnits = NMNoteLabel( "y", xRaster, "time unit" )
			endif
			
			strswitch( xUnits )
				case "s":
				case "sec":
					ISIH *= 0.001 // time conversion
			endswitch
			
			break
	
		default:
		
			yUnits = "Intervals/bin"
			
	endswitch
	
	NMNoteType( intvlsName, "Spike Intervals", xLabel, yUnits, "_FXN_" )
	Note $intvlsName, "ISIH Bin:" + num2str( binSize ) + ";ISIH Xbgn:" + num2str( xbgn ) + ";ISIH Xend:" + num2str( xend ) + ";"
	Note $intvlsName, "ISIH Min:" + num2str( minInterval ) + ";ISIH Max:" + num2str( maxInterval ) + ";"
	Note $intvlsName, "ISIH xRaster:" + xRaster
	
	NMNoteType( ISIHname, "Spike ISIH", xLabel, yUnits, "_FXN_" )
	Note $ISIHname, "ISIH Bin:" + num2str( binSize ) + ";ISIH Xbgn:" + num2str( xbgn ) + ";ISIH Xend:" + num2str( xend ) + ";"
	Note $ISIHname, "ISIH Min:" + num2str( minInterval ) + ";ISIH Max:" + num2str( maxInterval ) + ";"
	Note $ISIHname, "ISIH xRaster:" + xRaster
	
	SetNMstr( NMDF + "OutputWaveList", intvlsName + ";" + ISIHname + ";" )
	
	if ( !noGraph )
	
		gName = "SP_" + CurrentNMFolderPrefix() + ISIHname
		gName = NMCheckStringName( gName )
		
		gTitle = NMFolderListName( "" ) + " : " + ISIHname
	
		NMWinCascadeRect( w )
	
		DoWindow /K $gName
	
		Display /K=(NMK())/N=$gName/W=(w.left,w.top,w.right,w.bottom) ISIH as gTitle
	
		ModifyGraph /W=$gName standoff=0, rgb=(0,0,0), mode=5, hbFill=2
		Label /W=$gName bottom xLabel
		Label /W=$gName left yUnits
		SetAxis /A/W=$gName
		
		SetNMstr( NMDF + "OutputWinList", gName )
		
	endif
	
	NMHistoryOutputWaves()
	NMHistoryOutputWindows()
	
	KillWaves /Z U_INTVLS
	
	return ISIHname
	
End // NMSpikeISIH

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zCall_NMSpikeISIHJoint()

	String xRasterList, folder, promptStr = "Joint Inter-Spike Interval Histogram"
	
	String xWaveOrFolder = CurrentNMSpikeRasterOrFolder()
	
	if ( strlen( xWaveOrFolder ) == 0 )
		DoAlert /T=( promptStr ) 0, "There is no Spike Raster selection."
		return ""
	endif
	
	if ( DataFolderExists( xWaveOrFolder ) )
		xRasterList = zCall_NMSpikeSubfolderGet2( promptStr, xWaveOrFolder )
	elseif ( WaveExists( $xWaveOrFolder ) )
		xRasterList = zCall_NMSpikeRasterGet2( promptStr, xWaveOrFolder )
	else
		DoAlert /T=( promptStr ) 0, "The current Spike Raster selection " + NMQuotes( xWaveOrFolder ) + " does not appear to exist."
		return ""
	endif
	
	if ( ItemsInList( xRasterList ) != 2 )
		return ""
	endif
	
	Variable xbgn = NMSpikeAnalysisTbgn( xRasterList )
	Variable xend = NMSpikeAnalysisTend( xRasterList )
	Variable binSize = NMSpikeVarGet( "ISIHdelta" )
	String yUnits = NMSpikeStrGet( "ISIHyaxis" )
	String xUnits = zCall_Xunits( xRasterList )
	
	Prompt xbgn, NMPromptAddUnitsX( "x-axis window begin" )
	Prompt xend, NMPromptAddUnitsX( "x-axis window end" )
	Prompt binSize, NMPromptAddUnitsX( "histogram bin size" )
	Prompt yUnits, "y-dimensions to compute:", popup "Intervals/bin;Intervals/s;Intervals/ms;Probability;"
	
	DoPrompt promptStr, xbgn, xend, binSize, yUnits
		
	if ( V_flag == 1 )
		return ""
	endif
	
	SetNMvar( NMSpikeDF + "ISIHdelta", binSize )
	SetNMstr( NMSpikeDF + "ISIHyaxis", yUnits )
	
	folder = NMParent( xRasterList, noDuplications = 1 )
	
	if ( ItemsInList( folder ) == 1 ) // rasters are in same folder
		folder = NMChild( folder )
		xRasterList = NMChild( xRasterList )
	else
		folder = ""
	endif
	
	if ( StringMatch( yUnits, "Intervals/s" ) || StringMatch( yUnits, "Intervals/ms" ) )
		xUnits = zCall_CheckXunits( xUnits )
	else
		xUnits = ""
	endif
	
	if ( strlen( xUnits ) > 0 )
		if ( strlen( folder ) > 0 )
			return NMSpikeISIHJoint( folder = folder, xRasterList = xRasterList, xbgn = xbgn, xend = xend, binSize = binSize, xUnits = xUnits, yUnits = yUnits, history = 1 )
		else
			return NMSpikeISIHJoint( xRasterList = xRasterList, xbgn = xbgn, xend = xend, binSize = binSize, xUnits = xUnits, yUnits = yUnits, history = 1 )
		endif
	endif
	
	if ( strlen( folder ) > 0 )
		return NMSpikeISIHJoint( folder = folder, xRasterList = xRasterList, xbgn = xbgn, xend = xend, binSize = binSize, yUnits = yUnits, history = 1 )
	else
		return NMSpikeISIHJoint( xRasterList = xRasterList, xbgn = xbgn, xend = xend, binSize = binSize, yUnits = yUnits, history = 1 )
	endif

End // zCall_NMSpikeISIHJoint

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeISIHJoint( [ folder, xRasterList, yRasterList, xbgn, xend, binSize, xUnits, yUnits, noGraph, history ] )
	String folder // folder or subfolder, pass nothing for current folder
	String xRasterList // x-raster wave, pass nothing for current x-raster
	String yRasterList // y-raster wave list, pass nothing for automatic search based on xRaster
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	Variable binSize // histogram bin size
	String xUnits // "ms" or "s" // use this to specify time units if they are not in notes of x-raster wave
	String yUnits // "Intervals/bin" or "Intervals/s" or "Intervals/ms" or "Probability"
	Variable noGraph // ( 0 ) create graph ( 1 ) no graph
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable yMustExist = 1
	Variable npnts, wcnt, wbgn, wend, icnt, jcnt, kcnt, interval
	String xRaster1, yRaster1, xRaster2, yRaster2, wName, subfolder, paramList = ""
	String ISIHname, intvlsName, gName, gTitle, xLabel, wNameShort
	String thisFxn = GetRTStackInfo( 1 )
	
	STRUCT Rect w
	
	NMOutputListsReset()
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	else
		paramList = NMCmdStrOptional( "folder", folder, paramList )
	endif
	
	if ( ParamIsDefault( xRasterList ) )
		xRasterList = ""
	else
		paramList = NMCmdStrOptional( "xRasterList", xRasterList, paramList )
	endif
	
	if ( ParamIsDefault( yRasterList ) )
		yRasterList = ""
	else
		paramList = NMCmdStrOptional( "yRasterList", yRasterList, paramList )
	endif
	
	if ( ParamIsDefault( xbgn ) )
		xbgn = NaN
	else
		paramList = NMCmdNumOptional( "xbgn", xbgn, paramList )
	endif
	
	if ( ParamIsDefault( xend ) )
		xend = NaN
	else
		paramList = NMCmdNumOptional( "xend", xend, paramList )
	endif
	
	if ( ParamIsDefault( binSize ) )
		binSize = 1
	else
		paramList = NMCmdNumOptional( "binSize", binSize, paramList )
	endif
	
	if ( ParamIsDefault( xUnits ) )
		xUnits = ""
	else
		paramList = NMCmdStrOptional( "xUnits", xUnits, paramList )
	endif
	
	if ( ParamIsDefault( yUnits ) )
		yUnits = "Intervals/bin"
	else
		paramList = NMCmdStrOptional( "yUnits", yUnits, paramList )
	endif
	
	if ( !ParamIsDefault( noGraph ) )
		paramList = NMCmdNumOptional( "noGraph", noGraph, paramList, integer = 1 )
	endif
	
	if ( history )
		NMCommandHistory( paramList )
	endif
	
	xRasterList = zFullPathRasterXList( folder, xRasterList )
	
	if ( ItemsInList( xRasterList ) < 2 ) // need at last 2 waves
		return NM2ErrorStr( 21, "xRasterList", xRasterList )
	endif
	
	xRaster1 = StringFromList( 0, xRasterList )
	yRaster1 = StringFromList( 0, yRasterList )
	
	xRaster1 = CheckNMSpikeRasterXPath( xRaster1 )
	yRaster1 = CheckNMSpikeRasterYPath( xRaster1, yRaster1 )
	
	if ( CheckNMSpikeAnalysisWaves( xRaster1, yRaster1, yMustExist ) )
		return ""
	endif
	
	xRaster2 = StringFromList( 1, xRasterList ) // implement loop here
	yRaster2 = StringFromList( 1, yRasterList )
	
	xRaster2 = CheckNMSpikeRasterXPath( xRaster2 )
	yRaster2 = CheckNMSpikeRasterYPath( xRaster2, yRaster2 )
	
	if ( CheckNMSpikeAnalysisWaves( xRaster2, yRaster2, yMustExist ) )
		return ""
	endif
	
	if ( numtype( xbgn ) > 0 )
		xbgn = SpikeTmin( xRaster1 )
	endif
	
	if ( numtype( xend ) > 0 )
		xend = SpikeTmax( xRaster1 )
	endif
	
	if ( ( numtype( binSize ) > 0 ) || ( binSize <= 0 ) )
		return NM2ErrorStr( 10, "binSize", num2str( binSize ) )
	endif
	
	xLabel = NMNoteLabel( "y", xRaster1, "" )
	
	wName = NMChild( xRaster1 )
	subfolder = NMParent( xRaster1 )
	
	if ( StringMatch( NMSpikeStrGet( "WaveNamingFormat" ), "suffix" ) )
		intvlsName = wName + "_Intvls"
		ISIHname = wName + "_JISIH"
	else
		intvlsName = "Intvls_" + wName
		ISIHname = "JISIH_" + wName
	endif
	
	ISIHname = NMCheckStringName( ISIHname )
	
	if ( strlen( subfolder ) > 0 )
		intvlsName = subfolder + intvlsName
		ISIHname = subfolder + ISIHname
	endif
	
	npnts = numpnts( $xRaster1 ) * numpnts( $xRaster2 )
	
	Make /O/N=( npnts ) $intvlsName = NaN
	SetScale /P x xbgn, binSize, $intvlsName
	
	Wave intvls = $intvlsName
	
	Wave rx1 = $xRaster1
	Wave ry1 = $yRaster1
	
	Wave rx2 = $xRaster2
	Wave ry2 = $yRaster2
	
	WaveStats /Q ry1
	
	wbgn = V_min
	wend = V_max
	
	for ( wcnt = wbgn ; wcnt <= wend ; wcnt += 1 ) // wave counter
	
		for ( icnt = 0 ; icnt < numpnts( ry1 ) ; icnt += 1 )
	
			if ( ( numtype( ry1[ icnt ] ) > 0 ) || ( ry1[ icnt ] != wcnt ) )
				continue
			endif
			
			if ( ( rx1[ icnt ] < xbgn ) || ( rx1[ icnt ] > xend ) )
				continue
			endif
			
			for ( jcnt = 0 ; jcnt < numpnts( ry2 ) ; jcnt += 1 )
			
				if ( ( numtype( ry2[ jcnt ] ) > 0 ) || ( ry2[ jcnt ] != wcnt ) )
					continue
				endif
				
				if ( ( rx2[ jcnt ] < xbgn ) || ( rx2[ jcnt ] > xend ) )
					continue
				endif
				
				interval = rx1[ icnt ] - rx2[ jcnt ]
				
				if ( numtype( interval ) == 0 )
					intvls[ kcnt ] = interval
					kcnt += 1
				endif
			
			endfor
	
		endfor
	
	endfor
	
	WaveStats /Q/Z intvls
	
	if ( V_npnts <= 0 )
		NMHistory( thisFxn + " Abort: detected no spike intervals" )
		return ""
	endif
	
	npnts = 2 + 1.1 * ( V_max - V_min ) / binSize
	
	if ( npnts <= 0 )
		return NM2ErrorStr( 10, "npnts", num2istr( npnts ) )
	endif
	
	Make /O/N=1 $ISIHname
	
	Histogram /B={ V_min * 1.1, binSize, npnts } intvls, $ISIHname
	
	zCall_CheckYunits( yUnits )
	
	if ( strlen( xUnits ) == 0 )
		xUnits = NMNoteLabel( "y", xRaster1, "time unit" )
	endif
	
	Wave ISIH = $ISIHname
	
	strswitch( yUnits )
	
		case "Intervals/s":
		
			ISIH /= binSize
			
			strswitch( xUnits )
				case "ms":
				case "msec":
					ISIH *= 1000
			endswitch
			
			break
			
		case "Intervals/ms":
		
			ISIH /= binSize
			
			strswitch( xUnits )
				case "s":
				case "sec":
					ISIH *= 0.001
			endswitch
			
			break
			
		case "Probability":
			ISIH /= kcnt
			break
	
		default:
		
			yUnits = "Intervals/bin"
			
	endswitch
	
	NMNoteType( intvlsName, "Joint Spike Intervals", xLabel, yUnits, "_FXN_" )
	Note $intvlsName, "JISIH Bin:" + num2str( binSize ) + ";JISIH Xbgn:" + num2str( xbgn ) + ";JISIH Xend:" + num2str( xend ) + ";"
	Note $intvlsName, "JISIH xRaster1:" + xRaster1
	Note $intvlsName, "JISIH xRaster2:" + xRaster2
	
	NMNoteType( ISIHname, "Spike JISIH", xLabel, yUnits, "_FXN_" )
	Note $ISIHname, "JISIH Bin:" + num2str( binSize ) + ";JISIH Xbgn:" + num2str( xbgn ) + ";JISIH Xend:" + num2str( xend ) + ";"
	Note $ISIHname, "JISIH xRaster1:" + xRaster1
	Note $ISIHname, "JISIH xRaster2:" + xRaster2
	
	SetNMstr( NMDF + "OutputWaveList", intvlsName + ";" + ISIHname + ";" )
	
	if ( !noGraph )
	
		wNameShort = NMChild( ISIHname )
	
		gName = "SP_" + CurrentNMFolderPrefix() + wNameShort
		gName = NMCheckStringName( gName )
		
		gTitle = NMFolderListName( "" ) + " : " + wNameShort
	
		NMWinCascadeRect( w )
	
		DoWindow /K $gName
	
		Display /K=(NMK())/N=$gName/W=(w.left,w.top,w.right,w.bottom) $ISIHname as gTitle
	
		ModifyGraph /W=$gName standoff=0, rgb=(0,0,0), mode=5, hbFill=2
		Label /W=$gName bottom xLabel
		Label /W=$gName left yUnits
		SetAxis /A/W=$gName
		
		SetNMstr( NMDF + "OutputWinList", gName )
		
	endif
	
	NMHistoryOutputWaves()
	NMHistoryOutputWindows()
	
	KillWaves /Z U_INTVLS
	
	return ISIHname
	
End // NMSpikeISIHJoint

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeHazard( ISIHname ) // compute hazard function from ISI histogram
	String ISIHname // interspike interval wave name ( dimensions should be spikes/bin )
	
	Variable icnt, jcnt, ilimit, summ, delta
	String wName, subfolder, hazard
	
	if ( !WaveExists( $ISIHname ) )
		return NM2ErrorStr( 1, "ISIHname", ISIHname )
	endif
	
	wName = NMChild( ISIHname )
	subfolder = NMParent( ISIHname )
	
	hazard = wName
	hazard = ReplaceString( "ISIH_", hazard, "" )
	hazard = ReplaceString( "_ISIH", hazard, "" )
	
	if ( StringMatch( NMSpikeStrGet( "WaveNamingFormat" ), "suffix" ) )
		hazard = wName + "_Hazard"
	else
		hazard = "Hazard_" + wName
	endif
	
	hazard = subfolder + hazard
	
	Duplicate /O $ISIHname $hazard
	
	Wave ISIH = $ISIHname
	Wave HZD = $hazard
	
	delta = deltax( ISIH )
	ilimit = numpnts( ISIH )
	
	for ( icnt = 0 ; icnt < ilimit ; icnt+=1 )
	
		summ = 0
		
		for ( jcnt = icnt ; jcnt < ilimit ; jcnt += 1 )
		
			if ( numtype( ISIH[ jcnt ] ) == 0 )
				summ += ISIH[ jcnt ]
			endif
			
		endfor
		
		HZD[ icnt ] /= delta * summ
		
	endfor
	
	HZD *= 1000
	
	return hazard

End // NMSpikeHazard

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zCall_CheckYunits( yUnits )
	String yUnits
	
	yUnits = ReplaceString( " ", yUnits, "" )
	yUnits = ReplaceString( "intvls", yUnits, "Intervals" )
	yUnits = ReplaceString( "/sec", yUnits, "/s" )
	yUnits = ReplaceString( "/msec", yUnits, "/ms" )
	
	return yUnits

End // zCall_Xunits

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zCall_Xunits( xRasterList )
	String xRasterList

	String xUnits, xRaster
	
	if ( ItemsInList( xRasterList) == 0 )
		return ""
	endif
	
	xRaster = StringFromList( 0, xRasterList )
	xRaster = CheckNMSpikeRasterXPath( xRaster )
	xUnits = NMNoteLabel( "y", xRaster, "time unit" )
	
	return xUnits

End // zCall_Xunits

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zCall_CheckXunits( xUnits )
	String xUnits
	
	strswitch( xUnits )
		case "s":
		case "sec":
		case "ms":
		case "msec":
			return "" // OK
	endswitch

	xUnits = StrVarOrDefault( NMSpikeDF + "SpikeXunits", "ms" )
	
	Prompt xUnits, "please specify time units of your data:", popup "s;ms;"
	
	DoPrompt "NM Spike Tab", xUnits

	if ( V_flag == 1 )
		return ""
	endif
	
	SetNMstr( NMSpikeDF + "SpikeXunits", xUnits )
	
	return xUnits

End // zCall_CheckXunits

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zCall_NMSpikeRate()

	Variable xUnitsOK
	String folder, promptStr = "Spike Count / Rate"
	
	String xRasterList = zCall_NMSpikeRasterListGet( promptStr )
	
	if ( ItemsInList( xRasterList) == 0 )
		return NM2ErrorStr( 1, "xRasterList", xRasterList )
	endif
	
	Variable xbgn = NMSpikeAnalysisTbgn( xRasterList )
	Variable xend = NMSpikeAnalysisTend( xRasterList )
	String yUnits = StrVarOrDefault( NMSpikeDF + "RateYaxis", "Spikes/s" )
	String xUnits = zCall_Xunits( xRasterList )
	
	Prompt xbgn, NMPromptAddUnitsX( "x-axis window begin" )
	Prompt xend, NMPromptAddUnitsX( "x-axis window end" )
	Prompt yUnits, "y-dimensions to compute:", popup "Spikes;Spikes/s;Spikes/ms;"
	
	DoPrompt promptStr, xbgn, xend, yUnits
		
	if ( V_flag == 1 )
		return ""
	endif
	
	SetNMstr( NMSpikeDF + "RateYaxis", yUnits )
	
	folder = StringFromList( 0, xRasterList )
	folder = NMParent( folder, noPath = 1 )
	
	xRasterList = NMChild( xRasterList )
	
	if ( StringMatch( yUnits, "Spikes/s" ) || StringMatch( yUnits, "Spikes/ms" ) )
		xUnits = zCall_CheckXunits( xUnits )
	else
		xUnits = ""
	endif
	
	if ( strlen( xUnits ) > 0 )
		return NMSpikeRate( folder = folder, xRasterList = xRasterList, xbgn = xbgn, xend = xend, xUnits = xUnits, yUnits = yUnits, history = 1 )
	endif
	
	return NMSpikeRate( folder = folder, xRasterList = xRasterList, xbgn = xbgn, xend = xend, yUnits = yUnits, history = 1 )
	
End // zCall_NMSpikeRate

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeRate( [ folder, xRasterList, yRasterList, xbgn, xend, xUnits, yUnits, noGraph, history ] )
	String folder // folder or subfolder, pass nothing for current folder
	String xRasterList // x-raster wave, pass nothing for current x-raster
	String yRasterList // y-raster wave, pass nothing for automatic search based on x-raster
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	String xUnits // "ms" or "s" // use this to specify time units if they are not in notes of x-raster wave
	String yUnits // "Spikes" or "Spikes/s" or "Spikes/ms"
	Variable noGraph // ( 0 ) create graph ( 1 ) no graph
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable icnt, jcnt, npnts, count, spikeX, yMustExist = 0
	String xRaster, yRaster, yType
	String xLabel, wName, subfolder, rateName
	String gName, gTitle, wavePrefix, paramList = ""
	
	STRUCT Rect w
	
	NMOutputListsReset()
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	else
		paramList = NMCmdStrOptional( "folder", folder, paramList )
	endif
	
	if ( ParamIsDefault( xRasterList ) )
		xRasterList = ""
	else
		paramList = NMCmdStrOptional( "xRasterList", xRasterList, paramList )
	endif
	
	if ( ParamIsDefault( yRasterList ) )
		yRasterList = ""
	else
		paramList = NMCmdStrOptional( "yRasterList", yRasterList, paramList )
	endif
	
	if ( ParamIsDefault( xbgn ) )
		xbgn = NaN
	else
		paramList = NMCmdNumOptional( "xbgn", xbgn, paramList )
	endif
	
	if ( ParamIsDefault( xend ) )
		xend = NaN
	else
		paramList = NMCmdNumOptional( "xend", xend, paramList )
	endif
	
	if ( ParamIsDefault( xUnits ) )
		xUnits = ""
	else
		paramList = NMCmdStrOptional( "xUnits", xUnits, paramList )
	endif
	
	if ( ParamIsDefault( yUnits ) )
		yUnits = "Spikes"
	else
		paramList = NMCmdStrOptional( "yUnits", yUnits, paramList )
	endif
	
	if ( !ParamIsDefault( noGraph ) )
		paramList = NMCmdNumOptional( "noGraph", noGraph, paramList, integer = 1 )
	endif
	
	if ( history )
		NMCommandHistory( paramList )
	endif
	
	xRasterList = zFullPathRasterXList( folder, xRasterList )
	
	if ( ItemsInList( xRasterList ) == 0 )
		return NM2ErrorStr( 21, "xRasterList", xRasterList )
	endif
	
	xRaster = StringFromList( 0, xRasterList ) // implement loop here
	yRaster = StringFromList( 0, yRasterList )
	
	xRaster = CheckNMSpikeRasterXPath( xRaster )
	yRaster = CheckNMSpikeRasterYPath( xRaster, yRaster )
	
	if ( CheckNMSpikeAnalysisWaves( xRaster, yRaster, yMustExist ) )
		return ""
	endif
	
	wName = NMChild( xRaster )
	subfolder = NMParent( xRaster )
	
	if ( StringMatch( yUnits, "Spikes" ) )
		yType = "Count"
	else
		yType = "Rate"
	endif
	
	if ( StringMatch( NMSpikeStrGet( "WaveNamingFormat" ), "suffix" ) )
		rateName = wName + "_" + yType
	else
		rateName = yType + "_" + wName
	endif
	
	rateName = NMCheckStringName( rateName )
	
	gName = "SP_" + CurrentNMFolderPrefix() + rateName
	gTitle = NMFolderListName( "" ) + " : " + rateName
	
	gName = NMCheckStringName( gName )
	
	wavePrefix = NMNoteStrByKey( xRaster, "Spike Prefix" )
	
	if ( strlen( wavePrefix ) == 0 )
		wavePrefix = "Wave"
	endif
	
	if ( numtype( xbgn ) > 0 )
		xbgn = SpikeTmin( xRaster )
	endif
	
	if ( numtype( xend ) > 0 )
		xend = SpikeTmax( xRaster )
	endif
	
	if ( strlen( subfolder ) > 0 )
		rateName = subfolder + rateName
	endif
	
	Wave xRasterWave = $xRaster
	
	WaveStats /Q/Z xRasterWave
	
	npnts = V_NumNans
	
	if ( WaveExists( $yRaster ) )
	
		Wave yRasterWave = $yRaster
		
		WaveStats /Q/Z yRasterWave
		
		if ( ( numtype( V_max ) == 0 ) && ( V_max > 1 ) )
			npnts = V_max
		endif
		
		Make /O/N=( npnts+1 ) $rateName = NaN
		
		Wave wtemp = $rateName
		
		for ( icnt = 0 ; icnt < numpnts( yRasterWave ) ; icnt += 1 )
		
			jcnt = yRasterWave[ icnt ]
			
			if ( ( numtype( jcnt ) > 0 ) || ( jcnt < 0 ) || ( jcnt >= numpnts( wtemp ) ) )
				continue
			endif
		
			if ( numtype( wtemp[ jcnt ] ) > 0 )
				wtemp[ jcnt ] = 0
			endif
		
			if ( ( xRasterWave[ icnt ] >= xbgn ) && ( xRasterWave[ icnt ] <= xend ) )
				wtemp[ jcnt ] += 1
			endif
			
		endfor
		
		xLabel = NMNoteLabel( "y", yRaster, wavePrefix+" #" )
	
	else
	
		Make /O/N=( npnts+1 ) $rateName = NaN
		
		Wave wtemp = $rateName
		
		jcnt = 0
		count = 0
		
		for ( icnt = 0 ; icnt < numpnts( xRasterWave ) ; icnt += 1 )
		
			if ( jcnt >= numpnts( wtemp ) )
				break
			endif
		
			spikeX = xRasterWave[ icnt ]
			
			if ( numtype( spikeX ) > 0 )
				
				if ( count > 0 )
					jcnt += 1
					count = 0
				endif
				
				continue
				
			endif
			
			if ( numtype( wtemp[ jcnt ] ) > 0 )
				wtemp[ jcnt ] = 0
			endif
		
			if ( ( spikeX >= xbgn ) && ( spikeX <= xend ) )
				wtemp[ jcnt ] += 1
				count += 1
			endif
			
		endfor
		
		xLabel = "Wave #"
		yRaster = ""
		
		Redimension /N=(jcnt+1) wtemp
	
	endif
	
	yUnits = zCall_CheckYunits( yUnits )
	
	strswitch( yUnits )
			
		case "Spikes/s":
		
			wtemp /= xend - xbgn
			
			if ( strlen( xUnits ) == 0 )
				xUnits = NMNoteLabel( "y", xRaster, "time unit" )
			endif
			
			strswitch( xUnits )
				case "ms":
				case "msec":
				wtemp *= 1000 // time conversion
			endswitch
			
			break
			
		case "Spikes/ms":
		
			wtemp /= xend - xbgn
			
			if ( strlen( xUnits ) == 0 )
				xUnits = NMNoteLabel( "y", xRaster, "time unit" )
			endif
			
			strswitch( xUnits )
				case "s":
				case "sec":
				wtemp *= 0.001 // time conversion
			endswitch
			 
			break
			
	endswitch
	
	NMNoteType( rateName, "Spike Rate", xLabel, yUnits, "_FXN_" )
	Note $rateName, "Rate Xbgn:" + num2str( xbgn ) + ";Rate Xend:" + num2str( xend ) + ";"
	Note $rateName, "Rate xRaster:" + xRaster
	Note $rateName, "Rate yRaster:" + yRaster
	
	SetNMstr( NMDF + "OutputWaveList", rateName )
	
	if ( !noGraph )
	
		NMWinCascadeRect( w )
	
		DoWindow /K $gName
	
		Display /K=(NMK())/N=$gName/W=(w.left,w.top,w.right,w.bottom) $rateName as gTitle
	
		ModifyGraph /W=$gName standoff=0, rgb=(65280,0,0), mode=4, marker=19
		Label /W=$gName bottom xLabel
		Label /W=$gName left yUnits
	
		WaveStats /Q/Z $rateName
	
		SetAxis /W=$gName left 0, V_max
		
		SetNMstr( NMDF + "OutputWinList", gName )
		
	endif
	
	NMHistoryOutputWaves()
	NMHistoryOutputWindows()
	
	return rateName

End // NMSpikeRate

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zCall_NMSpikesToWaves()

	String xWaveOrFolder = CurrentNMSpikeRasterOrFolder()
	
	if ( strlen( xWaveOrFolder ) == 0 )
		NMDoAlert( "There is no Spike Raster selection." )
		return ""
	endif
	
	if ( DataFolderExists( xWaveOrFolder ) )
	
		return zCall_NMSpikesToWavesSubfolder( subfolder = xWaveOrFolder )
		
	elseif ( WaveExists( $xWaveOrFolder ) )
	
		return zCall_NMSpikesToWavesRasterX( xRaster = xWaveOrFolder )
	
	else
	
		NMDoAlert( "The current Spike Raster selection " + NMQuotes( xWaveOrFolder ) + " does not appear to exist." )
		
		return ""
		
	endif

End // zCall_NMSpikesToWaves

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zCall_NMSpikesToWavesRasterX( [ xRaster ] )
	String xRaster

	Variable stop, xwinMore
	String chanStr, chanList, wavePrefix, rstr
	String xRasterSelect, title = "Copy Spikes to Waves"
	
	Variable currentChan = CurrentNMChannel()
	Variable numChannels = NMNumChannels()
	
	String currentPrefix = CurrentNMWavePrefix()
	String defaultPrefix = NMSpikeStrGet( "S2W_WavePrefix" )
	
	if ( ParamIsDefault( xRaster ) )
		xRaster = CurrentNMSpikeRasterOrFolder()
	endif
	
	if ( ( strlen( xRaster) == 0 ) || !WaveExists( $xRaster ) )
		return NM2ErrorStr( 1, "xRaster", xRaster )
	endif
	
	xRasterSelect = CheckNMSpikeRasterXPath( xRaster )
	wavePrefix = NMNoteStrByKey( xRasterSelect, "Spike Prefix" )
	
	if ( !StringMatch( currentPrefix, wavePrefix ) )
	
		xRaster = NMChild( xRaster )
	
		DoAlert 1, "NMSpikesToWaves Alert: the current wave prefix does not match that of " + NMQuotes( xRaster ) + ". Do you want to continue?"
		
		if ( V_Flag != 1 )
			return ""
		endif
		
	endif
	
	Variable xwinBefore = NMSpikeVarGet( "S2W_XwinBefore" )
	Variable xwinAfter = NMSpikeVarGet( "S2W_XwinAfter" )
	Variable stopAtNextSpike = NMSpikeVarGet( "S2W_StopAtNextSpike" )
	Variable chanNum = CurrentNMChannel() // NumVarOrDefault( subfolder+"S2W_ChanNum", currentChan )
	Variable selectAsCurrent = 1 + NMSpikeVarGet( "S2W_SelectAsCurrent" )
	Variable setGroups = 1 + NMSpikeVarGet( "S2W_SetGroups" )
	
	wavePrefix = NMPrefixUnique( defaultPrefix )
	
	if ( chanNum >= numChannels )
		chanNum = currentChan
	endif
	
	if ( stopAtNextSpike < 0 )
		stop = 1 // No
	else
		stop = 2 // Yes
	endif
	
	Prompt xwinBefore, NMPromptAddUnitsX( "x-axis window to copy before spike" )
	Prompt xwinAfter, NMPromptAddUnitsX( "x-axis window to copy after spike" )
	Prompt stop, "limit new waves to time before next spike?", popup "no;yes;"
	Prompt xwinMore, NMPromptAddUnitsX( "additional x-axis window to limit before next spike" )
	Prompt wavePrefix, "prefix name of new spike waves:"
	Prompt selectAsCurrent, "select new spike waves to display and analyze?", popup "no;yes;"
	Prompt setGroups, "set group # of new spike waves based on input wave number?", popup "no;yes;"
	
	if ( numChannels > 1 )
	
		if ( chanNum < 0 )
			chanStr = "All"
		else
			chanStr = ChanNum2Char( chanNum )
		endif
		
		chanList = "All;" + NMChanList( "CHAR" )
		
		Prompt chanStr, "channel waves to copy from:", popup chanList
		DoPrompt title, chanStr, xwinBefore, xwinAfter, stop
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		DoPrompt title, wavePrefix, selectAsCurrent
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		if ( StringMatch( chanStr, "All" ) )
			chanNum = -1
		else
			chanNum = ChanChar2Num( chanStr )
		endif
		
		//SetNMvar( subfolder+"S2W_ChanNum", chanNum )
		
	else
	
		DoPrompt title, xwinBefore, xwinAfter, stop, wavePrefix, selectAsCurrent
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		chanNum = currentChan
		
	endif
	
	selectAsCurrent -= 1
	
	SetNMvar( NMSpikeDF + "S2W_XwinAfter", xwinAfter )
	SetNMvar( NMSpikeDF + "S2W_XwinBefore", xwinBefore )
	SetNMvar( NMSpikeDF + "S2W_SelectAsCurrent", selectAsCurrent )
	
	if ( stop == 2 ) // Yes
	
		if ( stopAtNextSpike < 0 )
			xwinMore = 0
		else
			xwinMore = stopAtNextSpike
		endif
		
		DoPrompt title, xwinMore
		
		if ( V_flag == 1 )
			return ""
		endif
		
		if ( ( numtype( xwinMore ) == 0 ) && ( xwinMore > 0 ) )
			stopAtNextSpike = xwinMore
		else
			stopAtNextSpike = 0
		endif
		
	else // No
	
		stopAtNextSpike = -1
		
	endif
	
	SetNMvar( NMSpikeDF + "S2W_StopAtNextSpike", stopAtNextSpike )
	
	wavePrefix = CheckNMPrefixUnique( wavePrefix, defaultPrefix, chanNum )
	
	if ( strlen( wavePrefix ) == 0 )
		return ""
	endif
	
	rstr = NMSpikesToWaves( xRaster = xRaster, xwinBefore = xwinBefore, xwinAfter = xwinAfter, stopAtNextSpike = stopAtNextSpike, chanNum = chanNum, wavePrefix = wavePrefix, history = 1 )
	
	if ( selectAsCurrent && ( strlen( rstr ) > 0 ) )
		NMSet( wavePrefix = wavePrefix + "_", history = 1 )
		NMTab( "Main" )
	endif
	
	return rstr
	
End // zCall_NMSpikesToWavesRasterX

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zCall_NMSpikesToWavesSubfolder( [ subfolder ] )
	String subfolder

	Variable stop, xwinMore
	String chanStr, chanList, wavePrefix, rstr
	String xRaster = "", xRasterSelect = "", xRasterList = ""
	String title = "Copy Spikes to Waves"
	
	String currentFolder = CurrentNMFolder( 1 )
	
	Variable currentChan = CurrentNMChannel()
	Variable numChannels = NMNumChannels()
	
	String currentPrefix = CurrentNMWavePrefix()
	String defaultPrefix = NMSpikeStrGet( "S2W_WavePrefix" )
	
	if ( ParamIsDefault( subfolder ) )
		subfolder = CurrentNMSpikeRasterOrFolder()
	endif
	
	if ( ( strlen( subfolder ) == 0 ) || !DataFolderExists( subfolder ) )
		return NM2ErrorStr( 30, "subfolder", subfolder )
	endif
	
	xRasterList = NMSpikeSubfolderRasterList( subfolder, 0, 0 )
	
	if ( ItemsInList( xRasterList ) > 1 )
	
		xRaster = StrVarOrDefault( currentFolder + subfolder + ":RasterXSelect", "" )
		
		if ( strlen( xRaster ) == 0 )
			xRaster = StringFromList( 0, xRasterList )
		endif

		Prompt xRaster, "select spike raster:", popup xRasterList
		DoPrompt title, xRaster
		
		if ( V_flag == 1 )
			return ""
		endif
		
		SetNMstr( currentFolder + subfolder + ":RasterXSelect", xRaster )
		
		xRasterSelect = CheckNMSpikeRasterXPath( currentFolder + subfolder + ":" + xRaster )
	
	endif
	
	if ( strlen( xRasterSelect ) == 0 )
		xRasterSelect = CheckNMSpikeRasterXPath( xRaster )
	endif
	
	wavePrefix = NMNoteStrByKey( xRasterSelect, "Spike Prefix" )
	
	if ( !StringMatch( currentPrefix, wavePrefix ) )
	
		xRaster = NMChild( xRaster )
	
		DoAlert 1, "NMSpikesToWaves Alert: the current wave prefix does not match that of " + NMQuotes( xRaster ) + ". Do you want to continue?"
		
		if ( V_Flag != 1 )
			return ""
		endif
		
	endif
	
	Variable xwinBefore = NMSpikeVarGet( "S2W_XwinBefore" )
	Variable xwinAfter = NMSpikeVarGet( "S2W_XwinAfter" )
	Variable stopAtNextSpike = NMSpikeVarGet( "S2W_StopAtNextSpike" )
	Variable chanNum = CurrentNMChannel() // NumVarOrDefault( subfolder+"S2W_ChanNum", currentChan )
	Variable selectAsCurrent = 1 + NMSpikeVarGet( "S2W_SelectAsCurrent" )
	Variable setGroups = 1 + NMSpikeVarGet( "S2W_SetGroups" )
	
	wavePrefix = NMPrefixUnique( defaultPrefix )
	
	if ( chanNum >= numChannels )
		chanNum = currentChan
	endif
	
	if ( stopAtNextSpike < 0 )
		stop = 1 // No
	else
		stop = 2 // Yes
	endif
	
	Prompt xwinBefore, NMPromptAddUnitsX( "x-axis window to copy before spike" )
	Prompt xwinAfter, NMPromptAddUnitsX( "x-axis window to copy after spike" )
	Prompt stop, "limit new waves to time before next spike?", popup "no;yes;"
	Prompt xwinMore, NMPromptAddUnitsX( "additional x-axis window to limit before next spike" )
	Prompt wavePrefix, "prefix name of new spike waves:"
	Prompt selectAsCurrent, "select new spike waves to display and analyze?", popup "no;yes;"
	Prompt setGroups, "set group # of new spike waves based on the input wave number?", popup "no;yes;"
	
	if ( numChannels > 1 )
	
		if ( chanNum < 0 )
			chanStr = "All"
		else
			chanStr = ChanNum2Char( chanNum )
		endif
		
		chanList = "All;" + NMChanList( "CHAR" )
		
		Prompt chanStr, "channel waves to copy from:", popup chanList
		DoPrompt title, chanStr, xwinBefore, xwinAfter, stop
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		DoPrompt title, wavePrefix, selectAsCurrent
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		if ( StringMatch( chanStr, "All" ) )
			chanNum = -1
		else
			chanNum = ChanChar2Num( chanStr )
		endif
		
		//SetNMvar( subfolder+"S2W_ChanNum", chanNum )
		
	else
	
		DoPrompt title, xwinBefore, xwinAfter, stop, wavePrefix, selectAsCurrent
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		chanNum = currentChan
		
	endif
	
	selectAsCurrent -= 1
	
	SetNMvar( NMSpikeDF + "S2W_XwinAfter", xwinAfter )
	SetNMvar( NMSpikeDF + "S2W_XwinBefore", xwinBefore )
	SetNMvar( NMSpikeDF + "S2W_SelectAsCurrent", selectAsCurrent )
	
	if ( stop == 2 ) // Yes
	
		if ( stopAtNextSpike < 0 )
			xwinMore = 0
		else
			xwinMore = stopAtNextSpike
		endif
		
		if ( selectAsCurrent )
			DoPrompt title, xwinMore, setGroups
		else
			DoPrompt title, xwinMore
		endif
		
		if ( V_flag == 1 )
			return ""
		endif
		
		if ( ( numtype( xwinMore ) == 0 ) && ( xwinMore > 0 ) )
			stopAtNextSpike = xwinMore
		else
			stopAtNextSpike = 0
		endif
		
	else // No
	
		stopAtNextSpike = -1
		
		if ( selectAsCurrent )
			DoPrompt title, setGroups
		endif
		
		if ( V_flag == 1 )
			return ""
		endif
		
	endif
	
	setGroups -= 1
	
	SetNMvar( NMSpikeDF + "S2W_SetGroups", setGroups )
	SetNMvar( NMSpikeDF + "S2W_StopAtNextSpike", stopAtNextSpike )
	
	wavePrefix = CheckNMPrefixUnique( wavePrefix, defaultPrefix, chanNum )
	
	if ( strlen( wavePrefix ) == 0 )
		return ""
	endif
	
	if ( strlen( xRaster ) > 0 )
		rstr = NMSpikesToWaves( folder=subfolder, xRaster=xRaster, xwinBefore=xwinBefore, xwinAfter=xwinAfter, stopAtNextSpike=stopAtNextSpike, chanNum=chanNum, wavePrefix=wavePrefix, selectPrefix=selectAsCurrent, setGroups=setGroups, history=1 )
	else
		rstr = NMSpikesToWaves( folder=subfolder, xwinBefore=xwinBefore, xwinAfter=xwinAfter, stopAtNextSpike=stopAtNextSpike, chanNum=chanNum, wavePrefix=wavePrefix, selectPrefix=selectAsCurrent, setGroups=setGroups, history=1 )
	endif
	
	return rstr
	
End // zCall_NMSpikesToWavesSubfolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikesToWaves( [ folder, xRaster, yRaster, xwinBefore, xwinAfter, stopAtNextSpike, chanNum, wavePrefix, selectPrefix, setGroups, noGraph, history ] )
	String folder // folder or subfolder, pass nothing for current folder
	String xRaster // x-raster wave, pass nothing for current x-raster
	String yRaster // y-raster wave, pass nothing for automatic search based on x-raster
	Variable xwinBefore, xwinAfter // x-axis copy windows before and after spike
	Variable stopAtNextSpike // ( < 0 ) no ( >= 0 ) yes... if greater than zero, use value to limit time before next spike
	Variable chanNum // channel number ( -1 ) for all
	String wavePrefix // prefix name for new output waves
	Variable selectPrefix // select the new wave prefix
	Variable setGroups // ( 0 ) no ( 1 ) yes, set group # of new output waves based on yRaster
	Variable noGraph // ( 0 ) plot new waves in graph ( 1 ) no graph
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable ccnt, cbgn, cend, numSpikes
	String wList, xLabel, yLabel, gPrefix, gName, gTitle, gList = "", outList = ""
	String xRasterList, wname, wname2, paramList = ""
	
	Variable yMustExist = 1 // ( 0 ) no ( 1 ) yes
	Variable allowTruncatedEvents = 1 // ( 0 ) no ( 1 ) yes
	
	Variable numChannels = NMNumChannels()
	
	NMOutputListsReset()
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	else
		paramList = NMCmdStrOptional( "folder", folder, paramList )
	endif
	
	if ( ParamIsDefault( xRaster ) )
		xRaster = ""
	else
		paramList = NMCmdStrOptional( "xRaster", xRaster, paramList )
	endif
	
	if ( ParamIsDefault( yRaster ) )
		yRaster = ""
	else
		paramList = NMCmdStrOptional( "yRaster", yRaster, paramList )
	endif
	
	if ( ParamIsDefault( xwinBefore ) )
		xwinBefore = NMSpikeVarGet( "S2W_XwinBefore" )
	else
		paramList = NMCmdNumOptional( "xwinBefore", xwinBefore, paramList )
	endif
	
	if ( ParamIsDefault( xwinAfter ) )
		xwinAfter = NMSpikeVarGet( "S2W_XwinAfter" )
	else
		paramList = NMCmdNumOptional( "xwinAfter", xwinAfter, paramList )
	endif
	
	if ( ParamIsDefault( stopAtNextSpike ) )
		stopAtNextSpike = NMSpikeVarGet( "S2W_StopAtNextSpike" )
	else
		paramList = NMCmdNumOptional( "stopAtNextSpike", stopAtNextSpike, paramList, integer = 1 )
	endif
	
	if ( ParamIsDefault( chanNum ) )
		chanNum = -1
	else
		paramList = NMCmdNumOptional( "chanNum", chanNum, paramList, integer = 1 )
	endif
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = NMSpikeStrGet( "S2W_WavePrefix" )
	else
		paramList = NMCmdStrOptional( "wavePrefix", wavePrefix, paramList )
	endif
	
	if ( ParamIsDefault( selectPrefix ) )
		selectPrefix = 0
	else
		paramList = NMCmdNumOptional( "selectPrefix", selectPrefix, paramList, integer = 1 )
	endif
	
	if ( ParamIsDefault( setGroups ) )
		setGroups = 0
	else
		paramList = NMCmdNumOptional( "setGroups", setGroups, paramList, integer = 1 )
	endif
	
	if ( ParamIsDefault( noGraph ) )
		noGraph = 1
	else
		paramList = NMCmdNumOptional( "noGraph", noGraph, paramList, integer = 1 )
	endif
	
	if ( history )
		NMCommandHistory( paramList )
	endif
	
	xRasterList = zFullPathRasterXList( folder, xRaster )
	
	if ( ItemsInList( xRasterList ) == 0 )
		return NM2ErrorStr( 21, "xRasterList", xRasterList )
	endif
	
	xRaster = StringFromList( 0, xRasterList )
	
	xRaster = CheckNMSpikeRasterXPath( xRaster )
	yRaster = CheckNMSpikeRasterYPath( xRaster, yRaster )
	
	if ( CheckNMSpikeAnalysisWaves( xRaster, yRaster, yMustExist ) )
		return ""
	endif
	
	if ( ( numtype( xwinBefore ) > 0 ) || ( xwinBefore < 0 ) )
		return NM2ErrorStr( 10, "xwinBefore", num2str( xwinBefore ) )
	endif
	
	if ( ( numtype( xwinAfter ) > 0 ) || ( xwinAfter < 0 ) )
		return NM2ErrorStr( 10, "xwinAfter", num2str( xwinAfter ) )
	endif
	
	if ( numtype( stopAtNextSpike ) > 0 )
		stopAtNextSpike = 0
	endif
	
	if ( ( numtype( chanNum ) > 0 ) || ( chanNum >= numChannels ) )
		return NM2ErrorStr( 10, "chanNum", num2istr( chanNum ) )
	endif

	if ( chanNum < 0 )
		cbgn = 0
		cend = numChannels - 1
	else
		cbgn = chanNum
		cend = chanNum
	endif
	
	for ( ccnt = cbgn ; ccnt <= cend ; ccnt += 1 )
	
		wList = NMEventsToWaves( yRaster, xRaster, xwinBefore, xwinAfter, stopAtNextSpike, allowTruncatedEvents, ccnt, wavePrefix )
		
		numSpikes = ItemsInList( wList )
		
		NMHistory( "Created " + num2str( numSpikes ) + " new spike waves with prefix " + NMQuotes( wavePrefix ) )
		
		if ( numSpikes == 0 )
			continue
		endif
		
		outList = NMAddToList( wList, outList, ";" )
		
		wname = wavePrefix + "Times"
		
		if ( WaveExists( $wname ) )
		
			wname2 = "SP_Times_" + wavePrefix
			
			Duplicate /O $wname, $wname2
			KillWaves /Z $wname
			
		endif
		
		if ( !noGraph )
			
			xLabel = NMChanLabelX( channel = ccnt )
			yLabel = NMChanLabelY( channel = ccnt )
			
			gPrefix = wavePrefix + "_" + CurrentNMFolderPrefix() + ChanNum2Char( ccnt )
			gName = NMCheckStringName( gPrefix )
			gTitle = NMFolderListName( "" ) + " : Ch " + ChanNum2Char( ccnt ) + " : " + wavePrefix
			
			NMGraph( wList = wList, gName = gName, gTitle = gTitle, xLabel = xLabel )
			
			gList += gName + ";"
		
		endif
		
	endfor
	
	SetNMstr( NMDF + "OutputWaveList", outList )
	SetNMstr( NMDF + "OutputWinList", gList )
	
	String waveSelectList
	Variable wcnt, chan = 0
	
	if ( selectPrefix && ( strlen( outList ) > 0 ) )
	
		NMSet( wavePrefix = wavePrefix + "_" )
		NMTab( "Main" )
	
		if ( setGroups )
			NMSpikesToWavesGroups()
		endif
		
	endif
	
	return outList

End // NMSpikesToWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikesToWavesGroups()

	String waveSelectList, wName, sName
	Variable wcnt, waveNum, chan = 0

	waveSelectList = NMWaveSelectList( chan )
	
	NMGroupsClear()
		
	for ( wcnt = 0 ; wcnt < ItemsInList( waveSelectList ) ; wcnt += 1 ) // loop thru selected waves
	
		wName = StringFromList( wcnt, waveSelectList )
		sName = NMNoteStrByKey( wName, "Event Source" )
		waveNum = GetSeqNum( sName )
		
		NMGroupsSet( waveNum=wcnt, group=waveNum, update = 0 )
		
	endfor
	
	UpdateNMGroups()
		
End // NMSpikesToWavesGroups

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zCall_NMSpikeTable()
	
	String xWaveOrFolder = CurrentNMSpikeRasterOrFolder()
	
	if ( strlen( xWaveOrFolder ) == 0 )
		NMDoAlert( "There is no Spike Raster selection." )
		return ""
	endif
	
	if ( DataFolderExists( xWaveOrFolder ) )
	
		return NMSpikeTableCall()
		
	elseif ( WaveExists( $xWaveOrFolder ) )
	
		return SpikeTable( xWaveOrFolder, history = 1 )
		
	else
	
		NMDoAlert( "The current Spike Raster selection " + NMQuotes( xWaveOrFolder ) + " does not appear to exist." )
		
		return ""
		
	endif
	
End // zCall_NMSpikeTable

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SpikeTable( xRaster [ hide, history ] )
	String xRaster
	Variable hide
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable icnt, yMustExist = 0
	Variable left, top, right, bottom
	String yRaster = "", wList1 = "", wList2, tName, title, paramList = ""
	
	STRUCT Rect w
	
	NMOutputListsReset()
	
	if ( history )
		paramList = NMCmdStr( xRaster, paramList )
		NMCommandHistory( paramList )
	endif
	
	xRaster = CheckNMSpikeRasterXPath( xRaster )
	yRaster = CheckNMSpikeRasterYPath( xRaster, yRaster )
	
	if ( CheckNMSpikeAnalysisWaves( xRaster, yRaster, yMustExist ) )
		return ""
	endif
	
	tName = "SP_" + CurrentNMFolderPrefix() + ReplaceString( "SP_", xRaster, "" )
	title = NMFolderListName( "" ) + " : " + xRaster
	
	wList1 = AddListItem( xRaster, wList1, ";", inf )
	
	if ( strlen( yRaster ) > 0 )
		wList1 = AddListItem( yRaster, wList1, ";", inf )
	endif
	
	wList2 = WaveList( "*" + xRaster + "*", ";", "TEXT:0" )
	
	NMWinCascadeRect( w )
	
	DoWindow /K $tName
	Edit /HIDE=(hide)/K=(NMK())/N=$tName/W=(w.left,w.top,w.right,w.bottom) as title
	
	for ( icnt = 0 ; icnt < ItemsInList( wList1 ) ; icnt += 1 )
		AppendToTable /W=$tName $StringFromList( icnt, wList1 )
	endfor
	
	for ( icnt = 0 ; icnt < ItemsInList( wList2 ) ; icnt += 1 )
		AppendToTable /W=$tName $StringFromList( icnt, wList2 )
	endfor
	
	SetNMstr( NMDF + "OutputWaveList", wList1 + wList2 )
	SetNMstr( NMDF + "OutputWinList", tName )
	
	NMHistoryOutputWindows()
	
	return tName

End // SpikeTable

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zCall_NMSpikeFolderKill()
	
	String xWaveOrFolder = CurrentNMSpikeRasterOrFolder()
	
	if ( strlen( xWaveOrFolder ) == 0 )
		NMDoAlert( "There is no Spike Raster selection." )
		return ""
	endif
	
	if ( !DataFolderExists( xWaveOrFolder ) )
		NMDoAlert( "The current Spike Raster selection " + NMQuotes( xWaveOrFolder ) + " is not a folder." )
		return ""
	endif
	
	DoAlert 1, "Are you sure you want to close subfolder " + NMQuotes( xWaveOrFolder ) + "?"
	
	if ( V_flag != 1 )
		return "" // cancel
	endif
	
	return NMSpikeFolderKill( folder = xWaveOrFolder, history = 1 )

End // zCall_NMSpikeFolderKill

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeFolderKill( [ folder, update, history ] )
	String folder // data folder
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	String paramList = ""
	
	if ( ParamIsDefault( folder ) )
		folder = CurrentNMSpikeRasterOrFolder()
	else
		paramList = NMCmdStrOptional( "folder", folder, paramList )
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( history )
		NMCommandHistory( paramList )
	endif
	
	if ( !DataFolderExists( folder ) )
		return NM2ErrorStr( 30, "folder", folder )
	endif
	
	if ( StringMatch( folder, CurrentNMFolder( 1 ) ) )
		NMDoAlert( GetRTStackInfo( 1 ) + " Abort: cannot close the current NM data folder." )
		return "" // not allowed
	endif
	
	Variable error = NMSubfolderKill( folder )
	
	if ( update )
		NMSpikeUpdate()
	endif
	
	if ( !error )
		return folder
	else
		return ""
	endif
	
End // NMSpikeFolderKill

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeRasterClearCall()

	String xWaveOrFolder = CurrentNMSpikeRasterOrFolder()
	
	if ( strlen( xWaveOrFolder ) == 0 )
		NMDoAlert( "There is no Spike Raster selection." )
		return ""
	endif
	
	DoAlert 1, "Are you sure you want to clear the currently selected spike raster plot?"
	
	if ( V_flag != 1 )
		return ""
	endif
	
	if ( DataFolderExists( xWaveOrFolder ) )
	
		return NMSpikeRasterClear( folder = xWaveOrFolder, history = 1 )
		
	elseif ( WaveExists( $xWaveOrFolder ) )
	
		return NMSpikeRasterClear( xRaster = xWaveOrFolder, history = 1 )
	
	else
	
		NMDoAlert( "The current Spike Raster selection " + NMQuotes( xWaveOrFolder ) + " does not appear to exist." )
		
		return ""
		
	endif

End // NMSpikeRasterClearCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeRasterClear( [ folder, xRaster, yRaster, update, history ] )
	String folder // folder or subfolder, pass nothing for current folder
	String xRaster // x-raster wave, pass nothing for current x-raster
	String yRaster // y-raster wave, pass nothing for automatic search based on x-raster
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable icnt, yMustExist = 1
	String xRasterList, paramList = ""
	
	if ( ParamIsDefault( folder ) )
		folder = ""
	else
		paramList = NMCmdStrOptional( "folder", folder, paramList )
	endif
	
	if ( ParamIsDefault( xRaster ) )
		xRaster = ""
	else
		paramList = NMCmdStrOptional( "xRaster", xRaster, paramList )
	endif
	
	if ( ParamIsDefault( yRaster ) )
		yRaster = ""
	else
		paramList = NMCmdStrOptional( "yRaster", yRaster, paramList )
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( history )
		NMCommandHistory( paramList )
	endif
	
	xRasterList = zFullPathRasterXList( folder, xRaster )
	
	if ( ItemsInList( xRasterList ) == 0 )
		return NM2ErrorStr( 21, "xRasterList", xRasterList )
	endif
	
	for ( icnt = 0 ; icnt < ItemsInList( xRasterList ) ; icnt += 1 )
	
		xRaster = StringFromList( icnt, xRasterList )
		
		if ( icnt > 0 )
			yRaster = ""
		endif
		
		xRaster = CheckNMSpikeRasterXPath( xRaster )
		yRaster = CheckNMSpikeRasterYPath( xRaster, yRaster )
		
		if ( CheckNMSpikeAnalysisWaves( xRaster, yRaster, yMustExist ) )
			return ""
		endif
		
		Wave xWave = $xRaster
		Wave yWave = $yRaster
		
		xWave = NaN
		yWave = NaN
		
	endfor
	
	if ( update )
		NMSpikeUpdate()
	endif
	
End // NMSpikeRasterClear

//****************************************************************
//****************************************************************
//****************************************************************

Menu "GraphMarquee"

	NMSpikeGraphMarqueeMenuStr( "-" )
	
	NMSpikeGraphMarqueeMenuStr( "NM Delete Spikes From Raster" ), NMSpikeDeleteFromRaster()
	
End

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeGraphMarqueeMenuStr( menuStr )
	String menuStr
	
	Variable review
	String xWaveOrFolder
	
	if ( !IsCurrentNMTab( "Spike" ) )
		return ""
	endif
	
	if ( !StringMatch( WinName( 0, 1 ), ChanGraphName( -1 ) ) )
		return ""
	endif
	
	review = NMSpikeReviewGet()
	
	xWaveOrFolder = CurrentNMSpikeRasterOrFolder()

	if ( ( strlen( xWaveOrFolder ) > 0 ) && review )
		return menuStr
	else
		return ""
	endif

End // NMSpikeGraphMarqueeMenuStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeDeleteFromRaster( [ update ] ) // use marquee x-values for spike xbgn and xend
	Variable update

	Variable xbgn, xend
	Variable icnt, waveNum, spikes
	String gName, txt, rasterX
	
	String xunits = NMChanLabelX( units = 1 )
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( !DataFolderExists( NMSpikeDF ) || !IsCurrentNMTab( "Spike" ) )
		return 0 
	endif
	
	Variable review = NMSpikeReviewGet()
	
	if ( !review )
		DoAlert 0, "Spike Tab Alert: you must click the Review checkbox ON in order to delete a spike in the current spike raster."
		return -1
	endif

	GetMarquee /K left, bottom
	
	if ( V_Flag == 0 )
		return 0
	endif
	
	xbgn = V_left
	xend = V_right
	
	gName = S_marqueeWin
	
	if ( !StringMatch( gName, ChanGraphName( -1 ) ) )
		return -1
	endif
	
	String currentRasterX = CheckNMSpikeRasterXPath( SELECTED )
	String currentRasterY = CheckNMSpikeRasterYPath( SELECTED, SELECTED )
	
	if ( !WaveExists( $currentRasterX ) || !WaveExists( $currentRasterY ) )
		return -1
	endif
	
	Wave cRX = $currentRasterX
	Wave cRY = $currentRasterY
	
	waveNum = CurrentNMWave()
	
	rasterX = NMChild( currentRasterX )
	
	for ( icnt = numpnts( cRY ) -1 ; icnt >= 0 ; icnt -= 1 )
	
		if ( ( cRY[ icnt ] == waveNum ) && ( cRX[ icnt ] > xbgn ) && ( cRX[ icnt ] < xend ) )
			txt = "Deleted spike from wave #" + num2istr( waveNum ) + " at " + num2str( cRX[ icnt ] ) + " " + xunits + " from raster " + rasterX
			DeletePoints icnt, 1, cRX, cRY
			spikes += 1
			NMHistory( txt )
		endif
		
	endfor
	
	if ( spikes == 1 )
		NMHistory( "Deleted " + num2str( spikes ) + " spike from " + rasterX )
	elseif ( spikes > 1 )
		NMHistory( "Deleted " + num2str( spikes ) + " spikes from " + rasterX )
	endif
	
	if ( update )
		NMSpikeAuto( force = 1 )
		NMSpikeUpdate()
	endif

End // NMSpikeDeleteFromRaster

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Spike functions not used anymore
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMSpikeVar( varName ) // NOT USED
	String varName
	
	return NMSpikeVarGet( varName )
	
End // NMSpikeVar

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeStr( strVarName ) // NOT USED
	String strVarName
	
	return NMSpikeStrGet( strVarName )
	
End // NMSpikeStr

//****************************************************************
//****************************************************************
//****************************************************************

Static Function zNMSpikeConfigVar( varName, description, type ) // NOT USED
	String varName
	String description
	String type
	
	return NMConfigVar( "Spike", varName, NMSpikeVarGet( varName ), description, type )
	
End // zNMSpikeConfigVar

//****************************************************************
//****************************************************************
//****************************************************************

Static Function zNMSpikeConfigStr( strVarName, description, type ) // NOT USED
	String strVarName
	String description
	String type
	
	return NMConfigStr( "Spike", strVarName, NMSpikeStrGet( strVarName ), description, type )
	
End // zNMSpikeConfigStr

//****************************************************************
//****************************************************************
//****************************************************************

Function SetNMSpikeVar( varName, value ) // NOT USED
	String varName
	Variable value
	
	if ( strlen( varName ) == 0 )
		return NM2Error( 21, "varName", varName )
	endif
	
	if ( !DataFolderExists( NMSpikeDF ) )
		return NM2Error( 30, "SpikeDF", NMSpikeDF )
	endif
	
	Variable /G $NMSpikeDF+varName = value
	
	return 0
	
End // SetNMSpikeVar

//****************************************************************
//****************************************************************
//****************************************************************

Function SetNMSpikeStr( strVarName, strValue ) // NOT USED
	String strVarName
	String strValue
	
	if ( strlen( strVarName ) == 0 )
		return NM2Error( 21, "strVarName", strVarName )
	endif
	
	if ( !DataFolderExists( NMSpikeDF ) )
		return NM2Error( 30, "SpikeDF", NMSpikeDF )
	endif
	
	String /G $NMSpikeDF+strVarName = strValue
	
	return 0
	
End // SetNMSpikeStr

//****************************************************************
//****************************************************************
//****************************************************************

Function SetNMSpikeWave( wName, pnt, value ) // NOT USED
	String wName
	Variable pnt // point to set, or ( -1 ) all points
	Variable value
	
	if ( strlen( wName ) == 0 )
		return NM2Error( 21, "wName", wName )
	endif
	
	if ( !DataFolderExists( NMSpikeDF ) )
		return NM2Error( 30, "SpikeDF", NMSpikeDF )
	endif
	
	return SetNMwave( NMSpikeDF+wName, pnt, value )
	
End // SetNMSpikeWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSpikeObjectName( oName ) // NOT USED
	String oName
	
	return NMSpikeDF + oName
	
End // NMSpikeObjectName

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S CurrentNMSpikeRasterOrFolderSet( xWaveOrFolder ) // NOT USED
	String xWaveOrFolder

	SetNMstr( CurrentNMPrefixFolder() + "SpikeRasterXSelect", xWaveOrFolder )
	
End // CurrentNMSpikeRasterOrFolderSet

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeWinBgn() // NOT USED

	Variable t = NMSpikeVarGet( "Xbgn" )

	if ( numtype( t ) > 0 )
		t = leftx( $ChanDisplayWave( -1 ) )
	endif
	
	return t

End // SpikeWinBgn

//****************************************************************
//****************************************************************
//****************************************************************

Function SpikeWinEnd() // NOT USED

	Variable t = NMSpikeVarGet( "Xend" )

	if ( numtype( t ) > 0 )
		t = rightx( $ChanDisplayWave( -1 ) )
	endif
	
	return t

End // SpikeWinEnd

//****************************************************************
//****************************************************************
//****************************************************************

Function XTimes2Spike() // : GraphMarquee // NOT USED
	
	if ( !DataFolderExists( NMSpikeDF ) || !IsCurrentNMTab( "Spike" ) )
		return 0 
	endif

	GetMarquee /K left, bottom
	
	if ( V_Flag == 0 )
		return 0
	endif
	
	SetNMvar( NMSpikeDF + "Xbgn", V_left )
	SetNMvar( NMSpikeDF + "Xend", V_right )
	
	NMSpikeAuto( force = 1 )

End // XTimes2Spike

//****************************************************************
//****************************************************************
//****************************************************************

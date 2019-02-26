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
//	Folder Functions
//
//	Useful Functions:
//
//		NMFolderNew( folderNameList [ update, history ] )
//		NMFolderChange( folderName [ update, history ] )
//		NMFolderClose( folderNameList [ update, history ] )
//		NMFolderDuplicate( folderName, newName [ history ] )
//		NMFolderRename( oldName, newName [ history ] )
//		NMDataReload( [ history ] )
//		NMFolderSaveAll( [ fileType, waveFileType, saveWaveNotes, saveSubfolders, dialogue, path, history ] )
//		NMPrefixSubfolderKill( killList [ history ] )
//		NMPrefixListSet( prefixList [ history ] )
//		NMPrefixListClear( [ history ] )
//		NMPrefixAdd( addList [ history ] )
//		NMPrefixRemove( removeList [ history ] )
//		
//****************************************************************
//****************************************************************

Function /S NMFolderCall( fxn )
	String fxn
	
	String promptStr
	
	strswitch( fxn )
	
		case "Edit FolderList":
			NMFolderListEdit()
			break
	
		case "New":
			NMFolderNewCall()
			break
			
		case "Check":
		case "Check NM globals":
			CheckNMDataFolder( GetDataFolder( 1 ), history = 1)
			break
			
		case "Open":
		case "Open Data File":
		case "Open Data Files":
			NMFileOpen()
			break
		
		case "Open All":
		case "Open All Data Files From Folder":
			NMFileOpenAll( "", alert = 1 )
			break
			
		case "Open All Data Files Inside Subfolders":
			NMFileOpenAllSubfolders( "", alert = 1 )
			break
		
		case "Merge":
			NMFoldersMerge()
			break
			
		case "Save":
			NMFolderSaveCall()
			break
			
		case "Save All":
			NMFolderSaveAllCall()
			break
		
		case "Kill":
		case "Close":
			NMFolderCloseCurrentCall()
			break
			
		case "Kill All":
		case "Close All":
			NMFolderCloseAllCall()
			break
			
		case "Duplicate":
			NMFolderDuplicateCall()
			break
			
		case "Rename":
			NMFolderRenameCall()
			break
			
		case "Change":
			NMFolderChangeCall()
			break
			
		case "Import":
		case "Import Data":
		case "Import Waves":
		case "Load Waves":
		case "Load Waves From Files":
			NMImportWavesCall()
			break
			
		case "Load Waves From Folder":
			NMLoadAllWavesFromExtFolderCall()
			break
			
		case "Save Waves":
			NMMainCall( "Save", "" )
			break
			
		case "Reload":
		case "Reload Data":
		case "Reload Waves":
			NMDataReloadCall()
			break
			
		case "Rename Waves":
			promptStr = "Rename Waves : " + CurrentNMFolder( 0 )
			return NMRenameWavesCall( "", promptStr = promptStr )
			
		case "Convert":
		case "Convert nmb to pxp":
			NMBin2IgorBinCall()
			break
			
		case "Open Path":
		case "Set Open Path":
			SetOpenDataPathCall()
			break
			
		case "Save Path":
		case "Set Save Path":
			SetSaveDataPathCall()
			break
			
		case "File Name Replace Strings":
			NMFileNameReplaceStringListEdit()
			break
			
		default:
			NMDoAlert( "NMFolderCall: unrecognized function call: " + fxn )
			
	endswitch
	
End // NMFolderCall

//****************************************************************
//****************************************************************
//****************************************************************

Function SetOpenDataPathCall()

	String defaultFolderPath = StrVarOrDefault( NMDF+"OpenDataPath", "" )

	String pathStr = NMGetExternalFolderPath( "Set Open File Path", defaultFolderPath )
	
	if ( strlen( pathStr ) == 0 )
		return 0
	endif

	return NMSet( openPath = pathStr, history = 1 )

End // SetOpenDataPathCall

//****************************************************************
//****************************************************************
//****************************************************************

Function SetSaveDataPathCall()

	String defaultFolderPath = StrVarOrDefault( NMDF+"SaveDataPath", "" )

	String pathStr = NMGetExternalFolderPath( "Set Save File Path", defaultFolderPath )
	
	if ( strlen( pathStr ) == 0 )
		return 0
	endif

	return NMSet( savePath = pathStr, history = 1 )

End // SetSaveDataPathCall

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckCurrentFolder() // check to make sure we are sitting in the current NM folder

	String currentFolder = StrVarOrDefault( NMDF + "CurrentFolder", "" )
	
	if ( !NMVarGet( "NMOn" ) )
		return 0
	endif

	if ( StringMatch( currentFolder, GetDataFolder( 1 ) ) )
		return 1 // OK
	endif
	
	if ( ( strlen( currentFolder ) > 0 ) && DataFolderExists( currentFolder ) )
		SetDataFolder $currentFolder
		UpdateNM( 0 )
		return 1
	endif
	
	return 0

End // CheckCurrentFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMWavePrefix()

	String currentFolder = StrVarOrDefault( NMDF + "CurrentFolder", "" )

	return StrVarOrDefault( currentFolder + "CurrentPrefix", "" )

End // CurrentNMWavePrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMFolder( path )
	Variable path // ( 0 ) no path ( 1 ) with path
	
	String currentFolder = StrVarOrDefault( NMDF + "CurrentFolder", "" )
	
	if ( strlen( currentFolder ) == 0 )
		return ""
	endif
	
	if ( !IsNMDataFolder( currentFolder ) )
		return ""
	endif
	
	if ( !path )
		return NMChild( currentFolder )
	endif
	
	return currentFolder

End // CurrentNMFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CheckNMFolderPath( folder ) // make sure folder name is full-path
	String folder
	
	String df
	
	String currentFolder = StrVarOrDefault( NMDF + "CurrentFolder", "" )
	
	if ( strlen( folder ) == 0 )
		return currentFolder
	endif
	
	if ( StringMatch( folder[ 0, 4 ], "root:" ) )
		return LastPathColon( folder, 1 )
	endif
	
	if ( strlen( currentFolder ) > 0 )

		df = currentFolder + folder
	
		if ( DataFolderExists( df ) )
			return LastPathColon( df, 1 ) // this is an existing subfolder
		endif
		
	endif
	
	df = "root:" + folder
	
	return LastPathColon( df, 1 )

End // CheckNMFolderPath

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CheckNMWavePath( folder, wList ) // make sure wave name is full-path
	String folder
	String wList
	
	Variable wcnt, numWaves = ItemsInList( wList )
	String wName, wName2, wList2 = ""
	
	if ( numWaves == 0 )
		return ""
	endif
	
	folder = CheckNMFolderPath( folder )
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
		
		wName = StringFromList( wcnt, wList )
		
		if ( strlen( wName ) == 0 )
			continue
		endif
		
		if ( StringMatch( wName[ 0, 4 ], "root:" ) )
			wName2 = wName
		else
			wName2 = folder + wName
		endif
		
		wList2 += wName2 + ";"
	
	endfor
	
	numWaves = ItemsInList( wList2 )
	
	if ( numWaves == 0 )
		return ""
	endif
	
	if ( numWaves == 1 )
		return StringFromList( 0, wList2 )
	endif
	
	return wList2
	
End // CheckNMWavePath

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMDataFolders() // check all NM Data folders

	Variable icnt

	String fList = NMDataFolderList()
	
	for ( icnt = 0 ; icnt < ItemsInList( fList ) ; icnt += 1 )
		CheckNMDataFolder( StringFromList( icnt, fList ) )
	endfor
	
End // CheckNMDataFolders

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMDataFolder( folderName [ history ] ) // check data folder globals
	String folderName
	Variable history
	
	Variable icnt, ccnt, changeFolder
	String wavePrefix, subfolder, stimDF, wList, wName
	
	String versionStr = NMStrGet( "NMVersionStr" )
	
	String saveCurrentFolder = NMStrGet( "CurrentFolder" )
	
	String vlist = NMCmdStr( folderName, "" )
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	folderName = CheckNMFolderPath( folderName )
	
	if ( !DataFolderExists( folderName ) )
		return -1
	endif
	
	if ( !StringMatch( folderName, saveCurrentFolder ) )
		changeFolder = 1
		SetNMstr( NMDF+"CurrentFolder", folderName )
	endif
 
	wavePrefix = StrVarOrDefault( folderName+"WavePrefix", "" )
	
	CheckNMFolderType( folderName )
	
	CheckNMvar( folderName+"FileFormat", NMVersionNum() )
	CheckNMstr( folderName+"FileFormatStr", "NM" + versionStr )
	CheckNMvar( folderName+"FileDateTime", DateTime )
	
	if ( exists( folderName+"FileType" ) == 2 )
		if ( StringMatch( StrVarOrDefault( folderName+"FileType", "test" ), "test" ) )
			KillVariables /Z $folderName+"FileType"
		endif
	endif
	
	CheckNMstr( folderName+"FileType", "NMData" )
	CheckNMstr( folderName+"FileDate", date() )
	CheckNMstr( folderName+"FileTime", time() )
	
	CheckOldNMDataNotes( folderName )
	
	stimDF = SubStimName( folderName, fullPath = 1 )
	
	if ( strlen( stimDF ) > 0 )
	
		wList = NMFolderWaveList( stimDF, "*_pulse", ";", "", 0 )
		
		for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
			wName = StringFromList( icnt, wList )
			NMStimWavesPulseUpdate( stimDF, wName )
		endfor
		
	endif
	
	NMPrefixFolderUtility( folderName, "rename" ) // new names for old prefix subfolders
	
	CheckNMDataFolderFormat6( folderName )
	
	NMPrefixFolderUtility( folderName, "check" ) // check for globals
	NMPrefixFolderUtility( folderName, "unlock" ) // remove old locks if they exist since they did not work well
	
	for ( ccnt = 0 ; ccnt < NMNumChannels() ; ccnt += 1 )
		ChanGraphSetCoordinates( ccnt )
	endfor
	
	//subfolder = NMPrefixFolderDF( folderName, wavePrefix )
	
	//if ( ( NumVarOrDefault( subfolder+"NumGrps", 0 ) == 0 ) && ( exists( "NumStimWaves" ) == 2 ) )
	//	SetNMvar( subfolder+"NumGrps", NumVarOrDefault( "NumStimWaves", 0 ) )
	//	SetNMvar( subfolder+"CurrentGrp", Nan )
	//	NMGroupSeqDefault() // set Groups for Nclamp data
	//endif
	
	CheckNMFolderList()
	
	if ( changeFolder )
		SetNMstr( NMDF+"CurrentFolder", saveCurrentFolder )
	endif
	
	return 0
	
End // CheckNMDataFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMDataFolderFormat6( folderName )
	String folderName

	Variable icnt
	String vname, waveSelect
	
	if ( strlen( folderName ) == 0 )
		return -1
	endif
	
	String setList = NMSetsWavesList( folderName, 0 )
	
	String wlist = "ChanSelect;ChanWaveList;WavSelect;Group;"
	String vList = "NumChannels;CurrentChan;NumWaves;CurrentWave;"
	String kvList = "SumSet1;SumSet2;SumSetX;NumActiveWaves;CurrentChan;CurrentWave;CurrentGrp;FirstGrp;"
	
	String currentPrefix = StrVarOrDefault( folderName+"CurrentPrefix", "" )
	String prefixFolder = NMPrefixFolderDF( folderName, currentPrefix )
	
	Variable numChannels = NumVarOrDefault( folderName+"NumChannels", 0 )
	Variable numWaves = NumVarOrDefault( folderName+"NumWaves", 0 )
	
	if ( strlen( currentPrefix ) == 0 )
		return 0 // nothing to update
	endif
	
	String twList = NMFolderWaveList( folderName, "wNames_*", ";", "TEXT:1", 0 )
	
	vname = folderName+"WavSelect"
	
	if ( WaveExists( $folderName+"WaveSelect" ) && !WaveExists( $vname ) )
		Rename $folderName+"WaveSelect" $vname // rename old wave
	endif

	if ( !WaveExists( $folderName+"ChanSelect" ) && !WaveExists( $vname ) )
		return 0 // nothing to do, must be new NM data folder format
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif
	
	if ( !DataFolderExists( prefixFolder ) )
		NewDataFolder $RemoveEnding( prefixFolder, ":" )
	endif
	
	for ( icnt = 0 ; icnt < ItemsInList( vList ) ; icnt += 1 ) // copy old variables to new subfolder
	
		vname = StringFromList( icnt, vList )
		
		if ( exists( folderName+vname ) != 2 )
			continue
		endif
		
		Variable /G $prefixFolder+vname = NumVarOrDefault( folderName+vname, Nan )
		
	endfor
	
	for ( icnt = 0 ; icnt < ItemsInList( kvList ) ; icnt += 1 ) // kill unecessary old variables
	
		vname = StringFromList( icnt, kvList )
		
		if ( exists( folderName+vname ) == 2 )
			KillVariables /Z $folderName+vname
		endif

	endfor
	
	wList = NMAddToList( setList, wList, ";" )
	wList = NMAddToList( twList, wList, ";" )
	
	for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 ) // copy old waves to new subfolder
	
		vname = StringFromList( icnt, wList )
		
		if ( !WaveExists( $folderName+vname ) )
			continue
		endif
		
		Duplicate /O $folderName+vname $prefixFolder+vname
		
		if ( WaveExists( $prefixFolder+vname ) )
			KillWaves /Z $folderName+vname
		endif
		
	endfor
	
	for ( icnt = 0 ; icnt < numChannels ; icnt += 1 ) // copy channel graph folders to new subfolder
		
		vname = ChanGraphName( icnt ) // channel graph folder name
		
		if ( DataFolderExists( folderName+vname ) && !DataFolderExists( prefixFolder+vname ) )
		
			DuplicateDataFolder $folderName+vname $prefixFolder+vname
			
			if ( DataFolderExists( prefixFolder+vname ) )
				KillDataFolder /Z $folderName+vname
			endif
			
		endif
		
	endfor
	
	folderName = NMChild( folderName )
	
	NMHistory( "Converted NM data folder " + NMQuotes( folderName ) + " to version " + NMVersionStr )

End // CheckNMDataFolderFormat6

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckOldNMDataNotes( folderName ) // check data notes of old NM acquired data
	String folderName
	
	Variable ccnt, wcnt
	String wList, wNote, yl
	
	String wname = "ChanWaveList" // OLD WAVE
	String ywname = "yLabel"
	
	folderName = CheckNMFolderPath( folderName )
	
	if ( !DataFolderExists( folderName ) )
		return 0
	endif
	
	String wavePrefix = StrVarOrDefault( folderName+"WavePrefix", "" )
	
	if ( strlen( wavePrefix ) == 0 )
		return 0 // nothing to do
	endif
	
	if ( !WaveExists( $wname ) || !WaveExists( $ywname ) )
		return 0
	endif
	
	String type = StrVarOrDefault( folderName+"DataFileType", "" )
	String file = StrVarOrDefault( folderName+"CurrentFile", "" )
	String fdate = StrVarOrDefault( folderName+"FileDate", "" )
	String ftime = StrVarOrDefault( folderName+"FileTime", "" )
	
	String xl = StrVarOrDefault( "xLabel", "" )
	
	String stim = SubStimName( folderName )
	
	Wave /T wtemp = $wname
	Wave /T ytemp = $ywname
	
	strswitch( type )
		case "IgorBin":
		case "NMBin":
			type = "NMData"
	endswitch
	
	for ( ccnt = 0; ccnt < numpnts( wtemp ); ccnt += 1 )
	
		wList = wtemp[ ccnt ]
		
		if ( ccnt < numpnts( ytemp ) )
			yl = ytemp[ ccnt ]
		else
			yl = ""
		endif
		
		for ( wcnt = 0; wcnt < ItemsInlist( wList ); wcnt += 1 )
		
			wname = StringFromList( wcnt, wList )
			
			if ( !WaveExists( $folderName+wname ) )
				continue
			endif
			
			if ( strsearch( wname, wavePrefix, 0, 2 ) < 0 )
				continue
			endif
			
			if ( strlen( NMNoteStrByKey( folderName+wname, "Type" ) ) == 0 )
			
				if ( strlen( stim ) > 0 )
					wNote = "Stim:" + stim
				else
					wNote = "Stim:NONE"
				endif
				
				wNote += NMCR + "Folder:" + NMChild( folderName )
				wNote += NMCR + "Date:" + NMNoteCheck( fdate )
				wNote += NMCR + "Time:" + NMNoteCheck( ftime )
				wNote += NMCR + "Chan:" + ChanNum2Char( ccnt )
				
				NMNoteType( folderName+wname, type, xl, yl, wNote )
				
			endif
			
			if ( strlen( NMNoteStrByKey( folderName+wname, "File" ) ) == 0 )
				Note $folderName+wname, "File:" + NMNoteCheck( file )
			endif
			
		endfor
	
	endfor
	
End // CheckOldNMDataNotes

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMFolderType( folderName )
	String folderName
	
	folderName = CheckNMFolderPath( folderName )
	
	if ( !DataFolderExists( folderName ) )
		return -1
	endif
	
	if ( exists( folderName+"FileType" ) == 0 )
		return -1
	endif

	String ftype = StrVarOrDefault( folderName+"FileType", "" )
	
	if ( StringMatch( ftype, "pclamp" ) )
	
		SetNMstr( folderName+"DataFileType", "pclamp" )
		SetNMstr( folderName+"FileType", "NMData" )
		
	elseif ( StringMatch( ftype, "axograph" ) )
	
		SetNMstr( folderName+"DataFileType", "axograph" )
		SetNMstr( folderName+"FileType", "NMData" )
		
	elseif ( strlen( ftype ) == 0 )
	
		SetNMstr( folderName+"FileType", "NMData" )
		
	endif
	
	return 0

End // CheckNMFolderType

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderNewCall()

	String folderName = FolderNameNext( "" )
	
	Prompt folderName, "enter new folder name:"
	DoPrompt "Create New NeuroMatic Folder", folderName
	
	if ( V_flag == 1 )
		return 0 // cancel
	endif
	
	NMFolderNew( folderName, history = 1 )

End // NMFolderNewCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderNew( folderNameList [ setCurrent, update, history ] )
	String folderNameList // list of folder names, or "" for next default name
	Variable setCurrent
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable icnt
	String folderName, fList = ""
	
	String vlist = NMCmdStr( folderNameList, "" )
	
	if ( ParamIsDefault( setCurrent ) )
		setCurrent = 1
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( ItemsInList( folderNameList ) == 0 )
		folderNameList = FolderNameNext( "" )
	endif
	
	for ( icnt = 0 ; icnt < ItemsInList( folderNameList ) ; icnt += 1 )
	
		folderName = StringFromList( icnt, folderNameList )
	
		if ( strlen( folderName ) == 0 )
			folderName = FolderNameNext( "" )
		else
			folderName = NMChild( folderName )
		endif
		
		folderName = CheckFolderName( folderName )
		
		if ( strlen( folderName ) == 0 )
			continue
		endif
		
		folderName = "root:" + folderName + ":"
	
		if ( DataFolderExists( folderName ) )
			return "" // already exists
		endif
		
		if ( setCurrent )
		
			NewDataFolder /S $RemoveEnding( folderName, ":" )
			
			SetNMstr( NMDF + "CurrentFolder", GetDataFolder( 1 ) )
			
		else
		
			NewDataFolder $RemoveEnding( folderName, ":" )
			
		endif
		
		CheckNMDataFolder( folderName )
		NMFolderListAdd( folderName )
		
		fList = AddListItem( folderName, fList, ";", inf )
	
	endfor
	
	if ( update )
		ChanGraphsReset()
		UpdateNM( 1 )
	endif
	
	if ( ItemsInList( fList ) == 1 )
		return StringFromList( 0, fList )
	else
		return fList
	endif

End // NMFolderNew

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderChangeCall() // change the active folder

	String folderName, vlist, fList = NMDataFolderList()
	
	folderName = StringFromList( 0, fList )
	
	folderName = NMChild( folderName )
	
	fList = RemoveFromList( CurrentNMFolder( 0 ) , fList ) // remove active folder from list

	If ( ItemsInList( fList ) == 0 )
		NMDoAlert( "Abort NMFolderChange: no folders to change to." )
		return ""
	endif
	
	Prompt folderName, "select folder:", popup fList
	DoPrompt "Change NeuroMatic Folder", folderName
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	NMSet( folder = folderName, history = 1 )
	
	return folderName

End // NMFolderChangeCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderChange( folderName [ update, history ] ) // change the active folder
	String folderName
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	String vlist = NMCmdStrOptional( "folder", folderName, "" )
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( strlen( folderName ) == 0 )
		return ""
	endif
	
	folderName = CheckNMFolderPath( folderName )
	
	if ( !DataFolderExists( folderName ) )
		NMDoAlert( "Abort NMFolderChange: " + folderName + " does not exist." )
		return ""
	endif
	
	if ( IsNMFolder( folderName, "NMLog" ) )
		LogDisplayCall( folderName )
		return ""
	endif
	
	if ( !IsNMDataFolder( folderName ) )
		return ""
	endif
	
	if ( strlen( NMFolderListName( folderName ) ) == 0 )
		NMFolderListAdd( folderName )
	endif
	
	NMChannelGraphConfigsSave( -2 )
	ChanScaleSave( -2 )
	
	SetDataFolder $folderName
	
	SetNMstr( NMDF+"CurrentFolder", GetDataFolder( 1 ) )
	
	if ( update )
		ChanGraphsReset()
		NMChanWaveListSet( 0 ) // check channel wave names
		UpdateNM( 1 )
	endif
	
	return folderName

End // NMFolderChange

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderChangeToFirst( [ update ] )
	Variable update
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif

	String fList = NMDataFolderList()
		
	if ( ItemsInList( fList ) > 0 )
		return NMFolderChange( StringFromList( 0, fList ), update = update ) // change to first data folder
	else
		return NMFolderNew( "", update = update )
	endif
		
End // NMFolderChangeToFirst

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderCloseAllCall()

	DoAlert 1, "Are you sure you want to close all NeuroMatic data folders?"
			
	if ( V_Flag != 1 )
		return 0
	endif
	
	return NMFolderClose( "All", history = 1 )
	
End //  NMFolderCloseAllCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderCloseCurrentCall()

	String folderName = CurrentNMFolder( 0 )

	String txt = "Are you sure you want to close " + NMQuotes( folderName ) + "?"
	txt += " This will kill all graphs, tables and waves associated with this folder."
	
	DoAlert 1, txt
	
	if ( V_flag != 1 )
		return 0
	endif
	
	return NMFolderClose( folderName, changeToFolder = "previous", history = 1 )

End // NMFolderCloseCurrentCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderClose( folderNameList [ changeToFolder, update, history ] ) // close/kill a data folder
	String folderNameList // folder path ( "" ) for current folder ( "All" ) to close all NM data folders
	String changeToFolder // folder to change to after closing folderNameList, or "next" or "previous" or "new"
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable inum, fcnt, forceChange, closeLogs
	String wname, folderName, folderNameShort, currentFolder, fList, failureList = ""
	
	String vlist = NMCmdStr( folderNameList, "" )
	
	if ( ParamIsDefault( changeToFolder ) )
		changeToFolder = "previous"
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	currentFolder = CurrentNMFolder( 0 )
	fList = NMDataFolderList()
	
	if ( strlen( folderNameList ) == 0 )
		folderNameList = StrVarOrDefault( NMDF + "CurrentFolder", "" )
	elseif ( StringMatch( folderNameList, "All" ) )
		folderNameList = fList
		closeLogs = 1
	endif
	
	if ( StringMatch( changeToFolder, "previous" ) )
		changeToFolder = NMFolderChangeToFolder( folderNameList, -1 )
	elseif ( StringMatch( changeToFolder, "next" ) )
		changeToFolder = NMFolderChangeToFolder( folderNameList, +1 )
	endif
	
	for ( fcnt = 0 ; fcnt < ItemsInList( folderNameList ) ; fcnt += 1 )
	
		folderName = StringFromList( fcnt, folderNameList )
	
		folderName = CheckNMFolderPath( folderName )
		
		if ( !DataFolderExists( folderName ) )
			continue
		endif
		
		folderNameShort = NMChild( folderName )
		
		inum = WhichListItem( folderNameShort, fList )
		
		if ( inum < 0 )
			continue
		endif
		
		//NMKillWindows( folderName ) // old kill method // kills too much
		NMFolderWinKill( folderName ) // new FolderList function
		
		if ( StringMatch( currentFolder, folderNameShort ) )
			ChanGraphClose( -2, 0 )
		endif
		
		NMPrefixFolderUtility( folderName, "unlock" )
	
		KillDataFolder /Z $folderName
	
		if ( DataFolderExists( folderName ) )
			failureList = AddListItem( folderName, failureList, ";", inf )
		else
			NMFolderListRemove( folderName )
		endif
	
	endfor
	
	if ( closeLogs )
	
		folderNameList = NMFolderList( "root:","NMLog" )
		
		for ( fcnt = 0 ; fcnt < ItemsInList( folderNameList ) ; fcnt += 1 )
	
			folderName = StringFromList( fcnt, folderNameList )
		
			folderName = CheckNMFolderPath( folderName )
			
			if ( !DataFolderExists( folderName ) )
				continue
			endif
			
			folderNameShort = NMChild( folderName )
			
			//NMKillWindows( folderName ) // old kill method // kills too much
			NMFolderWinKill( folderName ) // new FolderList function
		
			KillDataFolder /Z $folderName
		
			if ( DataFolderExists( folderName ) )
				failureList = AddListItem( folderName, failureList, ";", inf )
			else
				NMFolderListRemove( folderName )
			endif
		
		endfor
		
	endif
	
	if ( ItemsInList( failureList ) > 0 )
		NMFolderCloseAlert( failureList )
	endif
	
	fList = NMDataFolderList()
	
	if ( WhichListItem( currentFolder, fList ) >= 0 )
		return 0
	endif
	
	if ( StringMatch( changeToFolder, "new" ) || ( strlen( changeToFolder ) == 0 ) )
	
		NMFolderNew( "", update = update )
		
	elseif ( WhichListItem( changeToFolder, fList ) >= 0 )
	
		SetNMstr( NMDF + "CurrentFolder", "" )
		NMFolderChange( changeToFolder, update = update )
		
	else
	
		SetNMstr( NMDF + "CurrentFolder", "" )
		NMFolderChangeToFirst( update = update )
		
	endif
	
	return 0

End // NMFolderClose

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderCloseAlert( folderNameList )
	String folderNameList
	
	String txt
	Variable items = ItemsInList( folderNameList )
	
	if ( items == 0 )
		return 0
	elseif ( items == 1 )
		txt = "Failed to close data folder " + NMQuotes( NMChild( StringFromList( 0, folderNameList ) ) )
		txt += ". Waves that reside in this folder may be currently displayed in a graph or table"
		txt += ", or may be locked."
	else
		txt = "Failed to close data folders: " + NMChild( folderNameList )
		txt += " Waves that reside in these folders may be currently displayed in a graph or table"
		txt += ", or may be locked."
	endif
	
	NMDoAlert( txt )

End // NMFolderCloseAlert

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderChangeToFolder( folderNameList, direction )
	String folderNameList
	Variable direction // ( -1 ) previous folder ( +1 ) next folder
	
	Variable fcnt, inum, imax = -inf, imin = inf
	String folderName, folderNameShort
	
	String fList = NMDataFolderList()
	String fList2 = RemoveFromList( folderNameList, fList )
	
	if ( ItemsInList( fList2 ) == 0 )
		return "" // no folders to change to
	endif
	
	for ( fcnt = 0 ; fcnt < ItemsInList( folderNameList ) ; fcnt += 1 )
	
		folderName = StringFromList( fcnt, folderNameList )
	
		folderName = CheckNMFolderPath( folderName )
		
		if ( !DataFolderExists( folderName ) )
			continue
		endif
		
		folderNameShort = NMChild( folderName )
		
		inum = WhichListItem( folderNameShort, fList )
		
		if ( inum < 0 )
			continue
		endif
		
		imin = min( imin, inum )
		imax = max( imax, inum )
	
	endfor
	
	if ( numtype( imin * imax ) > 0 )
		return ""
	endif
	
	imin -= 1
	imax += 1
	
	if ( direction == -1 )
	
		if ( imin < 0 )
			return StringFromList( 0, fList2 )
		endif
	
		return StringFromList( imin, fList )
		
	else
	
		if ( imax >= ItemsInList( fList ) - 1 )
			return StringFromList( ItemsInList( fList2 ) - 1, fList2 )
		endif
	
		return StringFromList( imax, fList )
		
	endif
	
End // NMFolderChangeToFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function NMKillWindows( folderName )
	String folderName
	
	Variable wcnt
	String wName
	
	if ( ( strlen( folderName ) == 0 ) || ( !IsNMDataFolder( folderName ) ) )
		return -1
	endif
	
	folderName = NMChild( folderName )
	
	String wlist = WinList( "*" + folderName + "*", ";", "" )
	
	for ( wcnt = 0; wcnt < ItemsInList( wlist ); wcnt += 1 )
	
		wName = StringFromList( wcnt,wlist )
		
		if ( ( strlen( wName ) > 0 ) && ( winType( wName ) > 0 ) )
			DoWindow /K $wName
		endif
		
	endfor
	
	return 0
	
End // NMKillWindows

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderWinKill( folderName )
	String folderName
	
	String wname
	Variable wcnt
	
	if ( !IsNMDataFolder( folderName ) )
		return -1
	endif
	
	String wlist = WinList( "*" + NMFolderListName( folderName ) + "_" + "*", ";", "" )
	
	for ( wcnt = 0; wcnt < ItemsInList( wlist ); wcnt += 1 )
		
		wname = StringFromList( wcnt,wlist )
		
		if ( WinType( wname ) == 0 )
			continue
		endif
		
		DoWindow /K $wname
		
	endfor
	
	return 0
	
End // NMFolderWinKill

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderDuplicateCall()

	String folderName = CurrentNMFolder( 0 )
	String newName = FolderNameNext( folderName + "_copy0" )
	
	Prompt newName, "enter new folder name:"
	DoPrompt "Duplicate NeuroMatic Data Folder", newName
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	if ( StringMatch( folderName, newName ) )
		return -1 // not allowed
	endif
	
	//if ( DataFolderExists( CheckNMFolderPath( newName ) ) )
	//	NMDoAlert( "Abort NMFolderDuplicate: folder name already in use."
	//	return -1
	//endif
	
	NMFolderDuplicate( folderName, newName, history = 1 )
	
	return 0

End // NMFolderDuplicateCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderDuplicate( folderName, newName [ history ] ) // duplicate NeuroMatic data folder
	String folderName // folder to copy
	String newName
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	String newFolder, vlist = ""
	
	if ( history )
		vlist = NMCmdStr( folderName, vlist )
		vlist = NMCmdStr( newName, vlist )
		NMCommandHistory( vlist )
	endif
	
	folderName = CheckNMFolderPath( folderName )
	
	if ( !DataFolderExists( folderName ) )
		return ""
	endif
	
	newFolder = CheckNMFolderPath( newName )
	newFolder = CheckFolderName( newFolder )
	
	if ( ( strlen( newFolder ) == 0 ) || DataFolderExists( newFolder ) )
		return ""
	endif
	
	DuplicateDataFolder $RemoveEnding( folderName, ":" ), $RemoveEnding( newFolder, ":" )
	
	NMFolderListAdd( newName )
	
	return newName

End // NMFolderDuplicate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderRenameCall()

	String oldName = CurrentNMFolder( 0 )
	String newName = oldName
	
	Prompt newName, "rename " + NMQuotes( oldName ) + " as:"
	DoPrompt "Rename NeuroMatic Data Folder", newName
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	if ( StringMatch( oldName, newName ) )
		return -1 // nothing new
	endif
	
	//if ( DataFolderExists( CheckNMFolderPath( newName ) ) )
	//	NMDoAlert( "Abort NMFolderRename: folder name already in use."
	//	return -1
	//endif
	
	NMFolderRename( oldName, newName, history = 1 )
	
	return 0

End // NMFolderRenameCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderRename( oldName, newName [ history ] ) // rename NeuroMatic data folder
	String oldName
	String newName
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	String vlist = ""
	
	if ( history )
		vlist = NMCmdStr( oldName, vlist )
		vlist = NMCmdStr( newName, vlist )
		NMCommandHistory( vlist )
	endif
	
	oldName = CheckNMFolderPath( oldName )
	
	if ( !DataFolderExists( oldName ) )
		return ""
	endif
	
	oldName = NMChild( oldName )
	newName = NMChild( newName )
	newName = NMCheckStringName( newName )
	
	// note, this function does NOT change graph or table names
	// associated with the old folder name
	
	if ( ( strlen( oldName ) == 0 ) || ( strlen( newName ) == 0 ) )
		return ""
	endif
	
	if ( !DataFolderExists( "root:" + oldName ) )
		NMDoAlert( "Abort NMFolderRename: folder " + NMQuotes( oldName ) + " does not exist" )
		return ""
	endif
	
	if ( DataFolderExists( "root:" + newName ) )
		NMDoAlert( "Abort NMFolderRename: folder name " + NMQuotes( newName ) + " is already in use." )
		return ""
	endif
	
	RenameDataFolder $"root:"+oldName, $newName
	
	NMFolderListChange( oldName, newName )
	
	SetNMstr( NMDF+"CurrentFolder", GetDataFolder( 1 ) )
	
	UpdateNM( 0 )
	
	return newName

End // NMFolderRename

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderOpen()

	return NMFileOpen()

End // NMFolderOpen

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFileOpen()

	String extStr = "?"
	
	Variable nmPrefix = 0 // leave name as is
	
	String fname = NMFileBinOpen( 1, extStr, "root:", "OpenDataPath", "", 1, nmPrefix = nmPrefix, history = 1 )
	
	NMTab( "Main" ) // force back to Main tab
	UpdateNM( 1 )
	
	return fname

End // NMFileOpen

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFileOpenAll( extFolderPath [ alert, update ] )
	String extFolderPath
	Variable alert
	Variable update

	Variable numFiles, fcnt
	String shortName, fileList, fileList2 = "", folderList, fileName
	String extStr = "?"
	
	Variable nmPrefix = 0 // leave name as is
	
	if ( ParamIsDefault( alert ) )
		alert = 1
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( strlen( extFolderPath ) == 0 )
	
		extFolderPath = NMGetExternalFolderPath( "select folder where data files are located", "" )
		
		if ( strlen( extFolderPath ) == 0 )
			return ""
		endif
		
	endif
	
	shortName = NMChild( extFolderPath )
	
	NewPath /Q/O NMOpenAllFilesPath, extFolderPath
	
	if ( V_flag != 0 )
		return "" // error in creating path
	endif
	
	fileList = IndexedFile( NMOpenAllFilesPath, -1, "????" )
				
	numFiles = ItemsInList( fileList )
	
	KillPath /Z NMOpenAllFilesPath
	
	if ( numFiles == 0 )
		
		DoAlert 0, "Abort File Open All : found no files inside " + NMQuotes( shortName )
		
		return ""
	
	endif
	
	if ( alert )
	
		DoAlert 1, "Located " + num2istr( numFiles ) + " data files inside " + shortName + ". Do you want to open them?"
		
		if ( V_flag != 1 )
			return ""
		endif
	
	endif
	
	for ( fcnt = 0 ; fcnt < numFiles ; fcnt += 1 )
		fileName = StringFromList( fcnt, fileList )
		fileList2 += LastPathColon( extFolderPath, 1 ) + fileName + ";"
	endfor
	
	folderList = NMFileBinOpen( 0, extStr, "root:", "OpenDataPath", fileList2, 1, nmPrefix = nmPrefix, logDisplay = 1, history = 1 )
	
	if ( update )
		NMTab( "Main" ) // force back to Main tab
		UpdateNM( 1 )
	endif
	
	return folderList

End // NMFileOpenAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFileOpenAllSubfolders( extFolderPath [ alert ] )
	String extFolderPath
	Variable alert

	Variable numFolders, fcnt
	String shortName, extFolder, extFolderList, folderList, folderList2 = ""
	String extStr = "?"
	
	Variable nmPrefix = 0 // leave name as is
	
	if ( ParamIsDefault( alert ) )
		alert = 1
	endif
	
	if ( strlen( extFolderPath ) == 0 )
	
		extFolderPath = NMGetExternalFolderPath( "select folder containing data subfolders", "" )
		
		if ( strlen( extFolderPath ) == 0 )
			return ""
		endif
		
	endif
	
	shortName = NMChild( extFolderPath )
	
	NewPath /Q/O NMOpenAllFilesPath, extFolderPath
	
	if ( V_flag != 0 )
		return "" // error in creating path
	endif
	
	extFolderList = IndexedDir( NMOpenAllFilesPath, -1, 1 )
				
	numFolders = ItemsInList( extFolderList )
	
	KillPath /Z NMOpenAllFilesPath
	
	if ( numFolders == 0 )
		
		DoAlert 0, "Abort File Open All : found no subfolders inside " + NMQuotes( shortName )
		
		return ""
	
	endif
	
	if ( alert )
	
		DoAlert 1, "Located " + num2istr( numFolders ) + " subfolders inside " + shortName + ". Do you want to open all data files inside each subfolder?"
		
		if ( V_flag != 1 )
			return ""
		endif
	
	endif
	
	for ( fcnt = 0 ; fcnt < numFolders ; fcnt += 1 )
		extFolder = StringFromList( fcnt, extFolderList )
		 folderList = NMFileOpenAll( extFolder, alert = 0, update = 0 )
		 folderList2 = AddListItem( folderList, folderList2 )
	endfor
	
	NMTab( "Main" ) // force back to Main tab
	UpdateNM( 1 )
	
	return folderList2

End // NMFileOpenAllSubfolders

//****************************************************************
//****************************************************************
//****************************************************************

Function NMDataReloadCall()
	
	String wavePrefix = StrVarOrDefault( "WavePrefix", "" )
	String file = StrVarOrDefault( "CurrentFile", "" )
	
	if ( strlen( wavePrefix ) == 0 )
		wavePrefix = CurrentNMWavePrefix()
	endif
	
	Prompt wavePrefix, "prefix name of data waves to reload:"
	
	DoPrompt "Reload data waves from " + file, wavePrefix
	
	if ( V_flag == 1 )
		return 0 // cancel
	endif

	return NMDataReload( history = 1, wavePrefix = wavePrefix )

End // NMDataReloadCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMDataReload( [ history, wavePrefix ] )
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	String wavePrefix
	
	String vlist = ""
	
	if ( history )
		vlist = NMCmdStrOptional( "wavePrefix", wavePrefix, vlist )
		NMCommandHistory( vlist )
	endif

	String file = StrVarOrDefault( "CurrentFile", "" )
	String temp = CheckNMFolderPath( "reload_temp" )
	String folder, saveDF = GetDataFolder( 1 )
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = StrVarOrDefault( "WavePrefix", "" )
	endif
	
	if ( strlen( wavePrefix ) == 0 )
		return -1
	endif
	
	if ( !FileExistsAndNonZero( file ) )
		return -1
	endif
	
	if ( DataFolderExists( temp ) )
		KillDataFolder /Z $temp
	endif
	
	strswitch( StrVarOrDefault( "DataFileType","" ) )
		case "Pclamp":
		case "Axograph":
			//NMImportFile( temp, file )
			return 0
		case "NMBin":
			folder = NMBinOpen( temp, file, "1111", 1 )
			break
		case "IgorBin":
			folder = IgorBinOpen( temp, file, 1 )
			break
		case "HDF5":
			folder = NMHDF5OpenFile( temp, file, 1 )
			break
		default:
			return -1
	endswitch
	
	if ( strlen( folder ) == 0 )
		SetDataFolder $saveDF // failure, back to original folder
		return -1
	endif
	
	NMChanSelect( "All" )
	
	NMMainDuplicate( toFolder = saveDF, newPrefix = "", overwrite = 1, copySets = 0 )
	
	if ( DataFolderExists( temp ) )
		KillDataFolder /Z $temp
	endif
	
	NMFolderChange( saveDF )
	
	NMSet( wavePrefixNoPrompt = wavePrefix )
	
	return 0

End // NMDataReload

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFoldersMerge()

	Variable fcnt, numfolders, icnt, jcnt, kcnt
	String fname, wlist, noneStr
	String newPrefix, prefixFolder, currentPrefixFolder, prefixList = ""
	String setsListAll, setsList, setName
	String wList1, wList2
	
	Variable countFromZero = -1
	Variable copySets = 1 + NumVarOrDefault( NMMainDF + "DuplicateSets", 1 )
	
	String f1 = CurrentNMFolder( 0 )
	String f2 = ""
	String fList = NMDataFolderList()
	
	String wavePrefix = CurrentNMWavePrefix()
	String newfolder = FolderNameNext( "" )
	
	for ( fcnt = 0; fcnt < ItemsInList( fList ); fcnt += 1 )
		
		if ( StringMatch( f1, StringFromList( fcnt, fList ) ) && ( fcnt + 1 < ItemsInList( fList ) ) )
			f2 = StringFromList( fcnt+1, fList )
			break
		endif
		
	endfor
	
	Prompt newfolder, "new folder name:"
	Prompt wavePrefix, "prefix of waves to copy to new folder:"
	Prompt f1, "first folder:", popup fList
	Prompt f2, "second folder:", popup fList
	Prompt copySets, "copy Sets and Groups?", popup "no;yes;"
	
	DoPrompt "Merge Folders", newfolder, wavePrefix, f1, f2
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( NMFolderListNum( f1 ) > NMFolderListNum( f2 ) )
		countFromZero = 0 // not in order, so use counter
	endif
	
	copySets -= 1
		
	SetNMvar( NMMainDF + "DuplicateSets", copySets )
	
	NMFolderNew( newfolder )
	
	NMFolderChange( f1 )
	
	wlist = WaveList( wavePrefix + "*",";","" )
	
	if ( ItemsInList( wlist ) > 0 )
	
		NMSet( wavePrefixNoPrompt = wavePrefix )
		
		if ( countFromZero >= 0 )
			newPrefix = "DF" + num2str( countFromZero ) + "_"
			countFromZero += 1
		else
			newPrefix = "D" + NMFolderListName( f1 ) + "_"
		endif
	
		NMMainDuplicate( toFolder = "root:" + newfolder, newPrefix = newPrefix, overwrite = 1, copySets = copySets )
		
		prefixList += newPrefix + wavePrefix + ";"
		
	endif
	
	NMFolderChange( f2 )
	
	wlist = WaveList( wavePrefix + "*",";","" )
	
	if ( ItemsInList( wlist ) > 0 )
	
		NMSet( wavePrefixNoPrompt = wavePrefix )
		
		if ( countFromZero >= 0 )
			newPrefix = "DF" + num2str( countFromZero ) + "_"
			countFromZero += 1
		else
			newPrefix = "D" + NMFolderListName( f2 ) + "_"
		endif
	
		NMMainDuplicate( toFolder = "root:" + newfolder, newPrefix = newPrefix, overwrite = 1, copySets = copySets )
		
		prefixList += newPrefix + wavePrefix + ";"
		
	endif
	
	fList = RemoveFromList( f1, fList )
	fList = RemoveFromList( f2, fList )
	fList = RemoveFromList( newfolder, fList )
	
	f2 = ""
	
	numfolders = ItemsInList( fList )
	
	for ( fcnt = 0; fcnt < numfolders; fcnt += 1 )
	
		fname = StringFromList( 0, fList )
		
		if ( strlen( fname ) == 0 )
			break
		endif
		
		wlist = NMFolderWaveList( "root:" + fname, wavePrefix + "*", ";", "", 0 )
		
		if ( ItemsInList( wlist ) == 0 )
			fList = RemoveFromList( fname, fList )
		endif
	
	endfor
	
	numfolders = ItemsInList( fList )
	
	noneStr = "none, stop merge"
	
	for ( fcnt = 0; fcnt < numfolders; fcnt += 1 )
	
		if ( ItemsInList( fList ) <= 0 )
			break
		endif
	
		Prompt f2, "next folder to merge:", popup noneStr + ";" + fList
	
		DoPrompt "Merge Folders", f2
		
		if ( ( V_flag == 1 ) || StringMatch( f2, noneStr ) )
			break // cancel
		endif
		
		NMFolderChange( f2 )
		
		wlist = WaveList( wavePrefix + "*",";","" )
		
		if ( ItemsInList( wlist ) > 0 )
		
			NMSet( wavePrefixNoPrompt = wavePrefix )
			
			if ( countFromZero >= 0 )
				newPrefix = "DF" + num2str( countFromZero ) + "_"
				countFromZero += 1
			else
				newPrefix = "D" + NMFolderListName( f2 ) + "_"
			endif
	
			NMMainDuplicate( toFolder = "root:" + newfolder, newPrefix = newPrefix, overwrite = 1, copySets = copySets )
			
			prefixList += newPrefix + wavePrefix + ";"
		
			fList = RemoveFromList( f2, fList )
			
		endif
	
	endfor
	
	NMFolderChange( newfolder )
	
	newPrefix = "DF"
	
	NMSet( wavePrefixNoPrompt = newPrefix )
	
	if ( copySets && ( ItemsInList( prefixList ) > 0 ) )
	
		currentPrefixFolder = CurrentNMPrefixFolder()
	
		for ( icnt = 0 ; icnt < ItemsInList( prefixList ) ; icnt += 1 )
			
			wavePrefix = StringFromList( icnt, prefixList )
			
			prefixFolder = NMPrefixFolderDF( "", wavePrefix )
			
			if ( !DataFolderExists( prefixFolder ) )
				continue
			endif
			
			setsListAll = NMSetsListAll( prefixFolder = prefixFolder ) // e.g. "Set1;Group0;Group1;Group2;"
		
			for ( jcnt = 0 ; jcnt < ItemsInList( setsListAll ) ; jcnt += 1 )
				
				setName = StringFromList( jcnt, setsListAll )
				setsList = NMFolderStringList( prefixFolder, setName + "_*", ";", 0 ) // list names for all channels
				
				for ( kcnt = 0 ; kcnt < ItemsInList( setsList ) ; kcnt += 1 )
				
					setName = StringFromList( kcnt, setsList )
					wList1 = StrVarOrDefault( prefixFolder + setName, "" )
					
					if ( ItemsInList( wList1 ) == 0 )
						continue
					endif
					
					wList2 = StrVarOrDefault( currentPrefixFolder + setName, "" )
					
					wList2 = NMAddToList( wList1, wList2, ";" )
					
					SetNMstr( currentPrefixFolder + setName, wList2 )
					
				
				endfor  
			
			endfor
			
		endfor
		
		NMSet( wavePrefixNoPrompt = newPrefix ) // update Sets/Groups
		
	endif
	
	return newfolder
	
End // NMFoldersMerge

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderSaveCall()
	
	Variable fileTypeSelect = NumVarOrDefault( NMDF + "SaveFolderFileType", 1 )
	String waveFileType = StrVarOrDefault( NMDF + "SaveFolderWaveFileType", "Igor Binary" )
	Variable saveWaveNotes = 1 + NumVarOrDefault( NMDF + "SaveFolderWaveNotes", 1 )
	Variable saveSubfolders = 1 + NumVarOrDefault( NMDF + "SaveFolderSubfolders", 1 )
	
	if ( fileTypeSelect != 2 )
		fileTypeSelect = 1
	endif
	
	Prompt fileTypeSelect, "save folder as:", popup "Igor binary file (pxp);unpacked folder;HDF5;"
	
	DoPrompt "Save " + GetDataFolder( 0 ), fileTypeSelect
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( ( fileTypeSelect == 3 ) && !NMHDF5OK() )
		NMHDF5Allert()
		return "" // cancel
	endif
	
	SetNMvar( NMDF + "SaveFolderFileType", fileTypeSelect )
	
	if ( fileTypeSelect == 1 )
		return NMFolderSaveToDisk( fileType = "Igor Binary" )
	elseif ( fileTypeSelect == 3 )
		return NMFolderSaveToDisk( fileType = "HDF5" )
	endif
	
	Prompt waveFileType, "save waves as:", popup "Igor Binary;Igor Text;General Text;Delimited Text;"
	Prompt saveWaveNotes, "save waves notes?", popup "no;yes;"
	Prompt saveSubfolders, "save subfolders?", popup "no;yes;"
	DoPrompt "Save " + GetDataFolder( 0 ) + " as Unpacked Folder On Disk", waveFileType, saveWaveNotes, saveSubfolders
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	saveWaveNotes -= 1
	saveSubfolders -= 1
	
	SetNMvar( NMDF + "SaveFolderFileType", fileTypeSelect )
	SetNMstr( NMDF + "SaveFolderWaveFileType", waveFileType )
	SetNMvar( NMDF + "SaveFolderWaveNotes", saveWaveNotes )
	SetNMvar( NMDF + "SaveFolderSubfolders", saveSubfolders )
	
	return NMFolderSaveToDisk( fileType = "Unpacked", waveFileType = waveFileType, saveWaveNotes = saveWaveNotes, saveSubfolders = saveSubfolders )

End // NMFolderSaveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderSaveAllCall()

	String fileType, fList = NMDataFolderList()
	
	Variable numFolders = ItemsInList( fList )
	
	if ( numFolders == 0 )
		return ""
	endif
	
	if ( numFolders == 1 )
		return NMFolderSaveCall()
	endif
	
	Variable fileTypeSelect = NumVarOrDefault( NMDF + "SaveFolderFileType", 1 )
	String waveFileType = StrVarOrDefault( NMDF + "SaveFolderWaveFileType", "Igor Binary" )
	Variable saveWaveNotes = 1 + NumVarOrDefault( NMDF + "SaveFolderWaveNotes", 1 )
	Variable saveSubfolders = 1 + NumVarOrDefault( NMDF + "SaveFolderSubfolders", 1 )
	
	if ( fileTypeSelect != 2 )
		fileTypeSelect = 1
	endif

	Prompt fileTypeSelect, "save folders as:", popup "Igor binary files (pxp);unpacked folders;"
	DoPrompt "Save All Folders ( n = " + num2str( numFolders ) + " )", fileTypeSelect
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMvar( NMDF + "SaveFolderFileType", fileTypeSelect )
	
	if ( fileTypeSelect == 1 )
		return NMFolderSaveAll( history = 1 )
	endif
	
	Prompt waveFileType, "save waves as:", popup "Igor Binary;Igor Text;General Text;Delimited Text;"
	Prompt saveWaveNotes, "save waves notes?", popup "no;yes;"
	Prompt saveSubfolders, "save subfolders?", popup "no;yes;"
	DoPrompt "Save All Folders as Unpacked Folders On Disk ( n = " + num2str( numFolders ) + " )", waveFileType, saveWaveNotes, saveSubfolders
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	saveWaveNotes -= 1
	saveSubfolders -= 1
	
	SetNMstr( NMDF + "SaveFolderWaveFileType", waveFileType )
	SetNMvar( NMDF + "SaveFolderWaveNotes", saveWaveNotes )
	SetNMvar( NMDF + "SaveFolderSubfolders", saveSubfolders )
	
	if ( fileTypeSelect == 1 )
		fileType = "Igor Binary"
	else
		fileType = "Unpacked"
	endif
	
	return NMFolderSaveAll( fileType = fileType, waveFileType = waveFileType, saveWaveNotes = saveWaveNotes, saveSubfolders = saveSubfolders, history = 1 )

End // NMFolderSaveAllCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderSaveAll( [ fileType, waveFileType, saveWaveNotes, saveSubfolders, dialogue, path, history ] )
	String fileType // "NM" for NM binary, "Igor Binary" for Igor binary PXP or "unpacked" for unpacked folder along with waveFileType
	String waveFileType // "Igor Binary" or "Igor Text"  or "General Text" or "Delimited Text"  [ used only if fileType = "unpacked" ]
	Variable saveWaveNotes // ( 0 ) no ( 1 ) yes [ used only if fileType = 2 ]
	Variable saveSubfolders // ( 0 ) no ( 1 ) yes [ used only if fileType = 2 ]
	Variable dialogue // ( 0 ) no ( 1 ) yes
	String path // e.g. "SaveDataPath" // symbolic path name
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable icnt, numFolders, fType
	String folder, file, slist = "", vlist = "", fList = NMDataFolderList()
	
	if ( ParamIsDefault( fileType ) )
		fileType = "Igor Binary"
	else
		vlist = NMCmdStrOptional( "fileType", fileType, vlist )
	endif
	
	fType = NMFileTypeNum( fileType )
	
	if ( numtype( fType ) > 0 )
		return NM2ErrorStr( 20, "fileType", fileType )
	endif
	
	if ( ParamIsDefault( waveFileType ) )
		waveFileType = "Igor Binary"
	else
		vlist = NMCmdStrOptional( "waveFileType", waveFileType, vlist )
	endif
	
	if ( ParamIsDefault( saveWaveNotes ) )
		saveWaveNotes = 1
	else
		vlist = NMCmdNumOptional( "saveWaveNotes", saveWaveNotes, vlist )
	endif
	
	if ( ParamIsDefault( saveSubfolders ) )
		saveSubfolders = 1
	else
		vlist = NMCmdNumOptional( "saveSubfolders", saveSubfolders, vlist )
	endif
	
	if ( ParamIsDefault( dialogue ) )
		dialogue = 1
	else
		vlist = NMCmdNumOptional( "dialogue", dialogue, vlist )
	endif
	
	if ( ParamIsDefault( path ) )
	
		path = "SaveDataPath"
		
	else
	
		vlist = NMCmdStrOptional( "path", path, vlist )
	
		PathInfo $path
		
		if ( V_flag == 0 ) // bad path
			dialogue = 1
			path = ""
		endif
		
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	numFolders = ItemsInList( fList )
	
	for ( icnt = 0; icnt < numFolders; icnt += 1 )
	
		folder = CheckNMFolderPath( StringFromList( icnt, fList ) )
		
		if ( !DataFolderExists( folder ) )
			continue
		endif
		
		if ( fType == 2 )
			file = NMFolderSaveToDisk( folder = folder, fileType = fileType, waveFileType = waveFileType, saveWaveNotes = saveWaveNotes, saveSubfolders = saveSubfolders, dialogue = dialogue, path = path )
		else
			file = NMFolderSaveToDisk( folder = folder, fileType = fileType, dialogue = dialogue, path = path )
		endif
		
		if ( strlen( file ) == 0 )
			break // cancel
		endif
		
		if ( dialogue ) // end prompt - save in disk folder just selected
		
			NewPath /O/Q/Z NMSaveAllPath, NMParent( file )
			
			PathInfo NMSaveAllPath
			
			if ( V_flag == 1 ) // path OK
				dialogue = 0
				path = "NMSaveAllPath"
			endif
		
		endif
		
		slist = AddListItem( file, slist, ";", inf )
		
	endfor
	
	KillPath /Z NMSaveAllPath
	
	return slist
	
End // NMFolderSaveAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderList( df, type )
	String df // data folder to look in ( "" ) for current
	String type // "NMData", "NMStim", "NMLog", ( "" ) any
	
	Variable index
	String objName, folderlist = ""
	
	if ( strlen( df ) == 0 )
		df = StrVarOrDefault( NMDF + "CurrentFolder", "" )
	endif
	
	do
	
		objName = GetIndexedObjName( df, 4, index )
		
		if ( strlen( objName ) == 0 )
			break
		endif
		
		CheckNMFolderType( objName )
		
		if ( IsNMFolder( df+objName, type ) )
			folderlist = AddListItem( objName, folderlist, ";", inf )
		endif
		
		index += 1
		
	while( 1 )
	
	return folderlist

End // NMFolderList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDataFolderList()

	String wname = NMFolderListWave()
	String fList = ""
	
	if ( WaveExists( $wname ) )
		fList = Wave2List( NMFolderListWave() )
	endif

	if ( ItemsInlist( fList ) == 0 )
		return NMFolderList( "root:","NMData" )
	endif
	
	return fList
	
End // NMDataFolderList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMDataFolderListLong() // includes Folder list name ( e.g. "F0" )
	Variable icnt
	
	String fname, fList2 = "", fList = NMDataFolderList()
	
	for ( icnt = 0; icnt < ItemsInList( fList ); icnt += 1 )
		fname = StringFromList( icnt, fList )
		fname = NMFolderListName( fname ) + " : " + fname
		fList2 = AddListItem( fname, fList2, ";", inf )
	endfor

	return fList2
	
End // NMDataFolderListLong

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMLogFolderListLong()
	Variable icnt
	
	String fname, fList2 = "", fList = NMFolderList( "root:","NMLog" )
	
	for ( icnt = 0; icnt < ItemsInList( fList ); icnt += 1 )
		fname = StringFromList( icnt, fList )
		fname = "L" + num2istr( icnt ) + " : " + fname
		fList2 = AddListItem( fname, fList2, ";", inf )
	endfor

	return fList2
	
End // NMLogFolderListLong

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderListWave()

	return NMDF + "FolderList"

End // NMFolderListWave

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMFolderList()

	Variable icnt, folders
	String folder
	
	String wname = NMFolderListWave()
	String folderList = NMFolderList( "root:","NMData" )
	
	folders = ItemsInList( folderList )

	CheckNMtwave( wname, -1, "" )
	
	if ( !WaveExists( $wname ) )
		return 0
	endif
	
	Wave /T list = $wname
	
	for ( icnt = 0; icnt < numpnts( list ); icnt += 1 )
	
		folder = list[ icnt ]
		
		if ( !IsNMDataFolder( folder ) )
			NMFolderListRemove( folder )
		endif
		
	endfor
	
	for ( icnt = 0; icnt < folders; icnt += 1 )
		NMFolderListAdd( StringFromList( icnt, folderList ) )
	endfor
	
End // CheckNMFolderList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderListEdit()

	String tName = "NM_FolderList"
	
	String wname = NMFolderListWave()
	
	if ( !WaveExists( $wname ) )
		return -1
	endif
	
	if ( WinType( tName ) > 0 )
		DoWindow /F $tName
	else
		Edit /K=1/N=$tName $wname as "NM Data Folder List"
	endif

end // NMFolderListEdit

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderListNextNum()

	Variable icnt, found, npnts
	
	String wname = NMFolderListWave()
	
	if ( !WaveExists( $wname ) )
		return 0
	endif
	
	Wave /T list = $wname
	
	npnts = numpnts( list )
	
	for ( icnt = npnts-1; icnt >= 0; icnt -=1 )
		if ( strlen( list[ icnt ] ) > 0 )
			found = 1
			break
		endif
	endfor
	
	if ( found )
	
		icnt += 1
		
		return icnt
	
	else
	
		return 0
		
	endif

End // NMFolderListNextNum

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderListAdd( folder )
	String folder
	
	Variable icnt, found, npnts
	
	String wname = NMFolderListWave()
	
	if ( !WaveExists( $wname ) )
		return -1
	endif
	
	Wave /T list = $wname
	
	folder = NMChild( folder )
	
	npnts = numpnts( list )
	
	for ( icnt = 0; icnt < npnts; icnt += 1 )
		if ( StringMatch( folder, list[ icnt ] ) )
			return 0 // already exists
		endif
	endfor
	
	for ( icnt = npnts-1; icnt >= 0; icnt -=1 )
		if ( strlen( list[ icnt ] ) > 0 )
			found = 1
			break
		endif
	endfor

	if ( found )
		icnt = icnt + 1
	else
		icnt = 0
	endif
	
	if ( icnt < npnts )
		list[ icnt ] = folder
	else
		Redimension /N=( icnt+1 ) list
		list[ icnt ] = folder
	endif
	
	return icnt
	
End // NMFolderListAdd

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderListRemove( folder )
	String folder
	
	Variable icnt, found, npnts
	
	String wname = NMFolderListWave()
	
	if ( !WaveExists( $wname ) )
		return -1
	endif
	
	Wave /T list = $wname
	
	folder = NMChild( folder )
	
	npnts = numpnts( list )
	
	for ( icnt = 0; icnt < npnts; icnt += 1 )
		if ( StringMatch( folder, list[ icnt ] ) )
			list[ icnt ] = ""
			return 1
		endif
	endfor
	
	return 0
	
End // NMFolderListRemove

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderListChange( oldName, newName )
	String oldName, newName
	
	Variable icnt, found, npnts
	
	String wname = NMFolderListWave()
	
	if ( !WaveExists( $wname ) )
		return -1
	endif
	
	Wave /T list = $wname
	
	oldName = NMChild( oldName )
	
	npnts = numpnts( list )
	
	for ( icnt = 0; icnt < npnts; icnt += 1 )
		if ( StringMatch( oldName, list[ icnt ] ) )
			list[ icnt ] = NMChild( newName )
			return 1
		endif
	endfor
	
	return 0
	
End // NMFolderListChange

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFolderListNum( folder )
	String folder
	
	Variable icnt, found, npnts
	
	String wname = NMFolderListWave()
	
	if ( !WaveExists( $wname ) )
		return Nan
	endif
	
	if ( strlen( folder ) == 0 )
		folder = CurrentNMFolder( 0 )
	endif
	
	Wave /T list = $wname
	
	if ( StringMatch( folder[ 0, 4 ], "root:" ) )
		folder = ParseFilePath( 0, folder, ":", 0, 1 )
	else
		folder = NMChild( folder )
	endif
	
	npnts = numpnts( list )
	
	for ( icnt = 0; icnt < npnts; icnt += 1 )
		if ( StringMatch( folder, list[ icnt ] ) )
			return icnt
		endif
	endfor
	
	return Nan
	
End // NMFolderListNum

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderListName( folder )
	String folder // folder name ( "" ) for current
	
	String prefix = "F"
	
	if ( strlen( folder ) == 0 )
		folder = CurrentNMFolder( 0 )
	endif
	
	Variable id = NMFolderListNum( folder )
	
	if ( numtype( id ) == 0 )
		return prefix + num2istr( id )
	else
		return ""
	endif

End // NMFolderListName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMFolderPrefix()
	
	return NMFolderListName( "" ) + "_"

End // CurrentNMFolderPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderPrefix( folder )
	String folder // folder name, ( "" ) for current
	
	return NMFolderListName( folder ) + "_"

End // NMFolderPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function IsNMFolder( folder, type ) // returns 0 or 1
	String folder // full-path folder name
	String type // "NMData", "NMStim", "NMLog", ( "" ) any
	
	String ftype
	
	if ( strlen( folder ) == 0 )
		folder = GetDataFolder( 1 )
	endif
	
	//print folder, CheckNMFolderPath( folder )
	
	folder = CheckNMFolderPath( folder )
	
	if ( ( strlen( folder ) > 0 ) && DataFolderExists( folder ) )
	
		ftype = StrVarOrDefault( folder+"FileType", "No" )
	
		if ( StringMatch( type, ftype ) )
			return 1
		elseif ( ( strlen( type ) == 0 ) && !StringMatch( ftype, "No" ) )
			return 1
		endif
	
	endif
	
	return 0

End // IsNMFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function IsNMDataFolder( folder )
	String folder // full-path folder name
	
	return IsNMFolder( folder,"NMData" )
	
End // IsNMDataFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SubStimName( df [ fullPath ] ) // sub folder stim name
	String df // data folder or ( "" ) for current
	Variable fullPath
	
	String stimName = StringFromList( 0, NMFolderList( df, "NMStim" ) )
	
	if ( strlen( stimName ) == 0 )
		return ""
	endif
	
	if ( fullPath )
	
		if ( strlen( df ) == 0 )
			return GetDataFolder( 1 ) + stimName + ":"
		else
			return df + stimName + ":"
		endif
		
	else
	
		return stimName
		
	endif

End // SubStimName

//****************************************************************
//****************************************************************
//****************************************************************

Function PrintNMFolderDetails( folder )
	String folder
	
	Variable tempval
	String tempstr
	
	folder = CheckNMFolderPath( folder )

	if ( !DataFolderExists( folder ) )
		return -1
	endif
	
	NMHistory( "Data File: " + StrVarOrDefault( folder+"CurrentFile", "Unknown Data File" ) )
	NMHistory( "File Type: " + StrVarOrDefault( folder+"DataFileType", "Unknown" ) )
	
	tempstr = StrVarOrDefault( folder+"AcqMode", "" )
	
	if ( strlen( tempstr ) > 0 )
		NMHistory( "Acquisition Mode: " + tempstr )
	endif
	
	tempstr = StrVarOrDefault( folder+"WavePrefix", "" )
	
	if ( strlen( tempstr ) > 0 )
		NMHistory( "Data Prefix Name: " + tempstr )
	endif
	
	tempval = NumVarOrDefault( folder+"NumChannels", Nan )
	
	if ( numtype( tempval ) == 0 )
		NMHistory( "Channels: " + num2istr( tempval ) )
	endif

	tempval = NumVarOrDefault( folder+"NumWaves", Nan )
	
	if ( numtype( tempval ) == 0 )
		NMHistory( "Waves per Channel: " + num2istr( tempval ) )
	endif
	
	tempval = NumVarOrDefault( folder+"SamplesPerWave", Nan )
	
	if ( numtype( tempval ) == 0 )
		NMHistory( "Samples per Wave: " + num2istr( tempval ) )
	endif
	
	tempval = NumVarOrDefault( folder+"SampleInterval", Nan )
	
	if ( numtype( tempval ) == 0 )
		NMHistory( "Sample Interval ( ms ): " + num2str( tempval ) )
	endif
	
	NMHistory( " " )

End // PrintNMFolderDetails

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Folder utility functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderNameCreate( fileName [ nmPrefix, replaceStringList ] )  // create a folder name based on a given file name
	String fileName
	Variable nmPrefix // ( 0 ) no ( 1 ) yes, force "nm" prefix
	String replaceStringList // see NMStringReplaceList
	
	Variable num0, num1
	String folderName = fileName
	
	if ( ParamIsDefault( replaceStringList ) )
		replaceStringList = ""
	endif
	
	folderName = NMChild( folderName ) // remove file path if it exists
	folderName = FileExtCheck( folderName, ".*", 0 ) // remove extension if it exists
	
	if ( strlen( replaceStringList ) > 0 )
		folderName = NMReplaceStringList( folderName, replaceStringList )
	endif
	
	num0 = str2num( folderName[ 0, 0 ] )
	num1 = str2num( folderName[ 1, 1 ] )
	
	if ( numtype( num0 ) == 0 )
		folderName = "nm" + folderName
	elseif ( nmPrefix && StringMatch( folderName[ 0, 0 ], "f" ) && ( numtype( num1 ) == 0 ) )
		folderName = "nm" + folderName[ 1, inf ]
	endif
	
	if ( nmPrefix && !StringMatch( folderName[ 0, 1 ], "nm" ) )
		folderName = "nm" + folderName
	endif
	
	folderName = NMCheckStringName( folderName )
	
	return folderName

End // NMFolderNameCreate

//****************************************************************
//****************************************************************
//****************************************************************

Function /S FolderNameNext( folderName ) // return next unused folder name
	String folderName
	
	Variable iSeqBgn, iSeqEnd
	Variable fcnt, seqnum
	String testname, rname = ""
	
	if ( strlen( folderName ) == 0 )
		folderName = "nmFolder" + num2istr( NMFolderListNextNum() )
	else
		folderName = NMChild( folderName )
	endif
	
	folderName = NMCheckStringName( folderName )
	
	seqnum = SeqNumFind( folderName )
	
	iSeqBgn = NumVarOrDefault( "iSeqBgn", 0 )
	iSeqEnd = NumVarOrDefault( "iSeqEnd", 0 )

	for ( fcnt = 0; fcnt <= 99; fcnt += 1 )
	
		if ( numtype( seqnum ) == 0 )
			testname = SeqNumSet( folderName, iSeqBgn, iSeqEnd, ( seqnum+fcnt ) )
		else
			testname = folderName + num2istr( fcnt )
		endif
		
		testname = testname[ 0,30 ]
		
		if ( ( strlen( testname ) > 0 ) && !DataFolderExists( "root:" + testname ) )
			rname = testname
			break
		endif
		
	endfor

	KillVariables /Z iSeqBgn, iSeqEnd
	
	return rname
	
End // FolderNameNext

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CheckFolderName( folderName ) // if folder exists, request new folder name
	String folderName
	
	if ( strlen( folderName ) == 0 )
		return ""
	endif
	
	Variable icnt
	
	String parent = NMParent( folderName )
	String fname = NMChild( folderName )
	
	String lastname, savename = fname
	
	fname = NMCheckStringName( fname )
	
	if ( numtype( str2num( fname[ 0, 0 ] ) ) == 0 )
		fname = "nm" + fname
	endif
	
	do // test whether data folder already exists
	
		if ( DataFolderExists( parent+fname ) )
			
			lastname = fname
			fname = savename + "_" + num2istr( icnt )
			
			Prompt fname, "Folder " + NMQuotes( lastname ) + " already exists. Please enter a different folder name:"
			DoPrompt "Folder Name Conflict", fname
			
			if ( V_flag == 1 )
				return "" // cancel
			endif

		else
		
			break // name OK
			
		endif
		
	while ( 1 )
	
	return parent+fname

End // CheckFolderName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S FolderObjectList( df, objType )
	String df // data folder path ( "" ) for current
	Variable objType // ( 1 ) waves ( 2 ) variables ( 3 ) strings ( 4 ) data folders ( 5 ) numeric wave ( 6 ) text wave
	
	Variable ocnt, otype, add
	String objName, olist = ""
	
	switch( objType )
		case 1:
		case 2:
		case 3:
		case 4:
			otype = objType
			break
		case 5:
		case 6:
			otype = 1
			break
		default:
			return ""
	endswitch
	
	do
	
		add = 0
		objName = GetIndexedObjName( df, oType, ocnt )
		
		if ( strlen( objName ) == 0 )
			break
		endif
		
		switch( objType )
			case 1:
			case 2:
			case 3:
			case 4:
				add = 1
				break
			case 5:
				if ( WaveType( $( df+objName ) ) > 0 )
					add = 1
				endif
				break
			case 6:
				if ( WaveType( $( df+objName ) ) == 0 )
					add = 1
				endif
				break
		endswitch
		
		if ( add )
			olist = AddListItem( objName, olist, ";", inf )
		endif
		
		ocnt += 1
		
	while( 1 )
	
	return olist

End // FolderObjectList

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Prefix Menu Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefixSubfolderList( withNMPrefix [ folder ] )
	Variable withNMPrefix // ( 0 ) without "NMPrefix_" ( 1 ) with "NMPrefix_"
	String folder
	
	if ( ParamIsDefault( folder ) || ( strlen( folder ) == 0 ) )
		folder = StrVarOrDefault( NMDF + "CurrentFolder", "" )
	else
		folder = CheckNMFolderPath( folder )
	endif
	
	String subfolderList = NMSubfolderList( NMPrefixSubfolderPrefix, folder, 0 )
	
	if ( withNMPrefix )
		return subfolderList
	else
		return ReplaceString( NMPrefixSubfolderPrefix, subfolderList, "" )
	endif
	
End // NMPrefixSubfolderList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixSubfolderKillCall()

	String txt, vlist = ""
	String subfolderList = NMPrefixSubfolderList( 0 )
	String prefix = CurrentNMWavePrefix()
	
	if ( ItemsInList( subfolderList ) == 0 )
		
		NMDoAlert( "There are no prefix subfolders to kill." )
		return -1
		
	elseif ( ItemsInList( subfolderList ) > 1 )
		subfolderList += "All;"
	endif
	
	Prompt prefix, "select prefix to kill:", popup subfolderList
	DoPrompt "Kill Wave Prefix Subfolder Globals", prefix
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	if ( StringMatch( prefix, "All" ) )
		prefix = subfolderList
		txt = "Are you sure you want to kill all prefix subfolders?"
		txt += " This will kill all Sets and Groups and variables associated with these prefixes."
	else
		txt = "Are you sure you want to kill the subfolder for prefix " + NMQuotes( prefix ) + "?"
		txt += " This will kill all Sets, Groups and variables associated with this prefix."
	endif
	
	DoAlert 1, txt
	
	if ( V_flag != 1 )
		return -1
	endif
	
	return NMPrefixSubfolderKill( prefix, history = 1 )

End // NMPrefixSubfolderKillCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixSubfolderKill( killList [ history ] )
	String killList
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable icnt
	String prefix, subfolder, vlist = ""
	
	if ( history )
		vlist = NMCmdStr( killList, vlist )
		NMCommandHistory( vlist )
	endif
	
	String prefixList = NMStrGet( "PrefixList" )
	String currentPrefix = CurrentNMWavePrefix()
	String folderPrefix = NMPrefixSubfolderPrefix
	
	if ( ItemsInList( killList ) == 0 )
		return -1
	endif
	
	for ( icnt = 0 ; icnt < ItemsInList( killList ) ; icnt += 1 )
	
		prefix = StringFromList( icnt, killList )
		
		if ( StringMatch( prefix, currentPrefix ) )
			SetNMstr( "CurrentPrefix", "" )
		endif
		
		//prefixList = RemoveFromList( prefix, prefixList )
		
		subfolder = folderPrefix + prefix
		
		NMPrefixFolderLock( subfolder, 0 ) // remove lock if it exists
		NMSubfolderKill( subfolder )
	
	endfor
	
	SetNMstr( NMDF+"PrefixList", prefixList )
	
	UpdateNM( 1 )
	
	return 0
	
End // NMPrefixSubfolderKill

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefixList()

	Variable icnt
	String wavePrefix, wList, findAny, prefixList2 = ""

	String prefixList = NMStrGet( "PrefixList" )
	String subfolderList = NMPrefixSubfolderList( 0 )
	
	for ( icnt = 0 ; icnt < ItemsInList( NMWavePrefixList ) ; icnt += 1 )
	
		wavePrefix = StringFromList( icnt, NMWavePrefixList )
		wList = WaveList( wavePrefix + "*", ";", "Text:0" )
		
		if ( ItemsInList( wList ) > 0 )
			prefixList2 = NMAddToList( wavePrefix, prefixList2, ";" )
		endif
		
	endfor
	
	for ( icnt = 0 ; icnt < ItemsInList( prefixList ) ; icnt += 1 )
	
		wavePrefix = StringFromList( icnt, prefixList )
		wList = WaveList( wavePrefix + "*", ";", "Text:0" )
		
		if ( ItemsInList( wList ) > 0 )
			prefixList2 = NMAddToList( wavePrefix, prefixList2, ";" )
		endif
		
	endfor
	
	wList = WaveList( "DF0_*", ";", "Text:0" ) // imported data
	
	if ( ItemsInList( wList ) > 0 )
		prefixList2 = NMAddToList( "DF", prefixList2, ";" )
	endif
	
	prefixList2 = NMAddToList( subfolderList, prefixList2, ";" )
	
	if ( ItemsInList( prefixList2 ) == 0 )
	
		findAny = NMPrefixFindFirst()
		
		if ( strlen( findAny ) > 0 )
			prefixList2 = NMAddToList( findAny, prefixList2, ";" )
		endif
		
	endif
	
	if ( ItemsInList( prefixList2 ) == 0 )
		return ""
	endif
	
	return SortList( prefixList2, ";", 16 )

End // NMPrefixList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefixFindFirst()

	Variable icnt, jcnt, numChar, varNum, numWaves, foundCommon
	String wName, wList, wavePrefix
	
	Variable numWavesLimit = 10
	Variable numCharLimit = 5

	wList = WaveList( "*", ";", "Text:0" )
	
	numWaves = ItemsInList( wList )
		
	if ( numWaves == 0 )
		return ""
	endif
	
	numWaves = min( numWaves, numWavesLimit )
	
	for ( icnt = 0 ; icnt < numWaves ; icnt += 1 )
	
		wName = StringFromList( icnt, wList )
	
		numChar = strlen( wName )
		
		for ( jcnt = numChar - 1 ; jcnt >= 1 ; jcnt -= 1 )
		
			wavePrefix = wName[ 0, jcnt ]
			
			wList = WaveList( wavePrefix + "*", ";", "Text:0" )
			
			if ( ItemsInList( wList ) > 1 )
				foundCommon = 1
				break
			endif
			
		endfor
		
	endfor
	
	if ( foundCommon )
	
		icnt = strsearch( wavePrefix, "_", 0 )
		
		if ( icnt > 0 )
			return wavePrefix[ 0, icnt ] // if there is underscore, use string to left as prefix
		else
			return wavePrefix[ 0, numCharLimit - 1 ]
		endif
		
	endif
	
	// found no common prefix, so use prefix of first wave
	
	wavePrefix = StringFromList( 0, wList )
	
	icnt = strsearch( wavePrefix, "_", 0 )
		
	if ( icnt > 0 )
		return wavePrefix[ 0, icnt ]
	else
		return wavePrefix[ 0, numCharLimit - 1 ]
	endif

End // NMPrefixFindFirst

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixOtherCall()

	String newPrefix
	
	Prompt newPrefix, "enter new wave prefix:"
	DoPrompt "Other Wave Prefix", newPrefix
	
	if ( ( V_flag == 1 ) || ( strlen( newPrefix ) == 0 ) )
		return -1 // cancel
	endif
	
	return NMSet( wavePrefix = newPrefix, history = 1 )

End // NMPrefixOtherCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixListSetCall()

	Variable error
	
	String prefixList = NMStrGet( "PrefixList" )
	
	String addPrefix = ""
	String RemovePrefix = " "
	String editList = prefixList
	
	Prompt addPrefix, "enter new prefix:"
	Prompt removePrefix, "or select prefix to remove:", popup " ;" + prefixList
	Prompt editList, "or edit list directly:"
	DoPrompt "Edit Default Wave Prefix List", addPrefix, removePrefix, editList
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	if ( !StringMatch( editList, prefixList ) )
		error = NMPrefixListSet( editList, history = 1 )
	endif
	
	if ( strlen( addPrefix ) > 0 )
		error += NMPrefixAdd( addPrefix, history = 1 )
	endif
	
	if ( !StringMatch( removePrefix, " " ) )
		error += NMPrefixRemove( removePrefix, history = 1 )
	endif
	
	return error

End // NMPrefixListSetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixListSet( prefixList [ history ] )
	String prefixList
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable icnt
	String pList = "", vlist = ""
	
	if ( history )
		vlist = NMCmdStr( prefixList, vlist )
		NMCommandHistory( vlist )
	endif
	
	if ( strsearch( prefixList, ",", 0 ) >= 0 )
		prefixList = ReplaceString( ",", prefixList, ";" )
	endif
	
	for ( icnt = 0 ; icnt < ItemsInList( prefixList ) ; icnt += 1 )
		pList += StringFromList( icnt, prefixList ) + ";"
	endfor
	
	SetNMstr( NMDF+"PrefixList", pList )
	UpdateNMPanelPrefixMenu()
	
	return 0

End // NMPrefixListSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixListClear( [ history ] )
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	if ( history )
		NMCommandHistory( "" )
	endif

	SetNMstr( NMDF+"PrefixList", "Record;Avg;Wave;" )
	UpdateNMPanelPrefixMenu()
	
	return 0

End // NMPrefixListClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixAddCall()

	String newPrefix
	
	Prompt newPrefix, "enter prefix string:"
	DoPrompt "Add Wave Prefix", newPrefix
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	return NMPrefixAdd( newPrefix, history = 1 )

End // NMPrefixAddCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixAdd( addList [ history ] )
	String addList // prefix list to add
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	String prefixList = NMStrGet( "PrefixList" )
	String vlist = ""
	
	if ( history )
		vlist = NMCmdStr( addList, vlist )
		NMCommandHistory( vlist )
	endif
	
	if ( ItemsInList( addList ) == 0 )
		return -1
	endif
	
	prefixList = NMAddToList( addList, prefixList, ";" )
	
	SetNMstr( NMDF+"PrefixList", prefixList )
	
	UpdateNMPanelPrefixMenu()
	
	return 0

End // NMPrefixAdd

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixRemoveCall()

	String prefixList = NMStrGet( "PrefixList" )
	String CurrentPrefix = CurrentNMWavePrefix()

	String getprefix
	
	Prompt getprefix, "remove:", popup RemoveFromList( CurrentPrefix, prefixList )
	DoPrompt "Remove Wave Prefix", getprefix
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	return NMPrefixRemove( getprefix, history = 1 )

End // NMPrefixRemoveCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixRemove( removeList [ history ] )
	String removeList
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	String prefixList = NMStrGet( "PrefixList" )
	String vlist = ""
	
	if ( history )
		vlist = NMCmdStr( removeList, vlist )
		NMCommandHistory( vlist )
	endif
	
	if ( ItemsInList( removeList ) == 0 )
		return -1
	endif
	
	prefixList = RemoveFromList( removeList, prefixList, ";" )
	
	SetNMstr( NMDF+"PrefixList", prefixList )
	UpdateNMPanelPrefixMenu()
	
	return 0

End // NMPrefixRemove

//****************************************************************
//****************************************************************
//****************************************************************

Function NMOrderWavesPrefCall()
	
	String order = NMStrGet( "OrderWavesBy" )
	
	Prompt order, "Order selected waves by:", popup "name;date;"
	DoPrompt "Order Waves Preference", order
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	return NMSet( OrderWavesBy = order, history = 1 )

End // NMOrderWavesPreferenceCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixFoldersRenameWave( oldName, newName [ folder, ignorePrefixMatch ] ) // rename a wave in all the prefix folder wave lists
	String oldName // old wave name
	String newName // new wave name ( "" ) empty string to remove name
	String folder // NM folder
	Variable ignorePrefixMatch
	
	Variable pcnt, ccnt, numChannels, scnt, newNamePrefixMatch
	String prefixName, prefixFolder
	String matchStr, strVarList, strVarName, prefixList
	
	if ( ParamIsDefault( folder ) )
		folder = StrVarOrDefault( NMDF + "CurrentFolder", "" )
	endif
	
	prefixList = NMPrefixSubfolderList( 0, folder = folder )
	
	oldName = NMChild( oldName )
	newName = NMChild( newName )
	
	for ( pcnt = 0 ; pcnt < ItemsInList( prefixList ) ; pcnt += 1 )
		
		prefixName = StringFromList( pcnt, prefixList )
		
		if ( ( strlen( newName ) > 0 ) && ( strsearch( newName, prefixName, 0, 2 ) == 0 ) )
			newNamePrefixMatch = 1
		else
			newNamePrefixMatch = 0
		endif
		
		//if ( ( strlen( newName ) > 0 ) && ( newNamePrefixMatch == 0 ) )
		//	continue // newName does not match this prefix
		//endif
		
		prefixFolder = NMPrefixFolderDF( folder, prefixName )
		
		strVarName = prefixFolder + "PrefixSelect_WaveList"
		NMPrefixFoldersRenameWave2( strVarName, oldName, newName, newNamePrefixMatch, ignorePrefixMatch = ignorePrefixMatch )
		
		matchStr = "Chan_WaveList*"
		strVarList = NMFolderStringList( prefixFolder, matchStr, ";", 0 ) // list of all channel wave lists
		
		for ( scnt = 0 ; scnt < ItemsInList( strVarList ) ; scnt += 1 )
			strVarName = prefixFolder + StringFromList( scnt, strVarList )
			NMPrefixFoldersRenameWave2( strVarName, oldName, newName, newNamePrefixMatch, ignorePrefixMatch = ignorePrefixMatch )
		endfor
		
		matchStr = "*" + NMSetsListSuffix + "*"
		strVarList = NMFolderStringList( prefixFolder, matchStr, ";", 0 ) // list of all Sets

		for ( scnt = 0 ; scnt < ItemsInList( strVarList ) ; scnt += 1 )
			strVarName = prefixFolder + StringFromList( scnt, strVarList )
			NMPrefixFoldersRenameWave2( strVarName, oldName, newName, newNamePrefixMatch, ignorePrefixMatch = ignorePrefixMatch )
		endfor
		
	endfor
	
End // NMPrefixFoldersRenameWave

//****************************************************************
//****************************************************************
//****************************************************************

Static Function NMPrefixFoldersRenameWave2( strVarName, oldName, newName, newNamePrefixMatch [ ignorePrefixMatch ] )
	String strVarName
	String oldName, newName
	Variable newNamePrefixMatch
	Variable ignorePrefixMatch
	
	Variable wcnt
	String wName, wList2 = ""
	
	String wList = StrVarOrDefault( strVarName, "" )
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
		
		wName = StringFromList( wcnt, wList )
		
		if ( StringMatch( wName, oldName ) )
			if ( ignorePrefixMatch )
				wList2 = AddListItem( newName, wList2, ";", inf )
			elseif ( ( strlen( newName ) > 0 ) && newNamePrefixMatch )
				wList2 = AddListItem( newName, wList2, ";", inf )
			endif
		else
			wList2 = AddListItem( wName, wList2, ";", inf )
		endif
	
	endfor
	
	SetNMstr( strVarName, wList2 )
	
End // NMPrefixFoldersRenameWave2

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Wave Prefix Select Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixSelect( wavePrefix [ noPrompts ] ) // change to a new wave prefix
	String wavePrefix // wave prefix name, or ( "" ) for current prefix
	Variable noPrompts // ( 0 ) no ( 1 ) yes
	
	Variable ccnt, ccnt2, wcnt, numChannels, oldNumChannels, numItems, numWaves
	Variable oldWaveListExists, madePrefixFolder, prmpt = 1
	Variable ss
	
	String wlist, wName, wName2, newList, chanstr, seqstr, chanList = "", oldList = "", prefix, prefixFolder
	
	String currentFolder = StrVarOrDefault( NMDF + "CurrentFolder", "" )
	
	if ( strlen( wavePrefix ) == 0 )
		wavePrefix = StrVarOrDefault( currentFolder+"CurrentPrefix", "" )
	endif
	
	if ( strlen( wavePrefix ) == 0 )
		return -1
	endif
	
	prefixFolder = NMPrefixFolderDF( currentFolder, wavePrefix )
	
	newList = WaveList( wavePrefix + "*", ";", "Text:0" )
	numWaves = ItemsInList( newList )

	if ( numWaves <= 0 )
		NMDoAlert( "No waves detected with prefix " + NMQuotes( wavePrefix ) )
		return -1
	endif
	
	if ( strlen( prefixFolder ) > 0 )
		oldList = StrVarOrDefault( prefixFolder+"PrefixSelect_WaveList", "" )
		oldNumChannels = NumVarOrDefault( prefixFolder+"NumChannels", 0 )
	endif
	
	if ( StringMatch( newList, oldList ) )
	
		numChannels = NumVarOrDefault( prefixFolder+"NumChannels", 0 )
		numWaves = NumVarOrDefault( prefixFolder+"NumWaves", 0 )
		oldWaveListExists = 1
		prmpt = 0
		
	else
	
		numChannels = 0
	
		for ( ccnt = 0; ccnt <= 25; ccnt += 1 ) // detect multiple channels
		
			wlist = NMChanWaveListSearch( wavePrefix, ccnt )
			
			if ( ItemsInList( wlist ) > 0 )
			
				chanstr = ChanNum2Char( ccnt )
				
				for ( wcnt = 0 ; wcnt < ItemsInList( wlist ) ; wcnt += 1 )
				
					wName = StringFromList( wcnt, wList )
					
					ss = strsearch( wName, chanstr, inf, 3 )
					
					if ( ss < 0 )
						break // something is wrong
					endif
					
					prefix = wName[ 0, ss - 1 ]
					seqstr = wName[ ss + 1, inf ]
					
					chanList = chanstr + ";"
					
					for ( ccnt2 = ccnt + 1; ccnt2 <= 25; ccnt2 += 1 )
					
						wName2 = prefix + ChanNum2Char( ccnt2 ) + seqstr
					
						if ( WaveExists( $wName2 ) )
							chanList = AddListItem( ChanNum2Char( ccnt2 ), chanList, ";", inf )
						endif
					
					endfor
					
					if ( ItemsInList( chanList ) <= 1 )
						break
					endif
					
					if ( numChannels == 0 )
						numChannels = ItemsInList( chanList )
					elseif ( ItemsInList( chanList ) != numChannels )
						numChannels = -1
						break
					endif
				
				endfor
				
				break
				
			endif
			
		endfor
		
		if ( numChannels > 1 )
			numWaves = ItemsInList( wlist )
		endif
	
	endif
	
	if ( numChannels <= 0 )
		numChannels = 1
	endif
	
	if ( prmpt && ( numChannels > 1 ) && !noPrompts )
	
		Prompt numChannels, "number of channels:"
		Prompt numWaves, "waves per channel:"
	
		DoPrompt "Check Channel Configuration", numChannels, numWaves
		
		if ( V_Flag == 1 )
			return -1 // cancel
		endif
		
		if ( numChannels == 1 )
			newList = WaveList( wavePrefix + "*", ";", "Text:0" )
			numWaves = ItemsInList( newList )
		endif
		
	endif
	
	NMChannelGraphConfigsSave( -2 )
	ChanScaleSave( -2 )
	
	SetNMstr( "CurrentPrefix", wavePrefix ) // change to new prefix
	
	if ( ( strlen( prefixFolder ) > 0 ) && DataFolderExists( prefixFolder ) )
	
		CheckNMPrefixFolder( prefixFolder, numChannels, numWaves )
		
	else
	
		prefixFolder = NMPrefixFolderMake( currentFolder, wavePrefix, numChannels, numWaves )
	
		if ( strlen( prefixFolder ) > 0 )
			madePrefixFolder = 1
		endif
	
	endif
	
	if ( ( strlen( prefixFolder ) == 0 ) || !DataFolderExists( prefixFolder ) )
		NMDoAlert( "Failed to create prefix subfolder for " + NMQuotes( wavePrefix ) )
		return -1
	endif
	
	SetNMstr( prefixFolder+"PrefixSelect_WaveList", newList )
	
	if ( !oldWaveListExists )
		NMChanWaveListSet( 1 )
	endif
	
	if ( StringMatch( wavePrefix, "*Pulse_*" ) )
		NMChanUnits2Labels()
	endif
	
	CheckChanSubfolder( -2 )
	ChanGraphsReset()
	
	//UpdateNM( 1 ) // UPDATE TAB
	
	if ( oldNumChannels != numChannels )
	
		if ( ( oldNumChannels > 0 ) && ( numChannels != oldNumChannels ) )
		
			//DoAlert 1, "Alert: the number of channels for prefix " + NMQuotes( wavePrefix ) + " has changed. Do you want to update your Sets and Groups to correspond to the new number of channels?"
			
			//if ( V_Flag == 1 )
				NMSetsListsUpdateNewChannels()
				NMGroupsListsUpdateNewChannels()
			//endif
			
		endif
		
		NMChannelGraphSet( channel = -2, reposition = 1 )
		
	endif
	
	if ( madePrefixFolder )
	
		NMChanSelect( "A" )
		NMCurrentWaveSet( 0 )
		
		if ( !noPrompts )
			//NMPrefixSelectCheckDeltaX()
		endif
		
	endif
	
	if ( CurrentNMChannel() >= numChannels )
		NMChanSelect( "A" )
	endif
	
	if ( strlen( NMWaveSelectGet() ) == 0 )
		NMWaveSelect( "All" )
	else
		NMWaveSelect( "Update" )
	endif
	
	NMCurrentWaveSet( CurrentNMWave(), noSave = 1 )
	
	NMSetsPanelUpdate( 1 )
	NMGroupsPanelUpdate( 1 )
	
	return 0

End // NMPrefixSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixSelectPromptCall()

	Variable on = 1 + NMVarGet( "PrefixSelectPrompt" )
	
	Prompt on, "turn user prompts:", popup "off;on;"
	DoPrompt "Prefix Select Prompt", on
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	on -= 1
	
	return NMSet( PrefixSelectPrompt = on, history = 1 )

End // NMPrefixSelectPromptCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixSelectCheckDeltaX()

	Variable dx
	String wavePrefix, txt
	
	wavePrefix = CurrentNMWavePrefix()
	
	dx = NMChanDeltaX( 0, 1 )
	
	if ( numtype( dx ) > 0 ) // waves have different sample rates
	
		txt = "Warning: waves with prefix " + NMQuotes( wavePrefix ) + " have different x-axis sample rates (x-delta). If you want them to have the same sample rate, use the NM Main Tab Interpolate or Resample function."
	
		NMDoAlert( txt )
		
	elseif ( dx == 1 ) // sample rate may not have been set
	
		txt = "Warning: waves with prefix " + NMQuotes( wavePrefix ) + " have an x-axis delta of 1, the Igor default value. If you want to set a new x-axis delta value, use the NM Main Tab DeltaX or Wave Details functions."
		
		NMDoAlert( txt )
		
	endif

End // NMPrefixSelectCheckDeltaX

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Subfolder Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSubfolderName( folderPrefix, wavePrefix, chanNum, waveSelect )
	String folderPrefix // e.g. "Spike_" or "Event_"
	String wavePrefix // e.g. "Record"
	Variable chanNum // e.g. channel number or ( -1 ) for current channel or ( NAN ) for no channel
	String waveSelect // e.g. "Set1"
	
	String currentFolder, folderName
	
	Variable ilimit = floor( ( 29 - strlen( folderPrefix ) ) / 2 ) - 1
	
	if ( ( strlen( folderPrefix ) == 0 ) || ( strlen( wavePrefix ) == 0 ) || ( strlen( waveSelect ) == 0 ) )
		return ""
	endif
	
	currentFolder = StrVarOrDefault( NMDF + "CurrentFolder", "" )
	
	if ( strlen( currentFolder ) == 0 )
		return ""
	endif
	
	if ( chanNum == -1 )
		chanNum = CurrentNMChannel()
	endif
	
	wavePrefix = wavePrefix[ 0, ilimit ]
	wavePrefix = StringAddToEnd( wavePrefix, "_" )
	
	waveSelect = waveSelect[ 0, ilimit ]
	
	folderName = folderPrefix + wavePrefix + waveSelect
	
	folderName = folderName[ 0, 28 ]
	
	if ( ( numtype( chanNum ) == 0 ) && ( chanNum >= 0 ) && ( chanNum < NMNumChannels() ) )
		folderName += "_" + ChanNum2Char( chanNum )
	endif
	
	return currentFolder + folderName[ 0, 30 ] + ":"

End // NMSubfolderName

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMSubfolder( subfolder )
	String subfolder
	
	if ( strlen( subfolder ) == 0 )
		return -1
	endif
	
	if ( DataFolderExists( subfolder ) )
		return 0 // OK, exists
	endif
	
	NewDataFolder $RemoveEnding( subfolder, ":" )
	
	return 1 // OK, made
	
End // CheckNMSubfolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSubfolderList( folderPrefix, parentFolder, fullPath )
	String folderPrefix // e.g. "Spike_"
	String parentFolder // where to look for subfolders
	Variable fullPath // use full-path names ( 0 ) no ( 1 ) yes

	Variable icnt
	String subfolderList, folderName, outList = ""
	
	if ( strlen( parentFolder ) == 0 )
		parentFolder = StrVarOrDefault( NMDF + "CurrentFolder", "" )
	endif
	
	parentFolder = CheckNMFolderPath( parentFolder )
	
	subfolderList = FolderObjectList( parentFolder, 4 )
	
	for ( icnt = 0 ; icnt < ItemsInList( subfolderList ) ; icnt += 1 )
		
		folderName = StringFromList( icnt, subfolderList )
		
		if ( strsearch( folderName, folderPrefix, 0, 2 ) == 0 )
		
			if ( fullPath )
				outList = AddListItem( parentFolder + folderName + ":" , outList, ";", inf )
			else
				outList = AddListItem( folderName, outList, ";", inf )
			endif
			
		endif
	
	endfor
	
	return outList

End // NMSubfolderList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSubfolderList2( parentFolder, subfolderPrefix, fullPath, restrictToCurrentPrefix )
	String parentFolder // ( "" ) for current data folder
	String subfolderPrefix // e.g. "Stats_" or "Event_"
	Variable fullPath // ( 0 ) only wave name ( 1 ) folder + wname
	Variable restrictToCurrentPrefix
	
	Variable icnt
	String folderName, tempList = ""
	
	String currentPrefix = CurrentNMWavePrefix()
	
	String folderList = NMSubfolderList( subfolderPrefix, parentFolder, fullPath )
	
	Variable countFrom = strlen( subfolderPrefix )
	
	if ( restrictToCurrentPrefix )
		
		for ( icnt = 0 ; icnt < ItemsInList( folderList ) ; icnt += 1 )
			
			folderName = StringFromList( icnt, folderList )
			
			if ( strsearch( folderName, currentPrefix, countFrom, 2 ) >= countFrom )
				tempList = AddListItem( folderName, tempList, ";", inf )
			endif
			
		endfor
		
		folderList = tempList
	
	endif
	
	return folderList

End // NMSubfolderList2

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSubfolderTableName( subfolder, tablePrefix )
	String subfolder
	String tablePrefix

	String fname = NMChild( subfolder )
	
	return tablePrefix + CurrentNMFolderPrefix() + fname

End // NMSubfolderTableName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSubfolderTable( subfolder, tablePrefix [ hide, tName, tTitle ] )
	String subfolder
	String tablePrefix
	Variable hide
	String tName // table name
	String tTitle // table title
	
	Variable icnt, items
	String wList1, wList2, fname
	
	STRUCT Rect w
	
	NMOutputListsReset()
	
	if ( !DataFolderExists( subfolder ) )
		return ""
	endif
	
	wList1 = NMFolderWaveList( subfolder, "*", ";", "TEXT:1", 1 )
	wList2 = NMFolderWaveList( subfolder, "*", ";", "TEXT:0", 1 )
	
	items = ItemsInList( wList1 ) + ItemsInList( wList2 )
	
	if ( items == 0 )
		NMDoAlert( "NMSubfolderTable Alert: no waves found in subfolder " + NMChild( subfolder ) )
		return ""
	endif
	
	fname = NMChild( subfolder )
	
	if ( ParamIsDefault( tName ) || ( strlen( tName ) == 0 ) )
		tName = NMSubfolderTableName( subfolder, tablePrefix )
	endif
	
	if ( ParamIsDefault( tTitle ) || ( strlen( tTitle ) == 0 ) )
		tTitle = NMFolderListName( "" ) + " : " + ReplaceString( "_", fname, " " )
	endif
	
	DoWindow /K $tName
	
	NMWinCascadeRect( w )
	
	Edit /HIDE=(hide)/K=1/N=$tName/W=(w.left,w.top,w.right,w.bottom) as tTitle
	
	items = ItemsInList( wList1 )
	
	for ( icnt = 0 ; icnt < items ; icnt += 1 )
		AppendToTable /W=$tName $StringFromList( icnt, wList1 )
	endfor
	
	items = ItemsInList( wList2 )
	
	for ( icnt = 0 ; icnt < items ; icnt += 1 )
		AppendToTable /W=$tName $StringFromList( icnt, wList2 )
	endfor
	
	SetNMstr( NMDF + "OutputWaveList", wList1 + wList2 )
	SetNMstr( NMDF + "OutputWinList", tName )
	
	return tname
	
End // NMSubfolderTable

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSubfolderClear( subfolder )
	String subfolder
	
	Variable icnt, error = 0
	String wName, wList, failureList = ""
	
	if ( !DataFolderExists( subfolder ) )
		return ""
	endif
	
	if ( StringMatch( subfolder, GetDataFolder( 1 ) ) )
		NMDoAlert( "NMSubfolderClear Error: this function cannot kill waves inside the current NM data folder." )
		return ""
	endif
	
	wList = NMFolderWaveList( subfolder, "*", ";", "", 1 )
	
	for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
	
		wName = StringFromList( icnt, wList )
		
		KillWaves /Z $wName
		
		if ( WaveExists( $wName ) )
			failureList = AddListItem( NMChild( wName ), failureList, ";", inf )
		endif
		
	endfor
	
	return failureList

End // NMSubfolderClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSubfolderKill( subfolder )
	String subfolder
	
	if ( !DataFolderExists( subfolder ) )
		return -1
	endif
	
	if ( StringMatch( subfolder, GetDataFolder( 1 ) ) )
		NMDoAlert( "NMSubfolderKill Error: cannot delete the current NM data folder." )
		return -1
	endif
	
	if ( !DataFolderExists( subfolder ) )
		NMDoAlert( "NMSubfolderKill Error: no such folder: " + subfolder )
		return -1
	endif
	
	KillDataFolder /Z $subfolder
	
	if ( DataFolderExists( subfolder ) )
		NMFolderCloseAlert( subfolder )
		return -1
	endif
	
	return 0

End // NMSubfolderKill

//****************************************************************
//****************************************************************
//****************************************************************

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
//	Prefix Subfolder Functions
//
//	Note, prefix subfolders reside in NM data folders ( see NM_Folders.ipf )
//
//	Useful functions:
//		
//		NMNumChannels()
//		CurrentNMChannel()
//		CurrentNMChanChar()
//		NMNumWaves()
//		CurrentNMWave()
//		CurrentNMWaveName()
//		NMNumActiveWaves()
//		CurrentNMPrefixFolder( [ fullPath ] )
//		
//		NMXwaveSet( xwName [ prefixFolder, update, history ] )
//		NMNextWave( direction [ prefixFolder, update, history ] )
//		NMChanLabelSet( channel, waveSelect, xySelect, labelStr [ prefixFolder, update, history ] )
//		NMChanXLabelSetAll( xLabel [ prefixFolder, update, history ] )
//		NMWaveSelectClear( [ update, history ] )
//		NMOrderWavesByCreation( [ prefixFolder, update, history ] )
//		NMOrderWavesAlphaNum( [ prefixFolder, update, history ] )
//		NMOrderWavesByTable( [ prefixFolder, history ] )	
//		
//****************************************************************
//****************************************************************

StrConstant NMPrefixSubfolderPrefix = "NMPrefix_"
StrConstant NMChanWaveListPrefix = "Chan_WaveList"
StrConstant NMChanSelectVarName = "ChanSelect_List"
StrConstant NMWaveSelectVarName = "WaveSelect_List"

Static Constant xWavePrefix_ON = 0

//****************************************************************
//****************************************************************
//****************************************************************

Structure NMPrefixFolderParams

	Variable NumChannels, NumActiveChannels
	Variable NumWaves, NumActiveWaves
	
	Variable CurrentChannel, CurrentWave
	
	String xWave, CurrentWaveName

EndStructure // NMPrefixFolderParams

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNumChannels()
	
	Variable numChannels = NumVarOrDefault( CurrentNMPrefixFolder() + "NumChannels", 0 )

	return max( 0, numChannels )

End // NMNumChannels

//****************************************************************
//****************************************************************
//****************************************************************

Function CurrentNMChannel()
	
	Variable currentChan = NumVarOrDefault( CurrentNMPrefixFolder() + "CurrentChan", 0 )
	
	return max( 0, currentChan )

End // CurrentNMChannel

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMChanChar()

	return ChanNum2Char( CurrentNMChannel() )

End // CurrentNMChanChar

//****************************************************************
//****************************************************************
//****************************************************************

Function ChanNumCheck( channel )
	Variable channel // ( -1 ) for current channel
	
	if ( channel == -1 )
		channel = CurrentNMChannel()
	endif
	
	return channel
	
End // ChanNumCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChannelOK( channel )
	Variable channel
	
	if ( ( numtype( channel ) == 0 ) && ( channel >= 0 ) && ( channel < NMNumChannels() ) )
		return 1
	else
		return 0
	endif
	
End // NMChannelOK

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNumWaves()
	
	Variable numWaves = NumVarOrDefault( CurrentNMPrefixFolder() + "NumWaves", 0 )
	
	return max( 0, numWaves )

End // NMNumWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function CurrentNMWave()

	Variable currentWave = NumVarOrDefault( CurrentNMPrefixFolder() + "CurrentWave", 0 )
	
	return max( 0, currentWave )

End // CurrentNMWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMWaveName()

	return NMChanWaveName( -1, -1 )

End // CurrentNMWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNumActiveWaves()

	Variable numActiveWaves = NumVarOrDefault( CurrentNMPrefixFolder() + "NumActiveWaves", 0 )
	
	return max( 0, numActiveWaves )

End // NMNumActiveWaves

//****************************************************************
//****************************************************************
//****************************************************************
//
//	General Prefix Folder functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMPrefixFolder( [ fullPath ] )
	Variable fullPath // ( 0 ) folder name only ( 1 ) fullpath folder name, including root
	
	String folder, prefix, prefixFolder
	
	if ( ParamIsDefault( fullPath ) )
		fullPath = 1
	endif
	
	folder = CurrentNMFolder( 1 )
	prefix = StrVarOrDefault( folder + "CurrentPrefix", "" )
	
	if ( strlen( prefix ) == 0 )
		return ""
	endif
	
	if ( fullPath )
	
		prefixFolder = NMPrefixFolderDF( folder, prefix )
	
		if ( DataFolderExists( prefixFolder ) )
			return prefixFolder
		endif
	
	else
	
		return NMPrefixSubfolderPrefix + prefix
	
	endif
	
	return ""

End // CurrentNMPrefixFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixFolderAlert()

	if ( strlen( CurrentNMPrefixFolder() ) > 0 )
		return 0
	endif
	
	NMDoAlert( "No waves! You may need to select " + NMQuotes( "Wave Prefix" ) + " first." )
	
	return 1

End // NMPrefixFolderAlert

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CheckNMPrefixFolderPath( prefixFolder )
	String prefixFolder
	
	String parent

	if ( strlen( prefixFolder ) == 0 )
		prefixFolder = CurrentNMPrefixFolder()
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	if ( !DataFolderExists( prefixFolder ) )
		return ""
	endif
	
	if ( strsearch( prefixFolder, NMPrefixSubfolderPrefix, 0, 2 ) < 0 )
		return "" // wrong type of folder
	endif
	
	parent = NMParent( prefixFolder )
	
	if ( strlen( parent ) == 0 )
		return LastPathColon( GetDataFolder( 1 ) + prefixFolder, 1 )
	endif
	
	return LastPathColon( prefixFolder, 1 )
	
End // CheckNMPrefixFolderPath

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefixFolderDF( parent, wavePrefix )
	String parent, wavePrefix
	
	parent = CheckNMFolderPath( parent )
	
	if ( ( strlen( parent ) == 0 ) || !DataFolderExists( parent ) )
		return ""
	endif
	
	if ( strlen( wavePrefix ) == 0 )
		wavePrefix = StrVarOrDefault( parent + "CurrentPrefix", "" )
	endif
	
	if ( strlen( wavePrefix ) == 0 )
		return ""
	endif
	
	return parent + NMPrefixSubfolderPrefix + wavePrefix + ":"

End // NMPrefixFolderDF

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixFolderUtility( parent, select )
	String parent
	String select // "rename" or "check" or "unlock"
	
	Variable icnt
	String flist, prefixFolder
	
	parent = CheckNMFolderPath( parent )
	
	if ( ( strlen( parent ) == 0 ) || !DataFolderExists( parent ) )
		return -1
	endif
	
	flist = FolderObjectList( parent , 4 )
	
	for ( icnt = 0 ; icnt < ItemsInList( flist ) ; icnt += 1 )
	
		prefixFolder = StringFromList( icnt, flist )
	
		strswitch( select )
		
			case "rename":
				NMPrefixFolderRename( LastPathColon( parent+prefixFolder, 1 ) )
				break
				
			case "check":
				CheckNMPrefixFolder( LastPathColon( parent+prefixFolder, 1 ), Nan, Nan )
				break
				
			case "unlock":
				NMPrefixFolderLock( LastPathColon( parent+prefixFolder, 1 ), 0 )
				break
		
		endswitch
		
	endfor
	
	return 0

End // NMPrefixFolderUtility

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefixFolderMake( parent, wavePrefix, numChannels, numWaves )
	String parent, wavePrefix
	Variable numChannels, numWaves
	
	String prefixFolder = NMPrefixFolderDF( parent, wavePrefix )
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	if ( DataFolderExists( prefixFolder ) )
		return "" // already exists
	endif
	
	NewDataFolder $RemoveEnding( prefixFolder, ":" )
	
	CheckNMPrefixFolder( prefixFolder, numChannels, numWaves )
	
	return prefixFolder
	
End // NMPrefixFolderMake

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMPrefixFolder( prefixFolder, numChannels, numWaves ) // check prefix subfolder globals
	String prefixFolder
	Variable numChannels, numWaves
	
	String wName, waveSelect
	
	prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( numtype( numChannels ) == 0 )
		SetNMvar( prefixFolder + "NumChannels", numChannels )
	endif
	
	if ( numtype( numWaves ) == 0 )
		SetNMvar( prefixFolder + "NumWaves", numWaves )
	endif
	
	CheckNMChanWaveLists( prefixFolder = prefixFolder )
	
	CheckNMSets( prefixFolder = prefixFolder )
	CheckNMGroups( prefixFolder = prefixFolder )
	
	CheckNMChanSelect( prefixFolder = prefixFolder )
	CheckNMWaveSelect( prefixFolder = prefixFolder )
	
	return 0

End // CheckNMPrefixFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixFolderRename( prefixFolder )
	String prefixFolder
	
	String fname, parent, newName
	
	//prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	//if ( ( exists( prefixFolder+"CurrentChan" ) != 2 ) || ( exists( prefixFolder+"CurrentWave" ) != 2 ) )
	//	return -1 // wrong type of subfolder
	//endif
	
	if ( exists( prefixFolder+"NumChannels" ) != 2 )
		return -1 // wrong type of subfolder
	endif
	
	fname = NMChild( prefixFolder )
	parent = NMParent( prefixFolder )
	
	if ( ( strlen( NMPrefixSubfolderPrefix ) > 0 ) && ( strsearch( fname, NMPrefixSubfolderPrefix, 0, 2 ) < 0 ) )
				
		newName = NMPrefixSubfolderPrefix + fname
		
		if ( !DataFolderExists( parent + newName ) )
			RenameDataFolder $RemoveEnding( prefixFolder, ":" ), $newName
		endif
				
	endif

End // NMPrefixFolderRename

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixFolderLock( prefixFolder, lock )
	String prefixFolder
	Variable lock // ( 0 ) no ( 1 ) yes
	
	String wName
	
	Variable lockFolders = 0 // NOT USED ANYMORE
	
	if ( lock && !lockFolders )
		return -1
	endif
	
	prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	wName = prefixFolder + "Lock"
				
	if ( lock )
	
		if ( !WaveExists( $wName ) )
			Make /O/N=1 $wName
			Note $wName, "this NM wave is locked to prevent accidental deletion of NM data folders. Control click in the Data Browser to unlock this wave."
			SetWaveLock 1, $wName
		endif
		
	elseif ( WaveExists( $wName ) )

		SetWaveLock 0, $wName
		
	endif

End // NMPrefixFolderLock

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixFolderStrVarKill( strVarPrefix [ prefixFolder ] )
	String strVarPrefix // prefix name
	String prefixFolder

	Variable icnt, killedsomething
	String strVarName, strVarList
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	strVarList = NMFolderStringList( prefixFolder, strVarPrefix + "*", ";", 1 )
	
	for ( icnt = 0 ; icnt < ItemsInList( strVarList ) ; icnt += 1 )
	
		strVarName = StringFromList( icnt, strVarList )
		KillStrings /Z $strVarName
	
		if ( exists( strVarName ) == 0 )
			killedsomething = 1
		endif
		
	endfor
	
	return killedsomething

End // NMPrefixFolderStrVarKill

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixFolderWaveKill( wavePrefix [ prefixFolder ] )
	String wavePrefix // prefix name
	String prefixFolder

	Variable icnt, killedsomething
	String wName, wList
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	wList = NMFolderWaveList( prefixFolder, wavePrefix + "*", ";", "", 1 )
	
	for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
	
		wName = StringFromList( icnt, wList )
		KillWaves /Z $wName
	
		if ( !WaveExists( $wName ) )
			killedsomething = 1
		endif
		
	endfor
	
	return killedsomething

End // NMPrefixFolderWaveKill

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixFolderWaveToLists( inputWaveName, outputStrVarPrefix [ prefixFolder ] )
	String inputWaveName
	String outputStrVarPrefix
	String prefixFolder
	
	Variable icnt, ccnt, wcnt, numChannels, alertUser = 0
	String wList, strVarName, strVarList, chanList, wName
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( !WaveExists( $inputWaveName ) )
		return -1
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	if ( ( numtype( numChannels ) > 0 ) || ( numChannels <= 0 ) )
		return -1
	endif
	
	strVarList = NMFolderStringList( prefixFolder, outputStrVarPrefix + "*", ";", 1 )
	
	if ( ItemsInList( strVarList ) > 0 )
	
		if ( alertUser )
	
			DoAlert 1, "NMPrefixFolderWaveToLists Alert: wave lists with prefix " + NMQuotes( outputStrVarPrefix ) + " already exist. Do you want to overwrite them?"
			
			if ( V_flag != 1 )
				return -1 // cancel
			endif
		
		endif
		
		for ( icnt = 0 ; icnt < ItemsInList( strVarList ) ; icnt += 1 )
			KillStrings /Z $StringFromList( icnt, strVarList )
		endfor
	
	endif
	
	Wave input = $inputWaveName
	
	for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
	
		strVarName = prefixFolder + outputStrVarPrefix + ChanNum2Char( ccnt )
		
		wList = ""
		chanList = NMChanWaveList( ccnt, prefixFolder = prefixFolder )
	
		for ( wcnt = 0 ; wcnt < numpnts( input ) ; wcnt += 1 )
			
			if ( input[ wcnt ] == 1 )
			
				wName = StringFromList( wcnt, chanList )
				
				if ( strlen( wName ) > 0 )
					wList = AddListItem( wName, wList, ";", inf )
				endif
				
			endif
		
		endfor
		
		SetNMstr( strVarName, wList )
	
	endfor
	
	return 0
	
End // NMPrefixFolderWaveToLists

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixFolderListsToWave( inputStrVarPrefix, outputWaveName [ prefixFolder ] )
	String inputStrVarPrefix
	String outputWaveName
	String prefixFolder

	Variable ccnt, wcnt, wnum, numChannels, numWaves, alertUser = 0
	String wList, strVarName, chanList, wName 
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( WaveExists( $outputWaveName ) )
	
		if ( alertUser )
	
			DoAlert 1, "NMPrefixFolderListsToWave Alert: wave " + NMQuotes( outputWaveName ) + " already exists. Do you want to overwrite it?"
			
			if ( V_flag != 1 )
				return -1 // cancel
			endif
		
		endif
		
		KillWaves /Z $outputWaveName // try to kill
		
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	numWaves = NumVarOrDefault( prefixFolder + "NumWaves", 0 )
	
	if ( numChannels == 0 )
		return -1
	endif
	
	CheckNMWave( outputWaveName, numWaves, 0 )
	
	if ( !WaveExists( $outputWaveName ) )
		return -1
	endif

	Wave output = $outputWaveName
	
	output = 0

	for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
	
		strVarName = prefixFolder + inputStrVarPrefix + ChanNum2Char( ccnt )
		
		wList = StrVarOrDefault( strVarName, "" )
		chanList= NMChanWaveList( ccnt, prefixFolder = prefixFolder )
	
		for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
			
			wName = StringFromList( wcnt, wList )
			wnum = WhichListItem( wName, chanList )
			
			if ( ( wnum >= 0 ) && ( wnum < numpnts( output ) ) )
				output[ wnum ] = 1
			endif
		
		endfor
	
	endfor
	
	return 0

End // NMPrefixFolderListsToWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefixFolderStrVarListAdd( waveListToAdd, strVarName, channel [ prefixFolder ] )
	String waveListToAdd
	String strVarName
	Variable channel
	String prefixFolder
	
	String wList
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	wList = StrVarOrDefault( strVarName, "" )
	
	wList = NMAddToList( waveListToAdd, wList, ";" )
	wList = OrderToNMChanWaveList( wList, channel, prefixFolder = prefixFolder )
	
	SetNMstr( strVarName, wList )
	
	return wList
	
End // NMPrefixFolderStrVarListAdd

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefixFolderStrVarListRemove( waveListToRemove, strVarName, channel )
	String waveListToRemove
	String strVarName
	Variable channel
	
	String wList
	
	if ( exists( strVarName ) != 2 )
		return ""
	endif

	wList = StrVarOrDefault( strVarName, "" )
	wList = RemoveFromList( waveListToRemove, wList, ";" )
	
	SetNMstr( strVarName, wList )
	
	return wList
	
End // NMPrefixFolderStrVarListRemove

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixFolderGetOldGlobals( [ parent ] )
	String parent

	Variable icnt, channel, numChannels, currentChan, numWaves, currentWave, currentGrp
	String prefixFolder, setName, newName, wName, setList, chanSelectList

	if ( !NMVarGet( "CreateOldFolderGlobals" ) )
		return 0 // nothing to do
	endif
	
	if ( ParamIsDefault( parent ) )
		parent = CurrentNMFolder( 1 )
	else
		parent = CheckNMFolderPath( parent )
	endif
	
	if ( strlen( parent ) == 0 )
		return -1
	endif
	
	prefixFolder = NMPrefixFolderDF( parent, "" )
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	currentChan = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	
	numWaves = NumVarOrDefault( prefixFolder + "NumWaves", 0 )
	currentWave = NumVarOrDefault( prefixFolder + "CurrentWave", 0 )
	currentGrp = NMGroupsNum( currentWave, prefixFolder = prefixFolder )
	
	Variable /G $parent + "CurrentChan" = currentChan
	Variable /G $parent + "CurrentGrp" = currentGrp
	Variable /G $parent + "CurrentWave" = currentWave
	Variable /G $parent + "NumActiveWaves" = NumVarOrDefault( prefixFolder + "NumActiveWaves", 0 )
	Variable /G $parent + "NumChannels" = numChannels
	Variable /G $parent + "NumWaves" = numWaves
	Variable /G $parent + "TotalNumWaves" = numChannels * numWaves
	
	setList = NMSetsList( prefixFolder = prefixFolder )
	chanSelectList = StrVarOrDefault( prefixFolder + NMChanSelectVarName, "" )
	
	for ( icnt = 0 ; icnt < ItemsInList( setList ) ; icnt += 1 )
	
		setName = StringFromList( icnt, setList )
		newName = parent + setName
		
		KillWaves /Z $newName
		
		NMPrefixFolderListsToWave( NMSetsStrVarPrefix( setName ), newName, prefixFolder = prefixFolder )
		
		NMSetsWavesTag( newName )
		
	endfor
	
	newName = parent + "Group"
	
	KillWaves /Z $newName
	
	NMGroupsListsToWave( newName, prefixFolder = prefixFolder )
	
	newName = parent + "ChanSelect"
	
	Make /O/N=( numChannels ) $newName = 0
	
	Wave wtemp = $newName
	
	for ( icnt = 0 ; icnt < ItemsInList( chanSelectList ) ; icnt += 1 )
	
		channel = str2num( StringFromList( icnt, chanSelectList ) )
		
		if ( ( channel >= 0 ) && ( channel < numpnts( wtemp ) ) )
			wtemp[ channel ] = 1
		endif
		
	endfor
	
	newName = parent + "ChanWaveList"
	
	Make /T/O/N=( numChannels ) $newName = ""
	
	Wave /T stemp = $newName
	
	for ( icnt = 0 ; icnt < numpnts( stemp ) ; icnt += 1 )
	
		stemp[ icnt ] = NMChanWaveList( icnt, prefixFolder = prefixFolder )
		
		wName = prefixFolder + "ChanWaveNames" + ChanNum2Char( icnt )
		newName = parent + "wNames_" + ChanNum2Char( icnt )
		
		if ( WaveExists( $wName ) )
			Duplicate /O $wName $newName
		endif
		
	endfor
	
	newName = parent + "WavSelect"
	
	Make /O/N=( numWaves ) $newName = 0
	
	Wave wtemp = $newName
	
	for ( icnt = 0 ; icnt < numpnts( wtemp ) ; icnt += 1 )
		
		wName = NMWaveSelected( currentChan, icnt, prefixFolder = prefixFolder )
			
		if ( strlen( wName ) > 0 )
			wtemp[ icnt ] = 1
		endif
	
	endfor
	
	return 0

End // NMPrefixFolderGetOldGlobals

//****************************************************************
//****************************************************************
//****************************************************************
//
//	x-wave functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMXwaveNameDefault( [ wavePrefix, chanNum ] ) // NOT USED
	String wavePrefix
	Variable chanNum
	
	Variable slen
	String wName, xunits
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = CurrentNMWavePrefix()
	endif

	if ( strlen( wavePrefix ) == 0 )
		return ""
	endif
	
	if ( !ParamIsDefault( chanNum ) && ( numtype( chanNum ) == 0 ) )
		wavePrefix += ChanNum2Char( chanNum )
	endif
	
	wName = NMXscalePrefix + wavePrefix
	wName = NMCheckStringName( wName )
	
	slen = strlen( wName )
	
	xunits = NMChanLabelX( units = 1 )
	
	if ( ( strlen( xunits ) > 0 ) && ( strlen( wName + "_" + xunits ) <= 31 ) )
		wName += "_" + xunits
	endif
	
	return NMCheckStringName( wName )

End // NMXwaveNameDefault

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CurrentNMXwave( [ fullPath ] ) // NOT USED
	Variable fullPath

	String wName, xWave, xWavePrefix
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	Variable channel = CurrentNMChannel()
	Variable waveNum = CurrentNMWave()
	
	xWavePrefix = StrVarOrDefault( prefixFolder + "XwavePrefix", "" )
	
	if ( strlen( xWavePrefix ) > 0 )
	
		wName = NMChanWaveName( channel, waveNum, prefixFolder = prefixFolder )
		
		if ( strlen( wName ) == 0 )
			return ""
		endif
		
		if ( fullPath )
			xWave = NMParent( prefixFolder ) + xWavePrefix + wName
		else
			xWave = xWavePrefix + wName
		endif
		
		if ( WaveExists( $xWave ) )
			return xWave
		else
			return ""
		endif
		
	endif
	
	xWave = StrVarOrDefault( prefixFolder + "Xwave", "" )
	
	if ( strlen( xWave ) == 0 )
		return ""
	endif
	
	if ( fullPath )
		xWave = NMParent( prefixFolder ) + xWave
	endif
	
	if ( WaveExists( $xWave ) )
		return xWave
	endif

	return ""
	
End // CurrentNMXwave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMXwave( [ prefixFolder, waveNum, fullPath ] )
	String prefixFolder
	Variable waveNum // if using xWavePrefix
	Variable fullPath

	Variable channel
	String wName, yWave
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	String xWave = StrVarOrDefault( prefixFolder + "Xwave", "" )
	String xWavePrefix = StrVarOrDefault( prefixFolder + "XwavePrefix", "" )
	
	if ( xWavePrefix_ON && strlen( xWavePrefix ) > 0 )
	
		if ( ParamIsDefault( waveNum ) )
			print GetRTStackInfo( 2 )
			return NM2ErrorStr( 11, "waveNum", "" ) // need to specify wave number when using xWavePrefix
		endif
		
		channel = 0 // use channel 0 for name
		yWave = NMChanWaveName( channel, waveNum, prefixFolder = prefixFolder )
		
		if ( fullPath )
			wName = NMParent( prefixFolder ) + xWavePrefix + yWave
		else
			wName = xWavePrefix + yWave
		endif
		
	elseif ( strlen( xWave ) > 0 )
	
		if ( fullPath )
			wName = NMParent( prefixFolder ) + xWave
		else
			wName = xWave
		endif
		
	else
	
		return ""
	
	endif
	
	if ( WaveExists( $wName ) )
		return wName
	endif

	return ""

End // NMXwave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMXwaveSetCall()

	Variable ccnt, npnts, numChannels = NMNumChannels()
	String optionsStr, wList = ""
	
	String currentPrefix = CurrentNMWavePrefix()
	String prefixFolder = CurrentNMPrefixFolder()
	
	String xWave = StrVarOrDefault( prefixFolder + "Xwave", "" )
	String xWavePrefix = StrVarOrDefault( prefixFolder + "XwavePrefix", "" )
	
	npnts = NMChanXstats( "numpnts" )
	
	optionsStr = NMWaveListOptions( npnts, 0 )
	
	if ( numtype( npnts ) == 0 )
	
		wList = WaveList( "*", ";", optionsStr )
		
		for ( ccnt = 0; ccnt < numChannels; ccnt += 1 )
			wList = RemoveFromList( NMChanWaveList( ccnt ), wList, ";" )
		endfor
		
	endif
	
	if ( ItemsInList( wList ) == 0 )
		wList = "No Xwave;"
	else
		wList = "No Xwave;---;" + wList
	endif
	
	Prompt xWave, "select a wave of x-scale values:", popup wList
	Prompt xWavePrefix, "or enter the prefix name of the x-scale waves:"
	
	if ( xWavePrefix_ON )
		DoPrompt "set Xwave for wave prefix " + NMQuotes( currentPrefix ), xWave, xWavePrefix
	else
		DoPrompt "set Xwave for wave prefix " + NMQuotes( currentPrefix ), xWave
	endif
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( strlen( xWavePrefix ) > 0 )
		return NMXwavePrefixSet( xWavePrefix, prefixFolder = prefixFolder, history = 1 )
	else
		return NMXwaveSet( xWave, prefixFolder = prefixFolder, history = 1 )
	endif
	
End // NMXwaveSetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMXwaveSet( xWave [ prefixFolder, update, history ] )
	String xWave
	String prefixFolder
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable ccnt, npnts, numChannels
	String fxn = "NMXwaveSet"
	
	String vlist = NMCmdStr( xWave, "" )
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		vlist = NMCmdStrOptional( "prefixFolder", prefixFolder, vlist )
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	if ( StringMatch( xWave, "No Xwave" ) )
	
		xWave = ""
		
	elseif ( !WaveExists( $xWave ) )
	
		NMDoAlert( "Abort NMXwaveSet: " + xWave + " does not exist." )
		return ""
		
	else
	
		numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
		for ( ccnt = 0; ccnt < numChannels; ccnt += 1 )
		
			npnts = GetXstats( "numpnts", NMChanWaveList( ccnt, prefixFolder = prefixFolder ) )
		
			if ( numtype( npnts ) > 0 )
				NMDoAlert( "Abort NMXwaveSet: for this function to work, your waves must have the same dimension." )
				return ""
			endif
		
		endfor
	
	endif
	
	SetNMstr( prefixFolder + "Xwave", xWave )
	SetNMstr( prefixFolder + "XwavePrefix", "" )
	
	if ( history )
		//NMHistory( fxn + " : " + xWave )
	endif
	
	if ( update )
		ChanGraphsReset()
		ChanGraphsUpdate()
		UpdateNMPanel( 1 )
	endif
	
	return xWave
	
End // NMXwaveSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMXwavePrefixSet( xWavePrefix [ prefixFolder, update, history ] )
	String xWavePrefix
	String prefixFolder
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable ccnt, npnts
	String parent, wavePrefix, wList, thisfxn = GetRTStackInfo( 1 )
	
	String vlist = NMCmdStr( xWavePrefix, "" )
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		vlist = NMCmdStrOptional( "prefixFolder", prefixFolder, vlist )
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	parent = NMParent( prefixFolder )
	
	if ( strlen( xWavePrefix ) > 0 )
	
		wavePrefix = NMChild( prefixFolder )
		wavePrefix = ReplaceString( "NMPrefix_", wavePrefix, "" )
		
		wList = NMFolderWaveList( parent, xWavePrefix + wavePrefix + "*", ";", "TEXT:0", 0 )
			
		if ( ItemsInList( wList ) == 0 )
		
			NMDoAlert( "Abort " + thisfxn + ": waves with prefix name " + NMQuotes( xWavePrefix + wavePrefix ) + " do not exist." )
			
			return ""
			
		endif
		
	endif
	
	SetNMstr( prefixFolder + "Xwave", "" )
	SetNMstr( prefixFolder + "XwavePrefix", xWavePrefix )
	
	if ( update )
		ChanGraphsReset()
		ChanGraphsUpdate()
		UpdateNMPanel( 1 )
	endif
	
	return xWavePrefix
	
End // NMXwavePrefixSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMLeftX( yWave [ xWave ] )
	String yWave
	String xWave
	
	if ( strlen( yWave ) == 0 )
		yWave = CurrentNMWaveName()
	endif
	
	if ( !WaveExists( $yWave ) )
		return Nan
	endif
	
	if ( ParamIsDefault( xWave ) )
		xWave = ""
	endif
	
	if ( WaveExists( $xWave ) && ( numpnts( $yWave ) == numpnts( $xWave ) ) )
	
		WaveStats /Q $xWave
		
		return V_min
		
	endif
	
	return leftx( $yWave )
	
End // NMLeftX

//****************************************************************
//****************************************************************
//****************************************************************

Function NMRightX( yWave [ xWave ] )
	String yWave
	String xWave
	
	if ( strlen( yWave ) == 0 )
		yWave = CurrentNMWaveName()
	endif
	
	if ( !WaveExists( $yWave ) )
		return Nan
	endif
	
	if ( ParamIsDefault( xWave ) )
		xWave = ""
	endif
	
	if ( WaveExists( $xWave ) && ( numpnts( $yWave ) == numpnts( $xWave ) ) )
	
		WaveStats /Q $xWave
		
		return V_max
	
	endif
	
	return rightx( $yWave )
	
End // NMRightX

//****************************************************************
//****************************************************************
//****************************************************************

Function NMXscaleTransform( xValue, direction [ yWave, xWave, deprecation ] ) // for XY data pairs
	Variable xValue
	String direction // "x2y" or "y2x"
	String yWave // y-data wave name
	String xWave // x-scale wave name
	Variable deprecation
	
	Variable ipnt
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( yWave ) )
		yWave = ""
	endif
	
	if ( strlen( yWave ) == 0 )
		yWave = CurrentNMWaveName()
	endif
	
	if ( ParamIsDefault( xWave ) )
		xWave = ""
	endif
	
	if ( ( numtype( xValue ) > 0 ) || !WaveExists( $yWave ) || !WaveExists( $xWave ) )
		return xValue // no transformation
	endif
	
	if ( StringMatch( direction, "y2x" ) ) // from xValue of yWave to xWave
	
		ipnt = x2pnt( $yWave, xValue )
		
		Wave xtemp = $xWave
		
		if ( ( ipnt >= 0 ) && ( ipnt < numpnts( xtemp ) ) )
			return xtemp[ ipnt ]
		endif
		
	elseif ( StringMatch( direction, "x2y" ) ) // from xValue of xWave to timebase of yWave
	
		ipnt = NMX2Pnt( xWave, xValue )
		
		if ( ( numtype( ipnt ) == 0 ) && ( ipnt >= 0 ) && ( ipnt < numpnts( $yWave ) ) )
			return pnt2x( $yWave, ipnt )
		else
			return xValue // no transformation
		endif
	 	
	endif
	
	return xValue // no transformation
	
End // NMXscaleTransform

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Wave Number Select Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMCurrentWaveSet( waveNum [ prefixFolder, update, noSave ] )
	Variable waveNum
	String prefixFolder
	Variable update
	Variable noSave
	
	Variable ccnt, grpNum, numWaves, numChannels = NMNumChannels()
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return NaN
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	numWaves = NumVarOrDefault( prefixFolder + "NumWaves", 0 )
	
	if ( waveNum < 0 )
		waveNum = 0
	elseif ( waveNum >= numWaves )
		waveNum = numWaves - 1
	endif
	
	if ( numtype( waveNum ) > 0 )
		waveNum = NumVarOrDefault( prefixFolder + "CurrentWave", 0 )
	endif
	
	grpNum = NMGroupsNum( waveNum, prefixFolder = prefixFolder )
	
	SetNMvar( prefixFolder+"CurrentWave", waveNum )
	SetNMvar( prefixFolder+"CurrentGrp", grpNum )
	
	SetNMvar( NMDF+"CurrentWave", waveNum )
	SetNMvar( NMDF+"CurrentGrp", grpNum )
	SetNMstr( NMDF+"CurrentGrpStr", NMGroupsStr( grpNum ) )
	
	if ( !noSave )
		NMChannelGraphConfigsSave( -2 )
		ChanScaleSave( -2 )
	endif
	
	if ( update )
		UpdateCurrentWave()
	endif
	
	return waveNum
	
End // NMCurrentWaveSet

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateCurrentWave()

	//Print GetRTStackInfo( 0 )

	//NMGroupUpdate()
	UpdateNMPanelSets( 0 )
	ChanGraphsUpdate()
	//NMWaveSelect( "update" )
	NMAutoTabCall()
	
End // UpdateCurrentWave

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNextWave( direction [ prefixFolder, update, history ] ) // set next wave number
	Variable direction
	String prefixFolder
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable icnt, grpNum, next, found = -1
	Variable currentChan, currentWave, numWaves
	Variable wskip = NMVarGet( "WaveSkip" )
	String vlist = ""
	
	if ( direction != -1 )
		direction = 1
	endif
	
	vlist = NMCmdNum( direction, vlist, integer = 1 )
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		vlist = NMCmdStrOptional( "prefixFolder", prefixFolder, vlist )
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	currentChan = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	currentWave = NumVarOrDefault( prefixFolder + "CurrentWave", 0 )
	numWaves = NumVarOrDefault( prefixFolder + "NumWaves", 0 )
	
	if ( numWaves == 0 )
		NMDoAlert("No waves to display.")
		return -1
	endif
	
	if ( wskip < 0 )
		wskip = 1
		SetNMvar( NMDF+"WaveSkip", wskip)
	endif

	if ( wskip > 0 )
	
		next = currentWave + direction * wskip
		
		if ( ( next >= 0 ) && ( next < numWaves ) )
			found = next
		endif
		
	elseif ( wskip == 0 ) // As Wave Select
	
		if ( direction < 0 )
		
			for ( icnt = currentWave - 1 ; icnt >= 0 ; icnt -= 1 )
				
				if ( NMWaveIsSelected( currentChan, icnt, prefixFolder = prefixFolder ) )
					found = icnt
					break
				endif
			
			endfor
			
		else
		
			for ( icnt = currentWave + 1 ; icnt < numWaves ; icnt += 1 )
				
				if ( NMWaveIsSelected( currentChan, icnt, prefixFolder = prefixFolder ) )
					found = icnt
					break
				endif
			
			endfor
		
		endif
		
	endif

	if ( ( found >= 0 ) && ( found != currentWave ) )
	
		found = NMCurrentWaveSet( found, prefixFolder = prefixFolder, update = 0 )
		
		if ( update && ( numtype( found ) == 0 ) )
			UpdateCurrentWave()
		endif
		
	endif
	
	return found

End // NMNextWave

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Channel Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanList( type [ prefixFolder ] )
	String type // "NUM" or "CHAR"
	String prefixFolder
	
	Variable ccnt, numChannels
	String chanList = ""
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	for ( ccnt = 0; ccnt < numChannels; ccnt += 1 )
	
		strswitch( type )
			case "NUM":
				chanList = AddListItem( num2istr( ccnt ) , chanList, ";", inf )
				break
			case "CHAR":
				chanList = AddListItem( ChanNum2Char( ccnt ) , chanList, ";", inf )
				break
			default:
				return ""
		endswitch
		
	endfor
	
	return chanlist // returns chan list ( e.g. "0;1;2;" or "A;B;C;" )

End // NMChanList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanLabelXAll( [ folder, wavePrefix, prefixFolder, units ] )
	String folder // NM data folder, pass nothing for current data folder
	String wavePrefix // pass nothing for current wave prefix
	String prefixFolder // prefix subfolder ( passing this parameter will usurp folder and wavePrefix )
	Variable units // pass 1 to convert label to units, e.g. "mV" or "pA"

	Variable ccnt, numChannels
	String shortName, xLabel, xLabelList = ""
	
	// BEGIN folder / wavePrefix / prefixFolder check
	
	if ( ParamIsDefault( prefixFolder ) )
	
		if ( ParamIsDefault( folder ) )
			folder = CurrentNMFolder( 1 )
		else
			folder = CheckNMFolderPath( folder )
		endif
		
		if ( !IsNMDataFolder( folder ) )
			return ""
		endif
		
		if ( ParamIsDefault( wavePrefix ) )
			wavePrefix = StrVarOrDefault( folder + "CurrentPrefix", "" )
		endif
		
		prefixFolder = NMPrefixFolderDF( folder,  wavePrefix )
		
		if ( strlen( prefixFolder ) == 0 )
			return ""
		endif
		
	else
		
		if ( strlen( prefixFolder ) == 0 )
			prefixFolder = CurrentNMPrefixFolder()
		else
			prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
		endif
		
		if ( strlen( prefixFolder ) == 0 )
			return ""
		endif
		
		prefixFolder = LastPathColon( prefixFolder, 1 )
	
	endif
	
	// END folder / wavePrefix / prefixFolder check
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	if ( numChannels <= 0 )
		return ""
	endif

	for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
		xLabel = NMChanLabelX( prefixFolder = prefixFolder, channel = ccnt, units = units )
		xLabelList = NMAddToList( xLabel, xLabelList, ";" )
	endfor
	
	if ( ItemsInList( xLabelList ) > 1 )
		return xLabelList
	else
		return StringFromList( 0, xLabelList )
	endif
	
End // NMChanLabelXAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanLabelX( [ folder, wavePrefix, prefixFolder, channel, waveNum, units ] )
	String folder // NM data folder, pass nothing for current data folder
	String wavePrefix // pass nothing for current wave prefix
	String prefixFolder // prefix subfolder ( passing this parameter will usurp folder and wavePrefix ) 
	Variable channel // channel number, pass nothing or -1 for current channel
	Variable waveNum // wave number, pass nothing or -1 for current wave
	Variable units // pass 1 to convert label to units, e.g. "mV" or "pA"
	
	Variable numChannels, numWaves
	String xLabel, wName, shortName, wList
	String defaultWavePrefix, defaultLabel = ""
	
	// BEGIN folder / wavePrefix / prefixFolder check
	
	if ( ParamIsDefault( prefixFolder ) )
	
		if ( ParamIsDefault( folder ) )
			folder = CurrentNMFolder( 1 )
		else
			folder = CheckNMFolderPath( folder )
		endif
		
		if ( !IsNMDataFolder( folder ) )
			return ""
		endif
		
		if ( ParamIsDefault( wavePrefix ) )
			wavePrefix = StrVarOrDefault( folder + "CurrentPrefix", "" )
		endif
		
		prefixFolder = NMPrefixFolderDF( folder,  wavePrefix )
		
		if ( strlen( prefixFolder ) == 0 )
			return ""
		endif
		
	else
	
		if ( strlen( prefixFolder ) == 0 )
			prefixFolder = CurrentNMPrefixFolder()
		else
			prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
		endif
		
		if ( strlen( prefixFolder ) == 0 )
			return ""
		endif
		
		prefixFolder = LastPathColon( prefixFolder, 1 )
	
		folder = NMParent( prefixFolder )
		shortName = NMChild( prefixFolder )
		
		if ( strsearch( shortName, NMPrefixSubfolderPrefix, 0 ) != 0 )
			return "" // this is not a NM prefix subfolder
		endif
		
		wavePrefix = ReplaceString( NMPrefixSubfolderPrefix, shortName, "" )
		
		if ( strlen( wavePrefix ) == 0 )
			return "" // something is wrong
		endif
	
	endif
	
	// END folder / wavePrefix / prefixFolder check
	
	// BEGIN chan / waveNum check
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	numWaves = NumVarOrDefault( prefixFolder + "NumWaves", 0 )
	
	if ( ( ParamIsDefault( channel ) ) || ( channel == -1 ) )
		channel = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	endif
	
	if ( ( channel < 0 ) || ( channel >= numChannels ) )
		return ""
	endif
	
	if ( ParamIsDefault( waveNum ) )
		waveNum = 0 // use first channel wave as default
	endif
	
	if ( waveNum == -1 )
		waveNum = NumVarOrDefault( prefixFolder + "CurrentWave", 0 )
	endif
	
	if ( ( waveNum < 0 ) || ( waveNum >= numWaves ) )
		return ""
	endif
	
	// END chan / waveNum check
	
	defaultWavePrefix = StrVarOrDefault( folder + "WavePrefix", "" )
	
	if ( ( strlen( defaultWavePrefix ) > 0 ) && StringMatch( wavePrefix, defaultWavePrefix ) )
		defaultLabel = StrVarOrDefault( folder + "xLabel", "" )
	endif
	
	wList = StrVarOrDefault( prefixFolder + NMChanWaveListPrefix + ChanNum2Char( channel ), "" )
	
	if ( ItemsInList( wList ) == 0 )
	
		xLabel = defaultLabel
		
	else
	
		wName = StringFromList( waveNum, wList )
		
		xLabel = NMNoteLabel( "x", folder + wName, defaultLabel )
		
		if ( strlen( xLabel ) == 0 )
			xLabel = NMWaveUnits( "x", wName )
		endif
	
	endif
	
	if ( ( units == 1 ) && ( strlen( xLabel ) > 0 ) )
		return UnitsFromStr( xLabel )
	else
		return xLabel
	endif
	
End // NMChanLabelX

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanLabelX2( nm [ waveNum, units ] )
	STRUCT NMParams &nm
	Variable waveNum // wave number, pass nothing or -1 for current wave
	Variable units // pass 1 to convert label to units, e.g. "mV" or "pA"
	
	Variable numWaves
	String xLabel, wName, wList
	String defaultWavePrefix, defaultLabel = ""
	
	if ( NMParamsError( nm ) != 0 )
		return ""
	endif
	
	if ( ParamIsDefault( waveNum ) )
		waveNum = 0 // use first channel wave as default
	endif
	
	if ( waveNum == -1 )
		waveNum = NumVarOrDefault( nm.prefixFolder + "CurrentWave", 0 )
	endif
	
	numWaves = NumVarOrDefault( nm.prefixFolder + "NumWaves", 0 )
	
	if ( ( waveNum < 0 ) || ( waveNum >= numWaves ) )
		return ""
	endif

	defaultWavePrefix = StrVarOrDefault( nm.folder + "WavePrefix", "" )
	
	if ( ( strlen( defaultWavePrefix ) > 0 ) && StringMatch( nm.wavePrefix, defaultWavePrefix ) )
		defaultLabel = StrVarOrDefault( nm.folder + "xLabel", "" )
	endif
	
	wList = StrVarOrDefault( nm.prefixFolder + NMChanWaveListPrefix + ChanNum2Char( nm.chanNum ), "" )
	
	if ( ItemsInList( wList ) == 0 )
	
		xLabel = defaultLabel
		
	else
	
		wName = StringFromList( waveNum, wList )
		
		xLabel = NMNoteLabel( "x", nm.folder + wName, defaultLabel )
		
		if ( strlen( xLabel ) == 0 )
			xLabel = NMWaveUnits( "x", wName )
		endif
	
	endif
	
	if ( ( units == 1 ) && ( strlen( xLabel ) > 0 ) )
		return UnitsFromStr( xLabel )
	else
		return xLabel
	endif
	
End // NMChanLabelX2

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanLabelYAll( [ folder, wavePrefix, prefixFolder, units ] )
	String folder // NM data folder, pass nothing for current data folder
	String wavePrefix // pass nothing for current wave prefix
	String prefixFolder // prefix subfolder ( passing this parameter will usurp folder and wavePrefix )
	Variable units // pass 1 to convert label to units, e.g. "mV" or "pA"

	Variable ccnt, numChannels
	String shortName, yLabel, yLabelList = ""
	
	// BEGIN folder / wavePrefix / prefixFolder check
	
	if ( ParamIsDefault( prefixFolder ) )
	
		if ( ParamIsDefault( folder ) )
			folder = CurrentNMFolder( 1 )
		else
			folder = CheckNMFolderPath( folder )
		endif
		
		if ( !IsNMDataFolder( folder ) )
			return ""
		endif
		
		if ( ParamIsDefault( wavePrefix ) )
			wavePrefix = StrVarOrDefault( folder + "CurrentPrefix", "" )
		endif
		
		prefixFolder = NMPrefixFolderDF( folder,  wavePrefix )
		
		if ( strlen( prefixFolder ) == 0 )
			return ""
		endif
		
	else
	
		if ( strlen( prefixFolder ) == 0 )
			prefixFolder = CurrentNMPrefixFolder()
		else
			prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
		endif
		
		if ( strlen( prefixFolder ) == 0 )
			return ""
		endif
		
		prefixFolder = LastPathColon( prefixFolder, 1 )
	
	endif
	
	// END folder / wavePrefix / prefixFolder check
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	if ( numChannels <= 0 )
		return ""
	endif

	for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
		yLabel = NMChanLabelY( prefixFolder = prefixFolder, channel = ccnt, units = units )
		yLabelList = NMAddToList( yLabel, yLabelList, ";" )
	endfor
	
	if ( ItemsInList( yLabelList ) > 1 )
		return yLabelList
	else
		return StringFromList( 0, yLabelList )
	endif
	
End // NMChanLabelYAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanLabelY( [ folder, wavePrefix, prefixFolder, channel, waveNum, units ] )
	String folder // NM data folder, pass nothing for current data folder
	String wavePrefix // pass nothing for current wave prefix
	String prefixFolder // prefix subfolder ( passing this parameter will usurp folder and wavePrefix ) 
	Variable channel // channel number, pass nothing or -1 for current channel
	Variable waveNum // wave number, pass nothing or -1 for current wave
	Variable units // pass 1 to convert label to units, e.g. "mV" or "pA"
	
	Variable numChannels, numWaves
	String yLabel, strVarName, yName, wName, shortName, wList
	String defaultWavePrefix, defaultLabel = ""
	
	// BEGIN folder / wavePrefix / prefixFolder check
	
	if ( ParamIsDefault( prefixFolder ) )
	
		if ( ParamIsDefault( folder ) )
			folder = CurrentNMFolder( 1 )
		else
			folder = CheckNMFolderPath( folder )
		endif
		
		if ( !IsNMDataFolder( folder ) )
			return ""
		endif
		
		if ( ParamIsDefault( wavePrefix ) )
			wavePrefix = StrVarOrDefault( folder + "CurrentPrefix", "" )
		endif
		
		prefixFolder = NMPrefixFolderDF( folder,  wavePrefix )
		
		if ( strlen( prefixFolder ) == 0 )
			return ""
		endif
		
	else
	
		if ( strlen( prefixFolder ) == 0 )
			prefixFolder = CurrentNMPrefixFolder()
		else
			prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
		endif
		
		if ( strlen( prefixFolder ) == 0 )
			return ""
		endif
		
		prefixFolder = LastPathColon( prefixFolder, 1 )
	
		folder = NMParent( prefixFolder )
		shortName = NMChild( prefixFolder )
		
		if ( strsearch( shortName, NMPrefixSubfolderPrefix, 0 ) != 0 )
			return "" // this is not a NM prefix subfolder
		endif
		
		wavePrefix = ReplaceString( NMPrefixSubfolderPrefix, shortName, "" )
		
		if ( strlen( wavePrefix ) == 0 )
			return "" // something is wrong
		endif
	
	endif
	
	// END folder / wavePrefix / prefixFolder check
	
	// BEGIN chan / waveNum check
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	numWaves = NumVarOrDefault( prefixFolder + "NumWaves", 0 )
	
	if ( ( ParamIsDefault( channel ) ) || ( channel == -1 ) )
		channel = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	endif
	
	if ( ( channel < 0 ) || ( channel >= numChannels ) )
		return ""
	endif
	
	if ( ParamIsDefault( waveNum ) )
		waveNum = 0 // use first channel wave as default
	endif
	
	if ( waveNum == -1 )
		waveNum = NumVarOrDefault( prefixFolder + "CurrentWave", 0 )
	endif
	
	if ( ( waveNum < 0 ) || ( waveNum >= numWaves ) )
		return ""
	endif
	
	// END chan / waveNum check
	
	defaultWavePrefix = StrVarOrDefault( folder + "WavePrefix", "" )
	
	if ( ( strlen( defaultWavePrefix ) > 0 ) && StringMatch( wavePrefix, defaultWavePrefix ) )
	
		yName = folder + "yLabel"
		
		if ( WaveExists( $yName ) && ( channel < numpnts( $yName ) ) )
		
			Wave /T ytemp = $yName
				
			defaultLabel = ytemp[ channel ]
			
		endif
		
	endif
	
	wList = StrVarOrDefault( prefixFolder + NMChanWaveListPrefix + ChanNum2Char( channel ), "" )
	
	if ( ItemsInList( wList ) == 0 )
	
		yLabel = defaultLabel
		
	else
	
		wName = StringFromList( waveNum, wList )
		
		yLabel = NMNoteLabel( "y", folder  + wName, defaultLabel )
		
		if ( strlen( yLabel ) == 0 )
			yLabel = NMWaveUnits( "y", wName )
		endif
	
	endif
	
	if ( ( units == 1 ) && ( strlen( yLabel ) > 0 ) )
		return UnitsFromStr( yLabel )
	else
		return yLabel
	endif
	
End // NMChanLabelY

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanLabel( channel, xySelect, wList [ prefixFolder ] )
	Variable channel // ( -1 ) for current channel
	String xySelect // "x" or "y"
	String wList // ( "" ) for current channel wave list
	String prefixFolder
	
	String parent, wName, xyLabel, defaultStr = ""
	String yName, wavePrefix, currentPrefix, xWave
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	parent = NMParent( prefixFolder )
	
	xWave = NMXwave( prefixFolder = prefixFolder, waveNum = 0 )
	
	if ( StringMatch( xySelect, "x" ) && WaveExists( $xWave ) )
	
		xyLabel = NMNoteLabel( "y", xWave, "" )
		
		if ( strlen( xyLabel ) > 0 )
			return xyLabel
		endif
		
	endif
	
	yName = parent + "yLabel"
	wavePrefix = StrVarOrDefault( parent + "WavePrefix", "" ) // old NM string variable
	currentPrefix = StrVarOrDefault( parent + "CurrentPrefix", "" )
	
	if ( channel == -1 )
		channel = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	endif
	
	if ( ItemsInList( wList ) == 0 )
		wList = NMChanWaveList( channel, prefixFolder = prefixFolder )
	endif
	
	strswitch( xySelect )
	
		case "x":
			defaultStr = NMChanLabelX( channel = channel, prefixFolder = prefixFolder )
			break
			
		case "y":
			defaultStr = NMChanLabelY( channel = channel, prefixFolder = prefixFolder )
			break
			
		default:
			return ""
			
	endswitch
	
	wName = StringFromList( 0, wList ) // return first instance
	
	xyLabel = NMNoteLabel( xySelect, wName, defaultStr )
	
	if ( strlen( xyLabel ) > 0 )
		return xyLabel
	endif
	
	xyLabel = NMWaveUnits( xySelect, wName )

	return xyLabel
	
End // NMChanLabel

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanLabelList( channel, xySelect, wList [ prefixFolder ] )
	Variable channel // ( -1 ) for current channel
	String xySelect // "x" or "y"
	String wList // ( "" ) for current channel wave list
	String prefixFolder
	
	String labelList
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	if ( channel == -1 )
		channel = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	endif
	
	if ( ItemsInList( wList ) == 0 )
		wList = NMChanWaveList( channel, prefixFolder = prefixFolder )
	endif
	
	labelList = NMNoteLabelList( xySelect, wList )
	
	if ( strlen( labelList ) > 0 )
		return labelList
	endif
	
	return NMWaveUnitsList( xySelect, wList )
	
End // NMChanLabelList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPromptAddUnitsX( promptStr [ hz ] )
	String promptStr
	Variable hz
	
	String xunits = NMChanLabelX( units = 1 )
	
	if ( strlen( xunits ) > 0 )
	
		strswitch( xunits )
		
			case "usec":
			case "microseconds":
				xunits = "us"
				break
		
			case "msec":
			case "milliseconds":
				xunits = "ms"
				break
				
			case "sec":
			case "seconds":
				xunits = "s"
				break
				
		endswitch
		
		if ( hz )
		
			strswitch( xunits )
			
				case "us":
					xunits = "MHz"
					break
		
				case "ms":
					xunits = "kHz"
					break
					
				case "s":
					xunits = "Hz"
					break
				
			endswitch
		
		endif
		
		return promptStr + " (" + xunits + "):"
		
	endif
	
	return promptStr + ":"

End // NMPromptAddUnitsX

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPromptAddUnitsY( promptStr )
	String promptStr

	String yunits = NMChanLabelY( units = 1 )
	
	if ( strlen( yunits ) > 0 )
		return promptStr + " (" + yunits + "):"
	endif
	
	return promptStr + ":"

End // NMPromptAddUnitsY

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanLabelSetCall( channel, xySelect, labelStr )
	Variable channel
	String xySelect // "x" or "y"
	String labelStr
	
	Variable waveSelect = 2
	
	return NMChanLabelSet( channel, waveSelect, xySelect, labelStr, history = 1 )
	
End // NMChanLabelSetCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanLabelSet( channel, waveSelect, xySelect, labelStr [ prefixFolder, update, history ] )
	Variable channel // ( -1 ) for current channel ( -2 ) for all channels
	Variable waveSelect // ( 1 ) selected waves ( 2 ) all channel waves
	String xySelect // "x" or "y"
	String labelStr
	String prefixFolder
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable wcnt, ccnt, cbgn, cend, numChannels
	String wName, wList, vlist = ""
	
	vList = NMCmdNum( channel, vList, integer = 1 )
	vList = NMCmdNum( waveSelect, vList, integer = 1 )
	vList = NMCmdStr( xySelect, vList )
	vList = NMCmdStr( labelStr , vList )
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		vlist = NMCmdStrOptional( "prefixFolder", prefixFolder, vlist )
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( numtype( channel ) > 0 )
		return NM2Error( 10, "channel", num2str( channel ) )
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	if ( channel == -1 )
		cbgn = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
		cend = cbgn
	elseif ( channel == -2 )
		cbgn = 0
		cend = numChannels - 1
	elseif ( ( channel >= 0 ) && ( channel < numChannels ) )
		cbgn = channel
		cend = channel
	else
		//return NM2Error( 10, "channel", num2str( channel ) )
		return -1
	endif
	
	labelStr = StringFromList( 0, labelStr )
	
	for ( ccnt = cbgn ; ccnt <= cend ; ccnt += 1 )
	
		switch( waveSelect )
		
			case 1:
				wList = NMWaveSelectList( ccnt, prefixFolder = prefixFolder )
				break
				
			case 2:
				wList = NMChanWaveList( ccnt, prefixFolder = prefixFolder )
				break
				
			default:
				return NM2Error( 10, "waveSelect", num2istr( waveSelect ) )
				
		endswitch
		
		for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
		
			wName = StringFromList( wcnt, wList )
			
			strswitch( xySelect )
			
				case "x":
				case "y":
					NMNoteStrReplace( wName, xySelect+"Label", labelStr )
					RemoveWaveUnits( wName )
					break
					
				default:
					return NM2Error( 20, "xySelect", xySelect )
			
			endswitch
		
		endfor
		
	endfor
	
	if ( update )
		ChanGraphsUpdate()
		UpdateNMPanel( 1 )
	endif
	
	return 0

End // NMChanLabelSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanXLabelSetAll( xLabel [ prefixFolder, update, history ] )
	String xLabel
	String prefixFolder
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	String vList = NMCmdStr( xLabel, "" )
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		vlist = NMCmdStrOptional( "prefixFolder", prefixFolder, vlist )
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	return NMChanLabelSet( -2, 2, "x", xLabel, prefixFolder = prefixFolder, update = update ) // all channels and all waves
	
End // NMChanXLabelSetAll

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanUnits2Labels( [ prefixFolder, update ] )
	String prefixFolder
	Variable update
	
	Variable ccnt, numChannels, numWaves
	String wName, s, x, y
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	numWaves = NumVarOrDefault( prefixFolder + "NumWaves", 0 )
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	if ( numWaves <= 0 )
		return 0
	endif
	
	for ( ccnt = 0; ccnt < numChannels; ccnt += 1 ) // loop thru channels
		
		wName = NMChanWaveName( ccnt, 0, prefixFolder = prefixFolder )
		
		s = WaveInfo( $wName, 0 )
		x = StringByKey( "XUNITS", s )
		y = StringByKey( "DUNITS", s )
		
		if ( strlen( x ) > 0 )
			NMChanLabelSet( ccnt, 2, "x", x, prefixFolder = prefixFolder, update = update )
		endif
		
		if ( strlen( y ) > 0 )
			NMChanLabelSet( ccnt, 2, "y", y, prefixFolder = prefixFolder, update = update )
		endif

	endfor
	
	return 0

End // NMChanUnits2Labels

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Channel Select Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMChanSelect( [ prefixFolder ] )
	String prefixFolder
	
	Variable ccnt
	String wName, chanList = ""
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif
	
	wName = prefixFolder + "ChanSelect"
	
	if ( WaveExists( $wName ) )
		
		Wave wtemp = $wName

		for ( ccnt = 0 ; ccnt < numpnts( wtemp ) ; ccnt += 1 )
		
			if ( wtemp[ ccnt ] == 1 )
				chanList = AddListItem( num2istr( ccnt ), chanList, ";", inf )
			endif
		
		endfor
		
		KillWaves /Z $wName
		
	endif
	
	if ( ItemsInList( chanList ) == 0 )
	
		chanList = StrVarOrDefault( prefixFolder + NMChanSelectVarName, "" )
		
		if ( ItemsInList( chanList ) == 0 )
			chanList = "0;"
		else
			return 0
		endif
	
	endif
	
	SetNMstr( prefixFolder + NMChanSelectVarName, chanList )

End // CheckNMChanSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanSelectCharList( [ prefixFolder ] )
	String prefixFolder

	Variable ccnt, channel
	String chanList, charList = ""
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif

	chanList = StrVarOrDefault( prefixFolder + NMChanSelectVarName, "" )
	
	for ( ccnt = 0 ; ccnt < ItemsInList( chanList ) ; ccnt += 1 )
		channel = str2num ( StringFromList( ccnt, chanList ) )
		charList = AddListItem( ChanNum2Char( channel ) , charList, ";", inf )
	endfor
	
	return charList
	
End // NMChanSelectCharList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanSelect( chanStr [ prefixFolder, update ] ) // set current channel
	String chanStr // "A" or "B" or "C" or "All" or "0" or "1" or "2" or ( "" ) for current channel
	String prefixFolder
	Variable update
	
	Variable chan, currentChan
	String chanCharList, chanNumList, chanList = ""
	
	chanStr = StringFromList( 0, chanStr )
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return NaN
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	chanCharList = NMChanList( "CHAR", prefixFolder = prefixFolder )
	chanNumList = NMChanList( "NUM", prefixFolder = prefixFolder )
	
	if ( StringMatch( chanStr, "All" ) )
	
		chanList = chanNumList
		
	elseif ( strlen( chanStr ) == 0 )
	
		currentChan = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	
		chanList = AddListItem( num2istr( currentChan ), "", ";", inf )
		
	elseif ( WhichListItem( chanStr, chanCharList ) >= 0 )
	
		chan = ChanChar2Num( chanStr )
		chanList = AddListItem( num2istr( chan ), "", ";", inf )
	
	elseif ( WhichListItem( chanStr, chanNumList ) >= 0 )
	
		chanList = AddListItem( chanStr, "", ";", inf )
		
	else
	
		NMDoAlert( "NMChanSelect Error: channel is out of range: " + chanStr )
		return Nan
		
	endif
	
	if ( ItemsInList( chanList ) == 0 )
		return Nan
	endif
	
	return NMChanSelectListSet( chanList, prefixFolder = prefixFolder, update = update )

End // NMChanSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanSelectListSet( chanList [ prefixFolder, update ] )
	String chanList // e.g. "0" or "0;1;2" or "0;2"
	String prefixFolder
	Variable update
	
	Variable ccnt, chan, numChannels
	String chanStr, chanNumList
	
	String TabList = NMTabControlList()
	
	Variable currentTab = NMVarGet( "CurrentTab" )
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return NaN
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	chanNumList = NMChanList( "NUM", prefixFolder = prefixFolder )
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	if ( ( numChannels <= 0 ) || ( ItemsInList( chanList ) == 0 ) )
		return Nan
	endif
	
	for ( ccnt = 0 ; ccnt < ItemsInList( chanList ) ; ccnt += 1 )
	
		chanStr = StringFromList( ccnt, chanList )
	
		if ( WhichListItem( chanStr , chanNumList ) < 0 )
			NMDoAlert( "Abort NMChanSelectListSet: channel is out of range: " + chanStr )
			return Nan
		endif
		
	endfor
	
	chan = str2num( StringFromList( 0, chanList ) )
	
	SetNMvar( prefixFolder + "CurrentChan", chan )
	SetNMstr( prefixFolder + NMChanSelectVarName, chanList )
	
	if ( update )
	
		NMWaveSelectListMaster( prefixFolder = prefixFolder, updateNM = 1 )
		//UpdateNMPanelChannelSelect()
	
		UpdateNMPanel( 1 )
		
	endif
	
	return chan

End // NMChanSelectListSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanSelectListEdit()

	Variable ccnt, channel
	
	String chanNumList = ""
	String chanCharList = NMChanSelectCharList()
	
	Prompt chanCharList, " "
	DoPrompt "Edit Channel Select List", chanCharList
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	for ( ccnt = 0 ; ccnt < ItemsInList( chanCharList ) ; ccnt += 1 )
		channel = ChanChar2Num( StringFromList( ccnt, chanCharList ) )
		chanNumList = AddListItem( num2istr( channel ) , chanNumList, ";", inf )
	endfor
	
	if ( ItemsInList( chanNumList ) == 0 )
		return -1
	endif
	
	return NMChanSelectListSet( chanNumList )

End // NMChanSelectListEdit

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanSelected( channel [ prefixFolder ] )
	Variable channel
	String prefixFolder
	
	String chanList
	
	if ( ( numtype( channel ) > 0 )|| ( channel < 0 ) )
		return 0
	endif
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif
	
	chanList = StrVarOrDefault( prefixFolder + NMChanSelectVarName, "" )
	
	if ( ItemsInList( chanList ) == 0 )
		return 0
	endif
	
	if ( WhichListItem( num2istr( channel ) , chanList ) >= 0 )
		return 1
	endif
	
	return 0
	
End // NMChanSelected

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanSelectedAll( [ prefixFolder ] )
	String prefixFolder

	Variable ccnt, numChannels
	String chanList

	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif
	
	chanList = StrVarOrDefault( prefixFolder + NMChanSelectVarName, "" )
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
	
		if ( WhichListItem( num2istr( ccnt ) , chanList ) < 0 )
			return 0
		endif
		
	endfor
	
	return 1

End // NMChanSelectedAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanSelectAllList( [ prefixFolder ] ) // return a list of channels if more than one is selected
	String prefixFolder
	
	String chanList
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	chanList = NMChanSelectCharList( prefixFolder = prefixFolder )
	
	if ( ItemsInList( chanList ) <= 1 )
		return ""
	endif
	
	return chanList

End // NMChanSelectAllList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanSelectStr( [ prefixFolder ] )
	String prefixFolder
	
	Variable numChannels, currentChan
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	if ( ( numChannels > 1 ) && NMChanSelectedAll( prefixFolder = prefixFolder ) )
		return "All"
	endif
	
	currentChan = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	
	return ChanNum2Char( currentChan )

End // NMChanSelectStr

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Wave Select Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMWaveSelect( [ prefixFolder ] )
	String prefixFolder

	String wName, waveSelect = ""
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	wName = prefixFolder + "WavSelect"
	
	if ( WaveExists( $wName ) )
	
		waveSelect = note( $wName )
		
		KillWaves /Z $wName
		
	endif
	
	if ( strlen( waveSelect ) == 0 )
	
		waveSelect = StrVarOrDefault( prefixFolder + "WaveSelect", "" )
		
		if ( strlen( waveSelect ) == 0 )
			waveSelect = "All"
		else
			return 0
		endif
		
	endif
	
	SetNMstr( prefixFolder + "WaveSelect", waveSelect )
	
	NMWaveSelectListMaster( prefixFolder = prefixFolder, updateNM = 1 )
	
	return 0
	
End // CheckNMWaveSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMWaveSelectGet( [ prefixFolder ] )
	String prefixFolder

	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	return StrVarOrDefault( prefixFolder + "WaveSelect", "" )

End // NMWaveSelectGet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWaveSelectCall( waveSelect )
	String waveSelect // wave select function (e.g. "All" or "Set1" or "Group1")
	
	Variable grpNum, error, andor, history = 1
	String sname, sname2, wavList, grp, grpList, setList
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	strswitch( waveSelect )
	
		case "Clear List":
		
			DoAlert 1, "Are you sure you want to clear the Wave Select history?"
			
			if ( V_flag == 1 )
				NMWaveSelectClear( history = 1 )
			endif
			
			return 0
			
		case "Set x Set":
		
			setList = NMSetsList()
			
			if ( ItemsInList( setList ) == 0 )
				error = 1
				break
			endif
	
			sname = StringFromList( 0, setList )
			sname2 = StringFromList( 1, setList )
			
			Prompt sname, " ", popup setList
			Prompt andor, " ", popup "AND;OR"
			Prompt sname2, " ", popup setList
			DoPrompt "Set x Set", sname, andor, sname2
	
			if (V_flag == 1)
				error = 1
				break
			endif
			
			waveSelect = sname
			
			if (andor == 1)
				waveSelect += " x "
			else
				waveSelect += " + "
			endif
			
			waveSelect += sname2
			
			break
			
		case "Set x Group":
		
			grpList = NMGroupsList(1)
			grp = StringFromList( 0, grpList )
			
			if ( ItemsInList( grpList ) == 0 )
				error = 1
				break
			endif
	
			sname = StringFromList(0, NMSetsList())
			
			Prompt sname, " ", popup NMSetsList()
			Prompt andor, " ", popup "AND;OR"
			Prompt grp, " ", popup "All Groups;" + grpList
			DoPrompt "Set x Group", sname, andor, grp
	
			if (V_flag == 1)
				error = 1
				break
			endif
			
			waveSelect = sname
			
			if (andor == 1)
				waveSelect += " x "
			else
				waveSelect += " + "
			endif
			
			waveSelect += grp
			
			break
		
	endswitch
	
	if ( error ) // set to "All"
		waveSelect = "All"
	endif
	
	return NMSet( waveSelect = waveSelect, prefixFolder = "", history = 1 )

End // NMWaveSelectCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWaveSelectAdd( waveSelect )
	String waveSelect
	
	String addedList = NMStrGet( "WaveSelectAdded" )
	
	addedList = NMAddToList( waveSelect, addedList, ";" )
	
	SetNMstr( NMDF+"WaveSelectAdded", addedList )
	
End // NMWaveSelectAdd

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWaveSelectClear( [ update, history ] )
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	String vlist = ""

	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif

	SetNMstr( NMDF+"WaveSelectAdded", "" )
	
	if ( update )
		UpdateNMPanelWaveSelect()
	endif

End // NMWaveSelectClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWaveSelect( waveSelect [ prefixFolder, update ] )
	String waveSelect // wave select function (e.g. "All" or "Set1" or "Group1")
	String prefixFolder
	Variable update
	
	String saveWaveSelect, ok
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return NaN
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	saveWaveSelect = StrVarOrDefault( prefixFolder + "WaveSelect", "All" )
	
	if ( ( strlen( waveSelect ) == 0 ) || StringMatch( waveSelect, "Update" ) )
		waveSelect = StrVarOrDefault( prefixFolder + "WaveSelect", "" )
	else
		SetNMstr( prefixFolder + "WaveSelect", waveSelect )
	endif
	
	ok = NMWaveSelectListMaster( prefixFolder = prefixFolder, updateNM = 1 )
	
	if ( !StringMatch( ok, "OK" ) )
		SetNMstr( prefixFolder+"WaveSelect", saveWaveSelect ) // something went wrong
		NMDoAlert( "Abort NMWaveSelect: bad wave selection: " + waveSelect )
	endif
	
	if ( update )
		UpdateNMPanel(1 )
		//UpdateNMPanelWaveSelect()
		//NMAutoTabCall()
	endif
	
	return 0

End // NMWaveSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMWaveSelectListMaster( [ prefixFolder, chanNum, waveSelect, updateNM, fullPath ] )
	String prefixFolder
	Variable chanNum
	String waveSelect
	Variable updateNM
	Variable fullPath

	Variable ccnt, cbgn, cend, icnt, OK, numChannels, currentWave
	Variable grpNum = Nan, and = -1, or = -1
	String strVarName, strVarList, wList, swList, swList2, gwList
	String chanList, setName, setName2, grpList, setList
	String folder = ""
	
	Variable grpsOn = NMVarGet( "GroupsOn" )
	Variable setXclude = NMSetXType()

	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	currentWave = NumVarOrDefault( prefixFolder + "CurrentWave", 0 )
	
	if ( ParamIsDefault( chanNum ) )
		cbgn = CurrentNMChannel()
		cend = cbgn
	elseif ( ( chanNum >= 0 ) && ( chanNum < numChannels ) )
		cbgn = chanNum
		cend = chanNum
	else
		return ""
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = StrVarOrDefault( prefixFolder + "WaveSelect", "NONE" )
	endif
	
	if ( updateNM )
		cbgn = 0
		cend = numChannels - 1
		fullPath = 0
	else
		grpsOn = 1 // accept Groups
	endif
	
	setList = NMSetsList( prefixFolder = prefixFolder )
	
	waveSelect = ReplaceString( " & ", waveSelect, " x " )
	waveSelect = ReplaceString( " && ", waveSelect, " x " )
	waveSelect = ReplaceString( " | ", waveSelect, " + " )
	waveSelect = ReplaceString( " || ", waveSelect, " + " )
	
	and = strsearch( waveSelect, " x ", 0 )
	or = strsearch( waveSelect, " + ", 0 )
	
	if ( grpsOn )
		grpNum = NMGroupsNumFromStr( waveSelect )
	endif
	
	if ( updateNM )
		NMPrefixFolderStrVarKill( NMWaveSelectVarName, prefixFolder = prefixFolder )
	endif
	
	if ( fullPath )
		folder = NMParent( prefixFolder )
	endif
	
	if ( StringMatch( waveSelect, "This Wave" ) )
	
		for ( ccnt = cbgn ; ccnt <= cend ; ccnt += 1 )
		
			if ( updateNM && !NMChanSelected( ccnt, prefixFolder = prefixFolder ) )
				continue
			endif
			
			wList = NMChanWaveName( ccnt, currentWave, prefixFolder = prefixFolder ) + ";"
			wList = NMSetXcludeWaveList( wList, ccnt, prefixFolder = prefixFolder )
			strVarName = prefixFolder + NMWaveSelectVarName + ChanNum2Char( ccnt )
			
			if ( updateNM )
				SetNMstr( strVarName, wList )
			else
				if ( fullPath )
					return NMWaveListAddPath( folder, wList, ";" )
				else
					return wList
				endif
			endif

		endfor
		
		OK = 1
	
	elseif ( StringMatch( waveSelect, "All" ) )
		
		for ( ccnt = cbgn ; ccnt <= cend ; ccnt += 1 )
		
			if ( updateNM && !NMChanSelected( ccnt, prefixFolder = prefixFolder ) )
				continue
			endif
			
			wList = NMChanWaveList( ccnt, prefixFolder = prefixFolder )
			wList = NMSetXcludeWaveList( wList, ccnt, prefixFolder = prefixFolder )
			strVarName = prefixFolder + NMWaveSelectVarName + ChanNum2Char( ccnt )
			
			if ( updateNM )
				SetNMstr( strVarName, wList )
			else
				if ( fullPath )
					return NMWaveListAddPath( folder, wList, ";" )
				else
					return wList
				endif
			endif
			
		endfor
		
		OK = 1
		
	elseif ( StringMatch( waveSelect, "All+" ) ) // all including SetX
		
		for ( ccnt = cbgn ; ccnt <= cend ; ccnt += 1 )
		
			if ( updateNM && !NMChanSelected( ccnt, prefixFolder = prefixFolder ) )
				continue
			endif
			
			wList = NMChanWaveList( ccnt, prefixFolder = prefixFolder )
			//wList = NMSetXcludeWaveList( wList, ccnt, prefixFolder = prefixFolder )
			strVarName = prefixFolder + NMWaveSelectVarName + ChanNum2Char( ccnt )
			
			if ( updateNM )
				SetNMstr( strVarName, wList )
			else
				if ( fullPath )
					return NMWaveListAddPath( folder, wList, ";" )
				else
					return wList
				endif
			endif
			
		endfor
		
		OK = 1
		
	elseif ( WhichListItem( waveSelect, setList ) >= 0 )
	
		for ( ccnt = cbgn ; ccnt <= cend ; ccnt += 1 )
			
			if ( updateNM && !NMChanSelected( ccnt, prefixFolder = prefixFolder ) )
				continue
			endif
			
			swList = NMSetsWaveList( waveSelect, ccnt )
			
			if ( !StringMatch( waveSelect, "SetX" ) )
				swList = NMSetXcludeWaveList( swList, ccnt, prefixFolder = prefixFolder )
			endif
			
			strVarName = prefixFolder + NMWaveSelectVarName + ChanNum2Char( ccnt )
			
			if ( updateNM )
				SetNMstr( strVarName, swList )
			else
				if ( fullPath )
					return NMWaveListAddPath( folder, swList, ";" )
				else
					return swList
				endif
			endif
			
		endfor
		
		OK = 1
	
	elseif ( StringMatch( waveSelect, "All Sets") )
		
		if ( setXclude )
			setList = RemoveFromList( "SetX", setList )
		endif
	
		for ( ccnt = cbgn ; ccnt <= cend ; ccnt += 1 )
		
			if ( updateNM && !NMChanSelected( ccnt, prefixFolder = prefixFolder ) )
				continue
			endif
		
			swList = ""
		
			for ( icnt = 0 ; icnt < ItemsInList( setList ) ; icnt += 1 )
				setName = StringFromList( icnt, setList )
				swList = NMAddToList( NMSetsWaveList( setName, ccnt ) , swList, ";" )
			endfor
			
			swList = NMSetXcludeWaveList( swList, ccnt, prefixFolder = prefixFolder )
			swList = OrderToNMChanWaveList( swList, ccnt, prefixFolder = prefixFolder )
			
			strVarName = prefixFolder + NMWaveSelectVarName + ChanNum2Char( ccnt )
			
			if ( updateNM )
				SetNMstr( strVarName, swList )
			else
				if ( fullPath )
					return NMWaveListAddPath( folder, swList, ";" )
				else
					return swList
				endif
			endif
			
		endfor
		
		OK = 1
		
	elseif ( !grpsOn && StringMatch( waveSelect, "*Group*" ) )
	
		// error, nothing to do
		
	elseif ( grpsOn && StringMatch( waveSelect[0,4], "Group" ) )
	
		for ( ccnt = cbgn ; ccnt <= cend ; ccnt += 1 )
		
			if ( updateNM && !NMChanSelected( ccnt, prefixFolder = prefixFolder ) )
				continue
			endif
			
			gwList = NMGroupsWaveList( grpNum, ccnt )
			gwList = NMSetXcludeWaveList( gwList, ccnt, prefixFolder = prefixFolder )
			
			strVarName = prefixFolder + NMWaveSelectVarName + ChanNum2Char( ccnt )
			
			if ( updateNM )
				SetNMstr( strVarName, gwList )
			else
				if ( fullPath )
					return NMWaveListAddPath( folder, gwList, ";" )
				else
					return gwList
				endif
			endif
			
		endfor
		
		OK = 1
		
	elseif ( grpsOn && StringMatch( waveSelect, "All Groups" ) )
	
		grpList = NMGroupsList( 0 )
		
		for ( ccnt = cbgn ; ccnt <= cend ; ccnt += 1 )
		
			if ( updateNM && !NMChanSelected( ccnt, prefixFolder = prefixFolder ) )
				continue
			endif
		
			gwList = ""
		
			for ( icnt = 0 ; icnt < ItemsInList( grpList ) ; icnt += 1 )
			
				grpNum = str2num( StringFromList( icnt, grpList ) )
				
				if ( numtype( grpNum ) > 0 )
					continue
				endif
				
				gwList = NMAddToList( NMGroupsWaveList( grpNum, ccnt ), gwList, ";" )
				
			endfor
			
			gwList = NMSetXcludeWaveList( gwList, ccnt, prefixFolder = prefixFolder )
			gwList = OrderToNMChanWaveList( gwList, ccnt, prefixFolder = prefixFolder )
			
			strVarName = prefixFolder + NMWaveSelectVarName + ChanNum2Char( ccnt )
			
			if ( updateNM )
				SetNMstr( strVarName, gwList )
			else
				if ( fullPath )
					return NMWaveListAddPath( folder, gwList, ";" )
				else
					return gwList
				endif
			endif
			
		endfor
		
		OK = 1
		
	elseif ( grpsOn && ( strsearch( waveSelect, "Group", 0, 2 ) > 0 ) && ( ( and > 0 ) || ( or > 0 ) ) ) // Set && Group, Set || Group
	
		if ( and > 0 )
			setName = waveSelect[0, and-1]
		elseif ( or > 0 )
			setName = waveSelect[0, or-1]
		endif
		
		setName = ReplaceString( " ", setName, "" )
		
		grpList = ""
	
		if ( numtype( grpNum ) == 0 )
		
			grpList = num2istr( grpNum )
			
		elseif ( strsearch( waveSelect, "All Groups", 0, 2 ) > 0 )
		
			grpList = NMGroupsList( 0 )
			
		endif
		
		for ( ccnt = cbgn ; ccnt <= cend ; ccnt += 1 )
		
			if ( updateNM && !NMChanSelected( ccnt, prefixFolder = prefixFolder ) )
				continue
			endif
			
			wList = ""
			swList = NMSetsWaveList( setName, ccnt )
		
			for ( icnt = 0 ; icnt < ItemsInList( grpList ) ; icnt += 1 )
			
				grpNum = str2num( StringFromList( icnt, grpList ) )
				
				if ( numtype( grpNum ) > 0 )
					continue
				endif
				
				gwList = NMGroupsWaveList( grpNum, ccnt )
				
				if ( and > 0 )
					gwList = NMAndLists( swList, gwList, ";" )
				elseif ( or > 0 )
					gwList = NMAddToList( swList, gwList, ";" )
				endif
				
				wList = NMAddToList( gwList, wList, ";" )
				
			endfor
			
			wList = NMSetXcludeWaveList( wList, ccnt, prefixFolder = prefixFolder )
			wList = OrderToNMChanWaveList( wList, ccnt, prefixFolder = prefixFolder )
			
			strVarName = prefixFolder + NMWaveSelectVarName + ChanNum2Char( ccnt )
			
			if ( updateNM )
				SetNMstr( strVarName, wList )
			else
				if ( fullPath )
					return NMWaveListAddPath( folder, wList, ";" )
				else
					return wList
				endif
			endif
			
		endfor
		
		if ( updateNM )
			NMWaveSelectAdd( waveSelect )
		endif
		
		OK = 1
		
	elseif ( ( and > 0 ) || ( or > 0 ) ) // Set && Set, Set || Set
	
		if ( and > 0 )
			setName = waveSelect[0, and-1]
			setName2 = waveSelect[and+3, inf]
		elseif ( or > 0 )
			setName = waveSelect[0, or-1]
			setName2 = waveSelect[or+3, inf]
		endif
		
		setName = ReplaceString( " ", setName, "" )
		setName2 = ReplaceString( " ", setName2, "" )
		
		for ( ccnt = cbgn ; ccnt <= cend ; ccnt += 1 )
		
			if ( updateNM && !NMChanSelected( ccnt, prefixFolder = prefixFolder ) )
				continue
			endif
			
			wList = ""
			swList = NMSetsWaveList( setName, ccnt )
			swList2 = NMSetsWaveList( setName2, ccnt )
				
			if ( and > 0 )
				swList2 = NMAndLists( swList, swList2, ";" )
			elseif ( or > 0 )
				swList2 = NMAddToList( swList, swList2, ";" )
			endif
			
			wList = NMAddToList( swList2, wList, ";" )
			
			wList = NMSetXcludeWaveList( wList, ccnt, prefixFolder = prefixFolder )
			wList = OrderToNMChanWaveList( wList, ccnt, prefixFolder = prefixFolder )
			
			strVarName = prefixFolder + NMWaveSelectVarName + ChanNum2Char( ccnt )
			
			if ( updateNM )
				SetNMstr( strVarName, wList )
			else
				if ( fullPath )
					return NMWaveListAddPath( folder, wList, ";" )
				else
					return wList
				endif
			endif
			
		endfor
		
		if ( updateNM )
			NMWaveSelectAdd( waveSelect )
		endif
		
		OK = 1
		
	endif
	
	if ( updateNM && OK )
		UpdateNMWaveSelectCount( prefixFolder = prefixFolder )
	endif
	
	if ( updateNM )
		NMPrefixFolderGetOldGlobals()
	endif
	
	if ( OK )
		return "OK"
	else
		return ""
	endif
	
End // NMWaveSelectListMaster

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMWaveSelectCount( [ prefixFolder, update ] )
	String prefixFolder
	Variable update

	Variable ccnt, count, numChannels
	String wList, strVarName
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return NaN
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )

		if ( NMChanSelected( ccnt, prefixFolder = prefixFolder ) )
			strVarName = prefixFolder + NMWaveSelectVarName + ChanNum2Char( ccnt )
			wList = StrVarOrDefault( strVarName, "" )
			count += ItemsInList( wList )
		endif
		
	endfor
	
	SetNMvar( prefixFolder + "NumActiveWaves", count )
	
	if ( update )
		SetNMvar( NMDF + "NumActiveWaves", count ) // for NM Panel
	endif
	
	return count

End // UpdateNMWaveSelectCount

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMWaveSelectListAllChannels( [ prefixFolder ] )
	String prefixFolder
	
	Variable ccnt, numChannels
	String waveSelectList = ""
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )

	for ( ccnt = 0; ccnt < numChannels; ccnt += 1 ) // loop thru channels
	
		if ( !NMChanSelected( ccnt, prefixFolder = prefixFolder ) )
			continue // channel not selected
		endif
		
		waveSelectList += NMWaveSelectList( ccnt, prefixFolder = prefixFolder )
		
	endfor

	return waveSelectList
	
End // NMWaveSelectListAllChannels

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMWaveSelectList( channel [ prefixFolder ] ) // returns a list of all currently selected waves in a channel
	Variable channel // ( -1 ) for currently selected channel ( -2 ) for all channels
	String prefixFolder
	
	Variable ccnt, cbgn, cend, numChannels
	String strVarName, wList = ""
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	if ( channel == -1 )
		cbgn = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
		cend = cbgn
	elseif ( channel == -2 )
		cbgn = 0
		cend = numChannels - 1
	elseif ( ( channel >= 0 ) && ( channel < numChannels ) )
		cbgn = channel
		cend = channel
	else
		//return NM2ErrorStr( 10, "channel", num2str( channel ) )
		return ""
	endif
	
	//NMWaveSelectListMaster( prefixFolder = prefixFolder, updateNM = 1 ) // removed 14 Nov 2013 since it causes infinite loop with NMPrefixFolderGetOldGlobals
	
	for ( ccnt = cbgn ; ccnt <= cend ; ccnt += 1 )
		strVarName = prefixFolder + NMWaveSelectVarName + ChanNum2Char( ccnt )
		wList += StrVarOrDefault( strVarName , "" )
	endfor
	
	return wList

End // NMWaveSelectList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWaveSelectCount( channel [ prefixFolder ] ) // count number of currently active waves in a channel
	Variable channel
	String prefixFolder
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif

	return ItemsInList( NMWaveSelectList( channel, prefixFolder = prefixFolder ) )

End // NMWaveSelectCount

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMWaveSelected( channel, waveNum [ prefixFolder ] ) // return wave name if it is currently selected
	Variable channel // ( -1 ) for current channel
	Variable waveNum // wave number or ( -1 ) for current
	String prefixFolder
	
	Variable currentChan, currentWave
	String wName, wList, waveSelect
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	currentChan = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	currentWave = NumVarOrDefault( prefixFolder + "CurrentWave", 0 )
	
	if ( channel < 0 )
		channel = currentChan
	endif
	
	if ( waveNum < 0 )
		waveNum = currentWave
	endif
	
	if ( !NMChanSelected( channel, prefixFolder = prefixFolder ) )
		return ""
	endif
	
	wName = NMChanWaveName( channel, waveNum, prefixFolder = prefixFolder )
	
	waveSelect = StrVarOrDefault( prefixFolder + "WaveSelect", "" )
	
	if ( StringMatch( waveSelect, "This Wave" ) )
	
		if ( ( channel == currentChan ) && ( waveNum == currentWave ) )
			return wName
		else
			return ""
		endif
	
	endif
	
	wList = NMWaveSelectList( channel, prefixFolder = prefixFolder )
	
	if ( !WaveExists( $wName ) || ( WaveType( $wName ) == 0 ) )
		return ""
	endif
	
	if ( WhichListItem( wName, wList ) >= 0 )
		return wName
	endif
	
	return ""
	
End // NMWaveSelected

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWaveIsSelected( channel, waveNum [ prefixFolder ] )
	Variable channel
	Variable waveNum
	String prefixFolder
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( strlen( NMWaveSelected( channel, waveNum, prefixFolder = prefixFolder ) ) > 0 )
		return 1
	endif
	
	return 0
	
End // NMWaveIsSelected

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMWaveSelectAllList( [ prefixFolder, waveSelect ] ) // return a list of sets or groups if "All Sets" or "All Groups" is selected
	String prefixFolder
	String waveSelect

	Variable icnt
	String item, set, grpList, iList = ""
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	if ( ParamIsDefault( waveSelect ) )
		waveSelect = StrVarOrDefault( prefixFolder + "WaveSelect", "" )
	endif
	
	if ( strlen( waveSelect ) == 0 )
		return ""
	endif
	
	icnt = strsearch( waveSelect, "All Groups", 0, 2 )

	if ( StringMatch( waveSelect, "All Sets" ) )
	
		return NMSetsListXclude( prefixFolder = prefixFolder )
		
	elseif ( StringMatch( waveSelect, "All Groups" ) )
	
		return NMGroupsList( 1, prefixFolder = prefixFolder )
		
	elseif ( icnt > 0 ) // "Set x All Groups"
	
		set = waveSelect[0, icnt-1]
	
		grpList = NMGroupsList( 1, prefixFolder = prefixFolder )
		
		for ( icnt = 0; icnt < ItemsInList( grpList ); icnt += 1 )
			item = set + StringFromList( icnt, grpList )
			iList = AddListItem( item, iList, ";", inf )
		endfor
		
		return iList
		
	endif
	
	return ""

End // NMWaveSelectAllList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMAllSetsIsSelected( [ prefixFolder ] ) // determine if "All Sets" is selected
	String prefixFolder
	
	String waveSelect
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif
	
	waveSelect = StrVarOrDefault( prefixFolder + "WaveSelect", "" )

	if ( StringMatch( waveSelect, "All Sets" ) )
		return 1 // yes
	else
		return 0 // no
	endif

End // NMAllSetsIsSelected

//****************************************************************
//****************************************************************
//****************************************************************

Function NMAllGroupsIsSelected( [ prefixFolder ] ) // determine if "All Groups" is selected
	String prefixFolder
	
	String waveSelect
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif
	
	waveSelect = StrVarOrDefault( prefixFolder + "WaveSelect", "" )

	if ( StringMatch( waveSelect, "All Groups" ) )
		return 1 // yes
	else
		return 0 // no
	endif

End // NMAllGroupsIsSelected

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMWaveSelectShort( [ prefixFolder, waveSelect, waveNum ] )
	String prefixFolder
	String waveSelect
	Variable waveNum
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( ParamIsDefault( waveSelect ) )
	
		if ( strlen( prefixFolder ) == 0 )
			return ""
		endif
		
		waveSelect = StrVarOrDefault( prefixFolder + "WaveSelect", "" )
		
	endif

	if ( ParamIsDefault( waveNum ) )
	
		if ( strlen( prefixFolder ) == 0 )
			return ""
		endif
		
		waveNum = NumVarOrDefault( prefixFolder + "CurrentWave", 0 )
		
	endif
	
	waveSelect = ReplaceString( "This Wave", waveSelect, num2istr( waveNum ) )
	
	waveSelect = ReplaceString( " && ", waveSelect, "" )
	waveSelect = ReplaceString( " & ", waveSelect, "" )
	waveSelect = ReplaceString( " x ", waveSelect, "" )
	waveSelect = ReplaceString( " || ", waveSelect, "" )
	waveSelect = ReplaceString( " | ", waveSelect, "" )
	waveSelect = ReplaceString( " + ", waveSelect, "" )
	waveSelect = ReplaceString( "_", waveSelect, "" )
	waveSelect = ReplaceString( " ", waveSelect, "" )
	waveSelect = ReplaceString( ".", waveSelect, "" )
	waveSelect = ReplaceString( ",", waveSelect, "" )
	
	return waveSelect
	
End // NMWaveSelectShort

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNameStrShort( nameStr )
	String nameStr
	
	nameStr = ReplaceString("Data", nameStr, "D")
	nameStr = ReplaceString("Record", nameStr, "R")
	nameStr = ReplaceString("Sweep", nameStr, "S")
	nameStr = ReplaceString("Wave", nameStr, "W")
	nameStr = ReplaceString("EV_Evnt", nameStr, "EV")
	nameStr = ReplaceString("Stats", nameStr, "ST")
	nameStr = ReplaceString("Spike", nameStr, "SP")
	nameStr = ReplaceString("Event", nameStr, "EV")
	
	nameStr = ReplaceString("Groups", nameStr,"G")
	nameStr = ReplaceString("Group", nameStr,"G")
	nameStr = ReplaceString("Sets", nameStr, "S")
	nameStr = ReplaceString("Set", nameStr, "S")
	
	nameStr = ReplaceString("_", nameStr,"")
	nameStr = ReplaceString(" ", nameStr,"")
	nameStr = ReplaceString(".", nameStr,"")
	nameStr = ReplaceString(",", nameStr,"")
	
	return nameStr
	
End // NMNameStrShort

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMWaveSelectStr( [ prefixFolder ] )
	String prefixFolder
	
	String parent, currentPrefix, waveSelect
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	parent = NMParent( prefixFolder )
	
	currentPrefix = StrVarOrDefault( parent + "CurrentPrefix", "" )

	waveSelect = currentPrefix + NMWaveSelectShort( prefixFolder = prefixFolder )
	
	if ( strlen( waveSelect ) == 0 )
		return ""
	endif
	
	waveSelect = NMNameStrShort( waveSelect )
	
	return waveSelect[ 0,11 ]
	
End // NMWaveSelectStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWaveSelectXstats( statsSelect, channel [ prefixFolder ] )
	String statsSelect // see GetXstats
	Variable channel // ( -1 ) for current channel
	String prefixFolder

	Variable ccnt, cbgn, cend, numChannels
	String wList2, wList = ""
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return NaN
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	if ( channel < 0 )
	
		cbgn = 0
		cend = numChannels - 1
	
	elseif ( channel >= numChannels )
	
		return Nan
		
	else
	
		cbgn = channel
		cend = channel
	
	endif

	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
	
		if ( NMChanSelected( ccnt, prefixFolder = prefixFolder ) )
			wList2 = NMWaveSelectList( ccnt, prefixFolder = prefixFolder )
			wList = NMAddToList( wList2, wList, ";" )
		endif
		
	endfor

	return GetXstats( statsSelect, wList )
	
End // NMWaveSelectXstats

//****************************************************************
//****************************************************************
//****************************************************************

Function CreateOldNMWavSelect( dataFolder )
	String dataFolder // where to create WavSelect ( "" for current folder )
	
	String wName

	if ( strlen( dataFolder ) == 0 )
		dataFolder = CurrentNMFolder( 1 )
	endif
	
	if ( !DataFolderExists( dataFolder ) )
		return -1
	endif
	
	wName = dataFolder+"WavSelect"
	
	if ( WaveExists( $wName ) )
		KillWaves /Z $wName // try to kill first
	endif
	
	NMPrefixFolderListsToWave( NMWaveSelectVarName, wName )

End // CreateOldNMWavSelect

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Channel Wave List Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMChanWaveLists( [ prefixFolder ] )
	String prefixFolder

	Variable ccnt
	String strVarName
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif
	
	String wName = prefixFolder + "ChanWaveList" // OLD WAVE
	
	if ( !WaveExists( $wName ) )
		return 0
	endif

	Wave /T wtemp = $wName
	
	for ( ccnt = 0 ; ccnt < numpnts( wtemp ) ; ccnt += 1 )
		strVarName = prefixFolder + NMChanWaveListPrefix + ChanNum2Char( ccnt )
		SetNMstr( strVarName, wtemp[ ccnt ] )
	endfor
	
	KillWaves /Z $wName
	
	NMPrefixFolderWaveKill( "wNames_", prefixFolder = prefixFolder ) // kill old waves
	
	NMChanWaveList2Waves( prefixFolder = prefixFolder )

End // CheckNMChanWaveLists

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanWaveList( channel [ prefixFolder, fullPath ] )
	Variable channel // ( -1 ) for current channel ( -2 ) for all channels
	String prefixFolder
	Variable fullPath // ( 0 ) no ( 1 ) yes
	
	Variable ccnt, cbgn, cend, numChannels
	String strVarName, folder, wList = ""
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	if ( channel == -1 )
		cbgn = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
		cend = cbgn
	elseif ( channel == -2 )
		cbgn = 0
		cend = numChannels - 1
	elseif ( ( channel >= 0 ) && ( channel < numChannels ) )
		cbgn = channel
		cend = channel
	else
		//return NM2ErrorStr( 10, "channel", num2str( channel ) )
		return ""
	endif
	
	for ( ccnt = cbgn ; ccnt <= cend ; ccnt += 1 )
		strVarName = prefixFolder + NMChanWaveListPrefix + ChanNum2Char( ccnt )
		wList += StrVarOrDefault( strVarName, "" )
	endfor
	
	if ( fullPath )
		folder = NMParent( prefixFolder )
		return NMWaveListAddPath( folder, wList, ";" )
	else
		return wList
	endif
	
End // NMChanWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanWaveName( channel, waveNum [ prefixFolder ] )
	Variable channel // ( -1 ) for current channel
	Variable waveNum // ( -1 ) for current wave
	String prefixFolder
	
	String wList
	
	// return name of wave from wave ChanWaveList, given channel and wave number
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif

	if ( channel == -1 )
		channel = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	endif
	
	if ( waveNum == -1 )
		waveNum = NumVarOrDefault( prefixFolder + "CurrentWave", 0 )
	endif
	
	wList = NMChanWaveList( channel, prefixFolder = prefixFolder )
	
	return StringFromList( waveNum, wList )

End // NMChanWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanWaveNum( wName [ prefixFolder ] ) // return wave number, given name
	String wName // wave name
	String prefixFolder
	
	Variable ccnt, found, numChannels
	String wList
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	for ( ccnt = 0; ccnt < numChannels; ccnt += 1 )
	
		wList = NMChanWaveList( ccnt, prefixFolder = prefixFolder )
	
		found = WhichListItem( wName, wList, ";", 0, 0 )
		
		if ( found >= 0 )
			return found
		endif
		
	endfor
	
	return -1

End // NMChanWaveNum

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanWaveListSet( force [ prefixFolder ] ) // update the list of channel wave names
	Variable force // ( 0 ) no ( 1 ) yes
	String prefixFolder
	
	Variable ccnt, icnt, jcnt = -1
	Variable wcnt, nwaves, nmax, strict, numChannels, numWaves
	
	String parent, currentPrefix, wName, strVarName, wList = "", allList = "", sList = ""
	
	String order = NMStrGet( "OrderWavesBy" )
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	parent = NMParent( prefixFolder )
	
	currentPrefix = StrVarOrDefault( parent + "CurrentPrefix", "" )
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	numWaves = NumVarOrDefault( prefixFolder + "NumWaves", 0 )
	
	if ( numChannels == 0 )
		return 0
	endif
	
	DoWindow /K $NMChanWaveListTableName()
	
	if ( force )
		NMPrefixFolderStrVarKill( NMChanWaveListPrefix, prefixFolder = prefixFolder )
	endif
	
	for ( ccnt = 0; ccnt < numChannels; ccnt += 1 )
	
		strVarName = prefixFolder + NMChanWaveListPrefix + ChanNum2Char( ccnt )
	
		if ( ( force != 1 ) && ( ItemsInList( StrVarOrDefault( strVarName, "" ) ) > 0 ) )
			continue
		endif
		
		wList = ""
			
		if ( numChannels == 1 )
		
			wList = NMFolderWaveList( parent, currentPrefix + "*", ";", "Text:0", 0 )
			
		else
		
			if ( jcnt < 0 )
				wList = NMChanWaveListSearch( currentPrefix, ccnt )
			endif
			
			if ( ItemsInList( wList ) == 0 )
			
				jcnt = max( jcnt, ccnt )
		
				for ( icnt = jcnt; icnt < 10; icnt += 1 )
				
					wList = NMChanWaveListSearch( currentPrefix, icnt )
					
					if ( ItemsInList( wList ) > 0 )
						jcnt = icnt + 1
						break
					endif
					
				endfor
				
			endif
			
		endif

		if ( ItemsInList( wList ) == 0 ) // if none found, try most general name
			wList = NMFolderWaveList( parent, currentPrefix + "*", ";", "Text:0", 0 )
		endif
		
		for ( wcnt = 0; wcnt < ItemsInList( allList ); wcnt += 1 ) // remove waves already used
			wName = StringFromList( wcnt, allList )
			wList = RemoveFromList( wName, wList )
		endfor
		
		nwaves = ItemsInList( wList )
		
		if ( nwaves > nmax )
			nmax = nwaves
		endif
		
		if ( nwaves == 0 )
			continue
		elseif ( nwaves != NumWaves )
			//NMDoAlert( "Warning: located only " + num2istr( nwaves ) + " waves for channel " + ChanNum2Char( ccnt ) + "." )
		endif
		
		//strict = ChanWaveListStrict( wList, ccnt )
		
		slist = SortList( wList, ";", 16 ) // SortListAlphaNum( wList, currentPrefix )
		
		if ( StringMatch( order, "name" ) && !StringMatch( wList, slist ) )
			wList = slist
		endif
		
		//Print "Chan" + ChanNum2Char( ccnt ) + ": " + wList
	
		SetNMstr( strVarName, wList )
		
		allList += wList
		
	endfor
	
	NMChanWaveList2Waves( prefixFolder = prefixFolder )
	
	return 0

End // NMChanWaveListSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanWaveListSearch( wavePrefix, channel [ folder ] ) // return list of waves appropriate for channel
	String wavePrefix // wave prefix
	Variable channel
	String folder
	
	Variable wcnt, icnt, jcnt, seqnum, foundLetter
	String chanstr, wList, wName, seqstr, olist = ""
	
	if ( strlen( wavePrefix ) == 0 )
		return ""
	endif
	
	chanstr = ChanNum2Char( channel )
	
	if ( strlen( chanstr ) == 0 )
		return ""
	endif
	
	if ( ParamIsDefault( folder ) )
		folder = CurrentNMFolder( 1 )
	elseif ( !DataFolderExists( folder ) )
		return ""
	endif
	
	wList = NMFolderWaveList( folder, wavePrefix + "*" + chanstr + "*", ";", "Text:0", 0 )
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		for ( icnt = strlen( wName )-2; icnt > 0; icnt -= 1 )
		
			if ( StringMatch( wName[icnt,icnt], chanstr ) )
			
				seqstr = wName[icnt+1,inf]
				foundLetter = 0
				
				for ( jcnt=0; jcnt < strlen( seqstr ); jcnt += 1 )
					if ( numtype( str2num( seqstr[jcnt, jcnt] ) ) > 0 )
						foundLetter = 1
					endif
				endfor
				
				if ( foundLetter == 0 )
					olist = AddListItem( wName, olist, ";", inf ) // matches criteria
				endif
				
				break
				
			endif
			
		endfor
		
	endfor
	
	return olist

End // NMChanWaveListSearch

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanWaveListSort( channel, sortOption [ prefixFolder ] )
	Variable channel // channel number ( -1 ) for all currently selected channels
	Variable sortOption // ( -1 ) sort by creation date ( >= 0 ) see Igor SortList function options
	String prefixFolder
	
	Variable ccnt, cbgn = channel, cend = channel
	String parent, currentPrefix, strVarName, wList
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	parent = NMParent( prefixFolder )
	
	currentPrefix = StrVarOrDefault( parent + "CurrentPrefix", "" )
	
	DoWindow /K $NMChanWaveListTableName()
	
	if ( channel < 0 )
		cbgn = 0
		cend = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	endif
	
	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
	
		strVarName = prefixFolder + NMChanWaveListPrefix + ChanNum2Char( ccnt )
		
		wList = StrVarOrDefault( strVarName, "" )
		
		if ( ItemsInList( wList ) == 0 )
			continue
		endif
	
		switch( sortOption )
		
			case 0:
			case 1:
			case 2:
			case 4:
			case 8:
			case 16:
				wList = SortList( wList, ";", sortOption )
				SetNMstr( strVarName, wList )
				break
				
			case -1:
				wList = SortWaveListByCreation( wList )
				SetNMstr( strVarName, wList )
				break
				
			default:
				return -1
		
		endswitch
		
	endfor
	
	NMChanWaveList2Waves( prefixFolder = prefixFolder )

End // NMChanWaveListSort

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMOrderWavesCall()

	String wList

	Variable order = NMVarGet( "OrderWaves" )

	String tname = NMChanWaveListTableName()
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( NMPrefixFolderAlert() )
		return ""
	endif
		
	if ( WinType( tname ) == 2 )
		DoWindow /F $tname
		wList = NMFolderWaveList( prefixFolder, "*", ";","WIN:"+ tname, 0 )
		NMChanWaveListOrder( wList )
		NMChanWaves2WaveList()
		return ""
	endif
	
	Prompt order, "order waves by:", popup "creation date;alpha-numerically;user-input table;"
	DoPrompt NMPromptStr( "Order Waves" ), order
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMvar( NMDF+"OrderWaves", order )
	
	switch( order )
		case 1:
			NMOrderWavesByCreation( history = 1 )
			break
		case 2:
			NMOrderWavesAlphaNum( history = 1 )
			break
		case 3:
			NMOrderWavesByTable( history = 1 )
			break
	endswitch

End // NMOrderWavesCall()

//****************************************************************
//****************************************************************
//****************************************************************

Function NMOrderWavesByCreation( [ prefixFolder, update, history ] )
	String prefixFolder
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes

	Variable ccnt, numChannels
	String vlist = ""
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		vlist = NMCmdStrOptional( "prefixFolder", prefixFolder, vlist )
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )

	for ( ccnt = 0; ccnt < numChannels; ccnt += 1 ) // loop thru channels
		if ( NMChanSelected( ccnt, prefixFolder = prefixFolder ) )
			NMChanWaveListSort( ccnt, -1, prefixFolder = prefixFolder )
		endif
	endfor
	
	if ( update )
		ChanGraphsUpdate()
	endif
	
	return 0

End // NMOrderWavesByCreation

//****************************************************************
//****************************************************************
//****************************************************************

Function NMOrderWavesAlphaNum( [ prefixFolder, update, history ] )
	String prefixFolder
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes

	Variable ccnt, numChannels
	String vlist = ""
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		vlist = NMCmdStrOptional( "prefixFolder", prefixFolder, vlist )
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )

	for ( ccnt = 0; ccnt < numChannels; ccnt += 1 ) // loop thru channels
		if ( NMChanSelected( ccnt, prefixFolder = prefixFolder ) )
			NMChanWaveListSort( ccnt, 16, prefixFolder = prefixFolder )
		endif
	endfor
	
	if ( update )
		ChanGraphsUpdate()
	endif

End // NMOrderWavesAlphaNum

//****************************************************************
//****************************************************************
//****************************************************************

Function NMOrderWavesByTable( [ prefixFolder, history ] )
	String prefixFolder
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable currentChan
	String vlist = ""
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		vlist = NMCmdStrOptional( "prefixFolder", prefixFolder, vlist )
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	currentChan = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	
	if ( NMChanSelectedAll( prefixFolder = prefixFolder ) )
		NMChanWaveListOrderTable( -1, prefixFolder = prefixFolder )
	else
		NMChanWaveListOrderTable( currentChan, prefixFolder = prefixFolder )
	endif

End // NMOrderWavesByTable

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanWaveListTableName()

	return "NM_" + CurrentNMFolderPrefix() + "OrderWaveNames"

End // NMChanWaveListTableName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanWaveListOrderTable( channel [ prefixFolder ] )
	Variable channel // ( -1 ) for All
	String prefixFolder
	
	Variable ccnt, cbgn = channel, cend = channel
	String wName, wName2, tName, title
	
	STRUCT Rect w
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	wName = prefixFolder + "ChanWaveNames" + ChanNum2Char( channel )
	wName2 = prefixFolder + "wnames_Order"
	
	tName = NMChanWaveListTableName()
	
	if ( WinType( tName ) > 0 )
		DoWindow /F $tName
		return 0
	endif
	
	if ( channel < 0 )
		cbgn = 0
		cend = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	endif
	
	Make /O/N=( numpnts( $wName ) ) $wName2
	
	Wave wtemp = $wName2
	
	wtemp = x
	
	NMWinCascadeRect( w )
	
	title = "Click " + NMQuotes( "Order Waves" ) + " to re-order"
	
	Edit /K=1/N=$tName/W=(w.left,w.top,w.right,w.bottom) $wName2 as title
	SetWindow $tName hook=NMChanWaveListTableHook
	Execute /Z "ModifyTable title( Point )= " + NMQuotes( "Order" )
	
	for ( ccnt = cbgn; ccnt <= cend; ccnt += 1 )
	
		wName = prefixFolder + "ChanWaveNames" + ChanNum2Char( ccnt )
		
		if ( WaveExists( $wName ) )
			AppendToTable /W=$tName $wName
		endif
		
	endfor
	
	RemoveFromTable /W=$tName $wName2
	
	AppendToTable /W=$tName $wName2

End // NMChanWaveListOrderTable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanWaveListTableHook( infoStr )
	String infoStr
	
	String event= StringByKey( "EVENT", infoStr )
	String win= StringByKey( "WINDOW", infoStr )
	
	String wList = NMFolderWaveList( CurrentNMPrefixFolder(), "*", ";","WIN:"+ win, 0 )
	
	if ( ItemsInList( wList ) <= 1 )
		return -1
	endif

	strswitch( event )
		case "kill":
			NMChanWaveListOrder( wList )
	endswitch

End // NMChanWaveListTableHook

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanWaveListOrder( wList [ prefixFolder ] )
	String wList
	String prefixFolder

	Variable wcnt
	String wName, wName2
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	wName2 = prefixFolder + "wnames_Order"
	
	if ( !WaveExists( $wName2 ) )
		NMDoAlert( "Abort NMChanWaveListOrder: missing wave wnames_Order" )
		return -1
	endif
	
	wList = RemoveFromList( wName2, wList )
	
	if ( ItemsInList( wList ) == 0 )
		NMDoAlert( "Abort NMChanWaveListOrder: no waves to order" )
		return -1
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = prefixFolder + StringFromList( wcnt, wList )
		
		if ( !WaveExists( $wName ) || ( numpnts( $wName ) != numpnts( $wName2 ) ) )
			Print "Failed to order waves."
			continue
		endif
		
		Sort $wName2, $wName
		
	endfor
	
	Sort $wName2, $wName2
	
	Wave wtemp = $wName2
	
	wtemp = x
	
	NMChanWaves2WaveList( prefixFolder = prefixFolder )

End // NMChanWaveListOrder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S OrderToNMChanWaveList( wList, channel [ prefixFolder ] )
	String wList // wave list to order
	Variable channel
	String prefixFolder
	
	Variable items, icnt, numChannels
	String chanList, item, outList = ""
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return wList
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	if ( ( channel < 0 ) || ( channel >= numChannels ) )
		return wList
	endif
	
	chanList = NMChanWaveList( channel, prefixFolder = prefixFolder )
	
	items = ItemsInList( chanList )
	
	for ( icnt = 0 ; icnt < items ; icnt += 1 )
		
		item = StringFromList( icnt, chanList )
		
		if ( WhichListItem( item, wList ) >= 0 )
			outList += item + ";"
		endif
		
	endfor
	
	return outList
	
End // OrderToNMChanWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanWaveListName( channel [ prefixFolder ] )
	Variable channel
	String prefixFolder
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif

	return prefixFolder + "ChanWaveNames" + ChanNum2Char( channel )

End // NMChanWaveListName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanWaveList2Waves( [ prefixFolder ] )
	String prefixFolder

	Variable ccnt, icnt, numChannels, numWaves
	String strVarName, wList, wName
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	numWaves = NumVarOrDefault( prefixFolder + "NumWaves", 0 )
	
	NMPrefixFolderWaveKill( "ChanWaveNames", prefixFolder = prefixFolder )
	
	for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
	
		strVarName = prefixFolder + NMChanWaveListPrefix + ChanNum2Char( ccnt )
		
		wList = StrVarOrDefault( strVarName, "" )
		
		wName = prefixFolder + "ChanWaveNames" + ChanNum2Char( ccnt )
		
		Make /O/T/N=( numWaves ) $wName = ""
		
		Wave /T wtemp = $wName
		
		for ( icnt = 0 ; icnt < numpnts( wtemp ) ; icnt += 1 )
			wtemp[ icnt ] = StringFromList( icnt, wList )
		endfor
		
	endfor
	
	return 0

End // NMChanWaveList2Waves

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanWaves2WaveList( [ prefixFolder ] )
	String prefixFolder

	Variable ccnt, icnt, numChannels
	String strVarName, wName, wList
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	NMPrefixFolderStrVarKill( NMChanWaveListPrefix, prefixFolder = prefixFolder )
	
	for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
		
		strVarName = prefixFolder + NMChanWaveListPrefix + ChanNum2Char( ccnt )
		wName = prefixFolder + "ChanWaveNames" + ChanNum2Char( ccnt )
		
		if ( !WaveExists( $wName ) )
			continue
		endif
		
		Wave /T wtemp = $wName
		
		wList = ""
		
		for ( icnt = 0 ; icnt < numpnts( wtemp ) ; icnt += 1 )
			wList = AddListItem( wtemp[ icnt ], wList, ";", inf )
		endfor
		
		SetNMstr( strVarName, wList )
		
	endfor
	
	return 0

End // NMChanWaves2WaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanXstats( select [ prefixFolder ] )
	String select // see GetXstats
	String prefixFolder

	Variable ccnt, numChannels
	String wList = ""
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return NaN
	endif

	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	for ( ccnt = 0; ccnt < numChannels ; ccnt += 1 )
		wList = NMAddToList( NMChanWaveList( ccnt, prefixFolder = prefixFolder ), wList, ";" )
	endfor

	return GetXstats( select, wList )
	
End // NMChanXstats

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanStartX( waveSelect, forceNewSearch [ prefixFolder ] )
	Variable waveSelect // ( 0 ) all channel waves ( 1 ) only selected waves
	Variable forceNewSearch
	String prefixFolder

	Variable ccnt, wcnt, dumvar, numChannels, numWaves, startx = NaN
	String wName, wList, xWave, varName, xWavePrefix

	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return NaN
	endif
	
	varName = prefixFolder + "WaveStartX"
	
	xWave = StrVarOrDefault( prefixFolder + "Xwave", "" )
	xWavePrefix = StrVarOrDefault( prefixFolder + "XwavePrefix", "" )
	
	if ( WaveExists( $xWave ) )
		
		WaveStats /Q $xWave
		
		startx = V_min
		
		SetNMvar( varName, startx )
	
		return startx
	
	endif
	
	if ( ( forceNewSearch == 0 ) && ( exists( varName ) == 2 ) )
		return NumVarOrDefault( varName, NaN )
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	if ( numChannels <= 0 )
		return NaN
	endif
	
	for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
	
		if ( waveSelect == 1 )
			wList = NMWaveSelectList( ccnt, prefixFolder = prefixFolder )
		else
			wList = NMChanWaveList( ccnt, prefixFolder = prefixFolder )
		endif
		
		numWaves = ItemsInList( wList )
	
		for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
		
			wName = StringFromList( wcnt, wList )
			
			if ( strlen( xWavePrefix ) > 0 )
			
				xWave = NMXwave( prefixFolder = prefixFolder, waveNum = wcnt )
				
				if ( WaveExists( $xWave ) )
					WaveStats /Q $xWave
					dumvar = V_min
				else
					dumvar = NaN
				endif
		
			else
			
				dumvar = leftx( $wName )
			
			endif
		 
			if ( ( numtype( startx ) > 0 ) && ( numtype( dumvar ) == 0 ) )
				startx = dumvar // first wave
			elseif ( ( numtype( startx ) == 0 ) && ( abs( dumvar - startx ) > 0.001 ) )
				return NaN // waves have different startx
			endif
			
		endfor
	
	endfor
	
	if ( numtype( startx ) > 0 )
		startx = NaN
	endif
	
	SetNMvar( varName, startx )
	
	return startx

End // NMChanStartX

//****************************************************************
//****************************************************************
//****************************************************************

Function NMChanDeltaX( waveSelect, forceNewSearch [ prefixFolder, tolerance ] )
	Variable waveSelect // ( 0 ) all channel waves ( 1 ) only selected waves
	Variable forceNewSearch // ( 0 ) no ( 1 ) yes
	String prefixFolder
	Variable tolerance

	Variable ccnt, wcnt, dumvar, numChannels, numWaves, dx = -1
	String wName, wList, varName, xWave

	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( ParamIsDefault( tolerance ) )
		tolerance = 1e-8
	endif
	
	varName = prefixFolder + "WaveDeltaX"
	
	if ( !forceNewSearch && ( exists( varName ) == 2 ) )
		return NumVarOrDefault( prefixFolder + "WaveDeltaX", NaN )
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	if ( numChannels <= 0 )
		return -1
	endif
	
	//xWave = NMXwave( prefixFolder = prefixFolder, waveNum = 0 )
	
	for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
	
		if ( waveSelect == 1 )
			wList = NMWaveSelectList( ccnt, prefixFolder = prefixFolder )
		else
			wList = NMChanWaveList( ccnt, prefixFolder = prefixFolder )
		endif
		
		numWaves = ItemsInList( wList )
	
		for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
		
			wName = StringFromList( wcnt, wList )
			
			dumvar = deltax( $wName )
		 
			if ( ( dx < 0 ) && ( numtype( dumvar ) == 0 ) )
				dx = dumvar // first wave
			elseif ( ( numtype( dx ) == 0 ) && ( abs( dumvar - dx ) > tolerance ) )
				return NaN // waves have different deltax
			endif
			
		endfor
	
	endfor
	
	if ( ( dx <= 0 ) || ( numtype( dx ) > 0 ) )
		dx = NaN
	endif
	
	SetNMvar( varName, dx )
	
	return dx

End // NMChanDeltaX

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanXUnitsList( [ prefixFolder ] )
	String prefixFolder

	Variable ccnt, numChannels
	String wList, unitsList = ""
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )

	for ( ccnt = 0; ccnt < numChannels ; ccnt += 1 )
		wList = NMChanWaveList( ccnt, prefixFolder = prefixFolder )
		unitsList = NMAddToList( NMWaveUnitsList( "x", wList ) , unitsList, ";" )
	endfor
	
	return unitsList
	
End // NMChanXUnitsList

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Functions not used anymore
//
//****************************************************************
//****************************************************************
//****************************************************************

Function CurrentNMGroup() // NOT USED

	return NMGroupsNum( CurrentNMWave() )

End // CurrentNMGroup

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanWaveListPrefix() // NOT USED
	
	return "ChanWaveNames"
	
End // NMChanWaveListPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanWaveListStrVarPrefix() // NOT USED
	
	return NMChanWaveListPrefix
	
End // NMChanWaveListStrVarPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanSelectStrVarName() // NOT USED

	return NMChanSelectVarName

End // NMChanSelectStrVarName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMWaveSelectStrVarPrefix() // NOT USED
	String setName
	
	return NMWaveSelectVarName
	
End // NMWaveSelectStrVarPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefixFolderStrVarSearch( strVarPrefix, fullPath [ prefixFolder ] ) // NOT USED
	String strVarPrefix // prefix name
	Variable fullPath // return StrVarName with full path ( 0 ) no ( 1 ) yes
	String prefixFolder

	String matchStr = strVarPrefix + "*"
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	return NMFolderStringList( prefixFolder, matchStr, ";", fullPath )

End // NMPrefixFolderStrVarSearch

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefixFolderWaveSearch( wavePrefix, fullPath [ prefixFolder ] ) // NOT USED
	String wavePrefix // prefix name
	Variable fullPath // return waveName with full path ( 0 ) no ( 1 ) yes
	String prefixFolder

	String matchStr = wavePrefix + "*"
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	return NMFolderWaveList( prefixFolder, matchStr, ";", "", fullPath )

End // NMPrefixFolderWaveSearch

//****************************************************************
//****************************************************************
//****************************************************************

Function NMPrefixFolderVar( varName, defaultValue [ prefixFolder ] ) // NOT USED
	String varName
	Variable defaultValue
	String prefixFolder
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return defaultValue
	endif
	
	if ( ( strlen( varName ) == 0 ) || ( strlen( prefixFolder ) == 0 ) )
		return defaultValue // does not exist
	endif
	
	return NumVarOrDefault( prefixFolder + varName, defaultValue )

End // NMPrefixFolderVar

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefixFolderStr( varName, defaultStr [ prefixFolder ] ) // NOT USED
	String varName
	String defaultStr
	String prefixFolder
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return defaultStr
	endif
	
	if ( ( strlen( varName ) == 0 ) || ( strlen( prefixFolder ) == 0 ) )
		return defaultStr // does not exist
	endif
	
	return StrVarOrDefault( prefixFolder+varName, defaultStr )

End // NMPrefixFolderStr

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanWaveListStrVarName( channel [ prefixFolder ] ) // NOT USED
	Variable channel
	String prefixFolder
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif

	return prefixFolder + NMChanWaveListPrefix + ChanNum2Char( channel )

End // NMChanWaveListStrVarName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMWaveSelectStrVarName( channel [ prefixFolder ]  ) // NOT USED
	Variable channel
	String prefixFolder
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif

	return prefixFolder + NMWaveSelectVarName + ChanNum2Char( channel )

End // NMWaveSelectStrVarName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMPrefixFolderVarName( strVarPrefix, channel [ prefixFolder ] ) // NOT USED
	String strVarPrefix // prefix name
	Variable channel // channel number
	String prefixFolder
	
	Variable numChannels
	String chanStr = ""
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	if ( channel < 0 )
		channel = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	if ( ( numtype( channel ) == 0 ) && ( channel >= 0 ) && ( channel < numChannels ) )
		chanStr = ChanNum2Char( channel )
	endif
	
	return prefixFolder + strVarPrefix + chanStr
	
End // NMPrefixFolderVarName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMChanSelectList( [ prefixFolder ] ) // NOT USED
	String prefixFolder
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif

	return StrVarOrDefault( prefixFolder + NMChanSelectVarName, "" )
	
End // NMChanSelectList

//****************************************************************
//****************************************************************
//****************************************************************
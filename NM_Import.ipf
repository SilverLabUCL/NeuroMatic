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
//	Import file functions
//
//****************************************************************
//****************************************************************

StrConstant NMImportDF = "root:Packages:NeuroMatic:Import:"

//****************************************************************
//****************************************************************
//****************************************************************

Function /S ImportDF()

	if ( NMVarGet( "ImportPrompt" ) == 0 )
		return GetDataFolder( 1 )
	endif

	CheckImport()
	
	return "root:Packages:NeuroMatic:Import:"

End // ImportDF

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckImport()

	CheckNMPackageDF( "Import" )

End // CheckImport

//****************************************************************
//****************************************************************
//****************************************************************

Function CallNMImportFileManager( file, df, fileType, option ) // call appropriate import data function
	String file
	String df
	String fileType
	String option // "header", "data" or "test"
	
	Variable success = -1
	
	if ( strlen( fileType ) > 0 )
	
		success = NMImportFileManager( file, df, fileType, option )
	
	else
	
		if ( ReadPclampFormat( file ) > 0 )
			fileType = "Pclamp"
			success = NMImportFileManager( file, df, fileType, option )
		elseif ( ReadAxographFormat( file ) > 0 )
			fileType = "Axograph"
			success = NMImportFileManager( file, df, fileType, option )
		else
			NMDoAlert( "Abort NMImportFileManager: file format not recognized for " + file )
			fileType = ""
		endif
		
	endif
	
	SetNMstr( df+"DataFileType", fileType )
	
	return success

End // CallNMImportFileManager

//****************************************************************
//****************************************************************
//****************************************************************

Function NMImportFileManager( file, df, filetype, option ) // call appropriate import data function
	String file
	String df // data folder to import to ( "" ) for current
	String filetype // data file type ( ie. "axograph" or "Pclamp" )
	String option // "header" to read data header
				// "data" to read data
				// "test" to test whether this file manager supports file type
	
	Variable /G success // success flag ( 1 ) yes ( 0 ) no; or the number of data waves read
	
	if ( strlen( df ) == 0 )
		df = GetDataFolder( 1 )
	endif
	
	df = LastPathColon( df, 1 )
	
	strswitch( filetype )
	
		default:
			return 0
	
		case "Axograph": // ( see ReadAxograph.ipf )
		
			strswitch( option )
				case "header":
					Execute "success = ReadAxograph( " + NMQuotes( file ) + "," + NMQuotes( df ) + ", 0 )"
					break
					
				case "data":
					Execute "success = ReadAxograph( " + NMQuotes( file ) + "," + NMQuotes( df ) + ", 1 )"
					break
					
				case "test":
					success = 1
					break
					
			endswitch
			
			break
		
		case "Pclamp": // ( see ReadPclamp.ipf )
		
			strswitch( option )
			
				case "header":
					Execute "success = ReadPclampHeader( " + NMQuotes( file ) + "," + NMQuotes( df ) + " )"
					break
					
				case "data":
					Execute "success = ReadPclampData( " + NMQuotes( file ) + "," + NMQuotes( df ) + " )"
					break
					
				case "test":
					success = 1
					break
					
			endswitch
			
			break
			
	endswitch
	
	Variable ss = success
	
	KillVariables /Z success
	
	return ss

End // NMImportFileManager

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMImportFile( folder, fileList [ nmPrefix, history ] ) // import a data file
	String folder // folder name, or "new" for new folder, or "one" to import into a single folder
	String fileList // list of external file names
	Variable nmPrefix // ( 0 ) no ( 1 ) yes, force "nm" prefix when creating NM data folders
	Variable history
	
	Variable fcnt, newFolder, success, emptyfolder
	String file, folder2, saveDF, vlist = "", df
	
	String replaceStringList = NMStrGet( "FileNameReplaceStringList" )
	
	vList = NMCmdStr( folder, vList )
	vList = NMCmdStr( fileList, vList )
	
	if ( ParamIsDefault( nmPrefix ) )
		nmPrefix = 1
	else
		vlist = NMCmdNumOptional( "nmPrefix", nmPrefix, vlist )
	endif
	
	if ( history )
		NMCommandHistory( vList )
	endif
	
	for ( fcnt = 0 ; fcnt < ItemsInList( fileList ) ; fcnt += 1 )
	
		file = StringFromList( fcnt, fileList )
	
		if ( ( strlen( file ) == 0 ) || ( FileExistsAndNonZero( file ) == 0 ) )
			continue
		endif
		
		if ( StringMatch( folder, "one" ) == 1 )
		
			if ( fcnt == 0 )
				folder2 = NMFolderNameCreate( file, nmPrefix = nmPrefix, replaceStringList = replaceStringList )
			endif
		
		elseif ( ( strlen( folder ) == 0 ) || ( StringMatch( folder, "new" ) == 1 ) )
		
			folder2 = NMFolderNameCreate( file, nmPrefix = nmPrefix, replaceStringList = replaceStringList )
			
		else
		
			folder2 = folder
			
		endif
		
		saveDF = GetDataFolder( 0 )
			
		if ( DataFolderExists( folder2 ) == 1 )
		
			NMFolderChange( folder2 )
		
		//elseif ( ( NMNumChannels() == 0 ) && ( ItemsInList( WaveList( "*", ";", "" ) ) == 0 ) )
		
		//	NMFolderRename( "" , folder2 ) // removed this option due to conflict with NMImportWaves 13 July 2012
			
		else
		
			folder2 = NMFolderNew( folder2 )
			
			newFolder = 1
		
			if ( strlen( folder2 ) == 0 )
				continue
			endif
			
		endif
		
		df = GetDataFolder( 1 )
		
		SetNMstr( df+"CurrentFile", file )
		SetNMstr( df+"FileName", NMChild( file ) )
		SetNMstr( ImportDF()+"CurrentFile", file )
		SetNMstr( ImportDF()+"FileName", NMChild( file ) )
		
		success = NMImport( file, newFolder )
		
		if ( ( success < 0 ) && ( newfolder == 1 ) )
			KillDataFolder /Z $folder2
			NMFolderChange( saveDF )
			folder2 = ""
		endif
	
	endfor
	
	UpdateNM( 0 )
	
	KillVariables /Z V_Flag, WaveBgn, WaveEnd
	KillStrings /Z S_filename, S_wavenames
	KillWaves /Z DumWave0, DumWave1
	
	return folder

End // NMImportFile

//****************************************************************
//****************************************************************
//****************************************************************

Function NMImport( file, xnewFolder ) // main import data function
	String file
	Variable xnewFolder // NOT USED ANYMORE
	
	Variable success, amode, saveprompt, totalNumWaves, numChannels
	String acqMode, wPrefix, wList, prefixFolder, folderName
	String df = ImportDF()
	String folder = CurrentNMFolder( 1 ) // import into current data folder
	String folderShort = CurrentNMFolder( 0 )
	
	if ( CheckCurrentFolder() == 0 )
		return 0
	endif
	
	Variable importPrompt = NMVarGet( "ImportPrompt" )
	String saveWavePrefix = StrVarOrDefault( "WavePrefix", NMStrGet( "WavePrefix" ) )
	
	if ( FileExistsAndNonZero( file ) == 0 )
		NMDoAlert( "Error: external data file has not been selected." )
		return -1
	endif
	
	success = CallNMImportFileManager( file, df, "", "header" )
	
	if ( success <= 0 )
		return -1
	endif
	
	totalNumWaves = NumVarOrDefault( df+"TotalNumWaves", 0 )
	numChannels = NumVarOrDefault( df+"NumChannels", 1 )
	
	SetNMStr( df + "FolderName", GetDataFolder( 0 ) )
	
	SetNMvar( df+"WaveBgn", 0 )
	SetNMvar( df+"WaveEnd", ceil( totalNumWaves / numChannels ) - 1 )
	CheckNMstr( df+"WavePrefix", NMStrGet( "WavePrefix" ) )
	
	if ( importPrompt == 1 )
		NMImportPanel() // open panel to display header info and request user input
	endif
	
	if ( NumVarOrDefault( df+"WaveBgn", -1 ) < 0 ) // user aborted
		return -1
	endif
	
	folderName = StrVarOrDefault( df+"FolderName", folderShort )
	
	if ( !StringMatch( folderName, folderShort ) )
		NMFolderRename( folderShort, folderName )
		folder = CurrentNMFolder( 1 )
	endif
	
	wPrefix = StrVarOrDefault( df+"WavePrefix", NMStrGet( "WavePrefix" ) )
	
	SetNMvar( "WaveBgn", NumVarOrDefault( df+"WaveBgn", 0 ) )
	SetNMvar( "WaveEnd", NumVarOrDefault( df+"WaveEnd", -1 ) )
	
	SetNMstr( "WavePrefix", wPrefix )
	SetNMstr( "CurrentFile", file )
	
	success = CallNMImportFileManager( file, folder, StrVarOrDefault( df+"DataFileType", "" ), "Data" ) // now read the data
	
	if ( success < 0 ) // user aborted
		return -1
	endif
	
	PrintNMFolderDetails( GetDataFolder( 1 ) )
	NMSet( wavePrefixNoPrompt = wPrefix )
	
	prefixFolder = CurrentNMPrefixFolder()
	
	acqMode = StrVarOrDefault( df+"AcqMode", "" )
	
	amode = str2num( acqMode[0] )
	
	if ( ( numtype( amode ) == 0 ) && ( amode == 3 ) ) // gap free
	
		if ( NumVarOrDefault( df+"ConcatWaves", 0 ) == 1 )
		
			NMChanSelect( "All" )

			wList = NMMainConcatenate( newPrefix = "C_" )
			
			if ( ItemsInList( wList ) == NMNumWaves() * NMNumChannels() )
				NMKillWaves( wList, updateSets = 1, noAlert = 1 )
			else
				NMDoAlert( "Alert: waves may have not been properly concatenated." )
			endif
			
			NMSet( wavePrefixNoPrompt = "C_Record" )
			
		else
		
			NMMainXScaleMode( mode = "Continuous" )
			
		endif
		
	endif
	
	return 1

End // NMImport

//****************************************************************
//****************************************************************
//****************************************************************
//
//		Import File Panel
//		panel called to request user input
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMImportPanel()

	if ( CheckCurrentFolder() == 0 )
		return 0
	endif

	Variable x1, x2, y1, y2, yinc, height = 330, width = 280
	String df = ImportDF()
	
	Variable xPixels = NMComputerPixelsX()
	Variable waveEnd = NumVarOrDefault( df+"WaveEnd", 0 )
	Variable concat = NumVarOrDefault( df+"ConcatWaves", 0 )
	String acqmode = StrVarOrDefault( df+"AcqMode", "" )
	
	Variable amode = str2num( acqMode[0] )
	
	String fileType = StrVarOrDefault( df+"DataFileType", "UNKNOWN" )
	
	x1 = ( xPixels - width ) / 2
	y1 = 200
	x2 = x1 + width
	y2 = y1 + height
	
	DoWindow /K ImportPanel
	NewPanel /N=ImportPanel/W=( x1,y1,x2,y2 ) as "Import " + fileType + " File"
	
	x1 = 20
	y1 = 45
	yinc = 23
	
	SetDrawEnv fsize= 11
	DrawText x1, 30, "File: " + StrVarOrDefault( df+"FileName", "" )
	
	SetVariable NM_NumChannelSet, title="channels: ", limits={1,10,0}, pos={x1,y1}, size={240,50}, frame=0, value=$( df+"NumChannels" ), win=ImportPanel, proc=NMImportSetVariable
	SetVariable NM_SampIntSet, title="sample interval ( ms ): ", limits={0,10,0}, pos={x1,y1+1*yinc}, size={240,50}, frame=0, value=$( df+"SampleInterval" ), win=ImportPanel
	SetVariable NM_SPSSet, title="samples: ", limits={0,inf,0}, pos={x1,y1+2*yinc}, size={240,50}, frame=0, value=$( df+"SamplesPerWave" ), win=ImportPanel
	SetVariable NM_AcqModeSet, title="acquisition mode: ", pos={x1,y1+3*yinc}, size={240,50}, frame=0, value=$( df+"AcqMode" ), win=ImportPanel
	
	if ( ( numtype( amode ) == 0 ) && ( amode == 3 ) ) // gap free
		CheckBox NM_ConcatWaves, title="concatenate waves", pos={x1+50,y1+4*yinc}, size={16,18}, value=( concat ), proc=NMImportCheckBox, win=ImportPanel
		y1 += 15
	endif
	
	yinc = 28
	
	SetVariable NM_FolderNameSet, title="folder name ", pos={x1,y1+4*yinc}, size={240,60}, frame=1, value=$( df+"FolderName" ), win=ImportPanel
	SetVariable NM_WavePrefixSet, title="wave prefix ", pos={x1,y1+5*yinc}, size={240,60}, frame=1, value=$( df+"WavePrefix" ), win=ImportPanel
	SetVariable NM_WaveBgnSet, title="wave beg ", limits={0,waveEnd-1,0}, pos={x1,y1+6*yinc}, size={140,60}, frame=1, value=$( df+"WaveBgn" ), win=ImportPanel
	SetVariable NM_WaveEndSet, title="wave end ", limits={0,waveEnd-1,0}, pos={x1,y1+7*yinc}, size={140,60}, frame=1, value=$( df+"WaveEnd" ), win=ImportPanel
	
	Button NM_AbortButton, title="Abort", pos={55,y1+8.5*yinc}, size={50,20}, win=ImportPanel, proc=NMImportButton
	Button NM_ContinueButton, title="Open File", pos={145,y1+8.5*yinc}, size={80,20}, win=ImportPanel, proc=NMImportButton
	
	PauseForUser ImportPanel

End // NMImportPanel

//****************************************************************
//****************************************************************
//****************************************************************

Function NMImportCheckBox( ctrlName, checked ) : CheckBoxControl
	String ctrlName; Variable checked
	
	String df = ImportDF()
	
	strswitch( ctrlName )
		
		case "NM_ConcatWaves":
			SetNMvar( df+"ConcatWaves", checked )
			break
			
	endswitch
	
End // NMImportCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function NMImportButton( ctrlName ) : ButtonControl
	String ctrlName
	
	String df = ImportDF()
	
	if ( StringMatch( ctrlName, "NM_AbortButton" ) == 1 )
		SetNMvar( df+"WaveBgn", -1 )
	endif
	
	DoWindow /K ImportPanel

End // NMImportButton

//****************************************************************
//****************************************************************
//****************************************************************

Function NMImportSetVariable( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr, varName
	
	Variable chncnt, totalWaves, numChannels
	String df = ImportDF()
	
	strswitch( ctrlName )
	
		case "NM_NumChannelSet":
		
			totalWaves = NumVarOrDefault( df+"TotalNumWaves", 0 )
			numChannels = NumVarOrDefault( df+"NumChannels", 1 )
			SetNMvar( df+"WaveEnd", ceil( totalWaves / numChannels ) - 1 )
			
			break
		
	endswitch

End // NMImportSetVariable

//****************************************************************
//****************************************************************
//****************************************************************



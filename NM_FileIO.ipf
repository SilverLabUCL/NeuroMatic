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
//	Functions for opening / saving binary files and waves to disk
//
//****************************************************************
//****************************************************************

StrConstant NMVariablesFileName = "variables"
StrConstant NMWaveNotesFileName = "wavenotes"

StrConstant NMImageTypeList = "any;bmp;gif;jpeg;photoshop;pict;png;rpng;sgi;sunraster;targa;tiff;"

//StrConstant NMFileNameStrReplace = "ROI-,ROI;_POI_Dwell-4.0us,;_ChA,_A;_ChB,_B;_Trial-,;"

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFileCall( select )
	String select
	
	strswitch( select )
			
		case "Reload":
		case "Reload Data":
		case "Reload Waves":
			NMDataReloadCall()
			break
			
		case "Import":
		case "Import Data":
		case "Load":
		case "Load Waves":
			NMImportWavesCall()
			break
			
		case "Load From Folder":
		case "Load Waves From Folder":
			NMLoadAllWavesFromExtFolderCall()
			break
			
		case "Save":
		case "Save Waves":
			NMMainCall( "Save", "" )
			break
			
		case "Convert":
		case "Convert nmb to pxp":
			NMBin2IgorBinCall()
			break
			
		case "File Name Replace Strings":
			NMFileNameReplaceStringListEdit()
			break
			
	endswitch
	
End // NMFileCall

//****************************************************************
//****************************************************************
//****************************************************************
//
//	File utility functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S CheckNMPath() // find path to NeuroMatic Procedure folder

	Variable icnt
	String flist, fname, igor, path = ""
	
	PathInfo NMPath
	
	if ( V_flag == 1 )
		return S_path
	endif

	PathInfo Igor
	
	if ( V_flag == 0 )
		return ""
	endif
	
	igor = S_path + "Igor Procedures:"
	
	NewPath /O/Q NMPath, igor
	
	flist = IndexedDir( NMPath, -1, 0 ) // look for NM folder
	
	for ( icnt = 0; icnt < ItemsInList( flist ); icnt += 1 )
	
		fname = StringFromList( icnt, flist )
		
		if ( StrSearch( fname, "NeuroMatic", 0, 2 ) >= 0 )
			path = igor + fname + ":" // found it
			break
		endif
		
	endfor
	
	if ( strlen( path ) == 0 ) // try to locate NM alias
	
		flist = IndexedFile( NMPath, -1, "????" )
		
		for ( icnt = 0; icnt < ItemsInList( flist ); icnt += 1 )
		
			fname = StringFromList( icnt, flist )
			
			if ( StrSearch( fname, "NeuroMatic", 0, 2 ) >= 0 )
			
				//if ( IgorVersion() < 5 )
				//	NMDoAlert( "NM path cannot be determined. Try putting NM folder ( rather than alias ) in Igor Procedures folder." )
				//	break
				//endif
				
				GetFileFolderInfo /P=NMPath /Q/Z fname
				
				if ( V_isAliasShortcut == 1 )
					path = S_aliasPath
					break
				endif
				
			endif
			
		endfor
	
	endif
	
	NewPath /O/Q NMPath, path
	
	PathInfo /S Igor
	
	return path

End // CheckNMPath

//****************************************************************
//****************************************************************
//****************************************************************

Function KillNMPath()
	
	PathInfo igor
	
	if ( V_flag == 0 )
		return -1
	endif
	
	NewPath /O/Q NMPath, S_path
	
	KillPath /Z NMPath

End // KillNMPath

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMGetExternalFolderPath( message, defaultFolderPath )
	String message
	String defaultFolderPath
	
	String folderPath = ""
	
	if ( strlen( defaultFolderPath ) > 0 )
	
		NewPath /Q/O/Z NMGetExtFolderPath, defaultFolderPath
		
		if ( V_flag == 0 )
			PathInfo /S NMGetExtFolderPath
		else
			KillPath /Z NMGetExtFolderPath
			return ""
		endif
	
	endif
	
	NewPath /Q/O/M=( message ) NMGetExtFolderPath
	
	if ( V_flag == 0 )
		
		PathInfo NMGetExtFolderPath
		
		folderPath = S_path
		
	else
	
		KillPath /Z NMGetExtFolderPath
		
		return ""
		
	endif
	
	KillPath /Z NMGetExtFolderPath
	
	return folderPath

End // NMGetExternalFolderPath

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFileOpenDialogue( path, ext )
	String path // symbolic path name
	String ext // file extension; ( "" ) for FileBinExt ( ? ) for any

	Variable refnum, useDefaultPath = 0
	String fList = "", pathStr = "", type = "????"
	
	if ( strlen( ext ) == 0 )
		ext = ".pxp"
	endif
	
	strswitch( ext )
		case ".pxp":
			type = "IGsU????"
			break
		case ".txt":
			type = "TEXT"
			break
	endswitch
	
	if ( strlen( path ) > 0 )
	
		PathInfo /S $path
		
		if ( V_Flag == 1 )
			useDefaultPath = 0
		endif
	
	endif
	
	if ( useDefaultPath )
	
		pathStr = SpecialDirPath( "Documents", 0, 0, 0 )
	
		NewPath NMDefaultPath, pathStr
		
		PathInfo /S NMDefaultPath
	
	endif
	
	Open /R/D/M="Select one or more files to open"/MULT=1/T=type refnum // allows multiple selections
	
	fList = ReplaceString( "\r", S_fileName, ";" ) // replace carriage returns with semi-colon
	
	KillPath /Z NMDefaultPath
	
	if ( ItemsInList( fList ) == 1 )
		return StringFromList( 0, fList )
	else
		return fList // return file name list
	endif
	
End // NMFileOpenDialogue

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFileSaveDialogue( path, file, ext )
	String path // symbolic path name
	String file // for save dialogue
	String ext // file extension

	Variable refnum
	String type = "????"
	
	if ( strlen( ext ) > 0 )
		file = FileExtCheck( file, ext, 1 ) // check extension exists
	endif
	
	strswitch( ext )
		case ".pxp":
			type = "IGsU????"
			break
		case ".txt":
			type = "TEXT"
			break
	endswitch
	
	PathInfo /S $path

	Open /D/T=type refnum as NMChild( file )
	
	return S_fileName // return file name

End // NMFileSaveDialogue

//****************************************************************
//****************************************************************
//****************************************************************

Function FileExists( file ) // determine if file exists
	String file // file name
	
	Variable refnum
	
	if ( strlen( file ) == 0 )
		return 0
	endif
	
	Open /Z=1/R/T="????" refnum as file
	
	if ( refnum == 0 )
		return 0
	endif
	
	Close refnum
	
	return 1

End // FileExists

//****************************************************************
//****************************************************************
//****************************************************************

Function FileExistsAndNonZero( file ) // determine if file exists and contains bytes
	String file // file name
	
	Variable refnum
	Variable ok = 1
	
	if ( strlen( file ) == 0 )
		return 0
	endif
	
	Open /Z=1/R/T="????" refnum as file
	
	if ( refnum == 0 )
		
		return 0
	
	else
	
		FStatus refNum
		
		if ( V_logEOF == 0 )
			ok = 0
			NMHistory( "encountered empty file " + file )
		endif
	
	endif
	
	Close refnum
	
	return ok

End // FileExistsAndNonZero

//****************************************************************
//****************************************************************
//****************************************************************

Function /S FilePathCheck( path, file ) // combine path and file name
	String path, file
	
	PathInfo /S $path
	
	if ( V_Flag == 1 )
		return S_path + NMChild( file )
	else
		return file
	endif

End // FilePathCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function /S FileExtCheck( istring, ext, yes )
	String istring // string value, such as file name "myfile.txt"
	String ext // file extension such as ".txt"; ( ".*" ) for any ext
	Variable yes // ( 0 ) has no extension ( 1 ) has extension
	
	Variable icnt, ipnt = -1, sl = strlen( ext )
	
	yes = BinaryCheck( yes )
	
	for ( icnt = strlen( istring ) - 1; icnt >= 0; icnt -= 1 )
		if ( StringMatch( istring[ icnt, icnt ], "." ) )
			ipnt = icnt
		endif
		if ( StringMatch( istring[ icnt, icnt ], ":" ) )
			break
		endif
	endfor
	
	switch( yes )
	
		case 0:
			if ( StringMatch( ext, ".*" ) && ( ipnt >= 0 ) ) // any extension
				istring = istring[ 0, ipnt - 1 ] // remove extension
			elseif ( StringMatch( istring[ strlen( istring ) - sl, inf ], ext ) )
				istring = istring[ 0, strlen( istring ) - sl - 1 ] // remove extension
			endif
			break
			
		case 1:
			if ( ipnt >= 0 )
				istring = istring[ 0, ipnt-1 ] + ext // replace extension
			else
				istring += ext // add extension
			endif
			break
			
		default:
			return ""
			
	endswitch

	return istring

End // FileExtCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function /S FileExtGet( fileName )
	String fileName
	
	String ext = ParseFilePath( 0, NMChild( fileName ), ".", 1, 0)
	
	if ( strlen( ext ) > 0 )
		return "." + ext
	else
		return ""
	endif
	
End // FileExtGet

//****************************************************************
//****************************************************************
//****************************************************************

Function SeqNumFind( file ) // determine file sequence number, and its string index boundaries
	String file // file name
	
	Variable icnt, ibeg, iend, seqnum = Nan
	
	for ( icnt = strlen( file ) - 1; icnt >= 0; icnt -= 1 )
		if ( numtype( str2num( file[ icnt ] ) ) == 0 )
			break // first appearance of number, from right
		endif
	endfor
	
	iend = icnt
	
	for ( icnt = iend; icnt >= 0; icnt -= 1 )
		if ( numtype( str2num( file[ icnt ] ) ) == 2 )
			break // last appearance of number, from right
		endif
	endfor
	
	ibeg = icnt + 1
	
	seqnum = str2num( file[ ibeg, iend ] )
	
	Variable /G iSeqBgn = ibeg	// store begin/end placement of seq number
	Variable /G iSeqEnd = iend
	
	return seqnum

End // SeqNumFind

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SeqNumStr( file ) // get file sequence number as string
	String file // file name
	
	Variable icnt, ibeg, iend, seqnum = Nan
	
	for ( icnt = strlen( file ) - 1; icnt >= 0; icnt -= 1 )
		if ( numtype( str2num( file[ icnt, icnt ] ) ) == 0 )
			break // first appearance of number, from right
		endif
	endfor
	
	iend = icnt
	
	for ( icnt = iend; icnt >= 0; icnt -= 1 )
		if ( numtype( str2num( file[ icnt, icnt ] ) ) == 2 )
			break // last appearance of number, from right
		endif
	endfor
	
	ibeg = icnt + 1
	
	return file[ ibeg, iend ]

End // SeqNumStr

//****************************************************************
//****************************************************************
//****************************************************************

Function /S SeqNumSet( file, ibeg, iend, seqnum ) // create new file name, with new sequence number
	String file // original file name
	Variable ibeg // begin string index of sequence number ( iSeqBgn )
	Variable iend // end string index of sequence number ( iSeqEnd )
	Variable seqnum // new sequence number
	
	Variable icnt, jcnt
	
	icnt = iend - ibeg + 1
	
	jcnt = strlen( num2istr( seqnum ) )
	
	if ( jcnt <= icnt )
		ibeg = iend - jcnt + 1
		file[ ibeg, iend ] = num2istr( seqnum )
	else
		file = "overflow" // new sequence number does not fit within allowed index boundaries
	endif
	
	return file

End // SeqNumSet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S Seq2List( seqStr )
	String seqStr
	
	Variable icnt, jcnt, dash, from, to
	String item, seqList = ""
	
	if ( strlen( seqStr ) == 0 )
		return ""
	endif
	
	seqStr = ReplaceString( ",", seqStr, ";" )
	
	for ( icnt = 0; icnt < ItemsInList( seqStr ); icnt += 1 )
	
		item = StringFromList( icnt, seqStr )
		
		dash = strsearch( item, "-", 0 )
		
		if ( dash < 0 )
			seqList = AddListItem( item, seqList, ";", inf )
		else
		
			from = str2num( item[ 0, dash-1 ] )
			to = str2num( item[ dash+1, inf ] )
			
			if ( numtype( from * to ) > 0 )
				continue
			endif
			
			for ( jcnt = from; jcnt <= to; jcnt += 1 )
				seqList = AddListItem( num2istr( jcnt ), seqList, ";", inf )
			endfor
			
		endif
		
	endfor
	
	return seqList
	
End // Seq2List

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFileTypeNum( fileTypeStr )
	String fileTypeStr
	
	strswitch( fileTypeStr )
		case "NM":
		case "NM Binary":
			return 0
		case "Igor":
		case "Igor Binary":
			return 1
		case "Unpacked":
		case "Unpacked Folder":
			return 2
		case "H5":
		case "HDF5":
			return 3
	endswitch
	
	return NaN
	
End // NMFileTypeNum

//****************************************************************
//****************************************************************
//****************************************************************

Function NMWaveFileTypeNum( fileTypeStr )
	String fileTypeStr
	
	strswitch( fileTypeStr )
		case "Binary":
		case "Igor Binary":
			return 0
		case "Text":
		case "Igor Text":
			return 1
		case "General":
		case "General Text":
			return 2
		case "Delimited":
		case "Delimited Text":
			return 3
	endswitch
	
	return NaN
	
End // NMWaveFileTypeNum

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMWaveFileTypeExt( fileType )
	Variable fileType
	
	switch( fileType )
		case 0: // Igor Binary
			return ".ibw"
		case 1: // Igor Text
			return ".itx"
		case 2: // General Text
		case 3: // Delimited Text
			return ".txt"
	endswitch
	
	return ""
	
End // NMWaveFileTypeExt

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFileNameReplaceStringListEdit()

	Variable numItems, npnts, icnt, jcnt
	String itemStr, replaceThisStr, withThisStr
	
	String rName = "ReplaceThisStr"
	String wName = "WithThisStr"
	String tName = "NMFileNameReplaceStrings"
	String title = "NM Config FileNameReplaceStringList - Add Strings and Kill Window"
	
	String df = NMDF
	String replaceStringList = NMStrGet( "FileNameReplaceStringList" )
	
	STRUCT Rect w
	
	numItems = ItemsInList( replaceStringList, ";" )
	
	npnts = numItems + 5
	
	Make /O/N=( npnts )/T $df+rName = ""
	Make /O/N=( npnts )/T $df+wName = ""
	
	Wave /T rtemp = $df+rName
	Wave /T wtemp = $df+wName
	
	for ( icnt = 0 ; icnt < numItems ; icnt += 1 )
		
		itemStr = StringFromList( icnt, replaceStringList, ";" )
		
		replaceThisStr = StringFromList( 0, itemStr, "," )
		withThisStr = StringFromList( 1, itemStr, "," )
		
		if ( strlen( replaceThisStr ) > 0 )
			rtemp[ jcnt ] = replaceThisStr
			wtemp[ jcnt ] = withThisStr
			jcnt += 1
		endif
		
	endfor
	
	DoWindow /K $tName
	
	NMWinCascadeRect( w )
	Edit /K=1/N=$tName/W=(w.left,w.top,w.right,w.bottom) as title
	SetWindow $tName hook(NMFileNameRepStr)=NMFileNameReplaceStrTableHook
	
	AppendToTable /W=$tName rtemp, wtemp

End // NMFileNameReplaceStringListEdit

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFileNameReplaceStrListUpdate()

	Variable icnt

	String df = NMDF
	String rName = "ReplaceThisStr"
	String wName = "WithThisStr"
	String replaceStringList = ""
	
	Wave /T rtemp = $df+rName
	Wave /T wtemp = $df+wName
	
	if ( numpnts( rtemp ) != numpnts( wtemp ) )
		return -1
	endif
	
	for ( icnt = 0 ; icnt < numpnts( rtemp ) ; icnt += 1 )
	
		if ( strlen( rtemp[ icnt ] ) > 0 )
			replaceStringList += rtemp[ icnt ] + "," + wtemp[ icnt ] + ";"
		endif
	
	endfor
	
	NMHistory( "NM Config FileNameReplaceStringList = " + NMQuotes( replaceStringList ) )
	
	NMConfigStrSet( "NeuroMatic", "FileNameReplaceStringList", replaceStringList, history = 1 )

End // NMFileNameReplaceStrListUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMFileNameReplaceStrTableHook( s )
	STRUCT WMWinHookStruct &s
	
	switch( s.eventCode )
	
		case 1:
		case 2:
			NMFileNameReplaceStrListUpdate()
			break

	endswitch
	
	return 0

End // NMFileNameReplaceStrTableHook

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSaveWavesToDisk( wNameOrList, extFolderPath [ fileName, fileType, overWrite, saveWaveNames ] )
	String wNameOrList // wName, or list of wave names for General or Delimited text
	String extFolderPath // external folder path where to save waves
	String fileName // e.g. "RecordA0" ( if not passed, fileName is the first name in wNameOrList )
	String fileType // "Igor Binary" or "Igor Text"  or "General Text" or "Delimited Text"
	Variable overWrite // ( 0 ) no, default ( 1 ) yes ( be careful! )
	Variable saveWaveNames // ( 0 ) no ( 1 ) yes ( for General or Delimited text )
	
	Variable icnt, wcnt, ok, fType
	String wName, fileExt, fList, oList
	
	String path = "NMSaveWavesPath"

	if ( !WavesExist( wNameOrList ) )
		return ""
	endif
	
	if ( strlen( extFolderPath ) == 0 )
		extFolderPath = NMGetExternalFolderPath( "select folder to save waves", "" )
	endif
	
	if ( strlen( extFolderPath ) == 0 )
		return ""
	endif
	
	extFolderPath = LastPathColon( extFolderPath, 1 )
	
	if ( ParamIsDefault( fileType ) )
	
		if ( ItemsInList( wNameOrList ) > 1 )
			fileType = "Delimited Text"
		else
			fileType = "Igor Binary"
		endif
	
	endif
	
	fType = NMWaveFileTypeNum( fileType )
	
	if ( numtype( fType ) > 0 )
		return NM2ErrorStr( 20, "fileType", fileType )
	endif
	
	fileExt = NMWaveFileTypeExt( fType )
	
	if ( ParamIsDefault( fileName ) )
		wName = StringFromList( 0, wNameOrList )
		wName = NMChild( wName )
		fileName = wName + fileExt
	else
		fileName = NMChild( fileName )
		fileName = FileExtCheck( fileName, ".*", 0 ) // remove extension if it exists
		fileName += fileExt
	endif
	
	if ( ParamIsDefault( overWrite ) )
		overWrite = 0
	else
		overWrite = BinaryCheck( overWrite )
	endif
	
	if ( ParamIsDefault( saveWaveNames ) )
		saveWaveNames = 0
	else
		saveWaveNames = BinaryCheck( saveWaveNames )
	endif
	
	for ( icnt = 0; icnt < 4; icnt += 1 ) // 4 tries to enter new name
	
		if ( overWrite || !FileExists( extFolderPath + fileName ) )
			ok = 1
			break
		endif
		
		DoAlert /T=( "NM Save Waves To Disk" ) 2, "File " + NMQuotes( fileName ) + " already exists. Do you want to replace it?"
		
		if ( V_flag == 1 )
		
			ok = 1
			break
		
		elseif ( V_flag == 2 )
		
			Prompt fileName, "enter new file name:"
			DoPrompt NMPromptStr( "Save Waves" ), fileName
			
			if ( V_flag == 1 )
				return NMCancel
			endif
			
		elseif ( V_flag == 3 )
		
			return NMCancel
			
		endif
	
	endfor
	
	if ( !ok )
		return NMCancel
	endif
	
	NewPath /Q/O $path, extFolderPath
	
	if ( V_flag != 0 )
		return "" // error in creating path
	endif
	
	if ( fType < 2 )
	
		wName = StringFromList( 0, wNameOrList )
			
		if ( fType == 0 )
			Save /C/O/P=$path $wName as fileName
		elseif ( fType == 1 )
			Save /T/O/P=$path $wName as fileName
		else
			fileName = ""
		endif
		
	else
	
		if ( ItemsInList( wNameOrList ) == 1 )
		
			wName = StringFromList( 0, wNameOrList )
			
			if ( saveWaveNames )
			
				if ( fType == 2 )
					Save /G/O/P=$path/W $wName as fileName
				elseif ( fType == 3 )
					Save /J/O/P=$path/W $wName as fileName
				else
					fileName = ""
				endif
			
			else
			
				if ( fType == 2 )
					Save /G/O/P=$path $wName as fileName
				elseif ( fType == 3 )
					Save /J/O/P=$path $wName as fileName
				else
					fileName = ""
				endif
			
			endif
			
		elseif ( ItemsInList( wNameOrList ) > 1 )
		
			if ( saveWaveNames )
			
				if ( fType == 2 )
					Save /B/G/O/P=$path/W wNameOrList as fileName
				elseif ( fType == 3 )
					Save /B/J/O/P=$path/W wNameOrList as fileName
				else
					fileName = ""
				endif
			
			else
			
				if ( fType == 2 )
					Save /B/G/O/P=$path wNameOrList as fileName
				elseif ( fType == 3 )
					Save /B/J/O/P=$path wNameOrList as fileName
				else
					fileName = ""
				endif
			
			endif
			
		else
		
			fileName = ""
		
		endif
	
	endif
	
	KillPath /Z $path
	
	return fileName
	
End // NMSaveWavesToDisk

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Binary object file functions defined below...
// 	Igor 4 : NeuroMatic binary files
//	Igor 5 : Igor 5 packed binary files
//
//****************************************************************
//****************************************************************
//****************************************************************

Function FileBinLoadCurrent()

	if ( !DataFolderExists( "root:OpenFileTemp:" ) )
		NewDataFolder /O root:OpenFileTemp
	endif

	String CurrentFile = StrVarOrDefault( "CurrentFile", "" )
	
	String folder = NMFileBinOpen( 0, "?", "root:OpenFileTemp:", "", CurrentFile, 1, nmPrefix = 0 )
	
	if ( DataFolderExists( "root:OpenFileTemp:" ) )
		KillDataFolder root:OpenFileTemp:
	endif

End // FileBinLoadCurrent

//****************************************************************
//****************************************************************
//****************************************************************

Function /S CheckFileOpen( fileName )
	String fileName
	
	if ( !StringMatch( GetDataFolder( 0 ), "root" ) )
		return "" // not in root directory
	endif
	
	if ( strlen( fileName ) == 0 )
		fileName = GetDataFolder( 0 )
	endif

	if ( StringMatch( StrVarOrDefault( "FileType", "" ), "NMData" ) )
		return FileOpenFix2NM( fileName ) // move everything to subfolder
	else
		return ""
	endif

End // CheckFileOpen

//****************************************************************
//****************************************************************
//****************************************************************
//
//	FileOpenFix2NM : this program fixes NM folders which were
//	opened by double-clicking NM pxp folder, which Igor places
//	in root directory
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S FileOpenFix2NM( fileName ) // move opened NM folder to new subfolder
	String fileName
	
	Variable icnt
	String list, name
	
	if ( strlen( fileName ) == 0 )
		return "" // not allowed
	endif

	//String folder = "root:" + NMFolderNameCreate( fileName )
	String folder = "root:" + WinName( 0, 0 )
	
	folder = CheckFolderName( folder ) // get unused folder name

	if ( DataFolderExists( folder ) )
		return "" // not allowed
	endif
	
	list = FolderObjectList( "", 4 ) // df
	
	list = RemoveFromList( "WinGlobals;Packages;", list )
	
	NewDataFolder /O $RemoveEnding( folder, ":" )
	
	for ( icnt = 0; icnt < ItemsInList( list ); icnt += 1 )
		MoveDataFolder $StringFromList( icnt, list ), $folder
	endfor
	
	list = FolderObjectList( "", 1 ) // waves
	
	for ( icnt = 0; icnt < ItemsInList( list ); icnt += 1 )
		name = StringFromList( icnt, list )
		MoveWave $name, $( LastPathColon( folder, 1 ) + name )
	endfor
	
	list = FolderObjectList( "", 2 ) // variables
	
	for ( icnt = 0; icnt < ItemsInList( list ); icnt += 1 )
		name = StringFromList( icnt, list )
		MoveVariable $name, $( LastPathColon( folder, 1 ) + name )
	endfor
	
	list = FolderObjectList( "", 3 ) // strings
	
	for ( icnt = 0; icnt < ItemsInList( list ); icnt += 1 )
		name = StringFromList( icnt, list )
		MoveString $name, $( LastPathColon( folder, 1 ) + name )
	endfor
	
	NMFolderChange( folder )
	
	return folder
	
End // FileOpenFix2NM

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFileBinOpen( dialogue, extStr, parentFolder, path, fileList, changeFolder [ nmPrefix, logDisplay, history, quiet ] )
	Variable dialogue // ( 0 ) no ( 1 ) yes
	String extStr // file extension for open file dialogue; ( "" ) for FileBinExt ( ? ) for any
	String parentFolder // data folder path where to create data folders; ( "" ) for "root:"
	String path // symbolic path name (for open file dialogue)
	String fileList // string list of external file paths
	Variable changeFolder // change to this folder after opening file ( 0 ) no ( 1 ) yes
	Variable nmPrefix // ( 0 ) no ( 1 ) yes, force "nm" prefix when creating NM data folder
	Variable logDisplay // ( 1 ) notebook ( 2 ) table ( 3 ) both
	Variable history
	Variable quiet

	Variable icnt, fcnt, numFiles, bintype
	String file, extFolderPath, folder, folderPath, folderName, folderList = "", vList = "", df, promptStr = "NM File Open"
	
	if ( dialogue != 0 )
		fileList = NMFileOpenDialogue( path, extStr )
	endif
	
	numFiles = ItemsInList( fileList )

	if ( numFiles == 0 )
		return "" // nothing to open
	endif
	
	if ( strlen( parentFolder ) == 0 )
		parentFolder = "root:"
	endif
	
	if ( strlen( parentFolder ) > 0 )
		parentFolder = LastPathColon( parentFolder, 1 )
	endif
	
	for ( fcnt = 0; fcnt < numFiles; fcnt += 1 )
	
		if ( NMProgress( fcnt, numFiles, "Opening " + num2str( numFiles ) + " Data Files..." ) == 1 )
			break
		endif
		
		file = StringFromList( fcnt, fileList )
		
		if ( !dialogue && !FileExistsAndNonZero( file ) )
			continue
		endif
		
		folderName = NMFolderNameCreate( file, nmPrefix = nmPrefix, replaceStringList = NMStrGet( "FileNameReplaceStringList" ) )
		folderPath = parentFolder + folderName
	
		if ( DataFolderExists( folderPath ) )
		
			//DoAlert /T=( promptStr ) 2, "Alert: NM folder " + NMQuotes( folderName ) + " already exists. Do you want to replace it?"
			
			//if ( V_Flag == 1 )
			//	NMFolderClose( folderPath )
			//elseif ( V_Flag == 3 )
			//	return ""
			//endif
			
			folderName = FolderNameNext( folderName )
			folderPath = parentFolder + folderName
			
		endif
		
		if ( strsearch( file, ".nmb", 0 ) > 0 )
			
			bintype = 0
			
		elseif ( strsearch( file, ".pxp", 0 ) > 0 )
		
			bintype = 1
		
		elseif ( ( strsearch( file, ".h5", 0 ) > 0 ) || ( strsearch( file, ".hdf5", 0 ) > 0 ) )
		
			bintype = 4
			
			if ( !NMHDF5OK() )
				NMHDF5Allert()
				continue
			endif
		
		elseif ( ReadPclampFormat( file ) > 0 )
		
			bintype = 2
			
		elseif ( ReadAxographFormat( file ) > 0 )
		
			bintype = 3
			
		else
		
			NMDoAlert( "Error: file format not recognized for " + file, title = promptStr )
			
			continue
			
		endif
		
		vList = ""
		folder = ""
		
		switch( bintype )
			
			case 0: // old NM binary format
				folder = NMBinOpen( folderPath, file, "1111", changeFolder, nmPrefix = nmPrefix, history = history, quiet = quiet )
				break
				
			case 1: // Igor binary
				folder = IgorBinOpen( folderPath, file, changeFolder, nmPrefix = nmPrefix, logDisplay = logDisplay, convert2NM = 1, history = history, quiet = quiet )
				break
				
			case 2: // Pclamp
				NMImportFile( folderPath, file, nmPrefix = nmPrefix, history = history )
				break
			
			case 3: // Axograph
				NMImportFile( folderPath, file, nmPrefix = nmPrefix, history = history )
				break
				
			case 4: // HDF5
				folder = NMHDF5OpenFile( folderPath, file, changeFolder, nmPrefix = nmPrefix, history = history, quiet = quiet, convert2NM = 1 )
				break
		
		endswitch
		
		folderList = AddListItem( folder, folderList, ";", inf )
		
	endfor
	
	if ( ItemsInList( folderList ) == 1 )
		return StringFromList( 0, folderList )
	else
		return folderList
	endif
	
End // NMFileBinOpen

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMFolderSaveToDisk( [ folder, extFile, nmPrefix, fileType, waveFileType, new, closed, saveWaveNotes, saveSubfolders, nmbWriteFlag, dialogue, path, printCmd ] )
	String folder // data folder to save, default is current data folder
	String extFile // external file name; "" to create filename based on folder name
	Variable nmPrefix // ( 0 ) no ( 1 ) yes, force "nm" prefix when creating external file name
	String fileType // "NM" for NM binary, "Igor Binary" for Igor binary PXP, "unpacked" for Igor unpacked folder (see waveFileType), or "HDF5"
	String waveFileType // "Igor Binary" or "Igor Text"  or "General Text" or "Delimited Text"  ( used only if fileType = 2 )
	Variable new // ( 0 ) over-write existing file ( 1 ) create new file
	Variable closed // ( 0 ) save unclosed ( 1 ) save closed ( NM binary files only; allows appending )
	Variable saveWaveNotes // ( 0 ) no ( 1 ) yes [ used only if fileType = 2 ]
	Variable saveSubfolders // ( 0 ) no ( 1 ) yes [ used only if fileType = 2 ]
	String nmbWriteFlag // write flag for saving NM binary ( see zNMB_SaveFolder )
	Variable dialogue // ( 0 ) no ( 1 ) yes [ default ] ( be CAREFUL when using dialogue = 0 and new = 0 since this will over-write existing file )
	String path // path name for dialogue folder browser
	Variable printCmd // print command to Igor history ( 0 ) no ( 1 ) yes [ default ]
	
	Variable fType
	String vList = ""
	
	if ( ParamIsDefault( folder ) || ( strlen( folder ) == 0 ) )
		folder = CurrentNMFolder( 1 )
	elseif ( !DataFolderExists( folder ) )
		return NM2ErrorStr( 20, "folder", folder )
	endif
	
	if ( ParamIsDefault( extFile ) )
		extFile = ""
	endif
	
	if ( ParamIsDefault( fileType ) )
		fileType = "Igor Binary"
	endif
	
	fType = NMFileTypeNum( fileType )
	
	if ( numtype( fType ) > 0 )
		return NM2ErrorStr( 20, "fileType", fileType )
	endif
	
	if ( ( fType == 3 ) && !NMHDF5OK() )
		NMHDF5Allert()
		return ""
	endif
	
	if ( ParamIsDefault( new ) )
		new = 1
	else
		new = BinaryCheck( new )
	endif
	
	if ( ParamIsDefault( closed ) )
		closed = 1
	else
		closed = BinaryCheck( closed )
	endif
	
	if ( ParamIsDefault( saveWaveNotes ) )
		saveWaveNotes = 1
	else
		saveWaveNotes = BinaryCheck( saveWaveNotes )
	endif
	
	if ( ( ParamIsDefault( saveSubfolders ) ) && ( fType == 2 ) )
		saveSubfolders = 1
	else
		saveSubfolders = BinaryCheck( saveSubfolders )
	endif
	
	if ( ParamIsDefault( dialogue ) )
		dialogue = 1
	else
		dialogue = BinaryCheck( dialogue )
	endif
	
	if ( ParamIsDefault( path ) )
		path = ""
	endif
	
	if ( ParamIsDefault( nmbWriteFlag ) )
		nmbWriteFlag = "11111" // write all
	endif
	
	if ( ParamIsDefault( printCmd ) )
		printCmd = 1
	endif
	
	if ( !new )
		extFile = StrVarOrDefault( LastPathColon( folder, 1 ) + "CurrentFile", "" )
		path = ""
	endif
	
	if ( strlen( extFile ) == 0 )
		extFile = NMFolderNameCreate( folder, nmPrefix = nmPrefix )
	endif
	
	if ( strlen( extFile ) > 0 )
	
		if ( strlen( path ) > 0 )
			
			PathInfo /S $path
	
			if ( strlen( S_path ) == 0 )
				dialogue = 1
			endif
		
		endif
	
		if ( strlen( path ) > 0 )
			extFile = FilePathCheck( path, extFile )
		endif
	
		if ( fType == 0 )
			extFile = FileExtCheck( extFile, ".nmb", 1 ) // force this extension
		elseif ( fType == 1 )
			extFile = FileExtCheck( extFile, ".pxp", 1 ) // force this extension
		elseif ( fType == 2 )
			extFile = FileExtCheck( extFile, ".*", 0 ) // no extension
		elseif ( fType == 3 )
			extFile = FileExtCheck( extFile, ".h5", 1 ) // force this extension
		else
			return ""
		endif
	
	endif
	
	if ( !new && !FileExists( extFile ) )
		dialogue = 1
	elseif ( new && FileExists( extFile ) )
		dialogue = 1
	endif
	
	if ( dialogue )
	
		if ( fType == 0 )
			extFile = NMFileSaveDialogue( path, extFile, ".nmb" )
		elseif ( fType == 1 )
			extFile = NMFileSaveDialogue( path, extFile, ".pxp" )
		elseif ( fType == 2 )
			extFile = NMFileSaveDialogue( path, extFile, "" )
		elseif ( fType == 3 )
			extFile = NMFileSaveDialogue( path, extFile, ".h5" )
		endif
		
	endif
	
	if ( ( strlen( folder ) == 0 ) || ( strlen( extFile ) == 0 ) )
		return ""
	endif
	
	if ( printCmd )
	
		vList = NMCmdStrOptional( "folder", folder, vList )
		vList = NMCmdStrOptional( "extFile", extFile, vList )
		vList = NMCmdStrOptional( "fileType", fileType, vList )
		
		if ( fType == 2 )
			vList = NMCmdStrOptional( "waveFileType", waveFileType, vList )
		endif
		
		if ( !new )
			vList = NMCmdNumOptional( "new", new, vList )
		endif
		
		if ( !closed )
			vList = NMCmdNumOptional( "closed", closed, vList )
		endif
		
		if ( fType == 2 )
			vList = NMCmdNumOptional( "saveWaveNotes", saveWaveNotes, vList )
			vList = NMCmdNumOptional( "saveSubfolders", saveSubfolders, vList )
		endif
		
		vList = NMCmdNumOptional( "dialogue", 0, vList ) // no dialogue
		
		NMCmdHistory( "NMFolderSaveToDisk", vList ) // have users call this function rather than static functions below
		
	endif
	
	if ( fType == 3 ) // HDF5
	
		extFile = zHDF5_SaveFolder( folder, extFile )
	
	elseif ( fType == 2 ) // unpacked folder
	
		extFile = zSaveFolderUnpacked( folder, extFile, waveFileType, saveSubfolders, saveWaveNotes )
	
	elseif ( fType == 1 ) // Igor binary ( pxp )
	
		extFile = zPXP_SaveFolder( folder, extFile )
		
	elseif ( fType == 0 ) // NM binary ( nmb )
	
		if ( IsNMDataFolder( folder ) ) // special save function here
			
			extFile = zNMB_SaveFolderSpecial( folder, extFile, closed ) // save waves in Data subfolder
			
		else
		
			extFile = zNMB_SaveFolder( folder, extFile, nmbWriteFlag, closed ) // standard NM binary file
			
		endif
		
		if ( ( strlen( extFile ) > 0 ) && new )
			NMHistory( "Saved folder " + NMQuotes( folder ) + " to NeuroMatic binary file " + NMQuotes( extFile ) )
		endif
		
	endif

	SetNMstr( LastPathColon( folder,1 )+"CurrentFile", extFile )
	
	return extFile
	
End // NMFolderSaveToDisk

//****************************************************************
//****************************************************************
//****************************************************************
//
//	zSaveFolderUnpacked
//	save a data folder to disk as an unpacked folder
//	use NMFolderSaveToDisk to call this functions ( fileType = 2 )
//
//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zSaveFolderUnpacked( folder, extFolderPath, waveFileType, saveSubfolders, saveWaveNotes )
	String folder // data folder to save
	String extFolderPath // external folder path
	String waveFileType // "Igor Binary" or "Igor Text"  or "General Text" or "Delimited Text"
	Variable saveSubfolders // ( 0 ) no ( 1 ) yes
	Variable saveWaveNotes // ( 0 ) no ( 1 ) yes
	
	Variable error, icnt, iLimit
	String subfolderList
	
	String path = "NMSaveUnpackedPath"
	
	if ( !DataFolderExists( folder ) )
		return ""
	endif
	
	NewPath /O/Q/Z $path, extFolderPath
	
	if ( V_flag == 0 )
		
		DoAlert /T=( "Save Unpacked Folder" ) 1, "An external folder called " + NMQuotes( RemoveEnding( extFolderPath, ":" ) ) + " already exists. Do you want to continue?"
		
		if ( V_flag != 1 )
			KillPath /Z $path
			return ""
		endif
		
	endif
	
	extFolderPath = LastPathColon( extFolderPath, 1 )
	folder = LastPathColon( folder, 1 )
	
	error = zSaveFolderUnpacked2( folder, extFolderPath, waveFileType, saveWaveNotes )
	
	if ( error < 0 )
		return ""
	endif
	
	if ( saveSubfolders )
	
		subfolderList = zSaveFolderUnpackedSubs( folder, extFolderPath, waveFileType, saveWaveNotes )
		
		if ( !StringMatch( subfolderList, NMCancel ) && ( ItemsInList( subfolderList ) > 0 ) )
			subfolderList = ReplaceString( folder, subfolderList, "" )
			iLimit = 10
		endif
		
		for ( icnt = 0; icnt < iLimit; icnt += 1 ) // ten levels of subfolders
		
			subfolderList = zSaveFolderUnpackedSubs2( folder, extFolderPath, subfolderList, waveFileType, saveWaveNotes )
			
			if ( StringMatch( subfolderList, NMCancel ) || ( ItemsInList( subfolderList ) == 0 ) )
				break
			endif
			
			subfolderList = ReplaceString( folder, subfolderList, "" )
		
		endfor
		
	endif
	
	NMHistory( "Saved folder " + NMQuotes( folder ) + " to disk folder " + NMQuotes( extFolderPath ) )
	
	KillPath /Z $path
	
	return extFolderPath
	
End // zSaveFolderUnpacked

//****************************************************************
//****************************************************************
//****************************************************************

Static Function zSaveFolderUnpacked2( folder, extFolderPath, fileType, saveWaveNotes )
	String folder // data folder to save
	String extFolderPath // external folder path
	String fileType // "Igor Binary" or "Igor Text"  or "General Text" or "Delimited Text"
	Variable saveWaveNotes // ( 0 ) no ( 1 ) yes
	
	Variable icnt, ccnt, wcnt, refNum, folderExists, numChannels
	Variable isPrefixSubfolder
	String wName, wList, allList, varList, strList, objName, file, newFolder
	String xLabel, yLabel, strVarName, parent, txt
	
	String path = "NMSaveUnpackedPath"
	String saveDF = GetDataFolder( 1 )
	String shortName = NMChild( folder )
	
	STRUCT NMXAxisStruct s
	
	if ( strsearch( shortName, NMPrefixSubfolderPrefix, 0 ) == 0 )
		isPrefixSubfolder = 1
	endif
	
	extFolderPath = LastPathColon( extFolderPath, 1 )
	
	if ( !DataFolderExists( folder ) )
		return -1
	endif
	
	NewPath /C/O/Q/Z $path, extFolderPath
	
	SetDataFolder $folder
	
	wList = WaveList( "*", ";", "" )
	
	for ( icnt = 0; icnt < ItemsInList( wList ); icnt += 1 )
		
		objName = StringFromList( icnt, wList )
		
		file = NMSaveWavesToDisk( objName, extFolderPath, fileType = fileType )
		
		if ( StringMatch( file, NMCancel ) )
			return -2
		endif
	
	endfor
	
	if ( saveWaveNotes && ( ItemsInList( wList ) > 0 ) )
	
		NewPath /Q/O $path, extFolderPath
	
		if ( V_flag == 0 )
		
			Open /P=$path refNum as NMWaveNotesFileName + ".txt" // open file for writing
			
			for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
				
				wName = StringFromList( wcnt, wList )
				txt = note( $wName )
				
				if ( strlen( txt ) > 0 )
					fprintf refNum, wName + NMCR
					fprintf refNum, txt + NMCR + NMCR
				endif
				
			endfor
		
			Close refNum
			
		endif
	
	endif
	
	varList = VariableList( "*",";",4 )
	strList = StringList( "*",";" )
	
	if ( isPrefixSubfolder || ( ItemsInList( varList ) > 0 ) || ( ItemsInList( strList ) > 0 ) )
	
		Open /P=$path refNum as NMVariablesFileName + ".txt" // open file for writing
		
		for ( icnt = 0; icnt < ItemsInList( varList ); icnt += 1 )
		
			objName = StringFromList( icnt, varList )
			
			NVAR vtemp = $objName
			
			fprintf refNum, "%s=%g" + NMCR, objName, vtemp
		
		endfor
		
		if ( isPrefixSubfolder ) // add parameters that currently exist in wave notes
		
			folder = LastPathColon( folder, 1 )
			parent = NMParent( folder )
		
			numChannels = NumVarOrDefault( folder + "NumChannels", 0 )
			
			if ( numChannels > 0 )
			
				allList = ""
				
				for ( ccnt = 0; ccnt < numChannels; ccnt += 1 )
				
					strVarName = folder + NMChanWaveListPrefix + ChanNum2Char( ccnt )
					wList = StrVarOrDefault( strVarName, "" )
					
					for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
						allList += parent + StringFromList( wcnt, wList ) + ";"
					endfor
					
				endfor
	
				NMXAxisStructInit( s, allList )
				NMXAxisStats2( s )
			
				fprintf refNum, "NumPnts=%g" + NMCR, s.points
				fprintf refNum, "StartX=%g" + NMCR, s.leftx
				fprintf refNum, "DeltaX=%g" + NMCR, s.dx
				
				xLabel = NMChanLabelXAll( prefixFolder = folder )
				
				fprintf refNum, "xLabel=\"%s\"" + NMCR, xLabel
				
				for ( ccnt = 0; ccnt < numChannels; ccnt += 1 )
					yLabel = NMChanLabelY( prefixFolder = folder, channel = ccnt )
					fprintf refNum, "yLabel" + ChanNum2Char( ccnt ) + "=\"%s\"" + NMCR, yLabel
				endfor
			
			endif
		
		endif
		
		for ( icnt = 0; icnt < ItemsInList( strList ); icnt += 1 )
		
			objName = StringFromList( icnt, strList )
			
			SVAR stemp = $objName
			
			fprintf refNum, "%s=\"%s\"" + NMCR, objName, stemp
		
		endfor
		
		Close refNum
		
	endif
	
	SetDataFolder $saveDF
	
	KillPath /Z $path
	
	return 0 // OK
	
End // zSaveFolderUnpacked2

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zSaveFolderUnpackedSubs( folder, extFolderPath, waveFileType, saveWaveNotes )
	String folder
	String extFolderPath
	String waveFileType
	Variable saveWaveNotes
	
	Variable icnt, error
	String subfolder, fList = ""
	
	String subfolderList = FolderObjectList( folder, 4 )
			
	for ( icnt = 0; icnt < ItemsInList( subfolderList ); icnt += 1 )
	
		subfolder = StringFromList( icnt, subfolderList )
		
		error = zSaveFolderUnpacked2( folder + subfolder, extFolderPath + subfolder, waveFileType, saveWaveNotes )
		
		if ( error == -1 )
			continue
		elseif ( error == -2 )
			return NMCancel
		elseif ( error == 0 )
			fList = NMAddToList( folder + subfolder, fList, ";" )
		endif
		
	endfor
	
	return fList
	
End // zSaveFolderUnpackedSubs

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zSaveFolderUnpackedSubs2( folder, extFolderPath, subfolderList, waveFileType, saveWaveNotes )
	String folder
	String extFolderPath
	String subfolderList
	String waveFileType
	Variable saveWaveNotes
	
	Variable icnt
	String subfolder, sList, fList = ""
	
	for ( icnt = 0; icnt < ItemsInList( subfolderList ); icnt += 1 )
			
		subfolder = StringFromList( icnt, subfolderList )
		
		sList = zSaveFolderUnpackedSubs( folder + subfolder + ":", extFolderPath + subfolder + ":", waveFileType, saveWaveNotes )
		
		if ( StringMatch( sList, NMCancel ) )
			return NMCancel
		endif
		
		fList = NMAddToList( sList, fList, ";" )
		
	endfor
	
	return fList
	
End // zSaveFolderUnpackedSubs2

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Igor binary object file functions defined below...
//	requires Igor 5 LoadData and SaveData
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S IgorBinOpen( folder, extFile, changeFolder [ nmPrefix, convert2NM, logDisplay, history, quiet ] ) // open Igor packed binary file
	String folder // data folder path where to open folder, ( "" ) or ( "root:" ) to auto create in root
	String extFile // external file name
	Variable changeFolder // change to this folder after opening file ( 0 ) no ( 1 ) yes
	Variable nmPrefix // ( 0 ) no ( 1 ) yes, force "nm" prefix when creating NM data folder
	Variable convert2NM // ( 0 ) no ( 1 ) yes, create NM variables if they are missing
	Variable logDisplay // ( 1 ) notebook ( 2 ) table ( 3 ) both
	Variable quiet
	Variable history
	
	String vlist = ""
	
	vList = NMCmdStr( folder, vList )
	vList = NMCmdStr( extFile, vList )
	vList = NMCmdNum( changeFolder, vList, integer = 1 )
	
	if ( ParamIsDefault( nmPrefix ) )
		nmPrefix = 1
	else
		vlist = NMCmdNumOptional( "nmPrefix", nmPrefix, vlist )
	endif
	
	if ( ParamIsDefault( convert2NM ) )
		convert2NM = 1
	endif
				
	if ( history )
		NMCommandHistory( vList )
	endif
	
	changeFolder = BinaryCheck( changeFolder )
	
	if ( ( strlen( folder ) == 0 ) || StringMatch( folder, "root:" ) )
		folder = "root:" + NMFolderNameCreate( extFile, nmPrefix = nmPrefix, replaceStringList = NMStrGet( "FileNameReplaceStringList" ) )
	endif
	
	folder = CheckFolderName( folder ) // get unused folder name

	if ( ( strlen( extFile ) == 0 ) || ( strlen( folder ) == 0 ) || DataFolderExists( folder ) )
		return "" // not allowed
	endif

	String saveDF = GetDataFolder( 1 )
	
	NewDataFolder /O/S $RemoveEnding( folder, ":" )
	LoadData /O/Q/R extFile
	
	KillVariables /Z V_Progress // LoadData seems to create this variable - but this creates bug for progress window
	
	SetNMstr( "DataFileType", "IgorBin" )
	SetNMstr( "CurrentFile", extFile )
	
	String ftype = StrVarOrDefault( "FileType", "" )
	
	if ( !quiet )
		NMHistory( "Opened Igor binary file " + NMQuotes( extFile ) + " to folder " + NMQuotes( folder ) )
	endif
	
	if ( StringMatch( ftype, "NMLog" ) )
	
		if ( logDisplay == 0 )
			LogDisplayCall( folder )
		else
			NMLogDisplay( folder, logDisplay, history = 1 )
		endif
		
		changeFolder = 0
		
	elseif  ( StringMatch( ftype, "NMData" ) || convert2NM )
		CheckNMDataFolder( folder )
		NMFolderListAdd( folder )
		if ( !quiet )
			PrintNMFolderDetails( folder )
		endif
	endif
	
	SetDataFolder $saveDF // back to original data folder
	
	if ( changeFolder )
		NMFolderChange( folder )
	endif
	
	return folder
	
End // IgorBinOpen

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zPXP_SaveFolder( folder, extFile ) // save Igor packed binary file ( pxp )
	String folder // data folder to save
	String extFile // external file name
	
	// use NMFolderSaveToDisk to call this functions ( fileType = 1 )
	
	if ( !DataFolderExists( folder ) )
		return ""
	endif
 
 	//String /G S_path
	String saveDF = GetDataFolder( 1 )
	String thisFxn = GetRTStackInfo( 1 )
	
	SetDataFolder $folder
	SaveData /O/Q/R extFile
	
	if ( V_flag > 0 )
		NMDoAlert( thisFxn + " Error: failed to save " + folder + " to external file " + extFile )
	else
		NMHistory( "Saved folder " + NMQuotes( folder ) + " to Igor binary file " + NMQuotes( extFile ) )
	endif
	
	//if ( strlen( S_path ) > 0 )
	//	file = S_path
	//endif
	
	KillVariables /Z V_Flag
	
	SetDataFolder $saveDF
	
	if ( strlen( extFile ) > 0 )
		
	endif
	
	return extFile

End // zPXP_SaveFolder

//****************************************************************
//****************************************************************
//****************************************************************
//
//	HDF5 functions defined below...
//	requires HDF5.XOP
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMHDF5OK()

	return ( exists( "HDF5CreateFile" ) == 4 )

End // NMHDF5OK

//****************************************************************
//****************************************************************
//****************************************************************

Function NMHDF5Allert()

	String helpTopic = "Installing The HDF5 Package"

	String txt1 = "To save/open HDF5 files you need to install the HDF5 XOP provided by WaveMetrics. "
	String txt2 = "See Igor Help Topic: " + helpTopic

	NMDoAlert( txt1 + txt2, title = "How to activate the HDF5 XOP" )
	DisplayHelpTopic helpTopic

End // NMHDF5Allert

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMHDF5OpenFile( folder, extFile, changeFolder [ nmPrefix, history, quiet, convert2NM ] ) // open HDF5 file
	String folder // data folder path where to open folder, ( "" ) or ( "root:" ) to auto create in root
	String extFile // external file name
	Variable changeFolder // change to this folder after opening file ( 0 ) no ( 1 ) yes
	Variable nmPrefix // ( 0 ) no ( 1 ) yes, force "nm" prefix when creating NM data folder
	Variable quiet
	Variable history
	Variable convert2NM // ( 0 ) no ( 1 ) yes, create NM variables if they are missing
	
	Variable error = 0
	String vlist = ""
	
	if ( !NMHDF5OK() )
		NMHDF5Allert()
		return ""
	endif
	
	vList = NMCmdStr( folder, vList )
	vList = NMCmdStr( extFile, vList )
	vList = NMCmdNum( changeFolder, vList, integer = 1 )
	
	if ( ParamIsDefault( nmPrefix ) )
		nmPrefix = 1
	else
		vlist = NMCmdNumOptional( "nmPrefix", nmPrefix, vlist )
	endif
	
	if ( ParamIsDefault( convert2NM ) )
		convert2NM = 1
	endif
				
	if ( history )
		NMCommandHistory( vList )
	endif
	
	changeFolder = BinaryCheck( changeFolder )
	
	if ( ( strlen( folder ) == 0 ) || StringMatch( folder, "root:" ) )
		folder = "root:" + NMFolderNameCreate( extFile, nmPrefix = nmPrefix, replaceStringList = NMStrGet( "FileNameReplaceStringList" ) )
	endif
	
	folder = CheckFolderName( folder ) // get unused folder name

	if ( ( strlen( extFile ) == 0 ) || ( strlen( folder ) == 0 ) || DataFolderExists( folder ) )
		return "" // not allowed
	endif

	String saveDF = GetDataFolder( 1 )
	
	Variable V_flag
	
	NewDataFolder /O/S $RemoveEnding( folder, ":" )
	
	Variable /G HDF5_fileID
	
	Execute /Z "HDF5OpenFile /R/Z HDF5_fileID as " + NMQuotes( extFile )
	
	if ( V_flag != 0 )
		error = 1
		NMErr( "failed to open HDF5 file : " + extFile )
	endif
	
	if ( !error )
	
		Execute /Z "HDF5LoadGroup /IGOR=-1 /O/R/Z :, HDF5_fileID, " + NMQuotes( "." )
		
		if ( V_flag != 0 )
			error = 1
			NMErr( "failed to load data from HDF5 file : " + extFile )
		endif
	
	endif
	
	//Execute /Z "HDF5CloseFile /Z HDF5_fileID" // THIS CAUSES ERROR
	Execute /Z "HDF5CloseFile /A"
	
	if ( !error && ( V_flag != 0 ) )
		NMErr( "failed to close HDF5 file : " + extFile )
	endif
	
	KillVariables /Z HDF5_fileID
	
	if ( error )
		KillDataFolder $RemoveEnding( folder, ":" )
		SetDataFolder $saveDF // back to original data folder
		return ""
	endif
	
	SetNMstr( "DataFileType", "HDF5" )
	SetNMstr( "CurrentFile", extFile )
	
	String ftype = StrVarOrDefault( "FileType", "" )
	
	if ( !quiet )
		NMHistory( "Opened Igor binary file " + NMQuotes( extFile ) + " to folder " + NMQuotes( folder ) )
	endif
	
	if ( StringMatch( ftype, "NMLog" ) )
		LogDisplayCall( folder )
		changeFolder = 0
	elseif  ( StringMatch( ftype, "NMData" ) || convert2NM )
		CheckNMDataFolder( folder )
		NMFolderListAdd( folder )
		if ( !quiet )
			PrintNMFolderDetails( folder )
		endif
	endif
	
	SetDataFolder $saveDF // back to original data folder
	
	if ( changeFolder )
		NMFolderChange( folder )
	endif
	
	return folder
	
End // NMHDF5OpenFile

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zHDF5_SaveFolder( folder, extFile ) // save folder in HDF5 format
	String folder // data folder to save
	String extFile // external file name, full path
	
	// use NMFolderSaveToDisk to call this functions ( fileType = 3 )
	
	Variable error = 0
	
	if ( !NMHDF5OK() )
		NMHDF5Allert()
		return ""
	endif
	
	if ( !DataFolderExists( folder ) )
		return ""
	endif
	
	String extFolderPath = NMParent( extFile )
	String fileName = NMChild( extFile )
	
	Variable /G HDF5_fileID

	Execute /Z "HDF5CreateFile /O/Z HDF5_fileID as " + NMQuotes( extFile )
	
	if ( V_flag != 0 )
		error = 1
		NMErr( "failed to create HDF5 file : " + extFile )
	endif
	
	if ( !error )
	
		Execute /Z "HDF5SaveGroup /IGOR=-1 /O/R/Z " + folder + ", HDF5_fileID, " + NMQuotes( "." )
		
		if ( V_flag != 0 )
			error = 1
			NMErr( "failed to create HDF5 file : " + extFile )
		endif
	
	endif
	
	//Execute /Z "HDF5CloseFile /Z HDF5_fileID" // THIS CAUSES ERROR
	Execute /Z "HDF5CloseFile /A"
	
	if ( !error && ( V_flag != 0 ) )
		NMErr( "failed to close HDF5 file : " + extFile )
	endif
	
	KillVariables /Z HDF5_fileID
	
	if ( error )
		return ""
	endif
	
	NMHistory( "Saved folder " + NMQuotes( folder ) + " to HDF5 file " + NMQuotes( extFile ) )
	
	return extFile

End // zHDF5_SaveFolder

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Functions for saving a data folder as a NeuroMatic bineary ( NMB ) file
//	Used only with Clamp tab for data acquisition.
//	Created before it was possible to save data folders in PXP format.
//	Maintained since it allows "Save While Recording" option 
//	and reading NMB files.
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMBin2IgorBinCall()

	Variable select
	String path, fileList
	
	fileList = NMFileOpenDialogue( "OpenDataPath", ".nmb" )

	if ( ItemsInList( fileList ) == 0 )
		return -1
	endif
	
	NMBin2IgorBin( path, fileList, history = 1 ) // this folder only

End // NMBin2IgorBinCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMBin2IgorBin( path, fileList [ nmPrefix, history ] ) // open NM bin file and save as Igor bin file
	String path // path
	String fileList // file list
	Variable nmPrefix // ( 0 ) no ( 1 ) yes, force "nm" prefix when creating NM data folder
	Variable history

	Variable icnt
	String file, oname, sname, folder, vlist = ""
	
	vList = NMCmdStr( path, vList )
	vList = NMCmdStr( fileList, vList )
	
	if ( ParamIsDefault( nmPrefix ) )
		nmPrefix = 1
	else
		vlist = NMCmdNumOptional( "nmPrefix", nmPrefix, vlist )
	endif
	
	if ( history )
		NMCommandHistory( vList )
	endif
	
	for ( icnt = 0; icnt < ItemsInList( fileList ); icnt += 1 )
	
		file = path + StringFromlist( icnt, fileList )
		
		folder = "root:" + NMFolderNameCreate( file, nmPrefix = nmPrefix, replaceStringList = NMStrGet( "FileNameReplaceStringList" ) ) // get folder name
		folder = CheckFolderName( folder ) // get unused folder name
		
		if ( strlen( folder ) == 0 )
			return 0 // cancel
		endif
		
		oname = NMBinOpen( folder, file, "1111", 0 )
		
		if ( strlen( oname ) == 0 )
			continue // cancel
		endif
		
		sname = NMFolderSaveToDisk( folder = oname, extFile = NMChild( oname ), dialogue = 0, path = "OpenDataPath" )
		
		if ( strlen( sname ) > 0 )
			NMHistory( "Converted NM binary file " + NMQuotes( file ) + " to Igor binary file " +NMQuotes( sname ) )
		endif
		
		KillDataFolder /Z $oname
	
	endfor

End // NMBin2IgorBin

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMBinOpen( folder, file, makeflag, changeFolder [ nmPrefix, history, quiet ] )
	String folder // folder name where file objects are loaded, ( "" ) or ( "root:" ) to auto create folder in root 
	String file // external file name
	String makeflag // text waves | numeric waves | numeric variables | string variables
	Variable changeFolder // change to this folder after opening file ( 0 ) no ( 1 ) yes
	Variable nmPrefix // ( 0 ) no ( 1 ) yes, force "nm" prefix when creating NM data folder
	Variable history
	Variable quiet
	
	Variable wcnt
	String wList, wName, vlist = ""
	
	vList = NMCmdStr( folder, vList )
	vList = NMCmdStr( file, vList )
	vList = NMCmdStr( makeflag, vList )
	vList = NMCmdNum( changeFolder, vList, integer = 1 )
	
	if ( ParamIsDefault( nmPrefix ) )
		nmPrefix = 1
	else
		vlist = NMCmdNumOptional( "nmPrefix", nmPrefix, vlist )
	endif
	
	if ( history )
		NMCommandHistory( vList )
	endif
	
	changeFolder = BinaryCheck( changeFolder )
	
	if ( ( strlen( folder ) == 0 ) || StringMatch( folder, "root:" ) )
		folder = "root:" + NMFolderNameCreate( file, nmPrefix = nmPrefix, replaceStringList = NMStrGet( "FileNameReplaceStringList" ) )
	endif
	
	folder = CheckFolderName( folder ) // get unused folder name
	
	if ( DataFolderExists( folder ) )
		return "" // folder must not exist
	endif
	
	if ( strlen( file ) == 0 )
		return "" // not allowed
	endif
	
	if ( !FileExistsAndNonZero( file ) || ( strlen( zNMB_FileType( file ) ) == 0 ) )
		NMDoAlert( "Error: file " + NMQuotes( file ) + " is not a NeuroMatic binary file.", title = "NM Open File" )
		return "" // not a NM binary file
	endif

	String saveDF = GetDataFolder( 1 ) // save current directory
	
	NewDataFolder /O/S $RemoveEnding( folder, ":" ) // open new folder
	
	zNMB_ReadObject( file, makeflag ) // read data
	
	SetDataFolder $folder
	
	SetNMstr( "DataFileType", "NMBin" )
	SetNMstr( "CurrentFile", file )
	
	if ( !quiet )
		NMHistory( "Opened NeuroMatic binary file " + NMQuotes( file ) + " to folder " + NMQuotes( folder ) )
	endif
	
	String df = LastPathColon( folder, 1 ) + "Data:"
	String ftype = StrVarOrDefault( "FileType", "" )
	
	strswitch( ftype )
	
		case "NMLog":
			LogDisplayCall( folder )
			changeFolder = 0
			break
			
		case "NMData":
			
			if ( DataFolderExists( df ) )
			
				// folder was created by Clamp tab
				// waves stored in folder "Data"
				
				wList = NMFolderWaveList( df, "*", ";", "", 0 )
				
				for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
					
					wName = StringFromList( wcnt, wList )
					
					Duplicate /O $( df + wName ), $( LastPathColon( folder, 1 ) + wName )
				
				endfor
				
				if ( CountObjects( df, 1 ) == 0 )
					KillDataFolder RemoveEnding( df, ":" )
				endif
				
			endif
			
			CheckNMDataFolder( folder )
			NMFolderListAdd( folder )
			
			if ( !quiet )
				PrintNMFolderDetails( folder )
			endif
			
			break
			
	endswitch
	
	if ( !changeFolder )
		SetDataFolder $saveDF // back to original data folder
	else
		NMFolderChange( folder )
	endif
	
	return folder
	
End // NMBinOpen

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zNMB_SaveFolder( folder, file, writeflag, closed )
	String folder // data folder name
	String file // external file name
	String writeflag // string variables | numeric variables | text waves | numeric waves | subfolders
	// "11111" to write all
	// "00011" to write numeric waves, all folders
	Variable closed // ( 0 ) save unclosed ( 1 ) save and close
	
	// use NMFolderSaveToDisk to call this functions ( fileType = 0 )

	Variable ocnt
	String objName, olist
	
	if ( strlen( folder ) == 0 )
		return ""
	endif
	
	if ( !DataFolderExists( folder ) )
		NMDoAlert( "Data folder " + NMQuotes( folder ) + " does not exist.", title = "Save NM Binary File" )
		return ""
	endif

	String saveDF = GetDataFolder( 1 ) // save current directory
	
	folder = RemoveEnding( folder, ":" )
	
	SetDataFolder $folder
	
	zNMB_WriteObject( file, 1, "" ) // open new
	
	zNMB_WriteGlobals( file, writeflag )
	
	if ( StringMatch( writeflag[ 4, 4 ], "1" ) )
	
		olist = FolderObjectList( "", 4 ) // subfolder list
	
		for ( ocnt =0; ocnt < ItemsInList( olist ); ocnt += 1 ) // loop thru subfolders
			objName = StringFromList( ocnt, olist )
			zNMB_WriteObject( file, 2, objName )
			SetDataFolder $folder + ":" + objName
			zNMB_WriteGlobals( file, writeflag )
			SetDataFolder $folder
		endfor
		
	endif
	
	if ( closed )
		zNMB_WriteObject( file, 3, "" ) // close
	endif
	
	SetDataFolder $saveDF // back to original data folder
	
	return file
	
End // zNMB_SaveFolder

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zNMB_SaveFolderSpecial( folder, file, closed ) // creates a Data subfolder to hold data waves
	String folder, file
	Variable closed
	
	// Use NMFolderSaveToDisk to call this function
	
	Variable kill

	if ( !DataFolderExists( "Data" ) )
		NewDataFolder /O Data // create an empty data folder
		// upon opening, data waves will appear in Data subfolder
		kill = 1
	endif
	
	if ( !closed )
	
		zNMB_SaveFolder( folder, file, "11111", 0 ) // NM binary file unclosed
		
	else
	
		file = zNMB_SaveFolder( folder, file, "11121", 0 ) // save all except data waves, unclosed
		
		if ( strlen( file ) > 0 )
			zNMB_WriteGlobals( file, "0003" ) // save data waves last
			zNMB_WriteObject( file, 3, "" ) // EOF marker, close file
		endif
		
	endif
	
	if ( kill )
		KillDataFolder Data
	endif
	
	return file

End // zNMB_SaveFolderSpecial

//****************************************************************
//****************************************************************
//****************************************************************

Static Function zNMB_WriteGlobals( file, writeflag )
	String file // external file name
	String writeflag // string variables | numeric variables | text waves | numeric waves
	// number waves ( 0 ) dont write ( 1 ) write all waves ( 2 ) all waves except data waves ( 3 ) only data waves

	Variable ocnt, icnt, wflag
	String objName, olist, clist = ""
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) > 0 )
	
		for ( icnt = 0; icnt < NMNumChannels(); icnt += 1 )
			clist += NMChanWaveList( icnt )
		endfor
		
	endif
	
	if ( StringMatch( writeflag[ 0, 0 ], "1" ) ) // string variables
	
		olist = FolderObjectList( "", 3 )
		
		if ( WhichListItem( "FileType", olist, ";", 0, 0 ) > 0 ) // make sure FileType is first
			olist = RemoveFromList( "FileType", olist )
			olist = AddListItem( "FileType", olist ) // add back to beginning of list
		endif
		
		zNMB_WriteObject( file, 2, olist )
	
	endif
	
	if ( StringMatch( writeflag[ 1, 1 ], "1" ) ) // numeric variables
		olist = FolderObjectList( "", 2 )
		zNMB_WriteObject( file, 2, olist )
	endif
	
	if ( StringMatch( writeflag[ 2, 2 ], "1" ) ) // text waves
		olist = FolderObjectList( "", 6 )
		zNMB_WriteObject( file, 2, olist )
	endif
	
	wflag = str2num( writeflag[ 3, 3 ] )
	
	if ( wflag > 0 ) // numeric waves
	
		olist = FolderObjectList( "", 5 )
		
		if ( wflag > 1 ) // subset of waves
		
			for ( ocnt = 0; ocnt < ItemsInlist( olist ); ocnt += 1 )
			
				objName = StringFromList( ocnt, olist )
				
				if ( ( wflag == 2 ) && ( WhichListItem( objName, clist, ";", 0, 0 ) >= 0 ) )
					olist = RemoveFromList( objName, olist ) // except data waves
				elseif ( ( wflag == 3 ) && ( WhichListItem( objName, clist, ";", 0, 0 ) < 0 ) )
					olist = RemoveFromList( objName, olist ) // only data waves
				endif
			
			endfor
		
		endif

		zNMB_WriteObject( file, 2, olist )
	
	endif
	
End // zNMB_WriteGlobals

//****************************************************************
//****************************************************************
//****************************************************************

Function zNMB_WriteObject( file, openflag, olist ) // leave non-static - called from ClampNMbinAppend()
	String file // file name
	Variable openflag // ( 1 ) open new ( 2 ) append ( 3 ) append then close ( -1 objtype )
	String olist // object name list

	Variable ocnt, icnt, jcnt, nobjchar, opnts, otype, slength, refnum
	String objName, dumstr, wnote
	
	Variable /G dumvar
	
	if ( strlen( file ) == 0 )
		return -1
	endif
	
	if ( openflag == 1 )
		Open /T="IGBW" refnum as file
	elseif ( ( openflag == 2 ) || ( openflag == 3 ) )
		Open /A/T="IGBW" refnum as file
	else
		return -1
	endif
	
	for ( ocnt = 0; ocnt < ItemsInList( olist ); ocnt += 1 )
	
		objName = StringFromList( ocnt, olist )
		otype = zNMB_ObjectType( objName )
		
		if ( ( otype < 0 ) || ( otype > 4 ) )
			continue
		endif
		
		dumvar = otype
		FBinWrite /B=2/F=1 refnum, dumvar
		
		zNMB_WriteString( refnum, objName )
		
		switch( otype )
		
			case 0: // text wave ( 1D )
				Wave /T tWave = $objName
				zNMB_WriteString( refnum, note( tWave ) ) // write wave note
				
				opnts = numpnts( tWave ); dumvar = opnts
				FBinWrite /B=2/F=3 refnum, dumvar // write numpnts
				
				for ( icnt = 0; icnt < opnts; icnt += 1 ) // write wave points
					zNMB_WriteString( refnum, tWave[ icnt ] )
				endfor
				break
				
			case 1: // numeric wave ( 1D )
				Wave nWave = $objName
				zNMB_WriteString( refnum, note( nWave ) ) // write wave note
				
				dumvar = leftx( nWave )
				FBinWrite /B=2/F=4 refnum, dumvar // write leftx scaling
				
				dumvar = deltax( nWave )
				FBinWrite /B=2/F=4 refnum, dumvar // write deltax scaling
				
				opnts = numpnts( nWave ); dumvar = opnts
				FBinWrite /B=2/F=3 refnum, dumvar // write numpnts
				
				for ( icnt = 0; icnt < opnts; icnt += 1 ) // write wave points
					dumvar = nWave[ icnt ]
					FBinWrite /B=2/F=4 refnum, dumvar
				endfor
				break
				
			case 2: // numeric variable
				dumvar = NumVarOrDefault( objName, Nan )
				FBinWrite /B=2/F=4 refnum, dumvar
				break
				
			case 3: // string variable 
				zNMB_WriteString( refnum, StrVarOrDefault( objName, "" ) )
				break
				
			case 4: // folder
				break
			
		endswitch
		
	endfor
	
	if ( openflag == 3 ) // write EOF
		dumvar = -1
		FBinWrite /B=2/F=1 refnum, dumvar
	endif
	
	KillVariables /Z dumvar
	
	Close refnum

End // zNMB_WriteObject

//****************************************************************
//****************************************************************
//****************************************************************

Static Function zNMB_WriteString( refnum, str2write )
	Variable refnum
	String str2write
	
	Variable icnt, nobjchar = strlen( str2write )
	Variable /G dumvar = nobjchar
	
	FBinWrite /B=2/F=2 refnum, dumvar

	for ( icnt = 0; icnt < nobjchar; icnt += 1 )
		dumvar = char2num( str2write[ icnt, icnt ] )
		FBinWrite /B=2/F=1 refnum, dumvar
	endfor

End // zNMB_WriteString

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zNMB_ReadString( refnum )
	Variable refnum
	
	String str2read = ""
	
	Variable /G dumvar
	
	FBinRead /B=2/F=2 refnum, dumvar
	
	Variable icnt, nobjchar = dumvar

	for ( icnt = 0; icnt < nobjchar; icnt += 1 )
		FBinRead /B=2/F=1 refnum, dumvar
		str2read += num2char( dumvar )
	endfor
	
	return str2read

End // zNMB_ReadString

//****************************************************************
//****************************************************************
//****************************************************************

Static Function zNMB_ReadObject( file, makeflag )
	String file // file name
	String makeflag // string variables | numeric variables | text waves | numeric waves
	// "1111" to make all variables and waves
	// "0001" to make only numeric waves
	
	Variable icnt, jcnt, nobjchar, opnts, otype, slength, refnum, lx, dx, error = 0
	String objName, dumstr, wnote
	
	Variable /G dumvar
	
	String saveDF = GetDataFolder( 1 ) // save current directory 
	
	Open /R/T="IGBW" refnum as file
		
	do
	
		if ( error )
			break
		endif
		
		FBinRead /B=2/F=1 refnum, dumvar
		otype = dumvar

		if ( otype == -1 )
			break // NM Object EOF
		endif
		
		if ( ( otype < 0 ) || ( otype > 4 ) )
			break // something wrong
		endif
		
		objName = zNMB_ReadString( refnum )
		
		if ( strlen( objName ) == 0 )
			break // something wrong
		endif
		
		switch( otype )
		
			case 0: // text wave ( 1D )
			
				wnote = zNMB_ReadString( refnum ) // read wave note
				
				FBinRead /B=2/F=3 refnum, dumvar
				opnts = dumvar
				
				if ( ( numtype( opnts ) > 0 ) || ( opnts <= 0 ) )
					error = 1
					break
				endif
				
				if ( StringMatch( makeflag[ 2, 2 ], "1" ) ) // make wave
					Make /T/O/N=( opnts ) $objName
					Wave /T tWave = $objName
					Note tWave, wnote
				endif
				
				for ( icnt = 0; icnt < opnts; icnt += 1 ) // read wave points
					dumstr = zNMB_ReadString( refnum )
					if ( StringMatch( makeflag[ 2, 2 ], "1" ) && ( icnt < numpnts( tWave ) ) )
						tWave[ icnt ] = dumstr
					endif
				endfor
				
				break
				
			case 1: // numeric wave ( 1D )
				
				wnote = zNMB_ReadString( refnum ) // read wave note
				
				FBinRead /B=2/F=4 refnum, dumvar // read leftx scaling
				lx = dumvar
				
				FBinRead /B=2/F=4 refnum, dumvar // read deltax scaling
				dx = dumvar
				
				FBinRead /B=2/F=3 refnum, dumvar // read numpnts
				opnts = dumvar
				
				if ( ( numtype( opnts ) > 0 ) || ( opnts <= 0 ) )
					error = 1
					break
				endif
				
				if ( StringMatch( makeflag[ 3, 3 ], "1" ) ) // make wave
					Make /O/N=( opnts ) $objName
					Wave nWave = $objName
					Setscale /P x lx, dx, nWave
					Note nWave, wnote
				endif
				
				for ( icnt = 0; icnt < opnts; icnt += 1 ) // read wave points
					FBinRead /B=2/F=4 refnum, dumvar
					if ( StringMatch( makeflag[ 3, 3 ], "1" ) && ( icnt < numpnts( nWave ) ) )
						nWave[ icnt ] = dumvar
					endif
				endfor
				
				break
				
			case 2: // numeric variable
				FBinRead /B=2/F=4 refnum, dumvar
				if ( StringMatch( makeflag[ 1, 1 ], "1" ) )
					SetNMvar( objName, dumvar )
				endif
				break
				
			case 3: // string variable
				dumstr = zNMB_ReadString( refnum )
				if ( StringMatch( makeflag[ 0, 0 ], "1" ) )
					SetNMstr( objName, dumstr )
				endif
				break
				
			case 4: // folder type
				NewDataFolder /O/S $( saveDF+objName )
				break
				
			default:
				
			
		endswitch
		
	while ( 1 )
	
	KillVariables /Z dumvar
	
	Close refnum

End // zNMB_ReadObject

//****************************************************************
//****************************************************************
//****************************************************************

Static Function zNMB_ObjectType( objName )
	String objName
	
	Variable otype = -1
	
	switch( exists( objName ) )
	
		case 1: // wave
			if ( WaveType( $objName ) == 0 )
				otype = 0 // text wave
			else
				otype = 1 // numeric wave
			endif
			break
			
		case 2: // variable or string
			
			if ( NumVarOrDefault( objName, -pi ) == -pi )
				otype = -2
			else
				otype = 2 // numeric variable
				break
			endif
			
			if ( StringMatch( StrVarOrDefault( objName, "somethingcrazy" ), "somethingcrazy" ) )
				otype = -2
			else
				otype = 3 // string variable
				break
			endif
			
			break
			
	endswitch
	
	if ( ( otype == -1 ) && DataFolderExists( objName ) )
		otype = 4 // is folder
	endif
	
	return otype
	
End // zNMB_ObjectType

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S zNMB_FileType( file )
	String file // file name
	
	String ftype = ""
	
	Variable icnt, nobjchar, opnts, otype, refnum
	String objName
	
	Variable /G dumvar
	
	Open /R/T="IGBW" refnum as file
	
	FBinRead /B=2/F=1 refnum, dumvar
	
	otype = dumvar

	if ( otype == 3 )
	
		objName = zNMB_ReadString( refnum )
		
		if ( StringMatch( objName, "FileType" ) )
			ftype = zNMB_ReadString( refnum )
		endif
	
	endif
	
	KillVariables /Z dumvar
	
	Close refnum
	
	return ftype
		
End // zNMB_FileType

//****************************************************************
//****************************************************************
//****************************************************************
//
// 	Import Wave Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMImportWavesCall() // import data waves
	
	Variable fcnt
	String file, fileList2, folderPath, folder = "", folder2
	
	Variable newFolderOption = 0
	
	Variable createNewFolder = 0
	
	Variable userPrefixDF = NMVarGet( "LoadWithPrefixDF" )
	
	String fileList = NMFileOpenDialogue( "OpenDataPath", "?" )
	
	if ( ItemsInList( fileList ) == 0 )
		return ""
	endif
	
	file = StringFromList( 0, fileList )
	folderPath = NMParent( file )
	
	NewPath /Q/O NMImportWavesPath, folderPath
	
	if ( V_flag != 0 )
		return "" // error in creating path
	endif
	
	fileList2 = IndexedFile( NMImportWavesPath, -1, "????" )
		
	KillPath /Z NMImportWavesPath
	
	if ( newFolderOption && ( ItemsInList( fileList ) > 1 ) )
	
		file = NMChild( folderPath )
		folder = NMFolderNameCreate( file, nmPrefix = NMVarGet( "ForceNMFolderPrefix" ), replaceStringList = NMStrGet( "FileNameReplaceStringList" ) )
		
		if ( IsNMDataFolder( folder ) )
		
			for ( fcnt = 0; fcnt < 9999; fcnt += 1 )
			
				folder2 = folder + "_" + num2str( fcnt )
				
				if ( !IsNMDataFolder( folder2 ) )
					folder = folder2
					break
				endif
				
			endfor
			
		endif
		
		DoAlert /T=( "Import Multiple Files" ) 1, "Would you like to import the selected data files into a folder called " + NMQuotes( folder ) + "?"
		
		if ( V_flag == 1 )
			NMFolderNew( folder )
		else
			folder = ""
		endif
		
	endif
	
	fileList = ReplaceString( folderPath, fileList, "" )
	
	if ( ItemsInList( fileList ) == ItemsInList( fileList2 ) )
		fileList = "ALL"
	endif
	
	fileList2 = NMImportWaves( folder, folderPath, fileList, usePrefixDF = userPrefixDF, history = 1 )
	
	return fileList2
	
End // NMImportWavesCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMImportWaves( folder, folderPath, fileList [ usePrefixDF, history ] )
	String folder // folder name, ( "" ) for current folder
	String folderPath // external folder path
	String fileList // list of external file names, or "ALL" for all files inside folderPath
	Variable usePrefixDF // ( 0 ) no ( 1 ) yes, begin wave prefix with "DF0", "DF1", etc
	Variable history
	
	Variable fcnt, wcnt, dcnt, DFnum, selectNewData, itemNum
	String cstr, f, file, returnFileList = ""
	String prefixList, wavePrefix, wavePrefix2, wList, wName
	String ext, extList = "", fileType, fileTypeList = "", vlist = ""
	
	String tempFolder = "root:NM_Import_Temp:"
	String prefixDF = "DF"
	String prefixDF2 = ""
	
	String folderPrefix = NMPrefixSubfolderPrefix
	
	String subfolderList = NMSubfolderList( folderPrefix, CurrentNMFolder( 1 ), 0 )
	
	Variable changeFolder = 0
	
	vList = NMCmdStr( folder, vList )
	vList = NMCmdStr( folderPath, vList )
	vList = NMCmdStr( fileList, vList )
	
	if ( ParamIsDefault( usePrefixDF ) )
		usePrefixDF = 1
	else
		vlist = NMCmdNumOptional( "usePrefixDF", usePrefixDF, vlist )
	endif
	
	if ( history )
		NMCommandHistory( vList )
	endif
	
	if ( StringMatch( fileList, "All" ) )
		
		NewPath /Q/O NMImportWavesPath, folderPath
		
		if ( V_flag != 0 )
			return "" // error in creating path
		endif
	
		fileList = IndexedFile( NMImportWavesPath, -1, "????" )
		
		KillPath /Z NMImportWavesPath
	
	endif
	
	Variable numFiles = ItemsInList( fileList )
	
	if ( strlen( folder ) == 0 )
	
		folder = CurrentNMFolder( 1 )
		
	elseif ( !DataFolderExists( folder ) )
	
		folder = NMChild( folder )
		folder = CheckFolderName( folder )
		
		if ( IsNMDataFolder( folder ) )
			NMFolderChange( folder )
		else
			NMFolderNew( folder )
		endif
		
	endif
	
	for ( fcnt = 0; fcnt < numFiles; fcnt += 1 )
	
		if ( NMProgressTimer( fcnt, numFiles, "Importing " + num2str( numFiles ) + " Data Files..." ) == 1 )
			break
		endif
	
		file = folderPath + StringFromList( fcnt, fileList )
	
		if ( ( strlen( file ) == 0 ) || !FileExistsAndNonZero( file ) )
			continue
		endif
		
		if ( DataFolderExists( tempFolder ) )
			KillDataFolder /Z $tempFolder
		endif
		
		f = ""
		cstr = ""
		
		if ( strsearch( file, ".pxp", 0 ) > 0 )
		
			if ( strlen( zNMB_FileType( file ) ) > 0 )
				f = NMBinOpen( tempFolder, file, "1111", changeFolder )
			else
				f = IgorBinOpen( tempFolder, file, changeFolder )
			endif
		
		elseif ( ReadPclampFormat( file ) > 0 )
		
			f = NMImportFile( tempFolder, file )
			
		elseif ( ReadAxographFormat( file ) > 0 )
		
			f = NMImportFile( tempFolder, file )
			
		else
		
			ext = FileExtGet( file )
			
			itemNum = WhichListItem( ext, extList )
			
			if ( itemNum >= 0 )
			
				fileType = StringFromList( itemNum, fileTypeList )
				
			else
			
				fileType = NMImportWaveTypeGet( file )
				
				if ( strlen( fileType ) > 0 )
					extList = AddListItem( ext, extList, ";", inf )
					fileTypeList = AddListItem( fileType, fileTypeList, ";", inf )
				endif
				
			endif
			
			if ( strlen( fileType ) == 0 )
				continue
			endif
			
			cstr = NMImportWave( folder, fileType, file )
			
			if ( StringMatch( cstr, NMCancel ) )
				break
			endif
			
		endif
		
		if ( ( strlen( f ) > 0 ) || ( strlen( cstr ) > 0 ) )
			returnFileList = AddListItem( folder, returnFileList, ";", inf )
		endif
		
		if ( strlen( f ) == 0 )
		
			continue
			
		else
		
			selectNewData = 1
		
			wavePrefix = StrVarOrDefault( tempFolder + "WavePrefix", "" )
			
			if ( strlen( WavePrefix ) == 0 )
			
				prefixList = NMSubfolderList( folderPrefix, tempFolder, 0 )
				
				prefixList = ReplaceString( folderPrefix, subfolderList, "" )
				
				wavePrefix = StringFromList( 0, prefixList )
				
			endif
			
			if ( strlen( wavePrefix ) == 0 )
				continue
			endif
			
			if ( usePrefixDF )
			
				DFnum = -1
				
				for ( dcnt = 0; dcnt < 9999; dcnt += 1 )
				
					wList = NMFolderWaveList( folder, prefixDF + num2str( dcnt ) + "_*", ";", "", 0 )
					
					if ( ItemsInList( wList ) == 0 )
						DFnum = dcnt
						break
					endif
				
				endfor
				
				if ( DFnum < 0 )
					return ""
				endif
				
				prefixDF2 = prefixDF + num2str( DFnum ) + "_"
				
			endif
			
			wList = NMFolderWaveList( tempFolder, wavePrefix + "*", ";", "", 0 )
				
			for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
			
				wName = StringFromList( wcnt, wList )
				
				Duplicate /O $( tempFolder + wName ) $( folder + prefixDF2 + wName )
			
			endfor
			
		endif
		
	endfor
	
	NMHistory( "Imported " + num2istr( ItemsInList( returnFileList ) ) + " files from " + folderPath )
	
	KillDataFolder /Z $tempFolder
	
	if ( selectNewData )
	
		if ( usePrefixDF )
			wavePrefix2 = prefixDF
		else
			wavePrefix2 = wavePrefix
		endif
		
		wList = NMFolderWaveList( folder, wavePrefix2 + "*", ";", "", 0 )
		
		if ( ItemsInList( wList ) > 0 )
			NMFolderChange( folder )
			NMSet( wavePrefixNoPrompt = wavePrefix2 )
		endif
	
	endif

	return returnFileList
	
End // NMImportWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMImportWave( folder, fileType, file )
	String folder
	String fileType // see strswitch below
	String file
	
	Variable ss
	String wname, wname2
	
	String saveDF = GetDataFolder( 1 )
	
	if ( !FileExistsAndNonZero( file ) )
		return ""
	endif
	
	if ( strlen( fileType ) == 0 )
		fileType = NMImportWaveTypeGet( file )
	endif
	
	if ( strlen( fileType ) == 0 )
		return ""
	endif
	
	if ( strlen( folder ) == 0 )
	
		folder = CurrentNMFolder( 1 )
		
	elseif ( !DataFolderExists( folder ) )
	
		folder = NMChild( folder )
		folder = CheckFolderName( folder )
		
		if ( IsNMDataFolder( folder ) )
			NMFolderChange( folder )
		else
			NMFolderNew( folder )
		endif
		
	endif

	strswitch( fileType )
	
		case "Igor Binary":
			LoadWave /A=NMWave/H/O/Q file
			break
			
		case "Igor Text":
			LoadWave /A=NMWave/H/T/O/Q file
			break
			
		case "General Text":
			LoadWave /A=NMWave/D/G/H/O/Q file
			break
			
		case "Delimited Text":
			LoadWave /A=NMWave/D/H/J/K=1/O/Q file
			break

		default:
		
			if ( WhichListItem( fileType, NMImageTypeList ) >= 0 )
				ImageLoad /O/Q/T=$fileType file
			endif
			
	endswitch
	
	if ( V_flag > 0 )
	
		wname = StringFromList( 0, S_waveNames )
		
		wname2 = NMChild( file )
		
		wname2 = NMReplaceStringList( wname2, NMStrGet( "FileNameReplaceStringList" ) )
		
		ss = strsearch( wname2, ".", 0 )
		
		if ( ss > 0 )
			wname2 = wname2[ 0, ss - 1 ] // remove extension
		endif
		
		wname2 = NMCheckStringName( wname2 )
		wname2 = NMCheckWaveNameChanTrial( wname2 )
		
		if ( !StringMatch( wname, wname2 ) )
		
			if ( WaveExists( $wname2 ) )
			
				DoAlert /T=( "NM Import Wave" ) 2, "Wave " + NMQuotes( wname2 ) + " already exists. Do you want to over-write it?"
				
				switch( V_flag )
					case 1: // yes
						Duplicate /O $wname, $wname2
						break
					case 2: // no
						break
					case 3:
						return NMCancel
				endswitch
				
			else
			
				Duplicate /O $wname, $wname2
				
			endif
			
			KillWaves /Z $wname
			
		endif
	
	endif
	
	SetDataFolder $saveDF
	
	return wname2
		
End // NMImportWave

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMImportWaveTypeGet( file )
	String file // external file path
	
	String fileType, imageType, shortName, df = NMDF

	if ( strsearch( file, ".ibw", 0 ) > 0 )
		
		return "Igor Binary"
		
	elseif ( strsearch( file, ".itx", 0 ) > 0 )
		
		return "Igor Text"
		
	elseif ( strsearch( file, ".bmp", 0 ) > 0 )
		
		return "bmp"
		
	elseif ( strsearch( file, ".gif", 0 ) > 0 )
		
		return "gif"
		
	elseif ( strsearch( file, ".jpg", 0 ) > 0 )
		
		return "jpeg"
		
	elseif ( strsearch( file, ".jpeg", 0 ) > 0 )
		
		return "jpeg"
		
	elseif ( strsearch( file, ".pic", 0 ) > 0 )
		
		return "pict"
		
	elseif ( strsearch( file, ".pict", 0 ) > 0 )
		
		return "pict"
	
	elseif ( strsearch( file, ".png", 0 ) > 0 )
		
		return "png"
		
	elseif ( strsearch( file, ".rpng", 0 ) > 0 )
		
		return "rpng"
		
	elseif ( strsearch( file, ".sgi", 0 ) > 0 )
		
		return "sgi"
		
	elseif ( strsearch( file, ".tif", 0 ) > 0 )
		
		return "tiff"
		
	elseif ( strsearch( file, ".tiff", 0 ) > 0 )
		
		return "tiff"
		
	else
		
		shortName = NMChild( file )
		
		fileType = StrVarOrDefault( df+"ImportWavesFileType", "" )
		imageType = StrVarOrDefault( df+"ImportWavesImageType", "" )
		
		if ( strlen( imageType ) > 0 )
			fileType = ""
		endif

		Prompt fileType "select type of file:", popup " ;Igor Binary;Igor Text;General Text;Delimited Text;"
		Prompt imageType "or select type of image:", popup " ;" + NMImageTypeList
		
		DoPrompt "Import Wave : " + shortName, fileType, imageType
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		if ( StringMatch( fileType, " " ) )
			fileType = ""
		endif
		
		if ( StringMatch( imageType, " " ) )
			imageType = ""
		endif
		
		if ( strlen( imageType ) > 0 )
			fileType = ""
		endif
		
		SetNMstr( df+"ImportWavesFileType", fileType )
		SetNMstr( df+"ImportWavesImageType", imageType )
		
		if ( strlen( fileType ) > 0 )
			return fileType
		else
			return imageType
		endif
	
	endif

End // NMImportWaveTypeGet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMLoadAllWavesFromExtSubFolders( extFolderPath )
	String extFolderPath // external folder path
	
	Variable icnt, numFolders
	String shortName, shortName2, subFolderList, folderPath, file, fileList
	String newFolder, wList, fList = ""
	
	String fileType = ""
	String fileExt = "" // file extension of waves to load ( e.g. "txt" or "dat" )
	Variable createNewFolder = 0 // automatically done in this macro
	
	if ( strlen( extFolderPath ) == 0 )
		extFolderPath = NMGetExternalFolderPath( "select folder where data subfolders are located", "" )
	endif
	
	if ( strlen( extFolderPath ) == 0 )
		return ""
	endif
	
	shortName = NMChild( extFolderPath )
	
	NewPath /Q/O NMLoadAllWavesPath, extFolderPath
	
	if ( V_flag != 0 )
		return "" // error in creating path
	endif
	
	subFolderList = IndexedDir( NMLoadAllWavesPath, -1, 1 ) // look for any subfolders
		
	numFolders = ItemsInList( subFolderList )
	
	KillPath /Z NMLoadAllWavesPath
	
	if ( numFolders == 0 )
		
		DoAlert 0, "Abort Load Waves : found no subfolders inside " + NMQuotes( shortName )
		
		return ""
	
	endif
	
	DoAlert 1, "Located " + num2istr( numFolders ) + " subfolders inside " + shortName + ". Do you want to load data from these subfolders?"
		
	if ( V_flag != 1 )
		return ""
	endif
	
	file = ""
	
	for ( icnt = 0; icnt < numFolders; icnt += 1 )
		
		folderPath = StringFromList( icnt, subFolderList )
		
		NewPath /Q/O NMLoadAllWavesPath, folderPath
		
		if ( V_flag != 0 )
			return "" // error in creating path
		endif
		
		fileList = IndexedFile( NMLoadAllWavesPath, -1, "????" )
		
		if ( ItemsInList( fileList ) == 0 )
			continue
		endif
		
		file = StringFromList( 0, fileList )
		
		break
		
	endfor
	
	KillPath /Z NMLoadAllWavesPath
	
	if ( strlen( file ) == 0 )
		return ""
	endif
	
	if ( strsearch( file, ".ibw", 0 ) > 0 )
		fileType = "Igor Binary"
	elseif ( strsearch( file, ".itx", 0 ) > 0 )
		fileType = "Igor Text"
	else
		fileType = "Delimited Text"
	endif
	
	Prompt fileType "select type of files to import:", popup "Igor Binary;Igor Text;General Text;Delimited Text;"
	DoPrompt "Load Waves From Folder " + shortName, fileType
		
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	strswitch( fileType )
	
		case "Igor Binary":
			fileExt = "ibw"
			break
			
		case "Igor Text":
			fileExt = "itw"
			break
			
		case "General Text":
		case "Delimited Text":
		
			if ( strsearch( fileList, ".txt", 0 ) > 0 )
				fileExt = "txt"
			elseif ( strsearch( fileList, ".dat", 0 ) > 0 )
				fileExt = "dat"
			endif
			
			Prompt fileExt "extension of files to import ( leave blank to import all ):"
			DoPrompt "Load Waves From Folder " + shortName, fileExt
		
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
			break
			
		default:
			return ""
			
	endswitch
	
	if ( strlen( fileExt ) == 0 )
		
		Prompt fileExt "extension of files to import ( leave blank to import all ):"
		DoPrompt "Load Waves From Folder " + shortName, fileExt
		
		if ( V_flag == 1 )
			return "" // cancel
		endif

	endif
	
	for ( icnt = 0; icnt < numFolders; icnt += 1 )
		
		folderPath = StringFromList( icnt, subFolderList )
		
		shortName2 = NMChild( folderPath )
		
		newFolder = shortName + "_" + shortName2
		
		NMFolderNew( newFolder )
		
		if ( NMProgress( icnt, numFolders, "Loading Folder #" + num2istr( icnt ) + " : " + shortName + "_" + shortName2 ) == 1 ) // update progress display	
			break // cancel wave loop
		endif
		
		wList = NMLoadAllWavesFromExtFolder( folderPath, fileType, fileExt, createNewFolder )
		
		fList = AddListItem( newFolder, fList, ";", inf )
		
	endfor

	return fList
	
End // NMLoadAllWavesFromExtSubFolders

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMLoadAllWavesFromExtFolderCall()

	Variable numFiles, numFolders, nmPrefix
	String file, fileList, shortName, subFolderList, vList = ""
	String df = NMDF

	String fileType = ""
	String fileExt = ""
	Variable createNewFolder = NumVarOrDefault( df + "ImportToNewFolder", 1 )
	
	String extFolderPath = NMGetExternalFolderPath( "select folder where data files are located", "" )
	
	if ( strlen( extFolderPath ) == 0 )
		return ""
	endif
	
	shortName = NMChild( extFolderPath )
	
	NewPath /Q/O NMLoadAllWavesPath, extFolderPath
	
	if ( V_flag != 0 )
		return "" // error in creating path
	endif
	
	fileList = IndexedFile( NMLoadAllWavesPath,-1,"????" )
	
	numFiles = ItemsInList( fileList )
	
	if ( numFiles == 0 )
		return NMLoadAllWavesFromExtSubFolders( extFolderPath )
	endif
	
	KillPath /Z NMLoadAllWavesPath
	
	file = StringFromList( 0, fileList )
	
	if ( strsearch( file, ".ibw", 0 ) > 0 )
		fileType = "Igor Binary"
	elseif ( strsearch( file, ".itx", 0 ) > 0 )
		fileType = "Igor Text"
	else
		fileType = "Delimited Text"
	endif
	
	createNewFolder += 1
	
	Prompt fileType "select type of files to import:", popup "Igor Binary;Igor Text;General Text;Delimited Text;"
	Prompt createNewFolder "load waves into a new folder?", popup "no;yes;"
	DoPrompt "Load Waves From Folder " + shortName, fileType, createNewFolder
		
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	createNewFolder -= 1
	
	setNMvar( df + "ImportToNewFolder", createNewFolder )
	
	strswitch( fileType )
	
		case "Igor Binary":
			fileExt = "ibw"
			break
			
		case "Igor Text":
			fileExt = "itw"
			break
			
		case "General Text":
		case "Delimited Text":
		
			if ( strsearch( fileList, ".txt", 0 ) > 0 )
				fileExt = "txt"
			elseif ( strsearch( fileList, ".dat", 0 ) > 0 )
				fileExt = "dat"
			endif
			
			Prompt fileExt "extension of files to import ( leave blank to import all ):"
			DoPrompt "Load Waves From Folder " + shortName, fileExt
		
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
			break
			
		default:
			return ""
			
	endswitch
	
	if ( strlen( fileExt ) == 0 )
		
		Prompt fileExt "extension of files to import ( leave blank to import all ):"
		DoPrompt "Load Waves From Folder " + shortName, fileExt
		
		if ( V_flag == 1 )
			return "" // cancel
		endif

	endif
	
	nmPrefix = NMVarGet( "ForceNMFolderPrefix" )
	
	return NMLoadAllWavesFromExtFolder( extFolderPath, fileType, fileExt, createNewFolder, nmPrefix = nmPrefix, history = 1 )
	
End // NMLoadAllWavesFromExtFolderCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMLoadAllWavesFromExtFolder( extFolderPath, fileType, fileExt, createNewFolder [ nmPrefix, history ] )
	String extFolderPath // path to external folder where data is located
	String fileType // "Igor Binary" or "Igor Text" or "General Text" or "Delimited Text"
	String fileExt // file extension of waves to load ( e.g. "txt" or "dat" ), or enter "" for any
	Variable createNewFolder // ( 0 ) no ( 1 ) yes
	Variable nmPrefix // ( 0 ) no ( 1 ) yes, force "nm" prefix when creating NM data folders
	Variable history
	
	Variable numFiles, icnt, slen
	String file, newFolder, fileList, wname, wname2, wList = "", vlist = ""
	
	vList = NMCmdStr( extFolderPath, vList )
	vList = NMCmdStr( fileType, vList )
	vList = NMCmdStr( fileExt, vList )
	vList = NMCmdNum( createNewFolder, vList, integer = 1 )
	
	if ( ParamIsDefault( nmPrefix ) )
		nmPrefix = 1
	else
		vlist = NMCmdNumOptional( "nmPrefix", nmPrefix, vlist )
	endif
	
	if ( history )
		NMCommandHistory( vList )
	endif
	
	createNewFolder = BinaryCheck( createNewFolder )
	
	if ( ( strlen( fileExt ) > 0 ) && !StringMatch( fileExt[ 0, 0 ], "." ) )
		fileExt = "." + fileExt
	endif
	
	if ( strlen( extFolderPath ) == 0 )
		extFolderPath = NMGetExternalFolderPath( "select folder where data files are located", extFolderPath )
	endif
	
	if ( strlen( extFolderPath ) == 0 )
		return ""
	endif
	
	NewPath /Q/O NMLoadAllWavesPath, extFolderPath
	
	if ( V_flag != 0 )
		return "" // error in creating path
	endif
	
	fileList = IndexedFile( NMLoadAllWavesPath,-1,"????" )
	
	numFiles = ItemsInList( fileList )
	
	if ( numFiles == 0 )
		return ""
	endif
	
	if ( createNewFolder )
		newFolder = NMFolderNameCreate( extFolderPath, nmPrefix = nmPrefix, replaceStringList = NMStrGet( "FileNameReplaceStringList" ) )
		NMFolderNew( "" )
	endif
	
	for ( icnt = 0; icnt < numFiles; icnt += 1 )
	
		file = StringFromList( icnt, fileList )
		
		if ( !FileExistsAndNonZero( LastPathColon( extFolderPath, 1 ) + file ) )
			continue
		endif
		
		slen = strlen( file )
			
		if ( ( strlen( fileExt ) == 0 ) || StringMatch( file[ slen-strlen( fileExt ), slen-1 ], fileExt ) )
		
			strswitch( fileType )
				case "Igor Binary":
					LoadWave /A=NMwave/H/O/P=NMLoadAllWavesPath/Q file
					break
				case "Igor Text":
					LoadWave /A=NMwave/H/T/O/P=NMLoadAllWavesPath/Q file
					break
				case "General Text":
					LoadWave /A=NMwave/D/G/H/O/P=NMLoadAllWavesPath/Q file
					break
				case "Delimited Text":
					LoadWave /A=NMwave/D/H/J/K=1/O/P=NMLoadAllWavesPath/Q file
					break
				default:
					return "" // wrong format
			endswitch
			
			wname = StringFromList( 0, S_waveNames )
			wname2 = file[ 0, slen-5 ]
			
			if ( !StringMatch( wname, wname2 ) )
			
				Duplicate /O $wname, $wname2
				
				KillWaves /Z $wname
			
			endif
			
			wList = AddListItem( wname2, wList, ";", inf )
			
		endif
		
	endfor
	
	KillPath /Z NMLoadAllWavesPath
	
	if ( ( createNewFolder ) && !DataFolderExists( CheckNMFolderPath( newFolder ) ) )
		NMFolderRename( "" , newFolder )
	endif
	
	NMHistory( "Imported " + num2istr( ItemsInList( wList ) ) + " waves from " + extFolderPath )
	
	return wList
	
End // NMLoadAllWavesFromExtFolder

//****************************************************************
//****************************************************************
//****************************************************************
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma hide = 1

//****************************************************************
//****************************************************************

Static Constant D3DFORMAT = 2
Static Constant MULTIPLEFOLDERSOPTION = 1 // import subfolder data into (1) one folder (2) multiple folders
Static StrConstant DETECTORSHORTPREFIX = "D" // short prefix name for "Detector"
Static StrConstant SOURCESHORTPREFIX = "S" // short prefix name for "Source"

//****************************************************************
//****************************************************************

Macro NMImportD3DFilesCall()

	String folderPath = ""
	String fileList = ""
	Variable wavePrecision = 2

	NMImportD3DFiles( folderPath, fileList, wavePrecision )
	
End // NMImportD3DFilesCall

//****************************************************************
//****************************************************************

Macro NMImportD3DFolderCall()

	String folderPath = ""
	Variable NoAlerts = 0
	Variable wavePrecision = 2

	NMImportD3DFolder( folderPath, NoAlerts, wavePrecision )
	
End // NMImportD3DFolderCall

//****************************************************************
//****************************************************************

Function /S NMImportD3DFolder( folderPath, NoAlerts, precision )
	String folderPath // folder path on hard drive to open, enter ( "" ) to get dialogue
	Variable NoAlerts // ( 0 ) alert user when necessary ( 1 ) no alerts
	Variable precision // load into Igor waves ( 1 ) single floating point ( 2 ) double floating point
	
	//print folderPath, NoAlerts, precision

	String file, fileList, folderName, folderList = "", subFolderList, d3dFolderList = "" 
	String df, wName, wList = "", prefix, prefix2, prefixList = "", prefixList2, prefixList3
	
	Variable icnt, jcnt, folderSelect = 0, setCurrentPrefix, foundPrefix
	Variable numFiles, numFolders, createdFolder, addPrefix = 1

	if ( strlen( folderPath ) == 0 )
	
		if ( NoAlerts == 1 )
			return "" // nothing to do
		endif
		
		folderPath = NMGetExternalFolderPath( "select D3D folder to import", "" )
		
		if ( strlen( folderPath ) == 0 )
			return "" // cancel
		endif
		
	endif
	
	NMHistory( folderPath )
	
	NewPath /O/Q/Z D3DOpenFilePath, folderPath

	if ( V_flag != 0 )
		//Print "Unable to create path: ", folderPath
		return "" // unable to create path
	endif
	
	folderList = folderPath + ";"
	
	subFolderList = IndexedDir( D3DOpenFilePath, -1, 1 ) // look for any subfolders
	
	//return subFolderList // CHECK WITHOUT OPENING
	
	numFolders = ItemsInList( subFolderList )
	
	if ( numFolders > 0 )
	
		for ( icnt = 0 ; icnt < numFolders ; icnt += 1 )
		
			folderPath = StringFromList( icnt, subFolderList )
			
			NewPath /Q/O D3DOpenFilePath, folderPath
			
			fileList = IndexedFile( D3DOpenFilePath, -1, "????" )
			
			for ( jcnt = 0 ; jcnt < ItemsInList( fileList ) ; jcnt += 1 )
			
				file = StringFromList( jcnt, fileList )
				
				if ( strsearch( file, "D3D", 0, 2 ) >= 0 )
					d3dFolderList = AddListItem( folderPath, d3dFolderList, ";", inf )
					break
				endif
			
			endfor
			
		endfor
		
		numFolders = ItemsInList( d3dFolderList )
		
		if ( numFolders > 0 )
		
			if ( NoAlerts == 1 )
			
				// folderList += d3dFolderList // do not load subfolders by default
			
			else
			
				df = ImportDF()
	
				DoAlert 1, "D3D alert: located " + num2istr( numFolders ) + " subfolders inside the selected directory. Do you want to load data from these subfolders?"
				
				if ( V_flag == 1 )
				
					folderList += d3dFolderList
				
				
					folderSelect = NumVarOrDefault( df + "D3DMultipleFoldersSelect", MULTIPLEFOLDERSOPTION )
					
					Prompt folderSelect, "import subfolder data into:", popup "one folder;multiple folders;"
					DoPrompt "Import D3D Folders", folderSelect
					
					if ( V_Flag == 1 )
						return "" // cancel
					endif
					
					SetNMvar( df + "D3DMultipleFoldersSelect", folderSelect )
				
				endif
			
			endif
		
		endif
	
	endif
	
	numFolders = ItemsInList( folderList )
	
	for ( icnt = 0 ; icnt < numFolders ; icnt += 1 )
	
		folderPath = StringFromList( icnt, folderList )
		folderName = NMFolderNameCreate( folderPath )
			
		NewPath /Q/O D3DOpenFilePath, folderPath
	
		fileList = IndexedFile( D3DOpenFilePath, -1, "????" )
		
		numFiles = ItemsInList( fileList )
		
		if ( numFiles == 0 )
			continue
		endif
		
		if ( folderSelect == 1 )
			if ( !createdFolder )
				NMFolderNew(  folderName )
				createdFolder = 1
			endif
			addPrefix = 0
		else
			NMFolderNew( folderName )
		endif
		
		folderPath = LastPathColon( folderPath, 1 )
		
		foundPrefix = 0
		
		for ( jcnt = 0; jcnt < numFiles; jcnt += 1 )
		
			file = StringFromList( jcnt, fileList )
			
			if ( addPrefix && !foundPrefix && strsearch( file, "Detect", 0 ) >= 0 )
				setCurrentPrefix = 1
				foundPrefix = 1
			else
				setCurrentPrefix = 0
			endif
			
			prefix = NMImportD3DFile( folderPath + file, precision, addPrefix = addPrefix, setCurrentPrefix = setCurrentPrefix )
			
			if ( strlen( prefix ) > 0 )
				prefixList = AddListItem( prefix, prefixList, ";", inf )
			endif
		
		endfor
		
		if ( addPrefix && !foundPrefix )
			prefix = StringFromList( 0, prefixList )
			NMSet( wavePrefixNoPrompt = prefix )
		endif
		
	endfor
	
	Variable firstPrefix = 1
	
	if ( folderSelect == 1 )
	
		prefixList2 = prefixList
	
		for ( icnt = 0 ; icnt < 20 ; icnt += 1 )
		
			if ( ItemsInList( prefixList2 ) == 0 )
				break
			endif
	
			prefix = StringFromList( 0, prefixList2 )
			prefix = prefix[ 0, strlen( prefix ) - 2 ]
			
			if ( firstPrefix )
				NMSet( wavePrefixNoPrompt = prefix )
				firstPrefix = 0
			else
				NMPrefixAdd( prefix )
			endif
			
			prefixList3 = ""
			
			for ( jcnt = 0 ; jcnt < ItemsInList( prefixList2 ) ; jcnt += 1 )
			
				prefix2 = StringFromList( jcnt, prefixList2 )
				
				if ( strsearch( prefix2, prefix, 0 ) == 0 )
					continue
				endif
				
				prefixList3 += prefix2 + ";"
				
			endfor
			
			prefixList2 = prefixList3
		
		endfor
	
	endif
	
	KillPath /Z D3DOpenFilePath
	
	NMHistory( "Finished loading " + folderName )
	
	return folderName

End // NMImportD3DFolder

//****************************************************************
//****************************************************************

Function /S NMImportD3DFiles( folderPath, fileList, precision )
	String folderPath // folder path on hard drive, enter ( "" ) if file names contain full path
	String fileList // list of file names to open, enter ( "All" ) to open all within folderPath, or enter ( "" ) to get file open dialogue
	Variable precision // load into Igor waves ( 1 ) single floating point ( 2 ) double floating point
	
	Variable numFiles, icnt
	String filePath, parent
	
	if ( strlen( folderPath ) > 0 )
	
		NewPath /O/Q/Z D3DOpenFilePath, folderPath

		if ( V_flag != 0 )
			Print "Unable to create path to external folder: ", folderPath
			return ""
		endif
		
	endif
	
	if ( strlen( fileList ) == 0 )
	
		fileList = NMFileOpenDialogue( "D3DOpenFilePath", "?" )
		
		if ( ItemsInList( fileList ) == 0 )
			return "" // cancel
		endif
		
		parent = ""
		
	elseif ( StringMatch( fileList, "All" ) == 1 )
	
		fileList = IndexedFile( D3DOpenFilePath, -1, "????" )
		
		parent = folderPath

	endif
	
	numFiles = ItemsInList( fileList )
		
	if ( numFiles == 0 )
		return ""
	endif
	
	for ( icnt = 0 ; icnt < numFiles ; icnt += 1 )
	
		if ( NMProgressTimer( icnt, numFiles, "Loading D3D Files... " + num2istr( icnt ) ) == 1 )
			break // cancel
		endif
		
		filePath = parent + StringFromList( icnt, fileList )
		
		NMImportD3DFile( filePath, precision, addPrefix = 1, setCurrentPrefix = ( icnt == 0 ) )
		
	endfor
	
	KillPath /Z D3DOpenFilePath
	
	return ""
	
End // NMImportD3DFiles

//****************************************************************
//****************************************************************

Function /S NMD3DFileType( filePath )
	String filePath // file path on hard drive to open
	
	Variable slen, kcnt
	String fileName, parent, wName, stemp
	
	if ( strlen( filePath ) == 0 )
		return ""
	endif
	
	if ( FileExistsAndNonZero( filePath ) == 0 )
		return ""
	endif
	
	fileName = NMChild( filePath )
	parent = NMParent( filePath )
	
	slen = strlen( fileName )
	
	if ( ( StringMatch( fileName[ slen-4,slen-1 ], ".dat" ) == 0 ) && ( StringMatch( fileName[ slen-4,slen-1 ], ".bin" ) == 0 ) )
		return ""
	endif
	
	if ( StringMatch( fileName[ slen-4,slen-1 ], ".dat" ) == 1 )
	
		if ( strsearch( fileName, "D3Dconfig", 0, 2 ) >= 0 )
			return "D3Dconfig"
		elseif ( strsearch( fileName, "D3Dlog", 0, 2 ) >= 0 )
			return "D3Dlog"
		endif
	
	endif
	
	if ( D3DFORMAT == 2 )
		
		LoadWave /A=D3Dwave/J/K=2/L={0,0,20,0,0}/O/Q filePath // load as text wave
			
		if ( strlen( S_waveNames ) == 0 )
			return ""
		endif
			
		wName = StringFromList( 0, S_waveNames )
			
		if ( WaveExists( $wName ) == 0 )
			return ""
		endif
			
		Wave /T temp = $wName
			
		for ( kcnt = 0 ; kcnt < 20 ; kcnt+=1 ) // read header lines
		
			if ( kcnt >= numpnts( temp ) )
				break
			endif
		
			stemp = temp[ kcnt ]
			
			if ( StrSearch( stemp, "D3D=", 0, 2 ) == 0 )
				return stemp
			endif
			
		endfor
		
	endif
	
	return ""
	
End // NMD3DFileType

//****************************************************************
//****************************************************************

Function /S NMImportD3DFile( filePath, precision [ addPrefix, setCurrentPrefix ] )
	String filePath // file path on hard drive to open
	Variable precision // load into Igor waves ( 1 ) single floating point ( 2 ) double floating point
	Variable addPrefix // add wave prefix name ( 0 ) no ( 1 ) yes
	Variable setCurrentPrefix // set as current wave prefix name ( 0 ) no ( 1 ) yes
	
	String fileName, parent, outPrefix = ""
	String wName, wName2, wName3, wList, stemp, wName2D, prefix
	String xunits, yunits
	String dataDimensions = "time"
	String dataFormat = "General Text" // "General Text" or "Delimited Text" or "Binary Double"
	
	Variable icnt, jcnt, kcnt, wcnt, version, numWaves, samples2save
	Variable slen, dstop, snap
	Variable x1, y1, z1, x2, y2, z2, dx, dt, ncols, nrows, offset
	Variable EOH, skip
	
	Variable pointsPerSample = 1
	
	if ( ParamIsDefault( addPrefix ) )
		addPrefix = 1
	endif
	
	if ( ParamIsDefault( setCurrentPrefix ) )
		setCurrentPrefix = 1
	endif

	if ( strlen( filePath ) == 0 )
		return "" // cancel
	endif
	
	if ( FileExistsAndNonZero( filePath ) == 0 )
		return "" // cancel
	endif
	
	if ( D3DFORMAT == 2 )
		offset = 0
	else
		offset = 5
	endif
	
	fileName = NMChild( filePath )
	parent = NMParent( filePath )
	
	slen = strlen( fileName )
	
	wName = ""
	wName2 = ""
		
	if ( ( StringMatch( fileName[ slen-4,slen-1 ], ".dat" ) == 1 ) || ( StringMatch( fileName[ slen-4,slen-1 ], ".bin" ) == 1 ) )
		
		if ( D3DFORMAT == 2 )
		
			LoadWave /A=D3Dwave/J/K=2/L={0,0,2000,0,0}/O/Q filePath // load as text wave
			
			if ( strlen( S_waveNames ) == 0 )
				return ""
			endif
			
			wName = StringFromList( 0, S_waveNames )
			wName2 = fileName[ 0, slen-5 ]
			
			if ( WaveExists( $wName ) == 0 )
				return ""
			endif
			
			Wave /T temp = $wName
			
			dt = -1
			snap = 0
			dataDimensions = "time"
			dataFormat = "General Text"
			
			for ( kcnt = 0 ; kcnt < 20 ; kcnt+=1 ) // read header lines
			
				if ( kcnt >= numpnts( temp ) )
					break
				endif
			
				stemp = temp[ kcnt ]
				
				if ( StrSearch( stemp, "D3D=", 0, 2 ) == 0 )
				
					version = str2num( stemp[ 4, inf ] )
				
				elseif ( StrSearch( stemp, "dt=", 0, 2 ) == 0 )
				
					dt = str2num( stemp[ 3, inf ] )
					dstop = kcnt
					
				elseif ( StrSearch( stemp, "t=", 0, 2 ) == 0 )
				
					dt = 1
					dstop = kcnt
					snap = 1
					
				elseif ( StrSearch( stemp, "xdim=", 0, 2 ) == 0 )
				
					if ( StrSearch( stemp, "time", 0, 2 ) > 0 )
						dataDimensions = "time"
					elseif ( StrSearch( stemp, "ZYX", 0, 2 ) > 0 )
						dataDimensions = "ZYX"
					elseif ( StrSearch( stemp, "XYZ positions", 0, 2 ) > 0 )
						dataDimensions = "XYZ"
					endif
					
					xunits = stemp[ 5, inf ]
					
				elseif ( StrSearch( stemp, "ydim=", 0, 2 ) == 0 )
				
					yunits = stemp[ 5, inf ]
					
				elseif ( StrSearch( stemp, "dimensions=", 0, 2 ) == 0 )
				
					if ( StrSearch( stemp, "time", 0, 2 ) > 0 )
						dataDimensions = "time"
					elseif ( StrSearch( stemp, "ZYX", 0, 2 ) > 0 )
						dataDimensions = "ZYX"
					endif
					
				elseif ( StrSearch( stemp, "samples2save=", 0, 2 ) == 0 )
				
					samples2save = str2num( stemp[ 13, inf ] )
					
				elseif ( StrSearch( stemp, "pointsPerSample=", 0, 2 ) == 0 )
				
					pointsPerSample = str2num( stemp[ 16, inf ] )
					
				elseif ( StrSearch( stemp, "format=", 0, 2 ) == 0 )
					
					if ( StrSearch( stemp, "Text", 0, 2 ) > 0 )
						
						dstop = kcnt
						
						if ( numpnts( temp ) - kcnt > 2 )
							dataFormat = "General Text"
						else
							dataFormat = "Delimited Text"
						endif
						
					elseif ( StrSearch( stemp, "Binary Double", 0, 2 ) > 0 )
						dataFormat = "Binary Double"
						dstop = 0
					endif
					
					break // END OF HEADER
					
				elseif ( StrSearch( stemp, "x1=", 0, 2 ) == 0 )
					x1 = str2num( stemp[ 3, inf ] )
				elseif ( StrSearch( stemp, "y1=", 0, 2 ) == 0 )
					y1 = str2num( stemp[ 3, inf ] )
				elseif ( StrSearch( stemp, "z1=", 0, 2 ) == 0 )
					z1 = str2num( stemp[ 3, inf ] )
				elseif ( StrSearch( stemp, "x2=", 0, 2 ) == 0 )
					x2 = str2num( stemp[ 3, inf ] )
				elseif ( StrSearch( stemp, "y2=", 0, 2 ) == 0 )
					y2 = str2num( stemp[ 3, inf ] )
				elseif ( StrSearch( stemp, "z2=", 0, 2 ) == 0 )
					z2 = str2num( stemp[ 3, inf ] )
				elseif ( StrSearch( stemp, "dx=", 0, 2 ) == 0 )
					dx = str2num( stemp[ 3, inf ] )
				endif
				
			endfor
		
		endif
		
		if ( ( snap == 1 ) && ( StringMatch( dataDimensions, "XYZ" ) == 1 ) )
			snap = 0
		endif
		
		if ( strsearch( fileName, "D3Dconfig", 0, 2 ) >= 0 )
		
			Duplicate /O/T $wName, $wName2
			
		elseif ( strsearch( fileName, "D3Dlog", 0, 2 ) >= 0 )
		
			Duplicate /O/T $wName, $wName2
			
		elseif ( strsearch( fileName, "R_", 0, 2 ) == 0 )
		
			prefix = "R_TEMP_"
			LoadWave /A=$prefix/G/D/K=1/Q filePath
			
			Duplicate /O $StringFromList( 0 , S_waveNames ) $wName2
			Duplicate /O $StringFromList( 1 , S_waveNames ) $"d"+wName2
			
			KillWaves /Z $StringFromList( 0 , S_waveNames )
			KillWaves /Z $StringFromList( 1 , S_waveNames )
			
		elseif ( dt > 0 )
		
			KillWaves /Z $wName
			
			if ( StringMatch( dataFormat, "General Text" ) == 1 )
			
				if ( precision == 2 )
					LoadWave /A=D3Dwave/D/G/K=1/O/Q filePath // load again as numerical wave
				else
					LoadWave /A=D3Dwave/G/K=1/O/Q filePath // load again as numerical wave
				endif
				
				dstop = 0 // do not need to delete header when using /G ( but need it when /J )
			
			elseif ( StringMatch( dataFormat, "Delimited Text" ) == 1 )
			
				if ( precision == 2 )
					LoadWave /A=D3Dwave/J/D/K=1/O/Q filePath // load again as numerical wave
				else
					LoadWave /A=D3Dwave/J/K=1/O/Q filePath // load again as numerical wave
				endif
				
				//dstop = 0 // do not need to delete header when using /G ( but need it when /J )
				
			elseif ( StringMatch( dataFormat, "Binary Double" ) == 1 )
			
				GBLoadWave /A=D3Dwav/T={8,8}/O/Q/W=1 filePath  // load again as 8 bit signed integer
				
				if ( strlen( S_waveNames ) == 0 )
					return ""
				endif
			
				wName = StringFromList( 0, S_waveNames )
				
				if ( numpnts( $wName ) < 3 )
					return "" //  wrong file type
				endif
				
				Wave wtemp = $wName
				
				if ( ( wtemp[ 0 ] != char2num( "D" ) ) || ( wtemp[ 1 ] != char2num( "3" ) ) || ( wtemp[ 2 ] != char2num( "D" ) ) )
					return "" // wrong file type
				endif
				
				EOH = 0
				
				for ( kcnt = 0 ; kcnt < numpnts( wtemp ) - 8 ; kcnt += 1 )
					
					if ( ( wtemp[ kcnt ] == char2num( "f" ) ) && ( wtemp[ kcnt + 1 ] == char2num( "o" ) ) && ( wtemp[ kcnt + 2 ] == char2num( "r" ) ) )
						if ( ( wtemp[ kcnt + 3 ] == char2num( "m" ) ) && ( wtemp[ kcnt + 4 ] == char2num( "a" ) ) && ( wtemp[ kcnt + 5 ] == char2num( "t" ) ) )
							EOH = 1
						endif
					endif
					
					if ( ( EOH == 1 ) && ( wtemp[ kcnt ] == 10 ) ) // new line == 10 ASCII
						break // end of header
					endif
				
				endfor
				
				skip = kcnt + 1
			
				if ( precision == 2 )
					GBLoadWave /A=D3Dwav/T={4,4}/S=(skip)/O/Q/W=1 filePath  // load again as binary double float
				else
					GBLoadWave /A=D3Dwav/T={4,2}/S=(skip)/O/Q/W=1 filePath  // load again as binary double float
				endif
				
			else
			
				return "" // unknown file type
				
			endif
			
			numWaves = ItemsInList( S_waveNames )
			
			if ( numWaves <= 0 )
				return ""
			endif
			
			for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
		
				wName = StringFromList( wcnt, S_waveNames )
				wName2 = fileName[ 0,slen-5 ]
				
				if ( numWaves > 1 )
					wName2 += "_" + num2istr( wcnt )
				endif
				
				wName2 = ReplaceString( "Detector", wName2, DETECTORSHORTPREFIX )
				wName2 = ReplaceString( "Source", wName2, SOURCESHORTPREFIX )
				
				if ( snap == 1 )
					wName2 = "Snap_" + wName2
				endif
			
				Setscale /P x 0, dt, $wName
				
				if ( dstop > 0 )
					DeletePoints 0, dstop+1, $wName
				endif
			
				Duplicate /O $wName, $wName2
				
				NMNoteType( wName2, "NMD3D", xunits, yunits, "" )
				
				outPrefix = wName2
			
				if ( ( snap == 1 ) && ( x1 + y1 + z1 + x2 + y2 + z2 > 0 ) )
				
					if ( x1 == x2 ) // yz
					
						nrows = z2 - z1 + 1
						ncols = y2 - y1 + 1
						 
						wName2D = NMD3DSnapUnpack( ncols, nrows, wName2, offset, dx, "y (um)", "z (um)" )
					
					elseif ( y1 == y2 ) // zx
					
						nrows = z2 - z1 + 1
						ncols = x2 - x1 + 1
						
						wName2D = NMD3DSnapUnpack( ncols, nrows, wName2, offset, dx, "x (um)", "z (um)" )
					
					elseif ( z1 == z2 ) // xy
					
						ncols = x2 - x1 + 1
						nrows = y2 - y1 + 1
						
						wName2D = NMD3DSnapUnpack( ncols, nrows, wName2, offset, dx, "x (um)", "y (um)" )
					
					endif
				
				endif
			
			endfor
			
		elseif ( strsearch( fileName, "Vesicles_positions", 0, 2 ) >= 0 )
		
			if ( strsearch( fileName, "bgn", 0, 2 ) >= 0 )
			
				prefix = "VesPosBgn" + num2istr( icnt ) + "_"
				
				LoadWave /A=$prefix/G/D/W filePath
				
			elseif ( strsearch( fileName, "end", 0, 2 ) >= 0 )
			
				prefix = "VesPosEnd" + num2istr( icnt ) + "_"
			
				LoadWave /A=$prefix/G/D/W filePath
				
			endif
			
			outPrefix = prefix
			
		endif
		
	endif
	
	wList = WaveList( "D3Dwav*", ";", "" )
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
		KillWaves /Z $StringFromList( wcnt, wList )
	endfor
	
	if ( !snap && ( pointsPerSample > 1 ) )
	
		outPrefix = NMStrGet( "D3D_UnpackWavePrefix" )
		outPrefix = NMD3DUnpack( wName2, x1, y1, z1, x2, y2, z2, pointsPerSample, dt, xunits, yunits, outPrefix )
		
		if ( strlen( outPrefix ) > 0 )
			KillWaves /Z $wName2
		endif
		
	endif
	
	//Print "Finished loading " + filePath
	
	if ( addPrefix )
		if ( strlen( outPrefix ) > 0 )
			if ( setCurrentPrefix )
				NMSet( wavePrefixNoPrompt = outPrefix )
			else
				NMPrefixAdd( outPrefix )
			endif
		endif
	endif
	
	return outPrefix

End // NMImportD3DFile

//****************************************************************
//****************************************************************

Function /S NMD3DUnpack( wName, x1, y1, z1, x2, y2, z2, pointsPerSample, dx, xunits, yunits, outPrefix )
	String wName
	Variable x1, y1, z1, x2, y2, z2
	Variable pointsPerSample
	Variable dx
	String xunits, yunits
	String outPrefix
	
	Variable i, j, k, wcnt, timeSamples, tcnt, scnt, pcnt, offset, chan
	String wName2, ijkStr, yunits2
	
	if ( WaveExists( $wName ) == 0 )
		return ""
	endif
	
	if ( StringMatch( outPrefix, "prompt" ) )
		
		//outPrefix = NMD3DWavePrefix( wName )
		outPrefix = ReplaceString( "Detector", wName, DetectorShortPrefix )
		outPrefix = ReplaceString( "Source", outPrefix, SourceShortPrefix )
		
		if ( strlen( outPrefix ) == 0 )
		
			outPrefix = wName[ 0, 3 ] + "_"
			outPrefix = ReplaceString( "__", outPrefix, "_" )
	
			Prompt outPrefix, "enter wave prefix for unpacked waves (n=" + num2istr( pointsPerSample ) + "):"
			DoPrompt "Unpack " + wName, outPrefix
			
			if ( V_Flag == 1 )
				return "" // cancel
			endif
		
		endif
		
	endif
	
	if ( dx <= 0 )
		dx = 1
	endif
	
	Wave wtemp = $wName
	
	timeSamples = numpnts( wtemp ) / pointsPerSample
	timeSamples = max( timeSamples, 1 )
	
	//Print "Unpacking imported D3D data..."
	
	offset = ( z2 - z1 + 1 ) * ( y2 - y1 + 1 ) * ( x2 - x1 + 1 )
	
	if ( offset == pointsPerSample )
	
		for ( k = z1; k <= z2; k += 1 )
			for ( j = y1; j <= y2; j += 1 )
				for ( i = x1; i <= x2; i += 1 )
					
					ijkStr = "i" + num2istr( i ) + "j" + num2istr( j ) + "k" + num2istr( k )
					
					wName2 = outPrefix + ijkStr + "_A" + num2istr( wcnt )
					
					Make /O/N=( timeSamples ) $wName2 = NaN
					Setscale /P x 0, dx, $wName2
					
					NMNoteType( wName2, "NMD3D", xunits, yunits, "" )
					
					Wave wtemp2 = $wName2
					
					for ( tcnt = 0 ; tcnt < timeSamples ; tcnt += 1 )
					
						scnt = tcnt * offset + pcnt
					
						if ( tcnt < numpnts( wtemp2 ) )
							if ( scnt < numpnts( wtemp ) )
								wtemp2[ tcnt ] = wtemp[ scnt ]
							else
								wtemp2[ tcnt ] = NaN
							endif
						endif
					
					endfor
					
					pcnt += 1
					
				endfor
			endfor
		endfor
	
	else
	
		for ( i = 0 ; i < pointsPerSample ; i += 1 )
		
			chan = i
			wName2 = GetWaveName( outPrefix, chan, wcnt )
			yunits2 = StringFromList( i, yunits )
					
			Make /O/N=( timeSamples ) $wName2 = NaN
			Setscale /P x 0, dx, $wName2
			
			NMNoteType( wName2, "NMD3D", xunits, yunits2, "" )
			
			Wave wtemp2 = $wName2
			
			for ( tcnt = 0 ; tcnt < timeSamples ; tcnt += 1 )
					
				scnt = tcnt * pointsPerSample + pcnt
				
				if ( tcnt < numpnts( wtemp2 ) )
					if ( scnt < numpnts( wtemp ) )
						wtemp2[ tcnt ] = wtemp[ scnt ]
					else
						wtemp2[ tcnt ] = NaN
					endif
				
				endif
			
			endfor
			
			pcnt += 1
		
		endfor
	
	endif
	
	return outPrefix

End // NMD3DUnpack

//****************************************************************
//****************************************************************

Function /S NMD3DWavePrefix( wName )
	String wName
	
	Variable icnt, numChar = strlen( wName )
	String wPrefix
	
	icnt = strsearch( wName, "_", ( numChar - 1 ), 1 )
	
	if ( icnt > 0 )
		return wName[ icnt + 1, numChar - 1 ] + "_"
	endif
	
	if ( strsearch( wName, "_Ca", 0, 2 ) >= 0 )
		return "Ca_"
	endif
	
	return ""
	
End // NMD3DWavePrefix

//****************************************************************
//****************************************************************

Function /S NMD3DSnapUnpack( nrows, ncols, snap, offset, dx, rowUnits, colUnits )
	Variable nrows
	Variable ncols
	String snap // snapshot wave name
	Variable offset
	Variable dx
	String rowUnits
	String colUnits
	
	//print "Unpacking ", snap, "nrows", nrows, "ncols", ncols
	
	Variable i, j, k = offset
	String wName = "S2D_" + snap
	
	if ( !WaveExists( $snap ) || ( k < 0 ) )
		return ""
	endif
	
	if ( dx <= 0 )
		dx = 1
	endif
	
	Wave wtemp = $snap
	
	Make /O/N=( nrows, ncols ) $wName
	
	wave wtemp2 = $wName
	
	for ( j = 0; j < ncols; j += 1 )
	
		if ( k >= numpnts( wtemp ) )
			break
		endif
			
		for ( i = 0; i < nrows; i += 1 )
		
			if ( k >= numpnts( wtemp ) )
				break
			endif
			
			if ( wtemp[ k ] >= 0 )
				wtemp2[ i ][ j ] = wtemp[ k ]
			endif
			
			k+=1
			
		endfor
		
	endfor
	
	Setscale /P x 0, dx, wtemp2
	Setscale /P y 0, dx, wtemp2
	
	return wName

End // NMD3DSnapUnpack

//****************************************************************
//****************************************************************

Function NMD3DSnapGetRow( wName, row, dx )
	String wName
	Variable row
	Variable dx
	
	Variable j, ncols, nrows
	
	String wName2 = "Cleft_" + wName
	
	if ( WaveExists( $wName ) == 0 )
		return -1
	endif
	
	Wave wtemp = $wName
	
	nrows = DimSize( wtemp, 0 )
	ncols = DimSize( wtemp, 1 )
	
	if ( ( numtype( row ) > 0 ) || ( row < 0 ) || ( row >= nrows ) )
		return -1
	endif
	
	if ( ( numtype( dx ) > 0 ) || ( dx <= 0 ) )
		dx = 1
	endif
	
	Make /O/N=( ncols ) $wName2
	
	Wave wtemp2 = $wName2
	
	wtemp2 = Nan
	
	Setscale /P x 0, dx, wtemp2
	
	//dx = ( 0.02 * x ) - 2.9
	
	for ( j = 0; j < ncols; j+= 1 )
		if ( wtemp[ row ][ j ] >= 0 )
			wtemp2[ j ] = wtemp[ row ][ j ]
		endif
	endfor

End // NMD3DSnapGetRow

//****************************************************************
//****************************************************************

Function NMD3DSnapGetCol( wName, col, dx )
	String wName
	Variable col
	Variable dx
	
	Variable j, ncols, nrows
	
	String wName2 = "Cleft_" + wName
	
	if ( WaveExists( $wName ) == 0 )
		return -1
	endif
	
	Wave wtemp = $wName
	
	nrows = DimSize( wtemp, 0 )
	ncols = DimSize( wtemp, 1 )
	
	if ( ( numtype( col ) > 0 ) || ( col < 0 ) || ( col >= ncols ) )
		return -1
	endif
	
	if ( ( numtype( dx ) > 0 ) || ( dx <= 0 ) )
		dx = 1
	endif
	
	Make /O/N=( nrows ) $wName2
	
	Wave wtemp2 = $wName2
	
	wtemp2 = Nan
	
	Setscale /P x 0, dx, wtemp2
	
	//dx = ( 0.02 * x ) - 2.9
	
	for ( j = 0; j < nrows; j+= 1 )
		if ( wtemp[ j ][ col ] >= 0 )
			wtemp2[ j ] = wtemp[ j ][ col ]
		endif
	endfor

End // NMD3DSnapGetCol

//****************************************************************
//****************************************************************

Function /S NMD3DConfigWaveList()

	String wList = WaveList( "D3Dconfig" + "*", ";", "TEXT:1" )
	
	wList = SortList( wList, ";", 16)
	
	return wList

End // NMD3DConfigWaveList

//****************************************************************
//****************************************************************

Function /S NMD3DTextWaveStr( textWaveName, paramName )
	String textWaveName // text wave name
	String paramName // parameter name to find
	
	Variable icnt, jcnt, kcnt, avg, count
	String wName, pstr, rList = ""
	
	if ( WaveExists( $textWaveName ) == 0 )
		return ""
	endif
		
	Wave /T wtemp = $textWaveName
		
	for ( jcnt = 0 ; jcnt < numpnts( wtemp ) ; jcnt += 1 )
	
		pstr = wtemp[ jcnt ]
		
		if ( strsearch( pstr, paramName, 0, 2 ) < 0 )
			continue
		endif
		
		kcnt = strsearch( pstr, "=", 0 )
		
		if ( kcnt < 0 )
		
			kcnt = strsearch( pstr, ":", 0 )
		
			if ( kcnt < 0 )
				return "" // something is wrong
			endif
			
		endif
		
		return pstr[ kcnt + 1, inf ]
		
	endfor
	
	return ""
	
End // NMD3DTextWaveStr

//****************************************************************
//****************************************************************


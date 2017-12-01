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
//	Read PClamp Functions
//
//	PClamp file header details from Axon Instruments, now Molecular Devices. 
//	Code for reading ABF format 1 and 2 files.
//	Code for calling ReadPclampXOP if installed.
//
//	Non-Static functions to be called:
//	ReadPclampFormat( file )
//	ReadPClampHeader( file, dataFolder )
//	ReadPClampData( file, dataFolder )
//	NM_ABFHeaderVar( varNameOrMatchStr [ folder, alert ] ) // reads from existing ABFHeader subfolder
//	NM_ABFHeaderStr( varNameOrMatchStr [ folder, alert ] ) // reads from existing ABFHeader subfolder
//	NM_ABFHeaderWaveName( matchStr [ folder ] ) // returns full path name for wave in ABFHeader subfolder
//
//****************************************************************
//****************************************************************

Static Constant ABF_SCALEWAVES = 1 // ( 0 ) no ( 1 ) yes, scale waves by scale factor read from header file
Static Constant ABF_XOP_ON = 1 // ( 0 ) no, turn off XOP if it exists ( slower ) ( 1 ) yes, use XOP to read data if it exists 

Static StrConstant ABF_SUBFOLDERNAME = "ABFHeader"
Static StrConstant ABF_WAVENAMETIME1 = "ABF_WaveTimeStamps"
Static StrConstant ABF_WAVENAMETIME2 = "ABF_WaveStartTimes"
StrConstant ABF_STRINGERROR = "CouldNotFindHeaderString"

//****************************************************************
//****************************************************************
//****************************************************************

Static Constant ABF_NUMADCS = 16
Static Constant ABF_NUMDACS = 4
Static Constant ABF_EPOCHCOUNT = 10
Static Constant ABF_ADCUNITLEN = 8
Static Constant ABF_ADCNAMELEN = 10
Static Constant ABF_DACUNITLEN = 8
Static Constant ABF_DACNAMELEN = 10
Static Constant ABF_BLOCK = 512

//****************************************************************
//****************************************************************
//****************************************************************

Function ReadPclampXOPExists()

	if ( ABF_XOP_ON && ( exists( "ReadPclamp" ) == 4 ) )
		return 1
	endif

	return 0
	
End // ReadPclampXOPExists

//****************************************************************
//****************************************************************
//****************************************************************

Function NM_ABFHeaderVar( varNameOrMatchStr [ folder, alert ] )
	String varNameOrMatchStr
	String folder
	Variable alert
	
	String varList, varName = ""
	
	if ( ParamIsDefault( folder ) )
		folder = CurrentNMFolder( 1 ) + ABF_SUBFOLDERNAME + ":"
	else
		folder = ParseFilePath( 2, folder, ":", 0, 0 ) + ABF_SUBFOLDERNAME + ":"
	endif
	
	if ( strsearch( varNameOrMatchStr, "*", 0 ) >= 0 ) // found match string
	
		varList = NMFolderVariableList( folder, varNameOrMatchStr, ";", 4, 0 )
	
		if ( ItemsInList( varList ) > 0 )
			varName = StringFromList( 0, varList )
		endif
		
	else
	
		varName = varNameOrMatchStr
	
	endif
	
	if ( ( strlen( varName ) > 0 ) && ( exists( folder + varName ) == 2 ) )
		return NumVarOrDefault( folder + varName, NaN )
	endif
	
	if ( alert )
		NM2Error( 13, "varNameOrMatchStr", varNameOrMatchStr )
	endif
		
	return NaN
	
End // NM_ABFHeaderVar

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NM_ABFHeaderStr( varNameOrMatchStr [ folder, alert ] )
	String varNameOrMatchStr
	String folder
	Variable alert
	
	String varList, varName = ""
	
	if ( ParamIsDefault( folder ) )
		folder = CurrentNMFolder( 1 ) + ABF_SUBFOLDERNAME + ":"
	else
		folder = ParseFilePath( 2, folder, ":", 0, 0 ) + ABF_SUBFOLDERNAME + ":"
	endif
	
	if ( strsearch( varNameOrMatchStr, "*", 0 ) >= 0 ) // found match string
	
		varList = NMFolderStringList( folder, varNameOrMatchStr, ";", 0 )
	
		if ( ItemsInList( varList ) > 0 )
			varName = StringFromList( 0, varList )
		endif
		
	else
	
		varName = varNameOrMatchStr
	
	endif
	
	if ( ( strlen( varName ) > 0 ) && ( exists( folder + varName ) == 2 ) )
		return StrVarOrDefault( folder + varName, ABF_STRINGERROR )
	endif
	
	if ( alert )
		NM2Error( 23, "varNameOrMatchStr", varNameOrMatchStr )
	endif
		
	return ABF_STRINGERROR
	
End // NM_ABFHeaderStr

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NM_ABFHeaderWaveName( matchStr [ folder ] )
	String matchStr
	String folder
	
	String wList, wName
	
	if ( ParamIsDefault( folder ) )
		folder = CurrentNMFolder( 1 ) + ABF_SUBFOLDERNAME + ":"
	else
		folder = ParseFilePath( 2, folder, ":", 0, 0 ) + ABF_SUBFOLDERNAME + ":"
	endif
	
	wList = NMFolderWaveList( folder, matchStr, ";", "", 1 )

	if ( ItemsInList( wList ) > 0 )
		return StringFromList( 0, wList )
	endif
	
	return ""
	
End // NM_ABFHeaderWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function ReadPclampFormat( file )
	String file // external ABF data file
	
	String fileID = ReadPclampString( file, 0, 4 ) // file ID signature
	
	KillWaves /Z NM_ReadPclampWave0, NM_ReadPclampWave1
	
	strswitch( fileID )
		case "ABF ":
			return 1
		case "ABF2":
			return 2
	endswitch
	
	return -1
	
End // ReadPclampFormat

//****************************************************************
//****************************************************************
//****************************************************************

Function ReadPClampHeader( file, df )
	String file // external ABF data file
	String df // NM data folder where everything is imported
	
	Variable format = ReadPclampFormat( file )
	
	df = ParseFilePath( 2, df, ":", 0, 0 )
	
	switch( format )
		case 1:
		case 2:
			break
		default:
			Print "Import File Aborted: file not of Pclamp format"
			return -1
	endswitch
	
	if ( ReadPclampXOPExists() )
		return ReadPClampHeaderXOP( file, df )
	endif
	
	switch( format )
		case 1:
			return ReadPClampHeader1( file, df )
		case 2:
			return ReadPClampHeader2( file, df )
	endswitch
	
	//ReadPclampXOPAlert()
	
	return -1
	
End // ReadPClampHeader

//****************************************************************
//****************************************************************
//****************************************************************

Function ReadPClampData( file, df )
	String file // external ABF data file
	String df // NM data folder where everything is imported
	
	Variable format = ReadPclampFormat( file )
	
	df = ParseFilePath( 2, df, ":", 0, 0 )
		
	switch( format )
		case 1:
		case 2:
			break
		default:
			Print "Import File Aborted: file not of Pclamp format"
			return -1
	endswitch
	
	if ( ReadPclampXOPExists() )
		return ReadPClampDataXOP( file, df )
	endif
	
	switch( format )
		case 1:
		case 2: // can use old version for reading data
			return ReadPClampData1( file, df ) 
	endswitch
	
	//ReadPclampXOPAlert()
	
	return -1
	
End // ReadPClampData

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Read ABF Utility Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function ReadPclampVarPointer( file, varType )
	String file // external ABF data file
	String varType // variable type
	
	if ( exists( "ABF_Read_Pointer" ) != 2 )
		NM2Error( 13, "ABF_Read_Pointer", "" )
		return NaN // this global variable is required
	endif
	
	NVAR ABF_Read_Pointer
	
	ABF_Read_Pointer = ReadPclampFile( file, varType, ABF_Read_Pointer, 1 )
	
	if ( numtype( ABF_Read_Pointer ) > 0 )
		NM2Error( 10, "ABF_Read_Pointer", num2str( ABF_Read_Pointer ) )
		return Nan
	endif
	
	if ( !WaveExists( $"NM_ReadPclampWave0" ) )
		NM2Error( 1, "NM_ReadPclampWave0", "" )
		return Nan
	endif
	
	Wave NM_ReadPclampWave0
	
	if ( 0 < numpnts( NM_ReadPclampWave0 ) )
		return NM_ReadPclampWave0[ 0 ]
	else
		return NaN
	endif

End // ReadPclampVarPointer

//****************************************************************
//****************************************************************
//****************************************************************

Function ReadPclampVar( file, varType, pointer )
	String file // external ABF data file
	String varType // variable type
	Variable pointer // read file pointer in bytes
	
	if ( !FileExistsAndNonZero( file ) )
		return NaN
	endif
	
	pointer = ReadPclampFile( file, varType, pointer, 1 )
	
	if ( numtype( pointer ) > 0 )
		NM2Error( 10, "pointer", num2str( pointer ) )
		return Nan
	endif
	
	if ( !WaveExists( $"NM_ReadPclampWave0" ) )
		NM2Error( 1, "NM_ReadPclampWave0", "" )
		return Nan
	endif
	
	Wave NM_ReadPclampWave0
	
	if ( 0 < numpnts( NM_ReadPclampWave0 ) )
		return NM_ReadPclampWave0[ 0 ]
	else
		return NaN
	endif

End // ReadPclampVar

//****************************************************************
//****************************************************************
//****************************************************************

Function /T ReadPclampString( file, pointer, numCharToRead )
	String file // external ABF data file
	Variable pointer // read file pointer in bytes
	Variable numCharToRead // number of characters to read
	
	Variable icnt
	String str = ""
	
	if ( !FileExistsAndNonZero( file ) )
		return ""
	endif
	
	pointer = ReadPclampFile( file, "char", pointer, numCharToRead )
	
	if ( numtype( pointer ) > 0 )
		return NM2ErrorStr( 10, "pointer", num2str( pointer ) )
	endif
	
	if ( !WaveExists( $"NM_ReadPclampWave0" ) )
		return NM2ErrorStr( 1, "NM_ReadPclampWave0", "" )
	endif
	
	Wave NM_ReadPclampWave0
	
	for ( icnt = 0 ; icnt < numCharToRead ; icnt += 1 )
		if ( icnt < numpnts( NM_ReadPclampWave0 ) )
			str += num2char( NM_ReadPclampWave0[ icnt ] )
		endif
	endfor
	
	return str

End // ReadPclampString

//****************************************************************
//****************************************************************
//****************************************************************

Function ReadPclampFile( file, varType, pointer, numVarToRead )
	String file // external ABF data file
	String varType // variable type
	Variable pointer // read file pointer in bytes
	Variable numVarToRead // number of variables to read starting from pointer
	
	Variable bytes = 0
	
	if ( !FileExistsAndNonZero( file ) )
		return Nan
	endif
	
	if ( ( numtype( pointer ) > 0 ) || ( pointer < 0 ) )
		NM2Error( 10, "pointer", num2str( pointer ) )
		return Nan
	endif
	
	if ( ( numtype( numVarToRead ) > 0 ) || ( numVarToRead < 0 ) )
		NM2Error( 10, "numVarToRead", num2str( numVarToRead ) )
		return Nan
	endif
	
	strswitch( varType )
	
		case "char":
			bytes = 1
			GBLoadWave /B/N=NM_ReadPClampWave/O/S=(pointer)/T={8,8+64}/U=(numVarToRead)/W=1/Q file
			break
			
		case "unicode":
		case "short":
			bytes = 2
			GBLoadWave /B/N=NM_ReadPClampWave/O/S=(pointer)/T={16,2}/U=(numVarToRead)/W=1/Q file
			break
			
		case "uint": // unsigned integer
			bytes = 4
			GBLoadWave /B/N=NM_ReadPClampWave/O/S=(pointer)/T={32+64,32+64}/U=(numVarToRead)/W=1/Q file
			break
			
		case "long":
			bytes = 4
			GBLoadWave /B/N=NM_ReadPClampWave/O/S=(pointer)/T={32,2}/U=(numVarToRead)/W=1/Q file
			break
			
		case "float":
			bytes = 4
			GBLoadWave /B/N=NM_ReadPClampWave/O/S=(pointer)/T={2,2}/U=(numVarToRead)/W=1/Q file
			break
			
		case "double":
			bytes = 8
			GBLoadWave /B/N=NM_ReadPClampWave/O/S=(pointer)/T={4,4}/U=(numVarToRead)/W=1/Q file
			break
			
		default:
			NM2Error( 20, "varType", varType )
			return Nan
			
	endswitch
	
	return ( pointer + bytes * numVarToRead )
	
End // ReadPclampFile

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /T RemoveEndSpaces( str )
	String str
	Variable icnt
	
	for ( icnt = strlen( str ) - 1; icnt >= 0; icnt -= 1 )
		if ( !stringmatch( str[ icnt, icnt ], " " ) )
			return str[ 0, icnt ]
		endif
	endfor
	
	return str
	
End // RemoveEndSpaces

//****************************************************************
//****************************************************************
//****************************************************************
//
//	ReadPclampHeaderUpdateNM parameters
//
//	VARIABLES
//	nOperationMode
//	nDataFormat
//	lActualAcqLength	 // ReadPclampHeader1 or XOP
//	SectionData_NumEntries1 // ReadPclampHeader2
//	nADCNumChannels
//	lNumSamplesPerEpisode
//	lActualEpisodes // ReadPclampHeader1 or XOP
//	uActualEpisodes // ReadPclampHeader2
//	fADCSampleInterval
//	fADCSequenceInterval
//	fADCSecondSampleInterval
//	fADCRange
//	lADCResolution
//
//	WAVES
//	nADCSamplingSeq
//	fInstrumentScaleFactor
//	sADCChannelName
//	sADCUnits
//	fTelegraphAdditGain
//
//****************************************************************
//****************************************************************
//****************************************************************

Static Function ReadPclampHeaderUpdateNM( df, hdf )
	String df // where to update NM variables and waves
	String hdf // ABF header data folder
	
	Variable ccnt, chanNum, tempvar
	Variable amode, dataFormat, acqLength, numChannels, samplesPerWave, episodes
	Variable sampleInterval, splitClock, ADCRange
	String acqMode, yl, yu, wName
	String thisfxn = GetRTStackInfo( 1 )
	
	df = ParseFilePath( 2, df, ":", 0, 0 )

	CheckNMwave( df+"FileScaleFactors", ABF_NUMADCS, 1 )
	CheckNMtwave( df+"yLabel", ABF_NUMADCS, "" )
	
	Wave scaleFactors = $df+"FileScaleFactors"
	Wave /T yAxisLabels = $df+"yLabel"
	
	scaleFactors = 1
	yAxisLabels = ""
	
	amode = NM_ABFHeaderVar( "*OperationMode", folder = df )
	
	switch( amode )
		case 1:
			acqMode = "1 ( Event-Driven )"
			break
		case 2:
			acqMode = "2 ( Oscilloscope, loss free )"
			break
		case 3:
			acqMode = "3 ( Gap-Free )"
			break
		case 4:
			acqMode = "4 ( Oscilloscope, high-speed )"
			break
		case 5:
			acqMode = "5 ( Episodic )"
			break
		default:
			Print thisfxn + " Error: unknown acquisition mode :", acqMode
			return -1
	endswitch
	
	SetNMstr( df+"AcqMode", acqMode )
	
	dataFormat = NM_ABFHeaderVar( "*DataFormat", folder = df, alert = 1 )
	
	if ( numtype( dataFormat ) > 0 )
		Print thisfxn + " Error: unknown data format"
		return -1
	endif
	
	SetNMvar( df+"DataFormat", dataFormat )
	
	acqLength = NM_ABFHeaderVar( "*ActualAcqLength", folder = df ) // ReadPclampHeader1 or XOP
	
	if ( numtype( acqLength ) > 0 )
		acqLength = NM_ABFHeaderVar( "*SectionData_NumEntries1", folder = df ) // ReadPclampHeader2
	endif
	
	if ( acqLength < 0 )
		Print thisfxn + " Error: unknown acquisition length :", acqLength
		return -1
	endif
	
	SetNMvar( df+"AcqLength", acqLength )
	
	numChannels = NM_ABFHeaderVar( "*ADCNumChannels", folder = df )

	if ( ( numtype( numChannels ) > 0 ) || ( numChannels <= 0 ) )
		Print thisfxn + " Error: unknown number of channels :", numChannels
		return -1
	endif
	
	SetNMvar( df+"NumChannels", numChannels )
	
	samplesPerWave = NM_ABFHeaderVar( "*NumSamplesPerEpisode", folder = df )
	
	if ( ( numtype( samplesPerWave ) > 0 ) || ( samplesPerWave < 0 ) )
		Print thisfxn + " Error: unknown number of samples :", samplesPerWave
		return -1
	endif
	
	if ( numChannels > 1 )
		samplesPerWave /= numChannels
	endif
	
	SetNMvar( df+"SamplesPerWave", samplesPerWave )
	
	episodes = NM_ABFHeaderVar( "*ActualEpisodes", folder = df )
	
	if ( numtype( episodes ) > 0 )
		Print thisfxn + " Error: unknown number of episodes"
		return -1
	endif
	
	if ( ( amode == 3 ) || ( episodes == 0 ) ) // gap free
		episodes = acqLength / ( SamplesPerWave * NumChannels )
	endif
	
	if ( episodes <= 0 )
		Print thisfxn + " Error: unknown number of episodes :", episodes
		return -1
	endif
	
	SetNMvar( df+"NumWaves", episodes )
	SetNMvar( df+"TotalNumWaves", episodes * NumChannels )
	
	sampleInterval = NM_ABFHeaderVar( "*ADCSampleInterval", folder = df )
	
	if ( numtype( sampleInterval ) > 0 )
		sampleInterval = NM_ABFHeaderVar( "*ADCSequenceInterval", folder = df )
		sampleInterval = sampleInterval / 1000
	elseif ( sampleInterval > 0 )
		sampleInterval = ( sampleInterval * NumChannels ) / 1000
	endif
	
	if ( ( numtype( sampleInterval ) > 0 ) || ( sampleInterval <= 0 ) )
		Print thisfxn + " Error: unknown sample interval :", sampleInterval
		return -1
	endif
	
	SetNMvar( df+"SampleInterval", sampleInterval )
	
	splitClock = NM_ABFHeaderVar( "*ADCSecondSampleInterval", folder = df )
	SetNMvar( df+"SplitClock", splitClock )
	
	if ( ( numtype( splitClock ) == 0 ) && ( splitClock > 0 ) )
		NMDoAlert( "Warning: data contains split-clock recording, which is not supported by this version of NeuroMatic." )
	endif
	
	//
	// Hardware Info
	//
	
	ADCRange = NM_ABFHeaderVar( "*ADCRange", folder = df ) // ADC positive full-scale input ( volts )
	SetNMvar( df+"ADCRange", ADCRange )
	
	Variable ADCResolution = NM_ABFHeaderVar( "*ADCResolution", folder = df ) // number of ADC counts in ADC range
	SetNMvar( df+"ADCResolution", ADCResolution )
	
	//
	// Multi-channel Info
	//
	
	wName = NM_ABFHeaderWaveName( "*ADCSamplingSeq", folder = df )
	
	if ( !WaveExists( $wName ) )
		Print thisfxn + " Error: cannot locate ADCSamplingSeq wave"
		return -1
	endif
	
	Wave nADCSamplingSeq = $wName
	
	wName = NM_ABFHeaderWaveName( "*InstrumentScaleFactor", folder = df )
	
	if ( !WaveExists( $wName ) )
		Print thisfxn + " Error: cannot locate InstrumentScaleFactor wave"
		return -1
	endif
	
	Wave fInstrumentScaleFactor = $wName
	
	wName = NM_ABFHeaderWaveName( "*ADCChannelName", folder = df )
	
	if ( !WaveExists( $wName ) )
		Print thisfxn + " Error: cannot locate ADCChannelName wave"
		return -1
	endif
	
	Wave /T sADCChannelName = $wName
	
	wName = NM_ABFHeaderWaveName( "*ADCUnits", folder = df )
	
	if ( !WaveExists( $wName ) )
		Print thisfxn + " Error: cannot locate ADCUnits wave"
		return -1
	endif
	
	Wave /T sADCUnits = $wName

	for ( ccnt = 0; ccnt < NumChannels; ccnt += 1 )
	
		if ( ( ccnt >= numpnts( nADCSamplingSeq ) ) || ( ccnt >= numpnts( yAxisLabels ) ) )
			break
		endif
		
		chanNum = nADCSamplingSeq[ ccnt ]
		
		if ( ( chanNum >= 0 ) && ( chanNum < numpnts( sADCChannelName ) ) )
		
			yl = RemoveEndSpaces( sADCChannelName[ chanNum ] )
			yu = RemoveEndSpaces( sADCUnits[ chanNum ] )
			
			if ( ( strlen( yl ) > 0 ) || ( strlen( yu ) > 0 ) )
				yAxisLabels[ ccnt ] = yl + " ( " + yu + " )"
			endif
			
		endif
		
	endfor
	
	for ( ccnt = 0; ccnt < NumChannels; ccnt += 1 )
	
		if ( ( ccnt >= numpnts( nADCSamplingSeq ) ) || ( ccnt >= numpnts( scaleFactors ) ) )
			break
		endif
	
		chanNum = nADCSamplingSeq[ ccnt ]
		
		if ( ( chanNum >= 0 ) && ( chanNum < numpnts( fInstrumentScaleFactor ) ) )
			tempvar = fInstrumentScaleFactor[ chanNum ]
		else
			tempvar = Nan
		endif
		
		if ( ( numtype( tempvar ) == 0 ) && ( tempvar > 0 ) )
			scaleFactors[ ccnt ] = ADCRange / ( ADCResolution * tempvar )
		else
			scaleFactors[ ccnt ] = ADCRange / ADCResolution
		endif
		
	endfor
	
	//
	// Extended Environmental Info
	//
	
	wName = NM_ABFHeaderWaveName( "*TelegraphAdditGain", folder = df )
	
	if ( WaveExists( $wName ) )
	
		Wave fTelegraphAdditGain = $wName
	
		for ( ccnt = 0; ccnt < NumChannels; ccnt += 1 )
		
			if ( ( ccnt >= numpnts( nADCSamplingSeq ) ) || ( ccnt >= numpnts( scaleFactors ) ) )
				break
			endif
		
			chanNum = nADCSamplingSeq[ ccnt ]
		
			if ( ( chanNum >= 0 ) && ( chanNum < numpnts( fTelegraphAdditGain ) ) )
				tempvar = fTelegraphAdditGain[ chanNum ]
			else
				tempvar = NAN
			endif
			
			if ( ( numtype( tempvar ) == 0 ) && ( tempvar > 0 ) )
				scaleFactors[ ccnt ] /= tempvar
				//print "chan" + num2istr( ccnt ) + " telegraph gain:", NM_ReadPclampWave0[ ccnt ]
			endif
			
		endfor
	
	endif
	
	CheckNMwave( df+"FileScaleFactors", numChannels, 1 )
	CheckNMtwave( df+"yLabel", numChannels, "" )
	
	return 0
	
End // ReadPclampHeaderUpdateNM

//****************************************************************
//****************************************************************
//****************************************************************

Static Function PclampTimeStamps( file, format, amode, df, wName, episodeNum ) // modified from code from Gerard Borst, Erasmus MC, Dept of Neuroscience
	String file
	Variable format // pclamp format
	Variable amode // acquisition mode
	String df // NM data folder where everything is imported
	String wName // wave name
	Variable episodeNum // corresponding episode number for this wave
	
	Variable fileStartTime, fileStartMillisecs, stopwatchTime
	Variable runsPerTrial, episodesPerRun, triggerSource, episodeStartToStart, recordStart
	String tstr, wNote
	String thisfxn = GetRTStackInfo( 1 )
	
	df = ParseFilePath( 2, df, ":", 0, 0 )
	
	String wavePrefix = StrVarOrDefault( df + "WavePrefix", NMStrGet( "WavePrefix" ) )
	String wNameT1 = df + ABF_WAVENAMETIME1
	String wNameT2 = df + ABF_WAVENAMETIME2
	
	Variable sampleInterval = NumVarOrDefault( df + "SampleInterval", NaN )
	Variable samplesPerWave = NumVarOrDefault( df + "SamplesPerWave", NaN )
	Variable numChannels = NumVarOrDefault( df + "NumChannels", NaN )
	
	if ( ( numtype( sampleInterval ) > 0 ) || ( numtype( samplesPerWave ) > 0 ) )
		Print thisfxn + " Error: cannot locate SampleInterval or SamplesPerWave"
		return -1
	endif
	
	if ( ( numtype( numChannels ) > 0 ) || ( numChannels <= 0 ) )
		Print thisfxn + " Error: cannot locate NumChannels"
		return -1
	endif
	
	fileStartTime = NM_ABFHeaderVar( "*FileStartTimeMS", folder = df )
	
	if ( numtype( fileStartTime ) == 0 )
		fileStartTime /= 1000 // convert to seconds
	else
		fileStartTime = NM_ABFHeaderVar( "*FileStartTime", folder = df )
		// time of day in seconds past midnight when data portion of this file was first written to
	endif
	
	if ( numtype( fileStartTime ) > 0 )
		Print thisfxn + " Error: cannot locate FileStartTime"
		return -1
	endif
	
	fileStartMillisecs = NM_ABFHeaderVar( "*FileStartMillisecs", folder = df ) // msec portion of lFileStartTime
	
	if ( numtype( fileStartMillisecs ) ==  0 )
		fileStartTime += fileStartMillisecs / 1000
	endif
	
	//Print "FileStartTime", NMSecondsToStopwatch( fileStartTime )
	tstr = NMSecondsToStopwatch( fileStartTime )
	tstr = ReplaceString( ":", tstr, "," )
	NMNoteStrReplace( wName, "ABF_FileStartTime", tstr )
	sprintf tstr, "%.3f", fileStartTime
	NMNoteStrReplace( wName, "ABF_FileStartTimeSeconds", tstr )
	
	stopwatchTime = NM_ABFHeaderVar( "*StopwatchTime", folder = df )
	
	if ( numtype( stopwatchTime ) > 0 )
		Print thisfxn + " Error: cannot locate StopwatchTime"
		return -1
	endif
	
	//Print "StopwatchTime", NMSecondsToStopwatch( stopwatchTime )
	tstr = NMSecondsToStopwatch( stopwatchTime )
	tstr = ReplaceString( ":", tstr, "," )
	NMNoteStrReplace( wName, "ABF_StopwatchTime", tstr )
	sprintf tstr, "%.3f", stopwatchTime
	NMNoteStrReplace( wName, "ABF_StopwatchTimeSeconds", tstr )
	
	runsPerTrial = NM_ABFHeaderVar( "*RunsPerTrial", folder = df )
	// requested number of runs/trial.  0=Run until terminated by user. Runs are averaged.  If nOperationMode = 3 (gap free), the value of this parameter is 1.  See lAverageCount.
	
	if ( numtype( runsPerTrial ) > 0 )
		Print thisfxn + " Error: cannot locate RunsPerTrial"
		return -1
	endif
	
	if ( runsPerTrial > 1 )
		return 0 // finished, the remaining code currently only works for files with one run per trial
	endif
	
	episodesPerRun = NM_ABFHeaderVar( "*EpisodesPerRun", folder = df )
	// requested number of episodes/run.  0=Run until terminated by user. If nOperationMode = 3 (gap free), this parameter is 1 and the requested acquisition length is set in fSecondsPerRun.
	
	if ( numtype( episodesPerRun ) > 0 )
		Print thisfxn + " Error: cannot locate EpisodesPerRun"
		return -1
	endif
	
	triggerSource = NM_ABFHeaderVar( "*TriggerSource", folder = df )
	// trigger source:  N (>=0) = Physical channel number selected for threshold detection;  -1 = external trigger;  -2 = keyboard;  -3 = use start-to-start interval. If nOperationMode=3 (gap-free)  0 = start immediately.
	
	if ( numtype( triggerSource ) > 0 )
		Print thisfxn + " Error: cannot locate TriggerSource"
		return -1
	endif
	
	episodeStartToStart = NM_ABFHeaderVar( "*EpisodeStartToStart", folder = df )
	// time between start of sweeps (seconds).  Use when nTriggerSource = "start-to-start".
	
	if ( numtype( episodeStartToStart ) > 0 )
		Print thisfxn + " Error: cannot locate EpisodeStartToStart"
		return -1
	endif
	
	if ( ( episodesPerRun > 1 ) && ( triggerSource != -3 ) && ( episodeNum > 0 ) )
		//Print "Start of episode cannot be reliably determined from ABF header"
		return 0
	endif
	
	if ( ( episodesPerRun == 1 ) && ( episodeNum > 0 ) )
		//Print thisfxn + " Error: wrong episode number : ", episodeNum
		//return -1
		// could be gap-free with XOP import
	endif
	
	recordStart = fileStartTime + episodeNum * episodeStartToStart // assumes no missing traces, ascending order, etc.  !!!!!!!!!!!!!!!!!
	
	tstr = NMSecondsToStopwatch( recordStart )
	tstr = ReplaceString( ":", tstr, "," )
	
	NMNoteStrReplace( wName, "ABF_EpisodeTime", tstr )
	
	sprintf tstr, "%.3f", recordStart

	NMNoteStrReplace( wName, "ABF_EpisodeTimeSeconds", tstr )
	
	if ( ( amode == 3 ) || ( episodesPerRun <= 1 ) )
		return 0
	endif
	
	if ( WaveExists( $wNameT1 ) == 0 )
	
		Make /O/N=( episodesPerRun ) $wNameT1 = NaN
		
		wNote = "Folder:" + GetDataFolder( 0 )
		wNote += NMCR + "File:" + NMNoteCheck( file )
		NMNoteType( wNameT1, "Pclamp " + num2str( format ), "episode #", "seconds past midnight", wNote )
		
	endif
	
	if ( WaveExists( $wNameT2 ) == 0 )
	
		Make /O/N=( episodesPerRun ) $wNameT2 = NaN
		
		wNote = "Folder:" + GetDataFolder( 0 )
		wNote += NMCR + "File:" + NMNoteCheck( file )
		NMNoteType( wNameT2, "Pclamp " + num2str( format ), "episode #", NMXunits, wNote )
	
	endif
	
	Wave wt1 = $wNameT1
	
	if ( ( episodeNum >= 0 ) && ( episodeNum < numpnts( wt1 ) ) && ( numtype( wt1[ episodeNum ] ) > 0 ) )
		wt1[ episodeNum ] = recordStart
	endif
	
	Wave wt2 = $wNameT2
	
	if ( ( episodeNum >= 0 ) && ( episodeNum < numpnts( wt2 ) ) && ( numtype( wt2[ episodeNum ] ) > 0 ) )
		wt2[ episodeNum ] = episodeNum * episodeStartToStart * 1000 // ms
	endif
	
	return 0

End // PclampTimeStamps

//****************************************************************
//****************************************************************
//****************************************************************
//
//	ABF format 1
//
//****************************************************************
//****************************************************************
//****************************************************************

Static Function ReadPClampHeader1( file, df )
	String file // external ABF data file
	String df // NM data folder where everything is imported

	Variable ccnt, icnt, chan
	Variable numChannels, headerSize
	String fileSignature
	
	Variable readAll = NumVarOrDefault( NMDF+"ABF_HeaderReadAll", 0 )
	
	if ( ReadPclampFormat( file ) != 1 )
		return -1
	endif
	
	df = ParseFilePath( 2, df, ":", 0, 0 )
	
	String hdf = df + ABF_SUBFOLDERNAME + ":"
	
	if ( readAll )
		NMProgressCall( -1, "Reading ABF Header ..." )
	endif
	
	NewDataFolder /O $RemoveEnding( hdf, ":" ) // create subfolder in current directory
	
	// File ID and Size information
	
	fileSignature = ReadPclampString( file, 0, 4 )
	
	strswitch( fileSignature )
		case "ABF ":
		case "CLPX":
		case "FTCX":
			String /G $hdf +"sFileSignature" = fileSignature
			break
		default: // must be older ABF version
			Variable /G $hdf +"lFileSignature" = ReadPclampVar( file, "long", 0 )
	endswitch
	
	Variable /G $hdf +"fFileVersionNumber" = ReadPclampVar( file, "float", 4 )
	Variable /G $hdf +"nOperationMode" = ReadPclampVar( file, "short", 8 ) // NEED THIS
	Variable /G $hdf +"lActualAcqLength" = ReadPclampVar( file, "long", 10 ) // NEED THIS
	Variable /G $hdf +"nNumPointsIgnored" = ReadPclampVar( file, "short", 14 )
	Variable /G $hdf +"lActualEpisodes" = ReadPclampVar( file, "long", 16 )
	Variable /G $hdf +"lFileStartDate" = ReadPclampVar( file, "long", 20 ) // NEED THIS
	Variable /G $hdf +"lFileStartTime" = ReadPclampVar( file, "long", 24 ) // NEED THIS
	Variable /G $hdf +"lStopwatchTime" = ReadPclampVar( file, "long", 28 ) // NEED THIS
	Variable /G $hdf +"fHeaderVersionNumber" = ReadPclampVar( file, "float", 32 )
	Variable /G $hdf +"nFileType" = ReadPclampVar( file, "short", 36 ) // FileFormat
	Variable /G $hdf +"nMSBinFormat" = ReadPclampVar( file, "short", 38 )
	
	//
	// File Structure info
	//
	
	Variable /G $hdf +"lDataSectionPtr" = ReadPclampVar( file, "long", 40 ) // DataPointer, NEED THIS
	
	SetNMvar( df+"DataPointer", NumVarOrDefault( hdf +"lDataSectionPtr", -1 ) )
	
	if ( readAll )
		Variable /G $hdf +"lTagSectionPtr" = ReadPclampVar( file, "long", 44 )
		Variable /G $hdf +"lNumTagEntries" = ReadPclampVar( file, "long", 48 )
		Variable /G $hdf +"lScopeConfigPtr" = ReadPclampVar( file, "long", 52 )
		Variable /G $hdf +"lNumScopes" = ReadPclampVar( file, "long", 56 )
		Variable /G $hdf +"lDACFilePtr" = ReadPclampVar( file, "long", 60 )
		Variable /G $hdf +"lDACFileNumEpisodes" = ReadPclampVar( file, "long", 64 )
		Variable /G $hdf +"lDeltaArrayPtr" = ReadPclampVar( file, "long", 72 )
		Variable /G $hdf +"lNumDeltas" = ReadPclampVar( file, "long", 76 )
		Variable /G $hdf +"lVoiceTagPtr" = ReadPclampVar( file, "long", 80 )
		Variable /G $hdf +"lVoiceTagEntries" = ReadPclampVar( file, "long", 84 )
		Variable /G $hdf +"lSynchArrayPtr" = ReadPclampVar( file, "long", 92 )
		Variable /G $hdf +"lSynchArraySize" = ReadPclampVar( file, "long", 96 )
	endif
	
	Variable /G $hdf +"nDataFormat" = ReadPclampVar( file, "short", 100 ) // DataFormat, NEED THIS
	Variable /G $hdf +"nSimultaneousScan" = ReadPclampVar( file, "short", 102 )
	
	if ( readAll && ( NMProgressCall( -2, "Reading ABF Header ..." ) == 1 ) )
		return -1 // cancel
	endif
		
	//
	// Trial Hierarchy Information
	//
	
	Variable /G $hdf +"nADCNumChannels" = ReadPclampVar( file, "short", 120 ) // NumChannels, NEED THIS
	Variable /G $hdf +"fADCSampleInterval" = ReadPclampVar( file, "float", 122 ) // SampleInterval, NEED THIS
	Variable /G $hdf +"fADCSecondSampleInterval" = ReadPclampVar( file, "float", 126 ) // SplitClock // NEED THIS
	Variable /G $hdf +"fSynchTimeUnit" = ReadPclampVar( file, "float", 130 )
	Variable /G $hdf +"fSecondsPerRun" = ReadPclampVar( file, "float", 134 )
	Variable /G $hdf +"lNumSamplesPerEpisode" = ReadPclampVar( file, "long", 138 ) // SamplesPerWave
	Variable /G $hdf +"lPreTriggerSamples" = ReadPclampVar( file, "long", 142 )
	Variable /G $hdf +"lEpisodesPerRun" = ReadPclampVar( file, "long", 146 )
	Variable /G $hdf +"lRunsPerTrial" = ReadPclampVar( file, "long", 150 )
	Variable /G $hdf +"lNumberOfTrials" = ReadPclampVar( file, "long", 154 )
	Variable /G $hdf +"nAveragingMode" = ReadPclampVar( file, "short", 158 )
	Variable /G $hdf +"nUndoRunCount" = ReadPclampVar( file, "short", 160 )
	Variable /G $hdf +"nFirstEpisodeInRun" = ReadPclampVar( file, "short", 162 )
	Variable /G $hdf +"fTriggerThreshold" = ReadPclampVar( file, "float", 164 )
	Variable /G $hdf +"nTriggerSource" = ReadPclampVar( file, "short", 168 ) // NEED THIS FOR GB
	Variable /G $hdf +"nTriggerAction" = ReadPclampVar( file, "short", 170 )
	Variable /G $hdf +"nTriggerPolarity" = ReadPclampVar( file, "short", 172 )
	Variable /G $hdf +"fScopeOutputInterval" = ReadPclampVar( file, "float", 174 )
	Variable /G $hdf +"fEpisodeStartToStart" = ReadPclampVar( file, "float", 178 ) // NEED THIS FOR GB
	Variable /G $hdf +"fRunStartToStart" = ReadPclampVar( file, "float", 182 )
	Variable /G $hdf +"fTrialStartToStart" = ReadPclampVar( file, "float", 186 )
	Variable /G $hdf +"lAverageCount" = ReadPclampVar( file, "long", 190 )
	Variable /G $hdf +"lClockChange" = ReadPclampVar( file, "long", 194 )
	Variable /G $hdf +"nAutoTriggerStrategy" = ReadPclampVar( file, "short", 198 )
	
	numChannels = NumVarOrDefault( hdf +"nADCNumChannels", 0 )
	
	//
	// Hardware Information
	//
	
	Variable /G $hdf +"fADCRange" = ReadPclampVar( file, "float", 244 ) // ADCRange, NEED THIS
	Variable /G $hdf +"fDACRange" = ReadPclampVar( file, "float", 248 )
	Variable /G $hdf +"lADCResolution" = ReadPclampVar( file, "long", 252 ) // ADCResolution, NEED THIS
	Variable /G $hdf +"lDACResolution" = ReadPclampVar( file, "long", 256 )
	
	//
	// Environmental information
	//
	
	if ( readAll )
		Variable /G $hdf +"nExperimentType" = ReadPclampVar( file, "short", 260 )
		Variable /G $hdf +"nAutosampleEnable" = ReadPclampVar( file, "short", 262 )
		Variable /G $hdf +"nAutosampleADCNum" = ReadPclampVar( file, "short", 264 )
		Variable /G $hdf +"nAutosampleInstrument" = ReadPclampVar( file, "short", 266 )
		Variable /G $hdf +"fAutosampleAdditGain" = ReadPclampVar( file, "float", 268 )
		Variable /G $hdf +"fAutosampleFilter" = ReadPclampVar( file, "float", 272 )
		Variable /G $hdf +"fAutosampleMembraneCap" = ReadPclampVar( file, "float", 276 )
		Variable /G $hdf +"nManualInfoStrategy" = ReadPclampVar( file, "short", 280 )
		Variable /G $hdf +"fCellID1" = ReadPclampVar( file, "float", 282 )
		Variable /G $hdf +"fCellID2" = ReadPclampVar( file, "float", 286 )
		Variable /G $hdf +"fCellID3" = ReadPclampVar( file, "float", 290 )
	endif
	
	String /G $hdf +"sCreatorInfo" = ReadPclampString( file, 294, 16 )
	String /G $hdf +"sFileComment" = ReadPclampString( file, 310, 56 )
	Variable /G $hdf +"nFileStartMillisecs" = ReadPclampVar( file, "short", 366 )
	
	//
	// Multi-channel information
	//
	
	if ( readAll && ( NMProgressCall( -2, "Reading ABF Header ..." ) == 1 ) )
		return -1 // cancel
	endif
	
	Make /I/O/N=( ABF_NUMADCS ) $hdf+"nADCPtoLChannelMap" = 0
	Make /I/O/N=( ABF_NUMADCS ) $hdf+"nADCSamplingSeq" = 0
	Make /T/O/N=( ABF_NUMADCS ) $hdf+"sADCChannelName" = "" // yAxisLabels, NEED THIS
	Make /T/O/N=( ABF_NUMADCS ) $hdf+"sADCUnits" = "" // yAxisLabels, NEED THIS
	Make /O/N=( ABF_NUMADCS ) $hdf+"fADCProgrammableGain" = NaN
	Make /O/N=( ABF_NUMADCS ) $hdf+"fADCDisplayAmplification" = NaN
	Make /O/N=( ABF_NUMADCS ) $hdf+"fADCDisplayOffset" = NaN
	Make /O/N=( ABF_NUMADCS ) $hdf+"fInstrumentScaleFactor" = NaN // scaleFactors, NEED THIS
	Make /O/N=( ABF_NUMADCS ) $hdf+"fInstrumentOffset" = NaN
	
	Wave nADCPtoLChannelMap = $hdf+"nADCPtoLChannelMap"
	Wave nADCSamplingSeq = $hdf+"nADCSamplingSeq"
	Wave /T sADCChannelName = $hdf+"sADCChannelName" // yAxisLabels, NEED THIS
	Wave /T sADCUnits = $hdf+"sADCUnits" // yAxisLabels, NEED THIS
	Wave fADCProgrammableGain = $hdf+"fADCProgrammableGain"
	Wave fADCDisplayAmplification = $hdf+"fADCDisplayAmplification"
	Wave fADCDisplayOffset = $hdf+"fADCDisplayOffset"
	Wave fInstrumentScaleFactor = $hdf+"fInstrumentScaleFactor" // scaleFactors, NEED THIS
	Wave fInstrumentOffset = $hdf+"fInstrumentOffset"
	
	if ( readAll )
	
		Make /O/N=( ABF_NUMADCS ) $hdf+"fSignalGain" = NaN
		Make /O/N=( ABF_NUMADCS ) $hdf+"fSignalOffset" = NaN
		Make /O/N=( ABF_NUMADCS ) $hdf+"fSignalLowpassFilter" = NaN
		Make /O/N=( ABF_NUMADCS ) $hdf+"fSignalHighpassFilter" = NaN
		
		Make /T/O/N=( ABF_NUMDACS ) $hdf+"sDACChannelName" = ""
		Make /T/O/N=( ABF_NUMDACS ) $hdf+"sDACChannelUnits" = ""
		Make /O/N=( ABF_NUMDACS ) $hdf+"fDACScaleFactor" = NaN
		Make /O/N=( ABF_NUMDACS ) $hdf+"fDACHoldingLevel" = NaN
		
		Wave fSignalGain = $hdf+"fSignalGain"
		Wave fSignalOffset = $hdf+"fSignalOffset"
		Wave fSignalLowpassFilter = $hdf+"fSignalLowpassFilter"
		Wave fSignalHighpassFilter = $hdf+"fSignalHighpassFilter"
		
		Wave /T sDACChannelName = $hdf+"sDACChannelName"
		Wave /T sDACChannelUnits = $hdf+"sDACChannelUnits"
		Wave fDACScaleFactor = $hdf+"fDACScaleFactor"
		Wave fDACHoldingLevel = $hdf+"fDACHoldingLevel"
	
	endif
	
	for ( ccnt = 0; ccnt < ABF_NUMADCS; ccnt += 1 )
	
		nADCPtoLChannelMap[ ccnt ] = ReadPclampVar( file, "short", 378 + ccnt * 2 )
		nADCSamplingSeq[ ccnt ] = ReadPclampVar( file, "short", 410 + ccnt * 2 )
		sADCChannelName[ ccnt ] = ReadPclampString( file, 442 + ccnt * 10, 10 ) // yAxisLabels, NEED THIS
		sADCUnits[ ccnt ] = ReadPclampString( file, 602 + ccnt * 8, 8 ) // yAxisLabels, NEED THIS
		fADCProgrammableGain[ ccnt ] = ReadPclampVar( file, "float", 730 + ccnt * 4 )
		fADCDisplayAmplification[ ccnt ] = ReadPclampVar( file, "float", 794 + ccnt * 4 )
		fADCDisplayOffset[ ccnt ] = ReadPclampVar( file, "float", 858 + ccnt * 4 )
		fInstrumentScaleFactor[ ccnt ] = ReadPclampVar( file, "float", 922 + ccnt * 4 ) // scaleFactors, NEED THIS
		fInstrumentOffset[ ccnt ] = ReadPclampVar( file, "float", 986 + ccnt * 4 )
		
		if ( readAll )
			fSignalGain[ ccnt ] = ReadPclampVar( file, "float", 1050 + ccnt * 4 )
			fSignalOffset[ ccnt ] = ReadPclampVar( file, "float", 1114 + ccnt * 4 )
			fSignalLowpassFilter[ ccnt ] = ReadPclampVar( file, "float", 1178 + ccnt * 4 )
			fSignalHighpassFilter[ ccnt ] = ReadPclampVar( file, "float", 1242 + ccnt * 4 )
		endif
		
	endfor
	
	if ( readAll )
	
		for ( ccnt = 0; ccnt < ABF_NUMDACS; ccnt += 1 )
			sDACChannelName[ ccnt ] = ReadPclampString( file, 1306 + ccnt * 10, 10 )
			sDACChannelUnits[ ccnt ] = ReadPclampString( file, 1346 + ccnt * 8, 8 )
			fDACScaleFactor[ ccnt ] = ReadPclampVar( file, "float", 1378 + ccnt * 4 )
			fDACHoldingLevel[ ccnt ] = ReadPclampVar( file, "float", 1394 + ccnt * 4 )
		endfor
	
		Variable /G $hdf +"nSignalType" = ReadPclampVar( file, "short", 1410 )
	
	endif
	
	//
	// Synchronous timer outputs
	//
	
	if ( readAll )
		Variable /G $hdf +"nOUTEnable" = ReadPclampVar( file, "short", 1422 )
		Variable /G $hdf +"nSampleNumberOUT1" = ReadPclampVar( file, "short", 1424 )
		Variable /G $hdf +"nSampleNumberOUT2" = ReadPclampVar( file, "short", 1426 )
		Variable /G $hdf +"nFirstEpisodeOUT" = ReadPclampVar( file, "short", 1428 )
		Variable /G $hdf +"nLastEpisodeOUT" = ReadPclampVar( file, "short", 1430 )
		Variable /G $hdf +"nPulseSamplesOUT1" = ReadPclampVar( file, "short", 1432 )
		Variable /G $hdf +"nPulseSamplesOUT2" = ReadPclampVar( file, "short", 1434 )
	endif
	
	//
	// Epoch Waveform and Pulses
	//
	
	if ( readAll )
	
		Variable /G $hdf +"nDigitalEnable" = ReadPclampVar( file, "short", 1436 )
		Variable /G $hdf +"nWaveformSource" = ReadPclampVar( file, "short", 1438 )
		Variable /G $hdf +"nActiveDACChannel" = ReadPclampVar( file, "short", 1440 )
		Variable /G $hdf +"nInterEpisodeLevel" = ReadPclampVar( file, "short", 1442 )
		
		Make /I/O/N=( ABF_EPOCHCOUNT ) $hdf+"nEpochType" = 0
		Make /O/N=( ABF_EPOCHCOUNT ) $hdf+"fEpochInitLevel" = NaN
		Make /O/N=( ABF_EPOCHCOUNT ) $hdf+"fEpochLevelInc" = NaN
		Make /I/O/N=( ABF_EPOCHCOUNT ) $hdf+"nEpochInitDuration" = 0
		Make /I/O/N=( ABF_EPOCHCOUNT ) $hdf+"nEpochDurationInc" = 0
		
		Wave nEpochType = $hdf+"nEpochType"
		Wave fEpochInitLevel = $hdf+"fEpochInitLevel"
		Wave fEpochLevelInc = $hdf+"fEpochLevelInc"
		Wave nEpochInitDuration = $hdf+"nEpochInitDuration"
		Wave nEpochDurationInc = $hdf+"nEpochDurationInc"
		
		for ( icnt = 0 ; icnt < ABF_EPOCHCOUNT ; icnt += 1 )
			nEpochType[ icnt ] = ReadPclampVar( file, "short", 1444 + icnt * 2 )
			fEpochInitLevel[ icnt ] = ReadPclampVar( file, "float", 1464 + icnt * 4 )
			fEpochLevelInc[ icnt ] = ReadPclampVar( file, "float", 1504 + icnt * 4 )
			nEpochInitDuration[ icnt ] = ReadPclampVar( file, "short", 1544 + icnt * 2 )
			nEpochDurationInc[ icnt ] = ReadPclampVar( file, "short", 1564 + icnt * 2 )
		endfor
		
		Variable /G $hdf +"nDigitalHolding" = ReadPclampVar( file, "short", 1584 )
		Variable /G $hdf +"nDigitalInterEpisode" = ReadPclampVar( file, "short", 1586 )
		
		Make /I/O/N=( ABF_EPOCHCOUNT ) $hdf+"nDigitalValue" = 0
		
		Wave nDigitalValue = $hdf+"nDigitalValue"
		
		for ( icnt = 0 ; icnt < ABF_EPOCHCOUNT ; icnt += 1 )
			nDigitalValue[ icnt ] = ReadPclampVar( file, "short", 1588 + icnt * 2 )
		endfor
		
	endif
	
	//
	// DAC Output File
	//
	
	if ( readAll )
		Variable /G $hdf +"fDACFileScale" = ReadPclampVar( file, "float", 1620 )
		Variable /G $hdf +"fDACFileOffset" = ReadPclampVar( file, "float", 1624 )
		Variable /G $hdf +"nDACFileEpisodeNum" = ReadPclampVar( file, "short", 1630 )
		Variable /G $hdf +"nDACFileADCNum" = ReadPclampVar( file, "short", 1632 )
		String /G $hdf +"sDACFileName" = ReadPclampString( file, 1634, 12 )
		String /G $hdf +"sDACFilePath" = ReadPclampString( file, 1646, 60 )
	endif
	
	//
	// Conditioning pulse train
	//
	
	if ( readAll )
		Variable /G $hdf +"nConditEnable" = ReadPclampVar( file, "short", 1718 )
		Variable /G $hdf +"nConditChannel" = ReadPclampVar( file, "short", 1720 )
		Variable /G $hdf +"lConditNumPulses" = ReadPclampVar( file, "long", 1722 )
		Variable /G $hdf +"fBaselineDuration" = ReadPclampVar( file, "float", 1726 )
		Variable /G $hdf +"fBaselineLevel" = ReadPclampVar( file, "float", 1730 )
		Variable /G $hdf +"fStepDuration" = ReadPclampVar( file, "float", 1734 )
		Variable /G $hdf +"fStepLevel" = ReadPclampVar( file, "float", 1738 )
		Variable /G $hdf +"fPostTrainPeriod" = ReadPclampVar( file, "float", 1742 )
		Variable /G $hdf +"fPostTrainLevel" = ReadPclampVar( file, "float", 1746 )
	endif
	
	//
	// Variable Parameter User List
	//
	
	if ( readAll )
		Variable /G $hdf +"nParamToVary" = ReadPclampVar( file, "short", 1762 )
		String /G $hdf +"sParamValueList" = ReadPclampString( file, 1764, 80 )
	endif
	
	//
	// On-line Subtraction
	//
	
	if ( readAll )
		Variable /G $hdf +"nPNEnable" = ReadPclampVar( file, "short", 1932 )
		Variable /G $hdf +"nPNPosition" = ReadPclampVar( file, "short", 1934 )
		Variable /G $hdf +"nPNPolarity" = ReadPclampVar( file, "short", 1936 )
		Variable /G $hdf +"nPNNumPulses" = ReadPclampVar( file, "short", 1938 )
		Variable /G $hdf +"nPNADCNum" = ReadPclampVar( file, "short", 1940 )
		Variable /G $hdf +"fPNHoldingLevel" = ReadPclampVar( file, "float", 1942 )
		Variable /G $hdf +"fPNSettlingTime" = ReadPclampVar( file, "float", 1946 )
		Variable /G $hdf +"fPNInterpulse" = ReadPclampVar( file, "float", 1950 )
	endif
	
	//
	// Unused space at end of header block
	//
	
	if ( readAll )
	
		Variable /G $hdf +"nListEnable" = ReadPclampVar( file, "short", 1966 )
		Variable /G $hdf +"nLevelHysteresis" = ReadPclampVar( file, "short", 1980 )
		Variable /G $hdf +"lTimeHysteresis" = ReadPclampVar( file, "long", 1982 )
		Variable /G $hdf +"nAllowExternalTags" = ReadPclampVar( file, "short", 1986 )
		
		Make /I/O/N=( ABF_NUMADCS ) $hdf+"nLowpassFilterType" = 0
		Make /I/O/N=( ABF_NUMADCS ) $hdf+"nHighpassFilterType" = 0
		
		Wave nLowpassFilterType = $hdf+"nLowpassFilterType"
		Wave nHighpassFilterType = $hdf+"nHighpassFilterType"
		
		for ( ccnt = 0; ccnt < ABF_NUMADCS; ccnt += 1 )
			nLowpassFilterType[ ccnt ] = ReadPclampVar( file, "short", 1988 + ccnt * 2 )
			nHighpassFilterType[ ccnt ] = ReadPclampVar( file, "short", 2004 + ccnt * 2 )
		endfor
		
		Variable /G $hdf +"nAverageAlgorithm" = ReadPclampVar( file, "short", 2020 )
		Variable /G $hdf +"fAverageWeighting" = ReadPclampVar( file, "float", 2022 )
		Variable /G $hdf +"nUndoPromptStrategy" = ReadPclampVar( file, "short", 2026 )
		Variable /G $hdf +"nTrialTriggerSource" = ReadPclampVar( file, "short", 2028 )
		Variable /G $hdf +"nStatisticsDisplayStrategy" = ReadPclampVar( file, "short", 2030 )
		Variable /G $hdf +"nExternalTagType" = ReadPclampVar( file, "short", 2032 )
		
	endif
	
	Variable /G $hdf +"lHeaderSize" = ReadPclampVar( file, "short", 2034 )
	
	headerSize = NumVarOrDefault( hdf +"lHeaderSize", -1 )
	
	//
	// Extended Environmental Information
	//
	
	if ( headerSize >= 6144 )
	
		Make /I/O/N=( ABF_NUMADCS ) $hdf+"nTelegraphEnable" = 0
		Make /I/O/N=( ABF_NUMADCS ) $hdf+"nTelegraphInstrument" = 0
		Make /O/N=( ABF_NUMADCS ) $hdf+"fTelegraphAdditGain" = NaN
		Make /O/N=( ABF_NUMADCS ) $hdf+"fTelegraphFilter" = NaN
		Make /O/N=( ABF_NUMADCS ) $hdf+"fTelegraphMembraneCap" = NaN
		Make /I/O/N=( ABF_NUMADCS ) $hdf+"nTelegraphMode" = 0
		
		Wave nTelegraphEnable = $hdf+"nTelegraphEnable"
		Wave nTelegraphInstrument = $hdf+"nTelegraphInstrument"
		Wave fTelegraphAdditGain = $hdf+"fTelegraphAdditGain"
		Wave fTelegraphFilter = $hdf+"fTelegraphFilter"
		Wave fTelegraphMembraneCap = $hdf+"fTelegraphMembraneCap"
		Wave nTelegraphMode = $hdf+"nTelegraphMode"
		
		for ( ccnt = 0; ccnt < ABF_NUMADCS; ccnt += 1 )
			nTelegraphEnable[ ccnt ] = ReadPclampVar( file, "short", 4512 + ccnt * 2 )
			nTelegraphInstrument[ ccnt ] = ReadPclampVar( file, "short", 4544 + ccnt * 2 )
			fTelegraphAdditGain[ ccnt ] = ReadPclampVar( file, "float", 4576 + ccnt * 4 ) // 4572 in specs, but this must be a typo
			fTelegraphFilter[ ccnt ] = ReadPclampVar( file, "float", 4640 + ccnt * 4 )
			fTelegraphMembraneCap[ ccnt ] = ReadPclampVar( file, "float", 4704 + ccnt * 4  )
			nTelegraphMode[ ccnt ] = ReadPclampVar( file, "short", 4768 + ccnt * 2 )
		endfor
		
		Variable /G $hdf +"nTelegraphDACScaleFactor" = ReadPclampVar( file, "short", 4800 )
		String /G $hdf +"sProtocolPath" = ReadPclampString( file, 4898 , 256 )
		String /G $hdf +"sFileComment" = ReadPclampString( file, 5154 , 128 )
	
	endif
	
	ReadPClampGUID( hdf, file, 5282, "" )
	
	ReadPclampHeaderUpdateNM( df, hdf )
	
	SetNMstr( df+"ImportFileType", "Pclamp 1" )
	
	KillWaves /Z $df+"NM_ReadPclampWave0"
	KillWaves /Z $df+"NM_ReadPclampWave1"
	
	NMProgressKill()
	
	return 1

End // ReadPClampHeader1

//****************************************************************
//****************************************************************
//****************************************************************

Static Function ReadPClampGUID( df, file, startByte, namePrefix )
	String df
	String file
	Variable startByte
	String namePrefix
	
	Variable icnt
	
	Make /N=1/O/I/U U_GUID_i1
	Make /N=2/O/W/U U_GUID_s2
	Make /N=8/O/B/U U_GUID_c8
	
	U_GUID_i1[ 0 ] = ReadPclampVar( file, "uint", startByte )
	U_GUID_s2[ 0 ] = ReadPclampVar( file, "short", startByte + 4 )
	U_GUID_s2[ 1 ] = ReadPclampVar( file, "short", startByte + 6 )
	
	for ( icnt = 0 ; icnt < 8 ; icnt += 1 )
		U_GUID_c8[ icnt ] = ReadPclampVar( file, "char", startByte + 8 + icnt )
	endfor
	
	String /G $df + namePrefix + "sGUIDinHex" = GUIDconvertToStr( U_GUID_i1, U_GUID_s2, U_GUID_c8 )
	
	KillWaves /Z U_GUID_i1, U_GUID_s2, U_GUID_c8
	
End // ReadPClampGUID

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S GUIDconvertToStr( GUID_i1, GUID_s2, GUID_c8 )
	Wave GUID_i1
	Wave GUID_s2
	Wave GUID_c8

	Variable icnt
	String strTemp, GUIDstr = "{"
	
	if ( numpnts( GUID_i1 ) != 1 )
		return ""
	endif
	
	if ( numpnts( GUID_s2 ) != 2 )
		return ""
	endif
	
	if ( numpnts( GUID_c8 ) != 8 )
		return ""
	endif
	
	sprintf strTemp, "%08X", GUID_i1[ 0 ] & 0xFF000000
	GUIDstr += strTemp[ 0, 1 ]
	
	sprintf strTemp, "%08X", GUID_i1[ 0 ] & 0x00FF0000
	GUIDstr += strTemp[ 2, 3 ]
	
	sprintf strTemp, "%08X", GUID_i1[ 0 ] & 0x0000FF00
	GUIDstr += strTemp[ 4, 5 ]
	
	sprintf strTemp, "%08X", GUID_i1[ 0 ] & 0x000000FF
	GUIDstr += strTemp[ 6, 7 ]
	
	GUIDstr += "-"
	
	sprintf strTemp, "%04X", GUID_s2[ 0 ] & 0xFF00
	GUIDstr += strTemp[ 0, 1 ]
	
	sprintf strTemp, "%04X", GUID_s2[ 0 ] & 0x00FF
	GUIDstr += strTemp[ 2, 3 ]
	
	GUIDstr += "-"
	
	sprintf strTemp, "%04X", GUID_s2[ 1 ] & 0xFF00
	GUIDstr += strTemp[ 0, 1 ]
	
	sprintf strTemp, "%04X", GUID_s2[ 1 ] & 0x00FF
	GUIDstr += strTemp[ 2, 3 ]
	
	GUIDstr += "-"
	
	for ( icnt = 0 ; icnt < 8 ; icnt += 1 )
	
		sprintf strTemp, "%02X", GUID_c8[ icnt ] & 0xFF
		GUIDstr += strTemp[ 0, 1 ]
		
		if ( icnt == 1 )
			GUIDstr += "-"
		endif
		
	endfor
	
	GUIDstr += "}"
	
	return GUIDstr

End // GUIDconvertToStr

//****************************************************************
//****************************************************************
//****************************************************************

 Static Function ReadPClampHeader1_OLD( file, df ) // NOT USED ANYMORE
	String file // external ABF data file
	String df // NM data folder where everything is imported

	Variable ccnt, amode, ActualEpisodes, tempvar
	Variable ADCResolution, ADCRange, DataPointer, DataFormat, AcqLength
	Variable FileFormat, NumChannels, TotalNumWaves, SamplesPerWave, SampleInterval, SplitClock
	Variable lFileStartTime, lStopwatchTime
	String yl, dumstr, AcqMode, fileC
	
	if ( ReadPclampFormat( file ) != 1 )
		return -1
	endif
	
	df = ParseFilePath( 2, df, ":", 0, 0 )
	
	CheckNMwave( df+"FileScaleFactors", ABF_NUMADCS, 1 ) // increase size
	CheckNMtwave( df+"yLabel", ABF_NUMADCS, "" )
	
	Wave scaleFactors = $df+"FileScaleFactors"
	Wave /T yAxisLabels = $df+"yLabel"
	
	scaleFactors = 1
	yAxisLabels = ""
	
	FileFormat = ReadPclampVar( file, "short", 36 )
	//SetNMvar( df+"FileFormat", FileFormat )
	
	amode = ReadPclampVar( file, "short", 8 ) // acquisition/operation mode
	
	switch( amode )
		case 1:
			AcqMode = "1 ( Event-Driven )"
			break
		case 2:
			AcqMode = "2 ( Oscilloscope, loss free )"
			break
		case 3:
			AcqMode = "3 ( Gap-Free )"
			break
		case 4:
			AcqMode = "4 ( Oscilloscope, high-speed )"
			break
		case 5:
			AcqMode = "5 ( Episodic )"
			break
	endswitch
	
	SetNMstr( df+"AcqMode", AcqMode )
	
	AcqLength = ReadPclampVar( file, "long", 10 ) // actual number of ADC samples in data file
	SetNMvar( df+"AcqLength", AcqLength )
	ActualEpisodes = ReadPclampVar( file, "long", 16 )
	SetNMvar( df+"NumWaves", ActualEpisodes )
	
	lFileStartTime = ReadPclampVar( file, "long", 24 ) // time of day in seconds past midnight when data portion of this file was first written to
	
	
	lFileStartTime += ReadPclampVar( file, "short", 366 ) / 1000 // JSR - NOT SURE ABOUT THIS!!!
	
	lStopwatchTime = ReadPclampVar(file, "long", 28)
	
	//
	// File Structure info
	//
	
	DataPointer = ReadPclampVar( file, "long", 40 ) // block number of start of Data section
	SetNMvar( df+"DataPointer", DataPointer )
	DataFormat = ReadPclampVar( file, "short", 100 )
	SetNMvar( df+"DataFormat", DataFormat )
	
	if ( NMProgressCall( -2, "Reading ABF Header ..." ) == 1 )
		return -1 // cancel
	endif
		
	//
	// Trial Hierarchy info
	//
	
	NumChannels = ReadPclampVar( file, "short", 120 ) // nADCNumChannels
	SetNMvar( df+"NumChannels", NumChannels )
	TotalNumWaves = ActualEpisodes * NumChannels
	SetNMvar( df+"TotalNumWaves", TotalNumWaves )
	SampleInterval = ReadPclampVar( file, "float", 122 )
	SampleInterval = ( SampleInterval * NumChannels ) / 1000
	SetNMvar( df+"SampleInterval", SampleInterval )
	
	SplitClock = ReadPclampVar( file, "float", 126 ) // second clock interval
	
	SetNMvar( df+"SplitClock", SplitClock )
	
	if ( SplitClock != 0 ) // SecondSampleInterval
		NMDoAlert( "Warning: data contains split-clock recording, which is not supported by this version of NeuroMatic." )
	endif
	
	if ( ( amode != 1 ) && ( amode != 3 ) )
		SamplesPerWave = ReadPclampVar( file, "long", 138 ) / NumChannels // sample points per wave
	else
		SamplesPerWave = AcqLength / NumChannels
	endif
	
	SetNMvar( df+"SamplesPerWave", SamplesPerWave )
	
	//Variable /G $df + "PreTriggerSamples" = ReadPclampVar( file, "long", 142 )
	Variable /G $df + "EpisodesPerRun" = ReadPclampVar( file, "long", 146 ) // requested number of sweeps/run.  0=Run until terminated by user. If nOperationMode is 3 (gap free) this parameter is 1 and the requested acquisition length is set in fSecondsPerRun.
	Variable /G $df + "RunsPerTrial" = ReadPclampVar( file, "long", 150 )
	//Variable /G $df + "NumberOfTrials" = ReadPclampVar( file, "long", 154 )
	Variable /G $df + "nTriggerSource" = ReadPclampVar(file, "short", 168) // trigger source:  N (>=0) = Physical channel number selected for threshold detection;  -1 = external trigger;  -2 = keyboard;  -3 =   use start-to-start interval. If nOperationMode=3 (gap-free)  0= start immediately.
	Variable /G $df + "EpisodeStartToStart" = ReadPclampVar( file, "float", 178 ) // time between start of sweeps (seconds).  Use when nTriggerSource = "start-to-start".
	//Variable /G $df + "RunStartToStart" = ReadPclampVar( file, "float", 182 )
	//Variable /G $df + "TrialStartToStart" = ReadPclampVar( file, "float", 186 )
	//Variable /G $df + "ClockChange" = ReadPclampVar( file, "long", 194 )
	
	//
	// Hardware Info
	//
	
	ADCRange = ReadPclampVar( file, "float", 244 ) // ADC positive full-scale input ( volts )
	SetNMvar( df+"ADCRange", ADCRange )
	//Variable /G $df + "DACRange" = ReadPclampVar( file, "float", 248 )
	ADCResolution = ReadPclampVar( file, "long", 252 ) // number of ADC counts in ADC range
	SetNMvar( df+"ADCResolution", ADCResolution )
	//Variable /G $df + "DACResolution" = ReadPclampVar( file, "long", 256 )
	
	//
	// Multi-channel Info
	//
	
	if ( NMProgressCall( -2, "Reading ABF Header ..." ) == 1 )
		return -1 // cancel
	endif

	for ( ccnt = 0; ccnt < NumChannels; ccnt += 1 )
		if ( ccnt >= numpnts( yAxisLabels ) )
			break
		endif
		yl = ReadPclampString( file, 442 + ccnt * 10, 10 )
		yAxisLabels[ ccnt ] = RemoveEndSpaces( yl )
		
	endfor
	
	for ( ccnt = 0; ccnt < NumChannels; ccnt += 1 )
		if ( ccnt >= numpnts( yAxisLabels ) )
			break
		endif
		yl = ReadPclampString( file, 602 + ccnt * 8, 8 )
		yAxisLabels[ ccnt ] += " ( " + RemoveEndSpaces( yl ) + " )"
	endfor
	
	for ( ccnt = 0; ccnt < NumChannels; ccnt += 1 )
		if ( ccnt >= numpnts( scaleFactors ) )
			break
		endif
		tempvar = ReadPclampVar( file, "float", 922 + ccnt * 4 )
		scaleFactors[ ccnt ] = ADCRange / ( ADCResolution * tempvar )
		//print "chan" + num2istr( ccnt ) + " gain:", tempvar
	endfor
	
	//
	// Extended Environmental Info
	//
	
	//Variable /G $df + "TelegraphEnable" = ReadPclampVar( file, "short", 4512 )
	//Variable /G $df + "TelegraphInstrument" = = ReadPclampVar( file, "short", 4544 )
	
	for ( ccnt = 0; ccnt < NumChannels; ccnt += 1 )
		if ( ccnt >= numpnts( scaleFactors ) )
			break
		endif
		tempvar = ReadPclampVar( file, "float", 4576 + ccnt * 4 )
		if ( ( numtype( tempvar ) == 0 ) && ( tempvar > 0 ) )
			scaleFactors[ ccnt ] /= tempvar
			//print "chan" + num2istr( ccnt ) + " telegraph gain:", NM_ReadPclampWave0[ ccnt ]
		endif
	endfor
	
	if ( amode == 3 ) // gap free
		TotalNumWaves = ceil( AcqLength / SamplesPerWave )
		SetNMvar( df+"TotalNumWaves", TotalNumWaves )
	endif
	
	//if ( strlen( xLabel ) == 0 )
	//	xLabel = NMXunits
	//endif
	
	SetNMstr( df+"ImportFileType", "Pclamp 1" )
	
	CheckNMwave( df+"FileScaleFactors", numChannels, 1 )
	CheckNMtwave( df+"yLabel", numChannels, "" )
	
	KillWaves /Z $df+"NM_ReadPclampWave0"
	KillWaves /Z $df+"NM_ReadPclampWave1"
	
	return 1

End // ReadPClampHeader1_OLD

//****************************************************************
//****************************************************************
//****************************************************************

Static Function ReadPClampData1( file, df )
	String file // external ABF data file
	String df // NM data folder where everything is imported

	Variable startNum, nwaves, amode, scale, pointer, column, nsamples, bytesPerEpisode
	Variable ccnt, wcnt, scnt, npnts, lastwave, cancel
	String wName, wNote, wList
	
	Variable format = ReadPclampFormat( file )
	
	String saveDF = GetDataFolder( 1 )
	
	df = ParseFilePath( 2, df, ":", 0, 0 )
	
	if ( !FileExistsAndNonZero( file ) )
		return -1
	endif
	
	String acqMode = StrVarOrDefault( df+"AcqMode", "" )
	
	if ( strlen( acqMode ) == 0 )
	
		switch( format )
		
			case 1:
			
				if ( ReadPClampHeader1( file, df ) < 0 )
					return -1
				endif
			
				break
				
			case 2:
			
				if ( ReadPClampHeader2( file, df ) < 0 )
					return -1
				endif
			
				break
				
			default:
			
				return -1
		
		endswitch
		
		acqMode = StrVarOrDefault( df+"AcqMode", "" )
	
	endif
	
	amode = str2num( acqMode[ 0 ] )
	
	Variable NumChannels = NumVarOrDefault( df+"NumChannels", 0 )
	Variable NumWaves = NumVarOrDefault( df+"NumWaves", 0 )
	Variable SamplesPerWave = NumVarOrDefault( df+"SamplesPerWave", 0 )
	Variable SampleInterval = NumVarOrDefault( df+"SampleInterval", 1 )
	Variable AcqLength = NumVarOrDefault( df+"AcqLength", 0 )
	Variable DataPointer = NumVarOrDefault( df+"DataPointer", 0 )
	Variable WaveBgn = NumVarOrDefault( df+"WaveBgn", 0 )
	Variable WaveEnd = NumVarOrDefault( df+"WaveEnd", -1 )
	
	String xLabel = StrVarOrDefault( df+"xLabel", NMXunits )
	String wavePrefix = StrVarOrDefault( df+"WavePrefix", NMStrGet( "WavePrefix" ) )
	
	Wave scaleFactors = $df+"FileScaleFactors"
	Wave /T yAxisLabels = $df+"yLabel"
	
	Variable DataFormat = NumVarOrDefault( df+"DataFormat", 0 )
	
	switch( DataFormat )
		case 0:
		case 1:
			break
		default:
			DoAlert 0, "Abort ABF Import: unrecognized DataFormat: " + num2istr( DataFormat )
			return 0 // option not allowed
	endswitch
	
	SetDataFolder $df
	
	startNum = NextWaveNum( "", wavePrefix, 0, 0 )
	
	if ( WaveEnd < 0 )
		WaveEnd = NumWaves - 1
	endif
	
	if ( ( WaveBgn > WaveEnd ) || ( startNum < 0 ) || ( numtype( WaveBgn*WaveEnd*startNum ) != 0 ) )
		return 0 // options not allowed
	endif
	
	Make /O NM_ReadPclampWave0, NM_ReadPclampWave1 // where GBLoadWave puts data
	
	lastwave = ceil( AcqLength / ( NumChannels * SamplesPerWave ) )
	
	WaveEnd = min( WaveEnd, lastwave )
	
	if ( amode == 3 ) // gap-free
		WaveBgn = 0
		WaveEnd = NumWaves - 1 // force importing all waves
	endif
	
	nwaves = ceil( WaveEnd ) - floor( WaveBgn ) + 1
	
	NMProgressCall( -1, "Importing ABF waves ..." )
	
	column = WaveBgn
	
	if ( DataFormat == 0 ) // 2-byte integer
	
		bytesPerEpisode = SamplesPerWave * NumChannels * 2
		pointer = ABF_BLOCK * DataPointer + bytesPerEpisode * column
		nsamples = nwaves * bytesPerEpisode
		nsamples = min( nsamples, AcqLength )
		
		GBLoadWave/O/Q/B/N=NM_ReadPClampWave/T={16,2}/S=(pointer)/W=1/U=(nsamples) file
		
	elseif ( DataFormat == 1 ) // 4-byte float
	
		bytesPerEpisode = SamplesPerWave * NumChannels * 4
		pointer = ABF_BLOCK * DataPointer + bytesPerEpisode * column
		nsamples = nwaves * bytesPerEpisode
		nsamples = min( nsamples, AcqLength )
		
		GBLoadWave/O/Q/B/N=NM_ReadPClampWave/T={2,2}/S=(pointer)/W=1/U=(nsamples) file
		
	endif
	
	if ( NMProgressCall( -2, "Importing ABF waves ..." ) == 1 )
		return 0 // cancel
	endif
	
	npnts = nsamples / NumChannels
	
	if ( amode == 3 )
		WaveBgn = 0
		WaveEnd = 0
		nwaves = 1
		SamplesPerWave = npnts
		SetNMvar( df + "NumWaves", 1 )
		SetNMvar( df + "TotalNumWaves", 1 * NumChannels )
		SetNMvar( df + "SamplesPerWave", npnts )
	endif 
	
	for ( ccnt = 0; ccnt < NumChannels; ccnt += 1 ) // unpack channel waves
	
		if ( ( ccnt >= numpnts( scaleFactors ) ) ||  ( ccnt >= numpnts( yAxisLabels ) ) )
			break
		endif
	
		if ( NumChannels == 1 )
		
			Wave ctemp = NM_ReadPclampWave0
		
		else
		
			wName = "NM_ReadPClampWave_" + num2istr( ccnt )
		
			Make /O/N=( npnts ) $wName
			
			Wave ctemp = $wName
			
			ctemp = NM_ReadPclampWave0[ x * NumChannels + ccnt ]
		
		endif
		
		scale = scaleFactors[ ccnt ]
			
		if ( ABF_SCALEWAVES )
			if ( ( numtype( scale ) == 0 ) && ( scale > 0 ) )
				ctemp *= scale
			endif
		endif
		
		scnt = 0
	
		for ( wcnt = WaveBgn; wcnt <= WaveEnd; wcnt += 1 )
		
			if ( NMProgressCall( -2, "Importing ABF waves ..." ) == 1 )
				cancel = 1
				break
			endif
		
			wName = GetWaveName( wavePrefix, ccnt, ( scnt + startNum ) )
			
			Make /O/N=( SamplesPerWave ) $wName
			
			Wave wtemp = $wName
			
			wtemp = ctemp[ x + scnt * SamplesPerWave ]
			
			Setscale /P x 0, SampleInterval, $wName
			
			wNote = "Folder:" + GetDataFolder( 0 )
			wNote += NMCR + "File:" + NMNoteCheck( file )
			wNote += NMCR + "Chan:" + ChanNum2Char( ccnt )
			wNote += NMCR + "Wave:" + num2istr( wcnt )
			wNote += NMCR + "Scale:" + num2str( scale )

			NMNoteType( wName, "Pclamp " + num2str( format ), xLabel, yAxisLabels[ ccnt ], wNote )
			
			PclampTimeStamps( file, format, amode, df, wName, scnt )
			
			scnt += 1
		
		endfor
		
		if ( cancel )
			break
		endif
	
	endfor
	
	NMProgressKill()
	
	KillVariables /Z $df+"DataPointer"
	
	wList = WaveList( "NM_ReadPclampWave*", ";", "" )
	
	NMKillWaves( wList )
	
	SetDataFolder $saveDF // back to original folder
	
	return nwaves

End // ReadPClampData1

//****************************************************************
//****************************************************************
//****************************************************************
//
//	ABF format 2
//
//****************************************************************
//****************************************************************
//****************************************************************

Static Function ReadPClampHeader2( file, df )
	String file // external ABF data file
	String df // NM data folder where everything is imported
	
	Variable icnt, jcnt, kcnt, lcnt, numADCs, numDACs
	Variable varTemp, uNumStrings, uMaxSize, lTotalBytes
	String strTemp
	
	df = ParseFilePath( 2, df, ":", 0, 0 )
	
	String hdf = df + ABF_SUBFOLDERNAME + ":"
	
	if ( ReadPclampFormat( file ) != 2 )
		return -1
	endif
	
	Variable readAll = NumVarOrDefault( NMDF+"ABF_HeaderReadAll", 0 )
	
	if ( readAll )
		NMProgressCall( -1, "Reading ABF Header ..." )
	endif
	
	Variable /G ABF_Read_Pointer = 0
	
	NewDataFolder /O $RemoveEnding( hdf, ":" ) // create subfolder in current directory
	
	Variable /G $hdf +"uFileSignature" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"uFileVersionNumber" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"uFileInfoSize" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"uActualEpisodes" = ReadPclampVarPointer( file, "uint" ) // NEED THIS
	Variable /G $hdf +"uFileStartDate" = ReadPclampVarPointer( file, "uint" ) // NEED THIS
	Variable /G $hdf +"uFileStartTimeMS" = ReadPclampVarPointer( file, "uint" ) // NEED THIS
	Variable /G $hdf +"uStopwatchTime" = ReadPclampVarPointer( file, "uint" ) // NEED THIS
	Variable /G $hdf +"nFileType" = ReadPclampVarPointer( file, "short" )
	Variable /G $hdf +"nDataFormat" = ReadPclampVarPointer( file, "short" ) // NEED THIS
	Variable /G $hdf +"nSimultaneousScan" = ReadPclampVarPointer( file, "short" )
	Variable /G $hdf +"nCRCEnable" = ReadPclampVarPointer( file, "short" )
	Variable /G $hdf +"uFileCRC" = ReadPclampVarPointer( file, "uint" )
	
	// GUID // starts at byte 40
	
	Make /N=1/O/I/U U_GUID_i1
	Make /N=2/O/W/U U_GUID_s2
	Make /N=8/O/B/U U_GUID_c8
	
	U_GUID_i1[ 0 ] = ReadPclampVarPointer( file, "uint" )
	U_GUID_s2[ 0 ] = ReadPclampVarPointer( file, "short" )
	U_GUID_s2[ 1 ] = ReadPclampVarPointer( file, "short" )
	
	for ( icnt = 0 ; icnt < 8 ; icnt += 1 )
		U_GUID_c8[ icnt ] = ReadPclampVarPointer( file, "char" )
	endfor
	
	//U_GUID_i1[ 0 ] = 1
	//U_GUID_s2[ 0 ] = 2
	//U_GUID_s2[ 1 ] = 3
	
	//for ( icnt = 0 ; icnt < 8 ; icnt += 1 )
	//	U_GUID_c8[ icnt ] = icnt
	//endfor
	
	String /G $hdf +"sGUIDinHex" = GUIDconvertToStr( U_GUID_i1, U_GUID_s2, U_GUID_c8 )
	
	KillWaves /Z U_GUID_i1, U_GUID_s2, U_GUID_c8
	
	Variable /G $hdf +"uCreatorVersion" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"uCreatorNameIndex" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"uModifierVersion" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"uModifierNameIndex" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"uProtocolPathIndex" = ReadPclampVarPointer( file, "uint" )
	
	Variable /G $hdf +"SectionProtocol_BlockIndex" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"SectionProtocol_Bytes" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"SectionProtocol_NumEntries1" = ReadPclampVarPointer( file, "long" )
	Variable /G $hdf +"SectionProtocol_NumEntries2" = ReadPclampVarPointer( file, "long" )
	
	NVAR SectionProtocol_BlockIndex = $hdf +"SectionProtocol_BlockIndex"
	
	Variable /G $hdf +"SectionADC_BlockIndex" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"SectionADC_Bytes" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"SectionADC_NumEntries1" = ReadPclampVarPointer( file, "long" ) // NEED THIS
	Variable /G $hdf +"SectionADC_NumEntries2" = ReadPclampVarPointer( file, "long" )
	
	NVAR SectionADC_BlockIndex = $hdf +"SectionADC_BlockIndex"
	NVAR SectionADC_Bytes = $hdf +"SectionADC_Bytes"
	NVAR SectionADC_NumEntries1 = $hdf +"SectionADC_NumEntries1" // NEED THIS
	
	Variable /G $hdf +"SectionDAC_BlockIndex" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"SectionDAC_Bytes" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"SectionDAC_NumEntries1" = ReadPclampVarPointer( file, "long" )
	Variable /G $hdf +"SectionDAC_NumEntries2" = ReadPclampVarPointer( file, "long" )
	
	NVAR SectionDAC_BlockIndex = $hdf +"SectionDAC_BlockIndex"
	NVAR SectionDAC_Bytes = $hdf +"SectionDAC_Bytes"
	NVAR SectionDAC_NumEntries1 = $hdf +"SectionDAC_NumEntries1"
	
	Variable /G $hdf +"SectionEpoch_BlockIndex" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"SectionEpoch_Bytes" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"SectionEpoch_NumEntries1" = ReadPclampVarPointer( file, "long" )
	Variable /G $hdf +"SectionEpoch_NumEntries2" = ReadPclampVarPointer( file, "long" )
	
	NVAR SectionEpoch_BlockIndex = $hdf +"SectionEpoch_BlockIndex"
	NVAR SectionEpoch_Bytes = $hdf +"SectionEpoch_Bytes"
	NVAR SectionEpoch_NumEntries1 = $hdf +"SectionEpoch_NumEntries1"
	
	Variable /G $hdf +"SectionADCPerDAC_BlockIndex" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"SectionADCPerDAC_Bytes" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"SectionADCPerDAC_NumEntries1" = ReadPclampVarPointer( file, "long" )
	Variable /G $hdf +"SectionADCPerDAC_NumEntries2" = ReadPclampVarPointer( file, "long" )
	
	Variable /G $hdf +"SectionEpochPerDAC_BlockIndex" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"SectionEpochPerDAC_Bytes" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"SectionEpochPerDAC_NumEntries1" = ReadPclampVarPointer( file, "long" )
	Variable /G $hdf +"SectionEpochPerDAC_NumEntries2" = ReadPclampVarPointer( file, "long" )
	
	NVAR SectionEpochPerDAC_BlockIndex = $hdf +"SectionEpochPerDAC_BlockIndex"
	NVAR SectionEpochPerDAC_Bytes = $hdf +"SectionEpochPerDAC_Bytes"
	NVAR SectionEpochPerDAC_NumEntries1 = $hdf +"SectionEpochPerDAC_NumEntries1"
	
	Variable /G $hdf +"SectionUserList_BlockIndex" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"SectionUserList_Bytes" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"SectionUserList_NumEntries1" = ReadPclampVarPointer( file, "long" )
	Variable /G $hdf +"SectionUserList_NumEntries2" = ReadPclampVarPointer( file, "long" )
	
	Variable /G $hdf +"SectionStatsRegion_BlockIndex" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"SectionStatsRegion_Bytes" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"SectionStatsRegion_NumEntries1" = ReadPclampVarPointer( file, "long" )
	Variable /G $hdf +"SectionStatsRegion_NumEntries2" = ReadPclampVarPointer( file, "long" )
	
	Variable /G $hdf +"SectionMath_BlockIndex" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"SectionMath_Bytes" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"SectionMath_NumEntries1" = ReadPclampVarPointer( file, "long" )
	Variable /G $hdf +"SectionMath_NumEntries2" = ReadPclampVarPointer( file, "long" )
	
	Variable /G $hdf +"SectionStrings_BlockIndex" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"SectionStrings_Bytes" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"SectionStrings_NumEntries1" = ReadPclampVarPointer( file, "long" )
	Variable /G $hdf +"SectionStrings_NumEntries2" = ReadPclampVarPointer( file, "long" )
	
	NVAR SectionStrings_BlockIndex = $hdf +"SectionStrings_BlockIndex"
	NVAR SectionStrings_Bytes = $hdf +"SectionStrings_Bytes"
	NVAR SectionStrings_NumEntries1 = $hdf +"SectionStrings_NumEntries1"
	
	Variable /G $hdf +"SectionData_BlockIndex" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"SectionData_Bytes" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"SectionData_NumEntries1" = ReadPclampVarPointer( file, "long" ) // NEED THIS
	Variable /G $hdf +"SectionData_NumEntries2" = ReadPclampVarPointer( file, "long" )
	
	NVAR SectionData_BlockIndex = $hdf +"SectionData_BlockIndex"
	NVAR SectionData_Bytes = $hdf +"SectionData_Bytes"
	NVAR SectionData_NumEntries1 = $hdf +"SectionData_NumEntries1"
	NVAR SectionData_NumEntries2 = $hdf +"SectionData_NumEntries2"
	
	SetNMvar( df+"DataPointer", SectionData_BlockIndex )
	
	if ( readAll && ( NMProgressCall( -2, "Reading ABF Header ..." ) == 1 ) )
		return -1 // cancel
	endif
	
	if ( readAll )
	
		Variable /G $hdf +"SectionTag_BlockIndex" = ReadPclampVarPointer( file, "uint" )
		Variable /G $hdf +"SectionTag_Bytes" = ReadPclampVarPointer( file, "uint" )
		Variable /G $hdf +"SectionTag_NumEntries1" = ReadPclampVarPointer( file, "long" )
		Variable /G $hdf +"SectionTag_NumEntries2" = ReadPclampVarPointer( file, "long" )
		
		Variable /G $hdf +"SectionScope_BlockIndex" = ReadPclampVarPointer( file, "uint" )
		Variable /G $hdf +"SectionScope_Bytes" = ReadPclampVarPointer( file, "uint" )
		Variable /G $hdf +"SectionScope_NumEntries1" = ReadPclampVarPointer( file, "long" )
		Variable /G $hdf +"SectionScope_NumEntries2" = ReadPclampVarPointer( file, "long" )
		
		Variable /G $hdf +"SectionDelta_BlockIndex" = ReadPclampVarPointer( file, "uint" )
		Variable /G $hdf +"SectionDelta_Bytes" = ReadPclampVarPointer( file, "uint" )
		Variable /G $hdf +"SectionDelta_NumEntries1" = ReadPclampVarPointer( file, "long" )
		Variable /G $hdf +"SectionDelta_NumEntries2" = ReadPclampVarPointer( file, "long" )
		
		Variable /G $hdf +"SectionVoiceTag_BlockIndex" = ReadPclampVarPointer( file, "uint" )
		Variable /G $hdf +"SectionVoiceTag_Bytes" = ReadPclampVarPointer( file, "uint" )
		Variable /G $hdf +"SectionVoiceTag_NumEntries1" = ReadPclampVarPointer( file, "long" )
		Variable /G $hdf +"SectionVoiceTag_NumEntries2" = ReadPclampVarPointer( file, "long" )
		
		Variable /G $hdf +"SectionSynchArray_BlockIndex" = ReadPclampVarPointer( file, "uint" )
		Variable /G $hdf +"SectionSynchArray_Bytes" = ReadPclampVarPointer( file, "uint" )
		Variable /G $hdf +"SectionSynchArray_NumEntries1" = ReadPclampVarPointer( file, "long" )
		Variable /G $hdf +"SectionSynchArray_NumEntries2" = ReadPclampVarPointer( file, "long" )
		
		Variable /G $hdf +"SectionAnnotation_BlockIndex" = ReadPclampVarPointer( file, "uint" )
		Variable /G $hdf +"SectionAnnotatio_Bytes" = ReadPclampVarPointer( file, "uint" )
		Variable /G $hdf +"SectionAnnotatio_NumEntries1" = ReadPclampVarPointer( file, "long" )
		Variable /G $hdf +"SectionAnnotatio_NumEntries2" = ReadPclampVarPointer( file, "long" )
		
		Variable /G $hdf +"SectionStats_BlockIndex" = ReadPclampVarPointer( file, "uint" )
		Variable /G $hdf +"SectionStats_Bytes" = ReadPclampVarPointer( file, "uint" )
		Variable /G $hdf +"SectionStats_NumEntries1" = ReadPclampVarPointer( file, "long" )
		Variable /G $hdf +"SectionStats_NumEntries2" = ReadPclampVarPointer( file, "long" )
	
	endif
	
	// Protocol Information Section
	
	if ( readAll && ( NMProgressCall( -2, "Reading ABF Header ..." ) == 1 ) )
		return -1 // cancel
	endif
	
	ABF_Read_Pointer = SectionProtocol_BlockIndex * ABF_BLOCK
	
	Variable /G $hdf +"nOperationMode" = ReadPclampVarPointer( file, "short" ) // NEED THIS
	Variable /G $hdf +"fADCSequenceInterval" = ReadPclampVarPointer( file, "float" ) // NEED THIS
	Variable /G $hdf +"bEnableFileCompression" = ReadPclampVarPointer( file, "char" )
	
	ReadPclampVarPointer( file, "char" ) // unused
	ReadPclampVarPointer( file, "char" ) // unused
	ReadPclampVarPointer( file, "char" ) // unused
	
	Variable /G $hdf +"uFileCompressionRatio" = ReadPclampVarPointer( file, "uint" )
	Variable /G $hdf +"fSynchTimeUnit" = ReadPclampVarPointer( file, "float" )
	Variable /G $hdf +"fSecondsPerRun" = ReadPclampVarPointer( file, "float" )
	Variable /G $hdf +"lNumSamplesPerEpisode" = ReadPclampVarPointer( file, "long" ) // NEED THIS
	Variable /G $hdf +"lPreTriggerSamples" = ReadPclampVarPointer( file, "long" )
	Variable /G $hdf +"lEpisodesPerRun" = ReadPclampVarPointer( file, "long" ) // NEED THIS
	Variable /G $hdf +"lRunsPerTrial" = ReadPclampVarPointer( file, "long" ) // NEED THIS
	Variable /G $hdf +"lNumberOfTrials" = ReadPclampVarPointer( file, "long" )
	Variable /G $hdf +"nAveragingMode" = ReadPclampVarPointer( file, "short" )
	Variable /G $hdf +"nUndoRunCount" = ReadPclampVarPointer( file, "short" )
	Variable /G $hdf +"nFirstEpisodeInRun" = ReadPclampVarPointer( file, "short" )
	Variable /G $hdf +"fTriggerThreshold" = ReadPclampVarPointer( file, "float" )
	Variable /G $hdf +"nTriggerSource" = ReadPclampVarPointer( file, "short" )
	Variable /G $hdf +"nTriggerAction" = ReadPclampVarPointer( file, "short" )
	Variable /G $hdf +"nTriggerPolarity" = ReadPclampVarPointer( file, "short" )
	Variable /G $hdf +"fScopeOutputInterval" = ReadPclampVarPointer( file, "float" )
	Variable /G $hdf +"fEpisodeStartToStart" = ReadPclampVarPointer( file, "float" ) // NEED THIS
	Variable /G $hdf +"fRunStartToStart" = ReadPclampVarPointer( file, "float" )
	Variable /G $hdf +"lAverageCount" = ReadPclampVarPointer( file, "long" )
	Variable /G $hdf +"fTrialStartToStart" = ReadPclampVarPointer( file, "float" )
	Variable /G $hdf +"nAutoTriggerStrategy" = ReadPclampVarPointer( file, "short" )
	Variable /G $hdf +"fFirstRunDelays" = ReadPclampVarPointer( file, "float" )
	Variable /G $hdf +"nChannelStatsStrategy" = ReadPclampVarPointer( file, "short" )
	Variable /G $hdf +"lSamplesPerTrace" = ReadPclampVarPointer( file, "long" )
	Variable /G $hdf +"lStartDisplayNum" = ReadPclampVarPointer( file, "long" )
	Variable /G $hdf +"lFinishDisplayNum" = ReadPclampVarPointer( file, "long" )
	Variable /G $hdf +"nShowPNRawData" = ReadPclampVarPointer( file, "short" )
	Variable /G $hdf +"fStatisticsPeriod" = ReadPclampVarPointer( file, "float" )
	Variable /G $hdf +"lStatisticsMeasurements" = ReadPclampVarPointer( file, "long" )
	Variable /G $hdf +"nStatisticsSaveStrategy" = ReadPclampVarPointer( file, "short" )
	Variable /G $hdf +"fADCRange" = ReadPclampVarPointer( file, "float" ) // NEED THIS
	Variable /G $hdf +"fDACRange" = ReadPclampVarPointer( file, "float" )
	Variable /G $hdf +"lADCResolution" = ReadPclampVarPointer( file, "long" ) // NEED THIS
	
	if ( readAll )
		Variable /G $hdf +"lDACResolution" = ReadPclampVarPointer( file, "long" )
		Variable /G $hdf +"nExperimentType" = ReadPclampVarPointer( file, "short" )
		Variable /G $hdf +"nManualInfoStrategy" = ReadPclampVarPointer( file, "short" )
		Variable /G $hdf +"nCommentsEnable" = ReadPclampVarPointer( file, "short" )
		Variable /G $hdf +"lFileCommentIndex" = ReadPclampVarPointer( file, "long" )
		Variable /G $hdf +"nAutoAnalyseEnable" = ReadPclampVarPointer( file, "short" )
		Variable /G $hdf +"nSignalType" = ReadPclampVarPointer( file, "short" )
		Variable /G $hdf +"nDigitalEnable" = ReadPclampVarPointer( file, "short" )
		Variable /G $hdf +"nActiveDACChannel" = ReadPclampVarPointer( file, "short" )
		Variable /G $hdf +"nDigitalHolding" = ReadPclampVarPointer( file, "short" )
		Variable /G $hdf +"nDigitalInterEpisode" = ReadPclampVarPointer( file, "short" )
		Variable /G $hdf +"nDigitalDACChannel" = ReadPclampVarPointer( file, "short" )
		Variable /G $hdf +"nDigitalTrainActiveLogic" = ReadPclampVarPointer( file, "short" )
		Variable /G $hdf +"nStatsEnable" = ReadPclampVarPointer( file, "short" )
		Variable /G $hdf +"nStatisticsClearStrategy" = ReadPclampVarPointer( file, "short" )
		Variable /G $hdf +"nLevelHysteresis" = ReadPclampVarPointer( file, "short" )
		Variable /G $hdf +"lTimeHysteresis" = ReadPclampVarPointer( file, "long" )
		Variable /G $hdf +"nAllowExternalTags" = ReadPclampVarPointer( file, "short" )
		Variable /G $hdf +"nAverageAlgorithm" = ReadPclampVarPointer( file, "short" )
		Variable /G $hdf +"fAverageWeighting" = ReadPclampVarPointer( file, "float" )
		Variable /G $hdf +"nUndoPromptStrategy" = ReadPclampVarPointer( file, "short" )
		Variable /G $hdf +"nTrialTriggerSource" = ReadPclampVarPointer( file, "short" )
		Variable /G $hdf +"nStatisticsDisplayStrategy" = ReadPclampVarPointer( file, "short" )
		Variable /G $hdf +"nExternalTagType" = ReadPclampVarPointer( file, "short" )
		Variable /G $hdf +"nScopeTriggerOut" = ReadPclampVarPointer( file, "short" )
		Variable /G $hdf +"nLTPType" = ReadPclampVarPointer( file, "short" )
		Variable /G $hdf +"nAlternateDACOutputState" = ReadPclampVarPointer( file, "short" )
		Variable /G $hdf +"nAlternateDigitalOutputState" = ReadPclampVarPointer( file, "short" )
		Variable /G $hdf +"fCellID0" = ReadPclampVarPointer( file, "float" )
		Variable /G $hdf +"fCellID1" = ReadPclampVarPointer( file, "float" )
		Variable /G $hdf +"fCellID2" = ReadPclampVarPointer( file, "float" )
		Variable /G $hdf +"nDigitizerADCs" = ReadPclampVarPointer( file, "short" )
		Variable /G $hdf +"nDigitizerDACs" = ReadPclampVarPointer( file, "short" )
		Variable /G $hdf +"nDigitizerTotalDigitalOuts" = ReadPclampVarPointer( file, "short" )
		Variable /G $hdf +"nDigitizerSynchDigitalOuts" = ReadPclampVarPointer( file, "short" )
		Variable /G $hdf +"nDigitizerType" = ReadPclampVarPointer( file, "short" )
	endif
	
	// ADC Information Section
	
	if ( readAll && ( NMProgressCall( -2, "Reading ABF Header ..." ) == 1 ) )
		return -1 // cancel
	endif
	
	ABF_Read_Pointer = SectionADC_BlockIndex * ABF_BLOCK
	
	numADCs = max( ABF_NUMADCS, SectionADC_NumEntries1 )
	
	Make /I/O/N=( numADCs ) $hdf+"nTelegraphEnable" = 0
	Make /I/O/N=( numADCs ) $hdf+"nTelegraphInstrument" = 0
	Make /O/N=( numADCs ) $hdf+"fTelegraphAdditGain" = NaN
	Make /O/N=( numADCs ) $hdf+"fTelegraphFilter" = NaN
	Make /O/N=( numADCs ) $hdf+"fTelegraphMembraneCap" = NaN
	Make /I/O/N=( numADCs ) $hdf+"nTelegraphMode" = 0
	Make /O/N=( numADCs ) $hdf+"fTelegraphAccessResistance" = NaN
	
	Make /I/O/N=( numADCs ) $hdf+"nADCtoLChannelMap" = 0
	Make /I/O/N=( numADCs ) $hdf+"nADCSamplingSeq" = 0
	
	Make /O/N=( numADCs ) $hdf+"fADCProgrammableGain" = NaN
	Make /O/N=( numADCs ) $hdf+"fADCDisplayAmplification" = NaN
	Make /O/N=( numADCs ) $hdf+"fADCDisplayOffset" = NaN
	Make /O/N=( numADCs ) $hdf+"fInstrumentScaleFactor" = NaN
	Make /O/N=( numADCs ) $hdf+"fInstrumentOffset" = NaN
	Make /O/N=( numADCs ) $hdf+"fSignalGain" = NaN
	Make /O/N=( numADCs ) $hdf+"fSignalOffset" = NaN
	Make /O/N=( numADCs ) $hdf+"fSignalLowpassFilter" = NaN
	Make /O/N=( numADCs ) $hdf+"fSignalHighpassFilter" = NaN
	
	Make /T/O/N=( numADCs ) $hdf+"sLowpassFilterType" = ""
	Make /T/O/N=( numADCs ) $hdf+"sHighpassFilterType" = ""
	
	Make /O/N=( numADCs ) $hdf+"fPostProcessLowpassFilter" = NaN
	Make /T/O/N=( numADCs ) $hdf+"sPostProcessLowpassFilterType" = ""
	Make /I/O/N=( numADCs ) $hdf+"bEnabledDuringPN" = 0
	
	Make /I/O/N=( numADCs ) $hdf+"nStatsChannelPolarity" = 0
	
	Make /I/O/N=( numADCs ) $hdf+"lADCChannelNameIndex" = 0
	Make /I/O/N=( numADCs ) $hdf+"lADCUnitsIndex" = 0
	
	Make /T/O/N=( numADCs ) $hdf+"sADCChannelName" = ""
	Make /T/O/N=( numADCs ) $hdf+"sADCUnits" = ""
	
	Wave nTelegraphEnable = $hdf+"nTelegraphEnable"
	Wave nTelegraphInstrumen = $hdf+"nTelegraphInstrument"
	Wave fTelegraphAdditGain = $hdf+"fTelegraphAdditGain"
	Wave fTelegraphFilter = $hdf+"fTelegraphFilter"
	Wave fTelegraphMembraneCap = $hdf+"fTelegraphMembraneCap"
	Wave nTelegraphMode = $hdf+"nTelegraphMode"
	Wave fTelegraphResistance = $hdf+"fTelegraphAccessResistance"
	
	Wave nADCtoLChannelMap = $hdf+"nADCtoLChannelMap"
	Wave nADCSamplingSeq = $hdf+"nADCSamplingSeq"
	
	Wave fADCProgrammableGain = $hdf+"fADCProgrammableGain"
	Wave fADCDisplayAmplification = $hdf+"fADCDisplayAmplification"
	Wave fADCDisplayOffset = $hdf+"fADCDisplayOffset"
	Wave fInstrumentScaleFactor = $hdf+"fInstrumentScaleFactor"
	Wave fInstrumentOffset = $hdf+"fInstrumentOffset"
	Wave fSignalGain = $hdf+"fSignalGain"
	Wave fSignalOffset = $hdf+"fSignalOffset"
	Wave fSignalLowpassFilter = $hdf+"fSignalLowpassFilter"
	Wave fSignalHighpassFilter = $hdf+"fSignalHighpassFilter"
	
	Wave /T sLowpassFilterType = $hdf+"sLowpassFilterType"
	Wave /T sHighpassFilterType = $hdf+"sHighpassFilterType"
	
	Wave fPostProcessLowpassFilter = $hdf+"fPostProcessLowpassFilter"
	Wave /T sPostProcessLowpassFilterType = $hdf+"sPostProcessLowpassFilterType"
	Wave bEnabledDuringPN = $hdf+"bEnabledDuringPN"
	
	Wave nStatsChannelPolarity = $hdf+"nStatsChannelPolarity"
	
	Wave lADCChannelNameIndex = $hdf+"lADCChannelNameIndex"
	Wave lADCUnitsIndex = $hdf+"lADCUnitsIndex"
	
	Variable /G $hdf+"nADCNumChannels" = SectionADC_NumEntries1
	
	for ( icnt = 0 ; icnt < SectionADC_NumEntries1 ; icnt += 1 )
	
		if ( icnt >= numpnts( nADCSamplingSeq ) )
			break
		endif
		
		jcnt = ReadPclampVarPointer( file, "short" )
		
		nADCSamplingSeq[ icnt ] = jcnt // NEED THIS
		
		if ( ( jcnt < 0 ) || ( jcnt >= numADCs ) )
			Print "ADC index out of range", jcnt
			return -1
		endif
	
		nTelegraphEnable[ jcnt ] = ReadPclampVarPointer( file, "short" )
		nTelegraphInstrumen[ jcnt ] = ReadPclampVarPointer( file, "short" )
		fTelegraphAdditGain[ jcnt ] = ReadPclampVarPointer( file, "float" ) // NEED THIS
		fTelegraphFilter[ jcnt ] = ReadPclampVarPointer( file, "float" )
		fTelegraphMembraneCap[ jcnt ] = ReadPclampVarPointer( file, "float" )
		nTelegraphMode[ jcnt ] = ReadPclampVarPointer( file, "short" )
		fTelegraphResistance[ jcnt ] = ReadPclampVarPointer( file, "float" )
		
		nADCtoLChannelMap[ jcnt ] = ReadPclampVarPointer( file, "short" )
		//nADCSamplingSeq[ jcnt ] = ReadPclampVarPointer( file, "short" )
		ReadPclampVarPointer( file, "short" )
		
		fADCProgrammableGain[ jcnt ] = ReadPclampVarPointer( file, "float" )
		fADCDisplayAmplification[ jcnt ] = ReadPclampVarPointer( file, "float" )
		fADCDisplayOffset[ jcnt ] = ReadPclampVarPointer( file, "float" )
		fInstrumentScaleFactor[ jcnt ] = ReadPclampVarPointer( file, "float" ) // NEED THIS
		fInstrumentOffset[ jcnt ] = ReadPclampVarPointer( file, "float" )
		fSignalGain[ jcnt ] = ReadPclampVarPointer( file, "float" )
		fSignalOffset[ jcnt ] = ReadPclampVarPointer( file, "float" )
		fSignalLowpassFilter[ jcnt ] = ReadPclampVarPointer( file, "float" )
		fSignalHighpassFilter[ jcnt ] = ReadPclampVarPointer( file, "float" )
		
		sLowpassFilterType[ jcnt ] = num2char( ReadPclampVarPointer( file, "char" ) )
		sHighpassFilterType[ jcnt ] = num2char( ReadPclampVarPointer( file, "char" ) )
		
		fPostProcessLowpassFilter[ jcnt ] = ReadPclampVarPointer( file, "float" )
		sPostProcessLowpassFilterType[ jcnt ] = num2char( ReadPclampVarPointer( file, "char" ) )
		bEnabledDuringPN[ jcnt ] = ReadPclampVarPointer( file, "char" )
		
		nStatsChannelPolarity[ jcnt ] = ReadPclampVarPointer( file, "short" )
		
		lADCChannelNameIndex[ jcnt ] = ReadPclampVarPointer( file, "long" )
		lADCUnitsIndex[ jcnt ] = ReadPclampVarPointer( file, "long" )
		
		for ( kcnt = 0 ; kcnt < 46 ; kcnt += 1 )
			ReadPclampVarPointer( file, "char" ) // unused
		endfor
	
	endfor
	
	// DAC Information Section
	
	if ( readAll )
	
		if ( readAll && ( NMProgressCall( -2, "Reading ABF Header ..." ) == 1 ) )
			return -1 // cancel
		endif
	
		ABF_Read_Pointer = SectionDAC_BlockIndex * ABF_BLOCK
		
		numDACs = max( ABF_NUMDACS, SectionDAC_NumEntries1 )
		
		Make /I/O/N=( numDACs ) $hdf+"nTelegraphDACScaleFactorEnable" = 0
		Make /O/N=( numDACs ) $hdf+"fInstrumentHoldingLevel" = NaN
		Make /O/N=( numDACs ) $hdf+"fDACScaleFactor" = NaN
		Make /O/N=( numDACs ) $hdf+"fDACHoldingLevel" = NaN
		Make /O/N=( numDACs ) $hdf+"fDACCalibrationFactor" = NaN
		Make /O/N=( numDACs ) $hdf+"fDACCalibrationOffset" = NaN
		
		Make /I/O/N=( numDACs ) $hdf+"lDACChannelNameIndex" = 0
		Make /I/O/N=( numDACs ) $hdf+"lDACChannelUnitsIndex" = 0
		
		Make /I/O/N=( numDACs ) $hdf+"lDACFilePtr" = 0
		Make /I/O/N=( numDACs ) $hdf+"lDACFileNumEpisodes" = 0
		
		Make /I/O/N=( numDACs ) $hdf+"nWaveformEnable" = 0
		Make /I/O/N=( numDACs ) $hdf+"nWaveformSource" = 0
		Make /I/O/N=( numDACs ) $hdf+"nInterEpisodeLevel" = 0
		
		Make /O/N=( numDACs ) $hdf+"fDACFileScale" = NaN
		Make /O/N=( numDACs ) $hdf+"fDACFileOffset" = NaN
		Make /I/O/N=( numDACs ) $hdf+"lDACFileEpisodeNum" = 0
		Make /I/O/N=( numDACs ) $hdf+"nDACFileADCNum" = 0
		
		Make /I/O/N=( numDACs ) $hdf+"nConditEnable" = 0
		Make /I/O/N=( numDACs ) $hdf+"lConditNumPulses" = 0
		Make /O/N=( numDACs ) $hdf+"fBaselineDuration" = NaN
		Make /O/N=( numDACs ) $hdf+"fBaselineLevel" = NaN
		Make /O/N=( numDACs ) $hdf+"fStepDuration" = NaN
		Make /O/N=( numDACs ) $hdf+"fStepLevel" = NaN
		Make /O/N=( numDACs ) $hdf+"fPostTrainPeriod" = NaN
		Make /O/N=( numDACs ) $hdf+"fPostTrainLevel" = NaN
		Make /I/O/N=( numDACs ) $hdf+"nMembTestEnable" = 0
		
		Make /I/O/N=( numDACs ) $hdf+"nLeakSubtractType" = 0
		Make /I/O/N=( numDACs ) $hdf+"nPNPolarity" = 0
		
		Make /O/N=( numDACs ) $hdf+"fPNHoldingLevel" = NaN
		Make /I/O/N=( numDACs ) $hdf+"nPNNumADCChannels" = 0
		Make /I/O/N=( numDACs ) $hdf+"nPNPosition" = 0
		Make /I/O/N=( numDACs ) $hdf+"nPNNumPulses" = 0
		Make /O/N=( numDACs ) $hdf+"fPNSettlingTime" = NaN
		Make /O/N=( numDACs ) $hdf+"fPNInterpulse" = NaN
		
		Make /I/O/N=( numDACs ) $hdf+"nLTPUsageOfDAC" = 0
		Make /I/O/N=( numDACs ) $hdf+"nLTPPresynapticPulses" = 0
		
		Make /I/O/N=( numDACs ) $hdf+"lDACFilePathIndex" = 0
		
		Make /O/N=( numDACs ) $hdf+"fMembTestPreSettlingTimeMS" = NaN
		Make /O/N=( numDACs ) $hdf+"fMembTestPostSettlingTimeMS" = NaN
		
		Make /I/O/N=( numDACs ) $hdf+"nLeakSubtractADCIndex" = 0
		
		Make /T/O/N=( numDACs ) $hdf+"sDACChannelName" = ""
		Make /T/O/N=( numDACs ) $hdf+"sDACUnits" = ""
		
		Wave nTelegraphDACScaleFactorEnable = $hdf+"nTelegraphDACScaleFactorEnable"
		Wave fInstrumentHoldingLevel = $hdf+"fInstrumentHoldingLevel"
		Wave fDACScaleFactor = $hdf+"fDACScaleFactor"
		Wave fDACHoldingLevel = $hdf+"fDACHoldingLevel"
		Wave fDACCalibrationFactor = $hdf+"fDACCalibrationFactor"
		Wave fDACCalibrationOffset = $hdf+"fDACCalibrationOffset"
		
		Wave lDACChannelNameIndex = $hdf+"lDACChannelNameIndex"
		Wave lDACChannelUnitsIndex = $hdf+"lDACChannelUnitsIndex"
		
		Wave lDACFilePtr = $hdf+"lDACFilePtr"
		Wave lDACFileNumEpisodes = $hdf+"lDACFileNumEpisodes"
		
		Wave nWaveformEnabl = $hdf+"nWaveformEnable"
		Wave nWaveformSource = $hdf+"nWaveformSource"
		Wave nInterEpisodeLevel = $hdf+"nInterEpisodeLevel"
		
		Wave fDACFileScale = $hdf+"fDACFileScale"
		Wave fDACFileOffset = $hdf+"fDACFileOffset"
		Wave lDACFileEpisodeNum = $hdf+"lDACFileEpisodeNum"
		Wave nDACFileADCNum = $hdf+"nDACFileADCNum"
		
		Wave nConditEnable = $hdf+"nConditEnable"
		Wave lConditNumPulses = $hdf+"lConditNumPulses"
		Wave fBaselineDuration = $hdf+"fBaselineDuration"
		Wave fBaselineLevel = $hdf+"fBaselineLevel"
		Wave fStepDuration = $hdf+"fStepDuration"
		Wave fStepLevel = $hdf+"fStepLevel"
		Wave fPostTrainPeriod = $hdf+"fPostTrainPeriod"
		Wave fPostTrainLevel = $hdf+"fPostTrainLevel"
		Wave nMembTestEnable = $hdf+"nMembTestEnable"
		
		Wave nLeakSubtractType = $hdf+"nLeakSubtractType"
		Wave nPNPolarit = $hdf+"nPNPolarity"
		
		Wave fPNHoldingLevel = $hdf+"fPNHoldingLevel"
		Wave nPNNumADCChannels = $hdf+"nPNNumADCChannels"
		Wave nPNPosition = $hdf+"nPNPosition"
		Wave nPNNumPulses = $hdf+"nPNNumPulses"
		Wave fPNSettlingTime = $hdf+"fPNSettlingTime"
		Wave fPNInterpulse = $hdf+"fPNInterpulse"
		
		Wave nLTPUsageOfDAC = $hdf+"nLTPUsageOfDAC"
		Wave nLTPPresynapticPulses = $hdf+"nLTPPresynapticPulses"
		
		Wave lDACFilePathIndex = $hdf+"lDACFilePathIndex"
		
		Wave fMembTestPreSettlingTimeMS = $hdf+"fMembTestPreSettlingTimeMS"
		Wave fMembTestPostSettlingTimeMS = $hdf+"fMembTestPostSettlingTimeMS"
		
		Wave nLeakSubtractADCIndex = $hdf+"nLeakSubtractADCIndex"
		
		for ( icnt = 0 ; icnt < SectionDAC_NumEntries1 ; icnt += 1 )
			
			jcnt = ReadPclampVarPointer( file, "short" )
			
			// jcnt = icnt
			
			if ( ( jcnt < 0 ) || ( jcnt >= numDACs ) )
				Print "DAC index out of range", jcnt
				return -1
			endif
			
			nTelegraphDACScaleFactorEnable[ jcnt ] = ReadPclampVarPointer( file, "short" )
			fInstrumentHoldingLevel[ jcnt ] = ReadPclampVarPointer( file, "float" )
			fDACScaleFactor[ jcnt ] = ReadPclampVarPointer( file, "float" )
			
			fDACCalibrationFactor[ jcnt ] = ReadPclampVarPointer( file, "float" )
			fDACCalibrationOffset[ jcnt ] = ReadPclampVarPointer( file, "float" )
			fDACHoldingLevel[ jcnt ] = ReadPclampVarPointer( file, "float" )
			lDACChannelNameIndex[ jcnt ] = ReadPclampVarPointer( file, "long" )
			lDACChannelUnitsIndex[ jcnt ] = ReadPclampVarPointer( file, "long" )
			
			lDACFilePtr[ jcnt ] = ReadPclampVarPointer( file, "long" )
			lDACFileNumEpisodes[ jcnt ] = ReadPclampVarPointer( file, "long" )
			
			nWaveformEnabl[ jcnt ] = ReadPclampVarPointer( file, "short" )
			nWaveformSource[ jcnt ] = ReadPclampVarPointer( file, "short" )
			nInterEpisodeLevel[ jcnt ] = ReadPclampVarPointer( file, "short" )
			
			fDACFileScale[ jcnt ] = ReadPclampVarPointer( file, "float" )
			fDACFileOffset[ jcnt ] = ReadPclampVarPointer( file, "float" )
			lDACFileEpisodeNum[ jcnt ] = ReadPclampVarPointer( file, "long" )
			nDACFileADCNum[ jcnt ] = ReadPclampVarPointer( file, "short" )
			
			nConditEnable[ jcnt ] = ReadPclampVarPointer( file, "short" )
			lConditNumPulses[ jcnt ] = ReadPclampVarPointer( file, "long" )
			fBaselineDuration[ jcnt ] = ReadPclampVarPointer( file, "float" )
			fBaselineLevel[ jcnt ] = ReadPclampVarPointer( file, "float" )
			fStepDuration[ jcnt ] = ReadPclampVarPointer( file, "float" )
			fStepLevel[ jcnt ] = ReadPclampVarPointer( file, "float" )
			fPostTrainPeriod[ jcnt ] = ReadPclampVarPointer( file, "float" )
			fPostTrainLevel[ jcnt ] = ReadPclampVarPointer( file, "float" )
			nMembTestEnable[ jcnt ] = ReadPclampVarPointer( file, "short" )
			
			nLeakSubtractType[ jcnt ] = ReadPclampVarPointer( file, "short" )
			nPNPolarit[ jcnt ] = ReadPclampVarPointer( file, "short" )
			
			fPNHoldingLevel[ jcnt ] = ReadPclampVarPointer( file, "float" )
			nPNNumADCChannels[ jcnt ] = ReadPclampVarPointer( file, "short" )
			nPNPosition[ jcnt ] = ReadPclampVarPointer( file, "short" )
			nPNNumPulses[ jcnt ] = ReadPclampVarPointer( file, "short" )
			fPNSettlingTime[ jcnt ] = ReadPclampVarPointer( file, "float" )
			fPNInterpulse[ jcnt ] = ReadPclampVarPointer( file, "float" )
			
			nLTPUsageOfDAC[ jcnt ] = ReadPclampVarPointer( file, "short" )
			nLTPPresynapticPulses[ jcnt ] = ReadPclampVarPointer( file, "short" )
			
			lDACFilePathIndex[ jcnt ] = ReadPclampVarPointer( file, "long" )
			
			fMembTestPreSettlingTimeMS[ jcnt ] = ReadPclampVarPointer( file, "float" )
			fMembTestPostSettlingTimeMS[ jcnt ] = ReadPclampVarPointer( file, "float" )
		
			nLeakSubtractADCIndex[ jcnt ] = ReadPclampVarPointer( file, "short" )
			
			for ( kcnt = 0 ; kcnt < 124 ; kcnt += 1 )
				ReadPclampVarPointer( file, "char" ) // unused
			endfor
			
		endfor
	
	endif
	
	// Epoch Per DAC Section
	
	if ( readAll )
	
		if ( readAll && ( NMProgressCall( -2, "Reading ABF Header ..." ) == 1 ) )
			return -1 // cancel
		endif
	
		ABF_Read_Pointer = SectionEpochPerDAC_BlockIndex * ABF_BLOCK
		
		Make /I/O/N=( numDACs, ABF_EPOCHCOUNT ) $hdf+"nEpochType" = 0
		Make /O/N=( numDACs, ABF_EPOCHCOUNT ) $hdf+"fEpochInitLevel" = NaN
		Make /O/N=( numDACs, ABF_EPOCHCOUNT ) $hdf+"fEpochLevelInc" = NaN
		Make /I/O/N=( numDACs, ABF_EPOCHCOUNT ) $hdf+"lEpochInitDuration" = 0
		Make /I/O/N=( numDACs, ABF_EPOCHCOUNT ) $hdf+"lEpochDurationInc" = 0
		Make /I/O/N=( numDACs, ABF_EPOCHCOUNT ) $hdf+"lEpochPulsePeriod" = 0
		Make /I/O/N=( numDACs, ABF_EPOCHCOUNT ) $hdf+"lEpochPulseWidth" = 0
		
		Wave nEpochType = $hdf+"nEpochType"
		Wave fEpochInitLevel = $hdf+"fEpochInitLevel"
		Wave fEpochLevelInc = $hdf+"fEpochLevelInc"
		Wave lEpochInitDuration = $hdf+"lEpochInitDuration"
		Wave lEpochDurationInc = $hdf+"lEpochDurationInc"
		Wave lEpochPulsePeriod = $hdf+"lEpochPulsePeriod"
		Wave lEpochPulseWidth = $hdf+"lEpochPulseWidth"
		
		for ( icnt = 0 ; icnt < SectionEpochPerDAC_NumEntries1 ; icnt += 1 )
		
			kcnt = ReadPclampVarPointer( file, "short" )
			jcnt = ReadPclampVarPointer( file, "short" )
			
			if ( ( jcnt < 0 ) || ( jcnt >= numDACs ) )
				Print "DAC index out of range", jcnt
				return -1
			endif
			
			if ( ( kcnt < 0 ) || ( kcnt >= ABF_EPOCHCOUNT ) )
				Print "ABF_EPOCHCOUNT error", kcnt
				return -1
			endif
			
			nEpochType[ jcnt ][ kcnt ] = ReadPclampVarPointer( file, "short" )
			fEpochInitLevel[ jcnt ][ kcnt ] = ReadPclampVarPointer( file, "float" )
			fEpochLevelInc[ jcnt ][ kcnt ] = ReadPclampVarPointer( file, "float" )
			lEpochInitDuration[ jcnt ][ kcnt ] = ReadPclampVarPointer( file, "long" )
			lEpochDurationInc[ jcnt ][ kcnt ] = ReadPclampVarPointer( file, "long" )
			lEpochPulsePeriod[ jcnt ][ kcnt ] = ReadPclampVarPointer( file, "long" )
			lEpochPulseWidth[ jcnt ][ kcnt ] = ReadPclampVarPointer( file, "long" )
			
			for ( lcnt = 0 ; lcnt < 18 ; lcnt += 1 )
				ReadPclampVarPointer( file, "char" ) // unused
			endfor
			
		endfor
	
	endif
	
	// Epoch Information Section
	
	if ( readAll )
	
		if ( readAll && ( NMProgressCall( -2, "Reading ABF Header ..." ) == 1 ) )
			return -1 // cancel
		endif
	
		ABF_Read_Pointer = SectionEpoch_BlockIndex * ABF_BLOCK
		
		Make /I/O/N=( ABF_EPOCHCOUNT ) $hdf+"nDigitalValue" = 0
		Make /I/O/N=( ABF_EPOCHCOUNT ) $hdf+"nDigitalTrainValue" = 0
		Make /I/O/N=( ABF_EPOCHCOUNT ) $hdf+"nAlternateDigitalValue" = 0
		Make /I/O/N=( ABF_EPOCHCOUNT ) $hdf+"nAlternateDigitalTrainValue" = 0
		Make /I/O/N=( ABF_EPOCHCOUNT ) $hdf+"bEpochCompression" = 0
		
		Wave nDigitalValue = $hdf+"nDigitalValue"
		Wave nDigitalTrainValue = $hdf+"nDigitalTrainValue"
		Wave nAlternateDigitalValue = $hdf+"nAlternateDigitalValue"
		Wave nAlternateDigitalTrainValue = $hdf+"nAlternateDigitalTrainValue"
		Wave bEpochCompression = $hdf+"bEpochCompression"
		
		for ( icnt = 0 ; icnt < SectionEpoch_NumEntries1 ; icnt += 1 )
		
			jcnt = ReadPclampVarPointer( file, "short" )
			
			if ( ( jcnt < 0 ) || ( jcnt >= ABF_EPOCHCOUNT ) )
				Print "ABF_EPOCHCOUNT error", jcnt
				return -1
			endif
			
			nDigitalValue[ jcnt ] = ReadPclampVarPointer( file, "short" )
			nDigitalTrainValue[ jcnt ] = ReadPclampVarPointer( file, "short" )
			nAlternateDigitalValue[ jcnt ] = ReadPclampVarPointer( file, "short" )
			nAlternateDigitalTrainValue[ jcnt ] = ReadPclampVarPointer( file, "short" )
			bEpochCompression[ jcnt ] = ReadPclampVarPointer( file, "char" )
			
			for ( kcnt = 0 ; kcnt < 21 ; kcnt += 1 )
				ReadPclampVarPointer( file, "char" ) // unused
			endfor
		
		endfor
	
	endif
	
	// Strings Section
	
	if ( readAll && ( NMProgressCall( -2, "Reading ABF Header ..." ) == 1 ) )
		return -1 // cancel
	endif
	
	ABF_Read_Pointer = SectionStrings_BlockIndex * ABF_BLOCK
	
	strTemp = num2char( ReadPclampVarPointer( file, "char" ) ) // S
	strTemp += num2char( ReadPclampVarPointer( file, "char" ) ) // S
	strTemp += num2char( ReadPclampVarPointer( file, "char" ) ) // C
	strTemp += num2char( ReadPclampVarPointer( file, "char" ) ) // H
		
	if ( StringMatch( strTemp, "SSCH" ) )
	
		ReadPclampVarPointer( file, "char" ) // 1
		ReadPclampVarPointer( file, "char" ) // 0
		ReadPclampVarPointer( file, "char" ) // 0
		ReadPclampVarPointer( file, "char" ) // 0
	
		uNumStrings = ReadPclampVarPointer( file, "uint" )
		uMaxSize = ReadPclampVarPointer( file, "uint" )
		lTotalBytes = ReadPclampVarPointer( file, "long" )
	
		for ( icnt = 0 ; icnt < 6 ; icnt += 1 )
			ReadPclampVarPointer( file, "uint" ) // unused
		endfor
		
		Make /T/O/N=( uNumStrings ) $hdf+"sNames" = ""
	
		Wave /T sNames = $hdf+"sNames"
		
		jcnt = 0
		strTemp = ""
	
		for ( icnt = 0 ; icnt < lTotalBytes ; icnt += 1 )
		
			varTemp = ReadPclampVarPointer( file, "char" )
			
			if ( varTemp == 0 )
				sNames[ jcnt ] = strTemp
				strTemp = ""
				jcnt += 1
			elseif ( varTemp > 0 )
				strTemp += num2char( varTemp )
			endif
			
			if ( jcnt >= numpnts( sNames ) )
				break
			endif
			
		endfor
		
		Wave /T sADCChannelName = $hdf + "sADCChannelName"
		Wave /T sADCUnits = $hdf + "sADCUnits"
		
		Wave lADCChannelNameIndex = $hdf+"lADCChannelNameIndex"
		Wave lADCUnitsIndex = $hdf+"lADCUnitsIndex"
		
		for ( icnt = 0 ; icnt < numADCs ; icnt += 1 )
		
			varTemp = lADCChannelNameIndex[ icnt ] - 1
		
			if ( ( varTemp >= 0 ) && ( varTemp < numpnts( sNames ) ) )
				sADCChannelName[ icnt ] = sNames[ varTemp ] // NEED THIS
			endif
			
			varTemp = lADCUnitsIndex[ icnt ] - 1
			
			if ( ( varTemp >= 0 ) && ( varTemp < numpnts( sNames) ) )
				sADCUnits[ icnt ] = sNames[ varTemp ] // NEED THIS
			endif

		endfor
		
		if ( readAll )
		
			Wave /T sDACChannelName = $hdf + "sDACChannelName"
			Wave /T sDACUnits = $hdf + "sDACUnits"
			
			Wave lDACChannelNameIndex = $hdf+"lDACChannelNameIndex"
			Wave lDACChannelUnitsIndex = $hdf+"lDACChannelUnitsIndex"
			
			for ( icnt = 0 ; icnt < ABF_NUMDACS ; icnt += 1 )
			
				varTemp = lDACChannelNameIndex[ icnt ] - 1
			
				if ( ( varTemp >= 0 ) && ( varTemp < numpnts( sNames ) ) )
					sDACChannelName[ icnt ] = sNames[ varTemp ]
				endif
				
				varTemp = lDACChannelUnitsIndex[ icnt ] - 1
				
				if ( ( varTemp >= 0 ) && ( varTemp < numpnts( sNames ) ) )
					sDACUnits[ icnt ] = sNames[ varTemp ]
				endif
	
			endfor
		
		endif
	
	endif
	
	ReadPclampHeaderUpdateNM( df, hdf )
	
	SetNMstr( df+"ImportFileType", "Pclamp 2" )
	
	KillVariables /Z ABF_Read_Pointer
	
	KillWaves /Z $df+"NM_ReadPclampWave0"
	KillWaves /Z $df+"NM_ReadPclampWave1"
	
	NMProgressKill()
	
	return 1
	
End // ReadPClampHeader2

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Read Pclamp XOP Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Static Function ReadPClampHeaderXOP( file, df )
	String file // external ABF data file
	String df // NM data folder where everything is imported
	
	Variable OK, format, startByteGUID = 5282
	
	String saveDF = GetDataFolder( 1 )
	
	df = ParseFilePath( 2, df, ":", 0, 0 )
	
	String hdf = df + ABF_SUBFOLDERNAME + ":"
	
	NewDataFolder /O/S $RemoveEnding( hdf, ":" )
	
	Execute /Z "ReadPclamp /H " + NMQuotes( ReadPClampFileC( file ) ) // import header
	
	if ( WaveExists( $"ABF_nADCSamplingSeq" ) )
		OK = 1
	endif
	
	SetDataFolder $saveDF // back to original folder
	
	if ( !OK )
		return -1
	endif
	
	format = ReadPclampFormat( file )
	
	if ( format == 2 )
		startByteGUID = 40
	endif
	
	ReadPClampGUID( hdf, file, startByteGUID, "ABF_" )
	
	ReadPclampHeaderUpdateNM( df, hdf )
	
	return 1

End // ReadPClampHeaderXOP

//****************************************************************
//****************************************************************
//****************************************************************

Static Function ReadPClampDataXOP( file, df )
	String file // external ABF data file
	String df // NM data folder where everything is imported
	
	Variable wcnt, ccnt, scnt, scale, startNum, amode, samples
	String wName, cName, wNote, wList, yl
	
	Variable concat = NumVarOrDefault( NMDF+"ABF_GapFreeConcat", 1 )
	
	df = ParseFilePath( 2, df, ":", 0, 0 )
	
	String acqMode = StrVarOrDefault( df+"AcqMode", "" )
	
	if ( strlen( acqMode ) == 0 )
	
		if ( ReadPClampHeaderXOP( file, df ) < 0 ) // read header first
			return -1
		endif
		
		acqMode = StrVarOrDefault( df+"AcqMode", "" )
	
	endif
	
	amode = str2num( acqMode[ 0 ] )
	
	String hdf = df + ABF_SUBFOLDERNAME + ":"
	
	Variable NumWaves = NumVarOrDefault( df+"NumWaves", 0 )
	Variable NumChannels = NumVarOrDefault( df+"NumChannels", 0 )
	Variable WaveBgn = NumVarOrDefault( df+"WaveBgn", 0 )
	Variable WaveEnd = NumVarOrDefault( df+"WaveEnd", -1 )
	Variable format = ReadPclampFormat( file )
	
	String wavePrefix = StrVarOrDefault( df+"WavePrefix", NMStrGet( "WavePrefix" ) )
	String xLabel = StrVarOrDefault( df+"xLabel", NMXunits )
	
	Wave scaleFactors = $df+"FileScaleFactors"
	Wave /T yAxisLabels = $df+"yLabel"
	
	String saveDF = GetDataFolder( 1 )
	
	SetDataFolder $df
	
	startNum = NextWaveNum( "", wavePrefix, 0, 0 )
	
	if ( ( WaveBgn > WaveEnd ) || ( startNum < 0 ) || ( numtype( WaveBgn*WaveEnd*startNum ) != 0 ) )
		return 0 // options not allowed
	endif
	
	NMProgressCall( -1, "Reading Pclamp File..." ) // bring up progress window
	
	Execute /Z "ReadPclamp /D /N=( " + num2istr( WaveBgn + 1 ) + "," + num2istr( WaveEnd + 1 ) + " ) /P=" + NMQuotes( wavePrefix ) + " /S=" + num2istr( startNum ) + " " + NMQuotes( ReadPClampFileC( file ) )
	
	SetDataFolder $saveDF // back to original folder
	
	NMProgressKill()
	
	WaveBgn += startNum
	WaveEnd += startNum
	
	for ( ccnt = 0 ; ccnt < NumChannels ; ccnt += 1 )
	
		scnt = 0
		
		if ( ccnt < numpnts( scaleFactors ) )
			scale = scaleFactors[ ccnt ]
		else
			scale = 1
		endif
		
		if ( ccnt < numpnts( yAxisLabels ) )
			yl = yAxisLabels[ ccnt ]
		else
			yl = ""
		endif
		
		for ( wcnt = WaveBgn ; wcnt <= WaveEnd ; wcnt += 1 )
		
			wName = GetWaveName( wavePrefix, ccnt, wcnt )
			
			wNote = "Folder:" + GetDataFolder( 0 )
			wNote += NMCR + "File:" + NMNoteCheck( file )
			wNote += NMCR + "Chan:" + ChanNum2Char( ccnt )
			wNote += NMCR + "Wave:" + num2istr( wcnt )
			wNote += NMCR + "Scale:" + num2str( scale )

			NMNoteType( wName, "Pclamp " + num2str( format ), xLabel, yl, wNote )
			PclampTimeStamps( file, format, amode, df, wName, scnt )
			
			scnt += 1
			
		endfor
	endfor
	
	if ( ( amode == 3 ) && concat )
	
		for ( ccnt = 0 ; ccnt < NumChannels ; ccnt += 1 )
		
			wList = ""
			
			if ( ccnt < numpnts( yAxisLabels ) )
				yl = yAxisLabels[ ccnt ]
			else
				yl = ""
			endif
		
			for ( wcnt = WaveBgn ; wcnt <= WaveEnd ; wcnt += 1 )
				wName = GetWaveName( wavePrefix, ccnt, wcnt )
				wList = AddListItem( wName, wList, ";", inf )
			endfor
			
			cName = GetWaveName( "C_ABF_" + wavePrefix, ccnt, WaveBgn )
			
			Concatenate /O/NP wList, $cName
			
			if ( WaveExists( $cName ) )
				NMKillWaves( wList )
			else
				concat = 0 // something went wrong
				break
			endif
			
			wName = GetWaveName( wavePrefix, ccnt, WaveBgn )
			
			Duplicate /O $cName $wName
			
			samples = numpnts( $wName )
			
			wNote = "Folder:" + GetDataFolder( 0 )
			wNote += NMCR + "File:" + NMNoteCheck( file )
			wNote += NMCR + "Chan:" + ChanNum2Char( ccnt )
			wNote += NMCR + "Wave:" + num2istr( WaveBgn )
			wNote += NMCR + "Scale:" + num2str( scale )

			NMNoteType( wName, "Pclamp " + num2str( format ), xLabel, yl, wNote )
			PclampTimeStamps( file, format, amode, df, wName, 0 )
			
		endfor
		
		if ( concat )
			SetNMvar( df + "NumWaves", 1 )
			SetNMvar( df + "TotalNumWaves", 1 * NumChannels )
			SetNMvar( df + "SamplesPerWave", samples )
			WaveEnd = WaveBgn
		endif
		
		wList = WaveList( "C_ABF_*", ";", "" )
		NMKillWaves( wList )
	
	endif
	
	return ( WaveEnd - WaveBgn + 1 )
	
End // ReadPClampDataXOP

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S ReadPClampFileC( file ) // convert Igor file string to C/C++ file string
	String file // external ABF data file
	String fileC

	fileC = ReplaceString( ":", file, "/" )
	fileC = file[ 0, 0 ] + ":/" + fileC[ 2, inf ]
	
	return fileC
	
End // ReadPClampFileC

//****************************************************************
//****************************************************************
//****************************************************************

Static Function ReadPclampXOPAlert()

	String alertStr0, alertStr1, alertStr2, alertStr3

	if ( ReadPclampXOPExists() || StringMatch( NMComputerType(), "mac" ) )
		return 0
	endif
	
	if ( NumVarOrDefault( NMDF + "ReadPclampXOPAlertOff", 0 ) == 1 )
		return 0
	endif
	
	if ( ABF_XOP_ON == 0 )
		return 0
	endif
	
	alertStr0 = "PC / Windows users:  use the Read Pclamp XOP to import your data faster. "
	alertStr1 = "Download from http://neuromatic.thinkrandom.com/stuff/. "
	alertStr2 = "Instructions are inside the zip file. "
	alertStr3 = "This message has been printed to Igor's history window."
	
	Print alertStr0
	Print alertStr1
	Print alertStr2
	Print " "

	NMDoAlert( alertStr0 + alertStr1 + alertStr2 + alertStr3 )
	
	SetNMvar( NMDF + "ReadPclampXOPAlertOff", 1 ) // alert only once

End // ReadPclampXOPAlert

//****************************************************************
//****************************************************************
//****************************************************************


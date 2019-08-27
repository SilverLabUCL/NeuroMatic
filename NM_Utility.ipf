#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma hide = 1

// SetIgorOption IndependentModuleDev=1 (unhide)

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
//	String folder // data folder where waves in wList exist
//	String wList // list of wave names with ";" seperator
//	String xWave // x-axis wave name
//	Variable xbgn, xend // x-axis window begin and end
//	Variable deprecation
//
//****************************************************************
//****************************************************************

StrConstant NMPlotColorList = "black;gray;red;yellow;green;blue;purple;white;"
StrConstant NMCancel = "CANCEL"
StrConstant NMCR = "\r" // carriage return

//****************************************************************
//****************************************************************

Function BinaryCheck( num )
	Variable num
	
	if ( num == 0 )
		return 0
	else
		return 1
	endif

End // BinaryCheck

//****************************************************************
//****************************************************************

Function BinaryInvert( num )
	Variable num
	
	if ( num == 0 )
		return 1
	else
		return 0
	endif

End // BinaryInvert

//****************************************************************
//****************************************************************

Function Zero2Nan( num )
	Variable num
	
	if ( num == 0 )
		return NaN
	else
		return num
	endif
	
End // Zero2Nan

//****************************************************************
//****************************************************************

Function Nan2Zero( num )
	Variable num
	
	if ( numtype( num ) == 2 )
		return 0
	else
		return num
	endif
	
End // Nan2Zero

//****************************************************************
//****************************************************************

Function NMInequality( testValue [ greaterThan, lessThan, binaryOutput, deprecation ] )
	Variable testValue
	Variable greaterThan, lessThan
	Variable binaryOutput // ( 0 ) output wave will contain NaN for false or corresponding input wave value for true ( 1 ) output wave will contain '0' for false or '1' for true
	Variable deprecation
	
	Variable inequality = 1
	
	if ( deprecation )
		NMDeprecationAlert()
	endif
	
	if ( ParamIsDefault( binaryOutput ) )
		binaryOutput = 1
	endif
	
	if ( !ParamIsDefault( greaterThan ) && ( numtype( greaterThan ) == 0 ) )
		inequality = inequality && ( testValue > greaterThan )
	endif
	
	if ( !ParamIsDefault( lessThan ) && ( numtype( lessThan ) == 0 ) )
		inequality = inequality && ( testValue < lessThan )
	endif
	
	if ( binaryOutput )
		return inequality
	elseif ( inequality )
		return testValue
	else
		return NaN
	endif
	
End // NMInequality

//****************************************************************
//****************************************************************

Function /S NMInequalityFxn( greaterThan, lessThan ) // create function string
	Variable greaterThan, lessThan
	
	if ( ( numtype( greaterThan ) == 0 ) && ( numtype( lessThan ) == 0 ) )
		return num2str( greaterThan ) + " < y < " + num2str( lessThan )
	elseif ( numtype( greaterThan ) == 0 )
		return "y > " + num2str( greaterThan )
	elseif ( numtype( lessThan ) == 0 )
		return "y < " + num2str( lessThan )
	endif
	
End // NMInequalityFxn

//****************************************************************
//****************************************************************

Structure NMInequalityStruct
	
	Variable lessThan, greaterThan, binaryOutput

EndStructure

//****************************************************************
//****************************************************************

Structure NMInequalityStructOld

	// old inequality variables
	
	Variable select, aValue, sValue, nValue
	
	// new inequality variables
	
	Variable lessThan, greaterThan

EndStructure

//****************************************************************
//****************************************************************

Function NMInequalityStructNull( s )
	STRUCT NMInequalityStructOld &s
	
	s.select = NaN; s.aValue = NaN; s.sValue = NaN; s.nValue = NaN
	s.lessThan = NaN; s.greaterThan = NaN
	
End // NMInequalityStructNull

//****************************************************************
//****************************************************************

Function /S NMInequalityStructConvert( select, aValue, sValue, nValue, s )
	Variable select
	Variable aValue, sValue, nValue
	STRUCT NMInequalityStructOld &s
	
	NMInequalityStructNull( s )
	
	s.select = select
	s.aValue = aValue
	s.sValue = sValue
	s.nValue = nValue
	
	return NMInequalityStructConvert2( s )

End // NMInequalityStructConvert

//****************************************************************
//****************************************************************

Function /S NMInequalityStructConvert2( s ) // convert old to new variables
	STRUCT NMInequalityStructOld &s
	
	switch( s.select )
	
		case 1: // y > a
			s.greaterThan = s.aValue
			break
			
		case 2: // y > a - n * s
			s.greaterThan = s.aValue - s.nValue * s.sValue
			break
			
		case 3: // y < a
			s.lessThan = s.aValue
			break
			
		case 4: // y < a + n * s
			s.lessThan = s.aValue + s.nValue * s.sValue
			break
			
		case 5: // a < y < b
			s.greaterThan = s.aValue
			s.lessThan = s.sValue
			break
			
		case 6: // a - n * s < y < a + n * s
			s.greaterThan = s.aValue - s.nValue * s.sValue
			s.lessThan = s.aValue + s.nValue * s.sValue
			break
			
	endswitch
	
	return "lessThan=" + num2str( s.lessThan ) + ";greaterThan=" + num2str( s.greaterThan ) + ";"

End // NMInequalityStructConvert2

//****************************************************************
//****************************************************************

Function /S NMInequalityCall( s, df [ promptStr ] )
	STRUCT NMInequalityStruct &s
	String df // data folder for global variables
	String promptStr
	
	if ( ParamIsDefault( promptStr ) || ( strlen( promptStr ) == 0 ) )
		promptStr = NMPromptStr( "NM Inequality <>" )
	endif
	
	String inequality = StrVarOrDefault( df + "InequalitySelect", "y > a" )
	Variable binaryOutput = 1 + NumVarOrDefault( df + "InequalityBinary", 1 )
	Variable aValue = NumVarOrDefault( df + "InequalityValueA", 0 )
	Variable bValue = NumVarOrDefault( df + "InequalityValueB", 0 )
	
	Prompt inequality, "inequality test for wave point values y:", popup "y > a;y < b;a < y < b;"
	Prompt binaryOutput, "denote true and false with:", popup "y and NaN;1 and 0;"
	Prompt aValue, "enter value for a:"
	Prompt bValue, "enter value for b:"
	
	DoPrompt promptStr, inequality, binaryOutput
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	binaryOutput -= 1
	
	SetNMstr( df + "InequalitySelect", inequality )
	SetNMvar( df + "InequalityBinary", binaryOutput )
	
	s.binaryOutput = binaryOutput
	
	promptStr = NMPromptStr( inequality )
	
	strswitch( inequality )
	
		case "y > a":
		
			DoPrompt promptStr, aValue
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
			s.lessThan = NaN
			
			if ( numtype( aValue ) == 0 )
				SetNMvar( df + "InequalityValueA", aValue )
				s.greaterThan = aValue
			else
				s.greaterThan = NaN
			endif
			
			break
		
		case "y < b":
		
			DoPrompt promptStr, bValue
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
			s.greaterThan = NaN
			
			if ( numtype( bValue ) == 0 )
				SetNMvar( df + "InequalityValueB", bValue )
				s.lessThan = bValue
			else
				s.lessThan = NaN
			endif
			
			break
			
		case "a < y < b":
		
			DoPrompt promptStr, aValue, bValue
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
			if ( numtype( aValue ) == 0 )
				SetNMvar( df + "InequalityValueA", aValue )
				s.greaterThan = aValue
			else
				s.greaterThan = NaN
			endif
			
			if ( numtype( bValue ) == 0 )
				SetNMvar( df + "InequalityValueB", bValue )
				s.lessThan = bValue
			else
				s.lessThan = NaN
			endif
			
	endswitch
	
	return "lessThan=" + num2str( s.lessThan ) + ";greaterThan=" + num2str( s.greaterThan ) + ";binaryOutput=" + num2istr( binaryOutput ) + ";"
	
End // NMInequalityCall

//****************************************************************
//****************************************************************
//
//		Folder utility functions
//
//****************************************************************
//
//	NMFolderVariableList
//	return VariableList for a given folder (see Igor VariableList function)
//
//****************************************************************

Function /S NMFolderVariableList( folder, matchStr, separatorStr, variableTypeCode, fullPath )
	String folder // ( "" ) for current folder
	String matchStr, separatorStr // see Igor VariableList
	Variable variableTypeCode // see Igor VariableList
	Variable fullPath // ( 0 ) no, just variable name ( 1 ) yes, directory + variable name
	
	Variable icnt
	String sList, sName, oList = ""
	String saveDF = GetDataFolder( 1 ) // save current directory
	
	if ( strlen( folder ) == 0 )
		folder = GetDataFolder( 1 )
	endif
	
	if ( !DataFolderExists( folder ) )
		return NM2ErrorStr( 30, "folder", folder )
	endif
	
	SetDataFolder $folder
	
	sList = VariableList( matchStr, separatorStr, variableTypeCode )
	
	SetDataFolder $saveDF // back to original data folder
	
	if ( fullPath )
	
		for ( icnt = 0 ; icnt < ItemsInList( sList ) ; icnt += 1 )
			sName = StringFromList( icnt, sList )
			oList = AddListItem( folder+sName, oList, separatorStr, inf ) // full-path names
		endfor
		
		sList = oList
	
	endif
	
	return sList

End // NMFolderVariableList

//****************************************************************
//
//	NMFolderStringList
//	return StringList for a given folder (see Igor StringList function)
//
//****************************************************************

Function /S NMFolderStringList( folder, matchStr, separatorStr, fullPath )
	String folder // ( "" ) for current folder
	String matchStr, separatorStr // see Igor StringList
	Variable fullPath // ( 0 ) no, just variable name ( 1 ) yes, directory + variable name
	
	Variable icnt
	String sList, sName, oList = ""
	String saveDF = GetDataFolder( 1 ) // save current directory
	
	if ( strlen( folder ) == 0 )
		folder = GetDataFolder( 1 )
	endif
	
	if ( !DataFolderExists( folder ) )
		return NM2ErrorStr( 30, "folder", folder )
	endif
	
	SetDataFolder $folder
	
	sList = StringList( matchStr, separatorStr )
	
	SetDataFolder $saveDF // back to original data folder
	
	if ( fullPath )
	
		for ( icnt = 0 ; icnt < ItemsInList( sList ) ; icnt += 1 )
			sName = StringFromList( icnt, sList )
			oList = AddListItem( folder+sName, oList, separatorStr, inf ) // full-path names
		endfor
		
		sList = oList
	
	endif
	
	return sList

End // NMFolderStringList

//****************************************************************
//****************************************************************
//
//		Wave utility functions
//
//****************************************************************
//****************************************************************

Function NMUtilityWaveTest( wList )
	String wList
	
	Variable wcnt
	String wName
	
	if ( ItemsInList( wList ) == 0 )
		return -1
	endif
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
	
		if ( !WaveExists( $wName ) || ( WaveType( $wName ) == 0 ) )
			return -1
		endif
		
	endfor
	
	return 0
	
End // NMUtilityWaveTest

//****************************************************************
//****************************************************************

Function WavesExist( wList )
	String wList
	
	Variable wcnt
	String wName
	
	if ( ItemsInList( wList ) == 0 )
		return 0
	endif
	
	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( !WaveExists( $wName ) )
			return 0
		endif
		
	endfor
	
	return 1 // yes, all exist

End // WavesExist

//****************************************************************
//****************************************************************

Function /S WhichWavesDontExist( wList )
	String wList
	
	Variable wcnt, numWaves = ItemsInList( wList )
	String wName, returnList = ""
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( !WaveExists( $wName ) )
			returnList = AddListItem( wName, returnList, ";", inf )
		endif
		
	endfor
	
	return returnList // those that dont exist

End // WhichWavesDontExist

//****************************************************************
//****************************************************************

Function /S NMWaveBrowser( promptStr [ numWavesLimit, numPoints, noText, noSelect ] )
	String promptStr
	Variable numWavesLimit // check number of waves selected
	Variable numPoints // check number of points
	Variable noText // check for text waves
	Variable noSelect // no initial selection
	
	Variable vflag, npnts, error
	String optionsStr, wList, wName = "", saveDF = GetDataFolder( 1 )
	
	if ( ParamIsDefault( numPoints ) )
	
		wList = WaveList( "*", ";", "" )
		
		if ( ItemsInList( wList ) > 0 )
			wName = StringFromList( 0, wList )
		endif
		
	else
	
		optionsStr = NMWaveListOptions( numPoints, 0 )
		
		wList =WaveList( "*", ";", optionsStr )
		
		if ( ItemsInList( wList ) > 0 )
			wName = StringFromList( 0, wList )
		endif
	
	endif
	
	if ( !noSelect && ( strlen( wName ) > 0 ) )
		Execute "CreateBrowser prompt=" + NMQuotes( promptStr ) + ", showWaves=1, showVars=0, showStrs=0, select=" + NMQuotes( wName )
	else
		Execute "CreateBrowser prompt=" + NMQuotes( promptStr ) + ", showWaves=1, showVars=0, showStrs=0"
	endif
	
	SetDataFolder saveDF // in case user changed data folder
	
	if ( ( exists( "V_Flag" ) != 2 ) || ( exists( "S_BrowserList" ) != 2 ) )
		return "" // no flags
	endif
	
	vflag = NumVarOrDefault( "V_Flag", 0 )
	wList = StrVarOrDefault( "S_BrowserList", "" )
	
	if ( vflag == 0 )
		return "" // cancel
	endif
	
	if ( !ParamIsDefault( numWavesLimit ) && ( ItemsInList( wList ) > numWavesLimit ) )
		DoAlert /T="NM Wave Browser" 0, "number of waves selected was greater than " + num2istr( numWavesLimit ) + "."
		error = 1
		wList = ""
	endif
	
	if ( !error && !WavesExist( wList ) )
		DoAlert /T="NM Wave Browser" 0, "one or more selected items are not a wave."
		error = 1
		wList = ""
	endif
	
	npnts = GetXstats( "points", wList )
	
	if ( !error && !ParamIsDefault( numPoints ) && ( npnts != numPoints ) )
		DoAlert /T="NM Wave Browser" 0, "one or more selected waves do not have a dimension of " + num2istr( numPoints ) + " points."
		error = 1
		wList = ""
	endif
	
	if ( !error && noText && ( NMUtilityWaveTest( wList ) != 0 ) )
		DoAlert /T="NM Wave Browser" 0, "one or more selected items are text waves."
		error = 1
		wList = ""
	endif
	
	KillVariables /Z V_Flag
	KillStrings /Z S_BrowserList
	
	if ( ItemsInList( wList ) == 1 )
		return StringFromList( 0, wList )
	endif
	
	return wList

End // NMWaveBrowser

//****************************************************************
//****************************************************************

Function WaveValOrDefault( wName, rowNum, defaultVal )
	String wName // wave name
	Variable rowNum // wave row number to retrive value
	Variable defaultVal // default value if everything values
	
	if ( WaveExists( $wName ) && ( WaveType( $wName ) > 0 ) )
		if ( ( rowNum >= 0 ) && ( rowNum < numpnts( $wName ) ) )
			Wave wtemp = $wName
			return wtemp[rowNum]
		endif
	endif
	
	return defaultVal

End // WaveValOrDefault

//****************************************************************
//****************************************************************

Function /S WaveStrOrDefault( wName, rowNum, defaultStr )
	String wName // wave name
	Variable rowNum // wave row number to retrieve string
	String defaultStr // default value if does not exist
	
	if ( WaveExists( $wName ) && ( WaveType( $wName ) == 0 ) )
		if ( ( rowNum >= 0 ) && ( rowNum < numpnts( $wName ) ) )
			Wave /T wtemp = $wName
			return wtemp[rowNum]
		endif
	endif
	
	return defaultStr

End // WaveStrOrDefault

//****************************************************************
//
//	NMWaveListOptions
//	use this for optionsStr in Igor function WaveList
//
//****************************************************************

Function /S NMWaveListOptions( numRows, wType )
	Variable numRows // number of rows in 1-dimensional wave
	Variable wType // waveType ( 0 ) not text ( 1 ) text
	
	return "DIMS:1,MAXROWS:" + num2istr( numRows ) + ",MINROWS:" + num2istr( numRows ) + ",TEXT:" + num2istr( BinaryCheck( wType ) )
	
End // NMWaveListOptions

//****************************************************************
//****************************************************************

Function /S NMFolderWaveList( folder, matchStr, separatorStr, optionsStr, fullPath ) // like Igor WaveList, but for a folder
	String folder // ( "" ) for current folder
	String matchStr, separatorStr, optionsStr // see Igor WaveList
	Variable fullPath // ( 0 ) no, just wave name ( 1 ) yes, directory + wave name
	
	Variable icnt
	String wList, wName, oList = ""
	String saveDF = GetDataFolder( 1 ) // save current directory
	
	if ( strlen( folder ) == 0 )
		folder = GetDataFolder( 1 )
	endif
	
	folder = CheckNMFolderPath( folder )
	
	if ( !DataFolderExists( folder ) )
		//return NM2ErrorStr( 30, "folder", folder )
		
		return ""
	endif
	
	SetDataFolder $folder
	
	wList = WaveList( matchStr, separatorStr, optionsStr )
	
	SetDataFolder $saveDF // back to original data folder
	
	if ( fullPath )
	
		for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
			wName = StringFromList( icnt, wList )
			oList = AddListItem( folder + wName , oList, separatorStr, inf ) // full-path names
		endfor
		
		wList = oList
	
	endif
	
	return wList

End // NMFolderWaveList

//****************************************************************
//****************************************************************

Function /S NMWindowWaveList( winNameStr, type, fullPath ) // list of waves for a window
	String winNameStr // ( "" ) for top graph or table
	Variable type // see Igor WaveRefIndexed type
	Variable fullPath // ( 0 ) no, just wave name ( 1 ) yes, directory + wave name
	
	Variable icnt
	String wName, wList = ""
	
	for ( icnt = 0 ; icnt < 9999 ; icnt += 1 )
	
		if ( !WaveExists( WaveRefIndexed( winNameStr, icnt, type ) ) )
			break
		endif
		
		wName = ""
	
		if ( fullPath )
			wName = GetWavesDataFolder( WaveRefIndexed( winNameStr, icnt, type ), 2 )
		else
			wName = NameOfWave( WaveRefIndexed( winNameStr, icnt, type ) )
		endif
		
		wList = AddListItem( wName, wList, ";", inf )
	
	endfor
	
	return wList
	
End // NMWindowWaveList

//****************************************************************
//****************************************************************

Function /S NMTableWaveList( tName, fullPath )
	String tName
	Variable fullPath
	
	Variable icnt, columns
	String info, folder, wName, wList = ""
	
	if ( WinType( tName ) != 2 )
		return NM2ErrorStr( 50, "tName", tName )
	endif
	
	info = TableInfo( tName, -2 )
	
	columns = str2num( StringByKey("COLUMNS", info) )
	
	if ( ( numtype( columns ) > 0 ) || ( columns <= 0 ) )
		return ""
	endif
	
	for ( icnt = 0 ; icnt < columns ; icnt += 1 )
	
		if ( !WaveExists( WaveRefIndexed( tName, icnt, 1 ) ) )
			continue
		endif
	
		Wave w = WaveRefIndexed( tName, icnt, 1 )
		
		if ( !WaveExists( w ) )
			continue
		endif
		
		if ( fullPath )
			wName = GetWavesDataFolder( w, 2 )
		else
			wName = NameOfWave( w )
		endif
		
		if ( strlen( wName ) > 0 )
			wList += wName + ";"
		endif
		
	endfor

	return wList
	
End // NMTableWaveList

//****************************************************************
//****************************************************************

Function /S Wave2List( wName [ precision, integer ] ) // convert wave items to list items
	String wName // wave name
	Variable precision // floating point precision for numeric wave (default 3)
	Variable integer // integer for numeric wave ( 0 ) no ( 1 ) yes
	
	Variable icnt, npnts, numObj
	String numStr, strObj, strList = ""
	
	if ( ParamIsDefault( precision ) || ( precision < 0 ) )
		precision = 3
	endif
	
	if ( !WaveExists( $wName ) )
		return NM2ErrorStr( 1, "wName", wName )
	endif
	
	if ( WaveType( $wName ) == 0 ) // text wave
	
		Wave /T wtext = $wName
		
		npnts = numpnts( wtext )
		
		for ( icnt = 0; icnt < npnts; icnt += 1 )
			
			strObj = wtext[icnt]
			
			if ( strlen( strObj ) > 0 )
				strList = AddListItem( strObj, strList, ";", inf )
			endif
			
		endfor
		
	else // numeric wave
	
		Wave wtemp = $wName
		
		npnts = numpnts( wtemp )
	
		for ( icnt = 0; icnt < npnts; icnt += 1 )
		
			if ( integer )
				numStr = num2istr( wtemp[ icnt ] )
			else
				sprintf numStr, "%." + num2istr( precision ) + "f", wtemp[ icnt ]
			endif
			
			strList = AddListItem( numStr, strList, ";", inf )
			
		endfor
	
	endif
	
	return strList

End // Wave2List

//****************************************************************
//****************************************************************

Function List2Wave( strList, wName [ numeric, overwrite ] ) // convert list items to wave items
	String strList // string list
	String wName // output wave name
	Variable numeric // ( 0 ) create text wave, default ( 1 ) create numeric wave
	Variable overwrite // ( 0 ) no ( 1 ) yes
	
	Variable icnt
	String item
	
	Variable items = ItemsInList( strList )
	
	if ( items == 0 )
		return 0 // nothing to do
	endif
	
	if ( strlen( wName ) == 0 )
		return NM2Error( 21, "wName", "" )
	endif
	
	if ( WaveExists( $wName ) && !overwrite )
		return NM2Error( 2, "wName", wName )
	endif
	
	wName = NMCheckStringName( wName )
	
	if ( numeric )
	
		Make /O/N=( items ) $wName
	
		Wave wtemp = $wName
		
		for ( icnt = 0; icnt < items; icnt += 1 )
			wtemp[icnt] = str2num( StringFromList( icnt, strList ) )
		endfor
	
	else
		
		Make /O/T/N=( items ) $wName
	
		Wave /T ttemp = $wName
		
		for ( icnt = 0; icnt < items; icnt += 1 )
			ttemp[icnt] = StringFromList( icnt, strList )
		endfor
	
	endif
	
	return 0

End // List2Wave

//****************************************************************
//****************************************************************

Function /S NMWaveNameError( wName [ STDV, SEM ] )
	String wName
	Variable STDV // look only for STDV waves
	Variable SEM // look only for SEM waves

	String errorName = ""
	String wName2 = NMChild( wName )
	String path = NMParent( wName )
	
	if ( ParamIsDefault( STDV ) && ParamIsDefault( SEM ) )
		STDV = 1
		SEM = 1
	endif
	
	if ( STDV )
	
		errorName = path + "STDV_" + wName2
		
		if ( WaveExists( $errorName ) )
			return errorName
		endif
		
		errorName = path + wName2 + "_STDV"
		
		if ( WaveExists( $errorName ) )
			return errorName
		endif
	
	endif
	
	if ( SEM )
	
		errorName = path + "SEM_" + wName2
		
		if ( WaveExists( $errorName ) )
			return errorName
		endif
		
		errorName = path + wName2 + "_SEM"
		
		if ( WaveExists( $errorName ) )
			return errorName
		endif
	
	endif
	
	return ""
			
End // NMWaveNameError

//****************************************************************
//****************************************************************

Function NMWaveNameErrorExists( wList )
	String wList
	
	Variable wcnt
	String wName, errorName
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
		
		wName = StringFromList( wcnt, wList )
		errorName = NMWaveNameError( wName )
		
		if ( WaveExists( $errorName ) )
			return 1
		endif
		
	endfor
	
	return 0
	
End // NMWaveNameErrorExists

//****************************************************************
//****************************************************************

Function NMShuffleWave( wName )
	String wName
	
	Variable icnt, jcnt, kcnt, npnts, hold
	
	if ( !WaveExists( $wName ) )
		return -1
	endif
	
	Wave wtemp = $wName
	
	npnts = numpnts( wtemp )
	
	for ( icnt = 0 ; icnt < npnts ; icnt += 1 )
	
		for ( jcnt = 0 ; jcnt < 20 ; jcnt += 1 )
		
			kcnt = floor( abs( enoise( npnts ) ) )
			
			if ( ( kcnt != icnt ) && ( kcnt >= 0 ) && ( kcnt < numpnts( wtemp ) ) )
				break
			endif
			
		endfor
		
		hold = wtemp[ icnt ]
		wtemp[ icnt ] = wtemp[ kcnt ]
		wtemp[ kcnt ] = hold
	
	endfor
	
	return 0
	
End // NMShuffleWave

//****************************************************************
//****************************************************************

Function NMShuffleWave2( wName )
	String wName
	
	Variable icnt, jcnt, kcnt, npnts, items
	String jstr, iList = "", iList2 = "", saveList
	
	if ( !WaveExists( $wName ) )
		return -1
	endif
	
	Wave wtemp = $wName
	
	for ( icnt = 0 ; icnt < numpnts( wtemp ) ; icnt += 1 )
		iList = AddListItem( num2str( wtemp[ icnt ] ), iList, ";", inf )
	endfor
	
	saveList = iList
	
	for ( icnt = 0 ; icnt < 1000 ; icnt += 1 )
	
		items = ItemsInList( iList )
		
		if ( items == 0 )
			break
		elseif ( items == 1 )
			kcnt = 0
		else
			kcnt = floor( abs( enoise( items ) ) )
		endif
		
		if ( ( kcnt >= 0 ) && ( kcnt < items ) )
				
			jstr = StringFromList( kcnt, iList )
			jcnt = str2num( jstr )
			
			iList = RemoveListItem( kcnt, iList )
			
			iList2 = AddListItem( jstr, iList2 )
		
		endif
	
	endfor
	
	print icnt, saveList, ilist2
	
	for ( icnt = 0 ; icnt < ItemsInList( iList2 ) ; icnt += 1 )
		if ( icnt < numpnts( wtemp ) )
			wtemp[ icnt ] = str2num( StringFromList( icnt, iList2 ) )
		endif
	endfor
	
	return 0
	
End // NMShuffleWave2

//****************************************************************
//
//	NextWaveItem()
//	find next occurence of number within a wave
//
//****************************************************************

Function NextWaveItem( wName, item, from, direction ) // find next item in wave
	String wName // wave name
	Variable item // item number to find
	Variable from // start point number
	Variable direction // +1 forward; -1 backward
	
	Variable wcnt, wlmt, next, found, npnts, inc = 1

	if ( NMUtilityWaveTest( wName ) < 0 )
		return from
	endif
	
	Wave tWave = $wName
	
	npnts = numpnts( tWave )
	
	if ( direction < 0 )
		next = from - 1
		inc = -1
		wlmt = next + 1
	else
		next = from + 1
		wlmt = npnts - from
	endif
	
	if ( ( next > npnts - 1 ) || ( next < 0 ) )
		return from // next out of bounds
	endif
	
	found = from
	
	for ( wcnt = 0; wcnt < wlmt; wcnt += 1 )
	
		if ( tWave[next] == item )
			found = next
			break
		endif
		
		next += inc
		
	endfor
	
	return found

End // NextWaveItem

//****************************************************************
//****************************************************************

Function /S WaveSequence( wName, seqStr, pntBgn, pntEnd, pntBlocks )
	String wName // wave name
	String seqStr // seq string "0;1;2;3;" or "0,3" or "0-3" for range
	Variable pntBgn // starting wave number
	Variable pntEnd // ending wave number
	Variable pntBlocks // number of blocks in each group
	
	Variable index, last, icnt, jcnt, iend
	
	if ( NMUtilityWaveTest( wName ) < 0 )
		return NM2ErrorStr( 1, "wName", wName )
	endif
	
	if ( ( strsearch( seqStr, ",", 0 ) > 0 ) || ( strsearch( seqStr, "-", 0 ) > 0 ) )
		seqStr = RangeToSequenceStr( seqStr )
	endif
	
	if ( ( numtype( pntBgn ) > 0 ) || ( pntBgn < 0 ) )
		pntBgn = 0
	endif
	
	if ( ( numtype( pntEnd ) > 0 ) || ( pntEnd >= numpnts( $wName ) ) )
		pntEnd = numpnts( $wName ) - 1
	endif
	
	if ( ( numtype( pntBlocks ) > 0 ) || ( pntBlocks <= 0 ) )
		pntBlocks = 1
	endif
	
	if ( ItemsInList( seqStr ) == 0 )
		return "" // nothing to do
	endif
	
	Wave wTemp = $wName
		
	index = pntBgn
	
	for ( icnt = pntBgn; icnt <= pntEnd; icnt += pntBlocks )
	
		if ( icnt >= numpnts( wTemp ) )
			break
		endif
	
		iend = icnt + pntBlocks - 1
		iend = min( iend, numpnts( wtemp ) - 1 )
		
		wTemp[ icnt, iend ] = str2num( StringFromList( jcnt,seqStr ) )
	
		jcnt += 1
	
		if ( jcnt >= ItemsInList( seqStr ) )
			jcnt = 0
		endif
		
	endfor
	
	return seqStr

End // WaveSequence

//****************************************************************
//****************************************************************

Function Time2Intervals( wName, xbgn, xend, minIntvl, maxIntvl ) // compute inter-event intervals
	String wName // wName of events
	Variable xbgn, xend // x-axis window begin and end, use ( -inf, inf ) for all
	Variable minIntvl // min allowed interval ( use 0 for no limit )
	Variable maxIntvl // max allowed interval ( use inf for no limit )
	
	Variable isi, ecnt, icnt, event, last
	String xl, yl, thisFxn = GetRTStackInfo( 1 )
	
	if ( NMUtilityWaveTest( wName ) < 0 )
		return NM2Error( 1, "wName", wName )
	endif
	
	if ( numtype( xbgn ) > 0 )
		xbgn = -inf
	endif
	
	if ( numtype( xend ) > 0 )
		xend = inf
	endif
	
	if ( ( numtype( minIntvl ) > 0 ) || ( minIntvl < 0 ) )
		minIntvl = 0
	endif
	
	if ( ( numtype( maxIntvl ) > 0 ) || ( maxIntvl <= 0 ) )
		maxIntvl = inf
	endif
	
	Wave wtemp = $wName

	Duplicate /O $wName U_INTVLS
	
	U_INTVLS = NaN
	
	for ( ecnt = 1; ecnt < numpnts( wtemp ); ecnt += 1 )
	
		last = wtemp[ecnt - 1]
		event = wtemp[ecnt]
		
		if ( ( numtype( last ) > 0 ) || ( numtype( event ) > 0 ) )
			continue
		endif
		
		if ( ( event >= xbgn ) && ( event <= xend ) && ( event >= last ) )
		
			isi = event - last
			
			if ( ( isi >= minIntvl ) && ( isi <= maxIntvl ) )
				U_INTVLS[ecnt] = isi
				icnt += 1
			endif
			
		endif
		
	endfor
	
	xl = NMNoteLabel( "x", wName, "" )
	yl = NMNoteLabel( "y", wName, "" )
	
	NMNoteType( "U_INTVLS", "NMIntervals", xl, yl, "_FXN_" )
	
	Note U_INTVLS, "Interval Source:" + wName
	
	return icnt

End // Time2Intervals

//****************************************************************
//****************************************************************

Function /S NMEventsToWaves( waveOfWaveNums, waveOfEvents, xwinBefore, xwinAfter, stopAtNextEvent, allowTruncatedEvents, chanNum, outputWavePrefix )
	String waveOfWaveNums // wave of wave numbers
	String waveOfEvents // wave of event times
	Variable xwinBefore, xwinAfter // copy x-scale window before and after event
	Variable stopAtNextEvent // ( < 0 ) no ( >= 0 ) yes... if greater than zero, use value to limit time before next event
	Variable allowTruncatedEvents // ( 0 ) no ( 1 ) yes
	Variable chanNum // channel number ( pass -1 for current )
	String outputWavePrefix // prefix name for new waves
	
	Variable icnt, xbgn, xend, npnts, event, eventNum = 0
	Variable wnum, continuous, dx, intvl, pbgn, pend
	String xl, yl, wName1, wName2, wName3, lastWave, nextWave, sourceStr1 = "", sourceStr2 = "", wList = ""
	String thisFxn = GetRTStackInfo( 1 )
	
	if ( NMUtilityWaveTest( waveOfWaveNums ) < 0 )
		return NM2ErrorStr( 1, "waveOfWaveNums", waveOfWaveNums )
	endif
	
	if ( NMUtilityWaveTest( waveOfEvents ) < 0 )
		return NM2ErrorStr( 1, "waveOfEvents", waveOfEvents )
	endif
	
	if ( numpnts( $waveOfWaveNums ) != numpnts( $waveOfEvents ) )
		return NM2ErrorStr( 5, "waveOfWaveNums", waveOfWaveNums )
	endif
	
	if ( ( numtype( xwinBefore ) > 0 ) || ( xwinBefore < 0 ) )
		return NM2ErrorStr( 10, "xwinBefore", num2str( xwinBefore ) )
	endif
	
	if ( ( numtype( xwinAfter ) > 0 ) || ( xwinAfter < 0 ) )
		return NM2ErrorStr( 10, "xwinAfter", num2str( xwinAfter ) )
	endif
	
	chanNum = ChanNumCheck( chanNum )
	
	if ( strlen( outputWavePrefix ) == 0 )
		return NM2ErrorStr( 21, "outputWavePrefix", "" )
	endif
	
	Wave recordNum = $waveOfWaveNums
	Wave eventTimes = $waveOfEvents
	
	npnts = numpnts( recordNum )
	
	outputWavePrefix = NMCheckStringName( outputWavePrefix )
	
	wName3 = outputWavePrefix + "Times"
	
	Make /O/N=( npnts ) $wName3 = NaN
	
	Wave st = $wName3
	
	for ( icnt = 0; icnt < npnts; icnt += 1 )
	
		wnum = recordNum[icnt]
		wName1 = NMChanWaveName( chanNum, wnum ) // source wave, raw data
		nextWave = NMChanWaveName( chanNum, wnum+1 )
		
		if ( wnum == 0 )
			lastWave = ""
		else
			lastWave = NMChanWaveName( chanNum, wnum-1 ) 
		endif
		
		continuous = 0
		
		if ( !WaveExists( $wName1 ) )
			continue
		endif
		
		xl = NMNoteLabel( "x", wName1, "" )
		yl = NMNoteLabel( "y", wName1, "" )
		
		event = eventTimes[icnt]
		
		intvl = NaN
		
		if ( ( icnt < npnts - 1 ) && ( recordNum[icnt] == recordNum[icnt+1] ) )
			intvl = eventTimes[icnt+1] - eventTimes[icnt]
		endif
		
		if ( numtype( event ) > 0 )
			continue
		endif
		
		xbgn = event - xwinBefore
		xend = event + xwinAfter
		
		if ( xbgn < leftx( $wName1 ) )
			if ( WaveExists( $lastWave ) && ( xbgn >= leftx( $lastWave ) ) && ( xbgn <= rightx( $lastWave ) ) ) // continuous
				continuous = 1
			elseif ( allowTruncatedEvents != 1 )
				NMHistory( "Event " + num2istr( icnt ) + " out of range on the left: " + wName1 )
				continue
			endif
		endif
		
		if ( xend > rightx( $wName1 ) )
			if ( WaveExists( $nextWave ) && ( xend >= leftx( $nextWave ) ) && ( xend <= rightx( $nextWave ) ) ) // continuous
				continuous = 2
			elseif ( allowTruncatedEvents != 1 )
				NMHistory( "Event " + num2istr( icnt ) + " out of range on the right: " + wName1 )
				continue
			endif
		endif
		
		wName2 = GetWaveName( outputWavePrefix + "_", chanNum, eventNum )
		
		dx = deltax( $wName1 )
		
		switch ( continuous )
		
			case 1:
			
				Duplicate /O/R=( xbgn,rightx( $lastWave ) ) $lastWave $( wName2 + "_last" )
				Duplicate /O/R=( leftx( $wName1 ),xend ) $wName1 $wName2
				
				Wave w1 = $( wName2 + "_last" )
				Wave w2 = $wName2
				
				Concatenate /KILL/NP/O {w1, w2}, U_EventConcat
				Duplicate /O U_EventConcat, $wName2
				KillWaves /Z U_EventConcat
				
				sourceStr1 = lastWave + ";Event Time:" + Num2StrLong( event, 3 ) + ";"
				sourceStr1 += "Event Xbgn:" + Num2StrLong( xbgn, 3 ) + ";Event Xend:" + Num2StrLong( rightx( $lastWave ), 3 ) + ";"
				
				sourceStr2 = wName1 + ";Event Time:" + Num2StrLong( event, 3 ) + ";"
				sourceStr2 += "Event Xbgn:" + Num2StrLong( leftx( $wName1 ), 3 ) + ";Event Xend:" + Num2StrLong( xend, 3 ) + ";"
				
				break
				
			case 2:
			
				Duplicate /O/R=( xbgn,rightx( $wName1 ) ) $wName1 $wName2
				Duplicate /O/R=( leftx( $nextWave ),xend ) $nextWave $( wName2 + "_next" )
				
				Wave w1 = $wName2
				Wave w2 = $( wName2 + "_next" )
				
				Concatenate /KILL/NP/O {w1, w2}, U_EventConcat
				Duplicate /O U_EventConcat, $wName2
				KillWaves /Z U_EventConcat
				
				sourceStr1 = "Event Source:" + wName1 + ";Event Time:" + Num2StrLong( event, 3 ) + ";"
				sourceStr1 += "Event Xbgn:" + Num2StrLong( xbgn, 3 ) + ";Event Xend:" + Num2StrLong( rightx( $wName1 ), 3 ) + ";"
				
				sourceStr2 = "Event Source:" + nextWave + ";Event Time:" + Num2StrLong( event, 3 ) + ";"
				sourceStr2 += "Event Xbgn:" + Num2StrLong( leftx( $nextWave ), 3 ) + ";Event Xend:" + Num2StrLong( xend, 3 ) + ";"
				
				break
				
			default:
			
				Duplicate /O/R=( xbgn, xend ) $wName1 $wName2
				
				sourceStr1 = "Event Source:" + wName1 + ";Event Time:" + Num2StrLong( event, 3 ) + ";"
				sourceStr1 += "Event Xbgn:" + Num2StrLong( xbgn, 3 ) + ";Event Xend:" + Num2StrLong( xend, 3 ) + ";"
			
		endswitch
		
		Setscale /P x 0, dx, $wName2
		
		if ( ( stopAtNextEvent >= 0 ) && ( numtype( intvl ) == 0 ) && ( xwinBefore + intvl - stopAtNextEvent < xend ) )
		
			Wave wtemp = $wName2
			
			xbgn = xwinBefore + intvl - stopAtNextEvent
			
			pbgn = x2pnt( wtemp, xbgn )
			pend = numpnts( wtemp ) - 1
			
			if ( ( pbgn >= 0 ) && ( pbgn < numpnts( wtemp ) ) )
				wtemp[ pbgn, pend ] = NaN
			endif
			
		endif
		
		NMNoteType( wName2, "NMEvent", xl, yl, "_FXN_" )
		
		if ( strlen( sourceStr1 ) > 0 )
			Note $wName2, sourceStr1
		endif
		
		if ( strlen( sourceStr2 ) > 0 )
			Note $wName2, sourceStr2
		endif
		
		st[ eventNum ] = event
		
		eventNum += 1
	
		wList = AddListItem( wName2, wList, ";", inf )
		
	endfor
	
	if ( eventNum == 0 ) 
		KillWaves /Z st
	else
		Redimension /N=( eventNum ) st
	endif
	
	NMPrefixAdd( outputWavePrefix + "_" )
	
	return wList

End // NMEventsToWaves

//****************************************************************
//****************************************************************

Function NMWaveOfPeriodicTimes( wName, interval, xbgn, xend )
	String wName // output wave name
	Variable interval
	Variable xbgn, xend // time of first and last event
	
	Variable npnts
	
	if ( strlen( wName ) == 0 )
		return NM2Error( 21, "wName", "" )
	endif
	
	if ( ( numtype( interval ) > 0 ) || ( interval <= 0 ) )
		return NM2Error( 10, "interval", num2str( interval ) )
	endif
	
	if ( numtype( xbgn ) > 0 )
		return NM2Error( 10, "xbgn", num2str( xbgn ) )
	endif
	
	if ( numtype( xend ) > 0 )
		return NM2Error( 10, "xend", num2str( xend ) )
	endif
	
	wName = NMCheckStringName( wName )
	
	npnts = 1 + ( xend - xbgn ) / interval
	
	Make /O/N=( npnts ) $wName = NaN
	Setscale /P x 0, 1, $wName
	
	Wave wtemp = $wName
	
	wtemp = x * interval
	
	wtemp += xbgn
	
	return 0
	
End // NMWaveOfPeriodicTimes

//****************************************************************
//
//	RenameWaves()
//	string replace name
//
//****************************************************************

Function /S RenameWaves(findStr, repStr, wList)
	String findStr // search string
	String repStr // replace string
	String wList // wave list (seperator ";")
	
	if (strlen(findStr) <= 0)
		return ""
	endif
	
	String wName, newName = "", outList = "", badList = wList
	Variable wcnt, first = 1, kill
	
	if (ItemsInList(wList) == 0)
		return ""
	endif
	
	for (wcnt = 0; wcnt < ItemsInList(wList); wcnt += 1)
	
		wName = StringFromList(wcnt, wList)
		
		newName = ReplaceString(wName,findStr,repStr)
		
		if (StringMatch(newName, wName) == 1)
			continue // no change
		endif
		
		if ((WaveExists($newName) == 1) && (first == 1))
			DoAlert 1, "Name Conflict: wave(s) already exist with new name. Do you want to over-write them?"
			first = 0
			if (V_Flag == 1)
				kill = 1
			endif
		endif
		
		if ((WaveExists($newName) == 1) && (kill == 1) && (first == 0))
			KillWaves /Z $newName
		endif
		
		if ((WaveExists($wName) == 0) || (WaveExists($newName) == 1))
			continue
		endif

		Rename $wName $newName
		
		outList = AddListItem(newName, outList, ";", inf)
		badList = RemoveFromList(wName, badList)
		
	endfor
	
	//NMUtilityAlert("RenameWaves", badList)
	
	return outList

End // RenameWaves

//****************************************************************
//****************************************************************

Function /S NMMatrixArithmeticMake( matrixName, numRows )
	String matrixName
	Variable numRows
	
	if ( strlen( matrixName ) == 0 )
		return ""
	endif
	
	matrixName = NMCheckStringName( matrixName )

	Make /O/T/N=( numRows, 4 ) $matrixName = ""
	
	SetDimLabel 1, 0, wName, $matrixName
	SetDimLabel 1, 1, op, $matrixName
	SetDimLabel 1, 2, factor, $matrixName
	SetDimLabel 1, 3, success, $matrixName
	
	return matrixName
	
End // NMMatrixArithmeticMake

//****************************************************************
//****************************************************************

Function /S NMMatrixArithmetic( matrixName [ xbgn, xend, xWave, history ] )
	String matrixName // name of matrix, a text wave with 4 columns
	Variable xbgn, xend
	String xWave // for xbgn and xend
	Variable history // print wave-by-wave scaling operations to history
	
	// column 1 is name of wave to scale
	// column 2 is operation ( "x" ... "/" ... "+" ... "-" ... "=" )
	// column 3 is either wave to scale by, or a scale factor
	// column 4 reports success or failure ( 1 or 0 )
	
	Variable icnt, numRows, factor, points = 1, pcnt, pbgn, pend, xflag, wavePntByPnt
	String wName, op, op2, factorStr, pointsStr
	String successList = "", paramList = "", paramList2
	
	if ( ParamIsDefault( xbgn ) || ( numtype( xbgn ) > 0 ) )
		xbgn = -inf
	endif
	
	if ( ParamIsDefault( xend ) || ( numtype( xend ) > 0 ) )
		xend = inf
	endif
	
	if ( ( numtype( xbgn ) == 1 ) && ( numtype( xend ) == 1 ) )
		points = 0
	endif
	
	if ( ( numtype( xbgn ) == 0 ) || ( numtype( xend ) == 0 ) )
		paramList += "xbgn=" + num2istr( xbgn ) + ";"
		paramList += "xend=" + num2istr( xend ) + ";"
	endif
	
	if ( ParamIsDefault( xWave ) )
		xWave = ""
	elseif ( WaveExists( $xWave ) )
		pbgn = NMX2Pnt( xWave, xbgn )
		pend = NMX2Pnt( xWave, xend )
		xflag = 1
		paramList += xWave + ";"
	endif
	
	if ( !WaveExists( $matrixName ) )
		return NM2ErrorStr( 1, "matrixName", matrixName )
	endif
	
	if ( WaveType( $matrixName, 1 ) != 2 )
		return NM2ErrorStr( 1, "matrixName", matrixName )
	endif
	
	Wave /T matrix = $matrixName
	
	if ( DimSize( matrix, 1 ) != 4 )
		return NM2ErrorStr( 5, "matrixName", matrixName )
	endif
	
	numRows = DimSize( matrix, 0 )
	
	for ( icnt = 0 ; icnt < numRows ; icnt += 1 )
	
		wName = matrix[ icnt ][ 0 ]
		
		matrix[ icnt ][ 3 ] = "0"
		
		if ( !WaveExists( $wName ) )
			continue // bad wave name
		endif
		
		Wave wtemp1 = $wName
		
		op = matrix[ icnt ][ 1 ]
		factorStr = matrix[ icnt ][ 2 ]
		
		if ( strlen( factorStr ) == 0 )
			continue
		endif
		
		wavePntByPnt = 0
		
		if ( WaveExists( $factorStr ) )
			
			Wave wtemp2 = $factorStr
			
			wavePntByPnt = 1
			
			if ( points )
			
				if ( !xflag )
					pbgn = x2pnt( wtemp1, xbgn )
					pend = x2pnt( wtemp1, xend )
				endif
				
				pbgn = max( pbgn, 0 )
				pend = min( pend, numpnts( wtemp1 ) - 1 )
			
				for ( pcnt = pbgn ; pcnt <= pend ; pcnt += 1 )
				
					strswitch( op )
						case "*":
						case "x":
							wtemp1[ pcnt ] *= wtemp2[ pcnt ]
							break
						case "/":
							wtemp1[ pcnt ] /= wtemp2[ pcnt ]
							break
						case "+":
							wtemp1[ pcnt ] += wtemp2[ pcnt ]
							break
						case "-":
							wtemp1[ pcnt ] -= wtemp2[ pcnt ]
							break
						case "=":
							wtemp1[ pcnt ] = wtemp2[ pcnt ]
							break
						default:
							continue
					endswitch
				
				endfor
			
			else
			
				strswitch( op )
					case "*":
					case "x":
						MatrixOp /O wtemp1 = wtemp1 * wtemp2
						break
					case "/":
						MatrixOp /O wtemp1 = wtemp1 / wtemp2
						break
					case "+":
						MatrixOp /O wtemp1 = wtemp1 + wtemp2
						break
					case "-":
						MatrixOp /O wtemp1 = wtemp1 - wtemp2
						break
					case "=":
						wtemp1 = wtemp2
						break
					default:
						continue
				endswitch
			
			endif
		
		else
		
			factor = str2num( factorStr )
			
			if ( ( numtype( factor ) == 2 ) && !StringMatch( factorStr, "NaN" ) )
				continue // unacceptable number
			endif
			
			if ( points )
			
				if ( !xflag )
					pbgn = x2pnt( wtemp1, xbgn )
					pend = x2pnt( wtemp1, xend )
				endif
				
				pbgn = max( pbgn, 0 )
				pend = min( pend, numpnts( wtemp1 ) - 1 )
			
				strswitch( op )
					case "*":
					case "x":
						wtemp1[ pbgn, pend ] *= factor
						break
					case "/":
						wtemp1[ pbgn, pend ] /= factor
						break
					case "+":
						wtemp1[ pbgn, pend ] += factor
						break
					case "-":
						wtemp1[ pbgn, pend ] -= factor
						break
					case "=":
						wtemp1[ pbgn, pend ] = factor
				endswitch
				
			else
			
				strswitch( op )
					case "*":
					case "x":
						MatrixOp /O wtemp1 = wtemp1 * factor
						break
					case "/":
						MatrixOp /O wtemp1 = wtemp1 / factor
						break
					case "+":
						MatrixOp /O wtemp1 = wtemp1 + factor
						break
					case "-":
						MatrixOp /O wtemp1 = wtemp1 - factor
						break
					case "=":
						wtemp1 = factor
						break
					default:
						continue
				endswitch
			
			endif
		
		endif
		
		matrix[ icnt ][ 3 ] = "1"
		
		successList += wName + ";"
			
		paramList2 = "op=" + op + ";factor=" + factorStr + ";" + paramList
		NMLoopWaveNote( wName, paramList2 )
		
		if ( history )
		
			if ( StringMatch( op, "=" ) )
				op2 = " " + op + " "
			else
				op2 = " " + op + "= "
			endif
			
			if ( points )
				pointsStr = "[" + num2istr( pbgn ) + "," + num2istr( pend ) + "]"
			else
				pointsStr = ""
			endif
			
			if ( wavePntByPnt )
				NMHistory( wName + pointsStr + op2 + factorStr + pointsStr )
			else
				NMHistory( wName + pointsStr + op2 + factorStr )
			endif
			
		endif
	
	endfor
	
	return successList
	
End // NMMatrixArithmetic

//****************************************************************
//****************************************************************
//
//	2D matrix functions defined below...
//
//****************************************************************
//****************************************************************

//****************************************************************
//
//	NMMatrixAvgRows
//	compute avg and stdv of a matrix wave along its rows; results stored in U_Avg and U_Sdv and U_Pnts
//
//****************************************************************

Function /S NMMatrixAvgRows( matrixName, ignoreNANs )
	String matrixName // name of 2D matrix wave
	Variable ignoreNANs // ignore NANs in computation ( 0 ) no ( 1 ) yes
	
	Variable nrows, ncols, lftx, dx
	
	Variable minNumOfDataPoints = NumVarOrDefault( "U_minNumOfDataPoints", 2 ) // min number of data points to include in average
	
	if ( !WaveExists( $matrixName ) )
		return NM2ErrorStr( 1, "matrixName", matrixName )
	endif
	
	nrows = DimSize( $matrixName, 0 )
	ncols = DimSize( $matrixName, 1 )
	lftx = DimOffset( $matrixName, 0 )
	dx = DimDelta( $matrixName, 0 )
	
	if ( ( nrows < 1 ) || ( ncols < 2 ) )
		return ""
	endif
	
	Duplicate /O $matrixName U_cMatrix
	
	MatrixOp /O U_iMatrix = U_cMatrix / U_cMatrix // creates matrix with 1's where there are data points
	
	if ( ignoreNANs )
		MatrixOp /O U_iMatrix = ReplaceNaNs( U_iMatrix, 0 )
		MatrixOp /O U_cMatrix = ReplaceNaNs( U_cMatrix, 0 )
	endif
	
	MatrixOp /O U_Pnts = sumRows( U_iMatrix )
	MatrixOp /O U_Pnts = U_Pnts * greater( U_Pnts, minNumOfDataPoints - 1 ) // reject rows with not enough data points
	
	MatrixOp /O U_Pnts = U_Pnts * ( U_Pnts / U_Pnts ) // converts 0's to NAN's
	
	MatrixOp /O U_Sum = sumRows( U_cMatrix )
	MatrixOp /O U_SumSqr = sumRows( powR( U_cMatrix, 2 ) )
	
	MatrixOp /O U_Sdv = sqrt( ( U_SumSqr - ( ( powR( U_Sum, 2 ) ) / U_Pnts ) ) / ( U_Pnts - 1 ) )
	MatrixOp /O U_Avg = U_Sum / U_Pnts
	
	Setscale /P x lftx, dx, U_Avg, U_Sdv, U_Pnts
	
	KillWaves /Z U_cMatrix, U_iMatrix, U_Sum, U_SumSqr
	
	return "U_Avg;U_Sdv;U_Pnts;"
	
End // NMMatrixAvgRows

//****************************************************************
//
//	NMMatrixSumRows
//	compute the sum of rows of a matrix wave; results stored in U_Sum and U_Pnts
//
//****************************************************************

Function /S NMMatrixSumRows( matrixName, ignoreNANs )
	String matrixName // name of 2D matrix wave
	Variable ignoreNANs // ignore NANs in computation ( 0 ) no ( 1 ) yes
	
	if ( !WaveExists( $matrixName ) )
		return NM2ErrorStr( 1, "matrixName", matrixName )
	endif
	
	Variable nrows = DimSize( $matrixName, 0 )
	Variable ncols = DimSize( $matrixName, 1 )
	
	Variable lftx = DimOffset( $matrixName, 0 )
	Variable dx = DimDelta( $matrixName, 0 )
	
	if ( ( nrows < 1 ) || ( ncols < 2 ) )
		return ""
	endif
	
	Duplicate /O $matrixName U_cMatrix
	
	MatrixOp /O U_iMatrix = U_cMatrix / U_cMatrix // creates matrix with 1's where there are data points
	
	if ( ignoreNANs )
		MatrixOp /O U_iMatrix = ReplaceNaNs( U_iMatrix, 0 )
		MatrixOp /O U_cMatrix = ReplaceNaNs( U_cMatrix, 0 )
	endif
	
	MatrixOp /O U_Sum = sumRows( U_cMatrix )
	MatrixOp /O U_Pnts = sumRows( U_iMatrix )
	
	Setscale /P x lftx, dx, U_Sum, U_Pnts
	
	KillWaves /Z U_cMatrix, U_iMatrix
	
	return "U_Sum;U_Pnts;"
	
End // NMMatrixSumRows

//****************************************************************
//
//	NMMatrixRow2Wave
//	copy row of 2D wave to a new 1D wave
//
//****************************************************************

Function NMMatrixRow2Wave( matrixName, outputWaveName, rowNum [ overwrite ] )
	String matrixName // 2D matrix wave name
	String outputWaveName // output wave name
	Variable rowNum // row number
	Variable overwrite
	
	Variable rows, cols
	
	if ( !WaveExists( $matrixName ) )
		return NM2Error( 1, "matrixName", matrixName )
	endif
	
	if ( strlen( outputWaveName ) == 0 )
		return NM2Error( 21, "outputWaveName", "" )
	endif
	
	if ( WaveExists( $outputWaveName ) )
		return NM2Error( 2, "outputWaveName", outputWaveName )
	endif

	rows = DimSize( $matrixName, 0 )
	cols = DimSize( $matrixName, 1 )
	
	if ( ( rowNum < 0 ) || ( rowNum >= rows ) )
		return -1
	endif
	
	if ( cols == 0 )
		return -1
	endif
	
	Wave m2D = $matrixName
	
	outputWaveName = NMCheckStringName( outputWaveName )
	
	if ( !overwrite && WaveExists( $outputWaveName ) )
		return NM2Error( 2, "outputWaveName", outputWaveName )
	endif
	
	MatrixOp /O $outputWaveName = row( m2D, rowNum )
	Redimension /N=( cols ) $outputWaveName
	Setscale /P x DimOffset( $matrixName, 1 ), DimDelta( $matrixName, 1 ), $outputWaveName
	
	return 0

End // NMMatrixRow2Wave

//****************************************************************
//
//	NMMatrixRows2Waves
//	copy rows of 2D wave to new 1D waves
//
//****************************************************************

Function /S NMMatrixRows2Waves( matrixName, outputWavePrefix [ chanNum, overwrite ] )
	String matrixName // 2D matrix wave name
	String outputWavePrefix // output wave prefix name
	Variable chanNum // for wave name
	Variable overwrite
	
	Variable rcnt, rows, cols, startx, dx
	String chanStr, wName, wList = ""
	String thisFxn = GetRTStackInfo( 1 )
	
	if ( !WaveExists( $matrixName ) )
		return NM2ErrorStr( 1, "matrixName", matrixName )
	endif
	
	if ( strlen( outputWavePrefix ) == 0 )
		return NM2ErrorStr( 21, "outputWavePrefix", "" )
	endif
	
	chanStr = ChanNum2Char( chanNum )

	rows = DimSize( $matrixName, 0 )
	cols = DimSize( $matrixName, 1 )
	
	if ( cols == 0 )
		return ""
	endif
	
	outputWavePrefix = NMCheckStringName( outputWavePrefix )
	
	for ( rcnt = 0 ; rcnt < rows ; rcnt += 1 )
	
		wName = outputWavePrefix + "_" + chanStr + num2istr( rcnt )
		
		if ( WaveExists( $wName ) )
			NMDoAlert( "Abort " + thisFxn + " : a wave with prefix " + NMQuotes( outputWavePrefix ) + " exists already : " + wName )
			return ""
		endif
		
	endfor
	
	Wave m2D = $matrixName
	
	startx = DimOffset( $matrixName, 1 )
	dx = DimDelta( $matrixName, 1 )
	
	for ( rcnt = 0 ; rcnt < rows ; rcnt += 1 )
	
		wName = outputWavePrefix + "_" + chanStr + num2istr( rcnt )
		
		if ( !overwrite && WaveExists( $wName ) )
			continue
		endif
		
		MatrixOp /O $wName = row( m2D, rcnt )
		Redimension /N=( cols ) $wName
		Setscale /P x startx, dx, $wName
		
		wList = AddListItem( wName, wList, ";", inf )
		
	endfor
	
	return wList

End // NMMatrixRows2Waves

//****************************************************************
//
//	NMMatrixColumn2Wave
//	copy column of 2D wave to a new 1D wave
//
//****************************************************************

Function NMMatrixColumn2Wave( matrixName, outputWaveName, columnNum [ overwrite ] )
	String matrixName // 2D matrix wave name
	String outputWaveName // output wave name
	Variable columnNum // column number
	Variable overwrite
	
	Variable columns
	
	if ( !WaveExists( $matrixName ) )
		return NM2Error( 1, "matrixName", matrixName )
	endif
	
	if ( strlen( outputWaveName ) == 0 )
		return NM2Error( 21, "outputWaveName", "" )
	endif
	
	if ( WaveExists( $outputWaveName ) )
		return NM2Error( 2, "outputWaveName", outputWaveName )
	endif

	columns = DimSize( $matrixName, 1 )
	
	if ( ( columnNum < 0 ) || ( columnNum >= columns ) )
		return -1
	endif
	
	Wave m2D = $matrixName
	
	outputWaveName = NMCheckStringName( outputWaveName )
	
	if ( !overwrite && WaveExists( $outputWaveName ) )
		return NM2Error( 2, "outputWaveName", outputWaveName )
	endif
	
	MatrixOp /O $outputWaveName = col( m2D, columnNum )
	
	Setscale /P x DimOffset( $matrixName, 0), DimDelta( $matrixName, 0), $outputWaveName
	
	return 0

End // NMMatrixColumn2Wave

//****************************************************************
//
//	NMMatrixColumns2Waves()
//	copy columns of 2D wave to new 1D waves
//
//****************************************************************

Function /S NMMatrixColumns2Waves( matrixName, outputWavePrefix [ chanNum, overwrite ] )
	String matrixName // 2D matrix wave name
	String outputWavePrefix // output wave prefix name
	Variable chanNum // for wave name
	Variable overwrite
	
	Variable ccnt, columns, startx, dx
	String chanStr, wName, wList = ""
	String thisFxn = GetRTStackInfo( 1 )
	
	if ( !WaveExists( $matrixName ) )
		return NM2ErrorStr( 1, "matrixName", matrixName )
	endif
	
	if ( strlen( outputWavePrefix ) == 0 )
		return NM2ErrorStr( 21, "outputWavePrefix", "" )
	endif
	
	chanStr = ChanNum2Char( chanNum )

	columns = DimSize( $matrixName, 1 )
	
	outputWavePrefix = NMCheckStringName( outputWavePrefix )
	
	for ( ccnt = 0 ; ccnt < columns ; ccnt += 1 )
	
		wName = outputWavePrefix + "_" + chanStr + num2istr( ccnt )
		wName = ReplaceString( "__", wName, "_" )
		
		if ( WaveExists( $wName ) )
			NMDoAlert( "Abort " + thisFxn + " : a wave with prefix " + NMQuotes( outputWavePrefix ) + " exists already : " + wName )
			return ""
		endif
		
	endfor
	
	Wave m2D = $matrixName
	
	startx = DimOffset( $matrixName, 0 )
	dx = DimDelta( $matrixName, 0 )
	
	for ( ccnt = 0 ; ccnt < columns ; ccnt += 1 )
	
		wName = outputWavePrefix + "_" + chanStr + num2istr( ccnt )
		
		if ( !overwrite && WaveExists( $wName ) )
			continue
		endif
		
		MatrixOp /O $wName = col( m2D, ccnt )
	
		Setscale /P x startx, dx, $wName
		
		wList = AddListItem( wName, wList, ";", inf )
		
	endfor
	
	return wList

End // NMMatrixColumns2Waves

//****************************************************************
//****************************************************************
//
//	Window Functions
//
//****************************************************************
//****************************************************************

Function /S CheckGraphName( gName ) // check graph name is correct format
	String gName
	
	Variable icnt
	
	for ( icnt = 0; icnt < strlen( gName ); icnt += 1 )
	
		strswitch( gName[icnt,icnt] )
			case ":":
			case ";":
			case ",":
			case ".":
			case " ":
				gName[icnt,icnt] = "_"
		endswitch
	endfor
	
	return gName[0,30]

End // CheckGraphName

//****************************************************************
//****************************************************************

Function GraphRainbow( gName, wList ) // change color of waves to raindow
	String gName // graph name
	String wList // wave list or "_ALL_" for all waves in the graph
	
	Variable wcnt
	String wName
	
	STRUCT NMRGB c
	
	if ( Wintype( gName ) != 1 )
		return NM2Error( 40, "gName", gName )
	endif
	
	if ( StringMatch( wList, "_ALL_" ) || ( ItemsInList( wList ) == 0 ) )
		wList = TraceNameList( gName, ";", 1 )
	endif

	for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		NMRGBrainbow( wcnt, c )
		
		ModifyGraph /W=$gName rgb( $wName )=(c.r,c.g,c.b)
		
	endfor
	
End // GraphRaindow

//****************************************************************
//****************************************************************

Function PrintMarqueeCoords() //: GraphMarquee

	GetMarquee /K left, bottom
	
	if ( V_Flag == 0 )
		Print "There is no marquee"
	else
		printf "marquee left : %g" + NMCR, V_left
		printf "marquee right: %g" + NMCR, V_right
		printf "marquee top: %g" + NMCR, V_top
		printf "marquee bottom: %g" + NMCR, V_bottom
	endif
	
End // PrintMarqueeCoords

//****************************************************************
//****************************************************************
//
//	String Functions
//
//****************************************************************
//****************************************************************

Function /S NMAddToList( itemOrListStr, listStr, listSepStr ) // add to list only if it is not in the list
	String itemOrListStr, listStr, listSepStr
	
	Variable icnt, items
	String itemStr = ""
	
	if ( strlen( itemOrListStr ) == 0 )
		return listStr
	endif
	
	strswitch( listSepStr )
		case ";":
		case ",":
			break
		default:
			return listStr
	endswitch
	
	items = ItemsInList( itemOrListStr, listSepStr )
	
	for ( icnt = 0 ; icnt < items ; icnt += 1 )
	
		itemStr = StringFromList( icnt, itemOrListStr, listSepStr )
		
		if ( WhichListItem( itemStr, listStr, listSepStr ) < 0 )
			listStr += itemStr + listSepStr
		endif
		
	endfor
	
	return listStr

End // NMAddToList

//****************************************************************
//****************************************************************

Function /S NMAndLists( listStr1, listStr2, listSepStr )
	String listStr1, listStr2, listSepStr
	
	Variable icnt, items
	String itemStr, andList = ""
	
	items = ItemsInList( listStr1, listSepStr )
	
	for ( icnt = 0 ; icnt < items ; icnt += 1 )
	
		itemStr = StringFromList( icnt, listStr1, listSepStr )
		
		if ( WhichListItem( itemStr, listStr2, listSepStr ) >= 0 )
			andList += itemStr + listSepStr
		endif
		
	endfor
	
	return andList

End // NMAndLists

//****************************************************************
//****************************************************************

Function /S NMStrSearchList( listStr, findThisStr [ start, options ] )
	String listStr // e.g. "recordA0;recordA1;test1;test2;"
	String findThisStr // e.g. "record"
	Variable start, options // see strsearch
	
	Variable icnt, found
	String itemStr, itemOutputList = ""
	
	for ( icnt = 0 ; icnt < ItemsInList( listStr ) ; icnt += 1 )
	
		itemStr = StringFromList( icnt, listStr )
		
		found = strsearch( itemStr, findThisStr, start, options )
		
		if ( found >= 0 )
			itemOutputList += itemStr + ";"
		endif
		
	endfor

	return itemOutputList
	
End // NMStrSearchList

//****************************************************************
//****************************************************************

Function /S NMUtilityWaveListShort( wList ) // convert wave list to short format
	String wList
	
	Variable wcnt
	String prefix, wName, wNameNew, tempList = "", foundList = "", oList = ""
	
	if ( ItemsInList( wList ) <= 1 )
		return wList // not enough waves
	endif
	
	prefix = FindCommonPrefix( wList )
	
	if ( strlen( prefix ) == 0 )
		return wList
	endif
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
	
		wName = StringFromList( wcnt, wList )
		
		if ( strsearch( wName, prefix, 0, 2 ) == 0 )
		
			foundList = AddListItem( wName, foundList, ";", inf )
			wNameNew = ReplaceString( prefix, wName, "" )
			
			if ( strlen( wNameNew ) > 0 )
				tempList = AddListItem( wNameNew, tempList, ";", inf )
			endif
			
		endif
	
	endfor
	
	if ( ItemsInList( tempList ) == 0 )
	
		oList = prefix + ";"
		
	elseif ( ItemsInList( tempList ) >= 1 )
	
		tempList = SequenceToRangeStr( tempList, "-" )
		
		oList = AddListItem( prefix + "," + ReplaceString( ";", tempList, "," ), oList, ";", inf )
	
	endif
	
	return ReplaceString( ",;", oList, ";" ) + RemoveFromList( foundList, wList )
	
End // NMUtilityWaveListShort

//****************************************************************
//****************************************************************

Function /S NMFindMissingSeqNums( wList [ firstNum, lastNum, seqStep ] )
	String wList // list of names with ending sequence numbers ( e.g. "RecordA1;RecordA3;RecordA6;" )
	Variable firstNum // first number of sequence, pass nothing for do not care
	Variable lastNum // last number of sequence, pass nothing for do not care
	Variable seqStep // sequence step, default 1

	Variable wcnt, icnt, seq1, seq2, seqMax, numWaves, found
	String wName1, wName2, seqStr = ""
	
	numWaves = ItemsInList( wList ) 
	
	if ( numWaves <= 1 )
		return ""
	endif
	
	if ( ParamIsDefault( firstNum ) || ( firstNum < 0 ) )
		firstNum = NaN
	endif
	
	if ( ParamIsDefault( seqStep ) )
		seqStep = 1
	endif
	
	if ( ( numtype( seqStep ) > 0 ) || ( seqStep <= 0 ) )
		return NM2ErrorStr( 10, "seqStep", num2istr( seqStep ) )
	endif
	
	if ( ParamIsDefault( lastNum ) || ( lastNum < 0 ) )
		lastNum = NaN
	endif
	
	wName1 = StringFromList( 0, wList )
		
	seq1 = GetSeqNum( wName1 )
	seqMax = seq1
	
	if ( numtype( firstNum ) > 0 )
	
		firstNum = seq1
	
	elseif ( seq1 > firstNum )
	
		found = 1
	
		for ( icnt = firstNum ; icnt < seq1 ; icnt += seqStep )
			seqStr += num2str( icnt ) + ";"
		endfor
	
	endif
	
	for ( wcnt = 0 ; wcnt < numWaves - 1 ; wcnt += 1 )
	
		wName1 = StringFromList( wcnt, wList )
		
		seq1 = GetSeqNum( wName1 )
		seqMax = max( seq1, seqMax )
		
		wName2 = StringFromList( wcnt + 1, wList )
		
		seq2 = GetSeqNum( wName2 )
		seqMax = max( seq2, seqMax )
		
		if ( seq2 < seq1 )
			continue
		endif
		
		if ( seq2 - seq1 != seqStep )
		
			found = 1
		
			for ( icnt = seq1 + seqStep ; icnt < seq2 ; icnt += seqStep )	
				seqStr += num2str( icnt ) + ";"
			endfor
			
		endif
	
	endfor
	
	if ( ( numtype( lastNum ) == 0 ) && ( seqMax < lastNum ) )
	
		found = 1
	
		for ( icnt = firstNum ; icnt <= lastNum ; icnt += seqStep )
		
			if ( icnt > seqMax )
				seqStr += num2str( icnt ) + ";"
			endif
		
		endfor
	
	endif

	return seqStr

End // NMFindMissingSeqNum

//****************************************************************
//****************************************************************

Function /S RangeToSequenceStr( rangeStr )
	String rangeStr // e.g. "0,3" or "0-3"
	
	Variable first, last, icnt
	String seqStr = ""
	
	if ( strsearch( rangeStr, ",", 0 ) > 0 )
		// nothing to do
	elseif ( strsearch( rangeStr, "-", 0 ) > 0 )
		rangeStr = ReplaceString( "-", rangeStr, "," )
	else
		return "" // unrecognized seperator
	endif
	
	if ( ItemsInList( rangeStr, "," ) != 2 )
		return "" // bad range
	endif
	
	first = str2num( StringFromList( 0, rangeStr, "," ) )
	
	if ( numtype( first ) > 0 )
		return ""
	endif
	
	last = str2num( StringFromList( 1, rangeStr, "," ) )
	
	if ( numtype( last ) > 0 )
		return ""
	endif
	
	for ( icnt = first; icnt <= last; icnt += 1 )
		seqStr += num2istr( icnt ) + ";"
	endfor
		
	return seqStr // e.g. "0;1;2;3;"
	
End // RangeToSequenceStr

//****************************************************************
//****************************************************************

Function /S SequenceToRangeStr( seqList, seperator )
	String seqList // e.g. "0;1;2;3;5;6;7;"
	String seperator // "-" or ","
	
	Variable icnt, items, seqNum, first = NaN, last, next, foundRange
	String range, rangeList = ""
	
	items = ItemsInList( seqList )
	
	for ( icnt = 0 ; icnt < items ; icnt += 1 )
		
		seqNum = str2num( StringFromList( icnt, seqList ) )
		
		if ( numtype( seqNum ) > 0 )
			return seqList // error
		endif
		
		if ( numtype( first ) > 0 )
		
			first = seqNum
			next = first + 1
			foundRange = 0
			
		else
			
			if ( seqNum == next )
			
				next += 1
				foundRange = 1
				last = seqNum
				
				if ( icnt < items - 1 )
					continue
				endif
				
			endif
			
			if ( foundRange && ( last > first + 1 ) )
				
				range = num2str( first ) + seperator + num2str( last )
				rangeList += range + ";"
				
			else
			
				rangeList += num2str( first ) + ";"
				
				if ( last != first )
					rangeList += num2str( last ) + ";"
				endif
				
			endif
			
			if ( ( seqNum != last ) && ( icnt == items - 1 ) )
				rangeList += num2str( seqNum ) + ";"
			endif
			
			first = seqNum
			next = first + 1
			foundRange = 0
			
		endif
		
		last = seqNum
	
	endfor
		
	return rangeList // e.g. "0-3;5-7;"
	
End // SequenceToRangeStr

//****************************************************************
//****************************************************************

Function /S  NMReplaceStringList( inStr, replaceThisStr_withThisStr_List ) // see ReplaceString function
	String inStr
	String replaceThisStr_withThisStr_List // e.g. "_ChA,_A;_ChB,_B;_Trial-,;"
	// semicolon list of replaceThisStr, withThisStr
	
	Variable icnt
	String itemstr, replaceThisStr, withThisStr

	if ( ItemsInList( replaceThisStr_withThisStr_List, ";" ) == 0 )
		return inStr
	endif
		
	for ( icnt = 0 ; icnt < ItemsInList( replaceThisStr_withThisStr_List, ";" ) ; icnt += 1 )
	
		itemstr = StringFromList( icnt, replaceThisStr_withThisStr_List, ";" )
		replaceThisStr = StringFromList( 0, itemstr, "," )
		withThisStr = StringFromList( 1, itemstr, "," )
		
		if ( strlen( replaceThisStr ) > 0 )
			inStr = ReplaceString( replaceThisStr, inStr, withThisStr )
		endif
		
	endfor
	
	return inStr
		
End //  NMReplaceStringList

//****************************************************************
//****************************************************************

Function /S NMCheckStringName( strName )
	String strName
	
	Variable beLiberal = 0
	Variable maxChar = 31 // 31 or 255
	
	if ( strlen( strName ) == 0 )
		return ""
	endif
	
	if ( IgorVersion() >= 8 )
		maxChar = 255
	endif
	
	strName = ReplaceString( "__", strName, "_" )
	strName = ReplaceString( "__", strName, "_" )
	strName = ReplaceString( "__", strName, "_" )
	
	strName = RemoveEnding( strName , "_" )
	
	strName = CleanupName( strName, beLiberal )
	
	return strName[ 0, maxChar - 1 ]

End // NMCheckStringName

//****************************************************************
//****************************************************************

Function /S NMCheckWaveNameChanTrial( wName )
	String wName // wave name containing special characters "PREFIX#" and/or "CH" with "TRIAL" to denote wave prefix, channel number/letter and trial number
	
	// PREFIX# is a special flag to tell NM the following # characters denote the wave prefix (#=0-9)
	// CH is a special flag to tell NM the following character denotes a channel number or letter
	// TRIAL is a special flag to tell NM the following number denotes a trial number
	// This helps NM to convert to appropriate wave name, e.g. RecordA0, A1, A2... RecordB0, B1, B2...
	
	Variable i0, i1, j0, j1, kcnt, testNum, chanNum, trialNum, foundChar, numChars
	String rstr, prefix, chanStr, trialStr = "", wName2 = wName
	
	if ( strlen( wName ) == 0 )
		return ""
	endif
	
	i0 = strsearch( wName, "PREFIX", 0 )
	
	if ( i0 >= 0 )
		
		numChars = str2num( wName[ i0 + 6, i0 + 6 ] )
		
		if ( ( numtype( numChars ) == 0 ) && ( numChars >= 0 ) && ( numChars <= 9 ) )
		
			rstr = wName[ i0, i0 + 7 + numChars - 1 ]
			prefix = wName[ i0 + 7, i0 + 7 + numChars - 1 ]
			
			wName2 = ReplaceString( rstr, wName2, "" )
			wName2 = prefix + wName2
		
		endif
	
	endif
	
	i0 = strsearch( wName, "CH", 0 )
	j0 = strsearch( wName, "TRIAL", 0 )
	
	if ( ( i0 >= 0 ) && ( j0 >= 0 ) )
	
		chanStr = wName[ i0 + 2, i0 + 2 ]
		chanNum = str2num( chanStr )
		
		if ( numtype( chanNum ) == 0 )
			chanStr = ChanNum2Char( chanNum )
		endif
		
		for ( kcnt = j0 + 5 ; kcnt < strlen( wName2 ) ; kcnt += 1 )
		
			testNum = str2num( wName[ kcnt, kcnt ] )
		
			if ( numtype( testNum ) > 0 )
				foundChar = 1
				j1 = kcnt - 1
				break
			endif
			
		endfor
		
		if ( !foundChar )
			j1 = strlen( wName2 ) - 1
		endif
		
		trialStr = wName[ j0 + 5, j1 ]
		
		if ( numtype( str2num( trialStr ) ) > 0 )
			return wName2
		endif
		
		rstr = wName[ i0, i0 + 2 ]
		wName2 = ReplaceString( rstr, wName2, "" )
		rstr = wName[ j0, j1 ]
		wName2 = ReplaceString( rstr, wName2, "" )
		
		wName2 += chanStr + trialStr
	
	endif
	
	return wName2

End // NMCheckWaveNameChanTrial

//****************************************************************
//****************************************************************

Function /S Num2StrLong( num, decimals )
	Variable num, decimals
	
	String ttl
	
	sprintf ttl, "%." + num2str( decimals ) + "f", num
	
	return ttl
	
End // Num2StrLong

//****************************************************************
//****************************************************************

Function /S StringAddToEnd( str, str2add ) // add string to end, if it does not exist already
	String str
	String str2add
	
	Variable slen = strlen( str )
	Variable alen = strlen( str2add )
	
	if ( !StringMatch( str2add, str[ slen - alen , slen - 1 ] ) )
		return str + str2add
	endif
	
	return str
	
End // StringAddToEnd

//****************************************************************
//****************************************************************

Function /S NMQuotes( istring )
	String istring

	return "\"" + istring + "\"" // add string quotes "" around string

End // NMQuotes

//****************************************************************
//****************************************************************

Function /S FindCommonPrefix( wList )
	String wList
	
	Variable icnt, jcnt, thesame
	String wname, wname2, prefix = ""
	
	wname = StringFromList( 0, wList )
	
	for ( icnt = 0 ; icnt < strlen( wname ) ; icnt += 1 )
	
		thesame = 1
		
		for ( jcnt = 1 ; jcnt < ItemsInList( wList ) ; jcnt += 1 )
		
			wname2 = StringFromList( jcnt, wList )
			
			if ( !StringMatch( wname[icnt, icnt], wname2[icnt,icnt] ) )
				return prefix
			endif
		
		endfor
		
		prefix += wname[icnt, icnt]
	
	endfor
	
	return prefix
	
End // FindCommonPrefix

//****************************************************************
//****************************************************************

Function GetSeqNum( strWithSeqNum ) // find sequence number of wave name
	String strWithSeqNum
	
	Variable icnt, ibeg, iend, found, seqnum = NaN
	
	for ( icnt = strlen( strWithSeqNum )-1; icnt >= 0; icnt -= 1 )
		if ( numtype( str2num( strWithSeqNum[icnt] ) ) == 0 )
			found = 1
			break // first appearance of number, from right
		endif
	endfor
	
	if ( !found )
		return NaN
	endif
	
	iend = icnt
	found = 0
	
	for ( icnt = iend; icnt >= 0; icnt -= 1 )
		if ( numtype( str2num( strWithSeqNum[icnt] ) ) == 2 )
			found = 1
			break // last appearance of number, from right
		endif
	endfor
	
	if ( !found )
		return NaN
	endif
	
	ibeg = icnt+1
	
	seqnum = str2num( strWithSeqNum[ibeg, iend] )
	
	return seqnum

End // GetSeqNum

//****************************************************************
//****************************************************************

Function GetNumFromStr( str, findStr ) // find number following a string value
	String str // string to search
	String findStr // string to find ( e.g. "marker( x )=" or "Group:" )
	
	Variable icnt, ibgn
	
	str = ReplaceString( " ", str, "" ) // remove spaces
	
	ibgn = strsearch( str, findStr, 0 )
	
	if ( ibgn < 0 )
		return NaN
	endif
	
	ibgn += strlen( findStr )
	
	for ( icnt = ibgn+1; icnt < strlen( str ); icnt += 1 )
		if ( numtype( str2num( str[icnt] ) ) > 0 )
			break
		endif
	endfor
	
	return str2num( str[ibgn,icnt-1] )

End // GetNumFromStr

//****************************************************************
//
//	UnitsFromStr()
//	find units string from label string
//	units should be in parenthesis, e.g. "Vmem ( mV )"
//	or seperated by space, e.g. "Vmem mV"
//
//****************************************************************

Function /S UnitsFromStr( str )
	String str // string to search
	
	Variable icnt, jcnt
	
	str = UnPadString( str, 0x20 ) // remove trailing spaces if they exist
	
	for ( icnt = strlen( str )-1; icnt >= 0; icnt -= 1 )
	
		if ( StringMatch( str[icnt], ")" ) )
		
			for ( jcnt = icnt-1; jcnt >= 0; jcnt -= 1 )
				if ( StringMatch( str[jcnt, jcnt], "(" ) )
					return str[jcnt+1, icnt-1]
				endif
			endfor
			
		endif
		
	endfor
	
	for ( icnt = strlen( str )-1; icnt >= 0; icnt -= 1 )
		
		strswitch( str[icnt, icnt] )
			case " ":
			case ":":
				return str[icnt+1, inf]
		endswitch
		
	endfor
	
	return str
	
End // UnitsFromStr

//****************************************************************
//****************************************************************

Function /S OhmsUnitsFromStr( str ) // find units string from axis label string
	String str // string to search
	
	return CheckOhmsUnits( UnitsFromStr( str ) )
	
End // OhmsUnitsFromStr

//****************************************************************
//****************************************************************

Function /S CheckOhmsUnits( units )
	String units
	
	units = UnPadString( units, 0x20 ) // remove trailing spaces if they exist
	
	strswitch( units )
		case "V":
		case "mV":
		case "A":
		case "nA":
		case "pA":
		case "S":
		case "nS":
		case "pS":
		case "Ohms":
		case "MOhms":
		case "MegaOhms":
		case "GOhms":
		case "GigaOhms":
		case "sec":
		case "msec":
		case "ms":
		case "usec":
		case "us":
			break
		default:
			units = ""
	endswitch
	
	return units

End // CheckOhmsUnits

//****************************************************************
//****************************************************************

Function /S NMTimeUnitsCheck( units )
	String units
	
	strswitch( units )
		case "s":
		case "sec":
		case "seconds":
		case "ms":
		case "msec":
		case "milliseconds":
		case "us":
		case "usec":
		case "microseconds":
		case "ns":
		case "nsec":
		case "nanoseconds":
			return units
	endswitch
	
	return ""
	
End // NMTimeUnitsCheck

//****************************************************************
//****************************************************************

Function /S NMTimeUnitsStandard( units )
	String units

	strswitch( units )
		case "s":
		case "sec":
		case "seconds":
			return "sec"
		case "ms":
		case "msec":
		case "milliseconds":
			return "msec"
		case "us":
		case "usec":
		case "microseconds":
			return "usec"
		case "ns":
		case "nsec":
		case "nanoseconds":
			return "nsec"
	endswitch
	
	return ""

End // NMTimeUnitsStandard

//****************************************************************
//****************************************************************

Function /S NMTimeUnitsListStandard( unitsList )
	String unitsList
	
	Variable icnt
	String units, returnList = ""
	
	for ( icnt = 0 ; icnt < ItemsInList( unitsList ) ; icnt += 1 )
	
		units = StringFromList( icnt, unitsList )
		
		returnList = NMAddToList( NMTimeUnitsStandard( units ), returnList, ";" )
		
	endfor
	
	return returnList
	
End // NMTimeUnitsListStandard

//****************************************************************
//****************************************************************

Function NMTimeUnitsConvertScale( oldUnits, newUnits )
	String oldUnits // e.g. "sec"
	String newUnits // e.g. "msec"
		
	strswitch( oldunits )
	
		case "s":
		case "sec":
		case "seconds":
		
			strswitch( newUnits )
				case "s":
				case "sec":
				case "seconds":
					return 1
				case "ms":
				case "msec":
				case "milliseconds":
					return 1e3
				case "us":
				case "usec":
				case "microseconds":
					return 1e6
				case "ns":
				case "nsec":
				case "nanoseconds":
					return 1e9
			endswitch
			
			return NaN
		
		case "ms":
		case "msec":
		case "milliseconds":
		
			strswitch( newUnits )
				case "s":
				case "sec":
				case "seconds":
					return 1e-3
				case "ms":
				case "msec":
				case "milliseconds":
					return 1
				case "us":
				case "usec":
				case "microseconds":
					return 1e3
				case "ns":
				case "nsec":
				case "nanoseconds":
					return 1e6
			endswitch
			
			return NaN
			
		case "us":
		case "usec":
		case "microseconds":
		
			strswitch( newUnits )
				case "s":
				case "sec":
				case "seconds":
					return 1e-6
				case "ms":
				case "msec":
				case "milliseconds":
					return 1e-3
				case "us":
				case "usec":
				case "microseconds":
					return 1
				case "ns":
				case "nsec":
				case "nanoseconds":
					return 1e3
			endswitch
			
			return NaN
			
		case "ns":
		case "nsec":
		case "nanoseconds":
		
			strswitch( newUnits )
				case "s":
				case "sec":
				case "seconds":
					return 1e-9
				case "ms":
				case "msec":
				case "milliseconds":
					return 1e-6
				case "us":
				case "usec":
				case "microseconds":
					return 1e-3
				case "ns":
				case "nsec":
				case "nanoseconds":
					return 1
			endswitch
			
			return NaN
			
		default:
		
			return NaN
			
	endswitch
	
End // NMTimeUnitsConvertScale

//****************************************************************
//****************************************************************

Function /S NMReverseList( listStr, listSepStr )
	String listStr, listSepStr
	
	Variable icnt
	String item, returnList = ""
	
	for ( icnt = ItemsInList( listStr, listSepStr )-1; icnt >= 0 ; icnt -= 1 )
		item = StringFromList( icnt, listStr, listSepStr )
		returnList = AddListItem( item, returnList, listSepStr, inf )
	endfor

	return returnList

End // NMReverseList

//****************************************************************
//****************************************************************

Function /S NMAddPathNamePrefix( wName, prefix )
	String wName
	String prefix
	
	if ( strlen( prefix ) == 0 )
		return wName
	endif
	
	String path = NMParent( wName )
	String wName2 = NMChild( wName )
	String lastCharacter = wName[ strlen( wName ) - 1 ]
	
	if ( !StringMatch( lastCharacter, ":" ) )
		lastCharacter = ""
	endif
	
	return path + prefix + wName2 + lastCharacter
	
End // NMAddPathNamePrefix

//****************************************************************
//****************************************************************

Function /S NMChild( pList [ noDuplications ] )
	String pList // list of paths, e.g. "root:nmFolder0:RecordA0;root:nmFolder1:RecordA8;"
	Variable noDuplications // no duplication names in return list
	
	Variable icnt, numPaths, noList
	String path, returnList = "", listSepStr = ""
	
	if ( strsearch( pList, ";", 0 ) >= 0 )
		listSepStr = ";"
	elseif ( strsearch( pList, ",", 0 ) >= 0 )
		listSepStr = ","
	else
		return ParseFilePath( 0, pList, ":", 1, 0 )
	endif
	
	numPaths = ItemsInList( pList, listSepStr )
	
	if ( numPaths == 1 )
	
		path = StringFromList( 0, pList, listSepStr )
		
		return ParseFilePath( 0, path, ":", 1, 0 )
		
	endif
	
	for ( icnt = 0 ; icnt < numPaths ; icnt += 1 )
		
		path = StringFromList( icnt, pList, listSepStr )
		path = ParseFilePath( 0, path, ":", 1, 0 )
		
		if ( strlen( path ) == 0 )
			continue
		endif
		
		if ( noDuplications )
			returnList = NMAddToList( path, returnList, listSepStr )
		else
			returnList += path + listSepStr
		endif
		
	endfor
	
	if ( ItemsInList( returnList ) == 0 )
		return ""
	elseif ( ItemsInList( returnList ) == 1 )
		return StringFromList( 0, returnList )
	else
		return returnList // e.g. "RecordA0;RecordA8;"
	endif
	
End // NMChild

//****************************************************************
//****************************************************************

Function /S NMParent( pList [ noDuplications, noPath ] )
	String pList // list of paths, e.g. "root:nmFolder0:RecordA0;root:nmFolder1:RecordA8;"
	Variable noDuplications // no duplication names in return list
	Variable noPath
	
	Variable icnt, numPaths, noList
	String path, returnList = "", listSepStr = ""
	
	if ( strsearch( pList, ";", 0 ) >= 0 )
		listSepStr = ";"
	elseif ( strsearch( pList, ",", 0 ) >= 0 )
		listSepStr = ","
	else
		if ( noPath )
			return ParseFilePath( 0, pList, ":", 1, 1 )
		else
			return ParseFilePath( 1, pList, ":", 1, 0 )
		endif
	endif
	
	numPaths = ItemsInList( pList, listSepStr )
	
	if ( numPaths == 1 )
	
		path = StringFromList( 0, pList, listSepStr )
		
		if ( noPath )
			return ParseFilePath( 0, path, ":", 1, 1 )
		else
			return ParseFilePath( 1, path, ":", 1, 0 )
		endif
		
	endif
	
	for ( icnt = 0 ; icnt < numPaths ; icnt += 1 )
		
		path = StringFromList( icnt, pList, listSepStr )
		
		if ( noPath )
			path = ParseFilePath( 0, path, ":", 1, 1 )
		else
			path = ParseFilePath( 1, path, ":", 1, 0 )
		endif
		
		if ( strlen( path ) == 0 )
			continue
		endif
		
		if ( noDuplications )
			returnList = NMAddToList( path, returnList, listSepStr )
		else
			returnList += path + listSepStr
		endif
		
	endfor
	
	if ( ItemsInList( returnList ) == 0 )
		return ""
	elseif ( ItemsInList( returnList ) == 1 )
		return StringFromList( 0, returnList )
	else
		return returnList // e.g. "root:nmFolder0;root:nmFolder1;"
	endif
	
End // NMParent

//****************************************************************
//****************************************************************

Function /S LastPathColon( fullpath, yes )
	String fullpath
	Variable yes // check path (0) has no trailing colon ( 1 ) has trailing colon
	
	if ( yes == 1 )
		return ParseFilePath( 2, fullpath, ":", 0, 0 )
	else
		return RemoveEnding( fullpath, ":" )
	endif

End // LastPathColon

//****************************************************************
//****************************************************************

Function /S NMCheckFullPath( path )
	String path
	
	if ( !StringMatch( path[0,4], "root:" ) )
		path = "root:" + path
	endif
	
	return ParseFilePath( 2, path, ":", 0, 0 )
	
End // NMCheckFullPath

//****************************************************************
//****************************************************************

Function /S NMWaveListAddPath( pathToAdd, wList, listSepStr )
	String pathToAdd
	String wList
	String listSepStr
	
	Variable wcnt
	String wName, wList2 = ""
	
	if ( strlen( pathToAdd ) == 0 )
		return ""
	endif
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wList, listSepStr ) ; wcnt += 1 )
		wName = StringFromList( wcnt, wList, listSepStr )
		wList2 = AddListItem( pathToAdd + wName, wList2, listSepStr, inf )
	endfor
	
	return wList2
	
End // NMWaveListAddPath

//****************************************************************
//****************************************************************
//
//	STRUCT NMRGB c
//	NMColorList2RGB( rgbList, c )
//	rgb = c.r,c.g,c.b
//
//****************************************************************
//****************************************************************

Structure NMRGB

	UInt16 r, g, b
	
EndStructure

//****************************************************************
//****************************************************************

Function /S NMRGBbasic( color, c [ wcnt ] )
	String color
	STRUCT NMRGB &c
	Variable wcnt // for "rainbow" selection
	
	strswitch( color )
	
		case "white":
			c.r = 65535
			c.g = 65535
			c.b = 65535
			break
	
		case "black":
			c.r = 0
			c.g = 0
			c.b = 0
			break
	
		case "red":
			c.r = 65535
			c.g = 0
			c.b = 0
			break
			
		case "yellow":
			c.r = 65535
			c.g = 65535
			c.b = 0
			break
			
		case "green":
			c.r = 0
			c.g = 52224
			c.b = 0
			break
			
		case "blue":
			c.r = 0
			c.g = 0
			c.b = 65535
			break
			
			break
			
		case "purple":
			c.r = 65535
			c.g = 0
			c.b = 65535
			break
			
		case "gray":
		case "grey":
			c.r = 43520
			c.g = 43520
			c.b = 43520
			break
			
		case "rainbow":
			return NMRGBrainbow( wcnt, c )
			
		default:
		
			if ( ( ItemsInList( color, "," ) == 3 ) || ( ItemsInList( color, ";" ) == 3 ) )
				return NMColorList2RGB( color, c )
			endif
			
	endswitch
	
	return num2istr( c.r ) + "," + num2istr( c.g ) + "," + num2istr( c.b ) + ","
	
End // NMRGBbasic

//****************************************************************
//****************************************************************

Function NMisRGBlist( rgbList )
	String rgbList // e.g. "0,0,0"
	
	Variable icnt, ivalue, items = ItemsInList( rgbList, "," )
	
	if ( items != 3 )
		return 0 // no
	endif
	
	for ( icnt = 0 ; icnt <= 2 ; icnt += 1 )
		
		ivalue = str2num( StringFromList( icnt, rgbList, "," ) )
		
		if ( ( numtype( iValue ) > 0 ) || ( iValue < 0 ) || ( iValue > 65535 ) )
			return 0 // no
		endif
		
	endfor
	
	return 1 // yes
	
End // NMisRGBlist

//****************************************************************
//****************************************************************

Function /S NMColorList2RGB( rgbList, c )
	String rgbList
	STRUCT NMRGB &c
	
	Variable value, red, green, blue
	String listSepStr = ","
	
	if ( strsearch( rgbList, ";", 0 ) >= 0 )
		listSepStr = ";"
	endif
	
	if ( ItemsInList( rgbList, listSepStr ) != 3 )
		return ""
	endif
	
	c.r = str2num( StringFromList( 0, rgbList, listSepStr ) )
	
	if ( numtype( c.r ) > 0 )
		c.r = 0
	endif
	
	c.r = min( max( c.r, 0 ), 65535 )
	
	c.g = str2num( StringFromList( 1, rgbList, listSepStr ) )
	
	if ( numtype( c.g ) > 0 )
		c.g = 0
	endif
	
	c.g = min( max( c.g, 0 ), 65535 )
	
	c.b = str2num( StringFromList( 2, rgbList, listSepStr ) )
	
	if ( numtype( c.b ) > 0 )
		c.b = 0
	endif
	
	c.b = min( max( c.b, 0 ), 65535 )
	
	return num2istr( c.r ) + "," + num2istr( c.g ) + "," + num2istr( c.b ) + ","
	
End // NMColorList2RGB

//****************************************************************
//****************************************************************

Function /S NMRGBrainbow( wcnt, c )
	Variable wcnt
	STRUCT NMRGB &c
	
	Variable inc = 800, cmax = 65280, cvalue
	
	Variable minValue = 0 // 30000
		
	cvalue -= trunc( wcnt / 6 ) * inc
	
	if ( cvalue <= 3000 )
		cvalue = cmax
	endif
		
	switch ( mod( wcnt, 6 ) )
		case 0: // red
			c.r = cvalue
			c.g = minValue
			c.b = minValue
			break
		case 1: // green
			c.r = minValue
			c.g = cvalue
			c.b = minValue
			break
		case 2: // blue
			c.r = minValue
			c.g = minValue
			c.b = cvalue
			break
		case 3: // yellow
			cvalue = min( cvalue, 50000 )
			c.r = cvalue
			c.g = cvalue
			c.b = minValue
			break
		case 4: // turqoise
			c.r = minValue
			c.g = cvalue
			c.b = cvalue
			break
		case 5: // purple
			c.r = cvalue
			c.g = minValue
			c.b = cvalue
			break
	endswitch
	
	return num2istr( c.r ) + "," + num2istr( c.g ) + "," + num2istr( c.b ) + ","
	
End // NMRGBrainbow

//****************************************************************
//
//	Igor-timed clock functions
//
//****************************************************************

Function NMWait( t )
	Variable t
	
	if ( ( numtype( t ) > 0 ) || ( t <= 0 ) )
		return 0
	endif
	
	return NMWaitMSTimer( t )
	
End // NMWait

//****************************************************************
//****************************************************************

Function NMWaitTicks( t ) // wait t msec ( only accurate to 17 msec )
	Variable t
	
	if ( ( numtype( t ) > 0 ) || ( t <= 0 ) )
		return 0
	endif
	
	Variable t0 = ticks
	
	t *= 60 / 1000

	do
	while ( ticks - t0 < t )
	
	return 0
	
End // NMWaitTicks

//****************************************************************
//****************************************************************

Function NMWaitMSTimer( t ) // wait t msec ( this is more accurate )
	Variable t
	
	if ( ( numtype( t ) > 0 ) || ( t <= 0 ) )
		return 0
	endif
	
	Variable t0 = stopMSTimer( -2 )
	
	t *= 1000 // convert to usec
	
	do
	while ( stopMSTimer( -2 ) - t0 < t )
	
	return 0
	
End // NMWaitMSTimer

//****************************************************************
//****************************************************************

Function /S NMSecondsToStopwatch( timeInSeconds ) // from Gerard Borst, Erasmus MC, Dept of Neuroscience
	Variable timeInSeconds

	if ( numtype( timeInSeconds ) > 0 )
		return ""
	endif

	Variable hours, minutes, seconds
	String daytime

	hours = floor( timeInSeconds / 3600 )
	timeInSeconds -= hours * 3600
	
	minutes = floor( timeInSeconds / 60 )
	timeInSeconds -= minutes * 60
	
	seconds = timeInSeconds

	daytime = SelectString( ( hours < 10 ), num2str( hours ), num2str( 0 ) + num2str( hours ) ) + ":"
	daytime += SelectString( ( minutes < 10 ), num2str( minutes ), num2str( 0 ) + num2str( minutes ) ) + ":"
	daytime += SelectString( ( seconds < 10 ), num2str( seconds ), num2str( 0 ) + num2str( seconds ) )

	return daytime

End // NMSecondsToStopwatch

//****************************************************************
//****************************************************************
//
//		Gauss width conversion functions
//
//****************************************************************
//****************************************************************

Function NMGaussWidthConvertCall()

	Variable gaussFitType, gaussFitWidth, rvalue
	String convertTo

	String df = "root:Packages:NeuroMatic:Fit:"

	Variable gaussConvertSelect = NumVarOrDefault( df + "GaussConvertSelect", 1 )
	
	Prompt gaussConvertSelect, "convert:", popup "fit Gauss width to STDV;fit gauss width to FWHM;fit Gauss2D width to STDV;fit Gauss2D width to FWHM;Gauss STDV to FWHM;Gauss FWHM to STDV;"
	DoPrompt "Convert Gauss Width", gaussConvertSelect
	
	if ( V_flag == 1 )
		return 0
	endif
	
	SetNMVar( df + "GaussConvertSelect", gaussConvertSelect )
	
	switch( gaussConvertSelect )
			
		case 1:
		
			gaussFitType = 1
			convertTo = "STDV"
			break
			
		case 2:
		
			gaussFitType = 1
			convertTo = "FWHM"
			break
			
		case 3:
		
			gaussFitType = 2
			convertTo = "STDV"
			break
			
		case 4:
		
			gaussFitType = 2
			convertTo = "FWHM"
			break
			
		case 5:
		
			return NMFitGaussSTDV2FWHMCall()
			
		case 6:
		
			return NMFitGaussFWHM2STDVCall()
			
	endswitch
	
	gaussFitWidth = NumVarOrDefault( df + "GaussFitWidth", 1 )
	
	Prompt gaussFitWidth, "gauss fit width output parameter:"
	DoPrompt "Convert Gauss Fit Width", gaussFitWidth
	
	if ( V_flag == 1 )
		return 0
	endif
	
	SetNMVar( df + "GaussFitWidth", gaussFitWidth )
	
	rvalue = NMFitGaussWidthConvert( gaussFitType, gaussFitWidth, convertTo, history = 1 )
	
	Print convertTo + " = " + num2str( rvalue )

	return rvalue

End // NMGaussWidthConvertCall

//****************************************************************
//****************************************************************

Function NMFitGaussWidthConvert( gaussFitType, gaussFitWidth, convertTo [ history ] )
	Variable gaussFitType // ( 1 ) gauss 1D ( 2 ) Gauss2D
	Variable gaussFitWidth
	String convertTo // "STDV" or "FWHM"
	Variable history
	
	Variable stdv
	String vlist = ""
	
	vlist = NMCmdNum( gaussFitType, vlist, integer = 1 )
	vlist = NMCmdNum( gaussFitWidth, vlist )
	vlist = NMCmdStr( convertTo, vlist )
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	switch( gaussFitType )
		case 1: // gauss 1D
			stdv = gaussFitWidth / sqrt( 2 )
			break
		case 2: // Gauss2D
			stdv = gaussFitWidth
			break
		default:
			return NaN
	endswitch
	
	strswitch( convertTo )
		case "STDV":
			return stdv
		case "FWHM":
			return 2 * sqrt( 2 * ln( 2 ) ) * stdv // 2.35482 * stdv
	endswitch
	
	return NaN
	
End // NMFitGaussWidthConvert

//****************************************************************
//****************************************************************

Function NMFitGaussFWHM2STDVCall()

	Variable rvalue
	String df = NMFitDF

	Variable gaussFWHM = NumVarOrDefault( df + "GaussFWHM", 1 )
	
	Prompt gaussFWHM, "gauss FWHM:"
	DoPrompt "Convert Gauss FWHM to STDV", gaussFWHM
	
	if ( V_flag == 1 )
		return 0
	endif
	
	SetNMVar( df + "GaussFWHM", gaussFWHM )
	
	rvalue = NMGaussFWHM2STDV( gaussFWHM, history = 1 )
	
	Print "STDV = " + num2str( rvalue )

End // NMFitGaussFWHM2STDVCall

//****************************************************************
//****************************************************************

Function NMGaussFWHM2STDV( gaussFWHM [ history ] )
	Variable gaussFWHM
	Variable history
	
	String vlist = ""
	
	if ( history )
		vlist = NMCmdNum( gaussFWHM, vlist )
		NMCommandHistory( vlist )
	endif
	
	Variable cfactor = 2 * sqrt( 2 * ln( 2 ) ) // 2.35482
	
	return gaussFWHM / cfactor
	
End // NMGaussFWHM2STDV

//****************************************************************
//****************************************************************

Function NMFitGaussSTDV2FWHMCall()

	Variable rvalue
	String df = NMFitDF

	Variable gaussSTDV = NumVarOrDefault( df + "GaussSTDV", 1 )
	
	Prompt gaussSTDV, "gauss STDV:"
	DoPrompt "Convert Gauss STDV to FWHM", gaussSTDV
	
	if ( V_flag == 1 )
		return 0
	endif
	
	SetNMVar( df + "GaussSTDV", gaussSTDV )
	
	rvalue = NMGaussSTDV2FWHM( gaussSTDV, history = 1 )
	
	Print "FWHM = " + num2str( rvalue )

End // NMFitGaussSTDV2FWHMCall

//****************************************************************
//****************************************************************

Function NMGaussSTDV2FWHM( gaussSTDV [ history ] )
	Variable gaussSTDV
	Variable history
	
	String vlist = ""
	
	if ( history )
		vlist = NMCmdNum( gaussSTDV, vlist )
		NMCommandHistory( vlist )
	endif
	
	Variable cfactor = 2 * sqrt( 2 * ln( 2 ) ) // 2.35482
	
	return cfactor * gaussSTDV
	
End // NMGaussSTDV2FWHM

//****************************************************************
//****************************************************************
//
//		Functions not used anymore
//
//****************************************************************
//****************************************************************

Function NMVarStrExists( varName ) // NOT USED
	String varName
	
	if ( exists( varName ) != 2 )
		return 0
	endif
	
	String strValue = StrVarOrDefault( varName, "NMThisStringDoesNotExist" )
	
	if ( StringMatch(strValue, "NMThisStringDoesNotExist" ) )
		return 1 // must be a variable
	else
		return 2 // must be a string
	endif
	
End //NMVarStrExists

//****************************************************************
//****************************************************************

Function /S NMFolderPriority( wName, folder ) // NOT USED
	String wName, folder
	
	String parent = NMParent( wName )
	
	if ( DataFolderExists( parent ) )
		return parent
	else
		return folder
	endif
	
End // NMFolderPriority

//****************************************************************
//****************************************************************

Function /S GetPathName( fullPathList, option ) // NOT USED // see NMParent or NMChild
	String fullPathList
	Variable option
	
	if ( option == 0 )
		return NMChild( fullPathList )
	elseif ( option == 1 )
		return NMParent( fullPathList )
	endif

End // GetPathName

//****************************************************************
//****************************************************************

Function NMColorListRGB( select, rgbList ) // NOT USED // see NMColorList2RGB
	String select
	String rgbList
	
	STRUCT NMRGB c
	
	NMColorList2RGB( rgbList, c )
	
	strswitch( select )
		case "red":
			return c.r
		case "green":
			return c.g
		case "blue":
			return c.b
	endswitch
	
	return 0
	
End // NMColorListRGB

//****************************************************************
//****************************************************************

Function NMPlotRGB( color, rgbSelect ) // NOT USED // see NMRGBbasic
	String color
	String rgbSelect
	
	STRUCT NMRGB c
	
	NMRGBbasic( color, c )
	
	strswitch( rgbSelect )
		case "r":
			return c.r
		case "g":
			return c.g
		case "b":
			return c.b
	endswitch
	
	return 0

End // NMPlotRGB

//****************************************************************
//****************************************************************

Function SpikeSlope( wName, event, thresh, pwin ) // NOT USED
	String wName
	Variable event
	Variable thresh
	Variable pwin
	
	Variable xbgn, xend, epnt, xpnt, dt
	Variable icnt, jcnt, xavg, yavg, xsum, ysum, xysum, sumsqr, slope, intercept
	
	if ( NMUtilityWaveTest( wName ) < 0 )
		return NaN
	endif
	
	if ( ( numtype( event ) > 0 ) || ( event < leftx( $wName ) ) || ( event > rightx( $wName ) ) )
		return NaN
	endif
	
	Wave wtemp = $wName
	
	dt = deltax(wtemp)
	epnt = x2pnt(wtemp, event)
	xpnt = pnt2x(wtemp, epnt)
	
	Make /O/N=(1 + 2 * pWin) U_SlopeX, U_SlopeY
	
	if (xpnt == event) // unlikely
	
		jcnt = epnt - pwin
		
		for (icnt = 0; icnt < numpnts(U_SlopeX); icnt += 1)
			U_SlopeX[icnt] = pnt2x(wtemp, jcnt)
			U_SlopeY[icnt] = wtemp[jcnt]
			jcnt += 1
		endfor
		
	elseif (xpnt < event)
	
		U_SlopeX[0] = event
		U_SlopeY[0] = thresh
		
		jcnt = epnt - (pwin - 1)
	
		for (icnt = 1; icnt < numpnts(U_SlopeX); icnt += 1)
			U_SlopeX[icnt] = pnt2x(wtemp, jcnt)
			U_SlopeY[icnt] = wtemp[jcnt]
			jcnt += 1
		endfor
		
	else
	
		U_SlopeX[0] = event
		U_SlopeY[0] = thresh
		
		jcnt = epnt - pwin
	
		for (icnt = 1; icnt < numpnts(U_SlopeX); icnt += 1)
			U_SlopeX[icnt] = pnt2x(wtemp, jcnt)
			U_SlopeY[icnt] = wtemp[jcnt]
			jcnt += 1
		endfor
	
	endif
	
	Wavestats /Q/Z U_SlopeX
	
	xavg = V_avg
	xsum = sum(U_SlopeX)
	
	Wavestats /Q/Z U_SlopeY
	
	yavg = V_avg
	ysum = sum(U_SlopeY)
	
	for (icnt = 0; icnt < numpnts(U_SlopeX); icnt += 1)
		xysum += (U_SlopeX[icnt] - xavg) * (U_SlopeY[icnt] - yavg)
		sumsqr += (U_SlopeX[icnt] - xavg) ^ 2
	endfor
	
	slope = xysum / sumsqr
	intercept = (ysum - slope * xsum) / numpnts(U_SlopeX)
	
	KillWaves /Z U_SlopeY, U_SlopeX

	return slope

End // SpikeSlope

//****************************************************************
//****************************************************************

Function NMCrossCorrelation( wName1, wName2, outHistoName, binSize ) // NOT USED
	String wName1 // wave of events #1
	String wName2 // wave of events #2
	String outHistoName // output histogram wave name
	Variable binSize // histogram binsize
	
	Variable icnt, jcnt, kcnt, events1, events2, npnts1, npnts2, intervals
	Variable intvl, iMax = -inf, iMin = inf
	Variable npntsHisto
	
	if ( NMUtilityWaveTest( wName1 ) < 0 )
		return NM2Error( 1, "wName1", wName1 )
	endif
	
	if ( NMUtilityWaveTest( wName2 ) < 0 )
		return NM2Error( 1, "wName2", wName2 )
	endif
	
	if ( strlen( outHistoName ) == 0 )
		return NM2Error( 21, "outHistoName", outHistoName )
	endif
	
	//if ( WaveExists( $outHistoName ) )
	//	return NM2Error( 2, "outHistoName", outHistoName )
	//endif
	
	if ( ( numtype( binSize ) > 0 ) || ( binSize < 0 ) )
		return NM2Error( 10, "binSize", num2str( binSize ) )
	endif
	
	Wave wtemp1 = $wName1
	Wave wtemp2 = $wName2
	
	npnts1 = numpnts( wtemp1 )
	npnts2 = numpnts( wtemp2 )
	
	iMax = wtemp1[ npnts1 - 1 ] - wtemp2[ 0 ]
	iMin = wtemp1[ 0 ] - wtemp2[ npnts2 - 1 ]
	
	iMax *= 1.1
	iMin *= 1.1
	
	npntsHisto = 2 + ( iMax - iMin ) / binSize
	
	WaveStats /Q wtemp1
	
	events1 = V_npnts
	
	WaveStats /Q wtemp2
	
	events2 = V_npnts
	
	intervals = events1 * events2
	
	Make /O/N=( intervals + events1 ) NM_CC_Intervals = NaN
	
	for ( icnt = 0 ; icnt < npnts1 ; icnt += 1 )
		
		for ( jcnt = 0 ; jcnt < npnts2 ; jcnt += 1 )
		
			intvl = wtemp1[ icnt ] - wtemp2[ jcnt ]
			
			NM_CC_Intervals[ kcnt ] = intvl
			
			kcnt += 1
			
		endfor
		
		kcnt += 1
	
	endfor
	
	outHistoName = NMCheckStringName( outHistoName )
	
	Make /O/N=1 $outHistoName
	
	iMin = binSize * floor( iMin / binSize )
	
	Histogram /B={ iMin, binSize, npntsHisto } NM_CC_Intervals, $outHistoName
	
	Wave cc = $outHistoName
	
End // NMCrossCorrelation

//****************************************************************
//****************************************************************

Function NMFindStim( wName, xbinSize, conf ) // find stimulus artifact times // NOT USED
	String wName // wave name
	Variable xbinSize // x-axis bin size ( e.g. 1 ms )
	Variable conf // % confidence from max value ( e.g. 95 )
	
	Variable tlimit = 0.1 // limit of stim width
	Variable absmax, absmin, icnt, jcnt
	String thisFxn = GetRTStackInfo( 1 )
	
	if ( NMUtilityWaveTest( wName ) < 0 )
		return -1
	endif
	
	if ( ( xbinSize < 0 ) || ( conf <= 0 ) || ( conf > 100 ) || ( numtype( xbinSize*conf ) != 0 ) )
		return -1
	endif
	
	Duplicate /O $wName U_WaveTemp
	Differentiate U_WaveTemp
	WaveStats /Q/Z U_WaveTemp
	
	absmax = abs( V_max - V_avg )
	absmin = abs( V_min - V_avg )
	
	if ( absmax > absmin )
		Findlevels /Q U_WaveTemp, ( V_avg + absmax*conf/100 )
	else
		Findlevels /Q U_WaveTemp, ( V_avg - absmin*conf/100 )
	endif
	
	if ( V_Levelsfound == 0 )
		return -1
	endif
	
	Wave W_FindLevels
	
	Make /O/N=( V_Levelsfound/2 ) U_StimTimes
	
	for ( icnt = 0; icnt < V_Levelsfound-1;icnt += 2 )
		if ( W_FindLevels[1] - W_FindLevels[0] <= tlimit )
			U_StimTimes[jcnt] = floor( W_FindLevels[icnt]/xbinSize ) * xbinSize
			jcnt += 1
		endif
	endfor
	
	Note U_StimTimes, "Func:" + thisFxn
	Note U_StimTimes, "Source:" + wName
	
	KillWaves /Z U_WaveTemp, W_FindLevels
	
	return 0

End // NMFindStim

//****************************************************************
//****************************************************************